# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): EnergyPlus/EnergyPlus.hh
# - Files (from TARCOGOutput): EnergyPlus/TARCOGOutput.hh
# - DeflectionCalculation, TARCOGLayerType, TARCOGThermalModel: EnergyPlus/TARCOGParams.hh
# - Stdrd: EnergyPlus/TARCOGGassesParams.hh
# - Constants (maxlay, MaxGap, maxgas, maxlay1, maxlay2, MinStandard, MaxStandard): EnergyPlus/TARCOGGassesParams.hh, TARCOGParams.hh
# - C4_VENET_HORIZONTAL, C4_VENET_VERTICAL: TARCOGCommon.hh or TARCOGParams.hh
# - WriteInputArguments, WriteTARCOGInputFile, IsShadingLayer: EnergyPlus/TARCOGOutput.hh, TARCOGCommon.hh

from math import pi, cos, sin, pow, fabs
from utils import Span


# ==================== ENUMS ====================
@value
struct DeflectionCalculation:
    alias NONE = 0


@value
struct TARCOGLayerType:
    alias SPECULAR = 0
    alias VENETBLIND_HORIZ = 1
    alias WOVSHADE = 2
    alias PERFORATED = 3
    alias DIFFSHADE = 4
    alias BSDF = 5
    alias VENETBLIND_VERT = 6


@value
struct TARCOGThermalModel:
    alias ISO15099 = 0
    alias SCW = 1
    alias CSM = 2


@value
struct Stdrd:
    pass


# ==================== CONSTANTS ====================
alias maxlay = 10
alias MaxGap = 10
alias maxgas = 12
alias maxlay1 = 11
alias maxlay2 = 20
alias MinStandard = 0
alias MaxStandard = 4
alias C4_VENET_HORIZONTAL = 0.0
alias C4_VENET_VERTICAL = 0.0
alias PI = pi
alias STEFAN_BOLTZMANN = 5.670374419e-8


# ==================== STRUCTS ====================
@value
struct EnergyPlusData:
    pass


@value
struct Files:
    var WriteDebugOutput: Bool
    var DebugOutputFile: object
    var DBGD: object


# ==================== MATH HELPERS ====================
@always_inline
fn pow_6(x: Float64) -> Float64:
    return x * x * x * x * x * x


@always_inline
fn pow_4(x: Float64) -> Float64:
    return x * x * x * x


@always_inline
fn root_4(x: Float64) -> Float64:
    return pow(x, 0.25)


# ==================== EXTERNAL FUNCTION STUBS ====================
fn write_input_arguments(
    state: EnergyPlusData,
    debug_output_file: object,
    dbgd: object,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int32,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int32,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    vacuum_pressure: Float64,
    vacuum_max_gap_thickness: Float64,
    ibc: Span[Int32],
    hout: Float64,
    hin: Float64,
    standard: Stdrd,
    thermal_mod: Int32,
    sd_scalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int32,
    layer_type: Span[Int32],
    thick: Span[Float64],
    scon: Span[Float64],
    asol: Span[Float64],
    tir: Span[Float64],
    emis: Span[Float64],
    atop: Span[Float64],
    abot: Span[Float64],
    al: Span[Float64],
    ar: Span[Float64],
    ah: Span[Float64],
    slat_thick: Span[Float64],
    slat_width: Span[Float64],
    slat_angle: Span[Float64],
    slat_cond: Span[Float64],
    slat_spacing: Span[Float64],
    slat_curve: Span[Float64],
    nslice: Span[Int32],
    laminate_a: Span[Float64],
    laminate_b: Span[Float64],
    sumsol: Span[Float64],
    gap: Span[Float64],
    vvent: Span[Float64],
    tvent: Span[Float64],
    presure: Span[Float64],
    nmix: Span[Int32],
    iprop: Span[Span[Int32]],
    frct: Span[Span[Float64]],
    xgcon: Span[Span[Float64]],
    xgvis: Span[Span[Float64]],
    xgcp: Span[Span[Float64]],
    xwght: Span[Float64]) -> None:
    pass


fn write_tarcog_input_file(
    state: EnergyPlusData,
    files: Files,
    version_number: StringRef,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    iwd: Int32,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int32,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    vacuum_pressure: Float64,
    vacuum_max_gap_thickness: Float64,
    calc_deflection: Int32,
    pa: Float64,
    pini: Float64,
    tini: Float64,
    ibc: Span[Int32],
    hout: Float64,
    hin: Float64,
    standard: Stdrd,
    thermal_mod: Int32,
    sd_scalar: Float64,
    height: Float64,
    heightt: Float64,
    width: Float64,
    tilt: Float64,
    totsol: Float64,
    nlayer: Int32,
    layer_type: Span[Int32],
    thick: Span[Float64],
    scon: Span[Float64],
    youngs_mod: Span[Float64],
    poissons_rat: Span[Float64],
    asol: Span[Float64],
    tir: Span[Float64],
    emis: Span[Float64],
    atop: Span[Float64],
    abot: Span[Float64],
    al: Span[Float64],
    ar: Span[Float64],
    ah: Span[Float64],
    support_pillar: Span[Int32],
    pillar_spacing: Span[Float64],
    pillar_radius: Span[Float64],
    slat_thick: Span[Float64],
    slat_width: Span[Float64],
    slat_angle: Span[Float64],
    slat_cond: Span[Float64],
    slat_spacing: Span[Float64],
    slat_curve: Span[Float64],
    nslice: Span[Int32],
    gap: Span[Float64],
    gap_def: Span[Float64],
    vvent: Span[Float64],
    tvent: Span[Float64],
    presure: Span[Float64],
    nmix: Span[Int32],
    iprop: Span[Span[Int32]],
    frct: Span[Span[Float64]],
    xgcon: Span[Span[Float64]],
    xgvis: Span[Span[Float64]],
    xgcp: Span[Span[Float64]],
    xwght: Span[Float64],
    gama: Span[Float64]) -> None:
    pass


@always_inline
fn is_shading_layer(layer_type: Int32) -> Bool:
    return layer_type != TARCOGLayerType.SPECULAR and layer_type != TARCOGLayerType.BSDF


# ==================== MAIN FUNCTIONS ====================
fn arg_check(
    state: EnergyPlusData,
    files: Files,
    nlayer: Int32,
    iwd: Int32,
    tout: Float64,
    tind: Float64,
    trmin: Float64,
    wso: Float64,
    wsi: Float64,
    dir: Float64,
    outir: Float64,
    isky: Int32,
    tsky: Float64,
    esky: Float64,
    fclr: Float64,
    vacuum_pressure: Float64,
    vacuum_max_gap_thickness: Float64,
    calc_deflection: Int32,
    pa: Float64,
    pini: Float64,
    tini: Float64,
    gap: Span[Float64],
    gap_def: Span[Float64],
    thick: Span[Float64],
    scon: Span[Float64],
    youngs_mod: Span[Float64],
    poissons_rat: Span[Float64],
    tir: Span[Float64],
    emis: Span[Float64],
    totsol: Float64,
    tilt: Float64,
    asol: Span[Float64],
    height: Float64,
    heightt: Float64,
    width: Float64,
    presure: Span[Float64],
    iprop: Span[Span[Int32]],
    frct: Span[Span[Float64]],
    xgcon: Span[Span[Float64]],
    xgvis: Span[Span[Float64]],
    xgcp: Span[Span[Float64]],
    xwght: Span[Float64],
    gama: Span[Float64],
    nmix: Span[Int32],
    support_pillar: Span[Int32],
    pillar_spacing: Span[Float64],
    pillar_radius: Span[Float64],
    hin: Float64,
    hout: Float64,
    ibc: Span[Int32],
    atop: Span[Float64],
    abot: Span[Float64],
    al: Span[Float64],
    ar: Span[Float64],
    ah: Span[Float64],
    slat_thick: Span[Float64],
    slat_width: Span[Float64],
    slat_angle: Span[Float64],
    slat_cond: Span[Float64],
    slat_spacing: Span[Float64],
    slat_curve: Span[Float64],
    vvent: Span[Float64],
    tvent: Span[Float64],
    layer_type: Span[Int32],
    nslice: Span[Int32],
    laminate_a: Span[Float64],
    laminate_b: Span[Float64],
    sumsol: Span[Float64],
    standard: Stdrd,
    thermal_mod: Int32,
    sd_scalar: Float64,
    error_message: Span[StringRef]) -> Int32:

    var arg_check_val: Int32 = 0

    if files.WriteDebugOutput:
        write_input_arguments(state,
                            files.DebugOutputFile,
                            files.DBGD,
                            tout,
                            tind,
                            trmin,
                            wso,
                            iwd,
                            wsi,
                            dir,
                            outir,
                            isky,
                            tsky,
                            esky,
                            fclr,
                            vacuum_pressure,
                            vacuum_max_gap_thickness,
                            ibc,
                            hout,
                            hin,
                            standard,
                            thermal_mod,
                            sd_scalar,
                            height,
                            heightt,
                            width,
                            tilt,
                            totsol,
                            nlayer,
                            layer_type,
                            thick,
                            scon,
                            asol,
                            tir,
                            emis,
                            atop,
                            abot,
                            al,
                            ar,
                            ah,
                            slat_thick,
                            slat_width,
                            slat_angle,
                            slat_cond,
                            slat_spacing,
                            slat_curve,
                            nslice,
                            laminate_a,
                            laminate_b,
                            sumsol,
                            gap,
                            vvent,
                            tvent,
                            presure,
                            nmix,
                            iprop,
                            frct,
                            xgcon,
                            xgvis,
                            xgcp,
                            xwght)

        var version_number = " 7.0.15.00 "
        write_tarcog_input_file(state,
                               files,
                               version_number,
                               tout,
                               tind,
                               trmin,
                               wso,
                               iwd,
                               wsi,
                               dir,
                               outir,
                               isky,
                               tsky,
                               esky,
                               fclr,
                               vacuum_pressure,
                               vacuum_max_gap_thickness,
                               calc_deflection,
                               pa,
                               pini,
                               tini,
                               ibc,
                               hout,
                               hin,
                               standard,
                               thermal_mod,
                               sd_scalar,
                               height,
                               heightt,
                               width,
                               tilt,
                               totsol,
                               nlayer,
                               layer_type,
                               thick,
                               scon,
                               youngs_mod,
                               poissons_rat,
                               asol,
                               tir,
                               emis,
                               atop,
                               abot,
                               al,
                               ar,
                               ah,
                               support_pillar,
                               pillar_spacing,
                               pillar_radius,
                               slat_thick,
                               slat_width,
                               slat_angle,
                               slat_cond,
                               slat_spacing,
                               slat_curve,
                               nslice,
                               gap,
                               gap_def,
                               vvent,
                               tvent,
                               presure,
                               nmix,
                               iprop,
                               frct,
                               xgcon,
                               xgvis,
                               xgcp,
                               xwght,
                               gama)

    arg_check_val = 0

    if nlayer < 1:
        arg_check_val = 17
        error_message[0] = "Number of layers must be >0."
        return arg_check_val

    if int(standard) < MinStandard or int(standard) > MaxStandard:
        arg_check_val = 28
        error_message[0] = "Invalid code for standard."
        return arg_check_val

    if thermal_mod != TARCOGThermalModel.ISO15099 and thermal_mod != TARCOGThermalModel.SCW and thermal_mod != TARCOGThermalModel.CSM:
        arg_check_val = 29
        error_message[0] = "Invalid code for thermal mode."
        return arg_check_val

    if iwd != 0 and iwd != 1:
        arg_check_val = 18
        error_message[0] = "Wind direction can be windward (=0) or leeward (=1)."
        return arg_check_val

    if fclr < 0.0 or fclr > 1.0:
        arg_check_val = 19
        error_message[0] = "Fraction of sky that is clear can be in range between 0 and 1."
        return arg_check_val

    for i in range(nlayer - 1):
        if gap[i] <= 0.0:
            arg_check_val = 20
            error_message[0] = f"Gap width is less than (or equal to) zero. Gap #{i + 1:3}"
            return arg_check_val

    for i in range(nlayer):
        if thick[i] <= 0.0:
            arg_check_val = 21
            error_message[0] = f"Layer width is less than (or equal to) zero. Layer #{i + 1:3}"
            return arg_check_val
        if i < nlayer - 1 and is_shading_layer(layer_type[i]) and is_shading_layer(layer_type[i + 1]):
            arg_check_val = 37
            error_message[0] = "Cannot handle two consecutive shading layers."
            return arg_check_val
        if calc_deflection != DeflectionCalculation.NONE and layer_type[i] != TARCOGLayerType.SPECULAR:
            arg_check_val = 42
            error_message[0] = "Cannot calculate deflection with IGU containing shading devices."
            return arg_check_val

    if height <= 0.0:
        arg_check_val = 23
        error_message[0] = "IGU cavity height must be greater than zero."
        return arg_check_val

    if heightt <= 0.0:
        arg_check_val = 24
        error_message[0] = "Total window height must be greater than zero."
        return arg_check_val

    if width <= 0.0:
        arg_check_val = 25
        error_message[0] = "Window width must be greater than zero."
        return arg_check_val

    if sd_scalar < 0.0 or sd_scalar > 1.0:
        arg_check_val = 30
        error_message[0] = "SDscalar is out of range (<0.0 or >1.0)."
        return arg_check_val

    for i in range(nlayer):
        if scon[i] <= 0.0:
            arg_check_val = 26
            error_message[0] = f"Layer {i + 1:3} has conductivity which is less or equal to zero."
            return arg_check_val

        if (layer_type[i] != TARCOGLayerType.SPECULAR and
            layer_type[i] != TARCOGLayerType.WOVSHADE and
            layer_type[i] != TARCOGLayerType.VENETBLIND_HORIZ and
            layer_type[i] != TARCOGLayerType.PERFORATED and
            layer_type[i] != TARCOGLayerType.DIFFSHADE and
            layer_type[i] != TARCOGLayerType.BSDF and
            layer_type[i] != TARCOGLayerType.VENETBLIND_VERT):
            arg_check_val = 22
            error_message[0] = (f"Incorrect layer type for layer #{i + 1:3}"
                              ".  Layer type can either be 0 (glazing layer), 1 (Venetian blind), "
                              "2 (woven shade), 3 (perforated), 4 (diffuse shade) or 5 (bsdf).")
            return arg_check_val

        if is_shading_layer(layer_type[0]) and (thermal_mod == TARCOGThermalModel.SCW or thermal_mod == TARCOGThermalModel.CSM):
            arg_check_val = 39
            error_message[0] = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
            return arg_check_val

        if is_shading_layer(layer_type[nlayer - 1]) and (thermal_mod == TARCOGThermalModel.SCW or thermal_mod == TARCOGThermalModel.CSM):
            arg_check_val = 39
            error_message[0] = "CSM and SCW thermal models cannot be used for outdoor and indoor SD layers."
            return arg_check_val

        if (layer_type[i] == TARCOGLayerType.VENETBLIND_HORIZ or
            layer_type[i] == TARCOGLayerType.VENETBLIND_VERT):
            if slat_thick[i] <= 0:
                arg_check_val = 31
                error_message[0] = f"Invalid slat thickness (must be >0). Layer #{i + 1:3}"
                return arg_check_val
            if slat_width[i] <= 0.0:
                arg_check_val = 32
                error_message[0] = f"Invalid slat width (must be >0). Layer #{i + 1:3}"
                return arg_check_val
            if slat_angle[i] < -90.0 or slat_angle[i] > 90.0:
                arg_check_val = 33
                error_message[0] = f"Invalid slat angle (must be between -90 and 90). Layer #{i + 1:3}"
                return arg_check_val
            if slat_cond[i] <= 0.0:
                arg_check_val = 34
                error_message[0] = f"Invalid conductivity of slat material (must be >0). Layer #{i + 1:3}"
                return arg_check_val
            if slat_spacing[i] <= 0.0:
                arg_check_val = 35
                error_message[0] = f"Invalid slat spacing (must be >0). Layer #{i + 1:3}"
                return arg_check_val
            if slat_curve[i] != 0.0 and fabs(slat_curve[i]) <= slat_width[i] / 2.0:
                arg_check_val = 36
                error_message[0] = f"Invalid curvature radius (absolute value must be >SlatWidth/2, or 0 for flat slats). Layer #{i + 1:3}"
                return arg_check_val

    for i in range(nlayer + 1):
        if presure[i] < 0.0:
            arg_check_val = 27
            if i == 0 or i == nlayer:
                error_message[0] = "One of environments (inside or outside) has pressure which is less than zero."
            else:
                error_message[0] = f"One of gaps has pressure which is less than zero. Gap #{i:3}"
            return arg_check_val

    return arg_check_val


fn prep_variables_iso15099(
    nlayer: Int32,
    tout: Float64,
    tind: Float64,
    trmin: Span[Float64],
    isky: Int32,
    outir: Float64,
    tsky: Float64,
    esky: Span[Float64],
    fclr: Float64,
    gap: Span[Float64],
    thick: Span[Float64],
    scon: Span[Float64],
    tir: Span[Float64],
    emis: Span[Float64],
    tilt: Float64,
    hin: Float64,
    hout: Float64,
    ibc: Span[Int32],
    slat_thick: Span[Float64],
    slat_width: Span[Float64],
    slat_angle: Span[Float64],
    slat_cond: Span[Float64],
    layer_type: Span[Int32],
    thermal_mod: Int32,
    sd_scalar: Float64,
    shade_emis_ratio_out: Span[Float64],
    shade_emis_ratio_in: Span[Float64],
    shade_hc_ratio_out: Span[Float64],
    shade_hc_ratio_in: Span[Float64],
    keff: Span[Float64],
    shade_gap_keff_conv: Span[Float64],
    sc: Span[Float64],
    shgc: Span[Float64],
    ufactor: Span[Float64],
    flux: Span[Float64],
    laminate_au: Span[Float64],
    sumsol_u: Span[Float64],
    sol0: Span[Float64],
    hint: Span[Float64],
    houtt: Span[Float64],
    trmout: Span[Float64],
    ebsky: Span[Float64],
    ebroom: Span[Float64],
    gout: Span[Float64],
    gin: Span[Float64],
    rir: Span[Float64],
    vfreevent: Span[Float64],
    nperr: Span[Int32],
    error_message: Span[StringRef]) -> None:

    shade_emis_ratio_out[0] = 1.0
    shade_emis_ratio_in[0] = 1.0
    shade_hc_ratio_out[0] = 1.0
    shade_hc_ratio_in[0] = 1.0

    sc[0] = 0.0
    shgc[0] = 0.0
    ufactor[0] = 0.0
    flux[0] = 0.0

    for i in range(nlayer):
        laminate_au[i] = 0.0
        sumsol_u[i] = 0.0
        sol0[i] = 0.0
        keff[i] = 0.0

    for i in range(MaxGap):
        vfreevent[i] = 0.0
        shade_gap_keff_conv[i] = 0.0

    for i in range(nlayer):
        if (layer_type[i] == TARCOGLayerType.VENETBLIND_HORIZ or
            layer_type[i] == TARCOGLayerType.VENETBLIND_VERT):
            scon[i] = slat_cond[i]
            if thermal_mod == TARCOGThermalModel.SCW:
                thick[i] = slat_width[i] * cos(slat_angle[i] * PI / 180.0)
                if i > 0:
                    gap[i - 1] += (1.0 - sd_scalar) / 2.0 * thick[i]
                gap[i] += (1.0 - sd_scalar) / 2.0 * thick[i]
                thick[i] *= sd_scalar
                if thick[i] < slat_thick[i]:
                    thick[i] = slat_thick[i]
            elif thermal_mod == TARCOGThermalModel.ISO15099 or thermal_mod == TARCOGThermalModel.CSM:
                thick[i] = slat_thick[i]
                var slat_ang_rad = slat_angle[i] * 2.0 * PI / 360.0
                var c4_venet: Float64 = 0.0
                if layer_type[i] == TARCOGLayerType.VENETBLIND_HORIZ:
                    c4_venet = C4_VENET_HORIZONTAL
                if layer_type[i] == TARCOGLayerType.VENETBLIND_VERT:
                    c4_venet = C4_VENET_VERTICAL
                thick[i] = c4_venet * (slat_width[i] * cos(slat_ang_rad) + slat_thick[i] * sin(slat_ang_rad))

    hint[0] = hin
    houtt[0] = hout
    var tiltr = tilt * 2.0 * PI / 360.0

    if isky == 3:
        gout[0] = outir
        trmout[0] = root_4(gout[0] / STEFAN_BOLTZMANN)
    elif isky == 2:
        var rsky = 5.31e-13 * pow_6(tout)
        esky[0] = rsky / (STEFAN_BOLTZMANN * pow_4(tout))
    elif isky == 1:
        esky[0] = pow_4(tsky) / pow_4(tout)
    elif isky == 0:
        esky[0] *= pow_4(tsky) / pow_4(tout)
    else:
        nperr[0] = 1
        return

    if isky != 3:
        var fsky = (1.0 + cos(tiltr)) / 2.0
        var fground = 1.0 - fsky
        var e0 = fground + (1.0 - fclr) * fsky + fsky * fclr * esky[0]

        if ibc[0] == 1:
            trmout[0] = tout
        else:
            trmout[0] = tout * root_4(e0)

        gout[0] = STEFAN_BOLTZMANN * pow_4(trmout[0])

    ebsky[0] = gout[0]

    if ibc[1] == 1:
        trmin[0] = tind

    gin[0] = STEFAN_BOLTZMANN * pow_4(trmin[0])
    ebroom[0] = gin[0]

    for k in range(nlayer):
        var k1 = 2 * k
        rir[k1] = 1 - tir[k1] - emis[k1]
        rir[k1 + 1] = 1 - tir[k1] - emis[k1 + 1]
        if tir[k1] < 0.0 or tir[k1] > 1.0 or tir[k1 + 1] < 0.0 or tir[k1 + 1] > 1.0:
            nperr[0] = 4
            error_message[0] = f"Layer transmissivity is our of range (<0 or >1). Layer #{k + 1:3}"
            return
        if emis[k1] < 0.0 or emis[k1] > 1.0 or emis[k1 + 1] < 0.0 or emis[k1 + 1] > 1.0:
            nperr[0] = 14
            error_message[0] = f"Layer emissivity is our of range (<0 or >1). Layer #{k + 1:3}"
            return
        if rir[k1] < 0.0 or rir[k1] > 1.0 or rir[k1 + 1] < 0.0 or rir[k1 + 1] > 1.0:
            nperr[0] = 3
            error_message[0] = f"Layer reflectivity is our of range (<0 or >1). Layer #{k + 1:3}"
            return


fn go_ahead(nperr: Int32) -> Bool:
    return not (((nperr > 0) and (nperr < 1000)) or ((nperr > 2000) and (nperr < 3000)))
