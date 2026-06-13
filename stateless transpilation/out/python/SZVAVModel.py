# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from typing import Protocol, Callable
from dataclasses import dataclass, field
from enum import Enum
import math


# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData - from EnergyPlus.Data.EnergyPlusData
# FanCoilData - from EnergyPlus.FanCoilUnits
# UnitarySys - from EnergyPlus.UnitarySystem
# Node - from EnergyPlus.DataLoopNode
# PlantLocation - from EnergyPlus.DataPlant
# MixerType, CoilType, CompressorOp - from EnergyPlus.HVAC
# Psychrometrics functions - from EnergyPlus.Psychrometrics
# PlantUtilities functions - from EnergyPlus.PlantUtilities
# General functions - from EnergyPlus.General
# FanCoilUnits functions - from EnergyPlus.FanCoilUnits
# ShowWarningMessage, ShowContinueError, etc. - from EnergyPlus.UtilityRoutines


class LoopSideLocation(Enum):
    Invalid = 0


class MixerType(Enum):
    SupplySide = 0


class CoilType(Enum):
    HeatingWater = 0


class CompressorOp(Enum):
    Off = 0
    On = 1


@dataclass
class PlantLocation:
    loopNum: int = 0
    loopSideLocation: LoopSideLocation = LoopSideLocation.Invalid
    branchNum: int = 0
    compNum: int = 0


@dataclass
class Node:
    Temp: float = 0.0
    HumRat: float = 0.0
    MassFlowRate: float = 0.0


@dataclass
class NodeArray:
    nodes: dict = field(default_factory=dict)
    
    def __getitem__(self, key: int) -> Node:
        if key not in self.nodes:
            self.nodes[key] = Node()
        return self.nodes[key]


@dataclass
class LoopNodesData:
    Node: NodeArray = field(default_factory=NodeArray)


@dataclass
class EnergyPlusData:
    dataLoopNodes: LoopNodesData = field(default_factory=LoopNodesData)


class FanCoilData(Protocol):
    AirInNode: int
    AirOutNode: int
    ControlZoneNum: int
    NodeNumOfControlledZone: int
    MaxCoolCoilFluidFlow: float
    MaxHeatCoilFluidFlow: float
    DesignMinOutletTemp: float
    DesignMaxOutletTemp: float
    MaxNoCoolHeatAirMassFlow: float
    MaxCoolAirMassFlow: float
    MaxHeatAirMassFlow: float
    LowSpeedCoolFanRatio: float
    LowSpeedHeatFanRatio: float
    CoolCoilFluidInletNode: int
    CoolCoilFluidOutletNodeNum: int
    CoolCoilPlantLoc: PlantLocation
    CoolCoilInletNodeNum: int
    CoolCoilOutletNodeNum: int
    HeatCoilFluidInletNode: int
    HeatCoilFluidOutletNodeNum: int
    HeatCoilPlantLoc: PlantLocation
    HeatCoilInletNodeNum: int
    HeatCoilOutletNodeNum: int
    ATMixerExists: bool
    ATMixerType: MixerType
    ATMixerOutNode: int
    FanPartLoadRatio: float
    HeatCoilWaterFlowRatio: float
    ControlZoneMassFlowFrac: float
    MaxIterIndex: int
    RegulaFalsiFailedIndex: int
    UnitType: str
    Name: str


class UnitarySys(Protocol):
    AirInNode: int
    AirOutNode: int
    ControlZoneNum: int
    NodeNumOfControlledZone: int
    MaxCoolCoilFluidFlow: float
    MaxHeatCoilFluidFlow: float
    DesignMinOutletTemp: float
    DesignMaxOutletTemp: float
    MaxNoCoolHeatAirMassFlow: float
    MaxCoolAirMassFlow: float
    MaxHeatAirMassFlow: float
    LowSpeedCoolFanRatio: float
    LowSpeedHeatFanRatio: float
    CoolCoilFluidInletNode: int
    CoolCoilFluidOutletNodeNum: int
    CoolCoilPlantLoc: PlantLocation
    CoolCoilInletNodeNum: int
    CoolCoilOutletNodeNum: int
    HeatCoilFluidInletNode: int
    HeatCoilFluidOutletNodeNum: int
    HeatCoilPlantLoc: PlantLocation
    HeatCoilInletNodeNum: int
    HeatCoilOutletNodeNum: int
    ATMixerExists: bool
    ATMixerType: MixerType
    ATMixerOutNode: int
    FanPartLoadRatio: float
    CoolCoilWaterFlowRatio: float
    HeatCoilWaterFlowRatio: float
    ControlZoneMassFlowFrac: float
    MaxIterIndex: int
    RegulaFalsiFailedIndex: int
    UnitType: str
    Name: str
    m_SimASHRAEModelOn: bool
    m_CoolingSpeedNum: int
    m_NumOfSpeedCooling: int
    m_HeatingSpeedNum: int
    m_NumOfSpeedHeating: int
    heatCoilType: CoilType
    
    def calcUnitarySystemToLoad(
        self,
        state: EnergyPlusData,
        AirLoopNum: int,
        FirstHVACIteration: bool,
        CoolPLR: float,
        HeatPLR: float,
        OnOffAirFlowRatio: float,
        TempSensOutput: float,
        TempLatOutput: float,
        HXUnitOn: bool,
        HeatCoilLoad: float,
        SupHeaterLoad: float,
        CompressorONFlag: CompressorOp,
    ) -> None:
        pass
    
    def calcUnitarySystemWaterFlowResidual(
        self,
        state: EnergyPlusData,
        PartLoadRatio: float,
        FirstHVACIteration: bool,
        ZoneLoad: float,
        AirInNode: int,
        OnOffAirFlowRatio: float,
        AirLoopNum: int,
        coilFluidInletNode: int,
        maxCoilFluidFlow: float,
        lowSpeedFanRatio: float,
        minAirMassFlow: float,
        minTempTarget: float,
        maxAirMassFlow: float,
        CoolingLoad: bool,
        iterWaterAirOrNot: bool,
    ) -> float:
        return 0.0


def calc_szVAV_model_fan_coil(
    state: EnergyPlusData,
    szVAV_model: FanCoilData,
    SysIndex: int,
    FirstHVACIteration: bool,
    CoolingLoad: bool,
    HeatingLoad: bool,
    ZoneLoad: float,
    OnOffAirFlowRatio: float,
    HXUnitOn: bool,
    AirLoopNum: int,
    PartLoadRatio: float,
    CompressorONFlag: CompressorOp,
) -> None:
    MaxIter = 100
    SolFlag = 0
    MessagePrefix = ""
    
    lowBoundaryLoad = 0.0
    highBoundaryLoad = 0.0
    minHumRat = 0.0
    outletTemp = 0.0
    coilActive = False
    AirMassFlow = 0.0
    
    maxCoilFluidFlow = 0.0
    maxOutletTemp = 0.0
    minAirMassFlow = 0.0
    maxAirMassFlow = 0.0
    lowSpeedFanRatio = 0.0
    coilFluidInletNode = 0
    coilFluidOutletNode = 0
    coilPlantLoc = PlantLocation()
    coilAirInletNode = 0
    coilAirOutletNode = 0
    
    TempSensOutput = 0.0
    
    if CoolingLoad:
        maxCoilFluidFlow = szVAV_model.MaxCoolCoilFluidFlow
        maxOutletTemp = szVAV_model.DesignMinOutletTemp
        minAirMassFlow = szVAV_model.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = szVAV_model.MaxCoolAirMassFlow
        lowSpeedFanRatio = szVAV_model.LowSpeedCoolFanRatio
        coilFluidInletNode = szVAV_model.CoolCoilFluidInletNode
        coilFluidOutletNode = szVAV_model.CoolCoilFluidOutletNodeNum
        coilPlantLoc = szVAV_model.CoolCoilPlantLoc
        coilAirInletNode = szVAV_model.CoolCoilInletNodeNum
        coilAirOutletNode = szVAV_model.CoolCoilOutletNodeNum
    elif HeatingLoad:
        maxCoilFluidFlow = szVAV_model.MaxHeatCoilFluidFlow
        maxOutletTemp = szVAV_model.DesignMaxOutletTemp
        minAirMassFlow = szVAV_model.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = szVAV_model.MaxHeatAirMassFlow
        lowSpeedFanRatio = szVAV_model.LowSpeedHeatFanRatio
        coilFluidInletNode = szVAV_model.HeatCoilFluidInletNode
        coilFluidOutletNode = szVAV_model.HeatCoilFluidOutletNodeNum
        coilPlantLoc = szVAV_model.HeatCoilPlantLoc
        coilAirInletNode = szVAV_model.HeatCoilInletNodeNum
        coilAirOutletNode = szVAV_model.HeatCoilOutletNodeNum
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, LoopSideLocation.Invalid, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    
    InletNode = szVAV_model.AirInNode
    InletTemp = state.dataLoopNodes.Node[InletNode].Temp
    OutletNode = szVAV_model.AirOutNode
    ZoneTemp = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].Temp
    ZoneHumRat = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].HumRat
    lowWaterMdot = 0.0
    
    if szVAV_model.ATMixerExists:
        if szVAV_model.ATMixerType == MixerType.SupplySide:
            lowBoundaryLoad = minAirMassFlow * (
                psy_h_fn_tdb_w(state.dataLoopNodes.Node[szVAV_model.ATMixerOutNode].Temp, ZoneHumRat) -
                psy_h_fn_tdb_w(ZoneTemp, ZoneHumRat)
            )
        else:
            lowBoundaryLoad = minAirMassFlow * (
                psy_h_fn_tdb_w(maxOutletTemp, ZoneHumRat) -
                psy_h_fn_tdb_w(ZoneTemp, ZoneHumRat)
            )
    else:
        minHumRat = min(
            state.dataLoopNodes.Node[InletNode].HumRat,
            state.dataLoopNodes.Node[OutletNode].HumRat
        )
        lowBoundaryLoad = minAirMassFlow * (
            psy_h_fn_tdb_w(maxOutletTemp, minHumRat) -
            psy_h_fn_tdb_w(InletTemp, minHumRat)
        )
    
    if (CoolingLoad and lowBoundaryLoad < ZoneLoad) or (HeatingLoad and lowBoundaryLoad > ZoneLoad):
        PartLoadRatio = 1.0
        szVAV_model.FanPartLoadRatio = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = minAirMassFlow
        
        if coilPlantLoc.loopNum > 0:
            set_component_flow_rate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
        
        if HeatingLoad:
            if szVAV_model.MaxHeatCoilFluidFlow > 0.0:
                szVAV_model.HeatCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxHeatCoilFluidFlow
        
        calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
        
        coilActive = abs(
            state.dataLoopNodes.Node[coilAirInletNode].Temp -
            state.dataLoopNodes.Node[coilAirOutletNode].Temp
        ) > 0
        
        if not coilActive:
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                set_component_flow_rate(
                    state,
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                    coilFluidInletNode,
                    coilFluidOutletNode,
                    coilPlantLoc
                )
            return
        
        if (CoolingLoad and TempSensOutput < ZoneLoad) or (HeatingLoad and TempSensOutput > ZoneLoad):
            def f(PLR: float) -> float:
                return calc_fan_coil_water_flow_residual(
                    state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                    ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode,
                    maxCoilFluidFlow, minAirMassFlow
                )
            
            solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 1: "
            
            if coilPlantLoc.loopNum > 0:
                set_component_flow_rate(
                    state,
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                    coilFluidInletNode,
                    coilFluidOutletNode,
                    coilPlantLoc
                )
    
    else:
        highBoundaryLoad = lowBoundaryLoad * maxAirMassFlow / minAirMassFlow
        
        if (CoolingLoad and highBoundaryLoad < ZoneLoad) or (HeatingLoad and highBoundaryLoad > ZoneLoad):
            outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
            minHumRat = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].HumRat
            if outletTemp < ZoneTemp:
                minHumRat = state.dataLoopNodes.Node[OutletNode].HumRat
            
            outletTemp = maxOutletTemp
            AirMassFlow = min(
                maxAirMassFlow,
                ZoneLoad / (psy_h_fn_tdb_w(outletTemp, minHumRat) - psy_h_fn_tdb_w(ZoneTemp, minHumRat))
            )
            AirMassFlow = max(minAirMassFlow, AirMassFlow)
            szVAV_model.FanPartLoadRatio = (AirMassFlow - (maxAirMassFlow * lowSpeedFanRatio)) / (
                (1.0 - lowSpeedFanRatio) * maxAirMassFlow
            )
            
            state.dataLoopNodes.Node[InletNode].MassFlowRate = AirMassFlow
            if coilFluidInletNode > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = lowWaterMdot
            
            calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, 0.0)
            
            if (CoolingLoad and TempSensOutput > ZoneLoad) or (HeatingLoad and TempSensOutput < ZoneLoad):
                if coilFluidInletNode > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = maxCoilFluidFlow
                
                calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, 1.0)
                
                if coilPlantLoc.loopNum > 0:
                    set_component_flow_rate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
                
                if (CoolingLoad and TempSensOutput < ZoneLoad) or (HeatingLoad and TempSensOutput > ZoneLoad):
                    def f(PLR: float) -> float:
                        return calc_fan_coil_water_flow_residual(
                            state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                            ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode,
                            maxCoilFluidFlow, AirMassFlow
                        )
                    
                    solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                    
                    outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
                    if (CoolingLoad and outletTemp < maxOutletTemp) or (HeatingLoad and outletTemp > maxOutletTemp):
                        pass
                    if SolFlag < 0:
                        MessagePrefix = "Step 2: "
                else:
                    def f(PLR: float) -> float:
                        return calc_fan_coil_water_flow_residual(
                            state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                            ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode,
                            maxCoilFluidFlow, minAirMassFlow
                        )
                    
                    solve_root(state, 0.001, MaxIter, SolFlag, lowWaterMdot, f, 0.0, 1.0)
                    minFlow = lowWaterMdot if SolFlag >= 0 else 0.0
                    if SolFlag < 0:
                        MessagePrefix = "Step 2a: "
                    
                    def f2(PLR: float) -> float:
                        return calc_fan_coil_air_and_water_flow_residual(
                            state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                            ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode, minFlow
                        )
                    
                    solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                    if SolFlag < 0:
                        MessagePrefix = "Step 2b: "
            else:
                def f2(PLR: float) -> float:
                    return calc_fan_coil_air_and_water_flow_residual(
                        state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                        ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode, 0.0
                    )
                
                solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 2c: "
        
        else:
            PartLoadRatio = 1.0
            szVAV_model.FanPartLoadRatio = 1.0
            state.dataLoopNodes.Node[InletNode].MassFlowRate = maxAirMassFlow
            
            if coilPlantLoc.loopNum > 0:
                set_component_flow_rate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            
            if HeatingLoad:
                if szVAV_model.MaxHeatCoilFluidFlow > 0.0:
                    szVAV_model.HeatCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxHeatCoilFluidFlow
            
            calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            coilActive = abs(
                state.dataLoopNodes.Node[coilAirInletNode].Temp -
                state.dataLoopNodes.Node[coilAirOutletNode].Temp
            ) > 0
            
            if not coilActive:
                if coilPlantLoc.loopNum > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                    set_component_flow_rate(
                        state,
                        state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                        coilFluidInletNode,
                        coilFluidOutletNode,
                        coilPlantLoc
                    )
                return
            
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                return
            
            PartLoadRatio = 0.0
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                set_component_flow_rate(
                    state,
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                    coilFluidInletNode,
                    coilFluidOutletNode,
                    coilPlantLoc
                )
            
            calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                def f(PLR: float) -> float:
                    return calc_fan_coil_water_flow_residual(
                        state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                        ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode,
                        maxCoilFluidFlow, maxAirMassFlow
                    )
                
                solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 3: "
            else:
                def f2(PLR: float) -> float:
                    return calc_fan_coil_air_and_water_flow_residual(
                        state, PLR, SysIndex, FirstHVACIteration, szVAV_model.ControlZoneNum,
                        ZoneLoad, szVAV_model.AirInNode, coilFluidInletNode, 0.0
                    )
                
                solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f2, 0.0, 1.0)
                if SolFlag < 0:
                    MessagePrefix = "Step 3a: "
        
        if coilPlantLoc.loopNum > 0:
            set_component_flow_rate(
                state,
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                coilFluidInletNode,
                coilFluidOutletNode,
                coilPlantLoc
            )
    
    if SolFlag < 0:
        if SolFlag == -1:
            calc_4pipe_fan_coil(state, SysIndex, szVAV_model.ControlZoneNum, FirstHVACIteration, TempSensOutput, PartLoadRatio)
            
            if abs(TempSensOutput - ZoneLoad) * szVAV_model.ControlZoneMassFlowFrac > 15.0:
                if szVAV_model.MaxIterIndex == 0:
                    show_warning_message(
                        state,
                        f"{MessagePrefix}Coil control failed to converge for {szVAV_model.UnitType}:{szVAV_model.Name}"
                    )
                    show_continue_error(state, "  Iteration limit exceeded in calculating system sensible part-load ratio.")
                    show_continue_error_time_stamp(
                        state,
                        f"Sensible load to be met = {ZoneLoad:.2f} (watts), sensible output = {TempSensOutput:.2f} (watts), and the simulation continues."
                    )
                show_recurring_warning_error_at_end(
                    state,
                    f"{szVAV_model.UnitType} \"{szVAV_model.Name}\" - Iteration limit exceeded in calculating sensible part-load ratio error continues. Sensible load statistics:",
                    ZoneLoad
                )
        elif SolFlag == -2:
            if szVAV_model.RegulaFalsiFailedIndex == 0:
                show_warning_message(
                    state,
                    f"{MessagePrefix}Coil control failed for {szVAV_model.UnitType}:{szVAV_model.Name}"
                )
                show_continue_error(state, "  sensible part-load ratio determined to be outside the range of 0-1.")
                show_continue_error_time_stamp(state, f"Sensible load to be met = {ZoneLoad:.2f} (watts), and the simulation continues.")
            show_recurring_warning_error_at_end(
                state,
                f"{szVAV_model.UnitType} \"{szVAV_model.Name}\" - sensible part-load ratio out of range error continues. Sensible load statistics:",
                ZoneLoad
            )


def calc_szVAV_model_unitary_sys(
    state: EnergyPlusData,
    szVAV_model: UnitarySys,
    FirstHVACIteration: bool,
    CoolingLoad: bool,
    HeatingLoad: bool,
    ZoneLoad: float,
    OnOffAirFlowRatio: float,
    HXUnitOn: bool,
    AirLoopNum: int,
    PartLoadRatio: float,
    CompressorONFlag: CompressorOp,
) -> None:
    MaxIter = 100
    SolFlag = 0
    MessagePrefix = ""
    
    boundaryLoadMet = 0.0
    minHumRat = 0.0
    outletTemp = 0.0
    coilActive = False
    AirMassFlow = 0.0
    
    maxCoilFluidFlow = 0.0
    maxOutletTemp = 0.0
    minAirMassFlow = 0.0
    maxAirMassFlow = 0.0
    lowSpeedFanRatio = 0.0
    coilFluidInletNode = 0
    coilFluidOutletNode = 0
    coilPlantLoc = PlantLocation()
    coilAirInletNode = 0
    coilAirOutletNode = 0
    HeatCoilLoad = 0.0
    SupHeaterLoad = 0.0
    iterWaterAirOrNot = False
    
    TempSensOutput = 0.0
    TempLatOutput = 0.0
    
    if CoolingLoad:
        maxCoilFluidFlow = szVAV_model.MaxCoolCoilFluidFlow
        maxOutletTemp = szVAV_model.DesignMinOutletTemp
        minAirMassFlow = szVAV_model.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = szVAV_model.MaxCoolAirMassFlow
        lowSpeedFanRatio = szVAV_model.LowSpeedCoolFanRatio
        coilFluidInletNode = szVAV_model.CoolCoilFluidInletNode
        coilFluidOutletNode = szVAV_model.CoolCoilFluidOutletNodeNum
        coilPlantLoc = szVAV_model.CoolCoilPlantLoc
        coilAirInletNode = szVAV_model.CoolCoilInletNodeNum
        coilAirOutletNode = szVAV_model.CoolCoilOutletNodeNum
    elif HeatingLoad:
        maxCoilFluidFlow = szVAV_model.MaxHeatCoilFluidFlow
        maxOutletTemp = szVAV_model.DesignMaxOutletTemp
        minAirMassFlow = szVAV_model.MaxNoCoolHeatAirMassFlow
        maxAirMassFlow = szVAV_model.MaxHeatAirMassFlow
        lowSpeedFanRatio = szVAV_model.LowSpeedHeatFanRatio
        coilFluidInletNode = szVAV_model.HeatCoilFluidInletNode
        coilFluidOutletNode = szVAV_model.HeatCoilFluidOutletNodeNum
        coilPlantLoc = szVAV_model.HeatCoilPlantLoc
        coilAirInletNode = szVAV_model.HeatCoilInletNodeNum
        coilAirOutletNode = szVAV_model.HeatCoilOutletNodeNum
    else:
        maxCoilFluidFlow = 0.0
        maxOutletTemp = 0.0
        minAirMassFlow = 0.0
        maxAirMassFlow = 0.0
        lowSpeedFanRatio = 0.0
        coilFluidInletNode = 0
        coilFluidOutletNode = 0
        coilPlantLoc = PlantLocation(0, LoopSideLocation.Invalid, 0, 0)
        coilAirInletNode = 0
        coilAirOutletNode = 0
    
    InletNode = szVAV_model.AirInNode
    InletTemp = state.dataLoopNodes.Node[InletNode].Temp
    OutletNode = szVAV_model.AirOutNode
    ZoneTemp = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].Temp
    ZoneHumRat = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].HumRat
    szVAV_model.m_SimASHRAEModelOn = True
    
    if szVAV_model.ATMixerExists:
        if szVAV_model.ATMixerType == MixerType.SupplySide:
            boundaryLoadMet = minAirMassFlow * (
                psy_h_fn_tdb_w(state.dataLoopNodes.Node[szVAV_model.ATMixerOutNode].Temp, ZoneHumRat) -
                psy_h_fn_tdb_w(ZoneTemp, ZoneHumRat)
            )
        else:
            boundaryLoadMet = minAirMassFlow * (
                psy_h_fn_tdb_w(maxOutletTemp, ZoneHumRat) -
                psy_h_fn_tdb_w(ZoneTemp, ZoneHumRat)
            )
    else:
        minHumRat = min(
            state.dataLoopNodes.Node[InletNode].HumRat,
            state.dataLoopNodes.Node[OutletNode].HumRat
        )
        boundaryLoadMet = minAirMassFlow * (
            psy_h_fn_tdb_w(maxOutletTemp, minHumRat) -
            psy_h_fn_tdb_w(InletTemp, minHumRat)
        )
    
    if (CoolingLoad and boundaryLoadMet < ZoneLoad) or (HeatingLoad and boundaryLoadMet > ZoneLoad):
        PartLoadRatio = 1.0
        szVAV_model.FanPartLoadRatio = 0.0
        state.dataLoopNodes.Node[InletNode].MassFlowRate = minAirMassFlow
        
        if coilPlantLoc.loopNum > 0:
            set_component_flow_rate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
        
        if CoolingLoad:
            if szVAV_model.MaxCoolCoilFluidFlow > 0.0:
                szVAV_model.CoolCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxCoolCoilFluidFlow
            szVAV_model.calcUnitarySystemToLoad(
                state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0,
                OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                HeatCoilLoad, SupHeaterLoad, CompressorONFlag
            )
        else:
            if szVAV_model.MaxHeatCoilFluidFlow > 0.0:
                szVAV_model.HeatCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxHeatCoilFluidFlow
            szVAV_model.calcUnitarySystemToLoad(
                state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio,
                OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                ZoneLoad, SupHeaterLoad, CompressorONFlag
            )
        
        coilActive = abs(
            state.dataLoopNodes.Node[coilAirInletNode].Temp -
            state.dataLoopNodes.Node[coilAirOutletNode].Temp
        ) > 0
        
        if not coilActive:
            if coilPlantLoc.loopNum > 0:
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                set_component_flow_rate(
                    state,
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                    coilFluidInletNode,
                    coilFluidOutletNode,
                    coilPlantLoc
                )
            return
        
        if (CoolingLoad and TempSensOutput < ZoneLoad) or (HeatingLoad and TempSensOutput > ZoneLoad):
            def fR1(PartLoadRatio: float) -> float:
                return szVAV_model.calcUnitarySystemWaterFlowResidual(
                    state, PartLoadRatio, FirstHVACIteration, ZoneLoad, szVAV_model.AirInNode,
                    OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow,
                    lowSpeedFanRatio, minAirMassFlow, 0.0, maxAirMassFlow,
                    CoolingLoad, iterWaterAirOrNot
                )
            
            solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR1, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 1: "
            
            if coilPlantLoc.loopNum > 0:
                set_component_flow_rate(
                    state,
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                    coilFluidInletNode,
                    coilFluidOutletNode,
                    coilPlantLoc
                )
    
    else:
        boundaryLoadMet *= maxAirMassFlow / minAirMassFlow
        
        if (CoolingLoad and boundaryLoadMet < ZoneLoad) or (HeatingLoad and boundaryLoadMet > ZoneLoad):
            iterWaterAirOrNot = True
            outletTemp = state.dataLoopNodes.Node[OutletNode].Temp
            minHumRat = state.dataLoopNodes.Node[szVAV_model.NodeNumOfControlledZone].HumRat
            if outletTemp < ZoneTemp:
                minHumRat = state.dataLoopNodes.Node[OutletNode].HumRat
            
            outletTemp = maxOutletTemp
            AirMassFlow = min(
                maxAirMassFlow,
                ZoneLoad / (psy_h_fn_tdb_w(outletTemp, minHumRat) - psy_h_fn_tdb_w(ZoneTemp, minHumRat))
            )
            AirMassFlow = max(minAirMassFlow, AirMassFlow)
            szVAV_model.FanPartLoadRatio = (AirMassFlow - (maxAirMassFlow * lowSpeedFanRatio)) / (
                (1.0 - lowSpeedFanRatio) * maxAirMassFlow
            )
            
            def fR2(PartLoadRatio: float) -> float:
                return szVAV_model.calcUnitarySystemWaterFlowResidual(
                    state, PartLoadRatio, FirstHVACIteration, ZoneLoad, szVAV_model.AirInNode,
                    OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow,
                    lowSpeedFanRatio, AirMassFlow, 0.0, maxAirMassFlow,
                    CoolingLoad, iterWaterAirOrNot
                )
            
            solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR2, 0.0, 1.0)
            
            if SolFlag == -2 and (
                (CoolingLoad and szVAV_model.m_CoolingSpeedNum < szVAV_model.m_NumOfSpeedCooling) or
                (HeatingLoad and szVAV_model.m_HeatingSpeedNum < szVAV_model.m_NumOfSpeedHeating)
            ):
                if CoolingLoad:
                    szVAVModelSpeed = szVAV_model.m_CoolingSpeedNum + 1
                    szVAVModelSpeedMax = szVAV_model.m_NumOfSpeedCooling
                else:
                    szVAVModelSpeed = szVAV_model.m_HeatingSpeedNum + 1
                    szVAVModelSpeedMax = szVAV_model.m_NumOfSpeedHeating
                
                for szVAVSpeed in range(szVAVModelSpeed, szVAVModelSpeedMax + 1):
                    if CoolingLoad:
                        szVAV_model.m_CoolingSpeedNum = szVAVSpeed
                    else:
                        szVAV_model.m_HeatingSpeedNum = szVAVSpeed
                    
                    def f(PartLoadRatio: float) -> float:
                        return szVAV_model.calcUnitarySystemWaterFlowResidual(
                            state, PartLoadRatio, FirstHVACIteration, ZoneLoad, szVAV_model.AirInNode,
                            OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow,
                            lowSpeedFanRatio, AirMassFlow, 0.0, maxAirMassFlow,
                            CoolingLoad, iterWaterAirOrNot
                        )
                    
                    solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, f, 0.0, 1.0)
                    if SolFlag > 0:
                        break
                
                if SolFlag < 0:
                    MessagePrefix = "Step 2: "
        
        else:
            PartLoadRatio = 1.0
            szVAV_model.FanPartLoadRatio = 1.0
            state.dataLoopNodes.Node[InletNode].MassFlowRate = maxAirMassFlow
            
            if coilPlantLoc.loopNum > 0:
                set_component_flow_rate(state, maxCoilFluidFlow, coilFluidInletNode, coilFluidOutletNode, coilPlantLoc)
            
            if CoolingLoad:
                if szVAV_model.MaxCoolCoilFluidFlow > 0.0:
                    szVAV_model.CoolCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxCoolCoilFluidFlow
                szVAV_model.calcUnitarySystemToLoad(
                    state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0,
                    OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                    HeatCoilLoad, SupHeaterLoad, CompressorONFlag
                )
            else:
                if szVAV_model.MaxHeatCoilFluidFlow > 0.0:
                    szVAV_model.HeatCoilWaterFlowRatio = maxCoilFluidFlow / szVAV_model.MaxHeatCoilFluidFlow
                szVAV_model.calcUnitarySystemToLoad(
                    state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio,
                    OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                    ZoneLoad, SupHeaterLoad, CompressorONFlag
                )
            
            coilActive = abs(
                state.dataLoopNodes.Node[coilAirInletNode].Temp -
                state.dataLoopNodes.Node[coilAirOutletNode].Temp
            ) > 0
            
            if not coilActive:
                if coilPlantLoc.loopNum > 0:
                    state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate = 0.0
                    set_component_flow_rate(
                        state,
                        state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                        coilFluidInletNode,
                        coilFluidOutletNode,
                        coilPlantLoc
                    )
                return
            
            if (CoolingLoad and ZoneLoad < TempSensOutput) or (HeatingLoad and ZoneLoad > TempSensOutput):
                return
            
            iterWaterAirOrNot = False
            
            def fR3(PartLoadRatio: float) -> float:
                return szVAV_model.calcUnitarySystemWaterFlowResidual(
                    state, PartLoadRatio, FirstHVACIteration, ZoneLoad, szVAV_model.AirInNode,
                    OnOffAirFlowRatio, AirLoopNum, coilFluidInletNode, maxCoilFluidFlow,
                    lowSpeedFanRatio, maxAirMassFlow, 0.0, maxAirMassFlow,
                    CoolingLoad, iterWaterAirOrNot
                )
            
            solve_root(state, 0.001, MaxIter, SolFlag, PartLoadRatio, fR3, 0.0, 1.0)
            if SolFlag < 0:
                MessagePrefix = "Step 3: "
        
        if coilPlantLoc.loopNum > 0:
            set_component_flow_rate(
                state,
                state.dataLoopNodes.Node[coilFluidInletNode].MassFlowRate,
                coilFluidInletNode,
                coilFluidOutletNode,
                coilPlantLoc
            )
    
    if SolFlag < 0:
        if SolFlag == -1:
            if CoolingLoad:
                szVAV_model.calcUnitarySystemToLoad(
                    state, AirLoopNum, FirstHVACIteration, PartLoadRatio, 0.0,
                    OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                    HeatCoilLoad, SupHeaterLoad, CompressorONFlag
                )
            else:
                szVAV_model.calcUnitarySystemToLoad(
                    state, AirLoopNum, FirstHVACIteration, 0.0, PartLoadRatio,
                    OnOffAirFlowRatio, TempSensOutput, TempLatOutput, HXUnitOn,
                    ZoneLoad, SupHeaterLoad, CompressorONFlag
                )
            
            if abs(TempSensOutput - ZoneLoad) * szVAV_model.ControlZoneMassFlowFrac > 15.0:
                if szVAV_model.MaxIterIndex == 0:
                    show_warning_message(
                        state,
                        f"{MessagePrefix}Coil control failed to converge for {szVAV_model.UnitType}:{szVAV_model.Name}"
                    )
                    show_continue_error(state, "  Iteration limit exceeded in calculating system sensible part-load ratio.")
                    show_continue_error_time_stamp(
                        state,
                        f"Sensible load to be met = {ZoneLoad:.2f} (watts), sensible output = {TempSensOutput:.2f} (watts), and the simulation continues."
                    )
                show_recurring_warning_error_at_end(
                    state,
                    f"{szVAV_model.UnitType} \"{szVAV_model.Name}\" - Iteration limit exceeded in calculating sensible part-load ratio error continues. Sensible load statistics:",
                    ZoneLoad
                )
        elif SolFlag == -2:
            if szVAV_model.RegulaFalsiFailedIndex == 0:
                show_warning_message(
                    state,
                    f"{MessagePrefix}Coil control failed for {szVAV_model.UnitType}:{szVAV_model.Name}"
                )
                show_continue_error(state, "  sensible part-load ratio determined to be outside the range of 0-1.")
                show_continue_error_time_stamp(state, f"Sensible load to be met = {ZoneLoad:.2f} (watts), and the simulation continues.")
            show_recurring_warning_error_at_end(
                state,
                f"{szVAV_model.UnitType} \"{szVAV_model.Name}\" - sensible part-load ratio out of range error continues. Sensible load statistics:",
                ZoneLoad
            )


def psy_h_fn_tdb_w(Tdb: float, W: float) -> float:
    return 0.0


def calc_4pipe_fan_coil(
    state: EnergyPlusData,
    SysIndex: int,
    ControlZoneNum: int,
    FirstHVACIteration: bool,
    TempSensOutput: float,
    PartLoadRatio: float,
) -> None:
    pass


def calc_fan_coil_water_flow_residual(
    state: EnergyPlusData,
    PartLoadRatio: float,
    SysIndex: int,
    FirstHVACIteration: bool,
    ControlZoneNum: int,
    ZoneLoad: float,
    AirInNode: int,
    coilFluidInletNode: int,
    maxCoilFluidFlow: float,
    minAirMassFlow: float,
) -> float:
    return 0.0


def calc_fan_coil_load_residual(
    state: EnergyPlusData,
    SysIndex: int,
    FirstHVACIteration: bool,
    ControlZoneNum: int,
    ZoneLoad: float,
    PartLoadRatio: float,
) -> float:
    return 0.0


def calc_fan_coil_air_and_water_flow_residual(
    state: EnergyPlusData,
    PartLoadRatio: float,
    SysIndex: int,
    FirstHVACIteration: bool,
    ControlZoneNum: int,
    ZoneLoad: float,
    AirInNode: int,
    coilFluidInletNode: int,
    minFlow: float,
) -> float:
    return 0.0


def set_component_flow_rate(
    state: EnergyPlusData,
    flowRate: float,
    inletNode: int,
    outletNode: int,
    plantLoc: PlantLocation,
) -> None:
    pass


def solve_root(
    state: EnergyPlusData,
    Accuracy: float,
    MaxIter: int,
    SolFlag: int,
    ResultX: float,
    f: Callable[[float], float],
    XMin: float,
    XMax: float,
) -> None:
    pass


def show_warning_message(state: EnergyPlusData, message: str) -> None:
    pass


def show_continue_error(state: EnergyPlusData, message: str) -> None:
    pass


def show_continue_error_time_stamp(state: EnergyPlusData, message: str) -> None:
    pass


def show_recurring_warning_error_at_end(state: EnergyPlusData, message: str, value: float) -> None:
    pass
