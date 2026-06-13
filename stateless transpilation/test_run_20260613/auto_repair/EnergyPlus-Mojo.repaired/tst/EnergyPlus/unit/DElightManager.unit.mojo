from gtest import *  # hypothetical Mojo gtest if available; else we'll define test fixtures
from EnergyPlus import DElightManagerF, EnergyPlusData, DataEnvironment, DataGlobals, DataHeatBalance, DaylightingManager, General, HeatBalanceManager, IOFiles, InputProcessor, InternalHeatGains, Material, ScheduleManager, SimulationManager, SurfaceGeometry, ZoneEquipmentManager
from EnergyPlus.Fixtures import EnergyPlusFixture
from EnergyPlus.Constant import DegToRad
from math import cos, sin

def main() raises:
    var fixture = EnergyPlusFixture()
    fixture.SetUp()

    var idf_objects = delimited_string([
        "  Daylighting:DELight:ComplexFenestration,                                           ",
        "    Test CFS,                !- Name                                                 ",
        "    BTDF^GEN^LIGHTSHELF^1.0^20.0,  !- Complex Fenestration Type                      ",
        "    Zn001:Wall001,           !- Building Surface Name     ",
        "    Zn001:Wall001:Win001,    !- Window Name        ",
        "    0.0;                     !- Fenestration Rotation {deg}                          ",
        "                                                                                                                  ",
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
        "    2.048,                   !- X-Coordinate of Reference Point {m}                                               ",
        "    3.048,                   !- Y-Coordinate of Reference Point {m}                                               ",
        "    0.9;                     !- Z-Coordinate of Reference Point {m}                                               ",
        "                                                                                                                  ",
        "  Lights,                                                                                                         ",
        "    West Zone Lights 1,      !- Name                                                                              ",
        "    West Zone,               !- Zone or ZoneList Name                                                             ",
        "    Office Lighting,         !- Schedule Name                                                                     ",
        "    LightingLevel,           !- Design Level Calculation Method                                                   ",
        "    1464.375,                !- Lighting Level {W}                                                                ",
        "    ,                        !- Watts per Zone Floor Area {W/m2}                                                  ",
        "    ,                        !- Watts per Person {W/person}                                                       ",
        "    0.0000000E+00,           !- Return Air Fraction                                                               ",
        "    0.2000000,               !- Fraction Radiant                                                                  ",
        "    0.2000000,               !- Fraction Visible                                                                  ",
        "    1.0,                     !- Fraction Replaceable                                                              ",
        "    GeneralLights;           !- End-Use Subcategory                                                               ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Wall001,           !- Name                                                                              ",
        "    Wall,                    !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    SunExposed,              !- Sun Exposure                                                                      ",
        "    WindExposed,             !- Wind Exposure                                                                     ",
        "    0.5000000,               !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    0.0000000E+00,0.0000000E+00,3.048000,  !- X,Y,Z ==> Vertex 1 {m}                                              ",
        "    0.0000000E+00,0.0000000E+00,0.0000000E+00,  !- X,Y,Z ==> Vertex 2 {m}                                         ",
        "    6.096000,0.0000000E+00,0.0000000E+00,  !- X,Y,Z ==> Vertex 3 {m}                                              ",
        "    6.096000,0.0000000E+00,3.048000;  !- X,Y,Z ==> Vertex 4 {m}                                                   ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Wall002,           !- Name                                                                              ",
        "    Wall,                    !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    SunExposed,              !- Sun Exposure                                                                      ",
        "    WindExposed,             !- Wind Exposure                                                                     ",
        "    0.5000000,               !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    0.0000000E+00,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}                                                   ",
        "    0.0000000E+00,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 2 {m}                                              ",
        "    0.0000000E+00,0.0000000E+00,0.0000000E+00,  !- X,Y,Z ==> Vertex 3 {m}                                         ",
        "    0.0000000E+00,0.0000000E+00,3.048000;  !- X,Y,Z ==> Vertex 4 {m}                                              ",
        "                                                                                                                  ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Wall003,           !- Name                                                                              ",
        "    Wall,                    !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    SunExposed,              !- Sun Exposure                                                                      ",
        "    WindExposed,             !- Wind Exposure                                                                     ",
        "    0.5000000,               !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    6.096000,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}                                                        ",
        "    6.096000,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 2 {m}                                                   ",
        "    0.0000000E+00,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 3 {m}                                              ",
        "    0.0000000E+00,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}                                                   ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Wall004,           !- Name                                                                              ",
        "    Wall,                    !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    SunExposed,              !- Sun Exposure                                                                      ",
        "    WindExposed,             !- Wind Exposure                                                                     ",
        "    0.5000000,               !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    6.096000,0.0000000E+00,3.048000,  !- X,Y,Z ==> Vertex 1 {m}                                                   ",
        "    6.096000,0.0000000E+00,0.0000000E+00,  !- X,Y,Z ==> Vertex 2 {m}                                              ",
        "    6.096000,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 3 {m}                                                   ",
        "    6.096000,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}                                                        ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Flr001,            !- Name                                                                              ",
        "    Floor,                   !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    NoSun,                   !- Sun Exposure                                                                      ",
        "    NoWind,                  !- Wind Exposure                                                                     ",
        "    1.000000,                !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    0.0000000E+00,0.0000000E+00,0.0000000E+00,  !- X,Y,Z ==> Vertex 1 {m}                                         ",
        "    0.0000000E+00,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 2 {m}                                              ",
        "    6.096000,6.096000,0.0000000E+00,  !- X,Y,Z ==> Vertex 3 {m}                                                   ",
        "    6.096000,0.0000000E+00,0.0000000E+00;  !- X,Y,Z ==> Vertex 4 {m}                                              ",
        "                                                                                                                  ",
        "  BuildingSurface:Detailed,                                                                                       ",
        "    Zn001:Roof001,           !- Name                                                                              ",
        "    Roof,                    !- Surface Type                                                                      ",
        "    WALL80,                  !- Construction Name                                                                 ",
        "    West Zone,               !- Zone Name                                                                         ",
        "    ,                        !- Space Name                                                                        ",
        "    Outdoors,                !- Outside Boundary Condition                                                        ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    SunExposed,              !- Sun Exposure                                                                      ",
        "    WindExposed,             !- Wind Exposure                                                                     ",
        "    0.0000000E+00,           !- View Factor to Ground                                                             ",
        "    4,                       !- Number of Vertices                                                                ",
        "    0.0000000E+00,6.096000,3.048000,  !- X,Y,Z ==> Vertex 1 {m}                                                   ",
        "    0.0000000E+00,0.0000000E+00,3.048000,  !- X,Y,Z ==> Vertex 2 {m}                                              ",
        "    6.096000,0.0000000E+00,3.048000,  !- X,Y,Z ==> Vertex 3 {m}                                                   ",
        "    6.096000,6.096000,3.048000;  !- X,Y,Z ==> Vertex 4 {m}                                                        ",
        "                                                                                                                  ",
        "  FenestrationSurface:Detailed,                                                                                   ",
        "    Zn001:Wall001:Win001,    !- Name                                                                              ",
        "    Window,                  !- Surface Type                                                                      ",
        "    WIN-CON-SINGLEPANE,      !- Construction Name                                                                 ",
        "    Zn001:Wall001,           !- Building Surface Name                                                             ",
        "    ,                        !- Outside Boundary Condition Object                                                 ",
        "    0.5000000,               !- View Factor to Ground                                                             ",
        "    ,                        !- Frame and Divider Name                                                            ",
        "    1.0,                     !- Multiplier                                                                        ",
        "    4,                       !- Number of Vertices                                                                ",
        "    0.548000,0.0000000E+00,2.5000,  !- X,Y,Z ==> Vertex 1 {m}                                                     ",
        "    0.548000,0.0000000E+00,0.5000,  !- X,Y,Z ==> Vertex 2 {m}                                                     ",
        "    5.548000,0.0000000E+00,0.5000,  !- X,Y,Z ==> Vertex 3 {m}                                                     ",
        "    5.548000,0.0000000E+00,2.5000;  !- X,Y,Z ==> Vertex 4 {m}                                                     ",
        "                                                                                                                  ",
        "  Construction,                                                                                                   ",
        "    WALL80,               !- Name                                                                                 ",
        "    C4 - 4 IN COMMON BRICK;  !- Layer 1                                                                           ",
        "                                                                                                                  ",
        "  Material,                                                                                                       ",
        "    C4 - 4 IN COMMON BRICK,  !- Name                                                                              ",
        "    Rough,                   !- Roughness                                                                         ",
        "    0.1014984,               !- Thickness {m}                                                                     ",
        "    0.7264224,               !- Conductivity {W/m-K}                                                              ",
        "    1922.216,                !- Density {kg/m3}                                                                   ",
        "    836.8000,                !- Specific Heat {J/kg-K}                                                            ",
        "    0.9000000,               !- Thermal Absorptance                                                               ",
        "    0.7600000,               !- Solar Absorptance                                                                 ",
        "    0.7600000;               !- Visible Absorptance                                                               ",
        "                                                                                                                  ",
        "  Schedule:Compact,                                                                                               ",
        "    Office Lighting,         !- Name                                                                              ",
        "    ANY NUMBER,              !- Schedule Type Limits Name                                                         ",
        "    Through: 12/31,          !- Field 1                                                                           ",
        "    For: Alldays,            !- Field 2                                                                           ",
        "    Until: 24:00,1.00;       !- Field 7                                                                           ",
        "                                                                                                                  ",
        "  Construction,                                                                                                   ",
        "    WIN-CON-SINGLEPANE,      !- Name                                                                              ",
        "    SINGLEPANE;              !- Outside Layer                                                                     ",
        "                                                                                                                  ",
        "  WindowMaterial:Glazing,                                                                                         ",
        "    SINGLEPANE,              !- Name                                                                              ",
        "    SpectralAverage,         !- Optical Data Type                                                                 ",
        "    ,                        !- Window Glass Spectral Data Set Name                                               ",
        "    0.003,                   !- Thickness {m}                                                                     ",
        "    0.90,                    !- Solar Transmittance at Normal Incidence                                           ",
        "    0.031,                   !- Front Side Solar Reflectance at Normal Incidence                                  ",
        "    0.031,                   !- Back Side Solar Reflectance at Normal Incidence                                   ",
        "    0.90,                    !- Visible Transmittance at Normal Incidence                                         ",
        "    0.05,                    !- Front Side Visible Reflectance at Normal Incidence                                ",
        "    0.05,                    !- Back Side Visible Reflectance at Normal Incidence                                 ",
        "    0.0,                     !- Infrared Transmittance at Normal Incidence                                        ",
        "    0.84,                    !- Front Side Infrared Hemispherical Emissivity                                      ",
        "    0.84,                    !- Back Side Infrared Hemispherical Emissivity                                       ",
        "    0.9;                     !- Conductivity {W/m-K}                                                              ",
        "SurfaceConvectionAlgorithm:Inside,TARP;",
        "SurfaceConvectionAlgorithm:Outside,DOE-2;",
        "HeatBalanceAlgorithm,ConductionTransferFunction;",
        "ZoneAirHeatBalanceAlgorithm,",
        "    AnalyticalSolution;      !- Algorithm",
        "ScheduleTypeLimits,",
        "    Any Number;              !- Name",
    ])

    assert fixture.process_idf(idf_objects)

    var state = fixture.state
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)

    var foundErrors: Bool = false

    Material.GetMaterialData(state, foundErrors)
    assert not foundErrors

    HeatBalanceManager.GetConstructData(state, foundErrors)
    fixture.compare_err_stream("")
    assert not foundErrors

    HeatBalanceManager.GetZoneData(state, foundErrors)
    assert not foundErrors

    ZoneEquipmentManager.GetZoneEquipment(state)

    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = cos(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = sin(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0

    SurfaceGeometry.GetSurfaceData(state, foundErrors)
    assert not foundErrors

    SurfaceGeometry.SetupZoneGeometry(state, foundErrors)
    assert not foundErrors

    state.dataGlobal.TimeStep = 1
    state.dataGlobal.HourOfDay = 1
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

    GetInputDElightComplexFenestration(state, foundErrors)
    fixture.compare_err_stream("")
    assert not foundErrors

    assert Fixture.state.dataDayltg.DElightComplexFene.size() == 1
    assert Fixture.state.dataDayltg.DElightComplexFene[0].Name == "TEST CFS"
    assert Fixture.state.dataDayltg.DElightComplexFene[0].ComplexFeneType == "BTDF^GEN^LIGHTSHELF^1.0^20.0"
    assert Fixture.state.dataDayltg.DElightComplexFene[0].surfName == "ZN001:WALL001"
    assert Fixture.state.dataDayltg.DElightComplexFene[0].wndwName == "ZN001:WALL001:WIN001"
    assert Fixture.state.dataDayltg.DElightComplexFene[0].feneRota == 0.0

    print("Test DElightManagerF_GetInputDElightComplexFenestration_Test passed")