from memory import UnsafePointer
from collections import List
from math import max


struct CoilCoolingDXCurveFitPerformanceInputSpecification:
    var name: String
    var crankcase_heater_capacity: Float64
    var minimum_outdoor_dry_bulb_temperature_for_compressor_operation: Float64
    var maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation: Float64
    var unit_internal_static_air_pressure: Float64
    var basin_heater_capacity: Float64
    var basin_heater_setpoint_temperature: Float64
    var basin_heater_operating_schedule_name: String
    var compressor_fuel_type: String
    var base_operating_mode_name: String
    var alternate_operating_mode_name: String
    var alternate_operating_mode2_name: String
    var outdoor_temperature_dependent_crankcase_heater_capacity_curve_name: String
    var capacity_control: String

    fn __init__(inout self):
        self.name = ""
        self.crankcase_heater_capacity = 0.0
        self.minimum_outdoor_dry_bulb_temperature_for_compressor_operation = 0.0
        self.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation = 0.0
        self.unit_internal_static_air_pressure = 0.0
        self.basin_heater_capacity = 0.0
        self.basin_heater_setpoint_temperature = 0.0
        self.basin_heater_operating_schedule_name = ""
        self.compressor_fuel_type = ""
        self.base_operating_mode_name = ""
        self.alternate_operating_mode_name = ""
        self.alternate_operating_mode2_name = ""
        self.outdoor_temperature_dependent_crankcase_heater_capacity_curve_name = ""
        self.capacity_control = ""


struct CoilCoolingDXCurveFitPerformance:
    alias object_name = "Coil:Cooling:DX:CurveFit:Performance"

    var name: String
    var parentName: String
    var minOutdoorDrybulb: Float64
    var maxOutdoorDrybulbForBasin: Float64
    var crankcaseHeaterCap: Float64
    var capControlMethod: Int32
    var evapCondBasinHeatCap: Float64
    var evapCondBasinHeatSetpoint: Float64
    var evapCondBasinHeatSched: UnsafePointer[NoneType]
    var maxAvailCoilMode: Int32
    var compressorFuelType: Int32
    var crankcaseHeaterCapacityCurveIndex: Int32
    var recoveredEnergyRate: Float64
    var NormalSHR: Float64
    var OperatingMode: Int32
    var powerUse: Float64
    var RTF: Float64
    var wasteHeatRate: Float64
    var ModeRatio: Float64
    var crankcaseHeaterPower: Float64
    var crankcaseHeaterElectricityConsumption: Float64
    var basinHeaterPower: Float64
    var electricityConsumption: Float64
    var compressorFuelRate: Float64
    var compressorFuelConsumption: Float64
    var original_input_specs: CoilCoolingDXCurveFitPerformanceInputSpecification
    var normalMode: UnsafePointer[NoneType]
    var alternateMode: UnsafePointer[NoneType]
    var alternateMode2: UnsafePointer[NoneType]
    var myOneTimeAvailSchedInitFlag: Bool
    var myOneTimeMinOATFlag: Bool
    var mySizeFlag: Bool
    var oneTimeEIOHeaderWrite: Bool
    var coilCoolingDXAvailSched: UnsafePointer[NoneType]
    var standardRatingCoolingCapacity: Float64
    var standardRatingCoolingCapacity2023: Float64
    var standardRatingSEER: Float64
    var standardRatingSEER_Standard: Float64
    var standardRatingSEER2_User: Float64
    var standardRatingSEER2_Standard: Float64
    var standardRatingEER: Float64
    var standardRatingEER2: Float64
    var standardRatingIEER: Float64
    var standardRatingIEER2: Float64

    fn __init__(inout self):
        self.name = ""
        self.parentName = ""
        self.minOutdoorDrybulb = 0.0
        self.maxOutdoorDrybulbForBasin = 0.0
        self.crankcaseHeaterCap = 0.0
        self.capControlMethod = 0
        self.evapCondBasinHeatCap = 0.0
        self.evapCondBasinHeatSetpoint = 0.0
        self.evapCondBasinHeatSched = UnsafePointer[NoneType]()
        self.maxAvailCoilMode = 0
        self.compressorFuelType = 0
        self.crankcaseHeaterCapacityCurveIndex = 0
        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0
        self.OperatingMode = 0
        self.powerUse = 0.0
        self.RTF = 0.0
        self.wasteHeatRate = 0.0
        self.ModeRatio = 0.0
        self.crankcaseHeaterPower = 0.0
        self.crankcaseHeaterElectricityConsumption = 0.0
        self.basinHeaterPower = 0.0
        self.electricityConsumption = 0.0
        self.compressorFuelRate = 0.0
        self.compressorFuelConsumption = 0.0
        self.original_input_specs = CoilCoolingDXCurveFitPerformanceInputSpecification()
        self.normalMode = UnsafePointer[NoneType]()
        self.alternateMode = UnsafePointer[NoneType]()
        self.alternateMode2 = UnsafePointer[NoneType]()
        self.myOneTimeAvailSchedInitFlag = True
        self.myOneTimeMinOATFlag = True
        self.mySizeFlag = True
        self.oneTimeEIOHeaderWrite = True
        self.coilCoolingDXAvailSched = UnsafePointer[NoneType]()
        self.standardRatingCoolingCapacity = 0.0
        self.standardRatingCoolingCapacity2023 = 0.0
        self.standardRatingSEER = 0.0
        self.standardRatingSEER_Standard = 0.0
        self.standardRatingSEER2_User = 0.0
        self.standardRatingSEER2_Standard = 0.0
        self.standardRatingEER = 0.0
        self.standardRatingEER2 = 0.0
        self.standardRatingIEER = 0.0
        self.standardRatingIEER2 = 0.0

    fn instantiateFromInputSpec(inout self, state: UnsafePointer[NoneType], input_data: CoilCoolingDXCurveFitPerformanceInputSpecification) -> None:
        let routine_name = "CoilCoolingDXCurveFitPerformance::instantiateFromInputSpec: "
        var errors_found = False
        
        self.original_input_specs = input_data
        self.name = input_data.name
        self.minOutdoorDrybulb = input_data.minimum_outdoor_dry_bulb_temperature_for_compressor_operation
        self.maxOutdoorDrybulbForBasin = input_data.maximum_outdoor_dry_bulb_temperature_for_crankcase_heater_operation
        self.crankcaseHeaterCap = input_data.crankcase_heater_capacity

    fn simulate(inout self, state: UnsafePointer[NoneType], inletNode: UnsafePointer[NoneType], 
                outletNode: UnsafePointer[NoneType], currentCoilMode: Int32, speedNum: Int32, 
                speedRatio: Float64, fanOp: Int32, condInletNode: UnsafePointer[NoneType],
                condOutletNode: UnsafePointer[NoneType], singleMode: Bool, LoadSHR: Float64 = 0.0) -> None:
        var total_cooling_rate = 0.0
        var sens_nor_rate = 0.0
        var sens_sub_rate = 0.0
        var sens_reh_rate = 0.0
        var lat_rate = 0.0
        var sys_nor_shr = 0.0
        var sys_sub_shr = 0.0
        var sys_reh_shr = 0.0
        var hum_rat_nor_out = 0.0
        var temp_nor_out = 0.0
        var enthalpy_nor_out = 0.0
        var mode_ratio = 0.0

        self.recoveredEnergyRate = 0.0
        self.NormalSHR = 0.0

    fn size(inout self, state: UnsafePointer[NoneType]) -> None:
        pass

    fn calculate(inout self, state: UnsafePointer[NoneType], currentMode: UnsafePointer[NoneType],
                 inletNode: UnsafePointer[NoneType], outletNode: UnsafePointer[NoneType],
                 speedNum: Int32, speedRatio: Float64, fanOp: Int32,
                 condInletNode: UnsafePointer[NoneType], condOutletNode: UnsafePointer[NoneType],
                 singleMode: Bool) -> None:
        pass

    fn calcStandardRatings210240(inout self, state: UnsafePointer[NoneType]) -> None:
        let num_of_reduced_cap = 4
        var tot_cap_flow_mod_fac = 0.0
        var eir_flow_mod_fac = 0.0
        var tot_cap_temp_mod_fac = 0.0
        var eir_temp_mod_fac = 0.0
        var tot_cooling_cap_ahri = 0.0
        var net_cooling_cap_ahri = 0.0
        var net_cooling_cap_ahri2023 = 0.0
        var total_elec_power = 0.0
        var total_elec_power2023 = 0.0
        var total_elec_power_rated = 0.0
        var total_elec_power_rated2023 = 0.0
        var eir = 0.0
        var part_load_factor = 0.0
        var eer_reduced = 0.0
        var elec_power_reduced_cap = 0.0
        var net_cooling_cap_reduced = 0.0
        var load_factor = 0.0
        var degradation_coeff = 0.0
        var outdoor_unit_inlet_air_dry_bulb_temp_reduced = 0.0

        let default_fan_power_per_evap_air_flow_rate = 773.3
        let default_fan_power_per_evap_air_flow_rate2023 = 934.4
        let cooling_coil_inlet_air_wet_bulb_temp_rated = 19.44
        let outdoor_unit_inlet_air_dry_bulb_temp = 27.78
        let outdoor_unit_inlet_air_dry_bulb_temp_rated = 35.0
        let air_mass_flow_ratio_rated = 1.0
        let plr_for_seer = 0.5
        let oa_db_temp_low_reduced_capacity_test = 18.3
        let cyclic_degradation_coefficient = 0.20

    fn setOperMode(inout self, state: UnsafePointer[NoneType], currentMode: UnsafePointer[NoneType], mode: Int32) -> None:
        var errors_found = False
        pass

    fn oneTimeAvailSchedSetup(inout self) -> None:
        if self.myOneTimeAvailSchedInitFlag:
            self.myOneTimeAvailSchedInitFlag = False

    fn oneTimeMinOATSetup(inout self) -> None:
        if self.myOneTimeMinOATFlag:
            self.myOneTimeMinOATFlag = False

    fn ratedCBF(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0

    fn grossRatedSHR(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0

    fn grossRatedCoolingCOPAtMaxSpeed(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0

    fn nameAtSpeed(self, speed: Int32) -> String:
        return ""

    fn ratedAirMassFlowRateMaxSpeed(self, state: UnsafePointer[NoneType], mode: Int32) -> Float64:
        return 0.0

    fn ratedAirMassFlowRateMinSpeed(self, state: UnsafePointer[NoneType], mode: Int32) -> Float64:
        return 0.0

    fn ratedCondAirMassFlowRateNomSpeed(self, state: UnsafePointer[NoneType], mode: Int32) -> Float64:
        return 0.0

    fn ratedEvapAirMassFlowRate(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0

    fn ratedEvapAirFlowRate(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0

    fn ratedGrossTotalCap(self) -> Float64:
        return 0.0

    fn indexCapFT(self, mode: Int32) -> Int32:
        return 0

    fn subcoolReheatFlag(self) -> Bool:
        return (self.original_input_specs.base_operating_mode_name != "" and 
                self.original_input_specs.alternate_operating_mode_name != "" and
                self.original_input_specs.alternate_operating_mode2_name != "")

    fn numSpeeds(self) -> Int32:
        return 0

    fn setToHundredPercentDOAS(inout self) -> None:
        pass

    fn evapAirFlowRateAtSpeedIndex(self, state: UnsafePointer[NoneType], index: Int32) -> Float64:
        return 0.0

    fn ratedTotalCapacityAtSpeedIndex(self, state: UnsafePointer[NoneType], index: Int32) -> Float64:
        return 0.0

    fn currentEvapCondPumpPowerAtSpeed(self, state: UnsafePointer[NoneType], speed: Int32) -> Float64:
        return 0.0

    fn evapCondenserEffectivenessAtSpeedIndex(self, state: UnsafePointer[NoneType], index: Int32) -> Float64:
        return 0.0

    fn evapAirFlowFraction(self, state: UnsafePointer[NoneType]) -> Float64:
        return 0.0
