from gtest import Test, TestWithParam, ASSERT_EQ, EXPECT_NEAR
from ...test.input_cases.mhk.mhk_wave_inputs import wave_inputs
from core import run_module
from sscapi import ssc_data_t, ssc_number_t, ssc_data_create, ssc_data_clear, ssc_data_get_number, ssc_data_get_array

class CM_MHKWave(Test):
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]

    def SetUp(self):
        self.data = ssc_data_create()
        wave_inputs(self.data)

    def TearDown(self):
        if self.data:
            ssc_data_clear(self.data)

    def SetCalculated(self, name: String):
        ssc_data_get_number(self.data, name, self.calculated_value)

    def SetCalculatedArray(self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, n)

def ComputeModuleTest_cmod_mhk_wave(self: CM_MHKWave):
    var mhk_wave_errors: Int = run_module(self.data, "mhk_wave")
    ASSERT_EQ(mhk_wave_errors, 0)
    var annual_energy: ssc_number_t
    var average_power: ssc_number_t
    var capacity_factor: ssc_number_t
    var lcoe_fcr: ssc_number_t
    ssc_data_get_number(self.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 607850.58949, 0.1)
    ssc_data_get_number(self.data, "average_power", average_power)
    EXPECT_NEAR(average_power, 74.6122, 0.5)
    ssc_data_get_number(self.data, "capacity_factor", capacity_factor)
    EXPECT_NEAR(capacity_factor, 24.262, 0.1)
    mhk_wave_errors = run_module(self.data, "lcoefcr")
    ASSERT_EQ(mhk_wave_errors, 0)
    ssc_data_get_number(self.data, "lcoe_fcr", lcoe_fcr)
    EXPECT_NEAR(lcoe_fcr, 4.18968, 0.1)