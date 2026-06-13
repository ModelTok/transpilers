from map import map
from gtest import Test, EXPECT_TRUE, EXPECT_FALSE, EXPECT_DOUBLE_EQ, EXPECT_ENUM_EQ, EXPECT_NEAR, ASSERT_THROW, compare_err_stream, delimited_string
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.ElectricPowerServiceManager import ElectricPowerServiceManager
from EnergyPlus.PVWatts import PVWatts
from EnergyPlus.WeatherManager import Weather

def test_PVWattsGenerator_Constructor():
    using PVWatts
    var pvw = PVWattsGenerator(*state, "PVArray", 4000.0, ModuleType.STANDARD, ArrayType.FIXED_ROOF_MOUNTED)
    EXPECT_DOUBLE_EQ(4000.0, pvw.getDCSystemCapacity())
    EXPECT_ENUM_EQ(ModuleType.STANDARD, pvw.getModuleType())
    EXPECT_ENUM_EQ(ArrayType.FIXED_ROOF_MOUNTED, pvw.getArrayType())
    EXPECT_DOUBLE_EQ(0.14, pvw.getSystemLosses())
    EXPECT_ENUM_EQ(GeometryType.TILT_AZIMUTH, pvw.getGeometryType())
    EXPECT_DOUBLE_EQ(20.0, pvw.getTilt())
    EXPECT_DOUBLE_EQ(180.0, pvw.getAzimuth())
    EXPECT_DOUBLE_EQ(0.4, pvw.getGroundCoverageRatio())
    ASSERT_THROW(PVWattsGenerator pvw2(
                     *state, "", -1000.0, ModuleType.PREMIUM, ArrayType.FIXED_OPEN_RACK, 1.1, GeometryType.TILT_AZIMUTH, 91.0, 360.0, 0, -0.1),
                 RuntimeError)
    var error_string: String = delimited_string({"   ** Severe  ** PVWatts: name cannot be blank.",
                                                       "   ** Severe  ** PVWatts: DC system capacity must be greater than zero.",
                                                       "   ** Severe  ** PVWatts: Invalid system loss value 1.10",
                                                       "   ** Severe  ** PVWatts: Invalid tilt: 91.00",
                                                       "   ** Severe  ** PVWatts: Invalid azimuth: 360.00",
                                                       "   ** Severe  ** PVWatts: Invalid ground coverage ratio: -0.10",
                                                       "   **  Fatal  ** Errors found in getting PVWatts input",
                                                       "   ...Summary of Errors that led to program termination:",
                                                       "   ..... Reference severe error count=6",
                                                       "   ..... Last severe error=PVWatts: Invalid ground coverage ratio: -0.10"})
    EXPECT_TRUE(compare_err_stream(error_string, true))

def test_PVWattsGenerator_GetInputs():
    using PVWatts
    var idfTxt: String = delimited_string({"Generator:PVWatts,",
                                                 "PVWattsArray1,",
                                                 "5,",
                                                 "4000,",
                                                 "Premium,",
                                                 "OneAxis,",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ";",
                                                 "Generator:PVWatts,",
                                                 "PVWattsArray2,",
                                                 "5,",
                                                 "4000,",
                                                 "Premium,",
                                                 "OneAxis,",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ";",
                                                 "Generator:PVWatts,",
                                                 "PVWattsArray3,",
                                                 "5,",
                                                 "4000,",
                                                 "Premium,",
                                                 "OneAxis,",
                                                 ",",
                                                 ",",
                                                 "21,",
                                                 "175,",
                                                 ",",
                                                 "0.5;",
                                                 "Output:Variable,*,Generator Produced DC Electricity Rate,timestep;"})
    process_idf(idfTxt)
    EXPECT_FALSE(has_err_output())
    var pvw1 = PVWattsGenerator.createFromIdfObj(*state, 1)
    EXPECT_ENUM_EQ(pvw1.getModuleType(), ModuleType.PREMIUM)
    EXPECT_ENUM_EQ(pvw1.getArrayType(), ArrayType.ONE_AXIS)
    EXPECT_DOUBLE_EQ(0.4, pvw1.getGroundCoverageRatio())
    var pvw2 = PVWattsGenerator.createFromIdfObj(*state, 2)
    EXPECT_DOUBLE_EQ(0.4, pvw2.getGroundCoverageRatio())
    var pvw3 = PVWattsGenerator.createFromIdfObj(*state, 3)
    EXPECT_DOUBLE_EQ(175.0, pvw3.getAzimuth())
    EXPECT_DOUBLE_EQ(21.0, pvw3.getTilt())
    EXPECT_DOUBLE_EQ(0.5, pvw3.getGroundCoverageRatio())

def test_PVWattsGenerator_GetInputsFailure():
    using PVWatts
    var idfTxt: String = delimited_string({"Generator:PVWatts,",
                                                 "PVWattsArray1,",
                                                 "5,",
                                                 "4000,",
                                                 "Primo,",          // misspelled
                                                 "FixedRoofMount,", // misspelled
                                                 ",",
                                                 "asdf,",
                                                 ",",
                                                 ";",
                                                 "Output:Variable,*,Generator Produced DC Electricity Rate,timestep;"})
    EXPECT_FALSE(process_idf(idfTxt, false))
    ASSERT_THROW(PVWattsGenerator.createFromIdfObj(*state, 1), RuntimeError)
    var error_string: String = delimited_string(
        {"   ** Severe  ** <root>[Generator:PVWatts][PVWattsArray1][array_geometry_type] - \"asdf\" - Failed to match against any enum values.",
         "   ** Severe  ** <root>[Generator:PVWatts][PVWattsArray1][array_type] - \"FixedRoofMount\" - Failed to match against any enum values.",
         "   ** Severe  ** <root>[Generator:PVWatts][PVWattsArray1][module_type] - \"Primo\" - Failed to match against any enum values.",
         "   ** Severe  ** PVWatts: Invalid Module Type: PRIMO",
         "   ** Severe  ** PVWatts: Invalid Array Type: FIXEDROOFMOUNT",
         "   ** Severe  ** PVWatts: Invalid Geometry Type: ASDF",
         "   **  Fatal  ** Errors found in getting PVWatts input",
         "   ...Summary of Errors that led to program termination:",
         "   ..... Reference severe error count=6",
         "   ..... Last severe error=PVWatts: Invalid Geometry Type: ASDF"})
    EXPECT_TRUE(compare_err_stream(error_string, true))

def test_PVWattsGenerator_Calc():
    using PVWatts
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.TimeStepZone = 1.0
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.BeginTimeStepFlag = true
    state.dataGlobal.MinutesInTimeStep = 60
    state.dataGlobal.TimeStepsInHour = 1
    Weather.AllocateWeatherData(*state) // gets us the albedo array initialized
    state.dataEnvrn.Year = 1986
    state.dataEnvrn.Month = 6
    state.dataEnvrn.DayOfMonth = 15
    state.dataGlobal.HourOfDay = 8 // 8th hour of day, 7-8am
    state.dataWeather.WeatherFileLatitude = 33.45
    state.dataWeather.WeatherFileLongitude = -111.98
    state.dataWeather.WeatherFileTimeZone = -7
    state.dataEnvrn.BeamSolarRad = 728
    state.dataEnvrn.DifSolarRad = 70
    state.dataEnvrn.WindSpeed = 3.1
    state.dataEnvrn.OutDryBulbTemp = 31.7
    var pvwa = PVWattsGenerator(*state, "PVWattsArrayA", 4000.0, ModuleType.STANDARD, ArrayType.FIXED_ROOF_MOUNTED)
    pvwa.setCellTemperature(30.345)
    pvwa.setPlaneOfArrayIrradiance(92.257)
    pvwa.calc(*state)
    var generatorPower: Float64
    var generatorEnergy: Float64
    var thermalPower: Float64
    var thermalEnergy: Float64
    pvwa.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 884.137, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)
    var pvwb = PVWattsGenerator(*state, "PVWattsArrayB", 3000.0, ModuleType.PREMIUM, ArrayType.ONE_AXIS, 0.16, GeometryType.TILT_AZIMUTH, 25.0, 100.)
    pvwb.setCellTemperature(38.620)
    pvwb.setPlaneOfArrayIrradiance(478.641)
    pvwb.calc(*state)
    pvwb.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 1609.812, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)
    var pvwc = PVWattsGenerator(
        *state, "PVWattsArrayC", 1000.0, ModuleType.THIN_FILM, ArrayType.FIXED_OPEN_RACK, 0.1, GeometryType.TILT_AZIMUTH, 30.0, 140.)
    pvwc.setCellTemperature(33.764)
    pvwc.setPlaneOfArrayIrradiance(255.213)
    pvwc.calc(*state)
    pvwc.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 433.109, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)
    var pvwd = PVWattsGenerator(
        *state, "PVWattsArrayD", 5500.0, ModuleType.STANDARD, ArrayType.ONE_AXIS_BACKTRACKING, 0.05, GeometryType.TILT_AZIMUTH, 34.0, 180.)
    pvwd.setCellTemperature(29.205)
    pvwd.setPlaneOfArrayIrradiance(36.799)
    pvwd.calc(*state)
    pvwd.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 2524.947, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)
    var pvwe = PVWattsGenerator(*state, "PVWattsArrayE", 3800.0, ModuleType.PREMIUM, ArrayType.TWO_AXIS, 0.08, GeometryType.TILT_AZIMUTH, 34.0, 180.)
    pvwe.setCellTemperature(42.229)
    pvwe.setPlaneOfArrayIrradiance(647.867)
    pvwe.calc(*state)
    pvwe.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 2759.937, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)

def test_PVWattsInverter_Constructor():
    var idfTxt: String = delimited_string({"ElectricLoadCenter:Distribution,",
                                                 "ELC1,",
                                                 "GeneratorList1,",
                                                 "Baseload,",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 "DirectCurrentWithInverter,",
                                                 "Inverter1;",
                                                 "ElectricLoadCenter:Inverter:PVWatts,",
                                                 "Inverter1,",
                                                 "1.10,",
                                                 "0.96;",
                                                 "ElectricLoadCenter:Generators,",
                                                 "GeneratorList1,",
                                                 "PVWattsArray1,",
                                                 "Generator:PVWatts,",
                                                 "1500,",
                                                 ",",
                                                 ",",
                                                 "PVWattsArray2,",
                                                 "Generator:PVWatts,",
                                                 "2500,",
                                                 ",",
                                                 ";",
                                                 "Generator:PVWatts,",
                                                 "PVWattsArray1,",
                                                 "5,",
                                                 "1500,",
                                                 "Standard,",
                                                 "OneAxis,",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ";",
                                                 "Generator:PVWatts,",
                                                 "PVWattsArray2,",
                                                 "5,",
                                                 "2500,",
                                                 "Standard,",
                                                 "OneAxis,",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ",",
                                                 ";"})
    ASSERT_TRUE(process_idf(idfTxt))
    state.init_state(*state)
    var eplc = ElectPowerLoadCenter(*state, 1)
    ASSERT_TRUE(eplc.inverterPresent)
    EXPECT_DOUBLE_EQ(eplc.inverterObj.pvWattsDCCapacity(), 4000.0)
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    eplc.inverterObj.simulate(*state, 884.018)
    EXPECT_NEAR(eplc.inverterObj.aCPowerOut(), 842.527, 0.001)

def test_PVWatts_SSC_NaNFailure():
    var idfTxt: String = delimited_string({
        "Shading:Site:Detailed,",
        "  FlatSurfaceShadetoEast,  !- Name",
        "  ,                        !- Transmittance Schedule Name",
        "  4,                       !- Number of Vertices",
        "  0.0,25.0,12.0,  !- X,Y,Z ==> Vertex 1 {m}",
        "  0.0,20.00,12.0,  !- X,Y,Z ==> Vertex 2 {m}",
        "  5.0,20.00,12.0,  !- X,Y,Z ==> Vertex 3 {m}",
        "  5.0,25.0,12.0;  !- X,Y,Z ==> Vertex 4 {m}",
        "Generator:PVWatts,",
        "  PVWatts3,                !- Name",
        "  5,                       !- PVWatts Version",
        "  3000,                    !- DC System Capacity {W}",
        "  Premium,                 !- Module Type",
        "  FixedOpenRack,           !- Array Type",
        "  0.14,                    !- System Losses",
        "  Surface,                 !- Array Geometry Type",
        "  ,                        !- Tilt Angle {deg}",
        "  ,                        !- Azimuth Angle {deg}",
        "  FlatSurfaceShadetoEast;  !- Surface Name",
    })
    var name: String = "PVArray"
    var dcSystemCapacity: Float64 = 4000.0
    var moduleType = PVWatts.ModuleType.STANDARD
    var arrayType = PVWatts.ArrayType.FIXED_ROOF_MOUNTED
    var systemLosses: Float64 = 0.14
    var geometryType = PVWatts.GeometryType.TILT_AZIMUTH
    var tilt: Float64 = 0.0
    var azimuth: Float64 = 180.0
    var surfaceNum: Int = 0
    var groundCoverageRatio: Float64 = 0.4
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.TimeStepZone = 1.0
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataGlobal.BeginTimeStepFlag = true
    state.dataGlobal.MinutesInTimeStep = 60
    state.dataGlobal.TimeStepsInHour = 1
    Weather.AllocateWeatherData(*state) // gets us the albedo array initialized
    state.dataEnvrn.Year = 1986
    state.dataEnvrn.Month = 6
    state.dataEnvrn.DayOfMonth = 15
    state.dataGlobal.HourOfDay = 8 // 8th hour of day, 7-8am
    state.dataWeather.WeatherFileLatitude = 33.45
    state.dataWeather.WeatherFileLongitude = -111.98
    state.dataWeather.WeatherFileTimeZone = -7
    state.dataEnvrn.BeamSolarRad = 728
    state.dataEnvrn.DifSolarRad = 70
    state.dataEnvrn.WindSpeed = 3.1
    state.dataEnvrn.OutDryBulbTemp = 31.7
    var pvw = PVWatts.PVWattsGenerator(
        *state, name, dcSystemCapacity, moduleType, arrayType, systemLosses, geometryType, tilt, azimuth, surfaceNum, groundCoverageRatio)
    EXPECT_DOUBLE_EQ(dcSystemCapacity, pvw.getDCSystemCapacity())
    EXPECT_ENUM_EQ(moduleType, pvw.getModuleType())
    EXPECT_ENUM_EQ(arrayType, pvw.getArrayType())
    EXPECT_DOUBLE_EQ(systemLosses, pvw.getSystemLosses())
    EXPECT_ENUM_EQ(geometryType, pvw.getGeometryType())
    EXPECT_DOUBLE_EQ(tilt, pvw.getTilt())
    EXPECT_DOUBLE_EQ(azimuth, pvw.getAzimuth())
    EXPECT_DOUBLE_EQ(groundCoverageRatio, pvw.getGroundCoverageRatio())
    pvw.setCellTemperature(30.345)
    pvw.setPlaneOfArrayIrradiance(92.257)
    pvw.calc(*state)
    var generatorPower: Float64
    var generatorEnergy: Float64
    var thermalPower: Float64
    var thermalEnergy: Float64
    pvw.getResults(generatorPower, generatorEnergy, thermalPower, thermalEnergy)
    EXPECT_FALSE(isnan(generatorPower))
    EXPECT_FALSE(isnan(generatorEnergy))
    EXPECT_FALSE(isnan(thermalPower))
    EXPECT_FALSE(isnan(thermalEnergy))
    EXPECT_DOUBLE_EQ(thermalPower, 0.0)
    EXPECT_DOUBLE_EQ(thermalEnergy, 0.0)
    EXPECT_NEAR(generatorPower, 1117.75, 0.5)
    EXPECT_NEAR(generatorEnergy, generatorPower * 60 * 60, 1)
def main():
    test_PVWattsGenerator_Constructor()
    test_PVWattsGenerator_GetInputs()
    test_PVWattsGenerator_GetInputsFailure()
    test_PVWattsGenerator_Calc()
    test_PVWattsInverter_Constructor()
    test_PVWatts_SSC_NaNFailure()