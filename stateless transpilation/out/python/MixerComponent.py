# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state parameter carrying .dataMixerComponent, .dataLoopNodes, 
#   .dataZoneEquip, .dataDefineEquipment, .dataInputProcessing, 
#   .dataPowerInductionUnits, .dataContaminantBalance
# - Util.FindItemInList(items, items_list, attr_name) -> int (0 if not found)
# - ShowFatalError(state, message)
# - ShowSevereError(state, message) 
# - ShowContinueError(state, message)
# - Node.GetOnlySingleNode(state, name, errorsFound, connObjType, objName, 
#   fluidType, connType, compFluidStream, objIsNotParent) -> int
# - Psychrometrics.PsyTdbFnHW(enthalpy, humRat) -> float
# - format(...) from EnergyPlus utilities

from typing import Protocol, List
from dataclasses import dataclass, field

@dataclass
class MixerConditions:
    MixerName: str = ""
    OutletTemp: float = 0.0
    OutletHumRat: float = 0.0
    OutletEnthalpy: float = 0.0
    OutletPressure: float = 0.0
    OutletNode: int = 0
    OutletMassFlowRate: float = 0.0
    OutletMassFlowRateMaxAvail: float = 0.0
    OutletMassFlowRateMinAvail: float = 0.0
    InitFlag: bool = False
    NumInletNodes: int = 0
    InletNode: List[int] = field(default_factory=list)
    InletMassFlowRate: List[float] = field(default_factory=list)
    InletMassFlowRateMaxAvail: List[float] = field(default_factory=list)
    InletMassFlowRateMinAvail: List[float] = field(default_factory=list)
    InletTemp: List[float] = field(default_factory=list)
    InletHumRat: List[float] = field(default_factory=list)
    InletEnthalpy: List[float] = field(default_factory=list)
    InletPressure: List[float] = field(default_factory=list)


@dataclass
class MixerComponentData:
    NumMixers: int = 0
    LoopInletNode: int = 0
    LoopOutletNode: int = 0
    SimAirMixerInputFlag: bool = True
    GetZoneMixerIndexInputFlag: bool = True
    CheckEquipName: List[bool] = field(default_factory=list)
    MixerCond: List[MixerConditions] = field(default_factory=list)

    def clear_state(self):
        self.NumMixers = 0
        self.LoopInletNode = 0
        self.LoopOutletNode = 0
        self.GetZoneMixerIndexInputFlag = True
        self.SimAirMixerInputFlag = True
        self.CheckEquipName.clear()
        self.MixerCond.clear()


def SimAirMixer(state, CompName: str, CompIndex: List[int]):
    MixerNum = 0

    if state.dataMixerComponent.SimAirMixerInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.SimAirMixerInputFlag = False

    if CompIndex[0] == 0:
        from Util import FindItemInList
        MixerNum = FindItemInList(CompName, state.dataMixerComponent.MixerCond, 
                                   lambda x: x.MixerName)
        if MixerNum == 0:
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"SimAirLoopMixer: Mixer not found={CompName}")
        CompIndex[0] = MixerNum
    else:
        MixerNum = CompIndex[0]
        if MixerNum > state.dataMixerComponent.NumMixers or MixerNum < 1:
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"SimAirLoopMixer: Invalid CompIndex passed={MixerNum}, "
                          f"Number of Mixers={state.dataMixerComponent.NumMixers}, Mixer name={CompName}")
        if state.dataMixerComponent.CheckEquipName[MixerNum - 1]:
            if CompName != state.dataMixerComponent.MixerCond[MixerNum - 1].MixerName:
                from UtilityRoutines import ShowFatalError
                ShowFatalError(state, f"SimAirLoopMixer: Invalid CompIndex passed={MixerNum}, "
                              f"Mixer name={CompName}, stored Mixer Name for that index="
                              f"{state.dataMixerComponent.MixerCond[MixerNum - 1].MixerName}")
            state.dataMixerComponent.CheckEquipName[MixerNum - 1] = False

    InitAirMixer(state, MixerNum)
    CalcAirMixer(state, MixerNum)
    UpdateAirMixer(state, MixerNum)
    ReportMixer(MixerNum)


def GetMixerInput(state):
    from InputProcessing import GetOnlySingleNode
    from UtilityRoutines import ShowFatalError, ShowSevereError

    RoutineName = "GetMixerInput: "
    CurrentModuleObject = "AirLoopHVAC:ZoneMixer"

    state.dataMixerComponent.NumMixers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, CurrentModuleObject)

    if state.dataMixerComponent.NumMixers > 0:
        state.dataMixerComponent.MixerCond = [MixerConditions() for _ in range(state.dataMixerComponent.NumMixers)]

    state.dataMixerComponent.CheckEquipName = [True] * state.dataMixerComponent.NumMixers

    NumParams, NumAlphas, NumNums = state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(
        state, CurrentModuleObject)

    AlphArray = [""] * NumAlphas
    cAlphaFields = [""] * NumAlphas
    lAlphaBlanks = [True] * NumAlphas
    cNumericFields = [""] * NumNums
    lNumericBlanks = [True] * NumNums
    NumArray = [0.0] * NumNums

    ErrorsFound = False

    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        IOStat = 0
        AlphArray, NumAlphas, NumArray, NumNums, IOStat = state.dataInputProcessing.inputProcessor.getObjectItem(
            state, CurrentModuleObject, MixerNum, AlphArray, NumAlphas, NumArray, NumNums,
            IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)

        mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
        mixer.MixerName = AlphArray[0]

        mixer.OutletNode = GetOnlySingleNode(
            state, AlphArray[1], ErrorsFound,
            "AirLoopHVACZoneMixer", AlphArray[0],
            "Air", "Outlet", "Primary", "ObjectIsNotParent")

        mixer.NumInletNodes = NumAlphas - 2

        for e in state.dataMixerComponent.MixerCond:
            e.InitFlag = True

        mixer.InletNode = [0] * mixer.NumInletNodes
        mixer.InletMassFlowRate = [0.0] * mixer.NumInletNodes
        mixer.InletMassFlowRateMaxAvail = [0.0] * mixer.NumInletNodes
        mixer.InletMassFlowRateMinAvail = [0.0] * mixer.NumInletNodes
        mixer.InletTemp = [0.0] * mixer.NumInletNodes
        mixer.InletHumRat = [0.0] * mixer.NumInletNodes
        mixer.InletEnthalpy = [0.0] * mixer.NumInletNodes
        mixer.InletPressure = [0.0] * mixer.NumInletNodes

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
                from UtilityRoutines import ShowSevereError
                ShowSevereError(state, f"{cAlphaFields[1 + NodeNum]} is Blank, "
                              f"{CurrentModuleObject} = {AlphArray[0]}")
                ErrorsFound = True

    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
        NodeNum = mixer.OutletNode
        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            if NodeNum == mixer.InletNode[InNodeNum1 - 1]:
                from UtilityRoutines import ShowSevereError, ShowContinueError
                ShowSevereError(state, f"{CurrentModuleObject} = {mixer.MixerName} specifies an inlet "
                              f"node name the same as the outlet node.")
                ShowContinueError(state, f"..{cAlphaFields[1]} = {state.dataLoopNodes.NodeID(NodeNum)}")
                ShowContinueError(state, f"..Inlet Node #{InNodeNum1} is duplicate.")
                ErrorsFound = True

        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            for InNodeNum2 in range(InNodeNum1 + 1, mixer.NumInletNodes + 1):
                if mixer.InletNode[InNodeNum1 - 1] == mixer.InletNode[InNodeNum2 - 1]:
                    from UtilityRoutines import ShowSevereError, ShowContinueError
                    ShowSevereError(state, f"{CurrentModuleObject} = {mixer.MixerName} specifies duplicate "
                                  f"inlet nodes in its inlet node list.")
                    ShowContinueError(state, f"..Inlet Node #{InNodeNum1} Name={state.dataLoopNodes.NodeID(InNodeNum1)}")
                    ShowContinueError(state, f"..Inlet Node #{InNodeNum2} is duplicate.")
                    ErrorsFound = True

    if ErrorsFound:
        ShowFatalError(state, f"{RoutineName}Errors found in getting input.")


def InitAirMixer(state, MixerNum: int):
    mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    for NodeNum in range(1, mixer.NumInletNodes + 1):
        inletNode = state.dataLoopNodes.Node[mixer.InletNode[NodeNum - 1]]
        mixer.InletMassFlowRate[NodeNum - 1] = inletNode.MassFlowRate
        mixer.InletMassFlowRateMaxAvail[NodeNum - 1] = inletNode.MassFlowRateMaxAvail
        mixer.InletMassFlowRateMinAvail[NodeNum - 1] = inletNode.MassFlowRateMinAvail
        mixer.InletTemp[NodeNum - 1] = inletNode.Temp
        mixer.InletHumRat[NodeNum - 1] = inletNode.HumRat
        mixer.InletEnthalpy[NodeNum - 1] = inletNode.Enthalpy
        mixer.InletPressure[NodeNum - 1] = inletNode.Press


def CalcAirMixer(state, MixerNum: int):
    from Psychrometrics import PsyTdbFnHW

    mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    mixer.OutletMassFlowRate = 0.0
    mixer.OutletMassFlowRateMaxAvail = 0.0
    mixer.OutletMassFlowRateMinAvail = 0.0
    mixer.OutletTemp = 0.0
    mixer.OutletHumRat = 0.0
    mixer.OutletPressure = 0.0
    mixer.OutletEnthalpy = 0.0

    massFlowRateParallelPIULk = 0.0
    massFlowRateHumRatParallelPIULk = 0.0
    massFlowRatePressureParallelPIULk = 0.0
    massFlowRateEnthalpyParallelPIULk = 0.0

    for InletNodeNum in range(1, mixer.NumInletNodes + 1):
        if state.dataPowerInductionUnits.NumParallelPIUs > 0:
            for returnAirPathNum in range(1, len(state.dataZoneEquip.ReturnAirPath) + 1):
                returnAirPath = state.dataZoneEquip.ReturnAirPath[returnAirPathNum - 1]
                returnAirPathCompNumOfComponents = returnAirPath.NumOfComponents
                for returnPathCompNum in range(1, returnAirPathCompNumOfComponents + 1):
                    if (returnAirPath.ComponentName[returnPathCompNum - 1] == mixer.MixerName and
                        returnAirPath.ComponentTypeEnum[returnPathCompNum - 1] == "Mixer"):
                        if state.dataDefineEquipment.AirDistUnit:
                            for airDistUnitNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
                                airDistUnit = state.dataDefineEquipment.AirDistUnit[airDistUnitNum - 1]
                                if airDistUnit.piuLkZoneNum > 0:
                                    airDistUnitZoneNum = airDistUnit.ZoneNum
                                    if airDistUnitZoneNum > 0:
                                        numRetNodes = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum - 1].NumReturnNodes
                                        for retZoneAirNodeNum in range(1, numRetNodes + 1):
                                            retZoneAirNode = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum - 1].ReturnNodeAirLoopNum[retZoneAirNodeNum - 1]
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
            noLeakMassFlowRate = mixer.OutletMassFlowRate
            totMassFlowRate = noLeakMassFlowRate + massFlowRateParallelPIULk

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


def UpdateAirMixer(state, MixerNum: int):
    mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]

    outletNode = state.dataLoopNodes.Node[mixer.OutletNode]
    inletNode = state.dataLoopNodes.Node[mixer.InletNode[0]]

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


def ReportMixer(MixerNum: int):
    pass


def GetZoneMixerIndex(state, MixerName: str, MixerIndex: List[int], ErrorsFound: List[bool], ThisObjectType: str = ""):
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False

    from Util import FindItemInList
    MixerIndex[0] = FindItemInList(MixerName, state.dataMixerComponent.MixerCond,
                                    lambda x: x.MixerName)
    if MixerIndex[0] == 0:
        from UtilityRoutines import ShowSevereError
        if ThisObjectType:
            ShowSevereError(state, f"{ThisObjectType}, GetZoneMixerIndex: Zone Mixer not found={MixerName}")
        else:
            ShowSevereError(state, f"GetZoneMixerIndex: Zone Mixer not found={MixerName}")
        ErrorsFound[0] = True


def getZoneMixerIndexFromInletNode(state, InNodeNum: int) -> int:
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False

    if state.dataMixerComponent.NumMixers > 0:
        for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
            mixer = state.dataMixerComponent.MixerCond[MixerNum - 1]
            for InNodeCtr in range(1, mixer.NumInletNodes + 1):
                if InNodeNum == mixer.InletNode[InNodeCtr - 1]:
                    return MixerNum

    return 0
