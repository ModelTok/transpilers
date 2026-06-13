from math import isnan, copysign

# EXTERNAL DEPS (to wire in glue):
# - r64: type alias for Float64 (from DataPrecisionGlobals)
# - isnan: function to check for NaN (from math)

fn r64_trim_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var string: String
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var e_pos: Int = string.find("E")
    var e_string: String
    if e_pos >= 0:
        e_string = string[e_pos:]
        var spaces = String(" ") * (len(string) - e_pos)
        string = string[0:e_pos] + spaces
    else:
        e_string = " "
    
    var dot_pos: Int = string.find(".")
    var s_len: Int = len(string.rstrip())
    
    var include_dot: Bool = sig_digits > 0 or e_string != " "
    
    if include_dot:
        var end: Int = min(dot_pos + sig_digits + 1, s_len)
        string = string[0:end] + e_string
    else:
        string = string[0:dot_pos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn r_trim_sig_digits(real_value: Float32, sig_digits: Int) -> String:
    var string: String
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var e_pos: Int = string.find("E")
    var e_string: String
    if e_pos >= 0:
        e_string = string[e_pos:]
        var spaces = String(" ") * (len(string) - e_pos)
        string = string[0:e_pos] + spaces
    else:
        e_string = " "
    
    var dot_pos: Int = string.find(".")
    var s_len: Int = len(string.rstrip())
    
    var include_dot: Bool = sig_digits > 0 or e_string != " "
    
    if include_dot:
        var end: Int = min(dot_pos + sig_digits + 1, s_len)
        string = string[0:end] + e_string
    else:
        string = string[0:dot_pos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn i_trim_sig_digits(integer_value: Int, sig_digits: Int = 0) -> String:
    var string: String = str(integer_value)
    return string.lstrip()


fn r64_round_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var digit_char: String = "01234567890"
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var e_pos: Int = string.find("E")
    var e_string: String
    if e_pos >= 0:
        e_string = string[e_pos:]
        var spaces = String(" ") * (len(string) - e_pos)
        string = string[0:e_pos] + spaces
    else:
        e_string = " "
    
    var dot_pos: Int = string.find(".")
    var test_char_idx: Int = dot_pos + sig_digits + 1
    var test_char: String
    if test_char_idx < len(string):
        test_char = string[test_char_idx]
    else:
        test_char = " "
    
    var t_pos: Int = digit_char.find(test_char) + 1
    
    var s_pos: Int
    if sig_digits == 0:
        s_pos = dot_pos - 1
    else:
        s_pos = dot_pos + sig_digits
    
    if t_pos > 5:
        var chars = string.split("")
        var char_2_rep: String = chars[s_pos]
        var n_pos: Int = digit_char.find(char_2_rep) + 1
        
        if n_pos < len(digit_char):
            chars[s_pos] = digit_char[n_pos]
        
        while n_pos == 10:
            if sig_digits == 1:
                var tc: String = chars[s_pos - 2]
                if tc == ".":
                    tc = chars[s_pos - 3]
                    s_pos -= 2
                if tc == " ":
                    tc = "0"
                var t_pos_1: Int = digit_char.find(tc) + 1
                if t_pos_1 < len(digit_char):
                    chars[s_pos - 2] = digit_char[t_pos_1]
            else:
                var tc: String = chars[s_pos - 1]
                if tc == ".":
                    tc = chars[s_pos - 2]
                    s_pos -= 1
                if tc == " ":
                    tc = "0"
                var t_pos_1: Int = digit_char.find(tc) + 1
                if t_pos_1 < len(digit_char):
                    chars[s_pos - 1] = digit_char[t_pos_1]
            
            s_pos -= 1
            n_pos = t_pos_1
        
        string = "".join(chars)
    
    var s_len: Int = len(string.rstrip())
    var include_dot: Bool = sig_digits > 0 or e_string != " "
    
    if include_dot:
        var end: Int = min(dot_pos + sig_digits + 1, s_len)
        string = string[0:end] + e_string
    else:
        string = string[0:dot_pos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn r_round_sig_digits(real_value: Float32, sig_digits: Int) -> String:
    var digit_char: String = "01234567890"
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var e_pos: Int = string.find("E")
    var e_string: String
    if e_pos >= 0:
        e_string = string[e_pos:]
        var spaces = String(" ") * (len(string) - e_pos)
        string = string[0:e_pos] + spaces
    else:
        e_string = " "
    
    var dot_pos: Int = string.find(".")
    var test_char_idx: Int = dot_pos + sig_digits + 1
    var test_char: String
    if test_char_idx < len(string):
        test_char = string[test_char_idx]
    else:
        test_char = " "
    
    var t_pos: Int = digit_char.find(test_char) + 1
    
    var s_pos: Int
    if sig_digits == 0:
        s_pos = dot_pos - 1
    else:
        s_pos = dot_pos + sig_digits
    
    if t_pos > 5:
        var chars = string.split("")
        var char_2_rep: String = chars[s_pos]
        var n_pos: Int = digit_char.find(char_2_rep) + 1
        
        if n_pos < len(digit_char):
            chars[s_pos] = digit_char[n_pos]
        
        while n_pos == 10:
            if sig_digits == 1:
                var tc: String = chars[s_pos - 2]
                if tc == ".":
                    tc = chars[s_pos - 3]
                    s_pos -= 2
                if tc == " ":
                    tc = "0"
                var t_pos_1: Int = digit_char.find(tc) + 1
                if t_pos_1 < len(digit_char):
                    chars[s_pos - 2] = digit_char[t_pos_1]
            else:
                var tc: String = chars[s_pos - 1]
                if tc == ".":
                    tc = chars[s_pos - 2]
                    s_pos -= 1
                if tc == " ":
                    tc = "0"
                var t_pos_1: Int = digit_char.find(tc) + 1
                if t_pos_1 < len(digit_char):
                    chars[s_pos - 1] = digit_char[t_pos_1]
            
            s_pos -= 1
            n_pos = t_pos_1
        
        string = "".join(chars)
    
    var s_len: Int = len(string.rstrip())
    var include_dot: Bool = sig_digits > 0 or e_string != " "
    
    if include_dot:
        var end: Int = min(dot_pos + sig_digits + 1, s_len)
        string = string[0:end] + e_string
    else:
        string = string[0:dot_pos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn i_round_sig_digits(integer_value: Int, sig_digits: Int = 0) -> String:
    var string: String = str(integer_value)
    return string.lstrip()


fn d_safe_divide(a: Float64, b: Float64) -> Float64:
    var SMALL: Float64 = 1e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        return a / copysign(SMALL, b)


fn r_safe_divide(a: Float32, b: Float32) -> Float32:
    var SMALL: Float32 = 1e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        return a / copysign(SMALL, b)
