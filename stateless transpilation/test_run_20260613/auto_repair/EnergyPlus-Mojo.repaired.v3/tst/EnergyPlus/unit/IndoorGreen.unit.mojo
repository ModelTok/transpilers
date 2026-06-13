from ...EnergyPlus.Construction import *
from ...EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ...EnergyPlus.DataEnvironment import *
from ...EnergyPlus.DataHeatBalSurface import *
from ...EnergyPlus.DataHeatBalance import *
from ...EnergyPlus.DataSurfaces import *
from ...EnergyPlus.DataViewFactorInformation import *
from ...EnergyPlus.ElectricPowerServiceManager import *
from ...EnergyPlus.HeatBalanceIntRadExchange import *
from ...EnergyPlus.HeatBalanceManager import *
from ...EnergyPlus.HeatBalanceSurfaceManager import *
from ...EnergyPlus.IOFiles import *
from ...EnergyPlus.IndoorGreen import *
from ...EnergyPlus.InputProcessing.InputProcessor import *
from ...EnergyPlus.Material import *
from ...EnergyPlus.ScheduleManager import *
from ...EnergyPlus.SimulationManager import *
from ...EnergyPlus.SolarShading import *
from ...EnergyPlus.SurfaceGeometry import *
from ...EnergyPlus.UtilityRoutines import *
from ...EnergyPlus.ZoneTempPredictorCorrector import *
from ...EnergyPlus.Constant import DegToRad, rSecsInHour
from ...Fixtures.EnergyPlusFixture import process_idf, delimited_string
from math import cos, sin

var state: EnergyPlusData

@test
def IndoorGreen_CheckGetInputDataFunction() raises:
    var ErrorsFound: Bool = False
    var IndoorGreenNum: Int = 1
    var idf_objects: String = delimited_string([
        " Zone,",
        "    SPACE1-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0.0,                     !- X Origin {m}",
        "    0.0,                     !- Y Origin {m}",
        "    0.0,                     !- Z Origin {m}",
        "    ,                        !- Type",
        "    ,                        !- Multiplier",
        "    ,                        !- Ceiling Height {m}",
        "    ,                        !- Volume {m3}",
        "    ,                        !- Floor Area {m2}",
        "    ,                        !- Zone Inside Convection Algorithm",
        "    ,                        !- Zone Outside Convection Algorithm",
        "    No;                      !- Part of Total Floor Area",
        " Construction,",
        "    INT-WALL,                !- Name",
        "    GP02;                    !- Outside Layer",
        " Material,",
        "    GP02,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.1016,                  !- Thickness {m}",
        "    0.16,                    !- Conductivity {W/m-K}",
        "    801,                     !- Density {kg/m3}",
        "    837,                     !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.75,                    !- Solar Absorptance",
        "    0.75;                    !- Visible Absorptance",
        "  BuildingSurface:Detailed,",
        "    SPACE1-1SouthPartition,  !-Name",
        "    WALL,                        !-Surface Type",
        "    INT-WALL,                    !-Construction Name",
        "    SPACE1-1,                    !-Zone Name",
        "    ,                            !-Space Name",
        "    Adiabatic,                   !-Outside Boundary Condition",
        "    ,                            !-Outside Boundary Condition Object",
        "    NoSun,                       !-Sun Exposure",
        "    NoWind,                      !-Wind Exposure",
        "    0,                           !-View Factor to Ground",
        "    4,                           !-Number of Vertices",
        "    5, 1.5, 2,                   !- X,Y,Z ==> Vertex 1 {m}",
        "    5, 1.5, 0.0,                 !- X,Y,Z ==> Vertex 2 {m}",
        "    20, 1.5, 0.0,                !- X,Y,Z ==> Vertex 3 {m}",
        "    20, 1.5, 2;                  !- X,Y,Z ==> Vertex 3 {m}",
        "  Schedule:Compact,",
        "    AlwaysOn,                !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    1.0;                     !- Field 4",
        "  Schedule:Compact,",
        "    AlwaysOff,                !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    0.0;                     !- Field 4",
        "  IndoorLivingWall,",
        "    Space1-1IndoorLivingWall, !-Name",
        "    SPACE1-1SouthPartition, !-Surface Name",
        "    AlwaysOn,                   !-Schedule Name",
        "    Penman-Monteith,            !-ET Calculation Method",
        "    LED,                        !-Lighting Method",
        "    AlwaysOff,                  !-LED Intensity Schedule Name",
        "    ,                           !-Daylighting Control Name",
        "    ,                           !-LED - Daylight Targeted Lighting Intensity Schedule Name",
        "    30,                         !- Total Leaf Area {m2}",
        "    32.5,                       !- LED Nominal Intensity {umol_m2s}",
        "    640,                        !- LED Nominal Power {W}",
        "    0.6;                        !- Radiant Fraction of LED Lights",
    ])
    assert process_idf(idf_objects)
    state.init_state(state)
    Material.GetMaterialData(state, ErrorsFound)
    assert not ErrorsFound
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    assert not ErrorsFound
    HeatBalanceManager.GetZoneData(state, ErrorsFound)
    assert not ErrorsFound
    state.dataSurfaceGeometry.CosZoneRelNorth = [0.0]
    state.dataSurfaceGeometry.SinZoneRelNorth = [0.0]
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = cos(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = sin(-state.dataHeatBal.Zone[0].RelNorth * DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, ErrorsFound)
    assert not ErrorsFound
    state.dataHVACGlobal.TimeStepSys = 1
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * rSecsInHour
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.MinutesInTimeStep = 60 / state.dataGlobal.TimeStepsInHour
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.HourOfDay = 1
    state.dataEnvrn.DayOfWeek = 1
    state.dataEnvrn.DayOfYear_Schedule = 1
    Sched.UpdateScheduleVals(state)
    IndoorGreen.GetIndoorGreenInput(state, ErrorsFound)
    assert not ErrorsFound
    var thisindoorgreen = state.dataIndoorGreen.indoorGreens[IndoorGreenNum - 1]
    assert thisindoorgreen.LeafArea == 30.0
    assert int(thisindoorgreen.lightingMethod) == int(IndoorGreen.LightingMethod.LED)
    assert int(thisindoorgreen.etCalculationMethod) == int(IndoorGreen.ETCalculationMethod.PenmanMonteith)

@test
def IndoorGreen_CheckETFunction() raises:
    var IndoorGreenNum: Int = 1
    var ZonePreTemp: Float64 = 0.0
    var ZonePreHum: Float64 = 0.001
    var LAI: Float64 = 1.0
    var SwithF: Float64 = 1.0
    state.dataIndoorGreen.indoorGreens = [IndoorGreenStruct() for _ in range(IndoorGreenNum)]
    var thisindoorgreen = state.dataIndoorGreen.indoorGreens[IndoorGreenNum - 1]
    thisindoorgreen.ZCO2 = 400.0
    thisindoorgreen.ZPPFD = 0.0
    thisindoorgreen.ZVPD = 2000.0
    thisindoorgreen.ETRate = IndoorGreen.ETBaseFunction(state, ZonePreTemp, ZonePreHum, thisindoorgreen.ZPPFD, thisindoorgreen.ZVPD, LAI, SwithF)
    assert thisindoorgreen.ETRate == 0.0