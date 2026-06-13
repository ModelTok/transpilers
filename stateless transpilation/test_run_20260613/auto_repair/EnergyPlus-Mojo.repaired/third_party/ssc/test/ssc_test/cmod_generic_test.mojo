from gtest import Test, TestFixture, EXPECT_FALSE, EXPECT_TRUE
from cmod_generic_test import CMGeneric
from sscapi import ssc_data_create, ssc_data_free, ssc_data_get_number, ssc_data_get_array, ssc_data_set_number
from vartab import set_array, run_module
from ...input_cases.generic_common_data import generictest

@register_test_fixture("CMGeneric")
class CMGenericTest(CMGeneric):

def SingleOwnerWithBattery_cmod_generic():
    var data = ssc_data_create()
    generic_singleowner_battery_60min(data)
    var dispatch_options = List[Int](0, 1, 3, 4)
    for i in range(len(dispatch_options)):
        ssc_data_set_number(data, "batt_dispatch_choice", dispatch_options[i])
        EXPECT_FALSE(run_module(data, "generic_system"))
        EXPECT_FALSE(run_module(data, "battery"))
        EXPECT_FALSE(run_module(data, "singleowner"))
    set_array(data, "energy_output_array", generictest.gen_path_30min, 8760 * 2)
    set_array(data, "batt_custom_dispatch", generictest.batt_dispatch_path_30min, 8760 * 2)
    set_array(data, "batt_room_temperature_celsius", generictest.temperature_path_30min, 8760 * 2)
    for i in range(len(dispatch_options)):
        ssc_data_set_number(data, "batt_dispatch_choice", dispatch_options[i])
        EXPECT_FALSE(run_module(data, "generic_system"))
        EXPECT_FALSE(run_module(data, "battery"))
        EXPECT_FALSE(run_module(data, "singleowner"))
    ssc_data_set_number(data, "batt_dispatch_choice", 3)
    set_array(data, "batt_custom_dispatch", generictest.batt_dispatch_path_30min, 8760 * 2)
    EXPECT_FALSE(run_module(data, "generic_system"))
    EXPECT_FALSE(run_module(data, "battery"))
    ssc_data_free(data)

def CommercialWithBattery_cmod_generic():
    var data = ssc_data_create()
    generic_commerical_battery_60min(data)
    var dispatch_options = List[Int](0, 3, 4)
    for l in range(2):
        ssc_data_set_number(data, "system_use_lifetime_output", l)
        for i in range(len(dispatch_options)):
            ssc_data_set_number(data, "batt_dispatch_choice", dispatch_options[i])
            EXPECT_FALSE(run_module(data, "generic_system"))
            EXPECT_FALSE(run_module(data, "battery"))
            EXPECT_FALSE(run_module(data, "utilityrate5"))
            EXPECT_FALSE(run_module(data, "cashloan"))
    set_array(data, "energy_output_array", generictest.gen_path_30min, 8760 * 2)
    set_array(data, "batt_custom_dispatch", generictest.batt_dispatch_path_30min, 8760 * 2)
    set_array(data, "batt_room_temperature_celsius", generictest.temperature_path_30min, 8760 * 2)
    set_array(data, "load", generictest.load_profile_path_30min, 8760 * 2)
    for l in range(2):
        ssc_data_set_number(data, "system_use_lifetime_output", l)
        for i in range(len(dispatch_options)):
            ssc_data_set_number(data, "batt_dispatch_choice", dispatch_options[i])
            EXPECT_FALSE(run_module(data, "generic_system"))
            EXPECT_FALSE(run_module(data, "battery"))
            EXPECT_FALSE(run_module(data, "utilityrate5"))
            EXPECT_FALSE(run_module(data, "cashloan"))
    ssc_data_set_number(data, "batt_dispatch_choice", 3)
    set_array(data, "batt_custom_dispatch", generictest.batt_dispatch_path_30min, 8760 * 2)
    set_array(data, "energy_output_array", generictest.gen_path_30min, 2 * 8760)
    set_array(data, "batt_room_temperature_celsius", generictest.temperature_path_30min, 8760 * 2)
    set_array(data, "load", generictest.load_profile_path_60min, 8760)
    for l in range(2):
        ssc_data_set_number(data, "system_use_lifetime_output", l)
        EXPECT_FALSE(run_module(data, "generic_system"))
        EXPECT_FALSE(run_module(data, "battery"))
    ssc_data_free(data)

# Doesn't work to to outdated exeception handling methods in SSC which can not be 
# handled robustly in a cross-platform environment
# https://docs.microsoft.com/en-us/cpp/cpp/errors-and-exception-handling-modern-cpp?view=vs-2017#c-exceptions-versus-windows-seh-exceptions
# 
# TEST_F(CMGeneric, CommericalWithBatteryWrongSizes)
# {
# 	generic_commerical_battery_60min(data);
# 	set_array(data, "load", generictest::load_profile_path_30min, 2 * 8760);
# 	EXPECT_TRUE(run_module(data, "generic_system"));
# 	EXPECT_TRUE(run_module(data, "battery"));
# }