# ZoneEquipmentManager.mojo - Faithful translation from C++ (ZoneEquipmentManager.cc)

# Module imports - assuming corresponding .mojo files exist
from Utils import *
from DataGlobalConstants import *
from DataGlobals import *
from DataHeatBalance import *
from DataSizing import *
from DataZoneEnergyDemands import *
from DataZoneEquipment import *
from  import *
from Array1D import Array1D  # We'll use List but keep name for clarity
from Array2D import Array2D  # We'll use nested List
from EPVector import EPVector
from Optional import Optional
from Psychrometrics import PsyCpAirFnW, PsyHFnTdbW, PsyHgAirFnWTdb, PsyRhoAirFnPbTdbW, PsyWFnTdbRhPb, PsyWFnTdpPb
from General import MovingAvg, ParseTime
from Util import FindItemInList
from UtilityRoutines import ShowSevereError, ShowWarningError, ShowFatalError, ShowContinueError, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, DisplayString
from DataAirLoop import *
from DataAirSystems import *
from DataContaminantBalance import *
from DataConvergParams import *
from DataDefineEquip import *
from DataEnvironment import *
from DataHVACGlobals import *
from DataHeatBalFanSys import *
from DataLoopNode import *
from DataRoomAirModel import *
from DataSurfaces import *
from BaseboardElectric import *
from BaseboardRadiator import *
from ChilledCeilingPanelSimple import CoolingPanelSimple
from CoolTower import *
from DuctLoss import *
from EMSManager import *
from EarthTube import *
from ElectricBaseboardRadiator import *
from EvaporativeCoolers import *
from ExhaustAirSystemManager import *
from FanCoilUnits import *
from Fans import *
from HVACInterfaceManager import *
from HVACStandAloneERV import *
from HVACVariableRefrigerantFlow import *
from HWBaseboardRadiator import *
from HeatRecovery import *
from HighTempRadiantSystem import *
from HybridUnitaryAirConditioners import *
from InternalHeatGains import *
from LowTempRadiantSystem import *
from OutdoorAirUnit import *
from PurchasedAirManager import *
from RefrigeratedCase import *
from ReturnAirPathManager import *
from ScheduleManager import *
from SplitterComponent import *
from SteamBaseboardRadiator import *
from SystemAvailabilityManager import Avail
from ThermalChimney import *
from UnitHeater import *
from UnitVentilator import *
from UserDefinedComponents import *
from VentilatedSlab import *
from WaterThermalTanks import *
from WindowAC import *
from ZoneAirLoopEquipmentManager import *
from ZoneDehumidifier import *
from ZonePlenum import *
from ZoneTempPredictorCorrector import *
from DisplayRoutines import DisplayString

# Import constants and types
from DataSizing import (
    SupplyAirTemperature, TemperatureDifference, SupplyAirHumidityRatio,
    AirflowSizingMethod, ZoneSizing, DOASControl, SizingConcurrence,
    AutoSize, calcDesignSpecificationOutdoorAir
)
from DataZoneEquipment import (
    ZoneEquipType, EquipConfiguration, LoadDist, AirLoopHVACZone,
    NumValidSysAvailZoneComponents, scaleInletFlows
)
from DataGlobalConstants import Constant
from HVAC import SetptType, SmallLoad, SmallTempDiff, SmallMassFlow, VerySmallMassFlow, RetTempMax, RetTempMin, SmallAirVolFlow
from DataHeatBalance import (
    ZoneAirBalanceData, InfiltrationModelType, InfiltrationFlow, AdjustmentType,
    VentilationModelType, VentilationType, HybridCtrlType, InfVentDensityBasis,
    AllocateIntGains
)
from DataHeatBalFanSys import zoneTstatSetpts
from DataRoomAir import AirPatternZoneInfo
from DataSurface import (
    SurfWinAirflowThisTS, SurfWinAirflowDestination, SurfWinTAirflowGapOutlet,
    WindowAirFlowDestination
)
from DataContaminantBalance import Contaminant
from DataConvergParams import CalledFrom
from DataEnvironment import EnvironmentName
from DataHVACGlobals import FracTimeStepZone, TimeStepSysSec, FanOp
from DataLoopNode import Node
from DataAirLoop import AirLoopFlow
from DataAirSystems import PrimaryAirSystems
from DataDefineEquip import AirDistUnit
from DataDuctLoss import DuctLossSimu
from DataZoneEnergyDemands import ZoneSystemSensibleDemand, ZoneSystemMoistureDemand
from DataSizing import (
    ZoneSizingData, ZoneSizingInputData, DesDayWeathData, TermUnitFinalZoneSizing,
    SetupEMSInternalVariable, SetupEMSActuator
)
from DataZoneEquipment import (
    ZoneEquipList, ZoneEquipAvail, supplyAirPath, SupplyAirPath
)

# Use constant PeakHrMinFmt (assume defined globally)
alias PeakHrMinFmt = "{:02}:{:02}"

# For ObjexxFCL style, we'll use List with 0-based indexing
# But keep the original variable names

struct SimulationOrder:
    var EquipTypeName: String
    var equipType: DataZoneEquipment.ZoneEquipType = DataZoneEquipment.ZoneEquipType.Invalid
    var EquipName: String
    var EquipPtr: Int = 0
    var CoolingPriority: Int = 0
    var HeatingPriority: Int = 0

struct ZoneEquipmentManagerData:
    var AvgData: List[Float64] = List[Float64]()
    var NumOfTimeStepInDay: Int = 0
    var GetZoneEquipmentInputFlag: Bool = True
    var SizeZoneEquipmentOneTimeFlag: Bool = True
    var PrioritySimOrder: List[SimulationOrder] = List[SimulationOrder]()
    var InitZoneEquipmentOneTimeFlag: Bool = True
    var InitZoneEquipmentEnvrnFlag: Bool = True
    var FirstPassZoneEquipFlag: Bool = True

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = ZoneEquipmentManagerData()

def ManageZoneEquipment(
    inout state: EnergyPlusData,
    FirstHVACIteration: Bool,
    inout SimZone: Bool,
    inout SimAir: Bool
):
    InitZoneEquipment(state, FirstHVACIteration)
    if state.dataGlobal.ZoneSizingCalc:
        SizeZoneEquipment(state)
    else:
        SimZoneEquipment(state, FirstHVACIteration, SimAir)
        state.dataZoneEquip.ZoneEquipSimulatedOnce = True
    UpdateZoneEquipment(state, SimAir)
    SimZone = False

def GetZoneEquipment(inout state: EnergyPlusData):
    if state.dataZoneEquipmentManager.GetZoneEquipmentInputFlag:
        GetZoneEquipmentData(state)
        state.dataZoneEquipmentManager.GetZoneEquipmentInputFlag = False
        state.dataZoneEquip.ZoneEquipInputsFilled = True
        state.dataZoneEquipmentManager.NumOfTimeStepInDay = state.dataGlobal.TimeStepsInHour * Constant.iHoursInDay
        var MaxNumOfEquipTypes: Int = 0
        for Counter in range(state.dataGlobal.NumOfZones):
            if not state.dataZoneEquip.ZoneEquipConfig[Counter].IsControlled:
                continue
            MaxNumOfEquipTypes = max(MaxNumOfEquipTypes, state.dataZoneEquip.ZoneEquipList[Counter].NumOfEquipTypes)
        state.dataZoneEquipmentManager.PrioritySimOrder = List[SimulationOrder](MaxNumOfEquipTypes)

def InitZoneEquipment(inout state: EnergyPlusData, FirstHVACIteration: Bool):
    if state.dataZoneEquipmentManager.InitZoneEquipmentOneTimeFlag:
        state.dataZoneEquipmentManager.InitZoneEquipmentOneTimeFlag = False
        state.dataSize.ZoneEqSizing = List[DataSizing.ZoneEqSizingData](state.dataGlobal.NumOfZones)
        for ControlledZoneNum in range(state.dataGlobal.NumOfZones):
            if not state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].IsControlled:
                continue
            if state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].EquipListIndex == 0:
                continue
            ZoneEquipCount = state.dataZoneEquip.ZoneEquipList[state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum].EquipListIndex - 1].NumOfEquipTypes
            var thisZoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum]
            thisZoneSysEnergyDemand.NumZoneEquipment = ZoneEquipCount
            thisZoneSysEnergyDemand.SequencedOutputRequired = List[Float64](ZoneEquipCount)
            thisZoneSysEnergyDemand.SequencedOutputRequiredToHeatingSP = List[Float64](ZoneEquipCount)
            thisZoneSysEnergyDemand.SequencedOutputRequiredToCoolingSP = List[Float64](ZoneEquipCount)
            var thisZoneSysMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ControlledZoneNum]
            thisZoneSysMoistureDemand.NumZoneEquipment = ZoneEquipCount
            thisZoneSysMoistureDemand.SequencedOutputRequired = List[Float64](ZoneEquipCount)
            thisZoneSysMoistureDemand.SequencedOutputRequiredToHumidSP = List[Float64](ZoneEquipCount)
            thisZoneSysMoistureDemand.SequencedOutputRequiredToDehumidSP = List[Float64](ZoneEquipCount)
            state.dataSize.ZoneEqSizing[ControlledZoneNum].SizingMethod = List[Int](HVAC.NumOfSizingTypes)
            for i in range(HVAC.NumOfSizingTypes):
                state.dataSize.ZoneEqSizing[ControlledZoneNum].SizingMethod[i] = 0
            if state.dataHeatBal.doSpaceHeatBalanceSimulation or state.dataHeatBal.doSpaceHeatBalanceSizing:
                for spaceNum in state.dataHeatBal.Zone[ControlledZoneNum].spaceIndexes:
                    var thisSpaceSysEnergyDemand = state.dataZoneEnergyDemand.spaceSysEnergyDemand[spaceNum]
                    thisSpaceSysEnergyDemand.NumZoneEquipment = ZoneEquipCount
                    thisSpaceSysEnergyDemand.SequencedOutputRequired = List[Float64](ZoneEquipCount)
                    thisSpaceSysEnergyDemand.SequencedOutputRequiredToHeatingSP = List[Float64](ZoneEquipCount)
                    thisSpaceSysEnergyDemand.SequencedOutputRequiredToCoolingSP = List[Float64](ZoneEquipCount)
                    var thisSpaceSysMoistureDemand = state.dataZoneEnergyDemand.spaceSysMoistureDemand[spaceNum]
                    thisSpaceSysMoistureDemand.NumZoneEquipment = ZoneEquipCount
                    thisSpaceSysMoistureDemand.SequencedOutputRequired = List[Float64](ZoneEquipCount)
                    thisSpaceSysMoistureDemand.SequencedOutputRequiredToHumidSP = List[Float64](ZoneEquipCount)
                    thisSpaceSysMoistureDemand.SequencedOutputRequiredToDehumidSP = List[Float64](ZoneEquipCount)
    if state.dataZoneEquipmentManager.InitZoneEquipmentEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
        state.dataZoneEquip.ZoneEquipAvail = Avail.Status.NoAction
        if len(state.dataAvail.ZoneComp) > 0:
            for ZoneEquipType in range(NumValidSysAvailZoneComponents):
                if len(state.dataAvail.ZoneComp[ZoneEquipType].ZoneCompAvailMgrs) > 0:
                    var zoneComp = state.dataAvail.ZoneComp[ZoneEquipType]
                    for ZoneCompNum in range(zoneComp.TotalNumComp):
                        zoneComp.ZoneCompAvailMgrs[ZoneCompNum].availStatus = Avail.Status.NoAction
                        zoneComp.ZoneCompAvailMgrs[ZoneCompNum].StartTime = 0
                        zoneComp.ZoneCompAvailMgrs[ZoneCompNum].StopTime = 0
        for thisZoneEquipConfig in state.dataZoneEquip.ZoneEquipConfig:
            if not thisZoneEquipConfig.IsControlled:
                continue
            thisZoneEquipConfig.beginEnvirnInit(state)
        if state.dataHeatBal.doSpaceHeatBalanceSimulation:
            for thisSpaceEquipConfig in state.dataZoneEquip.spaceEquipConfig:
                if not thisSpaceEquipConfig.IsControlled:
                    continue
                thisSpaceEquipConfig.beginEnvirnInit(state)
        state.dataZoneEquipmentManager.InitZoneEquipmentEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataZoneEquipmentManager.InitZoneEquipmentEnvrnFlag = True
    for thisZoneEquipConfig in state.dataZoneEquip.ZoneEquipConfig:
        if not thisZoneEquipConfig.IsControlled:
            continue
        thisZoneEquipConfig.hvacTimeStepInit(state, FirstHVACIteration)
    if state.dataHeatBal.doSpaceHeatBalanceSimulation:
        for thisSpaceEquipConfig in state.dataZoneEquip.spaceEquipConfig:
            if not thisSpaceEquipConfig.IsControlled:
                continue
            thisSpaceEquipConfig.hvacTimeStepInit(state, FirstHVACIteration)
    for airLoop in range(state.dataHVACGlobal.NumPrimaryAirSys):
        var airLoopFlow = state.dataAirLoop.AirLoopFlow[airLoop]
        airLoopFlow.SupFlow = 0.0
        airLoopFlow.ZoneRetFlow = 0.0
        airLoopFlow.SysRetFlow = 0.0
        airLoopFlow.RecircFlow = 0.0
        airLoopFlow.LeakFlow = 0.0
        airLoopFlow.ExcessZoneExhFlow = 0.0

def sizeZoneSpaceEquipmentPart1(
    inout state: EnergyPlusData,
    zoneEquipConfig: DataZoneEquipment.EquipConfiguration,
    zsCalcSizing: DataSizing.ZoneSizingData,
    zsEnergyDemand: DataZoneEnergyDemands.ZoneSystemSensibleDemand,
    zsMoistureDemand: DataZoneEnergyDemands.ZoneSystemMoistureDemand,
    zoneOrSpace: DataHeatBalance.ZoneData,
    zoneNum: Int,
    spaceNum: Int = 0
):
    alias RoutineName = String("sizeZoneSpaceEquipmentPart1")
    var nonAirSystemResponse: Float64 = 0.0
    var sysDepZoneLoads: Float64 = 0.0
    var zoneNodeNum: Int = 0
    if spaceNum > 0:
        nonAirSystemResponse = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum].NonAirSystemResponse
        sysDepZoneLoads = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum].SysDepZoneLoads
        zoneNodeNum = state.dataHeatBal.space[spaceNum].SystemZoneNodeNumber
    else:
        nonAirSystemResponse = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum].NonAirSystemResponse
        sysDepZoneLoads = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum].SysDepZoneLoads
        zoneNodeNum = state.dataHeatBal.Zone[zoneNum].SystemZoneNodeNumber
    nonAirSystemResponse = 0.0
    sysDepZoneLoads = 0.0
    var zoneNode = state.dataLoopNodes.Node[zoneNodeNum]
    initOutputRequired(state, zoneNum, zsEnergyDemand, zsMoistureDemand, True, False, spaceNum)
    var LatOutputProvidedNoDOAS: Float64 = zsMoistureDemand.RemainingOutputRequired
    var SysOutputProvidedNoDOAS: Float64 = zsEnergyDemand.RemainingOutputRequired
    if state.dataZoneEnergyDemand.DeadBandOrSetback[zoneNum]:
        SysOutputProvidedNoDOAS = 0.0
    if not ((zsMoistureDemand.OutputRequiredToHumidifyingSP > 0.0 and zsMoistureDemand.OutputRequiredToDehumidifyingSP > 0.0) or
            (zsMoistureDemand.OutputRequiredToHumidifyingSP < 0.0 and zsMoistureDemand.OutputRequiredToDehumidifyingSP < 0.0)):
        LatOutputProvidedNoDOAS = 0.0
    var supplyAirNodeNum: Int = 0
    if zsCalcSizing.AccountForDOAS:
        var DOASMassFlowRate: Float64 = 0.0
        var DOASSupplyTemp: Float64 = 0.0
        var DOASSupplyHumRat: Float64 = 0.0
        var DOASCpAir: Float64 = 0.0
        var DOASSysOutputProvided: Float64 = 0.0
        var DOASLatOutputProvided: Float64 = 0.0
        var TotDOASSysOutputProvided: Float64 = 0.0
        var HR90H: Float64 = 0.0
        var HR90L: Float64 = 0.0
        var supplyAirNodeNum1: Int = 0
        var supplyAirNodeNum2: Int = 0
        if zoneEquipConfig.NumInletNodes >= 2:
            supplyAirNodeNum1 = zoneEquipConfig.InletNode[0]
            supplyAirNodeNum2 = zoneEquipConfig.InletNode[1]
        elif zoneEquipConfig.NumInletNodes >= 1:
            supplyAirNodeNum1 = zoneEquipConfig.InletNode[0]
            supplyAirNodeNum2 = 0
        else:
            ShowSevereError(state, format("{}: to account for the effect a Dedicated Outside Air System on zone equipment sizing", RoutineName))
            ShowContinueError(state, "there must be at least one zone air inlet node")
            ShowFatalError(state, "Previous severe error causes abort ")
        HR90H = PsyWFnTdbRhPb(state, zsCalcSizing.DOASHighSetpoint, 0.9, state.dataEnvrn.StdBaroPress)
        HR90L = PsyWFnTdbRhPb(state, zsCalcSizing.DOASLowSetpoint, 0.9, state.dataEnvrn.StdBaroPress)
        DOASMassFlowRate = state.dataSize.CalcFinalZoneSizing[zoneNum].MinOA * state.dataEnvrn.StdRhoAir
        CalcDOASSupCondsForSizing(
            state,
            state.dataEnvrn.OutDryBulbTemp,
            state.dataEnvrn.OutHumRat,
            zsCalcSizing.DOASControlStrategy,
            zsCalcSizing.DOASLowSetpoint,
            zsCalcSizing.DOASHighSetpoint,
            HR90H,
            HR90L,
            DOASSupplyTemp,
            DOASSupplyHumRat
        )
        DOASCpAir = PsyCpAirFnW(DOASSupplyHumRat)
        DOASSysOutputProvided = DOASMassFlowRate * DOASCpAir * (DOASSupplyTemp - zoneNode.Temp)
        TotDOASSysOutputProvided = DOASMassFlowRate * (PsyHFnTdbW(DOASSupplyTemp, DOASSupplyHumRat) - PsyHFnTdbW(zoneNode.Temp, zoneNode.HumRat))
        if zsCalcSizing.zoneLatentSizing:
            DOASLatOutputProvided = DOASMassFlowRate * (DOASSupplyHumRat - zoneNode.HumRat)
        updateSystemOutputRequired(state, zoneNum, DOASSysOutputProvided, DOASLatOutputProvided, zsEnergyDemand, zsMoistureDemand)
        var supplyAirNode1 = state.dataLoopNodes.Node[supplyAirNodeNum1]
        supplyAirNode1.Temp = DOASSupplyTemp
        supplyAirNode1.HumRat = DOASSupplyHumRat
        supplyAirNode1.MassFlowRate = DOASMassFlowRate
        supplyAirNode1.Enthalpy = PsyHFnTdbW(DOASSupplyTemp, DOASSupplyHumRat)
        zsCalcSizing.DOASHeatAdd = DOASSysOutputProvided
        zsCalcSizing.DOASLatAdd = TotDOASSysOutputProvided - DOASSysOutputProvided
        supplyAirNodeNum = supplyAirNodeNum2
        zsCalcSizing.DOASSupMassFlow = DOASMassFlowRate
        zsCalcSizing.DOASSupTemp = DOASSupplyTemp
        zsCalcSizing.DOASSupHumRat = DOASSupplyHumRat
        if DOASSysOutputProvided > 0.0:
            zsCalcSizing.DOASHeatLoad = DOASSysOutputProvided
            zsCalcSizing.DOASCoolLoad = 0.0
            zsCalcSizing.DOASTotCoolLoad = 0.0
        else:
            zsCalcSizing.DOASCoolLoad = DOASSysOutputProvided
            zsCalcSizing.DOASTotCoolLoad = TotDOASSysOutputProvided
            zsCalcSizing.DOASHeatLoad = 0.0
    else:
        if zoneEquipConfig.NumInletNodes > 0:
            supplyAirNodeNum = zoneEquipConfig.InletNode[0]
        else:
            supplyAirNodeNum = 0
    var DeltaTemp: Float64 = 0.0
    var CpAir: Float64 = 0.0
    var SysOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var Temp: Float64 = 0.0
    var HumRat: Float64 = 0.0
    var Enthalpy: Float64 = 0.0
    var MassFlowRate: Float64 = 0.0
    if not state.dataZoneEnergyDemand.DeadBandOrSetback[zoneNum] and abs(zsEnergyDemand.RemainingOutputRequired) > HVAC.SmallLoad:
        if zsEnergyDemand.RemainingOutputRequired < 0.0:
            if zsCalcSizing.ZnCoolDgnSAMethod == SupplyAirTemperature:
                Temp = zsCalcSizing.CoolDesTemp
                HumRat = zsCalcSizing.CoolDesHumRat
                DeltaTemp = Temp - zoneNode.Temp
                if zoneOrSpace.HasAdjustedReturnTempByITE and not (state.dataGlobal.BeginSimFlag):
                    DeltaTemp = Temp - zoneOrSpace.AdjustedReturnTempByITE
            else:
                DeltaTemp = -abs(zsCalcSizing.CoolDesTempDiff)
                Temp = DeltaTemp + zoneNode.Temp
                if zoneOrSpace.HasAdjustedReturnTempByITE and not (state.dataGlobal.BeginSimFlag):
                    Temp = DeltaTemp + zoneOrSpace.AdjustedReturnTempByITE
                HumRat = zsCalcSizing.CoolDesHumRat
        else:
            if zsCalcSizing.ZnHeatDgnSAMethod == SupplyAirTemperature:
                Temp = zsCalcSizing.HeatDesTemp
                HumRat = zsCalcSizing.HeatDesHumRat
                DeltaTemp = Temp - zoneNode.Temp
            else:
                DeltaTemp = abs(zsCalcSizing.HeatDesTempDiff)
                Temp = DeltaTemp + zoneNode.Temp
                HumRat = zsCalcSizing.HeatDesHumRat
        Enthalpy = PsyHFnTdbW(Temp, HumRat)
        SysOutputProvided = zsEnergyDemand.RemainingOutputRequired
        CpAir = PsyCpAirFnW(HumRat)
        if abs(DeltaTemp) > HVAC.SmallTempDiff:
            MassFlowRate = max(SysOutputProvided / (CpAir * DeltaTemp), 0.0)
        else:
            MassFlowRate = 0.0
        if zsCalcSizing.SupplyAirAdjustFactor > 1.0:
            MassFlowRate *= zsCalcSizing.SupplyAirAdjustFactor
    else:
        Temp = zoneNode.Temp
        HumRat = zoneNode.HumRat
        Enthalpy = zoneNode.Enthalpy
        MassFlowRate = 0.0
    if SysOutputProvided > 0.0:
        zsCalcSizing.HeatLoad = SysOutputProvided
        zsCalcSizing.HeatMassFlow = MassFlowRate
        zsCalcSizing.CoolLoad = 0.0
        zsCalcSizing.CoolMassFlow = 0.0
    elif SysOutputProvided < 0.0:
        zsCalcSizing.CoolLoad = -SysOutputProvided
        zsCalcSizing.CoolMassFlow = MassFlowRate
        zsCalcSizing.HeatLoad = 0.0
        zsCalcSizing.HeatMassFlow = 0.0
    else:
        zsCalcSizing.CoolLoad = 0.0
        zsCalcSizing.CoolMassFlow = 0.0
        zsCalcSizing.HeatLoad = 0.0
        zsCalcSizing.HeatMassFlow = 0.0
    zsCalcSizing.HeatZoneTemp = zoneNode.Temp
    zsCalcSizing.HeatZoneHumRat = zoneNode.HumRat
    zsCalcSizing.CoolZoneTemp = zoneNode.Temp
    zsCalcSizing.CoolZoneHumRat = zoneNode.HumRat
    zsCalcSizing.HeatOutTemp = state.dataEnvrn.OutDryBulbTemp
    zsCalcSizing.HeatMCPI = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum].MCPI
    zsCalcSizing.HeatMCPV = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum].MCPV
    zsCalcSizing.HeatOutHumRat = state.dataEnvrn.OutHumRat
    zsCalcSizing.CoolOutTemp = state.dataEnvrn.OutDryBulbTemp
    zsCalcSizing.CoolOutHumRat = state.dataEnvrn.OutHumRat
    var LatentAirMassFlow: Float64 = 0.0
    var MoistureLoad: Float64 = 0.0
    var HgAir: Float64 = PsyHgAirFnWTdb(zoneNode.HumRat, zoneNode.Temp)
    if zsCalcSizing.zoneLatentSizing:
        if (zsMoistureDemand.OutputRequiredToHumidifyingSP > 0.0 and zsMoistureDemand.OutputRequiredToDehumidifyingSP > 0.0) or \
           (zsMoistureDemand.OutputRequiredToHumidifyingSP < 0.0 and zsMoistureDemand.OutputRequiredToDehumidifyingSP < 0.0):
            LatOutputProvided = zsMoistureDemand.RemainingOutputRequired
        var DeltaHumRat: Float64 = 0.0
        if LatOutputProvided < 0.0:
            if zsCalcSizing.ZnLatCoolDgnSAMethod == SupplyAirHumidityRatio:
                DeltaHumRat = zsCalcSizing.LatentCoolDesHumRat - zoneNode.HumRat
            else:
                DeltaHumRat = -zsCalcSizing.CoolDesHumRatDiff
        elif LatOutputProvided > 0.0:
            if zsCalcSizing.ZnLatHeatDgnSAMethod == SupplyAirHumidityRatio:
                DeltaHumRat = zsCalcSizing.LatentHeatDesHumRat - zoneNode.HumRat
            else:
                DeltaHumRat = zsCalcSizing.HeatDesHumRatDiff
        if abs(DeltaHumRat) > HVAC.VerySmallMassFlow:
            LatentAirMassFlow = max(0.0, LatOutputProvided / DeltaHumRat)
        MoistureLoad = LatOutputProvided * HgAir
        if MassFlowRate > 0.0:
            HumRat = zoneNode.HumRat + LatOutputProvided / MassFlowRate
            CpAir = PsyCpAirFnW(HumRat)
            Temp = (SysOutputProvided / (MassFlowRate * CpAir)) + zoneNode.Temp
            Enthalpy = PsyHFnTdbW(Temp, HumRat)
        elif LatentAirMassFlow > 0.0:
            HumRat = zoneNode.HumRat + LatOutputProvided / LatentAirMassFlow
            Enthalpy = PsyHFnTdbW(Temp, HumRat)
            MassFlowRate = (LatentAirMassFlow if LatentAirMassFlow > HVAC.VerySmallMassFlow else 0.0)
        zsCalcSizing.HeatLatentLoad = MoistureLoad if LatOutputProvided > 0.0 else 0.0
        zsCalcSizing.ZoneHeatLatentMassFlow = LatentAirMassFlow if LatOutputProvided > 0.0 else 0.0
        zsCalcSizing.CoolLatentLoad = -MoistureLoad if LatOutputProvided < 0.0 else 0.0
        zsCalcSizing.ZoneCoolLatentMassFlow = LatentAirMassFlow if LatOutputProvided < 0.0 else 0.0
        zsCalcSizing.HeatLoadNoDOAS = SysOutputProvidedNoDOAS if SysOutputProvidedNoDOAS > 0.0 else 0.0
        zsCalcSizing.CoolLoadNoDOAS = -SysOutputProvidedNoDOAS if SysOutputProvidedNoDOAS < 0.0 else 0.0
        zsCalcSizing.HeatLatentLoadNoDOAS = LatOutputProvidedNoDOAS * HgAir if LatOutputProvidedNoDOAS > 0.0 else 0.0
        zsCalcSizing.CoolLatentLoadNoDOAS = -LatOutputProvidedNoDOAS * HgAir if LatOutputProvidedNoDOAS < 0.0 else 0.0
    if supplyAirNodeNum > 0:
        var supplyAirNode = state.dataLoopNodes.Node[supplyAirNodeNum]
        supplyAirNode.Temp = Temp
        supplyAirNode.HumRat = HumRat
        supplyAirNode.Enthalpy = Enthalpy
        supplyAirNode.MassFlowRate = MassFlowRate
    else:
        nonAirSystemResponse = SysOutputProvided
        if zsCalcSizing.zoneLatentSizing:
            var zoneMult = zoneOrSpace.Multiplier * zoneOrSpace.ListMultiplier
            var zoneLatentGain: Float64 = 0.0
            if spaceNum > 0:
                zoneLatentGain = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum].latentGain
            else:
                zoneLatentGain = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zoneNum].latentGain
            zoneLatentGain += (LatOutputProvided * HgAir) / zoneMult
        if state.dataHeatBal.doSpaceHeatBalance and spaceNum == 0:
            for spaceNum2 in state.dataHeatBal.Zone[zoneNum].spaceIndexes:
                var spHB = state.dataZoneTempPredictorCorrector.spaceHeatBalance[spaceNum2]
                spHB.NonAirSystemResponse = nonAirSystemResponse * state.dataHeatBal.space[spaceNum2].fracZoneVolume
                if zsCalcSizing.zoneLatentSizing:
                    var zoneMult = zoneOrSpace.Multiplier * zoneOrSpace.ListMultiplier
                    spHB.latentGain += (LatOutputProvided * HgAir) * state.dataHeatBal.space[spaceNum2].fracZoneVolume / zoneMult
    updateSystemOutputRequired(state, zoneNum, SysOutputProvided, LatOutputProvided, zsEnergyDemand, zsMoistureDemand)

def sizeZoneSpaceEquipmentPart2(
    inout state: EnergyPlusData,
    zoneEquipConfig: DataZoneEquipment.EquipConfiguration,
    zsCalcSizing: DataSizing.ZoneSizingData,
    zoneNum: Int,
    spaceNum: Int = 0
):
    var returnNodeNum: Int = zoneEquipConfig.ReturnNode[0] if zoneEquipConfig.NumReturnNodes > 0 else 0
    var zoneNodeNum: Int = state.dataHeatBal.space[spaceNum].SystemZoneNodeNumber if spaceNum > 0 else state.dataHeatBal.Zone[zoneNum].SystemZoneNodeNumber
    var RetTemp: Float64 = state.dataLoopNodes.Node[returnNodeNum].Temp if returnNodeNum > 0 else state.dataLoopNodes.Node[zoneNodeNum].Temp
    var zoneTstatSetpt = state.dataHeatBalFanSys.zoneTstatSetpts[zoneNum]
    if zsCalcSizing.HeatLoad > 0.0:
        zsCalcSizing.HeatZoneRetTemp = RetTemp
        zsCalcSizing.HeatTstatTemp = zoneTstatSetpt.setpt if zoneTstatSetpt.setpt > 0.0 else zoneTstatSetpt.setptLo
        zsCalcSizing.CoolTstatTemp = zoneTstatSetpt.setptHi
    elif zsCalcSizing.CoolLoad > 0.0:
        zsCalcSizing.CoolZoneRetTemp = RetTemp
        zsCalcSizing.CoolTstatTemp = zoneTstatSetpt.setpt if zoneTstatSetpt.setpt > 0.0 else zoneTstatSetpt.setptHi
        zsCalcSizing.HeatTstatTemp = zoneTstatSetpt.setptLo
    else:
        zsCalcSizing.CoolZoneRetTemp = RetTemp
        zsCalcSizing.HeatTstatTemp = zoneTstatSetpt.setptLo
        zsCalcSizing.CoolTstatTemp = zoneTstatSetpt.setptHi

def SizeZoneEquipment(inout state: EnergyPlusData):
    if state.dataZoneEquipmentManager.SizeZoneEquipmentOneTimeFlag:
        SetUpZoneSizingArrays(state)
        state.dataZoneEquipmentManager.SizeZoneEquipmentOneTimeFlag = False
    for ControlledZoneNum in range(state.dataGlobal.NumOfZones):
        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum]
        if not zoneEquipConfig.IsControlled:
            continue
        var calcZoneSizing = state.dataSize.CalcZoneSizing[state.dataSize.CurOverallSimDay][ControlledZoneNum]
        var zoneSysEnergyDemand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ControlledZoneNum]
        var zoneSysMoistureDemand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand[ControlledZoneNum]
        var zone = state.dataHeatBal.Zone[ControlledZoneNum]
        sizeZoneSpaceEquipmentPart1(state, zoneEquipConfig, calcZoneSizing, zoneSysEnergyDemand, zoneSysMoistureDemand, zone, ControlledZoneNum)
        if state.dataHeatBal.doSpaceHeatBalance:
            for spaceNum in state.dataHeatBal.Zone[ControlledZoneNum].spaceIndexes:
                sizeZoneSpaceEquipmentPart1(
                    state,
                    state.dataZoneEquip.spaceEquipConfig[spaceNum],
                    state.dataSize.CalcSpaceSizing[state.dataSize.CurOverallSimDay][spaceNum],
                    state.dataZoneEnergyDemand.spaceSysEnergyDemand[spaceNum],
                    state.dataZoneEnergyDemand.spaceSysMoistureDemand[spaceNum],
                    zone,
                    ControlledZoneNum,
                    spaceNum
                )
    CalcZoneMassBalance(state, True)
    CalcZoneLeavingConditions(state, True)
    for ControlledZoneNum in range(state.dataGlobal.NumOfZones):
        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[ControlledZoneNum]
        if not zoneEquipConfig.IsControlled:
            continue
        sizeZoneSpaceEquipmentPart2(state, zoneEquipConfig, state.dataSize.CalcZoneSizing[state.dataSize.CurOverallSimDay][ControlledZoneNum], ControlledZoneNum)
        if state.dataHeatBal.doSpaceHeatBalance:
            for spaceNum in state.dataHeatBal.Zone[ControlledZoneNum].spaceIndexes:
                sizeZoneSpaceEquipmentPart2(state, zoneEquipConfig, state.dataSize.CalcSpaceSizing[state.dataSize.CurOverallSimDay][spaceNum], ControlledZoneNum, spaceNum)

def CalcDOASSupCondsForSizing(
    state: EnergyPlusData,
    OutDB: Float64,
    OutHR: Float64,
    DOASControl: DataSizing.DOASControl,
    DOASLowTemp: Float64,
    DOASHighTemp: Float64,
    W90H: Float64,
    W90L: Float64,
    inout DOASSupTemp: Float64,
    inout DOASSupHR: Float64
):
    alias RoutineName = String("CalcDOASSupCondsForSizing")
    DOASSupTemp = 0.0
    DOASSupHR = 0.0
    if DOASControl == DataSizing.DOASControl.NeutralSup:
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASLowTemp
            DOASSupHR = OutHR
        elif OutDB > DOASHighTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = min(OutHR, W90H)
        else:
            DOASSupTemp = OutDB
            DOASSupHR = OutHR
    elif DOASControl == DataSizing.DOASControl.NeutralDehumSup:
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = OutHR
        else:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = min(OutHR, W90L)
    elif DOASControl == DataSizing.DOASControl.CoolSup:
        if OutDB < DOASLowTemp:
            DOASSupTemp = DOASHighTemp
            DOASSupHR = OutHR
        else:
            DOASSupTemp = DOASLowTemp
            DOASSupHR = min(OutHR, W90L)
    else:
        ShowFatalError(state, format("{}:illegal DOAS design control strategy", RoutineName))

def SetUpZoneSizingArrays(inout state: EnergyPlusData):
    var ErrorsFound: Bool = False
    if not state.dataHeatBal.ZoneIntGain.allocated():
        AllocateIntGains(state)
    for ZoneSizIndex in range(state.dataSize.NumZoneSizingInput):
        var zoneSizingInput = state.dataSize.ZoneSizingInput[ZoneSizIndex]
        var ZoneIndex = FindItemInList(zoneSizingInput.ZoneName, state.dataHeatBal.Zone)
        if ZoneIndex == -1:  # 0-based adjustment
            ShowSevereError(state, format("SetUpZoneSizingArrays: Sizing:Zone=\"{}\" references unknown zone", zoneSizingInput.ZoneName))
            ErrorsFound = True
        if any(e.IsControlled for e in state.dataZoneEquip.ZoneEquipConfig):
            ZoneIndex = FindItemInList(zoneSizingInput.ZoneName, state.dataZoneEquip.ZoneEquipConfig, lambda e: e.ZoneName)
            if ZoneIndex == -1:
                if not state.dataGlobal.isPulseZoneSizing:
                    ShowWarningError(state, format("SetUpZoneSizingArrays: Requested Sizing for Zone=\"{}\", Zone is not found in the Controlled Zones List", zoneSizingInput.ZoneName))
            else:
                state.dataSize.ZoneSizingInput[ZoneSizIndex].ZoneNum = ZoneIndex
            var coolMethod = zoneSizingInput.CoolAirDesMethod
            var heatMethod = zoneSizingInput.HeatAirDesMethod
            if coolMethod == FromDDCalc or heatMethod == FromDDCalc:
                if not ZoneTempPredictorCorrector.VerifyThermostatInZone(state, zoneSizingInput.ZoneName):
                    if not state.dataGlobal.isPulseZoneSizing:
                        ShowWarningError(state, format("SetUpZoneSizingArrays: Requested Sizing for Zone=\"{}\", Zone has no thermostat (ref: ZoneControl:Thermostat, et al)", zoneSizingInput.ZoneName))
        else:
            ShowSevereError(state, "SetUpZoneSizingArrays: Zone Sizing is requested but there are no ZoneHVAC:EquipmentConnections statements.")
            ErrorsFound = True
    AutoCalcDOASControlStrategy(state)
    var totDesDays = state.dataEnvrn.TotDesDays + state.dataEnvrn.TotRunDesPersDays
    state.dataSize.ZoneSizing = List[List[ZoneSizingData]](totDesDays)
    for i in range(totDesDays):
        state.dataSize.ZoneSizing[i] = List[ZoneSizingData](state.dataGlobal.NumOfZones)
    state.dataSize.FinalZoneSizing = List[ZoneSizingData](state.dataGlobal.NumOfZones)
    state.dataSize.CalcZoneSizing = List[List[ZoneSizingData]](totDesDays)
    for i in range(totDesDays):
        state.dataSize.CalcZoneSizing[i] = List[ZoneSizingData](state.dataGlobal.NumOfZones)
    state.dataSize.CalcFinalZoneSizing = List[ZoneSizingData](state.dataGlobal.NumOfZones)
    if state.dataHeatBal.doSpaceHeatBalanceSizing:
        state.dataSize.SpaceSizing = List[List[ZoneSizingData]](totDesDays)
        for i in range(totDesDays):
            state.dataSize.SpaceSizing[i] = List[ZoneSizingData](state.dataGlobal.numSpaces)
        state.dataSize.FinalSpaceSizing = List[ZoneSizingData](state.dataGlobal.numSpaces)
        state.dataSize.CalcSpaceSizing = List[List[ZoneSizingData]](totDesDays)
        for i in range(totDesDays):
            state.dataSize.CalcSpaceSizing[i] = List[ZoneSizingData](state.dataGlobal.numSpaces)
        state.dataSize.CalcFinalSpaceSizing = List[ZoneSizingData](state.dataGlobal.numSpaces)
    state.dataSize.TermUnitFinalZoneSizing = List[TermUnitFinalZoneSizing](state.dataSize.NumAirTerminalUnits)
    for i in range(len(state.dataSize.TermUnitFinalZoneSizing)):
        state.dataSize.TermUnitFinalZoneSizing[i].allocateMemberArrays(state.dataZoneEquipmentManager.NumOfTimeStepInDay)
    state.dataSize.DesDayWeath = List[DesDayWeathData](totDesDays)
    state.dataZoneEquipmentManager.AvgData = List[Float64](state.dataZoneEquipmentManager.NumOfTimeStepInDay)
    for DesDayNum in range(totDesDays):
        var thisDesDayWeather = state.dataSize.DesDayWeath[DesDayNum]
        var nSteps = state.dataGlobal.TimeStepsInHour * Constant.iHoursInDay
        thisDesDayWeather.Temp = List[Float64](nSteps)
        thisDesDayWeather.HumRat = List[Float64](nSteps)
        thisDesDayWeather.Press = List[Float64](nSteps)
        for i in range(nSteps):
            thisDesDayWeather.Temp[i] = 0.0
            thisDesDayWeather.HumRat[i] = 0.0
            thisDesDayWeather.Press[i] = 0.0
    for CtrlZoneNum in range(state.dataGlobal.NumOfZones):
        var zoneEquipConfig = state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum]
        if not zoneEquipConfig.IsControlled:
            continue
        var ZoneSizNum = FindItemInList(zoneEquipConfig.ZoneName, state.dataSize.ZoneSizingInput, lambda z: z.ZoneName)
        var zoneSizingInput: ZoneSizingInputData
        if ZoneSizNum > -1:
            zoneSizingInput = state.dataSize.ZoneSizingInput[ZoneSizNum]
        else:
            zoneSizingInput = state.dataSize.ZoneSizingInput[0]
            if not state.dataGlobal.isPulseZoneSizing:
                ShowWarningError(state, format("SetUpZoneSizingArrays: Sizing for Zone=\"{}\" will use Sizing:Zone specifications listed for Zone=\"{}\".",
                    state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum].ZoneName, zoneSizingInput.ZoneName))
        fillZoneSizingFromInput(state, zoneSizingInput, state.dataSize.ZoneSizing, state.dataSize.CalcZoneSizing,
            state.dataSize.FinalZoneSizing[CtrlZoneNum], state.dataSize.CalcFinalZoneSizing[CtrlZoneNum],
            state.dataHeatBal.Zone[CtrlZoneNum].Name, CtrlZoneNum)
        if state.dataHeatBal.doSpaceHeatBalanceSizing:
            for spaceNum in state.dataHeatBal.Zone[CtrlZoneNum].spaceIndexes:
                fillZoneSizingFromInput(state, zoneSizingInput, state.dataSize.SpaceSizing, state.dataSize.CalcSpaceSizing,
                    state.dataSize.FinalSpaceSizing[spaceNum], state.dataSize.CalcFinalSpaceSizing[spaceNum],
                    state.dataHeatBal.space[spaceNum].Name, spaceNum)
        if state.dataGlobal.AnyEnergyManagementSystemInModel:
            var finalZoneSizing = state.dataSize.FinalZoneSizing[CtrlZoneNum]
            var calcFinalZoneSizing = state.dataSize.CalcFinalZoneSizing[CtrlZoneNum]
            SetupEMSInternalVariable(state, "Final Zone Design Heating Air Mass Flow Rate", finalZoneSizing.ZoneName, "[kg/s]", finalZoneSizing.DesHeatMassFlow)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Heating Air Mass Flow Rate", calcFinalZoneSizing.ZoneName, "[kg/s]", calcFinalZoneSizing.DesHeatMassFlow)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Heating Air Mass Flow Rate", "[kg/s]", calcFinalZoneSizing.EMSOverrideDesHeatMassOn, calcFinalZoneSizing.EMSValueDesHeatMassFlow)
            SetupEMSInternalVariable(state, "Final Zone Design Cooling Air Mass Flow Rate", finalZoneSizing.ZoneName, "[kg/s]", finalZoneSizing.DesCoolMassFlow)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Cooling Air Mass Flow Rate", calcFinalZoneSizing.ZoneName, "[kg/s]", calcFinalZoneSizing.DesCoolMassFlow)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Cooling Air Mass Flow Rate", "[kg/s]", calcFinalZoneSizing.EMSOverrideDesCoolMassOn, calcFinalZoneSizing.EMSValueDesCoolMassFlow)
            SetupEMSInternalVariable(state, "Final Zone Design Heating Load", finalZoneSizing.ZoneName, "[W]", finalZoneSizing.DesHeatLoad)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Heating Load", calcFinalZoneSizing.ZoneName, "[W]", calcFinalZoneSizing.DesHeatLoad)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Heating Load", "[W]", calcFinalZoneSizing.EMSOverrideDesHeatLoadOn, calcFinalZoneSizing.EMSValueDesHeatLoad)
            SetupEMSInternalVariable(state, "Final Zone Design Cooling Load", finalZoneSizing.ZoneName, "[W]", finalZoneSizing.DesCoolLoad)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Cooling Load", calcFinalZoneSizing.ZoneName, "[W]", calcFinalZoneSizing.DesCoolLoad)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Cooling Load", "[W]", calcFinalZoneSizing.EMSOverrideDesCoolLoadOn, calcFinalZoneSizing.EMSValueDesCoolLoad)
            SetupEMSInternalVariable(state, "Final Zone Design Heating Air Density", finalZoneSizing.ZoneName, "[kg/m3]", finalZoneSizing.DesHeatDens)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Heating Air Density", calcFinalZoneSizing.ZoneName, "[kg/m3]", calcFinalZoneSizing.DesHeatDens)
            SetupEMSInternalVariable(state, "Final Zone Design Cooling Air Density", finalZoneSizing.ZoneName, "[kg/m3]", finalZoneSizing.DesCoolDens)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Cooling Air Density", calcFinalZoneSizing.ZoneName, "[kg/m3]", calcFinalZoneSizing.DesCoolDens)
            SetupEMSInternalVariable(state, "Final Zone Design Heating Volume Flow", finalZoneSizing.ZoneName, "[m3/s]", finalZoneSizing.DesHeatVolFlow)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Heating Volume Flow", calcFinalZoneSizing.ZoneName, "[m3/s]", calcFinalZoneSizing.DesHeatVolFlow)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Heating Vol Flow", "[m3/s]", calcFinalZoneSizing.EMSOverrideDesHeatVolOn, calcFinalZoneSizing.EMSValueDesHeatVolFlow)
            SetupEMSInternalVariable(state, "Final Zone Design Cooling Volume Flow", finalZoneSizing.ZoneName, "[m3/s]", finalZoneSizing.DesCoolVolFlow)
            SetupEMSInternalVariable(state, "Intermediate Zone Design Cooling Volume Flow", calcFinalZoneSizing.ZoneName, "[m3/s]", calcFinalZoneSizing.DesCoolVolFlow)
            SetupEMSActuator(state, "Sizing:Zone", calcFinalZoneSizing.ZoneName, "Zone Design Cooling Vol Flow", "[m3/s]", calcFinalZoneSizing.EMSOverrideDesCoolVolOn, calcFinalZoneSizing.EMSValueDesCoolVolFlow)
            SetupEMSInternalVariable(state, "Zone Outdoor Air Design Volume Flow Rate", calcFinalZoneSizing.ZoneName, "[m3/s]", calcFinalZoneSizing.MinOA)
    var dsoaError: Bool = False
    for oaIndex in range(state.dataSize.NumOARequirements):
        var thisOAReq = state.dataSize.OARequirements[oaIndex]
        if thisOAReq.numDSOA > 0:
            for spaceCounter in range(thisOAReq.numDSOA):
                var thisSpaceName = thisOAReq.dsoaSpaceNames[spaceCounter]
                var thisSpaceNum = FindItemInList(thisSpaceName, state.dataHeatBal.space)
                if thisSpaceNum > -1:
                    thisOAReq.dsoaSpaceIndexes.append(thisSpaceNum)
                else:
                    ShowSevereError(state, format("SetUpZoneSizingArrays: DesignSpecification:OutdoorAir:SpaceList={}", thisOAReq.Name))
                    ShowContinueError(state, format("Space Name={} not found.", thisSpaceName))
                    dsoaError = True
                    ErrorsFound = True
                for loop in range(len(thisOAReq.dsoaSpaceIndexes) - 1):
                    if thisSpaceNum == thisOAReq.dsoaSpaceIndexes[loop]:
                        ShowSevereError(state, format("SetUpZoneSizingArrays: DesignSpecification:OutdoorAir:SpaceList={}", thisOAReq.Name))
                        ShowContinueError(state, format("Space Name={} appears more than once in the list.", thisSpaceName))
                        dsoaError = True
                        ErrorsFound = True
    for CtrlZoneNum in range(state.dataGlobal.NumOfZones):
        if not state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum].IsControlled:
            continue
        var finalZoneSizing = state.dataSize.FinalZoneSizing[CtrlZoneNum]
        var calcFinalZoneSizing = state.dataSize.CalcFinalZoneSizing[CtrlZoneNum]
        calcSizingOA(state, finalZoneSizing, calcFinalZoneSizing, dsoaError, ErrorsFound, CtrlZoneNum)
    if state.dataHeatBal.doSpaceHeatBalanceSizing:
        for spaceNum in range(state.dataGlobal.numSpaces):
            var zoneNum = state.dataHeatBal.space[spaceNum].zoneNum
            if not state.dataZoneEquip.ZoneEquipConfig[zoneNum].IsControlled:
                continue
            var finalSpaceSizing = state.dataSize.FinalSpaceSizing[spaceNum]
            var calcFinalSpaceSizing = state.dataSize.CalcFinalSpaceSizing[spaceNum]
            calcSizingOA(state, finalSpaceSizing, calcFinalSpaceSizing, dsoaError, ErrorsFound, zoneNum, spaceNum)
    state.files.eio.print("! <Load Timesteps in Zone Design Calculation Averaging Window>, Value\n")
    state.files.eio.print(format(" Load Timesteps in Zone Design Calculation Averaging Window, {:4}\n", state.dataSize.NumTimeStepsInAvg))
    state.files.eio.print("! <Heating Sizing Factor Information>, Sizing Factor ID, Value\n")
    state.files.eio.print(format(" Heating Sizing Factor Information, Global, {:12.5G}\n", state.dataSize.GlobalHeatSizingFactor))
    for CtrlZoneNum in range(state.dataGlobal.NumOfZones):
        if not state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum].IsControlled:
            continue
        if state.dataSize.FinalZoneSizing[CtrlZoneNum].HeatSizingFactor != 1.0:
            state.files.eio.print(format(" Heating Sizing Factor Information, Zone {}, {:12.5G}\n",
                state.dataSize.FinalZoneSizing[CtrlZoneNum].ZoneName, state.dataSize.FinalZoneSizing[CtrlZoneNum].HeatSizingFactor))
    state.files.eio.print("! <Cooling Sizing Factor Information>, Sizing Factor ID, Value\n")
    state.files.eio.print(format(" Cooling Sizing Factor Information, Global, {:12.5G}\n", state.dataSize.GlobalCoolSizingFactor))
    for CtrlZoneNum in range(state.dataGlobal.NumOfZones):
        if not state.dataZoneEquip.ZoneEquipConfig[CtrlZoneNum].IsControlled:
            continue
        if state.dataSize.FinalZoneSizing[CtrlZoneNum].CoolSizingFactor != 1.0:
            state.files.eio.print(format(" Cooling Sizing Factor Information, Zone {}, {:12.5G}\n",
                state.dataSize.FinalZoneSizing[CtrlZoneNum].ZoneName, state.dataSize.FinalZoneSizing[CtrlZoneNum].CoolSizingFactor))
    if ErrorsFound:
        ShowFatalError(state, "SetUpZoneSizingArrays: Errors found in Sizing:Zone input")

def calcSizingOA(
    state: EnergyPlusData,
    zsFinalSizing: DataSizing.ZoneSizingData,
    zsCalcFinalSizing: DataSizing.ZoneSizingData,
    inout dsoaError: Bool,
    inout ErrorsFound: Bool,
    zoneNum: Int,
    spaceNum: Int = 0
):
    var TotPeopleInZone: Float64 = 0.0
    var ZoneMinOccupancy: Float64 = 0.0
    var DSOAPtr: Int = zsFinalSizing.ZoneDesignSpecOAIndex
    var thisZone = state.dataHeatBal.Zone[zoneNum]
    var zoneMult = thisZone.Multiplier * thisZone.ListMultiplier
    var floorArea: Float64 = thisZone.FloorArea if spaceNum == 0 else state.dataHeatBal.space[spaceNum].FloorArea
    if DSOAPtr > 0 and not dsoaError:
        var thisOAReq = state.dataSize.OARequirements[DSOAPtr]
        if thisOAReq.numDSOA > 0:
            for spaceCounter in range(thisOAReq.numDSOA):
                var thisSpaceNum = thisOAReq.dsoaSpaceIndexes[spaceCounter]
                if thisSpaceNum > -1:
                    if state.dataHeatBal.space[thisSpaceNum].zoneNum != zoneNum:
                        ShowSevereError(state, format("SetUpZoneSizingArrays: DesignSpecification:OutdoorAir:SpaceList={}", thisOAReq.Name))
                        ShowContinueError(state, format("is invalid for Sizing:Zone={}", zsFinalSizing.ZoneName))
                        ShowContinueError(state, "All spaces in the list must be part of this zone.")
                        ErrorsFound = True
        zsFinalSizing.DesOAFlowPPer = thisOAReq.desFlowPerZonePerson(state, zoneNum, spaceNum)
        zsFinalSizing.DesOAFlowPerArea = thisOAReq.desFlowPerZoneArea(state, zoneNum, spaceNum)
    for PeopleNum in range(state.dataHeatBal.TotPeople):
        var people = state.dataHeatBal.People[PeopleNum]
        if (spaceNum == 0 and people.ZonePtr == zoneNum) or (spaceNum > 0 and people.spaceIndex == spaceNum):
            var numPeople = people.NumberOfPeople * zoneMult
            TotPeopleInZone += numPeople
            var SchMax = people.sched.getMaxVal(state)
            if SchMax > 0:
                zsFinalSizing.ZonePeakOccupancy += numPeople * SchMax
            else:
                zsFinalSizing.ZonePeakOccupancy += numPeople
            ZoneMinOccupancy += numPeople * people.sched.getMinVal(state)
    zsFinalSizing.TotalZoneFloorArea = floorArea * zoneMult
    var OAFromPeople = zsFinalSizing.DesOAFlowPPer * TotPeopleInZone
    var OAFromArea = zsFinalSizing.DesOAFlowPerArea * zsFinalSizing.TotalZoneFloorArea
    zsFinalSizing.TotPeopleInZone = TotPeopleInZone
    zsFinalSizing.TotalOAFromPeople = OAFromPeople
    zsFinalSizing.TotalOAFromArea = OAFromArea
    var MinEz = min(zsFinalSizing.ZoneADEffCooling, zsFinalSizing.ZoneADEffHeating)
    if MinEz == 0:
        MinEz = 1.0
    var vozMin = (ZoneMinOccupancy * zsFinalSizing.DesOAFlowPPer + OAFromArea) / MinEz
    if spaceNum == 0:
        state.dataHeatBal.ZonePreDefRep[zoneNum].VozMin = vozMin
    var equipConfig = state.dataZoneEquip.ZoneEquipConfig[zoneNum] if spaceNum == 0 else state.dataZoneEquip.spaceEquipConfig[spaceNum]
    equipConfig.ZoneDesignSpecOAIndex = DSOAPtr
    equipConfig.ZoneAirDistributionIndex = zsFinalSizing.ZoneAirDistributionIndex
    var OAVolumeFlowRate: Float64 = 0.0
    if not dsoaError:
        var UseOccSchFlag: Bool = False
        var UseMinOASchFlag: Bool = False
        var PerPersonNotSet: Bool = False
        var MaxOAVolFlowFlag: Bool = False
        OAVolumeFlowRate = calcDesignSpecificationOutdoorAir(state, DSOAPtr, zoneNum, UseOccSchFlag, UseMinOASchFlag, PerPersonNotSet, MaxOAVolFlowFlag, spaceNum)
    zsFinalSizing.MinOA = OAVolumeFlowRate
    zsCalcFinalSizing.MinOA = OAVolumeFlowRate
    if zsFinalSizing.ZoneADEffCooling > 0.0 or zsFinalSizing.ZoneADEffHeating > 0.0:
        zsFinalSizing.MinOA /= min(zsFinalSizing.ZoneADEffCooling, zsFinalSizing.ZoneADEffHeating)
        zsCalcFinalSizing.MinOA = zsFinalSizing.MinOA
    zsFinalSizing.DesCoolMinAirFlow2 = zsFinalSizing.DesCoolMinAirFlowPerArea * floorArea * zoneMult
    zsCalcFinalSizing.DesCoolMinAirFlow2 = zsCalcFinalSizing.DesCoolMinAirFlowPerArea * floorArea * zoneMult
    zsFinalSizing.DesHeatMaxAirFlow2 = zsFinalSizing.DesHeatMaxAirFlowPerArea * floorArea * zoneMult
    zsCalcFinalSizing.DesHeatMaxAirFlow2 = zsCalcFinalSizing.DesHeatMaxAirFlowPerArea * floorArea * zoneMult
    var zoneMultiplier = zoneMult
    zsFinalSizing.DesCoolMinAirFlow *= zoneMultiplier
    zsCalcFinalSizing.DesCoolMinAirFlow *= zoneMultiplier
    zsFinalSizing.DesHeatMaxAirFlow *= zoneMultiplier
    zsCalcFinalSizing.DesHeatMaxAirFlow *= zoneMultiplier
    zsFinalSizing.InpDesCoolAirFlow *= zoneMultiplier
    zsCalcFinalSizing.InpDesCoolAirFlow *= zoneMultiplier
    zsFinalSizing.InpDesHeatAirFlow *= zoneMultiplier
    zsCalcFinalSizing.InpDesHeatAirFlow *= zoneMultiplier
    for DesDayNum in range(state.dataEnvrn.TotDesDays + state.dataEnvrn.TotRunDesPersDays):
        var zoneSizing = state.dataSize.ZoneSizing[DesDayNum][zoneNum]
        zoneSizing.MinOA = zsFinalSizing.MinOA
        state.dataSize.CalcZoneSizing[DesDayNum][zoneNum].MinOA = zsCalcFinalSizing.MinOA
        zoneSizing.DesCoolMinAirFlow2 = zsFinalSizing.DesCoolMinAirFlow2
        state.dataSize.CalcZoneSizing[DesDayNum][zoneNum].DesCoolMinAirFlow2 = zsCalcFinalSizing.DesCoolMinAirFlow2
        zoneSizing.DesCoolMinAirFlow = zsFinalSizing.DesCoolMinAirFlow
        state.dataSize.CalcZoneSizing[DesDayNum][zoneNum].DesCoolMinAirFlow = zsCalcFinalSizing.DesCoolMinAirFlow
        zoneSizing.DesHeatMaxAirFlow2 = zsFinalSizing.DesHeatMaxAirFlow2
        state.dataSize.CalcZoneSizing[DesDayNum][zoneNum].DesHeatMaxAirFlow2 = zsCalcFinalSizing.DesHeatMaxAirFlow2
        zoneSizing.DesHeatMaxAirFlow = zsFinalSizing.DesHeatMaxAirFlow
        state.dataSize.CalcZoneSizing[DesDayNum][zoneNum].DesHeatMaxAirFlow = zsCalcFinalSizing.DesHeatMaxAirFlow

def fillZoneSizingFromInput(
    state: EnergyPlusData,
    zoneSizingInput: DataSizing.ZoneSizingInputData,
    zsSizing: List[List[DataSizing.ZoneSizingData]],
    zsCalcSizing: List[List[DataSizing.ZoneSizingData]],
    zsFinalSizing: DataSizing.ZoneSizingData,
    zsCalcFinalSizing: DataSizing.ZoneSizingData,
    zoneOrSpaceName: String,
    zoneOrSpaceNum: Int
):
    for DesDayNum in range(state.dataEnvrn.TotDesDays + state.dataEnvrn.TotRunDesPersDays):
        var zoneSizing = zsSizing[DesDayNum][zoneOrSpaceNum]
        var calcZoneSizing = zsCalcSizing[DesDayNum][zoneOrSpaceNum]
        zoneSizing.ZoneName = zoneOrSpaceName
        zoneSizing.ZoneNum = zoneOrSpaceNum
        calcZoneSizing.ZoneName = zoneOrSpaceName
        calcZoneSizing.ZoneNum = zoneOrSpaceNum
        zoneSizing.ZnCoolDgnSAMethod = zoneSizingInput.ZnCoolDgnSAMethod
        zoneSizing.ZnHeatDgnSAMethod = zoneSizingInput.ZnHeatDgnSAMethod
        zoneSizing.CoolDesTemp = zoneSizingInput.CoolDesTemp
        zoneSizing.HeatDesTemp = zoneSizingInput.HeatDesTemp
        zoneSizing.CoolDesTempDiff = zoneSizingInput.CoolDesTempDiff
        zoneSizing.HeatDesTempDiff = zoneSizingInput.HeatDesTempDiff
        zoneSizing.CoolDesHumRat = zoneSizingInput.CoolDesHumRat
        zoneSizing.HeatDesHumRat = zoneSizingInput.HeatDesHumRat
        zoneSizing.CoolAirDesMethod = zoneSizingInput.CoolAirDesMethod
        zoneSizing.HeatAirDesMethod = zoneSizingInput.HeatAirDesMethod
