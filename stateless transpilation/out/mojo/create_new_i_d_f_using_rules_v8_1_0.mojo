# EXTERNAL DEPS (to wire in glue):
# From DataStringGlobals: VerString, VersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath, RepVarFileNameWithPath, ProgramPath, ProgNameConversion, blank, MaxNameLength, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs
# From DataVCompareGlobals: FullFileName, FileNamePath, Auditf, IDFRecords, NumIDFRecords, FatalError, ObjectDef, NumObjectDefs, NumAlphas, NumNumbers, Comments, CurComment, MakingPretty, NotInNew, OldRepVarName, NewRepVarName, NewRepVarCaution, NumRepVarNames, OTMVarCaution, CMtrVarCaution, CMtrDVarCaution, ProcessingIMFFile
# From InputProcessor: ProcessInput
# From VCompareGlobalRoutines: GetObjectDefInIDD, GetNewObjectDefInIDD
# From DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# From General: ScanOutputVariablesForReplacement, CheckSpecialObjects, GetNumSectionsFound, ProcessRviMviFiles, CloseOut, CreateNewName, WriteOutIDFLines, WriteOutIDFLinesAsComments, writePreprocessorObject, DisplayString, copyfile
# External functions: GetNewUnitNumber, TrimTrailZeros, FindItemInList, MakeUPPERCase, MakeLowerCase, SameString

struct ExternalState:
    pass

fn set_this_version_variables(state: ExternalState) -> None:
    pass

fn create_new_idf_using_rules(
    end_of_file: Pointer[Bool],
    diff_only: Bool,
    in_lfn: Int32,
    ask_for_input: Bool,
    input_file_name: StringSlice,
    arg_file: Bool,
    arg_idf_extension: StringSlice,
    state: ExternalState,
    get_new_unit_number: Callable[[], Int32],
    trim_trail_zeros: Callable[[StringSlice], String],
    find_item_in_list: Callable[[StringSlice, Pointer[String], Int32], Int32],
    make_uppercase: Callable[[StringSlice], String],
    make_lowercase: Callable[[StringSlice], String],
    same_string: Callable[[StringSlice, StringSlice], Bool],
    scan_output_variables_for_replacement: Callable[[], None],
    get_object_def_in_idd: Callable[[], None],
    get_new_object_def_in_idd: Callable[[], None],
    display_string: Callable[[StringSlice], None],
    write_preprocessor_object: Callable[[], None],
    process_input: Callable[[], None],
    write_out_idf_lines_as_comments: Callable[[], None],
    write_out_idf_lines: Callable[[], None],
    check_special_objects: Callable[[], None],
    get_num_sections_found: Callable[[StringSlice], Int32],
    process_rvi_mvi_files: Callable[[], None],
    close_out: Callable[[], None],
    create_new_name: Callable[[], None],
    copyfile: Callable[[], None],
    show_warning_error: Callable[[], None],
) -> None:
    var first_time: Bool = True
    var still_working: Bool = True
    var arg_file_being_done: Bool = False
    var latest_version: Bool = False
    var no_version: Bool = True
    var local_file_extension: String = ""
    var exit_because_bad_file: Bool = False
    var ios: Int32 = 0
    var dot_pos: Int32 = 0
    var dif_lfn: Int32 = 0
    var cur_args: Int32 = 0
    var num_alphas: Int32 = 0
    var num_numbers: Int32 = 0
    var na: Int32 = 0
    var nn: Int32 = 0
    var checkrvi: Bool = False
    var conn_comp: Bool = False
    var conn_comp_ctrl: Bool = False
    var nodiff: Bool = True
    var diff_min_fields: Bool = False
    var written: Bool = False
    var schedule_type_limits_any_number: Bool = False
    var cycling: Bool = False
    var continuous: Bool = False
    var err_flag: Bool = False

    if first_time:
        first_time = False

    while still_working:
        exit_because_bad_file = False

        while not end_of_file[]:
            var full_file_name: String = ""
            var units_arg: String = ""

            var file_name_path: String = ""

            dot_pos = full_file_name.rfind(".")
            if dot_pos >= 0:
                file_name_path = full_file_name[0:dot_pos]
                local_file_extension = make_lowercase(full_file_name[dot_pos+1:])
            else:
                file_name_path = full_file_name
                full_file_name = full_file_name.rstrip() + ".idf"
                local_file_extension = "idf"

            var file_ok: Bool = False

            if not file_ok:
                end_of_file[] = True
                exit_because_bad_file = True
                break

            if local_file_extension == "idf" or local_file_extension == "imf":
                checkrvi = False
                conn_comp = False
                conn_comp_ctrl = False

                var output_file: String = ""
                if diff_only:
                    output_file = file_name_path + "." + local_file_extension + "dif"
                else:
                    output_file = file_name_path + "." + local_file_extension + "new"

                var dif_f: Pointer[None] = Pointer[None]()

                if local_file_extension == "imf":
                    pass

                var alphas: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var numbers: InlineArray[Float64, 512] = InlineArray[Float64, 512](fill=0.0)
                var in_args: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var out_args: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var aorn: InlineArray[Bool, 512] = InlineArray[Bool, 512](fill=False)
                var req_fld: InlineArray[Bool, 512] = InlineArray[Bool, 512](fill=False)
                var fld_names: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var fld_defaults: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var fld_units: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var nw_aorn: InlineArray[Bool, 512] = InlineArray[Bool, 512](fill=False)
                var nw_req_fld: InlineArray[Bool, 512] = InlineArray[Bool, 512](fill=False)
                var nw_fld_names: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var nw_fld_defaults: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var nw_fld_units: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var match_arg: InlineArray[String, 512] = InlineArray[String, 512](fill="")
                var delete_this_record: InlineArray[Bool, 8192] = InlineArray[Bool, 8192](fill=False)

                no_version = True

                schedule_type_limits_any_number = False

                for num in range(0):
                    if delete_this_record[num]:
                        pass

                for num in range(0):
                    if delete_this_record[num]:
                        continue

                    if no_version and num == 0:
                        pass

                    var object_name: String = ""
                    var nw_num_args: Int32 = 0

                    nodiff = True
                    diff_min_fields = False
                    written = False

                    if diff_min_fields and nodiff:
                        for arg in range(cur_args, 0, -1):
                            out_args[arg] = nw_fld_defaults[arg]

                    if nodiff and diff_only:
                        continue

                    if not written:
                        pass

                    if not written:
                        pass

                process_rvi_mvi_files(file_name_path, "rvi")
                process_rvi_mvi_files(file_name_path, "mvi")
                close_out()
            else:
                process_rvi_mvi_files(file_name_path, "rvi")
                process_rvi_mvi_files(file_name_path, "mvi")

            end_of_file[] = True

            var created_output_name: String = ""
            create_new_name("Reallocate", Pointer[String](), " ")

        if not exit_because_bad_file:
            still_working = False
            break
        else:
            if not arg_file_being_done:
                end_of_file[] = False
            else:
                end_of_file[] = True
                still_working = False

    if arg_file_being_done and not latest_version and not exit_because_bad_file:
        err_flag = False
        copyfile(file_name_path + "." + String(arg_idf_extension), file_name_path + "." + String(arg_idf_extension) + "old", Pointer[Bool](err_flag))
        copyfile(file_name_path + "." + String(arg_idf_extension) + "new", file_name_path + "." + String(arg_idf_extension), Pointer[Bool](err_flag))
