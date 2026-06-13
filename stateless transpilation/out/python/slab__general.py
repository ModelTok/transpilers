import math
from typing import Optional

# EXTERNAL DEPS (to wire in glue):
# - r64: type alias for 64-bit float (from DataPrecisionGlobals, typically float)

def r64_trim_sig_digits(real_value: float, sig_digits: int) -> str:
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    e_pos = string.find('E')
    if e_pos >= 0:
        e_string = string[e_pos:]
        string = string[:e_pos] + ' ' * (len(string) - e_pos)
    else:
        e_string = ' '
    
    dot_pos = string.find('.')
    s_len = len(string.rstrip())
    
    include_dot = sig_digits > 0 or e_string != ' '
    
    if include_dot:
        end = min(dot_pos + sig_digits + 1, s_len)
        string = string[:end] + e_string
    else:
        string = string[:dot_pos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def r_trim_sig_digits(real_value: float, sig_digits: int) -> str:
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    e_pos = string.find('E')
    if e_pos >= 0:
        e_string = string[e_pos:]
        string = string[:e_pos] + ' ' * (len(string) - e_pos)
    else:
        e_string = ' '
    
    dot_pos = string.find('.')
    s_len = len(string.rstrip())
    
    include_dot = sig_digits > 0 or e_string != ' '
    
    if include_dot:
        end = min(dot_pos + sig_digits + 1, s_len)
        string = string[:end] + e_string
    else:
        string = string[:dot_pos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def i_trim_sig_digits(integer_value: int, sig_digits: Optional[int] = None) -> str:
    string = str(integer_value)
    return string.lstrip()


def r64_round_sig_digits(real_value: float, sig_digits: int) -> str:
    digit_char = '01234567890'
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    e_pos = string.find('E')
    if e_pos >= 0:
        e_string = string[e_pos:]
        string = string[:e_pos] + ' ' * (len(string) - e_pos)
    else:
        e_string = ' '
    
    dot_pos = string.find('.')
    test_char_idx = dot_pos + sig_digits + 1
    test_char = string[test_char_idx] if test_char_idx < len(string) else ' '
    t_pos = digit_char.find(test_char) + 1
    
    if sig_digits == 0:
        s_pos = dot_pos - 1
    else:
        s_pos = dot_pos + sig_digits
    
    if t_pos > 5:
        string = list(string)
        char_2_rep = string[s_pos]
        n_pos = digit_char.find(char_2_rep) + 1
        if n_pos < len(digit_char):
            string[s_pos] = digit_char[n_pos]
        
        while n_pos == 10:
            if sig_digits == 1:
                test_char = string[s_pos - 2]
                if test_char == '.':
                    test_char = string[s_pos - 3]
                    s_pos -= 2
                if test_char == ' ':
                    test_char = '0'
                t_pos_1 = digit_char.find(test_char) + 1
                if t_pos_1 < len(digit_char):
                    string[s_pos - 2] = digit_char[t_pos_1]
            else:
                test_char = string[s_pos - 1]
                if test_char == '.':
                    test_char = string[s_pos - 2]
                    s_pos -= 1
                if test_char == ' ':
                    test_char = '0'
                t_pos_1 = digit_char.find(test_char) + 1
                if t_pos_1 < len(digit_char):
                    string[s_pos - 1] = digit_char[t_pos_1]
            s_pos -= 1
            n_pos = t_pos_1
        
        string = ''.join(string)
    
    s_len = len(string.rstrip())
    include_dot = sig_digits > 0 or e_string != ' '
    
    if include_dot:
        end = min(dot_pos + sig_digits + 1, s_len)
        string = string[:end] + e_string
    else:
        string = string[:dot_pos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def r_round_sig_digits(real_value: float, sig_digits: int) -> str:
    digit_char = '01234567890'
    
    if real_value != 0.0:
        string = str(real_value)
    else:
        string = "0.000000000000000000000000000"
    
    e_pos = string.find('E')
    if e_pos >= 0:
        e_string = string[e_pos:]
        string = string[:e_pos] + ' ' * (len(string) - e_pos)
    else:
        e_string = ' '
    
    dot_pos = string.find('.')
    test_char_idx = dot_pos + sig_digits + 1
    test_char = string[test_char_idx] if test_char_idx < len(string) else ' '
    t_pos = digit_char.find(test_char) + 1
    
    if sig_digits == 0:
        s_pos = dot_pos - 1
    else:
        s_pos = dot_pos + sig_digits
    
    if t_pos > 5:
        string = list(string)
        char_2_rep = string[s_pos]
        n_pos = digit_char.find(char_2_rep) + 1
        if n_pos < len(digit_char):
            string[s_pos] = digit_char[n_pos]
        
        while n_pos == 10:
            if sig_digits == 1:
                test_char = string[s_pos - 2]
                if test_char == '.':
                    test_char = string[s_pos - 3]
                    s_pos -= 2
                if test_char == ' ':
                    test_char = '0'
                t_pos_1 = digit_char.find(test_char) + 1
                if t_pos_1 < len(digit_char):
                    string[s_pos - 2] = digit_char[t_pos_1]
            else:
                test_char = string[s_pos - 1]
                if test_char == '.':
                    test_char = string[s_pos - 2]
                    s_pos -= 1
                if test_char == ' ':
                    test_char = '0'
                t_pos_1 = digit_char.find(test_char) + 1
                if t_pos_1 < len(digit_char):
                    string[s_pos - 1] = digit_char[t_pos_1]
            s_pos -= 1
            n_pos = t_pos_1
        
        string = ''.join(string)
    
    s_len = len(string.rstrip())
    include_dot = sig_digits > 0 or e_string != ' '
    
    if include_dot:
        end = min(dot_pos + sig_digits + 1, s_len)
        string = string[:end] + e_string
    else:
        string = string[:dot_pos]
    
    if math.isnan(real_value):
        string = 'NAN'
    
    return string.lstrip()


def i_round_sig_digits(integer_value: int, sig_digits: Optional[int] = None) -> str:
    string = str(integer_value)
    return string.lstrip()


def d_safe_divide(a: float, b: float) -> float:
    SMALL = 1e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        return a / math.copysign(SMALL, b)


def r_safe_divide(a: float, b: float) -> float:
    SMALL = 1e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        return a / math.copysign(SMALL, b)
