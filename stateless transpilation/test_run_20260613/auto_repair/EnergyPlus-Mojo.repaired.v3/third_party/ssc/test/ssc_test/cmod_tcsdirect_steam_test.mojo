from testing import *
from tcsdirect_steam_defaults import tcsdirect_steam_defaults
from csp_common_test import CmodUnderTest, EXPECT_NEAR_FRAC, kErrorToleranceLo
from vs_google_test_explorer_namespace import NAMESPACE_TEST

@NAMESPACE_TEST("csp_tower", "SteamTowerCmod", "Default_NoFinancial")
def test_Default_NoFinancial():
    var defaults = tcsdirect_steam_defaults()
    var steam_tower = CmodUnderTest("tcsdirect_steam", defaults)
    var errors = steam_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_energy"), 263809742, kErrorToleranceLo)
        EXPECT_NEAR(steam_tower.GetOutput("annual_fuel_usage"), 0., kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("capacity_factor"), 30.08, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_W_cycle_gross"), 296630582, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("kwh_per_kw"), 2635, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("conversion_factor"), 92.64, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_total_water_use"), 55716, kErrorToleranceLo)

@NAMESPACE_TEST("csp_tower", "SteamTowerCmod", "EvaporativeCondenser_NoFinancial")
def test_EvaporativeCondenser_NoFinancial():
    var defaults = tcsdirect_steam_defaults()
    var steam_tower = CmodUnderTest("tcsdirect_steam", defaults)
    steam_tower.SetInput("ct", 1)
    steam_tower.SetInput("eta_ref", 0.404)
    steam_tower.SetInput("startup_frac", 0.5)
    steam_tower.SetInput("P_cond_min", 2)
    var errors = steam_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_energy"), 280975356, kErrorToleranceLo)
        EXPECT_NEAR(steam_tower.GetOutput("annual_fuel_usage"), 0., kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("capacity_factor"), 32.03, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_W_cycle_gross"), 307624737, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("kwh_per_kw"), 2806, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("conversion_factor"), 95.14, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_total_water_use"), 893431, kErrorToleranceLo)

@NAMESPACE_TEST("csp_tower", "SteamTowerCmod", "HybridCondenser_NoFinancial")
def test_HybridCondenser_NoFinancial():
    var defaults = tcsdirect_steam_defaults()
    var steam_tower = CmodUnderTest("tcsdirect_steam", defaults)
    steam_tower.SetInput("ct", 3)
    steam_tower.SetInput("eta_ref", 0.404)
    steam_tower.SetInput("startup_frac", 0.5)
    steam_tower.SetInput("P_cond_min", 2)
    var errors = steam_tower.RunModule()
    EXPECT_FALSE(errors)
    if not errors:
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_energy"), 268116066, kErrorToleranceLo)
        EXPECT_NEAR(steam_tower.GetOutput("annual_fuel_usage"), 0., kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("capacity_factor"), 30.57, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_W_cycle_gross"), 304066728, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("kwh_per_kw"), 2678, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("conversion_factor"), 91.85, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("system_heat_rate"), 3.413, kErrorToleranceLo)
        EXPECT_NEAR_FRAC(steam_tower.GetOutput("annual_total_water_use"), 55716, kErrorToleranceLo)