from testing import Test, Expect
from WCETarcog import Deflection
from memory import Pointer
from utils import Vector
class TestDeflectionE1300_DoubleLayer(Test):
    def setup() raises:

@fixture
def DeflectionSquaredWindow():
    let width: Float64 = 1.0
    let height: Float64 = 1.0
    var layer = Vector[Deflection.LayerData]()
    layer.push_back(Deflection.LayerData(0.003048))
    layer.push_back(Deflection.LayerData(0.00742))
    var gap = Vector[Deflection.GapData]()
    gap.push_back(Deflection.GapData(0.0127, 273.15 + 30))
    let def = Deflection.DeflectionE1300(width, height, layer, gap)
    let loadTemperatures = Vector[Float64](268)
    def.setLoadTemperatures(loadTemperatures)
    let res = def.results()
    let error = res.error
    let deflection = res.deflection
    let pressureDifference = res.paneLoad
    Expect.equal(error.has_value(), true)
    let correctError: Float64 = 9.924406e-08
    Expect.near(error.value(), correctError, 1e-9)
    let correctDeflection = Vector[Float64](-2.469101e-3, 0.259526e-3)
    for i in range(correctDeflection.size()):
        Expect.near(correctDeflection[i], deflection[i], 1e-9)
    let correctPressureDifference = Vector[Float64](-164.301506, 164.301506)
    for i in range(correctDeflection.size()):
        Expect.near(correctPressureDifference[i], pressureDifference[i], 1e-6)

@fixture
def DeflectionDifferentWidthAndHeight():
    let width: Float64 = 1.0
    let height: Float64 = 2.5
    var layer = Vector[Deflection.LayerData]()
    layer.push_back(Deflection.LayerData(0.003048))
    layer.push_back(Deflection.LayerData(0.00742))
    var gap = Vector[Deflection.GapData]()
    gap.push_back(Deflection.GapData(0.0127, 273.15 + 30))
    let def = Deflection.DeflectionE1300(width, height, layer, gap)
    let loadTemperatures = Vector[Float64](268)
    def.setLoadTemperatures(loadTemperatures)
    let res = def.results()
    let error = res.error
    let deflection = res.deflection
    let pressureDifference = res.paneLoad
    Expect.equal(error.has_value(), true)
    let correctError: Float64 = 5.43917994946e-05
    Expect.near(error.value(), correctError, 1e-9)
    let correctDeflection = Vector[Float64](-2.922637e-3, 0.216158e-3)
    for i in range(correctDeflection.size()):
        Expect.near(correctDeflection[i], deflection[i], 1e-9)
    let correctPressureDifference = Vector[Float64](-48.406364, 48.406364)
    for i in range(correctDeflection.size()):
        Expect.near(correctPressureDifference[i], pressureDifference[i], 1e-6)

@fixture
def DeflectionDifferentInteriorAndExteriorPressure():
    let width: Float64 = 1.0
    let height: Float64 = 2.5
    var layer = Vector[Deflection.LayerData]()
    layer.push_back(Deflection.LayerData(0.003048))
    layer.push_back(Deflection.LayerData(0.00742))
    var gap = Vector[Deflection.GapData]()
    gap.push_back(Deflection.GapData(0.0127, 273.15 + 30))
    let def = Deflection.DeflectionE1300(width, height, layer, gap)
    let exteriorPressure: Float64 = 102325
    def.setExteriorPressure(exteriorPressure)
    let loadTemperatures = Vector[Float64](268)
    def.setLoadTemperatures(loadTemperatures)
    let res = def.results()
    let error = res.error
    let deflection = res.deflection
    let pressureDifference = res.paneLoad
    Expect.equal(error.has_value(), true)
    let correctError: Float64 = -4.656613e-08
    Expect.near(error.value(), correctError, 1e-9)
    let correctDeflection = Vector[Float64](-6.029248e-3, -3.687419e-3)
    for i in range(correctDeflection.size()):
        Expect.near(correctDeflection[i], deflection[i], 1e-9)
    let correctPressureDifference = Vector[Float64](-128.864957, -871.135043)
    for i in range(correctDeflection.size()):
        Expect.near(correctPressureDifference[i], pressureDifference[i], 1e-6)

@fixture
def DeflectionWithTiltAngle():
    let width: Float64 = 1.0
    let height: Float64 = 2.5
    var layer = Vector[Deflection.LayerData]()
    layer.push_back(Deflection.LayerData(0.003048))
    layer.push_back(Deflection.LayerData(0.00742))
    var gap = Vector[Deflection.GapData]()
    gap.push_back(Deflection.GapData(0.0127, 273.15 + 30))
    let def = Deflection.DeflectionE1300(width, height, layer, gap)
    let tiltAngle: Float64 = 45.0
    def.setIGUTilt(tiltAngle)
    let loadTemperatures = Vector[Float64](268)
    def.setLoadTemperatures(loadTemperatures)
    let res = def.results()
    let error = res.error
    let deflection = res.deflection
    let pressureDifference = res.paneLoad
    Expect.equal(error.has_value(), true)
    let correctError: Float64 = 3.521785e-05
    Expect.near(error.value(), correctError, 1e-9)
    let correctDeflection = Vector[Float64](-2.626985e-3, 0.532367e-3)
    for i in range(correctDeflection.size()):
        Expect.near(correctDeflection[i], deflection[i], 1e-9)
    let correctPressureDifference = Vector[Float64](-43.450134, 119.245270)
    for i in range(correctDeflection.size()):
        Expect.near(correctPressureDifference[i], pressureDifference[i], 1e-6)

@fixture
def DeflectionWithAppliedLoad():
    let width: Float64 = 1.0
    let height: Float64 = 2.5
    var layer = Vector[Deflection.LayerData]()
    layer.push_back(Deflection.LayerData(0.003048))
    layer.push_back(Deflection.LayerData(0.00742))
    var gap = Vector[Deflection.GapData]()
    gap.push_back(Deflection.GapData(0.0127, 273.15 + 30))
    let def = Deflection.DeflectionE1300(width, height, layer, gap)
    let loadTemperatures = Vector[Float64](268)
    def.setLoadTemperatures(loadTemperatures)
    let appliedLoad = Vector[Float64](1500, 0)
    def.setAppliedLoad(appliedLoad)
    let res = def.results()
    let error = res.error
    let deflection = res.deflection
    let panesLoad = res.paneLoad
    Expect.equal(error.has_value(), true)
    let correctError: Float64 = -5.215406e-08
    Expect.near(error.value(), correctError, 1e-9)
    let correctDeflection = Vector[Float64](-7.190758e-3, -5.554584e-3)
    for i in range(correctDeflection.size()):
        Expect.near(correctDeflection[i], deflection[i], 1e-9)
    let correctPanesLoad = Vector[Float64](-177.299229, -1322.700771)
    for i in range(correctDeflection.size()):
        Expect.near(correctPanesLoad[i], panesLoad[i], 1e-6)