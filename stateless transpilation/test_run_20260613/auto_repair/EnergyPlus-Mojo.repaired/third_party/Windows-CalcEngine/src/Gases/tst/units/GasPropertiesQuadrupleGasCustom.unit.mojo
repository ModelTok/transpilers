from memory import ptr, address_of
from string import String
import gtest
from WCEGases import CGas, CGasData
from Gases import *

@value
class TestGasPropertiesQuadrupleGasCustom(gtest.Testing):
    var m_Gas: CGas

    def SetUp(self) raises:
        const Air = CGasData(
            "Air",
            28.97,                            # Molecular weight
            1.4,                              # Specific heat ratio
            (1.002737e+03, 1.2324e-02, 0.0),  # Specific heat coefficients
            (2.8733e-03, 7.76e-05, 0.0),      # Conductivity coefficients
            (3.7233e-06, 4.94e-08, 0.0)       # Viscosity coefficients
        )
        const Argon = CGasData(
            "Argon",
            39.948,                           # Molecular weight
            1.67,                             # Specific heat ratio
            (5.21929e+02, 0.0, 0.0),          # Specific heat coefficients
            (2.2848e-03, 5.1486e-05, 0.0),    # Conductivity coefficients
            (3.3786e-06, 6.4514e-08, 0.0)     # Viscosity coefficients
        )
        const Krypton = CGasData(
            "Krypton",
            83.8,                            # Molecular weight
            1.68,                            # Specific heat ratio
            (2.4809e+02, 0.0, 0.0),          # Specific heat coefficients
            (9.443e-04, 2.8260e-5, 0.0),     # Conductivity coefficients
            (2.213e-6, 7.777e-8, 0.0)        # Viscosity coefficients
        )
        const Xenon = CGasData(
            "Xenon",
            131.3,                          # Molecular weight
            1.66,                           # Specific heat ratio
            (1.5834e+02, 0.0, 0.0),         # Specific heat coefficients
            (4.538e-04, 1.723e-05, 0.0),    # Conductivity coefficients
            (1.069e-6, 7.414e-08, 0.0)      # Viscosity coefficients
        )
        self.m_Gas.addGasItems(((0.1, Air), (0.3, Argon), (0.3, Krypton), (0.3, Xenon)))

def TestSimpleProperties() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) simple mix - Temperature = 300 [K], "
                       "Pressure = 101325 [Pa]")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = test.m_Gas.getSimpleGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.24480400E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.33306700E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(379.15142, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.01775733E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.710622448, aProperties.m_PrandlNumber, 0.0001)

def TestSimplePropertiesRepeat() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) simple mix - Temperature = 300 [K], "
                       "Pressure = 101325 [Pa] (Repeatability)")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = test.m_Gas.getSimpleGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.24480400E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.33306700E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(379.15142, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.01775733E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.710622448, aProperties.m_PrandlNumber, 0.0001)

def TestRealProperties() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
                       "Pressure = 101325 [Pa]")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = test.m_Gas.getGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.26127756E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesRepeat() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
                       "Pressure = 101325 [Pa] (Repeatability)")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = test.m_Gas.getGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.26127756E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesLowPressure() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
                       "Pressure = 90,000 [Pa]")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 90000)
    var aProperties = test.m_Gas.getGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(2.865298981, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.41998832E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

def TestRealPropertiesLowPressureRepeat() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
                       "Pressure = 90,000 [Pa] (Repeatability)")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    test.m_Gas.setTemperatureAndPressure(300, 90000)
    var aProperties = test.m_Gas.getGasProperties()
    gtest.EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
    gtest.EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
    gtest.EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
    gtest.EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
    gtest.EXPECT_NEAR(2.865298981, aProperties.m_Density, 0.0001)
    gtest.EXPECT_NEAR(1.41998832E-05, aProperties.m_Alpha, 1e-6)
    gtest.EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

def TotalPercents() raises:
    gtest.SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) - Total percents.")
    var test = TestGasPropertiesQuadrupleGasCustom()
    test.SetUp()
    var percents = test.m_Gas.totalPercent()
    gtest.EXPECT_NEAR(1.0, percents, 1e-6)