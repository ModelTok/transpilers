from TARCOGGassesParams import *
from TARCOGParams import *
from .Data.EnergyPlusData import EnergyPlusData
from DataGlobals import Constant
from Array1D import Array1D
from Array2D import Array2D
from Array2A import Array2A
from BaseGlobalStruct import BaseGlobalStruct
from math import sqrt, pow
from sys import exit

def pow_2(x: Float64) -> Float64:
    return x * x

def root_4(x: Float64) -> Float64:
    return sqrt(sqrt(x))

struct TARCOGGasses90Data(BaseGlobalStruct):
    var fvis: Array1D[Float64]
    var fcon: Array1D[Float64]
    var fdens: Array1D[Float64]
    var fcp: Array1D[Float64]
    var kprime: Array1D[Float64]
    var kdblprm: Array1D[Float64]
    var mukpdwn: Array1D[Float64]
    var kpdown: Array1D[Float64]
    var kdpdown: Array1D[Float64]

    def __init__(inout self):
        self.fvis = Array1D[Float64](maxgas)
        self.fcon = Array1D[Float64](maxgas)
        self.fdens = Array1D[Float64](maxgas)
        self.fcp = Array1D[Float64](maxgas)
        self.kprime = Array1D[Float64](maxgas)
        self.kdblprm = Array1D[Float64](maxgas)
        self.mukpdwn = Array1D[Float64](maxgas)
        self.kpdown = Array1D[Float64](maxgas)
        self.kdpdown = Array1D[Float64](maxgas)

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.fvis = Array1D[Float64](maxgas)
        self.fcon = Array1D[Float64](maxgas)
        self.fdens = Array1D[Float64](maxgas)
        self.fcp = Array1D[Float64](maxgas)
        self.kprime = Array1D[Float64](maxgas)
        self.kdblprm = Array1D[Float64](maxgas)
        self.mukpdwn = Array1D[Float64](maxgas)
        self.kpdown = Array1D[Float64](maxgas)
        self.kdpdown = Array1D[Float64](maxgas)

def GASSES90(inout state: EnergyPlusData,
              tmean: Float64,
              iprop: Array1D[Int32],
              frct: Array1D[Float64],
              pres: Float64,
              nmix: Int32,
              xwght: Array1D[Float64],
              xgcon: Array2D[Float64],
              xgvis: Array2D[Float64],
              xgcp: Array2D[Float64],
              inout con: Float64,
              inout visc: Float64,
              inout dens: Float64,
              inout cp: Float64,
              inout pr: Float64,
              standard: Stdrd,
              inout nperr: Int32,
              inout ErrorMessage: String):
    var two_sqrt_2: Float64 = 2.0 * sqrt(2.0)
    var molmix: Float64
    var cpmixm: Float64
    var phimup: Float64
    var downer: Float64
    var psiup: Float64
    var psiterm: Float64
    var phikup: Float64
    var ENpressure: Float64 = 1.0e5
    var gaslaw: Float64 = 8314.51
    var tmean_2: Float64 = pow_2(tmean)
    state.dataTARCOGGasses90.fcon[0] = xgcon[0, iprop[0] - 1] + xgcon[1, iprop[0] - 1] * tmean + xgcon[2, iprop[0] - 1] * tmean_2
    state.dataTARCOGGasses90.fvis[0] = xgvis[0, iprop[0] - 1] + xgvis[1, iprop[0] - 1] * tmean + xgvis[2, iprop[0] - 1] * tmean_2
    state.dataTARCOGGasses90.fcp[0] = xgcp[0, iprop[0] - 1] + xgcp[1, iprop[0] - 1] * tmean + xgcp[2, iprop[0] - 1] * tmean_2
    state.dataTARCOGGasses90.fdens[0] = pres * xwght[iprop[0] - 1] / (Constant.UniversalGasConst * tmean)
    if (standard == Stdrd.EN673) or (standard == Stdrd.EN673Design):
        state.dataTARCOGGasses90.fdens[0] = ENpressure * xwght[iprop[0] - 1] / (gaslaw * tmean)
    if frct[0] == 1.0:
        visc = state.dataTARCOGGasses90.fvis[0]
        con = state.dataTARCOGGasses90.fcon[0]
        cp = state.dataTARCOGGasses90.fcp[0]
        dens = state.dataTARCOGGasses90.fdens[0]
    else:
        var stdISO15099: Bool = standard == Stdrd.ISO15099
        var stdEN673: Bool = (standard == Stdrd.EN673) or (standard == Stdrd.EN673Design)
        if stdISO15099:
            molmix = frct[0] * xwght[iprop[0] - 1]
            cpmixm = molmix * state.dataTARCOGGasses90.fcp[0]
            state.dataTARCOGGasses90.kprime[0] = 3.75 * Constant.UniversalGasConst / xwght[iprop[0] - 1] * state.dataTARCOGGasses90.fvis[0]
            state.dataTARCOGGasses90.kdblprm[0] = state.dataTARCOGGasses90.fcon[0] - state.dataTARCOGGasses90.kprime[0]
            state.dataTARCOGGasses90.mukpdwn[0] = 1.0
            state.dataTARCOGGasses90.kpdown[0] = 1.0
            state.dataTARCOGGasses90.kdpdown[0] = 1.0
        for i in range(2, nmix + 1):
            if frct[i - 1] == 0.0:
                nperr = 2011
                ErrorMessage = "Component fraction in mixture is 0%"
                return
            state.dataTARCOGGasses90.fcon[i - 1] = xgcon[0, iprop[i - 1] - 1] + xgcon[1, iprop[i - 1] - 1] * tmean + xgcon[2, iprop[i - 1] - 1] * tmean_2
            state.dataTARCOGGasses90.fvis[i - 1] = xgvis[0, iprop[i - 1] - 1] + xgvis[1, iprop[i - 1] - 1] * tmean + xgvis[2, iprop[i - 1] - 1] * tmean_2
            state.dataTARCOGGasses90.fcp[i - 1] = xgcp[0, iprop[i - 1] - 1] + xgcp[1, iprop[i - 1] - 1] * tmean + xgcp[2, iprop[i - 1] - 1] * tmean_2
            if stdEN673:
                state.dataTARCOGGasses90.fdens[i - 1] = ENpressure * xwght[iprop[i - 1] - 1] / (gaslaw * tmean)
            if stdISO15099:
                molmix += frct[i - 1] * xwght[iprop[i - 1] - 1]
                cpmixm += frct[i - 1] * state.dataTARCOGGasses90.fcp[i - 1] * xwght[iprop[i - 1] - 1]
                state.dataTARCOGGasses90.kprime[i - 1] = 3.75 * Constant.UniversalGasConst / xwght[iprop[i - 1] - 1] * state.dataTARCOGGasses90.fvis[i - 1]
                state.dataTARCOGGasses90.kdblprm[i - 1] = state.dataTARCOGGasses90.fcon[i - 1] - state.dataTARCOGGasses90.kprime[i - 1]
                state.dataTARCOGGasses90.mukpdwn[i - 1] = 1.0
                state.dataTARCOGGasses90.kpdown[i - 1] = 1.0
                state.dataTARCOGGasses90.kdpdown[i - 1] = 1.0
        if stdISO15099:
            var mumix: Float64 = 0.0
            var kpmix: Float64 = 0.0
            var kdpmix: Float64 = 0.0
            for i in range(1, nmix + 1):
                var kprime_i: Float64 = state.dataTARCOGGasses90.kprime[i - 1]
                var xwght_i: Float64 = xwght[iprop[i - 1] - 1]
                for j in range(1, nmix + 1):
                    var xwght_j: Float64 = xwght[iprop[j - 1] - 1]
                    var x_pow: Float64 = root_4(xwght_j / xwght_i)
                    phimup = pow_2(1.0 + sqrt(state.dataTARCOGGasses90.fvis[i - 1] / state.dataTARCOGGasses90.fvis[j - 1]) * x_pow)
                    downer = two_sqrt_2 * sqrt(1.0 + (xwght_i / xwght_j))
                    if i != j:
                        state.dataTARCOGGasses90.mukpdwn[i - 1] += phimup / downer * frct[j - 1] / frct[i - 1]
                    psiup = pow_2(1.0 + sqrt(kprime_i / state.dataTARCOGGasses90.kprime[j - 1]) / x_pow)
                    psiterm = 1.0 + 2.41 * (xwght_i - xwght_j) * (xwght_i - 0.142 * xwght_j) / pow_2(xwght_i + xwght_j)
                    if i != j:
                        state.dataTARCOGGasses90.kpdown[i - 1] += psiup * psiterm / downer * frct[j - 1] / frct[i - 1]
                    phikup = psiup
                    if i != j:
                        state.dataTARCOGGasses90.kdpdown[i - 1] += phikup / downer * frct[j - 1] / frct[i - 1]
                mumix += state.dataTARCOGGasses90.fvis[i - 1] / state.dataTARCOGGasses90.mukpdwn[i - 1]
                kpmix += state.dataTARCOGGasses90.kprime[i - 1] / state.dataTARCOGGasses90.kpdown[i - 1]
                kdpmix += state.dataTARCOGGasses90.kdblprm[i - 1] / state.dataTARCOGGasses90.kdpdown[i - 1]
            var rhomix: Float64 = pres * molmix / (Constant.UniversalGasConst * tmean)
            var kmix: Float64 = kpmix + kdpmix
            visc = mumix
            con = kmix
            dens = rhomix
            if molmix > 0:
                cp = cpmixm / molmix
            else:
                cp = 0
        elif stdEN673:
            con = 0.0
            visc = 0.0
            dens = 0.0
            cp = 0.0
            for i in range(1, nmix + 1):
                var frct_i: Float64 = frct[i - 1]
                con += state.dataTARCOGGasses90.fcon[i - 1] * frct_i
                visc += state.dataTARCOGGasses90.fvis[i - 1] * frct_i
                dens += state.dataTARCOGGasses90.fdens[i - 1] * frct_i
                cp += state.dataTARCOGGasses90.fcp[i - 1] * frct_i
        else:
            exit(1)
    pr = cp * visc / con

def GassesLow(tmean: Float64, mwght: Float64, pressure: Float64, gama: Float64, inout cond: Float64, inout nperr: Int32, inout ErrorMessage: String):
    var alpha: Float64 = alpha1 * alpha2 / (alpha2 + alpha1 * (1 - alpha2))
    if gama == 1:
        nperr = 40
        ErrorMessage = "Supplied gamma coefficient is incorrect."
        return
    var B: Float64 = alpha * (gama + 1) / (gama - 1) * sqrt(Constant.UniversalGasConst / (8 * Constant.Pi * mwght * tmean))
    cond = B * pressure