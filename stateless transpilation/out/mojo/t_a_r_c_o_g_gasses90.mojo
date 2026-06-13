from math import sqrt, pi
from dataclasses import dataclass

alias Stdrd = UInt8
alias ISO15099: Stdrd = 0
alias EN673: Stdrd = 1
alias EN673Design: Stdrd = 2

struct TARCOGGasses90Data:
    var fvis: DynamicVector[Float64]
    var fcon: DynamicVector[Float64]
    var fdens: DynamicVector[Float64]
    var fcp: DynamicVector[Float64]
    var kprime: DynamicVector[Float64]
    var kdblprm: DynamicVector[Float64]
    var mukpdwn: DynamicVector[Float64]
    var kpdown: DynamicVector[Float64]
    var kdpdown: DynamicVector[Float64]
    
    fn __init__(inout self, max_gas: Int):
        self.fvis = DynamicVector[Float64](max_gas)
        self.fcon = DynamicVector[Float64](max_gas)
        self.fdens = DynamicVector[Float64](max_gas)
        self.fcp = DynamicVector[Float64](max_gas)
        self.kprime = DynamicVector[Float64](max_gas)
        self.kdblprm = DynamicVector[Float64](max_gas)
        self.mukpdwn = DynamicVector[Float64](max_gas)
        self.kpdown = DynamicVector[Float64](max_gas)
        self.kdpdown = DynamicVector[Float64](max_gas)
        
        for i in range(max_gas):
            self.fvis[i] = 0.0
            self.fcon[i] = 0.0
            self.fdens[i] = 0.0
            self.fcp[i] = 0.0
            self.kprime[i] = 0.0
            self.kdblprm[i] = 0.0
            self.mukpdwn[i] = 0.0
            self.kpdown[i] = 0.0
            self.kdpdown[i] = 0.0
    
    fn clear_state(inout self):
        for i in range(len(self.fvis)):
            self.fvis[i] = 0.0
            self.fcon[i] = 0.0
            self.fdens[i] = 0.0
            self.fcp[i] = 0.0
            self.kprime[i] = 0.0
            self.kdblprm[i] = 0.0
            self.mukpdwn[i] = 0.0
            self.kpdown[i] = 0.0
            self.kdpdown[i] = 0.0

struct EnergyPlusData:
    var dataTARCOGGasses90: TARCOGGasses90Data
    
    fn __init__(inout self, max_gas: Int):
        self.dataTARCOGGasses90 = TARCOGGasses90Data(max_gas)

struct GASSES90Result:
    var con: Float64
    var visc: Float64
    var dens: Float64
    var cp: Float64
    var pr: Float64
    var nperr: Int32
    var error_message: String

struct GassesLowResult:
    var cond: Float64
    var nperr: Int32
    var error_message: String

fn pow_4_root(x: Float64) -> Float64:
    return pow(x, 0.25)

fn GASSES90(
    inout state: EnergyPlusData,
    tmean: Float64,
    iprop: DynamicVector[Int32],
    frct: DynamicVector[Float64],
    pres: Float64,
    nmix: Int32,
    xwght: DynamicVector[Float64],
    xgcon: DynamicVector[DynamicVector[Float64]],
    xgvis: DynamicVector[DynamicVector[Float64]],
    xgcp: DynamicVector[DynamicVector[Float64]],
    standard: Stdrd,
    universal_gas_const: Float64 = 8314.51
) -> GASSES90Result:
    
    let two_sqrt_2 = 2.0 * sqrt(2.0)
    let ENpressure = 1.0e5
    let gaslaw = 8314.51
    let UniversalGasConst = universal_gas_const
    
    let tmean_2 = tmean * tmean
    
    state.dataTARCOGGasses90.fcon[0] = (xgcon[0][iprop[0] - 1] +
                                        xgcon[1][iprop[0] - 1] * tmean +
                                        xgcon[2][iprop[0] - 1] * tmean_2)
    state.dataTARCOGGasses90.fvis[0] = (xgvis[0][iprop[0] - 1] +
                                        xgvis[1][iprop[0] - 1] * tmean +
                                        xgvis[2][iprop[0] - 1] * tmean_2)
    state.dataTARCOGGasses90.fcp[0] = (xgcp[0][iprop[0] - 1] +
                                       xgcp[1][iprop[0] - 1] * tmean +
                                       xgcp[2][iprop[0] - 1] * tmean_2)
    state.dataTARCOGGasses90.fdens[0] = pres * xwght[iprop[0] - 1] / (UniversalGasConst * tmean)
    
    if standard == EN673 or standard == EN673Design:
        state.dataTARCOGGasses90.fdens[0] = ENpressure * xwght[iprop[0] - 1] / (gaslaw * tmean)
    
    var visc: Float64
    var con: Float64
    var cp: Float64
    var dens: Float64
    
    if frct[0] == 1.0:
        visc = state.dataTARCOGGasses90.fvis[0]
        con = state.dataTARCOGGasses90.fcon[0]
        cp = state.dataTARCOGGasses90.fcp[0]
        dens = state.dataTARCOGGasses90.fdens[0]
    else:
        let stdISO15099 = (standard == ISO15099)
        let stdEN673 = (standard == EN673 or standard == EN673Design)
        
        var molmix: Float64 = 0.0
        var cpmixm: Float64 = 0.0
        
        if stdISO15099:
            molmix = frct[0] * xwght[iprop[0] - 1]
            cpmixm = molmix * state.dataTARCOGGasses90.fcp[0]
            state.dataTARCOGGasses90.kprime[0] = (3.75 * UniversalGasConst / xwght[iprop[0] - 1] *
                                                   state.dataTARCOGGasses90.fvis[0])
            state.dataTARCOGGasses90.kdblprm[0] = (state.dataTARCOGGasses90.fcon[0] -
                                                    state.dataTARCOGGasses90.kprime[0])
            state.dataTARCOGGasses90.mukpdwn[0] = 1.0
            state.dataTARCOGGasses90.kpdown[0] = 1.0
            state.dataTARCOGGasses90.kdpdown[0] = 1.0
        
        for i in range(1, int(nmix)):
            if frct[i] == 0.0:
                return GASSES90Result(
                    con=0.0, visc=0.0, dens=0.0, cp=0.0, pr=0.0,
                    nperr=2011, error_message="Component fraction in mixture is 0%"
                )
            
            state.dataTARCOGGasses90.fcon[i] = (xgcon[0][iprop[i] - 1] +
                                                xgcon[1][iprop[i] - 1] * tmean +
                                                xgcon[2][iprop[i] - 1] * tmean_2)
            state.dataTARCOGGasses90.fvis[i] = (xgvis[0][iprop[i] - 1] +
                                                xgvis[1][iprop[i] - 1] * tmean +
                                                xgvis[2][iprop[i] - 1] * tmean_2)
            state.dataTARCOGGasses90.fcp[i] = (xgcp[0][iprop[i] - 1] +
                                               xgcp[1][iprop[i] - 1] * tmean +
                                               xgcp[2][iprop[i] - 1] * tmean_2)
            
            if stdEN673:
                state.dataTARCOGGasses90.fdens[i] = ENpressure * xwght[iprop[i] - 1] / (gaslaw * tmean)
            
            if stdISO15099:
                molmix += frct[i] * xwght[iprop[i] - 1]
                cpmixm += frct[i] * state.dataTARCOGGasses90.fcp[i] * xwght[iprop[i] - 1]
                state.dataTARCOGGasses90.kprime[i] = (3.75 * UniversalGasConst / xwght[iprop[i] - 1] *
                                                       state.dataTARCOGGasses90.fvis[i])
                state.dataTARCOGGasses90.kdblprm[i] = (state.dataTARCOGGasses90.fcon[i] -
                                                        state.dataTARCOGGasses90.kprime[i])
                state.dataTARCOGGasses90.mukpdwn[i] = 1.0
                state.dataTARCOGGasses90.kpdown[i] = 1.0
                state.dataTARCOGGasses90.kdpdown[i] = 1.0
        
        if stdISO15099:
            var mumix: Float64 = 0.0
            var kpmix: Float64 = 0.0
            var kdpmix: Float64 = 0.0
            
            for i in range(int(nmix)):
                let kprime_i = state.dataTARCOGGasses90.kprime[i]
                let xwght_i = xwght[iprop[i] - 1]
                
                for j in range(int(nmix)):
                    let xwght_j = xwght[iprop[j] - 1]
                    
                    let x_pow = pow_4_root(xwght_j / xwght_i)
                    let phimup = (1.0 + sqrt(state.dataTARCOGGasses90.fvis[i] /
                                             state.dataTARCOGGasses90.fvis[j]) * x_pow) ** 2
                    
                    let downer = two_sqrt_2 * sqrt(1.0 + (xwght_i / xwght_j))
                    
                    if i != j:
                        state.dataTARCOGGasses90.mukpdwn[i] += phimup / downer * frct[j] / frct[i]
                    
                    let psiup = (1.0 + sqrt(kprime_i / state.dataTARCOGGasses90.kprime[j]) / x_pow) ** 2
                    
                    let psiterm = (1.0 + 2.41 * (xwght_i - xwght_j) *
                                  (xwght_i - 0.142 * xwght_j) / ((xwght_i + xwght_j) ** 2))
                    
                    if i != j:
                        state.dataTARCOGGasses90.kpdown[i] += psiup * psiterm / downer * frct[j] / frct[i]
                    
                    let phikup = psiup
                    
                    if i != j:
                        state.dataTARCOGGasses90.kdpdown[i] += phikup / downer * frct[j] / frct[i]
                
                mumix += state.dataTARCOGGasses90.fvis[i] / state.dataTARCOGGasses90.mukpdwn[i]
                kpmix += state.dataTARCOGGasses90.kprime[i] / state.dataTARCOGGasses90.kpdown[i]
                kdpmix += state.dataTARCOGGasses90.kdblprm[i] / state.dataTARCOGGasses90.kdpdown[i]
            
            let rhomix = pres * molmix / (UniversalGasConst * tmean)
            let kmix = kpmix + kdpmix
            
            visc = mumix
            con = kmix
            dens = rhomix
            if molmix > 0:
                cp = cpmixm / molmix
            else:
                cp = 0.0
        
        elif stdEN673:
            con = 0.0
            visc = 0.0
            dens = 0.0
            cp = 0.0
            
            for i in range(int(nmix)):
                let frct_i = frct[i]
                con += state.dataTARCOGGasses90.fcon[i] * frct_i
                visc += state.dataTARCOGGasses90.fvis[i] * frct_i
                dens += state.dataTARCOGGasses90.fdens[i] * frct_i
                cp += state.dataTARCOGGasses90.fcp[i] * frct_i
        else:
            return GASSES90Result(
                con=0.0, visc=0.0, dens=0.0, cp=0.0, pr=0.0,
                nperr=1, error_message="Unsupported standard"
            )
    
    let pr = if con != 0.0 then cp * visc / con else 0.0
    
    return GASSES90Result(
        con=con, visc=visc, dens=dens, cp=cp, pr=pr,
        nperr=0, error_message=""
    )

fn GassesLow(
    tmean: Float64,
    mwght: Float64,
    pressure: Float64,
    gama: Float64,
    alpha1: Float64,
    alpha2: Float64,
    universal_gas_const: Float64 = 8314.51
) -> GassesLowResult:
    
    let UniversalGasConst = universal_gas_const
    let Pi = pi
    
    let alpha = alpha1 * alpha2 / (alpha2 + alpha1 * (1.0 - alpha2))
    
    if gama == 1.0:
        return GassesLowResult(
            cond=0.0,
            nperr=40,
            error_message="Supplied gamma coefficient is incorrect."
        )
    
    let B = alpha * (gama + 1.0) / (gama - 1.0) * sqrt(UniversalGasConst / (8.0 * Pi * mwght * tmean))
    
    let cond = B * pressure
    
    return GassesLowResult(
        cond=cond,
        nperr=0,
        error_message=""
    )
