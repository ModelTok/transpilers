"""
/*******************************************************************************************************
*  Copyright 2017 - pvyield GmbH / Timo Richert
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  ("Alliance") under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as "System Advisor Model" or "SAM". Except
*  to comply with the foregoing, the terms "System Advisor Model", "SAM", or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/
"""
"""
/*******************************************************************************************************
* Implementation of the Mermoud/Thibault single-diode model
*
* SOURCES
* [1] André Mermoud and Thibault Lejeune, "Performance assessment of a simulation model for PV modules
*     of any available technology", 2010 (https://archive-ouverte.unige.ch/unige:38547)
* [2] John A. Duffie, "Solar Engineering of Thermal Processes", 4th Edition, 2013 by John Wiley & Sons
* [3] W. De Soto et al., "Improvement and validation of a model for photovoltaic array performance",
*     Solar Energy, vol 80, pp. 78-88, 2006.
*******************************************************************************************************/
"""

from lib_pvmodel import pvmodule_t, pvinput_t, pvoutput_t, pvcelltemp_t, air_mass_modifier, openvoltage_5par_rec, maxpower_5par_rec, current_5par_rec
from bspline import BSpline, DenseVector
from bsplinebuilder import BSplineBuilder
from datatable import DataTable
from math import exp, pow, cos

let k: Float64 = 1.38064852e-23  # Boltzmann constant [J/K]
let q: Float64 = 1.60217662e-19  # Elemenatry charge [C]
let T_0: Float64 = 273.15  # 0 degrees Celsius in Kelvin [K]
let PI: Float64 = 3.1415926535897932  # pi
let amavec: Float64[5] = Float64[5](0.918093, 0.086257, -0.024459, 0.002816, -0.000126)  # DeSoto IAM coefficients [3]
let T_MODE_NOCT: Int = 1
let T_MODE_FAIMAN: Int = 2
let IAM_MODE_ASHRAE: Int = 1
let IAM_MODE_SANDIA: Int = 2
let IAM_MODE_SPLINE: Int = 3
let AM_MODE_OFF: Int = 1
let AM_MODE_SANDIA: Int = 2
let AM_MODE_DESOTO: Int = 3
let AM_MODE_LEE_PANCHULA: Int = 4

def IAMvalue_ASHRAE(b0: Float64, theta: Float64) -> Float64:
    return (1 - b0 * (1 / cos(theta) - 1))

def IAMvalue_SANDIA(coeff: Float64[6], theta: Float64) -> Float64:
    return coeff[0] + coeff[1] * theta + coeff[2] * pow(theta, 2) + coeff[3] * pow(theta, 3) + coeff[4] * pow(theta, 4) + coeff[5] * pow(theta, 5)

struct mlmodel_module_t(pvmodule_t):
    var N_series: Int
    var N_parallel: Int
    var N_diodes: Int
    var Width: Float64
    var Length: Float64
    var V_mp_ref: Float64
    var I_mp_ref: Float64
    var V_oc_ref: Float64
    var I_sc_ref: Float64
    var S_ref: Float64
    var T_ref: Float64
    var R_shref: Float64
    var R_sh0: Float64
    var R_shexp: Float64
    var R_s: Float64
    var alpha_isc: Float64
    var beta_voc_spec: Float64
    var E_g: Float64
    var n_0: Float64
    var mu_n: Float64
    var D2MuTau: Float64
    var T_mode: Int
    var T_c_no_tnoct: Float64
    var T_c_no_mounting: Int
    var T_c_no_standoff: Int
    var T_c_fa_alpha: Float64
    var T_c_fa_U0: Float64
    var T_c_fa_U1: Float64
    var AM_mode: Int
    var AM_c_sa: Float64[5]
    var AM_c_lp: Float64[6]
    var IAM_mode: Int
    var IAM_c_as: Float64
    var IAM_c_sa: Float64[6]
    var IAM_c_cs_elements: Int
    var IAM_c_cs_incAngle: Float64[100]
    var IAM_c_cs_iamValue: Float64[100]
    var groundRelfectionFraction: Float64
    var isInitialized: Bool
    var nVT: Float64
    var I_0ref: Float64
    var I_Lref: Float64
    var Vbi: Float64
    var m_bspline3: BSpline

    def __init__(self):
        self.m_bspline3 = BSpline(1)
        self.Width = float64.nan
        self.Length = float64.nan
        self.V_mp_ref = float64.nan
        self.I_mp_ref = float64.nan
        self.V_oc_ref = float64.nan
        self.I_sc_ref = float64.nan
        self.S_ref = float64.nan
        self.T_ref = float64.nan
        self.R_shref = float64.nan
        self.R_sh0 = float64.nan
        self.R_shexp = float64.nan
        self.R_s = float64.nan
        self.alpha_isc = float64.nan
        self.beta_voc_spec = float64.nan
        self.E_g = float64.nan
        self.n_0 = float64.nan
        self.mu_n = float64.nan
        self.D2MuTau = float64.nan
        self.T_c_no_tnoct = float64.nan
        self.T_c_fa_alpha = float64.nan
        self.T_c_fa_U0 = float64.nan
        self.T_c_fa_U1 = float64.nan
        self.groundRelfectionFraction = float64.nan
        self.nVT = 0.0
        self.I_0ref = 0.0
        self.I_Lref = 0.0
        self.Vbi = 0.0
        self.N_series = 0
        self.N_parallel = 0
        self.N_diodes = 0
        self.isInitialized = False

    def AreaRef(self) -> Float64:
        return (self.Width * self.Length)

    def VmpRef(self) -> Float64:
        return self.V_mp_ref

    def ImpRef(self) -> Float64:
        return self.I_mp_ref

    def VocRef(self) -> Float64:
        return self.V_oc_ref

    def IscRef(self) -> Float64:
        return self.I_sc_ref

    def initializeManual(self):
        if not self.isInitialized:
            self.Vbi = 0.9 * self.N_series
            let R_sh_STC: Float64 = self.R_shref + (self.R_sh0 - self.R_shref) * exp(-self.R_shexp * (self.S_ref / self.S_ref))
            self.nVT = self.N_series * self.n_0 * k * (self.T_ref + T_0) / q
            self.I_0ref = (self.I_sc_ref + (self.I_sc_ref * self.R_s - self.V_oc_ref) / R_sh_STC) / ((exp(self.V_oc_ref / self.nVT) - 1) - (exp((self.I_sc_ref * self.R_s) / self.nVT) - 1))
            self.I_Lref = self.I_0ref * (exp(self.V_oc_ref / self.nVT) - 1) + self.V_oc_ref / R_sh_STC
            if self.IAM_mode == IAM_MODE_SPLINE:
                # /*
                # vector<double> X;
                # vector<double> Y;
                # X.clear();
                # Y.clear();
                # for (int i = 0; i <= IAM_c_cs_elements - 1; i = i + 1) {
                #     X.push_back(IAM_c_cs_incAngle[i]);
                #     Y.push_back(IAM_c_cs_iamValue[i]);
                # }
                # iamSpline.set_points(X, Y);
                # */
                let samples = DataTable()
                for i in range(0, self.IAM_c_cs_elements):
                    samples.addSample(self.IAM_c_cs_incAngle[i], self.IAM_c_cs_iamValue[i])
                self.m_bspline3 = BSpline.Builder(samples).degree(3).build()
                self.isInitialized = True

    def __call__(self, input: pvinput_t, T_C: Float64, opvoltage: Float64, out: inout pvoutput_t) -> Bool:
        out.Power = 0.0
        out.Voltage = 0.0
        out.Current = 0.0
        out.Efficiency = 0.0
        out.Voc_oper = 0.0
        out.Isc_oper = 0.0
        var f_IAM_beam: Float64 = 0.0
        var f_IAM_diff: Float64 = 0.0
        var f_IAM_gnd: Float64 = 0.0
        let theta_beam: Float64 = input.IncAng
        let theta_diff: Float64 = (59.7 - 0.1388 * input.Tilt + 0.001497 * pow(input.Tilt, 2))  # from [2], equation 5.4.2
        let theta_gnd: Float64 = (90.0 - 0.5788 * input.Tilt + 0.002693 * pow(input.Tilt, 2))  # from [2], equation 5.4.1
        if self.IAM_mode == IAM_MODE_ASHRAE:
            f_IAM_beam = IAMvalue_ASHRAE(self.IAM_c_as, theta_beam / 180 * PI)
            f_IAM_diff = IAMvalue_ASHRAE(self.IAM_c_as, theta_diff / 180 * PI)
            f_IAM_gnd = IAMvalue_ASHRAE(self.IAM_c_as, theta_gnd / 180 * PI)
        elif self.IAM_mode == IAM_MODE_SANDIA:
            f_IAM_beam = IAMvalue_SANDIA(self.IAM_c_sa, theta_beam / 180 * PI)
            f_IAM_diff = IAMvalue_SANDIA(self.IAM_c_sa, theta_diff / 180 * PI)
            f_IAM_gnd = IAMvalue_SANDIA(self.IAM_c_sa, theta_gnd / 180 * PI)
        elif self.IAM_mode == IAM_MODE_SPLINE:
            let x = DenseVector(1)
            x[0] = theta_beam
            f_IAM_beam = min(self.m_bspline3.eval(x), 1.0)
            x[0] = theta_diff
            f_IAM_diff = min(self.m_bspline3.eval(x), 1.0)
            x[0] = theta_gnd
            f_IAM_gnd = min(self.m_bspline3.eval(x), 1.0)
        var f_AM: Float64 = 0.0
        if self.AM_mode == AM_MODE_OFF:
            f_AM = 1.0
        elif self.AM_mode == AM_MODE_SANDIA:
            f_AM = air_mass_modifier(input.Zenith, input.Elev, self.AM_c_sa)
        elif self.AM_mode == AM_MODE_DESOTO:
            f_AM = air_mass_modifier(input.Zenith, input.Elev, amavec)
        elif self.AM_mode == AM_MODE_LEE_PANCHULA:
            f_AM = -1  # TO BE ADDED
        var S: Float64
        if input.radmode != 3:  # Skip module cover effects if using POA reference cell data
            S = (f_IAM_beam * input.Ibeam + f_IAM_diff * input.Idiff + self.groundRelfectionFraction * f_IAM_gnd * input.Ignd) * f_AM
        elif input.usePOAFromWF:  # Check if decomposed POA is required, if not use weather file POA directly
            S = input.poaIrr
        else:  # Otherwise use decomposed POA
            S = (f_IAM_beam * input.Ibeam + f_IAM_diff * input.Idiff + self.groundRelfectionFraction * f_IAM_gnd * input.Ignd) * f_AM
        if S >= 1:
            var n: Float64 = 0.0
            var a: Float64 = 0.0
            var I_L: Float64 = 0.0
            var I_0: Float64 = 0.0
            var R_sh: Float64 = 0.0
            var I_sc: Float64 = 0.0
            var V_oc: Float64 = self.V_oc_ref  # V_oc_ref as initial guess
            var P: Float64 = 0.0
            var V: Float64 = 0.0
            var I: Float64 = 0.0
            var eff: Float64 = 0.0
            var T_cell: Float64 = T_C
            var iterations: Int = 0
            if self.T_mode == T_MODE_FAIMAN:
                iterations = 1  # 2; // two iterations, 1st with guessed eff, 2nd with calculated efficiency
                eff = (self.I_mp_ref * self.V_mp_ref) / ((self.Width * self.Length) * self.S_ref)  # efficiency guess for initial run
            else:
                iterations = 1
            for i in range(1, iterations + 1):
                if self.T_mode == T_MODE_FAIMAN:
                    T_cell = input.Tdry + (self.T_c_fa_alpha * S * (1 - eff)) / (self.T_c_fa_U0 + input.Wspd * self.T_c_fa_U1)
                n = self.n_0 + self.mu_n * (T_cell - self.T_ref)
                a = self.N_series * k * (T_cell + T_0) * n / q
                I_L = (S / self.S_ref) * (self.I_Lref + self.alpha_isc * (T_cell - self.T_ref))
                I_0 = self.I_0ref * pow(((T_cell + T_0) / (self.T_ref + T_0)), 3) * exp((q * self.E_g) / (n * k) * (1 / (self.T_ref + T_0) - 1 / (T_cell + T_0)))
                R_sh = self.R_shref + (self.R_sh0 - self.R_shref) * exp(-self.R_shexp * (S / self.S_ref))
                V_oc = openvoltage_5par_rec(V_oc, a, I_L, I_0, R_sh, self.D2MuTau, self.Vbi)
                I_sc = I_L / (1 + self.R_s / R_sh)
                if opvoltage < 0:
                    P = maxpower_5par_rec(V_oc, a, I_L, I_0, self.R_s, R_sh, self.D2MuTau, self.Vbi, &V, &I)
                else:
                    # calculate power at specified operating voltage
                    V = opvoltage
                    if V >= V_oc:
                        I = 0
                    else:
                        I = current_5par_rec(V, 0.9 * I_L, a, I_L, I_0, self.R_s, R_sh, self.D2MuTau, self.Vbi)
                    P = V * I
                eff = P / ((self.Width * self.Length) * (input.Ibeam + input.Idiff + input.Ignd))
            out.Power = P
            out.Voltage = V
            out.Current = I
            out.Efficiency = eff
            out.Voc_oper = V_oc
            out.Isc_oper = I_sc
            out.CellTemp = T_cell
            out.AOIModifier = S / (input.Ibeam + input.Idiff + input.Ignd)
        return out.Power >= 0

struct mock_celltemp_t(pvcelltemp_t):
    def __call__(self, input: pvinput_t, module: pvmodule_t, opvoltage: Float64, Tcell: inout Float64) -> Bool:
        Tcell = -999
        return True