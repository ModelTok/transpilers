from gtest import gtest
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.CurveManager import Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.NodeInputManager import NodeInputManager
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantChillers import PlantChillers, ConstCOPChillerSpecs
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.DataBranchAirLoopPlant import DataBranchAirLoopPlant
from EnergyPlus.Fluid import Fluid
from EnergyPlus.UtilityRoutines import delimited_string

using EnergyPlus = EnergyPlus
using EnergyPlus::PlantChillers = PlantChillers

@EnergyPlusFixture
def ChillerConstantCOP_WaterCooled_Autosize():
    state.dataPlnt.TotNumLoops = 4
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    var idf_objects: String = delimited_string(
        [
            "  Chiller:ConstantCOP,",
            "    Chiller,                 !- Name",
            "    autosize,                !- Nominal Capacity {W}",
            "    4.0,                     !- Nominal COP {W/W}",
            "    autosize,                !- Design Chilled Water Flow Rate {m3/s}",
            "    autosize,                !- Design Condenser Water Flow Rate {m3/s}",
            "    Chiller ChW Inlet,       !- Chilled Water Inlet Node Name",
            "    Chiller ChW Outlet,      !- Chilled Water Outlet Node Name",
            "    Chiller Cnd Inlet,       !- Condenser Inlet Node Name",
            "    Chiller Cnd Outlet,      !- Condenser Outlet Node Name",
            "    WaterCooled,             !- Condenser Type",
            "    ConstantFlow,            !- Chiller Flow Mode",
            "    1,                       !- Sizing Factor",
            "    ,                        !- Basin Heater Capacity {W/K}",
            "    2,                       !- Basin Heater Setpoint Temperature {C}",
            "    ,                        !- temperature difference described above",
            "    ThermoCapFracCurve;      !- Thermosiphon Capacity Fraction Curve Name",
            "Curve:Linear, ThermoCapFracCurve, 0.0, 0.06, 0.0, 10.0, 0.0, 1.0, Dimensionless, Dimensionless;",
        ]
    )
    assert_true(process_idf(idf_objects, False))
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    ConstCOPChillerSpecs.getInput(state)
    var thisChiller = state.dataPlantChillers.ConstCOPChiller[1]
    state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[1].PlantSizNum = 1
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ConstCOP
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = thisChiller.EvapInletNodeNum
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = thisChiller.EvapOutletNodeNum
    state.dataPlnt.PlantLoop[2].Name = "CondenserWaterLoop"
    state.dataPlnt.PlantLoop[2].PlantSizNum = 2
    state.dataPlnt.PlantLoop[2].FluidName = "WATER"
    state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ConstCOP
    state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = thisChiller.CondInletNodeNum
    state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = thisChiller.CondOutletNodeNum
    state.dataSize.PlantSizData.allocate(2)
    state.dataSize.PlantSizData[1].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[1].DeltaT = 5.0
    state.dataSize.PlantSizData[2].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[2].DeltaT = 5.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = True
    state.dataPlnt.PlantFirstSizesOkayToReport = True
    state.dataPlnt.PlantFinalSizesOkayToReport = True
    var RunFlag: Bool = True
    var MyLoad: Real64 = -20000.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.size(state)
    state.dataGlobal.BeginEnvrnFlag = True
    thisChiller.initialize(state, RunFlag, MyLoad)
    assert_approx_equal(thisChiller.NomCap, 20987.5090557, 0.000001)
    assert_approx_equal(thisChiller.EvapVolFlowRate, 0.001, 0.000001)
    assert_approx_equal(thisChiller.EvapMassFlowRateMax, 0.999898, 0.0000001)
    assert_approx_equal(thisChiller.CondVolFlowRate, 0.0012606164769923673, 0.0000001)
    assert_approx_equal(thisChiller.CondMassFlowRateMax, 1.2604878941117141, 0.0000001)
    var EquipFlowCtrl: DataBranchAirLoopPlant.ControlType = DataBranchAirLoopPlant.ControlType.SeriesActive
    state.dataLoopNodes.Node[thisChiller.EvapInletNodeNum].Temp = 10.0
    state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].Temp = 6.0
    state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].TempSetPoint = 6.0
    state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 12.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.calculate(state, MyLoad, RunFlag, EquipFlowCtrl)
    assert_true(thisChiller.partLoadRatio > 0.95)
    assert_equal(thisChiller.thermosiphonStatus, 0)
    assert_true(thisChiller.Power > 4000.0)
    state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 5.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.calculate(state, MyLoad, RunFlag, EquipFlowCtrl)
    assert_true(thisChiller.partLoadRatio > 0.95)
    assert_equal(thisChiller.thermosiphonStatus, 0)
    assert_true(thisChiller.Power > 4000.0)
    MyLoad /= 15.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.calculate(state, MyLoad, RunFlag, EquipFlowCtrl)
    var dT: Real64 = thisChiller.EvapOutletTemp - thisChiller.CondInletTemp
    var thermosiphonCapFrac: Real64 = Curve.CurveValue(state, thisChiller.thermosiphonTempCurveIndex, dT)
    assert_true(thisChiller.partLoadRatio < 0.065)
    assert_true(thermosiphonCapFrac > thisChiller.partLoadRatio)
    assert_equal(thisChiller.thermosiphonStatus, 1)
    assert_equal(thisChiller.Power, 0.0)

@EnergyPlusFixture
def ChillerConstantCOP_Default_Des_Cond_Evap_Temps():
    state.dataPlnt.TotNumLoops = 12
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    var idf_objects: String = delimited_string(
        [
            "  Chiller:ConstantCOP,",
            "    Chiller_1_WaterCooled,   !- Name",
            "    autosize,                !- Nominal Capacity {W}",
            "    4.0,                     !- Nominal COP {W/W}",
            "    autosize,                !- Design Chilled Water Flow Rate {m3/s}",
            "    autosize,                !- Design Condenser Water Flow Rate {m3/s}",
            "    Chiller 1 ChW Inlet,     !- Chilled Water Inlet Node Name",
            "    Chiller 1 ChW Outlet,    !- Chilled Water Outlet Node Name",
            "    Chiller 1 Cnd Inlet,     !- Condenser Inlet Node Name",
            "    Chiller 1 Cnd Outlet,    !- Condenser Outlet Node Name",
            "    WaterCooled,             !- Condenser Type",
            "    ConstantFlow,            !- Chiller Flow Mode",
            "    1,                       !- Sizing Factor",
            "    ,                        !- Basin Heater Capacity {W/K}",
            "    2;                       !- Basin Heater Setpoint Temperature {C}",
            "  Chiller:ConstantCOP,",
            "    Chiller_2_AirCooled,     !- Name",
            "    autosize,                !- Nominal Capacity {W}",
            "    4.0,                     !- Nominal COP {W/W}",
            "    autosize,                !- Design Chilled Water Flow Rate {m3/s}",
            "    autosize,                !- Design Condenser Water Flow Rate {m3/s}",
            "    Chiller 2 ChW Inlet,     !- Chilled Water Inlet Node Name",
            "    Chiller 2 ChW Outlet,    !- Chilled Water Outlet Node Name",
            "    Chiller 2 Cnd Inlet,     !- Condenser Inlet Node Name",
            "    Chiller 2 Cnd Outlet,    !- Condenser Outlet Node Name",
            "    AirCooled,               !- Condenser Type",
            "    ConstantFlow,            !- Chiller Flow Mode",
            "    1,                       !- Sizing Factor",
            "    ,                        !- Basin Heater Capacity {W/K}",
            "    2;                       !- Basin Heater Setpoint Temperature {C}",
            "  Chiller:ConstantCOP,",
            "    Chiller_3_EvapCooled,    !- Name",
            "    autosize,                !- Nominal Capacity {W}",
            "    4.0,                     !- Nominal COP {W/W}",
            "    autosize,                !- Design Chilled Water Flow Rate {m3/s}",
            "    autosize,                !- Design Condenser Water Flow Rate {m3/s}",
            "    Chiller 3 ChW Inlet,     !- Chilled Water Inlet Node Name",
            "    Chiller 3 ChW Outlet,    !- Chilled Water Outlet Node Name",
            "    Chiller 3 Cnd Inlet,     !- Condenser Inlet Node Name",
            "    Chiller 3 Cnd Outlet,    !- Condenser Outlet Node Name",
            "    EvaporativelyCooled,     !- Condenser Type",
            "    ConstantFlow,            !- Chiller Flow Mode",
            "    1,                       !- Sizing Factor",
            "    ,                        !- Basin Heater Capacity {W/K}",
            "    2;                       !- Basin Heater Setpoint Temperature {C}",
        ]
    )
    assert_true(process_idf(idf_objects, False))
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    ConstCOPChillerSpecs.getInput(state)
    var thisChiller_1 = state.dataPlantChillers.ConstCOPChiller[1]
    assert_approx_equal(thisChiller_1.TempDesCondIn, 29.44, 1e-3)
    assert_approx_equal(thisChiller_1.TempDesEvapOut, 6.67, 1e-3)
    var thisChiller_2 = state.dataPlantChillers.ConstCOPChiller[2]
    assert_approx_equal(thisChiller_2.TempDesCondIn, 35.0, 1e-3)
    assert_approx_equal(thisChiller_2.TempDesEvapOut, 6.67, 1e-3)
    var thisChiller_3 = state.dataPlantChillers.ConstCOPChiller[3]
    assert_approx_equal(thisChiller_3.TempDesCondIn, 35.0, 1e-3)
    assert_approx_equal(thisChiller_3.TempDesEvapOut, 6.67, 1e-3)