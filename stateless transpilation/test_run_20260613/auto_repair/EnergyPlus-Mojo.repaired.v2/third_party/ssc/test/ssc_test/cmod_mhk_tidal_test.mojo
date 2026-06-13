from testing import assert_eq, assert_approx_eq
from sscapi import ssc_data_create, ssc_data_clear, ssc_data_get_number, ssc_data_get_array, run_module
from ...test.input_cases.mhk.mhk_tidal_inputs import tidal_inputs
from ...test.input_cases.code_generator_utilities import ... # Not used, but kept for fidelity

struct CM_MHKTidal:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var calculated_array: Pointer[ssc_number_t]

    def __init__(inout self):
        self.data = ssc_data_create()
        tidal_inputs(self.data)

    def __del__(owned self):
        if self.data:
            ssc_data_clear(self.data)

    def SetCalculated(inout self, name: String):
        self.calculated_value = ssc_data_get_number(self.data, name)

    def SetCalculatedArray(inout self, name: String):
        var n: Int
        self.calculated_array = ssc_data_get_array(self.data, name, n)

# The test function
def ComputeModuleTest_cmod_mhk_tidal(inout self: CM_MHKTidal):
    var mhk_tidal_errors = run_module(self.data, "mhk_tidal")
    assert_eq(mhk_tidal_errors, 0)
    var annual_energy: ssc_number_t
    var average_power: ssc_number_t
    var device_rated_capacity: ssc_number_t
    var capacity_factor: ssc_number_t
    var lcoe_fcr: ssc_number_t
    annual_energy = ssc_data_get_number(self.data, "annual_energy")
    assert_approx_eq(annual_energy, 2161517.37607, 0.1)
    average_power = ssc_data_get_number(self.data, "device_average_power")
    assert_approx_eq(average_power, 265.321, 0.1)
    device_rated_capacity = ssc_data_get_number(self.data, "device_rated_capacity")
    assert_approx_eq(device_rated_capacity, 1115.0, 0.1)
    capacity_factor = ssc_data_get_number(self.data, "capacity_factor")
    assert_approx_eq(capacity_factor, 22.1299, 0.1)
    mhk_tidal_errors = run_module(self.data, "lcoefcr")
    assert_eq(mhk_tidal_errors, 0)
    lcoe_fcr = ssc_data_get_number(self.data, "lcoe_fcr")
    assert_approx_eq(lcoe_fcr, 1.67476, 0.1)

# Optional test runner (not in original but required for execution)
def main():
    var test = CM_MHKTidal()
    ComputeModuleTest_cmod_mhk_tidal(test)