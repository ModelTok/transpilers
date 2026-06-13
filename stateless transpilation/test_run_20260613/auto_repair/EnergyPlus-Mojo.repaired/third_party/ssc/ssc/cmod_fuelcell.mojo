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

from core import compute_module, var_info, var_info_invalid, exec_error, ssc_number_t, SSC_INPUT, SSC_OUTPUT, SSC_INOUT, SSC_NUMBER, SSC_ARRAY, SSC_MATRIX
from lib_fuel_cell import FuelCell
from lib_fuel_cell_dispatch import FuelCellDispatch
from lib_util import matrix_t, percent_to_fraction, fraction_to_percent
from math import fmax

// Constants
alias BTU_PER_KWH = 3412.0  // approximate, adjust if needed
alias MCF_TO_KWH = fn(mcf: Float64, lhv: Float64) -> Float64:
    return mcf * lhv * 1000.0 / BTU_PER_KWH  // placeholder, actual formula may differ

// struct fuelCellVariables
struct fuelCellVariables:
    var systemUseLifetimeOutput: Bool
    var numberOfYears: Int
    var numberOfRecordsPerYear: Int
    var numberOfLifetimeRecords: Int
    var stepsPerHour: Int
    var systemGeneration_kW: List[Float64]
    var electricLoad_kW: List[Float64]
    var dt_hour: Float64
    var unitPowerMax_kW: Float64
    var unitPowerMin_kW: Float64
    var shutdown_hours: Float64
    var startup_hours: Float64
    var is_started: Bool
    var dynamicResponseUp_kWperHour: Float64
    var dynamicResponseDown_kWperHour: Float64
    var degradation_kWperHour: Float64
    var degradationRestart_kW: Float64
    var replacementOption: Int
    var replacement_percent: Float64
    var replacementSchedule: List[Int]
    var efficiencyTable: matrix_t[Float64]
    var efficiencyChoice: Int
    var shutdownTable: matrix_t[Int]
    var lowerHeatingValue_BtuPerFt3: Float64
    var higherHeatingValue_BtuPerFt3: Float64
    var availableFuel_MCf: Float64
    var shutdownOption: Int
    var numberOfUnits: Int
    var dispatchOption: Int
    var fixed_percent: Float64
    var dispatch_kW: List[Float64]
    var canCharge: List[Bool]
    var canDischarge: List[Bool]
    var discharge_percent: List[Float64]
    var discharge_units: List[Int]
    var discharge_percentByPeriod: Dict[Int, Float64]
    var discharge_unitsByPeriod: Dict[Int, Int]
    var scheduleWeekday: matrix_t[Int]
    var scheduleWeekend: matrix_t[Int]

    def __init__(inout self):

    def __init__(inout self, cm: compute_module):
        self.systemUseLifetimeOutput = cm.as_boolean("system_use_lifetime_output")
        self.unitPowerMax_kW = cm.as_double("fuelcell_unit_max_power")
        self.unitPowerMin_kW = cm.as_double("fuelcell_unit_min_power")
        self.shutdown_hours = cm.as_double("fuelcell_shutdown_time")
        self.startup_hours = cm.as_double("fuelcell_startup_time")
        self.is_started = cm.as_double("fuelcell_is_started")
        self.dynamicResponseUp_kWperHour = cm.as_double("fuelcell_dynamic_response_up")
        self.dynamicResponseDown_kWperHour = cm.as_double("fuelcell_dynamic_response_down")
        self.degradation_kWperHour = cm.as_double("fuelcell_degradation")
        self.degradationRestart_kW = cm.as_double("fuelcell_degradation_restart")
        self.replacementOption = cm.as_unsigned_long("fuelcell_replacement_option")
        self.replacement_percent = cm.as_double("fuelcell_replacement_percent")
        self.replacementSchedule = cm.as_vector_unsigned_long("fuelcell_replacement_schedule")
        self.efficiencyTable = cm.as_matrix("fuelcell_efficiency")
        self.efficiencyChoice = cm.as_unsigned_long("fuelcell_efficiency_choice")
        self.shutdownTable = cm.as_matrix_unsigned_long("fuelcell_availability_schedule")
        self.lowerHeatingValue_BtuPerFt3 = cm.as_double("fuelcell_lhv")
        self.higherHeatingValue_BtuPerFt3 = cm.as_double("fuelcell_lhv")
        self.availableFuel_MCf = cm.as_double("fuelcell_fuel_available")
        self.shutdownOption = cm.as_integer("fuelcell_operation_options")
        self.numberOfUnits = cm.as_integer("fuelcell_number_of_units")
        self.dispatchOption = cm.as_integer("fuelcell_dispatch_choice")
        self.fixed_percent = cm.as_double("fuelcell_fixed_pct")
        self.dispatch_kW = cm.as_vector_double("fuelcell_dispatch")
        self.canCharge = cm.as_vector_bool("dispatch_manual_fuelcellcharge")
        self.canDischarge = cm.as_vector_bool("dispatch_manual_fuelcelldischarge")
        self.discharge_percent = cm.as_vector_double("dispatch_manual_percent_fc_discharge")
        self.discharge_units = cm.as_vector_unsigned_long("dispatch_manual_units_fc_discharge")
        self.scheduleWeekday = cm.as_matrix_unsigned_long("dispatch_manual_sched")
        self.scheduleWeekend = cm.as_matrix_unsigned_long("dispatch_manual_sched_weekend")

        self.numberOfYears = 1
        if self.systemUseLifetimeOutput:
            self.numberOfYears = cm.as_unsigned_long("analysis_period")

        if cm.is_assigned("load"):
            self.electricLoad_kW = cm.as_vector_double("load")
        else:
            self.electricLoad_kW = List[Float64]()

        if cm.is_assigned("gen"):
            self.systemGeneration_kW = cm.as_vector_double("gen")
            self.numberOfRecordsPerYear = self.systemGeneration_kW.size() / self.numberOfYears
        else:
            self.numberOfRecordsPerYear = Int(fmax(self.electricLoad_kW.size(), 8760))
            self.systemGeneration_kW = List[Float64]()
            self.systemGeneration_kW.reserve(self.numberOfRecordsPerYear * self.numberOfYears)
            for j in range(self.numberOfRecordsPerYear * self.numberOfYears):
                self.systemGeneration_kW.push_back(0.0)

        self.numberOfLifetimeRecords = self.numberOfRecordsPerYear * self.numberOfYears
        self.stepsPerHour = self.numberOfRecordsPerYear / 8760
        self.dt_hour = 1.0 / Float64(self.stepsPerHour)

        var load: List[Float64] = self.electricLoad_kW
        self.electricLoad_kW = List[Float64]()
        self.electricLoad_kW.reserve(self.numberOfLifetimeRecords)
        if load.size() == 0:
            for k in range(self.numberOfLifetimeRecords):
                self.electricLoad_kW.push_back(0.0)
        elif load.size() == self.numberOfRecordsPerYear:
            for y in range(self.numberOfYears):
                for i in range(self.numberOfRecordsPerYear):
                    self.electricLoad_kW.push_back(load[i])
        elif load.size() == 8760:
            for y in range(self.numberOfYears):
                for h in range(8760):
                    var loadHour: Float64 = load[h]
                    for s in range(self.stepsPerHour):
                        self.electricLoad_kW.push_back(loadHour)
        else:
            throw exec_error("fuelcell", "Electric load time steps must equal generation time step or 8760")

        var count: Int = 0
        for p in range(self.canDischarge.size()):
            if self.canDischarge[p]:
                self.discharge_percentByPeriod[p] = self.discharge_percent[count]
                self.discharge_unitsByPeriod[p] = self.discharge_units[count]
                count += 1

// var_info arrays
var vtab_fuelcell_input: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Lifetime simulation", "0/1", "0=SingleYearRepeated,1=RunEveryYear", "Lifetime", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Lifetime analysis period", "years", "The number of years in the simulation", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INOUT, SSC_ARRAY, "gen", "System power generated", "kW", "Lifetime system generation", "", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "load", "Electricity load (year 1)", "kW", "", "Load", "", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "fuelcell_availability_schedule", "Fuel cell availability schedule ", "Column 1: Hour of year start shutdown/Column 2: Hours duration of shutdown ", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_degradation", "Fuel cell degradation per hour", "kW/h", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_degradation_restart", "Fuel cell degradation at restart", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_degradation_restart_schedule", "Fuel cell enable scheduled restarts", "0/1", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_degradation_restarts_per_year", "Fuel cell scheduled restarts per year", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_fixed_pct", "Fuel cell fixed operation percent", "%", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_dynamic_response_up", "Fuel cell ramp rate limit up", "kW/h", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_dynamic_response_down", "Fuel cell ramp rate limit down", "kW/h", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "fuelcell_efficiency", "Fuel cell efficiency table ", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_efficiency_choice", "Fuel cell efficiency definition choice ", "0/1", "0=OriginalNameplate,1=DegradedNameplate", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_fuel_available", "Fuel cell available fuel quantity", "MCf", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_fuel_price", "Fuel cell price", "$/MCf", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_fuel_type", "Fuel cell type", "0/1", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_lhv", "Fuel cell lower heating value", "Btu/ft3", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_number_of_units", "Fuel cell number of units", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_operation_options", "Fuel cell turn off options", "0/1", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_replacement_option", "Fuel cell replacement option", "0/1/2", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_replacement_percent", "Fuel cell replace at percentage", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "fuelcell_replacement_schedule", "Fuel cell replace on schedule", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_shutdown_time", "Fuel cell shutdown hours", "hours", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_startup_time", "Fuel cell startup hours", "hours", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_is_started", "Fuel cell is started", "0/1", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_type", "Fuel cell type", "0/1/2", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_unit_max_power", "Fuel cell max power per unit", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_unit_min_power", "Fuel cell min power per unit", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "fuelcell_dispatch", "Fuel cell dispatch input per unit", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fuelcell_dispatch_choice", "Fuel cell dispatch choice", "0/1/2", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_manual_fuelcellcharge", "Periods 1-6 charging allowed?", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_manual_fuelcelldischarge", "Periods 1-6 discharging allowed?", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_manual_percent_fc_discharge", "Periods 1-6 percent of max fuelcell output", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dispatch_manual_units_fc_discharge", "Periods 1-6 number of fuel cell units?", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "dispatch_manual_sched", "Dispatch schedule for weekday", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "dispatch_manual_sched_weekend", "Dispatch schedule for weekend", "", "", "Fuel Cell", "", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "", "?=0", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "annual_energy", "Annual Energy", "kWh", "", "", "?=0", "", ""),
    var_info_invalid
)

var vtab_fuelcell_output: List[var_info] = List[var_info](
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_power", "Electricity from fuel cell", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_power_max_percent", "Fuel cell max power percent available", "%", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_percent_load", "Fuel cell percent load", "%", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_electrical_efficiency", "Fuel cell electrical efficiency", "%", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_power_thermal", "Heat from fuel cell", "kWt", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_fuel_consumption_mcf", "Fuel consumption of fuel cell", "MCf", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_to_load", "Electricity to load from fuel cell", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_to_grid", "Electricity to grid from fuel cell", "kW", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "fuelcell_replacement", "Fuel cell replacements per year", "number/year", "", "Fuel Cell", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "system_heat_rate", "Heat rate conversion factor (MMBTUs/MWhe)", "MMBTUs/MWhe", "", "Fuel Cell", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_fuel_usage", "Annual Fuel Usage", "kWht", "", "Fuel Cell", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "annual_fuel_usage_lifetime", "Annual Fuel Usage (lifetime)", "kWht", "", "Fuel Cell", "", "", ""),
    var_info_invalid
)

// class cm_fuelcell
class cm_fuelcell(compute_module):
    var fcVars: Pointer[fuelCellVariables]
    var fuelCell: Pointer[FuelCell]
    var fuelCellDispatch: Pointer[FuelCellDispatch]
    var p_gen_kW: Pointer[ssc_number_t]
    var p_fuelCellPower_kW: Pointer[ssc_number_t]
    var p_fuelCellPowerMaxAvailable_percent: Pointer[ssc_number_t]
    var p_fuelCellLoad_percent: Pointer[ssc_number_t]
    var p_fuelCellElectricalEfficiency_percent: Pointer[ssc_number_t]
    var p_fuelCellPowerThermal_kW: Pointer[ssc_number_t]
    var p_fuelCellConsumption_MCf: Pointer[ssc_number_t]
    var p_fuelCellToGrid_kW: Pointer[ssc_number_t]
    var p_fuelCellToLoad_kW: Pointer[ssc_number_t]
    var p_fuelCellReplacements: Pointer[ssc_number_t]
    var p_fuelCellConsumption_MCf_annual: Pointer[ssc_number_t]

    def __init__(inout self):
        self.add_var_info(vtab_fuelcell_input)
        self.add_var_info(vtab_fuelcell_output)
        self.add_var_info(vtab_technology_outputs)

    def __del__(owned self):
        // unique_ptr destructors would delete; we manually delete
        if self.fuelCellDispatch:
            delete self.fuelCellDispatch
        if self.fuelCell:
            delete self.fuelCell
        if self.fcVars:
            delete self.fcVars

    def construct(inout self):
        var tmp = new fuelCellVariables(self)
        self.fcVars = tmp
        var tmp2 = new FuelCell(self.fcVars.unitPowerMax_kW, self.fcVars.unitPowerMin_kW,
            self.fcVars.startup_hours, self.fcVars.is_started, self.fcVars.shutdown_hours,
            self.fcVars.dynamicResponseUp_kWperHour, self.fcVars.dynamicResponseDown_kWperHour,
            self.fcVars.degradation_kWperHour, self.fcVars.degradationRestart_kW,
            self.fcVars.replacementOption, self.fcVars.replacement_percent, self.fcVars.replacementSchedule,
            self.fcVars.shutdownTable, self.fcVars.efficiencyChoice, self.fcVars.efficiencyTable,
            self.fcVars.lowerHeatingValue_BtuPerFt3, self.fcVars.higherHeatingValue_BtuPerFt3, self.fcVars.availableFuel_MCf,
            self.fcVars.shutdownOption, self.fcVars.dt_hour)
        self.fuelCell = tmp2
        var tmp3 = new FuelCellDispatch(self.fuelCell, self.fcVars.numberOfUnits,
            self.fcVars.dispatchOption, self.fcVars.shutdownOption, self.fcVars.dt_hour, self.fcVars.fixed_percent, self.fcVars.dispatch_kW,
            self.fcVars.canCharge, self.fcVars.canDischarge, self.fcVars.discharge_percentByPeriod, self.fcVars.discharge_unitsByPeriod,
            self.fcVars.scheduleWeekday, self.fcVars.scheduleWeekend)
        self.fuelCellDispatch = tmp3
        self.allocateOutputs()

    def exec(inout self):
        var annual_energy: Float64 = 0.0
        var annual_fuel: Float64 = 0.0
        /*
        if (is_assigned("percent_complete")) {
            percent_complete = as_float("percent_complete");
        }
        */
        self.construct()
        var idx: Int = 0
        for y in range(self.fcVars.numberOfYears):
            var idx_year: Int = 0
            var annual_index: Int
            if self.fcVars.numberOfYears > 1:
                annual_index = y + 1
            else:
                annual_index = 0
            for h in range(8760):
                /*
                if (h % (8760 / nStatusUpdates) == 0)
                {
                    float techs = 3;
                    percent = percent_complete + 100.0f * ((float)idx + 1) / ((float)fcVars->numberOfLifetimeRecords) / techs;
                    if (!update("", percent, (float)h)) {
                        throw exec_error("fuelcell", "simulation canceled at hour " + util::to_string(h + 1.0));
                    }
                }
                */
                for s in range(self.fcVars.stepsPerHour):
                    self.fuelCellDispatch.runSingleTimeStep(h, idx_year, self.fcVars.systemGeneration_kW[idx], self.fcVars.electricLoad_kW[idx])
                    self.p_fuelCellPower_kW[idx] = ssc_number_t(self.fuelCellDispatch.getPower())
                    self.p_fuelCellPowerMaxAvailable_percent[idx] = ssc_number_t(self.fuelCellDispatch.getPowerMaxPercent())
                    self.p_fuelCellLoad_percent[idx] = ssc_number_t(self.fuelCellDispatch.getPercentLoad())
                    self.p_fuelCellElectricalEfficiency_percent[idx] = ssc_number_t(self.fuelCellDispatch.getElectricalEfficiencyPercent())
                    self.p_fuelCellPowerThermal_kW[idx] = ssc_number_t(self.fuelCellDispatch.getPowerThermal())
                    self.p_fuelCellConsumption_MCf[idx] = ssc_number_t(self.fuelCellDispatch.getFuelConsumption())
                    self.p_fuelCellConsumption_MCf_annual[annual_index] += ssc_number_t(MCF_TO_KWH(self.p_fuelCellConsumption_MCf[idx], self.fcVars.lowerHeatingValue_BtuPerFt3))
                    self.p_fuelCellToGrid_kW[idx] = ssc_number_t(self.fuelCellDispatch.getBatteryPower().powerFuelCellToGrid)
                    self.p_fuelCellToLoad_kW[idx] = ssc_number_t(self.fuelCellDispatch.getBatteryPower().powerFuelCellToLoad)
                    self.p_gen_kW[idx] = ssc_number_t(self.fcVars.systemGeneration_kW[idx]) + self.p_fuelCellPower_kW[idx]
                    if y == 0:
                        annual_energy += self.p_gen_kW[idx] * self.fcVars.dt_hour
                    idx += 1
                    idx_year += 1
            if y == 0:
                annual_fuel = self.p_fuelCellConsumption_MCf_annual[annual_index]
            self.p_fuelCellReplacements[annual_index] = ssc_number_t(self.fuelCell.getTotalReplacements())
            self.fuelCell.resetReplacements()

        var capacity_factor_in: Float64 = 0.0
        var annual_energy_in: Float64 = 0.0
        var nameplate_in: Float64 = 0.0
        if self.is_assigned("capacity_factor") and self.is_assigned("annual_energy"):
            capacity_factor_in = self.as_double("capacity_factor")
            annual_energy_in = self.as_double("annual_energy")
            nameplate_in = (annual_energy_in / (capacity_factor_in * percent_to_fraction)) / 8760.0

        var nameplate: Float64 = nameplate_in + (self.fcVars.unitPowerMax_kW * self.fcVars.numberOfUnits)
        self.assign("capacity_factor", var_data(ssc_number_t(annual_energy * fraction_to_percent / (nameplate * 8760.0))))
        self.assign("annual_energy", var_data(ssc_number_t(annual_energy)))
        self.assign("system_heat_rate", var_data(ssc_number_t(BTU_PER_KWH / 1000)))
        self.assign("annual_fuel_usage", var_data(ssc_number_t(annual_fuel)))

    def allocateOutputs(inout self):
        self.p_fuelCellPower_kW = self.allocate("fuelcell_power", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellPowerMaxAvailable_percent = self.allocate("fuelcell_power_max_percent", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellLoad_percent = self.allocate("fuelcell_percent_load", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellElectricalEfficiency_percent = self.allocate("fuelcell_electrical_efficiency", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellPowerThermal_kW = self.allocate("fuelcell_power_thermal", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellConsumption_MCf = self.allocate("fuelcell_fuel_consumption_mcf", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellToGrid_kW = self.allocate("fuelcell_to_grid", self.fcVars.numberOfLifetimeRecords)
        self.p_fuelCellToLoad_kW = self.allocate("fuelcell_to_load", self.fcVars.numberOfLifetimeRecords)
        var annual_size: Int = self.fcVars.numberOfYears + 1
        if self.fcVars.numberOfYears == 1:
            annual_size = 1
        self.p_fuelCellReplacements = self.allocate("fuelcell_replacement", annual_size)
        self.p_fuelCellConsumption_MCf_annual = self.allocate("annual_fuel_usage_lifetime", annual_size)
        self.p_fuelCellReplacements[0] = 0
        self.p_fuelCellConsumption_MCf_annual[0] = 0
        self.p_gen_kW = self.allocate("gen", self.fcVars.numberOfLifetimeRecords)

// DEFINE_MODULE_ENTRY(fuelcell, "Fuel cell model", 1)