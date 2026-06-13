from ...WCEGases import CGas, CGasData
from testing import assert_almost_equal as assert_almost_equal

@fixture
struct TestGasPropertiesDoubleGas:
    var m_Gas: CGas

    def setup(inout self):
        const Air = CGasData(
            "Air",
            28.97,                          # Molecular weight
            1.4,                            # Specific heat ratio
            [1.002737e+03, 1.2324e-02, 0.0], # Specific heat coefficients
            [2.8733e-03, 7.76e-05, 0.0],    # Conductivity coefficients
            [3.7233e-06, 4.94e-08, 0.0]     # Viscosity coefficients
        )
        const Argon = CGasData(
            "Argon",
            39.948,                          # Molecular weight
            1.67,                            # Specific heat ratio
            [5.21929e+02, 0.0, 0.0],         # Specific heat coefficients
            [2.2848e-03, 5.1486e-05, 0.0],   # Conductivity coefficients
            [3.3786e-06, 6.4514e-08, 0.0]    # Viscosity coefficients
        )
        self.m_Gas.addGasItems([(0.1, Air), (0.9, Argon)])

@test
def TestSimpleProperties(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) simple mix - Temperature = 300 [K], Pressure = 101325 [Pa]")
    self.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = self.m_Gas.getSimpleGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.85728700E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.23138500E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 570.37952, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.578172439, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.06329175E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.685266362, atol=0.0001)

@test
def TestSimplePropertiesRepeat(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) simple mix - Temperature = 300 [K], Pressure = 101325 [Pa] (Repeatability)")
    self.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = self.m_Gas.getSimpleGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.85728700E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.23138500E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 570.37952, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.578172439, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.06329175E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.685266362, atol=0.0001)

@test
def TestRealProperties(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) real mix - Temperature = 300 [K], Pressure = 101325 [Pa]")
    self.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = self.m_Gas.getGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.850941662E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.235785737E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 558.0578118, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.578172439, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.10164367E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.674088072, atol=0.0001)

@test
def TestRealPropertiesRepeat(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) real mix - Temperature = 300 [K], Pressure = 101325 [Pa] (Repeatability)")
    self.m_Gas.setTemperatureAndPressure(300, 101325)
    var aProperties = self.m_Gas.getGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.850941662E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.235785737E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 558.0578118, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.578172439, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.10164367E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.674088072, atol=0.0001)

@test
def TestRealPropertiesLowPressure(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) real mix - Temperature = 300 [K], Pressure = 90,000 [Pa]")
    self.m_Gas.setTemperatureAndPressure(300, 90000)
    var aProperties = self.m_Gas.getGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.850941662E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.235785737E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 558.0578118, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.401781589, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.36610050E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.674088072, atol=0.0001)

@test
def TestRealPropertiesLowPressureRepeat(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) real mix - Temperature = 300 [K], Pressure = 90,000 [Pa] (Repeatability)")
    self.m_Gas.setTemperatureAndPressure(300, 90000)
    var aProperties = self.m_Gas.getGasProperties()
    assert_almost_equal(aProperties.m_MolecularWeight, 38.8502, atol=0.0001)
    assert_almost_equal(aProperties.m_ThermalConductivity, 1.850941662E-02, atol=1e-6)
    assert_almost_equal(aProperties.m_Viscosity, 2.235785737E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_SpecificHeat, 558.0578118, atol=0.0001)
    assert_almost_equal(aProperties.m_Density, 1.401781589, atol=0.0001)
    assert_almost_equal(aProperties.m_Alpha, 2.36610050E-05, atol=1e-6)
    assert_almost_equal(aProperties.m_PrandlNumber, 0.674088072, atol=0.0001)

@test
def TotalPercents(self: TestGasPropertiesDoubleGas):
    print("Begin Test: Gas Properties (Air 10% / Argon 90%) - Total percents.")
    var percents = self.m_Gas.totalPercent()
    assert_almost_equal(percents, 1.0, atol=1e-6)