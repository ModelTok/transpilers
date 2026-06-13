# Converted from C++ to Mojo - faithful 1:1 translation, no refactoring.
# Adjustments: 1-based -> 0-based indexing;  namespace removed; gtest macros replaced with assert.
# Imports: assume modules are available at the same relative path structure as original.

from Fixtures.EnergyPlusFixture import *  # Provides EnergyPlusFixture, TEST_F equivalent? We'll define functions manually.
from EnergyPlus.ConvectionCoefficients import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.HWBaseboardRadiator import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.PlantUtilities import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.ZoneEquipmentManager import *

# Equivalent of `using namespace EnergyPlus;` - import all names from modules.
# In Mojo, we can do `from EnergyPlus import *` but better to be explicit.
# We'll assume the above imports bring in all needed names.

# NOTE: The EnergyPlusFixture class is expected to be available from Fixtures.EnergyPlusFixture.
# It provides a `state` member of type reference (like `state`).
# In Mojo, we'll use a struct or class with a method `init_state`.

# Helper: convert gtest EXPECT_NEAR, EXPECT_EQ, EXPECT_FALSE, ASSERT_TRUE to assert.
def expect_near(actual: Float64, expected: Float64, tol: Float64):
    assert abs(actual - expected) <= tol, "Expect near failed: {} vs {}".format(actual, expected)

def expect_eq(actual, expected):
    assert actual == expected, "Expect eq failed: {} vs {}".format(actual, expected)

def expect_false(cond: Bool):
    assert not cond, "Expect false failed"

def assert_true(cond: Bool):
    assert cond, "Assert true failed"

# Test functions keep original names (without TEST_F wrapper).
def HWBaseboardRadiator_CalcHWBaseboard():
    # Assume fixture provides state variable, but for standalone, we create state? 
    # The original uses `state->init_state(*state)`. We'll assume we have a global state.
    # In Mojo, we'll mimic the fixture pattern: the function receives the fixture's state.
    # For simplicity, we'll use a top-level `state` var (from fixture or global).
    # However, the C++ code uses `state` as a shared pointer? We'll assume `state` is a reference to an EnergyPlusData object.
    # This translation expects a fixture instance with a `state` field.
    # We'll define the test function to take no arguments and use a global `state` for demonstration.
    # In a real Mojo test, you'd instantiate the fixture and call its methods.
    # We'll keep the code as close as possible, just remove pointer syntax.

    # We need to access `state` as a variable. Let's assume it's available in the scope.
    # For translation, we'll use `state` as a reference variable.
    var state = EnergyPlusData()  # Placeholder; actual initialization from fixture.
    state.init_state(state)

    var LoadMet: Float64
    var BBNum: Int
    var HWBaseboard = state.dataHWBaseboardRad.HWBaseboard
    var HWBaseboardDesignObject = state.dataHWBaseboardRad.HWBaseboardDesignObject
    state.dataLoopNodes.Node.allocate(1)
    HWBaseboard.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    state.dataPlnt.PlantLoop.allocate(1)
    HWBaseboardDesignObject.allocate(1)

    # 1-based indexing: Node(1) -> Node[0]
    state.dataLoopNodes.Node[0].MassFlowRate = 0.40
    state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = false
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 12000.0

    BBNum = 1
    LoadMet = 0.0
    HWBaseboard[0].DesignObjectPtr = 1
    HWBaseboard[0].ZonePtr = 1
    HWBaseboard[0].AirInletTemp = 21.0
    HWBaseboard[0].WaterInletTemp = 82.0
    HWBaseboard[0].WaterInletNode = 1
    HWBaseboard[0].WaterMassFlowRateMax = 0.40
    HWBaseboard[0].AirMassFlowRateStd = 0.5
    HWBaseboard[0].availSched = Sched.GetScheduleAlwaysOn(state)
    HWBaseboard[0].UA = 370
    HWBaseboard[0].QBBRadSource = 0.0

    state.dataPlnt.PlantLoop[0].FluidName = "Water"
    state.dataPlnt.PlantLoop[0].FluidType = Node.FluidType.Water
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    HWBaseboard[0].plantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, HWBaseboard[0].plantLoc)

    CalcHWBaseboard(state, BBNum, LoadMet)

    expect_near(HWBaseboard[0].TotPower, 14746.226690452937, 0.000001)
    expect_near(HWBaseboard[0].AirOutletTemp, 50.349854486072232, 0.000001)
    expect_near(HWBaseboard[0].WaterOutletTemp, 73.224991258180438, 0.000001)
    expect_near(HWBaseboard[0].AirMassFlowRate, 0.5, 0.000001)

    # Deallocate arrays (in Mojo, these may be automatic, but kept for parity)
    state.dataLoopNodes.Node.deallocate()
    HWBaseboard.deallocate()
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.deallocate()
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.deallocate()
    state.dataPlnt.PlantLoop.deallocate()

def HWBaseboardRadiator_HWBaseboardWaterFlowResetTest():
    var state = EnergyPlusData()
    state.init_state(state)
    var LoadMet: Float64
    var BBNum: Int
    state.dataFluid.init_state(state)
    BBNum = 1
    LoadMet = 0.0
    var HWBaseboard = state.dataHWBaseboardRad.HWBaseboard
    var HWBaseboardDesignObject = state.dataHWBaseboardRad.HWBaseboardDesignObject
    state.dataLoopNodes.Node.allocate(2)
    HWBaseboard.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.allocate(1)
    state.dataPlnt.PlantLoop.allocate(1)
    HWBaseboardDesignObject.allocate(1)

    state.dataZoneEnergyDemand.CurDeadBandOrSetback[0] = false
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0  # zero load test
    HWBaseboard[0].DesignObjectPtr = 1
    HWBaseboard[0].Name = "HWRadiativeConvectiveBB"
    HWBaseboard[0].EquipType = DataPlant.PlantEquipmentType.Baseboard_Rad_Conv_Water
    HWBaseboard[0].ZonePtr = 1
    HWBaseboard[0].AirInletTemp = 21.0
    HWBaseboard[0].WaterInletTemp = 82.0
    HWBaseboard[0].WaterInletNode = 1
    HWBaseboard[0].WaterOutletNode = 2
    HWBaseboard[0].WaterMassFlowRateMax = 0.40
    HWBaseboard[0].AirMassFlowRateStd = 0.5
    HWBaseboard[0].availSched = Sched.GetScheduleAlwaysOn(state)
    HWBaseboard[0].UA = 400.0
    HWBaseboard[0].QBBRadSource = 0.0

    state.dataPlnt.PlantLoop[0].FluidName = "Water"
    state.dataPlnt.PlantLoop[0].FluidType = Node.FluidType.Water
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataLoopNodes.Node[HWBaseboard[0].WaterInletNode - 1].MassFlowRate = 0.2
    state.dataLoopNodes.Node[HWBaseboard[0].WaterInletNode - 1].MassFlowRateMax = 0.4
    state.dataLoopNodes.Node[HWBaseboard[0].WaterOutletNode - 1].MassFlowRate = 0.2
    state.dataLoopNodes.Node[HWBaseboard[0].WaterOutletNode - 1].MassFlowRateMax = 0.4

    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):  # 1-based to 0-based: l-1
        var loopside = state.dataPlnt.PlantLoop[l-1].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = loopside.Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)

    state.dataPlnt.PlantLoop[0].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = HWBaseboard[0].Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = HWBaseboard[0].EquipType
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = HWBaseboard[0].WaterInletNode
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumOut = HWBaseboard[0].WaterOutletNode
    HWBaseboard[0].plantLoc = {1, DataPlant.LoopSideLocation.Demand, 1, 0}
    PlantUtilities.SetPlantLocationLinks(state, HWBaseboard[0].plantLoc)

    CalcHWBaseboard(state, BBNum, LoadMet)
    expect_eq(LoadMet, 0.0)
    expect_eq(HWBaseboard[0].TotPower, 0.0)
    expect_eq(state.dataLoopNodes.Node[HWBaseboard[0].WaterInletNode - 1].MassFlowRate, 0.0)
    expect_eq(HWBaseboard[0].AirOutletTemp, HWBaseboard[0].AirInletTemp)
    expect_eq(HWBaseboard[0].WaterOutletTemp, HWBaseboard[0].WaterInletTemp)
    expect_eq(HWBaseboard[0].AirMassFlowRate, 0.0)

    state.dataLoopNodes.Node.deallocate()
    HWBaseboard.deallocate()
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.deallocate()
    state.dataZoneEnergyDemand.CurDeadBandOrSetback.deallocate()
    state.dataPlnt.PlantLoop.deallocate()

def HWBaseboardRadiator_HWBaseboardWaterInputTest():
    var errorFound: Bool = false
    var absTol: Float64 = 0.00001
    # idf_objects as a list of strings; convert to delimited_string equivalent
    var idf_objects = delimited_string([
        "  ZoneHVAC:Baseboard:RadiantConvective:Water,",
        "    ThisIsABaseboard,        !- Name",
        "    Baseboard Design,        !- Design Object",
        "    ,                        !- Availability Schedule Name",
        "    Zone BB Water In Node,   !- Inlet Node Name",
        "    Zone BB Water Out Node,  !- Outlet Node Name",
        "    87.78,                   !- Rated Average Water Temperature {C}",
        "    0.063,                   !- Rated Water Mass Flow Rate {kg/s}",
        "    autosize,                !- Heating Design Capacity {W}",
        "    autosize,                !- Maximum Water Flow Rate {m3/s}",
        "    TheFloor,                !- Surface 1 Name",
        "    0.8;                     !- Fraction of Radiant Energy to Surface 1",
        "  ZoneHVAC:Baseboard:RadiantConvective:Water:Design,",
        "    Baseboard Design,        !- Name",
        "    HeatingDesignCapacity,   !- Heating Design Capacity Method",
        "    ,                        !- Heating Design Capacity Per Floor Area {W/m2}",
        "    ,                        !- Fraction of Autosized Heating Design Capacity",
        "    0.001,                   !- Convergence Tolerance",
        "    0.4,                     !- Fraction Radiant",
        "    0.2;                     !- Fraction of Radiant Energy Incident on People",
        "  Zone,",
        "    ThisIsAZone,  !- Name",
        "    0,            !- Direction of Relative North {deg}",
        "    0,            !- X Origin {m}",
        "    0,            !- Y Origin {m}",
        "    0,            !- Z Origin {m}",
        "    1,            !- Type",
        "    1,            !- Multiplier",
        "    3.0,          !- Ceiling Height {m}",
        "    200.0;        !- Volume {m3}",
        "  BuildingSurface:Detailed,",
        "    TheFloor,      !- Name",
        "    FLOOR,         !- Surface Type",
        "    MyCons,        !- Construction Name",
        "    ThisIsAZone,   !- Zone Name",
        "    ,              !- Space Name",
        "    Ground,        !- Outside Boundary Condition",
        "    C1-1,          !- Outside Boundary Condition Object",
        "    NoSun,         !- Sun Exposure",
        "    NoWind,        !- Wind Exposure",
        "    0.0,           !- View Factor to Ground",
        "    4,             !- Number of Vertices",
        "    26.8,3.7,2.4,  !- X,Y,Z ==> Vertex 1 {m}",
        "    30.5,0.0,2.4,  !- X,Y,Z ==> Vertex 2 {m}",
        "    0.0,0.0,2.4,   !- X,Y,Z ==> Vertex 3 {m}",
        "    3.7,3.7,2.4;   !- X,Y,Z ==> Vertex 4 {m}",
        "  Construction,",
        "    MyCons,        !- Name",
        "    MyLayer;       !- Outside Layer",
        "  Material,",
        "    MyLayer,       !- Name",
        "    MediumRough,   !- Roughness",
        "    0.1,           !- Thickness {m}",
        "    1.0,           !- Conductivity {W/m-K}",
        "    1000.0,        !- Density {kg/m3}",
        "    800.0,         !- Specific Heat {J/kg-K}",
        "    0.9,           !- Thermal Absorptance",
        "    0.65,          !- Solar Absorptance",
        "    0.65;          !- Visible Absorptance",
        "  ZoneHVAC:EquipmentList,",
        "    MyZoneEquipmentList,     !- Name",
        "    SequentialLoad,          !- Load Distribution Scheme",
        "    ZoneHVAC:Baseboard:RadiantConvective:Water,  !- Zone Equipment 1 Object Type",
        "    ThisIsABaseboard,        !- Zone Equipment 1 Name",
        "    1,                       !- Zone Equipment 1 Cooling Sequence",
        "    1,                       !- Zone Equipment 1 Heating or No-Load Sequence",
        "    ,                        !- Zone Equipment 1 Sequential Cooling Fraction Schedule Name",
        "    ;                        !- Zone Equipment 1 Sequential Heating Fraction Schedule Name",
        "  ZoneHVAC:EquipmentConnections,",
        "  ThisIsAZone,           !- Zone Name",
        "  MyZoneEquipmentList,   !- Zone Conditioning Equipment List Name",
        "  ThisIsAZone In Nodes,  !- Zone Air Inlet Node or NodeList Name",
        "  ,                      !- Zone Air Exhaust Node or NodeList Name",
        "  ThisIsAZone Node,      !- Zone Air Node Name",
        "  ThisIsAZone Out Node;  !- Zone Return Air Node or NodeList Name",
    ])
    assert_true(process_idf(idf_objects))
    var state = EnergyPlusData()
    state.init_state(state)
    errorFound = false
    HeatBalanceManager.GetZoneData(state, errorFound)
    expect_false(errorFound)
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = false
    errorFound = false
    Material.GetMaterialData(state, errorFound)
    expect_false(errorFound)
    errorFound = false
    HeatBalanceManager.GetConstructData(state, errorFound)
    expect_false(errorFound)
    errorFound = false
    state.dataSurfaceGeometry.CosZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.SinZoneRelNorth.allocate(1)
    state.dataSurfaceGeometry.CosZoneRelNorth[0] = Math.cos(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.SinZoneRelNorth[0] = Math.sin(-state.dataHeatBal.Zone[0].RelNorth * Constant.DegToRad)
    state.dataSurfaceGeometry.CosBldgRelNorth = 1.0
    state.dataSurfaceGeometry.SinBldgRelNorth = 0.0
    SurfaceGeometry.GetSurfaceData(state, errorFound)
    expect_false(errorFound)
    ZoneEquipmentManager.GetZoneEquipment(state)
    GetHWBaseboardInput(state)
    var surfNumTheFloor: Int = Util.FindItemInList("THEFLOOR", state.dataSurface.Surface)
    expect_eq(state.dataSurface.allGetsRadiantHeatSurfaceList[0], surfNumTheFloor)
    assert_true(state.dataSurface.surfIntConv[surfNumTheFloor].getsRadiantHeat)
    expect_near(state.dataHWBaseboardRad.HWBaseboard[0].FracDistribToSurf[0], 0.8, absTol)
    expect_near(state.dataHWBaseboardRad.HWBaseboardDesignObject[0].FracRadiant, 0.4, absTol)
    expect_near(state.dataHWBaseboardRad.HWBaseboardDesignObject[0].FracDistribPerson, 0.2, absTol)
    expect_near(state.dataHWBaseboardRad.HWBaseboard[0].FracConvect, 0.6, absTol)
    state.dataSize.CurZoneEqNum = 1
    state.dataSize.ZoneSizingRunDone = true
    state.dataSize.FinalZoneSizing.allocate(1)
    state.dataSize.FinalZoneSizing[0].NonAirSysDesHeatLoad = 1300.0
    state.dataSize.ZoneEqSizing.allocate(1)
    state.dataSize.ZoneEqSizing[0].SizingMethod.allocate(HVAC.NumOfSizingTypes)
    state.dataHWBaseboardRad.HWBaseboard[0].HeatingCapMethod = DataSizing.HeatingDesignCapacity
    state.dataHWBaseboardRad.HWBaseboard[0].ScaledHeatingCapacity = DataSizing.AutoSize
    state.dataHWBaseboardRad.HWBaseboard[0].plantLoc.loopNum = 1
    state.dataPlnt.PlantLoop.allocate(1)
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[0].DeltaT = 10.0
    state.dataPlnt.PlantLoop[0].LoopSide[0].Branch.allocate(1)
    state.dataPlnt.PlantLoop[0].LoopSide[0].Branch[0].Comp.allocate(1)
    var this_loop = state.dataPlnt.PlantLoop[0]
    this_loop.glycol = Fluid.GetWater(state)
    var this_loop_side = this_loop.LoopSide[0]
    var this_branch = state.dataPlnt.PlantLoop[0].LoopSide[0].Branch[0]
    var this_comp = state.dataPlnt.PlantLoop[0].LoopSide[0].Branch[0].Comp[0]
    state.dataHWBaseboardRad.HWBaseboard[0].plantLoc.loop = this_loop
    state.dataHWBaseboardRad.HWBaseboard[0].plantLoc.side = this_loop_side
    state.dataHWBaseboardRad.HWBaseboard[0].plantLoc.branch = this_branch
    state.dataHWBaseboardRad.HWBaseboard[0].plantLoc.comp = this_comp
    state.files.eio.open_as_stringstream()
    SizeHWBaseboard(state, 1)
    expect_near(state.dataHWBaseboardRad.HWBaseboard[0].UA, 24.2144, 0.0001)
    expect_near(state.dataHWBaseboardRad.HWBaseboard[0].WaterVolFlowRateMax, 3.15941E-05, 0.0000001)
    assert_true(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:RadiantConvective:Water, THISISABASEBOARD, "
                                              "Design Size Heating Load [W], 1300.00",
                                              false))
    assert_true(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:RadiantConvective:Water, THISISABASEBOARD, "
                                              "Design Size Maximum Water Flow Rate [m3/s], 3.15941E-05",
                                              false))
    assert_true(compare_eio_stream_substring("Component Sizing Information, ZoneHVAC:Baseboard:RadiantConvective:Water, THISISABASEBOARD, "
                                              "U-Factor times Area [W/C], 24.2144"))