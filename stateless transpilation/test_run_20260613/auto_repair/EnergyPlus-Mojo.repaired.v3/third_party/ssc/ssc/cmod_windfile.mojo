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
from lib_windfile import *

var _cm_wind_file_reader = List[var_info](
    var_info(SSC_INPUT, SSC_STRING, "file_name", "local weather file path", "", "", "Weather Reader", "*", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "scan_header_only", "only reader headers", "0/1", "", "Weather Reader", "?=0", "BOOLEAN", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "requested_ht", "requested measurement height", "m", "", "Weather Reader", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "interpolate", "interpolate to closest height measured?", "m", "", "Weather Reader", "scan_header_only=0", "BOOLEAN", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "city", "City", "", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "state", "State", "", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "location_id", "Location ID", "", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "country", "Country", "", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_STRING, "description", "Description", "", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "year", "Calendar year of data", "", "", "Weather Reader", "*", "INTEGER", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "lat", "Latitude", "deg", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "lon", "Longitude", "deg", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "elev", "Elevation", "m", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "closest_speed_meas_ht", "Height of closest speed meas in file", "m", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "closest_dir_meas_ht", "Height of closest direction meas in file", "m", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wind_speed", "Wind Speed", "m/s", "", "Weather Reader", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wind_direction", "Wind Direction", "deg", "0=N,E=90", "Weather Reader", "*", "LENGTH_EQUAL=wind_speed", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "temperature", "Temperature", "'C", "", "Weather Reader", "*", "LENGTH_EQUAL=wind_speed", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "pressure", "Atmospheric Pressure", "atm", "", "Weather Reader", "*", "LENGTH_EQUAL=wind_speed", ""),
    var_info_invalid
)

struct cm_wind_file_reader : compute_module:
    def __init__(inout self):
        self.add_var_info(_cm_wind_file_reader)

    def exec(inout self):
        var file = self.as_string("file_name")
        var wf = windfile(file)
        if not wf.ok():
            raise exec_error("windfile", "failed to read local weather file: " + String(file) + " " + wf.error())
        self.assign("city", var_data(String(wf.city)))
        self.assign("state", var_data(String(wf.state)))
        self.assign("location_id", var_data(String(wf.locid)))
        self.assign("country", var_data(String(wf.country)))
        self.assign("description", var_data(String(wf.desc)))
        self.assign("year", var_data(Float64(wf.year)))
        self.assign("lat", var_data(Float64(wf.lat)))
        self.assign("lon", var_data(Float64(wf.lon)))
        self.assign("elev", var_data(Float64(wf.elev)))
        var bHeaderOnly = self.as_boolean("scan_header_only")
        var wind: Float64 = 0
        var dir: Float64 = 0
        var temp: Float64 = 0
        var pres: Float64 = 0
        var closest_speed_meas_ht: Float64 = 0
        var closest_dir_meas_ht: Float64 = 0
        if bHeaderOnly:
            if not wf.read(self.as_double("requested_ht"), &wind, &dir, &temp, &pres, &closest_speed_meas_ht, &closest_dir_meas_ht):
                raise exec_error("windpower", util.format("error reading wind resource file at %d: ", 1) + wf.error())
            self.assign("closest_speed_meas_ht", var_data(Float64(closest_speed_meas_ht)))
            self.assign("closest_dir_meas_ht", var_data(Float64(closest_dir_meas_ht)))
            self.allocate("wind_speed", 1)
            self.allocate("wind_direction", 1)
            self.allocate("temperature", 1)
            self.allocate("pressure", 1)
            return
        var nsteps = 8760
        var p_speed = self.allocate("wind_speed", nsteps)
        var p_dir = self.allocate("wind_direction", nsteps)
        var p_temp = self.allocate("temperature", nsteps)
        var p_pres = self.allocate("pressure", nsteps)
        for i in range(nsteps):
            if not wf.read(self.as_double("requested_ht"), &wind, &dir, &temp, &pres, &closest_speed_meas_ht, &closest_dir_meas_ht, self.as_boolean("interpolate")):
                raise exec_error("windpower", util.format("error reading wind resource file at %d: ", i) + wf.error())
            p_speed[i] = Float64(wind)
            p_dir[i] = Float64(dir)
            p_temp[i] = Float64(temp)
            p_pres[i] = Float64(pres)
        self.assign("closest_speed_meas_ht", var_data(Float64(closest_speed_meas_ht)))
        self.assign("closest_dir_meas_ht", var_data(Float64(closest_dir_meas_ht)))
        return

# DEFINE_MODULE_ENTRY(wind_file_reader, "SAM Wind Resource File Reader (SRW)", 1)
def wind_file_reader() -> compute_module:
    return cm_wind_file_reader()