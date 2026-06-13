// from WCETarcog import Deflection  // Assuming Deflection module
from WCETarcog import Deflection

# Helper function to mimic gtest EXPECT_NEAR
def expect_near[T: Comparable](actual: T, expected: T, abs_error: T):
    if abs(actual - expected) > abs_error:
        print("FAIL: expected", expected, "actual", actual, "diff", abs(actual - expected))
        raise Error("Approximate comparison failed")

class TestDeflectionE1300_TripleLayer:
    def SetUp(self):

    def ZeroDeflection(self):
        let width = 1.0
        let height = 1.0
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let loadTemperatures = List[Float64](21 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](0, 0, 0)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](0, 0, 0)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionSquaredWindow(self):
        let width = 1.0
        let height = 1.0
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let loadTemperatures = List[Float64](22 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](0.07465884e-03, -0.022613683e-03, -0.02094219e-03)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](19.883320, -14.308254, -5.575066)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionDifferentWidthAndHeight(self):
        let width = 1.0
        let height = 2.5
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let loadTemperatures = List[Float64](22 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let error = res.error
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](0.072674289e-03, -0.02168655e-03, -0.02113032e-03)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](6.844653, -4.854545, -1.990108)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionDifferentInteriorAndExteriorPressure(self):
        let width = 1.0
        let height = 2.5
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let exteriorPressure = 102325
        def_.setExteriorPressure(exteriorPressure)
        let loadTemperatures = List[Float64](22 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](-2.408286e-3, -2.317540e-3, -2.242010e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](-238.541713, -539.835780, -221.622507)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionWithTiltAngle(self):
        let width = 1.0
        let height = 2.5
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let tiltAngle = 45.0
        def_.setIGUTilt(tiltAngle)
        let loadTemperatures = List[Float64](22 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](-0.261122e-3, -0.337247e-3, -0.302394e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](-24.606516, -75.533516, -28.496727)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionWithAppliedLoad(self):
        let width = 1.0
        let height = 2.5
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.00556), Deflection.LayerData(0.00742), Deflection.LayerData(0.00556))
        let gap = List[Deflection.GapData](Deflection.GapData(0.0127, 273.15 + 21), Deflection.GapData(0.0127, 273.15 + 21))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let appliedLoad = List[Float64](1500, 0, 0)
        def_.setAppliedLoad(appliedLoad)
        let loadTemperatures = List[Float64](22 + 273.15, 21 + 273.15)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](-3.619900e-3, -3.420178e-3, -3.323497e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](-361.828081, -806.503990, -331.667929)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionTestTripleClearNoLoad(self):
        let width = 1.0
        let height = 1.0
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.003048), Deflection.LayerData(0.003048), Deflection.LayerData(0.003048))
        let gap = List[Deflection.GapData](Deflection.GapData(0.006, 273), Deflection.GapData(0.025, 273))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let loadTemperatures = List[Float64](259.44977388, 273.46099867)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let error = res.error
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](-0.421354e-3, 0.265433e-3, 0.166646e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](-19.254700278326521, 11.941581502135044, 7.3131187761958927)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionTestTripleClearWithLoad(self):
        let width = 1.0
        let height = 1.0
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.003048), Deflection.LayerData(0.003048), Deflection.LayerData(0.003048))
        let gap = List[Deflection.GapData](Deflection.GapData(0.006, 273), Deflection.GapData(0.025, 273))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let appliedLoad = List[Float64](0, 0, 100000)
        def_.setAppliedLoad(appliedLoad)
        let loadTemperatures = List[Float64](259.4496024, 273.460723)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](22.795550e-3, 24.486071e-3, 63.329275e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](7726.904240, 8555.365110, 83717.730650)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

    def DeflectionTestTripleDifferentInOutPressureLoad(self):
        let width = 1.0
        let height = 1.0
        let layer = List[Deflection.LayerData](Deflection.LayerData(0.003048), Deflection.LayerData(0.003048), Deflection.LayerData(0.003048))
        let gap = List[Deflection.GapData](Deflection.GapData(0.006, 330, 102000), Deflection.GapData(0.0127, 330, 102000))
        var def_ = Deflection.DeflectionE1300(width, height, layer, gap)
        let interiorPressure = 101000
        let exteriorPressure = 104000
        def_.setInteriorPressure(interiorPressure)
        def_.setExteriorPressure(exteriorPressure)
        let loadTemperatures = List[Float64](316.3393916, 317.7188435)
        def_.setLoadTemperatures(loadTemperatures)
        let res = def_.results()
        let deflection = res.deflection
        let panesLoad = res.paneLoad
        let correctDeflection = List[Float64](-9.338437e-3, -9.100851e-3, -8.466587e-3)
        for i in range(len(correctDeflection)):
            expect_near(correctDeflection[i], deflection[i], 1e-9)
        let correctPanesLoad = List[Float64](-1132.076073, -1015.644143, -852.279784)
        for i in range(len(correctPanesLoad)):
            expect_near(correctPanesLoad[i], panesLoad[i], 1e-6)

def main():
    let test = TestDeflectionE1300_TripleLayer()
    test.SetUp()
    test.ZeroDeflection()
    test.DeflectionSquaredWindow()
    test.DeflectionDifferentWidthAndHeight()
    test.DeflectionDifferentInteriorAndExteriorPressure()
    test.DeflectionWithTiltAngle()
    test.DeflectionWithAppliedLoad()
    test.DeflectionTestTripleClearNoLoad()
    test.DeflectionTestTripleClearWithLoad()
    test.DeflectionTestTripleDifferentInOutPressureLoad()
    print("All tests passed")