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
from interpolation_routines import Linear_Interp
from csp_solver_util import C_csp_exception, C_csp_messages
from csp_solver_util import util
from sys import Float64

struct C_ud_power_cycle:
    enum E_output_order:
        i_W_dot_gross = 0
        i_Q_dot_HTF = 1
        i_W_dot_cooling = 2
        i_m_dot_water = 3

    var mc_T_htf_ind: Linear_Interp
    var mc_T_amb_ind: Linear_Interp
    var mc_m_dot_htf_ind: Linear_Interp
    var mc_T_htf_on_T_amb: Linear_Interp
    var mc_T_amb_on_m_dot_htf: Linear_Interp
    var mc_m_dot_htf_on_T_htf: Linear_Interp
    var m_error_msg: String
    var m_T_htf_ref: Float64
    var m_T_htf_low: Float64
    var m_T_htf_high: Float64
    var m_m_dot_htf_ref: Float64
    var m_m_dot_htf_low: Float64
    var m_m_dot_htf_high: Float64
    var m_T_amb_ref: Float64
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var m_ME_T_htf_low: List[Float64]
    var m_ME_T_htf_high: List[Float64]
    var m_ME_T_amb_low: List[Float64]
    var m_ME_T_amb_high: List[Float64]
    var m_ME_m_dot_htf_low: List[Float64]
    var m_ME_m_dot_htf_high: List[Float64]

    def __init__(inout self):
        self.mc_T_htf_ind = Linear_Interp()
        self.mc_T_amb_ind = Linear_Interp()
        self.mc_m_dot_htf_ind = Linear_Interp()
        self.mc_T_htf_on_T_amb = Linear_Interp()
        self.mc_T_amb_on_m_dot_htf = Linear_Interp()
        self.mc_m_dot_htf_on_T_htf = Linear_Interp()
        self.m_error_msg = String("")
        self.m_T_htf_ref = 0.0
        self.m_T_htf_low = 0.0
        self.m_T_htf_high = 0.0
        self.m_m_dot_htf_ref = 0.0
        self.m_m_dot_htf_low = 0.0
        self.m_m_dot_htf_high = 0.0
        self.m_T_amb_ref = 0.0
        self.m_T_amb_low = 0.0
        self.m_T_amb_high = 0.0
        self.m_ME_T_htf_low = List[Float64]()
        self.m_ME_T_htf_high = List[Float64]()
        self.m_ME_T_amb_low = List[Float64]()
        self.m_ME_T_amb_high = List[Float64]()
        self.m_ME_m_dot_htf_low = List[Float64]()
        self.m_ME_m_dot_htf_high = List[Float64]()

    def __del__(owned self):

    def init(inout self, T_htf_ind: object, T_htf_ref: Float64, T_htf_low: Float64, T_htf_high: Float64,
        T_amb_ind: object, T_amb_ref: Float64, T_amb_low: Float64, T_amb_high: Float64,
        m_dot_htf_ind: object, m_dot_htf_ref: Float64, m_dot_htf_low: Float64, m_dot_htf_high: Float64) raises:
        var error_index: Int32 = -2
        var column_index_array = List[Int32](0)
        column_index_array.append(0)
        if not self.mc_T_htf_ind.Set_1D_Lookup_Table(T_htf_ind, column_index_array, 1, error_index):
            if error_index == -1:
                raise C_csp_exception("Table representing Hot HTF Temperature parametric results must have"
                    "at least 3 rows", "User defined power cycle initialization")
            else:
                raise C_csp_exception("The Hot HTF Temperature must monotonically increase in the table",
                    "User defined power cycle initialization")
        if not self.mc_T_amb_ind.Set_1D_Lookup_Table(T_amb_ind, column_index_array, 1, error_index):
            if error_index == -1:
                raise C_csp_exception("Table representing Ambient Temperature parametric results must have"
                    "at least 3 rows", "User defined power cycle initialization")
            else:
                raise C_csp_exception("The Ambient Temperature must monotonically increase in the table",
                    "User defined power cycle initialization")
        if not self.mc_m_dot_htf_ind.Set_1D_Lookup_Table(m_dot_htf_ind, column_index_array, 1, error_index):
            if error_index == -1:
                raise C_csp_exception("Table representing HTF mass flow rate parametric results must have"
                    "at least 3 rows", "User defined power cycle initialization")
            else:
                raise C_csp_exception("The HTF mass flow rate must monotonically increase in the table",
                    "User defined power cycle initialization")
        self.m_T_htf_ref = T_htf_ref
        self.m_T_htf_low = T_htf_low
        self.m_T_htf_high = T_htf_high
        self.m_T_amb_ref = T_amb_ref
        self.m_T_amb_low = T_amb_low
        self.m_T_amb_high = T_amb_high
        self.m_m_dot_htf_ref = m_dot_htf_ref
        self.m_m_dot_htf_low = m_dot_htf_low
        self.m_m_dot_htf_high = m_dot_htf_high
        if not self.mc_T_htf_ind.check_x_value_x_col_0(self.m_T_htf_ref):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the hot HTF temperature"
                " must contain the design HTF temperature %lg [C]. %s [C]", self.m_T_htf_ref, self.mc_T_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_T_htf_ind.check_x_value_x_col_0(self.m_T_htf_low):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the hot HTF temperature"
                " must contain the lower level HTF temperature %lg [C]. %s [C]", self.m_T_htf_low, self.mc_T_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_T_htf_ind.check_x_value_x_col_0(self.m_T_htf_high):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the hot HTF temperature"
                " must contain the upper level HTF temperature %lg [C]. %s [C]", self.m_T_htf_high, self.mc_T_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_T_amb_ind.check_x_value_x_col_0(self.m_T_amb_ref):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the ambient temperature"
                " must contain the design ambient temperature %lg [C]. %s [C]", self.m_T_amb_ref, self.mc_T_amb_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_T_amb_ind.check_x_value_x_col_0(self.m_T_amb_low):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the ambient temperature"
                " must contain the lower level ambient temperature %lg [C]. %s [C]", self.m_T_amb_low, self.mc_T_amb_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_T_amb_ind.check_x_value_x_col_0(self.m_T_amb_high):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the ambient temperature"
                " must contain the upper level ambient temperature %lg [C]. %s [C]", self.m_T_amb_high, self.mc_T_amb_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_m_dot_htf_ind.check_x_value_x_col_0(self.m_m_dot_htf_ref):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the normalized HTF mass flow rate"
                " must contain the design normalized HTF mass flow rate %lg [-]. %s [-]", self.m_m_dot_htf_ref, self.mc_m_dot_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_m_dot_htf_ind.check_x_value_x_col_0(self.m_m_dot_htf_low):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the normalized HTF mass flow rate"
                " must contain the lower level normalized HTF mass flow rate %lg [-]. %s [-]", self.m_m_dot_htf_low, self.mc_m_dot_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        if not self.mc_m_dot_htf_ind.check_x_value_x_col_0(self.m_m_dot_htf_high):
            self.m_error_msg = util.format("The user defined power cycle table containing parametric runs on the normalized HTF mass flow rate"
                " must contain the upper level normalized HTF mass flow rate %lg [-]. %s [-]", self.m_m_dot_htf_high, self.mc_m_dot_htf_ind.get_error_msg())
            raise C_csp_exception(self.m_error_msg, "User defined power cycle initialization")
        self.m_ME_T_htf_low = List[Float64]()
        self.m_ME_T_htf_high = List[Float64]()
        self.m_ME_T_amb_low = List[Float64]()
        self.m_ME_T_amb_high = List[Float64]()
        self.m_ME_m_dot_htf_low = List[Float64]()
        self.m_ME_m_dot_htf_high = List[Float64]()
        self.m_ME_T_htf_low.resize(4)
        self.m_ME_T_htf_high.resize(4)
        self.m_ME_T_amb_low.resize(4)
        self.m_ME_T_amb_high.resize(4)
        self.m_ME_m_dot_htf_low.resize(4)
        self.m_ME_m_dot_htf_high.resize(4)
        for i in range(4):
            var i_col: Int32 = (i * 3 + 2) as Int32
            self.m_ME_T_htf_low[i] = self.mc_T_htf_ind.interpolate_x_col_0(i_col, self.m_T_htf_low) - 1.0
            self.m_ME_T_htf_high[i] = self.mc_T_htf_ind.interpolate_x_col_0(i_col, self.m_T_htf_high) - 1.0
            self.m_ME_T_amb_low[i] = self.mc_T_amb_ind.interpolate_x_col_0(i_col, self.m_T_amb_low) - 1.0
            self.m_ME_T_amb_high[i] = self.mc_T_amb_ind.interpolate_x_col_0(i_col, self.m_T_amb_high) - 1.0
            self.m_ME_m_dot_htf_low[i] = self.mc_m_dot_htf_ind.interpolate_x_col_0(i_col, self.m_m_dot_htf_low) - 1.0
            self.m_ME_m_dot_htf_high[i] = self.mc_m_dot_htf_ind.interpolate_x_col_0(i_col, self.m_m_dot_htf_high) - 1.0
        var n_T_htf_runs: Int32 = self.mc_T_htf_ind.get_number_of_rows()
        var n_T_amb_runs: Int32 = self.mc_T_amb_ind.get_number_of_rows()
        var n_m_dot_htf_runs: Int32 = self.mc_m_dot_htf_ind.get_number_of_rows()
        var T_htf_int_on_T_amb = matrix_t[Float64](n_T_amb_runs, 9)
        var T_amb_int_on_m_dot_htf = matrix_t[Float64](n_m_dot_htf_runs, 9)
        var m_dot_htf_int_on_T_htf = matrix_t[Float64](n_T_htf_runs, 9)
        for i in range(4):
            for j in range(n_T_amb_runs):
                if i == 0:
                    T_htf_int_on_T_amb.__setitem__(j, 0, self.mc_T_amb_ind.get_x_value_x_col_0(j))
                var aa: Float64 = self.mc_T_amb_ind.Get_Value((i * 3 + 1) as Int32, j)
                var bb: Float64 = self.m_ME_T_htf_low[i]
                var cc: Float64 = self.mc_T_amb_ind.Get_Value((i * 3 + 2) as Int32, j)
                T_htf_int_on_T_amb.__setitem__(j, (i * 2 + 1) as Int32, -(self.mc_T_amb_ind.Get_Value((i * 3 + 1) as Int32, j) - 1.0 - self.m_ME_T_htf_low[i] - (self.mc_T_amb_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
                aa = self.mc_T_amb_ind.Get_Value((i * 3 + 3) as Int32, j)
                bb = self.m_ME_T_htf_high[i]
                cc = self.mc_T_amb_ind.Get_Value((i * 3 + 2) as Int32, j)
                T_htf_int_on_T_amb.__setitem__(j, (i * 2 + 2) as Int32, -(self.mc_T_amb_ind.Get_Value((i * 3 + 3) as Int32, j) - 1.0 - self.m_ME_T_htf_high[i] - (self.mc_T_amb_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
            for j in range(n_m_dot_htf_runs):
                if i == 0:
                    T_amb_int_on_m_dot_htf.__setitem__(j, 0, self.mc_m_dot_htf_ind.get_x_value_x_col_0(j))
                var aa: Float64 = self.mc_m_dot_htf_ind.Get_Value((i * 3 + 1) as Int32, j)
                var bb: Float64 = self.m_ME_T_amb_low[i]
                var cc: Float64 = self.mc_m_dot_htf_ind.Get_Value((i * 3 + 2) as Int32, j)
                T_amb_int_on_m_dot_htf.__setitem__(j, (i * 2 + 1) as Int32, -(self.mc_m_dot_htf_ind.Get_Value((i * 3 + 1) as Int32, j) - 1.0 - self.m_ME_T_amb_low[i] - (self.mc_m_dot_htf_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
                aa = self.mc_m_dot_htf_ind.Get_Value((i * 3 + 3) as Int32, j)
                bb = self.m_ME_T_amb_high[i]
                cc = self.mc_m_dot_htf_ind.Get_Value((i * 3 + 2) as Int32, j)
                T_amb_int_on_m_dot_htf.__setitem__(j, (i * 2 + 2) as Int32, -(self.mc_m_dot_htf_ind.Get_Value((i * 3 + 3) as Int32, j) - 1.0 - self.m_ME_T_amb_high[i] - (self.mc_m_dot_htf_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
            for j in range(n_T_htf_runs):
                if i == 0:
                    m_dot_htf_int_on_T_htf.__setitem__(j, 0, self.mc_T_htf_ind.get_x_value_x_col_0(j))
                var aa: Float64 = self.mc_T_htf_ind.Get_Value((i * 3 + 1) as Int32, j)
                var bb: Float64 = self.m_ME_m_dot_htf_low[i]
                var cc: Float64 = self.mc_T_htf_ind.Get_Value((i * 3 + 2) as Int32, j)
                m_dot_htf_int_on_T_htf.__setitem__(j, (i * 2 + 1) as Int32, -(self.mc_T_htf_ind.Get_Value((i * 3 + 1) as Int32, j) - 1.0 - self.m_ME_m_dot_htf_low[i] - (self.mc_T_htf_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
                aa = self.mc_T_htf_ind.Get_Value((i * 3 + 3) as Int32, j)
                bb = self.m_ME_m_dot_htf_high[i]
                cc = self.mc_T_htf_ind.Get_Value((i * 3 + 2) as Int32, j)
                m_dot_htf_int_on_T_htf.__setitem__(j, (i * 2 + 2) as Int32, -(self.mc_T_htf_ind.Get_Value((i * 3 + 3) as Int32, j) - 1.0 - self.m_ME_m_dot_htf_high[i] - (self.mc_T_htf_ind.Get_Value((i * 3 + 2) as Int32, j) - 1.0)))
        if not self.mc_T_htf_on_T_amb.Set_1D_Lookup_Table(T_htf_int_on_T_amb, column_index_array, 1, error_index):
            raise C_csp_exception("Initialization of interpolation table for the interaction effect of T_HTF levels"
                "on the ambient temperature failed", "User defined power cycle initialization")
        if not self.mc_T_amb_on_m_dot_htf.Set_1D_Lookup_Table(T_amb_int_on_m_dot_htf, column_index_array, 1, error_index):
            raise C_csp_exception("Initialization of interpolation table for the interaction effect of T_amb levels"
                "on HTF mass flow rate failed", "User defined power cycle initialization")
        if not self.mc_m_dot_htf_on_T_htf.Set_1D_Lookup_Table(m_dot_htf_int_on_T_htf, column_index_array, 1, error_index):
            raise C_csp_exception("Initialization of interpolation table for the interaction effect of m_dot_HTF levels"
                "on the HTF temperature failed", "User defined power cycle initialization")

    def get_W_dot_gross_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) raises -> Float64:
        return self.get_interpolated_ND_output(Self.E_output_order.i_W_dot_gross, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_Q_dot_HTF_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) raises -> Float64:
        return self.get_interpolated_ND_output(Self.E_output_order.i_Q_dot_HTF, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_W_dot_cooling_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) raises -> Float64:
        return self.get_interpolated_ND_output(Self.E_output_order.i_W_dot_cooling, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_m_dot_water_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) raises -> Float64:
        return self.get_interpolated_ND_output(Self.E_output_order.i_m_dot_water, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_interpolated_ND_output(inout self, i_ME: Int32, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) raises -> Float64:
        var ME_T_htf: Float64 = self.mc_T_htf_ind.interpolate_x_col_0((i_ME * 3 + 2) as Int32, T_htf_hot) - 1.0
        var ME_T_amb: Float64 = self.mc_T_amb_ind.interpolate_x_col_0((i_ME * 3 + 2) as Int32, T_amb) - 1.0
        var ME_m_dot_htf: Float64 = self.mc_m_dot_htf_ind.interpolate_x_col_0((i_ME * 3 + 2) as Int32, m_dot_htf_ND) - 1.0
        var INT_T_htf_on_T_amb: Float64 = 0.0
        if T_htf_hot < self.m_T_htf_ref:
            INT_T_htf_on_T_amb = self.mc_T_htf_on_T_amb.interpolate_x_col_0((i_ME * 2 + 1) as Int32, T_amb) * (T_htf_hot - self.m_T_htf_ref) / (self.m_T_htf_ref - self.m_T_htf_low)
        if T_htf_hot > self.m_T_htf_ref:
            INT_T_htf_on_T_amb = self.mc_T_htf_on_T_amb.interpolate_x_col_0((i_ME * 2 + 2) as Int32, T_amb) * (T_htf_hot - self.m_T_htf_ref) / (self.m_T_htf_ref - self.m_T_htf_high)
        var INT_T_amb_on_m_dot_htf: Float64 = 0.0
        if T_amb < self.m_T_amb_ref:
            INT_T_amb_on_m_dot_htf = self.mc_T_amb_on_m_dot_htf.interpolate_x_col_0((i_ME * 2 + 1) as Int32, m_dot_htf_ND) * (T_amb - self.m_T_amb_ref) / (self.m_T_amb_ref - self.m_T_amb_low)
        if T_amb > self.m_T_amb_ref:
            INT_T_amb_on_m_dot_htf = self.mc_T_amb_on_m_dot_htf.interpolate_x_col_0((i_ME * 2 + 2) as Int32, m_dot_htf_ND) * (T_amb - self.m_T_amb_ref) / (self.m_T_amb_ref - self.m_T_amb_high)
        var INT_m_dot_htf_on_T_htf: Float64 = 0.0
        if m_dot_htf_ND < self.m_m_dot_htf_ref:
            INT_m_dot_htf_on_T_htf = self.mc_m_dot_htf_on_T_htf.interpolate_x_col_0((i_ME * 2 + 1) as Int32, T_htf_hot) * (m_dot_htf_ND - self.m_m_dot_htf_ref) / (self.m_m_dot_htf_ref - self.m_m_dot_htf_low)
        if m_dot_htf_ND > self.m_m_dot_htf_ref:
            INT_T_amb_on_m_dot_htf = self.mc_m_dot_htf_on_T_htf.interpolate_x_col_0((i_ME * 2 + 2) as Int32, T_htf_hot) * (m_dot_htf_ND - self.m_m_dot_htf_ref) / (self.m_m_dot_htf_ref - self.m_m_dot_htf_high)
        return 1.0 + ME_T_htf + ME_T_amb + ME_m_dot_htf + INT_T_htf_on_T_amb + INT_T_amb_on_m_dot_htf + INT_m_dot_htf_on_T_htf


trait C_od_pc_function:
    struct S_f_inputs:
        var m_T_htf_hot: Float64
        var m_m_dot_htf_ND: Float64
        var m_T_amb: Float64

        def __init__(inout self):
            self.m_T_htf_hot = Float64.NAN
            self.m_m_dot_htf_ND = Float64.NAN
            self.m_T_amb = Float64.NAN

    struct S_f_outputs:
        var m_W_dot_gross_ND: Float64
        var m_Q_dot_in_ND: Float64
        var m_W_dot_cooling_ND: Float64
        var m_m_dot_water_ND: Float64

        def __init__(inout self):
            self.m_W_dot_gross_ND = Float64.NAN
            self.m_Q_dot_in_ND = Float64.NAN
            self.m_W_dot_cooling_ND = Float64.NAN
            self.m_m_dot_water_ND = Float64.NAN

    def __call__(inout self, inputs: Self.S_f_inputs, outputs: Self.S_f_outputs) raises -> Int32


struct C_ud_pc_table_generator:
    var mf_pc_eq: C_od_pc_function
    var m_log_msg: String
    var m_progress_msg: String
    var mc_messages: C_csp_messages
    var mf_callback: FunctionRef[Bool(String, String, Pointer[NoneType], Float64, Int32)]
    var mp_mf_active: Pointer[NoneType]

    def __init__(inout self, f_pc_eq: C_od_pc_function):
        self.mf_pc_eq = f_pc_eq
        self.mf_callback = None
        self.mp_mf_active = Pointer[NoneType]()
        self.m_progress_msg = "Power cycle preprocessing..."
        self.m_log_msg = "Log message"
        self.mc_messages = C_csp_messages()
        return

    def __del__(owned self):

    def send_callback(inout self, is_od_model_error: Bool, run_number: Int32, n_runs_total: Int32,
        T_htf_hot: Float64, m_dot_htf_ND: Float64, T_amb: Float64,
        W_dot_gross_ND: Float64, Q_dot_in_ND: Float64,
        W_dot_cooling_ND: Float64, m_dot_water_ND: Float64) raises:
        if self.mf_callback and self.mp_mf_active:
            var od_err_msg: String = ""
            if is_od_model_error:
                od_err_msg = "***************\nWarning: off design model failed\n"
                    "Using generic off design for this point\n"
                    "Check if values are appropriate before running annual simulation\n"
                    "***************\n"
            self.m_log_msg = od_err_msg + util.format("[%d/%d] At T_htf = %lg [C],"
                " normalized m_dot = %lg,"
                " and T_amb = %lg [C]. The normalized outputs are: gross power = %lg,"
                " thermal input = %lg, cooling power = %lg, and water use = %lg",
                run_number, n_runs_total,
                T_htf_hot, m_dot_htf_ND, T_amb,
                W_dot_gross_ND, Q_dot_in_ND,
                W_dot_cooling_ND, m_dot_water_ND)
            if not self.mf_callback(self.m_log_msg, self.m_progress_msg, self.mp_mf_active, 100.0 * run_number / n_runs_total, 2):
                var error_msg: String = "User terminated simulation..."
                var loc_msg: String = "C_ud_pc_table_generator"
                raise C_csp_exception(error_msg, loc_msg, 1)

    def generate_tables(inout self, T_htf_ref: Float64, T_htf_low: Float64, T_htf_high: Float64, n_T_htf: Int32,
        T_amb_ref: Float64, T_amb_low: Float64, T_amb_high: Float64, n_T_amb: Int32,
        m_dot_htf_ND_ref: Float64, m_dot_htf_ND_low: Float64, m_dot_htf_ND_high: Float64, n_m_dot_htf_ND: Int32,
        T_htf_ind: object, T_amb_ind: object, m_dot_htf_ind: object) raises -> Int32:
        if T_htf_low >= T_htf_ref:
            var msg: String = util.format("The lower level of HTF temperature %lg [C] must be colder than the design temperature %lg [C].",
                T_htf_low, T_htf_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        if T_htf_high <= T_htf_ref:
            var msg: String = util.format("The upper level of HTF temperature %lg [C] must be hotter than the design temperature %lg [C].",
                T_htf_high, T_htf_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        if T_amb_low >= T_amb_ref:
            var msg: String = util.format("The lower level of ambient temperature %lg [C] must be colder than the design temperatuare %lg [C].",
                T_amb_low, T_amb_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        if T_amb_high <= T_amb_ref:
            var msg: String = util.format("The upper level of ambient temperature %lg [C] must be warmer than the design temperature %lg [C].",
                T_amb_high, T_amb_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        if m_dot_htf_ND_low >= m_dot_htf_ND_ref:
            var msg: String = util.format("The lower level of the normalized HTF mass flow rate %lg must be less than the design value %lg.",
                m_dot_htf_ND_low, m_dot_htf_ND_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        if m_dot_htf_ND_high <= m_dot_htf_ND_ref:
            var msg: String = util.format("The upper level of the normalized HTF mass flow rate %lg must be greater than the design value %lg.",
                m_dot_htf_ND_high, m_dot_htf_ND_ref)
            raise C_csp_exception(msg, "User defined power cycle, generate tables")
        var pc_inputs = C_od_pc_function.S_f_inputs()
        var pc_outputs = C_od_pc_function.S_f_outputs()
        if n_T_htf < 3:
            var msg: String = util.format("The input argument for number of indepedent HTF temperatures is %d."
                " It was reset to the minimum value of 3.", n_T_htf)
            self.mc_messages.add_notice(msg)
            n_T_htf = 3
        T_htf_ind.clear()
        T_htf_ind.resize(n_T_htf, 13)
        var delta_T_htf: Float64 = (T_htf_high - T_htf_low) / (n_T_htf - 1)
        var n_runs_total: Float64 = 3.0 * (n_T_htf + n_T_amb + n_m_dot_htf_ND)
        pc_inputs.m_T_amb = T_amb_ref
        for i in range(n_T_htf):
            T_htf_ind.__setitem__(i, 0, T_htf_low + delta_T_htf * i)
            pc_inputs.m_T_htf_hot = T_htf_ind.__getitem__(i, 0)
            var m_dot_htf_ND_levels = List[Float64](3)
            m_dot_htf_ND_levels[0] = m_dot_htf_ND_low
            m_dot_htf_ND_levels[1] = m_dot_htf_ND_ref
            m_dot_htf_ND_levels[2] = m_dot_htf_ND_high
            for j in range(3):
                var is_od_model_error: Bool = False
                pc_inputs.m_m_dot_htf_ND = m_dot_htf_ND_levels[j]
                var off_design_code: Int32 = self.mf_pc_eq(pc_inputs, pc_outputs)
                if off_design_code == 0:
                    T_htf_ind.__setitem__(i, 1 + j, pc_outputs.m_W_dot_gross_ND)
                    T_htf_ind.__setitem__(i, 4 + j, pc_outputs.m_Q_dot_in_ND)
                    T_htf_ind.__setitem__(i, 7 + j, pc_outputs.m_W_dot_cooling_ND)
                    T_htf_ind.__setitem__(i, 10 + j, pc_outputs.m_m_dot_water_ND)
                elif off_design_code == -1:
                    T_htf_ind.__setitem__(i, 1 + j, pc_inputs.m_m_dot_htf_ND)
                    T_htf_ind.__setitem__(i, 4 + j, pc_inputs.m_m_dot_htf_ND)
                    T_htf_ind.__setitem__(i, 7 + j, pc_inputs.m_m_dot_htf_ND)
                    T_htf_ind.__setitem__(i, 10 + j, pc_inputs.m_m_dot_htf_ND)
                    is_od_model_error = True
                else:
                    var err_msg: String = util.format("The 1st UDPC table (primary: T_htf, interaction: m_dot_htf_ND) generation failed at T_htf = %lg [C] and m_dot_htf = %lg [-]", pc_inputs.m_T_htf_hot, pc_inputs.m_m_dot_htf_ND)
                    raise C_csp_exception(err_msg, "UDPC")
                var run_number: Float64 = i * 3 + j
                self.send_callback(is_od_model_error, (run_number + 1) as Int32, (n_runs_total) as Int32,
                    pc_inputs.m_T_htf_hot, pc_inputs.m_m_dot_htf_ND, pc_inputs.m_T_amb,
                    T_htf_ind.__getitem__(i, 1 + j), T_htf_ind.__getitem__(i, 4 + j),
                    T_htf_ind.__getitem__(i, 7 + j), T_htf_ind.__getitem__(i, 10 + j))
        if n_T_amb < 3:
            var msg: String = util.format("The input argument for number of independent ambient temperatures"
                " is %d. It was reset to the minimum value of 3.", n_T_amb)
            self.mc_messages.add_notice(msg)
            n_T_amb = 3
        T_amb_ind.clear()
        T_amb_ind.resize(n_T_amb, 13)
        var delta_T_amb: Float64 = (T_amb_high - T_amb_low) / (n_T_amb - 1)
        pc_inputs.m_m_dot_htf_ND = m_dot_htf_ND_ref
        for i in range(n_T_amb):
            T_amb_ind.__setitem__(i, 0, T_amb_low + delta_T_amb * i)
            pc_inputs.m_T_amb = T_amb_ind.__getitem__(i, 0)
            var T_htf_levels = List[Float64](3)
            T_htf_levels[0] = T_htf_low
            T_htf_levels[1] = T_htf_ref
            T_htf_levels[2] = T_htf_high
            for j in range(3):
                var is_od_model_error: Bool = False
                pc_inputs.m_T_htf_hot = T_htf_levels[j]
                var off_design_code: Int32 = self.mf_pc_eq(pc_inputs, pc_outputs)
                if off_design_code == 0:
                    T_amb_ind.__setitem__(i, 1 + j, pc_outputs.m_W_dot_gross_ND)
                    T_amb_ind.__setitem__(i, 4 + j, pc_outputs.m_Q_dot_in_ND)
                    T_amb_ind.__setitem__(i, 7 + j, pc_outputs.m_W_dot_cooling_ND)
                    T_amb_ind.__setitem__(i, 10 + j, pc_outputs.m_m_dot_water_ND)
                elif off_design_code == -1:
                    T_amb_ind.__setitem__(i, 1 + j, pc_inputs.m_m_dot_htf_ND)
                    T_amb_ind.__setitem__(i, 4 + j, pc_inputs.m_m_dot_htf_ND)
                    T_amb_ind.__setitem__(i, 7 + j, pc_inputs.m_m_dot_htf_ND)
                    T_amb_ind.__setitem__(i, 10 + j, pc_inputs.m_m_dot_htf_ND)
                    is_od_model_error = True
                else:
                    var err_msg: String = util.format("The 2nd UDPC table (primary: T_amb, interaction: T_htf) generation failed at T_amb = %lg [C] and T_htf = %lg [C]", pc_inputs.m_T_amb, pc_inputs.m_T_htf_hot)
                    raise C_csp_exception(err_msg, "UDPC")
                var run_number: Float64 = 3.0 * n_T_htf + i * 3 + j
                self.send_callback(is_od_model_error, (run_number + 1) as Int32, (n_runs_total) as Int32,
                    pc_inputs.m_T_htf_hot, pc_inputs.m_m_dot_htf_ND, pc_inputs.m_T_amb,
                    T_amb_ind.__getitem__(i, 1 + j), T_amb_ind.__getitem__(i, 4 + j),
                    T_amb_ind.__getitem__(i, 7 + j), T_amb_ind.__getitem__(i, 10 + j))
        if n_m_dot_htf_ND < 3:
            var msg: String = util.format("The input argument for number of independent normalized HTF mass flow rates"
                " is %d. It was reset to the minimum value of 3.", n_m_dot_htf_ND)
            self.mc_messages.add_notice(msg)
            n_m_dot_htf_ND = 3
        m_dot_htf_ind.clear()
        m_dot_htf_ind.resize(n_m_dot_htf_ND, 13)
        var delta_m_dot: Float64 = (m_dot_htf_ND_high - m_dot_htf_ND_low) / (n_m_dot_htf_ND - 1)
        pc_inputs.m_T_htf_hot = T_htf_ref
        for i in range(n_m_dot_htf_ND):
            m_dot_htf_ind.__setitem__(i, 0, m_dot_htf_ND_low + delta_m_dot * i)
            pc_inputs.m_m_dot_htf_ND = m_dot_htf_ind.__getitem__(i, 0)
            var T_amb_levels = List[Float64](3)
            T_amb_levels[0] = T_amb_low
            T_amb_levels[1] = T_amb_ref
            T_amb_levels[2] = T_amb_high
            for j in range(3):
                var is_od_model_error: Bool = False
                pc_inputs.m_T_amb = T_amb_levels[j]
                var off_design_code: Int32 = self.mf_pc_eq(pc_inputs, pc_outputs)
                if off_design_code == 0:
                    m_dot_htf_ind.__setitem__(i, 1 + j, pc_outputs.m_W_dot_gross_ND)
                    m_dot_htf_ind.__setitem__(i, 4 + j, pc_outputs.m_Q_dot_in_ND)
                    m_dot_htf_ind.__setitem__(i, 7 + j, pc_outputs.m_W_dot_cooling_ND)
                    m_dot_htf_ind.__setitem__(i, 10 + j, pc_outputs.m_m_dot_water_ND)
                elif off_design_code == -1:
                    m_dot_htf_ind.__setitem__(i, 1 + j, pc_inputs.m_m_dot_htf_ND)
                    m_dot_htf_ind.__setitem__(i, 4 + j, pc_inputs.m_m_dot_htf_ND)
                    m_dot_htf_ind.__setitem__(i, 7 + j, pc_inputs.m_m_dot_htf_ND)
                    m_dot_htf_ind.__setitem__(i, 10 + j, pc_inputs.m_m_dot_htf_ND)
                    is_od_model_error = True
                else:
                    var err_msg: String = util.format("The 3rd UDPC table (primary: m_dot_htf_ND, interaction: T_amb) generation failed at T_amb = %lg [C] and m_dot_htf = %lg [-]", pc_inputs.m_T_amb, pc_inputs.m_m_dot_htf_ND)
                    raise C_csp_exception(err_msg, "UDPC")
                var run_number: Float64 = 3.0 * n_T_htf + 3.0 * n_T_amb + i * 3 + j
                self.send_callback(is_od_model_error, (run_number + 1) as Int32, (n_runs_total) as Int32,
                    pc_inputs.m_T_htf_hot, pc_inputs.m_m_dot_htf_ND, pc_inputs.m_T_amb,
                    m_dot_htf_ind.__getitem__(i, 1 + j), m_dot_htf_ind.__getitem__(i, 4 + j),
                    m_dot_htf_ind.__getitem__(i, 7 + j), m_dot_htf_ind.__getitem__(i, 10 + j))
        return 0