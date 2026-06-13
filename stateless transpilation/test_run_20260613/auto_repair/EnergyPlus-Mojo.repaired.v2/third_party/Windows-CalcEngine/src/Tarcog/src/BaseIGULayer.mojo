from BaseLayer import CBaseLayer
from Surface import Surface
from memory import pointer
from math import abs

@value
enum Side:
    Front = 0
    Back = 1

@value
class CBaseIGULayer(CBaseLayer):
    var m_Thickness: Float64

    def __init__(inout self, t_Thickness: Float64):
        self.m_Thickness = t_Thickness

    def layerTemperature(self) -> Float64:
        return (self.getTemperature(Side.Front) + self.getTemperature(Side.Back)) / 2

    def getThickness(self) -> Float64:
        return self.m_Thickness + self.getSurface(Side.Front).getMeanDeflection() - self.getSurface(Side.Back).getMeanDeflection()

    def getTemperature(self, t_Position: Side) -> Float64:
        return self.getSurface(t_Position).getTemperature()

    def J(self, t_Position: Side) -> Float64:
        return self.getSurface(t_Position).J()

    def getMaxDeflection(self) -> Float64:
        assert(self.getSurface(Side.Front).getMaxDeflection() == self.getSurface(Side.Back).getMaxDeflection())
        return self.getSurface(Side.Front).getMaxDeflection()

    def getMeanDeflection(self) -> Float64:
        assert(self.getSurface(Side.Front).getMeanDeflection() == self.getSurface(Side.Back).getMeanDeflection())
        return self.getSurface(Side.Front).getMeanDeflection()

    def getConductivity(self) -> Float64:
        return self.getConductionConvectionCoefficient() * self.m_Thickness

    def getEffectiveThermalConductivity(self) -> Float64:
        return abs(self.getHeatFlow() * self.m_Thickness / (self.m_Surface[Side.Front].getTemperature() - self.m_Surface[Side.Back].getTemperature()))