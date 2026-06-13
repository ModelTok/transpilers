from gtest import ASSERT_EQ, EXPECT_NEAR
from core import ssc_data_t, ssc_number_t
from sscapi import ssc_data_create, ssc_data_get_number, ssc_data_get_array, ssc_data_clear
from ...ssc.common import run_module
from ...input_cases.geothermal_costs_common_data import geothermal_costs_default

/**
 * CMGeothermalCosts tests the cmod_geothermal_costs. SAM code generator cannot be used to generate data for this module since it is
 * a derived cmod of cmod_geothermal. This means that all the data required to run this cmod is a subset of data created using SAM
 * code generator. The geothermal_costs_default() function in "../input_cases/geothermal_costs_common_data.h" is a data container for the 
 * data used in this particular cmod (which was obatined using the code generator). 
 * Eventually a method can be written to write this data to a vartable so that lower-level methods of pvsamv1 can be tested
 * For now, this uses the SSCAPI interfaces to run the compute module and compare results
 */
struct CMGeothermalCosts:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: ssc_number_t*

    def __init__(inout self):
        self.data = ssc_data_create()
        self.calculated_value = 0
        self.calculated_array = None

    def SetUp(inout self):
        self.data = ssc_data_create() //Data structure for cmod_geothermal_costs
        geothermal_costs_default(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_clear(self.data)

    def SetCalculated(inout self, name: String):
        ssc_data_get_number(self.data, name, &self.calculated_value)

    def SetCalculatedArray(inout self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, &n)

def CostModuleTest_cmod_geothermal_costs() raises:
    var fixture = CMGeothermalCosts()
    fixture.SetUp()
    defer: fixture.TearDown()
    var geothermal_errors = run_module(fixture.data, "geothermal_costs")
    ASSERT_EQ(geothermal_errors, 0)
    var baseline_cost: ssc_number_t
    ssc_data_get_number(fixture.data, "baseline_cost", &baseline_cost)
    EXPECT_NEAR(baseline_cost, 2300, 100)