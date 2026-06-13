from typing import Literal
from utils.string import String

# EXTERNAL DEPS (to wire in glue):
# - InputProcessor.ProcessInput (void, sets global IDF records)
# - VCompareGlobalRoutines.DisplayString, GetNewUnitNumber, GetObjectDefInIDD, GetNewObjectDefInIDD,
#   FindItemInList, WriteOutIDFLines, WriteOutIDFLinesAsComments, ScanOutputVariablesForReplacement,
#   CheckSpecialObjects, writePreprocessorObject, CreateNewName, ProcessRviMviFiles, CloseOut, GetNumSectionsFound
# - General.copyfile, TrimTrailZeros, MakeLowerCase
# - DataGlobals.ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - DataStringGlobals: VerString, VersionNum, sVersionNum, sVersionNumFourChars, IDDFileNameWithPath,
#   NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath, MaxNameLength, blank, Auditf,
#   FullFileName, FileNamePath, IDFRecords, NumIDFRecords, Comments, CurComment,
#   MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs, ProcessingIMFFile,
#   Alphas, Numbers, InArgs, TempArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits,
#   NwAorN, NwReqFld, NwFldNames, NwFldDefaults, NwFldUnits,
#   ObjectDef, NumObjectDefs, OldRepVarName, NumRepVarNames, NewRepVarName, NewRepVarCaution,
#   CMtrVarCaution, OTMVarCaution, CMtrDVarCaution, NotInNew, MakingPretty, FatalError
# - DataVCompareGlobals.OutArgs, NwNumArgs, NwObjMinFlds, ObjMinFlds, NumAlphas, NumNumbers

@dataclass
struct IDFRecord:
    var name: String
    var alphas: List[String]
    var numbers: List[Float64]
    var num_alphas: Int
    var num_numbers: Int
    var commt_s: Int
    var commt_e: Int

@dataclass
struct ObjectDef:
    var name: String

trait DataStringGlobalsTrait:
    fn get_ver_string(inout self) -> String: ...
    fn set_ver_string(inout self, val: String) -> None: ...
    fn get_version_num(inout self) -> Float64: ...
    fn set_version_num(inout self, val: Float64) -> None: ...
    fn get_s_version_num(inout self) -> String: ...
    fn set_s_version_num(inout self, val: String) -> None: ...
    fn get_s_version_num_four_chars(inout self) -> String: ...
    fn set_s_version_num_four_chars(inout self, val: String) -> None: ...
    fn get_idd_file_name_with_path(inout self) -> String: ...
    fn set_idd_file_name_with_path(inout self, val: String) -> None: ...
    fn get_new_idd_file_name_with_path(inout self) -> String: ...
    fn set_new_idd_file_name_with_path(inout self, val: String) -> None: ...
    fn get_rep_var_file_name_with_path(inout self) -> String: ...
    fn set_rep_var_file_name_with_path(inout self, val: String) -> None: ...
    fn get_program_path(inout self) -> String: ...
    fn get_full_file_name(inout self) -> String: ...
    fn set_full_file_name(inout self, val: String) -> None: ...
    fn get_file_name_path(inout self) -> String: ...
    fn set_file_name_path(inout self, val: String) -> None: ...
    fn get_idf_records(inout self) -> List[IDFRecord]: ...
    fn get_num_idf_records(inout self) -> Int: ...
    fn get_out_args(inout self) -> List[String]: ...
    fn get_in_args(inout self) -> List[String]: ...
    fn get_max_total_args(inout self) -> Int: ...
    fn get_blank(inout self) -> String: ...

trait DataGlobalsTrait:
    fn show_warning_error(inout self, msg: String, auditf: Int = -1) -> None: ...

trait VCompareRoutinesTrait:
    fn display_string(inout self, msg: String) -> None: ...
    fn get_new_unit_number(inout self) -> Int: ...
    fn process_input(inout self, idd: String, new_idd: String, idf: String) -> None: ...
    fn get_object_def_in_idd(inout self, name: String) -> None: ...
    fn get_new_object_def_in_idd(inout self, name: String) -> None: ...
    fn find_item_in_list(inout self, name: String, lst: List[String]) -> Int: ...
    fn write_out_idf_lines_as_comments(inout self, unit: Int, name: String, num_args: Int,
                                       args: List[String], fnames: List[String], fun: List[String]) -> None: ...
    fn write_out_idf_lines(inout self, unit: Int, name: String, num_args: Int,
                           args: List[String], fnames: List[String], fun: List[String]) -> None: ...
    fn scan_output_variables_for_replacement(inout self, field: Int, deltbl: List[Bool],
                                             chkrvi: List[Bool], nodiff: List[Bool],
                                             obj_name: String, unit: Int, outvar: Bool,
                                             mtrvar: Bool, timebinvar: Bool,
                                             curargs: List[Int], writ: List[Bool],
                                             is_sensor: Bool) -> None: ...
    fn check_special_objects(inout self, unit: Int, name: String, num_args: Int,
                             args: List[String], fnames: List[String], fun: List[String],
                             writ: List[Bool]) -> None: ...
    fn write_preprocessor_object(inout self, unit: Int, prog_name: String, msg_type: String, msg: String) -> None: ...
    fn create_new_name(inout self, action: String, outname: List[String], suffix: String) -> None: ...
    fn process_rvi_mvi_files(inout self, path: String, ext: String) -> None: ...
    fn close_out(inout self) -> None: ...
    fn get_num_sections_found(inout self, sect: String) -> Int: ...
    fn copyfile(inout self, src: String, dst: String, errflg: List[Bool]) -> None: ...

trait GeneralTrait:
    fn make_lower_case(inout self, s: String) -> String: ...
    fn make_upper_case(inout self, s: String) -> String: ...
    fn same_string(inout self, s1: String, s2: String) -> Bool: ...
    fn trim_trail_zeros(inout self, s: String) -> String: ...

fn set_this_version_variables(inout dsg: DataStringGlobalsTrait, inout gen: GeneralTrait) -> None:
    dsg.set_ver_string('Conversion 22.1 => 22.2')
    dsg.set_version_num(22.2)
    dsg.set_s_version_num('***')
    dsg.set_s_version_num_four_chars('22.2')
    let prog_path = dsg.get_program_path()
    dsg.set_idd_file_name_with_path(prog_path.strip() + 'V22-1-0-Energy+.idd')
    dsg.set_new_idd_file_name_with_path(prog_path.strip() + 'V22-2-0-Energy+.idd')
    dsg.set_rep_var_file_name_with_path(prog_path.strip() + 'Report Variables 22-1-0 to 22-2-0.csv')

fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout dsg: DataStringGlobalsTrait,
    inout dg: DataGlobalsTrait,
    inout vcr: VCompareRoutinesTrait,
    inout gen: GeneralTrait
) -> None:
    var ios: Int = 0
    var dot_pos: Int = 0
    var status: Int = 0
    var na: Int = 0
    var nn: Int = 0
    var cur_args: Int = 0
    var dif_lfn: Int = 0
    var x_count: Int = 0
    var num: Int = 0
    var arg: Int = 0
    var first_time: Bool = True
    var units_arg: String = ""
    var object_name: String = ""
    var uc_rep_var_name: String = ""
    var uc_comp_rep_var_name: String = ""
    var del_this: Bool = False
    var pos: Int = 0
    var pos2: Int = 0
    var exit_because_bad_file: Bool = False
    var still_working: Bool = True
    var no_diff: Bool = True
    var check_rvi: Bool = False
    var no_version: Bool = True
    var diff_min_fields: Bool = False
    var written: Bool = False
    var var_num: Int = 0
    var cur_var: Int = 0
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var local_file_extension: String = ""
    var wild_match: Bool = False
    var p_out_args = List[String]()
    var conn_comp: Bool = False
    var conn_comp_ctrl: Bool = False
    var file_exist: Bool = False
    var created_output_name: String = ""
    var delete_this_record = List[Bool]()
    var c_out_args: Int = 0
    var units_field: String = ""
    var err_flag: List[Bool] = List[Bool]()
    var i: Int = 0
    var cur_field: Int = 0
    var new_field: Int = 0
    var ka_index: Int = 0
    var search_num: Int = 0
    var alpha_num_i: Int = 0
    var save_number: Float64 = 0.0
    
    var tot_run_periods: Int = 0
    var run_period_num: Int = 0
    var iterate_run_period: Int = 0
    var wwhp_eq_ft_cool_index: Int = 0
    var wwhp_eq_ft_heat_index: Int = 0
    var wahp_eq_ft_cool_index: Int = 0
    var wahp_eq_ft_heat_index: Int = 0
    var current_run_period_names = List[String]()
    var num1: Int = 0
    var surrounding_field1: String = ""
    var surrounding_field2: String = ""
    var matched_surrounding_name: String = ""
    var potential_run_period_name: String = ""
    
    if first_time:
        first_time = False
    
    still_working = True
    arg_file_being_done = False
    latest_version = False
    no_version = True
    local_file_extension = arg_idf_extension
    end_of_file[0] = False
    ios = 0
    
    while still_working:
        exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                dsg.set_full_file_name("")
            else:
                if not arg_file:
                    dsg.set_full_file_name("")
                    ios = 0
                elif not arg_file_being_done:
                    dsg.set_full_file_name(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    dsg.set_full_file_name("")
                    ios = 1
                
                let fname = dsg.get_full_file_name()
                if fname.starts_with('!'):
                    dsg.set_full_file_name("")
                    continue
            
            units_arg = ""
            if ios != 0:
                dsg.set_full_file_name("")
            
            var fname = dsg.get_full_file_name()
            fname = fname.lstrip()
            dsg.set_full_file_name(fname)
            
            if fname != "":
                vcr.display_string("Processing IDF -- " + fname.rstrip())
                
                dot_pos = fname.rfind(".")
                if dot_pos != -1:
                    dsg.set_file_name_path(fname[0:dot_pos])
                    local_file_extension = gen.make_lower_case(fname[dot_pos+1:])
                else:
                    dsg.set_file_name_path(fname)
                    print(" assuming file extension of .idf")
                    dsg.set_full_file_name(fname.rstrip() + ".idf")
                    local_file_extension = "idf"
                
                dif_lfn = vcr.get_new_unit_number()
                
                try:
                    let file = open(fname, "r")
                    file_exist = True
                except:
                    file_exist = False
                
                if not file_exist:
                    print("File not found=" + fname)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    check_rvi = False
                    conn_comp = False
                    conn_comp_ctrl = False
                    
                    var out_file: String
                    if diff_only:
                        out_file = dsg.get_file_name_path() + "." + local_file_extension + "dif"
                    else:
                        out_file = dsg.get_file_name_path() + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        dg.show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.")
                    
                    vcr.process_input(dsg.get_idd_file_name_with_path(), dsg.get_new_idd_file_name_with_path(), fname)
                    
                    var in_args_list = dsg.get_in_args()
                    var out_args_list = dsg.get_out_args()
                    var max_total = dsg.get_max_total_args()
                    var blank_str = dsg.get_blank()
                    
                    delete_this_record.resize(dsg.get_num_idf_records())
                    for i in range(delete_this_record.size):
                        delete_this_record[i] = False
                    
                    no_version = True
                    let idf_records = dsg.get_idf_records()
                    for num_check in range(idf_records.size):
                        if gen.make_upper_case(idf_records[num_check].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    vcr.display_string("Processing IDF -- Processing idf objects . . .")
                    
                    for num in range(idf_records.size):
                        if delete_this_record[num]:
                            continue
                        
                        let cur_rec = idf_records[num]
                        object_name = cur_rec.name
                        
                        if no_version and num == 0:
                            out_args_list[0] = dsg.get_s_version_num_four_chars()
                            cur_args = 1
                            dg.show_warning_error("No version found in file, defaulting to " + dsg.get_s_version_num_four_chars())
                        
                        var obj_upper = gen.make_upper_case(object_name.rstrip())
                        
                        if not dsg.get_making_pretty():
                            if obj_upper == "VERSION":
                                if in_args_list[0][0:4] == dsg.get_s_version_num_four_chars() and arg_file:
                                    dg.show_warning_error("File is already at latest version.  No new diff file made.")
                                    latest_version = True
                                    break
                                out_args_list[0] = dsg.get_s_version_num_four_chars()
                                no_diff = False
                            
                            elif obj_upper == "COIL:COOLING:DX:CURVEFIT:SPEED":
                                no_diff = False
                                for i in range(8):
                                    out_args_list[i] = in_args_list[i]
                                out_args_list[8] = ""
                                for i in range(cur_args - 8):
                                    out_args_list[9 + i] = in_args_list[8 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == "COIL:COOLING:DX:SINGLESPEED":
                                no_diff = False
                                for i in range(7):
                                    out_args_list[i] = in_args_list[i]
                                out_args_list[7] = ""
                                for i in range(cur_args - 7):
                                    out_args_list[8 + i] = in_args_list[7 + i]
                                cur_args = cur_args + 1
                            
                            elif obj_upper == "SPACE":
                                no_diff = False
                                out_args_list[0] = in_args_list[0]
                                out_args_list[1] = in_args_list[1]
                                out_args_list[2] = "autocalculate"
                                out_args_list[3] = "autocalculate"
                                for i in range(cur_args - 2):
                                    out_args_list[4 + i] = in_args_list[2 + i]
                                cur_args = cur_args + 2
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
