// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from common import *
from core import *
from cmod_grid import *
from lib_time import *

struct gridVariables:
    var enable_interconnection_limit: Bool
    var grid_interconnection_limit_kW: Float64
    var gridCurtailmentLifetime_MW: List[Float64]
    var systemGenerationLifetime_kW: List[Float64]
    var systemGenerationPreInterconnect_kW: List[Float64]
    var loadLifetime_kW: List[Float64]
    var grid_kW: List[Float64]
    var numberOfLifetimeRecords: Int
    var numberOfSingleYearRecords: Int
    var numberOfYears: Int
    var dt_hour_gen: Float64

    def __init__(inout self, cm: compute_module):
        self.enable_interconnection_limit = cm.as_boolean("enable_interconnection_limit")
        self.grid_interconnection_limit_kW = cm.as_double("grid_interconnection_limit_kwac")
        self.gridCurtailmentLifetime_MW = List[Float64]()
        self.systemGenerationLifetime_kW = List[Float64]()
        self.systemGenerationPreInterconnect_kW = List[Float64]()
        self.loadLifetime_kW = List[Float64]()
        self.grid_kW = List[Float64]()
        self.numberOfLifetimeRecords = 0
        self.numberOfSingleYearRecords = 0
        self.numberOfYears = 0
        self.dt_hour_gen = 0.0

var vtab_grid_input: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Lifetime simulation", "0/1", "0=SingleYearRepeated,1=RunEveryYear", "Lifetime", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Lifetime analysis period", "years", "The number of years in the simulation", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "enable_interconnection_limit", "Enable grid interconnection limit", "0/1", "Enable a grid interconnection limit", "GridLimits", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "grid_interconnection_limit_kwac", "Grid interconnection limit", "kWac", "", "GridLimits", "", "", ""),
    var_info(SSC_INOUT, SSC_ARRAY, "gen", "System power generated", "kW", "Lifetime system generation", "System Output", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "load", "Electricity load (year 1)", "kW", "", "Load", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "load_escalation", "Annual load escalation", "%/year", "", "Load", "?=0", "", ""),
    var_info_invalid
)

var vtab_grid_output: List[var_info] = List[var_info](
    var_info(SSC_OUTPUT, SSC_ARRAY, "system_pre_interconnect_kwac", "System power before grid interconnect", "kW", "Lifetime system generation", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor_interconnect_ac", "Capacity factor of the interconnection (year 1)", "%", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy_pre_interconnect_ac", "Annual Energy AC pre-interconnection (year 1)", "kWh", "", "", "", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "annual_energy", "Annual Energy AC (year 1)", "kWh", "", "System Output", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_ac_interconnect_loss_percent", "Annual Energy loss from interconnection limit (year 1)", "%", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_ac_interconnect_loss_kwh", "Annual Energy loss from interconnection limit (year 1)", "kWh", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "system_pre_curtailment_kwac", "System power before grid curtailment", "kW", "Lifetime system generation", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor_curtailment_ac", "Capacity factor of the curtailment (year 1)", "%", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy_pre_curtailment_ac", "Annual Energy AC pre-curtailment (year 1)", "kWh", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_ac_curtailment_loss_percent", "Annual Energy loss from curtailment (year 1)", "%", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_ac_curtailment_loss_kwh", "Annual Energy loss from curtailment (year 1)", "kWh", "", "", "", "", ""),
    var_info_invalid
)

@value
struct cm_grid(compute_module):
    var gridVars: Pointer[gridVariables]
    var p_gen_kW: Pointer[ssc_number_t]
    var p_genPreCurtailment_kW: Pointer[ssc_number_t]
    var p_genPreInterconnect_kW: Pointer[ssc_number_t]

    def __init__(inout self):
        self.gridVars = Pointer[gridVariables]()
        self.p_gen_kW = Pointer[ssc_number_t]()
        self.p_genPreCurtailment_kW = Pointer[ssc_number_t]()
        self.p_genPreInterconnect_kW = Pointer[ssc_number_t]()
        self.add_var_info(vtab_grid_input)
        self.add_var_info(vtab_grid_output)
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(vtab_grid_curtailment)

    def __del__(owned self):

    def construct(inout self):
        var tmp = gridVariables(self)
        self.gridVars = Pointer[gridVariables](tmp)

    def exec(inout self):
        self.construct()
        self.gridVars[].systemGenerationLifetime_kW = self.as_vector_double("gen")
        var n_rec_lifetime: Int = self.gridVars[].systemGenerationLifetime_kW.size()
        var n_rec_single_year: Int
        var analysis_period: Int = 1
        if self.is_assigned("analysis_period"):
            analysis_period = self.as_integer("analysis_period")
        var system_use_lifetime_output: Bool = False
        if self.is_assigned("system_use_lifetime_output"):
            system_use_lifetime_output = self.as_integer("system_use_lifetime_output") != 0
        var scaleFactors = List[Float64](analysis_period, 1.0)
        var curtailment_year_one = List[Float64]()
        if self.is_assigned("grid_curtailment"):
            curtailment_year_one = self.as_vector_double("grid_curtailment")
        var interpolation_factor: Float64 = 1.0
        single_year_to_lifetime_interpolated[Float64](
            system_use_lifetime_output,
            analysis_period,
            n_rec_lifetime,
            curtailment_year_one,
            scaleFactors,
            interpolation_factor,
            self.gridVars[].gridCurtailmentLifetime_MW,
            n_rec_single_year,
            self.gridVars[].dt_hour_gen)
        self.allocateOutputs()
        self.gridVars[].numberOfLifetimeRecords = n_rec_lifetime
        self.gridVars[].numberOfSingleYearRecords = n_rec_single_year
        self.gridVars[].numberOfYears = n_rec_lifetime / n_rec_single_year
        self.gridVars[].grid_kW.reserve(self.gridVars[].numberOfLifetimeRecords)
        self.gridVars[].grid_kW = self.gridVars[].systemGenerationLifetime_kW
        var load_year_one = List[Float64]()
        if self.is_assigned("load"):
            load_year_one = self.as_vector_double("load")
        var scale_calculator = scalefactors(self.m_vartab)
        var load_scale = List[ssc_number_t](analysis_period, 1.0)
        if self.is_assigned("load_escalation"):
            load_scale = scale_calculator.get_factors("load_escalation")
        interpolation_factor = 1.0
        single_year_to_lifetime_interpolated[Float64](
            system_use_lifetime_output,
            analysis_period,
            n_rec_lifetime,
            load_year_one,
            load_scale,
            interpolation_factor,
            self.gridVars[].loadLifetime_kW,
            n_rec_single_year,
            self.gridVars[].dt_hour_gen)
        var capacity_factor_interconnect: Float64
        var annual_energy_pre_curtailment: Float64
        var annual_energy_pre_interconnect: Float64
        var annual_energy: Float64
        var capacity_factor_curtailment: Float64
        capacity_factor_interconnect = 0.0
        annual_energy_pre_curtailment = 0.0
        annual_energy_pre_interconnect = 0.0
        annual_energy = 0.0
        capacity_factor_curtailment = 0.0
        var hour: Int = 0
        var num_steps_per_hour: Int = Int(1.0 / self.gridVars[].dt_hour_gen)
        for i in range(self.gridVars[].numberOfLifetimeRecords):
            var gen: Float64 = self.gridVars[].systemGenerationLifetime_kW[i]
            var gridNet: Float64 = gen - self.gridVars[].loadLifetime_kW[i]
            if self.gridVars[].enable_interconnection_limit:
                self.p_genPreInterconnect_kW[i] = ssc_number_t(gen)
                var interconnectionLimited: Float64 = fmax(0.0, gridNet - self.gridVars[].grid_interconnection_limit_kW)
                gen -= interconnectionLimited
                gridNet -= interconnectionLimited
            self.p_genPreCurtailment_kW[i] = ssc_number_t(gen)
            var curtailed: Float64 = fmax(0.0, gridNet - self.gridVars[].gridCurtailmentLifetime_MW[i] * 1000.0)
            gen -= curtailed
            self.p_gen_kW[i] = ssc_number_t(gen)
            if i < self.gridVars[].numberOfSingleYearRecords:
                annual_energy_pre_interconnect += self.p_genPreInterconnect_kW[i]
                annual_energy_pre_curtailment += self.p_genPreCurtailment_kW[i]
                annual_energy += self.p_gen_kW[i]
            if ((i + 1) % self.gridVars[].numberOfSingleYearRecords) == 0:
                hour = 0
            elif ((i + 1) % num_steps_per_hour) == 0:
                hour += 1
        annual_energy_pre_curtailment *= self.gridVars[].dt_hour_gen
        annual_energy_pre_interconnect *= self.gridVars[].dt_hour_gen
        annual_energy *= self.gridVars[].dt_hour_gen
        if self.gridVars[].enable_interconnection_limit:
            capacity_factor_interconnect = annual_energy_pre_curtailment * util.fraction_to_percent / (self.gridVars[].grid_interconnection_limit_kW * 8760.0)
        capacity_factor_curtailment = annual_energy * util.fraction_to_percent / (self.gridVars[].grid_interconnection_limit_kW * 8760.0)
        if self.gridVars[].enable_interconnection_limit:
            self.assign("capacity_factor_interconnect_ac", var_data(capacity_factor_interconnect))
            self.assign("annual_energy_pre_interconnect_ac", var_data(annual_energy_pre_interconnect))
            self.assign("annual_ac_interconnect_loss_kwh", var_data(std_round(annual_energy_pre_interconnect - annual_energy_pre_curtailment)))
            self.assign("annual_ac_interconnect_loss_percent", var_data(100.0 * (annual_energy_pre_interconnect - annual_energy_pre_curtailment) / annual_energy_pre_interconnect))
            self.assign("capacity_factor_interconnect_ac", var_data(capacity_factor_curtailment))
        self.assign("annual_energy_pre_curtailment_ac", var_data(annual_energy_pre_curtailment))
        self.assign("annual_energy", var_data(annual_energy))
        self.assign("annual_ac_curtailment_loss_kwh", var_data(std_round(annual_energy_pre_curtailment - annual_energy)))
        self.assign("annual_ac_curtailment_loss_percent", var_data(100.0 * (annual_energy_pre_curtailment - annual_energy) / annual_energy_pre_curtailment))

    def allocateOutputs(inout self):
        self.p_gen_kW = self.allocate("gen", self.gridVars[].systemGenerationLifetime_kW.size())
        self.p_genPreCurtailment_kW = self.allocate("system_pre_curtailment_kwac", self.gridVars[].systemGenerationLifetime_kW.size())
        self.p_genPreInterconnect_kW = self.allocate("system_pre_interconnect_kwac", self.gridVars[].systemGenerationLifetime_kW.size())

DEFINE_MODULE_ENTRY(grid, "Grid model", 1)