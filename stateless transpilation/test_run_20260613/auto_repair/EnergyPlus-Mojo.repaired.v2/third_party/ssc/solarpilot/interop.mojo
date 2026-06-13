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

from string_util import *
from mod_base import *
from heliodata import *
from definitions import *
from SolarField import *
from STObject import *
from solpos00 import *
from sort_method import *
from memory import Pointer
from math import sqrt as sqrt_math

alias SP_USE_SOLTRACE = True

class ArrayString:
    var data: List[String]

    def __init__(inout self):
        self.data.clear()

    def __eq__(inout self, array: List[String]) -> Self:
        self.data = array
        return self

    def size(self) -> Int:
        return len(self.data)

    def __getitem__(self, i: Int) -> String:
        return self.data[i]

    def at(self, i: Int) -> String:
        return self.data[i]

    def clear(inout self):
        self.data.clear()

    def Clear(inout self):
        self.data.clear()

    def resize(inout self, newsize: Int):
        self.data.resize(newsize)

    def push_back(inout self, value: String):
        self.data.append(value)

    def Add(inout self, value: String):
        self.data.append(value)

    def back(self) -> String:
        return self.data[-1]

    def Index(self, item: String) -> Int:
        for i in range(len(self.data)):
            if item == self.data[i]:
                return i
        return -1

    def erase(inout self, position: Int) -> Int:
        self.data.pop(position)
        return position

    def begin(self) -> Int:  # returns index for iteration
        return 0

struct par_variable:
    var varname: String
    var display_text: String
    var units: String
    var data_type: String
    var selections: ArrayString
    var choices: ArrayString
    var sim_values: ArrayString
    var linked: Bool
    var layout_required: Bool

    def __init__(inout self):
        self.linked = False
        self.layout_required = False
        self.varname = String()
        self.display_text = String()
        self.units = String()
        self.data_type = String()
        self.selections = ArrayString()
        self.choices = ArrayString()
        self.sim_values = ArrayString()

class multivar:
    var weather_files: ArrayString
    var wf_are_set: Bool  # disabled in base class
    var variables: List[par_variable]
    var current_varpaths: ArrayString

    def __init__(inout self):
        self.wf_are_set = False
        self.variables = List[par_variable]()
        self.current_varpaths = ArrayString()

    def addVar(inout self, var: spbase):
        # Add a variable by reference to its variable map object
        var curind: Int = self.Index(var.name)
        var vback: par_variable
        if curind > 0:
            self.variables.pop(curind)
            self.variables.insert(curind, par_variable())
            vback = self.variables[curind]
        else:
            self.current_varpaths.Add(var.name)
            self.variables.append(par_variable())
            vback = self.variables[-1]
        vback.varname = var.name
        vback.display_text = split(var.name, ".")[0] + ": " + var.short_desc
        vback.units = var.units
        vback.selections.clear()
        if var.name == "ambient.0.weather_file":
            if not self.wf_are_set:
                return
            var ts: String
            var.as_string(ts)
            vback.selections.Add(ts)
            vback.data_type = "location"
            vback.choices.clear()
            for i in range(len(self.weather_files)):
                vback.choices.push_back(self.weather_files[i])
        elif var.ctype == "combo":
            vback.selections.Add(var.as_string())
            vback.data_type = "combo"
            vback.choices.clear()
            var vchoices: List[String] = var.combo_get_choices()
            for i in range(len(vchoices)):
                vback.choices.Add(vchoices[i])
        elif var.ctype == "checkbox":
            var ts: String
            var.as_string(ts)
            vback.selections.Add(ts)
            vback.data_type = "checkbox"
            vback.choices.clear()
            vback.choices.push_back("true")
            vback.choices.push_back("false")
        elif var.ctype == "bool":
            var ts: String
            var.as_string(ts)
            vback.selections.Add(ts)
            vback.data_type = "bool"
            vback.choices.clear()
            vback.choices.push_back("true")
            vback.choices.push_back("false")
        elif var.ctype == "int":
            var ts: String
            var.as_string(ts)
            vback.selections.Add(ts)
            vback.data_type = "int"
        else:  # doubles
            var ts: String
            var.as_string(ts)
            vback.selections.Add(ts)
            vback.data_type = "double"

    def size(self) -> Int:
        return len(self.variables)

    def clear(inout self):
        self.variables.clear()
        self.current_varpaths.Clear()

    def at(inout self, index: Int) -> par_variable:
        return self.variables[index]

    def __getitem__(inout self, index: Int) -> par_variable:
        return self.variables[index]

    def back(inout self) -> par_variable:
        return self.variables[-1]

    def remove(inout self, index: Int):
        self.variables.pop(index)
        self.current_varpaths.erase(self.current_varpaths.begin() + index)

    def Index(self, pathname: String) -> Int:
        return self.current_varpaths.Index(pathname)

class parametric(multivar):
    def __init__(inout self):
        super().__init__()
        self.wf_are_set = False

    def SetWeatherFileList(inout self, list: ArrayString):
        self.weather_files.clear()
        for i in range(list.size()):
            self.weather_files.push_back(list[i])
        self.wf_are_set = True

class optimization(multivar):

class simulation_table:
    var data: Dict[String, ArrayString]

    def __init__(inout self):
        self.data = Dict[String, ArrayString]()

    def __getitem__(inout self, varname: String) -> ArrayString:
        return self.data[varname]

    def at(inout self, varname: String) -> ArrayString:
        return self.data[varname]

    def nvar(self) -> Int:
        return len(self.data)

    def nsim(self) -> Int:
        if len(self.data) > 0:
            return len(self.data.values()[0])
        return 0

    def ClearAll(inout self):
        for key in self.data.keys():
            self.data[key].Clear()
        self.data.clear()

    def getKeys(inout self, keys: ArrayString):
        keys.clear()
        for key in self.data.keys():
            keys.push_back(key)

struct stat_object:
    var min: Float64
    var max: Float64
    var ave: Float64
    var stdev: Float64
    var sum: Float64
    var wtmean: Float64

    def set(inout self, _min: Float64, _max: Float64, _ave: Float64, _stdev: Float64, _sum: Float64, _wtmean: Float64):
        self.min = _min
        self.max = _max
        self.ave = _ave
        self.stdev = _stdev
        self.sum = _sum
        self.wtmean = _wtmean

    def initialize(inout self):
        self.min = 9.0e99
        self.max = -9.0e99
        self.sum = 0.0
        self.stdev = 0.0
        self.ave = 0.0

struct sim_result:
    var _q_coe: Float64
    var data_by_helio: Dict[Int, helio_perf_data]
    var total_heliostat_area: Float64
    var total_receiver_area: Float64
    var total_land_area: Float64
    var power_on_field: Float64
    var power_absorbed: Float64
    var power_thermal_loss: Float64
    var power_piping_loss: Float64
    var power_to_htf: Float64
    var power_to_cycle: Float64
    var power_gross: Float64
    var power_net: Float64
    var dni: Float64
    var solar_az: Float64
    var solar_zen: Float64
    var total_installed_cost: Float64
    var coe_metric: Float64
    var eff_total_heliostat: stat_object
    var eff_total_sf: stat_object
    var eff_cosine: stat_object
    var eff_attenuation: stat_object
    var eff_blocking: stat_object
    var eff_shading: stat_object
    var eff_reflect: stat_object
    var eff_intercept: stat_object
    var eff_absorption: stat_object
    var flux_density: stat_object
    var eff_cloud: stat_object
    var sim_type: Int
    var sim_id: Int
    var num_heliostats_used: Int
    var num_heliostats_avail: Int
    var num_ray_traced: Int
    var num_ray_heliostat: Int
    var num_ray_receiver: Int
    var is_soltrace: Bool
    var receiver_names: List[String]
    var flux_surfaces: List[FluxSurfaces]

    def __init__(inout self):
        self.initialize()

    def initialize(inout self):
        self.total_heliostat_area = 0.0
        self.total_receiver_area = 0.0
        self.total_land_area = 0.0
        self.power_on_field = 0.0
        self.power_absorbed = 0.0
        self.power_thermal_loss = 0.0
        self.power_piping_loss = 0.0
        self.power_to_htf = 0.0
        self.power_to_cycle = 0.0
        self.power_gross = 0.0
        self.power_net = 0.0
        self.num_heliostats_used = 0
        self.num_heliostats_avail = 0
        self.num_ray_traced = 0
        self.num_ray_heliostat = 0
        self.num_ray_receiver = 0
        self._q_coe = 0.0
        self.eff_total_heliostat.initialize()
        self.eff_total_sf.initialize()
        self.eff_cosine.initialize()
        self.eff_attenuation.initialize()
        self.eff_blocking.initialize()
        self.eff_shading.initialize()
        self.eff_reflect.initialize()
        self.eff_intercept.initialize()
        self.eff_absorption.initialize()
        self.eff_cloud.initialize()
        self.flux_density.initialize()
        self.flux_surfaces.clear()
        self.data_by_helio.clear()

    def add_heliostat(inout self, H: Heliostat):
        H.getEfficiencyObject().rec_absorptance = H.getWhichReceiver().getVarMap().absorptance.val
        self.data_by_helio[H.getId()] = *H.getEfficiencyObject()
        self.num_heliostats_used += 1
        self.total_heliostat_area += H.getArea()
        self._q_coe += H.getPowerValue()

    def process_field_stats(inout self):
        if len(self.data_by_helio) == 0:
            return
        var nm: Int = self.data_by_helio.values()[0].n_metric
        var sums: List[Float64] = List[Float64](nm, 0.0)
        var aves: List[Float64] = List[Float64](nm, 0.0)
        var stdevs: List[Float64] = List[Float64](nm, 0.0)
        var mins: List[Float64] = List[Float64](nm, 9.0e9)
        var maxs: List[Float64] = List[Float64](nm, -9.0e9)
        var wtmean: List[Float64] = List[Float64](nm, 0.0)
        var aves2: List[Float64] = List[Float64](nm, 0.0)

        var n: Int = 0
        for it in self.data_by_helio.values():
            n += 1
            for j in range(nm):
                var v: Float64 = it.getDataByIndex(j)
                sums[j] += v
                if v > maxs[j]:
                    maxs[j] = v
                if v < mins[j]:
                    mins[j] = v
                var delta: Float64 = v - aves[j]
                aves[j] += delta / Float64(n)
                aves2[j] += delta * (v - aves[j])

        for j in range(nm):
            stdevs[j] = sqrt_math(aves2[j] / Float64(n - 1))

        var eff_cascade_indices: List[Int] = List[Int](
            helio_perf_data.PERF_VALUES.ETA_CLOUD,
            helio_perf_data.PERF_VALUES.ETA_SHADOW,
            helio_perf_data.PERF_VALUES.ETA_COS,
            helio_perf_data.PERF_VALUES.SOILING,
            helio_perf_data.PERF_VALUES.REFLECTIVITY,
            helio_perf_data.PERF_VALUES.ETA_BLOCK,
            helio_perf_data.PERF_VALUES.ETA_ATT,
            helio_perf_data.PERF_VALUES.ETA_INT,
            helio_perf_data.PERF_VALUES.REC_ABSORPTANCE
        )
        var nh: Int = len(self.data_by_helio)
        var rowprod: List[Float64] = List[Float64](nh, 1.0)
        for i in range(len(eff_cascade_indices)):
            var cascade_index: Int = eff_cascade_indices[i]
            var j: Int = 0
            for it in self.data_by_helio.values():
                rowprod[j] *= it.getDataByIndex(cascade_index)
                j += 1
            for j in range(nh):
                wtmean[cascade_index] += rowprod[j]
            wtmean[cascade_index] /= Float64(nh if nh > 0 else 1)
            for k in range(i):
                wtmean[cascade_index] /= wtmean[eff_cascade_indices[k]]

        self.eff_total_heliostat.set(
            mins[helio_perf_data.PERF_VALUES.ETA_TOT],
            maxs[helio_perf_data.PERF_VALUES.ETA_TOT],
            aves[helio_perf_data.PERF_VALUES.ETA_TOT],
            stdevs[helio_perf_data.PERF_VALUES.ETA_TOT],
            sums[helio_perf_data.PERF_VALUES.ETA_TOT],
            wtmean[helio_perf_data.PERF_VALUES.ETA_TOT]
        )
        self.eff_cosine.set(
            mins[helio_perf_data.PERF_VALUES.ETA_COS],
            maxs[helio_perf_data.PERF_VALUES.ETA_COS],
            aves[helio_perf_data.PERF_VALUES.ETA_COS],
            stdevs[helio_perf_data.PERF_VALUES.ETA_COS],
            sums[helio_perf_data.PERF_VALUES.ETA_COS],
            wtmean[helio_perf_data.PERF_VALUES.ETA_COS]
        )
        self.eff_attenuation.set(
            mins[helio_perf_data.PERF_VALUES.ETA_ATT],
            maxs[helio_perf_data.PERF_VALUES.ETA_ATT],
            aves[helio_perf_data.PERF_VALUES.ETA_ATT],
            stdevs[helio_perf_data.PERF_VALUES.ETA_ATT],
            sums[helio_perf_data.PERF_VALUES.ETA_ATT],
            wtmean[helio_perf_data.PERF_VALUES.ETA_ATT]
        )
        self.eff_blocking.set(
            mins[helio_perf_data.PERF_VALUES.ETA_BLOCK],
            maxs[helio_perf_data.PERF_VALUES.ETA_BLOCK],
            aves[helio_perf_data.PERF_VALUES.ETA_BLOCK],
            stdevs[helio_perf_data.PERF_VALUES.ETA_BLOCK],
            sums[helio_perf_data.PERF_VALUES.ETA_BLOCK],
            wtmean[helio_perf_data.PERF_VALUES.ETA_BLOCK]
        )
        self.eff_shading.set(
            mins[helio_perf_data.PERF_VALUES.ETA_SHADOW],
            maxs[helio_perf_data.PERF_VALUES.ETA_SHADOW],
            aves[helio_perf_data.PERF_VALUES.ETA_SHADOW],
            stdevs[helio_perf_data.PERF_VALUES.ETA_SHADOW],
            sums[helio_perf_data.PERF_VALUES.ETA_SHADOW],
            wtmean[helio_perf_data.PERF_VALUES.ETA_SHADOW]
        )
        self.eff_intercept.set(
            mins[helio_perf_data.PERF_VALUES.ETA_INT],
            maxs[helio_perf_data.PERF_VALUES.ETA_INT],
            aves[helio_perf_data.PERF_VALUES.ETA_INT],
            stdevs[helio_perf_data.PERF_VALUES.ETA_INT],
            sums[helio_perf_data.PERF_VALUES.ETA_INT],
            wtmean[helio_perf_data.PERF_VALUES.ETA_INT]
        )
        self.eff_absorption.set(
            mins[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            maxs[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            aves[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            stdevs[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            sums[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE]
        )
        self.eff_cloud.set(
            mins[helio_perf_data.PERF_VALUES.ETA_CLOUD],
            maxs[helio_perf_data.PERF_VALUES.ETA_CLOUD],
            aves[helio_perf_data.PERF_VALUES.ETA_CLOUD],
            stdevs[helio_perf_data.PERF_VALUES.ETA_CLOUD],
            sums[helio_perf_data.PERF_VALUES.ETA_CLOUD],
            wtmean[helio_perf_data.PERF_VALUES.ETA_CLOUD]
        )
        self.eff_reflect.set(
            mins[helio_perf_data.PERF_VALUES.REFLECTIVITY] * mins[helio_perf_data.PERF_VALUES.SOILING],
            maxs[helio_perf_data.PERF_VALUES.REFLECTIVITY] * maxs[helio_perf_data.PERF_VALUES.SOILING],
            aves[helio_perf_data.PERF_VALUES.REFLECTIVITY] * aves[helio_perf_data.PERF_VALUES.SOILING],
            stdevs[helio_perf_data.PERF_VALUES.REFLECTIVITY] * stdevs[helio_perf_data.PERF_VALUES.SOILING],
            sums[helio_perf_data.PERF_VALUES.REFLECTIVITY] * sums[helio_perf_data.PERF_VALUES.SOILING],
            wtmean[helio_perf_data.PERF_VALUES.REFLECTIVITY] * wtmean[helio_perf_data.PERF_VALUES.SOILING]
        )
        self.eff_total_sf.set(
            mins[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            maxs[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            aves[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            stdevs[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            sums[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE],
            aves[helio_perf_data.PERF_VALUES.ETA_TOT] * wtmean[helio_perf_data.PERF_VALUES.REC_ABSORPTANCE]
        )

    def process_flux_stats(inout self, SF: SolarField):
        var fave: Float64 = 0.0
        var fave2: Float64 = 0.0
        var fmax: Float64 = -9.0e9
        var fmin: Float64 = 9.0e9
        var nf: Int = 0
        var recs: List[Receiver] = SF.getReceivers()
        for i in range(len(recs)):
            var fs: FluxSurfaces = recs[i].getFluxSurfaces()
            for j in range(len(fs)):
                var fg: FluxGrid = fs[j].getFluxMap()
                var nx: Int = fs[j].getFluxNX()
                var ny: Int = fs[j].getFluxNY()
                for k in range(nx):
                    for l in range(ny):
                        var v: Float64 = fg[k][l].flux
                        if v > fmax:
                            fmax = v
                        if v < fmin:
                            fmin = v
                        nf += 1
                        var delta: Float64 = v - fave
                        fave += delta / Float64(nf)
                        fave2 += delta * (v - fave)
        self.flux_density.stdev = sqrt_math(fave2 / Float64(nf - 1))
        self.flux_density.max = fmax
        self.flux_density.min = fmin
        self.flux_density.ave = fave

    def process_analytical_simulation(inout self, SF: SolarField, nsim_type: Int, sun_az_zen: Pointer[Float64], helios: List[Heliostat]):
        self.is_soltrace = False
        self.sim_type = nsim_type
        var V: var_map = SF.getVarMap()
        if self.sim_type == sim_result.SIM_TYPE.PARAMETRIC or self.sim_type == sim_result.SIM_TYPE.OPTIMIZATION or self.sim_type == sim_result.SIM_TYPE.LAYOUT:
            self.initialize()
            var effsum: Float64 = 0.0
            for i in range(len(helios)):
                effsum += helios[i].getEfficiencyTotal()
                self.add_heliostat(helios[i])
            self.eff_total_sf.ave = effsum / Float64(len(helios))
            self.total_receiver_area = V.sf.rec_area.Val()
            self.dni = V.sf.dni_des.val / 1000.0
            self.power_on_field = self.total_heliostat_area * self.dni
            self.power_absorbed = self.power_on_field * self.eff_total_sf.ave
            self.power_thermal_loss = SF.getReceiverTotalHeatLoss()
            self.power_piping_loss = SF.getReceiverPipingHeatLoss()
            self.power_to_htf = self.power_absorbed - (self.power_thermal_loss + self.power_piping_loss)
            self.solar_az = sun_az_zen[0]
            self.solar_zen = sun_az_zen[1]
        elif self.sim_type == sim_result.SIM_TYPE.FLUX_SIMULATION:
            self.initialize()
            for i in range(len(helios)):
                if helios[i].IsInLayout() and helios[i].IsEnabled():
                    self.add_heliostat(helios[i])
            self.process_field_stats()
            self.total_receiver_area = SF.calcReceiverTotalArea()
            self.dni = SF.getVarMap().flux.flux_dni.val / 1000.0
            self.power_on_field = self.total_heliostat_area * self.dni
            self.power_absorbed = self.power_on_field * self.eff_total_sf.ave
            self.power_thermal_loss = SF.getReceiverTotalHeatLoss()
            self.power_piping_loss = SF.getReceiverPipingHeatLoss()
            self.power_to_htf = self.power_absorbed - (self.power_thermal_loss + self.power_piping_loss)
            self.solar_az = sun_az_zen[0]
            self.solar_zen = sun_az_zen[1]
            self.total_installed_cost = V.fin.total_installed_cost.Val()
            self.coe_metric = self.total_installed_cost / self._q_coe
            self.process_flux_stats(SF)
        else:

    def process_analytical_simulation_overload(inout self, SF: SolarField, sim_type: Int, sun_az_zen: Pointer[Float64]):
        self.process_analytical_simulation(SF, sim_type, sun_az_zen, SF.getHeliostats())

    def process_raytrace_simulation(inout self, SF: SolarField, nsim_type: Int, sun_az_zen: Pointer[Float64], helios: List[Heliostat], qray: Float64, emap: Pointer[Int], smap: Pointer[Int], rnum: Pointer[Int], ntot: Int, boxinfo: Pointer[Float64]):
        self.is_soltrace = True
        self.initialize()
        self.sim_type = nsim_type
        if self.sim_type == 2:
            self.num_heliostats_used = len(helios)
            for i in range(self.num_heliostats_used):
                self.total_heliostat_area += helios[i].getArea()
            var dni: Float64 = SF.getVarMap().sf.dni_des.val / 1000.0
            var st: Int = 0
            var st0: Int = 0
            var ray: Int = 0
            var ray0: Int = 0
            var el: Int = 0
            var nhin: Int = 0
            var nhout: Int = 0
            var nhblock: Int = 0
            var nhabs: Int = 0
            var nrin: Int = 0
            var nrspill: Int = 0
            var nrabs: Int = 0
            for i in range(ntot):
                st = smap[i]
                ray = rnum[i]
                el = emap[i]
                if (ray != ray0) and (ray0 != 0):
                    if st0 == 1:
                        nhin += 1
                        nhout += 1
                    else:
                        nrin += 1
                    ray0 = 0
                    st0 = 0
                if el < 0:
                    if st == 1:
                        nhin += 1
                        if ray == ray0:
                            nhblock += 1
                        else:
                            nhabs += 1
                    else:
                        nrin += 1
                        nrabs += 1
                    ray0 = 0
                    st0 = 0
                elif el == 0:
                    nrspill += 1
                    ray0 = 0
                    st0 = 0
                else:
                    st0 = st
                    ray0 = ray
            var nsunrays: Int = Int(boxinfo[4])
            var Abox: Float64 = (boxinfo[0] - boxinfo[1]) * (boxinfo[2] - boxinfo[3])
            self.num_ray_traced = nsunrays
            self.num_ray_heliostat = nhin
            self.num_ray_receiver = nrin
            self.power_on_field = self.total_heliostat_area * dni
            self.power_absorbed = qray * Float64(nrabs)
            self.power_thermal_loss = SF.getReceiverTotalHeatLoss()
            self.power_piping_loss = SF.getReceiverPipingHeatLoss()
            self.power_to_htf = self.power_absorbed - (self.power_thermal_loss + self.power_piping_loss)
            self.eff_total_sf.set(0.0, 0.0, 0.0, 0.0, 0.0, self.power_absorbed / self.power_on_field)
            self.eff_cosine.set(0.0, 0.0, 0.0, 0.0, 0.0, Float64(nhin) / Float64(nsunrays) * Abox / self.total_heliostat_area)
            self.eff_blocking.set(0.0, 0.0, 0.0, 0.0, 0.0, 1.0 - Float64(nhblock) / Float64(nhin - nhabs))
            self.eff_attenuation.set(0.0, 0.0, 0.0, 0.0, 0.0, 1.0)
            self.eff_reflect.set(0.0, 0.0, 0.0, 0.0, 0.0, Float64(nhin - nhabs) / Float64(nhin))
            self.eff_intercept.set(0.0, 0.0, 0.0, 0.0, 0.0, Float64(nrin) / Float64(nhout))
            self.eff_absorption.set(0.0, 0.0, 0.0, 0.0, 0.0, Float64(nrabs) / Float64(nrin))
            self.eff_total_heliostat.set(0.0, 0.0, 0.0, 0.0, 0.0, Float64(nrabs) / Float64(nhin))
            self.eff_cloud.set(1.0, 1.0, 1.0, 0.0, 1.0, 1.0)
            self.total_receiver_area = SF.calcReceiverTotalArea()
            self.solar_az = sun_az_zen[0]
            self.solar_zen = sun_az_zen[1]
            SF.getFinancialObject().calcPlantCapitalCost(*SF.getVarMap())
            self.total_installed_cost = SF.getVarMap().fin.total_installed_cost.Val()
            self.coe_metric = self.total_installed_cost / self.power_absorbed
            self.process_flux_stats(SF)
        else:

    def process_flux(inout self, SF: SolarField, normalize: Bool):
        self.flux_surfaces.clear()
        self.receiver_names.clear()
        var nr: Int = len(SF.getReceivers())
        for i in range(nr):
            var rec: Receiver = SF.getReceivers()[i]
            if not rec.isReceiverEnabled():
                continue
            self.flux_surfaces.append(*rec.getFluxSurfaces())
            if normalize:
                for j in range(len(rec.getFluxSurfaces())):
                    self.flux_surfaces[-1][j].Normalize()
            self.receiver_names.append(
                SF.getReceivers()[i].getVarMap().rec_name.val
            )

# -------------------------------------------------------------------
# interop namespace functions (as module-level functions)
# -------------------------------------------------------------------

def GenerateSimulationWeatherData(V: var_map, design_method: Int, wf_entries: ArrayString):
    """ 
    Calculate and fill the weather data steps needed for simulation and the associated time step.
    The weather data is filled in the variable set vset["solarfield"][0]["sim_step_data"].value
    wf_entries consists of a list strings corresponding to each time step. 
    Each string is comma-separated and has the following entries:
    day, hour, month, dn, tdry, pres/1000., wspd
    """
    var wdatvar: WeatherData = V.sf.sim_step_data.Val()
    if design_method == var_solarfield.DES_SIM_DETAIL.SUBSET_OF_DAYSHOURS:
        V.amb.sim_time_step.Setval(0.0)
        throw spexception("Simulation with a user-specified list of days/hours is not currently supported. Please use another option.")
    elif design_method == var_solarfield.DES_SIM_DETAIL.SINGLE_SIMULATION_POINT:
        V.amb.sim_time_step.Setval(0.0)
        var vdata: List[String] = split(Ambient.getDefaultSimStep(), ",")
        var hour: Int = 0
        var dom: Int = 0
        var month: Int = 0
        to_integer(vdata[0], &dom)
        to_integer(vdata[1], &hour)
        to_integer(vdata[2], &month)
        var P: sim_params = sim_params()
        to_double(vdata[3], &P.dni)
        to_double(vdata[4], &P.Tamb)
        to_double(vdata[5], &P.Patm)
        to_double(vdata[6], &P.Vwind)
        to_double(vdata[7], &P.Simweight)
        wdatvar.resizeAll(1)
        wdatvar.setStep(0, dom, hour, month, P.dni, P.Tamb, P.Patm, P.Vwind, P.Simweight)
    elif design_method == var_solarfield.DES_SIM_DETAIL.DO_NOT_FILTER_HELIOSTATS:
        wdatvar.clear()
        V.amb.sim_time_step.Setval(0.0)
    elif design_method == var_solarfield.DES_SIM_DETAIL.ANNUAL_SIMULATION:
        wdatvar = WeatherData(V.amb.wf_data.val)
        wdatvar.initPointers()
        V.amb.sim_time_step.Setval(3600.0)
    elif design_method == var_solarfield.DES_SIM_DETAIL.EFFICIENCY_MAP__ANNUAL:
        V.amb.sim_time_step.Setval(3600.0)
        wdatvar.clear()
        var uday: List[Int] = List[Int]()
        var utime: List[List[Float64]] = List[List[Float64]]()
        var lat: Float64 = V.amb.latitude.val * D2R
        var lng: Float64 = V.amb.longitude.val * D2R
        var tmz: Float64 = V.amb.time_zone.val
        var dni_des: Float64 = V.sf.dni_des.val
        var nday: Int = V.sf.des_sim_ndays.val
        Ambient.calcSpacedDaysHours(lat, lng, tmz, nday, 1.0, utime, uday)
        var nflux_sim: Int = 0
        for i in range(len(utime)):
            nflux_sim += len(utime[i])
        var dt: DateTime = DateTime()
        var hod: Float64 = 0.0
        var month: Int = 0
        var dom: Int = 0
        for i in range(nday):
            var doy: Int = uday[i]
            for j in range(len(utime[i])):
                hod = utime[i][j] + 12.0
                var hoy: Float64 = Float64(doy) * 24.0
                dt.hours_to_date(hoy, month, dom)
                wdatvar.append(dom, hod, month, dni_des, 25.0, 1.0, 1.0, 1.0)
    elif design_method == var_solarfield.DES_SIM_DETAIL.LIMITED_ANNUAL_SIMULATION or design_method == var_solarfield.DES_SIM_DETAIL.REPRESENTATIVE_PROFILES or design_method == -1:
        V.amb.sim_time_step.Setval(0.0)
        wdatvar.clear()
        var dt: DateTime = DateTime()
        var lat: Float64 = V.amb.latitude.val
        var lng: Float64 = V.amb.longitude.val
        var tmz: Float64 = V.amb.time_zone.val
        var nday: Int, nskip: Int
        if design_method == -1:
            nday = 4
            nskip = 2
        else:
            nday = V.sf.des_sim_ndays.val
            nskip = V.sf.des_sim_nhours.val
        var delta_day: Float64 = 365.0 / Float64(nday)
        var doffset: Float64
        if nday % 2 == 1:
            doffset = 0.0
        else:
            doffset = delta_day / 2.0
        var simdays: List[Int] = List[Int](nday, 0)
        var dinit: Int = 171 - Int(Toolbox.round( (Float64(nday) / 2.0 - 1.0) * delta_day - doffset ))
        var dcalc: Int
        for i in range(nday):
            dcalc = Int(Toolbox.round(Float64(dinit) + Float64(i) * delta_day))
            if dcalc < 1:
                dcalc += 365
            elif dcalc > 365:
                dcalc += -365
            simdays[i] = dcalc - 1
        quicksort(simdays, 0, nday - 1)
        var tsdat: List[String] = List[String]()
        for i in range(nday):
            var month: Int, dom: Int
            var hoy: Float64
            var doy: Int = simdays[i]
            hoy = Float64(doy) * 24.0
            dt.hours_to_date(hoy, month, dom)
            dt.SetHour(12)
            dt.SetDate(2011, month, dom)
            doy += 1
            dt.SetYearDay(doy)
            var hrs: Pointer[Float64] = Pointer[Float64].alloc(2)
            Ambient.calcDaytimeHours(hrs, lat * D2R, lng * D2R, tmz, dt)
            var dni: Float64, tdry: Float64, pres: Float64, wind: Float64
            var hrmid: Float64 = (hrs[0] + hrs[1]) / 2.0 + hoy
            var nhrs: Int = Int((hrs[1] - hrs[0]) / Float64(nskip)) * nskip
            var nmidspan: Float64 = Float64(nhrs) / 2.0
            var hr_st: Float64 = hrmid - nmidspan
            var hr_end: Float64 = hrmid + nmidspan
            if design_method == var_solarfield.DES_SIM_DETAIL.LIMITED_ANNUAL_SIMULATION:
                var fthis: Float64 = fmin(0.5, hr_st - floor(hr_st)) + fmin(0.5, ceil(hr_st) - hr_st)
                var fcomp: Float64 = 1.0 - fthis
                var iind: Int = -1 if (hr_st - floor(hr_st)) < 0.5 else 1
                var jd: Float64 = hr_st
                while jd < hr_end + 0.001:
                    var jind: Int = Int(floor(jd))
                    tsdat = split(wf_entries[jind], ",")
                    to_double(tsdat[3], &dni)
                    to_double(tsdat[4], &tdry)
                    to_double(tsdat[5], &pres)
                    to_double(tsdat[6], &wind)
                    var hod: Float64 = fmod(jd, 24.0)
                    var step_weight: Float64
                    if jd == hr_st:
                        step_weight = hod - hrs[0] + Float64(nskip) / 2.0
                    elif jd + Float64(nskip) < hr_end + 0.001:
                        step_weight = Float64(nskip)
                    else:
                        step_weight = hrs[1] - hod + Float64(nskip) / 2.0
                    step_weight *= Toolbox.round(delta_day)
                    var dnimod: Float64, dnicomp: Float64
                    if iind > 0:
                        tsdat = split(wf_entries[min(8759, jind + 1)], ",")
                    else:
                        tsdat = split(wf_entries[max(0, jind - 1)], ",")
                    to_double(tsdat[3], &dnicomp)
                    dnimod = dni * fthis + dnicomp * fcomp
                    wdatvar.append(dom, hod, month, dnimod, tdry, pres, wind, step_weight)
                    jd += Float64(nskip)
            else:  # Representative profile
                var simprev: Int
                if i == 0:
                    simprev = simdays[-1]
                else:
                    simprev = simdays[i - 1]
                var simnext: Int
                if i == nday - 1:
                    simnext = simdays[0]
                else:
                    simnext = simdays[i + 1]
                var dprev: Int
                if simprev > simdays[i]:
                    dprev = simdays[i] - (simprev - 365)
                else:
                    dprev = simdays[i] - simprev
                var dnext: Int
                if simnext < simdays[i]:
                    dnext = simnext + 365 - simdays[i]
                else:
                    dnext = simnext - simdays[i]
                var range_start: Int = -dprev / 2
                var range_end: Int = dnext / 2
                var range: Int = range_end - range_start
                var fthis: Float64 = fmin(0.5, hr_st - floor(hr_st)) + fmin(0.5, ceil(hr_st) - hr_st)
                var fcomp: Float64 = 1.0 - fthis
                var iind: Int = -1 if (hr_st - floor(hr_st)) < 0.5 else 1
                var dayind: Int = 0
                var nwf: Int = len(wf_entries)
                var dnicomp: Float64
                var jd: Float64 = hr_st
                while jd < hr_end + 0.001:
                    var tdry_per: Float64 = 0.0
                    var pres_per: Float64 = 0.0
                    var wind_per: Float64 = 0.0
                    var dni_per: Float64 = 0.0
                    var dni_per2: Float64 = 0.0
                    for k in range(range_start, range_end):
                        var ind: Int = Int(floor(jd)) + k * 24
                        if ind < 0:
                            ind += 8760
                        if ind > 8759:
                            ind += -8760
                        tsdat = split(wf_entries[ind], ",")
                        to_double(tsdat[3], &dni)
                        to_double(tsdat[4], &tdry)
                        to_double(tsdat[5], &pres)
                        to_double(tsdat[6], &wind)
                        tsdat = split(wf_entries[min(max(ind + iind, 0), nwf - 1)], ",")
                        to_double(tsdat[3], &dnicomp)
                        dni_per += dni * fthis + dnicomp * fcomp
                        tdry_per += tdry
                        pres_per += pres
                        wind_per += wind
                    dni_per = (dni_per + dni_per2) / Float64(range)
                    tdry_per *= 1.0 / Float64(range)
                    pres_per *= 1.0 / Float64(range)
                    wind_per *= 1.0 / Float64(range)
                    var hod: Float64 = fmod(jd, 24.0)
                    var step_weight: Float64
                    if jd == hr_st:
                        step_weight = hod - hrs[0] + Float64(nskip) / 2.0
                    elif jd + Float64(nskip) < hr_end + 0.001:
                        step_weight = Float64(nskip)
                    else:
                        step_weight = hrs[1] - hod + Float64(nskip) / 2.0
                    step_weight *= Float64(range)
                    wdatvar.append(dom, hod, month, dni_per, tdry_per, pres_per, wind_per, step_weight)
                    dayind += 1
                    jd += Float64(nskip)
    else:

def GenerateSimulationWeatherData_overload(V: var_map, design_method: Int, wf_entries: List[String]):
    var wfdat: ArrayString = ArrayString()
    for i in range(len(wf_entries)):
        wfdat.Add(wf_entries[i])
    GenerateSimulationWeatherData(V, design_method, wfdat)

def parseRange(range: String, rangelow: Int, rangehi: Int, include_low: Bool, include_hi: Bool) -> Bool:
    var t1: List[String] = split(range, ",")
    if len(t1) < 2:
        return False
    var lop: String
    var rop: String
    var ops: String
    var ls: String
    var rs: String
    ls = t1[0]
    rs = t1[1]
    lop = ls[0]
    rop = rs[len(rs) - 1]
    to_integer(ls.erase(0, 1), &rangelow)
    to_integer(rs.erase(len(rs) - 1, 1), &rangehi)
    ops = lop + rop
    if ops == " ":
        return False
    if lop == "(":
        include_low = False
    else:
        include_low = True
    if rop == ")":
        include_hi = False
    else:
        include_hi = True
    return True

def ticker_initialize(indices: Pointer[Int], n: Int):
    for i in range(n):
        indices[i] = 0

def ticker_increment(lengths: Pointer[Int], indices: Pointer[Int], changed: Pointer[Bool], n: Int) -> Bool:
    for i in range(n):
        changed[i] = False
    var inc_next: Bool = True
    var complete: Bool = False
    for i in range(n - 1, -1, -1):
        if inc_next:
            indices[i] += 1
            changed[i] = True
            if i == 0:
                complete = (indices[0] == lengths[0])
        inc_next = (indices[i] > lengths[i] - 1)
        if not inc_next:
            break
        indices[i] = 0
    return complete

def PerformanceSimulationPrep(SF: SolarField, helios: List[Heliostat], sim_method: Int) -> Bool:
    var V: var_map = SF.getVarMap()
    var fd: FluxSimData = SF.getFluxSimObject()
    fd.Create(*V)
    var recs: List[Receiver] = SF.getReceivers()
    for i in range(len(recs)):
        recs[i].DefineReceiverGeometry(V.flux.x_res.val, V.flux.y_res.val)
    var ext: Pointer[Float64] = Pointer[Float64].alloc(2)
    SF.getLandObject().getExtents(*V, ext)
    SF.getCloudObject().Create(*V, ext)
    for i in range(len(helios)):
        var eta_cloud: Float64 = SF.getCloudObject().ShadowLoss(*V, *helios[i].getLocation())
        helios[i].setEfficiencyCloudiness(eta_cloud)
        helios[i].calcTotalEfficiency()
    var az: Float64, zen: Float64
    if V.flux.flux_time_type.mapval() == var_fluxsim.FLUX_TIME_TYPE.SUN_POSITION:
        az = V.flux.flux_solar_az_in.val
        zen = 90.0 - V.flux.flux_solar_el_in.val
    else:
        var flux_day: Int = V.flux.flux_day.val
        var flux_hour: Float64 = V.flux.flux_hour.val
        var flux_month: Int = V.flux.flux_month.val
        var DT: DateTime = DateTime()
        Ambient.setDateTime(DT, flux_hour, DT.GetDayOfYear(2011, flux_month, flux_day))
        Ambient.calcSunPosition(*V, DT, &az, &zen)
    V.flux.flux_solar_az.Setval(az)
    V.flux.flux_solar_el.Setval(90.0 - zen)
    var P: sim_params = sim_params()
    P.dni = V.flux.flux_dni.val
    P.Tamb = 25.0
    P.Patm = 1.0
    SF.Simulate(az * D2R, zen * D2R, P)
    return not SF.ErrCheck()

if SP_USE_SOLTRACE:
    from stapi import *

    def SolTraceFluxSimulation_ST_overload(cxt: st_context_t, seed: Int, ST: ST_System,
                                           callback: fn(st_uint_t, st_uint_t, st_uint_t, st_uint_t, st_uint_t, Pointer[UInt8]) -> Int,
                                           par: Pointer[UInt8],
                                           st0data: List[List[Float64]], st1data: List[List[Float64]], save_stage_data: Bool, load_stage_data: Bool) -> Bool:
        var minrays: Int = ST.sim_raycount
        var maxrays: Int = ST.sim_raymax
        st_sim_params(cxt, minrays, maxrays)
        return st_sim_run(cxt, seed, True, callback, par) != -1

    def SolTraceFluxSimulation_ST(cxt: st_context_t, SF: SolarField, helios: List[Heliostat], sunvect: Vect,
                                  callback: fn(st_uint_t, st_uint_t, st_uint_t, st_uint_t, st_uint_t, Pointer[UInt8]) -> Int,
                                  par: Pointer[UInt8],
                                  st0data: List[List[Float64]], st1data: List[List[Float64]], save_stage_data: Bool, load_stage_data: Bool) -> Bool:
        var STSim: ST_System = ST_System()
        STSim.CreateSTSystem(SF, helios, sunvect)
        ST_System.LoadIntoContext(&STSim, cxt)
        var seed: Int = SF.getFluxObject().getRandomObject().integer()
        return SolTraceFluxSimulation_ST_overload(cxt, seed, STSim, callback, par, st0data, st1data, save_stage_data, load_stage_data)

def UpdateMapLayoutData(V: var_map, heliostats: List[Heliostat]):
    var npos: Int = len(heliostats)
    var var_ref: String = V.sf.layout_data.val
    var_ref.clear()
    var sdat: String = String()
    for i in range(npos):
        var H: Heliostat = heliostats[i]
        var loc: sp_point = H.getLocation()
        var cant: Vect = H.getCantVector()
        var aim: sp_point = H.getAimPoint()
        var tchar1: String
        if H.getVarMap().focus_method.mapval() == var_heliostat.FOCUS_METHOD.USERDEFINED:
            tchar1 = String.format("%f,%f", H.getFocalX(), H.getFocalY())
        else:
            tchar1 = "NULL,NULL"
        var tchar2: String
        if H.IsUserCant():
            tchar2 = String.format("%f,%f,%f", cant.i, cant.j, cant.k)
        else:
            tchar2 = "NULL,NULL,NULL"
        var tchar3: String = String.format("%f,%f,%f", aim.x, aim.y, aim.z)
        var tchar4: String = String.format("%d,%d,%d,%f,%f,%f,%s,%s,%s\n",
            H.getVarMap().type.val,
            1 if H.IsEnabled() else 0,
            1 if H.IsInLayout() else 0,
            loc.x, loc.y, loc.z,
            tchar1, tchar2, tchar3)
        sdat = tchar4
        var_ref.append(sdat)