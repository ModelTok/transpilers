// Mojo translation of sam_mw_pt_type222.cpp (1:1, no refactoring)

from tcstype import (
    TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_MATRIX, TCS_INVALID,
    tcsvarinfo, tcstypeinterface, tcscontext, tcstypeinfo,
    TCS_ERROR, TCS_WARNING, TCS_MATRIX_INDEX
)
from htf_props import HTFProperties
from sam_csp_util import CSP
from ngcc_powerblock import ngcc_power_cycle
from util import matrix_t
from memory import Pointer, UnsafePointer
from math import pi, exp, log, pow, sqrt, floor, ceil, abs, min, max
from builtins import String, Float64, Int, Bool, let, var

// TCS_MATRIX_INDEX is imported as a function (defined in tcstype)

enum:
    // Parameters
    P_N_panels
    P_D_rec
    P_H_rec
    P_THT
    P_D_out
    P_th_tu
    P_mat_tube
    P_field_fl
    P_field_fl_props
    P_Flow_type
    P_epsilon
    P_hl_ffact
    P_T_htf_hot_des
    P_T_htf_cold_des
    P_f_rec_min
    P_Q_rec_des
    P_rec_su_delay
    P_rec_qf_delay
    P_m_dot_htf_max
    P_A_sf
    P_IS_DIRECT_ISCC
    P_CYCLE_CONFIG
    P_n_flux_x
    P_n_flux_y
    // Inputs
    I_azimuth
    I_zenith
    I_T_salt_hot
    I_T_salt_cold
    I_v_wind_10
    I_P_amb
    I_eta_pump
    I_T_dp
    I_I_bn
    I_field_eff
    I_T_db
    I_night_recirc
    I_hel_stow_deploy
    I_flux_map
    // Outputs
    O_m_dot_salt_tot
    O_eta_therm
    O_W_dot_pump
    O_q_conv_sum
    O_q_rad_sum
    O_Q_thermal
    O_T_salt_hot
    O_field_eff_adj
    O_q_solar_total
    O_q_startup
    O_dP_receiver
    O_dP_total
    O_vel_htf
    O_T_salt_in
    O_M_DOT_SS
    O_Q_DOT_SS
    O_F_TIMESTEP
    N_MAX

// Global variable list (translated as a constant list of tcsvarinfo)
let sam_mw_pt_type222_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_N_panels, "N_panels", "Number of individual panels on the receiver", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_D_rec, "D_rec", "The overall outer diameter of the receiver", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_H_rec, "H_rec", "The height of the receiver", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_THT, "THT", "The height of the tower (hel. pivot to rec equator)", "m", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_D_out, "d_tube_out", "The outer diameter of an individual receiver tube", "mm", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_th_tu, "th_tube", "The wall thickness of a single receiver tube", "mm", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_mat_tube, "mat_tube", "The material name of the receiver tubes", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_field_fl, "rec_htf", "The name of the HTF used in the receiver", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_MATRIX, P_field_fl_props, "field_fl_props", "User defined field fluid property data", "-", "7 columns (T,Cp,dens,visc,kvisc,cond,h), at least 3 rows", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Flow_type, "Flow_type", "A flag indicating which flow pattern is used", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_epsilon, "epsilon", "The emissivity of the receiver surface coating", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_hl_ffact, "hl_ffact", "The heat loss factor (thermal loss fudge factor)", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_htf_hot_des, "T_htf_hot_des", "Hot HTF outlet temperature at design conditions", "C", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_T_htf_cold_des, "T_htf_cold_des", "Cold HTF inlet temperature at design conditions", "C", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_f_rec_min, "f_rec_min", "Minimum receiver mass flow rate turn down fraction", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_Q_rec_des, "Q_rec_des", "Design-point receiver thermal power output", "MWt", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_su_delay, "rec_su_delay", "Fixed startup delay time for the receiver", "hr", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_rec_qf_delay, "rec_qf_delay", "Energy-based receiver startup delay (fraction of rated thermal power)", "", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_m_dot_htf_max, "m_dot_htf_max", "Maximum receiver mass flow rate", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_A_sf, "A_sf", "Solar Field Area", "m^2", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_IS_DIRECT_ISCC, "is_direct_iscc", "Is receiver directly connected to an iscc power block", "-", "", "", "-999"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_CYCLE_CONFIG, "cycle_config", "Configuration of ISCC power cycle", "-", "", "", "1"),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_flux_x, "n_flux_x", "Receiver flux map resolution - X", "-", "", "", ""),
    tcsvarinfo(TCS_PARAM, TCS_NUMBER, P_n_flux_y, "n_flux_y", "Receiver flux map resolution - Y", "-", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_azimuth, "azimuth", "Solar azimuth angle", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_zenith, "zenith", "Solar zenith angle", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_salt_hot, "T_salt_hot_target", "Desired HTF outlet temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_salt_cold, "T_salt_cold", "Desired HTF inlet temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_v_wind_10, "V_wind_10", "Ambient wind velocity, ground level", "m/s", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_P_amb, "P_amb", "Ambient atmospheric pressure", "mbar", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_eta_pump, "eta_pump", "Receiver HTF pump efficiency", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_dp, "T_dp", "Ambient dew point temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_I_bn, "I_bn", "Direct (beam) normal radiation", "W/m^2-K", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_field_eff, "field_eff", "Heliostat field efficiency", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_T_db, "T_db", "Ambient dry bulb temperature", "C", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_night_recirc, "night_recirc", "Flag to indicate night recirculation through the rec.", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_hel_stow_deploy, "hel_stow_deploy", "Heliostat field stow/deploy solar angle", "deg", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_MATRIX, I_flux_map, "flux_map", "Receiver flux map", "-", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_m_dot_salt_tot, "m_dot_salt_tot", "Total HTF flow rate through the receiver", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_eta_therm, "eta_therm", "Receiver thermal efficiency", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_W_dot_pump, "W_dot_pump", "Receiver pump power", "MWe", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_q_conv_sum, "q_conv_sum", "Receiver convective losses", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_q_rad_sum, "q_rad_sum", "Receiver radiative losses", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_thermal, "Q_thermal", "Receiver thermal output", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_salt_hot, "T_salt_hot", "HTF outlet temperature", "C", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_field_eff_adj, "field_eff_adj", "Adjusted heliostat field efficiency - includes overdesign adjustment", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_q_solar_total, "Q_solar_total", "Total incident power on the receiver", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_q_startup, "q_startup", "Startup energy consumed during the current time step", "MWt", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_dP_receiver, "dP_receiver", "Receiver HTF pressure drop", "bar", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_dP_total, "dP_total", "Total receiver and tower pressure drop", "bar", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_vel_htf, "vel_htf", "Heat transfer fluid average velocity", "m/s", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_T_salt_in, "T_salt_cold", "Inlet salt temperature", "C", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_M_DOT_SS, "m_dot_ss", "Mass flow rate at steady state - does not derate for startup", "kg/hr", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_Q_DOT_SS, "q_dot_ss", "Thermal at steady state - does not derate for startup", "MW", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_F_TIMESTEP, "f_timestep", "Fraction of timestep that receiver is operational (not starting-up)", "-", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, 0, 0, 0, 0, 0, 0)
)

@value
struct sam_mw_pt_type222(tcstypeinterface):
    var field_htfProps: HTFProperties
    var tube_material: HTFProperties
    var ambient_air: HTFProperties
    var cycle_calcs: ngcc_power_cycle
    var m_n_panels: Int
    var m_d_rec: Float64
    var m_h_rec: Float64
    var m_h_tower: Float64
    var m_od_tube: Float64
    var m_th_tube: Float64
    var m_epsilon: Float64
    var m_hl_ffact: Float64
    var m_T_htf_hot_des: Float64
    var m_T_htf_cold_des: Float64
    var m_f_rec_min: Float64
    var m_q_rec_des: Float64
    var m_rec_su_delay: Float64
    var m_rec_qf_delay: Float64
    var m_m_dot_htf_max: Float64
    var m_A_sf: Float64
    var m_id_tube: Float64
    var m_A_tube: Float64
    var m_n_t: Int
    var m_n_flux_x: Int
    var m_n_flux_y: Int
    var m_A_rec_proj: Float64
    var m_A_node: Float64
    var m_itermode: Int
    var m_od_control: Float64
    var m_tol_od: Float64
    var m_m_dot_htf_des: Float64
    var m_q_rec_min: Float64
    /* declare storage variables here */
    var m_mode: Int
    var m_mode_prev: Int
    var m_E_su: Float64
    var m_E_su_prev: Float64
    var m_t_su: Float64
    var m_t_su_prev: Float64
    var m_flow_pattern: matrix_t[Int]
    var m_n_lines: Int
    var m_flux_in: matrix_t[Float64]
    var m_q_dot_inc: matrix_t[Float64]
    var m_T_s_guess: matrix_t[Float64]
    var m_T_s: matrix_t[Float64]
    var m_T_panel_out_guess: matrix_t[Float64]
    var m_T_panel_out: matrix_t[Float64]
    var m_T_panel_in_guess: matrix_t[Float64]
    var m_T_panel_in: matrix_t[Float64]
    var m_T_panel_ave: matrix_t[Float64]
    var m_T_panel_ave_guess: matrix_t[Float64]
    var m_T_film: matrix_t[Float64]
    var m_q_dot_conv: matrix_t[Float64]
    var m_q_dot_rad: matrix_t[Float64]
    var m_q_dot_loss: matrix_t[Float64]
    var m_q_dot_abs: matrix_t[Float64]
    var m_m_mixed: Float64
    var m_LoverD: Float64
    var m_RelRough: Float64
    var m_is_iscc: Bool
    var m_cycle_config: Int
    var m_T_amb_low: Float64
    var m_T_amb_high: Float64
    var m_P_amb_low: Float64
    var m_P_amb_high: Float64
    var m_q_iscc_max: Float64
    var m_i_flux_map: Pointer[Float64]

    def __init__(inout self, cst: tcscontext, ti: tcstypeinfo):
        self.tcstypeinterface.__init__(cst, ti)
        self.m_n_panels = -1
        self.m_d_rec = Float64.NaN
        self.m_h_rec = Float64.NaN
        self.m_h_tower = Float64.NaN
        self.m_od_tube = Float64.NaN
        self.m_th_tube = Float64.NaN
        self.m_epsilon = Float64.NaN
        self.m_hl_ffact = Float64.NaN
        self.m_T_htf_hot_des = Float64.NaN
        self.m_T_htf_cold_des = Float64.NaN
        self.m_f_rec_min = Float64.NaN
        self.m_q_rec_des = Float64.NaN
        self.m_rec_su_delay = Float64.NaN
        self.m_rec_qf_delay = Float64.NaN
        self.m_m_dot_htf_max = Float64.NaN
        self.m_A_sf = Float64.NaN
        self.m_id_tube = Float64.NaN
        self.m_A_tube = Float64.NaN
        self.m_n_t = -1
        self.m_A_rec_proj = Float64.NaN
        self.m_A_node = Float64.NaN
        self.m_itermode = -1
        self.m_od_control = Float64.NaN
        self.m_tol_od = Float64.NaN
        self.m_m_dot_htf_des = Float64.NaN
        self.m_q_rec_min = Float64.NaN
        self.m_mode = -1
        self.m_mode_prev = -1
        self.m_E_su = Float64.NaN
        self.m_E_su_prev = Float64.NaN
        self.m_t_su = Float64.NaN
        self.m_t_su_prev = Float64.NaN
        /*m_fluxmap_angles	= 0.0
        m_fluxmap			= 0.0
        m_num_sol_pos		= -1;*/
        self.m_flow_pattern = matrix_t[Int](0,0)
        self.m_n_lines = -1
        /*m_flux_in.resize(12, 1);
        m_flux_in.fill(0.0);*/
        self.m_m_mixed = Float64.NaN
        self.m_LoverD = Float64.NaN
        self.m_RelRough = Float64.NaN
        self.m_is_iscc = False
        self.m_cycle_config = 1
        self.m_T_amb_low = Float64.NaN
        self.m_T_amb_high = Float64.NaN
        self.m_P_amb_low = Float64.NaN
        self.m_P_amb_high = Float64.NaN
        self.m_q_iscc_max = Float64.NaN
        self.m_n_flux_x = 0
        self.m_n_flux_y = 0

    def __del__(owned self):

    def init(inout self) -> Int:
        var dt: Float64 = self.time_step()
        self.ambient_air.SetFluid(self.ambient_air.Air)
        var field_fl: Int = Int(self.value(P_field_fl))
        if field_fl != HTFProperties.User_defined and field_fl < HTFProperties.End_Library_Fluids:
            if not self.field_htfProps.SetFluid(field_fl):
                self.message(TCS_ERROR, "Receiver HTF code is not recognized")
                return -1
        elif field_fl == HTFProperties.User_defined:
            var nrows: Int = 0
            var ncols: Int = 0
            var fl_mat: Pointer[Float64] = self.value(P_field_fl_props, nrows, ncols)
            if fl_mat != 0 and nrows > 2 and ncols == 7:
                var mat: matrix_t[Float64] = matrix_t[Float64](nrows, ncols, 0.0)
                for r in range(nrows):
                    for c in range(ncols):
                        mat.at(r, c) = TCS_MATRIX_INDEX(self.var(P_field_fl_props), r, c)
                if not self.field_htfProps.SetUserDefinedFluid(mat):
                    self.message(TCS_ERROR, self.field_htfProps.UserFluidErrMessage(), nrows, ncols)
                    return -1
            else:
                self.message(TCS_ERROR, "The user defined field HTF table must contain at least 3 rows and exactly 7 columns. The current table contains %d row(s) and %d column(s)", nrows, ncols)
                return -1
        else:
            self.message(TCS_ERROR, "Receiver HTF code is not recognized")
            return -1
        var mat_tube: Int = Int(self.value(P_mat_tube))
        if mat_tube == HTFProperties.Stainless_AISI316 or mat_tube == HTFProperties.T91_Steel:
            self.tube_material.SetFluid(mat_tube)
        elif mat_tube == HTFProperties.User_defined:
            self.message(TCS_ERROR, "Receiver material currently does not accept user defined properties")
            return -1
        else:
            self.message(TCS_ERROR, "Receiver material code, %d, is not recognized", mat_tube)
            return -1
        self.m_n_panels = Int(self.value(P_N_panels))			//[-] Number of panels in receiver
        self.m_d_rec = self.value(P_D_rec)						//[m] Diameter of receiver
        self.m_h_rec = self.value(P_H_rec)						//[m] Height of receiver
        self.m_h_tower = self.value(P_THT)						//[m] Height of tower
        self.m_od_tube = self.value(P_D_out)/1.E3				//[m] Outer diameter of receiver tubes -> convert from mm
        self.m_th_tube = self.value(P_th_tu)/1.E3				//[m] Thickness of receiver tubes -> convert from mm
        var flowtype: Int = Int(self.value(P_Flow_type))		//[-] Numerical code to designate receiver flow type
        self.m_epsilon = self.value(P_epsilon)					//[-] Emissivity of receiver
        self.m_hl_ffact = self.value(P_hl_ffact)				//[-] Heat Loss Fudge FACTor
        self.m_T_htf_hot_des = self.value(P_T_htf_hot_des) + 273.15	 //[K] Design receiver outlet temperature -> convert from K
        self.m_T_htf_cold_des = self.value(P_T_htf_cold_des) + 273.15 //[K] Design receiver inlet temperature -> convert from C
        self.m_f_rec_min = self.value(P_f_rec_min)				//[-] Minimum receiver mass flow rate turn down fraction
        self.m_q_rec_des = self.value(P_Q_rec_des)*1.E6			//[W] Design receiver thermal input -> convert from MW
        self.m_rec_su_delay = self.value(P_rec_su_delay)		//[hr] Receiver startup time duration
        self.m_rec_qf_delay = self.value(P_rec_qf_delay)		//[-] Energy-based receiver startup delay (fraction of rated thermal power)
        self.m_m_dot_htf_max = self.value(P_m_dot_htf_max)/3600.0	//[kg/s] Maximum mass flow rate through receiver -> convert from kg/hr
        self.m_A_sf = self.value(P_A_sf)						//[m^2] Solar field area
        self.m_n_flux_x = Int(self.value(P_n_flux_x))
        self.m_n_flux_y = Int(self.value(P_n_flux_y))
        self.m_id_tube = self.m_od_tube - 2*self.m_th_tube			//[m] Inner diameter of receiver tube
        self.m_A_tube = CSP.pi*self.m_od_tube/2.0*self.m_h_rec	//[m^2] Outer surface area of each tube
        self.m_n_t = Int(CSP.pi*self.m_d_rec/(self.m_od_tube*Float64(self.m_n_panels)))	// The number of tubes per panel, as a function of the number of panels and the desired diameter of the receiver
        var n_tubes: Int = self.m_n_t * self.m_n_panels				//[-] Number of tubes in the system
        self.m_A_rec_proj = self.m_od_tube*self.m_h_rec*Float64(n_tubes)		//[m^2] The projected area of the tubes on a plane parallel to the center lines of the tubes
        self.m_A_node = CSP.pi*self.m_d_rec/Float64(self.m_n_panels)*self.m_h_rec //[m^2] The area associated with each node
        self.m_mode = 0					//[-] 0 = requires startup, 1 = starting up, 2 = running
        self.m_itermode = 1				//[-] 1: Solve for design temp, 2: solve to match mass flow restriction
        self.m_od_control = 1.0			//[-] Additional defocusing for over-design conditions
        self.m_tol_od = 0.001			//[-] Tolerance for over-design iteration
        var c_htf_des: Float64 = self.field_htfProps.Cp((self.m_T_htf_hot_des + self.m_T_htf_cold_des)/2.0)*1000.0		//[J/kg-K] Specific heat at design conditions
        self.m_m_dot_htf_des = self.m_q_rec_des/(c_htf_des*(self.m_T_htf_hot_des - self.m_T_htf_cold_des))					//[kg/s]
        self.m_q_rec_min = self.m_q_rec_des * self.m_f_rec_min	//[W] Minimum receiver thermal power
        self.m_mode_prev = self.m_mode
        self.m_E_su_prev = self.m_q_rec_des * self.m_rec_qf_delay	//[W-hr] Startup energy
        self.m_t_su_prev = self.m_rec_su_delay				//[hr] Startup time requirement
        self.m_i_flux_map = self.allocate(I_flux_map, self.m_n_flux_y, self.m_n_flux_x)
        var flow_msg: String
        if not CSP.flow_patterns(self.m_n_panels, flowtype, self.m_n_lines, self.m_flow_pattern, flow_msg):
            self.message(TCS_ERROR, flow_msg)
            return -1
        self.m_q_dot_inc.resize(self.m_n_panels)
        self.m_q_dot_inc.fill(0.0)
        self.m_T_s_guess.resize(self.m_n_panels)
        self.m_T_s_guess.fill(0.0)
        self.m_T_s.resize(self.m_n_panels)
        self.m_T_s.fill(0.0)
        self.m_T_panel_out_guess.resize(self.m_n_panels)
        self.m_T_panel_out.resize(self.m_n_panels)
        self.m_T_panel_out_guess.fill(0.0)
        self.m_T_panel_out.fill(0.0)
        self.m_T_panel_in_guess.resize(self.m_n_panels)
        self.m_T_panel_in_guess.fill(0.0)
        self.m_T_panel_in.resize(self.m_n_panels)
        self.m_T_panel_in.fill(0.0)
        self.m_T_panel_ave.resize(self.m_n_panels)
        self.m_T_panel_ave.fill(0.0)
        self.m_T_panel_ave_guess.resize(self.m_n_panels)
        self.m_T_panel_ave_guess.fill(0.0)
        self.m_T_film.resize(self.m_n_panels)
        self.m_T_film.fill(0.0)
        self.m_q_dot_conv.resize(self.m_n_panels)
        self.m_q_dot_conv.fill(0.0)
        self.m_q_dot_rad.resize(self.m_n_panels)
        self.m_q_dot_rad.fill(0.0)
        self.m_q_dot_loss.resize(self.m_n_panels)
        self.m_q_dot_loss.fill(0.0)
        self.m_q_dot_abs.resize(self.m_n_panels)
        self.m_q_dot_abs.fill(0.0)
        self.m_m_mixed = 3.2	//[-] Exponential for calculating mixed convection
        self.m_LoverD = self.m_h_rec/self.m_id_tube
        self.m_RelRough = (4.5e-5)/self.m_id_tube	//[-] Relative roughness of the tubes. http:www.efunda.com/formulae/fluids/roughness.cfm
        self.m_is_iscc = self.value(P_IS_DIRECT_ISCC) == 1.0
        if self.m_is_iscc:
            self.m_cycle_config = Int(self.value(P_CYCLE_CONFIG))
            self.cycle_calcs.set_cycle_config(self.m_cycle_config)
            self.cycle_calcs.get_table_range(self.m_T_amb_low, self.m_T_amb_high, self.m_P_amb_low, self.m_P_amb_high)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int) -> Int:
        var azimuth: Float64 = self.value(I_azimuth)	//[deg] Solar azimuth angle 0 - 360, clockwise from due north, northern hemisphere
        var zenith: Float64 = self.value(I_zenith)		//[deg] Solar zenith angle
        var T_salt_hot_target: Float64 = self.value(I_T_salt_hot) + 273.15	//[K] Desired hot temp, convert from C
        var T_salt_cold_in: Float64 = self.value(I_T_salt_cold) + 273.15	//[K] Cold salt inlet temp, convert from C
        var v_wind_10: Float64 = self.value(I_v_wind_10)		//[m/s] Wind velocity
        var P_amb: Float64 = self.value(I_P_amb)*100.0	//[Pa] Ambient pressure, convert from mbar
        var eta_pump: Float64 = self.value(I_eta_pump)	//[-] Receiver HTF pump efficiency
        var hour: Float64 = time/3600.0				//[hr] Hour of the year
        var hour_day: Float64 = Float64(Int(hour)%24)		//[hr] Hour of the day
        var T_dp: Float64 = self.value(I_T_dp) + 273.15 //[K] Dewpoint temperature, convert from C
        var I_bn: Float64 = self.value(I_I_bn)			//[W/m^2-K] Beam normal radiation
        var field_eff: Float64 = self.value(I_field_eff) //[-] Field efficiency value
        var T_amb: Float64 = self.value(I_T_db) + 273.15 //[K] Dry bulb temperature, convert from C
        var night_recirc: Int = Int(self.value(I_night_recirc))	//[-] Night recirculation control 0 = empty receiver, 1 = recirculate
        var hel_stow_deploy: Float64 = self.value(I_hel_stow_deploy)	//[deg] Solar elevation angle at which heliostats are stowed
        var n_flux_y: Int = 0
        var n_flux_x: Int = 0
        self.m_i_flux_map = self.value(I_flux_map, n_flux_y, n_flux_x)
        if n_flux_y > 1:
            self.message(TCS_WARNING, "The Molten Salt External Receiver (Type222) model does not currently support 2-dimensional "
                "flux maps. The flux profile in the vertical dimension will be averaged. NY=%d",n_flux_y)
        self.m_flux_in.resize(n_flux_x)
        var T_sky: Float64 = CSP.skytemp(T_amb, T_dp, hour)
        self.m_mode = -1
        self.m_E_su = Float64.NaN
        self.m_t_su = Float64.NaN
        /*m_mode_prev = 2.0;
        m_E_su_prev = 0.0;
        m_t_su_prev = 0.0;
        m_itermode = 1;
        m_od_control = 1.0; */
        self.m_itermode = 1
        var v_wind: Float64 = log((self.m_h_tower+self.m_h_rec/2)/0.003)/log(10.0/0.003)*v_wind_10
        var c_p_coolant: Float64 = Float64.NaN
        var rho_coolant: Float64 = Float64.NaN
        var f: Float64 = Float64.NaN
        var u_coolant: Float64 = Float64.NaN
        var q_conv_sum: Float64 = Float64.NaN
        var q_rad_sum: Float64 = Float64.NaN
        var q_dot_inc_sum: Float64 = Float64.NaN
        c_p_coolant = rho_coolant = f = u_coolant = q_conv_sum = q_rad_sum = q_dot_inc_sum = Float64.NaN
        var eta_therm: Float64 = Float64.NaN
        var m_dot_salt_tot: Float64 = Float64.NaN
        var T_salt_hot_guess: Float64 = Float64.NaN
        var m_dot_salt_tot_ss: Float64 = Float64.NaN
        eta_therm = m_dot_salt_tot = T_salt_hot_guess = m_dot_salt_tot_ss = Float64.NaN
        var rec_is_off: Bool = False
        var rec_is_defocusing: Bool = False
        var field_eff_adj: Float64 = 0.0
        var q_thermal_ss: Float64 = 0.0
        var f_rec_timestep: Float64 = 1.0
        if zenith>(90.0-hel_stow_deploy) or I_bn<=1.E-6 or (zenith==0.0 and azimuth==180.0):
            if night_recirc == 1:
                I_bn = 0.0
            else:
                self.m_mode = 0
                rec_is_off = True
        var T_coolant_prop: Float64 = (T_salt_hot_target + T_salt_cold_in)/2.0		//[K] The temperature at which the coolant properties are evaluated. Validated as constant (mjw)
        c_p_coolant = self.field_htfProps.Cp(T_coolant_prop)*1000.0					//[kJ/kg-K] Specific heat of the coolant
        var m_dot_htf_max: Float64 = self.m_m_dot_htf_max
        if self.m_is_iscc:
            if ncall == 0:
                var T_amb_C: Float64 = max(self.m_P_amb_low, min(self.m_T_amb_high, T_amb - 273.15))
                var P_amb_bar: Float64 = max(self.m_P_amb_low, min(self.m_P_amb_high, P_amb / 1.E5))
                self.m_q_iscc_max = self.cycle_calcs.get_ngcc_data(0.0, T_amb_C, P_amb_bar, ngcc_power_cycle.E_solar_heat_max)*1.E6	// kWth, convert from MWth
            var m_dot_iscc_max: Float64 = self.m_q_iscc_max / (c_p_coolant*(T_salt_hot_target - T_salt_cold_in))		// [kg/s]
            m_dot_htf_max = min(self.m_m_dot_htf_max, m_dot_iscc_max)
        var err_od: Float64 = 999.0	// Reset error before iteration
        while True:
            if rec_is_off:
                break
            field_eff_adj = field_eff*self.m_od_control
            if I_bn > 1.0:
                for j in range(n_flux_x):
                    self.m_flux_in.at(j) = 0.0
                    for i in range(n_flux_y):
                        self.m_flux_in.at(j) += (self.m_i_flux_map.load(j*n_flux_y + i)
                            *I_bn*field_eff_adj*self.m_A_sf/1000./(CSP.pi*self.m_h_rec*self.m_d_rec/Float64(n_flux_x)))	//[kW/m^2];
            else:
                self.m_flux_in.fill(0.0)
            var n_flux_x_d: Float64 = Float64(self.m_n_flux_x)
            var n_panels_d: Float64 = Float64(self.m_n_panels)
            if self.m_n_panels >= self.m_n_flux_x:
                for i in range(self.m_n_panels):
                    var ppos: Float64 = (n_flux_x_d/n_panels_d*Float64(i)+n_flux_x_d*0.5/n_panels_d)
                    var flo: Int = Int(floor(ppos))
                    var ceiling: Int = Int(ceil(ppos))
                    var ind: Float64 = Float64((ppos - Float64(flo))/max(Float64(ceiling - flo),1.e-6))
                    if ceiling > self.m_n_flux_x-1:
                        ceiling = 0
                    var psp_field: Float64 = (ind*(self.m_flux_in.at(ceiling)-self.m_flux_in.at(flo))+self.m_flux_in.at(flo))		//[kW/m^2] Average area-specific power for each node
                    self.m_q_dot_inc.at(i) = self.m_A_node*psp_field	//[kW] The power incident on each node
            else:
                /* 
                The number of panels is always even, therefore the receiver panels are symmetric about the N-S plane.
                The number of flux points may be even or odd. The distribution is assumed to be symmetric
                about North, therefore:
                    (a) A distribution with an odd number of points includes a center point (n_flux_x - 1)/2+1 
                        whose normal faces exactly north
                    (b) A distribution with an even number of points includes 2 points n_flux_x/2, n_flux_x/2+1 
                        which straddle the North vector. 
                In either scenario, two points straddle the South vector and no scenario allows a point to fall 
                directly on the South vector. Hence, the first and last flux points fall completely on the first
                and last panel, respectively.
                */
                var leftovers: Float64 = 0.0
                var index_start: Int = 0
                var index_stop: Int = 0
                var q_flux_sum: Float64 = 0.0
                var panel_step: Float64 = n_flux_x_d/n_panels_d   //how many flux points are stepped over by each panel?
                for i in range(self.m_n_panels):
                    var panel_pos: Float64 = panel_step*Float64(i+1)   //Where does the current panel end in the flux array?
                    index_start = Int(floor(panel_step*Float64(i)))
                    index_stop = Int(floor(panel_pos))
                    q_flux_sum = 0.0
                    for j in range(index_start, index_stop+1):
                        if j == self.m_n_flux_x:
                            if leftovers > 0.:
                                self.message(TCS_WARNING, "An error occurred during interpolation of the receiver flux map. The results may be inaccurate! Contact SAM support to resolve this issue.")
                            break
                        if j == 0:
                            q_flux_sum = self.m_flux_in.at(j)
                            leftovers = 0.0
                        elif j == index_start:
                            q_flux_sum += leftovers
                            leftovers = 0.0
                        elif j == index_stop:
                            var stop_mult: Float64 = (panel_pos - floor(panel_pos))
                            q_flux_sum += stop_mult * self.m_flux_in.at(j)
                            leftovers = (1 - stop_mult)*self.m_flux_in.at(j)
                        else:
                            q_flux_sum += self.m_flux_in.at(j)
                    self.m_q_dot_inc.at(i) = q_flux_sum * self.m_A_node/n_flux_x_d*n_panels_d
            q_dot_inc_sum = 0.0
            for i in range(self.m_n_panels):
                q_dot_inc_sum += self.m_q_dot_inc.at(i)		//[kW] Total power absorbed by receiver
            if night_recirc == 1:
                self.m_T_s_guess.fill(T_salt_hot_target)		//[K] Guess the temperature for the surface nodes
                self.m_T_panel_out_guess.fill((T_salt_hot_target + T_salt_cold_in)/2.0)	//[K] Guess values for the fluid temp coming out of the control volume
                self.m_T_panel_in_guess.fill((T_salt_hot_target + T_salt_cold_in)/2.0)	//[K] Guess values for the fluid temp coming into the control volume
            else:
                self.m_T_s_guess.fill(T_salt_hot_target)		//[K] Guess the temperature for the surface nodes
                self.m_T_panel_out_guess.fill(T_salt_cold_in)	//[K] Guess values for the fluid temp coming out of the control volume
                self.m_T_panel_in_guess.fill(T_salt_cold_in)	//[K] Guess values for the fluid temp coming into the control volume
            var c_guess: Float64 = self.field_htfProps.Cp((T_salt_hot_target + T_salt_cold_in)/2.0)	//[kJ/kg-K] Estimate the specific heat of the fluid in receiver
            var m_dot_salt_guess: Float64 = Float64.NaN
            if I_bn > 1.E-6:
                var q_guess: Float64 = 0.5*q_dot_inc_sum		//[kW] Estimate the thermal power produced by the receiver
                m_dot_salt_guess = q_guess/(c_guess*(T_salt_hot_target - T_salt_cold_in)*Float64(self.m_n_lines))	//[kg/s] Mass flow rate for each flow path
            else:	// The tower recirculates at night (based on earlier conditions)
                T_salt_hot_target = T_salt_cold_in
                T_salt_cold_in = self.m_T_s_guess.at(0)		//T_s_guess is set to T_salt_hot before, so this just completes
                m_dot_salt_guess = -3500.0/(c_guess*(T_salt_hot_target - T_salt_cold_in)/2.0)
            T_salt_hot_guess = 9999.9		//[K] Initial guess value for error calculation
            var err: Float64 = -999.9					//[-] Relative outlet temperature error
            var tol: Float64 = Float64.NaN
            if night_recirc == 1:
                tol = 0.0057
            else:
                tol = 0.001
            var qq_max: Int = 50
            var m_dot_salt: Float64 = Float64.NaN
            var qq: Int = 0
            while abs(err) > tol:
                qq += 1
                if qq > qq_max:
                    self.m_mode = 0  // Set the startup mode
                    rec_is_off = True
                    break
                m_dot_salt = m_dot_salt_guess
                for i in range(self.m_n_panels):
                    self.m_T_s.at(i) = self.m_T_s_guess.at(i)
                    self.m_T_panel_out.at(i) = self.m_T_panel_out_guess.at(i)
                    self.m_T_panel_in.at(i) = self.m_T_panel_in_guess.at(i)
                    self.m_T_panel_ave.at(i) = (self.m_T_panel_in.at(i)+self.m_T_panel_out.at(i))/2.0		//[K] The average coolant temperature in each control volume
                    self.m_T_film.at(i) = (self.m_T_s.at(i) + T_amb)/2.0					//[K] Film temperature
                var T_s_sum: Float64 = 0.0
                for i in range(self.m_n_panels):
                    T_s_sum += self.m_T_s.at(i)
                var T_s_ave: Float64 = T_s_sum/Float64(self.m_n_panels)
                var T_film_ave: Float64 = (T_amb + T_salt_hot_target)/2.0
                var k_film: Float64 = self.ambient_air.cond(T_film_ave)				//[W/m-K] The conductivity of the ambient air
                var mu_film: Float64 = self.ambient_air.visc(T_film_ave)			//[kg/m-s] Dynamic viscosity of the ambient air
                var rho_film: Float64 = self.ambient_air.dens(T_film_ave, P_amb)	//[kg/m^3] Density of the ambient air
                var c_p_film: Float64 = self.ambient_air.Cp(T_film_ave)				//[kJ/kg-K] Specific heat of the ambient air
                var Re_for: Float64 = rho_film*v_wind*self.m_d_rec/mu_film			//[-] Reynolds number
                var ksD: Float64 = (self.m_od_tube/2.0)/self.m_d_rec						//[-] The effective roughness of the cylinder [Siebers, Kraabel 1984]
                var Nusselt_for: Float64 = CSP.Nusselt_FC(ksD, Re_for)		//[-] S&K
                var h_for: Float64 = Nusselt_for*k_film/self.m_d_rec*self.m_hl_ffact		//[W/m^2-K] Forced convection heat transfer coefficient
                var beta: Float64 = 1.0/T_amb												//[1/K] Volumetric expansion coefficient
                var nu_amb: Float64 = self.ambient_air.visc(T_amb)/self.ambient_air.dens(T_amb, P_amb)	//[m^2/s] Kinematic viscosity
                for i in range(self.m_n_panels):
                    var i_fp: Int = i
                    var Gr_nat: Float64 = max(0.0, CSP.grav*beta*(self.m_T_s.at(i_fp) - T_amb)*pow(self.m_h_rec,3)/pow(nu_amb,2))	//[-] Grashof Number at ambient conditions
                    var Nusselt_nat: Float64 = 0.098*pow(Gr_nat,(1.0/3.0))*pow(self.m_T_s.at(i_fp)/T_amb, -0.14)					//[-] Nusselt number
                    var h_nat: Float64 = Nusselt_nat*self.ambient_air.cond(T_amb)/self.m_h_rec*self.m_hl_ffact					//[W/m^-K] Natural convection coefficient
                    var h_mixed: Float64 = pow((pow(h_for,self.m_m_mixed) + pow(h_nat,self.m_m_mixed)), 1.0/self.m_m_mixed)*4.0			//(4.0) is a correction factor to match convection losses at Solar II (correspondance with G. Kolb, SNL)
                    self.m_q_dot_conv.at(i_fp) = h_mixed*self.m_A_node*(self.m_T_s.at(i_fp) - self.m_T_film.at(i_fp))							//[W] Convection losses per node
                    self.m_q_dot_rad.at(i_fp) = 0.5*CSP.sigma*self.m_epsilon*self.m_A_node*(2.0*pow(self.m_T_s.at(i_fp),4) - pow(T_amb,4) - pow(T_sky,4))*self.m_hl_ffact	//[W] Total radiation losses per node
                    self.m_q_dot_loss.at(i_fp) = self.m_q_dot_rad.at(i_fp) + self.m_q_dot_conv.at(i_fp)			//[W] Total overall losses per node
                    self.m_q_dot_abs.at(i_fp) = self.m_q_dot_inc.at(i_fp)*1000.0 - self.m_q_dot_loss.at(i_fp)	//[W] Absorbed flux at each node
                    var T_wall: Float64 = (self.m_T_s.at(i_fp) + self.m_T_panel_ave.at(i_fp))/2.0				//[K] The temperature at which the conductivity of the wall is evaluated
                    var k_tube: Float64 = self.tube_material.cond(T_wall)								//[W/m-K] The conductivity of the wall
                    var R_tube_wall: Float64 = self.m_th_tube/(k_tube*self.m_h_rec*self.m_d_rec*pow(CSP.pi,2)/2.0/Float64(self.m_n_panels))	//[K/W] The thermal resistance of the wall
                    var mu_coolant: Float64 = self.field_htfProps.visc(T_coolant_prop)					//[kg/m-s] Absolute viscosity of the coolant
                    var k_coolant: Float64 = self.field_htfProps.cond(T_coolant_prop)					//[W/m-K] Conductivity of the coolant
                    rho_coolant = self.field_htfProps.dens(T_coolant_prop, 1.0)			//[kg/m^3] Density of the coolant
                    u_coolant = m_dot_salt/(Float64(self.m_n_t)*rho_coolant*pow((self.m_id_tube/2.0),2)*CSP.pi)	//[m/s] Average velocity of the coolant through the receiver tubes
                    var Re_inner: Float64 = rho_coolant*u_coolant*self.m_id_tube/mu_coolant				//[-] Reynolds number of internal flow
                    var Pr_inner: Float64 = c_p_coolant*mu_coolant/k_coolant							//[-] Prandtl number of internal flow
                    var Nusselt_t: Float64 = 0.0
                    CSP.PipeFlow(Re_inner, Pr_inner, self.m_LoverD, self.m_RelRough, Nusselt_t, f)
                    if Nusselt_t <= 0.0:
                        self.m_mode = 0		// Set the startup mode
                        rec_is_off = True
                        break
                    var h_inner: Float64 = Nusselt_t*k_coolant/self.m_id_tube								//[W/m^2-K] Convective coefficient between the inner tube wall and the coolant
                    var R_conv_inner: Float64 = 1.0/(h_inner*CSP.pi*self.m_id_tube/2.0*self.m_h_rec*Float64(self.m_n_t))	//[K/W] Thermal resistance associated with this value
                    var j: Int = -1
                    var i_comp: Int = -1
                    var found_loc: Bool = False
                    for j in range(2):
                        for abc in range(self.m_n_panels/self.m_n_lines):
                            if not found_loc:
                                if self.m_flow_pattern.at(j, abc) == i:
                                    found_loc = True
                                i_comp = abc - 1
                        if found_loc:
                            break
                    if i_comp == -1:
                        self.m_T_panel_in_guess.at(i_fp) = T_salt_cold_in
                    else:
                        self.m_T_panel_in_guess.at(i_fp) = self.m_T_panel_out.at(self.m_flow_pattern.at(j, i_comp))
                    self.m_T_panel_out_guess.at(i_fp) = self.m_T_panel_in_guess.at(i_fp) + self.m_q_dot_abs.at(i_fp)/(m_dot_salt*c_p_coolant)
                    self.m_T_panel_ave_guess.at(i_fp) = (self.m_T_panel_in_guess.at(i_fp) + self.m_T_panel_out_guess.at(i_fp))/2.0
                    self.m_T_s_guess.at(i_fp) = self.m_T_panel_ave_guess.at(i_fp) + self.m_q_dot_abs.at(i_fp)*(R_conv_inner+R_tube_wall) / (self.m_A_node*1000.0) // adjusted: need to divide by area? Original: = T_panel_ave_guess + q_dot_abs*(R_conv_inner+R_tube_wall) -- but q_dot_abs is per node in W, R in K/W, so product is K. No division needed. Let's keep as original. Actually the C++ line is: m_T_s_guess.at(i_fp) = m_T_panel_ave_guess.at(i_fp) + m_q_dot_abs.at(i_fp)*(R_conv_inner+R_tube_wall); //[K] Surface temperature based on the absorbed heat
                    // So we will keep that:
                    self.m_T_s_guess.at(i_fp) = self.m_T_panel_ave_guess.at(i_fp) + self.m_q_dot_abs.at(i_fp)*(R_conv_inner+R_tube_wall)
                    if self.m_T_s_guess.at(i_fp) < 1.0:
                        self.m_mode = 0  // Set the startup mode
                        rec_is_off = True
                        break
                if rec_is_off:
                    break
                q_conv_sum = 0.0
                q_rad_sum = 0.0
                var q_abs_sum: Float64 = 0.0
                for i in range(self.m_n_panels):
                    q_conv_sum += self.m_q_dot_conv.at(i)
                    q_rad_sum += self.m_q_dot_rad.at(i)
                    q_abs_sum += self.m_q_dot_abs.at(i)
                var T_salt_hot_guess_sum: Float64 = 0.0
                for j in range(self.m_n_lines):
                    T_salt_hot_guess_sum += self.m_T_panel_out_guess.at(self.m_flow_pattern.at(j, self.m_n_panels/self.m_n_lines-1))		//[K] Update the calculated hot salt outlet temp
                T_salt_hot_guess = T_salt_hot_guess_sum/Float64(self.m_n_lines)
                if q_dot_inc_sum > 0.0:
                    eta_therm = q_abs_sum / (q_dot_inc_sum*1000.0)
                else:
                    eta_therm = 0.0
                err = (T_salt_hot_guess - T_salt_hot_target)/T_salt_hot_target
                if abs(err) > tol:
                    m_dot_salt_guess = q_abs_sum/(Float64(self.m_n_lines)*c_p_coolant*(T_salt_hot_target - T_salt_cold_in))			//[kg/s]
                    if m_dot_salt_guess < 1.E-5:
                        self.m_mode = 0				//[-] Set the startup mode
                        rec_is_off = True
            if rec_is_off:
                break
            m_dot_salt_tot = m_dot_salt*Float64(self.m_n_lines)
            var m_dot_tube: Float64 = m_dot_salt/Float64(self.m_n_t)		//[kg/s] The mass flow through each individual tube
            if (m_dot_salt_tot > m_dot_htf_max) or self.m_itermode == 2:
                err_od = (m_dot_salt_tot - m_dot_htf_max)/m_dot_htf_max
                if err_od < self.m_tol_od:
                    self.m_itermode = 1
                    self.m_od_control = 1.0
                    rec_is_defocusing = False
                else:
                    self.m_od_control = self.m_od_control*pow((m_dot_htf_max/m_dot_salt_tot), 0.8)	//[-] Adjust the over-design defocus control by modifying the current value
                    self.m_itermode = 2
                    rec_is_defocusing = True
            if not rec_is_defocusing:
                break
        var DELTAP: Float64 = Float64.NaN
        var Pres_D: Float64 = Float64.NaN
        var W_dot_pump: Float64 = Float64.NaN
        var q_thermal: