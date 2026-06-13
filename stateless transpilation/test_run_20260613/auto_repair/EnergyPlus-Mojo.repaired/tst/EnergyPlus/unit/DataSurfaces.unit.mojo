from math import sin, cos
from testing import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobalConstants import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Material import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.Vectors import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

from DataVectorTypes import Vector

def test_DataSurfaces_SetSurfaceOutBulbTempAtTest():
    var ErrorsFound: Bool = False
    var idf_objects: String = delimited_string({
        "	BuildingSurface:Detailed,",
        "    T3-RF1 - Floor:n,        !- Name",
        "    Floor,                   !- Surface Type",
        "    ExtSlabCarpet 4in ClimateZone 1-8,  !- Construction Name",
        "    T3-RF1,                  !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    NoSun,                   !- Sun Exposure",
        "    NoWind,                  !- Wind Exposure",
        "    ,                        !- View Factor to Ground",
        "    ,                        !- Number of Vertices",
        "    -73.4395447868102,       !- Vertex 1 X-coordinate {m}",
        "    115.81641271866,         !- Vertex 1 Y-coordinate {m}",
        "    25000,                   !- Vertex 1 Z-coordinate {m}",
        "    -58.0249751030646,       !- Vertex 2 X-coordinate {m}",
        "    93.1706338416311,        !- Vertex 2 Y-coordinate {m}",
        "    25000,                   !- Vertex 2 Z-coordinate {m}",
        "    -68.9295447868101,       !- Vertex 3 X-coordinate {m}",
        "    74.3054685889134,        !- Vertex 3 Y-coordinate {m}",
        "    25000,                   !- Vertex 3 Z-coordinate {m}",
        "    -58.0345461881513,       !- Vertex 4 X-coordinate {m}",
        "    93.1761597101821,        !- Vertex 4 Y-coordinate {m}",
        "    25000;                   !- Vertex 4 Z-coordinate {m}",
        "Zone,",
        "    T3-RF1,                  !- Name",
        "    60,                      !- Direction of Relative North {deg}",
        "    234.651324196041,        !- X Origin {m}",
        "    -132.406575100608,       !- Y Origin {m}",
        "    14.8000000000003,        !- Z Origin {m}",
        "    ,                        !- Type",
        "    ,                        !- Multiplier",
        "    ,                        !- Ceiling Height {m}",
        "    ,                        !- Volume {m3}",
        "    ,                        !- Floor Area {m2}",
        "    ,                        !- Zone Inside Convection Algorithm",
        "    ,                        !- Zone Outside Convection Algorithm",
        "    No;                      !- Part of Total Floor Area",
        "Construction,",
        "    ExtSlabCarpet 4in ClimateZone 1-8,  !- Name",
        "    MAT-CC05 4 HW CONCRETE,  !- Outside Layer",
        "    CP02 CARPET PAD;         !- Layer 2",
        "Material,",
        "    MAT-CC05 4 HW CONCRETE,  !- Name",
        "    Rough,                   !- Roughness",
        "    0.1016,                  !- Thickness {m}",
        "    1.311,                   !- Conductivity {W/m-K}",
        "    2240,                    !- Density {kg/m3}",
        "    836.800000000001,        !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.85,                    !- Solar Absorptance",
        "    0.85;                    !- Visible Absorptance",
        "Material:NoMass,",
        "    CP02 CARPET PAD,         !- Name",
        "    Smooth,                  !- Roughness",
        "    0.1,                     !- Thermal Resistance {m2-K/W}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.8,                     !- Solar Absorptance",
        "    0.8;                     !- Visible Absorptance",
        "SurfaceConvectionAlgorithm:Inside,TARP;",
        "SurfaceConvectionAlgorithm:Outside,DOE-2;",
        "HeatBalanceAlgorithm,ConductionTransferFunction;",
        "ZoneAirHeatBalanceAlgorithm,",
        "    AnalyticalSolution;      !- Algorithm",
    })
    assert_true(process_idf(idf_objects))
    ErrorsFound = False
    GetProjectControlData(*state, ErrorsFound) // read project control data
    expect_false(ErrorsFound)                  // expect no errors
    ErrorsFound = False
    Material.GetMaterialData(*state, ErrorsFound) // read material data
    expect_false(ErrorsFound)                      // expect no errors
    ErrorsFound = False
    GetConstructData(*state, ErrorsFound) // read construction data
    expect_false(ErrorsFound)             // expect no errors
    ErrorsFound = False
    GetZoneData(*state, ErrorsFound) // read zone data
    expect_false(ErrorsFound)        // expect no errors
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    ErrorsFound = False
    GetSurfaceData(*state, ErrorsFound) // setup zone geometry and get zone data
    expect_false(ErrorsFound)           // expect no errors
    SetSurfaceOutBulbTempAt(*state)
    expect_eq("T3-RF1 - FLOOR:N", state.dataSurface.Surface[0].Name)
    expect_gt(state.dataSurface.Surface[0].Centroid.z, 20000.0) // this condition is fatal
    expect_lt(state.dataSurface.SurfOutDryBulbTemp[0], -100.0)  // this condition is fatal
    expect_lt(state.dataSurface.SurfOutWetBulbTemp[0], -100.0)  // this condition is fatal

def test_SurfaceTest_Plane():
    {
        var s: SurfaceData
        s.Vertex.dimension(3)
        s.Vertex = {Vector(1, 1, 1), Vector(-1, 1, 0), Vector(2, 0, 3)}
        s.Shape = SurfaceShape.Triangle
        s.set_computed_geometry()
        expect_double_eq(-1.0, s.plane.x)
        expect_double_eq(3.0, s.plane.y)
        expect_double_eq(2.0, s.plane.z)
        expect_double_eq(-4.0, s.plane.w)
    }
    {
        var s: SurfaceData
        s.Vertex.dimension(3)
        s.Vertex = {Vector(2, 1, -1), Vector(0, -2, 0), Vector(1, -1, 2)}
        s.Shape = SurfaceShape.Triangle
        s.set_computed_geometry()
        expect_double_eq(-7.0, s.plane.x)
        expect_double_eq(5.0, s.plane.y)
        expect_double_eq(1.0, s.plane.z)
        expect_double_eq(10.0, s.plane.w)
    }

def test_SurfaceTest_Surface2D():
    {
        using Vector2D = Surface2D.Vector2D
        var s: SurfaceData
        s.Vertex.dimension(4)
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0), Vector(0, 1, 0)}
        s.Shape = SurfaceShape.Rectangle
        s.set_computed_geometry()
        var s2d: Surface2D = s.surface2d
        expect_eq(2, s2d.axis) // Projection along z axis
        expect_eq(Vector2D(0, 0), s2d.vertices[0])
        expect_eq(Vector2D(1, 0), s2d.vertices[1])
        expect_eq(Vector2D(1, 1), s2d.vertices[2])
        expect_eq(Vector2D(0, 1), s2d.vertices[3])
        expect_double_eq(0.0, s2d.vl.x)
        expect_double_eq(0.0, s2d.vl.y)
        expect_double_eq(1.0, s2d.vu.x)
        expect_double_eq(1.0, s2d.vu.y)
    }

def test_SurfaceTest_Surface2D_bigVertices():
    using Vector2D = Surface2D.Vector2D
    state.dataSurface.TotSurfaces = 1
    alias surfNum: Int = 1
    var nVertices: Int = 22
    state.dataSurface.MaxVerticesPerSurface = nVertices
    state.dataSurfaceGeometry.SurfaceTmp.allocate(state.dataSurface.TotSurfaces)
    var s = state.dataSurfaceGeometry.SurfaceTmp[surfNum - 1]
    s.Vertex.dimension(nVertices)
    s.Sides = nVertices
    s.Vertex = {Vector(0, 0, 0),     Vector(0.1, 1.0, 0), Vector(0.2, 1.9, 0), Vector(0.3, 2.7, 0), Vector(0.4, 3.4, 0), Vector(0.5, 4.0, 0),
                Vector(0.6, 4.5, 0), Vector(0.7, 4.9, 0), Vector(0.8, 5.2, 0), Vector(0.9, 5.4, 0), Vector(1.0, 5.5, 0), Vector(1.1, 5.4, 0),
                Vector(1.2, 5.2, 0), Vector(1.3, 4.9, 0), Vector(1.4, 4.5, 0), Vector(1.5, 4.0, 0), Vector(1.6, 3.4, 0), Vector(1.7, 2.7, 0),
                Vector(1.8, 1.9, 0), Vector(1.9, 1.0, 0), Vector(2.0, 0.0, 0), Vector(2.0, -1, 0)}
    s.Shape = SurfaceShape.Polygonal
    CheckConvexity(*state, 1, s.Sides)
    expect_true(s.IsConvex)
    s.set_computed_geometry()
    var s2d: Surface2D = s.surface2d
    expect_eq(2, s2d.axis) // Projection along z axis
    expect_eq(Vector2D(0.0, 0.0), s2d.vertices[0])
    expect_eq(Vector2D(2.0, -1.0), s2d.vertices[1])
    expect_eq(Vector2D(2.0, 0.0), s2d.vertices[2])
    expect_eq(Vector2D(1.9, 1.0), s2d.vertices[3])
    expect_eq(Vector2D(1.8, 1.9), s2d.vertices[4])
    expect_eq(Vector2D(1.7, 2.7), s2d.vertices[5])
    expect_eq(Vector2D(1.6, 3.4), s2d.vertices[6])
    expect_eq(Vector2D(1.5, 4.0), s2d.vertices[7])
    expect_eq(Vector2D(1.4, 4.5), s2d.vertices[8])
    expect_eq(Vector2D(1.3, 4.9), s2d.vertices[9])
    expect_eq(Vector2D(1.2, 5.2), s2d.vertices[10])
    expect_eq(Vector2D(1.1, 5.4), s2d.vertices[11])
    expect_eq(Vector2D(1.0, 5.5), s2d.vertices[12])
    expect_eq(Vector2D(0.9, 5.4), s2d.vertices[13])
    expect_eq(Vector2D(0.8, 5.2), s2d.vertices[14])
    expect_eq(Vector2D(0.7, 4.9), s2d.vertices[15])
    expect_eq(Vector2D(0.6, 4.5), s2d.vertices[16])
    expect_eq(Vector2D(0.5, 4.0), s2d.vertices[17])
    expect_eq(Vector2D(0.4, 3.4), s2d.vertices[18])
    expect_eq(Vector2D(0.3, 2.7), s2d.vertices[19])
    expect_eq(Vector2D(0.2, 1.9), s2d.vertices[20])
    expect_eq(Vector2D(0.1, 1.0), s2d.vertices[21])
    expect_double_eq(0.0, s2d.vl.x)
    expect_double_eq(-1.0, s2d.vl.y)
    expect_double_eq(2.0, s2d.vu.x)
    expect_double_eq(5.5, s2d.vu.y)
    expect_eq(11, len(s2d.slabs))
    expect_eq(2, len(s2d.slabs[0].edges))
    expect_eq(2, len(s2d.slabs[1].edges))
    expect_eq(2, len(s2d.slabs[2].edges))
    expect_eq(2, len(s2d.slabs[3].edges))
    expect_eq(2, len(s2d.slabs[4].edges))
    expect_eq(2, len(s2d.slabs[5].edges))
    expect_eq(2, len(s2d.slabs[6].edges))
    expect_eq(2, len(s2d.slabs[7].edges))
    expect_eq(2, len(s2d.slabs[8].edges))
    expect_eq(2, len(s2d.slabs[9].edges))
    expect_eq(2, len(s2d.slabs[10].edges))

def test_SurfaceTest_Surface2D_bigVertices2():
    using Vector2D = Surface2D.Vector2D
    state.dataSurface.TotSurfaces = 1
    alias surfNum: Int = 1
    var nVertices: Int = 24
    state.dataSurface.MaxVerticesPerSurface = nVertices
    state.dataSurfaceGeometry.SurfaceTmp.allocate(state.dataSurface.TotSurfaces)
    var s = state.dataSurfaceGeometry.SurfaceTmp[surfNum - 1]
    s.Vertex.dimension(nVertices)
    s.Sides = nVertices
    s.Vertex = {Vector(4.5047023, 14.8653133, 35.35), Vector(6.5689151, 13.4862441, 35.35), Vector(6.1242243, 12.8206238, 35.35),
                Vector(7.8836902, 11.6451513, 35.35), Vector(8.2156112, 12.1419759, 35.35), Vector(8.7993282, 11.7520035, 35.35),
                Vector(8.9659831, 12.0014552, 35.35), Vector(9.2241656, 11.8289674, 35.35), Vector(9.4352618, 12.1449395, 35.35),
                Vector(8.5933623, 12.7073998, 35.35), Vector(9.6032909, 14.219077, 35.35),  Vector(9.5550636, 14.251297, 35.35),
                Vector(8.5268029, 12.71218, 35.35),   Vector(9.1313075, 12.3083197, 35.35), Vector(8.7902205, 11.7977752, 35.35),
                Vector(8.1857159, 12.2016356, 35.35), Vector(7.8676828, 11.7255986, 35.35), Vector(6.2046715, 12.8366312, 35.35),
                Vector(6.6740828, 13.5392534, 35.35), Vector(4.646872, 14.8936022, 35.35),  Vector(5.8684524, 16.7220831, 35.35),
                Vector(7.8474358, 15.3999543, 35.35), Vector(7.8796558, 15.4481816, 35.35), Vector(5.815443, 16.8272508, 35.35)}
    s.Shape = SurfaceShape.Polygonal
    CheckConvexity(*state, 1, s.Sides)
    expect_false(s.IsConvex)
    s.set_computed_geometry()
    var s2d: Surface2D = s.surface2d
    expect_eq(2, s2d.axis) // Projection along z axis
    expect_eq(Vector2D(4.5047023, 14.8653133), s2d.vertices[0])
    expect_eq(Vector2D(6.5689151, 13.4862441), s2d.vertices[1])
    expect_eq(Vector2D(6.1242243, 12.8206238), s2d.vertices[2])
    expect_eq(Vector2D(7.8836902, 11.6451513), s2d.vertices[3])
    expect_eq(Vector2D(8.2156112, 12.1419759), s2d.vertices[4])
    expect_eq(Vector2D(8.7993282, 11.7520035), s2d.vertices[5])
    expect_eq(Vector2D(8.9659831, 12.0014552), s2d.vertices[6])
    expect_eq(Vector2D(9.2241656, 11.8289674), s2d.vertices[7])
    expect_eq(Vector2D(9.4352618, 12.1449395), s2d.vertices[8])
    expect_eq(Vector2D(8.5933623, 12.7073998), s2d.vertices[9])
    expect_eq(Vector2D(9.6032909, 14.219077), s2d.vertices[10])
    expect_eq(Vector2D(9.5550636, 14.251297), s2d.vertices[11])
    expect_eq(Vector2D(8.5268029, 12.71218), s2d.vertices[12])
    expect_eq(Vector2D(9.1313075, 12.3083197), s2d.vertices[13])
    expect_eq(Vector2D(8.7902205, 11.7977752), s2d.vertices[14])
    expect_eq(Vector2D(8.1857159, 12.2016356), s2d.vertices[15])
    expect_eq(Vector2D(7.8676828, 11.7255986), s2d.vertices[16])
    expect_eq(Vector2D(6.2046715, 12.8366312), s2d.vertices[17])
    expect_eq(Vector2D(6.6740828, 13.5392534), s2d.vertices[18])
    expect_eq(Vector2D(4.646872, 14.8936022), s2d.vertices[19])
    expect_eq(Vector2D(5.8684524, 16.7220831), s2d.vertices[20])
    expect_eq(Vector2D(7.8474358, 15.3999543), s2d.vertices[21])
    expect_eq(Vector2D(7.8796558, 15.4481816), s2d.vertices[22])
    expect_eq(Vector2D(5.815443, 16.8272508), s2d.vertices[23])
    expect_double_eq(4.5047023, s2d.vl.x)
    expect_double_eq(11.6451513, s2d.vl.y)
    expect_double_eq(9.6032909, s2d.vu.x)
    expect_double_eq(16.8272508, s2d.vu.y)
    expect_eq(23, len(s2d.slabs))
    expect_eq(2, len(s2d.slabs[0].edges))
    expect_eq(4, len(s2d.slabs[1].edges))
    expect_eq(6, len(s2d.slabs[2].edges))
    expect_eq(8, len(s2d.slabs[3].edges))
    expect_eq(10, len(s2d.slabs[4].edges))
    expect_eq(8, len(s2d.slabs[5].edges))
    expect_eq(6, len(s2d.slabs[6].edges))
    expect_eq(6, len(s2d.slabs[7].edges))
    expect_eq(4, len(s2d.slabs[8].edges))
    expect_eq(4, len(s2d.slabs[9].edges))
    expect_eq(4, len(s2d.slabs[10].edges))
    expect_eq(4, len(s2d.slabs[11].edges))
    expect_eq(4, len(s2d.slabs[12].edges))
    expect_eq(4, len(s2d.slabs[13].edges))
    expect_eq(4, len(s2d.slabs[14].edges))
    expect_eq(4, len(s2d.slabs[15].edges))
    expect_eq(4, len(s2d.slabs[16].edges))
    expect_eq(2, len(s2d.slabs[17].edges))
    expect_eq(2, len(s2d.slabs[18].edges))
    expect_eq(2, len(s2d.slabs[19].edges))
    expect_eq(4, len(s2d.slabs[20].edges))
    expect_eq(4, len(s2d.slabs[21].edges))
    expect_eq(2, len(s2d.slabs[22].edges))

def test_SurfaceTest_AverageHeightRectangle():
    {
        var s: SurfaceData
        s.Vertex.dimension(4)
        s.Shape = SurfaceShape.Rectangle
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0), Vector(0, 1, 0)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 0.0)
        s.Vertex = {Vector(0, 0, 0), Vector(1, 1, 0), Vector(1, 1, 1), Vector(0, 0, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 1.0)
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 1), Vector(0, 1, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 1.0 / s.SinTilt)
        s.Vertex = {Vector(0, 0, 0), Vector(0, 1, 0), Vector(0, 1, 1), Vector(0, 0, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 1.0)
        s.Vertex = {Vector(1, -1, 0), Vector(1, -1, -1), Vector(0, 0, -1), Vector(0, 0, 0)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 1.0)
    }

def test_SurfaceTest_AverageHeightTriangle():
    {
        var s: SurfaceData
        s.Vertex.dimension(3)
        s.Shape = SurfaceShape.Triangle
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 0, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 0.5)
        s.Vertex = {Vector(0, 0, 0), Vector(0, 0, 1), Vector(1, 0, 0)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 0.5)
    }

def test_SurfaceTest_AverageHeightL():
    {
        var s: SurfaceData
        s.Vertex.dimension(6)
        s.Shape = SurfaceShape.Polygonal
        s.Vertex = {Vector(0, 0, 0), Vector(0, 0, 1), Vector(0.5, 0, 1), Vector(0.5, 0, 0.5), Vector(1, 0, 0.5), Vector(1, 0, 0)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 0.75)
        s.Vertex = {Vector(0, 0, 0), Vector(0, 0, 1), Vector(1, 0, 1), Vector(1, 0, 0.5), Vector(0.5, 0, 0.5), Vector(0.5, 0, 0)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_double_eq(s.get_average_height(*state), 0.75)
    }

def test_SurfaceTest_HashMap():
    var numSurfs: Int = 4
    state.dataSurface.TotSurfaces = numSurfs
    state.dataSurface.Surface.allocate(numSurfs)
    state.dataSurface.SurfTAirRef.dimension(numSurfs, 0)
    state.dataSurface.surfIntConv.allocate(numSurfs)
    std.fill(state.dataSurface.surfIntConv.begin(), state.dataSurface.surfIntConv.end(), SurfIntConv())
    state.dataSurface.surfExtConv.allocate(numSurfs)
    std.fill(state.dataSurface.surfExtConv.begin(), state.dataSurface.surfExtConv.end(), SurfExtConv())
    state.dataSurface.SurfWinStormWinConstr.dimension(numSurfs, 0)
    state.dataSurface.intMovInsuls.allocate(numSurfs)
    state.dataSurface.extMovInsuls.allocate(numSurfs)
    for var SurfNum in range(1, numSurfs + 1):
        state.dataSurface.Surface[SurfNum - 1].set_representative_surface(*state, SurfNum)
    expect_eq(len(state.dataSurface.RepresentativeSurfaceMap), 1)
    expect_eq(state.dataSurface.Surface[0].RepresentativeCalcSurfNum, 1)
    expect_eq(state.dataSurface.Surface[1].RepresentativeCalcSurfNum, 1)
    expect_eq(state.dataSurface.Surface[2].RepresentativeCalcSurfNum, 1)
    expect_eq(state.dataSurface.Surface[3].RepresentativeCalcSurfNum, 1)
    state.dataSurface.RepresentativeSurfaceMap.clear()
    state.dataSurface.Surface[0].Area = 20.0
    state.dataSurface.Surface[1].Azimuth = 180.0
    state.dataSurface.Surface[2].Azimuth = 180.04
    for var SurfNum in range(1, numSurfs + 1):
        state.dataSurface.Surface[SurfNum - 1].set_representative_surface(*state, SurfNum)
    expect_eq(len(state.dataSurface.RepresentativeSurfaceMap), 2)
    expect_eq(state.dataSurface.Surface[0].RepresentativeCalcSurfNum, 1)
    expect_eq(state.dataSurface.Surface[1].RepresentativeCalcSurfNum, 2)
    expect_eq(state.dataSurface.Surface[2].RepresentativeCalcSurfNum, 2)
    expect_eq(state.dataSurface.Surface[3].RepresentativeCalcSurfNum, 1)
    state.dataSurface.RepresentativeSurfaceMap.clear()
    state.dataSurface.Surface[2].Azimuth = 180.05
    for var SurfNum in range(1, numSurfs + 1):
        state.dataSurface.Surface[SurfNum - 1].set_representative_surface(*state, SurfNum)
    expect_eq(len(state.dataSurface.RepresentativeSurfaceMap), 3)
    expect_eq(state.dataSurface.Surface[0].RepresentativeCalcSurfNum, 1)
    expect_eq(state.dataSurface.Surface[1].RepresentativeCalcSurfNum, 2)
    expect_eq(state.dataSurface.Surface[2].RepresentativeCalcSurfNum, 3)
    expect_eq(state.dataSurface.Surface[3].RepresentativeCalcSurfNum, 1)

def test_SurfaceTest_Azimuth_non_conv():
    {
        var s: SurfaceData
        s.Vertex.dimension(6)
        s.Shape = SurfaceShape.Polygonal
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 0, -1), Vector(2, 0, -1), Vector(2, 0, 1), Vector(0, 0, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        expect_double_eq(s.Azimuth, 180.0) // Original code without PR 9907 fix would fail this one by getting an s.Azimuth of 0.0
        expect_double_eq(s.Tilt, 90.0)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_near(s.SinAzim, 0.0, 1e-15)
        expect_double_eq(s.CosAzim, -1.0)
        expect_double_eq(s.SinTilt, 1.0)
    }
    {
        var s: SurfaceData
        s.Vertex.dimension(5)
        s.Shape = SurfaceShape.Polygonal
        s.Vertex = {Vector(0, 0, 0), Vector(1, 0, -1), Vector(2, 0, -1), Vector(2, 0, 1), Vector(0, 0, 1)}
        Vectors.CreateNewellSurfaceNormalVector(s.Vertex, len(s.Vertex), s.NewellSurfaceNormalVector)
        Vectors.DetermineAzimuthAndTilt(s.Vertex, s.Azimuth, s.Tilt, s.lcsx, s.lcsy, s.lcsz, s.NewellSurfaceNormalVector)
        expect_double_eq(s.Azimuth, 180.0)
        expect_double_eq(s.Tilt, 90.0)
        s.SinAzim = sin(s.Azimuth * Constant.DegToRad)
        s.CosAzim = cos(s.Azimuth * Constant.DegToRad)
        s.SinTilt = sin(s.Tilt * Constant.DegToRad)
        expect_near(s.SinAzim, 0.0, 1e-15)
        expect_double_eq(s.CosAzim, -1.0)
        expect_double_eq(s.SinTilt, 1.0)
    }