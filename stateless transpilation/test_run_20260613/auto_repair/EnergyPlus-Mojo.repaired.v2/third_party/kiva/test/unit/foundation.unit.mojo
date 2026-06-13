// Mojo translation of foundation.unit.cpp
// Faithful 1:1 translation, no refactoring.

from fixtures.aggregator-fixture import AggregatorFixture
from fixtures.bestest-fixture import BESTESTFixture
from fixtures.foundation-fixture import FoundationFixture
from fixtures.typical-fixture import TypicalFixture
from fixtures.gc10a-fixture import GC10aFixture
from Errors import *
from Kiva import (
    Foundation, Material, Layer, Point, Polygon, Surface, GroundOutput,
    InputBlock, Domain, Aggregator, isCounterClockWise, offset,
    KIVA_CONST_CONV, getDOE2ConvectionCoeff, showMessage, MSG_INFO,
    calcQ, calculate, SurfaceType, GroundOutputType
)

def dbl_to_string(dbl: Float64) -> String:
    return str(dbl)

def typical_fnd() -> Foundation:
    var fnd = Foundation()
    fnd.reductionStrategy = Foundation.RS_AP
    var concrete = Material(1.95, 2400.0, 900.0)
    var tempLayer = Layer()
    tempLayer.thickness = 0.10
    tempLayer.material = concrete
    fnd.slab.interior.emissivity = 0.8
    fnd.slab.layers.push_back(tempLayer)
    tempLayer.thickness = 0.2
    tempLayer.material = concrete
    fnd.wall.layers.push_back(tempLayer)
    fnd.wall.heightAboveGrade = 0.1
    fnd.wall.depthBelowSlab = 0.2
    fnd.wall.interior.emissivity = 0.8
    fnd.wall.exterior.emissivity = 0.8
    fnd.wall.interior.absorptivity = 0.8
    fnd.wall.exterior.absorptivity = 0.8
    fnd.foundationDepth = 0.0
    fnd.numericalScheme = Foundation.NS_ADI
    fnd.polygon.outer().push_back(Point(-6.0, -6.0))
    fnd.polygon.outer().push_back(Point(-6.0, 6.0))
    fnd.polygon.outer().push_back(Point(6.0, 6.0))
    fnd.polygon.outer().push_back(Point(6.0, -6.0))
    return fnd

# Helper assertion functions (simulating gtest macros)
def expect_near(actual: Float64, expected: Float64, tolerance: Float64):
    if abs(actual - expected) > tolerance:
        print("FAIL: expected", expected, "±", tolerance, "got", actual)
        raise Error("EXPECT_NEAR failed")

def expect_eq(actual: Float64, expected: Float64):
    if actual != expected:
        print("FAIL: expected", expected, "got", actual)
        raise Error("EXPECT_EQ failed")

def expect_ne(actual: Float64, expected: Float64):
    if actual == expected:
        print("FAIL: expected not equal, got", actual)
        raise Error("EXPECT_NE failed")

def expect_death(fn: () -> None, msg: String):
    try:
        fn()
        print("FAIL: expected death with message:", msg)
        raise Error("EXPECT_DEATH failed")
    except e:
        if not str(e).contains(msg):
            print("FAIL: death message mismatch. Expected:", msg, "Got:", str(e))
            raise Error("EXPECT_DEATH message mismatch")

# Test functions
def GC10aFixture_GC10a():
    var fixture = GC10aFixture()
    var analyticalQ = 2432.597
    expect_near(fixture.calcQ(), analyticalQ, analyticalQ * 0.03)

def BESTESTFixture_GC30a():
    var fixture = BESTESTFixture()
    fixture.fnd.deepGroundDepth = 30.0
    fixture.fnd.farFieldWidth = 20.0
    var trnsysQ = 2642.0
    var fluentQ = 2585.0
    var matlabQ = 2695.0
    var average = (trnsysQ + fluentQ + matlabQ) / 3.0
    expect_near(fixture.calcQ(), average, average * 0.05)

def BESTESTFixture_GC30b():
    var fixture = BESTESTFixture()
    fixture.fnd.deepGroundDepth = 15.0
    fixture.fnd.farFieldWidth = 15.0
    fixture.bcs.slabConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    fixture.bcs.intWallConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    fixture.bcs.extWallConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    fixture.bcs.gradeConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    var trnsysQ = 2533.0
    var fluentQ = 2504.0
    var matlabQ = 2570.0
    var average = (trnsysQ + fluentQ + matlabQ) / 3.0
    expect_near(fixture.calcQ(), average, average * 0.05)

def BESTESTFixture_GC30c():
    var fixture = BESTESTFixture()
    fixture.fnd.deepGroundDepth = 15.0
    fixture.fnd.farFieldWidth = 8.0
    fixture.bcs.slabConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    fixture.bcs.intWallConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    var trnsysQ = 2137.0
    var fluentQ = 2123.0
    var matlabQ = 2154.0
    var average = (trnsysQ + fluentQ + matlabQ) / 3.0
    expect_near(fixture.calcQ(), average, average * 0.05)

def BESTESTFixture_GC60b():
    var fixture = BESTESTFixture()
    fixture.fnd.deepGroundDepth = 15.0
    fixture.fnd.farFieldWidth = 15.0
    fixture.bcs.slabConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    fixture.bcs.intWallConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    fixture.bcs.extWallConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    fixture.bcs.gradeConvectionAlgorithm = KIVA_CONST_CONV(100.0)
    var trnsysQ = 2113.0
    var fluentQ = 2104.0
    var matlabQ = 2128.0
    var average = (trnsysQ + fluentQ + matlabQ) / 3.0
    expect_near(fixture.calcQ(), average, average * 0.05)

def BESTESTFixture_GC65b():
    var fixture = BESTESTFixture()
    fixture.fnd.deepGroundDepth = 15.0
    fixture.fnd.farFieldWidth = 15.0
    fixture.bcs.slabConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    fixture.bcs.intWallConvectionAlgorithm = KIVA_CONST_CONV(7.95)
    fixture.bcs.extWallConvectionAlgorithm = KIVA_CONST_CONV(11.95)
    fixture.bcs.gradeConvectionAlgorithm = KIVA_CONST_CONV(11.95)
    var trnsysQ = 1994.0
    var fluentQ = 1991.0
    var matlabQ = 2004.0
    var average = (trnsysQ + fluentQ + matlabQ) / 3.0
    expect_near(fixture.calcQ(), average, average * 0.05)

def BESTESTFixture_1D():
    var fixture = BESTESTFixture()
    fixture.fnd.exposedFraction = 0.0
    fixture.fnd.deepGroundDepth = 1.0
    fixture.fnd.useDetailedExposedPerimeter = false
    var area = 144.0  # m2
    var expectedQ = fixture.fnd.soil.conductivity / fixture.fnd.deepGroundDepth * area * (fixture.bcs.slabConvectiveTemp - fixture.bcs.deepGroundTemperature)
    expect_near(fixture.calcQ(), expectedQ, 1.0)

# Commented test block
# def TypicalFixture_Slab():
#     var fixture = TypicalFixture()
#     fixture.bcs.localWindSpeed = 0
#     fixture.bcs.outdoorTemp = 283.15
#     fixture.bcs.indoorTemp = 303.15
#     fixture.outputMap[Surface.ST_SLAB_CORE] = [GroundOutput.OT_RATE]
#     expect_near(1.0, 1.0, 1.0)

def GC10aFixture_calculateADI():
    var fixture = GC10aFixture()
    fixture.fnd.numericalScheme = Foundation.NS_ADI
    var fullyear = false
    if fullyear:
        var surface_avg = fixture.calculate(8760)
        showMessage(MSG_INFO, dbl_to_string(surface_avg))
        expect_near(surface_avg, 2888.473, 0.01)
    else:
        var surface_avg = fixture.calculate()
        showMessage(MSG_INFO, dbl_to_string(surface_avg))
        expect_near(surface_avg, 2607.32, 0.01)

def GC10aFixture_calculateImplicit():
    var fixture = GC10aFixture()
    fixture.fnd.numericalScheme = Foundation.NS_IMPLICIT
    var surface_avg = fixture.calculate()
    showMessage(MSG_INFO, dbl_to_string(surface_avg))
    expect_near(surface_avg, 2601.25, 0.01)

def GC10aFixture_calculateCrankN():
    var fixture = GC10aFixture()
    fixture.fnd.numericalScheme = Foundation.NS_CRANK_NICOLSON
    var surface_avg = fixture.calculate()
    showMessage(MSG_INFO, dbl_to_string(surface_avg))
    expect_near(surface_avg, 2600.87, 0.01)

def GC10aFixture_calculateADE():
    var fixture = GC10aFixture()
    fixture.fnd.numericalScheme = Foundation.NS_ADE
    var surface_avg = fixture.calculate()
    showMessage(MSG_INFO, dbl_to_string(surface_avg))
    expect_near(surface_avg, 2615.19, 0.01)

def GC10aFixture_GC10a_calculateSteadyState():
    var fixture = GC10aFixture()
    fixture.fnd.numericalScheme = Foundation.NS_STEADY_STATE
    var surface_avg = fixture.calculate()
    showMessage(MSG_INFO, dbl_to_string(surface_avg))
    expect_near(surface_avg, 3107.57, 0.01)

def AggregatorFixture_validation():
    var fixture = AggregatorFixture()
    var floor_results = Aggregator(Surface.SurfaceType.ST_SLAB_CORE)
    floor_results.add_instance(fixture.instances[0].ground.get(), 0.10)
    floor_results.add_instance(fixture.instances[1].ground.get(), 0.75)
    expect_death(fn: () -> None:
        floor_results.calc_weighted_results()
    , "The weights of associated Kiva instances do not add to unity.")
    floor_results = Aggregator(Surface.SurfaceType.ST_SLAB_CORE)
    expect_death(fn: () -> None:
        floor_results.add_instance(Surface.SurfaceType.ST_SLAB_PERIM, fixture.instances[0].ground.get(), 0.25)
    , "Inconsistent surface type added to aggregator.")
    floor_results = Aggregator(Surface.SurfaceType.ST_WALL_INT)
    floor_results.add_instance(fixture.instances[0].ground.get(), 0.25)
    floor_results.add_instance(fixture.instances[1].ground.get(), 0.75)
    expect_death(fn: () -> None:
        floor_results.calc_weighted_results()
    , "Aggregation requested for surface that is not part of foundation instance.")
    floor_results = Aggregator(Surface.SurfaceType.ST_SLAB_CORE)
    floor_results.add_instance(fixture.instances[0].ground.get(), 0.25)
    floor_results.add_instance(fixture.instances[1].ground.get(), 0.753)
    floor_results.calc_weighted_results()
    expect_ne(floor_results.get_instance(1).second, 0.753)
    floor_results = Aggregator(Surface.SurfaceType.ST_SLAB_CORE)
    floor_results.add_instance(fixture.instances[0].ground.get(), 0.25)
    floor_results.add_instance(fixture.instances[1].ground.get(), 0.75)
    floor_results.calc_weighted_results()  # Expect success

def AggregatorFixture_zeroConvection():
    var fixture = AggregatorFixture()
    var floor_results = Aggregator(Surface.SurfaceType.ST_SLAB_CORE)
    floor_results.add_instance(fixture.instances[0].ground.get(), 1.0)
    for surface in fixture.instances[0].foundation.surfaces:
        for index in surface.indices:
            fixture.instances[0].ground.TNew[index] = 310.15
    fixture.instances[0].ground.calculateSurfaceAverages()
    var Tavg = fixture.instances[0].ground.groundOutput.outputValues[{Surface.SurfaceType.ST_SLAB_CORE, GroundOutput.OT_TEMP}]
    expect_near(Tavg, 310.15, 0.01)
    fixture.instances[0].ground.groundOutput.outputValues[{Surface.SurfaceType.ST_SLAB_CORE, GroundOutput.OT_CONV}] = 0
    floor_results.calc_weighted_results()
    expect_eq(floor_results.results.Tconv, 310.15)

def TypicalFixture_convectionCallback():
    var fixture = TypicalFixture()
    var hc1 = fixture.bcs.slabConvectionAlgorithm(290.0, 295.0, 0.0, 0.0, 0.0)
    fixture.bcs.slabConvectionAlgorithm = KIVA_CONST_CONV(2.0)
    var hc2 = fixture.bcs.slabConvectionAlgorithm(290.0, 295.0, 0.0, 0.0, 0.0)
    expect_ne(hc1, hc2)
    expect_eq(2.0, hc2)
    fixture.bcs.slabConvectionAlgorithm = fn(Tsurf: Float64, Tamb: Float64, HfTerm: Float64, roughness: Float64, cosTilt: Float64) -> Float64:
        var deltaT = Tsurf - Tamb
        return hc2 + deltaT * deltaT + hc1 - getDOE2ConvectionCoeff(Tsurf, Tamb, HfTerm, roughness, cosTilt)
    var hc3 = fixture.bcs.slabConvectionAlgorithm(290.0, 295.0, 0.0, 0.0, 0.0)
    expect_near(hc3, 27.0, 0.00001)

def FoundationFixture_foundationSurfaces():
    var fixture = FoundationFixture()
    fixture.fnd.foundationDepth = 1.0
    fixture.fnd.wall.heightAboveGrade = 0.0
    var insulation = Material(0.0288, 28.0, 1450.0)
    var extIns = InputBlock()
    extIns.z = 0
    extIns.x = fixture.fnd.wall.totalWidth()
    extIns.depth = 1.0
    extIns.width = 0.05
    extIns.material = insulation
    fixture.fnd.inputBlocks.push_back(extIns)
    fixture.fnd.createMeshData()
    var domain = Domain(fixture.fnd)
    expect_eq(fixture.fnd.surfaces[6].type, Surface.ST_GRADE)
    expect_eq(fixture.fnd.surfaces[8].type, Surface.ST_WALL_TOP)
    expect_near(fixture.fnd.surfaces[8].xMax, fixture.fnd.surfaces[6].xMin, 0.00001)

def FoundationFixture_foundationSurfaces2():
    var fixture = FoundationFixture()
    var insulation = Material(0.0288, 28.0, 1450.0)
    var intIns = InputBlock()
    intIns.z = 0.0
    intIns.x = 0.0
    intIns.depth = 1.0
    intIns.width = -0.05
    intIns.material = insulation
    fixture.fnd.inputBlocks.push_back(intIns)
    fixture.fnd.createMeshData()
    var domain = Domain(fixture.fnd)
    expect_eq(fixture.fnd.surfaces[5].type, Surface.ST_SLAB_CORE)
    expect_eq(fixture.fnd.surfaces[8].type, Surface.ST_WALL_TOP)
    expect_near(fixture.fnd.surfaces[5].xMax, fixture.fnd.surfaces[8].xMin, 0.00001)

def FoundationFixture_clockwiseSurface():
    var fixture = FoundationFixture()
    var insulation = Material(0.0288, 28.0, 1450.0)
    var intIns = InputBlock()
    intIns.z = 0.0
    intIns.x = 0.0
    intIns.depth = 1.0
    intIns.width = -0.05
    intIns.material = insulation
    fixture.fnd.inputBlocks.push_back(intIns)
    fixture.fnd.polygon.clear()
    fixture.fnd.polygon.outer().push_back(Point(-6.0, -6.0))
    fixture.fnd.polygon.outer().push_back(Point(6.0, -6.0))
    fixture.fnd.polygon.outer().push_back(Point(6.0, 6.0))
    fixture.fnd.polygon.outer().push_back(Point(-6.0, 6.0))
    expect_eq(isCounterClockWise(fixture.fnd.polygon), false)
    fixture.fnd.createMeshData()
    expect_eq(isCounterClockWise(fixture.fnd.polygon), true)

def FoundationFixture_verticalSurfaceAreas():
    var fixture = FoundationFixture()
    fixture.fnd.foundationDepth = 2.0
    fixture.fnd.useDetailedExposedPerimeter = true
    var insulation = Material(0.0288, 28.0, 1450.0)
    var intIns = InputBlock()
    intIns.z = 0.0
    intIns.x = 0.0
    intIns.depth = 2.0
    intIns.width = -1.0
    intIns.material = insulation
    fixture.fnd.inputBlocks.push_back(intIns)
    fixture.fnd.polygon.clear()
    fixture.fnd.polygon.outer().push_back(Point(-6.0, -6.0))
    fixture.fnd.polygon.outer().push_back(Point(-6.0, 3.0))
    fixture.fnd.polygon.outer().push_back(Point(3.0, 3.0))
    fixture.fnd.polygon.outer().push_back(Point(3.0, 6.0))
    fixture.fnd.polygon.outer().push_back(Point(6.0, 6.0))
    fixture.fnd.polygon.outer().push_back(Point(6.0, -6.0))
    fixture.fnd.isExposedPerimeter.clear()
    fixture.fnd.isExposedPerimeter.push_back(true)
    fixture.fnd.isExposedPerimeter.push_back(true)
    fixture.fnd.isExposedPerimeter.push_back(true)
    fixture.fnd.isExposedPerimeter.push_back(false)
    fixture.fnd.isExposedPerimeter.push_back(false)
    fixture.fnd.isExposedPerimeter.push_back(true)
    fixture.fnd.createMeshData()
    var offset_polygon = offset(fixture.fnd.polygon, intIns.width)
    expect_near(fixture.fnd.surfaceAreas[Surface.SurfaceType.ST_WALL_INT],
                fixture.fnd.foundationDepth * perimeter(offset_polygon) * fixture.fnd.exposedFraction,
                0.00001)

def main():
    # Run all tests
    GC10aFixture_GC10a()
    BESTESTFixture_GC30a()
    BESTESTFixture_GC30b()
    BESTESTFixture_GC30c()
    BESTESTFixture_GC60b()
    BESTESTFixture_GC65b()
    BESTESTFixture_1D()
    GC10aFixture_calculateADI()
    GC10aFixture_calculateImplicit()
    GC10aFixture_calculateCrankN()
    GC10aFixture_calculateADE()
    GC10aFixture_GC10a_calculateSteadyState()
    AggregatorFixture_validation()
    AggregatorFixture_zeroConvection()
    TypicalFixture_convectionCallback()
    FoundationFixture_foundationSurfaces()
    FoundationFixture_foundationSurfaces2()
    FoundationFixture_clockwiseSurface()
    FoundationFixture_verticalSurfaceAreas()
    print("All tests passed.")