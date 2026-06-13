/*******************************************************************************************************
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  (Alliance) under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as System Advisor Model or SAM. Except
*  to comply with the foregoing, the terms System Advisor Model, SAM, or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/
/*

Forms the base class for the various components of the solar field. 
These components can use the methods and variable declarations provided here.
*/

from Toolbox import split, to_integer, to_double, to_bool, sp_point, matrix_t, WeatherData, spexception
from string_util import String

# Template function my_to_string
def my_to_string[T: AnyRegType](value: T) -> String:
    return String(value)

enum SP_DATTYPE:
    SP_INT = 0
    SP_DOUBLE = 1
    SP_STRING = 2
    SP_BOOL = 3
    SP_MATRIX_T = 4
    SP_DVEC_POINT = 5
    SP_VEC_DOUBLE = 6
    SP_VEC_INTEGER = 7
    SP_WEATHERDATA = 8
    SP_VOIDPTR = 9

@value
struct simulation_info:
    var _callback: fn(siminfo: simulation_info&, data: Pointer[Byte]) -> Bool = None
    var _callback_data: Pointer[Byte] = None
    var _sim_progress: Float64 = 0.0
    var _sim_notice: String = ""
    var _current_simulation: Int = 0
    var _total_sim_count: Int = 0
    var _is_active: Bool = False

    def __init__(inout self):
        self._is_active = False
        self.Reset()
        self._callback = None
        self._callback_data = None

    def isEnabled(self) -> Bool:
        """Indicates whether any simulation is currently in progress (that's being tracked)"""
        return self._is_active

    def getCurrentSimulation(self) -> Int:
        """Index of the current simulation"""
        return self._current_simulation if self._is_active else 0

    def getTotalSimulationCount(self) -> Int:
        """Total number of expected simulations in this batch"""
        return self._total_sim_count if self._is_active else 0

    def getSimulationProgress(self) -> Float64:
        """Fractional progress [0..1] of the simulation"""
        return self._sim_progress if self._is_active else 0.0

    def getSimulationInfo(inout self, inout current: Int, inout total: Int, inout progress: Float64):
        if not self._is_active:
            return
        current = self._current_simulation
        total = self._total_sim_count
        progress = self._sim_progress

    def getSimulationNotices(self) -> Pointer[String]:
        """Returns a pointer to the vector of simulation notices """
        return Pointer[String].address_of(self._sim_notice)

    def ResetValues(inout self):
        self._current_simulation = 0
        self._total_sim_count = 0
        self._sim_progress = 0.0

    def Reset(inout self):
        self._current_simulation = 0
        self._total_sim_count = 0
        self._sim_progress = 0.0
        self._sim_notice = ""

    def setCallbackFunction(inout self, updateFunc: fn(siminfo: simulation_info&, data: Pointer[Byte]) -> Bool, cdata: Pointer[Byte]):
        self._callback = updateFunc
        self._callback_data = cdata
        self._is_active = True

    def getCallbackData(self) -> Pointer[Byte]:
        return self._callback_data

    def setCurrentSimulation(inout self, val: Int) -> Bool:
        if not self._is_active:
            return True
        self._current_simulation = val
        return self._callback(self, self._callback_data)

    def setTotalSimulationCount(inout self, val: Int) -> Bool:
        if not self._is_active:
            return True
        self._total_sim_count = val
        return self._callback(self, self._callback_data)

    def clearSimulationNotices(inout self):
        if not self._is_active:
            return
        self._sim_notice = ""

    def addSimulationNotice(inout self, notice: String) -> Bool:
        if not self._is_active:
            return True
        self._sim_notice = notice
        return self._callback(self, self._callback_data)

    def addSimulationNotice(inout self, notice: String) -> Bool:
        if not self._is_active:
            return True
        self._sim_notice = notice
        return self._callback(self, self._callback_data)

    def isEnabled(inout self, state: Bool):
        self._is_active = state

@value
struct simulation_error:
    var _callback: fn(simerror: simulation_error&, data: Pointer[Byte]) -> None = None
    var _callback_data: Pointer[Byte] = None
    var _message_log: String = ""
    var _is_connected: Bool = False
    var _is_fatal: Bool = False
    var _force_display: Bool = False
    var _terminate_status: Bool = False

    def __init__(inout self):
        self._callback = None
        self._callback_data = None
        self._is_fatal = False
        self._force_display = False
        self._terminate_status = False
        self._is_connected = False
        self._message_log = ""

    def setCallbackFunction(inout self, errorFunc: fn(simerror: simulation_error&, data: Pointer[Byte]) -> None, cdata: Pointer[Byte]):
        self._callback = errorFunc
        self._callback_data = cdata
        self._is_connected = True

    def isFatal(self) -> Bool:
        return self._is_fatal

    def isDisplayNow(self) -> Bool:
        return self._force_display

    def getSimulationErrors(self) -> Pointer[String]:
        return Pointer[String].address_of(self._message_log)

    def checkForErrors(self) -> Bool:
        return self._terminate_status or self._is_fatal

    def Reset(inout self):
        self._is_fatal = False
        self._terminate_status = False
        self._force_display = False
        self._message_log = ""

    def addSimulationError(inout self, error: String, is_fatal: Bool = False, force_display: Bool = False):
        if not self._is_connected:
            return
        self._is_fatal = self._is_fatal if self._is_fatal else is_fatal
        self._force_display = self._force_display if self._force_display else force_display
        self._message_log += error
        self._callback(self, self._callback_data)

    def addRangeError(inout self, val: Float64, varname: String, range: String):
        var msg = "Variable " + varname + " is out of range with value " + String(val) + ". The valid range is " + range + ".\n"
        self.addSimulationError(msg, True, True)

    def setTerminateStatus(inout self, do_terminate: Bool):
        self._terminate_status = do_terminate

    def clearErrorLog(inout self):
        self._message_log = ""

struct spbase:
    var name: String = ""
    var units: String = ""
    var ctype: String = ""
    var dattype: SP_DATTYPE = SP_DATTYPE.SP_INT
    var short_desc: String = ""
    var long_desc: String = ""
    var is_param: Bool = False
    var is_disabled: Bool = False

    # Static helper functions
    @staticmethod
    def _setv(SV: String, inout Vp: Pointer[Byte]) -> Bool:
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: Int) -> Bool:
        return to_integer(SV, &Vp)

    @staticmethod
    def _setv(SV: String, inout Vp: Float64) -> Bool:
        return to_double(SV, &Vp)

    @staticmethod
    def _setv(SV: String, inout Vp: String) -> Bool:
        Vp = SV
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: Bool) -> Bool:
        return to_bool(SV, Vp)

    @staticmethod
    def _setv(SV: String, inout Vp: matrix_t[Float64]) -> Bool:
        try:
            var content = split(SV, ";")
            var nrows = len(content)
            if nrows == 0:
                Vp.resize_fill(1, 2, 0.0)
                return True
            var line: List[String]
            line = split(content[0], ",")
            var rowlen = len(line)
            Vp.resize(nrows, rowlen)
            for i in range(nrows):
                line = split(content[i], ",")
                for j in range(rowlen):
                    to_double(line[j], &Vp[i, j])
        except:
            return False
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: List[sp_point]) -> Bool:
        try:
            var content = split(SV, "[P]")
            var line: List[String]
            var x: Float64
            var y: Float64
            var z: Float64
            var nrows = len(content)
            Vp.resize(nrows)
            for i in range(nrows):
                line = split(content[i], ",")
                to_double(line[0], &x)
                to_double(line[1], &y)
                to_double(line[2], &z)
                Vp[i] = sp_point(x, y, z)
        except:
            return False
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: List[Float64]) -> Bool:
        try:
            var svals = split(SV, ",")
            Vp.resize(len(svals))
            for i in range(len(svals)):
                to_double(svals[i], &Vp[i])
        except:
            return False
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: List[Int]) -> Bool:
        try:
            var svals = split(SV, ",")
            Vp.resize(len(svals))
            for i in range(len(svals)):
                to_integer(svals[i], &Vp[i])
        except:
            return False
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: WeatherData) -> Bool:
        try:
            var vals: List[String]
            var entries = split(SV, "[P]")
            var nrows = len(entries)
            var nv: Int
            var i: Int
            var j: Int
            Vp.resizeAll(nrows, 0.0)
            var wdvars = Vp.getEntryPointers()
            for i in range(nrows):
                vals = split(entries[i], ",")
                nv = min(len(vals), len(wdvars))
                for j in range(nv):
                    to_double(vals[j], &wdvars[j][i])
        except:
            return False
        return True

    @staticmethod
    def _setv(SV: String, inout Vp: List[List[sp_point]]) -> Bool:
        """
        [POLY] separates entries
        [P] separates points within a polygon
        ',' separates x,y,z within a point
        """
        Vp.clear()
        if SV == "":
            return True
        var polys = split(SV, "[POLY]")
        Vp.resize(len(polys))
        for i in range(len(polys)):
            var pts = split(polys[i], "[P]")
            Vp[i].resize(len(pts), sp_point())
            for j in range(len(pts)):
                var vals = split(pts[j], ",")
                var x: Float64
                for k in range(len(vals)):
                    to_double(vals[k], &x)
                    Vp[i][j][k] = x
        return True

    # Protected helper
    def _as_str(inout self, inout vout: String, v: Pointer[Byte]):

    def _as_str(inout self, inout vout: String, v: Int):
        vout = my_to_string(v)

    def _as_str(inout self, inout vout: String, v: String):
        vout = v

    def _as_str(inout self, inout vout: String, v: Float64):
        vout = my_to_string(v)

    def _as_str(inout self, inout vout: String, v: Bool):
        vout = "true" if v else "false"

    def _as_str(inout self, inout vout: String, v: matrix_t[Float64]):
        vout = ""
        for i in range(v.nrows()):
            for j in range(v.ncols()):
                vout += my_to_string(v[i, j])
                if j < v.ncols() - 1:
                    vout += ","
            vout += ";"

    def _as_str(inout self, inout vout: String, v: List[sp_point]):
        vout = ""
        for i in range(len(v)):
            vout += "[P]" + my_to_string(v[i].x) + "," + my_to_string(v[i].y) + "," + my_to_string(v[i].z)

    def _as_str(inout self, inout vout: String, v: List[Float64]):
        vout = ""
        for i in range(len(v)):
            vout += my_to_string(v[i])
            if i < len(v) - 1:
                vout += ","

    def _as_str(inout self, inout vout: String, v: List[Int]):
        vout = ""
        for i in range(len(v)):
            vout += my_to_string(v[i])
            if i < len(v) - 1:
                vout += ","

    def _as_str(inout self, inout vout: String, v: WeatherData):
        vout = ""
        var S = StringWriter()
        var wp = v.getEntryPointers()
        for i in range(len(wp[0])):
            S.write("[P]")
            for j in range(len(wp)):
                S.write(String(wp[j][i]))
                if j < len(wp) - 1:
                    S.write(",")
        vout = S.str()

    def _as_str(inout self, inout vout: String, v: List[List[sp_point]]):
        """
        [POLY] separates entries
        [P] separates points within a polygon
        ',' separates x,y,z within a point
        """
        vout = ""
        for i in range(len(v)):
            vout += "[POLY]"
            for j in range(len(v[i])):
                vout += "[P]"
                for k in range(3):
                    vout += my_to_string(v[i][j][k])
                    if k < 2:
                        vout += ","
        return

    # Virtual methods (stubs raising exception)
    def set_from_string(self, Val: String) -> Bool: ...
    def as_string(inout self, inout ValAsStr: String): ...
    def as_string(self) -> String: ...
    def combo_select(self, choice: String) -> Bool: ...
    def combo_select_by_choice_index(self, index: Int) -> Bool: ...
    def combo_select_by_mapval(self, mapval: Int) -> Bool: ...
    def combo_get_choices(self) -> List[String]: ...
    def combo_get_count(self) -> Int: ...
    def mapval(self) -> Int: ...
    def combo_get_current_index(self) -> Int: ...
    def get_data_type(self) -> SP_DATTYPE: ...

struct spvar[T: AnyRegType](spbase):
    struct combo_choices:
        var _choices: List[String] = List[String]()
        var _intvals: List[Int] = List[Int]()

        def at_index(self, ind: Int) -> String:
            return self._choices[ind]

        def at(self, choicename: String) -> Int:
            var ind = self.index(choicename)
            if ind < len(self._intvals):
                return self._intvals[ind]
            else:
                raise spexception("Could not locate combo value " + choicename)

        def index(self, choicename: String) -> Int:
            # Find index of choicename in _choices
            for i in range(len(self._choices)):
                if self._choices[i] == choicename:
                    return i
            return -1  # not found, but C++ using find returns npos, we handle as below
            # However the original used find which returns end; if not found, subtract begin gives length
            # To replicate exactly, we need to return len if not found? But usage expects valid.
            # We'll keep as above; but the original find returns position or size() if not found.
            # We'll implement as find returning start index or length.
            # Let's do the original logic:
            var it = self._choices.find(choicename)
            if it == -1:
                return len(self._choices)
            return it

        def clear(inout self):
            self._choices.clear()
            self._intvals.clear()

    var choices: combo_choices = combo_choices()
    var val: T

    # combo functions
    def combo_clear(inout self):
        self.choices.clear()

    def combo_get_choices(self) -> List[String]:
        var nv = len(self.choices._choices)
        var rv = List[String](nv)
        for i in range(nv):
            rv[i] = self.choices._choices[i]
        return rv

    def combo_add_choice(inout self, choicename: String, mval: String):
        var mapint: Int
        to_integer(mval, &mapint)
        self.choices._choices.push_back(choicename)
        self.choices._intvals.push_back(mapint)

    def combo_select_by_choice_index(inout self, index: Int) -> Bool:
        self._setv(self.choices._choices[index], self.val)
        return True

    def combo_select_by_mapval(inout self, mapval: Int) -> Bool:
        var index = self.choices._intvals.find(mapval)
        if index < len(self.choices._intvals):
            self._setv(self.choices._choices[index], self.val)
            return True
        else:
            return False

    def combo_select(inout self, choice: String) -> Bool:
        var ind = self.choices._choices.find(choice)
        if ind < len(self.choices._choices):
            self._setv(choice, self.val)
            return True
        else:
            raise spexception("Invalid combo value specified: " + choice)

    def mapval(self) -> Int:
        var valstr: String
        self._as_str(valstr, self.val)
        return self.choices._intvals[self.choices.index(valstr)]

    def combo_get_current_index(self) -> Int:
        var valstr: String
        self._as_str(valstr, self.val)
        return self.choices.index(valstr)

    def combo_get_count(self) -> Int:
        return len(self.choices._choices)

    # main functions
    def set_from_string(inout self, Val: String) -> Bool:
        var sval = Val
        return self._setv(sval, self.val)

    def as_string(inout self, inout ValAsStr: String):
        self._as_str(ValAsStr, self.val)

    def as_string(self) -> String:
        var vstr: String
        self._as_str(vstr, self.val)
        return vstr

    def set(inout self, Address: String, Dtype: SP_DATTYPE, Value: String, Units: String, Is_param: Bool, Ctrl: String, Special: String, UI_disable: Bool, Label: String, Description: String):
        """
        Parse and set the variable to it's value from a string argument
        """
        self.name = Address
        self.units = Units
        self.ctype = Ctrl
        self.dattype = Dtype
        self.short_desc = Label
        self.long_desc = Description
        self.is_param = Is_param
        self.is_disabled = UI_disable
        self.choices.clear()
        if self.ctype == "combo":
            var ckeys = split(Special, ";")
            for i in range(len(ckeys)):
                var pair = split(ckeys[i], "=")
                self.combo_add_choice(pair[0], pair[1])
            var val_index: Int
            to_integer(Value, &val_index)
            if Special != "":
                self.combo_select_by_choice_index(val_index)
        else:
            var parseok = self._setv(Value, self.val)
            if not parseok:
                raise spexception("An error occurred while assigning input to the internal variable structure. {" + Address + " << " + Value + "}")

struct spout[T: AnyRegType](spbase):
    var _val: T

    def set_from_string(inout self, Val: String) -> Bool:
        var sval = Val
        return self._setv(sval, self._val)

    def as_string(inout self, inout ValAsStr: String):
        self._as_str(ValAsStr, self._val)

    def as_string(self) -> String:
        var vstr: String
        self._as_str(vstr, self._val)
        return vstr

    def setup(inout self, Address: String, Dtype: SP_DATTYPE, Units: String, Is_param: Bool, Ctrl: String, Special: String, UI_disable: Bool, Label: String, Description: String):
        self.name = Address
        self.units = Units
        self.ctype = Ctrl
        self.dattype = Dtype
        self.short_desc = Label
        self.long_desc = Description
        if Ctrl != "":
            raise spexception("Special controls are not allowed for spout objects")
        self.is_param = Is_param
        self.is_disabled = UI_disable

    def Val(self) -> T:
        return self._val

    def Setval(inout self, v: T):
        self._val = v

    def Name(self) -> String:
        return self.name

    def Units(self) -> String:
        return self.units

    def Ctype(self) -> String:
        return self.ctype

    def Dattype(self) -> SP_DATTYPE:
        return self.dattype

    def Short_desc(self) -> String:
        return self.short_desc

    def Long_desc(self) -> String:
        return self.long_desc

    def Is_param(self) -> Bool:
        return self.is_param

    def Is_disabled(self) -> Bool:
        return self.is_disabled

@value
struct mod_base:
    var _working_dir: String = ""

    def checkRange(range: String, inout val: Int, inout flag: Int? = None) -> Bool:
        var dval = Float64(val)
        return self.checkRange(range, dval, flag)

    def checkRange(range: String, inout val: Float64, inout flag: Int? = None) -> Bool:
        var t1 = split(range, ",")
        if len(t1) < 2:
            return True
        var lop: String
        var rop: String
        var ops: String
        var ls: String
        var rs: String
        ls = t1[0]
        rs = t1[1]
        lop = String(ls[0])
        rop = String(rs[len(rs)-1])
        var lval: Float64
        var rval: Float64
        # Erase first character from ls and last from rs
        var ls_trimmed = ls[1:]
        var rs_trimmed = rs[:len(rs)-1]
        to_double(ls_trimmed, &lval)
        to_double(rs_trimmed, &rval)
        var tflag = -1          # return the type of range applied (i.e. less than, greater than | less than or equal to, greater than, etc)
        var retflag = False     # Is the boundary satisfied?
        ops = lop + rop
        if ops == " ":
            return True         # no info, don't check
        elif ops == "()":
            if val > lval and val < rval:
                retflag = True
                tflag = 1
        elif ops == "[)":
            if val >= lval and val < rval:
                retflag = True
                tflag = 2
        elif ops == "(]":
            if val > lval and val <= rval:
                retflag = True
                tflag = 3
        elif ops == "[]":
            if val >= lval and val <= rval:
                retflag = True
                tflag = 4
        else:
            retflag = True
        if flag is not None:
            flag = tflag
        return retflag

    def getWorkingDir(self) -> Pointer[String]:
        return Pointer[String].address_of(self._working_dir)

    def setWorkingDir(inout self, dir: String):
        self._working_dir = dir