# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object containing data modules
# Node.GetOnlySingleNode: from EnergyPlus.NodeInputManager
# DataZoneEquipment.AirLoopHVACZone: enum from EnergyPlus.DataZoneEquipment
# DataZoneEquipment.AirLoopHVACTypeNamesCC: lookup from EnergyPlus.DataZoneEquipment
# Node enums: ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsParent
# Util functions: SameString, ValidateComponent, ShowContinueError, ShowSevereError, ShowFatalError
# getEnumValue: from EnergyPlus.GeneralRoutines
# MixerComponent.SimAirMixer: from EnergyPlus.MixerComponent
# ZonePlenum.SimAirZonePlenum: from EnergyPlus.ZonePlenum
# DuctLoss.SimulateDuctLoss, DuctLoss.AirPath: from EnergyPlus.DuctLoss
# nint: round-half-away-from-zero function

from math import floor

fn nint(x: Float64) -> Int:
    """Round to nearest integer, half away from zero"""
    if x >= 0.0:
        return Int(floor(x + 0.5))
    else:
        return Int(floor(x - 0.5))

struct ReturnAirPathData:
    """Data structure for return air path"""
    var name: String
    var num_of_components: Int
    var outlet_node_num: Int
    var component_type: List[String]
    var component_type_enum: List[Int]
    var component_name: List[String]
    var component_index: List[Int]
    
    fn __init__(inout self):
        self.name = ""
        self.num_of_components = 0
        self.outlet_node_num = 0
        self.component_type = List[String]()
        self.component_type_enum = List[Int]()
        self.component_name = List[String]()
        self.component_index = List[Int]()

struct ReturnAirPathMgr:
    """Manager for return air path state"""
    var get_input_flag: Bool
    
    fn __init__(inout self):
        self.get_input_flag = True
    
    fn init_constant_state(self, borrowed state: AnyType):
        pass
    
    fn init_state(self, borrowed state: AnyType):
        pass
    
    fn clear_state(inout self):
        self.get_input_flag = True

@export
fn sim_return_air_path(borrowed state: AnyType):
    """Simulate return air path"""
    if state.dataRetAirPathMrg.get_input_flag:
        get_return_air_path_input(state)
        state.dataRetAirPathMrg.get_input_flag = False
    
    for return_air_path_num in range(state.dataZoneEquip.num_return_air_paths):
        calc_return_air_path(state, return_air_path_num)

@export
fn get_return_air_path_input(borrowed state: AnyType):
    """Get return air path input"""
    var errors_found = False
    
    if state.dataZoneEquip.return_air_path is not None:
        return
    
    var c_current_module_object = "AirLoopHVAC:ReturnPath"
    state.dataIPShortCut.c_current_module_object = c_current_module_object
    state.dataZoneEquip.num_return_air_paths = state.dataInputProcessing.inputProcessor.get_num_objects_found(
        state, c_current_module_object
    )
    
    if state.dataZoneEquip.num_return_air_paths > 0:
        state.dataZoneEquip.return_air_path = List[ReturnAirPathData](state.dataZoneEquip.num_return_air_paths)
        
        for path_num in range(state.dataZoneEquip.num_return_air_paths):
            var num_alphas: Int = 0
            var num_nums: Int = 0
            var io_stat: Int = 0
            
            state.dataInputProcessing.inputProcessor.get_object_item(
                state,
                c_current_module_object,
                path_num,
                state.dataIPShortCut.c_alpha_args,
                num_alphas,
                state.dataIPShortCut.r_numeric_args,
                num_nums,
                io_stat
            )
            
            var ret_path = ReturnAirPathData()
            ret_path.name = state.dataIPShortCut.c_alpha_args[0]
            ret_path.num_of_components = nint((Float64(num_alphas) - 2.0) / 2.0)
            
            ret_path.outlet_node_num = get_only_single_node(
                state,
                state.dataIPShortCut.c_alpha_args[1],
                errors_found,
                ConnectionObjectType.air_loop_hvac_return_path,
                state.dataIPShortCut.c_alpha_args[0],
                FluidType.air,
                ConnectionType.outlet,
                CompFluidStream.primary,
                ObjectIsParent()
            )
            
            var num_comps = ret_path.num_of_components
            ret_path.component_type = List[String](num_comps)
            ret_path.component_type_enum = List[Int](num_comps)
            ret_path.component_name = List[String](num_comps)
            ret_path.component_index = List[Int](num_comps)
            
            for i in range(num_comps):
                ret_path.component_type[i] = ""
                ret_path.component_type_enum[i] = AirLoopHVACZone.invalid
                ret_path.component_name[i] = ""
                ret_path.component_index[i] = 0
            
            var counter = 2
            
            for comp_num in range(num_comps):
                if (same_string(state.dataIPShortCut.c_alpha_args[counter], "AirLoopHVAC:ZoneMixer") or
                    same_string(state.dataIPShortCut.c_alpha_args[counter], "AirLoopHVAC:ReturnPlenum")):
                    
                    var is_not_ok = False
                    ret_path.component_type[comp_num] = state.dataIPShortCut.c_alpha_args[counter]
                    ret_path.component_name[comp_num] = state.dataIPShortCut.c_alpha_args[counter + 1]
                    
                    validate_component(
                        state,
                        ret_path.component_type[comp_num],
                        ret_path.component_name[comp_num],
                        is_not_ok,
                        "AirLoopHVAC:ReturnPath"
                    )
                    
                    if is_not_ok:
                        show_continue_error(state, "In AirLoopHVAC:ReturnPath =" + ret_path.name)
                        errors_found = True
                    
                    ret_path.component_type_enum[comp_num] = get_enum_value(
                        AirLoopHVACTypeNamesCC(),
                        state.dataIPShortCut.c_alpha_args[counter]
                    )
                
                else:
                    show_severe_error(state, "Unhandled component type in AirLoopHVAC:ReturnPath of " + state.dataIPShortCut.c_alpha_args[counter])
                    show_continue_error(state, "Occurs in AirLoopHVAC:ReturnPath = " + ret_path.name)
                    show_continue_error(state, "Must be \"AirLoopHVAC:ZoneMixer\" or \"AirLoopHVAC:ReturnPlenum\"")
                    errors_found = True
                
                counter += 2
            
            state.dataZoneEquip.return_air_path[path_num] = ret_path
    
    if errors_found:
        show_fatal_error(state, "Errors found getting AirLoopHVAC:ReturnPath.  Preceding condition(s) causes termination.")

@export
fn calc_return_air_path(borrowed state: AnyType, return_air_path_num: Int):
    """Calculate return air path"""
    
    var ret_path = state.dataZoneEquip.return_air_path[return_air_path_num]
    
    for component_num in range(ret_path.num_of_components):
        var component_type_enum = ret_path.component_type_enum[component_num]
        
        if component_type_enum == AirLoopHVACZone.mixer:
            if not (state.afn.airflow_network_fan_activated and state.afn.distribution_simulated):
                sim_air_mixer(
                    state,
                    ret_path.component_name[component_num],
                    ret_path.component_index[component_num]
                )
                if state.dataDuctLoss.duct_loss_simu:
                    simulate_duct_loss(
                        state,
                        AirPath.return_,
                        ret_path.component_index[component_num]
                    )
        
        elif component_type_enum == AirLoopHVACZone.return_plenum:
            sim_air_zone_plenum(
                state,
                ret_path.component_name[component_num],
                AirLoopHVACZone.return_plenum,
                ret_path.component_index[component_num]
            )
        
        else:
            show_severe_error(state, "Invalid AirLoopHVAC:ReturnPath Component=" + ret_path.component_type[component_num])
            show_continue_error(state, "Occurs in AirLoopHVAC:ReturnPath =" + ret_path.name)
            show_fatal_error(state, "Preceding condition causes termination.")

@export
fn report_return_air_path(return_air_path_num: Int):
    """Report return air path"""
    pass

fn get_only_single_node(
    borrowed state: AnyType,
    arg1: String,
    borrowed errors_found: Bool,
    arg3: ConnectionObjectType,
    arg4: String,
    arg5: FluidType,
    arg6: ConnectionType,
    arg7: CompFluidStream,
    arg8: ObjectIsParent
) -> Int:
    """External function stub"""
    return 0

fn same_string(a: String, b: String) -> Bool:
    """External function stub"""
    return False

fn validate_component(
    borrowed state: AnyType,
    a: String,
    b: String,
    borrowed is_not_ok: Bool,
    d: String
):
    """External function stub"""
    pass

fn show_continue_error(borrowed state: AnyType, msg: String):
    """External function stub"""
    pass

fn show_severe_error(borrowed state: AnyType, msg: String):
    """External function stub"""
    pass

fn show_fatal_error(borrowed state: AnyType, msg: String):
    """External function stub"""
    pass

fn get_enum_value(borrowed names: AnyType, value: String) -> Int:
    """External function stub"""
    return 0

fn sim_air_mixer(borrowed state: AnyType, name: String, index: Int):
    """External function stub"""
    pass

fn sim_air_zone_plenum(borrowed state: AnyType, name: String, type_enum: Int, index: Int):
    """External function stub"""
    pass

fn simulate_duct_loss(borrowed state: AnyType, path_type: Int, index: Int):
    """External function stub"""
    pass

struct ConnectionObjectType:
    var air_loop_hvac_return_path: String = "AirLoopHVAC:ReturnPath"

struct FluidType:
    var air: String = "Air"

struct ConnectionType:
    var outlet: String = "Outlet"

struct CompFluidStream:
    var primary: String = "Primary"

struct ObjectIsParent:
    pass

struct AirLoopHVACZone:
    var invalid: Int = 0
    var mixer: Int = 1
    var return_plenum: Int = 2

struct AirLoopHVACTypeNamesCC:
    pass

struct AirPath:
    var return_: Int = 0
