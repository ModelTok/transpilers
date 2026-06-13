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
from csp_solver_util import C_csp_exception
from math import pow, exp, log10, fmax, fmin, ceil, sqrt
from memory import DTypePointer, Pointer
from utils import String
from utils.list import List
from utils.matrix import matrix_t

struct HTFProperties:
    var m_m: Int = 2
    var User_Defined_Props: Linear_Interp
    var mc_temp_enth_lookup: Linear_Interp
    var m_is_temp_enth_avail: Bool
    var m_fluid: Int
    var m_userTable: matrix_t[Float64]
    var uf_err_msg: String

    def __init__(inout self):
        self.m_fluid = 0
        self.uf_err_msg = "The user-defined htf property table is invalid (rows=%d cols=%d)"
        self.m_is_temp_enth_avail = False
        self.User_Defined_Props = Linear_Interp()
        self.mc_temp_enth_lookup = Linear_Interp()
        self.m_userTable = matrix_t[Float64]()

    def Air() -> Int: return 1
    def Stainless_AISI316() -> Int: return 2
    def Water_liquid() -> Int: return 3
    def Steam() -> Int: return 4
    def CO2() -> Int: return 5
    def Salt_68_KCl_32_MgCl2() -> Int: return 6
    def Salt_8_NaF_92_NaBF4() -> Int: return 7
    def Salt_25_KF_75_KBF4() -> Int: return 8
    def Salt_31_RbF_69_RbBF4() -> Int: return 9
    def Salt_465_LiF_115_NaF_42KF() -> Int: return 10
    def Salt_49_LiF_29_NaF_29_ZrF4() -> Int: return 11
    def Salt_58_KF_42_ZrF4() -> Int: return 12
    def Salt_58_LiCl_42_RbCl() -> Int: return 13
    def Salt_58_NaCl_42_MgCl2() -> Int: return 14
    def Salt_595_LiCl_405_KCl() -> Int: return 15
    def Salt_595_NaF_405_ZrF4() -> Int: return 16
    def Salt_60_NaNO3_40_KNO3() -> Int: return 17
    def Nitrate_Salt() -> Int: return 18
    def Caloria_HT_43() -> Int: return 19
    def Hitec_XL() -> Int: return 20
    def Therminol_VP1() -> Int: return 21
    def Hitec() -> Int: return 22
    def Dowtherm_Q() -> Int: return 23
    def Dowtherm_RP() -> Int: return 24
    def Blank1() -> Int: return 25
    def Argon_ideal() -> Int: return 26
    def Hydrogen_ideal() -> Int: return 27
    def T91_Steel() -> Int: return 28
    def Therminol_66() -> Int: return 29
    def Therminol_59() -> Int: return 30
    def Pressurized_Water() -> Int: return 31
    def N06230() -> Int: return 32
    def N07740() -> Int: return 33
    def End_Library_Fluids() -> Int: return 34
    def User_defined() -> Int: return 50

    def UserFluidErrMessage(self) -> String:
        return self.uf_err_msg

    def SetFluid(inout self, fluid: Int) -> Bool:
        self.m_fluid = fluid
        if self.m_is_temp_enth_avail:
            self.set_temp_enth_lookup()
        return True

    def SetFluid(inout self, fluid: Int, calc_temp_enth_table: Bool) -> Bool:
        self.m_is_temp_enth_avail = calc_temp_enth_table
        return self.SetFluid(fluid)

    def GetFluid(self) -> Int:
        return self.m_fluid

    def SetUserDefinedFluid(inout self, table: matrix_t[Float64]) -> Bool:
        if table.ncols() != 7:
            return False
        self.m_userTable = table
        self.m_fluid = 50
        var ind_var_index: List[Int] = List[Int](0, 6)
        var n_ind_var: Int = 2
        var error_index: Int = -99
        if not self.User_Defined_Props.Set_1D_Lookup_Table(table, ind_var_index, n_ind_var, error_index):
            if error_index == -1:
                self.uf_err_msg = "Interpolation table must have at least 3 rows (rows=%d cols=%d)"
            if error_index == 0:
                self.uf_err_msg = "Temperature must monotonically increase (rows=%d cols=%d)"
            if error_index == 1:
                self.uf_err_msg = "Enthalpy must monotonically increase (rows=%d cols=%d)"
            return False
        if self.m_is_temp_enth_avail:
            self.set_temp_enth_lookup()
        return True

    def SetUserDefinedFluid(inout self, table: matrix_t[Float64], calc_temp_enth_table: Bool) -> Bool:
        self.m_is_temp_enth_avail = calc_temp_enth_table
        return self.SetUserDefinedFluid(table)

    def set_temp_enth_lookup(inout self):
        var T_low: Float64 = 270.0 + 273.15
        var T_high: Float64 = 600.0 + 273.15
        var delta_T_target: Float64 = 1.0
        var n_rows: Int = Int(ceil((T_high - T_low) / delta_T_target) + 1.0)
        var delta_T: Float64 = (T_high - T_low) / Float64(n_rows - 1)
        var table: matrix_t[Float64] = matrix_t[Float64](n_rows, 2)
        var T: Float64
        var T_next: Float64
        var cp: Float64
        var h: Float64
        var h_next: Float64
        T_next = T_low
        h_next = 0.0
        table[0, 0] = T_next
        table[0, 1] = h_next
        for i in range(n_rows - 1):
            h = h_next
            T = T_next
            T_next = T + delta_T
            cp = self.Cp(0.5 * (T + T_next))
            h_next = h + cp * delta_T
            table[i + 1, 0] = T_next
            table[i + 1, 1] = h_next
        var ind_var_index: List[Int] = List[Int](0, 1)
        var n_ind_var: Int = 2
        var error_index: Int = -99
        if not self.mc_temp_enth_lookup.Set_1D_Lookup_Table(table, ind_var_index, n_ind_var, error_index):
            if error_index == -1:
                raise C_csp_exception("Interpolation table must have at least 3 rows (rows=%d cols=%d)", 
                    "HTFProperties::set_temp_enth_lookup")
            if error_index == 0:
                raise C_csp_exception("Temperature must monotonically increase (rows=%d cols=%d)",
                    "HTFProperties::set_temp_enth_lookup")
            if error_index == 1:
                raise C_csp_exception("Enthalpy must monotonically increase (rows=%d cols=%d)",
                    "HTFProperties::set_temp_enth_lookup")

    def temp_lookup(self, enth: Float64) -> Float64:
        if not self.m_is_temp_enth_avail:
            raise C_csp_exception("The enth-temp-lookup method is only available if fluid is set with optional Boolean to enable it")
        return self.mc_temp_enth_lookup.linear_1D_interp(1, 0, enth)

    def enth_lookup(self, temp: Float64) -> Float64:
        if not self.m_is_temp_enth_avail:
            raise C_csp_exception("This enth-temp-lookup method is only available if fluid is set with optional Boolean to enable it")
        return self.mc_temp_enth_lookup.linear_1D_interp(0, 1, temp)

    def get_prop_table(self) -> matrix_t[Float64]:
        return self.m_userTable

    def equals(self, comp_class: HTFProperties) -> Bool:
        return self.m_userTable.equals(comp_class.get_prop_table())

    def Cp_ave(self, T_cold_K: Float64, T_hot_K: Float64, n_points: Int) -> Float64:
        if T_cold_K <= 0.0:
            raise C_csp_exception("Cold temperature must be greater than 0.0", 
                "HTFProperties::Cp_ave", 1)
        if T_hot_K <= 0.0:
            raise C_csp_exception("Hot temperature must be greater than 0.0",
                "HTFProperties::Cp_ave", 1)
        var n_points_local: Int = n_points
        if n_points_local < 2:
            n_points_local = 2
        if n_points_local > 500:
            n_points_local = 500
        var cp_sum: Float64 = 0.0
        var T_i: Float64 = Float64(0.0)
        var delta_T: Float64 = (T_hot_K - T_cold_K) / Float64(n_points_local - 1)
        for i in range(n_points_local):
            T_i = T_cold_K + delta_T * Float64(i)
            cp_sum += self.Cp(T_i)
        return cp_sum / Float64(n_points_local)

    def Cp(self, T_K: Float64) -> Float64:
        var T_C: Float64 = T_K - 273.15
        if self.m_fluid == 1:
            return 1.03749 - 0.000305497 * T_K + 7.49335E-07 * T_K * T_K - 3.39363E-10 * T_K * T_K * T_K
        elif self.m_fluid == 2:
            return 0.368455 + 0.000399548 * T_K - 1.70558E-07 * T_K * T_K
        elif self.m_fluid == 3:
            return 4.181
        elif self.m_fluid == 6:
            return 1.9700E-08 * pow(T_C, 2) - 1.2203E-05 * T_C + 1.0091
        elif self.m_fluid == 7:
            return 1.507
        elif self.m_fluid == 8:
            return 1.306
        elif self.m_fluid == 9:
            return 9.127
        elif self.m_fluid == 10:
            return 2.010
        elif self.m_fluid == 11:
            return 1.239
        elif self.m_fluid == 12:
            return 1.051
        elif self.m_fluid == 13:
            return 8.918
        elif self.m_fluid == 14:
            return 1.080
        elif self.m_fluid == 15:
            return 1.202
        elif self.m_fluid == 16:
            return 1.172
        elif self.m_fluid == 17:
            return -1E-10 * T_K * T_K * T_K + 2E-07 * T_K * T_K + 5E-06 * T_K + 1.4387
        elif self.m_fluid == 18:
            return (1443.0 + 0.172 * (T_K - 273.15)) / 1000.0
        elif self.m_fluid == 19:
            return (3.88 * (T_K - 273.15) + 1606.0) / 1000.0
        elif self.m_fluid == 20:
            return fmax(1536.0 - 0.2624 * T_C - 0.0001139 * T_C * T_C, 1000.0) / 1000.0
        elif self.m_fluid == 21:
            return (1.509 + 0.002496 * T_C + 0.0000007888 * T_C * T_C)
        elif self.m_fluid == 22:
            return 1560.0 / 1000.0
        elif self.m_fluid == 23:
            return (-0.00053943 * T_C * T_C + 3.2028 * T_C + 1589.2) / 1000.0
        elif self.m_fluid == 24:
            return (-0.0000031915 * T_C * T_C + 2.977 * T_C + 1560.8) / 1000.0
        elif self.m_fluid == 26:
            return 0.5203
        elif self.m_fluid == 27:
            return fmin(fmax(-45.4022 + 0.690156 * T_K - 0.00327354 * T_K * T_K + 0.00000817326 * T_K * T_K * T_K - 1.13234E-08 * T_K * T_K * T_K * T_K + 8.24995E-12 * T_K * T_K * T_K * T_K * T_K - 2.46804E-15 * T_K * T_K * T_K * T_K * T_K * T_K, 11.3), 14.7)
        elif self.m_fluid == 28:
            return 0.0004 * T_C * T_C + 0.2473 * T_C + 450.08
        elif self.m_fluid == 29:
            return 0.0036 * T_C + 1.4801
        elif self.m_fluid == 30:
            return 0.0033 * T_C + 1.6132
        elif self.m_fluid == 31:
            return 1.E-5 * T_C * T_C - 0.0014 * T_C + 4.2092
        elif self.m_fluid == 32:
            return 0.2888 * T_C + 397.42
        elif self.m_fluid == 33:
            return -1.E-9 * pow(T_C, 4) + 3.E-6 * pow(T_C, 3) - 0.0022 * pow(T_C, 2) + 0.6218 * T_C + 434.06
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(0, 1, T_C)
        else:
            return Float64(0.0 / 0.0)

    def dens(self, T_K: Float64, P: Float64) -> Float64:
        var T_C: Float64 = T_K - 273.15
        if self.m_fluid == 1:
            return P / (287.0 * T_K)
        elif self.m_fluid == 2:
            return 8349.38 - 0.341708 * T_K - 0.0000865128 * T_K * T_K
        elif self.m_fluid == 3:
            return 1000.0
        elif self.m_fluid == 6:
            return (-5.0997E-4 * T_C + 1.8943) * 1.E3
        elif self.m_fluid == 7:
            return 8E-09 * T_K * T_K * T_K - 2E-05 * T_K * T_K - 0.6867 * T_K + 2438.5
        elif self.m_fluid == 8:
            return 2E-08 * T_K * T_K * T_K - 6E-05 * T_K * T_K - 0.7701 * T_K + 2466.1
        elif self.m_fluid == 9:
            return -1E-08 * T_K * T_K * T_K + 4E-05 * T_K * T_K - 1.0836 * T_K + 3242.6
        elif self.m_fluid == 10:
            return -2E-09 * T_K * T_K * T_K + 1E-05 * T_K * T_K - 0.7427 * T_K + 2734.7
        elif self.m_fluid == 11:
            return -2E-11 * T_K * T_K * T_K + 1E-07 * T_K * T_K - 0.5172 * T_K + 3674.3
        elif self.m_fluid == 12:
            return -6E-10 * T_K * T_K * T_K + 4E-06 * T_K * T_K - 0.8931 * T_K + 3661.3
        elif self.m_fluid == 13:
            return -8E-10 * T_K * T_K * T_K + 1E-06 * T_K * T_K - 0.689 * T_K + 2929.5
        elif self.m_fluid == 14:
            return -5E-09 * T_K * T_K * T_K + 2E-05 * T_K * T_K - 0.5298 * T_K + 2444.1
        elif self.m_fluid == 15:
            return 1E-09 * T_K * T_K * T_K - 5E-06 * T_K * T_K - 0.864 * T_K + 2112.6
        elif self.m_fluid == 16:
            return -5E-09 * T_K * T_K * T_K + 2E-05 * T_K * T_K - 0.9144 * T_K + 3837.0
        elif self.m_fluid == 17:
            return fmax(-1E-07 * T_K * T_K * T_K + 0.0002 * T_K * T_K - 0.7875 * T_K + 2299.4, 1000.0)
        elif self.m_fluid == 18:
            return fmax(2090.0 - 0.636 * (T_K - 273.15), 1000.0)
        elif self.m_fluid == 19:
            return fmax(885.0 - 0.6617 * T_C - 0.0001265 * T_C * T_C, 100.0)
        elif self.m_fluid == 20:
            return fmax(2240.0 - 0.8266 * T_C, 800.0)
        elif self.m_fluid == 21:
            return fmax(1074.0 - 0.6367 * T_C - 0.0007762 * T_C * T_C, 400.0)
        elif self.m_fluid == 22:
            return fmax(2080.0 - 0.733 * T_C, 1000.0)
        elif self.m_fluid == 23:
            return fmax(-0.757332 * T_C + 980.787, 100.0)
        elif self.m_fluid == 24:
            return fmax(-0.000186495 * T_C * T_C - 0.668337 * T_C + 1042.11, 200.0)
        elif self.m_fluid == 26:
            return fmax(P / (208.13 * T_K), 1.E-10)
        elif self.m_fluid == 27:
            return fmax(P / (4124.0 * T_K), 1.E-10)
        elif self.m_fluid == 28:
            return -0.3289 * T_C + 7742.5
        elif self.m_fluid == 29:
            return -0.7146 * T_C + 1024.8
        elif self.m_fluid == 30:
            return -0.0003 * T_C * T_C - 0.6963 * T_C + 988.44
        elif self.m_fluid == 31:
            return -0.0023 * T_C * T_C - 0.2337 * T_C + 1005.6
        elif self.m_fluid == 32:
            return 8970.0
        elif self.m_fluid == 33:
            return 8072.0
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(0, 2, T_C)
        else:
            return Float64(0.0 / 0.0)

    def visc(self, T_K: Float64) -> Float64:
        var T_C: Float64 = T_K - 273.15
        if self.m_fluid == 1:
            return fmax(0.0000010765 + 7.15173E-08 * T_K - 5.03525E-11 * T_K * T_K + 2.02799E-14 * T_K * T_K * T_K, 1.E-6)
        elif self.m_fluid == 6:
            return (1.8075E-5 * pow(T_C, 2) - 2.8496E-2 * T_C + 1.3489E1) * 0.001
        elif self.m_fluid == 7:
            return 0.0877 * exp(2240.0 / T_K) * 0.001
        elif self.m_fluid == 8:
            return 0.0431 * exp(3060.0 / T_K) * 0.001
        elif self.m_fluid == 9:
            return 0.0009
        elif self.m_fluid == 10:
            return 0.0400 * exp(4170.0 / T_K) * 0.001
        elif self.m_fluid == 11:
            return 0.0069
        elif self.m_fluid == 12:
            return 0.0159 * exp(3179.0 / T_K) * 0.001
        elif self.m_fluid == 13:
            return 0.0861 * exp(2517.0 / T_K) * 0.001
        elif self.m_fluid == 14:
            return 0.0286 * exp(1441.0 / T_K) * 0.001
        elif self.m_fluid == 15:
            return 0.0861 * exp(2517.0 / T_K) * 0.001
        elif self.m_fluid == 16:
            return 0.0767 * exp(3977.0 / T_K) * 0.001
        elif self.m_fluid == 17:
            return fmax(-1.473302E-10 * pow(T_C, 3) + 2.279989E-07 * pow(T_C, 2) - 1.199514E-04 * T_C + 2.270616E-02, 0.0001)
        elif self.m_fluid == 18:
            return fmax((22.714 - 0.12 * T_C + 0.0002281 * T_C * T_C - 0.0000001474 * pow(T_C, 3)) / 1000.0, 1.e-6)
        elif self.m_fluid == 19:
            return (0.040439268 * pow(fmax(T_C, 10.0), -1.946401872)) * self.dens(T_K, 0.0)
        elif self.m_fluid == 20:
            return 1372000.0 * pow(T_C, -3.364)
        elif self.m_fluid == 21:
            return 0.001 * (pow(10.0, 0.8703) * pow(fmax(T_C, 20.0), (0.2877 + log10(pow(fmax(T_C, 20.0), -0.3638)))))
        elif self.m_fluid == 22:
            return fmax(0.00622 - 0.0000102 * T_C, 1.e-6)
        elif self.m_fluid == 23:
            return 1.0 / (132.40658 + 4.36107 * T_C + 0.0781417 * T_C * T_C - 0.00011035416 * pow(T_C, 3))
        elif self.m_fluid == 24:
            return 1.0 / (4.523003 + 0.39156855 * T_C + 0.028604206 * T_C * T_C)
        elif self.m_fluid == 26:
            return 4.4997e-6 + 6.38920E-08 * T_K - 1.24550E-11 * T_K * T_K
        elif self.m_fluid == 27:
            return 0.00000231 + 2.37842E-08 * T_K - 5.73624E-12 * T_K * T_K
        elif self.m_fluid == 29:
            if T_C < 80.0:
                return 1.31959963 - 0.171204729 * T_C + 0.0100351594 * pow(T_C, 2) - 0.000313556341 * pow(T_C, 3) + 0.0000053430666 * pow(T_C, 4) - 4.66597650E-08 * pow(T_C, 5) + 1.63046296E-10 * pow(T_C, 6)
            else:
                return 0.0490075884 - 0.00120478233 * T_C + 0.0000130162082 * pow(T_C, 2) - 7.58913847E-08 * pow(T_C, 3) + 2.47856063E-10 * pow(T_C, 4) - 4.26872345E-13 * pow(T_C, 5) + 3.01949160E-16 * pow(T_C, 6)
        elif self.m_fluid == 30:
            if T_C < 25.0:
                return 0.0137267822 - 0.000218740224 * T_C + 0.0000759248815 * pow(T_C, 2) - 0.00000473464744 * pow(T_C, 3) - 1.97083667E-07 * pow(T_C, 4) + 4.35487179E-09 * pow(T_C, 5) + 2.40243056E-10 * pow(T_C, 6)
            else:
                return 0.0114608807 - 0.000313431056 * T_C + 0.00000416778121 * pow(T_C, 2) - 3.04668508E-08 * pow(T_C, 3) + 1.23719006E-10 * pow(T_C, 4) - 2.60834697E-13 * pow(T_C, 5) + 2.22227675E-16 * pow(T_C, 6)
        elif self.m_fluid == 31:
            return 3.E-8 * T_C * T_C - 1.E-5 * T_C + 0.0011
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(0, 3, T_C)
        else:
            return Float64(0.0 / 0.0)

    def cond(self, T_K: Float64) -> Float64:
        var T_C: Float64 = T_K - 273.15
        if self.m_fluid == 1:
            return fmax(0.00145453 + 0.0000872152 * T_K - 2.20614E-08 * T_K * T_K, 1.e-4)
        elif self.m_fluid == 2:
            return 3E-09 * pow(T_K, 3) - 8E-06 * pow(T_K, 2) + 0.0177 * T_K + 7.7765
        elif self.m_fluid == 6:
            return (-1.0000E-04 * T_C + 5.0470E-01)
        elif self.m_fluid == 7:
            return 0.5
        elif self.m_fluid == 8:
            return 0.4
        elif self.m_fluid == 9:
            return 0.28
        elif self.m_fluid == 10:
            return 0.92
        elif self.m_fluid == 11:
            return 0.53
        elif self.m_fluid == 12:
            return 0.45
        elif self.m_fluid == 13:
            return 0.39
        elif self.m_fluid == 14:
            return 0.43
        elif self.m_fluid == 15:
            return 0.43
        elif self.m_fluid == 16:
            return 0.49
        elif self.m_fluid == 17:
            return -1E-11 * pow(T_K, 3) + 3E-08 * pow(T_K, 2) + 0.0002 * T_K + 0.3922
        elif self.m_fluid == 18:
            return 0.443 + 0.00019 * T_C
        elif self.m_fluid == 19:
            return fmax(-0.00014 * T_C + 0.1245, 0.01)
        elif self.m_fluid == 20:
            return 0.519
        elif self.m_fluid == 21:
            return fmax(0.1381 - 0.00008708 * T_C - 0.0000001729 * pow(T_C, 2), 0.001)
        elif self.m_fluid == 22:
            return 0.588 - 0.000647 * T_C
        elif self.m_fluid == 23:
            return fmax(-0.0000000626555 * pow(T_C, 2) - 0.000124864 * T_C + 0.124379, 1.e-5)
        elif self.m_fluid == 24:
            return -0.00012963 * T_C + 0.13397
        elif self.m_fluid == 26:
            return 0.00548 + 0.0000438969 * T_K - 6.81410E-09 * T_K * T_K
        elif self.m_fluid == 27:
            return fmax(0.0302888 + 0.00053634 * T_K - 1.59604E-07 * T_K * T_K, 0.01)
        elif self.m_fluid == 28:
            return -2.E-5 * T_C * T_C + 0.017 * T_C + 25.535
        elif self.m_fluid == 29:
            return -2.E-7 * T_C * T_C - 3.E-5 * T_C + 0.1183
        elif self.m_fluid == 30:
            return -1.E-7 * T_C * T_C - 6.E-5 * T_C + 0.1227
        elif self.m_fluid == 31:
            return -6.E-6 * T_C * T_C + 0.0016 * T_C * T_C + 0.5631
        elif self.m_fluid == 32:
            return 0.0197 * T_C + 8.5359
        elif self.m_fluid == 33:
            return 0.0155 * T_C + 9.7239
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(0, 5, T_C)
        else:
            return Float64(0.0 / 0.0)

    def temp(self, H: Float64) -> Float64:
        var H_kJ: Float64
        if self.m_fluid == 18:
            return -0.0000000000262 * H * H + 0.0006923 * H + 0.03058
        elif self.m_fluid == 19:
            return 6.4394E-17 * pow(H, 3) - 0.00000000023383 * pow(H, 2) + 0.0005821 * H + 1.2744
        elif self.m_fluid == 20:
            return 0.00000000005111 * H * H + 0.0006466 * H + 0.2151
        elif self.m_fluid == 21:
            return 7.4333E-17 * pow(H, 3) - 0.00000000024625 * pow(H, 2) + 0.00063282 * H + 12.403
        elif self.m_fluid == 22:
            return -3.309E-24 * pow(H, 2) + 0.000641 * H + 0.000000000001364
        elif self.m_fluid == 23:
            return 6.186E-17 * pow(H, 3) - 0.00000000022211 * pow(H, 2) + 0.00059998 * H + 0.77742
        elif self.m_fluid == 24:
            return 6.6607E-17 * pow(H, 3) - 0.00000000023347 * pow(H, 2) + 0.00061419 * H + 0.77419
        elif self.m_fluid == 29:
            H_kJ = H / 1000.0
            return -0.00018 * H_kJ * H_kJ + 0.521 * H_kJ + 7.0
        elif self.m_fluid == 30:
            H_kJ = H / 1000.0
            return -0.000204 * H_kJ * H_kJ + 0.539 * H_kJ - 0.094
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(6, 0, H)
        else:
            return Float64(0.0 / 0.0)

    def enth(self, T_K: Float64) -> Float64:
        var T_C: Float64 = T_K - 273.15
        if self.m_fluid == 18:
            return 1443.0 * T_C + 0.086 * T_C * T_C
        elif self.m_fluid == 19:
            return 1.94 * T_C * T_C + 1606.0 * T_C
        elif self.m_fluid == 20:
            return 1536 * T_C - 0.1312 * T_C * T_C - 0.0000379667 * pow(T_C, 3)
        elif self.m_fluid == 21:
            return 1000.0 * (-18.34 + 1.498 * T_C + 0.001377 * T_C * T_C)
        elif self.m_fluid == 22:
            return 1560.0 * T_C
        elif self.m_fluid == 23:
            return (0.00151461 * T_C * T_C + 1.59867 * T_C - 0.0250596) * 1000.0
        elif self.m_fluid == 24:
            return (0.0014879 * T_C * T_C + 1.5609 * T_C - 0.0024798) * 1000.0
        elif self.m_fluid == 29:
            return 1000.0 * (0.0038 * T_C * T_C + 1.4363 * T_C + 1.6142)
        elif self.m_fluid == 30:
            return 1000.0 * (0.0034 * T_C * T_C + 1.5977 * T_C - 0.0926)
        elif self.m_fluid == 31:
            return 4.2711 * T_C - 4.3272
        elif self.m_fluid == 50:
            if self.m_userTable.nrows() < 3:
                return Float64(0.0 / 0.0)
            return self.User_Defined_Props.linear_1D_interp(0, 6, T_C)
        else:
            return Float64(0.0 / 0.0)

    def Cv(self, T_K: Float64) -> Float64:
        if self.m_fluid == 1:
            return 0.750466 - 0.000305497 * T_K + 7.49335E-07 * T_K * T_K - 3.39363E-10 * pow(T_K, 3)
        elif self.m_fluid == 26:
            return 0.3122
        elif self.m_fluid == 27:
            return fmin(fmax(-49.5264 + 0.690156 * T_K - 0.00327354 * T_K * T_K + 0.00000817326 * pow(T_K, 3) - 1.13234E-08 * pow(T_K, 4) + 8.24995E-12 * pow(T_K, 5) - 2.46804E-15 * pow(T_K, 6), 7.20), 10.60)
        else:
            return Float64(0.0 / 0.0)

    def kin_visc(self, T_K: Float64, P: Float64) -> Float64:
        var k_visc: Float64 = self.visc(T_K) / self.dens(T_K, P)
        return k_visc

    def therm_diff(self, T_K: Float64, P: Float64) -> Float64:
        var diff: Float64 = self.cond(T_K) / (self.dens(T_K, P) * self.Cp(T_K) * 1000.0)
        return diff

    def Pr(self, T_K: Float64, P: Float64) -> Float64:
        var Pr_num: Float64 = self.visc(T_K) / (self.dens(T_K, P) * self.therm_diff(T_K, P))
        return Pr_num

    def Re(self, T_K: Float64, P: Float64, vel: Float64, d: Float64) -> Float64:
        var Re_num: Float64 = self.dens(T_K, P) * vel * d / self.visc(T_K)
        return Re_num

struct AbsorberProps:
    var mnum: Int

    def __init__(inout self):
        self.mnum = 0

    def Mat_304L() -> Int: return 1
    def Mat_216L() -> Int: return 2
    def Mat_321H() -> Int: return 3
    def Mat_B42_Copper_Pipe() -> Int: return 4

    def setMaterial(inout self, mat_num: Int):
        self.mnum = mat_num

    def cond(self, T: Float64, mat_num: Int = -1) -> Float64:
        var mtemp: Int = mat_num
        if mat_num < 0:
            mtemp = self.mnum
        if mtemp == 1:
            return 0.013 * T + 15.2
        elif mtemp == 2:
            return 0.013 * T + 15.2
        elif mtemp == 3:
            return 0.0153 * T + 14.775
        elif mtemp == 4:
            return 400.0
        else:
            return Float64(0.0 / 0.0)