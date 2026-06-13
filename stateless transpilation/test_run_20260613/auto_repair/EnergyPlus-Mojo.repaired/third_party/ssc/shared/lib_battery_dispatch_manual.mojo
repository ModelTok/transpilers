"""
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
"""
from lib_battery_dispatch import dispatch_t
from lib_battery_powerflow import *
from math import *

"""
Manual dispatch class
"""

@value
struct dispatch_manual_t(dispatch_t):
    var _sched: matrix_t[size_t]
    var _sched_weekend: matrix_t[size_t]
    var _charge_array: List[bool]
    var _discharge_array: List[bool]
    var _gridcharge_array: List[bool]
    var _fuelcellcharge_array: List[bool]
    var _percent_discharge: Float64
    var _percent_charge: Float64
    var _percent_discharge_array: Dict[size_t, Float64]
    var _percent_charge_array: Dict[size_t, Float64]

    def __init__(inout self, Battery: battery_t, dt: Float64, SOC_min: Float64, SOC_max: Float64, current_choice: Int, Ic_max: Float64, Id_max: Float64,
        Pc_max_kwdc: Float64, Pd_max_kwdc: Float64, Pc_max_kwac: Float64, Pd_max_kwac: Float64,
        t_min: Float64, mode: Int, battMeterPosition: Int,
        dm_dynamic_sched: matrix_t[size_t], dm_dynamic_sched_weekend: matrix_t[size_t],
        dm_charge: List[bool], dm_discharge: List[bool], dm_gridcharge: List[bool], dm_fuelcellcharge: List[bool],
        dm_percent_discharge: Dict[size_t, Float64], dm_percent_gridcharge: Dict[size_t, Float64]):
        dispatch_t.__init__(self, Battery, dt, SOC_min, SOC_max, current_choice, Ic_max, Id_max, Pc_max_kwdc, Pd_max_kwdc, Pc_max_kwac, Pd_max_kwac,
            t_min, mode, battMeterPosition)
        self.init_with_vects(dm_dynamic_sched, dm_dynamic_sched_weekend, dm_charge, dm_discharge, dm_gridcharge, dm_fuelcellcharge, dm_percent_discharge, dm_percent_gridcharge)

    def init_with_vects(inout self,
        dm_dynamic_sched: matrix_t[size_t],
        dm_dynamic_sched_weekend: matrix_t[size_t],
        dm_charge: List[bool],
        dm_discharge: List[bool],
        dm_gridcharge: List[bool],
        dm_fuelcellcharge: List[bool],
        dm_percent_discharge: Dict[size_t, Float64],
        dm_percent_gridcharge: Dict[size_t, Float64]):
        self._sched = dm_dynamic_sched
        self._sched_weekend = dm_dynamic_sched_weekend
        self._charge_array = dm_charge
        self._discharge_array = dm_discharge
        self._gridcharge_array = dm_gridcharge
        self._fuelcellcharge_array = dm_fuelcellcharge
        self._percent_discharge_array = dm_percent_discharge
        self._percent_charge_array = dm_percent_gridcharge

    def __init__(inout self, dispatch: dispatch_t):
        dispatch_t.__init__(self, dispatch)
        var tmp = dispatch_manual_t(dispatch)
        self.init_with_vects(tmp._sched, tmp._sched_weekend,
            tmp._charge_array, tmp._discharge_array, tmp._gridcharge_array, tmp._fuelcellcharge_array,
            tmp._percent_discharge_array, tmp._percent_charge_array)

    def copy(inout self, dispatch: dispatch_t):
        dispatch_t.copy(self, dispatch)
        var tmp = dispatch_manual_t(dispatch)
        self.init_with_vects(tmp._sched, tmp._sched_weekend,
            tmp._charge_array, tmp._discharge_array, tmp._gridcharge_array, tmp._fuelcellcharge_array,
            tmp._percent_discharge_array, tmp._percent_charge_array)

    def prepareDispatch(inout self, hour_of_year: size_t, step: size_t):
        var m: size_t
        var h: size_t
        util.month_hour(hour_of_year, m, h)
        var column: size_t = h - 1
        var iprofile: size_t = 0
        var is_weekday: bool = util.weekday(hour_of_year)
        if not is_weekday and self._mode == MANUAL:
            iprofile = self._sched_weekend[m - 1, column]
        else:
            iprofile = self._sched[m - 1, column]  # 1-based
        self.m_batteryPower.canSystemCharge = self._charge_array[iprofile - 1]
        self.m_batteryPower.canDischarge = self._discharge_array[iprofile - 1]
        self.m_batteryPower.canGridCharge = self._gridcharge_array[iprofile - 1]
        if iprofile < len(self._fuelcellcharge_array):
            self.m_batteryPower.canFuelCellCharge = self._fuelcellcharge_array[iprofile - 1]
        self._percent_discharge = 0.0
        self._percent_charge = 0.0
        if self.m_batteryPower.canDischarge:
            self._percent_discharge = self._percent_discharge_array[iprofile]
        if self.m_batteryPower.canSystemCharge or self.m_batteryPower.canFuelCellCharge:
            self._percent_charge = 100.0
        if self.m_batteryPower.canGridCharge:
            self._percent_charge = self._percent_charge_array[iprofile]

    def dispatch(inout self, year: size_t,
        hour_of_year: size_t,
        step: size_t):
        self.prepareDispatch(hour_of_year, step)
        self.m_batteryPowerFlow.initialize(self._Battery.SOC())
        self.runDispatch(year, hour_of_year, step)

    def check_constraints(inout self, I: Float64, count: size_t) -> bool:
        var iterate: bool = dispatch_t.check_constraints(self, I, count)
        if not iterate:
            var I_initial: Float64 = I
            iterate = True
            if self.m_batteryPower.powerSystemToGrid > low_tolerance and \
                self.m_batteryPower.canSystemCharge and \
                self._Battery.SOC() < self.m_batteryPower.stateOfChargeMax - 1.0 and \
                fabs(I) < fabs(self.m_batteryPower.currentChargeMax) and \
                fabs(self.m_batteryPower.powerBatteryDC) < (self.m_batteryPower.powerBatteryChargeMaxDC - 1.0) and \
                I <= 0:
                var dI: Float64 = 0.0
                if fabs(self.m_batteryPower.powerBatteryDC) < tolerance:
                    dI = (self.m_batteryPower.powerSystemToGrid * util.kilowatt_to_watt / self._Battery.V())
                else:
                    dI = (self.m_batteryPower.powerSystemToGrid / fabs(self.m_batteryPower.powerBatteryAC)) * fabs(I)
                var dQ: Float64 = 0.01 * (self.m_batteryPower.stateOfChargeMax - self._Battery.SOC()) * \
                    self._Battery.charge_maximum_lifetime()
                I -= fmin(dI, dQ / self._dt_hour)
            elif self.m_batteryPower.meterPosition == dispatch_t.BEHIND and I < 0 and self.m_batteryPower.powerGridToLoad > tolerance and \
                self.m_batteryPower.powerSystemToBattery > 0:
                var dP: Float64 = self.m_batteryPower.powerGridToLoad
                if dP > self.m_batteryPower.powerSystemToBattery:
                    dP = self.m_batteryPower.powerSystemToBattery
                var dI: Float64 = 0.0
                if dP < tolerance:
                    dI = dP / self._Battery.V()
                else:
                    dI = (dP / fabs(self.m_batteryPower.powerBatteryAC)) * fabs(I)
                I += dI
            elif self.m_batteryPower.meterPosition == dispatch_t.BEHIND and I > 0 and self.m_batteryPower.powerBatteryToGrid > tolerance:
                if fabs(self.m_batteryPower.powerBatteryAC) < tolerance:
                    I -= (self.m_batteryPower.powerBatteryToGrid * util.kilowatt_to_watt / self._Battery.V())
                else:
                    I -= (self.m_batteryPower.powerBatteryToGrid / fabs(self.m_batteryPower.powerBatteryAC)) * fabs(I)
            else:
                iterate = False
            var current_iterate: bool = self.restrict_current(I)
            var power_iterate: bool = self.restrict_power(I)
            if iterate or current_iterate or power_iterate:
                iterate = True
            if count > battery_dispatch.constraintCount:
                iterate = False
            if (I_initial / I) < 0:
                I = 0
            if iterate:
                self._Battery.set_state(self._Battery_initial.get_state())
                self.m_batteryPower.powerBatteryAC = 0
                self.m_batteryPower.powerGridToBattery = 0
                self.m_batteryPower.powerBatteryToGrid = 0
                self.m_batteryPower.powerSystemToGrid = 0
        return iterate

    def SOC_controller(inout self):
        if self.m_batteryPower.powerBatteryDC > 0:
            self._charging = False
            if self.m_batteryPower.powerBatteryDC * self._dt_hour > self._e_max:
                self.m_batteryPower.powerBatteryDC = self._e_max / self._dt_hour
            var e_percent: Float64 = self._e_max * self._percent_discharge * 0.01
            if self.m_batteryPower.powerBatteryDC * self._dt_hour > e_percent:
                self.m_batteryPower.powerBatteryDC = e_percent / self._dt_hour
        elif self.m_batteryPower.powerBatteryDC < 0:
            self._charging = True
            if self.m_batteryPower.powerBatteryDC * self._dt_hour < -self._e_max:
                self.m_batteryPower.powerBatteryDC = -self._e_max / self._dt_hour
            var e_percent: Float64 = self._e_max * self._percent_charge * 0.01
            if fabs(self.m_batteryPower.powerBatteryDC) > fabs(e_percent) / self._dt_hour:
                self.m_batteryPower.powerBatteryDC = -e_percent / self._dt_hour
        else:
            self._charging = self._prev_charging