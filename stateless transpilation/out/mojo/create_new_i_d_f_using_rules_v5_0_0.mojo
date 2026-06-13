from memory.unsafe import DTypePointer, Pointer
from sys.intrinsics import llvm_expect

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: Blank, MaxNameLength, MaxNameLengthDiffUnits
# - DataVCompareGlobals: global state (FullFileName, FileNamePath, Auditf, VerString, VersionNum, 
#   IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath,
#   ProcessingIMFFile, FatalError, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   NumIDFRecords, IDFRecords, Comments, CurComment, Blank, OldRepVarName, NewRepVarName,
#   NewRepVarCaution, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, ObjectDef, NumObjectDefs,
#   NumRepVarNames, NotInNew, ProgNameConversion, MakingPretty)
# - InputProcessor: ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, FindItemInList
# - VCompareGlobalRoutines: ScanOutputVariablesForReplacement, CheckSpecialObjects, ProcessRviMviFiles,
#   WriteOutIDFLinesAsComments, WriteOutIDFLines, GetNumSectionsFound, CloseOut, CreateNewName
# - General: MakeLowerCase, MakeUPPERCase, SameString, ProcessNumber, RoundSigDigits, TrimTrailZeros,
#   GetNewUnitNumber, FindNumber, writePreprocessorObject, copyfile
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError


struct StringView:
    var data: Pointer[Int8]
    var len: Int
    
    fn __init__(inout self, s: StringRef) -> None:
        self.data = s.as_ptr()
        self.len = len(s)


trait ExternalDependencies:
    fn get_full_file_name(self) -> String: ...
    fn set_full_file_name(inout self, s: String): ...
    fn get_file_name_path(self) -> String: ...
    fn set_file_name_path(inout self, s: String): ...
    fn get_auditf(self) -> Int: ...
    fn set_auditf(inout self, v: Int): ...
    fn get_ver_string(self) -> String: ...
    fn set_ver_string(inout self, s: String): ...
    fn get_version_num(self) -> Float64: ...
    fn set_version_num(inout self, v: Float64): ...
    fn get_idd_file_name_with_path(self) -> String: ...
    fn set_idd_file_name_with_path(inout self, s: String): ...
    fn get_new_idd_file_name_with_path(self) -> String: ...
    fn set_new_idd_file_name_with_path(inout self, s: String): ...
    fn get_rep_var_file_name_with_path(self) -> String: ...
    fn set_rep_var_file_name_with_path(inout self, s: String): ...
    fn get_program_path(self) -> String: ...
    fn get_processing_imf_file(self) -> Bool: ...
    fn set_processing_imf_file(inout self, b: Bool): ...
    fn get_fatal_error(self) -> Bool: ...
    fn set_fatal_error(inout self, b: Bool): ...
    fn get_max_alpha_args_found(self) -> Int: ...
    fn get_max_numeric_args_found(self) -> Int: ...
    fn get_max_total_args(self) -> Int: ...
    fn get_num_idf_records(self) -> Int: ...
    fn get_cur_comment(self) -> Int: ...
    fn set_cur_comment(inout self, v: Int): ...
    fn get_blank(self) -> String: ...
    fn get_num_object_defs(self) -> Int: ...
    fn get_num_rep_var_names(self) -> Int: ...
    fn get_prog_name_conversion(self) -> String: ...
    fn get_making_pretty(self) -> Bool: ...
    fn get_idf_records(self, idx: Int) -> DType: ...
    fn get_comments(self, idx: Int) -> String: ...
    fn get_old_rep_var_name(self, idx: Int) -> String: ...
    fn get_new_rep_var_name(self, idx: Int) -> String: ...
    fn get_new_rep_var_caution(self, idx: Int) -> String: ...
    fn get_otm_var_caution(self, idx: Int) -> Bool: ...
    fn set_otm_var_caution(inout self, idx: Int, b: Bool): ...
    fn get_cmtr_var_caution(self, idx: Int) -> Bool: ...
    fn set_cmtr_var_caution(inout self, idx: Int, b: Bool): ...
    fn get_cmtr_d_var_caution(self, idx: Int) -> Bool: ...
    fn set_cmtr_d_var_caution(inout self, idx: Int, b: Bool): ...
    fn get_object_def(self) -> DType: ...
    fn get_not_in_new(self) -> List[String]: ...
    fn display_string(inout self, s: String): ...
    fn get_new_object_def_in_idd(inout self, name: String) -> Tuple[Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]]: ...
    fn get_object_def_in_idd(inout self, name: String) -> Tuple[Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]]: ...
    fn make_upper_case(inout self, s: String) -> String: ...
    fn make_lower_case(inout self, s: String) -> String: ...
    fn write_out_idf_lines_as_comments(inout self, lfn: Int, obj: String, nargs: Int, args: List[String], fnames: List[String], funits: List[String]): ...
    fn write_out_idf_lines(inout self, lfn: Int, obj: String, nargs: Int, args: List[String], fnames: List[String], funits: List[String]): ...
    fn scan_output_variables_for_replacement(inout self, idx: Int, del_this: Bool, check_rvi: Bool, nodiff: Bool, 
                                              obj: String, lfn: Int, is_outvar: Bool, is_mtrvar: Bool, 
                                              is_timebinvar: Bool, nargs: Int, written: Bool, sensor: Bool): ...
    fn check_special_objects(inout self, lfn: Int, obj: String, nargs: Int, args: List[String], fnames: List[String], funits: List[String], written: Bool): ...
    fn process_input(inout self, idd_old: String, idd_new: String, idf: String): ...
    fn create_new_name(inout self, op: String, name: String, ext: String): ...
    fn close_out(inout self): ...
    fn process_rvi_mvi_files(inout self, path: String, ext: String): ...
    fn find_item_in_list(inout self, item: String, lst: List[String], size: Int) -> Int: ...
    fn same_string(inout self, s1: String, s2: String) -> Bool: ...
    fn show_warning_error(inout self, msg: String, lfn: Int): ...
    fn show_severe_error(inout self, msg: String, lfn: Int): ...
    fn show_message(inout self, msg: String): ...
    fn show_continue_error(inout self, msg: String): ...
    fn show_fatal_error(inout self, msg: String): ...
    fn process_number(inout self, s: String, err_flag: Bool) -> Float64: ...
    fn round_sig_digits(inout self, val: Float64, digits: Int) -> String: ...
    fn trim_trail_zeros(inout self, s: String) -> String: ...
    fn get_new_unit_number(inout self) -> Int: ...
    fn find_number(inout self, name: String, lst: List[String]) -> Int: ...
    fn write_preprocessor_object(inout self, lfn: Int, prog: String, severity: String, msg: String): ...
    fn copyfile(inout self, src: String, dst: String, err_flag: Bool): ...
    fn get_num_sections_found(inout self, section: String) -> Int: ...


fn set_this_version_variables(inout deps: ExternalDependencies) -> None:
    """Initialize version variables for conversion from V4.0 to V5.0."""
    deps.set_ver_string('Conversion 4.0 => 5.0')
    deps.set_version_num(5.0)
    var prog_path = deps.get_program_path().strip()
    deps.set_idd_file_name_with_path(prog_path + 'V4-0-0-Energy+.idd')
    deps.set_new_idd_file_name_with_path(prog_path + 'V5-0-0-Energy+.idd')
    deps.set_rep_var_file_name_with_path(prog_path + 'Report Variables 4-0-0-024 to 5-0-0.csv')


fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout deps: ExternalDependencies
) -> Bool:
    """
    Creates new IDFs based on conversion rules specified by developers.
    Processes files and applies transformations from V4.0 to V5.0 format.
    """
    
    var first_time = True
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    
    var fmt_a = "(A)"
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file:
            var full_file_name: String
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                # Read input (simplified for Mojo)
                full_file_name = ""
            else:
                if not arg_file:
                    full_file_name = ""
                    ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = deps.get_blank()
                    ios = 1
                
                if full_file_name and full_file_name[0] == '!':
                    full_file_name = deps.get_blank()
                    continue
            
            var units_arg = deps.get_blank()
            if ios != 0:
                full_file_name = deps.get_blank()
            full_file_name = full_file_name.lstrip()
            deps.set_full_file_name(full_file_name)
            
            if full_file_name != deps.get_blank():
                deps.display_string('Processing IDF -- ' + full_file_name)
                
                var dot_pos = full_file_name.rfind('.')
                var file_name_path: String
                if dot_pos >= 0:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = deps.make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                deps.set_file_name_path(file_name_path)
                var dif_lfn = deps.get_new_unit_number()
                var file_ok = False  # would check os.path.isfile(full_file_name)
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    var check_rvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var output_file: String
                    if diff_only:
                        output_file = file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        output_file = file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        deps.show_warning_error('Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.', deps.get_auditf())
                        deps.set_processing_imf_file(True)
                    else:
                        deps.set_processing_imf_file(False)
                    
                    deps.process_input(deps.get_idd_file_name_with_path(), deps.get_new_idd_file_name_with_path(), full_file_name)
                    
                    if deps.get_fatal_error():
                        exit_because_bad_file = True
                        break
                    
                    # Allocate arrays
                    var alphas = List[String]()
                    var numbers = List[Float64]()
                    var in_args = List[String]()
                    var a_or_n = List[Bool]()
                    var req_fld = List[Bool]()
                    var fld_names = List[String]()
                    var fld_defaults = List[String]()
                    var fld_units = List[String]()
                    var nw_a_or_n = List[Bool]()
                    var nw_req_fld = List[Bool]()
                    var nw_fld_names = List[String]()
                    var nw_fld_defaults = List[String]()
                    var nw_fld_units = List[String]()
                    var out_args = List[String]()
                    var match_arg = List[Bool]()
                    
                    var delete_this_record = List[Bool]()
                    
                    var no_version = True
                    for num in range(1, deps.get_num_idf_records() + 1):
                        # Check if IDFRecords[num] name is 'VERSION'
                        if no_version:
                            break
                    
                    for num in range(1, deps.get_num_idf_records() + 1):
                        if delete_this_record[num]:
                            pass  # Write deletion message
                    
                    for num in range(1, deps.get_num_idf_records() + 1):
                        if delete_this_record[num]:
                            continue
                        
                        if no_version and num == 1:
                            var nw_num_args = 0
                            var nw_obj_min_flds = 0
                            out_args.append('3.2')
                            var cur_args = 1
                            deps.write_out_idf_lines_as_comments(dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        var object_name = ""
                        
                        # Check for deleted objects and skip as needed
                        
                        # Main processing logic for object transformation
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if not deps.get_making_pretty():
                            var obj_upper = deps.make_upper_case(object_name)
                            
                            # Handle VERSION case
                            if obj_upper == 'VERSION':
                                if in_args.size() > 0 and in_args[0][:3] == '5.0' and arg_file:
                                    deps.show_warning_error('File is already at latest version.  No new diff file made.', deps.get_auditf())
                                    latest_version = True
                                    break
                                no_diff = False
                            
                            # Handle other object types with case statements
                            elif obj_upper == 'UTILITYCOST:VARIABLE':
                                no_diff = False
                            elif obj_upper == 'COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                no_diff = False
                                var wto_ahp_recip = False
                                var wto_ahp_rotary = False
                                var wto_ahp_scroll = False
                            elif obj_upper == 'COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION':
                                no_diff = False
                            elif obj_upper == 'REFRIGERATION:SECONDARYSYSTEM':
                                no_diff = False
                            elif obj_upper == 'REFRIGERATION:CASE':
                                no_diff = False
                            elif obj_upper == 'ZONEVENTILATION':
                                object_name = 'ZoneVentilation:DesignFlowRate'
                                no_diff = False
                            elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT':
                                no_diff = False
                            elif obj_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT':
                                no_diff = False
                            elif obj_upper == 'COOLINGTOWER:SINGLESPEED':
                                no_diff = False
                            elif obj_upper == 'COOLINGTOWER:TWOSPEED':
                                no_diff = False
                            elif obj_upper == 'COIL:COOLING:DX:SINGLESPEED':
                                no_diff = False
                            elif obj_upper == 'COIL:COOLING:WATER:DETAILEDGEOMETRY':
                                no_diff = False
                                var err_flag = False
                                var field_a = 0.0
                            elif obj_upper == 'SIZINGPERIOD:DESIGNDAY':
                                no_diff = False
                            elif obj_upper == 'GROUNDHEATEXCHANGER:VERTICAL':
                                no_diff = False
                            elif obj_upper == 'ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW':
                                no_diff = False
                            elif obj_upper == 'WINDOWPROPERTY:SHADINGCONTROL':
                                no_diff = False
                            elif obj_upper == 'OUTPUT:VARIABLE':
                                out_args = in_args
                                no_diff = True
                                if out_args.size() > 0 and out_args[0] == deps.get_blank():
                                    out_args[0] = '*'
                                    no_diff = False
                                var del_this = False
                                deps.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_lfn, True, False, False, out_args.size(), written, False)
                            elif obj_upper in ('OUTPUT:METER', 'OUTPUT:METER:METERFILEONLY', 'OUTPUT:METER:CUMULATIVE', 'OUTPUT:METER:CUMULATIVE:METERFILEONLY'):
                                out_args = in_args
                                no_diff = True
                                var del_this = False
                                deps.scan_output_variables_for_replacement(1, del_this, check_rvi, no_diff, object_name, dif_lfn, False, True, False, out_args.size(), written, False)
                            elif obj_upper == 'OUTPUT:TABLE:TIMEBINS':
                                out_args = in_args
                                no_diff = True
                                if out_args.size() > 0 and out_args[0] == deps.get_blank():
                                    out_args[0] = '*'
                                    no_diff = False
                                var del_this = False
                                deps.scan_output_variables_for_replacement(2, del_this, check_rvi, no_diff, object_name, dif_lfn, False, False, True, out_args.size(), written, False)
                            elif obj_upper == 'ENERGYMANAGEMENTSYSTEM:SENSOR':
                                out_args = in_args
                                no_diff = True
                                var del_this = False
                                deps.scan_output_variables_for_replacement(3, del_this, check_rvi, no_diff, object_name, dif_lfn, False, False, False, out_args.size(), written, True)
                            elif obj_upper == 'OUTPUT:TABLE:MONTHLY':
                                no_diff = True
                                # Complex transformation logic for monthly table
                            elif obj_upper == 'METER:CUSTOM':
                                no_diff = True
                                # Complex transformation logic
                            elif obj_upper == 'METER:CUSTOMDECREMENT':
                                no_diff = True
                                # Complex transformation logic
                            else:
                                # Default case
                                if deps.find_item_in_list(object_name, deps.get_not_in_new(), deps.get_not_in_new().size()) != 0:
                                    deps.write_out_idf_lines_as_comments(dif_lfn, object_name, in_args.size(), in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    out_args = in_args
                                    no_diff = True
                        
                        if no_diff and diff_only:
                            continue
                        
                        if not written:
                            deps.check_special_objects(dif_lfn, object_name, out_args.size(), out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            deps.write_out_idf_lines(dif_lfn, object_name, out_args.size(), out_args, nw_fld_names, nw_fld_units)
                    
                    if deps.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        no_diff = False
                        out_args = List[String]()
                        out_args.append('Regular')
                        deps.write_out_idf_lines(dif_lfn, object_name, 1, out_args, nw_fld_names, nw_fld_units)
                    
                    deps.close_out()
                else:
                    deps.process_rvi_mvi_files(deps.get_file_name_path(), 'rvi')
                    deps.process_rvi_mvi_files(deps.get_file_name_path(), 'mvi')
            else:
                end_of_file = True
            
            var created_output_name = ""
            deps.create_new_name('Reallocate', created_output_name, ' ')
        
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file = False
            else:
                end_of_file = True
                still_working = False
    
    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        var err_flag = False
        deps.copyfile(deps.get_file_name_path() + '.' + arg_idf_extension, deps.get_file_name_path() + '.' + arg_idf_extension + 'old', err_flag)
        deps.copyfile(deps.get_file_name_path() + '.' + arg_idf_extension + 'new', deps.get_file_name_path() + '.' + arg_idf_extension, err_flag)
        var file_exist = False  # would check os.path.isfile
        if file_exist:
            deps.copyfile(deps.get_file_name_path() + '.rvi', deps.get_file_name_path() + '.rviold', err_flag)
        file_exist = False
        if file_exist:
            deps.copyfile(deps.get_file_name_path() + '.rvinew', deps.get_file_name_path() + '.rvi', err_flag)
        file_exist = False
        if file_exist:
            deps.copyfile(deps.get_file_name_path() + '.mvi', deps.get_file_name_path() + '.mviold', err_flag)
        file_exist = False
        if file_exist:
            deps.copyfile(deps.get_file_name_path() + '.mvinew', deps.get_file_name_path() + '.mvi', err_flag)
    
    return end_of_file
