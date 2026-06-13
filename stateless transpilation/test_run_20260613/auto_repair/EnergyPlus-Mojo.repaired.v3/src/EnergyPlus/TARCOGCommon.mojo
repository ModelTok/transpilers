from ObjexxFCL import Array1D, Array2, Array2A, Array1D_int
from TARCOGParams import MMax, NMax, Constant, pow_2, pow_3, TARCOGLayerType
from .Data.EnergyPlusData import EnergyPlusData
from .Data.BaseData import BaseGlobalStruct

let Pi = Constant.Pi
let PiOvr2 = Constant.PiOvr2
let StefanBoltzmann = Constant.StefanBoltzmann

const NMAX: Int = 500

def IsShadingLayer(layertype: TARCOGLayerType) -> Bool:
    return (layertype == TARCOGLayerType.VENETBLIND_HORIZ) or \
           (layertype == TARCOGLayerType.VENETBLIND_VERT) or \
           (layertype == TARCOGLayerType.WOVSHADE) or \
           (layertype == TARCOGLayerType.PERFORATED) or \
           (layertype == TARCOGLayerType.BSDF) or \
           (layertype == TARCOGLayerType.DIFFSHADE)

struct TARCOGCommonData(BaseGlobalStruct):
    var vv: Array1D[Float64] = Array1D[Float64](NMAX)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.vv = Array1D[Float64](NMAX)

def LDSumMax(Width: Float64, Height: Float64) -> Float64:
    var LDSumMax: Float64
    LDSumMax = 0.0
    for i in range(1, MMax + 1, 2):
        let sin_i = sin(i * PiOvr2)
        let pow_i_W = pow_2(i / Width)
        for j in range(1, NMax + 1, 2):
            LDSumMax += (sin_i * sin(j * PiOvr2)) / (i * j * pow_2(pow_i_W + pow_2(j / Height)))
        # do j = 1, DeflectionParameters::NMax, 2
    # do i = 1, DeflectionParameters::MMax, 2
    return LDSumMax

def LDSumMean(Width: Float64, Height: Float64) -> Float64:
    var LDSumMean: Float64
    let Pi_squared: Float64 = Pi * Pi
    LDSumMean = 0.0
    for i in range(1, MMax + 1, 2):
        let pow_i_Pi_2 = i * i * Pi_squared
        let pow_i_W = pow_2(i / Width)
        for j in range(1, NMax + 1, 2):
            LDSumMean += 4.0 / (pow_i_Pi_2 * pow_2(j) * pow_2(pow_i_W + pow_2(j / Height)))
        # do j = 1, DeflectionParameters::NMax, 2
    # do i = 1, MMax, 2
    return LDSumMean

def modifyHcGap(
    borrowed hcgap: Array1D[Float64],
    borrowed qv: Array1D[Float64],
    borrowed hcv: Array1D[Float64],
    inout hcgapMod: Array1D[Float64],
    nlayer: Int,
    edgeGlCorFac: Float64,
):
    for i in range(1, nlayer + 2):
        if qv[i - 1] != 0.0:
            hcgapMod[i - 1] = 0.5 * hcv[i - 1]
        else:
            hcgapMod[i - 1] = hcgap[i - 1] * edgeGlCorFac

def matrixQBalance(
    nlayer: Int,
    inout a: Array2[Float64],
    inout b: Array1D[Float64],
    borrowed sconScaled: Array1D[Float64],
    borrowed hcgas: Array1D[Float64],
    inout hcgapMod: Array1D[Float64],
    borrowed asol: Array1D[Float64],
    borrowed qv: Array1D[Float64],
    borrowed hcv: Array1D[Float64],
    Tin: Float64,
    Tout: Float64,
    Gin: Float64,
    Gout: Float64,
    borrowed theta: Array1D[Float64],
    borrowed tir: Array1D[Float64],
    borrowed rir: Array1D[Float64],
    borrowed emis: Array1D[Float64],
    edgeGlCorrFac: Float64,
):
    var i: Int
    var j: Int
    var k: Int
    var front: Int
    var back: Int
    for i in range(1, 4 * nlayer + 1):
        b[i - 1] = 0.0
        for j in range(1, 4 * nlayer + 1):
            a[j - 1][i - 1] = 0.0

    modifyHcGap(hcgas, qv, hcv, hcgapMod, nlayer, edgeGlCorrFac)

    for i in range(1, nlayer + 1):
        k = 4 * i - 3
        front = 2 * i - 1
        back = 2 * i
        if i != 1:
            a[k - 2][k - 1] = -hcgapMod[i - 1]
            a[k - 3][k - 1] = tir[front - 1] - 1.0
        a[k - 1][k - 1] = hcgapMod[i - 1] + sconScaled[i - 1]
        a[k][k - 1] = 1.0
        a[k + 2][k - 1] = -sconScaled[i - 1]
        if i != nlayer:
            a[k + 4][k - 1] = -tir[back - 1]
        a[k - 1][k] = emis[front - 1] * StefanBoltzmann * pow_3(theta[front - 1])
        a[k][k] = -1.0
        if i != 1:
            a[k - 3][k] = rir[front - 1]
        if i != nlayer:
            a[k + 4][k] = tir[back - 1]
        a[k + 1][k + 1] = -1.0
        a[k + 2][k + 1] = emis[back - 1] * StefanBoltzmann * pow_3(theta[back - 1])
        if i != 1:
            a[k - 3][k + 1] = tir[front - 1]
        if i != nlayer:
            a[k + 4][k + 1] = rir[back - 1]
        a[k - 1][k + 2] = sconScaled[i - 1]
        a[k + 1][k + 2] = -1.0
        a[k + 2][k + 2] = -hcgapMod[i] - sconScaled[i - 1]
        if i != 1:
            a[k - 3][k + 2] = tir[front - 1]
        if i != nlayer:
            a[k + 3][k + 2] = hcgapMod[i]
            a[k + 4][k + 2] = 1.0 - tir[back - 1]

    for i in range(1, nlayer + 1):
        k = 4 * i - 3
        front = 2 * i - 1
        back = 2 * i
        let vent = i + 1
        b[k - 1] = 0.5 * asol[i - 1] + 0.5 * qv[vent - 2]
        b[k + 2] = -0.5 * asol[i - 1] - 0.5 * qv[vent - 1]
        if i == 1:
            b[k - 1] = b[k - 1] + hcgapMod[0] * Tout + Gout - tir[front - 1] * Gout
            b[k] = b[k] - rir[front - 1] * Gout
            b[k + 1] = b[k + 1] - tir[front - 1] * Gout
            b[k + 2] = b[k + 2] - tir[front - 1] * Gout
        if i == nlayer:
            b[k - 1] = b[k - 1] + tir[back - 1] * Gin
            b[k] = b[k] - tir[back - 1] * Gin
            b[k + 1] = b[k + 1] - rir[back - 1] * Gin
            b[k + 2] = b[k + 2] - Gin - hcgapMod[i] * Tin + tir[back - 1] * Gin

def EquationsSolver(
    inout state: EnergyPlusData,
    inout a: Array2[Float64],
    inout b: Array1D[Float64],
    n: Int,
    inout nperr: Int,
    inout ErrorMessage: String,
):
    var indx = Array1D_int(n)
    var d: Float64
    ludcmp(state, a, n, indx, d, nperr, ErrorMessage)
    if (nperr > 0) and (nperr <= 1000):
        return
    lubksb(a, n, indx, b)

def ludcmp(
    inout state: EnergyPlusData,
    inout a: Array2[Float64],
    n: Int,
    inout indx: Array1D_int,
    inout d: Float64,
    inout nperr: Int,
    inout ErrorMessage: String,
):
    let TINY: Float64 = 1.0e-20
    var i: Int
    var imax: Int
    var j: Int
    var k: Int
    var aamax: Float64
    var dum: Float64
    var sum: Float64
    d = 1.0
    for i in range(1, n + 1):
        aamax = 0.0
        for j in range(1, n + 1):
            if abs(a[j - 1][i - 1]) > aamax:
                aamax = abs(a[j - 1][i - 1])
        # j
        if aamax == 0.0:
            nperr = 13
            ErrorMessage = "Singular matrix in ludcmp."
            return
        state.dataTARCOGCommon.vv[i - 1] = 1.0 / aamax
    # i
    for j in range(1, n + 1):
        for i in range(1, j):
            sum = a[j - 1][i - 1]
            for k in range(1, i):
                sum -= a[k - 1][i - 1] * a[j - 1][k - 1]
            # k
            a[j - 1][i - 1] = sum
        # i
        aamax = 0.0
        for i in range(j, n + 1):
            sum = a[j - 1][i - 1]
            for k in range(1, j):
                sum -= a[k - 1][i - 1] * a[j - 1][k - 1]
            # k
            a[j - 1][i - 1] = sum
            dum = state.dataTARCOGCommon.vv[i - 1] * abs(sum)
            if dum >= aamax:
                imax = i
                aamax = dum
        # i
        if j != imax:
            for k in range(1, n + 1):
                dum = a[k - 1][imax - 1]
                a[k - 1][imax - 1] = a[k - 1][j - 1]
                a[k - 1][j - 1] = dum
            # k
            d = -d
            state.dataTARCOGCommon.vv[imax - 1] = state.dataTARCOGCommon.vv[j - 1]
        indx[j - 1] = imax
        if a[j - 1][j - 1] == 0.0:
            a[j - 1][j - 1] = TINY
        if j != n:
            dum = 1.0 / a[j - 1][j - 1]
            for i in range(j + 1, n + 1):
                a[j - 1][i - 1] *= dum
            # i
    # j

def lubksb(
    a: Array2A[Float64],
    n: Int,
    borrowed indx: Array1D_int,
    inout b: Array1D[Float64],
):
    a.dim(n, n)
    # EP_SIZE_CHECK(indx, n)
    # EP_SIZE_CHECK(b, n)
    var i: Int
    var ii: Int
    var j: Int
    var sum: Float64
    ii = 0
    for i in range(1, n + 1):
        let ll = indx[i - 1]
        sum = b[ll - 1]
        b[ll - 1] = b[i - 1]
        if ii != 0:
            for j in range(ii, i):
                sum -= a[j - 1][i - 1] * b[j - 1]
            # j
        elif sum != 0.0:
            ii = i
        b[i - 1] = sum
    # i
    for i in range(n, 0, -1):
        sum = b[i - 1]
        for j in range(i + 1, n + 1):
            sum -= a[j - 1][i - 1] * b[j - 1]
        # j
        b[i - 1] = sum / a[i - 1][i - 1]
    # i

def pos(x: Float64) -> Float64:
    return (x + abs(x)) / 2.0