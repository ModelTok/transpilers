# EnergyPlus WindowAC Module - Python Port
# Port of WindowAC.hh and WindowAC.cc

from dataclasses import dataclass, field
from typing import Optional, List, Any
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with sub-objects for data access
# - Schedule: schedule objects with getCurrentVal() method
# - HVAC enums: FanType, FanOp, FanPlace, CoilType, SetptType, CompressorOp
# - Fan, DXCoil objects and simulation functions
# - Node objects and simulation utilities
# - Sizing and output processor utilities
# - Psychrometric functions


@dataclass
class WindACData:
    Name: str = ""
    UnitType: int = 0
    availSched: Optional[Any] = None
    fanOpModeSched: Optional[Any] = None
    fanAvailSched: Optional[Any] = None
    MaxAirVolFlow: float = 0.0
    MaxAirMassFlow: float = 0.0
    OutAirVolFlow: float = 0.0
    OutAirMassFlow: float = 0.0
    AirInNode: int = 0
    AirOutNode: int = 0
    OutsideAirNode: int = 0
    AirReliefNode: int = 0
    ReturnAirNode: int = 0
    MixedAirNode: int = 0
    OAMixName: str = ""
    OAMixType: str = ""
    OAMixIndex: int = 0
    FanName: str = ""
    fanType: int = 0
    FanIndex: int = 0
    DXCoilName: str = ""
    DXCoilType: str = ""
    coilType: int = 0
    DXCoilIndex: int = 0
    DXCoilNumOfSpeeds: int = 0
    CoilOutletNodeNum: int = 0
    fanOp: int = 0
    fanPlace: int = 0
    MaxIterIndex1: int = 0
    MaxIterIndex2: int = 0
    ConvergenceTol: float = 0.0
    PartLoadFrac: float = 0.0
    EMSOverridePartLoadFrac: bool = False
    EMSValueForPartLoadFrac: float = 0.0
    TotCoolEnergyRate: float = 0.0
    TotCoolEnergy: float = 0.0
    SensCoolEnergyRate: float = 0.0
    SensCoolEnergy: float = 0.0
    LatCoolEnergyRate: float = 0.0
    LatCoolEnergy: float = 0.0
    ElecPower: float = 0.0
    ElecConsumption: float = 0.0
    FanPartLoadRatio: float = 0.0
    CompPartLoadRatio: float = 0.0
    AvailManagerListName: str = ""
    availStatus: int = 0
    ZonePtr: int = 0
    HVACSizingIndex: int = 0
    FirstPass: bool = True


@dataclass
class WindACNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


@dataclass
class WindowACState:
    WindowAC_UnitType: int = 1
    cWindowAC_UnitType: str = "ZoneHVAC:WindowAirConditioner"
    cWindowAC_UnitTypes: List[str] = field(default_factory=lambda: ["ZoneHVAC:WindowAirConditioner"])
    MyOneTimeFlag: bool = True
    ZoneEquipmentListChecked: bool = False
    NumWindAC: int = 0
    NumWindACCyc: int = 0
    MySizeFlag: List[bool] = field(default_factory=list)
    GetWindowACInputFlag: bool = True
    CoolingLoad: bool = False
    CheckEquipName: List[bool] = field(default_factory=list)
    WindAC: List[WindACData] = field(default_factory=list)
    WindACNumericFields: List[WindACNumericFieldData] = field(default_factory=list)
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MyZoneEqFlag: List[bool] = field(default_factory=list)


def SimWindowAC(state, CompName, ZoneNum, FirstHVACIteration, PowerMet, LatOutputProvided, CompIndex):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    if CompIndex[0] == 0:
        WindACNum = find_item_in_list(CompName, [w.Name for w in wind_ac_state.WindAC])
        if WindACNum == 0:
            raise ValueError(f"SimWindowAC: Unit not found={CompName}")
        CompIndex[0] = WindACNum
    else:
        WindACNum = CompIndex[0]
        if WindACNum > wind_ac_state.NumWindAC or WindACNum < 1:
            raise ValueError(f"SimWindowAC: Invalid CompIndex passed={WindACNum}")
        if wind_ac_state.CheckEquipName[WindACNum - 1]:
            if CompName != wind_ac_state.WindAC[WindACNum - 1].Name:
                raise ValueError(f"SimWindowAC: Invalid CompIndex passed={WindACNum}")
            wind_ac_state.CheckEquipName[WindACNum - 1] = False
    
    RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
    
    if RemainingOutputToCoolingSP < 0.0 and state.dataHeatBalFanSys.TempControlType[ZoneNum] != 0:
        QZnReq = RemainingOutputToCoolingSP
    else:
        QZnReq = 0.0
    
    state.dataSize.ZoneEqDXCoil = True
    state.dataSize.ZoneCoolingOnlyFan = True
    
    InitWindowAC(state, WindACNum, QZnReq, ZoneNum, FirstHVACIteration)
    SimCyclingWindowAC(state, WindACNum, ZoneNum, FirstHVACIteration, PowerMet, QZnReq, LatOutputProvided)
    ReportWindowAC(state, WindACNum)
    
    state.dataSize.ZoneEqDXCoil = False
    state.dataSize.ZoneCoolingOnlyFan = False


def GetWindowAC(state):
    wind_ac_state = state.dataWindowAC
    CurrentModuleObject = "ZoneHVAC:WindowAirConditioner"
    
    wind_ac_state.NumWindACCyc = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    wind_ac_state.NumWindAC = wind_ac_state.NumWindACCyc
    
    wind_ac_state.WindAC = [WindACData() for _ in range(wind_ac_state.NumWindAC)]
    wind_ac_state.CheckEquipName = [True] * wind_ac_state.NumWindAC
    wind_ac_state.WindACNumericFields = [WindACNumericFieldData() for _ in range(wind_ac_state.NumWindAC)]
    
    TotalArgs = [0]
    NumAlphas = [0]
    NumNumbers = [0]
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
    
    for WindACIndex in range(wind_ac_state.NumWindACCyc):
        WindACNum = WindACIndex
        Alphas, Numbers, IOStatus, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields = (
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, CurrentModuleObject, WindACIndex + 1, NumAlphas[0], NumNumbers[0]
            )
        )
        
        wind_ac_state.WindACNumericFields[WindACNum].FieldNames = cNumericFields[:]
        windAC = wind_ac_state.WindAC[WindACNum]
        windAC.Name = Alphas[0]
        windAC.UnitType = wind_ac_state.WindowAC_UnitType
        
        if lAlphaBlanks[1]:
            windAC.availSched = state.dataSchedule.schedules_always_on()
        else:
            windAC.availSched = state.dataSchedule.GetSchedule(state, Alphas[1])
        
        windAC.MaxAirVolFlow = Numbers[0]
        windAC.OutAirVolFlow = Numbers[1]
        
        windAC.AirInNode = state.dataNodeInputMgr.GetOnlySingleNode(state, Alphas[2])
        windAC.AirOutNode = state.dataNodeInputMgr.GetOnlySingleNode(state, Alphas[3])
        
        windAC.OAMixType = Alphas[4]
        windAC.OAMixName = Alphas[5]
        OANodeNums = state.dataMixedAir.GetOAMixerNodeNumbers(state, windAC.OAMixName)
        
        if OANodeNums:
            windAC.OutsideAirNode = OANodeNums[0]
            windAC.AirReliefNode = OANodeNums[1]
            windAC.ReturnAirNode = OANodeNums[2]
            windAC.MixedAirNode = OANodeNums[3]
        
        windAC.FanName = Alphas[7]
        windAC.fanType = state.dataFans.get_fan_type_enum(Alphas[6])
        windAC.FanIndex = state.dataFans.GetFanIndex(state, windAC.FanName)
        
        if windAC.FanIndex > 0:
            fan = state.dataFans.fans[windAC.FanIndex - 1]
            windAC.fanAvailSched = fan.availSched
        
        windAC.DXCoilName = Alphas[9]
        
        if Alphas[8] in ["Coil:Cooling:DX:SingleSpeed", "CoilSystem:Cooling:DX:HeatExchangerAssisted", "Coil:Cooling:DX:VariableSpeed"]:
            windAC.DXCoilType = Alphas[8]
            if Alphas[8] == "Coil:Cooling:DX:SingleSpeed":
                windAC.coilType = 1
                windAC.CoilOutletNodeNum = state.dataDXCoils.GetCoilOutletNode(state, windAC.DXCoilType, windAC.DXCoilName)
            elif Alphas[8] == "CoilSystem:Cooling:DX:HeatExchangerAssisted":
                windAC.coilType = 2
                windAC.CoilOutletNodeNum = state.dataHVACHXAssistedCoolingCoil.GetCoilOutletNode(state, windAC.DXCoilType, windAC.DXCoilName)
            elif Alphas[8] == "Coil:Cooling:DX:VariableSpeed":
                windAC.coilType = 3
                windAC.CoilOutletNodeNum = state.dataVariableSpeedCoils.GetCoilOutletNodeVariableSpeed(state, windAC.DXCoilType, windAC.DXCoilName)
                windAC.DXCoilNumOfSpeeds = state.dataVariableSpeedCoils.GetVSCoilNumOfSpeeds(state, windAC.DXCoilName)
            windAC.DXCoilIndex = state.dataDXCoils.GetCoilIndex(state, windAC.DXCoilName)
        
        if not lAlphaBlanks[10]:
            windAC.fanOpModeSched = state.dataSchedule.GetSchedule(state, Alphas[10])
        else:
            windAC.fanOp = 1
        
        windAC.fanPlace = state.dataFans.get_fan_place_enum(Alphas[11])
        windAC.ConvergenceTol = Numbers[2]
        
        if not lAlphaBlanks[12]:
            windAC.AvailManagerListName = Alphas[12]
        
        if not lAlphaBlanks[13]:
            windAC.HVACSizingIndex = find_item_in_list(Alphas[13], state.dataSize.ZoneHVACSizing_names)
        
        windAC.ZonePtr = state.dataZoneEquip.find_zone_for_equipment(windAC.AirOutNode)


def InitWindowAC(state, WindACNum, QZnReq, ZoneNum, FirstHVACIteration):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.MyOneTimeFlag:
        wind_ac_state.MyEnvrnFlag = [True] * wind_ac_state.NumWindAC
        wind_ac_state.MySizeFlag = [True] * wind_ac_state.NumWindAC
        wind_ac_state.MyZoneEqFlag = [True] * wind_ac_state.NumWindAC
        wind_ac_state.MyOneTimeFlag = False
    
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    if wind_ac_state.MyZoneEqFlag[WindACNum - 1]:
        wind_ac_state.MyZoneEqFlag[WindACNum - 1] = False
    
    if not wind_ac_state.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        wind_ac_state.ZoneEquipmentListChecked = True
        for Loop in range(wind_ac_state.NumWindAC):
            if not state.dataZoneEquip.CheckZoneEquipmentList(state, wind_ac_state.cWindowAC_UnitType, wind_ac_state.WindAC[Loop].Name):
                raise ValueError(f"InitWindowAC: Window AC Unit=[{wind_ac_state.cWindowAC_UnitType},{wind_ac_state.WindAC[Loop].Name}] not on ZoneHVAC:EquipmentList")
    
    if not state.dataGlobal.SysSizingCalc and wind_ac_state.MySizeFlag[WindACNum - 1]:
        SizeWindowAC(state, WindACNum)
        wind_ac_state.MySizeFlag[WindACNum - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag and wind_ac_state.MyEnvrnFlag[WindACNum - 1]:
        InNode = windAC.AirInNode
        OutNode = windAC.AirOutNode
        OutsideAirNode = windAC.OutsideAirNode
        RhoAir = state.dataEnvrn.StdRhoAir
        
        windAC.MaxAirMassFlow = RhoAir * windAC.MaxAirVolFlow
        windAC.OutAirMassFlow = RhoAir * windAC.OutAirVolFlow
        
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMax = windAC.OutAirMassFlow
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMin = 0.0
        state.dataLoopNodes.Node[OutNode].MassFlowRateMax = windAC.MaxAirMassFlow
        state.dataLoopNodes.Node[OutNode].MassFlowRateMin = 0.0
        state.dataLoopNodes.Node[InNode].MassFlowRateMax = windAC.MaxAirMassFlow
        state.dataLoopNodes.Node[InNode].MassFlowRateMin = 0.0
        
        wind_ac_state.MyEnvrnFlag[WindACNum - 1] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        wind_ac_state.MyEnvrnFlag[WindACNum - 1] = True
    
    if windAC.fanOpModeSched is not None:
        if windAC.fanOpModeSched.getCurrentVal() == 0.0:
            windAC.fanOp = 1
        else:
            windAC.fanOp = 2
    
    InletNode = windAC.AirInNode
    OutsideAirNode = windAC.OutsideAirNode
    AirRelNode = windAC.AirReliefNode
    
    if (windAC.availSched.getCurrentVal() <= 0.0 or 
        (windAC.fanAvailSched.getCurrentVal() <= 0.0 and not state.dataHVACGlobal.TurnFansOn) or
        state.dataHVACGlobal.TurnFansOff):
        windAC.PartLoadFrac = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMaxAvail = 0.0
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[AirRelNode].MassFlowRate = 0.0
        state.dataLoopNodes.Node[AirRelNode].MassFlowRateMaxAvail = 0.0
        state.dataLoopNodes.Node[AirRelNode].MassFlowRateMinAvail = 0.0
    else:
        windAC.PartLoadFrac = 1.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = windAC.MaxAirMassFlow
        state.dataLoopNodes.Node[InletNode].MassFlowRateMaxAvail = windAC.MaxAirMassFlow
        state.dataLoopNodes.Node[InletNode].MassFlowRateMinAvail = windAC.MaxAirMassFlow
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate = windAC.OutAirMassFlow
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMaxAvail = windAC.OutAirMassFlow
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMinAvail = 0.0
        state.dataLoopNodes.Node[AirRelNode].MassFlowRate = windAC.OutAirMassFlow
        state.dataLoopNodes.Node[AirRelNode].MassFlowRateMaxAvail = windAC.OutAirMassFlow
        state.dataLoopNodes.Node[AirRelNode].MassFlowRateMinAvail = 0.0
    
    SmallLoad = 0.01
    if QZnReq < (-1.0 * SmallLoad) and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum] and windAC.PartLoadFrac > 0.0:
        wind_ac_state.CoolingLoad = True
    else:
        wind_ac_state.CoolingLoad = False
    
    if windAC.fanOp == 2 and windAC.PartLoadFrac > 0.0:
        NoCompOutput = [0.0]
        CalcWindowACOutput(state, WindACNum, FirstHVACIteration, windAC.fanOp, 0.0, False, NoCompOutput)
        
        QToCoolSetPt = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
        
        if (NoCompOutput[0] > (-1.0 * SmallLoad) and QToCoolSetPt > (-1.0 * SmallLoad) and
            state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum]):
            if NoCompOutput[0] > QToCoolSetPt:
                QZnReq = QToCoolSetPt
                wind_ac_state.CoolingLoad = True


def SizeWindowAC(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    CompType = "ZoneHVAC:WindowAirConditioner"
    CompName = windAC.Name
    TempSize = -999.0
    
    state.dataSize.DataZoneNumber = windAC.ZonePtr
    state.dataSize.DataFanType = windAC.fanType
    state.dataSize.DataFanIndex = windAC.FanIndex
    state.dataSize.DataFanPlacement = windAC.fanPlace
    
    if windAC.MaxAirVolFlow == -999.0:
        windAC.MaxAirVolFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow
    
    if windAC.OutAirVolFlow == -999.0:
        windAC.OutAirVolFlow = min(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA, windAC.MaxAirVolFlow)
        if windAC.OutAirVolFlow < 0.001:
            windAC.OutAirVolFlow = 0.0


def SimCyclingWindowAC(state, WindACNum, ZoneNum, FirstHVACIteration, PowerMet, QZnReq, LatOutputProvided):
    wind_ac_state = state.dataWindowAC
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    state.dataHVACGlobal.DXElecCoolingPower = 0.0
    
    UnitOn = True
    CoilOn = True
    QUnitOut = 0.0
    LatentOutput = 0.0
    OutletNode = windAC.AirOutNode
    InletNode = windAC.AirInNode
    AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    fanOp = windAC.fanOp
    
    SmallMassFlow = 0.001
    if windAC.fanOp == 1:
        if not wind_ac_state.CoolingLoad or AirMassFlow < SmallMassFlow:
            UnitOn = False
            CoilOn = False
    elif windAC.fanOp == 2:
        if AirMassFlow < SmallMassFlow:
            UnitOn = False
            CoilOn = False
        elif not wind_ac_state.CoolingLoad:
            CoilOn = False
    
    state.dataHVACGlobal.OnOffFanPartLoadFraction = 1.0
    
    PartLoadFrac = 0.0
    HXUnitOn = False
    
    if UnitOn and CoilOn:
        HXUnitOn = False
        ControlCycWindACOutput(state, WindACNum, FirstHVACIteration, fanOp, QZnReq, PartLoadFrac, HXUnitOn)
    else:
        PartLoadFrac = 0.0
    
    windAC.PartLoadFrac = PartLoadFrac
    
    LoadMet = [0.0]
    CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac, HXUnitOn, LoadMet)
    
    AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    MinHumRat = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
    
    QUnitOut = AirMassFlow * (state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinHumRat) -
                              state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinHumRat))
    
    SensCoolOut = QUnitOut
    
    SpecHumOut = state.dataLoopNodes.Node[OutletNode].HumRat
    SpecHumIn = state.dataLoopNodes.Node[InletNode].HumRat
    LatentOutput = AirMassFlow * (SpecHumOut - SpecHumIn)
    
    QTotUnitOut = AirMassFlow * (state.dataLoopNodes.Node[OutletNode].Enthalpy - state.dataLoopNodes.Node[InletNode].Enthalpy)
    
    windAC.CompPartLoadRatio = windAC.PartLoadFrac
    if windAC.fanOp == 1:
        windAC.FanPartLoadRatio = windAC.PartLoadFrac
    else:
        windAC.FanPartLoadRatio = 1.0 if UnitOn else 0.0
    
    windAC.SensCoolEnergyRate = abs(min(0.0, SensCoolOut))
    windAC.TotCoolEnergyRate = abs(min(0.0, QTotUnitOut))
    windAC.SensCoolEnergyRate = min(windAC.SensCoolEnergyRate, windAC.TotCoolEnergyRate)
    windAC.LatCoolEnergyRate = windAC.TotCoolEnergyRate - windAC.SensCoolEnergyRate
    
    locFanElecPower = state.dataFans.fans[windAC.FanIndex - 1].totalPower
    windAC.ElecPower = locFanElecPower + state.dataHVACGlobal.DXElecCoolingPower
    
    PowerMet[0] = QUnitOut
    LatOutputProvided[0] = LatentOutput


def ReportWindowAC(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    windAC.SensCoolEnergy = windAC.SensCoolEnergyRate * TimeStepSysSec
    windAC.TotCoolEnergy = windAC.TotCoolEnergyRate * TimeStepSysSec
    windAC.LatCoolEnergy = windAC.LatCoolEnergyRate * TimeStepSysSec
    windAC.ElecConsumption = windAC.ElecPower * TimeStepSysSec
    
    if windAC.FirstPass:
        if not state.dataGlobal.SysSizingCalc:
            windAC.FirstPass = False


def CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac, HXUnitOn, LoadMet):
    wind_ac_state = state.dataWindowAC
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    OutletNode = windAC.AirOutNode
    InletNode = windAC.AirInNode
    OutsideAirNode = windAC.OutsideAirNode
    AirRelNode = windAC.AirReliefNode
    
    if fanOp == 1:
        state.dataLoopNodes.Node[InletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRateMax * PartLoadFrac
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate = min(
            state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMax,
            state.dataLoopNodes.Node[InletNode].MassFlowRate
        )
        state.dataLoopNodes.Node[AirRelNode].MassFlowRate = state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate
    
    AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    state.dataMixedAir.SimOAMixer(state, windAC.OAMixName, windAC.OAMixIndex)
    
    if windAC.fanPlace == 1:
        state.dataFans.fans[windAC.FanIndex - 1].simulate(state, FirstHVACIteration, PartLoadFrac)
    
    if windAC.coilType == 2:
        state.dataHVACHXAssistedCoolingCoil.SimHXAssistedCoolingCoil(
            state, windAC.DXCoilName, FirstHVACIteration, 1, PartLoadFrac, windAC.DXCoilIndex, windAC.fanOp, HXUnitOn
        )
    elif windAC.coilType == 3:
        state.dataVariableSpeedCoils.SimVariableSpeedCoils(
            state, windAC.DXCoilName, windAC.DXCoilIndex, windAC.fanOp, 1, PartLoadFrac, 
            windAC.DXCoilNumOfSpeeds, 1.0, -1.0, 0.0, 1.0
        )
    else:
        state.dataDXCoils.SimDXCoil(state, windAC.DXCoilName, 1, FirstHVACIteration, windAC.DXCoilIndex, windAC.fanOp, PartLoadFrac)
    
    if windAC.fanPlace == 2:
        state.dataFans.fans[windAC.FanIndex - 1].simulate(state, FirstHVACIteration, PartLoadFrac)
    
    MinHumRat = min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
    LoadMet[0] = AirMassFlow * (
        state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinHumRat) -
        state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinHumRat)
    )


def ControlCycWindACOutput(state, WindACNum, FirstHVACIteration, fanOp, QZnReq, PartLoadFrac, HXUnitOn):
    wind_ac_state = state.dataWindowAC
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    MaxIter = 50
    MinPLF = 0.0
    
    if windAC.coilType == 2:
        if state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax == -999.0:
            HXUnitOn[0] = True
        else:
            HXUnitOn[0] = False
    else:
        HXUnitOn[0] = False
    
    if windAC.EMSOverridePartLoadFrac:
        PartLoadFrac[0] = windAC.EMSValueForPartLoadFrac
        return
    
    NoCoolOutput = [0.0]
    CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, 0.0, HXUnitOn[0], NoCoolOutput)
    
    if NoCoolOutput[0] < QZnReq:
        PartLoadFrac[0] = 0.0
        return
    
    FullOutput = [0.0]
    CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, 1.0, HXUnitOn[0], FullOutput)
    
    if FullOutput[0] >= 0.0 or FullOutput[0] >= NoCoolOutput[0]:
        PartLoadFrac[0] = 0.0
        return
    
    if QZnReq <= FullOutput[0] and windAC.coilType != 2:
        PartLoadFrac[0] = 1.0
        return
    
    if QZnReq <= FullOutput[0] and windAC.coilType == 2 and state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax <= 0.0:
        PartLoadFrac[0] = 1.0
        return
    
    PartLoadFrac[0] = max(MinPLF, abs(QZnReq - NoCoolOutput[0]) / abs(FullOutput[0] - NoCoolOutput[0]))
    
    ErrorToler = windAC.ConvergenceTol
    Error = 1.0
    Iter = 0
    Relax = 1.0
    
    while abs(Error) > ErrorToler and Iter <= MaxIter and PartLoadFrac[0] > MinPLF:
        ActualOutput = [0.0]
        CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac[0], HXUnitOn[0], ActualOutput)
        Error = (QZnReq - ActualOutput[0]) / QZnReq
        DelPLF = (QZnReq - ActualOutput[0]) / FullOutput[0]
        PartLoadFrac[0] += Relax * DelPLF
        PartLoadFrac[0] = max(MinPLF, min(1.0, PartLoadFrac[0]))
        Iter += 1
        if Iter == 16:
            Relax = 0.5
    
    if windAC.coilType == 2:
        if (state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax < state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRat and
            state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax > 0.0):
            
            HXUnitOn[0] = True
            CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, 1.0, HXUnitOn[0], FullOutput)
            
            if (state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax < state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRat or
                QZnReq <= FullOutput[0]):
                PartLoadFrac[0] = 1.0
                return
            
            Error = 1.0
            Iter = 0
            Relax = 1.0
            
            while abs(Error) > ErrorToler and Iter <= MaxIter and PartLoadFrac[0] > MinPLF:
                ActualOutput = [0.0]
                CalcWindowACOutput(state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac[0], HXUnitOn[0], ActualOutput)
                Error = (QZnReq - ActualOutput[0]) / QZnReq
                DelPLF = (QZnReq - ActualOutput[0]) / FullOutput[0]
                PartLoadFrac[0] += Relax * DelPLF
                PartLoadFrac[0] = max(MinPLF, min(1.0, PartLoadFrac[0]))
                Iter += 1
                if Iter == 16:
                    Relax = 0.5


def getWindowACNodeNumber(state, nodeNumber):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    for windowACIndex in range(wind_ac_state.NumWindAC):
        windowAC = wind_ac_state.WindAC[windowACIndex]
        FanInletNodeIndex = state.dataFans.fans[windowAC.FanIndex - 1].inletNodeNum
        FanOutletNodeIndex = state.dataFans.fans[windowAC.FanIndex - 1].outletNodeNum
        
        if (windowAC.OutAirVolFlow == 0 and
            (nodeNumber == windowAC.OutsideAirNode or nodeNumber == windowAC.MixedAirNode or 
             nodeNumber == windowAC.AirReliefNode or nodeNumber == FanInletNodeIndex or 
             nodeNumber == FanOutletNodeIndex or nodeNumber == windowAC.AirInNode or 
             nodeNumber == windowAC.CoilOutletNodeNum or nodeNumber == windowAC.AirOutNode or 
             nodeNumber == windowAC.ReturnAirNode)):
            return True
    return False


def GetWindowACZoneInletAirNode(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    return windAC.AirOutNode


def GetWindowACOutAirNode(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    windAC = wind_ac_state.WindAC[WindACNum - 1]
    return windAC.OutsideAirNode


def GetWindowACReturnAirNode(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    if WindACNum > 0 and WindACNum <= wind_ac_state.NumWindAC:
        windAC = wind_ac_state.WindAC[WindACNum - 1]
        if windAC.OAMixIndex > 0:
            return state.dataMixedAir.GetOAMixerReturnNodeNumber(state, windAC.OAMixIndex)
    return 0


def GetWindowACMixedAirNode(state, WindACNum):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    if WindACNum > 0 and WindACNum <= wind_ac_state.NumWindAC:
        windAC = wind_ac_state.WindAC[WindACNum - 1]
        if windAC.OAMixIndex > 0:
            return state.dataMixedAir.GetOAMixerMixedNodeNumber(state, windAC.OAMixIndex)
    return 0


def getWindowACIndex(state, CompName):
    wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(state)
        wind_ac_state.GetWindowACInputFlag = False
    
    for WindACIndex in range(wind_ac_state.NumWindAC):
        if wind_ac_state.WindAC[WindACIndex].Name == CompName:
            return WindACIndex + 1
    return 0


def find_item_in_list(item, items):
    for i, it in enumerate(items):
        if it == item:
            return i + 1
    return 0
