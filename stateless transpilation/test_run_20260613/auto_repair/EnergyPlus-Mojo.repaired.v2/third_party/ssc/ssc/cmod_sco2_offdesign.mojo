from core import *
from sco2_power_cycle import *
from vector import *

var _cm_vtab_sco2_offdesign: StaticArray[var_info, 28] = [
/*  VARTYPE   DATATYPE         NAME                  LABEL                                                UNITS     META        GROUP                      REQUIRED_IF          CONSTRAINTS   UI_HINTS*/
var_info(SSC_INPUT,  SSC_NUMBER,     "I_W_dot_net_des",     "Design cycle power output",                         "MWe",    "",         "sCO2 power cycle",         "*",                "",           "" ),		
var_info(SSC_INPUT,  SSC_NUMBER,     "I_T_mc_in_des",       "Main compressor inlet temp at design",              "C",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_T_t_in_des",        "Turbine inlet temp at design",                      "C",      "",         "sCO2 power cycle",         "*",                "",           "" ),								
var_info(SSC_INPUT,  SSC_NUMBER,     "I_N_t_des",           "Design turbine speed, negative links to comp.",     "rpm",    "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_eta_c",             "Design compressor(s) isentropic efficiency",        "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_eta_t",             "Design turbine isentropic efficiency",              "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_tol",               "Convergence tolerance for performance calcs",       "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_opt_tol",           "Convergence tolerance - optimization calcs",        "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_UA_total_des",      "Total UA allocatable to recuperators",              "kW/K",   "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_INPUT,  SSC_NUMBER,     "I_P_high_des",        "Design compressor outlet pressure",                 "MPa",    "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_PR_mc_des",         "Design Pressure Ratio across main comp.",           "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_LT_frac_des",       "Design UA distribution",                            "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_recomp_frac_des",   "Design recompression fraction",                     "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_T_mc_in",           "Compressor inlet temperature",                      "C",      "",         "sCO2 power cycle",         "*",                "",           "" ),    
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_T_t_in",            "Turbine inlet temperature",                         "C",		"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_W_dot_net_target",  "Target net output target",                          "MWe",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "I_optimize_N_t",      "Bool: '1 = true' or '0 = false' ",                  "-",		"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_eta_thermal_des",   "Design cycle thermal efficiency",                   "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_eta_thermal",       "Off-design thermal efficiency",                     "-",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_W_dot_net",         "Actual off-design net power output",                "MWe",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_P_mc_out",          "Main compressor outlet pressure",                   "MPa",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_P_mc_in",           "Main compressor inlet pressure",                    "MPa",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_recomp_frac",       "Recompression fraction",                            "-",		"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_N_mc",              "Main compressor shaft speed",                       "rpm",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_N_t",               "Turbine shaft speed",                               "rpm",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_N_rc",              "Recompressor shaft speed",                          "rpm",	"",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_NUMBER,     "O_m_dot_PHX",         "Mass flow rate through primary HX",                 "kg/s",   "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info(SSC_OUTPUT, SSC_ARRAY,      "O_T_array",			 "Cycle temp state points at design",                 "K",      "",         "sCO2 power cycle",         "*",                "",           "" ),
var_info_invalid
]

class cm_sco2_offdesign(compute_module):
    def __init__(self):
        super().__init__()
        self.add_var_info(_cm_vtab_sco2_offdesign)

    def exec(self) -> None:
        rc_des_par = cycle_design_parameters()
        rc_des_par.m_mc_type = 1
        rc_des_par.m_rc_type = 1
        rc_des_par.m_W_dot_net = self.as_double("I_W_dot_net_des") * 1000.0		# [kW] Design cycle power outpt
        rc_des_par.m_T_mc_in = self.as_double("I_T_mc_in_des") + 273.15			# [K] Compressor inlet temp at design, convert from C
        rc_des_par.m_T_t_in = self.as_double("I_T_t_in_des") + 273.15			# [K] Turbine inlet temp at design, convert from C
        rc_des_par.m_DP_LT[0] = 0.0
        rc_des_par.m_DP_LT[1] = 0.0
        rc_des_par.m_DP_HT[0] = 0.0
        rc_des_par.m_DP_HT[1] = 0.0
        rc_des_par.m_DP_PC[0] = 0.0
        rc_des_par.m_DP_PC[1] = 0.0
        rc_des_par.m_DP_PHX[0] = 0.0
        rc_des_par.m_DP_PHX[1] = 0.0
        rc_des_par.m_N_t = self.as_double("I_N_t_des")			# [rpm] Turbine speed, Negative number links to compressor speed
        eta_comps = self.as_double("I_eta_c")
        rc_des_par.m_eta_mc = eta_comps
        rc_des_par.m_eta_rc = eta_comps
        rc_des_par.m_eta_t = self.as_double("I_eta_t")
        rc_des_par.m_N_sub_hxrs = 20
        rc_des_par.m_tol = 1.E-6						# [-]
        rc_des_par.m_opt_tol = 1.E-6					# [-]
        rc_des_par.m_tol = self.as_double("I_tol")			# [-] Convergence tolerance for performance calcs
        rc_des_par.m_opt_tol = self.as_double("I_opt_tol")	# [-] Convergence tolerance for optimization calcs
        rc_des_par.m_fixed_LT_frac = True
        rc_des_par.m_UA_rec_total = self.as_double("I_UA_total_des")		# [kW/K] Total UA allocatable to recuperators
        rc_des_par.m_LT_frac = self.as_double("I_LT_frac_des")
        rc_des_par.m_fixed_P_mc_out = True
        rc_des_par.m_P_mc_out = self.as_double("I_P_high_des") * 1000.0
        rc_des_par.m_fixed_PR_mc = True
        rc_des_par.m_PR_mc = self.as_double("I_PR_mc_des")
        rc_des_par.m_P_high_limit = self.as_double("I_P_high_des") * 1000.0
        rc_des_par.m_fixed_recomp_frac = True
        rc_des_par.m_recomp_frac = self.as_double("I_recomp_frac_des")
        rc_cycle = RecompCycle(rc_des_par)
        design_cycle_success = rc_cycle.design_no_opt()
        self.assign("O_eta_thermal_des", var_data(ssc_number_t(rc_cycle.get_cycle_design_metrics().m_eta_thermal)))
        rc_opt_off_des_in = cycle_opt_off_des_inputs()
        rc_opt_off_des_in.m_T_mc_in = self.as_double("I_T_mc_in") + 273.15
        rc_opt_off_des_in.m_T_t_in = self.as_double("I_T_t_in") + 273.15
        rc_opt_off_des_in.m_W_dot_net_target = self.as_double("I_W_dot_net_target") * 1000.0
        rc_opt_off_des_in.m_N_sub_hxrs = rc_cycle.get_cycle_design_parameters().m_N_sub_hxrs
        if rc_cycle.get_cycle_design_parameters().m_recomp_frac == 0.0:
            rc_opt_off_des_in.m_fixed_recomp_frac = True		# If no recompressor then no need to vary recompression fraction
            rc_opt_off_des_in.m_recomp_frac = rc_cycle.get_cycle_design_parameters().m_recomp_frac
        else:
            rc_opt_off_des_in.m_fixed_recomp_frac = False
            rc_opt_off_des_in.m_recomp_frac_guess = rc_cycle.get_cycle_design_parameters().m_recomp_frac
        rc_opt_off_des_in.m_fixed_N_mc = False
        rc_opt_off_des_in.m_N_mc_guess = rc_cycle.get_cycle_design_metrics().m_N_mc
        rc_opt_off_des_in.m_fixed_N_t = not (bool)(self.as_double("I_optimize_N_t"))
        if rc_opt_off_des_in.m_fixed_N_t:
            rc_opt_off_des_in.m_N_t = rc_cycle.get_cycle_design_parameters().m_N_t
        else:
            rc_opt_off_des_in.m_N_t_guess = rc_cycle.get_cycle_design_parameters().m_N_t
        rc_opt_off_des_in.m_tol = rc_cycle.get_cycle_design_parameters().m_tol
        rc_opt_off_des_in.m_opt_tol = rc_cycle.get_cycle_design_parameters().m_opt_tol
        od_opt_cycle_success = rc_cycle.optimal_off_design(rc_opt_off_des_in)
        P_vector = rc_cycle.get_off_design_outputs().m_P
        self.assign("O_eta_thermal", var_data(ssc_number_t(rc_cycle.get_off_design_outputs().m_eta_thermal)))
        self.assign("O_W_dot_net", var_data(ssc_number_t(rc_cycle.get_off_design_outputs().m_W_dot_net / 1000.0)))
        self.assign("O_P_mc_out", var_data(ssc_number_t(P_vector[2 - 1] / 1000.0)))
        self.assign("O_P_mc_in", var_data(ssc_number_t(rc_cycle.get_off_design_inputs().m_P_mc_in / 1000.0)))
        self.assign("O_recomp_frac", var_data(ssc_number_t(rc_cycle.get_off_design_inputs().m_S.m_recomp_frac)))
        self.assign("O_N_mc", var_data(ssc_number_t(rc_cycle.get_off_design_inputs().m_S.m_N_mc)))
        self.assign("O_N_t", var_data(ssc_number_t(rc_cycle.get_off_design_inputs().m_S.m_N_t)))
        self.assign("O_N_rc", var_data(ssc_number_t(rc_cycle.get_off_design_outputs().m_N_rc)))
        self.assign("O_m_dot_PHX", var_data(ssc_number_t(rc_cycle.get_off_design_outputs().m_m_dot_PHX)))
        T_vector = rc_cycle.get_off_design_outputs().m_T
        l_T_array = len(T_vector)
        T_array = Pointer[ssc_number_t].alloc(l_T_array)
        for i in range(l_T_array):
            T_array[i] = ssc_number_t(T_vector[i])
        self.assign("O_T_array", var_data(T_array, l_T_array))
        del T_array

DEFINE_MODULE_ENTRY(sco2_offdesign, "Calls sCO2 off design performance model given cycle design parameters", 1)