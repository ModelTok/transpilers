from core import compute_module, var_info, SSC_INPUT, SSC_NUMBER
from ud_power_cycle import C_ud_power_cycle

var _cm_vtab_test_ud_power_cycle: List[var_info] = [
    #   VARTYPE   DATATYPE         NAME               LABEL                                          UNITS     META  GROUP REQUIRED_IF CONSTRAINTS         UI_HINTS
    var_info(SSC_INPUT, SSC_NUMBER, "q_pb_design", "Design point power block thermal power", "MWt", "", "", "", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "W_dot_fossil", "Electric output with no solar contribution", "MWe", "", "", "", "", ""),
    var_info_invalid,
]

class cm_test_ud_power_cycle(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_test_ud_power_cycle)

    def exec(inout self):
        let a_ref: Float64 = 12.0
        let b_ref: Float64 = 13.0
        let c_ref: Float64 = 14.0
        let Y_ref: Float64 = self.three_var_eqn(a_ref, b_ref, c_ref)
        let a_low: Float64 = 10.0
        let a_high: Float64 = 14.0
        let b_low: Float64 = 10.0
        let b_high: Float64 = 16.0
        let c_low: Float64 = 10.0
        let c_high: Float64 = 18.0
        let N_runs: Int = 20

        var a_table = List[List[Float64]](N_runs)
        var b_table = List[List[Float64]](N_runs)
        var c_table = List[List[Float64]](N_runs)
        for i in range(N_runs):
            a_table[i] = List[Float64](13, 1.0)
            b_table[i] = List[Float64](13, 1.0)
            c_table[i] = List[Float64](13, 1.0)

        for i in range(N_runs):
            a_table[i][0] = a_low + (a_high - a_low) / Float64(N_runs - 1) * Float64(i)
            a_table[i][1] = self.three_var_eqn(a_table[i][0], b_ref, c_low) / Y_ref
            a_table[i][2] = self.three_var_eqn(a_table[i][0], b_ref, c_ref) / Y_ref
            a_table[i][3] = self.three_var_eqn(a_table[i][0], b_ref, c_high) / Y_ref

            b_table[i][0] = b_low + (b_high - b_low) / Float64(N_runs - 1) * Float64(i)
            b_table[i][1] = self.three_var_eqn(a_low, b_table[i][0], c_ref) / Y_ref
            b_table[i][2] = self.three_var_eqn(a_ref, b_table[i][0], c_ref) / Y_ref
            b_table[i][3] = self.three_var_eqn(a_high, b_table[i][0], c_ref) / Y_ref

            c_table[i][0] = c_low + (c_high - c_low) / Float64(N_runs - 1) * Float64(i)
            c_table[i][1] = self.three_var_eqn(a_ref, b_low, c_table[i][0]) / Y_ref
            c_table[i][2] = self.three_var_eqn(a_ref, b_ref, c_table[i][0]) / Y_ref
            c_table[i][3] = self.three_var_eqn(a_ref, b_high, c_table[i][0]) / Y_ref

        var c_pc = C_ud_power_cycle()
        c_pc.init(
            a_table, a_ref, a_low, a_high,
            b_table, b_ref, b_low, b_high,
            c_table, c_ref, c_low, c_high
        )

        let n_test: Int = N_runs * N_runs * N_runs
        var Y_actual = List[Float64](n_test)
        var Y_reg = List[Float64](n_test)
        var E_reg_less_act = List[Float64](n_test)
        var max_err: Float64 = -1.0

        for i in range(N_runs):
            for j in range(N_runs):
                for k in range(N_runs):
                    let index = i * N_runs * N_runs + j * N_runs + k
                    Y_actual[index] = self.three_var_eqn(a_table[i][0], b_table[j][0], c_table[k][0])
                    Y_reg[index] = c_pc.get_W_dot_gross_ND(a_table[i][0], b_table[j][0], c_table[k][0]) * Y_ref
                    E_reg_less_act[index] = (Y_reg[index] - Y_actual[index]) / max(Y_actual[index], 0.0001)
                    if abs(E_reg_less_act[index]) > max_err:
                        max_err = abs(E_reg_less_act[index])

    def three_var_eqn(self, a: Float64, b: Float64, c: Float64) -> Float64:
        return a * pow(b, 1.24) - a / pow(c, 0.55) + b / (2 * c + 1.0) * a

# DEFINE_MODULE_ENTRY(test_ud_power_cycle, "Test user-defined power cylce model", 0)