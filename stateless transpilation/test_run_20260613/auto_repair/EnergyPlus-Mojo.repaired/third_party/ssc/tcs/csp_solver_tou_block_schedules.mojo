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

from csp_solver_core import C_csp_exception, C_csp_tou, S_csp_tou_outputs
from csp_solver_util import matrix_t, format
# from sam_csp_util import ... (not used directly)

@value
class C_block_schedule:
    var mstatic_n_rows: Int
    var mstatic_n_cols: Int
    var m_hr_tou: Pointer[Float64]  # [8760];
    var m_error_msg: String

    var mc_weekdays: matrix_t[Float64]
    var mc_weekends: matrix_t[Float64]
    var mvv_tou_arrays: List[List[Float64]]
    var mv_labels: List[String]

    def __init__(inout self):
        self.mstatic_n_rows = 12
        self.mstatic_n_cols = 24
        self.m_hr_tou = Pointer[Float64]()  # null pointer
        # initialize member variables
        self.mc_weekdays = matrix_t[Float64]()
        self.mc_weekends = matrix_t[Float64]()
        self.mvv_tou_arrays = List[List[Float64]]()
        self.mv_labels = List[String]()
        self.m_error_msg = String()

    def __del__(owned self):
        if self.m_hr_tou:
            self.m_hr_tou.free()
            self.m_hr_tou = Pointer[Float64]()

    def size_vv(inout self, n_arrays: Int):
        self.mvv_tou_arrays.reserve(n_arrays)
        for i in range(n_arrays):
            self.mvv_tou_arrays.append(List[Float64](0, Float64.NaN))

    def check_dimensions(inout self):
        if self.mc_weekdays.nrows() != self.mc_weekends.nrows() \
                or self.mc_weekdays.nrows() != 12 \
                or self.mc_weekdays.ncols() != self.mc_weekends.ncols() \
                or self.mc_weekdays.ncols() != 24:
            self.m_error_msg = "TOU schedules must have 12 rows and 24 columns"
            raise C_csp_exception(self.m_error_msg, "TOU block schedule init")
        return

    def check_arrays_for_tous(inout self, n_arrays: Int):
        var i_tou_min: Int = 1
        var i_tou_max: Int = 1
        var i_tou_day: Int = -1
        var i_tou_end: Int = -1
        var i_temp_max: Int = -1
        var i_temp_min: Int = -1
        for i in range(12):
            for j in range(24):
                i_tou_day = Int(self.mc_weekdays(i, j)) - 1
                i_tou_end = Int(self.mc_weekends(i, j)) - 1
                i_temp_max = max(i_tou_day, i_tou_end)
                i_temp_min = min(i_tou_day, i_tou_end)
                if i_temp_max > i_tou_max:
                    i_tou_max = i_temp_max
                if i_temp_min < i_tou_min:
                    i_tou_min = i_temp_min
        if i_tou_min < 0:
            raise C_csp_exception("Smallest TOU period cannot be less than 1", "TOU block schedule initialization")
        for k in range(n_arrays):
            if i_tou_max + 1 > self.mvv_tou_arrays[k].size:
                self.m_error_msg = format("TOU schedule contains TOU period = %d, while the %s array contains %d elements", i_temp_max, self.mv_labels[k], self.mvv_tou_arrays[k].size)
                raise C_csp_exception(self.m_error_msg, "TOU block schedule initialization")

    def set_hr_tou(inout self, is_leapyear: Bool = False):
        """ 
        This method sets the TOU schedule month by hour for an entire year, so only makes sense in the context of an annual simulation.
        """
        if self.m_hr_tou:
            self.m_hr_tou.free()
        var nhrann: Int = 8760 + (24 if is_leapyear else 0)
        self.m_hr_tou = Pointer[Float64].alloc(nhrann)
        var nday: List[Int] = List[Int](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        if is_leapyear:
            nday[1] += 1
        var wday: Int = 5
        var i: Int = 0
        for m in range(12):
            for d in range(nday[m]):
                var bWeekend: Bool = (wday <= 0)
                if wday >= 0:
                    wday -= 1
                else:
                    wday = 5
                for h in range(24):
                    if i >= nhrann or m * 24 + h >= 288:
                        break
                    if bWeekend:
                        self.m_hr_tou[i] = self.mc_weekends(m, h)
                    else:
                        self.m_hr_tou[i] = self.mc_weekdays(m, h)
                    i += 1

    def init(inout self, n_arrays: Int, is_leapyear: Bool = False):
        self.check_dimensions()
        self.check_arrays_for_tous(n_arrays)
        self.set_hr_tou(is_leapyear)

@value
class C_block_schedule_csp_ops(C_block_schedule):
    enum:
        TURB_FRAC = 0
        N_END = 1

    def __init__(inout self):
        super().__init__()
        self.size_vv(N_END)
        self.mv_labels.reserve(N_END)
        self.mv_labels.append("Turbine Fraction")

    def __del__(owned self):
        # base destructor handles m_hr_tou

@value
class C_block_schedule_pricing(C_block_schedule):
    var mv_is_diurnal: Bool

    enum:
        MULT_PRICE = 0
        N_END = 1

    def __init__(inout self):
        super().__init__()
        self.size_vv(N_END)
        self.mv_labels.reserve(N_END)
        self.mv_labels.append("Price Multiplier")
        self.mv_is_diurnal = True

    def __del__(owned self):

@value
struct S_params:
    var mc_csp_ops: C_block_schedule_csp_ops
    var mc_pricing: C_block_schedule_pricing

    def __init__(inout self):
        self.mc_csp_ops = C_block_schedule_csp_ops()
        self.mc_pricing = C_block_schedule_pricing()

@value
class C_csp_tou_block_schedules(C_csp_tou):
    var mc_csp_messages: C_csp_messages  # assuming imported
    var m_error_msg: String
    var ms_params: S_params

    def __init__(inout self):
        self.mc_csp_messages = C_csp_messages()
        self.m_error_msg = String()
        self.ms_params = S_params()

    def __del__(owned self):

    def init(inout self):
        try:
            self.ms_params.mc_csp_ops.init(C_block_schedule_csp_ops.N_END, self.mc_dispatch_params.m_isleapyear)
        except C_csp_exception as csp_exception:
            self.m_error_msg = "The CSP ops " + csp_exception.m_error_message
            raise C_csp_exception(self.m_error_msg, "TOU block schedule initialization")

        if self.ms_params.mc_pricing.mv_is_diurnal:
            try:
                self.ms_params.mc_pricing.init(C_block_schedule_pricing.N_END, self.mc_dispatch_params.m_isleapyear)
            except C_csp_exception as csp_exception:
                self.m_error_msg = "The CSP pricing " + csp_exception.m_error_message
                raise C_csp_exception(self.m_error_msg, "TOU block schedule initialization")
        return

    def call(inout self, time_s: Float64, inout tou_outputs: S_csp_tou_outputs):
        var i_hour: Int = Int(Math.ceil(time_s / 3600.0 - 1.e-6) - 1)
        if i_hour > 8760 - 1 + (24 if self.mc_dispatch_params.m_isleapyear else 0) or i_hour < 0:
            self.m_error_msg = format("The hour input to the TOU schedule must be from 1 to 8760. The input hour was %d.", i_hour + 1)
            raise C_csp_exception(self.m_error_msg, "TOU timestep call")
        var csp_op_tou: Int = Int(self.ms_params.mc_csp_ops.m_hr_tou[i_hour])
        tou_outputs.m_csp_op_tou = csp_op_tou
        tou_outputs.m_f_turbine = self.ms_params.mc_csp_ops.mvv_tou_arrays[C_block_schedule_csp_ops.TURB_FRAC][csp_op_tou - 1]
        if self.ms_params.mc_pricing.mv_is_diurnal:
            var pricing_tou: Int = Int(self.ms_params.mc_pricing.m_hr_tou[i_hour])
            tou_outputs.m_pricing_tou = pricing_tou
            tou_outputs.m_price_mult = self.ms_params.mc_pricing.mvv_tou_arrays[C_block_schedule_pricing.MULT_PRICE][pricing_tou - 1]
        else:
            var nrecs: Int = self.ms_params.mc_pricing.mvv_tou_arrays[C_block_schedule_pricing.MULT_PRICE].size
            if nrecs <= 0:
                self.m_error_msg = format("The timestep price multiplier array was empty.")
                raise C_csp_exception(self.m_error_msg, "TOU timestep call")
            var nrecs_per_hour: Int = nrecs / 8760
            var ndx: Int = Int((Math.ceil(time_s / 3600.0 - 1.e-6) - 1) * nrecs_per_hour)
            if ndx > nrecs - 1 + (24 if self.mc_dispatch_params.m_isleapyear else 0) or ndx < 0:
                self.m_error_msg = format("The index input to the TOU schedule must be from 1 to %d. The input timestep index was %d.", nrecs, ndx + 1)
                raise C_csp_exception(self.m_error_msg, "TOU timestep call")
            tou_outputs.m_price_mult = self.ms_params.mc_pricing.mvv_tou_arrays[C_block_schedule_pricing.MULT_PRICE][ndx]

    def setup_block_uniform_tod(inout self):
        var nrows: Int = self.ms_params.mc_csp_ops.mstatic_n_rows
        var ncols: Int = self.ms_params.mc_csp_ops.mstatic_n_cols
        for i in range(self.ms_params.mc_csp_ops.N_END):
            self.ms_params.mc_csp_ops.mvv_tou_arrays[i].resize(2, 1.0)
        for i in range(self.ms_params.mc_pricing.N_END):
            self.ms_params.mc_pricing.mvv_tou_arrays[i].resize(2, 1.0)
        self.ms_params.mc_csp_ops.mc_weekdays.resize_fill(nrows, ncols, 1.0)
        self.ms_params.mc_csp_ops.mc_weekends.resize_fill(nrows, ncols, 1.0)
        self.ms_params.mc_pricing.mc_weekdays.resize_fill(nrows, ncols, 1.0)
        self.ms_params.mc_pricing.mc_weekends.resize_fill(nrows, ncols, 1.0)