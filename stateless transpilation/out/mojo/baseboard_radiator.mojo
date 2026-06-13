import math
from collections import OrderedDict

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state container
# - Schedule: struct with getCurrentVal() -> Float64
# - PlantLocation: struct with loop, branch, comp fields
# - PlantLoop: struct with PlantSizNum field and glycol member
# - Fluid: struct with getDensity, getSpecificHeat methods
# - Zone: struct with FloorArea field
# - LoopNode: struct with Temp, HumRat, Enthalpy, Quality, Press, MassFlowRate, MassFlowRateMaxAvail, MassFlowRateMinAvail
# - ZoneEquipConfig: struct with ZoneNode field
# - ZoneSysEnergyDemand: struct with RemainingOutputReqToHeatSP field
# - External functions and procedures as indicated below

alias Real64 = Float64
alias Int = Int32

var cCMO_BBRadiator_Water: String = "ZoneHVAC:Baseboard:Convective:Water"

var AutoSize: Real64 = -99999.0
var HeatingDesignCapacity: Int = 1
var CapacityPerFloorArea: Int = 2
var FractionOfAutosizedHeatingCapacity: Int = 3

var HWInitConvTemp: Real64 = 60.0
var SmallLoad: Real64 = 1e-10
var EXP_LowerLimit: Real64 = -745.0

var Acc: Real64 = 0.0001
var MaxIte: Int = 500

var iHeatDesignCapacityNumericNum: Int = 1
var iHeatCapacityPerFloorAreaNumericNum: Int = 2
var iHeatFracOfAutosizedCapacityNumericNum: Int = 3

var RoutineName: String = "GetBaseboardInput: "
var routineName: String = "GetBaseboardInput"

struct Schedule:
    fn getCurrentVal(self) -> Real64:
        return 0.0

struct PlantLocation:
    var loop: UnsafeMutablePointer[PlantLoop]
    var branch: Int
    var comp: Int

struct PlantLoop:
    var PlantSizNum: Int
    var glycol: UnsafeMutablePointer[Fluid]

struct Fluid:
    fn getDensity(self, state, temp: Real64, routine_name: String) -> Real64:
        return 0.0
    fn getSpecificHeat(self, state, temp: Real64, routine_name: String) -> Real64:
        return 0.0

struct Zone:
    var FloorArea: Real64

struct LoopNode:
    var Temp: Real64
    var HumRat: Real64
    var Enthalpy: Real64
    var Quality: Real64
    var Press: Real64
    var MassFlowRate: Real64
    var MassFlowRateMaxAvail: Real64
    var MassFlowRateMinAvail: Real64

struct ZoneEquipConfig:
    var ZoneNode: Int

struct ZoneSysEnergyDemand:
    var RemainingOutputReqToHeatSP: Real64

struct BaseboardParams:
    var EquipID: String
    var Schedule: String
    var availSched: UnsafeMutablePointer[Schedule]
    var EquipType: Int
    var ZonePtr: Int
    var WaterInletNode: Int
    var WaterOutletNode: Int
    var ControlCompTypeNum: Int
    var CompErrIndex: Int
    var UA: Real64
    var WaterMassFlowRate: Real64
    var WaterVolFlowRateMax: Real64
    var WaterMassFlowRateMax: Real64
    var Offset: Real64
    var AirMassFlowRate: Real64
    var DesAirMassFlowRate: Real64
    var WaterInletTemp: Real64
    var WaterOutletTemp: Real64
    var WaterInletEnthalpy: Real64
    var WaterOutletEnthalpy: Real64
    var AirInletTemp: Real64
    var AirInletHumRat: Real64
    var AirOutletTemp: Real64
    var Power: Real64
    var Energy: Real64
    var plantLoc: PlantLocation
    var FieldNames: List[String]
    var HeatingCapMethod: Int
    var ScaledHeatingCapacity: Real64
    var MySizeFlag: Bool
    var CheckEquipName: Bool
    var SetLoopIndexFlag: Bool
    var MyEnvrnFlag: Bool

    fn __init__(inout self):
        self.EquipID = ""
        self.Schedule = ""
        self.availSched = UnsafeMutablePointer[Schedule]()
        self.EquipType = 0
        self.ZonePtr = 0
        self.WaterInletNode = 0
        self.WaterOutletNode = 0
        self.ControlCompTypeNum = 0
        self.CompErrIndex = 0
        self.UA = 0.0
        self.WaterMassFlowRate = 0.0
        self.WaterVolFlowRateMax = 0.0
        self.WaterMassFlowRateMax = 0.0
        self.Offset = 0.0
        self.AirMassFlowRate = 0.0
        self.DesAirMassFlowRate = 0.0
        self.WaterInletTemp = 0.0
        self.WaterOutletTemp = 0.0
        self.WaterInletEnthalpy = 0.0
        self.WaterOutletEnthalpy = 0.0
        self.AirInletTemp = 0.0
        self.AirInletHumRat = 0.0
        self.AirOutletTemp = 0.0
        self.Power = 0.0
        self.Energy = 0.0
        self.plantLoc = PlantLocation(loop: UnsafeMutablePointer[PlantLoop](), branch: 0, comp: 0)
        self.FieldNames = List[String]()
        self.HeatingCapMethod = 0
        self.ScaledHeatingCapacity = 0.0
        self.MySizeFlag = True
        self.CheckEquipName = True
        self.SetLoopIndexFlag = True
        self.MyEnvrnFlag = True

    fn InitBaseboard(inout self, state, baseboard_num: Int) -> None:
        var routine_name: String = "BaseboardRadiator:InitBaseboard"

        if self.SetLoopIndexFlag:
            var err_flag: Bool = False
            import_plant_loop_scan(state, self.EquipID, self.EquipType, self.plantLoc, err_flag)
            if err_flag:
                raise Error("InitBaseboard: Program terminated for previous conditions.")
            self.SetLoopIndexFlag = False

        if not state.dataGlobal.SysSizingCalc and self.MySizeFlag and not self.SetLoopIndexFlag:
            self.SizeBaseboard(state, baseboard_num)
            self.MySizeFlag = False

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and not self.SetLoopIndexFlag:
            var water_inlet_node: Int = self.WaterInletNode
            var rho: Real64 = self.plantLoc.loop[].glycol[].getDensity(state, HWInitConvTemp, routine_name)
            self.WaterMassFlowRateMax = rho * self.WaterVolFlowRateMax
            init_component_nodes(state, 0.0, self.WaterMassFlowRateMax, self.WaterInletNode, self.WaterOutletNode)
            state.dataLoopNodes.Node[water_inlet_node].Temp = HWInitConvTemp
            var cp: Real64 = self.plantLoc.loop[].glycol[].getSpecificHeat(state, state.dataLoopNodes.Node[water_inlet_node].Temp, routine_name)
            state.dataLoopNodes.Node[water_inlet_node].Enthalpy = cp * state.dataLoopNodes.Node[water_inlet_node].Temp
            state.dataLoopNodes.Node[water_inlet_node].Quality = 0.0
            state.dataLoopNodes.Node[water_inlet_node].Press = 0.0
            state.dataLoopNodes.Node[water_inlet_node].HumRat = 0.0
            if self.AirMassFlowRate <= 0.0:
                self.AirMassFlowRate = 2.0 * self.WaterMassFlowRateMax
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        var water_inlet_node: Int = self.WaterInletNode
        var zone_node: Int = state.dataZoneEquip.ZoneEquipConfig[self.ZonePtr].ZoneNode
        self.WaterMassFlowRate = state.dataLoopNodes.Node[water_inlet_node].MassFlowRate
        self.WaterInletTemp = state.dataLoopNodes.Node[water_inlet_node].Temp
        self.WaterInletEnthalpy = state.dataLoopNodes.Node[water_inlet_node].Enthalpy
        self.AirInletTemp = state.dataLoopNodes.Node[zone_node].Temp
        self.AirInletHumRat = state.dataLoopNodes.Node[zone_node].HumRat

    fn SizeBaseboard(inout self, state, baseboard_num: Int) -> None:
        var size_routine: String = cCMO_BBRadiator_Water + ":SizeBaseboard"
        
        var des_coil_load: Real64 = 0.0
        var ua0: Real64 = 0.0
        var ua1: Real64 = 0.0
        var ua: Real64 = 0.0
        var errors_found: Bool = False
        var rho: Real64 = 0.0
        var cp: Real64 = 0.0
        var water_vol_flow_rate_max_des: Real64 = 0.0
        var water_vol_flow_rate_max_user: Real64 = 0.0
        var ua_des: Real64 = 0.0
        var ua_user: Real64 = 0.0
        var temp_size: Real64 = 0.0

        var plt_siz_heat_num: Int = self.plantLoc.loop[].PlantSizNum if self.plantLoc.loop else 0

        if plt_siz_heat_num > 0:
            state.dataSize.DataScalableCapSizingON = False

            if state.dataSize.CurZoneEqNum > 0:
                var flow_auto_size: Bool = self.WaterVolFlowRateMax == AutoSize
                
                if not flow_auto_size and not state.dataSize.ZoneSizingRunDone:
                    if self.WaterVolFlowRateMax > 0.0:
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "User-Specified Maximum Water Flow Rate [m3/s]", self.WaterVolFlowRateMax)
                else:
                    var zone_eq_sizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                    var final_zone_sizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                    var comp_type: String = cCMO_BBRadiator_Water
                    var comp_name: String = self.EquipID
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                    state.dataSize.DataZoneNumber = self.ZonePtr
                    var sizing_method: Int = 1
                    var field_num: Int = 1
                    var sizing_string: String = self.FieldNames[field_num - 1] + " [W]"
                    var cap_sizing_method: Int = self.HeatingCapMethod
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
                        
                        var print_flag: Bool = False
                        var errs_found: Bool = False
                        des_coil_load = heating_capacity_sizer(state, comp_type, comp_name, sizing_string, 
                                                              temp_size, print_flag, size_routine)
                        state.dataSize.DataScalableCapSizingON = False
                    else:
                        des_coil_load = 0.0

                    if des_coil_load >= SmallLoad:
                        cp = self.plantLoc.loop[].glycol[].getSpecificHeat(state, HWInitConvTemp, size_routine)
                        rho = self.plantLoc.loop[].glycol[].getDensity(state, HWInitConvTemp, size_routine)
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
                                    show_extra_warning(state, f"SizeBaseboard: Potential issue with equipment sizing for ZoneHVAC:Baseboard:Convective:Water=\"{self.EquipID}\".", 
                                                     water_vol_flow_rate_max_user, water_vol_flow_rate_max_des)

                var ua_auto_size: Bool = self.UA == AutoSize
                if not ua_auto_size:
                    ua_user = self.UA
                
                if not ua_auto_size and not state.dataSize.ZoneSizingRunDone:
                    if self.UA > 0.0:
                        report_sizer_output(state, cCMO_BBRadiator_Water, self.EquipID,
                                          "User-Specified U-Factor Times Area Value [W/K]", self.UA)
                else:
                    var zone_eq_sizing = state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum]
                    var final_zone_sizing = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum]
                    self.WaterInletTemp = state.dataSize.PlantSizData[plt_siz_heat_num].ExitTemp
                    self.AirInletTemp = final_zone_sizing.ZoneTempAtHeatPeak
                    self.AirInletHumRat = final_zone_sizing.ZoneHumRatAtHeatPeak
                    rho = self.plantLoc.loop[].glycol[].getDensity(state, HWInitConvTemp, size_routine)
                    state.dataLoopNodes.Node[self.WaterInletNode].MassFlowRate = rho * self.WaterVolFlowRateMax

                    var comp_type: String = cCMO_BBRadiator_Water
                    var comp_name: String = self.EquipID
                    state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
                    state.dataSize.DataZoneNumber = self.ZonePtr
                    var sizing_method: Int = 1
                    var field_num: Int = 1
                    var sizing_string: String = self.FieldNames[field_num - 1] + " [W]"
                    var cap_sizing_method: Int = self.HeatingCapMethod
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
                        
                        var print_flag: Bool = False
                        var errs_found: Bool = False
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
                        var load_met: Real64 = 0.0
                        sim_hw_convective(state, baseboard_num, load_met)
                        
                        if load_met < des_coil_load:
                            self.UA = ua1
                            sim_hw_convective(state, baseboard_num, load_met)

                            if load_met > des_coil_load:
                                var sol_fla: Int = 0
                                var ua_final: Real64 = solve_root(Acc, MaxIte, sol_fla, ua0, ua1, 
                                                                 fn(ua_val: Real64) -> Real64:
                                                                     state.dataBaseboardRadiator.baseboards[baseboard_num - 1].UA = ua_val
                                                                     var load_val: Real64 = 0.0
                                                                     sim_hw_convective(state, baseboard_num, load_val)
                                                                     return (des_coil_load - load_val) / des_coil_load
                                )
                                
                                if sol_fla == -1:
                                    show_severe_error(state, f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, "Iteration limit exceeded in calculating coil UA")
                                    if ua_auto_size:
                                        errors_found = True
                                    else:
                                        ua_final = 0.0
                                elif sol_fla == -2:
                                    show_severe_error(state, f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, "Bad starting values for UA")
                                    if ua_auto_size:
                                        errors_found = True
                                    else:
                                        ua_final = 0.0
                                ua_des = ua_final
                            else:
                                ua_des = ua1
                                if ua_auto_size:
                                    show_warning_error(state, f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, f"Design UA set equal to design coil load for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                    show_continue_error(state, f"Design coil load used during sizing = {des_coil_load:.5f} W.")
                                    show_continue_error(state, f"Inlet water temperature used during sizing = {self.WaterInletTemp:.5f} C.")
                        else:
                            ua_des = ua0
                            if ua_auto_size:
                                show_warning_error(state, f"SizeBaseboard: Autosizing of HW baseboard UA failed for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                                show_continue_error(state, f"Design UA set equal to 0.001 * design coil load for {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
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
                                    show_extra_ua_warning(state, f"SizeBaseboard: Potential issue with equipment sizing for ZoneHVAC:Baseboard:Convective:Water=\"{self.EquipID}\".", ua_user, ua_des)
        else:
            if self.WaterVolFlowRateMax == AutoSize or self.UA == AutoSize:
                show_severe_error(state, f"SizeBaseboard: {cCMO_BBRadiator_Water}=\"{self.EquipID}\"")
                show_continue_error(state, "...Autosizing of hot water baseboard requires a heating loop Sizing:Plant object")
                errors_found = True

        register_plant_comp_design_flow(state, self.WaterInletNode, self.WaterVolFlowRateMax)

        if errors_found:
            raise Error("SizeBaseboard: Preceding sizing errors cause program termination")

    fn checkForZoneSizing(inout self, state) -> None:
        if ((self.UA == AutoSize) or (self.WaterVolFlowRateMax == AutoSize) or
            ((self.HeatingCapMethod == HeatingDesignCapacity) and (self.ScaledHeatingCapacity == AutoSize)) or
            ((self.HeatingCapMethod == FractionOfAutosizedHeatingCapacity) and (self.ScaledHeatingCapacity == AutoSize))):
            check_zone_sizing(state, cCMO_BBRadiator_Water, self.EquipID)

struct BaseboardRadiatorData:
    var getInputFlag: Bool
    var baseboards: List[BaseboardParams]

    fn __init__(inout self):
        self.getInputFlag = True
        self.baseboards = List[BaseboardParams]()

    fn init_constant_state(inout self, state) -> None:
        pass

    fn init_state(inout self, state) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.getInputFlag = True
        self.baseboards = List[BaseboardParams]()

fn SimBaseboard(state, equip_name: String, controlled_zone_num: Int, first_hvac_iteration: Bool, 
                inout power_met: Real64, inout comp_index: Int) -> None:
    if state.dataBaseboardRadiator.getInputFlag:
        GetBaseboardInput(state)
        state.dataBaseboardRadiator.getInputFlag = False

    if comp_index == 0:
        var baseboard_num: Int = find_item_in_list(equip_name, state.dataBaseboardRadiator.baseboards)
        if baseboard_num == -1:
            raise Error(f"SimBaseboard: Unit not found={equip_name}")
        comp_index = baseboard_num + 1

    var comp_idx_1based: Int = comp_index
    assert comp_idx_1based <= len(state.dataBaseboardRadiator.baseboards)
    var this_baseboard = state.dataBaseboardRadiator.baseboards[comp_idx_1based - 1]

    if this_baseboard.CheckEquipName:
        if equip_name != this_baseboard.EquipID:
            raise Error(f"SimBaseboard: Invalid CompIndex passed={comp_idx_1based}, Unit name={equip_name}, "
                       f"stored Unit Name for that index={this_baseboard.EquipID}")
        this_baseboard.CheckEquipName = False

    this_baseboard.InitBaseboard(state, comp_idx_1based)

    var q_zn_req: Real64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[controlled_zone_num].RemainingOutputReqToHeatSP
    var max_water_flow: Real64 = 0.0
    var min_water_flow: Real64 = 0.0
    var dummy_mdot: Real64 = 0.0

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

        power_met = this_baseboard.Power

    UpdateBaseboard(state, comp_idx_1based)
    this_baseboard.Energy = this_baseboard.Power * state.dataHVACGlobal.TimeStepSysSec

fn GetBaseboardInput(state) -> None:
    var c_current_module_object: String = cCMO_BBRadiator_Water

    var num_conv_hw_baseboards: Int = get_num_objects_found(state, c_current_module_object)

    state.dataBaseboardRadiator.baseboards = List[BaseboardParams](num_conv_hw_baseboards)

    if num_conv_hw_baseboards > 0:
        var errors_found: Bool = False

        for bb_num in range(num_conv_hw_baseboards):
            var this_baseboard: BaseboardParams = BaseboardParams()
            state.dataBaseboardRadiator.baseboards[bb_num] = this_baseboard

            var numeric_field_names: List[String] = List[String]()
            numeric_field_names.append("Heating Design Capacity")
            numeric_field_names.append("Heating Design Capacity Per Floor Area")
            numeric_field_names.append("Fraction of Autosized Heating Design Capacity")
            numeric_field_names.append("U-Factor Times Area Value")
            numeric_field_names.append("Maximum Water Flow Rate")
            numeric_field_names.append("Convergence Tolerance")
            this_baseboard.FieldNames = numeric_field_names

            var baseboard_name: String = get_baseboard_name(state, c_current_module_object, bb_num)
            var availability_schedule_name: String = get_field_value(state, c_current_module_object, bb_num, "availability_schedule_name")
            var inlet_node_name: String = get_field_value(state, c_current_module_object, bb_num, "inlet_node_name")
            var outlet_node_name: String = get_field_value(state, c_current_module_object, bb_num, "outlet_node_name")
            var heating_design_capacity_method: String = get_field_value(state, c_current_module_object, bb_num, "heating_design_capacity_method")

            verify_unique_baseboard_name(state, c_current_module_object, baseboard_name, errors_found)

            this_baseboard.EquipID = baseboard_name
            this_baseboard.EquipType = 8
            this_baseboard.Schedule = availability_schedule_name
            
            if not availability_schedule_name:
                this_baseboard.availSched = get_schedule_always_on(state)
            else:
                var sched = get_schedule(state, availability_schedule_name)
                if sched == UnsafeMutablePointer[Schedule]():
                    show_severe_item_not_found(state, "Availability Schedule Name", availability_schedule_name)
                    errors_found = True
                this_baseboard.availSched = sched

            this_baseboard.WaterInletNode = get_only_single_node(state, inlet_node_name, errors_found)
            this_baseboard.WaterOutletNode = get_only_single_node(state, outlet_node_name, errors_found)

            test_comp_set(state, c_current_module_object, baseboard_name, inlet_node_name, outlet_node_name)

            if same_string(heating_design_capacity_method, "HeatingDesignCapacity"):
                this_baseboard.HeatingCapMethod = HeatingDesignCapacity
                var heating_cap: Real64 = get_real_field_value(state, c_current_module_object, bb_num, "heating_design_capacity")
                if heating_cap < 0.0 and heating_cap != AutoSize:
                    show_severe_error(state, f"{c_current_module_object} = {this_baseboard.EquipID}")
                    show_continue_error(state, f"Illegal {numeric_field_names[iHeatDesignCapacityNumericNum - 1]} = {heating_cap:.7f}")
                    errors_found = True
                else:
                    this_baseboard.ScaledHeatingCapacity = heating_cap
            elif same_string(heating_design_capacity_method, "CapacityPerFloorArea"):
                this_baseboard.HeatingCapMethod = CapacityPerFloorArea
                var heating_cap_per_area: Real64 = get_real_field_value(state, c_current_module_object, bb_num, "heating_design_capacity_per_floor_area")
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
                var frac_heating_cap: Real64 = get_real_field_value(state, c_current_module_object, bb_num, "fraction_of_autosized_heating_design_capacity")
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

            this_baseboard.ZonePtr = get_zone_equip_controlled_zone_num(state, 8, this_baseboard.EquipID)
            this_baseboard.checkForZoneSizing(state)

        if errors_found:
            raise Error(f"{RoutineName}Errors found in getting input.  Preceding condition(s) cause termination.")

    for bb_idx in range(len(state.dataBaseboardRadiator.baseboards)):
        var this_bb: BaseboardParams = state.dataBaseboardRadiator.baseboards[bb_idx]
        setup_output_variable(state, "Baseboard Total Heating Energy", this_bb.Energy)
        setup_output_variable(state, "Baseboard Hot Water Energy", this_bb.Energy)
        setup_output_variable(state, "Baseboard Total Heating Rate", this_bb.Power)
        setup_output_variable(state, "Baseboard Hot Water Mass Flow Rate", this_bb.WaterMassFlowRate)
        setup_output_variable(state, "Baseboard Air Mass Flow Rate", this_bb.AirMassFlowRate)
        setup_output_variable(state, "Baseboard Air Inlet Temperature", this_bb.AirInletTemp)
        setup_output_variable(state, "Baseboard Air Outlet Temperature", this_bb.AirOutletTemp)
        setup_output_variable(state, "Baseboard Water Inlet Temperature", this_bb.WaterInletTemp)
        setup_output_variable(state, "Baseboard Water Outlet Temperature", this_bb.WaterOutletTemp)

fn SimHWConvective(state, baseboard_num: Int, inout load_met: Real64) -> None:
    var baseboard: BaseboardParams = state.dataBaseboardRadiator.baseboards[baseboard_num - 1]
    var zone_num: Int = baseboard.ZonePtr

    var q_zn_req: Real64 = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num].RemainingOutputReqToHeatSP
    if baseboard.MySizeFlag:
        q_zn_req = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum].NonAirSysDesHeatLoad

    var water_inlet_temp: Real64 = baseboard.WaterInletTemp
    var air_inlet_temp: Real64 = baseboard.AirInletTemp

    var cp_water: Real64 = baseboard.plantLoc.loop[].glycol[].getSpecificHeat(state, water_inlet_temp, cCMO_BBRadiator_Water + ":SimHWConvective")
    var cp_air: Real64 = psy_cp_air_fn_w(baseboard.AirInletHumRat)

    var air_mass_flow_rate: Real64
    if baseboard.DesAirMassFlowRate > 0.0:
        air_mass_flow_rate = baseboard.DesAirMassFlowRate
    else:
        air_mass_flow_rate = baseboard.AirMassFlowRate
        if air_mass_flow_rate <= 0.0:
            air_mass_flow_rate = 2.0 * baseboard.WaterMassFlowRateMax

    var water_mass_flow_rate: Real64 = state.dataLoopNodes.Node[baseboard.WaterInletNode].MassFlowRate
    var capacitance_air: Real64 = cp_air * air_mass_flow_rate

    if (q_zn_req > SmallLoad and 
        (not state.dataZoneEnergyDemand.CurDeadBandOrSetback[zone_num] or baseboard.MySizeFlag) and
        (baseboard.availSched[].getCurrentVal() > 0 or baseboard.MySizeFlag) and 
        (water_mass_flow_rate > 0.0)):

        var capacitance_water: Real64 = cp_water * water_mass_flow_rate
        var capacitance_max: Real64 = max(capacitance_air, capacitance_water)
        var capacitance_min: Real64 = min(capacitance_air, capacitance_water)
        var capacity_ratio: Real64 = capacitance_min / capacitance_max if capacitance_max > 0 else 0.0
        var ntu: Real64 = baseboard.UA / capacitance_min if capacitance_min > 0 else 0.0

        var aa: Real64 = -capacity_ratio * (ntu ** 0.78)
        var bb: Real64
        if aa < EXP_LowerLimit:
            bb = 0.0
        else:
            bb = math.exp(aa)

        var cc: Real64 = (1.0 / capacity_ratio if capacity_ratio > 0 else 1.0) * (ntu ** 0.22) * (bb - 1.0)
        var effectiveness: Real64
        if cc < EXP_LowerLimit:
            effectiveness = 1.0
        else:
            effectiveness = 1.0 - math.exp(cc)

        var air_outlet_temp: Real64 = air_inlet_temp + effectiveness * capacitance_min * (water_inlet_temp - air_inlet_temp) / capacitance_air
        var water_outlet_temp: Real64 = water_inlet_temp - capacitance_air * (air_outlet_temp - air_inlet_temp) / capacitance_water
        load_met = capacitance_water * (water_inlet_temp - water_outlet_temp)
        baseboard.WaterOutletEnthalpy = baseboard.WaterInletEnthalpy - load_met / water_mass_flow_rate
        baseboard.WaterOutletTemp = water_outlet_temp
        baseboard.AirOutletTemp = air_outlet_temp
        baseboard.Power = load_met
        baseboard.WaterMassFlowRate = water_mass_flow_rate
        baseboard.AirMassFlowRate = air_mass_flow_rate
    else:
        var air_outlet_temp: Real64 = air_inlet_temp
        var water_outlet_temp: Real64 = water_inlet_temp
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

fn sim_hw_convective(state, baseboard_num: Int, inout load_met: Real64) -> None:
    SimHWConvective(state, baseboard_num, load_met)

fn UpdateBaseboard(state, baseboard_num: Int) -> None:
    var baseboard = state.dataBaseboardRadiator
    var water_inlet_node: Int = baseboard.baseboards[baseboard_num - 1].WaterInletNode
    var water_outlet_node: Int = baseboard.baseboards[baseboard_num - 1].WaterOutletNode

    safe_copy_plant_node(state, water_inlet_node, water_outlet_node)
    state.dataLoopNodes.Node[water_outlet_node].Temp = baseboard.baseboards[baseboard_num - 1].WaterOutletTemp
    state.dataLoopNodes.Node[water_outlet_node].Enthalpy = baseboard.baseboards[baseboard_num - 1].WaterOutletEnthalpy

# External function stubs
fn find_item_in_list(item_name: String, item_list: List[BaseboardParams]) -> Int:
    for i in range(len(item_list)):
        if item_list[i].EquipID == item_name:
            return i
    return -1

fn show_fatal_error(state, message: String) -> None:
    raise Error(f"Fatal: {message}")

fn show_severe_error(state, message: String) -> None:
    print(f"Severe: {message}")

fn show_severe_item_not_found(state, field_name: String, value: String) -> None:
    print(f"Severe: {field_name} not found: {value}")

fn show_warning_error(state, message: String) -> None:
    print(f"Warning: {message}")

fn show_message(state, message: String) -> None:
    print(f"Message: {message}")

fn show_continue_error(state, message: String) -> None:
    print(f"  {message}")

fn show_extra_warning(state, msg: String, user_val: Real64, des_val: Real64) -> None:
    print(f"{msg}")
    print(f"  User value: {user_val}")
    print(f"  Design value: {des_val}")

fn show_extra_ua_warning(state, msg: String, user_ua: Real64, des_ua: Real64) -> None:
    print(f"{msg}")
    print(f"  User UA: {user_ua:.2f} [W/K]")
    print(f"  Design UA: {des_ua:.2f} [W/K]")

fn set_actuated_branch_flow_rate(state, mdot: Real64, node: Int, ploc: PlantLocation, execute: Bool) -> None:
    pass

fn import_plant_loop_scan(state, equip_id: String, equip_type: Int, inout plant_loc: PlantLocation, inout err_flag: Bool) -> None:
    pass

fn init_component_nodes(state, min_mdot: Real64, max_mdot: Real64, inlet_node: Int, outlet_node: Int) -> None:
    pass

fn report_sizer_output(state, comp_type: String, comp_name: String, *args) -> None:
    pass

fn heating_capacity_sizer(state, comp_type: String, comp_name: String, sizing_string: String, temp_size: Real64, 
                         print_flag: Bool, routine_name: String) -> Real64:
    return 0.0

fn safe_copy_plant_node(state, inlet_node: Int, outlet_node: Int) -> None:
    pass

fn register_plant_comp_design_flow(state, node: Int, flow: Real64) -> None:
    pass

fn check_zone_sizing(state, obj_type: String, obj_name: String) -> None:
    pass

fn control_comp_output(state, equip_id: String, equip_type: String, comp_idx: Int, first_hvac: Bool, 
                      q_required: Real64, inlet_node: Int, max_flow: Real64, min_flow: Real64, 
                      offset: Real64, control_type: Int, err_index: Int, plant_loc: PlantLocation) -> None:
    pass

fn get_num_objects_found(state, obj_type: String) -> Int:
    return 0

fn get_baseboard_name(state, obj_type: String, index: Int) -> String:
    return ""

fn get_field_value(state, obj_type: String, index: Int, field_name: String) -> String:
    return ""

fn get_real_field_value(state, obj_type: String, index: Int, field_name: String) -> Real64:
    return 0.0

fn verify_unique_baseboard_name(state, obj_type: String, name: String, inout err_flag: Bool) -> None:
    pass

fn get_schedule_always_on(state) -> UnsafeMutablePointer[Schedule]:
    return UnsafeMutablePointer[Schedule]()

fn get_schedule(state, sched_name: String) -> UnsafeMutablePointer[Schedule]:
    return UnsafeMutablePointer[Schedule]()

fn get_only_single_node(state, node_name: String, inout err_flag: Bool) -> Int:
    return 0

fn test_comp_set(state, obj_type: String, obj_name: String, inlet_name: String, outlet_name: String) -> None:
    pass

fn same_string(s1: String, s2: String) -> Bool:
    return s1.upper() == s2.upper()

fn get_zone_equip_controlled_zone_num(state, equip_type: Int, equip_name: String) -> Int:
    return 0

fn setup_output_variable(state, var_name: String, inout var_ref: Real64) -> None:
    pass

fn psy_cp_air_fn_w(hum_rat: Real64) -> Real64:
    return 1006.0

fn solve_root(acc: Real64, max_iter: Int, inout sol_fla: Int, ua0: Real64, ua1: Real64, func) -> Real64:
    return (ua0 + ua1) / 2.0
