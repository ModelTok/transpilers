from math import (
    cos, sin, acos, asin, log, exp, sqrt, pow, atan, fabs, ceil, floor
)
from memory import DTypePointer, memset_zero
from memory.unsafe import DTypePointer as UnsafeDTypePointer
import math

alias INVALID = -1
alias INLET = 0
alias AVERAGE = 1
alias OUTLET = 2
alias NUM_TEST_TYPES = 3

fn get_enum_value(key: StringLiteral) -> Int32:
    if key == "INLET":
        return INLET
    elif key == "AVERAGE":
        return AVERAGE
    elif key == "OUTLET":
        return OUTLET
    else:
        return INVALID

struct ParametersData:
    var Name: String
    var Area: Float64
    var TestMassFlowRate: Float64
    var TestType: Int32
    var eff0: Float64
    var eff1: Float64
    var eff2: Float64
    var iam1: Float64
    var iam2: Float64
    var Volume: Float64
    var SideHeight: Float64
    var ThermalMass: Float64
    var ULossSide: Float64
    var ULossBottom: Float64
    var AspectRatio: Float64
    var NumOfCovers: Int32
    var CoverSpacing: Float64
    var RefractiveIndex: InlineArray[Float64, 2]
    var ExtCoefTimesThickness: InlineArray[Float64, 2]
    var EmissOfCover: InlineArray[Float64, 2]
    var EmissOfAbsPlate: Float64
    var AbsorOfAbsPlate: Float64

    fn __init__(inout self):
        self.Name = String()
        self.Area = 0.0
        self.TestMassFlowRate = 0.0
        self.TestType = INLET
        self.eff0 = 0.0
        self.eff1 = 0.0
        self.eff2 = 0.0
        self.iam1 = 0.0
        self.iam2 = 0.0
        self.Volume = 0.0
        self.SideHeight = 0.0
        self.ThermalMass = 0.0
        self.ULossSide = 0.0
        self.ULossBottom = 0.0
        self.AspectRatio = 0.0
        self.NumOfCovers = 0
        self.CoverSpacing = 0.0
        self.RefractiveIndex = InlineArray[Float64, 2](fill=0.0)
        self.ExtCoefTimesThickness = InlineArray[Float64, 2](fill=0.0)
        self.EmissOfCover = InlineArray[Float64, 2](fill=0.0)
        self.EmissOfAbsPlate = 0.0
        self.AbsorOfAbsPlate = 0.0

    fn IAM(inout self, state: DTypePointer[DType.float64], IncidentAngle: Float64) -> Float64:
        var CutoffAngle = 60.0 * state[0]
        if abs(IncidentAngle) > CutoffAngle:
            return 0.0
        
        var s = (1.0 / cos(IncidentAngle)) - 1.0
        var IAM_val = 1.0 + self.iam1 * s + self.iam2 * s * s
        IAM_val = max(IAM_val, 0.0)
        
        if IAM_val > 10.0:
            _ = state
        
        return IAM_val

struct CollectorData:
    var Name: String
    var BCType: String
    var OSCMName: String
    var VentCavIndex: Int32
    var Type: Int32
    var plantLoc_loop_index: Int32
    var Init: Bool
    var InitSizing: Bool
    var Parameters: Int32
    var Surface: Int32
    var InletNode: Int32
    var InletTemp: Float64
    var OutletNode: Int32
    var OutletTemp: Float64
    var MassFlowRate: Float64
    var MassFlowRateMax: Float64
    var VolFlowRateMax: Float64
    var ErrIndex: Int32
    var IterErrIndex: Int32
    var IncidentAngleModifier: Float64
    var Efficiency: Float64
    var Power: Float64
    var HeatGain: Float64
    var HeatLoss: Float64
    var Energy: Float64
    var HeatRate: Float64
    var HeatEnergy: Float64
    var StoredHeatRate: Float64
    var StoredHeatEnergy: Float64
    var HeatGainRate: Float64
    var SkinHeatLossRate: Float64
    var CollHeatLossEnergy: Float64
    var TauAlpha: Float64
    var UTopLoss: Float64
    var TempOfWater: Float64
    var TempOfAbsPlate: Float64
    var TempOfInnerCover: Float64
    var TempOfOuterCover: Float64
    var TauAlphaSkyDiffuse: Float64
    var TauAlphaGndDiffuse: Float64
    var TauAlphaBeam: Float64
    var CoversAbsSkyDiffuse: InlineArray[Float64, 2]
    var CoversAbsGndDiffuse: InlineArray[Float64, 2]
    var CoverAbs: InlineArray[Float64, 2]
    var TimeElapsed: Float64
    var UbLoss: Float64
    var UsLoss: Float64
    var AreaRatio: Float64
    var RefDiffInnerCover: Float64
    var SavedTempOfWater: Float64
    var SavedTempOfAbsPlate: Float64
    var SavedTempOfInnerCover: Float64
    var SavedTempOfOuterCover: Float64
    var SavedTempCollectorOSCM: Float64
    var Length: Float64
    var TiltR2V: Float64
    var Tilt: Float64
    var CosTilt: Float64
    var SinTilt: Float64
    var SideArea: Float64
    var Area: Float64
    var Volume: Float64
    var OSCM_ON: Bool
    var InitICS: Bool
    var SetLoopIndexFlag: Bool
    var SetDiffRadFlag: Bool

    fn __init__(inout self):
        self.Name = String()
        self.BCType = String()
        self.OSCMName = String()
        self.VentCavIndex = 0
        self.Type = -1
        self.plantLoc_loop_index = 0
        self.Init = True
        self.InitSizing = True
        self.Parameters = 0
        self.Surface = 0
        self.InletNode = 0
        self.InletTemp = 0.0
        self.OutletNode = 0
        self.OutletTemp = 0.0
        self.MassFlowRate = 0.0
        self.MassFlowRateMax = 0.0
        self.VolFlowRateMax = 0.0
        self.ErrIndex = 0
        self.IterErrIndex = 0
        self.IncidentAngleModifier = 0.0
        self.Efficiency = 0.0
        self.Power = 0.0
        self.HeatGain = 0.0
        self.HeatLoss = 0.0
        self.Energy = 0.0
        self.HeatRate = 0.0
        self.HeatEnergy = 0.0
        self.StoredHeatRate = 0.0
        self.StoredHeatEnergy = 0.0
        self.HeatGainRate = 0.0
        self.SkinHeatLossRate = 0.0
        self.CollHeatLossEnergy = 0.0
        self.TauAlpha = 0.0
        self.UTopLoss = 0.0
        self.TempOfWater = 0.0
        self.TempOfAbsPlate = 0.0
        self.TempOfInnerCover = 0.0
        self.TempOfOuterCover = 0.0
        self.TauAlphaSkyDiffuse = 0.0
        self.TauAlphaGndDiffuse = 0.0
        self.TauAlphaBeam = 0.0
        self.CoversAbsSkyDiffuse = InlineArray[Float64, 2](fill=0.0)
        self.CoversAbsGndDiffuse = InlineArray[Float64, 2](fill=0.0)
        self.CoverAbs = InlineArray[Float64, 2](fill=0.0)
        self.TimeElapsed = 0.0
        self.UbLoss = 0.0
        self.UsLoss = 0.0
        self.AreaRatio = 0.0
        self.RefDiffInnerCover = 0.0
        self.SavedTempOfWater = 0.0
        self.SavedTempOfAbsPlate = 0.0
        self.SavedTempOfInnerCover = 0.0
        self.SavedTempOfOuterCover = 0.0
        self.SavedTempCollectorOSCM = 0.0
        self.Length = 0.0
        self.TiltR2V = 0.0
        self.Tilt = 0.0
        self.CosTilt = 0.0
        self.SinTilt = 0.0
        self.SideArea = 0.0
        self.Area = 0.0
        self.Volume = 0.0
        self.OSCM_ON = False
        self.InitICS = False
        self.SetLoopIndexFlag = True
        self.SetDiffRadFlag = True

struct SolarCollectorsData:
    var NumOfCollectors: Int32
    var NumOfParameters: Int32
    var GetInputFlag: Bool
    var Parameters: DTypePointer[DType.float64]
    var Collector: DTypePointer[DType.float64]
    var UniqueParametersNames: DTypePointer[DType.uint8]
    var UniqueCollectorNames: DTypePointer[DType.uint8]

    fn __init__(inout self):
        self.NumOfCollectors = 0
        self.NumOfParameters = 0
        self.GetInputFlag = True
        self.Parameters = DTypePointer[DType.float64]()
        self.Collector = DTypePointer[DType.float64]()
        self.UniqueParametersNames = DTypePointer[DType.uint8]()
        self.UniqueCollectorNames = DTypePointer[DType.uint8]()

@always_inline
fn pow_2(x: Float64) -> Float64:
    return x * x

@always_inline
fn pow_3(x: Float64) -> Float64:
    return x * x * x

@always_inline
fn pow_4(x: Float64) -> Float64:
    return x * x * x * x

@always_inline
fn root_4(x: Float64) -> Float64:
    return pow(x, 0.25)

fn CalcConvCoeffBetweenPlates(
    TempSurf1: Float64, TempSurf2: Float64, AirGap: Float64, CosTilt: Float64, SinTilt: Float64
) -> Float64:
    var gravity: Float64 = 9.806
    
    var Temps = InlineArray[Float64, 11](fill=0.0)
    var Mu = InlineArray[Float64, 11](fill=0.0)
    var Conductivity = InlineArray[Float64, 11](fill=0.0)
    var Pr = InlineArray[Float64, 11](fill=0.0)
    var Density = InlineArray[Float64, 11](fill=0.0)
    
    Temps[0] = -23.15
    Temps[1] = 6.85
    Temps[2] = 16.85
    Temps[3] = 24.85
    Temps[4] = 26.85
    Temps[5] = 36.85
    Temps[6] = 46.85
    Temps[7] = 56.85
    Temps[8] = 66.85
    Temps[9] = 76.85
    Temps[10] = 126.85
    
    Mu[0] = 0.0000161
    Mu[1] = 0.0000175
    Mu[2] = 0.000018
    Mu[3] = 0.0000184
    Mu[4] = 0.0000185
    Mu[5] = 0.000019
    Mu[6] = 0.0000194
    Mu[7] = 0.0000199
    Mu[8] = 0.0000203
    Mu[9] = 0.0000208
    Mu[10] = 0.0000229
    
    Conductivity[0] = 0.0223
    Conductivity[1] = 0.0246
    Conductivity[2] = 0.0253
    Conductivity[3] = 0.0259
    Conductivity[4] = 0.0261
    Conductivity[5] = 0.0268
    Conductivity[6] = 0.0275
    Conductivity[7] = 0.0283
    Conductivity[8] = 0.0290
    Conductivity[9] = 0.0297
    Conductivity[10] = 0.0331
    
    Pr[0] = 0.724
    Pr[1] = 0.717
    Pr[2] = 0.714
    Pr[3] = 0.712
    Pr[4] = 0.712
    Pr[5] = 0.711
    Pr[6] = 0.71
    Pr[7] = 0.708
    Pr[8] = 0.707
    Pr[9] = 0.706
    Pr[10] = 0.703
    
    Density[0] = 1.413
    Density[1] = 1.271
    Density[2] = 1.224
    Density[3] = 1.186
    Density[4] = 1.177
    Density[5] = 1.143
    Density[6] = 1.110
    Density[7] = 1.076
    Density[8] = 1.043
    Density[9] = 1.009
    Density[10] = 0.883
    
    var DeltaT = abs(TempSurf1 - TempSurf2)
    var Tref = 0.5 * (TempSurf1 + TempSurf2)
    var Index: Int32 = 0
    
    while Index < 11:
        if Tref < Temps[Index]:
            break
        Index += 1
    
    var VisDOfAir: Float64
    var CondOfAir: Float64
    var PrOfAir: Float64
    var DensOfAir: Float64
    
    if Index == 0:
        VisDOfAir = Mu[0]
        CondOfAir = Conductivity[0]
        PrOfAir = Pr[0]
        DensOfAir = Density[0]
    elif Index >= 11:
        Index = 10
        VisDOfAir = Mu[Index]
        CondOfAir = Conductivity[Index]
        PrOfAir = Pr[Index]
        DensOfAir = Density[Index]
    else:
        var InterpFrac = (Tref - Temps[Index - 1]) / (Temps[Index] - Temps[Index - 1])
        VisDOfAir = Mu[Index - 1] + InterpFrac * (Mu[Index] - Mu[Index - 1])
        CondOfAir = Conductivity[Index - 1] + InterpFrac * (Conductivity[Index] - Conductivity[Index - 1])
        PrOfAir = Pr[Index - 1] + InterpFrac * (Pr[Index] - Pr[Index - 1])
        DensOfAir = Density[Index - 1] + InterpFrac * (Density[Index] - Density[Index - 1])
    
    var Kelvin: Float64 = 273.15
    var VolExpAir = 1.0 / (Tref + Kelvin)
    
    var RaNum = gravity * pow_2(DensOfAir) * VolExpAir * PrOfAir * DeltaT * pow_3(AirGap) / pow_2(VisDOfAir)
    var RaNumCosTilt = RaNum * CosTilt
    
    var NuL: Float64
    if RaNum == 0.0:
        NuL = 0.0
    else:
        if RaNumCosTilt > 1708.0:
            NuL = 1.44 * (1.0 - 1708.0 * pow(SinTilt, 1.6) / (RaNum * CosTilt)) * (1.0 - 1708.0 / RaNumCosTilt)
        else:
            NuL = 0.0
    
    if RaNumCosTilt > 5830.0:
        NuL += pow(RaNumCosTilt / 5830.0 - 1.0, 1.0 / 3.0)
    
    NuL += 1.0
    var hConvCoef = NuL * CondOfAir / AirGap
    
    return hConvCoef

fn CalcConvCoeffAbsPlateAndWater(
    TAbsorber: Float64, TWater: Float64, Lc: Float64, TiltR2V: Float64
) -> Float64:
    var gravity: Float64 = 9.806
    
    var DeltaT = abs(TAbsorber - TWater)
    var TReference = TAbsorber - 0.25 * (TAbsorber - TWater)
    
    var WaterSpecHeat: Float64 = 4186.0
    var CondOfWater: Float64 = 0.6
    var VisOfWater: Float64 = 0.001
    var DensOfWater: Float64 = 1000.0
    var PrOfWater = VisOfWater * WaterSpecHeat / CondOfWater
    
    var VolExpWater: Float64 = 0.0002
    
    var GrNum = gravity * VolExpWater * pow_2(DensOfWater) * PrOfWater * DeltaT * pow_3(Lc) / pow_2(VisOfWater)
    var CosTilt = cos(TiltR2V * 0.017453292519943295)
    
    var RaNum: Float64
    var NuL: Float64
    
    if TAbsorber > TWater:
        if abs(TiltR2V - 90.0) < 1.0:
            RaNum = GrNum * PrOfWater
            if RaNum <= 1708.0:
                NuL = 1.0
            else:
                NuL = 0.58 * pow(RaNum, 0.20)
        else:
            RaNum = GrNum * PrOfWater * CosTilt
            if RaNum <= 1708.0:
                NuL = 1.0
            else:
                NuL = 0.56 * root_4(RaNum)
    else:
        RaNum = GrNum * PrOfWater
        if RaNum > 5.0e8:
            NuL = 0.13 * pow(RaNum, 1.0 / 3.0)
        else:
            NuL = 0.16 * pow(RaNum, 1.0 / 3.0)
            if RaNum <= 1708.0:
                NuL = 1.0
    
    var hConvA2W = NuL * CondOfWater / Lc
    
    return hConvA2W

fn ICSCollectorAnalyticalSolution(
    SecInTimeStep: Float64, a1: Float64, a2: Float64, a3: Float64,
    b1: Float64, b2: Float64, b3: Float64,
    TempAbsPlateOld: Float64, TempWaterOld: Float64,
    AbsorberPlateHasMass: Bool
) -> Tuple[Float64, Float64]:
    var TempAbsPlate: Float64
    var TempWater: Float64
    
    if AbsorberPlateHasMass:
        var a: Float64 = 1.0
        var b = -(a1 + b2)
        var c = a1 * b2 - a2 * b1
        var BSquareM4TimesATimesC = pow_2(b) - 4.0 * a * c
        
        if BSquareM4TimesATimesC > 0.0:
            var lamda1 = (-b + sqrt(BSquareM4TimesATimesC)) / (2.0 * a)
            var lamda2 = (-b - sqrt(BSquareM4TimesATimesC)) / (2.0 * a)
            
            var ConstOfTpSln = (-a3 * b2 + b3 * a2) / c
            var ConstOfTwSln = (-a1 * b3 + b1 * a3) / c
            
            var r1 = (lamda1 - a1) / a2
            var r2 = (lamda2 - a1) / a2
            
            var ConstantC2 = (TempWaterOld + r1 * ConstOfTpSln - r1 * TempAbsPlateOld - ConstOfTwSln) / (r2 - r1)
            var ConstantC1 = (TempAbsPlateOld - ConstOfTpSln - ConstantC2)
            
            TempAbsPlate = (
                ConstantC1 * exp(lamda1 * SecInTimeStep) +
                ConstantC2 * exp(lamda2 * SecInTimeStep) + ConstOfTpSln
            )
            TempWater = (
                r1 * ConstantC1 * exp(lamda1 * SecInTimeStep) +
                r2 * ConstantC2 * exp(lamda2 * SecInTimeStep) + ConstOfTwSln
            )
        else:
            TempAbsPlate = TempAbsPlateOld
            TempWater = TempWaterOld
    else:
        var b = b2 - b1 * (a2 / a1)
        var c = b3 - b1 * (a3 / a1)
        TempWater = (TempWaterOld + c / b) * exp(b * SecInTimeStep) - c / b
        TempAbsPlate = -(a2 * TempWater + a3) / a1
    
    return TempAbsPlate, TempWater

fn CalcTransRefAbsOfCover(
    IncidentAngle: Float64, NumCovers: Int32, DiffRefFlag: Bool = False
) -> Tuple[Float64, Float64, Float64, Float64, Float64]:
    var TransPerp = InlineArray[Float64, 2](fill=1.0)
    var TransPara = InlineArray[Float64, 2](fill=1.0)
    var ReflPerp = InlineArray[Float64, 2](fill=0.0)
    var ReflPara = InlineArray[Float64, 2](fill=0.0)
    var AbsorPerp = InlineArray[Float64, 2](fill=0.0)
    var AbsorPara = InlineArray[Float64, 2](fill=0.0)
    var TransAbsOnly = InlineArray[Float64, 2](fill=1.0)
    
    var AirRefIndex: Float64 = 1.0003
    var sin_IncAngle = sin(IncidentAngle)
    
    for nCover in range(NumCovers):
        var CoverRefrIndex: Float64 = 1.526
        var RefrAngle = asin(sin_IncAngle * AirRefIndex / CoverRefrIndex)
        
        TransAbsOnly[nCover] = exp(-0.1 / cos(RefrAngle))
        
        var ParaRad: Float64
        var PerpRad: Float64
        
        if IncidentAngle == 0.0:
            ParaRad = pow_2((CoverRefrIndex - AirRefIndex) / (CoverRefrIndex + AirRefIndex))
            PerpRad = pow_2((CoverRefrIndex - AirRefIndex) / (CoverRefrIndex + AirRefIndex))
        else:
            ParaRad = pow_2(math.tan(RefrAngle - IncidentAngle) / math.tan(RefrAngle + IncidentAngle))
            PerpRad = pow_2(sin(RefrAngle - IncidentAngle) / sin(RefrAngle + IncidentAngle))
        
        TransPerp[nCover] = (
            TransAbsOnly[nCover] * ((1.0 - PerpRad) / (1.0 + PerpRad)) *
            ((1.0 - pow_2(PerpRad)) / (1.0 - pow_2(PerpRad * TransAbsOnly[nCover])))
        )
        TransPara[nCover] = (
            TransAbsOnly[nCover] * ((1.0 - ParaRad) / (1.0 + ParaRad)) *
            ((1.0 - pow_2(ParaRad)) / (1.0 - pow_2(ParaRad * TransAbsOnly[nCover])))
        )
        
        ReflPerp[nCover] = (
            PerpRad + (pow_2(1.0 - PerpRad) * pow_2(TransAbsOnly[nCover]) * PerpRad) /
            (1.0 - pow_2(PerpRad * TransAbsOnly[nCover]))
        )
        ReflPara[nCover] = (
            ParaRad + (pow_2(1.0 - ParaRad) * pow_2(TransAbsOnly[nCover]) * ParaRad) /
            (1.0 - pow_2(ParaRad * TransAbsOnly[nCover]))
        )
        
        AbsorPerp[nCover] = 1.0 - TransPerp[nCover] - ReflPerp[nCover]
        AbsorPara[nCover] = 1.0 - TransPara[nCover] - ReflPara[nCover]
    
    var AbsCover1 = 0.5 * (AbsorPerp[0] + AbsorPara[0])
    var AbsCover2: Float64 = 0.0
    if NumCovers == 2:
        AbsCover2 = 0.5 * (AbsorPerp[1] + AbsorPara[1])
    
    var TransSys: Float64
    var ReflSys: Float64
    var RefSysDiffuse: Float64 = 0.0
    
    if NumCovers == 2:
        TransSys = 0.5 * (
            TransPerp[0] * TransPerp[1] / (1.0 - ReflPerp[0] * ReflPerp[1]) +
            TransPara[0] * TransPara[1] / (1.0 - ReflPara[0] * ReflPara[1])
        )
        ReflSys = 0.5 * (
            ReflPerp[0] + TransSys * ReflPerp[1] * TransPerp[0] / TransPerp[1] +
            ReflPara[0] + TransSys * ReflPara[1] * TransPara[0] / TransPara[1]
        )
        
        if DiffRefFlag:
            var TransSysDiff = 0.5 * (
                TransPerp[1] * TransPerp[0] / (1.0 - ReflPerp[1] * ReflPerp[0]) +
                TransPara[1] * TransPara[0] / (1.0 - ReflPara[1] * ReflPara[0])
            )
            RefSysDiffuse = 0.5 * (
                ReflPerp[1] + TransSysDiff * ReflPerp[0] * TransPerp[1] / TransPerp[0] +
                ReflPara[1] + TransSysDiff * ReflPara[0] * TransPara[1] / TransPara[0]
            )
    else:
        TransSys = TransPerp[0]
        ReflSys = ReflPerp[0]
    
    return TransSys, ReflSys, AbsCover1, AbsCover2, RefSysDiffuse

@export
fn solar_collectors_init():
    pass
