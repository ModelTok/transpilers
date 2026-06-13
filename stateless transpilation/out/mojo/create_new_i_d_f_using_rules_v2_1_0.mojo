from memory import UnsafePointer
from collections import Dict, List
from sys import exit

struct IDFRecord:
    var name: String
    var num_alphas: Int
    var num_numbers: Int
    var alphas: List[String]
    var numbers: List[Float64]
    var commt_s: Int
    var commt_e: Int
    
    fn __init__(inout self):
        self.name = ""
        self.num_alphas = 0
        self.num_numbers = 0
        self.alphas = List[String]()
        self.numbers = List[Float64]()
        self.commt_s = 0
        self.commt_e = 0


struct ObjectDefType:
    var name: List[String]
    
    fn __init__(inout self):
        self.name = List[String]()


trait ExternalContext:
    fn get_ver_string(self) -> String: ...
    fn set_ver_string(inout self, value: String): ...
    fn get_version_num(self) -> Float64: ...
    fn set_version_num(inout self, value: Float64): ...
    fn get_idd_file_name_with_path(self) -> String: ...
    fn set_idd_file_name_with_path(inout self, value: String): ...
    fn get_new_idd_file_name_with_path(self) -> String: ...
    fn set_new_idd_file_name_with_path(inout self, value: String): ...
    fn get_rep_var_file_name_with_path(self) -> String: ...
    fn set_rep_var_file_name_with_path(inout self, value: String): ...
    fn get_blank(self) -> String: ...
    fn get_fatal_error(self) -> Bool: ...
    fn set_fatal_error(inout self, value: Bool): ...
    fn get_max_alpha_args_found(self) -> Int: ...
    fn get_max_numeric_args_found(self) -> Int: ...
    fn get_max_total_args(self) -> Int: ...
    fn get_num_idf_records(self) -> Int: ...
    fn get_idf_records(self) -> List[IDFRecord]: ...
    fn get_object_def(self) -> ObjectDefType: ...
    fn get_num_object_defs(self) -> Int: ...
    fn get_comments(self) -> List[String]: ...
    fn get_cur_comment(self) -> Int: ...
    fn get_not_in_new(self) -> List[String]: ...
    fn get_num_rep_var_names(self) -> Int: ...
    fn get_old_rep_var_name(self) -> List[String]: ...
    fn get_new_rep_var_name(self) -> List[String]: ...
    fn get_processing_imf_file(self) -> Bool: ...
    fn set_processing_imf_file(inout self, value: Bool): ...
    fn get_making_pretty(self) -> Bool: ...
    fn get_file_name_path(self) -> String: ...
    fn set_file_name_path(inout self, value: String): ...
    fn get_full_file_name(self) -> String: ...
    fn set_full_file_name(inout self, value: String): ...
    fn get_auditf(self) -> UnsafePointer[Int8]: ...
    
    fn display_string(self, msg: String): ...
    fn process_input(inout self, old_idd: String, new_idd: String, file_path: String): ...
    fn get_new_object_def_in_idd(self, obj_name: String) -> (Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]): ...
    fn get_object_def_in_idd(self, obj_name: String) -> (Int, List[Bool], List[Bool], Int, List[String], List[String], List[String]): ...
    fn find_item_in_list(self, item: String, item_list: List[String]) -> Int: ...
    fn write_out_idf_lines_as_comments(self, lfn: UnsafePointer[Int8], obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]): ...
    fn write_out_idf_lines(self, lfn: UnsafePointer[Int8], obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]): ...
    fn make_upper_case(self, s: String) -> String: ...
    fn make_lower_case(self, s: String) -> String: ...
    fn process_number(self, s: String) -> (Bool, Float64): ...
    fn round_sig_digits(self, num: Float64, digits: Int) -> String: ...
    fn scan_output_variables_for_replacement(inout self, arg_pos: Int, out_var: Bool, mtr_var: Bool, time_bin_var: Bool, cur_args: Int, obj_name: String, lfn: UnsafePointer[Int8], out_args: List[String]) -> (Bool, Bool, Bool, Int, Bool): ...
    fn check_special_objects(self, lfn: UnsafePointer[Int8], obj_name: String, cur_args: Int, out_args: List[String], fld_names: List[String], fld_units: List[String]) -> Bool: ...
    fn process_rvi_mvi_files(self, path: String, ext: String): ...
    fn close_out(inout self): ...
    fn create_new_name(self, action: String, out_name: String, marker: String) -> String: ...
    fn same_string(self, s1: String, s2: String) -> Bool: ...
    fn copy_file(self, src: String, dst: String) -> Bool: ...
    fn trim_trail_zeros(self, s: String) -> String: ...
    fn get_new_unit_number(self) -> Int: ...
    fn show_warning_error(self, msg: String, lfn: UnsafePointer[Int8]): ...
    fn show_severe_error(self, msg: String, lfn: UnsafePointer[Int8]): ...


@value
struct StringHelper:
    @staticmethod
    fn len_trim(s: String) -> Int:
        var result = len(s)
        while result > 0 and s[result - 1] == " ":
            result -= 1
        return result


fn set_this_version_variables(inout context: ExternalContext):
    context.set_ver_string("Conversion 2.0 => 2.1")
    context.set_version_num(2.0)
    context.set_idd_file_name_with_path(context.get_file_name_path() + "V2-0-0-Energy+.idd")
    context.set_new_idd_file_name_with_path(context.get_file_name_path() + "V2-1-0-Energy+.idd")
    context.set_rep_var_file_name_with_path(context.get_file_name_path() + "Report Variables 2-0-0-025 to 2-1-0.csv")


fn create_new_idf_using_rules(
    inout end_of_file: Bool,
    diff_only: Bool,
    in_lfn: Int,
    ask_for_input: Bool,
    input_file_name: String,
    arg_file: Bool,
    arg_idf_extension: String,
    inout context: ExternalContext,
) -> Bool:
    var still_working = True
    var arg_file_being_done = False
    var latest_version = False
    var local_file_extension = arg_idf_extension
    end_of_file = False
    var ios: Int = 0
    
    while still_working:
        var exit_because_bad_file = False
        while not end_of_file:
            var full_file_name: String
            if ask_for_input:
                print("Enter input file name, with path")
                print("-->", end="")
                full_file_name = ""
            else:
                if not arg_file:
                    ios = 0
                    full_file_name = ""
                elif not arg_file_being_done:
                    full_file_name = input_file_name
                    ios = 0
                    arg_file_being_done = True
                else:
                    full_file_name = ""
                    ios = 1
                
                if len(full_file_name) > 0 and full_file_name[0] == "!":
                    full_file_name = ""
                    continue
            
            var units_arg = ""
            if ios != 0:
                full_file_name = ""
            
            var i = 0
            while i < len(full_file_name) and full_file_name[i] == " ":
                i += 1
            full_file_name = full_file_name[i:]
            
            if len(full_file_name) > 0:
                context.display_string("Processing IDF -- " + full_file_name)
                
                var dot_pos = -1
                for j in range(len(full_file_name) - 1, -1, -1):
                    if full_file_name[j] == ".":
                        dot_pos = j
                        break
                
                var file_name_path: String
                if dot_pos != -1:
                    file_name_path = full_file_name[:dot_pos]
                    local_file_extension = context.make_lower_case(full_file_name[dot_pos + 1:])
                else:
                    file_name_path = full_file_name
                    print("assuming file extension of .idf")
                    full_file_name = full_file_name + ".idf"
                    local_file_extension = "idf"
                
                var dif_lfn = context.get_new_unit_number()
                var file_ok = False
                
                if not file_ok:
                    print("File not found=" + full_file_name)
                    end_of_file = True
                    exit_because_bad_file = True
                    break
                
                if local_file_extension == "idf" or local_file_extension == "imf":
                    var checkrvi = False
                    var comis_sim = False
                    var ads_sim = False
                    
                    var out_file_name: String
                    if diff_only:
                        out_file_name = file_name_path + "." + local_file_extension + "dif"
                    else:
                        out_file_name = file_name_path + "." + local_file_extension + "new"
                    
                    if local_file_extension == "imf":
                        context.show_warning_error(
                            "Note: IMF file being processed. No guarantee of perfection. Please check new file carefully.",
                            context.get_auditf()
                        )
                        context.set_processing_imf_file(True)
                    else:
                        context.set_processing_imf_file(False)
                    
                    context.process_input(
                        context.get_idd_file_name_with_path(),
                        context.get_new_idd_file_name_with_path(),
                        full_file_name
                    )
                    
                    if context.get_fatal_error():
                        exit_because_bad_file = True
                        break
                    
                    var max_total_args = context.get_max_total_args()
                    var alphas = List[String]()
                    for _ in range(context.get_max_alpha_args_found()):
                        alphas.append("")
                    var numbers = List[Float64]()
                    for _ in range(context.get_max_numeric_args_found()):
                        numbers.append(0.0)
                    var in_args = List[String]()
                    for _ in range(max_total_args):
                        in_args.append("")
                    var aor_n = List[Bool]()
                    for _ in range(max_total_args):
                        aor_n.append(False)
                    var req_fld = List[Bool]()
                    for _ in range(max_total_args):
                        req_fld.append(False)
                    var fld_names = List[String]()
                    for _ in range(max_total_args):
                        fld_names.append("")
                    var fld_defaults = List[String]()
                    for _ in range(max_total_args):
                        fld_defaults.append("")
                    var fld_units = List[String]()
                    for _ in range(max_total_args):
                        fld_units.append("")
                    var nw_aor_n = List[Bool]()
                    for _ in range(max_total_args):
                        nw_aor_n.append(False)
                    var nw_req_fld = List[Bool]()
                    for _ in range(max_total_args):
                        nw_req_fld.append(False)
                    var nw_fld_names = List[String]()
                    for _ in range(max_total_args):
                        nw_fld_names.append("")
                    var nw_fld_defaults = List[String]()
                    for _ in range(max_total_args):
                        nw_fld_defaults.append("")
                    var nw_fld_units = List[String]()
                    for _ in range(max_total_args):
                        nw_fld_units.append("")
                    var out_args = List[String]()
                    for _ in range(max_total_args):
                        out_args.append("")
                    var match_arg = List[Bool]()
                    for _ in range(max_total_args):
                        match_arg.append(False)
                    var delete_this_record = List[Bool]()
                    for _ in range(context.get_num_idf_records()):
                        delete_this_record.append(False)
                    
                    var idf_records = context.get_idf_records()
                    for num in range(context.get_num_idf_records()):
                        if context.make_upper_case(idf_records[num].name) == "COMIS SIMULATION":
                            comis_sim = True
                        if context.make_upper_case(idf_records[num].name) == "ADS SIMULATION":
                            ads_sim = True
                    
                    if comis_sim and ads_sim:
                        print("File contains both COMIS and ADS Simulation objects=" + full_file_name)
                        print("Please contact EnergyPlus Support (energyplus-support@gard.com) for help in transitioning this file.")
                        exit_because_bad_file = True
                        break
                    
                    var no_version = True
                    for num in range(context.get_num_idf_records()):
                        if context.make_upper_case(idf_records[num].name) != "VERSION":
                            continue
                        no_version = False
                        break
                    
                    for num in range(context.get_num_idf_records()):
                        var comments = context.get_comments()
                        for xcount in range(idf_records[num].commt_s, idf_records[num].commt_e + 1):
                            if xcount == idf_records[num].commt_e:
                                pass
                        
                        if no_version and num == 0:
                            var nw_num_args: Int
                            var nw_aor_n_temp: List[Bool]
                            var nw_req_fld_temp: List[Bool]
                            var nw_obj_min_flds: Int
                            var nw_fld_names_temp: List[String]
                            var nw_fld_defaults_temp: List[String]
                            var nw_fld_units_temp: List[String]
                            (nw_num_args, nw_aor_n_temp, nw_req_fld_temp, nw_obj_min_flds, nw_fld_names_temp, nw_fld_defaults_temp, nw_fld_units_temp) = \
                                context.get_new_object_def_in_idd("VERSION")
                            out_args[0] = "2.1"
                            var cur_args = 1
                            context.write_out_idf_lines_as_comments(
                                context.get_auditf(), "VERSION", cur_args, out_args,
                                nw_fld_names_temp, nw_fld_units_temp
                            )
                        
                        var obj_upper = context.make_upper_case(idf_records[num].name.strip())
                        if obj_upper == "SKY RADIANCE DISTRIBUTION":
                            continue
                        if obj_upper == "AIRFLOW MODEL":
                            continue
                        if obj_upper == "GENERATOR:FC:BATTERY DATA":
                            continue
                        if obj_upper == "WATER HEATER:SIMPLE":
                            continue
                        
                        var object_name = idf_records[num].name
                        var obj_def = context.get_object_def()
                        
                        if context.find_item_in_list(object_name, obj_def.name) != 0:
                            var num_args: Int
                            var aor_n_temp: List[Bool]
                            var req_fld_temp: List[Bool]
                            var obj_min_flds: Int
                            var fld_names_temp: List[String]
                            var fld_defaults_temp: List[String]
                            var fld_units_temp: List[String]
                            (num_args, aor_n_temp, req_fld_temp, obj_min_flds, fld_names_temp, fld_defaults_temp, fld_units_temp) = \
                                context.get_object_def_in_idd(object_name)
                            
                            var num_alphas = idf_records[num].num_alphas
                            var num_numbers = idf_records[num].num_numbers
                            for i in range(num_alphas):
                                alphas[i] = idf_records[num].alphas[i]
                            for i in range(num_numbers):
                                numbers[i] = idf_records[num].numbers[i]
                            
                            cur_args = num_alphas + num_numbers
                            for i in range(max_total_args):
                                in_args[i] = ""
                                out_args[i] = ""
                            
                            var na = 0
                            var nn = 0
                            for arg in range(cur_args):
                                if aor_n_temp[arg]:
                                    in_args[arg] = alphas[na]
                                    na += 1
                                else:
                                    in_args[arg] = str(numbers[nn])
                                    nn += 1
                        
                        var nodiff = True
                        var diff_min_fields = False
                        var written = False
                    
                    if context.get_num_idf_records() > 0:
                        pass
                
                else:
                    context.process_rvi_mvi_files(file_name_path, "rvi")
                    context.process_rvi_mvi_files(file_name_path, "mvi")
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
    
    return end_of_file
