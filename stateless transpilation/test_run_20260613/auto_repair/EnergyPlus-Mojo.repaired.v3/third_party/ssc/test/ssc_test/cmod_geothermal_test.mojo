from core import *
from sscapi import *
from vartab import *
from ...ssc.common import *
from ...input_cases.geothermal_common_data import *
from ...input_cases.code_generator_utilities import *

# --- Minimal test-macro replacements (faithful to C++ names) ---
def ASSERT_EQ(a: Int, b: Int):
    if a != b:
        print("ASSERT_EQ failed: ", a, " != ", b)
        abort()

def EXPECT_EQ(a: Int, b: Int):
    if a != b:
        print("EXPECT_EQ failed: ", a, " != ", b)

def EXPECT_NEAR(val: Float64, expected: Float64, tol: Float64):
    if abs(val - expected) > tol:
        print("EXPECT_NEAR failed: ", val, " not near ", expected, " (tol=", tol, ")")

def EXPECT_GE(val: Float64, lower: Float64):
    if val < lower:
        print("EXPECT_GE failed: ", val, " < ", lower)

struct CMGeothermal:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]

    def SetUp(inout self):
        self.data = ssc_data_create()
        geothermal_singleowner_default(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_clear(self.data)

def SingleOwnerDefault_cmod_geothermal():
    var fixture: CMGeothermal
    fixture.SetUp()
    var geo_errors = run_module(fixture.data, "geothermal")
    ASSERT_EQ(geo_errors, 0)
    var grid_errors = run_module(fixture.data, "grid")
    EXPECT_EQ(grid_errors, 0)
    var singleowner_errors = run_module(fixture.data, "singleowner")
    EXPECT_EQ(singleowner_errors, 0)
    if not geo_errors:   //(!=geothermal_errors) == True;
        var annual_energy: ssc_number_t
        var eff_secondlaw: ssc_number_t
        ssc_data_get_number(fixture.data, "annual_energy", &annual_energy)
        ssc_data_get_number(fixture.data, "eff_secondlaw", &eff_secondlaw)
        EXPECT_NEAR(annual_energy, 262800000, 0.1)
        EXPECT_GE(eff_secondlaw, 0)
    fixture.TearDown()