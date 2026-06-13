# EXTERNAL DEPS (to wire in glue):
# - IDFRecords: vector of IDFRecord from InputProcessor
# - Comments: vector of String from InputProcessor
# - ObjectDef: vector of ObjectDefinition from InputProcessor
# - NumObjectDefs: Int from InputProcessor
# - NumIDFRecords: Int from InputProcessor
# - CurComment: Int from InputProcessor
# - MaxNameLength: Int constant from InputProcessor
# - MaxAlphaArgsFound: Int from InputProcessor
# - MaxNumericArgsFound: Int from InputProcessor
# - MaxTotalArgs: Int from InputProcessor
# - OldRepVarName: vector of String from DataVCompareGlobals
# - NewRepVarName: vector of String from DataVCompareGlobals
# - NewRepVarCaution: vector of String from DataVCompareGlobals
# - NumRepVarNames: Int from DataVCompareGlobals
# - OTMVarCaution, CMtrVarCaution, CMtrDVarCaution: vector of Bool from DataVCompareGlobals
# - NotInNew: vector of String from DataVCompareGlobals
# - ProcessingIMFFile: Bool from DataVCompareGlobals
# - ProgNameConversion: String from DataStringGlobals
# - ProgramPath: String from DataStringGlobals
# - VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath: from SetVersion
# - FatalError: Bool from InputProcessor
# - Blank: String constant
# - All helper functions as external declarations

from math import *

alias MaxNameLength = 100

struct FanData:
    var name: String
    var ftype: String
    
    fn __init__(inout self):
        self.name = ""
        self.ftype = ""

struct NodeListData:
    var name: String
    var node_names: DynamicVector[String]
    var num_nodes: Int
    
    fn __init__(inout self):
        self.name = ""
        self.node_names = DynamicVector[String]()
        self.num_nodes = 0

struct FluidLoop:
    var loop_name: String
    var loop_fluid: String
    var setpoint_node: String
    var is_plant: Bool
    var has_fluid_coolers: Bool
    var num_total_fluids: Int
    var fluid_component_type: DynamicVector[String]
    var fluid_component_name: DynamicVector[String]
    var fluid_change_name: DynamicVector[String]
    var inlet_node: DynamicVector[String]
    var outlet_node: DynamicVector[String]
    
    fn __init__(inout self):
        self.loop_name = " "
        self.loop_fluid = " "
        self.setpoint_node = ""
        self.is_plant = True
        self.has_fluid_coolers = False
        self.num_total_fluids = 0
        self.fluid_component_type = DynamicVector[String]()
        self.fluid_component_name = DynamicVector[String]()
        self.fluid_change_name = DynamicVector[String]()
        self.inlet_node = DynamicVector[String]()
        self.outlet_node = DynamicVector[String]()

struct Component:
    var comp_type: String
    var name: String
    var fluid1: String
    var fluid2: String
    var inlet_node1: String
    var inlet_node2: String
    var outlet_node1: String
    var outlet_node2: String
    
    fn __init__(inout self):
        self.comp_type = " "
        self.name = " "
        self.fluid1 = " "
        self.fluid2 = " "
        self.inlet_node1 = " "
        self.inlet_node2 = " "
        self.outlet_node1 = " "
        self.outlet_node2 = " "

struct SetpointTemperatureManagedNodes:
    var comp_type: String
    var name: String
    var node_num_field: Int
    var node_list_num: Int
    var node_name: String
    var plant_loop_name: String
    
    fn __init__(inout self):
        self.comp_type = " "
        self.name = " "
        self.node_num_field = 0
        self.node_list_num = 0
        self.node_name = " "
        self.plant_loop_name = " "

struct VariableFlowEquipment:
    var comp_type: String
    var comp_name: String
    var outlet_node_name: String
    var plant_loop_name: String
    var sp_name_insert: String
    
    fn __init__(inout self):
        self.comp_type = " "
        self.comp_name = " "
        self.outlet_node_name = " "
        self.plant_loop_name = " "
        self.sp_name_insert = " "

struct ExternalDeps:
    pass

@export
fn set_this_version_variables(deps: ExternalDeps) -> (String, Float64, String, String, String):
    var ver_string: String = "Conversion 6.0 => 7.0"
    var version_num: Float64 = 7.0
    var program_path: String = ""
    var idd_file_name_with_path: String = program_path + "V6-0-0-Energy+.idd"
    var new_idd_file_name_with_path: String = program_path + "V7-0-0-Energy+.idd"
    var rep_var_file_name_with_path: String = program_path + "Report Variables 6-0-0-023 to 7-0-0.csv"
    return ver_string, version_num, idd_file_name_with_path, new_idd_file_name_with_path, rep_var_file_name_with_path

@export
fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    deps: ExternalDeps
) -> Bool:
    
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    var blank: String = ""
    var fmta: String = "(A)"
    var making_pretty: Bool = False
    
    var fans_in_idf: DynamicVector[FanData] = DynamicVector[FanData]()
    var fan_count: Int = 0
    
    var plant_cond_loops: DynamicVector[FluidLoop] = DynamicVector[FluidLoop]()
    var num_plant_cond_loops: Int = 0
    var fluid_component: DynamicVector[Component] = DynamicVector[Component]()
    
    var node_lists: DynamicVector[NodeListData] = DynamicVector[NodeListData]()
    var num_node_lists: Int = 0
    
    var setpoint_managed_nodes: DynamicVector[SetpointTemperatureManagedNodes] = DynamicVector[SetpointTemperatureManagedNodes]()
    var sp_man_count: Int = 0
    var sp_proc_count: Int = 0
    
    var vf_equipment: DynamicVector[VariableFlowEquipment] = DynamicVector[VariableFlowEquipment]()
    var num_vf_equipment: Int = 0
    var num_vf_count: Int = 0
    
    var out_args: DynamicVector[String] = DynamicVector[String]()
    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            var full_file_name: String = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
            else:
                if not arg_file:
                    pass
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
            
            if full_file_name.startswith("!"):
                full_file_name = ""
                continue
            
            var units_arg: String = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = _strip_left(full_file_name)
            
            if full_file_name != "":
                var dot_pos: Int = full_file_name.rfind(".")
                var file_name_path: String = ""
                
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:]
                else:
                    file_name_path = full_file_name
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    if local_file_extension == "imf":
                        pass
                    else:
                        pass
                    
                    var num_node_lists: Int = 0
                    
                    node_lists = DynamicVector[NodeListData]()
                    
                    var num_node_list_count: Int = 0
                    
                    sp_man_count = 0
                    
                    setpoint_managed_nodes = DynamicVector[SetpointTemperatureManagedNodes]()
                    
                    sp_proc_count = 0
                    
                    num_vf_equipment = 0
                    
                    vf_equipment = DynamicVector[VariableFlowEquipment]()
                    num_vf_count = 0
                    
                    num_plant_cond_loops = 0
                    
                    plant_cond_loops = DynamicVector[FluidLoop]()
                    
                    plant_cond_num = 0
                    
                    var do_fluid_scan: Bool = False
                    var num_fluids: Int = 0
                    
                    no_version = True
                    
                    fan_count = 0
                    
                    fans_in_idf = DynamicVector[FanData]()
                    
                    delete_this_record = DynamicVector[Bool]()
                    
                    for num in range(0, 1):
                        var no_diff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        var object_name: String = ""
                        
                        var cur_args: Int = 0
                        var num_alphas: Int = 0
                        var num_numbers: Int = 0
                else:
                    pass
            else:
                end_of_file = True
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
    
    return end_of_file

fn _strip_left(s: String) -> String:
    var i: Int = 0
    while i < len(s) and (s[i] == " " or s[i] == "\t"):
        i += 1
    return s[i:]
