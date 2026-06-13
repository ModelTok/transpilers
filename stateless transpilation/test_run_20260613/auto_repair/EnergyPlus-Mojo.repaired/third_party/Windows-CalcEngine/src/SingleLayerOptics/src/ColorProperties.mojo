from WCECommon import CSeries, PropertySimple, Side, Scattering, SquareMatrix
from IScatteringLayer import IScatteringLayer
from List import List
from Math import pow as math_pow

struct Trichromatic:
    var X: Float64
    var Y: Float64
    var Z: Float64

    def __init__(inout self, X: Float64, Y: Float64, Z: Float64):
        self.X = X
        self.Y = Y
        self.Z = Z

struct aRGB:
    var R: Int
    var G: Int
    var B: Int

    def __init__(inout self, R: Int, G: Int, B: Int):
        self.R = R
        self.G = G
        self.B = B

struct CIE_LAB:
    var L: Float64
    var a: Float64
    var b: Float64

    def __init__(inout self, L: Float64, A: Float64, B: Float64):
        self.L = L
        self.a = A
        self.b = B

class ColorProperties:
    var m_LayerX: Pointer[IScatteringLayer]
    var m_LayerY: Pointer[IScatteringLayer]
    var m_LayerZ: Pointer[IScatteringLayer]
    var m_SDx: Float64
    var m_SDy: Float64
    var m_SDz: Float64

    def __init__(
        inout self,
        owned layerX: Pointer[IScatteringLayer],
        owned layerY: Pointer[IScatteringLayer],
        owned layerZ: Pointer[IScatteringLayer],
        t_Source: CSeries,
        t_DetectorX: CSeries,
        t_DetectorY: CSeries,
        t_DetectorZ: CSeries,
        t_wavelengths: List[Float64] = List[Float64]()
    ):
        self.m_LayerX = layerX
        self.m_LayerY = layerY
        self.m_LayerZ = layerZ
        var wavelengths: List[Float64] = self.m_LayerX[].getWavelengths()
        if len(t_wavelengths) > 0:
            wavelengths = t_wavelengths
        var aSolar = t_Source
        var DX = t_DetectorX
        var DY = t_DetectorY
        var DZ = t_DetectorZ
        aSolar = aSolar.interpolate(wavelengths)
        DX = DX.interpolate(wavelengths)
        DY = DY.interpolate(wavelengths)
        DZ = DZ.interpolate(wavelengths)
        self.m_SDx = (aSolar * DX).sum(self.m_LayerX[].getMinLambda(), self.m_LayerX[].getMaxLambda())
        self.m_SDy = (aSolar * DY).sum(self.m_LayerX[].getMinLambda(), self.m_LayerX[].getMaxLambda())
        self.m_SDz = (aSolar * DZ).sum(self.m_LayerX[].getMinLambda(), self.m_LayerX[].getMaxLambda())

    def getTrichromatic(
        inout self,
        t_Property: PropertySimple,
        t_Side: Side,
        t_Scattering: Scattering,
        t_Theta: Float64 = 0.0,
        t_Phi: Float64 = 0.0
    ) -> Trichromatic:
        var X = self.m_SDx / self.m_SDy * 100.0 * self.m_LayerX[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        var Y = 100.0 * self.m_LayerY[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        var Z = self.m_SDz / self.m_SDy * 100.0 * self.m_LayerZ[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        return Trichromatic(X, Y, Z)

    def getRGB(
        inout self,
        t_Property: PropertySimple,
        t_Side: Side,
        t_Scattering: Scattering,
        t_Theta: Float64 = 0.0,
        t_Phi: Float64 = 0.0
    ) -> aRGB:
        var tri = self.getTrichromatic(t_Property, t_Side, t_Scattering, t_Theta, t_Phi)
        var X = 0.0125313 * (tri.X - 0.1901)
        var Y = 0.0125313 * (tri.Y - 0.2)
        var Z = 0.0125313 * (tri.Z - 0.2178)
        var T = SquareMatrix(List[List[Float64]]([
            List[Float64]([3.2406255, -1.537208, -0.4986286]),
            List[Float64]([-0.9689307, 1.8757561, 0.0415175]),
            List[Float64]([0.0557101, -0.2040211, 1.0569959])
        ]))
        var xyz = List[Float64]([X, Y, Z])
        var mmult = T * xyz
        var testlimit: Float64 = 0.0031308
        for i in range(len(mmult)):
            var val = mmult[i]
            if val <= testlimit:
                val = val * 12.92
            else:
                val = 1.055 * math_pow(val, 1.0 / 2.4) - 0.055
            if val > 1.0:
                val = 1.0
            if val < 0.0:
                val = 0.0
            val = val * 255.0
            mmult[i] = val
        var R = Int(__lround(mmult[0]))
        var G = Int(__lround(mmult[1]))
        var B = Int(__lround(mmult[2]))
        return aRGB(R, G, B)

    def getCIE_Lab(
        inout self,
        t_Property: PropertySimple,
        t_Side: Side,
        t_Scattering: Scattering,
        t_Theta: Float64 = 0.0,
        t_Phi: Float64 = 0.0
    ) -> CIE_LAB:
        var X = self.m_LayerX[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        var Y = self.m_LayerY[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        var Z = self.m_LayerZ[].getPropertySimple(
            self.m_LayerX[].getMinLambda(),
            self.m_LayerX[].getMaxLambda(),
            t_Property,
            t_Side,
            t_Scattering,
            t_Theta,
            t_Phi
        )
        var Q = List[Float64]([X, Y, Z])
        for i in range(len(Q)):
            var val = Q[i]
            if val > math_pow(6.0 / 29.0, 3.0):
                val = math_pow(val, 1.0 / 3.0)
            else:
                val = (841.0 / 108.0) * val + 4.0 / 29.0
            Q[i] = val
        return CIE_LAB(116.0 * Q[1] - 16.0, 500.0 * (Q[0] - Q[1]), 200.0 * (Q[1] - Q[2]))

# Helper function to mimic lround (round to nearest integer, ties away from zero)
def __lround(x: Float64) -> Float64:
    if x >= 0.0:
        return Float64(Int(x + 0.5))
    else:
        return Float64(Int(x - 0.5))