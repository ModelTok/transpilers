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
from tcstype import tcscontext, tcstypeinfo, tcsvarinfo, TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_INVALID, TCS_ERROR, TCS_IMPLEMENT_TYPE
from sam_csp_util import CSP
from math import sin, cos, sqrt, pow, abs

enum:
    P_REC_TYPE = 0
    P_TRANSMITTANCE_COVER = 1
    P_MANUFACTURER = 2
    P_ALPHA_ABSORBER = 3
    P_A_ABSORBER = 4
    P_ALPHA_WALL = 5
    P_A_WALL = 6
    P_L_INSULATION = 7
    P_K_INSULATION = 8
    P_D_CAV = 9
    P_P_CAV = 10
    P_L_CAV = 11
    P_DELTA_T_DIR = 12
    P_DELTA_T_REFLUX = 13
    P_T_HEATER_HEAD_HIGH = 14
    P_T_HEATER_HEAD_LOW = 15
    I_POWER_IN_REC = 16
    I_T_AMB = 17
    I_P_ATM = 18
    I_WIND_SPEED = 19
    I_SUN_ANGLE = 20
    I_N_COLLECTORS = 21
    I_DNI = 22
    I_I_CUT_IN = 23
    I_D_AP = 24
    O_P_OUT_REC = 25
    O_Q_REC_LOSSES = 26
    O_ETA_REC = 27
    O_T_HEATER_HEAD_OPERATE = 28
    O_Q_RAD_REFLECTION = 29
    O_Q_RAD_EMISSION = 30
    O_Q_CONV = 31
    O_Q_COND = 32
    N_MAX = 33

var sam_pf_dish_receiver_type296_variables: List[tcsvarinfo] = List[
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_REC_TYPE,            "rec_type",           "Receiver type (always = 1)",                   "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_TRANSMITTANCE_COVER, "transmittance_cover","Transmittance cover (always = 1)",             "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_MANUFACTURER,        "manufacturer",       "Manufacturer (always=5)",                      "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ALPHA_ABSORBER,      "alpha_absorber",     "Absorber absorptance",                         "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_A_ABSORBER,          "A_absorber",         "Absorber surface area",                        "m^2", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_ALPHA_WALL,          "alpha_wall",         "Cavity absorptance",                           "-",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_A_WALL,              "A_wall",             "Cavity surface area",                          "m^2", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_L_INSULATION,        "L_insulation",       "Insulation thickness",                         "m",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_K_INSULATION,        "k_insulation",       "Insulation thermal conductivity",              "W/m-K", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_D_CAV,               "d_cav",              "Internal diameter of cavity perp to aperture", "m",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_P_CAV,               "P_cav",              "Internal cavity pressure with aperture covered","kPa", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_L_CAV,               "L_cav",              "Internal depth of cavity perp to aperture",    "m",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_DELTA_T_DIR,         "DELTA_T_DIR",        "Delta temperature for DIR receiver",           "K",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_DELTA_T_REFLUX,      "DELTA_T_REFLUX",     "Delta temp for REFLUX receiver (always = 40)", "K",   "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_HEATER_HEAD_HIGH,  "T_heater_head_high",	"Heater Head Set Temperature",               "K", "", "", ""),   
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_HEATER_HEAD_LOW,   "T_heater_head_low",		"Header Head Lowest Temperature",            "K", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_POWER_IN_REC,        "Power_in_rec",          "Power entering the receiver from the collector", "kW", "", "", ""),    
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_AMB,               "T_amb",					"Ambient temperature in Kelvin",                  "K", "", "", ""),   
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_ATM,               "P_atm",					"Atmospheric pressure",                           "Pa", "", "", ""),   
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_WIND_SPEED,          "wind_speed",			"Wind velocity",                                  "m/s", "", "", ""),   
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SUN_ANGLE,           "sun_angle",				"Solar altitude angle",                           "deg", "", "", ""),   
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_N_COLLECTORS,        "n_collectors",			"Total number of collectors (Num N-S x Num E-W)", "-", "", "", ""),    
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_DNI,                 "DNI",					"Direct normal radiation",                        "W/m^2", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_I_CUT_IN,            "I_cut_in",				"The cut-in DNI value used in the simulation",    "W/m^2", "", "", ""),    
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_D_AP,                "d_ap",					"The aperture diameter used in the simulation",   "m", "", "", ""),     
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P_OUT_REC,          "P_out_rec",                  "Receiver output power",                     "kW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_REC_LOSSES,       "Q_rec_losses",				 "Receiver thermal losses",                   "kW", "", "", ""),         
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_ETA_REC,            "eta_rec",					 "Receiver efficiency",                       "-", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_HEATER_HEAD_OPERATE, "T_heater_head_operate",	 "Receiver head operating temperature",       "K", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_RAD_REFLECTION,   "rad_reflection",			 "Reflected radiation",                       "kW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_RAD_EMISSION,     "rad_emission",				 "Emitted radiation",                         "kW", "", "", ""),         
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_CONV,             "q_conv",					 "Total convection losses",                   "kW", "", "", ""),         
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_COND,             "q_cond",					 "Conduction losses",                         "kW", "", "", ""),    
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX,			0,					0, 0, 0, 0, 0	)
]

class sam_pf_dish_receiver_type296(tcstypeinterface):
    var m_receiver_type: Float64
    var m_transmittance_cover: Float64
    var m_manufacturer: Int32
    var m_alpha_absorber: Float64
    var m_A_absorber: Float64
    var m_alpha_wall: Float64
    var m_A_wall: Float64
    var m_L_insulation: Float64
    var m_k_insulation: Float64
    var m_d_cav: Float64
    var m_P_cav: Float64
    var m_L_cav: Float64
    var m_delta_T_DIR: Float64
    var m_delta_T_reflux: Float64
    var m_T_heater_head_high: Float64
    var m_T_heater_head_low: Float64

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        super().__init__(cst, ti)
        self.m_receiver_type = float64.nan
        self.m_transmittance_cover = float64.nan
        self.m_manufacturer = -1
        self.m_alpha_absorber = float64.nan
        self.m_A_absorber = float64.nan
        self.m_alpha_wall = float64.nan
        self.m_A_wall = float64.nan
        self.m_L_insulation = float64.nan
        self.m_k_insulation = float64.nan
        self.m_d_cav = float64.nan
        self.m_P_cav = float64.nan
        self.m_L_cav = float64.nan
        self.m_delta_T_DIR = float64.nan
        self.m_delta_T_reflux = float64.nan
        self.m_T_heater_head_high = float64.nan
        self.m_T_heater_head_low = float64.nan

    def __del__(owned self):

    def init(inout self) -> Int32:
        self.m_receiver_type = self.value(P_REC_TYPE)
        self.m_transmittance_cover = self.value(P_TRANSMITTANCE_COVER)
        self.m_manufacturer = Int32(self.value(P_MANUFACTURER))
        self.m_P_cav = self.value(P_P_CAV)
        if self.m_manufacturer == 1:							// SES System = 1
            self.m_alpha_absorber = 0.90
            self.m_A_absorber = 0.6
            self.m_alpha_wall = 0.6
            self.m_A_wall = 0.6
            self.m_L_insulation = 0.075
            self.m_k_insulation = 0.06
            self.m_d_cav = 0.46
            self.m_L_cav = self.m_d_cav
            self.m_delta_T_DIR = 90.0
            self.m_delta_T_reflux = 40.0
            self.m_T_heater_head_high = 993.0
            self.m_T_heater_head_low = 973.0
        elif self.m_manufacturer == 2:							// WGA System = 2
            self.m_alpha_absorber = 0.9
            self.m_A_absorber = 0.15
            self.m_alpha_wall = 0.6
            self.m_A_wall = 0.15
            self.m_L_insulation = 0.075
            self.m_k_insulation = 0.06
            self.m_d_cav = 0.35
            self.m_L_cav = self.m_d_cav
            self.m_delta_T_DIR = 70.0
            self.m_delta_T_reflux = 30.0
            self.m_T_heater_head_high = 903.0
            self.m_T_heater_head_low = 903.0
        elif self.m_manufacturer == 3:							// SBP System = 3
            self.m_alpha_absorber = 0.90
            self.m_A_absorber = 0.15
            self.m_alpha_wall = 0.6
            self.m_A_wall = 0.15
            self.m_L_insulation = 0.075
            self.m_k_insulation = 0.06
            self.m_d_cav = 0.37
            self.m_L_cav = self.m_d_cav
            self.m_delta_T_DIR = 70.0
            self.m_delta_T_reflux = 30.0
            self.m_T_heater_head_high = 903.0
            self.m_T_heater_head_low = 903.0
        elif self.m_manufacturer == 4:							// SAIC System = 4
            self.m_alpha_absorber = 0.90
            self.m_A_absorber = 0.8
            self.m_alpha_wall = 0.6
            self.m_A_wall = 0.8
            self.m_L_insulation = 0.075
            self.m_k_insulation = 0.06
            self.m_d_cav = 0.5
            self.m_L_cav = self.m_d_cav
            self.m_delta_T_DIR = 90.0
            self.m_delta_T_reflux = 40.0
            self.m_T_heater_head_high = 993.0
            self.m_T_heater_head_low = 973.0
        elif self.m_manufacturer == 5:
            self.m_alpha_absorber = self.value(P_ALPHA_ABSORBER)
            self.m_A_absorber = self.value(P_A_ABSORBER)
            self.m_alpha_wall = self.value(P_ALPHA_WALL)
            self.m_A_wall = self.value(P_A_WALL)
            self.m_L_insulation = self.value(P_L_INSULATION)
            self.m_k_insulation = self.value(P_K_INSULATION)
            self.m_d_cav = self.value(P_D_CAV)
            self.m_L_cav = self.value(P_L_CAV)
            self.m_delta_T_DIR = self.value(P_DELTA_T_DIR)
            self.m_delta_T_reflux = self.value(P_DELTA_T_REFLUX)
            self.m_T_heater_head_high = self.value(P_T_HEATER_HEAD_HIGH)
            self.m_T_heater_head_low = self.value(P_T_HEATER_HEAD_LOW)
        else:
            self.message(TCS_ERROR, "Manufacturer integer needs to be from 1 to 5")
            return -1
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
        var Power_in = self.value(I_POWER_IN_REC)
        var T_amb = self.value(I_T_AMB) + 273.15
        var P_atm = self.value(I_P_ATM) * 100.0
        var wind_speed = self.value(I_WIND_SPEED)
        var sun_angle = 90.0 - self.value(I_SUN_ANGLE)
        var d_ap = self.value(I_D_AP)
        /*========================================================
        Determine average receiver temperature for a DIR or reflux receiver
        Reflux receivers should have a lower receiver temp and higher 
        heater head operating temp.....ie....lower receiver losses 
        and higher engine efficiency */
        var T_rec_ave: Float64
        var T_heater_head_operate: Float64
        if self.m_receiver_type == 1:					// DIR
            T_rec_ave = self.m_T_heater_head_high + self.m_delta_T_DIR
            T_heater_head_operate = self.m_T_heater_head_low
        elif self.m_receiver_type == 2:
            T_rec_ave = self.m_T_heater_head_high + 100.0 + self.m_delta_T_reflux
            T_heater_head_operate = self.m_T_heater_head_low + 100.0
        else:
            self.message(TCS_ERROR, "Receiver type must be set to 1 or 2")
            return -1
        var A_ap = CSP.pi * pow((d_ap/2.0), 2)
        var A_cav = self.m_A_absorber + self.m_A_wall
        var theta_rad = sun_angle * 2.0 * CSP.pi / 360.0
        var k_air = 0.00169319 + 0.0000794814 * T_amb
        var beta_air = 0.00949962 - 0.0000297215 * T_amb + 3.06353 * 10E-08 * pow(T_amb, 2)
        var mu_air = 0.00000499562 + 4.50917E-08 * T_amb
        var M_air = 28.97		// [kg/kmol]  molar mass of air
        var R_bar = 8314		// [J/kmol-K]  gas constant
        var R_air = R_bar / M_air
        var rho_air = P_atm / (R_air * T_amb)  // ideal gas law
        var nu_air = mu_air / (rho_air + 0.0000001)
        var h_out = 20.0	//[W/K-m^2]	External housing convective estimate
        var R_cond_ins = self.m_L_insulation / (self.m_k_insulation * A_cav + 0.0000001)
        var R_conv_housing = 1.0 / (h_out * 1.5 * A_cav + 0.0000001)
        var q_cond_loss = (T_rec_ave - T_amb) / (R_cond_ins + R_conv_housing + 0.0000001) / 1000.0
        var Lc_3 = self.m_d_cav			// characteristic length 
        var S3 = -0.982 * (d_ap / (Lc_3 + 0.0000001)) + 1.12
        var Gr3 = (CSP.grav * beta_air * (T_rec_ave - T_amb) * pow(Lc_3, 3)) / (pow(nu_air, 2) + 0.0000001)
        var Nu3 = 0.088 * pow(Gr3, 0.3333) * pow((T_rec_ave / (T_amb + 0.0000001)), 0.18) * pow((cos(sun_angle * 2.0 * CSP.pi / 360.0)), 2.47) * pow((d_ap / (Lc_3 + 0.0000001)), S3)		// Nusselt number
        var h_cav3 = Nu3 * k_air / (Lc_3 + 0.0000001)		// convection heat transfer coefficient
        var q_conv_loss = (h_cav3 * A_cav * (T_rec_ave - T_amb)) / 1000.0   	               
        var h_forced_wind = 0.1967 * pow(wind_speed, 1.849)
        var q_conv_forced = (h_forced_wind * A_cav * (T_rec_ave - T_amb)) / 1000.0   
        q_conv_loss = q_conv_loss + q_conv_forced
        var EPSILON_rad = 1.0			// slight increase in losses from effective absorptance ok
        var q_rad_emission = EPSILON_rad * A_ap * CSP.sigma * (pow(T_rec_ave, 4) - pow(T_amb, 4)) / 1000.0
        var alpha_cav_ave = (self.m_alpha_absorber + self.m_alpha_wall) / 2.0		// approx ave cavity apsorptance
        var transmit_diffuse = 0.85 * self.m_transmittance_cover				// approximation
        var alpha_eff: Float64
        if self.m_transmittance_cover < 1:
            alpha_eff = self.m_transmittance_cover * alpha_cav_ave / (alpha_cav_ave + (1 - alpha_cav_ave) * transmit_diffuse * (A_ap / (A_cav + 0.0000001)) + 0.0000001)
        else:
            alpha_eff = alpha_cav_ave / (alpha_cav_ave + (1 - alpha_cav_ave) * (A_ap / (A_cav + 0.0000001)) + 0.0000001)
        var q_rad_reflection = (1.0 - alpha_eff) * Power_in
        var q_rad_loss: Float64
        if self.m_transmittance_cover < 1:
            q_rad_loss = q_rad_reflection
        else:
            q_rad_loss = q_rad_emission + q_rad_reflection
        var q_rec_losses_kW: Float64
        if Power_in >= 0.001:
            if self.m_transmittance_cover < 1.0:
                q_rec_losses_kW = (q_cond_loss + q_rad_loss)
            else:
                q_rec_losses_kW = (q_cond_loss + q_conv_loss + q_rad_loss)
        else:
            q_rec_losses_kW = 0
        var Q_reject = float64.nan
        if self.m_transmittance_cover < 1.0:
            var tolerance = 5.0			// 2 eq's for glass temp must be within tolerance [K]
            var residual = 100.0		// initialize residual to be greater than tolerance
            var d_T = 1.0				// increment T_glass by 1 degree
            var T_glass = T_rec_ave
            while T_glass <= 1500:
                if residual >= tolerance:
                    var T_film_in = (T_glass + T_rec_ave) / 2
                    var k_air_in = 0.00169319 + 0.0000794814 * T_film_in
                    var rho_air_in = self.m_P_cav / (R_air * T_film_in)					// cavity can be pressurized
                    var Cp_air_in = 1017.7 - 0.136681 * T_film_in + 0.000311257 * pow(T_film_in, 2)
                    var mu_air_in = 0.00000499562 + 4.50917E-08 * T_film_in   
                    var BETA_in = 1.0 / T_film_in
                    var alpha_in = k_air_in / (rho_air_in * Cp_air_in)				// thermal diffusivity
                    var nu_in = mu_air_in / rho_air_in							// kinematic viscosity
                    var Gr_in = CSP.grav * BETA_in * (T_rec_ave - T_glass) * pow(d_ap, 3) / pow(nu_in, 2)
                    var Pr_in = nu_in / alpha_in
                    var Ra_in = Pr_in * Gr_in
                    var Nusselt_90 = 0.18 * pow((Pr_in / (0.2 + Pr_in) * Ra_in), 0.29)	// p563 Incropera
                    var Nusselt_in = 1.0 + (Nusselt_90 - 1) * sin(1.5708 + theta_rad)		// P.564 Incropera
                    var h_glass_in = max(0.000001, Nusselt_in / self.m_L_cav * k_air_in)
                    var T_film_out = (T_amb + T_glass) / 2.0
                    var k_air_out = 0.00169319 + 0.0000794814 * T_film_out
                    var rho_air_out = P_atm / (R_air * T_film_out)
                    var Cp_air_out = 1017.7 - 0.136681 * T_film_out + 0.000311257 * pow(T_film_out, 2)
                    var mu_air_out = 0.00000499562 + 4.50917E-08 * T_film_out
                    var BETA_out = 1.0 / T_film_out
                    var alpha_out = k_air_out / (rho_air_out * Cp_air_out)			// thermal diffusivity
                    var nu_out = mu_air_out / rho_air_out							// kinematic viscosity
                    var Gr_out = CSP.grav * BETA_out * (T_glass - T_amb) * pow(d_ap, 3) / pow(nu_out, 2)		// Grashof number
                    var Pr_out = nu_out / alpha_out								// Prandtl number
                    var Ra_out = Pr_out * Gr_out									// Rayleigh number
                    var Nusselt_vertical = 0.68 + (0.67 * pow((Ra_out * cos(theta_rad)), 0.25) / pow((1 + pow((0.492 / Pr_out), (9/16))), (4/9)))  // for theta between 0-60 degrees
                    var Nusselt_horiz = 0.27 * pow(Ra_out, 0.25)				// for theta between 60-90 degrees
                    var Nusselt_out_max = max(Nusselt_vertical, Nusselt_horiz)
                    var h_glass_out = Nusselt_out_max * k_air_out / d_ap
                    var Re_air_out = rho_air_out * wind_speed * d_ap / mu_air_out		// Reynolds number
                    var Nusselt_out_forced: Float64
                    if Re_air_out >= 500000:
                        Nusselt_out_forced = (0.037 * pow(Re_air_out, 0.8) - 871) * pow(Pr_out, (1/3))	// turb flow	
                    else:
                        Nusselt_out_forced = 0.664 * pow(Re_air_out, 0.5) * pow(Pr_out, 0.3333)		// laminar flow
                    var h_out_forced = Nusselt_out_forced * k_air_out / d_ap
                    var h_outside_total = pow(pow(h_glass_out, 3) + pow(h_out_forced, 3), (1/3))	// p924 Klein/Nellis
                    var R_rad_out = 1.0 / (A_ap * CSP.sigma * (pow(T_glass, 2) + pow(T_amb, 2)) * (T_glass + T_amb))
                    var R_conv_out = 1.0 / (h_outside_total * A_ap)
                    var R_rad_in = 1.0 / (A_ap * CSP.sigma * (pow(T_rec_ave, 2) + pow(T_glass, 2)) * (T_rec_ave + T_glass))
                    var R_conv_in = 0.001 + 1.0 / (h_glass_in * A_ap + 0.0000001)
                    var R1 = pow((1 / (R_rad_in + 0.0000001) + 1 / (R_conv_in + 0.0000001) + 0.000001), -1)
                    var R2 = pow((1 / (R_rad_out + 0.0000001) + 1 / (R_conv_out + 0.0000001) + 0.000001), -1)
                    var T_glass_res = R2 * (T_rec_ave - T_amb) / (R1 + R2) + T_amb
                    Q_reject = (T_glass_res - T_amb) / R2
                    residual = abs(T_glass_res - T_glass)
                else:
                    break
                T_glass += d_T
            q_rec_losses_kW = q_rec_losses_kW + (Q_reject / 1000.0)		// Convert to kW
        if self.m_transmittance_cover < 1:
            q_conv_loss = Q_reject / 1000.0
            q_rad_emission = 0.0
        if Power_in < 0.001:
            q_rec_losses_kW = 0.0
            q_conv_loss = 0.0
            q_rad_emission = 0.0
            q_cond_loss = 0.0
            q_rad_reflection = 0.0
        if q_rec_losses_kW <= Power_in:
            self.value(O_P_OUT_REC, Power_in - q_rec_losses_kW)
        else:
            self.value(O_P_OUT_REC, 0.0)
        self.value(O_Q_REC_LOSSES, q_rec_losses_kW)
        self.value(O_ETA_REC, self.value(O_P_OUT_REC) / (Power_in + 0.0000001))
        self.value(O_T_HEATER_HEAD_OPERATE, T_heater_head_operate)
        self.value(O_Q_RAD_REFLECTION, q_rad_reflection)
        self.value(O_Q_RAD_EMISSION, q_rad_emission)
        self.value(O_Q_CONV, q_conv_loss)
        self.value(O_Q_COND, q_cond_loss)
        return 0

    def converged(inout self, time: Float64) -> Int32:
        return 0

TCS_IMPLEMENT_TYPE(sam_pf_dish_receiver_type296, "Collector Dish", "Ty Neises", 1, sam_pf_dish_receiver_type296_variables, None, 1)