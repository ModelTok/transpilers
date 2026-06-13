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
from thermocline_tes import Thermocline_TES, HTFProperties
from math import nan

enum:	//Parameters
	P_h = 0
	P_A = 1
	P_fill_mat = 2
	P_U = 3
	P_U_top = 4
	P_U_bot = 5
	P_f_void = 6
	P_capfac = 7
	P_Thmin = 8
	P_Tcmax = 9
	P_nodes = 10
	P_T_hot_ini = 11
	P_T_cold_ini = 12
	P_TC_break = 13
	P_T_htr_set = 14
	P_max_htr_q = 15
	P_n_pairs = 16
	P_fluid_mat = 17
	I_T_hot_in = 18
	I_flow_h = 19
	I_T_cold_in = 20
	I_flow_c = 21
	I_T_env = 22
	I_solve_mode = 23
	I_Q_dis_target = 24
	I_Q_cha_target = 25
	I_f_storage = 26
	I_delta_time = 27
	O_m_dot_dis_avail = 28
	O_T_dis_avail = 29
	O_m_dot_cha_avail = 30
	O_T_cha_avail = 31
	O_Q_dot_out = 32
	O_Q_dot_losses = 33
	O_T_hot_bed = 34
	O_T_cold_bed = 35
	O_T_max_bed = 36
	O_f_hot = 37
	O_f_cold = 38
	O_Q_htr = 39
	O_T_TC_start = 40
	N_MAX = 41

var tc_test_type402_variables: StaticArray[tcsvarinfo, 42] = StaticArray[tcsvarinfo, 42](
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h,          "h",          "Height of the rock bed storage tank",                               "m",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_A,          "A",          "Cross-sectional area of storage tank",                              "m2",         "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_fill_mat,   "fill_mat",   "Filler material integer - see code",                                "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_U,          "U",          "Tank loss coefficient",                                             "kJ/hr-m2-K", "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_U_top,      "U_top",      "Top surface loss coefficient",                                      "kJ/hr-m2-K", "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_U_bot,      "U_bot",      "Bottom surface loss coefficient",                                   "kJ/hr-m2-k", "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_f_void,     "f_void",     "Rock bed void fraction",                                            "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_capfac,     "capfac",     "Bottom thermal mass capacitance factor multiplier",                 "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Thmin,      "Thmin",      "Min allowable hot side outlet temp during discharage",              "C",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Tcmax,      "Tcmax",      "Max allowable cold side outlet temp during charge",                 "C",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_nodes,      "nodes",      "Number of nodes in thermocline model",                              "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_hot_ini,  "T_hot_ini",  "Initial thermocline hot temperature",                               "C",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_cold_ini, "T_cold_ini", "Initial thermocline cold temperature",                              "C",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TC_break,   "TC_break",   "Fraction into tank for initial TC break (0: all hot, 1: all cold)", "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_htr_set,  "T_htr_set",  "Min tank temp before aux heater starts",                            "C",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_max_htr_q,  "max_htr_q",  "Capacity of tank heater",                                           "MW",         "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_pairs,    "n_pairs",    "Number of equivalent tank pairs",                                   "-",          "", "", "" ),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_fluid_mat,  "fluid_mat",  "Fluid material integer - see code",                                 "-",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_hot_in,      "T_hot_in",       "Charging (hot) temp into top of tank",                              "C",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_flow_h,        "flow_h",         "Charging (hot) mass flow rate into top of tank",                    "kg/hr",      "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_cold_in,     "T_cold_in",      "Discharging (cold) temp into bottom of tank",                       "C",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_flow_c,        "flow_c",         "Discharging (cold) mass flow rate into bottom of tank",             "kg/hr",      "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_env,         "T_env",          "Ambient (environment) temperature",                                 "C",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_solve_mode,    "solve_mode",     "Solve thermocline (1) or check availability (2)",                   "-",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_dis_target,  "Q_dis_target",   "Discharge rate required by controller",                             "W",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_cha_target,  "Q_cha_target",   "Charge rate required by controller",                                "W",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_f_storage,     "f_storage",      "Storage dispatch fraction",                                         "-",          "", "", "" ),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_delta_time,    "delta_time",     "Duration of steady state timestep",                                 "hr",         "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_m_dot_dis_avail,  "m_dot_dis_avail",    "Mass flow rate available for discharge",                    "kg/hr",      "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_dis_avail,      "T_dis_avail",        "Discharge (hot) outlet temperature (time averaged)",        "C",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_m_dot_cha_avail,  "m_dot_cha_avail",    "Mass flow rate available for charging",                     "kg/hr",      "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_cha_avail,      "T_cha_avail",        "Charge (cold) outlet temperature (time averaged)",          "C",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_dot_out,        "Q_dot_out",          "Thermal power (always +)",                                  "W",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_dot_losses,     "Q_dot_losses",       "Energy lost to environment",                                "kJ",         "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_hot_bed,        "T_hot_bed",          "Final temp at hot (top) node",                              "C",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_cold_bed,       "T_cold_bed",         "Final temp at cold (bottom) node",                          "C",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_max_bed,        "T_max_bed",          "Maximum temp in tank",                                      "C",          "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_f_hot,            "f_hot",              "Fraction of depth at which hot temperature decreases below minimum hot temperature limit", "-", "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_f_cold,           "f_cold",             "Fraction of depth at which cold temperature increases above maximum cold temperature limit", "-", "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_htr,            "Q_dot_htr",          "Total energy required by heater to maintain min temp in tank", "kJ",      "", "", "" ),
	tcsvarinfo(TCS_OUTPUT, TCS_ARRAY,  O_T_TC_start,       "T_TC_start",         "Temperature profile of thermocline at start of timestep",   "C",          "", "", "" ),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0 )
)

@value
struct tc_test_type402(tcstypeinterface):
	var n_zen: Float64
	var thermocline: Thermocline_TES
	var htfProps: HTFProperties		// Instance of HTFProperties class for field HTF

	def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cst, ti)
		self.n_zen = nan

	def __del__(owned self):

	def init(inout self) -> Int32:
		var h: Float64 = self.value(P_h)         
		var A: Float64 = self.value(P_A)         
		var fill_mat: Int32 = Int32(self.value(P_fill_mat))  
		var U: Float64 = self.value(P_U)         
		var U_top: Float64 = self.value(P_U_top)     
		var U_bot: Float64 = self.value(P_U_bot)     
		var f_void: Float64 = self.value(P_f_void)    
		var capfac: Float64 = self.value(P_capfac)    
		var Thmin: Float64 = self.value(P_Thmin)     
		var Tcmax: Float64 = self.value(P_Tcmax)     
		var nodes: Float64 = self.value(P_nodes)     
		var T_hot_ini: Float64 = self.value(P_T_hot_ini) 
		var T_cold_ini: Float64 = self.value(P_T_cold_ini)
		var TC_break: Float64 = self.value(P_TC_break)  
		var T_htr_set: Float64 = self.value(P_T_htr_set) 
		var max_htr_q: Float64 = self.value(P_max_htr_q) 
		var n_pairs: Float64 = self.value(P_n_pairs)   
		var fluid_mat: Int32 = Int32(self.value(P_fluid_mat)) 
		self.htfProps.SetFluid(fluid_mat)
		self.thermocline.Initialize_TC(h, A, fill_mat, U, U_top, U_bot, f_void, capfac, Thmin, Tcmax, Int32(nodes), T_hot_ini, T_cold_ini,
			TC_break, T_htr_set, max_htr_q, Int32(n_pairs), self.htfProps)
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
		var T_hot_in: Float64 = self.value(I_T_hot_in)    
		var flow_h: Float64 = self.value(I_flow_h)      
		var T_cold_in: Float64 = self.value(I_T_cold_in)   
		var flow_c: Float64 = self.value(I_flow_c)      
		var T_env: Float64 = self.value(I_T_env)       
		var solve_mode: Float64 = self.value(I_solve_mode)  
		var Q_dis_target: Float64 = self.value(I_Q_dis_target)
		var Q_cha_target: Float64 = self.value(I_Q_cha_target)
		var f_storage: Float64 = self.value(I_f_storage)   
		var delta_time: Float64 = self.value(I_delta_time)  
		var m_dot_dis_avail: Float64 = nan
		var T_dis_avail: Float64 = nan
		var m_dot_cha_avail: Float64 = nan
		var T_cha_avail: Float64 = nan
		var Q_dot_out: Float64 = nan
		var Q_dot_losses: Float64 = nan
		var T_hot_bed: Float64 = nan
		var T_cold_bed: Float64 = nan
		var T_max_bed: Float64 = nan
		var f_hot: Float64 = nan
		var f_cold: Float64 = nan
		var Q_dot_htr: Float64 = nan
		self.thermocline.Solve_TC(T_hot_in, flow_h, T_cold_in, flow_c, T_env, Int32(solve_mode), Q_dis_target, Q_cha_target, f_storage,
			delta_time, m_dot_dis_avail, T_dis_avail, m_dot_cha_avail, T_cha_avail, Q_dot_out, Q_dot_losses, T_hot_bed,
			T_cold_bed, T_max_bed, f_hot, f_cold, Q_dot_htr)
		self.value(O_m_dot_dis_avail, m_dot_dis_avail)
		self.value(O_T_dis_avail,     T_dis_avail)    
		self.value(O_m_dot_cha_avail, m_dot_cha_avail)
		self.value(O_T_cha_avail,     T_cha_avail)    
		self.value(O_Q_dot_out,       Q_dot_out)      
		self.value(O_Q_dot_losses,    Q_dot_losses)   
		self.value(O_T_hot_bed,       T_hot_bed)      
		self.value(O_T_cold_bed,      T_cold_bed)     
		self.value(O_T_max_bed,       T_max_bed)      
		self.value(O_f_hot,           f_hot)          
		self.value(O_f_cold,          f_cold)         
		self.value(O_Q_htr,           Q_dot_htr)      		
		return 0

	def converged(inout self, time: Float64) -> Int32:
		self.thermocline.Converged(time)
		return 0

TCS_IMPLEMENT_TYPE(tc_test_type402, "Test type for thermocline storage", "Ty Neises", 1, tc_test_type402_variables, NULL, 1)