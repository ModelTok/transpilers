from typing import *

# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: ProgNameConversion, MaxNameLength, blank, ProgramPath, Auditf
# - DataVCompareGlobals: IDFRecords, NumIDFRecords, Comments, CurComment, FullFileName, FileNamePath, FileOK, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, ObjectDef, NumObjectDefs, NotInNew, ProcessingIMFFile, FatalError, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - InputProcessor: ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD, GetNumSectionsFound, FindItemInList
# - VCompareGlobalRoutines: ScanOutputVariablesForReplacement, WriteOutIDFLines, WriteOutIDFLinesAsComments, CheckSpecialObjects, ProcessRviMviFiles, CloseOut, CreateNewName, DisplayString, writePreprocessorObject
# - General: SameString, MakeUPPERCase, MakeLowerCase, TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - System: GetNewUnitNumber, copyfile

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[Float64]
    var commt_s: Int
    var commt_e: Int

struct ObjectDefEntry:
    var name: String

struct DataStringGlobalsStub:
    var prog_name_conversion: String
    var max_name_length: Int
    var blank: String
    var program_path: String
    var auditf: Int

struct DataVCompareGlobalsStub:
    var idf_records: List[IDFRecord]
    var num_idf_records: Int
    var comments: List[String]
    var cur_comment: Int
    var full_file_name: String
    var file_name_path: String
    var file_ok: Bool
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var new_rep_var_caution: List[String]
    var num_rep_var_names: Int
    var object_def: List[ObjectDefEntry]
    var num_object_defs: Int
    var not_in_new: List[String]
    var processing_imf_file: Bool
    var fatal_error: Bool
    var otm_var_caution: List[Bool]
    var cmtr_var_caution: List[Bool]
    var cmtr_d_var_caution: List[Bool]
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var ver_string: String
    var version_num: Float64
    var s_version_num: String
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String

fn set_this_version_variables(inout data_string_globals: DataStringGlobalsStub, inout data_vcompare_globals: DataVCompareGlobalsStub) -> None:
    data_vcompare_globals.ver_string = 'Conversion 8.4 => 8.5'
    data_vcompare_globals.version_num = 8.5
    data_vcompare_globals.s_version_num = '8.5'
    var path = data_string_globals.program_path
    if path.endswith(' '):
        path = path.rstrip(' ')
    data_vcompare_globals.idd_file_name_with_path = path + 'V8-4-0-Energy+.idd'
    data_vcompare_globals.new_idd_file_name_with_path = path + 'V8-5-0-Energy+.idd'
    data_vcompare_globals.rep_var_file_name_with_path = path + 'Report Variables 8-4-0 to 8-5-0.csv'

fn create_new_idf_using_rules(
    inout end_of_file: List[Bool],
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout data_string_globals: DataStringGlobalsStub,
    inout data_vcompare_globals: DataVCompareGlobalsStub,
) -> None:
    var fmta = "(A)"
    var first_time = True
    if first_time:
        first_time = False
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension if arg_idf_extension else ' '
    end_of_file[0] = False
    var ios = 0
    
    var max_name_length = data_string_globals.max_name_length
    var max_alpha_args_found = data_vcompare_globals.max_alpha_args_found
    var max_numeric_args_found = data_vcompare_globals.max_numeric_args_found
    var max_total_args = data_vcompare_globals.max_total_args
    var blank_str = data_string_globals.blank
    
    var delete_this_record = List[Bool](capacity=data_vcompare_globals.num_idf_records + 1)
    var alphas = List[String](capacity=max_alpha_args_found + 1)
    var numbers = List[Float64](capacity=max_numeric_args_found + 1)
    var in_args = List[String](capacity=max_total_args + 1)
    var aorn = List[Bool](capacity=max_total_args + 1)
    var req_fld = List[Bool](capacity=max_total_args + 1)
    var fld_names = List[String](capacity=max_total_args + 1)
    var fld_defaults = List[String](capacity=max_total_args + 1)
    var fld_units = List[String](capacity=max_total_args + 1)
    var nwaorn = List[Bool](capacity=max_total_args + 1)
    var nw_req_fld = List[Bool](capacity=max_total_args + 1)
    var nw_fld_names = List[String](capacity=max_total_args + 1)
    var nw_fld_defaults = List[String](capacity=max_total_args + 1)
    var nw_fld_units = List[String](capacity=max_total_args + 1)
    var out_args = List[String](capacity=max_total_args + 1)
    var match_arg = List[Bool](capacity=max_total_args + 1)
    
    for i in range(max_alpha_args_found + 1):
        alphas.append('')
    for i in range(max_numeric_args_found + 1):
        numbers.append(0.0)
    for i in range(max_total_args + 1):
        in_args.append(blank_str)
        aorn.append(False)
        req_fld.append(False)
        fld_names.append('')
        fld_defaults.append('')
        fld_units.append('')
        nwaorn.append(False)
        nw_req_fld.append(False)
        nw_fld_names.append('')
        nw_fld_defaults.append('')
        nw_fld_units.append('')
        out_args.append(blank_str)
        match_arg.append(False)
    for i in range(data_vcompare_globals.num_idf_records + 1):
        delete_this_record.append(False)
    
    while still_working:
        var exit_because_bad_file = False
        while not end_of_file[0]:
            var full_file_name = ""
            if ask_for_input:
                print('Enter input file name, with path')
                print('-->', end='')
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = input()
                        ios = 0
                    except:
                        ios = 1
                        full_file_name = ''
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = blank_str
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == '!':
                    full_file_name = blank_str
                    continue
            
            var units_arg = blank_str
            if ios != 0:
                full_file_name = blank_str
            full_file_name = full_file_name.lstrip()
            
            if full_file_name != blank_str:
                print('Processing IDF -- ' + full_file_name)
                
                var dot_pos = full_file_name.rfind('.')
                if dot_pos >= 0:
                    data_vcompare_globals.file_name_path = full_file_name[:dot_pos]
                    local_file_extension = full_file_name[dot_pos+1:].lower()
                else:
                    data_vcompare_globals.file_name_path = full_file_name
                    print(' assuming file extension of .idf')
                    full_file_name = full_file_name.rstrip() + '.idf'
                    local_file_extension = 'idf'
                
                var dif_lfn = 0
                var file_exists = False
                try:
                    with open(full_file_name, 'r'):
                        data_vcompare_globals.file_ok = True
                        file_exists = True
                except:
                    data_vcompare_globals.file_ok = False
                    file_exists = False
                
                if not data_vcompare_globals.file_ok:
                    print('File not found=' + full_file_name)
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension in ('idf', 'imf'):
                    var check_rvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False
                    
                    var dif_file_path = ""
                    if diff_only:
                        dif_file_path = data_vcompare_globals.file_name_path + '.' + local_file_extension + 'dif'
                    else:
                        dif_file_path = data_vcompare_globals.file_name_path + '.' + local_file_extension + 'new'
                    
                    if local_file_extension == 'imf':
                        data_vcompare_globals.processing_imf_file = True
                    else:
                        data_vcompare_globals.processing_imf_file = False
                    
                    var no_version_found = True
                    for num in range(1, data_vcompare_globals.num_idf_records + 1):
                        if data_vcompare_globals.idf_records[num].name.upper() != 'VERSION':
                            continue
                        no_version_found = False
                        break
                    
                    var schedule_type_limits_any_number = False
                    for num in range(1, data_vcompare_globals.num_idf_records + 1):
                        if data_vcompare_globals.idf_records[num].name.lower() != 'scheduleTypeLimits':
                            continue
                        if len(data_vcompare_globals.idf_records[num].alphas) > 1:
                            if data_vcompare_globals.idf_records[num].alphas[1].lower() == 'any number':
                                schedule_type_limits_any_number = True
                                break
                    
                    for num in range(1, data_vcompare_globals.num_idf_records + 1):
                        if delete_this_record[num]:
                            continue
                    
                    for num in range(1, data_vcompare_globals.num_idf_records + 1):
                        if delete_this_record[num]:
                            continue
                        
                        var no_diff = True
                        var diff_min_fields = False
                        var written = False
                        var object_name = data_vcompare_globals.idf_records[num].name
                        
                        var object_name_upper = object_name.upper()
                        
                        if object_name_upper in ('SKY RADIANCE DISTRIBUTION', 'AIRFLOW MODEL', 'GENERATOR:FC:BATTERY DATA', 'AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS'):
                            continue
                        
                        if object_name_upper == 'WATER HEATER:SIMPLE':
                            continue
                        
                        var num_alphas = data_vcompare_globals.idf_records[num].num_alphas
                        var num_numbers = data_vcompare_globals.idf_records[num].num_numbers
                        var cur_args = num_alphas + num_numbers
                        
                        if object_name_upper == 'VERSION':
                            no_diff = False
                        elif object_name_upper == 'ENERGYMANAGEMENTSYSTEM:ACTUATOR':
                            no_diff = True
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                            var inner_case = in_args[4].upper()
                            if inner_case == 'OUTDOOR AIR DRYBLUB TEMPERATURE':
                                out_args[4] = 'Outdoor Air Drybulb Temperature'
                            elif inner_case == 'OUTDOOR AIR WETBLUB TEMPERATURE':
                                out_args[4] = 'Outdoor Air Wetbulb Temperature'
                        
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT':
                            no_diff = False
                            out_args[1:16] = in_args[1:16]
                            out_args[16] = in_args[17]
                            cur_args = max(cur_args - 1, 13)
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT':
                            no_diff = False
                            out_args[1:17] = in_args[1:17]
                            out_args[17] = in_args[18]
                            cur_args = max(cur_args - 1, 14)
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT':
                            no_diff = False
                            out_args[1:6] = in_args[1:6]
                            out_args[6:cur_args] = in_args[7:cur_args+1]
                            cur_args = cur_args - 1
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION':
                            no_diff = False
                            out_args[1:8] = in_args[1:8]
                            out_args[8:cur_args-1] = in_args[10:cur_args+1]
                            cur_args = cur_args - 2
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT':
                            no_diff = False
                            out_args[1:7] = in_args[1:7]
                            out_args[7:cur_args] = in_args[8:cur_args+1]
                            cur_args = cur_args - 1
                        elif object_name_upper == 'AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN':
                            no_diff = False
                            out_args[1:8] = in_args[1:8]
                            out_args[8:cur_args-1] = in_args[10:cur_args+1]
                            cur_args = cur_args - 2
                        elif object_name_upper == 'UNITARYSYSTEMPERFORMANCE:MULTISPEED':
                            no_diff = False
                            out_args[1:4] = in_args[1:4]
                            out_args[4] = 'No'
                            out_args[5:13] = in_args[4:12]
                            cur_args = cur_args + 1
                        else:
                            no_diff = True
                            out_args[1:cur_args+1] = in_args[1:cur_args+1]
                    
                    for xcount in range(data_vcompare_globals.num_idf_records, data_vcompare_globals.cur_comment + 1):
                        pass
    
        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[0] = False
            else:
                end_of_file[0] = True
                still_working = False
