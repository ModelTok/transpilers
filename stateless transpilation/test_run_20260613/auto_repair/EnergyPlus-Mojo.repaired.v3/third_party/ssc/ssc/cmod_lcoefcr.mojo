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
from core import *
from lib_financial import *
var vtab_lcoefcr: StaticArray[VarInfo, 7] = StaticArray[VarInfo, 7](
	VarInfo(SSC_INPUT, SSC_NUMBER, "capital_cost", "Capital cost", "$", "", "Simple LCOE", "*", "", ""),
	VarInfo(SSC_INPUT, SSC_NUMBER, "fixed_operating_cost", "Annual fixed operating cost", "$", "", "Simple LCOE", "*", "", ""),
	VarInfo(SSC_INPUT, SSC_NUMBER, "variable_operating_cost", "Annual variable operating cost", "$/kWh", "", "Simple LCOE", "*", "", ""),
	VarInfo(SSC_INPUT, SSC_NUMBER, "fixed_charge_rate", "Fixed charge rate", "", "", "Simple LCOE", "*", "", ""),
	VarInfo(SSC_INPUT, SSC_NUMBER, "annual_energy", "Annual energy production", "kWh", "", "Simple LCOE", "*", "", ""),
	VarInfo(SSC_OUTPUT, SSC_NUMBER, "lcoe_fcr", "Levelized cost of energy", "$/kWh", "", "Simple LCOE", "*", "", ""),
	var_info_invalid
)
class cm_lcoefcr(compute_module):
	private:
	public:
	def __init__(inout self):
		self.add_var_info(vtab_lcoefcr)
	def exec(inout self):
		var aep: Float64 = 1.0
		var fcr: Float64 = 0.0
		var icc: Float64 = 0.0
		var voc: Float64 = 0.0
		var foc: Float64 = 0.0
		aep = self.as_double("annual_energy")
		foc = self.as_double("fixed_operating_cost")
		voc = self.as_double("variable_operating_cost")
		fcr = self.as_double("fixed_charge_rate")
		icc = self.as_double("capital_cost")
		var lcoe: Float64 = (fcr*icc + foc) / aep + voc
		self.assign("lcoe_fcr", var_data(ssc_number_t(lcoe)))
DEFINE_MODULE_ENTRY(lcoefcr, "Calculate levelized cost of energy using fixed charge rate method.", 1)