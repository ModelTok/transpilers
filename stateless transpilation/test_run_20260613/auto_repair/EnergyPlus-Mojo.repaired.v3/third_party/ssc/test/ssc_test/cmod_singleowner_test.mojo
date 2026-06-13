# Mojo translation of cmod_singleowner_test.cpp
# Faithful 1:1 translation, no refactoring

from gtest import gtest  # Mock gtest import; equivalent to gtest/gtest.h
from core import *
from sscapi import ssc_data_t, ssc_number_t, ssc_data_create, ssc_data_free, ssc_data_get_number
from vartab import *
from ...ssc.common import run_module, ssc_number_t_ptr
from ...input_cases.singleowner_common import singleowner_common
from ...input_cases.code_generator_utilities import *

# Define alias for ssc_number_t (double)
alias ssc_number_t = Float64

# Define ASSERT_EQ and EXPECT_NEAR as simple assertion functions (1:1 translation)
def ASSERT_EQ(actual: Int, expected: Int) raises:
    assert actual == expected, "ASSERT_EQ failed"

def EXPECT_NEAR(actual: Float64, expected: Float64, tolerance: Float64) raises:
    assert abs(actual - expected) <= tolerance, "EXPECT_NEAR failed"

# Class definition from header
class CMSingleOwner:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]

    def __init__(inout self):
        self.data = ssc_data_create()
        singleowner_common(self.data)
        self.calculated_value = 0.0
        self.calculated_array = Pointer[ssc_number_t]()

    def SetUp(inout self):
        self.data = ssc_data_create()
        singleowner_common(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None

    # Test function (TEST_F equivalent)
    def ResidentialDefault_cmod_swh(inout self) raises:
        self.SetUp()
        var errors: Int = run_module(self.data, "singleowner")
        ASSERT_EQ(errors, 0)
        var npv: ssc_number_t
        ssc_data_get_number(self.data, "project_return_aftertax_npv", Pointer[ssc_number_t](address_of(npv)))
        EXPECT_NEAR(npv, -647727751.2, 0.1)
        self.TearDown()