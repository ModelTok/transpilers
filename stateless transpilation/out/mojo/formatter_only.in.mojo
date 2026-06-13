from memory import DTypePointer, Pointer, memcpy, stack_allocation
from collections import InlineArray
from pathlib import Path
from sys import argc

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: VerString, VersionNum, sVersionNum, sVersionNumFourChars, 
#   IDDFileNameWithPath, NewIDDFileNameWithPath, ProgNameConversion, ProgramPath, 
#   FullFileName, FileNamePath, Auditf, Comments, CurComment, Blank
# - DataVCompareGlobals: various flags/state
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, FindItemInList
# - VCompareGlobalRoutines: CheckSpecialObjects, WriteOutIDFLines, WriteOutIDFLinesAsComments,
#   ProcessRviMviFiles, CreateNewName, CloseOut, DisplayString, GetNumSectionsFound
# - General: MakeUPPERCase, MakeLowerCase, TrimTrailZeros, GetNewUnitNumber, copyfile
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var commt_s: Int
    var commt_e: Int

struct ObjectDefItem:
    var name: String

struct StringGlobals:
    var ver_string: String
    var version_num: Float64
    var s_version_num: String
    var s_version_num_four_chars: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var prog_name_conversion: String
    var program_path: String
    var full_file_name: String
    var file_name_path: String
    var auditf: Int
    var comments: DynamicVector[String]
    var cur_comment: Int
    var blank: String

struct VCompareGlobals:
    var idf_records: DynamicVector[IDFRecord]
    var num_idf_records: Int
    var object_def: DynamicVector[ObjectDefItem]
    var num_object_defs: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var alphas: DynamicVector[String]
    var numbers: DynamicVector[Float64]
    var in_args: DynamicVector[String]
    var temp_args: DynamicVector[String]
    var aorn: DynamicVector[Bool]
    var req_fld: DynamicVector[Bool]
    var fld_names: DynamicVector[String]
    var fld_defaults: DynamicVector[String]
    var fld_units: DynamicVector[String]
    var nw_aorn: DynamicVector[Bool]
    var nw_req_fld: DynamicVector[Bool]
    var nw_fld_names: DynamicVector[String]
    var nw_fld_defaults: DynamicVector[String]
    var nw_fld_units: DynamicVector[String]
    var out_args: DynamicVector[String]
    var not_in_new: DynamicVector[String]
    var processing_imf_file: Bool
    var fatal_error: Bool
    var file_ok: Bool

struct InputProcessor:
    fn process_input(inout self, idd_path: String, new_idd_path: String, idf_path: String) -> None: ...
    fn get_object_def_in_idd(inout self, obj_name: String) -> Tuple[Int, DynamicVector[Bool], DynamicVector[Bool], Int, DynamicVector[String], DynamicVector[String], DynamicVector[String]]: ...
    fn get_new_object_def_in_idd(inout self, obj_name: String) -> Tuple[Int, DynamicVector[Bool], DynamicVector[Bool], Int, DynamicVector[String], DynamicVector[String], DynamicVector[String]]: ...
    fn find_item_in_list(self, item: String, list_items: DynamicVector[String], size: Int) -> Int: ...

struct VCompareRoutines:
    fn check_special_objects(inout self, lun: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String], 
                            inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String], inout written: Bool) -> None: ...
    fn write_out_idf_lines(inout self, lun: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String],
                          inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String]) -> None: ...
    fn write_out_idf_lines_as_comments(inout self, lun: Int, obj_name: String, cur_args: Int, inout out_args: DynamicVector[String],
                                       inout fld_names: DynamicVector[String], inout fld_units: DynamicVector[String]) -> None: ...
    fn process_rvi_mvi_files(inout self, file_path: String, ext: String) -> None: ...
    fn create_new_name(inout self, cmd: String, inout output_name: String, placeholder: String) -> None: ...
    fn close_out(inout self) -> None: ...
    fn display_string(inout self, msg: String) -> None: ...
    fn get_num_sections_found(self, section: String) -> Int: ...

struct General:
    fn make_upper_case(self, s: String) -> String: ...
    fn make_lower_case(self, s: String) -> String: ...
    fn trim_trail_zeros(self, s: String) -> String: ...
    fn get_new_unit_number(self) -> Int: ...
    fn copyfile(inout self, src: String, dst: String, inout err_flag: Bool) -> None: ...

struct DataGlobals:
    fn show_message(inout self, msg: String) -> None: ...
    fn show_continue_error(inout self, msg: String, lun: Int = -1) -> None: ...
    fn show_fatal_error(inout self, msg: String, lun: Int = -1) -> None: ...
    fn show_severe_error(inout self, msg: String, lun: Int = -1) -> None: ...
    fn show_warning_error(inout self, msg: String, lun: Int = -1) -> None: ...

var _first_time: Bool = True

fn set_this_version_variables(inout string_globals: StringGlobals) -> None:
    string_globals.ver_string = 'Pretty Only @CMAKE_VERSION_MAJOR@.@CMAKE_VERSION_MINOR@'
    string_globals.version_num = 0.0
    string_globals.s_version_num = '***'
    string_globals.s_version_num_four_chars = '@CMAKE_VERSION_MAJOR@.@CMAKE_VERSION_MINOR@'
    string_globals.idd_file_name_with_path = string_globals.program_path.strip() + 
        'V@CMAKE_VERSION_MAJOR@-@CMAKE_VERSION_MINOR@-@CMAKE_VERSION_PATCH@-Energy+.idd'
    string_globals.new_idd_file_name_with_path = string_globals.program_path.strip() + 
        'V@CMAKE_VERSION_MAJOR@-@CMAKE_VERSION_MINOR@-@CMAKE_VERSION_PATCH@-Energy+.idd'

fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout string_globals: StringGlobals,
    inout vcompare_globals: VCompareGlobals,
    inout input_processor: InputProcessor,
    inout vcompare_routines: VCompareRoutines,
    inout general: General,
    inout data_globals: DataGlobals,
) -> None:
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    var delete_this_record: DynamicVector[Bool] = DynamicVector[Bool]()
    
    while still_working:
        var exit_because_bad_file: Bool = False
        while not end_of_file:
            var full_file_name: String
            if ask_for_input:
                print('Enter input file name, with path')
                full_file_name = input('-->')
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except:
                        full_file_name = string_globals.blank
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = string_globals.blank
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = string_globals.blank
                    continue
            
            var units_arg: String = string_globals.blank
            if ios != 0:
                full_file_name = string_globals.blank
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != string_globals.blank:
                vcompare_routines.display_string('Processing IDF -- ' + full_file_name.strip())
                var f_audit = open(str(string_globals.auditf), 'a')
                f_audit.write(' Processing IDF -- ' + full_file_name.strip() + '\n')
                
                var dot_pos: Int = full_file_name.rfind('.')
                var file_name_path: String
                if dot_pos >= 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = general.make_lower_case(full_file_name[dot_pos+1:])
                else:
                    file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    f_audit.write(' ..assuming file extension of .idf\n')
                    full_file_name = full_file_name.strip() + '.idf'
                    local_file_extension = 'idf'
                
                string_globals.file_name_path = file_name_path
                var dif_lfn: Int = general.get_new_unit_number()
                
                var file_ok: Bool
                try:
                    file_ok = Path(full_file_name).exists()
                except:
                    file_ok = False
                
                if not file_ok:
                    print('File not found=' + full_file_name)
                    f_audit.write('File not found=' + full_file_name + '\n')
                    end_of_file = True
                    exit_because_bad_file = True
                    f_audit.close()
                    break
                
                if local_file_extension == 'idf' or local_file_extension == 'imf':
                    var checkrvi: Bool = False
                    var conn_comp: Bool = False
                    var conn_comp_ctrl: Bool = False
                    
                    var dif_file
                    if diff_only:
                        dif_file = open(file_name_path + '.' + local_file_extension + 'dif', 'w')
                    else:
                        dif_file = open(file_name_path + '.' + local_file_extension + 'new', 'w')
                    
                    if local_file_extension == 'imf':
                        data_globals.show_warning_error(
                            'Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.',
                            string_globals.auditf
                        )
                        vcompare_globals.processing_imf_file = True
                    else:
                        vcompare_globals.processing_imf_file = False
                    
                    input_processor.process_input(
                        string_globals.idd_file_name_with_path,
                        string_globals.new_idd_file_name_with_path,
                        full_file_name
                    )
                    
                    if vcompare_globals.fatal_error:
                        exit_because_bad_file = True
                        f_audit.close()
                        dif_file.close()
                        break
                    
                    delete_this_record = DynamicVector[Bool](vcompare_globals.num_idf_records, False)
                    
                    vcompare_globals.alphas = DynamicVector[String](vcompare_globals.max_alpha_args_found, string_globals.blank)
                    vcompare_globals.numbers = DynamicVector[Float64](vcompare_globals.max_numeric_args_found, 0.0)
                    vcompare_globals.in_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.temp_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.aorn = DynamicVector[Bool](vcompare_globals.max_total_args, False)
                    vcompare_globals.req_fld = DynamicVector[Bool](vcompare_globals.max_total_args, False)
                    vcompare_globals.fld_names = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.fld_defaults = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.fld_units = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.nw_aorn = DynamicVector[Bool](vcompare_globals.max_total_args, False)
                    vcompare_globals.nw_req_fld = DynamicVector[Bool](vcompare_globals.max_total_args, False)
                    vcompare_globals.nw_fld_names = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.nw_fld_defaults = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.nw_fld_units = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    vcompare_globals.out_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                    
                    no_version = True
                    for num in range(vcompare_globals.num_idf_records):
                        if general.make_upper_case(vcompare_globals.idf_records[num].name) != 'VERSION':
                            continue
                        no_version = False
                        break
                    
                    for num in range(vcompare_globals.num_idf_records):
                        if delete_this_record[num]:
                            dif_file.write('! Deleting: ' + vcompare_globals.idf_records[num].name.strip() + 
                                         '="' + vcompare_globals.idf_records[num].alphas[0].strip() + '".\n')
                    
                    vcompare_routines.display_string('Processing IDF -- Processing idf objects . . .')
                    
                    for num in range(vcompare_globals.num_idf_records):
                        if delete_this_record[num]:
                            continue
                        
                        for xcount in range(vcompare_globals.idf_records[num].commt_s,
                                          vcompare_globals.idf_records[num].commt_e + 1):
                            if xcount < len(string_globals.comments):
                                dif_file.write(string_globals.comments[xcount].strip() + '\n')
                                if xcount == vcompare_globals.idf_records[num].commt_e:
                                    dif_file.write('\n')
                        
                        if no_version and num == 0:
                            var nw_num_args: Int
                            var nw_aorn: DynamicVector[Bool]
                            var nw_req_fld: DynamicVector[Bool]
                            var nw_obj_min_flds: Int
                            var nw_fld_names: DynamicVector[String]
                            var nw_fld_defaults: DynamicVector[String]
                            var nw_fld_units: DynamicVector[String]
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.get_new_object_def_in_idd('VERSION')
                            var out_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            out_args[0] = string_globals.s_version_num_four_chars
                            var cur_args: Int = 1
                            data_globals.show_warning_error(
                                'No version found in file, defaulting to ' + string_globals.s_version_num_four_chars,
                                string_globals.auditf
                            )
                            vcompare_routines.write_out_idf_lines_as_comments(
                                dif_lfn, 'Version', cur_args, out_args, nw_fld_names, nw_fld_units
                            )
                        
                        var object_name: String = vcompare_globals.idf_records[num].name
                        var object_names = DynamicVector[String](vcompare_globals.num_object_defs)
                        for i in range(vcompare_globals.num_object_defs):
                            object_names[i] = vcompare_globals.object_def[i].name
                        
                        if input_processor.find_item_in_list(object_name, object_names, vcompare_globals.num_object_defs) != 0:
                            var num_args: Int
                            var aorn: DynamicVector[Bool]
                            var req_fld: DynamicVector[Bool]
                            var obj_min_flds: Int
                            var fld_names: DynamicVector[String]
                            var fld_defaults: DynamicVector[String]
                            var fld_units: DynamicVector[String]
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                input_processor.get_object_def_in_idd(object_name)
                            var num_alphas: Int = vcompare_globals.idf_records[num].num_alphas
                            var num_numbers: Int = vcompare_globals.idf_records[num].num_numbers
                            
                            for i in range(num_alphas):
                                vcompare_globals.alphas[i] = vcompare_globals.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                vcompare_globals.numbers[i] = vcompare_globals.idf_records[num].numbers[i]
                            
                            var cur_args: Int = num_alphas + num_numbers
                            vcompare_globals.in_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            vcompare_globals.out_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            vcompare_globals.temp_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            var na: Int = 0
                            var nn: Int = 0
                            for arg in range(cur_args):
                                if aorn[arg]:
                                    vcompare_globals.in_args[arg] = vcompare_globals.alphas[na]
                                    na += 1
                                else:
                                    vcompare_globals.in_args[arg] = str(vcompare_globals.numbers[nn])
                                    nn += 1
                        else:
                            f_audit.write('Object="' + object_name.strip() + 
                                        '" does not seem to be on the "old" IDD.\n')
                            f_audit.write('... will be listed as comments (no field names) on the new output file.\n')
                            f_audit.write('... Alpha fields will be listed first, then numerics.\n')
                            
                            var num_alphas: Int = vcompare_globals.idf_records[num].num_alphas
                            var num_numbers: Int = vcompare_globals.idf_records[num].num_numbers
                            
                            for i in range(num_alphas):
                                vcompare_globals.alphas[i] = vcompare_globals.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                vcompare_globals.numbers[i] = vcompare_globals.idf_records[num].numbers[i]
                            
                            var out_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            for arg in range(num_alphas):
                                out_args[arg] = vcompare_globals.alphas[arg]
                            var nn: Int = num_alphas + 1
                            for arg in range(num_numbers):
                                out_args[nn] = str(vcompare_globals.numbers[arg])
                                nn += 1
                            
                            var cur_args: Int = num_alphas + num_numbers
                            var nw_fld_names = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            var nw_fld_units = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                            vcompare_routines.write_out_idf_lines_as_comments(
                                dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                            )
                            continue
                        
                        var nodiff: Bool = True
                        var diff_min_fields: Bool = False
                        var written: Bool = False
                        
                        if input_processor.find_item_in_list(
                            general.make_upper_case(object_name),
                            vcompare_globals.not_in_new,
                            len(vcompare_globals.not_in_new)
                        ) == 0:
                            var nw_num_args: Int
                            var nw_aorn: DynamicVector[Bool]
                            var nw_req_fld: DynamicVector[Bool]
                            var nw_obj_min_flds: Int
                            var nw_fld_names: DynamicVector[String]
                            var nw_fld_defaults: DynamicVector[String]
                            var nw_fld_units: DynamicVector[String]
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.get_new_object_def_in_idd(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        var nw_num_args: Int
                        var nw_aorn: DynamicVector[Bool]
                        var nw_req_fld: DynamicVector[Bool]
                        var nw_obj_min_flds: Int
                        var nw_fld_names: DynamicVector[String]
                        var nw_fld_defaults: DynamicVector[String]
                        var nw_fld_units: DynamicVector[String]
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            input_processor.get_new_object_def_in_idd(object_name)
                        
                        for i in range(cur_args):
                            vcompare_globals.out_args[i] = vcompare_globals.in_args[i]
                        
                        if diff_min_fields and nodiff:
                            nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                input_processor.get_new_object_def_in_idd(object_name)
                            for i in range(cur_args):
                                vcompare_globals.out_args[i] = vcompare_globals.in_args[i]
                            nodiff = False
                            for arg in range(cur_args, nw_obj_min_flds):
                                vcompare_globals.out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        vcompare_routines.check_special_objects(
                            dif_lfn, object_name, cur_args, vcompare_globals.out_args,
                            nw_fld_names, nw_fld_units, written
                        )
                        
                        if not written:
                            vcompare_routines.write_out_idf_lines(
                                dif_lfn, object_name, cur_args, vcompare_globals.out_args,
                                nw_fld_names, nw_fld_units
                            )
                    
                    vcompare_routines.display_string('Processing IDF -- Processing idf objects complete.')
                    
                    if vcompare_globals.idf_records[vcompare_globals.num_idf_records - 1].commt_e != string_globals.cur_comment:
                        for xcount in range(vcompare_globals.idf_records[vcompare_globals.num_idf_records - 1].commt_e + 1,
                                          string_globals.cur_comment + 1):
                            if xcount < len(string_globals.comments):
                                dif_file.write(string_globals.comments[xcount].strip() + '\n')
                                if xcount == vcompare_globals.idf_records[vcompare_globals.num_idf_records - 1].commt_e:
                                    dif_file.write('\n')
                    
                    if vcompare_routines.get_num_sections_found('Report Variable Dictionary') > 0:
                        object_name = 'Output:VariableDictionary'
                        var nw_num_args: Int
                        var nw_aorn: DynamicVector[Bool]
                        var nw_req_fld: DynamicVector[Bool]
                        var nw_obj_min_flds: Int
                        var nw_fld_names: DynamicVector[String]
                        var nw_fld_defaults: DynamicVector[String]
                        var nw_fld_units: DynamicVector[String]
                        nw_num_args, nw_aorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                            input_processor.get_new_object_def_in_idd(object_name)
                        nodiff = False
                        var out_args = DynamicVector[String](vcompare_globals.max_total_args, string_globals.blank)
                        out_args[0] = 'Regular'
                        cur_args = 1
                        vcompare_routines.write_out_idf_lines(
                            dif_lfn, object_name, cur_args, out_args, nw_fld_names, nw_fld_units
                        )
                    
                    var file_exist: Bool
                    try:
                        file_exist = Path(file_name_path + '.rvi').exists()
                    except:
                        file_exist = False
                    
                    dif_file.close()
                    vcompare_routines.process_rvi_mvi_files(file_name_path, 'rvi')
                    vcompare_routines.process_rvi_mvi_files(file_name_path, 'mvi')
                    vcompare_routines.close_out()
                else:
                    vcompare_routines.process_rvi_mvi_files(file_name_path, 'rvi')
                    vcompare_routines.process_rvi_mvi_files(file_name_path, 'mvi')
                
                f_audit.close()
            else:
                end_of_file = True
            
            var created_output_name: String = ''
            vcompare_routines.create_new_name('Reallocate', created_output_name, ' ')
        
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
        var err_flag: Bool = False
        general.copyfile(
            file_name_path + '.' + arg_idf_extension,
            file_name_path + '.' + arg_idf_extension + 'old',
            err_flag
        )
        general.copyfile(
            file_name_path + '.' + arg_idf_extension + 'new',
            file_name_path + '.' + arg_idf_extension,
            err_flag
        )
        
        var file_exist: Bool
        try:
            file_exist = Path(file_name_path + '.rvi').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.rvi',
                file_name_path + '.rviold',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.rvinew').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.rvinew',
                file_name_path + '.rvi',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.mvi').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.mvi',
                file_name_path + '.mviold',
                err_flag
            )
        
        try:
            file_exist = Path(file_name_path + '.mvinew').exists()
        except:
            file_exist = False
        
        if file_exist:
            general.copyfile(
                file_name_path + '.mvinew',
                file_name_path + '.mvi',
                err_flag
            )
