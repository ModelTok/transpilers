from WCEGases import CGas, GasDef

def EXPECT_NEAR(val: Float64, expected: Float64, tolerance: Float64):
    if abs(val - expected) > tolerance:
        print("EXPECT_NEAR failed: val=", val, " expected=", expected, " tol=", tolerance)
        # In a real test framework, this would be an assertion.

struct TestGasPropertiesQuadrupleGas:
    var m_Gas: CGas

    def SetUp(inout self):
        self.m_Gas.addGasItem(0.1, GasDef.Air)
        self.m_Gas.addGasItem(0.3, GasDef.Argon)
        self.m_Gas.addGasItem(0.3, GasDef.Krypton)
        self.m_Gas.addGasItem(0.3, GasDef.Xenon)

    def TestSimpleProperties(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) simple mix - Temperature = 300 [K], "
        #              "Pressure = 101325 [Pa]");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 101325)
        var aProperties = self.m_Gas.getSimpleGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.24480400E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.33306700E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(379.15142, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.01775733E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.710622448, aProperties.m_PrandlNumber, 0.0001)

    def TestSimplePropertiesRepeat(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) simple mix - Temperature = 300 [K], "
        #              "Pressure = 101325 [Pa] (Repeatability)");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 101325)
        var aProperties = self.m_Gas.getSimpleGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.24480400E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.33306700E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(379.15142, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.01775733E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.710622448, aProperties.m_PrandlNumber, 0.0001)

    def TestRealProperties(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
        #              "Pressure = 101325 [Pa]");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 101325)
        var aProperties = self.m_Gas.getGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.26127756E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

    def TestRealPropertiesRepeat(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
        #              "Pressure = 101325 [Pa] (Repeatability)");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 101325)
        var aProperties = self.m_Gas.getGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(3.225849103, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.26127756E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

    def TestRealPropertiesLowPressure(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
        #              "Pressure = 90,000 [Pa]");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 90000)
        var aProperties = self.m_Gas.getGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(2.865298981, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.41998832E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

    def TestRealPropertiesLowPressureRepeat(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) real mix - Temperature = 300 [K], "
        #              "Pressure = 90,000 [Pa] (Repeatability)");
        self.SetUp()
        self.m_Gas.setTemperatureAndPressure(300, 90000)
        var aProperties = self.m_Gas.getGasProperties()
        EXPECT_NEAR(79.4114, aProperties.m_MolecularWeight, 0.0001)
        EXPECT_NEAR(1.108977555E-02, aProperties.m_ThermalConductivity, 1e-6)
        EXPECT_NEAR(2.412413749E-05, aProperties.m_Viscosity, 1e-6)
        EXPECT_NEAR(272.5637141, aProperties.m_SpecificHeat, 0.001)
        EXPECT_NEAR(2.865298981, aProperties.m_Density, 0.0001)
        EXPECT_NEAR(1.41998832E-05, aProperties.m_Alpha, 1e-6)
        EXPECT_NEAR(0.592921334, aProperties.m_PrandlNumber, 0.0001)

    def TotalPercents(inout self):
        # SCOPED_TRACE("Begin Test: Gas Properties (quadruple gas) - Total percents.");
        self.SetUp()
        var percents = self.m_Gas.totalPercent()
        EXPECT_NEAR(1.0, percents, 1e-6)