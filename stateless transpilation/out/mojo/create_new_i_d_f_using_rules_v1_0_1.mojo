# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals.VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath
# - DataStringGlobals.Blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# - DataStringGlobals.ProgramPath, Auditf, FileNamePath, FullFileName, FileOK, ProcessingIMFFile
# - DataStringGlobals.Comments, CurComment, NumIDFRecords, IDFRecords
# - DataVCompareGlobals.ObjectDef, NumObjectDefs, NotInNew, FatalError, WithUnits
# - DataVCompareGlobals.MakingPretty, NumRepVarNames, OldRepVarName, NewRepVarName
# - InputProcessor.ProcessInput, GetNewObjectDefInIDD, GetObjectDefInIDD, GetNumObjectsFound, GetObjectItem
# - VCompareGlobalRoutines.ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments, WriteOutIDFLines, CheckSpecialObjects
# - VCompareGlobalRoutines.CloseOut, CreateNewName, ProcessRviMviFiles, copyfile
# - General.MakeUPPERCase, MakeLowerCase, FindItemInList, ProcessNumber, TrimTrailZeros, samestring
# - DataGlobals.ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - DisplayString, GetNewUnitNumber, FindNumber (external functions)

from math import *


struct GlobalState:
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    var program_path: String
    var auditf: Int
    var file_name_path: String
    var full_file_name: String
    var file_ok: Bool
    var processing_imf_file: Bool
    var fatal_error: Bool
    var making_pretty: Bool
    var with_units: Bool
    var num_idf_records: Int
    var num_object_defs: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var not_in_new: InlineArray[String, 64]
    var object_def: InlineArray[String, 256]
    var idf_records: InlineArray[IDFRecord, 512]
    var comments: InlineArray[String, 2048]
    var cur_comment: Int
    var num_rep_var_names: Int
    var old_rep_var_name: InlineArray[String, 256]
    var new_rep_var_name: InlineArray[String, 256]


struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: InlineArray[String, 64]
    var numbers: InlineArray[Float64, 64]
    var commt_s: Int
    var commt_e: Int


fn set_this_version_variables(inout state: GlobalState) -> None:
    state.ver_string = "Conversion 1.0 => 1.0.1"
    state.version_num = 1.0
    state.idd_file_name_with_path = state.program_path + "V1-0-0-Energy+.idd"
    state.new_idd_file_name_with_path = state.program_path + "V1-0-1-Energy+.idd"
    state.rep_var_file_name_with_path = state.program_path + "Report Variables 1-0-0-023 to 1-0-1.csv"


fn trim_string(s: String) -> String:
    var start = 0
    var end = len(s)
    while start < end and s[start] == ' ':
        start += 1
    while end > start and s[end - 1] == ' ':
        end -= 1
    return s[start:end]


fn scan_backward(s: String, c: String) -> Int:
    for i in range(len(s) - 1, -1, -1):
        if s[i:i+1] == c:
            return i
    return -1


fn create_new_idf_using_rules(
    inout state: GlobalState,
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String
) -> Bool:
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0
    
    while still_working:
        var exit_because_bad_file = False
        
        while not end_of_file:
            var full_file_name: String
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                full_file_name = input()
            else:
                if not arg_file:
                    try:
                        full_file_name = state.read_line_from_unit(in_lfn)
                        ios = 0
                    except:
                        full_file_name = ""
                        ios = 1
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0:1] == "!":
                    full_file_name = ""
                    continue
            
            var units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            full_file_name = trim_string(full_file_name)
            
            if len(full_file_name) > 0:
                state.display_string("Processing IDF -- " + full_file_name)
                state.write_audit(" Processing IDF -- " + full_file_name)
                
                var dot_pos = scan_backward(full_file_name, ".")
                var file_name_path: String
                if dot_pos > 0:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = full_file_name[dot_pos + 1:].lower()
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    state.write_audit(" ..assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn = state.get_new_unit_number()
                var file_ok = state.file_exists(full_file_name)
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    state.write_audit("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    
                    var output_file: String
                    if diff_only:
                        output_file = file_name_path + "." + local_file_extension + "dif"
                    else:
                        output_file = file_name_path + "." + local_file_extension + "new"
                    
                    var dif_file = state.open_file_for_write(dif_lfn, output_file)
                    
                    if local_file_extension == "imf":
                        state.show_warning_error(
                            "Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.",
                            state.auditf
                        )
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    state.process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path, full_file_name)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var alphas = InlineArray[String, 512](fill="")
                    var numbers = InlineArray[Float64, 256](fill=0.0)
                    var in_args = InlineArray[String, 256](fill="")
                    var a_or_n = InlineArray[Bool, 256](fill=False)
                    var req_fld = InlineArray[Bool, 256](fill=False)
                    var fld_names = InlineArray[String, 256](fill="")
                    var fld_defaults = InlineArray[String, 256](fill="")
                    var fld_units = InlineArray[String, 256](fill="")
                    var nw_a_or_n = InlineArray[Bool, 256](fill=False)
                    var nw_req_fld = InlineArray[Bool, 256](fill=False)
                    var nw_fld_names = InlineArray[String, 256](fill="")
                    var nw_fld_defaults = InlineArray[String, 256](fill="")
                    var nw_fld_units = InlineArray[String, 256](fill="")
                    var out_args = InlineArray[String, 256](fill="")
                    var match_arg = InlineArray[String, 256](fill="")
                    var delete_this_record = InlineArray[Bool, 512](fill=False)
                    
                    var no_version = True
                    for num in range(state.num_idf_records):
                        if state.idf_records[num].name.upper() != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(state.num_idf_records):
                        for xcount in range(state.idf_records[num].commt_s, state.idf_records[num].commt_e + 1):
                            dif_file.write(state.comments[xcount])
                            if xcount == state.idf_records[num].commt_e:
                                dif_file.write(" ")
                        
                        if no_version and num == 0:
                            state.get_new_object_def_in_idd("VERSION", nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            out_args[0] = "1.0.1"
                            var cur_args = 1
                            state.write_out_idf_lines_as_comments(dif_file, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        var object_name = state.idf_records[num].name
                        
                        if state.find_item_in_list(object_name, state.object_def, state.num_object_defs) != 0:
                            state.get_object_def_in_idd(object_name, a_or_n, req_fld, fld_names, fld_defaults, fld_units)
                            var num_alphas = state.idf_records[num].num_alphas
                            var num_numbers = state.idf_records[num].num_numbers
                            for i in range(num_alphas):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.idf_records[num].numbers[i]
                            cur_args = num_alphas + num_numbers
                            in_args = InlineArray[String, 256](fill="")
                            out_args = InlineArray[String, 256](fill="")
                            var na = 0
                            var nn = 0
                            for arg in range(cur_args):
                                if a_or_n[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = String(numbers[nn])
                                    nn += 1
                        else:
                            state.write_audit("Object=\"" + object_name + "\" does not seem to be on the \"old\" IDD.")
                            state.write_audit("... will be listed as comments (no field names) on the new output file.")
                            state.write_audit("... Alpha fields will be listed first, then numerics.")
                            var num_alphas = state.idf_records[num].num_alphas
                            var num_numbers = state.idf_records[num].num_numbers
                            for i in range(num_alphas):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = state.idf_records[num].numbers[i]
                            for arg in range(num_alphas):
                                out_args[arg] = alphas[arg]
                            var nn = num_alphas
                            for arg in range(num_numbers):
                                out_args[nn] = String(numbers[arg])
                                nn += 1
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = InlineArray[String, 256](fill="")
                            nw_fld_units = InlineArray[String, 256](fill="")
                            state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        
                        if state.find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) == 0:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            var obj_min_flds = state.get_obj_min_flds(object_name)
                            var nw_obj_min_flds = state.get_nw_obj_min_flds(object_name)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.making_pretty:
                            var object_name_upper = object_name.upper().strip()
                            
                            if object_name_upper == "VERSION":
                                if len(in_args[0]) >= 3 and in_args[0][0:3] == "1.0.1" and arg_file:
                                    state.show_warning_error("File is already at latest version.  No new diff file made.", state.auditf)
                                    dif_file.close()
                                    latest_version = True
                                    break
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                out_args[0] = "1.0.1"
                                nodiff = False
                            
                            elif object_name_upper == "RUNPERIOD":
                                state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                for i in range(cur_args):
                                    out_args[i] = in_args[i]
                                if out_args[4].upper() == "<BLANK>":
                                    out_args[4] = "UseWeatherFile"
                                nodiff = False
                            
                            else:
                                if state.find_item_in_list(object_name.upper(), state.not_in_new, len(state.not_in_new)) != 0:
                                    state.write_audit("Object=\"" + object_name + "\" is not in the \"new\" IDD.")
                                    state.write_audit("... will be listed as comments on the new output file.")
                                    state.write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                                    for i in range(cur_args):
                                        out_args[i] = in_args[i]
                                    nodiff = True
                        else:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                        
                        if diff_min_fields and nodiff:
                            state.get_new_object_def_in_idd(object_name, nw_a_or_n, nw_req_fld, nw_fld_names, nw_fld_defaults, nw_fld_units)
                            for i in range(cur_args):
                                out_args[i] = in_args[i]
                            nodiff = False
                            var nw_obj_min_flds = state.get_nw_obj_min_flds(object_name)
                            for arg in range(cur_args, nw_obj_min_flds):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            state.check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units, written)
                        
                        if not written:
                            state.write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.idf_records[state.num_idf_records - 1].commt_e != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records - 1].commt_e + 1, state.cur_comment + 1):
                            dif_file.write(state.comments[xcount])
                    
                    dif_file.close()
                    
                    if check_rvi:
                        state.process_rvi_mvi_files(file_name_path, "rvi")
                        state.process_rvi_mvi_files(file_name_path, "mvi")
                    
                    state.close_out()
                else:
                    state.process_rvi_mvi_files(file_name_path, "rvi")
                    state.process_rvi_mvi_files(file_name_path, "mvi")
            else:
                end_of_file = True
            
            state.create_new_name("Reallocate", "", " ")
            break
        
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
        state.copyfile(file_name_path + "." + arg_idf_extension, file_name_path + "." + arg_idf_extension + "old", err_flag)
        state.copyfile(file_name_path + "." + arg_idf_extension + "new", file_name_path + "." + arg_idf_extension, err_flag)
        
        if state.file_exists(file_name_path + ".rvi"):
            state.copyfile(file_name_path + ".rvi", file_name_path + ".rviold", err_flag)
        
        if state.file_exists(file_name_path + ".rvinew"):
            state.copyfile(file_name_path + ".rvinew", file_name_path + ".rvi", err_flag)
        
        if state.file_exists(file_name_path + ".mvi"):
            state.copyfile(file_name_path + ".mvi", file_name_path + ".mviold", err_flag)
        
        if state.file_exists(file_name_path + ".mvinew"):
            state.copyfile(file_name_path + ".mvinew", file_name_path + ".mvi", err_flag)
    
    return end_of_file
