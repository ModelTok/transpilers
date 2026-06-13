from WCECommon import radians, degrees
from memory import Pointer
from math import sin, asin, cos, acos, tan, atan, abs
from utils import Error

struct CBeamDirection:
    var m_Theta: Float64
    var m_Phi: Float64
    var m_ProfileAngle: Float64

    def __init__(inout self):
        self.m_Theta = 0.0
        self.m_Phi = 0.0
        self.updateProfileAngle(self.m_Theta, self.m_Phi)

    def __init__(inout self, t_BeamDirection: CBeamDirection):
        self = t_BeamDirection

    def __init__(inout self, t_Theta: Float64, t_Phi: Float64):
        self.m_Theta = t_Theta
        self.m_Phi = t_Phi
        if t_Theta < 0:
            raise Error("Theta angle cannot be less than zero degrees.")
        if t_Theta > 90:
            raise Error("Theta angle cannot be more than 90 degrees.")
        self.updateProfileAngle(self.m_Theta, self.m_Phi)

    def theta(self) -> Float64:
        return self.m_Theta

    def phi(self) -> Float64:
        return self.m_Phi

    def profileAngle(self) -> Float64:
        return self.m_ProfileAngle

    def __copyinit__(inout self, other: CBeamDirection):
        self.m_Theta = other.m_Theta
        self.m_Phi = other.m_Phi
        self.m_ProfileAngle = other.m_ProfileAngle

    def __moveinit__(inout self, owned other: CBeamDirection):
        self.m_Theta = other.m_Theta
        self.m_Phi = other.m_Phi
        self.m_ProfileAngle = other.m_ProfileAngle

    def __eq__(self, other: CBeamDirection) -> Bool:
        return (self.m_Theta == other.m_Theta) and (self.m_Phi == other.m_Phi) and (self.m_ProfileAngle == other.m_ProfileAngle)

    def __ne__(self, other: CBeamDirection) -> Bool:
        return not (self == other)

    def distance(self, t_Theta: Float64, t_Phi: Float64) -> Float64:
        return abs(self.m_Theta - t_Theta) + abs(self.m_Phi - t_Phi)

    def Altitude(self) -> Float64:
        var aTheta: Float64 = radians(self.m_Theta)
        var aPhi: Float64 = radians(self.m_Phi)
        return asin(sin(aTheta) * -sin(aPhi))

    def Azimuth(self) -> Float64:
        var aAltitude: Float64 = self.Altitude()
        var aTheta: Float64 = radians(self.m_Theta)
        var aPhi: Float64 = radians(self.m_Phi)
        var aAzimuth: Float64 = 0.0
        if abs(aTheta) - abs(aAltitude) > 1e-8:
            aAzimuth = -acos(cos(aTheta) / cos(aAltitude))
        if cos(aPhi) < 0:
            aAzimuth = -aAzimuth
        return aAzimuth

    def updateProfileAngle(inout self, t_Theta: Float64, t_Phi: Float64):
        self.m_ProfileAngle = -atan(sin(radians(t_Phi)) * tan(radians(t_Theta)))
        self.m_ProfileAngle = degrees(self.m_ProfileAngle)

    def rotate(self, angle: Float64) -> CBeamDirection:
        return CBeamDirection(self.m_Theta, self.m_Phi + angle)