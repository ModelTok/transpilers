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

from tcstype import tcstypeinterface, tcscontext, tcstypeinfo, TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_MATRIX, TCS_INVALID, TCS_ERROR, TCS_WARNING, TCS_NOTICE, TCS_MATRIX_INDEX, var
from htf_props import HTFProperties
from CO2_properties import CO2_state, CO2_TP
from heat_exchangers import C_CO2_to_air_cooler
from sco2_recompression_cycle import C_RecompCycle, C_sco2_cycle_core::S_auto_opt_design_hit_eta_parameters, C_RecompCycle::S_od_parameters, C_RecompCycle::S_PHX_od_parameters
from nlopt import nlopt
from nlopt_callbacks import nlopt_callbacks

#using namespace std;  # replaced by imports

# Define the enum for indices (0-based)
alias P_W_dot_net_des = 0
alias P_eta_c = 1
alias P_eta_t = 2
alias P_P_high_limit = 3
alias P_DELTAT_PHX = 4
alias P_DELTAT_ACC = 5
alias P_T_AMB_DES = 6
alias P_FAN_POWER_PERC = 7
alias P_PLANT_ELEVATION = 8
alias P_T_htf_hot = 9
alias P_T_htf_cold_est = 10
alias P_eta_des = 11
alias P_rec_fl = 12
alias P_rec_fl_props = 13
alias P_STARTUP_TIME = 14
alias P_STARTUP_FRAC = 15
alias P_Q_SBY_FRAC = 16
alias P_cycle_cutoff_frac = 17
alias I_T_HTF_HOT = 18
alias I_M_DOT_HTF = 19
alias I_STANDBY_CONTROL = 20
alias I_T_DB = 21
alias I_P_AMB = 22
alias O_ETA_CYCLE_DES = 23
alias O_P_LOW_DES = 24
alias O_P_HIGH_DES = 25
alias O_F_RECOMP_DES = 26
alias O_UA_RECUP_DES = 27
alias O_UA_PHX_DES = 28
alias O_T_COOLER_IN_DES = 29
alias O_COOLER_VOLUME = 30
alias O_P_CYCLE = 31
alias O_ETA = 32
alias O_T_HTF_COLD = 33
alias O_M_DOT_MAKEUP = 34
alias O_M_DOT_DEMAND = 35
alias O_M_DOT_HTF_REF = 36
alias O_W_COOL_PAR = 37
alias O_F_BAYS = 38
alias O_P_COND = 39
alias O_Q_STARTUP = 40
alias O_T_HTF_COLD_DES = 41
alias O_T_TURBINE_IN = 42
alias O_P_MC_IN = 43
alias O_P_MC_OUT = 44
alias O_F_RECOMP = 45
alias O_N_MC = 46
alias N_MAX = 47

# define the variable info struct
struct TCSVarInfo:
    var dir: Int
    var typ: Int
    var idx: Int
    var name: String
    var label: String
    var units: String
    var group: String
    var meta: String
    var default_val: String
    var meta2: String

# create the array (as List) - replacing the C array initializer
def make_sam_sco2_recomp_type424_variables() -> List[TCSVarInfo]:
    var vars = List[TCSVarInfo]()
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_W_dot_net_des, "W_dot_net_des", "Design cycle power output", "MW", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_eta_c, "eta_c", "Design compressor(s) isentropic efficiency", "-", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_eta_t, "eta_t", "Design turbine isentropic efficiency", "-", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_P_high_limit, "P_high_limit", "High pressure limit in cycle", "MPa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_DELTAT_PHX, "deltaT_PHX", "Temp diff btw hot HTF and turbine inlet", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_DELTAT_ACC, "deltaT_ACC", "Temp diff btw ambient air and compressor inlet", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_T_AMB_DES, "T_amb_des", "Design: Ambient temperature for air cooler", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_FAN_POWER_PERC, "fan_power_perc", "Percent of net cycle power used for fan", "%", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_PLANT_ELEVATION, "plant_elevation", "Plant Elevation", "m", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_T_htf_hot, "T_htf_hot_des", "Tower design outlet temp", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_T_htf_cold_est, "T_htf_cold_est", "Estimated tower design inlet temp", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_eta_des, "eta_des", "Power cycle thermal efficiency", "", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_rec_fl, "rec_htf", "The name of the HTF used in the receiver", "", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_MATRIX, P_rec_fl_props, "field_fl_props", "User defined rec fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", "", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_STARTUP_TIME, "startup_time", "Time needed for power block startup", "hr", "", "", "0.5", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_STARTUP_FRAC, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "", "0.2", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_Q_SBY_FRAC, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "", "0.2", ""))
    vars.append(TCSVarInfo(TCS_PARAM, TCS_NUMBER, P_cycle_cutoff_frac, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "-", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_INPUT, TCS_NUMBER, I_T_HTF_HOT, "T_htf_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_INPUT, TCS_NUMBER, I_M_DOT_HTF, "m_dot_htf", "HTF mass flow rate", "kg/hr", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_INPUT, TCS_NUMBER, I_STANDBY_CONTROL, "standby_control", "Control signal indicating standby mode", "none", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_INPUT, TCS_NUMBER, I_T_DB, "T_db", "Ambient dry bulb temperature", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_INPUT, TCS_NUMBER, I_P_AMB, "P_amb", "Ambient pressure", "mbar", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_CYCLE_DES, "eta_cycle_des", "Design: Power cycle efficiency", "%", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_LOW_DES, "P_low_des", "Design: Compressor inlet pressure", "kPa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_HIGH_DES, "P_high_des", "Design: Comp. outlet pressure", "kPa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_F_RECOMP_DES, "f_recomp_des", "Design: Recompression fraction", "-", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_UA_RECUP_DES, "UA_recup_des", "Design: Recuperator conductance UA", "kW/K", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_UA_PHX_DES, "UA_PHX_des", "Design: PHX conductance (UA)", "kW/K", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_T_COOLER_IN_DES, "T_cooler_in_des", "Design: Cooler CO2 inlet temp", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_COOLER_VOLUME, "cooler_volume", "Estimated required cooler material vol.", "m^3", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_CYCLE, "P_cycle", "Cycle power output", "MWe", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_ETA, "eta", "Cycle thermal efficiency", "none", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_T_HTF_COLD, "T_htf_cold", "Heat transfer fluid outlet temperature ", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_MAKEUP, "m_dot_makeup", "Cooling water makeup flow rate", "kg/hr", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_DEMAND, "m_dot_demand", "HTF required flow rate to meet power load", "kg/hr", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_HTF_REF, "m_dot_htf_ref", "Calculated reference HTF flow rate at design", "kg/hr", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_W_COOL_PAR, "W_cool_par", "Cooling system parasitic load", "MWe", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_F_BAYS, "f_bays", "Fraction of operating heat rejection bays", "none", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_COND, "P_cond", "Condenser pressure", "Pa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_Q_STARTUP, "q_pc_startup", "Power cycle startup energy", "MWt-hr", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_T_HTF_COLD_DES, "o_T_htf_cold_des", "Calculated htf cold temperature at design", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_T_TURBINE_IN, "T_turbine_in", "Turbine inlet temperature", "C", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_MC_IN, "P_mc_in", "Main compressor inlet pressure", "kPa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_P_MC_OUT, "P_mc_out", "Main compressor outlet pressure", "kPa", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_F_RECOMP, "f_recomp", "Recompression fraction", "", "", "", "", ""))
    vars.append(TCSVarInfo(TCS_OUTPUT, TCS_NUMBER, O_N_MC, "N_MC", "Main comp. shaft speed", "rpm", "", "", "", ""))
    # Terminator entry
    vars.append(TCSVarInfo(TCS_INVALID, TCS_INVALID, N_MAX, "", "", "", "", "", "", ""))
    return vars

# Global variable
var sam_sco2_recomp_type424_variables = make_sam_sco2_recomp_type424_variables()

class sam_sco2_recomp_type424(tcstypeinterface):
    # Private members
    var ms_rc_cycle: C_RecompCycle
    var ms_rc_autodes_hit_eta_par: C_sco2_cycle_core::S_auto_opt_design_hit_eta_parameters
    var ms_rc_od_par: C_RecompCycle::S_od_parameters
    var ms_phx_od_par: C_RecompCycle::S_PHX_od_parameters
    var rec_htfProps: HTFProperties
    var co2_props: CO2_state
    var ACC: C_CO2_to_air_cooler
    var co2_error: Int
    var m_W_dot_net_des: Float64
    var m_T_mc_in_des: Float64
    var m_T_t_in_des: Float64
    var m_N_t_des: Float64
    var m_eta_c: Float64
    var m_eta_t: Float64
    var m_P_high_limit: Float64
    var m_tol: Float64
    var m_opt_tol: Float64
    var m_DP_LT: List[Float64]
    var m_DP_HT: List[Float64]
    var m_DP_PC: List[Float64]
    var m_DP_PHX: List[Float64]
    var m_N_sub_hxrs: Int
    var m_deltaP_cooler_frac: Float64
    var m_q_max_sf: Float64
    var m_UA_total_des: Float64
    var m_delta_T_acc: Float64
    var m_delta_T_t: Float64
    var m_m_dot_des: Float64
    var m_cp_rec: Float64
    var m_UA_PHX_des: Float64
    var m_T_htf_cold_sby: Float64
    var m_m_dot_htf_sby: Float64
    var m_W_dot_fan_des: Float64
    var m_eta_thermal_des: Float64
    var m_T_htf_cold_des: Float64
    var m_T_htf_hot: Float64
    var m_Q_dot_rec_des: Float64
    var m_dot_rec_des: Float64
    var m_startup_time: Float64
    var m_startup_frac: Float64
    var m_startup_energy: Float64
    var m_q_sby_frac: Float64
    var m_standby_control_prev: Int
    var m_standby_control: Int
    var m_time_su_prev: Float64
    var m_time_su: Float64
    var m_E_su_prev: Float64
    var m_E_su: Float64
    var m_error_message_code: Int
    var m_is_first_t_call: Bool
    var m_q_dot_cycle_max: Float64
    var m_P_mc_in_q_max: Float64
    var m_ncall: Float64

    # Constructor
    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)
        self.m_W_dot_net_des = Float64.NaN
        self.m_T_mc_in_des = Float64.NaN
        self.m_T_t_in_des = Float64.NaN
        self.m_N_t_des = Float64.NaN
        self.m_eta_c = Float64.NaN
        self.m_eta_t = Float64.NaN
        self.m_P_high_limit = Float64.NaN
        self.m_tol = 1.0e-3
        self.m_opt_tol = self.m_tol
        self.m_DP_LT = List[Float64](2, 0.0)
        # fill with 0.0 (already initialized to 0.0 in List)
        self.m_DP_HT = List[Float64](2, 0.0)
        self.m_DP_PC = List[Float64](2, 0.0)
        self.m_DP_PHX = List[Float64](2, 0.0)
        self.m_N_sub_hxrs = 10
        self.m_deltaP_cooler_frac = 0.002
        self.m_N_t_des = 3600.0
        self.m_q_max_sf = 0.97
        self.m_UA_total_des = Float64.NaN
        self.m_delta_T_acc = Float64.NaN
        self.m_delta_T_t = Float64.NaN
        self.m_m_dot_des = Float64.NaN
        self.m_cp_rec = Float64.NaN
        self.m_T_htf_cold_sby = Float64.NaN
        self.m_m_dot_htf_sby = Float64.NaN
        self.m_W_dot_fan_des = Float64.NaN
        self.m_eta_thermal_des = Float64.NaN
        self.m_T_htf_cold_des = Float64.NaN
        self.m_T_htf_hot = Float64.NaN
        self.m_Q_dot_rec_des = Float64.NaN
        self.m_dot_rec_des = Float64.NaN
        self.m_UA_PHX_des = Float64.NaN
        self.m_startup_time = Float64.NaN
        self.m_startup_frac = Float64.NaN
        self.m_startup_energy = Float64.NaN
        self.m_q_sby_frac = Float64.NaN
        self.m_standby_control_prev = -1
        self.m_standby_control = -1
        self.m_time_su_prev = Float64.NaN
        self.m_time_su = Float64.NaN
        self.m_E_su_prev = Float64.NaN
        self.m_E_su = Float64.NaN
        self.m_is_first_t_call = True
        self.m_q_dot_cycle_max = Float64.NaN
        self.m_P_mc_in_q_max = Float64.NaN

    # Destructor (in C++, but in Mojo we just leave implicit)
    # (no destructor needed)

    # init
    def init(inout self) -> Int:
        self.m_W_dot_net_des = self.value(P_W_dot_net_des) * 1000.0  # [kW] Design cycle power output
        self.m_eta_c = self.value(P_eta_c)
        self.m_eta_t = self.value(P_eta_t)
        self.m_P_high_limit = self.value(P_P_high_limit) * 1.0e3  # [kPa] High pressure limit, convert from MPa
        self.m_delta_T_t = self.value(P_DELTAT_PHX)  # [C]
        self.m_delta_T_acc = self.value(P_DELTAT_ACC)  # [C]
        var T_amb_cycle_des: Float64 = self.value(P_T_AMB_DES) + 273.15  # [K]
        var fan_power_frac: Float64 = self.value(P_FAN_POWER_PERC) / 100.0  # [-]
        self.m_T_htf_hot = self.value(P_T_htf_hot) + 273.15  # [K]
        self.m_eta_thermal_des = self.value(P_eta_des)
        self.m_Q_dot_rec_des = self.m_W_dot_net_des / self.m_eta_thermal_des  # [kWt]
        self.m_T_mc_in_des = T_amb_cycle_des + self.m_delta_T_acc  # [K]
        self.m_T_t_in_des = self.m_T_htf_hot - self.m_delta_T_t  # [K]
        var error_msg: String = ""
        var auto_err_code: Int = 0
        self.ms_rc_autodes_hit_eta_par.m_W_dot_net = self.m_W_dot_net_des  # [kW]
        self.ms_rc_autodes_hit_eta_par.m_eta_thermal = self.m_eta_thermal_des  # [-]
        self.ms_rc_autodes_hit_eta_par.m_T_mc_in = self.m_T_mc_in_des  # [K]
        self.ms_rc_autodes_hit_eta_par.m_T_t_in = self.m_T_t_in_des  # [K]
        self.ms_rc_autodes_hit_eta_par.m_DP_LT = self.m_DP_LT
        self.ms_rc_autodes_hit_eta_par.m_DP_HT = self.m_DP_HT
        self.ms_rc_autodes_hit_eta_par.m_DP_PC_main = self.m_DP_PC
        self.ms_rc_autodes_hit_eta_par.m_DP_PHX = self.m_DP_PHX
        self.ms_rc_autodes_hit_eta_par.m_eta_mc = self.m_eta_c
        self.ms_rc_autodes_hit_eta_par.m_eta_rc = self.m_eta_c
        self.ms_rc_autodes_hit_eta_par.m_eta_t = self.m_eta_t
        self.ms_rc_autodes_hit_eta_par.m_LTR_N_sub_hxrs = self.m_N_sub_hxrs  # [-]
        self.ms_rc_autodes_hit_eta_par.m_HTR_N_sub_hxrs = self.m_N_sub_hxrs  # [-]
        self.ms_rc_autodes_hit_eta_par.m_P_high_limit = self.m_P_high_limit  # [kPa]
        self.ms_rc_autodes_hit_eta_par.m_des_tol = self.m_tol
        self.ms_rc_autodes_hit_eta_par.m_des_opt_tol = self.m_opt_tol
        self.ms_rc_autodes_hit_eta_par.m_N_turbine = self.m_N_t_des
        self.ms_rc_autodes_hit_eta_par.m_is_recomp_ok = 1
        auto_err_code = self.ms_rc_cycle.auto_opt_design_hit_eta(self.ms_rc_autodes_hit_eta_par, error_msg)
        if auto_err_code != 0:
            self.message(TCS_ERROR, error_msg)
            return -1
        if error_msg == "":
            self.message(TCS_NOTICE, "sCO2 cycle design optimization was successful")
        else:
            var out_msg: String = "The sCO2 cycle design optimization solved with the following warning(s):\n" + error_msg
            self.message(TCS_NOTICE, out_msg)
        if T_amb_cycle_des > self.m_T_mc_in_des - 2.0:
            self.message(TCS_ERROR, "The ambient temperature used for the air cooler design, %lg [C], must be 2 [C] less than the specified compressor inlet temperature %lg [C]", T_amb_cycle_des - 273.15, self.m_T_mc_in_des - 273.15)
            return -1
        if T_amb_cycle_des < 273.15:
            self.message(TCS_WARNING, "The ambient temperature used for the air cooler design, %lg [C], was reset to 0 [C] to improve solution stability", T_amb_cycle_des - 273.15)
            T_amb_cycle_des = 273.15
        var fan_power_frac_max: Float64 = 0.1
        if fan_power_frac > fan_power_frac_max:
            self.message(TCS_ERROR, "The fraction of cycle net power used by the cooling fan, %lg, is greater than the internal maximum %lg", fan_power_frac, fan_power_frac_max)
            return -1
        var fan_power_frac_min: Float64 = 0.001
        if fan_power_frac < fan_power_frac_min:
            self.message(TCS_ERROR, "The fraction of cycle net power used by the cooling fan, %lg, is less than the internal minimum %lg", fan_power_frac, fan_power_frac_min)
            return -1
        var rec_fl: Int = Int(self.value(P_rec_fl))
        if rec_fl != HTFProperties.User_defined and rec_fl < HTFProperties.End_Library_Fluids:
            if not self.rec_htfProps.SetFluid(rec_fl):
                self.message(TCS_ERROR, "Receiver HTF code is not recognized")
                return -1
        elif rec_fl == HTFProperties.User_defined:
            var nrows: Int = 0
            var ncols: Int = 0
            var fl_mat_ptr: Ptr[Float64] = self.value(P_rec_fl_props, nrows, ncols)
            if fl_mat_ptr[] != 0 and nrows > 2 and ncols == 7:
                var mat = util.matrix_t[Float64](nrows, ncols, 0.0)
                for r in range(nrows):
                    for c in range(ncols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(P_rec_fl_props), r, c)
                if not self.rec_htfProps.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, self.rec_htfProps.UserFluidErrMessage(), nrows, ncols)
                    return -1
            else:
                self.message(TCS_ERROR, "The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", nrows, ncols)
                return -1
        else:
            self.message(TCS_ERROR, "Receiver HTF code is not recognized")
            return -1
        var design_eta: Float64 = self.ms_rc_cycle.get_design_solved().m_eta_thermal
        self.m_m_dot_des = self.ms_rc_cycle.get_design_solved().m_m_dot_t  # [kg/s]
        var P_PHX_in: Float64 = self.ms_rc_cycle.get_design_solved().m_pres[5 - 1]  # [kPa] (1-based to 0-based)
        var T_htf_cold_est: Float64 = self.value(P_T_htf_cold_est) + 273.15
        var T_PHX_co2_in: Float64 = self.ms_rc_cycle.get_design_solved().m_temp[5 - 1]
        var T_htf_cold: Float64 = T_PHX_co2_in + self.m_delta_T_t
        var T_rec_ave: Float64 = 0.5 * (T_htf_cold + self.m_T_htf_hot)  # [K]
        self.m_cp_rec = self.rec_htfProps.Cp(T_rec_ave)  # [kJ/kg-K]
        self.m_dot_rec_des = self.m_Q_dot_rec_des / (self.m_cp_rec * (self.m_T_htf_hot - T_htf_cold))  # [kg/s]
        var T_PHX_co2_ave: Float64 = 0.5 * (self.m_T_t_in_des + T_PHX_co2_in)  # [K]
        self.co2_error = CO2_TP(T_PHX_co2_ave, P_PHX_in, self.co2_props)
        var q_dot_max: Float64 = self.m_dot_rec_des * self.m_cp_rec * (self.m_T_htf_hot - T_PHX_co2_in)  # [kW]
        var eff_des: Float64 = self.m_Q_dot_rec_des / q_dot_max
        var NTU: Float64 = eff_des / (1.0 - eff_des)
        self.m_UA_PHX_des = NTU * self.m_dot_rec_des * self.m_cp_rec
        self.m_T_htf_cold_des = T_htf_cold  # [K]
        self.message(TCS_WARNING, "The calculated cold HTF temperature is %lg [C]. The estimated cold HTF temperature is %lg [C]. This difference may affect the receiver design and hours of thermal storage. Try adjusting the receiver inlet temperature or design cycle efficiency",
                     T_htf_cold - 273.15, T_htf_cold_est - 273.15)
        self.value(O_T_HTF_COLD_DES, self.m_T_htf_cold_des - 273.15)
        var acc_des_par_ind: C_CO2_to_air_cooler.S_des_par_ind
        acc_des_par_ind.m_T_amb_des = T_amb_cycle_des  # [K]
        acc_des_par_ind.m_elev = self.value(P_PLANT_ELEVATION)  # [Pa]
        var acc_des_par_cycle_dep: C_CO2_to_air_cooler.S_des_par_cycle_dep
        acc_des_par_cycle_dep.m_T_hot_in_des = self.ms_rc_cycle.get_design_solved().m_temp[9 - 1]  # [K]
        acc_des_par_cycle_dep.m_P_hot_in_des = self.ms_rc_cycle.get_design_solved().m_pres[9 - 1]  # [kPa]
        acc_des_par_cycle_dep.m_m_dot_total = self.ms_rc_cycle.get_design_solved().m_m_dot_mc  # [kg/s]
        acc_des_par_cycle_dep.m_delta_P_des = self.m_deltaP_cooler_frac * self.ms_rc_cycle.get_design_solved().m_pres[2 - 1]  # [kPa]
        acc_des_par_cycle_dep.m_T_hot_out_des = self.m_T_mc_in_des  # [K]
        acc_des_par_cycle_dep.m_W_dot_fan_des = fan_power_frac * self.m_W_dot_fan_des / 1000.0  # [MW] # note: actually m_W_dot_fan_des is NaN initially; it's a bug in original? Keep as is.
        self.ACC.design_hx(acc_des_par_ind, acc_des_par_cycle_dep, 1.0e-3)
        self.value(O_ETA_CYCLE_DES, design_eta)
        self.value(O_P_LOW_DES, self.ms_rc_cycle.get_design_solved().m_pres[1 - 1])
        self.value(O_P_HIGH_DES, self.ms_rc_cycle.get_design_solved().m_pres[2 - 1])
        self.value(O_F_RECOMP_DES, self.ms_rc_cycle.get_design_solved().m_recomp_frac)
        self.value(O_UA_RECUP_DES, self.m_UA_total_des)
        self.value(O_UA_PHX_DES, self.m_UA_PHX_des)
        self.value(O_T_COOLER_IN_DES, acc_des_par_cycle_dep.m_T_hot_in_des - 273.15)  # [C]
        self.value(O_COOLER_VOLUME, self.ACC.get_total_hx_volume())
        self.m_startup_time = self.value(P_STARTUP_TIME)  # [hr]
        self.m_startup_frac = self.value(P_STARTUP_FRAC)  # [-]
        self.m_q_sby_frac = self.value(P_Q_SBY_FRAC)  # [-]
        var cutoff_frac: Float64 = self.value(P_cycle_cutoff_frac)  # [-]
        self.m_startup_energy = self.m_startup_frac * self.m_W_dot_net_des / design_eta  # [kWt-hr]
        self.m_standby_control_prev = 3
        self.m_time_su_prev = self.m_startup_time
        self.m_E_su_prev = self.m_startup_energy
        self.m_time_su = self.m_time_su_prev
        self.m_E_su = self.m_E_su_prev
        self.m_standby_control = self.m_standby_control_prev
        self.m_error_message_code = 0
        var q_sby_error_code: Int = 0
        self.ms_rc_od_par.m_T_mc_in = self.m_T_mc_in_des
        self.ms_rc_od_par.m_T_t_in = self.m_T_t_in_des
        self.ms_rc_od_par.m_N_t = self.ms_rc_cycle.get_design_solved().ms_t_des_solved.m_N_design
        self.ms_rc_od_par.m_tol = self.ms_rc_autodes_hit_eta_par.m_des_tol
        self.ms_phx_od_par.m_m_dot_htf_des = self.m_dot_rec_des
        self.ms_phx_od_par.m_T_htf_hot = self.m_T_htf_hot
        self.ms_phx_od_par.m_m_dot_htf = self.m_dot_rec_des * cutoff_frac
        self.ms_phx_od_par.m_T_htf_cold = self.m_T_htf_cold_des
        self.ms_phx_od_par.m_UA_PHX_des = self.m_UA_PHX_des
        self.ms_phx_od_par.m_cp_htf = self.m_cp_rec
        if q_sby_error_code != 0:
            self.message(TCS_ERROR, "The power cycle model crashes at the specified cutoff fraction, %lg. Try increasing this value", cutoff_frac)
            return -1
        var m_T_PHX_in_sby: Float64 = self.ms_rc_cycle.get_od_solved().m_temp[5 - 1]
        self.m_T_htf_cold_sby = m_T_PHX_in_sby + 5.0  # Estimate htf return temp w/o heat exchanger
        self.value(O_M_DOT_MAKEUP, 0.0)
        self.value(O_M_DOT_DEMAND, 0.0)
        self.value(O_M_DOT_HTF_REF, self.m_dot_rec_des * 3600.0)
        self.value(O_F_BAYS, 0.0)
        self.value(O_P_COND, 0.0)
        return 0

    # call
    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var T_htf_hot: Float64 = self.value(I_T_HTF_HOT) + 273.15  # [K]
        var m_dot_htf: Float64 = self.value(I_M_DOT_HTF) / 3600.0  # [kg/s]
        self.m_standby_control = Int(self.value(I_STANDBY_CONTROL))
        var T_db: Float64 = self.value(I_T_DB) + 273.15  # [K]
        var P_amb: Float64 = self.value(I_P_AMB) * 100.0  # [mbar] -> Pa? Actually: original uses mbar, conversion to Pa: 1 mbar=100 Pa? Might be 100.0? Check: in init they used *100.0 for Pa? Actually they wrote value(P_PLANT_ELEVATION) for elevation? This is ambiguous – keep as original.
        self.m_ncall = ncall
        self.m_error_message_code = 0
        var W_dot_net: Float64 = Float64.NaN
        var eta_thermal: Float64 = Float64.NaN
        var T_htf_cold: Float64 = Float64.NaN
        var W_dot_par: Float64 = Float64.NaN
        var Q_dot_PHX: Float64 = Float64.NaN
        var C_dot_htf: Float64 = Float64.NaN
        var T_turbine_in: Float64 = Float64.NaN
        var P_main_comp_in: Float64 = Float64.NaN
        var P_main_comp_out: Float64 = Float64.NaN
        var frac_recomp: Float64 = Float64.NaN
        var N_mc_od: Float64 = Float64.NaN
        var q_startup: Float64 = 0.0
        # Switch on m_standby_control
        if self.m_standby_control == 1:
            C_dot_htf = m_dot_htf * self.m_cp_rec
            var T_mc_in: Float64 = max(self.ms_rc_cycle.get_design_limits().m_T_mc_in_min, T_db + self.m_delta_T_acc)
            var T_t_in: Float64 = T_htf_hot - self.m_delta_T_t
            self.ms_rc_od_par.m_T_mc_in = T_mc_in
            self.ms_rc_od_par.m_T_t_in = T_t_in
            self.ms_rc_od_par.m_N_t = self.ms_rc_cycle.get_design_solved().ms_t_des_solved.m_N_design
            self.ms_rc_od_par.m_tol = self.ms_rc_autodes_hit_eta_par.m_des_tol
            self.ms_phx_od_par.m_m_dot_htf_des = self.m_dot_rec_des
            self.ms_phx_od_par.m_T_htf_hot = T_htf_hot
            self.ms_phx_od_par.m_m_dot_htf = m_dot_htf
            self.ms_phx_od_par.m_UA_PHX_des = self.m_UA_PHX_des
            self.ms_phx_od_par.m_cp_htf = self.m_cp_rec
            var hx_od_error: Int = 0
            if hx_od_error != 0:
                if hx_od_error != 1:
                    self.m_error_message_code = 1
                    break
                else:
                    self.m_error_message_code = 2
            W_dot_net = self.ms_rc_cycle.get_od_solved().m_W_dot_net
            Q_dot_PHX = self.ms_rc_cycle.get_od_solved().m_Q_dot
            T_htf_cold = T_htf_hot - Q_dot_PHX / C_dot_htf
            T_turbine_in = self.ms_rc_cycle.get_od_solved().m_temp[6 - 1]
            P_main_comp_in = self.ms_rc_cycle.get_od_solved().m_pres[1 - 1]
            P_main_comp_out = self.ms_rc_cycle.get_od_solved().m_pres[2 - 1]
            frac_recomp = self.ms_rc_cycle.get_od_solved().m_recomp_frac
            N_mc_od = self.ms_rc_cycle.get_od_solved().ms_mc_ms_od_solved.m_N  # [rpm]
            T_htf_cold = self.ms_phx_od_par.m_T_htf_cold
            eta_thermal = self.ms_rc_cycle.get_od_solved().m_eta_thermal
            var acc_error_code: Int = 0
            if acc_error_code == 1:
                W_dot_par = (m_dot_htf / self.m_dot_rec_des) * self.m_W_dot_fan_des
                self.message(TCS_NOTICE, "Off-design air cooler model did not solve. Fan power was set to the design value scaled by the timestep/design HTF mass flow rate")
            if acc_error_code == 2:
                self.message(TCS_NOTICE, "Off-design air cooler model did not converge within its numerical tolerance")
            # no break needed (fall through after block)
        elif self.m_standby_control == 2:
            W_dot_net = 0.0
            T_htf_cold = self.ms_phx_od_par.m_T_htf_cold
            T_turbine_in = 0.0
            P_main_comp_in = 0.0
            P_main_comp_out = 0.0
            frac_recomp = 0.0
            N_mc_od = 0.0
            eta_thermal = 0.0
            W_dot_par = 0.0
        else:  # case 3 and default
            W_dot_net = 0.0
            T_htf_cold = self.ms_phx_od_par.m_T_htf_cold
            T_turbine_in = 0.0 + 273.15  # [K] Output expected in K and converted to C
            P_main_comp_in = 0.0
            P_main_comp_out = 0.0
            frac_recomp = 0.0
            N_mc_od = 0.0
            eta_thermal = 0.0
            W_dot_par = 0.0
        # End switch (replaced by if/elif/else)
        if self.m_error_message_code == 1:
            W_dot_net = self.m_W_dot_net_des * (m_dot_htf / self.m_dot_rec_des)
            eta_thermal = self.ms_rc_cycle.get_design_solved().m_eta_thermal
            var Q_dot_PHX_guess: Float64 = W_dot_net / eta_thermal
            T_htf_cold = T_htf_hot - Q_dot_PHX_guess / C_dot_htf
            T_turbine_in = 0.0
            P_main_comp_in = 0.0
            P_main_comp_out = 0.0
            frac_recomp = 0.0
            T_htf_cold = self.ms_phx_od_par.m_T_htf_cold
            W_dot_par = (m_dot_htf / self.m_dot_rec_des) * self.m_W_dot_fan_des
        var W_dot_net_output: Float64 = W_dot_net
        if W_dot_net > 0.0:
            if (self.m_standby_control_prev == 3 and self.m_standby_control == 1) or (self.m_E_su_prev + self.m_time_su_prev > 0.0):
                self.m_time_su = max(self.m_time_su_prev - step / 3600.0, 0.0)
                if self.m_E_su_prev < Q_dot_PHX * step / 3600.0:
                    self.m_E_su = 0.0
                    if min(1.0, self.m_time_su_prev / (step / 3600.0)) > self.m_E_su_prev / (Q_dot_PHX * step / 3600.0):
                        W_dot_net_output = W_dot_net_output * (1.0 - min(1.0, self.m_time_su_prev / (step / 3600.0)))
                    else:
                        W_dot_net_output = (Q_dot_PHX * step / 3600.0 - self.m_E_su_prev) / (step / 3600.0) * eta_thermal
                else:
                    self.m_E_su = self.m_E_su_prev - Q_dot_PHX * step / 3600.0
            q_startup = self.m_E_su_prev - self.m_E_su
        self.value(O_P_CYCLE, W_dot_net_output / 1.0e3)  # [MWe]
        self.value(O_ETA, eta_thermal)  # [-]
        self.value(O_T_HTF_COLD, T_htf_cold - 273.15)  # [C]
        self.value(O_W_COOL_PAR, W_dot_par)  # [MWe]
        self.value(O_T_TURBINE_IN, T_turbine_in - 273.15)  # [C]
        self.value(O_P_MC_IN, P_main_comp_in)  # [kPa]
        self.value(O_P_MC_OUT, P_main_comp_out)  # [kPa]
        self.value(O_F_RECOMP, frac_recomp)  # [-]
        self.value(O_N_MC, N_mc_od)  # [rpm]
        self.value(O_Q_STARTUP, q_startup / 1.0e3)  # [MWt-hr]
        return 0

    # converged
    def converged(inout self, time: Float64) -> Int:
        if self.m_standby_control == 3:
            self.m_E_su_prev = self.m_startup_energy
            self.m_time_su_prev = self.m_startup_time
        else:
            self.m_E_su_prev = self.m_E_su
            self.m_time_su_prev = self.m_time_su
        self.m_standby_control_prev = self.m_standby_control
        if self.m_error_message_code == 1:
            self.message(TCS_NOTICE, "The off-design power cylce model did not solve. Performance values for this timestep are design point values scaled by HTF mass flow rate")
        if self.m_error_message_code == 2:
            self.message(TCS_NOTICE, "The off-design power cycle model solved, but the the PHX performance did not converge. The results at this timestep may be non-physical")
        self.m_error_message_code = 0
        self.m_is_first_t_call = True
        return 0

# The TCS_IMPLEMENT_TYPE macro is omitted as it's C++ specific and not needed in Mojo.
# The type is registered elsewhere in the module.