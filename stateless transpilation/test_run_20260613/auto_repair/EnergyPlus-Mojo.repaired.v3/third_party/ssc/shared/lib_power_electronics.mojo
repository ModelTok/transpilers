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

from lib_battery_dispatch import dispatch_t, BatteryPower
from lib_battery_powerflow import battery_metrics_t
from lib_shared_inverter import SharedInverter
from memory import new, destroy
from pointer import Pointer

struct BatteryBidirectionalInverter:
    var _dc_ac_efficiency: Float64
    var _ac_dc_efficiency: Float64
    var _loss_dc_ac: Float64
    var _loss_ac_dc: Float64

    def __init__(inout self, ac_dc_efficiency: Float64, dc_ac_efficiency: Float64):
        self._dc_ac_efficiency = 0.01 * dc_ac_efficiency
        self._ac_dc_efficiency = 0.01 * ac_dc_efficiency

    def dc_ac_efficiency(self) -> Float64:
        return self._dc_ac_efficiency

    def ac_dc_efficiency(self) -> Float64:
        return self._ac_dc_efficiency

    def convert_to_dc(inout self, P_ac: Float64, P_dc: Pointer[Float64]) -> Float64:
        var P_loss = P_ac * (1 - self._ac_dc_efficiency)
        P_dc[0] = P_ac * self._ac_dc_efficiency
        return P_loss

    def convert_to_ac(inout self, P_dc: Float64, P_ac: Pointer[Float64]) -> Float64:
        var P_loss = P_dc * (1 - self._dc_ac_efficiency)
        P_ac[0] = P_dc * self._dc_ac_efficiency
        return P_loss

    def compute_dc_from_ac(self, P_ac: Float64) -> Float64:
        return P_ac / self._dc_ac_efficiency


struct Battery_DC_DC_ChargeController:
    var _batt_dc_dc_bms_efficiency: Float64
    var _pv_dc_dc_mppt_efficiency: Float64
    var _loss_dc_dc: Float64

    def __init__(inout self, batt_dc_dc_bms_efficiency: Float64, pv_dc_dc_mppt_efficiency: Float64):
        self._batt_dc_dc_bms_efficiency = 0.01 * batt_dc_dc_bms_efficiency
        self._pv_dc_dc_mppt_efficiency = 0.01 * pv_dc_dc_mppt_efficiency

    def batt_dc_dc_bms_efficiency(self) -> Float64:
        return self._batt_dc_dc_bms_efficiency

    def pv_dc_dc_mppt_efficiency(self) -> Float64:
        return self._pv_dc_dc_mppt_efficiency


struct BatteryRectifier:
    var _ac_dc_efficiency: Float64
    var _loss_dc_ac: Float64

    def __init__(inout self, ac_dc_efficiency: Float64):
        self._ac_dc_efficiency = 0.01 * ac_dc_efficiency

    def ac_dc_efficiency(self) -> Float64:
        return self._ac_dc_efficiency

    def convert_to_dc(inout self, P_ac: Float64, P_dc: Pointer[Float64]) -> Float64:
        var P_loss = P_ac * (1 - self._ac_dc_efficiency)
        P_dc[0] = P_ac * self._ac_dc_efficiency
        return P_loss


@value
struct ChargeController:
    var m_batteryPower: Pointer[BatteryPower]
    var m_batteryMetrics: Pointer[battery_metrics_t]
    var m_dispatch: Pointer[dispatch_t]

    enum CONNECTION:
        DC_CONNECTED = 0
        AC_CONNECTED = 1

    def __init__(inout self, dispatch: Pointer[dispatch_t], battery_metrics: Pointer[battery_metrics_t]):
        self.m_batteryMetrics = battery_metrics
        self.m_dispatch = dispatch

    def __del__(owned self):

    def dispatch_model(self) -> Pointer[dispatch_t]:
        return self.m_dispatch

    def run(inout self, year: UInt, hour_of_year: UInt, step_of_hour: UInt, index: UInt):

struct ACBatteryController:
    var m_batteryPower: Pointer[BatteryPower]
    var m_batteryMetrics: Pointer[battery_metrics_t]
    var m_dispatch: Pointer[dispatch_t]
    var m_bidirectionalInverter: Pointer[BatteryBidirectionalInverter]

    def __init__(inout self, dispatch: Pointer[dispatch_t], battery_metrics: Pointer[battery_metrics_t], efficiencyACToDC: Float64, efficiencyDCToAC: Float64):
        self.m_batteryMetrics = battery_metrics
        self.m_dispatch = dispatch
        self.m_bidirectionalInverter = new[BatteryBidirectionalInverter](efficiencyACToDC, efficiencyDCToAC)
        self.m_batteryPower = dispatch[].getBatteryPower()
        self.m_batteryPower[].connectionMode = ChargeController.CONNECTION.AC_CONNECTED()
        self.m_batteryPower[].singlePointEfficiencyACToDC = self.m_bidirectionalInverter[].ac_dc_efficiency()
        self.m_batteryPower[].singlePointEfficiencyDCToAC = self.m_bidirectionalInverter[].dc_ac_efficiency()

    def __del__(owned self):
        destroy(self.m_bidirectionalInverter)

    def dispatch_model(self) -> Pointer[dispatch_t]:
        return self.m_dispatch

    def run(inout self, year: UInt, hour_of_year: UInt, step_of_hour: UInt, index: UInt):
        if self.m_batteryPower[].powerSystem < 0:
            self.m_batteryPower[].powerPVInverterDraw = self.m_batteryPower[].powerSystem
            self.m_batteryPower[].powerSystem = 0

        self.m_batteryPower[].powerSystemThroughSharedInverter = 0
        self.m_batteryPower[].powerSystemClipped = 0
        self.m_dispatch[].dispatch(year, hour_of_year, step_of_hour)
        self.m_batteryMetrics[].compute_metrics_ac(self.m_dispatch[].getBatteryPower())


struct DCBatteryController:
    var m_batteryPower: Pointer[BatteryPower]
    var m_batteryMetrics: Pointer[battery_metrics_t]
    var m_dispatch: Pointer[dispatch_t]
    var m_DCDCChargeController: Pointer[Battery_DC_DC_ChargeController]

    def __init__(inout self, dispatch: Pointer[dispatch_t], battery_metrics: Pointer[battery_metrics_t], efficiencyDCToDC: Float64, inverterEfficiencyCutoff: Float64):
        self.m_batteryMetrics = battery_metrics
        self.m_dispatch = dispatch
        self.m_DCDCChargeController = new[Battery_DC_DC_ChargeController](efficiencyDCToDC, 100)
        self.m_batteryPower = dispatch[].getBatteryPower()
        self.m_batteryPower[].connectionMode = ChargeController.CONNECTION.DC_CONNECTED()
        self.m_batteryPower[].singlePointEfficiencyDCToDC = self.m_DCDCChargeController[].batt_dc_dc_bms_efficiency()
        self.m_batteryPower[].inverterEfficiencyCutoff = inverterEfficiencyCutoff

    def __del__(owned self):
        destroy(self.m_DCDCChargeController)

    def dispatch_model(self) -> Pointer[dispatch_t]:
        return self.m_dispatch

    def setSharedInverter(inout self, sharedInverter: Pointer[SharedInverter]):
        self.m_batteryPower[].setSharedInverter(sharedInverter)

    def run(inout self, year: UInt, hour_of_year: UInt, step_of_hour: UInt, index: UInt):
        if self.m_batteryPower[].powerSystem < 0:
            self.m_batteryPower[].powerSystem = 0

        self.m_batteryPower[].powerSystemThroughSharedInverter = self.m_batteryPower[].powerSystem
        self.m_dispatch[].dispatch(year, hour_of_year, step_of_hour)
        self.m_batteryMetrics[].compute_metrics_ac(self.m_dispatch[].getBatteryPower())