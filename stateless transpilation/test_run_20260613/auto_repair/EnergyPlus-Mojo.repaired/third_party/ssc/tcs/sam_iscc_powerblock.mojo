// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from ngcc_powerblock import ngcc_power_cycle
from tcstype import tcstypeinterface, tcscontext, tcstypeinfo, TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_MATRIX, TCS_INVALID, TCS_ERROR, TCS_NOTICE
from htf_props import HTFProperties
from sam_csp_util import util
from water_properties import water_state, water_TP, water_PQ

# Define the enum for indices
enum Index:
    P_HTF = 0
    P_USER_HTF_PROPS = 1
    P_Q_SF_DES = 2
    P_PLANT_ELEVATION = 3
    P_CYCLE_CONFIG = 4
    P_HOT_SIDE_DELTA_T = 5
    P_PINCH_POINT = 6
    I_T_AMB = 7
    I_P_AMB = 8
    I_M_DOT_MS = 9
    I_Q_DOT_REC_SS = 10
    I_T_REC_IN = 11
    I_T_REC_OUT = 12
    O_T_HTF_COLD = 13
    O_T_HTF_HOT = 14
    O_W_DOT_PC_FOSSIL = 15
    O_W_DOT_PC_HYBRID = 16
    O_T_ST_COLD = 17
    O_T_ST_HOT = 18
    O_P_ST_COLD = 19
    O_P_ST_HOT = 20
    O_ETA_SOLAR_PC = 21
    O_Q_DOT_MAX = 22
    O_FUEL_USE = 23
    O_Q_DOT_FUEL = 24
    O_M_DOT_STEAM = 25
    N_MAX = 26

# Define tcsvarinfo struct
struct tcsvarinfo:
    var type: Int
    var datatype: Int
    var index: Int
    var name: String
    var label: String
    var units: String
    var group: String
    var meta: String
    var meta2: String

# Global variable array
var sam_iscc_powerblock_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_HTF,             "HTF_code",          "HTF fluid code",	                                    "-",     "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, Index.P_USER_HTF_PROPS,  "field_fl_props",    "User defined field fluid property data",               "-",     "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows",        "",        ""),			
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_Q_SF_DES,        "Q_sf_des",          "Design point solar field thermal output",              "MW",    "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_PLANT_ELEVATION, "plant_elevation",   "Plant Elevation",                                      "m",     "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_CYCLE_CONFIG,    "cycle_config",      "Cycle configuration code, 1 = HP evap injection",      "-",     "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_HOT_SIDE_DELTA_T,"hot_side_delta_t",  "Hot side temperature HX temperature difference",       "C",     "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, Index.P_PINCH_POINT,     "pinch_point",       "Cold side HX pinch point",                             "C",     "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_T_AMB,           "T_amb",             "Ambient temperature",                                  "C",     "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_P_AMB,           "P_amb",             "Ambient pressure",                                     "mbar",  "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_M_DOT_MS,        "m_dot_ms_ss",       "Molten salt mass flow rate from rec. - no startup derate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_Q_DOT_REC_SS,    "q_dot_rec_ss",      "Receiver thermal output - no startup derate",          "MWt",   "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_T_REC_IN,        "T_rec_in",          "Receiver inlet temperature",                           "C",     "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, Index.I_T_REC_OUT,       "T_rec_out",         "Receiver outlet temperature",                          "C",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_T_HTF_COLD,    "T_htf_cold",       "Outlet molten salt temp - inlet rec. temp",           "C",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_T_HTF_HOT,     "T_htf_hot",        "Inlet molten salt temp - outlet rec. temp",           "C",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_W_DOT_PC_FOSSIL,"W_dot_pc_fossil", "POWER CYCLE output - no solar thermal input",         "MWe",   "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_W_DOT_PC_HYBRID,"W_dot_pc_hybrid", "POWER CYCLE output at timestep with solar",           "MWe",   "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_T_ST_COLD,     "T_st_cold",        "Steam extraction temp TO molten salt HX",             "C",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_T_ST_HOT,      "T_st_hot",         "Steam injection temp TO ngcc",                        "C",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_P_ST_COLD,     "P_st_cold",        "Steam extraction pressure TO molten salt HX",         "bar",   "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_P_ST_HOT,      "P_st_hot",         "Steam extraction pressure TO ngcc",                   "bar",   "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_ETA_SOLAR_PC,  "eta_solar_pc",     "Solar use efficiency - no solar parasitics",          "-",     "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_Q_DOT_MAX,     "Q_dot_max",        "Maximum allowable thermal power to power cycle",      "MWt",   "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_FUEL_USE,      "fuel_use",         "Total fossil fuel used during timestep",              "MMBTU", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_Q_DOT_FUEL,    "q_dot_fuel",       "Fuel thermal power into gas turbines",                "kW",    "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, Index.O_M_DOT_STEAM,   "m_dot_steam",      "Solar steam mass flow rate",                          "kg/hr", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, Index.N_MAX,			0,					0, 0, 0, 0, 0)
)

class sam_iscc_powerblock(tcstypeinterface):
    var wp: water_state
    var htfProps: HTFProperties
    var cycle_calcs: ngcc_power_cycle
    var m_q_sf_des: Float64
    var m_T_amb_des: Float64
    var m_P_amb_des: Float64
    var m_m_dot_st_des: Float64
    var m_m_dot_ms_des: Float64
    var m_UA_econo_des: Float64
    var m_UA_sh_des: Float64
    var m_UA_evap_des: Float64
    var m_T_approach: Float64
    var m_cp_ms: Float64
    var m_T_ms_sh_in_des: Float64
    var m_T_ms_econo_out_des: Float64
    var m_P_st_extract: Float64
    var m_P_st_inject: Float64
    var m_T_st_extract: Float64
    var m_T_st_inject: Float64
    var m_W_dot_pc_fossil: Float64
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var m_P_amb_low: Float64
    var m_P_amb_high: Float64
    var m_q_dot_rec_max: Float64
    var m_plant_fuel_mass: Float64
    var m_q_dot_fuel: Float64
    var m_T_lowflag_ncall: Bool
    var m_T_upflag_ncall: Bool
    var m_T_low_ncall: Float64
    var m_T_up_ncall: Float64

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cst, ti)
        self.m_q_sf_des = float64.nan
        self.m_T_amb_des = float64.nan
        self.m_P_amb_des = float64.nan
        self.m_m_dot_st_des = float64.nan
        self.m_m_dot_ms_des = float64.nan
        self.m_UA_econo_des = float64.nan
        self.m_UA_sh_des = float64.nan
        self.m_UA_evap_des = float64.nan
        self.m_T_approach = float64.nan
        self.m_cp_ms = float64.nan
        self.m_T_ms_sh_in_des = float64.nan
        self.m_T_ms_econo_out_des = float64.nan
        self.m_P_st_extract = float64.nan
        self.m_P_st_inject = float64.nan
        self.m_T_st_extract = float64.nan
        self.m_T_st_inject = float64.nan
        self.m_W_dot_pc_fossil = float64.nan
        self.m_T_amb_low = float64.nan
        self.m_T_amb_high = float64.nan
        self.m_P_amb_low = float64.nan
        self.m_P_amb_high = float64.nan
        self.m_T_lowflag_ncall = False
        self.m_T_upflag_ncall = False
        self.m_T_low_ncall = float64.nan
        self.m_T_up_ncall = float64.nan
        self.m_q_dot_rec_max = float64.nan
        self.m_plant_fuel_mass = float64.nan
        self.m_q_dot_fuel = float64.nan

    def __del__(owned self):

    def init(inout self) -> Int:
        var field_fl: Int = Int(self.value(Index.P_HTF))
        if field_fl != HTFProperties.User_defined:
            if not self.htfProps.SetFluid(field_fl):
                self.message(TCS_ERROR, "Receiver HTF code is not recognized")
                return -1
        elif field_fl == HTFProperties.User_defined:
            var nrows: Int = 0
            var ncols: Int = 0
            var htf_mat: Pointer[Float64] = self.value(Index.P_USER_HTF_PROPS, nrows, ncols)
            if htf_mat != None and nrows > 2 and ncols == 7:
                var mat: util.matrix_t[Float64] = util.matrix_t[Float64]()
                mat.assign(htf_mat, nrows, ncols)
                if not self.htfProps.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, self.htfProps.UserFluidErrMessage(), nrows, ncols)
                    return -1
            else:
                self.message(TCS_ERROR, "The htf properties matrix must have more than 2 rows and exactly 7 columns - the input matrix has %d rows and %d columns", nrows, ncols)
                return -1
        else:
            self.message(TCS_ERROR, "Receiver HTF code is not recognized")
            return -1

        var cycle_config: Int = Int(self.value(Index.P_CYCLE_CONFIG))
        self.cycle_calcs.set_cycle_config(cycle_config)
        self.cycle_calcs.get_table_range(self.m_T_amb_low, self.m_T_amb_high, self.m_P_amb_low, self.m_P_amb_high)
        self.m_q_sf_des = self.value(Index.P_Q_SF_DES)		# [MWt]
        self.m_T_amb_des = 20.0						# [C]
        self.m_P_amb_des = 101325.0 * pow(1 - 2.25577E-5 * self.value(Index.P_PLANT_ELEVATION), 5.25588) / 1.E5	# [bar] http://www.engineeringtoolbox.com/air-altitude-pressure-d_462.html						
        if self.m_P_amb_des < self.m_P_amb_low:
            self.message(TCS_ERROR, "The design ambient pressure, %lg, [bar] is lower than the lowest value of ambient pressure, %lg [bar] in the cycle performance lookup table.", self.m_P_amb_des, self.m_P_amb_low)
            return -1
        if self.m_P_amb_des > self.m_P_amb_high:
            self.message(TCS_ERROR, "The design ambient pressure, %lg, [bar] is greater than the largest value of ambient pressure, %lg [bar] in the cycle performance lookup table.", self.m_P_amb_des, self.m_P_amb_high)
            return -1

        var q_dot_sf_max: Float64 = self.cycle_calcs.get_ngcc_data(0.0, self.m_T_amb_des, self.m_P_amb_des, ngcc_power_cycle.E_solar_heat_max)				# [MWt]
        if self.m_q_sf_des > q_dot_sf_max:
            self.message(TCS_ERROR, "The design solar thermal input, %lg MWt, is greater than the ngcc can accept, %lg MWt at the design ambient pressure, %lg bar, and designt ambient temperature"
                    "20 C. The HTF-steam HX was sized using the maximum solar thermal input.", self.m_q_sf_des, q_dot_sf_max, self.m_P_amb_des)
            self.m_q_sf_des = q_dot_sf_max

        var P_st_extract: Float64 = self.cycle_calcs.get_ngcc_data(self.m_q_sf_des, self.m_T_amb_des, self.m_P_amb_des, ngcc_power_cycle.E_solar_extraction_p) * 100.0	# [kPa] convert from [bar]
        var P_st_inject: Float64 = self.cycle_calcs.get_ngcc_data(self.m_q_sf_des, self.m_T_amb_des, self.m_P_amb_des, ngcc_power_cycle.E_solar_injection_p) * 100.0	# [kPa] convert from [bar]
        var T_st_extract: Float64 = self.cycle_calcs.get_ngcc_data(self.m_q_sf_des, self.m_T_amb_des, self.m_P_amb_des, ngcc_power_cycle.E_solar_extraction_t)		# [C]
        var T_st_inject: Float64 = self.cycle_calcs.get_ngcc_data(self.m_q_sf_des, self.m_T_amb_des, self.m_P_amb_des, ngcc_power_cycle.E_solar_injection_t)			# [C]

        water_TP(T_st_extract + 273.15, P_st_extract, self.wp)
        var h_st_extract: Float64 = self.wp.enth			# [kJ/kg]
        water_TP(T_st_inject + 273.15, P_st_inject, self.wp)
        var h_st_inject: Float64 = self.wp.enth			# [kJ/kg]

        self.m_m_dot_st_des = self.m_q_sf_des * 1000.0 / (h_st_inject - h_st_extract)
        self.m_P_st_extract = P_st_extract
        self.m_P_st_inject = P_st_inject
        self.m_T_st_extract = T_st_extract
        self.m_T_st_inject = T_st_inject

        water_PQ(P_st_extract, 0.0, self.wp)					# Steam props at design pressure and quality = 0
        var h_x0: Float64 = self.wp.enth									# [kJ/kg] Steam enthalpy at evaporator inlet
        var cp_x0: Float64 = self.wp.cp								# [kJ/kg-K] Thermal capacitance at evap inlet
        water_PQ(P_st_extract, 1.0, self.wp)					# Steam props at design pressure and quality = 1
        var T_sat: Float64 = self.wp.temp - 273.15								# [C] Saturation temperature
        var h_x1: Float64 = self.wp.enth									# [kJ/kg] Steam enthalpy at evaporator exit
        var cp_x1: Float64 = self.wp.cp								# [kJ/kg-K] Thermal capacitance at evap outlet
        water_TP(T_st_inject + 273.15, P_st_inject, self.wp)			# Steam props at superheater exit
        var h_sh_out: Float64 = self.wp.enth								# [kJ/kg] Steam enthalpy at sh exit
        var cp_sh_out: Float64 = self.wp.cp							# [kJ/kg-k] Thermal capacitance at sh exit
        water_TP(T_st_extract + 273.15, P_st_extract, self.wp)		# Steam props at economizer inlet
        var h_econo_in: Float64 = self.wp.enth							# [kJ/kg] Steam enthalpy at econo inlet
        var cp_econo_in: Float64 = self.wp.cp							# [kJ/kg-K] Thermal capacitance at econo inlet

        var q_dot_econo: Float64 = self.m_m_dot_st_des * (h_x0 - h_econo_in)				# [kW] design point duty of economizer
        var cp_st_econo: Float64 = (cp_x0 + cp_econo_in) / 2.0							# [kJ/kg-K] Average thermal capacitance of steam in economizer
        var q_dot_evap: Float64 = self.m_m_dot_st_des * (h_x1 - h_x0)					# [kW] design point duty of evaporator
        var q_dot_sh_des: Float64 = self.m_m_dot_st_des * (h_sh_out - h_x1)					# [kW] design point duty of superheater
        var cp_st_sh: Float64 = (cp_sh_out + cp_x1) / 2.0									# [kJ/kg-K] Average thermal capacitance of steam in superheater
        var q_dot_evap_and_sh: Float64 = q_dot_evap + q_dot_sh_des	# [kW] 
        var T_pinch_point: Float64 = self.value(Index.P_PINCH_POINT)			# [C] Get pinch point at design in evaporator
        var T_ms_evap_out: Float64 = T_sat + T_pinch_point			# [C] Molten Salt evaporator outlet temperature
        self.m_T_approach = self.value(Index.P_HOT_SIDE_DELTA_T)				# [C] Get molten salt approach temperature to superheater
        var T_ms_sh_in: Float64 = T_st_inject + self.m_T_approach			# [C] Molten salt superheater inlet temperature = receiver outlet temperature + approach temperature
        self.m_cp_ms = self.htfProps.Cp((T_ms_evap_out + T_ms_sh_in) / 2.0)				# [kJ/kg-K] Specific heat of molten salt
        self.m_m_dot_ms_des = q_dot_evap_and_sh / (self.m_cp_ms * (T_ms_sh_in - T_ms_evap_out))	# [kg/s] Mass flow rate of molten salt
        var T_ms_econo_out: Float64 = T_ms_evap_out - q_dot_econo / (self.m_m_dot_ms_des * self.m_cp_ms)		# [C] Temperature of molten salt at outlet of economizer
        var T_ms_evap_in: Float64 = q_dot_evap / (self.m_m_dot_ms_des * self.m_cp_ms) + T_ms_evap_out			# [C] Temperature of molten salt inlet of evaporator
        var C_dot_ms: Float64 = self.m_m_dot_ms_des * self.m_cp_ms											# [kW/K] Capacitance rate of molten salt in economizer
        var C_dot_st: Float64 = self.m_m_dot_st_des * cp_st_econo								# [kW/K] Capacitance rate of steam in economizer
        var C_dot_min: Float64 = min(C_dot_ms, C_dot_st)								# [kJ/kg-K] Minimum capacitance rate of economizer
        var C_dot_max: Float64 = max(C_dot_ms, C_dot_st)								# [kJ/kg-K] Maximum capacitance rate of economizer
        var q_dot_max: Float64 = C_dot_min * (T_ms_evap_out - T_st_extract)			# [kW] Maximum possible heat transfer in economizer
        var epsilon_econo: Float64 = q_dot_econo / q_dot_max								# [-] Effectiveness of economizer
        var CR: Float64 = C_dot_min / C_dot_max											# [-] Capacitance ratio of econo.
        var NTU: Float64 = log((epsilon_econo - 1.0) / (epsilon_econo * CR - 1.0)) / (CR - 1.0)	# [-] NTU
        self.m_UA_econo_des = NTU * C_dot_min											# [kW/K] Conductance

        var C_dot_st_sh_des: Float64 = self.m_m_dot_st_des * cp_st_sh										# [kW/K] Capacitance rate of steam in superheater
        var C_dot_min_sh_des: Float64 = min(C_dot_ms, C_dot_st_sh_des)										# [kJ/kg-K] Minimum capacitance rate of superheater
        var C_dot_max_sh_des: Float64 = max(C_dot_ms, C_dot_st_sh_des)										# [kJ/kg-K] Maximum capacitance rate of superheater
        var q_dot_max_sh_des: Float64 = C_dot_min_sh_des * (T_ms_sh_in - T_sat)							# [kW] Maximum possible heat transfer in superheater
        var epsilon_sh_des: Float64 = q_dot_sh_des / q_dot_max_sh_des										# [-] Effectiveness of superheater
        var CR_sh_des: Float64 = C_dot_min_sh_des / C_dot_max_sh_des													# [-] Capacitance ratio of superheater
        var NTU_sh_des: Float64 = log((epsilon_sh_des - 1.0) / (epsilon_sh_des * CR_sh_des - 1.0)) / (CR_sh_des - 1.0)			# [-] NTU
        self.m_UA_sh_des = NTU_sh_des * C_dot_min_sh_des										# [kW/K] Conductance of superheater

        C_dot_min = C_dot_ms														# [kJ/kg-K] Minimum capacitance rate of evap
        q_dot_max = C_dot_min * (T_ms_evap_in - T_sat)							# [kW] Max possible heat transfer in evap
        var epsilon_evap: Float64 = q_dot_evap / q_dot_max									# [-] Effectiveness of evaporator
        NTU = -log(1 - epsilon_evap)												# [-] NTU
        self.m_UA_evap_des = NTU * C_dot_min											# [kW/K] Conductance of evaporator

        self.m_T_ms_sh_in_des = T_ms_sh_in
        self.m_T_ms_econo_out_des = T_ms_econo_out

        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var T_amb: Float64 = self.value(Index.I_T_AMB)					# [C] Ambient temperature
        var P_amb: Float64 = self.value(Index.I_P_AMB) / 1000.0				# [bar] Ambient pressure, convert from [mbar]
        var q_dot_rec: Float64 = self.value(Index.I_Q_DOT_REC_SS) * 1000.0		# [kWt] Receiver thermal output, convert from [MWt]
        var T_rec_in_prev: Float64 = self.value(Index.I_T_REC_IN)			# [C] Receiver inlet molten salt temperature - used to solve previous call to tower model
        var T_rec_out: Float64 = self.value(Index.I_T_REC_OUT)		    # [C] Receiver outlet molten salt temperature - used to solve previous call to tower model

        if P_amb < self.m_P_amb_low or P_amb > self.m_P_amb_high:
            self.message(TCS_NOTICE, "The design ambient pressure, %lg, is outside of the bounds"
                    "for ambient pressure (%lg, %lg) [bar] in the cycle performance lookup table and has been set to the appropriate bound"
                    "for this timestep", self.m_P_amb_des, self.m_P_amb_low, self.m_P_amb_high)
            P_amb = max(self.m_P_amb_low, min(self.m_P_amb_high, P_amb))

        if ncall == 0:
            self.m_W_dot_pc_fossil = self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_plant_power_net)
            self.value(Index.O_W_DOT_PC_FOSSIL, self.m_W_dot_pc_fossil)
            self.m_q_dot_rec_max = self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_solar_heat_max) * 1000.0	# [kWt] Convert from MWt
            self.value(Index.O_Q_DOT_MAX, self.m_q_dot_rec_max / 1.E3)
            var m_dot: Float64 = self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_plant_fuel_mass)				# [kg/s] Fuel mass flow rate
            self.m_plant_fuel_mass = m_dot * 0.045556 * step	# [MMBTU] Fuel use over time period (LHV = 48065 kJ/kg per IPSEpro model)
            self.m_q_dot_fuel = m_dot * 48065				# [kW] Fuel thermal power into system
            self.value(Index.O_FUEL_USE, self.m_plant_fuel_mass)
            self.value(Index.O_Q_DOT_FUEL, self.m_q_dot_fuel)

        if q_dot_rec == 0:
            self.value(Index.O_T_HTF_COLD, T_rec_in_prev)
            self.value(Index.O_T_HTF_HOT, T_rec_out)
            self.value(Index.O_W_DOT_PC_HYBRID, self.m_W_dot_pc_fossil)
            self.value(Index.O_T_ST_COLD, self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_solar_extraction_t))
            self.value(Index.O_T_ST_HOT, self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_solar_injection_t))
            self.value(Index.O_P_ST_COLD, self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_solar_extraction_p))
            self.value(Index.O_P_ST_HOT, self.cycle_calcs.get_ngcc_data(0.0, T_amb, P_amb, ngcc_power_cycle.E_solar_injection_p))
            self.value(Index.O_ETA_SOLAR_PC, 0.0)
            self.value(Index.O_M_DOT_STEAM)
            return 0
        elif q_dot_rec > self.m_q_dot_rec_max:
            self.message(TCS_NOTICE, "Solar thermal input from the receiver, %lg MWt, is greater than the allowable maximum, %lg MWt", q_dot_rec / 1.E3, self.m_q_dot_rec_max / 1.E3)
            q_dot_rec = self.m_q_dot_rec_max

        var P_st_extract: Float64 = self.cycle_calcs.get_ngcc_data(q_dot_rec / 1000.0, T_amb, P_amb, ngcc_power_cycle.E_solar_extraction_p) * 100.0	# [kPa] convert from [bar]
        var P_st_inject: Float64 = self.cycle_calcs.get_ngcc_data(q_dot_rec / 1000.0, T_amb, P_amb, ngcc_power_cycle.E_solar_injection_p) * 100.0		# [kPa] convert from [bar]
        var T_st_extract: Float64 = self.cycle_calcs.get_ngcc_data(q_dot_rec / 1000.0, T_amb, P_amb, ngcc_power_cycle.E_solar_extraction_t)			# [C]
        var T_st_inject: Float64 = self.cycle_calcs.get_ngcc_data(q_dot_rec / 1000.0, T_amb, P_amb, ngcc_power_cycle.E_solar_injection_t)			# [C]

        water_TP(T_st_extract + 273.15, P_st_extract, self.wp)
        var h_st_extract: Float64 = self.wp.enth			# [kJ/kg]
        water_TP(T_st_inject + 273.15, P_st_inject, self.wp)
        var h_st_inject: Float64 = self.wp.enth			# [kJ/kg]

        var m_dot_st: Float64 = q_dot_rec / (h_st_inject - h_st_extract)

        var P_st_evap_in: Float64 = P_st_extract				# [kPa] Inlet pressure to evaporator
        var P_st_sh_in: Float64 = P_st_extract				# [kPa] Inlet pressure to superheater	

        water_TP(T_st_inject + 273.15, P_st_inject, self.wp)		# Water props at sh outlet
        var h_st_sh_out: Float64 = self.wp.enth						# [kJ/kg] Enthalpy at superheater outlet
        var cp_st_sh_out: Float64 = self.wp.cp					# [kJ/kg-K] Specific heat at superheater outlet
        water_PQ(P_st_sh_in, 1.0, self.wp)				# Water props at sh inlet
        var h_st_sh_in: Float64 = self.wp.enth						# [kJ/kg] Enthalpy at superheater inlet
        var cp_st_sh_in: Float64 = self.wp.cp						# [kJ/kg-K] Specific heat at superheater inlet
        var T_st_sh_in: Float64 = self.wp.temp - 273.15						# [C] Temperature at superheater inlet
        var cp_st_sh: Float64 = (cp_st_sh_in + cp_st_sh_out) / 2.0	# [kJ/kg-K] Average specific heat in superheater
        var C_dot_st_sh: Float64 = cp_st_sh * m_dot_st			# [kW/K] Capacitance rate of steam in superheater
        var q_dot_sh: Float64 = m_dot_st * (h_st_sh_out - h_st_sh_in)			# [kW] Superheater heater duty

        water_PQ(P_st_evap_in, 0.0, self.wp)				# Water props at evap inlet
        var h_st_econo_out: Float64 = self.wp.enth					# [kJ/kg] Enthalpy at evaporator inlet
        var cp_st_econo_out: Float64 = self.wp.cp					# [kJ/kg-K]
        water_TP(T_st_extract + 273.15, P_st_extract, self.wp)	# Water props at econo inlet
        var h_st_econo_in: Float64 = self.wp.enth					# [kJ/kg]
        var cp_st_econo_in: Float64 = self.wp.cp					# [kJ/kg-K]
        var cp_st_econo: Float64 = (cp_st_econo_in + cp_st_econo_out) / 2.0	# [kJ/kg-K]
        var C_dot_st_econo: Float64 = cp_st_econo * m_dot_st				# [kW/K]
        var q_dot_econo: Float64 = m_dot_st * (h_st_econo_out - h_st_econo_in)	# [kW]
        var q_dot_evap: Float64 = m_dot_st * (h_st_sh_in - h_st_econo_out)		# [kW] Evaporator duty

        var T_ms_out_guess: Float64 = T_st_sh_in
        var T_lower: Float64 = T_st_extract				# [C]
        var T_upflag: Bool = True
        var T_upper: Float64 = T_st_inject				# [C]
        var UAdiff_T_lowflag: Bool = False
        var UAdiff_T_lower: Float64 = float64.nan	# [C]
        var UAdiff_T_upflag: Bool = False
        var UAdiff_T_upper: Float64 = float64.nan	# [C]
        var pinch_point_break: Bool = False
        var iter_UA: Int = 0
        var diff_UA: Float64 = -999.9	# [-]

        while abs(diff_UA) > 0.0001 and iter_UA < 50:
            iter_UA += 1
            if iter_UA > 1:
                if UAdiff_T_lowflag and UAdiff_T_upflag:
                    if diff_UA > 0.0:
                        T_lower = T_ms_out_guess
                        UAdiff_T_lower = diff_UA
                    else:
                        T_upper = T_ms_out_guess
                        UAdiff_T_upper = diff_UA
                    T_ms_out_guess = UAdiff_T_upper / (UAdiff_T_upper - UAdiff_T_lower) * (T_lower - T_upper) + T_upper		# [C] False position method
                elif pinch_point_break:
                    pinch_point_break = False
                    T_lower = T_ms_out_guess
                    T_ms_out_guess = 0.5 * T_lower + 0.5 * T_upper		# [C] Biscetion method
                else:
                    if diff_UA > 0.0:					# Not enough UA for temperature difference -> increase inlet temperature
                        T_lower = T_ms_out_guess
                        UAdiff_T_lower = diff_UA
                        UAdiff_T_lowflag = True
                    else:								# Too much UA for temperature difference -> decrease inlet temperature
                        T_upper = T_ms_out_guess
                        T_upflag = True
                        UAdiff_T_upper = diff_UA
                        UAdiff_T_upflag = True
                    if UAdiff_T_lowflag and UAdiff_T_upflag:
                        T_ms_out_guess = UAdiff_T_upper / (UAdiff_T_upper - UAdiff_T_lower) * (T_lower - T_upper) + T_upper		# [C] False position method
                    else:
                        T_ms_out_guess = 0.5 * T_lower + 0.5 * T_upper		# [C] Biscetion method

            var m_dot_ms: Float64 = q_dot_rec / ((T_rec_out - T_ms_out_guess) * self.m_cp_ms)
            var UA_mult: Float64 = ((pow(m_dot_ms, 0.8) * pow(m_dot_st, 0.8)) / (pow(self.m_m_dot_ms_des, 0.8) * pow(self.m_m_dot_st_des, 0.8))) * ((pow(self.m_m_dot_ms_des, 0.8) + pow(self.m_m_dot_st_des, 0.8)) / (pow(m_dot_ms, 0.8) + pow(m_dot_st, 0.8)))
            var UA_econo_phys: Float64 = self.m_UA_econo_des * UA_mult
            var UA_evap_phys: Float64 = self.m_UA_evap_des * UA_mult
            var UA_sh_phys: Float64 = self.m_UA_sh_des * UA_mult
            var UA_total_phys: Float64 = UA_econo_phys + UA_evap_phys + UA_sh_phys

            var C_dot_ms: Float64 = m_dot_ms * self.m_cp_ms							# [kW/K] Capacitance rate of molten salt
            var C_dot_min_sh: Float64 = min(C_dot_ms, C_dot_st_sh)				# [kW/K] Minimum capacitance rate in superheater
            var C_dot_max_sh: Float64 = max(C_dot_ms, C_dot_st_sh)				# [kW/K] Maximum capacitance rate in superheater
            var CR_sh: Float64 = C_dot_min_sh / C_dot_max_sh						# [-] Capacitance ratio of superheater			
            var C_dot_min_econo: Float64 = min(C_dot_ms, C_dot_st_econo)		# [kW/K]
            var C_dot_max_econo: Float64 = max(C_dot_ms, C_dot_st_econo)		# [kW/K]
            var CR_econo: Float64 = C_dot_min_econo / C_dot_max_econo				# [-]											

            var T_ms_sh_out: Float64 = T_rec_out - q_dot_sh / (m_dot_ms * self.m_cp_ms)			# [C] Outlet temperature of superheater
            var q_dot_max_sh: Float64 = C_dot_min_sh * (T_rec_out - T_st_sh_in)			# [kW] Maximum possible heat transfer in superheater
            var epsilon_sh: Float64 = q_dot_sh / q_dot_max_sh								# [-] Superheater effectiveness
            var NTU_sh: Float64 = log((epsilon_sh - 1.0) / (epsilon_sh * CR_sh - 1.0)) / (CR_sh - 1.0)		# [-] NTU
            var UA_sh_guess: Float64 = NTU_sh * C_dot_min_sh								# [kW/K] Conductance of superheater

            var T_ms_evap_out: Float64 = T_ms_sh_out - q_dot_evap / (m_dot_ms * self.m_cp_ms)		# [C]
            if T_ms_evap_out < T_st_sh_in:
                T_lower = T_rec_out			# [C] Set lower limit on ms inlet temp
                UAdiff_T_lower = False				# [-] Don't have UA error for this
                pinch_point_break = True
                continue

            var q_dot_max_evap: Float64 = C_dot_ms * (T_ms_sh_out - T_st_sh_in)				# [kW] Maximum possible heat transfer in evap
            var epsilon_evap: Float64 = q_dot_evap / q_dot_max_evap							# [-] Effectiveness of evaporator
            var NTU_evap: Float64 = -log(1 - epsilon_evap)									# [-] NTU of evaporator
            var UA_evap_guess: Float64 = NTU_evap * C_dot_ms									# [kW/K] Conductance of evaporator

            var q_dot_max_econo: Float64 = C_dot_min_econo * (T_ms_evap_out - T_st_extract)	# [kW]
            var epsilon_econo: Float64 = q_dot_econo / q_dot_max_econo							# [-]
            var NTU_econo: Float64 = log((epsilon_econo - 1.0) / (epsilon_econo * CR_econo - 1.0)) / (CR_econo - 1.0)		# [-] NTU
            var UA_econo_guess: Float64 = NTU_econo * C_dot_min_econo						# [kW/K]																																	
            var UA_total_guess: Float64 = UA_sh_guess + UA_evap_guess + UA_econo_guess		# [kW/K]
            diff_UA = (UA_total_guess - UA_total_phys) / UA_total_phys			# [-]

        if T_ms_out_guess < T_rec_in_prev:
            self.m_T_upflag_ncall = True
            self.m_T_up_ncall = T_rec_in_prev
        else:
            self.m_T_lowflag_ncall = True
            self.m_T_low_ncall = T_rec_in_prev

        if ncall > 8 and self.m_T_upflag_ncall and self.m_T_lowflag_ncall:
            T_ms_out_guess = 0.5 * self.m_T_up_ncall + 0.5 * self.m_T_low_ncall

        self.value(Index.O_T_HTF_COLD, T_ms_out_guess)
        self.value(Index.O_T_HTF_HOT, T_rec_out)

        var W_dot_pc_hybrid: Float64 = self.cycle_calcs.get_ngcc_data(q_dot_rec / 1000.0, T_amb, P_amb, ngcc_power_cycle.E_plant_power_net)
        self.value(Index.O_W_DOT_PC_HYBRID, W_dot_pc_hybrid)
        self.value(Index.O_T_ST_COLD, T_st_extract)
        self.value(Index.O_T_ST_HOT, T_st_inject)
        self.value(Index.O_P_ST_COLD, P_st_extract)
        self.value(Index.O_P_ST_HOT, P_st_inject)
        self.value(Index.O_ETA_SOLAR_PC, (W_dot_pc_hybrid - self.m_W_dot_pc_fossil) / (q_dot_rec / 1000.0))
        self.value(Index.O_M_DOT_STEAM, m_dot_st * 3600.0)

        return 0

    def converged(inout self, time: Float64) -> Int:
        self.m_T_lowflag_ncall = False
        self.m_T_upflag_ncall = False
        return 0

# Macro replacement: TCS_IMPLEMENT_TYPE( sam_iscc_powerblock, "ISCC Powerblock ", "Ty Neises", 1, sam_iscc_powerblock_variables, NULL, 1 )
def TCS_IMPLEMENT_TYPE(cls: type, name: String, author: String, version: Int, variables: List[tcsvarinfo], extra1: None, extra2: Int):

TCS_IMPLEMENT_TYPE(sam_iscc_powerblock, "ISCC Powerblock ", "Ty Neises", 1, sam_iscc_powerblock_variables, None, 1)