from tcsmolten_salt_defaults import tcsmolten_salt_defaults
from cmod_csp_tower_eqns import *
from csp_common_test import *
from vs_google_test_explorer_namespace import *

# Namespace csp_tower
# using namespace csp_tower;

def csp_tower_PowerTowerCmod_Default_NoFinancial():
    var defaults: ssc_data_t = tcsmolten_salt_defaults()
    var power_tower: CmodUnderTest = CmodUnderTest("tcsmolten_salt", defaults)
    var errors: Int = power_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_energy"), 571408807, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("land_area_base"), 1847, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("capacity_factor"), 63.02, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_W_cycle_gross"), 638478912, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("kwh_per_kw"), 5521, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("conversion_factor"), 89.55, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("N_hel"), 8790, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("rec_height"), 21.60, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("A_sf"), 1269054, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("D_rec"), 17.65, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_total_water_use"), 98402, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("csp.pt.cost.total_land_area"), 1892, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("h_tower"), 193.5, kErrorToleranceLo)

def csp_tower_PowerTowerCmod_SlidingPressure_NoFinancial():
    var defaults: ssc_data_t = tcsmolten_salt_defaults()
    var power_tower: CmodUnderTest = CmodUnderTest("tcsmolten_salt", defaults)
    power_tower.SetInput("tech_type", 3)          # change to sliding pressure
    var errors: Int = power_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_energy"), 578111750, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("land_area_base"), 1847, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("capacity_factor"), 63.76, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_W_cycle_gross"), 645396296, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("kwh_per_kw"), 5586, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("conversion_factor"), 89.57, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("N_hel"), 8790, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("rec_height"), 21.60, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("A_sf"), 1269054, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("D_rec"), 17.65, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_total_water_use"), 98238, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("csp.pt.cost.total_land_area"), 1892, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("h_tower"), 193.5, kErrorToleranceLo)

def csp_tower_PowerTowerCmod_FlowPattern_NoFinancial():
    var defaults: ssc_data_t = tcsmolten_salt_defaults()
    var power_tower: CmodUnderTest = CmodUnderTest("tcsmolten_salt", defaults)
    power_tower.SetInput("Flow_type", 8)
    var errors: Int = power_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_energy"), 519995603, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("land_area_base"), 1847, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("capacity_factor"), 57.35, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_W_cycle_gross"), 642716926, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("kwh_per_kw"), 5024, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("conversion_factor"), 80.90, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("N_hel"), 8790, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("rec_height"), 21.60, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("A_sf"), 1269054, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("D_rec"), 17.65, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("annual_total_water_use"), 98678, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("csp.pt.cost.total_land_area"), 1892, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(power_tower.GetOutput("h_tower"), 193.5, kErrorToleranceLo)

def CopyVarTableAndGetValue(vartab: Pointer[var_table], var_name: String, var_value: Pointer[Float64]):
    var vartab_copy: var_table = vartab[]  # uses copy assignment operator, which is fine
    var_value[] = vartab[].as_double(var_name)
    return

def csp_tower_PowerTowerCmod_CopyingVarTable():
    var data: ssc_data_t = tcsmolten_salt_defaults()
    var vartab: Pointer[var_table] = data  # static_cast<var_table*>(data)
    var test_variable_name: String = "tower_exp"
    var test_value: Float64 = vartab[].as_double(test_variable_name)
    var test_value_from_orig_table_after_copied: Float64
    CopyVarTableAndGetValue(vartab, test_variable_name, Pointer[Float64](address_of(test_value_from_orig_table_after_copied)))
    var test_value_from_orig_table_after_copied_and_fun_returned: Float64
    try:
        test_value_from_orig_table_after_copied_and_fun_returned = vartab[].as_double(test_variable_name)       # throws error
    except:
        test_value_from_orig_table_after_copied_and_fun_returned = Float64.nan
    ASSERT_DOUBLE_EQ(test_value, test_value_from_orig_table_after_copied)
    ASSERT_DOUBLE_EQ(test_value, test_value_from_orig_table_after_copied_and_fun_returned)