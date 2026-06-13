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
from core import (
    compute_module, var_info, var_info_invalid,
    SSC_INPUT, SSC_OUTPUT, SSC_STRING, SSC_NUMBER, SSC_MATRIX,
    exec_error, ssc_number_t
)
from lib_util import split
from lib_weatherfile import *
from os import FileHandle, open as open_file, read_line
from memory import Pointer
from builtin import List, String, Float64, Int

let _cm_wave_file_reader: List[var_info] = List[var_info](
    #   VARTYPE           DATATYPE         NAME                           LABEL                                        UNITS     META                      GROUP                 REQUIRED_IF                CONSTRAINTS        UI_HINTS
    var_info(SSC_INPUT,         SSC_STRING,      "wave_resource_filename",               "local weather file path",                     "",       "",                      "Weather Reader",      "*",                       "LOCAL_FILE",      "" ),
    var_info(SSC_INPUT,         SSC_NUMBER,      "use_specific_wf_wave",               "user specified file",                     "0/1",       "",                      "Weather Reader",      "?=0",                       "INTEGER,MIN=0,MAX=1",      "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "name",                    "Name",                                        "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "city",                    "City",                                        "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "state",                   "State",                                       "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "country",                 "Country",                                     "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_NUMBER,      "lat",                     "Latitude",                                    "deg",    "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_NUMBER,      "lon",                     "Longitude",                                   "deg",    "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "nearby_buoy_number",      "Nearby buoy number",                          "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_NUMBER,      "average_power_flux",      "Distance to shore",                           "kW/m",   "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "bathymetry",              "Bathymetry",                                  "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "sea_bed",                 "Sea bed",                                     "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_NUMBER,      "tz",                      "Time zone",                                   "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "data_source",             "Data source",                                 "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_STRING,      "notes",                   "Notes",                                       "",       "",                      "Weather Reader",      "use_specific_wf_wave=0",                        "",               "" ),
    var_info(SSC_OUTPUT,        SSC_MATRIX,      "wave_resource_matrix",              "Frequency distribution of resource",                                  "m/s",   "",                       "Weather Reader",      "*",                        "",                            "" ),
    var_info_invalid
)

struct cm_wave_file_reader(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_wave_file_reader)

    def exec(inout self) raises:
        var file: String = self.as_string("wave_resource_filename")
        if file == "":
            raise exec_error("wave_file_reader", "File name missing.")
        var buf: String
        var buf1: String
        var ifs: FileHandle = open_file(file, "r")
        if not ifs.is_valid():
            raise exec_error("wave_file_reader", "could not open file for reading: " + file)
        var values: List[String]
        if self.as_integer("use_specific_wf_wave") == 0:
            buf = read_line(ifs)
            buf1 = read_line(ifs)
            var keys: List[String] = split(buf)
            values = split(buf1)
            var ncols: Int = keys.size
            var ncols1: Int = values.size
            if ncols != ncols1 or ncols < 13:
                raise exec_error("wave_file_reader", "incorrect number of header columns: " + String(ncols))
            self.assign("name", var_data(values[0]))
            self.assign("city", var_data(values[1]))
            self.assign("state", var_data(values[2]))
            self.assign("country", var_data(values[3]))
            var dlat: ssc_number_t = Float64.nan
            var slat: List[String] = split(values[4], " ")
            if slat.size > 0:
                dlat = Float64.parse(slat[0])
                if slat.size > 1:
                    if slat[1] == "S":
                        dlat = 0.0 - dlat
            self.assign("lat", var_data(dlat))
            var dlon: ssc_number_t = Float64.nan
            var slon: List[String] = split(values[5], " ")
            if slon.size > 0:
                dlon = Float64.parse(slon[0])
                if slon.size > 1:
                    if slon[1] == "W":
                        dlon = 0.0 - dlon
            self.assign("lon", var_data(dlon))
            self.assign("nearby_buoy_number", var_data(values[6]))
            self.assign("average_power_flux", var_data(Float64.parse(values[7])))
            self.assign("bathymetry", var_data(values[8]))
            self.assign("sea_bed", var_data(values[9]))
            self.assign("tz", var_data(Float64.parse(values[10])))
            self.assign("data_source", var_data(values[11]))
            self.assign("notes", var_data(values[12]))
        var mat: Pointer[ssc_number_t] = self.allocate("wave_resource_matrix", 21, 22)
        for r in range(21):
            buf = read_line(ifs)
            values.clear()
            values = split(buf)
            if values.size != 22:
                raise exec_error("wave_file_reader", "incorrect number of data columns: " + String(values.size))
            for c in range(22):
                if r == 0 and c == 0:
                    mat[r * 22 + c] = 0.0
                else:
                    mat[r * 22 + c] = Float64.parse(values[c])
        return

def DEFINE_MODULE_ENTRY(ClassName: type, desc: String, version: Int) -> None:

DEFINE_MODULE_ENTRY(cm_wave_file_reader, "SAM Wave Resource File Reader", 1)