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
from lib_weatherfile import *
from lib_irradproc import *
from lib_pvwatts import *

const DTOR: Float64 = 0.0174532925

var _cm_vtab_pvwattsv1_1ts: StaticArray[var_info, 35] = StaticArray[var_info, 35](
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
    var_info(SSC_INPUT, SSC_NUMBER, "snow", "Snow cover", "cm", "", "PVWatts", "?=0", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "elevation", "Elevation", "m", "", "PVWatts", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "pressure", "Pressure", "millibars", "", "PVWatts", "?", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "time_step", "Time step of input data", "hr", "", "PVWatts", "?=1", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_size", "Nameplate capacity", "kW", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "derate", "System derate value", "frac", "", "PVWatts", "*", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "0/1/2/3", "Fixed,1Axis,2Axis,AziAxis", "PVWatts", "*", "MIN=0,MAX=3,INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle", "deg", "E=90,S=180,W=270", "PVWatts", "*", "MIN=0,MAX=360", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle", "deg", "H=0,V=90", "PVWatts", "naof:tilt_eq_lat", "MIN=0,MAX=90", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "rotlim", "Tracker rotation limit (+/- 1 axis)", "deg", "", "PVWatts", "?=45.0", "MIN=1,MAX=90", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "t_noct", "Nominal operating cell temperature", "C", "", "PVWatts", "?=45.0", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "t_ref", "Reference cell temperature", "C", "", "PVWatts", "?=25.0", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "gamma", "Max power temperature coefficient", "%/C", "", "PVWatts", "?=-0.5", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "inv_eff", "Inverter efficiency at rated power", "frac", "", "PVWatts", "?=0.92", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "fd", "Diffuse fraction", "0..1", "", "PVWatts", "?=1.0", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "i_ref", "Rating condition irradiance", "W/m2", "", "PVWatts", "?=1000", "POSITIVE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "poa_cutin", "Min reqd irradiance for operation", "W/m2", "", "PVWatts", "?=0", "MIN=0", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "w_stow", "Wind stow speed", "m/s", "", "PVWatts", "?=0", "MIN=0", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "tcell", "Module temperature", "C", "", "PVWatts", "*", "", ""),
    var_info(SSC_INOUT, SSC_NUMBER, "poa", "Plane of array irradiance", "W/m2", "", "PVWatts", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "dc", "DC array output", "Wdc", "", "PVWatts", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "ac", "AC system output", "Wac", "", "PVWatts", "*", "", ""),
    var_info_invalid
)

@value
struct cm_pvwattsv1_1ts(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_pvwattsv1_1ts)

    def exec(inout self):
        var year: Int = as_integer("year")
        var month: Int = as_integer("month")
        var day: Int = as_integer("day")
        var hour: Int = as_integer("hour")
        var minute: Float64 = as_double("minute")
        var lat: Float64 = as_double("lat")
        var lon: Float64 = as_double("lon")
        var tz: Float64 = as_double("tz")
        var beam: Float64 = as_double("beam")
        var diff: Float64 = as_double("diffuse")
        var tamb: Float64 = as_double("tamb")
        var wspd: Float64 = as_double("wspd")
        var snow: Float64 = as_double("snow")
        var dcrate: Float64 = as_double("system_size")
        var derate: Float64 = as_double("derate")
        var track_mode: Int = as_integer("track_mode") // 0, 1, 2, 3
        var azimuth: Float64 = as_double("azimuth")
        var tilt: Float64 = fabs(as_double("tilt"))
        var elev: Float64
        var tdry: Float64
        var pres: Float64
        if not is_assigned("elevation"):
            elev = 0.0 #assume 0 meter elevation if none is provided
        else:
            elev = as_double("elevation")
            if elev < 0.0 or elev > 5100.0:
                throw exec_error("pvwattsv1_1ts", "The elevation input is outside of the expected range. Please make sure that the units are in meters")
        if not is_assigned("pressure"):
            pres = 1013.25 #assume 1013.24 millibars site pressure if none is provided
        else:
            pres = as_double("pressure")
            if pres > 2000.0 or pres < 500.0:
                throw exec_error("pvwattsv1_1ts", "The atmospheric pressure input is outside of the expected range. Please make sure that the units are in millibars")
        /* PV RELATED SPECIFICATIONS */
        var inoct: Float64 = as_double("t_noct") + 273.15 # PVWATTS_INOCT;        /* Installed normal operating cell temperature (deg K) */
        var reftem: Float64 = as_double("t_ref") # PVWATTS_REFTEM;                /* Reference module temperature (deg C) */
        var pwrdgr: Float64 = as_double("gamma") / 100.0 # PVWATTS_PWRDGR;              /* Power degradation due to temperature (decimal fraction), si approx -0.004 */
        var efffp: Float64 = as_double("inv_eff") # PVWATTS_EFFFP;                 /* Efficiency of inverter at rated output (decimal fraction) */
        var height: Float64 = PVWATTS_HEIGHT                 /* Average array height (meters) */
        var tmloss: Float64 = 1.0 - derate / efffp  /* All losses except inverter,decimal */
        var rlim: Float64 = as_double("rotlim")             /* +/- rotation in degrees permitted by physical constraint of tracker */
        var fd: Float64 = as_double("fd") # diffuse fraction
        var i_ref: Float64 = as_double("i_ref") # reference irradiance for rating condition
        var poa_cutin: Float64 = as_double("poa_cutin") # minimum POA irradiance level required for any operation
        var wind_stow: Float64 = as_double("w_stow") # maximum wind speed before stowing.  stowing causes all output to be lost
        if dcrate < 0.1: dcrate = 0.1
        if derate < 0.0 or derate > 1.0: # Use if default ac to dc derate factor out of range
            derate = 0.77
        var pcrate: Float64 = dcrate * 1000.0      # rated output of inverter in a.c. watts; 6/29/2005
        var refpwr: Float64 = dcrate * 1000.0      # nameplate in watts; 6/29/2005
        if track_mode < 0 or track_mode > 3:
            track_mode = 0
        if tilt < 0 or tilt > 90:
            tilt = lat
        if azimuth < 0 or azimuth > 360:
            azimuth = 180.0
        var last_tcell: Float64 = as_double("tcell")
        var last_poa: Float64 = as_double("poa")
        var tccalc: pvwatts_celltemp = pvwatts_celltemp(inoct, height, 1.0)
        tccalc.set_last_values(last_tcell, last_poa)
        var irr: irrad = irrad()
        irr.set_time(year, month, day, hour, minute, IRRADPROC_NO_INTERPOLATE_SUNRISE_SUNSET)
        irr.set_location(lat, lon, tz)
        irr.set_optional(elev, pres, tamb)
        var alb: Float64 = 0.2
        if snow > 0 and snow < 150:
            alb = 0.6
        irr.set_sky_model(2, alb)
        irr.set_beam_diffuse(beam, diff)
        irr.set_surface(track_mode, tilt, azimuth, rlim, True, -1, False, 0.0)
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
        var sunup: Int
        var code: Int = irr.calc()
        if code != 0:
            throw exec_error("pvwattsv1_1ts", "failed to calculate POA irradiance with given input parameters")
        var out_poa: Float64 = 0.0
        var out_tcell: Float64 = tamb
        var out_dc: Float64 = 0.0
        var out_ac: Float64 = 0.0
        irr.get_sun(&solazi, &solzen, &solalt, 0, 0, 0, &sunup, 0, 0, 0)
        if sunup > 0:
            irr.get_angles(&aoi, &stilt, &sazi, &rot, &btd)
            irr.get_poa(&ibeam, &iskydiff, &ignddiff, 0, 0, 0)
            var poa: Float64 = ibeam + fd * (iskydiff + ignddiff)
            if poa_cutin > 0 and poa < poa_cutin:
                poa = 0.0
            var wspd_corr: Float64 = wspd if wspd >= 0 else 0.0
            if wind_stow > 0 and wspd >= wind_stow:
                poa = 0.0
            var tpoa: Float64 = transpoa(poa, beam, aoi * 3.14159265358979 / 180, False)
            var pvt: Float64 = tccalc(poa, wspd_corr, tamb)
            var dc: Float64 = dcpowr(reftem, refpwr, pwrdgr, tmloss, tpoa, pvt, i_ref)
            var ac: Float64 = dctoac(pcrate, efffp, dc)
            out_poa = poa
            out_tcell = pvt
            out_dc = dc
            out_ac = ac
        assign("poa", var_data(ssc_number_t(out_poa)))
        assign("tcell", var_data(ssc_number_t(out_tcell)))
        assign("dc", var_data(ssc_number_t(out_dc)))
        assign("ac", var_data(ssc_number_t(out_ac)))

def DEFINE_MODULE_ENTRY_pvwattsv1_1ts():
    return DEFINE_MODULE_ENTRY(pvwattsv1_1ts, "pvwattsv1_1ts- single timestep calculation of PV system performance.", 1)