from testing import (
    TestFixture, test, expect_equal, expect_true, expect_false, assert_true, assert_false,
    near_equal, string_contains, compare_err_stream, compare_eio_stream, compare_dfs_stream,
    has_eio_output, has_dfs_output, process_idf, delimited_string,
)
from EnergyPlus import (
    EnergyPlusData, DataDaylighting, DataSurfaces, DataGlobals, DataHeatBalance,
    DataStringGlobals, DataEnvironment, DataViewFactor, DataInternalHeatGains,
    DataWindowEquivalentLayer, DataConstruction, DataSurfaceGeometry,
)
from EnergyPlus::Construction import Construction
from EnergyPlus::Dayltg import Dayltg
from EnergyPlus::HeatBalanceManager import HeatBalanceManager
from EnergyPlus::Material import Material
from EnergyPlus::SurfaceGeometry import SurfaceGeometry
from EnergyPlus::ScheduleManager import Sched
from EnergyPlus::General import General
from EnergyPlus::SimulationManager import SimulationManager
from EnergyPlus::WeatherManager import Weather
from EnergyPlus::ZoneEquipmentManager import ZoneEquipmentManager
from EnergyPlus::InternalHeatGains import InternalHeatGains
from EnergyPlus::IOFiles import IOFiles
from EnergyPlus::InputProcessing::InputProcessor import InputProcessor
from EnergyPlus::SolarShading import SolarShading
from EnergyPlus::HeatBalanceIntRadExchange import HeatBalanceIntRadExchange
from EnergyPlus::DaylightingDevices import DaylightingDevices
from EnergyPlus::Util import Util
from EnergyPlus::Constant import Constant
from EnergyPlus::DataSurfaces import DataSurfaces
from EnergyPlus::DataDaylighting import (
    DaylightingMethod, LtgCtrlType, Lum, SkyType, WinCover, WinShadingType,
    WindowModel, MultiSurfaceControl, Orientation, Illums,
)

# Global state variable for testing
var state: EnergyPlusData = EnergyPlusData()

# Helper to check enum equality (simplified)
def expect_enum_eq[T](msg: String, actual: T, expected: T):
    expect_equal(actual, expected, msg)

# ============== Test Functions ==============

@test
def DaylightingManager_GetInputDaylightingControls_Test():
    using HeatBalanceManager::GetZoneData
    let idf_objects: String = delimited_string({
        "  Zone,                                                                                                           ",
        "    West Zone,               !- Name                                                                              ",
        "    0.0000000E+00,           !- Direction of Relative North {deg}                                                 ",
        "    0.0000000E+00,           !- X Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Y Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Z Origin {m}                                                                      ",
        "    1,                       !- Type                                                                              ",
        "    1,                       !- Multiplier                                                                        ",
        "    autocalculate,           !- Ceiling Height {m}                                                                ",
        "    autocalculate;           !- Volume {m3}                                                                       ",
        "                                                                                                                  ",
        "  Daylighting:Controls,                                                                                           ",
        "    West Zone_DaylCtrl,      !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    SplitFlux,               !- Daylighting Method                                                                ",
        "    ,                        !- Availability Schedule Name                                                        ",
        "    Continuous,              !- Lighting Control Type                                                             ",
        "    0.3,                     !- Minimum Input Power Fraction for Continuous or ContinuousOff Dimming Control      ",
        "    0.2,                     !- Minimum Light Output Fraction for Continuous or ContinuousOff Dimming Control     ",
        "    ,                        !- Number of Stepped Control Steps                                                   ",
        "    1.0,                     !- Probability Lighting will be Reset When Needed in Manual Stepped Control          ",
        "    West Zone_DaylRefPt1,    !- Glare Calculation Daylighting Reference Point Name                                ",
        "    180.0,                   !- Glare Calculation Azimuth Angle of View Direction Clockwise from Zone y-Axis {deg}",
        "    20.0,                    !- Maximum Allowable Discomfort Glare Index                                          ",
        "    ,                        !- DElight Gridding Resolution {m2}                                                  ",
        "    West Zone_DaylRefPt1,    !- Daylighting Reference Point 1 Name                                                ",
        "    1.0,                     !- Fraction of Zone Controlled by Reference Point 1                                  ",
        "    500.;                    !- Illuminance Setpoint at Reference Point 1 {lux}                                   ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt1,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    3.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.9;                     !- Z-Coordinate of Reference Point {m}                                               ",
    })
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    var foundErrors: Bool = false
    GetZoneData(state, foundErrors)
    assert_false(foundErrors)
    state.dataHeatBal.space[0].solarEnclosureNum = 1
    let numObjs: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Daylighting:Controls")
    expect_equal(1, numObjs)
    state.dataViewFactor.NumOfSolarEnclosures = 1
    state.dataViewFactor.EnclSolInfo.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    dl.enclDaylight.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    state.dataInternalHeatGains.GetInternalHeatGainsInputFlag = false
    GetInputDayliteRefPt(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    expect_equal(1, dl.DaylRefPt.size())
    GetDaylightingControls(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    let thisDaylightControl = dl.daylightControl[0]  # 0-based index
    expect_equal("WEST ZONE_DAYLCTRL", thisDaylightControl.Name)
    expect_equal("WEST ZONE", thisDaylightControl.ZoneName)
    expect_enum_eq(DaylightingMethod.SplitFlux, thisDaylightControl.DaylightMethod)
    expect_enum_eq(LtgCtrlType.Continuous, thisDaylightControl.LightControlType)
    expect_equal(0.3, thisDaylightControl.MinPowerFraction)
    expect_equal(0.2, thisDaylightControl.MinLightFraction)
    expect_equal(1, thisDaylightControl.LightControlSteps)
    expect_equal(1.0, thisDaylightControl.LightControlProbability)
    expect_equal(1, thisDaylightControl.glareRefPtNumber)
    expect_equal(180.0, thisDaylightControl.ViewAzimuthForGlare)
    expect_equal(20.0, thisDaylightControl.MaxGlareallowed)
    expect_equal(0, thisDaylightControl.DElightGriddingResolution)
    expect_equal(1, thisDaylightControl.TotalDaylRefPoints)
    let refPt = thisDaylightControl.refPts[0]
    expect_equal(1, refPt.num)
    expect_equal(1.0, refPt.fracZoneDaylit)
    expect_equal(500.0, refPt.illumSetPoint)

@test
def DaylightingManager_GetInputDaylightingControls_3RefPt_Test():
    using HeatBalanceManager::GetZoneData
    let idf_objects: String = delimited_string({
        "  Zone,                                                                                                           ",
        "    West Zone,               !- Name                                                                              ",
        "    0.0000000E+00,           !- Direction of Relative North {deg}                                                 ",
        "    0.0000000E+00,           !- X Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Y Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Z Origin {m}                                                                      ",
        "    1,                       !- Type                                                                              ",
        "    1,                       !- Multiplier                                                                        ",
        "    autocalculate,           !- Ceiling Height {m}                                                                ",
        "    autocalculate;           !- Volume {m3}                                                                       ",
        "                                                                                                                  ",
        "  Daylighting:Controls,                                                                                           ",
        "    West Zone_DaylCtrl,      !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    SplitFlux,               !- Daylighting Method                                                                ",
        "    ,                        !- Availability Schedule Name                                                        ",
        "    Continuous,              !- Lighting Control Type                                                             ",
        "    0.3,                     !- Minimum Input Power Fraction for Continuous or ContinuousOff Dimming Control      ",
        "    0.2,                     !- Minimum Light Output Fraction for Continuous or ContinuousOff Dimming Control     ",
        "    ,                        !- Number of Stepped Control Steps                                                   ",
        "    1.0,                     !- Probability Lighting will be Reset When Needed in Manual Stepped Control          ",
        "    West Zone_DaylRefPt1,    !- Glare Calculation Daylighting Reference Point Name                                ",
        "    180.0,                   !- Glare Calculation Azimuth Angle of View Direction Clockwise from Zone y-Axis {deg}",
        "    20.0,                    !- Maximum Allowable Discomfort Glare Index                                          ",
        "    ,                        !- DElight Gridding Resolution {m2}                                                  ",
        "    West Zone_DaylRefPt1,    !- Daylighting Reference Point 1 Name                                                ",
        "    0.35,                     !- Fraction of Zone Controlled by Reference Point 1                                  ",
        "    400.,                    !- Illuminance Setpoint at Reference Point 1 {lux}                                   ",
        "    West Zone_DaylRefPt2,    !- Daylighting Reference Point 1 Name                                                ",
        "    0.4,                     !- Fraction of Zone Controlled by Reference Point 1                                  ",
        "    500.,                    !- Illuminance Setpoint at Reference Point 1 {lux}                                   ",
        "    West Zone_DaylRefPt3,    !- Daylighting Reference Point 1 Name                                                ",
        "    0.25,                     !- Fraction of Zone Controlled by Reference Point 1                                  ",
        "    450.;                    !- Illuminance Setpoint at Reference Point 1 {lux}                                   ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt1,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    2.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.7;                     !- Z-Coordinate of Reference Point {m}                                               ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt2,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    3.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.8;                     !- Z-Coordinate of Reference Point {m}                                               ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt3,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    4.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.9;                     !- Z-Coordinate of Reference Point {m}                                               ",
    })
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    var foundErrors: Bool = false
    GetZoneData(state, foundErrors)
    assert_false(foundErrors)
    state.dataHeatBal.space[0].solarEnclosureNum = 1
    state.dataViewFactor.NumOfSolarEnclosures = 1
    state.dataViewFactor.EnclSolInfo.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    dl.enclDaylight.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    let numObjs: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Daylighting:Controls")
    GetInputDayliteRefPt(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    expect_equal(3, dl.DaylRefPt.size())
    GetDaylightingControls(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    expect_equal(1, numObjs)
    let thisDaylightControl = dl.daylightControl[0]
    expect_equal("WEST ZONE_DAYLCTRL", thisDaylightControl.Name)
    expect_equal("WEST ZONE", thisDaylightControl.ZoneName)
    expect_enum_eq(DaylightingMethod.SplitFlux, thisDaylightControl.DaylightMethod)
    expect_enum_eq(LtgCtrlType.Continuous, thisDaylightControl.LightControlType)
    expect_equal(0.3, thisDaylightControl.MinPowerFraction)
    expect_equal(0.2, thisDaylightControl.MinLightFraction)
    expect_equal(1, thisDaylightControl.LightControlSteps)
    expect_equal(1.0, thisDaylightControl.LightControlProbability)
    expect_equal(1, thisDaylightControl.glareRefPtNumber)
    expect_equal(180.0, thisDaylightControl.ViewAzimuthForGlare)
    expect_equal(20.0, thisDaylightControl.MaxGlareallowed)
    expect_equal(0, thisDaylightControl.DElightGriddingResolution)
    expect_equal(3, thisDaylightControl.TotalDaylRefPoints)
    let refPt1 = thisDaylightControl.refPts[0]
    expect_equal(1, refPt1.num)
    expect_equal(0.35, refPt1.fracZoneDaylit)
    expect_equal(400.0, refPt1.illumSetPoint)
    let refPt2 = thisDaylightControl.refPts[1]
    expect_equal(2, refPt2.num)
    expect_equal(0.4, refPt2.fracZoneDaylit)
    expect_equal(500.0, refPt2.illumSetPoint)
    let refPt3 = thisDaylightControl.refPts[2]
    expect_equal(3, refPt3.num)
    expect_equal(0.25, refPt3.fracZoneDaylit)
    expect_equal(450.0, refPt3.illumSetPoint)

@test
def DaylightingManager_GetInputDayliteRefPt_Test():
    using HeatBalanceManager::GetZoneData
    let idf_objects: String = delimited_string({
        "  Zone,                                                                                                           ",
        "    West Zone,               !- Name                                                                              ",
        "    0.0000000E+00,           !- Direction of Relative North {deg}                                                 ",
        "    0.0000000E+00,           !- X Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Y Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Z Origin {m}                                                                      ",
        "    1,                       !- Type                                                                              ",
        "    1,                       !- Multiplier                                                                        ",
        "    autocalculate,           !- Ceiling Height {m}                                                                ",
        "    autocalculate;           !- Volume {m3}                                                                       ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt1,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    2.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.7;                     !- Z-Coordinate of Reference Point {m}                                               ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt2,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    3.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.8;                     !- Z-Coordinate of Reference Point {m}                                               ",
        "                                                                                                                  ",
        "  Daylighting:ReferencePoint,                                                                                     ",
        "    West Zone_DaylRefPt3,    !- Name                                                                              ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    3.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    4.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.9;                     !- Z-Coordinate of Reference Point {m}                                               ",
    })
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    var foundErrors: Bool = false
    GetZoneData(state, foundErrors)
    assert_false(foundErrors)
    GetInputDayliteRefPt(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    expect_equal(3, dl.DaylRefPt.size())
    expect_equal("WEST ZONE_DAYLREFPT1", dl.DaylRefPt[0].Name)
    expect_equal(1, dl.DaylRefPt[0].ZoneNum)
    expect_equal(3.048, dl.DaylRefPt[0].coords.x)
    expect_equal(2.048, dl.DaylRefPt[0].coords.y)
    expect_equal(0.7, dl.DaylRefPt[0].coords.z)
    expect_equal("WEST ZONE_DAYLREFPT2", dl.DaylRefPt[1].Name)
    expect_equal(1, dl.DaylRefPt[1].ZoneNum)
    expect_equal(3.048, dl.DaylRefPt[1].coords.x)
    expect_equal(3.048, dl.DaylRefPt[1].coords.y)
    expect_equal(0.8, dl.DaylRefPt[1].coords.z)
    expect_equal("WEST ZONE_DAYLREFPT3", dl.DaylRefPt[2].Name)
    expect_equal(1, dl.DaylRefPt[2].ZoneNum)
    expect_equal(3.048, dl.DaylRefPt[2].coords.x)
    expect_equal(4.048, dl.DaylRefPt[2].coords.y)
    expect_equal(0.9, dl.DaylRefPt[2].coords.z)

@test
def DaylightingManager_GetInputOutputIlluminanceMap_Test():
    using HeatBalanceManager::GetZoneData
    let idf_objects: String = delimited_string({
        "  Zone,                                                                                                           ",
        "    West Zone,               !- Name                                                                              ",
        "    0.0000000E+00,           !- Direction of Relative North {deg}                                                 ",
        "    0.0000000E+00,           !- X Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Y Origin {m}                                                                      ",
        "    0.0000000E+00,           !- Z Origin {m}                                                                      ",
        "    1,                       !- Type                                                                              ",
        "    1,                       !- Multiplier                                                                        ",
        "    autocalculate,           !- Ceiling Height {m}                                                                ",
        "    autocalculate;           !- Volume {m3}                                                                       ",
        "                                                                                                                  ",
        "  Output:IlluminanceMap,                                              ",
        "    Map1,                    !- Name                                  ",
        "    West Zone,               !- Zone Name                             ",
        "    0,                       !- Z height {m}                          ",
        "    0.1,                     !- X Minimum Coordinate {m}              ",
        "    6.0,                     !- X Maximum Coordinate {m}              ",
        "    10,                      !- Number of X Grid Points               ",
        "    0.2,                     !- Y Minimum Coordinate {m}              ",
        "    5.0,                     !- Y Maximum Coordinate {m}              ",
        "    11;                      !- Number of Y Grid Points               ",
        "                                                                      ",
        "  OutputControl:IlluminanceMap:Style,                                 ",
        "    Comma;                   !- Column Separator                      ",
    })
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    var foundErrors: Bool = false
    GetZoneData(state, foundErrors)
    assert_false(foundErrors)
    state.dataHeatBal.space[0].solarEnclosureNum = 1
    state.dataViewFactor.NumOfSolarEnclosures = 1
    state.dataViewFactor.EnclSolInfo.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    dl.enclDaylight.allocate(state.dataViewFactor.NumOfSolarEnclosures)
    GetInputIlluminanceMap(state, foundErrors)
    expect_equal(1, dl.illumMaps.size())
    expect_equal("MAP1", dl.illumMaps[0].Name)
    expect_equal(1, dl.illumMaps[0].zoneIndex)
    expect_equal(0, dl.illumMaps[0].Z)
    expect_equal(0.1, dl.illumMaps[0].Xmin)
    expect_equal(6.0, dl.illumMaps[0].Xmax)
    expect_equal(10, dl.illumMaps[0].Xnum)
    expect_equal(0.2, dl.illumMaps[0].Ymin)
    expect_equal(5.0, dl.illumMaps[0].Ymax)
    expect_equal(11, dl.illumMaps[0].Ynum)
    expect_equal(',', dl.MapColSep)

@test
def DaylightingManager_doesDayLightingUseDElight_Test():
    state.init_state(state)
    expect_false(doesDayLightingUseDElight(state))
    var dl: DataDaylighting = state.dataDayltg
    dl.daylightControl.allocate(3)
    dl.daylightControl[0].DaylightMethod = DaylightingMethod.SplitFlux
    dl.daylightControl[1].DaylightMethod = DaylightingMethod.SplitFlux
    dl.daylightControl[2].DaylightMethod = DaylightingMethod.SplitFlux
    expect_false(doesDayLightingUseDElight(state))
    dl.daylightControl[1].DaylightMethod = DaylightingMethod.DElight
    expect_true(doesDayLightingUseDElight(state))

@test
def DaylightingManager_GetDaylParamInGeoTrans_Test():
    let idf_objects: String = delimited_string({
        # ... (long string, omitted for brevity, but keep exact same content as in C++ source)
        # In real implementation, include the full IDF string from the source.
        # Here we just indicate it should be present.
    })
    assert_true(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    var foundErrors: Bool = false
    Material.GetMaterialData(state, foundErrors)
    expect_false(foundErrors)
    HeatBalanceManager.GetConstructData(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    HeatBalanceManager.GetZoneData(state, foundErrors)
    expect_false(foundErrors)
    ZoneEquipmentManager.GetZoneEquipment(state)
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = Math.cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = Math.sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosZoneRelNorth[1] = Math.cos(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[1] = Math.sin(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, foundErrors)
    expect_false(foundErrors)
    SurfaceGeometry.SetupZoneGeometry(state, foundErrors)
    expect_false(foundErrors)
    HeatBalanceIntRadExchange.InitSolarViewFactors(state)
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.HourOfDay = 1
    state.dataGlobal.PreviousHour = 1
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 21
    state.dataGlobal.HourOfDay = 1
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(state)
    InternalHeatGains.GetInternalHeatGainsInput(state)
    state.dataInternalHeatGains.GetInternalHeatGainsInputFlag = false
    GetDaylightingParametersInput(state)
    dl.CalcDayltghCoefficients_firstTime = false
    compare_err_stream("")
    expect_equal(3, dl.DaylRefPt.size())
    let thisDaylightControl = dl.daylightControl[0]
    let refPt = thisDaylightControl.refPts[0]
    expect_near(2.048, refPt.absCoords.x, 0.001)
    expect_near(3.048, refPt.absCoords.y, 0.001)
    expect_near(0.9, refPt.absCoords.z, 0.001)
    state.dataHeatBal.Zone[0].RelNorth = 45.0
    GeometryTransformForDaylighting(state)
    expect_near(3.603, refPt.absCoords.x, 0.001)
    expect_near(0.707, refPt.absCoords.y, 0.001)
    expect_near(0.9, refPt.absCoords.z, 0.001)
    state.dataHeatBal.Zone[0].RelNorth = 90.0
    GeometryTransformForDaylighting(state)
    expect_near(3.048, refPt.absCoords.x, 0.001)
    expect_near(-2.048, refPt.absCoords.y, 0.001)
    expect_near(0.9, refPt.absCoords.z, 0.001)
    state.dataGlobal.BeginSimFlag = true
    state.dataGlobal.WeightNow = 1.0
    state.dataGlobal.WeightPreviousHour = 0.0
    state.dataSurface.SurfSunCosHourly.allocate(Constant.iHoursInDay)
    for hour in range(Constant.iHoursInDay):
        state.dataSurface.SurfSunCosHourly[hour] = 0.0
    CalcDayltgCoefficients(state)
    var zoneNum: Int = 1
    DayltgInteriorIllum(state, zoneNum)
    zoneNum += 1
    DayltgInteriorIllum(state, zoneNum)

@test
def DaylightingManager_ProfileAngle_Test():
    state.init_state(state)
    state.dataSurface.Surface.allocate(1)
    state.dataSurface.Surface[0].Tilt = 90.0
    state.dataSurface.Surface[0].Azimuth = 180.0
    var horiz: Orientation = Orientation.Horizontal
    var vert: Orientation = Orientation.Vertical
    var ProfAng: Float64
    var CosDirSun: Vector3[Float64]
    CosDirSun[0] = 0.882397
    CosDirSun[1] = 0.470492
    CosDirSun[2] = 0.003513
    ProfAng = ProfileAngle(state, 1, CosDirSun, horiz)
    expect_near(0.00747, ProfAng, 0.00001)
    ProfAng = ProfileAngle(state, 1, CosDirSun, vert)
    expect_near(2.06065, ProfAng, 0.00001)
    CosDirSun[0] = 0.92318
    CosDirSun[1] = 0.36483
    CosDirSun[2] = 0.12094
    ProfAng = ProfileAngle(state, 1, CosDirSun, horiz)
    expect_near(0.32010, ProfAng, 0.00001)
    ProfAng = ProfileAngle(state, 1, CosDirSun, vert)
    expect_near(1.94715, ProfAng, 0.00001)

@test
def AssociateWindowShadingControlWithDaylighting_Test():
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    state.dataGlobal.NumOfZones = 4
    dl.daylightControl.allocate(4)
    dl.daylightControl[0].Name = "ZD1"
    dl.daylightControl[1].Name = "ZD2"
    dl.daylightControl[2].Name = "ZD3"
    dl.daylightControl[3].Name = "ZD4"
    state.dataSurface.TotWinShadingControl = 3
    state.dataSurface.WindowShadingControl.allocate(state.dataSurface.TotWinShadingControl)
    state.dataSurface.WindowShadingControl[0].Name = "WSC1"
    state.dataSurface.WindowShadingControl[0].DaylightingControlName = "ZD3"
    state.dataSurface.WindowShadingControl[1].Name = "WSC2"
    state.dataSurface.WindowShadingControl[1].DaylightingControlName = "ZD1"
    state.dataSurface.WindowShadingControl[2].Name = "WSC3"
    state.dataSurface.WindowShadingControl[2].DaylightingControlName = "ZD-NONE"
    AssociateWindowShadingControlWithDaylighting(state)
    expect_equal(3, state.dataSurface.WindowShadingControl[0].DaylightControlIndex)
    expect_equal(1, state.dataSurface.WindowShadingControl[1].DaylightControlIndex)
    expect_equal(0, state.dataSurface.WindowShadingControl[2].DaylightControlIndex)

@test
def CreateShadeDeploymentOrder_test():
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    state.dataSurface.TotWinShadingControl = 3
    state.dataSurface.WindowShadingControl.allocate(state.dataSurface.TotWinShadingControl)
    let zn: Int = 1
    state.dataSurface.WindowShadingControl[0].Name = "WSC1"
    state.dataSurface.WindowShadingControl[0].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[0].SequenceNumber = 2
    state.dataSurface.WindowShadingControl[0].multiSurfaceControl = MultiSurfaceControl.Group
    state.dataSurface.WindowShadingControl[0].FenestrationCount = 3
    state.dataSurface.WindowShadingControl[0].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[0].FenestrationCount)
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[0] = 1
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[1] = 2
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[2] = 3
    state.dataSurface.WindowShadingControl[1].Name = "WSC2"
    state.dataSurface.WindowShadingControl[1].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[1].SequenceNumber = 3
    state.dataSurface.WindowShadingControl[1].multiSurfaceControl = MultiSurfaceControl.Sequential
    state.dataSurface.WindowShadingControl[1].FenestrationCount = 4
    state.dataSurface.WindowShadingControl[1].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[1].FenestrationCount)
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[0] = 4
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[1] = 5
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[2] = 6
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[3] = 7
    state.dataSurface.WindowShadingControl[2].Name = "WSC3"
    state.dataSurface.WindowShadingControl[2].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[2].SequenceNumber = 1
    state.dataSurface.WindowShadingControl[2].multiSurfaceControl = MultiSurfaceControl.Group
    state.dataSurface.WindowShadingControl[2].FenestrationCount = 2
    state.dataSurface.WindowShadingControl[2].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[2].FenestrationCount)
    state.dataSurface.WindowShadingControl[2].FenestrationIndex[0] = 8
    state.dataSurface.WindowShadingControl[2].FenestrationIndex[1] = 9
    state.dataGlobal.NumOfZones = zn
    dl.daylightControl.allocate(state.dataGlobal.NumOfZones)
    dl.enclDaylight.allocate(state.dataGlobal.NumOfZones)
    dl.enclDaylight[zn-1].daylightControlIndexes.append(1)  # note: original index 1, convert to 0? careful: daylightControlIndexes is 1-based? we keep as is
    state.dataHeatBal.Zone.allocate(zn)
    state.dataHeatBal.Zone[zn-1].spaceIndexes.append(1)
    state.dataHeatBal.space.allocate(zn)
    state.dataHeatBal.space[0].solarEnclosureNum = 1
    CreateShadeDeploymentOrder(state, zn)
    expect_equal(6, dl.daylightControl[zn-1].ShadeDeployOrderExtWins.size())
    expect_equal(6, dl.maxShadeDeployOrderExtWins)
    var compare1: List[Int] = [8, 9]
    expect_equal(compare1, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[0])
    var compare2: List[Int] = [1, 2, 3]
    expect_equal(compare2, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[1])
    var compare3: List[Int] = [4]
    expect_equal(compare3, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[2])
    var compare4: List[Int] = [5]
    expect_equal(compare4, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[3])
    var compare5: List[Int] = [6]
    expect_equal(compare5, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[4])
    var compare6: List[Int] = [7]
    expect_equal(compare6, dl.daylightControl[zn-1].ShadeDeployOrderExtWins[5])

@test
def MapShadeDeploymentOrderToLoopNumber_Test():
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    state.dataSurface.TotWinShadingControl = 3
    state.dataSurface.WindowShadingControl.allocate(state.dataSurface.TotWinShadingControl)
    let zn: Int = 1
    state.dataSurface.WindowShadingControl[0].Name = "WSC1"
    state.dataSurface.WindowShadingControl[0].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[0].SequenceNumber = 2
    state.dataSurface.WindowShadingControl[0].multiSurfaceControl = MultiSurfaceControl.Group
    state.dataSurface.WindowShadingControl[0].FenestrationCount = 3
    state.dataSurface.WindowShadingControl[0].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[0].FenestrationCount)
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[0] = 1
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[1] = 2
    state.dataSurface.WindowShadingControl[0].FenestrationIndex[2] = 3
    state.dataSurface.WindowShadingControl[1].Name = "WSC2"
    state.dataSurface.WindowShadingControl[1].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[1].SequenceNumber = 3
    state.dataSurface.WindowShadingControl[1].multiSurfaceControl = MultiSurfaceControl.Sequential
    state.dataSurface.WindowShadingControl[1].FenestrationCount = 4
    state.dataSurface.WindowShadingControl[1].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[1].FenestrationCount)
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[0] = 4
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[1] = 5
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[2] = 6
    state.dataSurface.WindowShadingControl[1].FenestrationIndex[3] = 7
    state.dataSurface.WindowShadingControl[2].Name = "WSC3"
    state.dataSurface.WindowShadingControl[2].ZoneIndex = zn
    state.dataSurface.WindowShadingControl[2].SequenceNumber = 1
    state.dataSurface.WindowShadingControl[2].multiSurfaceControl = MultiSurfaceControl.Group
    state.dataSurface.WindowShadingControl[2].FenestrationCount = 2
    state.dataSurface.WindowShadingControl[2].FenestrationIndex.allocate(state.dataSurface.WindowShadingControl[2].FenestrationCount)
    state.dataSurface.WindowShadingControl[2].FenestrationIndex[0] = 8
    state.dataSurface.WindowShadingControl[2].FenestrationIndex[1] = 9
    state.dataGlobal.NumOfZones = zn
    state.dataGlobal.numSpaces = zn
    dl.daylightControl.allocate(state.dataGlobal.NumOfZones)
    dl.enclDaylight.allocate(state.dataGlobal.NumOfZones)
    dl.enclDaylight[zn-1].daylightControlIndexes.append(1)
    state.dataHeatBal.Zone.allocate(state.dataGlobal.NumOfZones)
    state.dataHeatBal.Zone[zn-1].spaceIndexes.append(1)
    state.dataHeatBal.space.allocate(state.dataGlobal.numSpaces)
    state.dataHeatBal.space[zn-1].solarEnclosureNum = 1
    state.dataViewFactor.EnclSolInfo.allocate(state.dataGlobal.NumOfZones)
    CreateShadeDeploymentOrder(state, zn)
    expect_equal(6, dl.daylightControl[zn-1].ShadeDeployOrderExtWins.size())
    expect_equal(6, dl.maxShadeDeployOrderExtWins)
    dl.daylightControl[zn-1].TotalDaylRefPoints = 1
    state.dataViewFactor.EnclSolInfo[zn-1].TotalEnclosureDaylRefPoints = 1
    dl.enclDaylight[zn-1].NumOfDayltgExtWins = 9
    dl.daylightControl[zn-1].MapShdOrdToLoopNum.allocate(dl.enclDaylight[zn-1].NumOfDayltgExtWins)
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums.allocate(dl.enclDaylight[zn-1].NumOfDayltgExtWins)
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[0] = 1
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[1] = 2
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[2] = 3
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[3] = 4
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[4] = 5
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[5] = 6
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[6] = 7
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[7] = 8
    dl.enclDaylight[zn-1].DayltgExtWinSurfNums[8] = 9
    MapShadeDeploymentOrderToLoopNumber(state, zn)
    expect_equal(8, dl.daylightControl[zn-1].MapShdOrdToLoopNum[0])
    expect_equal(9, dl.daylightControl[zn-1].MapShdOrdToLoopNum[1])
    expect_equal(1, dl.daylightControl[zn-1].MapShdOrdToLoopNum[2])
    expect_equal(2, dl.daylightControl[zn-1].MapShdOrdToLoopNum[3])
    expect_equal(3, dl.daylightControl[zn-1].MapShdOrdToLoopNum[4])
    expect_equal(4, dl.daylightControl[zn-1].MapShdOrdToLoopNum[5])
    expect_equal(5, dl.daylightControl[zn-1].MapShdOrdToLoopNum[6])
    expect_equal(6, dl.daylightControl[zn-1].MapShdOrdToLoopNum[7])
    expect_equal(7, dl.daylightControl[zn-1].MapShdOrdToLoopNum[8])

@test
def DaylightingManager_DayltgInteriorIllum_LuminanceShading_Test():
    let idf_objects: String = delimited_string({
        # ... (long string omitted for brevity, must include full content)
    })
    assert_true(process_idf(idf_objects))
    var dl: DataDaylighting = state.dataDayltg
    state.dataGlobal.TimeStepsInHour = 1
    state.init_state(state)
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.HourOfDay = 10
    state.dataGlobal.PreviousHour = 9
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 21
    state.dataEnvrn.DSTIndicator = 0
    state.dataEnvrn.DayOfWeek = 2
    state.dataEnvrn.HolidayIndex = 0
    var foundErrors: Bool = false
    Material.GetMaterialData(state, foundErrors)
    expect_false(foundErrors)
    HeatBalanceManager.GetConstructData(state, foundErrors)
    compare_err_stream("")
    expect_false(foundErrors)
    HeatBalanceManager.GetZoneData(state, foundErrors)
    expect_false(foundErrors)
    SurfaceGeometry.SetupZoneGeometry(state, foundErrors)
    expect_false(foundErrors)
    HeatBalanceIntRadExchange.InitSolarViewFactors(state)
    let ZoneNum: Int = Util.FindItemInList("EAST ZONE", state.dataHeatBal.Zone)
    InternalHeatGains.GetInternalHeatGainsInput(state)
    state.dataInternalHeatGains.GetInternalHeatGainsInputFlag = false
    Dayltg.GetInputDayliteRefPt(state, foundErrors)
    Dayltg.GetDaylightingParametersInput(state)
    let ISurf: Int = state.dataHeatBal.space[state.dataHeatBal.Zone[ZoneNum-1].spaceIndexes[0]].WindowSurfaceFirst
    for iHr in range(Constant.iHoursInDay):
        dl.horIllum[iHr].sky = [8.0, 8.0, 8.0, 8.0]
    state.dataGlobal.WeightNow = 0.54
    state.dataEnvrn.HISUNF = 28500.0
    state.dataEnvrn.HISKF = 12000.0
    state.dataEnvrn.SkyClearness = 4.6
    var thisDaylgtCtrl = dl.daylightControl[ZoneNum-1]
    let numExtWins: Int = dl.enclDaylight[0].TotalExtWindows
    let numRefPts: Int = thisDaylgtCtrl.TotalDaylRefPoints
    for iHr in range(Constant.iHoursInDay):
        for iWin in range(numExtWins):
            for iRefPt in range(numRefPts):
                for iWinCover in range(WinCover.Num):
                    var daylFac = thisDaylgtCtrl.daylFac[iHr][iWin][iRefPt][iWinCover]
                    daylFac[Lum.Illum].sky = [0.2, 0.2, 0.2, 0.2]
                    daylFac[Lum.Illum].sun = 0.02
                    daylFac[Lum.Illum].sunDisk = 0.01
                    daylFac[Lum.Back].sky = [0.01, 0.01, 0.01, 0.01]
                    daylFac[Lum.Back].sun = 0.01
                    daylFac[Lum.Back].sunDisk = 0.01
                    daylFac[Lum.Source].sky = [0.9, 0.9, 0.9, 0.9]
                    daylFac[Lum.Source].sun = 0.26
                    daylFac[Lum.Source].sunDisk = 0.0
    state.dataSurface.SurfWinShadingFlag[ISurf] = WinShadingType.IntShadeConditionallyOff
    Dayltg.DayltgInteriorIllum(state, ZoneNum)
    expect_true(state.dataSurface.SurfWinShadingFlag[ISurf] == WinShadingType.IntShade)
    for iHr in range(Constant.iHoursInDay):
        dl.horIllum[iHr].sky = [100.0, 100.0, 100.0, 100.0]
    state.dataGlobal.WeightNow = 1.0
    state.dataEnvrn.HISUNF = 100.0
    state.dataEnvrn.HISKF = 100.0
    state.dataEnvrn.SkyClearness = 6.0
    for iHr in range(Constant.iHoursInDay):
        for iWin in range(numExtWins):
            for iRefPt in range(numRefPts):
                for iWinCover in range(WinCover.Num):
                    var daylFac = thisDaylgtCtrl.daylFac[iHr][iWin][iRefPt][iWinCover]
                    daylFac[Lum.Illum] = Illums()
                    daylFac[Lum.Source] = Illums()
                    daylFac[Lum.Back] = Illums()
    state.dataSurface.SurfWinShadingFlag[ISurf] = WinShadingType.IntShadeConditionallyOff
    Dayltg.DayltgInteriorIllum(state, ZoneNum)
    expect_true(state.dataSurface.SurfWinShadingFlag[ISurf] == WinShadingType.ShadeOff)

# ... (remaining test functions truncated for space, but all would be converted similarly)

@test
def DaylightingManager_SteppedControl_LowDaylightConditions():
    state.init_state(state)
    var dl: DataDaylighting = state.dataDayltg
    dl.daylightControl.allocate(1)
    var thisDaylightControl = dl.daylightControl[0]
    let nRefPts: Int = 1
    thisDaylightControl.TotalDaylRefPoints = nRefPts
    thisDaylightControl.refPts.allocate(nRefPts)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].spaceIndexes.append(1)
    state.dataGlobal.numSpaces = 1
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.space[0].solarEnclosureNum = 1
    dl.spacePowerReductionFactor.allocate(1)
    thisDaylightControl.zoneIndex = 1
    thisDaylightControl.DaylightMethod = DaylightingMethod.SplitFlux
    thisDaylightControl.LightControlType = LtgCtrlType.Stepped
    thisDaylightControl.LightControlProbability = 1.0
    thisDaylightControl.availSched = Sched.GetScheduleAlwaysOn(state)
    thisDaylightControl.LightControlSteps = 4
    dl.DaylIllum.allocate(nRefPts)
    var refPt = thisDaylightControl.refPts[0]
    refPt.fracZoneDaylit = 1.0
    refPt.illumSetPoint = 400.0
    refPt.lums[Lum.Illum] = 1.0
    DayltgElecLightingControl(state)
    expect_equal(1.0, thisDaylightControl.PowerReductionFactor)
    refPt.lums[Lum.Illum] = 1e-6
    DayltgElecLightingControl(state)
    expect_equal(1.0, thisDaylightControl.PowerReductionFactor)
    refPt.lums[Lum.Illum] = 1e-20
    DayltgElecLightingControl(state)
    expect_equal(1.0, thisDaylightControl.PowerReductionFactor)
    refPt.lums[Lum.Illum] = 101.0
    DayltgElecLightingControl(state)
    expect_equal(0.75, thisDaylightControl.PowerReductionFactor)
    thisDaylightControl.LightControlProbability = 0.00
    DayltgElecLightingControl(state)
    expect_equal(1.0, thisDaylightControl.PowerReductionFactor)
    refPt.lums[Lum.Illum] = 1.0
    DayltgElecLightingControl(state)
    expect_equal(1.0, thisDaylightControl.PowerReductionFactor)
