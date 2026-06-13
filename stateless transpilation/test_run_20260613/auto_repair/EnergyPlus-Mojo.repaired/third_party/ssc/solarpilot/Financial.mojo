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

from definitions import *
from Financial.h import mod_base  # Note: mod_base should be available; actual import path TBD
from SolarField import SolarField  # Not directly used but may be needed

from math import exp, pow
from memory import DynamicVector

struct Financial(mod_base):
    var _tower_cost: Float64
    var _rec_cost: Float64
    var _site_cost: Float64
    var _heliostat_cost: Float64
    var _wiring_cost: Float64
    var _contingency_cost: Float64
    var _total_direct_cost: Float64
    var _total_indirect_cost: Float64
    var _land_cost: Float64
    var _sales_tax_cost: Float64
    var _total_installed_cost: Float64
    var _pricing_array: DynamicVector[Float64]
    var _schedule_array: DynamicVector[Int32]
    var _var_fin: var_financial  # from definitions

    def Create(self, inout V: var_map):
        self._var_fin = V.fin
        self.updateCalculatedParameters(V)

    def updateCalculatedParameters(self, inout V: var_map):
        if V.fin.pricing_array.Val().size() < 2:
            self.CreateHourlyTODSchedule(V)
            V.fin.pricing_array.Setval(self._pricing_array)
            V.fin.schedule_array.Setval(self._schedule_array)
        else:
            self._pricing_array = V.fin.pricing_array.Val()
            self._schedule_array = V.fin.schedule_array.Val()
        self.calcPlantCapitalCost(V)
        self._var_fin.schedule_array.Setval(self._schedule_array)
        self._var_fin.pricing_array.Setval(self._pricing_array)
        self._var_fin.tower_cost.Setval(self._tower_cost)
        self._var_fin.rec_cost.Setval(self._rec_cost)
        self._var_fin.site_cost.Setval(self._site_cost)
        self._var_fin.heliostat_cost.Setval(self._heliostat_cost)
        self._var_fin.wiring_cost.Setval(self._wiring_cost)
        self._var_fin.contingency_cost.Setval(self._contingency_cost)
        self._var_fin.total_direct_cost.Setval(self._total_direct_cost)
        self._var_fin.total_indirect_cost.Setval(self._total_indirect_cost)
        self._var_fin.land_cost.Setval(self._land_cost)
        self._var_fin.sales_tax_cost.Setval(self._sales_tax_cost)
        self._var_fin.total_installed_cost.Setval(self._total_installed_cost)

    def getPricingArray(self) -> DynamicVector[Float64]:
        return self._pricing_array

    def getScheduleArray(self) -> DynamicVector[Int32]:
        return self._schedule_array

    def CreateHourlyTODSchedule(self, inout V: var_map):
        """ 
        Take a schedule (12x24 = 288) of the TOD factors in string form and convert them into 
        an 8760 schedule of integers indicating the TOD factor for each hour of the year.
        Assume the year starts on a Sunday
        """
        var nwd: Int32 = V.fin.weekday_sched.val.size()
        var nwe: Int32 = V.fin.weekend_sched.val.size()
        if nwd != 288 or nwe != 288:
            return
        var monthlength: StaticArray[Int32, 12] = StaticArray[Int32, 12](31,28,31,30,31,30,31,31,30,31,30,31)
        self._schedule_array = DynamicVector[Int32]()
        self._schedule_array.resize(8760)
        self._pricing_array = DynamicVector[Float64]()
        self._pricing_array.resize(8760)
        var h: Int32 = 0
        var tod: Int32
        var dow: Int32 = 6   # M=0, T=1; W=2; Th=3; Fr=4, Sa=5; Su=6. Start on a Sunday
        var ss: String
        for i in range(12):
            for j in range(monthlength[i]):
                for k in range(24):
                    ss = V.fin.weekday_sched.val.at(i*24+k) if dow<5 else V.fin.weekend_sched.val.at(i*24+k)
                    to_integer(ss, &tod)   # expects to_integer from definitions
                    self._schedule_array[h] = tod
                    self._pricing_array[h] = V.fin.pmt_factors.val.at(tod-1)
                    h += 1
                if dow == 6:
                    dow = 0
                else:
                    dow += 1

    def calcPlantCapitalCost(self, inout V: var_map):
        var Asf: Float64 = V.sf.sf_area.Val()
        var Arec: Float64 = V.sf.rec_area.Val()
        self._tower_cost = V.fin.tower_fixed_cost.val * exp(V.sf.tht.val * V.fin.tower_exp.val)
        self._rec_cost = V.fin.rec_ref_cost.val * pow(Arec / V.fin.rec_ref_area.val, V.fin.rec_cost_exp.val)
        self._site_cost = V.fin.site_spec_cost.val * Asf
        self._heliostat_cost = V.fin.heliostat_spec_cost.val * Asf
        self._wiring_cost = V.fin.wiring_user_spec.val * Asf
        var tdc: Float64 = (
            self._tower_cost +
            self._rec_cost +
            self._heliostat_cost +
            self._wiring_cost +
            V.fin.fixed_cost.val
        )
        self._contingency_cost = V.fin.contingency_rate.val / 100.0 * tdc
        self._total_direct_cost = tdc + self._contingency_cost
        self._land_cost = V.land.land_area.Val() * V.fin.land_spec_cost.val
        self._sales_tax_cost = (
            V.fin.sales_tax_rate.val * V.fin.sales_tax_frac.val * self._total_direct_cost / 1.0e4
        )
        self._total_indirect_cost = (
            self._sales_tax_cost + self._land_cost
        )
        self._total_installed_cost = (
            self._total_direct_cost + self._total_indirect_cost
        )