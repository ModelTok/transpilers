# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided 
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import *
from csp_system_costs import *
from csp_solver_util import *
from math import nan as NaN

var _cm_vtab_cb_construction_financing: Pointer[var_info] = Pointer[var_info](
    var_info(SSC_INPUT,  SSC_NUMBER,   "total_installed_cost",                "Total installed cost",                        "$",    "",     "system costs",           "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_interest_rate1",            "Interest rate, loan 1",                       "%",    "",     "financial parameters",   "*",   "",  "" ),   
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_interest_rate2",            "Interest rate, loan 2",                       "%",    "",     "financial parameters",   "*",   "",  "" ),   
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_interest_rate3",            "Interest rate, loan 3",                       "%",    "",     "financial parameters",   "*",   "",  "" ),   
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_interest_rate4",            "Interest rate, loan 4",                       "%",    "",     "financial parameters",   "*",   "",  "" ),   
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_interest_rate5",            "Interest rate, loan 5",                       "%",    "",     "financial parameters",   "*",   "",  "" ),   
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_months1",                   "Months prior to operation, loan 1",           "",     "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_months2",                   "Months prior to operation, loan 2",           "",     "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_months3",                   "Months prior to operation, loan 3",           "",     "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_months4",                   "Months prior to operation, loan 4",           "",     "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_months5",                   "Months prior to operation, loan 5",           "",     "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_percent1",                  "Percent of tot. installed cost, loan 1",      "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_percent2",                  "Percent of tot. installed cost, loan 2",      "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_percent3",                  "Percent of tot. installed cost, loan 3",      "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_percent4",                  "Percent of tot. installed cost, loan 4",      "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_percent5",                  "Percent of tot. installed cost, loan 5",      "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_upfront_rate1",             "Upfront fee on principal, loan 1",            "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_upfront_rate2",             "Upfront fee on principal, loan 2",            "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_upfront_rate3",             "Upfront fee on principal, loan 3",            "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_upfront_rate4",             "Upfront fee on principal, loan 4",            "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_INPUT,  SSC_NUMBER,   "const_per_upfront_rate5",             "Upfront fee on principal, loan 5",            "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal1",                "Principal, loan 1",                           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal2",                "Principal, loan 2",                           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal3",                "Principal, loan 3",                           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal4",                "Principal, loan 4",                           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal5",                "Principal, loan 5",                           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest1",                 "Interest cost, loan 1",                       "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest2",                 "Interest cost, loan 2",                       "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest3",                 "Interest cost, loan 3",                       "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest4",                 "Interest cost, loan 4",                       "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest5",                 "Interest cost, loan 5",                       "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_total1",                    "Total financing cost, loan 1",                "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_total2",                    "Total financing cost, loan 2",                "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_total3",                    "Total financing cost, loan 3",                "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_total4",                    "Total financing cost, loan 4",                "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_total5",                    "Total financing cost, loan 5",                "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_percent_total",	           "Total percent of installed costs, all loans", "%",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_principal_total",           "Total principal, all loans",				  "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "const_per_interest_total",	           "Total interest costs, all loans",			  "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info(SSC_OUTPUT, SSC_NUMBER,   "construction_financing_cost",         "Total construction financing cost",           "$",    "",     "financial parameters",   "*",   "",  "" ),
    var_info_invalid()
)

@value
struct cm_cb_construction_financing(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_cb_construction_financing)

    def exec(inout self) raises:
        var total_installed_cost: ssc_number_t     = self.as_number("total_installed_cost")    
        var const_per_interest_rate1: ssc_number_t = self.as_number("const_per_interest_rate1")
        var const_per_interest_rate2: ssc_number_t = self.as_number("const_per_interest_rate2")
        var const_per_interest_rate3: ssc_number_t = self.as_number("const_per_interest_rate3")
        var const_per_interest_rate4: ssc_number_t = self.as_number("const_per_interest_rate4")
        var const_per_interest_rate5: ssc_number_t = self.as_number("const_per_interest_rate5")
        var const_per_months1: ssc_number_t        = self.as_number("const_per_months1")
        var const_per_months2: ssc_number_t        = self.as_number("const_per_months2")       
        var const_per_months3: ssc_number_t        = self.as_number("const_per_months3")       
        var const_per_months4: ssc_number_t        = self.as_number("const_per_months4")       
        var const_per_months5: ssc_number_t        = self.as_number("const_per_months5")       
        var const_per_percent1: ssc_number_t       = self.as_number("const_per_percent1")      
        var const_per_percent2: ssc_number_t       = self.as_number("const_per_percent2")      
        var const_per_percent3: ssc_number_t       = self.as_number("const_per_percent3")      
        var const_per_percent4: ssc_number_t       = self.as_number("const_per_percent4")      
        var const_per_percent5: ssc_number_t       = self.as_number("const_per_percent5")      
        var const_per_upfront_rate1: ssc_number_t  = self.as_number("const_per_upfront_rate1") 
        var const_per_upfront_rate2: ssc_number_t  = self.as_number("const_per_upfront_rate2") 
        var const_per_upfront_rate3: ssc_number_t  = self.as_number("const_per_upfront_rate3") 
        var const_per_upfront_rate4: ssc_number_t  = self.as_number("const_per_upfront_rate4") 
        var const_per_upfront_rate5: ssc_number_t  = self.as_number("const_per_upfront_rate5") 
        var const_per_principal1: Float64
        var const_per_principal2: Float64
        var const_per_principal3: Float64
        var const_per_principal4: Float64
        var const_per_principal5: Float64
        var const_per_interest1: Float64
        var const_per_interest2: Float64
        var const_per_interest3: Float64
        var const_per_interest4: Float64
        var const_per_interest5: Float64
        var const_per_total1: Float64
        var const_per_total2: Float64
        var const_per_total3: Float64
        var const_per_total4: Float64
        var const_per_total5: Float64
        var const_per_percent_total: Float64
        var const_per_principal_total: Float64
        var const_per_interest_total: Float64
        var construction_financing_cost: Float64

        const_per_principal1 = NaN
        const_per_principal2 = NaN
        const_per_principal3 = NaN
        const_per_principal4 = NaN
        const_per_principal5 = NaN
        const_per_interest1 = NaN
        const_per_interest2 = NaN
        const_per_interest3 = NaN
        const_per_interest4 = NaN
        const_per_interest5 = NaN
        const_per_total1 = NaN
        const_per_total2 = NaN
        const_per_total3 = NaN
        const_per_total4 = NaN
        const_per_total5 = NaN
        const_per_percent_total = NaN
        const_per_principal_total = NaN
        const_per_interest_total = NaN
        construction_financing_cost = NaN

        N_financial_parameters.construction_financing_total_cost(
            total_installed_cost,
            const_per_interest_rate1, const_per_interest_rate2, const_per_interest_rate3, const_per_interest_rate4, const_per_interest_rate5,
            const_per_months1, const_per_months2, const_per_months3, const_per_months4, const_per_months5,
            const_per_percent1, const_per_percent2, const_per_percent3, const_per_percent4, const_per_percent5,
            const_per_upfront_rate1, const_per_upfront_rate2, const_per_upfront_rate3, const_per_upfront_rate4, const_per_upfront_rate5,
            const_per_principal1, const_per_principal2, const_per_principal3, const_per_principal4, const_per_principal5,
            const_per_interest1, const_per_interest2, const_per_interest3, const_per_interest4, const_per_interest5,
            const_per_total1, const_per_total2, const_per_total3, const_per_total4, const_per_total5,
            const_per_percent_total, const_per_principal_total, const_per_interest_total, construction_financing_cost)

        self.assign("const_per_principal1",        ssc_number_t(const_per_principal1))         
        self.assign("const_per_principal2",        ssc_number_t(const_per_principal2))      
        self.assign("const_per_principal3",        ssc_number_t(const_per_principal3))      
        self.assign("const_per_principal4",        ssc_number_t(const_per_principal4))      
        self.assign("const_per_principal5",        ssc_number_t(const_per_principal5))      
        self.assign("const_per_interest1",         ssc_number_t(const_per_interest1))       
        self.assign("const_per_interest2",         ssc_number_t(const_per_interest2))       
        self.assign("const_per_interest3",         ssc_number_t(const_per_interest3))       
        self.assign("const_per_interest4",         ssc_number_t(const_per_interest4))       
        self.assign("const_per_interest5",         ssc_number_t(const_per_interest5))       
        self.assign("const_per_total1",            ssc_number_t(const_per_total1))          
        self.assign("const_per_total2",            ssc_number_t(const_per_total2))          
        self.assign("const_per_total3",            ssc_number_t(const_per_total3))          
        self.assign("const_per_total4",            ssc_number_t(const_per_total4))          
        self.assign("const_per_total5",            ssc_number_t(const_per_total5))          
        self.assign("const_per_percent_total",	   ssc_number_t(const_per_percent_total))	 
        self.assign("const_per_principal_total",   ssc_number_t(const_per_principal_total)) 
        self.assign("const_per_interest_total",	   ssc_number_t(const_per_interest_total))	 
        self.assign("construction_financing_cost", ssc_number_t(construction_financing_cost))

        # /* Useful for lk script:
        # outln("const_per_principal1 = ",      var("const_per_principal1")           )  
        # outln("const_per_principal2 = ",      var("const_per_principal2")      		)
        # outln("const_per_principal3 = ",      var("const_per_principal3")			)
        # outln("const_per_principal4 = ",      var("const_per_principal4")			)
        # outln("const_per_principal5 = ",      var("const_per_principal5")			)
        # outln("const_per_interest1 = ",       var("const_per_interest1")			)
        # outln("const_per_interest2 = ",       var("const_per_interest2")			)
        # outln("const_per_interest3 = ",       var("const_per_interest3")			)
        # outln("const_per_interest4 = ",       var("const_per_interest4")			)
        # outln("const_per_interest5 = ",       var("const_per_interest5")			)
        # outln("const_per_total1 = ",          var("const_per_total1")				)
        # outln("const_per_total2 = ",          var("const_per_total2")				)
        # outln("const_per_total3 = ",          var("const_per_total3")				)
        # outln("const_per_total4 = ",          var("const_per_total4")				)
        # outln("const_per_total5 = ",          var("const_per_total5")				)
        # outln("const_per_percent_total = ",	  var("const_per_percent_total")		)
        # outln("const_per_principal_total = ",   var("const_per_principal_total")	)
        # outln("const_per_interest_total = ",	var("const_per_interest_total")		)
        # outln("construction_financing_cost = ", var("construction_financing_cost")	)
        # */

DEFINE_MODULE_ENTRY(cb_construction_financing, "Construction financing cost calculations", 0)