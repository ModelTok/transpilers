// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from core import *
from lsqfit import *
from util import *
import sys

// Types
alias ssc_number_t = Float64

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

alias var_info_invalid = var_info(0, 0, "", "", "", "", "", "", "", "")

// Constants for vartype and datatype
alias SSC_INPUT = 0
alias SSC_OUTPUT = 1
alias SSC_NUMBER = 0
alias SSC_MATRIX = 1
alias SSC_ARRAY = 2
alias INTEGER = 0
alias MIN = 0
alias MAX = 1

// matrix_t wrapper
struct matrix_t[T: AnyType]:
    var data: DynamicVector[T]
    var nrows: Int
    var ncols: Int

    def __init__(inout self, nrows: Int, ncols: Int):
        self.nrows = nrows
        self.ncols = ncols
        self.data = DynamicVector[T](nrows * ncols)

    def __init__(inout self, ref other: Self):
        self.nrows = other.nrows
        self.ncols = other.ncols
        self.data = DynamiVector[T](other.data)

    def assign(inout self, ptr: DTypePointer[T], rows: Int, cols: Int):
        self.nrows = rows
        self.ncols = cols
        self.data = DynamicVector[T](rows * cols)
        for i in range(rows * cols):
            self.data[i] = ptr[i]

    def at(inout self, row: Int, col: Int) -> T:
        return self.data[row * self.ncols + col]

    def at(inout self, row: Int, col: Int) -> ref[T]:
        return self.data[row * self.ncols + col]

    def nrows(self) -> Int:
        return self.nrows

    def ncols(self) -> Int:
        return self.ncols

// Global variable table
var vtab_inv_cec_cg: StaticArray[var_info, 27+1] = StaticArray[
    var_info(SSC_INPUT, SSC_NUMBER, "inv_cec_cg_paco", "Rated max output", "W", "", "", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "inv_cec_cg_sample_power_units", "Sample data units for power output", "0=W,1=kW", "", "", "?=0", "INTEGER,MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_MATRIX, "inv_cec_cg_test_samples", "Sample data", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_MATRIX, "inv_cec_cg_Vmin", "Vmin for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_MATRIX, "inv_cec_cg_Vnom", "Vnom for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_MATRIX, "inv_cec_cg_Vmax", "Vmax for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Vmin_abc", "Vmin a,b,c for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Vnom_abc", "Vnom a,b,c for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Vmax_abc", "Vmax a,b,c for least squares fit", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Vdc", "Vdc at Vmin, Vnom, Vmax", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Vdc_Vnom", "Vdc - Vnom at Vmin, Vnom, Vmax", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Pdco", "Pdco at Vmin, Vnom, Vmax", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_Psco", "Psco at Vmin, Vnom, Vmax", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_C0", "C0 at Vmin, Vnom, Vmax", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_C1", "C1 at m and b", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_C2", "C1 at m and b", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "inv_cec_cg_C3", "C1 at m and b", "", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "Pdco", "CEC generated Pdco", "Wac", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "Vdco", "CEC generated Vdco", "Vdc", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "Pso", "CEC generated Pso", "Wdc", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c0", "CEC generated c0", "1/W", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c1", "CEC generated c1", "1/V", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c2", "CEC generated c2", "1/V", "", "", "*", "", ""),
    var_info(SSC_OUTPUT, SSC_NUMBER, "c3", "CEC generated c3", "1/V", "", "", "*", "", ""),
    var_info_invalid
]

def Quadratic_fit_eqn(_x: Float64, par: DTypePointer[Float64], _: None) -> Float64:
    return par[0] * _x * _x + par[1] * _x + par[2]

def Linear_fit_eqn(_x: Float64, par: DTypePointer[Float64], _: None) -> Float64:
    return par[0] * _x + par[1]

class cm_inv_cec_cg(compute_module):
    def __init__(inout self):
        self.add_var_info(vtab_inv_cec_cg)

    def exec(inout self):
        var i: Int
        var j: Int
        var nrows: Int
        var ncols: Int
        var Paco: Float64 = self.as_double("inv_cec_cg_paco")
        var kW_units: Bool = (self.as_integer("inv_cec_cg_sample_power_units") == 1)
        var inv_cec_cg_test_samples_in: DTypePointer[ssc_number_t] = self.as_matrix("inv_cec_cg_test_samples", nrows, ncols)
        if nrows != 18:
            var ss: String = String("The samples table must have 18 rows. Number of rows in samples table provided is ") + String(nrows) + String(" rows.")
            throw exec_error("inv_cec_cg", ss)
        if (ncols % 3) != 0:
            var ss: String = String("The samples table must have number of columns divisible by 3. Number of columns in samples table provided is ") + String(ncols) + String(" columns.")
            throw exec_error("inv_cec_cg", ss)
        var num_samples: Int = ncols / 3
        var columns_per_sample: Int = 3
        var inv_cec_cg_test_samples = matrix_t[ssc_number_t](nrows, ncols)
        inv_cec_cg_test_samples.assign(inv_cec_cg_test_samples_in, nrows, ncols)
        var vdc: ssc_number_t = 0
        var Pout: ssc_number_t = 0
        var eff: ssc_number_t = 0
        var Pin: ssc_number_t = 0
        var Pin2: ssc_number_t = 0
        var inv_cec_cg_Vmin: ref[matrix_t[ssc_number_t]] = self.allocate_matrix("inv_cec_cg_Vmin", 6 * num_samples, 3)
        var inv_cec_cg_Vnom: ref[matrix_t[ssc_number_t]] = self.allocate_matrix("inv_cec_cg_Vnom", 6 * num_samples, 3)
        var inv_cec_cg_Vmax: ref[matrix_t[ssc_number_t]] = self.allocate_matrix("inv_cec_cg_Vmax", 6 * num_samples, 3)
        var inv_cec_cg_Vdc: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Vdc", 3)
        var inv_cec_cg_Vdc_Vnom: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Vdc_Vnom", 3)
        var inv_cec_cg_Pdco: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Pdco", 3)
        var inv_cec_cg_Psco: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Psco", 3)
        var inv_cec_cg_C0: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_C0", 3)
        var inv_cec_cg_C1: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_C1", 2)
        var inv_cec_cg_C2: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_C2", 2)
        var inv_cec_cg_C3: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_C3", 2)
        for i in range(3):
            inv_cec_cg_Vdc[i] = 0
        for j in range(num_samples):
            for i in range(inv_cec_cg_test_samples.nrows()):
                vdc = inv_cec_cg_test_samples.at(i, j * columns_per_sample + 1)
                Pout = inv_cec_cg_test_samples.at(i, j * columns_per_sample)
                if kW_units: Pout *= 1000 // kW to W
                eff = inv_cec_cg_test_samples.at(i, j * columns_per_sample + 2)
                Pin = Pout
                if eff != 0.0:
                    Pin = ssc_number_t(100.0 * Pout) / eff
                Pin2 = Pin * Pin
                if i < 6: // Vmin 0 offset
                    inv_cec_cg_Vdc[0] += vdc
                    inv_cec_cg_Vmin.at(j * 6 + i, 0) = Pout
                    inv_cec_cg_Vmin.at(j * 6 + i, 1) = Pin
                    inv_cec_cg_Vmin.at(j * 6 + i, 2) = Pin2
                else if i < 12: // Vnom 6 offset
                    inv_cec_cg_Vdc[1] += vdc
                    inv_cec_cg_Vnom.at(j * 6 + i - 6, 0) = Pout
                    inv_cec_cg_Vnom.at(j * 6 + i - 6, 1) = Pin
                    inv_cec_cg_Vnom.at(j * 6 + i - 6, 2) = Pin2
                else: // Vmax 12 offset
                    inv_cec_cg_Vdc[2] += vdc
                    inv_cec_cg_Vmax.at(j * 6 + i - 12, 0) = Pout
                    inv_cec_cg_Vmax.at(j * 6 + i - 12, 1) = Pin
                    inv_cec_cg_Vmax.at(j * 6 + i - 12, 2) = Pin2
        var inv_cec_cg_Vmin_abc: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Vmin_abc", 3)
        var inv_cec_cg_Vnom_abc: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Vnom_abc", 3)
        var inv_cec_cg_Vmax_abc: DTypePointer[ssc_number_t] = self.allocate("inv_cec_cg_Vmax_abc", 3)
        var Pout_vec = DynamicVector[Float64](inv_cec_cg_Vmin.nrows())
        var Pin_vec = DynamicVector[Float64](inv_cec_cg_Vmin.nrows())
        var info: Int
        var C = DynamicVector[Float64](3) // initial guesses for lsqfit
        var data_size: Int = 3
        for i in range(inv_cec_cg_Vmin.nrows()):
            Pin_vec[i] = inv_cec_cg_Vmin.at(i, 1)
            Pout_vec[i] = inv_cec_cg_Vmin.at(i, 0)
        C[0] = -1e-6
        C[1] = 1
        C[2] = 1e3
        info = lsqfit(Quadratic_fit_eqn, None, C.data, data_size, Pin_vec.data, Pout_vec.data, inv_cec_cg_Vmin.nrows())
        if not info:
            throw exec_error("inv_cec_cg", util.format("error in nonlinear least squares fit, error %d", info))
            return
        inv_cec_cg_Vmin_abc[0] = ssc_number_t(C[0])
        inv_cec_cg_Vmin_abc[1] = ssc_number_t(C[1])
        inv_cec_cg_Vmin_abc[2] = ssc_number_t(C[2])
        for i in range(inv_cec_cg_Vnom.nrows()):
            Pin_vec[i] = inv_cec_cg_Vnom.at(i, 1)
            Pout_vec[i] = inv_cec_cg_Vnom.at(i, 0)
        C[0] = -1e-6
        C[1] = 1
        C[2] = 1e3
        info = lsqfit(Quadratic_fit_eqn, None, C.data, data_size, Pin_vec.data, Pout_vec.data, inv_cec_cg_Vnom.nrows())
        if not info:
            throw exec_error("inv_cec_cg", util.format("error in nonlinear least squares fit, error %d", info))
            return
        inv_cec_cg_Vnom_abc[0] = ssc_number_t(C[0])
        inv_cec_cg_Vnom_abc[1] = ssc_number_t(C[1])
        inv_cec_cg_Vnom_abc[2] = ssc_number_t(C[2])
        for i in range(inv_cec_cg_Vmax.nrows()):
            Pin_vec[i] = inv_cec_cg_Vmax.at(i, 1)
            Pout_vec[i] = inv_cec_cg_Vmax.at(i, 0)
        C[0] = -1e-6
        C[1] = 1
        C[2] = 1e3
        info = lsqfit(Quadratic_fit_eqn, None, C.data, data_size, Pin_vec.data, Pout_vec.data, inv_cec_cg_Vmax.nrows())
        if not info:
            throw exec_error("inv_cec_cg", util.format("error in nonlinear least squares fit, error %d", info))
            return
        inv_cec_cg_Vmax_abc[0] = ssc_number_t(C[0])
        inv_cec_cg_Vmax_abc[1] = ssc_number_t(C[1])
        inv_cec_cg_Vmax_abc[2] = ssc_number_t(C[2])
        for i in range(3):
            inv_cec_cg_Vdc[i] /= (6 * num_samples)
        for i in range(3):
            inv_cec_cg_Vdc_Vnom[i] = inv_cec_cg_Vdc[i] - inv_cec_cg_Vdc[1]
        var a: ssc_number_t
        var b: ssc_number_t
        var c: ssc_number_t
        a = inv_cec_cg_Vmin_abc[0]
        b = inv_cec_cg_Vmin_abc[1]
        c = inv_cec_cg_Vmin_abc[2]
        inv_cec_cg_Pdco[0] = ssc_number_t(-b + sqrt(b*b - 4 * a * (c - Paco)))
        inv_cec_cg_Psco[0] = ssc_number_t(-b + sqrt(b*b - 4 * a * c))
        inv_cec_cg_C0[0] = a
        if a != 0:
            inv_cec_cg_Pdco[0] /= ssc_number_t(2.0 * a)
            inv_cec_cg_Psco[0] /= ssc_number_t(2.0 * a)
        a = inv_cec_cg_Vnom_abc[0]
        b = inv_cec_cg_Vnom_abc[1]
        c = inv_cec_cg_Vnom_abc[2]
        inv_cec_cg_Pdco[1] = ssc_number_t(-b + sqrt(b*b - 4 * a * (c - Paco)))
        inv_cec_cg_Psco[1] = ssc_number_t(-b + sqrt(b*b - 4 * a * c))
        inv_cec_cg_C0[1] = a
        if a != 0:
            inv_cec_cg_Pdco[1] /= ssc_number_t(2.0 * a)
            inv_cec_cg_Psco[1] /= ssc_number_t(2.0 * a)
        a = inv_cec_cg_Vmax_abc[0]
        b = inv_cec_cg_Vmax_abc[1]
        c = inv_cec_cg_Vmax_abc[2]
        inv_cec_cg_Pdco[2] = ssc_number_t(-b + sqrt(b*b - 4 * a * (c - Paco)))
        inv_cec_cg_Psco[2] = ssc_number_t(-b + sqrt(b*b - 4 * a * c))
        inv_cec_cg_C0[2] = a
        if a != 0:
            inv_cec_cg_Pdco[2] /= ssc_number_t(2.0 * a)
            inv_cec_cg_Psco[2] /= ssc_number_t(2.0 * a)
        var X = DynamicVector[Float64](3)
        var Y = DynamicVector[Float64](3)
        var slope: Float64
        var intercept: Float64
        for i in range(3):
            X[i] = inv_cec_cg_Vdc_Vnom[i]
            Y[i] = inv_cec_cg_Pdco[i]
        info = linlsqfit(slope, intercept, X.data, Y.data, data_size)
        if info:
            throw exec_error("inv_cec_cg", util.format("error in linear least squares fit, error %d", info))
            return
        inv_cec_cg_C1[0] = ssc_number_t(slope)
        inv_cec_cg_C1[1] = ssc_number_t(intercept)
        for i in range(3):
            X[i] = inv_cec_cg_Vdc_Vnom[i]
            Y[i] = inv_cec_cg_Psco[i]
        info = linlsqfit(slope, intercept, X.data, Y.data, data_size)
        if info:
            throw exec_error("inv_cec_cg", util.format("error in linear least squares fit, error %d", info))
            return
        inv_cec_cg_C2[0] = ssc_number_t(slope)
        inv_cec_cg_C2[1] = ssc_number_t(intercept)
        for i in range(3):
            X[i] = inv_cec_cg_Vdc_Vnom[i]
            Y[i] = inv_cec_cg_C0[i]
        info = linlsqfit(slope, intercept, X.data, Y.data, data_size)
        if info:
            throw exec_error("inv_cec_cg", util.format("error in linear least squares fit, error %d", info))
            return
        inv_cec_cg_C3[0] = ssc_number_t(slope)
        inv_cec_cg_C3[1] = ssc_number_t(intercept)
        self.assign("Pdco", var_data(inv_cec_cg_C1[1]))
        self.assign("Vdco", var_data(inv_cec_cg_Vdc[1]))
        self.assign("Pso", var_data(inv_cec_cg_C2[1]))
        self.assign("c0", var_data(inv_cec_cg_C3[1]))
        self.assign("c1", var_data(inv_cec_cg_C1[0] / inv_cec_cg_C1[1]))
        self.assign("c2", var_data(inv_cec_cg_C2[0] / inv_cec_cg_C2[1]))
        self.assign("c3", var_data(inv_cec_cg_C3[0] / inv_cec_cg_C3[1]))

def DEFINE_MODULE_ENTRY(name: String, label: String, version: Int):

DEFINE_MODULE_ENTRY("inv_cec_cg", "CEC Inverter Coefficient Generator", 1)