# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: State object with dataTARCOGCommon.vv (from EnergyPlus/Data/EnergyPlusData.hh)
# - TARCOGParams: Module with MMax, NMax constants and TARCOGLayerType enum (from EnergyPlus/TARCOGParams.hh)
# - Constant: Module with Pi, PiOvr2, StefanBoltzmann constants (from EnergyPlus)

from math import sin, abs as math_abs
from sys.intrinsics import _mlirgen_llvm_exp
from memory import DTypePointer, Span

alias NMAX = 500
alias Real64 = Float64


@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x


@always_inline
fn pow_3(x: Float64) -> Float64:
    return x * x * x


struct TARCOGLayerType:
    alias VENETBLIND_HORIZ = 0
    alias VENETBLIND_VERT = 1
    alias WOVSHADE = 2
    alias PERFORATED = 3
    alias BSDF = 4
    alias DIFFSHADE = 5


trait TARCOGParams:
    fn get_mmax(self) -> Int
    fn get_nmax(self) -> Int


trait ConstantsProvider:
    fn get_pi(self) -> Float64
    fn get_pi_ovr2(self) -> Float64
    fn get_stefan_boltzmann(self) -> Float64


trait TARCOGCommonDataTrait:
    fn get_vv(self, idx: Int) -> Float64
    fn set_vv(self, idx: Int, val: Float64) -> None


trait EnergyPlusDataTrait:
    fn get_tarcog_common_data(self) -> TARCOGCommonDataTrait


fn is_shading_layer(layertype: Int) -> Bool:
    return (layertype == TARCOGLayerType.VENETBLIND_HORIZ or 
            layertype == TARCOGLayerType.VENETBLIND_VERT or
            layertype == TARCOGLayerType.WOVSHADE or 
            layertype == TARCOGLayerType.PERFORATED or 
            layertype == TARCOGLayerType.BSDF or
            layertype == TARCOGLayerType.DIFFSHADE)


fn ld_sum_max(width: Float64, height: Float64, tarcog_params: TARCOGParams, constant: ConstantsProvider) -> Float64:
    var ld_sum_max_val = 0.0
    var mmax = tarcog_params.get_mmax()
    var nmax = tarcog_params.get_nmax()
    var pi_ovr2 = constant.get_pi_ovr2()
    
    for i in range(1, mmax + 1, 2):
        var sin_i = sin(i * pi_ovr2)
        var pow_i_w = pow_2(i / width)
        for j in range(1, nmax + 1, 2):
            ld_sum_max_val += (sin_i * sin(j * pi_ovr2)) / (i * j * pow_2(pow_i_w + pow_2(j / height)))
    
    return ld_sum_max_val


fn ld_sum_mean(width: Float64, height: Float64, tarcog_params: TARCOGParams, constant: ConstantsProvider) -> Float64:
    var pi = constant.get_pi()
    var pi_squared = pi * pi
    var ld_sum_mean_val = 0.0
    var mmax = tarcog_params.get_mmax()
    var nmax = tarcog_params.get_nmax()
    var pi_ovr2 = constant.get_pi_ovr2()
    
    for i in range(1, mmax + 1, 2):
        var pow_i_pi_2 = i * i * pi_squared
        var pow_i_w = pow_2(i / width)
        for j in range(1, nmax + 1, 2):
            ld_sum_mean_val += 4.0 / (pow_i_pi_2 * pow_2(j) * pow_2(pow_i_w + pow_2(j / height)))
    
    return ld_sum_mean_val


fn modify_hc_gap(hcgap: Span[Float64], qv: Span[Float64], hcv: Span[Float64], 
                 hcgap_mod: Span[Float64], nlayer: Int, edge_gl_cor_fac: Float64) -> None:
    for i in range(1, nlayer + 2):
        if qv[i - 1] != 0:
            hcgap_mod[i - 1] = 0.5 * hcv[i - 1]
        else:
            hcgap_mod[i - 1] = hcgap[i - 1] * edge_gl_cor_fac


fn matrix_q_balance(nlayer: Int,
                    a: Span[Span[Float64]],
                    b: Span[Float64],
                    scon_scaled: Span[Float64],
                    hcgas: Span[Float64],
                    hcgap_mod: Span[Float64],
                    asol: Span[Float64],
                    qv: Span[Float64],
                    hcv: Span[Float64],
                    tin: Float64,
                    tout: Float64,
                    gin: Float64,
                    gout: Float64,
                    theta: Span[Float64],
                    tir: Span[Float64],
                    rir: Span[Float64],
                    emis: Span[Float64],
                    edge_gl_corr_fac: Float64,
                    tarcog_params: TARCOGParams,
                    constant: ConstantsProvider) -> None:
    
    for i in range(1, 4 * nlayer + 1):
        b[i - 1] = 0.0
        for j in range(1, 4 * nlayer + 1):
            a[j - 1][i - 1] = 0.0
    
    modify_hc_gap(hcgas, qv, hcv, hcgap_mod, nlayer, edge_gl_corr_fac)
    
    var stefan_boltzmann = constant.get_stefan_boltzmann()
    
    for i in range(1, nlayer + 1):
        var k = 4 * i - 3
        var front = 2 * i - 1
        var back = 2 * i
        
        if i != 1:
            a[k - 2][k - 1] = -hcgap_mod[i - 1]
            a[k - 3][k - 1] = tir[front - 1] - 1.0
        a[k - 1][k - 1] = hcgap_mod[i - 1] + scon_scaled[i - 1]
        a[k][k - 1] = 1.0
        a[k + 2][k - 1] = -scon_scaled[i - 1]
        if i != nlayer:
            a[k + 4][k - 1] = -tir[back - 1]
        
        a[k - 1][k] = emis[front - 1] * stefan_boltzmann * pow_3(theta[front - 1])
        a[k][k] = -1.0
        if i != 1:
            a[k - 3][k] = rir[front - 1]
        if i != nlayer:
            a[k + 4][k] = tir[back - 1]
        
        a[k + 1][k + 1] = -1.0
        a[k + 2][k + 1] = emis[back - 1] * stefan_boltzmann * pow_3(theta[back - 1])
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
        var k = 4 * i - 3
        var front = 2 * i - 1
        var back = 2 * i
        var vent = i + 1
        
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


fn equations_solver(state: EnergyPlusDataTrait, a: Span[Span[Float64]], b: Span[Float64], n: Int) -> tuple[Int, String]:
    var indx = InlineArray[Int, 500]()
    var d = 1.0
    var nperr = 0
    var error_message = String("")
    
    ludcmp(state, a, n, indx, d)
    
    if nperr > 0 and nperr <= 1000:
        return (nperr, error_message)
    
    lubksb(a, n, indx, b)
    return (0, String(""))


fn ludcmp(state: EnergyPlusDataTrait, a: Span[Span[Float64]], n: Int, indx: InlineArray[Int, 500], d: Float64) -> None:
    var TINY = 1.0e-20
    
    var tarcog_common = state.get_tarcog_common_data()
    
    for i in range(1, n + 1):
        var aamax = 0.0
        for j in range(1, n + 1):
            if math_abs(a[j - 1][i - 1]) > aamax:
                aamax = math_abs(a[j - 1][i - 1])
        if aamax == 0.0:
            return
        tarcog_common.set_vv(i - 1, 1.0 / aamax)
    
    for j in range(1, n + 1):
        for i in range(1, j):
            var sum_val = a[j - 1][i - 1]
            for k in range(1, i):
                sum_val -= a[k - 1][i - 1] * a[j - 1][k - 1]
            a[j - 1][i - 1] = sum_val
        
        var aamax = 0.0
        var imax = j
        for i in range(j, n + 1):
            var sum_val = a[j - 1][i - 1]
            for k in range(1, j):
                sum_val -= a[k - 1][i - 1] * a[j - 1][k - 1]
            a[j - 1][i - 1] = sum_val
            var dum = tarcog_common.get_vv(i - 1) * math_abs(sum_val)
            if dum >= aamax:
                imax = i
                aamax = dum
        
        if j != imax:
            for k in range(1, n + 1):
                var dum = a[k - 1][imax - 1]
                a[k - 1][imax - 1] = a[k - 1][j - 1]
                a[k - 1][j - 1] = dum
            tarcog_common.set_vv(imax - 1, tarcog_common.get_vv(j - 1))
        
        indx[j - 1] = imax
        if a[j - 1][j - 1] == 0.0:
            a[j - 1][j - 1] = TINY
        
        if j != n:
            var dum = 1.0 / a[j - 1][j - 1]
            for i in range(j + 1, n + 1):
                a[j - 1][i - 1] *= dum


fn lubksb(a: Span[Span[Float64]], n: Int, indx: InlineArray[Int, 500], b: Span[Float64]) -> None:
    var ii = 0
    for i in range(1, n + 1):
        var ll = indx[i - 1]
        var sum_val = b[ll - 1]
        b[ll - 1] = b[i - 1]
        if ii != 0:
            for j in range(ii, i):
                sum_val -= a[j - 1][i - 1] * b[j - 1]
        elif sum_val != 0.0:
            ii = i
        b[i - 1] = sum_val
    
    for i in range(n, 0, -1):
        var sum_val = b[i - 1]
        for j in range(i + 1, n + 1):
            sum_val -= a[j - 1][i - 1] * b[j - 1]
        b[i - 1] = sum_val / a[i - 1][i - 1]


fn pos(x: Float64) -> Float64:
    return (x + math_abs(x)) / 2.0


struct TARCOGCommonData:
    var vv: InlineArray[Float64, NMAX]
    
    fn __init__(inout self):
        self.vv = InlineArray[Float64, NMAX](fill=0.0)
    
    fn init_constant_state(self, state: EnergyPlusDataTrait) -> None:
        pass
    
    fn init_state(self, state: EnergyPlusDataTrait) -> None:
        pass
    
    fn clear_state(inout self) -> None:
        self.vv = InlineArray[Float64, NMAX](fill=0.0)
