from memory import pointer
from WCETarcog import Tarcog
from WCECommon import *
from testing import *

class TestDoubleLoweEnvironmentWithDeflection(Test):
    var m_TarcogSystem: pointer[Tarcog.ISO15099.CSystem]

    def SetUp(self):
        const airTemperature: Float64 = 255.15
        const airSpeed: Float64 = 5.5
        const tSky: Float64 = 255.15
        const solarRadiation: Float64 = 783.0
        var Outdoor = Tarcog.ISO15099.Environments.outdoor(
          airTemperature, airSpeed, solarRadiation, tSky, Tarcog.ISO15099.SkyModel.AllSpecified)
        assert True if Outdoor else False
        Outdoor.setHCoeffModel(Tarcog.ISO15099.BoundaryConditionsCoeffModel.CalculateH)
        const roomTemperature: Float64 = 294.15
        const Indoor = Tarcog.ISO15099.Environments.indoor(roomTemperature)
        assert True if Indoor else False
        const solidLayerThickness1: Float64 = 0.00318
        const solidLayerConductance1: Float64 = 1.0
        const tIR1: Float64 = 0.0
        const frontEmissivity1: Float64 = 0.84
        const backEmissivity1: Float64 = 0.046578168869
        const layer1 = Tarcog.ISO15099.Layers.solid(solidLayerThickness1,
                                                            solidLayerConductance1,
                                                            frontEmissivity1,
                                                            tIR1,
                                                            backEmissivity1,
                                                            tIR1)
        layer1.setSolarAbsorptance(0.194422408938, solarRadiation)
        assert True if layer1 else False
        const gapThickness: Float64 = 0.0127
        var gap = Tarcog.ISO15099.Layers.gap(gapThickness)
        const solidLayerThickness2: Float64 = 0.005715
        const solidLayerConductance2: Float64 = 1.0
        const layer2 = Tarcog.ISO15099.Layers.solid(solidLayerThickness2, solidLayerConductance2)
        layer2.setSolarAbsorptance(0.054760526866, solarRadiation)
        const iguWidth: Float64 = 1.0
        const iguHeight: Float64 = 1.0
        var aIGU = Tarcog.ISO15099.CIGU(iguWidth, iguHeight)
        aIGU.addLayers([layer1, gap, layer2])
        const initialTemperature: Float64 = 293.15
        const initialPressure: Float64 = 101325
        aIGU.setDeflectionProperties(initialTemperature, initialPressure)
        self.m_TarcogSystem = pointer[Tarcog.ISO15099.CSystem](aIGU, Indoor, Outdoor)
        assert True if self.m_TarcogSystem else False

    def GetSystem(self) -> pointer[Tarcog.ISO15099.CSystem]:
        return self.m_TarcogSystem

def Test1():
    SCOPED_TRACE("Begin Test: Double Low-e - Deflection Results")
    var aSystem = TestDoubleLoweEnvironmentWithDeflection().GetSystem()
    assert True if aSystem else False
    const MaxDeflectionU = aSystem.getMaxDeflections(Tarcog.ISO15099.System.Uvalue)
    var correctMaxDeflectionU = List[Float64](-1.849981e-3, 0.344021e-3)
    assert equal(len(correctMaxDeflectionU), len(MaxDeflectionU))
    for i in range(len(correctMaxDeflectionU)):
        expect_near(correctMaxDeflectionU[i], MaxDeflectionU[i], 1e-8)
    const MaxDeflectionS = aSystem.getMaxDeflections(Tarcog.ISO15099.System.SHGC)
    var correctMaxDeflectionSHGC = List[Float64](-1.385369e-3, 0.253010e-3)
    assert equal(len(correctMaxDeflectionSHGC), len(MaxDeflectionU))
    for i in range(len(correctMaxDeflectionSHGC)):
        expect_near(correctMaxDeflectionSHGC[i], MaxDeflectionS[i], 1e-8)
    const numOfIterU = aSystem.getNumberOfIterations(Tarcog.ISO15099.System.Uvalue)
    expect_equal(21, numOfIterU)
    const numOfIterS = aSystem.getNumberOfIterations(Tarcog.ISO15099.System.SHGC)
    expect_equal(21, numOfIterS)
    const Uvalue = aSystem.getUValue()
    expect_near(Uvalue, 1.695037, 1e-6)
    const SHGC = aSystem.getSHGC(0.3716)
    expect_near(SHGC, 0.425361, 1e-5)