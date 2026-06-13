from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_TRUE, EXPECT_NEAR, ASSERT_TRUE
from EnergyPlus.BoilerSteam import BoilerSteam, BoilerSpecs, GetBoilerInput
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchAirLoopPlant import DataBranchAirLoopPlant, ControlType
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobalConstants import Constant
from EnergyPlus.DataSizing import DataSizing, AutoSize
from EnergyPlus.Plant.DataPlant import DataPlant, PlantLocation, LoopSideLocation, LoopDemandCalcScheme, PlantEquipmentType
from EnergyPlus.Psychrometrics import Psychrometrics
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

using EnergyPlus
using EnergyPlus.BoilerSteam
using EnergyPlus.DataBranchAirLoopPlant
using EnergyPlus.DataEnvironment
using EnergyPlus.DataSizing
using EnergyPlus.Psychrometrics

@fixture
class BoilerSteam_GetInput(Test[EnergyPlusFixture]):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  Boiler:Steam,                                                                                            ",
            "    Steam Boiler Plant Boiler,  !- Name                                                                    ",
            "    NaturalGas,                !- Fuel Type                                                                ",
            "    160000,                    !- Maximum Operating Pressure{ Pa }                                         ",
            "    0.8,                       !- Theoretical Efficiency                                                   ",
            "    115,                       !- Design Outlet Steam Temperature{ C }                                     ",
            "    autosize,                  !- Nominal Capacity{ W }                                                    ",
            "    0.00001,                   !- Minimum Part Load Ratio                                                  ",
            "    1.0,                       !- Maximum Part Load Ratio                                                  ",
            "    0.2,                       !- Optimum Part Load Ratio                                                  ",
            "    0.8,                       !- Coefficient 1 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 2 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 3 of Fuel Use Function of Part Load Ratio Curve              ",
            "    Steam Boiler Plant Boiler Inlet Node,  !- Water Inlet Node Name                                        ",
            "    Steam Boiler Plant Boiler Outlet Node;  !- Steam Outlet Node Name                                      ",
        ])
        ASSERT_TRUE(process_idf(idf_objects, false))
        state.init_state(state)
        GetBoilerInput(state)
        var thisBoiler = state.dataBoilerSteam.Boiler[(int)(state.dataBoilerSteam.Boiler.size())]
        EXPECT_EQ(thisBoiler.Name, "STEAM BOILER PLANT BOILER")
        EXPECT_ENUM_EQ(thisBoiler.FuelType, Constant.eFuel.NaturalGas)
        EXPECT_EQ(thisBoiler.BoilerMaxOperPress, 160000)
        EXPECT_EQ(thisBoiler.NomEffic, 0.8)
        EXPECT_EQ(thisBoiler.TempUpLimitBoilerOut, 115)
        EXPECT_EQ(thisBoiler.NomCap, AutoSize)
        EXPECT_EQ(thisBoiler.MinPartLoadRat, 0.00001)
        EXPECT_EQ(thisBoiler.MaxPartLoadRat, 1.0)
        EXPECT_EQ(thisBoiler.OptPartLoadRat, 0.2)
        EXPECT_EQ(thisBoiler.FullLoadCoef[0], 0.8)
        EXPECT_EQ(thisBoiler.FullLoadCoef[1], 0.1)
        EXPECT_EQ(thisBoiler.FullLoadCoef[2], 0.1)
        EXPECT_EQ(thisBoiler.SizFac, 1.0)

@fixture
class BoilerSteam_Simulate(Test[EnergyPlusFixture]):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  Boiler:Steam,                                                                                            ",
            "    Boiler,                    !- Name                                                                    ",
            "    NaturalGas,                !- Fuel Type                                                                ",
            "    160000,                    !- Maximum Operating Pressure{ Pa }                                         ",
            "    0.8,                       !- Theoretical Efficiency                                                   ",
            "    115,                       !- Design Outlet Steam Temperature{ C }                                     ",
            "    1250,                      !- Nominal Capacity{ W }                                                    ",
            "    0.00001,                   !- Minimum Part Load Ratio                                                  ",
            "    1.0,                       !- Maximum Part Load Ratio                                                  ",
            "    0.2,                       !- Optimum Part Load Ratio                                                  ",
            "    0.8,                       !- Coefficient 1 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 2 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 3 of Fuel Use Function of Part Load Ratio Curve              ",
            "    Steam Boiler Plant Boiler Inlet Node,  !- Water Inlet Node Name                                        ",
            "    Steam Boiler Plant Boiler Outlet Node;  !- Steam Outlet Node Name                                      ",
        ])
        ASSERT_TRUE(process_idf(idf_objects, false))
        state.init_state(state)
        var ptr: BoilerSpecs = BoilerSteam.BoilerSpecs.factory(state, "BOILER")
        EXPECT_EQ(ptr.Name, "BOILER")
        var pl: PlantLocation = PlantLocation{1, EnergyPlus.DataPlant.LoopSideLocation.Demand, 1, 1}
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp.allocate(1)
        var max: Float64
        var opt: Float64
        var min: Float64 = 0.0
        ptr.getDesignCapacities(state, pl, max, min, opt)
        EXPECT_NEAR(max, 1250, 1.0)
        EXPECT_NEAR(min, 0.0, 1.0)
        EXPECT_NEAR(opt, 250.0, 1.0)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].TempSetPoint = 2.0
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].MyLoad = 1000
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].ON = true
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = ptr.BoilerInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = ptr.BoilerOutletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type =
            DataPlant.PlantEquipmentType.Boiler_Steam
        state.dataPlnt.PlantLoop[1].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = ptr.Name
        state.dataPlnt.PlantLoop[1].MaxVolFlowRate = 3
        state.dataPlnt.PlantLoop[1].MaxMassFlowRate = 3
        state.dataSize.CurLoopNum = 1
        state.dataLoopNodes.Node[ptr.BoilerOutletNodeNum].MassFlowRateMaxAvail = 5
        state.dataLoopNodes.Node[ptr.BoilerOutletNodeNum].MassFlowRateMax = 5
        state.dataLoopNodes.Node[ptr.BoilerInletNodeNum].Temp = 20
        state.dataLoopNodes.Node[ptr.BoilerInletNodeNum].MassFlowRateMaxAvail = 5
        state.dataLoopNodes.Node[ptr.BoilerInletNodeNum].MassFlowRateMax = 5
        var curLoad: Float64 = 1000.0
        ptr.simulate(state, pl, true, curLoad, true)

@fixture
class BoilerSteam_BoilerEfficiency(Test[EnergyPlusFixture]):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  Boiler:Steam,                                                                                            ",
            "    Steam Boiler Plant Boiler,  !- Name                                                                    ",
            "    NaturalGas,                !- Fuel Type                                                                ",
            "    160000,                    !- Maximum Operating Pressure{ Pa }                                         ",
            "    0.8,                       !- Theoretical Efficiency                                                   ",
            "    115,                       !- Design Outlet Steam Temperature{ C }                                     ",
            "    autosize,                  !- Nominal Capacity{ W }                                                    ",
            "    0.00001,                   !- Minimum Part Load Ratio                                                  ",
            "    1.0,                       !- Maximum Part Load Ratio                                                  ",
            "    0.2,                       !- Optimum Part Load Ratio                                                  ",
            "    0.8,                       !- Coefficient 1 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 2 of Fuel Use Function of Part Load Ratio Curve              ",
            "    0.1,                       !- Coefficient 3 of Fuel Use Function of Part Load Ratio Curve              ",
            "    Steam Boiler Plant Boiler Inlet Node,  !- Water Inlet Node Name                                        ",
            "    Steam Boiler Plant Boiler Outlet Node;  !- Steam Outlet Node Name                                      ",
        ])
        EXPECT_TRUE(process_idf(idf_objects, false))
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.init_state(state)
        var RunFlag: Bool = true
        var MyLoad: Float64 = 1000000.0
        state.dataPlnt.TotNumLoops = 2
        state.dataEnvrn.OutBaroPress = 101325.0
        state.dataEnvrn.StdRhoAir = 1.20
        state.dataGlobal.TimeStep = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        for l in range(1, state.dataPlnt.TotNumLoops + 1):
            var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetBoilerInput(state)
        var thisBoiler = state.dataBoilerSteam.Boiler[(int)(state.dataBoilerSteam.Boiler.size())]
        state.dataPlnt.PlantLoop[1].Name = "SteamLoop"
        state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        state.dataPlnt.PlantLoop[1].FluidName = "STEAM"
        state.dataPlnt.PlantLoop[1].steam = Fluid.GetSteam(state)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = thisBoiler.Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Boiler_Steam
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = thisBoiler.BoilerInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = thisBoiler.BoilerOutletNodeNum
        state.dataSize.PlantSizData.allocate(1)
        state.dataSize.PlantSizData[1].DesVolFlowRate = 0.1
        state.dataSize.PlantSizData[1].DeltaT = 10
        state.dataPlnt.PlantFirstSizesOkayToFinalize = true
        state.dataPlnt.PlantFirstSizesOkayToReport = true
        state.dataPlnt.PlantFinalSizesOkayToReport = true
        state.dataGlobal.BeginEnvrnFlag = true
        thisBoiler.initialize(state)
        thisBoiler.calculate(state, MyLoad, RunFlag, DataBranchAirLoopPlant.ControlType.SeriesActive)
        EXPECT_EQ(thisBoiler.BoilerLoad, 1000000)
        EXPECT_NEAR(thisBoiler.FuelUsed, 1562498, 1.0)
        var ExpectedBoilerEff: Float64 = thisBoiler.BoilerLoad / thisBoiler.FuelUsed
        EXPECT_NEAR(thisBoiler.BoilerEff, ExpectedBoilerEff, 0.01)