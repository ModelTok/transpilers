from builtin import List, Float64, Pointer, owned, borrow
from testing import test, assert_equal, assert_approx_equal
from lib_windwatts import windPowerCalculator, windTurbine, createDefaultTurbine
from lib_windwakemodel import wakeModelBase
from lib_windwakemodel_test import fakeWakeModel

/**
 * windPowerCalculatorTest requires an initialized windTurbine and wakeModel, and XCoords & YCoords.
 * SetUp() allocates the vectors for input and output variables for windPowerUsingResource. 
 */
struct windPowerCalculatorTest:
    var wpc: windPowerCalculator
    var wt: windTurbine
    var nTurbines: Int
    var windSpeedData: Float64
    var windDirData: Float64
    var pressureData: Float64
    var tempData: Float64
    var farmPower: Float64
    var farmPowerGross: Float64
    var power: List[Float64]
    var thrust: List[Float64]
    var eff: List[Float64]
    var windSpeed: List[Float64]
    var turbulenceCoeff: List[Float64]
    var distX: List[Float64]
    var distY: List[Float64]
    var distDownwind: List[Float64]
    var distCrosswind: List[Float64]
    var e: Float64

    def __init__(inout self):
        self.wpc = windPowerCalculator()
        self.wt = windTurbine()
        self.nTurbines = 0
        self.windSpeedData = 0.0
        self.windDirData = 0.0
        self.pressureData = 0.0
        self.tempData = 0.0
        self.farmPower = 0.0
        self.farmPowerGross = 0.0
        self.power = List[Float64]()
        self.thrust = List[Float64]()
        self.eff = List[Float64]()
        self.windSpeed = List[Float64]()
        self.turbulenceCoeff = List[Float64]()
        self.distX = List[Float64]()
        self.distY = List[Float64]()
        self.distDownwind = List[Float64]()
        self.distCrosswind = List[Float64]()
        self.e = 1000.0

    def SetUp(inout self):
        self.nTurbines = 3
        self.distDownwind.resize(self.nTurbines)
        self.distCrosswind.resize(self.nTurbines)
        self.thrust.resize(self.nTurbines, 0.47669)
        self.power.resize(self.nTurbines, 1190.0)
        self.eff.resize(self.nTurbines, 0.0)
        self.windSpeed.resize(self.nTurbines)
        self.turbulenceCoeff.resize(self.nTurbines)
        self.distX = List[Float64](0.0, 5.0, 10.0)
        self.distY = List[Float64](0.0, 5.0, 10.0)
        self.distDownwind.resize(self.nTurbines)
        self.distCrosswind.resize(self.nTurbines)
        for i in range(self.nTurbines):
            self.windSpeed[i] = 10.0
        createDefaultTurbine(self.wt)
        self.wpc.nTurbines = self.nTurbines
        self.wpc.turbulenceIntensity = 1.0 / 7.0
        self.wpc.windTurb = self.wt
        self.wpc.XCoords = self.distX
        self.wpc.YCoords = self.distY

@test
def windPowerUsingResource_lib_windwatts():
    var test = windPowerCalculatorTest()
    test.SetUp()
    test.windSpeedData = 10.0
    test.windDirData = 180.0
    test.tempData = 25.0
    test.pressureData = 1.0
    var fakeWM = owned[fakeWakeModel](fakeWakeModel())
    test.wpc.InitializeModel(fakeWM)
    var run = test.wpc.windPowerUsingResource(
        test.windSpeedData, test.windDirData, test.pressureData, test.tempData,
        test.farmPower, test.farmPowerGross,
        test.power.data, test.thrust.data, test.eff.data, test.windSpeed.data,
        test.turbulenceCoeff.data, test.distDownwind.data, test.distCrosswind.data
    )
    assert_equal(run, 3)

@test
def windPowerUsingWeibull_lib_windwatts():
    var test = windPowerCalculatorTest()
    test.SetUp()
    test.windSpeedData = 10.0
    test.windDirData = 180.0
    test.tempData = 25.0
    test.pressureData = 1.0
    var weibullK: Float64 = 2.0
    var avgSpeed: Float64 = 7.25
    var refHeight: Float64 = 50.0
    var energy = List[Float64](test.wpc.windTurb.powerCurveArrayLength, 0.0)
    var energyTotal = test.wpc.windPowerUsingWeibull(weibullK, avgSpeed, refHeight, energy.data)
    assert_approx_equal(energyTotal, 5_639_180.0, test.e)

@test
def windPowerUsingDistribution_lib_windwatts():
    var test = windPowerCalculatorTest()
    test.SetUp()
    var dst = List[List[Float64]]()
    dst.append(List[Float64](1.5, 180.0, 0.12583))
    dst.append(List[Float64](5.0, 180.0, 0.3933))
    dst.append(List[Float64](8.0, 180.0, 0.18276))
    dst.append(List[Float64](10.0, 180.0, 0.1341))
    dst.append(List[Float64](13.5, 180.0, 0.14217))
    dst.append(List[Float64](19.0, 180.0, 0.0211))
    var wakeModel = owned[wakeModelBase](fakeWakeModel())
    test.wpc.InitializeModel(wakeModel)
    test.wpc.windPowerUsingDistribution(dst, test.farmPower, test.farmPowerGross)
    assert_approx_equal(test.farmPower, 15_075_000.0, test.e)
    assert_approx_equal(test.farmPowerGross, 15_075_000.0, test.e)