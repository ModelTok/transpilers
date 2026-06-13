from dataclasses import dataclass, field
from enum import IntEnum
from typing import Protocol, Optional, List, Any
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing dataCoolTower, dataHeatBal, dataZoneTempPredictorCorrector,
#                   dataEnvrn, dataHVACGlobal, dataWaterData, dataInputProcessing (from EnergyPlus)
# - Schedule: schedule object with getCurrentVal() method (from ScheduleManager)
# - Psychrometrics.PsyWFnTdbTwbPb, PsyWFnTdbH, PsyRhoAirFnPbTdbW, RhoH2O, PsyCpAirFnW
# - Util.makeUPPER, Util.FindItemInList (from UtilityRoutines)
# - ShowSevereError, ShowContinueError, ShowSevereItemNotFound, ShowSevereEmptyField,
#   ShowSevereInvalidKey, ShowWarningBadMax, ShowWarningBadMin, ShowFatalError (from UtilityRoutines)
# - WaterManager.SetupTankDemandComponent (from WaterManager)
# - SetupOutputVariable (from OutputProcessor)
# - Util.getEnumValue (from InputProcessor)


class Schedule(Protocol):
    def getCurrentVal(self) -> float: ...


class FlowCtrl(IntEnum):
    Invalid = -1
    FlowSchedule = 0
    WindDriven = 1
    Num = 2


class WaterSupplyMode(IntEnum):
    Invalid = -1
    FromMains = 0
    FromTank = 1
    Num = 2


@dataclass
class CoolTowerParams:
    Name: str = ""
    CompType: str = ""
    availSched: Optional[Schedule] = None
    ZonePtr: int = 0
    spacePtr: int = 0
    pumpSched: Optional[Schedule] = None
    FlowCtrlType: int = FlowCtrl.Invalid
    CoolTWaterSupplyMode: int = WaterSupplyMode.FromMains
    CoolTWaterSupplyName: str = ""
    CoolTWaterSupTankID: int = 0
    CoolTWaterTankDemandARRID: int = 0
    TowerHeight: float = 0.0
    OutletArea: float = 0.0
    OutletVelocity: float = 0.0
    MaxAirVolFlowRate: float = 0.0
    AirMassFlowRate: float = 0.0
    CoolTAirMass: float = 0.0
    MinZoneTemp: float = 0.0
    FracWaterLoss: float = 0.0
    FracFlowSched: float = 0.0
    MaxWaterFlowRate: float = 0.0
    ActualWaterFlowRate: float = 0.0
    RatedPumpPower: float = 0.0
    SenHeatLoss: float = 0.0
    SenHeatPower: float = 0.0
    LatHeatLoss: float = 0.0
    LatHeatPower: float = 0.0
    AirVolFlowRate: float = 0.0
    AirVolFlowRateStd: float = 0.0
    CoolTAirVol: float = 0.0
    ActualAirVolFlowRate: float = 0.0
    InletDBTemp: float = 0.0
    InletWBTemp: float = 0.0
    InletHumRat: float = 0.0
    OutletTemp: float = 0.0
    OutletHumRat: float = 0.0
    CoolTWaterConsumpRate: float = 0.0
    CoolTWaterStarvMakeupRate: float = 0.0
    CoolTWaterStarvMakeup: float = 0.0
    CoolTWaterConsump: float = 0.0
    PumpElecPower: float = 0.0
    PumpElecConsump: float = 0.0


@dataclass
class CoolTowerData:
    GetInputFlag: bool = True
    CoolTowerSys: List[CoolTowerParams] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.GetInputFlag = True
        self.CoolTowerSys = []


FLOW_CTRL_NAMES_UC = ["WATERFLOWSCHEDULE", "WINDDRIVENFLOW"]


def ManageCoolTower(state: Any) -> None:
    if state.dataCoolTower.GetInputFlag:
        GetCoolTower(state)
        state.dataCoolTower.GetInputFlag = False

    if len(state.dataCoolTower.CoolTowerSys) == 0:
        return

    CalcCoolTower(state)
    UpdateCoolTower(state)
    ReportCoolTower(state)


def GetCoolTower(state: Any) -> None:
    routine_name = "GetCoolTower"
    current_module_object = "ZoneCoolTower:Shower"
    maximum_water_flow_rate = 0.016667
    minimum_water_flow_rate = 0.0
    max_height = 30.0
    min_height = 1.0
    max_value = 100.0
    min_value = 0.0
    max_frac = 1.0
    min_frac = 0.0

    errors_found = False
    input_processor = state.dataInputProcessing.inputProcessor
    num_cool_towers = input_processor.getNumObjectsFound(state, current_module_object)

    state.dataCoolTower.CoolTowerSys = [CoolTowerParams() for _ in range(num_cool_towers)]

    object_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
    cool_tower_objects = input_processor.epJSON.get(current_module_object, {}).items()

    if cool_tower_objects:
        cool_tower_num = 0
        for cool_tower_key, cool_tower_fields in cool_tower_objects:
            cool_tower_name = Util.makeUPPER(cool_tower_key)
            availability_schedule_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "availability_schedule_name")
            zone_or_space_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "zone_or_space_name")
            water_supply_storage_tank_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "water_supply_storage_tank_name")
            flow_control_type = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "flow_control_type")
            pump_flow_rate_schedule_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "pump_flow_rate_schedule_name")

            input_processor.markObjectAsUsed(current_module_object, cool_tower_key)

            eoh = (routine_name, current_module_object, cool_tower_name)
            cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

            cool_tower.Name = cool_tower_name
            if not availability_schedule_name:
                cool_tower.availSched = Sched.GetScheduleAlwaysOn(state)
            else:
                cool_tower.availSched = Sched.GetSchedule(state, availability_schedule_name)
                if cool_tower.availSched is None:
                    ShowSevereItemNotFound(state, eoh, "Availability Schedule Name", availability_schedule_name)
                    errors_found = True

            if not zone_or_space_name:
                ShowSevereEmptyField(state, eoh, "Zone or Space Name")
                errors_found = True
            else:
                cool_tower.ZonePtr = Util.FindItemInList(zone_or_space_name, state.dataHeatBal.Zone)
                if cool_tower.ZonePtr == 0:
                    cool_tower.spacePtr = Util.FindItemInList(zone_or_space_name, state.dataHeatBal.space)
                if cool_tower.ZonePtr == 0 and cool_tower.spacePtr == 0:
                    ShowSevereItemNotFound(state, eoh, "Zone or Space Name", zone_or_space_name)
                    errors_found = True
                elif cool_tower.ZonePtr == 0:
                    cool_tower.ZonePtr = state.dataHeatBal.space[cool_tower.spacePtr - 1].zoneNum

            cool_tower.CoolTWaterSupplyName = water_supply_storage_tank_name
            if not water_supply_storage_tank_name:
                cool_tower.CoolTWaterSupplyMode = WaterSupplyMode.FromMains
            elif cool_tower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
                WaterManager.SetupTankDemandComponent(state,
                                                      cool_tower.Name,
                                                      current_module_object,
                                                      cool_tower.CoolTWaterSupplyName,
                                                      errors_found,
                                                      cool_tower.CoolTWaterSupTankID,
                                                      cool_tower.CoolTWaterTankDemandARRID)

            cool_tower.FlowCtrlType = Util.getEnumValue(FLOW_CTRL_NAMES_UC, flow_control_type)
            if cool_tower.FlowCtrlType == FlowCtrl.Invalid:
                ShowSevereInvalidKey(state, eoh, "Flow Control Type", flow_control_type)
                errors_found = True

            cool_tower.pumpSched = Sched.GetSchedule(state, pump_flow_rate_schedule_name)
            if cool_tower.pumpSched is None:
                ShowSevereItemNotFound(state, eoh, "Pump Flow Rate Schedule Name", pump_flow_rate_schedule_name)
                errors_found = True

            cool_tower.MaxWaterFlowRate = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "maximum_water_flow_rate")
            if cool_tower.MaxWaterFlowRate > maximum_water_flow_rate:
                cool_tower.MaxWaterFlowRate = maximum_water_flow_rate
                ShowWarningBadMax(state, eoh, "Maximum Water Flow Rate", cool_tower.MaxWaterFlowRate, maximum_water_flow_rate)
            if cool_tower.MaxWaterFlowRate < minimum_water_flow_rate:
                cool_tower.MaxWaterFlowRate = minimum_water_flow_rate
                ShowWarningBadMin(state, eoh, "Maximum Water Flow Rate", cool_tower.MaxWaterFlowRate, minimum_water_flow_rate)

            cool_tower.TowerHeight = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "effective_tower_height")
            if cool_tower.TowerHeight > max_height:
                cool_tower.TowerHeight = max_height
                ShowWarningBadMax(state, eoh, "Effective Tower Height", cool_tower.TowerHeight, max_height)
            if cool_tower.TowerHeight < min_height:
                cool_tower.TowerHeight = min_height
                ShowWarningBadMin(state, eoh, "Effective Tower Height", cool_tower.TowerHeight, min_height)

            cool_tower.OutletArea = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "airflow_outlet_area")
            if cool_tower.OutletArea > max_value:
                cool_tower.OutletArea = max_value
                ShowWarningBadMax(state, eoh, "Airflow Outlet Area", cool_tower.OutletArea, max_value)
            if cool_tower.OutletArea < min_value:
                cool_tower.OutletArea = min_value
                ShowWarningBadMin(state, eoh, "Airflow Outlet Area", cool_tower.OutletArea, min_value)

            cool_tower.MaxAirVolFlowRate = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "maximum_air_flow_rate")
            if cool_tower.MaxAirVolFlowRate > max_value:
                cool_tower.MaxAirVolFlowRate = max_value
                ShowWarningBadMax(state, eoh, "Maximum Air Flow Rate", cool_tower.MaxAirVolFlowRate, max_value)
            if cool_tower.MaxAirVolFlowRate < min_value:
                cool_tower.MaxAirVolFlowRate = min_value
                ShowWarningBadMin(state, eoh, "Maximum Air Flow Rate", cool_tower.MaxAirVolFlowRate, min_value)

            cool_tower.MinZoneTemp = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "minimum_indoor_temperature")
            if cool_tower.MinZoneTemp > max_value:
                cool_tower.MinZoneTemp = max_value
                ShowWarningBadMax(state, eoh, "Minimum Indoor Temperature", cool_tower.MinZoneTemp, max_value)
            if cool_tower.MinZoneTemp < min_value:
                cool_tower.MinZoneTemp = min_value
                ShowWarningBadMin(state, eoh, "Minimum Indoor Temperature", cool_tower.MinZoneTemp, min_value)

            cool_tower.FracWaterLoss = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "fraction_of_water_loss")
            if cool_tower.FracWaterLoss > max_frac:
                cool_tower.FracWaterLoss = max_frac
                ShowWarningBadMax(state, eoh, "Fraction of Water Loss", cool_tower.FracWaterLoss, max_frac)
            if cool_tower.FracWaterLoss < min_frac:
                cool_tower.FracWaterLoss = min_frac
                ShowWarningBadMin(state, eoh, "Fraction of Water Loss", cool_tower.FracWaterLoss, min_frac)

            cool_tower.FracFlowSched = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "fraction_of_flow_schedule")
            if cool_tower.FracFlowSched > max_frac:
                cool_tower.FracFlowSched = max_frac
                ShowWarningBadMax(state, eoh, "Fraction of Flow Schedule", cool_tower.FracFlowSched, max_frac)
            if cool_tower.FracFlowSched < min_frac:
                cool_tower.FracFlowSched = min_frac
                ShowWarningBadMin(state, eoh, "Fraction of Flow Schedule", cool_tower.FracFlowSched, min_frac)

            cool_tower.RatedPumpPower = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "rated_power_consumption")
            cool_tower_num += 1

    if errors_found:
        ShowFatalError(state, f"{current_module_object} errors occurred in input.  Program terminates.")

    for cool_tower_num in range(num_cool_towers):
        cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]
        zone = state.dataHeatBal.Zone[cool_tower.ZonePtr - 1]

        SetupOutputVariable(state, "Zone Cooltower Sensible Heat Loss Energy", "J", cool_tower.SenHeatLoss, "System", "Sum", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Sensible Heat Loss Rate", "W", cool_tower.SenHeatPower, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Latent Heat Loss Energy", "J", cool_tower.LatHeatLoss, "System", "Sum", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Latent Heat Loss Rate", "W", cool_tower.LatHeatPower, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Volume", "m3", cool_tower.CoolTAirVol, "System", "Sum", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Current Density Air Volume Flow Rate", "m3/s", cool_tower.AirVolFlowRate, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Standard Density Air Volume Flow Rate", "m3/s", cool_tower.AirVolFlowRateStd, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Mass", "kg", cool_tower.CoolTAirMass, "System", "Sum", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Mass Flow Rate", "kg/s", cool_tower.AirMassFlowRate, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Inlet Temperature", "C", cool_tower.InletDBTemp, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Inlet Humidity Ratio", "kgWater/kgDryAir", cool_tower.InletHumRat, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Outlet Temperature", "C", cool_tower.OutletTemp, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Air Outlet Humidity Ratio", "kgWater/kgDryAir", cool_tower.OutletHumRat, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Pump Electricity Rate", "W", cool_tower.PumpElecPower, "System", "Average", zone.Name)
        SetupOutputVariable(state, "Zone Cooltower Pump Electricity Energy", "J", cool_tower.PumpElecConsump, "System", "Sum", zone.Name, "Electricity", "HVAC", "Cooling")

        if cool_tower.CoolTWaterSupplyMode == WaterSupplyMode.FromMains:
            SetupOutputVariable(state, "Zone Cooltower Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Mains Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name, "MainsWater", "HVAC", "Cooling")
        elif cool_tower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
            SetupOutputVariable(state, "Zone Cooltower Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Storage Tank Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            SetupOutputVariable(state, "Zone Cooltower Starved Mains Water Volume", "m3", cool_tower.CoolTWaterStarvMakeup, "System", "Sum", zone.Name, "MainsWater", "HVAC", "Cooling")


def CalcCoolTower(state: Any) -> None:
    min_wind_speed = 0.1
    max_wind_speed = 30.0
    uc_factor = 60000.0

    zone = state.dataHeatBal.Zone

    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]
        zone_num = cool_tower.ZonePtr
        this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1]
        this_zone_hb.MCPTC = 0.0
        this_zone_hb.MCPC = 0.0
        this_zone_hb.CTMFL = 0.0

        if state.dataHeatBal.doSpaceHeatBalance and cool_tower.spacePtr > 0:
            this_space_hb = state.dataZoneTempPredictorCorrector.spaceHeatBalance[cool_tower.spacePtr - 1]
            this_space_hb.MCPTC = 0.0
            this_space_hb.MCPC = 0.0
            this_space_hb.CTMFL = 0.0

        if cool_tower.availSched.getCurrentVal() > 0.0:
            if state.dataEnvrn.WindSpeed < min_wind_speed or state.dataEnvrn.WindSpeed > max_wind_speed:
                continue
            if state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT < cool_tower.MinZoneTemp:
                continue

            if cool_tower.FlowCtrlType == FlowCtrl.WindDriven:
                height_sqrt = math.sqrt(cool_tower.TowerHeight)
                cool_tower.OutletVelocity = 0.7 * height_sqrt + 0.47 * (state.dataEnvrn.WindSpeed - 1.0)
                air_vol_flow_rate = cool_tower.OutletArea * cool_tower.OutletVelocity
                air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                water_flow_rate = air_vol_flow_rate / (0.0125 * height_sqrt)
                if water_flow_rate > cool_tower.MaxWaterFlowRate * uc_factor:
                    water_flow_rate = cool_tower.MaxWaterFlowRate * uc_factor
                    air_vol_flow_rate = 0.0125 * water_flow_rate * height_sqrt
                    air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                water_flow_rate = min(water_flow_rate, cool_tower.MaxWaterFlowRate * uc_factor)
                outlet_temp = state.dataEnvrn.OutDryBulbTemp - (state.dataEnvrn.OutDryBulbTemp - state.dataEnvrn.OutWetBulbTemp) * (1.0 - math.exp(-0.8 * cool_tower.TowerHeight)) * (1.0 - math.exp(-0.15 * water_flow_rate))
            elif cool_tower.FlowCtrlType == FlowCtrl.FlowSchedule:
                water_flow_rate = cool_tower.MaxWaterFlowRate * uc_factor
                air_vol_flow_rate = 0.0125 * water_flow_rate * math.sqrt(cool_tower.TowerHeight)
                air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                outlet_temp = state.dataEnvrn.OutDryBulbTemp - (state.dataEnvrn.OutDryBulbTemp - state.dataEnvrn.OutWetBulbTemp) * (1.0 - math.exp(-0.8 * cool_tower.TowerHeight)) * (1.0 - math.exp(-0.15 * water_flow_rate))
            else:
                water_flow_rate = 0.0
                air_vol_flow_rate = 0.0
                outlet_temp = 0.0

            if outlet_temp < state.dataEnvrn.OutWetBulbTemp:
                ShowSevereError(state, "Cooltower outlet temperature exceed the outdoor wet bulb temperature reset to input values")
                ShowContinueError(state, f"Occurs in Cooltower ={cool_tower.Name}")

            water_flow_rate /= uc_factor

            if cool_tower.FracWaterLoss > 0.0:
                cool_tower.ActualWaterFlowRate = water_flow_rate * (1.0 + cool_tower.FracWaterLoss)
            else:
                cool_tower.ActualWaterFlowRate = water_flow_rate

            if cool_tower.FracFlowSched > 0.0:
                cool_tower.ActualAirVolFlowRate = air_vol_flow_rate * (1.0 - cool_tower.FracFlowSched)
            else:
                cool_tower.ActualAirVolFlowRate = air_vol_flow_rate

            if cool_tower.pumpSched.getCurrentVal() > 0:
                pump_part_load_rat = cool_tower.pumpSched.getCurrentVal()
            else:
                pump_part_load_rat = 1.0

            inlet_hum_rat = Psychrometrics.PsyWFnTdbTwbPb(state, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutWetBulbTemp, state.dataEnvrn.OutBaroPress)
            int_hum_rat = Psychrometrics.PsyWFnTdbH(state, outlet_temp, state.dataEnvrn.OutEnthalpy)
            air_density = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, outlet_temp, int_hum_rat)
            air_mass_flow_rate = air_density * cool_tower.ActualAirVolFlowRate
            rho_water = Psychrometrics.RhoH2O(outlet_temp)
            outlet_hum_rat = (inlet_hum_rat * (air_mass_flow_rate + (cool_tower.ActualWaterFlowRate * rho_water))) / air_mass_flow_rate
            air_spec_heat = Psychrometrics.PsyCpAirFnW(outlet_hum_rat)
            air_density = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, outlet_temp, outlet_hum_rat)
            cvf_zone_num = cool_tower.ActualAirVolFlowRate * cool_tower.availSched.getCurrentVal()
            this_mcpc = cvf_zone_num * air_density * air_spec_heat
            this_mcptc = this_mcpc * outlet_temp
            this_ctmfl = this_mcpc / air_spec_heat
            this_zt = this_zone_hb.ZT
            this_air_hum_rat = this_zone_hb.airHumRat
            this_zone_hb.MCPC = this_mcpc
            this_zone_hb.MCPTC = this_mcptc
            this_zone_hb.CTMFL = this_ctmfl

            if state.dataHeatBal.doSpaceHeatBalance and cool_tower.spacePtr > 0:
                this_space_hb = state.dataZoneTempPredictorCorrector.spaceHeatBalance[cool_tower.spacePtr - 1]
                this_space_hb.MCPC = this_mcpc
                this_space_hb.MCPTC = this_mcptc
                this_space_hb.CTMFL = this_ctmfl
                this_zt = this_space_hb.ZT
                this_air_hum_rat = this_space_hb.airHumRat

            cool_tower.SenHeatPower = this_mcpc * abs(this_zt - outlet_temp)
            cool_tower.LatHeatPower = cvf_zone_num * abs(this_air_hum_rat - outlet_hum_rat)
            cool_tower.OutletTemp = outlet_temp
            cool_tower.OutletHumRat = outlet_hum_rat
            cool_tower.AirVolFlowRate = cvf_zone_num
            cool_tower.AirMassFlowRate = this_ctmfl
            cool_tower.AirVolFlowRateStd = this_ctmfl / state.dataEnvrn.StdRhoAir
            cool_tower.InletDBTemp = zone[zone_num - 1].OutDryBulbTemp
            cool_tower.InletWBTemp = zone[zone_num - 1].OutWetBulbTemp
            cool_tower.InletHumRat = state.dataEnvrn.OutHumRat
            cool_tower.CoolTWaterConsumpRate = (abs(inlet_hum_rat - outlet_hum_rat) * this_ctmfl) / rho_water
            cool_tower.CoolTWaterStarvMakeupRate = 0.0
            cool_tower.PumpElecPower = cool_tower.RatedPumpPower * pump_part_load_rat
        else:
            cool_tower.SenHeatPower = 0.0
            cool_tower.LatHeatPower = 0.0
            cool_tower.OutletTemp = 0.0
            cool_tower.OutletHumRat = 0.0
            cool_tower.AirVolFlowRate = 0.0
            cool_tower.AirMassFlowRate = 0.0
            cool_tower.AirVolFlowRateStd = 0.0
            cool_tower.InletDBTemp = 0.0
            cool_tower.InletHumRat = 0.0
            cool_tower.PumpElecPower = 0.0
            cool_tower.CoolTWaterConsumpRate = 0.0
            cool_tower.CoolTWaterStarvMakeupRate = 0.0


def UpdateCoolTower(state: Any) -> None:
    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

        if cool_tower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
            state.dataWaterData.WaterStorage[cool_tower.CoolTWaterSupTankID - 1].VdotRequestDemand[cool_tower.CoolTWaterTankDemandARRID - 1] = cool_tower.CoolTWaterConsumpRate

        if cool_tower.CoolTWaterSupplyMode == WaterSupplyMode.FromTank:
            avail_water_rate = state.dataWaterData.WaterStorage[cool_tower.CoolTWaterSupTankID - 1].VdotAvailDemand[cool_tower.CoolTWaterTankDemandARRID - 1]
            if avail_water_rate < cool_tower.CoolTWaterConsumpRate:
                cool_tower.CoolTWaterStarvMakeupRate = cool_tower.CoolTWaterConsumpRate - avail_water_rate
                cool_tower.CoolTWaterConsumpRate = avail_water_rate


def ReportCoolTower(state: Any) -> None:
    ts_mult = state.dataHVACGlobal.TimeStepSysSec

    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

        cool_tower.CoolTAirVol = cool_tower.AirVolFlowRate * ts_mult
        cool_tower.CoolTAirMass = cool_tower.AirMassFlowRate * ts_mult
        cool_tower.SenHeatLoss = cool_tower.SenHeatPower * ts_mult
        cool_tower.LatHeatLoss = cool_tower.LatHeatPower * ts_mult
        cool_tower.PumpElecConsump = cool_tower.PumpElecPower * ts_mult
        cool_tower.CoolTWaterConsump = cool_tower.CoolTWaterConsumpRate * ts_mult
        cool_tower.CoolTWaterStarvMakeup = cool_tower.CoolTWaterStarvMakeupRate * ts_mult


# Stub external modules and functions (to be wired in at runtime)
class Util:
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()

    @staticmethod
    def FindItemInList(item: str, lst: List[Any]) -> int:
        try:
            return lst.index(item) + 1
        except ValueError:
            return 0

    @staticmethod
    def getEnumValue(names: List[str], value: str) -> int:
        try:
            return names.index(value.upper())
        except ValueError:
            return FlowCtrl.Invalid


class Sched:
    @staticmethod
    def GetScheduleAlwaysOn(state: Any) -> Optional[Schedule]:
        return None

    @staticmethod
    def GetSchedule(state: Any, name: str) -> Optional[Schedule]:
        return None


class Psychrometrics:
    @staticmethod
    def PsyWFnTdbTwbPb(state: Any, tdb: float, twb: float, pb: float) -> float:
        return 0.0

    @staticmethod
    def PsyWFnTdbH(state: Any, tdb: float, h: float) -> float:
        return 0.0

    @staticmethod
    def PsyRhoAirFnPbTdbW(state: Any, pb: float, tdb: float, w: float) -> float:
        return 1.0

    @staticmethod
    def RhoH2O(temp: float) -> float:
        return 1000.0

    @staticmethod
    def PsyCpAirFnW(w: float) -> float:
        return 1005.0


class WaterManager:
    @staticmethod
    def SetupTankDemandComponent(state: Any, name: str, obj_type: str, supply_name: str, errors_found: bool, tank_id: int, demand_id: int) -> None:
        pass


def ShowSevereError(state: Any, msg: str) -> None:
    pass


def ShowContinueError(state: Any, msg: str) -> None:
    pass


def ShowSevereItemNotFound(state: Any, eoh: tuple, field: str, value: str) -> None:
    pass


def ShowSevereEmptyField(state: Any, eoh: tuple, field: str) -> None:
    pass


def ShowSevereInvalidKey(state: Any, eoh: tuple, field: str, value: str) -> None:
    pass


def ShowWarningBadMax(state: Any, eoh: tuple, field: str, value: float, max_val: float) -> None:
    pass


def ShowWarningBadMin(state: Any, eoh: tuple, field: str, value: float, min_val: float) -> None:
    pass


def ShowFatalError(state: Any, msg: str) -> None:
    pass


def SetupOutputVariable(state: Any, var_name: str, units: str, var: Any, time_step: str, store_type: str, zone_name: str, resource: str = None, group: str = None, end_use: str = None) -> None:
    pass
