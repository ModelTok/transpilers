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
from 6par_jacobian import *
from 6par_lu import *
from 6par_search import *
from 6par_newton import *
from 6par_gamma import *
from 6par_solve import *

var _cm_vtab_6parsolve: StaticArray[var_info, 17] = [
/*   VARTYPE           DATATYPE         NAME                           LABEL                                UNITS     META                      GROUP                      REQUIRED_IF                 CONSTRAINTS                      UI_HINTS*/
	var_info(SSC_INPUT,         SSC_STRING,      "celltype",               "Cell technology type",           "monoSi,multiSi/polySi,cis,cigs,cdte,amorphous","","Six Parameter Solver",      "*",        "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Vmp",                    "Maximum power point voltage",    "V",       "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Imp",                    "Maximum power point current",    "A",       "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Voc",                    "Open circuit voltage",           "V",       "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Isc",                    "Short circuit current",          "A",       "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "alpha_isc",              "Temp coeff of current at SC",    "A/'C",    "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "beta_voc",               "Temp coeff of voltage at OC",    "V/'C",    "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "gamma_pmp",              "Temp coeff of power at MP",      "%/'C",    "",                      "Six Parameter Solver",      "*",                       "",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Nser",                   "Number of cells in series",      "",        "",                      "Six Parameter Solver",      "*",                       "INTEGER,POSITIVE",      "" ),
	var_info(SSC_INPUT,         SSC_NUMBER,      "Tref",                   "Reference cell temperature",     "'C",      "",                      "Six Parameter Solver",      "?",                       "",      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "a",                      "Modified nonideality factor",    "1/V",    "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "Il",                     "Light current",                  "A",      "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "Io",                     "Saturation current",             "A",      "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "Rs",                     "Series resistance",              "ohm",    "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "Rsh",                    "Shunt resistance",               "ohm",    "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info(SSC_OUTPUT,        SSC_NUMBER,      "Adj",                    "OC SC temp coeff adjustment",    "%",      "",                      "Six Parameter Solver",      "*",                        "",                      "" ),
	var_info_invalid
]

class cm_6parsolve(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_6parsolve)

    def exec(self):
        var tech_id: Int = module6par.monoSi
        var stype: String = self.as_string("celltype")
        if stype.find("mono") != -1:
            tech_id = module6par.monoSi
        elif stype.find("multi") != -1 or stype.find("poly") != -1:
            tech_id = module6par.multiSi
        elif stype.find("cis") != -1:
            tech_id = module6par.CIS
        elif stype.find("cigs") != -1:
            tech_id = module6par.CIGS
        elif stype.find("cdte") != -1:
            tech_id = module6par.CdTe
        elif stype.find("amor") != -1:
            tech_id = module6par.Amorphous
        else:
            raise general_error("could not determine cell type (mono,multi,cis,cigs,cdte,amorphous)")
        var Vmp: Float64 = self.as_double("Vmp")
        var Imp: Float64 = self.as_double("Imp")
        var Voc: Float64 = self.as_double("Voc")
        var Isc: Float64 = self.as_double("Isc")
        var bVoc: Float64 = self.as_double("beta_voc")
        var aIsc: Float64 = self.as_double("alpha_isc")
        var gPmp: Float64 = self.as_double("gamma_pmp")
        var nser: Int = self.as_integer("Nser")
        var Tref: Float64 = 25.0
        if self.is_assigned("Tref"):
            Tref = self.as_double("Tref")
        var m: module6par = module6par(tech_id, Vmp, Imp, Voc, Isc, bVoc, aIsc, gPmp, nser, Tref + 273.15)
        var err: Int = m.solve_with_sanity_and_heuristics[Float64](300, 1e-7)
        if err < 0:
            raise general_error("could not solve, check inputs")
        self.assign("a", var_data(ssc_number_t(m.a)))
        self.assign("Il", var_data(ssc_number_t(m.Il)))
        self.assign("Io", var_data(ssc_number_t(m.Io)))
        self.assign("Rs", var_data(ssc_number_t(m.Rs)))
        self.assign("Rsh", var_data(ssc_number_t(m.Rsh)))
        self.assign("Adj", var_data(ssc_number_t(m.Adj)))

DEFINE_MODULE_ENTRY(6parsolve, "Solver for CEC/6 parameter PV module coefficients", 1)