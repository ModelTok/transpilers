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
from lib_cec6par import *
var _cm_vtab_singlediode: StaticArray[var_info, 10] = StaticArray[var_info, 10](
/*   VARTYPE           DATATYPE         NAME                         LABEL                              UNITS     META                      GROUP                  REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,        SSC_NUMBER,      "a",                       "Modified nonideality factor",    "1/V",    "",                      "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Il",                      "Light current",                  "A",      "",                      "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Io",                      "Saturation current",             "A",      "",                      "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rs",                      "Series resistance",              "ohm",    "",                      "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rsh",                     "Shunt resistance",               "ohm",    "",                      "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Vop",                     "Module operating voltage",       "V",      "",                      "Single Diode Model",      "?"                         "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "V",                       "Output voltage",                "V",      "",                      "Single Diode Model",       "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "I",                       "Output current",                "A",      "",                      "Single Diode Model",       "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Voc",                     "Open circuit voltage",          "V",      "",                      "Single Diode Model",       "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Isc",                     "Short circuit current",         "A",      "",                      "Single Diode Model",       "*",                        "",                      "" ),
	var_info_invalid )

class cm_singlediode(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_singlediode)

    def exec(inout self):
        var a: Float64 = self.as_double("a")
        var Il: Float64 = self.as_double("Il")
        var Io: Float64 = self.as_double("Io")
        var Rs: Float64 = self.as_double("Rs")
        var Rsh: Float64 = self.as_double("Rsh")
        var Vop: Float64 = -1.0
        if self.is_assigned("Vop"):
            Vop = self.as_double("Vop")
        var V: Float64
        var I: Float64
        if Vop < 0:
            maxpower_5par(100, a, Il, Io, Rs, Rsh, &V, &I)
        else:
            V = Vop
            I = current_5par(V, 0.9*Il, a, Il, Io, Rs, Rsh)
        self.assign("V", var_data(ssc_number_t(V)))
        self.assign("I", var_data(ssc_number_t(I)))
        var Voc: Float64 = openvoltage_5par(V, a, Il, Io, Rsh)
        var Isc: Float64 = current_5par(0.0, Il, a, Il, Io, Rs, Rsh)
        self.assign("Voc", var_data(ssc_number_t(Voc)))
        self.assign("Isc", var_data(ssc_number_t(Isc)))

DEFINE_MODULE_ENTRY(singlediode, "Single diode model function.", 1)

var _cm_vtab_singlediodeparams: StaticArray[var_info, 15] = StaticArray[var_info, 15](
	/*   VARTYPE           DATATYPE         NAME                         LABEL                              UNITS     META                      GROUP                  REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,        SSC_NUMBER,      "I",                       "Irradiance",                    "W/m2",      "",                    "Single Diode Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "T",                       "Temperature",                   "C",         "",                    "Single Diode Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "alpha_isc",               "Temp coeff of current at SC",    "A/'C",    "",                     "Single Diode Model",      "*",                       "",              "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Adj_ref",                 "OC SC temp coeff adjustment",    "%",       "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "a_ref",                   "Modified nonideality factor",    "1/V",     "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Il_ref",                  "Light current",                  "A",       "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Io_ref",                  "Saturation current",             "A",       "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rs_ref",                  "Series resistance",              "ohm",     "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_INPUT,        SSC_NUMBER,      "Rsh_ref",                 "Shunt resistance",               "ohm",     "",                     "Single Diode Model",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "a",                       "Modified nonideality factor",    "1/V",    "",                      "Single Diode Model",      "*",                        "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Il",                      "Light current",                  "A",      "",                      "Single Diode Model",      "*",                        "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Io",                      "Saturation current",             "A",      "",                      "Single Diode Model",      "*",                        "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Rs",                      "Series resistance",              "ohm",    "",                      "Single Diode Model",      "*",                        "",                              "" ),
	var_info(SSC_OUTPUT,       SSC_NUMBER,      "Rsh",                     "Shunt resistance",               "ohm",    "",                      "Single Diode Model",      "*",                        "",                              "" ),
	var_info_invalid )

class cm_singlediodeparams(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_singlediodeparams)

    def exec(inout self):
        alias I_ref: Float64 = 1000.0
        alias Tc_ref: Float64 = 298.15
        alias Eg_ref: Float64 = 1.12
        alias KB: Float64 = 8.618e-5
        var I: Float64 = self.as_double("I")
        var T: Float64 = self.as_double("T") + 273.15 # want cell temp in kelvin
        var alpha_isc: Float64 = self.as_double("alpha_isc")
        var Adj: Float64 = self.as_double("Adj_ref")
        var Il: Float64 = self.as_double("Il_ref")
        var Io: Float64 = self.as_double("Io_ref")
        var a: Float64 = self.as_double("a_ref")
        var Rs: Float64 = self.as_double("Rs_ref")
        var Rsh: Float64 = self.as_double("Rsh_ref")
        var muIsc: Float64 = alpha_isc * (1-Adj/100.0)
        var IL_oper: Float64 = I/I_ref *( Il + muIsc*(T-Tc_ref) )
        if IL_oper < 0.0:
            IL_oper = 0.0
        var EG: Float64 = Eg_ref * (1-0.0002677*(T-Tc_ref))
        var IO_oper: Float64 = Io * pow(T/Tc_ref, 3) * exp( 1/KB*(Eg_ref/Tc_ref - EG/T) )
        var A_oper: Float64 = a * T / Tc_ref
        var Rsh_oper: Float64 = Rsh*(I_ref/I)
        self.assign("Rs", var_data(ssc_number_t(Rs)))
        self.assign("Rsh", var_data(ssc_number_t(Rsh_oper)))
        self.assign("a", var_data(ssc_number_t(A_oper)))
        self.assign("Io", var_data(ssc_number_t(IO_oper)))
        self.assign("Il", var_data(ssc_number_t(IL_oper)))

DEFINE_MODULE_ENTRY(singlediodeparams, "Single diode model parameter calculation.", 1)