from ..Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string
from ......src.EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ......src.EnergyPlus.PipeHeatTransfer import PipeHeatTransfer
from ......src.EnergyPlus.Pipes import Pipes
from ......src.EnergyPlus.Plant.DataPlant import DataPlant
from ......src.EnergyPlus.PlantUtilities import PlantUtilities
from ......src.EnergyPlus.Fluid import Fluid
from testing import expect_equal, expect_true

def TestPipesInput():
    alias idf_objects = delimited_string(
        [
            "Pipe:Adiabatic,",
            " Pipe Name,           !- Name",
            " Pipe Inlet Node,     !- Inlet Node Name",
            " Pipe Outlet Node;    !- Outlet Node Name",
            "Pipe:Adiabatic:Steam,",
            " Pipe Name 2,           !- Name",
            " Pipe Inlet Node 2,     !- Inlet Node Name",
            " Pipe Outlet Node 2;    !- Outlet Node Name",
        ]
    )
    expect_true(process_idf(idf_objects))
    Pipes.GetPipeInput(*state)
    expect_equal(2, state.dataPipes.LocalPipe.size())
    expect_equal(DataPlant.PlantEquipmentType.Pipe, state.dataPipes.LocalPipe[0].Type)
    expect_equal(DataPlant.PlantEquipmentType.PipeSteam, state.dataPipes.LocalPipe[1].Type)

def CalcPipeHeatTransCoef():
    state.init_state(state)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataLoopNodes.Node.allocate(2)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumOut = 2
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = "Indoor Pipe"
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.PipeInterior
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 0  // just skip the supply side search
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPipeHT.nsvNumOfPipeHT = 1
    state.dataPipeHT.PipeHT.allocate(state.dataPipeHT.nsvNumOfPipeHT)
    state.dataPipeHT.PipeHTUniqueNames.reserve(UInt(state.dataPipeHT.nsvNumOfPipeHT))
    state.dataPipeHT.GetPipeInputFlag = false
    var pipe = state.dataPipeHT.PipeHT[0]
    pipe.Name = "Indoor Pipe"
    pipe.Type = DataPlant.PlantEquipmentType.PipeInterior
    pipe.Construction = "Pipe construction"
    pipe.ConstructionNum = 1
    pipe.InletNodeNum = 1
    pipe.OutletNodeNum = 2
    alias NumPipeSections = 20
    pipe.FluidTemp.allocate({0, NumPipeSections})
    pipe.FluidTemp = 7.0
    var errFlag = False
    PlantUtilities.ScanPlantLoopsForObject(state, pipe.Name, pipe.Type, pipe.plantLoc, errFlag)
    expect_true(not errFlag)
    expect_equal(1, pipe.plantLoc.loopNum)
    expect_equal(DataPlant.LoopSideLocation.Demand, pipe.plantLoc.loopSideNum)
    expect_equal(1, pipe.plantLoc.branchNum)
    expect_equal(1, pipe.plantLoc.compNum)
    alias massFlowRate = 0.5
    alias diameter = 0.05
    pipe.CalcPipeHeatTransCoef(state, 1.0, massFlowRate, diameter)
    pipe.CalcPipeHeatTransCoef(state, 65.0, massFlowRate, diameter)