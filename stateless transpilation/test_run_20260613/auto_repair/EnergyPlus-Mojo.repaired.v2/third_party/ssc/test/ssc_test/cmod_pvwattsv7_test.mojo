from ...ssc.core import ssc_data_create, ssc_data_free, ssc_data_get_array, ssc_data_get_number, ssc_data_set_string, ssc_data_set_array, ssc_data_unassign, ssc_data_set_table, ssc_module_create, ssc_module_exec, ssc_module_free, SSCDIR
from ...input_cases.pvwattsv7_cases import pvwattsv7_nofinancial_testfile
from ...input_cases.weather_inputs import create_weatherdata_array, free_weatherdata_array, run_module, modify_ssc_data_and_run_module

struct CMPvwattsV7Integration_cmod_pvwattsv7:
    var data: ssc_data_t
    var error_tolerance: Float64 = 1.0e-3

    def __init__(inout self):
        # Initialize data pointer to None; setup done in SetUp
        self.data = None

    def SetUp(inout self):
        self.data = ssc_data_create()
        var errors = pvwattsv7_nofinancial_testfile(self.data)
        # EXPECT_FALSE(errors) -- assert no errors
        assert not errors

    def TearDown(inout self):
        ssc_data_free(self.data)
        self.data = None

    def compute(inout self) -> Bool:
        var module = ssc_module_create("pvwattsv7")
        if module is None:
            print("error: could not create 'pvwattsv7' module.")
            ssc_data_free(self.data)
            return False
        if ssc_module_exec(module, self.data) == 0:
            print("error during simulation.")
            ssc_module_free(module)
            ssc_data_free(self.data)
            return True  # error condition returns True? Original returns false, but consistency: return True on error
        ssc_module_free(module)
        return False  # original returns 0 (false) on success; we keep false for success

    # Test methods corresponding to TEST_F
    def DefaultNoFinancialModel_cmod_pvwattsv7(inout self):
        self.SetUp()
        var success = self.compute()
        # compute returns False on success per our translation
        # In original, compute() is called without checking
        var tmp: Float64 = 0.0
        var monthly_energy = ssc_data_get_array(self.data, "monthly_energy")
        for i in range(12):
            tmp += monthly_energy[i]
        expect_near(tmp, 6999.0158, self.error_tolerance, "Annual energy.")
        expect_near(monthly_energy[0], 439.453, self.error_tolerance, "Monthly energy of January")
        expect_near(monthly_energy[1], 485.215, self.error_tolerance, "Monthly energy of February")
        expect_near(monthly_energy[2], 597.276, self.error_tolerance, "Monthly energy of March")
        expect_near(monthly_energy[3], 680.286, self.error_tolerance, "Monthly energy of April")
        expect_near(monthly_energy[4], 724.357, self.error_tolerance, "Monthly energy of May")
        expect_near(monthly_energy[5], 675.908, self.error_tolerance, "Monthly energy of June")
        expect_near(monthly_energy[6], 674.691, self.error_tolerance, "Monthly energy of July")
        expect_near(monthly_energy[7], 658.672, self.error_tolerance, "Monthly energy of August")
        expect_near(monthly_energy[8], 606.967, self.error_tolerance, "Monthly energy of September")
        expect_near(monthly_energy[9], 579.669, self.error_tolerance, "Monthly energy of October")
        expect_near(monthly_energy[10], 459.671, self.error_tolerance, "Monthly energy of November")
        expect_near(monthly_energy[11], 416.851, self.error_tolerance, "Month energy of December")
        var capacity_factor: Float64 = 0.0
        capacity_factor = ssc_data_get_number(self.data, "capacity_factor")
        expect_near(capacity_factor, 19.974, self.error_tolerance, "Capacity factor")
        self.TearDown()

    def DifferentTechnologyInputs_cmod_pvwattsv7(inout self):
        self.SetUp()
        var annual_energy_expected = List[Float64](6999.01, 7030.26, 7077.07, 6999.01, 6971.04, 8785.40, 8725.66, 9861.27)
        var pairs = Dict[String, Float64]()
        var count: Int = 0
        self.error_tolerance = 0.01
        for module_type in range(3):
            pairs["module_type"] = module_type
            var pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
            assert not pvwatts_errors
            if not pvwatts_errors:
                var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
                expect_near(annual_energy, annual_energy_expected[count], self.error_tolerance, "Annual energy.")
            count += 1
        pairs["module_type"] = 0  # reset module type to its default value
        for array_type in range(5):
            pairs["array_type"] = array_type
            var pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
            assert not pvwatts_errors
            if not pvwatts_errors:
                var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
                expect_near(annual_energy, annual_energy_expected[count], self.error_tolerance, "Annual energy.")
            count += 1
        pairs["array_type"] = 0  # reset array type to fixed open rack
        self.TearDown()

    def LargeSystem_cmod_pvwattsv7(inout self):
        self.SetUp()
        var annual_energy_expected = List[Float64](1747992.2, 1742760.1, 2190219.7, 2175654.8, 2465319.2)
        var pairs = Dict[String, Float64]()
        var count: Int = 0
        self.error_tolerance = 0.1  # use a larger error tolerance for large numbers
        pairs["system_capacity"] = 1000  # 1 MW system
        for array_type in range(5):
            pairs["array_type"] = array_type
            var pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
            assert not pvwatts_errors
            if not pvwatts_errors:
                var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
                expect_near(annual_energy, annual_energy_expected[count], self.error_tolerance, "Annual energy.")
            count += 1
        self.TearDown()

    def SubhourlyWeather_cmod_pvwattsv7(inout self):
        self.SetUp()
        # Build the file path
        var subhourly = SSCDIR + "/test/input_cases/pvsamv1_data/LosAngeles_WeatherFile_15min.csv"
        ssc_data_set_string(self.data, "solar_resource_file", subhourly)  # file set above
        var pvwatts_errors = run_module(self.data, "pvwattsv7")
        assert not pvwatts_errors
        if not pvwatts_errors:
            var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
            expect_near(annual_energy, 6524.805, self.error_tolerance, "Annual energy.")
            var capacity_factor: Float64 = ssc_data_get_number(self.data, "capacity_factor")
            expect_near(capacity_factor, 18.62, 0.1, "Capacity factor")
        self.TearDown()

    def LifetimeModeTest_cmod_pvwattsv7(inout self):
        self.SetUp()
        var pairs = Dict[String, Float64]()
        pairs["system_use_lifetime_output"] = 1
        pairs["analysis_period"] = 25
        var dc_degradation_single = List[Float64](1)
        dc_degradation_single[0] = 0.5
        ssc_data_set_array(self.data, "dc_degradation", dc_degradation_single, 1)
        var pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
        assert not pvwatts_errors
        if not pvwatts_errors:
            var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
            expect_near(annual_energy, 6999.016, self.error_tolerance, "Annual energy degradation array length 1.")
        var dc_degradation = List[Float64](25)
        for i in range(25):
            dc_degradation[i] = 0.5
        ssc_data_set_array(self.data, "dc_degradation", dc_degradation, 25)
        pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
        assert not pvwatts_errors
        if not pvwatts_errors:
            var annual_energy: Float64 = ssc_data_get_number(self.data, "annual_energy")
            expect_near(annual_energy, 6963.977, self.error_tolerance, "Annual energy degradation array length 25.")
        var dc_degradation_fail = List[Float64](22)
        for i in range(22):
            dc_degradation_fail[i] = 0.5
        ssc_data_set_array(self.data, "dc_degradation", dc_degradation_fail, 22)
        pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
        assert pvwatts_errors  # EXPECT_TRUE(pvwatts_errors) -> should be true
        self.TearDown()

    def BifacialTest_cmod_pvwattsv7(inout self):
        self.SetUp()
        var pairs = Dict[String, Float64]()
        pairs["bifaciality"] = 0.0
        var annual_energy_mono: Float64 = 0.0
        var annual_energy_bi: Float64 = 0.0
        var pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
        assert not pvwatts_errors
        if not pvwatts_errors:
            annual_energy_mono = ssc_data_get_number(self.data, "annual_energy")
            expect_near(annual_energy_mono, 6999, 1, "System with bifaciality")
        pairs["bifaciality"] = 0.65
        pvwatts_errors = modify_ssc_data_and_run_module(self.data, "pvwattsv7", pairs)
        assert not pvwatts_errors
        if not pvwatts_errors:
            annual_energy_bi = ssc_data_get_number(self.data, "annual_energy")
        # EXPECT_GT
        assert (annual_energy_bi / annual_energy_mono) > 1.04
        self.TearDown()

    # SnowModelTest is commented out, so we skip it.

    def NonAnnual(inout self):
        self.SetUp()
        var weather_data = create_weatherdata_array(24)
        ssc_data_unassign(self.data, "solar_resource_file")
        ssc_data_set_table(self.data, "solar_resource_data", weather_data.table)
        assert not run_module(self.data, "pvwattsv7")
        var dc: Float64 = ssc_data_get_array(self.data, "dc")[12]
        expect_near(dc, 2512.300, 0.01, "DC Energy at noon")
        var gen: Float64 = ssc_data_get_array(self.data, "gen")[12]
        expect_near(gen, 2.417, 0.01, "Gen at noon")
        free_weatherdata_array(weather_data)
        self.TearDown()

def expect_near(actual: Float64, expected: Float64, tolerance: Float64, msg: String):
    if abs(actual - expected) > tolerance:
        print(msg + " failed: actual=", actual, " expected=", expected, " tolerance=", tolerance)
        assert False

def main():
    var test = CMPvwattsV7Integration_cmod_pvwattsv7()
    test.DefaultNoFinancialModel_cmod_pvwattsv7()
    test.DifferentTechnologyInputs_cmod_pvwattsv7()
    test.LargeSystem_cmod_pvwattsv7()
    test.SubhourlyWeather_cmod_pvwattsv7()
    test.LifetimeModeTest_cmod_pvwattsv7()
    test.BifacialTest_cmod_pvwattsv7()
    test.NonAnnual()
    print("All tests passed.")