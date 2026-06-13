from gtest import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Construction import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.SwimmingPool import *

using EnergyPlus
using EnergyPlus.SwimmingPool
using EnergyPlus.DataSurfaces
using EnergyPlus.DataPlant

@fixture(EnergyPlusFixture)
class SwimmingPool_MakeUpWaterVolFlow:
    def run(self):
        EXPECT_EQ(0.05, MakeUpWaterVolFlowFunct(5, 100))
        EXPECT_NEAR(0.00392, MakeUpWaterVolFlowFunct(0.1, 25.5), .0001)
        EXPECT_EQ(-180, MakeUpWaterVolFlowFunct(-9, .05))
        EXPECT_NE(10, MakeUpWaterVolFlowFunct(10, 0.01))
        EXPECT_EQ(0.05, MakeUpWaterVolFunct(5, 100))
        EXPECT_NEAR(0.00392, MakeUpWaterVolFunct(0.1, 25.5), .0001)
        EXPECT_EQ(-180, MakeUpWaterVolFunct(-9, .05))
        EXPECT_NE(10, MakeUpWaterVolFunct(10, 0.01))

@fixture(EnergyPlusFixture)
class SwimmingPool_CalcSwimmingPoolEvap:
    def run(self):
        var SurfNum: Int
        var PoolNum: Int
        var MAT: Float64
        var HumRat: Float64
        var EvapRate: Float64
        state.dataSwimmingPools.NumSwimmingPools = 1
        state.dataSwimmingPools.Pool.allocate(1)
        state.dataSurface.Surface.allocate(1)
        state.dataSurface.Surface[0].Area = 10.0
        SurfNum = 1
        PoolNum = 1
        state.dataEnvrn.OutBaroPress = 101400.0
        var thisPool = state.dataSwimmingPools.Pool[PoolNum - 1]
        state.dataSwimmingPools.Pool[PoolNum - 1].PoolWaterTemp = 30.0
        MAT = 20.0
        HumRat = 0.005
        state.dataSwimmingPools.Pool[PoolNum - 1].CurActivityFactor = 0.5
        state.dataSwimmingPools.Pool[PoolNum - 1].CurCoverEvapFac = 0.3
        thisPool.calcSwimmingPoolEvap(*state, EvapRate, SurfNum, MAT, HumRat)
        EXPECT_NEAR(0.000207, EvapRate, 0.000001)
        EXPECT_NEAR(4250.0, state.dataSwimmingPools.Pool[PoolNum - 1].SatPressPoolWaterTemp, 10.0)
        EXPECT_NEAR(810.0, state.dataSwimmingPools.Pool[PoolNum - 1].PartPressZoneAirTemp, 10.0)
        state.dataSwimmingPools.Pool[PoolNum - 1].PoolWaterTemp = 27.0
        MAT = 22.0
        HumRat = 0.010
        state.dataSwimmingPools.Pool[PoolNum - 1].CurActivityFactor = 1.0
        state.dataSwimmingPools.Pool[PoolNum - 1].CurCoverEvapFac = 1.0
        thisPool.calcSwimmingPoolEvap(*state, EvapRate, SurfNum, MAT, HumRat)
        EXPECT_NEAR(0.000788, EvapRate, 0.000001)
        EXPECT_NEAR(3570.0, state.dataSwimmingPools.Pool[PoolNum - 1].SatPressPoolWaterTemp, 10.0)
        EXPECT_NEAR(1600.0, state.dataSwimmingPools.Pool[PoolNum - 1].PartPressZoneAirTemp, 10.0)

@fixture(EnergyPlusFixture)
class SwimmingPool_InitSwimmingPoolPlantLoopIndex:
    def run(self):
        state.dataSwimmingPools.NumSwimmingPools = 2
        state.dataPlnt.TotNumLoops = 2
        state.dataSwimmingPools.Pool.allocate(state.dataSwimmingPools.NumSwimmingPools)
        state.dataSwimmingPools.Pool[0].Name = "FirstPool"
        state.dataSwimmingPools.Pool[1].Name = "SecondPool"
        state.dataSwimmingPools.Pool[0].WaterInletNode = 1
        state.dataSwimmingPools.Pool[1].WaterInletNode = 11
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.SwimmingPool_Indoor
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = "FirstPool"
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.SwimmingPool_Indoor
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Name = "SecondPool"
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = 11
        state.dataSwimmingPools.Pool[0].initSwimmingPoolPlantLoopIndex(*state)
        EXPECT_EQ(state.dataSwimmingPools.Pool[0].HWplantLoc.loopNum, 1)
        EXPECT_ENUM_EQ(state.dataSwimmingPools.Pool[0].HWplantLoc.loopSideNum, DataPlant.LoopSideLocation.Demand)
        EXPECT_EQ(state.dataSwimmingPools.Pool[0].HWplantLoc.branchNum, 1)
        EXPECT_EQ(state.dataSwimmingPools.Pool[0].HWplantLoc.compNum, 1)
        state.dataSwimmingPools.Pool[0].MyPlantScanFlagPool = true
        state.dataSwimmingPools.Pool[1].initSwimmingPoolPlantLoopIndex(*state)
        EXPECT_EQ(state.dataSwimmingPools.Pool[1].HWplantLoc.loopNum, 2)
        EXPECT_ENUM_EQ(state.dataSwimmingPools.Pool[1].HWplantLoc.loopSideNum, DataPlant.LoopSideLocation.Supply)
        EXPECT_EQ(state.dataSwimmingPools.Pool[1].HWplantLoc.branchNum, 1)
        EXPECT_EQ(state.dataSwimmingPools.Pool[1].HWplantLoc.compNum, 1)

@fixture(EnergyPlusFixture)
class SwimmingPool_InitSwimmingPoolPlantNodeFlow:
    def run(self):
        var PoolNum: Int = 1
        state.dataSwimmingPools.NumSwimmingPools = 1
        state.dataPlnt.TotNumLoops = 1
        state.dataSwimmingPools.Pool.allocate(state.dataSwimmingPools.NumSwimmingPools)
        state.dataSwimmingPools.Pool[0].Name = "FirstPool"
        state.dataSwimmingPools.Pool[0].WaterInletNode = 1
        state.dataSwimmingPools.Pool[0].WaterOutletNode = 2
        state.dataSwimmingPools.Pool[0].HWplantLoc.loopNum = 1
        state.dataSwimmingPools.Pool[0].HWplantLoc.loopSideNum = DataPlant.LoopSideLocation.Demand
        state.dataSwimmingPools.Pool[0].HWplantLoc.branchNum = 1
        state.dataSwimmingPools.Pool[0].HWplantLoc.compNum = 1
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.SwimmingPool_Indoor
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = "FirstPool"
        state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 1
        state.dataLoopNodes.Node.allocate(2)
        var thisPool = state.dataSwimmingPools.Pool[PoolNum - 1]
        state.dataSwimmingPools.Pool[0].WaterMassFlowRate = 0.75
        state.dataSwimmingPools.Pool[0].WaterMassFlowRateMax = 0.75
        state.dataSwimmingPools.Pool[0].WaterVolFlowMax = 0.00075
        state.dataSwimmingPools.Pool[0].MyPlantScanFlagPool = false
        state.dataSize.SaveNumPlantComps = 0
        state.dataSize.CompDesWaterFlow.deallocate()
        state.dataLoopNodes.Node[0].MassFlowRate = 0.0
        state.dataLoopNodes.Node[0].MassFlowRateMax = 0.0
        thisPool.initSwimmingPoolPlantNodeFlow(*state)
        EXPECT_EQ(state.dataSize.CompDesWaterFlow[0].SupNode, 1)
        EXPECT_EQ(state.dataSize.CompDesWaterFlow[0].DesVolFlowRate, 0.00075)
        state.dataSwimmingPools.Pool[0].WaterMassFlowRate = 0.5
        state.dataSwimmingPools.Pool[0].WaterMassFlowRateMax = 2.0
        state.dataSwimmingPools.Pool[0].WaterVolFlowMax = 0.002
        state.dataSwimmingPools.Pool[0].MyPlantScanFlagPool = false
        state.dataSize.SaveNumPlantComps = 0
        state.dataSize.CompDesWaterFlow.deallocate()
        state.dataLoopNodes.Node[0].MassFlowRate = 0.0
        state.dataLoopNodes.Node[0].MassFlowRateMax = 0.0
        thisPool.initSwimmingPoolPlantNodeFlow(*state)
        EXPECT_EQ(state.dataSize.CompDesWaterFlow[0].SupNode, 1)
        EXPECT_EQ(state.dataSize.CompDesWaterFlow[0].DesVolFlowRate, 0.002)

@fixture(EnergyPlusFixture)
class SwimmingPool_ErrorCheckSetupPoolSurfaceTest:
    def run(self):
        state.dataSwimmingPools.NumSwimmingPools = 1
        state.dataSwimmingPools.Pool.allocate(state.dataSwimmingPools.NumSwimmingPools)
        state.dataSurface.Surface.allocate(1)
        state.dataConstruction.Construct.allocate(1)
        state.dataSurface.SurfIsPool.allocate(1)
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool.allocate(1)
        state.dataSurface.intMovInsuls.allocate(1)
        var Alpha1: StringLiteral = "FirstString"
        var Alpha2: StringLiteral = "SecondString"
        var AlphaField2: StringLiteral = "cSecondString"
        var ErrFnd: Bool = False
        var poolReference = state.dataSwimmingPools.Pool[0]
        ErrFnd = False
        poolReference.SurfacePtr = 0
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = True
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CondFD
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Class = DataSurfaces.SurfaceClass.Window
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Class = DataSurfaces.SurfaceClass.Floor
        state.dataSurface.intMovInsuls[poolReference.SurfacePtr - 1].matNum = 1
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Class = DataSurfaces.SurfaceClass.Floor
        state.dataSurface.intMovInsuls[poolReference.SurfacePtr - 1].matNum = 1
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Construction = 1
        state.dataConstruction.Construct[state.dataSurface.Surface[poolReference.SurfacePtr - 1].Construction - 1].SourceSinkPresent = True
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Class = DataSurfaces.SurfaceClass.Wall
        state.dataSurface.intMovInsuls[poolReference.SurfacePtr - 1].matNum = 1
        state.dataConstruction.Construct[state.dataSurface.Surface[poolReference.SurfacePtr - 1].Construction - 1].SourceSinkPresent = False
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_TRUE(ErrFnd)
        ErrFnd = False
        poolReference.SurfacePtr = 1
        state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1] = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].HeatTransferAlgorithm = DataSurfaces.HeatTransferModel.CTF
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Class = DataSurfaces.SurfaceClass.Floor
        state.dataSurface.intMovInsuls[poolReference.SurfacePtr - 1].matNum = 0
        state.dataConstruction.Construct[state.dataSurface.Surface[poolReference.SurfacePtr - 1].Construction - 1].SourceSinkPresent = False
        state.dataSurface.Surface[poolReference.SurfacePtr - 1].Zone = 7
        state.dataSurface.SurfIsPool[poolReference.SurfacePtr - 1] = False
        poolReference.ZonePtr = 0
        poolReference.ErrorCheckSetupPoolSurface(*state, Alpha1, Alpha2, AlphaField2, ErrFnd)
        EXPECT_FALSE(ErrFnd)
        EXPECT_TRUE(state.dataSurface.SurfIsRadSurfOrVentSlabOrPool[poolReference.SurfacePtr - 1])
        EXPECT_TRUE(state.dataSurface.SurfIsPool[poolReference.SurfacePtr - 1])
        EXPECT_EQ(state.dataSurface.Surface[poolReference.SurfacePtr - 1].Zone, poolReference.ZonePtr)

@fixture(EnergyPlusFixture)
class SwimmingPool_MultiplePoolUpdatePoolSourceValAvgTest:
    def run(self):
        var PoolData = state.dataSwimmingPools
        var SurfData = state.dataSurface
        var HBFanData = state.dataHeatBalFanSys
        var closeEnough: Float64 = 0.00001
        PoolData.NumSwimmingPools = 2
        PoolData.Pool.allocate(PoolData.NumSwimmingPools)
        var Pool1Data = state.dataSwimmingPools.Pool[0]
        var Pool2Data = state.dataSwimmingPools.Pool[1]
        SurfData.TotSurfaces = 2
        SurfData.Surface.allocate(SurfData.TotSurfaces)
        var noResult: Float64 = -9999.0
        HBFanData.QPoolSurfNumerator.allocate(SurfData.TotSurfaces)
        HBFanData.QPoolSurfNumerator = noResult
        HBFanData.PoolHeatTransCoefs.allocate(SurfData.TotSurfaces)
        HBFanData.PoolHeatTransCoefs = noResult
        SurfData.Surface[0].ExtBoundCond = 0
        SurfData.Surface[1].ExtBoundCond = 0
        Pool1Data.SurfacePtr = 1
        Pool2Data.SurfacePtr = 2
        Pool1Data.QPoolSrcAvg = 0.0
        Pool1Data.HeatTransCoefsAvg = 0.0
        Pool2Data.QPoolSrcAvg = 0.0
        Pool2Data.HeatTransCoefsAvg = 0.0
        var poolOnFlag: Bool = False
        UpdatePoolSourceValAvg(*state, poolOnFlag)
        EXPECT_FALSE(poolOnFlag)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[0], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[1], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[0], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[1], 0.0, closeEnough)
        Pool1Data.QPoolSrcAvg = 100.0
        Pool1Data.HeatTransCoefsAvg = 10.0
        Pool2Data.QPoolSrcAvg = 0.0
        Pool2Data.HeatTransCoefsAvg = 0.0
        HBFanData.QPoolSurfNumerator = noResult
        HBFanData.PoolHeatTransCoefs = noResult
        poolOnFlag = False
        UpdatePoolSourceValAvg(*state, poolOnFlag)
        EXPECT_TRUE(poolOnFlag)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[0], Pool1Data.QPoolSrcAvg, closeEnough)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[1], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[0], Pool1Data.HeatTransCoefsAvg, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[1], 0.0, closeEnough)
        Pool1Data.QPoolSrcAvg = 0.0
        Pool1Data.HeatTransCoefsAvg = 0.0
        Pool2Data.QPoolSrcAvg = 200.0
        Pool2Data.HeatTransCoefsAvg = 20.0
        HBFanData.QPoolSurfNumerator = noResult
        HBFanData.PoolHeatTransCoefs = noResult
        poolOnFlag = False
        UpdatePoolSourceValAvg(*state, poolOnFlag)
        EXPECT_TRUE(poolOnFlag)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[0], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[1], Pool2Data.QPoolSrcAvg, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[0], 0.0, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[1], Pool2Data.HeatTransCoefsAvg, closeEnough)
        Pool1Data.QPoolSrcAvg = 100.0
        Pool1Data.HeatTransCoefsAvg = 10.0
        Pool2Data.QPoolSrcAvg = 200.0
        Pool2Data.HeatTransCoefsAvg = 20.0
        HBFanData.QPoolSurfNumerator = noResult
        HBFanData.PoolHeatTransCoefs = noResult
        poolOnFlag = False
        UpdatePoolSourceValAvg(*state, poolOnFlag)
        EXPECT_TRUE(poolOnFlag)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[0], Pool1Data.QPoolSrcAvg, closeEnough)
        EXPECT_NEAR(HBFanData.QPoolSurfNumerator[1], Pool2Data.QPoolSrcAvg, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[0], Pool1Data.HeatTransCoefsAvg, closeEnough)
        EXPECT_NEAR(HBFanData.PoolHeatTransCoefs[1], Pool2Data.HeatTransCoefsAvg, closeEnough)

@fixture(EnergyPlusFixture)
class SwimmingPool_factoryTest:
    def run(self):
        state.dataSwimmingPools.getSwimmingPoolInput = False
        state.dataSwimmingPools.NumSwimmingPools = 4
        state.dataSwimmingPools.Pool.allocate(state.dataSwimmingPools.NumSwimmingPools)
        var poolData = state.dataSwimmingPools.Pool
        poolData[0].Name = "Schwimmbad Nummer Eins"
        poolData[1].Name = "Schwimmbad Nummer Zwei"
        poolData[2].Name = "Schwimmbad Nummer Drei"
        poolData[3].Name = "Schwimmbad Nummer Vier"
        var factoryResult: SwimmingPoolData = SwimmingPoolData.factory(*state, poolData[0].Name)
        EXPECT_NE(factoryResult, None)
        factoryResult = SwimmingPoolData.factory(*state, poolData[1].Name)
        EXPECT_NE(factoryResult, None)
        factoryResult = SwimmingPoolData.factory(*state, poolData[2].Name)
        EXPECT_NE(factoryResult, None)
        factoryResult = SwimmingPoolData.factory(*state, poolData[3].Name)
        EXPECT_NE(factoryResult, None)

@fixture(EnergyPlusFixture)
class SwimmingPool_reportTest:
    def run(self):
        var closeEnough: Float64 = 0.000001
        var myPool: SwimmingPoolData
        state.init_state(*state)
        myPool.Name = "This Pool"
        myPool.glycol = Fluid.GetWater(*state)
        myPool.SurfacePtr = 1
        state.dataHeatBalSurf.SurfInsideTempHist.allocate(1)
        state.dataHeatBalSurf.SurfInsideTempHist[0].dimension(1, 0)
        state.dataHeatBalSurf.SurfInsideTempHist[0][0] = 10.0
        myPool.WaterMassFlowRate = 0.001
        myPool.WaterInletTemp = 40.0
        myPool.MiscPowerFactor = 1000.0
        myPool.RadConvertToConvect = 0.5
        state.dataSurface.Surface.allocate(1)
        state.dataSurface.Surface[0].Area = 5.0
        state.dataHVACGlobal.TimeStepSysSec = 60.0
        myPool.MiscEquipPower = 0.12
        myPool.MakeUpWaterMassFlowRate = 0.1
        myPool.EvapHeatLossRate = 0.016
        myPool.report(*state)
        var expectedHeatPower: Float64 = 125.73
        var expectedMiscEquipPower: Float64 = 0.0010003
        var expectedRadConvertToConvectRep: Float64 = 2.5
        var expectedMiscEquipEnergy: Float64 = 0.060018
        var expectedHeatEnergy: Float64 = 7543.8
        var expectedMakeUpWaterMass: Float64 = 6.0
        var expectedEvapEnergyLoss: Float64 = 0.96
        var expectedMakeUpWaterVolFlowRate: Float64 = 0.0001003
        var expectedMakeUpWaterVol: Float64 = 0.0060018
        EXPECT_NEAR(state.dataHeatBalSurf.SurfInsideTempHist[0][0], myPool.PoolWaterTemp, closeEnough)
        EXPECT_NEAR(expectedHeatPower, myPool.HeatPower, closeEnough)
        EXPECT_NEAR(expectedMiscEquipPower, myPool.MiscEquipPower, closeEnough)
        EXPECT_NEAR(expectedRadConvertToConvectRep, myPool.RadConvertToConvectRep, closeEnough)
        EXPECT_NEAR(expectedMiscEquipEnergy, myPool.MiscEquipEnergy, closeEnough)
        EXPECT_NEAR(expectedHeatEnergy, myPool.HeatEnergy, closeEnough)
        EXPECT_NEAR(expectedMakeUpWaterMass, myPool.MakeUpWaterMass, closeEnough)
        EXPECT_NEAR(expectedEvapEnergyLoss, myPool.EvapEnergyLoss, closeEnough)
        EXPECT_NEAR(expectedMakeUpWaterVolFlowRate, myPool.MakeUpWaterVolFlowRate, closeEnough)
        EXPECT_NEAR(expectedMakeUpWaterVol, myPool.MakeUpWaterVol, closeEnough)

@fixture(EnergyPlusFixture)
class SwimmingPool_calcMassFlowRateTest:
    def run(self):
        var closeEnough: Float64 = 0.00001
        var tPoolWater: Float64
        var tInletWaterLoop: Float64
        var calculatedFlowRate: Float64
        var expectedAnswer: Float64
        var testPool: SwimmingPoolData
        state.dataHVACGlobal.TimeStepSysSec = 60.0
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 20.0
        tPoolWater = 25.0
        tInletWaterLoop = 30.0
        expectedAnswer = 11.111111
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)
        calculatedFlowRate = 0.0
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 10.0
        tPoolWater = 25.0
        tInletWaterLoop = 30.0
        expectedAnswer = 10.0
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)
        calculatedFlowRate = -9999.9
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 10.0
        tPoolWater = 32.0
        tInletWaterLoop = 30.0
        expectedAnswer = 0.0
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)
        calculatedFlowRate = -9999.9
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 20.0
        tPoolWater = 25.0
        tInletWaterLoop = 27.0
        expectedAnswer = 20.0
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)
        calculatedFlowRate = -9999.9
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 20.0
        tPoolWater = 32.0
        tInletWaterLoop = 27.0
        expectedAnswer = 0.0
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)
        calculatedFlowRate = -9999.9
        testPool.CurSetPtTemp = 27.0
        testPool.WaterMass = 1000.0
        testPool.WaterMassFlowRateMax = 17.0
        tPoolWater = 25.0
        tInletWaterLoop = 26.0
        expectedAnswer = 17.0
        testPool.calcMassFlowRate(*state, calculatedFlowRate, tPoolWater, tInletWaterLoop)
        EXPECT_NEAR(calculatedFlowRate, expectedAnswer, closeEnough)