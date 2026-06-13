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
from lib_pvmodel import pvmodule_t, pvcelltemp_t, pvinput_t, pvoutput_t
from lib_pv_incidence_modifier import calculateIrradianceThroughCoverDeSoto
from lib_util import maxpower_5par, openvoltage_5par, current_5par, sind, cosd, tand, asind, MAX, MIN

var KB = 8.618e-5  # Boltzmann constant [eV/K] note units
var k_air: Float64 = 0.02676
var mu_air: Float64 = 1.927E-5
var Pr_air: Float64 = 0.724  # !Viscosity in units of N-s/m^2
var EmisC: Float64 = 0.84
var EmisB: Float64 = 0.7  # Emissivities of glass cover, backside material
var sigma: Float64 = 5.66961E-8
var cp_air: Float64 = 1005.5
var amavec: StaticTuple[Float64, 5] = StaticTuple(0.918093, 0.086257, -0.024459, 0.002816, -0.000126)  # !Air mass modifier coefficients as indicated in DeSoto paper
var Tc_ref: Float64 = (25 + 273.15)  # 25 'C
var I_ref: Float64 = 1000  # 1000 W/m2
var Tamb_noct: Float64 = 20  # 20 Ambient NOCT temp ('C)
var I_noct: Float64 = 800  # 800 NOCT Irradiance W/m2
var TauAlpha: Float64 = 0.9  # 0.9
var eg0: Float64 = 1.12  # 1.12

def air_mass_modifier(Zenith_deg: Float64, Elev_m: Float64, a: StaticTuple[Float64, 5]) -> Float64:
    var air_mass: Float64 = 1 / (cos(Zenith_deg * math.pi / 180) + 0.5057 * pow(96.080 - Zenith_deg, -1.634))
    air_mass *= exp(-0.0001184 * Elev_m)  # 'optional' correction for elevation (m), as applied in Sandia PV model
    var f1: Float64 = a[0] + a[1] * air_mass + a[2] * pow(air_mass, 2) + a[3] * pow(air_mass, 3) + a[4] * pow(air_mass, 4)
    return f1 if f1 > 0.0 else 0.0

@value
struct cec6par_module_t:
    var Area: Float64
    var Vmp: Float64
    var Imp: Float64
    var Voc: Float64
    var Isc: Float64
    var alpha_isc: Float64
    var beta_voc: Float64
    var a: Float64
    var Il: Float64
    var Io: Float64
    var Rs: Float64
    var Rsh: Float64
    var Adj: Float64

    def __init__(inout self):
        self.Area = Float64.NAN
        self.Vmp = Float64.NAN
        self.Imp = Float64.NAN
        self.Voc = Float64.NAN
        self.Isc = Float64.NAN
        self.alpha_isc = Float64.NAN
        self.beta_voc = Float64.NAN
        self.a = Float64.NAN
        self.Il = Float64.NAN
        self.Io = Float64.NAN
        self.Rs = Float64.NAN
        self.Rsh = Float64.NAN
        self.Adj = Float64.NAN

    def AreaRef(self) -> Float64:
        return self.Area

    def VmpRef(self) -> Float64:
        return self.Vmp

    def ImpRef(self) -> Float64:
        return self.Imp

    def VocRef(self) -> Float64:
        return self.Voc

    def IscRef(self) -> Float64:
        return self.Isc

    def __call__(self, input: pvinput_t, TcellC: Float64, opvoltage: Float64, out: pvoutput_t) -> Bool:
        var muIsc: Float64 = self.alpha_isc * (1 - self.Adj / 100)
        # initialize output first
        out.Power = 0.0
        out.Voltage = 0.0
        out.Current = 0.0
        out.Efficiency = 0.0
        out.Voc_oper = 0.0
        out.Isc_oper = 0.0
        out.AOIModifier = 0.0
        var G_front: Float64
        var G_total: Float64
        var Geff_front_total: Float64
        var Geff_total: Float64
        if input.radmode != 3:  # Determine if the model needs to skip the cover effects (will only be skipped if the user is using POA reference cell data)
            G_front = input.Ibeam + input.Idiff + input.Ignd
            G_total = G_front + input.Irear  # total incident irradiance on tilted surface, W/m2
            Geff_front_total = calculateIrradianceThroughCoverDeSoto(
                input.IncAng,
                input.Zenith,
                input.Tilt,
                input.Ibeam,
                input.Idiff,
                input.Ignd,
                False
            )
            Geff_total = Geff_front_total + input.Irear
            var aoi_modifier: Float64 = 0.0
            if G_front > 0.0:
                aoi_modifier = Geff_front_total / G_front
            out.AOIModifier = aoi_modifier
            var theta_z: Float64 = input.Zenith
            if theta_z > 86.0:
                theta_z = 86.0  # !Zenith angle must be < 90 (?? why 86?)
            if theta_z < 0:
                theta_z = 0  # Zenith angle must be >= 0
            Geff_total *= air_mass_modifier(theta_z, input.Elev, amavec)
        else:  # Even though we're using POA ref. data, we may still need to use the decomposed poa
            if input.usePOAFromWF:
                G_total = Geff_total = input.poaIrr
            else:
                G_total = input.poaIrr
                Geff_total = input.Ibeam + input.Idiff + input.Ignd + input.Irear
        var T_cell: Float64 = input.Tdry + 273.15
        if Geff_total >= 1.0:
            T_cell = TcellC + 273.15  # want cell temp in kelvin
            var IL_oper: Float64 = Geff_total / I_ref * (self.Il + muIsc * (T_cell - Tc_ref))
            if IL_oper < 0.0:
                IL_oper = 0.0
            var EG: Float64 = eg0 * (1 - 0.0002677 * (T_cell - Tc_ref))
            var IO_oper: Float64 = self.Io * pow(T_cell / Tc_ref, 3) * exp(1 / KB * (eg0 / Tc_ref - EG / T_cell))
            var A_oper: Float64 = self.a * T_cell / Tc_ref
            var Rsh_oper: Float64 = self.Rsh * (I_ref / Geff_total)
            var V_oc: Float64 = openvoltage_5par(self.Voc, A_oper, IL_oper, IO_oper, Rsh_oper)
            var I_sc: Float64 = IL_oper / (1 + self.Rs / Rsh_oper)
            var P: Float64
            var V: Float64
            var I: Float64
            if opvoltage < 0:
                P = maxpower_5par(V_oc, A_oper, IL_oper, IO_oper, self.Rs, Rsh_oper, V, I)
            else:
                V = opvoltage
                if V >= V_oc:
                    I = 0
                else:
                    I = current_5par(V, 0.9 * IL_oper, A_oper, IL_oper, IO_oper, self.Rs, Rsh_oper)
                P = V * I
            out.Power = P
            out.Voltage = V
            out.Current = I
            out.Efficiency = P / (self.Area * G_total)
            out.Voc_oper = V_oc
            out.Isc_oper = I_sc
            out.CellTemp = T_cell - 273.15
        return out.Power >= 0

@value
struct noct_celltemp_t:
    var standoff_tnoct_adj: Float64
    var ffv_wind: Float64
    var Tnoct: Float64

    def __call__(self, input: pvinput_t, module: pvmodule_t, opvoltage: Float64, Tcell: Float64) -> Bool:
        var G_total: Float64
        var Geff_total: Float64
        var tau_al: Float64 = abs(TauAlpha)
        var theta_z: Float64 = input.Zenith
        if theta_z > 86.0:
            theta_z = 86.0  # !Zenith angle must be < 90 (?? why 86?)
        if theta_z < 0:
            theta_z = 0  # Zenith angle must be >= 0
        var W_spd: Float64 = input.Wspd
        if W_spd < 0.001:
            W_spd = 0.001
        if input.radmode != 3:  # Determine if the model needs to skip the cover effects (will only be skipped if the user is using POA reference cell data)
            G_total = input.Ibeam + input.Idiff + input.Ignd  # total incident irradiance on tilted surface, W/m2
            Geff_total = G_total
            Geff_total = calculateIrradianceThroughCoverDeSoto(
                input.IncAng,
                input.Zenith,
                input.Tilt,
                input.Ibeam,
                input.Idiff,
                input.Ignd,
                False
            )
            if G_total > 0:
                tau_al *= Geff_total / G_total
            Geff_total *= air_mass_modifier(theta_z, input.Elev, amavec)
        else:
            if input.usePOAFromWF:
                G_total = Geff_total = input.poaIrr
            else:
                G_total = Geff_total = input.Ibeam + input.Idiff + input.Ignd
        if Geff_total > 0:
            var Imp: Float64 = module.ImpRef()
            var Vmp: Float64 = module.VmpRef()
            var Area: Float64 = module.AreaRef()
            var eff_ref: Float64 = Imp * Vmp / (I_ref * Area)
            tau_al = abs(TauAlpha)  # Sev: What's the point of recalculating this??
            W_spd = input.Wspd * self.ffv_wind  # added 1/11/12 to account for FFV_wind correction factor internally
            if W_spd < 0.001:
                W_spd = 0.001
            if G_total > 0:
                tau_al *= Geff_total / G_total
            var Tnoct_adj: Float64 = self.Tnoct + self.standoff_tnoct_adj  # added 1/11/12 for adjustment to NOCT as in the CECPV calculator based on standoff height, used in eqn below.
            Tcell = (input.Tdry + 273.15) + (G_total / I_noct * (Tnoct_adj - Tamb_noct) * (1.0 - eff_ref / tau_al)) * 9.5 / (5.7 + 3.8 * W_spd)
            Tcell = Tcell - 273.15
        return True

def free_convection_194(
    TC: Float64,
    TA: Float64,
    SLOPE: Float64,
    rho_air: Float64,
    Area: Float64,
    Length: Float64,
    Width: Float64
) -> Float64:
    var L_ch_f: Float64
    var nu: Float64
    var Beta: Float64
    var g_spec: Float64
    var Gr: Float64
    var Ra: Float64
    var C_lam: Float64
    var Nu_lam: Float64
    var C_turb: Float64
    var Nu_turb: Float64
    var Nu_bar: Float64
    var h_up: Float64
    var h_vert: Float64
    var h_down: Float64
    var grav: Float64 = 9.81
    L_ch_f = Area / (2.0 * (Length + Width))  # !Eq. 6-54 (Nellis&Klein)
    if TA > TC:
        SLOPE = 180.0 - SLOPE
    nu = mu_air / rho_air  # !Kinematic Viscosity
    Beta = 1.0 / ((TA + TC) / 2.0)  # !volumetric coefficient of thermal expansion
    g_spec = grav * MAX(0.0, cosd(SLOPE))  # !Adjustment of gravity vector;
    Gr = g_spec * Beta * abs(TC - TA) * pow(L_ch_f, 3) / pow(nu, 2)  # !Grashof Number
    Ra = MAX(0.0001, Gr * Pr_air)  # !Rayleigh Number
    C_lam = 0.671 / pow(1.0 + pow(0.492 / Pr_air, 9.0 / 16.0), 4.0 / 9.0)  # !Eq. 6-49 (Nellis&Klein)
    Nu_lam = 1.4 / log(1.0 + (1.4 / (0.835 * C_lam * pow(Ra, 0.25))))  # !Eq. 6-56 (Nellis&Klein)
    C_turb = 0.14 * ((1.0 + 0.0107 * Pr_air) / (1.0 + 0.01 * Pr_air))  # !Eq. 6-58 (Nellis&Klein)
    Nu_turb = C_turb * pow(Ra, 1.0 / 3.0)  # !Eq. 6-57  (Nellis&Klein)
    Nu_bar = pow(pow(Nu_lam, 10) + pow(Nu_turb, 10.0), 1.0 / 10.0)  # !Eq. 6-55  (Nellis&Klein)
    h_up = Nu_bar * k_air / L_ch_f
    g_spec = grav * sind(SLOPE)  # !Adjustment of gravity vector
    Gr = g_spec * Beta * abs(TC - TA) * pow(Length, 3) / pow(nu, 2)
    Ra = MAX(0.0001, Gr * Pr_air)
    Nu_bar = pow(
        0.825 + (0.387 * pow(Ra, 1.0 / 6.0)) / pow(1 + pow(0.492 / Pr_air, 9.0 / 16.0), 8.0 / 27.0),
        2
    )  # !(Incropera et al.,2006)
    h_vert = Nu_bar * k_air / Length
    g_spec = grav * MAX(0.0, -cosd(SLOPE))
    Gr = g_spec * Beta * abs(TC - TA) * pow(L_ch_f, 3) / pow(nu, 2)
    Ra = MAX(0.0001, Gr * Pr_air)
    Nu_bar = 2.5 / log(
        1.0 + (2.5 / (0.527 * pow(Ra, 0.2))) * pow(1.0 + pow(1.9 / Pr_air, 0.9), 2.0 / 9.0)
    )  # !Eq. 6-59  (Nellis&Klein)
    h_down = Nu_bar * k_air / L_ch_f
    return MAX(MAX(h_down, h_vert), h_up)  # !Fig. 6-12  (Nellis&Klein)

def ffd_194(D_h: Float64, Re_dh: Float64) -> Float64:
    var e: Float64 = 0.005
    return pow(
        -2.0 * log10(MAX(1e-6, ((2.0 * e / (7.54 * D_h) - 5.02 / Re_dh * log10(2.0 * e / (7.54 * D_h) + 13.0 / Re_dh))))),
        -2.0
    )

def channel_free_194(
    W_gap: Float64,
    SLOPE: Float64,
    TA: Float64,
    T_cr: Float64,
    rho_air: Float64,
    Length: Float64
) -> Float64:
    var g_spec: Float64
    var Beta: Float64
    var alpha: Float64
    var nu_air: Float64
    var Ra: Float64
    var Nu: Float64
    var grav: Float64 = 9.81
    nu_air = mu_air / rho_air  # !Kinematic Viscosity
    g_spec = MAX(0.1, sind(SLOPE) * grav)
    Beta = 1.0 / ((T_cr + TA) / 2.0)
    alpha = k_air / (rho_air * cp_air)
    Ra = MAX(0.001, g_spec * pow(W_gap, 3) * Beta * (T_cr - TA) / (nu_air * alpha))
    Nu = Ra / 24.0 * W_gap / Length * pow(1.0 - exp(-35.0 / Ra * Length / W_gap), 0.75)
    return Nu * k_air / W_gap

@value
struct mcsp_celltemp_t:
    var DcDerate: Float64  # DC derate factor (0..1)
    var MC: Int  # Mounting configuration (1=rack,2=flush,3=integrated,4=gap)
    var HTD: Int  # Heat transfer dimension (1=Module,2=Array)
    var MSO: Int  # Mounting structure orientation (1=does not impede flow beneath, 2=vertical supports, 3=horizontal supports)
    var Nrows: Int
    var Ncols: Int  # number of modules in rows and columns, when using array heat transfer dimensions
    var Length: Float64  # module length, along horizontal dimension, (m)
    var Width: Float64  # module width, along vertical dimension, (m)
    var Wgap: Float64  # gap width spacing (m)
    var TbackInteg: Float64  # back surface temperature for integrated modules ('C)
    var m_err: String

    def __init__(inout self):
        # fields must be initialized; use default values
        self.DcDerate = 1.0
        self.MC = 1
        self.HTD = 1
        self.MSO = 1
        self.Nrows = 1
        self.Ncols = 1
        self.Length = 1.0
        self.Width = 1.0
        self.Wgap = 0.0
        self.TbackInteg = 0.0
        self.m_err = ""

    def error(self) -> String:
        return self.m_err

    def __call__(self, input: pvinput_t, module: pvmodule_t, opvoltage: Float64, Tcell: Float64) -> Bool:
        if input.Ibeam + input.Idiff + input.Ignd < 1:
            Tcell = input.Tdry
            return True
        var THETAZ: Float64 = input.Zenith
        if THETAZ > 86.0:
            THETAZ = 86.0  # !Zenith angle must be < 90 degrees
        var THETA: Float64 = input.IncAng
        if THETA < 0:
            THETA = 1
        var n2: Float64 = 1.526  # !refractive index of glass
        var RefrAng1: Float64 = asind(sind(THETA) / n2)
        var TransSurf1: Float64 = 1 - 0.5 * (
            pow(sind(RefrAng1 - THETA), 2) / pow(sind(RefrAng1 + THETA), 2)
            + pow(tand(RefrAng1 - THETA), 2) / pow(tand(RefrAng1 + THETA), 2)
        )
        var TransCoverAbs1: Float64 = exp(-k_glass * l_glass / cosd(RefrAng1))
        var tau1: Float64 = TransCoverAbs1 * TransSurf1
        var THETA2: Float64 = 1
        var RefrAng2: Float64 = asind(sind(THETA2) / n2)
        var TransSurf2: Float64 = 1 - 0.5 * (
            pow(sind(RefrAng2 - 1), 2) / pow(sind(RefrAng2 + 1), 2)
            + pow(tand(RefrAng2 - 1), 2) / pow(tand(RefrAng2 + 1), 2)
        )
        var TransCoverAbs2: Float64 = exp(-k_glass * l_glass / cosd(RefrAng2))
        var tau2: Float64 = TransCoverAbs2 * TransSurf2
        var THETA3: Float64 = 59.7 - 0.1388 * input.Tilt + 0.001497 * pow(input.Tilt, 2)
        var RefrAng3: Float64 = asind(sind(THETA3) / n2)
        var TransSurf3: Float64 = 1 - 0.5 * (
            pow(sind(RefrAng3 - THETA3), 2) / pow(sind(RefrAng3 + THETA3), 2)
            + pow(tand(RefrAng3 - THETA3), 2) / pow(tand(RefrAng3 + THETA3), 2)
        )
        var TransCoverAbs3: Float64 = exp(-k_glass * l_glass / cosd(RefrAng3))
        var TransCoverDiff: Float64 = TransCoverAbs3
        var tau3: Float64 = TransCoverAbs3 * TransSurf3
        var TADIR: Float64 = tau1 / tau2
        var TADIFF: Float64 = tau3 / tau2
        THETA3 = 90.0 - 0.5788 * input.Tilt + 0.002693 * pow(input.Tilt, 2)
        RefrAng3 = asind(sind(THETA3) / n2)
        TransSurf3 = 1 - 0.5 * (
            pow(sind(RefrAng3 - THETA3), 2) / pow(sind(RefrAng3 + THETA3), 2)
            + pow(tand(RefrAng3 - THETA3), 2) / pow(tand(RefrAng3 + THETA3), 2)
        )
        TransCoverAbs3 = exp(-k_glass * l_glass / cosd(RefrAng3))
        tau3 = TransCoverAbs3 * TransSurf3
        var TAGND: Float64 = tau3 / tau2
        var QDIFF: Float64 = input.Idiff * (1.0 - TransCoverDiff)
        var QGND: Float64 = input.Ignd * (1.0 - TransCoverAbs3)
        var QDIR: Float64 = input.Ibeam * (1.0 - TransCoverAbs1)
        var QHDKR: Float64 = QDIFF + QGND + QDIR
        var SHDKR: Float64 = (
            input.Idiff * TADIFF * tau2
            + input.Ignd * TAGND * tau2
            + input.Ibeam * TADIR * tau2
            + QHDKR
        )
        var SUNDIFF: Float64 = input.Idiff * TADIFF
        var SUNGND: Float64 = input.Ignd * TAGND
        var SUNDIR: Float64 = input.Ibeam * TADIR
        var SUNEFF: Float64 = SUNDIFF + SUNGND + SUNDIR
        if SUNEFF < 0:
            SUNEFF = 0
        if THETAZ < 0:
            THETAZ = 0
        var MAM: Float64 = air_mass_modifier(THETAZ, input.Elev, amavec)
        SUNEFF = SUNEFF * MAM
        if SUNEFF < 1:
            Tcell = input.Tdry
            return True
        if self.HTD == 1:
            # Nrows, Ncols unchanged

        elif self.HTD == 2:
            self.Length = self.Nrows * self.Length
            self.Width = self.Ncols * self.Width
        var Imp: Float64 = module.ImpRef()
        var Vmp: Float64 = module.VmpRef()
        var Area_base: Float64 = module.AreaRef()  # !Use provided area for Duffie and Beckman model to maintain consistency w/ previous model
        var Area: Float64 = Area_base * self.Length * self.Width  # !Surface area of module
        var L_char: Float64 = 4.0 * self.Length * self.Width / (2.0 * (self.Width + self.Length))
        if self.Wgap < 0.001 and self.MC == 4:
            self.MC = 2
        var R_gap: Float64 = self.Wgap / self.Length
        if self.MC == 4 and R_gap > 1 and self.MSO == 1:
            self.MC = 1
        var v_ch: Float64 = 1.0
        var Fcg: Float64
        var Fcs: Float64
        var Fbs: Float64
        var Fbg: Float64
        var T_sky: Float64
        var T_ground: Float64
        var T_rw: Float64
        var V_WIND: Float64 = MAX(0.001, input.Wspd)
        var V_cover: Float64 = V_WIND
        var P_guess: Float64 = 0
        var TA: Float64 = input.Tdry + 273.15
        var Patm: Float64 = input.Patm * 100  # convert millibar into Pascal
        var EFFREF: Float64 = 1e-3
        if self.MC == 5:
            EFFREF = Imp * Vmp / (I_ref * Area_base)  # !Efficiency of module at SRC conditions
        else:
            EFFREF = Imp * Vmp / (I_ref * Area)  # !Efficiency of module at SRC conditions
        P_guess = EFFREF * (SUNEFF * Area)  # !Estimate performance based on SRC efficiency
        if self.HTD == 2:
            P_guess = P_guess * self.Nrows * self.Ncols
        if self.MC == 4:
            if self.MSO == 2:
                V_WIND = MAX(0.001, abs(cosd(input.Wdir - input.Azimuth)) * V_WIND)
            if self.MSO == 3:
                V_WIND = MAX(0.001, abs(cosd(input.Wdir + 90.0 - input.Azimuth)) * V_WIND)
            v_ch = V_WIND * 0.3  # !Give realistic starting value to channel air velocity
        Fcg = (1.0 - cosd(input.Tilt)) / 2  # !view factor between top of tilted plate and horizontal plane adjacent to bottom edge of plate
        Fcs = 1.0 - Fcg  # !view factor between top of tilted plate and everything else (sky)
        Fbs = Fcg  # !view factor bewteen top and ground = bottom and sky
        Fbg = Fcs  # !view factor bewteen bottom and ground = top and sky
        T_sky = TA * pow(
            0.711 + 0.0056 * input.Tdew + 0.000073 * pow(input.Tdew, 2) + 0.013 * cosd(input.HourOfDay),
            0.25
        )  # !Sky Temperature: Berdahl and Martin
        T_ground = TA  # !Set ground temp equal to ambient temp
        T_rw = TA  # !Initial guess for roof or wall temp
        var err_P: Float64 = 100.0  # !Set initial performance error. Must be > tolerance for power error in do loop
        var err_P1: Float64 = 100.0  # !Set initial performance error for updated power guess
        var err_P2: Float64 = 0.0  # !Set initial previous error.  Should be zero so approach factor doesn't reset after 1 iteration
        var p_iter: Int = 0  # !Set iteration counter (performance)
        var app_fac_P: Float64 = 1.0
        var TC: Float64 = input.Tdry + 273.15
        while p_iter <= 300 and abs(err_P) > 0.1:
            var err_TC: Float64 = 100.0  # !Set initial temperature error. Must be > tolerance for temp error in do loop
            var err_TC_p: Float64 = 0.0  # !Set initial previous error. Should be zero so approach factor doesn't reset after 1 iteration
            var h_iter: Int = 0  # !Set iteration counter (temperature)
            var app_fac: Float64 = 0.5  # !Set approach factor for updating cell temp guess value
            var app_fac_v: Float64 = 0.5  # !Set approach factor for updating channel velocity guess value
            if self.MC == 1:
                # !Rack Mounting Configuration
                while abs(err_TC) > 0.001:
                    var rho_air: Float64 = Patm * 28.967 / 8314.34 * (1.0 / ((TA + TC) / 2.0))
                    var Re_forced: Float64 = MAX(0.1, rho_air * V_cover * L_char / mu_air)
                    var Nu_forced: Float64 = 0.037 * pow(Re_forced, 4.0 / 5.0) * pow(Pr_air, 1.0 / 3.0)
                    var h_forced: Float64 = Nu_forced * k_air / L_char
                    var h_sky: Float64 = (TC * TC + T_sky * T_sky) * (TC + T_sky)
                    var h_ground: Float64 = (TC * TC + T_ground * T_ground) * (TC + T_ground)
                    var h_free_c: Float64 = free_convection_194(TC, TA, input.Tilt, rho_air, Area, self.Length, self.Width)
                    var h_free_b: Float64 = free_convection_194(TC, TA, 180.0 - input.Tilt, rho_air, Area, self.Length, self.Width)
                    var h_conv_c: Float64 = pow(pow(h_forced, 3.0) + pow(h_free_c, 3.0), 1.0 / 3.0)
                    var h_conv_b: Float64 = pow(pow(h_forced, 3.0) + pow(h_free_b, 3.0), 1.0 / 3.0)
                    var TC1: Float64 = (
                        (h_conv_c + h_conv_b) * TA
                        + (Fcs * EmisC + Fbs * EmisB) * sigma * h_sky * T_sky
                        + (Fcg * EmisC + Fbg * EmisB) * sigma * h_ground * T_ground
                        - (P_guess / Area) + SHDKR
                    ) / (
                        h_conv_c
                        + h_conv_b
                        + (Fcs * EmisC + Fbs * EmisB) * sigma * h_sky
                        + (Fcg * EmisC + Fbg * EmisB) * sigma * h_ground
                    )
                    err_TC = TC1 - TC
                    TC = TC1
                    h_iter += 1
                    if h_iter > 150:
                        return False
                # end while
            elif self.MC == 2:
                # !Flush Mounting Configuration
                while abs(err_TC) > 0.001:
                    var rho_air: Float64 = Patm * 28.967 / 8314.34 * (1.0 / ((TA + TC) / 2.0))
                    var Re_forced: Float64 = MAX(0.1, rho_air * V_cover * L_char / mu_air)
                    var Nu_forced: Float64 = 0.037 * pow(Re_forced, 4.0 / 5.0) * pow(Pr_air, 1.0 / 3.0)
                    var h_forced: Float64 = Nu_forced * k_air / L_char
                    var h_sky: Float64 = (TC * TC + T_sky * T_sky) * (TC + T_sky)
                    var h_ground: Float64 = (TC * TC + T_ground * T_ground) * (TC + T_ground)
                    var h_free_c: Float64 = free_convection_194(TC, TA, input.Tilt, rho_air, Area, self.Length, self.Width)
                    var h_conv_c: Float64 = pow(pow(h_forced, 3.0) + pow(h_free_c, 3.0), 1.0 / 3.0)
                    var TC1: Float64 = (
                        (h_conv_c) * TA
                        + (Fcs * EmisC) * sigma * h_sky * T_sky
                        + (Fcg * EmisC) * sigma * h_ground * T_ground
                        - (P_guess / Area) + SHDKR
                    ) / (
                        h_conv_c + (Fcs * EmisC) * sigma * h_sky + (Fcg * EmisC) * sigma * h_ground
                    )
                    err_TC = TC1 - TC
                    TC = TC1
                    h_iter += 1
                    if h_iter > 150:
                        return False
                # end while
            elif self.MC == 3:
                # !Integrated Mounting Configuration
                while abs(err_TC) > 0.001:
                    var TbackK: Float64 = self.TbackInteg + 273.15
                    var rho_air: Float64 = Patm * 28.967 / 8314.34 * (1.0 / ((TA + TC) / 2.0))
                    var rho_bk: Float64 = Patm * 28.967 / 8314.34 * (1.0 / ((TbackK + TC) / 2.0))
                    var Re_forced: Float64 = MAX(0.1, rho_air * V_cover * L_char / mu_air)
                    var Nu_forced: Float64 = 0.037 * pow(Re_forced, 4.0 / 5.0) * pow(Pr_air, 1.0 / 3.0)
                    var h_forced: Float64 = Nu_forced * k_air / L_char
                    var h_sky: Float64 = (TC * TC + T_sky * T_sky) * (TC + T_sky)
                    var h_ground: Float64 = (TC * TC + T_ground * T_ground) * (TC + T_ground)
                    var h_radbk: Float64 = (TC * TC + TbackK * TbackK) * (TC + TbackK)
                    var h_free_c: Float64 = free_convection_194(TC, TA, input.Tilt, rho_air, Area, self.Length, self.Width)
                    var h_free_b: Float64 = free_convection_194(TC, TbackK, 180.0 - input.Tilt, rho_bk, Area, self.Length, self.Width)
                    var h_conv_c: Float64 = pow(pow(h_forced, 3.0) + pow(h_free_c, 3.0), 1.0 / 3.0)
                    var h_conv_b: Float64 = h_free_b  # !No forced convection on backside
                    var TC1: Float64 = (
                        h_conv_c * TA
                        + h_conv_b * TbackK
                        + Fcs * EmisC * sigma * h_sky * T_sky
                        + Fcg * EmisC * sigma * h_ground * T_ground
                        + EmisB * sigma * h_radbk * TbackK
                        - (P_guess / Area) + SHDKR
                    ) / (
                        h_conv_c
                        + h_conv_b
                        + Fcs * EmisC * sigma * h_sky
                        + Fcg * EmisC * sigma * h_ground
                        + EmisB * sigma * h_radbk
                    )
                    err_TC = TC1 - TC
                    TC = TC1
                    h_iter += 1
                    if h_iter > 150:
                        return False
                # end while
            elif self.MC == 4:
                # !Gap (channel) Mounting Configuration
                var A_c: Float64
                var L_charB: Float64
                var L_str: Float64
                var Per_cw: Float64
                var D_h: Float64
                if self.MSO == 1:
                    L_charB = MIN(self.Width, self.Length)
                    L_str = MAX(self.Width, self.Length)
                    A_c = self.Wgap * L_str
                    Per_cw = 2.0 * L_str
                    D_h = (4.0 * A_c) / Per_cw
                elif self.MSO == 2:
                    L_charB = self.Length
                    L_str = self.Width / self.Ncols
                    A_c = self.Wgap * L_str
                    Per_cw = 2.0 * L_str + 2.0 * self.Wgap
                    D_h = (4.0 * A_c) / Per_cw
                elif self.MSO == 3:
                    L_charB = self.Width
                    L_str = self.Length / self.Nrows
                    A_c = self.Wgap * L_str
                    Per_cw = 2.0 * L_str + 2.0 * self.Wgap
                    D_h = (4.0 * A_c) / Per_cw
                else:
                    return False  # invalid parameter specified
                while abs(err_TC) > 0.001:
                    var rho_air: Float64 = Patm * 28.967 / 8314.34 * (1.0 / ((TA + TC) / 2.0))
                    var err_v: Float64 = 100.0
                    var err_v_p: Float64 = 100.0
                    var P_in: Float64 = 0.5 * V_WIND * V_WIND * rho_air
                    var v_iter: Int = 0
                    while v_iter < 80 and abs(err_v) > 0.001:
                        var Re_dh_ch: Float64 = rho_air * v_ch * (D_h / mu_air)
                        var f_fd: Float64 = ffd_194(D_h, Re_dh_ch)
                        var tau_s: Float64 = f_fd * rho_air * pow(v_ch, 2 / 8.0)
                        var P_out: Float64 = P_in - tau_s * Per_cw * L_charB / A_c
                        var v_ch1: Float64 = sqrt(MAX(0.0005, (2.0 * P_out / rho_air)))
                        err_v = v_ch1 - v_ch
                        var err_v_sign: Float64 = err_v * err_v_p
                        err_v_p = err_v
                        if err_v_sign < 0.0:
                            app_fac_v = app_fac_v * 0.5
                        v_ch = v_ch + app_fac_v * err_v
                        v_iter += 1
                    # end while
                    var Re_forced: Float64 = MAX(0.1, rho_air * V_cover * L_char / mu_air)
                    var Nu_forced: Float64 = 0.037 * pow(Re_forced, 4.0 / 5.0) * pow(Pr_air, 1.0 / 3.0)
                    var h_forced: Float64 = Nu_forced * k_air / L_char
                    var h_sky: Float64 = (TC * TC + T_sky * T_sky) * (TC + T_sky)
                    var h_ground: Float64 = (TC * TC + T_ground * T_ground) * (TC + T_ground)
                    var h_free_c: Float64 = free_convection_194(TC, TA, input.Tilt, rho_air, Area, self.Length, self.Width)
                    var h_conv_c: Float64 = pow(pow(h_forced, 3.0) + pow(h_free_c, 3.0), 1.0 / 3.0)
                    var Re_fp: Float64 = rho_air * v_ch * L_charB / mu_air
                    var Nus_ch: Float64 = 0.037 * pow(Re_fp, 4.0 / 5.0) * pow(Pr_air, 1.0 / 3.0)
                    var h_ch: Float64 = Nus_ch * k_air / L_charB
                    h_ch = MIN(h_ch, h_forced)
                    var iter_T_rw: Int = 0
                    var err_T_rw: Float64 = 2.0
                    var h_radbk: Float64 = 0.0
                    var Q_conv_c: Float64 = 0.0
                    var Q_conv_r: Float64 = 0.0
                    while iter_T_rw < 121 and abs(err_T_rw) > 0.001:
                        var T_cr: Float64 = (TC + T_rw) / 2.0
                        var h_fr: Float64 = 0.0
                        if self.MSO == 3:
                            h_fr = 0.0
                        else:
                            h_fr = channel_free_194(self.Wgap, input.Tilt, TA, T_cr, rho_air, self.Length)
                        var m_dot: Float64 = v_ch * rho_air * A_c
                        var h_conv_b: Float64 = pow(pow(h_ch, 3) + pow(h_fr, 3), 1.0 / 3.0)
                        var AR: Int = 0
                        if self.MSO == 1:
                            AR = 1
                        if self.MSO == 2:
                            AR = self.Ncols
                        if self.MSO == 3:
                            AR = self.Nrows
                        var T_m: Float64 = T_cr - (T_cr - TA) * exp(-2 * (Area / AR) * h_conv_b / (m_dot * cp_air))
                        var Q_air: Float64 = MAX(0.0001, cp_air * m_dot * (T_m - TA)) * AR
                        var DELTAT_r: Float64 = T_rw - TA
                        var DELTAT_c: Float64 = TC - TA
                        var R_r: Float64 = MIN(1.0, DELTAT_r / MAX(0.1, (DELTAT_r + DELTAT_c)))
                        var R_c: Float64 = MIN(1.0, DELTAT_c / MAX(0.1, (DELTAT_r + DELTAT_c)))
                        Q_conv_c = R_c * Q_air / Area
                        Q_conv_r = R_r * Q_air / Area
                        h_radbk = (TC * TC + T_rw * T_rw) * (TC + T_rw)
                        var T_rw1: Float64 = MAX(TA, TC - Q_conv_r / (EmisB * sigma * h_radbk))
                        err_T_rw = T_rw1 - T_rw
                        T_rw = T_rw + (0.5 - 0.495 * (iter_T_rw / 60)) * err_T_rw
                        iter_T_rw += 1
                    # end while
                    var TC1: Float64 = (
                        h_conv_c * TA
                        + Fcs * EmisC * sigma * h_sky * T_sky
                        + Fcg * EmisC * sigma * h_ground * T_ground
                        + sigma * EmisB * h_radbk * T_rw
                        - Q_conv_c
                        - (P_guess / Area)
                        + SHDKR
                    ) / (
                        h_conv_c
                        + Fcs * EmisC * sigma * h_sky
                        + Fcg * EmisC * sigma * h_ground
                        + sigma * EmisB * h_radbk
                    )
                    err_TC = TC1 - TC
                    var err_sign: Float64 = err_TC * err_TC_p
                    err_TC_p = err_TC
                    if err_sign < 0.0:
                        app_fac = app_fac * 0.9
                    TC = TC + app_fac * err_TC
                    h_iter += 1
                    if h_iter > 150:
                        return False
                # end while
            else:
                # unknown MC

            var out: pvoutput_t = pvoutput_t()
            if not module(input, TC - 273.15, opvoltage, out):
                self.m_err = module.error()
                return False
            var PMAX_1: Float64 = out.Power * self.DcDerate
            if self.HTD == 2:
                PMAX_1 = PMAX_1 * self.Nrows * self.Ncols
            err_P1 = PMAX_1 - P_guess
            var err_sign_P: Float64 = err_P1 * err_P2
            err_P2 = err_P1
            if p_iter > 5 and err_sign_P < 0.0:
                app_fac_P = 0.75 * app_fac_P
            err_P = (PMAX_1 - P_guess) / (self.Nrows * self.Ncols)
            P_guess = P_guess + app_fac_P * err_P1
            p_iter += 1
            if p_iter > 300 and abs(err_P) > 0.1:
                self.m_err = "Power Calculations Did Not Converge"
                return False
        # end while
        Tcell = TC - 273.15
        return True