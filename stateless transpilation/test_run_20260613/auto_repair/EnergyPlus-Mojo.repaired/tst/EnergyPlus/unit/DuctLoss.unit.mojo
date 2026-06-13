from gtest import Test, TestFixture, EXPECT_NEAR, ASSERT_TRUE
from AirflowNetwork.Elements import *
from AirflowNetwork.Solver import *
from EnergyPlus.BranchInputManager import *
from EnergyPlus.BranchNodeConnections import *
from EnergyPlus.CurveManager import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataDefineEquip import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.DuctLoss import DuctLoss
from EnergyPlus.Fans import Fans
from EnergyPlus.HVACStandAloneERV import HVACStandAloneERV
from EnergyPlus.HVACVariableRefrigerantFlow import *
from EnergyPlus.HeatBalanceAirManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HeatingCoils import *
from EnergyPlus.IOFiles import *
from EnergyPlus.InternalHeatGains import *
from EnergyPlus.Material import *
from EnergyPlus.OutAirNodeManager import OutAirNodeManager
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimAirServingZones import *
from EnergyPlus.SimulationManager import SimulationManager
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UnitarySystem import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WaterThermalTanks import *
from EnergyPlus.WindowAC import *
from EnergyPlus.ZoneAirLoopEquipmentManager import *
from EnergyPlus.ZoneEquipmentManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

using EnergyPlus
using AirflowNetwork
using DataSurfaces
using DataHeatBalance
using OutAirNodeManager
using EnergyPlus.Fans
using EnergyPlus.HVACStandAloneERV

@fixture
class DuctLoss_test(EnergyPlusFixture):
    def run(self):
        var idf_objects0: String = R"IDF(
  Version,26.2;
  Building,
    House with AirflowNetwork simulation,  !- Name
    0,                       !- North Axis {deg}
    Suburbs,                 !- Terrain
    0.001,                   !- Loads Convergence Tolerance Value {W}
    0.0050000,               !- Temperature Convergence Tolerance Value {deltaC}
    FullInteriorAndExterior, !- Solar Distribution
    25,                      !- Maximum Number of Warmup Days
    6;                       !- Minimum Number of Warmup Days
  Timestep,6;
  SurfaceConvectionAlgorithm:Inside,TARP;
  SurfaceConvectionAlgorithm:Outside,DOE-2;
  HeatBalanceAlgorithm,ConductionTransferFunction;
  Output:DebuggingData,
    No,                      !- Report Debugging Data
    No;                      !- Report During Warmup
  SimulationControl,
    No,                      !- Do Zone Sizing Calculation
    No,                      !- Do System Sizing Calculation
    No,                      !- Do Plant Sizing Calculation
    Yes,                     !- Run Simulation for Sizing Periods
    No,                      !- Run Simulation for Weather File Run Periods
    No,                      !- Do HVAC Sizing Simulation for Sizing Periods
    1;                       !- Maximum Number of HVAC Sizing Simulation Passes
  RunPeriod,
    Run Period 1,            !- Name
    1,                       !- Begin Month
    14,                      !- Begin Day of Month
    ,                        !- Begin Year
    1,                       !- End Month
    14,                      !- End Day of Month
    ,                        !- End Year
    Tuesday,                 !- Day of Week for Start Day
    Yes,                     !- Use Weather File Holidays and Special Days
    Yes,                     !- Use Weather File Daylight Saving Period
    No,                      !- Apply Weekend Holiday Rule
    Yes,                     !- Use Weather File Rain Indicators
    Yes;                     !- Use Weather File Snow Indicators
  RunPeriod,
    Run Period 2,            !- Name
    7,                       !- Begin Month
    7,                       !- Begin Day of Month
    ,                        !- Begin Year
    7,                       !- End Month
    7,                       !- End Day of Month
    ,                        !- End Year
    Tuesday,                 !- Day of Week for Start Day
    Yes,                     !- Use Weather File Holidays and Special Days
    Yes,                     !- Use Weather File Daylight Saving Period
    No,                      !- Apply Weekend Holiday Rule
    Yes,                     !- Use Weather File Rain Indicators
    No;                      !- Use Weather File Snow Indicators
  Site:Location,
    CHICAGO_IL_USA TMY2-94846,  !- Name
    41.78,                   !- Latitude {deg}
    -87.75,                  !- Longitude {deg}
    -6.00,                   !- Time Zone {hr}
    190.00;                  !- Elevation {m}
! CHICAGO_IL_USA Annual Heating 99% Design Conditions DB, MaxDB= -17.3degC
  SizingPeriod:DesignDay,
    CHICAGO_IL_USA Annual Heating 99% Design Conditions DB,  !- Name
    1,                       !- Month
    21,                      !- Day of Month
    WinterDesignDay,         !- Day Type
    -17.3,                   !- Maximum Dry-Bulb Temperature {C}
    0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}
    ,                        !- Dry-Bulb Temperature Range Modifier Type
    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name
    Wetbulb,                 !- Humidity Condition Type
    -17.3,                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}
    ,                        !- Humidity Condition Day Schedule Name
    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}
    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}
    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}
    99063.,                  !- Barometric Pressure {Pa}
    4.9,                     !- Wind Speed {m/s}
    270,                     !- Wind Direction {deg}
    No,                      !- Rain Indicator
    No,                      !- Snow Indicator
    No,                      !- Daylight Saving Time Indicator
    ASHRAEClearSky,          !- Solar Model Indicator
    ,                        !- Beam Solar Day Schedule Name
    ,                        !- Diffuse Solar Day Schedule Name
    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}
    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}
    0.0;                     !- Sky Clearness
! CHICAGO_IL_USA Annual Cooling 1% Design Conditions, MaxDB=  31.5degC MCWB=  23.0degC
  SizingPeriod:DesignDay,
    CHICAGO_IL_USA Annual Cooling 1% Design Conditions DB/MCWB,  !- Name
    7,                       !- Month
    21,                      !- Day of Month
    SummerDesignDay,         !- Day Type
    31.5,                    !- Maximum Dry-Bulb Temperature {C}
    10.7,                    !- Daily Dry-Bulb Temperature Range {deltaC}
    ,                        !- Dry-Bulb Temperature Range Modifier Type
    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name
    Wetbulb,                 !- Humidity Condition Type
    23.0,                    !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}
    ,                        !- Humidity Condition Day Schedule Name
    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}
    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}
    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}
    99063.,                  !- Barometric Pressure {Pa}
    5.3,                     !- Wind Speed {m/s}
    230,                     !- Wind Direction {deg}
    No,                      !- Rain Indicator
    No,                      !- Snow Indicator
    No,                      !- Daylight Saving Time Indicator
    ASHRAEClearSky,          !- Solar Model Indicator
    ,                        !- Beam Solar Day Schedule Name
    ,                        !- Diffuse Solar Day Schedule Name
    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}
    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}
    1.0;                     !- Sky Clearness
  Site:GroundTemperature:BuildingSurface,20.03,20.03,20.13,20.30,20.43,20.52,20.62,20.77,20.78,20.55,20.44,20.20;
  Material,
    A1 - 1 IN STUCCO,        !- Name
    Smooth,                  !- Roughness
    2.5389841E-02,           !- Thickness {m}
    0.6918309,               !- Conductivity {W/m-K}
    1858.142,                !- Density {kg/m3}
    836.8000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.9200000,               !- Solar Absorptance
    0.9200000;               !- Visible Absorptance
! CC Blk 8 in HW Hol.
  Material,
    CB11,                    !- Name
    MediumRough,             !- Roughness
    0.2032000,               !- Thickness {m}
    1.048000,                !- Conductivity {W/m-K}
    1105.000,                !- Density {kg/m3}
    837.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.2000000,               !- Solar Absorptance
    0.2000000;               !- Visible Absorptance
! Gyps or Plast Brd 1/2 in
  Material,
    GP01,                    !- Name
    MediumSmooth,            !- Roughness
    1.2700000E-02,           !- Thickness {m}
    0.1600000,               !- Conductivity {W/m-K}
    801.0000,                !- Density {kg/m3}
    837.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.7500000,               !- Solar Absorptance
    0.7500000;               !- Visible Absorptance
! Min.Wool/Fib Batt R-11
  Material,
    IN02,                    !- Name
    Rough,                   !- Roughness
    9.0099998E-02,           !- Thickness {m}
    4.3000001E-02,           !- Conductivity {W/m-K}
    10.00000,                !- Density {kg/m3}
    837.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.7500000,               !- Solar Absorptance
    0.7500000;               !- Visible Absorptance
! Min.Wool/Fib Batt R-30
  Material,
    IN05,                    !- Name
    Rough,                   !- Roughness
    0.2458000,               !- Thickness {m}
    4.3000001E-02,           !- Conductivity {W/m-K}
    10.00000,                !- Density {kg/m3}
    837.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.7500000,               !- Solar Absorptance
    0.7500000;               !- Visible Absorptance
! Plywood1/2 in
  Material,
    PW03,                    !- Name
    MediumSmooth,            !- Roughness
    1.2700000E-02,           !- Thickness {m}
    0.1150000,               !- Conductivity {W/m-K}
    545.0000,                !- Density {kg/m3}
    1213.000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.7800000,               !- Solar Absorptance
    0.7800000;               !- Visible Absorptance
! CC HW Dr.  140 lbs 4 in
  Material,
    CC03,                    !- Name
    MediumRough,             !- Roughness
    0.1016000,               !- Thickness {m}
    1.310000,                !- Conductivity {W/m-K}
    2243.000,                !- Density {kg/m3}
    837.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.6500000,               !- Solar Absorptance
    0.6500000;               !- Visible Absorptance
! STEEL SIDING LW
  Material,
    HF-A3,                   !- Name
    Smooth,                  !- Roughness
    1.5000000E-03,           !- Thickness {m}
    44.96960,                !- Conductivity {W/m-K}
    7689.000,                !- Density {kg/m3}
    418.0000,                !- Specific Heat {J/kg-K}
    0.9000000,               !- Thermal Absorptance
    0.2000000,               !- Solar Absorptance
    0.2000000;               !- Visible Absorptance
! Asphalt Shingle and Siding
  Material:NoMass,
    AR02,                    !- Name
    VeryRough,               !- Roughness
    7.8000002E-02,           !- Thermal Resistance {m2-K/W}
    0.9000000,               !- Thermal Absorptance
    0.7000000,               !- Solar Absorptance
    0.7000000;               !- Visible Absorptance
! Carpet With Rubber Pad
  Material:NoMass,
    CP02,                    !- Name
    Rough,                   !- Roughness
    0.2170000,               !- Thermal Resistance {m2-K/W}
    0.9000000,               !- Thermal Absorptance
    0.7500000,               !- Solar Absorptance
    0.7500000;               !- Visible Absorptance
! ID 2
  WindowMaterial:Glazing,
    CLEAR 3MM,               !- Name
    SpectralAverage,         !- Optical Data Type
    ,                        !- Window Glass Spectral Data Set Name
    0.003,                   !- Thickness {m}
    0.837,                   !- Solar Transmittance at Normal Incidence
    0.075,                   !- Front Side Solar Reflectance at Normal Incidence
    0.075,                   !- Back Side Solar Reflectance at Normal Incidence
    0.898,                   !- Visible Transmittance at Normal Incidence
    0.081,                   !- Front Side Visible Reflectance at Normal Incidence
    0.081,                   !- Back Side Visible Reflectance at Normal Incidence
    0.0,                     !- Infrared Transmittance at Normal Incidence
    0.84,                    !- Front Side Infrared Hemispherical Emissivity
    0.84,                    !- Back Side Infrared Hemispherical Emissivity
    0.9;                     !- Conductivity {W/m-K}
  WindowMaterial:Gas,
    AIR 6MM,                 !- Name
    AIR,                     !- Gas Type
    0.006;                   !- Thickness {m}
  Construction,
    EXTWALL:LIVING,          !- Name
    A1 - 1 IN STUCCO,        !- Outside Layer
    CB11,                    !- Layer 2
    GP01;                    !- Layer 3
  Construction,
    INTERIORWall,            !- Name
    GP01,                    !- Outside Layer
    IN02,                    !- Layer 2
    GP01;                    !- Layer 3
  Construction,
    FLOOR:GARAGE,            !- Name
    CC03;                    !- Outside Layer
  Construction,
    FLOOR:LIVING,            !- Name
    CC03,                    !- Outside Layer
    CP02;                    !- Layer 2
  Construction,
    ROOF,                    !- Name
    AR02,                    !- Outside Layer
    PW03;                    !- Layer 2
  Construction,
    EXTWALL:GARAGE,          !- Name
    A1 - 1 IN STUCCO,        !- Outside Layer
    CB11;                    !- Layer 2
  Construction,
    CEILING:LIVING,          !- Name
    IN05,                    !- Outside Layer
    GP01;                    !- Layer 2
  Construction,
    reverseCEILING:LIVING,   !- Name
    GP01,                    !- Outside Layer
    IN05;                    !- Layer 2
  Construction,
    GABLE,                   !- Name
    PW03;                    !- Outside Layer
! 2000  U=3.23  SC= .88  SHGC=.76  TSOL=.70  TVIS=.81
  Construction,
    Dbl Clr 3mm/6mm Air,     !- Name
    CLEAR 3MM,               !- Outside Layer
    AIR 6MM,                 !- Layer 2
    CLEAR 3MM;               !- Layer 3
  Construction,
    Garage:SteelDoor,        !- Name
    HF-A3;                   !- Outside Layer
  Construction,
    CEILING:Garage,          !- Name
    GP01;                    !- Outside Layer
  Zone,
    LIVING ZONE,             !- Name
    0,                       !- Direction of Relative North {deg}
    0,                       !- X Origin {m}
    0,                       !- Y Origin {m}
    0,                       !- Z Origin {m}
    1,                       !- Type
    1,                       !- Multiplier
    autocalculate,           !- Ceiling Height {m}
    autocalculate;           !- Volume {m3}
  Zone,
    GARAGE ZONE,             !- Name
    0,                       !- Direction of Relative North {deg}
    0,                       !- X Origin {m}
    0,                       !- Y Origin {m}
    0,                       !- Z Origin {m}
    1,                       !- Type
    1,                       !- Multiplier
    autocalculate,           !- Ceiling Height {m}
    autocalculate;           !- Volume {m3}
  Zone,
    ATTIC ZONE,              !- Name
    0,                       !- Direction of Relative North {deg}
    0,                       !- X Origin {m}
    0,                       !- Y Origin {m}
    0,                       !- Z Origin {m}
    1,                       !- Type
    1,                       !- Multiplier
    autocalculate,           !- Ceiling Height {m}
    autocalculate;           !- Volume {m3}
  GlobalGeometryRules,
    UpperLeftCorner,         !- Starting Vertex Position
    CounterClockWise,        !- Vertex Entry Direction
    World;                   !- Coordinate System
  BuildingSurface:Detailed,
    Living:North,            !- Name
    Wall,                    !- Surface Type
    EXTWALL:LIVING,          !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,10.778,0,  !- X,Y,Z ==> Vertex 2 {m}
    0,10.778,0,  !- X,Y,Z ==> Vertex 3 {m}
    0,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
    )IDF"
        var idf_objects1: String = R"IDF(
  BuildingSurface:Detailed,
    Living:East,             !- Name
    Wall,                    !- Surface Type
    EXTWALL:LIVING,          !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    17.242,0,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,0,0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Living:South,            !- Name
    Wall,                    !- Surface Type
    EXTWALL:LIVING,          !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    0,0,2.4383,  !- X,Y,Z ==> Vertex 1 {m}
    0,0,0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,0,0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,0,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Living:West,             !- Name
    Wall,                    !- Surface Type
    EXTWALL:LIVING,          !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    0,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    0,10.778,0,  !- X,Y,Z ==> Vertex 2 {m}
    0,0,0,  !- X,Y,Z ==> Vertex 3 {m}
    0,0,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Garage:Interior,         !- Name
    WALL,                    !- Surface Type
    INTERIORWall,            !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Living:Interior,         !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,10.778,0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Living:Interior,         !- Name
    WALL,                    !- Surface Type
    INTERIORWall,            !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Garage:Interior,         !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,10.778,0,  !- X,Y,Z ==> Vertex 2 {m}
    10.323,10.778,0,  !- X,Y,Z ==> Vertex 3 {m}
    10.323,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Living:Floor,            !- Name
    FLOOR,                   !- Surface Type
    FLOOR:LIVING,            !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Living:Floor,            !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0,                       !- View Factor to Ground
    4,                       !- Number of Vertices
    0,0,0,  !- X,Y,Z ==> Vertex 1 {m}
    0,10.778,0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,0,0;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Living:Ceiling,          !- Name
    CEILING,                 !- Surface Type
    CEILING:LIVING,          !- Construction Name
    LIVING ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Attic:LivingFloor,       !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0,                       !- View Factor to Ground
    4,                       !- Number of Vertices
    0,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    0,0,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,0,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Attic:LivingFloor,       !- Name
    FLOOR,                   !- Surface Type
    reverseCEILING:LIVING,   !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Living:Ceiling,          !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    0,0,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    0,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,0,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    NorthRoof1,              !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    13.782,5.389,4.6838,  !- X,Y,Z ==> Vertex 1 {m}
    13.782,7.3172,3.8804,  !- X,Y,Z ==> Vertex 2 {m}
    0,7.3172,3.8804,  !- X,Y,Z ==> Vertex 3 {m}
    0,5.389,4.6838;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    SouthRoof,               !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5000000,               !- View Factor to Ground
    4,                       !- Number of Vertices
    0.000000,5.389000,4.683800,  !- X,Y,Z ==> Vertex 1 {m}
    0.000000,0.000000,2.438400,  !- X,Y,Z ==> Vertex 2 {m}
    17.24200,0.000000,2.438400,  !- X,Y,Z ==> Vertex 3 {m}
    17.24200,5.389000,4.683800;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    NorthRoof2,              !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    13.782,7.3172,3.8804,  !- X,Y,Z ==> Vertex 1 {m}
    10.332,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    0.0,10.778,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    0.0,7.3172,3.8804;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    NorthRoof3,              !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    17.242,5.389,4.6838,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,7.3172,3.8804,  !- X,Y,Z ==> Vertex 2 {m}
    13.782,7.3172,3.8804,  !- X,Y,Z ==> Vertex 3 {m}
    13.782,5.389,4.6838;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    NorthRoof4,              !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    3,                       !- Number of Vertices
    17.242,7.3172,3.8804,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    13.782,7.3172,3.8804;  !- X,Y,Z ==> Vertex 3 {m}
  BuildingSurface:Detailed,
    EastGable,               !- Name
    WALL,                    !- Surface Type
    GABLE,                   !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    3,                       !- Number of Vertices
    17.242,5.389,4.6838,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,0.0,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,2.4384;  !- X,Y,Z ==> Vertex 3 {m}
  BuildingSurface:Detailed,
    WestGable,               !- Name
    WALL,                    !- Surface Type
    GABLE,                   !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    3,                       !- Number of Vertices
    0.0,5.389,4.6838,  !- X,Y,Z ==> Vertex 1 {m}
    0.0,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    0.0,0.0,2.4384;  !- X,Y,Z ==> Vertex 3 {m}
  BuildingSurface:Detailed,
    EastRoof,                !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    13.782,16.876,3.8804,  !- X,Y,Z ==> Vertex 1 {m}
    13.782,7.3172,3.8804,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,16.876,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    WestRoof,                !- Name
    ROOF,                    !- Surface Type
    ROOF,                    !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.9,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,16.876,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    13.782,7.3172,3.8804,  !- X,Y,Z ==> Vertex 3 {m}
    13.782,16.876,3.8804;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Attic:NorthGable,        !- Name
    WALL,                    !- Surface Type
    GABLE,                   !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    3,                       !- Number of Vertices
    13.782,16.876,3.8804,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,16.876,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    10.323,16.876,2.4384;  !- X,Y,Z ==> Vertex 3 {m}
  BuildingSurface:Detailed,
    Garage:EastWall,         !- Name
    WALL,                    !- Surface Type
    EXTWALL:GARAGE,          !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,10.778,0.0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,16.876,0.0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,16.876,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Garage:WestWall,         !- Name
    WALL,                    !- Surface Type
    EXTWALL:GARAGE,          !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,16.876,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,16.876,0.0,  !- X,Y,Z ==> Vertex 2 {m}
    10.323,10.778,0.0,  !- X,Y,Z ==> Vertex 3 {m}
    10.323,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Garage:FrontDoor,        !- Name
    WALL,                    !- Surface Type
    Garage:SteelDoor,        !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Outdoors,                !- Outside Boundary Condition
    ,                        !- Outside Boundary Condition Object
    SunExposed,              !- Sun Exposure
    WindExposed,             !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    17.242,16.876,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,16.876,0.0,  !- X,Y,Z ==> Vertex 2 {m}
    10.323,16.876,0.0,  !- X,Y,Z ==> Vertex 3 {m}
    10.323,16.876,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
    )IDF"
        var idf_objects2: String = R"IDF(
  BuildingSurface:Detailed,
    Attic:GarageFloor,       !- Name
    FLOOR,                   !- Surface Type
    CEILING:Garage,          !- Construction Name
    ATTIC ZONE,              !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Garage:Ceiling,          !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,10.778,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,16.876,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,16.876,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,10.778,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Garage:Ceiling,          !- Name
    CEILING,                 !- Surface Type
    CEILING:Garage,          !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Attic:GarageFloor,       !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0.5,                     !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,16.876,2.4384,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,10.778,2.4384,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,10.778,2.4384,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,16.876,2.4384;  !- X,Y,Z ==> Vertex 4 {m}
  BuildingSurface:Detailed,
    Garage:Floor,            !- Name
    FLOOR,                   !- Surface Type
    FLOOR:GARAGE,            !- Construction Name
    GARAGE ZONE,             !- Zone Name
    ,                        !- Space Name
    Surface,                 !- Outside Boundary Condition
    Garage:Floor,            !- Outside Boundary Condition Object
    NoSun,                   !- Sun Exposure
    NoWind,                  !- Wind Exposure
    0,                       !- View Factor to Ground
    4,                       !- Number of Vertices
    10.323,10.778,0,  !- X,Y,Z ==> Vertex 1 {m}
    10.323,16.876,0,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,16.876,0,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,10.778,0;  !- X,Y,Z ==> Vertex 4 {m}
  FenestrationSurface:Detailed,
    NorthWindow,             !- Name
    Window,                  !- Surface Type
    Dbl Clr 3mm/6mm Air,     !- Construction Name
    Living:North,            !- Building Surface Name
    ,                        !- Outside Boundary Condition Object
    0.5000000,               !- View Factor to Ground
    ,                        !- Frame and Divider Name
    1.0,                     !- Multiplier
    4,                       !- Number of Vertices
    6.572,10.778,2.1336,  !- X,Y,Z ==> Vertex 1 {m}
    6.572,10.778,0.6096,  !- X,Y,Z ==> Vertex 2 {m}
    2,10.778,0.6096,  !- X,Y,Z ==> Vertex 3 {m}
    2,10.778,2.1336;  !- X,Y,Z ==> Vertex 4 {m}
  FenestrationSurface:Detailed,
    EastWindow,              !- Name
    Window,                  !- Surface Type
    Dbl Clr 3mm/6mm Air,     !- Construction Name
    Living:East,             !- Building Surface Name
    ,                        !- Outside Boundary Condition Object
    0.5000000,               !- View Factor to Ground
    ,                        !- Frame and Divider Name
    1.0,                     !- Multiplier
    4,                       !- Number of Vertices
    17.242,2,2.1336,  !- X,Y,Z ==> Vertex 1 {m}
    17.242,2,0.6096,  !- X,Y,Z ==> Vertex 2 {m}
    17.242,6.572,0.6096,  !- X,Y,Z ==> Vertex 3 {m}
    17.242,6.572,2.1336;  !- X,Y,Z ==> Vertex 4 {m}
  FenestrationSurface:Detailed,
    SouthWindow,             !- Name
    Window,                  !- Surface Type
    Dbl Clr 3mm/6mm Air,     !- Construction Name
    Living:South,            !- Building Surface Name
    ,                        !- Outside Boundary Condition Object
    0.5000000,               !- View Factor to Ground
    ,                        !- Frame and Divider Name
    1.0,                     !- Multiplier
    4,                       !- Number of Vertices
    2,0,2.1336,  !- X,Y,Z ==> Vertex 1 {m}
    2,0,0.6096,  !- X,Y,Z ==> Vertex 2 {m}
    6.572,0,0.6096,  !- X,Y,Z ==> Vertex 3 {m}
    6.572,0,2.1336;  !- X,Y,Z ==> Vertex 4 {m}
  FenestrationSurface:Detailed,
    WestWindow,              !- Name
    Window,                  !- Surface Type
    Dbl Clr 3mm/6mm Air,     !- Construction Name
    Living:West,             !- Building Surface Name
    ,                        !- Outside Boundary Condition Object
    0.5000000,               !- View Factor to Ground
    ,                        !- Frame and Divider Name
    1.0,                     !- Multiplier
    4,                       !- Number of Vertices
    0,6.572,2.1336,  !- X,Y,Z ==> Vertex 1 {m}
    0,6.572,0.6096,  !- X,Y,Z ==> Vertex 2 {m}
    0,2,0.6096,  !- X,Y,Z ==> Vertex 3 {m}
    0,2,2.1336;  !- X,Y,Z ==> Vertex 4 {m}
    )IDF"
        var idf_objects3: String = R"IDF(
  ScheduleTypeLimits,
    Any Number;              !- Name
  ScheduleTypeLimits,
    Fraction,                !- Name
    0.0,                     !- Lower Limit Value
    1.0,                     !- Upper Limit Value
    CONTINUOUS;              !- Numeric Type
  ScheduleTypeLimits,
    Temperature,             !- Name
    -60,                     !- Lower Limit Value
    200,                     !- Upper Limit Value
    CONTINUOUS,              !- Numeric Type
    Temperature;             !- Unit Type
  ScheduleTypeLimits,
    Control Type,            !- Name
    0,                       !- Lower Limit Value
    4,                       !- Upper Limit Value
    DISCRETE;                !- Numeric Type
  ScheduleTypeLimits,
    On/Off,                  !- Name
    0,                       !- Lower Limit Value
    1,                       !- Upper Limit Value
    DISCRETE;                !- Numeric Type
  Schedule:Compact,
    WindowVentSched,         !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 3/31,           !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,25.55,      !- Field 3
    Through: 9/30,           !- Field 5
    For: AllDays,            !- Field 6
    Until: 24:00,21.11,      !- Field 7
    Through: 12/31,          !- Field 9
    For: AllDays,            !- Field 10
    Until: 24:00,25.55;      !- Field 11
  Schedule:Compact,
    Activity Sch,            !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,131.8;      !- Field 3
  Schedule:Compact,
    Work Eff Sch,            !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,0.0;        !- Field 3
  Schedule:Compact,
    Clothing Sch,            !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,1.0;        !- Field 3
  Schedule:Compact,
    Air Velo Sch,            !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,0.137;      !- Field 3
  Schedule:Compact,
    HOUSE OCCUPANCY,         !- Name
    Fraction,                !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: WeekDays,           !- Field 2
    Until: 6:00,1.0,         !- Field 3
    Until: 7:00,0.10,        !- Field 5
    Until: 8:00,0.50,        !- Field 7
    Until: 12:00,1.00,       !- Field 9
    Until: 13:00,0.50,       !- Field 11
    Until: 16:00,1.00,       !- Field 13
    Until: 17:00,0.50,       !- Field 15
    Until: 18:00,0.10,       !- Field 17
    Until: 24:00,1.0,        !- Field 19
    For: AllOtherDays,       !- Field 21
    Until: 24:00,0.0;        !- Field 22
  Schedule:Compact,
    INTERMITTENT,            !- Name
    Fraction,                !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: WeekDays,           !- Field 2
    Until: 8:00,0.0,         !- Field 3
    Until: 18:00,1.00,       !- Field 5
    Until: 24:00,0.0,        !- Field 7
    For: AllOtherDays,       !- Field 9
    Until: 24:00,0.0;        !- Field 10
  Schedule:Compact,
    HOUSE LIGHTING,          !- Name
    Fraction,                !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: WeekDays,           !- Field 2
    Until: 6:00,0.05,        !- Field 3
    Until: 7:00,0.20,        !- Field 5
    Until: 17:00,1.00,       !- Field 7
    Until: 18:00,0.50,       !- Field 9
    Until: 24:00,0.05,       !- Field 11
    For: AllOtherDays,       !- Field 13
    Until: 24:00,0.05;       !- Field 14
  Schedule:Compact,
    ReportSch,               !- Name
    on/off,                  !- Schedule Type Limits Name
    Through: 1/20,           !- Field 1
    For: AllDays,            !- Field 2
    Until:  24:00,0.0,       !- Field 3
    Through: 1/21,           !- Field 5
    For: AllDays,            !- Field 6
    Until:  24:00,1.0,       !- Field 7
    Through: 7/20,           !- Field 9
    For: AllDays,            !- Field 10
    Until:  24:00,0.0,       !- Field 11
    Through: 7/21,           !- Field 13
    For: AllDays,            !- Field 14
    Until:  24:00,1.0,       !- Field 15
    Through: 12/31,          !- Field 17
    For: AllDays,            !- Field 18
    Until:  24:00,0.0;       !- Field 19
  Schedule:Compact,
    HVACAvailSched,          !- Name
    Fraction,                !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,1.0;        !- Field 3
  Schedule:Compact,
    Dual Heating Setpoints,  !- Name
    Temperature,             !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,22.0;       !- Field 3
  Schedule:Compact,
    Dual Cooling Setpoints,  !- Name
    Temperature,             !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,26.6;       !- Field 3
  Schedule:Compact,
    Dual Zone Control Type Sched,  !- Name
    Control Type,            !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,4;          !- Field 3
  Schedule:Compact,
    CyclingFanSchedule,      !- Name
    Any Number,              !- Schedule Type Limits Name
    Through: 12/31,          !- Field 1
    For: AllDays,            !- Field 2
    Until: 24:00,0.0;        !- Field 3
  People,
    LIVING ZONE People,      !- Name
    LIVING ZONE,             !- Zone or ZoneList or Space or SpaceList Name
    HOUSE OCCUPANCY,         !- Number of People Schedule Name
    people,                  !- Number of People Calculation Method
    3.000000,                !- Number of People
    ,                        !- People per Floor Area {person/m2}
    ,                        !- Floor Area per Person {m2/person}
    0.3000000,               !- Fraction Radiant
    ,                        !- Sensible Heat Fraction
    Activity Sch,            !- Activity Level Schedule Name
    3.82E-8,                 !- Carbon Dioxide Generation Rate {m3/s-W}
    ,                        !- Enable ASHRAE 55 Comfort Warnings
    EnclosureAveraged,       !- Mean Radiant Temperature Calculation Type
    ,                        !- Surface Name/Angle Factor List Name
    Work Eff Sch,            !- Work Efficiency Schedule Name
    ClothingInsulationSchedule,  !- Clothing Insulation Calculation Method
    ,                        !- Clothing Insulation Calculation Method Schedule Name
    Clothing Sch,            !- Clothing Insulation Schedule Name
    Air Velo Sch,            !- Air Velocity Schedule Name
    FANGER;                  !- Thermal Comfort Model 1 Type
  Lights,
    LIVING ZONE Lights,      !- Name
    LIVING ZONE,             !- Zone or ZoneList or Space or SpaceList Name
    HOUSE LIGHTING,          !- Schedule Name
    LightingLevel,           !- Design Level Calculation Method
    1000,                    !- Lighting Level {W}
    ,                        !- Watts per Zone Floor Area {W/m2}
    ,                        !- Watts per Person {W/person}
    0,                       !- Return Air Fraction
    0.2000000,               !- Fraction Radiant
    0.2000000,               !- Fraction Visible
    0,                       !- Fraction Replaceable
    GeneralLights;           !- End-Use Subcategory
  ElectricEquipment,
    LIVING ZONE ElecEq,      !- Name
    LIVING ZONE,             !- Zone or ZoneList or Space or SpaceList Name
    INTERMITTENT,            !- Schedule Name
    EquipmentLevel,          !- Design Level Calculation Method
    500,                     !- Design Level {W}
    ,                        !- Watts per Zone Floor Area {W/m2}
    ,                        !- Watts per Person {W/person}
    0,                       !- Fraction Latent
    0.3000000,               !- Fraction Radiant
    0;                       !- Fraction Lost
  Curve:Biquadratic,
    WindACCoolCapFT,         !- Name
    0.942587793,             !- Coefficient1 Constant
    0.009543347,             !- Coefficient2 x
    0.000683770,             !- Coefficient3 x**2
    -0.011042676,            !- Coefficient4 y
    0.000005249,             !- Coefficient5 y**2
    -0.000009720,            !- Coefficient6 x*y
    12.77778,                !- Minimum Value of x
    23.88889,                !- Maximum Value of x
    18.0,                    !- Minimum Value of y
    46.11111,                !- Maximum Value of y
    ,                        !- Minimum Curve Output
    ,                        !- Maximum Curve Output
    Temperature,             !- Input Unit Type for X
    Temperature,             !- Input Unit Type for Y
    Dimensionless;           !- Output Unit Type
  Curve:Biquadratic,
    WindACEIRFT,             !- Name
    0.342414409,             !- Coefficient1 Constant
    0.034885008,             !- Coefficient2 x
    -0.000623700,            !- Coefficient3 x**2
    0.004977216,             !- Coefficient4 y
    0.000437951,             !- Coefficient5 y**2
    -0.000728028,            !- Coefficient6 x*y
    12.77778,                !- Minimum Value of x
    23.88889,                !- Maximum Value of x
    18.0,                    !- Minimum Value of y
    46.11111,                !- Maximum Value of y
    ,                        !- Minimum Curve Output
    ,                        !- Maximum Curve Output
    Temperature,             !- Input Unit Type for X
    Temperature,             !- Input Unit Type for Y
    Dimensionless;           !- Output Unit Type
  Curve:Quadratic,
    HPACCOOLPLFFPLR,         !- Name
    0.85,                    !- Coefficient1 Constant
    0.15,                    !- Coefficient2 x
    0.0,                     !- Coefficient3 x**2
    0.0,                     !- Minimum Value of x
    1.0;                     !- Maximum Value of x
  Curve:Cubic,
    HPACHeatCapFT,           !- Name
    0.758746,                !- Coefficient1 Constant
    0.027626,                !- Coefficient2 x
    0.000148716,             !- Coefficient3 x**2
    0.0000034992,            !- Coefficient4 x**3
    -20.0,                   !- Minimum Value of x
    20.0,                    !- Maximum Value of x
    ,                        !- Minimum Curve Output
    ,                        !- Maximum Curve Output
    Temperature,             !- Input Unit Type for X
    Dimensionless;           !- Output Unit Type
  Curve:Cubic,
    HPACHeatCapFFF,          !- Name
    0.84,                    !- Coefficient1 Constant
    0.16,                    !- Coefficient2 x
    0.0,                     !- Coefficient3 x**2
    0.0,                     !- Coefficient4 x**3
    0.5,                     !- Minimum Value of x
    1.5;                     !- Maximum Value of x
  Curve:Cubic,
    HPACHeatEIRFT,           !- Name
    1.19248,                 !- Coefficient1 Constant
    -0.0300438,              !- Coefficient2 x
    0.00103745,              !- Coefficient3 x**2
    -0.000023328,            !- Coefficient4 x**3
    -20.0,                   !- Minimum Value of x
    20.0,                    !- Maximum Value of x
    ,                        !- Minimum Curve Output
    ,                        !- Maximum Curve Output
    Temperature,             !- Input Unit Type for X
    Dimensionless;           !- Output Unit Type
  Curve:Quadratic,
    HPACHeatEIRFFF,          !- Name
    1.3824,                  !- Coefficient1 Constant
    -0.4336,                 !- Coefficient2 x
    0.0512,                  !- Coefficient3 x**2
    0.0,                     !- Minimum Value of x
    1.0;                     !- Maximum Value of x
  Curve:Quadratic,
    WindACCoolCapFFF,        !- Name
    0.8,                     !- Coefficient1 Constant
    0.2,                     !- Coefficient2 x
    0.0,                     !- Coefficient3 x**2
    0.5,                     !- Minimum Value of x
    1.5;                     !- Maximum Value of x
  Curve:Quadratic,
    WindACEIRFFF,            !- Name
    1.1552,                  !- Coefficient1 Constant
    -0.1808,                 !- Coefficient2 x
    0.0256,                  !- Coefficient3 x**2
    0.5,                     !- Minimum Value of x
    1.5;                     !- Maximum Value of x
  Curve:Quadratic,
    WindACPLFFPLR,           !- Name
    0.85,                    !- Coefficient1 Constant
    0.15,                    !- Coefficient2 x
    0.0,                     !- Coefficient3 x**2
    0.0,                     !- Minimum Value of x
    1.0;                     !- Maximum Value of x
  NodeList,
    ZoneInlets,              !- Name
    Zone Inlet Node;         !- Node 1 Name
  NodeList,
    Supply Air Temp Nodes,   !- Name
    Heating Coil Air Inlet Node,  !- Node 1 Name
    Air Loop Outlet Node;    !- Node 2 Name
  BranchList,
    Air Loop Branches,       !- Name
    Air Loop Main Branch;    !- Branch 1 Name
  Branch,
    Air Loop Main Branch,    !- Name
    ,                        !- Pressure Drop Curve Name
    AirLoopHVAC:UnitaryHeatPump:AirToAir,  !- Component 1 Object Type
    DXAC Heat Pump 1,        !- Component 1 Name
    Air Loop Inlet Node,     !- Component 1 Inlet Node Name
    Air Loop Outlet Node;    !- Component 1 Outlet Node Name
  AirLoopHVAC,
    Typical Residential System,  !- Name
    ,                        !- Controller List Name
    Reheat System 1 Avail List,  !- Availability Manager List Name
    1.18,                    !- Design Supply Air Flow Rate {m3/s}
    Air Loop Branches,       !- Branch List Name
    ,                        !- Connector List Name
    Air Loop Inlet Node,     !- Supply Side Inlet Node Name
    Return Air Mixer Outlet, !- Demand Side Outlet Node Name
    Zone Equipment Inlet Node,  !- Demand Side Inlet Node Names
    Air Loop Outlet Node;    !- Supply Side Outlet Node Names
  Duct:Loss:Conduction,
    Supply trunck,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    Main Link,  !- AirflowNetwork:Distribution:Linkage name
    Zone,                   !- Environment type
    Attic Zone;                     !- Ambient temperature zone
  Duct:Loss:Conduction,
    Supply branch,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ZoneSupplyLink,  !- AirflowNetwork:Distribution:Linkage name
    Zone,                   !- Environment type
    Attic Zone;                     !- Ambient temperature zone
  Duct:Loss:Conduction,
    Return Branch,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ZoneReturnLink,  !- AirflowNetwork:Distribution:Linkage name
    Zone,                   !- Environment type
    Attic Zone;                     !- Ambient temperature zone
  Duct:Loss:Conduction,
    Return trunck,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ReturnMixerLink,  !- AirflowNetwork:Distribution:Linkage name
    Zone,                   !- Environment type
    Attic Zone;                     !- Ambient temperature zone
  Duct:Loss:Leakage,
    Supply leak,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ZoneSupplyLeakLink;  !- AirflowNetwork:Distribution:Linkage name
  Duct:Loss:Leakage,
    Return leak,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ZoneReturnLeakLink;  !- AirflowNetwork:Distribution:Linkage name
  Duct:Loss:Leakage,
    SupplyBranchleak,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    SupplyBranchLeakLink;  !- AirflowNetwork:Distribution:Linkage name
  Duct:Loss:Leakage,
    ReturnBranchleak,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ReturnBranchLeakLink;  !- AirflowNetwork:Distribution:Linkage name
  Duct:Loss:MakeupAir,
    ReturnMakeup,      !- Name
    Typical Residential System,  !- AirLoopHVAC name
    ReturnMakeupLink;  !- AirflowNetwork:Distribution:Linkage name
    )IDF"
        var idf_objects5: String = R"IDF(
  AirflowNetwork:Distribution:Node,
    EquipmentInletNode,      !- Name
    Zone Equipment Inlet Node,  !- Component Name or Node Name
    Other,                   !- Component Object Type or Node Type
    3.0;                     !- Node Height {m}
  AirflowNetwork:Distribution:Node,
    SplitterNode,            !- Name
    ,                        !- Component Name or Node Name
    AirLoopHVAC:ZoneSplitter,!-