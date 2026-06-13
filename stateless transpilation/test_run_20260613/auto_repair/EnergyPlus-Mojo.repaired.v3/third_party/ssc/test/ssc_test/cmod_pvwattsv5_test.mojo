from gtest import Test, TestFixture, EXPECT_FALSE, EXPECT_NEAR, EXPECT_TRUE
from ...ssc.core import ssc_data_t, ssc_data_create, ssc_data_free, ssc_data_get_array, ssc_data_get_number, ssc_data_set_number, ssc_data_set_table, ssc_data_unassign, ssc_module_t, ssc_module_create, ssc_module_exec, ssc_module_free, ssc_number_t
from vartab import vartab
from ...ssc.common import common
from ...input_cases.pvwattsv5_cases import pvwattsv5_nofinancial_testfile, modify_ssc_data_and_run_module
from input_cases.weather_inputs import create_weatherdata_array, free_weatherdata_array

@value
class CMPvwattsV5Integration_cmod_pvwattsv5(TestFixture):
    var data: ssc_data_t
    var error_tolerance: Float64 = 1.0e-2

    def SetUp(inout self):
        self.data = ssc_data_create()
        var errors: Int = pvwattsv5_nofinancial_testfile(self.data)
        EXPECT_FALSE(errors)

    def TearDown(inout self):
        ssc_data_free(self.data)
        self.data = ssc_data_t()

    def compute(inout self) -> Bool:
        var module: ssc_module_t = ssc_module_create("pvwattsv5")
        if module is None:
            print("error: could not create 'pvwattsv5' module.")
            ssc_data_free(self.data)
            return False
        if ssc_module_exec(module, self.data) == 0:
            print("error during simulation.")
            ssc_module_free(module)
            ssc_data_free(self.data)
            return False
        ssc_module_free(module)
        return True

def test_DefaultNoFinancialModel():
    var fixture = CMPvwattsV5Integration_cmod_pvwattsv5()
    fixture.SetUp()
    fixture.compute()
    var tmp: Float64 = 0.0
    var count: Int
    var monthly_energy_ptr = ssc_data_get_array(fixture.data, "monthly_energy", count)
    for i in range(12):
        tmp += Float64(monthly_energy_ptr[i])
    EXPECT_NEAR(tmp, 6908.027, fixture.error_tolerance)  # Annual energy.
    EXPECT_NEAR(Float64(monthly_energy_ptr[0]), 435.198, fixture.error_tolerance)  # Monthly energy of January
    EXPECT_NEAR(Float64(monthly_energy_ptr[1]), 482.681, fixture.error_tolerance)  # Monthly energy of February
    EXPECT_NEAR(Float64(monthly_energy_ptr[2]), 593.864, fixture.error_tolerance)  # Monthly energy of March
    EXPECT_NEAR(Float64(monthly_energy_ptr[3]), 673.452, fixture.error_tolerance)  # Monthly energy of April
    EXPECT_NEAR(Float64(monthly_energy_ptr[4]), 715.823, fixture.error_tolerance)  # Monthly energy of May
    EXPECT_NEAR(Float64(monthly_energy_ptr[5]), 665.008, fixture.error_tolerance)  # Monthly energy of June
    EXPECT_NEAR(Float64(monthly_energy_ptr[6]), 665.698, fixture.error_tolerance)  # Monthly energy of July
    EXPECT_NEAR(Float64(monthly_energy_ptr[7]), 647.621, fixture.error_tolerance)  # Monthly energy of August
    EXPECT_NEAR(Float64(monthly_energy_ptr[8]), 594.314, fixture.error_tolerance)  # Monthly energy of September
    EXPECT_NEAR(Float64(monthly_energy_ptr[9]), 568.281, fixture.error_tolerance)  # Monthly energy of October
    EXPECT_NEAR(Float64(monthly_energy_ptr[10]), 453.305, fixture.error_tolerance)  # Monthly energy of November
    EXPECT_NEAR(Float64(monthly_energy_ptr[11]), 412.782, fixture.error_tolerance)  # Month energy of December
    var capacity_factor: ssc_number_t
    ssc_data_get_number(fixture.data, "capacity_factor", capacity_factor)
    EXPECT_NEAR(capacity_factor, 19.715, fixture.error_tolerance)  # Capacity factor
    fixture.TearDown()

def test_UsingData():
    var fixture = CMPvwattsV5Integration_cmod_pvwattsv5()
    fixture.SetUp()
    var weather_data = create_weatherdata_array(8760)
    ssc_data_unassign(fixture.data, "solar_resource_file")
    ssc_data_set_table(fixture.data, "solar_resource_data", weather_data.table)
    fixture.compute()
    var capacity_factor: ssc_number_t
    ssc_data_get_number(fixture.data, "capacity_factor", capacity_factor)
    EXPECT_NEAR(capacity_factor, 11.7360, fixture.error_tolerance)  # Capacity factor
    free_weatherdata_array(weather_data)
    fixture.TearDown()

def test_DifferentTechnologyInputs():
    var fixture = CMPvwattsV5Integration_cmod_pvwattsv5()
    fixture.SetUp()
    var annual_energy_expected = List[Float64](6908.02, 7121.52, 7334.71, 6908.02, 6802.62, 8584.29, 8721.18, 9687.18)
    var pairs = Dict[String, Float64]()
    var count: Int = 0
    for module_type in range(3):
        pairs["module_type"] = Float64(module_type)
        var pvwatts_errors = modify_ssc_data_and_run_module(fixture.data, "pvwattsv5", pairs)
        EXPECT_FALSE(pvwatts_errors)
        if not pvwatts_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(fixture.data, "annual_energy", annual_energy)
            EXPECT_NEAR(annual_energy, annual_energy_expected[count], fixture.error_tolerance)  # Annual energy.
        count += 1
    for array_type in range(5):
        pairs["module_type"] = 0.0  # reset module type to its default value
        pairs["array_type"] = Float64(array_type)
        var pvwatts_errors = modify_ssc_data_and_run_module(fixture.data, "pvwattsv5", pairs)
        EXPECT_FALSE(pvwatts_errors)
        if not pvwatts_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(fixture.data, "annual_energy", annual_energy)
            EXPECT_NEAR(annual_energy, annual_energy_expected[count], fixture.error_tolerance)  # Annual energy.
        count += 1
    fixture.TearDown()

def test_LargeSystem_cmod_pvwattsv5():
    var fixture = CMPvwattsV5Integration_cmod_pvwattsv5()
    fixture.SetUp()
    var annual_energy_expected = List[Float64](1727006, 1700656, 2146072, 2180297, 2421795)
    var pairs = Dict[String, Float64]()
    var count: Int = 0
    fixture.error_tolerance = 0.1  # use a larger error tolerance for large numbers
    pairs["system_capacity"] = 1000.0  # 1 MW system
    for array_type in range(5):
        pairs["array_type"] = Float64(array_type)
        var pvwatts_errors = modify_ssc_data_and_run_module(fixture.data, "pvwattsv5", pairs)
        EXPECT_FALSE(pvwatts_errors)
        if not pvwatts_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(fixture.data, "annual_energy", annual_energy)
            EXPECT_NEAR(annual_energy, annual_energy_expected[count], 1.0)  # Annual energy.
        count += 1
    fixture.TearDown()

def test_singleTS():
    var data_1ts = ssc_data_create()
    ssc_data_set_number(data_1ts, "alb", 0.2)
    ssc_data_set_number(data_1ts, "beam", 0.612)
    ssc_data_set_number(data_1ts, "day", 6)
    ssc_data_set_number(data_1ts, "diffuse", 162.91)
    ssc_data_set_number(data_1ts, "hour", 13)
    ssc_data_set_number(data_1ts, "lat", 39.744)
    ssc_data_set_number(data_1ts, "lon", -105.1778)
    ssc_data_set_number(data_1ts, "minute", 20)
    ssc_data_set_number(data_1ts, "month", 1)
    ssc_data_set_number(data_1ts, "tamb", 10.79)
    ssc_data_set_number(data_1ts, "tz", -7)
    ssc_data_set_number(data_1ts, "wspd", 1.4500)
    ssc_data_set_number(data_1ts, "year", 2019)
    ssc_data_set_number(data_1ts, "array_type", 2)
    ssc_data_set_number(data_1ts, "azimuth", 180)
    ssc_data_set_number(data_1ts, "dc_ac_ratio", 1.2)
    ssc_data_set_number(data_1ts, "gcr", 0.4)
    ssc_data_set_number(data_1ts, "inv_eff", 96)
    ssc_data_set_number(data_1ts, "losses", 0)
    ssc_data_set_number(data_1ts, "module_type", 0)
    ssc_data_set_number(data_1ts, "system_capacity", 720)
    ssc_data_set_number(data_1ts, "tilt", 0)
    var mod = ssc_module_create("pvwattsv5_1ts")
    EXPECT_TRUE(ssc_module_exec(mod, data_1ts))
    var val: Float64
    ssc_data_get_number(data_1ts, "poa", val)
    EXPECT_NEAR(val, 140.21, 0.1)
    ssc_data_get_number(data_1ts, "tcell", val)
    EXPECT_NEAR(val, 12.77, 0.1)
    ssc_data_get_number(data_1ts, "dc", val)
    EXPECT_NEAR(val, 106739, 1)
    ssc_data_get_number(data_1ts, "ac", val)
    EXPECT_NEAR(val, 100852, 1)
    EXPECT_TRUE(ssc_module_exec(mod, data_1ts))
    ssc_data_get_number(data_1ts, "poa", val)
    EXPECT_NEAR(val, 140.21, 0.1)
    ssc_data_get_number(data_1ts, "tcell", val)
    EXPECT_NEAR(val, 13.36, 0.1)
    ssc_data_get_number(data_1ts, "dc", val)
    EXPECT_NEAR(val, 106460, 1)
    ssc_data_get_number(data_1ts, "ac", val)
    EXPECT_NEAR(val, 100579, 1)
    ssc_data_set_number(data_1ts, "shaded_percent", 50)
    EXPECT_TRUE(ssc_module_exec(mod, data_1ts))
    ssc_data_get_number(data_1ts, "poa", val)
    EXPECT_NEAR(val, 140.05, 0.1)
    ssc_data_get_number(data_1ts, "tcell", val)
    EXPECT_NEAR(val, 13.36, 0.1)
    ssc_data_get_number(data_1ts, "dc", val)
    EXPECT_NEAR(val, 106342, 1)
    ssc_data_get_number(data_1ts, "ac", val)
    EXPECT_NEAR(val, 100464, 1)
    ssc_data_free(data_1ts)

def main():
    test_DefaultNoFinancialModel()
    test_UsingData()
    test_DifferentTechnologyInputs()
    test_LargeSystem_cmod_pvwattsv5()
    test_singleTS()