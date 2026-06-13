// Mojo translation of DataPlant.unit.cc
// Faithful 1:1 translation, no refactoring.

from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.PlantUtilities import PlantUtilities
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

@fixture
def DataPlant_AnyPlantLoopSidesNeedSim() :
    state.dataPlnt.TotNumLoops = 3
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    EXPECT_TRUE(PlantUtilities.AnyPlantLoopSidesNeedSim(state))
    PlantUtilities.SetAllPlantSimFlagsToValue(state, False)
    EXPECT_FALSE(PlantUtilities.AnyPlantLoopSidesNeedSim(state))


@fixture
def DataPlant_verifyTwoNodeNumsOnSamePlantLoop() :
    if state.dataPlnt.PlantLoop.allocated():
        state.dataPlnt.PlantLoop.deallocate()
    
    state.dataPlnt.TotNumLoops = 2
    state.dataPlnt.PlantLoop.allocate(2)
    
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp.allocate(1)
    
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.allocate(1)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.allocate(1)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch.allocate(1)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp.allocate(1)
    
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumOut = 0
    
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = 0
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumOut = 0
    
    const nodeNumA: Int = 1
    const nodeNumB: Int = 2
    
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumIn = 2
    EXPECT_TRUE(PlantUtilities.verifyTwoNodeNumsOnSamePlantLoop(state, nodeNumA, nodeNumB))
    
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp[0].NodeNumIn = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 1
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = 2
    EXPECT_FALSE(PlantUtilities.verifyTwoNodeNumsOnSamePlantLoop(state, nodeNumA, nodeNumB))
    
    state.dataPlnt.TotNumLoops = 0
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.deallocate()
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.deallocate()
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp.deallocate()
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Supply).Branch.deallocate()
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp.deallocate()
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch.deallocate()
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch[0].Comp.deallocate()
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Supply).Branch.deallocate()
    state.dataPlnt.PlantLoop.deallocate()