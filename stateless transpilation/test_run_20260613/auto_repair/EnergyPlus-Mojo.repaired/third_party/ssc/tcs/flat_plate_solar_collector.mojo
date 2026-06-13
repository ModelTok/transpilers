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
from lib_irradproc import irrad, PoaIrradianceComponents
from math import isfinite, isfinite, log, exp, cos, round, isnormal
from memory import memset_zero
from time import tm
from limits import Float64
from vector import DynamicVector

struct CollectorTestSpecifications:
    var FRta: Float64                        # [-]
    var FRUL: Float64                        # [W/m2-K]
    var iam: Float64                         # [-]
    var area_coll: Float64                   # [m2]
    var m_dot: Float64                       # [kg/s]
    var heat_capacity: Float64               # [kJ/kg-K]

struct CollectorLocation:
    var latitude: Float64                    # [deg N]
    var longitude: Float64                   # [deg E]
    var timezone: Int32                      # [hr]

struct CollectorOrientation:
    var tilt: Float64                        # [deg]
    var azimuth: Float64                     # [deg] Clockwise from North

struct ArrayDimensions:
    var num_in_series: Int32
    var num_in_parallel: Int32

struct TimeAndPosition:
    var timestamp: tm
    var collector_location: CollectorLocation
    var collector_orientation: CollectorOrientation

struct Weather:
    var dni: Float64                         # [W/m2]
    var dhi: Float64                         # [W/m2]
    var ghi: Float64                         # [W/m2]
    var ambient_temp: Float64                # [C]
    var wind_speed: Float64                  # [m/s]
    var wind_direction: Float64              # [deg] Clockwise from North

struct InletFluidFlow:
    var temp: Float64                        # [C]
    var m_dot: Float64                       # [kg/s]
    var specific_heat: Float64               # [kJ/kg-K]

struct ExternalConditions:
    var weather: Weather
    var inlet_fluid_flow: InletFluidFlow
    var albedo: Float64                      # [-]

struct PoaIrradianceComponents:
    var beam_with_aoi: DynamicVector[Float64]                          # {[W/m2], [deg]}
    var sky_diffuse_with_aoi: DynamicVector[Float64]                   # {[W/m2], [deg]}
    var ground_reflected_diffuse_with_aoi: DynamicVector[Float64]      # {[W/m2], [deg]}
    def __init__(inout self):
        self.beam_with_aoi = DynamicVector[Float64](2, Float64.NaN)
        self.sky_diffuse_with_aoi = DynamicVector[Float64](2, Float64.NaN)
        self.ground_reflected_diffuse_with_aoi = DynamicVector[Float64](2, Float64.NaN)

class FlatPlateCollector:
    var FRta_: Float64                       # [-] flow rate correction
    var FRUL_: Float64                       # [W/m2-K] flow rate correction
    var iam_: Float64                        # [-] incidence angle modifier
    var area_coll_: Float64                  # [m2] collector area
    var m_dot_test_: Float64                 # [kg/s] mass flow through collector during test
    var heat_capacity_rate_test_: Float64    # [kW/K] m_dot * c_p during ratings test

    def __init__(inout self):
        self.FRta_ = Float64.NaN
        self.FRUL_ = Float64.NaN
        self.iam_ = Float64.NaN
        self.area_coll_ = Float64.NaN
        self.heat_capacity_rate_test_ = Float64.NaN
        self.m_dot_test_ = Float64.NaN

    def __init__(inout self, collector_test_specifications: CollectorTestSpecifications):
        self.FRta_ = collector_test_specifications.FRta
        self.FRUL_ = collector_test_specifications.FRUL
        self.iam_ = collector_test_specifications.iam
        self.area_coll_ = collector_test_specifications.area_coll
        self.heat_capacity_rate_test_ = collector_test_specifications.heat_capacity * collector_test_specifications.m_dot
        self.m_dot_test_ = collector_test_specifications.m_dot

    def RatedPowerGain(self) -> Float64:   # [W]
        var G_T: Float64 = 1.0e3                  # normal incident irradiance [W/m2]
        var T_inlet_minus_T_amb: Float64 = 30.0   # [K]
        return self.area_coll_ * (self.FRta_ * G_T - self.FRUL_ * T_inlet_minus_T_amb)

    def UsefulPowerGain(self, time_and_position: TimeAndPosition, external_conditions: ExternalConditions) -> Float64:  # [W]
        var weather: Weather = external_conditions.weather
        var ambient_temp: Float64 = external_conditions.weather.ambient_temp
        var inlet_fluid_flow: InletFluidFlow = external_conditions.inlet_fluid_flow
        var albedo: Float64 = external_conditions.albedo
        var poa_irradiance_components: PoaIrradianceComponents = FlatPlateCollector.IncidentIrradiance(time_and_position, weather, albedo)
        var transmitted_irradiance: Float64 = self.TransmittedIrradiance(time_and_position.collector_orientation, poa_irradiance_components)
        var absorbed_radiant_power: Float64 = self.AbsorbedRadiantPower(transmitted_irradiance, inlet_fluid_flow, ambient_temp)
        var thermal_power_loss: Float64 = self.ThermalPowerLoss(inlet_fluid_flow, ambient_temp)
        var useful_power_gain: Float64 = absorbed_radiant_power - thermal_power_loss
        return useful_power_gain

    def T_out(self, time_and_position: TimeAndPosition, external_conditions: ExternalConditions) -> Float64:     # [C]
        var useful_power_gain: Float64 = self.UsefulPowerGain(time_and_position, external_conditions)
        var m_dot: Float64 = external_conditions.inlet_fluid_flow.m_dot
        var specific_heat: Float64 = external_conditions.inlet_fluid_flow.specific_heat
        var mdotCp_use: Float64 = m_dot * specific_heat * 1.0e3 # mass flow rate (kg/s) * Cp_fluid (kJ/kg.K) * 1000 J/kJ
        var dT_collector: Float64 = useful_power_gain / mdotCp_use
        var T_in: Float64 = external_conditions.inlet_fluid_flow.temp
        return dT_collector + T_in

    def area_coll(self) -> Float64:    # [m2]
        return self.area_coll_

    def area_coll(inout self, collector_area: Float64): #m2
        self.area_coll_ = collector_area

    def TestSpecifications(self) -> CollectorTestSpecifications:
        var collector_test_specifications: CollectorTestSpecifications
        collector_test_specifications.FRta = self.FRta_
        collector_test_specifications.FRUL = self.FRUL_
        collector_test_specifications.iam = self.iam_
        collector_test_specifications.area_coll = self.area_coll_
        collector_test_specifications.m_dot = self.m_dot_test_
        collector_test_specifications.heat_capacity = self.heat_capacity_rate_test_ / self.m_dot_test_
        return collector_test_specifications

    @staticmethod
    def IncidentIrradiance(time_and_position: TimeAndPosition, weather: Weather, albedo: Float64) -> PoaIrradianceComponents:   # [W/m2]
        var dni: Float64 = weather.dni
        var dhi: Float64 = weather.dhi
        var ghi: Float64 = weather.ghi
        var irrad_mode: Int32
        var tt: irrad
        if isfinite(dni) and isfinite(dhi):
            irrad_mode = 0     # 0 = beam & diffuse
            tt.set_beam_diffuse(dni, dhi)
        elif isfinite(ghi) and isfinite(dni):
            irrad_mode = 1     # 1 = total & beam
            tt.set_global_beam(ghi, dni)
        elif isfinite(ghi) and isfinite(dhi):
            irrad_mode = 2     # 2 = total & diffuse
            tt.set_global_diffuse(ghi, dhi)
        else:
            raise Error("FlatPlateCollector: Two of the three irradiance components must be specified.")
        tt.set_location(time_and_position.collector_location.latitude,
            time_and_position.collector_location.longitude,
            time_and_position.collector_location.timezone)
        tt.set_optional(0, 1013.25, weather.ambient_temp)
        var irradproc_no_interpolate_sunrise_sunset: Float64 = -1.0      # IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET = -1.0;
        var delt: Float64 = irradproc_no_interpolate_sunrise_sunset      # 
        tt.set_time(time_and_position.timestamp.tm_year + 1900,     # years since 1900
            time_and_position.timestamp.tm_mon + 1,                 # Jan. = 0
            time_and_position.timestamp.tm_mday,
            time_and_position.timestamp.tm_hour,
            time_and_position.timestamp.tm_min,
            delt)
        var sky_model: Int32 = 2      # isotropic=0, hdkr=1, perez=2
        tt.set_sky_model(sky_model, albedo)
        var tilt: Float64 = time_and_position.collector_orientation.tilt
        var azimuth: Float64 = time_and_position.collector_orientation.azimuth
        tt.set_surface(0, tilt, azimuth, 0, 0, 0, False, 0.0)
        tt.calc()
        var poa_beam: Float64
        var poa_sky_diffuse: Float64
        var poa_ground_reflected_diffuse: Float64
        tt.get_poa(poa_beam, poa_sky_diffuse, poa_ground_reflected_diffuse, 0, 0, 0)
        var poa_beam_aoi: Float64 = 0
        tt.get_angles(poa_beam_aoi, 0, 0, 0, 0) # note: angles returned in degrees
        var poa_irradiance_components: PoaIrradianceComponents
        poa_irradiance_components.beam_with_aoi[0] = poa_beam
        poa_irradiance_components.beam_with_aoi[1] = poa_beam_aoi
        poa_irradiance_components.sky_diffuse_with_aoi[0] = poa_sky_diffuse
        poa_irradiance_components.sky_diffuse_with_aoi[1] = Float64.NaN
        poa_irradiance_components.ground_reflected_diffuse_with_aoi[0] = poa_ground_reflected_diffuse
        poa_irradiance_components.ground_reflected_diffuse_with_aoi[1] = Float64.NaN
        return poa_irradiance_components

    def TransmittedIrradiance(self, collector_orientation: CollectorOrientation, poa_irradiance_components: PoaIrradianceComponents) -> Float64:   # [W/m2]
        var kPi: Float64 = 3.1415926535897
        var Kta_d: Float64 = 0.0
        var Kta_b: Float64 = 0.0
        var Kta_g: Float64 = 0.0
        var aoi_beam: Float64 = poa_irradiance_components.beam_with_aoi[1]
        if aoi_beam <= 60.0:
            Kta_b = 1 - self.iam_ * (1 / cos(aoi_beam * kPi / 180) - 1)
        elif aoi_beam > 60.0 and aoi_beam <= 90.0:
            Kta_b = (1 - self.iam_) * (aoi_beam - 90.0) * kPi / 180
        if Kta_b < 0:
            Kta_b = 0
        var tilt: Float64 = collector_orientation.tilt
        var theta_eff_diffuse: Float64 = 59.7 * kPi / 180 - 0.1388 * tilt * kPi / 180 + 0.001497 * tilt * kPi / 180 * tilt * kPi / 180
        var cos_theta_eff_diffuse: Float64 = cos(theta_eff_diffuse)
        if theta_eff_diffuse <= kPi / 3.0:
            Kta_d = 1 - self.iam_ * (1 / cos_theta_eff_diffuse - 1)
        elif theta_eff_diffuse > kPi / 3.0 and theta_eff_diffuse <= kPi / 0.2:
            Kta_d = (1 - self.iam_) * (theta_eff_diffuse - kPi / 2.0)
        if Kta_d < 0:
            Kta_d = 0
        var theta_eff_ground: Float64 = 90 * kPi / 180 - 0.5788 * tilt * kPi / 180 + 0.002693 * tilt * kPi / 180 * tilt * kPi / 180
        var cos_theta_eff_ground: Float64 = cos(theta_eff_ground)
        if theta_eff_ground <= kPi / 3:
            Kta_g = 1 - self.iam_ * (1 / cos_theta_eff_ground - 1)
        elif theta_eff_ground > kPi / 3 and theta_eff_ground <= kPi / 2:
            Kta_g = (1 - self.iam_) * (theta_eff_ground - kPi / 2.0)
        if Kta_g < 0:
            Kta_g = 0
        var beam_shading_factor: Float64 = 1.0
        var diffuse_shading_factor: Float64 = 1.0
        var poa_beam: Float64 = poa_irradiance_components.beam_with_aoi[0]
        var poa_sky_diffuse: Float64 = poa_irradiance_components.sky_diffuse_with_aoi[0]
        var poa_ground_reflected_diffuse: Float64 = poa_irradiance_components.ground_reflected_diffuse_with_aoi[0]
        var I_transmitted: Float64 = (
            Kta_b * poa_beam * beam_shading_factor +
            Kta_d * poa_sky_diffuse * diffuse_shading_factor +
            Kta_g * poa_ground_reflected_diffuse
        )
        return I_transmitted

    def AbsorbedRadiantPower(self, transmitted_irradiance: Float64, inlet_fluid_flow: InletFluidFlow, T_amb: Float64) -> Float64:    # [W]
        var m_dot: Float64 = inlet_fluid_flow.m_dot
        var specific_heat: Float64 = inlet_fluid_flow.specific_heat
        var mdotCp_use: Float64 = m_dot * specific_heat * 1.0e3 # mass flow rate (kg/s) * Cp_fluid (kJ/kg.K) * 1000 J/kJ
        # Flow rate corrections to FRta, FRUL (D&B pp 307)
        var FprimeUL: Float64 = -self.heat_capacity_rate_test_ * 1.0e3 / self.area_coll_ * log(1 - self.FRUL_ * self.area_coll_ / (self.heat_capacity_rate_test_ * 1.0e3)) # D&B eqn 6.20.4
        var r: Float64 = (mdotCp_use / self.area_coll_ * (1 - exp(-self.area_coll_ * FprimeUL / mdotCp_use))) / self.FRUL_ # D&B eqn 6.20.3
        var FRta_use: Float64 = self.FRta_ * r # FRta_use = value for this time step 
        var Q_dot_absorbed: Float64 = self.area_coll_ * FRta_use * transmitted_irradiance # from D&B eqn 6.8.1
        return Q_dot_absorbed

    def ThermalPowerLoss(self, inlet_fluid_flow: InletFluidFlow, T_amb: Float64) -> Float64:  # [W]
        var T_in: Float64 = inlet_fluid_flow.temp
        var m_dot: Float64 = inlet_fluid_flow.m_dot
        var specific_heat: Float64 = inlet_fluid_flow.specific_heat
        var mdotCp_use: Float64 = m_dot * specific_heat * 1.0e3 # mass flow rate (kg/s) * Cp_fluid (J/kg.K) * 1000 J/kJ
        var FprimeUL: Float64 = -self.heat_capacity_rate_test_ * 1.0e3 / self.area_coll_ * log(1 - self.FRUL_ * self.area_coll_ / (self.heat_capacity_rate_test_ * 1.0e3)) # D&B eqn 6.20.4
        var r: Float64 = (mdotCp_use / self.area_coll_ * (1 - exp(-self.area_coll_ * FprimeUL / mdotCp_use))) / self.FRUL_ # D&B eqn 6.20.3
        var FRUL_use: Float64 = self.FRUL_ * r # FRUL_use = value for this time step
        var Q_dot_losses: Float64 = self.area_coll_ * FRUL_use * (T_in - T_amb) # from D&B eqn 6.8.1
        return Q_dot_losses

class Pipe:
    var pipe_diam_: Float64                  # [m]
    var pipe_k_: Float64                     # [W/m-K]
    var pipe_insul_: Float64                 # [m]
    var pipe_length_: Float64                # [m] in whole system

    def __init__(inout self):
        self.pipe_diam_ = Float64.NaN
        self.pipe_k_ = Float64.NaN
        self.pipe_insul_ = Float64.NaN
        self.pipe_length_ = Float64.NaN

    def __init__(inout self, pipe_diam: Float64, pipe_k: Float64, pipe_insul: Float64, pipe_length: Float64):
        self.pipe_diam_ = pipe_diam
        self.pipe_k_ = pipe_k
        self.pipe_insul_ = pipe_insul
        self.pipe_length_ = pipe_length

    def pipe_od(self) -> Float64:    # [m]
        return self.pipe_diam_ + self.pipe_insul_ * 2

    def UA_pipe(self) -> Float64:    # [W/K]
        var kPi: Float64 = 3.1415926535897
        var U_pipe: Float64 = 2 * self.pipe_k_ / (self.pipe_od() * log(self.pipe_od() / self.pipe_diam_)) #  **TODO** CHECK whether should be pipe_diam*log(pipe_od/pipe_diam) in denominator
        var UA_pipe: Float64 = U_pipe * kPi * self.pipe_od() * self.pipe_length_ # W/'C
        return UA_pipe

    def ThermalPowerLoss(self, T_in: Float64, T_amb: Float64) -> Float64:   # [W]
        return self.UA_pipe() * (T_in - T_amb)

    def T_out(self, T_in: Float64, T_amb: Float64, heat_capacity_rate: Float64) -> Float64:     # [C]
        var thermal_power_loss: Float64 = self.ThermalPowerLoss(T_in, T_amb)
        var T_out: Float64 = -thermal_power_loss / (heat_capacity_rate * 1.0e3) + T_in
        return T_out

class FlatPlateArray:
    var flat_plate_collector_: FlatPlateCollector       # just scale a single collector for now -> premature optimization??
    var collector_location_: CollectorLocation
    var collector_orientation_: CollectorOrientation
    var array_dimensions_: ArrayDimensions
    var inlet_pipe_: Pipe
    var outlet_pipe_: Pipe

    def __init__(inout self):
        self.flat_plate_collector_ = FlatPlateCollector()
        self.collector_location_ = CollectorLocation()
        self.collector_orientation_ = CollectorOrientation()
        self.array_dimensions_ = ArrayDimensions()
        self.inlet_pipe_ = Pipe()
        self.outlet_pipe_ = Pipe()

    def __init__(inout self, flat_plate_collector: FlatPlateCollector, collector_location: CollectorLocation,
        collector_orientation: CollectorOrientation, array_dimensions: ArrayDimensions,
        inlet_pipe: Pipe, outlet_pipe: Pipe):
        self.flat_plate_collector_ = flat_plate_collector
        self.collector_location_ = collector_location
        self.collector_orientation_ = collector_orientation
        self.array_dimensions_ = array_dimensions
        self.inlet_pipe_ = inlet_pipe
        self.outlet_pipe_ = outlet_pipe

    def __init__(inout self, collector_test_specifications: CollectorTestSpecifications, collector_location: CollectorLocation,
        collector_orientation: CollectorOrientation, array_dimensions: ArrayDimensions,
        inlet_pipe: Pipe, outlet_pipe: Pipe):
        self.flat_plate_collector_ = FlatPlateCollector(collector_test_specifications)
        self.collector_location_ = collector_location
        self.collector_orientation_ = collector_orientation
        self.array_dimensions_ = array_dimensions
        self.inlet_pipe_ = inlet_pipe
        self.outlet_pipe_ = outlet_pipe

    def ncoll(self) -> Int32:
        return self.array_dimensions_.num_in_series * self.array_dimensions_.num_in_parallel

    def area_total(self) -> Float64:
        return self.flat_plate_collector_.area_coll() * self.ncoll()

    def resize_array(inout self, array_dimensions: ArrayDimensions):
        if array_dimensions.num_in_series <= 0 or array_dimensions.num_in_parallel <= 0:
            return
        self.array_dimensions_ = array_dimensions

    def resize_array(inout self, m_dot_array_design: Float64, specific_heat: Float64, temp_rise_array_design: Float64):
        if not isnormal(m_dot_array_design) or not isnormal(specific_heat) or not isnormal(temp_rise_array_design):
            return
        if m_dot_array_design <= 0.0 or specific_heat <= 0.0 or temp_rise_array_design <= 0.0:
            return
        var collector_test_specifications: CollectorTestSpecifications = self.flat_plate_collector_.TestSpecifications()
        var m_dot_design_single_collector: Float64 = collector_test_specifications.m_dot
        var exact_fractional_collectors_in_parallel: Float64 = m_dot_array_design / m_dot_design_single_collector
        if exact_fractional_collectors_in_parallel < 1.0:
            self.array_dimensions_.num_in_parallel = 1
        else:
            self.array_dimensions_.num_in_parallel = Int32(round(exact_fractional_collectors_in_parallel))      # round() rounds up at halfway point
        var m_dot_series_string: Float64 = m_dot_array_design / self.array_dimensions_.num_in_parallel      # [kg/s]
        var collector_rated_power: Float64 = self.flat_plate_collector_.RatedPowerGain()  # [W]
        var collector_rated_temp_rise: Float64 = collector_rated_power / (m_dot_series_string * specific_heat * 1.0e3)
        var exact_fractional_collectors_in_series: Float64 = temp_rise_array_design / collector_rated_temp_rise
        if exact_fractional_collectors_in_series < 1.0:
            self.array_dimensions_.num_in_series = 1
        else:
            self.array_dimensions_.num_in_series = Int32(round(exact_fractional_collectors_in_series))      # round() rounds up at halfway point

    def UsefulPowerGain(self, timestamp: tm, external_conditions: ExternalConditions) -> Float64:      # [W]
        var time_and_position: TimeAndPosition
        time_and_position.collector_location = self.collector_location_
        time_and_position.collector_orientation = self.collector_orientation_
        time_and_position.timestamp = timestamp
        var T_in: Float64 = external_conditions.inlet_fluid_flow.temp
        var T_amb: Float64 = external_conditions.weather.ambient_temp
        var m_dot: Float64 = external_conditions.inlet_fluid_flow.m_dot
        var specific_heat: Float64 = external_conditions.inlet_fluid_flow.specific_heat
        var specific_heat_capacity: Float64 = m_dot * specific_heat
        var inlet_pipe_thermal_power_loss: Float64 = self.inlet_pipe_.ThermalPowerLoss(T_in, T_amb)
        var T_out_inlet_pipe: Float64 = self.inlet_pipe_.T_out(T_in, T_amb, specific_heat_capacity)
        var T_array_in: Float64 = T_out_inlet_pipe
        var external_conditions_to_collector: ExternalConditions = external_conditions
        external_conditions_to_collector.inlet_fluid_flow.temp = T_array_in
        external_conditions_to_collector.inlet_fluid_flow.m_dot = m_dot / self.array_dimensions_.num_in_parallel
        var series_string_thermal_power_gain: Float64 = 0.0
        var T_array_out: Float64 = T_array_in
        for i in range(self.array_dimensions_.num_in_series):
            series_string_thermal_power_gain += self.flat_plate_collector_.UsefulPowerGain(time_and_position, external_conditions_to_collector)
            var T_collector_out: Float64 = self.flat_plate_collector_.T_out(time_and_position, external_conditions_to_collector)
            external_conditions_to_collector.inlet_fluid_flow.temp = T_collector_out   # to next collector in series
            T_array_out = T_collector_out
        var outlet_pipe_thermal_power_loss: Float64 = self.outlet_pipe_.ThermalPowerLoss(T_array_out, T_amb)
        var useful_power_gain: Float64 = -inlet_pipe_thermal_power_loss + series_string_thermal_power_gain * self.array_dimensions_.num_in_parallel - outlet_pipe_thermal_power_loss
        return useful_power_gain

    def T_out(self, timestamp: tm, external_conditions: ExternalConditions) -> Float64:     # [C]
        var time_and_position: TimeAndPosition
        time_and_position.collector_location = self.collector_location_
        time_and_position.collector_orientation = self.collector_orientation_
        time_and_position.timestamp = timestamp
        var T_in: Float64 = external_conditions.inlet_fluid_flow.temp
        var T_amb: Float64 = external_conditions.weather.ambient_temp
        var m_dot: Float64 = external_conditions.inlet_fluid_flow.m_dot
        var specific_heat: Float64 = external_conditions.inlet_fluid_flow.specific_heat
        var specific_heat_capacity: Float64 = m_dot * specific_heat
        var T_out_inlet_pipe: Float64 = self.inlet_pipe_.T_out(T_in, T_amb, specific_heat_capacity)
        var T_array_in: Float64 = T_out_inlet_pipe
        var external_conditions_to_collector: ExternalConditions = external_conditions
        external_conditions_to_collector.inlet_fluid_flow.temp = T_array_in
        external_conditions_to_collector.inlet_fluid_flow.m_dot = m_dot / self.array_dimensions_.num_in_parallel
        var T_array_out: Float64 = T_array_in
        for i in range(self.array_dimensions_.num_in_series):
            var T_collector_out: Float64 = self.flat_plate_collector_.T_out(time_and_position, external_conditions_to_collector)
            external_conditions_to_collector.inlet_fluid_flow.temp = T_collector_out   # to next collector in series
            T_array_out = T_collector_out
        var T_out_outlet_pipe: Float64 = self.outlet_pipe_.T_out(T_array_out, T_amb, specific_heat_capacity)
        return T_out_outlet_pipe