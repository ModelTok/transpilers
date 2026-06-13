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
from ..shared.lib_util import util
from math import pow, sqrt, fabs
from algorithm import min, max
from vector import DynamicVector
from string import String
from utils import format as util_format

struct Linear_Interp:
    var m_cor: Bool
    var m_error_msg: String
    var m_userTable: util.matrix_t[Float64]
    var m_rows: Int
    var m_lastIndex: Int
    var m_dj: Int
    var m_m: Int = 2

    def __init__(inout self):
        self.m_cor = False
        self.m_error_msg = String("")
        self.m_userTable = util.matrix_t[Float64]()
        self.m_rows = 0
        self.m_lastIndex = 0
        self.m_dj = 0

    def Set_1D_Lookup_Table(inout self, table: util.matrix_t[Float64], ind_var_index: Pointer[Int], n_ind_var: Int, error_index: Pointer[Int]) -> Bool:
        if table.nrows() < 3:
            error_index[] = -1
            return False
        for i in range(n_ind_var):
            for r in range(1, table.nrows()):
                if table.at(r, ind_var_index[i]) < table.at(r-1, ind_var_index[i]):
                    error_index[] = i
                    return False
        self.m_userTable = table
        self.m_rows = table.nrows()
        self.m_lastIndex = self.m_rows * 2
        self.m_dj = min(1, int(pow(self.m_rows, 0.25)))
        self.m_cor = False
        return True

    def linear_1D_interp(self, x_col: Int, y_col: Int, x: Float64) -> Float64:
        var j: Int = self.Get_Index(x_col, x)
        var y: Float64 = self.m_userTable.at(j, y_col) + ((x - self.m_userTable.at(j, x_col)) / (self.m_userTable.at(j+1, x_col) - self.m_userTable.at(j, x_col))) * (self.m_userTable.at(j+1, y_col) - self.m_userTable.at(j, y_col))
        return y

    def interpolate_x_col_0(self, y_col: Int, x_val: Float64) -> Float64:
        return self.linear_1D_interp(0, y_col, x_val)

    def Get_Index(self, x_col: Int, x: Float64) -> Int:
        var j: Int
        if self.m_cor:
            j = self.hunt(x_col, x)
        else:
            j = self.locate(x_col, x)
        return j

    def Get_Value(self, col: Int, index: Int) -> Float64:
        return self.m_userTable.at(index, col)

    def get_min_x_value_x_col_0(self) -> Float64:
        var index: Int = 0
        return self.Get_Value(0, index)

    def get_max_x_value_x_col_0(self) -> Float64:
        var index: Int = self.m_rows - 1
        return self.Get_Value(0, index)

    def get_column_data(self, col: Int) -> DynamicVector[Float64]:
        var mt_col: util.matrix_t[Float64] = self.m_userTable.col(col)
        var n_cols: Int = mt_col.ncols()
        var v_col = DynamicVector[Float64](n_cols)
        for i in range(n_cols):
            v_col[i] = mt_col[i]
        return v_col

    def check_x_value_x_col_0(inout self, x_val: Float64) -> Bool:
        var min_val: Float64 = self.get_min_x_value_x_col_0()
        var max_val: Float64 = self.get_max_x_value_x_col_0()
        if x_val < min_val:
            self.m_error_msg = util.format("The minimum value is %lg", min_val)
            return False
        if x_val > max_val:
            self.m_error_msg = util.format("The maximum value is %lg", max_val)
            return False
        return True

    def locate(self, col: Int, x: Float64) -> Int:
        var ju: Int, jm: Int, jl: Int
        jl = 0
        ju = self.m_rows - 1
        while ju - jl > 1:
            jm = (ju + jl) // 2
            if x >= self.m_userTable.at(jm, col):
                jl = jm
            else:
                ju = jm
        if abs(jl - self.m_lastIndex) > self.m_dj:
            self.m_cor = False
        else:
            self.m_cor = True
        self.m_lastIndex = jl
        return max(0, min(self.m_rows - self.m_m, jl - ((self.m_m - 2) // 2)))

    def hunt(self, col: Int, x: Float64) -> Int:
        var jl: Int = self.m_lastIndex, jm: Int, ju: Int, inc: Int = 1
        if jl < 0 or jl > self.m_rows - 1:
            jl = 0
            ju = self.m_rows - 1
        else:
            if x >= self.m_userTable.at(jl, col):
                ju = jl + inc
                while ju < self.m_rows - 1 and x > self.m_userTable.at(ju, col):
                    jl = ju
                    inc += inc
                    ju = jl + inc
            else:
                ju = jl
                jl = ju - inc
                while jl > 0 and x < self.m_userTable.at(jl, col):
                    ju = jl
                    inc += inc
                    jl = ju - inc
        if ju > self.m_rows - 1:
            ju = self.m_rows - 1
        if jl < 0:
            jl = 0
        while ju - jl > 1:
            jm = (ju + jl) // 2
            if x >= self.m_userTable.at(jm, col):
                jl = jm
            else:
                ju = jm
        if abs(jl - self.m_lastIndex) > self.m_dj:
            self.m_cor = False
        else:
            self.m_cor = True
        self.m_lastIndex = jl
        return max(0, min(self.m_rows - self.m_m, jl - ((self.m_m - 2) // 2)))

    def get_error_msg(self) -> String:
        return self.m_error_msg

    def get_number_of_rows(self) -> Int:
        return self.m_rows

struct Bilinear_Interp:
    var m_2axis_table: util.matrix_t[Float64]
    var m_nx: Int
    var m_ny: Int
    var x_vals: Linear_Interp
    var y_vals: Linear_Interp

    def __init__(inout self):
        self.m_2axis_table = util.matrix_t[Float64]()
        self.m_nx = 0
        self.m_ny = 0
        self.x_vals = Linear_Interp()
        self.y_vals = Linear_Interp()

    def bilinear_2D_interp(self, x: Float64, y: Float64) -> Float64:
        var i_x1: Int = self.x_vals.Get_Index(0, x)
        var i_y1: Int = self.y_vals.Get_Index(0, y)
        var i_x2: Int = i_x1 + 1
        var i_y2: Int = i_y1 + 1
        var i1: Int = self.m_nx * i_y1 + i_x1
        var x1: Float64 = self.m_2axis_table.at(i1, 0)
        var y1: Float64 = self.m_2axis_table.at(i1, 1)
        var z1: Float64 = self.m_2axis_table.at(i1, 2)
        var i2: Int = self.m_nx * i_y2 + i_x1
        var x2: Float64 = self.m_2axis_table.at(i2, 0)
        var y2: Float64 = self.m_2axis_table.at(i2, 1)
        var z2: Float64 = self.m_2axis_table.at(i2, 2)
        var i3: Int = self.m_nx * i_y2 + i_x2
        var x3: Float64 = self.m_2axis_table.at(i3, 0)
        var y3: Float64 = self.m_2axis_table.at(i3, 1)
        var z3: Float64 = self.m_2axis_table.at(i3, 2)
        var i4: Int = self.m_nx * i_y1 + i_x2
        var x4: Float64 = self.m_2axis_table.at(i4, 0)
        var y4: Float64 = self.m_2axis_table.at(i4, 1)
        var z4: Float64 = self.m_2axis_table.at(i4, 2)
        var x_frac: Float64 = (x - x1) / (x4 - x1)
        var y_frac: Float64 = (y - y1) / (y2 - y1)
        return (1.0 - x_frac) * (1.0 - y_frac) * z1 + (1.0 - x_frac) * y_frac * z2 + x_frac * y_frac * z3 + x_frac * (1.0 - y_frac) * z4

    def Set_2D_Lookup_Table(inout self, table: util.matrix_t[Float64]) -> Bool:
        self.m_2axis_table = table
        var nrows: Int = table.nrows()
        if nrows < 9:
            return False
        var first_val: Float64 = table.at(0, 0)
        var i: Int
        for i in range(1, table.nrows()):
            if table.at(i, 0) == first_val:
                break
        self.m_nx = i
        if self.m_nx < 3:
            return False
        self.m_ny = 1
        i = 0
        for j in range(nrows - 1):
            if table.at(j+1, 1) != table.at(j, 1):
                self.m_ny += 1
        if self.m_ny < 3:
            return False
        var x_matrix = util.matrix_t[Float64](self.m_nx, 1, 0.0)
        for j in range(self.m_nx):
            x_matrix.at(j, 0) = table.at(j, 0)
        var y_matrix = util.matrix_t[Float64](self.m_ny, 1, 0.0)
        for j in range(self.m_ny):
            y_matrix.at(j, 0) = table.at(self.m_nx * j, 1)
        var ind_var_index = Pointer[Int].alloc(1)
        ind_var_index[0] = 0
        var error_index = Pointer[Int].alloc(1)
        error_index[] = -99
        if not self.x_vals.Set_1D_Lookup_Table(x_matrix, ind_var_index, 1, error_index):
            return False
        if not self.y_vals.Set_1D_Lookup_Table(y_matrix, ind_var_index, 1, error_index):
            return False
        return True

struct Trilinear_Interp:
    var m_3axis_table: util.block_t[Float64]
    var m_nx: Int
    var m_ny: Int
    var m_nz: Int
    var x_vals: Linear_Interp
    var y_vals: Linear_Interp
    var z_vals: Linear_Interp

    def __init__(inout self):
        self.m_3axis_table = util.block_t[Float64]()
        self.m_nx = 0
        self.m_ny = 0
        self.m_nz = 0
        self.x_vals = Linear_Interp()
        self.y_vals = Linear_Interp()
        self.z_vals = Linear_Interp()

    def Set_3D_Lookup_Table(inout self, table: util.block_t[Float64]) -> Bool:
        self.m_3axis_table = table
        var nrows: Int = table.nrows()
        var nlayers: Int = table.nlayers()
        if nrows < 9 or nlayers < 3:
            return False
        var first_val: Float64 = table.at(0, 0, 0)
        var i: Int
        for i in range(1, table.nrows()):
            if table.at(i, 0, 0) == first_val:
                break
        self.m_nx = i
        if self.m_nx < 3:
            return False
        self.m_ny = 1
        i = 0
        for j in range(nrows - 1):
            if table.at(j+1, 1, 0) != table.at(j, 1, 0):
                self.m_ny += 1
        if self.m_ny < 3:
            return False
        self.m_nz = nlayers
        var x_matrix = util.matrix_t[Float64](self.m_nx, 1, 0.0)
        for j in range(self.m_nx):
            x_matrix.at(j, 0) = table.at(j, 0, 0)
        var y_matrix = util.matrix_t[Float64](self.m_ny, 1, 0.0)
        for j in range(self.m_ny):
            y_matrix.at(j, 0) = table.at(self.m_nx * j, 1, 0)
        var z_matrix = util.matrix_t[Float64](self.m_nz, 1, 0.0)
        for j in range(self.m_nz):
            z_matrix.at(j, 0) = table.at(0, 2, j)
        var ind_var_index = Pointer[Int].alloc(1)
        ind_var_index[0] = 0
        var error_index = Pointer[Int].alloc(1)
        error_index[] = -99
        if not self.x_vals.Set_1D_Lookup_Table(x_matrix, ind_var_index, 1, error_index):
            return False
        if not self.y_vals.Set_1D_Lookup_Table(y_matrix, ind_var_index, 1, error_index):
            return False
        if not self.z_vals.Set_1D_Lookup_Table(z_matrix, ind_var_index, 1, error_index):
            return False
        return True

    def trilinear_3D_interp(self, x: Float64, y: Float64, z: Float64) -> Float64:
        var i_x1: Int = self.x_vals.Get_Index(0, x)
        var i_y1: Int = self.y_vals.Get_Index(0, y)
        var i_z1: Int = self.z_vals.Get_Index(0, z)
        var i_x2: Int = i_x1 + 1
        var i_y2: Int = i_y1 + 1
        var i_z2: Int = i_z1 + 1
        var i1: Int = self.m_nx * i_y1 + i_x1
        var x1: Float64 = self.m_3axis_table.at(i1, 0, i_z1)
        var y1: Float64 = self.m_3axis_table.at(i1, 1, i_z1)
        var p1: Float64 = self.m_3axis_table.at(i1, 3, i_z1)
        var q1: Float64 = self.m_3axis_table.at(i1, 3, i_z2)
        var i2: Int = self.m_nx * i_y2 + i_x1
        var x2: Float64 = self.m_3axis_table.at(i2, 0, i_z1)
        var y2: Float64 = self.m_3axis_table.at(i2, 1, i_z1)
        var p2: Float64 = self.m_3axis_table.at(i2, 3, i_z1)
        var q2: Float64 = self.m_3axis_table.at(i2, 3, i_z2)
        var i3: Int = self.m_nx * i_y2 + i_x2
        var x3: Float64 = self.m_3axis_table.at(i3, 0, i_z1)
        var y3: Float64 = self.m_3axis_table.at(i3, 1, i_z1)
        var p3: Float64 = self.m_3axis_table.at(i3, 3, i_z1)
        var q3: Float64 = self.m_3axis_table.at(i3, 3, i_z2)
        var i4: Int = self.m_nx * i_y1 + i_x2
        var x4: Float64 = self.m_3axis_table.at(i4, 0, i_z1)
        var y4: Float64 = self.m_3axis_table.at(i4, 1, i_z1)
        var p4: Float64 = self.m_3axis_table.at(i4, 3, i_z1)
        var q4: Float64 = self.m_3axis_table.at(i4, 3, i_z2)
        var z1: Float64 = self.m_3axis_table.at(0, 2, i_z1)
        var z2: Float64 = self.m_3axis_table.at(0, 2, i_z2)
        var x_frac: Float64 = (x - x1) / (x4 - x1)
        var y_frac: Float64 = (y - y1) / (y2 - y1)
        var z_frac: Float64 = (z - z1) / (z2 - z1)
        if z2 - z1 == 0.0:
            z_frac = 1.0
        var m1: Float64 = (1.0 - x_frac) * (1.0 - y_frac)
        var m2: Float64 = (1.0 - x_frac) * y_frac
        var m3: Float64 = x_frac * y_frac
        var m4: Float64 = x_frac * (1.0 - y_frac)
        return (m1 * p1 + m2 * p2 + m3 * p3 + m4 * p4) * z_frac + (m1 * q1 + m2 * q2 + m3 * q3 + m4 * q4) * (1.0 - z_frac)

typealias VectDoub = DynamicVector[Float64]
typealias MatDoub = DynamicVector[DynamicVector[Float64]]

struct LUdcmp:
    var n: Int
    var lu: MatDoub
    var aref: MatDoub
    var indx: DynamicVector[Int]
    var d: Float64

    def __init__(inout self, a: MatDoub):
        self.n = a.size()
        self.lu = a
        self.aref = a
        self.indx = DynamicVector[Int](self.n)
        var TINY: Float64 = 1.0e-40
        var i: Int, imax: Int, j: Int, k: Int
        var big: Float64, temp: Float64
        var vv = VectDoub(self.n)
        self.d = 1.0
        for i in range(self.n):
            big = 0.0
            for j in range(self.n):
                temp = fabs(self.lu.at(i).at(j))
                if temp > big:
                    big = temp
            if big == 0.0:
                raise Error("Singular matrix in LUdcmp")
            vv[i] = 1.0 / big
        for k in range(self.n):
            big = 0.0
            for i in range(k, self.n):
                temp = vv[i] * fabs(self.lu.at(i).at(k))
                if temp > big:
                    big = temp
                    imax = i
            if k != imax:
                for j in range(self.n):
                    temp = self.lu.at(imax).at(j)
                    self.lu.at(imax).at(j) = self.lu.at(k).at(j)
                    self.lu.at(k).at(j) = temp
                self.d = -self.d
                vv[imax] = vv[k]
            self.indx[k] = imax
            if self.lu.at(k).at(k) == 0.0:
                self.lu.at(k).at(k) = TINY
            for i in range(k+1, self.n):
                temp = self.lu.at(i).at(k) / self.lu.at(k).at(k)
                self.lu.at(i).at(k) = temp
                for j in range(k+1, self.n):
                    self.lu.at(i).at(j) -= temp * self.lu.at(k).at(j)

    def solve(inout self, b: VectDoub, x: VectDoub):
        var i: Int, ii: Int = 0, ip: Int, j: Int
        var sum: Float64
        if b.size() != self.n or x.size() != self.n:
            raise Error("LUdcmp::solve bad sizes")
        for i in range(self.n):
            x[i] = b[i]
        for i in range(self.n):
            ip = self.indx[i]
            sum = x[ip]
            x[ip] = x[i]
            if ii != 0:
                for j in range(ii-1, i):
                    sum -= self.lu.at(i).at(j) * x[j]
            elif sum != 0.0:
                ii = i + 1
            x[i] = sum
        for i in range(self.n-1, -1, -1):
            sum = x[i]
            for j in range(i+1, self.n):
                sum -= self.lu.at(i).at(j) * x[j]
            x[i] = sum / self.lu.at(i).at(i)

    def solve_mat(inout self, b: MatDoub, x: MatDoub):
        var i: Int, j: Int, m: Int = b.front().size()
        if b.size() != self.n or x.size() != self.n or b.front().size() != x.front().size():
            raise Error("LUdcmp::solve bad sizes")
        var xx = VectDoub(self.n)
        for j in range(m):
            for i in range(self.n):
                xx[i] = b.at(i).at(j)
            self.solve(xx, xx)
            for i in range(self.n):
                x.at(i).at(j) = xx[i]

    def inverse(inout self, ainv: MatDoub):
        var i: Int, j: Int
        ainv = MatDoub(self.n, VectDoub(self.n))
        for i in range(self.n):
            for j in range(self.n):
                ainv.at(i).at(j) = 0.0
            ainv.at(i).at(i) = 1.0
        self.solve_mat(ainv, ainv)

    def det(self) -> Float64:
        var dd: Float64 = self.d
        for i in range(self.n):
            dd *= self.lu.at(i).at(i)
        return dd

    def mprove(inout self, b: VectDoub, x: VectDoub):
        var i: Int, j: Int
        var r = VectDoub(self.n)
        for i in range(self.n):
            var sdp: Float64 = -b[i]
            for j in range(self.n):
                sdp += self.aref.at(i).at(j) * x[j]
            r[i] = sdp
        self.solve(r, r)
        for i in range(self.n):
            x[i] -= r[i]

struct Powvargram:
    var alph: Float64
    var bet: Float64
    var nugsq: Float64

    def SQR(self, a: Float64) -> Float64:
        return a * a

    def __init__(inout self):
        self.alph = 0.0
        self.bet = 0.0
        self.nugsq = 0.0

    def __init__(inout self, x: MatDoub, y: VectDoub, beta: Float64 = 1.5, nug: Float64 = 0.0):
        self.bet = beta
        self.nugsq = nug * nug
        var i: Int, j: Int, k: Int
        var npt: Int = x.size()
        var ndim: Int = x.front().size()
        var rb: Float64
        var num: Float64 = 0.0
        var denom: Float64 = 0.0
        for i in range(npt):
            for j in range(i+1, npt):
                rb = 0.0
                for k in range(ndim):
                    rb += self.SQR(x.at(i).at(k) - x.at(j).at(k))
                rb = pow(rb, 0.5 * beta)
                num += rb * (0.5 * self.SQR(y[i] - y[j]) - self.nugsq)
                denom += self.SQR(rb)
        self.alph = num / denom

    def __call__(self, r: Float64) -> Float64:
        return self.nugsq + self.alph * pow(r, self.bet)

struct GaussMarkov:
    var x: MatDoub
    var vgram: Powvargram
    var ndim: Int
    var npt: Int
    var lastval: Float64
    var lasterr: Float64
    var y: VectDoub
    var dstar: VectDoub
    var vstar: VectDoub
    var yvi: VectDoub
    var v: MatDoub
    var vi: Pointer[LUdcmp]

    def SQR(self, a: Float64) -> Float64:
        return a * a

    def __init__(inout self, xx: MatDoub, yy: VectDoub, vargram: Powvargram, err: Pointer[Float64] = Pointer[Float64]()):
        self.vgram = vargram
        self.x = xx
        self.npt = xx.size()
        self.ndim = xx.front().size()
        self.dstar = VectDoub(self.npt + 1)
        self.vstar = VectDoub(self.npt + 1)
        self.v = MatDoub(self.npt + 1, VectDoub(self.npt + 1))
        self.y = VectDoub(self.npt + 1)
        self.yvi = VectDoub(self.npt + 1)
        var i: Int, j: Int
        for i in range(self.npt):
            self.y[i] = yy[i]
            for j in range(i, self.npt):
                self.v.at(i).at(j) = self.v.at(j).at(i) = self.vgram(self.rdist(&self.x.at(i), &self.x.at(j)))
            self.v.at(i).at(self.npt) = self.v.at(self.npt).at(i) = 1.0
        self.v.at(self.npt).at(self.npt) = 0.0
        self.y[self.npt] = 0.0
        if err:
            for i in range(self.npt):
                self.v.at(i).at(i) -= self.SQR(err[i])
        self.vi = Pointer[LUdcmp].alloc(LUdcmp(self.v))
        self.vi[].solve(self.y, self.yvi)

    def __init__(inout self):
        self.x = MatDoub()
        self.vgram = Powvargram()
        self.ndim = 0
        self.npt = 0
        self.lastval = 0.0
        self.lasterr = 0.0
        self.y = VectDoub()
        self.dstar = VectDoub()
        self.vstar = VectDoub()
        self.yvi = VectDoub()
        self.v = MatDoub()
        self.vi = Pointer[LUdcmp]()  # null

    def __del__(owned self):
        if self.vi:
            del self.vi[]

    def interp(inout self, xstar: VectDoub) -> Float64:
        var i: Int
        for i in range(self.npt):
            self.vstar[i] = self.vgram(self.rdist(&xstar, &self.x.at(i)))
        self.vstar[self.npt] = 1.0
        self.lastval = 0.0
        for i in range(self.npt + 1):
            self.lastval += self.yvi[i] * self.vstar[i]
        return self.lastval

    def interp_err(inout self, xstar: VectDoub, esterr: Pointer[Float64]) -> Float64:
        self.lastval = self.interp(xstar)
        self.vi[].solve(self.vstar, self.dstar)
        self.lasterr = 0.0
        for i in range(self.npt + 1):
            self.lasterr += self.dstar[i] * self.vstar[i]
        esterr[] = self.lasterr = sqrt(max(0.0, self.lasterr))
        return self.lastval

    def rdist(self, x1: Pointer[VectDoub], x2: Pointer[VectDoub]) -> Float64:
        var d: Float64 = 0.0
        for i in range(self.ndim):
            d += self.SQR(x1[].at(i) - x2[].at(i))
        return sqrt(d)