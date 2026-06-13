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
from tcstype import tcsvarinfo, TCS_PARAM, TCS_ARRAY, TCS_OUTPUT, TCS_NUMBER, TCS_INVALID, TCS_ERROR, TCS_IMPLEMENT_TYPE, tcscontext, tcstypeinfo, value, message

enum Indexes: 
    P_I_B = 0
    P_T_DB = 1
    P_V_WIND = 2
    P_P_AMB = 3
    P_T_DP = 4
    P_T_COLD_IN = 5
    P_M_DOT_IN = 6
    O_I_B = 7
    O_T_DB = 8
    O_V_WIND = 9
    O_P_AMB = 10
    O_T_DP = 11
    O_T_COLD_IN = 12
    O_M_DOT_IN = 13
    N_MAX = 14

let sam_type250_input_generator_variables: List[tcsvarinfo] = List[tcsvarinfo](
    /* DIRECTION    DATATYPE      INDEX       NAME           LABEL                                  UNITS      GROUP    META    DEFAULTVALUE */
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_I_B,      "I_b",       "Direct normal incident solar irradiation",   "W/m^2",   "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_T_DB,     "T_db",      "Dry bulb temperature",                       "C",       "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_V_WIND,   "V_wind",    "Wind speed",                                 "m/s",     "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_P_AMB,    "P_amb",     "Ambient pressure",                           "mbar",    "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_T_DP,     "T_dp",      "Dew point temperature",                      "C",       "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_T_COLD_IN,"T_cold_in", "HTF inlet temperature",                      "C",       "",  "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_ARRAY,  Indexes.P_M_DOT_IN, "m_dot_in",  "HTF mass flow rate at inlet",                "kg/hr",   "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_I_B,      "O_I_b",       "Direct normal incident solar irradiation",   "W/m^2",   "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_T_DB,     "O_T_db",      "Dry bulb temperature",                       "C",       "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_V_WIND,   "O_V_wind",    "Wind speed",                                 "m/s",     "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_P_AMB,    "O_P_amb",     "Ambient pressure",                           "mbar",    "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_T_DP,     "O_T_dp",      "Dew point temperature",                      "C",       "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_T_COLD_IN,"O_T_cold_in", "HTF inlet temperature",                      "C",       "",  "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER,  Indexes.O_M_DOT_IN, "O_m_dot_in",  "HTF mass flow rate at inlet",                "kg/hr",   "",  "",  ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, Indexes.N_MAX, 0, 0, 0, 0, 0, 0)
)

struct sam_type250_input_generator:
    var I_b: List[Float64]
    var nval_I_b: Int
    var T_db: List[Float64]
    var nval_T_db: Int
    var V_wind: List[Float64]
    var nval_V_wind: Int
    var P_amb: List[Float64]
    var nval_P_amb: Int
    var T_dp: List[Float64]
    var nval_T_dp: Int
    var T_cold_in: List[Float64]
    var nval_T_cold_in: Int
    var m_dot_in: List[Float64]
    var nval_m_dot_in: Int
    var nval_current: Int

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        self.I_b = List[Float64]()
        self.nval_I_b = -1
        self.T_db = List[Float64]()
        self.nval_T_db = -1
        self.V_wind = List[Float64]()
        self.nval_V_wind = -1
        self.P_amb = List[Float64]()
        self.nval_P_amb = -1
        self.T_dp = List[Float64]()
        self.nval_T_dp = -1
        self.T_cold_in = List[Float64]()
        self.nval_T_cold_in = -1
        self.m_dot_in = List[Float64]()
        self.nval_m_dot_in = -1
        self.nval_current = 1

    def init(inout self) -> Int:
        # I_b = value(P_I_B, &nval_I_b);			//[W/m^2] DNI
        var result = value(Indexes.P_I_B).as_tuple()
        self.I_b = result.get[0]()
        self.nval_I_b = result.get[1]()
        # T_db = value(P_T_DB, &nval_T_db);		//[C] Dry bulb temperature
        result = value(Indexes.P_T_DB).as_tuple()
        self.T_db = result.get[0]()
        self.nval_T_db = result.get[1]()
        # V_wind = value(P_V_WIND, &nval_V_wind);	//[m/s] Wind speed
        result = value(Indexes.P_V_WIND).as_tuple()
        self.V_wind = result.get[0]()
        self.nval_V_wind = result.get[1]()
        # P_amb = value(P_P_AMB, &nval_P_amb);	//[mbar] Ambient pressure
        result = value(Indexes.P_P_AMB).as_tuple()
        self.P_amb = result.get[0]()
        self.nval_P_amb = result.get[1]()
        # T_dp = value(P_T_DP, &nval_T_dp);		//[C] Dew point temperature
        result = value(Indexes.P_T_DP).as_tuple()
        self.T_dp = result.get[0]()
        self.nval_T_dp = result.get[1]()
        # T_cold_in = value(P_T_COLD_IN, &nval_T_cold_in);	//[C] HTF inlet temperature
        result = value(Indexes.P_T_COLD_IN).as_tuple()
        self.T_cold_in = result.get[0]()
        self.nval_T_cold_in = result.get[1]()
        # m_dot_in = value(P_M_DOT_IN, &nval_m_dot_in);		//[kg/hr] HTF inlet mass flow rate
        result = value(Indexes.P_M_DOT_IN).as_tuple()
        self.m_dot_in = result.get[0]()
        self.nval_m_dot_in = result.get[1]()
        if( self.nval_I_b != self.nval_T_db or self.nval_T_db != self.nval_V_wind or self.nval_V_wind != self.nval_P_amb or self.nval_P_amb != self.nval_T_dp or self.nval_T_dp != self.nval_T_cold_in or self.nval_T_cold_in != self.nval_m_dot_in ):
            message(TCS_ERROR, "All parameters arrays must be the same length")
            return -1
        if( self.nval_I_b < 1 ):
            message(TCS_ERROR, "Parameter arrays must have at least 1 value")
            return -1
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        if( self.nval_current > self.nval_I_b ):
            message(TCS_ERROR, "The simulation is running simulation ", self.nval_current, ". The length of the parameter arrays is ", self.nval_I_b, ".")
            return -1
        value( Indexes.O_I_B, self.I_b[self.nval_current-1] )
        value( Indexes.O_T_DB, self.T_db[self.nval_current-1] )
        value( Indexes.O_V_WIND, self.V_wind[self.nval_current-1] )
        value( Indexes.O_P_AMB, self.P_amb[self.nval_current-1] )
        value( Indexes.O_T_DP, self.T_dp[self.nval_current-1] )
        value( Indexes.O_T_COLD_IN, self.T_cold_in[self.nval_current-1] )
        value( Indexes.O_M_DOT_IN, self.m_dot_in[self.nval_current-1] )
        return 0

    def converged(inout self, time: Float64) -> Int:
        self.nval_current += 1		 # Advanced index counter
        return 0

TCS_IMPLEMENT_TYPE(sam_type250_input_generator, "Input generator for Type250", "Ty Neises", 1, sam_type250_input_generator_variables, NULL, 1)