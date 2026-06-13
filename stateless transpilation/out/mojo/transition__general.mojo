from math import isnan, copysign, fabs


fn r_trim_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var digit_char = "01234567890"
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var epos = string.find("E")
    var estring: String
    if epos >= 0:
        estring = string[epos:]
        var new_string = string[:epos]
        for _ in range(len(string) - epos):
            new_string += " "
        string = new_string
    else:
        estring = " "
    
    var dotpos = string.find(".")
    var slen = len(string.rstrip())
    
    var include_dot = sig_digits > 0 or estring != " "
    
    if include_dot:
        var end_idx = min(dotpos + sig_digits + 1, slen)
        string = string[:end_idx] + estring
    else:
        string = string[:dotpos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn rd_trim_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var epos = string.find("E")
    var estring: String
    if epos >= 0:
        estring = string[epos:]
        var new_string = string[:epos]
        for _ in range(len(string) - epos):
            new_string += " "
        string = new_string
    else:
        estring = " "
    
    var dotpos = string.find(".")
    var slen = len(string.rstrip())
    
    var include_dot = sig_digits > 0 or estring != " "
    
    if include_dot:
        var end_idx = min(dotpos + sig_digits + 1, slen)
        string = string[:end_idx] + estring
    else:
        string = string[:dotpos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn i_trim_sig_digits(integer_value: Int, sig_digits: Int = 0) -> String:
    var string = str(integer_value)
    return string.lstrip()


fn r_round_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var digit_char = "01234567890"
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var epos = string.find("E")
    var estring: String
    if epos >= 0:
        estring = string[epos:]
        var new_string = string[:epos]
        for _ in range(len(string) - epos):
            new_string += " "
        string = new_string
    else:
        estring = " "
    
    var dotpos = string.find(".")
    var test_char_idx = dotpos + sig_digits + 1
    var test_char: String
    if test_char_idx < len(string):
        test_char = string[test_char_idx:test_char_idx+1]
    else:
        test_char = " "
    
    var tpos = digit_char.find(test_char)
    if tpos >= 0:
        tpos += 1
    else:
        tpos = 0
    
    var spos: Int
    if sig_digits == 0:
        spos = dotpos - 1
    else:
        spos = dotpos + sig_digits
    
    if tpos > 5:
        var char2rep: String
        if spos < len(string):
            char2rep = string[spos:spos+1]
        else:
            char2rep = " "
        
        var npos = digit_char.find(char2rep)
        if npos >= 0:
            npos += 1
        else:
            npos = 0
        
        var new_string = string[:spos] + digit_char[npos:npos+1] + string[spos+1:]
        string = new_string
        
        while npos == 10:
            if sig_digits == 1:
                var test_char2: String
                if spos - 2 >= 0:
                    test_char2 = string[spos-2:spos-1]
                else:
                    test_char2 = " "
                
                if test_char2 == ".":
                    if spos - 3 >= 0:
                        test_char2 = string[spos-3:spos-2]
                    else:
                        test_char2 = " "
                    spos = spos - 2
                
                if test_char2 == " ":
                    test_char2 = "0"
                
                var tpos1 = digit_char.find(test_char2)
                if tpos1 >= 0:
                    tpos1 += 1
                else:
                    tpos1 = 0
                
                var new_str2 = string[:spos-2] + digit_char[tpos1:tpos1+1] + string[spos-1:]
                string = new_str2
            else:
                var test_char3: String
                if spos - 1 >= 0:
                    test_char3 = string[spos-1:spos]
                else:
                    test_char3 = " "
                
                if test_char3 == ".":
                    if spos - 2 >= 0:
                        test_char3 = string[spos-2:spos-1]
                    else:
                        test_char3 = " "
                    spos = spos - 1
                
                if test_char3 == " ":
                    test_char3 = "0"
                
                var tpos1 = digit_char.find(test_char3)
                if tpos1 >= 0:
                    tpos1 += 1
                else:
                    tpos1 = 0
                
                var new_str3 = string[:spos-1] + digit_char[tpos1:tpos1+1] + string[spos:]
                string = new_str3
            
            spos = spos - 1
            npos = tpos1
    
    var slen = len(string.rstrip())
    var include_dot = sig_digits > 0 or estring != " "
    
    if include_dot:
        var end_idx = min(dotpos + sig_digits + 1, slen)
        string = string[:end_idx] + estring
    else:
        string = string[:dotpos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn rd_round_sig_digits(real_value: Float64, sig_digits: Int) -> String:
    var digit_char = "01234567890"
    var string: String
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    var epos = string.find("E")
    var estring: String
    if epos >= 0:
        estring = string[epos:]
        var new_string = string[:epos]
        for _ in range(len(string) - epos):
            new_string += " "
        string = new_string
    else:
        estring = " "
    
    var dotpos = string.find(".")
    var test_char_idx = dotpos + sig_digits + 1
    var test_char: String
    if test_char_idx < len(string):
        test_char = string[test_char_idx:test_char_idx+1]
    else:
        test_char = " "
    
    var tpos = digit_char.find(test_char)
    if tpos >= 0:
        tpos += 1
    else:
        tpos = 0
    
    var spos: Int
    if sig_digits == 0:
        spos = dotpos - 1
    else:
        spos = dotpos + sig_digits
    
    if tpos > 5:
        var char2rep: String
        if spos < len(string):
            char2rep = string[spos:spos+1]
        else:
            char2rep = " "
        
        var npos = digit_char.find(char2rep)
        if npos >= 0:
            npos += 1
        else:
            npos = 0
        
        var new_string = string[:spos] + digit_char[npos:npos+1] + string[spos+1:]
        string = new_string
        
        while npos == 10:
            if sig_digits == 1:
                var test_char2: String
                if spos - 2 >= 0:
                    test_char2 = string[spos-2:spos-1]
                else:
                    test_char2 = " "
                
                if test_char2 == ".":
                    if spos - 3 >= 0:
                        test_char2 = string[spos-3:spos-2]
                    else:
                        test_char2 = " "
                    spos = spos - 2
                
                if test_char2 == " ":
                    test_char2 = "0"
                
                var tpos1 = digit_char.find(test_char2)
                if tpos1 >= 0:
                    tpos1 += 1
                else:
                    tpos1 = 0
                
                var new_str2 = string[:spos-2] + digit_char[tpos1:tpos1+1] + string[spos-1:]
                string = new_str2
            else:
                var test_char3: String
                if spos - 1 >= 0:
                    test_char3 = string[spos-1:spos]
                else:
                    test_char3 = " "
                
                if test_char3 == ".":
                    if spos - 2 >= 0:
                        test_char3 = string[spos-2:spos-1]
                    else:
                        test_char3 = " "
                    spos = spos - 1
                
                if test_char3 == " ":
                    test_char3 = "0"
                
                var tpos1 = digit_char.find(test_char3)
                if tpos1 >= 0:
                    tpos1 += 1
                else:
                    tpos1 = 0
                
                var new_str3 = string[:spos-1] + digit_char[tpos1:tpos1+1] + string[spos:]
                string = new_str3
            
            spos = spos - 1
            npos = tpos1
    
    var slen = len(string.rstrip())
    var include_dot = sig_digits > 0 or estring != " "
    
    if include_dot:
        var end_idx = min(dotpos + sig_digits + 1, slen)
        string = string[:end_idx] + estring
    else:
        string = string[:dotpos]
    
    if isnan(real_value):
        string = "NAN"
    
    return string.lstrip()


fn i_round_sig_digits(integer_value: Int, sig_digits: Int = 0) -> String:
    var string = str(integer_value)
    return string.lstrip()


fn safe_divide(a: Float64, b: Float64) -> Float64:
    var small = 1.0e-10
    if fabs(b) < small:
        return a / copysign(small, b)
    else:
        return a / b
