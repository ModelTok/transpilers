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

from math import fmin
from memory import Pointer
from algorithm import max_element
from vector import DynamicVector
from string import String
from exception import Exception

struct C_csp_reported_outputs:
    enum E_subts_weight_type:
        TS_WEIGHTED_AVE = 0
        TS_1ST = 1
        TS_LAST = 2
        TS_MAX = 3

    struct C_output:
        var mp_reporting_ts_array: Pointer[Float64]
        var m_n_reporting_ts_array: Int
        var mv_temp_outputs: DynamicVector[Float64]
        var m_is_allocated: Bool
        var m_subts_weight_type: Int
        var m_counter_reporting_ts_array: Int

        def __init__(inout self):
            self.mp_reporting_ts_array = Pointer[Float64]()
            self.m_is_allocated = False
            self.m_subts_weight_type = -1
            self.m_counter_reporting_ts_array = 0
            self.m_n_reporting_ts_array = -1

        def get_vector_size(self) -> Int:
            return self.mv_temp_outputs.size

        def set_m_is_ts_weighted(inout self, subts_weight_type: Int):
            self.m_subts_weight_type = subts_weight_type
            if not (self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_WEIGHTED_AVE or
                    self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_1ST or
                    self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_LAST or
                    self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_MAX):
                raise C_csp_exception("C_csp_reported_outputs::C_output::send_to_reporting_ts_array did not recognize subtimestep weighting type")

        def assign(inout self, p_reporting_ts_array: Pointer[Float64], n_reporting_ts_array: Int):
            self.mp_reporting_ts_array = p_reporting_ts_array
            self.mv_temp_outputs.reserve(10)
            self.m_is_allocated = True
            self.m_n_reporting_ts_array = n_reporting_ts_array

        def set_timestep_output(inout self, output_value: Float64):
            if self.m_is_allocated:
                self.mv_temp_outputs.push_back(output_value)

        def overwrite_most_recent_timestep(inout self, value: Float64):
            var n_timesteps = self.get_vector_size()
            if n_timesteps == 0:
                return
            self.mv_temp_outputs[n_timesteps - 1] = value

        def overwrite_vector_to_constant(inout self, value: Float64):
            var n_timesteps = self.get_vector_size()
            for i in range(n_timesteps):
                self.mv_temp_outputs[i] = value

        def get_output_vector(self) -> DynamicVector[Float64]:
            return self.mv_temp_outputs

        def send_to_reporting_ts_array(inout self, report_time_start: Float64, n_report: Int,
                v_temp_ts_time_end: DynamicVector[Float64], report_time_end: Float64, is_save_last_step: Bool, n_pop_back: Int):
            if self.m_is_allocated:
                if self.mv_temp_outputs.size != n_report:
                    raise C_csp_exception("Time and data arrays are not the same size", "C_csp_reported_outputs::send_to_reporting_ts_array")
                if self.m_counter_reporting_ts_array + 1 > self.m_n_reporting_ts_array:
                    raise C_csp_exception("Attempting store more points in Reporting Timestep Array than it was allocated for")
                var m_report_step = report_time_end - report_time_start
                if self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_WEIGHTED_AVE:
                    var time_prev = report_time_start
                    for i in range(n_report):
                        self.mp_reporting_ts_array[self.m_counter_reporting_ts_array] += (fmin(v_temp_ts_time_end[i], report_time_end) - time_prev) * self.mv_temp_outputs[i]
                        time_prev = fmin(v_temp_ts_time_end[i], report_time_end)
                    self.mp_reporting_ts_array[self.m_counter_reporting_ts_array] /= m_report_step
                elif self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_1ST:
                    self.mp_reporting_ts_array[self.m_counter_reporting_ts_array] = self.mv_temp_outputs[0]
                elif self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_LAST:
                    self.mp_reporting_ts_array[self.m_counter_reporting_ts_array] = self.mv_temp_outputs[n_report - 1]
                elif self.m_subts_weight_type == C_csp_reported_outputs.E_subts_weight_type.TS_MAX:
                    self.mp_reporting_ts_array[self.m_counter_reporting_ts_array] = max_element(self.mv_temp_outputs)
                else:
                    raise C_csp_exception("C_csp_reported_outputs::C_output::send_to_reporting_ts_array did not recognize subtimestep weighting type")
                if is_save_last_step:
                    self.mv_temp_outputs[0] = self.mv_temp_outputs[n_report - 1]
                for i in range(n_pop_back):
                    self.mv_temp_outputs.pop_back()
                self.m_counter_reporting_ts_array += 1

    struct S_output_info:
        var m_name: Int
        var m_subts_weight_type: Int

    var mvc_outputs: DynamicVector[C_output]
    var m_n_outputs: Int
    var m_n_reporting_ts_array: Int
    var mv_latest_calculated_outputs: DynamicVector[Float64]

    def __init__(inout self):

    def construct(inout self, output_info: Pointer[S_output_info]):
        var n_outputs = 0
        while output_info[n_outputs].m_name != csp_info_invalid.m_name:
            n_outputs += 1
        self.mvc_outputs.resize(n_outputs)
        self.m_n_outputs = n_outputs
        self.mv_latest_calculated_outputs.resize(n_outputs)
        for i in range(n_outputs):
            self.mvc_outputs[i].set_m_is_ts_weighted(output_info[i].m_subts_weight_type)
        self.m_n_reporting_ts_array = -1

    def assign(inout self, index: Int, p_reporting_ts_array: Pointer[Float64], n_reporting_ts_array: Int) -> Bool:
        if index < 0 or index >= self.m_n_outputs:
            return False
        if self.m_n_reporting_ts_array == -1:
            self.m_n_reporting_ts_array = n_reporting_ts_array
        else:
            if self.m_n_reporting_ts_array != n_reporting_ts_array:
                return False
        self.mvc_outputs[index].assign(p_reporting_ts_array, n_reporting_ts_array)
        return True

    def send_to_reporting_ts_array(inout self, report_time_start: Float64,
            v_temp_ts_time_end: DynamicVector[Float64], report_time_end: Float64):
        var n_report = v_temp_ts_time_end.size
        if n_report < 1:
            raise C_csp_exception("No data to report", "C_csp_reported_outputs::send_to_reporting_ts_array")
        var is_save_last_step = True
        var n_pop_back = n_report - 1
        if v_temp_ts_time_end[n_report - 1] == report_time_end:
            is_save_last_step = False
            n_pop_back = n_report
        for i in range(self.m_n_outputs):
            self.mvc_outputs[i].send_to_reporting_ts_array(report_time_start, n_report, v_temp_ts_time_end,
                report_time_end, is_save_last_step, n_pop_back)

    def get_output_vector(self, index: Int) -> DynamicVector[Float64]:
        return self.mvc_outputs[index].get_output_vector()

    def value(inout self, index: Int, value: Float64):
        self.mv_latest_calculated_outputs[index] = value

    def value(self, index: Int) -> Float64:
        return self.mv_latest_calculated_outputs[index]

    def overwrite_most_recent_timestep(inout self, index: Int, value: Float64):
        self.mvc_outputs[index].overwrite_most_recent_timestep(value)

    def overwrite_vector_to_constant(inout self, index: Int, value: Float64):
        self.mvc_outputs[index].overwrite_vector_to_constant(value)

    def size(self, index: Int) -> Int:
        return self.mvc_outputs[index].get_vector_size()

    def set_timestep_outputs(inout self):
        for i in range(self.m_n_outputs):
            self.mvc_outputs[i].set_timestep_output(self.mv_latest_calculated_outputs[i])

var csp_info_invalid = C_csp_reported_outputs.S_output_info{-1, -1}

struct C_csp_messages:
    struct S_message_def:
        var m_type: Int
        var msg: String

        def __init__(inout self):
            self.m_type = -1

        def __init__(inout self, type: Int, msgin: String):
            self.m_type = type
            self.msg = msgin

    var m_message_list: DynamicVector[S_message_def]

    def __init__(inout self):
        self.m_message_list.clear()

    def add_message(inout self, type: Int, msg: String):
        self.m_message_list.insert(0, S_message_def(type, msg))

    def add_notice(inout self, msg: String):
        self.add_message(1, msg)

    def get_message(inout self, type: Pointer[Int], msg: Pointer[String]) -> Bool:
        if self.m_message_list.size == 0:
            return False
        var temp = self.m_message_list.back()
        self.m_message_list.pop_back()
        msg[] = temp.msg
        type[] = temp.m_type
        return True

    def get_message(inout self, msg: Pointer[String]) -> Bool:
        var itemp: Int
        return self.get_message(Pointer[Int].address_of(itemp), msg)

    def transfer_messages(inout self, inout c_csp_messages_downstream: C_csp_messages):
        var out_type = -1
        var out_msg = String("")
        while c_csp_messages_downstream.get_message(Pointer[Int].address_of(out_type), Pointer[String].address_of(out_msg)):
            self.add_message(out_type, out_msg)

struct C_csp_exception(Exception):
    var m_error_message: String
    var m_code_location: String
    var m_error_code: Int

    def __init__(inout self, msg: String):
        self.m_error_message = msg
        self.m_code_location = "unknown"
        self.m_error_code = -1

    def __init__(inout self, error_message: String, code_location: String):
        self.m_error_message = error_message
        self.m_code_location = code_location
        self.m_error_code = -1

    def __init__(inout self, error_message: String, code_location: String, error_code: Int):
        self.m_error_message = error_message
        self.m_code_location = code_location
        self.m_error_code = error_code

    def what(self) -> String:
        return "CSP exception"

def check_double(x: Float64) -> Bool:
    if x != x:
        return False
    return True