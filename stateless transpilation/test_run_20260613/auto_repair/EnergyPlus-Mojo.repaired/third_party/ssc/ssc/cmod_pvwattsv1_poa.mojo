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
from math import pi
from core import *
from lib_pvwatts import *
from lib_irradproc import transpoa

alias M_PI = 3.141592653589793238462643

var _cm_vtab_pvwatts: StaticArray[var_info, 17] = [
/*   VARTYPE           DATATYPE         NAME                         LABEL                              UNITS     META                      GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,        SSC_ARRAY,       "beam",				       "Direct normal radiation",         "W/m2",  "",                      "Weather",      "*",                       "",                                         "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_beam",                   "Incident direct normal radiation","W/m2",  "",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                        "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_skydiff",                "Incident sky diffuse radiation",  "W/m2",  "",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_gnddiff",                "Incident ground diffuse irradiance","W/m2","",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "tdry",                       "Dry bulb temperature",           "'C",     "",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "wspd",                       "Wind speed",                     "m/s",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "incidence",                  "Incidence angle to surface",     "deg",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=beam",                    "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "step",                       "Time step of input data",        "sec",    "",                       "PVWatts",     "?=3600",                       "POSITIVE",                    "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "system_size",                "Nameplate capacity",             "kW",     "",                      "PVWatts",      "*",                       "MIN=0.5,MAX=100000",                       "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "derate",                     "System derate value",            "frac",   "",                      "PVWatts",      "*",                       "MIN=0,MAX=1",                              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "inoct",                     "Nominal operating cell temperature", "'C", "",                      "PVWatts",      "?=45.0",                  "POSITIVE",                                 "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "t_ref",                      "Reference cell temperature",     "'C",     "",                      "PVWatts",      "?=25.0",                  "POSITIVE",                                 "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "gamma",                      "Max power temperature coefficient", "%/'C", "",                     "PVWatts",      "?=-0.5",                  "",                                         "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "inv_eff",                    "Inverter efficiency at rated power", "frac", "",                    "PVWatts",      "?=0.92",                  "MIN=0,MAX=1",                              "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "tcell",                      "Cell temperature",               "'C",     "",                      "PVWatts",      "*",                       "LENGTH_EQUAL=beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc",                         "DC array output",                "kWhdc",  "",                      "PVWatts",      "*",                       "LENGTH_EQUAL=beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "ac",                         "AC system output",               "kWhac",  "",                      "PVWatts",      "*",                       "LENGTH_EQUAL=beam",                          "" ),
	var_info_invalid
]

class cm_pvwattsv1_poa(compute_module):
	private:
	public:
	def __init__(inout self):
		self.add_var_info(_cm_vtab_pvwatts)

	def exec(inout self):
		var arr_len: size_t
		var p_beam = self.as_array("beam", &arr_len)
		var p_poabeam = self.as_array("poa_beam", &arr_len)
		var p_poaskydiff = self.as_array("poa_skydiff", &arr_len)
		var p_poagnddiff = self.as_array("poa_gnddiff", &arr_len)
		var p_tdry = self.as_array("tdry", &arr_len)
		var p_wspd = self.as_array("wspd", &arr_len)
		var p_inc = self.as_array("incidence", &arr_len)
		
		var watt_spec: Float64 = 1000.0 * self.as_double("system_size")
		var derate: Float64 = self.as_double("derate")
		var tstephr: Float64 = self.as_double("step") / 3600.0
		
		var p_tcell = self.allocate("tcell", arr_len)
		var p_dc = self.allocate("dc", arr_len)
		var p_ac = self.allocate("ac", arr_len)
		
		/* PV RELATED SPECIFICATIONS */
		var inoct: Float64 = self.as_double("inoct") + 273.15
		var reftem: Float64 = self.as_double("t_ref")
		var pwrdgr: Float64 = self.as_double("gamma") / 100.0
		var efffp: Float64 = self.as_double("inv_eff")
		var height: Float64 = PVWATTS_HEIGHT
		var tmloss: Float64 = 1.0 - derate / efffp
		
		var Tccalc = pvwatts_celltemp(inoct, height, tstephr)
		
		for i in range(arr_len):
			var poa: Float64 = p_poabeam[i] + p_poaskydiff[i] + p_poagnddiff[i]
			if poa > 0:
				var tpoa: Float64 = 0
				if p_beam[i] > 0:
					tpoa = transpoa(poa, p_beam[i], p_inc[i] * M_PI / 180.0, False)
				else:
					tpoa = poa
				var tcell: Float64 = Tccalc(poa, p_wspd[i], p_tdry[i])
				var dc: Float64 = dcpowr(reftem, watt_spec, pwrdgr, tmloss, tpoa, tcell, 1000.0)
				var ac: Float64 = dctoac(watt_spec, efffp, dc)
				p_tcell[i] = ssc_number_t(tcell)
				p_dc[i] = ssc_number_t(dc)
				p_ac[i] = ssc_number_t(ac)
			else:
				/* night time */
				p_tcell[i] = p_tdry[i]
				p_dc[i] = ssc_number_t(0.0)
				p_ac[i] = ssc_number_t(0.0)

DEFINE_MODULE_ENTRY(pvwattsv1_poa, "PVWatts system performance calculator.  Does not include weather file reading or irradiance processing - user must supply arrays of precalculated POA irradiance data.", 1)