from gtest import Test
from core import *
from sscapi import *
from vartab import *
from ...ssc.common import *
from ...input_cases.biomass_common import *
from ...input_cases.code_generator_utilities import *

@value
struct CMBiomass(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]

    def SetUp(inout self):
        self.data = ssc_data_create()
        biomass_commondata(self.data)

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = Pointer[ssc_data_t]()

def SingleOwnerDefault_cmod_biomass():
    var biopower_errors = run_module(CMBiomass.data, "biomass")
    ASSERT_EQ(biopower_errors, 0)
    var annual_energy: ssc_number_t
    ssc_data_get_number(CMBiomass.data, "annual_energy", Pointer[ssc_number_t](address_of(annual_energy)))
    EXPECT_NEAR(annual_energy, 353982820.997, 0.1)