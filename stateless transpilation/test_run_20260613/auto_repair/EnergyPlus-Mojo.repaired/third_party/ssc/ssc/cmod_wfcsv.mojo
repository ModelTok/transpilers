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

var _cm_vtab_wfcsvconv: List[var_info] = List[var_info](
    var_info(SSC_INPUT, SSC_STRING, "input_file", "Input weather file name", "", "tmy2,tmy3,intl,epw,smw", "Weather File Converter", "*", "", ""),
    var_info(SSC_INOUT, SSC_STRING, "output_file", "Output file name", "", "", "Weather File Converter", "?", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "output_folder", "Output folder", "", "", "Weather File Converter", "?", "", ""),
    var_info(SSC_INPUT, SSC_STRING, "output_filename_format", "Output file name format", "", "recognizes $city $state $country $type $loc", "Weather File Converter", "?", "", ""),
    var_info_invalid
)

struct cm_wfcsvconv:
    var compute_module: compute_module

    def __init__(inout self):
        self.compute_module = compute_module()
        self.compute_module.add_var_info(_cm_vtab_wfcsvconv)

    def exec(inout self):
        var input: String = self.compute_module.as_string("input_file")
        if self.compute_module.is_assigned("output_file"):
            var output: String = self.compute_module.as_string("output_file")
            if not weatherfile.convert_to_wfcsv(input, output):
                raise exec_error("wfcsvconv", "could not convert " + input + " to " + output)
        else:
            var wfile: weatherfile = weatherfile(input, True)
            if not wfile.ok():
                raise exec_error("wfcsvconv", "could not read input file: " + input)
            var hdr: weather_header = weather_header()
            wfile.header(hdr)
            var state: String = hdr.state
            var city: String = weatherfile.normalize_city(hdr.city)
            var country: String = hdr.country
            var loc: String = hdr.location
            var type: String = "?"
            var wtype: Int = wfile.type()
            if wtype == weatherfile.TMY2:
                type = "TMY2"
                if country.empty():
                    country = "None"
            elif wtype == weatherfile.TMY3:
                type = "TMY3"
                if country.empty():
                    country = "None"
            elif wtype == weatherfile.EPW:
                type = "EPW"
            elif wtype == weatherfile.SMW:
                type = "SMW"
            if not country.empty():
                country += " "
            var ofmt: String = "$country $state $city ($type)"
            if self.compute_module.is_assigned("output_file_format"):
                ofmt = self.compute_module.as_string("output_filename_format")
            var folder: String = util.path_only(input)
            if self.compute_module.is_assigned("output_folder"):
                folder = self.compute_module.as_string("output_folder")
            var output: String = folder + "/" + ofmt
            util.replace(output, "$city", city)
            util.replace(output, "$state", state)
            util.replace(output, "$country ", country)
            util.replace(output, "$loc", loc)
            util.replace(output, "$type", type)
            var illegal: List[UInt8] = List[UInt8](63, 42, 35, 36, 37, 123, 125, 60, 62, 33, 59, 64, 124, 96, 43, 0)
            var i: Int = 0
            var buf: String = String(" ")
            buf[1] = 0
            while illegal[i] != 0:
                buf[0] = illegal[i]
                i += 1
                util.replace(output, buf, "")
            if util.ext_only(output) != "csv":
                output += ".csv"
            if not weatherfile.convert_to_wfcsv(input, output):
                raise exec_error("wfcsvconv", "could not convert " + input + " to " + output)
            self.compute_module.assign("output_file", var_data(output))

define_module_entry("wfcsvconv", "Converter for TMY2, TMY3, INTL, EPW, SMW weather files to standard CSV format", 1)