# lib_geothermal_test.mojo
# Translated from C++ header and source

from memory import malloc, free, UnsafePointer
from math import fabs

# Import required modules (assuming they exist at same relative paths)
from lib_geothermal import CGeothermalAnalyzer, SGeothermal_Inputs, SGeothermal_Outputs, \
    POWER_SALES, NUMBER_OF_WELLS, BINARY, FLASH, \
    SINGLE_FLASH_NO_TEMP_CONSTRAINT, SINGLE_FLASH_WITH_TEMP_CONSTRAINT, \
    DUAL_FLASH_NO_TEMP_CONSTRAINT, DUAL_FLASH_WITH_TEMP_CONSTRAINT, \
    ENTER_RATE, CALCULATE_RATE, HYDROTHERMAL, EGS, TEMPERATURE, \
    ENTER_PC, SIMPLE_FRACTURE, K_AREA, \
    SPowerBlockParameters, SPowerBlockInputs
from core import compute_module
from lib_physics import physics
from ...input_cases.geothermal_common_data import geothermal_weather_path

# Static function from header
def my_update_function(percent: Float64, data: Any) -> Bool:
    if data != None:
        return ((compute_module)data).update("working...", percent)
    else:
        return True

# Simple test helpers (replace gtest macros)
def expect_near(actual: Float64, expected: Float64, tolerance: Float64):
    assert fabs(actual - expected) <= tolerance, \
        "FAIL: expected " + str(expected) + " +/- " + str(tolerance) + ", got " + str(actual)

def expect_eq(actual: Int32, expected: Int32):
    assert actual == expected, "FAIL: expected " + str(expected) + ", got " + str(actual)

struct GeothermalPlantAnalyzer:
    var well_flow_rate: Int32
    var num_wells_getem: Float64
    var nameplate: Int32
    var analysis_type: Int32
    var conversion_type: Int32
    var conversion_subtype: Int32
    var plant_efficiency_input: Float64
    var decline_type: Int32
    var temp_decline_rate: Float64
    var temp_decline_max: Int32
    var wet_bulb_temp: Int32
    var ambient_pressure: Float64
    var pump_efficiency: Float64
    var delta_pressure_equip: Int32
    var excess_pressure_pump: Float64
    var well_diameter: Float64
    var casing_size: Float64
    var inj_well_diam: Float64
    var specify_pump_work: Int32
    var specified_pump_work_amount: Int32
    var resource_type: Int32
    var resource_depth: Int32
    var resource_temp: Int32
    var design_temp: Int32
    var rock_thermal_conductivity: Int32
    var rock_specific_heat: Int32
    var rock_density: Float64
    var reservoir_pressure_change: Float64
    var reservoir_width: Int32
    var reservoir_pressure_change_type: Int32
    var reservoir_height: Float64
    var reservoir_permeability: Float64
    var inj_prod_well_distance: Int32
    var subsurface_water_loss: Int32
    var fracture_aperature: Float64
    var num_fractures: Int32
    var fracture_width: Int32
    var fracture_angle: Int32
    var geothermal_analysis_period: Int32
    var resource_potential: Int32
    var tou: List[Int32]
    var SPBP: SPowerBlockParameters
    var PBInputs: SPowerBlockInputs
    var geoPlant_inputs: SGeothermal_Inputs
    var geoPlant_outputs: SGeothermal_Outputs
    var geoTester: CGeothermalAnalyzer

    def __init__(inout self):
        self.well_flow_rate = 110
        self.num_wells_getem = 3.0
        self.nameplate = 30000
        self.analysis_type = 0
        self.resource_temp = 200
        self.design_temp = 200
        self.conversion_subtype = 3
        self.plant_efficiency_input = 61.109
        self.decline_type = 0
        self.temp_decline_rate = 0.3
        self.temp_decline_max = 30
        self.wet_bulb_temp = 15
        self.ambient_pressure = 14.7
        self.pump_efficiency = 67.5
        self.delta_pressure_equip = 25
        self.excess_pressure_pump = 50.0
        self.well_diameter = 12.25
        self.casing_size = 9.625
        self.inj_well_diam = 12.25
        self.specify_pump_work = 0
        self.specified_pump_work_amount = 0
        self.resource_type = 0
        self.resource_depth = 2000
        self.rock_thermal_conductivity = 259200
        self.rock_specific_heat = 950
        self.rock_density = 2600.0
        self.reservoir_pressure_change = 0.35
        self.reservoir_width = 500
        self.reservoir_pressure_change_type = 0
        self.reservoir_height = 100.0
        self.reservoir_permeability = 0.05
        self.inj_prod_well_distance = 1500
        self.subsurface_water_loss = 2
        self.fracture_aperature = 0.0004
        self.num_fractures = 6
        self.fracture_width = 175
        self.fracture_angle = 15
        self.geothermal_analysis_period = 30
        self.resource_potential = 210
        # Initialize arrays (tou[8760])
        self.tou = List[Int32](capacity=8760)
        for i in range(8760):
            self.tou.append(0)
        # Initialize nested structs
        self.SPBP = SPowerBlockParameters()
        self.PBInputs = SPowerBlockInputs()
        self.geoPlant_inputs = SGeothermal_Inputs()
        self.geoPlant_outputs = SGeothermal_Outputs()
        # Placeholder for geoPlant_outputs pointers (we'll use lists for dynamic arrays)
        self.geoPlant_outputs.maf_ReplacementsByYear = List[Float64]()
        self.geoPlant_outputs.maf_monthly_resource_temp = List[Float64]()
        self.geoPlant_outputs.maf_monthly_power = List[Float64]()
        self.geoPlant_outputs.maf_monthly_energy = List[Float64]()
        self.geoPlant_outputs.maf_timestep_resource_temp = List[Float64]()
        self.geoPlant_outputs.maf_timestep_power = List[Float64]()
        self.geoPlant_outputs.maf_timestep_test_values = List[Float64]()
        self.geoPlant_outputs.maf_timestep_pressure = List[Float64]()
        self.geoPlant_outputs.maf_timestep_dry_bulb = List[Float64]()
        self.geoPlant_outputs.maf_timestep_wet_bulb = List[Float64]()
        self.geoPlant_outputs.maf_hourly_power = List[Float64]()
        self.geoTester = CGeothermalAnalyzer()

    def SetUp(inout self):
        self.well_flow_rate = 110
        self.num_wells_getem = 3.0
        self.nameplate = 30000
        self.analysis_type = 0
        self.resource_temp = 200
        self.design_temp = 200
        self.conversion_subtype = 3
        self.plant_efficiency_input = 61.109
        self.decline_type = 0
        self.temp_decline_rate = 0.3
        self.temp_decline_max = 30
        self.wet_bulb_temp = 15
        self.ambient_pressure = 14.7
        self.pump_efficiency = 67.5
        self.delta_pressure_equip = 25
        self.excess_pressure_pump = 50.0
        self.well_diameter = 12.25
        self.casing_size = 9.625
        self.inj_well_diam = 12.25
        self.specify_pump_work = 0
        self.specified_pump_work_amount = 0
        self.resource_type = 0
        self.resource_depth = 2000
        self.rock_thermal_conductivity = 259200
        self.rock_specific_heat = 950
        self.rock_density = 2600.0
        self.reservoir_pressure_change = 0.35
        self.reservoir_width = 500
        self.reservoir_pressure_change_type = 0
        self.reservoir_height = 100.0
        self.reservoir_permeability = 0.05
        self.inj_prod_well_distance = 1500
        self.subsurface_water_loss = 2
        self.fracture_aperature = 0.0004
        self.num_fractures = 6
        self.fracture_width = 175
        self.fracture_angle = 15
        self.geothermal_analysis_period = 30
        self.resource_potential = 210
        # SPBP initialization
        self.SPBP.tech_type = 4
        self.SPBP.T_htf_cold_ref = 90.0
        self.SPBP.T_htf_hot_ref = 175.0
        self.SPBP.HTF = 3
        self.SPBP.P_ref = self.nameplate / 1000.0
        self.SPBP.P_boil = 2
        self.SPBP.eta_ref = 0.17
        self.SPBP.q_sby_frac = 0.2
        self.SPBP.startup_frac = 0.2
        self.SPBP.startup_time = 1
        self.SPBP.pb_bd_frac = 0.013
        self.SPBP.T_amb_des = 27
        self.SPBP.CT = 0
        self.SPBP.dT_cw_ref = 10
        self.SPBP.T_approach = 5
        self.SPBP.T_ITD_des = 16
        self.SPBP.P_cond_ratio = 1.0028
        self.SPBP.P_cond_min = 1.25
        self.SPBP.n_pl_inc = 8
        self.SPBP.F_wc[0] = 0.0
        self.SPBP.F_wc[1] = 0.0
        self.SPBP.F_wc[2] = 0.0
        self.SPBP.F_wc[3] = 0.0
        self.SPBP.F_wc[4] = 0.0
        self.SPBP.F_wc[5] = 0.0
        self.SPBP.F_wc[6] = 0.0
        self.SPBP.F_wc[7] = 0.0
        self.SPBP.F_wc[8] = 0.0
        # PBInputs
        self.PBInputs.mode = 2
        if True: # used number of wells as calculated by GETEM
            self.PBInputs.m_dot_htf = self.well_flow_rate * 3600.0 * self.num_wells_getem
        self.PBInputs.demand_var = self.PBInputs.m_dot_htf
        self.PBInputs.standby_control = 1
        self.PBInputs.rel_humidity = 0.7
        # geoPlant_inputs
        self.geoPlant_inputs.md_RatioInjectionToProduction = 0.5
        self.geoPlant_inputs.md_DesiredSalesCapacityKW = self.nameplate
        if self.analysis_type == 0:
            self.geoPlant_inputs.me_cb = POWER_SALES
        else:
            self.geoPlant_inputs.me_cb = NUMBER_OF_WELLS
        if self.conversion_type == 0:
            self.geoPlant_inputs.me_ct = BINARY
        elif self.conversion_type == 1:
            self.geoPlant_inputs.me_ct = FLASH
        # conversion_subtype switch
        if self.conversion_subtype == 0:
            self.geoPlant_inputs.me_ft = SINGLE_FLASH_NO_TEMP_CONSTRAINT
        elif self.conversion_subtype == 1:
            self.geoPlant_inputs.me_ft = SINGLE_FLASH_WITH_TEMP_CONSTRAINT
        elif self.conversion_subtype == 2:
            self.geoPlant_inputs.me_ft = DUAL_FLASH_NO_TEMP_CONSTRAINT
        elif self.conversion_subtype == 3:
            self.geoPlant_inputs.me_ft = DUAL_FLASH_WITH_TEMP_CONSTRAINT
        self.geoPlant_inputs.md_PlantEfficiency = self.plant_efficiency_input / 100.0
        if self.decline_type == 0:
            self.geoPlant_inputs.me_tdm = ENTER_RATE
        elif self.decline_type == 1:
            self.geoPlant_inputs.me_tdm = CALCULATE_RATE
        self.geoPlant_inputs.md_TemperatureDeclineRate = self.temp_decline_rate / 100.0
        self.geoPlant_inputs.md_MaxTempDeclineC = self.temp_decline_max
        self.geoPlant_inputs.md_TemperatureWetBulbC = self.wet_bulb_temp
        self.geoPlant_inputs.md_PressureAmbientPSI = self.ambient_pressure
        self.geoPlant_inputs.md_ProductionFlowRateKgPerS = self.well_flow_rate
        self.geoPlant_inputs.md_GFPumpEfficiency = self.pump_efficiency / 100.0
        self.geoPlant_inputs.md_PressureChangeAcrossSurfaceEquipmentPSI = self.delta_pressure_equip
        self.geoPlant_inputs.md_ExcessPressureBar = physics.PsiToBar(self.excess_pressure_pump)
        self.geoPlant_inputs.md_DiameterProductionWellInches = self.well_diameter
        self.geoPlant_inputs.md_DiameterPumpCasingInches = self.casing_size
        self.geoPlant_inputs.md_DiameterInjectionWellInches = self.inj_well_diam
        self.geoPlant_inputs.mb_CalculatePumpWork = (1 != self.specify_pump_work)
        self.geoPlant_inputs.md_UserSpecifiedPumpWorkKW = self.specified_pump_work_amount * 1000
        if self.resource_type == 0:
            self.geoPlant_inputs.me_rt = HYDROTHERMAL
        elif self.resource_type == 1:
            self.geoPlant_inputs.me_rt = EGS
        self.geoPlant_inputs.md_ResourceDepthM = self.resource_depth
        self.geoPlant_inputs.md_TemperatureResourceC = self.resource_temp
        self.geoPlant_inputs.me_dc = TEMPERATURE
        self.geoPlant_inputs.md_TemperaturePlantDesignC = self.design_temp
        self.geoPlant_inputs.md_TemperatureEGSAmbientC = 15.0
        self.geoPlant_inputs.md_EGSThermalConductivity = self.rock_thermal_conductivity
        self.geoPlant_inputs.md_EGSSpecificHeatConstant = self.rock_specific_heat
        self.geoPlant_inputs.md_EGSRockDensity = self.rock_density
        # reservoir_pressure_change_type switch
        if self.reservoir_pressure_change_type == 0:
            self.geoPlant_inputs.me_pc = ENTER_PC
        elif self.reservoir_pressure_change_type == 1:
            self.geoPlant_inputs.me_pc = SIMPLE_FRACTURE
        elif self.reservoir_pressure_change_type == 2:
            self.geoPlant_inputs.me_pc = K_AREA
        self.geoPlant_inputs.md_ReservoirDeltaPressure = self.reservoir_pressure_change
        self.geoPlant_inputs.md_ReservoirWidthM = self.reservoir_width
        self.geoPlant_inputs.md_ReservoirHeightM = self.reservoir_height
        self.geoPlant_inputs.md_ReservoirPermeability = self.reservoir_permeability
        self.geoPlant_inputs.md_DistanceBetweenProductionInjectionWellsM = self.inj_prod_well_distance
        self.geoPlant_inputs.md_WaterLossPercent = self.subsurface_water_loss / 100.0
        self.geoPlant_inputs.md_EGSFractureAperature = self.fracture_aperature
        self.geoPlant_inputs.md_EGSNumberOfFractures = self.num_fractures
        self.geoPlant_inputs.md_EGSFractureWidthM = self.fracture_width
        self.geoPlant_inputs.md_EGSFractureAngle = self.fracture_angle
        self.geoPlant_inputs.mi_ModelChoice = 0
        self.geoPlant_inputs.mi_ProjectLifeYears = self.geothermal_analysis_period
        self.geoPlant_inputs.md_PotentialResourceMW = self.resource_potential
        self.geoPlant_inputs.mc_WeatherFileName = geothermal_weather_path
        self.geoPlant_inputs.mia_tou = self.tou  # note: Mojo uses list; original expects pointer
        self.geoPlant_inputs.mi_MakeupCalculationsPerYear = 8760 if (self.geoPlant_inputs.mi_ModelChoice == 2) else 12
        self.geoPlant_inputs.mi_TotalMakeupCalculations = self.geoPlant_inputs.mi_ProjectLifeYears * self.geoPlant_inputs.mi_MakeupCalculationsPerYear
        # geoPlant_outputs (initialize dynamic lists)
        numYears = self.geoPlant_inputs.mi_ProjectLifeYears
        self.geoPlant_outputs.md_NumberOfWells = 0.0  # placeholder
        self.geoPlant_outputs.md_PumpWorkKW = 0.0
        self.geoPlant_outputs.eff_secondlaw = 0.0
        self.geoPlant_outputs.qRejectedTotal = 0.0
        self.geoPlant_outputs.condenser_q = 0.0
        self.geoPlant_outputs.v_stage_1 = 0.0
        self.geoPlant_outputs.v_stage_2 = 0.0
        self.geoPlant_outputs.v_stage_3 = 0.0
        self.geoPlant_outputs.GF_flowrate = 0.0
        self.geoPlant_outputs.qRejectByStage_1 = 0.0
        self.geoPlant_outputs.qRejectByStage_2 = 0.0
        self.geoPlant_outputs.qRejectByStage_3 = 0.0
        self.geoPlant_outputs.ncg_condensate_pump = 0.0
        self.geoPlant_outputs.cw_pump_work = 0.0
        self.geoPlant_outputs.pressure_ratio_1 = 0.0
        self.geoPlant_outputs.pressure_ratio_2 = 0.0
        self.geoPlant_outputs.pressure_ratio_3 = 0.0
        self.geoPlant_outputs.condensate_pump_power = 0.0
        self.geoPlant_outputs.cwflow = 0.0
        self.geoPlant_outputs.cw_pump_head = 0.0
        self.geoPlant_outputs.flash_temperature = 0.0
        self.geoPlant_outputs.flash_temperature_lp = 0.0
        self.geoPlant_outputs.spec_vol = 0.0
        self.geoPlant_outputs.spec_vol_lp = 0.0
        self.geoPlant_outputs.getX_hp = 0.0
        self.geoPlant_outputs.getX_lp = 0.0
        self.geoPlant_outputs.flash_count = 0
        self.geoPlant_outputs.max_secondlaw = 0.0
        self.geoPlant_outputs.mb_BrineEffectivenessCalculated = False
        self.geoPlant_outputs.md_FlashBrineEffectiveness = 0.0
        self.geoPlant_outputs.mb_FlashPressuresCalculated = False
        self.geoPlant_outputs.md_PressureHPFlashPSI = 0.0
        self.geoPlant_outputs.md_PressureLPFlashPSI = 0.0
        self.geoPlant_outputs.md_PlantBrineEffectiveness = 0.0
        self.geoPlant_outputs.md_GrossPlantOutputMW = 0.0
        self.geoPlant_outputs.md_PumpDepthFt = 0.0
        self.geoPlant_outputs.md_PumpHorsePower = 0.0
        self.geoPlant_outputs.md_PressureChangeAcrossReservoir = 0.0
        self.geoPlant_outputs.md_AverageReservoirTemperatureF = 0.0
        self.geoPlant_outputs.md_BottomHolePressure = 0.0
        # Allocate dynamic arrays as lists
        self.geoPlant_outputs.maf_ReplacementsByYear = List[Float64](replicate=False, capacity=numYears)
        for i in range(numYears):
            self.geoPlant_outputs.maf_ReplacementsByYear.append(0.0)
        self.geoPlant_outputs.maf_monthly_resource_temp = List[Float64](replicate=False, capacity=12 * numYears)
        for i in range(12 * numYears):
            self.geoPlant_outputs.maf_monthly_resource_temp.append(0.0)
        self.geoPlant_outputs.maf_monthly_power = List[Float64](replicate=False, capacity=12 * numYears)
        for i in range(12 * numYears):
            self.geoPlant_outputs.maf_monthly_power.append(0.0)
        self.geoPlant_outputs.maf_monthly_energy = List[Float64](replicate=False, capacity=12 * numYears)
        for i in range(12 * numYears):
            self.geoPlant_outputs.maf_monthly_energy.append(0.0)
        totalMakeup = self.geoPlant_inputs.mi_TotalMakeupCalculations
        self.geoPlant_outputs.maf_timestep_resource_temp = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_resource_temp.append(0.0)
        self.geoPlant_outputs.maf_timestep_power = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_power.append(0.0)
        self.geoPlant_outputs.maf_timestep_test_values = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_test_values.append(0.0)
        self.geoPlant_outputs.maf_timestep_pressure = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_pressure.append(0.0)
        self.geoPlant_outputs.maf_timestep_dry_bulb = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_dry_bulb.append(0.0)
        self.geoPlant_outputs.maf_timestep_wet_bulb = List[Float64](replicate=False, capacity=totalMakeup)
        for i in range(totalMakeup):
            self.geoPlant_outputs.maf_timestep_wet_bulb.append(0.0)
        self.geoPlant_outputs.maf_hourly_power = List[Float64](replicate=False, capacity=numYears * 8760)
        for i in range(numYears * 8760):
            self.geoPlant_outputs.maf_hourly_power.append(0.0)
        # Create and run geoTester
        var user_data: Any = None
        self.geoTester = CGeothermalAnalyzer(self.SPBP, self.PBInputs, self.geoPlant_inputs, self.geoPlant_outputs)
        self.geoTester.RunAnalysis(my_update_function, user_data)
        self.geoTester.InterfaceOutputsFilled()

    def TearDown(inout self):
        # Note: geoTester is stack-allocated, no delete needed
        # Arrays are lists, automatically cleaned; but set to empty for consistency
        self.geoPlant_outputs.maf_hourly_power = List[Float64]()
        self.geoPlant_outputs.maf_timestep_wet_bulb = List[Float64]()
        self.geoPlant_outputs.maf_timestep_dry_bulb = List[Float64]()
        self.geoPlant_outputs.maf_timestep_pressure = List[Float64]()
        self.geoPlant_outputs.maf_timestep_test_values = List[Float64]()
        self.geoPlant_outputs.maf_timestep_power = List[Float64]()
        self.geoPlant_outputs.maf_timestep_resource_temp = List[Float64]()
        self.geoPlant_outputs.maf_monthly_energy = List[Float64]()
        self.geoPlant_outputs.maf_monthly_power = List[Float64]()
        self.geoPlant_outputs.maf_monthly_resource_temp = List[Float64]()
        self.geoPlant_outputs.maf_ReplacementsByYear = List[Float64]()

# Test functions (equivalent to TEST_F)
def TestBinaryPlant_lib_geothermal():
    var fixture = GeothermalPlantAnalyzer()
    fixture.conversion_type = 0
    fixture.SetUp()
    expect_near(fixture.geoPlant_outputs.max_secondlaw, 0.4, 0.2)
    expect_near(fixture.geoPlant_outputs.md_GrossPlantOutputMW, 33.159, 3.0)
    expect_near(fixture.geoPlant_outputs.GF_flowrate, 4993110.0, 200000.0)

def TestFlashPlant_lib_geothermal():
    var fixture = GeothermalPlantAnalyzer()
    fixture.conversion_type = 1
    fixture.SetUp()
    expect_eq(fixture.geoPlant_outputs.flash_count, 2)  # Dual Flash (Constrained) Plant Type
    expect_near(fixture.geoPlant_outputs.md_GrossPlantOutputMW, 33.978, 1.0)  # Expected value of 33.978 taken from GETEM
    expect_near(fixture.geoPlant_outputs.max_secondlaw, 0.5, 0.3)