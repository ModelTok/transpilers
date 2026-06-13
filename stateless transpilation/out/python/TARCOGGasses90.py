import math
from dataclasses import dataclass, field
from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# - TARCOGGassesParams.maxgas: int = 20
# - TARCOGGassesParams.Stdrd: class with ISO15099, EN673, EN673Design
# - TARCOGGassesParams.alpha1: float
# - TARCOGGassesParams.alpha2: float
# - Constant.UniversalGasConst: float = 8314.51

class Stdrd:
    ISO15099 = 0
    EN673 = 1
    EN673Design = 2

@dataclass
class TARCOGGasses90Data:
    max_gas: int = 20
    fvis: list = field(default_factory=list)
    fcon: list = field(default_factory=list)
    fdens: list = field(default_factory=list)
    fcp: list = field(default_factory=list)
    kprime: list = field(default_factory=list)
    kdblprm: list = field(default_factory=list)
    mukpdwn: list = field(default_factory=list)
    kpdown: list = field(default_factory=list)
    kdpdown: list = field(default_factory=list)
    
    def __post_init__(self):
        self.fvis = [0.0] * self.max_gas
        self.fcon = [0.0] * self.max_gas
        self.fdens = [0.0] * self.max_gas
        self.fcp = [0.0] * self.max_gas
        self.kprime = [0.0] * self.max_gas
        self.kdblprm = [0.0] * self.max_gas
        self.mukpdwn = [0.0] * self.max_gas
        self.kpdown = [0.0] * self.max_gas
        self.kdpdown = [0.0] * self.max_gas
    
    def clear_state(self):
        self.__post_init__()

@dataclass
class EnergyPlusData:
    dataTARCOGGasses90: TARCOGGasses90Data = field(default_factory=TARCOGGasses90Data)

@dataclass
class GASSES90Result:
    con: float
    visc: float
    dens: float
    cp: float
    pr: float
    nperr: int
    error_message: str

@dataclass
class GassesLowResult:
    cond: float
    nperr: int
    error_message: str

def GASSES90(
    state: EnergyPlusData,
    tmean: float,
    iprop: list,
    frct: list,
    pres: float,
    nmix: int,
    xwght: list,
    xgcon: list,
    xgvis: list,
    xgcp: list,
    standard: int,
    universal_gas_const: float = 8314.51
) -> GASSES90Result:
    
    two_sqrt_2 = 2.0 * math.sqrt(2.0)
    
    ENpressure = 1.0e5
    gaslaw = 8314.51
    UniversalGasConst = universal_gas_const
    
    tmean_2 = tmean * tmean
    
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
    
    if standard == Stdrd.EN673 or standard == Stdrd.EN673Design:
        state.dataTARCOGGasses90.fdens[0] = ENpressure * xwght[iprop[0] - 1] / (gaslaw * tmean)
    
    if frct[0] == 1.0:
        visc = state.dataTARCOGGasses90.fvis[0]
        con = state.dataTARCOGGasses90.fcon[0]
        cp = state.dataTARCOGGasses90.fcp[0]
        dens = state.dataTARCOGGasses90.fdens[0]
    else:
        stdISO15099 = (standard == Stdrd.ISO15099)
        stdEN673 = (standard == Stdrd.EN673 or standard == Stdrd.EN673Design)
        
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
        
        for i in range(1, nmix):
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
            mumix = 0.0
            kpmix = 0.0
            kdpmix = 0.0
            
            for i in range(nmix):
                kprime_i = state.dataTARCOGGasses90.kprime[i]
                xwght_i = xwght[iprop[i] - 1]
                
                for j in range(nmix):
                    xwght_j = xwght[iprop[j] - 1]
                    
                    x_pow = (xwght_j / xwght_i) ** 0.25
                    phimup = (1.0 + math.sqrt(state.dataTARCOGGasses90.fvis[i] /
                                              state.dataTARCOGGasses90.fvis[j]) * x_pow) ** 2
                    
                    downer = two_sqrt_2 * math.sqrt(1.0 + (xwght_i / xwght_j))
                    
                    if i != j:
                        state.dataTARCOGGasses90.mukpdwn[i] += phimup / downer * frct[j] / frct[i]
                    
                    psiup = (1.0 + math.sqrt(kprime_i / state.dataTARCOGGasses90.kprime[j]) / x_pow) ** 2
                    
                    psiterm = (1.0 + 2.41 * (xwght_i - xwght_j) *
                              (xwght_i - 0.142 * xwght_j) / ((xwght_i + xwght_j) ** 2))
                    
                    if i != j:
                        state.dataTARCOGGasses90.kpdown[i] += psiup * psiterm / downer * frct[j] / frct[i]
                    
                    phikup = psiup
                    
                    if i != j:
                        state.dataTARCOGGasses90.kdpdown[i] += phikup / downer * frct[j] / frct[i]
                
                mumix += state.dataTARCOGGasses90.fvis[i] / state.dataTARCOGGasses90.mukpdwn[i]
                kpmix += state.dataTARCOGGasses90.kprime[i] / state.dataTARCOGGasses90.kpdown[i]
                kdpmix += state.dataTARCOGGasses90.kdblprm[i] / state.dataTARCOGGasses90.kdpdown[i]
            
            rhomix = pres * molmix / (UniversalGasConst * tmean)
            kmix = kpmix + kdpmix
            
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
            
            for i in range(nmix):
                frct_i = frct[i]
                con += state.dataTARCOGGasses90.fcon[i] * frct_i
                visc += state.dataTARCOGGasses90.fvis[i] * frct_i
                dens += state.dataTARCOGGasses90.fdens[i] * frct_i
                cp += state.dataTARCOGGasses90.fcp[i] * frct_i
        else:
            return GASSES90Result(
                con=0.0, visc=0.0, dens=0.0, cp=0.0, pr=0.0,
                nperr=1, error_message="Unsupported standard"
            )
    
    pr = cp * visc / con if con != 0 else 0.0
    
    return GASSES90Result(
        con=con, visc=visc, dens=dens, cp=cp, pr=pr,
        nperr=0, error_message=""
    )

def GassesLow(
    tmean: float,
    mwght: float,
    pressure: float,
    gama: float,
    alpha1: float,
    alpha2: float,
    universal_gas_const: float = 8314.51
) -> GassesLowResult:
    
    UniversalGasConst = universal_gas_const
    Pi = math.pi
    
    alpha = alpha1 * alpha2 / (alpha2 + alpha1 * (1.0 - alpha2))
    
    if gama == 1.0:
        return GassesLowResult(
            cond=0.0,
            nperr=40,
            error_message="Supplied gamma coefficient is incorrect."
        )
    
    B = alpha * (gama + 1.0) / (gama - 1.0) * math.sqrt(UniversalGasConst / (8.0 * Pi * mwght * tmean))
    
    cond = B * pressure
    
    return GassesLowResult(
        cond=cond,
        nperr=0,
        error_message=""
    )
