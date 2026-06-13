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
from core import var_info, compute_module, ssc_number_t, SSC_INPUT, SSC_NUMBER, SSC_ARRAY, SSC_INOUT, SSC_OUTPUT, var_info_invalid, exec_error
from lib_irradproc import irrad, perez
from lib_util import util

var M_PI: Float64 = 3.14159265358979323
var DTOR: Float64 = 0.0174532925

var _cm_vtab_poacalib: List[var_info] = List[var_info](
    #   VARTYPE           DATATYPE         NAME                 LABEL                     UNITS               META                 GROUP            REQUIRED_IF    CONSTRAINTS                      UI_HINTS
    var_info(SSC_INPUT,        SSC_NUMBER,      "latitude",          "Latitude",              "decimal degrees",  "N= positive",       "POA Calibrate", "*",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "longitude",         "Longitude",             "decimal degrees",  "E= positive",       "POA Calibrate", "*",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "time_zone",         "Time Zone",             "",                 "-7= Denver",        "POA Calibrate", "*",           "MIN=-12,MAX=12",                "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "array_tilt",        "Array tilt",            "degrees",          "0-90",              "POA Calibrate", "*",           "MIN=0,MAX=90",                  "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "array_az",          "Array Azimuth",         "degrees",          "0=N, 90=E, 180=S",  "POA Calibrate", "*",           "MIN=0,MAX=360",                 "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "year",              "Year",                  "",                 "",                  "POA Calibrate", "*",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "albedo",            "Albedo",                "",                 "",                  "POA Calibrate", "*",           "MIN=0,MAX=1",                   "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "elevation",         "Elevation",             "m",                "",                  "POA Calibrate", "?",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "tamb",              "Ambient Temperature (dry bulb temperature)","°C",     "",        "POA Calibrate", "?",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_NUMBER,      "pressure",          "Pressure",              "millibars",        "",                  "POA Calibrate", "?",           "",                              "" ),
    var_info(SSC_INPUT,        SSC_ARRAY,       "poa",               "Plane of Array",        "W/m^2",            "",                  "POA Calibrate", "*",           "LENGTH=8760",                   "" ),
    var_info(SSC_INOUT,        SSC_ARRAY,       "beam",              "Beam Irradiation",      "W/m^2",            "",                  "POA Calibrate", "*",           "LENGTH=8760",                   "" ),
    var_info(SSC_INOUT,        SSC_ARRAY,       "diffuse",           "Diffuse Irradiation",   "W/m^2",            "",                  "POA Calibrate", "*",           "LENGTH=8760",                   "" ),
    var_info(SSC_OUTPUT,       SSC_ARRAY,       "pcalc",            "Calculated POA",        "W/m^2",            "",                  "POA Calibrate", "*",           "",                   "" ),
    var_info_invalid
)

struct cm_poacalib(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_poacalib)

    def exec(inout self):
        /* Changes input Beam and Diffuse irradiation so that they yield a POA equal to input POA using the Perez transposition model, while maintaining the input ratio between beam & diffuse.
        Function assumes that input POA has been error-checked (ie: no irradiance values at night, no negative values, no unreal values). Also assumes that input beam and diffuse are always >= 0
        Program is currently set up for FIXED TILT ONLY*/
        var lat: Float64 = self.as_double("latitude")
        var lon: Float64 = self.as_double("longitude")
        var tilt: Float64 = self.as_double("array_tilt") # in degrees
        var az: Float64 = self.as_double("array_az") # in degrees
        var timezone: Float64 = self.as_double("time_zone")
        var year: Int = self.as_integer("year")
        var alb: Float64 = self.as_double("albedo")
        var elev: Float64
        var tamb: Float64
        var pres: Float64
        var num_steps: Int
        var poa: List[ssc_number_t] = self.as_array("poa", &num_steps)
        var beam: List[ssc_number_t] = self.as_array("beam", &num_steps)
        var diffuse: List[ssc_number_t] = self.as_array("diffuse", &num_steps)
        var pcalc: List[ssc_number_t] = self.allocate("pcalc", num_steps)
        if not self.is_assigned("elevation"):
            elev = 0.0 # assume 0 meter elevation if none is provided
        else:
            elev = self.as_double("elevation")
            if elev < 0.0 or elev > 5100.0:
                raise Error("poacalib: The elevation input is outside of the expected range. Please make sure that the units are in meters")
        if not self.is_assigned("tamb"):
            tamb = 15.0 # assume 15°C average annual temperature if none is provided
        else:
            tamb = self.as_double("tamb")
            if tamb > 128.0 or tamb < -50.0:
                raise Error("poacalib: The annual average temperature input is outside of the expected range. Please make sure that the units are in degrees Celsius")
        if not self.is_assigned("pressure"):
            pres = 1013.25 # assume 1013.24 millibars site pressure if none is provided
        else:
            pres = self.as_double("pressure")
            if pres > 2000.0 or pres < 500.0:
                raise Error("poacalib: The atmospheric pressure input is outside of the expected range. Please make sure that the units are in millibars")
        var idx: Int = 0
        for m in range(1, 13): # index across months
            for d in range(1, util.nday[m-1] + 1): # index across days of month
                for h in range(0, 24): # index across hours
                    var P: Float64 = poa[idx]
                    var D: Float64 = diffuse[idx]
                    var B: Float64 = beam[idx]
                    if P <= 0.0:
                        beam[idx] = 0.0
                        diffuse[idx] = 0.0
                        pcalc[idx] = 0.0
                        idx += 1
                        continue
                    var x = irrad()
                    x.set_location(lat, lon, timezone)
                    x.set_optional(elev, pres, tamb)
                    x.set_time(year, m, d, h, 30, 1.0)
                    x.set_surface(0, tilt, az, 0, 0, 0, False, 0.0)
                    x.set_sky_model(2, alb)
                    x.set_beam_diffuse(B, D)
                    var solaz: Float64
                    var zen: Float64
                    x.calc()
                    x.get_sun(&solaz, &zen, 0, 0, 0, 0, 0, 0, 0, 0)
                    solaz = solaz * DTOR
                    zen = zen * DTOR
                    var inc: Float64
                    x.get_angles(&inc, 0, 0, 0, 0)
                    inc = inc * DTOR
                    var R: Float64 = B / D
                    if inc >= DTOR * 90.0 or (P > 0.0 and D <= 0.0) or P < 1.0:
                        R = 0.0
                    var poa_arr: List[Float64] = [0.0, 0.0, 0.0]
                    var diffc: List[Float64] = [0.0, 0.0, 0.0]
                    perez(0, B, D, alb, inc, DTOR * tilt, zen, poa_arr, diffc)
                    var Pcalc: Float64 = poa_arr[0] + poa_arr[1] + poa_arr[2]
                    var B_o: Float64 = B
                    var D_o: Float64 = D
                    var flag: Bool = False # flag for unreasonable values at high zenith angles
                    var counter: Int = 0 # counter to prevent an infinite loop
                    while abs(Pcalc - P) > 0.5 and counter < 5000:
                        var incr: Float64 = abs(Pcalc - P) * 0.01
                        if Pcalc > P:
                            D = D - incr
                        else:
                            D = D + incr
                        if not flag:
                            B = D * R
                        else:
                            B = B_o
                        perez(0, B, D, alb, inc, DTOR * tilt, zen, poa_arr, diffc)
                        Pcalc = poa_arr[0] + poa_arr[1] + poa_arr[2]
                        if zen > DTOR * 85.0:
                            if B - B_o > 100.0: # if Beam getting too far away from input beam at high zenith
                                flag = True # turn on flag so that beam does not get incremented
                                B = B_o # reset beam and diffuse
                                D = D_o
                                perez(0, B, D, alb, inc, DTOR * tilt, zen, poa_arr, diffc)
                                Pcalc = poa_arr[0] + poa_arr[1] + poa_arr[2] # reset Pcalc
                                counter = 0 # reset counter
                        counter += 1
                    if counter == 5000 or B < 0.0 or D < 0.0:
                        B = -999.0
                        D = -999.0
                    beam[idx] = B
                    diffuse[idx] = D
                    pcalc[idx] = Pcalc
                    idx += 1

# DEFINE_MODULE_ENTRY(poacalib, "Calibrates beam and diffuse to give POA input", 1)
def poacalib() -> cm_poacalib:
    return cm_poacalib()