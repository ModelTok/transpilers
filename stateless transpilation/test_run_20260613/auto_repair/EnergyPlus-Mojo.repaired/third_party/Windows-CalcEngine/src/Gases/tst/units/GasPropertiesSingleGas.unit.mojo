from memory import sizeof, address_of
from testing import *
from WCEGases import *

class TestGasPropertiesSingleGas(Test):
    var Gas: CGas

    def __init__(inout self):
        self.Gas = CGas()  # Default gas is 100% air

    def GetGas(inout self) -> CGas:
        return self.Gas

def TestSimpleProperties(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) simple properties - Temperature = 300 [K], "
                 "Pressure = 101325 [Pa]")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 101325)
    var aProperties = aGas.getSimpleGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.176819053, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.20816447E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TestSimplePropertiesRepeat(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) simple properties - Temperature = 300 [K], "
                 "Pressure = 101325 [Pa] (Repeatability)")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 101325)
    var aProperties = aGas.getSimpleGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.176819053, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.20816447E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TestRealProperties(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) real properties - Temperature = 300 [K], "
                 "Pressure = 101325 [Pa]")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 101325)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.176819053, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.20816447E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesRepeat(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) real properties - Temperature = 300 [K], "
                 "Pressure = 101325 [Pa] (Repeatability)")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 101325)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.176819053, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.20816447E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesLowPressure(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) real properties - Temperature = 300 [K], "
                 "Pressure = 90,000 [Pa]")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 90000)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.045287093, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.48602517E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesLowPressureRepeat(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) real properties - Temperature = 300 [K], "
                 "Pressure = 90,000 [Pa] (Repeatability)")
    var aGas = self.GetGas()
    aGas.setTemperatureAndPressure(300, 90000)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 0.0001)
    EXPECT_NEAR(2.61533000E-02, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(1.85433000E-05, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(1006.4342, aProperties.m_SpecificHeat, 0.0001)
    EXPECT_NEAR(1.045287093, aProperties.m_Density, 0.0001)
    EXPECT_NEAR(2.48602517E-05, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0.713585333, aProperties.m_PrandlNumber, 0.0001)

def TotalPercents(self: TestGasPropertiesSingleGas):
    SCOPED_TRACE("Begin Test: Gas Properties (Air) - Total percents.")
    var aGas = self.GetGas()
    var percents = aGas.totalPercent()
    ASSERT_EQ(1.0, percents)