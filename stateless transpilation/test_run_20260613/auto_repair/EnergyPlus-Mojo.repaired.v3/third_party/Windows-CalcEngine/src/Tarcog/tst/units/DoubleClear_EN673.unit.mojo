from WCETarcog import Tarcog
from WCECommon import ()

class TestDoubleClear_EN673:
    private var m_IGU: Tarcog.EN673.IGU

    def set_up(self):
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
        var layerAbsorptance = 9.64899212e-2
        let layer1 = Tarcog.EN673.Glass(conductivity, thickness, emissFront, emissBack, layerAbsorptance)
        self.m_IGU = Tarcog.EN673.IGU.create(indoor, outdoor)
        self.m_IGU.addGlass(layer1)
        let gapThickness = 0.0127   # [mm]
        let gap = Tarcog.EN673.Gap(gapThickness)
        self.m_IGU.addGap(gap)
        layerAbsorptance = 7.2256759e-2
        let layer2 = Tarcog.EN673.Glass(conductivity, thickness, emissFront, emissBack, layerAbsorptance)
        self.m_IGU.addGlass(layer2)

    def get_igu(self) -> Tarcog.EN673.IGU:
        return self.m_IGU

def test_double_clear_en673_test1():
    SCOPED_TRACE("Begin Test: Uvalue")
    var test_obj = TestDoubleClear_EN673()
    test_obj.set_up()
    var igu = test_obj.get_igu()
    var Uvalue = igu.Uvalue()
    assert_approx_equal(Uvalue, 2.82738, atol=1e-4)
    var SHGC = igu.shgc(0.703296)
    assert_approx_equal(SHGC, 0.7775, atol=1e-4)

def main():
    test_double_clear_en673_test1()