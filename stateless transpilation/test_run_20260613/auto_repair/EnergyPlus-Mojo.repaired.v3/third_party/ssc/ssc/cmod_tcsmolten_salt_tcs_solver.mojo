from core import *
from tckernel import *
from common import *
from AutoPilot_API import *
from SolarField import *
from IOUtil import *
from csp_common import *

var _cm_vtab_tcsmolten_salt: StaticArray[var_info, 1] = StaticArray[var_info](
    var_info(SSC_INPUT,        SSC_STRING,      "solar_resource_file",  "local weather file path",                                           "",             "",            "Weather",        "*",                       "LOCAL_FILE",            "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "system_capacity",      "Nameplate capacity",                                                "kW",           "",            "molten salt tower", "*",                    "",   "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "weekday_schedule",     "12x24 Time of Use Values for week days",                            "",             "",            "tou_translator", "*",                       "",                      "" ), 
    var_info(SSC_INPUT,        SSC_MATRIX,      "weekend_schedule",     "12x24 Time of Use Values for week end days",                        "",             "",            "tou_translator", "*",                       "",                      "" ), 
    var_info(SSC_INPUT,        SSC_NUMBER,      "run_type",             "Run type",                                                          "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "helio_width",          "Heliostat width",                                                   "m",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "helio_height",         "Heliostat height",                                                  "m",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "helio_optical_error",  "Heliostat optical error",                                           "rad",          "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "helio_active_fraction","Heliostat active frac.",                                            "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "dens_mirror",          "Ratio of Reflective Area to Profile",                               "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "helio_reflectance",    "Heliostat reflectance",                                             "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_absorptance",      "Receiver absorptance",                                              "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_height",           "Receiver height",                                                   "m",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_aspect",           "Receiver aspect ratio",                                             "-",            "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_hl_perm2",         "Receiver design heatloss",                                          "kW/m2",        "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "land_bound_type",      "Land boundary type",                                                "-",            "",            "heliostat",      "?=0",                     "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "land_max",             "Land max boundary",                                                 "-ORm",         "",            "heliostat",      "?=7.5",                   "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "land_min",             "Land min boundary",                                                 "-ORm",         "",            "heliostat",      "?=0.75",                  "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "land_bound_table",     "Land boundary table",                                               "m",            "",            "heliostat",      "?",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "land_bound_list",      "Boundary table listing",                                            "-",            "",            "heliostat",      "?",                       "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "dni_des",              "Design-point DNI",                                                  "W/m2",         "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "p_start",              "Heliostat startup energy",                                          "kWe-hr",       "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "p_track",              "Heliostat tracking energy",                                         "kWe",          "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "hel_stow_deploy",      "Stow/deploy elevation",                                             "deg",          "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "v_wind_max",           "Max. wind velocity",                                                "m/s",          "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "interp_nug",           "Interpolation nugget",                                              "-",            "",            "heliostat",      "?=0",                     "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "interp_beta",          "Interpolation beta coef.",                                          "-",            "",            "heliostat",      "?=1.99",                  "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "n_flux_x",             "Flux map X resolution",                                             "-",            "",            "heliostat",      "?=12",                    "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "n_flux_y",             "Flux map Y resolution",                                             "-",            "",            "heliostat",      "?=1",                     "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "helio_positions",      "Heliostat position table",                                          "m",            "",            "heliostat",      "run_type=1",              "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "helio_aim_points",     "Heliostat aim point table",                                         "m",            "",            "heliostat",      "?",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "N_hel",                "Number of heliostats",                                              "-",            "",            "heliostat",      "?",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "eta_map",              "Field efficiency array",                                            "-",            "",            "heliostat",      "?",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "flux_positions",       "Flux map sun positions",                                            "deg",          "",            "heliostat",      "?",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "flux_maps",            "Flux map intensities",                                              "-",            "",            "heliostat",      "?",                       "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "c_atm_0",              "Attenuation coefficient 0",                                         "",             "",            "heliostat",      "?=0.006789",              "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "c_atm_1",              "Attenuation coefficient 1",                                         "",             "",            "heliostat",      "?=0.1046",                "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "c_atm_2",              "Attenuation coefficient 2",                                         "",             "",            "heliostat",      "?=-0.0107",               "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "c_atm_3",              "Attenuation coefficient 3",                                         "",             "",            "heliostat",      "?=0.002845",              "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "n_facet_x",            "Number of heliostat facets - X",                                    "",             "",            "heliostat",      "*",                       "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "n_facet_y",            "Number of heliostat facets - Y",                                    "",             "",            "heliostat",      "*",                       "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "focus_type",           "Heliostat focus method",                                            "",             "",            "heliostat",      "*",                       "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "cant_type",            "Heliostat cant method",                                             "",             "",            "heliostat",      "*",                       "",                     "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "n_flux_days",          "No. days in flux map lookup",                                       "",             "",            "heliostat",      "?=8",                     "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "delta_flux_hrs",       "Hourly frequency in flux map lookup",                               "",             "",            "heliostat",      "?=1",                     "",                     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "h_tower",                   "Tower height",                               "m",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "q_design",                  "Receiver thermal design power",              "MW",     "",         "heliostat",   "*",                "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "calc_fluxmaps",             "Include fluxmap calculations",               "",       "",         "heliostat",   "?=1",              "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "tower_fixed_cost",          "Tower fixed cost",                           "$",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "tower_exp",                 "Tower cost scaling exponent",                "",       "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "rec_ref_cost",              "Receiver reference cost",                    "$",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "rec_ref_area",              "Receiver reference area for cost scale",     "",       "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "rec_cost_exp",              "Receiver cost scaling exponent",             "",       "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "site_spec_cost",            "Site improvement cost",                      "$/m2",   "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "heliostat_spec_cost",       "Heliostat field cost",                       "$/m2",   "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "plant_spec_cost",           "Power cycle specific cost",                  "$/kWe",  "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "bop_spec_cost",             "BOS specific cost",                          "$/kWe",  "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "tes_spec_cost",             "Thermal energy storage cost",                "$/kWht", "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "land_spec_cost",            "Total land area cost",                       "$/acre", "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "contingency_rate",          "Contingency for cost overrun",               "%",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "sales_tax_rate",            "Sales tax rate",                             "%",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "sales_tax_frac",            "Percent of cost to which sales tax applies", "%",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "cost_sf_fixed",             "Solar field fixed cost",                     "$",      "",         "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "fossil_spec_cost",          "Fossil system specific cost",                "$/kWe",      "",     "heliostat",   "*",                "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "is_optimize",          "Do SolarPILOT optimization",                                        "",             "",            "heliostat",       "?=0",                    "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "flux_max",             "Maximum allowable flux",                                            "",             "",            "heliostat",       "?=1000",                 "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "opt_init_step",        "Optimization initial step size",                                    "",             "",            "heliostat",       "?=0.05",                 "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "opt_max_iter",         "Max. number iteration steps",                                       "",             "",            "heliostat",       "?=200",                 "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "opt_conv_tol",         "Optimization convergence tol",                                      "",             "",            "heliostat",       "?=0.001",                "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "opt_algorithm",        "Optimization algorithm",                                            "",             "",            "heliostat",       "?=0",                    "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "opt_flux_penalty",     "Flux over-design penalty",                                          "",             "",            "heliostat",       "?=0.35",                 "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.epc.per_acre",       "EPC cost per acre",                 "$/acre",   "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.epc.percent",        "EPC cost percent of direct",        "",         "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.epc.per_watt",       "EPC cost per watt",                 "$/W",      "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.epc.fixed",          "EPC fixed",                         "$",        "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.plm.per_acre",       "PLM cost per acre",                 "$/acre",   "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.plm.percent",        "PLM cost percent of direct",        "",         "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.plm.per_watt",       "PLM cost per watt",                 "$/W",      "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.cost.plm.fixed",          "PLM fixed",                         "$",        "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.sf.fixed_land_area",      "Fixed land area",                   "acre",     "",     "heliostat",   "*",                "",                "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "csp.pt.sf.land_overhead_factor", "Land overhead factor",              "",         "",     "heliostat",   "*",                "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "total_installed_cost",           "Total installed cost",              "$",        "",     "heliostat",   "*",                "",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "receiver_type",        "External=0, Cavity=1",                                              "",             "",            "receiver",       "*",                       "INTEGER",               "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "N_panels",             "Number of individual panels on the receiver",                       "",             "",            "receiver",       "*",                       "INTEGER",               "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "D_rec",                "The overall outer diameter of the receiver",                        "m",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "H_rec",                "The height of the receiver",                                        "m",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "THT",                  "The height of the tower (hel. pivot to rec equator)",               "m",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "d_tube_out",           "The outer diameter of an individual receiver tube",                 "mm",           "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "th_tube",              "The wall thickness of a single receiver tube",                      "mm",           "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "mat_tube",             "The material name of the receiver tubes",                           "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_htf",              "The name of the HTF used in the receiver",                          "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "field_fl_props",       "User defined field fluid property data",                            "-",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "Flow_type",            "A flag indicating which flow pattern is used",                      "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "epsilon",              "The emissivity of the receiver surface coating",                    "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "hl_ffact",             "The heat loss factor (thermal loss fudge factor)",                  "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_htf_hot_des",        "Hot HTF outlet temperature at design conditions",                   "C",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_htf_cold_des",       "Cold HTF inlet temperature at design conditions",                   "C",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "f_rec_min",            "Minimum receiver mass flow rate turn down fraction",                "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "Q_rec_des",            "Design-point receiver thermal power output",                        "MWt",          "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_su_delay",         "Fixed startup delay time for the receiver",                         "hr",           "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_qf_delay",         "Energy-based rcvr startup delay (fraction of rated thermal power)", "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "m_dot_htf_max",        "Maximum receiver mass flow rate",                                   "kg/hr",        "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "A_sf",                 "Solar Field Area",                                                  "m^2",          "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_salt_hot_target",    "Desired HTF outlet temperature",                                    "C",            "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "eta_pump",             "Receiver HTF pump efficiency",                                      "",             "",            "receiver",       "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_d_spec",           "Receiver aperture width",                                           "m",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "h_rec_panel",          "Height of a receiver panel",                                        "m",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "h_lip",                "Height of upper lip of cavity",                                     "m",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "rec_angle",            "Section of the cavity circle covered in panels",                    "deg",          "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "conv_model",           "Type of convection model (1=Clausing, 2=Siebers/Kraabel)",          "-",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_MATRIX,      "eps_wavelength",       "Matrix containing wavelengths, active & passive surface eps",       "-",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "conv_coupled",         "1=coupled, 2=uncoupled",                                            "-",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "conv_forced",          "1=forced (use wind), 0=natural",                                    "-",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "h_wind_meas",          "Height at which wind measurements are given",                       "m",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "conv_wind_dir",        "Wind direction dependent forced convection 1=on 0=off",             "-",            "",            "cavity_receiver","*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "field_fluid",          "Material number for the collector field",                           "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tshours",              "Equivalent full-load thermal storage hours",                        "hr",           "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "q_max_aux",            "Max heat rate of auxiliary heater",                                 "MWt",          "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_set_aux",            "Aux heater outlet temp set point",                                  "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "V_tank_hot_ini",       "Initial hot tank fluid volume",                                     "m3",           "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_tank_hot_ini",       "Initial hot tank fluid temperature",                                "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_tank_cold_ini",      "Initial cold tank fluid tmeperature",                               "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "vol_tank",             "Total tank volume, including unusable HTF at bottom",               "m3",           "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "h_tank",               "Total height of tank (height of HTF when tank is full",             "m",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "h_tank_min",           "Minimum allowable HTF height in storage tank",                      "m",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "u_tank",               "Loss coefficient from the tank",                                    "W/m2-K",       "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tank_pairs",           "Number of equivalent tank pairs",                                   "-",            "",            "controller",     "*",                       "INTEGER",               "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "cold_tank_Thtr",       "Minimum allowable cold tank HTF temp",                              "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "hot_tank_Thtr",        "Minimum allowable hot tank HTF temp",                               "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "hot_tank_max_heat",    "Rated heater capacity for hot tank heating",                        "MW",           "",            "controller",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "cold_tank_max_heat",   "Rated heater capacity for cold tank heating",                       "MW",           "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_field_in_des",       "Field design inlet temperature",                                    "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_field_out_des",      "Field design outlet temperature",                                   "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "q_pb_design",          "Design heat input to power block",                                  "MWt",          "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "W_pb_design",          "Rated plant capacity",                                              "MWe",          "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "cycle_max_frac",       "Maximum turbine over design operation fraction",                    "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "cycle_cutoff_frac",    "Minimum turbine operation fraction before shutdown",                "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "solarm",               "Solar Multiple",                                                    "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "pb_pump_coef",         "Pumping power to move 1kg of HTF through PB loop",                  "kW/kg",        "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_startup",            "Startup temperature",                                               "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "fossil_mode",          "Fossil backup mode 1=Normal 2=Topping",                             "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "nSCA",                 "Number of SCAs in a single loop",                                   "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "I_bn_des",             "Design point irradiation value",                                    "W/m2",         "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "fc_on",                "DNI forecasting enabled",                                           "-",            "",            "controller",     "?=0",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "q_sby_frac",           "Fraction of thermal power required for standby",                    "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "t_standby_reset",      "Maximum allowable time for PB standby operation",                   "hr",           "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "sf_type",              "Solar field type, 1 = trough, 2 = tower",                           "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tes_type",             "1=2-tank, 2=thermocline",                                           "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "tslogic_a",            "Dispatch logic without solar",                                      "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "tslogic_b",            "Dispatch logic with solar",                                         "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "tslogic_c",            "Dispatch logic for turbine load fraction",                          "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "ffrac",                "Fossil dispatch logic",                                             "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tc_fill",              "Thermocline fill material",                                         "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tc_void",              "Thermocline void fraction",                                         "-",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "t_dis_out_min",        "Min allowable hot side outlet temp during discharge",               "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "t_ch_out_max",         "Max allowable cold side outlet temp during charge",                 "C",            "",            "controller",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "nodes",                "Nodes modeled in the flow path",                                    "-",            "",            "controller",     "*",                       "INTEGER",               "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "f_tc_cold",            "0=entire tank is hot, 1=entire tank is cold",                       "-",            "",            "controller",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "eta_lhv",              "Fossil fuel lower heating value - Thermal power generated per unit fuel",   "MW/MMBTU",     "",    "controller",     "*",                       "",                      "" ),													     																	  
    var_info(SSC_INPUT,        SSC_NUMBER,      "P_ref",                "Reference output electric power at design condition",               "MW",           "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "eta_ref",              "Reference conversion efficiency at design condition",               "none",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_htf_hot_ref",        "Reference HTF inlet temperature at design",                         "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_htf_cold_ref",       "Reference HTF outlet temperature at design",                        "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "dT_cw_ref",            "Reference condenser cooling water inlet/outlet T diff",             "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_amb_des",            "Reference ambient temperature at design point",                     "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "P_boil",               "Boiler operating pressure",                                         "bar",          "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "CT",                   "Flag for using dry cooling or wet cooling system",                  "none",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "startup_time",         "Time needed for power block startup",                               "hr",           "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "startup_frac",         "Fraction of design thermal power needed for startup",               "none",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_approach",           "Cooling tower approach temperature",                                "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "T_ITD_des",            "ITD at design for dry system",                                      "C",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "P_cond_ratio",         "Condenser pressure ratio",                                          "none",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "pb_bd_frac",           "Power block blowdown steam fraction ",                              "none",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "P_cond_min",           "Minimum condenser pressure",                                        "inHg",         "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "n_pl_inc",             "Number of part-load increments for the heat rejection system",      "none",         "",            "powerblock",     "*",                       "INTEGER",               "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "F_wc",                 "Fraction indicating wet cooling use for hybrid system",             "none",         "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "pc_config",            "0: Steam Rankine (224), 1: sCO2 Recompression (424)",               "none",         "",            "powerblock",     "?=0",                       "INTEGER",               "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "eta_c",                "Isentropic efficiency of compressor(s)",                            "none",         "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "eta_t",                "Isentropic efficiency of turbine",							      "none",         "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "P_high_limit",         "Upper pressure limit in cycle",								      "MPa",          "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "deltaT_PHX",           "Design temperature difference in PHX",						      "C",	          "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "fan_power_perc_net",   "% of net cycle output used for fan power at design",			      "%",	          "",            "powerblock",     "*",                       "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "elev",                 "Site elevation",                                                    "m",            "",            "powerblock",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "piping_loss",          "Thermal loss per meter of piping",                                  "Wt/m",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "piping_length",        "Total length of exposed piping",                                    "m",            "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "piping_length_mult",   "Piping length multiplier",                                          "",             "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "piping_length_const",  "Piping constant length",                                            "m",            "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "design_eff",           "Power cycle efficiency at design",                                  "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "pb_fixed_par",         "Fixed parasitic load - runs at all times",                          "MWe/MWcap",    "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "aux_par",              "Aux heater, boiler parasitic",                                      "MWe/MWcap",    "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "aux_par_f",            "Aux heater, boiler parasitic - multiplying fraction",               "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "aux_par_0",            "Aux heater, boiler parasitic - constant coefficient",               "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "aux_par_1",            "Aux heater, boiler parasitic - linear coefficient",                 "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "aux_par_2",            "Aux heater, boiler parasitic - quadratic coefficient",              "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "bop_par",              "Balance of plant parasitic power fraction",                         "MWe/MWcap",    "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "bop_par_f",            "Balance of plant parasitic power fraction - mult frac",             "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "bop_par_0",            "Balance of plant parasitic power fraction - const coeff",           "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "bop_par_1",            "Balance of plant parasitic power fraction - linear coeff",          "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "bop_par_2",            "Balance of plant parasitic power fraction - quadratic coeff",       "none",         "",            "parasitics",     "*",                       "",                      "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "month",             "Resource Month",                                                  "",             "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "hour",              "Resource Hour of Day",                                            "",             "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "solazi",            "Resource Solar Azimuth",                                          "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "solzen",            "Resource Solar Zenith",                                           "deg",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "beam",              "Resource Beam normal irradiance",                                 "W/m2",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tdry",              "Resource Dry bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "twet",              "Resource Wet bulb temperature",                                   "C",            "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "wspd",              "Resource Wind Speed",                                             "m/s",          "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "pres",              "Resource Pressure",                                               "mbar",         "",            "weather",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tou_value",         "Resource Time-of-use value",                                      "",             "",            "tou",            "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "eta_field",            "Field optical efficiency",                                     "",             "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "defocus",              "Field optical focus fraction",                                 "",             "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "eta_therm",            "Receiver thermal efficiency",                                    "",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "Q_solar_total",        "Receiver thermal power absorbed",                                "MWt",           "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_conv_sum",           "Receiver thermal power loss to convection",                      "MWt",           "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_rad_sum",            "Receiver thermal power loss to radiation",                       "MWt",           "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "Q_thermal",            "Receiver thermal power to HTF",                                  "MWt",           "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_startup",            "Receiver startup thermal energy consumed",                       "MWt-hr",       "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "m_dot_field",          "Receiver HTF mass flow rate",                                    "kg/hr",        "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_field_in",           "Receiver HTF temperature in",                                    "C",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_field_out",          "Receiver HTF temperature out",                                   "C",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "mass_tank_cold",       "TES HTF mass in cold tank",                                      "kg",           "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "mass_tank_hot",        "TES HTF mass in hot tank",                                       "kg",           "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "vol_tank_cold_fin",    "TES HTF volume in cold tank",                                    "m3",           "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "vol_tank_hot_fin",     "TES HTF volume in hot tank",                                     "m3",           "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "m_dot_charge_field",   "TES HTF mass flow rate (charging)",                              "kg/hr",        "",            "Type250",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "tank_losses",          "TES thermal losses from tank(s)",                                "MWt",          "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_to_tes",             "TES thermal energy into storage",                                "MWt",          "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_hot_node",           "TES [thermocline] temperature - hot node",                       "C",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_cold_node",          "TES [thermocline] temperature - cold node",                      "C",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_max",                "TES [thermocline] temperature - max",                            "C",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "f_hot",                "TES [thermocline] Hot depth fraction",                           "",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "f_cold",               "TES [thermocline] Cold depth fraction",                          "",            "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "eta",               "Cycle efficiency (gross)",                                          "",         "",            "Type224",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_out_net",         "Cycle electrical power output (net)",                               "MWe",          "",            "Net_E_Calc",     "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_cycle",           "Cycle electrical power output (gross)",                             "MWe",          "",            "Net_E_Calc",     "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "m_dot_pb",          "Cycle HTF mass flow rate",                                          "kg/hr",        "",            "Type250",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_pb_in",           "Cycle HTF temperature in (hot)",                                    "C",            "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_pb_out",          "Cycle HTF temperature out (cold)",                                  "C",            "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "m_dot_makeup",      "Cycle cooling water mass flow rate - makeup",                       "kg/hr",        "",            "Type250",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_pb",              "Cycle thermal power input",                                         "MWt",          "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_pc_startup",      "Cycle startup energy",                                        "MWt-hr",       "",            "Type251",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "T_turbine_in",         "Cycle turbine inlet temperature",                                         "C",            "",            "Outputs",        "",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_mc_in",              "Cycle main comp inlet pressure",                                          "kPa",          "",            "Outputs",        "",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_mc_out",             "Cycle main comp outlet pressure",                                         "kPa",		  "",            "Outputs",        "",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "f_recomp",             "Cycle recomp fraction",                                                   "",			  "",            "Outputs",        "",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "N_MC",                 "Cycle main comp. shaft speed",                                            "rpm",          "",            "Outputs",        "",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_cond",            "Condenser pressure",                                                "Pa",           "",            "Type250",        "*",                       "LENGTH=8760",           "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "f_bays",            "Condenser fraction of operating bays",                              "",         "",            "Type250",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_aux_heat",           "Fossil thermal power produced",                                  "MWt",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_aux_fuel",           "Fossil fuel usage",                                              "MMBTU",        "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_tower_pump",         "Parasitic power receiver HTF pump",                              "MWe",           "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "htf_pump_power",       "Parasitic power TES and Cycle HTF pump",                         "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "pparasi",              "Parasitic power heliostat drives",                               "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_plant_balance_tot",  "Parasitic power generation-dependent load",                      "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_fixed",              "Parasitic power fixed load",                                     "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_aux",                "Parasitic power auxiliary heater operation",                     "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_cooling_tower_tot",  "Parasitic power condenser operation",                            "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_piping_tot",         "Parasitic power equiv. header pipe losses",                      "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_tank_heater",        "Parasitic power TES freeze protection",                          "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "P_parasitics",         "Parasitic power total consumption",                              "MWe",          "",            "Outputs",        "*",                       "LENGTH=8760",           "" ),
	var_info(SSC_OUTPUT,       SSC_MATRIX,      "eff_lookup",           "Field efficiency lookup matrix",                                    "",             "",            "Outputs",        "*",                       "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_MATRIX,      "flux_lookup",          "Receiver flux map lookup matrix",                                   "",             "",            "Outputs",        "*",                       "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_MATRIX,      "sunpos_eval",          "Sun positions for lookup calcs",                                    "deg",          "",            "Outputs",        "*",                       "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "land_area",            "Calculated solar field land area",                                  "acre",         "",            "Outputs",        "*",                       "",                      "" ),
    var_info(SSC_OUTPUT,       SSC_MATRIX,      "opt_history",          "Step history of optimization",                                      "",             "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY, "UA_recup_des", "", "kW/K", "", "Outputs", "", "LENGTH=8760", "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY, "P_low_des", "", "kPa", "", "Outputs", "", "LENGTH=8760", "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY, "P_high_des", "", "kPa", "", "Outputs", "", "LENGTH=8760", "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY, "f_recomp_des", "", "", "", "Outputs", "", "LENGTH=8760", "" ),
	var_info(SSC_OUTPUT, SSC_ARRAY, "UA_PHX_des", "", "", "", "Outputs", "", "LENGTH=8760", "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,       "UA_recup_des_value",         "Cycle: Recuperator conductance",                                           "kW/K",         "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,       "P_low_des_value",            "Cycle: Main compressor inlet pressure",                                    "kPa",          "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,       "P_high_des_value",           "Cycle: Main compressor outlet pressure",                                   "kPa",          "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,       "f_recomp_des_value",         "Cycle: Recompression fraction",                                            "",             "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,       "UA_PHX_des_value",           "Cycle: PHX conductance",                                                   "kW/K",         "",            "Outputs",        "",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "m_dot_balance",        "Relative mass flow balance error",                             "",             "",            "Controller",     "*",                       "",           "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "q_balance",            "Relative energy balance error",                                "",             "",            "Controller",     "*",                       "",           "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy",        "Annual energy",                                "kWh",         "",    "Type228",    "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "annual_W_cycle_gross", "Electrical source - Power cycle gross output", "kWh",         "",    "Type228",    "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "conversion_factor",    "Gross to Net Conversion Factor",                "%",          "",    "Calculated", "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor",      "Capacity factor",                               "%",          "",    "",           "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw",           "First year kWh/kW",                             "kWh/kW",     "",    "",           "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate",     "System heat rate",                              "MMBtu/MWh",  "",    "",           "*", "", "" ),
	var_info(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage",     "Annual fuel usage",                            "kWh",        "",    "",           "*", "", "" ),
	var_info_invalid
)

class cm_tcsmolten_salt(tcKernel):
    def __init__(self, prov: tcstypeprovider):
        tcKernel.__init__(self, prov)
        self.add_var_info(_cm_vtab_tcsmolten_salt)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        weather: int = 0
        avg_temp: float64 = 0.0
        avg_wind_v: float64 = 0.0
        #ifdef DEBUG_WITH_TRNSYS_READER
        #	weather = add_unit("trnsys_weatherreader", "TRNSYS weather reader");
        #	set_unit_value( weather, "file_name", "C:/svn_NREL/main/ssc/tcsdata/typelib/TRNSYS_weather_outputs/daggett_trnsys_weather.out" );
        #	set_unit_value( weather, "i_hour", "TIME" );
        #	set_unit_value( weather, "i_month", "month" );
        #	set_unit_value( weather, "i_day", "day" );
        #	set_unit_value( weather, "i_global", "GlobalHorizontal" );
        #	set_unit_value( weather, "i_beam", "DNI" );
        #	set_unit_value( weather, "i_diff", "DiffuseHorizontal" );
        #	set_unit_value( weather, "i_tdry", "T_dry" );
        #	set_unit_value( weather, "i_twet", "T_wet" );
        #	set_unit_value( weather, "i_tdew", "T_dew" );
        #	set_unit_value( weather, "i_wspd", "WindSpeed" );
        #	set_unit_value( weather, "i_wdir", "WindDir" );
        #	set_unit_value( weather, "i_rhum", "RelHum" );
        #	set_unit_value( weather, "i_pres", "AtmPres" );
        #	set_unit_value( weather, "i_snow", "SnowCover" );
        #	set_unit_value( weather, "i_albedo", "GroundAlbedo" );
        #	set_unit_value( weather, "i_poa", "POA" );
        #	set_unit_value( weather, "i_solazi", "Azimuth" );
        #	set_unit_value( weather, "i_solzen", "Zenith" );
        #	set_unit_value( weather, "i_lat", "Latitude" );
        #	set_unit_value( weather, "i_lon", "Longitude" );
        #	set_unit_value( weather, "i_shift", "Shift" );
        #else
        weather = self.add_unit("weatherreader", "TCS weather reader")
        self.set_unit_value(weather, "file_name", self.as_string("solar_resource_file"))
        self.set_unit_value(weather, "track_mode", 0.0)
        self.set_unit_value(weather, "tilt", 0.0)
        self.set_unit_value(weather, "azimuth", 0.0)
        #endif
        avg_temp = 10.3 if self.as_integer("receiver_type") == 0 else 15
        avg_wind_v = 0.0
        is_steam_pc: bool = True
        pb_tech_type: int = self.as_integer("pc_config")
        if pb_tech_type == 1:
            pb_tech_type = 424
            is_steam_pc = False
        tou: int = self.add_unit("tou_translator", "Time of Use Translator")
        type251_controller: int = 0
        type_hel_field: int = 0
        type222_receiver: int = 0
        type232_cav_rec: int = 0
        if is_steam_pc:
            type_hel_field = self.add_unit("sam_mw_pt_heliostatfield")
            if self.as_integer("receiver_type") == 0:
                type222_receiver = self.add_unit("sam_mw_pt_type222")
            else:
                type232_cav_rec = self.add_unit("sam_lf_st_pt_type232")
            type251_controller = self.add_unit("sam_mw_trough_type251")
        else:
            type251_controller = self.add_unit("sam_mw_trough_type251")
            type_hel_field = self.add_unit("sam_mw_pt_heliostatfield")
            if self.as_integer("receiver_type") == 0:
                type222_receiver = self.add_unit("sam_mw_pt_type222")
            else:
                type232_cav_rec = self.add_unit("sam_lf_st_pt_type232")
        type224_powerblock: int = 0
        type424_sco2: int = 0
        if is_steam_pc:
            type224_powerblock = self.add_unit("sam_mw_pt_type224")
        else:
            type424_sco2 = self.add_unit("sam_sco2_recomp_type424")
        type228_parasitics: int = self.add_unit("sam_mw_pt_type228")
        self.set_unit_value_ssc_matrix(tou, "weekday_schedule")
        self.set_unit_value_ssc_matrix(tou, "weekend_schedule")
        self.set_unit_value_ssc_double(type_hel_field, "run_type")
        self.set_unit_value_ssc_double(type_hel_field, "helio_width")
        self.set_unit_value_ssc_double(type_hel_field, "helio_height")
        self.set_unit_value_ssc_double(type_hel_field, "helio_optical_error")
        self.set_unit_value_ssc_double(type_hel_field, "helio_active_fraction")
        self.set_unit_value_ssc_double(type_hel_field, "dens_mirror")
        self.set_unit_value_ssc_double(type_hel_field, "helio_reflectance")
        self.set_unit_value_ssc_double(type_hel_field, "rec_absorptance")
        is_optimize: bool = self.as_boolean("is_optimize")
        H_rec: float64 = 0.0
        D_rec: float64 = 0.0
        rec_aspect: float64 = 0.0
        THT: float64 = 0.0
        A_sf: float64 = 0.0
        if is_optimize:
            spi: solarpilot_invoke = solarpilot_invoke(self)
            spi.run()
            steps: List[List[float64]] = List[List[float64]]()
            obj: List[float64] = List[float64]()
            flux: List[float64] = List[float64]()
            spi.opt.getOptimizationSimulationHistory(steps, obj, flux)
            nr: int = len(steps)
            nc: int = len(steps[0]) + 2
            ssc_hist: Pointer[ssc_number_t] = self.allocate("opt_history", nr, nc)
            for i in range(nr):
                for j in range(len(steps[0])):
                    ssc_hist[i * nc + j] = steps[i][j]
                ssc_hist[i * nc + nc - 2] = obj[i]
                ssc_hist[i * nc + nc - 1] = flux[i]
            H_rec = spi.recs[0].height
            rec_aspect = spi.recs[0].aspect
            THT = spi.layout.h_tower
            nr = len(spi.layout.heliostat_positions)
            ssc_hl: Pointer[ssc_number_t] = self.allocate("helio_positions", nr, 2)
            for i in range(nr):
                ssc_hl[i * 2] = ssc_number_t(spi.layout.heliostat_positions[i].location.x)
                ssc_hl[i * 2 + 1] = ssc_number_t(spi.layout.heliostat_positions[i].location.y)
            A_sf = self.as_double("helio_height") * self.as_double("helio_width") * self.as_double("dens_m