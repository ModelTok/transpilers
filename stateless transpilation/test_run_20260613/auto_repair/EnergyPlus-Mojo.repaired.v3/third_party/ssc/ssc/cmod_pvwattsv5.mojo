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
from memory import unique_ptr
from core import *
from common import *
from lib_weatherfile import *
from lib_irradproc import *
from lib_pvwatts import *
from lib_pvshade import *
from lib_pvmodel import *
from lib_pv_incidence_modifier import *

enum pvwatts_tracking_input: Int32 { FIXED_OPEN_RACK = 0, FIXED_ROOF_MOUNT = 1, ONE_AXIS_SELF_SHADED = 2, ONE_AXIS_BACKTRACKED = 3, TWO_AXIS = 4, AZIMUTH_AXIS = 5 }

var _cm_vtab_pvwattsv5_part1: StaticArray[var_info, 6] = StaticArray[var_info, 6](
    var_info(SSC_INOUT, SSC_NUMBER, "system_use_lifetime_output", "Run lifetime simulation", "0/1", "", "Lifetime", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "analysis_period", "Analysis period", "years", "", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "dc_degradation", "Annual DC degradation for lifetime simulations", "%/year", "", "Lifetime", "system_use_lifetime_output=1", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "solar_resource_file", "Weather file path", "", "", "Solar Resource", "?", "", ""),
    var_info(SSC_INPUT, SSC_TABLE, "solar_resource_data", "Weather data", "", "dn,df,tdry,wspd,lat,lon,tz", "Solar Resource", "?", "", ""),
    var_info_invalid
)

var _cm_vtab_pvwattsv5_common: StaticArray[var_info, 9] = StaticArray[var_info, 9](
    var_info(SSC_INPUT, SSC_NUMBER, "system_capacity", "System size (DC nameplate)", "kW", "", "System Design", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "module_type", "Module type", "0/1/2", "Standard,Premium,Thin film", "System Design", "?=0", "MIN=0,MAX=2,INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "dc_ac_ratio", "DC to AC ratio", "ratio", "", "System Design", "?=1.1", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "inv_eff", "Inverter efficiency at rated power", "%", "", "System Design", "?=96", "MIN=90,MAX=99.5", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "losses", "System losses", "%", "Total system losses", "System Design", "*", "MIN=-5,MAX=99", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "array_type", "Array type", "0/1/2/3/4", "Fixed OR,Fixed Roof,1Axis,Backtracked,2Axis", "System Design", "*", "MIN=0,MAX=4,INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle", "deg", "H=0,V=90", "System Design", "array_type<4", "MIN=0,MAX=90", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle", "deg", "E=90,S=180,W=270", "System Design", "array_type<4", "MIN=0,MAX=360", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "gcr", "Ground coverage ratio", "0..1", "", "System Design", "?=0.4", "MIN=0.01,MAX=0.99", ""),
    var_info_invalid
)

var _cm_vtab_pvwattsv5_part2: StaticArray[var_info, 37] = StaticArray[var_info, 37](
    var_info(SSC_INPUT, SSC_MATRIX, "shading:timestep", "Time step beam shading loss", "%", "", "System Design", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "shading:mxh", "Month x Hour beam shading loss", "%", "", "System Design", "?", "", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "shading:azal", "Azimuth x altitude beam shading loss", "%", "", "System Design", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "shading:diff", "Diffuse shading loss", "%", "", "System Design", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "batt_simple_enable", "Enable Battery", "0/1", "", "System Design", "?=0", "BOOLEAN", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "gh", "Global horizontal irradiance", "W/m2", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dn", "Beam irradiance", "W/m2", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "df", "Diffuse irradiance", "W/m2", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tamb", "Ambient temperature (dry bulb temperature)", "C", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wspd", "Wind speed", "m/s", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sunup", "Sun up over horizon", "0/1", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "shad_beam_factor", "Shading factor for beam radiation", "", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "aoi", "Angle of incidence", "deg", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa", "Plane of array irradiance", "W/m2", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tpoa", "Transmitted plane of array irradiance", "W/m2", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tcell", "Module temperature", "C", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dc", "DC array power", "W", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "ac", "AC inverter power", "W", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "gen", "AC system power (lifetime)", "kWh", "", "Time Series", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_monthly", "Plane of array irradiance", "kWh/m2", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "solrad_monthly", "Daily average solar irradiance", "kWh/m2/day", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dc_monthly", "DC array output", "kWh", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "ac_monthly", "AC system output", "kWh", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "monthly_energy", "Monthly energy", "kWh", "", "Monthly", "*", "LENGTH=12", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "solrad_annual", "Daily average solar irradiance", "kWh/m2/day", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "ac_annual", "Annual AC system output", "kWh", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "annual_energy", "Annual energy", "kWh", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "capacity_factor", "Capacity factor", "%", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "kwh_per_kw", "Energy yield", "kWh/kW", "", "Annual", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "location", "Location ID", "", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "city", "City", "", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "state", "State", "", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "lat", "Latitude", "deg", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "lon", "Longitude", "deg", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "tz", "Time zone", "hr", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "elev", "Site elevation", "m", "", "Location", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "inverter_count", "Inverter count", "", "", "", "INTEGER,MIN=0", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "inverter_efficiency", "Inverter efficiency at rated power", "%", "", "PVWatts", "?=96", "MIN=90,MAX=99.5", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "ts_shift_hours", "Time offset for interpreting time series outputs", "hours", "", "Miscellaneous", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "percent_complete", "Estimated percent of total comleted simulation", "%", "", "Miscellaneous", "", "", ""),
    var_info_invalid
)

class cm_pvwattsv5_base(compute_module):
    var dc_nameplate: Float64
    var dc_ac_ratio: Float64
    var ac_nameplate: Float64
    var inv_eff_percent: Float64
    var loss_percent: Float64
    var tilt: Float64
    var azimuth: Float64
    var gamma: Float64
    var use_ar_glass: Bool
    var module_type: Int32
    var track_mode: Int32
    var inoct: Float64
    var shade_mode_1x: Int32
    var array_type: Int32
    var gcr: Float64
    var skydiff_table: sssky_diffuse_table
    var ibeam: Float64
    var iskydiff: Float64
    var ignddiff: Float64
    var solazi: Float64
    var solzen: Float64
    var solalt: Float64
    var aoi: Float64
    var stilt: Float64
    var sazi: Float64
    var rot: Float64
    var btd: Float64
    var sunup: Int32
    var tccalc: pvwatts_celltemp
    var poa: Float64
    var tpoa: Float64
    var pvt: Float64
    var dc: Float64
    var ac: Float64

    def __init__(inout self):
        self.tccalc = pvwatts_celltemp()
        self.dc_nameplate = Float64.NaN
        self.dc_ac_ratio = Float64.NaN
        self.ac_nameplate = Float64.NaN
        self.inv_eff_percent = Float64.NaN
        self.loss_percent = Float64.NaN
        self.tilt = Float64.NaN
        self.azimuth = Float64.NaN
        self.gamma = Float64.NaN
        self.use_ar_glass = False
        self.module_type = -999
        self.track_mode = -999
        self.array_type = -999
        self.shade_mode_1x = -999
        self.inoct = Float64.NaN
        self.gcr = Float64.NaN
        self.ibeam = Float64.NaN
        self.iskydiff = Float64.NaN
        self.ignddiff = Float64.NaN
        self.solazi = Float64.NaN
        self.solzen = Float64.NaN
        self.solalt = Float64.NaN
        self.aoi = Float64.NaN
        self.stilt = Float64.NaN
        self.sazi = Float64.NaN
        self.rot = Float64.NaN
        self.btd = Float64.NaN
        self.sunup = 0
        self.poa = Float64.NaN
        self.tpoa = Float64.NaN
        self.pvt = Float64.NaN
        self.dc = Float64.NaN
        self.ac = Float64.NaN

    def __del__(owned self):

    def setup_system_inputs(inout self):
        self.dc_nameplate = self.as_double("system_capacity") * 1000
        self.dc_ac_ratio = self.as_double("dc_ac_ratio")
        self.ac_nameplate = self.dc_nameplate / self.dc_ac_ratio
        self.inv_eff_percent = self.as_double("inv_eff")
        self.loss_percent = self.as_double("losses")
        if self.is_assigned("tilt"):
            self.tilt = self.as_double("tilt")
        if self.is_assigned("azimuth"):
            self.azimuth = self.as_double("azimuth")
        self.gamma = 0
        self.use_ar_glass = False
        self.module_type = self.as_integer("module_type")
        if self.module_type == 0:
            self.gamma = -0.0047
            self.use_ar_glass = False
        elif self.module_type == 1:
            self.gamma = -0.0035
            self.use_ar_glass = True
        elif self.module_type == 2:
            self.gamma = -0.0020
            self.use_ar_glass = False
        self.track_mode = 0
        self.inoct = 45
        self.shade_mode_1x = 0
        self.array_type = self.as_integer("array_type")
        if self.array_type == pvwatts_tracking_input.FIXED_OPEN_RACK:
            self.track_mode = 0
            self.inoct = 45
            self.shade_mode_1x = 0
        elif self.array_type == pvwatts_tracking_input.FIXED_ROOF_MOUNT:
            self.track_mode = 0
            self.inoct = 49
            self.shade_mode_1x = 0
        elif self.array_type == pvwatts_tracking_input.ONE_AXIS_SELF_SHADED:
            self.track_mode = 1
            self.inoct = 45
            self.shade_mode_1x = 0
        elif self.array_type == pvwatts_tracking_input.ONE_AXIS_BACKTRACKED:
            self.track_mode = 1
            self.inoct = 45
            self.shade_mode_1x = 1
        elif self.array_type == pvwatts_tracking_input.TWO_AXIS:
            self.track_mode = 2
            self.inoct = 45
            self.shade_mode_1x = 0
        elif self.array_type == pvwatts_tracking_input.AZIMUTH_AXIS:
            self.track_mode = 3
            self.inoct = 45
            self.shade_mode_1x = 0
        if (self.array_type == pvwatts_tracking_input.ONE_AXIS_SELF_SHADED or self.array_type == pvwatts_tracking_input.ONE_AXIS_BACKTRACKED) and self.tilt > 0:
            self.log("A non-zero tilt was assigned for a single-axis tracking system. This is a very uncommon configuration.", SSC_WARNING)
        self.gcr = 0.4
        if self.track_mode == 1 and self.is_assigned("gcr"):
            self.gcr = self.as_double("gcr")
        self.skydiff_table.init(self.tilt, self.gcr)

    def initialize_cell_temp(inout self, ts_hour: Float64, last_tcell: Float64 = -9999, last_poa: Float64 = -9999):
        self.tccalc = pvwatts_celltemp(self.inoct + 273.15, PVWATTS_HEIGHT, ts_hour)
        if last_tcell > -99 and last_poa >= 0:
            self.tccalc.set_last_values(last_tcell, last_poa)

    def process_irradiance(inout self, year: Int32, month: Int32, day: Int32, hour: Int32, minute: Float64, ts_hour: Float64,
        lat: Float64, lon: Float64, tz: Float64, dn: Float64, df: Float64, alb: Float64, elev: Float64, pres: Float64, tdry: Float64) -> Int32:
        var irr: irrad = irrad()
        irr.set_time(year, month, day, hour, minute, ts_hour)
        irr.set_location(lat, lon, tz)
        irr.set_optional(elev, pres, tdry)
        irr.set_sky_model(2, alb)
        irr.set_beam_diffuse(dn, df)
        irr.set_surface(self.track_mode, self.tilt, self.azimuth, 45.0,
            self.shade_mode_1x == 1,
            self.gcr, False, 0.0)
        var code: Int32 = irr.calc()
        irr.get_sun(&self.solazi, &self.solzen, &self.solalt, 0, 0, 0, &self.sunup, 0, 0, 0)
        irr.get_angles(&self.aoi, &self.stilt, &self.sazi, &self.rot, &self.btd)
        irr.get_poa(&self.ibeam, &self.iskydiff, &self.ignddiff, 0, 0, 0)
        return code

    def powerout(inout self, time: Float64, degradationFactor: Float64, shad_beam: Float64, shad_diff: Float64, dni: Float64, dhi: Float64, alb: Float64, wspd: Float64, tdry: Float64):
        if self.sunup > 0:
            if self.sunup > 0 and self.track_mode == 1 and self.shade_mode_1x == 0:
                var shad1xf: Float64 = shadeFraction1x(self.solazi, self.solzen, self.tilt, self.azimuth, self.gcr, self.rot)
                shad_beam *= (ssc_number_t)(1 - shad1xf)
                if self.shade_mode_1x == 0 and self.iskydiff > 0:
                    var reduced_skydiff: Float64 = self.iskydiff
                    var Fskydiff: Float64 = 1.0
                    var reduced_gnddiff: Float64 = self.ignddiff
                    var Fgnddiff: Float64 = 1.0
                    diffuse_reduce(self.solzen, self.stilt,
                        dni, dhi, self.iskydiff, self.ignddiff,
                        self.gcr, alb, 1000, self.skydiff_table,
                        reduced_skydiff, Fskydiff,
                        reduced_gnddiff, Fgnddiff)
                    if Fskydiff >= 0 and Fskydiff <= 1:
                        self.iskydiff *= Fskydiff
                    else:
                        self.log(util.format("sky diffuse reduction factor invalid at time %lg: fskydiff=%lg, stilt=%lg", time, Fskydiff, self.stilt), SSC_NOTICE, (float)time)
                    if Fgnddiff >= 0 and Fgnddiff <= 1:
                        self.ignddiff *= Fgnddiff
                    else:
                        self.log(util.format("gnd diffuse reduction factor invalid at time %lg: fgnddiff=%lg, stilt=%lg", time, Fgnddiff, self.stilt), SSC_NOTICE, (float)time)
            self.ibeam *= shad_beam
            self.iskydiff *= shad_diff
            self.poa = self.ibeam + self.iskydiff + self.ignddiff
            var wspd_corr: Float64 = wspd if wspd >= 0 else 0
            self.tpoa = self.poa
            if self.aoi > AOI_MIN and self.aoi < AOI_MAX:
                var mod: Float64 = iam(self.aoi, self.use_ar_glass)
                self.tpoa = self.poa - (1.0 - mod) * dni * cosd(self.aoi)
                if self.tpoa < 0.0:
                    self.tpoa = 0.0
                if self.tpoa > self.poa:
                    self.tpoa = self.poa
            self.pvt = self.tccalc(self.poa, wspd_corr, tdry)
            self.dc = self.dc_nameplate * (1.0 + self.gamma * (self.pvt - 25.0)) * self.tpoa / 1000.0
            self.dc = self.dc * (1 - self.loss_percent / 100)
            self.dc *= degradationFactor
            var etanom: Float64 = self.inv_eff_percent / 100.0
            var etaref: Float64 = 0.9637
            var A: Float64 = -0.0162
            var B: Float64 = -0.0059
            var C: Float64 = 0.9858
            var pdc0: Float64 = self.ac_nameplate / etanom
            var plr: Float64 = self.dc / pdc0
            self.ac = 0
            if plr > 0:
                var eta: Float64 = (A * plr + B / plr + C) * etanom / etaref
                self.ac = self.dc * eta
            if self.ac > self.ac_nameplate:
                self.ac = self.ac_nameplate
            if self.ac < 0:
                self.ac = 0
        else:
            self.poa = 0
            self.tpoa = 0
            self.pvt = tdry
            self.dc = 0
            self.ac = 0

class cm_pvwattsv5(cm_pvwattsv5_base):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_pvwattsv5_part1)
        self.add_var_info(_cm_vtab_pvwattsv5_common)
        self.add_var_info(_cm_vtab_pvwattsv5_part2)
        self.add_var_info(vtab_adjustment_factors)
        self.add_var_info(vtab_technology_outputs)

    def exec(inout self):
        var wdprov: unique_ptr[weather_data_provider]
        if self.is_assigned("solar_resource_file"):
            var file: String = self.as_string("solar_resource_file")
            wdprov = unique_ptr[weather_data_provider](weatherfile(file))
            var wfile: weatherfile = wdprov[] as weatherfile
            if not wfile.ok():
                raise exec_error("pvwattsv5", wfile.message())
            if wfile.has_message():
                self.log(wfile.message(), SSC_WARNING)
        elif self.is_assigned("solar_resource_data"):
            wdprov = unique_ptr[weather_data_provider](weatherdata(self.lookup("solar_resource_data")))
        else:
            raise exec_error("pvwattsv5", "no weather data supplied")
        self.setup_system_inputs()
        var haf: adjustment_factors = adjustment_factors(self, "adjust")
        if not haf.setup():
            raise exec_error("pvwattsv5", "failed to setup adjustment factors: " + haf.error())
        var shad: shading_factor_calculator = shading_factor_calculator()
        if not shad.setup(self, ""):
            raise exec_error("pvwattsv5", shad.get_error())
        var hdr: weather_header = weather_header()
        wdprov[].header(&hdr)
        var ts_shift_hours: Float64 = 0.0
        var instantaneous: Bool = True
        if wdprov[].has_data_column(weather_data_provider.MINUTE):
            var rec: weather_record = weather_record()
            if wdprov[].read(&rec):
                ts_shift_hours = rec.minute / 60.0
            wdprov[].rewind()
        elif wdprov[].nrecords() == 8760:
            instantaneous = False
            ts_shift_hours = 0.5
        else:
            raise exec_error("pvwattsv5", "subhourly weather files must specify the minute for each record")
        self.assign("ts_shift_hours", var_data((ssc_number_t)ts_shift_hours))
        var wf: weather_record = weather_record()
        var nyears: Int = 1
        var degradationFactor: List[Float64] = List[Float64]()
        if self.as_boolean("system_use_lifetime_output"):
            nyears = self.as_unsigned_long("analysis_period")
            var dc_degradation: List[Float64] = self.as_vector_double("dc_degradation")
            if dc_degradation.size == 1:
                degradationFactor.append(1.0)
                for y in range(1, nyears):
                    degradationFactor.append(pow((1.0 - dc_degradation[0] / 100.0), y))
            else:
                if dc_degradation.size != nyears:
                    raise exec_error("pvwattsv5", "length of degradation array must be equal to analysis period")
                for y in range(nyears):
                    degradationFactor.append(1.0 - dc_degradation[y] / 100.0)
        else:
            degradationFactor.append(1.0)
        var nrec: Int = wdprov[].nrecords()
        var nlifetime: Int = nrec * nyears
        var step_per_hour: Int = nrec / 8760
        if step_per_hour < 1 or step_per_hour > 60 or step_per_hour * 8760 != nrec:
            raise exec_error("pvwattsv5", util.format("invalid number of data records (%d): must be an integer multiple of 8760", (int)nrec))
        var p_gh: Pointer[ssc_number_t] = self.allocate("gh", nrec)
        var p_dn: Pointer[ssc_number_t] = self.allocate("dn", nrec)
        var p_df: Pointer[ssc_number_t] = self.allocate("df", nrec)
        var p_tamb: Pointer[ssc_number_t] = self.allocate("tamb", nrec)
        var p_wspd: Pointer[ssc_number_t] = self.allocate("wspd", nrec)
        var p_sunup: Pointer[ssc_number_t] = self.allocate("sunup", nrec)
        var p_aoi: Pointer[ssc_number_t] = self.allocate("aoi", nrec)
        var p_shad_beam: Pointer[ssc_number_t] = self.allocate("shad_beam_factor", nrec)
        var p_tcell: Pointer[ssc_number_t] = self.allocate("tcell", nrec)
        var p_poa: Pointer[ssc_number_t] = self.allocate("poa", nrec)
        var p_tpoa: Pointer[ssc_number_t] = self.allocate("tpoa", nrec)
        var p_dc: Pointer[ssc_number_t] = self.allocate("dc", nrec)
        var p_ac: Pointer[ssc_number_t] = self.allocate("ac", nrec)
        var p_gen: Pointer[ssc_number_t] = self.allocate("gen", nlifetime)
        var ts_hour: Float64 = 1.0 / step_per_hour
        self.initialize_cell_temp(ts_hour)
        var annual_kwh: Float64 = 0
        var idx_life: Int = 0
        var percent: Float32 = 0
        for y in range(nyears):
            var idx: Int = 0
            for hour in range(8760):
                var NSTATUS_UPDATES: Int = 50
                if hour % (8760 / NSTATUS_UPDATES) == 0:
                    var techs: Float32 = 3
                    percent = 100.0 * ((float)idx_life + 1) / ((float)nlifetime) / techs
                    if not self.update("", percent, (float)hour):
                        raise exec_error("pvwattsv5", "simulation canceled at hour " + util.to_string(hour + 1.0))
                for jj in range(step_per_hour):
                    if not wdprov[].read(&wf):
                        raise exec_error("pvwattsv5", util.format("could not read data line %d of %d in weather file", (int)(idx + 1), (int)nrec))
                    p_gh[idx] = (ssc_number_t)wf.gh
                    p_dn[idx] = (ssc_number_t)wf.dn
                    p_df[idx] = (ssc_number_t)wf.df
                    p_tamb[idx] = (ssc_number_t)wf.tdry
                    p_wspd[idx] = (ssc_number_t)wf.wspd
                    p_tcell[idx] = (ssc_number_t)wf.tdry
                    var alb: Float64 = 0.2
                    if wf.alb.is_finite() and wf.alb > 0 and wf.alb < 1:
                        alb = wf.alb
                    var code: Int32 = self.process_irradiance(wf.year, wf.month, wf.day, wf.hour, wf.minute,
                        IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET if instantaneous else ts_hour,
                        hdr.lat, hdr.lon, hdr.tz, wf.dn, wf.df, alb, hdr.elev, wf.pres, wf.tdry)
                    if -1 == code:
                        self.log(util.format("beam irradiance exceeded extraterrestrial value at record [y:%d m:%d d:%d h:%d]",
                            wf.year, wf.month, wf.day, wf.hour))
                    elif 0 != code:
                        raise exec_error("pvwattsv5",
                            util.format("failed to process irradiation on surface (code: %d) [y:%d m:%d d:%d h:%d]",
                                code, wf.year, wf.month, wf.day, wf.hour))
                    p_sunup[idx] = (ssc_number_t)self.sunup
                    p_aoi[idx] = (ssc_number_t)self.aoi
                    var shad_beam: Float64 = 1.0
                    if shad.fbeam(hour, wf.minute, self.solalt, self.solazi):
                        shad_beam = shad.beam_shade_factor()
                    p_shad_beam[idx] = (ssc_number_t)shad_beam
                    if self.sunup > 0:
                        self.powerout((double)idx, degradationFactor[y], shad_beam, shad.fdiff(), wf.dn, wf.df, alb, wf.wspd, wf.tdry)
                        p_shad_beam[idx] = (ssc_number_t)shad_beam
                        p_poa[idx] = (ssc_number_t)self.poa
                        p_tpoa[idx] = (ssc_number_t)self.tpoa
                        p_tcell[idx] = (ssc_number_t)self.pvt
                        p_dc[idx] = (ssc_number_t)self.dc
                        p_ac[idx] = (ssc_number_t)self.ac
                        p_gen[idx_life] = (ssc_number_t)(self.ac * haf(hour) * util.watt_to_kilowatt)
                        if y == 0:
                            annual_kwh += p_gen[idx] / step_per_hour
                    idx += 1
                    idx_life += 1
            wdprov[].rewind()
            if y == 0:
                self.accumulate_monthly("gen", "monthly_energy", ts_hour)
                self.accumulate_annual("gen", "annual_energy", ts_hour)
        self.accumulate_monthly("dc", "dc_monthly", 0.001 * ts_hour)
        self.accumulate_monthly("ac", "ac_monthly", 0.001 * ts_hour)
        var poam: Pointer[ssc_number_t] = self.accumulate_monthly("poa", "poa_monthly", 0.001 * ts_hour)
        var solrad: Pointer[ssc_number_t] = self.allocate("solrad_monthly", 12)
        var solrad_ann: Float64 = 0
        for m in range(12):
            solrad[m] = poam[m] / util.nday[m]
            solrad_ann += solrad[m]
        self.assign("solrad_annual", var_data(solrad_ann / 12))
        self.accumulate_annual("ac", "ac_annual", 0.001 * ts_hour)
        self.assign("location", var_data(hdr.location))
        self.assign("city", var_data(hdr.city))
        self.assign("state", var_data(hdr.state))
        self.assign("lat", var_data((ssc_number_t)hdr.lat))
        self.assign("lon", var_data((ssc_number_t)hdr.lon))
        self.assign("tz", var_data((ssc_number_t)hdr.tz))
        self.assign("elev", var_data((ssc_number_t)hdr.elev))
        self.assign("percent_complete", var_data((ssc_number_t)percent))
        self.assign("inverter_count", var_data((ssc_number_t)1))
        self.assign("inverter_efficiency", var_data((ssc_number_t)(self.as_double("inv_eff"))))
        var kWhperkW: Float64 = util.kilowatt_to_watt * annual_kwh / self.dc_nameplate
        self.assign("capacity_factor", var_data((ssc_number_t)(kWhperkW / 87.6)))
        self.assign("kwh_per_kw", var_data((ssc_number_t)kWhperkW))

DEFINE_MODULE_ENTRY(pvwattsv5, "PVWatts V5 - integrated hourly weather reader and PV system simulator.", 3)

/* *****************************************************************************
            SINGLE TIME STEP VERSION   29oct2014
 ***************************************************************************** */
var _cm_vtab_pvwattsv5_1ts_weather: StaticArray[var_info, 17] = StaticArray[var_info, 17](
    var_info(SSC_INPUT, SSC_NUMBER, "year", "Year", "yr", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "month", "Month", "mn", "1-12", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "day", "Day", "dy", "1-days in month", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "hour", "Hour", "hr", "0-23", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "minute", "Minute", "min", "0-59", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "lat", "Latitude", "deg", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "lon", "Longitude", "deg", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tz", "Time zone", "hr", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "beam", "Beam normal irradiance", "W/m2", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "diffuse", "Diffuse irradiance", "W/m2", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tamb", "Ambient temperature (dry bulb temperature)", "C", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "wspd", "Wind speed", "m/s", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "alb", "Albedo", "frac", "", "PVWatts", "?=0.2", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "time_step", "Time step of input data", "hr", "", "PVWatts", "?=1", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "elevation", "Elevation", "m", "", "PVWatts", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pressure", "Pressure", "mbars", "", "PVWatts", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "shaded_percent", "Percent of panels that are shaded", "%", "", "PVWatts", "?=0", "MIN=0,MAX=100", ""),
    var_info_invalid
)

var _cm_vtab_pvwattsv5_1ts_outputs: StaticArray[var_info, 5] = StaticArray[var_info, 5](
    var_info(SSC_INOUT, SSC_NUMBER, "tcell", "Module temperature", "C", "Output from last time step may be used as input", "PVWatts", "", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "poa", "Plane of array irradiance", "W/m2", "Output from last time step may be used as input", "PVWatts", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "dc", "DC array output", "Wdc", "", "PVWatts", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "ac", "AC system output", "Wac", "", "PVWatts", "*", "", ""),
    var_info_invalid
)

class cm_pvwattsv5_1ts(cm_pvwattsv5_base):
    var system_inputs_are_setup: Bool

    def __init__(inout self):
        self.add_var_info(_cm_vtab_pvwattsv5_1ts_weather)
        self.add_var_info(_cm_vtab_pvwattsv5_common)
        self.add_var_info(_cm_vtab_pvwattsv5_1ts_outputs)
        self.system_inputs_are_setup = False

    def exec(inout self):
        if not self.system_inputs_are_setup:
            self.setup_system_inputs()
            self.system_inputs_are_setup = True
        var ts: Float64 = self.as_number("time_step")
        if self.is_assigned("tcell") and self.is_assigned("poa"):
            self.initialize_cell_temp(ts, self.as_double("tcell"), self.as_double("poa"))
        else:
            self.initialize_cell_temp(ts)
        var year: Int32 = self.as_integer("year")
        var month: Int32 = self.as_integer("month")
        var day: Int32 = self.as_integer("day")
        var hour: Int32 = self.as_integer("hour")
        var minute: Float64 = self.as_double("minute")
        var lat: Float64 = self.as_double("lat")
        var lon: Float64 = self.as_double("lon")
        var tz: Float64 = self.as_double("tz")
        var beam: Float64 = self.as_double("beam")
        var diff: Float64 = self.as_double("diffuse")
        var tamb: Float64 = self.as_double("tamb")
        var wspd: Float64 = self.as_double("wspd")
        var alb: Float64 = self.as_double("alb")
        var elev: Float64
        var pres: Float64
        if not self.is_assigned("elevation"):
            elev = 0
        else:
            elev = self.as_double("elevation")
            if elev < 0 or elev > 5100:
                raise exec_error("poacalib", "The elevation input is outside of the expected range. Please make sure that the units are in meters")
        if not self.is_assigned("pressure"):
            pres = 1013.25
        else:
            pres = self.as_double("pressure")
            if pres > 2000 or pres < 500:
                raise exec_error("poacalib", "The atmospheric pressure input is outside of the expected range. Please make sure that the units are in millibars")
        var shad_beam: Float64 = 1.0 - self.as_double("shaded_percent") / 100.0
        self.powerout(0, 1.0, shad_beam, 1.0, beam, diff, alb, wspd, tamb)
        var code: Int32 = self.process_irradiance(year, month, day, hour, minute,
            IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET,
            lat, lon, tz, beam, diff, alb, elev, pres, tamb)
        if code != 0:
            raise exec_error("pvwattsv5_1ts", "failed to calculate plane of array irradiance with given input parameters")
        self.powerout(0, 1.0, shad_beam, 1.0, beam, diff, alb, wspd, tamb)
        self.assign("poa", var_data((ssc_number_t)self.poa))
        self.assign("tcell", var_data((ssc_number_t)self.pvt))
        self.assign("dc", var_data((ssc_number_t)self.dc))
        self.assign("ac", var_data((ssc_number_t)self.ac))

DEFINE_MODULE_ENTRY(pvwattsv5_1ts, "pvwattsv5_1ts- single timestep calculation of PV system performance.", 1)