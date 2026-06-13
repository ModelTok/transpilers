from trough_physical_defaults import *
from csp_common_test import *
from vs_google_test_explorer_namespace import *

@value
struct EXPECT_FALSE:
    def __init__(condition: Bool) raises:
        if condition:
            raise Error("EXPECT_FALSE failed")

@value
struct EXPECT_NEAR_FRAC:
    def __init__(actual: Float64, expected: Float64, tol: Float64) raises:
        if abs(actual - expected) > tol:
            raise Error("EXPECT_NEAR_FRAC failed")

namespace csp_trough:
    struct PowerTroughCmod:
        @staticmethod
        def Default_NoFinancial() raises:
            var defaults: ssc_data_t = trough_physical_defaults()
            var power_trough: CmodUnderTest = CmodUnderTest("trough_physical", defaults)
            var errors: Int = power_trough.RunModule()
            EXPECT_FALSE(errors)
            if not errors:
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_energy"), 369272759, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_thermal_consumption"), 596547, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_tes_freeze_protection"), 558505, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_field_freeze_protection"), 38042, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("capacity_factor"), 42.20, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_W_cycle_gross"), 420379150, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("kwh_per_kw"), 3696, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("conversion_factor"), 87.84, kErrorToleranceLo)
                EXPECT_NEAR_FRAC(power_trough.GetOutput("annual_total_water_use"), 80708, kErrorToleranceLo)