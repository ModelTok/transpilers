# EXTERNAL DEPS (to wire in glue):
# - DataStringGlobals: blank, ProgNameConversion
# - DataVCompareGlobals: VersionNum, sVersionNum, IDDFileNameWithPath, NewIDDFileNameWithPath,
#   RepVarFileNameWithPath, ProgramPath, ProcessingIMFFile, Auditf, FatalError, FullFileName,
#   FileNamePath, NumIDFRecords, IDFRecords, MaxAlphaArgsFound, MaxNumericArgsFound, MaxTotalArgs,
#   Alphas, Numbers, InArgs, AorN, ReqFld, FldNames, FldDefaults, FldUnits, NwAorN, NwReqFld,
#   NwFldNames, NwFldDefaults, NwFldUnits, OutArgs, MatchArg, DeleteThisRecord, Comments,
#   CurComment, NumRepVarNames, OldRepVarName, NewRepVarName, NewRepVarCaution, OTMVarCaution,
#   CMtrVarCaution, CMtrDVarCaution, ObjectDef, NumObjectDefs, NotInNew, MakingPretty
# - VCompareGlobalRoutines: DisplayString, ProcessInput, GetObjectDefInIDD, GetNewObjectDefInIDD,
#   ScanOutputVariablesForReplacement, WriteOutIDFLinesAsComments, WriteOutIDFLines,
#   CheckSpecialObjects, CreateNewName, ProcessRviMviFiles, CloseOut, writePreprocessorObject,
#   GetNumSectionsFound, copyfile
# - General: MakeUPPERCase, MakeLowerCase, SameString, FindItemInList, TrimTrailZeros
# - DataGlobals: ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError
# - External functions: GetNewUnitNumber, CalculateMuEMPD

from collections import deque


trait DataStringGlobals:
    fn get_blank(self) -> String:
        ...
    fn get_prog_name_conversion(self) -> String:
        ...


trait IDFRecord:
    fn get_name(self) -> String:
        ...
    fn get_num_alphas(self) -> Int:
        ...
    fn get_num_numbers(self) -> Int:
        ...
    fn get_alpha(self, i: Int) -> String:
        ...
    fn get_number(self, i: Int) -> Float64:
        ...
    fn get_commt_s(self) -> Int:
        ...
    fn get_commt_e(self) -> Int:
        ...


trait ObjectDef:
    fn get_name(self, i: Int) -> String:
        ...


trait DataVCompareGlobals:
    fn set_version_num(self, v: Float64) -> None:
        ...
    fn get_version_num(self) -> Float64:
        ...
    fn get_s_version_num(self) -> String:
        ...
    fn get_idd_file_name_with_path(self) -> String:
        ...
    fn get_new_idd_file_name_with_path(self) -> String:
        ...
    fn get_rep_var_file_name_with_path(self) -> String:
        ...
    fn get_program_path(self) -> String:
        ...
    fn set_processing_imf_file(self, v: Bool) -> None:
        ...
    fn get_processing_imf_file(self) -> Bool:
        ...
    fn get_auditf(self) -> Int:
        ...
    fn set_fatal_error(self, v: Bool) -> None:
        ...
    fn get_fatal_error(self) -> Bool:
        ...
    fn set_full_file_name(self, s: String) -> None:
        ...
    fn get_full_file_name(self) -> String:
        ...
    fn set_file_name_path(self, s: String) -> None:
        ...
    fn get_file_name_path(self) -> String:
        ...
    fn get_num_idf_records(self) -> Int:
        ...
    fn get_idf_record(self, i: Int) -> IDFRecord:
        ...
    fn get_max_alpha_args_found(self) -> Int:
        ...
    fn get_max_numeric_args_found(self) -> Int:
        ...
    fn get_max_total_args(self) -> Int:
        ...
    fn set_processing_imf_file(self, v: Bool) -> None:
        ...


trait VCompareGlobalRoutines:
    fn display_string(self, msg: String) -> None:
        ...
    fn process_input(self, idd_path: String, new_idd_path: String, idf_path: String) -> None:
        ...
    fn get_object_def_in_idd(self, name: String) -> Tuple[Int, DynamicVector[Bool], DynamicVector[Bool], Int, DynamicVector[String], DynamicVector[String], DynamicVector[String]]:
        ...
    fn get_new_object_def_in_idd(self, name: String) -> Tuple[Int, DynamicVector[Bool], DynamicVector[Bool], Int, DynamicVector[String], DynamicVector[String], DynamicVector[String]]:
        ...
    fn scan_output_variables_for_replacement(self, field_num: Int, inout del_this: Bool, inout check_rvi: Bool,
                                              inout nodiff: Bool, obj_name: String, lfn: Int, out_var: Bool,
                                              mtr_var: Bool, time_bin_var: Bool, inout cur_args: Int,
                                              inout written: Bool, is_sensor: Bool) -> None:
        ...
    fn write_out_idf_lines_as_comments(self, lfn: Int, obj_name: String, cur_args: Int,
                                        out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]) -> None:
        ...
    fn write_out_idf_lines(self, lfn: Int, obj_name: String, cur_args: Int,
                           out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String]) -> None:
        ...
    fn check_special_objects(self, lfn: Int, obj_name: String, cur_args: Int,
                              out_args: DynamicVector[String], fld_names: DynamicVector[String], fld_units: DynamicVector[String], inout written: Bool) -> None:
        ...
    fn create_new_name(self, mode: String, output_name: String, extra: String) -> String:
        ...
    fn process_rvi_mvi_files(self, file_path: String, ext: String) -> None:
        ...
    fn close_out(self) -> None:
        ...
    fn write_preprocessor_object(self, lfn: Int, prog_name: String, msg_type: String, msg: String) -> None:
        ...
    fn get_num_sections_found(self, section: String) -> Int:
        ...
    fn copyfile(self, src: String, dst: String, inout err_flag: Bool) -> None:
        ...


trait General:
    fn make_upper_case(self, s: String) -> String:
        ...
    fn make_lower_case(self, s: String) -> String:
        ...
    fn same_string(self, s1: String, s2: String) -> Bool:
        ...
    fn find_item_in_list(self, item: String, list_items: DynamicVector[String], n: Int) -> Int:
        ...
    fn trim_trail_zeros(self, s: String) -> String:
        ...


trait DataGlobals:
    fn show_message(self, msg: String) -> None:
        ...
    fn show_continue_error(self, msg: String) -> None:
        ...
    fn show_fatal_error(self, msg: String) -> None:
        ...
    fn show_severe_error(self, msg: String) -> None:
        ...
    fn show_warning_error(self, msg: String, lfn: Int = -1) -> None:
        ...


fn set_this_version_variables(
    data_version: DataVCompareGlobals,
    data_string: DataStringGlobals
) -> None:
    data_version.set_version_num(8.7)
    let sVersionNum = String("8.7")
    let program_path = data_version.get_program_path()
    data_version.set_idd_file_name_with_path(program_path + "V8-6-0-Energy+.idd")
    data_version.set_new_idd_file_name_with_path(program_path + "V8-7-0-Energy+.idd")
    data_version.set_rep_var_file_name_with_path(program_path + "Report Variables 8-6-0 to 8-7-0.csv")


fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    data_version: DataVCompareGlobals,
    data_string: DataStringGlobals,
    v_compare: VCompareGlobalRoutines,
    general: General,
    data_globals: DataGlobals
) -> None:

    var first_time = True
    if first_time:
        first_time = False

    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var no_version = True
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios = 0

    while still_working:
        var exit_because_bad_file = False

        while not end_of_file:
            var full_file_name = String()

            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                # Simulated input in Mojo - would need actual I/O binding
                full_file_name = input_file_name
            else:
                if not arg_file:
                    # Read from in_lfn - would need actual I/O binding
                    full_file_name = input_file_name
                    ios = 0
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = String()
                    ios = 1

                if full_file_name.startswith("!"):
                    full_file_name = String()
                    continue

            var units_arg = String()
            if ios != 0:
                full_file_name = String()

            full_file_name = full_file_name.lstrip()

            if full_file_name != String():
                v_compare.display_string("Processing IDF -- " + full_file_name)

                let dot_pos = full_file_name.rfind(".")

                var file_name_path = String()
                if dot_pos != -1:
                    file_name_path = full_file_name[0:dot_pos]
                    local_file_extension = general.make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print(" assuming file extension of .idf")
                    full_file_name = full_file_name.rstrip() + ".idf"
                    local_file_extension = "idf"

                let dif_lfn = v_compare.get_new_unit_number()

                var file_ok = False
                # Would check file existence with actual I/O binding

                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break

                if local_file_extension == "idf" or local_file_extension == "imf":
                    var check_rvi = False
                    var conn_comp = False
                    var conn_comp_ctrl = False

                    if diff_only:
                        let dif_file_path = file_name_path + "." + local_file_extension + "dif"
                    else:
                        let dif_file_path = file_name_path + "." + local_file_extension + "new"

                    if local_file_extension == "imf":
                        data_globals.show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.")
                        data_version.set_processing_imf_file(True)
                    else:
                        data_version.set_processing_imf_file(False)

                    v_compare.process_input(data_version.get_idd_file_name_with_path(),
                                           data_version.get_new_idd_file_name_with_path(),
                                           full_file_name)

                    if data_version.get_fatal_error():
                        exit_because_bad_file = True
                        break

                    var no_version = True
                    var num_idf_records = data_version.get_num_idf_records()
                    for num in range(num_idf_records):
                        let idf_rec = data_version.get_idf_record(num)
                        if general.make_upper_case(idf_rec.get_name()) != "VERSION":
                            continue
                        no_version = False
                        break

                    var schedule_type_limits_any_number = False
                    for num in range(num_idf_records):
                        let idf_rec = data_version.get_idf_record(num)
                        if not general.same_string(idf_rec.get_name(), "ScheduleTypeLimits"):
                            continue
                        if not general.same_string(idf_rec.get_alpha(0), "Any Number"):
                            continue
                        schedule_type_limits_any_number = True
                        break

                    for num in range(num_idf_records):
                        let idf_rec = data_version.get_idf_record(num)

                    for num in range(num_idf_records):
                        let idf_rec = data_version.get_idf_record(num)

                        if no_version and num == 0:
                            var nw_num_args = 0
                            var nw_aorn = DynamicVector[Bool]()
                            var nw_req_fld = DynamicVector[Bool]()
                            var nw_obj_min_flds = 0
                            var nw_fld_names = DynamicVector[String]()
                            var nw_fld_defaults = DynamicVector[String]()
                            var nw_fld_units = DynamicVector[String]()

                        var obj_name = idf_rec.get_name()
                        let obj_upper = general.make_upper_case(obj_name.rstrip())

                        if obj_upper == "PROGRAMCONTROL":
                            continue
                        if obj_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if obj_upper == "AIRFLOW MODEL":
                            continue
                        if obj_upper == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if obj_upper == "AIRFLOWNETWORK:MULTIZONE:SITEWINDCONDITIONS":
                            continue
                        if obj_upper == "WATER HEATER:SIMPLE":
                            v_compare.write_preprocessor_object(dif_lfn, data_string.get_prog_name_conversion(),
                                                               "Warning", "The WATER HEATER:SIMPLE object has been deleted")
                            continue

                        var num_alphas = idf_rec.get_num_alphas()
                        var num_numbers = idf_rec.get_num_numbers()

                        var cur_args = num_alphas + num_numbers
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False

                        if not data_version.get_making_pretty():
                            if obj_upper == "VERSION":
                                nodiff = False

                            elif obj_upper in ["COIL:COOLING:DX:MULTISPEED", "COIL:HEATING:DX:MULTISPEED"]:
                                nodiff = False

                            elif obj_upper == "COOLINGTOWER:SINGLESPEED":
                                obj_name = "CoolingTower:SingleSpeed"
                                nodiff = False
                                cur_args = cur_args + 4

                            elif obj_upper == "COOLINGTOWER:TWOSPEED":
                                obj_name = "CoolingTower:TwoSpeed"
                                nodiff = False
                                cur_args = cur_args + 4

                            elif obj_upper == "COOLINGTOWER:VARIABLESPEED:MERKEL":
                                obj_name = "CoolingTower:VariableSpeed:Merkel"
                                nodiff = False
                                cur_args = cur_args + 4

                            elif obj_upper == "AIRFLOWNETWORK:SIMULATIONCONTROL":
                                obj_name = "AirflowNetwork:SimulationControl"
                                nodiff = False
                                cur_args = cur_args - 1

                            elif obj_upper == "ZONECAPACITANCEMULTIPLIER:RESEARCHSPECIAL":
                                obj_name = "ZoneCapacitanceMultiplier:ResearchSpecial"
                                nodiff = False
                                cur_args = cur_args + 2

                            elif obj_upper == "WATERHEATER:HEATPUMP:WRAPPEDCONDENSER":
                                obj_name = "WaterHeater:HeatPump:WrappedCondenser"
                                nodiff = False

                            elif obj_upper == "AIRFLOWNETWORK:DISTRIBUTION:COMPONENT:DUCT":
                                obj_name = "AirflowNetwork:Distribution:Component:Duct"
                                nodiff = False
                                cur_args = cur_args + 2

                            elif obj_upper == "OUTPUT:VARIABLE":
                                nodiff = True

                            elif obj_upper in ["OUTPUT:METER", "OUTPUT:METER:METERFILEONLY",
                                             "OUTPUT:METER:CUMULATIVE", "OUTPUT:METER:CUMULATIVE:METERFILEONLY"]:
                                nodiff = True

                            elif obj_upper == "OUTPUT:TABLE:TIMEBINS":
                                nodiff = True

                            elif obj_upper in ["EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITIMPORT:FROM:VARIABLE",
                                             "EXTERNALINTERFACE:FUNCTIONALMOCKUPUNITEXPORT:FROM:VARIABLE"]:
                                nodiff = True

                            elif obj_upper == "ENERGYMANAGEMENTSYSTEM:SENSOR":
                                nodiff = True

                            elif obj_upper == "OUTPUT:TABLE:MONTHLY":
                                nodiff = True

                            elif obj_upper == "METER:CUSTOM":
                                nodiff = True

                            elif obj_upper == "METER:CUSTOMDECREMENT":
                                nodiff = True

                            else:
                                nodiff = True

                        if nodiff and diff_only:
                            continue

                        if not written:
                            v_compare.check_special_objects(dif_lfn, obj_name, cur_args,
                                                           DynamicVector[String](), nw_fld_names, nw_fld_units, written)

                        if not written:
                            v_compare.write_out_idf_lines(dif_lfn, obj_name, cur_args,
                                                         DynamicVector[String](), nw_fld_names, nw_fld_units)

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
