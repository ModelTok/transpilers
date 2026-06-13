from memory import Pointer
from WCETarcog import Tarcog
from WCECommon import * # Not directly used, but kept for completeness

def SCOPED_TRACE(message: String):
    print(message)

def EXPECT_NEAR(a: Float64, b: Float64, tol: Float64):
    assert(abs(a - b) < tol, "Expected " + str(a) + " == " + str(b) + " within " + str(tol))

struct TestTripleClear_EN673:
    var m_IGU: Pointer[Tarcog.EN673.IGU]

    def __init__(inout self):
        self.m_IGU = Pointer[Tarcog.EN673.IGU]()

    def SetUp(self):
        var airTemperature = 273.15   # Kelvins
        var filmCoefficient = 23      # [W/m2K]
        let outdoor = Tarcog.EN673.Environment(airTemperature, filmCoefficient)
        airTemperature = 293.15   # Kelvins
        filmCoefficient = 8       # [W/m2K]
        let indoor = Tarcog.EN673.Environment(airTemperature, filmCoefficient)
        let thickness = 0.003    # [m]
        let conductivity = 1.0   # [W/m2K]
        let emissFront = 0.84
        let emissBack = 0.84
        var layerAbsorptance = 0.099839858711
        let layer1 = Tarcog.EN673.Glass(conductivity, thickness, emissFront, emissBack, layerAbsorptance)
        self.m_IGU = Tarcog.EN673.IGU.create(indoor, outdoor)
        self.m_IGU[].addGlass(layer1)
        let gapThickness = 0.0127   # [mm]
        let gap1 = Tarcog.EN673.Gap(gapThickness)
        self.m_IGU[].addGap(gap1)
        layerAbsorptance = 0.076627746224
        let layer2 = Tarcog.EN673.Glass(conductivity, thickness, emissFront, emissBack, layerAbsorptance)
        self.m_IGU[].addGlass(layer2)
        let gap2 = Tarcog.EN673.Gap(gapThickness)
        self.m_IGU[].addGap(gap2)
        layerAbsorptance = 0.058234799653
        let layer3 = Tarcog.EN673.Glass(conductivity, thickness, emissFront, emissBack, layerAbsorptance)
        self.m_IGU[].addGlass(layer3)

    def Test1(self):
        SCOPED_TRACE("Begin Test: Uvalue")
        let igu = self.GetIGU()
        let Uvalue = igu[].Uvalue()
        EXPECT_NEAR(1.874193, Uvalue, 1e-4)
        let SHGC = igu[].shgc(0.5984)
        EXPECT_NEAR(0.7084, SHGC, 1e-4)

    def GetIGU(self) -> Pointer[Tarcog.EN673.IGU]:
        return self.m_IGU

def main():
    var test = TestTripleClear_EN673()
    test.SetUp()
    test.Test1()