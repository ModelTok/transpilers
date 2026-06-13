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
from tcstype import tcscontext, tcstypeinfo, tcsvarinfo, TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_INVALID, tcstypeinterface, TCS_IMPLEMENT_TYPE

enum:
	P_W_HTF_PC_PUMP = 0
	P_Q_SF_DES = 1
	P_PB_FIXED_PAR = 2
	P_BOP_PAR = 3
	P_BOP_PAR_F = 4
	P_BOP_PAR_0 = 5
	P_BOP_PAR_1 = 6
	P_BOP_PAR_2 = 7
	P_W_DOT_FOSSIL_DES = 8
	P_W_DOT_SOLAR_DES = 9
	I_W_DOT_TRACKING = 10
	I_W_DOT_REC_PUMP = 11
	I_M_DOT_HTF_SS = 12
	I_W_DOT_PC_HYBRID = 13
	I_W_DOT_PC_FOSSIL = 14
	I_F_TIMESTEP = 15
	I_Q_SOLAR_SS = 16
	I_Q_DOT_FUEL = 17
	O_W_DOT_PC_HYBRID = 18
	O_W_DOT_PC_FOSSIL = 19
	O_W_DOT_PLANT_HYBRID = 20
	O_W_DOT_PLANT_FOSSIL = 21
	O_W_DOT_PLANT_SOLAR = 22
	O_ETA_SOLAR_USE = 23
	O_ETA_FUEL = 24
	O_SOLAR_FRACTION = 25
	O_P_PLANT_BALANCE_TOT = 26
	O_P_FIXED = 27
	N_MAX = 28

var sam_iscc_parasitics_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_W_HTF_PC_PUMP,      "W_htf_pc_pump",          "Required pumping power for HTF through power block",             "kJ/kg",     "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Q_SF_DES,           "Q_sf_des",               "Design point solar field thermal output",                        "MW",        "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_PB_FIXED_PAR,       "pb_fixed_par",           "Fixed parasitic load - runs at all times",                       "MWe/MWcap", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BOP_PAR,            "bop_par",                "Balance of plant parasitic power fraction",                      "MWe/MWcap", "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BOP_PAR_F,          "bop_par_f",              "Balance of plant parasitic power fraction - mult frac",          "none",      "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BOP_PAR_0,          "bop_par_0",              "Balance of plant parasitic power fraction - const coeff",        "none",      "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BOP_PAR_1,          "bop_par_1",              "Balance of plant parasitic power fraction - linear coeff",       "none",      "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_BOP_PAR_2,          "bop_par_2",              "Balance of plant parasitic power fraction - quadratic coeff",    "none",      "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_W_DOT_FOSSIL_DES,   "W_dot_fossil_des",       "Fossil-only cycle output at design",                             "MWe",       "", "", ""),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_W_DOT_SOLAR_DES,    "W_dot_solar_des",        "Solar contribution to cycle output at design",                    "MWe",       "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_DOT_TRACKING,     "W_dot_tracking",         "Heliostat tracking power",                                 "MWe",   "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_DOT_REC_PUMP,     "W_dot_rec_pump",         "Receiver pumping power",                                   "MWe",   "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_M_DOT_HTF_SS,       "m_dot_htf_ss",           "HTF mass flow rate through PC HX at steady state - no derate for startup",                         "kg/s",  "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_DOT_PC_HYBRID,    "W_dot_pc_hybrid",        "Net PC power with solar",                                  "MWe",   "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_DOT_PC_FOSSIL,    "W_dot_pc_fossil",        "Net PC power at no-solar baseline",                      "MWe",   "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_F_TIMESTEP,         "f_timestep",             "Fraction of timestep that receiver is operational (not starting-up)",      "-",        "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_SOLAR_SS,         "q_solar_ss",             "Solar thermal power at steady state - no derate for startup", "MWe", "", "", ""),     
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_DOT_FUEL,         "q_dot_fuel",             "Fuel thermal power into gas turbines",                      "kW",    "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PC_HYBRID,   "W_dot_pc_hybrid",        "Net POWER CYCLE power output with solar",                  "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PC_FOSSIL,   "W_dot_pc_fossil",        "Net POWER CYCLE power output at baseline",                 "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PLANT_HYBRID,"W_dot_plant_hybrid",     "Net PLANT power output with solar",                        "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PLANT_FOSSIL,"W_dot_plant_fossil",     "Net PLANT power output at baseline",                       "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_DOT_PLANT_SOLAR, "W_dot_plant_solar",      "Net PLANT power output attributable",                      "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_SOLAR_USE,     "eta_solar_use",          "Solar use efficiency considering parasitics",              "",         "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_FUEL,          "eta_fuel",               "Electrical efficiency of fossil only operation",           "%",        "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLAR_FRACTION,    "solar_fraction",         "Solar contribution to total electrical power",             "-",        "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_PLANT_BALANCE_TOT, "P_plant_balance_tot",  "Total solar balance of plant parasitic power",             "MWe",      "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_FIXED,           "P_fixed",                "Total fixed parasitic losses",                             "MWe",      "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX,			0,					0, 0, 0, 0, 0)
)

class sam_iscc_parasitics(tcstypeinterface):
	var W_htf_pc_pump: Float64
	var Piping_loss: Float64
	var Piping_length: Float64
	var q_solar_design: Float64
	var pb_fixed_par: Float64
	var bop_par: Float64
	var bop_par_f: Float64
	var bop_par_0: Float64
	var bop_par_1: Float64
	var bop_par_2: Float64
	var W_dot_fossil_des: Float64
	var W_dot_solar_des: Float64
	var W_dot_total_des: Float64

	def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cst, ti)

	def __del__(inout self):
		self.W_htf_pc_pump = Float64.nan
		self.Piping_loss = Float64.nan
		self.Piping_length = Float64.nan
		self.q_solar_design = Float64.nan
		self.pb_fixed_par = Float64.nan
		self.bop_par = Float64.nan
		self.bop_par_f = Float64.nan
		self.bop_par_0 = Float64.nan
		self.bop_par_1 = Float64.nan
		self.bop_par_2 = Float64.nan
		self.W_dot_fossil_des = Float64.nan
		self.W_dot_solar_des = Float64.nan
		self.W_dot_total_des = Float64.nan

	def init(inout self) -> Int:
		self.W_htf_pc_pump = self.value(P_W_HTF_PC_PUMP)				#[kJ/kg]
		self.q_solar_design = self.value(P_Q_SF_DES)					#[MWt]
		self.pb_fixed_par = self.value(P_PB_FIXED_PAR)					#[-]
		self.bop_par = self.value(P_BOP_PAR)							#[MWe/MWcap]
		self.bop_par_f = self.value(P_BOP_PAR_F)						#[-]
		self.bop_par_0 = self.value(P_BOP_PAR_0)						#[-]
		self.bop_par_1 = self.value(P_BOP_PAR_1)						#[-]
		self.bop_par_2 = self.value(P_BOP_PAR_2)						#[-]
		self.W_dot_fossil_des = self.value(P_W_DOT_FOSSIL_DES)			#[MWe]
		self.W_dot_solar_des = self.value(P_W_DOT_SOLAR_DES)			#[MWe]
		self.W_dot_total_des = self.W_dot_fossil_des + self.W_dot_solar_des	#[MWe]
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
		var W_dot_tracking: Float64 = self.value(I_W_DOT_TRACKING)		#[MWe] Solar field startup and tracking power
		var W_dot_rec_pump: Float64 = self.value(I_W_DOT_REC_PUMP)		#[MWe] Power required to pump HTF through receiver
		var m_dot_htf: Float64 = self.value(I_M_DOT_HTF_SS)				#[kg/hr] Steady-state mass flow rate through receiver and HX
		var W_dot_pc_hybrid: Float64 = self.value(I_W_DOT_PC_HYBRID)	#[MWe] Steady state power cycle fossil+solar output
		var W_dot_pc_fossil: Float64 = self.value(I_W_DOT_PC_FOSSIL)    #[MWe] Fossil-only power cycle output
		var f_timestep: Float64 = self.value(I_F_TIMESTEP)				#[-] Fracion of timestep that receiver is operating (not starting up)
		var q_solar: Float64 = self.value(I_Q_SOLAR_SS)					#[MWt] Steady-state receiver thermal power 
		var q_dot_fuel: Float64 = self.value(I_Q_DOT_FUEL)				#[kWt] Fuel thermal power
		var W_dot_htf: Float64 = self.W_htf_pc_pump * m_dot_htf / (3600.0) / 1000.0		#[kJ/kg]*[kg/hr]*[hr/s]*[MW/kW] = [MWe] HTF pumping power through power cycle heat exchanger
		var P_ratio: Float64 = (W_dot_pc_hybrid - W_dot_pc_fossil) / self.W_dot_solar_des		#[-] Base on ratio of current and design solar contribution
		var W_dot_BOP: Float64 = 0.0
		if P_ratio > 0.0:
			W_dot_BOP = self.W_dot_solar_des * self.bop_par * self.bop_par_f * (self.bop_par_0 + self.bop_par_1 * P_ratio + self.bop_par_2 * (P_ratio ** 2))
		var W_dot_fixed: Float64 = self.pb_fixed_par * self.W_dot_total_des		#[MWe]
		var W_dot_plant_hybrid: Float64 = f_timestep * W_dot_pc_hybrid + (1.0 - f_timestep) * W_dot_pc_fossil \
			                        - W_dot_rec_pump - W_dot_tracking - W_dot_fixed \
									- f_timestep * (W_dot_htf + W_dot_BOP)
		var W_dot_plant_fossil: Float64 = W_dot_pc_fossil - W_dot_fixed
		var eta_fuel: Float64 = W_dot_plant_fossil * 1000.0 / q_dot_fuel * 100.0	#[%] Electrical efficiency of fossil-only mode after fixed losses
		var eta_solar_use: Float64 = 0.0
		if q_solar > 0.0:
			eta_solar_use = max(0.0, (W_dot_plant_hybrid - W_dot_plant_fossil) / (f_timestep * q_solar))		#[-] Solar use fraction with parasitics
		self.value(O_W_DOT_PC_HYBRID, f_timestep * W_dot_pc_hybrid + (1.0 - f_timestep) * W_dot_pc_fossil)
		self.value(O_W_DOT_PC_FOSSIL, W_dot_pc_fossil)
		self.value(O_W_DOT_PLANT_HYBRID, W_dot_plant_hybrid)			#[MWe]
		self.value(O_W_DOT_PLANT_FOSSIL, W_dot_plant_fossil)			#[MWe]
		self.value(O_W_DOT_PLANT_SOLAR, W_dot_plant_hybrid - W_dot_plant_fossil)
		self.value(O_ETA_SOLAR_USE, eta_solar_use)					#[MWe]
		self.value(O_ETA_FUEL, eta_fuel)					#[%]
		self.value(O_SOLAR_FRACTION, (W_dot_plant_hybrid - W_dot_plant_fossil) / W_dot_plant_hybrid)	#[-]
		self.value(O_P_PLANT_BALANCE_TOT, W_dot_BOP)
		self.value(O_P_FIXED, W_dot_fixed)
		return 0

	def converged(inout self, time: Float64) -> Int:
		return 0

TCS_IMPLEMENT_TYPE(sam_iscc_parasitics, "ISCC Powerblock ", "Ty Neises", 1, sam_iscc_parasitics_variables, NULL, 1)