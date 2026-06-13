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
from sscapi import *
from vartab import *
from core import *
from json import JSON
from memory import memset
from os import popen, pclose
from threading import Thread
from time import sleep
from sys import get_system

# ifdef _MSC_VER
# define popen _popen
# define pclose _pclose
# endif

@value
struct var_info:
    var vartype: Int
    var datatype: Int
    var name: String
    var label: String
    var units: String
    var meta: String
    var group: String
    var required_if: String
    var constraints: String
    var ui_hints: String

    @staticmethod
    def invalid() -> var_info:
        return var_info { vartype: 0, datatype: 0, name: "", label: "", units: "", meta: "", group: "", required_if: "", constraints: "", ui_hints: "" }

var _cm_vtab_wind_landbosse: List[var_info] = List[var_info](
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "en_landbosse", label: "Enable landbosse (1 for enabled)", units: "", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_STRING, name: "wind_resource_filename", label: "Local hourly wind data file path", units: "", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "distance_to_interconnect_mi", label: "Distance to Interconnect", units: "miles", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "interconnect_voltage_kV", label: "Interconnect Voltage", units: "kV", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "depth", label: "Foundation Depth", units: "m", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "rated_thrust_N", label: "Rated Thrust", units: "N", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "labor_cost_multiplier", label: "Labor Cost Multiplier", units: "", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "gust_velocity_m_per_s", label: "50 year Gust Velocity", units: "m/s", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "wind_resource_shear", label: "Wind Shear Exponent", units: "", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "num_turbines", label: "Number of Turbines", units: "", meta: "", group: "LandBOSSE", required_if: "*", constraints: "INTEGER,", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "turbine_spacing_rotor_diameters", label: "Turbine Spacing", units: "diameters", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "row_spacing_rotor_diameters", label: "Row Spacing", units: "diameters", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "turbine_rating_MW", label: "Turbine Rating", units: "kW", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "wind_turbine_hub_ht", label: "Hub Height", units: "m", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_INPUT, datatype: SSC_NUMBER, name: "wind_turbine_rotor_diameter", label: "Rotor Diameter", units: "m", meta: "", group: "LandBOSSE", required_if: "*", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_STRING, name: "errors", label: "BOS - Error message", units: "", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "bonding_usd", label: "BOS - Management - Bonding Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "collection_equipment_rental_usd", label: "BOS - Collection - Equipment Rental Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "collection_labor_usd", label: "BOS - Collection - Labor Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "collection_material_usd", label: "BOS - Collection - Materials Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "collection_mobilization_usd", label: "BOS - Collection - Mobilization Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "construction_permitting_usd", label: "BOS - Management - Construction Permitting Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "development_labor_usd", label: "BOS - Development - Labor Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "development_material_usd", label: "BOS - Development - Material Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "development_mobilization_usd", label: "BOS - Development - Mobilization Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "engineering_usd", label: "BOS - Management - Engineering Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_equipment_rental_usd", label: "BOS - Erection - Equipment Rental Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_fuel_usd", label: "BOS - Erection - Fuel Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_labor_usd", label: "BOS - Erection - Labor Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_material_usd", label: "BOS - Erection - Material Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_mobilization_usd", label: "BOS - Erection - Mobilization Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "erection_other_usd", label: "BOS - Erection - Other Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "foundation_equipment_rental_usd", label: "BOS - Foundation - Equipment Rental Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "foundation_labor_usd", label: "BOS - Foundation - Labor Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "foundation_material_usd", label: "BOS - Foundation - Material Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "foundation_mobilization_usd", label: "BOS - Foundation - Mobilization Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "insurance_usd", label: "BOS - Management - Insurance Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "markup_contingency_usd", label: "BOS - Management - Markup Contingency", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "project_management_usd", label: "BOS - Management - Project Management Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "site_facility_usd", label: "BOS - Management - Site Facility Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "sitepreparation_equipment_rental_usd", label: "BOS - Site Preparation - Equipment Rental Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "sitepreparation_labor_usd", label: "BOS - Site Preparation - Labor Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "sitepreparation_material_usd", label: "BOS - Site Preparation - Material Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "sitepreparation_mobilization_usd", label: "BOS - Site Preparation - Mobilization Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_collection_cost", label: "BOS - Total Collection Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_development_cost", label: "BOS - Total Development Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_erection_cost", label: "BOS - Total Erection Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_foundation_cost", label: "BOS - Total Foundation Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_gridconnection_cost", label: "BOS - Total Grid Connection Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_management_cost", label: "BOS - Total Management Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_sitepreparation_cost", label: "BOS - Total Site Preparation Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_substation_cost", label: "BOS - Total Substation Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info { vartype: SSC_OUTPUT, datatype: SSC_NUMBER, name: "total_bos_cost", label: "BOS - Total BOS Cost", units: "$", meta: "", group: "LandBOSSE", required_if: "en_landbosse=1", constraints: "", ui_hints: "" },
    var_info.invalid()
)

@value
class cm_wind_landbosse(compute_module):
    var python_module_name: String
    var python_exec_path: String
    var python_run_cmd: String

    def __init__(inout self):
        self.add_var_info(_cm_vtab_wind_landbosse)

    def load_config(inout self):
        var python_config_path: String = get_python_path()
        if python_config_path == "":
            raise exec_error("wind_landbosse", "Path to SAM python configuration directory not set. "
                                               "Use 'set_python_path' function in sscapi.h to point to the correct folder.")
        var python_config_root: JSON = JSON()
        var python_config_doc: String = load_file(python_config_path + "/python_config.json")
        if python_config_doc == "":
            raise exec_error("wind_landbosse", "Could not open 'python_config.json'. "
                                               "Use 'set_python_path' function in sscapi.h to point to the folder containing the file.")
        # ifdef __WINDOWS__
        # char a,b,c;
        # a = (char)python_config_doc.get();
        # b = (char)python_config_doc.get();
        # c = (char)python_config_doc.get();
        # if (a != (char)0xEF || b != (char)0xBB || c != (char)0xBF) {
        #     python_config_doc.seekg(0);
        # }
        # endif
        python_config_root = JSON.parse(python_config_doc)
        if not python_config_root.has("exec_path"):
            raise exec_error("wind_landbosse", "Missing key 'exec_path' in 'python_config.json'.")
        if not python_config_root.has("python_version"):
            raise exec_error("wind_landbosse", "Missing key 'python_version' in 'python_config.json'.")
        self.python_exec_path = python_config_root["exec_path"].as_string()
        var python_version: String = python_config_root["python_version"].as_string()
        var landbosse_config_root: JSON = JSON()
        var landbosse_config_doc: String = load_file(python_config_path + "/landbosse.json")
        if landbosse_config_doc == "":
            raise exec_error("wind_landbosse", "Could not open 'landbosse.json'. "
                                               "Use 'set_python_path' function in sscapi.h to point to the folder containing the file.")
        landbosse_config_root = JSON.parse(landbosse_config_doc)
        if not landbosse_config_root.has("run_cmd"):
            raise exec_error("wind_landbosse", "Missing key 'run_cmd' in 'landbosse.json'.")
        if not landbosse_config_root.has("min_python_version"):
            raise exec_error("wind_landbosse", "Missing key 'min_python_version' in 'landbosse.json'.")
        self.python_run_cmd = landbosse_config_root["run_cmd"].as_string()
        var min_python_version: String = landbosse_config_root["min_python_version"].as_string()
        var min_ver: List[String] = min_python_version.split(".")
        var py_ver: List[String] = python_version.split(".")
        var i: Int = 0
        while i < len(min_ver):
            if i >= len(py_ver):
                return
            if int(min_ver[i]) > int(py_ver[i]):
                raise exec_error("wind_landbosse", "'min_python_version' requirement not met.")
            i += 1

    const BUFSIZE: Int = 4096

    def call_python_module(inout self, input_dict_as_text: String) -> String:
        var python_result: Promise[String] = Promise[String]()
        var f_completes: Future[String] = python_result.get_future()
        var t: Thread = Thread(lambda: self._call_python_thread(python_result, input_dict_as_text))
        t.detach()
        var time_passed: Int = now() + 60 * 5 * 1000000  # microseconds
        if f_completes.wait_until(time_passed) == FutureStatus.ready:
            return f_completes.get()
        else:
            raise exec_error("wind_landbosse", "python handler error. Python process timed out.")

    def _call_python_thread(inout self, python_result: Promise[String], input_dict_as_text: String):
        var cmd: String = get_python_path() + "/" + self.python_exec_path + " -c \"" + self.python_run_cmd + "\""
        var pos: Int = cmd.find("<input>")
        cmd = cmd.replace(pos, 7, input_dict_as_text)
        var file_pipe: FILE* = popen(cmd, "r")
        if file_pipe == None:
            python_result.set_value("wind_landbosse error. Could not call python with cmd:\n" + cmd)
            return
        var mod_response: String = ""
        var buffer: String = String(BUFSIZE)
        while fgets(buffer, BUFSIZE, file_pipe):
            mod_response += buffer
        pclose(file_pipe)
        if mod_response == "":
            python_result.set_value("LandBOSSE error. Function did not return a response.")
        else:
            python_result.set_value(mod_response)

    # ifdef __WINDOWS__
    # def call_python_module_windows(inout self, input_dict_as_text: String) -> String:
    #     STARTUPINFO si;
    #     SECURITY_ATTRIBUTES sa;
    #     PROCESS_INFORMATION pi;
    #     HANDLE stdin_rd = NULL;
    #     HANDLE stdout_wr = NULL;
    #     HANDLE stdout_rd = NULL;
    #     HANDLE stdin_wr = NULL;
    #     HANDLE stderr_rd = NULL;
    #     HANDLE stderr_wr = NULL;  //pipe handles
    #     char buf[BUFSIZE];           //i/o buffer
    #     memset(buf, 0, sizeof(buf));
    #     string pythonpath = string(get_python_path()) + "\\" + python_exec_path;
    #     CA2T programpath( pythonpath.c_str());
    #     string pythonarg = " -c \"" + python_run_cmd + "\"";
    #     size_t pos = pythonarg.find("<input>");
    #     pythonarg.replace(pos, 7, input_dict_as_text);
    #     CA2T programargs(pythonarg.c_str());
    #     sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    #     sa.bInheritHandle = TRUE;
    #     sa.lpSecurityDescriptor = NULL;
    #     if (!CreatePipe(&stdin_rd, &stdin_wr, &sa, 0)) {
    #         goto done;
    #     }
    #     if (!SetHandleInformation(stdin_wr, HANDLE_FLAG_INHERIT, 0)) {
    #         goto done;
    #     }
    #     if (!CreatePipe(&stdout_rd, &stdout_wr, &sa, 0)) {
    #         goto done;
    #     }
    #     if (!SetHandleInformation(stdout_rd, HANDLE_FLAG_INHERIT, 0)) {
    #         goto done;
    #     }
    #     if (!CreatePipe(&stderr_rd, &stderr_wr, &sa, 0)) {
    #         goto done;
    #     }
    #     if (!SetHandleInformation(stderr_rd, HANDLE_FLAG_INHERIT, 0)) {
    #         goto done;
    #     }
    #     /*The dwFlags member tells CreateProcess how to make the process.
    #     STARTF_USESTDHANDLES: validates the hStd* members.
    #     STARTF_USESHOWWINDOW: validates the wShowWindow member*/
    #     GetStartupInfo(&si);
    #     si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    #     si.wShowWindow = SW_HIDE;
    #     si.hStdOutput = stdout_wr;
    #     si.hStdError = stderr_wr;
    #     si.hStdInput = stdin_rd;
    #     if (CreateProcess(programpath, programargs, NULL, NULL, TRUE, CREATE_NO_WINDOW,
    #         NULL, NULL, &si, &pi)) {
    #         unsigned long bread;   //bytes read
    #         unsigned long bread_last = 0;
    #         unsigned long avail;   //bytes available
    #         for (;;) {
    #             PeekNamedPipe(stdout_rd, buf, BUFSIZE - 1, &bread, &avail, NULL);
    #             if (bread != 0) {
    #                 if (ReadFile(stdout_rd, buf, BUFSIZE - 1, &bread, NULL)) {
    #                     bread_last = bread;
    #                 }
    #             }
    #             else if (bread_last > 0)
    #             {
    #                 break;
    #             }
    #         }
    #         CloseHandle(pi.hThread);
    #         CloseHandle(pi.hProcess);
    #     }
    #     done:
    #     vector<HANDLE> handles = {stdin_rd, stdin_wr, stdout_rd, stdout_wr, stderr_rd, stderr_wr};
    #     for (HANDLE handle : handles) {
    #         if (handle && handle != INVALID_HANDLE_VALUE) {
    #             CloseHandle(handle);
    #         }
    #     }
    #     if (buf[0] == '\0')
    #         throw exec_error("wind_landbosse", "LandBOSSE error. Function did not return a response.");
    #     return buf;
    # }
    # endif

    def cleanOutputString(inout self, inout output_json: String):
        var pos: Int = output_json.find("{")
        if pos != -1:
            output_json = output_json.substr(pos)
        output_json = output_json.replace("'", "\"")

    def exec(inout self):
        if not m_vartab.lookup("en_landbosse").num[0]:
            return
        var input_data: var_table = var_table()
        input_data.assign_match_case("weather_file_path", m_vartab.lookup("wind_resource_filename"))
        input_data.assign_match_case("distance_to_interconnect_mi", m_vartab.lookup("distance_to_interconnect_mi"))
        input_data.assign_match_case("interconnect_voltage_kV", m_vartab.lookup("interconnect_voltage_kv"))
        input_data.assign_match_case("depth", m_vartab.lookup("depth"))
        input_data.assign_match_case("rated_thrust_N", m_vartab.lookup("rated_thrust_n"))
        input_data.assign_match_case("labor_cost_multiplier", m_vartab.lookup("labor_cost_multiplier"))
        input_data.assign_match_case("gust_velocity_m_per_s", m_vartab.lookup("gust_velocity_m_per_s"))
        input_data.assign_match_case("wind_shear_exponent", m_vartab.lookup("wind_resource_shear"))
        input_data.assign_match_case("num_turbines", m_vartab.lookup("num_turbines"))
        input_data.assign_match_case("turbine_spacing_rotor_diameters", m_vartab.lookup("turbine_spacing_rotor_diameters"))
        input_data.assign_match_case("row_spacing_rotor_diameters", m_vartab.lookup("row_spacing_rotor_diameters"))
        input_data.assign_match_case("turbine_rating_MW", m_vartab.lookup("turbine_rating_mw"))
        input_data.assign_match_case("hub_height_meters", m_vartab.lookup("wind_turbine_hub_ht"))
        input_data.assign_match_case("rotor_diameter_m", m_vartab.lookup("wind_turbine_rotor_diameter"))
        var input_json: String = ssc_data_to_json(&input_data)
        var input_dict_as_text: String = input_json
        input_dict_as_text = input_dict_as_text.replace("\"", "'")
        self.load_config()
        # ifdef __WINDOWS__
        # var output_json: String = call_python_module_windows(input_dict_as_text)
        # else
        var output_json: String = self.call_python_module(input_dict_as_text)
        # endif
        self.cleanOutputString(output_json)
        var output_data: var_table* = json_to_ssc_data(output_json)
        if output_data.is_assigned("error"):
            m_vartab.assign("errors", output_json)
            return
        m_vartab.merge(output_data, False)
        var error_vd: var_data* = m_vartab.lookup("errors")
        if error_vd and error_vd.type == SSC_ARRAY:
            m_vartab.assign("errors", str(0))
        if error_vd and error_vd.type == SSC_DATARR:
            m_vartab.assign("errors", error_vd.vec[0].str)

DEFINE_MODULE_ENTRY(wind_landbosse, "Land-based Balance-of-System Systems Engineering (LandBOSSE) cost model", 1)