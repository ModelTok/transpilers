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

from tcstype import tcsvarinfo, tcstypeinterface, TCS_INPUT, TCS_NUMBER, TCS_OUTPUT, TCS_INVALID, TCS_IMPLEMENT_TYPE, tcscontext, tcstypeinfo

alias I_W_CYCLE_GROSS = 0
alias I_W_PAR_SF_TOT = 1
alias I_W_PAR_COOLING = 2
alias O_W_NET = 3
alias N_MAX = 4

var sam_mw_lf_type261_Wnet_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_CYCLE_GROSS, "W_cycle_gross",                                            "Electrical source - Power cycle gross output",           "MW",             "",             "",             ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_SF_TOT,           "W_par_sf_tot",                                             "Total solar field parasitics"                            "MW",             "",             "",             ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_W_PAR_COOLING,          "W_par_cooling",                                            "Parasitics from power cycle cooling",                    "MW",             "",             "",             ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_NET,                  "W_net",												    "Net electricity generation (or usage) by the plant",           "MW",             "",             "",             ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID,    N_MAX,                0,                    0,                                                        0,                0,        0,        0)
)

class sam_mw_lf_type261_Wnet(tcstypeinterface):
    def __init__(self, cxt: tcscontext, ti: tcstypeinfo):
        super().__init__(cxt, ti)
    
    def __del__(self):

    def init(self) -> Int:
        return 0
    
    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        var W_dot_pb_gross: Float64 = self.value(I_W_CYCLE_GROSS)
        var W_dot_sf_par: Float64 = self.value(I_W_PAR_SF_TOT)
        var W_dot_cooling_par: Float64 = self.value(I_W_PAR_COOLING)
        self.value(O_W_NET, W_dot_pb_gross - W_dot_sf_par - W_dot_cooling_par)
        return 0
    
    def converged(self, time: Float64) -> Int:
        return 0

TCS_IMPLEMENT_TYPE(sam_mw_lf_type261_Wnet, "Net electricity calculator for the Physical Trough", "Mike Wagner", 1, sam_mw_lf_type261_Wnet_variables, None, 1)