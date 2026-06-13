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
const M_PI: Float64 = 3.141592653589793238462643
from core import *
from lib_cec6par import *
from lib_irradproc import *

var _cm_vtab_pv6parmod: StaticArray[var_info, 33] = StaticArray[var_info, 33](
/*   VARTYPE           DATATYPE         NAME                         LABEL                              UNITS     META                      GROUP          REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_beam",                   "Incident direct normal radiation","W/m2",  "",                      "Weather",      "*",                       "",                        "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_skydiff",                "Incident sky diffuse radiation",  "W/m2",  "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "poa_gnddiff",                "Incident ground diffuse irradiance","W/m2","",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "tdry",                       "Dry bulb temperature",           "'C",     "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "wspd",                       "Wind speed",                     "m/s",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "wdir",                       "Wind direction",                 "deg",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "sun_zen",                    "Sun zenith angle",               "deg",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "incidence",                  "Incidence angle to surface",     "deg",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "surf_tilt",                  "Surface tilt angle",             "deg",    "",                      "Weather",      "*",                       "LENGTH_EQUAL=poa_beam",                    "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "elev",                       "Site elevation",                 "m",      "",                    "Weather",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_ARRAY,       "opvoltage",               "Module operating voltage",       "Volt",    "",                     "CEC 6 Parameter PV Module Model",      "?"                        "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "area",                    "Module area",                    "m2",      "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Vmp",                     "Maximum power point voltage",    "V",       "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Imp",                     "Maximum power point current",    "A",       "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Voc",                     "Open circuit voltage",           "V",       "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Isc",                     "Short circuit current",          "A",       "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "alpha_isc",               "Temp coeff of current at SC",    "A/'C",    "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "beta_voc",                "Temp coeff of voltage at OC",    "V/'C",    "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "gamma_pmp",               "Temp coeff of power at MP",      "%/'C",    "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "tnoct",                   "NOCT cell temperature",          "'C",      "",                     "CEC 6 Parameter PV Module Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "a",                       "Modified nonideality factor",    "1/V",    "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Il",                      "Light current",                  "A",      "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Io",                      "Saturation current",             "A",      "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rs",                      "Series resistance",              "ohm",    "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rsh",                     "Shunt resistance",               "ohm",    "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Adj",                     "OC SC temp coeff adjustment",    "%",      "",                      "CEC 6 Parameter PV Module Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "standoff",                "Mounting standoff option",       "0..6",   "0=bipv, 1= >3.5in, 2=2.5-3.5in, 3=1.5-2.5in, 4=0.5-1.5in, 5= <0.5in, 6=ground/rack",   "CEC 6 Parameter PV Module Model",      "?=6",     "INTEGER,MIN=0,MAX=6",     "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "height",                  "System installation height",     "0/1",    "0=less than 22ft, 1=more than 22ft",                                                   "CEC 6 Parameter PV Module Model",      "?=0",     "INTEGER,MIN=0,MAX=1",     "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "tcell",                      "Cell temperature",               "'C",     "",                   "CEC 6 Parameter PV Module Model",      "*",                       "LENGTH_EQUAL=poa_beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc_voltage",                 "DC module voltage",              "Volt",   "",                   "CEC 6 Parameter PV Module Model",      "*",                       "LENGTH_EQUAL=poa_beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc_current",                 "DC module current",              "Ampere", "",                   "CEC 6 Parameter PV Module Model",      "*",                       "LENGTH_EQUAL=poa_beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "eff",                        "Conversion efficiency",          "0..1",   "",                   "CEC 6 Parameter PV Module Model",      "*",                       "LENGTH_EQUAL=poa_beam",                          "" ),
	var_info(SSC_OUTPUT,       SSC_ARRAY,       "dc",                         "DC power output",                "Watt",   "",                   "CEC 6 Parameter PV Module Model",      "*",                       "LENGTH_EQUAL=poa_beam",                          "" ),
	var_info_invalid()
)

class cm_pv6parmod(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_pv6parmod)

    def exec(inout self):
        var arr_len: Int
        var p_poabeam: Pointer[ssc_number_t] = as_array("poa_beam", &arr_len)
        var p_poaskydiff: Pointer[ssc_number_t] = as_array("poa_skydiff", &arr_len)
        var p_poagnddiff: Pointer[ssc_number_t] = as_array("poa_gnddiff", &arr_len)
        var p_tdry: Pointer[ssc_number_t] = as_array("tdry", &arr_len)
        var p_wspd: Pointer[ssc_number_t] = as_array("wspd", &arr_len)
        var p_wdir: Pointer[ssc_number_t] = as_array("wdir", &arr_len)
        var p_inc: Pointer[ssc_number_t] = as_array("incidence", &arr_len)
        var p_zen: Pointer[ssc_number_t] = as_array("sun_zen", &arr_len)
        var p_stilt: Pointer[ssc_number_t] = as_array("surf_tilt", &arr_len)
        var site_elevation: Float64 = as_double("elev")
        var mod: cec6par_module_t
        mod.Area = as_double("area")
        mod.Vmp = as_double("Vmp")
        mod.Imp = as_double("Imp")
        mod.Voc = as_double("Voc")
        mod.Isc = as_double("Isc")
        mod.alpha_isc = as_double("alpha_isc")
        mod.beta_voc = as_double("beta_voc")
        mod.a = as_double("a")
        mod.Il = as_double("Il")
        mod.Io = as_double("Io")
        mod.Rs = as_double("Rs")
        mod.Rsh = as_double("Rsh")
        mod.Adj = as_double("Adj")
        var tc: noct_celltemp_t
        tc.Tnoct = as_double("tnoct")
        var standoff: Int = as_integer("standoff")
        tc.standoff_tnoct_adj = 0
        #source for standoff adjustment constants: https://prod-ng.sandia.gov/techlib-noauth/access-control.cgi/1985/850330.pdf page 12
        if standoff == 2:
            tc.standoff_tnoct_adj = 2 # between 2.5 and 3.5 inches
        elif standoff == 3:
            tc.standoff_tnoct_adj = 6 # between 1.5 and 2.5 inches
        elif standoff == 4:
            tc.standoff_tnoct_adj = 11 # between 0.5 and 1.5 inches
        elif standoff == 5:
            tc.standoff_tnoct_adj = 18 # less than 0.5 inches
        var height: Int = as_integer("height")
        tc.ffv_wind = 0.51
        if height == 1:
            tc.ffv_wind = 0.61
        var opvoltage: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        if is_assigned("opvoltage"):
            var opvlen: Int = 0
            opvoltage = as_array("opvoltage", &opvlen)
            if opvlen != arr_len:
                throw general_error("operating voltage array must be same length as input vectors")
        var p_tcell: Pointer[ssc_number_t] = allocate("tcell", arr_len)
        var p_volt: Pointer[ssc_number_t] = allocate("dc_voltage", arr_len)
        var p_amp: Pointer[ssc_number_t] = allocate("dc_current", arr_len)
        var p_eff: Pointer[ssc_number_t] = allocate("eff", arr_len)
        var p_dc: Pointer[ssc_number_t] = allocate("dc", arr_len)
        for i in range(arr_len):
            var in_: pvinput_t
            in_.Ibeam = Float64(p_poabeam[i])
            in_.Idiff = Float64(p_poaskydiff[i])
            in_.Ignd = Float64(p_poagnddiff[i])
            in_.Tdry = Float64(p_tdry[i])
            in_.Wspd = Float64(p_wspd[i])
            in_.Wdir = Float64(p_wdir[i])
            in_.Zenith = Float64(p_zen[i])
            in_.IncAng = Float64(p_inc[i])
            in_.Elev = site_elevation
            in_.Tilt = Float64(p_stilt[i])
            var out_: pvoutput_t
            var opv: Float64 = -1.0 # by default, calculate MPPT
            if opvoltage:
                opv = Float64(opvoltage[i])
            var tcell: Float64 = in_.Tdry
            if not tc(in_, mod, opv, tcell):
                throw general_error("error calculating cell temperature", Float32(i))
            if not mod(in_, tcell, opv, out_):
                throw general_error("error calculating module power and temperature with given parameters", Float32(i))
            p_tcell[i] = ssc_number_t(out_.CellTemp)
            p_volt[i] = ssc_number_t(out_.Voltage)
            p_amp[i] = ssc_number_t(out_.Current)
            p_eff[i] = ssc_number_t(out_.Efficiency)
            p_dc[i] = ssc_number_t(out_.Power)

DEFINE_MODULE_ENTRY(pv6parmod, "CEC 6 Parameter PV module model performance calculator.  Does not include weather file reading or irradiance processing, or inverter (DC to AC) modeling.", 1)