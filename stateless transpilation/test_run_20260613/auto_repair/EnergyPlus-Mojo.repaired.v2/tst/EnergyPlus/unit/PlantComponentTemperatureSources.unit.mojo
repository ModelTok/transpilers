from gtest import Test, TestFixture, AssertTrue, ExpectEQ, ExpectNEAR, ExpectENUM_EQ
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.Plant.PlantLocation import PlantLocation
from EnergyPlus.PlantComponentTemperatureSources import PlantComponentTemperatureSources, TempSpecType

@fixture
class EnergyPlusFixture:

@TestFixture
class TestPlantComponentTemperatureSource(EnergyPlusFixture):
    def run(self):
        var idf_objects: String = delimited_string([
            "PlantComponent:TemperatureSource,",
            " FluidSource,             !- Name",
            " FluidSource Inlet Node,  !- Inlet Node",
            " FluidSource Outlet Node, !- Outlet Node",
            " 0.001,                   !- Design Volume Flow Rate {m3/s}",
            " Constant,                !- Temperature Specification Type",
            " 8,                       !- Source Temperature {C}",
            " ;                        !- Source Temperature Schedule Name"
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state)
        state.dataPlnt.TotNumLoops = 1
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.WaterSource
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Name = "FLUIDSOURCE"
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = 1
        var myLoad: Float64 = 0.0
        var firstHVACIteration: Bool
        var runFlag: Bool = False
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        PlantComponentTemperatureSources.GetWaterSourceInput(state)
        ExpectEQ(1, state.dataPlantCompTempSrc.WaterSource.size())
        var waterSource1 = state.dataPlantCompTempSrc.WaterSource[0]
        ExpectENUM_EQ(TempSpecType.Constant, waterSource1.tempSpecType)
        ExpectEQ(1, waterSource1.InletNodeNum)
        ExpectEQ(2, waterSource1.OutletNodeNum)
        firstHVACIteration = True
        var loc: PlantLocation
        waterSource1.simulate(state, loc, firstHVACIteration, myLoad, runFlag)
        ExpectNEAR(0.0, waterSource1.MassFlowRate, 0.00001)
        firstHVACIteration = False
        myLoad = 1696.55
        waterSource1.simulate(state, loc, firstHVACIteration, myLoad, runFlag)
        ExpectNEAR(0.05, waterSource1.MassFlowRate, 0.001)