from tcsfresnel_molten_salt_defaults import tcsfresnel_molten_salt_defaults
from csp_common_test import CmodUnderTest, EXPECT_FALSE, EXPECT_NEAR, EXPECT_NEAR_FRAC, kErrorToleranceLo
from vs_google_test_explorer_namespace import NAMESPACE_TEST

# namespace csp_tower {}
# using namespace csp_tower;

module csp_fresnel:
    def PowerFresnelCmod_Default_NoFinancial():
        var defaults: ssc_data_t = tcsfresnel_molten_salt_defaults()
        var power_fresnel = CmodUnderTest("tcsmslf", defaults)
        var errors = power_fresnel.RunModule()
        EXPECT_FALSE(errors)
        if not errors:
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_energy"), 337249089, kErrorToleranceLo)
            EXPECT_NEAR(power_fresnel.GetOutput("annual_fuel_usage"), 0, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("capacity_factor"), 38.50, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_W_cycle_gross"), 372639466, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("kwh_per_kw"), 3372, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("conversion_factor"), 94.27, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_total_water_use"), 30058, kErrorToleranceLo)

    def PowerFresnelCmod_SequencedDefocusing_NoFinancial():
        var defaults: ssc_data_t = tcsfresnel_molten_salt_defaults()
        var power_fresnel = CmodUnderTest("tcsmslf", defaults)
        power_fresnel.SetInput("fthrctrl", 1)
        var errors = power_fresnel.RunModule()
        EXPECT_FALSE(errors)
        if not errors:
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_energy"), 337249089, kErrorToleranceLo)
            EXPECT_NEAR(power_fresnel.GetOutput("annual_fuel_usage"), 0, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("capacity_factor"), 38.50, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_W_cycle_gross"), 372639466, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("kwh_per_kw"), 3372, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("conversion_factor"), 94.27, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_total_water_use"), 30058, kErrorToleranceLo)

    def PowerFresnelCmod_TherminolVp1Htf_NoFinancial():
        var defaults: ssc_data_t = tcsfresnel_molten_salt_defaults()
        var power_fresnel = CmodUnderTest("tcsmslf", defaults)
        power_fresnel.SetInput("Fluid", 21)
        power_fresnel.SetInput("field_fluid", 21)
        power_fresnel.SetInput("is_hx", 1)
        power_fresnel.SetInput("V_tank_hot_ini", 1290.5642)
        power_fresnel.SetInput("vol_tank", 6452.821)
        var errors = power_fresnel.RunModule()
        EXPECT_FALSE(errors)
        if not errors:
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_energy"), 336171001, kErrorToleranceLo)
            EXPECT_NEAR(power_fresnel.GetOutput("annual_fuel_usage"), 0, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("capacity_factor"), 38.38, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_W_cycle_gross"), 371306661, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("kwh_per_kw"), 3362, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("conversion_factor"), 94.31, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_total_water_use"), 29944, kErrorToleranceLo)

    def PowerFresnelCmod_SolarPositioinOpticalChar_NoFinancial():
        var defaults: ssc_data_t = tcsfresnel_molten_salt_defaults()
        var power_fresnel = CmodUnderTest("tcsmslf", defaults)
        power_fresnel.SetInput("opt_model", 1)
        var errors = power_fresnel.RunModule()
        EXPECT_FALSE(errors)
        if not errors:
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_energy"), 228344862, kErrorToleranceLo)
            EXPECT_NEAR(power_fresnel.GetOutput("annual_fuel_usage"), 0, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("capacity_factor"), 26.07, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_W_cycle_gross"), 255036717, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("kwh_per_kw"), 2283, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("conversion_factor"), 93.26, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
            EXPECT_NEAR_FRAC(power_fresnel.GetOutput("annual_total_water_use"), 21776, kErrorToleranceLo)