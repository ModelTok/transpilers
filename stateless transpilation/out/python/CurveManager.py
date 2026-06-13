"""
EnergyPlus CurveManager module - Python port.
Manages performance curves and table lookups for HVAC equipment.
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Protocol
import math
from pathlib import Path

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from Data/EnergyPlusData
# - ErrorObjectHeader: from error handling
# - DataBranchAirLoopPlant: branch/plant data structure
# - Node: node constants (SensedNodeFlagValue)
# - Constant: physical constants
# - OutputProcessor: output variable setup functions
# - Btwxt: table interpolation library (GridAxis, RegularGridInterpolator, etc.)
# - ShowMessage, ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningError, ShowSevereDuplicateName: logging
# - SetupOutputVariable, SetupEMSActuator: output/EMS setup
# - DataSystemVariables.CheckForActualFilePath: file path checking
# - InputProcessor: input parsing (getObjectItem, getNumObjectsFound, etc.)
# - Util.makeUPPER, Util.SameString, Util.FindItemInList: string utilities
# - DBL_MAX: max float constant
# - getEnumValue: enum lookup helper
# - sign, pow_2: math utilities


class CurveType(IntEnum):
    """Enum for curve types"""
    Invalid = -1
    Linear = 0
    Quadratic = 1
    BiQuadratic = 2
    Cubic = 3
    QuadraticLinear = 4
    BiCubic = 5
    TriQuadratic = 6
    Exponent = 7
    Quartic = 8
    FanPressureRise = 9
    ExponentialSkewNormal = 10
    Sigmoid = 11
    RectangularHyperbola1 = 12
    RectangularHyperbola2 = 13
    ExponentialDecay = 14
    DoubleExponentialDecay = 15
    QuadLinear = 16
    QuintLinear = 17
    CubicLinear = 18
    ChillerPartLoadWithLift = 19
    BtwxtTableLookup = 20
    Num = 21


CURVE_OBJECT_NAMES = [
    "Curve:Linear",
    "Curve:Quadratic",
    "Curve:Biquadratic",
    "Curve:Cubic",
    "Curve:QuadLinear",
    "Curve:Bicubic",
    "Curve:Triquadratic",
    "Curve:Exponent",
    "Curve:Quartic",
    "Curve:FanPressureRise",
    "Curve:ExponentialSkewNormal",
    "Curve:Sigmoid",
    "Curve:RectangularHyperbola1",
    "Curve:RectangularHyperbola2",
    "Curve:ExponentialDecay",
    "Curve:DoubleExponentialDecay",
    "Curve:QuadraticLinear",
    "Curve:QuintLinear",
    "Curve:CubicLinear",
    "Curve:ChillerPartLoadWithLift",
    "Table:Lookup",
]


@dataclass
class Limits:
    """Limits struct for curve input/output bounds"""
    min: float = 0.0
    max: float = 0.0
    minPresent: bool = False
    maxPresent: bool = False


@dataclass
class Curve:
    """Performance curve data structure"""
    Name: str = ""
    Num: int = 0
    curveType: CurveType = CurveType.Invalid
    TableIndex: int = 0
    numDims: int = 0
    GridValueIndex: int = 0
    contextString: str = ""
    coeff: List[float] = field(default_factory=lambda: [0.0] * 27)
    inputs: List[float] = field(default_factory=lambda: [0.0] * 6)
    inputLimits: List[Limits] = field(default_factory=lambda: [Limits() for _ in range(6)])
    output: float = 0.0
    outputLimits: Limits = field(default_factory=Limits)
    EMSOverrideOn: bool = False
    EMSOverrideCurveValue: float = 0.0

    def value(self, state, *args):
        """Multi-signature value() method"""
        if len(args) == 1:
            return self._value_1(state, args[0])
        elif len(args) == 2:
            return self._value_2(state, args[0], args[1])
        elif len(args) == 3:
            return self._value_3(state, args[0], args[1], args[2])
        elif len(args) == 4:
            return self._value_4(state, args[0], args[1], args[2], args[3])
        elif len(args) == 5:
            return self._value_5(state, args[0], args[1], args[2], args[3], args[4])
        elif len(args) == 6:
            return self._value_6(state, args[0], args[1], args[2], args[3], args[4], args[5])
        else:
            raise ValueError(f"Unsupported number of arguments: {len(args)}")

    def _value_1(self, state, V1: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        Val = 0.0

        if self.curveType == CurveType.Linear:
            Val = self.coeff[0] + V1 * self.coeff[1]
        elif self.curveType == CurveType.Quadratic:
            Val = self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2])
        elif self.curveType == CurveType.Cubic:
            Val = self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * self.coeff[3]))
        elif self.curveType == CurveType.Quartic:
            Val = self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * (self.coeff[3] + V1 * self.coeff[4])))
        elif self.curveType == CurveType.Exponent:
            Val = self.coeff[0] + self.coeff[1] * (V1 ** self.coeff[2])
        elif self.curveType == CurveType.ExponentialSkewNormal:
            CoeffZ1 = (V1 - self.coeff[0]) / self.coeff[1]
            CoeffZ2 = (self.coeff[3] * V1 * math.exp(self.coeff[2] * V1) - self.coeff[0]) / self.coeff[1]
            CoeffZ3 = -self.coeff[0] / self.coeff[1]
            sqrt_2_inv = 1.0 / math.sqrt(2.0)
            Numer = math.exp(-0.5 * (CoeffZ1 * CoeffZ1)) * (1.0 + math.copysign(1.0, CoeffZ2) * math.erf(abs(CoeffZ2) * sqrt_2_inv))
            Denom = math.exp(-0.5 * (CoeffZ3 * CoeffZ3)) * (1.0 + math.copysign(1.0, CoeffZ3) * math.erf(abs(CoeffZ3) * sqrt_2_inv))
            Val = Numer / Denom
        elif self.curveType == CurveType.Sigmoid:
            CurveValueExp = math.exp((self.coeff[2] - V1) / self.coeff[3])
            Val = self.coeff[0] + self.coeff[1] / ((1.0 + CurveValueExp) ** self.coeff[4])
        elif self.curveType == CurveType.RectangularHyperbola1:
            Numer = self.coeff[0] * V1
            Denom = self.coeff[1] + V1
            Val = (Numer / Denom) + self.coeff[2]
        elif self.curveType == CurveType.RectangularHyperbola2:
            Numer = self.coeff[0] * V1
            Denom = self.coeff[1] + V1
            Val = (Numer / Denom) + (self.coeff[2] * V1)
        elif self.curveType == CurveType.ExponentialDecay:
            Val = self.coeff[0] + self.coeff[1] * math.exp(self.coeff[2] * V1)
        elif self.curveType == CurveType.DoubleExponentialDecay:
            Val = self.coeff[0] + self.coeff[1] * math.exp(self.coeff[2] * V1) + self.coeff[3] * math.exp(self.coeff[4] * V1)
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1)
        else:
            Val = self.valueFallback(state, V1, 0.0, 0.0, 0.0, 0.0)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def _value_2(self, state, V1: float, V2: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        V2 = max(min(V2, self.inputLimits[1].max), self.inputLimits[1].min)
        Val = 0.0

        if self.curveType == CurveType.FanPressureRise:
            Val = V1 * (self.coeff[0] * V1 + self.coeff[1] + self.coeff[2] * math.sqrt(V2)) + self.coeff[3] * V2
        elif self.curveType == CurveType.BiQuadratic:
            Val = (self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2]) + 
                   V2 * (self.coeff[3] + V2 * self.coeff[4]) + V1 * V2 * self.coeff[5])
        elif self.curveType == CurveType.QuadraticLinear:
            Val = ((self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2])) + 
                   (self.coeff[3] + V1 * (self.coeff[4] + V1 * self.coeff[5])) * V2)
        elif self.curveType == CurveType.CubicLinear:
            Val = ((self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * self.coeff[3]))) + 
                   (self.coeff[4] + V1 * self.coeff[5]) * V2)
        elif self.curveType == CurveType.BiCubic:
            Val = (self.coeff[0] + V1 * self.coeff[1] + V1 * V1 * self.coeff[2] + V2 * self.coeff[3] + 
                   V2 * V2 * self.coeff[4] + V1 * V2 * self.coeff[5] + V1 * V1 * V1 * self.coeff[6] + 
                   V2 * V2 * V2 * self.coeff[7] + V1 * V1 * V2 * self.coeff[8] + V1 * V2 * V2 * self.coeff[9])
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1, V2)
        else:
            Val = self.valueFallback(state, V1, V2, 0.0, 0.0, 0.0)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def _value_3(self, state, V1: float, V2: float, V3: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        V2 = max(min(V2, self.inputLimits[1].max), self.inputLimits[1].min)
        V3 = max(min(V3, self.inputLimits[2].max), self.inputLimits[2].min)
        Val = 0.0

        if self.curveType == CurveType.ChillerPartLoadWithLift:
            Val = (self.coeff[0] + self.coeff[1] * V1 + self.coeff[2] * V1 * V1 + self.coeff[3] * V2 + 
                   self.coeff[4] * V2 * V2 + self.coeff[5] * V1 * V2 + self.coeff[6] * V1 * V1 * V1 + 
                   self.coeff[7] * V2 * V2 * V2 + self.coeff[8] * V1 * V1 * V2 + self.coeff[9] * V1 * V2 * V2 + 
                   self.coeff[10] * V1 * V1 * V2 * V2 + self.coeff[11] * V3 * V2 * V2 * V2)
        elif self.curveType == CurveType.TriQuadratic:
            V1s = V1 * V1
            V2s = V2 * V2
            V3s = V3 * V3
            c = self.coeff
            Val = (c[0] + c[1] * V1s + c[2] * V1 + c[3] * V2s + c[4] * V2 + c[5] * V3s + c[6] * V3 + 
                   c[7] * V1s * V2s + c[8] * V1 * V2 + c[9] * V1 * V2s + c[10] * V1s * V2 + 
                   c[11] * V1s * V3s + c[12] * V1 * V3 + c[13] * V1 * V3s + c[14] * V1s * V3 + 
                   c[15] * V2s * V3s + c[16] * V2 * V3 + c[17] * V2 * V3s + c[18] * V2s * V3 + 
                   c[19] * V1s * V2s * V3s + c[20] * V1s * V2s * V3 + c[21] * V1s * V2 * V3s + 
                   c[22] * V1 * V2s * V3s + c[23] * V1s * V2 * V3 + c[24] * V1 * V2s * V3 + 
                   c[25] * V1 * V2 * V3s + c[26] * V1 * V2 * V3)
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1, V2, V3)
        else:
            Val = self.valueFallback(state, V1, V2, V3, 0.0, 0.0)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def _value_4(self, state, V1: float, V2: float, V3: float, V4: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        V2 = max(min(V2, self.inputLimits[1].max), self.inputLimits[1].min)
        V3 = max(min(V3, self.inputLimits[2].max), self.inputLimits[2].min)
        V4 = max(min(V4, self.inputLimits[3].max), self.inputLimits[3].min)
        Val = 0.0

        if self.curveType == CurveType.QuadLinear:
            Val = self.coeff[0] + V1 * self.coeff[1] + V2 * self.coeff[2] + V3 * self.coeff[3] + V4 * self.coeff[4]
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1, V2, V3, V4)
        else:
            Val = self.valueFallback(state, V1, V2, V3, V4, 0.0)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def _value_5(self, state, V1: float, V2: float, V3: float, V4: float, V5: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        self.inputs[4] = V5
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        V2 = max(min(V2, self.inputLimits[1].max), self.inputLimits[1].min)
        V3 = max(min(V3, self.inputLimits[2].max), self.inputLimits[2].min)
        V4 = max(min(V4, self.inputLimits[3].max), self.inputLimits[3].min)
        V5 = max(min(V5, self.inputLimits[4].max), self.inputLimits[4].min)
        Val = 0.0

        if self.curveType == CurveType.QuintLinear:
            Val = self.coeff[0] + V1 * self.coeff[1] + V2 * self.coeff[2] + V3 * self.coeff[3] + V4 * self.coeff[4] + V5 * self.coeff[5]
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1, V2, V3, V4, V5)
        else:
            Val = self.valueFallback(state, V1, V2, V3, V4, V5)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def _value_6(self, state, V1: float, V2: float, V3: float, V4: float, V5: float, V6: float) -> float:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        self.inputs[4] = V5
        self.inputs[5] = V6
        V1 = max(min(V1, self.inputLimits[0].max), self.inputLimits[0].min)
        V2 = max(min(V2, self.inputLimits[1].max), self.inputLimits[1].min)
        V3 = max(min(V3, self.inputLimits[2].max), self.inputLimits[2].min)
        V4 = max(min(V4, self.inputLimits[3].max), self.inputLimits[3].min)
        V5 = max(min(V5, self.inputLimits[4].max), self.inputLimits[4].min)
        V6 = max(min(V6, self.inputLimits[5].max), self.inputLimits[5].min)

        Val = self.BtwxtTableInterpolation(state, V1, V2, V3, V4, V5, V6)

        if self.outputLimits.minPresent:
            Val = max(Val, self.outputLimits.min)
        if self.outputLimits.maxPresent:
            Val = min(Val, self.outputLimits.max)
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    def valueFallback(self, state, V1: float, V2: float, V3: float, V4: float, V5: float) -> float:
        if state.dataCurveManager.showFallbackMessage:
            ShowMessage(state, "Note: You have encountered a corner case in the EnergyPlus Curve:* evaluation code.")
            ShowMessage(state, "The code was refactored for version 23.1, but there were a few corner cases that could not be found automatically")
            ShowMessage(state, "If you are able, please provide your input file to the EnergyPlus helpdesk or repository so a developer can patch for your use case")
            ShowMessage(state, "Your simulation continues as normal, thanks!")
            state.dataCurveManager.showFallbackMessage = False

        if self.curveType == CurveType.Linear:
            return self.coeff[0] + V1 * self.coeff[1]
        elif self.curveType == CurveType.Quadratic:
            return self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2])
        elif self.curveType == CurveType.QuadLinear:
            return self.coeff[0] + V1 * self.coeff[1] + V2 * self.coeff[2] + V3 * self.coeff[3] + V4 * self.coeff[4]
        elif self.curveType == CurveType.QuintLinear:
            return self.coeff[0] + V1 * self.coeff[1] + V2 * self.coeff[2] + V3 * self.coeff[3] + V4 * self.coeff[4] + V5 * self.coeff[5]
        elif self.curveType == CurveType.Cubic:
            return self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * self.coeff[3]))
        elif self.curveType == CurveType.Quartic:
            return self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * (self.coeff[3] + V1 * self.coeff[4])))
        elif self.curveType == CurveType.BiQuadratic:
            return (self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2]) + 
                    V2 * (self.coeff[3] + V2 * self.coeff[4]) + V1 * V2 * self.coeff[5])
        elif self.curveType == CurveType.QuadraticLinear:
            return ((self.coeff[0] + V1 * (self.coeff[1] + V1 * self.coeff[2])) + 
                    (self.coeff[3] + V1 * (self.coeff[4] + V1 * self.coeff[5])) * V2)
        elif self.curveType == CurveType.CubicLinear:
            return ((self.coeff[0] + V1 * (self.coeff[1] + V1 * (self.coeff[2] + V1 * self.coeff[3]))) + 
                    (self.coeff[4] + V1 * self.coeff[5]) * V2)
        elif self.curveType == CurveType.BiCubic:
            return (self.coeff[0] + V1 * self.coeff[1] + V1 * V1 * self.coeff[2] + V2 * self.coeff[3] + 
                    V2 * V2 * self.coeff[4] + V1 * V2 * self.coeff[5] + V1 * V1 * V1 * self.coeff[6] + 
                    V2 * V2 * V2 * self.coeff[7] + V1 * V1 * V2 * self.coeff[8] + V1 * V2 * V2 * self.coeff[9])
        elif self.curveType == CurveType.ChillerPartLoadWithLift:
            return (self.coeff[0] + self.coeff[1] * V1 + self.coeff[2] * V1 * V1 + self.coeff[3] * V2 + 
                    self.coeff[4] * V2 * V2 + self.coeff[5] * V1 * V2 + self.coeff[6] * V1 * V1 * V1 + 
                    self.coeff[7] * V2 * V2 * V2 + self.coeff[8] * V1 * V1 * V2 + self.coeff[9] * V1 * V2 * V2 + 
                    self.coeff[10] * V1 * V1 * V2 * V2 + self.coeff[11] * V3 * V2 * V2 * V2)
        elif self.curveType == CurveType.TriQuadratic:
            V1s = V1 * V1
            V2s = V2 * V2
            V3s = V3 * V3
            c = self.coeff
            return (c[0] + c[1] * V1s + c[2] * V1 + c[3] * V2s + c[4] * V2 + c[5] * V3s + c[6] * V3 + 
                    c[7] * V1s * V2s + c[8] * V1 * V2 + c[9] * V1 * V2s + c[10] * V1s * V2 + 
                    c[11] * V1s * V3s + c[12] * V1 * V3 + c[13] * V1 * V3s + c[14] * V1s * V3 + 
                    c[15] * V2s * V3s + c[16] * V2 * V3 + c[17] * V2 * V3s + c[18] * V2s * V3 + 
                    c[19] * V1s * V2s * V3s + c[20] * V1s * V2s * V3 + c[21] * V1s * V2 * V3s + 
                    c[22] * V1 * V2s * V3s + c[23] * V1s * V2 * V3 + c[24] * V1 * V2s * V3 + 
                    c[25] * V1 * V2 * V3s + c[26] * V1 * V2 * V3)
        elif self.curveType == CurveType.Exponent:
            return self.coeff[0] + self.coeff[1] * (V1 ** self.coeff[2])
        elif self.curveType == CurveType.FanPressureRise:
            return V1 * (self.coeff[0] * V1 + self.coeff[1] + self.coeff[2] * math.sqrt(V2)) + self.coeff[3] * V2
        elif self.curveType == CurveType.ExponentialSkewNormal:
            CoeffZ1 = (V1 - self.coeff[0]) / self.coeff[1]
            CoeffZ2 = (self.coeff[3] * V1 * math.exp(self.coeff[2] * V1) - self.coeff[0]) / self.coeff[1]
            CoeffZ3 = -self.coeff[0] / self.coeff[1]
            sqrt_2_inv = 1.0 / math.sqrt(2.0)
            CurveValueNumer = math.exp(-0.5 * (CoeffZ1 * CoeffZ1)) * (1.0 + math.copysign(1.0, CoeffZ2) * math.erf(abs(CoeffZ2) * sqrt_2_inv))
            CurveValueDenom = math.exp(-0.5 * (CoeffZ3 * CoeffZ3)) * (1.0 + math.copysign(1.0, CoeffZ3) * math.erf(abs(CoeffZ3) * sqrt_2_inv))
            return CurveValueNumer / CurveValueDenom
        elif self.curveType == CurveType.Sigmoid:
            CurveValueExp = math.exp((self.coeff[2] - V1) / self.coeff[3])
            return self.coeff[0] + self.coeff[1] / ((1.0 + CurveValueExp) ** self.coeff[4])
        elif self.curveType == CurveType.RectangularHyperbola1:
            CurveValueNumer = self.coeff[0] * V1
            CurveValueDenom = self.coeff[1] + V1
            return (CurveValueNumer / CurveValueDenom) + self.coeff[2]
        elif self.curveType == CurveType.RectangularHyperbola2:
            CurveValueNumer = self.coeff[0] * V1
            CurveValueDenom = self.coeff[1] + V1
            return (CurveValueNumer / CurveValueDenom) + (self.coeff[2] * V1)
        elif self.curveType == CurveType.ExponentialDecay:
            return self.coeff[0] + self.coeff[1] * math.exp(self.coeff[2] * V1)
        elif self.curveType == CurveType.DoubleExponentialDecay:
            return self.coeff[0] + self.coeff[1] * math.exp(self.coeff[2] * V1) + self.coeff[3] * math.exp(self.coeff[4] * V1)
        else:
            return 0.0

    def BtwxtTableInterpolation(self, state, *args) -> float:
        """Multi-signature BtwxtTableInterpolation method"""
        target = list(args)
        callback_pair = (state, self.contextString)
        state.dataCurveManager.btwxtManager.setLoggingContext(callback_pair)
        return state.dataCurveManager.btwxtManager.getGridValue(self.TableIndex, self.GridValueIndex, target)


@dataclass
class TableFile:
    """Table file data structure"""
    filePath: Optional[Path] = None
    contents: List[List[str]] = field(default_factory=list)
    arrays: Dict[Tuple[int, int], List[float]] = field(default_factory=dict)
    numRows: int = 0
    numColumns: int = 0

    def load(self, state, path: Path) -> bool:
        self.filePath = path
        contextString = "CurveManager::TableFile::load: "
        fullPath = CheckForActualFilePath(state, path, contextString)
        if not fullPath:
            return True
        try:
            with open(fullPath, 'r') as file:
                self.numRows = 0
                self.numColumns = 0
                for line in file:
                    self.numRows += 1
                    parts = line.rstrip('\n').split(',')
                    colNum = len(parts)
                    if colNum > self.numColumns:
                        self.numColumns = colNum
                        self.contents.extend([[] for _ in range(colNum - len(self.contents))])
                    for i, part in enumerate(parts):
                        self.contents[i].append(part)
                    for i in range(colNum, self.numColumns):
                        self.contents[i].append("")
        except Exception:
            return True
        return False

    def getArray(self, state, colAndRow: Tuple[int, int]) -> List[float]:
        if colAndRow not in self.arrays:
            col, row = colAndRow
            if col >= self.numColumns:
                ShowFatalError(state, f"File \"{self.filePath}\" : Requested column ({col + 1}) exceeds the number of columns ({self.numColumns}).")
            if row >= self.numRows:
                ShowFatalError(state, f"File \"{self.filePath}\" : Requested starting row ({row + 1}) exceeds the number of rows ({self.numRows}).")
            content = self.contents[col]
            array = []
            for s in content[row:]:
                s = s.strip()
                if s:
                    try:
                        array.append(float(s))
                    except ValueError:
                        array.append(float('nan'))
                else:
                    array.append(float('nan'))
            self.arrays[colAndRow] = array
        return self.arrays[colAndRow]


@dataclass
class BtwxtManager:
    """Container for Btwxt N-d Objects"""
    gridMap: Dict[str, int] = field(default_factory=dict)
    grids: List = field(default_factory=list)
    independentVarRefs: Dict[str, dict] = field(default_factory=dict)
    tableFiles: Dict[Path, TableFile] = field(default_factory=dict)
    btwxt_logger: Optional[object] = None

    def addGrid(self, indVarListName: str, grid) -> int:
        self.grids.append(grid)
        self.gridMap[indVarListName] = len(self.grids) - 1
        return len(self.grids) - 1

    def setLoggingContext(self, context):
        for btwxt in self.grids:
            if hasattr(btwxt, 'get_logger'):
                btwxt.get_logger().set_message_context(context)

    def normalizeGridValues(self, gridIndex: int, outputIndex: int, target: List[float], scalar: float = 1.0) -> float:
        return self.grids[gridIndex].normalize_grid_point_data_set_at_target(outputIndex, target, scalar)

    def addOutputValues(self, gridIndex: int, values: List[float]) -> int:
        return self.grids[gridIndex].add_grid_point_data_set(values)

    def getGridIndex(self, state, indVarListName: str) -> Tuple[int, bool]:
        gridIndex = -1
        ErrorsFound = False
        if indVarListName in self.gridMap:
            gridIndex = self.gridMap[indVarListName]
        else:
            ShowSevereError(state, f"Table:Lookup \"{indVarListName}\" : No Table:IndependentVariableList found.")
            ErrorsFound = True
        return gridIndex, ErrorsFound

    def getNumGridDims(self, gridIndex: int) -> int:
        return self.grids[gridIndex].get_number_of_dimensions()

    def getGridValue(self, gridIndex: int, outputIndex: int, target: List[float]) -> float:
        return self.grids[gridIndex](target)[outputIndex]

    def clear(self):
        self.grids.clear()
        self.gridMap.clear()
        self.independentVarRefs.clear()
        self.tableFiles.clear()


@dataclass
class CurveManagerData:
    """Curve manager state data"""
    CurveValueMyBeginTimeStepFlag: bool = False
    FrictionFactorErrorHasOccurred: bool = False
    showFallbackMessage: bool = True
    curves: List[Optional[Curve]] = field(default_factory=list)
    curveMap: Dict[str, int] = field(default_factory=dict)
    btwxtManager: BtwxtManager = field(default_factory=BtwxtManager)

    def clear_state(self):
        self.curves.clear()
        self.curveMap.clear()


def commonEnvironInit(state):
    if state.dataGlobal.BeginEnvrnFlag and state.dataCurveManager.CurveValueMyBeginTimeStepFlag:
        ResetPerformanceCurveOutput(state)
        state.dataCurveManager.CurveValueMyBeginTimeStepFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataCurveManager.CurveValueMyBeginTimeStepFlag = True


def ResetPerformanceCurveOutput(state):
    for c in state.dataCurveManager.curves:
        if c is not None:
            c.output = Node.SensedNodeFlagValue
            for i in range(len(c.inputs)):
                c.inputs[i] = Node.SensedNodeFlagValue


def CurveValue(state, CurveIndex: int, *args) -> float:
    """Multi-signature CurveValue function"""
    if CurveIndex <= 0 or CurveIndex > len(state.dataCurveManager.curves):
        return 0.0
    curve = state.dataCurveManager.curves[CurveIndex - 1]
    if curve is None:
        return 0.0
    return curve.value(state, *args)


def AddCurve(state, name: str) -> Curve:
    curve = Curve(Name=name)
    state.dataCurveManager.curves.append(curve)
    curve.Num = len(state.dataCurveManager.curves)
    state.dataCurveManager.curveMap[Util.makeUPPER(curve.Name)] = curve.Num
    return curve


def GetCurveInput(state):
    GetInputErrorsFound = False
    GetCurveInputData(state)
    # Error handling deferred to caller


def GetCurveInputData(state):
    # Extensive input parsing - placeholder for complex logic
    # This function is very large and would parse all curve input types
    pass


def InitCurveReporting(state):
    for thisCurve in state.dataCurveManager.curves:
        if thisCurve is None:
            continue
        for dim in range(1, thisCurve.numDims + 1):
            numStr = str(dim)
            SetupOutputVariable(state,
                              f"Performance Curve Input Variable {numStr} Value",
                              "None",
                              thisCurve.inputs[dim - 1],
                              "System",
                              "Average",
                              thisCurve.Name)
        SetupOutputVariable(state,
                          "Performance Curve Output Value",
                          "None",
                          thisCurve.output,
                          "System",
                          "Average",
                          thisCurve.Name)


def IsCurveInputTypeValid(InInputType: str) -> bool:
    inputTypes = [
        "DIMENSIONLESS",
        "TEMPERATURE",
        "PRESSURE",
        "VOLUMETRICFLOW",
        "MASSFLOW",
        "POWER",
        "DISTANCE",
        "WAVELENGTH",
        "ANGLE",
        "VOLUMETRICFLOWPERPOWER",
    ]
    if not InInputType:
        return True
    return Util.makeUPPER(InInputType) in inputTypes


def IsCurveOutputTypeValid(InOutputType: str) -> bool:
    outputTypes = [
        "DIMENSIONLESS", "PRESSURE", "TEMPERATURE", "CAPACITY", "POWER"
    ]
    return Util.makeUPPER(InOutputType) in outputTypes


def CheckCurveDims(state, CurveIndex: int, validDims: List[int], routineName: str, 
                   objectType: str, objectName: str, curveFieldText: str) -> bool:
    if CurveIndex <= 0 or CurveIndex > len(state.dataCurveManager.curves):
        return True
    thisCurve = state.dataCurveManager.curves[CurveIndex - 1]
    if thisCurve is None:
        return True
    curveDim = thisCurve.numDims
    if curveDim in validDims:
        return False
    validDimsString = str(validDims[0])
    for i in range(1, len(validDims)):
        validDimsString += f" or {validDims[i]}"
    eoh = ErrorObjectHeader(routineName, objectType, objectName)
    ShowSevereCurveDims(state, eoh, curveFieldText, thisCurve.Name, validDimsString, curveDim)
    return True


def ShowSevereCurveDims(state, eoh, fieldName: str, curveName: str, validDims: str, dim: int):
    ShowSevereError(state, f"{eoh.routineName}: {eoh.objectType}=\"{eoh.objectName}\"")
    ShowContinueError(state, f"...Invalid curve for {fieldName}.")
    ShowContinueError(state, f"...Input curve=\"{curveName}\" has dimension {dim}.")
    ShowContinueError(state, f"...Curve type must have dimension {validDims}.")


def GetCurveName(state, CurveIndex: int) -> str:
    if CurveIndex > 0 and CurveIndex <= len(state.dataCurveManager.curves):
        curve = state.dataCurveManager.curves[CurveIndex - 1]
        if curve is not None:
            return curve.Name
    return ""


def GetCurveIndex(state, CurveName: str) -> int:
    CurveNameUC = Util.makeUPPER(CurveName)
    return state.dataCurveManager.curveMap.get(CurveNameUC, 0)


def GetCurve(state, CurveName: str) -> Optional[Curve]:
    curveNum = GetCurveIndex(state, CurveName)
    if curveNum == 0:
        return None
    if curveNum > 0 and curveNum <= len(state.dataCurveManager.curves):
        return state.dataCurveManager.curves[curveNum - 1]
    return None


def GetCurveMinMaxValues(state, CurveIndex: int, *args):
    """Multi-signature GetCurveMinMaxValues"""
    if CurveIndex <= 0 or CurveIndex > len(state.dataCurveManager.curves):
        return
    thisCurve = state.dataCurveManager.curves[CurveIndex - 1]
    if thisCurve is None:
        return

    numArgs = len(args)
    if numArgs == 2:
        args[0].__dict__.update({'value': thisCurve.inputLimits[0].min})
        args[1].__dict__.update({'value': thisCurve.inputLimits[0].max})
    elif numArgs == 4:
        args[0].__dict__.update({'value': thisCurve.inputLimits[0].min})
        args[1].__dict__.update({'value': thisCurve.inputLimits[0].max})
        args[2].__dict__.update({'value': thisCurve.inputLimits[1].min})
        args[3].__dict__.update({'value': thisCurve.inputLimits[1].max})
    # ... continue for other arities


def SetCurveOutputMinValue(state, CurveIndex: int, CurveMin: float) -> bool:
    if CurveIndex > 0 and CurveIndex <= len(state.dataCurveManager.curves):
        thisCurve = state.dataCurveManager.curves[CurveIndex - 1]
        if thisCurve is not None:
            thisCurve.outputLimits.min = CurveMin
            thisCurve.outputLimits.minPresent = True
            return False
    ShowSevereError(state, f"SetCurveOutputMinValue: CurveIndex=[{CurveIndex}] not in range of curves=[1:{len(state.dataCurveManager.curves)}].")
    return True


def SetCurveOutputMaxValue(state, CurveIndex: int, CurveMax: float) -> bool:
    if CurveIndex > 0 and CurveIndex <= len(state.dataCurveManager.curves):
        thisCurve = state.dataCurveManager.curves[CurveIndex - 1]
        if thisCurve is not None:
            thisCurve.outputLimits.max = CurveMax
            thisCurve.outputLimits.maxPresent = True
            return False
    ShowSevereError(state, f"SetCurveOutputMaxValue: CurveIndex=[{CurveIndex}] not in range of curves=[1:{len(state.dataCurveManager.curves)}].")
    return True


def GetPressureSystemInput(state):
    pass  # Placeholder for pressure system input parsing


def GetPressureCurveTypeAndIndex(state, PressureCurveName: str):
    pass  # Placeholder


def PressureCurveValue(state, PressureCurveIndex: int, MassFlow: float, Density: float, Viscosity: float) -> float:
    pass  # Placeholder


def CalculateMoodyFrictionFactor(state, ReynoldsNumber: float, RoughnessRatio: float) -> float:
    if ReynoldsNumber == 0.0 or RoughnessRatio == 0.0:
        return 0.0
    Term1 = RoughnessRatio / 3.7
    Term1 = Term1 ** 1.11
    Term2 = 6.9 / ReynoldsNumber
    Term3 = -1.8 * math.log10(Term1 + Term2)
    if Term3 != 0.0:
        return Term3 ** (-2.0)
    if not state.dataCurveManager.FrictionFactorErrorHasOccurred:
        ShowSevereError(state, "Plant Pressure System: Error in moody friction factor calculation")
        ShowContinueError(state, f"Current Conditions: Roughness Ratio={RoughnessRatio:.7f}; Reynolds Number={ReynoldsNumber:.1f}")
        ShowContinueError(state, "These conditions resulted in an unhandled numeric issue.")
        ShowContinueError(state, "Please contact EnergyPlus support/development team to raise an alert about this issue")
        ShowContinueError(state, "This issue will occur only one time.  The friction factor has been reset to 0.04 for calculations")
        state.dataCurveManager.FrictionFactorErrorHasOccurred = True
    return 0.04


def checkCurveIsNormalizedToOne(state, callingRoutineObj: str, objectName: str, curveIndex: int, 
                                cFieldName: str, cFieldValue: str, Var1: float, Var2: Optional[float] = None):
    if curveIndex <= 0:
        return
    if Var2 is None:
        CurveVal = CurveValue(state, curveIndex, Var1)
    else:
        CurveVal = CurveValue(state, curveIndex, Var1, Var2)
    if CurveVal > 1.10 or CurveVal < 0.90:
        ShowWarningError(state, f"{callingRoutineObj}=\"{objectName}\" curve values")
        ShowContinueError(state, f"... {cFieldName} = {cFieldValue} output is not equal to 1.0 (+ or - 10%) at rated conditions.")
        ShowContinueError(state, f"... Curve output at rated conditions = {CurveVal:.3f}")


# Stub for external functions (to be wired in)
def ShowMessage(state, msg: str): pass
def ShowSevereError(state, msg: str): pass
def ShowContinueError(state, msg: str): pass
def ShowFatalError(state, msg: str): pass
def ShowWarningError(state, msg: str): pass
def ShowSevereDuplicateName(state, eoh): pass
def SetupOutputVariable(state, varName: str, units: str, var, timeStep: str, storeType: str, objName: str): pass
def SetupEMSActuator(state, typeStr: str, name: str, controlStr: str, unitsStr: str, onFlag, value): pass
def CheckForActualFilePath(state, path: Path, context: str) -> Optional[Path]: return None

class ErrorObjectHeader: pass

class Util:
    @staticmethod
    def makeUPPER(s: str) -> str: return s.upper()
    @staticmethod
    def SameString(a: str, b: str) -> bool: return a.upper() == b.upper()
    @staticmethod
    def FindItemInList(name: str, items: list) -> int: return 0

class Node:
    SensedNodeFlagValue = -999.0

class Constant:
    Pi = 3.141592653589793

class OutputProcessor:
    class TimeStepType: System = "System"
    class StoreType: Average = "Average"
