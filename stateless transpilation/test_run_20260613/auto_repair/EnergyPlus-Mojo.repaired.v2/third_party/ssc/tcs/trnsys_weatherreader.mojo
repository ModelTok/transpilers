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
from tcstype import *
from stdlib import List, String, Float64, Int, Bool, print, open, File, read_line, close, atof, M_PI

# define M_PI if not defined
if not defined("M_PI"):
    let M_PI: Float64 = 3.14159265358979323

# enum constants
let I_FILENAME: Int = 0
let I_YEAR: Int = 1
let I_MONTH: Int = 2
let I_DAY: Int = 3
let I_HOUR: Int = 4
let I_MINUTE: Int = 5
let I_GLOBAL: Int = 6
let I_BEAM: Int = 7
let I_DIFFUSE: Int = 8
let I_TDRY: Int = 9
let I_TWET: Int = 10
let I_TDEW: Int = 11
let I_WSPD: Int = 12
let I_WDIR: Int = 13
let I_RHUM: Int = 14
let I_PRES: Int = 15
let I_SNOW: Int = 16
let I_ALBEDO: Int = 17
let I_POA: Int = 18
let I_SOLAZI: Int = 19
let I_SOLZEN: Int = 20
let I_LAT: Int = 21
let I_LON: Int = 22
let I_TZ: Int = 23
let I_SHIFT: Int = 24
let O_YEAR: Int = 25
let O_MONTH: Int = 26
let O_DAY: Int = 27
let O_HOUR: Int = 28
let O_MINUTE: Int = 29
let O_GLOBAL: Int = 30
let O_BEAM: Int = 31
let O_DIFFUSE: Int = 32
let O_TDRY: Int = 33
let O_TWET: Int = 34
let O_TDEW: Int = 35
let O_WSPD: Int = 36
let O_WDIR: Int = 37
let O_RHUM: Int = 38
let O_PRES: Int = 39
let O_SNOW: Int = 40
let O_ALBEDO: Int = 41
let O_POA: Int = 42
let O_SOLAZI: Int = 43
let O_SOLZEN: Int = 44
let O_LAT: Int = 45
let O_LON: Int = 46
let O_SHIFT: Int = 47
let O_TZ: Int = 48
let N_MAX: Int = 49

# tcsvarinfo array
var trnsys_weatherreader_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_FILENAME, "file_name", "TRNSYS hourly output with weather data on local computer", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_YEAR, "i_year", "Year column from TRNSYS input file", "yr", "Time", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_MONTH, "i_month", "Month column from TRNSYS input file", "mn", "Time", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_DAY, "i_day", "Day column from TRNSYS input file", "dy", "Time", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_HOUR, "i_hour", "Hour column from TRNSYS input file", "hr", "Time", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_MINUTE, "i_minute", "Minute column from TRNSYS input file", "mi", "Time", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_GLOBAL, "i_global", "Global horizontal irradiance column from TRNSYS input file", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_BEAM, "i_beam", "Beam normal irradiance column from TRNSYS input file", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_DIFFUSE, "i_diff", "Diffuse horizontal irradiance column from TRNSYS input file", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_TDRY, "i_tdry", "Dry bulb temperature column from TRNSYS input file", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_TWET, "i_twet", "Wet bulb temperature column from TRNSYS input file", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_TDEW, "i_tdew", "Dew point temperature column from TRNSYS input file", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_WSPD, "i_wspd", "Wind speed column from TRNSYS input file", "m/s", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_WDIR, "i_wdir", "Wind direction column from TRNSYS input file", "deg", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_RHUM, "i_rhum", "Relative humidity column from TRNSYS input file", "%", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_PRES, "i_pres", "Pressure column from TRNSYS input file", "mbar", "Meteo", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_SNOW, "i_snow", "Snow cover column from TRNSYS input file", "cm", "Meteo", "valid (0,150)", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_ALBEDO, "i_albedo", "Ground albedo column from TRNSYS input file", "0..1", "Meteo", "valid (0,1)", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_POA, "i_poa", "Plane-of-array total incident irradiance column from TRNSYS input file", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_SOLAZI, "i_solazi", "Solar Azimuth column from TRNSYS input file", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_SOLZEN, "i_solzen", "Solar Zenith column from TRNSYS input file", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_LAT, "i_lat", "Latitude column from TRNSYS input file", "DDD", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_LON, "i_lon", "Longitude column from TRNSYS input file", "DDD", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_STRING, I_TZ, "i_tz", "Timezone column from TRNSYS input file", "DDD", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SHIFT, "i_shift", "shift in longitude from local standard meridian from TRNSYS input file", "deg", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_YEAR, "year", "Year", "yr", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_MONTH, "month", "Month", "mn", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DAY, "day", "Day", "dy", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_HOUR, "hour", "Hour", "hr", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_MINUTE, "minute", "Minute", "mi", "Time", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_GLOBAL, "global", "Global horizontal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_BEAM, "beam", "Beam normal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_DIFFUSE, "diff", "Diffuse horizontal irradiance", "W/m2", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TDRY, "tdry", "Dry bulb temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TWET, "twet", "Wet bulb temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TDEW, "tdew", "Dew point temperature", "'C", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_WSPD, "wspd", "Wind speed", "m/s", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_WDIR, "wdir", "Wind direction", "deg", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_RHUM, "rhum", "Relative humidity", "%", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_PRES, "pres", "Pressure", "mbar", "Meteo", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SNOW, "snow", "Snow cover", "cm", "Meteo", "valid (0,150)", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ALBEDO, "albedo", "Ground albedo", "0..1", "Meteo", "valid (0,1)", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_POA, "poa", "Plane-of-array total incident irradiance", "W/m2", "Irrad", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLAZI, "solazi", "Solar Azimuth", "deg", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SOLZEN, "solzen", "Solar Zenith", "deg", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_LAT, "lat", "Latitude", "DDD", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_LON, "lon", "Longitude", "DDD", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SHIFT, "shift", "shift in longitude from local standard meridian", "deg", "Solar", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TZ, "tz", "Timezone", "DDD", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, "", "", "", "", "", "")
)

struct trnsys_weatherreader(tcstypeinterface):
    var m_trnsys_file: File
    var m_trnsys_values: List[String]
    var m_ndx_year: Int
    var m_ndx_month: Int
    var m_ndx_day: Int
    var m_ndx_hour: Int
    var m_ndx_minute: Int
    var m_ndx_global: Int
    var m_ndx_beam: Int
    var m_ndx_diff: Int
    var m_ndx_tdry: Int
    var m_ndx_twet: Int
    var m_ndx_tdew: Int
    var m_ndx_wspd: Int
    var m_ndx_wdir: Int
    var m_ndx_rhum: Int
    var m_ndx_pres: Int
    var m_ndx_snow: Int
    var m_ndx_albedo: Int
    var m_ndx_poa: Int
    var m_ndx_solazi: Int
    var m_ndx_solzen: Int
    var m_ndx_lat: Int
    var m_ndx_lon: Int
    var m_ndx_tz: Int
    var m_ndx_shift: Int

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        super().__init__(cxt, ti)
        # initialize member variables
        self.m_trnsys_file = File()
        self.m_trnsys_values = List[String]()
        self.m_ndx_year = -1
        self.m_ndx_month = -1
        self.m_ndx_day = -1
        self.m_ndx_hour = -1
        self.m_ndx_minute = -1
        self.m_ndx_global = -1
        self.m_ndx_beam = -1
        self.m_ndx_diff = -1
        self.m_ndx_tdry = -1
        self.m_ndx_twet = -1
        self.m_ndx_tdew = -1
        self.m_ndx_wspd = -1
        self.m_ndx_wdir = -1
        self.m_ndx_rhum = -1
        self.m_ndx_pres = -1
        self.m_ndx_snow = -1
        self.m_ndx_albedo = -1
        self.m_ndx_poa = -1
        self.m_ndx_solazi = -1
        self.m_ndx_solzen = -1
        self.m_ndx_lat = -1
        self.m_ndx_lon = -1
        self.m_ndx_tz = -1
        self.m_ndx_shift = -1

    def __del__(owned self):
        # destructor - empty

    def init(inout self) -> Int:
        var trnsys_columns: List[String] = List[String]()
        var file: String = self.value_str(I_FILENAME)
        self.m_trnsys_file.open(file, "r")
        var file_line: String
        if self.m_trnsys_file.read_line(file_line):
            var ss: String = file_line
            var col_name: String
            # split by tab
            var parts: List[String] = ss.split("\t")
            for col_name in parts:
                # remove whitespace
                col_name = self.remove_whitespace(col_name)
                trnsys_columns.append(col_name)
        # read second line (skip)
        self.m_trnsys_file.read_line(file_line)
        # find indices
        var it: Int
        it = trnsys_columns.find(self.value_str(I_YEAR))
        if it != -1:
            self.m_ndx_year = it
        else:
            self.m_ndx_year = -1
        it = trnsys_columns.find(self.value_str(I_MONTH))
        if it != -1:
            self.m_ndx_month = it
        else:
            self.m_ndx_month = -1
        it = trnsys_columns.find(self.value_str(I_DAY))
        if it != -1:
            self.m_ndx_day = it
        else:
            self.m_ndx_day = -1
        it = trnsys_columns.find(self.value_str(I_HOUR))
        if it != -1:
            self.m_ndx_hour = it
        else:
            self.m_ndx_hour = -1
        it = trnsys_columns.find(self.value_str(I_MINUTE))
        if it != -1:
            self.m_ndx_minute = it
        else:
            self.m_ndx_minute = -1
        it = trnsys_columns.find(self.value_str(I_GLOBAL))
        if it != -1:
            self.m_ndx_global = it
        else:
            self.m_ndx_global = -1
        it = trnsys_columns.find(self.value_str(I_BEAM))
        if it != -1:
            self.m_ndx_beam = it
        else:
            self.m_ndx_beam = -1
        it = trnsys_columns.find(self.value_str(I_DIFFUSE))
        if it != -1:
            self.m_ndx_diff = it
        else:
            self.m_ndx_diff = -1
        it = trnsys_columns.find(self.value_str(I_TDRY))
        if it != -1:
            self.m_ndx_tdry = it
        else:
            self.m_ndx_tdry = -1
        it = trnsys_columns.find(self.value_str(I_TWET))
        if it != -1:
            self.m_ndx_twet = it
        else:
            self.m_ndx_twet = -1
        it = trnsys_columns.find(self.value_str(I_TDEW))
        if it != -1:
            self.m_ndx_tdew = it
        else:
            self.m_ndx_tdew = -1
        it = trnsys_columns.find(self.value_str(I_WSPD))
        if it != -1:
            self.m_ndx_wspd = it
        else:
            self.m_ndx_wspd = -1
        it = trnsys_columns.find(self.value_str(I_WDIR))
        if it != -1:
            self.m_ndx_wdir = it
        else:
            self.m_ndx_wdir = -1
        it = trnsys_columns.find(self.value_str(I_RHUM))
        if it != -1:
            self.m_ndx_rhum = it
        else:
            self.m_ndx_rhum = -1
        it = trnsys_columns.find(self.value_str(I_PRES))
        if it != -1:
            self.m_ndx_pres = it
        else:
            self.m_ndx_pres = -1
        it = trnsys_columns.find(self.value_str(I_SNOW))
        if it != -1:
            self.m_ndx_snow = it
        else:
            self.m_ndx_snow = -1
        it = trnsys_columns.find(self.value_str(I_ALBEDO))
        if it != -1:
            self.m_ndx_albedo = it
        else:
            self.m_ndx_albedo = -1
        it = trnsys_columns.find(self.value_str(I_POA))
        if it != -1:
            self.m_ndx_poa = it
        else:
            self.m_ndx_poa = -1
        it = trnsys_columns.find(self.value_str(I_SOLAZI))
        if it != -1:
            self.m_ndx_solazi = it
        else:
            self.m_ndx_solazi = -1
        it = trnsys_columns.find(self.value_str(I_SOLZEN))
        if it != -1:
            self.m_ndx_solzen = it
        else:
            self.m_ndx_solzen = -1
        it = trnsys_columns.find(self.value_str(I_LAT))
        if it != -1:
            self.m_ndx_lat = it
        else:
            self.m_ndx_lat = -1
        it = trnsys_columns.find(self.value_str(I_LON))
        if it != -1:
            self.m_ndx_lon = it
        else:
            self.m_ndx_lon = -1
        it = trnsys_columns.find(self.value_str(I_TZ))
        if it != -1:
            self.m_ndx_tz = it
        else:
            self.m_ndx_tz = -1
        it = trnsys_columns.find(self.value_str(I_SHIFT))
        if it != -1:
            self.m_ndx_shift = it
        else:
            self.m_ndx_shift = -1
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        if ncall == 0:
            self.m_trnsys_values.clear()
            var file_line: String
            if self.m_trnsys_file.read_line(file_line):
                var ss: String = file_line
                var col_value: String
                var parts: List[String] = ss.split("\t")
                for col_value in parts:
                    col_value = self.remove_whitespace(col_value)
                    self.m_trnsys_values.append(col_value)
            else:
                self.message(TCS_ERROR, "failed to read from weather file %s at time %lg", self.value_str(I_FILENAME), time)
                return -1
        if self.m_ndx_year > -1:
            self.value(O_YEAR, atof(self.m_trnsys_values[self.m_ndx_year]))
        else:
            self.value(O_YEAR, 0.0)
        if self.m_ndx_month > -1:
            self.value(O_MONTH, atof(self.m_trnsys_values[self.m_ndx_month]))
        else:
            self.value(O_MONTH, 0.0)
        if self.m_ndx_day > -1:
            self.value(O_DAY, atof(self.m_trnsys_values[self.m_ndx_day]))
        else:
            self.value(O_DAY, 0.0)
        if self.m_ndx_hour > -1:
            self.value(O_HOUR, atof(self.m_trnsys_values[self.m_ndx_hour]))
        else:
            self.value(O_HOUR, 0.0)
        if self.m_ndx_minute > -1:
            self.value(O_MINUTE, atof(self.m_trnsys_values[self.m_ndx_minute]))
        else:
            self.value(O_MINUTE, 0.0)
        if self.m_ndx_global > -1:
            self.value(O_GLOBAL, atof(self.m_trnsys_values[self.m_ndx_global]) / 3.6)
        else:
            self.value(O_GLOBAL, 0.0)
        if self.m_ndx_beam > -1:
            self.value(O_BEAM, atof(self.m_trnsys_values[self.m_ndx_beam]) / 3.6)
        else:
            self.value(O_BEAM, 0.0)
        if self.m_ndx_diff > -1:
            self.value(O_DIFFUSE, atof(self.m_trnsys_values[self.m_ndx_diff]) / 3.6)
        else:
            self.value(O_DIFFUSE, 0.0)
        if self.m_ndx_tdry > -1:
            self.value(O_TDRY, atof(self.m_trnsys_values[self.m_ndx_tdry]))
        else:
            self.value(O_TDRY, 0.0)
        if self.m_ndx_twet > -1:
            self.value(O_TWET, atof(self.m_trnsys_values[self.m_ndx_twet]))
        else:
            self.value(O_TWET, 0.0)
        if self.m_ndx_tdew > -1:
            self.value(O_TDEW, atof(self.m_trnsys_values[self.m_ndx_tdew]))
        else:
            self.value(O_TDEW, 0.0)
        if self.m_ndx_wspd > -1:
            self.value(O_WSPD, atof(self.m_trnsys_values[self.m_ndx_wspd]))
        else:
            self.value(O_WSPD, 0.0)
        if self.m_ndx_wdir > -1:
            self.value(O_WDIR, atof(self.m_trnsys_values[self.m_ndx_wdir]))
        else:
            self.value(O_WDIR, 0.0)
        if self.m_ndx_rhum > -1:
            self.value(O_RHUM, atof(self.m_trnsys_values[self.m_ndx_rhum]))
        else:
            self.value(O_RHUM, 0.0)
        if self.m_ndx_pres > -1:
            self.value(O_PRES, atof(self.m_trnsys_values[self.m_ndx_pres]) * 1013.25)
        else:
            self.value(O_PRES, 0.0)
        if self.m_ndx_snow > -1:
            self.value(O_SNOW, atof(self.m_trnsys_values[self.m_ndx_snow]))
        else:
            self.value(O_SNOW, 0.0)
        if self.m_ndx_albedo > -1:
            self.value(O_ALBEDO, atof(self.m_trnsys_values[self.m_ndx_albedo]))
        else:
            self.value(O_ALBEDO, 0.0)
        if self.m_ndx_poa > -1:
            self.value(O_POA, atof(self.m_trnsys_values[self.m_ndx_poa]) / 3.6)
        else:
            self.value(O_POA, 0.0)
        if self.m_ndx_solazi > -1:
            self.value(O_SOLAZI, atof(self.m_trnsys_values[self.m_ndx_solazi]) + 180)
        else:
            self.value(O_SOLAZI, 0.0)
        if self.m_ndx_solzen > -1:
            self.value(O_SOLZEN, atof(self.m_trnsys_values[self.m_ndx_solzen]))
        else:
            self.value(O_SOLZEN, 0.0)
        if self.m_ndx_lat > -1:
            self.value(O_LAT, atof(self.m_trnsys_values[self.m_ndx_lat]))
        else:
            self.value(O_LAT, 0.0)
        if self.m_ndx_lon > -1:
            self.value(O_LON, atof(self.m_trnsys_values[self.m_ndx_lon]))
        else:
            self.value(O_LON, 0.0)
        if self.m_ndx_tz > -1:
            self.value(O_TZ, atof(self.m_trnsys_values[self.m_ndx_tz]))
        else:
            self.value(O_TZ, 0.0)
        if self.m_ndx_shift > -1:
            self.value(O_SHIFT, atof(self.m_trnsys_values[self.m_ndx_shift]))
        else:
            self.value(O_SHIFT, 0.0)
        return 0

    # helper function to remove whitespace (equivalent to remove_if with ::isspace)
    def remove_whitespace(inout self, s: String) -> String:
        var result: String = ""
        for c in s:
            if not c.is_space():
                result += c
        return result

# TCS_IMPLEMENT_TYPE macro call
TCS_IMPLEMENT_TYPE(trnsys_weatherreader, "TRNSYS Weather File reader", "Steven Janzou", 1, trnsys_weatherreader_variables, NULL, 0)