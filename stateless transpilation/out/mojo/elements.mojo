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

from math import sqrt, log, pow, fabs, sin, cos, tan, exp, pi
alias Float64 = Float64
alias Int32 = Int32

fn square(x: Float64) -> Float64:
    return x * x

fn pow_2(x: Float64) -> Float64:
    return x * x

fn pow_5(x: Float64) -> Float64:
    return x * x * x * x * x

fn sign(a: Float64, b: Float64) -> Float64:
    if b >= 0:
        return fabs(a)
    else:
        return -fabs(a)

fn TOKELVIN(T_celsius: Float64) -> Float64:
    return T_celsius + 273.15

fn AIRDENSITY_CONSTEXPR(P: Float64, T: Float64, W: Float64) -> Float64:
    pass

struct AirState:
    var density: Float64
    var viscosity: Float64
    var temperature: Float64
    var humidity_ratio: Float64
    var sqrt_density: Float64
    
    fn __init__(inout self):
        self.density = 0.0
        self.viscosity = 0.0
        self.temperature = 0.0
        self.humidity_ratio = 0.0
        self.sqrt_density = 0.0

struct EnergyPlusData:
    pass

struct Duct:
    var roughness: Float64
    var hydraulicDiameter: Float64
    var L: Float64
    var A: Float64
    var LamFriCoef: Float64
    var LamDynCoef: Float64
    var InitLamCoef: Float64
    var TurDynCoef: Float64
    
    fn __init__(inout self):
        self.roughness = 0.0
        self.hydraulicDiameter = 0.0
        self.L = 0.0
        self.A = 0.0
        self.LamFriCoef = 0.0
        self.LamDynCoef = 0.0
        self.InitLamCoef = 0.0
        self.TurDynCoef = 0.0
    
    fn calculate(self, state: EnergyPlusData, LFLAG: Bool, PDROP: Float64, i: Int32,
                 multiplier: Float64, control: Float64, propN: AirState, propM: AirState,
                 inout F: InlineArray[Float64, 2], inout DF: InlineArray[Float64, 2]) -> Int32:
        let C: Float64 = 0.868589
        let EPS: Float64 = 0.001
        
        var ed: Float64 = self.roughness / self.hydraulicDiameter
        var ld: Float64 = self.L / self.hydraulicDiameter
        var g: Float64 = 1.14 - 0.868589 * log(ed)
        let AA1: Float64 = g
        
        if LFLAG:
            if PDROP >= 0.0:
                DF[0] = (2.0 * propN.density * self.A * self.hydraulicDiameter) / (propN.viscosity * self.InitLamCoef * ld)
            else:
                DF[0] = (2.0 * propM.density * self.A * self.hydraulicDiameter) / (propM.viscosity * self.InitLamCoef * ld)
            F[0] = -DF[0] * PDROP
        else:
            var FL: Float64
            var FT: Float64
            var CDM: Float64
            
            if PDROP >= 0.0:
                if self.LamFriCoef >= 0.001:
                    let A2: Float64 = self.LamFriCoef / (2.0 * propN.density * self.A * self.A)
                    let A1: Float64 = (propN.viscosity * self.LamDynCoef * ld) / (2.0 * propN.density * self.A * self.hydraulicDiameter)
                    let A0: Float64 = -PDROP
                    CDM = sqrt(A1 * A1 - 4.0 * A2 * A0)
                    FL = (CDM - A1) / (2.0 * A2)
                    CDM = 1.0 / CDM
                else:
                    CDM = (2.0 * propN.density * self.A * self.hydraulicDiameter) / (propN.viscosity * self.LamDynCoef * ld)
                    FL = CDM * PDROP
                
                let RE: Float64 = FL * self.hydraulicDiameter / (propN.viscosity * self.A)
                
                if RE >= 10.0:
                    let S2: Float64 = sqrt(2.0 * propN.density * PDROP) * self.A
                    var FTT: Float64 = S2 / sqrt(ld / pow_2(g) + self.TurDynCoef)
                    var g_local = g
                    while True:
                        FT = FTT
                        let B: Float64 = (9.3 * propN.viscosity * self.A) / (FT * self.roughness)
                        let D: Float64 = 1.0 + g_local * B
                        g_local -= (g_local - AA1 + C * log(D)) / (1.0 + C * B / D)
                        FTT = S2 / sqrt(ld / pow_2(g_local) + self.TurDynCoef)
                        if fabs(FTT - FT) / FTT < EPS:
                            break
                    FT = FTT
                else:
                    FT = FL
            else:
                if self.LamFriCoef >= 0.001:
                    let A2: Float64 = self.LamFriCoef / (2.0 * propM.density * self.A * self.A)
                    let A1: Float64 = (propM.viscosity * self.LamDynCoef * ld) / (2.0 * propM.density * self.A * self.hydraulicDiameter)
                    let A0: Float64 = PDROP
                    CDM = sqrt(A1 * A1 - 4.0 * A2 * A0)
                    FL = -(CDM - A1) / (2.0 * A2)
                    CDM = 1.0 / CDM
                else:
                    CDM = (2.0 * propM.density * self.A * self.hydraulicDiameter) / (propM.viscosity * self.LamDynCoef * ld)
                    FL = CDM * PDROP
                
                let RE: Float64 = -FL * self.hydraulicDiameter / (propM.viscosity * self.A)
                
                if RE >= 10.0:
                    let S2: Float64 = sqrt(-2.0 * propM.density * PDROP) * self.A
                    var FTT: Float64 = S2 / sqrt(ld / pow_2(g) + self.TurDynCoef)
                    var g_local = g
                    while True:
                        FT = FTT
                        let B: Float64 = (9.3 * propM.viscosity * self.A) / (FT * self.roughness)
                        let D: Float64 = 1.0 + g_local * B
                        g_local -= (g_local - AA1 + C * log(D)) / (1.0 + C * B / D)
                        FTT = S2 / sqrt(ld / pow_2(g_local) + self.TurDynCoef)
                        if fabs(FTT - FT) / FTT < EPS:
                            break
                    FT = -FTT
                else:
                    FT = FL
            
            if fabs(FL) <= fabs(FT):
                F[0] = FL
                DF[0] = CDM
            else:
                F[0] = FT
                DF[0] = 0.5 * FT / PDROP
        
        return 1

struct SurfaceCrack:
    var coefficient: Float64
    var exponent: Float64
    var reference_density: Float64
    var reference_viscosity: Float64
    
    fn __init__(inout self):
        self.coefficient = 0.0
        self.exponent = 0.0
        self.reference_density = 0.0
        self.reference_viscosity = 0.0
    
    fn calculate(self, state: EnergyPlusData, linear: Bool, pdrop: Float64, i: Int32,
                 multiplier: Float64, control: Float64, propN: AirState, propM: AirState,
                 inout F: InlineArray[Float64, 2], inout DF: InlineArray[Float64, 2]) -> Int32:
        let VisAve: Float64 = 0.5 * (propN.viscosity + propM.viscosity)
        let Tave: Float64 = 0.5 * (propN.temperature + propM.temperature)
        
        var sign_val: Float64 = 1.0
        var upwind_temperature: Float64 = propN.temperature
        var upwind_density: Float64 = propN.density
        var upwind_viscosity: Float64 = propN.viscosity
        var upwind_sqrt_density: Float64 = propN.sqrt_density
        var abs_pdrop: Float64 = pdrop
        
        if pdrop < 0.0:
            sign_val = -1.0
            upwind_temperature = propM.temperature
            upwind_density = propM.density
            upwind_viscosity = propM.viscosity
            upwind_sqrt_density = propM.sqrt_density
            abs_pdrop = -pdrop
        
        let coef: Float64 = self.coefficient * control * multiplier / upwind_sqrt_density
        
        let RhoCor: Float64 = TOKELVIN(upwind_temperature) / TOKELVIN(Tave)
        let Ctl: Float64 = pow(self.reference_density / upwind_density / RhoCor, self.exponent - 1.0) * \
                           pow(self.reference_viscosity / VisAve, 2.0 * self.exponent - 1.0)
        let CDM: Float64 = coef * upwind_density / upwind_viscosity * Ctl
        let FL: Float64 = CDM * pdrop
        
        if linear:
            DF[0] = CDM
            F[0] = FL
        else:
            var abs_FT: Float64
            if self.exponent == 0.5:
                abs_FT = coef * upwind_sqrt_density * sqrt(abs_pdrop) * Ctl
            else:
                abs_FT = coef * upwind_sqrt_density * pow(abs_pdrop, self.exponent) * Ctl
            
            if fabs(FL) <= abs_FT:
                F[0] = FL
                DF[0] = CDM
            else:
                F[0] = sign_val * abs_FT
                DF[0] = F[0] * self.exponent / pdrop
        
        return 1

fn generic_crack(coefficient: Float64, exponent: Float64, linear: Bool, pdrop: Float64,
                 propN: AirState, propM: AirState, inout F: InlineArray[Float64, 2],
                 inout DF: InlineArray[Float64, 2]) -> None:
    let reference_density: Float64 = AIRDENSITY_CONSTEXPR(101325.0, 20.0, 0.0)
    let reference_viscosity: Float64 = 1.71432e-5 + 4.828e-8 * 20.0
    
    let VisAve: Float64 = 0.5 * (propN.viscosity + propM.viscosity)
    let Tave: Float64 = 0.5 * (propN.temperature + propM.temperature)
    
    var sign_val: Float64 = 1.0
    var upwind_temperature: Float64 = propN.temperature
    var upwind_density: Float64 = propN.density
    var upwind_viscosity: Float64 = propN.viscosity
    var upwind_sqrt_density: Float64 = propN.sqrt_density
    var abs_pdrop: Float64 = pdrop
    
    if pdrop < 0.0:
        sign_val = -1.0
        upwind_temperature = propM.temperature
        upwind_density = propM.density
        upwind_viscosity = propM.viscosity
        upwind_sqrt_density = propM.sqrt_density
        abs_pdrop = -pdrop
    
    let coef: Float64 = coefficient / upwind_sqrt_density
    
    let RhoCor: Float64 = TOKELVIN(upwind_temperature) / TOKELVIN(Tave)
    let Ctl: Float64 = pow(reference_density / upwind_density / RhoCor, exponent - 1.0) * \
                       pow(reference_viscosity / VisAve, 2.0 * exponent - 1.0)
    let CDM: Float64 = coef * upwind_density / upwind_viscosity * Ctl
    let FL: Float64 = CDM * pdrop
    
    if linear:
        DF[0] = CDM
        F[0] = FL
    else:
        var abs_FT: Float64
        if exponent == 0.5:
            abs_FT = coef * upwind_sqrt_density * sqrt(abs_pdrop) * Ctl
        else:
            abs_FT = coef * upwind_sqrt_density * pow(abs_pdrop, exponent) * Ctl
        
        if fabs(FL) <= abs_FT:
            F[0] = FL
            DF[0] = CDM
        else:
            F[0] = sign_val * abs_FT
            DF[0] = F[0] * exponent / pdrop
