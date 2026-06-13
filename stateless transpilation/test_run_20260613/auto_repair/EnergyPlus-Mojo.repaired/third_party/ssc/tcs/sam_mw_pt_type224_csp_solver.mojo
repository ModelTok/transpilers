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
from tcstype import *
from htf_props import *
from powerblock import *
from csp_solver_pc_Rankine_indirect_224 import *
from csp_solver_util import *

enum:
    P_P_REF = 0
    P_ETA_REF = 1
    P_T_HTF_HOT_REF = 2
    P_T_HTF_COLD_REF = 3
    P_DT_CW_REF = 4
    P_T_AMB_DES = 5
    P_HTF = 6
    P_FIELD_FL_PROPS = 7
    P_Q_SBY_FRAC = 8
    P_P_BOIL = 9
    P_CT = 10
    P_STARTUP_TIME = 11
    P_STARTUP_FRAC = 12
    P_TECH_TYPE = 13
    P_T_APPROACH = 14
    P_T_ITD_DES = 15
    P_P_COND_RATIO = 16
    P_PB_BD_FRAC = 17
    P_PB_INPUT_FILE = 18
    P_P_COND_MIN = 19
    P_N_PL_INC = 20
    P_F_WC = 21
    P_CYCLE_MAX_FRAC = 22
    P_CYCLE_CUTOFF_FRAC = 23
    P_PB_PUMP_COEF = 24
    P_PC_CONFIG = 25
    P_UD_T_AMB_DES = 26
    P_UD_F_W_DOT_COOL_DES = 27
    P_UD_M_DOT_WATER_COOL_DES = 28
    P_UD_T_HTF_LOW = 29
    P_UD_T_HTF_HIGH = 30
    P_UD_T_AMB_LOW = 31
    P_UD_T_AMB_HIGH = 32
    P_UD_M_DOT_HTF_LOW = 33
    P_UD_M_DOT_HTF_HIGH = 34
    P_UD_T_HTF_IND_OD = 35
    P_UD_T_AMB_IND_OD = 36
    P_UD_M_DOT_HTF_IND_OD = 37
    P_UD_IND_OD = 38
    I_MODE = 39
    I_T_HTF_HOT = 40
    I_M_DOT_HTF = 41
    I_T_WB = 42
    I_DEMAND_VAR = 43
    I_STANDBY_CONTROL = 44
    I_T_DB = 45
    I_P_AMB = 46
    I_TOU = 47
    I_RH = 48
    O_P_CYCLE = 49
    O_ETA = 50
    O_T_HTF_COLD = 51
    O_M_DOT_MAKEUP = 52
    O_M_DOT_DEMAND = 53
    O_M_DOT_HTF_OUT = 54
    O_M_DOT_HTF_REF = 55
    O_W_COOL_PAR = 56
    O_P_REF_OUT = 57
    O_F_BAYS = 58
    O_P_COND = 59
    O_Q_STARTUP = 60
    N_MAX = 61

var sam_mw_pt_type224_variables: StaticArray[tcsvarinfo, N_MAX] = tcsvarinfo(
    { TCS_PARAM, TCS_NUMBER, P_P_REF, "P_ref", "Reference output electric power at design condition", "MW", "", "", "111" },
    { TCS_PARAM, TCS_NUMBER, P_ETA_REF, "eta_ref", "Reference conversion efficiency at design condition", "none", "", "", "0.3774" },
    { TCS_PARAM, TCS_NUMBER, P_T_HTF_HOT_REF, "T_htf_hot_ref", "Reference HTF inlet temperature at design", "C", "", "", "391" },
    { TCS_PARAM, TCS_NUMBER, P_T_HTF_COLD_REF, "T_htf_cold_ref", "Reference HTF outlet temperature at design", "C", "", "", "293" },
    { TCS_PARAM, TCS_NUMBER, P_DT_CW_REF, "dT_cw_ref", "Reference condenser cooling water inlet/outlet T diff", "C", "", "", "10" },
    { TCS_PARAM, TCS_NUMBER, P_T_AMB_DES, "T_amb_des", "Reference ambient temperature at design point", "C", "", "", "20" },
    { TCS_PARAM, TCS_NUMBER, P_HTF, "HTF", "Integer flag identifying HTF in power block", "none", "", "", "21" },
    { TCS_PARAM, TCS_NUMBER, P_FIELD_FL_PROPS, "field_fl_props", "User defined field fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_Q_SBY_FRAC, "q_sby_frac", "Fraction of thermal power required for standby mode", "none", "", "", "0.2" },
    { TCS_PARAM, TCS_NUMBER, P_P_BOIL, "P_boil", "Boiler operating pressure", "bar", "", "", "100" },
    { TCS_PARAM, TCS_NUMBER, P_CT, "CT", "Flag for using dry cooling or wet cooling system", "none", "", "", "1" },
    { TCS_PARAM, TCS_NUMBER, P_STARTUP_TIME, "startup_time", "Time needed for power block startup", "hr", "", "", "0.5" },
    { TCS_PARAM, TCS_NUMBER, P_STARTUP_FRAC, "startup_frac", "Fraction of design thermal power needed for startup", "none", "", "", "0.2" },
    { TCS_PARAM, TCS_NUMBER, P_TECH_TYPE, "tech_type", "Flag indicating which coef. set to use. (1=tower,2=trough,3=user)", "none", "", "", "2" },
    { TCS_PARAM, TCS_NUMBER, P_T_APPROACH, "T_approach", "Cooling tower approach temperature", "C", "", "", "5" },
    { TCS_PARAM, TCS_NUMBER, P_T_ITD_DES, "T_ITD_des", "ITD at design for dry system", "C", "", "", "16" },
    { TCS_PARAM, TCS_NUMBER, P_P_COND_RATIO, "P_cond_ratio", "Condenser pressure ratio", "none", "", "", "1.0028" },
    { TCS_PARAM, TCS_NUMBER, P_PB_BD_FRAC, "pb_bd_frac", "Power block blowdown steam fraction ", "none", "", "", "0.02" },
    { TCS_PARAM, TCS_STRING, P_PB_INPUT_FILE, "pb_input_file", "Power block coefficient file name", "none", "", "", "pb_coef_file.in" },
    { TCS_PARAM, TCS_NUMBER, P_P_COND_MIN, "P_cond_min", "Minimum condenser pressure", "inHg", "", "", "1.25" },
    { TCS_PARAM, TCS_NUMBER, P_N_PL_INC, "n_pl_inc", "Number of part-load increments for the heat rejection system", "none", "", "", "2" },
    { TCS_PARAM, TCS_ARRAY, P_F_WC, "F_wc", "Fraction indicating wet cooling use for hybrid system", "none", "", "", "0,0,0,0,0,0,0,0,0" },
    { TCS_PARAM, TCS_NUMBER, P_CYCLE_MAX_FRAC, "cycle_max_frac", "Maximum turbine over design operation fraction", "-", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_CYCLE_CUTOFF_FRAC, "cycle_cutoff_frac", "Minimum turbine operation fraction before shutdown", "-", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_PB_PUMP_COEF, "pb_pump_coef", "Pumping power to move 1kg of HTF through PB loop", "kW/kg/s", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_PC_CONFIG, "pc_config", "0: Steam Rankine, 1: user defined", "-", "", "", "0" },
    { TCS_PARAM, TCS_NUMBER, P_UD_T_AMB_DES, "ud_T_amb_des", "Ambient temperature at user-defined power cycle design point", "C", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_F_W_DOT_COOL_DES, "ud_f_W_dot_cool_des", "Percent of user-defined power cycle design gross output consumed by cooling", "%", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_M_DOT_WATER_COOL_DES, "ud_m_dot_water_cool_des", "Mass flow rate of water required at user-defined power cycle design point", "kg/s", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_T_HTF_LOW, "ud_T_htf_low", "Low level HTF inlet temperature for T_amb parametric", "C", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_T_HTF_HIGH, "ud_T_htf_high", "High level HTF inlet temperature for T_amb parametric", "C", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_T_AMB_LOW, "ud_T_amb_low", "Low level ambient temperature for HTF mass flow rate parametric", "C", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_T_AMB_HIGH, "ud_T_amb_high", "High level ambient temperature for HTF mass flow rate parametric", "C", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_M_DOT_HTF_LOW, "ud_m_dot_htf_low", "Low level normalized HTF mass flow rate for T_HTF parametric", "-", "", "", "" },
    { TCS_PARAM, TCS_NUMBER, P_UD_M_DOT_HTF_HIGH, "ud_m_dot_htf_high", "High level normalized HTF mass flow rate for T_HTF parametric", "-", "", "", "" },
    { TCS_PARAM, TCS_MATRIX, P_UD_T_HTF_IND_OD, "ud_T_htf_ind_od", "Off design table of user-defined power cycle performance formed from parametric on T_htf_hot [C]", "", "", "", "" },
    { TCS_PARAM, TCS_MATRIX, P_UD_T_AMB_IND_OD, "ud_T_amb_ind_od", "Off design table of user-defined power cycle performance formed from parametric on T_amb [C]", "", "", "", "" },
    { TCS_PARAM, TCS_MATRIX, P_UD_M_DOT_HTF_IND_OD, "ud_m_dot_htf_ind_od", "Off design table of user-defined power cycle performance formed from parametric on m_dot_htf [ND]", "", "", "", "" },
    { TCS_PARAM, TCS_MATRIX, P_UD_IND_OD, "ud_ind_od", "Off design user-defined power cycle performance as function of T_htf, m_dot_htf [ND], and T_amb", "", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_MODE, "mode", "Cycle part load control, from plant controller", "none", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_T_HTF_HOT, "T_htf_hot", "Hot HTF inlet temperature, from storage tank", "C", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_M_DOT_HTF, "m_dot_htf", "HTF mass flow rate", "kg/hr", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_T_WB, "T_wb", "Ambient wet bulb temperature", "C", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_DEMAND_VAR, "demand_var", "Control signal indicating operational mode", "none", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_STANDBY_CONTROL, "standby_control", "Control signal indicating standby mode", "none", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_T_DB, "T_db", "Ambient dry bulb temperature", "C", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_P_AMB, "P_amb", "Ambient pressure", "mbar", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_TOU, "TOU", "Current Time-of-use period", "none", "", "", "" },
    { TCS_INPUT, TCS_NUMBER, I_RH, "rh", "Relative humidity of the ambient air", "none", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_P_CYCLE, "P_cycle", "Cycle power output", "MWe", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_ETA, "eta", "Cycle thermal efficiency", "none", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_T_HTF_COLD, "T_htf_cold", "Heat transfer fluid outlet temperature ", "C", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_M_DOT_MAKEUP, "m_dot_makeup", "Cooling water makeup flow rate", "kg/hr", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_M_DOT_DEMAND, "m_dot_demand", "HTF required flow rate to meet power load", "kg/hr", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_M_DOT_HTF_OUT, "m_dot_htf_out", "Actual HTF flow rate passing through the power cycle", "kg/hr", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_M_DOT_HTF_REF, "m_dot_htf_ref", "Calculated reference HTF flow rate at design", "kg/hr", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_W_COOL_PAR, "W_cool_par", "Cooling system parasitic load", "MWe", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_P_REF_OUT, "P_ref_out", "Reference power level output at design (mirror param)", "MWe", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_F_BAYS, "f_bays", "Fraction of operating heat rejection bays", "none", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_P_COND, "P_cond", "Condenser pressure", "Pa", "", "", "" },
    { TCS_OUTPUT, TCS_NUMBER, O_Q_STARTUP, "q_pc_startup", "Power cycle startup energy", "MWt-hr", "", "", "" },
    { TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0 }
)

class sam_mw_pt_type224(tcstypeinterface):
    var mc_power_cycle: C_pc_Rankine_indirect_224
    var ms_weather: C_csp_weatherreader.S_outputs
    var ms_sim_info: C_csp_solver_sim_info
    var ms_htf_state_in: C_csp_solver_htf_1state
    var ms_inputs: C_csp_power_cycle.S_control_inputs
    var ms_out_solver: C_csp_power_cycle.S_csp_pc_out_solver
    var p_eta_thermal: Pointer[Float64]
    var p_m_dot_water: Pointer[Float64]
    var p_q_dot_startup: Pointer[Float64]

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.p_eta_thermal = Pointer[Float64].alloc(8760)
        self.mc_power_cycle.mc_reported_outputs.assign(C_pc_Rankine_indirect_224.E_ETA_THERMAL, self.p_eta_thermal, 8760)
        self.p_m_dot_water = Pointer[Float64].alloc(8760)
        self.mc_power_cycle.mc_reported_outputs.assign(C_pc_Rankine_indirect_224.E_T_HTF_OUT, self.p_m_dot_water, 8760)
        self.p_q_dot_startup = Pointer[Float64].alloc(8760)
        self.mc_power_cycle.mc_reported_outputs.assign(C_pc_Rankine_indirect_224.E_Q_DOT_STARTUP, self.p_q_dot_startup, 8760)

    def __del__(owned self):
        del self.p_eta_thermal
        del self.p_m_dot_water
        del self.p_q_dot_startup

    def init(inout self) -> Int32:
        var p_params: C_pc_Rankine_indirect_224.S_params = self.mc_power_cycle.ms_params
        p_params.m_P_ref = self.value(P_P_REF)
        p_params.m_eta_ref = self.value(P_ETA_REF)
        p_params.m_T_htf_hot_ref = self.value(P_T_HTF_HOT_REF)
        p_params.m_T_htf_cold_ref = self.value(P_T_HTF_COLD_REF)
        p_params.m_cycle_max_frac = self.value(P_CYCLE_MAX_FRAC)
        p_params.m_cycle_cutoff_frac = self.value(P_CYCLE_CUTOFF_FRAC)
        p_params.m_q_sby_frac = self.value(P_Q_SBY_FRAC)
        p_params.m_startup_time = self.value(P_STARTUP_TIME)
        p_params.m_startup_frac = self.value(P_STARTUP_FRAC)
        p_params.m_htf_pump_coef = self.value(P_PB_PUMP_COEF)
        p_params.m_pc_fl = Int32(self.value(P_HTF))
        var n_rows: Int32 = -1
        var n_cols: Int32 = -1
        var pc_fl_props: Pointer[Float64] = self.value(P_FIELD_FL_PROPS, &n_rows, &n_cols)
        p_params.m_pc_fl_props.resize(n_rows, n_cols)
        for r in range(n_rows):
            for c in range(n_cols):
                p_params.m_pc_fl_props[r, c] = TCS_MATRIX_INDEX(self.var(P_FIELD_FL_PROPS), r, c)
        p_params.m_is_user_defined_pc = Int32(self.value(P_PC_CONFIG)) == 1
        if not p_params.m_is_user_defined_pc:
            p_params.m_dT_cw_ref = self.value(P_DT_CW_REF)
            p_params.m_T_amb_des = self.value(P_T_AMB_DES)
            p_params.m_P_boil = self.value(P_P_BOIL)
            p_params.m_CT = Int32(self.value(P_CT))
            p_params.m_tech_type = Int32(self.value(P_TECH_TYPE))
            p_params.m_T_approach = self.value(P_T_APPROACH)
            p_params.m_T_ITD_des = self.value(P_T_ITD_DES)
            p_params.m_P_cond_ratio = self.value(P_P_COND_RATIO)
            p_params.m_pb_bd_frac = self.value(P_PB_BD_FRAC)
            p_params.m_P_cond_min = self.value(P_P_COND_MIN)
            p_params.m_n_pl_inc = Int32(self.value(P_N_PL_INC))
            var nval_F_wc: Int32 = -1
            var F_wc: Pointer[Float64] = self.value(P_F_WC, &nval_F_wc)
            p_params.m_F_wc.resize(nval_F_wc)
            for i in range(nval_F_wc):
                p_params.m_F_wc[i] = F_wc[i]
        else:
            p_params.m_T_amb_des = self.value(P_UD_T_AMB_DES)
            p_params.m_W_dot_cooling_des = self.value(P_UD_F_W_DOT_COOL_DES) / 100.0 * p_params.m_P_ref
            p_params.m_m_dot_water_des = self.value(P_UD_M_DOT_WATER_COOL_DES)
            p_params.m_T_htf_low = self.value(P_UD_T_HTF_LOW)
            p_params.m_T_htf_high = self.value(P_UD_T_HTF_HIGH)
            p_params.m_T_amb_low = self.value(P_UD_T_AMB_LOW)
            p_params.m_T_amb_high = self.value(P_UD_T_AMB_HIGH)
            p_params.m_m_dot_htf_low = self.value(P_UD_M_DOT_HTF_LOW)
            p_params.m_m_dot_htf_high = self.value(P_UD_M_DOT_HTF_HIGH)
            n_rows = -1
            n_cols = -1
            var p_T_htf_ind: Pointer[Float64] = self.value(P_UD_T_HTF_IND_OD, &n_rows, &n_cols)
            p_params.mc_T_htf_ind.resize(n_rows, n_cols)
            for r in range(n_rows):
                for c in range(n_cols):
                    p_params.mc_T_htf_ind[r, c] = TCS_MATRIX_INDEX(self.var(P_UD_T_HTF_IND_OD), r, c)
            n_rows = -1
            n_cols = -1
            var p_T_amb_ind: Pointer[Float64] = self.value(P_UD_T_AMB_IND_OD, &n_rows, &n_cols)
            p_params.mc_T_amb_ind.resize(n_rows, n_cols)
            for r in range(n_rows):
                for c in range(n_cols):
                    p_params.mc_T_amb_ind[r, c] = TCS_MATRIX_INDEX(self.var(P_UD_T_AMB_IND_OD), r, c)
            n_rows = -1
            n_cols = -1
            var p_m_dot_htf_ind: Pointer[Float64] = self.value(P_UD_M_DOT_HTF_IND_OD, &n_rows, &n_cols)
            p_params.mc_m_dot_htf_ind.resize(n_rows, n_cols)
            for r in range(n_rows):
                for c in range(n_cols):
                    p_params.mc_m_dot_htf_ind[r, c] = TCS_MATRIX_INDEX(self.var(P_UD_M_DOT_HTF_IND_OD), r, c)
            n_rows = -1
            n_cols = -1
            var p_ind: Pointer[Float64] = self.value(P_UD_IND_OD, &n_rows, &n_cols)
            p_params.mc_combined_ind.resize(n_rows, n_cols)
            for r in range(n_rows):
                for c in range(n_cols):
                    p_params.mc_combined_ind[r, c] = TCS_MATRIX_INDEX(self.var(P_UD_IND_OD), r, c)
        var out_type: Int32 = -1
        var out_msg: String = ""
        try:
            var solved_params: C_csp_power_cycle.S_solved_params
            self.mc_power_cycle.init(solved_params)
        except C_csp_exception as csp_exception:
            while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
        self.ms_htf_state_in.m_temp = self.value(I_T_HTF_HOT)
        self.ms_inputs.m_m_dot = self.value(I_M_DOT_HTF)
        self.ms_weather.m_twet = self.value(I_T_WB)
        self.ms_inputs.m_standby_control = C_csp_power_cycle.E_csp_power_cycle_modes(Int32(self.value(I_STANDBY_CONTROL)))
        self.ms_weather.m_tdry = self.value(I_T_DB)
        self.ms_weather.m_pres = self.value(I_P_AMB)
        self.ms_weather.m_rhum = self.value(I_RH) / 100.0
        self.ms_sim_info.ms_ts.m_time = time
        self.ms_sim_info.ms_ts.m_step = step
        self.ms_sim_info.m_tou = Int32(self.value(I_TOU))
        var out_type: Int32 = -1
        var out_msg: String = ""
        try:
            self.mc_power_cycle.call(self.ms_weather, self.ms_htf_state_in, self.ms_inputs, self.ms_out_solver, self.ms_sim_info)
        except C_csp_exception as csp_exception:
            while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        self.value(O_P_CYCLE, self.ms_out_solver.m_P_cycle)
        self.value(O_ETA, self.mc_power_cycle.mc_reported_outputs.value(C_pc_Rankine_indirect_224.E_ETA_THERMAL))
        self.value(O_T_HTF_COLD, self.ms_out_solver.m_T_htf_cold)
        self.value(O_M_DOT_MAKEUP, self.mc_power_cycle.mc_reported_outputs.value(C_pc_Rankine_indirect_224.E_M_DOT_WATER))
        self.value(O_M_DOT_DEMAND, 0.0)
        self.value(O_P_REF_OUT, 0.0)
        self.value(O_F_BAYS, 0.0)
        self.value(O_P_COND, 0.0)
        self.value(O_M_DOT_HTF_OUT, self.ms_out_solver.m_m_dot_htf)
        self.value(O_M_DOT_HTF_REF, self.mc_power_cycle.mc_reported_outputs.value(C_pc_Rankine_indirect_224.E_M_DOT_HTF_REF))
        self.value(O_W_COOL_PAR, self.ms_out_solver.m_W_cool_par)
        self.value(O_Q_STARTUP, self.mc_power_cycle.mc_reported_outputs.value(C_pc_Rankine_indirect_224.E_Q_DOT_STARTUP))
        return 0

    def converged(inout self, time: Float64) -> Int32:
        var out_type: Int32 = -1
        var out_msg: String = ""
        try:
            self.mc_power_cycle.converged()
        except C_csp_exception as csp_exception:
            while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_power_cycle.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_pt_type224, "Indirect HTF power cycle model", "Mike Wagner", 1, sam_mw_pt_type224_variables, None, 1)