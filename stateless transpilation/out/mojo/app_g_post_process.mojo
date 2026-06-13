from pathlib import Path
import sys

alias MAX_NAME_LENGTH = 200
alias LONG_STRING = 20000
alias EOF = -1
alias ESO_CSV = 1
alias METER_CSV = 2
alias NUM_FILES_AVG = 4
alias ERR_FH = 200

struct AppState:
    var file_name: String
    var file_root: String
    var err_file: String
    var errors_exist: Bool
    var use_htm_not_html: Bool
    var err_fh: FileHandle

    fn __init__(inout self):
        self.file_name = ""
        self.file_root = ""
        self.err_file = ""
        self.errors_exist = False
        self.use_htm_not_html = False
        self.err_fh = FileHandle()

struct FileHandle:
    var file: AnyPointer[Int8]
    var is_open: Bool
    
    fn __init__(inout self):
        self.file = AnyPointer[Int8]()
        self.is_open = False

fn scan(string_val: String, set_val: String) -> Int:
    for i in range(len(string_val)):
        for char in set_val:
            if string_val[i] == char:
                return i + 1
    return 0

fn verify(string_val: String, set_val: String) -> Int:
    for i in range(len(string_val)):
        var found = False
        for char in set_val:
            if string_val[i] == char:
                found = True
                break
        if not found:
            return i + 1
    return 0

fn make_upper_case(input_string: String) -> String:
    let lower_case = "abcdefghijklmnopqrstuvwxyz"
    let upper_case = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    var result = String()
    let pos = scan(input_string, lower_case)
    
    if pos != 0:
        let trimmed = input_string.rstrip()
        for i in range(len(trimmed)):
            let char = trimmed[i]
            var found_pos = 0
            for j in range(len(lower_case)):
                if lower_case[j] == char:
                    found_pos = j + 1
                    break
            if found_pos != 0:
                result += upper_case[found_pos - 1]
            else:
                result += char
        return result
    else:
        return input_string.rstrip()

fn get_file_root(string_in: String, inout state: AppState) -> String:
    var dot_pos = 0
    var dash_g_pos = 0
    var slash_pos = 0
    var extension_is_valid = False
    
    state.use_htm_not_html = False
    var string_out = string_in
    var string_in_upper = make_upper_case(string_in) + "                 "
    string_in_upper = string_in_upper[:MAX_NAME_LENGTH + 10]
    
    var slash_pos_temp = string_in_upper.rfind("\\")
    if slash_pos_temp == -1:
        slash_pos_temp = string_in_upper.rfind("/")
        if slash_pos_temp != -1:
            slash_pos = slash_pos_temp + 1
    else:
        slash_pos = slash_pos_temp + 1
    
    if slash_pos_temp == -1:
        slash_pos = 0
    
    var dot_pos_temp = string_in_upper.rfind(".")
    if dot_pos_temp == -1:
        dot_pos = 0
    else:
        dot_pos = dot_pos_temp + 1
    
    if dot_pos < slash_pos:
        dot_pos = 0
    
    if dot_pos != 0:
        if string_in_upper[dot_pos:dot_pos + 3] == "CSV":
            extension_is_valid = True
        elif string_in_upper[dot_pos:dot_pos + 4] == "HTML":
            extension_is_valid = True
        elif string_in_upper[dot_pos:dot_pos + 3] == "HTM":
            state.use_htm_not_html = True
            extension_is_valid = True
    
    if extension_is_valid or dot_pos == 0:
        dash_g_pos = 0
        for pattern in ["-G000", "-G090", "-G180", "-G270"]:
            let temp = string_in_upper.rfind(pattern)
            if temp != -1:
                dash_g_pos = temp + 1
                break
        
        if dash_g_pos < slash_pos:
            dash_g_pos = 0
        
        if dash_g_pos > 1:
            string_out = string_out[:dash_g_pos - 2]
    
    return string_out

fn same_string(test_string1: String, test_string2: String) -> Bool:
    if len(test_string1.rstrip()) != len(test_string2.rstrip()):
        return False
    
    let upper1 = make_upper_case(test_string1)
    let upper2 = make_upper_case(test_string2)
    return upper1 == upper2

fn is_content_number(string_in: String) -> Bool:
    if len(string_in.rstrip()) >= 1:
        if verify(string_in.rstrip().lstrip(), "-0123456789.E+") == 0:
            return True
    return False

fn string_to_real(string_in: String) -> Float64:
    if len(string_in.rstrip()) >= 1:
        if verify(string_in.rstrip(), "-0123456789.E+") == 0:
            try:
                return atof(string_in)
            except:
                return 0.0
    return 0.0

fn get_point_and_exponent(string_in: String) -> Tuple[Int, Int, Bool]:
    var digits_before_out = 0
    var digits_after_out = 0
    var exponent_out = False
    
    if verify(string_in.rstrip(), "-0123456789.E+") == 0:
        let copy_string_in = string_in.lstrip()
        var pos_e = -1
        var pos_pt = -1
        
        for i in range(len(copy_string_in)):
            if copy_string_in[i] == 'E':
                pos_e = i
                break
            if copy_string_in[i] == '.':
                pos_pt = i
        
        if pos_pt >= 0:
            digits_before_out = pos_pt
        else:
            digits_before_out = 0
        
        if pos_e >= 0:
            exponent_out = True
            if pos_e > pos_pt:
                digits_after_out = (pos_e - pos_pt) - 1
            else:
                digits_after_out = 0
        else:
            let num_length = len(copy_string_in.rstrip())
            if num_length > pos_pt and pos_pt >= 0:
                digits_after_out = num_length - pos_pt - 1
            else:
                digits_after_out = 0
            exponent_out = False
    
    return Tuple(digits_before_out, digits_after_out, exponent_out)

fn int_to_str(int_in: Int) -> String:
    return str(int_in).rstrip()

fn real_to_str(real_in: Float64, digits_before: Int, digits_after: Int, use_exponent: Bool) -> String:
    var format_str = ""
    if use_exponent:
        format_str = "{:." + str(digits_after) + "E}"
    else:
        format_str = "{:." + str(digits_after) + "f}"
    
    return format(format_str, real_in).rstrip()

fn out_and_err_file(string_in: String, inout state: AppState, int_in: Int = 0, has_int: Bool = False):
    var msg = ""
    if has_int:
        msg = string_in + String(int_in)
    else:
        msg = string_in
    
    print(msg)
    state.errors_exist = True

fn out_msg(string_in: String, inout state: AppState):
    print(string_in)

fn line_without_time_stamp(line_in: String) -> String:
    var line_out = line_in
    let len_line = len(line_in)
    
    for i in range(1, len_line - 3):
        if line_out[i] == ':':
            if i + 3 < len_line and line_out[i + 3] == ':':
                if verify(line_out[i - 2:i + 6], ":0123456789") == 0:
                    line_out = line_out[:i - 2] + "        " + line_out[i + 6:]
            else:
                if i - 2 >= 0 and line_out[i - 2] != ' ':
                    if verify(line_out[i - 2:i + 3], ":0123456789") == 0:
                        line_out = line_out[:i - 2] + "     " + line_out[i + 3:]
                elif i - 1 >= 0:
                    if verify(line_out[i - 1:i + 3], ":0123456789") == 0:
                        line_out = line_out[:i - 1] + "    " + line_out[i + 3:]
    
    return line_out

fn are_lines_same_except_time(in_lines: List[String]) -> Bool:
    var in_copy = List[String]()
    for i in range(NUM_FILES_AVG):
        in_copy.append(line_without_time_stamp(in_lines[i]))
    
    for i in range(1, NUM_FILES_AVG):
        if in_copy[i] != in_copy[0]:
            return False
    return True

fn average_html_files(root_file: String, inout state: AppState):
    var in_file = List[String]()
    var out_file = ""
    
    if not state.use_htm_not_html:
        out_msg("      Processing HTML files", state)
        in_file.append(root_file.rstrip() + "-G000Table.HTML")
        in_file.append(root_file.rstrip() + "-G090Table.HTML")
        in_file.append(root_file.rstrip() + "-G180Table.HTML")
        in_file.append(root_file.rstrip() + "-G270Table.HTML")
        out_file = root_file.rstrip() + "-GAVGTable.HTML"
    else:
        out_msg("      Processing HTM files", state)
        in_file.append(root_file.rstrip() + "-G000Table.HTM")
        in_file.append(root_file.rstrip() + "-G090Table.HTM")
        in_file.append(root_file.rstrip() + "-G180Table.HTM")
        in_file.append(root_file.rstrip() + "-G270Table.HTM")
        out_file = root_file.rstrip() + "-GAVGTable.HTM"
    
    let out_file_no_ext = root_file.rstrip() + "-GAVGTable"
    
    var file_missing = False
    for i in range(NUM_FILES_AVG):
        if not Path(in_file[i]).exists():
            out_and_err_file("    ERROR File missing: " + in_file[i], state)
            file_missing = True
    
    if file_missing:
        return

fn average_csv_files(kind_of_csv: Int, root_file: String, inout state: AppState):
    var in_file = List[String]()
    var out_file = ""
    
    if kind_of_csv == ESO_CSV:
        out_msg("      Processing main CSV files", state)
        in_file.append(root_file.rstrip() + "-G000.CSV")
        in_file.append(root_file.rstrip() + "-G090.CSV")
        in_file.append(root_file.rstrip() + "-G180.CSV")
        in_file.append(root_file.rstrip() + "-G270.CSV")
        out_file = root_file.rstrip() + "-GAVG.CSV"
    else:
        out_msg("      Processing meter CSV files", state)
        in_file.append(root_file.rstrip() + "-G000Meter.CSV")
        in_file.append(root_file.rstrip() + "-G090Meter.CSV")
        in_file.append(root_file.rstrip() + "-G180Meter.CSV")
        in_file.append(root_file.rstrip() + "-G270Meter.CSV")
        out_file = root_file.rstrip() + "-GAVGMeter.CSV"
    
    var file_missing = False
    for i in range(NUM_FILES_AVG):
        if not Path(in_file[i]).exists():
            out_and_err_file("    ERROR File missing: " + in_file[i], state)
            file_missing = True
    
    if file_missing:
        return

fn main():
    var state = AppState()
    
    var file_name = ""
    if len(sys.argv) > 1:
        file_name = sys.argv[1]
    
    state.file_name = file_name
    state.file_root = get_file_root(state.file_name, state)
    state.err_file = state.file_root.rstrip() + "-AppGErr.txt"
    
    out_msg("  Started AppGPostProcess", state)
    out_msg("      File name[" + state.file_name + "]", state)
    out_msg("      File root[" + state.file_root + "]", state)
    
    average_html_files(state.file_root, state)
    average_csv_files(METER_CSV, state.file_root, state)
    average_csv_files(ESO_CSV, state.file_root, state)
    
    out_msg("  Complete", state)
    
    if state.errors_exist:
        out_msg("  ", state)
        out_msg("Errors were found.", state)
        print("Press the ENTER key to exit.")

if __name__ == "__main__":
    main()
