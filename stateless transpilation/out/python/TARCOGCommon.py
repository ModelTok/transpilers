# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: State object with dataTARCOGCommon.vv (from EnergyPlus/Data/EnergyPlusData.hh)
# - TARCOGParams: Module with MMax, NMax constants and TARCOGLayerType enum (from EnergyPlus/TARCOGParams.hh)
# - Constant: Module with Pi, PiOvr2, StefanBoltzmann constants (from EnergyPlus)

import math
from typing import List, Protocol


NMAX = 500


class TARCOGLayerType:
    VENETBLIND_HORIZ = 0
    VENETBLIND_VERT = 1
    WOVSHADE = 2
    PERFORATED = 3
    BSDF = 4
    DIFFSHADE = 5


class TARCOGParamsStub:
    MMax = 100
    NMax = 100
    TARCOGLayerType = TARCOGLayerType


class ConstantStub:
    Pi = 3.141592653589793
    PiOvr2 = 1.5707963267948966
    StefanBoltzmann = 5.670374419e-8


class TARCOGCommonDataStub:
    vv: List[float]
    
    def __init__(self):
        self.vv = [0.0] * NMAX


class EnergyPlusDataStub(Protocol):
    dataTARCOGCommon: TARCOGCommonDataStub


def pow_2(x: float) -> float:
    return x * x


def pow_3(x: float) -> float:
    return x * x * x


def is_shading_layer(layertype: int) -> bool:
    return (layertype == TARCOGLayerType.VENETBLIND_HORIZ or 
            layertype == TARCOGLayerType.VENETBLIND_VERT or
            layertype == TARCOGLayerType.WOVSHADE or 
            layertype == TARCOGLayerType.PERFORATED or 
            layertype == TARCOGLayerType.BSDF or
            layertype == TARCOGLayerType.DIFFSHADE)


def ld_sum_max(width: float, height: float, tarcog_params=None, constant=None) -> float:
    if tarcog_params is None:
        tarcog_params = TARCOGParamsStub
    if constant is None:
        constant = ConstantStub
    
    ld_sum_max_val = 0.0
    for i in range(1, tarcog_params.MMax + 1, 2):
        sin_i = math.sin(i * constant.PiOvr2)
        pow_i_w = pow_2(i / width)
        for j in range(1, tarcog_params.NMax + 1, 2):
            ld_sum_max_val += (sin_i * math.sin(j * constant.PiOvr2)) / (i * j * pow_2(pow_i_w + pow_2(j / height)))
    return ld_sum_max_val


def ld_sum_mean(width: float, height: float, tarcog_params=None, constant=None) -> float:
    if tarcog_params is None:
        tarcog_params = TARCOGParamsStub
    if constant is None:
        constant = ConstantStub
    
    pi_squared = constant.Pi * constant.Pi
    ld_sum_mean_val = 0.0
    for i in range(1, tarcog_params.MMax + 1, 2):
        pow_i_pi_2 = i * i * pi_squared
        pow_i_w = pow_2(i / width)
        for j in range(1, tarcog_params.NMax + 1, 2):
            ld_sum_mean_val += 4.0 / (pow_i_pi_2 * pow_2(j) * pow_2(pow_i_w + pow_2(j / height)))
    return ld_sum_mean_val


def modify_hc_gap(hcgap: List[float], qv: List[float], hcv: List[float], 
                  hcgap_mod: List[float], nlayer: int, edge_gl_cor_fac: float) -> None:
    for i in range(1, nlayer + 2):
        if qv[i - 1] != 0:
            hcgap_mod[i - 1] = 0.5 * hcv[i - 1]
        else:
            hcgap_mod[i - 1] = hcgap[i - 1] * edge_gl_cor_fac


def matrix_q_balance(nlayer: int,
                     a: List[List[float]],
                     b: List[float],
                     scon_scaled: List[float],
                     hcgas: List[float],
                     hcgap_mod: List[float],
                     asol: List[float],
                     qv: List[float],
                     hcv: List[float],
                     tin: float,
                     tout: float,
                     gin: float,
                     gout: float,
                     theta: List[float],
                     tir: List[float],
                     rir: List[float],
                     emis: List[float],
                     edge_gl_corr_fac: float,
                     tarcog_params=None,
                     constant=None) -> None:
    if tarcog_params is None:
        tarcog_params = TARCOGParamsStub
    if constant is None:
        constant = ConstantStub
    
    for i in range(1, 4 * nlayer + 1):
        b[i - 1] = 0.0
        for j in range(1, 4 * nlayer + 1):
            a[j - 1][i - 1] = 0.0
    
    modify_hc_gap(hcgas, qv, hcv, hcgap_mod, nlayer, edge_gl_corr_fac)
    
    for i in range(1, nlayer + 1):
        k = 4 * i - 3
        front = 2 * i - 1
        back = 2 * i
        
        if i != 1:
            a[k - 2][k - 1] = -hcgap_mod[i - 1]
            a[k - 3][k - 1] = tir[front - 1] - 1.0
        a[k - 1][k - 1] = hcgap_mod[i - 1] + scon_scaled[i - 1]
        a[k][k - 1] = 1.0
        a[k + 2][k - 1] = -scon_scaled[i - 1]
        if i != nlayer:
            a[k + 4][k - 1] = -tir[back - 1]
        
        a[k - 1][k] = emis[front - 1] * constant.StefanBoltzmann * pow_3(theta[front - 1])
        a[k][k] = -1.0
        if i != 1:
            a[k - 3][k] = rir[front - 1]
        if i != nlayer:
            a[k + 4][k] = tir[back - 1]
        
        a[k + 1][k + 1] = -1.0
        a[k + 2][k + 1] = emis[back - 1] * constant.StefanBoltzmann * pow_3(theta[back - 1])
        if i != 1:
            a[k - 3][k + 1] = tir[front - 1]
        if i != nlayer:
            a[k + 4][k + 1] = rir[back - 1]
        
        a[k - 1][k + 2] = scon_scaled[i - 1]
        a[k + 1][k + 2] = -1.0
        a[k + 2][k + 2] = -hcgap_mod[i] - scon_scaled[i - 1]
        if i != 1:
            a[k - 3][k + 2] = tir[front - 1]
        if i != nlayer:
            a[k + 3][k + 2] = hcgap_mod[i]
            a[k + 4][k + 2] = 1.0 - tir[back - 1]
    
    for i in range(1, nlayer + 1):
        k = 4 * i - 3
        front = 2 * i - 1
        back = 2 * i
        vent = i + 1
        
        b[k - 1] = 0.5 * asol[i - 1] + 0.5 * qv[vent - 2]
        b[k + 2] = -0.5 * asol[i - 1] - 0.5 * qv[vent - 1]
        
        if i == 1:
            b[k - 1] = b[k - 1] + hcgap_mod[i - 1] * tout + gout - tir[front - 1] * gout
            b[k] = b[k] - rir[front - 1] * gout
            b[k + 1] = b[k + 1] - tir[front - 1] * gout
            b[k + 2] = b[k + 2] - tir[front - 1] * gout
        
        if i == nlayer:
            b[k - 1] = b[k - 1] + tir[back - 1] * gin
            b[k] = b[k] - tir[back - 1] * gin
            b[k + 1] = b[k + 1] - rir[back - 1] * gin
            b[k + 2] = b[k + 2] - gin - hcgap_mod[i] * tin + tir[back - 1] * gin


def equations_solver(state: EnergyPlusDataStub, a: List[List[float]], b: List[float], n: int) -> tuple:
    indx = [0] * n
    d = 1.0
    nperr = 0
    error_message = ""
    
    ludcmp(state, a, n, indx, d)
    
    if nperr > 0 and nperr <= 1000:
        return nperr, error_message
    
    lubksb(a, n, indx, b)
    return 0, ""


def ludcmp(state: EnergyPlusDataStub, a: List[List[float]], n: int, indx: List[int], d_ref: List[float]) -> tuple:
    TINY = 1.0e-20
    
    d = 1.0
    nperr = 0
    error_message = ""
    
    for i in range(1, n + 1):
        aamax = 0.0
        for j in range(1, n + 1):
            if abs(a[j - 1][i - 1]) > aamax:
                aamax = abs(a[j - 1][i - 1])
        if aamax == 0.0:
            nperr = 13
            error_message = "Singular matrix in ludcmp."
            return nperr, error_message
        state.dataTARCOGCommon.vv[i - 1] = 1.0 / aamax
    
    for j in range(1, n + 1):
        for i in range(1, j):
            sum_val = a[j - 1][i - 1]
            for k in range(1, i):
                sum_val -= a[k - 1][i - 1] * a[j - 1][k - 1]
            a[j - 1][i - 1] = sum_val
        
        aamax = 0.0
        imax = j
        for i in range(j, n + 1):
            sum_val = a[j - 1][i - 1]
            for k in range(1, j):
                sum_val -= a[k - 1][i - 1] * a[j - 1][k - 1]
            a[j - 1][i - 1] = sum_val
            dum = state.dataTARCOGCommon.vv[i - 1] * abs(sum_val)
            if dum >= aamax:
                imax = i
                aamax = dum
        
        if j != imax:
            for k in range(1, n + 1):
                dum = a[k - 1][imax - 1]
                a[k - 1][imax - 1] = a[k - 1][j - 1]
                a[k - 1][j - 1] = dum
            d = -d
            state.dataTARCOGCommon.vv[imax - 1] = state.dataTARCOGCommon.vv[j - 1]
        
        indx[j - 1] = imax
        if a[j - 1][j - 1] == 0.0:
            a[j - 1][j - 1] = TINY
        
        if j != n:
            dum = 1.0 / a[j - 1][j - 1]
            for i in range(j + 1, n + 1):
                a[j - 1][i - 1] *= dum
    
    return nperr, error_message


def lubksb(a: List[List[float]], n: int, indx: List[int], b: List[float]) -> None:
    ii = 0
    for i in range(1, n + 1):
        ll = indx[i - 1]
        sum_val = b[ll - 1]
        b[ll - 1] = b[i - 1]
        if ii != 0:
            for j in range(ii, i):
                sum_val -= a[j - 1][i - 1] * b[j - 1]
        elif sum_val != 0.0:
            ii = i
        b[i - 1] = sum_val
    
    for i in range(n, 0, -1):
        sum_val = b[i - 1]
        for j in range(i + 1, n + 1):
            sum_val -= a[j - 1][i - 1] * b[j - 1]
        b[i - 1] = sum_val / a[i - 1][i - 1]


def pos(x: float) -> float:
    return (x + abs(x)) / 2.0


class TARCOGCommonData:
    def __init__(self):
        self.vv = [0.0] * NMAX
    
    def init_constant_state(self, state: EnergyPlusDataStub) -> None:
        pass
    
    def init_state(self, state: EnergyPlusDataStub) -> None:
        pass
    
    def clear_state(self) -> None:
        self.vv = [0.0] * NMAX
