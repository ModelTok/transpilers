from core import ssc_data_create, ssc_data_free, ssc_data_get_number, ssc_data_get_array, ssc_data_set_array, ssc_data_set_matrix, ssc_data_unassign, ssc_data_set_table, ssc_data_set_number, ssc_data_clear, ssc_data_t, ssc_number_t, run_module, modify_ssc_data_and_run_module
from vartab import var_data, var_table
from ...ssc.common import set_matrix
from ...input_cases.pvsamv1_cases import pvsamv_nofinancial_default, pvsam_residential_pheonix, pvsamv1_with_residential_default, Reopt_size_battery_params
from ...input_cases.weather_inputs import solar_resource_path_15_min, solar_resource_path_15min_fail, solar_resource_path, subarray1_shading, subarray2_shading
from ...ssc.common import create_weatherdata_array, free_weatherdata_array, utility_rate5_default, belpe_default
from testing import assert_approx_equal, assert_true, assert_false, assert_equal
from memory import Pointer, free

def expect_near(actual: Float64, expected: Float64, tol: Float64, msg: String = ""):
    assert_approx_equal(actual, expected, tol, msg)

def expect_false(cond: Bool, msg: String = ""):
    assert_false(cond, msg)

def expect_true(cond: Bool, msg: String = ""):
    assert_true(cond, msg)

def expect_eq[T](actual: T, expected: T, msg: String = ""):
    assert_equal(actual, expected, msg)

struct CMPvsamv1PowerIntegration_cmod_pvsamv1:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]
    var m_error_tolerance_hi: Float64 = 1.0
    var m_error_tolerance_lo: Float64 = 0.1

    def __init__(inout self):
        self.data = ssc_data_create()
        pvsamv_nofinancial_default(self.data)
        self.calculated_array = Pointer[ssc_number_t].alloc(8760)

    def __del__(owned self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None
        if self.calculated_array:
            free(self.calculated_array)

    def SetUp(inout self):
        self.data = ssc_data_create()
        pvsamv_nofinancial_default(self.data)
        self.calculated_array = Pointer[ssc_number_t].alloc(8760)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None
        if self.calculated_array:
            free(self.calculated_array)

    def SetCalculated(inout self, name: String):
        self.calculated_value = ssc_data_get_number(self.data, name)

    def SetCalculatedArray(inout self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, &n)

@test
def DefaultNoFinancialModel():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pvsam_errors: Int = run_module(fixture.data, "pvsamv1")
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, 8711.6, fixture.m_error_tolerance_hi, "Annual energy.")
        var capacity_factor: ssc_number_t
        capacity_factor = ssc_data_get_number(fixture.data, "capacity_factor")
        expect_near(capacity_factor, 21.2, fixture.m_error_tolerance_lo, "Capacity factor")
        var kwh_per_kw: ssc_number_t
        kwh_per_kw = ssc_data_get_number(fixture.data, "kwh_per_kw")
        expect_near(kwh_per_kw, 1857, fixture.m_error_tolerance_hi, "Energy yield")
        var performance_ratio: ssc_number_t
        performance_ratio = ssc_data_get_number(fixture.data, "performance_ratio")
        expect_near(performance_ratio, 0.79, fixture.m_error_tolerance_lo, "Energy yield")

@test
def DefaultLifetimeNoFinancialModel():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["system_use_lifetime_output"] = 1.0
    pairs["save_full_lifetime_variables"] = 1.0
    pairs["analysis_period"] = 25.0
    var dc_degradation: StaticFloat64[25] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    ssc_data_set_array(fixture.data, "dc_degradation", (ssc_number_t*)dc_degradation.data(), 25)
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, 8711.6, fixture.m_error_tolerance_hi, "Annual energy.")
        var capacity_factor: ssc_number_t
        capacity_factor = ssc_data_get_number(fixture.data, "capacity_factor")
        expect_near(capacity_factor, 21.2, fixture.m_error_tolerance_lo, "Capacity factor")
        var kwh_per_kw: ssc_number_t
        kwh_per_kw = ssc_data_get_number(fixture.data, "kwh_per_kw")
        expect_near(kwh_per_kw, 1857, fixture.m_error_tolerance_hi, "Energy yield")
        var performance_ratio: ssc_number_t
        performance_ratio = ssc_data_get_number(fixture.data, "performance_ratio")
        expect_near(performance_ratio, 0.79, fixture.m_error_tolerance_lo, "Energy yield")

@test
def DefaultResidentialModel():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pvsam_errors: Int = pvsam_residential_pheonix(fixture.data)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, 8711.6, fixture.m_error_tolerance_hi, "Annual energy.")
        var capacity_factor: ssc_number_t
        capacity_factor = ssc_data_get_number(fixture.data, "capacity_factor")
        expect_near(capacity_factor, 21.2, fixture.m_error_tolerance_lo, "Capacity factor")
        var kwh_per_kw: ssc_number_t
        kwh_per_kw = ssc_data_get_number(fixture.data, "kwh_per_kw")
        expect_near(kwh_per_kw, 1857, fixture.m_error_tolerance_hi, "Energy yield")
        var performance_ratio: ssc_number_t
        performance_ratio = ssc_data_get_number(fixture.data, "performance_ratio")
        expect_near(performance_ratio, 0.79, fixture.m_error_tolerance_lo, "Energy yield")
        var lcoe_nom: ssc_number_t
        lcoe_nom = ssc_data_get_number(fixture.data, "lcoe_nom")
        expect_near(lcoe_nom, 7.14, fixture.m_error_tolerance_lo, "Levelized COE (nominal)")
        var lcoe_real: ssc_number_t
        lcoe_real = ssc_data_get_number(fixture.data, "lcoe_real")
        expect_near(lcoe_real, 5.65, fixture.m_error_tolerance_lo, "Levelized COE (real)")
        var elec_cost_without_system_year1: ssc_number_t
        elec_cost_without_system_year1 = ssc_data_get_number(fixture.data, "elec_cost_without_system_year1")
        expect_near(elec_cost_without_system_year1, 973, fixture.m_error_tolerance_hi, "Electricity bill without system (year 1)")
        var elec_cost_with_system_year1: ssc_number_t
        elec_cost_with_system_year1 = ssc_data_get_number(fixture.data, "elec_cost_with_system_year1")
        expect_near(elec_cost_with_system_year1, 125, fixture.m_error_tolerance_hi, "Electricity bill with system (year 1)")
        var savings_year1: ssc_number_t
        savings_year1 = ssc_data_get_number(fixture.data, "savings_year1")
        expect_near(savings_year1, 848, fixture.m_error_tolerance_hi, "Net savings with system (year 1)")
        var npv: ssc_number_t
        npv = ssc_data_get_number(fixture.data, "npv")
        expect_near(npv, 4646.7, fixture.m_error_tolerance_hi, "Net present value")
        var payback: ssc_number_t
        payback = ssc_data_get_number(fixture.data, "payback")
        expect_near(payback, 11.8, fixture.m_error_tolerance_lo, "Payback period")
        var discounted_payback: ssc_number_t
        discounted_payback = ssc_data_get_number(fixture.data, "discounted_payback")
        expect_near(discounted_payback, 22.9, fixture.m_error_tolerance_lo, "Discounted payback period")
        var adjusted_installed_cost: ssc_number_t
        adjusted_installed_cost = ssc_data_get_number(fixture.data, "adjusted_installed_cost")
        expect_near(adjusted_installed_cost, 13758, fixture.m_error_tolerance_hi, "Net capital cost")
        var first_cost: ssc_number_t
        first_cost = ssc_data_get_number(fixture.data, "first_cost")
        expect_near(first_cost, 0, fixture.m_error_tolerance_lo, "Equity")
        var loan_amount: ssc_number_t
        loan_amount = ssc_data_get_number(fixture.data, "loan_amount")
        expect_near(loan_amount, 13758, fixture.m_error_tolerance_hi, "Debt")

@test
def NoFinancialModelCustomWeatherFile():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pairs: Map[String, String] = Map[String, String]()
    pairs["solar_resource_file"] = solar_resource_path_15_min
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, 8079.1, fixture.m_error_tolerance_hi, "Annual energy.")
        var capacity_factor: ssc_number_t
        capacity_factor = ssc_data_get_number(fixture.data, "capacity_factor")
        expect_near(capacity_factor, 19.6, fixture.m_error_tolerance_lo, "Capacity factor")
        var kwh_per_kw: ssc_number_t
        kwh_per_kw = ssc_data_get_number(fixture.data, "kwh_per_kw")
        expect_near(kwh_per_kw, 1722, fixture.m_error_tolerance_hi, "Energy yield")
        var performance_ratio: ssc_number_t
        performance_ratio = ssc_data_get_number(fixture.data, "performance_ratio")
        expect_near(performance_ratio, 0.80, fixture.m_error_tolerance_lo, "Energy yield")
    pairs["solar_resource_file"] = solar_resource_path_15min_fail
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_true(pvsam_errors)

@test
def NoFinancialModelSkyDiffuseAndIrradModels():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](8511, 8522, 8525, 8633, 8644, 8647, 8712, 8722, 8726, 7623, 7297)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    var count: Int = 0
    for sky_diffuse_model in range(3):
        for irrad_mode in range(3):
            pairs["irrad_mode"] = Float64(irrad_mode)
            pairs["sky_model"] = Float64(sky_diffuse_model)
            var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
            expect_false(pvsam_errors)
            if not pvsam_errors:
                var annual_energy: ssc_number_t
                annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
                expect_near(annual_energy, annual_energy_expected[count], fixture.m_error_tolerance_hi, "Annual energy.")
            count += 1
    pairs["sky_model"] = 2.0
    pairs["irrad_mode"] = 3.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[count], fixture.m_error_tolerance_hi)
        count += 1
    pairs["irrad_mode"] = 4.0
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[count], fixture.m_error_tolerance_hi)

@test
def NoFinancialModelModuleAndInverterModels():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](2517, 2547, 2474, 2517, 8712, 8691, 8657, 8711, 54, 57, 60, 54, 5403, 5398, 5345, 5403, 1726, 1764, 1695, 1726)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    var count: Int = 0
    for module_model in range(5):
        for inverter_model in range(4):
            pairs["module_model"] = Float64(module_model)
            pairs["inverter_model"] = Float64(inverter_model)
            var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
            expect_false(pvsam_errors)
            if not pvsam_errors:
                var annual_energy: ssc_number_t
                annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
                expect_near(annual_energy, annual_energy_expected[count], fixture.m_error_tolerance_hi, "Annual energy.")
            count += 1

@test
def NoFinancialModelModuleThermalSpectralReflection():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](8712, 8749)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    var count: Int = 0
    for cec_temp_corr_mode in range(1):
        pairs["cec_temp_corr_mode"] = Float64(cec_temp_corr_mode)
        var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
        expect_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
            expect_near(annual_energy, annual_energy_expected[count], fixture.m_error_tolerance_hi, "Annual energy.")
        count += 1

@test
def NoFinancialModelSystemDesign():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    pvsamv_nofinancial_default(fixture.data)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["subarray1_modules_per_string"] = 6.0
    pairs["subarray2_modules_per_string"] = 6.0
    pairs["subarray3_modules_per_string"] = 6.0
    pairs["subarray4_modules_per_string"] = 6.0
    pairs["subarray1_nstrings"] = 49.0
    pairs["inverter_count"] = 22.0
    pairs["subarray1_track_mode"] = 0.0
    var annual_energy_expected: List[Float64] = List[Float64](183183, 242368, 258372, 216129, 192903)
    for tracking_option in range(5):
        pairs["subarray1_track_mode"] = Float64(tracking_option)
        var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
        expect_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
            expect_near(annual_energy, annual_energy_expected[tracking_option], fixture.m_error_tolerance_hi, "Annual energy.")
    pairs["subarray1_track_mode"] = 1.0
    pairs["subarray1_backtrack"] = 1.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, 237115, fixture.m_error_tolerance_hi, "Annual energy.")
    pairs["subarray1_nstrings"] = 14.0
    pairs["subarray2_enable"] = 1.0
    pairs["subarray2_nstrings"] = 15.0
    pairs["subarray3_enable"] = 1.0
    pairs["subarray3_nstrings"] = 10.0
    pairs["subarray4_enable"] = 1.0
    pairs["subarray4_nstrings"] = 10.0
    annual_energy_expected.clear()
    var subarray1_azimuth: List[Float64] = List[Float64](0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
    var subarray2_azimuth: List[Float64] = List[Float64](180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
    var subarray3_azimuth: List[Float64] = List[Float64](180, 180, 180, 180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
    var subarray4_azimuth: List[Float64] = List[Float64](180, 180, 180, 180, 180, 180, 180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
    var enable_mismatch: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var subarray1_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
    var subarray2_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
    var subarray3_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
    var subarray4_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
    var subarray1_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
    var subarray2_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
    var subarray3_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
    var subarray4_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
    var subarray1_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
    var subarray2_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
    var subarray3_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
    var subarray4_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
    var subarray1_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var subarray2_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    var subarray3_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0)
    var subarray4_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4)
    annual_energy_expected = List[Float64](167338, 176266, 183183, 166198, 175768, 183183, 171896, 178257, 183183, 171896, 178257,
                              183183, 183183, 183175, 183183, 183183, 183183, 183183, 183183, 183183, 183183, 183183,
                              183183, 183183, 183183, 183183, 177254, 182865, 162398, 176827, 182840, 160903, 178957,
                              182963, 168372, 178957, 182963, 168372, 183183, 183183, 183183, 183183, 183183, 198689,
                              205087, 192620, 186025, 183183, 201406, 206647, 193294, 186227, 183183, 195336, 198838,
                              189925, 185216, 183183, 195336, 198838, 189925, 185216)
    for i in range(annual_energy_expected.size):
        pairs["enable_mismatch_vmax_calc"] = enable_mismatch[i]
        pairs["subarray1_azimuth"] = subarray1_azimuth[i]
        pairs["subarray2_azimuth"] = subarray2_azimuth[i]
        pairs["subarray3_azimuth"] = subarray3_azimuth[i]
        pairs["subarray4_azimuth"] = subarray4_azimuth[i]
        pairs["subarray1_gcr"] = subarray1_gcr[i]
        pairs["subarray2_gcr"] = subarray2_gcr[i]
        pairs["subarray3_gcr"] = subarray3_gcr[i]
        pairs["subarray4_gcr"] = subarray4_gcr[i]
        pairs["subarray1_tilt"] = subarray1_tilt[i]
        pairs["subarray2_tilt"] = subarray2_tilt[i]
        pairs["subarray3_tilt"] = subarray3_tilt[i]
        pairs["subarray4_tilt"] = subarray4_tilt[i]
        pairs["subarray1_rotlim"] = subarray1_rotlim[i]
        pairs["subarray2_rotlim"] = subarray2_rotlim[i]
        pairs["subarray3_rotlim"] = subarray3_rotlim[i]
        pairs["subarray4_rotlim"] = subarray4_rotlim[i]
        pairs["subarray1_track_mode"] = subarray1_track_mode[i]
        pairs["subarray2_track_mode"] = subarray2_track_mode[i]
        pairs["subarray3_track_mode"] = subarray3_track_mode[i]
        pairs["subarray4_track_mode"] = subarray4_track_mode[i]
        pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
        expect_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
            expect_near(annual_energy, annual_energy_expected[i], fixture.m_error_tolerance_hi, "Index: " + String(i))

@test
def NoFinancialModelShading():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](12905, 10604, 10526, 10326)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["subarray1_modules_per_string"] = 6.0
    pairs["subarray2_modules_per_string"] = 6.0
    pairs["subarray3_modules_per_string"] = 6.0
    pairs["subarray4_modules_per_string"] = 6.0
    pairs["inverter_count"] = 2.0
    pairs["subarray1_nstrings"] = 2.0
    pairs["subarray1_azimuth"] = 90.0
    pairs["subarray2_enable"] = 1.0
    pairs["subarray2_nstrings"] = 2.0
    pairs["subarray2_azimuth"] = 270.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[0], fixture.m_error_tolerance_hi)
    pairs["subarray1_azimuth"] = 180.0
    pairs["subarray2_azimuth"] = 180.0
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var n1: Int
        var n2: Int
        var subarray1_poa_front: Pointer[ssc_number_t] = ssc_data_get_array(fixture.data, "subarray1_poa_front", &n1)
        var subarray2_poa_front: Pointer[ssc_number_t] = ssc_data_get_array(fixture.data, "subarray2_poa_front", &n2)
        expect_eq(n1, n2)
        for i in range(n1):
            expect_eq(subarray1_poa_front[i], subarray2_poa_front[i])
    pairs["subarray1_azimuth"] = 90.0
    pairs["subarray2_azimuth"] = 270.0
    set_matrix(fixture.data, "subarray1_shading:timestep", subarray1_shading, 8760, 2)
    set_matrix(fixture.data, "subarray2_shading:timestep", subarray2_shading, 8760, 2)
    pairs["subarray1_shading:diff"] = 10.010875701904297
    pairs["subarray2_shading:diff"] = 10.278481483459473
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[1], fixture.m_error_tolerance_hi)
    pairs["subarray1_shade_mode"] = 1.0
    pairs["subarray1_mod_orient"] = 1.0
    pairs["subarray1_nmody"] = 1.0
    pairs["subarray1_nmodx"] = 6.0
    pairs["subarray2_shade_mode"] = 1.0
    pairs["subarray2_mod_orient"] = 1.0
    pairs["subarray2_nmody"] = 1.0
    pairs["subarray2_nmodx"] = 6.0
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[2], fixture.m_error_tolerance_hi)
    pairs["en_snow_model"] = 1.0
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[3], fixture.m_error_tolerance_hi)

@test
def NoFinancialModelLosses():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](8712, 7871, 7604)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[0], fixture.m_error_tolerance_hi)
    var p_subarray1_soiling: StaticFloat64[12] = [5.0, 5.0, 5.0, 5.0, 6.0, 6.0, 6.0, 6.0, 5.0, 5.0, 5.0, 5.0]
    ssc_data_set_array(fixture.data, "subarray1_soiling", (ssc_number_t*)p_subarray1_soiling.data(), 12)
    pairs["subarray1_mismatch_loss"] = 3.0
    pairs["subarray1_diodeconn_loss"] = 0.6
    pairs["subarray1_dcwiring_loss"] = 2.0
    pairs["subarray1_tracking_loss"] = 1.0
    pairs["subarray1_nameplate_loss"] = 1.0
    pairs["dcoptimizer_loss"] = 1.0
    pairs["acwiring_loss"] = 2.0
    pairs["transformer_no_load_loss"] = 1.0
    pairs["transformer_load_loss"] = 1.0
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[1], fixture.m_error_tolerance_hi)
    var p_adjust: StaticFloat64[3] = [5268.0, 5436.0, 50.0]
    ssc_data_set_matrix(fixture.data, "adjust:periods", (ssc_number_t*)p_adjust.data(), 1, 3)
    var p_dc_adjust: StaticFloat64[3] = [5088.0, 5256.0, 100.0]
    ssc_data_set_matrix(fixture.data, "dc_adjust:periods", (ssc_number_t*)p_dc_adjust.data(), 1, 3)
    pvsam_errors = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        fixture.SetCalculated("annual_energy")
        expect_near(fixture.calculated_value, annual_energy_expected[2], fixture.m_error_tolerance_hi)

@test
def InvTempDerate():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var weatherData: Pointer[var_data] = create_weatherdata_array(8760)
    ssc_data_unassign(fixture.data, "solar_resource_file")
    var vt: Pointer[var_table] = Pointer[var_table](address_of(fixture.data))  # cast? Assume var_table* from ssc_data_t
    var temp: StaticFloat64[8760] = [26.0] * 8760
    for i in range(4380):
        temp[i] = 76.6
    var tdry_vd: var_data = var_data(temp.data(), 8760)
    tdry_vd = var_data(temp.data(), 8760)
    weatherData[0].table.assign("tdry", tdry_vd)
    vt[0].assign("solar_resource_data", weatherData[0])
    expect_false(run_module(fixture.data, "pvsamv1"))
    var annual_energy: ssc_number_t
    var loss: ssc_number_t
    var percent_loss: ssc_number_t
    var monthly_energy: ssc_number_t
    annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
    expect_near(annual_energy, 4382, 10, "Annual energy reduced")
    loss = ssc_data_get_number(fixture.data, "annual_inv_tdcloss")
    expect_near(loss, 149, 10, "Annual loss")
    percent_loss = ssc_data_get_number(fixture.data, "annual_dc_inv_tdc_loss_percent")
    expect_near(percent_loss, 3, 2)
    monthly_energy = ssc_data_get_array(fixture.data, "monthly_energy", None)[0]
    expect_near(monthly_energy, 520, 10, "Monthly energy of January reduced")
    monthly_energy = ssc_data_get_array(fixture.data, "monthly_energy", None)[11]
    expect_near(monthly_energy, 740, 10, "Month energy of December not reduced")
    free_weatherdata_array(weatherData)

@test
def NoFinancialModelMultipleMPPT():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var annual_energy_expected: List[Float64] = List[Float64](7631)
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["inv_num_mppt"] = 2.0
    pairs["subarray1_nstrings"] = 1.0
    pairs["subarray1_modules_per_string"] = 7.0
    pairs["subarray1_mppt_input"] = 1.0
    pairs["subarray1_tilt"] = 20.0
    pairs["subarray2_enable"] = 1.0
    pairs["subarray2_nstrings"] = 1.0
    pairs["subarray2_modules_per_string"] = 6.0
    pairs["subarray2_tilt"] = 0.0
    pairs["subarray2_mppt_input"] = 2.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annual_energy: ssc_number_t
        annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annual_energy, annual_energy_expected[0], fixture.m_error_tolerance_hi, "Annual energy.")

@test
def SnowModel():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["en_snow_model"] = 1.0
    pairs["subarray1_track_mode"] = 1.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    var annual_energy: ssc_number_t
    annual_energy = ssc_data_get_number(fixture.data, "annual_energy")
    expect_near(annual_energy, 11346.4, fixture.m_error_tolerance_hi, "Annual energy.")

@test
def InverterNighttime():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pvsam_errors: Int = run_module(fixture.data, "pvsamv1")
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var inverterMppt1Voltage: ssc_number_t
        inverterMppt1Voltage = ssc_data_get_array(fixture.data, "inverterMPPT1_DCVoltage", None)[0]
        expect_near(inverterMppt1Voltage, 0.0, 0.001, "MPPT Voltage should be 0 at night.")

@test
def TiltEqualsLat():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["subarray1_tilt_eq_lat"] = 1.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var subarray1SurfaceTilt: ssc_number_t
        subarray1SurfaceTilt = ssc_data_get_array(fixture.data, "subarray1_surf_tilt", None)[12]
        expect_near(subarray1SurfaceTilt, 33.4, 0.1, "Subarray 1 tilt should be equal to latitude.")

@test
def bifacial():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    var pairs: Map[String, Float64] = Map[String, Float64]()
    pairs["cec_is_bifacial"] = 1.0
    pairs["cec_bifacial_transmission_factor"] = 0.013
    pairs["cec_bifaciality"] = 0.65
    pairs["cec_bifacial_ground_clearance_height"] = 1.0
    pairs["cec_adjust"] = 4.86
    pairs["cec_i_o_ref"] = 3.9880000000000000e-12
    pairs["mppt_low_inverter"] = 100.0
    pairs["inv_snl_c0"] = -3.0810000000000000e-06
    pairs["inv_snl_c1"] = -4.8000000000000000e-05
    pairs["inv_snl_c2"] = 0.000123
    pairs["inv_snl_c3"] = -0.00163
    pairs["inv_snl_paco"] = 3850.0
    pairs["inv_snl_pdco"] = 3964.0
    pairs["inv_snl_pnt"] = 1.15
    pairs["inv_snl_pso"] = 17.9
    pairs["inv_snl_vdco"] = 400.0
    pairs["inv_snl_vdcmax"] = 480.0
    var pvsam_errors: Int = modify_ssc_data_and_run_module(fixture.data, "pvsamv1", pairs)
    expect_false(pvsam_errors)
    if not pvsam_errors:
        var annualEnergy: ssc_number_t
        annualEnergy = ssc_data_get_number(fixture.data, "annual_energy")
        expect_near(annualEnergy, 9139, 1.0, "Bifacial annual energy from SAM version 2018.11.11 using Phoenix TMY2")

@test
def reopt_sizing():
    var fixture = CMPvsamv1PowerIntegration_cmod_pvsamv1()
    ssc_data_clear(fixture.data)
    pvsamv1_with_residential_default(fixture.data)
    utility_rate5_default(fixture.data)
    belpe_default(f