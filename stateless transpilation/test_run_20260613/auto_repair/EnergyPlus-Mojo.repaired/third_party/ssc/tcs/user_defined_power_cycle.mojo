from interpolation_routines import Linear_Interp
from csp_solver_util import C_csp_exception, util

struct C_user_defined_pc:
    enum E_output_ME_index:
        i_W_dot_gross = 1
        i_Q_dot_HTF = 3
        i_W_dot_cooling = 5
        i_m_dot_water = 7

    var mc_T_htf_ind: Linear_Interp
    var mc_T_amb_ind: Linear_Interp
    var mc_m_dot_htf_ind: Linear_Interp
    var m_error_msg: String

    def __init__(inout self):
        self.mc_T_htf_ind = Linear_Interp()
        self.mc_T_amb_ind = Linear_Interp()
        self.mc_m_dot_htf_ind = Linear_Interp()
        self.m_error_msg = String()

    def __del__(owned self):

    def init(inout self, T_htf_ind: util.matrix_t[Float64], T_amb_ind: util.matrix_t[Float64], m_dot_htf_ind: util.matrix_t[Float64]) raises:
        var error_index: Int = -2
        var column_index_array: StaticIntTuple[1] = StaticIntTuple[1](0)
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

    def get_W_dot_gross_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) -> Float64:
        return self.get_interpolated_ND_output(E_output_ME_index.i_W_dot_gross, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_Q_dot_HTF_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) -> Float64:
        return self.get_interpolated_ND_output(E_output_ME_index.i_Q_dot_HTF, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_W_dot_cooling_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) -> Float64:
        return self.get_interpolated_ND_output(E_output_ME_index.i_W_dot_cooling, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_m_dot_water_ND(inout self, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) -> Float64:
        return self.get_interpolated_ND_output(E_output_ME_index.i_m_dot_water, T_htf_hot, T_amb, m_dot_htf_ND)

    def get_interpolated_ND_output(inout self, i_ME: Int, T_htf_hot: Float64, T_amb: Float64, m_dot_htf_ND: Float64) -> Float64:
        var Y_ME_T_htf: Float64 = self.mc_T_htf_ind.interpolate_x_col_0(i_ME, T_htf_hot)
        var Y_INT_on_T_htf: Float64 = self.mc_T_amb_ind.interpolate_x_col_0(i_ME+1, T_amb)
        var Y_ME_T_amb: Float64 = self.mc_T_amb_ind.interpolate_x_col_0(i_ME, T_amb)
        var Y_INT_on_T_amb: Float64 = self.mc_m_dot_htf_ind.interpolate_x_col_0(i_ME+1, m_dot_htf_ND)
        var Y_ME_m_dot: Float64 = self.mc_m_dot_htf_ind.interpolate_x_col_0(i_ME, m_dot_htf_ND)
        var Y_INT_on_m_dot: Float64 = self.mc_T_htf_ind.interpolate_x_col_0(i_ME+1, T_htf_hot)
        return ((Y_ME_T_htf-1)*Y_INT_on_T_htf + 1.0) * \
               ((Y_ME_T_amb-1)*Y_INT_on_T_amb + 1.0) * \
               ((Y_ME_m_dot-1)*Y_INT_on_m_dot + 1.0)