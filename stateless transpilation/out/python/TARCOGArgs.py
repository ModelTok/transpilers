# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): EnergyPlus/EnergyPlus.hh
# - Files (from TARCOGOutput): EnergyPlus/TARCOGOutput.hh
# - DeflectionCalculation, TARCOGLayerType, TARCOGThermalModel: EnergyPlus/TARCOGParams.hh
# - Stdrd: EnergyPlus/TARCOGGassesParams.hh
# - Constants (maxlay, MaxGap, maxgas, maxlay1, maxlay2, MinStandard, MaxStandard): EnergyPlus/TARCOGGassesParams.hh, TARCOGParams.hh
# - C4_VENET_HORIZONTAL, C4_VENET_VERTICAL: TARCOGCommon.hh or TARCOGParams.hh
# - WriteInputArguments, WriteTARCOGInputFile, IsShadingLayer: EnergyPlus/TARCOGOutput.hh, TARCOGCommon.hh

from typing import Protocol, List, Tuple
from enum import IntEnum
from dataclasses import dataclass
import math


# ==================== ENUMS ====================
class DeflectionCalculation(IntEnum):
    NONE = 0


class TARCOGLayerType(IntEnum):
    SPECULAR = 0
    VENETBLIND_HORIZ = 1
    WOVSHADE = 2
    PERFORATED = 3
    DIFFSHADE = 4
    BSDF = 5
    VENETBLIND_VERT = 6


class TARCOGThermalModel(IntEnum):
    ISO15099 = 0
    SCW = 1
    CSM = 2


class Stdrd(IntEnum):
    pass


# ==================== CONSTANTS ====================
maxlay = 10
MaxGap = 10
maxgas = 12
maxlay1 = 11
maxlay2 = 20
MinStandard = 0
MaxStandard = 4
C4_VENET_HORIZONTAL = 0.0
C4_VENET_VERTICAL = 0.0


# ==================== PROTOCOLS & STUBS ====================
class EnergyPlusData(Protocol):
    pass


@dataclass
class Files:
    WriteDebugOutput: bool
    DebugOutputFile: object
    DBGD: object


# ==================== MATH HELPERS ====================
def pow_6(x: float) -> float:
    return x ** 6


def pow_4(x: float) -> float:
    return x ** 4


def root_4(x: float) -> float:
    return x ** 0.25


# ==================== CONSTANTS (PHYSICAL) ====================
PI = math.pi
STEFAN_BOLTZMANN = 5.670374419e-8


# ==================== EXTERNAL FUNCTION STUBS ====================
def write_input_arguments(state: EnergyPlusData,
                         debug_output_file: object,
                         dbgd: object,
                         tout: float,
                         tind: float,
                         trmin: float,
                         wso: float,
                         iwd: int,
                         wsi: float,
                         dir: float,
                         outir: float,
                         isky: int,
                         tsky: float,
                         esky: float,
                         fclr: float,
                         vacuum_pressure: float,
                         vacuum_max_gap_thickness: float,
                         ibc: List[int],
                         hout: float,
                         hin: float,
                         standard: Stdrd,
                         thermal_mod: TARCOGThermalModel,
                         sd_scalar: float,
                         height: float,
                         heightt: float,
                         width: float,
                         tilt: float,
                         totsol: float,
                         nlayer: int,
                         layer_type: List[TARCOGLayerType],
                         thick: List[float],
                         scon: List[float],
                         asol: List[float],
                         tir: List[float],
                         emis: List[float],
                         atop: List[float],
                         abot: List[float],
                         al: List[float],
                         ar: List[float],
                         ah: List[float],
                         slat_thick: List[float],
                         slat_width: List[float],
                         slat_angle: List[float],
                         slat_cond: List[float],
                         slat_spacing: List[float],
                         slat_curve: List[float],
                         nslice: List[int],
                         laminate_a: List[float],
                         laminate_b: List[float],
                         sumsol: List[float],
                         gap: List[float],
                         vvent: List[float],
                         tvent: List[float],
                         presure: List[float],
                         nmix: List[int],
                         iprop: List[List[int]],
                         frct: List[List[float]],
                         xgcon: List[List[float]],
                         xgvis: List[List[float]],
                         xgcp: List[List[float]],
                         xwght: List[float]) -> None:
    pass


def write_tarcog_input_file(state: EnergyPlusData,
                           files: Files,
                           version_number: str,
                           tout: float,
                           tind: float,
                           trmin: float,
                           wso: float,
                           iwd: int,
                           wsi: float,
                           dir: float,
                           outir: float,
                           isky: int,
                           tsky: float,
                           esky: float,
                           fclr: float,
                           vacuum_pressure: float,
                           vacuum_max_gap_thickness: float,
                           calc_deflection: DeflectionCalculation,
                           pa: float,
                           pini: float,
                           tini: float,
                           ibc: List[int],
                           hout: float,
                           hin: float,
                           standard: Stdrd,
                           thermal_mod: TARCOGThermalModel,
                           sd_scalar: float,
                           height: float,
                           heightt: float,
                           width: float,
                           tilt: float,
                           totsol: float,
                           nlayer: int,
                           layer_type: List[TARCOGLayerType],
                           thick: List[float],
                           scon: List[float],
                           youngs_mod: List[float],
                           poissons_rat: List[float],
                           asol: List[float],
                           tir: List[float],
                           emis: List[float],
                           atop: List[float],
                           abot: List[float],
                           al: List[float],
                           ar: List[float],
                           ah: List[float],
                           support_pillar: List[int],
                           pillar_spacing: List[float],
                           pillar_radius: List[float],
                           slat_thick: List[float],
                           slat_width: List[float],
                           slat_angle: List[float],
                           slat_cond: List[float],
                           slat_spacing: List[float],
                           slat_curve: List[float],
                           nslice: List[int],
                           gap: List[float],
                           gap_def: List[float],
                           vvent: List[float],
                           tvent: List[float],
                           presure: List[float],
                           nmix: List[int],
                           iprop: List[List[int]],
                           frct: List[List[float]],
                           xgcon: List[List[float]],
                           xgvis: List[List[float]],
                           xgcp: List[List[float]],
                           xwght: List[float],
                           gama: List[float]) -> None:
    pass


def is_shading_layer(layer_type: TARCOGLayerType) -> bool:
    return layer_type != TARCOGLayerType.SPECULAR and layer_type != TARCOGLayerType.BSDF


# ==================== MAIN FUNCTIONS ====================
def arg_check(state: EnergyPlusData,
             files: Files,
             nlayer: int,
             iwd: int,
             tout: float,
             tind: float,
             trmin: float,
             wso: float,
             wsi: float,
             dir: float,
             outir: float,
             isky: int,
             tsky: float,
             esky: float,
             fclr: float,
             vacuum_pressure: float,
             vacuum_max_gap_thickness: float,
             calc_deflection: DeflectionCalculation,
             pa: float,
             pini: float,
             tini: float,
             gap: List[float],
             gap_def: List[float],
             thick: List[float],
             scon: List[float],
             youngs_mod: List[float],
             poissons_rat: List[float],
             tir: List[float],
             emis: List[float],
             totsol: float,
             tilt: float,
             asol: List[float],
             height: float,
             heightt: float,
             width: float,
             presure: List[float],
             iprop: List[List[int]],
             frct: List[List[float]],
             xgcon: List[List[float]],
             xgvis: List[List[float]],
             xgcp: List[List[float]],
             xwght: List[float],
             gama: List[float],
             nmix: List[int],
             support_pillar: List[int],
             pillar_spacing: List[float],
             pillar_radius: List[float],
             hin: float,
             hout: float,
             ibc: List[int],
             atop: List[float],
             abot: List[float],
             al: List[float],
             ar: List[float],
             ah: List[float],
             slat_thick: List[float],
             slat_width: List[float],
             slat_angle: List[float],
             slat_cond: List[float],
             slat_spacing: List[float],
             slat_curve: List[float],
             vvent: List[float],
             tvent: List[float],
             layer_type: List[TARCOGLayerType],
             nslice: List[int],
             laminate_a: List[float],
             laminate_b: List[float],
             sumsol: List[float],
             standard: Stdrd,
             thermal_mod: TARCOGThermalModel,
             sd_scalar: float,
             error_message: List[str]) -> int:

    arg_check_val = 0

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

        version_number = " 7.0.15.00 "
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
            if slat_curve[i] != 0.0 and abs(slat_curve[i]) <= slat_width[i] / 2.0:
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


def prep_variables_iso15099(nlayer: int,
                           tout: float,
                           tind: float,
                           trmin: List[float],
                           isky: int,
                           outir: float,
                           tsky: float,
                           esky: List[float],
                           fclr: float,
                           gap: List[float],
                           thick: List[float],
                           scon: List[float],
                           tir: List[float],
                           emis: List[float],
                           tilt: float,
                           hin: float,
                           hout: float,
                           ibc: List[int],
                           slat_thick: List[float],
                           slat_width: List[float],
                           slat_angle: List[float],
                           slat_cond: List[float],
                           layer_type: List[TARCOGLayerType],
                           thermal_mod: TARCOGThermalModel,
                           sd_scalar: float,
                           shade_emis_ratio_out: List[float],
                           shade_emis_ratio_in: List[float],
                           shade_hc_ratio_out: List[float],
                           shade_hc_ratio_in: List[float],
                           keff: List[float],
                           shade_gap_keff_conv: List[float],
                           sc: List[float],
                           shgc: List[float],
                           ufactor: List[float],
                           flux: List[float],
                           laminate_au: List[float],
                           sumsol_u: List[float],
                           sol0: List[float],
                           hint: List[float],
                           houtt: List[float],
                           trmout: List[float],
                           ebsky: List[float],
                           ebroom: List[float],
                           gout: List[float],
                           gin: List[float],
                           rir: List[float],
                           vfreevent: List[float],
                           nperr: List[int],
                           error_message: List[str]) -> None:

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
                thick[i] = slat_width[i] * math.cos(slat_angle[i] * PI / 180.0)
                if i > 0:
                    gap[i - 1] += (1.0 - sd_scalar) / 2.0 * thick[i]
                gap[i] += (1.0 - sd_scalar) / 2.0 * thick[i]
                thick[i] *= sd_scalar
                if thick[i] < slat_thick[i]:
                    thick[i] = slat_thick[i]
            elif thermal_mod == TARCOGThermalModel.ISO15099 or thermal_mod == TARCOGThermalModel.CSM:
                thick[i] = slat_thick[i]
                slat_ang_rad = slat_angle[i] * 2.0 * PI / 360.0
                c4_venet = 0.0
                if layer_type[i] == TARCOGLayerType.VENETBLIND_HORIZ:
                    c4_venet = C4_VENET_HORIZONTAL
                if layer_type[i] == TARCOGLayerType.VENETBLIND_VERT:
                    c4_venet = C4_VENET_VERTICAL
                thick[i] = c4_venet * (slat_width[i] * math.cos(slat_ang_rad) + slat_thick[i] * math.sin(slat_ang_rad))

    hint[0] = hin
    houtt[0] = hout
    tiltr = tilt * 2.0 * PI / 360.0

    match isky:
        case 3:
            gout[0] = outir
            trmout[0] = root_4(gout[0] / STEFAN_BOLTZMANN)
        case 2:
            rsky = 5.31e-13 * pow_6(tout)
            esky[0] = rsky / (STEFAN_BOLTZMANN * pow_4(tout))
        case 1:
            esky[0] = pow_4(tsky) / pow_4(tout)
        case 0:
            esky[0] *= pow_4(tsky) / pow_4(tout)
        case _:
            nperr[0] = 1
            return

    if isky != 3:
        fsky = (1.0 + math.cos(tiltr)) / 2.0
        fground = 1.0 - fsky
        e0 = fground + (1.0 - fclr) * fsky + fsky * fclr * esky[0]

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
        k1 = 2 * k
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


def go_ahead(nperr: int) -> bool:
    return not (((nperr > 0) and (nperr < 1000)) or ((nperr > 2000) and (nperr < 3000)))
