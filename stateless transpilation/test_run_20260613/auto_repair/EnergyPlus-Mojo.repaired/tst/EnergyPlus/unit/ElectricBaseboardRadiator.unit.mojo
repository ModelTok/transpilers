from gtest import Test, EXPECT_EQ, EXPECT_TRUE, EXPECT_FALSE, EXPECT_NEAR, ASSERT_TRUE, ASSERT_FALSE
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.ElectricBaseboardRadiator import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Material import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.Data.EnergyPlusData import state as state_ptr
from EnergyPlus.Data.EnergyPlusData import Constant
from EnergyPlus.Data.EnergyPlusData import HVAC
from EnergyPlus.Data.EnergyPlusData import DataSizing as DataSizingMod
from EnergyPlus.Data.EnergyPlusData import Util
from EnergyPlus.Data.EnergyPlusData import delimited_string

def RadConvElecBaseboard_Test1():
    var idf_objects: String = delimited_string([
        "  Zone,",
        "    SPACE2-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    2.438400269,             !- Ceiling Height {m}",
        "    103.311355591;           !- Volume {m3}",
        "  Zone,",
        "    SPACE4-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    2.438400269,             !- Ceiling Height {m}",
        "    103.311355591;           !- Volume {m3}",
        "  ZoneHVAC:EquipmentConnections,",
        "    SPACE2-1,                !- Zone Name",
        "    SPACE2-1 Eq,             !- Zone Conditioning Equipment List Name",
        "    SPACE2-1 in node,       !- Zone Air Inlet Node or NodeList Name",
        "    ,                        !- Zone Air Exhaust Node or NodeList Name",
        "    SPACE2-1 Node,           !- Zone Air Node Name",
        "    SPACE2-1 ret node;       !- Zone Return Air Node Name",
        "  ZoneHVAC:EquipmentConnections,",
        "    SPACE4-1,                !- Zone Name",
        "    SPACE4-1 Eq,             !- Zone Conditioning Equipment List Name",
        "    SPACE4-1 in node,       !- Zone Air Inlet Node or NodeList Name",
        "    ,                        !- Zone Air Exhaust Node or NodeList Name",
        "    SPACE4-1 Node,           !- Zone Air Node Name",
        "    SPACE4-1 ret node;       !- Zone Return Air Node Name",
        "  ZoneHVAC:EquipmentList,",
        "    SPACE2-1 Eq,             !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Electric,  !- Zone Equipment 1 Object Type",
        "    SPACE2-1 Baseboard,      !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "  ZoneHVAC:EquipmentList,",
        "    SPACE4-1 Eq,             !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Electric,  !- Zone Equipment 1 Object Type",
        "    SPACE4-1 Baseboard,      !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        " ZoneHVAC:Baseboard:RadiantConvective:Electric,",
        "    SPACE2-1 Baseboard,      !- Name",
        "    CONSTANT-1.0,    !- Availability Schedule Name",
        "    HeatingDesignCapacity,   !- Heating Design Capacity Method",
        "    1000.0,                !- Heating Design Capacity {W}",
        "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
        "    ,                        !- Fraction of Autosized Heating Design Capacity",
        "    0.97,                    !- Efficiency",
        "    0.2,                     !- Fraction Radiant",
        "    0.3,                     !- Fraction of Radiant Energy Incident on People",
        "    RIGHT-1,                 !- Surface 1 Name",
        "    0.7;                     !- Fraction of Radiant Energy to Surface 1",
        "  BuildingSurface:Detailed,",
        "    RIGHT-1,                 !- Name",
        "    WALL,                    !- Surface Type",
        "    WALL-1,                  !- Construction Name",
        "    SPACE2-1,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50000,                 !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    30.5,0.0,2.4,  !- X,Y,Z ==> Vertex 1 {m}",
        "    30.5,0.0,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    30.5,15.2,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    30.5,15.2,2.4;  !- X,Y,Z ==> Vertex 4 {m}",
        "  ZoneHVAC:Baseboard:RadiantConvective:Electric,",
        "    SPACE4-1 Baseboard,      !- Name",
        "    CONSTANT-1.0,    !- Availability Schedule Name",
        "    HeatingDesignCapacity,   !- Heating Design Capacity Method",
        "    1000.0,                !- Heating Design Capacity {W}",
        "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
        "    ,                        !- Fraction of Autosized Heating Design Capacity",
        "    0.97,                    !- Efficiency",
        "    0.2,                     !- Fraction Radiant",
        "    0.3,                     !- Fraction of Radiant Energy Incident on People",
        "    LEFT-1,                  !- Surface 1 Name",
        "    0.7;                     !- Fraction of Radiant Energy to Surface 1",
        "  BuildingSurface:Detailed,",
        "    LEFT-1,                  !- Name",
        "    WALL,                    !- Surface Type",
        "    WALL-1,                  !- Construction Name",
        "    SPACE4-1,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50000,                 !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.0,15.2,2.4,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0.0,15.2,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    0.0,0.0,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    0.0,0.0,2.4;  !- X,Y,Z ==> Vertex 4 {m}",
        "SurfaceConvectionAlgorithm:Inside,TARP;",
        "SurfaceConvectionAlgorithm:Outside,DOE-2;",
        "HeatBalanceAlgorithm,ConductionTransferFunction;",
        "ZoneAirHeatBalanceAlgorithm,",
        "    AnalyticalSolution;      !- Algorithm",
        "  Construction,",
        "    WALL-1,                  !- Name",
        "    WD01,                    !- Outside Layer",
        "    PW03,                    !- Layer 2",
        "    IN02,                    !- Layer 3",
        "    GP01;                    !- Layer 4",
        "  Material,",
        "    WD01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.9099999E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    513.0000,                !- Density {kg/m3}",
        "    1381.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "  Material,",
        "    PW03,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    545.0000,                !- Density {kg/m3",
        "    1213.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "  Material,",
        "    IN02,                    !- Name",
        "    Rough,                   !- Roughness",
        "    9.0099998E-02,           !- Thickness {m}",
        "    4.3000001E-02,           !- Conductivity {W/m-K}",
        "    10.00000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Material,",
        "    GP01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1600000,               !- Conductivity {W/m-K}",
        "    801.0000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1    // must initialize this to get schedules initialized
    state.dataGlobal.MinutesInTimeStep = 60 // must initialize this to get schedules initialized
    state.init_state(state)
    var errorsFound: Bool = False
    HeatBalanceManager.GetProjectControlData(state, errorsFound) // read project control data
    EXPECT_FALSE(errorsFound)                                      // expect no errors
    errorsFound = False
    Material.GetMaterialData(state, errorsFound) // read material data
    EXPECT_FALSE(errorsFound)                      // expect no errors
    errorsFound = False
    HeatBalanceManager.GetConstructData(state, errorsFound) // read construction data
    EXPECT_FALSE(errorsFound)                                 // expect no errors
    HeatBalanceManager.GetZoneData(state, errorsFound)
    ASSERT_FALSE(errorsFound)
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(2)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = Math.cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosZoneRelNorth[1] = Math.cos(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = Math.sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[1] = Math.sin(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, errorsFound)
    ASSERT_FALSE(errorsFound)
    DataZoneEquipment.GetZoneEquipmentData(state)
    ElectricBaseboardRadiator.GetElectricBaseboardInput(state)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[0].ZonePtr, 1)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[1].ZonePtr, 2)
    var surfNumRight1: Int = Util.FindItemInList("RIGHT-1", state.dataSurface.Surface)
    var surfNumLeft1: Int = Util.FindItemInList("LEFT-1", state.dataSurface.Surface)
    EXPECT_EQ(state.dataSurface.allGetsRadiantHeatSurfaceList[0], surfNumRight1)
    EXPECT_EQ(state.dataSurface.allGetsRadiantHeatSurfaceList[1], surfNumLeft1)
    EXPECT_TRUE(state.dataSurface.surfIntConv[surfNumRight1 - 1].getsRadiantHeat)
    EXPECT_TRUE(state.dataSurface.surfIntConv[surfNumLeft1 - 1].getsRadiantHeat)

def ElectricBaseboardRadConv_SizingTest():
    var BaseboardNum: Int = 0
    var CntrlZoneNum: Int = 0
    var FirstHVACIteration: Bool = False
    var idf_objects: String = delimited_string([
        "  Zone,",
        "    SPACE2-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    2.438400269,             !- Ceiling Height {m}",
        "    103.311355591;           !- Volume {m3}",
        "  Zone,",
        "    SPACE3-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    2.438400269,             !- Ceiling Height {m}",
        "    103.311355591;           !- Volume {m3}",
        "  Zone,",
        "    SPACE4-1,                !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    2.438400269,             !- Ceiling Height {m}",
        "    103.311355591;           !- Volume {m3}",
        "  ZoneHVAC:EquipmentConnections,",
        "    SPACE2-1,                !- Zone Name",
        "    SPACE2-1 Eq,             !- Zone Conditioning Equipment List Name",
        "    SPACE2-1 in node,        !- Zone Air Inlet Node or NodeList Name",
        "    ,                        !- Zone Air Exhaust Node or NodeList Name",
        "    SPACE2-1 Node,           !- Zone Air Node Name",
        "    SPACE2-1 ret node;       !- Zone Return Air Node Name",
        "  ZoneHVAC:EquipmentConnections,",
        "    SPACE3-1,                !- Zone Name",
        "    SPACE3-1 Eq,             !- Zone Conditioning Equipment List Name",
        "    SPACE3-1 in node,        !- Zone Air Inlet Node or NodeList Name",
        "    ,                        !- Zone Air Exhaust Node or NodeList Name",
        "    SPACE3-1 Node,           !- Zone Air Node Name",
        "    SPACE3-1 ret node;       !- Zone Return Air Node Name",
        "  ZoneHVAC:EquipmentConnections,",
        "    SPACE4-1,                !- Zone Name",
        "    SPACE4-1 Eq,             !- Zone Conditioning Equipment List Name",
        "    SPACE4-1 in node,       !- Zone Air Inlet Node or NodeList Name",
        "    ,                        !- Zone Air Exhaust Node or NodeList Name",
        "    SPACE4-1 Node,           !- Zone Air Node Name",
        "    SPACE4-1 ret node;       !- Zone Return Air Node Name",
        "  ZoneHVAC:EquipmentList,",
        "    SPACE2-1 Eq,             !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Electric,  !- Zone Equipment 1 Object Type",
        "    SPACE2-1 Baseboard,      !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "  ZoneHVAC:EquipmentList,",
        "    SPACE3-1 Eq,             !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Electric,  !- Zone Equipment 1 Object Type",
        "    SPACE3-1 Baseboard,      !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "  ZoneHVAC:EquipmentList,",
        "    SPACE4-1 Eq,             !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Electric,  !- Zone Equipment 1 Object Type",
        "    SPACE4-1 Baseboard,      !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
        " ZoneHVAC:Baseboard:RadiantConvective:Electric,",
        "    SPACE2-1 Baseboard,      !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    HeatingDesignCapacity,   !- Heating Design Capacity Method",
        "    1000.0,                  !- Heating Design Capacity {W}",
        "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
        "    ,                        !- Fraction of Autosized Heating Design Capacity",
        "    0.97,                    !- Efficiency",
        "    0.2,                     !- Fraction Radiant",
        "    0.3,                     !- Fraction of Radiant Energy Incident on People",
        "    RIGHT-1,                 !- Surface 1 Name",
        "    0.7;                     !- Fraction of Radiant Energy to Surface 1",
        "  BuildingSurface:Detailed,",
        "    RIGHT-1,                 !- Name",
        "    WALL,                    !- Surface Type",
        "    WALL-1,                  !- Construction Name",
        "    SPACE2-1,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50000,                 !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    30.5,0.0,2.4,   !- X,Y,Z ==> Vertex 1 {m}",
        "    30.5,0.0,0.0,   !- X,Y,Z ==> Vertex 2 {m}",
        "    30.5,15.2,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
        "    30.5,15.2,2.4;  !- X,Y,Z ==> Vertex 4 {m}",
        "  ZoneHVAC:Baseboard:RadiantConvective:Electric,",
        "    SPACE3-1 Baseboard,      !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    CapacityPerFloorArea,    !- Heating Design Capacity Method",
        "    ,                        !- Heating Design Capacity {W}",
        "    30.0,                    !- Heating Design Capacity Per Floor Area {W/m2}",
        "    ,                        !- Fraction of Autosized Heating Design Capacity",
        "    0.97,                    !- Efficiency",
        "    0.2,                     !- Fraction Radiant",
        "    0.3,                     !- Fraction of Radiant Energy Incident on People",
        "    FRONT-1,                 !- Surface 1 Name",
        "    0.7;                     !- Fraction of Radiant Energy to Surface 1",
        "  BuildingSurface:Detailed,",
        "    FRONT-1,                  !- Name",
        "    WALL,                    !- Surface Type",
        "    WALL-1,                  !- Construction Name",
        "    SPACE3-1,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50000,                 !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.0, 0.0, 2.4,    !- X,Y,Z ==> Vertex 1 {m}",
        "    0.0, 0.0, 0.0,    !- X,Y,Z ==> Vertex 2 {m}",
        "    20.0, 0.0, 0.0,   !- X,Y,Z ==> Vertex 3 {m}",
        "    20.0, 0.0, 2.4;   !- X,Y,Z ==> Vertex 4 {m}",
        "  ZoneHVAC:Baseboard:RadiantConvective:Electric,",
        "    SPACE4-1 Baseboard,      !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    FractionOfAutosizedHeatingCapacity,   !- Heating Design Capacity Method",
        "    ,                        !- Heating Design Capacity {W}",
        "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
        "    0.5,                     !- Fraction of Autosized Heating Design Capacity",
        "    0.97,                    !- Efficiency",
        "    0.2,                     !- Fraction Radiant",
        "    0.3,                     !- Fraction of Radiant Energy Incident on People",
        "    LEFT-1,                  !- Surface 1 Name",
        "    0.7;                     !- Fraction of Radiant Energy to Surface 1",
        "  BuildingSurface:Detailed,",
        "    LEFT-1,                  !- Name",
        "    WALL,                    !- Surface Type",
        "    WALL-1,                  !- Construction Name",
        "    SPACE4-1,                !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50000,                 !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0.0,15.2,2.4,  !- X,Y,Z ==> Vertex 1 {m}",
        "    0.0,15.2,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
        "    0.0,0.0,0.0,   !- X,Y,Z ==> Vertex 3 {m}",
        "    0.0,0.0,2.4;   !- X,Y,Z ==> Vertex 4 {m}",
        "SurfaceConvectionAlgorithm:Inside,TARP;",
        "SurfaceConvectionAlgorithm:Outside,DOE-2;",
        "HeatBalanceAlgorithm,ConductionTransferFunction;",
        "ZoneAirHeatBalanceAlgorithm,",
        "    AnalyticalSolution;      !- Algorithm",
        "  Construction,",
        "    WALL-1,                  !- Name",
        "    WD01,                    !- Outside Layer",
        "    PW03,                    !- Layer 2",
        "    IN02,                    !- Layer 3",
        "    GP01;                    !- Layer 4",
        "  Material,",
        "    WD01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.9099999E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    513.0000,                !- Density {kg/m3}",
        "    1381.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "  Material,",
        "    PW03,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1150000,               !- Conductivity {W/m-K}",
        "    545.0000,                !- Density {kg/m3",
        "    1213.000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7800000,               !- Solar Absorptance",
        "    0.7800000;               !- Visible Absorptance",
        "  Material,",
        "    IN02,                    !- Name",
        "    Rough,                   !- Roughness",
        "    9.0099998E-02,           !- Thickness {m}",
        "    4.3000001E-02,           !- Conductivity {W/m-K}",
        "    10.00000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
        "  Material,",
        "    GP01,                    !- Name",
        "    MediumSmooth,            !- Roughness",
        "    1.2700000E-02,           !- Thickness {m}",
        "    0.1600000,               !- Conductivity {W/m-K}",
        "    801.0000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.7500000,               !- Solar Absorptance",
        "    0.7500000;               !- Visible Absorptance",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.dataGlobal.TimeStepsInHour = 1    // must initialize this to get schedules initialized
    state.dataGlobal.MinutesInTimeStep = 60 // must initialize this to get schedules initialized
    state.init_state(state)
    var errorsFound: Bool = False
    HeatBalanceManager.GetProjectControlData(state, errorsFound) // read project control data
    EXPECT_FALSE(errorsFound)                                      // expect no errors
    errorsFound = False
    Material.GetMaterialData(state, errorsFound) // read material data
    EXPECT_FALSE(errorsFound)                      // expect no errors
    errorsFound = False
    HeatBalanceManager.GetConstructData(state, errorsFound) // read construction data
    EXPECT_FALSE(errorsFound)                                 // expect no errors
    HeatBalanceManager.GetZoneData(state, errorsFound)
    ASSERT_FALSE(errorsFound)
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(3)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(3)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = Math.cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosZoneRelNorth[1] = Math.cos(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosZoneRelNorth[2] = Math.cos(-state.dataHeatBal.Zone[2].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = Math.sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[1] = Math.sin(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[2] = Math.sin(-state.dataHeatBal.Zone[2].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, errorsFound)
    ASSERT_FALSE(errorsFound)
    DataZoneEquipment.GetZoneEquipmentData(state)
    ElectricBaseboardRadiator.GetElectricBaseboardInput(state)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[0].ZonePtr, 1)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[1].ZonePtr, 2)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[2].ZonePtr, 3)
    state.dataSize.FinalZoneSizing.allocate(3)
    state.dataSize.ZoneEqSizing.allocate(3)
    state.dataSize.ZoneSizingRunDone = True
    BaseboardNum = 1
    CntrlZoneNum = 1
    state.dataSize.CurZoneEqNum = CntrlZoneNum
    FirstHVACIteration = True
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing - 1] =
        state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].HeatingCapMethod
    state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 2000.0
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity, 1000.0)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 1000.0)
    state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity = DataSizingMod.AutoSize
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 2000.0)
    BaseboardNum = 2
    CntrlZoneNum = 2
    state.dataSize.CurZoneEqNum = CntrlZoneNum
    FirstHVACIteration = True
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing - 1] =
        state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].HeatingCapMethod
    state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 2000.0
    state.dataHeatBal.Zone[CntrlZoneNum - 1].FloorArea = 100.0
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity, 30.0)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 3000.0)
    state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].HeatingCapMethod = DataSizingMod.HeatingDesignCapacity
    state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity = DataSizingMod.AutoSize
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 2000.0)
    BaseboardNum = 3
    CntrlZoneNum = 3
    state.dataSize.CurZoneEqNum = CntrlZoneNum
    FirstHVACIteration = True
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing - 1] =
        state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].HeatingCapMethod
    state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 3000.0
    state.dataHeatBal.Zone[CntrlZoneNum - 1].FloorArea = 100.0
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity, 0.50)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 1500.0)
    state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].HeatingCapMethod = DataSizingMod.HeatingDesignCapacity
    state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].ScaledHeatingCapacity = DataSizingMod.AutoSize
    ElectricBaseboardRadiator.SizeElectricBaseboard(state, BaseboardNum)
    EXPECT_EQ(state.dataElectBaseboardRad.ElecBaseboard[BaseboardNum - 1].NominalCapacity, 3000.0)

def RadConvElecBaseboard_UpdateElectricBaseboardOff():
    var LoadMet: Float64
    var QBBCap: Float64
    var RadHeat: Float64
    var QBBElecRadSrc: Float64
    var ElecUseRate: Float64
    var AirOutletTemp: Float64
    var AirInletTemp: Float64
    LoadMet = -1000.0
    QBBCap = 500.0
    RadHeat = 300.0
    QBBElecRadSrc = 300.0
    ElecUseRate = 600.0
    AirOutletTemp = 25.0
    AirInletTemp = 23.0
    ElectricBaseboardRadiator.UpdateElectricBaseboardOff(LoadMet, QBBCap, RadHeat, QBBElecRadSrc, ElecUseRate, AirOutletTemp, AirInletTemp)
    EXPECT_EQ(LoadMet, 0.0)
    EXPECT_EQ(QBBCap, 0.0)
    EXPECT_EQ(RadHeat, 0.0)
    EXPECT_EQ(QBBElecRadSrc, 0.0)
    EXPECT_EQ(ElecUseRate, 0.0)
    EXPECT_EQ(AirOutletTemp, AirInletTemp)

def RadConvElecBaseboard_UpdateElectricBaseboardOn():
    var AirOutletTemp: Float64
    var ElecUseRate: Float64
    var AirInletTemp: Float64
    var QBBCap: Float64
    var CapacitanceAir: Float64
    var Effic: Float64
    AirOutletTemp = 0.0
    ElecUseRate = 0.0
    AirInletTemp = 20.0
    QBBCap = 1200.0
    CapacitanceAir = 1000.0
    Effic = 0.5
    ElectricBaseboardRadiator.UpdateElectricBaseboardOn(AirOutletTemp, ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
    EXPECT_NEAR(AirOutletTemp, 21.2, 0.0001)
    EXPECT_NEAR(ElecUseRate, 2400.0, 0.0001)