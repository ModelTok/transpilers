/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from math import cos, sqrt, pow, fabs, atan, cbrt

var cos_map = Dict[Float, Float]()
var pow025_map = Dict[Float, Float]()
var pow089_map = Dict[Float, Float]()
var pow0617_map = Dict[Float, Float]()

struct Memo:
    @staticmethod
    def cos(x: Float) -> Float:
        if x in cos_map:
            return cos_map[x]
        else:
            var val = math.cos(x)
            cos_map[x] = val
            return val

    @staticmethod
    def pow025(x: Float) -> Float:
        if x in pow025_map:
            return pow025_map[x]
        else:
            var val = math.sqrt(math.sqrt(x))
            pow025_map[x] = val
            return val

    @staticmethod
    def pow089(x: Float) -> Float:
        if x in pow089_map:
            return pow089_map[x]
        else:
            var val = math.pow(x, 0.89)
            pow089_map[x] = val
            return val

    @staticmethod
    def pow0617(x: Float) -> Float:
        if x in pow0617_map:
            return pow0617_map[x]
        else:
            var val = math.pow(x, 0.617)
            pow0617_map[x] = val
            return val

struct Kiva:
    static let PI = 4.0 * math.atan(1.0)
    static let SIGMA = 5.67 * 1e-8   // [W/m2-K4]

    @staticmethod
    def cbrt_a(x: Float) -> Float:
        # Note: original uses bit manipulation; replaced with math.cbrt
        return math.cbrt(x)

    @staticmethod
    def getMoWiTTForcedTerm(cosTilt: Float, azimuth: Float, windDir: Float, windSpeed: Float) -> Float:
        if isWindward(cosTilt, azimuth, windDir):
            return 3.26 * Memo.pow089(windSpeed)
        else:
            return 3.55 * Memo.pow0617(windSpeed)

    @staticmethod
    def getDOE2ConvectionCoeff(Tsurf: Float, Tamb: Float, hfTerm: Float, roughness: Float,
                              cosTilt: Float) -> Float:
        /* Based on the DOE-2 convection model as used in EnergyPlus
         *
         * Roughness factors:
         * Very Rough = 2.17
         * Rough = 1.67
         * Medium Rough = 1.52
         * Medium Smooth = 1.13
         * Smooth = 1.11
         * Very Smooth = 1.0
         *
         * These values correspond roughly to the relief in milimeters.  We ask
         * for rougness in meters instead, so we multiply by 100.
         */
        var hn: Float
        var dT3rd = Kiva.cbrt_a(math.fabs(Tsurf - Tamb))
        if cosTilt == 0.0:
            hn = 1.31 * dT3rd
        elif (cosTilt < 0.0 and Tsurf < Tamb) or (cosTilt > 0.0 and Tsurf > Tamb):
            hn = 9.482 * dT3rd / (7.283 - math.fabs(cosTilt))
        else: /*if ((cosTilt < 0.0 && Tsurf > Tamb) ||
                (cosTilt > 0.0 && Tsurf < Tamb)) */
        {
            hn = 1.810 * dT3rd / (1.382 + math.fabs(cosTilt))
        }
        var hcGlass = math.sqrt(hn * hn + hfTerm * hfTerm)
        var rf = 1 + roughness / 0.004   // convert meters to milimeters
        var hf = rf * (hcGlass - hn)
        return hn + hf

    @staticmethod
    def isWindward(cosTilt: Float, azimuth: Float, windDirection: Float) -> bool:
        if math.fabs(cosTilt) < 0.98:
            var diff = math.fabs(windDirection - azimuth)
            if (diff - Kiva.PI) > 0.001:
                diff -= 2 * Kiva.PI
            if math.fabs((diff) - 100.0 * Kiva.PI / 180.0) > 0.001:
                return False
            else:
                return True
        else:
            return True

    @staticmethod
    def getExteriorIRCoeff(eSurf: Float, Tsurf: Float, Tamb: Float, Fqtr: Float) -> Float:
        return eSurf * Kiva.SIGMA * (Tamb * Tamb * Fqtr * Fqtr + Tsurf * Tsurf) * (Tamb * Fqtr + Tsurf)

    @staticmethod
    def getEffectiveExteriorViewFactor(eSky: Float, tilt: Float) -> Float:
        var Fsky = 0.5 * (1.0 + Memo.cos(tilt))
        var beta = Memo.cos(tilt * 0.5)
        return Fsky * beta * (eSky - 1.0) + 1.0

    @staticmethod
    def getSimpleInteriorIRCoeff(eSurf: Float, Tsurf: Float, Trad: Float) -> Float:
        return eSurf * Kiva.SIGMA * (Trad * Trad + Tsurf * Tsurf) * (Trad + Tsurf)