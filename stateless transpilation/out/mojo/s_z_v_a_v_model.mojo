# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from math import fabs


# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - from EnergyPlus.Data.EnergyPlusData
# FanCoilData - from EnergyPlus.FanCoilUnits
# UnitarySys - from EnergyPlus.UnitarySystem
# Node - from EnergyPlus.DataLoopNode
# PlantLocation - from EnergyPlus.DataPlant
# LoopSideLocation, MixerType, CoilType, CompressorOp - from EnergyPlus.HVAC
# Psychrometrics functions - from EnergyPlus.Psychrometrics
# PlantUtilities functions - from EnergyPlus.PlantUtilities
# General functions - from EnergyPlus.General
# FanCoilUnits functions - from EnergyPlus.FanCoilUnits
# ShowWarningMessage, ShowContinueError, etc. - from EnergyPlus.UtilityRoutines


@value
struct LoopSideLocation:
    Invalid: Int32 = 0


@value
struct MixerType:
    SupplySide: Int32 = 0


@value
struct CoilType:
    HeatingWater: Int32 = 0


@value
struct CompressorOp:
    Off: Int32 = 0
    On: Int32 = 1


struct PlantLocation:
    var loopNum: Int32
    var loopSideLocation: Int32
    var branchNum: Int32
    var compNum: Int32
    
    fn __init__(
        inout self,
        loopNum: Int32 = 0,
        loopSideLocation: Int32 = 0,
        branchNum: Int32 = 0,
        compNum: Int32 = 0,
    ):
        self.loopNum = loopNum
        self.loopSideLocation = loopSideLocation
        self.branchNum = branchNum
        self.compNum = compNum


struct Node:
    var Temp: Float64
    var HumRat: Float64
    var MassFlowRate: Float64
    
    fn __init__(inout self):
        self.Temp = 0.0
        self.HumRat = 0.0
        self.MassFlowRate = 0.0


struct NodeArray:
    var nodes: DynamicVector[Node]
    
    fn __init__(inout self):
        self.nodes = DynamicVector[Node]()
    
    fn __getitem__(self, key: Int32) -> Node:
        if key >= len(self.nodes):
            return Node()
        return self.nodes[key]


struct LoopNodesData:
    var Node: NodeArray
    
    fn __init__(inout self):
        self.Node = NodeArray()


struct EnergyPlusData:
    var dataLoopNodes: LoopNodesData
    
    fn __init__(inout self):
        self.dataLoopNodes = LoopNodesData()


trait FanCoilData:
    fn get_AirInNode(self) -> Int32: ...
    fn get_AirOutNode(self) -> Int32: ...
    fn get_ControlZoneNum(self) -> Int32: ...
    fn get_NodeNumOfControlledZone(self) -> Int32: ...
    fn get_MaxCoolCoilFluidFlow(self) -> Float64: ...
    fn get_MaxHeatCoilFluidFlow(self) -> Float64: ...
    fn get_DesignMinOutletTemp(self) -> Float64: ...
    fn get_DesignMaxOutletTemp(self) -> Float64: ...
    fn get_MaxNoCoolHeatAirMassFlow(self) -> Float64: ...
    fn get_MaxCoolAirMassFlow(self) -> Float64: ...
    fn get_MaxHeatAirMassFlow(self) -> Float64: ...
    fn get_LowSpeedCoolFanRatio(self) -> Float64: ...
    fn get_LowSpeedHeatFanRatio(self) -> Float64: ...
    fn get_CoolCoilFluidInletNode(self) -> Int32: ...
    fn get_CoolCoilFluidOutletNodeNum(self) -> Int32: ...
    fn get_CoolCoilPlantLoc(self) -> PlantLocation: ...
    fn get_CoolCoilInletNodeNum(self) -> Int32: ...
    fn get_CoolCoilOutletNodeNum(self) -> Int32: ...
    fn get_HeatCoilFluidInletNode(self) -> Int32: ...
    fn get_HeatCoilFluidOutletNodeNum(self) -> Int32: ...
    fn get_HeatCoilPlantLoc(self) -> PlantLocation: ...
    fn get_HeatCoilInletNodeNum(self) -> Int32: ...
    fn get_HeatCoilOutletNodeNum(self) -> Int32: ...
    fn get_ATMixerExists(self) -> Bool: ...
    fn get_ATMixerType(self) -> Int32: ...
    fn get_ATMixerOutNode(self) -> Int32: ...
    fn set_FanPartLoadRatio(inout self, val: Float64): ...
    fn get_FanPartLoadRatio(self) -> Float64: ...
    fn set_HeatCoilWaterFlowRatio(inout self, val: Float64): ...
    fn get_HeatCoilWaterFlowRatio(self) -> Float64: ...
    fn get_ControlZoneMassFlowFrac(self) -> Float64: ...
    fn get_MaxIterIndex(self) -> Int32: ...
    fn get_RegulaFalsiFailedIndex(self) -> Int32: ...
    fn get_UnitType(self) -> StringRef: ...
    fn get_Name(self) -> StringRef: ...


trait UnitarySys:
    fn get_AirInNode(self) -> Int32: ...
    fn get_AirOutNode(self) -> Int32: ...
    fn get_ControlZoneNum(self) -> Int32: ...
    fn get_NodeNumOfControlledZone(self) -> Int32: ...
    fn get_MaxCoolCoilFluidFlow(self) -> Float64: ...
    fn get_MaxHeatCoilFluidFlow(self) -> Float64: ...
    fn get_DesignMinOutletTemp(self) -> Float64: ...
    fn get_DesignMaxOutletTemp(self) -> Float64: ...
    fn get_MaxNoCoolHeatAirMassFlow(self) -> Float64: ...
    fn get_MaxCoolAirMassFlow(self) -> Float64: ...
    fn get_MaxHeatAirMassFlow(self) -> Float64: ...
    fn get_LowSpeedCoolFanRatio(self) -> Float64: ...
    fn get_LowSpeedHeatFanRatio(self) -> Float64: ...
    fn get_CoolCoilFluidInletNode(self) -> Int32: ...
    fn get_CoolCoilFluidOutletNodeNum(self) -> Int32: ...
    fn get_CoolCoilPlantLoc(self) -> PlantLocation: ...
    fn get_CoolCoilInletNodeNum(self) -> Int32: ...
    fn get_CoolCoilOutletNodeNum(self) -> Int32: ...
    fn get_HeatCoilFluidInletNode(self) -> Int32: ...
    fn get_HeatCoilFluidOutletNodeNum(self) -> Int32: ...
    fn get_HeatCoilPlantLoc(self) -> PlantLocation: ...
    fn get_HeatCoilInletNodeNum(self) -> Int32: ...
    fn get_HeatCoilOutletNodeNum(self) -> Int32: ...
    fn get_ATMixerExists(self) -> Bool: ...
    fn get_ATMixerType(self) -> Int32: ...
    fn get_ATMixerOutNode(self) -> Int32: ...
    fn set_FanPartLoadRatio(inout self, val: Float64): ...
    fn get_FanPartLoadRatio(self) -> Float64: ...
    fn set_CoolCoilWaterFlowRatio(inout self, val: Float64): ...
    fn get_CoolCoilWaterFlowRatio(self) -> Float64: ...
    fn set_HeatCoilWaterFlowRatio(inout self, val: Float64): ...
    fn get_HeatCoilWaterFlowRatio(self) -> Float64: ...
    fn get_ControlZoneMassFlowFrac(self) -> Float64: ...
    fn get_MaxIterIndex(self) -> Int32: ...
    fn get_RegulaFalsiFailedIndex(self) -> Int32: ...
    fn get_UnitType(self) -> StringRef: ...
    fn get_Name(self) -> StringRef: ...
    fn set_m_SimASHRAEModelOn(inout self, val: Bool): ...
    fn get_m_CoolingSpeedNum(self) -> Int32: ...
    fn set_m_CoolingSpeedNum(inout self, val: Int32): ...
    fn get_m_NumOfSpeedCooling(self) -> Int32: ...
    fn get_m_HeatingSpeedNum(self) -> Int32: ...
    fn set_m_HeatingSpeedNum(inout self, val: Int32): ...
    fn get_m_NumOfSpeedHeating(self) -> Int32: ...
    fn get_heatCoilType(self) -> Int32: ...
    fn calcUnitarySystemToLoad(
        inout self,
        state: EnergyPlusData,
        AirLoopNum: Int32,
        FirstHVACIteration: Bool,
        CoolPLR: Float64,
        HeatPLR: Float64,
        OnOffAirFlowRatio: Float64,
        inout TempSensOutput: Float64,
        inout TempLatOutput: Float64,
        HXUnitOn: Bool,
        HeatCoilLoad: Float64,
        SupHeaterLoad: Float64,
        CompressorONFlag: Int32,
    ): ...
    fn calcUnitarySystemWaterFlowResidual(
        inout self,
        state: EnergyPlusData,
        PartLoadRatio: Float64,
        FirstHVACIteration: Bool,
        ZoneLoad: Float64,
        AirInNode: Int32,
        OnOffAirFlowRatio: Float64,
        AirLoopNum: Int32,
        coilFluidInletNode: Int32,
        maxCoilFluidFlow: Float64,
        lowSpeedFanRatio: Float64,
        minAirMassFlow: Float64,
        minTempTarget: Float64,
        maxAirMassFlow: Float64,
        CoolingLoad: Bool,
        iterWaterAirOrNot: Bool,
    ) -> Float64: ...


fn psy_h_fn_tdb_w(Tdb: Float64, W: Float64) -> Float64:
    return 0.0


fn calc_4pipe_fan_coil(
    state: EnergyPlusData,
    SysIndex: Int32,
    ControlZoneNum: Int32,
    FirstHVACIteration: Bool,
    inout TempSensOutput: Float64,
    PartLoadRatio: Float64,
) -> None:
    pass


fn calc_fan_coil_water_flow_residual(
    state: EnergyPlusData,
    PartLoadRatio: Float64,
    SysIndex: Int32,
    FirstHVACIteration: Bool,
    ControlZoneNum: Int32,
    ZoneLoad: Float64,
    AirInNode: Int32,
    coilFluidInletNode: Int32,
    maxCoilFluidFlow: Float64,
    minAirMassFlow: Float64,
) -> Float64:
    return 0.0


fn calc_fan_coil_air_and_water_flow_residual(
    state: EnergyPlusData,
    PartLoadRatio: Float64,
    SysIndex: Int32,
    FirstHVACIteration: Bool,
    ControlZoneNum: Int32,
    ZoneLoad: Float64,
    AirInNode: Int32,
    coilFluidInletNode: Int32,
    minFlow: Float64,
) -> Float64:
    return 0.0


fn set_component_flow_rate(
    state: EnergyPlusData,
    flowRate: Float64,
    inletNode: Int32,
    outletNode: Int32,
    plantLoc: PlantLocation,
) -> None:
    pass


fn solve_root(
    state: EnergyPlusData,
    Accuracy: Float64,
    MaxIter: Int32,
    inout SolFlag: Int32,
    inout ResultX: Float64,
    f: fn(Float64) -> Float64,
    XMin: Float64,
    XMax: Float64,
) -> None:
    pass


fn show_warning_message(state: EnergyPlusData, message: StringRef) -> None:
    pass


fn show_continue_error(state: EnergyPlusData, message: StringRef) -> None:
    pass


fn show_continue_error_time_stamp(state: EnergyPlusData, message: StringRef) -> None:
    pass


fn show_recurring_warning_error_at_end(state: EnergyPlusData, message: StringRef, value: Float64) -> None:
    pass


fn calc_szVAV_model_fan_coil(
    state: EnergyPlusData,
    inout szVAV_model: FanCoilData,
    SysIndex: Int32,
    FirstHVACIteration: Bool,
    CoolingLoad: Bool,
    HeatingLoad: Bool,
    ZoneLoad: Float64,
    inout OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool,
    AirLoopNum: Int32,
    inout PartLoadRatio: Float64,
    CompressorONFlag: Int32,
) -> None:
    var MaxIter: Int32 = 100
    var SolFlag: Int32 = 0
    var MessagePrefix: String = ""
    
    var lowBoundaryLoad: Float64 = 0.0
    var highBoundaryLoad: Float64 = 0.0
    var minHumRat: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var coilActive: Bool = False
    var AirMassFlow: Float64 = 0.0
    
    var maxCoilFluidFlow: Float64 = 0.0
    var maxOutletTemp: Float64 = 0.0
    var minAirMassFlow: Float64 = 0.0
    var maxAirMassFlow: Float64 = 0.0
    var lowSpeedFanRatio: Float64 = 0.0
    var coilFluidInletNode: Int32 = 0
    var coilFluidOutletNode: Int32 = 0
    var coilPlantLoc: PlantLocation = PlantLocation()
    var coilAirInletNode: Int32 = 0
    var coilAirOutletNode: Int32 = 0
    
    var TempSensOutput: Float64 = 0.0
    
    if CoolingLoad:
        maxCoilFluidFlow = szVAV_model.get_MaxCoolCoilFluidFlow()
        maxOutletTemp = szVAV_model.get_DesignMinOutletTemp()
        minAirMassFlow = szVAV_model.get_MaxNoCoolHeatAirMassFlow()
        maxAirMassFlow = szVAV_model.get_MaxCoolAirMassFlow()
        lowSpeedFanRatio = szVAV_model.get_LowSpeedCoolFanRatio()
        coilFluidInletNode = szVAV_model.get_CoolCoilFluidInletNode()
        coilFluidOutletNode = szVAV_model.get_CoolCoilFluidOutletNodeNum()
        coilPlantLoc = szVAV_model.get_CoolCoilPlantLoc()
        coilAirInletNode = szVAV_model.get_CoolCoilInletNodeNum()
        coilAirOutletNode = szVAV_model.get_CoolCoilOutletNodeNum()
    elif HeatingLoad:
        maxCoilFluidFlow = szVAV_model.get_MaxHeatCoilFluidFlow()
        maxOutletTemp = szVAV_model.get_DesignMaxOutletTemp()
        minAirMassFlow = szVAV_model.get_MaxNoCoolHeatAirMassFlow()
        maxAirMassFlow = szVAV_model.get_MaxHeatAirMassFlow()
        lowSpeedFanRatio = szVAV_model.get_LowSpeedHeatFanRatio()
        coilFluidInletNode = szVAV_model.get_HeatCoilFluidInletNode()
        coilFluidOutletNode = szVAV_model.get_HeatCoilFluidOutletNodeNum()
        coilPlantLoc = szVAV_model.get_HeatCoilPlantLoc()
        coilAirInletNode = szVAV_model.get_HeatCoilInletNodeNum()
        coilAirOutletNode = szVAV_model.get_HeatCoilOutletNodeNum()
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, 0, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    
    var InletNode: Int32 = szVAV_model.get_AirInNode()
    var InletTemp: Float64 = state.dataLoopNodes.Node[InletNode].Temp
    var OutletNode: Int32 = szVAV_model.get_AirOutNode()
    var ZoneTemp: Float64 = state.dataLoopNodes.Node[szVAV_model.get_NodeNumOfControlledZone()].Temp
    var ZoneHumRat: Float64 = state.dataLoopNodes.Node[szVAV_model.get_NodeNumOfControlledZone()].HumRat
    var lowWaterMdot: Float64 = 0.0


fn calc_szVAV_model_unitary_sys(
    state: EnergyPlusData,
    inout szVAV_model: UnitarySys,
    FirstHVACIteration: Bool,
    CoolingLoad: Bool,
    HeatingLoad: Bool,
    ZoneLoad: Float64,
    inout OnOffAirFlowRatio: Float64,
    HXUnitOn: Bool,
    AirLoopNum: Int32,
    inout PartLoadRatio: Float64,
    CompressorONFlag: Int32,
) -> None:
    var MaxIter: Int32 = 100
    var SolFlag: Int32 = 0
    var MessagePrefix: String = ""
    
    var boundaryLoadMet: Float64 = 0.0
    var minHumRat: Float64 = 0.0
    var outletTemp: Float64 = 0.0
    var coilActive: Bool = False
    var AirMassFlow: Float64 = 0.0
    
    var maxCoilFluidFlow: Float64 = 0.0
    var maxOutletTemp: Float64 = 0.0
    var minAirMassFlow: Float64 = 0.0
    var maxAirMassFlow: Float64 = 0.0
    var lowSpeedFanRatio: Float64 = 0.0
    var coilFluidInletNode: Int32 = 0
    var coilFluidOutletNode: Int32 = 0
    var coilPlantLoc: PlantLocation = PlantLocation()
    var coilAirInletNode: Int32 = 0
    var coilAirOutletNode: Int32 = 0
    var HeatCoilLoad: Float64 = 0.0
    var SupHeaterLoad: Float64 = 0.0
    var iterWaterAirOrNot: Bool = False
    
    var TempSensOutput: Float64 = 0.0
    var TempLatOutput: Float64 = 0.0
    
    if CoolingLoad:
        maxCoilFluidFlow = szVAV_model.get_MaxCoolCoilFluidFlow()
        maxOutletTemp = szVAV_model.get_DesignMinOutletTemp()
        minAirMassFlow = szVAV_model.get_MaxNoCoolHeatAirMassFlow()
        maxAirMassFlow = szVAV_model.get_MaxCoolAirMassFlow()
        lowSpeedFanRatio = szVAV_model.get_LowSpeedCoolFanRatio()
        coilFluidInletNode = szVAV_model.get_CoolCoilFluidInletNode()
        coilFluidOutletNode = szVAV_model.get_CoolCoilFluidOutletNodeNum()
        coilPlantLoc = szVAV_model.get_CoolCoilPlantLoc()
        coilAirInletNode = szVAV_model.get_CoolCoilInletNodeNum()
        coilAirOutletNode = szVAV_model.get_CoolCoilOutletNodeNum()
    elif HeatingLoad:
        maxCoilFluidFlow = szVAV_model.get_MaxHeatCoilFluidFlow()
        maxOutletTemp = szVAV_model.get_DesignMaxOutletTemp()
        minAirMassFlow = szVAV_model.get_MaxNoCoolHeatAirMassFlow()
        maxAirMassFlow = szVAV_model.get_MaxHeatAirMassFlow()
        lowSpeedFanRatio = szVAV_model.get_LowSpeedHeatFanRatio()
        coilFluidInletNode = szVAV_model.get_HeatCoilFluidInletNode()
        coilFluidOutletNode = szVAV_model.get_HeatCoilFluidOutletNodeNum()
        coilPlantLoc = szVAV_model.get_HeatCoilPlantLoc()
        coilAirInletNode = szVAV_model.get_HeatCoilInletNodeNum()
        coilAirOutletNode = szVAV_model.get_HeatCoilOutletNodeNum()
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, 0, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    
    var InletNode: Int32 = szVAV_model.get_AirInNode()
    var InletTemp: Float64 = state.dataLoopNodes.Node[InletNode].Temp
    var OutletNode: Int32 = szVAV_model.get_AirOutNode()
    var ZoneTemp: Float64 = state.dataLoopNodes.Node[szVAV_model.get_NodeNumOfControlledZone()].Temp
    var ZoneHumRat: Float64 = state.dataLoopNodes.Node[szVAV_model.get_NodeNumOfControlledZone()].HumRat
    szVAV_model.set_m_SimASHRAEModelOn(True)
