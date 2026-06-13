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

from math import fabs, isfinite, isnan, nan
from memory import Pointer
from sys import int_type
from utils import Vector

trait C_monotonic_equation:
    def __call__(self, x: Float64, y: Pointer[Float64]) -> Int32:
        ...

@value
struct C_import_mono_eq(C_monotonic_equation):
    var mf_monotonic_function: Pointer[Int32](Float64, Pointer[Float64])

    def __init__(self, f: Pointer[Int32](Float64, Pointer[Float64])):
        self.mf_monotonic_function = f

    def __del__(self):

    def __call__(self, x: Float64, y: Pointer[Float64]) -> Int32:
        return self.mf_monotonic_function(x, y)

@value
struct C_monotonic_eq_solver:
    struct S_eq_chars:
        var x: Float64
        var y: Float64
        var err_code: Int32

        def __init__(self):
            self.x = nan()
            self.y = nan()
            self.err_code = 0

    struct S_xy_pair:
        var x: Float64
        var y: Float64

        def __init__(self):
            self.x = nan()
            self.y = nan()

    var mf_mono_eq: C_monotonic_equation
    var m_is_pos_bound: Bool
    var m_is_neg_bound: Bool
    var m_is_pos_error: Bool
    var m_is_neg_error: Bool
    var m_is_pos_error_prev: Bool
    var m_is_neg_error_prev: Bool
    var m_x_guess: Float64
    var m_x_neg_err: Float64
    var m_x_pos_err: Float64
    var m_y_err_pos: Float64
    var m_y_err_neg: Float64
    var m_y_err: Float64
    var m_iter: Int32
    var m_E_slope: Float64
    var ms_eq_call_tracker: Vector[S_eq_chars]
    var ms_eq_tracker_temp: S_eq_chars
    var m_func_x_lower: Float64
    var m_func_x_upper: Float64
    var m_tol: Float64
    var m_iter_max: Int32
    var m_is_err_rel: Bool

    enum solver_exit_modes:
        REL_TOL_WITH_0_TARGET = 0
        EQUAL_GUESS_VALUES = 1
        NO_SOLUTION = 2
        CONVERGED = 3
        SLOPE_POS_NO_NEG_ERR = 4
        SLOPE_NEG_NO_NEG_ERR = 5
        SLOPE_POS_NO_POS_ERR = 6
        SLOPE_NEG_NO_POS_ERR = 7
        SLOPE_POS_BOTH_ERRS = 8
        SLOPE_NEG_BOTH_ERRS = 9
        MAX_ITER_SLOPE_POS_NO_NEG_ERR = 10
        MAX_ITER_SLOPE_NEG_NO_NEG_ERR = 11
        MAX_ITER_SLOPE_POS_NO_POS_ERR = 12
        MAX_ITER_SLOPE_NEG_NO_POS_ERR = 13
        MAX_ITER_SLOPE_POS_BOTH_ERRS = 14
        MAX_ITER_SLOPE_NEG_BOTH_ERRS = 15

    def __init__(self, f: C_monotonic_equation):
        self.mf_mono_eq = f
        self.m_x_guess = nan()
        self.m_x_neg_err = nan()
        self.m_x_pos_err = nan()
        self.m_y_err_pos = nan()
        self.m_y_err_neg = nan()
        self.m_y_err = nan()
        self.m_E_slope = nan()
        self.m_func_x_lower = nan()
        self.m_func_x_upper = nan()
        self.m_is_pos_bound = False
        self.m_is_neg_bound = False
        self.m_is_pos_error = False
        self.m_is_neg_error = False
        self.m_is_pos_error_prev = False
        self.m_is_neg_error_prev = False
        self.m_iter = -1
        self.m_tol = 0.001
        self.m_is_err_rel = True
        self.m_iter_max = 50
        self.ms_eq_call_tracker = Vector[S_eq_chars]()
        self.ms_eq_tracker_temp = S_eq_chars()

    def __del__(self):

    def settings(self, tol: Float64, iter_limit: Int32, x_lower: Float64, x_upper: Float64, is_err_rel: Bool):
        self.m_tol = tol
        self.m_func_x_lower = x_lower
        self.m_func_x_upper = x_upper
        self.m_is_err_rel = is_err_rel
        self.m_iter_max = max(1, iter_limit)

    def check_against_limits(self, x: Float64) -> Float64:
        if not isfinite(self.m_func_x_lower) and not isfinite(self.m_func_x_upper):
            return x
        elif not isfinite(self.m_func_x_lower):
            return min(self.m_func_x_upper, x)
        elif not isfinite(self.m_func_x_upper):
            return max(self.m_func_x_lower, x)
        else:
            return min(self.m_func_x_upper, max(x, self.m_func_x_lower))

    def calc_x_intercept(self, x1: Float64, y1: Float64, x2: Float64, y2: Float64) -> Float64:
        return (x2 - x1) / (y2 - y1) * (-y1) + x1

    def solve(self, x_guess_1: Float64, x_guess_2: Float64, y_target: Float64, x_solved: Pointer[Float64], tol_solved: Pointer[Float64], iter_solved: Pointer[Int32]) -> Int32:
        self.ms_eq_call_tracker.resize(0)
        self.ms_eq_call_tracker.reserve(self.m_iter_max)
        x_guess_1 = self.check_against_limits(x_guess_1)
        x_guess_2 = self.check_against_limits(x_guess_2)
        var y1: Float64
        var y2: Float64
        if self.call_mono_eq(x_guess_1, Pointer[Float64].address_of(y1)) != 0:
            y1 = nan()
        if x_guess_1 != x_guess_2:
            if self.call_mono_eq(x_guess_2, Pointer[Float64].address_of(y2)) != 0:
                y2 = nan()
        else:
            y2 = y1
        return self.solver_core(x_guess_1, y1, x_guess_2, y2, y_target, x_solved, tol_solved, iter_solved)

    def solve(self, solved_pair_1: S_xy_pair, x_guess_2: Float64, y_target: Float64, x_solved: Pointer[Float64], tol_solved: Pointer[Float64], iter_solved: Pointer[Int32]) -> Int32:
        self.ms_eq_call_tracker.resize(0)
        self.ms_eq_call_tracker.reserve(self.m_iter_max)
        var x_guess_1: Float64 = solved_pair_1.x
        var y1: Float64 = solved_pair_1.y
        self.ms_eq_tracker_temp.x = x_guess_1
        self.ms_eq_tracker_temp.y = y1
        self.ms_eq_tracker_temp.err_code = 0
        self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
        x_guess_2 = self.check_against_limits(x_guess_2)
        var y2: Float64 = nan()
        self.call_mono_eq(x_guess_2, Pointer[Float64].address_of(y2))
        return self.solver_core(x_guess_1, y1, x_guess_2, y2, y_target, x_solved, tol_solved, iter_solved)

    def solve(self, solved_pair_1: S_xy_pair, solved_pair_2: S_xy_pair, y_target: Float64, x_solved: Pointer[Float64], tol_solved: Pointer[Float64], iter_solved: Pointer[Int32]) -> Int32:
        self.ms_eq_call_tracker.resize(0)
        self.ms_eq_call_tracker.reserve(self.m_iter_max)
        var x_guess_1: Float64 = solved_pair_1.x
        var x_guess_2: Float64 = solved_pair_2.x
        var y1: Float64 = solved_pair_1.y
        var y2: Float64 = solved_pair_2.y
        self.ms_eq_tracker_temp.x = x_guess_1
        self.ms_eq_tracker_temp.y = y1
        self.ms_eq_tracker_temp.err_code = 0
        self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
        self.ms_eq_tracker_temp.x = x_guess_2
        self.ms_eq_tracker_temp.y = y2
        self.ms_eq_tracker_temp.err_code = 0
        self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
        return self.solver_core(x_guess_1, y1, x_guess_2, y2, y_target, x_solved, tol_solved, iter_solved)

    def solve(self, x_solved_vector: Vector[Float64], y_solved_vector: Vector[Float64], y_target: Float64, x_solved: Pointer[Float64], tol_solved: Pointer[Float64], iter_solved: Pointer[Int32]) -> Int32:
        var x_len: Int = x_solved_vector.size()
        var y_len: Int = y_solved_vector.size()
        if x_len != y_len:
            return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
        var i_low: Int32 = -1
        var y_low: Float64 = nan()
        var i_high: Int32 = -1
        var y_high: Float64 = nan()
        for i in range(y_len):
            if isfinite(y_solved_vector[i]) and y_solved_vector[i] <= y_target:
                if (i_low > -1 and y_solved_vector[i] > y_low) or i_low == -1:
                    i_low = i
                    y_low = y_solved_vector[i]
            elif isfinite(y_solved_vector[i]):
                if (i_high > -1 and y_solved_vector[i] < y_high) or i_high == -1:
                    i_high = i
                    y_high = y_solved_vector[i]
        if i_low == -1 and i_high == -1:
            return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
        elif i_low == -1:
            var xy_pair: S_xy_pair
            xy_pair.x = x_solved_vector[i_high]
            xy_pair.y = y_solved_vector[i_high]
            self.ms_eq_tracker_temp.x = xy_pair.x
            self.ms_eq_tracker_temp.y = xy_pair.y
            self.ms_eq_tracker_temp.err_code = 0
            self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
            return self.solve(xy_pair, xy_pair.x * 0.9, y_target, x_solved, tol_solved, iter_solved)
        elif i_high == -1:
            var xy_pair: S_xy_pair
            xy_pair.x = x_solved_vector[i_low]
            xy_pair.y = y_solved_vector[i_low]
            self.ms_eq_tracker_temp.x = xy_pair.x
            self.ms_eq_tracker_temp.y = xy_pair.y
            self.ms_eq_tracker_temp.err_code = 0
            self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
            return self.solve(xy_pair, xy_pair.x * 0.9, y_target, x_solved, tol_solved, iter_solved)
        else:
            var xy_pair1: S_xy_pair
            xy_pair1.x = x_solved_vector[i_high]
            xy_pair1.y = y_solved_vector[i_high]
            self.ms_eq_tracker_temp.x = xy_pair1.x
            self.ms_eq_tracker_temp.y = xy_pair1.y
            self.ms_eq_tracker_temp.err_code = 0
            self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
            var xy_pair2: S_xy_pair
            xy_pair2.x = x_solved_vector[i_low]
            xy_pair2.y = y_solved_vector[i_low]
            self.ms_eq_tracker_temp.x = xy_pair2.x
            self.ms_eq_tracker_temp.y = xy_pair2.y
            self.ms_eq_tracker_temp.err_code = 0
            self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
            return self.solve(xy_pair1, xy_pair2, y_target, x_solved, tol_solved, iter_solved)

    def solver_core(self, x_guess_1: Float64, y1: Float64, x_guess_2: Float64, y2: Float64, y_target: Float64, x_solved: Pointer[Float64], tol_solved: Pointer[Float64], iter_solved: Pointer[Int32]) -> Int32:
        if not isfinite(y1) and not isfinite(y2):
            x_solved[] = nan()
            tol_solved[] = nan()
            iter_solved[] = 0
            return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
        elif not isfinite(y1):
            x_guess_1 = x_guess_2 + (x_guess_2 - x_guess_1)
            x_guess_1 = self.check_against_limits(x_guess_1)
            if x_guess_1 == x_guess_2:
                x_solved[] = nan()
                tol_solved[] = nan()
                iter_solved[] = 0
                return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
            if self.call_mono_eq(x_guess_1, Pointer[Float64].address_of(y1)) != 0:
                y1 = nan()
            if not isfinite(y1):
                x_solved[] = nan()
                tol_solved[] = nan()
                iter_solved[] = 0
                return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
        elif not isfinite(y2):
            x_guess_2 = x_guess_1 + (x_guess_1 - x_guess_2)
            x_guess_2 = self.check_against_limits(x_guess_2)
            if x_guess_1 == x_guess_2:
                x_solved[] = nan()
                tol_solved[] = nan()
                iter_solved[] = 0
                return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
            if self.call_mono_eq(x_guess_2, Pointer[Float64].address_of(y2)) != 0:
                y2 = nan()
            if not isfinite(y2):
                x_solved[] = nan()
                tol_solved[] = nan()
                iter_solved[] = 0
                return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
        var E1: Float64 = y1 - y_target
        var E2: Float64 = y2 - y_target
        if self.m_is_err_rel:
            if y_target == 0:
                return Int32(C_monotonic_eq_solver.solver_exit_modes.REL_TOL_WITH_0_TARGET)
            E1 = E1 / fabs(y_target)
            E2 = E2 / fabs(y_target)
        if fabs(E1) < self.m_tol:
            self.call_mono_eq(x_guess_1, Pointer[Float64].address_of(y1))
            x_solved[] = x_guess_1
            tol_solved[] = E1
            iter_solved[] = 0
            return Int32(C_monotonic_eq_solver.solver_exit_modes.CONVERGED)
        if fabs(E2) < self.m_tol:
            var last_x_tried: Float64 = self.get_last_mono_eq_call().x
            if last_x_tried != x_guess_2 or not isfinite(last_x_tried):
                self.call_mono_eq(x_guess_2, Pointer[Float64].address_of(y2))
            x_solved[] = x_guess_2
            tol_solved[] = E2
            iter_solved[] = 0
            return Int32(C_monotonic_eq_solver.solver_exit_modes.CONVERGED)
        self.m_E_slope = (E2 - E1) / (x_guess_2 - x_guess_1)
        if self.m_E_slope == 0.0 or x_guess_1 == x_guess_2:
            x_solved[] = nan()
            tol_solved[] = nan()
            iter_solved[] = 0
            return Int32(C_monotonic_eq_solver.solver_exit_modes.EQUAL_GUESS_VALUES)
        if E1 > 0.0 and E2 > 0.0:
            self.m_is_pos_bound = True
            self.m_is_pos_error = True
            self.m_is_pos_error_prev = True
            self.m_is_neg_bound = False
            self.m_is_neg_error = False
            self.m_is_neg_error_prev = False
            var x_pos_err_prev: Float64 = nan()
            var y_err_pos_prev: Float64 = nan()
            if E1 < E2:
                self.m_x_pos_err = x_guess_1
                self.m_y_err_pos = E1
                x_pos_err_prev = x_guess_2
                y_err_pos_prev = E2
            else:
                self.m_x_pos_err = x_guess_2
                self.m_y_err_pos = E2
                x_pos_err_prev = x_guess_1
                y_err_pos_prev = E1
            self.m_x_guess = self.calc_x_intercept(self.m_x_pos_err, self.m_y_err_pos, x_pos_err_prev, y_err_pos_prev)
            self.m_x_guess = self.check_against_limits(self.m_x_guess)
        elif E2 < 0.0 and E1 < 0.0:
            self.m_is_neg_bound = True
            self.m_is_neg_error = True
            self.m_is_neg_error_prev = True
            self.m_is_pos_bound = False
            self.m_is_pos_error = False
            self.m_is_pos_error_prev = False
            var x_neg_err_prev: Float64 = nan()
            var y_err_neg_prev: Float64 = nan()
            if E1 < E2:
                self.m_x_neg_err = x_guess_2
                self.m_y_err_neg = E2
                x_neg_err_prev = x_guess_1
                y_err_neg_prev = E1
            else:
                self.m_x_neg_err = x_guess_1
                self.m_y_err_neg = E1
                x_neg_err_prev = x_guess_2
                y_err_neg_prev = E2
            self.m_x_guess = self.calc_x_intercept(self.m_x_neg_err, self.m_y_err_neg, x_neg_err_prev, y_err_neg_prev)
            self.m_x_guess = self.check_against_limits(self.m_x_guess)
        elif E1 > 0.0:
            self.m_is_pos_bound = True
            self.m_is_pos_error = True
            self.m_is_pos_error_prev = False
            self.m_is_neg_bound = True
            self.m_is_neg_error = True
            self.m_is_neg_error_prev = False
            self.m_x_pos_err = x_guess_1
            self.m_y_err_pos = E1
            self.m_x_neg_err = x_guess_2
            self.m_y_err_neg = E2
            self.m_x_guess = self.calc_x_intercept(self.m_x_pos_err, self.m_y_err_pos, self.m_x_neg_err, self.m_y_err_neg)
        else:
            self.m_is_pos_bound = True
            self.m_is_pos_error = True
            self.m_is_pos_error_prev = False
            self.m_is_neg_bound = True
            self.m_is_neg_error = True
            self.m_is_neg_error_prev = False
            self.m_x_pos_err = x_guess_2
            self.m_y_err_pos = E2
            self.m_x_neg_err = x_guess_1
            self.m_y_err_neg = E1
            self.m_x_guess = self.calc_x_intercept(self.m_x_pos_err, self.m_y_err_pos, self.m_x_neg_err, self.m_y_err_neg)
        self.m_y_err = 999.9 * self.m_tol
        self.m_iter = 0
        while fabs(self.m_y_err) > self.m_tol or not isfinite(self.m_y_err):
            self.m_iter += 1
            var diff_x_bounds: Float64 = nan()
            if self.m_E_slope > 0.0:
                if not isfinite(self.m_x_pos_err):
                    diff_x_bounds = self.m_func_x_upper - self.m_x_neg_err
                elif not isfinite(self.m_x_neg_err):
                    diff_x_bounds = self.m_x_pos_err - self.m_func_x_lower
                else:
                    diff_x_bounds = self.m_x_pos_err - self.m_x_neg_err
            else:
                if not isfinite(self.m_x_pos_err):
                    diff_x_bounds = self.m_x_neg_err - self.m_func_x_lower
                elif not isfinite(self.m_x_neg_err):
                    diff_x_bounds = self.m_func_x_upper - self.m_x_pos_err
                else:
                    diff_x_bounds = self.m_x_neg_err - self.m_x_pos_err
            if self.m_is_err_rel:
                if isfinite(self.m_x_neg_err) and isfinite(self.m_x_pos_err):
                    diff_x_bounds = diff_x_bounds / max(self.m_x_neg_err, self.m_x_pos_err)
                elif isfinite(self.m_x_neg_err):
                    diff_x_bounds = diff_x_bounds / self.m_x_neg_err
                elif isfinite(self.m_x_pos_err):
                    diff_x_bounds = diff_x_bounds / self.m_x_pos_err
            if fabs(diff_x_bounds) < self.m_tol / 10.0 and self.m_iter > 1:
                if not self.m_is_neg_error and self.m_is_pos_error:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_pos_err
                        tol_solved[] = self.m_y_err_pos
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_POS_NO_NEG_ERR)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_NEG_NO_NEG_ERR)
                elif self.m_is_neg_error and not self.m_is_pos_error:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_neg_err
                        tol_solved[] = self.m_y_err_neg
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_POS_NO_POS_ERR)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_NEG_NO_POS_ERR)
                else:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_POS_BOTH_ERRS)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_NEG_BOTH_ERRS)
            if self.m_iter > self.m_iter_max:
                if not self.m_is_neg_error and self.m_is_pos_error:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_pos_err
                        tol_solved[] = self.m_y_err_pos
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_POS_NO_NEG_ERR)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_NEG_NO_NEG_ERR)
                elif self.m_is_neg_error and not self.m_is_pos_error:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_neg_err
                        tol_solved[] = self.m_y_err_neg
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_POS_NO_POS_ERR)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_NEG_NO_POS_ERR)
                else:
                    if isfinite(self.m_y_err):
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter - 1
                    else:
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                        iter_solved[] = self.m_iter
                    var x_at_lowest: Float64 = nan()
                    if self.is_last_x_best(Pointer[Float64].address_of(x_at_lowest), y_target):
                        self.m_x_guess = x_at_lowest
                        self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
                        x_solved[] = self.m_x_guess
                        tol_solved[] = self.m_y_err
                    if self.m_E_slope > 0.0:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_POS_BOTH_ERRS)
                    else:
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_NEG_BOTH_ERRS)
            if self.m_iter > 1:
                if not isfinite(self.m_y_err):
                    if not self.m_is_neg_bound and not self.m_is_pos_bound:
                        x_solved[] = nan()
                        tol_solved[] = nan()
                        iter_solved[] = self.m_iter
                        return Int32(C_monotonic_eq_solver.solver_exit_modes.NO_SOLUTION)
                    elif self.m_is_neg_bound and not self.m_is_pos_bound:
                        self.m_x_pos_err = self.m_x_guess
                        self.m_is_pos_bound = True
                        self.m_is_pos_error = False
                        self.m_is_pos_error_prev = False
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    elif not self.m_is_neg_bound and self.m_is_pos_bound:
                        self.m_x_neg_err = self.m_x_guess
                        self.m_is_neg_bound = True
                        self.m_is_neg_error = False
                        self.m_is_neg_error_prev = False
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    elif self.m_is_neg_error and not self.m_is_pos_error:
                        self.m_x_pos_err = self.m_x_guess
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    elif not self.m_is_neg_error and self.m_is_pos_error:
                        self.m_x_neg_err = self.m_x_guess
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    else:
                        var x_min_abs_err: Float64 = self.m_x_pos_err
                        if fabs(self.m_y_err_neg) < fabs(self.m_y_err_pos):
                            x_min_abs_err = self.m_x_neg_err
                        self.m_x_guess = 0.5 * (self.m_x_guess + x_min_abs_err)
                elif self.m_y_err > 0.0:
                    var x_pos_err_prev: Float64 = nan()
                    var y_err_pos_prev: Float64 = nan()
                    if self.m_is_pos_error:
                        if self.m_y_err > self.m_y_err_pos:
                            self.m_is_pos_error_prev = False
                        else:
                            self.m_is_pos_error_prev = True
                            x_pos_err_prev = self.m_x_pos_err
                            y_err_pos_prev = self.m_y_err_pos
                    else:
                        self.m_is_pos_error_prev = False
                    self.m_x_pos_err = self.m_x_guess
                    self.m_y_err_pos = self.m_y_err
                    self.m_is_pos_bound = True
                    self.m_is_pos_error = True
                    if not self.m_is_neg_bound:
                        if self.m_is_pos_error_prev:
                            self.m_x_guess = self.calc_x_intercept(self.m_x_pos_err, self.m_y_err_pos, x_pos_err_prev, y_err_pos_prev)
                        elif self.m_E_slope > 0.0:
                            self.m_x_guess = self.m_x_pos_err - 0.5 * max(x_guess_1, x_guess_2)
                        else:
                            self.m_x_guess = self.m_x_pos_err + 0.5 * max(fabs(x_guess_1), fabs(x_guess_2))
                        self.m_x_guess = self.check_against_limits(self.m_x_guess)
                    elif not self.m_is_neg_error:
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    else:
                        self.m_x_guess = self.calc_x_intercept(self.m_x_neg_err, self.m_y_err_neg, self.m_x_pos_err, self.m_y_err_pos)
                else:
                    var x_neg_err_prev: Float64 = nan()
                    var y_err_neg_prev: Float64 = nan()
                    if self.m_is_neg_error:
                        if self.m_y_err < self.m_y_err_neg:
                            self.m_is_neg_error_prev = False
                        else:
                            self.m_is_neg_error_prev = True
                            x_neg_err_prev = self.m_x_neg_err
                            y_err_neg_prev = self.m_y_err_neg
                    else:
                        self.m_is_pos_error_prev = False
                    self.m_x_neg_err = self.m_x_guess
                    self.m_y_err_neg = self.m_y_err
                    self.m_is_neg_bound = True
                    self.m_is_neg_error = True
                    if not self.m_is_pos_bound:
                        if self.m_is_neg_error_prev:
                            self.m_x_guess = self.calc_x_intercept(self.m_x_neg_err, self.m_y_err_neg, x_neg_err_prev, y_err_neg_prev)
                        elif self.m_E_slope > 0.0:
                            self.m_x_guess = self.m_x_neg_err + 0.5 * max(fabs(x_guess_1), fabs(x_guess_2))
                        else:
                            self.m_x_guess = self.m_x_neg_err - 0.5 * max(x_guess_1, x_guess_2)
                        self.m_x_guess = self.check_against_limits(self.m_x_guess)
                    elif not self.m_is_pos_error:
                        self.m_x_guess = 0.5 * (self.m_x_pos_err + self.m_x_neg_err)
                    else:
                        self.m_x_guess = self.calc_x_intercept(self.m_x_neg_err, self.m_y_err_neg, self.m_x_pos_err, self.m_y_err_pos)
            self.m_y_err = self.call_mono_eq_calc_y_err(self.m_x_guess, y_target)
        x_solved[] = self.m_x_guess
        tol_solved[] = self.m_y_err
        iter_solved[] = self.m_iter
        return Int32(C_monotonic_eq_solver.solver_exit_modes.CONVERGED)

    def call_mono_eq_calc_y_err(self, x: Float64, y_target: Float64) -> Float64:
        var y_calc: Float64
        if self.call_mono_eq(x, Pointer[Float64].address_of(y_calc)) != 0:
            y_calc = nan()
        var y_err: Float64 = y_calc - y_target
        if self.m_is_err_rel:
            y_err = y_err / fabs(y_target)
        return y_err

    def call_mono_eq(self, x: Float64, y: Pointer[Float64]) -> Int32:
        try:
            self.ms_eq_tracker_temp.err_code = self.mf_mono_eq(x, y)
        except:
            y[] = nan()
            self.ms_eq_tracker_temp.err_code = -99
        self.ms_eq_tracker_temp.x = x
        self.ms_eq_tracker_temp.y = y[]
        self.ms_eq_call_tracker.push_back(self.ms_eq_tracker_temp)
        return self.ms_eq_tracker_temp.err_code

    def is_last_x_best(self, x_at_lowest: Pointer[Float64], y_target: Float64) -> Bool:
        var s_eq_chars_min_abs_diff: S_eq_chars
        var is_use_last_x: Bool = False
        x_at_lowest[] = nan()
        if self.get_min_abs_diff_no_err(Pointer[S_eq_chars].address_of(s_eq_chars_min_abs_diff), y_target):
            var y_err: Float64 = s_eq_chars_min_abs_diff.y - y_target
            if self.m_is_err_rel:
                y_err = y_err / fabs(y_target)
            var min_abs_diff: Float64 = fabs(y_err)
            if min_abs_diff < fabs(self.m_y_err) or not isfinite(self.m_y_err):
                x_at_lowest[] = s_eq_chars_min_abs_diff.x
                is_use_last_x = True
        return is_use_last_x

    def get_min_abs_diff_no_err(self, s_eq_chars_min_abs_diff: Pointer[S_eq_chars], y_target: Float64) -> Bool:
        var len: Int = self.ms_eq_call_tracker.size()
        if len == 0:
            return False
        var is_found_min: Bool = False
        var min_abs_diff: Float64 = nan()
        var y_err: Float64 = nan()
        for i in range(len):
            var i_ms_eq: S_eq_chars = self.ms_eq_call_tracker[i]
            if i_ms_eq.err_code == 0 and isfinite(i_ms_eq.y):
                y_err = fabs(i_ms_eq.y - y_target)
                if self.m_is_err_rel:
                    y_err = y_err / fabs(y_target)
                if is_found_min and y_err < min_abs_diff:
                    min_abs_diff = y_err
                    s_eq_chars_min_abs_diff[] = i_ms_eq
                elif not is_found_min:
                    min_abs_diff = y_err
                    is_found_min = True
                    s_eq_chars_min_abs_diff[] = i_ms_eq
        return is_found_min

    def get_last_mono_eq_call(self) -> S_eq_chars:
        var len: Int = self.ms_eq_call_tracker.size()
        if len == 0:
            var s_null: S_eq_chars
            return s_null
        else:
            return self.ms_eq_call_tracker[len - 1]

    def test_member_function(self, x: Float64, y: Pointer[Float64]) -> Int32:
        return self.mf_mono_eq(x, y)

    def did_solver_find_negative_error(self, solver_exit_mode: Int32) -> Bool:
        if solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_POS_NO_NEG_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_NEG_NO_NEG_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_NEG_NO_NEG_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_POS_NO_NEG_ERR):
            return False
        return True

    def did_solver_find_positive_error(self, solver_exit_mode: Int32) -> Bool:
        if solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_POS_NO_POS_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.SLOPE_NEG_NO_POS_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_NEG_NO_POS_ERR) or solver_exit_mode == Int32(C_monotonic_eq_solver.solver_exit_modes.MAX_ITER_SLOPE_POS_NO_POS_ERR):
            return False
        return True

    def get_E_slope(self) -> Float64:
        return self.m_E_slope