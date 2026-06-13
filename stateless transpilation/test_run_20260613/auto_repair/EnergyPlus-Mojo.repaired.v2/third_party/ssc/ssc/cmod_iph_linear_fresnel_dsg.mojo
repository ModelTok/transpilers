from core import *
from tckernel import *
from common import *
from lib_weatherfile import *
from csp_solver_lf_dsg_collector_receiver import *
from csp_solver_pc_heat_sink import *
from csp_solver_tou_block_schedules import *
from csp_solver_two_tank_tes import *

var _cm_vtab_iph_linear_fresnel_dsg: var_info[] = [
/*	EXAMPLE LINES FOR INPUTS
    { SSC_INPUT,        SSC_NUMBER,      "XXXXXXXXXXXXXX",    "Label",                                                                               "",              "",            "sca",            "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "INTINTINTINT",      "Label",                                                                               "",              "",            "parasitic",      "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_ARRAY,       "XXXXXXXXXXX",       "Number indicating the receiver type",                                                 "",              "",            "hce",            "*",                       "",                      "" },
    { SSC_INPUT,        SSC_MATRIX,      "XXXXXXXXXXX",       "Label",                                                                               "",              "",            "tes",            "*",                       "",                      "" },
*/
    { SSC_INPUT,        SSC_STRING,      "file_name",         "local weather file path",                                                             "",              "",            "Weather",        "*",                       "LOCAL_FILE",            "" },
    { SSC_INPUT,        SSC_NUMBER,      "track_mode",        "Tracking mode",                                                                       "",              "",            "Weather",        "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "tilt",              "Tilt angle of surface/axis",                                                          "",              "",            "Weather",        "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "azimuth",           "Azimuth angle of surface/axis",                                                       "",              "",            "Weather",        "*",                       "",                      "" },
	{ SSC_INPUT,        SSC_NUMBER,      "system_capacity",   "Nameplate capacity",                                                                 "kW",             "",            "linear fresnelr", "*", "", "" },
    { SSC_INPUT,        SSC_MATRIX,      "weekday_schedule",  "12x24 Time of Use Values for week days",                                              "",             "",             "tou_translator", "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_MATRIX,      "weekend_schedule",  "12x24 Time of Use Values for week end days",                                          "",             "",             "tou_translator", "*",                       "",                      "" }, 
    { SSC_INPUT,        SSC_NUMBER,      "tes_hours",         "Equivalent full-load thermal storage hours",                                          "hr",            "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "q_max_aux",         "Maximum heat rate of the auxiliary heater",                                           "MW",            "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "LHV_eff",           "Fuel LHV efficiency (0..1)",                                                          "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "x_b_des",           "Design point boiler outlet steam quality",                                            "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_turb_des",        "Design-point turbine inlet pressure",                                                 "bar",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_hdr_c",          "Average design-point cold header pressure drop fraction",                             "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_sf_boil",        "Design-point pressure drop across the solar field boiler fraction",                   "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_boil_to_sh",     "Design-point pressure drop between the boiler and superheater frac",                  "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_sf_sh",          "Design-point pressure drop across the solar field superheater frac",                  "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fP_hdr_h",          "Average design-point hot header pressure drop fraction",                              "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "q_pb_des",          "Design heat input to the power block",                                                "MW",            "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "cycle_max_fraction","Maximum turbine over design operation fraction",                                      "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown",                                  "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "t_sby",             "Low resource standby period",                                                         "hr",            "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "q_sby_frac",        "Fraction of thermal power required for standby",                                      "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "solarm",            "Solar multiple",                                                                      "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "PB_pump_coef",      "Pumping power required to move 1kg of HTF through power block flow",                  "kW/kg",         "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "PB_fixed_par",      "fraction of rated gross power consumed at all hours of the year",                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_ARRAY,       "bop_array",         "BOP_parVal, BOP_parPF, BOP_par0, BOP_par1, BOP_par2",                                 "-",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_ARRAY,       "aux_array",         "Aux_parVal, Aux_parPF, Aux_par0, Aux_par1, Aux_par2",                                 "-",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "fossil_mode",       "Operation mode for the fossil backup {1=Normal,2=supp,3=toppin}",                     "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "I_bn_des",          "Design point irradiation value",                                                      "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "is_sh",             "Does the solar field include a superheating section",                                 "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "is_oncethru",       "Flag indicating whether flow is once through with superheat",                         "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "is_multgeom",       "Does the superheater have a different geometry from the boiler {1=yes}",              "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "nModBoil",          "Number of modules in the boiler section",                                             "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "nModSH",            "Number of modules in the superheater section",                                        "none",          "",            "solarfield",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "nLoops",            "Number of loops",                                                                     "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "eta_pump",          "Feedwater pump efficiency",                                                           "none",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "latitude",          "Site latitude resource page",                                                         "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "theta_stow",        "stow angle",                                                                          "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "theta_dep",         "deploy angle",                                                                        "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "m_dot_min",         "Minimum loop flow rate",                                                              "kg/s",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_fp",              "Freeze protection temperature (heat trace activation temperature)",                   "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "Pipe_hl_coef",      "Loss coefficient from the header.. runner pipe.. and non-HCE pipin",                  "W/m2-K",        "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "SCA_drives_elec",   "Tracking power.. in Watts per SCA drive",                                             "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "ColAz",             "Collector azimuth angle",                                                             "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "e_startup",         "Thermal inertia contribution per sq meter of solar field",                            "kJ/K-m2",       "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_amb_des_sf",      "Design-point ambient temperature",                                                    "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "V_wind_max",        "Maximum allowable wind velocity before safety stow",                                  "m/s",           "",            "solarfield",     "*",                       "",                      "" },
	{ SSC_INPUT,        SSC_NUMBER,      "csp.lf.sf.water_per_wash",  "Water usage per wash",                "L/m2_aper",    "",    "heliostat", "*", "", "" },
	{ SSC_INPUT,        SSC_NUMBER,      "csp.lf.sf.washes_per_year", "Mirror washing frequency",            "",             "",    "heliostat", "*", "", "" },
	{ SSC_INPUT,        SSC_ARRAY,       "ffrac",             "Fossil dispatch logic - TOU periods",                                                 "none",          "",            "solarfield",     "*",                       "",                      "" },
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
    { SSC_INPUT,        SSC_NUMBER,      "dnifc",             "Forecast DNI",                                                                        "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "I_bn",              "Beam normal radiation (input kJ/m2-hr)",                                              "W/m2",          "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_db",              "Dry bulb air temperature",                                                            "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_dp",              "The dewpoint temperature",                                                            "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_amb",             "Ambient pressure",                                                                    "atm",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "V_wind",            "Ambient windspeed",                                                                   "m/s",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "m_dot_htf_ref",     "Reference HTF flow rate at design conditions",                                        "kg/hr",         "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "m_pb_demand",       "Demand htf flow from the power block",                                                "kg/hr",         "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "shift",             "Shift in longitude from local standard meridian",                                     "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "SolarAz_init",      "Solar azimuth angle",                                                                 "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "SolarZen",          "Solar zenith angle",                                                                  "deg",           "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_pb_out_init",     "Fluid temperature from the power block",                                              "C",             "",            "solarfield",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "eta_ref",           "Reference conversion efficiency at design condition",                                 "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_cold_ref",        "Reference HTF outlet temperature at design",                                          "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "dT_cw_ref",         "Reference condenser cooling water inlet/outlet T diff",                               "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_amb_des",         "Reference ambient temperature at design point",                                       "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "q_sby_frac",        "Fraction of thermal power required for standby mode",                                 "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_boil_des",        "Boiler operating pressure @ design",                                                  "bar",           "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_rh_ref",          "Reheater operating pressure at design",                                               "bar",           "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "rh_frac_ref",       "Reheater flow fraction at design",                                                    "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "CT",                "Flag for using dry cooling or wet cooling system",                                    "none",          "",            "powerblock",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_NUMBER,      "startup_time",      "Time needed for power block startup",                                                 "hr",            "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "startup_frac",      "Fraction of design thermal power needed for startup",                                 "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_approach",        "Cooling tower approach temperature",                                                  "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_ITD_des",         "ITD at design for dry system",                                                        "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_cond_ratio",      "Condenser pressure ratio",                                                            "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "pb_bd_frac",        "Power block blowdown steam fraction ",                                                "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_cond_min",        "Minimum condenser pressure",                                                          "inHg",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "n_pl_inc",          "Number of part-load increments for the heat rejection system",                        "none",          "",            "powerblock",     "*",                       "INTEGER",               "" },
    { SSC_INPUT,        SSC_ARRAY,       "F_wc",              "Fraction indicating wet cooling use for hybrid system",                               "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "pc_mode",           "Cycle part load control, from plant controller",                                      "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_hot",             "Hot HTF inlet temperature, from storage tank",                                        "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "m_dot_st",          "HTF mass flow rate",                                                                  "kg/hr",         "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_wb",              "Ambient wet bulb temperature",                                                        "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "demand_var",        "Control signal indicating operational mode",                                          "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "standby_control",   "Control signal indicating standby mode",                                              "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "T_db_pwb",          "Ambient dry bulb temperature",                                                        "C",             "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "P_amb_pwb",         "Ambient pressure",                                                                    "atm",           "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "relhum",            "Relative humidity of the ambient air",                                                "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "f_recSU",           "Fraction powerblock can run due to receiver startup",                                 "none",          "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "dp_b",              "Pressure drop in boiler",                                                             "Pa",            "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "dp_sh",             "Pressure drop in superheater",                                                        "Pa",            "",            "powerblock",     "*",                       "",                      "" },
    { SSC_INPUT,        SSC_NUMBER,      "dp_rh",             "Pressure drop in reheater",                                                           "Pa",            "",            "powerblock",     "*",                       "",                      "" },
	{ SSC_OUTPUT, SSC_ARRAY, "Q_thermal", "Thermal power to HTF", "MWt", "", "CR", "", "", "" },
	{ SSC_OUTPUT, SSC_ARRAY, "gen", "Total electric power to grid w/ avail. derate", "kWe", "", "System", "", "", "" },
	var_info_invalid ]

class cm_iph_linear_fresnel_dsg(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        tcKernel.__init__(self, prov)
        self.add_var_info(_cm_vtab_iph_linear_fresnel_dsg)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        c_lf_dsg = C_csp_lf_dsg_collector_receiver()
        c_lf_dsg.m_tes_hours = as_double("tes_hours")  # TSHOURS )
        c_lf_dsg.m_q_max_aux = as_double("q_max_aux")*1.0E3 # q_max_aux )
        c_lf_dsg.m_LHV_eff = as_double("LHV_eff") # LHV_eff )
        c_lf_dsg.m_T_set_aux = as_double("T_hot") + 273.15
        c_lf_dsg.m_T_field_in_des = as_double("T_cold_ref") +273.15
        c_lf_dsg.m_T_field_out_des = as_double("T_hot") + 273.15
        c_lf_dsg.m_x_b_des = as_double("x_b_des") # x_b_des )
        c_lf_dsg.m_P_turb_des = as_double("P_turb_des") # P_turb_des )
        c_lf_dsg.m_fP_hdr_c = as_double("fP_hdr_c") # fP_hdr_c )
        c_lf_dsg.m_fP_sf_boil = as_double("fP_sf_boil") # fP_sf_boil )
        c_lf_dsg.m_fP_boil_to_sh = as_double("fP_boil_to_sh") # fP_boil_to_SH )
        c_lf_dsg.m_fP_sf_sh = as_double("fP_sf_sh") # fP_sf_sh )
        c_lf_dsg.m_fP_hdr_h = as_double("fP_hdr_h") # fP_hdr_h )
        c_lf_dsg.m_q_pb_des = as_double("q_pb_des")*1000.0 # Q_ref ) # = P_ref/eta_ref
        c_lf_dsg.m_W_pb_des = as_double("demand_var")*1000.0
        c_lf_dsg.m_cycle_max_fraction = as_double("cycle_max_fraction") # cycle_max_fraction )
        c_lf_dsg.m_cycle_cutoff_frac = as_double("cycle_cutoff_frac") # cycle_cutoff_frac )
        c_lf_dsg.m_t_sby_des = as_double("t_sby") # t_sby )
        c_lf_dsg.m_q_sby_frac = as_double("q_sby_frac") # q_sby_frac )
        c_lf_dsg.m_solarm = as_double("solarm") # solarm )
        c_lf_dsg.m_PB_pump_coef = as_double("PB_pump_coef") # PB_pump_coef )
        c_lf_dsg.m_PB_fixed_par = as_double("PB_fixed_par") # PB_fixed_par )	c_lf_dsg.q_max_aux = as_double("T_startup", as_double("T_hot"))
        c_lf_dsg.m_fossil_mode = as_double("fossil_mode") # fossil_mode )
        c_lf_dsg.m_I_bn_des = as_double("I_bn_des") # I_bn_des )
        c_lf_dsg.m_is_sh = 0 # remove superheaters
        c_lf_dsg.m_is_oncethru = bool(as_double("is_oncethru")) # is_oncethru ) ? bool
        c_lf_dsg.m_is_multgeom = bool(as_double("is_multgeom")) # is_multgeom ) 
        c_lf_dsg.m_nModBoil = as_integer("nModBoil") # nModBoil )
        c_lf_dsg.m_nModSH = as_integer("nModSH") # nModSH )
        c_lf_dsg.m_nLoops = as_integer("nLoops") # nLoops )
        c_lf_dsg.m_eta_pump = as_double("eta_pump") # eta_pump )
        c_lf_dsg.m_latitude = as_double("latitude")*0.0174533 # latitude )
        c_lf_dsg.m_theta_stow = as_double("theta_stow")*0.0174533 # theta_stow )
        c_lf_dsg.m_theta_dep = as_double("theta_dep")*0.0174533 # theta_dep )
        c_lf_dsg.m_m_dot_min = as_double("m_dot_min") # m_dot_min )
        c_lf_dsg.m_T_field_ini = as_double("T_cold_ref") +275.15
        c_lf_dsg.m_T_fp = as_double("T_fp") + 273.15 # T_fp )
        c_lf_dsg.m_Pipe_hl_coef = as_double("Pipe_hl_coef") # Pipe_hl_coef )
        c_lf_dsg.m_SCA_drives_elec = as_double("SCA_drives_elec") # SCA_drives_elec )
        c_lf_dsg.m_ColAz = as_double("ColAz")*0.0174533 # ColAz )
        c_lf_dsg.m_e_startup = as_double("e_startup") # e_startup )
        c_lf_dsg.m_T_amb_des_sf = as_double("T_amb_des_sf") +273.15 # T_amb_des_sf )
        c_lf_dsg.m_V_wind_max = as_double("V_wind_max") # V_wind_max )		
        nval_bop_array: size_t = -1
        bop_array = as_array("bop_array", &nval_bop_array)
        c_lf_dsg.m_bop_array.resize(nval_bop_array)
        for i in range(nval_bop_array):
            c_lf_dsg.m_bop_array[i] = float(bop_array[i])
        nval_aux_array: size_t = -1
        aux_array = as_array("aux_array", &nval_aux_array)
        c_lf_dsg.m_aux_array.resize(nval_aux_array)
        for i in range(nval_aux_array):
            c_lf_dsg.m_aux_array[i] = float(aux_array[i])
        nval_ffrac: size_t = -1
        ffrac = as_array("ffrac", &nval_ffrac)
        c_lf_dsg.m_ffrac.resize(nval_ffrac)
        for i in range(nval_ffrac):
            c_lf_dsg.m_ffrac[i] = float(ffrac[i])
        m_n_rows_matrix: float64 = 1
        if c_lf_dsg.m_is_multgeom:
            m_n_rows_matrix = 2
        c_lf_dsg.m_n_rows_matrix = m_n_rows_matrix
        c_lf_dsg.m_A_aperture = as_matrix("A_aperture") #A_aper)
        c_lf_dsg.m_L_col = as_matrix("L_col") #L_col)
        c_lf_dsg.m_OptCharType = as_matrix("OptCharType") #OptCharType)
        c_lf_dsg.m_IAM_T = as_matrix("IAM_T") #IAM_T)
        c_lf_dsg.m_IAM_L = as_matrix("IAM_L") #IAM_L)
        c_lf_dsg.m_TrackingError = as_matrix("TrackingError") #TrackingError)
        c_lf_dsg.m_GeomEffects = as_matrix("GeomEffects") #GeomEffects)
        c_lf_dsg.m_rho_mirror_clean = as_matrix("rho_mirror_clean") #rho_mirror_clean)
        c_lf_dsg.m_dirt_mirror = as_matrix("dirt_mirror") #dirt_mirror)
        c_lf_dsg.m_error = as_matrix("error") #error)
        c_lf_dsg.m_HLCharType = as_matrix("HLCharType") #HLCharType)
        c_lf_dsg.m_HL_dT = as_matrix("HL_dT") #HL_dT)
        c_lf_dsg.m_HL_W = as_matrix("HL_W") #HL_W)
        c_lf_dsg.m_D_2 = as_matrix("D_2") #D_2)
        c_lf_dsg.m_D_3 = as_matrix("D_3") #D_3)
        c_lf_dsg.m_D_4 = as_matrix("D_4") #D_4)
        c_lf_dsg.m_D_5 = as_matrix("D_5") #D_5)
        c_lf_dsg.m_D_p = as_matrix("D_p") #D_p)
        c_lf_dsg.m_Rough = as_matrix("Rough") #Rough)
        c_lf_dsg.m_Flow_type = as_matrix("Flow_type") #Flow_type)
        c_lf_dsg.m_AbsorberMaterial_in = as_matrix("AbsorberMaterial")
        c_lf_dsg.m_HCE_FieldFrac = as_matrix("HCE_FieldFrac") #HCE_FieldFrac)
        c_lf_dsg.m_alpha_abs = as_matrix("alpha_abs") #alpha_abs)
        c_lf_dsg.m_b_eps_HCE1 = as_matrix("b_eps_HCE1") #b_eps_HCE1)
        c_lf_dsg.m_b_eps_HCE2 = as_matrix("b_eps_HCE2") #b_eps_HCE2)
        c_lf_dsg.m_b_eps_HCE3 = as_matrix("b_eps_HCE3") #b_eps_HCE3)
        c_lf_dsg.m_b_eps_HCE4 = as_matrix("b_eps_HCE4") #b_eps_HCE4)
        if c_lf_dsg.m_is_multgeom != 0:
            c_lf_dsg.m_sh_eps_HCE1 = as_matrix("sh_eps_HCE1") #s_eps_HCE1)
            c_lf_dsg.m_sh_eps_HCE2 = as_matrix("sh_eps_HCE2") #s_eps_HCE2)
            c_lf_dsg.m_sh_eps_HCE3 = as_matrix("sh_eps_HCE3") #s_eps_HCE3)
            c_lf_dsg.m_sh_eps_HCE4 = as_matrix("sh_eps_HCE4") #s_eps_HCE4)
        c_lf_dsg.m_alpha_env = as_matrix("alpha_env") #alpha_env) [-] Envelope absorptance
        c_lf_dsg.m_EPSILON_4 = as_matrix("EPSILON_4") #EPSILON_4) [-] Inner glass envelope emissivities (Pyrex)
        c_lf_dsg.m_Tau_envelope = as_matrix("Tau_envelope") #Tau_envelope) [-] Envelope transmittance
        c_lf_dsg.m_GlazingIntactIn = bool(as_matrix("GlazingIntactIn")) #GlazingIntactIn) [-] Is the glazing intact?
        c_lf_dsg.m_AnnulusGas_in = as_matrix("AnnulusGas") #AnnulusGas)
        c_lf_dsg.m_P_a = as_matrix("P_a") #P_a) [torr] Annulus gas pressure 
        c_lf_dsg.m_Design_loss = as_matrix("Design_loss") #Design_loss) [W/m] Receiver heat loss at design
        c_lf_dsg.m_Shadowing = as_matrix("Shadowing") #Shadowing) [-] Receiver bellows shadowing loss factor
        c_lf_dsg.m_Dirt_HCE = as_matrix("Dirt_HCE") #Dirt_HCE) [-] Loss due to dirt on the receiver envelope
        c_lf_dsg.m_b_OpticalTable = as_matrix("b_OpticalTable") # opt_data) [-] Boiler Optical Table
        c_lf_dsg.m_sh_OpticalTable = as_matrix("sh_OpticalTable") # opt_data)
        c_lf_dsg.m_is_multgeom = False # single geometry  is used
        c_lf_dsg.m_is_sh = False # no superheater
        heat_sink = C_pc_heat_sink()
        heat_sink.ms_params.m_T_htf_hot_des = as_double("T_loop_out")		#[C] FIELD design outlet temperature
        heat_sink.ms_params.m_T_htf_cold_des = as_double("T_field_in")	#[C] FIELD design inlet temperature
        heat_sink.ms_params.m_q_dot_des = as_double("q_pb_des")	#[MWt] FIELD design thermal power
        heat_sink.ms_params.m_htf_pump_coef = as_double("PB_pump_coef")	#[kWe/kg/s]
        tou = C_csp_tou_block_schedules()
        tou.setup_block_uniform_tod()
        tou.mc_dispatch_params.m_dispatch_optimize = False
        system = C_csp_solver.S_csp_system_params()
        system.m_pb_fixed_par = as_double("pb_fixed_par")
        system.m_bop_par = 0.0
        system.m_bop_par_f = 0.0
        system.m_bop_par_0 = 0.0
        system.m_bop_par_1 = 0.0
        system.m_bop_par_2 = 0.0
        storage = C_csp_two_tank_tes()
        tes = storage.ms_params
        weather_reader = C_csp_weatherreader()
        weather_reader.m_filename = as_string("file_name")
        weather_reader.m_trackmode = 0
        weather_reader.m_tilt = 0.0
        weather_reader.m_azimuth = 0.0
        weather_reader.init()
        c_lf_dsg.m_nSCA = c_lf_dsg.m_nModBoil
        c_lf_dsg.m_m_dot_htfmin = c_lf_dsg.m_m_dot_min
        c_lf_dsg.m_m_dot_htfmax = c_lf_dsg.m_m_dot_max
        c_lf_dsg.m_P_out_des = c_lf_dsg.m_P_turb_des
        csp_solver = C_csp_solver(weather_reader, c_lf_dsg, heat_sink, storage, tou, system)

DEFINE_TCS_MODULE_ENTRY(iph_linear_fresnel_dsg, "CSP model using the linear fresnel TCS types.", 4)