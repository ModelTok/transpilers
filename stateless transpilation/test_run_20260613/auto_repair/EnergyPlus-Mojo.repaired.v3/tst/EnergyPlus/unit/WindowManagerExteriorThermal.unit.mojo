from testing import expect_near, expect_eq, expect_enum_eq
from EnergyPlus.Construction import Construct, ConstructionData
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataSurfaces import SurfaceData, WinShadingType, NfrcVisionType, SurfWinShadingFlag, SurfWinActiveShadedConstruction
from EnergyPlus.DataSystemVariables import DataSystemVariables
from EnergyPlus.HeatBalanceManager import GetProjectControlData, SetPreConstructionInputParameters, GetFrameAndDividerData, GetConstructData, GetZoneData
from EnergyPlus.Material import Material, MaterialGlass, MaterialShade, MaterialBlind, GetMaterialData
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SimulationManager import SimulationManager
from EnergyPlus.SolarShading import AllocateModuleArrays, DetermineShadowingCombinations, InitSolarCalculations, SkyDifSolarShading
from EnergyPlus.SurfaceGeometry import GetGeometryParameters, GetSurfaceData, SetupZoneGeometry
from EnergyPlus.WindowManager import WindowManager
from WCEMultiLayerOptics import WCEMultiLayerOptics
from WCETarcog import WCETarcog
from EnergyPlus.WindowManagerExteriorThermal import CWCEHeatTransferFactory, GetWindowAssemblyNfrcForReport
from EnergyPlus.DataHeatBalance import Shadowing, DataHeatBalance
from EnergyPlus.Constant import DegToRad
from EnergyPlus.Util import FindItemInList
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string

# Global state for tests (mimicking the fixture's state pointer)
var state: EnergyPlusData = EnergyPlusData()

# Helper function to initialize common test data (duplicated per test rule)
def init_surface_and_construct(numSurf: Int, numCons: Int, numLayers: Int, materialOutside: Int, materialInside: Int):
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)

def test_overallUfactorFromFilmsAndCond():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    var numCons: Int = 1
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    var numLayers: Int = 2
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialGlass())
    s_mat.materials.append(MaterialGlass())
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, numCons)
    var hIntConvCoeff: Float64 = 0.0
    var hExtConvCoeff: Float64 = 0.0
    var conductance: Float64 = 0.0
    var uvalue: Float64 = aFactory.overallUfactorFromFilmsAndCond(conductance, hIntConvCoeff, hExtConvCoeff)
    expect_near(uvalue, 0.0, 0.0001)
    conductance = 0.5
    uvalue = aFactory.overallUfactorFromFilmsAndCond(conductance, hIntConvCoeff, hExtConvCoeff)
    expect_near(uvalue, 0.0, 0.0001)
    hIntConvCoeff = 1.0
    hExtConvCoeff = 1.0
    conductance = 1.0
    uvalue = aFactory.overallUfactorFromFilmsAndCond(conductance, hIntConvCoeff, hExtConvCoeff)
    expect_near(uvalue, 0.33333, 0.0001)
    hIntConvCoeff = 8.0
    hExtConvCoeff = 30.0
    conductance = 2.326112
    uvalue = aFactory.overallUfactorFromFilmsAndCond(conductance, hIntConvCoeff, hExtConvCoeff)
    expect_near(uvalue, 1.700, 0.001)
    hIntConvCoeff = 30.0
    hExtConvCoeff = 8.0
    conductance = 3.543645
    uvalue = aFactory.overallUfactorFromFilmsAndCond(conductance, hIntConvCoeff, hExtConvCoeff)
    expect_near(uvalue, 2.270, 0.001)

def test_getOutdoorNfrc():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    var numCons: Int = 1
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    var numLayers: Int = 2
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)
    var matOutside = MaterialGlass()
    s_mat.materials.append(matOutside)
    var matInside = MaterialGlass()
    s_mat.materials.append(matInside)
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, numCons)
    var indoor = aFactory.getOutdoorNfrc(true)
    expect_near(indoor.getAirTemperature(), 305.15, 0.01)
    expect_near(indoor.getDirectSolarRadiation(), 783.0, 0.01)
    indoor = aFactory.getOutdoorNfrc(false)
    expect_near(indoor.getAirTemperature(), 255.15, 0.01)
    expect_near(indoor.getDirectSolarRadiation(), 0.0, 0.01)

def test_getIndoorNfrc():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    var numCons: Int = 1
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    var numLayers: Int = 2
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialGlass())
    s_mat.materials.append(MaterialGlass())
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, numCons)
    var indoor = aFactory.getIndoorNfrc(true)
    expect_near(indoor.getAirTemperature(), 297.15, 0.01)
    indoor = aFactory.getIndoorNfrc(false)
    expect_near(indoor.getAirTemperature(), 294.15, 0.01)

def test_getShadeType():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    var numCons: Int = 2
    var simpleCons: Int = 1
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = simpleCons
    var numLayers: Int = 3
    state.dataConstruction.Construct[simpleCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[simpleCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[simpleCons-1].TotGlassLayers = numLayers - 1
    state.dataConstruction.Construct[simpleCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[simpleCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[simpleCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialGlass())
    s_mat.materials.append(MaterialGlass())
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, simpleCons)
    var typeOfShade = aFactory.getShadeType(state, simpleCons)
    expect_enum_eq(typeOfShade, WinShadingType.NoShade)
    s_mat.materials[materialOutside-1] = MaterialShade()
    typeOfShade = aFactory.getShadeType(state, simpleCons)
    expect_enum_eq(typeOfShade, WinShadingType.ExtShade)
    s_mat.materials[materialOutside-1] = MaterialBlind()
    typeOfShade = aFactory.getShadeType(state, simpleCons)
    expect_enum_eq(typeOfShade, WinShadingType.ExtBlind)
    s_mat.materials[materialOutside-1] = MaterialGlass()
    s_mat.materials[materialInside-1] = MaterialShade()
    typeOfShade = aFactory.getShadeType(state, simpleCons)
    expect_enum_eq(typeOfShade, WinShadingType.IntShade)
    s_mat.materials[materialInside-1] = MaterialBlind()
    typeOfShade = aFactory.getShadeType(state, simpleCons)
    expect_enum_eq(typeOfShade, WinShadingType.IntBlind)
    s_mat.materials[materialInside-1] = MaterialGlass()
    var betweenCons: Int = 2
    state.dataSurface.Surface[numSurf-1].Construction = betweenCons
    numLayers = 4
    var shadeLayer: Int = 3
    state.dataConstruction.Construct[betweenCons-1].LayerPoint.allocate(numLayers)
    var materialShade: Int = 3
    state.dataConstruction.Construct[betweenCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[betweenCons-1].TotGlassLayers = 2
    state.dataConstruction.Construct[betweenCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[betweenCons-1].LayerPoint[shadeLayer-1] = materialShade
    state.dataConstruction.Construct[betweenCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[betweenCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialShade())
    typeOfShade = aFactory.getShadeType(state, betweenCons)
    expect_enum_eq(typeOfShade, WinShadingType.BGShade)
    s_mat.materials[materialShade-1] = MaterialBlind()
    typeOfShade = aFactory.getShadeType(state, betweenCons)
    expect_enum_eq(typeOfShade, WinShadingType.BGBlind)

def test_getActiveConstructionNumber():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    state.dataSurface.SurfWinShadingFlag.allocate(numSurf)
    state.dataSurface.SurfWinActiveShadedConstruction.allocate(numSurf)
    var numCons: Int = 2
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    var numLayers: Int = 2
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialGlass())
    s_mat.materials.append(MaterialGlass())
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, numCons)
    var surface = state.dataSurface.Surface[numSurf-1]
    state.dataSurface.SurfWinShadingFlag[numSurf-1] = WinShadingType.ExtBlind
    state.dataSurface.SurfWinActiveShadedConstruction[numSurf-1] = 7
    var consSelected: Int = aFactory.getActiveConstructionNumber(state, surface, numSurf)
    expect_eq(consSelected, 7)
    state.dataSurface.SurfWinShadingFlag[numSurf-1] = WinShadingType.NoShade
    consSelected = aFactory.getActiveConstructionNumber(state, surface, numSurf)
    expect_eq(consSelected, numCons)

def test_getIGU():
    var s_mat = state.dataMaterial
    var numSurf: Int = 1
    state.dataSurface.Surface.allocate(numSurf)
    state.dataSurface.SurfaceWindow.allocate(numSurf)
    var numCons: Int = 1
    state.dataConstruction.Construct.allocate(numCons)
    state.dataSurface.Surface[numSurf-1].Construction = numCons
    var numLayers: Int = 2
    state.dataConstruction.Construct[numCons-1].LayerPoint.allocate(numLayers)
    var materialOutside: Int = 1
    var materialInside: Int = 2
    state.dataConstruction.Construct[numCons-1].TotLayers = numLayers
    state.dataConstruction.Construct[numCons-1].LayerPoint[0] = materialOutside
    state.dataConstruction.Construct[numCons-1].LayerPoint[numLayers-1] = materialInside
    state.dataConstruction.Construct[numCons-1].AbsDiff.allocate(2)
    s_mat.materials.append(MaterialGlass())
    s_mat.materials.append(MaterialGlass())
    var aFactory = CWCEHeatTransferFactory(state, state.dataSurface.Surface[numSurf-1], numSurf, numCons)
    var width: Float64 = 10.0
    var height: Float64 = 15.0
    var tilt: Float64 = 90.0
    var igu = aFactory.getIGU(width, height, tilt)
    expect_near(igu.getTilt(), 90.0, 0.01)
    expect_near(igu.getHeight(), 15.0, 0.01)
    expect_near(igu.getWidth(), 10.0, 0.01)

def test_GetWindowAssemblyNfrcForReport_withIDF():
    var idf_objects: String = delimited_string({
        "  Building,",
        "    DemoFDT,                 !- Name",
        "    0,                       !- North Axis {deg}",
        "    Suburbs,                 !- Terrain",
        "    3.9999999E-02,           !- Loads Convergence Tolerance Value",
        "    4.0000002E-03,           !- Temperature Convergence Tolerance Value {deltaC}",
        "    FullExterior,            !- Solar Distribution",
        "    ,                        !- Maximum Number of Warmup Days",
        "    6;                       !- Minimum Number of Warmup Days",
        "  ShadowCalculation,",
        "    PolygonClipping,         !- Shading Calculation Method",
        "    Timestep,                !- Shading Calculation Update Frequency Method",
        "    ,                        !- Shading Calculation Update Frequency",
        "    ,                        !- Maximum Figures in Shadow Overlap Calculations",
        "    ,                        !- Polygon Clipping Algorithm",
        "    ,                        !- Pixel Counting Resolution",
        "    DetailedSkyDiffuseModeling;  !- Sky Diffuse Modeling Algorithm",
        "  SurfaceConvectionAlgorithm:Inside,TARP;",
        "  SurfaceConvectionAlgorithm:Outside,TARP;",
        "  HeatBalanceAlgorithm,ConductionTransferFunction;",
        "  Timestep,6;",
        "  RunPeriod,",
        "    RP1,                     !- Name",
        "    1,                       !- Begin Month",
        "    1,                       !- Begin Day of Month",
        "    ,                        !- Begin Year",
        "    12,                      !- End Month",
        "    31,                      !- End Day of Month",
        "    ,                        !- End Year",
        "    ,                        !- Day of Week for Start Day",
        "    ,                        !- Use Weather File Holidays and Special Days",
        "    ,                        !- Use Weather File Daylight Saving Period",
        "    ,                        !- Apply Weekend Holiday Rule",
        "    ,                        !- Use Weather File Rain Indicators",
        "    ;                        !- Use Weather File Snow Indicators",
        "  ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    Continuous;              !- Numeric Type",
        "  ScheduleTypeLimits,",
        "    ON/OFF,                  !- Name",
        "    0,                       !- Lower Limit Value",
        "    1,                       !- Upper Limit Value",
        "    Discrete;                !- Numeric Type",
        "  Schedule:Compact,",
        "    SunShading,              !- Name",
        "    ON/OFF,                  !- Schedule Type Limits Name",
        "    Through: 4/30,           !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    until: 24:00,1,          !- Field 3",
        "    Through: 10/31,          !- Field 5",
        "    For: AllDays,            !- Field 6",
        "    until: 24:00,0,          !- Field 7",
        "    Through: 12/31,          !- Field 9",
        "    For: AllDays,            !- Field 10",
        "    until: 24:00,1;          !- Field 11",
        "  Material,",
        "    A2 - 4 IN DENSE FACE BRICK,  !- Name",
        "    Rough,                   !- Roughness",
        "    0.1014984,               !- Thickness {m}",
        "    1.245296,                !- Conductivity {W/m-K}",
        "    2082.400,                !- Density {kg/m3}",
        "    920.4800,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.9300000,               !- Solar Absorptance",
        "    0.9300000;               !- Visible Absorptance",
        "  Material,",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD,  !- Name",
        "    Smooth,                  !- Roughness",
        "    1.9050000E-02,           !- Thickness {m}",
        "    0.7264224,               !- Conductivity {W/m-K}",
        "    1601.846,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.9200000,               !- Solar Absorptance",
        "    0.9200000;               !- Visible Absorptance",
        "  Material,",
        "    E2 - 1 / 2 IN SLAG OR STONE,  !- Name",
        "    Rough,                   !- Roughness",
        "    1.2710161E-02,           !- Thickness {m}",
        "    1.435549,                !- Conductivity {W/m-K}",
        "    881.0155,                !- Density {kg/m3}",
        "    1673.600,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.5500000,               !- Solar Absorptance",
        "    0.5500000;               !- Visible Absorptance",
        "  Material,",
        "    C12 - 2 IN HW CONCRETE,  !- Name",
        "    MediumRough,             !- Roughness",
        "    5.0901599E-02,           !- Thickness {m}",
        "    1.729577,                !- Conductivity {W/m-K}",
        "    2242.585,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.6500000,               !- Solar Absorptance",
        "    0.6500000;               !- Visible Absorptance",
        "  Material:NoMass,",
        "    R13LAYER,                !- Name",
        "    Rough,                   !- Roughness",
        "    2.290965,                !- Thermal Resistance {m2-K/W}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  WindowMaterial:Glazing,",
        "    GLASS - CLEAR PLATE 1 / 4 IN,  !- Name",
        "    SpectralAverage,         !- Optical Data Type",
        "    ,                        !- Window Glass Spectral Data Set Name",
        "    0.006,                   !- Thickness {m}",
        "    0.80,                    !- Solar Transmittance at Normal Incidence",
        "    0.10,                    !- Front Side Solar Reflectance at Normal Incidence",
        "    0.10,                    !- Back Side Solar Reflectance at Normal Incidence",
        "    0.80,                    !- Visible Transmittance at Normal Incidence",
        "    0.10,                    !- Front Side Visible Reflectance at Normal Incidence",
        "    0.10,                    !- Back Side Visible Reflectance at Normal Incidence",
        "    0.0,                     !- Infrared Transmittance at Normal Incidence",
        "    0.84,                    !- Front Side Infrared Hemispherical Emissivity",
        "    0.84,                    !- Back Side Infrared Hemispherical Emissivity",
        "    0.9;                     !- Conductivity {W/m-K}",
        "  WindowMaterial:Gas,",
        "    AIRGAP,                  !- Name",
        "    AIR,                     !- Gas Type",
        "    0.0125;                  !- Thickness {m}",
        "  Construction,",
        "    R13WALL,                 !- Name",
        "    R13LAYER;                !- Outside Layer",
        "  Construction,",
        "    EXTWALL09,               !- Name",
        "    A2 - 4 IN DENSE FACE BRICK,  !- Outside Layer",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 4",
        "  Construction,",
        "    INTERIOR,                !- Name",
        "    C12 - 2 IN HW CONCRETE;  !- Layer 4",
        "  Construction,",
        "    SLAB FLOOR,              !- Name",
        "    C12 - 2 IN HW CONCRETE;  !- Layer 4",
        "  Construction,",
        "    ROOF31,                  !- Name",
        "    E2 - 1 / 2 IN SLAG OR STONE,  !- Outside Layer",
        "    C12 - 2 IN HW CONCRETE;  !- Layer 4",
        "  Construction,",
        "    DOUBLE PANE HW WINDOW,   !- Name",
        "    GLASS - CLEAR PLATE 1 / 4 IN,  !- Outside Layer",
        "    AIRGAP,                  !- Layer 2",
        "    GLASS - CLEAR PLATE 1 / 4 IN;  !- Layer 3",
        "  Construction,",
        "    PARTITION02,             !- Name",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD,  !- Outside Layer",
        "    C12 - 2 IN HW CONCRETE,  !- Layer 4",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 3",
        "  Construction,",
        "    single PANE HW WINDOW,   !- Name",
        "    GLASS - CLEAR PLATE 1 / 4 IN;  !- Outside Layer",
        "  Construction,",
        "    EXTWALLdemo,             !- Name",
        "    A2 - 4 IN DENSE FACE BRICK,  !- Outside Layer",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 4",
        "  GlobalGeometryRules,",
        "    UpperLeftCorner,         !- Starting Vertex Position",
        "    Counterclockwise,        !- Vertex Entry Direction",
        "    Relative;                !- Coordinate System",
        "  Zone,",
        "    ZONE ONE,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    0,                       !- Ceiling Height {m}",
        "    0;                       !- Volume {m3}",
        "  BuildingSurface:Detailed,",
        "    Zn001:Wall-North,        !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALLdemo,             !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    5,5,3,  !- X,Y,Z ==> Vertex 1 {m}",
        "    5,5,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    -5,5,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    -5,5,3;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Zn001:Wall-East,         !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL09,               !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    5,-5,3,  !- X,Y,Z ==> Vertex 1 {m}",
        "    5,-5,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    5,5,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    5,5,3;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Zn001:Wall-South,        !- Name",
        "    Wall,                    !- Surface Type",
        "    R13WALL,                 !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    -5,-5,3,  !- X,Y,Z ==> Vertex 1 {m}",
        "    -5,-5,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    5,-5,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    5,-5,3;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Zn001:Wall-West,         !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL09,               !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    -5,5,3,  !- X,Y,Z ==> Vertex 1 {m}",
        "    -5,5,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    -5,-5,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    -5,-5,3;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Zn001:roof,              !- Name",
        "    Roof,                    !- Surface Type",
        "    ROOF31,                  !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.0000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    -5,-5,3,  !- X,Y,Z ==> Vertex 1 {m}",
        "    5,-5,3,  !- X,Y,Z ==> Vertex 2 {m}",
        "    5,5,3,  !- X,Y,Z ==> Vertex 3 {m}",
        "    -5,5,3;  !- X,Y,Z ==> Vertex 4 {m}",
        "  BuildingSurface:Detailed,",
        "    Zn001:floor,             !- Name",
        "    Floor,                   !- Surface Type",
        "    SLAB FLOOR,              !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.0000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    -5,5,0,  !- X,Y,Z ==> Vertex 1 {m}",
        "    5,5,0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    5,-5,0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    -5,-5,0;  !- X,Y,Z ==> Vertex 4 {m}",
        "  FenestrationSurface:Detailed,",
        "    Zn001:Wall-South:Win001, !- Name",
        "    Window,                  !- Surface Type",
        "    DOUBLE PANE HW WINDOW,   !- Construction Name",
        "    Zn001:Wall-South,        !- Building Surface Name",
        "    ,                        !- Outside Boundary Condition Object",
        "    0.5000000,               !- View Factor to Ground",
        "    TestFrameAndDivider,     !- Frame and Divider Name",
        "    1.0,                     !- Multiplier",
        "    4,                       !- Number of Vertices",
        "    -3,-5,2.5,  !- X,Y,Z ==> Vertex 1 {m}",
        "    -3,-5,0.5,  !- X,Y,Z ==> Vertex 2 {m}",
        "    3,-5,0.5,  !- X,Y,Z ==> Vertex 3 {m}",
        "    3,-5,2.5;  !- X,Y,Z ==> Vertex 4 {m}",
        "  WindowProperty:FrameAndDivider,",
        "    TestFrameAndDivider,     !- Name",
        "    0.05,                    !- Frame Width {m}",
        "    0.05,                    !- Frame Outside Projection {m}",
        "    0.05,                    !- Frame Inside Projection {m}",
        "    5.0,                     !- Frame Conductance {W/m2-K}",
        "    1.2,                     !- Ratio of Frame-Edge Glass Conductance to Center-Of-Gl",
        "    0.8,                     !- Frame Solar Absorptance",
        "    0.8,                     !- Frame Visible Absorptance",
        "    0.9,                     !- Frame Thermal Hemispherical Emissivity",
        "    DividedLite,             !- Divider Type",
        "    0.02,                    !- Divider Width {m}",
        "    2,                       !- Number of Horizontal Dividers",
        "    2,                       !- Number of Vertical Dividers",
        "    0.02,                    !- Divider Outside Projection {m}",
        "    0.02,                    !- Divider Inside Projection {m}",
        "    5.0,                     !- Divider Conductance {W/m2-K}",
        "    1.2,                     !- Ratio of Divider-Edge Glass Conductance to Center-Of-",
        "    0.8,                     !- Divider Solar Absorptance",
        "    0.8,                     !- Divider Visible Absorptance",
        "    0.9;                     !- Divider Thermal Hemispherical Emissivity",
        "  Shading:Zone:Detailed,",
        "    Zn001:Wall-South:Shade001,  !- Name",
        "    Zn001:Wall-South,        !- Base Surface Name",
        "    SunShading,              !- Transmittance Schedule Name",
        "    4,                       !- Number of Vertices",
        "    -3,-5,2.5,  !- X,Y,Z ==> Vertex 1 {m}",
        "    -3,-6,2.5,  !- X,Y,Z ==> Vertex 2 {m}",
        "    3,-6,2.5,  !- X,Y,Z ==> Vertex 3 {m}",
        "    3,-5,2.5;  !- X,Y,Z ==> Vertex 4 {m}",
        "  ShadingProperty:Reflectance,",
        "    Zn001:Wall-South:Shade001,  !- Shading Surface Name",
        "    0.2,                     !- Diffuse Solar Reflectance of Unglazed Part of Shading",
        "    0.2;                     !- Diffuse Visible Reflectance of Unglazed Part of Shading",
    })
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    var FoundError: Bool = false
    HeatBalanceManager.GetProjectControlData(state, FoundError)
    expect_false(FoundError)
    HeatBalanceManager.SetPreConstructionInputParameters(state)
    Material.GetMaterialData(state, FoundError)
    expect_false(FoundError)
    HeatBalanceManager.GetFrameAndDividerData(state)
    HeatBalanceManager.GetConstructData(state, FoundError)
    expect_false(FoundError)
    HeatBalanceManager.GetZoneData(state, FoundError)
    expect_false(FoundError)
    SurfaceGeometry.GetGeometryParameters(state, FoundError)
    expect_false(FoundError)
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = ( -state.dataHeatBal.Zone[0].RelNorth * DegToRad).cos()
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = ( -state.dataHeatBal.Zone[0].RelNorth * DegToRad).sin()
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, FoundError)
    expect_false(FoundError)
    SurfaceGeometry.SetupZoneGeometry(state, FoundError)
    expect_false(FoundError)
    SolarShading.AllocateModuleArrays(state)
    SolarShading.DetermineShadowingCombinations(state)
    state.dataEnvrn.DayOfYear_Schedule = 168
    state.dataEnvrn.DayOfWeek = 6
    state.dataGlobal.TimeStep = 4
    state.dataGlobal.HourOfDay = 9
    state.dataSurface.ShadingTransmittanceVaries = true
    state.dataSysVars.DetailedSkyDiffuseAlgorithm = true
    state.dataHeatBal.SolarDistribution = Shadowing.FullExterior
    state.dataSolarShading.CalcSkyDifShading = true
    SolarShading.InitSolarCalculations(state)
    SolarShading.SkyDifSolarShading(state)
    state.dataSolarShading.CalcSkyDifShading = false
    var uValueRep: Float64 = 0.0
    var shgcRep: Float64 = 0.0
    var vtRep: Float64 = 0.0
    var windowSurfNum: Int = Util.FindItemInList("ZN001:WALL-SOUTH:WIN001", state.dataSurface.Surface)
    expect_true(windowSurfNum > 0)
    var constructNum: Int = Util.FindItemInList("DOUBLE PANE HW WINDOW", state.dataConstruction.Construct)
    expect_true(constructNum > 0)
    GetWindowAssemblyNfrcForReport(
        state, windowSurfNum, constructNum, 1.0, 0.5, NfrcVisionType.DualVertical, uValueRep, shgcRep, vtRep)
    expect_near(uValueRep, 3.24, 0.01)
    expect_near(shgcRep, 0.029, 0.001)
    expect_near(vtRep, 0.0, 0.1)
    GetWindowAssemblyNfrcForReport(
        state, windowSurfNum, constructNum, 1.0, 0.5, NfrcVisionType.DualHorizontal, uValueRep, shgcRep, vtRep)
    expect_near(uValueRep, 3.07, 0.01)
    expect_near(shgcRep, 0.024, 0.001)
    expect_near(vtRep, 0.0, 0.1)
    GetWindowAssemblyNfrcForReport(state, windowSurfNum, constructNum, 1.0, 0.5, NfrcVisionType.Single, uValueRep, shgcRep, vtRep)
    expect_near(uValueRep, 3.11, 0.01)
    expect_near(shgcRep, 0.021, 0.001)
    expect_near(vtRep, 0.0, 0.1)