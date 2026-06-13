# Imports
from csp_solver_core import (
    C_csp_solver, C_csp_power_cycle, C_csp_collector_receiver,
    C_csp_messages, C_csp_exception
)
from numeric_solvers import C_monotonic_eq_solver
from lib_util import util
from math import abs, min, max

# Note: This file extends the C_csp_solver struct with the methods and nested classes
# as found in the C++ source. The struct C_csp_solver is defined elsewhere,
# but we need to define its members and nested classes here.
struct C_csp_solver:
    var mc_kernel: ...   # type from csp_solver_core
    var mc_sim_info: ...
    var mc_weather: ...
    var mc_cr_htf_state_in: ...
    var mc_cr_out_solver: ...
    var mc_pc_htf_state_in: ...
    var mc_pc_out_solver: ...
    var mc_tes: ...
    var mc_tes_outputs: ...
    var mc_pc_inputs: ...
    var mc_csp_messages: ...
    var mc_collector_receiver: ...
    var mc_power_cycle: ...
    var m_is_tes: Bool
    var m_P_cold_des: Float64
    var m_x_cold_des: Float64
    var m_T_htf_cold_des: Float64
    var m_T_field_cold_limit: Float64
    var m_T_field_in_hot_limit: Float64
    var m_m_dot_pc_des: Float64
    var m_m_dot_pc_max: Float64
    var m_m_dot_pc_max_startup: Float64
    var m_step_tolerance: Float64
    var m_is_cr_config_recirc: Bool
    var m_q_dot_pc_max: Float64
    var error_msg: String

    # Nested class C_MEQ__defocus
    struct C_MEQ__defocus:
        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var m_df_target_mode: E_defocus_target_modes
        var m_ts_target_mode: C_MEQ__timestep.E_timestep_target_modes
        var mpc_csp_solver: C_csp_solver
        var m_q_dot_pc_target: Float64
        var m_pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes
        var m_cr_mode: C_csp_collector_receiver
        var m_t_ts_initial: Float64

        enum E_defocus_target_modes:
            E_M_DOT_BAL
            E_Q_DOT_PC

        def __init__(
            inout self,
            solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes,
            df_target_mode: E_defocus_target_modes,
            ts_target_mode: C_MEQ__timestep.E_timestep_target_modes,
            csp_solver: C_csp_solver,
            q_dot_pc_target: Float64,
            pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes,
            cr_mode: C_csp_collector_receiver,
            t_ts_initial: Float64
        ):
            self.m_solver_mode = solver_mode
            self.m_df_target_mode = df_target_mode
            self.m_ts_target_mode = ts_target_mode
            self.mpc_csp_solver = csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_t_ts_initial = t_ts_initial

        def calc_meq_target(self) -> Float64:
            if self.m_df_target_mode == C_MEQ__defocus.E_defocus_target_modes.E_M_DOT_BAL:
                var m_dot_rec: Float64 = self.mpc_csp_solver.mc_cr_out_solver.m_m_dot_salt_tot  # [kg/hr]
                var m_dot_pc: Float64 = self.mpc_csp_solver.mc_pc_out_solver.m_m_dot_htf        # [kg/hr]
                var m_dot_ch: Float64 = max(0.0, self.mpc_csp_solver.mc_tes_outputs.m_m_dot_cr_to_tes_hot -
                    self.mpc_csp_solver.mc_tes_outputs.m_m_dot_tes_hot_out) * 3600.0  # [kg/hr]
                var m_dot_dc: Float64 = max(0.0, self.mpc_csp_solver.mc_tes_outputs.m_m_dot_pc_to_tes_cold -
                    self.mpc_csp_solver.mc_tes_outputs.m_m_dot_tes_cold_out) * 3600.0  # [kg/hr]
                return (m_dot_rec + m_dot_dc - m_dot_pc - m_dot_ch) / self.mpc_csp_solver.m_m_dot_pc_des  # [-]
            elif self.m_df_target_mode == C_MEQ__defocus.E_defocus_target_modes.E_Q_DOT_PC:
                return self.mpc_csp_solver.mc_pc_out_solver.m_q_dot_htf  # [MWt]

        def __call__(
            inout self,
            defocus: Float64,
            inout target: Float64
        ) -> Int:
            var c_T_cold_eq: C_MEQ__timestep = C_MEQ__timestep(
                self.m_solver_mode,
                self.m_ts_target_mode,
                self.mpc_csp_solver,
                self.m_q_dot_pc_target,
                self.m_pc_mode,
                self.m_cr_mode,
                defocus
            )
            var c_T_cold_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_T_cold_eq)
            var t_ts_solved: Float64 = Float64.nan
            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step = self.m_t_ts_initial  # [s]
            var t_ts_max_local: Float64 = self.m_t_ts_initial  # [s]
            if self.m_ts_target_mode == C_MEQ__timestep.E_timestep_target_modes.E_STEP_Q_DOT_PC:
                var t_ts_guess: Float64 = t_ts_max_local  # [s]
                var q_dot_pc_calc: Float64 = Float64.nan
                var test_code: Int = c_T_cold_solver.test_member_function(t_ts_guess, q_dot_pc_calc)
                if test_code != 0 or (q_dot_pc_calc - self.m_q_dot_pc_target) / self.m_q_dot_pc_target < 1e-3:
                    var xy1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                    xy1.x = t_ts_guess  # [s]
                    xy1.y = q_dot_pc_calc  # [MWt]
                    var t_ts_prev: Float64 = t_ts_guess
                    while test_code != 0:
                        t_ts_prev = xy1.x
                        xy1.x *= 0.8  # [s]
                        xy1.y = Float64.nan
                        test_code = c_T_cold_solver.test_member_function(xy1.x, xy1.y)
                        if xy1.x < self.mpc_csp_solver.m_step_tolerance:
                            self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                            return -6
                    t_ts_guess = 0.5 * xy1.x
                    if xy1.y - self.m_q_dot_pc_target > 0.0:
                        t_ts_guess = 1.05 * xy1.x
                    c_T_cold_solver.settings(1e-3, 50, 0.1, t_ts_prev, True)
                    var tol_solved: Float64 = Float64.nan  # [s]
                    var iter_solved: Int = -1
                    var t_ts_code: Int = 0
                    try:
                        t_ts_code = c_T_cold_solver.solve(xy1, t_ts_guess, self.m_q_dot_pc_target, t_ts_solved, tol_solved, iter_solved)
                    except C_csp_exception:
                        target = Float64.nan
                        self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                        return -4
                    if t_ts_code != C_monotonic_eq_solver.CONVERGED:
                        if t_ts_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved) < 0.1:
                            var msg: String = util.format(
                                "At time = %lg power cycle startup time iteration "
                                " only reached a convergence"
                                "= %lg [s]. Check that results at this timestep are not unreasonably biasing total simulation results",
                                self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                                tol_solved
                            )
                            self.mpc_csp_solver.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                        else:
                            target = Float64.nan
                            self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                            return -7
                else:
                    t_ts_solved = t_ts_guess  # [s]
                if self.m_cr_mode == C_csp_collector_receiver.STARTUP:
                    var t_ts_cr_su: Float64 = self.mpc_csp_solver.mc_cr_out_solver.m_time_required_su  # [s]
                    if t_ts_cr_su < t_ts_solved:
                        self.m_ts_target_mode = C_MEQ__timestep.E_timestep_target_modes.E_STEP_FROM_COMPONENT
                        t_ts_max_local = t_ts_solved
                        t_ts_solved = Float64.nan
            if (self.m_ts_target_mode == C_MEQ__timestep.E_timestep_target_modes.E_STEP_FROM_COMPONENT
                or self.m_ts_target_mode == C_MEQ__timestep.E_timestep_target_modes.E_STEP_FIXED):
                var diff_t_ts_calculated: Float64 = Float64.nan
                var test_code: Int = c_T_cold_solver.test_member_function(t_ts_max_local, diff_t_ts_calculated)
                if self.m_ts_target_mode == C_MEQ__timestep.E_timestep_target_modes.E_STEP_FIXED:
                    if test_code != 0:
                        target = Float64.nan
                        self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                        return -1
                    target = self.calc_meq_target()
                    self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                    return 0
                var t_ts_guess: Float64 = t_ts_max_local  # [s]
                var t_ts_prev: Float64 = t_ts_guess
                while test_code != 0:
                    t_ts_prev = t_ts_guess
                    t_ts_guess *= 0.8  # [s]
                    diff_t_ts_calculated = Float64.nan
                    test_code = c_T_cold_solver.test_member_function(t_ts_guess, diff_t_ts_calculated)
                    if t_ts_guess < self.mpc_csp_solver.m_step_tolerance:
                        self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                        return -6
                t_ts_max_local = t_ts_prev
                if self.m_ts_target_mode == C_MEQ__timestep.E_timestep_target_modes.E_STEP_FROM_COMPONENT and test_code == 0:
                    var t_ts_calculated: Float64 = diff_t_ts_calculated + t_ts_guess  # [s]
                    if t_ts_calculated <= 0.0:
                        target = Float64.nan
                        self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                        return -2
                    if t_ts_calculated < t_ts_guess - self.mpc_csp_solver.m_step_tolerance:
                        var xy1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                        xy1.x = t_ts_guess  # [s]
                        xy1.y = diff_t_ts_calculated
                        t_ts_solved = t_ts_calculated + 0.05  # [s]
                        test_code = c_T_cold_solver.test_member_function(t_ts_solved, diff_t_ts_calculated)
                        t_ts_calculated = diff_t_ts_calculated + t_ts_solved  # [s]
                        if test_code != 0 or t_ts_calculated <= 0.0:
                            target = Float64.nan
                            self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                            return -3
                        if diff_t_ts_calculated < -0.1 or diff_t_ts_calculated > 0.0:
                            var tol_t_ts_target: Float64 = 0.1  # [s]
                            c_T_cold_solver.settings(tol_t_ts_target, 50, 0.0, t_ts_max_local, False)
                            var xy2: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                            xy2.x = t_ts_solved  # [s]
                            xy2.y = diff_t_ts_calculated
                            var tol_solved: Float64 = Float64.nan  # [s]
                            var iter_solved: Int = -1
                            var t_ts_code: Int = 0
                            try:
                                t_ts_code = c_T_cold_solver.solve(xy1, xy2, -tol_t_ts_target, t_ts_solved, tol_solved, iter_solved)
                            except C_csp_exception:
                                target = Float64.nan
                                self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                                return -4
                            if t_ts_code != C_monotonic_eq_solver.CONVERGED:
                                if t_ts_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved) < 0.1 * self.m_t_ts_initial:
                                    var msg: String = util.format(
                                        "At time = %lg power cycle startup time iteration "
                                        " only reached a convergence"
                                        "= %lg [s]. Check that results at this timestep are not unreasonably biasing total simulation results",
                                        self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                                        tol_solved
                                    )
                                    self.mpc_csp_solver.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                                else:
                                    target = Float64.nan
                                    self.mpc_csp_solver.reset_time(self.m_t_ts_initial)
                                    return -5
                    else:
                        t_ts_solved = t_ts_max_local
                else:
                    return -123
            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step = t_ts_solved  # [s]
            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time = self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time_start + t_ts_solved  # [s]
            target = self.calc_meq_target()
            return 0

    # Nested class C_MEQ__timestep
    struct C_MEQ__timestep:
        enum E_timestep_target_modes:
            E_STEP_Q_DOT_PC
            E_STEP_FROM_COMPONENT
            E_STEP_FIXED

        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var m_step_target_mode: E_timestep_target_modes
        var mpc_csp_solver: C_csp_solver
        var m_q_dot_pc_target: Float64
        var m_pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes
        var m_cr_mode: C_csp_collector_receiver
        var m_defocus: Float64

        def __init__(
            inout self,
            solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes,
            step_target_mode: E_timestep_target_modes,
            csp_solver: C_csp_solver,
            q_dot_pc_target: Float64,
            pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes,
            cr_mode: C_csp_collector_receiver,
            defocus: Float64
        ):
            self.m_solver_mode = solver_mode
            self.m_step_target_mode = step_target_mode
            self.mpc_csp_solver = csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_defocus = defocus

        def __call__(
            inout self,
            t_ts_guess: Float64,
            inout target: Float64
        ) -> Int:
            var c_eq: C_MEQ__T_field_cold = C_MEQ__T_field_cold(
                self.m_solver_mode,
                self.mpc_csp_solver,
                self.m_q_dot_pc_target,
                self.m_pc_mode,
                self.m_cr_mode,
                self.m_defocus,
                t_ts_guess,
                self.mpc_csp_solver.m_P_cold_des,
                self.mpc_csp_solver.m_x_cold_des
            )
            var c_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_eq)
            var T_field_cold_guess_1: Float64 = self.mpc_csp_solver.m_T_htf_cold_des - 273.15  # [C], convert from [K]
            var diff_T_field_cold: Float64 = Float64.nan
            var T_field_cold_code: Int = -1
            try:
                T_field_cold_code = c_solver.test_member_function(T_field_cold_guess_1, diff_T_field_cold)
            except C_csp_exception:
                return -2
            if T_field_cold_code != 0:
                return -3
            if abs(diff_T_field_cold) > 1e-3:
                c_solver.settings(1e-3, 50, self.mpc_csp_solver.m_T_field_cold_limit, self.mpc_csp_solver.m_T_field_in_hot_limit, False)
                var xy1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                xy1.x = T_field_cold_guess_1  # [C]
                xy1.y = diff_T_field_cold  # [-]
                var T_field_cold_guess_2: Float64 = Float64.nan
                if diff_T_field_cold > 0.0:
                    T_field_cold_guess_2 = T_field_cold_guess_1 + 10.0  # [C]
                else:
                    T_field_cold_guess_2 = T_field_cold_guess_1 - 10.0  # [C]
                var T_field_cold_solved: Float64 = Float64.nan
                var tol_solved: Float64 = Float64.nan
                var iter_solved: Int = -1
                T_field_cold_code = 0
                try:
                    T_field_cold_code = c_solver.solve(xy1, T_field_cold_guess_2, 0.0, T_field_cold_solved, tol_solved, iter_solved)
                except C_csp_exception:
                    raise C_csp_exception(
                        util.format(
                            "At time = %lg, C_MEQ__timestep failed",
                            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time
                        ),
                        ""
                    )
                if T_field_cold_code != C_monotonic_eq_solver.CONVERGED:
                    if T_field_cold_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved) < 0.1:
                        var abc: Float64 = 1.23
                    else:
                        target = Float64.nan
                        return -1
            if self.m_step_target_mode == E_timestep_target_modes.E_STEP_FROM_COMPONENT:
                target = c_eq.m_t_ts_calc - t_ts_guess  # [s]
            elif self.m_step_target_mode == E_timestep_target_modes.E_STEP_Q_DOT_PC:
                target = self.mpc_csp_solver.mc_pc_out_solver.m_q_dot_htf  # [MWt]
            elif self.m_step_target_mode == E_timestep_target_modes.E_STEP_FIXED:
                target = 0.0
            else:
                target = Float64.nan
            return 0

    # Nested class C_MEQ__m_dot_tes
    struct C_MEQ__m_dot_tes:
        enum E_m_dot_solver_modes:
            E__CR_OUT__CR_OUT_PLUS_TES_EMPTY
            E__CR_OUT__0
            E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
            E__CR_OUT__ITER_M_DOT_SU_DC_ONLY
            E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY
            E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY
            E__CR_OUT__CR_OUT
            E__CR_OUT__CR_OUT_LESS_TES_FULL
            E__PC_MAX_PLUS_TES_FULL__PC_MAX
            E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU
            E__TO_PC__PC_MAX
            E__TO_PC__ITER_M_DOT_SU
            E__TES_FULL__0

        var m_solver_mode: E_m_dot_solver_modes
        var mpc_csp_solver: C_csp_solver
        var m_pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes
        var m_cr_mode: C_csp_collector_receiver
        var m_q_dot_pc_target: Float64
        var m_defocus: Float64
        var m_t_ts_in: Float64
        var m_P_field_in: Float64
        var m_x_field_in: Float64
        var m_T_field_cold_guess: Float64
        # Output members
        var m_T_field_cold_calc: Float64 = Float64.nan
        var m_t_ts_calc: Float64 = Float64.nan
        var m_m_dot_pc_in: Float64 = Float64.nan

        def __init__(
            inout self,
            solver_mode: E_m_dot_solver_modes,
            csp_solver: C_csp_solver,
            pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes,
            cr_mode: C_csp_collector_receiver,
            q_dot_pc_target: Float64,
            defocus: Float64,
            t_ts_in: Float64,
            P_field_in: Float64,
            x_field_in: Float64,
            T_field_cold_guess: Float64
        ):
            self.m_solver_mode = solver_mode
            self.mpc_csp_solver = csp_solver
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_defocus = defocus
            self.m_t_ts_in = t_ts_in
            self.m_P_field_in = P_field_in
            self.m_x_field_in = x_field_in
            self.m_T_field_cold_guess = T_field_cold_guess
            self.init_calc_member_vars()

        def init_calc_member_vars(inout self):
            self.m_T_field_cold_calc = Float64.nan
            self.m_t_ts_calc = Float64.nan
            self.m_m_dot_pc_in = Float64.nan

        def __call__(
            inout self,
            f_m_dot_tes: Float64,
            inout diff_target: Float64
        ) -> Int:
            self.init_calc_member_vars()
            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step = self.m_t_ts_in  # [s]
            self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time = self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time_start + self.m_t_ts_in  # [s]
            self.mpc_csp_solver.mc_cr_htf_state_in.m_temp = self.m_T_field_cold_guess  # [C]
            self.mpc_csp_solver.mc_cr_htf_state_in.m_pres = self.m_P_field_in  # [kPa]
            self.mpc_csp_solver.mc_cr_htf_state_in.m_qual = self.m_x_field_in  # [-]
            var m_dot_field_out: Float64 = Float64.nan  # [kg/hr]
            var t_ts_cr_su: Float64 = self.m_t_ts_in
            if self.m_cr_mode == C_csp_collector_receiver.ON:
                self.mpc_csp_solver.mc_collector_receiver.on(
                    self.mpc_csp_solver.mc_weather.ms_outputs,
                    self.mpc_csp_solver.mc_cr_htf_state_in,
                    self.m_defocus,
                    self.mpc_csp_solver.mc_cr_out_solver,
                    self.mpc_csp_solver.mc_kernel.mc_sim_info
                )
                if self.mpc_csp_solver.mc_cr_out_solver.m_m_dot_salt_tot == 0.0 or self.mpc_csp_solver.mc_cr_out_solver.m_q_thermal == 0.0:
                    diff_target = Float64.nan
                    return -1
                m_dot_field_out = self.mpc_csp_solver.mc_cr_out_solver.m_m_dot_salt_tot  # [kg/hr]
            elif self.m_cr_mode == C_csp_collector_receiver.STARTUP:
                self.mpc_csp_solver.mc_collector_receiver.startup(
                    self.mpc_csp_solver.mc_weather.ms_outputs,
                    self.mpc_csp_solver.mc_cr_htf_state_in,
                    self.mpc_csp_solver.mc_cr_out_solver,
                    self.mpc_csp_solver.mc_kernel.mc_sim_info
                )
                if self.mpc_csp_solver.mc_cr_out_solver.m_q_startup == 0.0:
                    diff_target = Float64.nan
                    return -1
                if self.mpc_csp_solver.m_is_cr_config_recirc:
                    m_dot_field_out = 0.0  # [kg/hr]
                t_ts_cr_su = self.mpc_csp_solver.mc_cr_out_solver.m_time_required_su  # [s]
            elif self.m_cr_mode == C_csp_collector_receiver.OFF:
                self.mpc_csp_solver.mc_collector_receiver.off(
                    self.mpc_csp_solver.mc_weather.ms_outputs,
                    self.mpc_csp_solver.mc_cr_htf_state_in,
                    self.mpc_csp_solver.mc_cr_out_solver,
                    self.mpc_csp_solver.mc_kernel.mc_sim_info
                )
                if self.mpc_csp_solver.m_is_cr_config_recirc:
                    m_dot_field_out = 0.0  # [kg/hr]
            if abs((self.mpc_csp_solver.mc_cr_out_solver.m_P_htf_hot - self.m_P_field_in) / self.m_P_field_in) > 0.001 and not self.mpc_csp_solver.mc_collector_receiver.m_is_sensible_htf:
                var msg: String = util.format(
                    "C_csp_solver::solver_cr_to_pc_to_cr(...) The pressure returned from the CR model, %lg [bar],"
                    " is different than the assumed constant pressure, %lg [bar]",
                    self.mpc_csp_solver.mc_cr_out_solver.m_P_htf_hot / 100.0,
                    self.m_P_field_in / 100.0
                )
                self.mpc_csp_solver.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
            var m_dot_pc_max: Float64 = self.mpc_csp_solver.m_m_dot_pc_max  # [kg/hr]
            if self.m_pc_mode == C_csp_power_cycle.E_csp_power_cycle_modes.STARTUP_CONTROLLED:
                m_dot_pc_max = self.mpc_csp_solver.m_m_dot_pc_max_startup  # [kg/hr]
            var m_dot_hot_to_tes: Float64 = Float64.nan
            if (self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT_PLUS_TES_EMPTY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__0
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_DC_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT_LESS_TES_FULL):
                if self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT_PLUS_TES_EMPTY:
                    var q_dot_dc_est: Float64 = Float64.nan
                    var m_dot_tes_dc: Float64 = Float64.nan
                    var T_tes_dc_est: Float64 = Float64.nan
                    self.mpc_csp_solver.mc_tes.discharge_avail_est(
                        self.m_T_field_cold_guess,
                        self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                        q_dot_dc_est,
                        m_dot_tes_dc,
                        T_tes_dc_est
                    )
                    m_dot_tes_dc *= 3600.0  # [kg/hr] convert from kg/s
                    self.m_m_dot_pc_in = min(m_dot_pc_max, m_dot_field_out + m_dot_tes_dc)
                elif self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__0:
                    self.m_m_dot_pc_in = 0.0
                elif (self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_DC_ONLY
                      or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY):
                    var q_dot_dc_est: Float64 = Float64.nan
                    var m_dot_tes_dc: Float64 = Float64.nan
                    var T_tes_dc_est: Float64 = Float64.nan
                    self.mpc_csp_solver.mc_tes.discharge_avail_est(
                        self.m_T_field_cold_guess,
                        self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                        q_dot_dc_est,
                        m_dot_tes_dc,
                        T_tes_dc_est
                    )
                    m_dot_tes_dc *= 3600.0  # [kg/hr] convert from kg/s
                    var m_dot_to_pc_max: Float64 = min(m_dot_pc_max, m_dot_tes_dc + m_dot_field_out)
                    self.m_m_dot_pc_in = m_dot_field_out + min(0.99999, f_m_dot_tes) * max(0.0, m_dot_to_pc_max - m_dot_field_out)
                elif (self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
                      or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY):
                    var q_dot_ch_est: Float64 = Float64.nan
                    var m_dot_hot_to_tes_est: Float64 = Float64.nan
                    var T_cold_field_est: Float64 = Float64.nan
                    self.mpc_csp_solver.mc_tes.charge_avail_est(
                        self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                        self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                        q_dot_ch_est,
                        m_dot_hot_to_tes_est,
                        T_cold_field_est
                    )
                    m_dot_hot_to_tes_est *= 3600  # [kg/hr] convert from kg/s
                    var m_dot_to_tes_max: Float64 = min(m_dot_field_out, m_dot_hot_to_tes_est)
                    var m_dot_to_tes_min: Float64 = max(m_dot_field_out - m_dot_pc_max, 0.0)
                    var m_dot_to_tes: Float64 = m_dot_to_tes_max - min(0.99999, f_m_dot_tes) * max(0.0, m_dot_to_tes_max - m_dot_to_tes_min)
                    self.m_m_dot_pc_in = m_dot_field_out - m_dot_to_tes
                elif self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT:
                    self.m_m_dot_pc_in = m_dot_field_out  # [kg/hr]
                elif self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__CR_OUT_LESS_TES_FULL:
                    var q_dot_ch_est: Float64 = Float64.nan
                    var m_dot_hot_to_tes_est: Float64 = Float64.nan
                    var T_cold_field_est: Float64 = Float64.nan
                    self.mpc_csp_solver.mc_tes.charge_avail_est(
                        self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                        self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                        q_dot_ch_est,
                        m_dot_hot_to_tes_est,
                        T_cold_field_est
                    )
                    m_dot_hot_to_tes_est *= 3600  # [kg/hr] convert from kg/s
                    self.m_m_dot_pc_in = max(0.0, m_dot_field_out - m_dot_hot_to_tes_est)  # [kg/hr]
                if self.m_m_dot_pc_in < 0.0:
                    diff_target = Float64.nan
                    return -2
                if self.m_m_dot_pc_in > m_dot_pc_max:
                    return -11
                m_dot_hot_to_tes = m_dot_field_out  # [kg/hr]
            elif (self.m_solver_mode == E_m_dot_solver_modes.E__PC_MAX_PLUS_TES_FULL__PC_MAX
                  or self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU):
                var q_dot_ch_est: Float64 = Float64.nan
                var m_dot_hot_to_tes_est: Float64 = Float64.nan
                var T_cold_field_est: Float64 = Float64.nan
                self.mpc_csp_solver.mc_tes.charge_avail_est(
                    self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                    self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                    q_dot_ch_est,
                    m_dot_hot_to_tes_est,
                    T_cold_field_est
                )
                m_dot_hot_to_tes_est *= 3600  # [kg/hr] convert from kg/s
                if self.m_solver_mode == E_m_dot_solver_modes.E__PC_MAX_PLUS_TES_FULL__PC_MAX:
                    self.m_m_dot_pc_in = m_dot_pc_max  # [kg/hr]
                elif self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU:
                    self.m_m_dot_pc_in = min(0.99999, f_m_dot_tes) * m_dot_pc_max
                if self.m_m_dot_pc_in > m_dot_pc_max:
                    return -12
                m_dot_hot_to_tes = self.m_m_dot_pc_in + m_dot_hot_to_tes_est  # [kg/hr]
            elif (self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC__PC_MAX
                  or self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC__ITER_M_DOT_SU):
                if self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC__PC_MAX:
                    self.m_m_dot_pc_in = m_dot_pc_max  # [kg/hr]
                elif self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC__ITER_M_DOT_SU:
                    self.m_m_dot_pc_in = min(0.99999, f_m_dot_tes) * m_dot_pc_max
                if self.m_m_dot_pc_in > m_dot_pc_max:
                    return -12
                m_dot_hot_to_tes = self.m_m_dot_pc_in
            elif self.m_solver_mode == E_m_dot_solver_modes.E__TES_FULL__0:
                var q_dot_ch_est: Float64 = Float64.nan
                var m_dot_hot_to_tes_est: Float64 = Float64.nan
                var T_cold_field_est: Float64 = Float64.nan
                self.mpc_csp_solver.mc_tes.charge_avail_est(
                    self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                    self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                    q_dot_ch_est,
                    m_dot_hot_to_tes_est,
                    T_cold_field_est
                )
                m_dot_hot_to_tes_est *= 3600  # [kg/hr] convert from kg/s
                m_dot_hot_to_tes = m_dot_hot_to_tes_est  # [kg/hr]
                self.m_m_dot_pc_in = 0.0
            var T_cycle_hot: Float64 = Float64.nan  # [K]
            var T_field_cold_calc: Float64 = Float64.nan  # [K]
            if self.mpc_csp_solver.m_is_tes:
                var tes_code: Int = self.mpc_csp_solver.mc_tes.solve_tes_off_design(
                    self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                    self.mpc_csp_solver.mc_weather.ms_outputs.m_tdry + 273.15,
                    m_dot_hot_to_tes / 3600.0,
                    self.m_m_dot_pc_in / 3600.0,
                    self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                    self.m_T_field_cold_guess + 273.15,
                    T_cycle_hot,
                    T_field_cold_calc,
                    self.mpc_csp_solver.mc_tes_outputs
                )
                if tes_code != 0:
                    diff_target = Float64.nan
                    return -3
            else:
                T_cycle_hot = self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15  # [K]
            self.mpc_csp_solver.mc_pc_htf_state_in.m_temp = T_cycle_hot - 273.15  # [C]
            self.mpc_csp_solver.mc_pc_htf_state_in.m_pres = self.mpc_csp_solver.mc_cr_out_solver.m_P_htf_hot  # [kPa]
            self.mpc_csp_solver.mc_pc_htf_state_in.m_qual = self.mpc_csp_solver.mc_cr_out_solver.m_xb_htf_hot  # [-]
            self.mpc_csp_solver.mc_pc_inputs.m_m_dot = self.m_m_dot_pc_in  # [kg/hr]
            self.mpc_csp_solver.mc_pc_inputs.m_standby_control = self.m_pc_mode
            self.mpc_csp_solver.mc_power_cycle.call(
                self.mpc_csp_solver.mc_weather.ms_outputs,
                self.mpc_csp_solver.mc_pc_htf_state_in,
                self.mpc_csp_solver.mc_pc_inputs,
                self.mpc_csp_solver.mc_pc_out_solver,
                self.mpc_csp_solver.mc_kernel.mc_sim_info
            )
            if not self.mpc_csp_solver.mc_pc_out_solver.m_was_method_successful and self.mpc_csp_solver.mc_pc_inputs.m_standby_control == C_csp_power_cycle.ON:
                diff_target = Float64.nan
                return -2
            var t_ts_pc_su: Float64 = self.m_t_ts_in  # [s]
            if self.m_pc_mode == C_csp_power_cycle.STARTUP or self.m_pc_mode == C_csp_power_cycle.STARTUP_CONTROLLED:
                t_ts_pc_su = self.mpc_csp_solver.mc_pc_out_solver.m_time_required_max  # [s]
            if self.mpc_csp_solver.m_is_tes:
                var tes_code: Int = self.mpc_csp_solver.mc_tes.solve_tes_off_design(
                    self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_step,
                    self.mpc_csp_solver.mc_weather.ms_outputs.m_tdry + 273.15,
                    m_dot_hot_to_tes / 3600.0,
                    self.m_m_dot_pc_in / 3600.0,
                    self.mpc_csp_solver.mc_cr_out_solver.m_T_salt_hot + 273.15,
                    self.mpc_csp_solver.mc_pc_out_solver.m_T_htf_cold + 273.15,
                    T_cycle_hot,
                    T_field_cold_calc,
                    self.mpc_csp_solver.mc_tes_outputs
                )
                if tes_code != 0:
                    diff_target = Float64.nan
                    return -3
            else:
                T_field_cold_calc = self.mpc_csp_solver.mc_pc_out_solver.m_T_htf_cold + 273.15  # [K]
            self.m_T_field_cold_calc = T_field_cold_calc - 273.15  # [C]
            if self.m_cr_mode == C_csp_collector_receiver.STARTUP and (self.m_pc_mode == C_csp_power_cycle.STARTUP or self.m_pc_mode == C_csp_power_cycle.STARTUP_CONTROLLED):
                self.m_t_ts_calc = min(t_ts_pc_su, t_ts_cr_su)  # [s]
            elif self.m_cr_mode == C_csp_collector_receiver.STARTUP:
                self.m_t_ts_calc = t_ts_cr_su  # [s]
            elif self.m_pc_mode == C_csp_power_cycle.STARTUP or self.m_pc_mode == C_csp_power_cycle.STARTUP_CONTROLLED:
                self.m_t_ts_calc = t_ts_pc_su  # [s]
            if (self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_DC_ONLY
                or self.m_solver_mode == E_m_dot_solver_modes.E__TO_PC__ITER_M_DOT_SU):
                diff_target = (self.m_m_dot_pc_in - self.mpc_csp_solver.mc_pc_out_solver.m_m_dot_htf) / self.mpc_csp_solver.mc_pc_out_solver.m_m_dot_htf
            elif (self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY
                  or self.m_solver_mode == E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY):
                diff_target = (self.mpc_csp_solver.mc_pc_out_solver.m_q_dot_htf - self.m_q_dot_pc_target) / self.m_q_dot_pc_target
            return 0

    # Nested class C_MEQ__T_field_cold
    struct C_MEQ__T_field_cold:
        var m_solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes
        var mpc_csp_solver: C_csp_solver
        var m_q_dot_pc_target: Float64
        var m_pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes
        var m_cr_mode: C_csp_collector_receiver
        var m_defocus: Float64
        var m_t_ts_in: Float64
        var m_P_field_in: Float64
        var m_x_field_in: Float64
        var m_t_ts_calc: Float64 = Float64.nan

        def __init__(
            inout self,
            solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes,
            csp_solver: C_csp_solver,
            q_dot_pc_target: Float64,
            pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes,
            cr_mode: C_csp_collector_receiver,
            defocus: Float64,
            t_ts_in: Float64,
            P_field_in: Float64,
            x_field_in: Float64
        ):
            self.m_solver_mode = solver_mode
            self.mpc_csp_solver = csp_solver
            self.m_q_dot_pc_target = q_dot_pc_target
            self.m_pc_mode = pc_mode
            self.m_cr_mode = cr_mode
            self.m_defocus = defocus
            self.m_t_ts_in = t_ts_in
            self.m_P_field_in = P_field_in
            self.m_x_field_in = x_field_in

        def init_calc_member_vars(inout self):
            self.m_t_ts_calc = Float64.nan

        def __call__(
            inout self,
            T_field_cold: Float64,
            inout diff_T_field_cold: Float64
        ) -> Int:
            self.init_calc_member_vars()
            var c_eq: C_MEQ__m_dot_tes = C_MEQ__m_dot_tes(
                self.m_solver_mode,
                self.mpc_csp_solver,
                self.m_pc_mode,
                self.m_cr_mode,
                self.m_q_dot_pc_target,
                self.m_defocus,
                self.m_t_ts_in,
                self.m_P_field_in,
                self.m_x_field_in,
                T_field_cold
            )
            var c_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_eq)
            if (self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_DC_ONLY
                or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY
                or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
                or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY
                or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__TO_PC_PLUS_TES_FULL__ITER_M_DOT_SU
                or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__TO_PC__ITER_M_DOT_SU):
                var diff_m_dot: Float64 = Float64.nan
                var f_m_dot_guess_1: Float64 = 1.0
                var f_m_dot_code: Int = c_solver.test_member_function(f_m_dot_guess_1, diff_m_dot)
                if f_m_dot_code != 0:
                    return -1
                if ((self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_CH_ONLY
                     or self.m_solver_mode == C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_Q_DOT_TARGET_DC_ONLY)
                    and diff_m_dot < 0.0):
                    self.m_t_ts_calc = c_eq.m_t_ts_calc
                    var T_field_cold_calc: Float64 = c_eq.m_T_field_cold_calc  # [C]
                    diff_T_field_cold = (T_field_cold_calc - T_field_cold) / T_field_cold  # [-]
                    return 0
                elif diff_m_dot < -1e-3:
                    return -4
                if abs(diff_m_dot) > 1e-3:
                    var xy1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                    xy1.x = f_m_dot_guess_1  # [-]
                    xy1.y = diff_m_dot  # [-]
                    var f_m_dot_guess_2: Float64 = 1.0 / (1.0 + diff_m_dot)  # [-]
                    c_solver.settings(1e-3, 50, 0.0, 1.0, False)
                    var f_m_dot_solved: Float64 = Float64.nan
                    var tol_solved: Float64 = Float64.nan
                    var iter_solved: Int = -1
                    f_m_dot_code = -1
                    try:
                        f_m_dot_code = c_solver.solve(xy1, f_m_dot_guess_2, 0.0, f_m_dot_solved, tol_solved, iter_solved)
                    except C_csp_exception:
                        return -2
                    if f_m_dot_code != C_monotonic_eq_solver.CONVERGED:
                        if f_m_dot_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved) < 0.1:
                            var msg: String = util.format(
                                "At time = %lg power cycle mass flow for startup "
                                "iteration to find a defocus resulting in the maximum power cycle mass flow rate only reached a convergence "
                                "= %lg. Check that results at this timestep are not unreasonably biasing total simulation results",
                                self.mpc_csp_solver.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                                tol_solved
                            )
                            self.mpc_csp_solver.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                        else:
                            return -3
            else:
                var m_dot_tes: Float64 = Float64.nan
                var y_diff_target: Float64 = Float64.nan
                var m_dot_err: Int = c_solver.test_member_function(m_dot_tes, y_diff_target)
                if m_dot_err != 0:
                    diff_T_field_cold = Float64.nan
                    return m_dot_err
            self.m_t_ts_calc = c_eq.m_t_ts_calc
            var T_field_cold_calc: Float64 = c_eq.m_T_field_cold_calc  # [C]
            diff_T_field_cold = (T_field_cold_calc - T_field_cold) / T_field_cold  # [-]
            return 0

    # Methods of C_csp_solver
    def reset_time(inout self, step: Float64):  # step [s]
        self.mc_kernel.mc_sim_info.ms_ts.m_step = step  # [s]
        self.mc_kernel.mc_sim_info.ms_ts.m_time = self.mc_kernel.mc_sim_info.ms_ts.m_time_start + self.mc_kernel.mc_sim_info.ms_ts.m_step  # [s]

    def solve_operating_mode(
        inout self,
        cr_mode: Int,
        pc_mode: C_csp_power_cycle.E_csp_power_cycle_modes,
        solver_mode: C_MEQ__m_dot_tes.E_m_dot_solver_modes,
        step_target_mode: C_MEQ__timestep.E_timestep_target_modes,
        q_dot_pc_target: Float64,  # MWt
        is_defocus: Bool,
        op_mode_str: String,
        inout defocus_solved: Float64
    ) -> Int:
        var t_ts_initial: Float64 = self.mc_kernel.mc_sim_info.ms_ts.m_step  # [s]
        var c_mdot_eq: C_MEQ__defocus = C_MEQ__defocus(
            solver_mode,
            C_MEQ__defocus.E_defocus_target_modes.E_M_DOT_BAL,
            step_target_mode,
            self,
            q_dot_pc_target,
            pc_mode,
            cr_mode,
            t_ts_initial
        )
        var c_mdot_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_mdot_eq)
        var df_full: Float64 = 1.0
        var m_dot_bal: Float64 = Float64.nan
        var m_dot_bal_code: Int = c_mdot_solver.test_member_function(df_full, m_dot_bal)
        if m_dot_bal_code != 0:
            self.reset_time(t_ts_initial)
            return -1
        defocus_solved = df_full  # [-]
        var is_m_dot_bal_converged: Bool = False
        if is_defocus:
            if m_dot_bal > 0.0:
                var xy1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                xy1.x = defocus_solved
                xy1.y = m_dot_bal
                var xy2: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                var m_dot_bal2: Float64 = Float64.nan
                var x1: Float64 = xy1.x
                do:
                    xy2.x = x1 * (1.0 / (1.0 + m_dot_bal))
                    m_dot_bal_code = c_mdot_solver.test_member_function(xy2.x, m_dot_bal2)
                    if m_dot_bal_code != 0:
                        self.reset_time(t_ts_initial)
                        return -2
                    x1 = xy2.x
                while abs(m_dot_bal2 - m_dot_bal) < 0.02
                xy2.y = m_dot_bal2
                c_mdot_solver.settings(1e-3, 50, 0.0, 1.0, False)
                var tol_solved: Float64 = Float64.nan
                var iter_solved: Int = -1
                try:
                    m_dot_bal_code = c_mdot_solver.solve(xy1, xy2, -1e-3, defocus_solved, tol_solved, iter_solved)
                except C_csp_exception:
                    self.reset_time(t_ts_initial)
                    return -3
                if m_dot_bal_code != C_monotonic_eq_solver.CONVERGED:
                    if m_dot_bal_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved) < 0.1:
                        var msg: String = util.format(
                            "At time = %lg %s "
                            "iteration to find a defocus resulting in the maximum power cycle mass flow rate only reached a convergence "
                            "= %lg. Check that results at this timestep are not unreasonably biasing total simulation results",
                            self.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                            op_mode_str,
                            tol_solved
                        )
                        self.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                    else:
                        self.error_msg = util.format(
                            "At time = %lg the controller chose %s operating mode, but the code"
                            " failed to converge.",
                            self.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                            op_mode_str
                        )
                        self.mc_csp_messages.add_message(C_csp_messages.NOTICE, self.error_msg)
                        self.reset_time(t_ts_initial)
                        return -4
                is_m_dot_bal_converged = True
            if (self.mc_pc_out_solver.m_q_dot_htf - self.m_q_dot_pc_max) / self.m_q_dot_pc_max > 1e-3:
                var defocus_guess: Float64 = defocus_solved
                var c_q_dot_eq: C_MEQ__defocus = C_MEQ__defocus(
                    C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__CR_OUT_LESS_TES_FULL,
                    C_MEQ__defocus.E_defocus_target_modes.E_Q_DOT_PC,
                    step_target_mode,
                    self,
                    q_dot_pc_target,
                    pc_mode,
                    cr_mode,
                    t_ts_initial
                )
                var c_q_dot_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_q_dot_eq)
                c_q_dot_solver.settings(1e-3, 50, 0.0, defocus_guess, True)
                var q_dot_pc_1: Float64 = Float64.nan
                var q_dot_df_code: Int = -1
                var defocus_set: Float64 = defocus_guess
                while q_dot_df_code != 0:
                    defocus_guess = defocus_set
                    q_dot_df_code = c_q_dot_solver.test_member_function(defocus_guess, q_dot_pc_1)
                    if q_dot_df_code != 0 and defocus_guess < 0.1:
                        self.error_msg = util.format(
                            "At time = %lg the controller chose %s operating mode, but the code"
                            " failed to converge.",
                            self.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                            op_mode_str
                        )
                        self.mc_csp_messages.add_message(C_csp_messages.NOTICE, self.error_msg)
                        self.reset_time(t_ts_initial)
                        return -5
                    defocus_set *= 0.8
                var xy_q_dot_1: C_monotonic_eq_solver.S_xy_pair = C_monotonic_eq_solver.S_xy_pair()
                xy_q_dot_1.x = defocus_guess
                xy_q_dot_1.y = q_dot_pc_1
                var defocus_guess_q_dot: Float64 = max(
                    0.7 * defocus_guess,
                    min(0.99 * defocus_guess, defocus_guess * (self.m_q_dot_pc_max / self.mc_pc_out_solver.m_q_dot_htf))
                )
                var defocus_solved_local: Float64 = Float64.nan
                var tol_solved_local: Float64 = Float64.nan
                var iter_solved: Int = -1
                var solver_code: Int = 0
                try:
                    solver_code = c_q_dot_solver.solve(xy_q_dot_1, defocus_guess_q_dot, self.m_q_dot_pc_max, defocus_solved_local, tol_solved_local, iter_solved)
                except C_csp_exception:
                    self.reset_time(t_ts_initial)
                    return -6
                if solver_code != C_monotonic_eq_solver.CONVERGED:
                    if solver_code > C_monotonic_eq_solver.CONVERGED and abs(tol_solved_local) < 0.1:
                        var msg: String = util.format(
                            "At time = %lg %s "
                            "iteration to find a defocus resulting in the maximum power cycle heat input only reached a convergence "
                            "= %lg. Check that results at this timestep are not unreasonably biasing total simulation results",
                            self.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                            op_mode_str,
                            tol_solved_local
                        )
                        self.mc_csp_messages.add_message(C_csp_messages.NOTICE, msg)
                    else:
                        self.error_msg = util.format(
                            "At time = %lg the controller chose %s operating mode, but the code"
                            " failed to solve. Controller will shut-down CR and PC",
                            self.mc_kernel.mc_sim_info.ms_ts.m_time / 3600.0,
                            op_mode_str
                        )
                        self.mc_csp_messages.add_message(C_csp_messages.NOTICE, self.error_msg)
                        self.reset_time(t_ts_initial)
                        return -7
            elif defocus_solved == 1.0:
                var solver_mode_df1: C_MEQ__m_dot_tes.E_m_dot_solver_modes = C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__CR_OUT_LESS_TES_FULL
                if pc_mode == C_csp_power_cycle.STARTUP_CONTROLLED:
                    solver_mode_df1 = C_MEQ__m_dot_tes.E_m_dot_solver_modes.E__CR_OUT__ITER_M_DOT_SU_CH_ONLY
                var c_bal_eq: C_MEQ__defocus = C_MEQ__defocus(
                    solver_mode_df1,
                    C_MEQ__defocus.E_defocus_target_modes.E_Q_DOT_PC,
                    step_target_mode,
                    self,
                    q_dot_pc_target,
                    pc_mode,
                    cr_mode,
                    t_ts_initial
                )
                var c_bal_solver: C_monotonic_eq_solver = C_monotonic_eq_solver(c_bal_eq)
                c_bal_solver.settings(1e-3, 50, 0.0, defocus_solved, True)
                var q_dot_pc_bal: Float64 = Float64.nan
                var q_dot_bal_code: Int = c_bal_solver.test_member_function(defocus_solved, q_dot_pc_bal)
                if q_dot_bal_code != 0:
                    self.reset_time(t_ts_initial)
                    return -8
        return 0