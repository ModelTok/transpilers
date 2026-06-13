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
from lib_financial import *
using libfin
from core import *
from string import String
from memory import UnsafePointer
from math import pow

var _cm_vtab_annualoutput: StaticArray[var_info, 12] = StaticArray(
/*   VARTYPE           DATATYPE         NAME                           LABEL                                    UNITS     META                                      GROUP                REQUIRED_IF                 CONSTRAINTS                     UI_HINTS*/
    var_info(SSC_INPUT, SSC_NUMBER,     "analysis_period",              "Analyis period",                        "years",  "",                                       "AnnualOutput",      "?=30",                   "INTEGER,MIN=0,MAX=50",           ""),
    var_info(SSC_INPUT, SSC_ARRAY,      "energy_availability",		   "Annual energy availability",	        "%",      "",                                       "AnnualOutput",      "*",						"",                              ""),
    var_info(SSC_INPUT, SSC_ARRAY,      "energy_degradation",		   "Annual energy degradation",	            "%",      "",                                       "AnnualOutput",      "*",						"",                              ""),
    var_info(SSC_INPUT, SSC_MATRIX,     "energy_curtailment",		   "First year energy curtailment",	         "",      "(0..1)",                                 "AnnualOutput",      "*",						"",                              ""),
    var_info(SSC_INPUT, SSC_NUMBER,     "system_use_lifetime_output",  "Lifetime hourly system outputs",        "0/1",    "0=hourly first year,1=hourly lifetime",  "AnnualOutput",      "*",						"INTEGER,MIN=0",                 ""),
    var_info(SSC_INPUT, SSC_ARRAY,		"system_hourly_energy",	       "Hourly energy produced by the system",  "kW",     "",                                       "AnnualOutput",      "*",						"",                              ""),
/* output */
    var_info(SSC_OUTPUT, SSC_ARRAY,     "annual_energy",               "Annual energy",                            "kWh",     "",                                      "AnnualOutput",      "*",                      "",                               ""),
    var_info(SSC_OUTPUT, SSC_ARRAY,     "monthly_energy",               "Monthly energy",                            "kWh",     "",                                      "AnnualOutput",      "*",                      "",                               ""),
    var_info(SSC_OUTPUT, SSC_ARRAY,     "hourly_energy",               "Hourly energy",                            "kWh",     "",                                      "AnnualOutput",      "*",                      "",                               ""),
    var_info(SSC_OUTPUT, SSC_ARRAY,     "annual_availability",               "Annual availability",                            "",     "",                                      "AnnualOutput",      "*",                      "",                               ""),
    var_info(SSC_OUTPUT, SSC_ARRAY,     "annual_degradation",               "Annual degradation",                            "",     "",                                      "AnnualOutput",      "*",                      "",                               ""),
    var_info_invalid()
)

alias vtab_standard_financial = Pointer[var_info]
alias vtab_oandm = Pointer[var_info]
alias vtab_tax_credits = Pointer[var_info]
alias vtab_payment_incentives = Pointer[var_info]

external var vtab_standard_financial: Pointer[var_info]
external var vtab_oandm: Pointer[var_info]
external var vtab_tax_credits: Pointer[var_info]
external var vtab_payment_incentives: Pointer[var_info]

enum CF_energy_net: Int32:
    CF_energy_net = 0

enum CF_availability: Int32:
    CF_availability = 1

enum CF_degradation: Int32:
    CF_degradation = 2

enum CF_max: Int32:
    CF_max = 3

class cm_annualoutput(compute_module):
    private:
        var cf: util.matrix_t[Float64]
    public:
        def __init__(inout self):
            self.cf = util.matrix_t[Float64]()
            self.add_var_info( UnsafePointer[var_info](_cm_vtab_annualoutput.data()) )

        def exec(inout self):
            var nyears: Int32 = self.as_integer("analysis_period")
            self.cf.resize_fill( CF_max, nyears + 1, 0.0 )
            var i: Int32 = 0
            var count_avail: Int = 0
            var avail: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
            avail = self.as_array("energy_availability", &count_avail)
            var count_degrad: Int = 0
            var degrad: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
            degrad = self.as_array("energy_degradation", &count_degrad)
            if count_degrad == 1:
                if self.as_integer("system_use_lifetime_output"):
                    if nyears >= 1: 
                        self.cf.at(CF_degradation, 1) = 1.0
                    for i in range(2, nyears + 1):
                        self.cf.at(CF_degradation, i) = 1.0 - degrad[0] / 100.0
                else:
                    for i in range(1, nyears + 1):
                        self.cf.at(CF_degradation, i) = pow((1.0 - degrad[0] / 100.0), i - 1)
            elif count_degrad > 0:
                for i in range(0, nyears):
                    if i < count_degrad:
                        self.cf.at(CF_degradation, i + 1) = (1.0 - degrad[i] / 100.0)
            if count_avail == 1:
                for i in range(1, nyears + 1):
                    self.cf.at(CF_availability, i) = avail[0] / 100.0
            elif count_avail > 0:
                for i in range(0, nyears):
                    if i < count_avail:
                        self.cf.at(CF_availability, i + 1) = avail[i] / 100.0
            if self.as_integer("system_use_lifetime_output"):
                self.compute_lifetime_output(nyears)
            else:
                self.compute_output(nyears)
            self.save_cf( CF_energy_net, nyears, "annual_energy" )
            self.save_cf( CF_availability, nyears, "annual_availability" )
            self.save_cf( CF_degradation, nyears, "annual_degradation" )

        def compute_output(inout self, nyears: Int32) -> Bool:
            var hourly_enet: Pointer[ssc_number_t]
            var count: Int
            hourly_enet = self.as_array("system_hourly_energy", &count)
            if count != 8760:
                var outm: String = String("Bad hourly energy output length (") + String(count) + String("), should be 8760.")
                self.log( outm )
                return False
            var monthly_energy_to_grid: Pointer[ssc_number_t] = self.allocate( "monthly_energy", 12 )
            var hourly_energy_to_grid: Pointer[ssc_number_t] = self.allocate( "hourly_energy", 8760 )
            var first_year_energy: Float64 = 0.0
            var i: Int32 = 0
            var nrows: Int = 0
            var ncols: Int = 0
            var diurnal_curtailment: Pointer[ssc_number_t] = self.as_matrix( "energy_curtailment", &nrows, &ncols )
            if nrows != 12 or ncols != 24:
                var stream_error: String = String("month x hour curtailment factors must have 12 rows and 24 columns, input has ") + String(nrows) + String(" rows and ") + String(ncols) + String(" columns.")
                var str_error: String = stream_error
                self.throw_exec_error("annualoutput", str_error)
            for m in range(0, 12):
                for d in range(0, util.nday[m]):
                    for h in range(0, 24):
                        if i < 8760:
                            first_year_energy += diurnal_curtailment[m * ncols + h] * hourly_enet[i]
                            hourly_energy_to_grid[i] = ssc_number_t(diurnal_curtailment[m * ncols + h] * hourly_enet[i] * self.cf.at(CF_availability, 1) * self.cf.at(CF_degradation, 1))
                            monthly_energy_to_grid[m] += hourly_energy_to_grid[i]
                            i += 1
            for y in range(1, nyears + 1):
                self.cf.at(CF_energy_net, y) = first_year_energy * self.cf.at(CF_availability, y) * self.cf.at(CF_degradation, y)
            return True

        def compute_lifetime_output(inout self, nyears: Int32) -> Bool:
            var hourly_enet: Pointer[ssc_number_t]
            var count: Int
            hourly_enet = self.as_array("system_hourly_energy", &count)
            if count != (8760 * nyears):
                var outm: String = String("Bad hourly lifetime energy output length (") + String(count) + String("), should be (analysis period-1) * 8760 value (") + String(8760 * nyears) + String(")")
                self.log( outm )
                return False
            var nrows: Int = 0
            var ncols: Int = 0
            var diurnal_curtailment: Pointer[ssc_number_t] = self.as_matrix( "energy_curtailment", &nrows, &ncols )
            if nrows != 12 or ncols != 24:
                self.throw_exec_error("annualoutput", "month x hour curtailment factors must have 12 rows and 24 columns")
            var monthly_energy_to_grid: Pointer[ssc_number_t] = self.allocate( "monthly_energy", 12 * nyears )
            var hourly_energy_to_grid: Pointer[ssc_number_t] = self.allocate( "hourly_energy", 8760 * nyears )
            for y in range(1, nyears + 1):
                self.cf.at(CF_energy_net, y) = 0
                var i: Int32 = 0
                for m in range(0, 12):
                    monthly_energy_to_grid[(y - 1) * 12 + m] = 0
                    for d in range(0, util.nday[m]):
                        for h in range(0, 24):
                            if i < 8760:
                                hourly_energy_to_grid[(y - 1) * 8760 + i] = ssc_number_t(diurnal_curtailment[m * ncols + h] * hourly_enet[(y - 1) * 8760 + i] * self.cf.at(CF_availability, y) * self.cf.at(CF_degradation, y))
                                monthly_energy_to_grid[(y - 1) * 12 + m] += hourly_energy_to_grid[(y - 1) * 8760 + i]
                                self.cf.at(CF_energy_net, y) += hourly_energy_to_grid[(y - 1) * 8760 + i]
                                i += 1
            return True

        def save_cf(inout self, cf_line: Int32, nyears: Int32, name: String):
            var arrp: Pointer[ssc_number_t] = self.allocate( name, nyears + 1 )
            for i in range(0, nyears + 1):
                arrp[i] = ssc_number_t(self.cf.at(cf_line, i))

def DEFINE_MODULE_ENTRY(annualoutput: alias, "Annual Output_": String, 1: Int32):
