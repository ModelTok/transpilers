"""
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
"""
from tcstype import *
from csp_solver_tou_block_schedules import C_csp_tou_block_schedules, C_block_schedule_csp_ops, C_block_schedule_pricing
from csp_solver_util import C_csp_exception, C_csp_messages
from csp_solver_core import C_csp_tou, S_csp_tou_outputs

alias P_WEEKDAY_SCHEDULE = 0
alias P_WEEKEND_SCHEDULE = 1
alias O_TOU_VALUE = 2
alias N_MAX = 3

var tou_translator_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_WEEKDAY_SCHEDULE, "weekday_schedule", "12x24 matrix of values for weekdays", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_WEEKEND_SCHEDULE, "weekend_schedule", "12x24 matrix of values for weekend days", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_TOU_VALUE, "tou_value", "Value during time step", "", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0)
)

@value
struct tou_translator(tcstypeinterface):
    var mc_tou: C_csp_tou_block_schedules
    var ms_outputs: S_csp_tou_outputs

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.mc_tou = C_csp_tou_block_schedules()
        self.ms_outputs = S_csp_tou_outputs()

    def __del__(owned self):

    def init(inout self) -> int:
        var nrows: int = 0
        var ncols: int = 0
        var weekdays: Pointer[float64] = self.value(P_WEEKDAY_SCHEDULE, &nrows, &ncols)
        self.mc_tou.ms_params.mc_csp_ops.mc_weekdays.resize(nrows, ncols)
        for r in range(nrows):
            for c in range(ncols):
                self.mc_tou.ms_params.mc_csp_ops.mc_weekdays[r, c] = TCS_MATRIX_INDEX(self.var(P_WEEKDAY_SCHEDULE), r, c)
        nrows = 0
        ncols = 0
        var weekends: Pointer[float64] = self.value(P_WEEKEND_SCHEDULE, &nrows, &ncols)
        self.mc_tou.ms_params.mc_csp_ops.mc_weekends.resize(nrows, ncols)
        for r in range(nrows):
            for c in range(ncols):
                self.mc_tou.ms_params.mc_csp_ops.mc_weekends[r, c] = TCS_MATRIX_INDEX(self.var(P_WEEKEND_SCHEDULE), r, c)
        self.mc_tou.ms_params.mc_pricing.mc_weekdays = self.mc_tou.ms_params.mc_csp_ops.mc_weekdays
        self.mc_tou.ms_params.mc_pricing.mc_weekends = self.mc_tou.ms_params.mc_csp_ops.mc_weekends
        var turbine_fracs: List[float64] = List[float64]()
        turbine_fracs.resize(9, 0.0)
        self.mc_tou.ms_params.mc_csp_ops.mvv_tou_arrays[C_block_schedule_csp_ops.TURB_FRAC] = turbine_fracs
        self.mc_tou.ms_params.mc_pricing.mvv_tou_arrays[C_block_schedule_pricing.MULT_PRICE] = turbine_fracs
        var out_type: int = -1
        var out_msg: String = ""
        try:
            self.mc_tou.init()
        except C_csp_exception as csp_exception:
            while self.mc_tou.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_tou.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        return 0

    def call(inout self, time: float64, step: float64, ncall: int) -> int:
        var out_type: int = -1
        var out_msg: String = ""
        try:
            self.mc_tou.call(time, self.ms_outputs)
        except C_csp_exception as csp_exception:
            while self.mc_tou.mc_csp_messages.get_message(&out_type, &out_msg):
                if out_type == C_csp_messages.NOTICE:
                    self.message(TCS_NOTICE, out_msg)
                elif out_type == C_csp_messages.WARNING:
                    self.message(TCS_WARNING, out_msg)
            self.message(TCS_ERROR, csp_exception.m_error_message)
            return -1
        while self.mc_tou.mc_csp_messages.get_message(&out_type, &out_msg):
            if out_type == C_csp_messages.NOTICE:
                self.message(TCS_NOTICE, out_msg)
            elif out_type == C_csp_messages.WARNING:
                self.message(TCS_WARNING, out_msg)
        self.value(O_TOU_VALUE, float64(self.ms_outputs.m_csp_op_tou))
        return 0

TCS_IMPLEMENT_TYPE(tou_translator, "Time of Use translator", "Tom Ferguson", 1, tou_translator_variables, None, 0)