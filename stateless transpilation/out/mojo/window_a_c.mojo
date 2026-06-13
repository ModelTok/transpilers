# EnergyPlus WindowAC Module - Mojo Port
# Port of WindowAC.hh and WindowAC.cc

from collections import InlineArray
from math import fabs, min as math_min, max as math_max

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with sub-objects for data access
# - Schedule: schedule objects with getCurrentVal() method
# - HVAC enums: FanType, FanOp, FanPlace, CoilType, SetptType, CompressorOp
# - Fan, DXCoil objects and simulation functions
# - Node objects and simulation utilities
# - Sizing and output processor utilities
# - Psychrometric functions


@value
struct WindACData:
    var Name: String
    var UnitType: Int32
    var availSched: UnsafePointer[Object]
    var fanOpModeSched: UnsafePointer[Object]
    var fanAvailSched: UnsafePointer[Object]
    var MaxAirVolFlow: Float64
    var MaxAirMassFlow: Float64
    var OutAirVolFlow: Float64
    var OutAirMassFlow: Float64
    var AirInNode: Int32
    var AirOutNode: Int32
    var OutsideAirNode: Int32
    var AirReliefNode: Int32
    var ReturnAirNode: Int32
    var MixedAirNode: Int32
    var OAMixName: String
    var OAMixType: String
    var OAMixIndex: Int32
    var FanName: String
    var fanType: Int32
    var FanIndex: Int32
    var DXCoilName: String
    var DXCoilType: String
    var coilType: Int32
    var DXCoilIndex: Int32
    var DXCoilNumOfSpeeds: Int32
    var CoilOutletNodeNum: Int32
    var fanOp: Int32
    var fanPlace: Int32
    var MaxIterIndex1: Int32
    var MaxIterIndex2: Int32
    var ConvergenceTol: Float64
    var PartLoadFrac: Float64
    var EMSOverridePartLoadFrac: Bool
    var EMSValueForPartLoadFrac: Float64
    var TotCoolEnergyRate: Float64
    var TotCoolEnergy: Float64
    var SensCoolEnergyRate: Float64
    var SensCoolEnergy: Float64
    var LatCoolEnergyRate: Float64
    var LatCoolEnergy: Float64
    var ElecPower: Float64
    var ElecConsumption: Float64
    var FanPartLoadRatio: Float64
    var CompPartLoadRatio: Float64
    var AvailManagerListName: String
    var availStatus: Int32
    var ZonePtr: Int32
    var HVACSizingIndex: Int32
    var FirstPass: Bool
    
    fn __init__(inout self):
        self.Name = ""
        self.UnitType = 0
        self.availSched = UnsafePointer[Object]()
        self.fanOpModeSched = UnsafePointer[Object]()
        self.fanAvailSched = UnsafePointer[Object]()
        self.MaxAirVolFlow = 0.0
        self.MaxAirMassFlow = 0.0
        self.OutAirVolFlow = 0.0
        self.OutAirMassFlow = 0.0
        self.AirInNode = 0
        self.AirOutNode = 0
        self.OutsideAirNode = 0
        self.AirReliefNode = 0
        self.ReturnAirNode = 0
        self.MixedAirNode = 0
        self.OAMixName = ""
        self.OAMixType = ""
        self.OAMixIndex = 0
        self.FanName = ""
        self.fanType = 0
        self.FanIndex = 0
        self.DXCoilName = ""
        self.DXCoilType = ""
        self.coilType = 0
        self.DXCoilIndex = 0
        self.DXCoilNumOfSpeeds = 0
        self.CoilOutletNodeNum = 0
        self.fanOp = 0
        self.fanPlace = 0
        self.MaxIterIndex1 = 0
        self.MaxIterIndex2 = 0
        self.ConvergenceTol = 0.0
        self.PartLoadFrac = 0.0
        self.EMSOverridePartLoadFrac = False
        self.EMSValueForPartLoadFrac = 0.0
        self.TotCoolEnergyRate = 0.0
        self.TotCoolEnergy = 0.0
        self.SensCoolEnergyRate = 0.0
        self.SensCoolEnergy = 0.0
        self.LatCoolEnergyRate = 0.0
        self.LatCoolEnergy = 0.0
        self.ElecPower = 0.0
        self.ElecConsumption = 0.0
        self.FanPartLoadRatio = 0.0
        self.CompPartLoadRatio = 0.0
        self.AvailManagerListName = ""
        self.availStatus = 0
        self.ZonePtr = 0
        self.HVACSizingIndex = 0
        self.FirstPass = True


@value
struct WindACNumericFieldData:
    var FieldNames: DynamicVector[String]
    
    fn __init__(inout self):
        self.FieldNames = DynamicVector[String]()


@value
struct WindowACState:
    var WindowAC_UnitType: Int32
    var cWindowAC_UnitType: String
    var cWindowAC_UnitTypes: DynamicVector[String]
    var MyOneTimeFlag: Bool
    var ZoneEquipmentListChecked: Bool
    var NumWindAC: Int32
    var NumWindACCyc: Int32
    var MySizeFlag: DynamicVector[Bool]
    var GetWindowACInputFlag: Bool
    var CoolingLoad: Bool
    var CheckEquipName: DynamicVector[Bool]
    var WindAC: DynamicVector[WindACData]
    var WindACNumericFields: DynamicVector[WindACNumericFieldData]
    var MyEnvrnFlag: DynamicVector[Bool]
    var MyZoneEqFlag: DynamicVector[Bool]
    
    fn __init__(inout self):
        self.WindowAC_UnitType = 1
        self.cWindowAC_UnitType = "ZoneHVAC:WindowAirConditioner"
        self.cWindowAC_UnitTypes = DynamicVector[String]()
        self.cWindowAC_UnitTypes.push_back("ZoneHVAC:WindowAirConditioner")
        self.MyOneTimeFlag = True
        self.ZoneEquipmentListChecked = False
        self.NumWindAC = 0
        self.NumWindACCyc = 0
        self.MySizeFlag = DynamicVector[Bool]()
        self.GetWindowACInputFlag = True
        self.CoolingLoad = False
        self.CheckEquipName = DynamicVector[Bool]()
        self.WindAC = DynamicVector[WindACData]()
        self.WindACNumericFields = DynamicVector[WindACNumericFieldData]()
        self.MyEnvrnFlag = DynamicVector[Bool]()
        self.MyZoneEqFlag = DynamicVector[Bool]()


fn SimWindowAC(inout state: Object, CompName: StringRef, ZoneNum: Int32, FirstHVACIteration: Bool, inout PowerMet: Float64, inout LatOutputProvided: Float64, inout CompIndex: Int32):
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    var WindACNum: Int32
    if CompIndex == 0:
        WindACNum = find_item_in_list(CompName, wind_ac_state.WindAC)
        if WindACNum == 0:
            _ = "SimWindowAC: Unit not found=" + String(CompName)
        CompIndex = WindACNum
    else:
        WindACNum = CompIndex
        if WindACNum > wind_ac_state.NumWindAC or WindACNum < 1:
            _ = "SimWindowAC: Invalid CompIndex passed"
        if wind_ac_state.CheckEquipName[WindACNum - 1]:
            if CompName != wind_ac_state.WindAC[WindACNum - 1].Name:
                _ = "SimWindowAC: Invalid CompIndex passed"
            wind_ac_state.CheckEquipName[WindACNum - 1] = False
    
    let RemainingOutputToCoolingSP = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum].RemainingOutputReqToCoolSP
    var QZnReq: Float64 = 0.0
    
    if RemainingOutputToCoolingSP < 0.0 and state.dataHeatBalFanSys.TempControlType[ZoneNum] != 0:
        QZnReq = RemainingOutputToCoolingSP
    
    state.dataSize.ZoneEqDXCoil = True
    state.dataSize.ZoneCoolingOnlyFan = True
    
    InitWindowAC(inout state, WindACNum, inout QZnReq, ZoneNum, FirstHVACIteration)
    SimCyclingWindowAC(inout state, WindACNum, ZoneNum, FirstHVACIteration, inout PowerMet, QZnReq, inout LatOutputProvided)
    ReportWindowAC(inout state, WindACNum)
    
    state.dataSize.ZoneEqDXCoil = False
    state.dataSize.ZoneCoolingOnlyFan = False


fn GetWindowAC(inout state: Object):
    let wind_ac_state = state.dataWindowAC
    let CurrentModuleObject = "ZoneHVAC:WindowAirConditioner"
    
    wind_ac_state.NumWindACCyc = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    wind_ac_state.NumWindAC = wind_ac_state.NumWindACCyc
    
    for i in range(wind_ac_state.NumWindAC):
        wind_ac_state.WindAC.push_back(WindACData())
        wind_ac_state.CheckEquipName.push_back(True)
        wind_ac_state.WindACNumericFields.push_back(WindACNumericFieldData())
    
    for WindACIndex in range(wind_ac_state.NumWindACCyc):
        let WindACNum = WindACIndex
        var windAC = wind_ac_state.WindAC[WindACNum]
        let Alphas = state.dataInputProcessing.inputProcessor.getObjectItem_Alphas(state, CurrentModuleObject, WindACIndex + 1)
        let Numbers = state.dataInputProcessing.inputProcessor.getObjectItem_Numbers(state, CurrentModuleObject, WindACIndex + 1)
        
        windAC.Name = Alphas[0]
        windAC.UnitType = wind_ac_state.WindowAC_UnitType
        
        if Alphas.size() > 1 and Alphas[1] != "":
            windAC.availSched = state.dataSchedule.GetSchedule(state, Alphas[1])
        else:
            windAC.availSched = state.dataSchedule.schedules_always_on()
        
        if Numbers.size() > 0:
            windAC.MaxAirVolFlow = Numbers[0]
        if Numbers.size() > 1:
            windAC.OutAirVolFlow = Numbers[1]
        
        if Alphas.size() > 2:
            windAC.AirInNode = state.dataNodeInputMgr.GetOnlySingleNode(state, Alphas[2])
        if Alphas.size() > 3:
            windAC.AirOutNode = state.dataNodeInputMgr.GetOnlySingleNode(state, Alphas[3])
        
        if Alphas.size() > 5:
            windAC.OAMixType = Alphas[4]
            windAC.OAMixName = Alphas[5]
            let OANodeNums = state.dataMixedAir.GetOAMixerNodeNumbers(state, windAC.OAMixName)
            if OANodeNums.size() > 0:
                windAC.OutsideAirNode = OANodeNums[0]
                windAC.AirReliefNode = OANodeNums[1]
                windAC.ReturnAirNode = OANodeNums[2]
                windAC.MixedAirNode = OANodeNums[3]
        
        if Alphas.size() > 7:
            windAC.FanName = Alphas[7]
            windAC.fanType = state.dataFans.get_fan_type_enum(Alphas[6])
            windAC.FanIndex = state.dataFans.GetFanIndex(state, windAC.FanName)
            if windAC.FanIndex > 0:
                let fan = state.dataFans.fans[windAC.FanIndex - 1]
                windAC.fanAvailSched = fan.availSched
        
        if Alphas.size() > 9:
            windAC.DXCoilName = Alphas[9]
            let CoilType = Alphas[8]
            
            if CoilType == "Coil:Cooling:DX:SingleSpeed" or CoilType == "CoilSystem:Cooling:DX:HeatExchangerAssisted" or CoilType == "Coil:Cooling:DX:VariableSpeed":
                windAC.DXCoilType = CoilType
                if CoilType == "Coil:Cooling:DX:SingleSpeed":
                    windAC.coilType = 1
                    windAC.CoilOutletNodeNum = state.dataDXCoils.GetCoilOutletNode(state, windAC.DXCoilType, windAC.DXCoilName)
                elif CoilType == "CoilSystem:Cooling:DX:HeatExchangerAssisted":
                    windAC.coilType = 2
                    windAC.CoilOutletNodeNum = state.dataHVACHXAssistedCoolingCoil.GetCoilOutletNode(state, windAC.DXCoilType, windAC.DXCoilName)
                elif CoilType == "Coil:Cooling:DX:VariableSpeed":
                    windAC.coilType = 3
                    windAC.CoilOutletNodeNum = state.dataVariableSpeedCoils.GetCoilOutletNodeVariableSpeed(state, windAC.DXCoilType, windAC.DXCoilName)
                    windAC.DXCoilNumOfSpeeds = state.dataVariableSpeedCoils.GetVSCoilNumOfSpeeds(state, windAC.DXCoilName)
                windAC.DXCoilIndex = state.dataDXCoils.GetCoilIndex(state, windAC.DXCoilName)
        
        if Alphas.size() > 10 and Alphas[10] != "":
            windAC.fanOpModeSched = state.dataSchedule.GetSchedule(state, Alphas[10])
        else:
            windAC.fanOp = 1
        
        if Alphas.size() > 11:
            windAC.fanPlace = state.dataFans.get_fan_place_enum(Alphas[11])
        
        if Numbers.size() > 2:
            windAC.ConvergenceTol = Numbers[2]
        
        if Alphas.size() > 12 and Alphas[12] != "":
            windAC.AvailManagerListName = Alphas[12]
        
        if Alphas.size() > 13 and Alphas[13] != "":
            windAC.HVACSizingIndex = find_item_in_list(Alphas[13], state.dataSize.ZoneHVACSizing_names)
        
        windAC.ZonePtr = state.dataZoneEquip.find_zone_for_equipment(windAC.AirOutNode)
        wind_ac_state.WindAC[WindACNum] = windAC


fn InitWindowAC(inout state: Object, WindACNum: Int32, inout QZnReq: Float64, ZoneNum: Int32, FirstHVACIteration: Bool):
    let wind_ac_state = state.dataWindowAC
    let SmallLoad = 0.01
    
    if wind_ac_state.MyOneTimeFlag:
        for _ in range(wind_ac_state.NumWindAC):
            wind_ac_state.MyEnvrnFlag.push_back(True)
            wind_ac_state.MySizeFlag.push_back(True)
            wind_ac_state.MyZoneEqFlag.push_back(True)
        wind_ac_state.MyOneTimeFlag = False
    
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    if wind_ac_state.MyZoneEqFlag[WindACNum - 1]:
        wind_ac_state.MyZoneEqFlag[WindACNum - 1] = False
    
    if not wind_ac_state.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        wind_ac_state.ZoneEquipmentListChecked = True
    
    if not state.dataGlobal.SysSizingCalc and wind_ac_state.MySizeFlag[WindACNum - 1]:
        SizeWindowAC(inout state, WindACNum)
        wind_ac_state.MySizeFlag[WindACNum - 1] = False
    
    if state.dataGlobal.BeginEnvrnFlag and wind_ac_state.MyEnvrnFlag[WindACNum - 1]:
        let InNode = windAC.AirInNode
        let OutNode = windAC.AirOutNode
        let OutsideAirNode = windAC.OutsideAirNode
        let RhoAir = state.dataEnvrn.StdRhoAir
        
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
    
    if windAC.fanOpModeSched != UnsafePointer[Object]():
        if windAC.fanOpModeSched.pointee.getCurrentVal() == 0.0:
            windAC.fanOp = 1
        else:
            windAC.fanOp = 2
    
    let InletNode = windAC.AirInNode
    let OutsideAirNode = windAC.OutsideAirNode
    let AirRelNode = windAC.AirReliefNode
    
    if (windAC.availSched.pointee.getCurrentVal() <= 0.0 or 
        (windAC.fanAvailSched.pointee.getCurrentVal() <= 0.0 and not state.dataHVACGlobal.TurnFansOn) or
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
    
    if QZnReq < (-1.0 * SmallLoad) and not state.dataZoneEnergyDemand.CurDeadBandOrSetback[ZoneNum] and windAC.PartLoadFrac > 0.0:
        wind_ac_state.CoolingLoad = True
    else:
        wind_ac_state.CoolingLoad = False
    
    wind_ac_state.WindAC[WindACNum - 1] = windAC


fn SizeWindowAC(inout state: Object, WindACNum: Int32):
    let wind_ac_state = state.dataWindowAC
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    let CompType = "ZoneHVAC:WindowAirConditioner"
    let CompName = windAC.Name
    
    state.dataSize.DataZoneNumber = windAC.ZonePtr
    state.dataSize.DataFanType = windAC.fanType
    state.dataSize.DataFanIndex = windAC.FanIndex
    state.dataSize.DataFanPlacement = windAC.fanPlace
    
    if windAC.MaxAirVolFlow == -999.0:
        windAC.MaxAirVolFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow
    
    if windAC.OutAirVolFlow == -999.0:
        windAC.OutAirVolFlow = math_min(state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA, windAC.MaxAirVolFlow)
        if windAC.OutAirVolFlow < 0.001:
            windAC.OutAirVolFlow = 0.0
    
    wind_ac_state.WindAC[WindACNum - 1] = windAC


fn SimCyclingWindowAC(inout state: Object, WindACNum: Int32, ZoneNum: Int32, FirstHVACIteration: Bool, inout PowerMet: Float64, QZnReq: Float64, inout LatOutputProvided: Float64):
    let wind_ac_state = state.dataWindowAC
    let SmallMassFlow = 0.001
    
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    state.dataHVACGlobal.DXElecCoolingPower = 0.0
    
    var UnitOn = True
    var CoilOn = True
    let OutletNode = windAC.AirOutNode
    let InletNode = windAC.AirInNode
    var AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    let fanOp = windAC.fanOp
    
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
    
    var PartLoadFrac = 0.0
    var HXUnitOn = False
    
    if UnitOn and CoilOn:
        ControlCycWindACOutput(inout state, WindACNum, FirstHVACIteration, fanOp, QZnReq, inout PartLoadFrac, inout HXUnitOn)
    else:
        PartLoadFrac = 0.0
    
    windAC.PartLoadFrac = PartLoadFrac
    
    var LoadMet = 0.0
    CalcWindowACOutput(inout state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac, HXUnitOn, inout LoadMet)
    
    AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
    let MinHumRat = math_min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
    let QUnitOut = AirMassFlow * (state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinHumRat) -
                              state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinHumRat))
    
    let SensCoolOut = QUnitOut
    let SpecHumOut = state.dataLoopNodes.Node[OutletNode].HumRat
    let SpecHumIn = state.dataLoopNodes.Node[InletNode].HumRat
    let LatentOutput = AirMassFlow * (SpecHumOut - SpecHumIn)
    
    let QTotUnitOut = AirMassFlow * (state.dataLoopNodes.Node[OutletNode].Enthalpy - state.dataLoopNodes.Node[InletNode].Enthalpy)
    
    windAC.CompPartLoadRatio = windAC.PartLoadFrac
    if windAC.fanOp == 1:
        windAC.FanPartLoadRatio = windAC.PartLoadFrac
    else:
        windAC.FanPartLoadRatio = 1.0 if UnitOn else 0.0
    
    windAC.SensCoolEnergyRate = fabs(math_min(0.0, SensCoolOut))
    windAC.TotCoolEnergyRate = fabs(math_min(0.0, QTotUnitOut))
    windAC.SensCoolEnergyRate = math_min(windAC.SensCoolEnergyRate, windAC.TotCoolEnergyRate)
    windAC.LatCoolEnergyRate = windAC.TotCoolEnergyRate - windAC.SensCoolEnergyRate
    
    let locFanElecPower = state.dataFans.fans[windAC.FanIndex - 1].totalPower
    windAC.ElecPower = locFanElecPower + state.dataHVACGlobal.DXElecCoolingPower
    
    PowerMet = QUnitOut
    LatOutputProvided = LatentOutput
    wind_ac_state.WindAC[WindACNum - 1] = windAC


fn ReportWindowAC(inout state: Object, WindACNum: Int32):
    let wind_ac_state = state.dataWindowAC
    let TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
    
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    windAC.SensCoolEnergy = windAC.SensCoolEnergyRate * TimeStepSysSec
    windAC.TotCoolEnergy = windAC.TotCoolEnergyRate * TimeStepSysSec
    windAC.LatCoolEnergy = windAC.LatCoolEnergyRate * TimeStepSysSec
    windAC.ElecConsumption = windAC.ElecPower * TimeStepSysSec
    
    if windAC.FirstPass:
        if not state.dataGlobal.SysSizingCalc:
            windAC.FirstPass = False
    
    wind_ac_state.WindAC[WindACNum - 1] = windAC


fn CalcWindowACOutput(inout state: Object, WindACNum: Int32, FirstHVACIteration: Bool, fanOp: Int32, PartLoadFrac: Float64, HXUnitOn: Bool, inout LoadMet: Float64):
    let wind_ac_state = state.dataWindowAC
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    let OutletNode = windAC.AirOutNode
    let InletNode = windAC.AirInNode
    let OutsideAirNode = windAC.OutsideAirNode
    let AirRelNode = windAC.AirReliefNode
    
    if fanOp == 1:
        state.dataLoopNodes.Node[InletNode].MassFlowRate = state.dataLoopNodes.Node[InletNode].MassFlowRateMax * PartLoadFrac
        state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate = math_min(
            state.dataLoopNodes.Node[OutsideAirNode].MassFlowRateMax,
            state.dataLoopNodes.Node[InletNode].MassFlowRate
        )
        state.dataLoopNodes.Node[AirRelNode].MassFlowRate = state.dataLoopNodes.Node[OutsideAirNode].MassFlowRate
    
    let AirMassFlow = state.dataLoopNodes.Node[InletNode].MassFlowRate
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
    
    let MinHumRat = math_min(state.dataLoopNodes.Node[InletNode].HumRat, state.dataLoopNodes.Node[OutletNode].HumRat)
    LoadMet = AirMassFlow * (
        state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[OutletNode].Temp, MinHumRat) -
        state.dataPsychrometrics.PsyHFnTdbW(state.dataLoopNodes.Node[InletNode].Temp, MinHumRat)
    )


fn ControlCycWindACOutput(inout state: Object, WindACNum: Int32, FirstHVACIteration: Bool, fanOp: Int32, QZnReq: Float64, inout PartLoadFrac: Float64, inout HXUnitOn: Bool):
    let wind_ac_state = state.dataWindowAC
    let MaxIter = 50
    let MinPLF = 0.0
    
    var windAC = wind_ac_state.WindAC[WindACNum - 1]
    
    if windAC.coilType == 2:
        if state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax == -999.0:
            HXUnitOn = True
        else:
            HXUnitOn = False
    else:
        HXUnitOn = False
    
    if windAC.EMSOverridePartLoadFrac:
        PartLoadFrac = windAC.EMSValueForPartLoadFrac
        return
    
    var NoCoolOutput = 0.0
    CalcWindowACOutput(inout state, WindACNum, FirstHVACIteration, fanOp, 0.0, HXUnitOn, inout NoCoolOutput)
    
    if NoCoolOutput < QZnReq:
        PartLoadFrac = 0.0
        return
    
    var FullOutput = 0.0
    CalcWindowACOutput(inout state, WindACNum, FirstHVACIteration, fanOp, 1.0, HXUnitOn, inout FullOutput)
    
    if FullOutput >= 0.0 or FullOutput >= NoCoolOutput:
        PartLoadFrac = 0.0
        return
    
    if QZnReq <= FullOutput and windAC.coilType != 2:
        PartLoadFrac = 1.0
        return
    
    if QZnReq <= FullOutput and windAC.coilType == 2 and state.dataLoopNodes.Node[windAC.CoilOutletNodeNum].HumRatMax <= 0.0:
        PartLoadFrac = 1.0
        return
    
    PartLoadFrac = math_max(MinPLF, fabs(QZnReq - NoCoolOutput) / fabs(FullOutput - NoCoolOutput))
    
    let ErrorToler = windAC.ConvergenceTol
    var Error = 1.0
    var Iter = 0
    var Relax = 1.0
    
    while fabs(Error) > ErrorToler and Iter <= MaxIter and PartLoadFrac > MinPLF:
        var ActualOutput = 0.0
        CalcWindowACOutput(inout state, WindACNum, FirstHVACIteration, fanOp, PartLoadFrac, HXUnitOn, inout ActualOutput)
        Error = (QZnReq - ActualOutput) / QZnReq
        let DelPLF = (QZnReq - ActualOutput) / FullOutput
        PartLoadFrac += Relax * DelPLF
        PartLoadFrac = math_max(MinPLF, math_min(1.0, PartLoadFrac))
        Iter += 1
        if Iter == 16:
            Relax = 0.5


fn getWindowACNodeNumber(inout state: Object, nodeNumber: Int32) -> Bool:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    for windowACIndex in range(wind_ac_state.NumWindAC):
        let windowAC = wind_ac_state.WindAC[windowACIndex]
        let FanInletNodeIndex = state.dataFans.fans[windowAC.FanIndex - 1].inletNodeNum
        let FanOutletNodeIndex = state.dataFans.fans[windowAC.FanIndex - 1].outletNodeNum
        
        if (windowAC.OutAirVolFlow == 0 and
            (nodeNumber == windowAC.OutsideAirNode or nodeNumber == windowAC.MixedAirNode or 
             nodeNumber == windowAC.AirReliefNode or nodeNumber == FanInletNodeIndex or 
             nodeNumber == FanOutletNodeIndex or nodeNumber == windowAC.AirInNode or 
             nodeNumber == windowAC.CoilOutletNodeNum or nodeNumber == windowAC.AirOutNode or 
             nodeNumber == windowAC.ReturnAirNode)):
            return True
    return False


fn GetWindowACZoneInletAirNode(inout state: Object, WindACNum: Int32) -> Int32:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    let windAC = wind_ac_state.WindAC[WindACNum - 1]
    return windAC.AirOutNode


fn GetWindowACOutAirNode(inout state: Object, WindACNum: Int32) -> Int32:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    let windAC = wind_ac_state.WindAC[WindACNum - 1]
    return windAC.OutsideAirNode


fn GetWindowACReturnAirNode(inout state: Object, WindACNum: Int32) -> Int32:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    if WindACNum > 0 and WindACNum <= wind_ac_state.NumWindAC:
        let windAC = wind_ac_state.WindAC[WindACNum - 1]
        if windAC.OAMixIndex > 0:
            return state.dataMixedAir.GetOAMixerReturnNodeNumber(state, windAC.OAMixIndex)
    return 0


fn GetWindowACMixedAirNode(inout state: Object, WindACNum: Int32) -> Int32:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    if WindACNum > 0 and WindACNum <= wind_ac_state.NumWindAC:
        let windAC = wind_ac_state.WindAC[WindACNum - 1]
        if windAC.OAMixIndex > 0:
            return state.dataMixedAir.GetOAMixerMixedNodeNumber(state, windAC.OAMixIndex)
    return 0


fn getWindowACIndex(inout state: Object, CompName: StringRef) -> Int32:
    let wind_ac_state = state.dataWindowAC
    
    if wind_ac_state.GetWindowACInputFlag:
        GetWindowAC(inout state)
        wind_ac_state.GetWindowACInputFlag = False
    
    for WindACIndex in range(wind_ac_state.NumWindAC):
        if wind_ac_state.WindAC[WindACIndex].Name == String(CompName):
            return Int32(WindACIndex + 1)
    return 0


fn find_item_in_list(item: StringRef, items: DynamicVector[WindACData]) -> Int32:
    for i in range(items.size()):
        if items[i].Name == String(item):
            return Int32(i + 1)
    return 0
