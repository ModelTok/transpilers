from math import sqrt, exp
from collections import InlineArray


alias FLOW_CTRL_INVALID: Int32 = -1
alias FLOW_CTRL_FLOW_SCHEDULE: Int32 = 0
alias FLOW_CTRL_WIND_DRIVEN: Int32 = 1
alias FLOW_CTRL_NUM: Int32 = 2

alias WATER_SUPPLY_MODE_INVALID: Int32 = -1
alias WATER_SUPPLY_MODE_FROM_MAINS: Int32 = 0
alias WATER_SUPPLY_MODE_FROM_TANK: Int32 = 1
alias WATER_SUPPLY_MODE_NUM: Int32 = 2

alias FLOW_CTRL_NAMES_UC: InlineArray[StringRef, 2] = InlineArray[StringRef, 2]("WATERFLOWSCHEDULE", "WINDDRIVENFLOW")


struct Schedule:
    fn getCurrentVal(self) -> Float64:
        return 0.0


struct CoolTowerParams:
    var Name: String
    var CompType: String
    var availSched: Optional[Pointer[Schedule]]
    var ZonePtr: Int32
    var spacePtr: Int32
    var pumpSched: Optional[Pointer[Schedule]]
    var FlowCtrlType: Int32
    var CoolTWaterSupplyMode: Int32
    var CoolTWaterSupplyName: String
    var CoolTWaterSupTankID: Int32
    var CoolTWaterTankDemandARRID: Int32
    var TowerHeight: Float64
    var OutletArea: Float64
    var OutletVelocity: Float64
    var MaxAirVolFlowRate: Float64
    var AirMassFlowRate: Float64
    var CoolTAirMass: Float64
    var MinZoneTemp: Float64
    var FracWaterLoss: Float64
    var FracFlowSched: Float64
    var MaxWaterFlowRate: Float64
    var ActualWaterFlowRate: Float64
    var RatedPumpPower: Float64
    var SenHeatLoss: Float64
    var SenHeatPower: Float64
    var LatHeatLoss: Float64
    var LatHeatPower: Float64
    var AirVolFlowRate: Float64
    var AirVolFlowRateStd: Float64
    var CoolTAirVol: Float64
    var ActualAirVolFlowRate: Float64
    var InletDBTemp: Float64
    var InletWBTemp: Float64
    var InletHumRat: Float64
    var OutletTemp: Float64
    var OutletHumRat: Float64
    var CoolTWaterConsumpRate: Float64
    var CoolTWaterStarvMakeupRate: Float64
    var CoolTWaterStarvMakeup: Float64
    var CoolTWaterConsump: Float64
    var PumpElecPower: Float64
    var PumpElecConsump: Float64

    fn __init__(inout self):
        self.Name = ""
        self.CompType = ""
        self.availSched = None
        self.ZonePtr = 0
        self.spacePtr = 0
        self.pumpSched = None
        self.FlowCtrlType = FLOW_CTRL_INVALID
        self.CoolTWaterSupplyMode = WATER_SUPPLY_MODE_FROM_MAINS
        self.CoolTWaterSupplyName = ""
        self.CoolTWaterSupTankID = 0
        self.CoolTWaterTankDemandARRID = 0
        self.TowerHeight = 0.0
        self.OutletArea = 0.0
        self.OutletVelocity = 0.0
        self.MaxAirVolFlowRate = 0.0
        self.AirMassFlowRate = 0.0
        self.CoolTAirMass = 0.0
        self.MinZoneTemp = 0.0
        self.FracWaterLoss = 0.0
        self.FracFlowSched = 0.0
        self.MaxWaterFlowRate = 0.0
        self.ActualWaterFlowRate = 0.0
        self.RatedPumpPower = 0.0
        self.SenHeatLoss = 0.0
        self.SenHeatPower = 0.0
        self.LatHeatLoss = 0.0
        self.LatHeatPower = 0.0
        self.AirVolFlowRate = 0.0
        self.AirVolFlowRateStd = 0.0
        self.CoolTAirVol = 0.0
        self.ActualAirVolFlowRate = 0.0
        self.InletDBTemp = 0.0
        self.InletWBTemp = 0.0
        self.InletHumRat = 0.0
        self.OutletTemp = 0.0
        self.OutletHumRat = 0.0
        self.CoolTWaterConsumpRate = 0.0
        self.CoolTWaterStarvMakeupRate = 0.0
        self.CoolTWaterStarvMakeup = 0.0
        self.CoolTWaterConsump = 0.0
        self.PumpElecPower = 0.0
        self.PumpElecConsump = 0.0


struct CoolTowerData:
    var GetInputFlag: Bool
    var CoolTowerSys: List[CoolTowerParams]

    fn __init__(inout self):
        self.GetInputFlag = True
        self.CoolTowerSys = List[CoolTowerParams]()

    fn init_constant_state(self, inout state: Any) -> None:
        pass

    fn init_state(self, inout state: Any) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.GetInputFlag = True
        self.CoolTowerSys = List[CoolTowerParams]()


fn manage_cool_tower(inout state: Any) -> None:
    if state.dataCoolTower.GetInputFlag:
        get_cool_tower(state)
        state.dataCoolTower.GetInputFlag = False

    if len(state.dataCoolTower.CoolTowerSys) == 0:
        return

    calc_cool_tower(state)
    update_cool_tower(state)
    report_cool_tower(state)


fn get_cool_tower(inout state: Any) -> None:
    let routine_name = "GetCoolTower"
    let current_module_object = "ZoneCoolTower:Shower"
    let maximum_water_flow_rate: Float64 = 0.016667
    let minimum_water_flow_rate: Float64 = 0.0
    let max_height: Float64 = 30.0
    let min_height: Float64 = 1.0
    let max_value: Float64 = 100.0
    let min_value: Float64 = 0.0
    let max_frac: Float64 = 1.0
    let min_frac: Float64 = 0.0

    var errors_found: Bool = False
    let input_processor = state.dataInputProcessing.inputProcessor
    let num_cool_towers = input_processor.getNumObjectsFound(state, current_module_object)

    state.dataCoolTower.CoolTowerSys.reserve(num_cool_towers)
    for i in range(num_cool_towers):
        state.dataCoolTower.CoolTowerSys.append(CoolTowerParams())

    let object_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
    let cool_tower_objects = input_processor.epJSON.get(current_module_object, {})

    var cool_tower_num: Int32 = 0
    for cool_tower_key in cool_tower_objects.keys():
        let cool_tower_fields = cool_tower_objects[cool_tower_key]
        let cool_tower_name = util_make_upper(cool_tower_key)
        let availability_schedule_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "availability_schedule_name")
        let zone_or_space_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "zone_or_space_name")
        let water_supply_storage_tank_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "water_supply_storage_tank_name")
        let flow_control_type = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "flow_control_type")
        let pump_flow_rate_schedule_name = input_processor.getAlphaFieldValue(cool_tower_fields, object_schema_props, "pump_flow_rate_schedule_name")

        input_processor.markObjectAsUsed(current_module_object, cool_tower_key)

        var cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

        cool_tower.Name = cool_tower_name
        if len(availability_schedule_name) == 0:
            cool_tower.availSched = sched_get_schedule_always_on(state)
        else:
            cool_tower.availSched = sched_get_schedule(state, availability_schedule_name)
            if cool_tower.availSched == None:
                show_severe_item_not_found(state, routine_name, current_module_object, cool_tower_name, "Availability Schedule Name", availability_schedule_name)
                errors_found = True

        if len(zone_or_space_name) == 0:
            show_severe_empty_field(state, routine_name, current_module_object, cool_tower_name, "Zone or Space Name")
            errors_found = True
        else:
            cool_tower.ZonePtr = util_find_item_in_list(zone_or_space_name, state.dataHeatBal.Zone)
            if cool_tower.ZonePtr == 0:
                cool_tower.spacePtr = util_find_item_in_list(zone_or_space_name, state.dataHeatBal.space)
            if cool_tower.ZonePtr == 0 and cool_tower.spacePtr == 0:
                show_severe_item_not_found(state, routine_name, current_module_object, cool_tower_name, "Zone or Space Name", zone_or_space_name)
                errors_found = True
            elif cool_tower.ZonePtr == 0:
                cool_tower.ZonePtr = state.dataHeatBal.space[cool_tower.spacePtr - 1].zoneNum

        cool_tower.CoolTWaterSupplyName = water_supply_storage_tank_name
        if len(water_supply_storage_tank_name) == 0:
            cool_tower.CoolTWaterSupplyMode = WATER_SUPPLY_MODE_FROM_MAINS
        elif cool_tower.CoolTWaterSupplyMode == WATER_SUPPLY_MODE_FROM_TANK:
            water_manager_setup_tank_demand_component(state,
                                                      cool_tower.Name,
                                                      current_module_object,
                                                      cool_tower.CoolTWaterSupplyName,
                                                      errors_found,
                                                      cool_tower.CoolTWaterSupTankID,
                                                      cool_tower.CoolTWaterTankDemandARRID)

        cool_tower.FlowCtrlType = util_get_enum_value(flow_control_type)
        if cool_tower.FlowCtrlType == FLOW_CTRL_INVALID:
            show_severe_invalid_key(state, routine_name, current_module_object, cool_tower_name, "Flow Control Type", flow_control_type)
            errors_found = True

        cool_tower.pumpSched = sched_get_schedule(state, pump_flow_rate_schedule_name)
        if cool_tower.pumpSched == None:
            show_severe_item_not_found(state, routine_name, current_module_object, cool_tower_name, "Pump Flow Rate Schedule Name", pump_flow_rate_schedule_name)
            errors_found = True

        cool_tower.MaxWaterFlowRate = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "maximum_water_flow_rate")
        if cool_tower.MaxWaterFlowRate > maximum_water_flow_rate:
            cool_tower.MaxWaterFlowRate = maximum_water_flow_rate
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Maximum Water Flow Rate", cool_tower.MaxWaterFlowRate, maximum_water_flow_rate)
        if cool_tower.MaxWaterFlowRate < minimum_water_flow_rate:
            cool_tower.MaxWaterFlowRate = minimum_water_flow_rate
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Maximum Water Flow Rate", cool_tower.MaxWaterFlowRate, minimum_water_flow_rate)

        cool_tower.TowerHeight = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "effective_tower_height")
        if cool_tower.TowerHeight > max_height:
            cool_tower.TowerHeight = max_height
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Effective Tower Height", cool_tower.TowerHeight, max_height)
        if cool_tower.TowerHeight < min_height:
            cool_tower.TowerHeight = min_height
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Effective Tower Height", cool_tower.TowerHeight, min_height)

        cool_tower.OutletArea = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "airflow_outlet_area")
        if cool_tower.OutletArea > max_value:
            cool_tower.OutletArea = max_value
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Airflow Outlet Area", cool_tower.OutletArea, max_value)
        if cool_tower.OutletArea < min_value:
            cool_tower.OutletArea = min_value
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Airflow Outlet Area", cool_tower.OutletArea, min_value)

        cool_tower.MaxAirVolFlowRate = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "maximum_air_flow_rate")
        if cool_tower.MaxAirVolFlowRate > max_value:
            cool_tower.MaxAirVolFlowRate = max_value
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Maximum Air Flow Rate", cool_tower.MaxAirVolFlowRate, max_value)
        if cool_tower.MaxAirVolFlowRate < min_value:
            cool_tower.MaxAirVolFlowRate = min_value
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Maximum Air Flow Rate", cool_tower.MaxAirVolFlowRate, min_value)

        cool_tower.MinZoneTemp = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "minimum_indoor_temperature")
        if cool_tower.MinZoneTemp > max_value:
            cool_tower.MinZoneTemp = max_value
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Minimum Indoor Temperature", cool_tower.MinZoneTemp, max_value)
        if cool_tower.MinZoneTemp < min_value:
            cool_tower.MinZoneTemp = min_value
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Minimum Indoor Temperature", cool_tower.MinZoneTemp, min_value)

        cool_tower.FracWaterLoss = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "fraction_of_water_loss")
        if cool_tower.FracWaterLoss > max_frac:
            cool_tower.FracWaterLoss = max_frac
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Fraction of Water Loss", cool_tower.FracWaterLoss, max_frac)
        if cool_tower.FracWaterLoss < min_frac:
            cool_tower.FracWaterLoss = min_frac
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Fraction of Water Loss", cool_tower.FracWaterLoss, min_frac)

        cool_tower.FracFlowSched = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "fraction_of_flow_schedule")
        if cool_tower.FracFlowSched > max_frac:
            cool_tower.FracFlowSched = max_frac
            show_warning_bad_max(state, routine_name, current_module_object, cool_tower_name, "Fraction of Flow Schedule", cool_tower.FracFlowSched, max_frac)
        if cool_tower.FracFlowSched < min_frac:
            cool_tower.FracFlowSched = min_frac
            show_warning_bad_min(state, routine_name, current_module_object, cool_tower_name, "Fraction of Flow Schedule", cool_tower.FracFlowSched, min_frac)

        cool_tower.RatedPumpPower = input_processor.getRealFieldValue(cool_tower_fields, object_schema_props, "rated_power_consumption")
        cool_tower_num += 1

    if errors_found:
        show_fatal_error(state, current_module_object + " errors occurred in input.  Program terminates.")

    for cool_tower_num in range(num_cool_towers):
        var cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]
        var zone = state.dataHeatBal.Zone[cool_tower.ZonePtr - 1]

        setup_output_variable(state, "Zone Cooltower Sensible Heat Loss Energy", "J", cool_tower.SenHeatLoss, "System", "Sum", zone.Name)
        setup_output_variable(state, "Zone Cooltower Sensible Heat Loss Rate", "W", cool_tower.SenHeatPower, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Latent Heat Loss Energy", "J", cool_tower.LatHeatLoss, "System", "Sum", zone.Name)
        setup_output_variable(state, "Zone Cooltower Latent Heat Loss Rate", "W", cool_tower.LatHeatPower, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Volume", "m3", cool_tower.CoolTAirVol, "System", "Sum", zone.Name)
        setup_output_variable(state, "Zone Cooltower Current Density Air Volume Flow Rate", "m3/s", cool_tower.AirVolFlowRate, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Standard Density Air Volume Flow Rate", "m3/s", cool_tower.AirVolFlowRateStd, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Mass", "kg", cool_tower.CoolTAirMass, "System", "Sum", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Mass Flow Rate", "kg/s", cool_tower.AirMassFlowRate, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Inlet Temperature", "C", cool_tower.InletDBTemp, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Inlet Humidity Ratio", "kgWater/kgDryAir", cool_tower.InletHumRat, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Outlet Temperature", "C", cool_tower.OutletTemp, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Air Outlet Humidity Ratio", "kgWater/kgDryAir", cool_tower.OutletHumRat, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Pump Electricity Rate", "W", cool_tower.PumpElecPower, "System", "Average", zone.Name)
        setup_output_variable(state, "Zone Cooltower Pump Electricity Energy", "J", cool_tower.PumpElecConsump, "System", "Sum", zone.Name, "Electricity", "HVAC", "Cooling")

        if cool_tower.CoolTWaterSupplyMode == WATER_SUPPLY_MODE_FROM_MAINS:
            setup_output_variable(state, "Zone Cooltower Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            setup_output_variable(state, "Zone Cooltower Mains Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name, "MainsWater", "HVAC", "Cooling")
        elif cool_tower.CoolTWaterSupplyMode == WATER_SUPPLY_MODE_FROM_TANK:
            setup_output_variable(state, "Zone Cooltower Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            setup_output_variable(state, "Zone Cooltower Storage Tank Water Volume", "m3", cool_tower.CoolTWaterConsump, "System", "Sum", zone.Name)
            setup_output_variable(state, "Zone Cooltower Starved Mains Water Volume", "m3", cool_tower.CoolTWaterStarvMakeup, "System", "Sum", zone.Name, "MainsWater", "HVAC", "Cooling")


fn calc_cool_tower(inout state: Any) -> None:
    let min_wind_speed: Float64 = 0.1
    let max_wind_speed: Float64 = 30.0
    let uc_factor: Float64 = 60000.0

    var zone = state.dataHeatBal.Zone

    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        var cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]
        let zone_num = cool_tower.ZonePtr
        var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1]
        this_zone_hb.MCPTC = 0.0
        this_zone_hb.MCPC = 0.0
        this_zone_hb.CTMFL = 0.0

        if state.dataHeatBal.doSpaceHeatBalance and cool_tower.spacePtr > 0:
            var this_space_hb = state.dataZoneTempPredictorCorrector.spaceHeatBalance[cool_tower.spacePtr - 1]
            this_space_hb.MCPTC = 0.0
            this_space_hb.MCPC = 0.0
            this_space_hb.CTMFL = 0.0

        if cool_tower.availSched.getCurrentVal() > 0.0:
            if state.dataEnvrn.WindSpeed < min_wind_speed or state.dataEnvrn.WindSpeed > max_wind_speed:
                continue
            if state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num - 1].MAT < cool_tower.MinZoneTemp:
                continue

            var air_vol_flow_rate: Float64 = 0.0
            var water_flow_rate: Float64 = 0.0
            var outlet_temp: Float64 = 0.0

            if cool_tower.FlowCtrlType == FLOW_CTRL_WIND_DRIVEN:
                let height_sqrt = sqrt(cool_tower.TowerHeight)
                cool_tower.OutletVelocity = 0.7 * height_sqrt + 0.47 * (state.dataEnvrn.WindSpeed - 1.0)
                air_vol_flow_rate = cool_tower.OutletArea * cool_tower.OutletVelocity
                air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                water_flow_rate = air_vol_flow_rate / (0.0125 * height_sqrt)
                if water_flow_rate > cool_tower.MaxWaterFlowRate * uc_factor:
                    water_flow_rate = cool_tower.MaxWaterFlowRate * uc_factor
                    air_vol_flow_rate = 0.0125 * water_flow_rate * height_sqrt
                    air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                water_flow_rate = min(water_flow_rate, cool_tower.MaxWaterFlowRate * uc_factor)
                outlet_temp = state.dataEnvrn.OutDryBulbTemp - (state.dataEnvrn.OutDryBulbTemp - state.dataEnvrn.OutWetBulbTemp) * (1.0 - exp(-0.8 * cool_tower.TowerHeight)) * (1.0 - exp(-0.15 * water_flow_rate))
            elif cool_tower.FlowCtrlType == FLOW_CTRL_FLOW_SCHEDULE:
                water_flow_rate = cool_tower.MaxWaterFlowRate * uc_factor
                air_vol_flow_rate = 0.0125 * water_flow_rate * sqrt(cool_tower.TowerHeight)
                air_vol_flow_rate = min(air_vol_flow_rate, cool_tower.MaxAirVolFlowRate)
                outlet_temp = state.dataEnvrn.OutDryBulbTemp - (state.dataEnvrn.OutDryBulbTemp - state.dataEnvrn.OutWetBulbTemp) * (1.0 - exp(-0.8 * cool_tower.TowerHeight)) * (1.0 - exp(-0.15 * water_flow_rate))

            if outlet_temp < state.dataEnvrn.OutWetBulbTemp:
                show_severe_error(state, "Cooltower outlet temperature exceed the outdoor wet bulb temperature reset to input values")
                show_continue_error(state, "Occurs in Cooltower =" + cool_tower.Name)

            water_flow_rate /= uc_factor

            if cool_tower.FracWaterLoss > 0.0:
                cool_tower.ActualWaterFlowRate = water_flow_rate * (1.0 + cool_tower.FracWaterLoss)
            else:
                cool_tower.ActualWaterFlowRate = water_flow_rate

            if cool_tower.FracFlowSched > 0.0:
                cool_tower.ActualAirVolFlowRate = air_vol_flow_rate * (1.0 - cool_tower.FracFlowSched)
            else:
                cool_tower.ActualAirVolFlowRate = air_vol_flow_rate

            var pump_part_load_rat: Float64 = 1.0
            if cool_tower.pumpSched.getCurrentVal() > 0:
                pump_part_load_rat = cool_tower.pumpSched.getCurrentVal()
            else:
                pump_part_load_rat = 1.0

            let inlet_hum_rat = psychrometrics_psy_wfn_tdb_twb_pb(state, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutWetBulbTemp, state.dataEnvrn.OutBaroPress)
            let int_hum_rat = psychrometrics_psy_wfn_tdb_h(state, outlet_temp, state.dataEnvrn.OutEnthalpy)
            var air_density = psychrometrics_psy_rho_air_fn_pb_tdb_w(state, state.dataEnvrn.OutBaroPress, outlet_temp, int_hum_rat)
            let air_mass_flow_rate = air_density * cool_tower.ActualAirVolFlowRate
            let rho_water = psychrometrics_rho_h2_o(outlet_temp)
            let outlet_hum_rat = (inlet_hum_rat * (air_mass_flow_rate + (cool_tower.ActualWaterFlowRate * rho_water))) / air_mass_flow_rate
            let air_spec_heat = psychrometrics_psy_cp_air_fn_w(outlet_hum_rat)
            air_density = psychrometrics_psy_rho_air_fn_pb_tdb_w(state, state.dataEnvrn.OutBaroPress, outlet_temp, outlet_hum_rat)
            let cvf_zone_num = cool_tower.ActualAirVolFlowRate * cool_tower.availSched.getCurrentVal()
            let this_mcpc = cvf_zone_num * air_density * air_spec_heat
            let this_mcptc = this_mcpc * outlet_temp
            let this_ctmfl = this_mcpc / air_spec_heat
            var this_zt = this_zone_hb.ZT
            var this_air_hum_rat = this_zone_hb.airHumRat
            this_zone_hb.MCPC = this_mcpc
            this_zone_hb.MCPTC = this_mcptc
            this_zone_hb.CTMFL = this_ctmfl

            if state.dataHeatBal.doSpaceHeatBalance and cool_tower.spacePtr > 0:
                var this_space_hb = state.dataZoneTempPredictorCorrector.spaceHeatBalance[cool_tower.spacePtr - 1]
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


fn update_cool_tower(inout state: Any) -> None:
    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        var cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

        if cool_tower.CoolTWaterSupplyMode == WATER_SUPPLY_MODE_FROM_TANK:
            state.dataWaterData.WaterStorage[cool_tower.CoolTWaterSupTankID - 1].VdotRequestDemand[cool_tower.CoolTWaterTankDemandARRID - 1] = cool_tower.CoolTWaterConsumpRate

        if cool_tower.CoolTWaterSupplyMode == WATER_SUPPLY_MODE_FROM_TANK:
            let avail_water_rate = state.dataWaterData.WaterStorage[cool_tower.CoolTWaterSupTankID - 1].VdotAvailDemand[cool_tower.CoolTWaterTankDemandARRID - 1]
            if avail_water_rate < cool_tower.CoolTWaterConsumpRate:
                cool_tower.CoolTWaterStarvMakeupRate = cool_tower.CoolTWaterConsumpRate - avail_water_rate
                cool_tower.CoolTWaterConsumpRate = avail_water_rate


fn report_cool_tower(inout state: Any) -> None:
    let ts_mult = state.dataHVACGlobal.TimeStepSysSec

    for cool_tower_num in range(len(state.dataCoolTower.CoolTowerSys)):
        var cool_tower = state.dataCoolTower.CoolTowerSys[cool_tower_num]

        cool_tower.CoolTAirVol = cool_tower.AirVolFlowRate * ts_mult
        cool_tower.CoolTAirMass = cool_tower.AirMassFlowRate * ts_mult
        cool_tower.SenHeatLoss = cool_tower.SenHeatPower * ts_mult
        cool_tower.LatHeatLoss = cool_tower.LatHeatPower * ts_mult
        cool_tower.PumpElecConsump = cool_tower.PumpElecPower * ts_mult
        cool_tower.CoolTWaterConsump = cool_tower.CoolTWaterConsumpRate * ts_mult
        cool_tower.CoolTWaterStarvMakeup = cool_tower.CoolTWaterStarvMakeupRate * ts_mult


@always_inline
fn util_make_upper(s: String) -> String:
    return s.upper()


@always_inline
fn util_find_item_in_list(item: String, lst: List[Any]) -> Int32:
    for i in range(len(lst)):
        if lst[i] == item:
            return i + 1
    return 0


@always_inline
fn util_get_enum_value(value: String) -> Int32:
    let upper_value = value.upper()
    for i in range(len(FLOW_CTRL_NAMES_UC)):
        if upper_value == FLOW_CTRL_NAMES_UC[i]:
            return i
    return FLOW_CTRL_INVALID


fn sched_get_schedule_always_on(inout state: Any) -> Optional[Pointer[Schedule]]:
    return None


fn sched_get_schedule(inout state: Any, name: String) -> Optional[Pointer[Schedule]]:
    return None


fn psychrometrics_psy_wfn_tdb_twb_pb(inout state: Any, tdb: Float64, twb: Float64, pb: Float64) -> Float64:
    return 0.0


fn psychrometrics_psy_wfn_tdb_h(inout state: Any, tdb: Float64, h: Float64) -> Float64:
    return 0.0


fn psychrometrics_psy_rho_air_fn_pb_tdb_w(inout state: Any, pb: Float64, tdb: Float64, w: Float64) -> Float64:
    return 1.0


fn psychrometrics_rho_h2_o(temp: Float64) -> Float64:
    return 1000.0


fn psychrometrics_psy_cp_air_fn_w(w: Float64) -> Float64:
    return 1005.0


fn water_manager_setup_tank_demand_component(inout state: Any, name: String, obj_type: String, supply_name: String, inout errors_found: Bool, inout tank_id: Int32, inout demand_id: Int32) -> None:
    pass


fn show_severe_error(inout state: Any, msg: String) -> None:
    pass


fn show_continue_error(inout state: Any, msg: String) -> None:
    pass


fn show_severe_item_not_found(inout state: Any, routine_name: String, module_name: String, obj_name: String, field: String, value: String) -> None:
    pass


fn show_severe_empty_field(inout state: Any, routine_name: String, module_name: String, obj_name: String, field: String) -> None:
    pass


fn show_severe_invalid_key(inout state: Any, routine_name: String, module_name: String, obj_name: String, field: String, value: String) -> None:
    pass


fn show_warning_bad_max(inout state: Any, routine_name: String, module_name: String, obj_name: String, field: String, value: Float64, max_val: Float64) -> None:
    pass


fn show_warning_bad_min(inout state: Any, routine_name: String, module_name: String, obj_name: String, field: String, value: Float64, min_val: Float64) -> None:
    pass


fn show_fatal_error(inout state: Any, msg: String) -> None:
    pass


fn setup_output_variable(inout state: Any, var_name: String, units: String, var: Any, time_step: String, store_type: String, zone_name: String, resource: String = "", group: String = "", end_use: String = "") -> None:
    pass
