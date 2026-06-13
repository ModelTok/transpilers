# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter carrying dataMixerComponent, dataLoopNodes,
#   dataZoneEquip, dataDefineEquipment, dataInputProcessing,
#   dataPowerInductionUnits, dataContaminantBalance
# - Util.FindItemInList(items, items_list, attr_name_fn) -> int (0 if not found)
# - ShowFatalError(state, message)
# - ShowSevereError(state, message)
# - ShowContinueError(state, message)
# - Node.GetOnlySingleNode(state, name, errorsFound, connObjType, objName,
#   fluidType, connType, compFluidStream, objIsNotParent) -> int
# - Psychrometrics.PsyTdbFnHW(enthalpy, humRat) -> Float64
# - format(...) from EnergyPlus utilities

from collections import List
import math

struct MixerConditions:
    var MixerName: String
    var OutletTemp: Float64
    var OutletHumRat: Float64
    var OutletEnthalpy: Float64
    var OutletPressure: Float64
    var OutletNode: Int
    var OutletMassFlowRate: Float64
    var OutletMassFlowRateMaxAvail: Float64
    var OutletMassFlowRateMinAvail: Float64
    var InitFlag: Bool
    var NumInletNodes: Int
    var InletNode: List[Int]
    var InletMassFlowRate: List[Float64]
    var InletMassFlowRateMaxAvail: List[Float64]
    var InletMassFlowRateMinAvail: List[Float64]
    var InletTemp: List[Float64]
    var InletHumRat: List[Float64]
    var InletEnthalpy: List[Float64]
    var InletPressure: List[Float64]

    fn __init__(inout self):
        self.MixerName = ""
        self.OutletTemp = 0.0
        self.OutletHumRat = 0.0
        self.OutletEnthalpy = 0.0
        self.OutletPressure = 0.0
        self.OutletNode = 0
        self.OutletMassFlowRate = 0.0
        self.OutletMassFlowRateMaxAvail = 0.0
        self.OutletMassFlowRateMinAvail = 0.0
        self.InitFlag = False
        self.NumInletNodes = 0
        self.InletNode = List[Int]()
        self.InletMassFlowRate = List[Float64]()
        self.InletMassFlowRateMaxAvail = List[Float64]()
        self.InletMassFlowRateMinAvail = List[Float64]()
        self.InletTemp = List[Float64]()
        self.InletHumRat = List[Float64]()
        self.InletEnthalpy = List[Float64]()
        self.InletPressure = List[Float64]()


struct MixerComponentData:
    var NumMixers: Int
    var LoopInletNode: Int
    var LoopOutletNode: Int
    var SimAirMixerInputFlag: Bool
    var GetZoneMixerIndexInputFlag: Bool
    var CheckEquipName: List[Bool]
    var MixerCond: List[MixerConditions]

    fn __init__(inout self):
        self.NumMixers = 0
        self.LoopInletNode = 0
        self.LoopOutletNode = 0
        self.SimAirMixerInputFlag = True
        self.GetZoneMixerIndexInputFlag = True
        self.CheckEquipName = List[Bool]()
        self.MixerCond = List[MixerConditions]()

    fn clear_state(inout self):
        self.NumMixers = 0
        self.LoopInletNode = 0
        self.LoopOutletNode = 0
        self.GetZoneMixerIndexInputFlag = True
        self.SimAirMixerInputFlag = True
        self.CheckEquipName.clear()
        self.MixerCond.clear()


fn SimAirMixer(inout state, CompName: String, inout CompIndex: Int):
    var MixerNum: Int = 0

    if state.dataMixerComponent.SimAirMixerInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.SimAirMixerInputFlag = False

    if CompIndex == 0:
        MixerNum = FindItemInList(CompName, state.dataMixerComponent.MixerCond)
        if MixerNum == 0:
            ShowFatalError(state, "SimAirLoopMixer: Mixer not found=" + CompName)
        CompIndex = MixerNum
    else:
        MixerNum = CompIndex
        if MixerNum > state.dataMixerComponent.NumMixers or MixerNum < 1:
            ShowFatalError(state, "SimAirLoopMixer: Invalid CompIndex passed=" + str(MixerNum) +
                          ", Number of Mixers=" + str(state.dataMixerComponent.NumMixers) +
                          ", Mixer name=" + CompName)
        if state.dataMixerComponent.CheckEquipName[MixerNum - 1]:
            if CompName != state.dataMixerComponent.MixerCond[MixerNum - 1].MixerName:
                ShowFatalError(state, "SimAirLoopMixer: Invalid CompIndex passed=" + str(MixerNum) +
                              ", Mixer name=" + CompName + ", stored Mixer Name for that index=" +
                              state.dataMixerComponent.MixerCond[MixerNum - 1].MixerName)
            state.dataMixerComponent.CheckEquipName[MixerNum - 1] = False

    InitAirMixer(state, MixerNum)
    CalcAirMixer(state, MixerNum)
    UpdateAirMixer(state, MixerNum)
    ReportMixer(MixerNum)


fn GetMixerInput(inout state):
    var RoutineName = "GetMixerInput: "
    var CurrentModuleObject = "AirLoopHVAC:ZoneMixer"

    state.dataMixerComponent.NumMixers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, CurrentModuleObject)

    if state.dataMixerComponent.NumMixers > 0:
        state.dataMixerComponent.MixerCond.clear()
        for i in range(state.dataMixerComponent.NumMixers):
            state.dataMixerComponent.MixerCond.append(MixerConditions())

    state.dataMixerComponent.CheckEquipName.clear()
    for i in range(state.dataMixerComponent.NumMixers):
        state.dataMixerComponent.CheckEquipName.append(True)

    var NumParams: Int = 0
    var NumAlphas: Int = 0
    var NumNums: Int = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, CurrentModuleObject, NumParams, NumAlphas, NumNums)

    var AlphArray = List[String]()
    var cAlphaFields = List[String]()
    var lAlphaBlanks = List[Bool]()
    var cNumericFields = List[String]()
    var lNumericBlanks = List[Bool]()
    var NumArray = List[Float64]()

    for i in range(NumAlphas):
        AlphArray.append("")
        cAlphaFields.append("")
        lAlphaBlanks.append(True)

    for i in range(NumNums):
        cNumericFields.append("")
        lNumericBlanks.append(True)
        NumArray.append(0.0)

    var ErrorsFound: Bool = False

    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        var IOStat: Int = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, MixerNum, AlphArray, NumAlphas, NumArray, NumNums,
            IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)

        var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
        mixer.MixerName = AlphArray[0]

        mixer.OutletNode = GetOnlySingleNode(
            state, AlphArray[1], ErrorsFound,
            "AirLoopHVACZoneMixer", AlphArray[0],
            "Air", "Outlet", "Primary", "ObjectIsNotParent")

        mixer.NumInletNodes = NumAlphas - 2

        for e in state.dataMixerComponent.MixerCond:
            e.InitFlag = True

        mixer.InletNode.clear()
        mixer.InletMassFlowRate.clear()
        mixer.InletMassFlowRateMaxAvail.clear()
        mixer.InletMassFlowRateMinAvail.clear()
        mixer.InletTemp.clear()
        mixer.InletHumRat.clear()
        mixer.InletEnthalpy.clear()
        mixer.InletPressure.clear()

        for i in range(mixer.NumInletNodes):
            mixer.InletNode.append(0)
            mixer.InletMassFlowRate.append(0.0)
            mixer.InletMassFlowRateMaxAvail.append(0.0)
            mixer.InletMassFlowRateMinAvail.append(0.0)
            mixer.InletTemp.append(0.0)
            mixer.InletHumRat.append(0.0)
            mixer.InletEnthalpy.append(0.0)
            mixer.InletPressure.append(0.0)

        mixer.OutletMassFlowRate = 0.0
        mixer.OutletMassFlowRateMaxAvail = 0.0
        mixer.OutletMassFlowRateMinAvail = 0.0
        mixer.OutletTemp = 0.0
        mixer.OutletHumRat = 0.0
        mixer.OutletEnthalpy = 0.0
        mixer.OutletPressure = 0.0

        for NodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.InletNode[NodeNum - 1] = GetOnlySingleNode(
                state, AlphArray[1 + NodeNum], ErrorsFound,
                "AirLoopHVACZoneMixer", AlphArray[0],
                "Air", "Inlet", "Primary", "ObjectIsNotParent")
            if lAlphaBlanks[1 + NodeNum]:
                ShowSevereError(state, cAlphaFields[1 + NodeNum] + " is Blank, " +
                              CurrentModuleObject + " = " + AlphArray[0])
                ErrorsFound = True

    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
        var NodeNum = mixer.OutletNode
        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            if NodeNum == mixer.InletNode[InNodeNum1 - 1]:
                ShowSevereError(state, CurrentModuleObject + " = " + mixer.MixerName +
                              " specifies an inlet node name the same as the outlet node.")
                ShowContinueError(state, ".." + cAlphaFields[1] + " = " +
                                state.dataLoopNodes.NodeID(NodeNum))
                ShowContinueError(state, "..Inlet Node #" + str(InNodeNum1) + " is duplicate.")
                ErrorsFound = True

        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            for InNodeNum2 in range(InNodeNum1 + 1, mixer.NumInletNodes + 1):
                if mixer.InletNode[InNodeNum1 - 1] == mixer.InletNode[InNodeNum2 - 1]:
                    ShowSevereError(state, CurrentModuleObject + " = " + mixer.MixerName +
                                  " specifies duplicate inlet nodes in its inlet node list.")
                    ShowContinueError(state, "..Inlet Node #" + str(InNodeNum1) + " Name=" +
                                    state.dataLoopNodes.NodeID(InNodeNum1))
                    ShowContinueError(state, "..Inlet Node #" + str(InNodeNum2) + " is duplicate.")
                    ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(state, RoutineName + "Errors found in getting input.")


fn InitAirMixer(inout state, MixerNum: Int):
    var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    for NodeNum in range(1, mixer.NumInletNodes + 1):
        var inletNode = state.dataLoopNodes.Node[mixer.InletNode[NodeNum - 1]]
        mixer.InletMassFlowRate[NodeNum - 1] = inletNode.MassFlowRate
        mixer.InletMassFlowRateMaxAvail[NodeNum - 1] = inletNode.MassFlowRateMaxAvail
        mixer.InletMassFlowRateMinAvail[NodeNum - 1] = inletNode.MassFlowRateMinAvail
        mixer.InletTemp[NodeNum - 1] = inletNode.Temp
        mixer.InletHumRat[NodeNum - 1] = inletNode.HumRat
        mixer.InletEnthalpy[NodeNum - 1] = inletNode.Enthalpy
        mixer.InletPressure[NodeNum - 1] = inletNode.Press


fn CalcAirMixer(inout state, inout MixerNum: Int):
    var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    mixer.OutletMassFlowRate = 0.0
    mixer.OutletMassFlowRateMaxAvail = 0.0
    mixer.OutletMassFlowRateMinAvail = 0.0
    mixer.OutletTemp = 0.0
    mixer.OutletHumRat = 0.0
    mixer.OutletPressure = 0.0
    mixer.OutletEnthalpy = 0.0

    var massFlowRateParallelPIULk: Float64 = 0.0
    var massFlowRateHumRatParallelPIULk: Float64 = 0.0
    var massFlowRatePressureParallelPIULk: Float64 = 0.0
    var massFlowRateEnthalpyParallelPIULk: Float64 = 0.0

    for InletNodeNum in range(1, mixer.NumInletNodes + 1):
        if state.dataPowerInductionUnits.NumParallelPIUs > 0:
            for returnAirPathNum in range(1, len(state.dataZoneEquip.ReturnAirPath) + 1):
                var returnAirPath = state.dataZoneEquip.ReturnAirPath[returnAirPathNum - 1]
                var returnAirPathCompNumOfComponents = returnAirPath.NumOfComponents
                for returnPathCompNum in range(1, returnAirPathCompNumOfComponents + 1):
                    if (returnAirPath.ComponentName[returnPathCompNum - 1] == mixer.MixerName and
                        returnAirPath.ComponentTypeEnum[returnPathCompNum - 1] == "Mixer"):
                        if not state.dataDefineEquipment.AirDistUnit.is_empty():
                            for airDistUnitNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
                                var airDistUnit = state.dataDefineEquipment.AirDistUnit[airDistUnitNum - 1]
                                if airDistUnit.piuLkZoneNum > 0:
                                    var airDistUnitZoneNum = airDistUnit.ZoneNum
                                    if airDistUnitZoneNum > 0:
                                        var numRetNodes = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum - 1].NumReturnNodes
                                        for retZoneAirNodeNum in range(1, numRetNodes + 1):
                                            var retZoneAirNode = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum - 1].ReturnNodeAirLoopNum[retZoneAirNodeNum - 1]
                                            if retZoneAirNode == InletNodeNum:
                                                massFlowRateParallelPIULk += airDistUnit.massFlowRateParallelPIULk
                                                massFlowRateHumRatParallelPIULk += (airDistUnit.massFlowRateParallelPIULk *
                                                                                    state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum].HumRat)
                                                massFlowRatePressureParallelPIULk += (airDistUnit.massFlowRateParallelPIULk *
                                                                                      state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum].Press)
                                                massFlowRateEnthalpyParallelPIULk += (airDistUnit.massFlowRateParallelPIULk *
                                                                                      state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum].Enthalpy)

        mixer.OutletMassFlowRate += mixer.InletMassFlowRate[InletNodeNum - 1]
        mixer.OutletMassFlowRateMaxAvail += mixer.InletMassFlowRateMaxAvail[InletNodeNum - 1]
        mixer.OutletMassFlowRateMinAvail += mixer.InletMassFlowRateMinAvail[InletNodeNum - 1]

    if mixer.OutletMassFlowRate > 0.0:
        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletHumRat += (mixer.InletMassFlowRate[InletNodeNum - 1] *
                                   mixer.InletHumRat[InletNodeNum - 1] / mixer.OutletMassFlowRate)

        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletPressure += (mixer.InletPressure[InletNodeNum - 1] *
                                     mixer.InletMassFlowRate[InletNodeNum - 1] / mixer.OutletMassFlowRate)

        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletEnthalpy += (mixer.InletEnthalpy[InletNodeNum - 1] *
                                     mixer.InletMassFlowRate[InletNodeNum - 1] / mixer.OutletMassFlowRate)

        if massFlowRateParallelPIULk > 0:
            var noLeakMassFlowRate = mixer.OutletMassFlowRate
            var totMassFlowRate = noLeakMassFlowRate + massFlowRateParallelPIULk

            mixer.OutletHumRat = ((noLeakMassFlowRate * mixer.OutletHumRat +
                                   massFlowRateHumRatParallelPIULk) / totMassFlowRate)

            mixer.OutletPressure = ((noLeakMassFlowRate * mixer.OutletPressure +
                                     massFlowRatePressureParallelPIULk) / totMassFlowRate)

            mixer.OutletEnthalpy = ((noLeakMassFlowRate * mixer.OutletEnthalpy +
                                     massFlowRateEnthalpyParallelPIULk) / totMassFlowRate)

            mixer.OutletMassFlowRate = totMassFlowRate

        mixer.OutletTemp = PsyTdbFnHW(mixer.OutletEnthalpy, mixer.OutletHumRat)

    else:
        mixer.OutletHumRat = mixer.InletHumRat[0]
        mixer.OutletPressure = mixer.InletPressure[0]
        mixer.OutletEnthalpy = mixer.InletEnthalpy[0]
        mixer.OutletTemp = mixer.InletTemp[0]

    mixer.OutletMassFlowRateMaxAvail = max(mixer.OutletMassFlowRateMaxAvail, mixer.OutletMassFlowRate)


fn UpdateAirMixer(inout state, MixerNum: Int):
    var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    var outletNode = state.dataLoopNodes.Node[mixer.OutletNode]
    var inletNode = state.dataLoopNodes.Node[mixer.InletNode[0]]

    outletNode.MassFlowRate = mixer.OutletMassFlowRate
    outletNode.MassFlowRateMaxAvail = mixer.OutletMassFlowRateMaxAvail
    outletNode.MassFlowRateMinAvail = mixer.OutletMassFlowRateMinAvail
    outletNode.Temp = mixer.OutletTemp
    outletNode.HumRat = mixer.OutletHumRat
    outletNode.Enthalpy = mixer.OutletEnthalpy
    outletNode.Press = mixer.OutletPressure
    outletNode.Quality = inletNode.Quality

    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        if mixer.OutletMassFlowRate > 0.0:
            outletNode.CO2 = 0.0
            for InletNodeNum in range(1, mixer.NumInletNodes + 1):
                outletNode.CO2 += (state.dataLoopNodes.Node[mixer.InletNode[InletNodeNum - 1]].CO2 *
                                   mixer.InletMassFlowRate[InletNodeNum - 1] / mixer.OutletMassFlowRate)
        else:
            outletNode.CO2 = inletNode.CO2

    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        if mixer.OutletMassFlowRate > 0.0:
            outletNode.GenContam = 0.0
            for InletNodeNum in range(1, mixer.NumInletNodes + 1):
                outletNode.GenContam += (state.dataLoopNodes.Node[mixer.InletNode[InletNodeNum - 1]].GenContam *
                                         mixer.InletMassFlowRate[InletNodeNum - 1] / mixer.OutletMassFlowRate)
        else:
            outletNode.GenContam = inletNode.GenContam


fn ReportMixer(MixerNum: Int):
    pass


fn GetZoneMixerIndex(inout state, MixerName: String, inout MixerIndex: Int, inout ErrorsFound: Bool, ThisObjectType: String = ""):
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False

    MixerIndex = FindItemInList(MixerName, state.dataMixerComponent.MixerCond)
    if MixerIndex == 0:
        if len(ThisObjectType) > 0:
            ShowSevereError(state, ThisObjectType + ", GetZoneMixerIndex: Zone Mixer not found=" + MixerName)
        else:
            ShowSevereError(state, "GetZoneMixerIndex: Zone Mixer not found=" + MixerName)
        ErrorsFound = True


fn getZoneMixerIndexFromInletNode(inout state, InNodeNum: Int) -> Int:
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False

    if state.dataMixerComponent.NumMixers > 0:
        for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
            var mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
            for InNodeCtr in range(1, mixer.NumInletNodes + 1):
                if InNodeNum == mixer.InletNode[InNodeCtr - 1]:
                    return MixerNum

    return 0


@always_inline
fn FindItemInList(name: String, items: List[MixerConditions]) -> Int:
    for i in range(len(items)):
        if items[i].MixerName == name:
            return i + 1
    return 0


@always_inline
fn GetOnlySingleNode(inout state, name: String, inout errorsFound: Bool, connObjType: String,
                     objName: String, fluidType: String, connType: String,
                     compFluidStream: String, objIsNotParent: String) -> Int:
    return 0


@always_inline
fn ShowFatalError(inout state, message: String):
    pass


@always_inline
fn ShowSevereError(inout state, message: String):
    pass


@always_inline
fn ShowContinueError(inout state, message: String):
    pass


@always_inline
fn PsyTdbFnHW(enthalpy: Float64, humRat: Float64) -> Float64:
    return 0.0
