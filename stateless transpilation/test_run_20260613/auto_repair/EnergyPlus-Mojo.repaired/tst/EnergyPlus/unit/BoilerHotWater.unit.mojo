# [Mojo] Port of BoilerHotWater.unit.cc
# 1:1 translation, no refactoring.

from gtest import gtest  # Assume gtest module provides TEST_F etc. but we'll define our own.
# Alternatively, use Mojo testing:
# from testing import *
# But we keep gtest-like macros for faithfulness.

# Includes translated to imports:
from EnergyPlus.Boilers import Boilers, BoilerSpecs
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchAirLoopPlant import DataBranchAirLoopPlant, ControlType
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataSizing import DataSizing, AutoSize
from EnergyPlus.FluidProperties import Fluid
from EnergyPlus.Plant.DataPlant import DataPlant, LoopSideLocation, PlantEquipmentType
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Psychrometrics import Psychrometrics
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, compare_err_stream, GetBoilerInput
# Test fixtures
def Boiler_HotWaterSizingTest():
    # state->dataFluid->init_state(*state); // Still necessary?
    state.dataFluid.init_state(state)
    state.dataBoilers.Boiler.append(Boilers.BoilerSpecs())  # emplace_back
    state.dataBoilers.Boiler[0].plantLoc.loopNum = 1
    state.dataBoilers.Boiler[0].SizFac = 1.2
    state.dataBoilers.Boiler[0].NomCap = 40000.0
    state.dataBoilers.Boiler[0].NomCapWasAutoSized = false
    state.dataBoilers.Boiler[0].VolFlowRate = 1.0
    state.dataBoilers.Boiler[0].VolFlowRateWasAutoSized = false
    state.dataPlnt.PlantLoop = List[DataPlant.PlantLoopType](1)  # allocate(1)
    state.dataSize.PlantSizData = List[DataSizing.PlantSizDataType](1)  # allocate(1)
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1  # 0-indexed
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataBoilers.Boiler[0].plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, state.dataBoilers.Boiler[0].plantLoc)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = True
    state.dataBoilers.Boiler[0].SizeBoiler(state)
    expect_equal(state.dataBoilers.Boiler[0].VolFlowRate, 1.0)
    expect_equal(state.dataBoilers.Boiler[0].NomCap, 40000.0)
    state.dataBoilers.Boiler[0].NomCapWasAutoSized = True
    state.dataBoilers.Boiler[0].VolFlowRateWasAutoSized = True
    state.dataBoilers.Boiler[0].NomCap = DataSizing.AutoSize
    state.dataBoilers.Boiler[0].VolFlowRate = DataSizing.AutoSize
    state.dataBoilers.Boiler[0].SizeBoiler(state)
    expect_near(state.dataBoilers.Boiler[0].VolFlowRate, 1.2, 0.000001)
    expect_near(state.dataBoilers.Boiler[0].NomCap, 49376304.0, 1.0)
    state.dataBoilers.Boiler = List[Boilers.BoilerSpecs]()  # clear()
    state.dataSize.PlantSizData = List[DataSizing.PlantSizDataType]()  # deallocate()
    state.dataPlnt.PlantLoop = List[DataPlant.PlantLoopType]()  # deallocate()

def Boiler_HotWaterAutoSizeTempTest():
    state.dataFluid.init_state(state)
    state.dataBoilers.Boiler.append(Boilers.BoilerSpecs())
    state.dataBoilers.Boiler[0].SizFac = 1.2
    state.dataBoilers.Boiler[0].NomCap = DataSizing.AutoSize
    state.dataBoilers.Boiler[0].NomCapWasAutoSized = True
    state.dataBoilers.Boiler[0].VolFlowRate = DataSizing.AutoSize
    state.dataBoilers.Boiler[0].VolFlowRateWasAutoSized = True
    state.dataPlnt.PlantLoop = List[DataPlant.PlantLoopType](1)
    state.dataSize.PlantSizData = List[DataSizing.PlantSizDataType](1)
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = True
    state.dataBoilers.Boiler[0].plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, state.dataBoilers.Boiler[0].plantLoc)
    var rho = state.dataBoilers.Boiler[0].plantLoc.loop.glycol.getDensity(state, 60.0, "Boiler_HotWaterAutoSizeTempTest")
    var Cp = state.dataBoilers.Boiler[0].plantLoc.loop.glycol.getSpecificHeat(state, 60.0, "Boiler_HotWaterAutoSizeTempTest")
    var NomCapBoilerExpected = rho * state.dataSize.PlantSizData[0].DesVolFlowRate * Cp * state.dataSize.PlantSizData[0].DeltaT * state.dataBoilers.Boiler[0].SizFac
    state.dataBoilers.Boiler[0].SizeBoiler(state)
    expect_equal(state.dataBoilers.Boiler[0].VolFlowRate, 1.2)
    expect_equal(state.dataBoilers.Boiler[0].NomCap, NomCapBoilerExpected)

def Boiler_HotWater_BlankDesignWaterFlowRate():
    var idf_objects = delimited_string({
        "Boiler:HotWater,",
        "  Boiler 1,                !- Name",
        "  NaturalGas,              !- Fuel Type",
        "  2344000,                 !- Nominal Capacity {W}",
        "  0.8,                     !- Nominal Thermal Efficiency",
        "  ,                        !- Efficiency Curve Temperature Evaluation Variable",
        "  ,                        !- Normalized Boiler Efficiency Curve Name",
        "  ,                        !- Design Water Flow Rate {m3/s}",
        "  ,                        !- Minimum Part Load Ratio",
        "  1,                       !- Maximum Part Load Ratio",
        "  1,                       !- Optimum Part Load Ratio",
        "  Node boiler 1 inlet,     !- Boiler Water Inlet Node Name",
        "  Node boiler 1 outlet,    !- Boiler Water Outlet Node Name",
        "  99.9,                    !- Water Outlet Upper Temperature Limit {C}",
        "  NotModulated,            !- Boiler Flow Mode",
        "  ,                        !- On Cycle Parasitic Electric Load {W}",
        "  1;                       !- Sizing Factor",
    })
    assert_true(process_idf(idf_objects))
    GetBoilerInput(state)
    expect_equal(1, int(state.dataBoilers.Boiler.size()))
    expect_equal(AutoSize, state.dataBoilers.Boiler[0].VolFlowRate)
    expect_enum_equal(state.dataBoilers.Boiler[0].FuelType, Constant.eFuel.NaturalGas)

def Boiler_HotWater_ZeroNominalCapacity():
    var idf_objects = delimited_string({
        "Boiler:HotWater,",
        "  Central Boiler,          !- Name",
        "  NaturalGas,              !- Fuel Type",
        "  0.0,                     !- Nominal Capacity {W}",
        "  0.8,                     !- Nominal Thermal Efficiency",
        "  LeavingBoiler,           !- Efficiency Curve Temperature Evaluation Variable",
        "  BoilerEfficiency,        !- Normalized Boiler Efficiency Curve Name",
        "  Autosize,                !- Design Water Flow Rate {m3/s}",
        "  0.0,                     !- Minimum Part Load Ratio",
        "  1.2,                     !- Maximum Part Load Ratio",
        "  1.0,                     !- Optimum Part Load Ratio",
        "  Boiler Inlet 1,          !- Boiler Water Inlet Node Name",
        "  Boiler Inlet 2;          !- Boiler Water Outlet Node Name",
        "Curve:Quadratic,",
        "  BoilerEfficiency,        !- Name",
        "  1.0,                     !- Coefficient1 Constant",
        "  0.0,                     !- Coefficient2 x",
        "  0.0,                     !- Coefficient3 x**2",
        "  0,                       !- Minimum Value of x",
        "  1;                       !- Maximum Value of x",
    })
    expect_false(process_idf(idf_objects, false))
    var expected_error = delimited_string({
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - \"0.000000\" - Expected number greater than 0.000000",
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - Failed to validate against child schema #0.",
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - Value type \"number\" for input \"0.000000\" not permitted by 'type' constraint.",
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - \"0.000000\" - Failed to match against any enum values.",
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - Failed to validate against child schema #1.",
        "   ** Severe  ** <root>[Boiler:HotWater][Central Boiler][nominal_capacity] - Failed to validate against any schemas allowed by anyOf constraint."})
    compare_err_stream(expected_error, True)

def Boiler_HotWater_BoilerEfficiency():
    var RunFlag = True
    var MyLoad = 1000000.0
    state.dataPlnt.TotNumLoops = 2
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    var idf_objects = delimited_string({
        "Boiler:HotWater,",
        "  Boiler 1,                !- Name",
        "  NaturalGas,              !- Fuel Type",
        "  Autosize,                !- Nominal Capacity {W}",
        "  0.8,                     !- Nominal Thermal Efficiency",
        "  LeavingBoiler,           !- Efficiency Curve Temperature Evaluation Variable",
        "  BoilerEfficiency,        !- Normalized Boiler Efficiency Curve Name",
        "  Autosize,                !- Design Water Flow Rate {m3/s}",
        "  0.0,                     !- Minimum Part Load Ratio",
        "  1.2,                     !- Maximum Part Load Ratio",
        "  1.0,                     !- Optimum Part Load Ratio",
        "  Node boiler 1 inlet,     !- Boiler Water Inlet Node Name",
        "  Node boiler 1 outlet,    !- Boiler Water Outlet Node Name",
        "  99.9,                    !- Water Outlet Upper Temperature Limit {C}",
        "  NotModulated,            !- Boiler Flow Mode",
        "  ,                        !- On Cycle Parasitic Electric Load {W}",
        "  1;                       !- Sizing Factor",
        "Curve:Quadratic,",
        "  BoilerEfficiency,        !- Name",
        "  0.5887682,               !- Coefficient1 Constant",
        "  0.7888184,               !- Coefficient2 x",
        "  -0.3862498,              !- Coefficient3 x**2",
        "  0,                       !- Minimum Value of x",
        "  1;                       !- Maximum Value of x",
    })
    expect_true(process_idf(idf_objects, false))
    state.init_state(state)
    state.dataPlnt.PlantLoop = List[DataPlant.PlantLoopType](state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l - 1].LoopSide(LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch = List[DataPlant.BranchType](1)
        var loopsidebranch = loopside.Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp = List[DataPlant.CompType](1)
    GetBoilerInput(state)
    var thisBoiler = state.dataBoilers.Boiler[0]
    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide(LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisBoiler.Name
    state.dataPlnt.PlantLoop[0].LoopSide(LoopSideLocation.Demand).Branch[0].Comp[0].Type = PlantEquipmentType.Boiler_Simple
    state.dataPlnt.PlantLoop[0].LoopSide(LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisBoiler.BoilerInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide(LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisBoiler.BoilerOutletNodeNum
    state.dataSize.PlantSizData = List[DataSizing.PlantSizDataType](1)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 0.1
    state.dataSize.PlantSizData[0].DeltaT = 10
    state.dataPlnt.PlantFirstSizesOkayToFinalize = True
    state.dataPlnt.PlantFirstSizesOkayToReport = True
    state.dataPlnt.PlantFinalSizesOkayToReport = True
    thisBoiler.InitBoiler(state)
    thisBoiler.SizeBoiler(state)
    state.dataGlobal.BeginEnvrnFlag = True
    thisBoiler.InitBoiler(state)
    thisBoiler.CalcBoilerModel(state, MyLoad, RunFlag, ControlType.SeriesActive)
    expect_near(thisBoiler.BoilerPLR, 0.24, 0.01)
    var ExpectedBoilerEff = (0.5887682 + 0.7888184 * thisBoiler.BoilerPLR - 0.3862498 * pow(thisBoiler.BoilerPLR, 2.0)) * thisBoiler.NomEffic
    expect_near(thisBoiler.BoilerEff, ExpectedBoilerEff, 0.01)

def Boiler_HotWater_Factory():
    state.dataBoilers.Boiler.append(Boilers.BoilerSpecs())
    state.dataBoilers.Boiler.append(Boilers.BoilerSpecs())
    state.dataBoilers.Boiler.append(Boilers.BoilerSpecs())
    state.dataBoilers.Boiler[0].Name = "Boiler1"
    state.dataBoilers.Boiler[1].Name = "Boiler2"
    state.dataBoilers.Boiler[2].Name = "Boiler3"
    state.dataBoilers.Boiler[2].NomCap = 1000.0
    state.dataBoilers.Boiler[2].MinPartLoadRat = 0.1
    state.dataBoilers.Boiler[2].MaxPartLoadRat = 1.1
    state.dataBoilers.Boiler[2].OptPartLoadRat = 1.0
    state.dataBoilers.getBoilerInputFlag = False
    var compPtr = Boilers.BoilerSpecs.factory(state, state.dataBoilers.Boiler[2].Name)
    var Location: PlantLocation
    var MaxLoad: Float64
    var MinLoad: Float64
    var OptLoad: Float64
    compPtr.getDesignCapacities(state, Location, MaxLoad, MinLoad, OptLoad)
    expect_equal(MinLoad, state.dataBoilers.Boiler[2].NomCap * state.dataBoilers.Boiler[2].MinPartLoadRat)
    expect_equal(100.0, MinLoad)
    expect_equal(MaxLoad, state.dataBoilers.Boiler[2].NomCap * state.dataBoilers.Boiler[2].MaxPartLoadRat)
    expect_equal(1100.0, MaxLoad)
    expect_equal(OptLoad, state.dataBoilers.Boiler[2].NomCap * state.dataBoilers.Boiler[2].OptPartLoadRat)
    expect_equal(1000.0, OptLoad)
    expect_equal(0.0, state.dataBoilers.Boiler[0].NomCap)
    expect_equal(0.0, state.dataBoilers.Boiler[1].NomCap)
    expect_equal(1000.0, state.dataBoilers.Boiler[2].NomCap)
    var thisBoiler = Boilers.BoilerSpecs.factory(state, state.dataBoilers.Boiler[1].Name)
    expect_equal(0.0, thisBoiler.NomCap)
    expect_equal(thisBoiler.Name, state.dataBoilers.Boiler[1].Name)