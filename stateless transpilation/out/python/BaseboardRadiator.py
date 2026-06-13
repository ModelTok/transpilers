"""
EnergyPlus BaseboardRadiator module - faithful Python port.

EXTERNAL DEPS (to wire in glue):
- EnergyPlusData: main state container with sub-objects:
  .dataBaseboardRadiator: BaseboardRadiatorData instance
  .dataZoneEnergyDemand: zones' energy demand state
  .dataLoopNodes: node array and properties
  .dataZoneEquip: zone equipment configuration
  .dataGlobal: global simulation state
  .dataSize: sizing calculation state
  .dataHeatBal: heat balance data (Zone array)
  .dataHVACGlobal: HVAC globals (TimeStepSysSec)
  .dataInputProcessing: input processor
  .dataPlnt: plant loop data
- Schedule: class with getCurrentVal() -> float
- PlantLocation: struct with .loop, .branch, .comp
- PlantLoop: has .PlantSizNum, .glycol (Fluid)
- Fluid: has getDensity(state, temp, routine_name), getSpecificHeat(state, temp, routine_name)
- Zone: has .FloorArea
- LoopNode: has Temp, HumRat, Enthalpy, Quality, Press, MassFlowRate, MassFlowRateMaxAvail, MassFlowRateMinAvail
- ZoneEquipConfig: has .ZoneNode
- ZoneSysEnergyDemand: has .RemainingOutputReqToHeatSP
- External functions: Util.FindItemInList, Util.makeUPPER, Util.SameString
  ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowWarningError, ShowMessage, ShowContinueError
  PlantUtilities.SetActuatedBranchFlowRate, PlantUtilities.ScanPlantLoopsForObject, PlantUtilities.InitComponentNodes
  PlantUtilities.RegisterPlantCompDesignFlow, PlantUtilities.SafeCopyPlantNode
  Node.GetOnlySingleNode, Node.TestCompSet, ControlCompOutput, CheckZoneSizing
  Sched.GetScheduleAlwaysOn, Sched.GetSchedule, GlobalNames.VerifyUniqueBaseboardName
  BaseSizer.reportSizerOutput, HeatingCapacitySizer class, General.SolveRoot
  Psychrometrics.PsyCpAirFnW, Psychrometrics.PsyRhoAirFnPbTdbW
  SetupOutputVariable, OutputProcessor constants
  DataSizing constants (AutoSize, HeatingDesignCapacity, CapacityPerFloorArea, FractionOfAutosizedHeatingCapacity)
  DataPlant.PlantEquipmentType enum
  DataZoneEquipment functions and enums
"""

from dataclasses import dataclass, field
from typing import List, Optional, Callable, Protocol
import math

# Constants
cCMO_BBRadiator_Water = "ZoneHVAC:Baseboard:Convective:Water"

# Enum-like constants (from DataSizing)
AutoSize = -99999.0
HeatingDesignCapacity = 1
CapacityPerFloorArea = 2
FractionOfAutosizedHeatingCapacity = 3

# Physical constants
HWInitConvTemp = 60.0  # Constant::HWInitConvTemp
SmallLoad = 1e-10

# Precision constants
EXP_LowerLimit = -745.0

# Sizing algorithm constants
Acc = 0.0001
MaxIte = 500

# Numeric field indices
iHeatDesignCapacityNumericNum = 1
iHeatCapacityPerFloorAreaNumericNum = 2
iHeatFracOfAutosizedCapacityNumericNum = 3

RoutineName = "GetBaseboardInput: "
routineName = "GetBaseboardInput"

class Schedule(Protocol):
    def getCurrentVal(self) -> float:
        pass

class PlantLocation:
    def __init__(self):
        self.loop = None
        self.branch = 0
        self.comp = 0

class Zone(Protocol):
    FloorArea: float

class LoopNode(Protocol):
    Temp: float
    HumRat: float
    Enthalpy: float
    Quality: float
    Press: float
    MassFlowRate: float
    MassFlowRateMaxAvail: float
    MassFlowRateMinAvail: float

class ZoneEquipConfig(Protocol):
    ZoneNode: int

class ZoneSysEnergyDemand(Protocol):
    RemainingOutputReqToHeatSP: float

class BaseboardRadiatorData:
    def __init__(self):
        self.getInputFlag = True
        self.baseboards: List['BaseboardParams'] = []

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        self.getInputFlag = True
        self.baseboards = []

@dataclass
class BaseboardParams:
    EquipID: str = ""
    Schedule: str = ""
    availSched: Optional[Schedule] = None
    EquipType: int = 0  # DataPlant::PlantEquipmentType::Invalid
    ZonePtr: int = 0
    WaterInletNode: int = 0
    WaterOutletNode: int = 0
    ControlCompTypeNum: int = 0
    CompErrIndex: int = 0
    UA: float = 0.0
    WaterMassFlowRate: float = 0.0
    WaterVolFlowRateMax: float = 0.0
    WaterMassFlowRateMax: float = 0.0
    Offset: float = 0.0
    AirMassFlowRate: float = 0.0
    DesAirMassFlowRate: float = 0.0
    WaterInletTemp: float = 0.0
    WaterOutletTemp: float = 0.0
    WaterInletEnthalpy: float = 0.0
    WaterOutletEnthalpy: float = 0.0
    AirInletTemp: float = 0.0
    AirInletHumRat: float = 0.0
    AirOutletTemp: float = 0.0
    Power: float = 0.0
    Energy: float = 0.0
    plantLoc: Optional[PlantLocation] = field(default_factory=PlantLocation)
    FieldNames: List[str] = field(default_factory=list)
    HeatingCapMethod: int = 0
    ScaledHeatingCapacity: float = 0.0
    MySizeFlag: bool = True
    CheckEquipName: bool = True
    SetLoopIndexFlag: bool = True
    MyEnvrnFlag: bool = True

    def InitBaseboard(self, state, baseboard_num: int) -> None:
        routine_name = "BaseboardRadiator:InitBaseboard"

        if self.SetLoopIndexFlag and hasattr(state.dataPlnt, 'PlantLoop') and state.dataPlnt.PlantLoop is not None:
            err_flag = False
            # PlantUtilities::ScanPlantLoopsForObject stub
            import_plant_loop_scan(state, self.EquipID, self.EquipType, self.plantLoc, err_flag)
            if err_flag:
                raise RuntimeError("InitBaseboard: Program terminated for previous conditions.")
            self.SetLoopIndexFlag = False

        if not state.dataGlobal.SysSizingCalc and self.MySizeFlag and not self.SetLoopIndexFlag:
            self.SizeBaseboard(state, baseboard_num)
            self.MySizeFlag = False

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and not self.SetLoopIndexFlag:
            water_inlet_node = self.WaterInletNode
            rho = self.plantLoc.loop.glycol.getDensity(state, HWInitConvTemp, routine_name)
            self.WaterMassFlowRateMax = rho * self.WaterVolFlowRateMax
            init_component_nodes(state, 0.0, self.WaterMassFlowRateMax, self.WaterInletNode, self.WaterOutletNode)
            state.dataLoopNodes.Node[water_inlet_node].Temp = HWInitConvTemp
            cp = self.plantLoc.loop.glycol.getSpecificHeat(state, state.dataLoopNodes.Node[water_inlet_node].Temp, routine_name)
            state.dataLoopNodes.Node[water_inlet_node].Enthalpy = cp * state.dataLoopNodes.Node[water_inlet_node].Temp
            state.dataLoopNodes.Node[water_inlet_node].Quality = 0.0
            state.dataLoopNodes.Node[water_inlet_node].Press = 0.0
            state.dataLoopNodes.Node[water_inlet_node].HumRat = 0.0
            if self.AirMassFlowRate <= 0.0:
                self.AirMassFlowRate = 2.0 * self.WaterMassFlowRateMax
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        water_inlet_node = self.WaterInletNode
        zone_node = state.dataZoneEquip.ZoneEquipConfig[self.ZonePtr].ZoneNode
        self.WaterMassFlowRate = state.dataLoopNodes.Node[water_inlet_node].MassFlowRate
        self.WaterInletTemp = state.dataLoopNodes.Node[water_inlet_node].Temp
        self.WaterInletEnthalpy = state.dataLoopNodes.Node[water_inlet_node].Enthalpy
        self.AirInletTemp = state.dataLoopNodes.Node[zone_node].Temp
        self.AirInletHumRat = state.dataLoopNodes.Node[zone_node].HumRat

    def SizeBaseboard(self, state, baseboard_num: int) -> None:
        size_routine = cCMO_BBRadiator_Water + ":SizeBaseboard"
        
        des_coil_load = 0.0
        ua0 = 0.0
        ua1 = 0.0
        ua = 0.0
        errors_found = False
        rho = 0.0
        cp = 0.0
        water_vol_flow_rate_max_des = 0.0
        water_vol_flow_rate_max_user = 0.0
        ua_des = 0.0
        ua_user = 0.0
        temp_size = 0.0

        plt_siz_heat_num = self.plantLoc.loop.PlantSizNum if self.plantLoc and self.plantLoc.loop else 0

        if plt_siz_heat_num > 0:
            state.dataSize.DataScalableCapSizingON = False

            if state.dataSize.CurZoneEqNum > 0:
                flow_auto_size = self.WaterVolFlowRateMax == AutoSize
                
                if not flow_auto_size and not state.dataSize.ZoneSizingRunDone:
                    if self.WaterVolFlowRateMax > 0.0:
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "User-Specified Maximum Water Flow Rate [m3/s]", self.WaterVolFlowRateMax)
                else:
                    zone_eq_sizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                    final_zone_sizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                    comp_type = cCMO_BBRadiator_Water
                    comp_name = self.EquipID
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                    state.dataSize.DataZoneNumber = self.ZonePtr
                    sizing_method = 1  # HVAC::HeatingCapacitySizing
                    field_num = 1
                    sizing_string = f"{self.FieldNames[field_num - 1]} [W]"
                    cap_sizing_method = self.HeatingCapMethod
                    zone_eq_sizing.SizingMethod = cap_sizing_method
                    
                    if (cap_sizing_method == HeatingDesignCapacity or 
                        cap_sizing_method == CapacityPerFloorArea or 
                        cap_sizing_method == FractionOfAutosizedHeatingCapacity):
                        
                        if cap_sizing_method == HeatingDesignCapacity:
                            if self.ScaledHeatingCapacity == AutoSize:
                                zone_eq_sizing.DesHeatingLoad = final_zone_sizing.NonAirSysDesHeatLoad
                            else:
                                zone_eq_sizing.DesHeatingLoad = self.ScaledHeatingCapacity
                            zone_eq_sizing.HeatingCapacity = True
                            temp_size = zone_eq_sizing.DesHeatingLoad
                        elif cap_sizing_method == CapacityPerFloorArea:
                            zone_eq_sizing.HeatingCapacity = True
                            zone_eq_sizing.DesHeatingLoad = (self.ScaledHeatingCapacity * 
                                                            state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea)
                            temp_size = zone_eq_sizing.DesHeatingLoad
                            state.dataSize.DataScalableCapSizingON = True
                        elif cap_sizing_method == FractionOfAutosizedHeatingCapacity:
                            zone_eq_sizing.HeatingCapacity = True
                            state.dataSize.DataFracOfAutosizedHeatingCapacity = self.ScaledHeatingCapacity
                            zone_eq_sizing.DesHeatingLoad = final_zone_sizing.NonAirSysDesHeatLoad
                            temp_size = AutoSize
                            state.dataSize.DataScalableCapSizingON = True
                        else:
                            temp_size = self.ScaledHeatingCapacity
                        
                        print_flag = False
                        errs_found = False
                        des_coil_load = heating_capacity_sizer(state, comp_type, comp_name, sizing_string, 
                                                              temp_size, print_flag, size_routine)
                        state.dataSize.DataScalableCapSizingON = False
                    else:
                        des_coil_load = 0.0

                    if des_coil_load >= SmallLoad:
                        cp = self.plantLoc.loop.glycol.getSpecificHeat(state, HWInitConvTemp, size_routine)
                        rho = self.plantLoc.loop.glycol.getDensity(state, HWInitConvTemp, size_routine)
                        water_vol_flow_rate_max_des = (des_coil_load / 
                                                      (state.dataSize.PlantSizData[plt_siz_heat_num].DeltaT * cp * rho))
                    else:
                        water_vol_flow_rate_max_des = 0.0

                    if flow_auto_size:
                        self.WaterVolFlowRateMax = water_vol_flow_rate_max_des
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "Design Size Maximum Water Flow Rate [m3/s]", water_vol_flow_rate_max_des)
                    else:
                        if self.WaterVolFlowRateMax > 0.0 and water_vol_flow_rate_max_des > 0.0:
                            water_vol_flow_rate_max_user = self.WaterVolFlowRateMax
                            report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                              "Design Size Maximum Water Flow Rate [m3/s]", water_vol_flow_rate_max_des,
                                              "User-Specified Maximum Water Flow Rate [m3/s]", water_vol_flow_rate_max_user)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if ((abs(water_vol_flow_rate_max_des - water_vol_flow_rate_max_user) / water_vol_flow_rate_max_user) > 
                                    state.dataSize.AutoVsHardSizingThreshold):
                                    msg = (f"SizeBaseboard: Potential issue with equipment sizing for "
                                          f"ZoneHVAC:Baseboard:Convective:Water=\"{self.EquipID}\".")
                                    show_extra_warning(state, msg, water_vol_flow_rate_max_user, water_vol_flow_rate_max_des)

                ua_auto_size = self.UA == AutoSize
                if not ua_auto_size:
                    ua_user = self.UA
                
                if not ua_auto_size and not state.dataSize.ZoneSizingRunDone:
                    if self.UA > 0.0:
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "User-Specified U-Factor Times Area Value [W/K]", self.UA)
                else:
                    zone_eq_sizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                    final_zone_sizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                    self.WaterInletTemp = state.dataSize.PlantSizData[plt_siz_heat_num].ExitTemp
                    self.AirInletTemp = final_zone_sizing.ZoneTempAtHeatPeak
                    self.AirInletHumRat = final_zone_sizing.ZoneHumRatAtHeatPeak
                    rho = self.plantLoc.loop.glycol.getDensity(state, HWInitConvTemp, size_routine)
                    state.dataLoopNodes.Node[self.WaterInletNode].MassFlowRate = rho * self.WaterVolFlowRateMax

                    comp_type = cCMO_BBRadiator_Water
                    comp_name = self.EquipID
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                    state.dataSize.DataZoneNumber = self.ZonePtr
                    sizing_method = 1
                    field_num = 1
                    sizing_string = f"{self.FieldNames[field_num - 1]} [W]"
                    cap_sizing_method = self.HeatingCapMethod
                    zone_eq_sizing.SizingMethod = cap_sizing_method
                    
                    if (cap_sizing_method == HeatingDesignCapacity or 
                        cap_sizing_method == CapacityPerFloorArea or 
                        cap_sizing_method == FractionOfAutosizedHeatingCapacity):
                        if cap_sizing_method == HeatingDesignCapacity:
                            if self.ScaledHeatingCapacity == AutoSize:
                                zone_eq_sizing.DesHeatingLoad = final_zone_sizing.NonAirSysDesHeatLoad
                            else:
                                zone_eq_sizing.DesHeatingLoad = self.ScaledHeatingCapacity
                            zone_eq_sizing.HeatingCapacity = True
                            temp_size = zone_eq_sizing.DesHeatingLoad
                        elif cap_sizing_method == CapacityPerFloorArea:
                            zone_eq_sizing.HeatingCapacity = True
                            zone_eq_sizing.DesHeatingLoad = (self.ScaledHeatingCapacity * 
                                                            state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea)
                            temp_size = zone_eq_sizing.DesHeatingLoad
                            state.dataSize.DataScalableCapSizingON = True
                        elif cap_sizing_method == FractionOfAutosizedHeatingCapacity:
                            zone_eq_sizing.HeatingCapacity = True
                            state.dataSize.DataFracOfAutosizedHeatingCapacity = self.ScaledHeatingCapacity
                            zone_eq_sizing.DesHeatingLoad = final_zone_sizing.NonAirSysDesHeatLoad
                            temp_size = AutoSize
                            state.dataSize.DataScalableCapSizingON = True
                        else:
                            temp_size = self.ScaledHeatingCapacity
                        
                        print_flag = False
                        errs_found = False
                        des_coil_load = heating_capacity_sizer(state, comp_type, comp_name, sizing_string, 
                                                              temp_size, print_flag, size_routine)
                        state.dataSize.DataScalableCapSizingON = False
                    else:
                        des_coil_load = 0.0
                    
                    if des_coil_load >= SmallLoad:
                        self.DesAirMassFlowRate = 2.0 * rho * self.WaterVolFlowRateMax
                        ua0 = 0.001 * des_coil_load
                        ua1 = des_coil_load

                        self.UA = ua0
                        load_met = 0.0
                        sim_hw_convective(state, baseboard_num, load_met)
                        
                        if load_met < des_coil_load:
                            self.UA = ua1
                            sim_hw_convective(state, baseboard_num, load_met)

                            if load_met > des_coil_load:
                                def f_residual(ua_val):
                                    state.dataBaseboardRadiator.baseboards[baseboard_num - 1].UA = ua_val
                                    load_val = 0.0
                                    sim_hw_convective(state, baseboard_num, load_val)
                                    return (des_coil_load - load_val) / des_coil_load

                                sol_fla = 0
                                ua_final = solve_root(Acc, MaxIte, sol_fla, ua0, ua1, f_residual)
                                
                                if sol_fla == -1:
                                    show_severe_error(state, 
                                                    f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, "Iteration limit exceeded in calculating coil UA")
                                    if ua_auto_size:
                                        errors_found = True
                                    else:
                                        ua_final = 0.0
                                elif sol_fla == -2:
                                    show_severe_error(state,
                                                    f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, "Bad starting values for UA")
                                    if ua_auto_size:
                                        errors_found = True
                                    else:
                                        ua_final = 0.0
                                ua_des = ua_final
                            else:
                                ua_des = ua1
                                if ua_auto_size:
                                    show_warning_error(state,
                                                     f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state,
                                                      f"Design UA set equal to design coil load for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, f"Design coil load used during sizing = {des_coil_load:.5f} W.")
                                    show_continue_error(state, f"Inlet water temperature used during sizing = {self.WaterInletTemp:.5f} C.")
                        else:
                            ua_des = ua0
                            if ua_auto_size:
                                show_warning_error(state,
                                                 f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                show_continue_error(state,
                                                  f"Design UA set equal to 0.001 * design coil load for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                show_continue_error(state, f"Design coil load used during sizing = {des_coil_load:.5f} W.")
                                show_continue_error(state, f"Inlet water temperature used during sizing = {self.WaterInletTemp:.5f} C.")
                    else:
                        ua_des = 0.0

                    if ua_auto_size:
                        self.UA = ua_des
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "Design Size U-Factor Times Area Value [W/K]", ua_des)
                    else:
                        self.UA = ua_user
                        if ua_user > 0.0 and ua_des > 0.0:
                            report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                              "Design Size U-Factor Times Area Value [W/K]", ua_des,
                                              "User-Specified U-Factor Times Area Value [W/K]", ua_user)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(ua_des - ua_user) / ua_user) > state.dataSize.AutoVsHardSizingThreshold:
                                    msg = (f"SizeBaseboard: Potential issue with equipment sizing for "
                                          f"ZoneHVAC:Baseboard:Convective:Water=\"{self.EquipID}\".")
                                    show_extra_ua_warning(state, msg, ua_user, ua_des)
        else:
            if self.WaterVolFlowRateMax == AutoSize or self.UA == AutoSize:
                show_severe_error(state, f"SizeBaseboard: {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                show_continue_error(state, "...Autosizing of hot water baseboard requires a heating loop Sizing:Plant object")
                errors_found = True

        register_plant_comp_design_flow(state, self.WaterInletNode, self.WaterVolFlowRateMax)

        if errors_found:
            raise RuntimeError("SizeBaseboard: Preceding sizing errors cause program termination")

    def checkForZoneSizing(self, state) -> None:
        if ((self.UA == AutoSize) or (self.WaterVolFlowRateMax == AutoSize) or
            ((self.HeatingCapMethod == HeatingDesignCapacity) and (self.ScaledHeatingCapacity == AutoSize)) or
            ((self.HeatingCapMethod == FractionOfAutosizedHeatingCapacity) and (self.ScaledHeatingCapacity == AutoSize))):
            check_zone_sizing(state, cCMO_BBRadiator_Water, self.EquipID)

def SimBaseboard(state, equip_name: str, controlled_zone_num: int, first_hvac_iteration: bool, 
                 power_met_ref: dict, comp_index_ref: dict) -> None:
    if state.dataBaseboardRadiator.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardRadiator.getInputFlag = False

    if comp_index_ref['value'] == 0:
        baseboard_num = find_item_in_list(equip_name, state.dataBaseboardRadiator.baseboards, 'EquipID')
        if baseboard_num == -1:
            raise RuntimeError(f"SimBaseboard: Unit not found={equip_name}")
        comp_index_ref['value'] = baseboard_num + 1  # Convert to 1-based

    comp_idx_1based = comp_index_ref['value']
    assert comp_idx_1based <= len(state.dataBaseboardRadiator.baseboards)
    this_baseboard = state.dataBaseboardRadiator.baseboards[comp_idx_1based - 1]  # Convert to 0-based

    if this_baseboard.CheckEquipName:
        if equip_name != this_baseboard.EquipID:
            raise RuntimeError(f"SimBaseboard: Invalid CompIndex passed={comp_idx_1based}, Unit name={equip_name}, "
                             f"stored Unit Name for that index={this_baseboard.EquipID}")
        this_baseboard.CheckEquipName = False

    this_baseboard.InitBaseboard(state, comp_idx_1based)

    q_zn_req = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[controlled_zone_num].RemainingOutputReqToHeatSP
    max_water_flow = 0.0
    min_water_flow = 0.0
    dummy_mdot = 0.0

    if (q_zn_req < SmallLoad) or (this_baseboard.WaterInletTemp <= this_baseboard.AirInletTemp):
        this_baseboard.WaterOutletTemp = this_baseboard.WaterInletTemp
        this_baseboard.AirOutletTemp = this_baseboard.AirInletTemp
        this_baseboard.Power = 0.0
        this_baseboard.WaterMassFlowRate = 0.0
        dummy_mdot = 0.0
        set_actuated_branch_flow_rate(state, dummy_mdot, this_baseboard.WaterInletNode, this_baseboard.plantLoc, False)
    else:
        dummy_mdot = 0.0
        set_actuated_branch_flow_rate(state, dummy_mdot, this_baseboard.WaterInletNode, this_baseboard.plantLoc, True)

        if first_hvac_iteration:
            max_water_flow = this_baseboard.WaterMassFlowRateMax
            min_water_flow = 0.0
        else:
            max_water_flow = state.dataLoopNodes.Node[this_baseboard.WaterInletNode].MassFlowRateMaxAvail
            min_water_flow = state.dataLoopNodes.Node[this_baseboard.WaterInletNode].MassFlowRateMinAvail

        control_comp_output(state, this_baseboard.EquipID, cCMO_BBRadiator_Water, comp_idx_1based,
                           first_hvac_iteration, q_zn_req, this_baseboard.WaterInletNode,
                           max_water_flow, min_water_flow, this_baseboard.Offset,
                           this_baseboard.ControlCompTypeNum, this_baseboard.CompErrIndex,
                           this_baseboard.plantLoc)

        power_met_ref['value'] = this_baseboard.Power

    UpdateBaseboard(state, comp_idx_1based)
    this_baseboard.Energy = this_baseboard.Power * state.dataHVACGlobal.TimeStepSysSec

def GetBaseboardInput(state) -> None:
    c_current_module_object = cCMO_BBRadiator_Water

    num_conv_hw_baseboards = get_num_objects_found(state, c_current_module_object)

    state.dataBaseboardRadiator.baseboards = [None] * num_conv_hw_baseboards

    if num_conv_hw_baseboards > 0:
        errors_found = False

        for bb_num in range(num_conv_hw_baseboards):
            this_baseboard = BaseboardParams()
            state.dataBaseboardRadiator.baseboards[bb_num] = this_baseboard

            numeric_field_names = ["Heating Design Capacity",
                                  "Heating Design Capacity Per Floor Area",
                                  "Fraction of Autosized Heating Design Capacity",
                                  "U-Factor Times Area Value",
                                  "Maximum Water Flow Rate",
                                  "Convergence Tolerance"]
            this_baseboard.FieldNames = numeric_field_names

            baseboard_name = get_baseboard_name(state, c_current_module_object, bb_num)
            availability_schedule_name = get_field_value(state, c_current_module_object, bb_num, "availability_schedule_name")
            inlet_node_name = get_field_value(state, c_current_module_object, bb_num, "inlet_node_name")
            outlet_node_name = get_field_value(state, c_current_module_object, bb_num, "outlet_node_name")
            heating_design_capacity_method = get_field_value(state, c_current_module_object, bb_num, "heating_design_capacity_method")

            verify_unique_baseboard_name(state, c_current_module_object, baseboard_name, errors_found)

            this_baseboard.EquipID = baseboard_name
            this_baseboard.EquipType = 8  # DataPlant::PlantEquipmentType::Baseboard_Conv_Water
            this_baseboard.Schedule = availability_schedule_name
            
            if not availability_schedule_name:
                this_baseboard.availSched = get_schedule_always_on(state)
            else:
                sched = get_schedule(state, availability_schedule_name)
                if sched is None:
                    show_severe_item_not_found(state, "Availability Schedule Name", availability_schedule_name)
                    errors_found = True
                this_baseboard.availSched = sched

            this_baseboard.WaterInletNode = get_only_single_node(state, inlet_node_name, errors_found)
            this_baseboard.WaterOutletNode = get_only_single_node(state, outlet_node_name, errors_found)

            test_comp_set(state, c_current_module_object, baseboard_name, inlet_node_name, outlet_node_name)

            if same_string(heating_design_capacity_method, "HeatingDesignCapacity"):
                this_baseboard.HeatingCapMethod = HeatingDesignCapacity
                heating_cap = get_real_field_value(state, c_current_module_object, bb_num, "heating_design_capacity")
                if heating_cap < 0.0 and heating_cap != AutoSize:
                    show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                    show_continue_error(state, f"Illegal {numeric_field_names[iHeatDesignCapacityNumericNum - 1]} = {heating_cap:.7f}")
                    errors_found = True
                else:
                    this_baseboard.ScaledHeatingCapacity = heating_cap
            elif same_string(heating_design_capacity_method, "CapacityPerFloorArea"):
                this_baseboard.HeatingCapMethod = CapacityPerFloorArea
                heating_cap_per_area = get_real_field_value(state, c_current_module_object, bb_num, "heating_design_capacity_per_floor_area")
                if heating_cap_per_area <= 0.0:
                    show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                    show_continue_error(state, f"Illegal {numeric_field_names[iHeatCapacityPerFloorAreaNumericNum - 1]} = {heating_cap_per_area:.7f}")
                    errors_found = True
                elif heating_cap_per_area == AutoSize:
                    show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                    show_continue_error(state, f"Illegal {numeric_field_names[iHeatCapacityPerFloorAreaNumericNum - 1]} = Autosize")
                    errors_found = True
                else:
                    this_baseboard.ScaledHeatingCapacity = heating_cap_per_area
            elif same_string(heating_design_capacity_method, "FractionOfAutosizedHeatingCapacity"):
                this_baseboard.HeatingCapMethod = FractionOfAutosizedHeatingCapacity
                frac_heating_cap = get_real_field_value(state, c_current_module_object, bb_num, "fraction_of_autosized_heating_design_capacity")
                if frac_heating_cap < 0.0:
                    show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                    show_continue_error(state, f"Illegal {numeric_field_names[iHeatFracOfAutosizedCapacityNumericNum - 1]} = {frac_heating_cap:.7f}")
                    errors_found = True
                else:
                    this_baseboard.ScaledHeatingCapacity = frac_heating_cap
            else:
                show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                show_continue_error(state, f"Illegal {heating_design_capacity_method}")
                errors_found = True

            this_baseboard.UA = get_real_field_value(state, c_current_module_object, bb_num, "u_factor_times_area_value")
            this_baseboard.WaterVolFlowRateMax = get_real_field_value(state, c_current_module_object, bb_num, "maximum_water_flow_rate")
            this_baseboard.Offset = get_real_field_value(state, c_current_module_object, bb_num, "convergence_tolerance")
            
            if this_baseboard.Offset <= 0.0:
                this_baseboard.Offset = 0.001

            this_baseboard.ZonePtr = get_zone_equip_controlled_zone_num(state, 8, this_baseboard.EquipID)  # 8 = BaseboardConvectiveWater
            this_baseboard.checkForZoneSizing(state)

        if errors_found:
            raise RuntimeError(f"{RoutineName}Errors found in getting input.  Preceding condition(s) cause termination.")

    for bb_idx in range(len(state.dataBaseboardRadiator.baseboards)):
        this_bb = state.dataBaseboardRadiator.baseboards[bb_idx]
        setup_output_variable(state, "Baseboard Total Heating Energy", this_bb.Energy)
        setup_output_variable(state, "Baseboard Hot Water Energy", this_bb.Energy)
        setup_output_variable(state, "Baseboard Total Heating Rate", this_bb.Power)
        setup_output_variable(state, "Baseboard Hot Water Mass Flow Rate", this_bb.WaterMassFlowRate)
        setup_output_variable(state, "Baseboard Air Mass Flow Rate", this_bb.AirMassFlowRate)
        setup_output_variable(state, "Baseboard Air Inlet Temperature", this_bb.AirInletTemp)
        setup_output_variable(state, "Baseboard Air Outlet Temperature", this_bb.AirOutletTemp)
        setup_output_variable(state, "Baseboard Water Inlet Temperature", this_bb.WaterInletTemp)
        setup_output_variable(state, "Baseboard Water Outlet Temperature", this_bb.WaterOutletTemp)

def SimHWConvective(state, baseboard_num: int, load_met_ref: dict) -> None:
    baseboard = state.dataBaseboardRadiator.baseboards[baseboard_num - 1]
    zone_num = baseboard.ZonePtr

    q_zn_req = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num].RemainingOutputReqToHeatSP
    if baseboard.MySizeFlag:
        q_zn_req = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad

    water_inlet_temp = baseboard.WaterInletTemp
    air_inlet_temp = baseboard.AirInletTemp

    cp_water = baseboard.plantLoc.loop.glycol.getSpecificHeat(state, water_inlet_temp, cCMO_BBRadiator_Water + ":SimHWConvective")
    cp_air = psy_cp_air_fn_w(baseboard.AirInletHumRat)

    if baseboard.DesAirMassFlowRate > 0.0:
        air_mass_flow_rate = baseboard.DesAirMassFlowRate
    else:
        air_mass_flow_rate = baseboard.AirMassFlowRate
        if air_mass_flow_rate <= 0.0:
            air_mass_flow_rate = 2.0 * baseboard.WaterMassFlowRateMax

    water_mass_flow_rate = state.dataLoopNodes.Node[baseboard.WaterInletNode].MassFlowRate
    capacitance_air = cp_air * air_mass_flow_rate

    if (q_zn_req > SmallLoad and 
        (not state.dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num] or baseboard.MySizeFlag) and
        (baseboard.availSched.getCurrentVal() > 0 or baseboard.MySizeFlag) and 
        (water_mass_flow_rate > 0.0)):

        capacitance_water = cp_water * water_mass_flow_rate
        capacitance_max = max(capacitance_air, capacitance_water)
        capacitance_min = min(capacitance_air, capacitance_water)
        capacity_ratio = capacitance_min / capacitance_max if capacitance_max > 0 else 0.0
        ntu = baseboard.UA / capacitance_min if capacitance_min > 0 else 0.0

        aa = -capacity_ratio * (ntu ** 0.78)
        if aa < EXP_LowerLimit:
            bb = 0.0
        else:
            bb = math.exp(aa)

        cc = (1.0 / capacity_ratio if capacity_ratio > 0 else 1.0) * (ntu ** 0.22) * (bb - 1.0)
        if cc < EXP_LowerLimit:
            effectiveness = 1.0
        else:
            effectiveness = 1.0 - math.exp(cc)

        air_outlet_temp = air_inlet_temp + effectiveness * capacitance_min * (water_inlet_temp - air_inlet_temp) / capacitance_air
        water_outlet_temp = water_inlet_temp - capacitance_air * (air_outlet_temp - air_inlet_temp) / capacitance_water
        load_met = capacitance_water * (water_inlet_temp - water_outlet_temp)
        baseboard.WaterOutletEnthalpy = baseboard.WaterInletEnthalpy - load_met / water_mass_flow_rate
    else:
        air_outlet_temp = air_inlet_temp
        water_outlet_temp = water_inlet_temp
        load_met = 0.0
        baseboard.WaterOutletEnthalpy = baseboard.WaterInletEnthalpy
        water_mass_flow_rate = 0.0

        set_actuated_branch_flow_rate(state, water_mass_flow_rate, baseboard.WaterInletNode, baseboard.plantLoc, False)
        air_mass_flow_rate = 0.0

    baseboard.WaterOutletTemp = water_outlet_temp
    baseboard.AirOutletTemp = air_outlet_temp
    baseboard.Power = load_met
    baseboard.WaterMassFlowRate = water_mass_flow_rate
    baseboard.AirMassFlowRate = air_mass_flow_rate
    
    load_met_ref['value'] = load_met

def sim_hw_convective(state, baseboard_num: int, load_met) -> None:
    load_met_ref = {'value': load_met}
    SimHWConvective(state, baseboard_num, load_met_ref)
    return load_met_ref['value']

def UpdateBaseboard(state, baseboard_num: int) -> None:
    baseboard = state.dataBaseboardRadiator
    water_inlet_node = baseboard.baseboards[baseboard_num - 1].WaterInletNode
    water_outlet_node = baseboard.baseboards[baseboard_num - 1].WaterOutletNode

    safe_copy_plant_node(state, water_inlet_node, water_outlet_node)
    state.dataLoopNodes.Node[water_outlet_node].Temp = baseboard.baseboards[baseboard_num - 1].WaterOutletTemp
    state.dataLoopNodes.Node[water_outlet_node].Enthalpy = baseboard.baseboards[baseboard_num - 1].WaterOutletEnthalpy

# External function stubs
def find_item_in_list(item_name: str, item_list: List[BaseboardParams], attr_name: str) -> int:
    for i, item in enumerate(item_list):
        if getattr(item, attr_name, None) == item_name:
            return i
    return -1

def show_fatal_error(state, message: str) -> None:
    raise RuntimeError(f"Fatal: {message}")

def show_severe_error(state, message: str) -> None:
    print(f"Severe: {message}")

def show_severe_item_not_found(state, field_name: str, value: str) -> None:
    print(f"Severe: {field_name} not found: {value}")

def show_warning_error(state, message: str) -> None:
    print(f"Warning: {message}")

def show_message(state, message: str) -> None:
    print(f"Message: {message}")

def show_continue_error(state, message: str) -> None:
    print(f"  {message}")

def show_extra_warning(state, msg: str, user_val: float, des_val: float) -> None:
    print(f"{msg}")
    print(f"  User value: {user_val}")
    print(f"  Design value: {des_val}")

def show_extra_ua_warning(state, msg: str, user_ua: float, des_ua: float) -> None:
    print(f"{msg}")
    print(f"  User UA: {user_ua:.2f} [W/K]")
    print(f"  Design UA: {des_ua:.2f} [W/K]")

def set_actuated_branch_flow_rate(state, mdot: float, node: int, ploc, execute: bool) -> None:
    pass

def import_plant_loop_scan(state, equip_id: str, equip_type: int, plant_loc, err_flag: bool) -> None:
    pass

def init_component_nodes(state, min_mdot: float, max_mdot: float, inlet_node: int, outlet_node: int) -> None:
    pass

def report_sizer_output(state, comp_type: str, comp_name: str, *args) -> None:
    pass

def heating_capacity_sizer(state, comp_type: str, comp_name: str, sizing_string: str, temp_size, 
                          print_flag: bool, routine_name: str) -> float:
    return 0.0

def safe_copy_plant_node(state, inlet_node: int, outlet_node: int) -> None:
    pass

def register_plant_comp_design_flow(state, node: int, flow: float) -> None:
    pass

def check_zone_sizing(state, obj_type: str, obj_name: str) -> None:
    pass

def control_comp_output(state, equip_id: str, equip_type: str, comp_idx: int, first_hvac: bool, 
                       q_required: float, inlet_node: int, max_flow: float, min_flow: float, 
                       offset: float, control_type: int, err_index: int, plant_loc) -> None:
    pass

def get_num_objects_found(state, obj_type: str) -> int:
    return 0

def get_baseboard_name(state, obj_type: str, index: int) -> str:
    return ""

def get_field_value(state, obj_type: str, index: int, field_name: str) -> str:
    return ""

def get_real_field_value(state, obj_type: str, index: int, field_name: str) -> float:
    return 0.0

def verify_unique_baseboard_name(state, obj_type: str, name: str, err_flag: bool) -> None:
    pass

def get_schedule_always_on(state):
    return None

def get_schedule(state, sched_name: str):
    return None

def get_only_single_node(state, node_name: str, err_flag: bool) -> int:
    return 0

def test_comp_set(state, obj_type: str, obj_name: str, inlet_name: str, outlet_name: str) -> None:
    pass

def same_string(s1: str, s2: str) -> bool:
    return s1.upper() == s2.upper()

def get_zone_equip_controlled_zone_num(state, equip_type: int, equip_name: str) -> int:
    return 0

def setup_output_variable(state, var_name: str, var_ref) -> None:
    pass

def psy_cp_air_fn_w(hum_rat: float) -> float:
    return 1006.0

def solve_root(acc: float, max_iter: int, sol_fla_ref: int, ua0: float, ua1: float, func: Callable) -> float:
    return (ua0 + ua1) / 2.0
