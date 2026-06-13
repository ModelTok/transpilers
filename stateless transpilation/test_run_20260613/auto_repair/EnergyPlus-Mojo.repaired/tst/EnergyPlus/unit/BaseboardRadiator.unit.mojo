from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_NEAR, EXPECT_TRUE, ASSERT_TRUE, ASSERT_THROW, ASSERT_FALSE
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.BaseboardRadiator import BaseboardRadiator
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataZoneEnergyDemands import DataZoneEnergyDemands
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.Material import Material
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.SurfaceGeometry import SurfaceGeometry
from EnergyPlus.Data.EnergyPlusData import state as state_type
from EnergyPlus.Data.EnergyPlusData import Constant
from EnergyPlus.Data.EnergyPlusData import HVAC
from EnergyPlus.Data.EnergyPlusData import Fluid
from EnergyPlus.Data.EnergyPlusData import LoopSideLocation
from EnergyPlus.Data.EnergyPlusData import delimited_string
from EnergyPlus.Data.EnergyPlusData import compare_eio_stream_substring
from EnergyPlus.Data.EnergyPlusData import compare_err_stream
from EnergyPlus.Data.EnergyPlusData import process_idf
from EnergyPlus.Data.EnergyPlusData import std
from EnergyPlus.Data.EnergyPlusData import runtime_error

@fixture
class EnergyPlusFixture:

@TestFixture
class BaseboardConvWater_SizingTest(EnergyPlusFixture):
    def run(self):
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
            "    ZoneHVAC:Baseboard:Convective:Water,  !- Zone Equipment 1 Object Type",
            "    SPACE2-1 Baseboard,      !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:EquipmentList,",
            "    SPACE3-1 Eq,             !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:Baseboard:Convective:Water,  !- Zone Equipment 1 Object Type",
            "    SPACE3-1 Baseboard,      !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            "  ZoneHVAC:EquipmentList,",
            "    SPACE4-1 Eq,             !- Name",
            "    SequentialLoad,          !- Load Distribution Scheme",
            "    ZoneHVAC:Baseboard:Convective:Water,  !- Zone Equipment 1 Object Type",
            "    SPACE4-1 Baseboard,      !- Zone Equipment 1 Name",
            "    1,                       !- Zone Equipment 1 Cooling Sequence",
            "    1;                       !- Zone Equipment 1 Heating or No-Load Sequence",
            " ZoneHVAC:Baseboard:Convective:Water,",
            "    SPACE2-1 Baseboard,      !- Name",
            "    CONSTANT-1.0,               !- Availability Schedule Name",
            "    SPACE2-1 Baseboard Inlet Node,   !- Inlet Node Name",
            "    SPACE2-1 Baseboard Outlet Node,  !- Outlet Node Name",
            "    HeatingDesignCapacity,   !- Heating Design Capacity Method",
            "    1000.0,                  !- Heating Design Capacity {W}",
            "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
            "    ,                        !- Fraction of Autosized Heating Design Capacity",
            "    autosize,                !- U-Factor Times Area Value",
            "    autosize,                !- Maximum Water Flow Rate",
            "    0.001;                   !- Convergence Tolerance",
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
            "  ZoneHVAC:Baseboard:Convective:Water,",
            "    SPACE3-1 Baseboard,      !- Name",
            "    CONSTANT-1.0,               !- Availability Schedule Name",
            "    SPACE3-1 Baseboard Inlet Node,   !- Inlet Node Name",
            "    SPACE3-1 Baseboard Outlet Node,  !- Outlet Node Name",
            "    CapacityPerFloorArea,    !- Heating Design Capacity Method",
            "    ,                        !- Heating Design Capacity {W}",
            "    40.0,                    !- Heating Design Capacity Per Floor Area {W/m2}",
            "    ,                        !- Fraction of Autosized Heating Design Capacity",
            "    autosize,                !- U-Factor Times Area Value",
            "    autosize,                !- Maximum Water Flow Rate",
            "    0.001;                   !- Convergence Tolerance",
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
            "  ZoneHVAC:Baseboard:Convective:Water,",
            "    SPACE4-1 Baseboard,      !- Name",
            "    CONSTANT-1.0,               !- Availability Schedule Name",
            "    SPACE4-1 Baseboard Inlet Node,   !- Inlet Node Name",
            "    SPACE4-1 Baseboard Outlet Node,  !- Outlet Node Name",
            "    FractionOfAutosizedHeatingCapacity,   !- Heating Design Capacity Method",
            "    ,                        !- Heating Design Capacity {W}",
            "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
            "    0.5,                     !- Fraction of Autosized Heating Design Capacity",
            "    autosize,                !- U-Factor Times Area Value",
            "    autosize,                !- Maximum Water Flow Rate",
            "    0.001;                   !- Convergence Tolerance",
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
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.init_state(state)
        var errorsFound: Bool = False
        HeatBalanceManager.GetProjectControlData(state, errorsFound)
        EXPECT_FALSE(errorsFound)
        errorsFound = False
        Material.GetMaterialData(state, errorsFound)
        EXPECT_FALSE(errorsFound)
        errorsFound = False
        HeatBalanceManager.GetConstructData(state, errorsFound)
        EXPECT_FALSE(errorsFound)
        HeatBalanceManager.GetZoneData(state, errorsFound)
        ASSERT_FALSE(errorsFound)
        state.dataSurfaceGeometry.CosZoneRelNorth.allocate(3)
        state.dataSurfaceGeometry.SinZoneRelNorth.allocate(3)
        state.dataSurfaceGeometry.CosZoneRelNorth[0] = std.cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.CosZoneRelNorth[1] = std.cos(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.CosZoneRelNorth[2] = std.cos(-state.dataHeatBal.Zone[2].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.SinZoneRelNorth[0] = std.sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.SinZoneRelNorth[1] = std.sin(-state.dataHeatBal.Zone[1].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.SinZoneRelNorth[2] = std.sin(-state.dataHeatBal.Zone[2].RelNorth * Constant.DegToRad)
        state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
        state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
        SurfaceGeometry.GetSurfaceData(state, errorsFound)
        ASSERT_FALSE(errorsFound)
        state.dataSize.ZoneSizingInput.allocate(3)
        state.dataSize.NumZoneSizingInput = 3
        state.dataSize.ZoneSizingInput[0].ZoneNum = 1
        state.dataSize.ZoneSizingInput[1].ZoneNum = 2
        state.dataSize.ZoneSizingInput[2].ZoneNum = 3
        var TotNumLoops: Int = 1
        state.dataPlnt.PlantLoop.allocate(TotNumLoops)
        state.dataSize.PlantSizData.allocate(TotNumLoops)
        state.dataSize.PlantSizData[0].DeltaT = 10.0
        state.dataSize.PlantSizData[0].ExitTemp = 40.0
        for l in range(1, TotNumLoops + 1):
            var loop = state.dataPlnt.PlantLoop[l - 1]
            loop.PlantSizNum = 1
            loop.FluidName = "WATER"
            loop.glycol = Fluid.GetWater(state)
            var loopside = state.dataPlnt.PlantLoop[l - 1].LoopSide[LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop[l - 1].LoopSide[LoopSideLocation.Demand].Branch[0]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        state.dataSize.ZoneSizingRunDone = True
        DataZoneEquipment.GetZoneEquipmentData(state)
        BaseboardRadiator.GetBaseboardInput(state)
        state.dataSize.FinalZoneSizing.allocate(3)
        state.dataSize.ZoneEqSizing.allocate(3)
        state.dataSize.ZoneSizingRunDone = True
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(3)
        state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(3)
        BaseboardNum = 1
        CntrlZoneNum = 1
        state.dataSize.CurZoneEqNum = CntrlZoneNum
        FirstHVACIteration = True
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing] = state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].HeatingCapMethod
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 2000.0
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CntrlZoneNum - 1].RemainingOutputReqToHeatSP = 2000.0
        state.dataZoneEnergyDemand.CurDeadBandOrSetback[CntrlZoneNum - 1] = False
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneTempAtHeatPeak = 20.0
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneHumRatAtHeatPeak = 0.005
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(state, state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ZonePtr = 1
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity, 1000.0)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 1000.0)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA = DataSizing.AutoSize
        state.files.eio.open_as_stringstream()
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataZoneEnergyDemand.ZoneSysEnergyDemand[CntrlZoneNum - 1].RemainingOutputReqToHeatSP, 2000.0)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 2000.0)
        EXPECT_NEAR(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax, 4.86063E-05, 0.0000001)
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE2-1 BASEBOARD, "
                                                 "Design Size Maximum Water Flow Rate [m3/s], 4.86063E-05",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE2-1 BASEBOARD, "
                                                 "Design Size Heating Load [W], 2000.00",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE2-1 BASEBOARD, "
                                                 "Design Size U-Factor Times Area Value [W/K], 2000.00",
                                                 True))
        BaseboardNum = 2
        CntrlZoneNum = 2
        state.dataSize.CurZoneEqNum = CntrlZoneNum
        FirstHVACIteration = True
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing] = state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].HeatingCapMethod
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 2000.0
        state.dataZoneEnergyDemand.CurDeadBandOrSetback[CntrlZoneNum - 1] = False
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneTempAtHeatPeak = 20.0
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneHumRatAtHeatPeak = 0.005
        state.dataHeatBal.Zone[CntrlZoneNum - 1].FloorArea = 100.0
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(state, state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ZonePtr = 2
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity, 40.0)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 4000.0)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].HeatingCapMethod = DataSizing.HeatingDesignCapacity
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity = DataSizing.AutoSize
        state.files.eio.open_as_stringstream()
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 2000.0)
        EXPECT_NEAR(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax, 4.86063E-05, 0.0000001)
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE3-1 BASEBOARD, "
                                                 "Design Size Maximum Water Flow Rate [m3/s], 4.86063E-05",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE3-1 BASEBOARD, "
                                                 "Design Size Heating Load [W], 2000.00",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE3-1 BASEBOARD, "
                                                 "Design Size U-Factor Times Area Value [W/K], 2000.00",
                                                 True))
        BaseboardNum = 3
        CntrlZoneNum = 3
        state.dataSize.CurZoneEqNum = CntrlZoneNum
        FirstHVACIteration = True
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod.allocate(HVAC.NumOfSizingTypes)
        state.dataSize.ZoneEqSizing[CntrlZoneNum - 1].SizingMethod[HVAC.HeatingCapacitySizing] = state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].HeatingCapMethod
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].NonAirSysDesHeatLoad = 3000.0
        state.dataZoneEnergyDemand.CurDeadBandOrSetback[CntrlZoneNum - 1] = False
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneTempAtHeatPeak = 20.0
        state.dataSize.FinalZoneSizing[CntrlZoneNum - 1].ZoneHumRatAtHeatPeak = 0.005
        state.dataHeatBal.Zone[CntrlZoneNum - 1].FloorArea = 100.0
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(state, state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].plantLoc)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ZonePtr = 3
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity, 0.50)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 1500.0)
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax = DataSizing.AutoSize
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].HeatingCapMethod = DataSizing.HeatingDesignCapacity
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].ScaledHeatingCapacity = DataSizing.AutoSize
        state.files.eio.open_as_stringstream()
        state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].SizeBaseboard(state, BaseboardNum)
        EXPECT_EQ(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].UA, 3000.0)
        EXPECT_NEAR(state.dataBaseboardRadiator.baseboards[BaseboardNum - 1].WaterVolFlowRateMax, 7.29095E-05, 0.0000001)
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE4-1 BASEBOARD, "
                                                 "Design Size Maximum Water Flow Rate [m3/s], 7.29095E-05",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE4-1 BASEBOARD, "
                                                 "Design Size Heating Load [W], 3000.00",
                                                 False))
        EXPECT_TRUE(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:Convective:Water, SPACE4-1 BASEBOARD, "
                                                 "Design Size U-Factor Times Area Value [W/K], 3000.00"))

@TestFixture
class BaseboardConvWater_checkForZoneSizingTest(EnergyPlusFixture):
    def run(self):
        state.dataBaseboardRadiator.baseboards.allocate(1)
        var thisBB = state.dataBaseboardRadiator.baseboards[0]
        state.dataSize.ZoneSizingRunDone = False
        var error_string: String = delimited_string(["   ** Severe  ** For autosizing of ZoneHVAC:Baseboard:Convective:Water , a zone sizing run must be done.\n"
                                                      "   **   ~~~   ** No \"Sizing:Zone\" objects were entered.\n"
                                                      "   **   ~~~   ** The \"SimulationControl\" object did not have the field \"Do Zone Sizing Calculation\" set to Yes.\n"
                                                      "   **  Fatal  ** Program terminates due to previously shown condition(s).\n"
                                                      "   ...Summary of Errors that led to program termination:\n"
                                                      "   ..... Reference severe error count=1\n"
                                                      "   ..... Last severe error=For autosizing of ZoneHVAC:Baseboard:Convective:Water , a zone sizing run must be done."])
        thisBB.UA = DataSizing.AutoSize
        thisBB.WaterVolFlowRateMax = 0.001
        thisBB.HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
        thisBB.ScaledHeatingCapacity = 1.0
        ASSERT_THROW(thisBB.checkForZoneSizing(state), runtime_error)
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataErrTracking.TotalSevereErrors = 0
        thisBB.UA = 0.5
        thisBB.WaterVolFlowRateMax = DataSizing.AutoSize
        thisBB.HeatingCapMethod = DataSizing.FractionOfAutosizedHeatingCapacity
        thisBB.ScaledHeatingCapacity = 1.0
        ASSERT_THROW(thisBB.checkForZoneSizing(state), runtime_error)
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataErrTracking.TotalSevereErrors = 0
        thisBB.UA = 0.5
        thisBB.WaterVolFlowRateMax = 0.001
        thisBB.HeatingCapMethod = DataSizing.HeatingDesignCapacity
        thisBB.ScaledHeatingCapacity = DataSizing.AutoSize
        ASSERT_THROW(thisBB.checkForZoneSizing(state), runtime_error)
        EXPECT_TRUE(compare_err_stream(error_string, True))
        state.dataErrTracking.TotalSevereErrors = 0
        thisBB.UA = 0.5
        thisBB.WaterVolFlowRateMax = 0.001
        thisBB.HeatingCapMethod = DataSizing.HeatingDesignCapacity
        thisBB.ScaledHeatingCapacity = 1000.0
        thisBB.checkForZoneSizing(state)
        EXPECT_TRUE(compare_err_stream("", True))
        state.dataErrTracking.TotalSevereErrors = 0
        thisBB.UA = 0.5
        thisBB.WaterVolFlowRateMax = 0.001
        thisBB.HeatingCapMethod = DataSizing.CapacityPerFloorArea
        thisBB.ScaledHeatingCapacity = DataSizing.AutoSize
        thisBB.checkForZoneSizing(state)
        EXPECT_TRUE(compare_err_stream("", True))