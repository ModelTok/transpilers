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
// #define _TCSTYPEINTERFACE_
from tcstype import tcscontext, tcstypeinfo, tcsvarinfo, TCS_INPUT, TCS_NUMBER, TCS_OUTPUT, TCS_INVALID, tcstypeinterface, TCS_IMPLEMENT_TYPE
alias I_T1 = 0
alias I_T2 = 1
alias I_TDIFF = 2
alias I_MDOTSET = 3
alias O_MDOT = 4
alias O_CTRL = 5
alias O_ENTHALPY = 6
alias N_MAX = 7
var pump_variables: List[tcsvarinfo] = List[tcsvarinfo](
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T1, "t1", "Test temperature 1", "'C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T2, "t2", "Test temperature 2", "'C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_TDIFF, "tdiff", "Difference setpoint (ON if T2-T1 > Tdiff)", "'C", "", "", ""),
	tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_MDOTSET, "mdotset", "Design flow rate", "L/s", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_MDOT, "mdot", "Flow rate", "L/s", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_CTRL, "ctrl", "Control signal (1/0)", "0/1", "", "", ""),
	tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ENTHALPY, "enthalpy", "Enthalpy", "kJ/kg", "", "", ""),
	tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, None, None, None, None, None, None)
)
from water_properties import water_state, water_PS
struct pump(tcstypeinterface):
	def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
		tcstypeinterface.__init__(self, cxt, ti)
	def __del__(owned self):

	def init(inout self) -> Int:
		return 0
	def call(inout self, time: Float64 /*time*/, step: Float64 /*step*/, ncall: Int /*ncall*/) -> Int:
		if value(I_T2) - value(I_T1) > value(I_TDIFF):
			value(O_CTRL, 1)
			value(O_MDOT, value(I_MDOTSET))
		else:
			value(O_CTRL, 0.0)
			value(O_MDOT, 0.0)
		var wp: water_state
		water_PS(600, 5.5, &wp)
		value(O_ENTHALPY, wp.enth)
		return 0
TCS_IMPLEMENT_TYPE(pump, "Basic pump unit", "Aron Dobos", 1, pump_variables, None, 0)