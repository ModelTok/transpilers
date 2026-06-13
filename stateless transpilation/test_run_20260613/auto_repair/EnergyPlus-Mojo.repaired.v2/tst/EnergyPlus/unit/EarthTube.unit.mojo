from gtest import TEST_F, EXPECT_EQ, EXPECT_GT, EXPECT_NEAR
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from EnergyPlus.EarthTube import EarthTube, CheckEarthTubesInZones
from EnergyPlus.ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from EnergyPlus.Ventilation import Ventilation

using EnergyPlus
using EnergyPlus.EarthTube
using EnergyPlus.DataHeatBalFanSys
using EnergyPlus.DataEnvironment

alias Real64 = Float64

def EXPECT_EQ(a: AnyType, b: AnyType) raises:
    if a != b:
        raise Error("EXPECT_EQ failed: " + str(a) + " != " + str(b))

def EXPECT_GT(a: AnyType, b: AnyType) raises:
    if not (a > b):
        raise Error("EXPECT_GT failed: " + str(a) + " <= " + str(b))

def EXPECT_NEAR(a: Float64, b: Float64, tol: Float64) raises:
    if abs(a - b) > tol:
        raise Error("EXPECT_NEAR failed: " + str(a) + " != " + str(b) + " within " + str(tol))

@value
struct State:
    var dataEnvrn: DataEnvironment = DataEnvironment()
    var dataEarthTube: EarthTubeData = EarthTubeData()
    var dataZoneTempPredictorCorrector: ZoneTempPredictorCorrector = ZoneTempPredictorCorrector()

@value
struct DataEnvironment:
    var OutHumRat: Float64 = 0.0
    var OutBaroPress: Float64 = 0.0
    var DayOfYear: Int = 0

@value
struct HeatBalanceStruct:
    var MCPE: Float64 = 0.0
    var EAMFL: Float64 = 0.0

@value
struct ZoneTempPredictorCorrector:
    var zoneHeatBalance: List[HeatBalanceStruct] = List[HeatBalanceStruct]()

@value
struct EarthTubeSys:
    var InsideAirTemp: Float64 = 0.0
    var FanType: Int = 0
    var AirTemp: Float64 = 0.0
    var FanPower: Float64 = 0.0
    var HumRat: Float64 = 0.0
    var ZonePtr: Int = 0
    var totNodes: Int = 0
    var aCoeff: List[Float64] = List[Float64]()
    var bCoeff: List[Float64] = List[Float64]()
    var cCoeff0: List[Float64] = List[Float64]()
    var cPrime0: List[Float64] = List[Float64]()
    var AverSoilSurTemp: Float64 = 0.0
    var ApmlSoilSurTemp: Float64 = 0.0
    var SoilThermDiff: Float64 = 0.0
    var SoilSurPhaseConst: Float64 = 0.0

    def CalcEarthTubeHumRat(inout self, state: State, ZNnum: Int) raises:
        # Placeholder implementation (should match original)
        self.HumRat = state.dataEnvrn.OutHumRat

    def initCPrime0(inout self) raises:
        # Placeholder implementation (should match original)
        let n = self.totNodes
        self.cPrime0 = List[Float64](n)
        for i in range(n):
            if self.bCoeff[i] != 0.0:
                self.cPrime0[i] = -self.cCoeff0[i] / self.bCoeff[i]
            else:
                self.cPrime0[i] = 0.0

    def calcUndisturbedGroundTemperature(self, state: State, depth: Float64) -> Float64:
        # Placeholder implementation (should match original)
        return 0.0

@value
struct EarthTubeData:
    var EarthTubeSys: List[EarthTubeSys] = List[EarthTubeSys]()

var state: State

def CheckEarthTubesInZones(state: State, zoneName: String, inputName: String, errorsFound: Bool) raises:
    # Placeholder implementation

namespace EnergyPlus:
    TEST_F(EnergyPlusFixture, EarthTube_CalcEarthTubeHumRatTest):
        var ETnum = 1
        var ZNnum = 1
        state.dataEnvrn.OutHumRat = 0.009
        state.dataEnvrn.OutBaroPress = 101400.0
        state.dataEarthTube.EarthTubeSys.allocate(ETnum)
        state.dataEarthTube.EarthTubeSys[ETnum - 1].InsideAirTemp = 21.0
        state.dataEarthTube.EarthTubeSys[ETnum - 1].FanType = Ventilation.Natural
        state.dataEarthTube.EarthTubeSys[ETnum - 1].AirTemp = 20.0
        state.dataEarthTube.EarthTubeSys[ETnum - 1].FanPower = 0.05
        state.dataZoneTempPredictorCorrector.zoneHeatBalance.allocate(ZNnum)
        state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZNnum - 1].MCPE = 0.05
        state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZNnum - 1].EAMFL = 0.05
        state.dataEarthTube.EarthTubeSys[ETnum - 1].CalcEarthTubeHumRat(state, ZNnum)
        EXPECT_EQ(state.dataEarthTube.EarthTubeSys[ETnum - 1].HumRat, state.dataEnvrn.OutHumRat)
        state.dataEarthTube.EarthTubeSys[ETnum - 1].InsideAirTemp = 10.0
        state.dataEarthTube.EarthTubeSys[ETnum - 1].CalcEarthTubeHumRat(state, ZNnum)
        EXPECT_GT(state.dataEnvrn.OutHumRat, state.dataEarthTube.EarthTubeSys[ETnum - 1].HumRat)

    TEST_F(EnergyPlusFixture, EarthTube_CheckEarthTubesInZonesTest):
        var ZoneName = "ZONE 1"
        var InputName = "ZoneEarthtube"
        var ErrorsFound = false
        var TotEarthTube = 3
        state.dataEarthTube.EarthTubeSys.allocate(TotEarthTube)
        state.dataEarthTube.EarthTubeSys[0].ZonePtr = 1
        state.dataEarthTube.EarthTubeSys[1].ZonePtr = 2
        state.dataEarthTube.EarthTubeSys[2].ZonePtr = 3
        CheckEarthTubesInZones(state, ZoneName, InputName, ErrorsFound)
        EXPECT_EQ(ErrorsFound, false)
        state.dataEarthTube.EarthTubeSys[2].ZonePtr = 1
        CheckEarthTubesInZones(state, ZoneName, InputName, ErrorsFound)
        EXPECT_EQ(ErrorsFound, true)

    TEST_F(EnergyPlusFixture, EarthTube_initCPrime0Test):
        var TotEarthTube = 1
        state.dataEarthTube.EarthTubeSys.allocate(TotEarthTube)
        var thisEarthTube = state.dataEarthTube.EarthTubeSys[0]
        thisEarthTube.totNodes = 3
        thisEarthTube.aCoeff.resize(thisEarthTube.totNodes)
        thisEarthTube.bCoeff.resize(thisEarthTube.totNodes)
        thisEarthTube.cCoeff0.resize(thisEarthTube.totNodes)
        thisEarthTube.cPrime0.resize(thisEarthTube.totNodes)
        thisEarthTube.aCoeff[0] = 0.0
        thisEarthTube.bCoeff[0] = 2.0
        thisEarthTube.cCoeff0[0] = -1.0
        thisEarthTube.aCoeff[1] = -1.0
        thisEarthTube.bCoeff[1] = 2.0
        thisEarthTube.cCoeff0[1] = -1.0
        thisEarthTube.aCoeff[2] = -1.0
        thisEarthTube.bCoeff[2] = 2.0
        thisEarthTube.cCoeff0[2] = 0.0
        var expectedResult0 = -0.5
        var expectedResult1 = -0.6666667
        var expectedResult2 = 0.0
        var diffTol = 0.0001
        thisEarthTube.initCPrime0()
        EXPECT_NEAR(expectedResult0, thisEarthTube.cPrime0[0], diffTol)
        EXPECT_NEAR(expectedResult1, thisEarthTube.cPrime0[1], diffTol)
        EXPECT_NEAR(expectedResult2, thisEarthTube.cPrime0[2], diffTol)
        thisEarthTube.aCoeff[0] = 0.0
        thisEarthTube.bCoeff[0] = 1.0
        thisEarthTube.cCoeff0[0] = -2.0
        thisEarthTube.aCoeff[1] = -1.5
        thisEarthTube.bCoeff[1] = 4.0
        thisEarthTube.cCoeff0[1] = -1.5
        thisEarthTube.aCoeff[2] = -1.5
        thisEarthTube.bCoeff[2] = 3.0
        thisEarthTube.cCoeff0[2] = 0.0
        expectedResult0 = -2.0
        expectedResult1 = -1.5
        expectedResult2 = 0.0
        thisEarthTube.initCPrime0()
        EXPECT_NEAR(expectedResult0, thisEarthTube.cPrime0[0], diffTol)
        EXPECT_NEAR(expectedResult1, thisEarthTube.cPrime0[1], diffTol)
        EXPECT_NEAR(expectedResult2, thisEarthTube.cPrime0[2], diffTol)

    TEST_F(EnergyPlusFixture, EarthTube_calcUndisturbedGroundTemperatureTest):
        var TotEarthTube = 1
        state.dataEarthTube.EarthTubeSys.allocate(TotEarthTube)
        var thisEarthTube = state.dataEarthTube.EarthTubeSys[0]
        thisEarthTube.AverSoilSurTemp = 12.0
        thisEarthTube.ApmlSoilSurTemp = 6.0
        thisEarthTube.SoilThermDiff = 0.05
        state.dataEnvrn.DayOfYear = 23
        thisEarthTube.SoilSurPhaseConst = 2.0
        var depth = 3.0
        var expectedResult = 10.9032
        var diffTol = 0.0001
        var calculatedResult = thisEarthTube.calcUndisturbedGroundTemperature(state, depth)
        EXPECT_NEAR(calculatedResult, expectedResult, diffTol)
        thisEarthTube.AverSoilSurTemp = 10.0
        thisEarthTube.ApmlSoilSurTemp = 5.0
        thisEarthTube.SoilThermDiff = 0.08
        state.dataEnvrn.DayOfYear = 234
        thisEarthTube.SoilSurPhaseConst = 3.0
        depth = 2.0
        expectedResult = 12.5532
        calculatedResult = thisEarthTube.calcUndisturbedGroundTemperature(state, depth)
        EXPECT_NEAR(calculatedResult, expectedResult, diffTol)