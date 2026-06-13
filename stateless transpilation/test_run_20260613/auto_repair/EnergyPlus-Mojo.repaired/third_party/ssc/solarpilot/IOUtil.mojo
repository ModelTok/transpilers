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
INCLUDING, BUT NOT LIMITED TO, THE LIMITED TO WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from interop import *
from definitions import *
from rapidxml import *
from sort_method import *
from IOUtil import *
from python import Python
import os
import sys

def file_exists(file: String) -> Bool:
    #ifdef _WIN32
    #DWORD ret = ::GetFileAttributesA( file );
    #return (ret != (DWORD)-1) && !(ret & FILE_ATTRIBUTE_DIRECTORY);
    #else
    var st: os.stat_result
    try:
        st = os.stat(file)
        return os.path.isfile(file)
    except:
        return False
    #endif

def dir_exists(path: String) -> Bool:
    #ifdef _WIN32
    #char *wpath = _strdup( path );
    #if (!wpath) return false;
    #int pos = (int)strlen(wpath)-1;
    #while (pos > 1 && (wpath[pos] == '/' || wpath[pos] == '\\'))
    #{
    #	if (pos == 3 && wpath[pos-1] == ':') break;
    #	wpath[pos] = 0;
    #	pos--;
    #}
    #DWORD ret = ::GetFileAttributesA(wpath);
    #bool exists =  (ret != (DWORD)-1) && (ret & FILE_ATTRIBUTE_DIRECTORY);
    #free( wpath );
    #return exists;
    #else
    try:
        var st: os.stat_result = os.stat(path)
        return os.path.isdir(path)
    except:
        return False
    #endif

def remove_file(path: String) -> Bool:
    try:
        os.remove(path)
        return True
    except:
        return False

#def SP_USE_MKDIR
#def make_dir(x)  ::CreateDirectory(x, NULL)
#def make_dir(x) ::_mkdir(x, 0777)
def mkdir(path: String, make_full: Bool = False) -> Bool:
    if make_full:
        var parts: List[String] = split(path, "/\\")
        if len(parts) < 1:
            return False
        var cur_path: String = parts[0] + path_separator()
        for i in range(1, len(parts)):
            cur_path += parts[i]
            if not dir_exists(cur_path):
                try:
                    os.mkdir(cur_path)
                except:
                    return False
            cur_path += path_separator()
        return True
    else:
        try:
            os.mkdir(path)
            return True
        except:
            return False

def path_only(path: String) -> String:
    var pos: Int = path.rfind("/\\")
    if pos == -1:
        return path
    else:
        return path[:pos]

def name_only(path: String) -> String:
    var pos: Int = path.rfind("/\\")
    if pos == -1:
        return path
    else:
        return path[pos+1:]

def ext_only(path: String) -> String:
    var pos: Int = path.rfind(".")
    if pos == -1:
        return path
    else:
        return path[pos+1:]

def path_separator() -> UInt8:
    #ifdef _WIN32
    #return '\\';
    #else
    return '/'
    #endif

def get_cwd() -> String:
    var buf: String = String(" " * 2048)
    #ifdef _WIN32
    #if (::GetCurrentDirectoryA(sizeof(buf), buf) == 0)
    #  return string();
    #else
    try:
        return os.getcwd()
    except:
        return String()
    #endif

def set_cwd(path: String) -> Bool:
    #ifdef _WIN32
    #return ::SetCurrentDirectoryA( path.c_str() ) != 0;
    #else
    try:
        os.chdir(path)
        return True
    except:
        return False
    #endif

def read_chars(fp: PythonObject, text: String, nchars: Int = 256):
    var c: Int
    text = ""
    var nc: Int = 0
    while True:
        c = fp.read(1)
        if c == "" or nc >= nchars:
            break
        text += chr(ord(c))
        nc += 1

def read_line(fp: PythonObject, buf: String, prealloc: Int = 256) -> Bool:
    var c: Int
    buf = ""
    if prealloc > 10:
        buf.reserve(prealloc)
    while True:
        c = fp.read(1)
        if c == "" or c == "\n" or c == "\r":
            break
        buf += c
    if c == "\r":
        c = fp.read(1)
        if c != "\n":
            fp.seek(-1, 1)
    if c == "\n":
        c = fp.read(1)
        if c != "\r":
            fp.seek(-1, 1)
    return not (len(buf) == 0 and c == "")

def read_file(fname: String, file: String, eol_marker: String):
    file = ""
    var line: String
    var fin: PythonObject = open(fname, "r")
    eol_marker = "\n"
    if fin:
        while True:
            line = fin.readline()
            if not line:
                break
            file += line.rstrip("\n") + "\n"
        fin.close()
    return

def parseXMLInputFile(fname: String, V: var_map, par_data: parametric, opt_data: optimization):
    var file: String
    var eol: String
    ioutil.read_file(fname, file, eol)
    var fstr: String = file
    var doc: xml_document = xml_document()
    doc.parse(fstr)
    var top_node: xml_node = doc.first_node()
    var version: String = top_node.first_node("version").value()
    V.reset()
    V.drop_heliostat(0)
    V.drop_receiver(0)
    var rec_insts: List[Int] = List[Int]()
    var hel_insts: List[Int] = List[Int]()
    var var_node: xml_node = top_node.first_node("variable")
    var component0: String = ""
    var inst0: Int = -1
    while var_node:
        var component: String = var_node.first_node("component").value()
        var sinst: String = var_node.first_node("instance").value()
        var varname: String = var_node.first_node("varname").value()
        var units: String = var_node.first_node("units").value()
        var inst: Int
        to_integer(sinst, inst)
        if component == "receiver":
            if inst != inst0 or component != component0:
                if rec_insts.find(inst) == -1:
                    V.add_receiver(inst)
                    rec_insts.append(inst)
        if component == "heliostat":
            if inst != inst0 or component != component0:
                if hel_insts.find(inst) == -1:
                    V.add_heliostat(inst)
                    hel_insts.append(inst)
        component0 = component
        inst0 = inst
        var v: Optional[spbase] = V._varptrs.get(component + "." + sinst + "." + varname)
        if v:
            if v.ctype == "combo":
                var selection: String = var_node.first_node("value").value()
                var cbchoices: List[String] = v.combo_get_choices()
                if varname == "temp_which" or cbchoices.find(selection) != -1:
                    v.set_from_string(selection)
            else:
                v.set_from_string(var_node.first_node("value").value())
            v.units = var_node.first_node("units").value()
        var_node = var_node.next_sibling("variable")
    par_data.clear()
    var par_node: xml_node = top_node.first_node("parametric")
    if par_node:
        var par: xml_node = par_node.first_node("par_variable")
        while par:
            var v: Optional[spbase] = V._varptrs.get(par.first_node("varname").value())
            if v:
                par_data.addVar(v)
            else:
                par = par.next_sibling("par_variable")
                continue
            var pvar: par_variable = par_data.back()
            pvar.units = par.first_node("units").value()
            pvar.display_text = par.first_node("display_text").value()
            pvar.data_type = par.first_node("data_type").value()
            pvar.linked = lower_case(par.first_node("linked").value()) == "true"
            pvar.layout_required = lower_case(par.first_node("layout_required").value()) == "true"
            var sel_node: xml_node = par.first_node("selections").first_node("selection")
            pvar.selections.Clear()
            while sel_node:
                pvar.selections.push_back(sel_node.value())
                sel_node = sel_node.next_sibling()
            var choice_node: xml_node = par.first_node("choices").first_node("choice")
            pvar.choices.Clear()
            while choice_node:
                pvar.choices.push_back(choice_node.value())
                choice_node = choice_node.next_sibling()
            var sim_node: xml_node = par.first_node("sim_values").first_node("sim_value")
            pvar.sim_values.Clear()
            while sim_node:
                pvar.sim_values.push_back(sim_node.value())
                sim_node = sim_node.next_sibling()
            par = par.next_sibling("par_variable")
    opt_data.clear()
    var opt_node: xml_node = top_node.first_node("optimization")
    if opt_node:
        var opt: xml_node = opt_node.first_node("opt_variable")
        while opt:
            var v: Optional[spbase] = V._varptrs.get(opt.first_node("varname").value())
            if v:
                opt_data.addVar(v)
            else:
                opt = opt.next_sibling("opt_variable")
                continue
            var ovar: par_variable = opt_data.back()
            ovar.units = opt.first_node("units").value()
            ovar.display_text = opt.first_node("display_text").value()
            ovar.data_type = opt.first_node("data_type").value()
            ovar.linked = lower_case(opt.first_node("linked").value()) == "true"
            ovar.layout_required = lower_case(opt.first_node("layout_required").value()) == "true"
            var sel_node: xml_node = opt.first_node("selections").first_node("selection")
            ovar.selections.Clear()
            while sel_node:
                ovar.selections.push_back(sel_node.value())
                sel_node = sel_node.next_sibling()
            var choice_node: xml_node = opt.first_node("choices").first_node("choice")
            ovar.choices.Clear()
            while choice_node:
                ovar.choices.push_back(choice_node.value())
                choice_node = choice_node.next_sibling()
            var sim_node: xml_node = opt.first_node("sim_values").first_node("sim_value")
            ovar.sim_values.Clear()
            while sim_node:
                ovar.sim_values.push_back(sim_node.value())
                sim_node = sim_node.next_sibling()
            opt = opt.next_sibling("opt_variable")
    return

def saveXMLInputFile(fname: String, V: var_map, par_data: parametric, opt_data: optimization, version: String) -> Bool:
    var fobj: PythonObject = open(fname, "w")
    if fobj:
        fobj.write("<data>\n")
        var t1: String = "\t"
        var t2: String = "\t\t"
        var t3: String = "\t\t\t"
        var t4: String = "\t\t\t\t"
        fobj.write(t1 + "<version>" + version + "</version>\n")
        var dt: DTobj = DTobj()
        dt.Now()
        fobj.write(t1 + "<header>Last saved " + dt._month + "-" + dt._mday + "-" + dt._year + " at " + dt._hour + ":" + dt._min + ":" + dt._sec + "</header>\n")
        var module: String
        var inst: String
        var varname: String
        var units: String
        var keys: List[String] = List[String]()
        for it in V._varptrs:
            keys.append(it.key())
        quicksort(keys)
        for i in range(len(keys)):
            var v: spbase = V._varptrs[keys[i]]
            var nm: List[String] = split(v.name, ".")
            fobj.write(t1 + "<variable>\n")
            fobj.write(t2 + "<component>" + nm[0] + "</component>\n")
            fobj.write(t2 + "<instance>" + nm[1] + "</instance>\n")
            fobj.write(t2 + "<varname>" + nm[2] + "</varname>\n")
            fobj.write(t2 + "<units>" + v.units + "</units>\n")
            var val: String
            v.as_string(val)
            fobj.write(t2 + "<value>" + val + "</value>\n")
            fobj.write(t1 + "</variable>\n")
        if len(par_data) > 0:
            fobj.write(t1 + "<parametric>\n")
            for i in range(len(par_data)):
                fobj.write(t2 + "<par_variable>\n")
                var pv: par_variable = par_data[i]
                fobj.write(t3 + "<varname>" + pv.varname + "</varname>\n")
                fobj.write(t3 + "<display_text>" + pv.display_text + "</display_text>\n")
                fobj.write(t3 + "<units>" + pv.units + "</units>\n")
                fobj.write(t3 + "<data_type>" + pv.data_type + "</data_type>\n")
                fobj.write(t3 + "<linked>" + ("true" if pv.linked else "false") + "</linked>\n")
                fobj.write(t3 + "<layout_required>" + ("true" if pv.layout_required else "false") + "</layout_required>\n")
                fobj.write(t3 + "<selections>\n")
                for j in range(len(pv.selections)):
                    fobj.write(t4 + "<selection>" + pv.selections[j] + "</selection>\n")
                fobj.write(t3 + "</selections>\n")
                fobj.write(t3 + "<choices>\n")
                for j in range(len(pv.choices)):
                    fobj.write(t4 + "<choice>" + pv.choices[j] + "</choice>\n")
                fobj.write(t3 + "</choices>\n")
                fobj.write(t3 + "<sim_values>\n")
                for j in range(len(pv.sim_values)):
                    fobj.write(t4 + "<sim_value>" + pv.sim_values[j] + "</sim_value>\n")
                fobj.write(t3 + "</sim_values>\n")
                fobj.write(t2 + "</par_variable>\n")
            fobj.write(t1 + "</parametric>\n")
        if len(opt_data) > 0:
            fobj.write(t1 + "<optimization>\n")
            for i in range(len(opt_data)):
                fobj.write(t2 + "<opt_variable>\n")
                var ov: par_variable = opt_data[i]
                fobj.write(t3 + "<varname>" + ov.varname + "</varname>\n")
                fobj.write(t3 + "<display_text>" + ov.display_text + "</display_text>\n")
                fobj.write(t3 + "<units>" + ov.units + "</units>\n")
                fobj.write(t3 + "<data_type>" + ov.data_type + "</data_type>\n")
                fobj.write(t3 + "<linked>" + ("true" if ov.linked else "false") + "</linked>\n")
                fobj.write(t3 + "<layout_required>" + ("true" if ov.layout_required else "false") + "</layout_required>\n")
                fobj.write(t3 + "<selections>\n")
                for j in range(len(ov.selections)):
                    fobj.write(t4 + "<selection>" + ov.selections[j] + "</selection>\n")
                fobj.write(t3 + "</selections>\n")
                fobj.write(t3 + "<choices>\n")
                for j in range(len(ov.choices)):
                    fobj.write(t4 + "<choice>" + ov.choices[j] + "</choice>\n")
                fobj.write(t3 + "</choices>\n")
                fobj.write(t3 + "<sim_values>\n")
                for j in range(len(ov.sim_values)):
                    fobj.write(t4 + "<sim_value>" + ov.sim_values[j] + "</sim_value>\n")
                fobj.write(t3 + "</sim_values>\n")
                fobj.write(t2 + "</opt_variable>\n")
            fobj.write(t1 + "</optimization>\n")
        fobj.write("</data>\n")
        fobj.close()
        return True
    else:
        return False

def getDelimiter(text: String) -> String:
    if text == "":
        return ","
    var delims: List[String] = List[String]()
    delims.append(",")
    delims.append(" ")
    delims.append("\t")
    delims.append(";")
    var delim: String = "\t"
    var ns: Int = 0
    for i in range(4):
        var data: List[String] = split(text, delims[i])
        if len(data) > ns:
            delim = delims[i]
            ns = len(data)
    return delim