from collections import InlineArray
from memory import memset_zero
import os


# EXTERNAL DEPS (to wire in glue):
# - InputProcessor.process_input(idd_old, idd_new, idf_file)
# - InputProcessor.get_new_object_def_idd(obj_name) -> tuple(num_args, aorn, reqfld, min_flds, names, defaults, units)
# - InputProcessor.get_object_def_idd(obj_name) -> tuple(num_args, aorn, reqfld, min_flds, names, defaults, units)
# - InputProcessor.find_item_in_list(item, list, size) -> int
# - DataVCompareGlobals.idf_records: list of IDFRecord
# - DataVCompareGlobals.comments: list of comment strings
# - DataVCompareGlobals.cur_comment: int
# - DataVCompareGlobals.num_idf_records: int
# - DataVCompareGlobals.fatal_error: bool
# - DataVCompareGlobals.processing_imf_file: bool
# - VCompareGlobalRoutines.scan_output_variables_for_replacement(...)
# - VCompareGlobalRoutines.write_out_idf_lines_as_comments(...)
# - VCompareGlobalRoutines.write_out_idf_lines(...)
# - VCompareGlobalRoutines.check_special_objects(...)
# - VCompareGlobalRoutines.process_rvi_mvi_files(...)
# - VCompareGlobalRoutines.close_out()
# - VCompareGlobalRoutines.create_new_name(...)
# - VCompareGlobalRoutines.write_preprocessor_object(...)
# - VCompareGlobalRoutines.get_num_sections_found(section_name) -> int
# - General.make_upper_case(string) -> string
# - General.make_lower_case(string) -> string
# - General.same_string(s1, s2) -> bool
# - DataStringGlobals.blank: string constant
# - DataStringGlobals.program_path: string
# - DataStringGlobals.prog_name_conversion: string
# - DataGlobals.show_warning_error(msg, auditf)
# - DataGlobals.show_message(msg)
# - DataGlobals.show_continue_error(msg)
# - DataGlobals.show_fatal_error(msg)
# - DataGlobals.show_severe_error(msg)
# - General.get_new_unit_number() -> int
# - DataGlobals.trim(string) -> string
# - copy_file(src, dst) -> bool
# - file_exists(path) -> bool


@value
struct IDFRecord:
    var name: String
    var alphas: List[String]
    var numbers: List[Float64]
    var num_alphas: Int
    var num_numbers: Int
    var commt_s: Int
    var commt_e: Int
    
    fn __init__(inout self):
        self.name = String()
        self.alphas = List[String]()
        self.numbers = List[Float64]()
        self.num_alphas = 0
        self.num_numbers = 0
        self.commt_s = 0
        self.commt_e = 0


@value
struct ObjectDefinition:
    var name: String
    
    fn __init__(inout self):
        self.name = String()


trait ExternalDependencies:
    fn process_input(self, inout deps: Self, inout idd_old: String, inout idd_new: String, inout idf_file: String):
        ...
    fn display_string(self, inout deps: Self, inout msg: String):
        ...
    fn get_new_object_def_idd(self, inout deps: Self, inout obj_name: String):
        ...
    fn get_object_def_idd(self, inout deps: Self, inout obj_name: String):
        ...
    fn find_item_in_list(self, obj_name: String, items: List[String]) -> Int:
        ...
    fn scan_output_variables_for_replacement(
        self, inout deps: Self, field_num: Int, inout del_this: List[Bool],
        inout check_rvi: List[Bool], inout nodiff: List[Bool],
        inout obj_name: String, dif_lfn: Int,
        out_var: Bool, mtr_var: Bool, time_bin_var: Bool,
        cur_args: Int, inout written: List[Bool], sensor: Bool
    ):
        ...
    fn write_out_idf_lines_as_comments(
        self, inout deps: Self, dif_lfn: Int, inout obj_name: String, cur_args: Int,
        inout out_args: List[String], inout fld_names: List[String],
        inout fld_units: List[String]
    ):
        ...
    fn write_out_idf_lines(
        self, inout deps: Self, dif_lfn: Int, inout obj_name: String, cur_args: Int,
        inout out_args: List[String], inout fld_names: List[String],
        inout fld_units: List[String]
    ):
        ...
    fn check_special_objects(
        self, inout deps: Self, dif_lfn: Int, inout obj_name: String, cur_args: Int,
        inout out_args: List[String], inout fld_names: List[String],
        inout fld_units: List[String], inout written: List[Bool]
    ):
        ...
    fn process_rvi_mvi_files(self, inout deps: Self, inout file_name_path: String, inout extension: String):
        ...
    fn close_out(self, inout deps: Self):
        ...
    fn create_new_name(self, inout deps: Self, inout operation: String, inout output_name: List[String], inout filler: String):
        ...
    fn write_preprocessor_object(self, inout deps: Self, dif_lfn: Int, inout prog_name: String, inout msg_type: String, inout msg: String):
        ...
    fn get_num_sections_found(self, inout section_name: String) -> Int:
        ...
    fn make_upper_case(self, inout s: String) -> String:
        ...
    fn make_lower_case(self, inout s: String) -> String:
        ...
    fn same_string(self, inout s1: String, inout s2: String) -> Bool:
        ...
    fn show_warning_error(self, inout msg: String, auditf: Int):
        ...
    fn show_message(self, inout msg: String):
        ...
    fn show_continue_error(self, inout msg: String):
        ...
    fn show_fatal_error(self, inout msg: String):
        ...
    fn show_severe_error(self, inout msg: String):
        ...
    fn get_new_unit_number(self) -> Int:
        ...
    fn trim(self, inout s: String) -> String:
        ...
    fn copy_file(self, inout src: String, inout dst: String) -> Bool:
        ...
    fn file_exists(self, inout path: String) -> Bool:
        ...


fn set_this_version_variables(inout deps: ExternalDependencies):
    """Set version variables for this version transition."""
    var ver_string: String = "Conversion 9.3 => 9.4"
    var version_num: Float64 = 9.4
    var s_version_num: String = "***"
    var s_version_num_four_chars: String = "23.2"


fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    inout input_file_name: String,
    arg_file: Bool,
    inout arg_idf_extension: String,
    inout deps: ExternalDependencies
):
    """Create new IDF using rules specified by developers."""
    
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file[0] = False
    var ios: Int = 0
    
    var blank: String = String()
    var created_output_name: List[String] = List[String]()
    created_output_name.append(String())
    
    var delete_this_record: List[Bool] = List[Bool]()
    
    while still_working:
        var exit_because_bad_file: Bool = False
        
        while not end_of_file[0]:
            var full_file_name: String = String()
            
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
                    full_file_name = blank
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = blank
                    continue
            
            if ios != 0:
                full_file_name = blank
            
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != blank:
                deps.display_string("Processing IDF -- " + deps.trim(full_file_name))
                
                var dot_pos: Int = -1
                for i in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[i] == '.':
                        dot_pos = i
                        break
                
                var file_name_path: String = String()
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = deps.make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = deps.trim(full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn: Int = deps.get_new_unit_number()
                var file_ok: Bool = deps.file_exists(deps.trim(full_file_name))
                
                if not file_ok:
                    print("File not found=" + deps.trim(full_file_name))
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var output_file: String = String()
                    if diff_only:
                        output_file = deps.trim(file_name_path) + "." + deps.trim(local_file_extension) + "dif"
                    else:
                        output_file = deps.trim(file_name_path) + "." + deps.trim(local_file_extension) + "new"
                    
                    if local_file_extension == "imf":
                        deps.show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", 0)
                    else:
                        pass
                    
                    var idd_old: String = deps.trim("") + "V9-3-0-Energy+.idd"
                    var idd_new: String = deps.trim("") + "V9-4-0-Energy+.idd"
                    deps.process_input(idd_old, idd_new, full_file_name)
                    
                    var num_idf_records: Int = 0
                    var num_alpha_args_found: Int = 0
                    var num_numeric_args_found: Int = 0
                    var max_total_args: Int = 0
                    var max_name_length: Int = 0
                    
                    var alphas: List[String] = List[String]()
                    var numbers: List[Float64] = List[Float64]()
                    var in_args: List[String] = List[String]()
                    var temp_args: List[String] = List[String]()
                    var out_args: List[String] = List[String]()
                    var a_or_n: List[Bool] = List[Bool]()
                    var req_fld: List[Bool] = List[Bool]()
                    var fld_names: List[String] = List[String]()
                    var fld_defaults: List[String] = List[String]()
                    var fld_units: List[String] = List[String]()
                    var nw_a_or_n: List[Bool] = List[Bool]()
                    var nw_req_fld: List[Bool] = List[Bool]()
                    var nw_fld_names: List[String] = List[String]()
                    var nw_fld_defaults: List[String] = List[String]()
                    var nw_fld_units: List[String] = List[String]()
                    
                    delete_this_record = List[Bool]()
                    for i in range(num_idf_records + 1):
                        delete_this_record.append(False)
                    
                    var no_version: Bool = True
                    
                    deps.display_string("Processing IDF -- Processing idf objects . . .")
                    
                    var num: Int = 0
                    while num < num_idf_records:
                        if delete_this_record[num]:
                            num += 1
                            continue
                        
                        var obj_name_upper: String = deps.make_upper_case("")
                        
                        if obj_name_upper == "VERSION":
                            if len(in_args) > 0 and in_args[0][:4] == "23.2" and arg_file:
                                deps.show_warning_error("File is already at latest version.  No new diff file made.", 0)
                                latest_version = True
                                break
                            out_args[0] = "23.2"
                        
                        elif obj_name_upper == "OUTPUT:VARIABLE":
                            pass
                        
                        elif obj_name_upper == "OUTPUT:METER":
                            pass
                        
                        elif obj_name_upper == "OUTPUT:TABLE:TIMEBINS":
                            pass
                        
                        elif obj_name_upper == "METER:CUSTOM":
                            pass
                        
                        elif obj_name_upper == "METER:CUSTOMDECREMENT":
                            pass
                        
                        num += 1
                    
                    deps.display_string("Processing IDF -- Processing idf objects complete.")
                    
                    if deps.get_num_sections_found("Report Variable Dictionary") > 0:
                        out_args[0] = "Regular"
                    
                    deps.process_rvi_mvi_files(file_name_path, "rvi")
                    deps.process_rvi_mvi_files(file_name_path, "mvi")
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(file_name_path, "rvi")
                    deps.process_rvi_mvi_files(file_name_path, "mvi")
            
            else:
                end_of_file[0] = True
            
            var temp_name: List[String] = List[String]()
            temp_name.append(String())
            deps.create_new_name("Reallocate", temp_name, " ")
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var file_name_path: String = String()
        deps.copy_file(
            deps.trim(file_name_path) + "." + deps.trim(arg_idf_extension),
            deps.trim(file_name_path) + "." + deps.trim(arg_idf_extension) + "old"
        )
        deps.copy_file(
            deps.trim(file_name_path) + "." + deps.trim(arg_idf_extension) + "new",
            deps.trim(file_name_path) + "." + deps.trim(arg_idf_extension)
        )
        
        if deps.file_exists(deps.trim(file_name_path) + ".rvi"):
            deps.copy_file(
                deps.trim(file_name_path) + ".rvi",
                deps.trim(file_name_path) + ".rviold"
            )
        
        if deps.file_exists(deps.trim(file_name_path) + ".rvinew"):
            deps.copy_file(
                deps.trim(file_name_path) + ".rvinew",
                deps.trim(file_name_path) + ".rvi"
            )
        
        if deps.file_exists(deps.trim(file_name_path) + ".mvi"):
            deps.copy_file(
                deps.trim(file_name_path) + ".mvi",
                deps.trim(file_name_path) + ".mviold"
            )
        
        if deps.file_exists(deps.trim(file_name_path) + ".mvinew"):
            deps.copy_file(
                deps.trim(file_name_path) + ".mvinew",
                deps.trim(file_name_path) + ".mvi"
            )
