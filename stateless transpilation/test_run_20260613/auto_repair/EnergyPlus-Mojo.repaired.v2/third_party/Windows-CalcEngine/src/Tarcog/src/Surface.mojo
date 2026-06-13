from math import pow
from memory import Arc
from WCEGases import STEFANBOLTZMANN

struct ISurface:
    var m_Temperature: Float64
    var m_J: Float64
    var m_Emissivity: Float64
    var m_Reflectance: Float64
    var m_Transmittance: Float64
    var m_MeanDeflection: Float64
    var m_MaxDeflection: Float64

    def __init__(inout self):
        self.m_Temperature = 273.15
        self.m_J = 0
        self.m_Emissivity = 0.84
        self.m_Transmittance = 0
        self.m_MeanDeflection = 0
        self.m_MaxDeflection = 0
        self.calculateReflectance()

    def __init__(inout self, t_Emissivity: Float64, t_Transmittance: Float64):
        self.m_Temperature = 273.15
        self.m_J = 0
        self.m_Emissivity = t_Emissivity
        self.m_Transmittance = t_Transmittance
        self.m_MeanDeflection = 0
        self.m_MaxDeflection = 0
        self.calculateReflectance()

    def __copyinit__(inout self, t_Surface: Self):
        self.__copyassign__(t_Surface)

    def __copyassign__(inout self, t_Surface: Self) -> Self:
        self.m_Emissivity = t_Surface.m_Emissivity
        self.m_Transmittance = t_Surface.m_Transmittance
        self.m_Temperature = t_Surface.m_Temperature
        self.m_J = t_Surface.m_J
        self.m_MaxDeflection = t_Surface.m_MaxDeflection
        self.m_MeanDeflection = t_Surface.m_MeanDeflection
        self.calculateReflectance()
        return self

    def setTemperature(inout self, t_Temperature: Float64):
        self.m_Temperature = t_Temperature

    def setJ(inout self, t_J: Float64):
        self.m_J = t_J

    def applyDeflection(inout self, t_MeanDeflection: Float64, t_MaxDeflection: Float64):
        self.m_MeanDeflection = t_MeanDeflection
        self.m_MaxDeflection = t_MaxDeflection

    def getTemperature(self) -> Float64:
        return self.m_Temperature

    def getEmissivity(self) -> Float64:
        return self.m_Emissivity

    def getReflectance(self) -> Float64:
        return self.m_Reflectance

    def getTransmittance(self) -> Float64:
        return self.m_Transmittance

    def J(self) -> Float64:
        return self.m_J

    def getMeanDeflection(self) -> Float64:
        return self.m_MeanDeflection

    def getMaxDeflection(self) -> Float64:
        return self.m_MaxDeflection

    def emissivePowerTerm(self) -> Float64:
        return STEFANBOLTZMANN * self.m_Emissivity * pow(self.m_Temperature, 3)

    def calculateReflectance(inout self):
        if self.m_Emissivity + self.m_Transmittance > 1:
            raise Error("Sum of emittance and transmittance cannot be greater than one.")
        else:
            self.m_Reflectance = 1 - self.m_Emissivity - self.m_Transmittance

    def initializeStart(inout self, t_Temperature: Float64):
        self.m_Temperature = t_Temperature
        self.m_J = STEFANBOLTZMANN * pow(self.m_Temperature, 4)

    def initializeStart(inout self, t_Temperature: Float64, t_Radiation: Float64):
        self.m_Temperature = t_Temperature
        self.m_J = t_Radiation

    def clone(self) -> Arc[ISurface]:
        raise Error("ISurface::clone() pure virtual")

struct CSurface(ISurface):
    def __init__(inout self, t_Emissivity: Float64, t_Transmittance: Float64):
        super().__init__(t_Emissivity, t_Transmittance)

    def __init__(inout self, t_Surface: Self):
        super().__init__(t_Surface)

    def __init__(inout self):
        super().__init__()

    def clone(self) -> Arc[ISurface]:
        return Arc(CSurface(self))