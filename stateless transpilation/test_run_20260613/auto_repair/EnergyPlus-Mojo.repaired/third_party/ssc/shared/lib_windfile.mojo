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
from python import Python
from python import PythonObject
from python import PythonFn
from memory import memset_zero
from math import fabs, isnan
from sys import info as sys_info
from lib_util import util

def trim(inout buf: String):
    if buf.back() == '\n': # strip newline
        buf.pop_back()
    if buf.back() == '\r': # strip carriage return
        buf.pop_back()

def locate2(buf: String, inout vstring: List[String], delim: UInt8) -> Int:
    trim(buf)
    var ss = StringStream(buf)
    var token: String
    vstring.clear()
    while ss.getline(token, delim):
        vstring.push_back(token)
    return len(vstring)

@value
struct winddata_provider:
    enum:
        INVAL = 0
        TEMP = 1  /* degrees Celsius */
        PRES = 2  /* atmospheres */
        SPEED = 3 # m/s
        DIR = 4   /* degrees */

    var city: String
    var state: String
    var locid: String
    var country: String
    var desc: String
    var year: Int
    var lat: Float64
    var lon: Float64
    var elev: Float64
    var measurementHeight: Float64
    var m_dataid: List[Int]
    var m_heights: List[Float64]
    var m_relativeHumidity: List[Float64]
    var m_errorMsg: String

    def __init__(inout self):
        self.year = 1900
        self.lat = 0.0
        self.lon = 0.0
        self.elev = 0.0
        self.measurementHeight = 0.0
        self.m_errorMsg = String("")
        self.m_dataid = List[Int]()
        self.m_heights = List[Float64]()
        self.m_relativeHumidity = List[Float64]()
        self.city = String("")
        self.state = String("")
        self.locid = String("")
        self.country = String("")
        self.desc = String("")

    def __del__(owned self):

    def types(inout self) -> List[Int]:
        return self.m_dataid

    def heights(inout self) -> List[Float64]:
        return self.m_heights

    def relativeHumidity(inout self) -> List[Float64]:
        return self.m_relativeHumidity

    def read(inout self, requested_height: Float64, speed: Pointer[Float64], direction: Pointer[Float64], temperature: Pointer[Float64], pressure: Pointer[Float64], speed_meas_height: Pointer[Float64], dir_meas_height: Pointer[Float64], bInterpolate: Bool = False) -> Bool:
        var values = List[Float64]()
        if not self.read_line(values):
            return False
        if len(values) < len(self.m_heights) or len(values) < len(self.m_dataid):
            return False
        var ncols = len(values)
        speed[] = Float64.NaN
        direction[] = Float64.NaN
        temperature[] = Float64.NaN
        pressure[] = Float64.NaN
        speed_meas_height[] = Float64.NaN
        dir_meas_height[] = Float64.NaN
        var index: Int = -1
        var index2: Int = -1
        if self.find_closest(index, winddata_provider.SPEED, ncols, requested_height):
            if (bInterpolate) and (self.m_heights[index] != requested_height) and self.find_closest(index2, winddata_provider.SPEED, ncols, requested_height, index) and self.can_interpolate(index, index2, ncols, requested_height):
                speed[] = util.interpolate(self.m_heights[index], values[index], self.m_heights[index2], values[index2], requested_height)
                speed_meas_height[] = requested_height
            else:
                speed[] = values[index]
                speed_meas_height[] = self.m_heights[index]
        if self.find_closest(index, winddata_provider.DIR, ncols, requested_height):
            var dir1: Float64 = 0.0
            var dir2: Float64 = 0.0
            var angle: Float64 = 0.0
            var ht1: Float64 = 0.0
            var ht2: Float64 = 0.0
            var interp_direction: Bool = (bInterpolate) and (self.m_heights[index] != requested_height) and self.find_closest(index2, winddata_provider.DIR, ncols, requested_height, index) and self.can_interpolate(index, index2, ncols, requested_height)
            if interp_direction:
                dir1 = values[index]
                dir2 = values[index2]
                if isnan(dir1) or isnan(dir2):
                    return False
                while dir1 < 0:
                    dir1 += 360
                while dir1 >= 360:
                    dir1 -= 360
                while dir2 < 0:
                    dir2 += 360
                while dir2 >= 360:
                    dir2 -= 360
                ht1 = self.m_heights[index]
                ht2 = self.m_heights[index2]
                if dir1 > dir2:
                    var temp: Float64 = dir2
                    dir2 = dir1
                    dir1 = temp
                    temp = ht2
                    ht2 = ht1
                    ht1 = temp
                angle = (dir2 - dir1) if (dir2 - dir1) < 180 else 360.0 - (dir2 - dir1)
                interp_direction = interp_direction and (angle <= 180)
            if interp_direction:
                if dir1 < 90 and dir2 > 270:
                    direction[] = util.interpolate(ht1, dir1 + 90.0, ht2, dir2 - 270.0, requested_height) - 90.0
                    if direction[] < 0:
                        direction[] += 360.0
                else:
                    direction[] = util.interpolate(ht1, dir1, ht2, dir2, requested_height)
                dir_meas_height[] = requested_height
            else:
                direction[] = values[index]
                dir_meas_height[] = self.m_heights[index]
        if self.find_closest(index, winddata_provider.TEMP, ncols, requested_height):
            if (bInterpolate) and (self.m_heights[index] != requested_height) and self.find_closest(index2, winddata_provider.TEMP, ncols, requested_height, index) and self.can_interpolate(index, index2, ncols, requested_height):
                temperature[] = util.interpolate(self.m_heights[index], values[index], self.m_heights[index2], values[index2], requested_height)
            else:
                temperature[] = values[index]
        if self.find_closest(index, winddata_provider.PRES, ncols, requested_height):
            if (bInterpolate) and (self.m_heights[index] != requested_height) and self.find_closest(index2, winddata_provider.PRES, ncols, requested_height, index) and self.can_interpolate(index, index2, ncols, requested_height):
                pressure[] = util.interpolate(self.m_heights[index], values[index], self.m_heights[index2], values[index2], requested_height)
            else:
                pressure[] = values[index]
        var found_all: Bool = (not isnan(speed[])) and (not isnan(direction[])) and (not isnan(temperature[])) and (not isnan(pressure[]))
        if speed[] < 0 or speed[] > 120:
            found_all = False
            self.m_errorMsg = util.format("Error: wind speed of %g m/s found in weather file, this speed is outside the possible range of 0 to 120 m/s", speed[])
        if temperature[] < -200 or temperature[] > 100:
            found_all = False
            self.m_errorMsg = util.format("Error: temperature of %g degrees Celsius found in weather file, this temperature is outside the possible range of -200 to 100 degrees C", pressure[])
        if pressure[] < 0.5 or pressure[] > 1.1:
            found_all = False
            self.m_errorMsg = util.format("Error: atmospheric pressure of %g atm found in weather file, this pressure is outside the possible range of 0.5 to 1.1 atm", pressure[])
        return found_all

    def error(inout self) -> String:
        return self.m_errorMsg

    def find_closest(inout self, inout closest_index: Int, id: Int, ncols: Int, requested_height: Float64, index_to_exclude: Int = -1) -> Bool:
        closest_index = -1
        var height_diff: Float64 = 1e99
        for i in range(len(self.m_dataid)):
            if (self.m_dataid[i] == id) and (i != index_to_exclude):
                if fabs(self.m_heights[i] - requested_height) < height_diff:
                    if index_to_exclude >= 0:
                        if (self.m_heights[i] > requested_height) and (self.m_heights[index_to_exclude] > requested_height):
                            continue
                        if (self.m_heights[i] < requested_height) and (self.m_heights[index_to_exclude] < requested_height):
                            continue
                    closest_index = i
                    height_diff = fabs(self.m_heights[i] - requested_height)
        return (closest_index >= 0) and (closest_index < ncols)

    def can_interpolate(inout self, index1: Int, index2: Int, ncols: Int, requested_height: Float64) -> Bool:
        if index1 < 0 or index2 < 0:
            return False
        if index1 >= ncols or index2 >= ncols:
            return False
        if self.m_heights[index1] < requested_height and requested_height < self.m_heights[index2]:
            return True
        if self.m_heights[index1] > requested_height and requested_height > self.m_heights[index2]:
            return True
        return False

    def read_line(inout self, inout values: List[Float64]) -> Bool:
        ...

    def nrecords(inout self) -> Int:
        ...

@value
struct windfile:
    var m_ifs: PythonObject
    var m_buf: String
    var m_file: String
    var m_nrec: Int
    var city: String
    var state: String
    var locid: String
    var country: String
    var desc: String
    var year: Int
    var lat: Float64
    var lon: Float64
    var elev: Float64
    var measurementHeight: Float64
    var m_dataid: List[Int]
    var m_heights: List[Float64]
    var m_relativeHumidity: List[Float64]
    var m_errorMsg: String

    def __init__(inout self):
        self.m_ifs = Python.evaluate("open('/dev/null', 'r')")
        self.m_buf = String("")
        self.m_file = String("")
        self.m_nrec = 0
        self.city = String("")
        self.state = String("")
        self.locid = String("")
        self.country = String("")
        self.desc = String("")
        self.year = 1900
        self.lat = 0.0
        self.lon = 0.0
        self.elev = 0.0
        self.measurementHeight = 0.0
        self.m_dataid = List[Int]()
        self.m_heights = List[Float64]()
        self.m_relativeHumidity = List[Float64]()
        self.m_errorMsg = String("")
        self.close()

    def __init__(inout self, file: String):
        self.m_ifs = Python.evaluate("open('/dev/null', 'r')")
        self.m_buf = String("")
        self.m_file = String("")
        self.m_nrec = 0
        self.city = String("")
        self.state = String("")
        self.locid = String("")
        self.country = String("")
        self.desc = String("")
        self.year = 1900
        self.lat = 0.0
        self.lon = 0.0
        self.elev = 0.0
        self.measurementHeight = 0.0
        self.m_dataid = List[Int]()
        self.m_heights = List[Float64]()
        self.m_relativeHumidity = List[Float64]()
        self.m_errorMsg = String("")
        self.close()
        self.open(file)

    def __del__(owned self):
        self.m_ifs.close()

    def ok(inout self) -> Bool:
        return self.m_ifs.good()

    def filename(inout self) -> String:
        return self.m_file

    def open(inout self, file: String) -> Bool:
        self.close()
        if len(file) == 0:
            return False
        self.m_ifs = Python.evaluate("open('" + file + "', 'r')")
        if not self.m_ifs.good():
            self.m_errorMsg = "could not open file for reading: " + file
            return False
        self.m_buf = self.m_ifs.readline()
        var cols = List[String]()
        var ncols = locate2(self.m_buf, cols, ord(','))
        if ncols < 8:
            self.m_errorMsg = util.format("error reading header (line 1).  At least 8 columns required, %d found.", ncols)
            self.m_ifs.close()
            return False
        self.locid = cols[0]
        self.city = cols[1]
        self.state = cols[2]
        self.country = cols[3]
        try:
            self.year = int(cols[4])
        except:

        try:
            self.lat = float(cols[5])
        except:

        try:
            self.lon = float(cols[6])
        except:

        try:
            self.elev = float(cols[7])
        except:

        self.m_buf = self.m_ifs.readline()
        self.desc = self.m_buf
        trim(self.desc)
        self.m_buf = self.m_ifs.readline()
        ncols = locate2(self.m_buf, cols, ord(','))
        if ncols < 3:
            self.m_errorMsg = util.format("too few data column types found: %d.  at least 3 required.", ncols)
            self.m_ifs.close()
            return False
        for i in range(ncols):
            var ctype: String = util.lower_case(cols[i])
            if ctype == "temperature" or ctype == "temp":
                self.m_dataid.push_back(winddata_provider.TEMP)
            elif ctype == "pressure" or ctype == "pres":
                self.m_dataid.push_back(winddata_provider.PRES)
            elif ctype == "speed" or ctype == "velocity":
                self.m_dataid.push_back(winddata_provider.SPEED)
            elif ctype == "direction" or ctype == "dir":
                self.m_dataid.push_back(winddata_provider.DIR)
            elif len(ctype) > 0:
                self.m_errorMsg = util.format("error reading data column type specifier in col %d of %d: '%s' len: %d", i+1, ncols, ctype, len(ctype))
                self.m_ifs.close()
                return False
        self.m_heights.resize(len(self.m_dataid), -1.0)
        self.m_buf = self.m_ifs.readline()
        self.m_buf = self.m_ifs.readline()
        ncols = locate2(self.m_buf, cols, ord(','))
        if ncols < len(self.m_heights):
            self.m_errorMsg = util.format("too few columns in the height row.  %d required but only %d found", len(self.m_heights), ncols)
            self.m_ifs.close()
            return False
        for i in range(len(self.m_heights)):
            self.m_heights[i] = float(cols[i])
        self.m_nrec = 0
        while self.m_ifs.readline() != "":
            self.m_nrec += 1
        self.m_ifs.seek(0)
        for i in range(5):
            self.m_ifs.readline()
        self.m_file = file
        return True

    def close(inout self):
        self.m_ifs.close()
        self.m_file = String("")
        self.city = String("")
        self.state = String("")
        self.locid = String("")
        self.country = String("")
        self.desc = String("")
        self.year = 1900
        self.lat = 0.0
        self.lon = 0.0
        self.elev = 0.0
        self.m_nrec = 0

    def nrecords(inout self) -> Int:
        return self.m_nrec

    def read_line(inout self, inout values: List[Float64]) -> Bool:
        if not self.ok():
            return False
        var cols = List[String]()
        self.m_buf = self.m_ifs.readline()
        var ncols = locate2(self.m_buf, cols, ord(','))
        if ncols >= len(self.m_heights) and ncols >= len(self.m_dataid):
            values.resize(len(self.m_heights), 0.0)
            for i in range(len(self.m_heights)):
                values[i] = float(cols[i])
            return True
        else:
            return False