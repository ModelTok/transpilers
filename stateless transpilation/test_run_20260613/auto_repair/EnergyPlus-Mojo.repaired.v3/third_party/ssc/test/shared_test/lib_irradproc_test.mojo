
from lib_irradproc import irrad, solarpos, solarpos_spa, incidence, truetrack, backtrack, shadeFraction1x
from memory import DynamicVector
from math import pi
from random import randint

# Assume SSCDIR is defined as an environment variable or constant
alias SSCDIR: String = "/home/bart/Github/EnergyPlus-Mojo/third_party/ssc"

/**
* \class IrradTest
*
* Month: 1-12, Hour: 0-23, Minute: 0-59.
*
*/
class IrradTest:
    var lat: Float64
    var lon: Float64
    var tz: Float64
    var alb: Float64
    var tilt: Float64
    var azim: Float64
    var rotlim: Float64
    var gcr: Float64
    var elev: Float64
    var pres: Float64
    var tdry: Float64
    var year: Int
    var month: Int
    var day: Int
    var skymodel: Int
    var tracking: Int
    var backtrack_on: Bool
    var calc_sunrise: Float64
    var calc_sunset: Float64
    var e: Float64

    def SetUp(self):
        self.lat = 31.6340
        self.lon = 74.8723
        self.tz = 5.5
        self.year = 2017
        self.month = 7
        self.day = 19
        self.skymodel = 2
        self.alb = 0.2
        self.tracking = 0
        self.tilt = 10
        self.azim = 180
        self.rotlim = 0
        self.backtrack_on = False
        self.gcr = 0
        self.e = 0.0001
        self.pres = 1013.25
        self.elev = 234
        self.tdry = 15
        self.calc_sunrise = 5.70924 # 5:43 am
        self.calc_sunset = 19.5179  # 7:31 pm

class NightCaseIrradProc(IrradTest):
    var irr_hourly_night: irrad
    var irr_15m_night: irrad

    def SetUp(self):
        IrradTest.SetUp(self)
        var night_hr: Int = 1
        self.irr_hourly_night = irrad()
        self.irr_hourly_night.set_time(self.year, self.month, self.day, night_hr, 30, 1)
        self.irr_hourly_night.set_location(self.lat, self.lon, self.tz)
        self.irr_hourly_night.set_optional(self.elev, self.pres, self.tdry)
        self.irr_hourly_night.set_sky_model(self.skymodel, self.alb)
        self.irr_hourly_night.set_beam_diffuse(0, 0)
        self.irr_hourly_night.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

        self.irr_15m_night = irrad()
        self.irr_15m_night.set_time(self.year, self.month, self.day, night_hr, 15, -1)
        self.irr_15m_night.set_location(self.lat, self.lon, self.tz)
        self.irr_15m_night.set_optional(self.elev, self.pres, self.tdry)
        self.irr_15m_night.set_sky_model(self.skymodel, self.alb)
        self.irr_15m_night.set_beam_diffuse(0, 0)
        self.irr_15m_night.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

class SunriseCaseIrradProc(IrradTest):
    var irr_hourly_sunrise: irrad
    var irr_15m_sunrise: irrad

    def SetUp(self):
        IrradTest.SetUp(self)
        var sr_hr: Int = 5
        self.irr_hourly_sunrise = irrad()
        self.irr_hourly_sunrise.set_time(self.year, self.month, self.day, sr_hr, 30, 1)
        self.irr_hourly_sunrise.set_location(self.lat, self.lon, self.tz)
        self.irr_hourly_sunrise.set_optional(self.elev, self.pres, self.tdry)
        self.irr_hourly_sunrise.set_sky_model(self.skymodel, self.alb)
        self.irr_hourly_sunrise.set_beam_diffuse(0, 1)
        self.irr_hourly_sunrise.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

        self.irr_15m_sunrise = irrad()
        self.irr_15m_sunrise.set_time(self.year, self.month, self.day, sr_hr, 30, 1)
        self.irr_15m_sunrise.set_location(self.lat, self.lon, self.tz)
        self.irr_15m_sunrise.set_optional(self.elev, self.pres, self.tdry)
        self.irr_15m_sunrise.set_sky_model(self.skymodel, self.alb)
        self.irr_15m_sunrise.set_beam_diffuse(0, 1)
        self.irr_15m_sunrise.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

class DayCaseIrradProc(IrradTest):
    var irr_hourly_day: irrad
    var irr_15m_day: irrad

    def SetUp(self):
        IrradTest.SetUp(self)
        var day_hr: Int = 12
        self.irr_hourly_day = irrad()
        self.irr_hourly_day.set_time(self.year, self.month, self.day, day_hr, 30, 1)
        self.irr_hourly_day.set_location(self.lat, self.lon, self.tz)
        self.irr_hourly_day.set_optional(self.elev, self.pres, self.tdry)
        self.irr_hourly_day.set_sky_model(self.skymodel, self.alb)
        self.irr_hourly_day.set_beam_diffuse(2, 2)
        self.irr_hourly_day.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

        self.irr_15m_day = irrad()
        self.irr_15m_day.set_time(self.year, self.month, self.day, day_hr, 45, 1)
        self.irr_15m_day.set_location(self.lat, self.lon, self.tz)
        self.irr_15m_day.set_optional(self.elev, self.pres, self.tdry)
        self.irr_15m_day.set_sky_model(self.skymodel, self.alb)
        self.irr_15m_day.set_beam_diffuse(2, 2)
        self.irr_15m_day.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

class SunsetCaseIrradProc(IrradTest):
    var irr_hourly_sunset: irrad
    var irr_15m_sunset: irrad

    def SetUp(self):
        IrradTest.SetUp(self)
        var ss_hr: Int = 19
        self.irr_hourly_sunset = irrad()
        self.irr_hourly_sunset.set_time(self.year, self.month, self.day, ss_hr, 30, 1)
        self.irr_hourly_sunset.set_location(self.lat, self.lon, self.tz)
        self.irr_hourly_sunset.set_optional(self.elev, self.pres, self.tdry)
        self.irr_hourly_sunset.set_sky_model(self.skymodel, self.alb)
        self.irr_hourly_sunset.set_beam_diffuse(0, 1)
        self.irr_hourly_sunset.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

        self.irr_15m_sunset = irrad()
        self.irr_15m_sunset.set_time(self.year, self.month, self.day, ss_hr, 30, 1)
        self.irr_15m_sunset.set_location(self.lat, self.lon, self.tz)
        self.irr_15m_sunset.set_optional(self.elev, self.pres, self.tdry)
        self.irr_15m_sunset.set_sky_model(self.skymodel, self.alb)
        self.irr_15m_sunset.set_beam_diffuse(0, 1)
        self.irr_15m_sunset.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack_on, self.gcr, False, 0.0)

/**
*    Test which uses the example in bifacialvf.py within github.com/NREL/bifacialvf
*/
class BifacialIrradTest:
    var tilt: Float64
    var azim: Float64
    var transmissionFactor: Float64
    var bifaciality: Float64
    var gcr: Float64
    var rotlim: Float64
    var albedo: Float64
    var slopeLength: Float64
    var rowToRow: Float64
    var clearanceGround: Float64
    var distanceBetweenRows: Float64
    var verticalHeight: Float64
    var horizontalLength: Float64
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var solarAzimuthRadians: Float64
    var solarZenithRadians: Float64
    var solarElevationRadians: Float64
    var lat: Float64
    var lon: Float64
    var tz: Float64
    var tracking: Int
    var skyModel: Int
    var backtrack: Bool
    var irr: irrad
    var beam: Float64
    var diffuse: Float64
    var e: Float64
    var elev: Float64
    var tdry: Float64
    var pres: Float64
    var frontSkyConfigFactorsFile: String
    var rearSkyConfigFactorsFile: String
    var pvBackSHFile: String
    var pvFrontSHFile: String
    var frontGroundShadeFile: String
    var rearGroundShadeFile: String
    var frontGroundGHIFile: String
    var rearGroundGHIFile: String
    var frontIrradianceFile: String
    var frontReflectedFile: String
    var rearIrradianceFile: String
    var weatherFile: String
    var averageIrradianceFile: String
    var expectedPVFrontShadeFraction: DynamicVector[Float64]
    var expectedPVRearShadeFraction: DynamicVector[Float64]
    var expectedFrontSkyConfigFactors: DynamicVector[Float64]
    var expectedRearSkyConfigFactors: DynamicVector[Float64]
    var expectedFrontGroundShade: DynamicVector[Int32]
    var expectedRearGroundShade: DynamicVector[Int32]
    var expectedFrontGroundGHI: DynamicVector[Float64]
    var expectedRearGroundGHI: DynamicVector[Float64]
    var expectedFrontReflected: DynamicVector[Float64]
    var expectedFrontIrradiance: DynamicVector[Float64]
    var expectedRearIrradiance: DynamicVector[Float64]
    var expectedAverageIrradiance: DynamicVector[Float64]
    var numberOfTimeSteps: Int
    var numberOfSamples: Int
    var samples: DynamicVector[Int32]

    def SetUp(self):
        self.tilt = 10
        self.azim = 180
        self.gcr = 0.666667
        self.e = 0.01
        self.tracking = 0
        self.rotlim = 90
        self.backtrack = False
        self.albedo = 0.62
        self.skyModel = 2 # perez
        self.transmissionFactor = 0.013
        self.bifaciality = 0.65
        self.slopeLength = 1.                                        # The unit slope length of the panel
        self.rowToRow = 1.5                                          # Row to row spacing between the front of one row to the front of the next row
        var tiltRadian: Float64 = self.tilt * 3.141592653589793 / 180.
        self.clearanceGround = 0.2                                   # The normalized clearance from the bottom edge of module to ground
        self.distanceBetweenRows = self.rowToRow - _math_cos(tiltRadian)   # The normalized distance from the read of module to front of module in next row
        self.verticalHeight = _math_sin(tiltRadian)
        self.horizontalLength = _math_cos(tiltRadian)
        self.lat = 37.517
        self.lon = -77.317
        self.tz = -5.0
        self.elev = 1730
        self.tdry = 15
        self.pres = 1013.25
        # char frontSkyConfigFactorsFile[256];
        # char resource_matrix[256];
        # int nb2 = sprintf(resource_matrix, "%s/test/input_cases/mhk/wave_resource_matrix.csv", SSCDIR);
        # int nb3 = sprintf(device_matrix, "%s/test/input_cases/mhk/wave_power_matrix.csv", SSCDIR);
        var sscdir: String = SSCDIR
        self.frontSkyConfigFactorsFile = sscdir + "/test/input_cases/bifacialvf_data/expectedFrontSkyConfigFactors.txt"
        self.rearSkyConfigFactorsFile = sscdir + "/test/input_cases/bifacialvf_data/expectedRearSkyConfigFactors.txt"
        self.pvFrontSHFile = sscdir + "/test/input_cases/bifacialvf_data/expectedPVFrontSH.txt"
        self.pvBackSHFile = sscdir + "/test/input_cases/bifacialvf_data/expectedPVBackSH.txt"
        self.frontGroundShadeFile = sscdir + "/test/input_cases/bifacialvf_data/expectedFrontGroundShade.txt"
        self.rearGroundShadeFile = sscdir + "/test/input_cases/bifacialvf_data/expectedRearGroundShade.txt"
        self.frontGroundGHIFile = sscdir + "/test/input_cases/bifacialvf_data/expectedFrontGroundGHI.txt"
        self.rearGroundGHIFile = sscdir + "/test/input_cases/bifacialvf_data/expectedRearGroundGHI.txt"
        self.frontIrradianceFile = sscdir + "/test/input_cases/bifacialvf_data/expectedFrontIrradiance.txt"
        self.rearIrradianceFile = sscdir + "/test/input_cases/bifacialvf_data/expectedRearIrradiance.txt"
        self.frontReflectedFile = sscdir + "/test/input_cases/bifacialvf_data/expectedFrontReflected.txt"
        self.weatherFile = sscdir + "/test/input_cases/bifacialvf_data/expectedWeather.txt"
        self.averageIrradianceFile = sscdir + "/test/input_cases/bifacialvf_data/expectedAverageIrradiance.txt"
        self.readDataFromTextFile(self.pvBackSHFile, self.expectedPVRearShadeFraction)
        self.readDataFromTextFile(self.pvFrontSHFile, self.expectedPVFrontShadeFraction)
        self.readDataFromTextFile(self.frontSkyConfigFactorsFile, self.expectedFrontSkyConfigFactors)
        self.readDataFromTextFile(self.rearSkyConfigFactorsFile, self.expectedRearSkyConfigFactors)
        self.numberOfTimeSteps = self.expectedPVRearShadeFraction.size()
        self.numberOfSamples = 10
        self.createSamples()
        self.irr = irrad()
        self.runIrradCalc(0)

    def TearDown(self):
        # No destructor needed; Mojo handles memory.

    def createSamples(self):
        for i in range(self.numberOfSamples):
            var index: Int = randint(0, self.numberOfTimeSteps - 1)
            self.samples.push_back(index)

    def runIrradCalc(self, index: Int):
        var expectedWeather: DynamicVector[Float64] = DynamicVector[Float64]()
        self.readLineFromTextFile[Float64](self.weatherFile, index, expectedWeather)
        self.year = __int__(expectedWeather[0])
        self.month = __int__(expectedWeather[1])
        self.day = __int__(expectedWeather[2])
        self.hour = __int__(expectedWeather[3])
        self.minute = __int__(expectedWeather[4])
        self.beam = expectedWeather[5]
        self.diffuse = expectedWeather[6]
        self.solarAzimuthRadians = expectedWeather[7]
        self.solarZenithRadians = expectedWeather[8]
        self.solarElevationRadians = expectedWeather[9]
        self.irr.set_surface(self.tracking, self.tilt, self.azim, self.rotlim, self.backtrack, self.gcr, False, 0.0)
        self.irr.set_beam_diffuse(self.beam, self.diffuse)
        self.irr.set_time(self.year, self.month, self.day, self.hour, self.minute, 1)
        self.irr.set_location(self.lat, self.lon, self.tz)
        self.irr.set_optional(self.elev, self.pres, self.tdry)
        self.irr.set_sky_model(self.skyModel, self.albedo)
        self.irr.calc()
        self.irr.set_sun_component(0, self.solarAzimuthRadians)
        self.irr.set_sun_component(1, self.solarZenithRadians)
        self.irr.set_sun_component(2, self.solarElevationRadians)

    def readLineFromTextFile[T: AnyType](self, fileName: String, lineNumber: Int, data: DynamicVector[T]):
        var n: Int = data.size()
        if n > 0:
            data.clear()
            # data.reserve(n) not needed in Mojo DynamicVector
        var dataFile: Optional[File] # We'll use Python-like file I/O via open
        var line: String
        var count: Int = 0
        var maxTries: Int = 5
        var resolvedFileName = fileName
        while True:
            var file = open(resolvedFileName, "r")
            if file.is_valid():
                dataFile = file
                break
            if count >= maxTries:
                break
            var prefix: String = "../"
            resolvedFileName = prefix + resolvedFileName
            count += 1
        if dataFile:
            var currentLine: Int = 0
            while currentLine <= lineNumber:
                line = dataFile.read_line()
                if dataFile.eof():
                    break
                currentLine += 1
            var ss = line
            var tmpData = ss.split(" ")
            for elem in tmpData:
                data.push_back(T(elem))

    def readDataFromTextFile(self, fileName: String, data: DynamicVector[Float64]):
        var n: Int = data.size()
        if n > 0:
            data.clear()
        var dataFile: Optional[File]
        var line: String
        var count: Int = 0
        var maxTries: Int = 5
        var resolvedFileName = fileName
        while True:
            var file = open(resolvedFileName, "r")
            if file.is_valid():
                dataFile = file
                break
            if count >= maxTries:
                break
            var prefix: String = "../"
            resolvedFileName = prefix + resolvedFileName
            count += 1
        if dataFile:
            while not dataFile.eof():
                line = dataFile.read_line()
                if dataFile.eof():
                    break
                var ss = line
                var tmpData = ss.split(" ")
                for elem in tmpData:
                    data.push_back(Float64(elem))

# Helper functions for math (since Mojo's stdlib might not have sin/cos in Float64 directly)
def _math_cos(x: Float64) -> Float64:
    return __builtin__._math_cos(x)

def _math_sin(x: Float64) -> Float64:
    return __builtin__._math_sin(x)

# Test functions
/**
 * Solar Position Function Tests
 * Output: sun[] = azimuth (rad), zenith(rad), elevation(rad), declination(rad), sunrise time, sunset time,
 * eccentricity correction factor, true solar time, extraterrestrial solar irradiance on horizontal (W/m2)
 */
@test
def solarposTest_lib_irradproc_NightCase():
    var fixture = NightCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var e: Float64 = 0.0001
    /* Just before sunrise test case */
    solarpos(fixture.year, fixture.month, fixture.day, 4, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([0.95662, 1.79457, -0.223771, 0.363938, 5.70882, 19.5183, 0.968276, 3.88646, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], e)  # approximate comparison not built-in; use simple check for faithfulness
    /* 15m before sunrise */
    solarpos(fixture.year, fixture.month, fixture.day, 5, 15, fixture.lat, fixture.lon, fixture.tz, sun)
    solution = DynamicVector[Float64]([1.0744, 1.65255, -0.0817513, 0.363839, 5.7091, 19.518, 0.96828, 4.63642, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], e)
    /* Just after sunset test case */
    solarpos(fixture.year, fixture.month, fixture.day, 20, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    solution = DynamicVector[Float64]([5.28748, 1.75391, -0.183117, 0.361807, 5.71544, 19.5131, 0.968361, 19.8857, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], e)
    /* 15m after sunset */
    solarpos(fixture.year, fixture.month, fixture.day, 19, 45, fixture.lat, fixture.lon, fixture.tz, sun)
    solution = DynamicVector[Float64]([5.17431, 1.60864, -0.0378397, 0.361908, 5.71513, 19.5133, 0.968357, 19.1358, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], e)

@test
def solarposTest_lib_irradproc_SunriseCase():
    var fixture = SunriseCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    solarpos(fixture.year, fixture.month, fixture.day, 5, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([1.11047, 1.6031, -0.0323028, 0.363806, 5.70924, 19.5179, 0.968281, 4.88641, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)

@test
def sunriseAndSunsetAtDifferentLocationsTest_lib_irradproc():
    var fixture = IrradTest()
    fixture.SetUp()
    fixture.e = 0.001
    var latitudes: DynamicVector[Float64] = DynamicVector[Float64]([39.77, 52.5, -12.03, 40.43, -17.75, 66.9, 68.35, 66.9])
    var longitudes: DynamicVector[Float64] = DynamicVector[Float64]([-105.22, 13.3, -77.06, -3.72, -179.3, -162.6, -166.8, -162.6])
    var time_zones: DynamicVector[Float64] = DynamicVector[Float64]([-7, 1, -5, 1, 12, -9, -9, -9])
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]([4.636, 3.849, 6.521, 5.833, 6.513, -100.0, 2.552, -100.0])
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]([19.455, 20.436, 17.814, 20.723, 17.449, 100.0, 25.885, 100.0])
    var month: DynamicVector[Int] = DynamicVector[Int]([6, 6, 6, 6, 6, 6, 7, 6])
    var day: DynamicVector[Int] = DynamicVector[Int]([21, 21, 21, 21, 21, 21, 14, 11])
    var sun_results: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    for i in range(latitudes.size()):
        solarpos(2010, month[i], day[i], 14, 30, latitudes[i], longitudes[i], time_zones[i], sun_results)
        expect(sun_results[4] == sunrise_times[i], fixture.e)
        expect(sun_results[5] == sunset_times[i], fixture.e)

@test
def sunriseAndSunsetAtDifferentLocationsTest_spa_lib_irradproc():
    var fixture = IrradTest()
    fixture.SetUp()
    fixture.e = 0.001
    var latitudes: DynamicVector[Float64] = DynamicVector[Float64]([39.77, 52.5, -12.03, 40.43, -17.75, 66.9, 68.35, 66.9])
    var longitudes: DynamicVector[Float64] = DynamicVector[Float64]([-105.22, 13.3, -77.06, -3.72, -179.3, -162.6, -166.8, -162.6])
    var time_zones: DynamicVector[Float64] = DynamicVector[Float64]([-7, 1, -5, 1, 12, -9, -9, -9])
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]([4.549, 3.726, 6.458, 5.745, 6.451, -100.0, 2.7831, -100.0])
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]([19.541, 20.559, 17.877, 20.810, 17.514, 100.0, 25.4795, 100.0])
    var month: DynamicVector[Int] = DynamicVector[Int]([6, 6, 6, 6, 6, 6, 7, 6])
    var day: DynamicVector[Int] = DynamicVector[Int]([21, 21, 21, 21, 21, 21, 20, 11])
    var alt: DynamicVector[Int] = DynamicVector[Int]([1730, 34, 154, 667, 0, 6, 2, 6])
    var sun_results: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    for i in range(latitudes.size()):
        solarpos_spa(2010, month[i], day[i], 14, 30, 0, latitudes[i], longitudes[i], time_zones[i], 0, alt[i], 0, 1016, 15, 180, sun_results)
        expect(sun_results[4] == sunrise_times[i], fixture.e)
        expect(sun_results[5] == sunset_times[i], fixture.e)

@test
def sunriseAndSunsetAlaskaTest_spa_lib_irradproc():
    var fixture = IrradTest()
    fixture.SetUp()
    fixture.e = 0.001
    var latitude: Float64 = -17.75
    var longitude: Float64 = -179.3
    var time_zone: Float64 = 12
    var sunrise_time: Float64 = 6.451
    var sunset_time: Float64 = 17.514
    var month: Int = 6
    var day: Int = 21
    var sun_results: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var alt: Int = 0
    solarpos_spa(2010, month, day, 14, 30, 0, latitude, longitude, time_zone, 0, 2, 1016, 15, latitude, 180, sun_results)
    expect(sun_results[4] == sunrise_time, fixture.e)
    expect(sun_results[5] == sunset_time, fixture.e)

@test
def atmos_refractionTest_spa_lib_irradproc():
    var fixture = IrradTest()
    fixture.SetUp()
    var latitude: Float64 = 31.6430
    var longitude: Float64 = 74.8723
    var time_zone: Float64 = 5.5
    var elevation_angle: Float64 = -.00175
    var month: Int = 7
    var day: Int = 19
    var sun_results: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var alt: Int = 0
    solarpos_spa(2017, month, day, 5, 39, 0, latitude, longitude, time_zone, 0, 234, 1013.25, 15, latitude, 180, sun_results)
    expect(sun_results[2] == elevation_angle, fixture.e)

@test
def solarposTest_lib_irradproc_DayCase():
    var fixture = DayCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    /* Just before sunset test case */
    solarpos(fixture.year, fixture.month, fixture.day, 18, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([5.01022, 1.3584, 0.212397, 0.362076, 5.71461, 19.5137, 0.96835, 17.8858, 279.08756])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)
    solarpos(fixture.year, fixture.month, fixture.day, 19, 15, fixture.lat, fixture.lon, fixture.tz, sun)
    solution = DynamicVector[Float64]([5.10579, 1.51295, 0.0578472, 0.361975, 5.71492, 19.5135, 0.968354, 18.6358, 76.5423])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)
    /* Sunset time test case */
    solarpos(fixture.year, fixture.month, fixture.day, 19, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    solution = DynamicVector[Float64]([5.13947, 1.55886, 0.0119379, 0.361941, 5.71503, 19.5134, 0.968356, 18.8858, 15.8044])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)

@test
def solarposTest_lib_irradproc_SunsetCase():
    var fixture = SunsetCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    /* Sunset time test case */
    solarpos(fixture.year, fixture.month, fixture.day, 19, 30, fixture.lat, fixture.lon, fixture.tz, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([5.13947, 1.55886, 0.0119379, 0.361941, 5.71503, 19.5134, 0.968356, 18.8858, 15.8044])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)

/**
* Solar Incidence Function Test
* Mode = 0 for fixed tilt.
* Output: angle[] = incident angle (rad), tilt angle (rad), surface azimuth (rad), tracking axis rotation angle for single axis tracker (rad),
* backtracking angle difference: rot - ideal_rot (rad)
*/
@test
def solarpos_spaTest_lib_irradproc_NightCase():
    var fixture = NightCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var needed: DynamicVector[Float64] = DynamicVector[Float64](13, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    fixture.e = 0.0001
    /* Just before sunrise test case */
    solarpos_spa(fixture.year, fixture.month, fixture.day, 4, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 0, 1016, 15, fixture.lat, 180, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([0.95668, 1.80432, -0.233522, 0.363905, 5.636927, 19.584888, 0.968276, 3.88691, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)
    solarpos_spa(fixture.year, fixture.month, fixture.day, 5, 15, 0, fixture.lat, fixture.lon, fixture.tz, 0, 0, 1016, 15, fixture.lat, 180, sun)
    solution = DynamicVector[Float64]([1.0744, 1.6623, -0.091497, 0.363809, 5.636927, 19.584888, 0.96828, 4.63687, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)
    /* Just after sunset test case */
    solarpos_spa(fixture.year, fixture.month, fixture.day, 20, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    solution = DynamicVector[Float64]([5.28754, 1.76380, -0.19300, 0.361775, 5.636927, 19.584888, 0.968361, 19.88618, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)
    solarpos_spa(fixture.year, fixture.month, fixture.day, 19, 45, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    solution = DynamicVector[Float64]([5.17436, 1.618526, -0.047730, 0.361878, 5.636927, 19.584888, 0.968357, 19.13621, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)

@test
def solarpos_spaTest_lib_irradproc_SunriseCase():
    var fixture = SunriseCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var needed: DynamicVector[Float64] = DynamicVector[Float64](13, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    fixture.e = 0.0001
    solarpos_spa(fixture.year, fixture.month, fixture.day, 5, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([1.11053, 1.61284, -0.0420474, 0.363777, 5.636927, 19.584888, 0.968281, 4.88686, 0])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)

@test
def solarpos_spaTest_lib_irradproc_DayCase():
    var fixture = DayCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var needed: DynamicVector[Float64] = DynamicVector[Float64](13, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    /* Just before sunset test case */
    solarpos_spa(fixture.year, fixture.month, fixture.day, 18, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([5.01026, 1.35848, 0.212317, 0.36205, 5.636927, 19.584888, 0.96835, 17.88626, 278.9899])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)
    solarpos_spa(fixture.year, fixture.month, fixture.day, 19, 15, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    solution = DynamicVector[Float64]([5.10583, 1.51323, 0.057570, 0.361947, 5.636927, 19.584888, 0.968358, 18.6362, 76.1906])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)
    /* Sunset time test case */
    solarpos_spa(fixture.year, fixture.month, fixture.day, 19, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    solution = DynamicVector[Float64]([5.13951, 1.56025, 0.010544, 0.361913, 5.636927, 19.584888, 0.968356, 18.88622, 13.9890])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], 0.0001)

@test
def solarpos_spaTest_lib_irradproc_SunsetCase():
    var fixture = SunsetCaseIrradProc()
    fixture.SetUp()
    var sun: DynamicVector[Float64] = DynamicVector[Float64](9, 0.0)
    var needed: DynamicVector[Float64] = DynamicVector[Float64](13, 0.0)
    var sunrise_times: DynamicVector[Float64] = DynamicVector[Float64]()
    var sunset_times: DynamicVector[Float64] = DynamicVector[Float64]()
    fixture.e = 0.0001
    solarpos_spa(fixture.year, fixture.month, fixture.day, 19, 30, 0, fixture.lat, fixture.lon, fixture.tz, 0, 234, 1016, 15, fixture.lat, 180, sun)
    var solution: DynamicVector[Float64] = DynamicVector[Float64]([5.13951, 1.56025, 0.010544, 0.361913, 5.636927, 19.584888, 0.968356, 18.88622, 13.98903])
    sunrise_times.push_back(solution[4])
    sunset_times.push_back(solution[5])
    for i in range(9):
        expect(sun[i] == solution[i], fixture.e)

@test
def incidenceTest_lib_irradproc_NightCase():
    var fixture = NightCaseIrradProc()
    fixture.SetUp()
    var mode: Int = 0
    var angle: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var sun_zen: Float64
    var sun_azm: Float64
    var solutions: DynamicVector[Float64]
    /* Just before sunrise test case */
    sun_azm = 0.95662
    sun_zen = 1.79457
    incidence(mode, fixture.tilt, fixture.azim, fixture.rotlim, sun_zen, sun_azm, fixture.backtrack_on, fixture.gcr, False, 0.0, angle)
    solutions = DynamicVector[Float64]([1.89243, 0.174533, 3.14159, 0, 0])
    for i in range(5):
        expect(angle[i] == solutions[i], 0.0001)

@test
def incidenceTest_lib_irradproc_SunriseCase():
    var fixture = SunriseCaseIrradProc()
    fixture.SetUp()
    var mode: Int = 0
    var angle: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var sun_zen: Float64
    var sun_azm: Float64
    var solution: Float64
    var solutions: DynamicVector[Float64]
    sun_azm = 1.11047
    sun_zen = 1.6031
    incidence(mode, fixture.tilt, fixture.azim, fixture.rotlim, sun_zen, sun_azm, fixture.backtrack_on, fixture.gcr, False, 0.0, angle)
    solution = 1.67992
    expect(angle[0] == solution, 0.0001)

@test
def incidenceTest_lib_irradproc_DayCase():
    var fixture = DayCaseIrradProc()
    fixture.SetUp()
    var mode: Int = 0
    var angle: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var sun_zen: Float64
    var sun_azm: Float64
    var solution: Float64
    var solutions: DynamicVector[Float64]
    sun_azm = 0
    sun_zen = 0
    incidence(mode, fixture.tilt, fixture.azim, fixture.rotlim, sun_zen, sun_azm, fixture.backtrack_on, fixture.gcr, False, 0.0, angle)
    solution = 0.174533
    expect(angle[0] == solution, 0.0001)

@test
def incidenceTest_lib_irradproc_SunsetCase():
    var fixture = SunsetCaseIrradProc()
    fixture.SetUp()
    var mode: Int = 0
    var angle: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var sun_zen: Float64
    var sun_azm: Float64
    var solution: Float64
    var solutions: DynamicVector[Float64]
    sun_azm = 5.13947
    sun_zen = 1.55886
    incidence(mode, fixture.tilt, fixture.azim, fixture.rotlim, sun_zen, sun_azm, fixture.backtrack_on, fixture.gcr, False, 0.0, angle)
    solution = 1.631
    expect(angle[0] == solution, 0.0001)

/**
* Calc Function Tests
* Output:
* sun[] =	azimuth (rad), zenith(rad), elevation(rad), declination(rad), sunrise time, sunset time,
*			eccentricity correction factor, true solar time, extraterrestrial solar irradiance on horizontal (W/m2);
* angle_p[] = incident angle (rad), tilt angle (rad), surface azimuth (rad), tracking axis rotation angle for single axis tracker (rad),
*			backtracking angle difference: rot - ideal_rot (rad);
* poa_p[] = incident beam, incident sky diffuse, incident ground diffuse, diffuse isotropic, diffuse circumsolar, horizon brightening (W/m2);
* irrad parameters: ghi, dni, dhi
*/
@test
def CalcTestRadMode0_lib_irradproc_NightCase():
    var fixture = NightCaseIrradProc()
    fixture.SetUp()
    var sun_p: DynamicVector[Float64] = DynamicVector[Float64](10, 0.0)
    var sunup: Int = 0  # false
    var angle_p: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var poa_p: DynamicVector[Float64] = DynamicVector[Float64](6, 0.0)
    var rad_p: DynamicVector[Float64] = DynamicVector[Float64]([1, 1, 1])
    fixture.irr_hourly_night.set_beam_diffuse(rad_p[1], rad_p[2])
    fixture.irr_15m_night.set_beam_diffuse(rad_p[1], rad_p[2])
    /* Hourly during the night */
    fixture.irr_hourly_night.calc()
    fixture.irr_hourly_night.get_sun(&sun_p[0], &sun_p[1], &sun_p[2], &sun_p[3], &sun_p[4], &sun_p[5], &sunup, &sun_p[7], &sun_p[8], &sun_p[9])
    fixture.irr_hourly_night.get_angles(&angle_p[0], &angle_p[1], &angle_p[2], &angle_p[3], &angle_p[4])
    fixture.irr_hourly_night.get_poa(&poa_p[0], &poa_p[1], &poa_p[2], &poa_p[3], &poa_p[4], &poa_p[5])
    fixture.irr_hourly_night.get_irrad(&rad_p[0], &rad_p[1], &rad_p[2])
    sun_p[6] = Float64(sunup)
    var sun_solution: DynamicVector[Float64] = DynamicVector[Float64]([15.406943, 125.967030, -35.967029, 20.872514, 5.636927, 19.584888, 0, 0.968315, 0.887054, 0])
    for i in range(10):
        expect(sun_p[i] == sun_solution[i], 0.0001)
    var angle_solution: DynamicVector[Float64] = DynamicVector[Float64]([0, 0, 0, 0, 0])
    for i in range(5):
        expect(angle_p[i] == angle_solution[i], 0.0001)
    var poa_solution: DynamicVector[Float64] = DynamicVector[Float64]([0, 0, 0, 0, 0, 0])
    for i in range(6):
        expect(poa_p[i] == poa_solution[i], 0.0001)
    var rad_solution: DynamicVector[Float64] = DynamicVector[Float64]([0, 0, 0])
    for i in range(3):
        expect(rad_p[i] == rad_solution[i], 0.0001)
    /* 15m during the night */
    fixture.irr_15m_night.calc()
    fixture.irr_15m_night.get_sun(&sun_p[0], &sun_p[1], &sun_p[2], &sun_p[3], &sun_p[4], &sun_p[5], &sunup, &sun_p[7], &sun_p[8], &sun_p[9])
    fixture.irr_15m_night.get_angles(&angle_p[0], &angle_p[1], &angle_p[2], &angle_p[3], &angle_p[4])
    fixture.irr_15m_night.get_poa(&poa_p[0], &poa_p[1], &poa_p[2], &poa_p[3], &poa_p[4], &poa_p[5])
    fixture.irr_15m_night.get_irrad(&rad_p[0], &rad_p[1], &rad_p[2])
    sun_p[6] = Float64(sunup)
    sun_solution = DynamicVector[Float64]([11.153456, 126.698858, -36.698858, 20.874383, 5.636927, 19.584888, 0, 0.968315, 0.637066, 0])
    for i in range(10):
        expect(sun_p[i] == sun_solution[i], 0.0001)
    angle_solution = DynamicVector[Float64]([0, 0, 0, 0, 0])
    for i in range(5):
        expect(angle_p[i] == angle_solution[i], 0.0001)
    poa_solution = DynamicVector[Float64]([0, 0, 0, 0, 0, 0])
    for i in range(6):
        expect(poa_p[i] == poa_solution[i], 0.0001)
    rad_solution = DynamicVector[Float64]([0, 0, 0])
    for i in range(3):
        expect(rad_p[i] == rad_solution[i], 0.0001)

@test
def CalcTestRadMode0_lib_irradproc_SunriseCase():
    var fixture = SunriseCaseIrradProc()
    fixture.SetUp()
    var sun_p: DynamicVector[Float64] = DynamicVector[Float64](10, 0.0)
    var sunup: Int = 1  # true
    var angle_p: DynamicVector[Float64] = DynamicVector[Float64](5, 0.0)
    var poa_p: DynamicVector[Float64] = DynamicVector[Float64](6, 0.0)
    var rad_p: DynamicVector[Float64] = DynamicVector[Float64]([1, 1, 1])
    fixture.irr_hourly_sunrise.set_beam_diffuse(rad_p[1], rad_p[2])
    fixture.irr_15m_sunrise.set_beam_diffuse(rad_p[1], rad_p[2])
    /* hourly during sunrise */
    fixture.irr_hourly_sunrise.calc()
    fixture.irr