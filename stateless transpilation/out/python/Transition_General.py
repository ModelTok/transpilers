import math

# EXTERNAL DEPS (to wire in glue):
# None (uses only Python intrinsics)

r64 = float


def r_trim_sig_digits(real_value: float, sig_digits: int) -> str:
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = '0.000000000000000000000000000'
    
    epos = string.find('E')
    if epos >= 0:
        estring = string[epos:]
        string = string[:epos] + ' ' * (len(string) - epos)
    else:
        estring = ' '
    
    dotpos = string.find('.')
    slen = len(string.rstrip())
    
    if sig_digits > 0 or estring != ' ':
        include_dot = True
    else:
        include_dot = False
    
    if include_dot:
        string = string[:min(dotpos + sig_digits + 1, slen)] + estring
    else:
        string = string[:dotpos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def rd_trim_sig_digits(real_value: float, sig_digits: int) -> str:
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = '0.000000000000000000000000000'
    
    epos = string.find('E')
    if epos >= 0:
        estring = string[epos:]
        string = string[:epos] + ' ' * (len(string) - epos)
    else:
        estring = ' '
    
    dotpos = string.find('.')
    slen = len(string.rstrip())
    
    if sig_digits > 0 or estring != ' ':
        include_dot = True
    else:
        include_dot = False
    
    if include_dot:
        string = string[:min(dotpos + sig_digits + 1, slen)] + estring
    else:
        string = string[:dotpos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def i_trim_sig_digits(integer_value: int, sig_digits: int = None) -> str:
    string = str(integer_value)
    return string.lstrip()


def r_round_sig_digits(real_value: float, sig_digits: int) -> str:
    digit_char = '01234567890'
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = '0.000000000000000000000000000'
    
    epos = string.find('E')
    if epos >= 0:
        estring = string[epos:]
        string = string[:epos] + ' ' * (len(string) - epos)
    else:
        estring = ' '
    
    dotpos = string.find('.')
    test_char_idx = dotpos + sig_digits + 1
    test_char = string[test_char_idx] if test_char_idx < len(string) else ' '
    tpos = digit_char.find(test_char)
    tpos = tpos + 1 if tpos >= 0 else 0
    
    if sig_digits == 0:
        spos = dotpos - 1
    else:
        spos = dotpos + sig_digits
    
    if tpos > 5:
        char2rep = string[spos] if spos < len(string) else ' '
        npos = digit_char.find(char2rep)
        npos = npos + 1 if npos >= 0 else 0
        
        string = string[:spos] + digit_char[npos] + string[spos+1:]
        
        while npos == 10:
            if sig_digits == 1:
                test_char = string[spos - 2] if spos - 2 >= 0 else ' '
                if test_char == '.':
                    test_char = string[spos - 3] if spos - 3 >= 0 else ' '
                    spos = spos - 2
                if test_char == ' ':
                    test_char = '0'
                tpos1 = digit_char.find(test_char)
                tpos1 = tpos1 + 1 if tpos1 >= 0 else 0
                string = string[:spos-2] + digit_char[tpos1] + string[spos-1:]
            else:
                test_char = string[spos - 1] if spos - 1 >= 0 else ' '
                if test_char == '.':
                    test_char = string[spos - 2] if spos - 2 >= 0 else ' '
                    spos = spos - 1
                if test_char == ' ':
                    test_char = '0'
                tpos1 = digit_char.find(test_char)
                tpos1 = tpos1 + 1 if tpos1 >= 0 else 0
                string = string[:spos-1] + digit_char[tpos1] + string[spos:]
            
            spos = spos - 1
            npos = tpos1
    
    slen = len(string.rstrip())
    if sig_digits > 0 or estring != ' ':
        include_dot = True
    else:
        include_dot = False
    
    if include_dot:
        string = string[:min(dotpos + sig_digits + 1, slen)] + estring
    else:
        string = string[:dotpos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def rd_round_sig_digits(real_value: float, sig_digits: int) -> str:
    digit_char = '01234567890'
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = '0.000000000000000000000000000'
    
    epos = string.find('E')
    if epos >= 0:
        estring = string[epos:]
        string = string[:epos] + ' ' * (len(string) - epos)
    else:
        estring = ' '
    
    dotpos = string.find('.')
    test_char_idx = dotpos + sig_digits + 1
    test_char = string[test_char_idx] if test_char_idx < len(string) else ' '
    tpos = digit_char.find(test_char)
    tpos = tpos + 1 if tpos >= 0 else 0
    
    if sig_digits == 0:
        spos = dotpos - 1
    else:
        spos = dotpos + sig_digits
    
    if tpos > 5:
        char2rep = string[spos] if spos < len(string) else ' '
        npos = digit_char.find(char2rep)
        npos = npos + 1 if npos >= 0 else 0
        
        string = string[:spos] + digit_char[npos] + string[spos+1:]
        
        while npos == 10:
            if sig_digits == 1:
                test_char = string[spos - 2] if spos - 2 >= 0 else ' '
                if test_char == '.':
                    test_char = string[spos - 3] if spos - 3 >= 0 else ' '
                    spos = spos - 2
                if test_char == ' ':
                    test_char = '0'
                tpos1 = digit_char.find(test_char)
                tpos1 = tpos1 + 1 if tpos1 >= 0 else 0
                string = string[:spos-2] + digit_char[tpos1] + string[spos-1:]
            else:
                test_char = string[spos - 1] if spos - 1 >= 0 else ' '
                if test_char == '.':
                    test_char = string[spos - 2] if spos - 2 >= 0 else ' '
                    spos = spos - 1
                if test_char == ' ':
                    test_char = '0'
                tpos1 = digit_char.find(test_char)
                tpos1 = tpos1 + 1 if tpos1 >= 0 else 0
                string = string[:spos-1] + digit_char[tpos1] + string[spos:]
            
            spos = spos - 1
            npos = tpos1
    
    slen = len(string.rstrip())
    if sig_digits > 0 or estring != ' ':
        include_dot = True
    else:
        include_dot = False
    
    if include_dot:
        string = string[:min(dotpos + sig_digits + 1, slen)] + estring
    else:
        string = string[:dotpos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def i_round_sig_digits(integer_value: int, sig_digits: int = None) -> str:
    string = str(integer_value)
    return string.lstrip()


def safe_divide(a: float, b: float) -> float:
    small = 1.0e-10
    if abs(b) < small:
        return a / math.copysign(small, b)
    else:
        return a / b
