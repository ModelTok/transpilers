from math import pow, exp, sin, abs
from builtin import assert
from memory import Arc
from Environment import CEnvironment, CState
from WCEGases import CGas
from Surface import CSurface
from WCECommon import ConstantsData, Side, BoundaryConditionsCoeffModel, AirHorizontalDirection
from FenestrationCommon import Side as FenestrationCommon_Side

namespace Tarcog:
    namespace ISO15099:
        class CIndoorEnvironment(CEnvironment):
            m_RoomRadiationTemperature: Float64

            def __init__(inout self, t_AirTemperature: Float64, t_Pressure: Float64 = 101325):
                CEnvironment.__init__(self, t_Pressure, 0, AirHorizontalDirection.Windward)
                self.m_RoomRadiationTemperature = t_AirTemperature
                self.m_Surface[Side.Back] = Arc(CSurface(self.m_Emissivity, 0))
                self.m_Surface[Side.Back].setTemperature(t_AirTemperature)

            def __init__(inout self, t_Indoor: CIndoorEnvironment):
                CState.__init__(self, t_Indoor)
                CEnvironment.__init__(self, t_Indoor)
                self.__copy_assignment(t_Indoor)

            def __copy_assignment(inout self, t_Environment: CIndoorEnvironment) -> CIndoorEnvironment:
                self.CState.__copy_assignment(t_Environment)
                self.CEnvironment.__copy_assignment(t_Environment)
                self.m_RoomRadiationTemperature = t_Environment.m_RoomRadiationTemperature
                return self

            def connectToIGULayer(inout self, t_IGULayer: Arc[CBaseLayer]):
                t_IGULayer.connectToBackSide(Arc.from_ref(self))

            def setRoomRadiationTemperature(inout self, t_RadiationTemperature: Float64):
                self.m_RoomRadiationTemperature = t_RadiationTemperature
                self.resetCalculated()

            def clone(self) -> Arc[CBaseLayer]:
                return self.cloneEnvironment()

            def cloneEnvironment(self) -> Arc[CEnvironment]:
                return Arc(CIndoorEnvironment(self))

            def getGasTemperature(inout self) -> Float64:
                assert(self.m_Surface[Side.Back] is not None)
                return self.m_Surface[Side.Back].getTemperature()

            def calculateIRFromVariables(self) -> Float64:
                return ConstantsData.STEFANBOLTZMANN * self.m_Emissivity * pow(self.m_RoomRadiationTemperature, 4)

            def calculateConvectionOrConductionFlow(inout self):
                if self.m_HCoefficientModel == BoundaryConditionsCoeffModel.CalculateH:
                    self.calculateHc()
                elif self.m_HCoefficientModel == BoundaryConditionsCoeffModel.HPrescribed:
                    var hr: Float64 = self.getHr()
                    self.m_ConductiveConvectiveCoeff = self.m_HInput - hr
                elif self.m_HCoefficientModel == BoundaryConditionsCoeffModel.HcPrescribed:
                    self.m_ConductiveConvectiveCoeff = self.m_HInput
                else:
                    raise RuntimeError("Incorrect definition for convection model (Indoor environment).")

            def calculateHc(inout self):
                if self.m_AirSpeed > 0:
                    self.m_ConductiveConvectiveCoeff = 4 + 4 * self.m_AirSpeed
                else:
                    assert(self.m_Surface[Side.Front] is not None)
                    assert(self.m_Surface[Side.Back] is not None)
                    var tiltRadians: Float64 = self.m_Tilt * ConstantsData.WCE_PI / 180
                    var tMean: Float64 = self.getGasTemperature() + 0.25 * (self.m_Surface[Side.Front].getTemperature() - self.getGasTemperature())
                    if tMean < 0:
                        tMean = 0.1
                    var deltaTemp: Float64 = abs(self.m_Surface[Side.Front].getTemperature() - self.getGasTemperature())
                    self.m_Gas.setTemperatureAndPressure(tMean, self.m_Pressure)
                    var aProperties = self.m_Gas.getGasProperties()
                    var gr: Float64 = ConstantsData.GRAVITYCONSTANT * pow(self.m_Height, 3) * deltaTemp * pow(aProperties.m_Density, 2) / (tMean * pow(aProperties.m_Viscosity, 2))
                    var RaCrit: Float64 = 2.5e5 * pow(exp(0.72 * self.m_Tilt) / sin(tiltRadians), 0.2)
                    var RaL: Float64 = gr * aProperties.m_PrandlNumber
                    var Gnui: Float64 = 0.0
                    if (0.0 <= self.m_Tilt) and (self.m_Tilt < 15.0):
                        Gnui = 0.13 * pow(RaL, 1 / 3.0)
                    elif (15.0 <= self.m_Tilt) and (self.m_Tilt <= 90.0):
                        if RaL <= RaCrit:
                            Gnui = 0.56 * pow(RaL * sin(tiltRadians), 0.25)
                        else:
                            Gnui = 0.13 * (pow(RaL, 1 / 3.0) - pow(RaCrit, 1 / 3.0)) + 0.56 * pow(RaCrit * sin(tiltRadians), 0.25)
                    elif (90.0 < self.m_Tilt) and (self.m_Tilt <= 179.0):
                        Gnui = 0.56 * pow(RaL * sin(tiltRadians), 0.25)
                    elif (179.0 < self.m_Tilt) and (self.m_Tilt <= 180.0):
                        Gnui = 0.58 * pow(RaL, 1 / 3.0)
                    self.m_ConductiveConvectiveCoeff = Gnui * aProperties.m_ThermalConductivity / self.m_Height

            def getHr(self) -> Float64:
                assert(self.m_Surface[Side.Front] is not None)
                return self.getRadiationFlow() / (self.getRadiationTemperature() - self.m_Surface[Side.Front].getTemperature())

            def setIRFromEnvironment(inout self, t_IR: Float64):
                assert(self.m_Surface[Side.Back] is not None)
                self.m_Surface[Side.Back].setJ(t_IR)

            def getIRFromEnvironment(self) -> Float64:
                assert(self.m_Surface[Side.Back] is not None)
                return self.m_Surface[Side.Back].J()

            def getRadiationTemperature(self) -> Float64:
                return self.m_RoomRadiationTemperature