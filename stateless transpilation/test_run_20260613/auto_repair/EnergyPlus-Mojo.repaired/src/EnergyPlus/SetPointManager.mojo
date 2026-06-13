//! Import necessary modules (assumed present in same directory structure)
from EnergyPlusData import EnergyPlusData
from DataEnvironment import (
    GroundTempType,
    OutHumRat, OutDryBulbTemp, OutWetBulbTemp, OutBaroPress,
    GroundTemp, GroundTempInputs
)
from DataGlobals import (
    BeginEnvrnFlag, SysSizingCalc, AnyEnergyManagementSystemInModel,
    MetersHaveBeenInitialized, RunOptCondEntTemp, AnyIdealCondEntSetPointInModel,
    NumOfZones, isEpJSON, preserveIDFOrder, SmallMassFlow, SmallLoad
)
from DataLoopNodes import (
    Node, NodeID, MoreNodeInfo, SensedNodeFlagValue, SPMNodeWetBulbRepReq
)
from DataAirLoop import AirToZoneNodeInfo, AirLoopFlow, AirLoopControlInfo, LoopFlowRateSet
from DataAirSystems import PrimaryAirSystems, CompType, RABExists, RABMixInNode, SupMixInNode, MixOutNode, RABSplitOutNode
from DataConvergParams import PlantFlowRateToler
from DataHVACGlobals import NumPrimaryAirSys, SetPointErrorFlag
from DataHeatBalance import Zone
from DataIPShortCuts import cCurrentModuleObject
from DataZoneControls import StageZoneLogic, HumidityControlZone, NumHumidityControlZones
from DataZoneEnergyDemands import ZoneSysEnergyDemand, ZoneSysMoistureDemand, DeadBandOrSetback
from DataZoneEquipment import ZoneEquipConfig, ZoneEquipInputsFilled, GetSystemNodeNumberForZone
from EMSManager import CheckIfNodeSetPointManagedByEMS
from CurveManager import CurveValue, GetCurveIndex
from FluidProperties import GetInternalVariableValue, GetNumMeteredVariables, GetMeteredVariables
from General import FindNumberInList
from InputProcessing.InputProcessor import InputProcessor, getEnumValue
from NodeInputManager import GetNodeNums, GetOnlySingleNode
from OutAirNodeManager import CheckOutAirNodeNumber
from OutputProcessor import SetupOutputVariable, VariableType, TimeStepType, StoreType, MeteredVar
from OutputReportPredefined import PreDefTableEntry, pdchSPMOArType, pdchSPMOArStLo1, pdchSPMOArStHi1,
    pdchSPMOArOutLo1, pdchSPMOArOutHi1, pdchSPMOArSchNm, pdchSPMOArStLo2, pdchSPMOArStHi2,
    pdchSPMOArOutLo2, pdchSPMOArOutHi2, pdchSPMOArStPtNd, pdchSPMOArStPtLp,
    pdchSPMRetType, pdchSPMRetMinT, pdchSPMRetMaxT, pdchSPMRetRetT, pdchSPMRetRetType,
    pdchSPMRetOutNd, pdchSPMRetInNd, pdchSPMRetPltLp
from OutputReportTabular import stringJoinDelimiter
from Plant.DataPlant import (
    PlantEquipmentType, CtrlType, LoopSideLocation, PlantLocation,
    PlantLoop, TotNumLoops
)
from Plant.PlantUtilities import SetPlantLocationLinks, ScanPlantLoopsForNodeNum, verifyTwoNodeNumsOnSamePlantLoop
from Plant.Enums import CtrlVarType
from Psychrometrics import PsyCpAirFnW, PsyHFnTdbW, PsyTdbFnHW, PsyWFnTdbRhPb
from ScheduleManager import Schedule, GetSchedule
from SimAirServingZones import CompType as SACompType
from UtilityRoutines import (
    ShowFatalError, ShowSevereError, ShowSevereDuplicateName, ShowSevereItemNotFound,
    ShowSevereInvalidKey, ShowContinueError, ShowWarningError, ShowWarningCustom,
    ShowRecurringSevereErrorAtEnd, ShowSevereCustom, ErrorObjectHeader, FindItemInList, makeUPPER
)
from DataPlant import (
    Chiller_Absorption, Chiller_Indirect_Absorption, Chiller_CombTurbine,
    Chiller_ConstCOP, Chiller_Electric, Chiller_ElectricEIR, Chiller_DFAbsorption,
    Chiller_ElectricReformEIR, Chiller_EngineDriven,
    CoolingTower_SingleSpd, CoolingTower_TwoSpd, CoolingTower_VarSpd,
    PumpVariableSpeed, PumpConstantSpeed
)
from DataPrecisionGlobals import pi
from math import abs, max, min, clamp, sqrt

// ----------------------------------------------------------------------
// Enums (from SetPointManager.hh)
enum SupplyFlowTempStrategy: Int32:
    Invalid = -1
    MaxTemp
    MinTemp
    Num

enum ControlStrategy: Int32:
    Invalid = -1
    TempFirst
    FlowFirst
    Num

enum AirTempType: Int32:
    Invalid = -1
    WetBulb
    DryBulb
    Num

enum ReturnTempType: Int32:
    Invalid = -1
    Scheduled
    Constant
    Setpoint
    Num

enum SPMType: Int32:
    Invalid = -1
    Scheduled
    ScheduledDual
    OutsideAir
    SZReheat
    SZHeating
    SZCooling
    SZMinHum
    SZMaxHum
    MixedAir
    OutsideAirPretreat
    Warmest
    Coldest
    WarmestTempFlow
    ReturnAirBypass
    MZCoolingAverage
    MZHeatingAverage
    MZMinHumAverage
    MZMaxHumAverage
    MZMinHum
    MZMaxHum
    FollowOutsideAirTemp
    FollowSystemNodeTemp
    FollowGroundTemp
    CondenserEnteringTemp
    IdealCondenserEnteringTemp
    SZOneStageCooling
    SZOneStageHeating
    ChilledWaterReturnTemp
    HotWaterReturnTemp
    TESScheduled
    SystemNodeTemp
    SystemNodeHum
    Num

// ----------------------------------------------------------------------
// Struct definitions (from SetPointManager.hh)
struct SPMBase:
    var Name: String = ""
    var type: SPMType = SPMType.Invalid
    var ctrlVar: CtrlVarType = CtrlVarType.Invalid
    var ctrlNodeNums: List[Int] = List[Int]()
    var airLoopName: String = ""
    var airLoopNum: Int = 0
    var refNodeNum: Int = 0
    var minSetTemp: Float64 = 0.0
    var maxSetTemp: Float64 = 0.0
    var minSetHum: Float64 = 0.0
    var maxSetHum: Float64 = 0.0
    var setPt: Float64 = 0.0

    def __del__(owned self): pass

    def calculate(inout self, state: EnergyPlusData):
        """Override in derived types"""

struct SPMScheduled(SPMBase):
    var sched: Optional[Schedule] = None

    def calculate(inout self, state: EnergyPlusData):
        self.setPt = self.sched.getCurrentVal()

struct SPMScheduledDual(SPMBase):
    var hiSched: Optional[Schedule] = None
    var loSched: Optional[Schedule] = None
    var setPtHi: Float64 = 0.0
    var setPtLo: Float64 = 0.0

    def calculate(inout self, state: EnergyPlusData):
        self.setPtHi = self.hiSched.getCurrentVal()
        self.setPtLo = self.loSched.getCurrentVal()

struct SPMOutsideAir(SPMBase):
    var sched: Optional[Schedule] = None
    var lowSetPt1: Float64 = 0.0
    var low1: Float64 = 0.0
    var highSetPt1: Float64 = 0.0
    var high1: Float64 = 0.0
    var invalidSchedValErrorIndex: Int = 0
    var setPtErrorCount: Int = 0
    var lowSetPt2: Float64 = 0.0
    var low2: Float64 = 0.0
    var highSetPt2: Float64 = 0.0
    var high2: Float64 = 0.0

    def calculate(inout self, state: EnergyPlusData):
        var SchedVal: Float64 = (self.sched if self.sched else 0.0)
        if SchedVal == 2.0:
            self.setPt = interpSetPoint(self.low2, self.high2, state.dataEnvrn.OutDryBulbTemp, self.lowSetPt2, self.highSetPt2)
        else:
            if (self.sched) and (SchedVal != 1.0):
                self.setPtErrorCount += 1
                if self.setPtErrorCount <= 10:
                    ShowSevereError(state, "Schedule Values for the Outside Air Setpoint Manager = {} are something other than 1 or 2.".format(self.Name))
                    ShowContinueError(state, "...the value for the schedule currently is {}".format(SchedVal))
                    ShowContinueError(state, "...the value is being interpreted as 1 for this run but should be fixed.")
                else:
                    ShowRecurringSevereErrorAtEnd(state, "Schedule Values for the Outside Air Setpoint Manager = {} are something other than 1 or 2.".format(self.Name), self.invalidSchedValErrorIndex)
            self.setPt = interpSetPoint(self.low1, self.high1, state.dataEnvrn.OutDryBulbTemp, self.lowSetPt1, self.highSetPt1)

struct SPMSingleZoneReheat(SPMBase):
    var ctrlZoneName: String = ""
    var ctrlZoneNum: Int = 0
    var zoneNodeNum: Int = 0
    var zoneInletNodeNum: Int = 0
    var mixedAirNodeNum: Int = 0
    var fanInNodeNum: Int = 0
    var fanOutNodeNum: Int = 0
    var oaInNodeNum: Int = 0
    var retNodeNum: Int = 0
    var loopInNodeNum: Int = 0

    def calculate(inout self, state: EnergyPlusData):
        // implementation from .cc
        let zoneInletNode = state.dataLoopNodes.Node[self.zoneInletNodeNum]
        var OAFrac = state.dataAirLoop.AirLoopFlow[self.airLoopNum].OAFrac
        var ZoneMassFlow = zoneInletNode.MassFlowRate
        let zoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.ctrlZoneNum]
        var ZoneLoad = zoneSysEnergyDemand.TotalOutputRequired
        var ZoneLoadToCoolSetPt = zoneSysEnergyDemand.OutputRequiredToCoolingSP
        var ZoneLoadToHeatSetPt = zoneSysEnergyDemand.OutputRequiredToHeatingSP
        var DeadBand = state.dataZoneEnergyDemand.DeadBandOrSetback(self.ctrlZoneNum)
        var ZoneTemp = state.dataLoopNodes.Node[self.zoneNodeNum].Temp
        var TMixAtMinOA: Float64
        if self.oaInNodeNum > 0:
            let oaInNode = state.dataLoopNodes.Node[self.oaInNodeNum]
            let retNode = state.dataLoopNodes.Node[self.retNodeNum]
            var HumRatMixAtMinOA = (1.0 - OAFrac) * retNode.HumRat + OAFrac * oaInNode.HumRat
            var EnthMixAtMinOA = (1.0 - OAFrac) * retNode.Enthalpy + OAFrac * oaInNode.Enthalpy
            TMixAtMinOA = PsyTdbFnHW(EnthMixAtMinOA, HumRatMixAtMinOA)
        else:
            TMixAtMinOA = state.dataLoopNodes.Node[self.loopInNodeNum].Temp
        var FanDeltaT: Float64
        if self.fanOutNodeNum > 0 and self.fanInNodeNum > 0:
            FanDeltaT = state.dataLoopNodes.Node[self.fanOutNodeNum].Temp - state.dataLoopNodes.Node[self.fanInNodeNum].Temp
        else:
            FanDeltaT = 0.0
        var TSupNoHC = TMixAtMinOA + FanDeltaT
        var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
        var ExtrRateNoHC = CpAir * ZoneMassFlow * (TSupNoHC - ZoneTemp)
        var TSetPt: Float64
        if ZoneMassFlow <= SmallMassFlow:
            TSetPt = TSupNoHC
        elif DeadBand or abs(ZoneLoad) < SmallLoad:
            if ExtrRateNoHC < 0.0:
                TSetPt = TSupNoHC if ExtrRateNoHC >= ZoneLoadToHeatSetPt else (ZoneTemp + ZoneLoadToHeatSetPt / (CpAir * ZoneMassFlow))
            elif ExtrRateNoHC > 0.0:
                TSetPt = TSupNoHC if ExtrRateNoHC <= ZoneLoadToCoolSetPt else (ZoneTemp + ZoneLoadToCoolSetPt / (CpAir * ZoneMassFlow))
            else:
                TSetPt = TSupNoHC
        elif ZoneLoad < (-1.0 * SmallLoad):
            var TSetPt1 = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlow)
            var TSetPt2 = ZoneTemp + ZoneLoadToHeatSetPt / (CpAir * ZoneMassFlow)
            TSetPt = TSetPt1 if TSetPt1 <= TSupNoHC else (TSetPt2 if TSetPt2 > TSupNoHC else TSupNoHC)
        elif ZoneLoad > SmallLoad:
            var TSetPt1 = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlow)
            var TSetPt2 = ZoneTemp + ZoneLoadToCoolSetPt / (CpAir * ZoneMassFlow)
            TSetPt = TSetPt1 if TSetPt1 >= TSupNoHC else (TSetPt2 if TSetPt2 < TSupNoHC else TSupNoHC)
        else:
            TSetPt = TSupNoHC
        self.setPt = clamp(TSetPt, self.minSetTemp, self.maxSetTemp)

struct SPMSingleZoneTemp(SPMBase):
    var ctrlZoneName: String = ""
    var ctrlZoneNum: Int = 0
    var zoneNodeNum: Int = 0
    var zoneInletNodeNum: Int = 0

    def calculate(inout self, state: EnergyPlusData):
        let zoneInletNode = state.dataLoopNodes.Node[self.zoneInletNodeNum]
        let zoneEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[self.ctrlZoneNum]
        var ZoneLoadToSP = zoneEnergyDemand.OutputRequiredToHeatingSP if self.type == SPMType.SZHeating else zoneEnergyDemand.OutputRequiredToCoolingSP
        var ZoneTemp = state.dataLoopNodes.Node[self.zoneNodeNum].Temp
        if zoneInletNode.MassFlowRate <= SmallMassFlow:
            self.setPt = self.minSetTemp if self.type == SPMType.SZHeating else self.maxSetTemp
        else:
            var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
            self.setPt = ZoneTemp + ZoneLoadToSP / (CpAir * zoneInletNode.MassFlowRate)
            self.setPt = clamp(self.setPt, self.minSetTemp, self.maxSetTemp)

struct SPMSingleZoneHum(SPMBase):
    var zoneNodeNum: Int = 0
    var ctrlZoneNum: Int = 0

    def calculate(inout self, state: EnergyPlusData):
        let zoneNode = state.dataLoopNodes.Node[self.zoneNodeNum]
        var ZoneMassFlow = zoneNode.MassFlowRate
        if ZoneMassFlow > SmallMassFlow:
            let zoneMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[self.ctrlZoneNum]
            var MoistureLoad = zoneMoistureDemand.OutputRequiredToHumidifyingSP if self.type == SPMType.SZMinHum else zoneMoistureDemand.OutputRequiredToDehumidifyingSP
            var MaxHum = 0.0 if self.type == SPMType.SZMinHum else 0.00001
            self.setPt = max(MaxHum, zoneNode.HumRat + MoistureLoad / ZoneMassFlow)
        else:
            self.setPt = 0.0

struct SPMMixedAir(SPMBase):
    var fanInNodeNum: Int = 0
    var fanOutNodeNum: Int = 0
    var mySetPointCheckFlag: Bool = True
    var freezeCheckEnable: Bool = True
    var coolCoilInNodeNum: Int = 0
    var coolCoilOutNodeNum: Int = 0
    var minCoolCoilOutTemp: Float64 = 7.2

    def calculate(inout self, state: EnergyPlusData):
        let fanInNode = state.dataLoopNodes.Node[self.fanInNodeNum]
        let fanOutNode = state.dataLoopNodes.Node[self.fanOutNodeNum]
        let refNode = state.dataLoopNodes.Node[self.refNodeNum]
        self.freezeCheckEnable = False
        if not state.dataGlobals.SysSizingCalc and self.mySetPointCheckFlag:
            if refNode.TempSetPoint == SensedNodeFlagValue:
                if not state.dataGlobals.AnyEnergyManagementSystemInModel:
                    ShowSevereError(state, "CalcMixedAirSetPoint: Missing reference temperature setpoint for Mixed Air Setpoint Manager {}".format(self.Name))
                    ShowContinueError(state, "Node Referenced ={}".format(state.dataLoopNodes.NodeID[self.refNodeNum]))
                    ShowContinueError(state, "  use an additional Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at this node.")
                    state.dataHVACGlobals.SetPointErrorFlag = True
                else:
                    CheckIfNodeSetPointManagedByEMS(state, self.refNodeNum, CtrlVarType.Temp, state.dataHVACGlobals.SetPointErrorFlag)
                    if state.dataHVACGlobals.SetPointErrorFlag:
                        ShowSevereError(state, "CalcMixedAirSetPoint: Missing reference temperature setpoint for Mixed Air Setpoint Manager {}".format(self.Name))
                        ShowContinueError(state, "Node Referenced ={}".format(state.dataLoopNodes.NodeID[self.refNodeNum]))
                        ShowContinueError(state, "  use an additional Setpoint Manager with Control Variable = \"Temperature\" to establish a setpoint at this node.")
                        ShowContinueError(state, "Or add EMS Actuator to provide temperature setpoint at this node")
            self.mySetPointCheckFlag = False
        self.setPt = refNode.TempSetPoint - (fanOutNode.Temp - fanInNode.Temp)
        if self.coolCoilInNodeNum > 0 and self.coolCoilOutNodeNum > 0:
            let coolCoilInNode = state.dataLoopNodes.Node[self.coolCoilInNodeNum]
            let coolCoilOutNode = state.dataLoopNodes.Node[self.coolCoilOutNodeNum]
            var dtFan = fanOutNode.Temp - fanInNode.Temp
            var dtCoolCoil = coolCoilInNode.Temp - coolCoilOutNode.Temp
            if dtCoolCoil > 0.0 and self.minCoolCoilOutTemp > state.dataEnvrn.OutDryBulbTemp:
                self.freezeCheckEnable = True
                if refNode.Temp == coolCoilOutNode.Temp:  // blow through
                    self.setPt = max(refNode.TempSetPoint, self.minCoolCoilOutTemp) - dtFan + dtCoolCoil
                elif self.refNodeNum != self.coolCoilOutNodeNum:  // draw through
                    self.setPt = max(refNode.TempSetPoint - dtFan, self.minCoolCoilOutTemp) + dtCoolCoil
                else:
                    self.setPt = max(refNode.TempSetPoint, self.minCoolCoilOutTemp) + dtCoolCoil

struct SPMOutsideAirPretreat(SPMBase):
    var mixedOutNodeNum: Int = 0
    var oaInNodeNum: Int = 0
    var returnInNodeNum: Int = 0
    var mySetPointCheckFlag: Bool = True

    def calculate(inout self, state: EnergyPlusData):
        var ReturnInValue: Float64 = 0.0
        var RefNodeSetPoint: Float64 = 0.0
        var MinSetPoint: Float64 = 0.0
        var MaxSetPoint: Float64 = 0.0
        let refNode = state.dataLoopNodes.Node[self.refNodeNum]
        let mixedOutNode = state.dataLoopNodes.Node[self.mixedOutNodeNum]
        let oaInNode = state.dataLoopNodes.Node[self.oaInNodeNum]
        let returnInNode = state.dataLoopNodes.Node[self.returnInNodeNum]
        var isHumiditySetPoint: Bool = False
        match self.ctrlVar:
            case CtrlVarType.Temp:
                RefNodeSetPoint = refNode.TempSetPoint
                ReturnInValue = returnInNode.Temp
                MinSetPoint = self.minSetTemp
                MaxSetPoint = self.maxSetTemp
            case CtrlVarType.MaxHumRat:
                RefNodeSetPoint = refNode.HumRatMax
                ReturnInValue = returnInNode.HumRat
                MinSetPoint = self.minSetHum
                MaxSetPoint = self.maxSetHum
                isHumiditySetPoint = True
            case CtrlVarType.MinHumRat:
                RefNodeSetPoint = refNode.HumRatMin
                ReturnInValue = returnInNode.HumRat
                MinSetPoint = self.minSetHum
                MaxSetPoint = self.maxSetHum
                isHumiditySetPoint = True
            case CtrlVarType.HumRat:
                RefNodeSetPoint = refNode.HumRatSetPoint
                ReturnInValue = returnInNode.HumRat
                MinSetPoint = self.minSetHum
                MaxSetPoint = self.maxSetHum
                isHumiditySetPoint = True
            else: pass
        if not state.dataGlobals.SysSizingCalc and self.mySetPointCheckFlag:
            self.mySetPointCheckFlag = False
            if RefNodeSetPoint == SensedNodeFlagValue:
                if not state.dataGlobals.AnyEnergyManagementSystemInModel:
                    ShowSevereError(state, "CalcOAPretreatSetPoint: Missing reference setpoint for Outdoor Air Pretreat Setpoint Manager {}".format(self.Name))
                    ShowContinueError(state, "Node Referenced ={}".format(state.dataLoopNodes.NodeID[self.refNodeNum]))
                    ShowContinueError(state, "use a Setpoint Manager to establish a setpoint at this node.")
                    ShowFatalError(state, "Missing reference setpoint.")
                else:
                    var LocalSetPointCheckFailed: Bool = False
                    match self.ctrlVar:
                        case CtrlVarType.Temp:
                        case CtrlVarType.MaxHumRat:
                        case CtrlVarType.MinHumRat:
                        case CtrlVarType.HumRat:
                            CheckIfNodeSetPointManagedByEMS(state, self.refNodeNum, self.ctrlVar, LocalSetPointCheckFailed)
                        else: pass
                    if LocalSetPointCheckFailed:
                        ShowSevereError(state, "CalcOAPretreatSetPoint: Missing reference setpoint for Outdoor Air Pretreat Setpoint Manager {}".format(self.Name))
                        ShowContinueError(state, "Node Referenced ={}".format(state.dataLoopNodes.NodeID[self.refNodeNum]))
                        ShowContinueError(state, "use a Setpoint Manager to establish a setpoint at this node.")
                        ShowContinueError(state, "Or use an EMS actuator to control a setpoint at this node.")
                        ShowFatalError(state, "Missing reference setpoint.")
        if (mixedOutNode.MassFlowRate <= 0.0) or (oaInNode.MassFlowRate <= 0.0):
            self.setPt = RefNodeSetPoint
        elif isHumiditySetPoint and (RefNodeSetPoint == 0.0):
            self.setPt = 0.0
        else:
            var OAFraction = oaInNode.MassFlowRate / mixedOutNode.MassFlowRate
            self.setPt = ReturnInValue + (RefNodeSetPoint - ReturnInValue) / OAFraction
            self.setPt = clamp(self.setPt, MinSetPoint, MaxSetPoint)

struct SPMTempest(SPMBase):
    var strategy: SupplyFlowTempStrategy = SupplyFlowTempStrategy.Invalid

    def calculate(inout self, state: EnergyPlusData):
        var SetPointTemp: Float64 = 0.0
        let airToZoneNode = state.dataAirLoop.AirToZoneNodeInfo[self.airLoopNum]
        if self.type == SPMType.Warmest:
            var TotCoolLoad: Float64 = 0.0
            SetPointTemp = self.maxSetTemp
            for iZoneNum in range(1, airToZoneNode.NumZonesCooled + 1):
                let CtrlZoneNum = airToZoneNode.CoolCtrlZoneNums[iZoneNum - 1]
                let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.CoolZoneInletNodes[iZoneNum - 1]]
                let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
                var ZoneMassFlowMax = zoneInletNode.MassFlowRateMax
                var ZoneLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CtrlZoneNum - 1].TotalOutputRequired
                var ZoneTemp = zoneNode.Temp
                var ZoneSetPointTemp = self.maxSetTemp
                if ZoneLoad < 0.0:
                    TotCoolLoad += abs(ZoneLoad)
                    var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
                    if ZoneMassFlowMax > SmallMassFlow:
                        ZoneSetPointTemp = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlowMax)
                SetPointTemp = min(SetPointTemp, ZoneSetPointTemp)
            SetPointTemp = clamp(SetPointTemp, self.minSetTemp, self.maxSetTemp)
            if TotCoolLoad < SmallLoad:
                SetPointTemp = self.maxSetTemp
        else:  // Coldest
            var TotHeatLoad: Float64 = 0.0
            SetPointTemp = self.minSetTemp
            if airToZoneNode.NumZonesHeated > 0:
                for iZoneNum in range(1, airToZoneNode.NumZonesHeated + 1):
                    let CtrlZoneNum = airToZoneNode.HeatCtrlZoneNums[iZoneNum - 1]
                    let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.HeatZoneInletNodes[iZoneNum - 1]]
                    let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
                    var ZoneMassFlowMax = zoneInletNode.MassFlowRateMax
                    var ZoneLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CtrlZoneNum - 1].TotalOutputRequired
                    var ZoneTemp = zoneNode.Temp
                    var ZoneSetPointTemp = self.minSetTemp
                    if ZoneLoad > 0.0:
                        TotHeatLoad += ZoneLoad
                        var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
                        if ZoneMassFlowMax > SmallMassFlow:
                            ZoneSetPointTemp = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlowMax)
                    SetPointTemp = max(SetPointTemp, ZoneSetPointTemp)
            else:
                for iZoneNum in range(1, airToZoneNode.NumZonesCooled + 1):
                    let CtrlZoneNum = airToZoneNode.CoolCtrlZoneNums[iZoneNum - 1]
                    let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.CoolZoneInletNodes[iZoneNum - 1]]
                    let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
                    var ZoneMassFlowMax = zoneInletNode.MassFlowRateMax
                    var ZoneLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CtrlZoneNum - 1].TotalOutputRequired
                    var ZoneTemp = zoneNode.Temp
                    var ZoneSetPointTemp = self.minSetTemp
                    if ZoneLoad > 0.0:
                        TotHeatLoad += ZoneLoad
                        var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
                        if ZoneMassFlowMax > SmallMassFlow:
                            ZoneSetPointTemp = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlowMax)
                    SetPointTemp = max(SetPointTemp, ZoneSetPointTemp)
            SetPointTemp = clamp(SetPointTemp, self.minSetTemp, self.maxSetTemp)
            if TotHeatLoad < SmallLoad:
                SetPointTemp = self.minSetTemp
        self.setPt = SetPointTemp

struct SPMWarmestTempFlow(SPMBase):
    var strategy: ControlStrategy = ControlStrategy.Invalid
    var minTurndown: Float64 = 0.0
    var turndown: Float64 = 0.0
    var critZoneNum: Int = 0
    var simReady: Bool = False

    def calculate(inout self, state: EnergyPlusData):
        if not self.simReady:
            return
        var TotCoolLoad: Float64 = 0.0
        var MaxSetPointTemp = self.maxSetTemp
        var SetPointTemp = MaxSetPointTemp
        var MinSetPointTemp = self.minSetTemp
        var MinFracFlow = self.minTurndown
        var FracFlow = MinFracFlow
        var CritZoneNumTemp: Int = 0
        var CritZoneNumFlow: Int = 0
        let airToZoneNode = state.dataAirLoop.AirToZoneNodeInfo[self.airLoopNum]
        for iZoneNum in range(1, airToZoneNode.NumZonesCooled + 1):
            let CtrlZoneNum = airToZoneNode.CoolCtrlZoneNums[iZoneNum - 1]
            let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.CoolZoneInletNodes[iZoneNum - 1]]
            let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
            var ZoneMassFlowMax = zoneInletNode.MassFlowRateMax
            var ZoneLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CtrlZoneNum - 1].TotalOutputRequired
            var ZoneTemp = zoneNode.Temp
            var ZoneSetPointTemp = MaxSetPointTemp
            var ZoneFracFlow = MinFracFlow
            if ZoneLoad < 0.0:
                TotCoolLoad += abs(ZoneLoad)
                var CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
                if ZoneMassFlowMax > SmallMassFlow:
                    if self.strategy == ControlStrategy.TempFirst:
                        ZoneSetPointTemp = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlowMax * MinFracFlow)
                        if ZoneSetPointTemp < MinSetPointTemp:
                            ZoneFracFlow = (ZoneLoad / (CpAir * (MinSetPointTemp - ZoneTemp))) / ZoneMassFlowMax
                        else:
                            ZoneFracFlow = MinFracFlow
                    else:  // FlowFirst
                        ZoneFracFlow = (ZoneLoad / (CpAir * (MaxSetPointTemp - ZoneTemp))) / ZoneMassFlowMax
                        if ZoneFracFlow > 1.0 or ZoneFracFlow < 0.0:
                            ZoneSetPointTemp = ZoneTemp + ZoneLoad / (CpAir * ZoneMassFlowMax)
                        else:
                            ZoneSetPointTemp = MaxSetPointTemp
            if ZoneSetPointTemp < SetPointTemp:
                SetPointTemp = ZoneSetPointTemp
                CritZoneNumTemp = CtrlZoneNum
            if ZoneFracFlow > FracFlow:
                FracFlow = ZoneFracFlow
                CritZoneNumFlow = CtrlZoneNum
        SetPointTemp = clamp(SetPointTemp, MinSetPointTemp, MaxSetPointTemp)
        FracFlow = clamp(FracFlow, MinFracFlow, 1.0)
        if TotCoolLoad < SmallLoad:
            SetPointTemp = MaxSetPointTemp
            FracFlow = MinFracFlow
        self.setPt = SetPointTemp
        self.turndown = FracFlow
        if self.strategy == ControlStrategy.TempFirst:
            self.critZoneNum = CritZoneNumFlow if CritZoneNumFlow != 0 else CritZoneNumTemp
        else:
            self.critZoneNum = CritZoneNumTemp if CritZoneNumTemp != 0 else CritZoneNumFlow

struct SPMReturnAirBypassFlow(SPMBase):
    var sched: Optional[Schedule] = None
    var FlowSetPt: Float64 = 0.0
    var rabMixInNodeNum: Int = 0
    var supMixInNodeNum: Int = 0
    var mixOutNodeNum: Int = 0
    var rabSplitOutNodeNum: Int = 0
    var sysOutNodeNum: Int = 0

    def calculate(inout self, state: EnergyPlusData):
        let mixerRABInNode = state.dataLoopNodes.Node[self.rabMixInNodeNum]
        let mixerSupInNode = state.dataLoopNodes.Node[self.supMixInNodeNum]
        let mixerOutNode = state.dataLoopNodes.Node[self.mixOutNodeNum]
        let loopOutNode = state.dataLoopNodes.Node[self.sysOutNodeNum]
        var TempSetPt = self.sched.getCurrentVal()
        var TempSetPtMod = TempSetPt - (loopOutNode.Temp - mixerOutNode.Temp)
        var SupFlow = mixerSupInNode.MassFlowRate
        var TempSup = mixerSupInNode.Temp
        var TotSupFlow = mixerOutNode.MassFlowRate
        var TempRAB = mixerRABInNode.Temp
        var RABFlow = (TotSupFlow * TempSetPtMod - SupFlow * TempSup) / max(TempRAB, 1.0)
        RABFlow = clamp(RABFlow, 0.0, TotSupFlow)
        self.FlowSetPt = RABFlow

struct SPMMultiZoneTemp(SPMBase):
    def calculate(inout self, state: EnergyPlusData):
        var SumLoad: Float64 = 0.0
        var SumProductMdotCp: Float64 = 0.0
        var SumProductMdotCpTot: Float64 = 0.0
        var SumProductMdotCpTZoneTot: Float64 = 0.0
        let airToZoneNode = state.dataAirLoop.AirToZoneNodeInfo[self.airLoopNum]
        for iZoneNum in range(1, airToZoneNode.NumZonesCooled + 1):
            let CtrlZoneNum = airToZoneNode.CoolCtrlZoneNums[iZoneNum - 1]
            let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.CoolZoneInletNodes[iZoneNum - 1]]
            let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
            var ZoneMassFlowRate = zoneInletNode.MassFlowRate
            var ZoneLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CtrlZoneNum - 1].TotalOutputRequired
            var ZoneTemp = zoneNode.Temp
            var CpAir = PsyCpAirFnW(zoneNode.HumRat)
            SumProductMdotCpTot += ZoneMassFlowRate * CpAir
            SumProductMdotCpTZoneTot += ZoneMassFlowRate * CpAir * ZoneTemp
            if (self.type == SPMType.MZHeatingAverage and ZoneLoad > 0.0) or (self.type == SPMType.MZCoolingAverage and ZoneLoad < 0.0):
                CpAir = PsyCpAirFnW(zoneInletNode.HumRat)
                SumLoad += ZoneLoad
                SumProductMdotCp += ZoneMassFlowRate * CpAir
        var ZoneAverageTemp = (SumProductMdotCpTot / SumProductMdotCpTot) if SumProductMdotCpTot > 0.0 else 0.0
        var SetPointTemp = (ZoneAverageTemp + SumLoad / SumProductMdotCp) if SumProductMdotCp > 0.0 else (self.minSetTemp if self.type == SPMType.MZHeatingAverage else self.maxSetTemp)
        SetPointTemp = clamp(SetPointTemp, self.minSetTemp, self.maxSetTemp)
        if abs(SumLoad) < SmallLoad:
            SetPointTemp = self.minSetTemp if self.type == SPMType.MZHeatingAverage else self.maxSetTemp
        self.setPt = SetPointTemp

struct SPMMultiZoneHum(SPMBase):
    def calculate(inout self, state: EnergyPlusData):
        var SmallMoistureLoad: Float64 = 0.00001
        var SumMdot: Float64 = 0.0
        var SumMdotTot: Float64 = 0.0
        var SumMoistureLoad: Float64 = 0.0
        var SumProductMdotHumTot: Float64 = 0.0
        let airToZoneNode = state.dataAirLoop.AirToZoneNodeInfo[self.airLoopNum]
        var SetPointHum = self.minSetHum if (self.type == SPMType.MZMinHum or self.type == SPMType.MZMinHumAverage) else self.maxSetHum
        for iZoneNum in range(1, airToZoneNode.NumZonesCooled + 1):
            let CtrlZoneNum = airToZoneNode.CoolCtrlZoneNums[iZoneNum - 1]
            let zoneInletNode = state.dataLoopNodes.Node[airToZoneNode.CoolZoneInletNodes[iZoneNum - 1]]
            let zoneNode = state.dataLoopNodes.Node[state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum - 1].ZoneNode]
            let zoneMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[CtrlZoneNum - 1]
            var ZoneMassFlowRate = zoneInletNode.MassFlowRate
            var MoistureLoad = zoneMoistureDemand.OutputRequiredToHumidifyingSP if (self.type == SPMType.MZMinHum or self.type == SPMType.MZMinHumAverage) else zoneMoistureDemand.OutputRequiredToDehumidifyingSP
            var ZoneHum = zoneNode.HumRat
            match self.type:
                case SPMType.MZMinHumAverage:
                    SumMdotTot += ZoneMassFlowRate
                    SumProductMdotHumTot += ZoneMassFlowRate * ZoneHum
                    if MoistureLoad > 0.0:
                        SumMdot += ZoneMassFlowRate
                        SumMoistureLoad += MoistureLoad
                case SPMType.MZMaxHumAverage:
                    SumMdotTot += ZoneMassFlowRate
                    SumProductMdotHumTot += ZoneMassFlowRate * ZoneHum
                    if MoistureLoad < 0.0:
                        SumMdot += ZoneMassFlowRate
                        SumMoistureLoad += MoistureLoad
                case SPMType.MZMinHum:
                    var ZoneSetPointHum = self.minSetHum
                    if MoistureLoad > 0.0:
                        SumMoistureLoad += MoistureLoad
                        if ZoneMassFlowRate > SmallMassFlow:
                            ZoneSetPointHum = max(0.0, ZoneHum + MoistureLoad / ZoneMassFlowRate)
                    SetPointHum = max(SetPointHum, ZoneSetPointHum)
                case SPMType.MZMaxHum:
                    var ZoneSetPointHum = self.maxSetHum
                    if MoistureLoad < 0.0:
                        SumMoistureLoad += MoistureLoad
                        if ZoneMassFlowRate > SmallMassFlow:
                            ZoneSetPointHum = max(0.0, ZoneHum + MoistureLoad / ZoneMassFlowRate)
                    SetPointHum = min(SetPointHum, ZoneSetPointHum)
                else: pass
        if self.type == SPMType.MZMinHumAverage or self.type == SPMType.MZMaxHumAverage:
            var AverageZoneHum = (SumProductMdotHumTot / SumMdotTot) if SumMdotTot > SmallMassFlow else 0.0
            if SumMdot > SmallMassFlow:
                SetPointHum = max(0.0, AverageZoneHum + SumMoistureLoad / SumMdot)
        else:
            if abs(SumMoistureLoad) < SmallMoistureLoad:
                SetPointHum = self.minSetHum if self.type == SPMType.MZMinHum else self.maxSetHum
        self.setPt = clamp(SetPointHum, self.minSetHum, self.maxSetHum)

struct SPMFollowOutsideAirTemp(SPMBase):
    var refTempType: AirTempType = AirTempType.Invalid
    var offset: Float64 = 0.0

    def calculate(inout self, state: EnergyPlusData):
        self.setPt = (state.dataEnvrn.OutWetBulbTemp if self.refTempType == AirTempType.WetBulb else state.dataEnvrn.OutDryBulbTemp) + self.offset
        self.setPt = clamp(self.setPt, self.minSetTemp, self.maxSetTemp)

struct SPMFollowSysNodeTemp(SPMBase):
    var refTempType: AirTempType = AirTempType.Invalid
    var offset: Float64 = 0.0

    def calculate(inout self, state: EnergyPlusData):
        var RefNodeTemp = state.dataLoopNodes.Node[self.refNodeNum].Temp if self.refTempType == AirTempType.DryBulb else (state.dataLoopNodes.MoreNodeInfo[self.refNodeNum].WetBulbTemp if allocated(state.dataLoopNodes.MoreNodeInfo) and self.refTempType == AirTempType.WetBulb else 0.0)
        self.setPt = RefNodeTemp + self.offset
        self.setPt = clamp(self.setPt, self.minSetTemp, self.maxSetTemp)

struct SPMFollowGroundTemp(SPMBase):
    var refTempType: GroundTempType = GroundTempType.Invalid
    var offset: Float64 = 0.0

    def calculate(inout self, state: EnergyPlusData):
        self.setPt = state.dataEnvrn.GroundTemp[self.refTempType] + self.offset
        self.setPt = clamp(self.setPt, self.minSetTemp, self.maxSetTemp)

struct SPMCondenserEnteringTemp(SPMBase):
    var condenserEnteringTempSched: Optional[Schedule] = None
    var towerDesignInletAirWetBulbTemp: Float64 = 0.0
    var minTowerDesignWetBulbCurveNum: Int = 0
    var minOAWetBulbCurveNum: Int = 0
    var optCondenserEnteringTempCurveNum: Int = 0
    var minLift: Float64 = 0.0
    var maxCondenserEnteringTemp: Float64 = 0.0
    var plantPloc: PlantLocation
    var demandPloc: PlantLocation
    var chillerType: PlantEquipmentType

    def calculate(inout self, state: EnergyPlusData):
        let dspm = state.dataSetPointManager
        var CondenserEnteringTempSetPoint = self.condenserEnteringTempSched.getCurrentVal()
        let supplyLoop = self.plantPloc.loop.LoopSide[LoopSideLocation.Supply]
        let supplyComp = supplyLoop.Branch[self.plantPloc.branchNum].Comp[self.plantPloc.compNum]
        let demandLoop = self.demandPloc.loop.LoopSide[LoopSideLocation.Demand]
        let demandComp = demandLoop.Branch[self.demandPloc.branchNum].Comp[self.demandPloc.compNum]
        var CurLoad = abs(supplyComp.MyLoad)
        if CurLoad > 0:
            var CondInletTemp: Float64 = 0.0
            var EvapOutletTemp: Float64 = 0.0
            var DesignLoad: Float64 = 0.0
            var ActualLoad: Float64 = 0.0
            var DesignCondenserInTemp: Float64 = 0.0
            var DesignEvapOutTemp: Float64 = 0.0
            let NormDesignCondenserFlow = 5.38e-8
            if (self.chillerType == Chiller_Absorption or self.chillerType == Chiller_CombTurbine or
                self.chillerType == Chiller_Electric or self.chillerType == Chiller_ElectricReformEIR or
                self.chillerType == Chiller_EngineDriven):
                DesignCondenserInTemp = supplyComp.TempDesCondIn
                CondInletTemp = state.dataLoopNodes.Node[demandComp.NodeNumIn].Temp
                EvapOutletTemp = state.dataLoopNodes.Node[supplyComp.NodeNumOut].Temp
                DesignEvapOutTemp = supplyComp.TempDesEvapOut
                DesignLoad = supplyComp.MaxLoad
                ActualLoad = self.plantPloc.loop.CoolingDemand
            elif (self.chillerType == Chiller_Indirect_Absorption or self.chillerType == Chiller_DFAbsorption):
                DesignCondenserInTemp = supplyComp.TempDesCondIn
                DesignEvapOutTemp = 6.666
            else:
                DesignCondenserInTemp = 25.0
                DesignEvapOutTemp = 6.666
            dspm.CET_DesignMinCondenserSetPt = 999.0
            dspm.CET_DesignEnteringCondenserTemp = 0.0
            var DesignMinCondenserEnteringTempThisChiller = DesignEvapOutTemp + self.minLift
            dspm.CET_DesignMinCondenserSetPt = min(dspm.CET_DesignMinCondenserSetPt, DesignMinCondenserEnteringTempThisChiller)
            dspm.CET_DesignEnteringCondenserTemp = max(dspm.CET_DesignEnteringCondenserTemp, DesignCondenserInTemp)
            dspm.CET_ActualLoadSum += ActualLoad
            dspm.CET_DesignLoadSum += DesignLoad
            if dspm.CET_ActualLoadSum <= 0:
                CondenserEnteringTempSetPoint = dspm.CET_DesignEnteringCondenserTemp
                return
            var WeightedActualLoad: Float64 = 0.0
            var WeightedDesignLoad: Float64 = 0.0
            if dspm.CET_ActualLoadSum != 0 and dspm.CET_DesignLoadSum != 0:
                WeightedActualLoad = ((ActualLoad / dspm.CET_ActualLoadSum) * ActualLoad)
                WeightedDesignLoad = ((DesignLoad / dspm.CET_DesignLoadSum) * DesignLoad)
            dspm.CET_WeightedActualLoadSum += WeightedActualLoad
            dspm.CET_WeightedDesignLoadSum += WeightedDesignLoad
            dspm.CET_WeightedLoadRatio = dspm.CET_WeightedActualLoadSum / dspm.CET_WeightedDesignLoadSum
            dspm.CET_DesignMinWetBulbTemp = CurveValue(state, self.minTowerDesignWetBulbCurveNum, state.dataEnvrn.OutWetBulbTemp, dspm.CET_WeightedLoadRatio, self.towerDesignInletAirWetBulbTemp, NormDesignCondenserFlow)
            dspm.CET_MinActualWetBulbTemp = CurveValue(state, self.minOAWetBulbCurveNum, dspm.CET_DesignMinWetBulbTemp, dspm.CET_WeightedLoadRatio, self.towerDesignInletAirWetBulbTemp, NormDesignCondenserFlow)
            dspm.CET_OptCondenserEnteringTemp = CurveValue(state, self.optCondenserEnteringTempCurveNum, state.dataEnvrn.OutWetBulbTemp, dspm.CET_WeightedLoadRatio, self.towerDesignInletAirWetBulbTemp, NormDesignCondenserFlow)
            dspm.CET_CurMinLift = 9999.0
            var TempMinLift = CondInletTemp - EvapOutletTemp
            dspm.CET_CurMinLift = min(dspm.CET_CurMinLift, TempMinLift)
        var SetPoint: Float64 = 0.0
        if (dspm.CET_WeightedLoadRatio >= 0.90) and (dspm.CET_OptCondenserEnteringTemp >= (dspm.CET_DesignEnteringCondenserTemp + 1.0)):
            SetPoint = dspm.CET_DesignEnteringCondenserTemp + 1.0
        elif (state.dataEnvrn.OutWetBulbTemp >= dspm.CET_MinActualWetBulbTemp) and (self.towerDesignInletAirWetBulbTemp >= dspm.CET_DesignMinWetBulbTemp) and (dspm.CET_CurMinLift > self.minLift):
            SetPoint = dspm.CET_OptCondenserEnteringTemp
        else:
            SetPoint = CondenserEnteringTempSetPoint
        self.setPt = max(SetPoint, dspm.CET_DesignMinCondenserSetPt)

struct SPMVar:
    var Type: VariableType = VariableType.Invalid
    var Num: Int = 0

struct SPMIdealCondenserEnteringTemp(SPMBase):
    var minLift: Float64 = 0.0
    var maxCondenserEnteringTemp: Float64 = 0.0
    var chillerPloc: PlantLocation
    var chillerVar: SPMVar
    var chilledWaterPumpVar: SPMVar
    var towerVars: List[SPMVar] = List[SPMVar]()
    var condenserPumpVar: SPMVar
    var chillerType: PlantEquipmentType = PlantEquipmentType.Invalid
    var towerPlocs: List[PlantLocation] = List[PlantLocation]()
    var numTowers: Int = 0
    var condenserPumpPloc: PlantLocation
    var chilledWaterPumpPloc: PlantLocation
    var setupIdealCondEntSetPtVars: Bool = True

    def calculate(inout self, state: EnergyPlusData):
        let dspm = state.dataSetPointManager
        let supplyLoop = self.chillerPloc.loop.LoopSide[LoopSideLocation.Supply]
        let supplyComp = supplyLoop.Branch[self.chillerPloc.branchNum].Comp[self.chillerPloc.compNum]
        if state.dataGlobals.MetersHaveBeenInitialized:
            if self.setupIdealCondEntSetPtVars:
                self.SetupMeteredVarsForSetPt(state)
                self.setupIdealCondEntSetPtVars = False
        if state.dataGlobals.MetersHaveBeenInitialized and state.dataGlobals.RunOptCondEntTemp:
            var CurLoad = abs(supplyComp.MyLoad)
            if CurLoad > 0:
                var EvapOutletTemp = (state.dataLoopNodes.Node[supplyComp.NodeNumOut].Temp if (self.chillerType == Chiller_Absorption or self.chillerType == Chiller_CombTurbine or self.chillerType == Chiller_Electric or self.chillerType == Chiller_ElectricReformEIR or self.chillerType == Chiller_EngineDriven) else 6.666)
                var CondTempLimit = self.minLift + EvapOutletTemp
                var TotEnergy = self.calculateCurrentEnergyUsage(state)
                self.setupSetPointAndFlags(TotEnergy, dspm.ICET_TotEnergyPre, dspm.ICET_CondenserWaterSetPt, CondTempLimit, state.dataGlobals.RunOptCondEntTemp, dspm.ICET_RunSubOptCondEntTemp, dspm.ICET_RunFinalOptCondEntTemp)
            else:
                dspm.ICET_CondenserWaterSetPt = self.maxCondenserEnteringTemp
                dspm.ICET_TotEnergyPre = 0.0
                state.dataGlobals.RunOptCondEntTemp = False
                dspm.ICET_RunSubOptCondEntTemp = False
        else:
            dspm.ICET_CondenserWaterSetPt = self.maxCondenserEnteringTemp
            state.dataGlobals.RunOptCondEntTemp = False
            dspm.ICET_RunSubOptCondEntTemp = False
        self.setPt = dspm.ICET_CondenserWaterSetPt

    def setupSetPointAndFlags(self, inout TotEnergy: Float64, inout TotEnergyPre: Float64, inout CondWaterSetPoint: Float64, CondTempLimit: Float64, inout RunOptCondEntTemp: Bool, inout RunSubOptCondEntTemp: Bool, inout RunFinalOptCondEntTemp: Bool):
        if TotEnergyPre != 0.0:
            var DeltaTotEnergy = TotEnergyPre - TotEnergy
            if (DeltaTotEnergy > 0) and (CondWaterSetPoint >= CondTempLimit) and (not RunFinalOptCondEntTemp):
                if not RunSubOptCondEntTemp:
                    CondWaterSetPoint -= 1.0
                    RunOptCondEntTemp = True
                else:
                    CondWaterSetPoint -= 0.2
                    RunOptCondEntTemp = True
                TotEnergyPre = TotEnergy
            elif (DeltaTotEnergy < 0) and (not RunSubOptCondEntTemp) and (CondWaterSetPoint > CondTempLimit) and (not RunFinalOptCondEntTemp):
                CondWaterSetPoint += 0.8
                RunOptCondEntTemp = True
                RunSubOptCondEntTemp = True
            else:
                if not RunFinalOptCondEntTemp:
                    CondWaterSetPoint += 0.2
                    RunOptCondEntTemp = True
                    RunSubOptCondEntTemp = False
                    RunFinalOptCondEntTemp = True
                else:
                    TotEnergyPre = 0.0
                    RunOptCondEntTemp = False
