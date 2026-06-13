from gtest import Test, TestFixture, EXPECT_NEAR, EXPECT_EQ, EXPECT_FALSE, EXPECT_TRUE
from ObjexxFCL.Array1D import Array1D
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataContaminantBalance import DataContaminantBalance
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.HVACInterfaceManager import HVACInterfaceManager, UpdateHalfLoopInletTemp, UpdateHVACInterface
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.Plant.PlantManager import PlantManager
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.Data.EnergyPlusData import Constant

@register_passable("trivial")
struct EnergyPlusFixture(TestFixture):

def ExcessiveHeatStorage_Test():
    var state = EnergyPlusData()
    state.init_state(state)
    using DataPlant
    using HVACInterfaceManager
    var TankOutletTemp: Float64
    state.dataHVACGlobal.TimeStepSys = 1
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop = Array1D[DataPlant.PlantLoopData](state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop[0].Mass = 50
    state.dataPlnt.PlantLoop[0].FluidName = "Water"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumOut = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].NodeNumIn = 1
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LastTempInterfaceTankOutlet = 80
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalPumpHeat = 500
    state.dataLoopNodes.Node = Array1D[DataLoopNode.NodeData](state.dataPlnt.TotNumLoops)
    state.dataLoopNodes.Node[0].Temp = 100
    state.dataLoopNodes.Node[0].MassFlowRate = 10
    state.dataPlnt.PlantLoop[0].OutletNodeFlowrate = 10
    UpdateHalfLoopInletTemp(state, 1, DataPlant.LoopSideLocation.Demand, TankOutletTemp)
    PlantManager.UpdateNodeThermalHistory(state)
    EXPECT_NEAR((2928.82 - 500), state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_MdotCpDeltaT, 0.001)
    EXPECT_NEAR(2928.82, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_McpDTdt, 0.001)
    EXPECT_EQ(1, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_CapExcessStorageTime)
    EXPECT_EQ(1, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_TotalTime)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LastTempInterfaceTankOutlet = 120
    UpdateHalfLoopInletTemp(state, 1, DataPlant.LoopSideLocation.Demand, TankOutletTemp)
    PlantManager.UpdateNodeThermalHistory(state)
    EXPECT_NEAR((-588.264 - 500), state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_MdotCpDeltaT, 0.001)
    EXPECT_NEAR(-588.264, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_McpDTdt, 0.001)
    EXPECT_EQ(1, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_CapExcessStorageTime)
    EXPECT_EQ(2, state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].LoopSideInlet_TotalTime)

def UpdateHVACInterface_Test():
    var state = EnergyPlusData()
    using DataPlant
    using HVACInterfaceManager
    var AirLoopNum = 1
    var InletNode = 1
    var OutletNode = 2
    var OutOfToleranceFlag = False
    state.dataHVACInterfaceMgr.TmpRealARR = Array1D[Float64](10)
    state.dataConvergeParams.AirLoopConvergence = Array1D[DataConvergParams.AirLoopConvergenceData](AirLoopNum)
    state.dataLoopNodes.Node = Array1D[DataLoopNode.NodeData](2)
    state.dataLoopNodes.Node[InletNode - 1].MassFlowRate = 0.01
    state.dataLoopNodes.Node[OutletNode - 1].MassFlowRate = 0.01
    state.dataLoopNodes.Node[InletNode - 1].HumRat = 0.001
    state.dataLoopNodes.Node[OutletNode - 1].HumRat = 0.001
    state.dataLoopNodes.Node[InletNode - 1].Temp = 23.0
    state.dataLoopNodes.Node[OutletNode - 1].Temp = 23.0
    state.dataLoopNodes.Node[InletNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(23.0, 0.001)
    state.dataLoopNodes.Node[OutletNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(23.0, 0.001)
    state.dataLoopNodes.Node[InletNode - 1].Press = 101325.0
    state.dataLoopNodes.Node[OutletNode - 1].Press = 101325.0
    state.dataContaminantBalance.Contaminant.CO2Simulation = True
    state.dataContaminantBalance.Contaminant.GenericContamSimulation = True
    state.dataLoopNodes.Node[InletNode - 1].CO2 = 400.0
    state.dataLoopNodes.Node[OutletNode - 1].CO2 = 400.0
    state.dataLoopNodes.Node[InletNode - 1].GenContam = 20.0
    state.dataLoopNodes.Node[OutletNode - 1].GenContam = 20.0
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemDemandSide, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_FALSE(OutOfToleranceFlag)
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[0])
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[0])
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemSupplySideDeck1, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_FALSE(OutOfToleranceFlag)
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[1])
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[1])
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemSupplySideDeck2, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_FALSE(OutOfToleranceFlag)
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[2])
    EXPECT_FALSE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[2])
    state.dataLoopNodes.Node[InletNode - 1].CO2 = 400.0
    state.dataLoopNodes.Node[InletNode - 1].GenContam = 20.0
    state.dataLoopNodes.Node[OutletNode - 1].CO2 = 401.0
    state.dataLoopNodes.Node[OutletNode - 1].GenContam = 20.5
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemDemandSide, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_TRUE(OutOfToleranceFlag)
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[0])
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[0])
    state.dataLoopNodes.Node[InletNode - 1].CO2 = 400.0
    state.dataLoopNodes.Node[InletNode - 1].GenContam = 20.0
    state.dataLoopNodes.Node[OutletNode - 1].CO2 = 401.0
    state.dataLoopNodes.Node[OutletNode - 1].GenContam = 20.5
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemSupplySideDeck1, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_TRUE(OutOfToleranceFlag)
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[1])
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[1])
    state.dataLoopNodes.Node[InletNode - 1].CO2 = 400.0
    state.dataLoopNodes.Node[InletNode - 1].GenContam = 20.0
    state.dataLoopNodes.Node[OutletNode - 1].CO2 = 401.0
    state.dataLoopNodes.Node[OutletNode - 1].GenContam = 20.5
    UpdateHVACInterface(state, AirLoopNum, DataConvergParams.CalledFrom.AirSystemSupplySideDeck2, OutletNode, InletNode, OutOfToleranceFlag)
    EXPECT_TRUE(OutOfToleranceFlag)
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACCO2NotConverged[2])
    EXPECT_TRUE(state.dataConvergeParams.AirLoopConvergence[0].HVACGenContamNotConverged[2])