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
from lib_util import *

var _cm_vtab_wfcheck: StaticArray[var_info, 2] = StaticArray[var_info, 2](
    var_info(
        var_type = SSC_INPUT,
        data_type = SSC_STRING,
        name = "input_file",
        label = "Input weather file name",
        units = "",
        meta = "wfcsv format",
        group = "Weather File Checker",
        required_if = "*",
        constraints = "",
        ui_hints = ""
    ),
    var_info_invalid
)

@value
class cm_wfcheck(compute_module):
    var nwarnings: Int
    var nerrors: Int

    def __init__(inout self):
        self.nwarnings = 0
        self.nerrors = 0
        self.add_var_info(_cm_vtab_wfcheck)

    def warn(inout self, fmt: StringLiteral):
        var buf: String
        var ap: va_list
        va_start(ap, fmt)
        #if defined(_MSC_VER)||defined(_WIN32)
        _vsnprintf(buf, 1023, fmt, ap)
        #else
        vsnprintf(buf, 1023, fmt, ap)
        #endif
        va_end(ap)
        self.assign(util.format("warning{}", self.nwarnings), var_data(String(buf)))
        self.nwarnings += 1

    def exec(inout self):
        var wfile = weatherfile(self.as_string("input_file"))
        if not wfile.ok():
            raise general_error(wfile.message())
        if wfile.has_message():
            self.log(wfile.message(), SSC_WARNING)
        var hdr = weather_header()
        wfile.header(&hdr)
        var wf = weather_record()
        self.nwarnings = 0
        self.nerrors = 0
        var T: Float64 = 60.0
        var zenith: Float64
        var hextra: Float64
        var sunn: StaticArray[Float64, 9] = StaticArray[Float64, 9](0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        for i in range(wfile.nrecords()):
            if not wfile.read(&wf):
                self.warn("error reading record {}, stopping".format(i))
                break
            solarpos_spa(wf.year, wf.month, wf.day, wf.hour, wf.minute, 0, hdr.lat, hdr.lon, hdr.tz, 0, hdr.elev, wf.pres, wf.tdry, 0, 180, sunn)
            zenith = sunn[1]
            hextra = sunn[8]
            var gh_est: Float64 = wf.dn * cos(zenith) + wf.df
            if is_nan(gh_est):
                gh_est = wf.gh
            if not is_nan(wf.dn) and not is_nan(wf.df) and not is_nan(wf.gh):
                if gh_est > 500 and fabs(gh_est - wf.gh) / wf.gh > 0.2:
                    self.warn("beam+diffuse ({}) inconsistent with global ({}) at record {} by greater than 20 percent".format(gh_est, wf.gh, i))
                elif gh_est > 200 and fabs(gh_est - wf.gh) / wf.gh > 0.5:
                    self.warn("beam+diffuse ({}) inconsistent with global ({}) at record {} by greater than 50 percent".format(gh_est, wf.gh, i))
            if not is_nan(wf.dn) and wf.dn > 1500:
                self.warn("beam irradiance ({}) at record {} is greater than 1500".format(wf.dn, i))
            if not is_nan(wf.dn) and wf.dn < 0:
                self.warn("beam irradiance ({}) at record {} is negative".format(wf.dn, i))
            var irrmax: Float64 = 1.5 * (hextra + 150)
            if irrmax > 1500:
                irrmax = 1500
            if not is_nan(wf.df) and wf.df > irrmax:
                self.warn("diffuse irradiance ({}) at record {} is greater than threshold ({})".format(wf.df, i, irrmax))
            if not is_nan(wf.df) and wf.df < 0:
                self.warn("diffuse irradiance ({}) at record {} is negative".format(wf.df, i))
            if not is_nan(wf.gh) and wf.gh > irrmax:
                self.warn("global irradiance ({}) at record {} is greater than threshold ({})".format(wf.gh, i, irrmax))
            if not is_nan(wf.gh) and wf.gh < 0:
                self.warn("global irradiance ({}) at record {} is negative".format(wf.gh, i))
            var nirrnans: Int = 0
            if is_nan(wf.dn):
                nirrnans += 1
            if is_nan(wf.gh):
                nirrnans += 1
            if is_nan(wf.df):
                nirrnans += 1
            if nirrnans > 1:
                self.warn("[{} {} {}] only 1 component of irradiance specified at record {}".format(wf.gh, wf.dn, wf.df, i))
            if wf.wspd > 30:
                self.warn("wind speed ({}) greater than 30 m/s at record {}".format(wf.wspd, i))
            if wf.wspd < 0:
                self.warn("wind speed ({}) less than 0 m/s at record {}".format(wf.wspd, i))
            if wf.wdir > 360:
                self.warn("wind direction angle ({}) greater than 360 degrees at record {}".format(wf.wdir, i))
            if wf.wdir < 0:
                self.warn("wind direction angle ({}) less than 0 degrees at record {}".format(wf.wdir, i))
            if wf.tdry > T:
                self.warn("dry bulb temperature ({}) greater than {} C at record {}".format(wf.tdry, T, i))
            if wf.tdry < -T:
                self.warn("dry bulb temperature ({}) less than -{} C at record {}".format(wf.tdry, T, i))
            if wf.twet > T:
                self.warn("wet bulb temperature ({}) greater than {} C at record {}".format(wf.twet, T, i))
            if wf.twet < -T:
                self.warn("wet bulb temperature ({}) less than -{} C at record {}".format(wf.twet, T, i))
            if wf.tdew > T:
                self.warn("dew point temperature ({}) greater than {} C at record {}".format(wf.tdew, T, i))
            if wf.tdew < -T:
                self.warn("dew point temperature ({}) less than -{} C at record {}".format(wf.tdew, T, i))
            if wf.rhum < 2:
                self.warn("relative humidity ({}) less than 2 percent at record {}".format(wf.rhum, i))
            if wf.rhum > 100:
                self.warn("relative humidity ({}) greater than 100 percent at record {}".format(wf.rhum, i))
            if wf.pres < 200:
                self.warn("pressure ({}) less than 200 millibar at record {}".format(wf.pres, i))
            if wf.pres > 1100:
                self.warn("pressure greater than 1100 millibar at record {}".format(wf.pres, i))
            if self.nwarnings >= 99:
                self.warn("bailing... too many warnings.")
                break
        self.assign("nwarnings", var_data(ssc_number_t(self.nwarnings)))

DEFINE_MODULE_ENTRY(wfcheck, "Weather file checker.", 1)