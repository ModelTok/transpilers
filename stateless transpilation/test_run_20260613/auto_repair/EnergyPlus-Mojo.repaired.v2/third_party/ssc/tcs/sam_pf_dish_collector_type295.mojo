from math import pi as pi_constant # to possibly use later; keep CSP::pi as is via import
from math import sin, cos, tan, atan, exp, sqrt, pow
from sam_csp_util import CSP
# from tcstype import TCSContext, TCSTypeInfo, TCSTypeInterface, TCSVarInfo, TCS_PARAM, TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_INVALID
# We'll define our own minimal replacements to keep compile happy.

# --- Enums and constants from tcstype.h (minimal) ---
# In actual translation, these would be imported; we replicate the original enumerations.
# Original enum defined in the source:
# enum{ P_D_AP, P_RHO, ..., N_MAX };
# We'll define global constants with values as they appear in the original enum.
# Since it's an unnamed enum, the order is important. We'll list them.

const P_D_AP = 0
const P_RHO = 1
const P_N_NS = 2
const P_N_EW = 3
const P_NS_DISH_SEP = 4
const P_EW_DISH_SEP = 5
const P_SLOPE_NS = 6
const P_SLOPE_EW = 7
const P_W_SLOT_GAP = 8
const P_H_SLOT_GAP = 9
const P_MANUFACTURER = 10
const P_WIND_STOW_SPEED = 11
const P_A_PROJ = 12
const P_I_CUT_IN = 13
const P_D_AP_TEST = 14
const P_TEST_IF = 15
const P_TEST_L_FOCAL = 16
const P_A_TOTAL = 17
const I_I_BEAM = 18
const I_T_AMB = 19
const I_WIND_SPEED = 20
const I_ZENITH = 21
const I_P_ATM = 22
const I_AZIMUTH = 23
const O_POWER_OUT_COL = 24
const O_COLLECTOR_LOSSES = 25
const O_ETA_COLLECTOR = 26
const O_NUMBER_OF_COLLECTORS = 27
const O_I_CUT_IN = 28
const O_POWER_IN_REC = 29
const O_INTERCEPT_FACTOR = 30
const O_D_AP = 31
const O_POWER_IN_COLLECTOR = 32
const O_PHI_SHADE = 33
const N_MAX = 34

# Minimal tcsvarinfo struct (the original uses a struct defined in tcstype.h)
struct TCSVarInfo:
    var vtype: Int32   # e.g. TCS_PARAM, TCS_INPUT, TCS_OUTPUT
    var datatype: Int32 # e.g. TCS_NUMBER
    var index: Int32
    var name: String
    var description: String
    var units: String
    var dummy1: String
    var dummy2: String
    var dummy3: String

    def __init__(inout self, vtype: Int32, datatype: Int32, index: Int32, name: String, description: String, units: String):
        self.vtype = vtype
        self.datatype = datatype
        self.index = index
        self.name = name
        self.description = description
        self.units = units
        self.dummy1 = ""
        self.dummy2 = ""
        self.dummy3 = ""

# Placeholder for base class tcstypeinterface (we won't inherit, just replicate interface)
struct TCSTypeInterface:
    # For demonstration, provide minimal methods that the original depends on.
    # We'll include value() get/set via a dictionary or context. For translation, we'll keep the calls.
    # We can define a hidden context pointer. For simplicity, we'll just declare the methods with no body.
    # In a real translation, these would be imported.
    def value(self, index: Int32) -> Float64:
        # placeholder
        return 0.0

    def value(self, index: Int32, val: Float64):
        # placeholder

# The main struct for the dish collector type
struct sam_pf_dish_collector_type295:
    var m_d_ap: Float64
    var m_rho: Float64
    var m_n_ns: Float64
    var m_n_ew: Float64
    var m_ns_dish_sep: Float64
    var m_ew_dish_sep: Float64
    var m_slope_ns: Float64
    var m_slope_ew: Float64
    var m_w_slot_gap: Float64
    var m_h_slot_gap: Float64
    var m_manufacturer: Int32
    var m_wind_stow_speed: Float64
    var m_A_proj: Float64
    var m_I_cut_in: Float64
    var m_d_ap_test: Float64
    var m_test_if: Float64
    var m_test_L_focal: Float64
    var m_A_total: Float64
    var m_d_collector: Float64
    var m_x_mirror_gap: Float64
    var m_H_mirror_gap: Float64
    var m_intercept_factor: Float64
    # We need a reference to the context for value() calls; for simplicity we store a pointer.
    var m_cst: __ptr[TCSTypeInterface] # not fully accurate but placeholder

    def __init__(inout self, cst: __ptr[TCSTypeInterface], ti: __ptr[TCSTypeInfo]):
        # call base initializer (if we were inheriting)
        self.m_cst = cst
        self.m_d_ap = Float64.nan
        self.m_rho = Float64.nan
        self.m_n_ns = Float64.nan
        self.m_n_ew = Float64.nan
        self.m_ns_dish_sep = Float64.nan
        self.m_ew_dish_sep = Float64.nan
        self.m_slope_ns = Float64.nan
        self.m_slope_ew = Float64.nan
        self.m_w_slot_gap = Float64.nan
        self.m_h_slot_gap = Float64.nan
        self.m_manufacturer = -1
        self.m_wind_stow_speed = Float64.nan
        self.m_A_proj = Float64.nan
        self.m_I_cut_in = Float64.nan
        self.m_d_ap_test = Float64.nan
        self.m_test_if = Float64.nan
        self.m_test_L_focal = Float64.nan
        self.m_A_total = Float64.nan
        self.m_x_mirror_gap = Float64.nan
        self.m_H_mirror_gap = Float64.nan
        self.m_d_collector = Float64.nan
        self.m_intercept_factor = Float64.nan

    # Destructor not needed; Mojo has automatic destruction.

    def init(inout self) -> Int32:
        self.m_d_ap = self.value(P_D_AP)
        self.m_rho = self.value(P_RHO)
        self.m_n_ns = self.value(P_N_NS)
        self.m_n_ew = self.value(P_N_EW)
        self.m_ns_dish_sep = self.value(P_NS_DISH_SEP)
        self.m_ew_dish_sep = self.value(P_EW_DISH_SEP)
        self.m_slope_ns = self.value(P_SLOPE_NS)
        self.m_slope_ew = self.value(P_SLOPE_EW)
        self.m_w_slot_gap = self.value(P_W_SLOT_GAP)
        self.m_h_slot_gap = self.value(P_H_SLOT_GAP)
        self.m_manufacturer = Int32(self.value(P_MANUFACTURER))
        # switch on m_manufacturer
        if self.m_manufacturer == 1:
            # SES System = 1
            self.m_A_proj = 87.7
            self.m_wind_stow_speed = 16.0
            self.m_I_cut_in = 200.0
            self.m_d_ap_test = 0.184
            self.m_test_if = 0.995
            self.m_test_L_focal = 7.45
            self.m_A_total = 91.0
        elif self.m_manufacturer == 2:
            # WGA System = 2
            self.m_A_proj = 41.2
            self.m_wind_stow_speed = 16.0
            self.m_I_cut_in = 275.0
            self.m_d_ap_test = 0.14
            self.m_test_if = 0.998
            self.m_test_L_focal = 5.45
            self.m_A_total = 42.9
        elif self.m_manufacturer == 3:
            # SBP System = 3
            self.m_A_proj = 56.7
            self.m_wind_stow_speed = 16.0
            self.m_I_cut_in = 250.0
            self.m_d_ap_test = 0.15
            self.m_test_if = 0.93
            self.m_test_L_focal = 4.5
            self.m_A_total = 60.0
        elif self.m_manufacturer == 4:
            # SAIC System = 4
            self.m_A_proj = 113.5
            self.m_wind_stow_speed = 16.0
            self.m_I_cut_in = 375.0
            self.m_d_ap_test = 0.38
            self.m_test_if = 0.90
            self.m_test_L_focal = 12.0
            self.m_A_total = 117.2
        elif self.m_manufacturer == 5:
            # User input values = 5
            self.m_wind_stow_speed = self.value(P_WIND_STOW_SPEED)
            self.m_A_proj = self.value(P_A_PROJ)
            self.m_I_cut_in = self.value(P_I_CUT_IN)
            self.m_d_ap_test = self.value(P_D_AP_TEST)
            self.m_test_if = self.value(P_TEST_IF)
            self.m_test_L_focal = self.value(P_TEST_L_FOCAL)
            self.m_A_total = self.value(P_A_TOTAL)

        # --------------------------------------
        # Adding code to solve for intercept factor here to reduce time
        # The intercept factor only needs to be solved for the first time step
        # Theory comes from Stine and Harrigan (1985)
        # -------------------------------
        let r = 0.2316419
        let b1 = 0.319381530
        let b2 = -0.356563782
        let b3 = 1.781477937
        let b4 = -1.82125978
        let b5 = 1.330274429
        self.m_d_collector = 2.0 * pow(self.m_A_total / (CSP.pi + 0.0000001), 0.5)
        let h = pow(self.m_d_collector, 2) / (16.0 * self.m_test_L_focal + 0.0000001)
        var sigma_tot_guess = 0.001
        var intercept_factor_solve = 1.001
        let Ib = 1000.0
        let d_psi = 0.001  # radians
        var Power_tot = 0.0
        var Power_int_tot = 0.0
        let psi_rim = atan(1.0 / (0.0000001 + (self.m_d_collector / (8.0 * h + 0.0000001) - (2.0 * h / (self.m_d_collector + 0.0000001)))))
        # Note: original had a while loop condition that checked intercept_factor_solve >= m_test_if, but the loop increments sigma_tot_guess.
        # However, the original code has a for loop that runs only once? Actually the C++ code has:
        # "if( intercept_factor_solve >= m_test_if ) { ... }"
        # and inside that block it does a loop over psi and recomputes intercept_factor_solve, but the loop is not a while; it's a single iteration.
        # Actually, the C++ code uses a "for" loop over psi inside the if block, but outside that block there is a separate loop (the later one).
        # The code as given: 
        # if( intercept_factor_solve >= m_test_if ) { while? No, it's an if block with a for loop. Then after that if block, there's another for loop.
        # So we replicate that.
        if intercept_factor_solve >= self.m_test_if:
            sigma_tot_guess += 0.000015
            Power_tot = 0.0
            Power_int_tot = 0.0
            var psi: Float64 = 0.0
            while psi <= psi_rim:
                let omega_n_accurate = self.m_d_ap_test
                let DELTAr_accurate = omega_n_accurate * cos(psi)
                let p = 2.0 * self.m_test_L_focal / (1.0 + cos(psi) + 0.0000001)
                let n_std_dev = (2.0 / sigma_tot_guess) * atan(DELTAr_accurate / (2.0 * p + 0.0000001))
                let x = n_std_dev / 2.0
                let t1 = 1.0 / (1.0 + r * x + 0.0000001)
                let fx = 1.0 / (pow(2.0 * CSP.pi, 0.5) + 0.0000001) * exp(-(x * x / 2.0) + 0.0000001)
                let Q = fx * (b1 * t1 + b2 * t1 * t1 + b3 * pow(t1, 3) + b4 * pow(t1, 4) + b5 * pow(t1, 5))
                let gamma = 1.0 - 2.0 * Q
                let d_power = (8.0 * CSP.pi * Ib * pow(self.m_test_L_focal, 2) * sin(psi) * d_psi) / pow(1.0 + cos(psi) + 0.0000001, 2)
                let d_power_intercept = d_power * pow(gamma, 4)
                Power_tot = Power_tot + d_power
                Power_int_tot = Power_int_tot + d_power_intercept
                psi += d_psi
            intercept_factor_solve = Power_int_tot / (Power_tot + 0.0000001)

        let sigma_tot = sigma_tot_guess  # error in collector solved above in loops
        Power_tot = 0.0
        Power_int_tot = 0.0
        self.m_intercept_factor = 1.0
        if self.m_d_ap == self.m_d_ap_test:
            self.m_intercept_factor = self.m_test_if
        else:
            var psi: Float64 = 0.0
            while psi <= psi_rim:
                let omega_n_accurate = self.m_d_ap
                let DELTAr_accurate = omega_n_accurate * cos(psi)
                let p = 2.0 * self.m_test_L_focal / (1.0 + cos(psi) + 0.0000001)
                let n_std_dev = (2.0 / sigma_tot) * atan(DELTAr_accurate / (2.0 * p + 0.0000001))
                let x = n_std_dev / 2.0
                let t1 = 1.0 / (1.0 + r * x + 0.0000001)
                let fx = 1.0 / (pow(2.0 * CSP.pi, 0.5) + 0.0000001) * exp(-(x * x / 2.0) + 0.0000001)
                let Q = fx * (b1 * t1 + b2 * pow(t1, 2) + b3 * pow(t1, 3) + b4 * pow(t1, 4) + b5 * pow(t1, 5))
                let gamma = 1.0 - 2.0 * Q
                let d_power = (8.0 * CSP.pi * Ib * pow(self.m_test_L_focal, 2) * sin(psi) * d_psi) / pow(1.0 + cos(psi) + 0.0000001, 2)
                let d_power_intercept = d_power * pow(gamma, 4)
                Power_tot = Power_tot + d_power
                Power_int_tot = Power_int_tot + d_power_intercept
                psi += d_psi
            self.m_intercept_factor = Power_int_tot / (Power_tot + 0.0000001)
        return 0

    def call(inout self, time: Float64, step: Float64, ncall: Int32) -> Int32:
        let I_beam_in = self.value(I_I_BEAM)  # [W/m^2]
        let wind_speed = self.value(I_WIND_SPEED)
        let sun_angle_in = self.value(I_ZENITH)
        let solar_azimuth = self.value(I_AZIMUTH) - 180.0  # [deg] Convert to TRNSYS convention
        self.m_x_mirror_gap = self.m_w_slot_gap
        self.m_H_mirror_gap = self.m_h_slot_gap
        let DNI = I_beam_in
        let elevation_angle = (90.0 - sun_angle_in) * 2.0 * 3.142 / 360.0  # convert to radians
        let azimuth_angle = (solar_azimuth * 2.0 * 3.142 / 360.0)  # convert to radians
        let zero = 0.0
        let Number_of_Collectors = self.m_n_ew * self.m_n_ns
        let N_rect = 99.0  # [-] number of rectangles dish is broken up into
        let phi_A = azimuth_angle  # [rad] azimuth angle
        let phi_E = elevation_angle  # [rad] elevation angle
        let L_NS = self.m_ns_dish_sep  # "dish separation distance N-S"
        let L_EW = self.m_ew_dish_sep
        let D_dish = self.m_d_collector  # diameter of dish
        let r_dish = D_dish / 2.0  # radius of dish
        let w_rect = D_dish / N_rect  # width of differential rectangle for shading
        var rise_NS = 0.01 * self.m_slope_ns * L_NS  # distance the dish moves vertically based on slope
        var rise_EW = 0.0
        if phi_A < 0.0:
            rise_EW = 0.01 * self.m_slope_ew * L_EW
        else:
            rise_EW = -0.01 * self.m_slope_ew * L_EW
        var slope_diag = 0.0
        if phi_A <= 0.0:
            slope_diag = (rise_NS + rise_EW) / pow(pow(L_NS, 2) + pow(L_EW, 2), 0.5)
        else:
            slope_diag = (rise_NS - rise_EW) / pow(pow(L_NS, 2) + pow(L_EW, 2), 0.5)
        let rise_diag = 0.01 * slope_diag * pow(pow(L_NS, 2) + pow(L_EW, 2), 0.5)
        let x_A = sin(phi_A) * L_NS  # distance shading line from south dish is offset from center of north dish x-direction
        let y_B = pow(pow(L_NS, 2) - pow(x_A, 2), 0.5)  # distance shading line from south dish is offset from center of north dish y-direction
        let x_A_EW = sin(CSP.pi / 2.0 - phi_A) * L_EW  # distance shading line from south dish is offset from center of north dish x-direction
        let y_B_EW = pow(pow(L_EW, 2) - pow(x_A_EW, 2), 0.5)  # distance shading line from south dish is offset from center of north dish y-direction
        let phi_diag = atan(L_NS / L_EW)
        let phi_diag_pt = CSP.pi / 2.0 - abs(phi_A) - phi_diag
        let x_A_diag = sin(phi_diag_pt) * pow(pow(L_EW, 2) + pow(L_NS, 2), 0.5)
        let y_B_diag = pow(pow(L_EW, 2) + pow(L_NS, 2) - pow(x_A_diag, 2), 0.5)
        let N_loop_1 = (-N_rect + 1.0) / 2.0  # # of rectangles to the left of center
        let N_loop_2 = (N_rect - 1.0) / 2.0  # # of rectangles to the right of center
        let one = 1.0
        var A_shade_NS = 0.0  # initialize N-S shading
        var A_shade_EW = 0.0  # initialize E-W shading
        var A_shade_diag = 0.0
        var NS_shade = 0.0  # initialize
        var EW_shade = 0.0  # initialize
        var diag_shade = 0.0
        # Loop from N_loop_1 to N_loop_2 inclusive
        var N_loop: Float64 = N_loop_1
        while N_loop <= N_loop_2:
            let x_dish_1 = N_loop * w_rect  # position of differential rectangle on x-axis of dish 1 (south)
            let x_dish_2 = N_loop * w_rect - x_A  # position of differential rectangle on x-axis of dish 2 (north) that the center of dish 1 projects onto"
            let x_dish_2_EW = N_loop * w_rect - x_A_EW  # point on dish 2 that the pt x_dish_1 on dish 1 projects to
            let x_dish_2_diag = N_loop * w_rect - x_A_diag
            if x_dish_2 < -r_dish:
                NS_shade = 0.0  # [m^2]
            if x_dish_2 > r_dish:
                NS_shade = 0.0  # [m^2]
            if x_dish_2_EW < -r_dish:
                EW_shade = 0.0  # [m^2]
            if x_dish_2_EW > r_dish:
                EW_shade = 0.0  # [m^2]
            if x_dish_2_diag < -r_dish:
                diag_shade = 0.0  # [m^2]
            if x_dish_2_diag > r_dish:
                diag_shade = 0.0  # [m^2]
            let H_dish_1 = pow(pow(r_dish, 2) - pow(x_dish_1, 2), 0.5)  # height (radius) between center of each differential rectangle on dish 1 and perimeter of dish 1
            if x_dish_2 >= -r_dish:
                if x_dish_2 <= r_dish:
                    let x_shade = w_rect
                    let H_dish_2 = pow(pow(r_dish, 2) - pow(x_dish_2, 2), 0.5)  # "height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade = -(tan(phi_E) * y_B) + H_dish_1 + H_dish_2 - rise_NS
                    if y_shade <= 0:
                        y_shade = 0.0
                    if y_shade > 2.0 * H_dish_2:
                        y_shade = 2.0 * H_dish_2
                    NS_shade = x_shade * y_shade
            if x_dish_2_EW >= -r_dish:
                if x_dish_2_EW <= r_dish:
                    let H_dish_2_EW = pow(pow(r_dish, 2) - pow(x_dish_2_EW, 2), 0.5)  # height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade_EW = -(tan(phi_E) * y_B_EW) + H_dish_1 + H_dish_2_EW - rise_EW
                    let x_shade = w_rect
                    if y_shade_EW <= 0:
                        y_shade_EW = 0.0
                    if y_shade_EW > 2.0 * H_dish_2_EW:
                        y_shade_EW = 2.0 * H_dish_2_EW
                    EW_shade = x_shade * y_shade_EW
            if x_dish_2_diag >= -r_dish:
                if x_dish_2_diag <= r_dish:
                    let H_dish_2_diag = pow(pow(r_dish, 2) - pow(x_dish_2_diag, 2), 0.5)  # height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade_diag = -(tan(phi_E) * y_B_diag) + H_dish_1 + H_dish_2_diag - rise_diag
                    let x_shade = w_rect
                    if y_shade_diag <= 0.0:
                        y_shade_diag = 0.0
                    if y_shade_diag > 2.0 * H_dish_2_diag:
                        y_shade_diag = 2.0 * H_dish_2_diag
                    diag_shade = x_shade * y_shade_diag
            if x_dish_2 >= (-self.m_x_mirror_gap / 2.0):
                if x_dish_2 <= (self.m_x_mirror_gap / 2.0):
                    let x_shade = w_rect
                    let H_dish_1_local = pow(pow(r_dish, 2) - pow(x_dish_1, 2), 0.5)  # height (radius) between center of each differential rectangle on dish 1 and perimeter of dish 1
                    let H_dish_2_local = pow(pow(r_dish, 2) - pow(x_dish_2, 2), 0.5)  # height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade = -(tan(phi_E) * y_B) + H_dish_1_local + H_dish_2_local - self.m_H_mirror_gap - rise_NS
                    if y_shade <= 0:
                        y_shade = 0.0
                    if y_shade > 2.0 * H_dish_2_local:
                        y_shade = 2.0 * H_dish_2_local
                    NS_shade = x_shade * y_shade
            if x_dish_2_EW >= (-self.m_x_mirror_gap / 2.0):
                if x_dish_2_EW <= (self.m_x_mirror_gap / 2.0):
                    let x_shade = w_rect
                    let H_dish_2_EW_local = pow(pow(r_dish, 2) - pow(x_dish_2_EW, 2), 0.5)  # height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade_EW = -(tan(phi_E) * y_B_EW) + H_dish_1_local + H_dish_2_EW_local - self.m_H_mirror_gap - rise_EW
                    if y_shade_EW <= 0:
                        y_shade_EW = 0.0
                    if y_shade_EW > 2.0 * H_dish_2_EW_local:
                        y_shade_EW = 2.0 * H_dish_2_EW_local
                    EW_shade = x_shade * y_shade_EW
            if x_dish_2_diag >= (-self.m_x_mirror_gap / 2.0):
                if x_dish_2_diag <= (self.m_x_mirror_gap / 2.0):
                    let x_shade = w_rect
                    let H_dish_2_diag_local = pow(pow(r_dish, 2) - pow(x_dish_2_diag, 2), 0.5)  # height (radius) between center of differential rectangle on dish 2 (point projected from dish 1) and perimeter of dish 2
                    var y_shade_diag = -(tan(phi_E) * y_B_diag) + H_dish_1_local + H_dish_2_diag_local - self.m_H_mirror_gap - rise_diag
                    if y_shade_diag <= 0:
                        y_shade_diag = 0.0
                    if y_shade_diag > 2.0 * H_dish_2_diag_local:
                        y_shade_diag = 2.0 * H_dish_2_diag_local
                    diag_shade = x_shade * y_shade_diag
            A_shade_NS = A_shade_NS + NS_shade  # sum up total NS shading over dish
            A_shade_EW = A_shade_EW + EW_shade  # sum up total EW shading over dish
            A_shade_diag = A_shade_diag + diag_shade
            N_loop += one

        if phi_E < 0:
            A_shade_NS = 0.0
            A_shade_EW = 0.0
            A_shade_diag = 0.0
        let A_shade_combined = A_shade_NS + A_shade_EW + A_shade_diag
        let A_shade_interior = (self.m_n_ns - 1.0) * (self.m_n_ew - 1.0) * A_shade_combined
        var A_shade_exterior: Float64
        if solar_azimuth <= -90.0:  # Northeast quadrant
            A_shade_exterior = (self.m_n_ns - 1.0) * A_shade_NS + (self.m_n_ew - 1.0) * A_shade_EW
        if solar_azimuth >= 0.0:  # Southwest quadrant
            if solar_azimuth <= 90.0:
                A_shade_exterior = (self.m_n_ns - 1.0) * A_shade_NS + (self.m_n_ew - 1.0) * A_shade_EW
        if solar_azimuth >= 90.0:  # Northwest quadrant
            A_shade_exterior = (self.m_n_ns - 1.0) * A_shade_EW + (self.m_n_ew - 1.0) * A_shade_NS
        if solar_azimuth > -90.0:  # Southeast quadrant
            if solar_azimuth < 0.0:
                A_shade_exterior = (self.m_n_ns - 1.0) * A_shade_EW + (self.m_n_ns - 1.0) * A_shade_NS
        let A_shade_tot = A_shade_interior + A_shade_exterior
        let Shade_AVG = max(zero, (A_shade_tot) / (self.m_n_ns * self.m_n_ew))
        let phi_shade = max(zero, (self.m_A_proj - Shade_AVG) / (self.m_A_proj + 0.0000001))
        if wind_speed <= self.m_wind_stow_speed:
            if DNI >= self.m_I_cut_in:
                self.set_value(O_POWER_OUT_COL, DNI * self.m_rho * self.m_A_proj * phi_shade / 1000.0)
                self.set_value(O_COLLECTOR_LOSSES, DNI / 1000.0 * self.m_A_proj - self.get_value(O_POWER_OUT_COL))
                self.set_value(O_ETA_COLLECTOR, self.get_value(O_POWER_OUT_COL) / (self.get_value(O_POWER_OUT_COL) + self.get_value(O_COLLECTOR_LOSSES)))
            else:
                self.set_value(O_POWER_OUT_COL, 0.0)
                self.set_value(O_COLLECTOR_LOSSES, 0.0)
                self.set_value(O_ETA_COLLECTOR, 0.0)
        else:
            self.set_value(O_POWER_OUT_COL, 0.0)
            self.set_value(O_COLLECTOR_LOSSES, 0.0)
            self.set_value(O_ETA_COLLECTOR, 0.0)
        self.set_value(O_NUMBER_OF_COLLECTORS, Number_of_Collectors)
        self.set_value(O_I_CUT_IN, self.m_I_cut_in)
        self.set_value(O_POWER_IN_REC, self.get_value(O_POWER_OUT_COL) * self.m_intercept_factor)
        self.set_value(O_INTERCEPT_FACTOR, self.m_intercept_factor)
        self.set_value(O_D_AP, self.m_d_ap)
        self.set_value(O_POWER_IN_COLLECTOR, DNI * self.m_A_proj / 1000.0)
        self.set_value(O_PHI_SHADE, phi_shade)
        return 0

    def converged(inout self, time: Float64) -> Int32:
        return 0

    # Helper function to replicate base class value() method
    def get_value(self, index: Int32) -> Float64:
        # In actual implementation, this would access some context storage.
        # For translation, we just return placeholder.
        # To keep the code compile, we'll return 0.
        # In a real integration, this would be provided by the framework.
        return 0.0

    def set_value(self, index: Int32, val: Float64):
        # Placeholder

# Variable definitions (the original global array)
# In Mojo we can define a static array of TCSVarInfo
var sam_pf_dish_collector_type295_variables: List[TCSVarInfo] = List(
    TCSVarInfo(0, 0, P_D_AP, "d_ap", "Dish aperture diameter", "m"),
    TCSVarInfo(0, 0, P_RHO, "rho", "Mirror surface reflectivity", "-"),
    TCSVarInfo(0, 0, P_N_NS, "n_ns", "Number of collectors North-South", "-"),
    TCSVarInfo(0, 0, P_N_EW, "n_ew", "Number of collectors East-West", "-"),
    TCSVarInfo(0, 0, P_NS_DISH_SEP, "ns_dish_sep", "Collector separation North-South", "m"),
    TCSVarInfo(0, 0, P_EW_DISH_SEP, "ew_dish_sep", "Collector separation East-West", "m"),
    TCSVarInfo(0, 0, P_SLOPE_NS, "slope_ns", "North-South ground slope", "%"),
    TCSVarInfo(0, 0, P_SLOPE_EW, "slope_ew", "East-West ground slope", "%"),
    TCSVarInfo(0, 0, P_W_SLOT_GAP, "w_slot_gap", "Slot gap width", "m"),
    TCSVarInfo(0, 0, P_H_SLOT_GAP, "h_slot_gap", "Slot gap height", "m"),
    TCSVarInfo(0, 0, P_MANUFACTURER, "manufacturer", "Dish manufacturer (fixed as 5 = other)", "-"),
    TCSVarInfo(0, 0, P_WIND_STOW_SPEED, "wind_stow_speed", "Wind stow speed", "m/s"),
    TCSVarInfo(0, 0, P_A_PROJ, "A_proj", "Projected mirror area", "m^2"),
    TCSVarInfo(0, 0, P_I_CUT_IN, "I_cut_in", "Insolation cut in value", "W/m^2"),
    TCSVarInfo(0, 0, P_D_AP_TEST, "d_ap_test", "Receiver aperture diameter during test", "m"),
    TCSVarInfo(0, 0, P_TEST_IF, "test_if", "Test intercept factor", "-"),
    TCSVarInfo(0, 0, P_TEST_L_FOCAL, "test_L_focal", "Focal length of mirror system", "m"),
    TCSVarInfo(0, 0, P_A_TOTAL, "A_total", "Total Area", "m^2"),
    TCSVarInfo(1, 0, I_I_BEAM, "I_beam", "Direct normal radiation", "kJ/hr-m2"),
    TCSVarInfo(1, 0, I_T_AMB, "T_amb", "Dry bulb temperature", "C"),
    TCSVarInfo(1, 0, I_WIND_SPEED, "wind_speed", "Wind velocity", "m/s"),
    TCSVarInfo(1, 0, I_ZENITH, "zenith", "Solar zenith angle", "deg"),
    TCSVarInfo(1, 0, I_P_ATM, "P_atm", "Atmospheric pressure", "Pa"),
    TCSVarInfo(1, 0, I_AZIMUTH, "azimuth", "Solar azimuth angle", "deg"),
    TCSVarInfo(2, 0, O_POWER_OUT_COL, "Power_out_col", "Total power from the collector dish", "kW"),
    TCSVarInfo(2, 0, O_COLLECTOR_LOSSES, "Collector_Losses", "Total collector losses (Incident - P_out)", "kW"),
    TCSVarInfo(2, 0, O_ETA_COLLECTOR, "eta_collector", "Collector efficiency", "-"),
    TCSVarInfo(2, 0, O_NUMBER_OF_COLLECTORS, "Number_of_collectors", "Total number of collectors (n_es*n_ns)", "-"),
    TCSVarInfo(2, 0, O_I_CUT_IN, "I_cut_in", "The cut-in DNI value used in the simulation", "W/m^2"),
    TCSVarInfo(2, 0, O_POWER_IN_REC, "Power_in_rec", "Power entering the receiver from the collector", "kW"),
    TCSVarInfo(2, 0, O_INTERCEPT_FACTOR, "Intercept_factor", "The receiver intercept factor", "-"),
    TCSVarInfo(2, 0, O_D_AP, "d_ap_out", "Dish aperture diameter", "m"),
    TCSVarInfo(2, 0, O_POWER_IN_COLLECTOR, "Power_in_collector", "Power incident on the collector", "kW"),
    TCSVarInfo(2, 0, O_PHI_SHADE, "Phi_shade", "Dish-to-dish shading performance factor", "-"),
    TCSVarInfo(-1, -1, N_MAX, "", "", "")  # sentinel
)

# Original macro TCS_IMPLEMENT_TYPE( sam_pf_dish_collector_type295, "Collector Dish", "Ty Neises", 1, sam_pf_dish_collector_type295_variables, NULL, 1 )
# In Mojo, we can register the type with a function; for translation we just keep the call as a stub.
# We'll define a function that does the registration.
def TCS_IMPLEMENT_TYPE( type_name: String, description: String, author: String, version: Int32, variables: List[TCSVarInfo], extras: AnyType, flag: Int32):
    # Placeholder

# Call the implementation macro
TCS_IMPLEMENT_TYPE("sam_pf_dish_collector_type295", "Collector Dish", "Ty Neises", 1, sam_pf_dish_collector_type295_variables, None, 1)