# DuctLoss.mojo - Faithful 1:1 translation of EnergyPlus DuctLoss.cc

from .AirflowNetwork.src.Solver import (Solver, AirflowNetworkCompData, AirflowNetworkLinkageData, AirflowNetworkNodeData, AirflowNetworkNodeSimu, AirflowNetworkLinkSimu, DisSysCompDuctData, DisSysCompELRData, DisSysNodeData)
from .Data.EnergyPlusData import EnergyPlusData
from .DataContaminantBalance import (ContaminantBalance, ContaminantData)
from .DataDefineEquip import (DataDefineEquipment, AirDistUnit)
from DataHeatBalance import (Zone, HeatBalanceData)
from .DataLoopNode import (NodeData, LoopNodes)
from DataZoneEquipment import (ZoneEquipConfig, ZoneEquipmentData)
from .InputProcessing.InputProcessor import InputProcessor
from MixerComponent import MixerComponent
from OutputProcessor import OutputProcessor, SetupOutputVariable
from Psychrometrics import (PsyCpAirFnW, PsyHFnTdbW, PsyRhoFnTdbW)
from ScheduleManager import ScheduleManager as Sched
from SplitterComponent import SplitterComponent
from UtilityRoutines import (makeUPPER, SameString, FindItemInList, Format as UtilFormat)
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from .DataGlobals import (DataGlobals, Constants, General, Psychrometrics as PsyGlob)
from .Data.BaseData import BaseGlobalStruct
from .EnergyPlus import EnergyPlus as EP
from .Autosizing.Base import Base as AutoSizeBase

from ObjexxFCL.Array1D import DynamicVector

# Import needed for string_view constants
from builtin import String, StringLiteral

# Enums - exact names and values
enum EnvironmentType: Int32 {
    Invalid = -1,
    Zone = 0,
    Schedule = 1,
    Num = 2
}

enum DuctLossType: Int32 {
    Invalid = -1,
    Conduction = 0,
    Leakage = 1,
    MakeupAir = 2,
    Num = 3
}

enum DuctLossSubType: Int32 {
    Invalid = -1,
    SupplyBranch = 0,
    SupplyTrunk = 1,
    ReturnBranch = 2,
    ReturnTrunk = 3,
    SupLeakTrunk = 4,
    SupLeakBranch = 5,
    RetLeakTrunk = 6,
    RetLeakBranch = 7,
    Num = 8
}

enum AirPath: Int32 {
    Invalid = -1,
    Supply = 0,
    Return = 1,
    Num = 2
}

# Global constants (string_view -> let)
let cCMO_DuctLossConduction: String = "Duct:Loss:Conduction"
let cCMO_DuctLossLeakage: String = "Duct:Loss:Leakage"
let cCMO_DuctLossMakeupAir: String = "Duct:Loss:MakeupAir"

# Forward declaration of functions (to be defined later)
def SimulateDuctLoss(state: EnergyPlusData, AirPathWay: AirPath = AirPath.Invalid, PathNum: Int32 = 0)
def GetDuctLossInput(state: EnergyPlusData)
def InitDuctLoss(state: EnergyPlusData)
def ReportDuctLoss(state: EnergyPlusData)
def ReturnPathUpdate(state: EnergyPlusData, MixerNum: Int32)
def SupplyPathUpdate(state: EnergyPlusData, SplitterNum: Int32)

# Struct DuctLossComp
struct DuctLossComp:
    var Name: String
    var AirLoopName: String
    var EnvType: EnvironmentType = EnvironmentType.Invalid
    var ZoneName: String = ""
    var ScheduleNameT: String = ""
    var ScheduleNameW: String = ""
    var tambSched: Sched.Schedule? = None # nullable pointer
    var wambSched: Sched.Schedule? = None
    var LossType: DuctLossType = DuctLossType.Invalid
    var AirLoopNum: Int32 = 0
    var LinkageNum: Int32 = 0
    var ZoneNum: Int32 = 0
    var LossSubType: DuctLossSubType = DuctLossSubType.Invalid
    var Qsen: Float64 = 0.0
    var Qlat: Float64 = 0.0
    var QsenSL: Float64 = 0.0
    var QlatSL: Float64 = 0.0
    var RetLeakZoneNum: Int32 = 0

    def __init__(inout self):
        self.Name = String("")
        self.AirLoopName = String("")
        self.EnvType = EnvironmentType.Invalid
        self.ZoneName = String("")
        self.ScheduleNameT = String("")
        self.ScheduleNameW = String("")
        self.tambSched = None
        self.wambSched = None
        self.LossType = DuctLossType.Invalid
        self.AirLoopNum = 0
        self.LinkageNum = 0
        self.ZoneNum = 0
        self.LossSubType = DuctLossSubType.Invalid
        self.Qsen = 0.0
        self.Qlat = 0.0
        self.QsenSL = 0.0
        self.QlatSL = 0.0
        self.RetLeakZoneNum = 0

    def CalcDuctLoss(inout self, state: EnergyPlusData, Index: Int32)
    def CalcConduction(inout self, state: EnergyPlusData)
    def CalcLeakage(inout self, state: EnergyPlusData)
    def CalcMakeupAir(inout self, state: EnergyPlusData)

# Struct DuctLossData (global data)
struct DuctLossData(BaseGlobalStruct):
    var DuctLossSimu: Bool = False
    var NumOfDuctLosses: Int32 = 0
    var GetDuctLossInputFlag: Bool = True
    var AirLoopConnectionFlag: Bool = True
    var AirLoopInNodeNum: Int32 = 0
    var ductloss: DynamicVector[DuctLossComp]
    var ZoneSen: DynamicVector[Float64]
    var ZoneLat: DynamicVector[Float64]
    var SysSen: Float64 = 0.0
    var SysLat: Float64 = 0.0
    var CtrlZoneNum: Int32 = 0
    var SubTypeSimuFlag: DynamicVector[Bool]
    var ZoneEquipInletNodes: DynamicVector[Int32]
    var SplitterNum: Int32 = 0
    var MixerNum: Int32 = 0

    def __init__(inout self):
        self.DuctLossSimu = False
        self.NumOfDuctLosses = 0
        self.GetDuctLossInputFlag = True
        self.AirLoopConnectionFlag = True
        self.AirLoopInNodeNum = 0
        self.ductloss = DynamicVector[DuctLossComp]()
        self.ZoneSen = DynamicVector[Float64]()
        self.ZoneLat = DynamicVector[Float64]()
        self.SysSen = 0.0
        self.SysLat = 0.0
        self.CtrlZoneNum = 0
        self.SubTypeSimuFlag = DynamicVector[Bool]()
        self.ZoneEquipInletNodes = DynamicVector[Int32]()
        self.SplitterNum = 0
        self.MixerNum = 0

    def init_constant_state(borrow self, state: EnergyPlusData):

    def init_state(borrow self, state: EnergyPlusData):

    def clear_state(inout self):
        self.__init__()

# ------------------------------------------------------------
# Implementation of functions

def SimulateDuctLoss(state: EnergyPlusData, AirPathWay: AirPath = AirPath.Invalid, PathNum: Int32 = 0):
    if state.dataDuctLoss.GetDuctLossInputFlag: # First time subroutine has been entered
        GetDuctLossInput(state)
        state.dataDuctLoss.GetDuctLossInputFlag = False

    if PathNum == 0:
        return

    if state.dataAirLoop.AirLoopInputsFilled:
        InitDuctLoss(state)
        if state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate == 0.0:
            # Zero out all loads
            for i in range(len(state.dataDuctLoss.ZoneSen)):
                state.dataDuctLoss.ZoneSen[i] = 0.0
            for i in range(len(state.dataDuctLoss.ZoneLat)):
                state.dataDuctLoss.ZoneLat[i] = 0.0
            for i in range(len(state.dataDuctLoss.ZoneSen)):
                state.dataDuctLoss.ZoneSen[i] = 0.0
            for i in range(len(state.dataDuctLoss.ZoneLat)):
                state.dataDuctLoss.ZoneLat[i] = 0.0
            state.dataDuctLoss.SysSen = 0.0
            state.dataDuctLoss.SysLat = 0.0
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):  # 1-based -> 0-based index
                state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].QsenSL = 0.0
                state.dataDuctLoss.ductloss[DuctLossNum - 1].QlatSL = 0.0
            return

    if not state.dataDuctLoss.AirLoopConnectionFlag and state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate > 0.0:
        if AirPathWay == AirPath.Supply:
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)  # Index is 1-based
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            SupplyPathUpdate(state, PathNum)
            ReportDuctLoss(state)
        elif AirPathWay == AirPath.Return: # Return branch leak
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.RetLeakBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.ReturnBranch:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.RetLeakTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.ReturnTrunk:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
                if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossType == DuctLossType.MakeupAir:
                    state.dataDuctLoss.ductloss[DuctLossNum - 1].CalcDuctLoss(state, DuctLossNum)
            ReturnPathUpdate(state, PathNum)

def GetDuctLossInput(state: EnergyPlusData):
    let RoutineName: String = "GetDuctLossInput: " # include trailing bla
    var CurrentModuleObject: String # for ease in getting objects
    var LinkageName: String # Name of the Duct linkage
    var errorsFound: Bool = False

    var NumDuctLossConduction = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_DuctLossConduction)
    var NumDuctLossLeakage = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_DuctLossLeakage)
    var NumDuctLossMakeupAir = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCMO_DuctLossMakeupAir)

    if NumDuctLossConduction + NumDuctLossLeakage + NumDuctLossMakeupAir == 0:
        return

    var NumOfAirloops = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC")
    if NumOfAirloops == 0:
        ShowSevereError(state, "The simple duct model allows a single AirLoop. No AirLoopHVAC object is found")
        errorsFound = True

    var NumOfSplitters = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:ZoneSplitter")
    if NumOfSplitters == 0:
        ShowSevereError(state, "The simple duct model allows a single AirLoopHVAC:ZoneSplitter. No AirLoopHVAC:ZoneSplitter object is found")
        errorsFound = True
    elif NumOfSplitters > 1:
        ShowSevereError(state,
                        "The simple duct model allows a single AirLoopHVAC:ZoneSplitter. Multiple objects of AirLoopHVAC:ZoneSplitter are found")
        errorsFound = True

    var NumOfMixers = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "AirLoopHVAC:ZoneMixer")
    if NumOfMixers == 0:
        ShowSevereError(state, "The simple duct model allows a single AirLoopHVAC:ZoneMixers. No AirLoopHVAC:ZoneNumOfMixer object is found")
        errorsFound = True
    elif NumOfMixers > 1:
        ShowSevereError(state,
                        "The simple duct model allows a single AirLoopHVAC:ZonefMixer. Multiple objects of AirLoopHVAC:ZoneMixer are found")
        errorsFound = True

    if errorsFound:
        ShowFatalError(state, "GetDuctLossLeakageInput: Previous errors cause termination.")

    CurrentModuleObject = "Duct:Loss:Conduction"
    var instances = state.dataInputProcessing.inputProcessor.epJSON.find(CurrentModuleObject)
    if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
        var DuctLossCondNum: Int32 = 0
        var instancesValue = instances.value()
        for instance in instancesValue.begin() to instancesValue.end():
            var thisObjectName = instance.key()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(CurrentModuleObject, thisObjectName)
            DuctLossCondNum = DuctLossCondNum + 1
            var thisDuctLoss: DuctLossComp
            thisDuctLoss.Name = makeUPPER(thisObjectName)
            var fields = instance.value()
            thisDuctLoss.AirLoopName = makeUPPER(fields["airloophvac_name"].get[String]())
            LinkageName = makeUPPER(fields["airflownetwork_distribution_linkage_name"].get[String]())
            thisDuctLoss.LinkageNum = FindItemInList(LinkageName, state.afn.AirflowNetworkLinkageData)
            if thisDuctLoss.LinkageNum == 0:
                ShowSevereError(state,
                                "{}, \"{}\" {} not found: {}".format(CurrentModuleObject, thisDuctLoss.Name, "Airflownetwork:Distribution:Linkage = ", LinkageName))
                errorsFound = True

            var EnvType = makeUPPER(fields["environment_type"].get[String]())
            if SameString(EnvType, "SCHEDULE"):
                thisDuctLoss.EnvType = EnvironmentType.Schedule
            elif SameString(EnvType, "ZONE"):
                thisDuctLoss.EnvType = EnvironmentType.Zone
            else:
                ShowSevereError(state,
                                "{}, \"{}\" {} not found: {}".format(CurrentModuleObject, thisDuctLoss.Name, "Environment Type = ", EnvType))
                errorsFound = True

            if thisDuctLoss.EnvType == EnvironmentType.Schedule:
                thisDuctLoss.ScheduleNameT = makeUPPER(fields["ambient_temperature_schedule_name"].get[String]())
                var schedT = Sched.GetSchedule(state, thisDuctLoss.ScheduleNameT)
                if schedT == None:
                    # ErrorObjectHeader eoh{RoutineName, CurrentModuleObject, thisDuctLoss.ScheduleNameT};
                    ShowSevereItemNotFound(state, RoutineName, CurrentModuleObject, thisDuctLoss.ScheduleNameT, "ambient_temperature_schedule_name")
                    errorsFound = True
                thisDuctLoss.tambSched = schedT
                thisDuctLoss.ScheduleNameW = makeUPPER(fields["ambient_humidity_ratio_schedule_name"].get[String]())
                var schedW = Sched.GetSchedule(state, thisDuctLoss.ScheduleNameW)
                if schedW == None:
                    ShowSevereItemNotFound(state, RoutineName, CurrentModuleObject, thisDuctLoss.ScheduleNameW, "ambient_humidity_ratio_schedule_name")
                    errorsFound = True
                thisDuctLoss.wambSched = schedW

            if thisDuctLoss.EnvType == EnvironmentType.Zone:
                thisDuctLoss.ZoneName = makeUPPER(fields["ambient_zone_name"].get[String]())
                thisDuctLoss.ZoneNum = FindItemInList(thisDuctLoss.ZoneName, state.dataHeatBal.Zone)

            thisDuctLoss.LossType = DuctLossType.Conduction
            state.dataDuctLoss.ductloss.append(thisDuctLoss)

        if errorsFound:
            ShowFatalError(state, "GetDuctLossConductionInput: Previous errors cause termination.")
        state.dataDuctLoss.NumOfDuctLosses = DuctLossCondNum

    CurrentModuleObject = "Duct:Loss:Leakage"
    instances = state.dataInputProcessing.inputProcessor.epJSON.find(CurrentModuleObject)
    if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
        var DuctLossLeakNum: Int32 = 0
        var instancesValue = instances.value()
        for instance in instancesValue.begin() to instancesValue.end():
            var thisObjectName = instance.key()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(CurrentModuleObject, thisObjectName)
            DuctLossLeakNum = DuctLossLeakNum + 1
            var thisDuctLoss: DuctLossComp
            thisDuctLoss.Name = makeUPPER(thisObjectName)
            var fields = instance.value()
            thisDuctLoss.AirLoopName = makeUPPER(fields["airloophvac_name"].get[String]())
            LinkageName = makeUPPER(fields["airflownetwork_distribution_linkage_name"].get[String]())
            thisDuctLoss.LinkageNum = FindItemInList(LinkageName, state.afn.AirflowNetworkLinkageData)
            if thisDuctLoss.LinkageNum == 0:
                ShowSevereError(state,
                                "{}, \"{}\" {} not found: {}".format(CurrentModuleObject, thisDuctLoss.Name, "Airflownetwork:Distribution:Linkage = ", LinkageName))
                errorsFound = True
            thisDuctLoss.LossType = DuctLossType.Leakage
            state.dataDuctLoss.ductloss.append(thisDuctLoss)

        state.dataDuctLoss.NumOfDuctLosses = state.dataDuctLoss.NumOfDuctLosses + DuctLossLeakNum
        if errorsFound:
            ShowFatalError(state, "GetDuctLossLeakageInput: Previous errors cause termination.")

    CurrentModuleObject = "Duct:Loss:MakeupAir"
    instances = state.dataInputProcessing.inputProcessor.epJSON.find(CurrentModuleObject)
    if instances != state.dataInputProcessing.inputProcessor.epJSON.end():
        var DuctLossMakeNum: Int32 = 0
        var instancesValue = instances.value()
        for instance in instancesValue.begin() to instancesValue.end():
            var thisObjectName = instance.key()
            state.dataInputProcessing.inputProcessor.markObjectAsUsed(CurrentModuleObject, thisObjectName)
            DuctLossMakeNum = DuctLossMakeNum + 1
            var thisDuctLoss: DuctLossComp
            thisDuctLoss.Name = makeUPPER(thisObjectName)
            var fields = instance.value()
            thisDuctLoss.AirLoopName = makeUPPER(fields["airloophvac_name"].get[String]())
            LinkageName = makeUPPER(fields["airflownetwork_distribution_linkage_name"].get[String]())
            thisDuctLoss.LinkageNum = FindItemInList(LinkageName, state.afn.AirflowNetworkLinkageData)
            if thisDuctLoss.LinkageNum == 0:
                ShowSevereError(state,
                                "{}, \"{}\" {} not found: {}".format(CurrentModuleObject, thisDuctLoss.Name, "Airflownetwork:Distribution:Linkage = ", LinkageName))
                errorsFound = True
            thisDuctLoss.LossType = DuctLossType.MakeupAir
            state.dataDuctLoss.ductloss.append(thisDuctLoss)

        state.dataDuctLoss.NumOfDuctLosses = state.dataDuctLoss.NumOfDuctLosses + DuctLossMakeNum
        if errorsFound:
            ShowFatalError(state, "GetDuctLossMakeupAirInput: Previous errors cause termination.")

    if state.afn.AirflowNetworkGetInputFlag:
        state.afn.get_input()
        state.afn.AirflowNetworkGetInputFlag = False

    var airLoopFound: Bool = True
    for DuctLossNum in range(2, state.dataDuctLoss.NumOfDuctLosses + 1):
        if not SameString(state.dataDuctLoss.ductloss[0].AirLoopName, state.dataDuctLoss.ductloss[DuctLossNum - 1].AirLoopName):
            airLoopFound = False

    if not airLoopFound:
        ShowSevereError(state, "Multiple AirLoopHVAC names are found. A single AirLoopHVAC is required")
        ShowFatalError(state, "GetDuctLossMakeupAirInput: Previous errors cause termination.")

    state.dataDuctLoss.SplitterNum = 1
    state.dataDuctLoss.MixerNum = 1
    state.dataDuctLoss.ZoneSen.allocate(state.dataGlobal.NumOfZones)
    state.dataDuctLoss.ZoneLat.allocate(state.dataGlobal.NumOfZones)
    state.dataDuctLoss.SubTypeSimuFlag.dimension(8, False)

    state.afn.AirflowNetworkNodeSimu.allocate(state.afn.AirflowNetworkNumOfNodes) # Node simulation variable in air distribution system
    state.afn.AirflowNetworkLinkSimu.allocate(state.afn.AirflowNetworkNumOfLinks) # Link simulation variable in air distribution system

    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        SetupOutputVariable(state,
                            "Duct Loss Node Temperature",
                            Constants.Units.C,
                            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.afn.AirflowNetworkNodeData[NodeNum - 1].Name)
        SetupOutputVariable(state,
                            "Duct Loss Node Humidity Ratio",
                            Constants.Units.kgWater_kgDryAir,
                            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.afn.AirflowNetworkNodeData[NodeNum - 1].Name)

    for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
        SetupOutputVariable(state,
                            "Duct Loss Sensible Loss Rate",
                            Constants.Units.W,
                            state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataDuctLoss.ductloss[DuctLossNum - 1].Name)
        SetupOutputVariable(state,
                            "Duct Loss Latent Loss Rate",
                            Constants.Units.kgWater_s,
                            state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataDuctLoss.ductloss[DuctLossNum - 1].Name)

    for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
        SetupOutputVariable(state,
                            "Zone Added Sensible Rate Due to Duct Loss",
                            Constants.Units.W,
                            state.dataDuctLoss.ZoneSen[ZoneNum - 1],
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataHeatBal.Zone[ZoneNum - 1].Name)
        SetupOutputVariable(state,
                            "Zone Added Latent Rate Due to Duct Loss",
                            Constants.Units.kgWater_s,
                            state.dataDuctLoss.ZoneLat[ZoneNum - 1],
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataHeatBal.Zone[ZoneNum - 1].Name)

    if state.dataDuctLoss.NumOfDuctLosses > 0:
        state.dataDuctLoss.DuctLossSimu = True

def DuctLossComp.CalcDuctLoss(inout self, state: EnergyPlusData, Index: Int32):
    var thisDuctComp = state.dataDuctLoss.ductloss[Index - 1]  # Index is 1-based
    # Note: self refers to the same object as thisDuctComp? In original code, it's called on the object itself.
    # We'll use self directly but the original uses 'thisDuctComp' variable, so we keep as is.
    # However, we need to dispatch on loss type. The original uses self->CalcConduction etc.
    # We'll call the appropriate method on self (since self is the same as thisDuctComp).
    # But to match exactly, we'll switch on self.LossType.
    if self.LossType == DuctLossType.Conduction:
        self.CalcConduction(state)
    elif self.LossType == DuctLossType.Leakage:
        self.CalcLeakage(state)
    elif self.LossType == DuctLossType.MakeupAir:
        self.CalcMakeupAir(state)
    # default: break

def DuctLossComp.CalcConduction(inout self, state: EnergyPlusData):
    var MassFlowRate: Float64
    var Tamb: Float64
    var Wamb: Float64
    var Tin: Float64
    var Tout: Float64
    var Win: Float64
    var Wout: Float64
    var CpAir: Float64
    var enthalpy: Float64
    var NodeNum1: Int32
    var NodeNum2: Int32
    var NodeNum: Int32

    var TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
    var DuctSurfArea = state.afn.DisSysCompDuctData[TypeNum - 1].L * state.afn.DisSysCompDuctData[TypeNum - 1].hydraulicDiameter * Constants.Pi
    var UThermal = state.afn.DisSysCompDuctData[TypeNum - 1].UThermConduct
    var UMoisture = state.afn.DisSysCompDuctData[TypeNum - 1].UMoisture

    self.Qsen = 0.0
    self.Qlat = 0.0

    if self.EnvType == EnvironmentType.Zone and self.ZoneNum > 0:
        Tamb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneNum - 1].MAT
        Wamb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.ZoneNum - 1].airHumRat
    else:
        # Assuming tambSched and wambSched are not None
        Tamb = self.tambSched.getCurrentVal()
        Wamb = self.wambSched.getCurrentVal()

    NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]  # 0-based in C++? Actually NodeNums[0] and [1] are 0-based in C++ array
    NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]

    if self.LossSubType == DuctLossSubType.SupplyTrunk:
        NodeNum = state.afn.DisSysNodeData[NodeNum1 - 1].EPlusNodeNum
        MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
        Tin = state.dataLoopNodes.Node[NodeNum - 1].Temp
        Win = state.dataLoopNodes.Node[NodeNum - 1].HumRat
        state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ = Tin
        state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ = Win
        CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
        Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir))
        Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
        self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir)))
        self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout

        if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch) + 1 - 1]: # +1 because enum value? Actually DuctLossSubType.SupplyBranch = 0, +1 -> 1, but SubTypeSimuFlag index is 0-based. We need to adjust.
            # Original uses int(DuctLossSubType::SupplyBranch) + 1 as index into SubTypeSimuFlag (0-based? Actually C++ Array1D<bool> is 1-based, so they add 1. In Mojo we need 0-based, so we use int(DuctLossSubType.SupplyBranch) (which is 0) => index 0.
            # But careful: They also have SubTypeSimuFlag declared with dimension(8, false). They assign to indices 1..8. We'll maintain 0-based by using DuctLossSubType enum value directly.
            # Let's check: In C++, SubTypeSimuFlag(int(DuctLossSubType::SupplyBranch) + 1) = true; For SupplyBranch=0, index 1. So in Mojo we need index 0.
            # So we'll use int(DuctLossSubType.SupplyBranch) without +1.
            if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch)]:
                enthalpy = PsyHFnTdbW(Tout, Wout)
                for OutNodeNum in range(1, state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].NumOutletNodes + 1):
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].Temp = Tout
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].HumRat = Wout
                    state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1] - 1].Enthalpy = enthalpy
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].Temp = Tout
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].HumRat = Wout
                    state.dataLoopNodes.Node[state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] - 1].Enthalpy = enthalpy

    elif self.LossSubType == DuctLossSubType.SupplyBranch:
        NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
        MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
        if state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk)]: # SupplyTrunk=1, index 1 in C++? Actually SupplyTrunk=1, in C++ they use +1 => index 2. But we need 0-based: index 1. We'll use int(DuctLossSubType.SupplyTrunk) as index.
            Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
            Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
        else:
            Tin = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].Temp
            Win = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].HumRat
        CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
        Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir))
        Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
        self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir)))
        self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout

    elif self.LossSubType == DuctLossSubType.ReturnTrunk:
        NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
        MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
        if state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnBranch)]: # ReturnBranch=2, index 2 in C++? Actually ReturnBranch=2, C++ +1 -> index 3. Mojo index 2.
            Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
            Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
        else:
            Tin = state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletTemp
            Win = state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletHumRat
        CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
        Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir))
        Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
        self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir)))
        self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout

    elif self.LossSubType == DuctLossSubType.ReturnBranch:
        NodeNum = state.afn.DisSysNodeData[NodeNum1 - 1].EPlusNodeNum
        MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
        Tin = state.dataLoopNodes.Node[NodeNum - 1].Temp
        state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ = Tin
        Win = state.dataLoopNodes.Node[NodeNum - 1].HumRat
        state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ = Win
        CpAir = PsyCpAirFnW(state.dataLoopNodes.Node[NodeNum - 1].HumRat)
        Tout = Tamb + (Tin - Tamb) * General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir))
        Wout = Wamb + (Win - Wamb) * General.epexp(-UMoisture * DuctSurfArea, MassFlowRate)
        self.Qsen = -MassFlowRate * CpAir * (Tamb - Tin) * (1.0 - General.epexp(-UThermal * DuctSurfArea, (MassFlowRate * CpAir)))
        self.Qlat = -MassFlowRate * (Wamb - Win) * (1.0 - General.epexp(-UMoisture * DuctSurfArea, MassFlowRate))
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout

        if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnTrunk)]: # ReturnTrunk=3, C++ index 4, Mojo index 3.
            state.dataLoopNodes.Node[state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletNode - 1].Temp = Tout
            state.dataLoopNodes.Node[state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].OutletNode - 1].HumRat = Wout

    # default: break

def DuctLossComp.CalcLeakage(inout self, state: EnergyPlusData):
    var MassFlowRate: Float64
    var Tin: Float64
    var Tout: Float64
    var Win: Float64
    var Wout: Float64
    var CpAir: Float64
    var NodeNum1: Int32
    var NodeNum2: Int32

    NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]
    NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]

    var TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
    var LeakRatio = state.afn.DisSysCompELRData[TypeNum - 1].ELR

    self.Qsen = 0.0
    self.Qlat = 0.0
    self.QsenSL = 0.0
    self.QlatSL = 0.0

    if self.LossSubType == DuctLossSubType.SupLeakTrunk:
        Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
        Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
        CpAir = PsyCpAirFnW(Win)
        MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
        self.Qsen = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
        self.Qlat = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)
        self.QsenSL = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].MAT)
        self.QlatSL = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].airHumRat)

    elif self.LossSubType == DuctLossSubType.SupLeakBranch:
        Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
        Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
        CpAir = PsyCpAirFnW(Win)
        MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
        self.Qsen = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
        self.Qlat = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)
        self.QsenSL = MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].MAT)
        self.QlatSL = MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataDuctLoss.CtrlZoneNum - 1].airHumRat)

    elif self.LossSubType == DuctLossSubType.RetLeakTrunk:
        MassFlowRate = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate
        Tout = state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT * LeakRatio
        Wout = state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat * LeakRatio
        CpAir = PsyCpAirFnW(Wout)
        self.Qsen = MassFlowRate * CpAir * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT - state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ)
        self.Qlat = MassFlowRate * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat - state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ)
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout

    elif self.LossSubType == DuctLossSubType.RetLeakBranch:
        var NodeNum = state.afn.DisSysNodeData[NodeNum2 - 1].EPlusNodeNum
        MassFlowRate = state.dataLoopNodes.Node[NodeNum - 1].MassFlowRate
        Tout = state.dataLoopNodes.Node[self.RetLeakZoneNum - 1].Temp * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT * LeakRatio
        Wout = state.dataLoopNodes.Node[self.RetLeakZoneNum - 1].HumRat * (1.0 - LeakRatio) + state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat * LeakRatio
        CpAir = PsyCpAirFnW((Wout + state.dataLoopNodes.Node[NodeNum - 1].HumRat) / 2.0)
        self.Qsen = MassFlowRate * CpAir * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].MAT - Tout)
        self.Qlat = MassFlowRate * LeakRatio * (state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1 - 1].EPlusZoneNum - 1].airHumRat - Wout)
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].TZ = Tout
        state.afn.AirflowNetworkNodeSimu[NodeNum2 - 1].WZ = Wout
        state.dataLoopNodes.Node[NodeNum - 1].Temp = Tout
        state.dataLoopNodes.Node[NodeNum - 1].HumRat = Wout

    # default: break

def DuctLossComp.CalcMakeupAir(inout self, state: EnergyPlusData):
    var NodeNum1: Int32
    var NodeNum2: Int32
    var Tin: Float64
    var Win: Float64
    var CpAir: Float64

    NodeNum1 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[0]
    NodeNum2 = state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].NodeNums[1]

    var TypeNum = state.afn.AirflowNetworkCompData[state.afn.AirflowNetworkLinkageData[self.LinkageNum - 1].CompNum - 1].TypeNum
    var LeakRatio = state.afn.DisSysCompELRData[TypeNum - 1].ELR

    self.Qsen = 0.0
    self.Qlat = 0.0

    Tin = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].TZ
    Win = state.afn.AirflowNetworkNodeSimu[NodeNum1 - 1].WZ
    CpAir = PsyCpAirFnW(Win)

    self.Qsen = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate * CpAir * LeakRatio * (Tin - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].MAT)
    self.Qlat = state.dataLoopNodes.Node[state.dataDuctLoss.AirLoopInNodeNum - 1].MassFlowRate * LeakRatio * (Win - state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum - 1].airHumRat)

    var ZoneNum = state.afn.AirflowNetworkNodeData[NodeNum2 - 1].EPlusZoneNum
    if ZoneNum > 0:
        state.dataDuctLoss.ZoneSen[ZoneNum - 1] += self.Qsen
        state.dataDuctLoss.ZoneLat[ZoneNum - 1] += self.Qlat

def InitDuctLoss(state: EnergyPlusData):
    if state.dataDuctLoss.AirLoopConnectionFlag:
        var errorsFound: Bool = False
        var CurrentModuleObject: String
        for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
            var thisDuctLoss = state.dataDuctLoss.ductloss[DuctLossNum - 1]
            thisDuctLoss.AirLoopNum = FindItemInList(thisDuctLoss.AirLoopName, state.dataAirSystemsData.PrimaryAirSystems)
            if thisDuctLoss.LossType == DuctLossType.Conduction:
                CurrentModuleObject = cCMO_DuctLossConduction
            elif thisDuctLoss.LossType == DuctLossType.Leakage:
                CurrentModuleObject = cCMO_DuctLossLeakage
            else:
                CurrentModuleObject = cCMO_DuctLossMakeupAir
            if thisDuctLoss.AirLoopNum == 0:
                ShowSevereError(state,
                                "{}, \"{}\" {} not found: {}".format(CurrentModuleObject, thisDuctLoss.Name, "AirLoopHVAC = ", thisDuctLoss.AirLoopName))
                errorsFound = True

        var AFNNodeNum1: Int32
        var NodeNum1: Int32
        var AFNNodeNum2: Int32
        var NodeNum2: Int32

        for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
            var thisDuctLoss = state.dataDuctLoss.ductloss[DuctLossNum - 1]
            if thisDuctLoss.LossType == DuctLossType.Conduction:
                AFNNodeNum1 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[0]
                AFNNodeNum2 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[1]
                if not state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName.empty():
                    NodeNum1 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName, state.dataLoopNodes.NodeID)
                    state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusNodeNum = NodeNum1
                else:
                    NodeNum1 = 0
                if NodeNum1 > 0:
                    if SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "AirLoopHVAC:ZoneSplitter"):
                        if NodeNum1 == state.dataAirLoop.AirToZoneNodeInfo[thisDuctLoss.AirLoopNum - 1].ZoneEquipSupplyNodeNum[0]: # 0-based
                            thisDuctLoss.LossSubType = DuctLossSubType.SupplyTrunk
                            state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk)] = True   # SupplyTrunk=1, index 1 in C++? Actually +1 -> 2, but we use enum value (1) for 0-based? Wait: In C++ they used: SubTypeSimuFlag(int(DuctLossSubType::SupplyTrunk) + 1) = true; So if SupplyTrunk=1, then index = 2. In Mojo we need index 1 because we are 0-based. So we subtract 1? Actually we want to match the same logical index. Since C++ array is 1-based, they store at 2. In Mojo 0-based, that corresponds to index 1. So we use int(DuctLossSubType.SupplyTrunk) which is 1, but that gives index 1 (0-based). But careful: The array dimension is 8, and they set flags at positions corresponding to enum values+1. So we should map: SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk)] (0-based) should be set. However, in the C++ code, they access SubTypeSimuFlag(int(DuctLossSubType::SupplyBranch) + 1) for SupplyBranch (0) => index 1. So for SupplyTrunk (1) => index 2. So in Mojo, we want index = int(DuctLossSubType) + 1? Wait: Because C++ 1-based indexing means they store at index = enum_value + 1. In Mojo 0-based, we store at index = enum_value. Because 1-based offset by 1. So for enum_value 1, C++ index 2, Mojo index 1. That matches int(DuctLossSubType.SupplyTrunk) = 1. So set SubTypeSimuFlag[1] = true. That's correct.
                            # However, we need to be consistent: In the rest of the code, when checking SubTypeSimuFlag, they use int(DuctLossSubType::SupplyBranch) + 1. That in Mojo would be int(DuctLossSubType.SupplyBranch) + 1 - 1? No, we must preserve the mapping. The safest way is to keep the formula as is: SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch) + 1] in C++ becomes SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch) + 1 - 1] = SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch)] in Mojo? Because C++ index +1 -> Mojo index = (C++index) - 1. So if C++ uses int(Enum) + 1, then Mojo index = int(Enum) + 1 - 1 = int(Enum). So we should always use int(Enum) as the Mojo index. That is simpler.
                            # Let's verify: In CalcConduction, they check SubTypeSimuFlag(int(DuctLossSubType::SupplyBranch) + 1). That's for SupplyBranch enum value 0, C++ index 1. In Mojo we want index 0. So using int(SupplyBranch) (0) gives index 0. Perfect.
                            # In InitDuctLoss, they set SubTypeSimuFlag(int(DuctLossSubType::SupplyTrunk) + 1) = true. That's C++ index 2, Mojo index 1. So use int(SupplyTrunk) (1) = index 1. So consistent.
                            # So we will set SubTypeSimuFlag[int(SubType)] = true.
                            state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk)] = True
                            state.dataDuctLoss.AirLoopInNodeNum = NodeNum1
                    elif SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "AirLoopHVAC:ZoneMixer"):
                        for InNodeNum in range(1, state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].NumInletNodes + 1):
                            if NodeNum1 == state.dataMixerComponent.MixerCond[state.dataDuctLoss.MixerNum - 1].InletNode[InNodeNum - 1] + 1: # InletNode is 1-based? In C++ they use InletNode(InNodeNum) which is 1-based. Mojo array is 0-based so we need to subtract 1 from C++ value? Actually InletNode(InNodeNum) returns a node number (1-based). So NodeNum1 (C++ node number) equals that. In Mojo we have InletNode[InNodeNum-1] which is also 1-based node number. So comparison is NodeNum1 == InletNode[InNodeNum-1] (no +1). The original C++ used NodeNum1 == InletNode(InNodeNum) + 1? Wait, the original code is: if (NodeNum1 == state.dataMixerComponent->MixerCond(state.dataDuctLoss->MixerNum).InletNode(InNodeNum) + 1)  That's strange: they added +1. Possibly because InletNode is 0-based in C++? Actually ObjexxFCL arrays are 1-based, but they might have overloaded to return index +1? Hmm. Let's look: In C++ data structures, InletNode is likely an array of int (1-based node numbers). So InletNode(InNodeNum) returns the node number (1-based). Then they compare with NodeNum1 (also 1-based). So why +1? Could be a bug in original? But we must keep exactly. So we'll keep the +1. In Mojo, InletNode[InNodeNum-1] returns the node number (1-based). Then we compare NodeNum1 == InletNode[InNodeNum-1] + 1. That is faithful.
                                thisDuctLoss.LossSubType = DuctLossSubType.ReturnBranch
                                state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnBranch)] = True
                                break
                else:
                    if not state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName.empty():
                        NodeNum2 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName, state.dataLoopNodes.NodeID)
                        state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusNodeNum = NodeNum2
                    else:
                        NodeNum2 = 0
                    if NodeNum2 > 0:
                        if SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "AirLoopHVAC:ZoneSplitter"):
                            for OutNodeNum in range(1, state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].NumOutletNodes + 1):
                                if NodeNum2 == state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1]:
                                    thisDuctLoss.LossSubType = DuctLossSubType.SupplyBranch
                                    state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch)] = True
                                    for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
                                        for inletNum in range(1, state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].NumInletNodes + 1):
                                            if state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] > 0:
                                                if state.dataDefineEquipment.AirDistUnit[state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] - 1].InletNodeNum == NodeNum2:
                                                    state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusZoneInletNodeNum = state.dataDefineEquipment.AirDistUnit[state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] - 1].OutletNodeNum
                                    break
                        elif SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "AirLoopHVAC:ZoneMixer"):
                            thisDuctLoss.LossSubType = DuctLossSubType.ReturnTrunk
                            state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.ReturnTrunk)] = True

            if thisDuctLoss.LossType == DuctLossType.Leakage:
                AFNNodeNum1 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[0]
                AFNNodeNum2 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[1]
                if not state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName.empty() and state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType != "ZONE":
                    NodeNum1 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName, state.dataLoopNodes.NodeID)
                    state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusNodeNum = NodeNum1
                    if NodeNum1 > 0:
                        if SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "Zone") or SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OutdoorAir:NodeList") or SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OutdoorAir:Node"):
                            thisDuctLoss.LossSubType = DuctLossSubType.SupLeakBranch
                            state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupLeakBranch)] = True
                elif SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "AirLoopHVAC:ZoneSplitter"):
                    if SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "Zone") or SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OutdoorAir:NodeList") or SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OutdoorAir:Node"):
                        thisDuctLoss.LossSubType = DuctLossSubType.SupLeakTrunk
                        state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupLeakTrunk)] = True

                if SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "Zone") or SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "OutdoorAir:NodeList") or SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "OutdoorAir:Node"):
                    if not state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName.empty():
                        NodeNum2 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName, state.dataLoopNodes.NodeID)
                        if NodeNum2 > 0:
                            for NumEquip in range(1, state.dataZoneEquip.NumOfZoneEquipLists + 1):
                                for NumReturn in range(1, state.dataZoneEquip.ZoneEquipConfig[NumEquip - 1].NumReturnNodes + 1):
                                    if state.dataZoneEquip.ZoneEquipConfig[NumEquip - 1].ReturnNode[NumReturn - 1] == NodeNum2:
                                        thisDuctLoss.LossSubType = DuctLossSubType.RetLeakBranch
                                        state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.RetLeakBranch)] = True
                                        thisDuctLoss.RetLeakZoneNum = state.dataZoneEquip.ZoneEquipConfig[NumEquip - 1].ZoneNode
                    elif SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "AirLoopHVAC:ZoneMixer"):
                        thisDuctLoss.LossSubType = DuctLossSubType.RetLeakTrunk
                        state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.RetLeakTrunk)] = True

            if thisDuctLoss.LossType == DuctLossType.MakeupAir:
                AFNNodeNum1 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[0]
                AFNNodeNum2 = state.afn.AirflowNetworkLinkageData[thisDuctLoss.LinkageNum - 1].NodeNums[1]
                if SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "ZONE"):
                    state.afn.AirflowNetworkNodeData[AFNNodeNum1 - 1].EPlusZoneNum = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName, state.dataHeatBal.Zone)
                elif SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "OUTDOORAIR:NODELIST") or SameString(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusType, "OUTDOORAIR:NODE"):
                    NodeNum1 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusName, state.dataLoopNodes.NodeID)
                    if NodeNum1 > 0:
                        state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusNodeNum = NodeNum1
                else:
                    ShowSevereError(state,
                                    "{}, \"{}\" {} not found: {}".format("Duct:Loss:MakeupAir", thisDuctLoss.Name, "Incorrect input, not Zone, OUTDOORAIR:NODELIST, and OUTDOORAIR:NODE = ", state.afn.DisSysNodeData[AFNNodeNum1 - 1].Name))
                    errorsFound = True

                if SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "ZONE"):
                    state.afn.AirflowNetworkNodeData[AFNNodeNum2 - 1].EPlusZoneNum = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName, state.dataHeatBal.Zone)
                elif SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OUTDOORAIR:NODELIST") or SameString(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusType, "OUTDOORAIR:NODE"):
                    NodeNum2 = FindItemInList(state.afn.DisSysNodeData[AFNNodeNum2 - 1].EPlusName, state.dataLoopNodes.NodeID)
                    if NodeNum2 > 0:
                        state.afn.DisSysNodeData[AFNNodeNum1 - 1].EPlusNodeNum = NodeNum2
                else:
                    ShowSevereError(state,
                                    "{}, \"{}\" {} not found: {}".format("Duct:Loss:MakeupAir", thisDuctLoss.Name, "Incorrect input, not Zone, OUTDOORAIR:NODELIST, and OUTDOORAIR:NODE = ", state.afn.DisSysNodeData[AFNNodeNum2 - 1].Name))
                    errorsFound = True

            if errorsFound:
                ShowFatalError(state, "GetDuctLossMakeupAirInput: Previous errors cause termination.")

        for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
            if state.dataHeatBal.Zone[ZoneNum - 1].IsControlled:
                state.dataDuctLoss.CtrlZoneNum = ZoneNum
                break

        SetupOutputVariable(state,
                            "System Added Sensible Rate Due to Duct Loss",
                            Constants.Units.W,
                            state.dataDuctLoss.SysSen,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataAirSystemsData.PrimaryAirSystems[0].Name)
        SetupOutputVariable(state,
                            "System Added Latent Rate Due to Duct Loss",
                            Constants.Units.kgWater_s,
                            state.dataDuctLoss.SysLat,
                            OutputProcessor.TimeStepType.System,
                            OutputProcessor.StoreType.Average,
                            state.dataAirSystemsData.PrimaryAirSystems[0].Name)

        state.dataDuctLoss.AirLoopConnectionFlag = False

        if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyTrunk)]: # SupplyTrunk=1, index 1
            state.dataDuctLoss.AirLoopInNodeNum = state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].InletNode

        if not state.dataDuctLoss.SubTypeSimuFlag[int(DuctLossSubType.SupplyBranch)]: # SupplyBranch=0, index 0
            state.dataDuctLoss.ZoneEquipInletNodes.allocate(state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].NumOutletNodes)
            for OutNodeNum in range(1, state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].NumOutletNodes + 1):
                for ZoneNum in range(1, state.dataGlobal.NumOfZones + 1):
                    for inletNum in range(1, state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].NumInletNodes + 1):
                        if state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] > 0:
                            if state.dataDefineEquipment.AirDistUnit[state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] - 1].InletNodeNum == state.dataSplitterComponent.SplitterCond[state.dataDuctLoss.SplitterNum - 1].OutletNode[OutNodeNum - 1]:
                                state.dataDuctLoss.ZoneEquipInletNodes[OutNodeNum - 1] = state.dataDefineEquipment.AirDistUnit[state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].InletNodeADUNum[inletNum - 1] - 1].OutletNodeNum

    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        if state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusZoneNum > 0:
            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusZoneNum - 1].MAT
            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusZoneNum - 1].airHumRat
        if state.afn.AirflowNetworkNodeData[NodeNum - 1].NodeTypeNum == 1:
            state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusNodeNum = state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum
            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ = state.dataLoopNodes.Node[state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusNodeNum - 1].Temp
            state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ = state.dataLoopNodes.Node[state.afn.AirflowNetworkNodeData[NodeNum - 1].EPlusNodeNum - 1].HumRat

def ReportDuctLoss(state: EnergyPlusData):
    var ZoneNum: Int32
    # Reset arrays
    for i in range(len(state.dataDuctLoss.ZoneSen)):
        state.dataDuctLoss.ZoneSen[i] = 0.0
    for i in range(len(state.dataDuctLoss.ZoneLat)):
        state.dataDuctLoss.ZoneLat[i] = 0.0
    state.dataDuctLoss.SysSen = 0.0
    state.dataDuctLoss.SysLat = 0.0

    for DuctLossNum in range(1, state.dataDuctLoss.NumOfDuctLosses + 1):
        if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossType == DuctLossType.Conduction:
            ZoneNum = state.dataDuctLoss.ductloss[DuctLossNum - 1].ZoneNum
            if ZoneNum > 0:
                state.dataDuctLoss.ZoneSen[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.ZoneLat[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat
            if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyBranch or state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupplyTrunk:
                state.dataDuctLoss.SysSen += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.SysLat += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat

        if state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakBranch or state.dataDuctLoss.ductloss[DuctLossNum - 1].LossSubType == DuctLossSubType.SupLeakTrunk:
            ZoneNum = state.afn.AirflowNetworkNodeData[state.afn.AirflowNetworkLinkageData[state.dataDuctLoss.ductloss[DuctLossNum - 1].LinkageNum - 1].NodeNums[1] - 1].EPlusZoneNum
            if ZoneNum > 0:
                state.dataDuctLoss.ZoneSen[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qsen
                state.dataDuctLoss.ZoneLat[ZoneNum - 1] += state.dataDuctLoss.ductloss[DuctLossNum - 1].Qlat
            state.dataDuctLoss.SysSen += state.dataDuctLoss.ductloss[DuctLossNum - 1].QsenSL
            state.dataDuctLoss.SysLat += state.dataDuctLoss.ductloss[DuctLossNum - 1].QlatSL

    state.dataDuctLoss.ZoneSen[state.dataDuctLoss.CtrlZoneNum - 1] -= state.dataDuctLoss.SysSen
    state.dataDuctLoss.ZoneLat[state.dataDuctLoss.CtrlZoneNum - 1] -= state.dataDuctLoss.SysLat

def ReturnPathUpdate(state: EnergyPlusData, MixerNum: Int32):
    var OutletNode: Int32
    OutletNode = state.dataMixerComponent.MixerCond[MixerNum - 1].OutletNode
    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        if state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum == OutletNode:
            state.dataLoopNodes.Node[OutletNode - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
            state.dataLoopNodes.Node[OutletNode - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
            state.dataLoopNodes.Node[OutletNode - 1].Enthalpy = PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
            break

    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletTemp = state.dataLoopNodes.Node[OutletNode - 1].Temp
    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletHumRat = state.dataLoopNodes.Node[OutletNode - 1].HumRat
    state.dataMixerComponent.MixerCond[MixerNum - 1].OutletEnthalpy = state.dataLoopNodes.Node[OutletNode - 1].Enthalpy

def SupplyPathUpdate(state: EnergyPlusData, SplitterNum: Int32):
    var OutletNodeNum: Int32
    for NodeNum in range(1, state.afn.AirflowNetworkNumOfNodes + 1):
        for OutletNodeNum in range(1, state.dataSplitterComponent.SplitterCond[SplitterNum - 1].NumOutletNodes + 1):
            if state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum == state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1]:
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
                state.dataLoopNodes.Node[state.dataSplitterComponent.SplitterCond[SplitterNum - 1].OutletNode[OutletNodeNum - 1] - 1].Enthalpy = PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
                if state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum != state.afn.DisSysNodeData[NodeNum - 1].EPlusNodeNum:
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].Temp = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].HumRat = state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ
                    state.dataLoopNodes.Node[state.afn.DisSysNodeData[NodeNum - 1].EPlusZoneInletNodeNum - 1].Enthalpy = PsyHFnTdbW(state.afn.AirflowNetworkNodeSimu[NodeNum - 1].TZ, state.afn.AirflowNetworkNodeSimu[NodeNum - 1].WZ)
                break