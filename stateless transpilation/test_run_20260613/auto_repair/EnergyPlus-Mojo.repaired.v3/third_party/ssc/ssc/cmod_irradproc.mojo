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
from core import *
from lib_util import *
from lib_irradproc import *

const M_PI: Float64 = 3.141592653589793238462643

var _cm_vtab_irradproc: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_NUMBER, "irrad_mode", "Irradiance input mode", "0/1/2", "Beam+Diff,Global+Beam, Global+Diff", "Irradiance Processor", "?=0", "INTEGER,MIN=0,MAX=2", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "beam", "Beam normal irradiance", "W/m2", "", "Irradiance Processor", "irrad_mode~2", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "diffuse", "Diffuse horizontal irradiance", "W/m2", "", "Irradiance Processor", "irrad_mode~1", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "global", "Global horizontal irradiance", "W/m2", "", "Irradiance Processor", "irrad_mode~0", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "albedo", "Ground reflectance (time depend.)", "frac", "0..1", "Irradiance Processor", "?", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "albedo_const", "Ground reflectance (single value)", "frac", "0..1", "Irradiance Processor", "?=0.2", "", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "year", "Year", "yr", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "month", "Month", "mn", "1-12", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "day", "Day", "dy", "1-days in month", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "hour", "Hour", "hr", "0-23", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_ARRAY, "minute", "Minute", "min", "0-59", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "lat", "Latitude", "deg", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "lon", "Longitude", "deg", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tz", "Time zone", "hr", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "sky_model", "Tilted surface irradiance model", "0/1/2", "Isotropic,HDKR,Perez", "Irradiance Processor", "?=2", "INTEGER,MIN=0,MAX=2", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "0/1/2", "Fixed,1Axis,2Axis", "Irradiance Processor", "*", "MIN=0,MAX=2,INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle", "deg", "E=90,S=180,W=270", "Irradiance Processor", "*", "MIN=0,MAX=360", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle", "deg", "H=0,V=90", "Irradiance Processor", "?", "MIN=0,MAX=90", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rotlim", "Rotational limit on tracker", "deg", "", "Irradiance Processor", "?=45", "MIN=0,MAX=90", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "backtrack", "Enable backtracking", "0/1", "", "Irradiance Processor", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "gcr", "Ground coverage ratio", "0..1", "", "Irradiance Processor", "backtrack=1", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "elevation", "Elevation", "m", "", "Irradiance Processor", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tamb", "Ambient Temperature (dry bulb temperature)", "°C", "", "Irradiance Processor", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pressure", "Pressure", "mbars", "", "Irradiance Processor", "?", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_beam", "Incident Beam Irradiance", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_skydiff", "Incident Sky Diffuse", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_gnddiff", "Incident Ground Reflected Diffuse", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_skydiff_iso", "Incident Diffuse Isotropic Component", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_skydiff_cir", "Incident Diffuse Circumsolar Component", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa_skydiff_hor", "Incident Diffuse Horizon Brightening Component", "W/m2", "", "Irradiance Processor", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "incidence", "Incidence angle to surface", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "surf_tilt", "Surface tilt angle", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "surf_azm", "Surface azimuth angle", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "axis_rotation", "Tracking axis rotation angle", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "bt_diff", "Backtracking difference from ideal rotation", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sun_azm", "Solar azimuth", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sun_zen", "Solar zenith", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sun_elv", "Sun elevation", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sun_dec", "Sun declination", "deg", "", "Irradiance Processor", "*", "LENGTH_EQUAL=beam", ""),
    var_info_invalid
)

class cm_irradproc(compute_module):
    def __init__(self):
        self.add_var_info(_cm_vtab_irradproc)

    def exec(self):
        var count: Int
        var beam: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var glob: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var diff: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        var irrad_mode: Int = self.as_integer("irrad_mode")
        if irrad_mode == 0:  # beam and diffuse
            beam = self.as_array("beam", &count)
            if count < 2:
                raise general_error("need at least 2 data points in irradproc")
            diff = self.as_array("diffuse", &count)
        elif irrad_mode == 1:  # global and beam
            beam = self.as_array("beam", &count)
            if count < 2:
                raise general_error("need at least 2 data points in irradproc")
            glob = self.as_array("global", &count)
        else:  # global and diffuse
            diff = self.as_array("diffuse", &count)
            if count < 2:
                raise general_error("need at least 2 data points in irradproc")
            glob = self.as_array("global", &count)

        var year: Pointer[ssc_number_t] = self.as_array("year", &count)
        var month: Pointer[ssc_number_t] = self.as_array("month", &count)
        var day: Pointer[ssc_number_t] = self.as_array("day", &count)
        var hour: Pointer[ssc_number_t] = self.as_array("hour", &count)
        var minute: Pointer[ssc_number_t] = self.as_array("minute", &count)

        var sky_model: Int = self.as_integer("sky_model")
        var lat: Float64 = self.as_double("lat")
        var lon: Float64 = self.as_double("lon")
        var tz: Float64 = self.as_double("tz")

        var elev: Float64
        var tamb: Float64
        var pres: Float64
        if not self.is_assigned("elevation"):
            elev = 0.0  # assume 0 meter elevation if none is provided
        else:
            elev = self.as_double("elevation")
            if elev < 0 or elev > 5100:
                raise exec_error("irradproc", "The elevation input is outside of the expected range. Please make sure that the units are in meters")

        if not self.is_assigned("tamb"):
            tamb = 15.0  # assume 15°C average annual temperature if none is provided
        else:
            tamb = self.as_double("tamb")
            if tamb > 128 or tamb < -50:
                raise exec_error("irradproc", "The annual average temperature input is outside of the expected range. Please make sure that the units are in degrees Celsius")

        if not self.is_assigned("pressure"):
            pres = 1013.25  # assume 1013.24 millibars site pressure if none is provided
        else:
            pres = self.as_double("pressure")
            if pres > 2000 or pres < 500:
                raise exec_error("irradproc", "The atmospheric pressure input is outside of the expected range. Please make sure that the units are in millibars")

        var tilt: Float64 = lat
        if self.is_assigned("tilt"):
            tilt = self.as_double("tilt")

        var azimuth: Float64 = self.as_double("azimuth")
        var track_mode: Int = self.as_integer("track_mode")
        var rotlim: Float64 = self.as_double("rotlim")
        var en_backtrack: Bool = self.as_boolean("backtrack")
        var gcr: Float64 = 0.0  # use a default value since it's needed to be passed into the set_surface function, but isn't used subsequently
        if self.is_assigned("gcr"):
            gcr = self.as_double("gcr")

        var alb_const: Float64 = self.as_double("albedo_const")
        var albvec: Pointer[ssc_number_t] = Pointer[ssc_number_t]()
        if self.is_assigned("albedo"):
            albvec = self.as_array("albedo", &count)

        var p_inc: Pointer[ssc_number_t] = self.allocate("incidence", count)
        var p_surftilt: Pointer[ssc_number_t] = self.allocate("surf_tilt", count)
        var p_surfazm: Pointer[ssc_number_t] = self.allocate("surf_azm", count)
        var p_rot: Pointer[ssc_number_t] = self.allocate("axis_rotation", count)
        var p_btdiff: Pointer[ssc_number_t] = self.allocate("bt_diff", count)
        var p_azm: Pointer[ssc_number_t] = self.allocate("sun_azm", count)
        var p_zen: Pointer[ssc_number_t] = self.allocate("sun_zen", count)
        var p_elv: Pointer[ssc_number_t] = self.allocate("sun_elv", count)
        var p_dec: Pointer[ssc_number_t] = self.allocate("sun_dec", count)
        var p_poa_beam: Pointer[ssc_number_t] = self.allocate("poa_beam", count)
        var p_poa_skydiff: Pointer[ssc_number_t] = self.allocate("poa_skydiff", count)
        var p_poa_gnddiff: Pointer[ssc_number_t] = self.allocate("poa_gnddiff", count)
        var p_poa_skydiff_iso: Pointer[ssc_number_t] = self.allocate("poa_skydiff_iso", count)
        var p_poa_skydiff_cir: Pointer[ssc_number_t] = self.allocate("poa_skydiff_cir", count)
        var p_poa_skydiff_hor: Pointer[ssc_number_t] = self.allocate("poa_skydiff_hor", count)
        var p_sunup: Pointer[ssc_number_t] = self.allocate("sunup", count)
        var p_sunrise: Pointer[ssc_number_t] = self.allocate("sunrise", count)
        var p_sunset: Pointer[ssc_number_t] = self.allocate("sunset", count)

        for i in range(count):
            var t_cur: Float64 = hour[i] + minute[i] / 60.0
            var delt: Float64 = 1.0
            if i == 0:
                var t_next: Float64 = hour[i + 1] + minute[i + 1] / 60.0
                if t_cur > t_next:
                    t_next += 24
                delt = t_next - t_cur
            else:
                var t_prev: Float64 = hour[i - 1] + minute[i - 1] / 60.0
                if t_cur < t_prev:
                    t_cur += 24
                delt = t_cur - t_prev

            if abs(delt - 1.0) < 1e-14:
                delt = 1.0

            var alb: Float64 = alb_const
            if albvec and albvec[i] >= 0 and albvec[i] <= Float64(1.0):
                alb = albvec[i]

            var x = irrad()
            x.set_time(Int(year[i]), Int(month[i]), Int(day[i]), Int(hour[i]), minute[i], IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET)
            x.set_location(lat, lon, tz)
            x.set_optional(elev, pres, tamb)
            x.set_sky_model(sky_model, alb)

            if irrad_mode == 1:
                x.set_global_beam(glob[i], beam[i])
            elif irrad_mode == 2:
                x.set_global_diffuse(glob[i], diff[i])
            else:
                x.set_beam_diffuse(beam[i], diff[i])

            x.set_surface(track_mode, tilt, azimuth, rotlim, en_backtrack, gcr, False, 0.0)  # last two inputs are to force to a stow angle, which doesn't make sense for irradproc as a standalone cmod

            var code: Int = x.calc()
            if code < 0:
                raise general_error(format("irradiance processor issued error code %d", code))

            var solazi: Float64
            var solzen: Float64
            var solelv: Float64
            var soldec: Float64
            var sunrise: Float64
            var sunset: Float64
            var sunup: Int
            x.get_sun(&solazi, &solzen, &solelv, &soldec, &sunrise, &sunset, &sunup, Pointer[Float64](), Pointer[Float64](), Pointer[Float64]())

            p_azm[i] = Float64(solazi)
            p_zen[i] = Float64(solzen)
            p_elv[i] = Float64(solelv)
            p_dec[i] = Float64(soldec)
            p_sunrise[i] = Float64(sunrise)
            p_sunset[i] = Float64(sunset)
            p_sunup[i] = Float64(sunup)

            var aoi: Float64
            var stilt: Float64
            var sazi: Float64
            var rot: Float64
            var btd: Float64
            x.get_angles(&aoi, &stilt, &sazi, &rot, &btd)

            p_inc[i] = Float64(aoi)
            p_surftilt[i] = Float64(stilt)
            p_surfazm[i] = Float64(sazi)
            p_rot[i] = Float64(rot)
            p_btdiff[i] = Float64(btd)

            var beam_poa: Float64
            var skydiff: Float64
            var gnddiff: Float64
            var iso: Float64
            var cir: Float64
            var hor: Float64
            x.get_poa(&beam_poa, &skydiff, &gnddiff, &iso, &cir, &hor)

            p_poa_beam[i] = Float64(beam_poa)
            p_poa_skydiff[i] = Float64(skydiff)
            p_poa_gnddiff[i] = Float64(gnddiff)
            p_poa_skydiff_iso[i] = Float64(iso)
            p_poa_skydiff_cir[i] = Float64(cir)
            p_poa_skydiff_hor[i] = Float64(hor)

DEFINE_MODULE_ENTRY(irradproc, "Irradiance Processor", 1)