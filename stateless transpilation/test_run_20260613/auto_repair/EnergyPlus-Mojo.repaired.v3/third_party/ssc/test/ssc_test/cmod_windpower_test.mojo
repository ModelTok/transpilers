from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_GT, ASSERT_THROW, ASSERT_NEAR, ASSERT_EQ
from ...ssc.core import ssc_data_t, ssc_module_t, ssc_number_t
from vartab import var_data, var_table
from ...ssc.common import *
from ...ssc.cmod_windpower_eqns import Turbine_calculate_powercurve
from ...input_cases.weather_inputs import *
from ...input_cases.windpower_cases import *
from lib_util import *
from ...ssc.sscapi import *
import json
import os
import sys

class CMWindPowerIntegration(TestFixture):
    var data: ssc_data_t
    var e: Float64 = 1000.0

    def compute(self, errorNotExpected: Bool = True) -> Bool:
        var module: ssc_module_t = ssc_module_create("windpower")
        if module is None:
            if errorNotExpected:
                print("error: could not create 'windpower' module.")
            return False
        if ssc_module_exec(module, self.data) == 0:
            if errorNotExpected:
                print("error during simulation.")
            ssc_module_free(module)
            return False
        ssc_module_free(module)
        return True

    def SetUp(self):
        self.data = ssc_data_create()
        var errors: Int = windpower_nofinancial_testfile(self.data)
        EXPECT_FALSE(errors)

    def TearDown(self):
        ssc_data_free(self.data)
        self.data = None

def test_HubHeightInterpolation_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_unassign(test.data, "wind_resource_filename")
    var windresourcedata: var_data = create_winddata_array(1, 1)
    var vt: var_table = var_table(test.data)
    vt.assign("wind_resource_data", windresourcedata)
    vt.assign("wind_turbine_hub_ht", 200)
    var completed: Bool = test.compute(False)
    EXPECT_FALSE(completed) << "Heights difference > 35m"
    vt.unassign("wind_turbine_hub_ht")
    vt.assign("wind_turbine_hub_ht", 90)
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_GT(annual_energy, 4e06) << "Annual energy should be higher than height at 90"
    free_winddata_array(windresourcedata)
    test.TearDown()

def test_WakeModelsUsingFile_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 33224154, test.e) << "Simple"
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 2.8218e6, test.e) << "Simple: January"
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 2.8218e6, test.e) << "Simple: December"
    var wake_loss: ssc_number_t
    ssc_data_get_number(test.data, "wake_losses", wake_loss)
    EXPECT_NEAR(wake_loss, 1.546, 1e-3) << "Simple: Wake loss"
    ssc_data_set_number(test.data, "wind_farm_wake_model", 1)
    test.compute()
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 32346158, test.e) << "Wasp"
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 2.7472e6, test.e) << "Wasp: Jan"
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 2.7472e6, test.e) << "Wasp: Dec"
    ssc_data_get_number(test.data, "wake_losses", wake_loss)
    EXPECT_NEAR(wake_loss, 4.148, 1e-3) << "Wasp: Wake loss"
    ssc_data_set_number(test.data, "wind_farm_wake_model", 2)
    test.compute()
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 31081848, test.e) << "Eddy"
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 2.6398e6, test.e) << "Eddy: Jan"
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 2.6398e6, test.e) << "Eddy: Dec"
    ssc_data_get_number(test.data, "wake_losses", wake_loss)
    EXPECT_NEAR(wake_loss, 7.895, 1e-3) << "Eddy: Wake loss"
    ssc_data_set_number(test.data, "wind_farm_wake_model", 3)
    ssc_data_set_number(test.data, "wake_int_loss", 5)
    test.compute()
    var gross: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    ssc_data_get_number(test.data, "annual_gross_energy", gross)
    EXPECT_NEAR(annual_energy, gross * 0.95, test.e) << "Constant"
    ssc_data_get_number(test.data, "wake_losses", wake_loss)
    EXPECT_NEAR(wake_loss, 5, 1e-3) << "Constant: Wake loss"
    test.TearDown()

def test_UsingInterpolatedSubhourly_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    var SSCDIR: String = os.environ.get("SSCDIR", "")
    var file: String = SSCDIR + "/test/input_docs/AR Northwestern-Flat Lands.srw"
    ssc_data_set_string(test.data, "wind_resource_filename", file)
    var success: Bool = test.compute()
    EXPECT_TRUE(success) << "Computation 1 should succeed"
    var hourly_annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", hourly_annual_energy)
    var hourly_january_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    file = SSCDIR + "/test/input_docs/AR Northwestern-Flat Lands-15min.srw"
    ssc_data_set_string(test.data, "wind_resource_filename", file)
    success = test.compute()
    EXPECT_TRUE(success) << "Computation 2 should succeed"
    var check_annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", check_annual_energy)
    EXPECT_NEAR(check_annual_energy, hourly_annual_energy, 0.005 * check_annual_energy)
    var check_january_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(check_january_energy, hourly_january_energy, 0.005 * check_january_energy)
    var nEntries: Int = var_table(test.data).lookup("gen").num.ncols()
    EXPECT_EQ(nEntries, 8760 * 4)
    file = SSCDIR + "/test/input_docs/AR Northwestern-Flat Lands-5min.srw"
    ssc_data_set_string(test.data, "wind_resource_filename", file)
    success = test.compute()
    EXPECT_TRUE(success) << "Computation 3 should succeed"
    ssc_data_get_number(test.data, "annual_energy", check_annual_energy)
    EXPECT_NEAR(check_annual_energy, hourly_annual_energy, 0.005 * check_annual_energy)
    check_january_energy = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(check_january_energy, hourly_january_energy, 0.005 * check_january_energy)
    nEntries = var_table(test.data).lookup("gen").num.ncols()
    EXPECT_EQ(nEntries, 8760 * 12)
    test.TearDown()

def test_UsingDataArray_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_unassign(test.data, "wind_resource_filename")
    var windresourcedata: var_data = create_winddata_array(1, 1)
    var vt: var_table = var_table(test.data)
    vt.assign("wind_resource_data", windresourcedata)
    test.compute()
    var expectedAnnualEnergy: Float64 = 4219481.0
    var relErr: Float64 = expectedAnnualEnergy * 0.001
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, expectedAnnualEnergy, relErr)
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 0, relErr / 10.0)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 1972735, relErr / 10.0)
    free_winddata_array(windresourcedata)
    ssc_data_unassign(test.data, "wind_resource_data")
    windresourcedata = create_winddata_array(4, 1)
    vt.assign("wind_resource_data", windresourcedata)
    test.compute()
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, expectedAnnualEnergy, relErr)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 0, relErr / 10.0)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 1972735, relErr / 10.0)
    var gen_length: Int = 0
    ssc_data_get_array(test.data, "gen", gen_length)
    EXPECT_EQ(gen_length, 8760 * 4)
    free_winddata_array(windresourcedata)
    test.TearDown()

def test_Weibull_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_set_number(test.data, "wind_resource_model_choice", 1)
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 180453760, test.e)
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 15326247, test.e)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 15326247, test.e)
    test.TearDown()

def test_WindDist_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_set_number(test.data, "wind_resource_model_choice", 2)
    var dist: Float64[18] = [1.5, 180, 0.12583,
                       5, 180, 0.3933,
                       8, 180, 0.18276,
                       10, 180, 0.1341,
                       13.5, 180, 0.14217,
                       19, 180, 0.0211]
    ssc_data_set_matrix(test.data, "wind_resource_distribution", dist, 6, 3)
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 159807000, test.e)
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 13573000, test.e)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 13573000, test.e)
    test.TearDown()

def test_WindDist2_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_set_number(test.data, "wind_resource_model_choice", 2)
    var dst: Float64[18] = [1.5, 180, 0.12583,
                      5, 180, 0.3933,
                      8, 180, 0.18276,
                      10, 180, 0.1341,
                      13.5, 180, 0.14217,
                      19, 180, 0.0211]
    var dist: var_data = var_data(dst, 6, 3)
    var vt: var_table = var_table(test.data)
    vt.assign("wind_resource_distribution", dist)
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 159806945, test.e)
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 13572644, test.e)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 13572644, test.e)
    test.TearDown()

def test_WindDist3_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_set_number(test.data, "wind_resource_model_choice", 2)
    var dst: Float64[18] = [1.5, 180, 0.12583,
                      5, 180, 0.3933,
                      8, 180, 0.18276,
                      10, 180, 0.1341,
                      13.5, 180, 0.14217,
                      19, 180, 0.0211]
    var dist: var_data = var_data(dst, 6, 3)
    var vt: var_table = var_table(test.data)
    vt.assign("wind_resource_distribution", dist)
    ssc_data_set_number(test.data, "wind_farm_wake_model", 3)
    ssc_data_set_number(test.data, "wake_int_loss", 5)
    ssc_data_set_number(test.data, "avail_turb_loss", 5)
    test.compute()
    var annual_energy: ssc_number_t
    var gross: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    ssc_data_get_number(test.data, "annual_gross_energy", gross)
    EXPECT_NEAR(gross, 160804000, test.e)
    EXPECT_NEAR(annual_energy, gross * 0.95 * 0.95, test.e)
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 12326000, test.e)
    test.TearDown()

def test_IcingAndLowTempCutoff_cmod_windpower():
    var test = CMWindPowerIntegration()
    test.SetUp()
    ssc_data_unassign(test.data, "wind_resource_filename")
    var windresourcedata: var_data = create_winddata_array(1, 1)
    var rh: Float64[8760]
    for i in range(8760):
        if i % 2 == 0:
            rh[i] = 0.75
        else:
            rh[i] = 0.0
    var rh_vd: var_data = var_data(rh, 8760)
    windresourcedata.table.assign("rh", rh_vd)
    var vt: var_table = var_table(test.data)
    vt.assign("wind_resource_data", windresourcedata)
    vt.assign("en_low_temp_cutoff", 1)
    vt.assign("en_icing_cutoff", 1)
    vt.assign("low_temp_cutoff", 40.0)
    vt.assign("icing_cutoff_temp", 55.0)
    vt.assign("icing_cutoff_rh", 0.70)
    test.compute()
    var annual_energy: ssc_number_t
    ssc_data_get_number(test.data, "annual_energy", annual_energy)
    EXPECT_NEAR(annual_energy, 2110545, test.e) << "Reduced annual energy"
    var monthly_energy: ssc_number_t = ssc_data_get_array(test.data, "monthly_energy", None)[0]
    EXPECT_NEAR(monthly_energy, 0, test.e)
    monthly_energy = ssc_data_get_array(test.data, "monthly_energy", None)[11]
    EXPECT_NEAR(monthly_energy, 986114, test.e)
    var losses_percent: ssc_number_t
    ssc_data_get_number(test.data, "cutoff_losses", losses_percent)
    EXPECT_NEAR(losses_percent, 0.5, 0.01)
    free_winddata_array(windresourcedata)
    test.TearDown()

def test_Turbine_powercurve_cmod_windpower_eqns_NoData():
    ASSERT_THROW(Turbine_calculate_powercurve(None), RuntimeError)

def test_Turbine_powercurve_cmod_windpower_eqns_MissingVariables():
    var vd: var_table = var_table()
    ASSERT_THROW(Turbine_calculate_powercurve(vd), RuntimeError)

def test_Turbine_powercurve_cmod_windpower_eqns_Case1():
    var vd: var_table = var_table()
    vd.assign("turbine_size", 1500)
    vd.assign("wind_turbine_rotor_diameter", 75)
    vd.assign("elevation", 0)
    vd.assign("wind_turbine_max_cp", 0.45)
    vd.assign("max_tip_speed", 80)
    vd.assign("max_tip_sp_ratio", 8)
    vd.assign("cut_in", 4)
    vd.assign("cut_out", 25)
    vd.assign("drive_train", 0)
    Turbine_calculate_powercurve(vd)
    var ws: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_windspeeds").num
    var power: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_powerout").num
    var eff: util.matrix_t[ssc_number_t] = vd.lookup("hub_efficiency").num
    var rated_wx: Float64 = vd.lookup("rated_wind_speed").num
    ASSERT_NEAR(power[17], 64.050, 1e-2)
    ASSERT_NEAR(power[18], 80.0420, 1e-2)
    ASSERT_NEAR(power[43], 1346.764, 1e-2)
    ASSERT_NEAR(power[44], 1431.227, 1e-2)
    ASSERT_NEAR(power[45], 1500.0, 1e-2)
    ASSERT_NEAR(power[100], 0.0, 1e-2)
    ASSERT_NEAR(ws[100], 25.0, 1e-2)
    ASSERT_NEAR(rated_wx, 11.204, 1e-2)

def test_Turbine_powercurve_cmod_windpower_eqns_Case2():
    var vd: var_table = var_table()
    vd.assign("turbine_size", 1500)
    vd.assign("wind_turbine_rotor_diameter", 75)
    vd.assign("elevation", 0)
    vd.assign("wind_turbine_max_cp", 0.45)
    vd.assign("max_tip_speed", 80)
    vd.assign("max_tip_sp_ratio", 8)
    vd.assign("cut_in", 4)
    vd.assign("cut_out", 25)
    vd.assign("drive_train", 1)
    Turbine_calculate_powercurve(vd)
    var ws: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_windspeeds").num
    var power: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_powerout").num
    var eff: util.matrix_t[ssc_number_t] = vd.lookup("hub_efficiency").num
    var rated_wx: Float64 = vd.lookup("rated_wind_speed").num
    ASSERT_NEAR(power[17], 67.26, 1e-2)
    ASSERT_NEAR(power[18], 83.971, 1e-2)
    ASSERT_NEAR(power[44], 1416.36, 1e-2)
    ASSERT_NEAR(power[45], 1494.44, 1e-2)
    ASSERT_NEAR(power[46], 1500.0, 1e-2)
    ASSERT_NEAR(power[100], 0.0, 1e-2)
    ASSERT_NEAR(ws[100], 25.0, 1e-2)
    ASSERT_NEAR(rated_wx, 11.27, 1e-2)

def test_Turbine_powercurve_cmod_windpower_eqns_Case3():
    var vd: var_table = var_table()
    vd.assign("turbine_size", 1500)
    vd.assign("wind_turbine_rotor_diameter", 75)
    vd.assign("elevation", 0)
    vd.assign("wind_turbine_max_cp", 0.45)
    vd.assign("max_tip_speed", 80)
    vd.assign("max_tip_sp_ratio", 8)
    vd.assign("cut_in", 4)
    vd.assign("cut_out", 25)
    vd.assign("drive_train", 2)
    Turbine_calculate_powercurve(vd)
    var ws: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_windspeeds").num
    var power: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_powerout").num
    var eff: util.matrix_t[ssc_number_t] = vd.lookup("hub_efficiency").num
    var rated_wx: Float64 = vd.lookup("rated_wind_speed").num
    ASSERT_NEAR(power[17], 62.66, 1e-2)
    ASSERT_NEAR(power[18], 79.24, 1e-2)
    ASSERT_NEAR(power[44], 1405.26, 1e-2)
    ASSERT_NEAR(power[45], 1483.27, 1e-2)
    ASSERT_NEAR(power[46], 1500.0, 1e-2)
    ASSERT_NEAR(power[100], 0.0, 1e-2)
    ASSERT_NEAR(ws[100], 25.0, 1e-2)
    ASSERT_NEAR(rated_wx, 11.30, 1e-2)

def test_Turbine_powercurve_cmod_windpower_eqns_Case4():
    var vd: var_table = var_table()
    vd.assign("turbine_size", 1500)
    vd.assign("wind_turbine_rotor_diameter", 75)
    vd.assign("elevation", 0)
    vd.assign("wind_turbine_max_cp", 0.45)
    vd.assign("max_tip_speed", 80)
    vd.assign("max_tip_sp_ratio", 8)
    vd.assign("cut_in", 4)
    vd.assign("cut_out", 25)
    vd.assign("drive_train", 3)
    Turbine_calculate_powercurve(vd)
    var ws: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_windspeeds").num
    var power: util.matrix_t[ssc_number_t] = vd.lookup("wind_turbine_powercurve_powerout").num
    var eff: util.matrix_t[ssc_number_t] = vd.lookup("hub_efficiency").num
    var rated_wx: Float64 = vd.lookup("rated_wind_speed").num
    ASSERT_NEAR(power[17], 74.44, 1e-2)
    ASSERT_NEAR(power[18], 91.43, 1e-2)
    ASSERT_NEAR(power[43], 1356.14, 1e-2)
    ASSERT_NEAR(power[44], 1434.82, 1e-2)
    ASSERT_NEAR(power[45], 1500.0, 1e-2)
    ASSERT_NEAR(power[100], 0.0, 1e-2)
    ASSERT_NEAR(ws[100], 25.0, 1e-2)
    ASSERT_NEAR(rated_wx, 11.21, 1e-2)

def setup_python() -> Bool:
    var python_dir: String
    if os.name == "nt":
        python_dir = os.environ.get("SAMNTDIR", "") + "\\deploy\\runtime\\python\\"
    else:
        if not os.environ.get("CMAKEBLDDIR"):
            return False
        python_dir = os.environ.get("CMAKEBLDDIR", "") + "/sam/SAM.app/Contents/runtime/python/"
        if not util.dir_exists(python_dir + "Miniconda-4.8.2/"):
            print("Python not configured.", file=sys.stderr)
            return False
    set_python_path(python_dir)
    return True

def test_windpower_landbosse_SetupPython():
    if not setup_python():
        return
    var python_config_root: json.Value
    var configPath: String = get_python_path() + "python_config.json"
    var python_config_doc: file = open(configPath, "r")
    if python_config_doc.fail():
        print("Could not open " + configPath)
        return
    python_config_root = json.load(python_config_doc)
    if not python_config_root.isMember("miniconda_version"):
        raise RuntimeError("Missing key 'miniconda_version' in " + configPath)
    if not python_config_root.isMember("python_version"):
        raise RuntimeError("Missing key 'python_version' in " + configPath)
    if not python_config_root.isMember("exec_path"):
        raise RuntimeError("Missing key 'exec_path' in " + configPath)
    if not python_config_root.isMember("pip_path"):
        raise RuntimeError("Missing key 'pip_path' in " + configPath)
    if not python_config_root.isMember("packages"):
        raise RuntimeError("Missing key 'packages' in " + configPath)
    var packages: List[String] = []
    for i in python_config_root["packages"]:
        packages.append(i.asString())
    var config: List[String] = [python_config_root["python_version"].asString(),
                           python_config_root["miniconda_version"].asString(),
                           python_config_root["exec_path"].asString(),
                           python_config_root["pip_path"].asString()
                            ]

def check_Python_setup() -> Bool:
    if not setup_python():
        print("Python not configured.", file=sys.stderr)
        return False
    var configPath: String = get_python_path() + "python_config.json"
    var python_config_doc: file = open(configPath, "r")
    var python_config_root: json.Value
    python_config_root = json.load(python_config_doc)
    if python_config_root["exec_path"].asString().empty():
        print("Python not configured.", file=sys.stderr)
        return False
    return True

def test_windpower_landbosse_RunSuccess():
    if not check_Python_setup():
        return
    var file: String = os.environ.get("SSCDIR", "") + "/test/input_docs/AR Northwestern-Flat Lands.srw"
    var vd: var_table = var_table()
    vd.assign("en_landbosse", 1)
    vd.assign("wind_resource_filename", file)
    vd.assign("turbine_rating_MW", 1.5)
    vd.assign("wind_turbine_rotor_diameter", 45)
    vd.assign("wind_turbine_hub_ht", 80)
    vd.assign("num_turbines", 100)
    vd.assign("wind_resource_shear", 0.2)
    vd.assign("turbine_spacing_rotor_diameters", 4)
    vd.assign("row_spacing_rotor_diameters", 10)
    vd.assign("interconnect_voltage_kV", 137)
    vd.assign("distance_to_interconnect_mi", 10)
    vd.assign("depth", 2.36)
    vd.assign("rated_thrust_N", 589000)
    vd.assign("labor_cost_multiplier", 1)
    vd.assign("gust_velocity_m_per_s", 59.50)
    var landbosse: ssc_module_t = ssc_module_create("wind_landbosse")
    ssc_module_exec(landbosse, vd)
    ASSERT_EQ(vd.lookup("errors").str, "0")
    EXPECT_NEAR(vd.lookup("total_collection_cost").num[0], 4202342, 1e2)
    EXPECT_NEAR(vd.lookup("total_development_cost").num[0], 150000, 1e2)
    EXPECT_NEAR(vd.lookup("total_erection_cost").num[0], 6057403, 1e2)
    EXPECT_NEAR(vd.lookup("total_foundation_cost").num[0], 10036157, 1e2)
    EXPECT_NEAR(vd.lookup("total_gridconnection_cost").num[0], 5.61774e+06, 1e2)
    EXPECT_NEAR(vd.lookup("total_management_cost").num[0], 10516516, 1e2)
    EXPECT_NEAR(vd.lookup("total_bos_cost").num[0], 43836161, 1e2)
    EXPECT_NEAR(vd.lookup("total_sitepreparation_cost").num[0], 2698209, 1e2)
    EXPECT_NEAR(vd.lookup("total_substation_cost").num[0], 4940746, 1e2)
    var all_outputs: List[String] = ["bonding_usd", "collection_equipment_rental_usd", "collection_labor_usd",
                                            "collection_material_usd", "collection_mobilization_usd",
                                            "construction_permitting_usd", "development_labor_usd",
                                            "development_material_usd", "development_mobilization_usd",
                                            "engineering_usd", "erection_equipment_rental_usd", "erection_fuel_usd",
                                            "erection_labor_usd", "erection_material_usd", "erection_mobilization_usd",
                                            "erection_other_usd", "foundation_equipment_rental_usd",
                                            "foundation_labor_usd", "foundation_material_usd",
                                            "foundation_mobilization_usd", "insurance_usd", "markup_contingency_usd",
                                            "project_management_usd", "site_facility_usd",
                                            "sitepreparation_equipment_rental_usd", "sitepreparation_labor_usd",
                                            "sitepreparation_material_usd", "sitepreparation_mobilization_usd"]
    for i in all_outputs:
        EXPECT_GE(vd.lookup(i).num[0], 0) << i

def test_windpower_landbosse_SubhourlyFail():
    if not check_Python_setup():
        return
    var file: String = os.environ.get("SSCDIR", "") + "/test/input_docs/AR Northwestern-Flat Lands-15min.srw"
    var vd: var_table = var_table()
    vd.assign("en_landbosse", 1)
    vd.assign("wind_resource_filename", file)
    vd.assign("turbine_rating_MW", 1.5)
    vd.assign("wind_turbine_rotor_diameter", 45)
    vd.assign("wind_turbine_hub_ht", 80)
    vd.assign("num_turbines", 100)
    vd.assign("wind_resource_shear", 0.2)
    vd.assign("turbine_spacing_rotor_diameters", 4)
    vd.assign("row_spacing_rotor_diameters", 10)
    vd.assign("interconnect_voltage_kV", 137)
    vd.assign("distance_to_interconnect_mi", 10)
    vd.assign("depth", 2.36)
    vd.assign("rated_thrust_N", 589000)
    vd.assign("labor_cost_multiplier", 1)
    vd.assign("gust_velocity_m_per_s", 59.50)
    var landbosse: ssc_module_t = ssc_module_create("wind_landbosse")
    var success: Bool = ssc_module_exec(landbosse, vd)
    EXPECT_FALSE(success)
    var err: String = vd.lookup("errors").str
    EXPECT_EQ(err, "Error in Weather_Data: Length of values does not match length of index")

def test_windpower_landbosse_NegativeInputFail():
    if not check_Python_setup():
        return
    var file: String = os.environ.get("SSCDIR", "") + "/test/input_docs/AR Northwestern-Flat Lands.srw"
    var vd: var_table = var_table()
    vd.assign("en_landbosse", 1)
    vd.assign("wind_resource_filename", file)
    vd.assign("turbine_rating_MW", 1.5)
    vd.assign("wind_turbine_rotor_diameter", 45)
    vd.assign("wind_turbine_hub_ht", 80)
    vd.assign("num_turbines", 100)
    vd.assign("wind_resource_shear", 0.2)
    vd.assign("turbine_spacing_rotor_diameters", 4)
    vd.assign("row_spacing_rotor_diameters", 10)
    vd.assign("interconnect_voltage_kV", 137)
    vd.assign("distance_to_interconnect_mi", 10)
    vd.assign("depth", -2.36)
    vd.assign("rated_thrust_N", 589000)
    vd.assign("labor_cost_multiplier", 1)
    vd.assign("gust_velocity_m_per_s", 59.50)
    var landbosse: ssc_module_t = ssc_module_create("wind_landbosse")
    var success: Bool = ssc_module_exec(landbosse, vd)
    EXPECT_FALSE(success)
    var err: String = vd.lookup("errors").str
    EXPECT_EQ(err, "Error in NegativeInputError: User entered a negative value for depth. This is an invalid entry")