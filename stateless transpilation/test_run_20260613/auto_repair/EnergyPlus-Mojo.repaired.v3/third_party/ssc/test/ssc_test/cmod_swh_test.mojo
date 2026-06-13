from gtest import Test, TestFixture, ASSERT_EQ, EXPECT_NEAR
from cmod_swh_test import CM_SWH
from input_cases.weather_inputs import create_weatherdata_array, free_weatherdata_array

@register_test_fixture(CM_SWH)
class TestResidentialDefault_cmod_swh(Test[CM_SWH]):
    def run_test(self) -> None:
        var swh_errors: int = run_module(self.data, "swh")
        ASSERT_EQ(swh_errors, 0)
        var annual_energy: ssc_number_t
        ssc_data_get_number(self.data, "annual_energy", &annual_energy)
        EXPECT_NEAR(annual_energy, 2362.2, 0.1)

@register_test_fixture(CM_SWH)
class TestResidentialDefaultUsingData_cmod_swh(Test[CM_SWH]):
    def run_test(self) -> None:
        var weather_data = create_weatherdata_array(8760)
        ssc_data_unassign(self.data, "solar_resource_file")
        ssc_data_set_table(self.data, "solar_resource_data", &weather_data.table)
        var swh_errors: int = run_module(self.data, "swh")
        ASSERT_EQ(swh_errors, 0)
        var annual_energy: ssc_number_t
        ssc_data_get_number(self.data, "annual_energy", &annual_energy)
        EXPECT_NEAR(annual_energy, 1229, 1)
        free_weatherdata_array(weather_data)