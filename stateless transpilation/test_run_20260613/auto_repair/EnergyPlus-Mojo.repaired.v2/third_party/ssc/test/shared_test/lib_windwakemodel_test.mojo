from testing import *
from vector import *
from io import *
from lib_physics import *
from lib_windwakemodel import *

def createDefaultTurbine(wt: Pointer[windTurbine]):
    wt.shearExponent = 0.14
    wt.measurementHeight = 80
    wt.hubHeight = 80
    wt.rotorDiameter = 77
    var windSpeeds = List[Float64](0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25, 5.5, 5.75, 6, 6.25, 6.5, 6.75, 7, 7.25, 7.5, 7.75, 8, 8.25, 8.5, 8.75, 9, 9.25, 9.5, 9.75, 10, 10.25, 10.5, 10.75, 11, 11.25, 11.5, 11.75, 12, 12.25, 12.5, 12.75, 13, 13.25, 13.5, 13.75, 14, 14.25, 14.5, 14.75, 15, 15.25, 15.5, 15.75, 16, 16.25, 16.5, 16.75, 17, 17.25, 17.5, 17.75, 18, 18.25, 18.5, 18.75, 19, 19.25, 19.5, 19.75, 20, 20.25, 20.5, 20.75, 21, 21.25, 21.5, 21.75, 22, 22.25, 22.5, 22.75, 23, 23.25, 23.5, 23.75, 24, 24.25, 24.5, 24.75, 25, 25.25, 25.5, 25.75, 26, 26.25, 26.5, 26.75, 27, 27.25, 27.5, 27.75, 28, 28.25, 28.5, 28.75, 29, 29.25, 29.5, 29.75, 30, 30.25, 30.5, 30.75, 31, 31.25, 31.5, 31.75, 32, 32.25, 32.5, 32.75, 33, 33.25, 33.5, 33.75, 34, 34.25, 34.5, 34.75, 35, 35.25, 35.5, 35.75, 36, 36.25, 36.5, 36.75, 37, 37.25, 37.5, 37.75, 38, 38.25, 38.5, 38.75, 39, 39.25, 39.5, 39.75, 40)
    var powerOutput = List[Float64](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21.320, 33.510, 45.690, 65.210, 79.830, 104.25, 128.660, 157.970, 187.270, 216.580, 250.780, 292.320, 333.850, 375.400, 426.720, 475.600, 534.270, 597.810, 656.490, 724.940, 798.290, 871.630, 940.080, 1010, 1060, 1130, 1190, 1240, 1290, 1330, 1370, 1390, 1410, 1430, 1440, 1460, 1470, 1475, 1480, 1485, 1490, 1495, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 1500, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    wt.setPowerCurve(windSpeeds, powerOutput)

@value
class windTurbineTest(Test):
    var wt: windTurbine
    var airDensity: Float64
    var e: Float64 = 0.01

    def SetUp(inout self):
        self.airDensity = 1.22498
        self.wt = windTurbine()

@value
class fakeWakeModel(wakeModelBase):
    def __init__(inout self):

    def wakeCalculations(
        inout self, airDensity: Float64, distanceDownwind: Pointer[Float64], distanceCrosswind: Pointer[Float64],
        power: Pointer[Float64], eff: Pointer[Float64], thrust: Pointer[Float64], windSpeed: Pointer[Float64], turbulenceIntensity: Pointer[Float64]):

@value
class simpleWakeModelTest(Test):
    var swm: simpleWakeModel
    var wt: windTurbine
    var numberTurbines: Int
    var distDownwind: List[Float64]
    var distCrosswind: List[Float64]
    var thrust: List[Float64]
    var power: List[Float64]
    var eff: List[Float64]
    var windSpeed: List[Float64]
    var turbIntensity: List[Float64]
    var seaLevelAirDensity: Float64 = physics.AIR_DENSITY_SEA_LEVEL
    var e: Float64 = 0.1

    def SetUp(inout self):
        self.numberTurbines = 3
        self.distDownwind = List[Float64](0, 0, 0)
        self.distCrosswind = List[Float64](0, 0, 0)
        self.thrust = List[Float64](0.47669, 0.47669, 0.47669)
        self.power = List[Float64](1190, 1190, 1190)
        self.eff = List[Float64](0, 0, 0)
        self.windSpeed = List[Float64](0, 0, 0)
        self.turbIntensity = List[Float64](0.1, 0.1, 0.1)
        createDefaultTurbine(Pointer(self.wt))
        self.swm = simpleWakeModel(self.numberTurbines, Pointer(self.wt))
        for i in range(self.numberTurbines):
            self.windSpeed[i] = 10.0

@value
class parkWakeModelTest(Test):
    var pm: parkWakeModel
    var wt: windTurbine
    var numberTurbines: Int
    var distDownwind: List[Float64]
    var distCrosswind: List[Float64]
    var thrust: List[Float64]
    var power: List[Float64]
    var eff: List[Float64]
    var windSpeed: List[Float64]
    var turbIntensity: List[Float64]
    var seaLevelAirDensity: Float64 = physics.AIR_DENSITY_SEA_LEVEL
    var e: Float64 = 0.1

    def SetUp(inout self):
        self.numberTurbines = 3
        self.distDownwind = List[Float64](0, 0, 0)
        self.distCrosswind = List[Float64](0, 0, 0)
        self.thrust = List[Float64](0.47669, 0.47669, 0.47669)
        self.power = List[Float64](1190, 1190, 1190)
        self.eff = List[Float64](0, 0, 0)
        self.windSpeed = List[Float64](0, 0, 0)
        self.turbIntensity = List[Float64](0.1, 0.1, 0.1)
        createDefaultTurbine(Pointer(self.wt))
        self.pm = parkWakeModel(self.numberTurbines, Pointer(self.wt))
        for i in range(self.numberTurbines):
            self.windSpeed[i] = 10.0

@value
class eddyViscosityWakeModelTest(Test):
    var evm: eddyViscosityWakeModel
    var wt: windTurbine
    var numberTurbines: Int
    var turbCoeff: Float64
    var distDownwind: List[Float64]
    var distCrosswind: List[Float64]
    var thrust: List[Float64]
    var power: List[Float64]
    var eff: List[Float64]
    var windSpeed: List[Float64]
    var turbIntensity: List[Float64]
    var seaLevelAirDensity: Float64 = physics.AIR_DENSITY_SEA_LEVEL
    var e: Float64 = 0.1

    def SetUp(inout self):
        self.numberTurbines = 3
        self.distDownwind = List[Float64](0, 0, 0)
        self.distCrosswind = List[Float64](0, 0, 0)
        self.thrust = List[Float64](0.47669, 0.47669, 0.47669)
        self.power = List[Float64](1190, 1190, 1190)
        self.eff = List[Float64](0, 0, 0)
        self.windSpeed = List[Float64](0, 0, 0)
        self.turbIntensity = List[Float64](0.1, 0.1, 0.1)
        createDefaultTurbine(Pointer(self.wt))
        self.evm = eddyViscosityWakeModel(self.numberTurbines, Pointer(self.wt), 0.1)
        for i in range(self.numberTurbines):
            self.windSpeed[i] = 10.0

def test_turbinePowerTest_lib_windwakemodel():
    var test_obj = windTurbineTest()
    test_obj.SetUp()
    var output: Float64 = 0
    var thrustCoeff: Float64 = 0
    test_obj.wt.turbinePower(20.0, test_obj.airDensity, Pointer(output), Pointer[Float64](), Pointer(thrustCoeff))
    expectNear(output, 0.0, test_obj.e) << "Turbine not initialized."
    expectNear(thrustCoeff, 0.0, test_obj.e) << "Turbine not initialized."
    createDefaultTurbine(Pointer(test_obj.wt))
    test_obj.wt.turbinePower(11.25, test_obj.airDensity, Pointer(output), Pointer[Float64](), Pointer(thrustCoeff))
    expectNear(output, 1390, test_obj.e) << "At 11.25m/s, the output should be 1390."
    expectNear(thrustCoeff, 0.3725, test_obj.e) << "At 11.25m/s, the thrust coeff should be 0.3725"
    output = 0
    thrustCoeff = 0
    test_obj.wt.turbinePower(11.25, 0.5, Pointer(output), Pointer[Float64](), Pointer(thrustCoeff))
    expectNear(output, 752.85, test_obj.e) << "Low air density"
    expectNear(thrustCoeff, 0.538, test_obj.e) << "Low air density"

def test_wakeCalcNoInterference_lib_windwakemodel_simple():
    var test_obj = simpleWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 0
        test_obj.distCrosswind[i] = 5 * i
    test_obj.swm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.47669, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 1190, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 100, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 10, test_obj.e) << "No change expected in windspeed at index " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity calculated at index " << i

def test_wakeCalcAllInterference_lib_windwakemodel_simple():
    var test_obj = simpleWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 5 * i
        test_obj.distCrosswind[i] = 0
    test_obj.swm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    var newThrust = List[Float64](0.4767, 0.4256, 0.4154)
    var newPower = List[Float64](1190, 157.6, 145.98)
    var newEff = List[Float64](100, 13.244, 12.267)
    var newWindSpeed = List[Float64](10, 5.247, 5.148)
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], newThrust[i], test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], newPower[i], test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], newEff[i], test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], newWindSpeed[i], test_obj.e) << "windSpeeds at turbine " << i << " should be reduced."
        if i >= 1:
            expectGT(test_obj.turbIntensity[i], 0.1) << "Turb intensity at turbine " << i << " should be increased."

def test_wakeCalcTriangleInterference_lib_windwakemodel_simple():
    var test_obj = simpleWakeModelTest()
    test_obj.SetUp()
    test_obj.distDownwind = List[Float64](0, 5, 5)
    test_obj.distCrosswind = List[Float64](0, -5, 5)
    test_obj.swm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.4767, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 1190, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 100, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 10, test_obj.e) << "Minor wind reduction expected at turbine " << i
        if i >= 1:
            expectNear(test_obj.turbIntensity[i], 0.10031, test_obj.e) << "Turb intensity should be increased at turbine " << i
    expectEq(test_obj.turbIntensity[1], test_obj.turbIntensity[2])

def test_wakeCalcNoInterference_lib_windwakemodel_park():
    var test_obj = parkWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 0
        test_obj.distCrosswind[i] = 5 * i
    test_obj.pm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.47669, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 1190, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 100, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 10, test_obj.e) << "No change expected in windspeed at index " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity calculated at index " << i

def test_wakeCalcAllInterference_lib_windwakemodel_park():
    var test_obj = parkWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 5 * i
        test_obj.distCrosswind[i] = 0
    test_obj.pm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    var newThrust = List[Float64](0.4767, 0.540, 0.507)
    var newPower = List[Float64](1190, 793.1, 423.27)
    var newEff = List[Float64](100, 66.65, 35.6)
    var newWindSpeed = List[Float64](10, 8.48, 6.98)
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], newThrust[i], test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], newPower[i], test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], newEff[i], test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], newWindSpeed[i], test_obj.e) << "windSpeeds at turbine " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity at turbine " << i

def test_wakeCalcTriangleInterference_lib_windwakemodel_park():
    var test_obj = parkWakeModelTest()
    test_obj.SetUp()
    test_obj.distDownwind = List[Float64](0, 5, 5)
    test_obj.distCrosswind = List[Float64](0, -1, 1)
    test_obj.pm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(1, test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.533, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 949.8, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 79.8, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 9.03, test_obj.e) << "Minor wind reduction expected at turbine " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity at turbine " << i
    expectEq(test_obj.turbIntensity[1], test_obj.turbIntensity[2])

def test_wakeCalcNoInterference_lib_windwakemodel_eddy():
    var test_obj = eddyViscosityWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 0
        test_obj.distCrosswind[i] = 5 * i
    test_obj.evm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.47669, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 1190, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 100, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 10, test_obj.e) << "No change expected in windspeed at index " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity calculated at index " << i

def test_wakeCalcAllInterference_lib_windwakemodel_eddy():
    var test_obj = eddyViscosityWakeModelTest()
    test_obj.SetUp()
    for i in range(test_obj.numberTurbines):
        test_obj.distDownwind[i] = 5 * i
        test_obj.distCrosswind[i] = 0
    test_obj.evm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    var newThrust = List[Float64](0.4767, 0.499, 0.443)
    var newPower = List[Float64](1190, 394.9, 188.8)
    var newEff = List[Float64](100, 33.19, 15.87)
    var newWindSpeed = List[Float64](10, 6.84, 5.51)
    for i in range(test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], newThrust[i], test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], newPower[i], test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], newEff[i], test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], newWindSpeed[i], test_obj.e) << "windSpeeds at turbine " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity at turbine " << i

def test_wakeCalcTriangleInterference_lib_windwakemodel_eddy():
    var test_obj = eddyViscosityWakeModelTest()
    test_obj.SetUp()
    test_obj.distDownwind = List[Float64](0, 5, 5)
    test_obj.distCrosswind = List[Float64](0, -1, 1)
    test_obj.evm.wakeCalculations(test_obj.seaLevelAirDensity, Pointer(test_obj.distDownwind[0]), Pointer(test_obj.distCrosswind[0]), Pointer(test_obj.power[0]), Pointer(test_obj.eff[0]), Pointer(test_obj.thrust[0]), Pointer(test_obj.windSpeed[0]), Pointer(test_obj.turbIntensity[0]))
    for i in range(1, test_obj.numberTurbines):
        expectNear(test_obj.thrust[i], 0.531, test_obj.e) << "Thrust calculated at index " << i
        expectNear(test_obj.power[i], 668.1, test_obj.e) << "Power calculated at index " << i
        expectNear(test_obj.eff[i], 56.1, test_obj.e) << "Eff calculated at index " << i
        expectNear(test_obj.windSpeed[i], 8.04, test_obj.e) << "Minor wind reduction expected at turbine " << i
        expectNear(test_obj.turbIntensity[i], 0.1, test_obj.e) << "Turb intensity at turbine " << i
    expectEq(test_obj.turbIntensity[1], test_obj.turbIntensity[2])