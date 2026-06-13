from ..IGUConfigurations import IIGUSystem, System, Environment

module Tarcog:
    module ISO15099:
        @value
        struct SimpleIGU(IIGUSystem):
            var m_UValue: Float64
            var m_SHGC: Float64
            var m_H: Float64

            def __init__(mut self, uValue: Float64, shgc: Float64, h: Float64):
                self.m_UValue = uValue
                self.m_SHGC = shgc
                self.m_H = h

            def getUValue(self) -> Float64:
                return self.m_UValue

            def getSHGC(self, t_TotSol: Float64) -> Float64:
                return self.m_SHGC

            def getH(self, system: System, environment: Environment) -> Float64:
                return self.m_H

            def setWidth(mut self, width: Float64):

            def setHeight(mut self, height: Float64):

            def setWidthAndHeight(mut self, width: Float64, height: Float64):

            def setInteriorAndExteriorSurfacesHeight(mut self, height: Float64):

            def setTilt(mut self, tilt: Float64):
