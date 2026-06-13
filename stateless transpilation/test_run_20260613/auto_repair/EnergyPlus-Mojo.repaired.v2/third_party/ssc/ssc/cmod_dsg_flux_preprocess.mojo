from core import *
from water_properties import *

var _cm_vtab_dsg_flux_preprocess: StaticArray[var_info, 24] = StaticArray[var_info, 24](
    var_info(SSC_INPUT,  SSC_NUMBER,  "P_HP_in",         "HP Turbine inlet pressure",            "bar",    "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "P_HP_out",        "HP Turbine outlet pressure",           "bar",    "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_sh_out_ref",    "Superheater outlet temperature",       "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_rh_out_ref",    "Reheater outlet temperature",          "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "P_cycle_des",     "Cycle power output at design",         "MW",     "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "eta_cycle_des",   "Cycle thermal efficiency at des.",     "",       "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "rh_frac_ref",     "Mdot fraction to reheat at design",    "",       "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "CT",              "Cooling type",                         "",       "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "dT_cooling_ref",  "dT of cooling water",                  "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_approach",      "dT cold cooling water - T_wb",         "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_amb_des",       "Ambient (wb) temp at design",          "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "T_ITD_des",       "T_cond - T_db",                        "C",      "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "Q_rec_des",       "Receiver thermal power at des.",        "MW",     "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "max_flux_b",      "Max allow. boiler flux",               "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "max_flux_sh",     "Max allow. superheater flux",          "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "max_flux_rh",     "Max allow. reheater flux",             "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "b_q_loss_flux",   "Boiler heat loss flux",                "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "sh_q_loss_flux",  "Superheater heat loss flux",	          "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "rh_q_loss_flux",  "Reheater heat loss flux",              "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "max_flux",        "Maximum flux allow. on receiver",      "kW/m2",  "",     "",    "*",        "",          ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "f_b",             "Fraction of total height to boiler",   "",	    "",     "",    "*",        "",          ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "f_sh",            "Fraction of total height to SH",       "",	    "",     "",    "*",        "",          ""),
    var_info(SSC_OUTPUT, SSC_NUMBER,  "f_rh",            "Fraction of total height to RH",       "",       "",     "",    "*",        "",          ""),
    var_info_invalid
)

@value
struct cm_dsg_flux_preprocess(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_dsg_flux_preprocess)

    def exec(inout self):
        var wp: water_state
        var P_HP_in = self.as_double("P_HP_in")*1.E2
        var P_HP_out = self.as_double("P_HP_out")*1.E2
        var T_sh_out_ref = self.as_double("T_sh_out_ref")+273.15
        var T_rh_out_ref = self.as_double("T_rh_out_ref")+273.15
        var P_cycle_des = self.as_double("P_cycle_des")
        var eta_cycle_des = self.as_double("eta_cycle_des")
        var rh_frac_ref = self.as_double("rh_frac_ref")
        var ct = Int(self.as_double("CT"))
        var dT_cooling_ref = self.as_double("dT_cooling_ref")
        var T_approach = self.as_double("T_approach")
        var T_amb_des = self.as_double("T_amb_des")+273.15
        var T_ITD_des = self.as_double("T_ITD_des")
        var Q_rec_des = self.as_double("Q_rec_des")
        var max_flux_b = self.as_double("max_flux_b")
        var max_flux_sh = self.as_double("max_flux_sh")
        var max_flux_rh = self.as_double("max_flux_rh")
        var b_q_loss_flux = self.as_double("b_q_loss_flux")
        var sh_q_loss_flux = self.as_double("sh_q_loss_flux")
        var rh_q_loss_flux = self.as_double("rh_q_loss_flux")
        water_TP(T_sh_out_ref, P_HP_in, &wp)
        var h_HP_in_des = wp.enth
        var s_HP_in_des = wp.entr
        water_PS(P_HP_out, s_HP_in_des, &wp)
        var h_HP_out_isen = wp.enth
        var h_HP_out_des = h_HP_in_des - (h_HP_in_des - h_HP_out_isen)*0.88
        water_PH(P_HP_out, h_HP_out_des, &wp)
        water_TP(T_rh_out_ref, P_HP_out, &wp)
        var h_rh_out_des = wp.enth
        var s_rh_out_des = wp.entr
        if ct == 1:
            water_TQ(dT_cooling_ref + 3.0 + T_approach + T_amb_des, 0.0, &wp)
        else:
            water_TQ(T_ITD_des + T_amb_des, 0.0, &wp)
        var Psat_des = wp.pres
        water_PS(Psat_des, s_rh_out_des, &wp)
        var h_LP_out_isen = wp.enth
        var h_LP_out_des = h_rh_out_des - (h_rh_out_des - h_LP_out_isen)*0.88
        water_PQ(P_HP_in, 1.0, &wp)
        var h_sh_in_des = wp.enth
        var m_dot_des = (P_cycle_des*1.E3)/( (h_HP_in_des-h_HP_out_des) + rh_frac_ref*(h_rh_out_des - h_LP_out_des))
        var q_sh_des = (h_HP_in_des - h_sh_in_des)*m_dot_des
        var q_rh_des = (h_rh_out_des - h_HP_out_des)*m_dot_des*rh_frac_ref
        var Q_pb_des = (P_cycle_des*1.E3) / eta_cycle_des
        var q_b_des = Q_pb_des - q_sh_des - q_rh_des
        var h_fw_out_des = h_sh_in_des - q_b_des / m_dot_des
        var q_sh_des_sp = (h_HP_in_des - h_sh_in_des)
        var q_rh_des_sp = (h_rh_out_des - h_HP_out_des)
        var q_b_des_sp = (h_sh_in_des - h_fw_out_des)
        var m_dot_ref = (Q_rec_des*1.E3)/(q_b_des_sp + q_sh_des_sp + q_rh_des_sp*rh_frac_ref)
        var Q_b_ref = q_b_des_sp * m_dot_ref
        var Q_sh_ref = q_sh_des_sp * m_dot_ref
        var Q_rh_ref = q_rh_des_sp * rh_frac_ref * m_dot_ref
        var A_b_min = Q_b_ref / (max_flux_b - b_q_loss_flux)
        var A_sh_min = Q_sh_ref / (max_flux_sh - sh_q_loss_flux)
        var A_rh_min = Q_rh_ref / (max_flux_rh - rh_q_loss_flux)
        var A_min = A_b_min + A_sh_min + A_rh_min
        var f_b = A_b_min / A_min
        var f_sh = A_sh_min / A_min
        var f_rh = A_rh_min / A_min
        var Q_rec_inc = (Q_b_ref + A_b_min*b_q_loss_flux) + (Q_sh_ref + A_sh_min*sh_q_loss_flux) + (Q_rh_ref + A_rh_min*rh_q_loss_flux)
        var max_flux = Q_rec_inc / A_min
        self.assign("max_flux", ssc_number_t(max_flux))
        self.assign("f_b", ssc_number_t(f_b))
        self.assign("f_sh", ssc_number_t(f_sh))
        self.assign("f_rh", ssc_number_t(f_rh))

def __module_entry__():
    return DEFINE_MODULE_ENTRY(dsg_flux_preprocess, "Calculate receiver max flux and absorber (boiler, etc.) fractions", 0)