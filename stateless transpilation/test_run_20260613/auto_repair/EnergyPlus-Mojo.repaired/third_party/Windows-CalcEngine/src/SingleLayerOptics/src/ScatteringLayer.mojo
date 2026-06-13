from ScatteringLayer.hpp import CScatteringLayer, CScatteringLayerIR, IScatteringLayer, EmissivityPolynomials, emissPolynomial
from LayerSingleComponent import CLayerSingleComponent
from OpticalSurface import CScatteringSurface
from BaseCell import ICellDescription
from BSDFLayer import CBSDFLayer
from MaterialDescription import CMaterial
from BSDFDirections import CBSDFHemisphere, BSDFBasis
from BSDFIntegrator import CBSDFIntegrator
from BeamDirection import CBeamDirection
from WCESpectralAveraging import SpectralAveraging
from WCECommon import CSeries, Side, PropertySimple, Scattering, ScatteringSimple, DistributionMethod, WavelengthRange, CWavelengthRange
from SpecularBSDFLayer import CSpecularBSDFLayer
from BSDFLayerMaker import CBSDFLayerMaker
from memory import Pointer
from math import pow
from utils import Vector

@value
struct CScatteringLayer(IScatteringLayer):
    var m_Surface: Map[Side, CScatteringSurface]
    var m_BSDFLayer: Pointer[CBSDFLayer]
    var m_Theta: Float64
    var m_Phi: Float64

    def __init__(inout self):
        self.m_Surface = Map[Side, CScatteringSurface]()
        self.m_BSDFLayer = Pointer[CBSDFLayer]()
        self.m_Theta = 0.0
        self.m_Phi = 0.0

    def __init__(inout self, t_Front: CScatteringSurface, t_Back: CScatteringSurface):
        self.m_Surface = Map[Side, CScatteringSurface]()
        self.m_Surface[Side.Front] = t_Front
        self.m_Surface[Side.Back] = t_Back
        self.m_BSDFLayer = Pointer[CBSDFLayer]()
        self.m_Theta = 0.0
        self.m_Phi = 0.0

    def __init__(inout self, owned t_Front: CScatteringSurface, owned t_Back: CScatteringSurface):
        self.m_Surface = Map[Side, CScatteringSurface]()
        self.m_Surface[Side.Front] = t_Front^
        self.m_Surface[Side.Back] = t_Back^
        self.m_BSDFLayer = Pointer[CBSDFLayer]()
        self.m_Theta = 0.0
        self.m_Phi = 0.0

    def __init__(inout self,
                Tf_dir_dir: Float64,
                Rf_dir_dir: Float64,
                Tb_dir_dir: Float64,
                Rb_dir_dir: Float64,
                Tf_dir_dif: Float64,
                Rf_dir_dif: Float64,
                Tb_dir_dif: Float64,
                Rb_dir_dif: Float64,
                Tf_dif_dif: Float64,
                Rf_dif_dif: Float64,
                Tb_dif_dif: Float64,
                Rb_dif_dif: Float64):
        self.m_Surface = Map[Side, CScatteringSurface]()
        self.m_Surface[Side.Front] = CScatteringSurface(
            Tf_dir_dir, Rf_dir_dir, Tf_dir_dif, Rf_dir_dif, Tf_dif_dif, Rf_dif_dif)
        self.m_Surface[Side.Back] = CScatteringSurface(
            Tb_dir_dir, Rb_dir_dir, Tb_dir_dif, Rb_dir_dif, Tb_dif_dif, Rb_dif_dif)
        self.m_BSDFLayer = Pointer[CBSDFLayer]()
        self.m_Theta = 0.0
        self.m_Phi = 0.0

    def __init__(inout self, t_Material: Pointer[CMaterial], t_Description: Pointer[ICellDescription] = Pointer[ICellDescription](), t_Method: DistributionMethod = DistributionMethod.UniformDiffuse):
        self.m_BSDFLayer = Pointer[CBSDFLayer]()
        self.m_Theta = 0.0
        self.m_Phi = 0.0
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        var aMaker = CBSDFLayerMaker(t_Material, aBSDF, t_Description, t_Method)
        self.m_BSDFLayer = aMaker.getLayer()

    @staticmethod
    def createSpecularLayer(t_Material: Pointer[CMaterial]) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getSpecularLayer(t_Material, aBSDF))

    @staticmethod
    def createPerfectlyDiffusingLayer(t_Material: Pointer[CMaterial]) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getPerfectlyDiffuseLayer(t_Material, aBSDF))

    @staticmethod
    def createWovenLayer(t_Material: Pointer[CMaterial], diameter: Float64, spacing: Float64) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getWovenLayer(t_Material, aBSDF, diameter, spacing))

    @staticmethod
    def createVenetianLayer(t_Material: Pointer[CMaterial],
                           slatWidth: Float64,
                           slatSpacing: Float64,
                           slatTiltAngle: Float64,
                           curvatureRadius: Float64,
                           numOfSlatSegments: Int,
                           method: DistributionMethod = DistributionMethod.DirectionalDiffuse,
                           isHorizontal: Bool = True) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getVenetianLayer(t_Material,
                                                                  aBSDF,
                                                                  slatWidth,
                                                                  slatSpacing,
                                                                  slatTiltAngle,
                                                                  curvatureRadius,
                                                                  numOfSlatSegments,
                                                                  method,
                                                                  isHorizontal))

    @staticmethod
    def createPerforatedCircularLayer(t_Material: Pointer[CMaterial],
                                     x: Float64,
                                     y: Float64,
                                     thickness: Float64,
                                     radius: Float64) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getCircularPerforatedLayer(t_Material, aBSDF, x, y, thickness, radius))

    @staticmethod
    def createPerforatedRectangularLayer(t_Material: Pointer[CMaterial],
                                        x: Float64,
                                        y: Float64,
                                        thickness: Float64,
                                        xHole: Float64,
                                        yHole: Float64) -> CScatteringLayer:
        var aBSDF = CBSDFHemisphere.create(BSDFBasis.Full)
        return CScatteringLayer(CBSDFLayerMaker.getRectangularPerforatedLayer(t_Material, aBSDF, x, y, thickness, xHole, yHole))

    def setSourceData(self, t_SourceData: CSeries):
        if self.m_BSDFLayer:
            self.m_BSDFLayer.setSourceData(t_SourceData)

    def setBlackBodySource(self, temperature: Float64):
        var wlFull = self.getWavelengths()
        var wl = Vector[Float64]()
        for wwl in wlFull:
            if wwl >= 5.0:
                wl.append(wwl)
        var spectrum = SpectralAveraging.BlackBodySpectrum(wl, temperature)
        var seriesSpectrum = CSeries(spectrum)
        self.setSourceData(seriesSpectrum)
        self.setWavelengths(wl)

    def getSurface(self, t_Side: Side) -> CScatteringSurface:
        if self.m_Surface.size() == 0:
            self.m_Theta = 0.0
            self.m_Phi = 0.0
            self.createResultsAtAngle(self.m_Theta, self.m_Phi)
        return self.m_Surface[t_Side]

    def getPropertySimple(self,
                         minLambda: Float64,
                         maxLambda: Float64,
                         t_Property: PropertySimple,
                         t_Side: Side,
                         t_Scattering: Scattering,
                         t_Theta: Float64 = 0.0,
                         t_Phi: Float64 = 0.0) -> Float64:
        self.checkCurrentAngles(t_Theta, t_Phi)
        var aSurface = self.getSurface(t_Side)
        return aSurface.getPropertySimple(t_Property, t_Scattering)

    def getAbsorptance(self,
                      t_Side: Side,
                      t_Scattering: ScatteringSimple,
                      t_Theta: Float64 = 0.0,
                      t_Phi: Float64 = 0.0) -> Float64:
        self.checkCurrentAngles(t_Theta, t_Phi)
        var aSurface = self.getSurface(t_Side)
        return aSurface.getAbsorptance(t_Scattering)

    def getAbsorptance(self, t_Side: Side, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0) -> Float64:
        self.checkCurrentAngles(t_Theta, t_Phi)
        var aSurface = self.getSurface(t_Side)
        return aSurface.getAbsorptance()

    def getAbsorptanceLayers(self,
                            minLambda: Float64,
                            maxLambda: Float64,
                            side: Side,
                            scattering: ScatteringSimple,
                            theta: Float64,
                            phi: Float64) -> Vector[Float64]:
        var abs = Vector[Float64]()
        abs.append(self.getAbsorptance(side, theta, phi))
        return abs

    def getLayer(self, t_Scattering: Scattering, t_Theta: Float64 = 0.0, t_Phi: Float64 = 0.0) -> CLayerSingleComponent:
        var Tf = self.getPropertySimple(self.getMinLambda(),
                                        self.getMaxLambda(),
                                        PropertySimple.T,
                                        Side.Front,
                                        t_Scattering,
                                        t_Theta,
                                        t_Phi)
        var Rf = self.getPropertySimple(self.getMinLambda(),
                                        self.getMaxLambda(),
                                        PropertySimple.R,
                                        Side.Front,
                                        t_Scattering,
                                        t_Theta,
                                        t_Phi)
        var Tb = self.getPropertySimple(self.getMinLambda(),
                                        self.getMaxLambda(),
                                        PropertySimple.T,
                                        Side.Back,
                                        t_Scattering,
                                        t_Theta,
                                        t_Phi)
        var Rb = self.getPropertySimple(self.getMinLambda(),
                                        self.getMaxLambda(),
                                        PropertySimple.R,
                                        Side.Back,
                                        t_Scattering,
                                        t_Theta,
                                        t_Phi)
        return CLayerSingleComponent(Tf, Rf, Tb, Rb)

    def getWavelengths(self) -> Vector[Float64]:
        return self.m_BSDFLayer.getBandWavelengths()

    def setWavelengths(self, wavelengths: Vector[Float64]):
        self.m_BSDFLayer.setBandWavelengths(wavelengths)

    def getMinLambda(self) -> Float64:
        var result: Float64 = 0.0
        if self.m_BSDFLayer:
            result = self.m_BSDFLayer.getCell().getMinLambda()
        return result

    def getMaxLambda(self) -> Float64:
        var result: Float64 = 0.0
        if self.m_BSDFLayer:
            result = self.m_BSDFLayer.getCell().getMaxLambda()
        return result

    def canApplyEmissivityPolynomial(self) -> Bool:
        return self.m_BSDFLayer and (self.m_BSDFLayer as CSpecularBSDFLayer) and (self.m_BSDFLayer.getBandWavelengths().size() > 2)

    def __init__(inout self, aBSDF: Pointer[CBSDFLayer]):
        self.m_Surface = Map[Side, CScatteringSurface]()
        self.m_BSDFLayer = aBSDF
        self.m_Theta = 0.0
        self.m_Phi = 0.0

    def createResultsAtAngle(self, t_Theta: Float64, t_Phi: Float64):
        if self.m_BSDFLayer:
            self.m_Surface.clear()
            self.m_Surface[Side.Front] = self.createSurface(Side.Front, t_Theta, t_Phi)
            self.m_Surface[Side.Back] = self.createSurface(Side.Back, t_Theta, t_Phi)

    def createSurface(self, t_Side: Side, t_Theta: Float64, t_Phi: Float64) -> CScatteringSurface:
        var aDirection = CBeamDirection(t_Theta, t_Phi)
        var T_dir_dir = self.m_BSDFLayer.getCell().T_dir_dir(t_Side, aDirection)
        var R_dir_dir = self.m_BSDFLayer.getCell().R_dir_dir(t_Side, aDirection)
        var T_dir_dif = self.m_BSDFLayer.getResults().DirHem(t_Side, PropertySimple.T, t_Theta, t_Phi) - T_dir_dir
        if T_dir_dif < 0:
            T_dir_dif = 0.0
        var R_dir_dif = self.m_BSDFLayer.getResults().DirHem(t_Side, PropertySimple.R, t_Theta, t_Phi) - R_dir_dir
        if R_dir_dif < 0:
            R_dir_dif = 0.0
        var T_dif_dif = self.m_BSDFLayer.getResults().DiffDiff(t_Side, PropertySimple.T)
        var R_dif_dif = self.m_BSDFLayer.getResults().DiffDiff(t_Side, PropertySimple.R)
        return CScatteringSurface(T_dir_dir, R_dir_dir, T_dir_dif, R_dir_dif, T_dif_dif, R_dif_dif)

    def checkCurrentAngles(self, t_Theta: Float64, t_Phi: Float64) -> Bool:
        var curAngles = (t_Theta == self.m_Theta) and (t_Phi == self.m_Phi)
        if not curAngles:
            self.m_Theta = t_Theta
            self.m_Phi = t_Phi
            self.createResultsAtAngle(self.m_Theta, self.m_Phi)
        return False

@value
struct CScatteringLayerIR:
    var m_Layer: CScatteringLayer

    def __init__(inout self, layer: CScatteringLayer):
        self.m_Layer = layer

    def emissivity(self, t_Side: Side, type: EmissivityPolynomials = EmissivityPolynomials.NFRC_301_Uncoated) -> Float64:
        return self.emissivity(t_Side, emissPolynomial[type])

    def emissivity(self, t_Side: Side, polynomial: Vector[Float64]) -> Float64:
        var value: Float64 = 0.0
        if self.m_Layer.canApplyEmissivityPolynomial():
            var abs = self.m_Layer.getAbsorptance(t_Side, ScatteringSimple.Direct, 0.0, 0.0)
            for i in range(polynomial.size()):
                value += pow(abs, i + 1) * polynomial[i]
        else:
            value = self.m_Layer.getAbsorptance(t_Side, ScatteringSimple.Diffuse, 0.0, 0.0)
        return value

    def transmittance(self, t_Side: Side) -> Float64:
        var wrIR = CWavelengthRange(WavelengthRange.IR)
        return self.m_Layer.getPropertySimple(wrIR.minLambda(),
                                              wrIR.maxLambda(),
                                              PropertySimple.T,
                                              t_Side,
                                              Scattering.DiffuseDiffuse)