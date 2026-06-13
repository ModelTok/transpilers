from math import pow, abs
from memory import shared_ptr
from BaseIGULayer import CBaseIGULayer
from WCEGases import CGasLayer, Gases
from BaseShade import BaseShade
from Surface import Surface
from NusseltNumber import CNusseltNumber
from WCECommon import FenestrationCommon, Side, ConstantsData

namespace Tarcog:
    namespace ISO15099:
        class CIGUGapLayer(CBaseIGULayer, CGasLayer):
            def __init__(self, t_Thickness: float64, t_Pressure: float64):
                CBaseIGULayer.__init__(self, t_Thickness)
                CGasLayer.__init__(self, t_Pressure)

            def __init__(self, t_Thickness: float64, t_Pressure: float64, t_Gas: Gases.CGas):
                CBaseIGULayer.__init__(self, t_Thickness)
                CGasLayer.__init__(self, t_Pressure, t_Gas)

            def connectToBackSide(self, t_Layer: shared_ptr[CBaseLayer]):
                CBaseLayer.connectToBackSide(self, t_Layer)
                self.m_Surface[Side.Back] = t_Layer.getSurface(Side.Front)

            def initializeStateVariables(self):
                CGasLayer.initializeStateVariables(self)

            def calculateConvectionOrConductionFlow(self):
                self.checkNextLayer()
                if not self.isCalculated():
                    if self.getThickness() == 0:
                        raise RuntimeError("Layer thickness is set to zero.")
                    self.convectiveH()

            def checkNextLayer(self):
                if self.m_NextLayer is not None:
                    self.m_NextLayer.getGainFlow()

            def layerTemperature(self) -> float64:
                return self.averageTemperature()

            def calculateRayleighNumber(self) -> float64:
                using ConstantsData.GRAVITYCONSTANT
                var tGapTemperature = self.layerTemperature()
                var deltaTemp = abs(self.getSurface(Side.Back).getTemperature() - self.getSurface(Side.Front).getTemperature())
                var aProperties = self.m_Gas.getGasProperties()
                var ra: float64 = 0
                if aProperties.m_Viscosity != 0:
                    ra = GRAVITYCONSTANT * pow(self.getThickness(), 3) * deltaTemp * aProperties.m_SpecificHeat * pow(aProperties.m_Density, 2) / (tGapTemperature * aProperties.m_Viscosity * aProperties.m_ThermalConductivity)
                return ra

            def aspectRatio(self) -> float64:
                if self.getThickness() == 0:
                    raise RuntimeError("Gap thickness is set to zero.")
                return self.m_Height / self.getThickness()

            def convectiveH(self) -> float64:
                var tGapTemperature = self.layerTemperature()
                self.m_Gas.setTemperatureAndPressure(tGapTemperature, self.getPressure())
                var Ra = self.calculateRayleighNumber()
                var Asp = self.aspectRatio()
                var nusseltNumber = CNusseltNumber()
                var aProperties = self.m_Gas.getGasProperties()
                if aProperties.m_Viscosity != 0:
                    self.m_ConductiveConvectiveCoeff = nusseltNumber.calculate(self.m_Tilt, Ra, Asp) * aProperties.m_ThermalConductivity / self.getThickness()
                else:
                    self.m_ConductiveConvectiveCoeff = aProperties.m_ThermalConductivity
                if self.m_AirSpeed != 0:
                    self.m_ConductiveConvectiveCoeff = self.m_ConductiveConvectiveCoeff + 2 * self.m_AirSpeed
                return self.m_ConductiveConvectiveCoeff

            def getGasTemperature(self) -> float64:
                return self.layerTemperature()

            def averageTemperature(self) -> float64:
                var aveTemp: float64 = Gases.DefaultTemperature
                if self.areSurfacesInitalized():
                    aveTemp = (self.getSurface(Side.Front).getTemperature() + self.getSurface(Side.Back).getTemperature()) / 2
                return aveTemp

            def getPressure(self) -> float64:
                return self.m_Pressure

            def clone(self) -> shared_ptr[CBaseLayer]:
                return shared_ptr[CIGUGapLayer](self)