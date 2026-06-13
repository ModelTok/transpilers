from collections.deque import Deque
from math import min, max

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor: process_input(idd_path, new_idd_path, idf_path), get_object_def_in_idd, get_new_object_def_in_idd, find_item_in_list
# - DataVCompareGlobals: IDFRecords (list of records), NumIDFRecords, Comments, CurComment, FatalError, NumObjectDefs, ObjectDef
# - VCompareGlobalRoutines: same_string, find_item_in_list, write_out_idf_lines, write_out_idf_lines_as_comments, check_special_objects, write_preprocessor_object, scan_output_variables_for_replacement, process_rvi_mvi_files, close_out, create_new_name, copy_file
# - DataStringGlobals: ProgNameConversion, ProgramPath
# - General: make_lower_case, make_upper_case, trim_trail_zeros, same_string, trim, adjustl, make_upper_case
# - DataGlobals: show_message, show_continue_error, show_fatal_error, show_severe_error, show_warning_error

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[String]
    var commt_s: Int
    var commt_e: Int

struct ObjectDef:
    var name: String
    var num_args: Int

struct GlobalState:
    var idf_records: DynamicVector[IDFRecord]
    var num_idf_records: Int
    var comments: DynamicVector[String]
    var cur_comment: Int
    var fatal_error: Bool
    var num_object_defs: Int
    var object_def: DynamicVector[ObjectDef]
    var processing_imf_file: Bool
    var program_path: String
    var prog_name_conversion: String
    var ver_string: String
    var version_num: Float32
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var auditf: Int32
    var full_file_name: String
    var file_name_path: String
    var file_ok: Bool
    var cond_fd_variables: Bool
    var num_chillers: Int
    var num_chiller_heaters: Int
    var making_pretty: Bool
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int

trait ExternalDeps:
    fn process_input(self, old_idd: String, new_idd: String, idf_file: String) -> None: ...
    fn get_object_def_in_idd(self, obj_name: String) -> None: ...
    fn get_new_object_def_in_idd(self, obj_name: String) -> None: ...
    fn find_item_in_list(self, item: String, list_items: DynamicVector[String]) -> Int: ...
    fn same_string(self, s1: String, s2: String) -> Bool: ...
    fn write_out_idf_lines(self, unit: Int32, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]) -> None: ...
    fn write_out_idf_lines_as_comments(self, unit: Int32, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]) -> None: ...
    fn check_special_objects(self, unit: Int32, obj_name: String, cur_args: Int, out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String], written: DynamicVector[Bool]) -> None: ...
    fn write_preprocessor_object(self, unit: Int32, prog_name: String, level: String, msg: String) -> None: ...
    fn process_rvi_mvi_files(self, file_path: String, extension: String) -> None: ...
    fn close_out(self) -> None: ...
    fn create_new_name(self, action: String, output_name: DynamicVector[String], path: String) -> None: ...
    fn copy_file(self, src: String, dst: String, err_flag: DynamicVector[Bool]) -> None: ...
    fn show_warning_error(self, msg: String, unit: Int32) -> None: ...

fn set_this_version_variables(inout state: GlobalState) -> None:
    state.ver_string = 'Conversion 7.2 => 8.0'
    state.version_num = 8.0
    state.idd_file_name_with_path = state.program_path + 'V7-2-0-Energy+.idd'
    state.new_idd_file_name_with_path = state.program_path + 'V8-0-0-Energy+.idd'
    state.rep_var_file_name_with_path = state.program_path + 'Report Variables 7-2-0-006 to 8-0-0.csv'

fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int32,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    deps: ExternalDeps,
    inout state: GlobalState
) -> None:
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int32 = 0
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file:
            var full_file_name: String = ""
            
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # Note: In Mojo, reading from stdin would require external input handling
                # For now, this is a placeholder
            else:
                if not arg_file:
                    # Would read from file unit in_lfn
                    ios = 1
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
            
            # Trim left
            if full_file_name:
                var i: Int = 0
                while i < len(full_file_name) and full_file_name[i] == ' ':
                    i += 1
                if i > 0:
                    full_file_name = full_file_name[i:]
            
            if full_file_name != "":
                deps.write_preprocessor_object(state.auditf, state.prog_name_conversion, "Info", "Processing IDF -- " + full_file_name)
                
                var dot_pos: Int = -1
                for i in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[i] == '.':
                        dot_pos = i
                        break
                
                var file_name_path: String = ""
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:]
                    # Make lowercase
                    var lower_ext: String = ""
                    for c in local_file_extension:
                        if c >= 'A' and c <= 'Z':
                            lower_ext += chr(ord(c) + 32)
                        else:
                            lower_ext += c
                    local_file_extension = lower_ext
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                # Check if file exists
                var file_ok: Bool = False
                try:
                    # File existence check would be platform specific in Mojo
                    file_ok = True
                except:
                    file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    # File handling would go here
                    
                    if local_file_extension == "imf":
                        deps.show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    try:
                        deps.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    except:
                        pass
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        # Close file if open
                        break
                    
                    # Allocate arrays
                    var max_args: Int = state.max_total_args
                    var alphas = DynamicVector[String](state.max_alpha_args_found + 1)
                    var numbers = DynamicVector[String](state.max_numeric_args_found + 1)
                    var in_args = DynamicVector[String](max_args + 1)
                    var aor_n = DynamicVector[Bool](max_args + 1)
                    var req_fld = DynamicVector[Bool](max_args + 1)
                    var fld_names = DynamicVector[String](max_args + 1)
                    var fld_defaults = DynamicVector[String](max_args + 1)
                    var fld_units = DynamicVector[String](max_args + 1)
                    var nw_aor_n = DynamicVector[Bool](max_args + 1)
                    var nw_req_fld = DynamicVector[Bool](max_args + 1)
                    var nw_fld_names = DynamicVector[String](max_args + 1)
                    var nw_fld_defaults = DynamicVector[String](max_args + 1)
                    var nw_fld_units = DynamicVector[String](max_args + 1)
                    var out_args = DynamicVector[String](max_args + 1)
                    var match_arg = DynamicVector[String](max_args + 1)
                    var delete_this_record = DynamicVector[Bool](state.num_idf_records + 1)
                    
                    no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if state.idf_records[num].name.upper() == "VERSION":
                            no_version = False
                            break
                    
                    state.cond_fd_variables = False
                    state.num_chillers = 0
                    state.num_chiller_heaters = 0
                    
                    for num in range(1, state.num_idf_records + 1):
                        var obj_name: String = state.idf_records[num].name
                        
                        if (deps.same_string(obj_name, "Chiller:Electric:EIR") or
                            deps.same_string(obj_name, "Chiller:Electric:ReformulatedEIR") or
                            deps.same_string(obj_name, "Chiller:Electric") or
                            deps.same_string(obj_name, "Chiller:Absorption:Indirect") or
                            deps.same_string(obj_name, "Chiller:Absorption") or
                            deps.same_string(obj_name, "Chiller:ConstantCOP") or
                            deps.same_string(obj_name, "Chiller:EngineDriven") or
                            deps.same_string(obj_name, "Chiller:CombustionTurbine")):
                            state.num_chillers += 1
                        
                        if (deps.same_string(obj_name, "ChillerHeater:Absorption:DirectFired") or
                            deps.same_string(obj_name, "ChillerHeater:Absorption:DoubleEffect")):
                            state.num_chiller_heaters += 1
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            # Write deletion comments
                            pass
                    
                    for num in range(1, state.num_idf_records + 1):
                        if delete_this_record[num]:
                            continue
                        
                        # Process each record
                        var obj_name: String = state.idf_records[num].name
                        var obj_name_upper: String = obj_name.upper()
                        
                        if obj_name_upper == "VERSION":
                            deps.get_new_object_def_in_idd(obj_name)
                            out_args[0] = "8.0"
                        elif obj_name_upper == "SHADOWCALCULATION":
                            deps.get_new_object_def_in_idd(obj_name)
                            out_args[0] = "AverageOverDaysInFrequency"
                        elif obj_name_upper == "COIL:HEATING:DX:MULTISPEED":
                            deps.get_new_object_def_in_idd(obj_name)
                            # Complex field remapping would go here
                        else:
                            deps.get_new_object_def_in_idd(obj_name)
                    
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(file_name_path, "rvi")
                    deps.process_rvi_mvi_files(file_name_path, "mvi")
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
