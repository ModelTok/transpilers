// Mojo translation of WaterToAirHeatPumpSimple.unit.cc (1:1, no refactoring)

from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_NEAR, EXPECT_TRUE, EXPECT_NE, ASSERT_TRUE, ASSERT_EQ
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.CurveManager import AddCurve
from EnergyPlus.Data.EnergyPlusData import state
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataErrorTracking import *
from EnergyPlus.DataHVACGlobals import HVAC
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.General import ShowMessage
from EnergyPlus.InputProcessing.InputProcessor import process_idf, delimited_string
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ReportCoilSelection import ReportCoilSelection
from EnergyPlus.WaterToAirHeatPumpSimple import *
from EnergyPlus.DataPlant import DataPlant, LoopSideLocation, PlantEquipmentType
from EnergyPlus.DataSizing import DataSizing, AutoSize

# Test fixture class
class EnergyPlusFixture(TestFixture):

# Test: WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAir
def test_WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAir():
    state.dataFluid.init_state(state)
    var HPNum: Int = 1
    state.dataSize.SysSizingRunDone = True
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.CurSysNum = 0
    state.dataSize.CurZoneEqNum = 1
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP.allocate(HPNum)
    state.dataSize.FinalZoneSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.ZoneEqSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.DesDayWeath.allocate(1)
    state.dataSize.DesDayWeath[1].Temp.allocate(24)
    var wahpSimple1 = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum]
    wahpSimple1.WAHPType = WatertoAirHP.Cooling
    wahpSimple1.coilType = HVAC.CoilType.CoolingWAHPSimple
    wahpSimple1.coilReportNum = ReportCoilSelection.getReportIndex(state, wahpSimple1.Name, wahpSimple1.coilType)
    wahpSimple1.RatedAirVolFlowRate = AutoSize
    wahpSimple1.RatedCapCoolTotal = AutoSize
    wahpSimple1.RatedCapCoolSens = AutoSize
    wahpSimple1.RatedWaterVolFlowRate = 0.0
    wahpSimple1.WaterInletNodeNum = 1
    wahpSimple1.WaterOutletNodeNum = 2
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.20
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.20
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesTemp = 13.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesHumRat = 0.0075
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].TimeStepNumAtCoolMax = 15
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDDNum = 1
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInTemp = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInHumRat = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneRetTempAtCoolPeak = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtCoolPeak = 0.0045
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].OAVolFlow = 0.0
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.QuadLinear
    curve1.coeff[0] = -9.149069561
    curve1.coeff[1] = 10.878140260
    curve1.coeff[2] = -1.718780157
    curve1.coeff[3] = 0.746414818
    curve1.coeff[4] = 0.0
    curve1.inputLimits[0].min = 0.0
    curve1.inputLimits[0].max = 80.0
    curve1.inputLimits[1].min = 0.0
    curve1.inputLimits[1].max = 100.0
    curve1.inputLimits[2].min = 0.0
    curve1.inputLimits[2].max = 2.0
    curve1.inputLimits[3].min = 0.0
    curve1.inputLimits[3].max = 2.0
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.QuintLinear
    curve2.coeff[0] = -5.462690012
    curve2.coeff[1] = 17.95968138
    curve2.coeff[2] = -11.87818402
    curve2.coeff[3] = -0.980163419
    curve2.coeff[4] = 0.767285761
    curve2.coeff[5] = 0.0
    curve2.inputLimits[0].min = 0.0
    curve2.inputLimits[0].max = 100.0
    curve2.inputLimits[1].min = 0.0
    curve2.inputLimits[1].max = 100.0
    curve2.inputLimits[2].min = 0.0
    curve2.inputLimits[2].max = 100.0
    curve2.inputLimits[3].min = 0.0
    curve2.inputLimits[3].max = 1.0
    curve2.inputLimits[4].min = 0.0
    curve2.inputLimits[4].max = 1.0
    var curve3 = AddCurve(state, "Curve3")
    curve3.curveType = CurveType.QuadLinear
    curve3.coeff[0] = -3.205409884
    curve3.coeff[1] = -0.976409399
    curve3.coeff[2] = 3.97892546
    curve3.coeff[3] = 0.938181818
    curve3.coeff[4] = 0.0
    curve3.inputLimits[0].min = -100
    curve3.inputLimits[0].max = 100
    curve3.inputLimits[1].min = -100
    curve3.inputLimits[1].max = 100
    curve3.inputLimits[2].min = 0
    curve3.inputLimits[2].max = 100
    curve3.inputLimits[3].min = 0
    curve3.inputLimits[3].max = 38
    wahpSimple1.TotalCoolCapCurve = curve1
    wahpSimple1.SensCoolCapCurve = curve2
    wahpSimple1.CoolPowCurve = curve3
    wahpSimple1.RatedCOPCoolAtRatedCdts = 5.12
    state.dataSize.DesDayWeath[1].Temp[15] = 32.0
    state.dataEnvrn.StdBaroPress = 101325.0
    state.dataSize.ZoneEqDXCoil = True
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[1].Name = "Condenser Water Loop"
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    var loopside = state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand)
    loopside.TotalBranches = 1
    loopside.Branch.allocate(1)
    var loopsidebranch = state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1]
    loopsidebranch.TotalComponents = 1
    loopsidebranch.Comp.allocate(1)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = wahpSimple1.Name
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = wahpSimple1.WAHPPlantType
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = wahpSimple1.WaterInletNodeNum
    wahpSimple1.plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, wahpSimple1.plantLoc)
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[1].ExitTemp = 29.4
    WaterToAirHeatPumpSimple.SizeHVACWaterToAir(state, HPNum)
    EXPECT_DOUBLE_EQ(0.0075, state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesHumRat)
    EXPECT_GE(wahpSimple1.RatedCapCoolTotal, wahpSimple1.RatedCapCoolSens)
    if wahpSimple1.RatedCapCoolTotal != 0.0:
        ShowMessage(state,
                    EnergyPlus.format("SizeHVACWaterToAir: Rated Sensible Heat Ratio = {:.2R} [-]",
                                       wahpSimple1.RatedCapCoolSens / wahpSimple1.RatedCapCoolTotal)
                   )
    EXPECT_TRUE(compare_eio_stream_substring("Design Size Rated Air Flow Rate", False))
    EXPECT_TRUE(compare_eio_stream_substring("Design Size Rated Total Cooling Capacity", False))
    EXPECT_TRUE(compare_eio_stream_substring("Design Size Rated Sensible Cooling Capacity", True))

# Test: WaterToAirHeatPumpSimple_TestAirFlow
def test_WaterToAirHeatPumpSimple_TestAirFlow():
    var idf_objects = delimited_string([
        " Coil:Cooling:WaterToAirHeatPump:EquationFit,",
        "   Sys 5 Heat Pump Cooling Mode,  !- Name",
        "   ,                              !- Availability Schedule Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Inlet Node,  !- Water Inlet Node Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Outlet Node,  !- Water Outlet Node Name",
        "   Sys 5 Cooling Coil Air Inlet Node,  !- Air Inlet Node Name",
        "   Sys 5 Heating Coil Air Inlet Node,  !- Air Outlet Node Name",
        "   2.0,                     !- Rated Air Flow Rate {m3/s}",
        "   0.0033,                  !- Rated Water Flow Rate {m3/s}",
        "   20000,                   !- Gross Rated Total Cooling Capacity {W}",
        "   16000,                   !- Gross Rated Sensible Cooling Capacity {W}",
        "   7.007757577,             !- Gross Rated Cooling COP",
        "   ,                        !- Rated Entering Water Temperature",
        "   ,                        !- Rated Entering Air Dry-Bulb Temperature",
        "   ,                        !- Rated Entering Air Wet-Bulb Temperature",
        "   TotCoolCapCurve,         !- Total Cooling Capacity Curve Name",
        "   SensCoolCapCurve,        !- Sensible Cooling Capacity Curve Name",
        "   CoolPowCurve,            !- Cooling Power Consumption Curve Name",
        "   PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
        "   0,                       !- Nominal Time for Condensate Removal to Begin {s}",
        "   0;                       !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        " Coil:Heating:WaterToAirHeatPump:EquationFit,",
        "  Sys 5 Heat Pump Heating Mode,  !- Name",
        "  ,                              !- Availability Schedule Name",
        "  Sys 5 Water to Air Heat Pump Source Side2 Inlet Node,  !- Water Inlet Node Name",
        "  Sys 5 Water to Air Heat Pump Source Side2 Outlet Node,  !- Water Outlet Node Name",
        "  Sys 5 Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Sys 5 SuppHeating Coil Air Inlet Node,  !- Air Outlet Node Name",
        "  1.0,                      !- Rated Air Flow Rate {m3/s}",
        "  0.0033,                   !- Rated Water Flow Rate {m3/s}",
        "  20000,                    !- Gross Rated Heating Capacity {W}",
        "  3.167053691,              !- Gross Rated Heating COP",
        "  ,                         !- Rated Entering Water Temperature",
        "  ,                         !- Rated Entering Air Dry-Bulb Temperature",
        "  ,                         !- Ratio of Rated Heating Capacity to Rated Cooling Capacity",
        "  HeatCapCurve,             !- Heating Capacity Curve Name",
        "  HeatPowCurve,             !- Heating Power Curve Name",
        "  PLFFPLR;                  !- Part Load Fraction Correlation Curve Name",
        "Curve:QuintLinear,",
        "  SensCoolCapCurve,     ! Curve Name",
        "  0,           ! CoefficientC1",
        "  0.2,           ! CoefficientC2",
        "  0.2,          ! CoefficientC3",
        "  0.2,          ! CoefficientC4",
        "  0.2,          ! CoefficientC5",
        "  0.2,           ! CoefficientC6",
        "  0.,                   ! Minimum Value of v",
        "  100.,                 ! Maximum Value of v",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  TotCoolCapCurve,      ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  CoolPowCurve,      ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  HeatCapCurve,         ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  HeatPowCurve,         ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:Quadratic, PLFFPLR, 0.85, 0.83, 0.0, 0.0, 0.3, 0.85, 1.0, Dimensionless, Dimensionless; ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    GetSimpleWatertoAirHPInput(state)
    var HPNum: Int = 1
    var ActualAirflow: Float64 = 1.0
    var DesignWaterflow: Float64 = 15.0
    var CpAir = PsyCpAirFnW(0.007)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Temp = 5.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Enthalpy = 44650.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMax = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMaxAvail = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Temp = 26.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].HumRat = 0.007
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Enthalpy = 43970.75
    state.dataPlnt.TotNumLoops = 2
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WAHPPlantType
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum
    var compressorOp: HVAC.CompressorOp = HVAC.CompressorOp.On
    var fanOp: HVAC.FanOp = HVAC.FanOp.Cycling
    var FirstHVACIteration: Bool = True
    var SensLoad: Float64 = 38000.0
    var LatentLoad: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    var OnOffAirFlowRatio: Float64 = 1.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].plantLoc.loopNum = 1
    state.dataEnvrn.OutBaroPress = 101325.0
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.85781, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 16000 * 0.89755, 0.1)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.02
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.001
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.005
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    EXPECT_TRUE(compare_err_stream_substring(delimited_string([
        "   ** Warning ** InitSimpleWatertoAirHP: Actual air mass flow rate is smaller than 25% of water-to-air heat pump coil (SYS 5 HEAT PUMP "
        "COOLING MODE) rated air flow rate.",
    ])))
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, 43970.75 - (17156.275 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 26.0 - (14360.848 / 1.0 / CpAir), 0.0001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 0.5)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.85781 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 16000 * 0.89755 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, 43970.75 - (17156.275 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 26.0 - (14360.848 / 1.0 / CpAir), 0.0001)
    fanOp = HVAC.FanOp.Continuous
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.85781, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 16000 * 0.89755, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, 43970.75 - (17156.275 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 26.0 - (14360.848 / 1.0 / CpAir), 0.0001)
    EXPECT_EQ(state.dataErrTracking.NumRecurringErrors, 0)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.85781 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 16000 * 0.89755 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, (43970.75 - (17156.275 / 1.0)) * 0.5 + 43970.75 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 18.95267, 0.0001)
    HPNum = 2
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].plantLoc.loopNum = 2
    state.dataPlnt.PlantLoop[2].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[2].FluidName = "WATER"
    state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WAHPPlantType
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMax = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMaxAvail = DesignWaterflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Temp = 35.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Enthalpy = 43950.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Temp = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].HumRat = 0.004
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Enthalpy = PsyHFnTdbW(15.0, 0.004)
    CpAir = PsyCpAirFnW(0.004)
    fanOp = HVAC.FanOp.Cycling
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.981844, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 20000 * 0.981844, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, PsyHFnTdbW(15.0, 0.004) + (19636.8798 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 15.0 + (19636.8798 / 1.0 / CpAir), 0.0001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 0.5)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.981844 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 20000 * 0.981844 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, PsyHFnTdbW(15.0, 0.004) + (19636.8798 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 15.0 + (19636.8798 / 1.0 / CpAir), 0.0001)
    fanOp = HVAC.FanOp.Continuous
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.981844, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 20000 * 0.981844, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy, PsyHFnTdbW(15.0, 0.004) + (19636.8798 / 1.0), 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 15.0 + (19636.8798 / 1.0 / CpAir), 0.0001)
    EXPECT_EQ(state.dataErrTracking.NumRecurringErrors, 0)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = ActualAirflow
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirMassFlowRate, 1.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QLoadTotal, 20000 * 0.981844 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].QSensible, 20000 * 0.981844 * 0.5, 0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirEnthalpy,
                (PsyHFnTdbW(15.0, 0.004) + (19636.8798 / 1.0)) * 0.5 + 0.5 * PsyHFnTdbW(15.0, 0.004),
                0.1)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletAirDBTemp, 24.69937, 0.0001)
    HPNum = 1
    EXPECT_NE(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].RatedEntAirDrybulbTemp, DataSizing.AutoSize)
    EXPECT_NE(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].RatedEntAirWetbulbTemp, DataSizing.AutoSize)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].SensCoolCapCurve = None
    WaterToAirHeatPumpSimple.CheckSimpleWAHPRatedCurvesOutputs(state, state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].TotalCoolCapCurve = None
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].CoolPowCurve = None
    WaterToAirHeatPumpSimple.CheckSimpleWAHPRatedCurvesOutputs(state, state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name)
    HPNum = 2
    EXPECT_NE(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].RatedEntAirDrybulbTemp, DataSizing.AutoSize)
    EXPECT_NE(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].RatedEntAirWetbulbTemp, DataSizing.AutoSize)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].HeatCapCurve = None
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].HeatPowCurve = None
    WaterToAirHeatPumpSimple.CheckSimpleWAHPRatedCurvesOutputs(state, state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name)
    fanOp = HVAC.FanOp.Continuous
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.2
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.01
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = 0.05
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    EXPECT_EQ(state.dataErrTracking.NumRecurringErrors, 1)
    EXPECT_EQ(state.dataErrTracking.RecurringErrors[0].MinValue, 0.01)
    EXPECT_EQ(state.dataErrTracking.RecurringErrors[0].MaxValue, 0.2)
    EXPECT_EQ(state.dataErrTracking.RecurringErrors[0].Count, 3)
    EXPECT_EQ(state.dataErrTracking.RecurringErrors[0].Message,
              " ** Warning ** Actual air mass flow rate is smaller than 25% of water-to-air heat pump coil rated air flow rate.")

# Test: WaterToAirHeatPumpSimple_TestWaterFlowControl
def test_WaterToAirHeatPumpSimple_TestWaterFlowControl():
    var idf_objects = delimited_string([
        " Coil:Cooling:WaterToAirHeatPump:EquationFit,",
        "   Sys 5 Heat Pump Cooling Mode,  !- Name",
        "   ,                              !- Availability Schedule Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Inlet Node,  !- Water Inlet Node Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Outlet Node,  !- Water Outlet Node Name",
        "   Sys 5 Cooling Coil Air Inlet Node,  !- Air Inlet Node Name",
        "   Sys 5 Heating Coil Air Inlet Node,  !- Air Outlet Node Name",
        "   1.0,                     !- Rated Air Flow Rate {m3/s}",
        "   0.0033,                  !- Rated Water Flow Rate {m3/s}",
        "   23125.59,                !- Gross Rated Total Cooling Capacity {W}",
        "   16267,                   !- Gross Rated Sensible Cooling Capacity {W}",
        "   7.007757577,             !- Gross Rated Cooling COP",
        "   ,                        !- Rated Entering Water Temperature",
        "   ,                        !- Rated Entering Air Dry-Bulb Temperature",
        "   ,                        !- Rated Entering Air Wet-Bulb Temperature",
        "   TotCoolCapCurve,         !- Total Cooling Capacity Curve Name",
        "   SensCoolCapCurve,        !- Sensible Cooling Capacity Curve Name",
        "   CoolPowCurve,            !- Cooling Power Consumption Curve Name",
        "   PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
        "   0,                       !- Nominal Time for Condensate Removal to Begin {s}",
        "   0;                       !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        " Coil:Heating:WaterToAirHeatPump:EquationFit,",
        "  Sys 5 Heat Pump Heating Mode,  !- Name",
        "  ,                              !- Availability Schedule Name",
        "  Sys 5 Water to Air Heat Pump Source Side2 Inlet Node,  !- Water Inlet Node Name",
        "  Sys 5 Water to Air Heat Pump Source Side2 Outlet Node,  !- Water Outlet Node Name",
        "  Sys 5 Heating Coil Air Inlet Node,  !- Air Inlet Node Name",
        "  Sys 5 SuppHeating Coil Air Inlet Node,  !- Air Outlet Node Name",
        "  1.0,                      !- Rated Air Flow Rate {m3/s}",
        "  0.0033,                   !- Rated Water Flow Rate {m3/s}",
        "  19156.73,                 !- Gross Rated Heating Capacity {W}",
        "  3.167053691,              !- Gross Rated Heating COP",
        "  ,                         !- Rated Entering Water Temperature",
        "  ,                         !- Rated Entering Air Dry-Bulb Temperature",
        "  ,                         !- Ratio of Rated Heating Capacity to Rated Cooling Capacity",
        "  HeatCapCurve,             !- Heating Capacity Curve Name",
        "  HeatPowCurve,             !- Heating Power Curve Name",
        "  PLFFPLR;                  !- Part Load Fraction Correlation Curve Name",
        "Curve:QuintLinear,",
        "  SensCoolCapCurve,     ! Curve Name",
        "  2.24209455,           ! CoefficientC1",
        "  7.28913391,           ! CoefficientC2",
        "  -9.06079896,          ! CoefficientC3",
        "  -0.36729404,          ! CoefficientC4",
        "  0.218826161,          ! CoefficientC5",
        "  0.00901534,           ! CoefficientC6",
        "  0.,                   ! Minimum Value of v",
        "  100.,                 ! Maximum Value of v",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  TotCoolCapCurve,      ! Curve Name",
        "  -0.68126221,          ! CoefficientC1",
        "  1.99529297,           ! CoefficientC2",
        "  -0.93611888,          ! CoefficientC3",
        "  0.02081177,           ! CoefficientC4",
        "  0.008438868,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  CoolPowCurve,      ! Curve Name",
        "  -3.20456384,          ! CoefficientC1",
        "  0.47656454,           ! CoefficientC2",
        "  3.16734236,           ! CoefficientC3",
        "  0.10244637,           ! CoefficientC4",
        "  -0.038132556,         ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  HeatCapCurve,         ! Curve Name",
        "  -5.50102734,          ! CoefficientC1",
        "  -0.96688754,          ! CoefficientC2",
        "  7.70755007,           ! CoefficientC3",
        "  0.031928881,          ! CoefficientC4",
        "  0.028112522,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  HeatPowCurve,         ! Curve Name",
        "  -7.47517858,          ! CoefficientC1",
        "  6.40876653,           ! CoefficientC2",
        "  1.99711665,           ! CoefficientC3",
        "  -0.050682973,         ! CoefficientC4",
        "  0.011385145,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:Quadratic, PLFFPLR, 0.85, 0.83, 0.0, 0.0, 0.3, 0.85, 1.0, Dimensionless, Dimensionless; ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    GetSimpleWatertoAirHPInput(state)
    var HPNum: Int = 1
    var DesignAirflow: Float64 = 2.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Temp = 5.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Enthalpy = 44650.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMax = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMaxAvail = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Temp = 26.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].HumRat = 0.007
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Enthalpy = 43970.75
    state.dataPlnt.TotNumLoops = 2
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WAHPPlantType
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum
    var compressorOp: HVAC.CompressorOp = HVAC.CompressorOp.On
    var fanOp: HVAC.FanOp = HVAC.FanOp.Cycling
    var FirstHVACIteration: Bool = True
    var SensLoad: Float64 = 38000.0
    var LatentLoad: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    var OnOffAirFlowRatio: Float64 = 1.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].plantLoc.loopNum = 1
    state.dataEnvrn.OutBaroPress = 101325.0
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 5.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 5.20387, 0.00001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 5.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 5.10193, 0.00001)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterCyclingMode = HVAC.WaterFlow.Cycling
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 5.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 5.20387, 0.00001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 7.5)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 5.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 5.20387, 0.00001)
    PartLoadRatio = 0.25
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = 3.75
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPCoolingSimple(state, HPNum, fanOp, SensLoad, LatentLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 3.75)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 5.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 5.20387, 0.00001)
    UpdateSimpleWatertoAirHP(state, HPNum)
    EXPECT_EQ(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate, 3.75)
    EXPECT_EQ(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterOutletNodeNum].MassFlowRate, 3.75)
    EXPECT_NEAR(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterOutletNodeNum].Temp, 5.20387, 0.00001)
    HPNum = 2
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].plantLoc.loopNum = 2
    state.dataPlnt.PlantLoop[2].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[2].FluidName = "WATER"
    state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WAHPPlantType
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Temp = 35.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].Enthalpy = 43950.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMax = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRateMaxAvail = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Temp = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].HumRat = 0.004
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].Enthalpy = PsyHFnTdbW(15.0, 0.004)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].DesignWaterMassFlowRate = 15.0
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 35.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 34.50472, 0.00001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 35.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 34.75236, 0.00001)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterCyclingMode = HVAC.WaterFlow.Cycling
    PartLoadRatio = 1.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 15.0)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 35.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 34.50472, 0.00001)
    PartLoadRatio = 0.5
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 7.5)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 35.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 34.50472, 0.00001)
    PartLoadRatio = 0.25
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].AirInletNodeNum].MassFlowRate = DesignAirflow * PartLoadRatio
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate = 3.75
    InitSimpleWatertoAirHP(state, HPNum, SensLoad, LatentLoad, fanOp, OnOffAirFlowRatio, FirstHVACIteration, PartLoadRatio)
    CalcHPHeatingSimple(state, HPNum, fanOp, SensLoad, compressorOp, PartLoadRatio, OnOffAirFlowRatio)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterMassFlowRate, 3.75)
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].InletWaterTemp, 35.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].OutletWaterTemp, 34.50472, 0.00001)
    UpdateSimpleWatertoAirHP(state, HPNum)
    EXPECT_EQ(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterInletNodeNum].MassFlowRate, 3.75)
    EXPECT_EQ(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterOutletNodeNum].MassFlowRate, 3.75)
    EXPECT_NEAR(state.dataLoopNodes.Node[state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].WaterOutletNodeNum].Temp, 34.50472, 0.00001)

# Test: WaterToAirHeatPumpSimpleTest_CheckSimpleWAHPRatedCurvesOutputs
def test_WaterToAirHeatPumpSimpleTest_CheckSimpleWAHPRatedCurvesOutputs():
    var HPNum: Int = 2
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP.allocate(HPNum)
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].Name = "WAHP"
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WAHPType = WatertoAirHP.Cooling
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedAirVolFlowRate = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedCapCoolTotal = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedCapCoolSens = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedWaterVolFlowRate = 0.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WaterInletNodeNum = 1
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WaterOutletNodeNum = 2
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntWaterTemp = 30.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntAirWetbulbTemp = 19.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntAirDrybulbTemp = 27.0
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.QuadLinear
    curve1.coeff[0] = -9.32564313298629
    curve1.coeff[1] = 11.088084240584
    curve1.coeff[2] = -1.75195196204063
    curve1.coeff[3] = 0.760820340847872
    curve1.coeff[4] = 0.0
    curve1.inputLimits[0].min = 0.0
    curve1.inputLimits[0].max = 80.0
    curve1.inputLimits[1].min = 0.0
    curve1.inputLimits[1].max = 100.0
    curve1.inputLimits[2].min = 0.0
    curve1.inputLimits[2].max = 2.0
    curve1.inputLimits[3].min = 0.0
    curve1.inputLimits[3].max = 2.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].TotalCoolCapCurve = curve1
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.QuintLinear
    curve2.coeff[0] = -5.26562830117273
    curve2.coeff[1] = 17.3118017582604
    curve2.coeff[2] = -11.4496890368762
    curve2.coeff[3] = -0.944804890543481
    curve2.coeff[4] = 0.739606605780884
    curve2.coeff[5] = 0.0
    curve2.inputLimits[0].min = 0.0
    curve2.inputLimits[0].max = 100.0
    curve2.inputLimits[1].min = 0.0
    curve2.inputLimits[1].max = 100.0
    curve2.inputLimits[2].min = 0.0
    curve2.inputLimits[2].max = 100.0
    curve2.inputLimits[3].min = 0.0
    curve2.inputLimits[3].max = 1.0
    curve2.inputLimits[4].min = 0.0
    curve2.inputLimits[4].max = 1.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].SensCoolCapCurve = curve2
    var curve3 = AddCurve(state, "Curve3")
    curve3.curveType = CurveType.QuadLinear
    curve3.coeff[0] = -3.25323327026219
    curve3.coeff[1] = -0.990977022339372
    curve3.coeff[2] = 4.03828937789764
    curve3.coeff[3] = 0.952179101682919
    curve3.coeff[4] = 0.0
    curve3.inputLimits[0].min = -100
    curve3.inputLimits[0].max = 100
    curve3.inputLimits[1].min = -100
    curve3.inputLimits[1].max = 100
    curve3.inputLimits[2].min = 0
    curve3.inputLimits[2].max = 100
    curve3.inputLimits[3].min = 0
    curve3.inputLimits[3].max = 38
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].CoolPowCurve = curve3
    CheckSimpleWAHPRatedCurvesOutputs(state, "WAHP")
    EXPECT_TRUE(compare_err_stream("", True))
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].Name = "WAHP 2"
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WAHPType = WatertoAirHP.Cooling
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedAirVolFlowRate = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedCapCoolTotal = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedCapCoolSens = AutoSize
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedWaterVolFlowRate = 0.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WaterInletNodeNum = 1
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].WaterOutletNodeNum = 2
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntWaterTemp = 30.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntAirWetbulbTemp = 19.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].RatedEntAirDrybulbTemp = 27.0
    var curve4 = AddCurve(state, "Curve4")
    curve4.curveType = CurveType.QuadLinear
    curve4.coeff[0] = -0.68126221
    curve4.coeff[1] = 1.99529297
    curve4.coeff[2] = -0.93611888
    curve4.coeff[3] = 0.02081177
    curve4.coeff[4] = 0.008438868
    curve4.inputLimits[0].min = 0.0
    curve4.inputLimits[0].max = 80.0
    curve4.inputLimits[1].min = 0.0
    curve4.inputLimits[1].max = 100.0
    curve4.inputLimits[2].min = 0.0
    curve4.inputLimits[2].max = 2.0
    curve4.inputLimits[3].min = 0.0
    curve4.inputLimits[3].max = 2.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].TotalCoolCapCurve = curve4
    var curve5 = AddCurve(state, "Curve5")
    curve5.curveType = CurveType.QuintLinear
    curve5.coeff[0] = 2.24209455
    curve5.coeff[1] = 7.28913391
    curve5.coeff[2] = -9.06079896
    curve5.coeff[3] = -0.36729404
    curve5.coeff[4] = 0.218826161
    curve5.coeff[5] = 0.00901534
    curve5.inputLimits[0].min = 0.0
    curve5.inputLimits[0].max = 100.0
    curve5.inputLimits[1].min = 0.0
    curve5.inputLimits[1].max = 100.0
    curve5.inputLimits[2].min = 0.0
    curve5.inputLimits[2].max = 100.0
    curve5.inputLimits[3].min = 0.0
    curve5.inputLimits[3].max = 1.0
    curve5.inputLimits[4].min = 0.0
    curve5.inputLimits[4].max = 1.0
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].SensCoolCapCurve = curve5
    var curve6 = AddCurve(state, "Curve6")
    curve6.curveType = CurveType.QuadLinear
    curve6.coeff[0] = -3.20456384
    curve6.coeff[1] = 0.47656454
    curve6.coeff[2] = 3.16734236
    curve6.coeff[3] = 0.10244637
    curve6.coeff[4] = -0.038132556
    curve6.inputLimits[0].min = -100
    curve6.inputLimits[0].max = 100
    curve6.inputLimits[1].min = -100
    curve6.inputLimits[1].max = 100
    curve6.inputLimits[2].min = 0
    curve6.inputLimits[2].max = 100
    curve6.inputLimits[3].min = 0
    curve6.inputLimits[3].max = 38
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1].CoolPowCurve = curve6
    CheckSimpleWAHPRatedCurvesOutputs(state, "WAHP 2")
    var error_string = delimited_string([
        "   ** Warning ** CheckSimpleWAHPRatedCurvesOutputs: Coil:Cooling:WaterToAirHeatPump:EquationFit=\"WAHP 2\"\n   **   ~~~   ** Total cooling "
        "capacity as a function of temperature curve output is not equal to 1.0 (+ or - 2%) at rated conditions.\n   **   ~~~   ** Curve output at "
        "rated conditions = 0.404\n   ** Warning ** CheckSimpleWAHPRatedCurvesOutputs: Coil:Cooling:WaterToAirHeatPump:EquationFit=\"WAHP 2\"\n   "
        "**  "
        " ~~~   ** Cooling power consumption as a function of temperature curve output is not equal to 1.0 (+ or - 2%) at rated conditions.\n   **  "
        " ~~~   ** Curve output at rated conditions = 0.743\n   ** Warning ** "
        "CheckSimpleWAHPRatedCurvesOutputs: Coil:Cooling:WaterToAirHeatPump:EquationFit=\"WAHP 2\"\n   **   ~~~   ** Sensible cooling capacity as a "
        "function of temperature curve output is not equal to 1.0 (+ or - 2%) at rated conditions.\n   **   ~~~   ** Curve output at rated "
        "conditions = 0.455"
    ])
    EXPECT_TRUE(compare_err_stream(error_string, True))

# Test: WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAirRatedConditions
def test_WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAirRatedConditions():
    state.dataFluid.init_state(state)
    var HPNum: Int = 2
    state.dataSize.SysSizingRunDone = True
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.CurSysNum = 0
    state.dataSize.CurZoneEqNum = 1
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP.allocate(HPNum)
    state.dataSize.FinalZoneSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.ZoneEqSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.DesDayWeath.allocate(1)
    state.dataSize.DesDayWeath[1].Temp.allocate(24)
    var wahpSimple1 = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1]
    wahpSimple1.WAHPType = WatertoAirHP.Cooling
    wahpSimple1.coilType = HVAC.CoilType.CoolingWAHPSimple
    wahpSimple1.coilReportNum = ReportCoilSelection.getReportIndex(state, wahpSimple1.Name, wahpSimple1.coilType)
    wahpSimple1.RatedAirVolFlowRate = AutoSize
    wahpSimple1.RatedCapCoolTotal = AutoSize
    wahpSimple1.RatedCapCoolSens = AutoSize
    wahpSimple1.RatedWaterVolFlowRate = AutoSize
    wahpSimple1.WaterInletNodeNum = 1
    wahpSimple1.WaterOutletNodeNum = 2
    wahpSimple1.RatedEntWaterTemp = 30.0
    wahpSimple1.RatedEntAirWetbulbTemp = 19.0
    wahpSimple1.RatedEntAirDrybulbTemp = 27.0
    wahpSimple1.CompanionHeatingCoilNum = 2
    wahpSimple1.WAHPPlantType = DataPlant.PlantEquipmentType.CoilWAHPCoolingEquationFit
    wahpSimple1.availSched = Sched.GetScheduleAlwaysOn(state)
    var wahpSimple2 = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[2]
    wahpSimple2.WAHPType = WatertoAirHP.Heating
    wahpSimple2.coilType = HVAC.CoilType.HeatingWAHPSimple
    wahpSimple2.coilReportNum = ReportCoilSelection.getReportIndex(state, wahpSimple2.Name, wahpSimple2.coilType)
    wahpSimple2.RatedAirVolFlowRate = AutoSize
    wahpSimple2.RatedCapHeat = AutoSize
    wahpSimple2.RatedWaterVolFlowRate = AutoSize
    wahpSimple2.WaterInletNodeNum = 3
    wahpSimple2.WaterOutletNodeNum = 4
    wahpSimple2.RatedEntWaterTemp = 20.0
    wahpSimple2.RatedEntAirDrybulbTemp = 20.0
    wahpSimple2.CompanionCoolingCoilNum = 1
    wahpSimple2.WAHPPlantType = DataPlant.PlantEquipmentType.CoilWAHPHeatingEquationFit
    wahpSimple2.RatioRatedHeatRatedTotCoolCap = 1.23
    wahpSimple2.availSched = Sched.GetScheduleAlwaysOn(state)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.20
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.20
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesTemp = 13.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatDesTemp = 40
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesHumRat = 0.0075
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].TimeStepNumAtCoolMax = 15
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDDNum = 1
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatOutTemp = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInTemp = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInTemp = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInHumRat = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRat = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneRetTempAtCoolPeak = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtCoolPeak = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneRetTempAtHeatPeak = 15.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0045
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].OAVolFlow = 0.0
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.QuadLinear
    curve1.coeff[0] = -9.32564313298629
    curve1.coeff[1] = 11.088084240584
    curve1.coeff[2] = -1.75195196204063
    curve1.coeff[3] = 0.760820340847872
    curve1.coeff[4] = 0.0
    curve1.inputLimits[0].min = 0.0
    curve1.inputLimits[0].max = 80.0
    curve1.inputLimits[1].min = 0.0
    curve1.inputLimits[1].max = 100.0
    curve1.inputLimits[2].min = 0.0
    curve1.inputLimits[2].max = 2.0
    curve1.inputLimits[3].min = 0.0
    curve1.inputLimits[3].max = 2.0
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.QuintLinear
    curve2.coeff[0] = -5.26562830117273
    curve2.coeff[1] = 17.3118017582604
    curve2.coeff[2] = -11.4496890368762
    curve2.coeff[3] = -0.944804890543481
    curve2.coeff[4] = 0.739606605780884
    curve2.coeff[5] = 0.0
    curve2.inputLimits[0].min = 0.0
    curve2.inputLimits[0].max = 100.0
    curve2.inputLimits[1].min = 0.0
    curve2.inputLimits[1].max = 100.0
    curve2.inputLimits[2].min = 0.0
    curve2.inputLimits[2].max = 100.0
    curve2.inputLimits[3].min = 0.0
    curve2.inputLimits[3].max = 1.0
    curve2.inputLimits[4].min = 0.0
    curve2.inputLimits[4].max = 1.0
    var curve3 = AddCurve(state, "Curve3")
    curve3.curveType = CurveType.QuadLinear
    curve3.coeff[0] = -3.25323327026219
    curve3.coeff[1] = -0.990977022339372
    curve3.coeff[2] = 4.03828937789764
    curve3.coeff[3] = 0.952179101682919
    curve3.coeff[4] = 0.0
    curve3.inputLimits[0].min = -100
    curve3.inputLimits[0].max = 100
    curve3.inputLimits[1].min = -100
    curve3.inputLimits[1].max = 100
    curve3.inputLimits[2].min = 0
    curve3.inputLimits[2].max = 100
    curve3.inputLimits[3].min = 0
    curve3.inputLimits[3].max = 38
    var curve4 = AddCurve(state, "Curve4")
    curve4.curveType = CurveType.QuadLinear
    curve4.coeff[0] = -1.30782327125798
    curve4.coeff[1] = -2.37467612404102
    curve4.coeff[2] = 4.00919247797279
    curve4.coeff[3] = 0.615580752610271
    curve4.coeff[4] = 0.0
    curve4.inputLimits[0].min = -100
    curve4.inputLimits[0].max = 100
    curve4.inputLimits[1].min = -100
    curve4.inputLimits[1].max = 100
    curve4.inputLimits[2].min = 0
    curve4.inputLimits[2].max = 100
    curve4.inputLimits[3].min = 0
    curve4.inputLimits[3].max = 38
    var curve5 = AddCurve(state, "Curve5")
    curve5.curveType = CurveType.QuadLinear
    curve5.coeff[0] = -2.17352461285805
    curve5.coeff[1] = 0.830808361346509
    curve5.coeff[2] = 1.5682782658283
    curve5.coeff[3] = 0.689709515714146
    curve5.coeff[4] = 0.0
    curve5.inputLimits[0].min = -100
    curve5.inputLimits[0].max = 100
    curve5.inputLimits[1].min = -100
    curve5.inputLimits[1].max = 100
    curve5.inputLimits[2].min = 0
    curve5.inputLimits[2].max = 100
    curve5.inputLimits[3].min = 0
    curve5.inputLimits[3].max = 38
    wahpSimple1.TotalCoolCapCurve = curve1
    wahpSimple1.SensCoolCapCurve = curve2
    wahpSimple1.CoolPowCurve = curve3
    wahpSimple2.HeatCapCurve = curve4
    wahpSimple2.HeatPowCurve = curve5
    wahpSimple1.RatedCOPCoolAtRatedCdts = 5.12
    wahpSimple2.RatedCOPHeatAtRatedCdts = 3.0
    state.dataSize.DesDayWeath[1].Temp[15] = 32.0
    state.dataEnvrn.StdBaroPress = 101325.0
    state.dataSize.ZoneEqDXCoil = True
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(1)
    var loop = state.dataPlnt.PlantLoop[1]
    loop.Name = "Condenser Water Loop"
    loop.FluidName = "WATER"
    loop.glycol = Fluid.GetWater(state)
    var demandside = loop.LoopSide(DataPlant.LoopSideLocation.Demand)
    demandside.TotalBranches = 1
    demandside.Branch.allocate(1)
    var branch = demandside.Branch[1]
    branch.TotalComponents = 2
    branch.Comp.allocate(2)
    branch.Comp[1].Name = wahpSimple1.Name
    branch.Comp[1].Type = wahpSimple1.WAHPPlantType
    branch.Comp[1].NodeNumIn = wahpSimple1.WaterInletNodeNum
    wahpSimple1.plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, wahpSimple1.plantLoc)
    branch.Comp[2].Name = wahpSimple2.Name
    branch.Comp[2].Type = wahpSimple2.WAHPPlantType
    branch.Comp[2].NodeNumIn = wahpSimple2.WaterInletNodeNum
    wahpSimple2.plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, wahpSimple2.plantLoc)
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[1].PlantLoopName = "Condenser Water Loop"
    state.dataSize.PlantSizData[1].ExitTemp = 29.4
    state.dataSize.PlantSizData[1].DeltaT = 5.56
    WaterToAirHeatPumpSimple.SizeHVACWaterToAir(state, 1)
    WaterToAirHeatPumpSimple.SizeHVACWaterToAir(state, 2)
    EXPECT_NEAR(wahpSimple1.RatedCapCoolAtRatedCdts / wahpSimple1.RatedPowerCoolAtRatedCdts, 5.12, 0.00001)
    EXPECT_NEAR(wahpSimple1.RatedCapCoolTotal - wahpSimple1.RatedCapCoolAtRatedCdts, 0.0, 0.00001)
    EXPECT_NEAR(wahpSimple2.RatedCapHeatAtRatedCdts / wahpSimple2.RatedPowerHeatAtRatedCdts, 3.0, 0.00001)
    EXPECT_NEAR(wahpSimple2.RatedCapHeat - wahpSimple2.RatedCapHeatAtRatedCdts, 0.0, 0.00001)
    EXPECT_NEAR(wahpSimple2.RatedCapHeatAtRatedCdts / wahpSimple1.RatedCapCoolAtRatedCdts, 1.23, 0.00001)
    EXPECT_NEAR(wahpSimple1.RatedWaterVolFlowRate - wahpSimple2.RatedWaterVolFlowRate, 0.0, 0.00001)
    EXPECT_TRUE(wahpSimple1.RatedWaterVolFlowRate > 0.0)
    var waterVolFlowRate = max(((1 - 1 / wahpSimple2.RatedCOPHeatAtRatedCdts) * wahpSimple2.RatedCapHeat),
                                  ((1 + 1 / wahpSimple1.RatedCOPCoolAtRatedCdts) * wahpSimple1.RatedCapCoolTotal)) / \
                              (state.dataSize.PlantSizData[1].DeltaT * 4179.88 * 995.768)
    EXPECT_NEAR(waterVolFlowRate - wahpSimple2.RatedWaterVolFlowRate, 0.0, 0.00001)

# Test: WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAirRatedConditionsNoDesHtgAirFlow
def test_WaterToAirHeatPumpSimpleTest_SizeHVACWaterToAirRatedConditionsNoDesHtgAirFlow():
    state.dataFluid.init_state(state)
    var HPNum: Int = 2
    state.dataSize.SysSizingRunDone = True
    state.dataSize.ZoneSizingRunDone = True
    state.dataSize.CurSysNum = 0
    state.dataSize.CurZoneEqNum = 1
    state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP.allocate(HPNum)
    state.dataSize.FinalZoneSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.ZoneEqSizing.allocate(state.dataSize.CurZoneEqNum)
    state.dataSize.DesDayWeath.allocate(1)
    state.dataSize.DesDayWeath[1].Temp.allocate(24)
    var wahpSimple1 = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[1]
    wahpSimple1.WAHPType = WatertoAirHP.Cooling
    wahpSimple1.coilType = HVAC.CoilType.CoolingWAHPSimple
    wahpSimple1.coilReportNum = ReportCoilSelection.getReportIndex(state, wahpSimple1.Name, wahpSimple1.coilType)
    wahpSimple1.RatedAirVolFlowRate = AutoSize
    wahpSimple1.RatedCapCoolTotal = AutoSize
    wahpSimple1.RatedCapCoolSens = AutoSize
    wahpSimple1.RatedWaterVolFlowRate = AutoSize
    wahpSimple1.WaterInletNodeNum = 1
    wahpSimple1.WaterOutletNodeNum = 2
    wahpSimple1.RatedEntWaterTemp = 30.0
    wahpSimple1.RatedEntAirWetbulbTemp = 19.0
    wahpSimple1.RatedEntAirDrybulbTemp = 27.0
    wahpSimple1.CompanionHeatingCoilNum = 2
    wahpSimple1.WAHPPlantType = DataPlant.PlantEquipmentType.CoilWAHPCoolingEquationFit
    var wahpSimple2 = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[2]
    wahpSimple2.WAHPType = WatertoAirHP.Heating
    wahpSimple2.coilType = HVAC.CoilType.CoolingWAHPSimple
    wahpSimple2.coilReportNum = ReportCoilSelection.getReportIndex(state, wahpSimple2.Name, wahpSimple2.coilType)
    wahpSimple2.RatedAirVolFlowRate = AutoSize
    wahpSimple2.RatedCapHeat = AutoSize
    wahpSimple2.RatedWaterVolFlowRate = 0.000185
    wahpSimple2.WaterInletNodeNum = 3
    wahpSimple2.WaterOutletNodeNum = 4
    wahpSimple2.RatedEntWaterTemp = 20.0
    wahpSimple2.RatedEntAirDrybulbTemp = 20.0
    wahpSimple2.CompanionCoolingCoilNum = 1
    wahpSimple2.WAHPPlantType = DataPlant.PlantEquipmentType.CoilWAHPHeatingEquationFit
    wahpSimple2.RatioRatedHeatRatedTotCoolCap = 1.23
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolVolFlow = 0.20
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatVolFlow = 0.0004
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesTemp = 13.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatDesTemp = 40
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDesHumRat = 0.0075
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].TimeStepNumAtCoolMax = 15
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].CoolDDNum = 1
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].HeatOutTemp = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInTemp = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInTemp = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesCoolCoilInHumRat = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].DesHeatCoilInHumRat = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneRetTempAtCoolPeak = 25.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtCoolPeak = 0.0045
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneRetTempAtHeatPeak = 15.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].ZoneHumRatAtHeatPeak = 0.0045
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum].OAVolFlow = 0.0
    var curve1 = AddCurve(state, "Curve1")
    curve1.curveType = CurveType.QuadLinear
    curve1.coeff[0] = -9.32564313298629
    curve1.coeff[1] = 11.088084240584
    curve1.coeff[2] = -1.75195196204063
    curve1.coeff[3] = 0.760820340847872
    curve1.coeff[4] = 0.0
    curve1.inputLimits[0].min = 0.0
    curve1.inputLimits[0].max = 80.0
    curve1.inputLimits[1].min = 0.0
    curve1.inputLimits[1].max = 100.0
    curve1.inputLimits[2].min = 0.0
    curve1.inputLimits[2].max = 2.0
    curve1.inputLimits[3].min = 0.0
    curve1.inputLimits[3].max = 2.0
    var curve2 = AddCurve(state, "Curve2")
    curve2.curveType = CurveType.QuintLinear
    curve2.coeff[0] = -5.26562830117273
    curve2.coeff[1] = 17.3118017582604
    curve2.coeff[2] = -11.4496890368762
    curve2.coeff[3] = -0.944804890543481
    curve2.coeff[4] = 0.739606605780884
    curve2.coeff[5] = 0.0
    curve2.inputLimits[0].min = 0.0
    curve2.inputLimits[0].max = 100.0
    curve2.inputLimits[1].min = 0.0
    curve2.inputLimits[1].max = 100.0
    curve2.inputLimits[2].min = 0.0
    curve2.inputLimits[2].max = 100.0
    curve2.inputLimits[3].min = 0.0
    curve2.inputLimits[3].max = 1.0
    curve2.inputLimits[4].min = 0.0
    curve2.inputLimits[4].max = 1.0
    var curve3 = AddCurve(state, "Curve3")
    curve3.curveType = CurveType.QuadLinear
    curve3.coeff[0] = -3.25323327026219
    curve3.coeff[1] = -0.990977022339372
    curve3.coeff[2] = 4.03828937789764
    curve3.coeff[3] = 0.952179101682919
    curve3.coeff[4] = 0.0
    curve3.inputLimits[0].min = -100
    curve3.inputLimits[0].max = 100
    curve3.inputLimits[1].min = -100
    curve3.inputLimits[1].max = 100
    curve3.inputLimits[2].min = 0
    curve3.inputLimits[2].max = 100
    curve3.inputLimits[3].min = 0
    curve3.inputLimits[3].max = 38
    var curve4 = AddCurve(state, "Curve4")
    curve4.curveType = CurveType.QuadLinear
    curve4.coeff[0] = -1.30782327125798
    curve4.coeff[1] = -2.37467612404102
    curve4.coeff[2] = 4.00919247797279
    curve4.coeff[3] = 0.615580752610271
    curve4.coeff[4] = 0.0
    curve4.inputLimits[0].min = -100
    curve4.inputLimits[0].max = 100
    curve4.inputLimits[1].min = -100
    curve4.inputLimits[1].max = 100
    curve4.inputLimits[2].min = 0
    curve4.inputLimits[2].max = 100
    curve4.inputLimits[3].min = 0
    curve4.inputLimits[3].max = 38
    var curve5 = AddCurve(state, "Curve5")
    curve5.curveType = CurveType.QuadLinear
    curve5.coeff[0] = -2.17352461285805
    curve5.coeff[1] = 0.830808361346509
    curve5.coeff[2] = 1.5682782658283
    curve5.coeff[3] = 0.689709515714146
    curve5.coeff[4] = 0.0
    curve5.inputLimits[0].min = -100
    curve5.inputLimits[0].max = 100
    curve5.inputLimits[1].min = -100
    curve5.inputLimits[1].max = 100
    curve5.inputLimits[2].min = 0
    curve5.inputLimits[2].max = 100
    curve5.inputLimits[3].min = 0
    curve5.inputLimits[3].max = 38
    wahpSimple1.TotalCoolCapCurve = curve1
    wahpSimple1.SensCoolCapCurve = curve2
    wahpSimple1.CoolPowCurve = curve3
    wahpSimple2.HeatCapCurve = curve4
    wahpSimple2.HeatPowCurve = curve5
    wahpSimple1.RatedCOPCoolAtRatedCdts = 5.12
    wahpSimple2.RatedCOPHeatAtRatedCdts = 3.0
    state.dataSize.DesDayWeath[1].Temp[15] = 32.0
    state.dataEnvrn.StdBaroPress = 101325.0
    state.dataSize.ZoneEqDXCoil = True
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(1)
    var loop = state.dataPlnt.PlantLoop[1]
    loop.Name = "Condenser Water Loop"
    loop.FluidName = "WATER"
    loop.glycol = Fluid.GetWater(state)
    var demandside = loop.LoopSide(DataPlant.LoopSideLocation.Demand)
    demandside.TotalBranches = 1
    demandside.Branch.allocate(1)
    var branch = demandside.Branch[1]
    branch.TotalComponents = 2
    branch.Comp.allocate(2)
    branch.Comp[1].Name = wahpSimple1.Name
    branch.Comp[1].Type = wahpSimple1.WAHPPlantType
    branch.Comp[1].NodeNumIn = wahpSimple1.WaterInletNodeNum
    wahpSimple1.plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, wahpSimple1.plantLoc)
    branch.Comp[2].Name = wahpSimple2.Name
    branch.Comp[2].Type = wahpSimple2.WAHPPlantType
    branch.Comp[2].NodeNumIn = wahpSimple2.WaterInletNodeNum
    wahpSimple2.plantLoc.loopNum = 1
    state.dataSize.NumPltSizInput = 1
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[1].PlantLoopName = "Condenser Water Loop"
    state.dataSize.PlantSizData[1].ExitTemp = 29.4
    state.dataSize.PlantSizData[1].DeltaT = 5.56
    WaterToAirHeatPumpSimple.SizeHVACWaterToAir(state, 1)
    WaterToAirHeatPumpSimple.SizeHVACWaterToAir(state, 2)
    EXPECT_NEAR(wahpSimple2.RatedCapHeatAtRatedCdts / wahpSimple1.RatedCapCoolAtRatedCdts, 1.23, 0.00001)
    EXPECT_NEAR(wahpSimple2.RatedWaterVolFlowRate - 0.000185, 0.0, 0.000001)
    EXPECT_NEAR(wahpSimple2.RatedWaterVolFlowRate - wahpSimple1.RatedWaterVolFlowRate, 0.0, 0.000001)

# Test: EquationFit_Initialization
def test_EquationFit_Initialization():
    var idf_objects = delimited_string([
        " Coil:Cooling:WaterToAirHeatPump:EquationFit,",
        "   Sys 5 Heat Pump Cooling Mode,  !- Name",
        "   ,                              !- Availability Schedule Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Inlet Node,  !- Water Inlet Node Name",
        "   Sys 5 Water to Air Heat Pump Source Side1 Outlet Node,  !- Water Outlet Node Name",
        "   Sys 5 Cooling Coil Air Inlet Node,  !- Air Inlet Node Name",
        "   Sys 5 Heating Coil Air Inlet Node,  !- Air Outlet Node Name",
        "   2.0,                     !- Rated Air Flow Rate {m3/s}",
        "   0.0033,                  !- Rated Water Flow Rate {m3/s}",
        "   20000,                   !- Gross Rated Total Cooling Capacity {W}",
        "   16000,                   !- Gross Rated Sensible Cooling Capacity {W}",
        "   7.007757577,             !- Gross Rated Cooling COP",
        "   ,                        !- Rated Entering Water Temperature",
        "   ,                        !- Rated Entering Air Dry-Bulb Temperature",
        "   ,                        !- Rated Entering Air Wet-Bulb Temperature",
        "   TotCoolCapCurve,         !- Total Cooling Capacity Curve Name",
        "   SensCoolCapCurve,        !- Sensible Cooling Capacity Curve Name",
        "   CoolPowCurve,            !- Cooling Power Consumption Curve Name",
        "   PLFFPLR,                 !- Part Load Fraction Correlation Curve Name",
        "   0,                       !- Nominal Time for Condensate Removal to Begin {s}",
        "   0;                       !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        "Curve:QuintLinear,",
        "  SensCoolCapCurve,     ! Curve Name",
        "  0,           ! CoefficientC1",
        "  0.2,           ! CoefficientC2",
        "  0.2,          ! CoefficientC3",
        "  0.2,          ! CoefficientC4",
        "  0.2,          ! CoefficientC5",
        "  0.2,           ! CoefficientC6",
        "  0.,                   ! Minimum Value of v",
        "  100.,                 ! Maximum Value of v",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  TotCoolCapCurve,      ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:QuadLinear,",
        "  CoolPowCurve,      ! Curve Name",
        "  0,          ! CoefficientC1",
        "  0.25,           ! CoefficientC2",
        "  0.25,          ! CoefficientC3",
        "  0.25,           ! CoefficientC4",
        "  0.25,          ! CoefficientC5",
        "  0.,                   ! Minimum Value of w",
        "  100.,                 ! Maximum Value of w",
        "  0.,                   ! Minimum Value of x",
        "  100.,                 ! Maximum Value of x",
        "  0.,                   ! Minimum Value of y",
        "  100.,                 ! Maximum Value of y",
        "  0,                    ! Minimum Value of z",
        "  100,                  ! Maximum Value of z",
        "  0.,                   ! Minimum Curve Output",
        "  38.;                  ! Maximum Curve Output",
        "Curve:Quadratic, PLFFPLR, 0.85, 0.83, 0.0, 0.0, 0.3, 0.85, 1.0, Dimensionless, Dimensionless; ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var CurrentModuleObject: String = "Coil:Cooling:DX:VariableSpeed"
    var num_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    ASSERT_EQ(0, num_coils)
    CurrentModuleObject = "Coil:Cooling:WaterToAirHeatPump:EquationFit"
    num_coils = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    ASSERT_EQ(1, num_coils)
    var TotalArgs: Int = 0
    var NumAlphas: Int = 0
    var NumNumbers: Int = 0
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, TotalArgs, NumAlphas, NumNumbers)
    EXPECT_EQ(TotalArgs, 23)
    EXPECT_EQ(NumAlphas, 10)
    EXPECT_EQ(NumNumbers, 13)
    WaterToAirHeatPumpSimple.GetSimpleWatertoAirHPInput(state)
    var HPNum: Int = 1
    EXPECT_EQ(state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum].Name, "SYS 5 HEAT PUMP COOLING MODE")
    var thisCoil = state.dataWaterToAirHeatPumpSimple.SimpleWatertoAirHP[HPNum]
    EXPECT_NEAR(thisCoil.RatedCOPCoolAtRatedCdts, 7.00776, 0.01)

# Register tests with the test fixture (simulating TEST_F macro)
def main():
    # Note: Mojo testing infrastructure would register these; for 1:1 translation we keep the test function names as is.
