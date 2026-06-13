from .Data.BaseData import BaseGlobalStruct
from .DataGlobals import *
from .EPVector import EPVector
from .EnergyPlus import *
from .Data.EnergyPlusData import EnergyPlusData
from .DataContaminantBalance import *
from .DataDefineEquip import *
from DataEnvironment import *
from .DataLoopNode import Node
from DataZoneEquipment import *
from .InputProcessing.InputProcessor import *
from NodeInputManager import GetOnlySingleNode
from PoweredInductionUnits import *
from Psychrometrics import PsyTdbFnHW
from UtilityRoutines import ShowFatalError, ShowSevereError, ShowContinueError, FindItemInList as Util_FindItemInList
from ObjexxFCL.Fmath import max as ObjexxFCL_max

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

    def __init__(inout self):
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

struct MixerComponentData(BaseGlobalStruct):
    var NumMixers: Int = 0
    var LoopInletNode: Int = 0
    var LoopOutletNode: Int = 0
    var SimAirMixerInputFlag: Bool = True
    var GetZoneMixerIndexInputFlag: Bool = True
    var CheckEquipName: List[Bool]
    var MixerCond: EPVector[MixerConditions]

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.NumMixers = 0
        self.LoopInletNode = 0
        self.LoopOutletNode = 0
        self.GetZoneMixerIndexInputFlag = True
        self.SimAirMixerInputFlag = True
        self.CheckEquipName = List[Bool]()
        self.MixerCond = EPVector[MixerConditions]()

def SimAirMixer(inout state: EnergyPlusData, CompName: String, inout CompIndex: Int):
    var MixerNum: Int
    if state.dataMixerComponent.SimAirMixerInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.SimAirMixerInputFlag = False
    if CompIndex == 0:
        MixerNum = Util_FindItemInList(CompName, state.dataMixerComponent.MixerCond, &MixerConditions.MixerName)
        if MixerNum == 0:
            ShowFatalError(state, String.format("SimAirLoopMixer: Mixer not found={}", CompName))
        CompIndex = MixerNum
    else:
        MixerNum = CompIndex
        if MixerNum > state.dataMixerComponent.NumMixers or MixerNum < 1:
            ShowFatalError(state,
                           String.format("SimAirLoopMixer: Invalid CompIndex passed={}, Number of Mixers={}, Mixer name={}",
                                         MixerNum,
                                         state.dataMixerComponent.NumMixers,
                                         CompName))
        if state.dataMixerComponent.CheckEquipName[MixerNum-1]:
            if CompName != state.dataMixerComponent.MixerCond[MixerNum-1].MixerName:
                ShowFatalError(state,
                               String.format("SimAirLoopMixer: Invalid CompIndex passed={}, Mixer name={}, stored Mixer Name for that index={}",
                                             MixerNum,
                                             CompName,
                                             state.dataMixerComponent.MixerCond[MixerNum-1].MixerName))
            state.dataMixerComponent.CheckEquipName[MixerNum-1] = False
    InitAirMixer(state, MixerNum)
    CalcAirMixer(state, MixerNum)
    UpdateAirMixer(state, MixerNum)
    ReportMixer(MixerNum)

def GetMixerInput(inout state: EnergyPlusData):
    var RoutineName: StringLiteral = "GetMixerInput: "
    var MixerNum: Int
    var NumAlphas: Int
    var NumNums: Int
    var NodeNum: Int
    var IOStat: Int
    var ErrorsFound: Bool = False
    var NumParams: Int
    var InNodeNum1: Int
    var InNodeNum2: Int
    var CurrentModuleObject: String = "AirLoopHVAC:ZoneMixer"
    var AlphArray: List[String] = List[String]()
    var cAlphaFields: List[String] = List[String]()
    var cNumericFields: List[String] = List[String]()
    var NumArray: List[Float64] = List[Float64]()
    var lAlphaBlanks: List[Bool] = List[Bool]()
    var lNumericBlanks: List[Bool] = List[Bool]()
    CurrentModuleObject = "AirLoopHVAC:ZoneMixer"
    state.dataMixerComponent.NumMixers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    if state.dataMixerComponent.NumMixers > 0:
        state.dataMixerComponent.MixerCond = EPVector[MixerConditions](state.dataMixerComponent.NumMixers)
    state.dataMixerComponent.CheckEquipName = List[Bool](state.dataMixerComponent.NumMixers, True)
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNums)
    AlphArray = List[String](NumAlphas)
    cAlphaFields = List[String](NumAlphas)
    lAlphaBlanks = List[Bool](NumAlphas, True)
    cNumericFields = List[String](NumNums)
    lNumericBlanks = List[Bool](NumNums, True)
    NumArray = List[Float64](NumNums, 0.0)
    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 CurrentModuleObject,
                                                                 MixerNum,
                                                                 AlphArray,
                                                                 NumAlphas,
                                                                 NumArray,
                                                                 NumNums,
                                                                 IOStat,
                                                                 lNumericBlanks,
                                                                 lAlphaBlanks,
                                                                 cAlphaFields,
                                                                 cNumericFields)
        var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
        mixer.MixerName = AlphArray[0]  # 0-based
        mixer.OutletNode = GetOnlySingleNode(state,
                                             AlphArray[1],
                                             ErrorsFound,
                                             Node.ConnectionObjectType.AirLoopHVACZoneMixer,
                                             AlphArray[0],
                                             Node.FluidType.Air,
                                             Node.ConnectionType.Outlet,
                                             Node.CompFluidStream.Primary,
                                             Node.ObjectIsNotParent)
        mixer.NumInletNodes = NumAlphas - 2
        for e in state.dataMixerComponent.MixerCond:
            e.InitFlag = True
        mixer.InletNode = List[Int](mixer.NumInletNodes)
        mixer.InletMassFlowRate = List[Float64](mixer.NumInletNodes)
        mixer.InletMassFlowRateMaxAvail = List[Float64](mixer.NumInletNodes)
        mixer.InletMassFlowRateMinAvail = List[Float64](mixer.NumInletNodes)
        mixer.InletTemp = List[Float64](mixer.NumInletNodes)
        mixer.InletHumRat = List[Float64](mixer.NumInletNodes)
        mixer.InletEnthalpy = List[Float64](mixer.NumInletNodes)
        mixer.InletPressure = List[Float64](mixer.NumInletNodes)
        for i in range(mixer.NumInletNodes):
            mixer.InletNode[i] = 0
            mixer.InletMassFlowRate[i] = 0.0
            mixer.InletMassFlowRateMaxAvail[i] = 0.0
            mixer.InletMassFlowRateMinAvail[i] = 0.0
            mixer.InletTemp[i] = 0.0
            mixer.InletHumRat[i] = 0.0
            mixer.InletEnthalpy[i] = 0.0
            mixer.InletPressure[i] = 0.0
        mixer.OutletMassFlowRate = 0.0
        mixer.OutletMassFlowRateMaxAvail = 0.0
        mixer.OutletMassFlowRateMinAvail = 0.0
        mixer.OutletTemp = 0.0
        mixer.OutletHumRat = 0.0
        mixer.OutletEnthalpy = 0.0
        mixer.OutletPressure = 0.0
        for NodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.InletNode[NodeNum-1] = GetOnlySingleNode(state,
                                                         AlphArray[1 + NodeNum], # 0-based: index = (2+NodeNum) -1 = 1+NodeNum
                                                         ErrorsFound,
                                                         Node.ConnectionObjectType.AirLoopHVACZoneMixer,
                                                         AlphArray[0],
                                                         Node.FluidType.Air,
                                                         Node.ConnectionType.Inlet,
                                                         Node.CompFluidStream.Primary,
                                                         Node.ObjectIsNotParent)
            if lAlphaBlanks[1 + NodeNum]: # 0-based
                ShowSevereError(state, String.format("{} is Blank, {} = {}", cAlphaFields[1 + NodeNum], CurrentModuleObject, AlphArray[0]))
                ErrorsFound = True
    for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
        var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
        NodeNum = mixer.OutletNode
        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            if NodeNum != mixer.InletNode[InNodeNum1-1]:
                continue
            ShowSevereError(state,
                            String.format("{} = {} specifies an inlet node name the same as the outlet node.", CurrentModuleObject, mixer.MixerName))
            ShowContinueError(state, String.format("..{} = {}", cAlphaFields[1], state.dataLoopNodes.NodeID[NodeNum-1]))
            ShowContinueError(state, String.format("..Inlet Node #{} is duplicate.", InNodeNum1))
            ErrorsFound = True
        for InNodeNum1 in range(1, mixer.NumInletNodes + 1):
            for InNodeNum2 in range(InNodeNum1 + 1, mixer.NumInletNodes + 1):
                if mixer.InletNode[InNodeNum1-1] != mixer.InletNode[InNodeNum2-1]:
                    continue
                ShowSevereError(state,
                                String.format("{} = {} specifies duplicate inlet nodes in its inlet node list.", CurrentModuleObject, mixer.MixerName))
                ShowContinueError(state, String.format("..Inlet Node #{} Name={}", InNodeNum1, state.dataLoopNodes.NodeID[InNodeNum1-1]))
                ShowContinueError(state, String.format("..Inlet Node #{} is duplicate.", InNodeNum2))
                ErrorsFound = True
    AlphArray = List[String]()
    NumArray = List[Float64]()
    cAlphaFields = List[String]()
    lAlphaBlanks = List[Bool]()
    cNumericFields = List[String]()
    lNumericBlanks = List[Bool]()
    if ErrorsFound:
        ShowFatalError(state, String.format("{}Errors found in getting input.", RoutineName))

def InitAirMixer(inout state: EnergyPlusData, MixerNum: Int):
    var NodeNum: Int
    var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
    for NodeNum in range(1, mixer.NumInletNodes + 1):
        var inletNode = state.dataLoopNodes.Node[mixer.InletNode[NodeNum-1]-1]  # Node indexing is 1-based in C++, assume 0-based here
        mixer.InletMassFlowRate[NodeNum-1] = inletNode.MassFlowRate
        mixer.InletMassFlowRateMaxAvail[NodeNum-1] = inletNode.MassFlowRateMaxAvail
        mixer.InletMassFlowRateMinAvail[NodeNum-1] = inletNode.MassFlowRateMinAvail
        mixer.InletTemp[NodeNum-1] = inletNode.Temp
        mixer.InletHumRat[NodeNum-1] = inletNode.HumRat
        mixer.InletEnthalpy[NodeNum-1] = inletNode.Enthalpy
        mixer.InletPressure[NodeNum-1] = inletNode.Press

def CalcAirMixer(inout state: EnergyPlusData, inout MixerNum: Int):
    var InletNodeNum: Int
    var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
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
                var returnAirPath = state.dataZoneEquip.ReturnAirPath[returnAirPathNum-1]
                var returnAirPathCompNumOfComponents = returnAirPath.NumOfComponents
                for returnPathCompNum in range(1, returnAirPathCompNumOfComponents + 1):
                    if returnAirPath.ComponentName[returnPathCompNum-1] == mixer.MixerName and \
                       returnAirPath.ComponentTypeEnum[returnPathCompNum-1] == DataZoneEquipment.AirLoopHVACZone.Mixer:
                        if not state.dataDefineEquipment.AirDistUnit.empty():
                            for airDistUnitNum in range(1, len(state.dataDefineEquipment.AirDistUnit) + 1):
                                var airDistUnit = state.dataDefineEquipment.AirDistUnit[airDistUnitNum-1]
                                if airDistUnit.piuLkZoneNum > 0:
                                    var airDistUnitZoneNum = airDistUnit.ZoneNum
                                    if airDistUnitZoneNum > 0:
                                        var numRetNodes = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum-1].NumReturnNodes
                                        for retZoneAirNodeNum in range(1, numRetNodes + 1):
                                            var retZoneAirNode = state.dataZoneEquip.ZoneEquipConfig[airDistUnitZoneNum-1].ReturnNodeAirLoopNum[retZoneAirNodeNum-1]
                                            if retZoneAirNode == InletNodeNum:
                                                massFlowRateParallelPIULk += airDistUnit.massFlowRateParallelPIULk
                                                massFlowRateHumRatParallelPIULk += airDistUnit.massFlowRateParallelPIULk * \
                                                                                   state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum-1].HumRat
                                                massFlowRatePressureParallelPIULk += \
                                                    airDistUnit.massFlowRateParallelPIULk * state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum-1].Press
                                                massFlowRateEnthalpyParallelPIULk += airDistUnit.massFlowRateParallelPIULk * \
                                                                                     state.dataLoopNodes.Node[airDistUnit.piuLkZoneNum-1].Enthalpy
        mixer.OutletMassFlowRate += mixer.InletMassFlowRate[InletNodeNum-1]
        mixer.OutletMassFlowRateMaxAvail += mixer.InletMassFlowRateMaxAvail[InletNodeNum-1]
        mixer.OutletMassFlowRateMinAvail += mixer.InletMassFlowRateMinAvail[InletNodeNum-1]
    if mixer.OutletMassFlowRate > 0.0:
        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletHumRat += mixer.InletMassFlowRate[InletNodeNum-1] * mixer.InletHumRat[InletNodeNum-1] / mixer.OutletMassFlowRate
        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletPressure += mixer.InletPressure[InletNodeNum-1] * mixer.InletMassFlowRate[InletNodeNum-1] / mixer.OutletMassFlowRate
        for InletNodeNum in range(1, mixer.NumInletNodes + 1):
            mixer.OutletEnthalpy += mixer.InletEnthalpy[InletNodeNum-1] * mixer.InletMassFlowRate[InletNodeNum-1] / mixer.OutletMassFlowRate
        if massFlowRateParallelPIULk > 0:
            var noLeakMassFlowRate = mixer.OutletMassFlowRate
            var totMassFlowRate = noLeakMassFlowRate + massFlowRateParallelPIULk
            mixer.OutletHumRat = (noLeakMassFlowRate * mixer.OutletHumRat + massFlowRateHumRatParallelPIULk) / totMassFlowRate
            mixer.OutletPressure = (noLeakMassFlowRate * mixer.OutletPressure + massFlowRatePressureParallelPIULk) / totMassFlowRate
            mixer.OutletEnthalpy = (noLeakMassFlowRate * mixer.OutletEnthalpy + massFlowRateEnthalpyParallelPIULk) / totMassFlowRate
            mixer.OutletMassFlowRate = totMassFlowRate
        mixer.OutletTemp = PsyTdbFnHW(mixer.OutletEnthalpy, mixer.OutletHumRat)
    else:
        mixer.OutletHumRat = mixer.InletHumRat[0]
        mixer.OutletPressure = mixer.InletPressure[0]
        mixer.OutletEnthalpy = mixer.InletEnthalpy[0]
        mixer.OutletTemp = mixer.InletTemp[0]
    mixer.OutletMassFlowRateMaxAvail = ObjexxFCL_max(mixer.OutletMassFlowRateMaxAvail, mixer.OutletMassFlowRate)

def UpdateAirMixer(inout state: EnergyPlusData, MixerNum: Int):
    var InletNodeNum: Int
    var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
    var outletNode = state.dataLoopNodes.Node[mixer.OutletNode-1]
    var inletNode = state.dataLoopNodes.Node[mixer.InletNode[0]-1]  # For now use first inlet node
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
                outletNode.CO2 += \
                    state.dataLoopNodes.Node[mixer.InletNode[InletNodeNum-1]-1].CO2 * mixer.InletMassFlowRate[InletNodeNum-1] / mixer.OutletMassFlowRate
        else:
            outletNode.CO2 = inletNode.CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        if mixer.OutletMassFlowRate > 0.0:
            outletNode.GenContam = 0.0
            for InletNodeNum in range(1, mixer.NumInletNodes + 1):
                outletNode.GenContam += state.dataLoopNodes.Node[mixer.InletNode[InletNodeNum-1]-1].GenContam * mixer.InletMassFlowRate[InletNodeNum-1] / \
                                        mixer.OutletMassFlowRate
        else:
            outletNode.GenContam = inletNode.GenContam

def ReportMixer(MixerNum: Int):

def GetZoneMixerIndex(inout state: EnergyPlusData, MixerName: String, inout MixerIndex: Int, inout ErrorsFound: Bool, ThisObjectType: String = ""):
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False
    MixerIndex = Util_FindItemInList(MixerName, state.dataMixerComponent.MixerCond, &MixerConditions.MixerName)
    if MixerIndex == 0:
        if ThisObjectType != "":
            ShowSevereError(state, String.format("{}, GetZoneMixerIndex: Zone Mixer not found={}", ThisObjectType, MixerName))
        else:
            ShowSevereError(state, String.format("GetZoneMixerIndex: Zone Mixer not found={}", MixerName))
        ErrorsFound = True

def getZoneMixerIndexFromInletNode(inout state: EnergyPlusData, InNodeNum: Int) -> Int:
    if state.dataMixerComponent.GetZoneMixerIndexInputFlag:
        GetMixerInput(state)
        state.dataMixerComponent.GetZoneMixerIndexInputFlag = False
    if state.dataMixerComponent.NumMixers > 0:
        for MixerNum in range(1, state.dataMixerComponent.NumMixers + 1):
            var mixer = state.dataMixerComponent.MixerCond[MixerNum-1]
            for InNodeCtr in range(1, mixer.NumInletNodes + 1):
                if InNodeNum == mixer.InletNode[InNodeCtr-1]:
                    return MixerNum
    return 0