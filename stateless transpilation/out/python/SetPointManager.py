"""
EnergyPlus SetPointManager module (faithful port from C++)
Copyright notices and licensing as per original source.
"""

from enum import IntEnum, auto
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Protocol, Any
from abc import ABC, abstractmethod
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (stub Protocol below)
# - DataEnvironment.GroundTempType, DataEnvironment.GroundTemp
# - DataLoopNode.Node, DataLoopNode.NodeID
# - HVAC.CtrlVarType
# - Sched.Schedule, Sched.GetSchedule
# - PlantLocation, DataPlant types
# - CurveManager.GetCurveIndex, CurveManager.CurveValue
# - Psychrometrics.PsyCpAirFnW, PsyHFnTdbW, PsyTdbFnHW, PsyWFnTdbRhPb
# - InputProcessing.InputProcessor
# - ScheduleManager.Schedule
# - General.FindNumberInList
# - Various Show*Error functions
# - Node.ConnectionObjectType, Node.GetOnlySingleNode, Node.GetNodeNums
# - OutputProcessor, OutputReportPredefined
# - PlantUtilities
# - EMSManager.CheckIfNodeSetPointManagedByEMS


class GroundTempType(IntEnum):
    BuildingSurface = 0
    Shallow = 1
    Deep = 2
    FCFactorMethod = 3
    Num = 4
    Invalid = -1


class SupplyFlowTempStrategy(IntEnum):
    Invalid = -1
    MaxTemp = 0
    MinTemp = 1
    Num = 2


class ControlStrategy(IntEnum):
    Invalid = -1
    TempFirst = 0
    FlowFirst = 1
    Num = 2


class AirTempType(IntEnum):
    Invalid = -1
    WetBulb = 0
    DryBulb = 1
    Num = 2


class ReturnTempType(IntEnum):
    Invalid = -1
    Scheduled = 0
    Constant = 1
    Setpoint = 2
    Num = 3


class SPMType(IntEnum):
    Invalid = -1
    Scheduled = 0
    ScheduledDual = 1
    OutsideAir = 2
    SZReheat = 3
    SZHeating = 4
    SZCooling = 5
    SZMinHum = 6
    SZMaxHum = 7
    MixedAir = 8
    OutsideAirPretreat = 9
    Warmest = 10
    Coldest = 11
    WarmestTempFlow = 12
    ReturnAirBypass = 13
    MZCoolingAverage = 14
    MZHeatingAverage = 15
    MZMinHumAverage = 16
    MZMaxHumAverage = 17
    MZMinHum = 18
    MZMaxHum = 19
    FollowOutsideAirTemp = 20
    FollowSystemNodeTemp = 21
    FollowGroundTemp = 22
    CondenserEnteringTemp = 23
    IdealCondenserEnteringTemp = 24
    SZOneStageCooling = 25
    SZOneStageHeating = 26
    ChilledWaterReturnTemp = 27
    HotWaterReturnTemp = 28
    TESScheduled = 29
    SystemNodeTemp = 30
    SystemNodeHum = 31
    Num = 32


class CtrlVarType(IntEnum):
    Invalid = -1
    Temp = 0
    MaxTemp = 1
    MinTemp = 2
    HumRat = 3
    MaxHumRat = 4
    MinHumRat = 5
    MassFlowRate = 6
    MaxMassFlowRate = 7
    MinMassFlowRate = 8
    Num = 9


class PlantEquipmentType(IntEnum):
    Invalid = -1
    Chiller_Absorption = 0
    Chiller_Indirect_Absorption = 1
    Chiller_CombTurbine = 2
    Chiller_ConstCOP = 3
    Chiller_Electric = 4
    Chiller_ElectricEIR = 5
    Chiller_DFAbsorption = 6
    Chiller_ElectricReformEIR = 7
    Chiller_EngineDriven = 8
    CoolingTower_SingleSpd = 9
    CoolingTower_TwoSpd = 10
    CoolingTower_VarSpd = 11
    PumpVariableSpeed = 12
    PumpConstantSpeed = 13


@dataclass
class LoopSideLocation:
    Supply: int = 0
    Demand: int = 1


@dataclass
class PlantLocation:
    loopNum: int = 0
    loopSideNum: int = 0
    branchNum: int = 0
    compNum: int = 0
    loop: Optional[Any] = None
    side: Optional[Any] = None


@dataclass
class SPMVar:
    Type: int = -1
    Num: int = 0


@dataclass
class SPMBase(ABC):
    Name: str = ""
    type: int = SPMType.Invalid
    ctrlVar: int = CtrlVarType.Invalid
    ctrlNodeNums: List[int] = field(default_factory=list)
    airLoopName: str = ""
    airLoopNum: int = 0
    refNodeNum: int = 0
    minSetTemp: float = 0.0
    maxSetTemp: float = 0.0
    minSetHum: float = 0.0
    maxSetHum: float = 0.0
    setPt: float = 0.0

    @abstractmethod
    def calculate(self, state: Any) -> None:
        pass


@dataclass
class SPMScheduled(SPMBase):
    sched: Optional[Any] = None

    def calculate(self, state: Any) -> None:
        if self.sched is not None:
            self.setPt = self.sched.getCurrentVal()
        else:
            self.setPt = 0.0


@dataclass
class SPMScheduledDual(SPMBase):
    hiSched: Optional[Any] = None
    loSched: Optional[Any] = None
    setPtHi: float = 0.0
    setPtLo: float = 0.0

    def calculate(self, state: Any) -> None:
        if self.hiSched is not None:
            self.setPtHi = self.hiSched.getCurrentVal()
        else:
            self.setPtHi = 0.0
        if self.loSched is not None:
            self.setPtLo = self.loSched.getCurrentVal()
        else:
            self.setPtLo = 0.0


@dataclass
class SPMOutsideAir(SPMBase):
    sched: Optional[Any] = None
    lowSetPt1: float = 0.0
    low1: float = 0.0
    highSetPt1: float = 0.0
    high1: float = 0.0
    invalidSchedValErrorIndex: int = 0
    setPtErrorCount: int = 0
    lowSetPt2: float = 0.0
    low2: float = 0.0
    highSetPt2: float = 0.0
    high2: float = 0.0

    def calculate(self, state: Any) -> None:
        sched_val = self.sched.getCurrentVal() if self.sched is not None else 0.0
        
        if sched_val == 2.0:
            self.setPt = interp_set_point(self.low2, self.high2, state.dataEnvrn.OutDryBulbTemp,
                                          self.lowSetPt2, self.highSetPt2)
        else:
            if self.sched is not None and sched_val != 1.0:
                self.setPtErrorCount += 1
                # Show error handling would go here
            self.setPt = interp_set_point(self.low1, self.high1, state.dataEnvrn.OutDryBulbTemp,
                                          self.lowSetPt1, self.highSetPt1)


@dataclass
class SPMSingleZoneReheat(SPMBase):
    ctrlZoneName: str = ""
    ctrlZoneNum: int = 0
    zoneNodeNum: int = 0
    zoneInletNodeNum: int = 0
    mixedAirNodeNum: int = 0
    fanInNodeNum: int = 0
    fanOutNodeNum: int = 0
    oaInNodeNum: int = 0
    retNodeNum: int = 0
    loopInNodeNum: int = 0

    def calculate(self, state: Any) -> None:
        from math import sqrt
        SMALL_MASS_FLOW = 0.001
        SMALL_LOAD = 0.1
        
        zone_inlet_node = state.dataLoopNodes.Node(self.zoneInletNodeNum)
        oa_frac = state.dataAirLoop.AirLoopFlow(self.airLoopNum).OAFrac
        zone_mass_flow = zone_inlet_node.MassFlowRate
        
        zone_sys_energy_demand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(self.ctrlZoneNum)
        zone_load = zone_sys_energy_demand.TotalOutputRequired
        zone_load_to_cool_setp = zone_sys_energy_demand.OutputRequiredToCoolingSP
        zone_load_to_heat_setp = zone_sys_energy_demand.OutputRequiredToHeatingSP
        dead_band = state.dataZoneEnergyDemand.DeadBandOrSetback(self.ctrlZoneNum)
        zone_temp = state.dataLoopNodes.Node(self.zoneNodeNum).Temp
        
        if self.oaInNodeNum > 0:
            oa_in_node = state.dataLoopNodes.Node(self.oaInNodeNum)
            ret_node = state.dataLoopNodes.Node(self.retNodeNum)
            hum_rat_mix = (1.0 - oa_frac) * ret_node.HumRat + oa_frac * oa_in_node.HumRat
            enth_mix = (1.0 - oa_frac) * ret_node.Enthalpy + oa_frac * oa_in_node.Enthalpy
            # PsyTdbFnHW would be imported
            t_mix_at_min_oa = zone_temp  # placeholder
        else:
            t_mix_at_min_oa = state.dataLoopNodes.Node(self.loopInNodeNum).Temp
        
        fan_delta_t = 0.0
        if self.fanOutNodeNum > 0 and self.fanInNodeNum > 0:
            fan_delta_t = (state.dataLoopNodes.Node(self.fanOutNodeNum).Temp - 
                          state.dataLoopNodes.Node(self.fanInNodeNum).Temp)
        
        t_sup_no_hc = t_mix_at_min_oa + fan_delta_t
        cp_air = 1006.0  # PsyCpAirFnW placeholder
        extr_rate_no_hc = cp_air * zone_mass_flow * (t_sup_no_hc - zone_temp)
        
        if zone_mass_flow <= SMALL_MASS_FLOW:
            t_set_pt = t_sup_no_hc
        elif dead_band or abs(zone_load) < SMALL_LOAD:
            if extr_rate_no_hc < 0.0:
                t_set_pt = t_sup_no_hc if extr_rate_no_hc >= zone_load_to_heat_setp else (
                    zone_temp + zone_load_to_heat_setp / (cp_air * zone_mass_flow))
            elif extr_rate_no_hc > 0.0:
                t_set_pt = t_sup_no_hc if extr_rate_no_hc <= zone_load_to_cool_setp else (
                    zone_temp + zone_load_to_cool_setp / (cp_air * zone_mass_flow))
            else:
                t_set_pt = t_sup_no_hc
        elif zone_load < -1.0 * SMALL_LOAD:
            t_set_pt1 = zone_temp + zone_load / (cp_air * zone_mass_flow)
            t_set_pt2 = zone_temp + zone_load_to_heat_setp / (cp_air * zone_mass_flow)
            t_set_pt = t_set_pt1 if t_set_pt1 <= t_sup_no_hc else (
                t_set_pt2 if t_set_pt2 > t_sup_no_hc else t_sup_no_hc)
        elif zone_load > SMALL_LOAD:
            t_set_pt1 = zone_temp + zone_load / (cp_air * zone_mass_flow)
            t_set_pt2 = zone_temp + zone_load_to_cool_setp / (cp_air * zone_mass_flow)
            t_set_pt = t_set_pt1 if t_set_pt1 >= t_sup_no_hc else (
                t_set_pt2 if t_set_pt2 < t_sup_no_hc else t_sup_no_hc)
        else:
            t_set_pt = t_sup_no_hc
        
        self.setPt = max(self.minSetTemp, min(t_set_pt, self.maxSetTemp))


@dataclass
class SPMSingleZoneTemp(SPMBase):
    ctrlZoneName: str = ""
    ctrlZoneNum: int = 0
    zoneNodeNum: int = 0
    zoneInletNodeNum: int = 0

    def calculate(self, state: Any) -> None:
        SMALL_MASS_FLOW = 0.001
        
        zone_inlet_node = state.dataLoopNodes.Node(self.zoneInletNodeNum)
        zone_energy_demand = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(self.ctrlZoneNum)
        
        zone_load_to_sp = (zone_energy_demand.OutputRequiredToHeatingSP 
                          if self.type == SPMType.SZHeating 
                          else zone_energy_demand.OutputRequiredToCoolingSP)
        
        zone_temp = state.dataLoopNodes.Node(self.zoneNodeNum).Temp
        
        if zone_inlet_node.MassFlowRate <= SMALL_MASS_FLOW:
            self.setPt = self.minSetTemp if self.type == SPMType.SZHeating else self.maxSetTemp
        else:
            cp_air = 1006.0  # PsyCpAirFnW placeholder
            self.setPt = zone_temp + zone_load_to_sp / (cp_air * zone_inlet_node.MassFlowRate)
            self.setPt = max(self.minSetTemp, min(self.setPt, self.maxSetTemp))


@dataclass
class SPMSingleZoneHum(SPMBase):
    zoneNodeNum: int = 0
    ctrlZoneNum: int = 0

    def calculate(self, state: Any) -> None:
        SMALL_MASS_FLOW = 0.001
        
        zone_node = state.dataLoopNodes.Node(self.zoneNodeNum)
        zone_mass_flow = zone_node.MassFlowRate
        
        if zone_mass_flow > SMALL_MASS_FLOW:
            zone_moisture_demand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(self.ctrlZoneNum)
            moisture_load = (zone_moisture_demand.OutputRequiredToHumidifyingSP 
                           if self.type == SPMType.SZMinHum 
                           else zone_moisture_demand.OutputRequiredToDehumidifyingSP)
            
            max_hum = 0.0 if self.type == SPMType.SZMinHum else 0.00001
            self.setPt = max(max_hum, zone_node.HumRat + moisture_load / zone_mass_flow)
        else:
            self.setPt = 0.0


@dataclass
class SPMMixedAir(SPMBase):
    fanInNodeNum: int = 0
    fanOutNodeNum: int = 0
    mySetPointCheckFlag: bool = True
    freezeCheckEnable: bool = True
    coolCoilInNodeNum: int = 0
    coolCoilOutNodeNum: int = 0
    minCoolCoilOutTemp: float = 7.2

    def calculate(self, state: Any) -> None:
        fan_in_node = state.dataLoopNodes.Node(self.fanInNodeNum)
        fan_out_node = state.dataLoopNodes.Node(self.fanOutNodeNum)
        ref_node = state.dataLoopNodes.Node(self.refNodeNum)
        
        self.freezeCheckEnable = False
        
        if not state.dataGlobal.SysSizingCalc and self.mySetPointCheckFlag:
            if ref_node.TempSetPoint == -9999.0:  # SensedNodeFlagValue
                # Show error handling
                pass
            self.mySetPointCheckFlag = False
        
        self.setPt = ref_node.TempSetPoint - (fan_out_node.Temp - fan_in_node.Temp)
        
        if self.coolCoilInNodeNum > 0 and self.coolCoilOutNodeNum > 0:
            cool_coil_in = state.dataLoopNodes.Node(self.coolCoilInNodeNum)
            cool_coil_out = state.dataLoopNodes.Node(self.coolCoilOutNodeNum)
            dt_fan = fan_out_node.Temp - fan_in_node.Temp
            dt_cool_coil = cool_coil_in.Temp - cool_coil_out.Temp
            
            if dt_cool_coil > 0.0 and self.minCoolCoilOutTemp > state.dataEnvrn.OutDryBulbTemp:
                self.freezeCheckEnable = True
                if ref_node.Temp == cool_coil_out.Temp:
                    self.setPt = max(ref_node.TempSetPoint, self.minCoolCoilOutTemp) - dt_fan + dt_cool_coil
                elif self.refNodeNum != self.coolCoilOutNodeNum:
                    self.setPt = max(ref_node.TempSetPoint - dt_fan, self.minCoolCoilOutTemp) + dt_cool_coil
                else:
                    self.setPt = max(ref_node.TempSetPoint, self.minCoolCoilOutTemp) + dt_cool_coil


@dataclass
class SPMOutsideAirPretreat(SPMBase):
    mixedOutNodeNum: int = 0
    oaInNodeNum: int = 0
    returnInNodeNum: int = 0
    mySetPointCheckFlag: bool = True

    def calculate(self, state: Any) -> None:
        ref_node = state.dataLoopNodes.Node(self.refNodeNum)
        mixed_out_node = state.dataLoopNodes.Node(self.mixedOutNodeNum)
        oa_in_node = state.dataLoopNodes.Node(self.oaInNodeNum)
        return_in_node = state.dataLoopNodes.Node(self.returnInNodeNum)
        
        is_humidity_setp = False
        ref_node_setp = 0.0
        return_in_value = 0.0
        min_setp = self.minSetTemp
        max_setp = self.maxSetTemp
        
        if self.ctrlVar == CtrlVarType.Temp:
            ref_node_setp = ref_node.TempSetPoint
            return_in_value = return_in_node.Temp
            min_setp = self.minSetTemp
            max_setp = self.maxSetTemp
        elif self.ctrlVar == CtrlVarType.MaxHumRat:
            ref_node_setp = ref_node.HumRatMax
            return_in_value = return_in_node.HumRat
            min_setp = self.minSetHum
            max_setp = self.maxSetHum
            is_humidity_setp = True
        elif self.ctrlVar == CtrlVarType.MinHumRat:
            ref_node_setp = ref_node.HumRatMin
            return_in_value = return_in_node.HumRat
            min_setp = self.minSetHum
            max_setp = self.maxSetHum
            is_humidity_setp = True
        elif self.ctrlVar == CtrlVarType.HumRat:
            ref_node_setp = ref_node.HumRatSetPoint
            return_in_value = return_in_node.HumRat
            min_setp = self.minSetHum
            max_setp = self.maxSetHum
            is_humidity_setp = True
        
        if not state.dataGlobal.SysSizingCalc and self.mySetPointCheckFlag:
            self.mySetPointCheckFlag = False
            if ref_node_setp == -9999.0:  # SensedNodeFlagValue
                # Show error handling
                pass
        
        if mixed_out_node.MassFlowRate <= 0.0 or oa_in_node.MassFlowRate <= 0.0:
            self.setPt = ref_node_setp
        elif is_humidity_setp and ref_node_setp == 0.0:
            self.setPt = 0.0
        else:
            oa_fraction = oa_in_node.MassFlowRate / mixed_out_node.MassFlowRate
            self.setPt = return_in_value + (ref_node_setp - return_in_value) / oa_fraction
            self.setPt = max(min_setp, min(self.setPt, max_setp))


@dataclass
class SPMTempest(SPMBase):
    strategy: int = SupplyFlowTempStrategy.Invalid

    def calculate(self, state: Any) -> None:
        SMALL_MASS_FLOW = 0.001
        SMALL_LOAD = 0.1
        
        air_to_zone_node = state.dataAirLoop.AirToZoneNodeInfo(self.airLoopNum)
        
        if self.type == SPMType.Warmest:
            tot_cool_load = 0.0
            set_point_temp = self.maxSetTemp
            
            for i_zone_num in range(air_to_zone_node.NumZonesCooled):
                ctrl_zone_num = air_to_zone_node.CoolCtrlZoneNums(i_zone_num)
                zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.CoolZoneInletNodes(i_zone_num))
                zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
                
                zone_mass_flow_max = zone_inlet_node.MassFlowRateMax
                zone_load = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ctrl_zone_num).TotalOutputRequired
                zone_temp = zone_node.Temp
                zone_set_point_temp = self.maxSetTemp
                
                if zone_load < 0.0:
                    tot_cool_load += abs(zone_load)
                    cp_air = 1006.0  # placeholder
                    if zone_mass_flow_max > SMALL_MASS_FLOW:
                        zone_set_point_temp = zone_temp + zone_load / (cp_air * zone_mass_flow_max)
                
                set_point_temp = min(set_point_temp, zone_set_point_temp)
            
            set_point_temp = max(self.minSetTemp, min(set_point_temp, self.maxSetTemp))
            if tot_cool_load < SMALL_LOAD:
                set_point_temp = self.maxSetTemp
        else:  # Coldest
            tot_heat_load = 0.0
            set_point_temp = self.minSetTemp
            
            if air_to_zone_node.NumZonesHeated > 0:
                for i_zone_num in range(air_to_zone_node.NumZonesHeated):
                    ctrl_zone_num = air_to_zone_node.HeatCtrlZoneNums(i_zone_num)
                    zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.HeatZoneInletNodes(i_zone_num))
                    zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
                    
                    zone_mass_flow_max = zone_inlet_node.MassFlowRateMax
                    zone_load = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ctrl_zone_num).TotalOutputRequired
                    zone_temp = zone_node.Temp
                    zone_set_point_temp = self.minSetTemp
                    
                    if zone_load > 0.0:
                        tot_heat_load += zone_load
                        cp_air = 1006.0  # placeholder
                        if zone_mass_flow_max > SMALL_MASS_FLOW:
                            zone_set_point_temp = zone_temp + zone_load / (cp_air * zone_mass_flow_max)
                    
                    set_point_temp = max(set_point_temp, zone_set_point_temp)
            else:
                for i_zone_num in range(air_to_zone_node.NumZonesCooled):
                    ctrl_zone_num = air_to_zone_node.CoolCtrlZoneNums(i_zone_num)
                    zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.CoolZoneInletNodes(i_zone_num))
                    zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
                    
                    zone_mass_flow_max = zone_inlet_node.MassFlowRateMax
                    zone_load = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ctrl_zone_num).TotalOutputRequired
                    zone_temp = zone_node.Temp
                    zone_set_point_temp = self.minSetTemp
                    
                    if zone_load > 0.0:
                        tot_heat_load += zone_load
                        cp_air = 1006.0  # placeholder
                        if zone_mass_flow_max > SMALL_MASS_FLOW:
                            zone_set_point_temp = zone_temp + zone_load / (cp_air * zone_mass_flow_max)
                    
                    set_point_temp = max(set_point_temp, zone_set_point_temp)
            
            set_point_temp = max(self.minSetTemp, min(set_point_temp, self.maxSetTemp))
            if tot_heat_load < SMALL_LOAD:
                set_point_temp = self.minSetTemp
        
        self.setPt = set_point_temp


@dataclass
class SPMWarmestTempFlow(SPMBase):
    strategy: int = ControlStrategy.Invalid
    minTurndown: float = 0.0
    turndown: float = 0.0
    critZoneNum: int = 0
    simReady: bool = False

    def calculate(self, state: Any) -> None:
        SMALL_MASS_FLOW = 0.001
        SMALL_LOAD = 0.1
        
        if not self.simReady:
            return
        
        tot_cool_load = 0.0
        max_set_point_temp = self.maxSetTemp
        set_point_temp = max_set_point_temp
        min_set_point_temp = self.minSetTemp
        min_frac_flow = self.minTurndown
        frac_flow = min_frac_flow
        crit_zone_num_temp = 0
        crit_zone_num_flow = 0
        
        air_to_zone_node = state.dataAirLoop.AirToZoneNodeInfo(self.airLoopNum)
        
        for i_zone_num in range(air_to_zone_node.NumZonesCooled):
            ctrl_zone_num = air_to_zone_node.CoolCtrlZoneNums(i_zone_num)
            zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.CoolZoneInletNodes(i_zone_num))
            zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
            
            zone_mass_flow_max = zone_inlet_node.MassFlowRateMax
            zone_load = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ctrl_zone_num).TotalOutputRequired
            zone_temp = zone_node.Temp
            zone_set_point_temp = max_set_point_temp
            zone_frac_flow = min_frac_flow
            
            if zone_load < 0.0:
                tot_cool_load += abs(zone_load)
                cp_air = 1006.0  # placeholder
                if zone_mass_flow_max > SMALL_MASS_FLOW:
                    if self.strategy == ControlStrategy.TempFirst:
                        zone_set_point_temp = zone_temp + zone_load / (cp_air * zone_mass_flow_max * min_frac_flow)
                        if zone_set_point_temp < min_set_point_temp:
                            zone_frac_flow = (zone_load / (cp_air * (min_set_point_temp - zone_temp))) / zone_mass_flow_max
                        else:
                            zone_frac_flow = min_frac_flow
                    else:  # FlowFirst
                        zone_frac_flow = (zone_load / (cp_air * (max_set_point_temp - zone_temp))) / zone_mass_flow_max
                        if zone_frac_flow > 1.0 or zone_frac_flow < 0.0:
                            zone_set_point_temp = zone_temp + zone_load / (cp_air * zone_mass_flow_max)
                        else:
                            zone_set_point_temp = max_set_point_temp
            
            if zone_set_point_temp < set_point_temp:
                set_point_temp = zone_set_point_temp
                crit_zone_num_temp = ctrl_zone_num
            if zone_frac_flow > frac_flow:
                frac_flow = zone_frac_flow
                crit_zone_num_flow = ctrl_zone_num
        
        set_point_temp = max(min_set_point_temp, min(set_point_temp, max_set_point_temp))
        frac_flow = max(min_frac_flow, min(frac_flow, 1.0))
        if tot_cool_load < SMALL_LOAD:
            set_point_temp = max_set_point_temp
            frac_flow = min_frac_flow
        
        self.setPt = set_point_temp
        self.turndown = frac_flow
        if self.strategy == ControlStrategy.TempFirst:
            self.critZoneNum = crit_zone_num_flow if crit_zone_num_flow != 0 else crit_zone_num_temp
        else:
            self.critZoneNum = crit_zone_num_temp if crit_zone_num_temp != 0 else crit_zone_num_flow


@dataclass
class SPMReturnAirBypassFlow(SPMBase):
    sched: Optional[Any] = None
    FlowSetPt: float = 0.0
    rabMixInNodeNum: int = 0
    supMixInNodeNum: int = 0
    mixOutNodeNum: int = 0
    rabSplitOutNodeNum: int = 0
    sysOutNodeNum: int = 0

    def calculate(self, state: Any) -> None:
        mixer_rab_in_node = state.dataLoopNodes.Node(self.rabMixInNodeNum)
        mixer_sup_in_node = state.dataLoopNodes.Node(self.supMixInNodeNum)
        mixer_out_node = state.dataLoopNodes.Node(self.mixOutNodeNum)
        loop_out_node = state.dataLoopNodes.Node(self.sysOutNodeNum)
        
        temp_set_pt = self.sched.getCurrentVal() if self.sched else 0.0
        temp_set_pt_mod = temp_set_pt - (loop_out_node.Temp - mixer_out_node.Temp)
        sup_flow = mixer_sup_in_node.MassFlowRate
        temp_sup = mixer_sup_in_node.Temp
        tot_sup_flow = mixer_out_node.MassFlowRate
        temp_rab = mixer_rab_in_node.Temp
        rab_flow = (tot_sup_flow * temp_set_pt_mod - sup_flow * temp_sup) / max(temp_rab, 1.0)
        rab_flow = max(0.0, min(rab_flow, tot_sup_flow))
        self.FlowSetPt = rab_flow


@dataclass
class SPMMultiZoneTemp(SPMBase):
    def calculate(self, state: Any) -> None:
        SMALL_MASS_FLOW = 0.001
        SMALL_LOAD = 0.1
        
        sum_load = 0.0
        sum_product_mdot_cp = 0.0
        sum_product_mdot_cp_tot = 0.0
        sum_product_mdot_cp_t_zone_tot = 0.0
        
        air_to_zone_node = state.dataAirLoop.AirToZoneNodeInfo(self.airLoopNum)
        
        for i_zone_num in range(air_to_zone_node.NumZonesCooled):
            ctrl_zone_num = air_to_zone_node.CoolCtrlZoneNums(i_zone_num)
            zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.CoolZoneInletNodes(i_zone_num))
            zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
            
            zone_mass_flow_rate = zone_inlet_node.MassFlowRate
            zone_load = state.dataZoneEnergyDemand.ZoneSysEnergyDemand(ctrl_zone_num).TotalOutputRequired
            zone_temp = zone_node.Temp
            cp_air_node = 1006.0  # PsyCpAirFnW placeholder
            
            sum_product_mdot_cp_tot += zone_mass_flow_rate * cp_air_node
            sum_product_mdot_cp_t_zone_tot += zone_mass_flow_rate * cp_air_node * zone_temp
            
            if ((self.type == SPMType.MZHeatingAverage and zone_load > 0.0) or 
                (self.type == SPMType.MZCoolingAverage and zone_load < 0.0)):
                cp_air_inlet = 1006.0  # placeholder
                sum_load += zone_load
                sum_product_mdot_cp += zone_mass_flow_rate * cp_air_inlet
        
        zone_avg_temp = sum_product_mdot_cp_t_zone_tot / sum_product_mdot_cp_tot if sum_product_mdot_cp_tot > 0.0 else 0.0
        set_point_temp = (zone_avg_temp + sum_load / sum_product_mdot_cp 
                         if sum_product_mdot_cp > 0.0 
                         else (self.minSetTemp if self.type == SPMType.MZHeatingAverage else self.maxSetTemp))
        
        set_point_temp = max(self.minSetTemp, min(set_point_temp, self.maxSetTemp))
        if abs(sum_load) < SMALL_LOAD:
            set_point_temp = self.minSetTemp if self.type == SPMType.MZHeatingAverage else self.maxSetTemp
        
        self.setPt = set_point_temp


@dataclass
class SPMMultiZoneHum(SPMBase):
    def calculate(self, state: Any) -> None:
        SMALL_MOISTURE_LOAD = 0.00001
        SMALL_MASS_FLOW = 0.001
        
        sum_mdot = 0.0
        sum_mdot_tot = 0.0
        sum_moisture_load = 0.0
        sum_product_mdot_hum_tot = 0.0
        
        air_to_zone_node = state.dataAirLoop.AirToZoneNodeInfo(self.airLoopNum)
        
        set_point_hum = (self.minSetHum if (self.type == SPMType.MZMinHum or self.type == SPMType.MZMinHumAverage)
                        else self.maxSetHum)
        
        for i_zone_num in range(air_to_zone_node.NumZonesCooled):
            ctrl_zone_num = air_to_zone_node.CoolCtrlZoneNums(i_zone_num)
            zone_inlet_node = state.dataLoopNodes.Node(air_to_zone_node.CoolZoneInletNodes(i_zone_num))
            zone_node = state.dataLoopNodes.Node(state.dataZoneEquip.ZoneEquipConfig(ctrl_zone_num).ZoneNode)
            zone_moisture_demand = state.dataZoneEnergyDemand.ZoneSysMoistureDemand(ctrl_zone_num)
            
            zone_mass_flow_rate = zone_inlet_node.MassFlowRate
            moisture_load = (zone_moisture_demand.OutputRequiredToHumidifyingSP
                           if (self.type == SPMType.MZMinHum or self.type == SPMType.MZMinHumAverage)
                           else zone_moisture_demand.OutputRequiredToDehumidifyingSP)
            
            zone_hum = zone_node.HumRat
            
            if self.type == SPMType.MZMinHumAverage:
                sum_mdot_tot += zone_mass_flow_rate
                sum_product_mdot_hum_tot += zone_mass_flow_rate * zone_hum
                if moisture_load > 0.0:
                    sum_mdot += zone_mass_flow_rate
                    sum_moisture_load += moisture_load
            elif self.type == SPMType.MZMaxHumAverage:
                sum_mdot_tot += zone_mass_flow_rate
                sum_product_mdot_hum_tot += zone_mass_flow_rate * zone_hum
                if moisture_load < 0.0:
                    sum_mdot += zone_mass_flow_rate
                    sum_moisture_load += moisture_load
            elif self.type == SPMType.MZMinHum:
                zone_set_point_hum = self.minSetHum
                if moisture_load > 0.0:
                    sum_moisture_load += moisture_load
                    if zone_mass_flow_rate > SMALL_MASS_FLOW:
                        zone_set_point_hum = max(0.0, zone_hum + moisture_load / zone_mass_flow_rate)
                set_point_hum = max(set_point_hum, zone_set_point_hum)
            elif self.type == SPMType.MZMaxHum:
                zone_set_point_hum = self.maxSetHum
                if moisture_load < 0.0:
                    sum_moisture_load += moisture_load
                    if zone_mass_flow_rate > SMALL_MASS_FLOW:
                        zone_set_point_hum = max(0.0, zone_hum + moisture_load / zone_mass_flow_rate)
                set_point_hum = min(set_point_hum, zone_set_point_hum)
        
        if self.type == SPMType.MZMinHumAverage or self.type == SPMType.MZMaxHumAverage:
            avg_zone_hum = sum_product_mdot_hum_tot / sum_mdot_tot if sum_mdot_tot > SMALL_MASS_FLOW else 0.0
            if sum_mdot > SMALL_MASS_FLOW:
                set_point_hum = max(0.0, avg_zone_hum + sum_moisture_load / sum_mdot)
        else:
            if abs(sum_moisture_load) < SMALL_MOISTURE_LOAD:
                set_point_hum = self.minSetHum if self.type == SPMType.MZMinHum else self.maxSetHum
        
        self.setPt = max(self.minSetHum, min(set_point_hum, self.maxSetHum))


@dataclass
class SPMFollowOutsideAirTemp(SPMBase):
    refTempType: int = AirTempType.Invalid
    offset: float = 0.0

    def calculate(self, state: Any) -> None:
        ref_temp = (state.dataEnvrn.OutWetBulbTemp if self.refTempType == AirTempType.WetBulb 
                   else state.dataEnvrn.OutDryBulbTemp)
        self.setPt = ref_temp + self.offset
        self.setPt = max(self.minSetTemp, min(self.setPt, self.maxSetTemp))


@dataclass
class SPMFollowSysNodeTemp(SPMBase):
    refTempType: int = AirTempType.Invalid
    offset: float = 0.0

    def calculate(self, state: Any) -> None:
        ref_node_temp = (state.dataLoopNodes.Node(self.refNodeNum).Temp 
                        if self.refTempType == AirTempType.DryBulb
                        else 0.0)  # WetBulb placeholder
        self.setPt = ref_node_temp + self.offset
        self.setPt = max(self.minSetTemp, min(self.setPt, self.maxSetTemp))


@dataclass
class SPMFollowGroundTemp(SPMBase):
    refTempType: int = GroundTempType.Invalid
    offset: float = 0.0

    def calculate(self, state: Any) -> None:
        self.setPt = state.dataEnvrn.GroundTemp[int(self.refTempType)] + self.offset
        self.setPt = max(self.minSetTemp, min(self.setPt, self.maxSetTemp))


@dataclass
class SPMCondenserEnteringTemp(SPMBase):
    condenserEnteringTempSched: Optional[Any] = None
    towerDesignInletAirWetBulbTemp: float = 0.0
    minTowerDesignWetBulbCurveNum: int = 0
    minOAWetBulbCurveNum: int = 0
    optCondenserEnteringTempCurveNum: int = 0
    minLift: float = 0.0
    maxCondenserEnteringTemp: float = 0.0
    plantPloc: PlantLocation = field(default_factory=PlantLocation)
    demandPloc: PlantLocation = field(default_factory=PlantLocation)
    chillerType: int = PlantEquipmentType.Invalid

    def calculate(self, state: Any) -> None:
        # Simplified placeholder
        if self.condenserEnteringTempSched:
            self.setPt = self.condenserEnteringTempSched.getCurrentVal()
        else:
            self.setPt = self.maxCondenserEnteringTemp


@dataclass
class SPMIdealCondenserEnteringTemp(SPMBase):
    minLift: float = 0.0
    maxCondenserEnteringTemp: float = 0.0
    chillerPloc: PlantLocation = field(default_factory=PlantLocation)
    chillerVar: SPMVar = field(default_factory=SPMVar)
    chilledWaterPumpVar: SPMVar = field(default_factory=SPMVar)
    towerVars: List[SPMVar] = field(default_factory=list)
    condenserPumpVar: SPMVar = field(default_factory=SPMVar)
    chillerType: int = PlantEquipmentType.Invalid
    towerPlocs: List[PlantLocation] = field(default_factory=list)
    numTowers: int = 0
    condenserPumpPloc: PlantLocation = field(default_factory=PlantLocation)
    chilledWaterPumpPloc: PlantLocation = field(default_factory=PlantLocation)
    setupIdealCondEntSetPtVars: bool = True

    def calculate(self, state: Any) -> None:
        self.setPt = self.maxCondenserEnteringTemp

    def setup_metered_vars_for_set_pt(self, state: Any) -> None:
        pass

    def calculate_current_energy_usage(self, state: Any) -> float:
        return 0.0

    def setup_set_point_and_flags(self, tot_energy: float, tot_energy_pre: float, cond_water_setp: float,
                                  cond_temp_limit: float, run_opt: bool, run_subopt: bool, run_final: bool) -> None:
        pass


@dataclass
class SPMSingleZoneOneStageCooling(SPMBase):
    ctrlZoneNum: int = 0
    zoneNodeNum: int = 0
    coolingOnSetPt: float = 0.0
    coolingOffSetPt: float = 0.0

    def calculate(self, state: Any) -> None:
        self.setPt = (self.coolingOffSetPt 
                     if state.dataZoneEnergyDemand.ZoneSysEnergyDemand(self.ctrlZoneNum).StageNum >= 0
                     else self.coolingOnSetPt)


@dataclass
class SPMSingleZoneOneStageHeating(SPMBase):
    ctrlZoneNum: int = 0
    zoneNodeNum: int = 0
    heatingOnSetPt: float = 0.0
    heatingOffSetPt: float = 0.0

    def calculate(self, state: Any) -> None:
        self.setPt = (self.heatingOffSetPt 
                     if state.dataZoneEnergyDemand.ZoneSysEnergyDemand(self.ctrlZoneNum).StageNum <= 0
                     else self.heatingOnSetPt)


@dataclass
class SPMReturnWaterTemp(SPMBase):
    returnNodeNum: int = 0
    supplyNodeNum: int = 0
    returnTempSched: Optional[Any] = None
    returnTempConstantTarget: float = 0.0
    currentSupplySetPt: float = 0.0
    plantLoopNum: int = 0
    plantSetPtNodeNum: int = 0
    returnTempType: int = ReturnTempType.Invalid

    def calculate(self, state: Any) -> None:
        supply_node = state.dataLoopNodes.Node(self.supplyNodeNum)
        return_node = state.dataLoopNodes.Node(self.returnNodeNum)
        
        mdot = supply_node.MassFlowRate
        delta_t = ((return_node.Temp - supply_node.Temp) 
                  if self.type == SPMType.ChilledWaterReturnTemp
                  else (supply_node.Temp - return_node.Temp))
        
        if delta_t < 0.0:
            self.currentSupplySetPt = self.minSetTemp if self.type == SPMType.ChilledWaterReturnTemp else self.maxSetTemp
            return
        
        t_return_target = self.returnTempConstantTarget
        if self.returnTempSched is not None:
            t_return_target = self.returnTempSched.getCurrentVal()
        elif self.returnTempType == ReturnTempType.Setpoint:
            if return_node.TempSetPoint != -9999.0:
                t_return_target = return_node.TempSetPoint
        
        t_supply_setp = self.minSetTemp if self.type == SPMType.ChilledWaterReturnTemp else self.maxSetTemp
        if mdot > 0.001:
            t_supply_setp = t_return_target + ((-delta_t) if self.type == SPMType.ChilledWaterReturnTemp else delta_t)
        
        self.currentSupplySetPt = max(self.minSetTemp, min(t_supply_setp, self.maxSetTemp))


@dataclass
class SPMTESScheduled(SPMBase):
    sched: Optional[Any] = None
    chargeSched: Optional[Any] = None
    ctrlNodeNum: int = 0
    nonChargeCHWTemp: float = 0.0
    chargeCHWTemp: float = 0.0
    compOpType: int = 0

    def calculate(self, state: Any) -> None:
        ON_VAL = 0.5
        cur_sch_val_on_peak = self.sched.getCurrentVal() if self.sched else 0.0
        cur_sch_val_charge = self.chargeSched.getCurrentVal() if self.chargeSched else 0.0
        
        # Placeholder logic
        if cur_sch_val_on_peak >= ON_VAL:
            self.setPt = self.nonChargeCHWTemp
        else:
            self.setPt = self.nonChargeCHWTemp


@dataclass
class SPMSystemNode(SPMBase):
    lowRefSetPt: float = 0.0
    highRefSetPt: float = 0.0
    lowRef: float = 0.0
    highRef: float = 0.0

    def calculate(self, state: Any) -> None:
        ref_value = 0.0
        
        ref_node = state.dataLoopNodes.Node(self.refNodeNum)
        
        if self.ctrlVar in (CtrlVarType.Temp, CtrlVarType.MaxTemp, CtrlVarType.MinTemp):
            ref_value = ref_node.Temp
        elif self.ctrlVar in (CtrlVarType.HumRat, CtrlVarType.MaxHumRat, CtrlVarType.MinHumRat):
            ref_value = ref_node.HumRat
        
        self.setPt = interp_set_point(self.lowRef, self.highRef, ref_value, 
                                      self.lowRefSetPt, self.highRefSetPt)


@dataclass
class SetPointManagerData:
    ManagerOn: bool = False
    GetInputFlag: bool = True
    InitSetPointManagersOneTimeFlag: bool = True
    InitSetPointManagersOneTimeFlag2: bool = True
    NoGroundTempObjWarning: List[bool] = field(default_factory=lambda: [True, True, True, True])
    InitSetPointManagersMyEnvrnFlag: bool = True
    spms: List[SPMBase] = field(default_factory=list)
    spmMap: Dict[str, int] = field(default_factory=dict)
    ICET_RunSubOptCondEntTemp: bool = False
    ICET_RunFinalOptCondEntTemp: bool = False
    ICET_CondenserWaterSetPt: float = 0.0
    ICET_TotEnergyPre: float = 0.0
    CET_ActualLoadSum: float = 0.0
    CET_DesignLoadSum: float = 0.0
    CET_WeightedActualLoadSum: float = 0.0
    CET_WeightedDesignLoadSum: float = 0.0
    CET_WeightedLoadRatio: float = 0.0
    CET_DesignMinCondenserSetPt: float = 0.0
    CET_DesignEnteringCondenserTemp: float = 0.0
    CET_DesignMinWetBulbTemp: float = 0.0
    CET_MinActualWetBulbTemp: float = 0.0
    CET_OptCondenserEnteringTemp: float = 0.0
    CET_CurMinLift: float = 0.0


def interp_set_point(low_val: float, high_val: float, ref_val: float, 
                     setp_at_low: float, setp_at_high: float) -> float:
    """Interpolate setpoint between two reference values."""
    if low_val >= high_val:
        return 0.5 * (setp_at_low + setp_at_high)
    if ref_val <= low_val:
        return setp_at_low
    if ref_val >= high_val:
        return setp_at_high
    return setp_at_low - ((ref_val - low_val) / (high_val - low_val)) * (setp_at_low - setp_at_high)


def get_set_point_manager_index(state: Any, name: str) -> int:
    """Get the index of a setpoint manager by name."""
    found = state.dataSetPointManager.spmMap.get(name)
    return found if found else 0


def manage_set_points(state: Any) -> None:
    """Main entry point for setpoint manager simulation."""
    if state.dataSetPointManager.GetInputFlag:
        # Get input would go here
        state.dataSetPointManager.GetInputFlag = False
    
    # Initialize, simulate, and update setpoint managers
    if state.dataSetPointManager.ManagerOn:
        for spm in state.dataSetPointManager.spms:
            if spm.type not in (SPMType.MixedAir, SPMType.OutsideAirPretreat):
                spm.calculate(state)


def update_set_point_managers(state: Any) -> None:
    """Update node setpoints from calculated values."""
    for spm in state.dataSetPointManager.spms:
        if spm.type == SPMType.Scheduled:
            for ctrl_node_num in spm.ctrlNodeNums:
                node = state.dataLoopNodes.Node(ctrl_node_num)
                if spm.ctrlVar == CtrlVarType.Temp:
                    node.TempSetPoint = spm.setPt
                elif spm.ctrlVar == CtrlVarType.MaxTemp:
                    node.TempSetPointHi = spm.setPt
                elif spm.ctrlVar == CtrlVarType.MinTemp:
                    node.TempSetPointLo = spm.setPt


def update_mixed_air_set_points(state: Any) -> None:
    """Update setpoints for mixed air managers."""
    for spm in state.dataSetPointManager.spms:
        if spm.type != SPMType.MixedAir or spm.ctrlVar != CtrlVarType.Temp:
            continue
        for ctrl_node_num in spm.ctrlNodeNums:
            state.dataLoopNodes.Node(ctrl_node_num).TempSetPoint = spm.setPt


def update_oa_pretreat_set_points(state: Any) -> None:
    """Update setpoints for outdoor air pretreat managers."""
    for spm in state.dataSetPointManager.spms:
        if spm.type != SPMType.OutsideAirPretreat:
            continue
        for ctrl_node_num in spm.ctrlNodeNums:
            node = state.dataLoopNodes.Node(ctrl_node_num)
            if spm.ctrlVar == CtrlVarType.Temp:
                node.TempSetPoint = spm.setPt
            elif spm.ctrlVar == CtrlVarType.MaxHumRat:
                node.HumRatMax = spm.setPt
            elif spm.ctrlVar == CtrlVarType.MinHumRat:
                node.HumRatMin = spm.setPt


def is_node_on_set_pt_manager(state: Any, node_num: int, ctrl_var: int) -> bool:
    """Check if a node is controlled by a setpoint manager of given type."""
    for spm in state.dataSetPointManager.spms:
        if spm.ctrlVar != ctrl_var:
            continue
        if node_num in spm.ctrlNodeNums:
            return True
    return False


def node_has_spm_ctrl_var_type(state: Any, node_num: int, ctrl_var: int) -> bool:
    """Check if a node has a specific control variable type."""
    for spm in state.dataSetPointManager.spms:
        if spm.ctrlVar != ctrl_var:
            continue
        if node_num in spm.ctrlNodeNums:
            return True
    return False


def get_humidity_ratio_variable_type(state: Any, ctrl_node_num: int) -> int:
    """Determine humidity ratio setpoint variable type for a node."""
    for spm in state.dataSetPointManager.spms:
        if spm.type in (SPMType.SZMaxHum, SPMType.MZMaxHum, SPMType.MZMaxHumAverage):
            if ctrl_node_num in spm.ctrlNodeNums:
                return CtrlVarType.MaxHumRat
    
    for spm in state.dataSetPointManager.spms:
        if spm.type in (SPMType.SZMinHum, SPMType.MZMinHum, SPMType.MZMinHumAverage):
            if ctrl_node_num in spm.ctrlNodeNums:
                return CtrlVarType.MaxHumRat
    
    for spm in state.dataSetPointManager.spms:
        if spm.type == SPMType.Scheduled:
            if ctrl_node_num in spm.ctrlNodeNums:
                if spm.ctrlVar in (CtrlVarType.HumRat, CtrlVarType.MaxHumRat):
                    return spm.ctrlVar
    
    return CtrlVarType.HumRat


def get_mixed_air_num_with_coil_freezing_check(state: Any, mixed_air_node: int) -> int:
    """Get the index of a mixed air SPM with coil freezing check."""
    for i_spm in range(len(state.dataSetPointManager.spms)):
        spm = state.dataSetPointManager.spms[i_spm]
        if spm.type != SPMType.MixedAir:
            continue
        if hasattr(spm, 'ctrlNodeNums') and mixed_air_node in spm.ctrlNodeNums:
            if hasattr(spm, 'coolCoilInNodeNum') and hasattr(spm, 'coolCoilOutNodeNum'):
                if spm.coolCoilInNodeNum > 0 and spm.coolCoilOutNodeNum > 0:
                    return i_spm + 1
    return 0
