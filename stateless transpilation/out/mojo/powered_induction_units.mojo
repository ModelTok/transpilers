# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (and others as noted). All rights reserved.

from math import max, min, abs, fabs


# ===================== Enums =====================

struct FanCntrlType:
    alias Invalid = -1
    alias ConstantSpeedFan = 0
    alias VariableSpeedFan = 1
    alias Num = 2


struct HeatCntrlBehaviorType:
    alias Invalid = -1
    alias StagedHeaterBehavior = 0
    alias ModulatedHeaterBehavior = 1
    alias Num = 2


struct HeatOpModeType:
    alias Invalid = -1
    alias HeaterOff = 0
    alias ConstantVolumeHeat = 1
    alias StagedHeatFirstStage = 2
    alias StagedHeatSecondStage = 3
    alias ModulatedHeatFirstStage = 4
    alias ModulatedHeatSecondStage = 5
    alias ModulatedHeatThirdStage = 6
    alias Num = 7


struct CoolOpModeType:
    alias Invalid = -1
    alias CoolerOff = 0
    alias ConstantVolumeCool = 1
    alias CoolFirstStage = 2
    alias CoolSecondStage = 3
    alias Num = 4


@value
struct PowIndUnitData:
    var Name: String
    var UnitType: String
    var UnitType_Num: Int32
    var availSched: AnyType
    var MaxTotAirVolFlow: Float64
    var MaxTotAirMassFlow: Float64
    var MaxPriAirVolFlow: Float64
    var MaxPriAirMassFlow: Float64
    var MinPriAirFlowFrac: Float64
    var MinPriAirMassFlow: Float64
    var PriDamperPosition: Float64
    var MaxSecAirVolFlow: Float64
    var MaxSecAirMassFlow: Float64
    var FanOnFlowFrac: Float64
    var FanOnAirMassFlow: Float64
    var PriAirInNode: Int32
    var SecAirInNode: Int32
    var OutAirNode: Int32
    var HCoilInAirNode: Int32
    var ControlCompTypeNum: Int32
    var CompErrIndex: Int32
    var MixerName: String
    var Mixer_Num: Int32
    var FanName: String
    var fanType: Int32
    var Fan_Index: Int32
    var fanAvailSched: AnyType
    var heatCoilType: Int32
    var HCoil_PlantType: Int32
    var HCoil: String
    var HCoil_Index: Int32
    var HCoil_fluid: AnyType
    var MaxVolHotWaterFlow: Float64
    var MaxVolHotSteamFlow: Float64
    var MaxHotWaterFlow: Float64
    var MaxHotSteamFlow: Float64
    var MinVolHotWaterFlow: Float64
    var MinHotSteamFlow: Float64
    var MinVolHotSteamFlow: Float64
    var MinHotWaterFlow: Float64
    var HotControlNode: Int32
    var HotCoilOutNodeNum: Int32
    var HotControlOffset: Float64
    var HWplantLoc: AnyType
    var ADUNum: Int32
    var InducesPlenumAir: Bool
    var HeatingRate: Float64
    var HeatingEnergy: Float64
    var SensCoolRate: Float64
    var SensCoolEnergy: Float64
    var CtrlZoneNum: Int32
    var ctrlZoneInNodeIndex: Int32
    var AirLoopNum: Int32
    var OutdoorAirFlowRate: Float64
    var PriAirMassFlow: Float64
    var SecAirMassFlow: Float64
    var fanControlType: Int32
    var MinFanTurnDownRatio: Float64
    var MinTotAirVolFlow: Float64
    var MinTotAirMassFlow: Float64
    var MinSecAirVolFlow: Float64
    var MinSecAirMassFlow: Float64
    var heatingControlType: Int32
    var designHeatingDAT: Float64
    var highLimitDAT: Float64
    var TotMassFlowRate: Float64
    var SecMassFlowRate: Float64
    var PriMassFlowRate: Float64
    var DischargeAirTemp: Float64
    var heatingOperatingMode: Int32
    var coolingOperatingMode: Int32
    var leakFrac: Float64
    var leakFlow: Float64
    var leakFracCurve: Int32
    var damperLeakageZoneNum: Int32
    var CurOperationControlStage: Int32
    var plenumIndex: Int32

    fn __init__(inout self):
        self.Name = String()
        self.UnitType = String()
        self.UnitType_Num = -1
        self.availSched = AnyType()
        self.MaxTotAirVolFlow = 0.0
        self.MaxTotAirMassFlow = 0.0
        self.MaxPriAirVolFlow = 0.0
        self.MaxPriAirMassFlow = 0.0
        self.MinPriAirFlowFrac = 0.0
        self.MinPriAirMassFlow = 0.0
        self.PriDamperPosition = 0.0
        self.MaxSecAirVolFlow = 0.0
        self.MaxSecAirMassFlow = 0.0
        self.FanOnFlowFrac = 0.0
        self.FanOnAirMassFlow = 0.0
        self.PriAirInNode = 0
        self.SecAirInNode = 0
        self.OutAirNode = 0
        self.HCoilInAirNode = 0
        self.ControlCompTypeNum = 0
        self.CompErrIndex = 0
        self.MixerName = String()
        self.Mixer_Num = 0
        self.FanName = String()
        self.fanType = -1
        self.Fan_Index = 0
        self.fanAvailSched = AnyType()
        self.heatCoilType = -1
        self.HCoil_PlantType = -1
        self.HCoil = String()
        self.HCoil_Index = 0
        self.HCoil_fluid = AnyType()
        self.MaxVolHotWaterFlow = 0.0
        self.MaxVolHotSteamFlow = 0.0
        self.MaxHotWaterFlow = 0.0
        self.MaxHotSteamFlow = 0.0
        self.MinVolHotWaterFlow = 0.0
        self.MinHotSteamFlow = 0.0
        self.MinVolHotSteamFlow = 0.0
        self.MinHotWaterFlow = 0.0
        self.HotControlNode = 0
        self.HotCoilOutNodeNum = 0
        self.HotControlOffset = 0.0
        self.HWplantLoc = AnyType()
        self.ADUNum = 0
        self.InducesPlenumAir = False
        self.HeatingRate = 0.0
        self.HeatingEnergy = 0.0
        self.SensCoolRate = 0.0
        self.SensCoolEnergy = 0.0
        self.CtrlZoneNum = 0
        self.ctrlZoneInNodeIndex = 0
        self.AirLoopNum = 0
        self.OutdoorAirFlowRate = 0.0
        self.PriAirMassFlow = 0.0
        self.SecAirMassFlow = 0.0
        self.fanControlType = FanCntrlType.ConstantSpeedFan
        self.MinFanTurnDownRatio = 0.0
        self.MinTotAirVolFlow = 0.0
        self.MinTotAirMassFlow = 0.0
        self.MinSecAirVolFlow = 0.0
        self.MinSecAirMassFlow = 0.0
        self.heatingControlType = HeatCntrlBehaviorType.Invalid
        self.designHeatingDAT = 0.0
        self.highLimitDAT = 0.0
        self.TotMassFlowRate = 0.0
        self.SecMassFlowRate = 0.0
        self.PriMassFlowRate = 0.0
        self.DischargeAirTemp = 0.0
        self.heatingOperatingMode = HeatOpModeType.HeaterOff
        self.coolingOperatingMode = CoolOpModeType.CoolerOff
        self.leakFrac = 0.0
        self.leakFlow = 0.0
        self.leakFracCurve = 0
        self.damperLeakageZoneNum = 0
        self.CurOperationControlStage = -1
        self.plenumIndex = 0

    fn CalcOutdoorAirVolumeFlowRate(inout self, state: AnyType) -> None:
        if self.AirLoopNum > 0:
            self.OutdoorAirFlowRate = (state.dataLoopNodes.Node[self.PriAirInNode - 1].MassFlowRate / state.dataEnvrn.StdRhoAir) * \
                                      state.dataAirLoop.AirLoopFlow[self.AirLoopNum - 1].OAFrac
        else:
            self.OutdoorAirFlowRate = 0.0

    fn reportTerminalUnit(inout self, state: AnyType) -> None:
        orp = state.dataOutRptPredefined
        adu = state.dataDefineEquipment.AirDistUnit[self.ADUNum - 1]
        if state.dataSize.TermUnitFinalZoneSizing:
            sizing = state.dataSize.TermUnitFinalZoneSizing[adu.TermUnitSizingNum - 1]
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermMinFlow, adu.Name, sizing.DesCoolVolFlowMin)
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermMinOutdoorFlow, adu.Name, sizing.MinOA)
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermSupCoolingSP, adu.Name, sizing.CoolDesTemp)
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermSupHeatingSP, adu.Name, sizing.HeatDesTemp)
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermHeatingCap, adu.Name, sizing.DesHeatLoad)
            state.outputProcessor.PreDefTableEntry(orp.pdchAirTermCoolingCap, adu.Name, sizing.DesCoolLoad)
        state.outputProcessor.PreDefTableEntry(orp.pdchAirTermTypeInp, adu.Name, self.UnitType)
        state.outputProcessor.PreDefTableEntry(orp.pdchAirTermPrimFlow, adu.Name, self.MaxPriAirVolFlow)
        state.outputProcessor.PreDefTableEntry(orp.pdchAirTermSecdFlow, adu.Name, self.MaxSecAirVolFlow)


var FAN_CNTRL_TYPE_NAMES = InlineArray[StringLiteral, 2]("ConstantSpeed", "VariableSpeed")
var FAN_CNTRL_TYPE_NAMES_UC = InlineArray[StringLiteral, 2]("CONSTANTSPEED", "VARIABLESPEED")
var HEAT_CNTRL_TYPE_NAMES = InlineArray[StringLiteral, 2]("Staged", "Modulated")
var HEAT_CNTRL_TYPE_NAMES_UC = InlineArray[StringLiteral, 2]("STAGED", "MODULATED")


fn SimPIU(state: AnyType, CompName: String, FirstHVACIteration: Bool, ZoneNum: Int32, ZoneNodeNum: Int32, CompIndex: AnyType) -> None:
    var PIUNum: Int32 = 0

    if state.dataPowerInductionUnits.GetPIUInputFlag:
        GetPIUs(state)
        state.dataPowerInductionUnits.GetPIUInputFlag = False

    if CompIndex[] == 0:
        PIUNum = state.utilities.FindItemInList(CompName, state.dataPowerInductionUnits.PIU)
        if PIUNum == 0:
            state.showFatalError("SimPIU: PIU Unit not found=" + CompName)
        CompIndex[] = PIUNum
    else:
        PIUNum = CompIndex[]
        if PIUNum > state.dataPowerInductionUnits.NumPIUs or PIUNum < 1:
            state.showFatalError("SimPIU: Invalid CompIndex passed")
        if state.dataPowerInductionUnits.CheckEquipName[PIUNum - 1]:
            if CompName != state.dataPowerInductionUnits.PIU[PIUNum - 1].Name:
                state.showFatalError("SimPIU: Invalid CompIndex passed")
            state.dataPowerInductionUnits.CheckEquipName[PIUNum - 1] = False

    state.dataSize.CurTermUnitSizingNum = state.dataDefineEquipment.AirDistUnit[state.dataPowerInductionUnits.PIU[PIUNum - 1].ADUNum - 1].TermUnitSizingNum
    InitPIU(state, PIUNum, FirstHVACIteration)

    state.dataSize.TermUnitPIU = True

    piu_type = state.dataPowerInductionUnits.PIU[PIUNum - 1].UnitType_Num
    if piu_type == 16:
        CalcSeriesPIU(state, PIUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    elif piu_type == 17:
        CalcParallelPIU(state, PIUNum, ZoneNum, ZoneNodeNum, FirstHVACIteration)
    else:
        state.showSevereError("Illegal PI Unit Type used")
        state.showFatalError("Preceding condition causes termination.")

    state.dataSize.TermUnitPIU = False
    ReportPIU(state, PIUNum)


fn GetPIUs(state: AnyType) -> None:
    state.dataPowerInductionUnits.NumSeriesPIUs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "AirTerminal:SingleDuct:SeriesPIU:Reheat")
    state.dataPowerInductionUnits.NumParallelPIUs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, "AirTerminal:SingleDuct:ParallelPIU:Reheat")
    state.dataPowerInductionUnits.NumPIUs = state.dataPowerInductionUnits.NumSeriesPIUs + state.dataPowerInductionUnits.NumParallelPIUs

    if state.dataPowerInductionUnits.NumPIUs > 0:
        if state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag:
            state.zoneAirLoopEquipmentManager.GetZoneAirLoopEquipment(state)
            state.dataZoneAirLoopEquipmentManager.GetAirDistUnitsFlag = False

    state.dataPowerInductionUnits.PIU.resize(state.dataPowerInductionUnits.NumPIUs)
    state.dataPowerInductionUnits.CheckEquipName.resize(state.dataPowerInductionUnits.NumPIUs, True)


fn InitPIU(state: AnyType, PIUNum: Int32, FirstHVACIteration: Bool) -> None:
    var thisPIU = state.dataPowerInductionUnits.PIU[PIUNum - 1]

    if state.dataPowerInductionUnits.MyOneTimeFlag:
        state.dataPowerInductionUnits.MyEnvrnFlag.resize(state.dataPowerInductionUnits.NumPIUs, True)
        state.dataPowerInductionUnits.MySizeFlag.resize(state.dataPowerInductionUnits.NumPIUs, True)
        state.dataPowerInductionUnits.MyPlantScanFlag.resize(state.dataPowerInductionUnits.NumPIUs, True)
        state.dataPowerInductionUnits.MyOneTimeFlag = False

    if state.dataPowerInductionUnits.MyPlantScanFlag[PIUNum - 1] and state.dataPlnt.PlantLoop:
        if thisPIU.HCoil_PlantType in [11, 17]:
            state.plantUtilities.ScanPlantLoopsForObject(state, thisPIU.HCoil, thisPIU.HCoil_PlantType, thisPIU.HWplantLoc)
            thisPIU.HotCoilOutNodeNum = state.dataPlant.CompData.getPlantComponent(state, thisPIU.HWplantLoc).NodeNumOut
        state.dataPowerInductionUnits.MyPlantScanFlag[PIUNum - 1] = False
    elif state.dataPowerInductionUnits.MyPlantScanFlag[PIUNum - 1] and not state.dataGlobal.AnyPlantInModel:
        state.dataPowerInductionUnits.MyPlantScanFlag[PIUNum - 1] = False

    if state.dataGlobal.BeginEnvrnFlag and state.dataPowerInductionUnits.MyEnvrnFlag[PIUNum - 1]:
        var RhoAir: Float64 = state.dataEnvrn.StdRhoAir
        var PriNode: Int32 = thisPIU.PriAirInNode
        var SecNode: Int32 = thisPIU.SecAirInNode
        var OutletNode: Int32 = thisPIU.OutAirNode

        if thisPIU.UnitType == "AirTerminal:SingleDuct:SeriesPIU:Reheat":
            thisPIU.MaxTotAirMassFlow = RhoAir * thisPIU.MaxTotAirVolFlow
            thisPIU.MaxPriAirMassFlow = RhoAir * thisPIU.MaxPriAirVolFlow
            thisPIU.MinPriAirMassFlow = RhoAir * thisPIU.MinPriAirFlowFrac * thisPIU.MaxPriAirVolFlow
            state.dataLoopNodes.Node[PriNode - 1].MassFlowRateMax = thisPIU.MaxPriAirMassFlow
            state.dataLoopNodes.Node[PriNode - 1].MassFlowRateMin = thisPIU.MinPriAirMassFlow
            state.dataLoopNodes.Node[OutletNode - 1].MassFlowRateMax = thisPIU.MaxTotAirMassFlow
        else:
            thisPIU.MaxPriAirMassFlow = RhoAir * thisPIU.MaxPriAirVolFlow
            thisPIU.MinPriAirMassFlow = RhoAir * thisPIU.MinPriAirFlowFrac * thisPIU.MaxPriAirVolFlow
            thisPIU.MaxSecAirMassFlow = RhoAir * thisPIU.MaxSecAirVolFlow
            thisPIU.FanOnAirMassFlow = RhoAir * thisPIU.FanOnFlowFrac * thisPIU.MaxPriAirVolFlow
            state.dataLoopNodes.Node[PriNode - 1].MassFlowRateMax = thisPIU.MaxPriAirMassFlow
            state.dataLoopNodes.Node[PriNode - 1].MassFlowRateMin = thisPIU.MinPriAirMassFlow
            state.dataLoopNodes.Node[OutletNode - 1].MassFlowRateMax = thisPIU.MaxPriAirMassFlow

        if thisPIU.fanControlType == FanCntrlType.VariableSpeedFan:
            if thisPIU.UnitType == "AirTerminal:SingleDuct:SeriesPIU:Reheat":
                thisPIU.MinTotAirMassFlow = thisPIU.MaxTotAirMassFlow * thisPIU.MinFanTurnDownRatio
                thisPIU.MaxSecAirVolFlow = thisPIU.MaxTotAirMassFlow - thisPIU.MinPriAirMassFlow
                thisPIU.MaxSecAirMassFlow = RhoAir * thisPIU.MaxSecAirVolFlow
                thisPIU.MinSecAirMassFlow = max(0.0, thisPIU.MinTotAirMassFlow - thisPIU.MinPriAirMassFlow)

        state.dataPowerInductionUnits.MyEnvrnFlag[PIUNum - 1] = False

    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataPowerInductionUnits.MyEnvrnFlag[PIUNum - 1] = True


fn SizePIU(state: AnyType, PIUNum: Int32) -> None:
    var thisPIU = state.dataPowerInductionUnits.PIU[PIUNum - 1]
    var CurTermUnitSizingNum: Int32 = state.dataSize.CurTermUnitSizingNum

    if CurTermUnitSizingNum > 0:
        if thisPIU.UnitType_Num == 16:
            state.dataSize.TermUnitSizing[CurTermUnitSizingNum - 1].AirVolFlow = thisPIU.MaxTotAirVolFlow
        elif thisPIU.UnitType_Num == 17:
            state.dataSize.TermUnitSizing[CurTermUnitSizingNum - 1].AirVolFlow = thisPIU.MaxSecAirVolFlow + thisPIU.MinPriAirFlowFrac * thisPIU.MaxPriAirVolFlow


fn CalcSeriesPIU(state: AnyType, PIUNum: Int32, ZoneNum: Int32, ZoneNode: Int32, FirstHVACIteration: Bool) -> None:
    var thisPIU = state.dataPowerInductionUnits.PIU[PIUNum - 1]
    var SmallMassFlow: Float64 = 1e-8
    var SmallLoad: Float64 = 1e-5
    var SmallTempDiff: Float64 = 1e-8

    var UnitOn: Bool = True
    var PriOn: Bool = True
    var QCoilReq: Float64 = 0.0

    var PriAirMassFlowMax: Float64 = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRateMaxAvail
    var PriAirMassFlowMin: Float64 = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRateMinAvail
    var QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputRequired
    var QToHeatSetPt: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputReqToHeatSP
    var CpAirZn: Float64 = state.psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[ZoneNode - 1].HumRat)

    thisPIU.PriAirMassFlow = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate
    thisPIU.SecAirMassFlow = state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate

    if thisPIU.fanControlType == FanCntrlType.VariableSpeedFan:
        thisPIU.heatingOperatingMode = HeatOpModeType.HeaterOff
    else:
        thisPIU.heatingOperatingMode = HeatOpModeType.ConstantVolumeHeat
    thisPIU.coolingOperatingMode = CoolOpModeType.CoolerOff

    if thisPIU.availSched.getCurrentVal() <= 0.0:
        UnitOn = False

    if UnitOn:
        if not PriOn:
            thisPIU.PriAirMassFlow = 0.0
            if QZnReq <= SmallLoad:
                thisPIU.SecAirMassFlow = 0.0
        elif QZnReq > SmallLoad:
            thisPIU.PriAirMassFlow = PriAirMassFlowMin
            if thisPIU.fanControlType == FanCntrlType.ConstantSpeedFan:
                thisPIU.heatingOperatingMode = HeatOpModeType.ConstantVolumeHeat
                thisPIU.SecAirMassFlow = max(0.0, thisPIU.MaxTotAirMassFlow - thisPIU.PriAirMassFlow)
    else:
        thisPIU.PriAirMassFlow = 0.0
        thisPIU.SecAirMassFlow = 0.0

    state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate = thisPIU.PriAirMassFlow
    state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate = thisPIU.SecAirMassFlow

    if PriAirMassFlowMax == 0:
        thisPIU.PriDamperPosition = 0
    else:
        thisPIU.PriDamperPosition = thisPIU.PriAirMassFlow / PriAirMassFlowMax

    state.mixerComponent.SimAirMixer(state, thisPIU.MixerName, thisPIU.Mixer_Num)

    var QActualHeating: Float64 = QToHeatSetPt - state.dataLoopNodes.Node[thisPIU.HCoilInAirNode - 1].MassFlowRate * CpAirZn * \
        (state.dataLoopNodes.Node[thisPIU.HCoilInAirNode - 1].Temp - state.dataLoopNodes.Node[ZoneNode - 1].Temp)

    if QActualHeating < SmallLoad:
        thisPIU.heatingOperatingMode = HeatOpModeType.HeaterOff
        QCoilReq = 0.0
    else:
        QCoilReq = QActualHeating

    if thisPIU.heatCoilType == 1:
        if thisPIU.heatingOperatingMode == HeatOpModeType.HeaterOff:
            state.waterCoils.SimulateWaterCoilComponents(state, thisPIU.HCoil, FirstHVACIteration, thisPIU.HCoil_Index)

    var PowerMet: Float64 = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].MassFlowRate * \
        (state.psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].Temp, state.dataLoopNodes.Node[ZoneNode - 1].HumRat) -
         state.psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneNode - 1].Temp, state.dataLoopNodes.Node[ZoneNode - 1].HumRat))

    thisPIU.HeatingRate = max(0.0, PowerMet)
    thisPIU.SensCoolRate = fabs(min(0.0, PowerMet))
    thisPIU.TotMassFlowRate = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].MassFlowRate
    thisPIU.SecMassFlowRate = state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate
    thisPIU.PriMassFlowRate = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate
    thisPIU.DischargeAirTemp = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].Temp

    ReportCurOperatingControlStage(state, PIUNum, UnitOn, thisPIU.heatingOperatingMode, thisPIU.coolingOperatingMode)


fn CalcParallelPIU(state: AnyType, PIUNum: Int32, ZoneNum: Int32, ZoneNode: Int32, FirstHVACIteration: Bool) -> None:
    var thisPIU = state.dataPowerInductionUnits.PIU[PIUNum - 1]

    thisPIU.leakFlow = 0.0
    thisPIU.leakFrac = 0.0

    var UnitOn: Bool = True
    var PriAirMassFlowMax: Float64 = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRateMaxAvail
    var PriAirMassFlowMin: Float64 = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRateMinAvail

    thisPIU.PriAirMassFlow = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate
    thisPIU.SecAirMassFlow = state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate

    var QZnReq: Float64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].RemainingOutputRequired
    var CpAirZn: Float64 = state.psychrometrics.PsyCpAirFnW(state.dataLoopNodes.Node[ZoneNode - 1].HumRat)

    thisPIU.heatingOperatingMode = HeatOpModeType.HeaterOff
    thisPIU.coolingOperatingMode = CoolOpModeType.CoolerOff

    if thisPIU.availSched.getCurrentVal() <= 0.0:
        UnitOn = False

    if UnitOn:
        if QZnReq > 1e-5:
            thisPIU.PriAirMassFlow = PriAirMassFlowMin
            if thisPIU.fanControlType == FanCntrlType.ConstantSpeedFan:
                thisPIU.heatingOperatingMode = HeatOpModeType.ConstantVolumeHeat
                thisPIU.SecAirMassFlow = thisPIU.MaxSecAirMassFlow
    else:
        thisPIU.PriAirMassFlow = 0.0
        thisPIU.SecAirMassFlow = 0.0

    state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate = thisPIU.PriAirMassFlow
    state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate = thisPIU.SecAirMassFlow

    if PriAirMassFlowMax == 0:
        thisPIU.PriDamperPosition = 0
    else:
        thisPIU.PriDamperPosition = thisPIU.PriAirMassFlow / PriAirMassFlowMax

    state.mixerComponent.SimAirMixer(state, thisPIU.MixerName, thisPIU.Mixer_Num)

    var PowerMet: Float64 = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].MassFlowRate * \
        (state.psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].Temp, state.dataLoopNodes.Node[ZoneNode - 1].HumRat) -
         state.psychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[ZoneNode - 1].Temp, state.dataLoopNodes.Node[ZoneNode - 1].HumRat))

    thisPIU.HeatingRate = max(0.0, PowerMet)
    thisPIU.SensCoolRate = fabs(min(0.0, PowerMet))
    thisPIU.TotMassFlowRate = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].MassFlowRate
    thisPIU.SecMassFlowRate = state.dataLoopNodes.Node[thisPIU.SecAirInNode - 1].MassFlowRate
    thisPIU.PriMassFlowRate = state.dataLoopNodes.Node[thisPIU.PriAirInNode - 1].MassFlowRate
    thisPIU.DischargeAirTemp = state.dataLoopNodes.Node[thisPIU.OutAirNode - 1].Temp

    ReportCurOperatingControlStage(state, PIUNum, UnitOn, thisPIU.heatingOperatingMode, thisPIU.coolingOperatingMode)


fn ReportCurOperatingControlStage(state: AnyType, piuNum: Int32, unitOn: Bool, heaterMode: Int32, coolingMode: Int32) -> None:
    var undetermined: Int32 = -1
    var off: Int32 = 0
    var constantVolumeCooling: Int32 = 1
    var constantVolumeHeating: Int32 = 2
    var deadband: Int32 = 3

    var thisPIU = state.dataPowerInductionUnits.PIU[piuNum - 1]
    thisPIU.CurOperationControlStage = undetermined

    if not unitOn:
        thisPIU.CurOperationControlStage = off
    else:
        if thisPIU.fanControlType == FanCntrlType.ConstantSpeedFan:
            if heaterMode != HeatOpModeType.HeaterOff and coolingMode == CoolOpModeType.CoolerOff:
                thisPIU.CurOperationControlStage = constantVolumeHeating
            elif coolingMode != CoolOpModeType.CoolerOff and heaterMode == HeatOpModeType.HeaterOff:
                thisPIU.CurOperationControlStage = constantVolumeCooling
            else:
                thisPIU.CurOperationControlStage = deadband


fn ReportPIU(state: AnyType, PIUNum: Int32) -> None:
    var TimeStepSysSec: Float64 = state.dataHVACGlobal.TimeStepSysSec
    var thisPIU = state.dataPowerInductionUnits.PIU[PIUNum - 1]
    thisPIU.HeatingEnergy = thisPIU.HeatingRate * TimeStepSysSec
    thisPIU.SensCoolEnergy = thisPIU.SensCoolRate * TimeStepSysSec
    thisPIU.CalcOutdoorAirVolumeFlowRate(state)


fn PIUnitHasMixer(state: AnyType, CompName: String) -> Bool:
    if state.dataPowerInductionUnits.GetPIUInputFlag:
        GetPIUs(state)
        state.dataPowerInductionUnits.GetPIUInputFlag = False

    if state.dataPowerInductionUnits.NumPIUs > 0:
        for i in range(state.dataPowerInductionUnits.NumPIUs):
            if state.dataPowerInductionUnits.PIU[i].MixerName == CompName:
                return True
    return False


fn PIUInducesPlenumAir(state: AnyType, NodeNum: Int32, plenumNum: Int32) -> None:
    if state.dataPowerInductionUnits.GetPIUInputFlag:
        GetPIUs(state)
        state.dataPowerInductionUnits.GetPIUInputFlag = False

    for i in range(state.dataPowerInductionUnits.NumPIUs):
        if NodeNum == state.dataPowerInductionUnits.PIU[i].SecAirInNode:
            state.dataPowerInductionUnits.PIU[i].InducesPlenumAir = True
            state.dataPowerInductionUnits.PIU[i].plenumIndex = plenumNum
            break


fn getParallelPIUNumFromSecNodeNum(state: AnyType, zoneNum: Int32) -> Int32:
    if state.dataPowerInductionUnits.GetPIUInputFlag:
        GetPIUs(state)
        state.dataPowerInductionUnits.GetPIUInputFlag = False

    for i in range(state.dataPowerInductionUnits.NumPIUs):
        if zoneNum == state.dataPowerInductionUnits.PIU[i].SecAirInNode:
            return Int32(i + 1)
    return 0
