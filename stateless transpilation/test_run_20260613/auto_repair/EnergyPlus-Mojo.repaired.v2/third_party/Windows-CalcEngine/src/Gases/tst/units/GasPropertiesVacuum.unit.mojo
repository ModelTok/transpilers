from memory import pointer
from testing import *
from WCEGases import *

class TestGasPropertiesVacuum(Testing):
    var Gas: CGas

    def __init__(inout self):
        self.Gas = CGas()

    def GetGas(inout self) -> CGas:
        return self.Gas

@fixture
def TestGasPropertiesVacuum_fixture() -> TestGasPropertiesVacuum:
    return TestGasPropertiesVacuum()

def TestVacuumProperties1():
    let fixture = TestGasPropertiesVacuum_fixture()
    SCOPED_TRACE(
      "Begin Test: Gas Vacuum Properties (Air) - Temperature = 273.15 [K], Pressure = 0.1333 [Pa]")
    var aGas = fixture.GetGas()
    aGas.setTemperatureAndPressure(273.15, 0.1333)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 1e-6)
    EXPECT_NEAR(0.106769062, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(0, aProperties.m_SpecificHeat, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Density, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0, aProperties.m_PrandlNumber, 1e-6)

def TestVacuumProperties2():
    let fixture = TestGasPropertiesVacuum_fixture()
    SCOPED_TRACE(
      "Begin Test: Gas Vacuum Properties (Air) - Temperature = 293.15 [K], Pressure = 0.1333 [Pa]")
    var aGas = fixture.GetGas()
    aGas.setTemperatureAndPressure(293.15, 0.1333)
    var aProperties = aGas.getGasProperties()
    EXPECT_NEAR(28.97, aProperties.m_MolecularWeight, 1e-6)
    EXPECT_NEAR(0.1030625965, aProperties.m_ThermalConductivity, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Viscosity, 1e-6)
    EXPECT_NEAR(0, aProperties.m_SpecificHeat, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Density, 1e-6)
    EXPECT_NEAR(0, aProperties.m_Alpha, 1e-6)
    EXPECT_NEAR(0, aProperties.m_PrandlNumber, 1e-6)