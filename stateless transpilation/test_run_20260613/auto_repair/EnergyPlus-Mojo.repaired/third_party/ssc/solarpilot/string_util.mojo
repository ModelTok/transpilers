/**
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
*/

def split(str: String, delim: String, ret_empty: Bool = False, ret_delim: Bool = False) -> List[String]:
    var list = List[String]()
    var cur_delim = String()
    var m_pos: Int = 0
    var token = String()
    var dsize = len(delim)
    while m_pos < len(str):
        var pos = str.find(delim, m_pos)
        if pos == -1:
            cur_delim = ""
            token = str[m_pos:]
            m_pos = len(str)
        else:
            cur_delim = str[pos]
            var len_ = pos - m_pos
            token = str[m_pos:m_pos + len_]
            m_pos = pos + dsize
        if token == "" and not ret_empty:
            continue
        list.append(token)
        if ret_delim and cur_delim != "" and m_pos < len(str):
            list.append(cur_delim)
    return list

def join(list: List[String], delim: String) -> String:
    var str_ = String()
    for i in range(len(list)):
        str_ += list[i]
        if i < len(list) - 1:
            str_ += delim
    return str_

def to_integer(str: String, inout x: Int) -> Bool:
    try:
        x = Int(str)
        return True
    except:
        return False

def to_float(str: String, inout x: Float32) -> Bool:
    var val: Float64 = 0.0
    var ok = to_double(str, val)
    x = Float32(val)
    return ok

def to_double(str: String, inout x: Float64) -> Bool:
    try:
        x = Float64(str)
        return True
    except:
        return False

def to_bool(str: String, inout x: Bool) -> Bool:
    var val1: Bool = False
    var val2: Bool = False
    var val3: Bool = False
    var strl = lower_case(str)
    val1 = strl == "true"
    val2 = strl == "t"
    val3 = strl == "1"
    var vals = (val1 or val2 or val3) == True
    x = vals
    return True

def to_string(x: Int, fmt: String = "%d") -> String:
    var buf = fmt % x
    return String(buf)

def to_string(x: Float64, fmt: String = "%lg") -> String:
    var buf = fmt % x
    return String(buf)

def lower_case(in_: String) -> String:
    var ret = in_.lower()
    return ret

def upper_case(in_: String) -> String:
    var ret = in_.upper()
    return ret

def ReplaceString(subject: String, search: String, replace: String) -> String:
    var result = String()
    var pos: Int = 0
    while True:
        var found = subject.find(search, pos)
        if found == -1:
            result += subject[pos:]
            break
        result += subject[pos:found]
        result += replace
        pos = found + len(search)
    return result

def ReplaceStringInPlace(inout subject: String, search: String, replace: String):
    subject = ReplaceString(subject, search, replace)