# EXTERNAL DEPS (to wire in glue):
# - ProcessInput: from InputProcessor, processes IDD and IDF files
# - GetNewUnitNumber: returns an available file unit number
# - FindNumber: searches for a numeric value
# - TrimTrailZeros: formats a number string
# - GetNewObjectDefInIDD: retrieves object definition from new IDD
# - GetObjectDefInIDD: retrieves object definition from old IDD
# - FindItemInList: searches for item in a string list
# - MakeUPPERCase: converts string to uppercase
# - MakeLowerCase: converts string to lowercase
# - samestring: case-insensitive string comparison
# - DisplayString: displays a message
# - ShowMessage, ShowContinueError, ShowFatalError, ShowSevereError, ShowWarningError: error reporting
# - WriteOutIDFLines: writes IDF object to file
# - WriteOutIDFLinesAsComments: writes IDF object as comments
# - CheckSpecialObjects: handles special object formatting
# - ProcessRviMviFiles: processes RVI/MVI auxiliary files
# - CloseOut: closes output files
# - CreateNewName: generates new file names
# - copyfile: copies files

from math import min, max


fn feq(s1: StringRef, s2: StringRef) -> Bool:
    """Fortran-style blank-padded string equality."""
    return s1.strip() == s2.strip()


fn fortran_index(s: StringRef, substr: StringRef, backward: Bool = False) -> Int:
    """Fortran INDEX function: 1-based, returns 0 if not found."""
    if backward:
        var pos = s.rfind(substr)
    else:
        var pos = s.find(substr)
    return pos + 1 if pos >= 0 else 0


fn fortran_scan(s: StringRef, chars: StringRef, backward: Bool = False) -> Int:
    """Fortran SCAN function: 1-based, returns 0 if not found."""
    if backward:
        for i in range(len(s) - 1, -1, -1):
            if chars.contains(s[i]):
                return i + 1
    else:
        for i in range(len(s)):
            if chars.contains(s[i]):
                return i + 1
    return 0


fn trim(s: StringRef) -> String:
    """Fortran TRIM: remove trailing blanks."""
    return s.rstrip()


fn adjustl(s: StringRef) -> String:
    """Fortran ADJUSTL: remove leading blanks."""
    return s.lstrip()


struct VersionState:
    var ver_string: String
    var version_num: Float64
    var idd_file_name_with_path: String
    var new_idd_file_name_with_path: String
    var rep_var_file_name_with_path: String
    
    fn __init__(inout self):
        self.ver_string = ""
        self.version_num = 0.0
        self.idd_file_name_with_path = ""
        self.new_idd_file_name_with_path = ""
        self.rep_var_file_name_with_path = ""


struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var commt_s: Int
    var commt_e: Int
    var alphas: List[String]
    var numbers: List[String]
    
    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.commt_s = 0
        self.commt_e = 0
        self.alphas = List[String]()
        self.numbers = List[String]()


struct ProcessingState:
    var full_file_name: String
    var file_name_path: String
    var auditf: Optional[StringRef]
    var idf_records: List[IDFRecord]
    var comments: List[String]
    var num_idf_records: Int
    var cur_comment: Int
    var object_def: Optional[StringRef]
    var num_object_defs: Int
    var max_alpha_args_found: Int
    var max_numeric_args_found: Int
    var max_total_args: Int
    var num_alphas: Int
    var num_numbers: Int
    var processing_imf_file: Bool
    var fatal_error: Bool
    var old_rep_var_name: List[String]
    var new_rep_var_name: List[String]
    var num_rep_var_names: Int
    var not_in_new: List[String]
    var making_pretty: Bool
    var program_path: String
    
    fn __init__(inout self):
        self.full_file_name = ""
        self.file_name_path = ""
        self.auditf = None
        self.idf_records = List[IDFRecord]()
        self.comments = List[String]()
        self.num_idf_records = 0
        self.cur_comment = 0
        self.object_def = None
        self.num_object_defs = 0
        self.max_alpha_args_found = 0
        self.max_numeric_args_found = 0
        self.max_total_args = 0
        self.num_alphas = 0
        self.num_numbers = 0
        self.processing_imf_file = False
        self.fatal_error = False
        self.old_rep_var_name = List[String]()
        self.new_rep_var_name = List[String]()
        self.num_rep_var_names = 0
        self.not_in_new = List[String]()
        self.making_pretty = False
        self.program_path = ""


var Blank = " " * 132


fn set_version(inout state: VersionState, program_path: StringRef):
    """SetThisVersionVariables subroutine."""
    state.ver_string = "Conversion 1.2.1 => 1.2.2"
    state.version_num = 1.0
    state.idd_file_name_with_path = trim(program_path) + "V1-2-1-Energy+.idd"
    state.new_idd_file_name_with_path = trim(program_path) + "V1-2-2-Energy+.idd"
    state.rep_var_file_name_with_path = trim(program_path) + "Report Variables 1-2-1-012 to 1-2-2.csv"


fn slice_assign(arr: List[String], start: Int, end: Int, values: List[String]):
    """Assign values to Fortran-style 1-based inclusive slice."""
    for i in range(len(values)):
        if start + i <= end and start + i < len(arr):
            arr[start + i] = values[i]


fn process_input(idd_file: StringRef, new_idd_file: StringRef, idf_file: StringRef, inout state: ProcessingState):
    pass


fn get_new_unit_number() -> Int:
    pass


fn find_number(name: StringRef) -> Int:
    pass


fn trim_trail_zeros(value: StringRef) -> String:
    pass


fn get_new_object_def_in_idd(name: StringRef, inout state: ProcessingState) -> Tuple[Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]]:
    pass


fn get_object_def_in_idd(name: StringRef, inout state: ProcessingState) -> Tuple[Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]]:
    pass


fn find_item_in_list(item: StringRef, items: List[String], count: Int) -> Int:
    pass


fn make_upper_case(s: StringRef) -> String:
    pass


fn make_lower_case(s: StringRef) -> String:
    pass


fn samestring(s1: StringRef, s2: StringRef) -> Bool:
    pass


fn display_string(msg: StringRef):
    pass


fn show_warning_error(msg: StringRef, auditf: Optional[StringRef] = None):
    pass


fn write_out_idf_lines(lfn: Int, obj_name: StringRef, cur_args: Int, out_args: List[String],
                       fld_names: List[String], fld_units: List[String]):
    pass


fn write_out_idf_lines_as_comments(lfn: Int, obj_name: StringRef, cur_args: Int, out_args: List[String],
                                   fld_names: List[String], fld_units: List[String]):
    pass


fn check_special_objects(lfn: Int, obj_name: StringRef, cur_args: Int, out_args: List[String],
                         fld_names: List[String], fld_units: List[String]) -> Tuple[Bool]:
    pass


fn process_rvi_mvi_files(path: StringRef, ext: StringRef):
    pass


fn close_out():
    pass


fn create_new_name(mode: StringRef, name: StringRef, default: StringRef):
    pass


fn copyfile(src: StringRef, dst: StringRef) -> Bool:
    pass


fn scan_output_variables_for_replacement(var_pos: Int, del_this: List[Bool], checkrvi: List[Bool],
                                         nodiff: List[Bool], obj_name: StringRef, lfn: Int,
                                         out_var: Bool, mtr_var: Bool, time_bin_var: Bool,
                                         cur_args: Int, written: List[Bool], use_parent: Bool,
                                         inout state: ProcessingState):
    pass


fn create_new_idf_using_rules(end_of_file: List[Bool], diff_only: Bool, in_lfn: Int,
                              ask_for_input: Bool, input_file_name: StringRef,
                              arg_file: Bool, arg_idf_extension: StringRef,
                              inout state: ProcessingState):
    """CreateNewIDFUsingRules subroutine."""
    
    var fmta = "(A)"
    
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = String(arg_idf_extension)
    end_of_file[0] = False
    var ios = 0
    
    while still_working:
        var exit_because_bad_file = False
        while not end_of_file[0]:
            if ask_for_input:
                print("Enter input file name, with path")
                state.full_file_name = input("--> ")
            else:
                if not arg_file:
                    ios = 0
                    state.full_file_name = ""
                elif not arg_file_being_done:
                    state.full_file_name = String(input_file_name)
                    ios = 0
                    arg_file_being_done = True
                else:
                    state.full_file_name = Blank
                    ios = 1
                
                if state.full_file_name[0:1] == "!":
                    state.full_file_name = Blank
                    continue
            
            var units_arg = Blank
            if ios != 0:
                state.full_file_name = Blank
            state.full_file_name = adjustl(state.full_file_name)
            
            if state.full_file_name != Blank:
                display_string("Processing IDF -- " + trim(state.full_file_name))
                if state.auditf:
                    print(" Processing IDF -- " + trim(state.full_file_name))
                
                var dot_pos = fortran_scan(state.full_file_name, ".", backward=True)
                if dot_pos != 0:
                    state.file_name_path = state.full_file_name[0:dot_pos - 1]
                    local_file_extension = make_lower_case(state.full_file_name[dot_pos:])
                else:
                    state.file_name_path = state.full_file_name
                    print(" assuming file extension of .idf")
                    state.full_file_name = trim(state.full_file_name) + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn = get_new_unit_number()
                var file_ok = _file_exists(trim(state.full_file_name))
                
                if not file_ok:
                    print("File not found=" + trim(state.full_file_name))
                    end_of_file[0] = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    var out_file_name: String
                    if diff_only:
                        out_file_name = trim(state.file_name_path) + "." + trim(local_file_extension) + "dif"
                    else:
                        out_file_name = trim(state.file_name_path) + "." + trim(local_file_extension) + "new"
                    
                    var dif_file = _open_file(out_file_name, "w")
                    
                    if local_file_extension == "imf":
                        show_warning_error("Note: IMF file being processed.  No guarantee of perfection.  Please check new file carefully.", state.auditf)
                        state.processing_imf_file = True
                    else:
                        state.processing_imf_file = False
                    
                    process_input(state.idd_file_name_with_path, state.new_idd_file_name_with_path,
                                trim(state.full_file_name), state)
                    
                    if state.fatal_error:
                        exit_because_bad_file = True
                        break
                    
                    var max_alpha = state.max_alpha_args_found
                    var max_numeric = state.max_numeric_args_found
                    var max_total = state.max_total_args
                    
                    var alphas = List[String](capacity=max_alpha + 1)
                    var numbers = List[String](capacity=max_numeric + 1)
                    var in_args = List[String](capacity=max_total + 1)
                    var out_args = List[String](capacity=max_total + 1)
                    var match_arg = List[String](capacity=max_total + 1)
                    
                    var aorn = List[Bool](capacity=max_total + 1)
                    var req_fld = List[Bool](capacity=max_total + 1)
                    var fld_names = List[String](capacity=max_total + 1)
                    var fld_defaults = List[String](capacity=max_total + 1)
                    var fld_units = List[String](capacity=max_total + 1)
                    
                    var nwaorn = List[Bool](capacity=max_total + 1)
                    var nw_req_fld = List[Bool](capacity=max_total + 1)
                    var nw_fld_names = List[String](capacity=max_total + 1)
                    var nw_fld_defaults = List[String](capacity=max_total + 1)
                    var nw_fld_units = List[String](capacity=max_total + 1)
                    
                    var delete_this_record = List[Bool](capacity=state.num_idf_records + 1)
                    
                    var no_version = True
                    for num in range(1, state.num_idf_records + 1):
                        if make_upper_case(state.idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(1, state.num_idf_records + 1):
                        for xcount in range(state.idf_records[num].commt_s + 1, state.idf_records[num].commt_e + 1):
                            _file_write(dif_file, trim(state.comments[xcount]) + "\n")
                            if xcount == state.idf_records[num].commt_e:
                                _file_write(dif_file, "\n")
                        
                        if no_version and num == 1:
                            var nw_num_args: Int
                            var nw_obj_min_flds: Int
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                get_new_object_def_in_idd("VERSION", state)
                            out_args[1] = "1.2.2"
                            var cur_args = 1
                            write_out_idf_lines_as_comments(dif_file, "VERSION", cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if make_upper_case(trim(state.idf_records[num].name)) == "SKY RADIANCE DISTRIBUTION":
                            continue
                        
                        var object_name = state.idf_records[num].name
                        var num_alphas: Int
                        var num_numbers: Int
                        var num_args: Int
                        var obj_min_flds: Int
                        
                        if find_item_in_list(object_name, state.idf_records[num].name, state.num_object_defs) != 0:
                            num_args, aorn, req_fld, obj_min_flds, fld_names, fld_defaults, fld_units = \
                                get_object_def_in_idd(object_name, state)
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            
                            for i in range(1, num_alphas + 1):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = state.idf_records[num].numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            in_args = List[String](capacity=max_total + 1)
                            out_args = List[String](capacity=max_total + 1)
                            var na = 0
                            var nn = 0
                            
                            for arg in range(1, cur_args + 1):
                                if aorn[arg]:
                                    na += 1
                                    in_args[arg] = alphas[na]
                                else:
                                    nn += 1
                                    in_args[arg] = numbers[nn]
                        else:
                            num_alphas = state.idf_records[num].num_alphas
                            num_numbers = state.idf_records[num].num_numbers
                            
                            for i in range(1, num_alphas + 1):
                                alphas[i] = state.idf_records[num].alphas[i]
                            for i in range(1, num_numbers + 1):
                                numbers[i] = state.idf_records[num].numbers[i]
                            
                            for arg in range(1, num_alphas + 1):
                                out_args[arg] = alphas[arg]
                            
                            nn = num_alphas + 1
                            for arg in range(1, num_numbers + 1):
                                out_args[nn] = numbers[arg]
                                nn += 1
                            
                            cur_args = num_alphas + num_numbers
                            nw_fld_names = List[String](capacity=max_total + 1)
                            nw_fld_units = List[String](capacity=max_total + 1)
                            
                            write_out_idf_lines_as_comments(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                            continue
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                        var nw_num_args: Int
                        var nw_obj_min_flds: Int
                        
                        if find_item_in_list(make_upper_case(object_name), state.not_in_new, len(state.not_in_new)) == 0:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                get_new_object_def_in_idd(object_name, state)
                            if obj_min_flds != nw_obj_min_flds:
                                diff_min_fields = True
                            else:
                                diff_min_fields = False
                        
                        if not state.making_pretty:
                            var obj_upper = make_upper_case(trim(state.idf_records[num].name))
                            
                            if obj_upper == "VERSION":
                                if in_args[1][0:5] == "1.2.2" and arg_file:
                                    show_warning_error("File is already at latest version.  No new diff file made.", state.auditf)
                                    _file_close(dif_file)
                                    latest_version = True
                                    break
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                out_args[1] = "1.2.2"
                                nodiff = False
                            
                            elif obj_upper == "DESICCANT DEHUMIDIFIER:SOLID":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if out_args[7] == "LEAVING HUMRAT:BYPASS":
                                    nodiff = False
                                    out_args[7] = "FIXED LEAVING HUMRAT SETPOINT:BYPASS"
                            
                            elif obj_upper == "DOMESTIC HOT WATER":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                nodiff = False
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = in_args[3]
                                out_args[4] = "1.0"
                                out_args[5] = in_args[4]
                                out_args[5] = trim(in_args[1]) + ":FRF Sch"
                                cur_args = 6
                                write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                                
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd("SCHEDULE:COMPACT", state)
                                out_args[1] = trim(in_args[1]) + ":FRF Sch"
                                out_args[2] = " "
                                out_args[3] = "Through: 12/31"
                                out_args[4] = "For: AllDays"
                                out_args[5] = "Until: 24:00"
                                out_args[6] = in_args[5]
                                cur_args = 6
                                write_out_idf_lines(dif_file, "SCHEDULE:COMPACT", cur_args, out_args, nw_fld_names, nw_fld_units)
                                written = True
                            
                            elif obj_upper == "PLANT LOAD PROFILE":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = in_args[3]
                                out_args[4] = in_args[4]
                                out_args[5] = "1.0"
                                out_args[6] = in_args[5]
                                cur_args = 6
                                nodiff = False
                            
                            elif obj_upper == "UNITARYSYSTEM:HEATPUMP:WATERTOAIR":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, 11, in_args[1:12])
                                slice_assign(out_args, 12, 13, in_args[13:15])
                                out_args[14] = "2.5"
                                out_args[15] = "60"
                                out_args[16] = "0.01"
                                out_args[17] = "60"
                                slice_assign(out_args, 18, 24, in_args[16:23])
                                cur_args = 24
                                nodiff = False
                            
                            elif obj_upper == "COIL:WATERTOAIRHP:COOLING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = "Water"
                                out_args[4] = "R22"
                                out_args[5] = in_args[3]
                                out_args[6] = in_args[4]
                                out_args[7] = "0"
                                out_args[8] = "0"
                                slice_assign(out_args, 9, 14, in_args[5:11])
                                out_args[15] = in_args[13]
                                out_args[16] = in_args[12]
                                slice_assign(out_args, 17, 22, in_args[14:20])
                                out_args[23] = in_args[11]
                                out_args[24] = " "
                                cur_args = 24
                                nodiff = False
                            
                            elif obj_upper == "COIL:WATERTOAIRHP:HEATING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                out_args[1] = in_args[1]
                                out_args[2] = in_args[2]
                                out_args[3] = "Water"
                                out_args[4] = "R22"
                                slice_assign(out_args, 5, 12, in_args[3:11])
                                out_args[13] = in_args[12]
                                slice_assign(out_args, 14, 19, in_args[13:19])
                                out_args[20] = in_args[11]
                                out_args[21] = " "
                                cur_args = 21
                                nodiff = False
                            
                            elif obj_upper == "BUILDING":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if cur_args == 8:
                                    nodiff = False
                                    if make_upper_case(out_args[8]) == "YES":
                                        out_args[6] = trim(out_args[6]) + "WithReflections"
                                        out_args[8] = Blank
                                        cur_args = 7
                                    elif make_upper_case(out_args[8]) == "NO":
                                        out_args[8] = Blank
                                        cur_args = 7
                            
                            elif obj_upper == "WINDOWSHADINGCONTROL":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                nodiff = False
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                if samestring("InteriorNonInsulatingShade", in_args[2]):
                                    out_args[2] = "InteriorShade"
                                if samestring("ExteriorNonInsulatingShade", in_args[2]):
                                    out_args[2] = "ExteriorShade"
                                if samestring("InteriorInsulatingShade", in_args[2]):
                                    out_args[2] = "InteriorShade"
                                if samestring("ExteriorInsulatingShade", in_args[2]):
                                    out_args[2] = "ExteriorShade"
                                if samestring("Schedule", in_args[4]):
                                    out_args[4] = "OnIfScheduleAllows"
                                if samestring("SolarOnWindow", in_args[4]):
                                    out_args[4] = "OnIfHighSolarOnWindow"
                                if samestring("HorizontalSolar", in_args[4]):
                                    out_args[4] = "OnIfHighHorizontalSolar"
                                if samestring("OutsideAirTemp", in_args[4]):
                                    out_args[4] = "OnIfHighOutsideAirTemp"
                                if samestring("ZoneAirTemp", in_args[4]):
                                    out_args[4] = "OnIfHighZoneAirTemp"
                                if samestring("ZoneCooling", in_args[4]):
                                    out_args[4] = "OnIfHighZoneCooling"
                                if samestring("Glare", in_args[4]):
                                    out_args[4] = "OnIfHighGlare"
                                if samestring("DaylightIlluminance", in_args[4]):
                                    out_args[4] = "MeetDaylightIlluminanceSetpoint"
                            
                            elif obj_upper == "REPORT VARIABLE":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                var del_this = List[Bool]()
                                del_this.append(False)
                                scan_output_variables_for_replacement(2, del_this, List[Bool](), List[Bool](), object_name, dif_file,
                                                                     True, False, False, cur_args, List[Bool](), False, state)
                                if del_this[0]:
                                    continue
                            
                            elif obj_upper in ["REPORT METER", "REPORT METERFILEONLY", "REPORT CUMULATIVE METER", "REPORT CUMULATIVE METERFILEONLY"]:
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                var del_this2 = List[Bool]()
                                del_this2.append(False)
                                scan_output_variables_for_replacement(1, del_this2, List[Bool](), List[Bool](), object_name, dif_file,
                                                                     False, True, False, cur_args, List[Bool](), False, state)
                                if del_this2[0]:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:TIMEBINS":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                var del_this3 = List[Bool]()
                                del_this3.append(False)
                                scan_output_variables_for_replacement(2, del_this3, List[Bool](), List[Bool](), object_name, dif_file,
                                                                     False, False, True, cur_args, List[Bool](), False, state)
                                if del_this3[0]:
                                    continue
                            
                            elif obj_upper == "REPORT:TABLE:MONTHLY":
                                nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                    get_new_object_def_in_idd(object_name, state)
                                slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                nodiff = True
                                if out_args[1] == Blank:
                                    out_args[1] = "*"
                                    nodiff = False
                                
                                var cur_var = 3
                                var var_loop = 3
                                while var_loop <= cur_args:
                                    var uc_rep_var_name = make_upper_case(in_args[var_loop])
                                    out_args[cur_var] = in_args[var_loop]
                                    out_args[cur_var + 1] = in_args[var_loop + 1]
                                    var pos = fortran_index(uc_rep_var_name, "[")
                                    if pos > 0:
                                        uc_rep_var_name = uc_rep_var_name[0:pos - 1]
                                        out_args[cur_var] = in_args[var_loop][0:pos - 1]
                                        out_args[cur_var + 1] = in_args[var_loop + 1]
                                    
                                    var del_this4 = False
                                    for arg in range(1, state.num_rep_var_names + 1):
                                        var uc_comp_rep_var_name = make_upper_case(state.old_rep_var_name[arg])
                                        var wild_match = False
                                        if uc_comp_rep_var_name[len(trim(uc_comp_rep_var_name)) - 1] == "*":
                                            wild_match = True
                                            uc_comp_rep_var_name = uc_comp_rep_var_name[0:len(trim(uc_comp_rep_var_name)) - 1] + " "
                                        
                                        pos = fortran_index(trim(uc_rep_var_name), trim(uc_comp_rep_var_name))
                                        if pos > 0 and pos != 1:
                                            continue
                                        if pos > 0:
                                            if state.new_rep_var_name[arg] != "<DELETE>":
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg]
                                                else:
                                                    out_args[cur_var] = trim(state.new_rep_var_name[arg]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var_loop + 1]
                                                nodiff = False
                                            else:
                                                del_this4 = True
                                            
                                            if state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 1]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 1]
                                                else:
                                                    out_args[cur_var] = trim(state.new_rep_var_name[arg + 1]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var_loop + 1]
                                                nodiff = False
                                            
                                            if arg + 2 <= state.num_rep_var_names and state.old_rep_var_name[arg] == state.old_rep_var_name[arg + 2]:
                                                cur_var += 2
                                                if not wild_match:
                                                    out_args[cur_var] = state.new_rep_var_name[arg + 2]
                                                else:
                                                    out_args[cur_var] = trim(state.new_rep_var_name[arg + 2]) + out_args[cur_var][len(trim(uc_comp_rep_var_name)):]
                                                out_args[cur_var + 1] = in_args[var_loop + 1]
                                                nodiff = False
                                            break
                                    
                                    if not del_this4:
                                        cur_var += 2
                                    var_loop += 2
                                
                                cur_args = cur_var - 1
                            
                            else:
                                if find_item_in_list(object_name, state.not_in_new, len(state.not_in_new)) != 0:
                                    write_out_idf_lines_as_comments(dif_file, object_name, cur_args, in_args, fld_names, fld_units)
                                    written = True
                                else:
                                    nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                        get_new_object_def_in_idd(object_name, state)
                                    slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                                    nodiff = True
                        
                        else:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                get_new_object_def_in_idd(state.idf_records[num].name, state)
                            slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                        
                        if diff_min_fields and nodiff:
                            nw_num_args, nwaorn, nw_req_fld, nw_obj_min_flds, nw_fld_names, nw_fld_defaults, nw_fld_units = \
                                get_new_object_def_in_idd(object_name, state)
                            slice_assign(out_args, 1, cur_args, in_args[1:cur_args + 1])
                            nodiff = False
                            for arg in range(cur_args + 1, nw_obj_min_flds + 1):
                                out_args[arg] = nw_fld_defaults[arg]
                            cur_args = max(nw_obj_min_flds, cur_args)
                        
                        if nodiff and diff_only:
                            continue
                        
                        if not written:
                            check_special_objects(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                        
                        if not written:
                            write_out_idf_lines(dif_file, object_name, cur_args, out_args, nw_fld_names, nw_fld_units)
                    
                    if state.idf_records[state.num_idf_records].commt_e != state.cur_comment:
                        for xcount in range(state.idf_records[state.num_idf_records].commt_e + 1, state.cur_comment + 1):
                            _file_write(dif_file, trim(state.comments[xcount]) + "\n")
                            if xcount == state.idf_records[state.num_idf_records].commt_e:
                                _file_write(dif_file, "\n")
                    
                    _file_close(dif_file)
                    
                    if checkrvi:
                        process_rvi_mvi_files(state.file_name_path, "rvi")
                        process_rvi_mvi_files(state.file_name_path, "mvi")
                    
                    close_out()
                
                else:
                    process_rvi_mvi_files(state.file_name_path, "rvi")
                    process_rvi_mvi_files(state.file_name_path, "mvi")
            
            else:
                end_of_file[0] = True
            
            create_new_name("Reallocate", "", " ")
        
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
        copyfile(trim(state.file_name_path) + "." + trim(arg_idf_extension),
                trim(state.file_name_path) + "." + trim(arg_idf_extension) + "old")
        copyfile(trim(state.file_name_path) + "." + trim(arg_idf_extension) + "new",
                trim(state.file_name_path) + "." + trim(arg_idf_extension))
        
        if _file_exists(trim(state.file_name_path) + ".rvi"):
            copyfile(trim(state.file_name_path) + ".rvi",
                    trim(state.file_name_path) + ".rviold")
        
        if _file_exists(trim(state.file_name_path) + ".rvinew"):
            copyfile(trim(state.file_name_path) + ".rvinew",
                    trim(state.file_name_path) + ".rvi")
        
        if _file_exists(trim(state.file_name_path) + ".mvi"):
            copyfile(trim(state.file_name_path) + ".mvi",
                    trim(state.file_name_path) + ".mviold")
        
        if _file_exists(trim(state.file_name_path) + ".mvinew"):
            copyfile(trim(state.file_name_path) + ".mvinew",
                    trim(state.file_name_path) + ".mvi")


fn _file_exists(path: StringRef) -> Bool:
    pass


fn _open_file(path: StringRef, mode: StringRef):
    pass


fn _file_write(f, content: StringRef):
    pass


fn _file_close(f):
    pass
