from math import acos, sqrt, asin, sin, cos, pow
from WCECommon import ConstantsData

struct ThermalPermeability:
    struct Venetian:
        @staticmethod
        def maxAngle(t_SlatSpacing: Float64, t_MatThickness: Float64) -> Float64:
            return acos(t_MatThickness / (t_SlatSpacing + t_MatThickness)) * 180 / ConstantsData.WCE_PI

        @staticmethod
        def calculateRise(t_Curvature: Float64, t_SlatWidth: Float64) -> Float64:
            let rise: Float64 = 0
            if t_Curvature > 0:
                let val: Float64 = t_Curvature * t_Curvature - t_SlatWidth * t_SlatWidth / 4
                if val < 0:
                    rise = t_SlatWidth / 2
                else:
                    let Rprime: Float64 = sqrt(val)
                    rise = t_Curvature - Rprime
            return rise

        @staticmethod
        def openness(t_TiltAngle: Float64,
                    t_SlatSpacing: Float64,
                    t_MatThickness: Float64,
                    t_SlatCurvature: Float64,
                    t_SlatWidth: Float64) -> Float64:
            let aRise: Float64 = calculateRise(t_SlatCurvature, t_SlatWidth)
            let h: Float64 = aRise > 1e-6 ? aRise else 1e-6
            let temp: Float64 = h + pow(t_SlatWidth, 2) / (4 * h)
            let Ls: Float64 = asin(t_SlatWidth / temp) * temp
            let angleMax: Float64 = maxAngle(t_SlatSpacing, t_MatThickness)
            let slatAngle: Float64 = min(abs(t_TiltAngle), angleMax)
            var cosPhi: Float64 = cos(slatAngle * ConstantsData.WCE_PI / 180)
            var sinPhi: Float64 = sin(abs(slatAngle) * ConstantsData.WCE_PI / 180)
            if (slatAngle == 90) or (slatAngle == -90):
                cosPhi = 0
            var opennessFactor: Float64 = 1 - (t_MatThickness * Ls) / ((Ls * cosPhi + t_MatThickness * sinPhi) * (t_SlatSpacing + t_MatThickness))
            if opennessFactor < 0:
                opennessFactor = 0
            return opennessFactor

    struct Perforated:
        struct Geometry:
            static let Circular: Int = 0
            static let Square: Int = 1
            static let Rectangular: Int = 2

        struct XYDimension:
            var x: Float64
            var y: Float64

            def __init__(self, x: Float64, y: Float64):
                self.x = x
                self.y = y

        @staticmethod
        def openness(t_Geometry: Int,
                    t_SpacingX: Float64,
                    t_SpacingY: Float64,
                    t_DimensionX: Float64,
                    t_DimensionY: Float64) -> Float64:
            let cellArea: Float64 = t_SpacingX * t_SpacingY
            let opennessFraction: Dict[Int, fn(Float64, Float64) -> Float64] = Dict{
                Geometry.Circular: fn(x: Float64, y: Float64) -> Float64:
                    return (x / 2) * (y / 2) * ConstantsData.WCE_PI / cellArea,
                Geometry.Square: fn(x: Float64, y: Float64) -> Float64:
                    return x * y / cellArea,
                Geometry.Rectangular: fn(x: Float64, y: Float64) -> Float64:
                    return x * y / cellArea
            }
            return opennessFraction[t_Geometry](t_DimensionX, t_DimensionY)

        @staticmethod
        def diameterToXYDimension(diameter: Float64) -> XYDimension:
            return XYDimension{diameter, diameter}

    struct Woven:
        @staticmethod
        def openness(t_Diameter: Float64, t_Spacing: Float64) -> Float64:
            var opennessFraction: Float64 = (t_Spacing - t_Diameter) * (t_Spacing - t_Diameter) / (t_Spacing * t_Spacing)
            if opennessFraction < 0:
                opennessFraction = 0
            return opennessFraction