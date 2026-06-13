"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
from cstdio import *
from cstdarg import *
from cstring import *
from cstdlib import *
from limits import *
from numeric import *
from algorithm import *
from lib_util import *
from cmath import *

# ifdef _MSC_VER
# /* taken from wxMSW-2.9.1/include/wx/defs.h - appropriate for Win32/Win64 */
# ifndef va_copy
# define va_copy(d, s) ((d)=(s))
# endif
# endif

# ifdef _MSC_VER  /* Microsoft Visual C++ -- warning level 4 */
# pragma warning( disable : 4996)  /* function was declared deprecated(strcpy, localtime, etc.) */
# endif

def util.split(str: String, delim: String, ret_empty: Bool = False, ret_delim: Bool = False) -> List[String]:
    var list: List[String] = List[String]()
    var cur_delim: StaticTuple[2, UInt8] = StaticTuple[2, UInt8](0, 0)
    var m_pos: Int = 0
    var token: String = ""
    while m_pos < len(str):
        var pos: Int = str.find_first_of(delim, m_pos)
        if pos == -1:
            cur_delim[0] = 0
            token = str[m_pos:]
            m_pos = len(str)
        else:
            cur_delim[0] = str[pos]
            var len_val: Int = pos - m_pos
            token = str[m_pos:pos]
            m_pos = pos + 1
        if len(token) == 0 and not ret_empty:
            continue
        list.append(token)
        if ret_delim and cur_delim[0] != 0 and m_pos < len(str):
            list.append(String(cur_delim[0]))
    return list

def util.join(list: List[String], delim: String) -> String:
    var str_val: String = ""
    for i in range(len(list)):
        str_val += list[i]
        if i < len(list) - 1:
            str_val += delim
    return str_val

def util.replace(s: String, old_text: String, new_text: String) -> Int:
    var uiOldLen: Int = len(old_text)
    var uiNewLen: Int = len(new_text)
    var pos: Int = 0
    var uiCount: Int = 0
    while True:
        pos = s.find(old_text, pos)
        if pos == -1:
            break
        s = s[:pos] + new_text + s[pos + uiOldLen:]
        pos += uiNewLen
        uiCount += 1
    return uiCount

def util.to_integer(str: String, x: Pointer[Int]) -> Bool:
    var startp: String = str
    var endp: Pointer[UInt8] = Pointer[UInt8]()
    x[0] = atol(startp)
    return len(startp) > 0

def util.to_float(str: String, x: Pointer[Float32]) -> Bool:
    var val: Float64 = 0.0
    var ok: Bool = to_double(str, Pointer[Float64](address_of(val)))
    x[0] = Float32(val)
    return ok

def util.to_double(str: String, x: Pointer[Float64]) -> Bool:
    var startp: String = str
    var endp: Pointer[UInt8] = Pointer[UInt8]()
    x[0] = atof(startp)
    return len(startp) > 0

def util.to_string(x: Int, fmt: String = "%d") -> String:
    var buf: StaticTuple[64, UInt8] = StaticTuple[64, UInt8](0)
    snprintf(buf.data, 64, fmt, x)
    return String(buf.data)

def util.to_string(x: Float64, fmt: String = "%lg") -> String:
    var buf: StaticTuple[256, UInt8] = StaticTuple[256, UInt8](0)
    snprintf(buf.data, 256, fmt, x)
    return String(buf.data)

def util.lower_case(in_val: String) -> String:
    var ret: String = in_val
    for i in range(len(ret)):
        ret[i] = chr(tolower(ord(ret[i])))
    return ret

def util.upper_case(in_val: String) -> String:
    var ret: String = in_val
    for i in range(len(ret)):
        ret[i] = chr(toupper(ord(ret[i])))
    return ret

def util.file_exists(file: String) -> Bool:
    var fp: FILEStar = fopen(file, "r")
    if fp:
        fclose(fp)
        return True
    return False

def util.dir_exists(path: String) -> Bool:
    var fp: FILEStar = fopen(path, "r")
    if fp:
        fclose(fp)
        return True
    return False

def util.remove_file(path: String) -> Bool:
    return remove(path) == 0

def util.mkdir(path: String, make_full: Bool = False) -> Bool:
    if make_full:
        var parts: List[String] = split(path, "/\\")
        if len(parts) < 1:
            return False
        var cur_path: String = parts[0] + path_separator()
        for i in range(1, len(parts)):
            cur_path += parts[i]
            if not dir_exists(cur_path):
                if mkdir(cur_path) != 0:
                    return False
            cur_path += path_separator()
        return True
    else:
        return mkdir(path) == 0

def util.path_only(path: String) -> String:
    var pos: Int = path.rfind("/\\")
    if pos == -1:
        return path
    else:
        return path[:pos]

def util.name_only(path: String) -> String:
    var pos: Int = path.rfind("/\\")
    if pos == -1:
        return path
    else:
        return path[pos + 1:]

def util.ext_only(path: String) -> String:
    var pos: Int = path.rfind(".")
    if pos == -1:
        return path
    else:
        return path[pos + 1:]

def util.path_separator() -> UInt8:
    return ord('/')

def util.get_cwd() -> String:
    var buf: StaticTuple[2048, UInt8] = StaticTuple[2048, UInt8](0)
    if getcwd(buf.data, 2048) == None:
        return String()
    return String(buf.data)

def util.set_cwd(path: String) -> Bool:
    return chdir(path) == 0

def util.read_file(file: String) -> String:
    var buf: String = ""
    var c: UInt8 = 0
    var fp: FILEStar = fopen(file, "r")
    if fp:
        while True:
            c = fgetc(fp)
            if c == EOF:
                break
            buf += chr(c)
        fclose(fp)
    return buf

def util.read_line(fp: FILEStar, buf: String, prealloc: Int = 256) -> Bool:
    var c: Int = 0
    buf = ""
    if prealloc > 10:
        buf.reserve(prealloc)
    while True:
        c = fgetc(fp)
        if c == EOF or c == ord('\n') or c == ord('\r'):
            break
        buf += chr(c)
    if c == ord('\r'):
        c = fgetc(fp)
        if c != ord('\n'):
            ungetc(c, fp)
    if c == ord('\n'):
        c = fgetc(fp)
        if c != ord('\r'):
            ungetc(c, fp)
    return not (len(buf) == 0 and c == EOF)

def util.sync_piped_process.spawn(command: String, workdir: String = "") -> Int:
    var line: String = ""
    var lastwd: String = ""
    if not workdir.empty():
        lastwd = util.get_cwd()
        util.set_cwd(workdir)
    var fp: FILEStar = popen(command, "r")
    if not fp:
        return -99
    while util.read_line(fp, line):
        on_stdout(line)
    if not lastwd.empty():
        util.set_cwd(lastwd)
    return pclose(fp)

def util.format(fmt: String, ...) -> String:
    if len(fmt) == 0 or fmt[0] == 0:
        return ""
    var arglist: VaList = va_start()
    var ret: Int = 0
    var size: Int = 512
    var buffer: Pointer[UInt8] = Pointer[UInt8].alloc(size)
    if not buffer:
        return ""
    var argptr_copy: VaList = va_copy(arglist)
    ret = util.format_vn(buffer, size - 1, fmt, argptr_copy)
    va_end(argptr_copy)
    if ret == 0:
        buffer.free()
        size *= 2
        buffer = Pointer[UInt8].alloc(size)
        if not buffer:
            return ""
    va_end(arglist)
    var s: String = String(buffer)
    if buffer:
        buffer.free()
    return s

def util.format_vn(buffer: Pointer[UInt8], maxlen: Int, fmt: String, arglist: VaList) -> Int:
    var p: Pointer[UInt8] = fmt.data
    var bp: Pointer[UInt8] = buffer
    var tp: Pointer[UInt8] = Pointer[UInt8]()
    var bpmax: Pointer[UInt8] = buffer + maxlen - 1
    var i: Int = 0
    var arg_char: UInt8 = 0
    var arg_str: Pointer[UInt8] = Pointer[UInt8]()
    var arg_int: Int = 0
    var arg_uint: UInt32 = 0
    var arg_double: Float64 = 0.0
    var temp: StaticTuple[256, UInt8] = StaticTuple[256, UInt8](0)
    var tempfmt: StaticTuple[256, UInt8] = StaticTuple[256, UInt8](0)
    var decpt: Pointer[UInt8] = Pointer[UInt8]()
    var ndigit: Int = 0
    var with_precision: Int = 0
    var with_comma: Pointer[UInt8] = Pointer[UInt8]()
    var prev: UInt8 = 0
    if not p:
        bp[0] = 0
        return 0
    while p[0] != 0 and bp < bpmax:
        if p[0] != ord('%'):
            bp[0] = p[0]
            bp += 1
            p += 1
        else:
            p += 1
            if p[0] == ord('d') or p[0] == ord('D'):
                p += 1
                arg_int = va_arg[Int](arglist)
                snprintf(temp.data, 256, "%d", arg_int)
                tp = temp.data
                while tp[0] != 0 and bp < bpmax:
                    bp[0] = tp[0]
                    bp += 1
                    tp += 1
            elif p[0] == ord('u') or p[0] == ord('U'):
                p += 1
                arg_uint = va_arg[UInt32](arglist)
                snprintf(temp.data, 256, "%u", arg_uint)
                tp = temp.data
                while tp[0] != 0 and bp < bpmax:
                    bp[0] = tp[0]
                    bp += 1
                    tp += 1
            elif p[0] == ord('x') or p[0] == ord('X'):
                p += 1
                arg_uint = va_arg[UInt32](arglist)
                snprintf(temp.data, 256, "%x", arg_uint)
                tp = temp.data
                while tp[0] != 0 and bp < bpmax:
                    bp[0] = tp[0]
                    bp += 1
                    tp += 1
            elif p[0] == ord('c') or p[0] == ord('C'):
                arg_char = UInt8(va_arg[Int](arglist))
                if bp + 1 < bpmax:
                    bp[0] = arg_char
                    bp += 1
                p += 1
            elif p[0] == ord('s') or p[0] == ord('S'):
                p += 1
                arg_str = va_arg[Pointer[UInt8]](arglist)
                tp = arg_str
                while tp[0] != 0 and bp < bpmax:
                    bp[0] = tp[0]
                    bp += 1
                    tp += 1
            elif p[0] == ord('%'):
                if bp + 1 < bpmax:
                    bp[0] = p[0]
                    bp += 1
                    p += 1
            elif p[0] == ord('l') or p[0] == ord('L') or p[0] == ord('f') or p[0] == ord('F') or p[0] == ord('g') or p[0] == ord('G') or p[0] == ord('.'):
                with_precision = 0
                with_comma = Pointer[UInt8]()
                tp = tempfmt.data
                tp[0] = ord('%')
                tp += 1
                if p[0] == ord('.'):
                    with_precision = 1
                    tp[0] = p[0]
                    tp += 1
                    p += 1
                    if p[0] == ord('0'):
                        with_precision = 2
                    while p[0] != 0 and isdigit(p[0]):
                        tp[0] = p[0]
                        tp += 1
                        p += 1
                tp[0] = ord('l')
                tp += 1
                if p[0] == ord('l') or p[0] == ord('L'):
                    p += 1
                if p[0] == ord(','):
                    tp[0] = ord('f')
                    tp += 1
                    p += 1
                    with_comma = Pointer[UInt8](1)
                else:
                    tp[0] = p[0]
                    tp += 1
                    p += 1
                tp[0] = 0
                arg_double = va_arg[Float64](arglist)
                snprintf(temp.data, 256, tempfmt.data, arg_double)
                i = 0
                if with_comma:
                    decpt = strchr(temp.data, ord('.'))
                    if not decpt:
                        ndigit = strlen(temp.data)
                    else:
                        ndigit = Int(decpt - temp.data)
                    i = 0 - ndigit % 3
                if (not with_precision or with_comma != None) and not strchr(tempfmt.data, ord('g')) and not strchr(tempfmt.data, ord('G')) and not (with_precision == 2):
                    tp = temp.data + strlen(temp.data) - 1
                    while tp > temp.data and tp[0] == ord('0'):
                        tp[0] = 0
                        tp -= 1
                    if tp[0] == ord('.'):
                        tp[0] = 0
                tp = temp.data
                decpt = Pointer[UInt8]()
                prev = 0
                while tp[0] != 0 and bp < bpmax:
                    if tp[0] == ord('.'):
                        decpt = Pointer[UInt8](1)
                    if with_comma != None and isdigit(prev) and i % 3 == 0 and not decpt and bp < bpmax:
                        bp[0] = ord(',')
                        bp += 1
                    prev = tp[0]
                    if bp < bpmax:
                        bp[0] = tp[0]
                        bp += 1
                    tp += 1
                    i += 1
            elif p[0] == ord('m') or p[0] == ord('M') or p[0] == ord(','):
                arg_double = va_arg[Float64](arglist)
                if p[0] == ord(','):
                    snprintf(temp.data, 256, "%lf", arg_double)
                    if strchr(temp.data, ord('e')) != None:
                        snprintf(temp.data, 256, "%d", Int(arg_double))
                else:
                    snprintf(temp.data, 256, "%.2lf", arg_double)
                decpt = strchr(temp.data, ord('.'))
                if not decpt:
                    ndigit = strlen(temp.data)
                else:
                    ndigit = Int(decpt - temp.data)
                if p[0] == ord(','):
                    tp = temp.data + strlen(temp.data) - 1
                    while tp > temp.data and tp[0] == ord('0'):
                        tp[0] = 0
                        tp -= 1
                    if tp[0] == ord('.'):
                        tp[0] = 0
                i = 0 - (ndigit % 3)
                tp = temp.data
                decpt = Pointer[UInt8]()
                prev = 0
                while tp[0] != 0:
                    if tp[0] == ord('.'):
                        decpt = Pointer[UInt8](1)
                    if isdigit(prev) and i % 3 == 0 and not decpt and bp < bpmax:
                        bp[0] = ord(',')
                        bp += 1
                    prev = tp[0]
                    if bp < bpmax:
                        bp[0] = tp[0]
                        bp += 1
                    tp += 1
                    i += 1
                p += 1
    bp[0] = 0
    if bp == bpmax:
        return 0
    else:
        return Int(bp - buffer)

def util.hours_in_month(month: Int) -> Int:
    return (0 if (month < 1) or (month > 12) else nday[month - 1] * 24)

def util.percent_of_year(month: Int, hours: Int) -> Float64:
    if month < 1:
        return 0.0
    if month > 12:
        return 1.0
    var hours_from_months: Int = 0
    for i in range(month - 1):
        hours_from_months += Int(nday[i] * 24)
    return Float64(hours_from_months + hours) / 8760.0

def util.day_of(time: Float64) -> Int:
    var daynum: Int = Int(time / 24.0)
    return daynum % 7

def util.week_of(time: Float64) -> Int:
    var weeknum: Int = Int(time / (24.0 * 7.0))
    return weeknum

def util.month_of(time: Float64) -> Int:
    if time < 0:
        return 0
    if time < 744:
        return 1
    if time < 1416:
        return 2
    if time < 2160:
        return 3
    if time < 2880:
        return 4
    if time < 3624:
        return 5
    if time < 4344:
        return 6
    if time < 5088:
        return 7
    if time < 5832:
        return 8
    if time < 6552:
        return 9
    if time < 7296:
        return 10
    if time < 8016:
        return 11
    if time < 8760:
        return 12
    return 0

def util.days_in_month(month: Int) -> Int:
    var days_in_months: List[Int] = List[Int](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    return days_in_months[month]

def util.day_of_month(month: Int, time: Float64) -> Int:
    var daynum: Int = Int(time / 24.0) + 1
    if month == 1:
        return daynum
    elif month == 2:
        return daynum - 31
    elif month == 3:
        return daynum - 31 - 28
    elif month == 4:
        return daynum - 31 - 28 - 31
    elif month == 5:
        return daynum - 31 - 28 - 31 - 30
    elif month == 6:
        return daynum - 31 - 28 - 31 - 30 - 31
    elif month == 7:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30
    elif month == 8:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30 - 31
    elif month == 9:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30 - 31 - 31
    elif month == 10:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30 - 31 - 31 - 30
    elif month == 11:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30 - 31 - 31 - 30 - 31
    elif month == 12:
        return daynum - 31 - 28 - 31 - 30 - 31 - 30 - 31 - 31 - 30 - 31 - 30
    else:
        return daynum

def util.month_hour(hour_of_year: Int, out_month: Pointer[Int], out_hour: Pointer[Int]):
    var tmpSum: Int = 0
    var hour: Int = 0
    var month: Int = 0
    for month in range(1, 13):
        var hours_in_month_val: Int = util.hours_in_month(month)
        tmpSum += hours_in_month_val
        if hour_of_year + 1 <= tmpSum:
            var tmp: Int = Int(floor(Float32(hour_of_year) / 24))
            hour = (hour_of_year + 1) - (tmp * 24)
            break
    out_month[0] = month
    out_hour[0] = hour

def util.hour_of_day(hour_of_year: Int) -> Int:
    return hour_of_year % 24

def util.hour_of_year(month: Int, day: Int, hour: Int) -> Int:
    var h: Int = 0
    var ok: Bool = True
    var days_in_months: List[Int] = List[Int](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    if month >= 1 and month <= 12:
        for m in range(month - 1):
            h += days_in_months[m] * 24
    else:
        ok = False
    if day >= 1 and day <= days_in_months[month - 1]:
        h += (day - 1) * 24
    elif month == 2 and day == 29:
        h += (27 * 24)
    else:
        ok = False
    if hour >= 0 and hour <= 23:
        h += hour
    else:
        ok = False
    if hour > 8759:
        raise Error("hour_of_year range is (0-8759) but calculated hour is > 8759.")
    if not ok:
        raise Error("hour_of_year input month, day, or hour out of correct range")
    return h

def util.weekday(hour_of_year: Int) -> Bool:
    var day_of_year: Int = Int(floor(Float32(hour_of_year) / 24))
    var day_of_week: Int = day_of_year
    if day_of_week > 6:
        day_of_week = day_of_year % 7
    return day_of_week < 5

def util.schedule_char_to_int(c: UInt8) -> Int:
    var ret: Int = 0
    if c == ord('1'):
        ret = 1
    elif c == ord('2'):
        ret = 2
    elif c == ord('3'):
        ret = 3
    elif c == ord('4'):
        ret = 4
    elif c == ord('5'):
        ret = 5
    elif c == ord('6'):
        ret = 6
    elif c == ord('7'):
        ret = 7
    elif c == ord('8'):
        ret = 8
    elif c == ord('9'):
        ret = 9
    elif c == ord('A') or c == ord('a') or c == ord(':'):
        ret = 10
    elif c == ord('B') or c == ord('b') or c == ord('='):
        ret = 11
    elif c == ord('C') or c == ord('c') or c == ord('<'):
        ret = 12
    return ret

def util.schedule_int_to_month(m: Int) -> String:
    var ret: String = ""
    if m == 0:
        ret = "jan"
    elif m == 1:
        ret = "feb"
    elif m == 2:
        ret = "mar"
    elif m == 3:
        ret = "apr"
    elif m == 4:
        ret = "may"
    elif m == 5:
        ret = "jun"
    elif m == 6:
        ret = "jul"
    elif m == 7:
        ret = "aug"
    elif m == 8:
        ret = "sep"
    elif m == 9:
        ret = "oct"
    elif m == 10:
        ret = "nov"
    elif m == 11:
        ret = "dec"
    return ret

def util.translate_schedule(tod: Pointer[Int], wkday: String, wkend: String, min_val: Int, max_val: Int) -> Bool:
    var i: Int = 0
    if len(wkday) == 0 or len(wkend) == 0 or len(wkday) != 288 or len(wkend) != 288:
        for i in range(8760):
            tod[i] = min_val
        return False
    var wday: Int = 5
    for m in range(12):
        for d in range(nday[m]):
            var sptr: String = wkend if wday <= 0 else wkday
            if wday >= 0:
                wday -= 1
            else:
                wday = 5
            for h in range(24):
                tod[i] = schedule_char_to_int(ord(sptr[m * 24 + h])) - 1
                if tod[i] < min_val:
                    tod[i] = min_val
                if tod[i] > max_val:
                    tod[i] = max_val
                i += 1
    return True

def util.translate_schedule(tod: Pointer[Int], wkday: matrix_t[Float64], wkend: matrix_t[Float64], min_val: Int, max_val: Int) -> Bool:
    var i: Int = 0
    if (wkday.nrows() != 12) or (wkend.nrows() != 12) or (wkday.ncols() != 24) or (wkend.ncols() != 24):
        for i in range(8760):
            tod[i] = min_val
        return False
    var wday: Int = 5
    var is_weekday: Bool = True
    for m in range(12):
        for d in range(nday[m]):
            is_weekday = (wday > 0)
            if wday >= 0:
                wday -= 1
            else:
                wday = 5
            for h in range(24):
                if is_weekday:
                    tod[i] = Int(wkday.at(m, h))
                else:
                    tod[i] = Int(wkend.at(m, h))
                if tod[i] < min_val:
                    tod[i] = min_val
                if tod[i] > max_val:
                    tod[i] = max_val
                i += 1
    return True

def util.bilinear(rowval: Float64, colval: Float64, mat: matrix_t[Float64]) -> Float64:
    if mat.nrows() < 3 or mat.ncols() < 3:
        return Float64.nan
    var ridx: Int = 2
    while ridx < Int(mat.nrows()) and rowval > mat.at(ridx, 0):
        ridx += 1
    var cidx: Int = 2
    while cidx < Int(mat.ncols()) and colval > mat.at(0, cidx):
        cidx += 1
    if ridx == Int(mat.nrows()):
        ridx -= 1
    if cidx == Int(mat.ncols()):
        cidx -= 1
    var r1: Float64 = mat.at(ridx - 1, 0)
    var r2: Float64 = mat.at(ridx, 0)
    var c1: Float64 = mat.at(0, cidx - 1)
    var c2: Float64 = mat.at(0, cidx)
    var denom: Float64 = (r2 - r1) * (c2 - c1)
    return mat.at(ridx - 1, cidx - 1) * (r2 - rowval) * (c2 - colval) / denom + mat.at(ridx, cidx - 1) * (rowval - r1) * (c2 - colval) / denom + mat.at(ridx - 1, cidx) * (r2 - rowval) * (colval - c1) / denom + mat.at(ridx, cidx) * (rowval - r1) * (colval - c1) / denom

def util.interpolate(x1: Float64, y1: Float64, x2: Float64, y2: Float64, xValueToGetYValueFor: Float64) -> Float64:
    if x1 == x2:
        return y1
    if y1 == y2:
        return y1
    var slope: Float64 = (y2 - y1) / (x2 - x1)
    var inter: Float64 = y1 - (slope * x1)
    return (slope * xValueToGetYValueFor) + inter

def util.linterp_col(mat: matrix_t[Float64], ixcol: Int, xval: Float64, iycol: Int) -> Float64:
    var n: Int = mat.nrows()
    if n == 1 and ixcol == 0 and iycol == 0:
        return mat.at(0)
    if ixcol >= mat.ncols() or iycol >= mat.ncols() or n < 2:
        return Float64.nan
    var last: Float64 = mat(0, ixcol)
    var i: Int = 1
    while i < n:
        var x: Float64 = mat(i, ixcol)
        if x < last:
            return Float64.nan
        if x > xval:
            break
        last = x
        i += 1
    if i == n:
        i -= 1
    return util.interpolate(mat(i - 1, ixcol), mat(i - 1, iycol), mat(i, ixcol), mat(i, iycol), xval)

def util.lifetimeIndex(year: Int, hour_of_year: Int, step_of_hour: Int, step_per_hour: Int) -> Int:
    return (year * util.hours_per_year + hour_of_year) * step_per_hour + step_of_hour

def util.yearOneIndex(dtHour: Float64, lifetimeIndex: Int) -> Int:
    var stepsPerHour: Int = Int(1 / dtHour)
    var stepsPerYear: Int = Int(8760 * stepsPerHour)
    var year: Int = 0
    if lifetimeIndex >= stepsPerYear:
        year = Int(floor(Float64(lifetimeIndex) / Float64(stepsPerYear)))
    var indexYearOne: Int = lifetimeIndex - (year * stepsPerYear)
    return indexYearOne

def util.frequency_table(values: Pointer[Float64], n_vals: Int, bin_width: Float64) -> List[Float64]:
    if not values:
        raise Error("frequency_table requires data values.")
    if bin_width <= 0:
        raise Error("frequency_table bin_width must be greater than 0.")
    var max_val: Float64 = values[0]
    for i in range(1, n_vals):
        if values[i] > max_val:
            max_val = values[i]
    var freq: List[Float64] = List[Float64](size=Int(max_val / bin_width) + 1, fill=0.0)
    for i in range(n_vals):
        var bin: Int = Int(floor(values[i] / bin_width))
        freq[bin] += 1.0
    for f in range(len(freq)):
        freq[f] /= Float64(n_vals)
    return freq