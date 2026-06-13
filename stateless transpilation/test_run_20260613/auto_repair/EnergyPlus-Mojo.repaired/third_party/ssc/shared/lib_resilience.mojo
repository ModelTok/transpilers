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

from lib_shared_inverter import SharedInverter, CONNECTION
from lib_battery_dispatch import dispatch_t
from lib_battery_powerflow import battstor
from cmod_battery import battstor_vars  # if needed, adjust import

from utils import Pointer, SharedPtr
from math import abs, max, min
from builtins import Int, Float64, Bool, String, List, Dict, Error
from memory import Pointer  # for raw pointer usage

# ------------------------------------------------------------------------------
# class dispatch_resilience
# ------------------------------------------------------------------------------
class dispatch_resilience(dispatch_t):
    """
    *
    * \class dispatch_resilience
    *
    *  Dispatches the battery when the grid is unavailable is during an outage.
    *
    *  The battery model is run according to the purpose of meeting a critical load for as many time steps as possible.
    *  Normal operational limits such as min/max state-of-charge and dis/charging power and current are disregarded.
    *
    *  A fully-initialized dispatch_t instance is required to construct a dispatch_resilience. The original dispatch_t's
    *  dispatch algorithm is not used, but its underlying models (capacity, voltage, inverter for DC-connected batteries, etc)
    *  and certain dispatch parameters (conversion efficiencies, connection mode, time interval) are required.
    *
    * The start_outage_index is the time step at which the outage starts. Each time one of the run_outage_step functions are
    * run, met_loads_kw is updated and if the battery system meets the critical load, the current_outage_index is incremented.
    *
    """
    var connection: CONNECTION
    var start_outage_index: Int
    var current_outage_index: Int
    var met_loads_kw: Float64
    var inverter: Pointer[SharedInverter]

    def __init__(self, orig: dispatch_t, start_index: Int):
        dispatch_t.__init__(self, orig)  # call base
        self.connection = CONNECTION(self.m_batteryPower.connectionMode)
        self.start_outage_index = start_index
        self.inverter = Pointer[SharedInverter]()  # null
        if self.connection == CONNECTION.DC_CONNECTED:
            self.inverter = Pointer[SharedInverter](SharedInverter(*self.m_batteryPower.sharedInverter))
        self.current_outage_index = start_outage_index
        self.met_loads_kw = 0.0
        self.m_batteryPower.canClipCharge = True
        self.m_batteryPower.canSystemCharge = True
        self.m_batteryPower.canGridCharge = False
        self.m_batteryPower.canDischarge = True
        self._Battery.changeSOCLimits(0.0, 100.0)
        self.m_batteryPower.stateOfChargeMin = 0
        self.m_batteryPower.stateOfChargeMax = 100

    def __del__(self):
        # destructor not needed in Mojo; memory management automatic

    def run_outage_step_ac(self, crit_load_kwac: Float64, pv_kwac: Float64) -> Bool:
        if self.connection != CONNECTION.AC_CONNECTED:
            raise Error("Error in resilience::run_outage_step_ac: called for battery with DC connection.")
        var battery_dispatched_kwac: Float64 = 0.0
        var max_discharge_kwdc: Float64 = self._Battery.calculate_max_discharge_kw()
        var max_discharge_kwac: Float64 = max_discharge_kwdc * self.m_batteryPower.singlePointEfficiencyDCToDC
        var max_charge_kwdc: Float64 = self._Battery.calculate_max_charge_kw()
        var met_load: Float64
        if pv_kwac > crit_load_kwac:
            var remaining_kwdc: Float64 = -(pv_kwac - crit_load_kwac) * self.m_batteryPower.singlePointEfficiencyACToDC
            remaining_kwdc = max(remaining_kwdc, max_charge_kwdc)
            self.dispatch_kw(remaining_kwdc)
            met_load = crit_load_kwac
        else:
            var max_to_load_kwac: Float64 = max_discharge_kwac + pv_kwac
            var required_kwdc: Float64 = (crit_load_kwac - pv_kwac) / self.m_batteryPower.singlePointEfficiencyDCToAC
            required_kwdc = min(required_kwdc, max_discharge_kwdc)
            if max_to_load_kwac > crit_load_kwac:
                var discharge_kwdc: Float64 = required_kwdc
                var Battery_initial = self._Battery.get_state()
                var battery_dispatched_kwdc: Float64 = self.dispatch_kw(discharge_kwdc)
                if abs(battery_dispatched_kwdc - required_kwdc) > tolerance:
                    while discharge_kwdc < max_discharge_kwdc:
                        if battery_dispatched_kwdc - required_kwdc > tolerance:
                            break
                        discharge_kwdc *= 1.01
                        self._Battery.set_state(Battery_initial)
                        battery_dispatched_kwdc = self.dispatch_kw(discharge_kwdc)
                battery_dispatched_kwac = battery_dispatched_kwdc * self.m_batteryPower.singlePointEfficiencyDCToAC
            else:
                battery_dispatched_kwac = self.dispatch_kw(max_discharge_kwdc) * self.m_batteryPower.singlePointEfficiencyDCToAC
            met_load = battery_dispatched_kwac + pv_kwac
        var unmet_load: Float64 = crit_load_kwac - met_load
        self.met_loads_kw += met_load
        var survived: Bool = unmet_load < tolerance
        if survived:
            self.current_outage_index += 1
        return survived

    def run_outage_step_dc(self, crit_load_kwac: Float64, pv_kwdc: Float64, V_pv: Float64, pv_clipped: Float64, tdry: Float64) -> Bool:
        if self.connection != CONNECTION.DC_CONNECTED:
            raise Error("Error in resilience::run_outage_step_dc: called for battery with AC connection.")
        var dc_dc_eff: Float64 = self.m_batteryPower.singlePointEfficiencyDCToDC
        self.inverter.calculateACPower(pv_kwdc, V_pv, tdry)
        var dc_ac_eff: Float64 = self.inverter.efficiencyAC * 0.01
        var pv_kwac: Float64 = self.inverter.powerAC_kW
        var battery_dispatched_kwdc: Float64
        var battery_dispatched_kwac: Float64
        var max_discharge_kwdc: Float64 = self._Battery.calculate_max_discharge_kw()
        var max_charge_kwdc: Float64 = self._Battery.calculate_max_charge_kw()
        var met_load: Float64
        if pv_kwac > crit_load_kwac:
            var remaining_kwdc: Float64 = -(pv_kwac - crit_load_kwac) / dc_ac_eff + pv_clipped
            remaining_kwdc = max(remaining_kwdc / dc_dc_eff, max_charge_kwdc)
            self.dispatch_kw(remaining_kwdc)
            met_load = crit_load_kwac
        else:
            var required_kwdc: Float64 = (self.inverter.calculateRequiredDCPower(crit_load_kwac, V_pv, tdry) - pv_kwdc) / dc_dc_eff
            if required_kwdc < max_discharge_kwdc:
                required_kwdc = min(required_kwdc, max_discharge_kwdc)
                var required_kwac: Float64 = required_kwdc * self.inverter.efficiencyAC * 0.01 * dc_dc_eff
                var discharge_kwdc: Float64 = required_kwdc
                var Battery_initial = self._Battery.get_state()
                battery_dispatched_kwdc = self.dispatch_kw(discharge_kwdc)
                self.inverter.calculateACPower(battery_dispatched_kwdc * dc_dc_eff, V_pv, tdry)
                battery_dispatched_kwac = self.inverter.powerAC_kW
                if abs(battery_dispatched_kwac - required_kwac) > tolerance:
                    while discharge_kwdc < max_discharge_kwdc:
                        if battery_dispatched_kwac - required_kwac > tolerance:
                            break
                        discharge_kwdc *= 1.01
                        self._Battery.set_state(Battery_initial)
                        battery_dispatched_kwdc = self.dispatch_kw(discharge_kwdc)
                        self.inverter.calculateACPower(battery_dispatched_kwdc * dc_dc_eff, V_pv, tdry)
                        battery_dispatched_kwac = self.inverter.powerAC_kW
            else:
                battery_dispatched_kwdc = self.dispatch_kw(max_discharge_kwdc)
                self.inverter.calculateACPower(battery_dispatched_kwdc * dc_dc_eff, V_pv, tdry)
                battery_dispatched_kwac = self.inverter.powerAC_kW
            met_load = battery_dispatched_kwac + pv_kwac
        var unmet_load: Float64 = crit_load_kwac - met_load
        self.met_loads_kw += met_load
        var survived: Bool = unmet_load < tolerance
        if survived:
            self.current_outage_index += 1
        return survived

    def get_indices_survived(self) -> Int:
        return self.current_outage_index - self.start_outage_index

    def get_met_loads(self) -> Float64:
        return self.met_loads_kw

    def dispatch_kw(self, kw: Float64) -> Float64:
        if kw == 0.0:
            return 0.0
        var charging_current: Float64 = self._Battery.calculate_current_for_power_kw(kw)
        var power_dc: Float64 = self._Battery.run(self.current_outage_index, charging_current)
        if abs(kw - power_dc) < tolerance:
            return kw
        return power_dc

    def dispatch(self, a: Int, b: Int, c: Int):

# ------------------------------------------------------------------------------
# class resilience_runner
# ------------------------------------------------------------------------------
class resilience_runner:
    """
    *
    * \class resilience_runner
    *
    *  Maintains a collection of batteries operating for resilience (no grid access, access to renewable energy sources)
    *  organized by the starting time step of the outage, for calculating annual or lifetime statistics about hours of
    *  autonomy and total met loads for a battery system design.
    *
    *  An example from cmod_battwatts.cpp for calculating how a battery would respond if an outage occurred at every time step
    *  of the simulation. This is done by simulating the original battery system as it steps through the entire simulation
    *  while adding a copy of the dispatch_t to resilience_runner for simulating outage conditions. After the annual simulation
    *  is complete, the battery added at the last time step (and likely several of the ones added before that) is still
    *  surviving so run_surviving_batteries_by_looping simulates how many hours the batteries still surviving would last until
    *  the next year assuming the critical load and pv production is exactly the same.
    *
    *    for (hour = 0; hour < 8760; hour++)
    *    {
    *       for (size_t jj = 0; jj < batt->step_per_hour; jj++)
    *       {
    *           batt->initialize_time(year, hour, jj);
    *
    *           resilience->add_battery_at_outage_timestep(*batt->dispatch_model, count);
    *           resilience->run_surviving_batteries(p_crit_load[count % n_rec_single_year], p_ac[count]);
    *
    *           batt->advance(m_vartab, p_ac[count], voltage, p_load[count]);
    *           p_gen[count] = batt->outGenPower[count];
    *           count++;
    *       }
    *    }
    *
    *    resilience->run_surviving_batteries_by_looping(&p_crit_load[0], &p_ac[0]);
    *
    *  Provides metrics for the total load met and the time steps survived for each outage.
    """
    var batt: SharedPtr[battstor]
    var battery_per_outage_start: Dict[Int, SharedPtr[dispatch_resilience]]
    var indices_survived: List[Int]
    var total_load_met: List[Float64]
    var outage_durations: List[Float64]
    var probs_of_surviving: List[Float64]
    var logs: List[String]

    def __init__(self, battery: SharedPtr[battstor]):
        self.batt = battery
        var steps_lifetime: Int = battery.step_per_hour * battery.nyears * 8760
        self.indices_survived = List[Int](steps_lifetime, 0)
        self.total_load_met = List[Float64](steps_lifetime, 0.0)
        self.logs = List[String]()
        self.outage_durations = List[Float64]()
        self.probs_of_surviving = List[Float64]()
        self.battery_per_outage_start = Dict[Int, SharedPtr[dispatch_resilience]]()

    def get_logs(self) -> List[String]:
        return self.logs

    def add_battery_at_outage_timestep(self, orig: dispatch_t, index: Int):
        if index in self.battery_per_outage_start:
            self.logs.append("Replacing battery which already existed at index " + String(index) + ".")
        self.battery_per_outage_start[index] = SharedPtr[dispatch_resilience](dispatch_resilience(orig, index))

    def run_surviving_batteries(self, crit_loads_kwac: Float64, pv_kwac: Float64,
                                pv_kwdc: Float64 = 0.0, V: Float64 = 0.0,
                                pv_clipped_kw: Float64 = 0.0, tdry_c: Float64 = 0.0):
        # Assume batt.batt_vars is accessible
        if self.batt.batt_vars.batt_topology == dispatch_resilience.DC_CONNECTED:
            if self.batt.batt_vars.inverter_paco * self.batt.batt_vars.inverter_count < crit_loads_kwac:
                self.logs.append("For DC-connected battery, maximum inverter AC Power less than max load will lead to dropped load.")
        var depleted_battery_keys: List[Int] = List[Int]()
        for key, value in self.battery_per_outage_start.items():
            var start_index: Int = key
            var batt_system: SharedPtr[dispatch_resilience] = value
            var survived: Bool
            if batt_system.connection == dispatch_resilience.DC_CONNECTED:
                survived = batt_system.run_outage_step_dc(crit_loads_kwac, pv_kwdc, V, pv_clipped_kw, tdry_c)
            else:
                survived = batt_system.run_outage_step_ac(crit_loads_kwac, pv_kwac)
            if not survived:
                depleted_battery_keys.append(start_index)
                self.indices_survived[start_index] = batt_system.get_indices_survived()
        for key in depleted_battery_keys:
            var b: SharedPtr[dispatch_resilience] = self.battery_per_outage_start[key]
            self.indices_survived[key] = b.get_indices_survived()
            self.total_load_met[key] = b.get_met_loads()
            self.battery_per_outage_start.erase(key)

    def run_surviving_batteries_by_looping(self, crit_loads_kwac: Pointer[Float64], pv_kwac: Pointer[Float64],
                                          pv_kwdc: Pointer[Float64] = None, V: Pointer[Float64] = None,
                                          pv_clipped_kw: Pointer[Float64] = None, tdry_c: Pointer[Float64] = None):
        var nrec: Int = self.batt.step_per_year
        var steps_lifetime: Int = nrec * self.batt.nyears
        var i: Int = 0
        while self.get_n_surviving_batteries() > 0 and i < steps_lifetime:
            if pv_kwdc is not None and V is not None and pv_clipped_kw is not None and tdry_c is not None:
                self.run_surviving_batteries(crit_loads_kwac[i % nrec], pv_kwac[i],
                                             pv_kwdc[i], V[i], pv_clipped_kw[i], tdry_c[i % nrec])
            else:
                self.run_surviving_batteries(crit_loads_kwac[i % nrec], pv_kwac[i])
            i += 1
        if self.battery_per_outage_start.is_empty():
            return
        var total_load: Float64 = 0.0
        for j in range(nrec):
            total_load += crit_loads_kwac[j]
        total_load *= Float64(self.batt.nyears)
        for key, value in self.battery_per_outage_start.items():
            self.indices_survived[key] = steps_lifetime
            self.total_load_met[key] = total_load
        self.battery_per_outage_start.clear()

    def compute_metrics(self) -> Float64:
        self.outage_durations.clear()
        self.probs_of_surviving.clear()
        var hrs_total: Float64 = Float64(self.batt.step_per_hour) * 8760.0 * Float64(self.batt.nyears)
        # copy indices_survived to outage_durations as Float64
        self.outage_durations = List[Float64]()
        for val in self.indices_survived:
            self.outage_durations.append(Float64(val))
        # sort
        self.outage_durations.sort()
        # unique
        var unique_durations: List[Float64] = List[Float64]()
        for val in self.outage_durations:
            if unique_durations.is_empty() or val != unique_durations[-1]:
                unique_durations.append(val)
        self.outage_durations = unique_durations
        for dur in self.outage_durations:
            var count_val: Float64 = Float64(self.indices_survived.count(Int(dur)))
            var prob: Float64 = count_val / hrs_total
            # convert to hours
            self.outage_durations[self.outage_durations.index_of(dur)] = dur / Float64(self.batt.step_per_hour)
            self.probs_of_surviving.append(prob)
        var total_survived: Float64 = 0.0
        for val in self.indices_survived:
            total_survived += Float64(val)
        return total_survived / Float64(self.batt.step_per_hour) / Float64(self.indices_survived.len)

    def get_n_surviving_batteries(self) -> Int:
        return self.battery_per_outage_start.len

    def get_hours_survived(self) -> List[Float64]:
        var hours_per_step: Float64 = 1.0 / Float64(self.batt.step_per_hour)
        var hours_survived: List[Float64] = List[Float64]()
        for val in self.indices_survived:
            hours_survived.append(Float64(val) * hours_per_step)
        return hours_survived

    def get_avg_crit_load_kwh(self) -> Float64:
        var total: Float64 = 0.0
        for val in self.total_load_met:
            total += val
        return total / Float64(self.total_load_met.len * self.batt.step_per_hour)

    def get_outage_duration_hrs(self) -> List[Float64]:
        return self.outage_durations

    def get_probs_of_surviving(self) -> List[Float64]:
        return self.probs_of_surviving

    def get_cdf_of_surviving(self) -> List[Float64]:
        var cum_prob: List[Float64] = List[Float64]()
        cum_prob.append(self.probs_of_surviving[0])
        for i in range(1, self.probs_of_surviving.len):
            cum_prob.append(self.probs_of_surviving[i] + cum_prob[i - 1])
        return cum_prob

    def get_survival_function(self) -> List[Float64]:
        var survival_fx: List[Float64] = List[Float64]()
        survival_fx.append(1.0 - self.probs_of_surviving[0])
        for i in range(1, self.probs_of_surviving.len):
            survival_fx.append(survival_fx[i - 1] - self.probs_of_surviving[i])
        if survival_fx[-1] < 1e-7:
            survival_fx[-1] = 0.0
        return survival_fx