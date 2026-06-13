from core import *
from vartab import *
from ...ssc.common import *
from ...input_cases.pvyield_cases import *
from ...input_cases.weather_inputs import *

from std import *
from testing import *

struct CMPvYieldTimo:
    var data: ssc_data_t
    var calculated_value: ssc_number_t
    var m_error_tolerance_hi: Float64 = 1.0
    var m_error_tolerance_lo: Float64 = 0.1

    def SetUp(inout self):
        self.data = ssc_data_create()

    def TearDown(inout self):
        if self.data:
            ssc_data_free(self.data)
            self.data = None

    def SetCalculated(inout self, name: String):
        self.calculated_value = ssc_data_get_number(self.data, name)

    def DefaultTimoModel_cmod_pvsamv1(inout self):
        pvyield_no_financial_meteo(self.data)
        var pvsam_errors: Int = pvyield_test(self.data)
        assert_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(self.data, "annual_energy", annual_energy)
            assert_approx_equal(annual_energy, 7380478, 7380478e-4, "Annual energy.")
            var capacity_factor: ssc_number_t
            ssc_data_get_number(self.data, "capacity_factor", capacity_factor)
            assert_approx_equal(capacity_factor, 20.219496, self.m_error_tolerance_lo, "Capacity factor")
            var kwh_per_kw: ssc_number_t
            ssc_data_get_number(self.data, "kwh_per_kw", kwh_per_kw)
            assert_approx_equal(kwh_per_kw, 1764.669, self.m_error_tolerance_hi, "Energy yield")
            var performance_ratio: ssc_number_t
            ssc_data_get_number(self.data, "performance_ratio", performance_ratio)
            assert_approx_equal(performance_ratio, -14.485646, self.m_error_tolerance_lo, "Energy yield")

    def TimoModel80603_meteo_cmod_pvsamv1(inout self):
        pvyield_user_support_80603_meteo(self.data)
        var pvsam_errors: Int = pvyield_test_user_support_80603_meteo(self.data)
        assert_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(self.data, "annual_energy", annual_energy)
            assert_approx_equal(annual_energy, 7441557, 7441557e-4, "Annual energy.")
            var capacity_factor: ssc_number_t
            ssc_data_get_number(self.data, "capacity_factor", capacity_factor)
            assert_approx_equal(capacity_factor, 20.399, self.m_error_tolerance_lo, "Capacity factor")
            var kwh_per_kw: ssc_number_t
            ssc_data_get_number(self.data, "kwh_per_kw", kwh_per_kw)
            assert_approx_equal(kwh_per_kw, 1779.27, self.m_error_tolerance_hi, "Energy yield")
            var performance_ratio: ssc_number_t
            ssc_data_get_number(self.data, "performance_ratio", performance_ratio)
            assert_approx_equal(performance_ratio, -14.6145, self.m_error_tolerance_lo, "Energy yield")

    def TimoModel80603_AZ_cmod_pvsamv1(inout self):
        pvyield_user_support_80603_AZ(self.data)
        var pvsam_errors: Int = pvyield_test_user_support_80603_AZ(self.data)
        assert_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(self.data, "annual_energy", annual_energy)
            assert_approx_equal(annual_energy, 8198434, 8198434e-4, "Annual energy.")
            var capacity_factor: ssc_number_t
            ssc_data_get_number(self.data, "capacity_factor", capacity_factor)
            assert_approx_equal(capacity_factor, 22.456, self.m_error_tolerance_lo, "Capacity factor")
            var kwh_per_kw: ssc_number_t
            ssc_data_get_number(self.data, "kwh_per_kw", kwh_per_kw)
            assert_approx_equal(kwh_per_kw, 1960.46, self.m_error_tolerance_hi, "Energy yield")
            var performance_ratio: ssc_number_t
            ssc_data_get_number(self.data, "performance_ratio", performance_ratio)
            assert_approx_equal(performance_ratio, -14.105, self.m_error_tolerance_lo, "Energy yield")

    def NoFinancialModelSystemDesign_cmod_pvsamv1(inout self):
        pvsamMPPT_nofinancial_default(self.data)
        var pairs: Dict[String, Float64] = Dict[String, Float64]()
        pairs["subarray1_modules_per_string"] = 6
        pairs["subarray2_modules_per_string"] = 6
        pairs["subarray3_modules_per_string"] = 6
        pairs["subarray4_modules_per_string"] = 6
        pairs["subarray1_nstrings"] = 49
        pairs["inverter_count"] = 22
        pairs["subarray1_track_mode"] = 0
        var annual_energy_expected: List[Float64] = List[Float64](183183, 242368, 258372, 216129, 192903)
        for tracking_option in range(5):
            pairs["subarray1_track_mode"] = Float64(tracking_option)
            var pvsam_errors: Int = modify_ssc_data_and_run_module(self.data, "pvsamv1", pairs)
            assert_false(pvsam_errors)
            if not pvsam_errors:
                var annual_energy: ssc_number_t
                ssc_data_get_number(self.data, "annual_energy", annual_energy)
                assert_approx_equal(annual_energy, annual_energy_expected[tracking_option], self.m_error_tolerance_hi, "Annual energy.")
        pairs["subarray1_track_mode"] = 1
        pairs["subarray1_backtrack"] = 1
        var pvsam_errors: Int = modify_ssc_data_and_run_module(self.data, "pvsamv1", pairs)
        assert_false(pvsam_errors)
        if not pvsam_errors:
            var annual_energy: ssc_number_t
            ssc_data_get_number(self.data, "annual_energy", annual_energy)
            assert_approx_equal(annual_energy, 237115, self.m_error_tolerance_hi, "Annual energy.")
        pairs["subarray1_nstrings"] = 14
        pairs["subarray2_enable"] = 1
        pairs["subarray2_nstrings"] = 15
        pairs["subarray3_enable"] = 1
        pairs["subarray3_nstrings"] = 10
        pairs["subarray4_enable"] = 1
        pairs["subarray4_nstrings"] = 10
        annual_energy_expected.clear()
        var subarray1_azimuth: List[Float64] = List[Float64](0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
        var subarray2_azimuth: List[Float64] = List[Float64](180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
        var subarray3_azimuth: List[Float64] = List[Float64](180, 180, 180, 180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
        var subarray4_azimuth: List[Float64] = List[Float64](180, 180, 180, 180, 180, 180, 180, 180, 180, 0, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180)
        var enable_mismatch: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        var subarray1_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
        var subarray2_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
        var subarray3_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
        var subarray4_gcr: List[Float64] = List[Float64](0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.1, 0.5, 0.9, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3)
        var subarray1_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
        var subarray2_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
        var subarray3_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
        var subarray4_tilt: List[Float64] = List[Float64](20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 45, 90, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20)
        var subarray1_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
        var subarray2_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
        var subarray3_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
        var subarray4_rotlim: List[Float64] = List[Float64](45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45)
        var subarray1_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        var subarray2_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        var subarray3_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0)
        var subarray4_track_mode: List[Float64] = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4)
        annual_energy_expected = List[Float64](167338, 176266, 183183, 166198, 175768, 183183, 171896, 178257, 183183, 171896, 178257,
                                               183183, 183183, 183175, 183183, 183183, 183183, 183183, 183183, 183183, 183183, 183183,
                                               183183, 183183, 183183, 183183, 177254, 182865, 162398, 176827, 182840, 160903, 178957,
                                               182963, 168372, 178957, 182963, 168372, 183183, 183183, 183183, 183183, 183183, 198689,
                                               205087, 192620, 186025, 183183, 201406, 206647, 193294, 186227, 183183, 195336, 198838,
                                               189925, 185216, 183183, 195336, 198838, 189925, 185216)
        for i in range(len(annual_energy_expected)):
            pairs["enable_mismatch_vmax_calc"] = enable_mismatch[i]
            pairs["subarray1_azimuth"] = subarray1_azimuth[i]
            pairs["subarray2_azimuth"] = subarray2_azimuth[i]
            pairs["subarray3_azimuth"] = subarray3_azimuth[i]
            pairs["subarray4_azimuth"] = subarray4_azimuth[i]
            pairs["subarray1_gcr"] = subarray1_gcr[i]
            pairs["subarray2_gcr"] = subarray2_gcr[i]
            pairs["subarray3_gcr"] = subarray3_gcr[i]
            pairs["subarray4_gcr"] = subarray4_gcr[i]
            pairs["subarray1_tilt"] = subarray1_tilt[i]
            pairs["subarray2_tilt"] = subarray2_tilt[i]
            pairs["subarray3_tilt"] = subarray3_tilt[i]
            pairs["subarray4_tilt"] = subarray4_tilt[i]
            pairs["subarray1_rotlim"] = subarray1_rotlim[i]
            pairs["subarray2_rotlim"] = subarray2_rotlim[i]
            pairs["subarray3_rotlim"] = subarray3_rotlim[i]
            pairs["subarray4_rotlim"] = subarray4_rotlim[i]
            pairs["subarray1_track_mode"] = subarray1_track_mode[i]
            pairs["subarray2_track_mode"] = subarray2_track_mode[i]
            pairs["subarray3_track_mode"] = subarray3_track_mode[i]
            pairs["subarray4_track_mode"] = subarray4_track_mode[i]
            var pvsam_errors2: Int = modify_ssc_data_and_run_module(self.data, "pvsamv1", pairs)
            assert_false(pvsam_errors2)
            if not pvsam_errors2:
                var annual_energy: ssc_number_t
                ssc_data_get_number(self.data, "annual_energy", annual_energy)
                assert_approx_equal(annual_energy, annual_energy_expected[i], self.m_error_tolerance_hi, "Index: " + String(i))

def main():
    var test_fixture = CMPvYieldTimo()
    test_fixture.SetUp()
    test_fixture.DefaultTimoModel_cmod_pvsamv1()
    test_fixture.TearDown()
    test_fixture.SetUp()
    test_fixture.TimoModel80603_meteo_cmod_pvsamv1()
    test_fixture.TearDown()
    test_fixture.SetUp()
    test_fixture.TimoModel80603_AZ_cmod_pvsamv1()
    test_fixture.TearDown()
    test_fixture.SetUp()
    test_fixture.NoFinancialModelSystemDesign_cmod_pvsamv1()
    test_fixture.TearDown()
    print("All tests passed.")