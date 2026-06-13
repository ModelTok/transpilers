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

from common import *
from core import *
from lib_util import *
from lib_time import *
from lib_shared_inverter import *
from lib_battery import *
from cmod_battery import *
from lib_power_electronics import *
from lib_resilience import *

# var_info vtab_battwatts[] = { ... }
# we need to construct the array. In Mojo, we can define a list of var_info structs.
# Assuming var_info is a struct with fields: vartype, datatype, name, label, units, meta, group, required_if, constraints, ui_hints
var vtab_battwatts: List[var_info] = List[
    # each element constructed with var_info(...)
    var_info(SSC_INPUT, SSC_NUMBER, "system_use_lifetime_output", "Enable lifetime simulation", "0/1", "0=SingleYearRepeated,1=RunEveryYear", "Lifetime", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Lifetime analysis period", "years", "The number of years in the simulation", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_enable", "Enable Battery", "0/1", "", "Battery", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_kwh", "Battery Capacity", "kWh", "", "Battery", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_kw", "Battery Power", "kW", "", "Battery", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_chemistry", "Battery Chemistry", "0=LeadAcid,1=Li-ion/2", "", "Battery", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_dispatch", "Battery Dispatch", "0=PeakShavingLookAhead,1=PeakShavingLookBehind,2=Custom", "", "Battery", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "batt_custom_dispatch", "Battery Dispatch", "kW", "", "Battery", "batt_simple_dispatch=2", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_meter_position", "Battery Meter Position", "0=BehindTheMeter,1=FrontOfMeter", "", "Battery", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dc", "DC array power", "W", "", "Battery", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "ac", "AC inverter power", "W", "", "Battery", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "load", "Electricity load (year 1)", "kW", "", "Battery", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "crit_load", "Critical electricity load (year 1)", "kW", "", "Battery", "", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "load_escalation", "Annual load escalation", "%/year", "", "Load", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "inverter_efficiency", "Inverter Efficiency", "%", "", "Battery", "", "MIN=0,MAX=100", ""),
    var_info_invalid  # sentinel
]

def battwatts_create(n_recs: Int, n_years: Int, chem: Int, meter_pos: Int, size_kwh: Float64, size_kw: Float64, inv_eff: Float64,
                   dispatch: Int, dispatch_custom: List[Float64] = List[Float64]()) -> batt_variables:
    var batt_vars = batt_variables()
    var lifetime_matrix = List[Float64]()
    var capacity_vs_temperature = List[Float64]()
    var batt_specific_energy_per_mass: Float64 = 0
    var batt_specific_energy_per_volume: Float64 = 0
    batt_vars.batt_chem = chem
    batt_vars.analysis_period = n_years
    batt_vars.batt_meter_position = meter_pos
    batt_vars.system_use_lifetime_output = (n_years > 1)
    var voltage_guess: Float64 = 0
    if batt_vars.batt_chem == battery_params.LITHIUM_ION:
        voltage_guess = 500
        batt_vars.batt_Vnom_default = 3.6
        batt_vars.batt_Vfull = 4.1
        batt_vars.batt_Vexp = 4.05
        batt_vars.batt_Vnom = 3.4
        batt_vars.batt_Qfull = 2.25
        batt_vars.batt_Qfull_flow = 0
        batt_vars.batt_Qexp = 0.178 * batt_vars.batt_Qfull
        batt_vars.batt_Qnom = 0.889 * batt_vars.batt_Qfull
        batt_vars.batt_C_rate = 0.2
        batt_vars.batt_resistance = 0.1
        lifetime_matrix.append(20); lifetime_matrix.append(0); lifetime_matrix.append(100)
        lifetime_matrix.append(20); lifetime_matrix.append(5000); lifetime_matrix.append(80)
        lifetime_matrix.append(80); lifetime_matrix.append(0); lifetime_matrix.append(100)
        lifetime_matrix.append(80); lifetime_matrix.append(1000); lifetime_matrix.append(80)
        var batt_lifetime_matrix = matrix_t[Float64](4, 3, lifetime_matrix)
        batt_vars.batt_lifetime_matrix = batt_lifetime_matrix
        batt_vars.batt_calendar_q0 = 1.02
        batt_vars.batt_calendar_a = 2.66e-3
        batt_vars.batt_calendar_b = -7280
        batt_vars.batt_calendar_c = 930
        capacity_vs_temperature.append(-15); capacity_vs_temperature.append(65)
        capacity_vs_temperature.append(0); capacity_vs_temperature.append(85)
        capacity_vs_temperature.append(25); capacity_vs_temperature.append(100)
        capacity_vs_temperature.append(40); capacity_vs_temperature.append(104)
        var batt_capacity_vs_temperature = matrix_t[Float64](4, 2, capacity_vs_temperature)
        batt_vars.cap_vs_temp = batt_capacity_vs_temperature
        batt_vars.batt_Cp = 1004
        batt_vars.batt_h_to_ambient = 500
        for i in range(n_recs):
            batt_vars.T_room.append(293)
        batt_specific_energy_per_mass = 197.33  # Wh/kg
        batt_specific_energy_per_volume = 501.25 # Wh/L
    elif batt_vars.batt_chem == battery_params.LEAD_ACID:
        voltage_guess = 48
        batt_vars.batt_Vnom_default = 2
        batt_vars.batt_Vfull = 2.2
        batt_vars.batt_Vexp = 2.06
        batt_vars.batt_Vnom = 2.03
        batt_vars.batt_Qfull = 20
        batt_vars.batt_Qexp = 0.025 * batt_vars.batt_Qfull
        batt_vars.batt_Qnom = 0.90 * batt_vars.batt_Qfull
        batt_vars.batt_C_rate = 0.05
        batt_vars.batt_resistance = 0.1
        lifetime_matrix.append(30); lifetime_matrix.append(0); lifetime_matrix.append(100)
        lifetime_matrix.append(30); lifetime_matrix.append(1100); lifetime_matrix.append(90)
        lifetime_matrix.append(30); lifetime_matrix.append(1200); lifetime_matrix.append(50)
        lifetime_matrix.append(50); lifetime_matrix.append(0); lifetime_matrix.append(100)
        lifetime_matrix.append(50); lifetime_matrix.append(400); lifetime_matrix.append(90)
        lifetime_matrix.append(50); lifetime_matrix.append(500); lifetime_matrix.append(50)
        lifetime_matrix.append(100); lifetime_matrix.append(0); lifetime_matrix.append(100)
        lifetime_matrix.append(100); lifetime_matrix.append(100); lifetime_matrix.append(90)
        lifetime_matrix.append(100); lifetime_matrix.append(150); lifetime_matrix.append(50)
        var batt_lifetime_matrix = matrix_t[Float64](9, 3, lifetime_matrix)
        batt_vars.batt_lifetime_matrix = batt_lifetime_matrix
        capacity_vs_temperature.append(-15); capacity_vs_temperature.append(65)
        capacity_vs_temperature.append(0); capacity_vs_temperature.append(85)
        capacity_vs_temperature.append(25); capacity_vs_temperature.append(100)
        capacity_vs_temperature.append(40); capacity_vs_temperature.append(104)
        var batt_capacity_vs_temperature = matrix_t[Float64](4, 2, capacity_vs_temperature)
        batt_vars.cap_vs_temp = batt_capacity_vs_temperature
        batt_vars.batt_Cp = 600
        batt_vars.batt_h_to_ambient = 500
        for i in range(n_recs):
            batt_vars.T_room.append(293)
        batt_specific_energy_per_mass = 30  # Wh/kg
        batt_specific_energy_per_volume = 30 # Wh/L
    batt_vars.batt_kwh = size_kwh
    batt_vars.batt_kw = size_kw
    batt_vars.batt_computed_series = Int(math.ceil(voltage_guess / batt_vars.batt_Vnom_default))
    batt_vars.batt_computed_strings = Int(math.ceil((batt_vars.batt_kwh * 1000.0) / (batt_vars.batt_Qfull * batt_vars.batt_computed_series * batt_vars.batt_Vnom_default))) - 1
    batt_vars.batt_kwh = batt_vars.batt_computed_strings * batt_vars.batt_Qfull * batt_vars.batt_computed_series * batt_vars.batt_Vnom_default / 1000.0
    if batt_vars.batt_chem == battery_params.LEAD_ACID:
        var LeadAcid_q20: Float64 = 100
        var LeadAcid_q10: Float64 = 93.2
        var LeadAcid_qn: Float64 = 58.12
        var LeadAcid_tn: Float64 = 1
        batt_vars.LeadAcid_q10_computed = batt_vars.batt_computed_strings * LeadAcid_q10 * batt_vars.batt_Qfull / 100
        batt_vars.LeadAcid_q20_computed = batt_vars.batt_computed_strings * LeadAcid_q20 * batt_vars.batt_Qfull / 100
        batt_vars.LeadAcid_qn_computed = batt_vars.batt_computed_strings * LeadAcid_qn * batt_vars.batt_Qfull / 100
        batt_vars.LeadAcid_tn = LeadAcid_tn
    batt_vars.batt_voltage_choice = voltage_params.MODEL
    batt_vars.batt_voltage_matrix = matrix_t[Float64]()
    var batt_time_hour: Float64 = batt_vars.batt_kwh / batt_vars.batt_kw
    var batt_C_rate_discharge: Float64 = 1.0 / batt_time_hour
    batt_vars.batt_current_choice = dispatch_t.RESTRICT_CURRENT
    batt_vars.batt_current_charge_max = 1000 * batt_C_rate_discharge * batt_vars.batt_kwh / voltage_guess
    batt_vars.batt_current_discharge_max = 1000 * batt_C_rate_discharge * batt_vars.batt_kwh / voltage_guess
    batt_vars.batt_power_charge_max_kwac = batt_vars.batt_kw
    batt_vars.batt_power_discharge_max_kwac = batt_vars.batt_kw
    batt_vars.batt_power_charge_max_kwdc = batt_vars.batt_kw / (batt_vars.batt_dc_ac_efficiency * 0.01)
    batt_vars.batt_power_discharge_max_kwdc = batt_vars.batt_kw / (batt_vars.batt_ac_dc_efficiency * 0.01)
    batt_vars.batt_topology = ChargeController.AC_CONNECTED
    batt_vars.batt_ac_dc_efficiency = 96
    batt_vars.batt_dc_ac_efficiency = 96
    batt_vars.batt_dc_dc_bms_efficiency = 99
    batt_vars.pv_dc_dc_mppt_efficiency = 99
    batt_vars.batt_initial_SOC = 50.0
    batt_vars.batt_maximum_SOC = 95.0
    batt_vars.batt_minimum_SOC = 15.0
    batt_vars.batt_minimum_modetime = 10
    # dispatch switch
    # default: case 0
    if dispatch == 0:
        batt_vars.batt_dispatch = dispatch_t.LOOK_AHEAD
    elif dispatch == 1:
        batt_vars.batt_dispatch = dispatch_t.LOOK_BEHIND
    elif dispatch == 2:
        batt_vars.batt_dispatch = dispatch_t.CUSTOM_DISPATCH
        batt_vars.batt_custom_dispatch = dispatch_custom
    batt_vars.batt_dispatch_auto_can_charge = True
    batt_vars.batt_dispatch_auto_can_gridcharge = True
    batt_vars.batt_replacement_capacity = 0.0
    batt_vars.batt_calendar_choice = calendar_cycle_params.CALENDAR_CHOICE.NONE
    batt_vars.batt_calendar_lifetime_matrix = matrix_t[Float64]()
    batt_vars.batt_calendar_q0 = 1.0
    batt_vars.batt_mass = batt_vars.batt_kwh * 1000 / batt_specific_energy_per_mass
    var batt_volume: Float64 = batt_vars.batt_kwh / batt_specific_energy_per_volume
    batt_vars.batt_surface_area = math.pow(batt_volume, 2.0 / 3.0) * 6
    batt_vars.batt_loss_choice = losses_params.MONTHLY
    batt_vars.batt_losses_charging.append(0)
    batt_vars.batt_losses_discharging.append(0)
    batt_vars.batt_losses_idle.append(0)
    batt_vars.inverter_model = SharedInverter.NONE
    batt_vars.inverter_efficiency = inv_eff
    # delete lifetime_matrix and capacity_vs_temperature not needed in Mojo
    return batt_vars

@value
class cm_battwatts(compute_module):
    def __init__(inout self):
        self.add_var_info(vtab_battwatts)
        self.add_var_info(vtab_battery_outputs)
        self.add_var_info(vtab_technology_outputs)
        self.add_var_info(vtab_resilience_outputs)

    def setup_variables(inout self, n_recs: Int) -> batt_variables:
        var nyears: Int = 1
        if self.as_boolean("system_use_lifetime_output"):
            nyears = Int(self.as_double("analysis_period"))
        var chem: Int = self.as_integer("batt_simple_chemistry")
        var pos: Int = self.as_integer("batt_simple_meter_position")
        var kwh: Float64 = self.as_number("batt_simple_kwh")
        var kw: Float64 = self.as_number("batt_simple_kw")
        var inv_eff: Float64 = self.as_number("inverter_efficiency")
        var dispatch: Int = self.as_integer("batt_simple_dispatch")
        var dispatch_custom: List[Float64] = List[Float64]()
        if dispatch == 2:
            dispatch_custom = self.as_vector_double("batt_custom_dispatch")
            if dispatch_custom.size != n_recs:
                raise exec_error("battwatts", "'batt_custom_dispatch' length must be equal to length of 'ac'.")
        return battwatts_create(n_recs, nyears, chem, pos, kwh, kw, inv_eff, dispatch, dispatch_custom)

    def exec(inout self):
        if self.as_boolean("batt_simple_enable"):
            # /* *********************************************************************************************
            # Setup problem
            # *********************************************************************************************** */
            var p_ac: List[ssc_number_t] = List[ssc_number_t]()
            var p_load: List[ssc_number_t] = List[ssc_number_t]()
            var voltage: Float64 = 500
            p_ac = self.as_vector_ssc_number_t("ac")
            util.vector_multiply_scalar[ssc_number_t](p_ac, ssc_number_t(util.watt_to_kilowatt))
            p_load = self.as_vector_ssc_number_t("load")
            var batt_vars = self.setup_variables(p_ac.size)
            var n_rec_lifetime: Int = p_ac.size
            var analysis_period: Int = Int(self.as_integer("analysis_period"))
            var scale_calculator = scalefactors(self.m_vartab)
            var load_scale: List[ssc_number_t] = scale_calculator.get_factors("load_escalation")
            var load_lifetime: List[ssc_number_t] = List[ssc_number_t]()
            var n_rec_single_year: Int = 0
            var dt_hour_gen: Float64 = 0.0
            var interpolation_factor: Float64 = 1.0
            single_year_to_lifetime_interpolated[ssc_number_t](
                Bool(self.as_integer("system_use_lifetime_output")),
                analysis_period,
                n_rec_lifetime,
                p_load,
                load_scale,
                interpolation_factor,
                load_lifetime,
                n_rec_single_year,
                dt_hour_gen)
            var batt = battstor(self.m_vartab, True, p_ac.size, dt_hour_gen, batt_vars)
            batt.initialize_automated_dispatch(p_ac, p_load)
            var resilience: resilience_runner? = None
            var p_crit_load: List[ssc_number_t] = List[ssc_number_t]()
            if self.is_assigned("crit_load"):
                p_crit_load = self.as_vector_ssc_number_t("crit_load")
                if p_crit_load.size != p_load.size:
                    raise exec_error("battwatts", "critical electric load profile must have same number of values as load")
                if not p_crit_load.empty() and max(p_crit_load) > 0:
                    resilience = resilience_runner(batt)
                    var logs = resilience.get_logs()
                    if not logs.empty():
                        self.log(logs[0], SSC_WARNING)
            # /* *********************************************************************************************
            # Run Simulation
            # *********************************************************************************************** */
            var p_gen: Pointer[ssc_number_t] = self.allocate("gen", p_ac.size)
            var year: Int = 0
            var hour: Int = 0
            var count: Int = 0
            for year in range(batt.nyears):
                for hour in range(8760):
                    for jj in range(batt.step_per_hour):
                        batt.initialize_time(year, hour, jj)
                        if resilience:
                            resilience.add_battery_at_outage_timestep(batt.dispatch_model, count)
                            resilience.run_surviving_batteries(p_crit_load[count % n_rec_single_year], p_ac[count])
                        batt.outGenWithoutBattery[count] = p_ac[count]
                        batt.advance(self.m_vartab, p_ac[count], voltage, p_load[count])
                        p_gen[count] = batt.outGenPower[count]
                        count += 1
            batt.calculate_monthly_and_annual_outputs(self)
            if resilience:
                resilience.run_surviving_batteries_by_looping(&p_crit_load[0], &p_ac[0])
                calculate_resilience_outputs(self, resilience)
        else:
            self.assign("average_battery_roundtrip_efficiency", var_data(ssc_number_t(0.0)))

# DEFINE_MODULE_ENTRY(battwatts, "simple battery model", 1)
# In Mojo, we need to define a module entry point. Usually a function with @register_passable.
# We'll assume a module entry macro that sets up.
def battwatts_module_entry() -> None:

# The macro may be replaced by a decorator or registration.
# For faithfulness, we'll just define the function name as the module entry.