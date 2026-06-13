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
from tcstype import tcsvarinfo, tcscontext, tcstypeinfo, tcstypeinterface, TCS_IMPLEMENT_TYPE
from tcstype import TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_INVALID, TCS_NUMBER, TCS_NUMBER
from math import nan

enum:
	P_ETA_LHV = 0
	P_ETA_TES_HTR = 1
	P_FP_MODE = 2
	I_W_CYCLE_GROSS = 3
	I_W_PAR_HEATREJ = 4
	I_W_PAR_SF_PUMP = 5
	I_W_PAR_TES_PUMP = 6
	I_W_PAR_BOP = 7
	I_W_PAR_FIXED = 8
	I_W_PAR_TRACKING = 9
	I_W_PAR_AUX_BOILER = 10
	I_Q_PAR_TES_FP = 11
	I_Q_PAR_SF_FP = 12
	I_Q_AUX_BACKUP = 13
	O_W_NET = 14
	O_HOURLY_ENERGY = 15
	O_W_PAR_TOT = 16
	O_FUEL_USAGE = 17
	O_Q_FP_TOT = 18
	N_MAX = 19

var sam_mw_csp_SumCalcs_variables = List[tcsvarinfo](
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_LHV, "eta_lhv", "Fossil fuel lower heating value - Thermal power generated per unit fuel", "MW/MMBTU", "", "", "0.9"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ETA_TES_HTR, "eta_tes_htr", "Thermal storage tank heater efficiency (fp_mode=1 only)", "none", "", "", "0.98"),
	tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_FP_MODE, "fp_mode", "Freeze protection mode (1=Electrical heating ; 2=Fossil heating)", "none", "", "", "1"),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_CYCLE_GROSS, "W_cycle_gross", "Electrical source - Power cycle gross output", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_HEATREJ, "W_par_heatrej", "Electrical parasitic - power cycle heat rejection system", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_SF_PUMP, "W_par_sf_pump", "Electrical parasitic - solar field HTF pumping power", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_TES_PUMP, "W_par_tes_pump", "Electrical parasitic - TES dispatch pumping power", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_BOP, "W_par_BOP", "Electrical parasitic - Balance of plant equipment - variable with generation", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_FIXED, "W_par_fixed", "Electrical parasitic - Constant parasitic for plant operations", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_TRACKING, "W_par_tracking", "Electrical parasitic - Power required for solar field collector drive operation", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_AUX_BOILER, "W_par_aux_boiler", "Electrical parasitic - Electrical power required to operate auxiliary fossil system", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_PAR_TES_FP, "Q_par_tes_fp", "Modal parasitic - Thermal energy used for freeze protection in TES", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_PAR_SF_FP, "Q_par_sf_fp", "Modal parasitic - Thermal energy used for freeze protection in the receiver/solar field", "MW", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_Q_AUX_BACKUP, "Q_aux_backup", "Thermal source - Thermal power provided by the auxiliary fossil backup system for generation", "MW", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_NET, "W_net", "Net electricity generation (or usage) by the plant", "MW", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HOURLY_ENERGY, "W_net_kW", "Hourly Energy", "kW", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_PAR_TOT, "W_par_tot", "Total electrical parasitic consumption by all plant subsystems", "MW", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_FUEL_USAGE, "Fuel_usage", "Total fossil fuel usage by all plant subsystems", "MMBTU", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_FP_TOT, "Q_fp_tot", "Total freeze protection thermal energy requirement", "MW", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

@value
struct sam_mw_csp_SumCalcs(tcstypeinterface):
	var eta_lhv: Float64		#Fossil fuel lower heating value - Thermal power generated per unit fuel
	var eta_tes_htr: Float64		#Thermal storage tank heater efficiency (fp_mode=1 only)
	var fp_mode: Float64		#Freeze protection mode (1=Electrical heating ; 2=Fossil heating)
	var W_cycle_gross: Float64		#Electrical source - Power cycle gross output
	var W_par_heatrej: Float64		#Electrical parasitic - power cycle heat rejection system
	var W_par_sf_pump: Float64		#Electrical parasitic - solar field HTF pumping power
	var W_par_tes_pump: Float64		#Electrical parasitic - TES dispatch pumping power
	var W_par_BOP: Float64		#Electrical parasitic - Balance of plant equipment - variable with generation
	var W_par_fixed: Float64		#Electrical parasitic - Constant parasitic for plant operations
	var W_par_tracking: Float64		#Electrical parasitic - Power required for solar field collector drive operation
	var W_par_aux_boiler: Float64		#Electrical parasitic - Electrical power required to operate auxiliary fossil system
	var Q_par_tes_fp: Float64		#Modal parasitic - Thermal energy used for freeze protection in TES
	var Q_par_sf_fp: Float64		#Modal parasitic - Thermal energy used for freeze protection in the receiver/solar field
	var Q_aux_backup: Float64		#Thermal source - Thermal power provided by the auxiliary fossil backup system for generation
	var W_net: Float64		#Net electricity generation (or usage) by the plant
	var W_par_tot: Float64		#Total electrical parasitic consumption by all plant subsystems
	var Fuel_usage: Float64		#Total fossil fuel usage by all plant subsystems
	var Q_fp_tot: Float64		#Total freeze protection thermal energy requirement

	def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cxt, ti)
		self.eta_lhv = nan()
		self.eta_tes_htr = nan()
		self.fp_mode = nan()
		self.W_cycle_gross = nan()
		self.W_par_heatrej = nan()
		self.W_par_sf_pump = nan()
		self.W_par_tes_pump = nan()
		self.W_par_BOP = nan()
		self.W_par_fixed = nan()
		self.W_par_tracking = nan()
		self.W_par_aux_boiler = nan()
		self.Q_par_tes_fp = nan()
		self.Q_par_sf_fp = nan()
		self.Q_aux_backup = nan()
		self.W_net = nan()
		self.W_par_tot = nan()
		self.Fuel_usage = nan()
		self.Q_fp_tot = nan()

	def __del__(owned self):

	def init(inout self) -> Int:
		"""
		--Initialization call-- 
		Do any setup required here.
		Get the values of the inputs and parameters
		"""
		self.eta_lhv = self.value(P_ETA_LHV)		#Fossil fuel lower heating value - Thermal power generated per unit fuel [MW/MMBTU]
		self.eta_tes_htr = self.value(P_ETA_TES_HTR)		#Thermal storage tank heater efficiency (fp_mode=1 only) [none]
		self.fp_mode = self.value(P_FP_MODE)		#Freeze protection mode (1=Electrical heating ; 2=Fossil heating) [none]
		return 0

	def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
		"""
		E_net = [5,1] - ([4,29]+[4,28]+[4,27]+[4,17]+[3,18]+[4,26]+[3,5]+[5,8]+[3,6])  
		5 :: Power block
		1 | P_cycle			| MW
		8 | W_cool_par		| MW
		4 :: Controller
		17 | (q_tank_hot_htr + q_tank_cold_htr)/eta_heater_tank | MWe
		26 | htf_pump_power | MW
		27 | BOP_par		| MW
		28 | W_pb_design*PB_fixed_par/1.e6	| MW
		29 | Aux_par		| MW
		3 :: Solar field
		5  | W_dot_pump/1000.	| MW
		6  | E_fp_tot*1.e-6		| MW
		18 | SCA_par_tot/1.e6	| MW
		"""
		self.W_cycle_gross = self.value(I_W_CYCLE_GROSS)		#Electrical source - Power cycle gross output [MW]
		self.W_par_heatrej = self.value(I_W_PAR_HEATREJ)		#Electrical parasitic - power cycle heat rejection system [MW]
		self.W_par_sf_pump = self.value(I_W_PAR_SF_PUMP)		#Electrical parasitic - solar field HTF pumping power [MW]
		self.W_par_tes_pump = self.value(I_W_PAR_TES_PUMP)		#Electrical parasitic - TES dispatch pumping power [MW]
		self.W_par_BOP = self.value(I_W_PAR_BOP)		#Electrical parasitic - Balance of plant equipment - variable with generation [MW]
		self.W_par_fixed = self.value(I_W_PAR_FIXED)		#Electrical parasitic - Constant parasitic for plant operations [MW]
		self.W_par_tracking = self.value(I_W_PAR_TRACKING)		#Electrical parasitic - Power required for solar field collector drive operation [MW]
		self.W_par_aux_boiler = self.value(I_W_PAR_AUX_BOILER)		#Electrical parasitic - Electrical power required to operate auxiliary fossil system [MW]
		self.Q_par_tes_fp = self.value(I_Q_PAR_TES_FP)		#Modal parasitic - Thermal energy used for freeze protection in TES [MW]
		self.Q_par_sf_fp = self.value(I_Q_PAR_SF_FP)		#Modal parasitic - Thermal energy used for freeze protection in the receiver/solar field [MW]
		self.Q_aux_backup = self.value(I_Q_AUX_BACKUP)		#Thermal source - Thermal power provided by the auxiliary fossil backup system for generation [MW]
		self.W_par_tot = self.W_par_heatrej + self.W_par_sf_pump + self.W_par_tes_pump + self.W_par_BOP + self.W_par_fixed + self.W_par_tracking + self.W_par_aux_boiler
		self.Q_fp_tot = self.Q_par_tes_fp + self.Q_par_sf_fp
		self.Fuel_usage = self.Q_aux_backup
		if self.fp_mode == 1:	#Electric heat tracing
			self.W_par_tot += self.Q_par_tes_fp/self.eta_tes_htr + self.Q_par_sf_fp
		else:
			self.Fuel_usage += self.Q_par_tes_fp + self.Q_par_sf_fp
		self.Fuel_usage *= 3.41214116*step/3600./self.eta_lhv	#Convert from thermal power [MW] to fuel usage [MMBTU]. 1 MWhr = 3.412.. [MMBTU]
		self.W_net = self.W_cycle_gross - self.W_par_tot
		self.value(O_W_NET, self.W_net)		            #[MW] Net electricity generation (or usage) by the plant
		self.value(O_HOURLY_ENERGY, self.W_net*1000)		#[kW] Net electricity generation (or usage) by the plant
		self.value(O_W_PAR_TOT, self.W_par_tot)		    #[MW] Total electrical parasitic consumption by all plant subsystems
		self.value(O_FUEL_USAGE, self.Fuel_usage)		#[MMBTU] Total fossil fuel usage by all plant subsystems
		self.value(O_Q_FP_TOT, self.Q_fp_tot)		    #[MW] Total freeze protection thermal energy requirement
		return 0

	def converged(inout self, time: Float64) -> Int:
		return 0

TCS_IMPLEMENT_TYPE(sam_mw_csp_SumCalcs, "Net electricity calculator for the Physical Trough", "Mike Wagner", 1, sam_mw_csp_SumCalcs_variables, None, 1)