# This file is a faithful C++ to Mojo translation of the original test file.
# No refactoring, only syntactic changes to conform to Mojo.

from ....ssc.common.mojo import *
from ....tcs.csp_solver_core.mojo import *
from ....tcs.csp_solver_mspt_receiver_222.mojo import *
from ....tcs.csp_solver_mspt_collector_receiver.mojo import *
from ....tcs.csp_solver_pc_Rankine_indirect_224.mojo import *
from ....tcs.csp_solver_two_tank_tes.mojo import *
from ....tcs.csp_solver_tou_block_schedules.mojo import *
from ....input_cases.weather_inputs.mojo import *
from testing.mojo import *  # Assume a testing module provides TEST_F, EXPECT_NEAR, etc.

# Equivalent to #include <string>, <vector>, <memory>, <cmath> – Mojo stdlib includes.

# ------------------------------------------------------------------------------------------
# The following are replacements for gtest macros, kept with original names as close as possible.
# They are simple functions that emulate the behaviour.
# For true 1:1 translation, these would be macros, but Mojo does not have C++ macros.
# We keep the names and semantics.
# ------------------------------------------------------------------------------------------

def TEST_F(test_class_name: StringLiteral, test_name: StringLiteral, test_body: fn()) -> None:
    # This function is intended to be called by the test runner.
    # For simplicity, we just call the test body directly.
    print("Running test: " + test_class_name + "." + test_name)
    test_body()

def EXPECT_NEAR(val1: Float64, val2: Float64, epsilon: Float64, msg: StringLiteral = "") -> None:
    if abs(val1 - val2) > epsilon:
        print("FAILED EXPECT_NEAR: ", val1, " vs ", val2, " with epsilon ", epsilon, " - ", msg)
        assert False

def EXPECT_EQ(val1: Int, val2: Int, msg: StringLiteral = "") -> None:
    if val1 != val2:
        print("FAILED EXPECT_EQ: ", val1, " vs ", val2, " - ", msg)
        assert False

def EXPECT_TRUE(condition: Bool, msg: StringLiteral = "") -> None:
    if not condition:
        print("FAILED EXPECT_TRUE: ", msg)
        assert False

def EXPECT_FALSE(condition: Bool, msg: StringLiteral = "") -> None:
    if condition:
        print("FAILED EXPECT_FALSE: ", msg)
        assert False

def ASSERT_NEAR(val1: Float64, val2: Float64, epsilon: Float64, msg: StringLiteral = "") -> None:
    if abs(val1 - val2) > epsilon:
        print("FATAL ASSERT_NEAR: ", val1, " vs ", val2, " with epsilon ", epsilon, " - ", msg)
        assert False

def ASSERT_EQ(val1: Int, val2: Int, msg: StringLiteral = "") -> None:
    if val1 != val2:
        print("FATAL ASSERT_EQ: ", val1, " vs ", val2, " - ", msg)
        assert False

# ------------------------------------------------------------------------------------------
# End of test macro replacements.
# ------------------------------------------------------------------------------------------

/**
 * This class tests the C_csp_weatherreader's functions and ensures that the interface is the
 * same using weatherfile & weatherdata as weather inputs. The test also tests for variable
 * access and memory.
 */
class CspWeatherReaderTest:
    var wr: C_csp_weatherreader
    var sim_info: C_csp_solver_sim_info
    var e: Float64   # epsilon for double comparison

    def __init__(inout self):
        self.wr = C_csp_weatherreader()
        self.sim_info = C_csp_solver_sim_info()
        self.e = 0.0001

    def SetUp(self):
        self.e = 0.0001
        self.wr = C_csp_weatherreader()
        self.wr.m_trackmode = 0
        self.wr.m_tilt = 0
        self.wr.m_azimuth = 0.0

class UsingFileCaseWeatherReader(CspWeatherReaderTest):
    var file: String  # Not used in original, but kept for consistency

    def SetUp(self):
        var hourly: String = ""   # Simulate getenv and sprintf
        # In Mojo, we need to construct the file path. Assume a global environment variable SSCDIR exists.
        let sscdir: String = getenv("SSCDIR")   # Need to implement getenv
        hourly = sscdir + "/test/input_docs/weather.csv"
        self.wr.m_filename = hourly
        super().SetUp()
        self.sim_info.ms_ts.m_step = 3600
        self.sim_info.ms_ts.m_time_start = 0
        # In Mojo, weatherfile is a class, we need to create a shared pointer.
        # For simplicity, we assume make_shared and weatherfile are available with same name.
        self.wr.m_weather_data_provider = make_shared[weatherfile](hourly)

class UsingDataCaseWeatherReader(CspWeatherReaderTest):
    var data: var_data   # Note: var_data might be a struct, need to manage memory

    def SetUp(self):
        super().SetUp()
        self.sim_info.ms_ts.m_step = 3600
        self.sim_info.ms_ts.m_time_start = 0
        self.data = create_weatherdata_array(8760)  # allocates memory for weatherdata
        self.wr.m_weather_data_provider = make_shared[weatherdata](self.data)

    def TearDown(self):
        free_weatherdata_array(self.data)

/**
 * Integration tests for CSP's weatherreader class test that the interface & outputs
 * are the same whether the data is taken from a file or as var_data.
 * The test weather data is for Buenos Aires and taken from SAM's solar resource.
 */
TEST_F("UsingFileCaseWeatherReader", "IntegrationTest_csp_solver_core", fn() {
    var self_: UsingFileCaseWeatherReader = UsingFileCaseWeatherReader()
    self_.SetUp()
    self_.wr.init()
    EXPECT_NEAR(self_.wr.m_weather_data_provider.lat(), -34.82, self_.e, "Values in weather file's m_hdr\n")
    EXPECT_NEAR(self_.wr.m_weather_data_provider.lon(), -58.53, self_.e, "Values in weather file's m_hdr\n")
    EXPECT_NEAR(self_.wr.m_weather_data_provider.tz(), -3, self_.e, "Values in weather file's m_hdr\n")
    EXPECT_NEAR(self_.wr.m_weather_data_provider.elev(), 20, self_.e, "Values in weather file's m_hdr\n")
    EXPECT_EQ(self_.wr.m_weather_data_provider.step_sec(), 3600, "Values in weather file's m_hdr\n")
    EXPECT_EQ(self_.wr.m_weather_data_provider.nrecords(), 8760, "Values in weather file's m_hdr\n")
    self_.sim_info.ms_ts.m_time = 3600
    self_.wr.timestep_call(self_.sim_info)
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 19.1422, self_.e, "Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 20.9, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1010, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 0.0, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 2.1, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 187.367892, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 121.750884, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_solved_params.m_shift, -13.530000, self_.e, "Members specific to CSP weather\n")
    EXPECT_FALSE(self_.wr.ms_solved_params.m_leapyear, "Members specific to CSP weather\n")
    self_.wr.read_time_step(10, self_.sim_info)
    EXPECT_EQ(self_.wr.ms_outputs.m_month, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_day, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_hour, 10)
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 27.4906, self_.e, "Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 29.6, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1007, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 566, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 1.5, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 79.817137, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 34.102205, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_solved_params.m_shift, -13.530000, self_.e, "Members specific to CSP weather\n")
    EXPECT_FALSE(self_.wr.ms_solved_params.m_leapyear, "Members specific to CSP weather\n")
    self_.wr.converged()  # reset number of times the function is called
    self_.sim_info.ms_ts.m_time = 43600
    self_.wr.timestep_call(self_.sim_info)
    EXPECT_EQ(self_.wr.ms_outputs.m_month, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_day, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_hour, 11)
    EXPECT_EQ(self_.wr.ms_outputs.m_minute, 30, "Originally empty, minute column should be set to 30 by weatherfile")
    EXPECT_TRUE(isnan(self_.wr.ms_outputs.m_global), "Global not in weatherfile\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 602, self_.e)
    EXPECT_NEAR(self_.wr.ms_outputs.m_diffuse, 315, self_.e)
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 30.6, self_.e)
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 28.4516, self_.e, "Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdew, 19.8, self_.e)
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 2.6, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wdir, 180, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_rhum, 85, self_.e, "Rhum is 85 in weatherfile\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1007, self_.e, "Values copied from weather file\n")
    EXPECT_TRUE(isnan(self_.wr.ms_outputs.m_snow), "Snow not in weatherfile\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_albedo, 0.17, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_poa, 871.628310, self_.e, "Calculated in timestep_call()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 64.094861, self_.e, "Calculated in timestep_call()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 22.387110, self_.e, "Calculated in timestep_call()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_hor_beam, 556.628310, self_.e, "Calculated in timestep_call()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_time_rise, 5.804955, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_time_set, 20.095858, self_.e, "11th hour\n")
})

TEST_F("UsingDataCaseWeatherReader", "IntegrationTest_csp_solver_core", fn() {
    var self_: UsingDataCaseWeatherReader = UsingDataCaseWeatherReader()
    self_.SetUp()
    self_.wr.init()
    ASSERT_NEAR(self_.wr.m_weather_data_provider.lat(), -34.82, self_.e, "Values in weather data's m_hdr")
    ASSERT_NEAR(self_.wr.m_weather_data_provider.lon(), -58.53, self_.e, "Values in weather data's m_hdr")
    ASSERT_NEAR(self_.wr.m_weather_data_provider.tz(), -3, self_.e, "Values in weather data's m_hdr")
    ASSERT_NEAR(self_.wr.m_weather_data_provider.elev(), 20, self_.e, "Values in weather data's m_hdr")
    ASSERT_EQ(self_.wr.m_weather_data_provider.step_sec(), 3600, "Values in weather data's m_hdr")
    ASSERT_EQ(self_.wr.m_weather_data_provider.nrecords(), 8760, "Values in weather data's m_hdr")
    self_.sim_info.ms_ts.m_time = 3600
    self_.wr.timestep_call(self_.sim_info)
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 19.1422, self_.e, "1st time step: Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 20.9, self_.e, "1st time step: Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1010, self_.e, "1st time step: Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 0.0, self_.e, "1st time step: Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 2.1, self_.e, "1st time step: Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "1st time step: Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 187.367892, self_.e, "1st time step: Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 121.750884, self_.e, "1st time step: Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_solved_params.m_shift, -13.530000, self_.e, "1st time step: Members specific to CSP weather\n")
    EXPECT_FALSE(self_.wr.ms_solved_params.m_leapyear, "1st time step: Members specific to CSP weather\n")
    self_.wr.read_time_step(10, self_.sim_info)
    EXPECT_EQ(self_.wr.ms_outputs.m_month, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_day, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_hour, 10)
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 27.4906, self_.e, "Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 29.6, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1007, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 566, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 1.5, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 79.817137, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 34.102206, self_.e, "Members specific to CSP weather\n")
    EXPECT_NEAR(self_.wr.ms_solved_params.m_shift, -13.530000, self_.e, "Members specific to CSP weather\n")
    EXPECT_FALSE(self_.wr.ms_solved_params.m_leapyear, "Members specific to CSP weather\n")
    self_.wr.converged()  # reset number of times the function is called
    self_.sim_info.ms_ts.m_time = 43600
    self_.wr.timestep_call(self_.sim_info)
    EXPECT_EQ(self_.wr.ms_outputs.m_month, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_day, 1)
    EXPECT_EQ(self_.wr.ms_outputs.m_hour, 11)
    EXPECT_EQ(self_.wr.ms_outputs.m_minute, 30, "Originally empty, minute column should be set to 30 by weatherfile")
    EXPECT_TRUE(isnan(self_.wr.ms_outputs.m_global), "11th hour, Global not in weatherfile\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_beam, 602, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_diffuse, 315, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdry, 30.6, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_twet, 28.4516, self_.e, "Twet should be calculated in weather_data_provider.read()\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_tdew, 19.8, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wspd, 2.6, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_wdir, 180, self_.e, "Values copied from weather file\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_rhum, 85, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_pres, 1007, self_.e, "11th hour\n")
    EXPECT_TRUE(isnan(self_.wr.ms_outputs.m_snow), "11th hour, Snow not in weatherfile\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_albedo, 0.17, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_aod, 0.291, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_poa, 871.628306, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solazi, 64.094861, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_solzen, 22.387111, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_hor_beam, 556.628306, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_time_rise, 5.804955, self_.e, "11th hour\n")
    EXPECT_NEAR(self_.wr.ms_outputs.m_time_set, 20.095858, self_.e, "11th hour\n")
    self_.TearDown()
})

/**
 *	Integration & Execution Time test
 */
class CspSolverCoreTest:
    var wr: C_csp_weatherreader
    var heliostatfield: C_pt_sf_perf_interp
    var receiver: C_mspt_receiver_222
    var cr: C_csp_collector_receiver  # pointer, but in Mojo we use owned or borrowed reference
    var pc: C_csp_power_cycle
    var rankine: C_pc_Rankine_indirect_224
    var tes: C_csp_two_tank_tes
    var tou: C_csp_tou_block_schedules
    var sim_setup: C_csp_solver.S_sim_setup
    var system: C_csp_solver.S_csp_system_params
    var solver: C_csp_solver  # pointer; we'll use owned reference

    def __init__(inout self):
        self.wr = C_csp_weatherreader()
        self.heliostatfield = C_pt_sf_perf_interp()
        self.receiver = C_mspt_receiver_222()
        # cr and pc are pointers; we allocate them later
        self.rankine = C_pc_Rankine_indirect_224()
        self.tes = C_csp_two_tank_tes()
        self.tou = C_csp_tou_block_schedules()
        self.sim_setup = C_csp_solver.S_sim_setup()
        self.system = C_csp_solver.S_csp_system_params()
        # solver will be allocated in SetUp

    def SetUp(self):
        self.pc = self.rankine    # pointer to rankine
        # Create C_csp_mspt_collector_receiver using heilostatfield and receiver
        self.cr = C_csp_mspt_collector_receiver(self.heliostatfield, self.receiver)
        self.sim_setup.m_sim_time_start = 0
        self.sim_setup.m_sim_time_start = 31536000  # intentional double assignment? kept as is.
        self.sim_setup.m_report_step = 3600.0
        # In C++, solver = new C_csp_solver(...). In Mojo we allocate.
        self.solver = C_csp_solver(self.wr, self.cr, self.pc, self.tes, self.tou, self.system, ssc_cmod_update, None)

def set_heliostatfield(heliostatfield: C_pt_sf_perf_interp, case_type: String):
    var p: C_pt_sf_perf_interp.S_params = &(heliostatfield.ms_params)  # Not directly translatable
    if case_type == "default":

class DefaultCaseCspSolverCore(CspSolverCoreTest):
    def SetUp(self):
        super().SetUp()
        self.tou.mc_dispatch_params.m_dispatch_optimize = 1
        self.solver.Ssimulate(self.sim_setup)