# /**
# BSD-3-Clause
# Copyright 2019 Alliance for Sustainable Energy, LLC
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met :
# 1.	Redistributions of source code must retain the above copyright notice, this list of conditions
# and the following disclaimer.
# 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
# and the following disclaimer in the documentation and/or other materials provided with the distribution.
# 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
# or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
# DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# */

from core import compute_module, as_matrix, assign, split_ind_tbl, C_csp_exception

# Define constants to match the C++ macros
SSC_INPUT = 0
SSC_OUTPUT = 1
SSC_MATRIX = 2
SSC_NUMBER = 3
var_info_invalid = None

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

    def __init__(inout self, vartype: Int, datatype: Int, name: String, label: String, units: String, meta: String, group: String, required_if: String, constraints: String, ui_hints: String):
        self.vartype = vartype
        self.datatype = datatype
        self.name = name
        self.label = label
        self.units = units
        self.meta = meta
        self.group = group
        self.required_if = required_if
        self.constraints = constraints
        self.ui_hints = ui_hints

var _cm_vtab_ui_udpc_checks: StaticArray[var_info, 14] = StaticArray[var_info, 14](
    var_info(SSC_INPUT,   SSC_MATRIX, "ud_ind_od", "Off design user-defined power cycle performance as function of T_htf, m_dot_htf [ND], and T_amb", "", "", "User Defined Power Cycle", "?=[[0]]", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "n_T_htf_pars", "Number of HTF parametrics", "-", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_htf_low", "HTF low temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_htf_des", "HTF design temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_htf_high", "HTF high temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "n_T_amb_pars", "Number of ambient temperature parametrics", "-", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_amb_low", "Low ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_amb_des", "Design ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "T_amb_high", "High ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "n_m_dot_pars", "Number of HTF mass flow parametrics", "-", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "m_dot_low", "Low ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "m_dot_des", "Design ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "m_dot_high", "High ambient temperature", "C", "", "", "*", "", ""),
    var_info(SSC_OUTPUT,  SSC_NUMBER, "", "", "", "", "", "", "", "")  # var_info_invalid placeholder
)

class cm_ui_udpc_checks(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_ui_udpc_checks)

    def exec(inout self) -> None:
        var n_T_htf_pars: Int
        var n_T_amb_pars: Int
        var n_m_dot_pars: Int
        n_T_htf_pars = n_T_amb_pars = n_m_dot_pars = -1
        var m_dot_low: Float64
        var m_dot_des: Float64
        var m_dot_high: Float64
        var T_htf_low: Float64
        var T_htf_des: Float64
        var T_htf_high: Float64
        var T_amb_low: Float64
        var T_amb_des: Float64
        var T_amb_high: Float64
        m_dot_low = m_dot_des = m_dot_high = T_htf_low = T_htf_des = T_htf_high = T_amb_low = T_amb_des = T_amb_high = Float64.NaN

        var cmbd_ind: matrix_t[Float64] = self.as_matrix("ud_ind_od")
        var T_htf_ind: matrix_t[Float64]
        var m_dot_ind: matrix_t[Float64]
        var T_amb_ind: matrix_t[Float64]

        try:
            split_ind_tbl(cmbd_ind, T_htf_ind, m_dot_ind, T_amb_ind,
                n_T_htf_pars, n_T_amb_pars, n_m_dot_pars,
                m_dot_low, m_dot_des, m_dot_high,
                T_htf_low, T_htf_des, T_htf_high,
                T_amb_low, T_amb_des, T_amb_high)
        except C_csp_exception as csp_exception:
            n_T_htf_pars = n_T_amb_pars = n_m_dot_pars = -1
            m_dot_low = m_dot_des = m_dot_high = T_htf_low = T_htf_des = T_htf_high = T_amb_low = T_amb_des = T_amb_high = Float64.NaN

        self.assign("n_T_htf_pars", ssc_number_t(n_T_htf_pars))
        self.assign("T_htf_low", ssc_number_t(T_htf_low))
        self.assign("T_htf_des", ssc_number_t(T_htf_des))
        self.assign("T_htf_high", ssc_number_t(T_htf_high))
        self.assign("n_T_amb_pars", ssc_number_t(n_T_amb_pars))
        self.assign("T_amb_low", ssc_number_t(T_amb_low))
        self.assign("T_amb_des", ssc_number_t(T_amb_des))
        self.assign("T_amb_high", ssc_number_t(T_amb_high))
        self.assign("n_m_dot_pars", ssc_number_t(n_m_dot_pars))
        self.assign("m_dot_low", ssc_number_t(m_dot_low))
        self.assign("m_dot_des", ssc_number_t(m_dot_des))
        self.assign("m_dot_high", ssc_number_t(m_dot_high))
        return

# DEFINE_MODULE_ENTRY equivalent
def DEFINE_MODULE_ENTRY(name: String, desc: String, version: Int):
    # Placeholder: registers the module with the framework

DEFINE_MODULE_ENTRY("ui_udpc_checks", "Calculates the levels and number of paramteric runs for 3 udpc ind variables", 0)