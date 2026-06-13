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
from tcstype import *
from htf_props import *
from cavity_calcs import *
from sam_csp_util import *
from lib_util import *
from math import *

/* Cavity Solar Central Receiver
Type 232
Authors: Lukas Feierabend & Soenke Teichel
Converted from Fortran to c++ November 2012 by Ty Neises  */

def TranslateFluxArray(inout fluxarray_2D: util.matrix_t[Float64], inout n_nodes: Int, inout n_panels: Int, inout solarflux: util.matrix_t[Float64]):
    var fluxarray1 = util.matrix_t[Float64](10, n_panels, 0.0)
    if n_panels == 4:
        for i in range(10):
            fluxarray1.at(i,0) = (fluxarray_2D.at(i,0) + fluxarray_2D.at(i,1) + fluxarray_2D.at(i,2)) / 3.0
            fluxarray1.at(i,1) = (fluxarray_2D.at(i,3) + fluxarray_2D.at(i,4) + fluxarray_2D.at(i,5)) / 3.0
            fluxarray1.at(i,2) = (fluxarray_2D.at(i,6) + fluxarray_2D.at(i,7) + fluxarray_2D.at(i,8)) / 3.0
            fluxarray1.at(i,3) = (fluxarray_2D.at(i,9) + fluxarray_2D.at(i,10) + fluxarray_2D.at(i,11)) / 3.0
    if n_nodes == 5:
        for i in range(n_panels):
            solarflux.at(0,i) = (fluxarray1.at(0,i) + fluxarray1.at(1,i)) / 2.0
            solarflux.at(1,i) = (fluxarray1.at(2,i) + fluxarray1.at(3,i)) / 2.0
            solarflux.at(2,i) = (fluxarray1.at(4,i) + fluxarray1.at(5,i)) / 2.0
            solarflux.at(3,i) = (fluxarray1.at(6,i) + fluxarray1.at(7,i)) / 2.0
            solarflux.at(4,i) = (fluxarray1.at(8,i) + fluxarray1.at(9,i)) / 2.0
    return

def PipeFlowCavity(Re: Float64, Pr: Float64, LoverD: Float64, relRough: Float64, q_solar_total: Float64, is_fd: Int, inout Nusselt: Float64, inout f: Float64):
    /* *********************************************************************
    !* PipeFlow_turbulent:              *
    !* This procedure calculates the average Nusselt number and friction *
    !* factor for turbulent flow in a pipe given Reynolds number (Re),   *
    !* Prandtl number (Pr), the pipe length diameter ratio (LoverD) and  *
    !* the relative roughness}             *
    !********************************************************************* */
    if Re < 0.0:
        if q_solar_total > 2.0E+7:
            Re = -5979.08 + 0.00266426 * q_solar_total
        elif q_solar_total > 3.69E+06:
            Re = -14267.6 + 0.00410787 * q_solar_total - 6.40334E-11 * (q_solar_total ** 2)
        else:
            Re = 0.001174 * q_solar_total
    if Pr < 0.0:
        Pr = 5.0
    if Re < 2300.0:
        var Gz = Re * Pr / LoverD    // Eq. 5-79 Nellis and Klein
        var Nusselt_T = 3.66 + ((0.049 + 0.02 / Pr) * (Gz ** 1.12)) / (1.0 + 0.065 * (Gz ** 0.7))    // Eq. 5-80 Nellis and Klein
        Nusselt = Nusselt_T    // Constant temperature Nu is better approximation
    else:
        var f_fd: Float64
        var Nusselt_L: Float64
        if relRough > 1e-5:    // Duct with surface roughness
            f_fd = (-2.0 * log10(2.0 * relRough / 7.4 - 5.02 * log10(2.0 * relRough / 7.4 + 13.0 / Re) / Re)) ** (-2)    // Eq. 5-65
        else:    // Aerodynamically smooth duct
            f_fd = (0.79 * log(Re) - 1.64) ** (-2)    // Eq. 5-63 Nellis and Klein
        Nusselt_L = ((f_fd / 8.0) * (Re - 1000.0) * Pr) / (1.0 + 12.7 * sqrt(f_fd / 8.0) * ((Pr ** (2.0 / 3.0)) - 1.0))    // Eq. 5-84
        if is_fd == 0:    // Flow is fully developed, don't account for developing flow
            f = f_fd
            Nusselt = Nusselt_L
        else:
            f = f_fd * (1.0 + (1.0 / LoverD) ** 0.7)    // Eq. 5-66 Nellis and Klein: account for developing flow
            Nusselt = Nusselt_L * (1.0 + (1.0 / LoverD) ** 0.7)    // !account for developing flow
    return

def FractionFunction(n_nodes: Int, n_panels: Int, n_band: Int, inout T_s_guess_1D: util.matrix_t[Float64], inout lambda_step_band: util.matrix_t[Float64], 
                    inout f_temp_band: util.matrix_t[Float64], inout f_solar_band: util.matrix_t[Float64]):
    /* !integer,parameter,intent(IN)::N_nodes,N_panels
    integer::N_nodes,N_panels,N_band
    real(8),dimension(N_band-1),intent(IN)::lambda_step_band
    real(8),dimension(N_nodes*N_panels+4),intent(IN)::T_sX_array
    !real(8),dimension(N_nodes*N_panels+4)::
    real(8),dimension(N_nodes*N_panels+5,N_band)::f_uni,gamma_array
    real(8),dimension(10)::n
    real(8),dimension(N_nodes*N_panels+4,N_band),intent(OUT):: f_temp_band
    real(8),dimension(N_band),intent(OUT):: f_solar_band
    real(8)::i,k,T_sun,l
    real(8),parameter::pi=3.14159265, C_2=14387.69 */
    var gamma_array = util.matrix_t[Float64](n_nodes * n_panels + 5, n_band, 0.0)
    var f_uni = util.matrix_t[Float64](n_nodes * n_panels + 5, n_band, 0.0)
    var T_sun = 5800.0    // [K] Sun temperature
    var C_2 = 14387.69
    var n = Array[Int](10)
    for i in range(10):
        n[i] = i + 1
    for l in range(n_band - 1):
        for k in range(n_nodes * n_panels + 4):
            gamma_array.at(k, l) = C_2 / (lambda_step_band.at(l, 0) * T_s_guess_1D.at(k, 0))
        gamma_array.at(n_nodes * n_panels + 4, l) = C_2 / (lambda_step_band.at(l, 0) * T_sun)
        for k in range(n_nodes * n_panels + 5):
            var sum_val = 0.0
            for i in range(10):
                sum_val += exp(-n[i] * gamma_array.at(k, l)) / n[i] * (gamma_array.at(k, l) ** 3 + (3.0 * gamma_array.at(k, l) ** 2) / n[i] + (6.0 * gamma_array.at(k, l)) / (n[i] ** 2) + 6.0 / (n[i] ** 3))
            f_uni.at(k, l) = 15.0 / (CSP.pi ** 4) * sum_val
    for l in range(n_band):
        if l == 0:
            for k in range(n_nodes * n_panels + 4):
                f_temp_band.at(k, l) = f_uni.at(k, l)
            f_solar_band.at(l, 0) = f_uni.at(n_nodes * n_panels + 4, l)
        elif l == n_band - 1:
            for k in range(n_nodes * n_panels + 4):
                f_temp_band.at(k, l) = 1.0 - f_uni.at(k, l - 1)
            f_solar_band.at(l, 0) = 1.0 - f_uni.at(n_nodes * n_panels + 4, l - 1)
        else:
            for k in range(n_nodes * n_panels + 4):
                f_temp_band.at(k, l) = f_uni.at(k, l) - f_uni.at(k, l - 1)
            f_solar_band.at(l, 0) = f_uni.at(n_nodes * n_panels + 4, l) - f_uni.at(n_nodes * n_panels + 4, l - 1)
    return

enum P_rec_d_spec: Int = 0
enum P_h_rec: Int = 1
enum P_h_lip: Int = 2
enum P_h_tower: Int = 3
enum P_rec_angle: Int = 4
enum P_d_tube_out: Int = 5
enum P_th_tube: Int = 6
enum P_eta_pump: Int = 7
enum P_hel_stow: Int = 8
enum P_flow_pattern: Int = 9
enum P_HTF: Int = 10
enum P_htf_props: Int = 11
enum P_material: Int = 12
enum P_hl_ffact: Int = 13
enum P_T_htf_hot_des: Int = 14
enum P_T_htf_cold_des: Int = 15
enum P_f_rec_min: Int = 16
enum P_q_rec_des: Int = 17
enum P_rec_su_delay: Int = 18
enum P_rec_qf_delay: Int = 19
enum P_conv_model: Int = 20
enum P_m_dot_htf_max: Int = 21
enum P_eps_wavelength: Int = 22
enum P_conv_coupled: Int = 23
enum P_conv_forced: Int = 24
enum P_h_wind_meas: Int = 25
enum P_conv_wind_dir: Int = 26
enum P_fluxmap_angles: Int = 27
enum P_fluxmap: Int = 28
enum I_azimuth: Int = 29
enum I_zenith: Int = 30
enum I_T_htf_hot: Int = 31
enum I_T_htf_cold: Int = 32
enum I_P_amb: Int = 33
enum I_T_dp: Int = 34
enum I_I_bn: Int = 35
enum I_eta_field: Int = 36
enum I_T_amb: Int = 37
enum I_u_wind: Int = 38
enum I_deg_wind: Int = 39
enum O_m_htf_total: Int = 40
enum O_eta_therm: Int = 41
enum O_W_pump: Int = 42
enum O_Q_conv_loss: Int = 43
enum O_Q_rad_loss: Int = 44
enum O_Q_thermal: Int = 45
enum O_T_htf_hot: Int = 46
enum O_Q_rec_abs: Int = 47
enum O_field_eff_adj: Int = 48
enum O_Q_solar_total: Int = 49
enum O_Q_startup: Int = 50
enum O_availability: Int = 51
enum O_Q_rad_solar: Int = 52
enum O_Q_rad_therm: Int = 53
enum N_MAX: Int = 54

struct tcsvarinfo:
    var type: Int
    var datatype: Int
    var index: Int
    var name: String
    var description: String
    var units: String
    var group: String
    var meta: String
    var meta2: String

var sam_lf_st_pt_type232_variables = Array[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_d_spec,     "rec_d_spec",     "Receiver aperture width",                                     "m",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h_rec,          "h_rec",          "Height of a receiver panel",                                  "m",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h_lip,          "h_lip",          "Height of upper lip of cavity",                               "m",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h_tower,        "h_tower",        "Total height of the solar tower",                             "m",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_angle,      "rec_angle",      "Section of the cavity circle covered in panels",              "deg",   "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_d_tube_out,     "d_tube_out",     "Outer diameter of a single tube",                             "mm",    "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_th_tube,        "th_tube",        "Wall thickness of a single tube",                             "mm",    "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_eta_pump,       "eta_pump",       "Efficiency of HTF pump",                                      "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_hel_stow,       "hel_stow",       "Heliostat field stow/deploy solar angle",                     "deg",   "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_flow_pattern,   "flow_pattern",   "HTF flow scheme through receiver panels",                     "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_HTF,            "htf",            "Flag indicating heat transfer fluid",                         "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_htf_props,      "field_fl_props", "User defined field fluid property data",                      "-",     "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows",        "",        ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_material,       "material",       "Receiver tube material",                                      "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_hl_ffact,       "hl_ffact",       "Heat loss factor (thermal loss fudge factor)",                "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_htf_hot_des,  "T_htf_hot_des",  "Hot HTF outlet temperature at design",                        "C",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_htf_cold_des, "T_htf_cold_des", "Cold HTF outlet temperature at design",                       "C",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_f_rec_min,      "f_rec_min",      "Minimum receiver mass flow rate turndown fraction",           "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_q_rec_des,      "q_rec_des",      "Design-point receiver thermal power output",                  "MWt",   "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_su_delay,   "rec_su_delay",   "Fixed startup delay time for the receiver",                   "hr",    "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_qf_delay,   "rec_qf_delay",   "Energy-based receiver startup delay (frac of rated power)",   "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_conv_model,     "conv_model",     "Type of convection model (1=Clausing, 2=Siebers/Kraabel)",    "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_m_dot_htf_max,  "m_dot_htf_max",  "Maximum receiver mass flow rate",                             "kg/hr", "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_eps_wavelength, "eps_wavelength", "Matrix containing wavelengths, active & passive surface eps", "-",     "3 columns - band-end wavelength (end of final band should be entered but is assumed infinite), active surface emissivity, passive surface emissivity", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_conv_coupled,   "conv_coupled",   "1=coupled, 2=uncoupled",                                      "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_conv_forced,    "conv_forced",    "1=forced (use wind), 0=natural",                              "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_h_wind_meas,    "h_wind_meas",    "Height at which wind measurements are given",                 "m",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_conv_wind_dir,  "conv_wind_dir",  "Wind direction dependent forced convection 1=on 0=off",       "-",     "",    "",  ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_fluxmap_angles, "fluxmap_angles", "Matrix containing zenith and azimuth angles for flux maps",   "-",     "2 columns - azimuth angle, zenith angle. number of rows must equal number of flux maps provided", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_fluxmap,        "fluxmap",        "Matrix containing 10x12 flux map for various solar positions","-",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_azimuth,        "azimuth",        "0 at due north, ranges clockwise from 0 to 360",              "deg",   "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_zenith,         "zenith",         "solar zenith angle",                                          "deg",   "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_htf_hot,      "T_htf_hot",      "Target hot outlet temperature of the working fluid",          "C",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_htf_cold,     "T_htf_cold",     "Inlet temperature of the HTF",                                "C",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_amb,          "P_amb",          "Ambient pressure",                                            "atm",   "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_dp,           "T_dp",           "Dew point temperature",                                       "C",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_I_bn,           "I_bn",           "Direct normal irradiation",                                   "W/m2",  "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_eta_field,      "eta_field",      "Overall efficiency of heliostat field",                       "-",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_amb,          "T_amb",          "Ambient temperature",                                         "C",     "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_u_wind,         "u_wind",         "Wind velocity",                                               "m/s",   "",    "",  ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_deg_wind,       "deg_wind",       "Wind direction",                                              "deg",   "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_m_htf_total,   "m_htf_total",    "Total mass flow rate of the working fluid",                   "kg/hr", "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_eta_therm,     "eta_therm",      "Thermal efficiency of the receiver",                          "-",     "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_pump,        "W_pump",         "Estimated power for pumping the working fluid",               "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_conv_loss,   "Q_conv_loss",    "Thermal convection losses from the receiver",                 "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_rad_loss,    "Q_rad_loss",     "Radiation losses from the receiver",                          "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_thermal,     "Q_thermal",      "Thermal energy absorbed by the heat transfer fluid",          "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_htf_hot,     "T_htf_hot_out",  "Outlet temperature of the heat transfer fluid",               "C",     "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_rec_abs,     "Q_rec_abs",      "Receiver power prior to thermal losses",                      "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_field_eff_adj, "field_eff_adj",  "Adjusted heliostat field efficiency - includes defocus",      "-",     "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_solar_total, "Q_solar_total",  "Total incident power on the receiver",                        "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_startup,     "Q_startup",      "Startup energy consumed during the current time step",        "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_availability,  "availability",   "Availability of the solar tower",                             "hr",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_rad_solar,   "Q_rad_solar",    "Solar radiation losses from the receiver",                    "MW",    "",    "",  ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_rad_therm,   "Q_therm_solar",  "Thermal radiation losses from the receiver",                  "MW",    "",    "",  ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID,  N_MAX,        "",             "", "", "", "", "")
)

class sam_lf_st_pt_type232(tcstypeinterface):
    var rec_htf: HTFProperties
    var tube_mat: HTFProperties
    var cavity: Cavity_Calcs
    var m_n_nodes: Int
    var m_n_panels: Int
    var m_n_coils: Int
    var m_night_recirc: Int
    var m_n_45_bends: Int
    var m_n_90_bends: Int
    var m_L_e_45: Float64
    var m_L_e_90: Float64
    var m_eta_thermal_guess: Float64
    var m_n_rays: Int
    var rec_d_spec: Float64
    var h_rec: Float64
    var h_lip: Float64
    var h_tower: Float64
    var rec_angle: Float64
    var d_tube_out: Float64
    var th_tube: Float64
    var eta_pump: Float64
    var hel_stow: Float64
    var flow_pattern: Int
    var htf: Int
    var material: Int
    var hl_ffact: Float64
    var T_htf_hot_des: Float64
    var T_htf_cold_des: Float64
    var f_rec_min: Float64
    var q_rec_des: Float64
    var rec_su_delay: Float64
    var rec_qf_delay: Float64
    var conv_model: Int
    var m_dot_htf_max: Float64
    var n_bands: Int
    var conv_coupled: Int
    var conv_forced: Int
    var h_wind_meas: Float64
    var conv_wind_dir: Int
    var fluxmap_angles: util.matrix_t[Float64]
    var fluxmap: util.matrix_t[Float64]
    var num_sol_pos: Int
    var A_array: Array[Float64]
    var e_band_array: util.matrix_t[Float64]
    var lambda_step_band: util.matrix_t[Float64]
    var is_fd: util.matrix_t[Float64]
    var F_hat: util.block_t[Float64]
    var r_rec: Float64
    var tol_od: Float64
    var m_dot_htf_des: Float64
    var m_dot_htf_min: Float64
    var A_node: Float64
    var q_solar_critical: Float64
    var A_tube: Float64
    var n_tubes: Int
    var d_tube_in: Float64
    var L_over_D: Float64
    var L_over_D_p: Float64
    var relRough: Float64
    var L_tube_node: Float64
    var max_eps_active: Float64
    var A_f: Float64
    var A_lip: Float64
    var W_panel: Float64
    var tolerance: Float64
    var mode: Int
    var E_su_prev: Float64
    var E_su: Float64
    var t_su_prev: Float64
    var t_su: Float64
    var itermode: Int
    var od_control: Float64
    var flux_array_2D: util.matrix_t[Float64]
    var solarflux: util.matrix_t[Float64]
    var q_solar: util.matrix_t[Float64]
    var q_solar_panel: util.matrix_t[Float64]
    var T_s: util.matrix_t[Float64]
    var T_s_guess: util.matrix_t[Float64]
    var T_htf_guess: util.matrix_t[Float64]
    var T_htf: util.matrix_t[Float64]
    var T_htf_ave: util.matrix_t[Float64]
    var T_htf_ave_guess: util.matrix_t[Float64]
    var m_htf_guess: util.matrix_t[Float64]
    var T_htf_hot_guess: util.matrix_t[Float64]
    var m_htf: util.matrix_t[Float64]
    var h_conv: util.matrix_t[Float64]
    var q_conv: util.matrix_t[Float64]
    var T_htf_guess_mid: util.matrix_t[Float64]
    var T_s_guess_mid_1D: util.matrix_t[Float64]
    var T_htf_ave_guess_mid: util.matrix_t[Float64]
    var flux_1D: util.matrix_t[Float64]
    var T_s_1D: util.matrix_t[Float64]
    var T_s_guess_1D: util.matrix_t[Float64]
    var h_rad_semi_gray_therm: util.matrix_t[Float64]
    var q_rad_solar: util.matrix_t[Float64]
    var q_rad_solar_net: util.matrix_t[Float64]
    var UA_1DIM: util.matrix_t[Float64]
    var T_htf_ave_1D: util.matrix_t[Float64]
    var q_htf_1D: util.matrix_t[Float64]
    var f_temp_band: util.matrix_t[Float64]
    var f_solar_band: util.matrix_t[Float64]
    var q_rad_therm: util.matrix_t[Float64]
    var q_rad_semi_gray: util.matrix_t[Float64]
    var q_rad_therm_net: util.matrix_t[Float64]
    var q_rad_semi_gray_net: util.matrix_t[Float64]
    var q_htf: util.matrix_t[Float64]
    var q_htf_panel: util.matrix_t[Float64]
    var error_temp: util.matrix_t[Float64]
    var error_flow: util.matrix_t[Float64]
    var deltaP_node: util.matrix_t[Float64]
    var T_htf_ave_guess_1D: util.matrix_t[Float64]
    var rho_htf_p: util.matrix_t[Float64]
    var u_htf_p: util.matrix_t[Float64]
    var f_htf_p: util.matrix_t[Float64]
    var m_htf_p: util.matrix_t[Float64]

    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        tcstypeinterface.__init__(self, cxt, ti)
        self.m_n_nodes = 5
        self.m_n_panels = 4
        self.m_n_coils = 6
        self.m_night_recirc = 0
        self.m_n_45_bends = 0
        self.m_n_90_bends = 4 * self.m_n_coils
        self.m_L_e_45 = 16.0
        self.m_L_e_90 = 30.0
        self.m_eta_thermal_guess = 0.85
        self.m_n_rays = 300000
        self.rec_d_spec = float64.nan
        self.h_rec = float64.nan
        self.h_lip = float64.nan
        self.h_tower = float64.nan
        self.rec_angle = float64.nan
        self.d_tube_out = float64.nan
        self.th_tube = float64.nan
        self.eta_pump = float64.nan
        self.hel_stow = float64.nan
        self.flow_pattern = -1
        self.htf = -1
        self.material = -1
        self.hl_ffact = float64.nan
        self.T_htf_hot_des = float64.nan
        self.T_htf_cold_des = float64.nan
        self.f_rec_min = float64.nan
        self.q_rec_des = float64.nan
        self.rec_su_delay = float64.nan
        self.rec_qf_delay = float64.nan
        self.conv_model = -1
        self.m_dot_htf_max = float64.nan
        self.n_bands = -1
        self.fluxmap_angles = util.matrix_t[Float64](0.0)
        self.fluxmap = util.matrix_t[Float64](0.0)
        self.num_sol_pos = -1
        self.conv_coupled = -1
        self.conv_forced = -1
        self.h_wind_meas = float64.nan
        self.conv_wind_dir = -1
        self.A_array = Array[Float64](self.m_n_nodes * self.m_n_panels + 4)
        self.e_band_array = util.matrix_t[Float64](0.0)
        self.lambda_step_band = util.matrix_t[Float64](0.0)
        self.is_fd = util.matrix_t[Float64](0.0)
        self.F_hat = util.block_t[Float64](0.0)
        self.r_rec = float64.nan
        self.tol_od = float64.nan
        self.m_dot_htf_des = float64.nan
        self.m_dot_htf_min = float64.nan
        self.A_node = float64.nan
        self.q_solar_critical = float64.nan
        self.A_tube = float64.nan
        self.n_tubes = -1
        self.d_tube_in = float64.nan
        self.L_over_D = float64.nan
        self.L_over_D_p = float64.nan
        self.relRough = float64.nan
        self.L_tube_node = float64.nan
        self.max_eps_active = float64.nan
        self.A_f = float64.nan
        self.A_lip = float64.nan
        self.W_panel = float64.nan
        self.tolerance = float64.nan
        self.mode = -1
        self.E_su_prev = float64.nan
        self.E_su = float64.nan
        self.t_su_prev = float64.nan
        self.t_su = float64.nan
        self.itermode = -1
        self.od_control = float64.nan

    def __del__(inout self):
        # A_array is automatically freed

    def init(inout self) -> Int:
        self.rec_d_spec = self.value(P_rec_d_spec)
        self.h_rec = self.value(P_h_rec)
        self.h_lip = self.value(P_h_lip)
        self.h_tower = self.value(P_h_tower)
        self.rec_angle = self.value(P_rec_angle) * CSP.pi / 180.0
        self.d_tube_out = self.value(P_d_tube_out) / 1000.0
        self.th_tube = self.value(P_th_tube) / 1000.0
        self.eta_pump = self.value(P_eta_pump)
        self.hel_stow = self.value(P_hel_stow)
        self.flow_pattern = Int(self.value(P_flow_pattern))
        self.htf = Int(self.value(P_HTF))
        if self.htf != HTFProperties.User_defined:
            if not self.rec_htf.SetFluid(self.htf):
                self.message(TCS_ERROR, "Receiver HTF code is not recognized")
                return -1
        else:
            var htf_rows = 0
            var htf_cols = 0
            var fl_mat = self.value(P_htf_props, &htf_rows, &htf_cols)
            if fl_mat != 0 and htf_rows > 2 and htf_cols == 7:
                var mat = util.matrix_t[Float64](htf_rows, htf_cols, 0.0)
                for r in range(htf_rows):
                    for c in range(htf_cols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(P_htf_props), r, c)
                if not self.rec_htf.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, "user defined htf property table was invalid (rows=%d cols=%d)", htf_rows, htf_cols)
                    return -1
            else:
                self.message(TCS_ERROR, "The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", htf_rows, htf_cols)
                return -1
        self.material = Int(self.value(P_material))
        if self.material != HTFProperties.User_defined:
            self.tube_mat.SetFluid(self.material)
        else:
            self.message(TCS_ERROR, "user defined properties are not an option for tubing material. Select an available material number.")
            return -1
        self.hl_ffact = self.value(P_hl_ffact)
        self.T_htf_hot_des = self.value(P_T_htf_hot_des) + 273.15
        self.T_htf_cold_des = self.value(P_T_htf_cold_des) + 273.15
        self.f_rec_min = self.value(P_f_rec_min)
        self.q_rec_des = self.value(P_q_rec_des) * 1.0E6
        self.rec_su_delay = self.value(P_rec_su_delay)
        self.rec_qf_delay = self.value(P_rec_qf_delay)
        self.conv_model = Int(self.value(P_conv_model))
        self.m_dot_htf_max = self.value(P_m_dot_htf_max) / 3600.0
        self.conv_coupled = Int(self.value(P_conv_coupled))
        self.conv_forced = Int(self.value(P_conv_forced))
        self.h_wind_meas = self.value(P_h_wind_meas)
        self.conv_wind_dir = Int(self.value(P_conv_wind_dir))
        var eps_rows = 0
        var eps_cols = 0
        var p_eps = self.value(P_eps_wavelength, &eps_rows, &eps_cols)
        var eps_wavelength = util.matrix_t[Float64](eps_rows, eps_cols)
        if p_eps != 0 and eps_rows > 0 and eps_cols == 3:
            for r in range(eps_rows):
                for c in range(eps_cols):
                    eps_wavelength.at(r, c) = TCS_MATRIX_INDEX(self.var(P_eps_wavelength), r, c)
        self.n_bands = eps_rows
        self.max_eps_active = 0.0
        for i in range(eps_rows):
            self.max_eps_active = max(self.max_eps_active, eps_wavelength.at(i, 1))
        self.lambda_step_band.resize(self.n_bands, 1)
        for l in range(self.n_bands):
            self.lambda_step_band.at(l, 0) = eps_wavelength.at(l, 0)
        var angle_rows = 0
        var angle_cols = 0
        var p_angle = self.value(P_fluxmap_angles, &angle_rows, &angle_cols)
        self.fluxmap_angles.resize(angle_rows, angle_cols)
        if p_angle != 0 and angle_rows == 2 and angle_cols > 3:
            for r in range(angle_rows):
                for c in range(angle_cols):
                    self.fluxmap_angles.at(r, c) = TCS_MATRIX_INDEX(self.var(P_fluxmap_angles), r, c)
        else:
            self.message(TCS_ERROR, "Flux map solar position input is incorrect P_fluxmap_angles: %d x %d", angle_rows, angle_cols)
            return -1
        self.num_sol_pos = angle_cols
        var flux_rows = 0
        var flux_cols = 0
        var p_flux = self.value(P_fluxmap, &flux_rows, &flux_cols)
        if flux_rows != self.num_sol_pos:
            self.message(TCS_ERROR, "Number of flux maps is not equal to number of solar positions")
            return -1
        self.fluxmap.resize(flux_rows, flux_cols)
        if p_flux != 0 and flux_cols == 120:
            for r in range(flux_rows):
                for c in range(flux_cols):
                    self.fluxmap.at(r, c) = TCS_MATRIX_INDEX(self.var(P_fluxmap), r, c)
        else:
            self.message(TCS_ERROR, "Flux map input is incorrect")
            return -1
        self.r_rec = self.rec_d_spec / 2.0
        self.itermode = 1
        self.tol_od = 0.001
        self.od_control = 1.0
        var c_htf_des = self.rec_htf.Cp((self.T_htf_hot_des + self.T_htf_cold_des) / 2.0) * 1000.0
        self.m_dot_htf_des = self.q_rec_des / (c_htf_des * (self.T_htf_hot_des - self.T_htf_cold_des))
        self.m_dot_htf_min = self.m_dot_htf_des * self.f_rec_min
        self.q_solar_critical = self.q_rec_des / self.m_eta_thermal_guess / self.max_eps_active * self.f_rec_min
        self.E_su_prev = self.q_rec_des * self.rec_qf_delay
        self.t_su_prev = self.rec_su_delay
        self.cavity.Define_Cavity(self.m_n_rays, self.h_rec, self.r_rec, self.rec_angle, self.h_lip)
        var F_AF = Array[Float64](self.m_n_nodes)
        var F_BF = Array[Float64](self.m_n_nodes)
        var F_LCE = 0.0
        var F_LF = 0.0
        var F_OCE = 0.0
        var F_OF = 0.0
        var F_FCE = 0.0
        self.cavity.OuterPanel_Floor(F_AF)
        self.cavity.InnerPanel_Floor(F_BF)
        self.cavity.Lip_Ceiling(F_LCE)
        self.cavity.Lip_Floor(F_LF)
        self.cavity.Opening_Ceiling(F_OCE)
        self.cavity.Opening_Floor(F_OF)
        var F_AA = util.matrix_t[Float64](self.cavity.m_n_nodes, self.cavity.m_n_nodes, 0.0)
        var F_AB = util.matrix_t[Float64](self.cavity.m_n_nodes, self.cavity.m_n_nodes, 0.0)
        var F_AC = util.matrix_t[Float64](self.cavity.m_n_nodes, self.cavity.m_n_nodes, 0.0)
        var F_AD = util.matrix_t[Float64](self.cavity.m_n_nodes, self.cavity.m_n_nodes, 0.0)
        var F_AO = Array[Float64](self.m_n_nodes)
        var F_AL = Array[Float64](self.m_n_nodes)
        var F_BO = Array[Float64](self.m_n_nodes)
        var F_BL = Array[Float64](self.m_n_nodes)
        self.cavity.PanelViewFactors(F_AB, F_AC, F_AD, F_AO, F_AL, F_BO, F_BL)
        var h_node: Float64
        var alpha: Float64
        var W_aperture: Float64
        var z: Float64
        self.cavity.GetGeometry(h_node, alpha, self.W_panel, W_aperture, z)
        self.A_node = self.W_panel * h_node
        self.A_f = 2.0 * self.W_panel * self.r_rec * cos(alpha / 2.0) + z * W_aperture
        var A_ce = self.A_f
        self.A_lip = self.h_lip * W_aperture
        var A_o = (self.h_rec - self.h_lip) * W_aperture
        self.n_tubes = Int(self.h_rec / (2.0 * Float64(self.m_n_coils) * self.d_tube_out))
        self.d_tube_in = self.d_tube_out - 2.0 * self.th_tube
        self.A_tube = 0.25 * CSP.pi * (self.d_tube_in ** 2)
        var L_tube = 2.0 * Float64(self.m_n_coils) * self.W_panel
        self.L_tube_node = L_tube / Float64(self.m_n_nodes)
        self.L_over_D = self.L_tube_node / self.d_tube_in
        self.L_over_D_p = L_tube / self.d_tube_in
        self.relRough = (4.5e-5) / self.d_tube_in
        for j in range(1, self.m_n_nodes):
            for i in range(j + 1):
                F_AB.at(i, j) = F_AB.at(j - i, 0)
                F_AC.at(i, j) = F_AC.at(j - i, 0)
                F_AD.at(i, j) = F_AD.at(j - i, 0)
        for j in range(1, self.m_n_nodes):
            for i in range(j + 1, self.m_n_nodes):
                F_AB.at(i, j) = F_AB.at(i - j, 0)
                F_AC.at(i, j) = F_AC.at(i - j, 0)
                F_AD.at(i, j) = F_AD.at(i - j, 0)
        var sum_AF = 0.0
        var sum_BF = 0.0
        for i in range(self.m_n_nodes):
            sum_AF += F_AF[i]
            sum_BF += F_BF[i]
        F_FCE = 1.0 - ((sum_AF + sum_BF) * 2.0 * self.A_node + F_LF * self.A_lip + F_OF * A_o) / self.A_f
        var F_L = util.matrix_t[Float64](self.m_n_nodes, self.m_n_panels, 0.0)
        var F_O = util.matrix_t[Float64](self.m_n_nodes, self.m_n_panels, 0.0)
        var F_F = util.matrix_t[Float64](self.m_n_nodes, self.m_n_panels, 0.0)
        for i in range(self.m_n_nodes):
            F_L.at(i, 0) = F_AL[i]
            F_L.at(i, 1) = F_BL[i]
            F_L.at(i, 2) = F_BL[i]
            F_L.at(i, 3) = F_AL[i]
            F_O.at(i, 0) = F_AO[i]
            F_O.at(i, 1) = F_BO[i]
            F_O.at(i, 2) = F_BO[i]
            F_O.at(i, 3) = F_AO[i]
            F_F.at(i, 0) = F_AF[i]
            F_F.at(i, 1) = F_BF[i]
            F_F.at(i, 2) = F_BF[i]
            F_F.at(i, 3) = F_AF[i]
        var F_view = util.matrix_t[Float64](self.m_n_nodes * self.m_n_panels + 4, self.m_n_nodes * self.m_n_panels + 4, 0.0)
        for i in range(self.m_n_nodes):
            for j in range(self.m_n_nodes):
                F_view.at(i, j + self.m_n_nodes) = F_AB.at(i, j)
                F_view.at(i, j + 2 * self.m_n_nodes) = F_AC.at(i, j)
                F_view.at(i, j + 3 * self.m_n_nodes) = F_AD.at(i, j)
                F_view.at(i + self.m_n_nodes, j + 2 * self.m_n_nodes) = F_view.at(i, j + self.m_n_nodes)
                F_view.at(i + 2 * self.m_n_nodes, j + 3 * self.m_n_nodes) = F_view.at(i, j + self.m_n_nodes)
                F_view.at(i + self.m_n_nodes, j + 3 * self.m_n_nodes) = F_view.at(i, j + 2 * self.m_n_nodes)
                F_view.at(i, j) = 0.0
                F_view.at(i + self.m_n_nodes, j + self.m_n_nodes) = 0.0
                F_view.at(i + 2 * self.m_n_nodes, j + 2 * self.m_n_nodes) = 0.0
                F_view.at(i + 3 * self.m_n_nodes, j + 3 * self.m_n_nodes) = 0.0
        for i in range(4 * self.m_n_nodes, 4 * self.m_n_nodes + 4):
            F_view.at(i, i) = 0.0
        for i in range(self.m_n_nodes):
            F_view.at(i, self.m_n_panels * self.m_n_nodes) = F_AF[i]
            F_view.at(i, self.m_n_panels * self.m_n_nodes + 1) = F_AF[self.m_n_nodes - 1 - i]
            F_view.at(i, self.m_n_panels * self.m_n_nodes + 2) = F_L.at(i, 0)
            F_view.at(i, self.m_n_panels * self.m_n_nodes + 3) = F_O.at(i, 0)
            F_view.at(i + self.m_n_nodes, self.m_n_panels * self.m_n_nodes) = F_BF[i]
            F_view.at(i + self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 1) = F_BF[self.m_n_nodes - 1 - i]
            F_view.at(i + self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 2) = F_L.at(i, 1)
            F_view.at(i + self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 3) = F_O.at(i, 1)
            F_view.at(i + 2 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes) = F_BF[i]
            F_view.at(i + 2 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 1) = F_BF[self.m_n_nodes - 1 - i]
            F_view.at(i + 2 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 2) = F_L.at(i, 2)
            F_view.at(i + 2 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 3) = F_O.at(i, 2)
            F_view.at(i + 3 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes) = F_AF[i]
            F_view.at(i + 3 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 1) = F_AF[self.m_n_nodes - 1 - i]
            F_view.at(i + 3 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 2) = F_L.at(i, 3)
            F_view.at(i + 3 * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 3) = F_O.at(i, 3)
        for i in range(self.m_n_panels * self.m_n_nodes):
            self.A_array[i] = self.A_node
        self.A_array[self.m_n_panels * self.m_n_nodes] = self.A_f
        self.A_array[self.m_n_panels * self.m_n_nodes + 1] = A_ce
        self.A_array[self.m_n_panels * self.m_n_nodes + 2] = self.A_lip
        self.A_array[self.m_n_panels * self.m_n_nodes + 3] = A_o
        for i in range(self.m_n_panels * self.m_n_nodes + 4):
            for j in range(self.m_n_panels * self.m_n_nodes + 4):
                F_view.at(j, i) = (self.A_array[i] * F_view.at(i, j)) / self.A_array[j]
        F_view.at(4 * self.m_n_nodes + 2, 4 * self.m_n_nodes) = F_LF
        F_view.at(4 * self.m_n_nodes, 4 * self.m_n_nodes + 2) = (self.A_array[4 * self.m_n_nodes + 2] * F_view.at(4 * self.m_n_nodes + 2, 4 * self.m_n_nodes)) / self.A_array[4 * self.m_n_nodes]
        F_view.at(4 * self.m_n_nodes + 3, 4 * self.m_n_nodes) = F_OF
        F_view.at(4 * self.m_n_nodes, 4 * self.m_n_nodes + 3) = (self.A_array[4 * self.m_n_nodes + 3] * F_view.at(4 * self.m_n_nodes + 3, 4 * self.m_n_nodes)) / self.A_array[4 * self.m_n_nodes]
        F_view.at(4 * self.m_n_nodes + 2, 4 * self.m_n_nodes + 1) = F_LCE
        F_view.at(4 * self.m_n_nodes + 1, 4 * self.m_n_nodes + 2) = (self.A_array[4 * self.m_n_nodes + 2] * F_view.at(4 * self.m_n_nodes + 2, 4 * self.m_n_nodes + 1)) / self.A_array[4 * self.m_n_nodes + 1]
        F_view.at(4 * self.m_n_nodes + 3, 4 * self.m_n_nodes + 1) = F_OCE
        F_view.at(4 * self.m_n_nodes + 1, 4 * self.m_n_nodes + 3) = (self.A_array[4 * self.m_n_nodes + 3] * F_view.at(4 * self.m_n_nodes + 3, 4 * self.m_n_nodes + 1)) / self.A_array[4 * self.m_n_nodes + 1]
        F_view.at(4 * self.m_n_nodes, 4 * self.m_n_nodes + 1) = F_FCE
        F_view.at(4 * self.m_n_nodes + 1, 4 * self.m_n_nodes) = (self.A_array[4 * self.m_n_nodes] * F_view.at(4 * self.m_n_nodes, 4 * self.m_n_nodes + 1)) / self.A_array[4 * self.m_n_nodes + 1]
        F_view.at(4 * self.m_n_nodes + 2, 4 * self.m_n_nodes + 3) = 0.0
        F_view.at(4 * self.m_n_nodes + 3, 4 * self.m_n_nodes + 2) = 0.0
        self.e_band_array.resize(self.m_n_nodes * self.m_n_panels + 4, self.n_bands)
        for j in range(eps_rows):
            for i in range(self.m_n_panels * self.m_n_nodes):
                self.e_band_array.at(i, j) = eps_wavelength.at(j, 1)
            for i in range(self.m_n_panels * self.m_n_nodes, self.m_n_panels * self.m_n_nodes + 3):
                self.e_band_array.at(i, j) = eps_wavelength.at(j, 2)
            self.e_band_array.at(self.m_n_panels * self.m_n_nodes + 3, j) = 1.0
        self.F_hat.resize(self.m_n_panels * self.m_n_nodes + 4, self.m_n_panels * self.m_n_nodes + 4, self.n_bands)
        var F_hat_guess = util.block_t[Float64](self.m_n_panels * self.m_n_nodes + 4, self.m_n_panels * self.m_n_nodes + 4, eps_rows)
        var error_array = util.matrix_t[Float64](self.m_n_panels * self.m_n_nodes + 4, self.m_n_panels * self.m_n_nodes + 4)
        for k in range(eps_rows):
            for i in range(self.m_n_panels * self.m_n_nodes + 4):
                for j in range(self.m_n_panels * self.m_n_nodes + 4):
                    self.F_hat.at(i, j, k) = F_view.at(i, j)
            var err_f_hat = 9999.0
