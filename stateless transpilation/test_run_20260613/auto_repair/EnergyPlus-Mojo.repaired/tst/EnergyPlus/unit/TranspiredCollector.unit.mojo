from EnergyPlus.ConvectionCoefficients import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.GeneralRoutines import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Material import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.TranspiredCollector import *
from Fixtures.EnergyPlusFixture import *  # contains process_idf, delimited_string etc.

from Constant import DegToRad  # exact name

def test_TranspiredCollectors_InitTranspiredCollectorTest():
    var ErrorsFound = False
    var UTSCNum = 1
    var idf_objects = delimited_string([
        "  Zone,",
        "    ZN1_S_Space_1,           !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0.000,                   !- X Origin {m}",
        "    0.000,                   !- Y Origin {m}",
        "    0.000,                   !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    3.000,                   !- Ceiling Height {m}",
        "    644.812;                 !- Volume {m3}",
        "  Material,",
        "    4 in Prefab Stone Wall,  !- Name",
        "    Smooth,                  !- Roughness",
        "    0.1016,                  !- Thickness {m}",
        "    0.858,                   !- Conductivity {W/m-K}",
        "    1968,                    !- Density {kg/m3}",
        "    836.8,                   !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.7,                     !- Solar Absorptance",
        "    0.7;                     !- Visible Absorptance",
        "  Construction,",
        "    Ext-wall,                !- Name",
        "    4 in Prefab Stone Wall;  !- Outside Layer",
        "  BuildingSurface:Detailed,",
        "    ZN1_ExtWallSouth_1,      !- Name",
        "    wall,                    !- Surface Type",
        "    Ext-Wall,                !- Construction Name",
        "    ZN1_S_Space_1,           !- Zone Name",
        "    ,                        !- Space Name",
        "    OtherSideConditionsModel,!- Outside Boundary Condition",
        "    UTSC OSCM 1,             !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.500,                   !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.000,0.000,3.000,       !- X,Y,Z ==> Vertex 1 {m}",
        "    0.000,0.000,1.500,       !- X,Y,Z ==> Vertex 2 {m}",
        "    50.000,0.000,1.500,      !- X,Y,Z ==> Vertex 3 {m}",
        "    50.000,0.000,3.000;      !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    ZN1_ExtWallSouth_2,      !- Name",
        "    wall,                    !- Surface Type",
        "    Ext-Wall,                !- Construction Name",
        "    ZN1_S_Space_1,           !- Zone Name",
        "    ,                        !- Space Name",
        "    OtherSideConditionsModel,!- Outside Boundary Condition",
        "    UTSC OSCM 1,             !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.500,                   !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.000,0.000,1.500,       !- X,Y,Z ==> Vertex 1 {m}",
        "    0.000,0.000,0.000,       !- X,Y,Z ==> Vertex 2 {m}",
        "    50.000,0.000,0.000,      !- X,Y,Z ==> Vertex 3 {m}",
        "    50.000,0.000,1.500;      !- X,Y,Z ==> Vertex 4 {m}",
        "  SurfaceProperty:OtherSideConditionsModel,",
        "    UTSC OSCM 1,             !- Name",
        "    GapConvectionRadiation;  !- Type of Modeling",
        "  Schedule:Compact,",
        "    HeatingAvailSched,       !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,1.0;        !- Field 3",
        "  Schedule:Compact,",
        "    ShopFreeHeatingSetpoints,!- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,21.0;       !- Field 3",
        "  SolarCollector:UnglazedTranspired,",
        "    OFFICE OA UTSC,          !- Name",
        "    UTSC OSCM 1,             !- Boundary Conditions Model Name",
        "    HeatingAvailSched,       !- Availability Schedule Name",
        "    InletNodeName,           !- Inlet Node Name",
        "    OutletNodeName,          !- Outlet Node Name",
        "    OutletNodeName,          !- Setpoint Node Name",
        "    ZN1_S_Space_1,           !- Zone Node Name",
        "    ShopFreeHeatingSetpoints,!- Free Heating Setpoint Schedule Name",
        "    0.001,                   !- Diameter of Perforations in Collector {m}",
        "    0.020,                   !- Distance Between Perforations in Collector {m}",
        "    0.9,                     !- Thermal Emissivity of Collector Surface {dimensionless}",
        "    0.9,                     !- Solar Absorbtivity of Collector Surface {dimensionless}",
        "    4.0,                     !- Effective Overall Height of Collector",
        "    0.1,                     !- Effective Gap Thickness of Plenum Behind Collector {m}",
        "    5.0,                     !- Effective Cross Section Area of Plenum Behind Collector {m2}",
        "    Triangle,                !- Hole Layout Pattern for Pitch",
        "    Kutscher1994,            !- Heat Exchange Effectiveness Correlation",
        "    1.165,                   !- Ratio of Actual Collector Surface Area to Projected Surface Area {dimensionless}",
        "    MediumRough,             !- Roughness of Collector",
        "    0.001,                   !- Collector Thickness {m}",
        "    0.25,                    !- Effectiveness for Perforations with Respect to Wind {dimensionless}",
        "    0.5,                     !- Discharge Coefficient for Openings with Respect to Buoyancy Driven Flow {dimensionless}",
        "    ZN1_ExtWallSouth_1,      !- Surface 1 Name",
        "    ZN1_ExtWallSouth_2;      !- Surface 2 Name",
    ])
    assert process_idf(idf_objects), "process_idf failed"
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    GetProjectControlData(state, ErrorsFound) // read project control data
    assert not ErrorsFound
    GetZoneData(state, ErrorsFound)
    GetZoneEquipmentData(state)
    Material.GetMaterialData(state, ErrorsFound) // read material data
    assert not ErrorsFound                      // expect no errors
    GetConstructData(state, ErrorsFound) // read construction data
    assert not ErrorsFound              // expect no errors
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = Math.cos(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = Math.sin(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    GetSurfaceData(state, ErrorsFound) // setup zone geometry and get zone data
    assert not ErrorsFound            // expect no errors
    state.dataEnvrn.OutDryBulbTemp = 20.0
    state.dataEnvrn.OutWetBulbTemp = 15.0
    SetSurfaceOutBulbTempAt(state)
    GetTranspiredCollectorInput(state)
    assert not ErrorsFound
    state.dataGlobal.BeginEnvrnFlag = true
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.SkyTemp = 24.0
    state.dataEnvrn.IsRain = false
    InitTranspiredCollector(state, UTSCNum)
    # Note: original uses 1-based indexing, we convert to 0-based
    # UTSCNum is 1 -> index 0
    assert state.dataTranspiredCollector.UTSC[0].Tcoll == 22.0, "Tcoll mismatch"
    assert state.dataTranspiredCollector.UTSC[0].Tplen == 22.5, "Tplen mismatch"
    assert Math.abs(state.dataTranspiredCollector.UTSC[0].TairHX - 19.990) < 0.001, "TairHX mismatch"