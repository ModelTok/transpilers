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

from core import compute_module, var_info, ssc_number_t, SSC_INPUT, SSC_NUMBER, SSC_INOUT, SSC_OUTPUT, SSC_MATRIX, var_info_invalid, exec_error, log, allocate, is_assigned, as_boolean, as_double, as_integer, assign
from common import util, matrix_t
from csp_common import C_sco2_phx_air_cooler, C_csp_exception, sco2_design_cmod_common, vtab_sco2_design

# Placeholder for matrix_t; assuming it is defined in common but we can define locally if not available
# We'll use a simple struct to mimic matrix_t<double> with nrows(), ncols() and operator()
struct matrix_t:
    var data: DynamicVector[DynamicVector[Float64]]

    def __init__(self):
        self.data = DynamicVector[DynamicVector[Float64]]()

    def nrows(self) -> Int:
        return len(self.data)

    def ncols(self) -> Int:
        if len(self.data) == 0:
            return 0
        return len(self.data[0])

    def __call__(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]

    def set(self, i: Int, j: Int, val: Float64):
        self.data[i][j] = val

    def append_row(self, row: DynamicVector[Float64]):
        self.data.append(row)

static var _cm_vtab_sco2_csp_ud_pc_tables: List[var_info] = [
    # VARTYPE   DATATYPE         NAME               LABEL                                                    UNITS     META  GROUP REQUIRED_IF CONSTRAINTS     UI_HINTS
    var_info(SSC_INPUT,  SSC_NUMBER,  "is_generate_udpc",     "1 = generate udpc tables, 0 = only calculate design point cycle", "",   "",    "",      "?=1",   "",       ""),
    var_info(SSC_INPUT,  SSC_NUMBER,  "is_apply_default_htf_mins", "1 = yes (0.5 rc, 0.7 simple), 0 = no, only use 'm_dot_htf_ND_low'", "", "", "",   "?=1",   "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "T_htf_hot_low",        "Lower level of HTF hot temperature",					  "C",         "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "T_htf_hot_high",	   "Upper level of HTF hot temperature",					  "C",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "n_T_htf_hot",		   "Number of HTF hot temperature parametric runs",			  "",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "T_amb_low",			   "Lower level of ambient temperature",					  "C",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "T_amb_high",		   "Upper level of ambient temperature",					  "C",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "n_T_amb",			   "Number of ambient temperature parametric runs",			  "",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "m_dot_htf_ND_low",	   "Lower level of normalized HTF mass flow rate",			  "",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "m_dot_htf_ND_high",	   "Upper level of normalized HTF mass flow rate",			  "",		   "",    "",      "",     "",       ""),
    var_info(SSC_INOUT,  SSC_NUMBER,  "n_m_dot_htf_ND",	   "Number of normalized HTF mass flow rate parametric runs", "",		   "",    "",      "",     "",       ""),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "T_htf_ind",            "Parametric of HTF temperature w/ ND HTF mass flow rate levels",     "",       "",    "",      "?=[[0,1,2,3,4,5,6,7,8,9,10,11,12][0,1,2,3,4,5,6,7,8,9,10,11,12]]",     "",       ""),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "T_amb_ind",            "Parametric of ambient temp w/ HTF temp levels",                     "",       "",    "",      "?=[[0,1,2,3,4,5,6,7,8,9,10,11,12][0,1,2,3,4,5,6,7,8,9,10,11,12]]",     "",       ""),
    var_info(SSC_OUTPUT, SSC_MATRIX,  "m_dot_htf_ND_ind",     "Parametric of ND HTF mass flow rate w/ ambient temp levels",        "",       "",    "",      "?=[[0,1,2,3,4,5,6,7,8,9,10,11,12][0,1,2,3,4,5,6,7,8,9,10,11,12]]",     "",       ""),
    var_info_invalid
]

def test_mono_function(x: Float64, y: Pointer[Float64]) -> Int:
    # TODO: implement body from original C++ if needed
    return 0

struct cm_sco2_csp_ud_pc_tables(compute_module):
    def __init__(self):
        self.add_var_info(vtab_sco2_design)
        self.add_var_info(_cm_vtab_sco2_csp_ud_pc_tables)

    def exec(self) raises:
        var c_sco2_cycle = C_sco2_phx_air_cooler()
        var sco2_des_err = sco2_design_cmod_common(self, c_sco2_cycle)
        if sco2_des_err != 0:
            return
        var sco2_f_min = 0.5
        var m_dot_htf_ND_low = sco2_f_min
        if self.is_assigned("m_dot_htf_ND_low"):
            if self.as_boolean("is_apply_default_htf_mins"):
                m_dot_htf_ND_low = max(sco2_f_min, self.as_double("m_dot_htf_ND_low"))   # [-]
            else:
                m_dot_htf_ND_low = self.as_double("m_dot_htf_ND_low")
        self.assign("m_dot_htf_ND_low", m_dot_htf_ND_low)
        if self.as_integer("is_generate_udpc") == 0:
            self.log("\n Design calculations complete; no off-design cases requested")
            return
        var T_htf_hot_low = c_sco2_cycle.get_design_par().m_T_htf_hot_in - 273.15 - 30.0   # [C]
        if self.is_assigned("T_htf_hot_low"):
            T_htf_hot_low = self.as_double("T_htf_hot_low")   # [C]
        self.assign("T_htf_hot_low", T_htf_hot_low)
        var T_htf_hot_high = c_sco2_cycle.get_design_par().m_T_htf_hot_in - 273.15 + 15.0   # [C]
        if self.is_assigned("T_htf_hot_high"):
            T_htf_hot_high = self.as_double("T_htf_hot_high")   # [C]
        self.assign("T_htf_hot_high", T_htf_hot_high)
        var n_T_htf_hot_in = 4
        if self.is_assigned("n_T_htf_hot"):
            n_T_htf_hot_in = self.as_integer("n_T_htf_hot")   # [-]
        self.assign("n_T_htf_hot", n_T_htf_hot_in)
        var T_amb_low = 0.0
        if self.is_assigned("T_amb_low"):
            T_amb_low = self.as_double("T_amb_low")   # [C]
        self.assign("T_amb_low", T_amb_low)
        var T_amb_high = max(45.0, c_sco2_cycle.get_design_par().m_T_amb_des - 273.15 + 5.0)
        if self.is_assigned("T_amb_high"):
            T_amb_high = self.as_double("T_amb_high")   # [C]
        self.assign("T_amb_high", T_amb_high)
        var n_T_amb_in = round((T_amb_high - T_amb_low) / 2.0) + 1   # [-]
        if self.is_assigned("n_T_amb"):
            n_T_amb_in = self.as_integer("n_T_amb")   # [-]
        self.assign("n_T_amb", n_T_amb_in)
        var m_dot_htf_ND_high = 1.05
        if self.is_assigned("m_dot_htf_ND_high"):
            m_dot_htf_ND_high = self.as_double("m_dot_htf_ND_high")
        self.assign("m_dot_htf_ND_high", m_dot_htf_ND_high)
        var n_m_dot_htf_ND_in = 10
        if self.is_assigned("n_m_dot_htf_ND"):
            n_m_dot_htf_ND_in = self.as_integer("n_m_dot_htf_ND")
        self.assign("n_m_dot_htf_ND", n_m_dot_htf_ND_in)
        if n_T_htf_hot_in < 3 or n_T_amb_in < 3 or n_m_dot_htf_ND_in < 3:
            raise exec_error("sco2_csp_ud_pc_tables", "Need at 3 three points for each independent variable")
        var T_htf_parametrics: matrix_t
        var T_amb_parametrics: matrix_t
        var m_dot_htf_ND_parametrics: matrix_t
        var out_type: Int = -1
        var out_msg: String = ""
        var od_opt_tol: Float64 = 1.E-3
        var od_tol: Float64 = 1.E-3
        try:
            c_sco2_cycle.generate_ud_pc_tables(T_htf_hot_low, T_htf_hot_high, n_T_htf_hot_in,
                            T_amb_low, T_amb_high, n_T_amb_in,
                            m_dot_htf_ND_low, m_dot_htf_ND_high, n_m_dot_htf_ND_in,
                            T_htf_parametrics, T_amb_parametrics, m_dot_htf_ND_parametrics,
                            od_opt_tol, od_tol)
        except C_csp_exception as csp_exception:
            while c_sco2_cycle.mc_messages.get_message(&out_type, &out_msg):
                self.log(out_msg)
            raise exec_error("sco2_csp_system", csp_exception.m_error_message)
        var n_T_htf_hot = T_htf_parametrics.nrows()
        var n_T_amb = T_amb_parametrics.nrows()
        var n_m_dot_htf_ND = m_dot_htf_ND_parametrics.nrows()
        var ncols = T_htf_parametrics.ncols()
        var p_T_htf_ind = self.allocate("T_htf_ind", n_T_htf_hot, ncols)
        for i in range(n_T_htf_hot):
            for j in range(ncols):
                p_T_htf_ind[i * ncols + j] = ssc_number_t(T_htf_parametrics(i, j))
        var p_T_amb_ind = self.allocate("T_amb_ind", n_T_amb, ncols)
        for i in range(n_T_amb):
            for j in range(ncols):
                p_T_amb_ind[i * ncols + j] = ssc_number_t(T_amb_parametrics(i, j))
        var p_m_dot_htf_ND_ind = self.allocate("m_dot_htf_ND_ind", n_m_dot_htf_ND, ncols)
        for i in range(n_m_dot_htf_ND):
            for j in range(ncols):
                p_m_dot_htf_ND_ind[i * ncols + j] = ssc_number_t(m_dot_htf_ND_parametrics(i, j))
        while c_sco2_cycle.mc_messages.get_message(&out_type, &out_msg):
            self.log(out_msg)
        self.log("\n UDPC tables complete")

# DEFINE_MODULE_ENTRY(sco2_csp_ud_pc_tables, "...", 0)