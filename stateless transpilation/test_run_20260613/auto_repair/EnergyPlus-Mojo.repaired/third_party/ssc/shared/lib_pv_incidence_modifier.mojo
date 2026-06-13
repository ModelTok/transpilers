from math import sin, cos, tan, asin, exp, pow, pi

alias AOI_MIN: Float64 = 0.5
alias AOI_MAX: Float64 = 89.5
alias n_glass: Float64 = 1.526
alias l_glass: Float64 = 0.002
alias k_glass: Float64 = 4
alias n_arc: Float64 = 1.3
alias l_arc: Float64 = l_glass * 0.01
alias k_arc: Float64 = 4
alias n_air: Float64 = 1.0

def transmittance(
    theta1_deg: Float64,
    n_cover: Float64,
    n_incoming: Float64,
    k: Float64,
    l_thick: Float64,
    _theta2_deg: Pointer[Float64] = Pointer[Float64]()
) -> Float64:
    var theta1: Float64 = theta1_deg * pi / 180.0
    var theta2: Float64 = asin(n_incoming / n_cover * sin(theta1))
    var tr: Float64 = 1 - 0.5 * (
        pow(sin(theta2 - theta1), 2) / pow(sin(theta2 + theta1), 2)
        + pow(tan(theta2 - theta1), 2) / pow(tan(theta2 + theta1), 2)
    )
    if _theta2_deg:
        _theta2_deg[0] = theta2 * 180 / pi
    return tr * exp(-k * l_thick / cos(theta2))

def iam_nonorm(theta: Float64, ar_glass: Bool) -> Float64:
    var theta_local = theta
    if theta_local < AOI_MIN:
        theta_local = AOI_MIN
    if theta_local > AOI_MAX:
        theta_local = AOI_MAX
    if ar_glass:
        var theta2: Float64 = 1
        var tau_coating: Float64 = transmittance(theta_local, n_arc, n_air, k_arc, l_arc, Pointer[Float64].address_of(theta2))
        var tau_glass: Float64 = transmittance(theta2, n_glass, n_arc, k_glass, l_glass)
        return tau_coating * tau_glass
    else:
        return transmittance(theta_local, n_glass, n_air, k_glass, l_glass)

def iam(theta: Float64, ar_glass: Bool) -> Float64:
    var theta_local = theta
    if theta_local < AOI_MIN:
        theta_local = AOI_MIN
    if theta_local > AOI_MAX:
        theta_local = AOI_MAX
    var normal: Float64 = iam_nonorm(1, ar_glass)
    var actual: Float64 = iam_nonorm(theta_local, ar_glass)
    return actual / normal

def iamSjerpsKoomen(n2: Float64, incidenceAngleRadians: Float64) -> Float64:
    var cor: Float64 = -9999.0
    var r0: Float64 = pow((n2 - 1.0) / (n2 + 1), 2)
    if incidenceAngleRadians == 0:
        cor = 1.0
    elif incidenceAngleRadians > 0.0 and incidenceAngleRadians <= pi / 2.0:
        var refrAng: Float64 = asin(sin(incidenceAngleRadians) / n2)
        var r1: Float64 = (pow(sin(refrAng - incidenceAngleRadians), 2.0) / pow(sin(refrAng + incidenceAngleRadians), 2.0))
        var r2: Float64 = (pow(tan(refrAng - incidenceAngleRadians), 2.0) / pow(tan(refrAng + incidenceAngleRadians), 2.0))
        cor = 1.0 - 0.5 * (r1 + r2)
        cor /= 1.0 - r0
    return cor

def calculateIrradianceThroughCoverDeSoto(
    theta: Float64,
    theta_z: Float64,
    tilt: Float64,
    G_beam: Float64,
    G_sky: Float64,
    G_gnd: Float64,
    antiReflectiveGlass: Bool
) -> Float64:
    var theta_local = theta
    var theta_z_local = theta_z
    if theta_local < 1:
        theta_local = 1
    if theta_local > 89:
        theta_local = 89
    if theta_z_local > 86.0:
        theta_z_local = 86.0
    if theta_z_local < 0:
        theta_z_local = 0
    var tau_norm: Float64 = transmittance(1.0, n_glass, 1.0, k_glass, l_glass)
    var theta_after_coating: Float64 = theta_local
    var tau_beam: Float64 = 1.0
    if antiReflectiveGlass:
        var tau_coating: Float64 = transmittance(theta_local, n_arc, 1.0, k_arc, l_arc, Pointer[Float64].address_of(theta_after_coating))
        tau_beam *= tau_coating
    tau_beam *= transmittance(theta_after_coating, n_glass, (n_arc if antiReflectiveGlass else 1.0), k_glass, l_glass)
    var theta_sky: Float64 = 59.7 - 0.1388 * tilt + 0.001497 * tilt * tilt
    var tau_sky: Float64 = transmittance(theta_sky, n_glass, 1.0, k_glass, l_glass)
    var theta_gnd: Float64 = 90.0 - 0.5788 * tilt + 0.002693 * tilt * tilt
    var tau_gnd: Float64 = transmittance(theta_gnd, n_glass, 1.0, k_glass, l_glass)
    var Kta_beam: Float64 = tau_beam / tau_norm
    var Kta_sky: Float64 = tau_sky / tau_norm
    var Kta_gnd: Float64 = tau_gnd / tau_norm
    var Geff_total: Float64 = G_beam * Kta_beam + G_sky * Kta_sky + G_gnd * Kta_gnd
    if Geff_total < 0:
        Geff_total = 0
    return Geff_total