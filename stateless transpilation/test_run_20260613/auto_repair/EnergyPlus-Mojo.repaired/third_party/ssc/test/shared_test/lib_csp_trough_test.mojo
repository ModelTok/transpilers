from gtest import EXPECT_NEAR, NAMESPACE_TEST
from csp_solver_trough_collector_receiver import C_csp_trough_collector_receiver as Trough
from csp_solver_trough_collector_receiver import C_csp_collector_receiver
from csp_weatherreader import C_csp_weatherreader
from csp_solver_htf_1state import C_csp_solver_htf_1state as FluidInletState
from csp_solver_sim_info import C_csp_solver_sim_info as TimestepAndTou
from util import matrix_t
from memory import Pointer
from math import fabs, min, max, nan as quiet_nan
from vs_google_test_explorer_namespace import NAMESPACE_TEST

using Location = C_csp_collector_receiver.S_csp_cr_init_inputs
using TroughSolvedParams = C_csp_collector_receiver.S_csp_cr_solved_params
using TimeAndWeather = C_csp_weatherreader.S_outputs
using TroughOutputs = C_csp_collector_receiver.S_csp_cr_out_solver

@value
struct TroughSpecifications:
    var nSCA: Int
    var nHCEt: Int
    var nColt: Int
    var nHCEVar: Int
    var nLoops: Int
    var FieldConfig: Int
    var L_power_block_piping: Float64
    var include_fixed_power_block_runner: Bool
    var eta_pump: Float64
    var Fluid: Int
    var fthrctrl: Int
    var accept_loc: Int
    var HDR_rough: Float64
    var theta_stow: Float64
    var theta_dep: Float64
    var Row_Distance: Float64
    var T_loop_in_des: Float64
    var T_loop_out_des: Float64
    var T_startup: Float64
    var m_dot_htfmin: Float64
    var m_dot_htfmax: Float64
    var field_fl_props: matrix_t[Float64]
    var T_fp: Float64
    var I_bn_des: Float64
    var V_hdr_cold_max: Float64
    var V_hdr_cold_min: Float64
    var V_hdr_hot_max: Float64
    var V_hdr_hot_min: Float64
    var V_hdr_max: Float64
    var V_hdr_min: Float64
    var Pipe_hl_coef: Float64
    var SCA_drives_elec: Float64
    var ColTilt: Float64
    var ColAz: Float64
    var wind_stow_speed: Float64
    var accept_mode: Int
    var accept_init: Bool
    var solar_mult: Float64
    var mc_bal_hot_per_MW: Float64
    var mc_bal_cold_per_MW: Float64
    var mc_bal_sca: Float64
    var W_aperture: List[Float64]
    var A_aperture: List[Float64]
    var TrackingError: List[Float64]
    var GeomEffects: List[Float64]
    var Rho_mirror_clean: List[Float64]
    var Dirt_mirror: List[Float64]
    var Error: List[Float64]
    var Ave_Focal_Length: List[Float64]
    var L_SCA: List[Float64]
    var L_aperture: List[Float64]
    var ColperSCA: List[Float64]
    var Distance_SCA: List[Float64]
    var IAM_matrix: matrix_t[Float64]
    var HCE_FieldFrac: matrix_t[Float64]
    var D_2: matrix_t[Float64]
    var D_3: matrix_t[Float64]
    var D_4: matrix_t[Float64]
    var D_5: matrix_t[Float64]
    var D_p: matrix_t[Float64]
    var Flow_type: matrix_t[Float64]
    var Rough: matrix_t[Float64]
    var alpha_env: matrix_t[Float64]
    var epsilon_3_11: matrix_t[Float64]
    var epsilon_3_12: matrix_t[Float64]
    var epsilon_3_13: matrix_t[Float64]
    var epsilon_3_14: matrix_t[Float64]
    var epsilon_3_21: matrix_t[Float64]
    var epsilon_3_22: matrix_t[Float64]
    var epsilon_3_23: matrix_t[Float64]
    var epsilon_3_24: matrix_t[Float64]
    var epsilon_3_31: matrix_t[Float64]
    var epsilon_3_32: matrix_t[Float64]
    var epsilon_3_33: matrix_t[Float64]
    var epsilon_3_34: matrix_t[Float64]
    var epsilon_3_41: matrix_t[Float64]
    var epsilon_3_42: matrix_t[Float64]
    var epsilon_3_43: matrix_t[Float64]
    var epsilon_3_44: matrix_t[Float64]
    var alpha_abs: matrix_t[Float64]
    var Tau_envelope: matrix_t[Float64]
    var EPSILON_4: matrix_t[Float64]
    var EPSILON_5: matrix_t[Float64]
    var GlazingIntact_dbl: matrix_t[Float64]
    var GlazingIntact: matrix_t[Bool]
    var P_a: matrix_t[Float64]
    var AnnulusGas: matrix_t[Float64]
    var AbsorberMaterial: matrix_t[Float64]
    var Shadowing: matrix_t[Float64]
    var Dirt_HCE: matrix_t[Float64]
    var Design_loss: matrix_t[Float64]
    var SCAInfoArray: matrix_t[Float64]
    var calc_design_pipe_vals: Bool
    var L_rnr_pb: Float64
    var N_max_hdr_diams: Float64
    var L_rnr_per_xpan: Float64
    var L_xpan_hdr: Float64
    var L_xpan_rnr: Float64
    var Min_rnr_xpans: Float64
    var northsouth_field_sep: Float64
    var N_hdr_per_xpan: Float64
    var K_cpnt: matrix_t[Float64]
    var D_cpnt: matrix_t[Float64]
    var L_cpnt: matrix_t[Float64]
    var Type_cpnt: matrix_t[Float64]
    var custom_sf_pipe_sizes: Bool
    var sf_rnr_diams: matrix_t[Float64]
    var sf_rnr_wallthicks: matrix_t[Float64]
    var sf_rnr_lengths: matrix_t[Float64]
    var sf_hdr_diams: matrix_t[Float64]
    var sf_hdr_wallthicks: matrix_t[Float64]
    var sf_hdr_lengths: matrix_t[Float64]

@value
struct TroughState:
    var T_in_loop_prev: Float64
    var T_out_loop_prev: Float64
    var T_out_SCAs_prev: List[Float64]

@value
struct kErrorToleranceLo:
    alias value = 0.001

@value
struct kErrorToleranceHi:
    alias value = 0.01

trait TroughFactory:
    def MakeTrough(location: Location) -> Pointer[Trough]
    def MakeTrough(trough_specifications: Pointer[TroughSpecifications], location: Location) -> Pointer[Trough]
    def MakeSpecifications() -> Pointer[TroughSpecifications]
    def MakeTroughState() -> Pointer[TroughState]
    def MakeTimeLocationWeather(location: Location) -> Pointer[TimeAndWeather]
    def MakeTimestepAndTou() -> TimestepAndTou
    def MakeInletState() -> FluidInletState
    def MakeDefocus() -> Float64
    def MakeLocation() -> Location
    def SetTroughState(trough: Pointer[Trough], trough_state: Pointer[TroughState])

@value
struct DefaultTroughFactory(TroughFactory):
    def MakeTrough(location: Location) -> Pointer[Trough]
    def MakeSpecifications() -> Pointer[TroughSpecifications]
    def MakeTroughState() -> Pointer[TroughState]
    def MakeTimeLocationWeather(location: Location) -> Pointer[TimeAndWeather]
    def MakeTimestepAndTou() -> TimestepAndTou
    def MakeInletState() -> FluidInletState
    def MakeDefocus() -> Float64
    def MakeLocation() -> Location

def MakeTrough(trough_specifications: Pointer[TroughSpecifications], location: Location) -> Pointer[Trough]:
    var trough = Pointer[Trough].alloc()
    var ts = trough_specifications[]
    trough[].m_nSCA = ts.nSCA
    trough[].m_nHCEt = ts.nHCEt
    trough[].m_nColt = ts.nColt
    trough[].m_nHCEVar = ts.nHCEVar
    trough[].m_nLoops = ts.nLoops
    trough[].m_FieldConfig = ts.FieldConfig
    trough[].m_L_power_block_piping = ts.L_power_block_piping
    trough[].m_include_fixed_power_block_runner = ts.include_fixed_power_block_runner
    trough[].m_eta_pump = ts.eta_pump
    trough[].m_Fluid = ts.Fluid
    trough[].m_fthrctrl = ts.fthrctrl
    trough[].m_accept_loc = ts.accept_loc
    trough[].m_HDR_rough = ts.HDR_rough
    trough[].m_theta_stow = ts.theta_stow
    trough[].m_theta_dep = ts.theta_dep
    trough[].m_Row_Distance = ts.Row_Distance
    trough[].m_T_loop_in_des = ts.T_loop_in_des
    trough[].m_T_loop_out_des = ts.T_loop_out_des
    trough[].m_T_startup = ts.T_startup
    trough[].m_m_dot_htfmin = ts.m_dot_htfmin
    trough[].m_m_dot_htfmax = ts.m_dot_htfmax
    trough[].m_field_fl_props = ts.field_fl_props
    trough[].m_T_fp = ts.T_fp
    trough[].m_I_bn_des = ts.I_bn_des
    trough[].m_V_hdr_cold_max = ts.V_hdr_cold_max
    trough[].m_V_hdr_cold_min = ts.V_hdr_cold_min
    trough[].m_V_hdr_hot_max = ts.V_hdr_hot_max
    trough[].m_V_hdr_hot_min = ts.V_hdr_hot_min
    trough[].m_V_hdr_max = ts.V_hdr_max
    trough[].m_V_hdr_min = ts.V_hdr_min
    trough[].m_Pipe_hl_coef = ts.Pipe_hl_coef
    trough[].m_SCA_drives_elec = ts.SCA_drives_elec
    trough[].m_ColTilt = ts.ColTilt
    trough[].m_ColAz = ts.ColAz
    trough[].m_wind_stow_speed = ts.wind_stow_speed
    trough[].m_accept_mode = ts.accept_mode
    trough[].m_accept_init = ts.accept_init
    trough[].m_solar_mult = ts.solar_mult
    trough[].m_mc_bal_hot_per_MW = ts.mc_bal_hot_per_MW
    trough[].m_mc_bal_cold_per_MW = ts.mc_bal_cold_per_MW
    trough[].m_mc_bal_sca = ts.mc_bal_sca
    trough[].m_W_aperture = ts.W_aperture
    trough[].m_A_aperture = ts.A_aperture
    trough[].m_TrackingError = ts.TrackingError
    trough[].m_GeomEffects = ts.GeomEffects
    trough[].m_Rho_mirror_clean = ts.Rho_mirror_clean
    trough[].m_Dirt_mirror = ts.Dirt_mirror
    trough[].m_Error = ts.Error
    trough[].m_Ave_Focal_Length = ts.Ave_Focal_Length
    trough[].m_L_SCA = ts.L_SCA
    trough[].m_L_aperture = ts.L_aperture
    trough[].m_ColperSCA = ts.ColperSCA
    trough[].m_Distance_SCA = ts.Distance_SCA
    trough[].m_IAM_matrix = ts.IAM_matrix
    trough[].m_HCE_FieldFrac = ts.HCE_FieldFrac
    trough[].m_D_2 = ts.D_2
    trough[].m_D_3 = ts.D_3
    trough[].m_D_4 = ts.D_4
    trough[].m_D_5 = ts.D_5
    trough[].m_D_p = ts.D_p
    trough[].m_Flow_type = ts.Flow_type
    trough[].m_Rough = ts.Rough
    trough[].m_alpha_env = ts.alpha_env
    trough[].m_epsilon_3_11 = ts.epsilon_3_11
    trough[].m_epsilon_3_12 = ts.epsilon_3_12
    trough[].m_epsilon_3_13 = ts.epsilon_3_13
    trough[].m_epsilon_3_14 = ts.epsilon_3_14
    trough[].m_epsilon_3_21 = ts.epsilon_3_21
    trough[].m_epsilon_3_22 = ts.epsilon_3_22
    trough[].m_epsilon_3_23 = ts.epsilon_3_23
    trough[].m_epsilon_3_24 = ts.epsilon_3_24
    trough[].m_epsilon_3_31 = ts.epsilon_3_31
    trough[].m_epsilon_3_32 = ts.epsilon_3_32
    trough[].m_epsilon_3_33 = ts.epsilon_3_33
    trough[].m_epsilon_3_34 = ts.epsilon_3_34
    trough[].m_epsilon_3_41 = ts.epsilon_3_41
    trough[].m_epsilon_3_42 = ts.epsilon_3_42
    trough[].m_epsilon_3_43 = ts.epsilon_3_43
    trough[].m_epsilon_3_44 = ts.epsilon_3_44
    trough[].m_alpha_abs = ts.alpha_abs
    trough[].m_Tau_envelope = ts.Tau_envelope
    trough[].m_EPSILON_4 = ts.EPSILON_4
    trough[].m_EPSILON_5 = ts.EPSILON_5
    trough[].m_GlazingIntact = ts.GlazingIntact
    trough[].m_P_a = ts.P_a
    trough[].m_AnnulusGas = ts.AnnulusGas
    trough[].m_AbsorberMaterial = ts.AbsorberMaterial
    trough[].m_Shadowing = ts.Shadowing
    trough[].m_Dirt_HCE = ts.Dirt_HCE
    trough[].m_Design_loss = ts.Design_loss
    trough[].m_SCAInfoArray = ts.SCAInfoArray
    trough[].m_calc_design_pipe_vals = ts.calc_design_pipe_vals
    trough[].m_L_rnr_pb = ts.L_rnr_pb
    trough[].m_N_max_hdr_diams = ts.N_max_hdr_diams
    trough[].m_L_rnr_per_xpan = ts.L_rnr_per_xpan
    trough[].m_L_xpan_hdr = ts.L_xpan_hdr
    trough[].m_L_xpan_rnr = ts.L_xpan_rnr
    trough[].m_Min_rnr_xpans = ts.Min_rnr_xpans
    trough[].m_northsouth_field_sep = ts.northsouth_field_sep
    trough[].m_N_hdr_per_xpan = ts.N_hdr_per_xpan
    trough[].m_K_cpnt = ts.K_cpnt
    trough[].m_D_cpnt = ts.D_cpnt
    trough[].m_L_cpnt = ts.L_cpnt
    trough[].m_Type_cpnt = ts.Type_cpnt
    trough[].m_custom_sf_pipe_sizes = ts.custom_sf_pipe_sizes
    trough[].m_sf_rnr_diams = ts.sf_rnr_diams
    trough[].m_sf_rnr_wallthicks = ts.sf_rnr_wallthicks
    trough[].m_sf_rnr_lengths = ts.sf_rnr_lengths
    trough[].m_sf_hdr_diams = ts.sf_hdr_diams
    trough[].m_sf_hdr_wallthicks = ts.sf_hdr_wallthicks
    trough[].m_sf_hdr_lengths = ts.sf_hdr_lengths
    var trough_solved_params = TroughSolvedParams()
    trough[].init(location, trough_solved_params)
    return trough

def SetTroughState(trough: Pointer[Trough], trough_state: Pointer[TroughState]):
    var N_scas_trough = len(trough[].m_T_htf_out_t_end_converged)
    var N_scas_state = len(trough_state[].T_out_SCAs_prev)
    if N_scas_trough != N_scas_state:
        raise Error("Incorrect trough state array length.")
    trough[].m_T_sys_c_t_end_converged = trough_state[].T_in_loop_prev
    trough[].m_T_sys_h_t_end_converged = trough_state[].T_out_loop_prev
    for i in range(len(trough_state[].T_out_SCAs_prev)):
        trough[].m_T_htf_out_t_end_converged[i] = trough_state[].T_out_SCAs_prev[i]

def DefaultTroughFactory_MakeTrough(self: DefaultTroughFactory, location: Location) -> Pointer[Trough]:
    var trough_specifications = self.MakeSpecifications()
    var trough = MakeTrough(trough_specifications, location)
    return trough

def DefaultTroughFactory_MakeSpecifications(self: DefaultTroughFactory) -> Pointer[TroughSpecifications]:
    var trough_specifications = Pointer[TroughSpecifications].alloc()
    trough_specifications[].nSCA = 8
    trough_specifications[].nHCEt = 4
    trough_specifications[].nColt = 4
    trough_specifications[].nHCEVar = 4
    trough_specifications[].nLoops = 181
    trough_specifications[].FieldConfig = 2
    trough_specifications[].L_power_block_piping = 50.
    trough_specifications[].include_fixed_power_block_runner = True
    trough_specifications[].eta_pump = 0.85
    trough_specifications[].Fluid = 21
    trough_specifications[].fthrctrl = 2
    trough_specifications[].accept_loc = 1
    trough_specifications[].HDR_rough = 4.57e-5
    trough_specifications[].theta_stow = 170.
    trough_specifications[].theta_dep = 10.
    trough_specifications[].Row_Distance = 15.
    trough_specifications[].T_loop_in_des = 293.
    trough_specifications[].T_loop_out_des = 391.
    trough_specifications[].T_startup = 0.67 * trough_specifications[].T_loop_in_des + 0.33 * trough_specifications[].T_loop_out_des
    trough_specifications[].m_dot_htfmin = 1.
    trough_specifications[].m_dot_htfmax = 12.
    var vals: List[Float64] = List[Float64](0.)
    trough_specifications[].field_fl_props = matrix_t[Float64](vals, 1, 1)
    trough_specifications[].T_fp = 150.
    trough_specifications[].I_bn_des = 950.
    trough_specifications[].V_hdr_cold_max = 3.
    trough_specifications[].V_hdr_cold_min = 2.
    trough_specifications[].V_hdr_hot_max = 3.
    trough_specifications[].V_hdr_hot_min = 2.
    trough_specifications[].V_hdr_max = min(trough_specifications[].V_hdr_cold_max, trough_specifications[].V_hdr_hot_max)
    trough_specifications[].V_hdr_min = max(trough_specifications[].V_hdr_cold_min, trough_specifications[].V_hdr_hot_min)
    trough_specifications[].Pipe_hl_coef = 0.45
    trough_specifications[].SCA_drives_elec = 125.
    trough_specifications[].ColTilt = 0.
    trough_specifications[].ColAz = 0.
    trough_specifications[].wind_stow_speed = 25.
    trough_specifications[].accept_mode = 0
    trough_specifications[].accept_init = False
    trough_specifications[].solar_mult = 2.
    trough_specifications[].mc_bal_hot_per_MW = 0.2
    trough_specifications[].mc_bal_cold_per_MW = 0.2
    trough_specifications[].mc_bal_sca = 4.5
    trough_specifications[].W_aperture = List[Float64](6., 6., 6., 6.)
    trough_specifications[].A_aperture = List[Float64](656., 656., 656., 656.)
    trough_specifications[].TrackingError = List[Float64](0.988, 0.988, 0.988, 0.988)
    trough_specifications[].GeomEffects = List[Float64](0.952, 0.952, 0.952, 0.952)
    trough_specifications[].Rho_mirror_clean = List[Float64](0.93, 0.93, 0.93, 0.93)
    trough_specifications[].Dirt_mirror = List[Float64](0.97, 0.97, 0.97, 0.97)
    trough_specifications[].Error = List[Float64](1., 1., 1., 1.)
    trough_specifications[].Ave_Focal_Length = List[Float64](2.15, 2.15, 2.15, 2.15)
    trough_specifications[].L_SCA = List[Float64](115., 115., 115., 115.)
    trough_specifications[].L_aperture = List[Float64](14.375, 14.375, 14.375, 14.375)
    trough_specifications[].ColperSCA = List[Float64](8., 8., 8., 8.)
    trough_specifications[].Distance_SCA = List[Float64](1., 1., 1., 1.)
    var vals2: List[Float64] = List[Float64](
        1., 0.0327, -0.1351,
        1., 0.0327, -0.1351,
        1., 0.0327, -0.1351,
        1., 0.0327, -0.1351)
    trough_specifications[].IAM_matrix = matrix_t[Float64](vals2, 4, 3)
    var vals3: List[Float64] = List[Float64](
        0.985, 0.01, 0.005, 0.,
        1., 0., 0., 0.,
        1., 0., 0., 0.,
        1., 0., 0., 0.)
    trough_specifications[].HCE_FieldFrac = matrix_t[Float64](vals3, 4, 4)
    var vals4: List[Float64] = List[Float64](
        0.076, 0.076, 0.076, 0.076,
        0.076, 0.076, 0.076, 0.076,
        0.076, 0.076, 0.076, 0.076,
        0.076, 0.076, 0.076, 0.076)
    trough_specifications[].D_2 = matrix_t[Float64](vals4, 4, 4)
    var vals5: List[Float64] = List[Float64](
        0.08, 0.08, 0.08, 0.08,
        0.08, 0.08, 0.08, 0.08,
        0.08, 0.08, 0.08, 0.08,
        0.08, 0.08, 0.08, 0.08)
    trough_specifications[].D_3 = matrix_t[Float64](vals5, 4, 4)
    var vals6: List[Float64] = List[Float64](
        0.115, 0.115, 0.115, 0.115,
        0.115, 0.115, 0.115, 0.115,
        0.115, 0.115, 0.115, 0.115,
        0.115, 0.115, 0.115, 0.115)
    trough_specifications[].D_4 = matrix_t[Float64](vals6, 4, 4)
    var vals7: List[Float64] = List[Float64](
        0.12, 0.12, 0.12, 0.12,
        0.12, 0.12, 0.12, 0.12,
        0.12, 0.12, 0.12, 0.12,
        0.12, 0.12, 0.12, 0.12)
    trough_specifications[].D_5 = matrix_t[Float64](vals7, 4, 4)
    var vals8: List[Float64] = List[Float64](
        0., 0., 0., 0.,
        0., 0., 0., 0.,
        0., 0., 0., 0.,
        0., 0., 0., 0.)
    trough_specifications[].D_p = matrix_t[Float64](vals8, 4, 4)
    var vals9: List[Float64] = List[Float64](
        1., 1., 1., 1.,
        1., 1., 1., 1.,
        1., 1., 1., 1.,
        1., 1., 1., 1.)
    trough_specifications[].Flow_type = matrix_t[Float64](vals9, 4, 4)
    var vals10: List[Float64] = List[Float64](
        4.5e-5, 4.5e-5, 4.5e-5, 4.5e-5,
        4.5e-5, 4.5e-5, 4.5e-5, 4.5e-5,
        4.5e-5, 4.5e-5, 4.5e-5, 4.5e-5,
        4.5e-5, 4.5e-5, 4.5e-5, 4.5e-5)
    trough_specifications[].Rough = matrix_t[Float64](vals10, 4, 4)
    var vals11: List[Float64] = List[Float64](
        0.02, 0.02, 0., 0.,
        0.02, 0.02, 0., 0.,
        0.02, 0.02, 0., 0.,
        0.02, 0.02, 0., 0.)
    trough_specifications[].alpha_env = matrix_t[Float64](vals11, 4, 4)
    var vals12: List[Float64] = List[Float64](
        100., 150., 200., 250., 300., 350., 400., 450., 500.,
        0.064, 0.0665, 0.07, 0.0745, 0.08, 0.0865, 0.094, 0.1025, 0.112)
    trough_specifications[].epsilon_3_11 = matrix_t[Float64](vals12, 2, 9)
    var vals13: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_12 = matrix_t[Float64](vals13, 1, 1)
    var vals14: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_13 = matrix_t[Float64](vals14, 1, 1)
    var vals15: List[Float64] = List[Float64](0.)
    trough_specifications[].epsilon_3_14 = matrix_t[Float64](vals15, 0, 0)
    var vals16: List[Float64] = List[Float64](
        100., 150., 200., 250., 300., 350., 400., 450., 500.,
        0.064, 0.0665, 0.07, 0.0745, 0.08, 0.0865, 0.094, 0.1025, 0.112)
    trough_specifications[].epsilon_3_21 = matrix_t[Float64](vals16, 2, 9)
    var vals17: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_22 = matrix_t[Float64](vals17, 1, 1)
    var vals18: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_23 = matrix_t[Float64](vals18, 1, 1)
    var vals19: List[Float64] = List[Float64](0.)
    trough_specifications[].epsilon_3_24 = matrix_t[Float64](vals19, 1, 1)
    var vals20: List[Float64] = List[Float64](
        100., 150., 200., 250., 300., 350., 400., 450., 500.,
        0.064, 0.0665, 0.07, 0.0745, 0.08, 0.0865, 0.094, 0.1025, 0.112)
    trough_specifications[].epsilon_3_31 = matrix_t[Float64](vals20, 2, 9)
    var vals21: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_32 = matrix_t[Float64](vals21, 1, 1)
    var vals22: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_33 = matrix_t[Float64](vals22, 1, 1)
    var vals23: List[Float64] = List[Float64](0.)
    trough_specifications[].epsilon_3_34 = matrix_t[Float64](vals23, 1, 1)
    var vals24: List[Float64] = List[Float64](
        100., 150., 200., 250., 300., 350., 400., 450., 500.,
        0.064, 0.0665, 0.07, 0.0745, 0.08, 0.0865, 0.094, 0.1025, 0.112)
    trough_specifications[].epsilon_3_41 = matrix_t[Float64](vals24, 2, 9)
    var vals25: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_42 = matrix_t[Float64](vals25, 1, 1)
    var vals26: List[Float64] = List[Float64](0.65)
    trough_specifications[].epsilon_3_43 = matrix_t[Float64](vals26, 1, 1)
    var vals27: List[Float64] = List[Float64](0.)
    trough_specifications[].epsilon_3_44 = matrix_t[Float64](vals27, 1, 1)
    var vals28: List[Float64] = List[Float64](
        0.963, 0.963, 0.8, 0.,
        0.963, 0.963, 0.8, 0.,
        0.963, 0.963, 0.8, 0.,
        0.963, 0.963, 0.8, 0.)
    trough_specifications[].alpha_abs = matrix_t[Float64](vals28, 4, 4)
    var vals29: List[Float64] = List[Float64](
        0.964, 0.964, 1., 0.,
        0.964, 0.964, 1., 0.,
        0.964, 0.964, 1., 0.,
        0.964, 0.964, 1., 0.)
    trough_specifications[].Tau_envelope = matrix_t[Float64](vals29, 4, 4)
    var vals30: List[Float64] = List[Float64](
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.)
    trough_specifications[].EPSILON_4 = matrix_t[Float64](vals30, 4, 4)
    var vals31: List[Float64] = List[Float64](
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.,
        0.86, 0.86, 1., 0.)
    trough_specifications[].EPSILON_5 = matrix_t[Float64](vals31, 4, 4)
    var vals32: List[Float64] = List[Float64](
        1., 1., 0., 1.,
        1., 1., 0., 1.,
        1., 1., 0., 1.,
        1., 1., 0., 1.)
    trough_specifications[].GlazingIntact_dbl = matrix_t[Float64](vals32, 4, 4)
    var n_gl_row = Int(trough_specifications[].GlazingIntact_dbl.nrows())
    var n_gl_col = Int(trough_specifications[].GlazingIntact_dbl.ncols())
    trough_specifications[].GlazingIntact = matrix_t[Bool](n_gl_row, n_gl_col)
    for i in range(n_gl_row):
        for j in range(n_gl_col):
            trough_specifications[].GlazingIntact[i, j] = (trough_specifications[].GlazingIntact_dbl[i, j] > 0.)
    var vals33: List[Float64] = List[Float64](
        1.e-4, 750., 750., 0.,
        1.e-4, 750., 750., 0.,
        1.e-4, 750., 750., 0.,
        1.e-4, 750., 750., 0.)
    trough_specifications[].P_a = matrix_t[Float64](vals33, 4, 4)
    var vals34: List[Float64] = List[Float64](
        27., 1., 1., 27.,
        27., 1., 1., 27.,
        27., 1., 1., 27.,
        27., 1., 1., 27.)
    trough_specifications[].AnnulusGas = matrix_t[Float64](vals34, 4, 4)
    var vals35: List[Float64] = List[Float64](
        1., 1., 1., 1.,
        1., 1., 1., 1.,
        1., 1., 1., 1.,
        1., 1., 1., 1.)
    trough_specifications[].AbsorberMaterial = matrix_t[Float64](vals35, 4, 4)
    var vals36: List[Float64] = List[Float64](
        0.935, 0.935, 0.935, 0.963,
        0.935, 0.935, 0.935, 0.963,
        0.935, 0.935, 0.935, 0.963,
        0.935, 0.935, 0.935, 0.963)
    trough_specifications[].Shadowing = matrix_t[Float64](vals36, 4, 4)
    var vals37: List[Float64] = List[Float64](
        0.98, 0.98, 1., 0.98,
        0.98, 0.98, 1., 0.98,
        0.98, 0.98, 1., 0.98,
        0.98, 0.98, 1., 0.98)
    trough_specifications[].Dirt_HCE = matrix_t[Float64](vals37, 4, 4)
    var vals38: List[Float64] = List[Float64](
        190., 1270., 1500., 0.,
        190., 1270., 1500., 0.,
        190., 1270., 1500., 0.,
        190., 1270., 1500., 0.)
    trough_specifications[].Design_loss = matrix_t[Float64](vals38, 4, 4)
    var vals39: List[Float64] = List[Float64](
        1., 1.,
        1., 1.,
        1., 1.,
        1., 1.,
        1., 1.,
        1., 1.,
        1., 1.,
        1., 1.)
    trough_specifications[].SCAInfoArray = matrix_t[Float64](vals39, 8, 2)
    trough_specifications[].calc_design_pipe_vals = True
    trough_specifications[].L_rnr_pb = 25.
    trough_specifications[].N_max_hdr_diams = 10.
    trough_specifications[].L_rnr_per_xpan = 70.
    trough_specifications[].L_xpan_hdr = 20.
    trough_specifications[].L_xpan_rnr = 20.
    trough_specifications[].Min_rnr_xpans = 1.
    trough_specifications[].northsouth_field_sep = 20.
    trough_specifications[].N_hdr_per_xpan = 2.
    var vals40: List[Float64] = List[Float64](
        0.9, 0., 0.19, 0., 0.9, -1., -1., -1., -1., -1., -1.,
        0., 0.6, 0.05, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.42, 0., 0.15,
        0.05, 0., 0.42, 0., 0.6, 0., 0.6, 0., 0.15, 0.6, 0.,
        0.9, 0., 0.19, 0., 0.9, -1., -1., -1., -1., -1., -1.)
    trough_specifications[].K_cpnt = matrix_t[Float64](vals40, 11, 11)
    var vals41: List[Float64] = List[Float64](
        0.085, 0.0635, 0.085, 0.0635, 0.085, -1., -1., -1., -1., -1., -1.,
        0.085, 0.085, 0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085,
        0.085, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.0635, 0.085, 0.085, 0.085,
        0.085, 0.0635, 0.085, 0.0635, 0.085, -1., -1., -1., -1., -1., -1.)
    trough_specifications[].D_cpnt = matrix_t[Float64](vals41, 11, 11)
    var vals42: List[Float64] = List[Float64](
        0., 0., 0., 0., 0., -1., -1., -1., -1., -1., -1.,
        0., 0., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 1., 0.,
        0., 1., 0., 1., 0., 0., 0., 1., 0., 0., 0.,
        0., 0., 0., 0., 0., -1., -1., -1., -1., -1., -1.)
    trough_specifications[].L_cpnt = matrix_t[Float64](vals42, 11, 11)
    var vals43: List[Float64] = List[Float64](
        0., 1., 0., 1., 0., -1., -1., -1., -1., -1., -1.,
        1., 0., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 2., 0.,
        0., 2., 0., 2., 0., 1., 0., 2., 0., 0., 1.,
        0., 1., 0., 1., 0., -1., -1., -1., -1., -1., -1.)
    trough_specifications[].Type_cpnt = matrix_t[Float64](vals43, 11, 11)
    trough_specifications[].custom_sf_pipe_sizes = False
    var vals44: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_rnr_diams = matrix_t[Float64](vals44, 1, 1)
    var vals45: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_rnr_wallthicks = matrix_t[Float64](vals45, 1, 1)
    var vals46: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_rnr_lengths = matrix_t[Float64](vals46, 1, 1)
    var vals47: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_hdr_diams = matrix_t[Float64](vals47, 1, 1)
    var vals48: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_hdr_wallthicks = matrix_t[Float64](vals48, 1, 1)
    var vals49: List[Float64] = List[Float64](-1.)
    trough_specifications[].sf_hdr_lengths = matrix_t[Float64](vals49, 1, 1)
    return trough_specifications

def DefaultTroughFactory_MakeTroughState(self: DefaultTroughFactory) -> Pointer[TroughState]:
    var trough_state = Pointer[TroughState].alloc()
    trough_state[].T_in_loop_prev = 574.6
    trough_state[].T_out_loop_prev = 664.5
    trough_state[].T_out_SCAs_prev = List[Float64]()
    trough_state[].T_out_SCAs_prev.append(586.5)
    trough_state[].T_out_SCAs_prev.append(598.4)
    trough_state[].T_out_SCAs_prev.append(610.0)
    trough_state[].T_out_SCAs_prev.append(621.4)
    trough_state[].T_out_SCAs_prev.append(632.5)
    trough_state[].T_out_SCAs_prev.append(643.4)
    trough_state[].T_out_SCAs_prev.append(654.1)
    trough_state[].T_out_SCAs_prev.append(664.5)
    return trough_state

def DefaultTroughFactory_MakeTimeLocationWeather(self: DefaultTroughFactory, location: Location) -> Pointer[TimeAndWeather]:
    var time_and_weather = Pointer[TimeAndWeather].alloc()
    time_and_weather[].m_year = 2009
    time_and_weather[].m_month = 2
    time_and_weather[].m_day = 14
    time_and_weather[].m_hour = 12
    time_and_weather[].m_minute = 0
    time_and_weather[].m_beam = 1016.0
    time_and_weather[].m_tdry = 16.0
    time_and_weather[].m_tdew = -14.0
    time_and_weather[].m_wspd = 1.2
    time_and_weather[].m_pres = 920.0
    time_and_weather[].m_solazi = 167.06
    time_and_weather[].m_solzen = 45.79
    time_and_weather[].m_lat = location.m_latitude
    time_and_weather[].m_lon = location.m_longitude
    time_and_weather[].m_tz = location.m_tz
    time_and_weather[].m_shift = location.m_shift
    time_and_weather[].m_elev = location.m_elev
    time_and_weather[].m_global = quiet_nan(Float64)
    time_and_weather[].m_hor_beam = quiet_nan(Float64)
    time_and_weather[].m_diffuse = quiet_nan(Float64)
    time_and_weather[].m_twet = quiet_nan(Float64)
    time_and_weather[].m_wdir = quiet_nan(Float64)
    time_and_weather[].m_rhum = quiet_nan(Float64)
    time_and_weather[].m_snow = quiet_nan(Float64)
    time_and_weather[].m_albedo = quiet_nan(Float64)
    time_and_weather[].m_aod = quiet_nan(Float64)
    time_and_weather[].m_poa = quiet_nan(Float64)
    time_and_weather[].m_time_rise = quiet_nan(Float64)
    time_and_weather[].m_time_set = quiet_nan(Float64)
    return time_and_weather

def DefaultTroughFactory_MakeTimestepAndTou(self: DefaultTroughFactory) -> TimestepAndTou:
    var timestep_and_tou = TimestepAndTou()
    timestep_and_tou.ms_ts.m_time_start = 3844800.
    timestep_and_tou.ms_ts.m_step = 3600.
    timestep_and_tou.ms_ts.m_time = timestep_and_tou.ms_ts.m_time_start + timestep_and_tou.ms_ts.m_step
    timestep_and_tou.m_tou = 1.
    return timestep_and_tou

def DefaultTroughFactory_MakeInletState(self: DefaultTroughFactory) -> FluidInletState:
    var fluid_inlet_state = FluidInletState()
    fluid_inlet_state.m_temp = 296.5
    fluid_inlet_state.m_pres = quiet_nan(Float64)
    fluid_inlet_state.m_qual = -1.
    fluid_inlet_state.m_m_dot = quiet_nan(Float64)
    return fluid_inlet_state

def DefaultTroughFactory_MakeDefocus(self: DefaultTroughFactory) -> Float64:
    return 1.

def DefaultTroughFactory_MakeLocation(self: DefaultTroughFactory) -> Location:
    var location = Location()
    location.m_latitude = 32.13000107
    location.m_longitude = -110.9400024
    location.m_tz = -7
    location.m_shift = -5.940002441
    location.m_elev = -773
    return location

NAMESPACE_TEST(csp_trough, TroughLoop, DefaultTest)
    var default_trough_factory = DefaultTroughFactory()
    var location = default_trough_factory.MakeLocation()
    var trough = default_trough_factory.MakeTrough(location)
    var trough_state = default_trough_factory.MakeTroughState()
    SetTroughState(trough, trough_state)
    var time_and_weather = default_trough_factory.MakeTimeLocationWeather(location)
    var fluid_inlet_state = default_trough_factory.MakeInletState()
    var defocus = default_trough_factory.MakeDefocus()
    var trough_outputs = TroughOutputs()
    var timestep_and_tou = default_trough_factory.MakeTimestepAndTou()
    trough[].on(time_and_weather[], fluid_inlet_state, defocus, trough_outputs, timestep_and_tou)
    EXPECT_NEAR(trough_outputs.m_T_salt_hot, 391.17, 391.17 * kErrorToleranceLo.value)
    EXPECT_NEAR(trough_outputs.m_m_dot_salt_tot, 6568369, 6568369 * kErrorToleranceLo.value)

NAMESPACE_TEST(csp_trough, TroughLoop, SteadyStateTest)
    var default_trough_factory = DefaultTroughFactory()
    var location = default_trough_factory.MakeLocation()
    var trough = default_trough_factory.MakeTrough(location)
    var trough_state = default_trough_factory.MakeTroughState()
    SetTroughState(trough, trough_state)
    var time_and_weather = default_trough_factory.MakeTimeLocationWeather(location)
    var fluid_inlet_state = default_trough_factory.MakeInletState()
    var defocus = default_trough_factory.MakeDefocus()
    var trough_outputs = TroughOutputs()
    var timestep_and_tou = default_trough_factory.MakeTimestepAndTou()
    trough[].m_accept_mode = 1
    trough[].m_accept_init = False
    trough[].m_accept_loc = 1
    trough[].m_is_using_input_gen = False
    time_and_weather[].m_beam = trough[].m_I_bn_des
    time_and_weather[].m_solazi = trough[].m_ColAz
    time_and_weather[].m_solzen = trough[].m_ColTilt
    timestep_and_tou.ms_ts.m_step = 5. * 60.
    timestep_and_tou.ms_ts.m_time = timestep_and_tou.ms_ts.m_time_start + timestep_and_tou.ms_ts.m_step
    fluid_inlet_state.m_temp = trough[].m_T_loop_in_des - 273.15
    trough[].m_T_sys_c_t_end_converged = trough[].m_T_loop_in_des
    trough[].m_T_sys_h_t_end_converged = trough[].m_T_loop_in_des
    for i in range(trough[].m_nSCA):
        trough[].m_T_htf_out_t_end_converged[i] = trough[].m_T_loop_in_des
    var ss_diff = quiet_nan(Float64)
    var tol = 0.05
    var T_htf_in_t_int_prev = List[Float64](trough[].m_T_htf_in_t_int)
    var T_htf_out_t_int_prev = List[Float64](trough[].m_T_htf_out_t_int)
    var minutes2SS = 0.
    do:
        trough[].on(time_and_weather[], fluid_inlet_state, defocus, trough_outputs, timestep_and_tou)
        ss_diff = 0.
        for i in range(trough[].m_nSCA):
            ss_diff += fabs(trough[].m_T_htf_in_t_int[i] - T_htf_in_t_int_prev[i]) + fabs(trough[].m_T_htf_out_t_int[i] - T_htf_out_t_int_prev[i])
        trough[].m_T_sys_c_t_end_converged = trough[].m_T_sys_c_t_end
        trough[].m_T_sys_h_t_end_converged = trough[].m_T_sys_h_t_end
        trough[].m_T_htf_out_t_end_converged = List[Float64](trough[].m_T_htf_out_t_end)
        T_htf_in_t_int_prev = List[Float64](trough[].m_T_htf_in_t_int)
        T_htf_out_t_int_prev = List[Float64](trough[].m_T_htf_out_t_int)
        minutes2SS += timestep_and_tou.ms_ts.m_step / 60.
    while ss_diff / 200. > tol
    EXPECT_NEAR(trough[].m_T_sys_h_t_end, 656.1, 656.1 * kErrorToleranceLo.value)
    EXPECT_NEAR(minutes2SS, 35., 35. * kErrorToleranceLo.value)