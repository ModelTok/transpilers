"""
EnergyPlus CurveManager module - Mojo port.
Manages performance curves and table lookups for HVAC equipment.
"""

from collections import Dict, List
from math import sqrt, exp, erf, log10, pow, copysign, pi
import sys


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


struct CurveType:
    """Enum for curve types"""
    alias Invalid = -1
    alias Linear = 0
    alias Quadratic = 1
    alias BiQuadratic = 2
    alias Cubic = 3
    alias QuadraticLinear = 4
    alias BiCubic = 5
    alias TriQuadratic = 6
    alias Exponent = 7
    alias Quartic = 8
    alias FanPressureRise = 9
    alias ExponentialSkewNormal = 10
    alias Sigmoid = 11
    alias RectangularHyperbola1 = 12
    alias RectangularHyperbola2 = 13
    alias ExponentialDecay = 14
    alias DoubleExponentialDecay = 15
    alias QuadLinear = 16
    alias QuintLinear = 17
    alias CubicLinear = 18
    alias ChillerPartLoadWithLift = 19
    alias BtwxtTableLookup = 20
    alias Num = 21


fn get_curve_object_names() -> List[String]:
    var names = List[String]()
    names.append("Curve:Linear")
    names.append("Curve:Quadratic")
    names.append("Curve:Biquadratic")
    names.append("Curve:Cubic")
    names.append("Curve:QuadLinear")
    names.append("Curve:Bicubic")
    names.append("Curve:Triquadratic")
    names.append("Curve:Exponent")
    names.append("Curve:Quartic")
    names.append("Curve:FanPressureRise")
    names.append("Curve:ExponentialSkewNormal")
    names.append("Curve:Sigmoid")
    names.append("Curve:RectangularHyperbola1")
    names.append("Curve:RectangularHyperbola2")
    names.append("Curve:ExponentialDecay")
    names.append("Curve:DoubleExponentialDecay")
    names.append("Curve:QuadraticLinear")
    names.append("Curve:QuintLinear")
    names.append("Curve:CubicLinear")
    names.append("Curve:ChillerPartLoadWithLift")
    names.append("Table:Lookup")
    return names


struct Limits:
    """Limits struct for curve input/output bounds"""
    var min: F64
    var max: F64
    var minPresent: Bool
    var maxPresent: Bool

    fn __init__(inout self):
        self.min = 0.0
        self.max = 0.0
        self.minPresent = False
        self.maxPresent = False


struct Curve:
    """Performance curve data structure"""
    var Name: String
    var Num: Int32
    var curveType: Int32
    var TableIndex: Int32
    var numDims: Int32
    var GridValueIndex: Int32
    var contextString: String
    var coeff: InlineArray[F64, 27]
    var inputs: InlineArray[F64, 6]
    var inputLimits: InlineArray[Limits, 6]
    var output: F64
    var outputLimits: Limits
    var EMSOverrideOn: Bool
    var EMSOverrideCurveValue: F64

    fn __init__(inout self):
        self.Name = ""
        self.Num = 0
        self.curveType = CurveType.Invalid
        self.TableIndex = 0
        self.numDims = 0
        self.GridValueIndex = 0
        self.contextString = ""
        self.coeff = InlineArray[F64, 27](fill=0.0)
        self.inputs = InlineArray[F64, 6](fill=0.0)
        var i: Int32 = 0
        while i < 6:
            self.inputLimits[i] = Limits()
            i += 1
        self.output = 0.0
        self.outputLimits = Limits()
        self.EMSOverrideOn = False
        self.EMSOverrideCurveValue = 0.0

    fn value(inout self, state: EnergyPlusData, args: VariadicList[F64]) -> F64:
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
            return 0.0

    fn _value_1(inout self, state: EnergyPlusData, V1: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        var V1_clamp = V1
        if V1_clamp > self.inputLimits[0].max:
            V1_clamp = self.inputLimits[0].max
        if V1_clamp < self.inputLimits[0].min:
            V1_clamp = self.inputLimits[0].min
        var Val: F64 = 0.0

        if self.curveType == CurveType.Linear:
            Val = self.coeff[0] + V1_clamp * self.coeff[1]
        elif self.curveType == CurveType.Quadratic:
            Val = self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * self.coeff[2])
        elif self.curveType == CurveType.Cubic:
            Val = self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * (self.coeff[2] + V1_clamp * self.coeff[3]))
        elif self.curveType == CurveType.Quartic:
            Val = self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * (self.coeff[2] + V1_clamp * (self.coeff[3] + V1_clamp * self.coeff[4])))
        elif self.curveType == CurveType.Exponent:
            Val = self.coeff[0] + self.coeff[1] * pow(V1_clamp, self.coeff[2])
        elif self.curveType == CurveType.ExponentialSkewNormal:
            var CoeffZ1 = (V1_clamp - self.coeff[0]) / self.coeff[1]
            var CoeffZ2 = (self.coeff[3] * V1_clamp * exp(self.coeff[2] * V1_clamp) - self.coeff[0]) / self.coeff[1]
            var CoeffZ3 = -self.coeff[0] / self.coeff[1]
            var sqrt_2_inv = 1.0 / sqrt(2.0)
            var Numer = exp(-0.5 * (CoeffZ1 * CoeffZ1)) * (1.0 + copysign(1.0, CoeffZ2) * erf(abs(CoeffZ2) * sqrt_2_inv))
            var Denom = exp(-0.5 * (CoeffZ3 * CoeffZ3)) * (1.0 + copysign(1.0, CoeffZ3) * erf(abs(CoeffZ3) * sqrt_2_inv))
            Val = Numer / Denom
        elif self.curveType == CurveType.Sigmoid:
            var CurveValueExp = exp((self.coeff[2] - V1_clamp) / self.coeff[3])
            Val = self.coeff[0] + self.coeff[1] / pow(1.0 + CurveValueExp, self.coeff[4])
        elif self.curveType == CurveType.RectangularHyperbola1:
            var Numer = self.coeff[0] * V1_clamp
            var Denom = self.coeff[1] + V1_clamp
            Val = (Numer / Denom) + self.coeff[2]
        elif self.curveType == CurveType.RectangularHyperbola2:
            var Numer = self.coeff[0] * V1_clamp
            var Denom = self.coeff[1] + V1_clamp
            Val = (Numer / Denom) + (self.coeff[2] * V1_clamp)
        elif self.curveType == CurveType.ExponentialDecay:
            Val = self.coeff[0] + self.coeff[1] * exp(self.coeff[2] * V1_clamp)
        elif self.curveType == CurveType.DoubleExponentialDecay:
            Val = self.coeff[0] + self.coeff[1] * exp(self.coeff[2] * V1_clamp) + self.coeff[3] * exp(self.coeff[4] * V1_clamp)
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1_clamp)
        else:
            Val = self.valueFallback(state, V1_clamp, 0.0, 0.0, 0.0, 0.0)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn _value_2(inout self, state: EnergyPlusData, V1: F64, V2: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        var V1_clamp = V1
        var V2_clamp = V2
        if V1_clamp > self.inputLimits[0].max:
            V1_clamp = self.inputLimits[0].max
        if V1_clamp < self.inputLimits[0].min:
            V1_clamp = self.inputLimits[0].min
        if V2_clamp > self.inputLimits[1].max:
            V2_clamp = self.inputLimits[1].max
        if V2_clamp < self.inputLimits[1].min:
            V2_clamp = self.inputLimits[1].min
        var Val: F64 = 0.0

        if self.curveType == CurveType.FanPressureRise:
            Val = V1_clamp * (self.coeff[0] * V1_clamp + self.coeff[1] + self.coeff[2] * sqrt(V2_clamp)) + self.coeff[3] * V2_clamp
        elif self.curveType == CurveType.BiQuadratic:
            Val = (self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * self.coeff[2]) + 
                   V2_clamp * (self.coeff[3] + V2_clamp * self.coeff[4]) + V1_clamp * V2_clamp * self.coeff[5])
        elif self.curveType == CurveType.QuadraticLinear:
            Val = ((self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * self.coeff[2])) + 
                   (self.coeff[3] + V1_clamp * (self.coeff[4] + V1_clamp * self.coeff[5])) * V2_clamp)
        elif self.curveType == CurveType.CubicLinear:
            Val = ((self.coeff[0] + V1_clamp * (self.coeff[1] + V1_clamp * (self.coeff[2] + V1_clamp * self.coeff[3]))) + 
                   (self.coeff[4] + V1_clamp * self.coeff[5]) * V2_clamp)
        elif self.curveType == CurveType.BiCubic:
            Val = (self.coeff[0] + V1_clamp * self.coeff[1] + V1_clamp * V1_clamp * self.coeff[2] + V2_clamp * self.coeff[3] + 
                   V2_clamp * V2_clamp * self.coeff[4] + V1_clamp * V2_clamp * self.coeff[5] + V1_clamp * V1_clamp * V1_clamp * self.coeff[6] + 
                   V2_clamp * V2_clamp * V2_clamp * self.coeff[7] + V1_clamp * V1_clamp * V2_clamp * self.coeff[8] + V1_clamp * V2_clamp * V2_clamp * self.coeff[9])
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1_clamp, V2_clamp)
        else:
            Val = self.valueFallback(state, V1_clamp, V2_clamp, 0.0, 0.0, 0.0)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn _value_3(inout self, state: EnergyPlusData, V1: F64, V2: F64, V3: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        var V1_clamp = clamp_value(V1, self.inputLimits[0])
        var V2_clamp = clamp_value(V2, self.inputLimits[1])
        var V3_clamp = clamp_value(V3, self.inputLimits[2])
        var Val: F64 = 0.0

        if self.curveType == CurveType.ChillerPartLoadWithLift:
            Val = (self.coeff[0] + self.coeff[1] * V1_clamp + self.coeff[2] * V1_clamp * V1_clamp + self.coeff[3] * V2_clamp + 
                   self.coeff[4] * V2_clamp * V2_clamp + self.coeff[5] * V1_clamp * V2_clamp + self.coeff[6] * V1_clamp * V1_clamp * V1_clamp + 
                   self.coeff[7] * V2_clamp * V2_clamp * V2_clamp + self.coeff[8] * V1_clamp * V1_clamp * V2_clamp + self.coeff[9] * V1_clamp * V2_clamp * V2_clamp + 
                   self.coeff[10] * V1_clamp * V1_clamp * V2_clamp * V2_clamp + self.coeff[11] * V3_clamp * V2_clamp * V2_clamp * V2_clamp)
        elif self.curveType == CurveType.TriQuadratic:
            var V1s = V1_clamp * V1_clamp
            var V2s = V2_clamp * V2_clamp
            var V3s = V3_clamp * V3_clamp
            Val = (self.coeff[0] + self.coeff[1] * V1s + self.coeff[2] * V1_clamp + self.coeff[3] * V2s + self.coeff[4] * V2_clamp + self.coeff[5] * V3s + self.coeff[6] * V3_clamp + 
                   self.coeff[7] * V1s * V2s + self.coeff[8] * V1_clamp * V2_clamp + self.coeff[9] * V1_clamp * V2s + self.coeff[10] * V1s * V2_clamp + 
                   self.coeff[11] * V1s * V3s + self.coeff[12] * V1_clamp * V3_clamp + self.coeff[13] * V1_clamp * V3s + self.coeff[14] * V1s * V3_clamp + 
                   self.coeff[15] * V2s * V3s + self.coeff[16] * V2_clamp * V3_clamp + self.coeff[17] * V2_clamp * V3s + self.coeff[18] * V2s * V3_clamp + 
                   self.coeff[19] * V1s * V2s * V3s + self.coeff[20] * V1s * V2s * V3_clamp + self.coeff[21] * V1s * V2_clamp * V3s + 
                   self.coeff[22] * V1_clamp * V2s * V3s + self.coeff[23] * V1s * V2_clamp * V3_clamp + self.coeff[24] * V1_clamp * V2s * V3_clamp + 
                   self.coeff[25] * V1_clamp * V2_clamp * V3s + self.coeff[26] * V1_clamp * V2_clamp * V3_clamp)
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1_clamp, V2_clamp, V3_clamp)
        else:
            Val = self.valueFallback(state, V1_clamp, V2_clamp, V3_clamp, 0.0, 0.0)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn _value_4(inout self, state: EnergyPlusData, V1: F64, V2: F64, V3: F64, V4: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        var V1_clamp = clamp_value(V1, self.inputLimits[0])
        var V2_clamp = clamp_value(V2, self.inputLimits[1])
        var V3_clamp = clamp_value(V3, self.inputLimits[2])
        var V4_clamp = clamp_value(V4, self.inputLimits[3])
        var Val: F64 = 0.0

        if self.curveType == CurveType.QuadLinear:
            Val = self.coeff[0] + V1_clamp * self.coeff[1] + V2_clamp * self.coeff[2] + V3_clamp * self.coeff[3] + V4_clamp * self.coeff[4]
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1_clamp, V2_clamp, V3_clamp, V4_clamp)
        else:
            Val = self.valueFallback(state, V1_clamp, V2_clamp, V3_clamp, V4_clamp, 0.0)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn _value_5(inout self, state: EnergyPlusData, V1: F64, V2: F64, V3: F64, V4: F64, V5: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        self.inputs[4] = V5
        var V1_clamp = clamp_value(V1, self.inputLimits[0])
        var V2_clamp = clamp_value(V2, self.inputLimits[1])
        var V3_clamp = clamp_value(V3, self.inputLimits[2])
        var V4_clamp = clamp_value(V4, self.inputLimits[3])
        var V5_clamp = clamp_value(V5, self.inputLimits[4])
        var Val: F64 = 0.0

        if self.curveType == CurveType.QuintLinear:
            Val = self.coeff[0] + V1_clamp * self.coeff[1] + V2_clamp * self.coeff[2] + V3_clamp * self.coeff[3] + V4_clamp * self.coeff[4] + V5_clamp * self.coeff[5]
        elif self.curveType == CurveType.BtwxtTableLookup:
            Val = self.BtwxtTableInterpolation(state, V1_clamp, V2_clamp, V3_clamp, V4_clamp, V5_clamp)
        else:
            Val = self.valueFallback(state, V1_clamp, V2_clamp, V3_clamp, V4_clamp, V5_clamp)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn _value_6(inout self, state: EnergyPlusData, V1: F64, V2: F64, V3: F64, V4: F64, V5: F64, V6: F64) -> F64:
        commonEnvironInit(state)
        self.inputs[0] = V1
        self.inputs[1] = V2
        self.inputs[2] = V3
        self.inputs[3] = V4
        self.inputs[4] = V5
        self.inputs[5] = V6
        var V1_clamp = clamp_value(V1, self.inputLimits[0])
        var V2_clamp = clamp_value(V2, self.inputLimits[1])
        var V3_clamp = clamp_value(V3, self.inputLimits[2])
        var V4_clamp = clamp_value(V4, self.inputLimits[3])
        var V5_clamp = clamp_value(V5, self.inputLimits[4])
        var V6_clamp = clamp_value(V6, self.inputLimits[5])

        var Val = self.BtwxtTableInterpolation(state, V1_clamp, V2_clamp, V3_clamp, V4_clamp, V5_clamp, V6_clamp)

        if self.outputLimits.minPresent and Val < self.outputLimits.min:
            Val = self.outputLimits.min
        if self.outputLimits.maxPresent and Val > self.outputLimits.max:
            Val = self.outputLimits.max
        if self.EMSOverrideOn:
            Val = self.EMSOverrideCurveValue

        self.output = Val
        return Val

    fn valueFallback(inout self, state: EnergyPlusData, V1: F64, V2: F64, V3: F64, V4: F64, V5: F64) -> F64:
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
            var V1s = V1 * V1
            var V2s = V2 * V2
            var V3s = V3 * V3
            return (self.coeff[0] + self.coeff[1] * V1s + self.coeff[2] * V1 + self.coeff[3] * V2s + self.coeff[4] * V2 + self.coeff[5] * V3s + self.coeff[6] * V3 + 
                    self.coeff[7] * V1s * V2s + self.coeff[8] * V1 * V2 + self.coeff[9] * V1 * V2s + self.coeff[10] * V1s * V2 + 
                    self.coeff[11] * V1s * V3s + self.coeff[12] * V1 * V3 + self.coeff[13] * V1 * V3s + self.coeff[14] * V1s * V3 + 
                    self.coeff[15] * V2s * V3s + self.coeff[16] * V2 * V3 + self.coeff[17] * V2 * V3s + self.coeff[18] * V2s * V3 + 
                    self.coeff[19] * V1s * V2s * V3s + self.coeff[20] * V1s * V2s * V3 + self.coeff[21] * V1s * V2 * V3s + 
                    self.coeff[22] * V1 * V2s * V3s + self.coeff[23] * V1s * V2 * V3 + self.coeff[24] * V1 * V2s * V3 + 
                    self.coeff[25] * V1 * V2 * V3s + self.coeff[26] * V1 * V2 * V3)
        elif self.curveType == CurveType.Exponent:
            return self.coeff[0] + self.coeff[1] * pow(V1, self.coeff[2])
        elif self.curveType == CurveType.FanPressureRise:
            return V1 * (self.coeff[0] * V1 + self.coeff[1] + self.coeff[2] * sqrt(V2)) + self.coeff[3] * V2
        elif self.curveType == CurveType.ExponentialSkewNormal:
            var CoeffZ1 = (V1 - self.coeff[0]) / self.coeff[1]
            var CoeffZ2 = (self.coeff[3] * V1 * exp(self.coeff[2] * V1) - self.coeff[0]) / self.coeff[1]
            var CoeffZ3 = -self.coeff[0] / self.coeff[1]
            var sqrt_2_inv = 1.0 / sqrt(2.0)
            var CurveValueNumer = exp(-0.5 * (CoeffZ1 * CoeffZ1)) * (1.0 + copysign(1.0, CoeffZ2) * erf(abs(CoeffZ2) * sqrt_2_inv))
            var CurveValueDenom = exp(-0.5 * (CoeffZ3 * CoeffZ3)) * (1.0 + copysign(1.0, CoeffZ3) * erf(abs(CoeffZ3) * sqrt_2_inv))
            return CurveValueNumer / CurveValueDenom
        elif self.curveType == CurveType.Sigmoid:
            var CurveValueExp = exp((self.coeff[2] - V1) / self.coeff[3])
            return self.coeff[0] + self.coeff[1] / pow(1.0 + CurveValueExp, self.coeff[4])
        elif self.curveType == CurveType.RectangularHyperbola1:
            var CurveValueNumer = self.coeff[0] * V1
            var CurveValueDenom = self.coeff[1] + V1
            return (CurveValueNumer / CurveValueDenom) + self.coeff[2]
        elif self.curveType == CurveType.RectangularHyperbola2:
            var CurveValueNumer = self.coeff[0] * V1
            var CurveValueDenom = self.coeff[1] + V1
            return (CurveValueNumer / CurveValueDenom) + (self.coeff[2] * V1)
        elif self.curveType == CurveType.ExponentialDecay:
            return self.coeff[0] + self.coeff[1] * exp(self.coeff[2] * V1)
        elif self.curveType == CurveType.DoubleExponentialDecay:
            return self.coeff[0] + self.coeff[1] * exp(self.coeff[2] * V1) + self.coeff[3] * exp(self.coeff[4] * V1)
        else:
            return 0.0

    fn BtwxtTableInterpolation(inout self, state: EnergyPlusData, args: VariadicList[F64]) -> F64:
        var target = List[F64]()
        var i: Int32 = 0
        while i < len(args):
            target.append(args[i])
            i += 1
        return state.dataCurveManager.btwxtManager.getGridValue(self.TableIndex, self.GridValueIndex, target)


struct TableFile:
    """Table file data structure"""
    var filePath: Optional[Path]
    var contents: List[List[String]]
    var arrays: Dict[Tuple[Int32, Int32], List[F64]]
    var numRows: Int32
    var numColumns: Int32

    fn __init__(inout self):
        self.filePath = None
        self.contents = List[List[String]]()
        self.arrays = Dict[Tuple[Int32, Int32], List[F64]]()
        self.numRows = 0
        self.numColumns = 0

    fn load(inout self, state: EnergyPlusData, path: Path) -> Bool:
        self.filePath = path
        # Placeholder for file loading logic
        return False

    fn getArray(inout self, state: EnergyPlusData, colAndRow: Tuple[Int32, Int32]) -> List[F64]:
        # Placeholder for array retrieval
        return List[F64]()


struct BtwxtManager:
    """Container for Btwxt N-d Objects"""
    var gridMap: Dict[String, Int32]
    var grids: List
    var independentVarRefs: Dict[String, DictOf]
    var tableFiles: Dict[Path, TableFile]
    var btwxt_logger: Optional[Object]

    fn __init__(inout self):
        self.gridMap = Dict[String, Int32]()
        self.grids = List()
        self.independentVarRefs = Dict[String, DictOf]()
        self.tableFiles = Dict[Path, TableFile]()
        self.btwxt_logger = None

    fn addGrid(inout self, indVarListName: String, grid: GridAxis) -> Int32:
        self.grids.append(grid)
        var idx = Int32(len(self.grids)) - 1
        self.gridMap[indVarListName] = idx
        return idx

    fn setLoggingContext(inout self, context: Tuple[EnergyPlusData, String]):
        pass

    fn normalizeGridValues(inout self, gridIndex: Int32, outputIndex: Int32, target: List[F64], scalar: F64 = 1.0) -> F64:
        return 0.0

    fn addOutputValues(inout self, gridIndex: Int32, values: List[F64]) -> Int32:
        return 0

    fn getGridIndex(inout self, state: EnergyPlusData, indVarListName: String) -> Tuple[Int32, Bool]:
        return (0, True)

    fn getNumGridDims(inout self, gridIndex: Int32) -> Int32:
        return 0

    fn getGridValue(inout self, gridIndex: Int32, outputIndex: Int32, target: List[F64]) -> F64:
        return 0.0

    fn clear(inout self):
        pass


struct CurveManagerData:
    """Curve manager state data"""
    var CurveValueMyBeginTimeStepFlag: Bool
    var FrictionFactorErrorHasOccurred: Bool
    var showFallbackMessage: Bool
    var curves: List[Optional[Curve]]
    var curveMap: Dict[String, Int32]
    var btwxtManager: BtwxtManager

    fn __init__(inout self):
        self.CurveValueMyBeginTimeStepFlag = False
        self.FrictionFactorErrorHasOccurred = False
        self.showFallbackMessage = True
        self.curves = List[Optional[Curve]]()
        self.curveMap = Dict[String, Int32]()
        self.btwxtManager = BtwxtManager()

    fn clear_state(inout self):
        self.curves.clear()
        self.curveMap.clear()


fn clamp_value(value: F64, limits: Limits) -> F64:
    if value > limits.max:
        return limits.max
    if value < limits.min:
        return limits.min
    return value


fn commonEnvironInit(inout state: EnergyPlusData):
    if state.dataGlobal.BeginEnvrnFlag and state.dataCurveManager.CurveValueMyBeginTimeStepFlag:
        ResetPerformanceCurveOutput(state)
        state.dataCurveManager.CurveValueMyBeginTimeStepFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataCurveManager.CurveValueMyBeginTimeStepFlag = True


fn ResetPerformanceCurveOutput(inout state: EnergyPlusData):
    var i: Int32 = 0
    while i < len(state.dataCurveManager.curves):
        var c = state.dataCurveManager.curves[i]
        if c is not None:
            c.output = Node.SensedNodeFlagValue
            var j: Int32 = 0
            while j < 6:
                c.inputs[j] = Node.SensedNodeFlagValue
                j += 1
        i += 1


fn CurveValue(inout state: EnergyPlusData, CurveIndex: Int32, args: VariadicList[F64]) -> F64:
    if CurveIndex <= 0 or CurveIndex > len(state.dataCurveManager.curves):
        return 0.0
    var curve = state.dataCurveManager.curves[CurveIndex - 1]
    if curve is None:
        return 0.0
    return curve.value(state, args)


fn AddCurve(inout state: EnergyPlusData, name: String) -> Curve:
    var curve = Curve()
    curve.Name = name
    state.dataCurveManager.curves.append(curve)
    curve.Num = Int32(len(state.dataCurveManager.curves))
    state.dataCurveManager.curveMap[Util.makeUPPER(curve.Name)] = curve.Num
    return curve


fn GetCurveInput(inout state: EnergyPlusData):
    pass


fn GetCurveInputData(inout state: EnergyPlusData):
    pass


fn InitCurveReporting(inout state: EnergyPlusData):
    pass


fn IsCurveInputTypeValid(InInputType: String) -> Bool:
    var inputTypes = get_input_types()
    if len(InInputType) == 0:
        return True
    return InInputType.upper() in inputTypes


fn get_input_types() -> List[String]:
    var types = List[String]()
    types.append("DIMENSIONLESS")
    types.append("TEMPERATURE")
    types.append("PRESSURE")
    types.append("VOLUMETRICFLOW")
    types.append("MASSFLOW")
    types.append("POWER")
    types.append("DISTANCE")
    types.append("WAVELENGTH")
    types.append("ANGLE")
    types.append("VOLUMETRICFLOWPERPOWER")
    return types


fn IsCurveOutputTypeValid(InOutputType: String) -> Bool:
    var outputTypes = get_output_types()
    return Util.makeUPPER(InOutputType) in outputTypes


fn get_output_types() -> List[String]:
    var types = List[String]()
    types.append("DIMENSIONLESS")
    types.append("PRESSURE")
    types.append("TEMPERATURE")
    types.append("CAPACITY")
    types.append("POWER")
    return types


fn CheckCurveDims(inout state: EnergyPlusData, CurveIndex: Int32, validDims: List[Int32], 
                  routineName: String, objectType: String, objectName: String, curveFieldText: String) -> Bool:
    if CurveIndex <= 0 or CurveIndex > len(state.dataCurveManager.curves):
        return True
    var thisCurve = state.dataCurveManager.curves[CurveIndex - 1]
    if thisCurve is None:
        return True
    var curveDim = thisCurve.numDims
    var i: Int32 = 0
    while i < len(validDims):
        if curveDim == validDims[i]:
            return False
        i += 1
    return True


fn GetCurveName(inout state: EnergyPlusData, CurveIndex: Int32) -> String:
    if CurveIndex > 0 and CurveIndex <= len(state.dataCurveManager.curves):
        var curve = state.dataCurveManager.curves[CurveIndex - 1]
        if curve is not None:
            return curve.Name
    return ""


fn GetCurveIndex(state: EnergyPlusData, CurveName: String) -> Int32:
    var key = Util.makeUPPER(CurveName)
    if key in state.dataCurveManager.curveMap:
        return state.dataCurveManager.curveMap[key]
    return 0


fn CalculateMoodyFrictionFactor(inout state: EnergyPlusData, ReynoldsNumber: F64, RoughnessRatio: F64) -> F64:
    if ReynoldsNumber == 0.0 or RoughnessRatio == 0.0:
        return 0.0
    var Term1 = pow(RoughnessRatio / 3.7, 1.11)
    var Term2 = 6.9 / ReynoldsNumber
    var Term3 = -1.8 * log10(Term1 + Term2)
    if Term3 != 0.0:
        return pow(Term3, -2.0)
    if not state.dataCurveManager.FrictionFactorErrorHasOccurred:
        state.dataCurveManager.FrictionFactorErrorHasOccurred = True
    return 0.04


# Stub external functions
fn ShowMessage(state: EnergyPlusData, msg: String): pass
fn ShowSevereError(state: EnergyPlusData, msg: String): pass
fn ShowContinueError(state: EnergyPlusData, msg: String): pass
fn ShowFatalError(state: EnergyPlusData, msg: String): pass
fn ShowWarningError(state: EnergyPlusData, msg: String): pass
fn ShowSevereDuplicateName(state: EnergyPlusData, eoh: ErrorObjectHeader): pass
fn SetupOutputVariable(state: EnergyPlusData, varName: String, units: String, var: F64, timeStep: String, storeType: String, objName: String): pass
fn SetupEMSActuator(state: EnergyPlusData, typeStr: String, name: String, controlStr: String, unitsStr: String, onFlag: Bool, value: F64): pass


struct Node:
    alias SensedNodeFlagValue = -999.0


struct Util:
    @staticmethod
    fn makeUPPER(s: String) -> String:
        return s.upper()

    @staticmethod
    fn SameString(a: String, b: String) -> Bool:
        return a.upper() == b.upper()


struct EnergyPlusData:
    var dataGlobal: Object
    var dataCurveManager: CurveManagerData


struct ErrorObjectHeader:
    var routineName: String
    var objectType: String
    var objectName: String


struct Path: pass
struct GridAxis: pass
struct DictOf: pass
struct Optional[T]: pass
