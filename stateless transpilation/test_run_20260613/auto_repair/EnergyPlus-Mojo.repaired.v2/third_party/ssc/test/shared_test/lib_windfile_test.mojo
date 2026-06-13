from testing import Test
from testing import EXPECT_NEAR
from core import *
from lib_windfile import winddata_provider, winddata
from cmod_windpower import *
from ...input_cases.weather_inputs import create_winddata_array

@register_testcase("windDataProviderCalculatorTest")
class windDataProviderCalculatorTest(Test):
    var windDataProvider: winddata_provider
    var e: Float64

    def __init__(inout self):
        self.e = 0.1

    def SetUp(inout self):

    def TearDown(inout self):
        if self.windDataProvider:
            del self.windDataProvider

    @test
    def FindClosestUsingData_lib_windfile_test(inout self):
        var windresourcedata: var_data = create_winddata_array(1, 2)
        self.windDataProvider = winddata(windresourcedata)
        var pres: Float64
        var temp: Float64
        var spd: Float64
        var dir: Float64
        var heightOfClosestMeasuredSpd: Float64
        var heightOfClosestMeasuredDir: Float64
        self.windDataProvider.read[85, &spd, &dir, &temp, &pres, &heightOfClosestMeasuredSpd, &heightOfClosestMeasuredDir, True](wait=True)
        EXPECT_NEAR(pres, 0.975, self.e) << "case 1: hub height can be interpolated."
        EXPECT_NEAR(temp, 52.5, self.e) << "case 1: hub height can be interpolated."
        EXPECT_NEAR(spd, 2.5, self.e) << "case 1: hub height can be interpolated."
        EXPECT_NEAR(dir, 190, self.e) << "case 1: hub height can be interpolated."
        EXPECT_NEAR(heightOfClosestMeasuredSpd, 85, self.e) << "case 1: hub height can be interpolated."
        self.windDataProvider.read[95, &spd, &dir, &temp, &pres, &heightOfClosestMeasuredSpd, &heightOfClosestMeasuredDir, True](wait=True)
        EXPECT_NEAR(pres, 1.0, self.e) << "case 2"
        EXPECT_NEAR(temp, 55, self.e) << "case 2"
        EXPECT_NEAR(spd, 5, self.e) << "case 2"
        EXPECT_NEAR(dir, 200, self.e) << "case 2"
        EXPECT_NEAR(heightOfClosestMeasuredSpd, 90, self.e) << "case 2"