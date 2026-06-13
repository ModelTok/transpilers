from WCECommon import radians, checkRange, SurfaceType, WCE_PI
from math import cos, sin, asin, log, sqrt, pow, exp
from memory import Arc

enum CoatingProperty:
    T
    R

enum CoatingType:
    Clear
    Bronze

@inheritable
struct CAngularProperties:
    var m_Transmittance0: Float64
    var m_Reflectance0: Float64
    var m_Transmittance: Float64
    var m_Reflectance: Float64
    var m_StateAngle: Float64
    var m_StateWavelength: Float64

    def __init__(inout self, t_TransmittanceZero: Float64, t_ReflectanceZero: Float64):
        self.m_Transmittance0 = t_TransmittanceZero
        self.m_Reflectance0 = t_ReflectanceZero
        self.m_Transmittance = -1.0
        self.m_Reflectance = -1.0
        self.m_StateAngle = -1.0
        self.m_StateWavelength = -1.0

    @def transmittance(inout self, t_Angle: Float64, t_Wavelength: Float64 = 0.0) -> Float64:
        raise "Pure call"

    @def reflectance(inout self, t_Angle: Float64, t_Wavelength: Float64 = 0.0) -> Float64:
        raise "Pure call"

    def cosAngle(self, t_Angle: Float64) -> Float64:
        return cos(radians(t_Angle))

    def checkStateProperties(inout self, t_Angle: Float64, t_Wavelength: Float64):
        if t_Angle > 90.0 or t_Angle < 0.0:
            raise "Incoming angle is out of range. Incoming angle must be between 0 and 90 degrees."

@value
struct CAngularPropertiesUncoated(CAngularProperties):
    var m_Thickness: Float64
    var m_Beta: Float64
    var m_Rho0: Float64

    def __init__(inout self, t_Thicknes: Float64, t_TransmittanceZero: Float64, t_ReflectanceZero: Float64):
        CAngularProperties.__init__(self, t_TransmittanceZero, t_ReflectanceZero)
        self.m_Thickness = t_Thicknes
        self.m_Beta = self.m_Transmittance0 * self.m_Transmittance0 - self.m_Reflectance0 * self.m_Reflectance0 + 2.0 * self.m_Reflectance0 + 1.0
        self.m_Rho0 = (self.m_Beta - sqrt(self.m_Beta * self.m_Beta - 4.0 * (2.0 - self.m_Reflectance0) * self.m_Reflectance0)) / (2.0 * (2.0 - self.m_Reflectance0))

    def transmittance(inout self, t_Angle: Float64, t_Wavelength: Float64) -> Float64:
        self.checkStateProperties(t_Angle, t_Wavelength)
        return self.m_Transmittance

    def reflectance(inout self, t_Angle: Float64, t_Wavelength: Float64) -> Float64:
        self.checkStateProperties(t_Angle, t_Wavelength)
        return self.m_Reflectance

    def checkStateProperties(inout self, t_Angle: Float64, t_Wavelength: Float64):
        CAngularProperties.checkStateProperties(self, t_Angle, t_Wavelength)
        if self.m_StateAngle != t_Angle or self.m_StateWavelength != t_Wavelength:
            var aAngle = radians(t_Angle)
            var aCosPhi = cos(aAngle)
            var n = (1.0 + sqrt(self.m_Rho0)) / (1.0 - sqrt(self.m_Rho0))
            var aCosPhiPrim = cos(asin(sin(aAngle) / n))
            var a: Float64 = 0.0
            if self.m_Transmittance0 > 0.0:
                var k = -t_Wavelength / (4.0 * WCE_PI * self.m_Thickness) * log((self.m_Reflectance0 - self.m_Rho0) / (self.m_Transmittance0 * self.m_Rho0))
                var alpha = 2.0 * WCE_PI * k / t_Wavelength
                a = exp(-2.0 * alpha * self.m_Thickness / aCosPhiPrim)
            var rhoP = pow(((n * aCosPhi - aCosPhiPrim) / (n * aCosPhi + aCosPhiPrim)), 2.0)
            var rhoS = pow(((aCosPhi - n * aCosPhiPrim) / (aCosPhi + n * aCosPhiPrim)), 2.0)
            var tauP = 1.0 - rhoP
            var tauS = 1.0 - rhoS
            var tau_TotP: Float64 = 0.0
            var pCoeff = 1.0 - pow(a, 2.0) * pow(rhoP, 2.0)
            if pCoeff != 0.0:
                tau_TotP = a * pow(tauP, 2.0) / pCoeff
            var tau_TotS: Float64 = 0.0
            var sCoeff = 1.0 - pow(a, 2.0) * pow(rhoS, 2.0)
            if sCoeff != 0.0:
                tau_TotS = a * pow(tauS, 2.0) / sCoeff
            var rho_TotP = (1.0 + a * tau_TotP) * rhoP
            var rho_TotS = (1.0 + a * tau_TotS) * rhoS
            self.m_Transmittance = (tau_TotS + tau_TotP) / 2.0
            self.m_Reflectance = (rho_TotS + rho_TotP) / 2.0
            var tr = checkRange(self.m_Transmittance, self.m_Reflectance)
            self.m_Transmittance = tr.T
            self.m_Reflectance = tr.R
            self.m_StateAngle = t_Angle
            self.m_StateWavelength = t_Wavelength

@value
struct CAngularPropertiesCoated(CAngularProperties):
    var m_SolTransmittance0: Float64

    def __init__(inout self, t_Transmittance: Float64, t_Reflectance: Float64, t_SolTransmittance0: Float64):
        CAngularProperties.__init__(self, t_Transmittance, t_Reflectance)
        self.m_SolTransmittance0 = t_SolTransmittance0

    def transmittance(inout self, t_Angle: Float64, t_Wavelength: Float64 = 0.0) -> Float64:
        self.checkStateProperties(t_Angle, t_Wavelength)
        return self.m_Transmittance

    def reflectance(inout self, t_Angle: Float64, t_Wavelength: Float64 = 0.0) -> Float64:
        self.checkStateProperties(t_Angle, t_Wavelength)
        return self.m_Reflectance

    def checkStateProperties(inout self, t_Angle: Float64, t_Wavelength: Float64):
        CAngularProperties.checkStateProperties(self, t_Angle, 0.0)  # Wavelength not provided for coated glass
        if self.m_StateAngle != t_Angle:
            var aAngle = radians(t_Angle)
            var aCosPhi = cos(aAngle)
            var TCoeff: Optional[Arc[Coefficients]] = None
            var RCoeff: Optional[Arc[Coefficients]] = None
            var aCoefficients = CCoatingCoefficients()
            if self.m_SolTransmittance0 > 0.645:
                TCoeff = aCoefficients.getCoefficients(CoatingProperty.T, CoatingType.Clear)
                RCoeff = aCoefficients.getCoefficients(CoatingProperty.R, CoatingType.Clear)
            else:
                TCoeff = aCoefficients.getCoefficients(CoatingProperty.T, CoatingType.Bronze)
                RCoeff = aCoefficients.getCoefficients(CoatingProperty.R, CoatingType.Bronze)
            assert(TCoeff is not None)
            assert(RCoeff is not None)
            var tau = TCoeff.value().inerpolation(aCosPhi)
            self.m_Transmittance = tau * self.m_Transmittance0
            var rho = RCoeff.value().inerpolation(aCosPhi) - tau
            self.m_Reflectance = self.m_Reflectance0 * (1.0 - rho) + rho
            if self.m_Transmittance > 1.0:
                self.m_Transmittance = 1.0
            elif self.m_Transmittance < 0.0:
                self.m_Transmittance = 0.0
            if self.m_Reflectance > 1.0:
                self.m_Reflectance = 1.0
            elif self.m_Reflectance < 0.0:
                self.m_Reflectance = 0.0
            var tr = checkRange(self.m_Transmittance, self.m_Reflectance)
            self.m_Transmittance = tr.T
            self.m_Reflectance = tr.R
            self.m_StateAngle = t_Angle

@value
struct Coefficients:
    var C0: Float64
    var C1: Float64
    var C2: Float64
    var C3: Float64
    var C4: Float64

    def __init__(inout self, t_C0: Float64, t_C1: Float64, t_C2: Float64, t_C3: Float64, t_C4: Float64):
        self.C0 = t_C0
        self.C1 = t_C1
        self.C2 = t_C2
        self.C3 = t_C3
        self.C4 = t_C4

    def inerpolation(self, t_Value: Float64) -> Float64:
        return self.C0 + self.C1 * t_Value + self.C2 * pow(t_Value, 2.0) + self.C3 * pow(t_Value, 3.0) + self.C4 * pow(t_Value, 4.0)

@value
struct CCoatingCoefficients:
    def __init__(inout self):

    def getCoefficients(self, t_Property: CoatingProperty, t_Type: CoatingType) -> Arc[Coefficients]:
        if t_Property == CoatingProperty.T:
            if t_Type == CoatingType.Clear:
                return Arc(Coefficients(-0.0015, 3.355, -3.84, 1.46, 0.0288))
            elif t_Type == CoatingType.Bronze:
                return Arc(Coefficients(-0.002, 2.813, -2.341, -0.05725, 0.599))
            else:
                assert(False, "Incorrect selection of type.")
        elif t_Property == CoatingProperty.R:
            if t_Type == CoatingType.Clear:
                return Arc(Coefficients(0.999, -0.563, 2.043, -2.532, 1.054))
            elif t_Type == CoatingType.Bronze:
                return Arc(Coefficients(0.997, -1.868, 6.513, -7.862, 3.225))
            else:
                assert(False, "Incorrect selection of type.")
        else:
            assert(False, "Incorrect selection of property.")
        unreachable

@value
struct CAngularPropertiesFactory:
    var m_Thickness: Float64
    var m_Transmittance0: Float64
    var m_Reflectance0: Float64
    var m_SolarTransmittance0: Float64

    def __init__(inout self, t_Transmittance0: Float64, t_Reflectance0: Float64, t_Thickness: Float64 = 0.0, t_SolarTransmittance: Float64 = 0.0):
        self.m_Thickness = t_Thickness
        self.m_Transmittance0 = t_Transmittance0
        self.m_Reflectance0 = t_Reflectance0
        self.m_SolarTransmittance0 = t_SolarTransmittance

    def getAngularProperties(self, t_SurfaceType: SurfaceType) -> Arc[CAngularProperties]:
        var aProperties: Arc[CAngularProperties]
        if t_SurfaceType == SurfaceType.Coated:
            aProperties = Arc(CAngularPropertiesCoated(self.m_Transmittance0, self.m_Reflectance0, self.m_SolarTransmittance0))
        elif t_SurfaceType == SurfaceType.Uncoated:
            aProperties = Arc(CAngularPropertiesUncoated(self.m_Thickness, self.m_Transmittance0, self.m_Reflectance0))
        else:
            raise "Incorrect surface type. Cannot create correct angular properties."
        assert(aProperties is not None)
        return aProperties
<<<FILE>>>