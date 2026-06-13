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
from math import *
from memory import Pointer, alloc, free

# Import shared library types
from ...shared.lib_util import matrix_t as MatrixFloat64, MatrixInt, MatrixBool
from htf_props import HTFProperties, AbsorberProps
from water_properties import water_state, water_TP, water_TQ, water_PQ
from csp_solver_util import C_csp_exception

# Define constants
var sigma: Float64 = 5.67E-8          # [W/m2K4] stefan boltzmann constant
var grav: Float64 = 9.81              # [m/s2] gravitational constant
var pi: Float64 = 3.1415926           # [-]

# ------------------------------------------------------------------------------
# Free functions in CSP namespace
# ------------------------------------------------------------------------------
def interp(data: Pointer[MatrixFloat64], x: Float64, low_bound: Int = -1, up_bound: Int = -1, increasing: Bool = True) -> Float64:
    """ 
    Given a matrix with 2 rows and N columns, interpolate along row 0 to find a corresponding 
    value in row 1. 
    -----------------------------------------------------------------------------
    data.at(0,:)	|	X - independent variable data
    data.at(1,:)	|	Y - dependent variable data
    x				|	independent variable
    low_bound		|	{optional} Minimum index of interest for interpolation
    up_bound		|	{optional} Maximum index of interest for interpolation
    increasing		|	The data is in increasing order
    -----------------------------------------------------------------------------
    Unlike the methods used in HTFProperties, this assumes no storage of indices from call to call.
    Method uses bisection.
    """
    var lb: Int = low_bound if low_bound >= 0 else 0
    var ub: Int = up_bound if up_bound >= 0 else Int((data[].ncols()) - 1)
    if ub < lb: return 0.0
    if ub == lb: return data[].at(1, lb)
    var jl: Int = lb
    var ju: Int = ub
    var jm: Int
    while ju - jl > 1:
        jm = (ju + jl) // 2
        if x < data[].at(0, jm):
            if increasing: ju = jm
            else: jl = jm
        else:
            if increasing: jl = jm
            else: ju = jm
    var y: Float64 = data[].at(1, jl) + (x - data[].at(0, jl)) / (data[].at(0, ju) - data[].at(0, jl)) * (data[].at(1, ju) - data[].at(1, jl))
    if (increasing and y < data[].at(1, lb)) or (not increasing and y > data[].at(1, lb)):
        y = data[].at(1, lb)
    elif (not increasing and y < data[].at(1, lb)) or (increasing and y > data[].at(1, ub)):
        y = data[].at(1, ub)
    return y

def interp(xdat: Pointer[Float64], ydat: Pointer[Float64], x: Float64, low_bound: Int, up_bound: Int, increasing: Bool = True) -> Float64:
    """ 
    Given X and Y data arrays, interpolate along X to find a corresponding 
    value in Y. 
    This is an overload of the matrix_t<> call above. 
    -----------------------------------------------------------------------------
    xdat			|	X - independent variable data
    ydat			|	Y - dependent variable data
    x				|	independent variable
    low_bound		|	Minimum index of interest for interpolation
    up_bound		|	Maximum index of interest for interpolation
    increasing		|	The data is in increasing order
    -----------------------------------------------------------------------------
    Unlike the methods used in HTFProperties, this assumes no storage of indices from call to call.
    Method uses bisection.
    """
    if up_bound < low_bound: return 0.0
    if up_bound == low_bound: return ydat[up_bound]
    var jl: Int = low_bound
    var ju: Int = up_bound
    var jm: Int
    while ju - jl > 1:
        jm = (ju + jl) // 2
        if x < xdat[jm]:
            if increasing: ju = jm
            else: jl = jm
        else:
            if increasing: jl = jm
            else: ju = jm
    var y: Float64 = ydat[jl] + (x - xdat[jl]) / (xdat[ju] - xdat[jl]) * (ydat[ju] - ydat[jl])
    if (increasing and y < ydat[low_bound]) or (not increasing and y > ydat[low_bound]):
        y = ydat[low_bound]
    elif (not increasing and y < ydat[up_bound]) or (increasing and y > ydat[up_bound]):
        y = ydat[up_bound]
    return y

def interp2D(xvals: Pointer[Float64], nx: inout Int, yvals: Pointer[Float64], ny: inout Int, data2D: Pointer[Float64], x: Float64, y: Float64, strict_range: Bool = False) -> Float64:
    """ 
    This method interpolates a 2D array (as a list of information) based on the values of x and y.
    xvals -> size(nx)	|	Positional data along the X dimension. Provide in ascending order
    yvals -> size(ny)	|	Positional data along the Y dimension. Provide in ascending order
    data2D-> size(nx*ny)|	Array containing values to be interpolated. Data provided as (1->ny) for rows (1->nx).
    x					|	basis of interpolation along X
    y					|	basis of interpolation along Y
    strict_range		|	Throw an error if either 'x' or 'y' are outside of the bounds of X and Y
    """
    var xlow: Int = 0
    var xhi: Int = nx - 1
    var xrange: Int = xhi - xlow
    var xmid: Int = xrange // 2
    if strict_range and (x < Float64(xlow) or x > Float64(xhi)):
        return float('nan')
    while xrange > 1:
        if x > xvals[xmid]:
            xlow = xmid
        else:
            xhi = xmid
        if xlow > nx - 2: break
        if xhi < 1: break
        xmid = (xhi + xlow) // 2
        xrange = xhi - xlow
    var ylow: Int = 0
    var yhi: Int = ny - 1
    var yrange: Int = yhi - ylow
    var ymid: Int = yrange // 2
    if strict_range and (y < Float64(ylow) or y > Float64(yhi)):
        return float('nan')
    while yrange > 1:
        if y > yvals[ymid]:
            ylow = ymid
        else:
            yhi = ymid
        if ylow > ny - 2: break
        if yhi < 1: break
        ymid = (yhi + ylow) // 2
        yrange = yhi - ylow
    var xf: Float64 = (x - xvals[xlow]) / (xvals[xhi] - xvals[xlow])
    var yf: Float64 = (y - yvals[ylow]) / (yvals[yhi] - yvals[ylow])
    var p11: Float64 = data2D[ylow * nx + xlow]
    var p12: Float64 = data2D[ylow * nx + xhi]
    var p21: Float64 = data2D[yhi * nx + xlow]
    var p22: Float64 = data2D[yhi * nx + xhi]
    var x1: Float64 = p11 + xf * (p12 - p11)
    var x2: Float64 = p21 + xf * (p22 - p21)
    return x1 + yf * (x2 - x1)

def theta_trans(alpha_sun: Float64, phi_sun: Float64, alpha_fix: Float64, phi_t: inout Float64, theta: inout Float64) -> None:
    """
    Take solar position and convert it into longitudinal and transversal incidence angles
    Reference: G. Zhu (2011). Incidence Angle Modifier for Parabolic Trough Collector and its 
                Measurement at SIMTA. Internal communication, NREL, August, 2011.
    ------------------------------------------------------------------------------------------
    INPUTS:
    ------------------------------------------------------------------------------------------
        *   alpha_sun       [rad] Solar azimuth angle, range is (-90=E..0=S..+90=W)
        *   phi_sun         [rad] Solar zenith angle, zero is directly overhead
        *   alpha_fix       [rad] Angle of rotation of the collector axis. Zero when aligned north-
                            south, positive clockwise
    OUTPUTS:
    ------------------------------------------------------------------------------------------
        *   phi_t           [rad] Collector angle in the transversal plane
        *   theta           [rad] Collector angle in the longitudinal plane
    ------------------------------------------------------------------------------------------
    """
    if phi_sun >= pi / 2.0:
        phi_t = 0.0
        theta = 0.0
        return
    var alpha_sunX: Float64 = alpha_sun + pi
    phi_t = fabs(atan(tan(phi_sun) * sin(alpha_sunX - alpha_fix)))
    theta = fabs(asin(sin(phi_sun) * cos(alpha_sunX - alpha_fix)))
    if theta != theta or phi_t != phi_t:
        phi_t = 0.0
        theta = 0.0
    return

def skytemp(T_amb_K: Float64, T_dp_K: Float64, hour: Float64) -> Float64:
    """
    **********************************************************************
        This function uses the correlation for Sky Temperature             *
        that was provided in Duffie & Beckman (2006), and was              *
        also implemented in EES.                                           *
                                                                            *
        This function takes as inputs:                                     *
        - T_amb -> ambient air temperature, dry bulb [K]                 *
        - T_dp  -> the ambient dewpoint temperature [K]                  *
        - hour  -> the hour, in solar time starting at midnight           *
        The function outputs:                                              *
        - skytemp -> the effective temperature of the sky, in degrees [K]*
                                                                            *
    **********************************************************************
    """
    var T_dpC: Float64
    var time: Float64
    time = hour * 15.0 * pi / 180.0
    T_dpC = T_dp_K - 273.15
    return T_amb_K * pow(.711 + .0056 * T_dpC + .000073 * T_dpC * T_dpC + .013 * cos(time), .25)

def sign(val: Float64) -> Float64:
    if val < 0.0: return -1.0
    else: return 1.0

def nint(val: Float64) -> Float64:
    return fmod(val, 1.0) < 0.5 if floor(val) else ceil(val)

def TOU_Reader(TOUSched: Pointer[Float64], time_sec: Float64, nTOUSched: Int = 8760) -> Int:
    """ Returns the current Time of Use period """
    """ TOUSched should have zero indexed value (all values should be between 0 and 8) """
    var hr: Int = Int(floor(time_sec / 3600.0 + 1.e-6) - 1)
    if hr > nTOUSched - 1 or hr < 0:
        return -1
    return Int(TOUSched[hr])

def poly_eval(x: Float64, coefs: Pointer[Float64], order: inout Int) -> Float64:
    """ 
    Evaluate a polynomial at 'x' with coefficients 'coefs[size=order]'. Return the evaluated result
    """
    var y: Float64 = 0.0
    for i in range(order):
        y += coefs[i] * pow(x, Float64(i))
    return y

def Nusselt_FC(ksDin: Float64, Re: Float64) -> Float64:
    var ksD: Float64 = ksDin
    var Nomval: Float64 = ksD
    var rerun: Int = 0
    var Nu_FC: Float64 = 0.0
    var ValHi: Float64
    var ValLo: Float64
    var Nu_Lo: Float64 = 0.0
    var Nu_Hi: Float64 = 0.0
    var ValHi2: Float64 = 0.0
    var ValLo2: Float64 = 0.0
    var repeat_loop: Bool = True
    while repeat_loop:
        repeat_loop = False
        if ksD < 75.E-5:
            Nu_FC = 0.3 + 0.488 * pow(Re, 0.5) * pow((1.0 + pow(Re / 282000.0, 0.625)), 0.8)
            ValHi = 75.E-5
            ValLo = 0.0
        else:
            if ksD >= 75.E-5 and ksD < 300.E-5:
                ValHi = 300.E-5
                ValLo = 75.E-5
                if Re <= 7.E5:
                    Nu_FC = 0.3 + 0.488 * pow(Re, 0.5) * pow((1.0 + pow(Re / 282000.0, 0.625)), 0.8)
                else:
                    if Re > 7.0E5 and Re < 2.2E7:
                        Nu_FC = 2.57E-3 * pow(Re, 0.98)
                    else:
                        Nu_FC = 0.0455 * pow(Re, 0.81)
            else:
                if ksD >= 300.E-5 and ksD < 900.E-5:
                    ValHi = 900.E-5
                    ValLo = 300.E-5
                    if Re <= 1.8E5:
                        Nu_FC = 0.3 + 0.488 * pow(Re, 0.5) * pow((1.0 + pow(Re / 282000.0, 0.625)), 0.8)
                    else:
                        if Re > 1.8E5 and Re < 4.E6:
                            Nu_FC = 0.0135 * pow(Re, 0.89)
                        else:
                            Nu_FC = 0.0455 * pow(Re, 0.81)
                else:
                    if ksD >= 900.0E-5:
                        ValHi = 900.0E-5
                        ValLo = 900.0E-5
                        if Re <= 1E5:
                            Nu_FC = 0.3 + 0.488 * pow(Re, 0.5) * pow((1.0 + pow(Re / 282000.0, 0.625)), 0.8)
                        else:
                            Nu_FC = 0.0455 * pow(Re, 0.81)
        if rerun != 1:
            rerun = 1
            Nu_Lo = Nu_FC
            ksD = ValHi
            ValLo2 = ValLo
            ValHi2 = ValHi
            repeat_loop = True
    Nu_Hi = Nu_FC
    var chi: Float64
    if Nomval >= 900.E-5:
        chi = 0.0
    else:
        chi = (Nomval - ValLo2) / (ValHi2 - ValLo2)
    Nu_FC = Nu_Lo + (Nu_Hi - Nu_Lo) * chi
    return Nu_FC

def PipeFlow(Re: Float64, Pr: Float64, LoverD: Float64, relRough: Float64, Nusselt: inout Float64, f: inout Float64) -> None:
    /*********************************************************************
    * PipeFlow_turbulent:                                               *
    * This procedure calculates the average Nusselt number and friction *
    * factor for turbulent flow in a pipe given Reynolds number (Re),   *
    * Prandtl number (Pr), the pipe length diameter ratio (LoverD) and  *
    * the relative roughness}                                           *
    *********************************************************************/
    var f_fd: Float64
    var Nusselt_L: Float64
    var Gz: Float64
    var Gm: Float64
    var Nusselt_T: Float64
    var Nusselt_H: Float64
    var fR: Float64
    var X: Float64
    if Re < 2300.0:
        Gz = Re * Pr / LoverD
        X = LoverD / Re
        fR = 3.44 / sqrt(X) + (1.25 / (4.0 * X) + 16.0 - 3.44 / sqrt(X)) / (1.0 + 0.00021 * pow(X, -2.0))
        f = 4.0 * fR / Re
        Gm = pow(Gz, 1.0 / 3.0)
        Nusselt_T = 3.66 + ((0.049 + 0.02 / Pr) * pow(Gz, 1.12)) / (1.0 + 0.065 * pow(Gz, 0.7))
        Nusselt_H = 4.36 + ((0.1156 + 0.08569 / pow(Pr, 0.4)) * Gz) / (1.0 + 0.1158 * pow(Gz, 0.6))
        Nusselt = Nusselt_T
    else:
        f_fd = pow(0.79 * log(Re) - 1.64, -2.0)
        Nusselt_L = ((f_fd / 8.0) * (Re - 1000.0) * Pr) / (1.0 + 12.7 * sqrt(f_fd / 8.0) * (pow(Pr, 2.0 / 3.0) - 1.0))
        if relRough > 1e-5:
            f_fd = pow(-2.0 * log10(2.0 * relRough / 7.4 - 5.02 * log10(2.0 * relRough / 7.4 + 13.0 / Re) / Re), -2.0)
            Nusselt_L = ((f_fd / 8.0) * (Re - 1000.0) * Pr) / (1.0 + 12.7 * sqrt(f_fd / 8.0) * (pow(Pr, 2.0 / 3.0) - 1.0))
        f = f_fd * (1.0 + pow(1.0 / LoverD, 0.7))
        Nusselt = Nusselt_L * (1.0 + pow(1.0 / LoverD, 0.7))

def P_sat4(T_celcius: Float64) -> Float64:
    var T_K: Float64 = T_celcius + 273.15
    return (-99.7450105 + 1.02450484 * T_K - 0.00360264243 * T_K * T_K + 0.00000435512698 * T_K * T_K * T_K) * 1.e5

def f_h_air_T(T_C: Float64) -> Float64:
    return 273474.659 + (1002.9404 * T_C) + (0.0326819988 * T_C * T_C)

def evap_tower(tech_type: Int, P_cond_min: Float64, n_pl_inc: Int, DeltaT_cw_des: Float64, T_approach: Float64, P_cycle: Float64,
               eta_ref: Float64, T_db_K: Float64, T_wb_K: Float64, P_amb: Float64, q_reject: Float64, m_dot_water: inout Float64,
               W_dot_tot: inout Float64, P_cond: inout Float64, T_cond: inout Float64, f_hrsys: inout Float64) -> None:
    # ... (full function body from source) ...
    # For brevity, we include the exact translated code as in the original.
    var T_db: Float64 = T_db_K - 273.15
    var T_wb: Float64 = T_wb_K - 273.15
    var dt_out: Float64 = 3.0
    var drift_loss_frac: Float64 = 0.001
    var blowdown_frac: Float64 = 0.003
    var dp_evap: Float64 = 0.37 * 1.0e5
    var eta_pump: Float64 = 0.75
    var eta_pcw_s: Float64 = 0.8
    var eta_fan: Float64 = 0.75
    var eta_fan_s: Float64 = 0.8
    var p_ratio_fan: Float64 = 1.0025
    var mass_ratio_fan: Float64 = 1.01
    var wp: water_state
    water_TP(max(T_wb, 10.0) + 273.15, P_amb / 1000.0, &wp)
    var c_cw: Float64 = wp.cp * 1000.0
    var q_reject_des: Float64 = P_cycle * (1.0 / eta_ref - 1.0)
    var m_dot_cw_des: Float64 = q_reject_des / (c_cw * DeltaT_cw_des)
    f_hrsys = 1.0
    var m_dot_cw: Float64 = m_dot_cw_des
    var deltat_cw: Float64 = q_reject / (m_dot_cw * c_cw)
    T_cond = T_wb + deltat_cw + dt_out + T_approach
    if tech_type != 4:
        water_TQ(T_cond + 273.15, 1.0, &wp)
        P_cond = wp.pres * 1000.0
    else:
        P_cond = P_sat4(T_cond)
    if (P_cond < P_cond_min) and (tech_type != 4):
        for i in range(2, n_pl_inc + 1):
            f_hrsys = (1.0 - Float64((i - 1) / n_pl_inc))
            m_dot_cw = m_dot_cw_des * f_hrsys
            deltat_cw = q_reject / (m_dot_cw * c_cw)
            T_cond = T_wb + deltat_cw + dt_out + T_approach
            water_TQ(T_cond + 273.15, 1.0, &wp)
            P_cond = wp.pres * 1000.0
            if P_cond > P_cond_min: break
        if P_cond <= P_cond_min:
            P_cond = P_cond_min
            water_PQ(P_cond / 1000.0, 1.0, &wp)
            T_cond = wp.temp - 273.15
            deltat_cw = T_cond - (T_wb + dt_out + T_approach)
            m_dot_cw = q_reject / (deltat_cw * c_cw)
    water_TP(T_cond - 3.0 + 273.15, P_amb / 1000.0, &wp)
    var h_pcw_in: Float64 = wp.enth * 1000.0
    var rho_cw: Float64 = wp.dens
    var h_pcw_out_s: Float64 = (dp_evap / rho_cw) + h_pcw_in
    var h_pcw_out: Float64 = h_pcw_in + ((h_pcw_out_s - h_pcw_in) / eta_pcw_s)
    var w_dot_cw_pump: Float64 = (h_pcw_out - h_pcw_in) * m_dot_cw / eta_pump * 1.0E-6
    var m_dot_air: Float64 = m_dot_cw * mass_ratio_fan
    var t_fan_in: Float64 = (T_db + T_wb + T_approach) / 2.0
    var h_fan_in: Float64 = f_h_air_T(t_fan_in)
    var c_air: Float64 = 1003.0
    var R: Float64 = 8314.0 / 28.97
    var t_fan_in_k: Float64 = t_fan_in + 273.15
    var t_fan_out_k: Float64 = t_fan_in_k * pow(p_ratio_fan, (R / c_air))
    var t_fan_out: Float64 = t_fan_out_k - 273.15
    var h_fan_out_s: Float64 = f_h_air_T(t_fan_out)
    var h_fan_out: Float64 = h_fan_in + (h_fan_out_s - h_fan_in) / eta_fan_s
    var w_dot_fan: Float64 = (h_fan_out - h_fan_in) * m_dot_air / eta_fan * 1.0E-6
    W_dot_tot = w_dot_cw_pump + w_dot_fan
    water_PQ(P_amb / 1000.0, 0.0, &wp)
    var dh_low: Float64 = wp.enth
    water_PQ(P_amb / 1000.0, 1.0, &wp)
    var dh_high: Float64 = wp.enth
    var deltah_evap: Float64 = (dh_high - dh_low) * 1000.0
    var m_dot_evap: Float64 = q_reject / deltah_evap
    var m_dot_drift: Float64 = drift_loss_frac * m_dot_cw
    var m_dot_blowdown: Float64 = blowdown_frac * m_dot_cw
    m_dot_water = m_dot_evap + m_dot_drift + m_dot_blowdown
    T_db = T_db + 273.15
    T_wb = T_wb + 273.15
    T_cond = T_cond + 273.15

def ACC(tech_type: Int, P_cond_min: Float64, n_pl_inc: Int, T_ITD_des: Float64, P_cond_ratio: Float64, P_cycle: Float64, eta_ref: Float64,
        T_db: Float64, P_amb: Float64, q_reject: Float64, m_dot_air: inout Float64, W_dot_fan: inout Float64, P_cond: inout Float64,
        T_cond: inout Float64, f_hrsys: inout Float64) -> None:
    var PvsQT = fn(Q: Float64, T: Float64) -> Float64:
        var a_0: Float64 = 147.96619 - 329.021562 * T + 183.4601872 * pow(T, 2.0)
        var a_1: Float64 = 71.23482281 - 159.2675368 * T + 89.50235831 * pow(T, 2.0)
        var a_2: Float64 = 27.55395547 - 62.24857193 * T + 35.57127305 * pow(T, 2.0)
        var P: Float64 = a_0 + a_1 * Q + a_2 * pow(Q, 2.0)
        return P
    var c_air: Float64 = 1005.0
    var T_db_des_C: Float64 = 42.8
    var T_hot_diff: Float64 = 1.0
    var P_cond_lower_bound_bar: Float64 = 0.036
    var P_cond_min_bar: Float64 = max(P_cond_lower_bound_bar, P_cond_min * 1.e-5)
    var T_db_K: Float64 = T_db
    var T_db_C: Float64 = T_db_K - 273.15
    var Q_rej_des: Float64 = P_cycle * (1.0 / eta_ref - 1.0)
    var m_dot_air_des: Float64 = Q_rej_des / (c_air * (T_ITD_des - T_hot_diff))
    var T: Float64 = T_db_K / (T_db_des_C + 273.15)
    var P_cond_bar: Float64
    if T >= 0.9:
        var Q: Float64 = q_reject / Q_rej_des
        var P: Float64 = PvsQT(Q, T)
        P_cond_bar = P * P_cond_min_bar
    else:
        P_cond_bar = P_cond_min_bar
    var wp: water_state
    var T_cond_K: Float64
    if (P_cond_bar < P_cond_min_bar) and (tech_type != 4):
        for i in range(2, n_pl_inc + 1):
            f_hrsys = 1.0 - (Float64(i - 1) / Float64(n_pl_inc))
            var Q: Float64 = q_reject / (Q_rej_des * f_hrsys)
            var P: Float64 = PvsQT(Q, T)
            P_cond_bar = P * P_cond_min_bar
            if P_cond_bar > P_cond_min_bar: break
        if P_cond_bar <= P_cond_min_bar:
            P_cond_bar = P_cond_min_bar
    else:
        f_hrsys = 1.0
    m_dot_air = m_dot_air_des * f_hrsys
    water_PQ(P_cond_bar * 100.0, 1.0, &wp)
    T_cond_K = wp.temp
    P_cond = P_cond_bar * 1.e5
    T_cond = T_cond_K
    var eta_fan_s: Float64 = 0.85
    var eta_fan: Float64 = 0.97
    var h_fan_in: Float64 = f_h_air_T(T_db_C)
    var MM: Float64 = 28.97
    var R: Float64 = 8314.0 / MM
    var T_fan_in_K: Float64 = T_db_K
    var T_fan_out_K: Float64 = T_fan_in_K * pow(P_cond_ratio, (R / c_air))
    var T_fan_out_C: Float64 = T_fan_out_K - 273.15
    var dT_fan: Float64 = T_fan_out_K - T_fan_in_K
    var h_fan_out_s: Float64 = f_h_air_T(T_fan_out_C)
    var h_fan_out: Float64 = h_fan_in + (h_fan_out_s - h_fan_in) / eta_fan_s
    W_dot_fan = (h_fan_out - h_fan_in) * m_dot_air / eta_fan * 1.0e-6

def HybridHR(tech_type: Int, P_cond_min: Float64, n_pl_inc: Int, F_wc: Float64, F_wcmax: Float64, F_wcmin: Float64,
             T_ITD_des: Float64, T_approach: Float64, dT_cw_ref: Float64, P_cond_ratio: Float64, P_cycle: Float64, eta_ref: Float64,
             T_db: Float64, T_wb: Float64, P_amb: Float64, q_reject: Float64, m_dot_water: inout Float64, W_dot_acfan: inout Float64,
             W_dot_wctot: inout Float64, W_dot_tot: inout Float64, P_cond: inout Float64, T_cond: inout Float64, f_hrsys: inout Float64) -> None:
    # Full function body omitted for brevity; same translation pattern.
    var T_hot_diff: Float64 = 3.0
    var eta_acfan_s: Float64 = 0.8
    var eta_acfan: Float64 = pow(0.98, 3)
    var C_air: Float64 = 1005.0
    var R: Float64 = 286.986538
    var drift_loss_frac: Float64 = 0.001
    var blowdown_frac: Float64 = 0.003
    var dP_evap: Float64 = 0.37 * 1.e5
    var eta_pump: Float64 = 0.75
    var eta_pcw_s: Float64 = 0.8
    var eta_wcfan: Float64 = 0.75
    var eta_wcfan_s: Float64 = 0.8
    var P_ratio_wcfan: Float64 = 1.0025
    var mass_ratio_wcfan: Float64 = 1.01
    var Q_reject_des: Float64 = P_cycle * (1.0 / eta_ref - 1.0)
    var q_ac_des: Float64 = Q_reject_des * (1.0 - F_wcmin)
    var m_dot_acair_des: Float64 = q_ac_des / (C_air * (T_ITD_des - T_hot_diff))
    var q_wc_des: Float64 = Q_reject_des * F_wcmax
    T_db = T_db - 273.15
    T_wb = T_wb - 273.15
    var wp: water_state
    water_TP(max(T_wb, 10.0) + 273.15, P_amb / 1000.0, &wp)
    var c_cw: Float64 = wp.cp * 1000.0
    var m_dot_cw_des: Float64 = q_wc_des / (c_cw * dT_cw_ref)
    var q_ac_rej: Float64 = q_reject * (1.0 - F_wc)
    var q_wc_rej: Float64 = q_reject * F_wc
    var f_hrsyswc: Float64 = 1.0
    var f_hrsysair: Float64 = 1.0
    var dT_air: Float64 = q_ac_rej / (m_dot_acair_des * C_air)
    var T_ITD: Float64 = T_hot_diff + dT_air
    var DeltaT_cw: Float64 = q_wc_rej / (m_dot_cw_des * c_cw)
    var T_condwc: Float64 = T_wb + DeltaT_cw + T_hot_diff + T_approach
    var T_condair: Float64 = T_db + T_ITD
    if F_wc > 0.0:
        T_cond = max(T_condwc, T_condair)
    else:
        T_cond = T_condair
    if tech_type != 4:
        water_TQ(T_cond + 273.15, 1.0, &wp)
        P_cond = wp.pres * 1000.0
    else:
        P_cond = P_sat4(T_cond)
    var m_dot_acair: Float64 = m_dot_acair_des
    var m_dot_cw: Float64 = m_dot_cw_des
    if (P_cond < P_cond_min) and (tech_type != 4):
        var i: Int = 1
        var j: Int = 1
        while True:
            if T_condwc > T_condair:
                i += 1
                f_hrsyswc = (1.0 - Float64((i - 1) / n_pl_inc))
                m_dot_cw = m_dot_cw_des * f_hrsyswc
                DeltaT_cw = q_wc_rej / (m_dot_cw * c_cw)
                T_condwc = T_wb + DeltaT_cw + T_hot_diff + T_approach
            else:
                i += 1
                j += 1
                f_hrsysair = (1.0 - Float64((j - 1) / n_pl_inc))
                m_dot_acair = m_dot_acair_des * f_hrsysair
                dT_air = q_ac_rej / (m_dot_acair * C_air)
                T_condair = T_db + dT_air + T_hot_diff
                f_hrsyswc = (1.0 - Float64((i - 1) / n_pl_inc))
                m_dot_cw = m_dot_cw_des * f_hrsyswc
                DeltaT_cw = q_wc_rej / (m_dot_cw * c_cw)
                T_condwc = T_wb + DeltaT_cw + T_hot_diff + T_approach
            if F_wc > 0.0:
                T_cond = max(T_condwc, T_condair)
            else:
                T_cond = T_condair
            water_TQ(T_cond + 273.15, 1.0, &wp)
            P_cond = wp.pres * 1000.0
            if (i >= n_pl_inc) or (j >= n_pl_inc): break
        if P_cond <= P_cond_min:
            P_cond = P_cond_min
            water_PQ(P_cond / 1000.0, 1.0, &wp)
            T_cond = wp.temp - 273.15
            if T_condwc > T_condair:
                DeltaT_cw = T_cond - (T_wb + T_hot_diff + T_approach)
                m_dot_cw = q_reject / (DeltaT_cw * c_cw)
            else:
                dT_air = T_cond - (T_db + T_hot_diff)
                m_dot_acair = q_reject / (dT_air * C_air)
    f_hrsys = (f_hrsyswc + f_hrsysair) / 2.0
    var h_acfan_in: Float64 = f_h_air_T(T_db)
    var T_acfan_in_K: Float64 = T_db + 273.15
    var T_acfan_out_K: Float64 = T_acfan_in_K * pow(P_cond_ratio, (R / C_air))
    var T_acfan_out: Float64 = T_acfan_out_K - 273.15
    var h_acfan_out_s: Float64 = f_h_air_T(T_acfan_out)
    var h_acfan_out: Float64 = h_acfan_in + (h_acfan_out_s - h_acfan_in) / eta_acfan_s
    W_dot_acfan = (h_acfan_out - h_acfan_in) * m_dot_acair / eta_acfan * 1.e-6
    if q_wc_rej > 0.001:
        water_TP(T_cond - 3.0 + 273.15, P_amb / 1000.0, &wp)
        var h_pcw_in: Float64 = wp.enth * 1000.0
        var rho_cw: Float64 = wp.dens
        var h_pcw_out_s: Float64 = dP_evap / rho_cw + h_pcw_in
        var h_pcw_out: Float64 = h_pcw_in + (h_pcw_out_s - h_pcw_in) / eta_pcw_s
        var W_dot_cw_pump: Float64 = (h_pcw_out - h_pcw_in) * m_dot_cw / eta_pump * 1.e-6
        var m_dot_wcair: Float64 = m_dot_cw * mass_ratio_wcfan
        var T_wcfan_in: Float64 = (T_db + T_wb + T_approach) / 2.0
        var h_wcfan_in: Float64 = f_h_air_T(T_wcfan_in)
        var T_wcfan_in_K: Float64 = T_wcfan_in + 273.15
        var T_wcfan_out_K: Float64 = T_wcfan_in_K * pow(P_ratio_wcfan, (R / C_air))
        var T_wcfan_out: Float64 = T_wcfan_out_K - 273.15
        var h_wcfan_out_s: Float64 = f_h_air_T(T_wcfan_out)
        var h_wcfan_out: Float64 = h_wcfan_in + (h_wcfan_out_s - h_wcfan_in) / eta_wcfan_s
        var W_dot_wcfan: Float64 = (h_wcfan_out - h_wcfan_in) * m_dot_wcair / eta_wcfan * 1.0E-6
        W_dot_wctot = W_dot_cw_pump + W_dot_wcfan
        water_PQ(P_amb / 1000.0, 0.0, &wp)
        var dh_low: Float64 = wp.enth
        water_PQ(P_amb / 1000.0, 1.0, &wp)
        var dh_high: Float64 = wp.enth
        var deltaH_evap: Float64 = (dh_high - dh_low) * 1000.0
        var m_dot_evap: Float64 = q_wc_rej / deltaH_evap
        var m_dot_drift: Float64 = drift_loss_frac * m_dot_cw
        var m_dot_blowdown: Float64 = blowdown_frac * m_dot_cw
        m_dot_water = m_dot_evap + m_dot_drift + m_dot_blowdown
    else:
        m_dot_water = 0.0
        W_dot_wctot = 0.0
    W_dot_tot = W_dot_wctot + W_dot_acfan
    T_db = T_db + 273.15
    T_wb = T_wb + 273.15
    T_cond = T_cond + 273.15

def surface_cond(tech_type: Int, P_cond_min: Float64, n_pl_inc: Int, DeltaT_cw_des: Float64, T_approach: Float64, P_cycle: Float64,
                 eta_ref: Float64, T_db_K: Float64, T_wb_K: Float64, P_amb: Float64, T_cold: Float64, q_reject: Float64,
                 m_dot_water: inout Float64, W_dot_tot: inout Float64, P_cond: inout Float64, T_cond: inout Float64,
                 f_hrsys: inout Float64, T_cond_out: inout Float64) -> None:
    var T_db: Float64 = T_db_K - 273.15
    var T_wb: Float64 = T_wb_K - 273.15
    var dt_out: Float64 = 3.0
    var drift_loss_frac: Float64 = 0.001
    var blowdown_frac: Float64 = 0.003
    var dp_evap: Float64 = 0.37 * 1.0e5
    var eta_pump: Float64 = 0.75
    var eta_pcw_s: Float64 = 0.8
    var eta_fan: Float64 = 0.75
    var eta_fan_s: Float64 = 0.8
    var p_ratio_fan: Float64 = 1.0025
    var mass_ratio_fan: Float64 = 1.01
    var wp: water_state
    water_TP(max(T_cold, 10.0) + 273.15, P_amb / 1000.0, &wp)
    var c_cw: Float64 = wp.cp * 1000.0
    var q_reject_des: Float64 = P_cycle * (1.0 / eta_ref - 1.0)
    var m_dot_cw_des: Float64 = q_reject_des / (c_cw * DeltaT_cw_des)
    f_hrsys = 1.0
    var m_dot_cw: Float64 = m_dot_cw_des
    var deltat_cw: Float64 = q_reject / (m_dot_cw * c_cw)
    T_cond = T_cold + deltat_cw + dt_out
    if tech_type != 4:
        water_TQ(T_cond + 273.15, 1.0, &wp)
        P_cond = wp.pres * 1000.0
    else:
        P_cond = P_sat4(T_cond)
    if (P_cond < P_cond_min) and (tech_type != 4):
        for i in range(2, n_pl_inc + 1):
            f_hrsys = (1.0 - Float64((i - 1) / n_pl_inc))
            m_dot_cw = m_dot_cw_des * f_hrsys
            deltat_cw = q_reject / (m_dot_cw * c_cw)
            T_cond = T_cold + deltat_cw + dt_out
            water_TQ(T_cond + 273.15, 1.0, &wp)
            P_cond = wp.pres * 1000.0
            if P_cond > P_cond_min: break
        if P_cond <= P_cond_min:
            P_cond = P_cond_min
            water_PQ(P_cond / 1000.0, 1.0, &wp)
            T_cond = wp.temp - 273.15
            deltat_cw = T_cond - (T_cold + dt_out)
            m_dot_cw = q_reject / (deltat_cw * c_cw)
    water_TP(T_cond - 3.0 + 273.15, P_amb / 1000.0, &wp)
    var h_pcw_in: Float64 = wp.enth * 1000.0
    var rho_cw: Float64 = wp.dens
    var h_pcw_out_s: Float64 = (dp_evap / rho_cw) + h_pcw_in
    var h_pcw_out: Float64 = h_pcw_in + ((h_pcw_out_s - h_pcw_in) / eta_pcw_s)
    var w_dot_cw_pump: Float64 = (h_pcw_out - h_pcw_in) * m_dot_cw / eta_pump * 1.0E-6
    T_cond_out = T_cond - dt_out
    W_dot_tot = w_dot_cw_pump
    m_dot_water = 0.0
    T_db = T_db + 273.15
    T_wb = T_wb + 273.15
    T_cond = T_cond + 273.15

def eta_pl(mf: Float64) -> Float64:
    return 1.0 - (0.191 - 0.409 * mf + 0.218 * pow(mf, 2.0))

def pipe_sched(De: Float64, selectLarger: Bool = True) -> Float64:
    var D_m: List[Float64] = List[Float64](0.01855, 0.02173, 0.03115, 0.0374, 0.04375, 0.0499, 0.0626,
        0.06880860, 0.08468360, 0.1082040, 0.16146780, 0.2063750, 0.260350, 0.311150, 0.33975040,
        0.39055040, 0.438150, 0.488950, 0.53340, 0.58420, 0.6350, 0.679450, 0.730250, 0.781050,
        0.82864960, 0.87630, 1.02870, 1.16840, 1.32080, 1.47320, 1.62560, 1.7780,
        1.8796, 1.9812, 2.1844, 2.286)
    var np: Int = len(D_m)
    if selectLarger:
        for i in range(np):
            if D_m[i] >= De: return D_m[i]
    else:
        for i in range(np - 1, -1, -1):
            if D_m[i] <= De: return D_m[i]
    var mtoinch: Float64 = 39.3700787
    var buffer: String = "No suitable pipe schedule found for this plant design. Looking for a schedule above " + str(De * mtoinch) + " in ID. Maximum schedule is " + str(D_m[np - 1] * mtoinch) + " in ID. Using the exact pipe diameter instead. Consider increasing the header design velocity range or the number of field subsections."
    return De

def WallThickness(d_in: Float64) -> Float64:
    return 0.0194 * d_in

def MinorPressureDrop(vel: Float64, rho: Float64, k: Float64) -> Float64:
    return k * (vel * vel) * rho / 2.0

def MajorPressureDrop(vel: Float64, rho: Float64, ff: Float64, l: Float64, d: Float64) -> Float64:
    if d <= 0: raise C_csp_exception("The inner diameter must be greater than 0.")
    if vel == 0: return 0.0
    return ff * (vel * vel) * l * rho / (2.0 * d)

def FrictionFactor(rel_rough: Float64, Re: Float64) -> Float64:
    if Re < 2100.0:
        return 64.0 / Re
    elif Re < 4000.0:
        return FricFactor_Iter(rel_rough, Re)
    else:
        return pow(-2.0 * log10(rel_rough / 3.7 - 5.02 / Re * log10(rel_rough / 3.7 - 5.02 / Re * log10(rel_rough / 3.7 + 13.0 / Re))), -2.0)

def FricFactor_Iter(rel_rough: Float64, Re: Float64) -> Float64:
    var Test: Float64
    var TestOld: Float64
    var X: Float64
    var Xold: Float64
    var Slope: Float64
    var Acc: Float64 = 0.01
    var NumTries: Int
    if Re < 2750.0:
        return 64.0 / max(Re, 1.0)
    X = 33.33333
    TestOld = X + 2.0 * log10(rel_rough / 3.7 + 2.51 * X / Re)
    Xold = X
    X = 28.5714
    NumTries = 0
    while NumTries < 21:
        NumTries += 1
        Test = X + 2.0 * log10(rel_rough / 3.7 + 2.51 * X / Re)
        if abs(Test - TestOld) <= Acc:
            return 1.0 / (X * X)
        Slope = (Test - TestOld) / (X - Xold)
        Xold = X
        TestOld = Test
        X = max((Slope * X - Test) / Slope, 1.e-5)
    return 0.0

def mode(v: List[Float64]) -> Float64:
    if len(v) == 0: raise C_csp_exception("Vector size cannot be 0 for mode calculation.")
    if len(v) == 1: return v[0]
    v.sort()
    var mode_val: Float64 = v[0]
    var new_count: Int = 1
    var mode_count: Int = 0
    for i in range(1, len(v)):
        if v[i] == v[i - 1]:
            new_count += 1
        else:
            if new_count > mode_count:
                mode_val = v[i - 1]
                mode_count = new_count
            new_count = 1
    if new_count > mode_count:
        mode_val = v[len(v) - 1]
        mode_count = new_count
    return mode_val

# ------------------------------------------------------------------------------
# Helper template
# ------------------------------------------------------------------------------
def isequal[T: AnyType](a: T, b: T) -> Bool:
    return abs(a - b) <= min(abs(a), abs(b)) * Float64.epsilon

# ------------------------------------------------------------------------------
# Classes
# ------------------------------------------------------------------------------
class P_max_check:
    var P_max: Float64
    var P_save: Float64
    var is_error: Bool
    def __init__(inout self):

    def __del__(inout self):

    def set_P_max(inout self, P_max_set: Float64) -> None:
        self.P_max = P_max_set
        self.P_save = 0.0
        self.is_error = False
    def report_and_reset(inout self) -> None:
        if self.is_error:

        self.P_save = 0.0
        self.is_error = False
    def P_check(inout self, P: Float64) -> Float64:
        if P > self.P_max:
            self.is_error = True
            if P > self.P_save:
                self.P_save = P
            return self.P_max
        return P

class enth_lim:
    var h_min: Float64
    var h_max: Float64
    def __init__(inout self):

    def __del__(inout self):

    def set_enth_limits(inout self, h_min_in: Float64, h_max_in: Float64) -> None:
        self.h_min = h_min_in
        self.h_max = h_max_in
    def check(inout self, h_in: Float64) -> Float64:
        if