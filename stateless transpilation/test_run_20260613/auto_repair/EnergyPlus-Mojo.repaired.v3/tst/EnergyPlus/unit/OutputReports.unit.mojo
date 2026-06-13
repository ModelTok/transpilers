from testing import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, has_eio_output, compare_eio_stream, delimited_string
from EnergyPlus.HeatBalanceManager import GetProjectControlData, GetConstructData, GetZoneData
from EnergyPlus.Material import GetMaterialData
from EnergyPlus.SurfaceGeometry import GetSurfaceData
from EnergyPlus.OutputReports import DetailsForSurfaces
from EnergyPlus.Data.EnergyPlusData import state as EnergyPlusData_state, Constant
from EnergyPlus.DataHeatBalance import Zone, HeatBalData
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.Data.GlobalConstants import DegToRad
import math

# Define test struct inheriting from EnergyPlusFixture
struct OutputReports_SurfaceDetailsReport(EnergyPlusFixture):
    def __init__(inout self):
        super().__init__()

    @Test
    def run_test(self):
        var idf_objects: String = delimited_string(
            [
                "Zone,",
                "  Space1,                !- Name",
                "  0.0000,                  !- Direction of Relative North {deg}",
                "  0.0000,                  !- X Origin {m}",
                "  0.0000,                  !- Y Origin {m}",
                "  0.0000,                  !- Z Origin {m}",
                "  1,                       !- Type",
                "  1,                       !- Multiplier",
                "  2.4,                     !- Ceiling Height {m}",
                "  ,                        !- Volume {m3}",
                "  autocalculate,           !- Floor Area {m2}",
                "  ,                        !- Zone Inside Convection Algorithm",
                "  ,                        !- Zone Outside Convection Algorithm",
                "  Yes;                     !- Part of Total Floor Area",
                "BuildingSurface:Detailed,",
                " FRONT-1,                  !- Name",
                " WALL,                     !- Surface Type",
                " INT-WALL-1,               !- Construction Name",
                " Space1,                    !- Zone Name",
                "    ,                        !- Space Name",
                " Outdoors,                 !- Outside Boundary Condition",
                " ,                         !- Outside Boundary Condition Object",
                " SunExposed,               !- Sun Exposure",
                " WindExposed,              !- Wind Exposure",
                " 0.50000,                  !- View Factor to Ground",
                " 4,                        !- Number of Vertices",
                " 0.0, 0.0, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
                " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 2 {m}",
                " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 3 {m}",
                " 30.5, 0.0, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
                "Construction,",
                " INT-WALL-1,               !- Name",
                " GP02,                     !- Outside Layer",
                " AL21,                     !- Layer 2",
                " GP02;                     !- Layer 3",
                " ",
                "Material,",
                " GP02,                     !- Name",
                " MediumSmooth,             !- Roughness",
                " 1.5900001E-02,            !- Thickness{ m }",
                " 0.1600000,                !- Conductivity{ W / m - K }",
                " 801.0000,                 !- Density{ kg / m3 }",
                " 837.0000,                 !- Specific Heat{ J / kg - K }",
                " 0.9000000,                !- Thermal Absorptance",
                " 0.7500000,                !- Solar Absorptance",
                " 0.7500000;                !- Visible Absorptance",
                " ",
                "Material:AirGap,",
                " AL21,                     !- Name",
                " 0.1570000;                !- Thermal Resistance{ m2 - K / W }",
                " ",
                "Output:Surfaces:List,Details;",
            ]
        )
        assert_true(process_idf(idf_objects))
        var foundErrors: Bool = False
        GetProjectControlData(self.state, foundErrors)  # read project control data
        assert_false(foundErrors)                         # expect no errors
        GetMaterialData(self.state, foundErrors)          # read material data
        assert_false(foundErrors)                         # expect no errors
        GetConstructData(self.state, foundErrors)         # read construction data
        compare_err_stream("")
        assert_false(foundErrors)                         # expect no errors
        GetZoneData(self.state, foundErrors)              # read zone data
        assert_false(foundErrors)                         # expect no errors
        self.state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
        self.state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
        self.state.dataSurfaceGeometry.CosZoneRelNorth[0] = math.cos(-self.state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        self.state.dataSurfaceGeometry.SinZoneRelNorth[0] = math.sin(-self.state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        self.state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
        self.state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
        GetSurfaceData(self.state, foundErrors)           # setup zone geometry and get zone data
        assert_false(foundErrors)                         # expect no errors
        has_eio_output(True)
        DetailsForSurfaces(self.state, 10)                # 10 = Details Only, Surface details report
        var eiooutput: String = delimited_string(
            [
                "! <Zone Surfaces>,Zone Name,# Surfaces",
                "! <Shading Surfaces>,Number of Shading Surfaces,# Surfaces",
                "! <HeatTransfer Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Construction,Nominal U (w/o film coefs) {W/m2-K},Nominal U (with film coefs) {W/m2-K},Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m},ExtBoundCondition,ExtConvCoeffCalc,IntConvCoeffCalc,SunExposure,WindExposure,ViewFactorToGround,ViewFactorToSky,ViewFactorToGround-IR,ViewFactorToSky-IR,#Sides",
                "! <Shading Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Transmittance Schedule,Min Schedule Value,Max Schedule Value,Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m},ExtBoundCondition,ExtConvCoeffCalc,IntConvCoeffCalc,SunExposure,WindExposure,ViewFactorToGround,ViewFactorToSky,ViewFactorToGround-IR,ViewFactorToSky-IR,#Sides",
                "! <Frame/Divider Surface>,Surface Name,Surface Class,Base Surface,Heat Transfer Algorithm,Construction,Nominal U (w/o film coefs) {W/m2-K},Nominal U (with film coefs) {W/m2-K},Solar Diffusing,Area (Net) {m2},Area (Gross) {m2},Area (Sunlit Calc) {m2},Azimuth {deg},Tilt {deg},~Width {m},~Height {m},Reveal {m}",
                "Zone Surfaces,SPACE1,1",
                "HeatTransfer Surface,FRONT-1,Wall,,CTF - ConductionTransferFunction,INT-WALL-1,2.81096,1.97846,,73.20,73.20,73.20,180.00,90.00,30.50,2.40,0.00,ExternalEnvironment,DOE-2,ASHRAETARP,SunExposed,WindExposed,0.50000,0.50000,0.50000,0.50000,4",
            ],
            "\n"
        )
        assert_true(compare_eio_stream(eiooutput, True))