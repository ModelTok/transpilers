# EXTERNAL DEPS (to wire in glue):
# - TOKELVIN(T_celsius): converts Celsius to Kelvin
# - AIRDENSITY_CONSTEXPR(P, T, W): air density at reference conditions
# - Constant.Pi, Constant.PiOvr2: math constants
# - pow_2(x), pow_5(x): x^2, x^5
# - sign(a, b): returns |a| with sign of b
# - ShowFatalError(state, msg), ShowWarningError(state, msg), etc.: error reporting
# - state.afn->properties.density(P, T, W): compute air density
# - state.afn->AirflowNetworkCompData(), AirflowNetworkLinkageData(), etc.: lookup tables
# - state.dataLoopNodes->Node(i), state.dataAirLoop->AirLoopAFNInfo(), state.dataSurface->Surface(): node/zone/surface data
# - state.dataEnvrn->OutBaroPress, OutDryBulbTemp, OutHumRat, Latitude: environment
# - HVAC enums: VerySmallMassFlow, FanType, FanOp, PressureCtrlExhaust, PressureCtrlRelief
# - iComponentTypeNum enum: ELR, DOP

import math
from typing import List, Tuple, Optional
from dataclasses import dataclass

def square(x: float) -> float:
    return x * x

def pow_2(x: float) -> float:
    return x * x

def pow_5(x: float) -> float:
    return x * x * x * x * x

def sign(a: float, b: float) -> float:
    if b >= 0:
        return abs(a)
    else:
        return -abs(a)

def TOKELVIN(T_celsius: float) -> float:
    return T_celsius + 273.15

def AIRDENSITY_CONSTEXPR(P: float, T: float, W: float) -> float:
    pass

class AirState:
    def __init__(self):
        self.density: float = 0.0
        self.viscosity: float = 0.0
        self.temperature: float = 0.0
        self.humidity_ratio: float = 0.0
        self.sqrt_density: float = 0.0

class EnergyPlusData:
    pass

class Duct:
    def __init__(self):
        self.roughness: float = 0.0
        self.hydraulicDiameter: float = 0.0
        self.L: float = 0.0
        self.A: float = 0.0
        self.LamFriCoef: float = 0.0
        self.LamDynCoef: float = 0.0
        self.InitLamCoef: float = 0.0
        self.TurDynCoef: float = 0.0

    def calculate(self, state: EnergyPlusData, LFLAG: bool, PDROP: float, i: int, 
                  multiplier: float, control: float, propN: AirState, propM: AirState,
                  F: List[float], DF: List[float]) -> int:
        C = 0.868589
        EPS = 0.001
        
        ed = self.roughness / self.hydraulicDiameter
        ld = self.L / self.hydraulicDiameter
        g = 1.14 - 0.868589 * math.log(ed)
        AA1 = g
        
        if LFLAG:
            if PDROP >= 0.0:
                DF[0] = (2.0 * propN.density * self.A * self.hydraulicDiameter) / (propN.viscosity * self.InitLamCoef * ld)
            else:
                DF[0] = (2.0 * propM.density * self.A * self.hydraulicDiameter) / (propM.viscosity * self.InitLamCoef * ld)
            F[0] = -DF[0] * PDROP
        else:
            if PDROP >= 0.0:
                if self.LamFriCoef >= 0.001:
                    A2 = self.LamFriCoef / (2.0 * propN.density * self.A * self.A)
                    A1 = (propN.viscosity * self.LamDynCoef * ld) / (2.0 * propN.density * self.A * self.hydraulicDiameter)
                    A0 = -PDROP
                    CDM = math.sqrt(A1 * A1 - 4.0 * A2 * A0)
                    FL = (CDM - A1) / (2.0 * A2)
                    CDM = 1.0 / CDM
                else:
                    CDM = (2.0 * propN.density * self.A * self.hydraulicDiameter) / (propN.viscosity * self.LamDynCoef * ld)
                    FL = CDM * PDROP
                RE = FL * self.hydraulicDiameter / (propN.viscosity * self.A)
                if RE >= 10.0:
                    S2 = math.sqrt(2.0 * propN.density * PDROP) * self.A
                    FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                    while True:
                        FT = FTT
                        B = (9.3 * propN.viscosity * self.A) / (FT * self.roughness)
                        D = 1.0 + g * B
                        g -= (g - AA1 + C * math.log(D)) / (1.0 + C * B / D)
                        FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                        if abs(FTT - FT) / FTT < EPS:
                            break
                    FT = FTT
                else:
                    FT = FL
            else:
                if self.LamFriCoef >= 0.001:
                    A2 = self.LamFriCoef / (2.0 * propM.density * self.A * self.A)
                    A1 = (propM.viscosity * self.LamDynCoef * ld) / (2.0 * propM.density * self.A * self.hydraulicDiameter)
                    A0 = PDROP
                    CDM = math.sqrt(A1 * A1 - 4.0 * A2 * A0)
                    FL = -(CDM - A1) / (2.0 * A2)
                    CDM = 1.0 / CDM
                else:
                    CDM = (2.0 * propM.density * self.A * self.hydraulicDiameter) / (propM.viscosity * self.LamDynCoef * ld)
                    FL = CDM * PDROP
                RE = -FL * self.hydraulicDiameter / (propM.viscosity * self.A)
                if RE >= 10.0:
                    S2 = math.sqrt(-2.0 * propM.density * PDROP) * self.A
                    FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                    while True:
                        FT = FTT
                        B = (9.3 * propM.viscosity * self.A) / (FT * self.roughness)
                        D = 1.0 + g * B
                        g -= (g - AA1 + C * math.log(D)) / (1.0 + C * B / D)
                        FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                        if abs(FTT - FT) / FTT < EPS:
                            break
                    FT = -FTT
                else:
                    FT = FL
            
            if abs(FL) <= abs(FT):
                F[0] = FL
                DF[0] = CDM
            else:
                F[0] = FT
                DF[0] = 0.5 * FT / PDROP
        
        return 1

    def calculate_without_lflag(self, state: EnergyPlusData, PDROP: float, multiplier: float, 
                                control: float, propN: AirState, propM: AirState,
                                F: List[float], DF: List[float]) -> int:
        C = 0.868589
        EPS = 0.001
        
        ed = self.roughness / self.hydraulicDiameter
        ld = self.L / self.hydraulicDiameter
        g = 1.14 - 0.868589 * math.log(ed)
        AA1 = g
        
        if PDROP >= 0.0:
            if self.LamFriCoef >= 0.001:
                A2 = self.LamFriCoef / (2.0 * propN.density * self.A * self.A)
                A1 = (propN.viscosity * self.LamDynCoef * ld) / (2.0 * propN.density * self.A * self.hydraulicDiameter)
                A0 = -PDROP
                CDM = math.sqrt(A1 * A1 - 4.0 * A2 * A0)
                FL = (CDM - A1) / (2.0 * A2)
                CDM = 1.0 / CDM
            else:
                CDM = (2.0 * propN.density * self.A * self.hydraulicDiameter) / (propN.viscosity * self.LamDynCoef * ld)
                FL = CDM * PDROP
            RE = FL * self.hydraulicDiameter / (propN.viscosity * self.A)
            if RE >= 10.0:
                S2 = math.sqrt(2.0 * propN.density * PDROP) * self.A
                FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                while True:
                    FT = FTT
                    B = (9.3 * propN.viscosity * self.A) / (FT * self.roughness)
                    D = 1.0 + g * B
                    g -= (g - AA1 + C * math.log(D)) / (1.0 + C * B / D)
                    FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                    if abs(FTT - FT) / FTT < EPS:
                        break
                FT = FTT
            else:
                FT = FL
        else:
            if self.LamFriCoef >= 0.001:
                A2 = self.LamFriCoef / (2.0 * propM.density * self.A * self.A)
                A1 = (propM.viscosity * self.LamDynCoef * ld) / (2.0 * propM.density * self.A * self.hydraulicDiameter)
                A0 = PDROP
                CDM = math.sqrt(A1 * A1 - 4.0 * A2 * A0)
                FL = -(CDM - A1) / (2.0 * A2)
                CDM = 1.0 / CDM
            else:
                CDM = (2.0 * propM.density * self.A * self.hydraulicDiameter) / (propM.viscosity * self.LamDynCoef * ld)
                FL = CDM * PDROP
            RE = -FL * self.hydraulicDiameter / (propM.viscosity * self.A)
            if RE >= 10.0:
                S2 = math.sqrt(-2.0 * propM.density * PDROP) * self.A
                FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                while True:
                    FT = FTT
                    B = (9.3 * propM.viscosity * self.A) / (FT * self.roughness)
                    D = 1.0 + g * B
                    g -= (g - AA1 + C * math.log(D)) / (1.0 + C * B / D)
                    FTT = S2 / math.sqrt(ld / pow_2(g) + self.TurDynCoef)
                    if abs(FTT - FT) / FTT < EPS:
                        break
                FT = -FTT
            else:
                FT = FL
        
        if abs(FL) <= abs(FT):
            F[0] = FL
            DF[0] = CDM
        else:
            F[0] = FT
            DF[0] = 0.5 * FT / PDROP
        
        return 1

class SurfaceCrack:
    def __init__(self):
        self.coefficient: float = 0.0
        self.exponent: float = 0.0
        self.reference_density: float = 0.0
        self.reference_viscosity: float = 0.0

    def calculate(self, state: EnergyPlusData, linear: bool, pdrop: float, i: int,
                  multiplier: float, control: float, propN: AirState, propM: AirState,
                  F: List[float], DF: List[float]) -> int:
        VisAve = 0.5 * (propN.viscosity + propM.viscosity)
        Tave = 0.5 * (propN.temperature + propM.temperature)
        
        sign_val = 1.0
        upwind_temperature = propN.temperature
        upwind_density = propN.density
        upwind_viscosity = propN.viscosity
        upwind_sqrt_density = propN.sqrt_density
        abs_pdrop = pdrop
        
        if pdrop < 0.0:
            sign_val = -1.0
            upwind_temperature = propM.temperature
            upwind_density = propM.density
            upwind_viscosity = propM.viscosity
            upwind_sqrt_density = propM.sqrt_density
            abs_pdrop = -pdrop
        
        coef = self.coefficient * control * multiplier / upwind_sqrt_density
        
        RhoCor = TOKELVIN(upwind_temperature) / TOKELVIN(Tave)
        Ctl = pow(self.reference_density / upwind_density / RhoCor, self.exponent - 1.0) * \
              pow(self.reference_viscosity / VisAve, 2.0 * self.exponent - 1.0)
        CDM = coef * upwind_density / upwind_viscosity * Ctl
        FL = CDM * pdrop
        
        if linear:
            DF[0] = CDM
            F[0] = FL
        else:
            if self.exponent == 0.5:
                abs_FT = coef * upwind_sqrt_density * math.sqrt(abs_pdrop) * Ctl
            else:
                abs_FT = coef * upwind_sqrt_density * pow(abs_pdrop, self.exponent) * Ctl
            
            if abs(FL) <= abs_FT:
                F[0] = FL
                DF[0] = CDM
            else:
                F[0] = sign_val * abs_FT
                DF[0] = F[0] * self.exponent / pdrop
        
        return 1

    def calculate_without_linear(self, state: EnergyPlusData, pdrop: float, multiplier: float,
                                 control: float, propN: AirState, propM: AirState,
                                 F: List[float], DF: List[float]) -> int:
        VisAve = 0.5 * (propN.viscosity + propM.viscosity)
        Tave = 0.5 * (propN.temperature + propM.temperature)
        
        sign_val = 1.0
        upwind_temperature = propN.temperature
        upwind_density = propN.density
        upwind_viscosity = propN.viscosity
        upwind_sqrt_density = propN.sqrt_density
        abs_pdrop = pdrop
        
        if pdrop < 0.0:
            sign_val = -1.0
            upwind_temperature = propM.temperature
            upwind_density = propM.density
            upwind_viscosity = propM.viscosity
            upwind_sqrt_density = propM.sqrt_density
            abs_pdrop = -pdrop
        
        coef = self.coefficient * control * multiplier / upwind_sqrt_density
        
        RhoCor = TOKELVIN(upwind_temperature) / TOKELVIN(Tave)
        Ctl = pow(self.reference_density / upwind_density / RhoCor, self.exponent - 1.0) * \
              pow(self.reference_viscosity / VisAve, 2.0 * self.exponent - 1.0)
        CDM = coef * upwind_density / upwind_viscosity * Ctl
        FL = CDM * pdrop
        
        if self.exponent == 0.5:
            abs_FT = coef * upwind_sqrt_density * math.sqrt(abs_pdrop) * Ctl
        else:
            abs_FT = coef * upwind_sqrt_density * pow(abs_pdrop, self.exponent) * Ctl
        
        if abs(FL) <= abs_FT:
            F[0] = FL
            DF[0] = CDM
        else:
            F[0] = sign_val * abs_FT
            DF[0] = F[0] * self.exponent / pdrop
        
        return 1

def generic_crack(coefficient: float, exponent: float, linear: bool, pdrop: float,
                  propN: AirState, propM: AirState, F: List[float], DF: List[float]) -> None:
    reference_density = AIRDENSITY_CONSTEXPR(101325.0, 20.0, 0.0)
    reference_viscosity = 1.71432e-5 + 4.828e-8 * 20.0
    
    VisAve = 0.5 * (propN.viscosity + propM.viscosity)
    Tave = 0.5 * (propN.temperature + propM.temperature)
    
    sign_val = 1.0
    upwind_temperature = propN.temperature
    upwind_density = propN.density
    upwind_viscosity = propN.viscosity
    upwind_sqrt_density = propN.sqrt_density
    abs_pdrop = pdrop
    
    if pdrop < 0.0:
        sign_val = -1.0
        upwind_temperature = propM.temperature
        upwind_density = propM.density
        upwind_viscosity = propM.viscosity
        upwind_sqrt_density = propM.sqrt_density
        abs_pdrop = -pdrop
    
    coef = coefficient / upwind_sqrt_density
    
    RhoCor = TOKELVIN(upwind_temperature) / TOKELVIN(Tave)
    Ctl = pow(reference_density / upwind_density / RhoCor, exponent - 1.0) * \
          pow(reference_viscosity / VisAve, 2.0 * exponent - 1.0)
    CDM = coef * upwind_density / upwind_viscosity * Ctl
    FL = CDM * pdrop
    
    if linear:
        DF[0] = CDM
        F[0] = FL
    else:
        if exponent == 0.5:
            abs_FT = coef * upwind_sqrt_density * math.sqrt(abs_pdrop) * Ctl
        else:
            abs_FT = coef * upwind_sqrt_density * pow(abs_pdrop, exponent) * Ctl
        
        if abs(FL) <= abs_FT:
            F[0] = FL
            DF[0] = CDM
        else:
            F[0] = sign_val * abs_FT
            DF[0] = F[0] * exponent / pdrop
