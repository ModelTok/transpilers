from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataAirSystems import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.EvaporativeFluidCoolers import *
from EnergyPlus.PlantUtilities import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.SimAirServingZones import *
from Fixtures.EnergyPlusFixture import *
from testing import *
from math import *

using EnergyPlus
using EnergyPlus.DataEnvironment
using EnergyPlus.EvaporativeFluidCoolers

// Note: Mojo does not have gtest macros; replaced with assert_approx_equal, etc.

@test
def EvapFluidCoolerSpecs_getDesignCapacitiesTest() -> Unit:
    state.init_state(*state)
    var MaxLoad: Real64
    var MinLoad: Real64
    var OptLoad: Real64
    var ExpectedMaxLoad: Real64
    var ExpectedMinLoad: Real64
    var ExpectedOptLoad: Real64
    state.dataEnvrn.OutDryBulbTemp = 20.0
    state.dataEnvrn.OutHumRat = 0.02
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.OutWetBulbTemp = 8.0
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(*state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].FlowLock = DataPlant.FlowLock.Locked
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].MyLoad = 1.0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].ON = false
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].CurOpSchemeType = DataPlant.OpScheme.Invalid
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantFinalSizesOkayToReport = false
    state.dataSize.SaveNumPlantComps = 0
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(*state)
    state.dataSize.PlantSizData[0].ExitTemp = 20.0
    state.dataEvapFluidCoolers.SimpleEvapFluidCooler.allocate(1)
    var thisEFC = state.dataEvapFluidCoolers.SimpleEvapFluidCooler[0]
    thisEFC.Type = DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd
    thisEFC.MyOneTimeFlag = False
    thisEFC.OneTimeFlagForEachEvapFluidCooler = False
    thisEFC.MyEnvrnFlag = False
    state.dataGlobal.BeginEnvrnFlag = True
    thisEFC.WaterInletNodeNum = 0  // Mojo 0-based: original 1 -> 0
    thisEFC.WaterOutletNodeNum = 1 // original 2 -> 1
    thisEFC.OutdoorAirInletNodeNum = -1 // original 0 -> -1 (invalid node)
    thisEFC.plantLoc.loopNum = 0     // original 1 -> 0
    thisEFC.plantLoc.loopSideNum = DataPlant.LoopSideLocation.Supply
    thisEFC.plantLoc.branchNum = 0   // original 1 -> 0
    thisEFC.plantLoc.compNum = 0     // original 1 -> 0
    PlantUtilities.SetPlantLocationLinks(*state, thisEFC.plantLoc)
    thisEFC.DesignWaterFlowRateWasAutoSized = False
    thisEFC.LowSpeedAirFlowRateWasAutoSized = False
    thisEFC.HighSpeedEvapFluidCoolerUAWasAutoSized = False
    thisEFC.PerformanceInputMethod_Num = PIM.UFactor
    thisEFC.DesignWaterFlowRate = 0.001
    state.dataLoopNodes.Node.allocate(2)
    state.dataLoopNodes.Node[thisEFC.WaterInletNodeNum].Temp = 20.0
    state.dataLoopNodes.Node[0].Temp = 23.0
    state.dataLoopNodes.Node[0].MassFlowRateRequest = 0.05
    state.dataLoopNodes.Node[0].MassFlowRateMinAvail = 0.0
    state.dataLoopNodes.Node[0].MassFlowRateMin = 0.0
    state.dataLoopNodes.Node[0].MassFlowRateMax = 0.05
    state.dataLoopNodes.Node[0].MassFlowRateMaxAvail = 0.05
    MaxLoad = 0.0
    OptLoad = 0.0
    MinLoad = 999.9
    thisEFC.HighSpeedStandardDesignCapacity = 1.0
    thisEFC.HeatRejectCapNomCapSizingRatio = 2.0
    ExpectedMaxLoad = 20902.8677
    ExpectedOptLoad = 10451.4338
    ExpectedMinLoad = 0.0
    var loc = PlantLocation(0, DataPlant.LoopSideLocation.Supply, 0, 0)  // 0-based
    PlantUtilities.SetPlantLocationLinks(*state, loc)
    thisEFC.onInitLoopEquip(*state, loc)
    thisEFC.getDesignCapacities(*state, loc, MaxLoad, MinLoad, OptLoad)
    assert_approx_equal(MaxLoad, ExpectedMaxLoad, 0.01)
    assert_approx_equal(MinLoad, ExpectedMinLoad, 0.01)
    assert_approx_equal(OptLoad, ExpectedOptLoad, 0.01)

@test
def ExerciseSingleSpeedEvapFluidCooler() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidcooler:SingleSpeed,",
        "Big EvaporativeFluidCooler,  !- Name",
        "Condenser EvaporativeFluidcooler Inlet Node,  !- Water Inlet Node Name",
        "Condenser EvaporativeFluidcooler Outlet Node,  !- Water Outlet Node Name",
        "3.02,                    !- Design Air Flow Rate {m3/s}",
        "2250,                    !- Design Air Flow Rate Fan Power {W}",
        "0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "UserSpecifiedDesignCapacity,  !- Performance Input Method",
        ",                        !- Outdoor Air Inlet Node Name",
        ",                        !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "1000,                        !- Standard Design Capacity {W}",
        ",                        !- Design Air Flow Rate U-factor Times Area Value {W/K}",
        "0.001703,                !- Design Water Flow Rate {m3/s}",
        "87921,                   !- User Specified Design Capacity {W}",
        "46.11,                   !- Design Entering Water Temperature {C}",
        "35,                      !- Design Entering Air Temperature {C}",
        "25.6;                    !- Design Entering Air Wet-bulb Temperature {C}"
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(*state)
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(*state)
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    var loc: PlantLocation = PlantLocation(0, EnergyPlus.DataPlant.LoopSideLocation.Supply, 0, 0)
    PlantUtilities.SetPlantLocationLinks(*state, loc)
    var max: Real64
    var opt: Real64
    var min: Real64 = 0.0
    ptr.getDesignCapacities(*state, loc, max, min, opt)
    assert_approx_equal(max, 1250, 1.0)
    assert_approx_equal(min, 0.0, 1.0)
    assert_approx_equal(opt, 1000.0, 1.0)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].TempSetPoint = 2.0
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].MyLoad = 1000
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].ON = true
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = ptr.WaterInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumOut = ptr.WaterOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Name = ptr.Name
    state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 3
    state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 3
    state.dataSize.CurLoopNum = 0  // 1->0 0-based
    state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMaxAvail = 5
    state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMax = 5
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].Temp = 20
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMaxAvail = 5
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMax = 5
    var firstHVAC: Bool = true
    var curLoad: Real64 = 0.0
    ptr.plantLoc.loopNum = 0
    ptr.plantLoc.loopSideNum = EnergyPlus.DataPlant.LoopSideLocation.Supply
    ptr.plantLoc.branchNum = 0
    ptr.plantLoc.compNum = 0
    PlantUtilities.SetPlantLocationLinks(*state, ptr.plantLoc)
    ptr.DesWaterMassFlowRate = 3.141
    ptr.WaterMassFlowRate = 3.141
    ptr.onInitLoopEquip(*state, loc)
    ptr.simulate(*state, loc, firstHVAC, curLoad, true)

@test
def ExerciseTwoSpeedEvapFluidCooler() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidCooler:TwoSpeed,",
        "Central Tower,           !- Name",
        "Central Tower Inlet Node,!- Water Inlet Node Name",
        "Central Tower Outlet Node,  !- Water Outlet Node Name",
        "autosize,                !- High Fan Speed Air Flow Rate {m3/s}",
        "autosize,                !- High Fan Speed Fan Power {W}",
        "autocalculate,           !- Low Fan Speed Air Flow Rate {m3/s}",
        ",                        !- Low Fan Speed Air Flow Rate Sizing Factor",
        "autocalculate,           !- Low Fan Speed Fan Power {W}",
        ",                        !- Low Fan Speed Fan Power Sizing Factor",
        "0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
        ",                        !- Outdoor Air Inlet Node Name",
        "1.25,                    !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "1000,                        !- High Speed Standard Design Capacity {W}",
        "1000,                        !- Low Speed Standard Design Capacity {W}",
        "0.5,                     !- Low Speed Standard Capacity Sizing Factor",
        "autosize,                !- High Fan Speed U-factor Times Area Value {W/K}",
        "autocalculate,           !- Low Fan Speed U-factor Times Area Value {W/K}",
        "0.6,                     !- Low Fan Speed U-Factor Times Area Sizing Factor",
        "autosize,                !- Design Water Flow Rate {m3/s}",
        ",                        !- High Speed User Specified Design Capacity {W}",
        ",                        !- Low Speed User Specified Design Capacity {W}",
        "0.5,                     !- Low Speed User Specified Design Capacity Sizing Factor",
        ",                        !- Design Entering Water Temperature {C}",
        ",                        !- Design Entering Air Temperature {C}",
        ",                        !- Design Entering Air Wet-bulb Temperature {C}",
        "1,                       !- High Speed Sizing Factor",
        "SaturatedExit,           !- Evaporation Loss Mode",
        ",                        !- Evaporation Loss Factor {percent/K}",
        "0.008,                   !- Drift Loss Percent {percent}",
        "ConcentrationRatio,      !- Blowdown Calculation Mode",
        "3;                       !- Blowdown Concentration Ratio"
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(*state)
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd, "CENTRAL TOWER")
    var pl: PlantLocation = PlantLocation(0, EnergyPlus.DataPlant.LoopSideLocation.Supply, 0, 0)
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(*state)
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    var max: Real64
    var opt: Real64
    var min: Real64 = 0.0
    ptr.getDesignCapacities(*state, pl, max, min, opt)
    assert_approx_equal(max, 1250, 1.0)
    assert_approx_equal(min, 0.0, 1.0)
    assert_approx_equal(opt, 1000.0, 1.0)
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].TotalBranches = 1
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].TotalComponents = 1
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].TempSetPoint = 2.0
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].MyLoad = 1000
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].ON = true
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumIn = ptr.WaterInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].NodeNumOut = ptr.WaterOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd
    state.dataPlnt.PlantLoop[0].LoopSide[EnergyPlus.DataPlant.LoopSideLocation.Supply].Branch[0].Comp[0].Name = ptr.Name
    state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 3
    state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 3
    state.dataSize.CurLoopNum = 0
    state.dataPlnt.PlantLoop[pl.loopNum].PlantSizNum = 1
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[0].ExitTemp = 35
    state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMaxAvail = 5
    state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMax = 5
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].Temp = 20
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMaxAvail = 5
    state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMax = 5
    var firstHVAC: Bool = true
    var curLoad: Real64 = 0.0
    ptr.plantLoc.loopNum = 0
    ptr.plantLoc.loopSideNum = EnergyPlus.DataPlant.LoopSideLocation.Supply
    ptr.plantLoc.branchNum = 0
    ptr.plantLoc.compNum = 0
    ptr.DesWaterMassFlowRate = 3.141
    ptr.WaterMassFlowRate = 3.141
    ptr.onInitLoopEquip(*state, pl)
    ptr.simulate(*state, pl, firstHVAC, curLoad, true)

@test
def EvapFluidCooler_SizeWhenPlantSizingIndexIsZeroAndAutosized() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidcooler:SingleSpeed,",
        "  Big EvaporativeFluidCooler,  !- Name",
        "  Condenser EvaporativeFluidcooler Inlet Node,  !- Water Inlet Node Name",
        "  Condenser EvaporativeFluidcooler Outlet Node,  !- Water Outlet Node Name",
        "  Autosize,                !- Design Air Flow Rate {m3/s}",
        "  Autosize,                !- Design Air Flow Rate Fan Power {W}",
        "  0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "  UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
        "  ,                        !- Outdoor Air Inlet Node Name",
        "  ,                        !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "  ,                        !- Standard Design Capacity {W}",
        "  Autosize,                !- Design Air Flow Rate U-factor Times Area Value {W/K}",
        "  Autosize,                !- Design Water Flow Rate {m3/s}",
        "  ,                        !- User Specified Design Capacity {W}",
        "  46.11,                   !- Design Entering Water Temperature {C}",
        "  35,                      !- Design Entering Air Temperature {C}",
        "  25.6;                    !- Design Entering Air Wet-bulb Temperature {C}",
    ])
    assert_true(process_idf(idf_objects))
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].PlantSizNum = 0
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    ptr.plantLoc.loopNum = 0
    ptr.plantLoc.loopSideNum = DataPlant.LoopSideLocation.Supply
    ptr.plantLoc.branchNum = 0
    ptr.plantLoc.compNum = 0
    PlantUtilities.SetPlantLocationLinks(*state, ptr.plantLoc)
    state.dataPlnt.PlantFirstSizesOkayToFinalize = false
    assert_true(ptr.DesignWaterFlowRateWasAutoSized)
    assert_true(ptr.HighSpeedAirFlowRateWasAutoSized)
    assert_true(ptr.HighSpeedFanPowerWasAutoSized)
    assert_true(ptr.HighSpeedEvapFluidCoolerUAWasAutoSized)
    ptr.SizeEvapFluidCooler(*state)

@test
def EvapFluidCooler_SingleSpeed_DesignEnteringWaterIsAutosized() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidCooler:SingleSpeed,",
        "  Big EvaporativeFluidCooler,  !- Name",
        "  Condenser EvaporativeFluidCooler Inlet Node,  !- Water Inlet Node Name",
        "  Condenser EvaporativeFluidCooler Outlet Node,  !- Water Outlet Node Name",
        "  3.02,                    !- Design Air Flow Rate {m3/s}",
        "  2250,                    !- Design Air Flow Rate Fan Power {W}",
        "  0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "  UserSpecifiedDesignCapacity,  !- Performance Input Method",
        "  ,                        !- Outdoor Air Inlet Node Name",
        "  ,                        !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "  ,                        !- Standard Design Capacity {W}",
        "  ,                        !- Design Air Flow Rate U-factor Times Area Value {W/K}",
        "  0.001703,                !- Design Water Flow Rate {m3/s}",
        "  87921,                   !- User Specified Design Capacity {W}",
        "  Autosize,                !- Design Entering Water Temperature {C}",
        "  35,                      !- Design Entering Air Temperature {C}",
        "  25.6;                    !- Design Entering Air Wet-bulb Temperature {C}",
    ])
    assert_true(process_idf(idf_objects))
    // EXPECT_NO_THROW: we assume factory does not throw; we just call it
    _ = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    compare_err_stream("")
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_SingleSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    assert_equal(DataSizing.AutoSize, ptr.DesignEnteringWaterTemp)
    assert_true(ptr.DesignEnteringWaterTempWasAutoSized)
    state.dataPlnt.PlantLoop.allocate(1)
    var plantLoop = state.dataPlnt.PlantLoop[0]
    plantLoop.PlantSizNum = 0
    plantLoop.LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    plantLoop.LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    plantLoop.FluidName = "WATER"
    plantLoop.glycol = Fluid.GetWater(*state)
    ptr.plantLoc.loopNum = 0
    ptr.plantLoc.loopSideNum = DataPlant.LoopSideLocation.Supply
    ptr.plantLoc.branchNum = 0
    ptr.plantLoc.compNum = 0
    PlantUtilities.SetPlantLocationLinks(*state, ptr.plantLoc)
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    // EXPECT_THROW(FatalError) - we can use try-except. For now, assume fatal throws and we catch.
    try:
        ptr.SizeEvapFluidCooler(*state)
        assert_true(false) // should not reach
    except:

    assert_true(compare_err_stream_substring(delimited_string([
        "   ** Severe  ** Autosizing error for evaporative fluid cooler object = BIG EVAPORATIVEFLUIDCOOLER",
        "   **  Fatal  ** Autosizing of evaporative fluid cooler Design Entering Water Temperature requires a loop Sizing:Plant object.",
    ])))
    assert_false(ptr.DesignWaterFlowRateWasAutoSized)
    assert_false(ptr.HighSpeedAirFlowRateWasAutoSized)
    assert_false(ptr.HighSpeedFanPowerWasAutoSized)
    assert_false(ptr.HighSpeedEvapFluidCoolerUAWasAutoSized)
    assert_true(ptr.DesignEnteringWaterTempWasAutoSized)
    state.dataSize.PlantSizData.allocate(1)
    var sizingPlant = state.dataSize.PlantSizData[0]
    plantLoop.PlantSizNum = 1
    sizingPlant.ExitTemp = 10.0
    sizingPlant.DeltaT = 10.0
    var expected_ewt: Real64 = sizingPlant.ExitTemp + sizingPlant.DeltaT
    assert_equal(20.0, expected_ewt)
    try:
        ptr.SizeEvapFluidCooler(*state)
        assert_true(false)
    except:

    assert_true(compare_err_stream_substring(delimited_string([
        "   ** Severe  ** Error when autosizing the Design Entering Water Temperature for Evaporative Fluid Cooler = BIG EVAPORATIVEFLUIDCOOLER.",
        "   **   ~~~   ** Design Entering Water Temperature (20.0000 C) must be greater than design entering air wet-bulb temperature (25.6000 C).",
        "   **   ~~~   ** Check the Sizing:Plant object and the Design Entering Air Wet-bulb Temp input field for the Evaporative Fluid Cooler.",
        "   **  Fatal  ** Review and revise design input values as appropriate.",
    ])))
    assert_ne(DataSizing.AutoSize, ptr.DesignEnteringWaterTemp)
    assert_equal(expected_ewt, ptr.DesignEnteringWaterTemp)
    compare_eio_stream("")
    sizingPlant.ExitTemp = 30.0
    expected_ewt = sizingPlant.ExitTemp + sizingPlant.DeltaT
    assert_equal(40.0, expected_ewt)
    ptr.SizeEvapFluidCooler(*state)
    compare_err_stream("")
    assert_equal(expected_ewt, ptr.DesignEnteringWaterTemp)
    assert_true(compare_eio_stream_substring("Component Sizing Information, EvaporativeFluidCooler:SingleSpeed, BIG EVAPORATIVEFLUIDCOOLER, Design Entering Water Temperature [C], 40.0000"))

@test
def EvapFluidCooler_TwoSpeed_DesignEnteringWaterIsAutosized() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidCooler:TwoSpeed,",
        "  Big EvaporativeFluidCooler,  !- Name",
        "  Condenser EvaporativeFluidCooler Inlet Node,  !- Water Inlet Node Name",
        "  Condenser EvaporativeFluidCooler Outlet Node,  !- Water Outlet Node Name",
        "  3.02,                    !- High Fan Speed Air Flow Rate {m3/s}",
        "  2250,                    !- High Fan Speed Fan Power {W}",
        "  autocalculate,           !- Low Fan Speed Air Flow Rate {m3/s}",
        "  ,                        !- Low Fan Speed Air Flow Rate Sizing Factor",
        "  autocalculate,           !- Low Fan Speed Fan Power {W}",
        "  ,                        !- Low Fan Speed Fan Power Sizing Factor",
        "  0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "  UserSpecifiedDesignCapacity,  !- Performance Input Method",
        "  ,                        !- Outdoor Air Inlet Node Name",
        "  1.0,                     !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "  ,                        !- High Speed Standard Design Capacity {W}",
        "  ,                        !- Low Speed Standard Design Capacity {W}",
        "  ,                        !- Low Speed Standard Capacity Sizing Factor",
        "  ,                        !- High Fan Speed U-factor Times Area Value {W/K}",
        "  ,                        !- Low Fan Speed U-factor Times Area Value {W/K}",
        "  ,                        !- Low Fan Speed U-Factor Times Area Sizing Factor",
        "  0.001703,                !- Design Water Flow Rate {m3/s}",
        "  87921,                   !- High Speed User Specified Design Capacity {W}",
        "  21980,                   !- Low Speed User Specified Design Capacity {W}",
        "  0.25,                    !- Low Speed User Specified Design Capacity Sizing Factor",
        "  Autosize,                !- Design Entering Water Temperature {C}",
        "  35.0,                    !- Design Entering Air Temperature {C}",
        "  25.6,                    !- Design Entering Air Wet-bulb Temperature {C}",
        "  1,                       !- High Speed Sizing Factor",
        "  SaturatedExit,           !- Evaporation Loss Mode",
        "  ,                        !- Evaporation Loss Factor {percent/K}",
        "  0.008,                   !- Drift Loss Percent {percent}",
        "  ConcentrationRatio,      !- Blowdown Calculation Mode",
        "  3;                       !- Blowdown Concentration Ratio",
    ])
    assert_true(process_idf(idf_objects))
    _ = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    compare_err_stream("")
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    assert_equal(DataSizing.AutoSize, ptr.DesignEnteringWaterTemp)
    assert_true(ptr.DesignEnteringWaterTempWasAutoSized)
    assert_equal(DataSizing.AutoSize, ptr.DesignEnteringWaterTemp)
    assert_true(ptr.DesignEnteringWaterTempWasAutoSized)
    state.dataPlnt.PlantLoop.allocate(1)
    var plantLoop = state.dataPlnt.PlantLoop[0]
    plantLoop.PlantSizNum = 0
    plantLoop.LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
    plantLoop.LoopSide[DataPlant.LoopSideLocation.Supply].Branch[0].Comp.allocate(1)
    plantLoop.FluidName = "WATER"
    plantLoop.glycol = Fluid.GetWater(*state)
    ptr.plantLoc.loopNum = 0
    ptr.plantLoc.loopSideNum = DataPlant.LoopSideLocation.Supply
    ptr.plantLoc.branchNum = 0
    ptr.plantLoc.compNum = 0
    PlantUtilities.SetPlantLocationLinks(*state, ptr.plantLoc)
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    try:
        ptr.SizeEvapFluidCooler(*state)
        assert_true(false)
    except:

    assert_true(compare_err_stream_substring(delimited_string([
        "   ** Severe  ** Autosizing error for evaporative fluid cooler object = BIG EVAPORATIVEFLUIDCOOLER",
        "   **  Fatal  ** Autosizing of evaporative fluid cooler Design Entering Water Temperature requires a loop Sizing:Plant object.",
    ])))
    assert_false(ptr.DesignWaterFlowRateWasAutoSized)
    assert_false(ptr.HighSpeedAirFlowRateWasAutoSized)
    assert_false(ptr.HighSpeedFanPowerWasAutoSized)
    assert_false(ptr.HighSpeedEvapFluidCoolerUAWasAutoSized)
    assert_true(ptr.DesignEnteringWaterTempWasAutoSized)
    state.dataSize.PlantSizData.allocate(1)
    var sizingPlant = state.dataSize.PlantSizData[0]
    plantLoop.PlantSizNum = 1
    sizingPlant.ExitTemp = 10.0
    sizingPlant.DeltaT = 10.0
    var expected_ewt: Real64 = sizingPlant.ExitTemp + sizingPlant.DeltaT
    assert_equal(20.0, expected_ewt)
    try:
        ptr.SizeEvapFluidCooler(*state)
        assert_true(false)
    except:

    assert_true(compare_err_stream_substring(delimited_string([
        "   ** Severe  ** Error when autosizing the Design Entering Water Temperature for Evaporative Fluid Cooler = BIG EVAPORATIVEFLUIDCOOLER.",
        "   **   ~~~   ** Design Entering Water Temperature (20.0000 C) must be greater than design entering air wet-bulb temperature (25.6000 C).",
        "   **   ~~~   ** Check the Sizing:Plant object and the Design Entering Air Wet-bulb Temp input field for the Evaporative Fluid Cooler.",
        "   **  Fatal  ** Review and revise design input values as appropriate.",
    ])))
    assert_ne(DataSizing.AutoSize, ptr.DesignEnteringWaterTemp)
    assert_equal(expected_ewt, ptr.DesignEnteringWaterTemp)
    compare_eio_stream("")
    sizingPlant.ExitTemp = 30.0
    expected_ewt = sizingPlant.ExitTemp + sizingPlant.DeltaT
    assert_equal(40.0, expected_ewt)
    ptr.SizeEvapFluidCooler(*state)
    compare_err_stream("")
    assert_equal(expected_ewt, ptr.DesignEnteringWaterTemp)
    assert_true(compare_eio_stream_substring("Component Sizing Information, EvaporativeFluidCooler:TwoSpeed, BIG EVAPORATIVEFLUIDCOOLER, Design Entering Water Temperature [C], 40.0000"))

@test
def EvapFluidCooler_TwoSpeed_UserSpecifiedDesignCapacity_LowSpeed_CanAutocalculate() -> Unit:
    var idf_objects: String = delimited_string([
        "EvaporativeFluidCooler:TwoSpeed,",
        "  Big EvaporativeFluidCooler,  !- Name",
        "  Condenser EvaporativeFluidCooler Inlet Node,  !- Water Inlet Node Name",
        "  Condenser EvaporativeFluidCooler Outlet Node,  !- Water Outlet Node Name",
        "  3.02,                    !- High Fan Speed Air Flow Rate {m3/s}",
        "  2250,                    !- High Fan Speed Fan Power {W}",
        "  autocalculate,           !- Low Fan Speed Air Flow Rate {m3/s}",
        "  ,                        !- Low Fan Speed Air Flow Rate Sizing Factor",
        "  autocalculate,           !- Low Fan Speed Fan Power {W}",
        "  ,                        !- Low Fan Speed Fan Power Sizing Factor",
        "  0.002208,                !- Design Spray Water Flow Rate {m3/s}",
        "  UserSpecifiedDesignCapacity,  !- Performance Input Method",
        "  ,                        !- Outdoor Air Inlet Node Name",
        "  1.0,                     !- Heat Rejection Capacity and Nominal Capacity Sizing Ratio",
        "  ,                        !- High Speed Standard Design Capacity {W}",
        "  ,                        !- Low Speed Standard Design Capacity {W}",
        "  ,                        !- Low Speed Standard Capacity Sizing Factor",
        "  ,                        !- High Fan Speed U-factor Times Area Value {W/K}",
        "  ,                        !- Low Fan Speed U-factor Times Area Value {W/K}",
        "  ,                        !- Low Fan Speed U-Factor Times Area Sizing Factor",
        "  0.001703,                !- Design Water Flow Rate {m3/s}",
        "  87921,                   !- High Speed User Specified Design Capacity {W}",
        "  Autocalculate,           !- Low Speed User Specified Design Capacity {W}",           // This is set to autocalculate
        "  0.25,                    !- Low Speed User Specified Design Capacity Sizing Factor", // This has a default of 0.5 anyways
        "  46.11,                   !- Design Entering Water Temperature {C}",
        "  35.0,                    !- Design Entering Air Temperature {C}",
        "  25.6,                    !- Design Entering Air Wet-bulb Temperature {C}",
        "  1,                       !- High Speed Sizing Factor",
        "  SaturatedExit,           !- Evaporation Loss Mode",
        "  ,                        !- Evaporation Loss Factor {percent/K}",
        "  0.008,                   !- Drift Loss Percent {percent}",
        "  ConcentrationRatio,      !- Blowdown Calculation Mode",
        "  3;                       !- Blowdown Concentration Ratio",
    ])
    assert_true(process_idf(idf_objects))
    _ = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    compare_err_stream("")
    var ptr: EvapFluidCoolerSpecs* = EvapFluidCoolerSpecs.factory(*state, DataPlant.PlantEquipmentType.EvapFluidCooler_TwoSpd, "BIG EVAPORATIVEFLUIDCOOLER")
    assert_equal(87921.0, ptr.HighSpeedUserSpecifiedDesignCapacity)
    assert_equal(87921.0 * 0.25, ptr.LowSpeedUserSpecifiedDesignCapacity)