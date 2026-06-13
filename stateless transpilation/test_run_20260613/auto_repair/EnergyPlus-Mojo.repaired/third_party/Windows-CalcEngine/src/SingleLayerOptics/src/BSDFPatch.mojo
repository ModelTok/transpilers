from math import sin
from memory import Rc
from WCECommon import WCE_PI
from BeamDirection import CBeamDirection

class CAngleLimits:
    var m_Low: Float64
    var m_High: Float64

    def __init__(inout self, t_Low: Float64, t_High: Float64):
        self.m_Low = t_Low
        self.m_High = t_High

    def low(self) -> Float64:
        return self.m_Low

    def high(self) -> Float64:
        return self.m_High

    def delta(self) -> Float64:
        return self.m_High - self.m_Low

    def isInLimits(self, t_Angle: Float64) -> Bool:
        var aAngle: Float64 = (self.m_Low + 360.0) if t_Angle else t_Angle - 360.0
        if (self.m_Low + 360.0) < t_Angle:
            aAngle = t_Angle - 360.0
        else:
            aAngle = t_Angle
        return (aAngle >= self.m_Low) and (aAngle <= self.m_High)

    def average(self) -> Float64:
        return (self.m_Low + self.m_High) / 2.0


class CCentralAngleLimits(CAngleLimits):
    def __init__(inout self, t_High: Float64):
        super().__init__(0.0, t_High)

    def average(self) -> Float64:
        return self.m_Low


class CBSDFPatch:
    var m_Theta: Rc[CAngleLimits]
    var m_Phi: CAngleLimits
    var m_Lambda: Float64

    def __init__(inout self, t_Theta: Rc[CAngleLimits], t_Phi: CAngleLimits):
        self.m_Theta = t_Theta
        self.m_Phi = t_Phi
        self.calculateLambda()

    def centerPoint(self) -> CBeamDirection:
        return CBeamDirection(self.m_Theta[].average(), self.m_Phi.average())

    def lambda_(self) -> Float64:
        return self.m_Lambda

    def isInPatch(self, t_Theta: Float64, t_Phi: Float64) -> Bool:
        return self.m_Theta[].isInLimits(t_Theta) and self.m_Phi.isInLimits(t_Phi)

    def calculateLambda(inout self):
        var thetaLow: Float64 = self.m_Theta[].low() * WCE_PI / 180.0
        var thetaHight: Float64 = self.m_Theta[].high() * WCE_PI / 180.0
        var deltaPhi: Float64 = self.m_Phi.delta() * WCE_PI / 180.0
        self.m_Lambda = 0.5 * deltaPhi * (
            sin(thetaHight) * sin(thetaHight) - sin(thetaLow) * sin(thetaLow)
        )