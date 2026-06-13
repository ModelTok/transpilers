from testing import *
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import *
from DataHeatBalSurface import *
from DataHeatBalance import *
from DataSurfaces import *
from HeatBalanceManager import *
from HeatBalanceSurfaceManager import *
from IOFiles import *
from Material import *
from ScheduleManager import *
from SurfaceGeometry import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

@test
def test_HeatBalanceMovableInsulation_EvalOutsideMovableInsulation():
    var state = EnergyPlusData()
    state.init_state(state)
    var s_mat = state.dataMaterial
    var SurfNum: Int = 1
    state.dataSurface.Surface.allocate(SurfNum)
    state.dataSurface.extMovInsuls.allocate(SurfNum)
    state.dataSurface.extMovInsuls[0].sched = Sched.GetScheduleAlwaysOn(state)
    state.dataSurface.extMovInsuls[0].matNum = 1
    state.dataHeatBalSurf.SurfAbsSolarExt.allocate(SurfNum)
    state.dataHeatBalSurf.SurfAbsThermalExt.allocate(SurfNum)
    state.dataHeatBalSurf.SurfRoughnessExt.allocate(SurfNum)
    state.dataSurface.extMovInsuls[0].present = true
    state.dataSurface.extMovInsulSurfNums.push_back(SurfNum)
    var mat1 = MaterialShade()
    s_mat.materials.push_back(mat1)
    mat1.Resistance = 1.25
    mat1.Roughness = Material.SurfaceRoughness.VeryRough
    mat1.group = Material.Group.Regular
    mat1.AbsorpSolar = 0.75
    mat1.AbsorpThermal = 0.75
    mat1.Trans = 0.25
    mat1.ReflectSolBeamFront = 0.20
    state.dataHeatBal.Zone.allocate(1)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.Zone[0].spaceIndexes.emplace_back(1)
    state.dataHeatBal.space[0].OpaqOrIntMassSurfaceFirst = 1
    state.dataHeatBal.space[0].OpaqOrIntMassSurfaceLast = 1
    state.dataHeatBalSurf.SurfAbsSolarExt[0] = 0.0
    HeatBalanceSurfaceManager.EvalOutsideMovableInsulation(state)
    assert_eq(0.75, state.dataHeatBalSurf.SurfAbsSolarExt[0])
    assert_eq(0.8, state.dataSurface.extMovInsuls[0].H)
    assert_eq(Material.SurfaceRoughness.VeryRough, state.dataHeatBalSurf.SurfRoughnessExt[0])
    assert_eq(0.75, state.dataHeatBalSurf.SurfAbsThermalExt[0])
    s_mat.materials.clear()
    state.dataHeatBalSurf.SurfAbsSolarExt[0] = 0.0
    var mat2 = MaterialGlass()
    s_mat.materials.push_back(mat2)
    mat2.Resistance = 1.25
    mat2.Roughness = Material.SurfaceRoughness.VeryRough
    mat2.group = Material.Group.Glass
    mat2.AbsorpSolar = 0.75
    mat2.AbsorpThermal = 0.75
    mat2.Trans = 0.25
    mat2.ReflectSolBeamFront = 0.20
    HeatBalanceSurfaceManager.EvalOutsideMovableInsulation(state)
    assert_eq(0.55, state.dataHeatBalSurf.SurfAbsSolarExt[0])
    s_mat.materials.clear()
    state.dataHeatBalSurf.SurfAbsSolarExt[0] = 0.0
    var mat3 = MaterialGlassEQL()
    s_mat.materials.push_back(mat3)
    mat3.Resistance = 1.25
    mat3.Roughness = Material.SurfaceRoughness.VeryRough
    mat3.group = Material.Group.GlassEQL
    mat3.AbsorpSolar = 0.75
    mat3.AbsorpThermal = 0.75
    mat3.Trans = 0.25
    mat3.ReflectSolBeamFront = 0.20
    HeatBalanceSurfaceManager.EvalOutsideMovableInsulation(state)
    assert_eq(0.55, state.dataHeatBalSurf.SurfAbsSolarExt[0])
    s_mat.materials.clear()

@test
def test_HeatBalanceMovableInsulation_EvalInsideMovableInsulation():
    var state = EnergyPlusData()
    state.init_state(state)
    var SurfNum: Int = 1
    state.dataSurface.Surface.allocate(SurfNum)
    state.dataSurface.intMovInsuls.allocate(SurfNum)
    state.dataSurface.intMovInsuls[0].sched = Sched.GetScheduleAlwaysOn(state)
    state.dataSurface.intMovInsuls[0].matNum = 1
    state.dataHeatBalSurf.SurfAbsSolarInt.allocate(SurfNum)
    state.dataHeatBalSurf.SurfAbsThermalInt.allocate(SurfNum)
    state.dataSurface.intMovInsulSurfNums.push_back(SurfNum)
    var mat = MaterialShade()
    state.dataMaterial.materials.push_back(mat)
    mat.Resistance = 1.25
    mat.Roughness = Material.SurfaceRoughness.VeryRough
    mat.group = Material.Group.Regular
    mat.AbsorpSolar = 0.75
    mat.AbsorpThermal = 0.75
    mat.Trans = 0.25
    mat.ReflectSolBeamFront = 0.20
    state.dataHeatBal.Zone.allocate(1)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.space.allocate(1)
    state.dataHeatBal.Zone[0].spaceIndexes.emplace_back(1)
    state.dataHeatBal.space[0].OpaqOrIntMassSurfaceFirst = 1
    state.dataHeatBal.space[0].OpaqOrIntMassSurfaceLast = 1
    state.dataHeatBalSurf.SurfAbsSolarInt[0] = 0.0
    HeatBalanceSurfaceManager.EvalInsideMovableInsulation(state)
    assert_eq(0.75, state.dataHeatBalSurf.SurfAbsSolarInt[0])
    assert_eq(0.8, state.dataSurface.intMovInsuls[0].H)
    assert_eq(true, state.dataSurface.intMovInsuls[0].present)
    assert_eq(0.75, state.dataHeatBalSurf.SurfAbsThermalInt[0])
    state.dataHeatBalSurf.SurfAbsSolarInt[0] = 0.0
    mat.group = Material.Group.Glass
    HeatBalanceSurfaceManager.EvalInsideMovableInsulation(state)
    assert_eq(0.55, state.dataHeatBalSurf.SurfAbsSolarInt[0])
    state.dataHeatBalSurf.SurfAbsSolarInt[0] = 0.0
    mat.group = Material.Group.GlassEQL
    HeatBalanceSurfaceManager.EvalInsideMovableInsulation(state)
    assert_eq(0.55, state.dataHeatBalSurf.SurfAbsSolarInt[0])

@test
def test_SurfaceControlMovableInsulation_InvalidWindowSimpleGlazingTest():
    var idf_objects = delimited_string([
        "  Construction,",
        "    EXTWALL80,               !- Name",
        "    A1 - 1 IN STUCCO,        !- Outside Layer",
        "    C4 - 4 IN COMMON BRICK,  !- Layer 2",
        "    E1 - 3 / 4 IN PLASTER OR GYP BOARD;  !- Layer 3",
        "  Material,",
        "    A1 - 1 IN STUCCO,        !- Name",
        "    Smooth,                  !- Roughness",
        "    2.5389841E-02,           !- Thickness {m}",
        "    0.6918309,               !- Conductivity {W/m-K}",
        "    1858.142,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.9200000,               !- Solar Absorptance",
        "    0.9200000;               !- Visible Absorptance",
        "  Material,",
        "    C4 - 4 IN COMMON BRICK,  !- Name",
        "    Rough,                   !- Roughness",
        "    0.1014984,               !- Thickness {m}",
        "    0.7264224,               !- Conductivity {W/m-K}",
        "    1922.216,                !- Density {kg/m3}",
        "    836.8000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7600000,               !- Solar Absorptance",
        "    0.7600000;               !- Visible Absorptance",
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
        "  BuildingSurface:Detailed,",
        "    Zn001:Wall001,           !- Name",
        "    Wall,                    !- Surface Type",
        "    EXTWALL80,               !- Construction Name",
        "    ZONE ONE,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.5000000,               !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,0,4.572000,            !- X,Y,Z ==> Vertex 1 {m}",
        "    0,0,0,                   !- X,Y,Z ==> Vertex 2 {m}",
        "    15.24000,0,0,            !- X,Y,Z ==> Vertex 3 {m}",
        "    15.24000,0,4.572000;     !- X,Y,Z ==> Vertex 4 {m}",
        "  WindowMaterial:SimpleGlazingSystem,",
        "    SimpleGlazingSystem,     !- Name",
        "    2.8,                     !- U-Factor {W/m2-K}",
        "    0.7;                     !- Solar Heat Gain Coefficient",
        "  SurfaceControl:MovableInsulation,",
        "    Outside,                 !- Insulation Type",
        "    Zn001:Wall001,           !- Surface Name",
        "    SimpleGlazingSystem,     !- Material Name",
        "    ON;                      !- Schedule Name",
        "  Schedule:Compact,",
        "    ON,                      !- Name",
        "    FRACTION,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: Alldays,            !- Field 2",
        "    Until: 24:00,1.00;       !- Field 3",
        "  ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
    ])
    assert_true(process_idf(idf_objects))
    var state = EnergyPlusData()
    state.init_state(state)
    var ErrorsFound: Bool = false
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[0].Name = "ZONE ONE"
    Material.GetMaterialData(state, ErrorsFound)
    assert_false(ErrorsFound)
    assert_eq(4, state.dataMaterial.materials.size())
    assert_eq(state.dataMaterial.materials[3].group, Material.Group.GlassSimple)
    HeatBalanceManager.GetConstructData(state, ErrorsFound)
    assert_eq(1, state.dataHeatBal.TotConstructs)
    assert_false(ErrorsFound)
    SurfaceGeometry.GetGeometryParameters(state, ErrorsFound)
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = 1.0
    state.dataSurfaceGeometry.CosZoneRelNorth[1] = 1.0
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = 0.0
    state.dataSurfaceGeometry.SinZoneRelNorth[1] = 0.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    state.dataSurface.TotSurfaces = 1
    state.dataSurface.Surface.allocate(1)
    state.dataSurface.extMovInsuls.allocate(1)
    state.dataSurface.intMovInsuls.allocate(1)
    state.dataSurface.extMovInsuls[0].matNum = 0
    state.dataSurface.extMovInsuls[0].sched = None
    state.dataSurface.intMovInsuls[0].matNum = 0
    state.dataSurface.intMovInsuls[0].sched = None
    state.dataSurfaceGeometry.SurfaceTmp.allocate(1)
    var SurfNum: Int = 0
    var TotHTSurfs: Int = state.dataSurface.TotSurfaces = 1
    var BaseSurfCls = List[String](1, "WALL")
    var BaseSurfIDs = List[DataSurfaces.SurfaceClass](1, DataSurfaces.SurfaceClass.Wall)
    var NeedToAddSurfaces: Int
    SurfaceGeometry.GetHTSurfaceData(state, ErrorsFound, SurfNum, TotHTSurfs, 0, 0, 0, BaseSurfCls, BaseSurfIDs, NeedToAddSurfaces)
    state.dataSurface.Surface[0] = state.dataSurfaceGeometry.SurfaceTmp[0]
    SurfaceGeometry.GetMovableInsulationData(state, ErrorsFound)
    assert_eq(state.dataSurfaceGeometry.SurfaceTmp[0].BaseSurfName, "ZN001:WALL001")
    assert_eq(state.dataSurface.extMovInsuls[0].matNum, 4)
    assert_eq(state.dataMaterial.materials[3].Name, "SIMPLEGLAZINGSYSTEM")
    assert_eq(state.dataMaterial.materials[3].group, Material.Group.GlassSimple)
    assert_true(ErrorsFound)