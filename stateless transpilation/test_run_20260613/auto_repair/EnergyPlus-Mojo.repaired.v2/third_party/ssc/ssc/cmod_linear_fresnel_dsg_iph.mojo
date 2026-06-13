/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

from core import *
from tckernel import *
from common import *
from lib_weatherfile import *
from csp_solver_lf_dsg_collector_receiver import *
from csp_solver_pc_steam_heat_sink import *
from csp_solver_tou_block_schedules import *
from csp_solver_two_tank_tes import *

static var_info _cm_vtab_linear_fresnel_dsg_iph[] = {
    { SSC_INPUT,        SSC_STRING,      "file_name",         "local weather file path",                                                             "",              "",            "Weather",        "*",                       "LOCAL_FILE",            "" },
    { SSC_INPUT,        SSC_TABLE,       "solar_resource_data", "Weather resource data in memory",                                                   "",              "",            "Weather",        "?",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "I_bn_des",          "Design point irradiation value",                                                      "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_cold_ref",        "Reference HTF outlet temperature at design",                                          "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_turb_des",        "Design-point turbine inlet pressure",                                                 "bar",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_hot",             "Hot HTF inlet temperature, from storage tank",                                        "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "x_b_des",           "Design point boiler outlet steam quality",                                            "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "q_pb_des",          "Design heat input to the power block",                                                "MW",            "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_hdr_c",          "Average design-point cold header pressure drop fraction",                             "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_sf_boil",        "Design-point pressure drop across the solar field boiler fraction",                   "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_hdr_h",          "Average design-point hot header pressure drop fraction",                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "nModBoil",          "Number of modules in the boiler section",                                             "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "nLoops",            "Number of loops",                                                                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "eta_pump",          "Feedwater pump efficiency",                                                           "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "theta_stow",        "stow angle",                                                                          "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "theta_dep",         "deploy angle",                                                                        "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_fp",              "Freeze protection temperature (heat trace activation temperature)",                   "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "Pipe_hl_coef",      "Loss coefficient from the header.. runner pipe.. and non-HCE pipin",                  "W/m2-K",        "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "SCA_drives_elec",   "Tracking power.. in Watts per m2",                                                    "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "ColAz",             "Collector azimuth angle",                                                             "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "e_startup",         "Thermal inertia contribution per sq meter of solar field",                            "kJ/K-m2",       "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_amb_des_sf",      "Design-point ambient temperature",                                                    "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "V_wind_max",        "Maximum allowable wind velocity before safety stow",                                  "m/s",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "csp.lf.sf.water_per_wash",  "Water usage per wash",                "L/m2_aper",    "",    "heliostat", "*", "", "" },
    { SSC_INPUT,        SSC_NUMBER,      "csp.lf.sf.washes_per_year", "Mirror washing frequency",            "-/year",       "",    "heliostat", "*", "", "" },
    { SSC_INPUT,        SSC_MATRIX,      "A_aperture",        "(boiler, SH) Reflective aperture area of the collector module",                       "m^2",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "L_col",             "(boiler, SH) Active length of the superheater section collector module",              "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "OptCharType",       "(boiler, SH) The optical characterization method",                                    "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "IAM_T",             "(boiler, SH) Transverse Incident angle modifiers (0,1,2,3,4 order terms)",            "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "IAM_L",             "(boiler, SH) Longitudinal Incident angle modifiers (0,1,2,3,4 order terms)",          "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "TrackingError",     "(boiler, SH) User-defined tracking error derate",                                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "GeomEffects",       "(boiler, SH) User-defined geometry effects derate",                                   "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "rho_mirror_clean",  "(boiler, SH) User-defined clean mirror reflectivity",                                 "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "dirt_mirror",       "(boiler, SH) User-defined dirt on mirror derate",                                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "error",             "(boiler, SH) User-defined general optical error derate",                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "HLCharType",        "(boiler, SH) Flag indicating the heat loss model type {1=poly.; 2=Forristall}",       "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "HL_dT",             "(boiler, SH) Heat loss coefficient - HTF temperature (0,1,2,3,4 order terms)",        "W/m-K^order",   "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "HL_W",              "(boiler, SH) Heat loss coef adj wind velocity (0,1,2,3,4 order terms)",               "1/(m/s)^order", "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "D_2",               "(boiler, SH) The inner absorber tube diameter",                                       "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "D_3",               "(boiler, SH) The outer absorber tube diameter",                                       "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "D_4",               "(boiler, SH) The inner glass envelope diameter",                                      "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "D_5",               "(boiler, SH) The outer glass envelope diameter",                                      "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "D_p",               "(boiler, SH) The diameter of the absorber flow plug (optional)",                      "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Rough",             "(boiler, SH) Roughness of the internal surface",                                      "m",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Flow_type",         "(boiler, SH) The flow type through the absorber",                                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "AbsorberMaterial",  "(boiler, SH) Absorber material type",                                                 "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "HCE_FieldFrac",     "(boiler, SH) The fraction of the field occupied by this HCE type (4: # field fracs)", "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "alpha_abs",         "(boiler, SH) Absorber absorptance (4: # field fracs)",                                "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "b_eps_HCE1",        "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "b_eps_HCE2",        "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "b_eps_HCE3",        "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "b_eps_HCE4",        "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "sh_eps_HCE1",       "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "sh_eps_HCE2",       "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "sh_eps_HCE3",       "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "sh_eps_HCE4",       "(temperature) Absorber emittance (eps)",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "alpha_env",         "(boiler, SH) Envelope absorptance (4: # field fracs)",                                "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "EPSILON_4",         "(boiler, SH) Inner glass envelope emissivities (Pyrex) (4: # field fracs)",           "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Tau_envelope",      "(boiler, SH) Envelope transmittance (4: # field fracs)",                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "GlazingIntactIn",   "(boiler, SH) The glazing intact flag {true=0; false=1} (4: # field fracs)",           "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "AnnulusGas",        "(boiler, SH) Annulus gas type {1=air; 26=Ar; 27=H2} (4: # field fracs)",              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "P_a",               "(boiler, SH) Annulus gas pressure (4: # field fracs)",                                "torr",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Design_loss",       "(boiler, SH) Receiver heat loss at design (4: # field fracs)",                        "W/m",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Shadowing",         "(boiler, SH) Receiver bellows shadowing loss factor (4: # field fracs)",              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "Dirt_HCE",          "(boiler, SH) Loss due to dirt on the receiver envelope (4: # field fracs)",           "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "b_OpticalTable",    "Values of the optical efficiency table",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "sh_OpticalTable",   "Values of the optical efficiency table",                                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "heat_sink_dP_frac", "Fractional pressure drop through heat sink",                                          "",              "",            "heat_sink",      "*",                       "",                      "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "time_hr",             "Time at end of timestep",                                      "hr",           "",            "Solver",         "*",                       "",           "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "month",               "Resource Month",                         "",             "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "hour_day",            "Resource Hour of Day",                   "",             "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "solazi",              "Resource Solar Azimuth",                 "deg",          "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "solzen",              "Resource Solar Zenith",                  "deg",          "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "beam",                "Resource Beam normal irradiance",        "W/m2",         "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "tdry",                "Resource Dry bulb temperature",          "C",            "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "twet",                "Resource Wet bulb temperature",          "C",            "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "wspd",                "Resource Wind Speed",                    "m/s",          "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "pres",                "Resource Pressure",                      "mbar",         "",      "weather",        "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "theta_traverse",      "Field traverse incidence angle",          "deg",         "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "theta_longitudinal",  "Field traverse incidence angle",          "deg",         "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "eta_opt_ave",         "Field optical efficiency before defocus", "deg",         "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "defocus",             "Field collector focus fraction",          "",            "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_inc_sf_tot",        "Field thermal power incident",            "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_rec_inc",       "Receiver thermal power incident",         "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_rec_thermal_loss", "Receiver thermal losses",              "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_rec_abs",       "Receiver thermal power absorbed",         "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_piping_loss",   "Field piping thermal losses",             "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "e_dot_field_int_energy", "Field change in material/htf internal energy", "MWt", "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_sf_out",        "Field thermal power leaving in steam",    "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_freeze_prot",   "Field freeze protection required",        "MWt",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "m_dot_loop",          "Receiver mass flow rate",                 "kg/s",         "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "m_dot_field",         "Field total mass flow rate",              "kg/s",         "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "T_field_cold_in",     "Field timestep-averaged inlet temperature","C",            "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "T_rec_cold_in",       "Loop timestep-averaged inlet temperature","C",            "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "T_rec_hot_out",       "Loop timestep-averaged outlet temperature","C",            "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "x_rec_hot_out",       "Loop timestep-averaged outlet quality",   "",             "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "T_field_hot_out",     "Field timestep-averaged outlet temperature","C",           "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "x_field_hot_out",     "Field timestep-averaged outlet quality",  "",             "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "deltaP_field",        "Field pressure drop",                     "bar",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "W_dot_sca_track",     "Field collector tracking power",           "MWe",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "W_dot_field_pump",    "Field htf pumping power",                  "MWe",          "",      "dsg_field",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "q_dot_to_heat_sink",  "Heat sink thermal power",                  "MWt",          "",      "Heat_Sink",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "W_dot_heat_sink_pump","Heat sink pumping power",                  "MWe",          "",      "Heat_Sink",      "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "W_dot_parasitic_tot", "System total electrical parasitic",        "MWe",          "",      "Controller",     "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "op_mode_1",           "1st operating mode",                       "",             "",      "Controller",     "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "op_mode_2",           "2nd op. mode, if applicable",              "",             "",      "Controller",     "*",       "",     "" },
    { SSC_OUTPUT,   SSC_ARRAY,   "op_mode_3",           "3rd op. mode, if applicable",              "",             "",      "Controller",     "*",       "",     "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "annual_energy",       "Annual Net Thermal Energy Production w/ avail derate",     "kWt-hr",   "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "annual_field_energy", "Annual Gross Thermal Energy Production w/ avail derate",   "kWt-hr",   "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "annual_thermal_consumption", "Annual thermal freeze protection required",           "kWt-hr",   "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "annual_electricity_consumption", "Annual electricity consumptoin w/ avail derate",   "kWe-hr",   "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "annual_total_water_use", "Total Annual Water Usage",                                "m^3",      "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "capacity_factor",      "Capacity factor",                                          "%",        "",   "Post-process",     "*",       "",   "" },
    { SSC_OUTPUT,   SSC_NUMBER,  "kwh_per_kw",           "First year kWh/kW",                                        "kWht/kWt", "",   "Post-process",     "*",       "",   "" },
    var_info_invalid };

class cm_linear_fresnel_dsg_iph : compute_module {
    def __init__(self):
        self.add_var_info(_cm_vtab_linear_fresnel_dsg_iph)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        var weather_reader = C_csp_weatherreader()
        if self.is_assigned("file_name"):
            weather_reader.m_weather_data_provider = make_shared[weatherfile](self.as_string("file_name"))
            if weather_reader.m_weather_data_provider.has_message():
                self.log(weather_reader.m_weather_data_provider.message(), SSC_WARNING)
        if self.is_assigned("solar_resource_data"):
            weather_reader.m_weather_data_provider = make_shared[weatherdata](self.lookup("solar_resource_data"))
            if weather_reader.m_weather_data_provider.has_message():
                self.log(weather_reader.m_weather_data_provider.message(), SSC_WARNING)
        weather_reader.m_trackmode = 0
        weather_reader.m_tilt = 0.0
        weather_reader.m_azimuth = 0.0
        weather_reader.init()
        if weather_reader.has_error():
            raise exec_error("linear_fresnel_dsg_iph", weather_reader.get_error())
        var nhourssim = 8760.0                # [hr] Number of hours to simulate
        var sim_setup = C_csp_solver.S_sim_setup()
        sim_setup.m_sim_time_start = 0.0               # [s] starting first hour of year
        sim_setup.m_sim_time_end = nhourssim * 3600.0  # [s] full year simulation
        var steps_per_hour: Int = 1          # [-]
        var n_wf_records = weather_reader.m_weather_data_provider.nrecords()
        steps_per_hour = n_wf_records / 8760   # [-]
        var n_steps_fixed: Int = steps_per_hour * 8760  # [-]
        sim_setup.m_report_step = 3600.0 / Float64(steps_per_hour)  # [s]

        var c_lf_dsg = C_csp_lf_dsg_collector_receiver()
        c_lf_dsg.m_q_max_aux = 0.0            # [kWt] No aux for IPH
        c_lf_dsg.m_LHV_eff = 1.0            # [-] No aux for IPH
        c_lf_dsg.m_T_set_aux = self.as_double("T_hot") + 273.15               # [K], convert from [C]
        c_lf_dsg.m_T_field_in_des = self.as_double("T_cold_ref") + 273.15     # [K], convert from [C]
        c_lf_dsg.m_T_field_out_des = self.as_double("T_hot") + 273.15         # [K], convert from [C]
        c_lf_dsg.m_x_b_des = self.as_double("x_b_des")               # [-]
        c_lf_dsg.m_P_turb_des = self.as_double("P_turb_des")         # [bar]
        c_lf_dsg.m_fP_hdr_c = self.as_double("fP_hdr_c")            # [-]
        c_lf_dsg.m_fP_sf_boil = self.as_double("fP_sf_boil")        # [-]
        c_lf_dsg.m_fP_boil_to_sh = 0.0                              # [-] Modeling only for boiling, so far
        c_lf_dsg.m_fP_sf_sh = 0.0                                    # [-] Modeling only for boiling, so far
        c_lf_dsg.m_fP_hdr_h = self.as_double("fP_hdr_h")            # [-]
        c_lf_dsg.m_q_pb_des = self.as_double("q_pb_des") * 1000.0    # [kWt]   Q_ref ); // = P_ref/eta_ref;
        c_lf_dsg.m_W_pb_des = 0.0                                    # [kWe]
        c_lf_dsg.m_m_dot_max_frac = 1.2
        c_lf_dsg.m_m_dot_min_frac = 0.2
        c_lf_dsg.m_cycle_max_fraction = 100.0                        # [-]
        c_lf_dsg.m_cycle_cutoff_frac = 0.0                           # [-] Scales the design pressure to find the lowest expected pressure in system
        c_lf_dsg.m_t_sby_des = 0.0                                    # [hr] Used to calculated q_dot_aux, so hardcode = 0
        c_lf_dsg.m_q_sby_frac = 0.0                                   # [-] Used to calculated q_dot_aux, so hardcode = 0
        c_lf_dsg.m_PB_fixed_par = 0.0                                 # [-] Calculates fixed parasitics in CR class. Set to 0 and calculate this parasitic somewhere else
        c_lf_dsg.m_fossil_mode = 4                                     # [-] in mode 4 the fossil mode sets the off-design pressure to the design pressure
        c_lf_dsg.m_I_bn_des = self.as_double("I_bn_des")             # [W/m2]
        c_lf_dsg.m_is_oncethru = true                                  # [-] Once through because assuming boiler only, for now
        c_lf_dsg.m_is_sh_target = false                                # [-] Targeting 2-phase outlet
        c_lf_dsg.m_is_multgeom = false                                 # [-] Only one geometry because assuming boiler only, for now
        c_lf_dsg.m_nModBoil = self.as_integer("nModBoil")             # [-] Number of modules in a loop
        c_lf_dsg.m_nModSH = 0                                          # [-] No superheat, for now
        c_lf_dsg.m_nLoops = self.as_integer("nLoops")                 # [-]
        c_lf_dsg.m_eta_pump = self.as_double("eta_pump")              # [-] 
        c_lf_dsg.m_theta_stow = self.as_double("theta_stow") * 0.0174533  # [rad], convert from [deg]
        c_lf_dsg.m_theta_dep = self.as_double("theta_dep") * 0.0174533   # [rad], convert from [deg]
        c_lf_dsg.m_T_field_ini = self.as_double("T_cold_ref") + 275.15   # [K], convert from [C]
        c_lf_dsg.m_T_fp = self.as_double("T_fp") + 273.15            # [K], convert from [C]
        c_lf_dsg.m_Pipe_hl_coef = self.as_double("Pipe_hl_coef")     # [W/m2-K]
        c_lf_dsg.m_SCA_drives_elec = self.as_double("SCA_drives_elec")   # [W/SCA]
        c_lf_dsg.m_ColAz = self.as_double("ColAz") * 0.0174533        # [rad], convert from [deg]
        c_lf_dsg.m_e_startup = self.as_double("e_startup")            # [kJ/K-m2], Thermal inertia contribution per sq meter of solar field
        c_lf_dsg.m_T_amb_des_sf = self.as_double("T_amb_des_sf") + 273.15    # [K] Ambient temperature at design
        c_lf_dsg.m_V_wind_max = self.as_double("V_wind_max")          # [m/s] Maximum wind speed before stow

        c_lf_dsg.m_bop_array.resize(5)
        for i in range(5):
            c_lf_dsg.m_bop_array[i] = 0.0
        c_lf_dsg.m_aux_array.resize(5)
        for i in range(5):
            c_lf_dsg.m_aux_array[i] = 0.0
        c_lf_dsg.m_ffrac.resize(5)
        for i in range(5):
            c_lf_dsg.m_ffrac[i] = 0.0

        c_lf_dsg.m_A_aperture = self.as_matrix("A_aperture")          # [m2]
        c_lf_dsg.m_L_col = self.as_matrix("L_col")                    # [m]
        c_lf_dsg.m_OptCharType = self.as_matrix("OptCharType")        # [-]
        c_lf_dsg.m_IAM_T = self.as_matrix("IAM_T")                    # [-]
        c_lf_dsg.m_IAM_L = self.as_matrix("IAM_L")                    # [-]
        c_lf_dsg.m_TrackingError = self.as_matrix("TrackingError")    # [-]
        c_lf_dsg.m_GeomEffects = self.as_matrix("GeomEffects")        # [-]              "W/m-K^order", 
        c_lf_dsg.m_rho_mirror_clean = self.as_matrix("rho_mirror_clean")  # [-]	   "1/(m/s)^order"
        c_lf_dsg.m_dirt_mirror = self.as_matrix("dirt_mirror")        # [-]
        c_lf_dsg.m_error = self.as_matrix("error")                    # [-]
        c_lf_dsg.m_HLCharType = self.as_matrix("HLCharType")          # [-]
        c_lf_dsg.m_HL_dT = self.as_matrix("HL_dT")                    # [W/m-K^order]
        c_lf_dsg.m_HL_W = self.as_matrix("HL_W")                      # [1/(m/s)^order]
        c_lf_dsg.m_D_2 = self.as_matrix("D_2")                        # [m]
        c_lf_dsg.m_D_3 = self.as_matrix("D_3")                        # [m]
        c_lf_dsg.m_D_4 = self.as_matrix("D_4")                        # [m]
        c_lf_dsg.m_D_5 = self.as_matrix("D_5")                        # [m]
        c_lf_dsg.m_D_p = self.as_matrix("D_p")                        # [m]
        c_lf_dsg.m_Rough = self.as_matrix("Rough")                    # [m]
        c_lf_dsg.m_Flow_type = self.as_matrix("Flow_type")            # [-]
        c_lf_dsg.m_AbsorberMaterial_in = self.as_matrix("AbsorberMaterial")    # [-]
        c_lf_dsg.m_HCE_FieldFrac = self.as_matrix("HCE_FieldFrac")    # [-]
        c_lf_dsg.m_alpha_abs = self.as_matrix("alpha_abs")            # [-]
        c_lf_dsg.m_b_eps_HCE1 = self.as_matrix("b_eps_HCE1")          # [-]
        c_lf_dsg.m_b_eps_HCE2 = self.as_matrix("b_eps_HCE2")          # [-]
        c_lf_dsg.m_b_eps_HCE3 = self.as_matrix("b_eps_HCE3")          # [-]
        c_lf_dsg.m_b_eps_HCE4 = self.as_matrix("b_eps_HCE4")          # [-]
        if c_lf_dsg.m_is_multgeom:
            c_lf_dsg.m_sh_eps_HCE1 = self.as_matrix("sh_eps_HCE1")    # [-]
            c_lf_dsg.m_sh_eps_HCE2 = self.as_matrix("sh_eps_HCE2")    # [-]
            c_lf_dsg.m_sh_eps_HCE3 = self.as_matrix("sh_eps_HCE3")    # [-]
            c_lf_dsg.m_sh_eps_HCE4 = self.as_matrix("sh_eps_HCE4")    # [-]

        c_lf_dsg.m_alpha_env = self.as_matrix("alpha_env")            # [-] Envelope absorptance
        c_lf_dsg.m_EPSILON_4 = self.as_matrix("EPSILON_4")            # [-] Inner glass envelope emissivities
        c_lf_dsg.m_Tau_envelope = self.as_matrix("Tau_envelope")      # [-] Envelope transmittance

        var glazing_intact_double = self.as_matrix("GlazingIntactIn") # [-] Is the glazing intact?
        var n_gl_row = Int(glazing_intact_double.nrows())
        var n_gl_col = Int(glazing_intact_double.ncols())
        c_lf_dsg.m_GlazingIntactIn.resize(n_gl_row, n_gl_col)
        for i in range(n_gl_row):
            for j in range(n_gl_col):
                c_lf_dsg.m_GlazingIntactIn[i, j] = (glazing_intact_double[i, j] > 0)

        c_lf_dsg.m_AnnulusGas_in = self.as_matrix("AnnulusGas")       # [-]
        c_lf_dsg.m_P_a = self.as_matrix("P_a")                        # [torr] Annulus gas pressure 
        c_lf_dsg.m_Design_loss = self.as_matrix("Design_loss")        # [W/m] Receiver heat loss at design
        c_lf_dsg.m_Shadowing = self.as_matrix("Shadowing")            # [-] Receiver bellows shadowing loss factor
        c_lf_dsg.m_Dirt_HCE = self.as_matrix("Dirt_HCE")              # [-] Loss due to dirt on the receiver envelope
        c_lf_dsg.m_b_OpticalTable = self.as_matrix("b_OpticalTable")  # [-] Boiler Optical Table
        c_lf_dsg.m_sh_OpticalTable = self.as_matrix("sh_OpticalTable")# [-] Superheater Optical Table

        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_THETA_TRAVERSE, self.allocate("theta_traverse", n_steps_fixed), n_steps_fixed)
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_THETA_LONGITUDINAL, self.allocate("theta_longitudinal", n_steps_fixed), n_steps_fixed)
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_ETA_OPTICAL, self.allocate("eta_opt_ave", n_steps_fixed), n_steps_fixed)
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_DEFOCUS, self.allocate("defocus", n_steps_fixed), n_steps_fixed)
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_INC_SF_TOT, self.allocate("q_inc_sf_tot", n_steps_fixed), n_steps_fixed)                        # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_REC_THERMAL_LOSS, self.allocate("q_dot_rec_thermal_loss", n_steps_fixed), n_steps_fixed)        # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_REC_ABS, self.allocate("q_dot_rec_abs", n_steps_fixed), n_steps_fixed)                          # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_REC_INC, self.allocate("q_dot_rec_inc", n_steps_fixed), n_steps_fixed)                          # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_PIPING_LOSS, self.allocate("q_dot_piping_loss", n_steps_fixed), n_steps_fixed)                  # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_E_DOT_INTERNAL_ENERGY, self.allocate("e_dot_field_int_energy", n_steps_fixed), n_steps_fixed)         # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_OUT, self.allocate("q_dot_sf_out", n_steps_fixed), n_steps_fixed)                               # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_Q_DOT_FREEZE_PROT, self.allocate("q_dot_freeze_prot", n_steps_fixed), n_steps_fixed)                 # [MWt]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_M_DOT_LOOP, self.allocate("m_dot_loop", n_steps_fixed), n_steps_fixed)     # [kg/s]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_M_DOT_FIELD, self.allocate("m_dot_field", n_steps_fixed), n_steps_fixed)    # [kg/s]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_T_FIELD_COLD_IN, self.allocate("T_field_cold_in", n_steps_fixed), n_steps_fixed)       # [C]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_T_REC_COLD_IN, self.allocate("T_rec_cold_in", n_steps_fixed), n_steps_fixed)           # [C]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_T_REC_HOT_OUT, self.allocate("T_rec_hot_out", n_steps_fixed), n_steps_fixed)           # [C]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_X_REC_HOT_OUT, self.allocate("x_rec_hot_out", n_steps_fixed), n_steps_fixed)           # [-]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_T_FIELD_HOT_OUT, self.allocate("T_field_hot_out", n_steps_fixed), n_steps_fixed)       # [C]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_X_FIELD_HOT_OUT, self.allocate("x_field_hot_out", n_steps_fixed), n_steps_fixed)       # [-]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_PRESSURE_DROP, self.allocate("deltaP_field", n_steps_fixed), n_steps_fixed)            # [bar]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_W_DOT_SCA_TRACK, self.allocate("W_dot_sca_track", n_steps_fixed), n_steps_fixed)       # [MWe]
        c_lf_dsg.mc_reported_outputs.assign(C_csp_lf_dsg_collector_receiver.E_W_DOT_PUMP, self.allocate("W_dot_field_pump", n_steps_fixed), n_steps_fixed)           # [MWe]

        var steam_heat_sink = C_pc_steam_heat_sink()
        steam_heat_sink.ms_params.m_x_hot_des = self.as_double("x_b_des")        # [-] Inlet quality = field outlet
        steam_heat_sink.ms_params.m_T_hot_des = self.as_double("T_hot")            # [C] Inlet temperature = field outlet
        steam_heat_sink.ms_params.m_P_hot_des = self.as_double("P_turb_des") * 100.0   # [kPa], convert from [bar], Inlet pressure = field outlet = design
        steam_heat_sink.ms_params.m_T_cold_des = self.as_double("T_cold_ref")     # [C] Outlet temperature = FIELD design inlet temperature
        steam_heat_sink.ms_params.m_dP_frac_des = self.as_double("heat_sink_dP_frac") # [-] Fractional pressure drop through heat sink at design
        steam_heat_sink.ms_params.m_q_dot_des = self.as_double("q_pb_des")        # [MWt] Design thermal power to heat sink
        steam_heat_sink.ms_params.m_m_dot_max_frac = c_lf_dsg.m_cycle_max_fraction  # [-]
        steam_heat_sink.ms_params.m_pump_eta_isen = self.as_double("eta_pump")            # [-] 
        steam_heat_sink.mc_reported_outputs.assign(C_pc_steam_heat_sink.E_Q_DOT_HEAT_SINK, self.allocate("q_dot_to_heat_sink", n_steps_fixed), n_steps_fixed)
        steam_heat_sink.mc_reported_outputs.assign(C_pc_steam_heat_sink.E_W_DOT_PUMPING, self.allocate("W_dot_heat_sink_pump", n_steps_fixed), n_steps_fixed)

        var tou = C_csp_tou_block_schedules()
        tou.setup_block_uniform_tod()
        tou.mc_dispatch_params.m_dispatch_optimize = false

        var system = C_csp_solver.S_csp_system_params()
        system.m_pb_fixed_par = 0.0
        system.m_bop_par = 0.0
        system.m_bop_par_f = 0.0
        system.m_bop_par_0 = 0.0
        system.m_bop_par_1 = 0.0
        system.m_bop_par_2 = 0.0

        var storage = C_csp_two_tank_tes()

        var csp_solver = C_csp_solver(weather_reader,
                                     c_lf_dsg,
                                     steam_heat_sink,
                                     storage,
                                     tou,
                                     system,
                                     ssc_cmod_update,
                                     Pointer[Void](self))

        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.TIME_FINAL, self.allocate("time_hr", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.MONTH, self.allocate("month", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.HOUR_DAY, self.allocate("hour_day", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.SOLAZ, self.allocate("solazi", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.SOLZEN, self.allocate("solzen", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.BEAM, self.allocate("beam", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.TDRY, self.allocate("tdry", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.TWET, self.allocate("twet", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.WSPD, self.allocate("wspd", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.PRES, self.allocate("pres", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.W_DOT_NET, self.allocate("W_dot_parasitic_tot", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.OP_MODE_1, self.allocate("op_mode_1", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.OP_MODE_2, self.allocate("op_mode_2", n_steps_fixed), n_steps_fixed)
        csp_solver.mc_reported_outputs.assign(C_csp_solver.C_solver_outputs.OP_MODE_3, self.allocate("op_mode_3", n_steps_fixed), n_steps_fixed)

        self.update("Initialize linear direct steam process heat model...", 0.0)

        var out_type: Int = -1
        var out_msg: String = ""
        try:
            csp_solver.init()
        except C_csp_exception as csp_exception:
            while csp_solver.mc_csp_messages.get_message(Pointer[Int](out_type), Pointer[String](out_msg)):
                self.log(out_msg, out_type)
            raise exec_error("linear_fresnel_dsg_iph", csp_exception.m_error_message)

        while csp_solver.mc_csp_messages.get_message(Pointer[Int](out_type), Pointer[String](out_msg)):
            self.log(out_msg, out_type)

        try:
            csp_solver.Ssimulate(sim_setup)
        except C_csp_exception as csp_exception:
            while csp_solver.mc_csp_messages.get_message(Pointer[Int](out_type), Pointer[String](out_msg)):
                self.log(out_msg)
            raise exec_error("linear_fresnel_dsg_iph", csp_exception.m_error_message)

        while csp_solver.mc_csp_messages.get_message(Pointer[Int](out_type), Pointer[String](out_msg)):
            self.log(out_msg, out_type)

        var count: Int
        var p_time_final_hr = self.as_array("time_hr", Pointer[Int](count))
        if count != n_steps_fixed:
            raise exec_error("linear_fresnel_dsg_iph", "The number of fixed steps does not match the length of output data arrays")
        var p_q_dot_heat_sink = self.as_array("q_dot_to_heat_sink", Pointer[Int](count))
        if count != n_steps_fixed:
            raise exec_error("linear_fresnel_dsg_iph", "The number of fixed steps does not match the length of output data arrays")

        var haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("linear_fresnel_dsg_iph", "failed to setup adjustment factors: " + haf.error())

        var p_gen = self.allocate("gen", n_steps_fixed)
        var p_W_dot_par_tot_haf = self.allocate("W_dot_par_tot_haf", n_steps_fixed)
        var p_W_dot_parasitic_tot = self.as_array("W_dot_parasitic_tot", Pointer[Int](count))

        for i in range(n_steps_fixed):
            var hour: Int = Int(ceil(p_time_final_hr[i]))
            p_gen[i] = p_q_dot_heat_sink[i] * ssc_number_t(haf(hour) * 1.E3)       # [kWt]
            p_W_dot_parasitic_tot[i] *= -1.0            # [kWe] Label is total parasitics, so change to a positive value
            p_W_dot_par_tot_haf[i] = ssc_number_t(p_W_dot_parasitic_tot[i] * haf(hour) * 1.E3)        # [kWe]

        self.accumulate_annual_for_year("gen", "annual_field_energy", sim_setup.m_report_step / 3600.0, steps_per_hour)  # [kWt-hr]
        self.accumulate_annual_for_year("W_dot_par_tot_haf", "annual_electricity_consumption", sim_setup.m_report_step / 3600.0, steps_per_hour)  # [kWe-hr]
        self.accumulate_annual_for_year("q_dot_freeze_prot", "annual_thermal_consumption", sim_setup.m_report_step / 3600.0 * 1.E3, steps_per_hour)  # [kWt-hr]

        var annual_field_energy = self.as_number("annual_field_energy")   # [kWt-hr]
        var annual_thermal_consumption = self.as_number("annual_thermal_consumption")   # [kWt-hr]
        self.assign("annual_energy", annual_field_energy - annual_thermal_consumption)   # [kWt-hr]

        var A_aper_tot = csp_solver.get_cr_aperture_area()   # [m2]
        var V_water_mirrors = self.as_double("csp.lf.sf.water_per_wash") / 1000.0 * A_aper_tot * self.as_double("csp.lf.sf.washes_per_year")
        self.assign("annual_total_water_use", ssc_number_t(V_water_mirrors))   # [m3]

        var ae = self.as_number("annual_energy")            # [kWt-hr]
        var nameplate = self.as_double("q_pb_des") * 1.e3   # [kWt]
        var kWh_per_kW = ae / nameplate
        self.assign("capacity_factor", ssc_number_t(kWh_per_kW / 8760.0 * 100.0))
        self.assign("kwh_per_kw", ssc_number_t(kWh_per_kW))

DEFINE_MODULE_ENTRY(linear_fresnel_dsg_iph, "CSP model using the linear fresnel TCS types.", 1)