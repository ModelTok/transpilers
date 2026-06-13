from DataHeatBalance import Zone, space (maybe)
from DataEnvironment import state.dataEnvrn (assume)
from DataHVACGlobals import TimeStepSysSec (as var)
from DataZoneTempPredictorCorrector import zoneHeatBalance, spaceHeatBalance
from InputProcessing.InputProcessor import InputProcessor, getObjectSchemaProps, getNumObjectsFound, getAlphaFieldValue, getRealFieldValue, markObjectAsUsed
from OutputProcessor import SetupOutputVariable, Constant, OutputProcessor
from Psychrometrics import PsyWFnTdbTwbPb, PsyWFnTdbH, PsyRhoAirFnPbTdbW, RhoH2O, PsyCpAirFnW
from ScheduleManager import Sched
from UtilityRoutines import makeUPPER, FindItemInList
from WaterManager import SetupTankDemandComponent
from DataWater import WaterStorage (struct or alias)
from DataGlobals import Clusive, ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowSevereEmptyField, ShowSevereInvalidKey, ShowWarningBadMax, ShowWarningBadMin, ShowContinueError, ErrorObjectHeader
from Data.EnergyPlusData import EnergyPlusData (struct)
from Data.BaseData import BaseGlobalStruct
import math
from memory import Pointer
module CoolTower:
    @value
    struct FlowCtrl(Int):
        Invalid = -1
        FlowSchedule = 0
        WindDriven = 1
        Num = 2
    @value
    struct WaterSupplyMode(Int):
        Invalid = -1
        FromMains = 0
        FromTank = 1
        Num = 2
    struct CoolTowerParams:
        var Name: String
        var CompType: String
        var availSched: Pointer[Sched.Schedule]
        var ZonePtr: Int = 0
        var spacePtr: Int = 0
        var pumpSched: Pointer[Sched.Schedule]
        var FlowCtrlType: FlowCtrl = FlowCtrl.Invalid
        var CoolTWaterSupplyMode: WaterSupplyMode = WaterSupplyMode.FromMains
        var CoolTWaterSupplyName: String
        var CoolTWaterSupTankID: Int
        var CoolTWaterTankDemandARRID: Int
        var TowerHeight: Float64 = 0.0
        var OutletArea: Float64 = 0.0
        var OutletVelocity: Float64 = 0.0
        var MaxAirVolFlowRate: Float64 = 0.0
        var AirMassFlowRate: Float64 = 0.0
        var CoolTAirMass: Float64 = 0.0
        var MinZoneTemp: Float64 = 0.0
        var FracWaterLoss: Float64 = 0.0
        var FracFlowSched: Float64 = 0.0
        var MaxWaterFlowRate: Float64 = 0.0
        var ActualWaterFlowRate: Float64 = 0.0
        var RatedPumpPower: Float64 = 0.0
        var SenHeatLoss: Float64 = 0.0
        var SenHeatPower: Float64 = 0.0
        var LatHeatLoss: Float64 = 0.0
        var LatHeatPower: Float64 = 0.0
        var AirVolFlowRate: Float64 = 0.0
        var AirVolFlowRateStd: Float64 = 0.0
        var CoolTAirVol: Float64 = 0.0
        var ActualAirVolFlowRate: Float64 = 0.0
        var InletDBTemp: Float64 = 0.0
        var InletWBTemp: Float64 = 0.0
        var InletHumRat: Float64 = 0.0
        var OutletTemp: Float64 = 0.0
        var OutletHumRat: Float64 = 0.0
        var CoolTWaterConsumpRate: Float64 = 0.0
        var CoolTWaterStarvMakeupRate: Float64 = 0.0
        var CoolTWaterStarvMakeup: Float64 = 0.0
        var CoolTWaterConsump: Float64 = 0.0
        var PumpElecPower: Float64 = 0.0
        var PumpElecConsump: Float64 = 0.0
    var FlowCtrlNamesUC: List[String] = ["WATERFLOWSCHEDULE", "WINDDRIVENFLOW"]
    def ManageCoolTower(state: Pointer[EnergyPlusData]):
        if state[].dataCoolTower.GetInputFlag:
            GetCoolTower(state)
            state[].dataCoolTower.GetInputFlag = False
        if len(state[].dataCoolTower.CoolTowerSys) == 0:
            return
        CalcCoolTower(state)
        UpdateCoolTower(state)
        ReportCoolTower(state)
    def GetCoolTower(state: Pointer[EnergyPlusData]):
        var routineName: String = "GetCoolTower"
        var CurrentModuleObject: String = "ZoneCoolTower:Shower"
        let MaximumWaterFlowRate: Float64 = 0.016667
        let MinimumWaterFlowRate: Float64 = 0.0
        let MaxHeight: Float64 = 30.0
        let MinHeight: Float64 = 1.0
        let MaxValue: Float64 = 100.0
        let MinValue: Float64 = 0.0
        let MaxFrac: Float64 = 1.0
        let MinFrac: Float64 = 0.0
        var ErrorsFound: Bool = False
        var inputProcessor: Pointer[InputProcessor] = state[].dataInputProcessing.inputProcessor
        var NumCoolTowers: Int = inputProcessor[].getNumObjectsFound(state, CurrentModuleObject)
        state[].dataCoolTower.CoolTowerSys = List[CoolTowerParams](capacity=NumCoolTowers)
        for _ in range(NumCoolTowers):
            state[].dataCoolTower.CoolTowerSys.append(CoolTowerParams())
        var objectSchemaProps = inputProcessor[].getObjectSchemaProps(state, CurrentModuleObject)
        var coolTowerObjects = inputProcessor[].epJSON[CurrentModuleObject]  # assuming dict
        if coolTowerObjects is not None:   # check existence
            var CoolTowerNum: Int = 0   # 0-based index
            for coolTowerInstance in coolTowerObjects.items():
                var coolTowerFields = coolTowerInstance.value
                var coolTowerName: String = Util.makeUPPER(coolTowerInstance.key)
                var availabilityScheduleName: String = inputProcessor[].getAlphaFieldValue(coolTowerFields, objectSchemaProps, "availability_schedule_name")
                var zoneOrSpaceName: String = inputProcessor[].getAlphaFieldValue(coolTowerFields, objectSchemaProps, "zone_or_space_name")
                var waterSupplyStorageTankName: String = inputProcessor[].getAlphaFieldValue(coolTowerFields, objectSchemaProps, "water_supply_storage_tank_name")
                var flowControlType: String = inputProcessor[].getAlphaFieldValue(coolTowerFields, objectSchemaProps, "flow_control_type")
                var pumpFlowRateScheduleName: String = inputProcessor[].getAlphaFieldValue(coolTowerFields, objectSchemaProps, "pump_flow_rate_schedule_name")
                inputProcessor[].markObjectAsUsed(CurrentModuleObject, coolTowerInstance.key)
                var eoh: ErrorObjectHeader = ErrorObjectHeader(routineName, CurrentModuleObject, coolTowerName)
                var coolTower = state[].dataCoolTower.CoolTowerSys[CoolTowerNum]
                coolTower.Name = coolTowerName
                if availabilityScheduleName == "":
                    coolTower.availSched = Sched.GetScheduleAlwaysOn(state)
                else:
                    var sched_ptr = Sched.GetSchedule(state, availabilityScheduleName)
                    if sched_ptr == None:
                        ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availabilityScheduleName)
                        ErrorsFound = True
                    else:
                        coolTower.availSched = sched_ptr
                if zoneOrSpaceName == "":
                    ShowSevereEmptyField(state, eoh, "Zone or Space Name")
                    ErrorsFound = True
                else:
                    var zonePtr = Util.FindItemInList(zoneOrSpaceName, state[].dataHeatBal.Zone)
                    var spacePtr = Util.FindItemInList(zoneOrSpaceName, state[].dataHeatBal.space)
                    if zonePtr == 0 and spacePtr == 0:
                        ShowSevereItemNotFound(state, eoh, "Zone or Space Name", zoneOrSpaceName)
                        ErrorsFound = True
                    else:
                        if zonePtr == 0:
                            coolTower.ZonePtr = state[].dataHeatBal.space[spacePtr-1].zoneNum
                        else:
                            coolTower.ZonePtr = zonePtr
                        coolTower.spacePtr = spacePtr
                coolTower.CoolTWaterSupplyName = waterSupplyStorageTankName
                if waterSupplyStorageTankName == "":
                    coolTower.CoolTWaterSupplyMode = WaterSupplyMode.FromMains
                elif coolTower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
                    WaterManager.SetupTankDemandComponent(state, coolTower.Name, CurrentModuleObject, coolTower.CoolTWaterSupplyName, ErrorsFound, coolTower.CoolTWaterSupTankID, coolTower.CoolTWaterTankDemandARRID)
                var flowCtrlVal: Int = -1
                for (i, name) in enumerate(FlowCtrlNamesUC):
                    if name == flowControlType:
                        flowCtrlVal = i
                        break
                if flowCtrlVal == -1:
                    ShowSevereInvalidKey(state, eoh, "Flow Control Type", flowControlType)
                    ErrorsFound = True
                else:
                    coolTower.FlowCtrlType = FlowCtrl(flowCtrlVal)
                var pump_sched_ptr = Sched.GetSchedule(state, pumpFlowRateScheduleName)
                if pump_sched_ptr == None:
                    ShowSevereItemNotFound(state, eoh, "Pump Flow Rate Schedule Name", pumpFlowRateScheduleName)
                    ErrorsFound = True
                else:
                    coolTower.pumpSched = pump_sched_ptr
                coolTower.MaxWaterFlowRate = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "maximum_water_flow_rate")
                if coolTower.MaxWaterFlowRate > MaximumWaterFlowRate:
                    coolTower.MaxWaterFlowRate = MaximumWaterFlowRate
                    ShowWarningBadMax(state, eoh, "Maximum Water Flow Rate", coolTower.MaxWaterFlowRate, Clusive.In, MaximumWaterFlowRate)
                if coolTower.MaxWaterFlowRate < MinimumWaterFlowRate:
                    coolTower.MaxWaterFlowRate = MinimumWaterFlowRate
                    ShowWarningBadMin(state, eoh, "Maximum Water Flow Rate", coolTower.MaxWaterFlowRate, Clusive.In, MinimumWaterFlowRate)
                coolTower.TowerHeight = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "effective_tower_height")
                if coolTower.TowerHeight > MaxHeight:
                    coolTower.TowerHeight = MaxHeight
                    ShowWarningBadMax(state, eoh, "Effective Tower Height", coolTower.TowerHeight, Clusive.In, MaxHeight)
                if coolTower.TowerHeight < MinHeight:
                    coolTower.TowerHeight = MinHeight
                    ShowWarningBadMin(state, eoh, "Effective Tower Height", coolTower.TowerHeight, Clusive.In, MinHeight)
                coolTower.OutletArea = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "airflow_outlet_area")
                if coolTower.OutletArea > MaxValue:
                    coolTower.OutletArea = MaxValue
                    ShowWarningBadMax(state, eoh, "Airflow Outlet Area", coolTower.OutletArea, Clusive.In, MaxValue)
                if coolTower.OutletArea < MinValue:
                    coolTower.OutletArea = MinValue
                    ShowWarningBadMin(state, eoh, "Airflow Outlet Area", coolTower.OutletArea, Clusive.In, MinValue)
                coolTower.MaxAirVolFlowRate = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "maximum_air_flow_rate")
                if coolTower.MaxAirVolFlowRate > MaxValue:
                    coolTower.MaxAirVolFlowRate = MaxValue
                    ShowWarningBadMax(state, eoh, "Maximum Air Flow Rate", coolTower.MaxAirVolFlowRate, Clusive.In, MaxValue)
                if coolTower.MaxAirVolFlowRate < MinValue:
                    coolTower.MaxAirVolFlowRate = MinValue
                    ShowWarningBadMin(state, eoh, "Maximum Air Flow Rate", coolTower.MaxAirVolFlowRate, Clusive.In, MinValue)
                coolTower.MinZoneTemp = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "minimum_indoor_temperature")
                if coolTower.MinZoneTemp > MaxValue:
                    coolTower.MinZoneTemp = MaxValue
                    ShowWarningBadMax(state, eoh, "Minimum Indoor Temperature", coolTower.MinZoneTemp, Clusive.In, MaxValue)
                if coolTower.MinZoneTemp < MinValue:
                    coolTower.MinZoneTemp = MinValue
                    ShowWarningBadMin(state, eoh, "Minimum Indoor Temperature", coolTower.MinZoneTemp, Clusive.In, MinValue)
                coolTower.FracWaterLoss = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "fraction_of_water_loss")
                if coolTower.FracWaterLoss > MaxFrac:
                    coolTower.FracWaterLoss = MaxFrac
                    ShowWarningBadMax(state, eoh, "Fraction of Water Loss", coolTower.FracWaterLoss, Clusive.In, MaxFrac)
                if coolTower.FracWaterLoss < MinFrac:
                    coolTower.FracWaterLoss = MinFrac
                    ShowWarningBadMin(state, eoh, "Fraction of Water Loss", coolTower.FracWaterLoss, Clusive.In, MinFrac)
                coolTower.FracFlowSched = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "fraction_of_flow_schedule")
                if coolTower.FracFlowSched > MaxFrac:
                    coolTower.FracFlowSched = MaxFrac
                    ShowWarningBadMax(state, eoh, "Fraction of Flow Schedule", coolTower.FracFlowSched, Clusive.In, MaxFrac)
                if coolTower.FracFlowSched < MinFrac:
                    coolTower.FracFlowSched = MinFrac
                    ShowWarningBadMin(state, eoh, "Fraction of Flow Schedule", coolTower.FracFlowSched, Clusive.In, MinFrac)
                coolTower.RatedPumpPower = inputProcessor[].getRealFieldValue(coolTowerFields, objectSchemaProps, "rated_power_consumption")
                CoolTowerNum += 1
            if ErrorsFound:
                ShowFatalError(state, String.format("{} errors occurred in input.  Program terminates.", CurrentModuleObject))
        for CoolTowerNum in range(len(state[].dataCoolTower.CoolTowerSys)):
            var coolTower = state[].dataCoolTower.CoolTowerSys[CoolTowerNum]
            var zone = state[].dataHeatBal.Zone[coolTower.ZonePtr - 1]  # 0-based
            SetupOutputVariable(state, "Zone Cooltower Sensible Heat Loss Energy", Constant.Units.J, coolTower.SenHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Sensible Heat Loss Rate", Constant.Units.W, coolTower.SenHeatPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Latent Heat Loss Energy", Constant.Units.J, coolTower.LatHeatLoss, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Latent Heat Loss Rate", Constant.Units.W, coolTower.LatHeatPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Volume", Constant.Units.m3, coolTower.CoolTAirVol, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Current Density Air Volume Flow Rate", Constant.Units.m3_s, coolTower.AirVolFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Standard Density Air Volume Flow Rate", Constant.Units.m3_s, coolTower.AirVolFlowRateStd, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Mass", Constant.Units.kg, coolTower.CoolTAirMass, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Mass Flow Rate", Constant.Units.kg_s, coolTower.AirMassFlowRate, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Inlet Temperature", Constant.Units.C, coolTower.InletDBTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Inlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, coolTower.InletHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Outlet Temperature", Constant.Units.C, coolTower.OutletTemp, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Air Outlet Humidity Ratio", Constant.Units.kgWater_kgDryAir, coolTower.OutletHumRat, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Pump Electricity Rate", Constant.Units.W, coolTower.PumpElecPower, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Average, zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Pump Electricity Energy", Constant.Units.J, coolTower.PumpElecConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name, Constant.eResource.Electricity, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
            if coolTower.CoolTWaterSupplyMode == WaterSupplyMode.FromMains:
                SetupOutputVariable(state, "Zone Cooltower Water Volume", Constant.Units.m3, coolTower.CoolTWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                SetupOutputVariable(state, "Zone Cooltower Mains Water Volume", Constant.Units.m3, coolTower.CoolTWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name, Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
            elif coolTower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
                SetupOutputVariable(state, "Zone Cooltower Water Volume", Constant.Units.m3, coolTower.CoolTWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                SetupOutputVariable(state, "Zone Cooltower Storage Tank Water Volume", Constant.Units.m3, coolTower.CoolTWaterConsump, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name)
                SetupOutputVariable(state, "Zone Cooltower Starved Mains Water Volume", Constant.Units.m3, coolTower.CoolTWaterStarvMakeup, OutputProcessor.TimeStepType.System, OutputProcessor.StoreType.Sum, zone.Name, Constant.eResource.MainsWater, OutputProcessor.Group.HVAC, OutputProcessor.EndUseCat.Cooling)
    def CalcCoolTower(state: Pointer[EnergyPlusData]):
        let MinWindSpeed: Float64 = 0.1
        let MaxWindSpeed: Float64 = 30.0
        let UCFactor: Float64 = 60000.0
        var CVF_ZoneNum: Float64
        var AirMassFlowRate: Float64
        var AirSpecHeat: Float64
        var AirDensity: Float64
        var RhoWater: Float64
        var PumpPartLoadRat: Float64
        var WaterFlowRate: Float64 = 0.0
        var AirVolFlowRate: Float64 = 0.0
        var InletHumRat: Float64
        var OutletHumRat: Float64
        var OutletTemp: Float64 = 0.0
        var IntHumRat: Float64
        var Zone = state[].dataHeatBal.Zone
        for CoolTowerNum in range(len(state[].dataCoolTower.CoolTowerSys)):
            var coolTower = state[].dataCoolTower.CoolTowerSys[CoolTowerNum]
            let ZoneNum: Int = coolTower.ZonePtr
            var thisZoneHB = state[].dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]  # 0-based
            thisZoneHB.MCPTC = 0.0
            thisZoneHB.MCPC = 0.0
            thisZoneHB.CTMFL = 0.0
            if state[].dataHeatBal.doSpaceHeatBalance and coolTower.spacePtr > 0:
                var thisSpaceHB = state[].dataZoneTempPredictorCorrector.spaceHeatBalance[coolTower.spacePtr - 1]
                thisSpaceHB.MCPTC = 0.0
                thisSpaceHB.MCPC = 0.0
                thisSpaceHB.CTMFL = 0.0
            if coolTower.availSched[].getCurrentVal() > 0.0:
                if state[].dataEnvrn.WindSpeed < MinWindSpeed or state[].dataEnvrn.WindSpeed > MaxWindSpeed:
                    continue
                if state[].dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT < coolTower.MinZoneTemp:
                    continue
                if coolTower.FlowCtrlType == FlowCtrl.WindDriven:
                    let height_sqrt: Float64 = math.sqrt(coolTower.TowerHeight)
                    coolTower.OutletVelocity = 0.7 * height_sqrt + 0.47 * (state[].dataEnvrn.WindSpeed - 1.0)
                    AirVolFlowRate = coolTower.OutletArea * coolTower.OutletVelocity
                    AirVolFlowRate = min(AirVolFlowRate, coolTower.MaxAirVolFlowRate)
                    WaterFlowRate = (AirVolFlowRate / (0.0125 * height_sqrt))
                    if WaterFlowRate > coolTower.MaxWaterFlowRate * UCFactor:
                        WaterFlowRate = coolTower.MaxWaterFlowRate * UCFactor
                        AirVolFlowRate = 0.0125 * WaterFlowRate * height_sqrt
                        AirVolFlowRate = min(AirVolFlowRate, coolTower.MaxAirVolFlowRate)
                    WaterFlowRate = min(WaterFlowRate, (coolTower.MaxWaterFlowRate * UCFactor))
                    OutletTemp = state[].dataEnvrn.OutDryBulbTemp - (state[].dataEnvrn.OutDryBulbTemp - state[].dataEnvrn.OutWetBulbTemp) * (1.0 - math.exp(-0.8 * coolTower.TowerHeight)) * (1.0 - math.exp(-0.15 * WaterFlowRate))
                elif coolTower.FlowCtrlType == FlowCtrl.FlowSchedule:
                    WaterFlowRate = coolTower.MaxWaterFlowRate * UCFactor
                    AirVolFlowRate = 0.0125 * WaterFlowRate * math.sqrt(coolTower.TowerHeight)
                    AirVolFlowRate = min(AirVolFlowRate, coolTower.MaxAirVolFlowRate)
                    OutletTemp = state[].dataEnvrn.OutDryBulbTemp - (state[].dataEnvrn.OutDryBulbTemp - state[].dataEnvrn.OutWetBulbTemp) * (1.0 - math.exp(-0.8 * coolTower.TowerHeight)) * (1.0 - math.exp(-0.15 * WaterFlowRate))
                if OutletTemp < state[].dataEnvrn.OutWetBulbTemp:
                    ShowSevereError(state, "Cooltower outlet temperature exceed the outdoor wet bulb temperature reset to input values")
                    ShowContinueError(state, String.format("Occurs in Cooltower ={}", coolTower.Name))
                WaterFlowRate /= UCFactor
                if coolTower.FracWaterLoss > 0.0:
                    coolTower.ActualWaterFlowRate = WaterFlowRate * (1.0 + coolTower.FracWaterLoss)
                else:
                    coolTower.ActualWaterFlowRate = WaterFlowRate
                if coolTower.FracFlowSched > 0.0:
                    coolTower.ActualAirVolFlowRate = AirVolFlowRate * (1.0 - coolTower.FracFlowSched)
                else:
                    coolTower.ActualAirVolFlowRate = AirVolFlowRate
                if coolTower.pumpSched[].getCurrentVal() > 0:
                    PumpPartLoadRat = coolTower.pumpSched[].getCurrentVal()
                else:
                    PumpPartLoadRat = 1.0
                InletHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, state[].dataEnvrn.OutDryBulbTemp, state[].dataEnvrn.OutWetBulbTemp, state[].dataEnvrn.OutBaroPress)
                IntHumRat = Psychrometrics.PsyWFnTdbH(state, OutletTemp, state[].dataEnvrn.OutEnthalpy)
                AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state[].dataEnvrn.OutBaroPress, OutletTemp, IntHumRat)
                AirMassFlowRate = AirDensity * coolTower.ActualAirVolFlowRate
                RhoWater = Psychrometrics.RhoH2O(OutletTemp)
                OutletHumRat = (InletHumRat * (AirMassFlowRate + (coolTower.ActualWaterFlowRate * RhoWater))) / AirMassFlowRate
                AirSpecHeat = Psychrometrics.PsyCpAirFnW(OutletHumRat)
                AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state[].dataEnvrn.OutBaroPress, OutletTemp, OutletHumRat)
                CVF_ZoneNum = coolTower.ActualAirVolFlowRate * coolTower.availSched[].getCurrentVal()
                let thisMCPC: Float64 = CVF_ZoneNum * AirDensity * AirSpecHeat
                let thisMCPTC: Float64 = thisMCPC * OutletTemp
                let thisCTMFL: Float64 = thisMCPC / AirSpecHeat
                var thisZT: Float64 = thisZoneHB.ZT
                var thisAirHumRat: Float64 = thisZoneHB.airHumRat
                thisZoneHB.MCPC = thisMCPC
                thisZoneHB.MCPTC = thisMCPTC
                thisZoneHB.CTMFL = thisCTMFL
                if state[].dataHeatBal.doSpaceHeatBalance and coolTower.spacePtr > 0:
                    var thisSpaceHB = state[].dataZoneTempPredictorCorrector.spaceHeatBalance[coolTower.spacePtr - 1]
                    thisSpaceHB.MCPC = thisMCPC
                    thisSpaceHB.MCPTC = thisMCPTC
                    thisSpaceHB.CTMFL = thisCTMFL
                    thisZT = thisSpaceHB.ZT
                    thisAirHumRat = thisSpaceHB.airHumRat
                coolTower.SenHeatPower = thisMCPC * abs(thisZT - OutletTemp)
                coolTower.LatHeatPower = CVF_ZoneNum * abs(thisAirHumRat - OutletHumRat)
                coolTower.OutletTemp = OutletTemp
                coolTower.OutletHumRat = OutletHumRat
                coolTower.AirVolFlowRate = CVF_ZoneNum
                coolTower.AirMassFlowRate = thisCTMFL
                coolTower.AirVolFlowRateStd = thisCTMFL / state[].dataEnvrn.StdRhoAir
                coolTower.InletDBTemp = Zone[ZoneNum - 1].OutDryBulbTemp
                coolTower.InletWBTemp = Zone[ZoneNum - 1].OutWetBulbTemp
                coolTower.InletHumRat = state[].dataEnvrn.OutHumRat
                coolTower.CoolTWaterConsumpRate = (abs(InletHumRat - OutletHumRat) * thisCTMFL) / RhoWater
                coolTower.CoolTWaterStarvMakeupRate = 0.0
                coolTower.PumpElecPower = coolTower.RatedPumpPower * PumpPartLoadRat
            else:
                coolTower.SenHeatPower = 0.0
                coolTower.LatHeatPower = 0.0
                coolTower.OutletTemp = 0.0
                coolTower.OutletHumRat = 0.0
                coolTower.AirVolFlowRate = 0.0
                coolTower.AirMassFlowRate = 0.0
                coolTower.AirVolFlowRateStd = 0.0
                coolTower.InletDBTemp = 0.0
                coolTower.InletHumRat = 0.0
                coolTower.PumpElecPower = 0.0
                coolTower.CoolTWaterConsumpRate = 0.0
                coolTower.CoolTWaterStarvMakeupRate = 0.0
    def UpdateCoolTower(state: Pointer[EnergyPlusData]):
        for CoolTowerNum in range(len(state[].dataCoolTower.CoolTowerSys)):
            var coolTower = state[].dataCoolTower.CoolTowerSys[CoolTowerNum]
            if coolTower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
                state[].dataWaterData.WaterStorage[coolTower.CoolTWaterSupTankID - 1].VdotRequestDemand[coolTower.CoolTWaterTankDemandARRID - 1] = coolTower.CoolTWaterConsumpRate
            if coolTower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
                var AvailWaterRate: Float64 = state[].dataWaterData.WaterStorage[coolTower.CoolTWaterSupTankID - 1].VdotAvailDemand[coolTower.CoolTWaterTankDemandARRID - 1]
                if AvailWaterRate < coolTower.CoolTWaterConsumpRate:
                    coolTower.CoolTWaterStarvMakeupRate = coolTower.CoolTWaterConsumpRate - AvailWaterRate
                    coolTower.CoolTWaterConsumpRate = AvailWaterRate
    def ReportCoolTower(state: Pointer[EnergyPlusData]):
        let TSMult: Float64 = state[].dataHVACGlobal.TimeStepSysSec
        for CoolTowerNum in range(len(state[].dataCoolTower.CoolTowerSys)):
            var coolTower = state[].dataCoolTower.CoolTowerSys[CoolTowerNum]
            coolTower.CoolTAirVol = coolTower.AirVolFlowRate * TSMult
            coolTower.CoolTAirMass = coolTower.AirMassFlowRate * TSMult
            coolTower.SenHeatLoss = coolTower.SenHeatPower * TSMult
            coolTower.LatHeatLoss = coolTower.LatHeatPower * TSMult
            coolTower.PumpElecConsump = coolTower.PumpElecPower * TSMult
            coolTower.CoolTWaterConsump = coolTower.CoolTWaterConsumpRate * TSMult
            coolTower.CoolTWaterStarvMakeup = coolTower.CoolTWaterStarvMakeupRate * TSMult
struct CoolTowerData(BaseGlobalStruct):
    var GetInputFlag: Bool = True
    var CoolTowerSys: List[CoolTowerParams] = List[CoolTowerParams]()
    def init_constant_state(inout self, state: Pointer[EnergyPlusData]):

    def init_state(inout self, state: Pointer[EnergyPlusData]):

    def clear_state(inout self):
        self = CoolTowerData()