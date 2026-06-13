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
from core import var_info, SSC_INPUT, SSC_NUMBER, SSC_ARRAY, SSC_INOUT, SSC_OUTPUT, var_info_invalid, compute_module, exec_error, util, vtab_adjustment_factors, vtab_technology_outputs
from lib_windfile import *
from lib_windwatts import *
from common import adjustment_factors
from math import pow

alias ssc_number_t = Float32
alias double = Float64

var __ARCHBITS__: Int = 64

var _cm_vtab_generic_system: List[var_info] = [
    var_info(SSC_INPUT, SSC_NUMBER, "spec_mode", "Spec mode: 0=constant CF,1=profile", "", "", "Plant", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "derate", "Derate", "%", "", "Plant", "*", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "system_capacity", "Nameplace Capcity", "kW", "", "Plant", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "user_capacity_factor", "Capacity Factor", "%", "", "Plant", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "heat_rate", "Heat Rate", "MMBTUs/MWhe", "", "Plant", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "conv_eff", "Conversion Efficiency", "%", "", "Plant", "*", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "energy_output_array", "Array of Energy Output Profile", "kW", "", "Plant", "spec_mode=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Generic lifetime simulation", "0/1", "", "Lifetime", "?=0", "INTEGER,MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Lifetime analysis period", "years", "", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "generic_degradation", "Annual AC degradation", "%/year", "", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly Energy", "kWh", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual Fuel Usage", "kWht", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "water_usage", "Annual Water Usage", "", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "Heat Rate Conversion Factor", "MMBTUs/MWhe", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "First year kWh/kW", "kWh/kW", "", "Annual", "*", "", ""),
    var_info_invalid
]

class cm_generic_system(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_generic_system)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(self):
        var spec_mode: Int = self.as_integer("spec_mode")
        var system_use_lifetime_output: Bool = (self.as_integer("system_use_lifetime_output") == 1)
        # static bool is32BitLifetime = (__ARCHBITS__ == 32 && system_use_lifetime_output);
        var is32BitLifetime: Bool = (__ARCHBITS__ == 32 and system_use_lifetime_output)
        if is32BitLifetime:
            raise exec_error("generic", "Lifetime simulation of generic systems is only available in the 64 bit version of SAM.")
        var enet: List[ssc_number_t] = List[ssc_number_t]()
        var nyears: size_t = 1
        if system_use_lifetime_output:
            nyears = self.as_integer("analysis_period")
        var load: List[double] = List[double]()
        var nrec_load: size_t = 8760
        if self.is_assigned("load"):
            load = self.as_vector_double("load")
            nrec_load = len(load)
        var nlifetime: size_t = nrec_load * nyears
        var steps_per_hour: size_t = nrec_load // 8760
        var ts_hour: double = 1.0 / double(steps_per_hour)
        var sys_degradation: List[ssc_number_t] = List[ssc_number_t]()
        # sys_degradation.reserve(nyears); // not needed in Mojo
        var derate: double = (1.0 - double(self.as_number("derate")) / 100.0)
        var haf = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("generic system", "failed to setup adjustment factors: " + haf.error())
        if system_use_lifetime_output:
            var i: size_t = 0
            var count_degrad: size_t = 0
            var degrad: List[ssc_number_t] = self.as_array("generic_degradation", count_degrad)
            if count_degrad == 1:
                for i in range(nyears):
                    sys_degradation.append(ssc_number_t(pow(1.0 - double(degrad[0]) / 100.0, i)))
            elif count_degrad > 0:
                for i in range(nyears):
                    if i < int(count_degrad):
                        sys_degradation.append(ssc_number_t(1.0 - double(degrad[i]) / 100.0))
        else:
            sys_degradation.append(1) # single year mode - degradation handled in financial models.
        var idx: size_t = 0
        var annual_output: double = 0.0
        if spec_mode == 0:
            var output: double = double(self.as_number("system_capacity")) * double(self.as_number("user_capacity_factor")) / 100.0 * derate # kW
            annual_output = 8760.0 * output # kWh
            enet = self.allocate("gen", nlifetime)
            for iyear in range(nyears):
                for ihour in range(8760):
                    for ihourstep in range(steps_per_hour):
                        enet[idx] = ssc_number_t(output * haf(ihour)) * sys_degradation[iyear] # kW
                        idx += 1
        else:
            var nrec_gen: size_t = 0
            var enet_in: List[ssc_number_t] = self.as_array("energy_output_array", nrec_gen) # kW
            var steps_per_hour_gen: size_t = nrec_gen // 8760
            if not enet_in:
                raise exec_error("generic", util.format("energy_output_array variable had no values."))
            if nrec_gen < nrec_load:
                raise exec_error("generic", util.format("energy_output_array {} must be greater than or equal to load array {}", nrec_gen, nrec_load))
            else:
                nlifetime = nrec_gen * nyears
                steps_per_hour = steps_per_hour_gen
                ts_hour = 1.0 / double(steps_per_hour)
            enet = self.allocate("gen", nlifetime)
            for iyear in range(nyears):
                for ihour in range(8760):
                    for ihourstep in range(steps_per_hour_gen):
                        enet[idx] = enet_in[ihour * steps_per_hour_gen + ihourstep] * ssc_number_t(derate * haf(ihour)) * sys_degradation[iyear]
                        idx += 1
        var annual_ac_pre_avail: double = 0.0
        var annual_energy: double = 0.0
        idx = 0
        for iyear in range(nyears):
            for hour in range(8760):
                for jj in range(steps_per_hour):
                    if iyear == 0:
                        annual_ac_pre_avail += enet[idx] * ts_hour
                    enet[idx] *= haf(hour)
                    if iyear == 0:
                        annual_energy += ssc_number_t(enet[idx] * ts_hour)
                    idx += 1
        self.accumulate_monthly_for_year("gen", "monthly_energy", ts_hour, steps_per_hour)
        annual_output = self.accumulate_annual_for_year("gen", "annual_energy", ts_hour, steps_per_hour)
        var fuel_usage: double = 0.0
        if self.as_double("conv_eff") != 0.0:
            fuel_usage = annual_output * 100.0 / self.as_double("conv_eff")
        self.assign("annual_fuel_usage", ssc_number_t(fuel_usage))
        self.assign("water_usage", 0.0)
        self.assign("system_heat_rate", ssc_number_t(self.as_number("heat_rate") * self.as_number("conv_eff") / 100.0))
        var kWhperkW: double = 0.0
        var nameplate: double = self.as_double("system_capacity")
        if nameplate <= 0:
            nameplate = annual_output / (8760.0 * double(self.as_number("user_capacity_factor") / 100.0) * derate)
        self.assign("system_capacity", var_data(ssc_number_t(nameplate)))
        if nameplate > 0:
            kWhperkW = annual_output / nameplate
        self.assign("capacity_factor", var_data(ssc_number_t(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data(ssc_number_t(kWhperkW)))
# DEFINE_MODULE_ENTRY( generic_system, "Generic System", 1 )