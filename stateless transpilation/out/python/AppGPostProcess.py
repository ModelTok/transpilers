import sys
import os

# EXTERNAL DEPS (to wire in glue):
# None - uses only standard library

MAX_NAME_LENGTH = 200
LONG_STRING = 20000
EOF = -1
ESO_CSV = 1
METER_CSV = 2
NUM_FILES_AVG = 4
ERR_FH = 200

class AppState:
    def __init__(self):
        self.file_name = ""
        self.file_root = ""
        self.err_file = ""
        self.errors_exist = False
        self.use_htm_not_html = False
        self.err_fh = None

def scan(string_val, set_val):
    for i, char in enumerate(string_val):
        if char in set_val:
            return i + 1
    return 0

def verify(string_val, set_val):
    for i, char in enumerate(string_val):
        if char not in set_val:
            return i + 1
    return 0

def make_upper_case(input_string):
    lower_case = 'abcdefghijklmnopqrstuvwxyz'
    upper_case = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    
    pos = scan(input_string, lower_case)
    
    if pos != 0:
        length_input_string = len(input_string.rstrip())
        result_chars = []
        for count in range(length_input_string):
            char = input_string[count]
            pos = scan(lower_case, char)
            if pos != 0:
                result_chars.append(upper_case[pos - 1])
            else:
                result_chars.append(char)
        return ''.join(result_chars).rstrip()
    else:
        return input_string.rstrip()

def get_file_root(string_in, state):
    dot_pos = 0
    dash_g_pos = 0
    slash_pos = 0
    extension_is_valid = False
    
    state.use_htm_not_html = False
    string_out = string_in
    string_in_upper = (make_upper_case(string_in) + '                 ')[:MAX_NAME_LENGTH + 10]
    
    slash_pos = string_in_upper.rfind('\\')
    if slash_pos == -1:
        slash_pos = string_in_upper.rfind('/')
        if slash_pos != -1:
            slash_pos += 1
    else:
        slash_pos += 1
    
    if slash_pos == -1:
        slash_pos = 0
    
    dot_pos_temp = string_in_upper.rfind('.')
    if dot_pos_temp == -1:
        dot_pos = 0
    else:
        dot_pos = dot_pos_temp + 1
    
    if dot_pos < slash_pos:
        dot_pos = 0
    
    if dot_pos != 0:
        if string_in_upper[dot_pos:dot_pos + 3] == 'CSV':
            extension_is_valid = True
        elif string_in_upper[dot_pos:dot_pos + 4] == 'HTML':
            extension_is_valid = True
        elif string_in_upper[dot_pos:dot_pos + 3] == 'HTM':
            state.use_htm_not_html = True
            extension_is_valid = True
    
    if extension_is_valid or dot_pos == 0:
        dash_g_pos = 0
        for pattern in ['-G000', '-G090', '-G180', '-G270']:
            temp = string_in_upper.rfind(pattern)
            if temp != -1:
                dash_g_pos = temp + 1
                break
        
        if dash_g_pos < slash_pos:
            dash_g_pos = 0
        
        if dash_g_pos > 1:
            string_out = string_out[:dash_g_pos - 2]
    
    return string_out

def same_string(test_string1, test_string2):
    if len(test_string1.rstrip()) != len(test_string2.rstrip()):
        return False
    
    upper1 = make_upper_case(test_string1)
    upper2 = make_upper_case(test_string2)
    return upper1 == upper2

def is_content_number(string_in):
    if len(string_in.rstrip()) >= 1:
        if verify(string_in.rstrip().lstrip(), '-0123456789.E+') == 0:
            return True
    return False

def string_to_real(string_in):
    if len(string_in.rstrip()) >= 1:
        if verify(string_in.rstrip(), '-0123456789.E+') == 0:
            try:
                return float(string_in)
            except:
                return 0.0
    return 0.0

def get_point_and_exponent(string_in):
    digits_before_out = 0
    digits_after_out = 0
    exponent_out = False
    
    if verify(string_in.rstrip(), '-0123456789.E+') == 0:
        copy_string_in = string_in.lstrip()
        pos_e = copy_string_in.find('E')
        pos_pt = copy_string_in.find('.')
        
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
            num_length = len(copy_string_in.rstrip())
            if num_length > pos_pt and pos_pt >= 0:
                digits_after_out = num_length - pos_pt - 1
            else:
                digits_after_out = 0
            exponent_out = False
    
    return digits_before_out, digits_after_out, exponent_out

def int_to_str(int_in):
    return str(int_in).strip()

def real_to_str(real_in, digits_before, digits_after, use_exponent):
    if use_exponent:
        return f"{real_in:.{digits_after}E}"
    else:
        return f"{real_in:.{digits_after}f}"

def out_and_err_file(string_in, state, int_in=None):
    if int_in is not None:
        msg = f"{string_in}{int_in:6d}"
    else:
        msg = string_in
    
    print(msg)
    if state.err_fh:
        state.err_fh.write(msg + '\n')
    state.errors_exist = True

def out_msg(string_in, state):
    print(string_in)
    if state.err_fh:
        state.err_fh.write(string_in + '\n')

def line_without_time_stamp(line_in):
    line_out = list(line_in)
    
    for i in range(1, len(line_in) - 3):
        if line_out[i] == ':':
            if i + 3 < len(line_out) and line_out[i + 3] == ':':
                if verify(''.join(line_out[i-2:i+6]), ':0123456789') == 0:
                    line_out = line_out[:i-2] + list('        ') + line_out[i+6:]
            else:
                if i - 2 >= 0 and line_out[i - 2] != ' ':
                    if verify(''.join(line_out[i-2:i+3]), ':0123456789') == 0:
                        line_out = line_out[:i-2] + list('     ') + line_out[i+3:]
                elif i - 1 >= 0:
                    if verify(''.join(line_out[i-1:i+3]), ':0123456789') == 0:
                        line_out = line_out[:i-1] + list('    ') + line_out[i+3:]
    
    return ''.join(line_out)

def are_lines_same_except_time(in_lines):
    in_copy = [line_without_time_stamp(in_lines[i]) for i in range(NUM_FILES_AVG)]
    
    for i in range(1, NUM_FILES_AVG):
        if in_copy[i] != in_copy[0]:
            return False
    return True

def average_html_files(root_file, state):
    if not state.use_htm_not_html:
        out_msg("      Processing HTML files", state)
        in_file = [
            root_file.rstrip() + '-G000Table.HTML',
            root_file.rstrip() + '-G090Table.HTML',
            root_file.rstrip() + '-G180Table.HTML',
            root_file.rstrip() + '-G270Table.HTML'
        ]
        out_file = root_file.rstrip() + '-GAVGTable.HTML'
    else:
        out_msg("      Processing HTM files", state)
        in_file = [
            root_file.rstrip() + '-G000Table.HTM',
            root_file.rstrip() + '-G090Table.HTM',
            root_file.rstrip() + '-G180Table.HTM',
            root_file.rstrip() + '-G270Table.HTM'
        ]
        out_file = root_file.rstrip() + '-GAVGTable.HTM'
    
    out_file_no_ext = root_file.rstrip() + '-GAVGTable'
    
    file_missing = False
    file_handles = []
    for i in range(NUM_FILES_AVG):
        if not os.path.exists(in_file[i]):
            out_and_err_file(f"    ERROR File missing: {in_file[i]}", state)
            file_missing = True
    
    if file_missing:
        return
    
    for i in range(NUM_FILES_AVG):
        file_handles.append(open(in_file[i], 'r'))
    
    out_fh = open(out_file, 'w')
    
    line_count = 0
    any_file_end = False
    
    while not any_file_end:
        line_count += 1
        do_write_line = False
        
        line_in = []
        read_status = []
        for i in range(NUM_FILES_AVG):
            try:
                line = file_handles[i].readline()
                if not line:
                    line_in.append('')
                    read_status.append(EOF)
                    any_file_end = True
                else:
                    line_in.append(line.rstrip('\n\r'))
                    read_status.append(0)
            except:
                line_in.append('')
                read_status.append(EOF)
                any_file_end = True
        
        lines_match = True
        for i in range(1, NUM_FILES_AVG):
            if not same_string(line_in[i], line_in[0]):
                lines_match = False
                break
        
        if lines_match:
            line_out = line_in[0]
            do_write_line = True
        else:
            if are_lines_same_except_time(line_in):
                line_out = line_in[0]
                do_write_line = True
            else:
                is_cell = True
                end_of_cell = [0] * NUM_FILES_AVG
                for i in range(NUM_FILES_AVG):
                    if not line_in[i].startswith('    <td align="right">'):
                        is_cell = False
                        break
                    end_of_cell_pos = line_in[i].find('</td>')
                    if end_of_cell_pos == -1:
                        is_cell = False
                        break
                    end_of_cell[i] = end_of_cell_pos
                
                if is_cell:
                    is_number = True
                    cell_content = [''] * NUM_FILES_AVG
                    for i in range(NUM_FILES_AVG):
                        cell_content[i] = line_in[i][22:end_of_cell[i]].strip()
                        if not is_content_number(cell_content[i]):
                            is_number = False
                            break
                        if same_string('-', cell_content[i]):
                            is_number = False
                            break
                    
                    if is_number:
                        sum_read_value = 0.0
                        read_value = [0.0] * NUM_FILES_AVG
                        any_have_exponent = False
                        max_digits_after = 0
                        max_digits_before = 0
                        
                        for i in range(NUM_FILES_AVG):
                            read_value[i] = string_to_real(cell_content[i])
                            cur_digit_before, cur_digit_after, cur_has_exponent = get_point_and_exponent(cell_content[i])
                            if cur_has_exponent:
                                any_have_exponent = True
                            if cur_digit_after > max_digits_after:
                                max_digits_after = cur_digit_after
                            if cur_digit_before > max_digits_before:
                                max_digits_before = cur_digit_before
                            sum_read_value += read_value[i]
                        
                        line_out = '    <td align="right">'
                        if max_digits_before > 0 or max_digits_after > 0:
                            line_out += real_to_str(sum_read_value / NUM_FILES_AVG, max_digits_before, max_digits_after, any_have_exponent)
                        line_out += '</td>'
                        do_write_line = True
                    else:
                        line_out = '    <td align="right">'
                        for i in range(NUM_FILES_AVG):
                            line_out += '{' + cell_content[i].strip() + '}'
                        line_out += '</td>'
                        do_write_line = True
                else:
                    if line_in[0].startswith('<title>'):
                        line_out = '<title>' + out_file_no_ext.rstrip()
                        do_write_line = True
                    elif line_in[0].startswith('<p>Building: <b>'):
                        line_out = '<p>Building: <b>' + out_file_no_ext.rstrip() + '</b></p>'
                        do_write_line = True
                    else:
                        out_and_err_file(" ERROR - Unexpected non-matching line in the HTML files on line: ", state, line_count)
                        out_fh.write('</tr>\n')
                        out_fh.write('</table>\n')
                        num_lines_skipped = 0
                        for i in range(NUM_FILES_AVG):
                            while True:
                                if line_in[i].startswith('</table>'):
                                    break
                                try:
                                    line_in[i] = file_handles[i].readline().rstrip('\n\r')
                                    num_lines_skipped += 1
                                    if not line_in[i]:
                                        any_file_end = True
                                        break
                                except:
                                    any_file_end = True
                                    break
                            out_and_err_file("           For file: ", state, i + 1)
                            out_and_err_file("             skipped lines: ", state, num_lines_skipped)
                
                if line_in[0].startswith('<p>Report:'):
                    out_and_err_file(" ERROR - Report name not identical in the HTML files on line: ", state, line_count)
                
                if line_in[0].startswith('<p>For:'):
                    out_and_err_file(" ERROR - The reported FOR: name is not identical in the HTML files on line: ", state, line_count)
                
                line_length = len(line_in[0].rstrip())
                if line_length >= 12:
                    if line_in[0][line_length - 12:] == '</b><br><br>':
                        out_and_err_file(" ERROR - Subtable name is not identical in the HTML files on line: ", state, line_count)
        
        if do_write_line:
            out_fh.write(line_out + '\n')
        
        if any_file_end:
            break
    
    out_fh.close()
    for fh in file_handles:
        fh.close()

def average_csv_files(kind_of_csv, root_file, state):
    if kind_of_csv == ESO_CSV:
        out_msg("      Processing main CSV files", state)
        in_file = [
            root_file.rstrip() + '-G000.CSV',
            root_file.rstrip() + '-G090.CSV',
            root_file.rstrip() + '-G180.CSV',
            root_file.rstrip() + '-G270.CSV'
        ]
        out_file = root_file.rstrip() + '-GAVG.CSV'
    else:
        out_msg("      Processing meter CSV files", state)
        in_file = [
            root_file.rstrip() + '-G000Meter.CSV',
            root_file.rstrip() + '-G090Meter.CSV',
            root_file.rstrip() + '-G180Meter.CSV',
            root_file.rstrip() + '-G270Meter.CSV'
        ]
        out_file = root_file.rstrip() + '-GAVGMeter.CSV'
    
    file_missing = False
    file_handles = []
    for i in range(NUM_FILES_AVG):
        if not os.path.exists(in_file[i]):
            out_and_err_file(f"    ERROR File missing: {in_file[i]}", state)
            file_missing = True
    
    if file_missing:
        return
    
    for i in range(NUM_FILES_AVG):
        file_handles.append(open(in_file[i], 'r'))
    
    out_fh = open(out_file, 'w')
    
    line_count = 0
    any_file_end = False
    first_line = True
    read_status = [0] * NUM_FILES_AVG
    
    while not any_file_end:
        line_count += 1
        
        line_in = []
        for i in range(NUM_FILES_AVG):
            try:
                line = file_handles[i].readline()
                if not line:
                    line_in.append('')
                    read_status[i] = EOF
                    any_file_end = True
                else:
                    line_in.append(line.rstrip('\n\r'))
                    read_status[i] = 0
            except:
                line_in.append('')
                read_status[i] = EOF
                any_file_end = True
        
        if first_line:
            lines_match = True
            for i in range(1, NUM_FILES_AVG):
                if not same_string(line_in[i], line_in[0]):
                    lines_match = False
            
            if lines_match:
                out_fh.write(line_in[-1] + '\n')
            else:
                out_and_err_file(" ERROR - Heading lines in the CSV files are not identical.", state)
            
            first_line = False
            continue
        
        last_comma = [False] * NUM_FILES_AVG
        any_last_comma = False
        word_start = [0] * NUM_FILES_AVG
        line_out = ''
        first_column = True
        fld_string = ''
        
        while True:
            sum_read_value = 0.0
            any_have_exponent = False
            max_digits_after = 0
            max_digits_before = 0
            
            for i in range(NUM_FILES_AVG):
                comma_pos = line_in[i].find(',', word_start[i])
                if comma_pos > 0:
                    word_end = comma_pos - 1
                    fld_string = line_in[i][word_start[i]:word_end + 1].strip()
                    word_start[i] = comma_pos + 1
                else:
                    fld_string = line_in[i][word_start[i]:].strip()
                    last_comma[i] = True
                    any_last_comma = True
                
                read_value = string_to_real(fld_string)
                cur_digit_before, cur_digit_after, cur_has_exponent = get_point_and_exponent(fld_string)
                if cur_has_exponent:
                    any_have_exponent = True
                if cur_digit_after > max_digits_after:
                    max_digits_after = cur_digit_after
                if cur_digit_before > max_digits_before:
                    max_digits_before = cur_digit_before
                sum_read_value += read_value
            
            if first_column:
                for i in range(1, NUM_FILES_AVG):
                    if not same_string(line_in[i].split(',')[0], line_in[0].split(',')[0]):
                        out_and_err_file(" ERROR - Date/Time is not identical in the CSV files on line: ", state, line_count)
                line_out = fld_string.rstrip()
                first_column = False
            else:
                if max_digits_before > 0 or max_digits_after > 0:
                    line_out += ',' + real_to_str(sum_read_value / NUM_FILES_AVG, max_digits_before, max_digits_after, any_have_exponent).strip()
                else:
                    line_out += ','
            
            if any_last_comma:
                break
        
        out_fh.write(line_out + '\n')
        for i in range(NUM_FILES_AVG):
            if not last_comma[i]:
                out_and_err_file(" ERROR - Number of commas in the CSV files are not identical on line: ", state, line_count)
        
        if any_file_end:
            break
    
    for i in range(NUM_FILES_AVG):
        if read_status[i] != EOF:
            out_and_err_file(" ERROR - Number of lines in the CSV files are not identical. ", state, read_status[i])
    
    out_fh.close()
    for fh in file_handles:
        fh.close()

def main():
    state = AppState()
    
    if len(sys.argv) > 1:
        state.file_name = sys.argv[1]
    else:
        state.file_name = ""
    
    state.file_root = get_file_root(state.file_name, state)
    state.err_file = state.file_root.rstrip() + '-AppGErr.txt'
    
    state.err_fh = open(state.err_file, 'w')
    
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
        input()
    
    state.err_fh.close()

if __name__ == "__main__":
    main()
