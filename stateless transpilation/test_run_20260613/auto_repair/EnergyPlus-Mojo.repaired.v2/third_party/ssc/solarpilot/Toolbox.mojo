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

from math import (
    sin, cos, sqrt, atan2, asin, acos, floor, ceil, fabs, pow, tan, atan
)
from time import time, localtime as localtime
from sys import File
from exceptions import spexception
from definitions import PI, to_double

# Helper macro (not needed in Mojo)
# #if defined(_DEBUG) etc. - ignore debug assertions

struct block_t[T: AnyType]:
    var t_array: List[T]
    var n_rows: Int
    var n_cols: Int
    var n_layers: Int

    def __init__(inout self):
        self.t_array = List[T](1)
        self.n_rows = 1
        self.n_cols = 1
        self.n_layers = 1

    def __init__(inout self, other: Self):
        self.n_rows = other.nrows()
        self.n_cols = other.ncols()
        self.n_layers = other.nlayers()
        var nn: Int = self.n_rows * self.n_cols * self.n_layers
        self.t_array = List[T](nn)
        for i in range(nn):
            self.t_array[i] = other.t_array[i]

    def __init__(inout self, nr: Int, nc: Int, nl: Int):
        self.t_array = List[T]()
        self.n_rows = 0
        self.n_cols = 0
        self.n_layers = 0
        var nr_ = nr
        var nc_ = nc
        var nl_ = nl
        if nl_ < 1: nl_ = 1
        if nr_ < 1: nr_ = 1
        if nc_ < 1: nc_ = 1
        self.resize(nr_, nc_, nl_)

    def __init__(inout self, nr: Int, nc: Int, nl: Int, val: T):
        self.t_array = List[T]()
        self.n_rows = 0
        self.n_cols = 0
        self.n_layers = 0
        var nr_ = nr
        var nc_ = nc
        var nl_ = nl
        if nr_ < 1: nr_ = 1
        if nc_ < 1: nc_ = 1
        if nl_ < 1: nl_ = 1
        self.resize(nr_, nc_, nl_)
        self.fill(val)

    # No destructor needed; List handles memory

    def clear(inout self):
        # Note: when Clear() is called before resize() or resize_fill(), it can cause a memory error.
        self.t_array = List[T]()
        self.n_layers = 0
        self.n_rows = 0
        self.n_cols = 0

    def copy(inout self, rhs: Self):
        if self is rhs:
            return
        self.resize(rhs.nlayers(), rhs.nrows(), rhs.ncols())
        var nn: Int = self.n_layers * self.n_rows * self.n_cols
        for i in range(nn):
            self.t_array[i] = rhs.t_array[i]

    def assign(inout self, pvalues: Pointer[T], nr: Int, nc: Int, nl: Int):
        self.resize(nr, nc, nl)
        if self.n_rows == nr and self.n_cols == nc and self.n_layers == nl:
            var len: Int = nr * nc * nl
            for i in range(len):
                self.t_array[i] = pvalues[i]

    # operator= not directly supported; use copy method
    # block_t &operator=(const T &val) -> not used in this file, skip for now

    def equals(self, rhs: Self) -> Bool:
        if self.n_rows != rhs.n_rows or self.n_cols != rhs.n_cols or self.n_layers != rhs.n_layers:
            return False
        var nn: Int = self.n_rows * self.n_cols * self.n_layers
        for i in range(nn):
            if self.t_array[i] != rhs.t_array[i]:
                return False
        return True

    def is_single(self) -> Bool:
        return (self.n_rows == 1 and self.n_cols == 1 and self.n_layers == 1)

    def is_array(self) -> Bool:
        return (self.n_rows == 1 and self.n_layers == 1)

    def fill(inout self, val: T):
        var ncells: Int = self.n_rows * self.n_cols * self.n_layers
        for i in range(ncells):
            self.t_array[i] = val

    def resize(inout self, nr: Int, nc: Int, nl: Int):
        if nr < 1 or nc < 1 or nl < 1: return
        if nr == self.n_rows and nc == self.n_cols and nl == self.n_layers: return
        self.t_array = List[T](nr * nc * nl)
        self.n_rows = nr
        self.n_cols = nc
        self.n_layers = nl

    def resize_fill(inout self, nr: Int, nc: Int, nl: Int, val: T):
        self.resize(nr, nc, nl)
        self.fill(val)

    def resize(inout self, len: Int):
        self.resize(1, len, 1)

    def resize_fill(inout self, len: Int, val: T):
        self.resize_fill(1, len, 1, val)

    def at(self, r: Int, c: Int, l: Int) -> T:
        # debug assertion omitted
        return self.t_array[self.n_layers * (c + r * self.n_cols) + l]

    def set_at(inout self, r: Int, c: Int, l: Int, val: T):
        self.t_array[self.n_layers * (c + r * self.n_cols) + l] = val

    def __getitem__(self, r: Int, c: Int, l: Int) -> T:
        return self.at(r, c, l)

    def __setitem__(inout self, r: Int, c: Int, l: Int, val: T):
        self.set_at(r, c, l, val)

    def nrows(self) -> Int:
        return self.n_rows

    def ncols(self) -> Int:
        return self.n_cols

    def nlayers(self) -> Int:
        return self.n_layers

    def ncells(self) -> Int:
        return self.n_rows * self.n_cols * self.n_layers

    def membytes(self) -> Int:
        return self.n_rows * self.n_cols * self.n_layers * sizeof[T]()

    def size(self) -> (Int, Int, Int):
        return (self.n_rows, self.n_cols, self.n_layers)

    def length(self) -> Int:
        return self.n_cols

    def data(self) -> Pointer[T]:
        return self.t_array.data

    def value(self) -> T:
        return self.t_array[0]


struct matrix_t[T: AnyType]:
    var t_array: List[T]
    var n_rows: Int
    var n_cols: Int

    def __init__(inout self):
        self.t_array = List[T](1)
        self.n_rows = 1
        self.n_cols = 1

    def __init__(inout self, other: Self):
        self.n_rows = other.nrows()
        self.n_cols = other.ncols()
        var nn: Int = self.n_rows * self.n_cols
        self.t_array = List[T](nn)
        for i in range(nn):
            self.t_array[i] = other.t_array[i]

    def __init__(inout self, len: Int):
        self.t_array = List[T]()
        self.n_rows = 0
        self.n_cols = 0
        var len_ = len
        if len_ < 1: len_ = 1
        self.resize(1, len_)

    def __init__(inout self, nr: Int, nc: Int):
        self.t_array = List[T]()
        self.n_rows = 0
        self.n_cols = 0
        var nr_ = nr
        var nc_ = nc
        if nr_ < 1: nr_ = 1
        if nc_ < 1: nc_ = 1
        self.resize(nr_, nc_)

    def __init__(inout self, nr: Int, nc: Int, val: T):
        self.t_array = List[T]()
        self.n_rows = 0
        self.n_cols = 0
        var nr_ = nr
        var nc_ = nc
        if nr_ < 1: nr_ = 1
        if nc_ < 1: nc_ = 1
        self.resize(nr_, nc_)
        self.fill(val)

    def clear(inout self):
        self.t_array = List[T](1)
        self.n_rows = 0
        self.n_cols = 0

    def copy(inout self, rhs: Self):
        if self is rhs:
            return
        self.resize(rhs.nrows(), rhs.ncols())
        var nn: Int = self.n_rows * self.n_cols
        for i in range(nn):
            self.t_array[i] = rhs.t_array[i]

    def assign(inout self, pvalues: Pointer[T], len: Int):
        self.resize(len)
        if self.n_cols == len and self.n_rows == 1:
            for i in range(len):
                self.t_array[i] = pvalues[i]

    def assign(inout self, pvalues: Pointer[T], nr: Int, nc: Int):
        self.resize(nr, nc)
        if self.n_rows == nr and self.n_cols == nc:
            var len: Int = nr * nc
            for i in range(len):
                self.t_array[i] = pvalues[i]

    def equals(self, rhs: Self) -> Bool:
        if self.n_rows != rhs.n_rows or self.n_cols != rhs.n_cols:
            return False
        var nn: Int = self.n_rows * self.n_cols
        for i in range(nn):
            if self.t_array[i] != rhs.t_array[i]:
                return False
        return True

    def is_single(self) -> Bool:
        return (self.n_rows == 1 and self.n_cols == 1)

    def is_array(self) -> Bool:
        return (self.n_rows == 1)

    def fill(inout self, val: T):
        var ncells: Int = self.n_rows * self.n_cols
        for i in range(ncells):
            self.t_array[i] = val

    def resize(inout self, nr: Int, nc: Int):
        if nr < 1 or nc < 1: return
        if nr == self.n_rows and nc == self.n_cols: return
        self.t_array = List[T](nr * nc)
        self.n_rows = nr
        self.n_cols = nc

    def resize_fill(inout self, nr: Int, nc: Int, val: T):
        self.resize(nr, nc)
        self.fill(val)

    def resize(inout self, len: Int):
        self.resize(1, len)

    def resize_fill(inout self, len: Int, val: T):
        self.resize_fill(1, len, val)

    def at(self, c: Int) -> T:
        # debug assertion omitted
        return self.t_array[c]

    def set_at(inout self, c: Int, val: T):
        self.t_array[c] = val

    def at(self, r: Int, c: Int) -> T:
        # debug assertion omitted
        return self.t_array[self.n_cols * r + c]

    def set_at(inout self, r: Int, c: Int, val: T):
        self.t_array[self.n_cols * r + c] = val

    def __getitem__(self, i: Int) -> T:
        return self.t_array[i]

    def __setitem__(inout self, i: Int, val: T):
        self.t_array[i] = val

    # Overload for 2D indexing using tuple
    def __getitem__(self, r: Int, c: Int) -> T:
        return self.at(r, c)

    def __setitem__(inout self, r: Int, c: Int, val: T):
        self.set_at(r, c, val)

    def nrows(self) -> Int:
        return self.n_rows

    def ncols(self) -> Int:
        return self.n_cols

    def ncells(self) -> Int:
        return self.n_rows * self.n_cols

    def membytes(self) -> Int:
        return self.n_rows * self.n_cols * sizeof[T]()

    def size(self) -> (Int, Int):
        return (self.n_rows, self.n_cols)

    def length(self) -> Int:
        return self.n_cols

    def data(self) -> Pointer[T]:
        return self.t_array.data

    def value(self) -> T:
        return self.t_array[0]


struct sp_point:
    var x: Float64
    var y: Float64
    var z: Float64

    def __init__(inout self):
        self.x = 0.0
        self.y = 0.0
        self.z = 0.0

    def __init__(inout self, other: Self):
        self.x = other.x
        self.y = other.y
        self.z = other.z

    def __init__(inout self, X: Float64, Y: Float64, Z: Float64):
        self.x = X
        self.y = Y
        self.z = Z

    def Set(inout self, X: Float64, Y: Float64, Z: Float64):
        self.x = X
        self.y = Y
        self.z = Z

    def Set(inout self, P: Self):
        self.x = P.x
        self.y = P.y
        self.z = P.z

    def Add(inout self, P: Self):
        self.x += P.x
        self.y += P.y
        self.z += P.z

    def Add(inout self, X: Float64, Y: Float64, Z: Float64):
        self.x += X
        self.y += Y
        self.z += Z

    def Subtract(inout self, P: Self):
        self.x += -P.x
        self.y += -P.y
        self.z += -P.z

    def __getitem__(self, index: Int) -> Float64:
        if index == 0:
            return self.x
        elif index == 1:
            return self.y
        elif index == 2:
            return self.z
        else:
            raise spexception("Index out of range in sp_point()")

    def __setitem__(inout self, index: Int, val: Float64):
        if index == 0:
            self.x = val
        elif index == 1:
            self.y = val
        elif index == 2:
            self.z = val
        else:
            raise spexception("Index out of range in sp_point()")

    def __lt__(self, p: Self) -> Bool:
        return self.x < p.x or (self.x == p.x and self.y < p.y)


def operator==(lhs: sp_point, rhs: sp_point) -> Bool:
    return lhs.x == rhs.x and lhs.y == rhs.y and lhs.z == rhs.z


struct Vect:
    var i: Float64
    var j: Float64
    var k: Float64

    def __init__(inout self):
        self.i = 0.0
        self.j = 0.0
        self.k = 0.0

    def __init__(inout self, i: Float64, j: Float64, k: Float64):
        self.i = i
        self.j = j
        self.k = k

    def __init__(inout self, other: Self):
        self.i = other.i
        self.j = other.j
        self.k = other.k

    def Set(inout self, i: Float64, j: Float64, k: Float64):
        self.i = i
        self.j = j
        self.k = k

    def Set(inout self, V: Self):
        self.i = V.i
        self.j = V.j
        self.k = V.k

    def Add(inout self, V: Self):
        self.i += V.i
        self.j += V.j
        self.k += V.k

    def Subtract(inout self, V: Self):
        self.i += -V.i
        self.j += -V.j
        self.k += -V.k

    def Add(inout self, i: Float64, j: Float64, k: Float64):
        self.i += i
        self.j += j
        self.k += k

    def Scale(inout self, m: Float64):
        self.i *= m
        self.j *= m
        self.k *= m

    def __getitem__(self, index: Int) -> Float64:
        if index == 0: return self.i
        if index == 1: return self.j
        if index == 2: return self.k
        raise spexception("Index out of range in Vect()")

    def __setitem__(inout self, index: Int, val: Float64):
        if index == 0: self.i = val
        elif index == 1: self.j = val
        elif index == 2: self.k = val
        else: raise spexception("Index out of range in Vect()")


struct PointVect:
    var p: sp_point
    var v: Vect
    var x: Float64
    var y: Float64
    var z: Float64
    var i: Float64
    var j: Float64
    var k: Float64

    def __init__(inout self, other: Self):
        self.x = other.x
        self.y = other.y
        self.z = other.z
        self.i = other.i
        self.j = other.j
        self.k = other.k
        # p and v are initialized by default constructor

    def __copyinit__(inout self, other: Self):
        self.x = other.x
        self.y = other.y
        self.z = other.z
        self.i = other.i
        self.j = other.j
        self.k = other.k

    def __init__(inout self, px: Float64 = 0.0, py: Float64 = 0.0, pz: Float64 = 0.0, vi: Float64 = 0.0, vj: Float64 = 0.0, vk: Float64 = 1.0):
        self.x = px
        self.y = py
        self.z = pz
        self.i = vi
        self.j = vj
        self.k = vk
        self.p = sp_point()
        self.v = Vect()

    def point(inout self) -> Pointer[sp_point]:
        self.p.Set(self.x, self.y, self.z)
        return Pointer[sp_point](addressof(self.p))

    def vect(inout self) -> Pointer[Vect]:
        self.v.Set(self.i, self.j, self.k)
        return Pointer[Vect](addressof(self.v))


struct DTobj:
    var _year: Int
    var _month: Int
    var _yday: Int
    var _mday: Int
    var _wday: Int
    var _hour: Int
    var _min: Int
    var _sec: Int
    var _ms: Int

    def __init__(inout self):
        self.setZero()

    def setZero(inout self):
        self._year = 0
        self._month = 0
        self._yday = 0
        self._mday = 0
        self._wday = 0
        self._hour = 0
        self._min = 0
        self._sec = 0
        self._ms = 0

    def Now(inout self) -> Pointer[Self]:
        var now: tm
        # Simplified: use localtime
        var now_time: Int = time()
        var now_tm: tm = localtime(now_time)
        self._year = now_tm.tm_year + 1900
        self._month = now_tm.tm_mon
        self._yday = now_tm.tm_yday
        self._mday = now_tm.tm_mday
        self._wday = now_tm.tm_wday
        self._hour = now_tm.tm_hour
        self._min = now_tm.tm_min
        self._sec = now_tm.tm_sec
        self._ms = 0
        return Pointer[Self](addressof(self))


struct DateTime(DTobj):
    var monthLength: List[Int]

    def __init__(inout self):
        self.monthLength = List[Int](12)
        self.setDefaults()

    def __init__(inout self, DT: DTobj):
        self._year = DT._year
        self._month = DT._month
        self._yday = DT._yday
        self._mday = DT._mday
        self._wday = DT._wday
        self._hour = DT._hour
        self._min = DT._min
        self._sec = DT._sec
        self._ms = DT._ms
        self.monthLength = List[Int](12)
        self.SetMonthLengths(self._year)

    def __init__(inout self, doy: Float64, hour: Float64):
        self.monthLength = List[Int](12)
        var hr: Int = Int(floor(hour))
        var minutes: Float64 = 60.0 * (hour - Float64(hr))
        var min: Int = Int(floor(minutes))
        var sec: Int = Int(60.0 * (minutes - Float64(min)))
        self.setZero()
        self.SetYearDay(Int(doy + 0.001))
        self.SetHour(hr)
        self.SetMinute(min)
        self.SetSecond(sec)

    def GetYear(self) -> Int:
        return self._year
    def GetMonth(self) -> Int:
        return self._month
    def GetYearDay(self) -> Int:
        return self._yday
    def GetMonthDay(self) -> Int:
        return self._mday
    def GetWeekDay(self) -> Int:
        return self._wday
    def GetMinute(self) -> Int:
        return self._min
    def GetSecond(self) -> Int:
        return self._sec
    def GetMillisecond(self) -> Int:
        return self._ms

    def SetYear(inout self, val: Int):
        self._year = val
        self.SetMonthLengths(self._year)
    def SetMonth(inout self, val: Int):
        self._month = val
    def SetYearDay(inout self, val: Int):
        self._yday = val
    def SetMonthDay(inout self, val: Int):
        self._mday = val
    def SetWeekDay(inout self, val: Int):
        self._wday = val
    def SetHour(inout self, val: Int):
        self._hour = val
    def SetMinute(inout self, val: Int):
        self._min = val
    def SetSecond(inout self, val: Int):
        self._sec = val
    def SetMillisecond(inout self, val: Int):
        self._ms = val

    def setDefaults(inout self):
        self.setZero()
        var N: DTobj
        N.Now()
        self.SetYear(2011)
        self.SetMonth(6)
        self.SetMonthDay(21)
        self.SetYearDay(self.GetDayOfYear())
        self.SetHour(12)

    def SetDate(inout self, year: Int, month: Int, day: Int):
        self.SetYear(year)
        self.SetMonth(month)
        self.SetMonthDay(day)
        self.SetMonthLengths(self._year)
        self.SetYearDay(self.GetDayOfYear(year, month, day))

    def SetMonthLengths(inout self, year: Int):
        for i in range(0, 12, 2):
            self.monthLength[i] = 31
        for i in range(1, 12, 2):
            self.monthLength[i] = 30
        self.monthLength[1] = 28
        if year % 4 == 0:
            self.monthLength[1] = 29
        if year % 100 == 0:
            if year % 400 == 0:
                self.monthLength[1] = 29
            else:
                self.monthLength[1] = 28

    def GetDayOfYear(self) -> Int:
        return self.GetDayOfYear(self._year, self._month, self._mday)

    def GetDayOfYear(self, year: Int, month: Int, mday: Int) -> Int:
        var doy: Int = 0
        if month > 1:
            for i in range(month - 1):
                doy += self.monthLength[i]
        doy += mday
        return doy

    @staticmethod
    def CalculateDayOfYear(year: Int, month: Int, mday: Int) -> Int:
        var monthLength = List[Int](12)
        for i in range(0, 12, 2):
            monthLength[i] = 31
        for i in range(1, 12, 2):
            monthLength[i] = 30
        monthLength[1] = 28
        if year % 4 == 0:
            monthLength[1] = 29
        if year % 100 == 0:
            if year % 400 == 0:
                monthLength[1] = 29
            else:
                monthLength[1] = 28
        var doy: Int = 0
        if month > 1:
            for i in range(month - 1):
                doy += monthLength[i]
        doy += mday
        return doy

    def GetHourOfYear(self) -> Int:
        var doy: Int = self.GetDayOfYear()
        var hr: Int = (doy - 1) * 24 + self._hour
        return hr

    def hours_to_date(self, hours: Float64, month: Pointer[Int], day_of_month: Pointer[Int]):
        # Take hour of the year (0-8759) and convert it to month and day of the month.
        # If the year is not provided, the default is 2011 (no leap year)
        # Month = 1-12
        # Day = 1-365
        var days: Float64 = hours / 24.0
        var dsum: Int = 0
        for i in range(12):
            dsum += self.monthLength[i]
            if days <= Float64(dsum):
                month[] = i + 1
                break
        day_of_month[] = Int(floor(days - Float64(dsum - self.monthLength[month[] - 1]))) + 1

    @staticmethod
    def GetMonthName(month: Int) -> String:
        if month == 1: return "January"
        elif month == 2: return "February"
        elif month == 3: return "March"
        elif month == 4: return "April"
        elif month == 5: return "May"
        elif month == 6: return "June"
        elif month == 7: return "July"
        elif month == 8: return "August"
        elif month == 9: return "September"
        elif month == 10: return "October"
        elif month == 11: return "November"
        elif month == 12: return "December"
        else: return ""


struct WeatherData:
    var v_ptrs: List[Pointer[List[Float64]]]
    var _N_items: Int
    var Day: List[Float64]
    var Hour: List[Float64]
    var Month: List[Float64]
    var DNI: List[Float64]
    var T_db: List[Float64]
    var Pres: List[Float64]
    var V_wind: List[Float64]
    var Step_weight: List[Float64]

    def __init__(inout self):
        self.Day = List[Float64]()
        self.Hour = List[Float64]()
        self.Month = List[Float64]()
        self.DNI = List[Float64]()
        self.T_db = List[Float64]()
        self.Pres = List[Float64]()
        self.V_wind = List[Float64]()
        self.Step_weight = List[Float64]()
        self.v_ptrs = List[Pointer[List[Float64]]](8)
        self.initPointers()

    def __init__(inout self, wd: Self):
        self._N_items = wd._N_items
        self.Day = wd.Day.copy()
        self.Hour = wd.Hour.copy()
        self.Month = wd.Month.copy()
        self.DNI = wd.DNI.copy()
        self.T_db = wd.T_db.copy()
        self.Pres = wd.Pres.copy()
        self.V_wind = wd.V_wind.copy()
        self.Step_weight = wd.Step_weight.copy()
        self.v_ptrs = List[Pointer[List[Float64]]](8)
        self.initPointers()

    def initPointers(inout self):
        # Using pointers to the member lists (addresses)
        self.v_ptrs[0] = Pointer[List[Float64]](addressof(self.Day))
        self.v_ptrs[1] = Pointer[List[Float64]](addressof(self.Hour))
        self.v_ptrs[2] = Pointer[List[Float64]](addressof(self.Month))
        self.v_ptrs[3] = Pointer[List[Float64]](addressof(self.DNI))
        self.v_ptrs[4] = Pointer[List[Float64]](addressof(self.T_db))
        self.v_ptrs[5] = Pointer[List[Float64]](addressof(self.Pres))
        self.v_ptrs[6] = Pointer[List[Float64]](addressof(self.V_wind))
        self.v_ptrs[7] = Pointer[List[Float64]](addressof(self.Step_weight))
        self._N_items = self.Day.size

    def resizeAll(inout self, size: Int, val: Float64 = 0.0):
        for i in range(self.v_ptrs.size):
            var vec = self.v_ptrs[i]
            vec[].resize(size, val)
        self._N_items = size

    def clear(inout self):
        for i in range(self.v_ptrs.size):
            var vec = self.v_ptrs[i]
            vec[].clear()
        self._N_items = 0

    def getStep(self, step: Int, day: Pointer[Float64], hour: Pointer[Float64], dni: Pointer[Float64], step_weight: Pointer[Float64]):
        day[] = self.Day[step]
        hour[] = self.Hour[step]
        dni[] = self.DNI[step]
        step_weight[] = self.Step_weight[step]

    def getStep(self, step: Int, day: Pointer[Float64], hour: Pointer[Float64], month: Pointer[Float64], dni: Pointer[Float64], tdb: Pointer[Float64], pres: Pointer[Float64], vwind: Pointer[Float64], step_weight: Pointer[Float64]):
        var args: List[Pointer[Float64]] = List[Pointer[Float64]](8)
        args[0] = day
        args[1] = hour
        args[2] = month
        args[3] = dni
        args[4] = tdb
        args[5] = pres
        args[6] = vwind
        args[7] = step_weight
        for i in range(self.v_ptrs.size):
            var vec = self.v_ptrs[i]
            args[i][] = vec[][step]

    def append(inout self, day: Float64, hour: Float64, dni: Float64, step_weight: Float64):
        self.Day.append(day)
        self.Hour.append(hour)
        self.DNI.append(dni)
        self.Step_weight.append(step_weight)
        self._N_items += 1

    def append(inout self, day: Float64, hour: Float64, month: Float64, dni: Float64, tdb: Float64, pres: Float64, vwind: Float64, step_weight: Float64):
        self.Day.append(day)
        self.Hour.append(hour)
        self.Month.append(month)
        self.DNI.append(dni)
        self.T_db.append(tdb)
        self.Pres.append(pres)
        self.V_wind.append(vwind)
        self.Step_weight.append(step_weight)
        self._N_items += 1

    def setStep(inout self, step: Int, day: Float64, hour: Float64, dni: Float64, step_weight: Float64):
        self.Day[step] = day
        self.Hour[step] = hour
        self.DNI[step] = dni
        self.Step_weight[step] = step_weight

    def setStep(inout self, step: Int, day: Float64, hour: Float64, month: Float64, dni: Float64, tdb: Float64, pres: Float64, vwind: Float64, step_weight: Float64):
        self.Day[step] = day
        self.Hour[step] = hour
        self.Month[step] = month
        self.DNI[step] = dni
        self.T_db[step] = tdb
        self.Pres[step] = pres
        self.V_wind[step] = vwind
        self.Step_weight[step] = step_weight

    def getEntryPointers(inout self) -> Pointer[List[Pointer[List[Float64]]]]:
        return Pointer[List[Pointer[List[Float64]]]](addressof(self.v_ptrs))

    def size(self) -> Int:
        return self._N_items


struct Toolbox:
    @staticmethod
    def round(x: Float64) -> Float64:
        return fabs(x - ceil(x)) > 0.5 ? floor(x) : ceil(x)

    @staticmethod
    def factorial(x: Int) -> Int:
        var f: Int = x
        for i in range(1, x):
            var j: Int = x - i
            f = f * j
        if f < 1: f = 1
        return f

    @staticmethod
    def factorial_d(x: Int) -> Float64:
        return Float64(Toolbox.factorial(x))

    @staticmethod
    def writeMatD(dir: String, name: String, mat: matrix_t[Float64], clear: Bool = False):
        var path: String = dir + "/matrix_data_log.txt"
        var mode: String = "a"
        if clear: mode = "w"
        var file = File(path, mode)
        var nr: Int = mat.nrows()
        var nc: Int = mat.ncols()
        file.write(name + "\n")
        for i in range(nr):
            for j in range(nc):
                file.write("{:e}\t".format(mat[i, j]))
            file.write("\n")
        file.write("\n")
        file.close()

    @staticmethod
    def writeMatD(dir: String, name: String, mat: block_t[Float64], clear: Bool = False):
        var path: String = dir + "/matrix_data_log.txt"
        var mode: String = "a"
        if clear: mode = "w"
        var file = File(path, mode)
        var nr: Int = mat.nrows()
        var nc: Int = mat.ncols()
        var nl: Int = mat.nlayers()
        file.write(name + "\n")
        for k in range(nl):
            file.write("{:d}--\n".format(k))
            for i in range(nr):
                for j in range(nc):
                    file.write("{:e}\t".format(mat[i, j, k]))
                file.write("\n")
        file.write("\n")
        file.close()

    @staticmethod
    def swap(inout a: Float64, inout b: Float64):
        var xt: Float64 = a
        a = b
        b = xt

    @staticmethod
    def swap(inout a: Float64, inout b: Float64):
        # Overload for pointers? We'll just use the same signature with inout.
        # In C++ there are two overloads: (double &, double &) and (double *, double *).
        # In Mojo, we can use pointers.

    # We'll handle pointer version separately
    @staticmethod
    def swap_ptr(inout a: Float64, inout b: Float64):
        var xt: Float64 = a
        a = b
        b = xt
    # Actually the second overload uses pointers. We'll implement it as:
    @staticmethod
    def swap(inout a: Pointer[Float64], inout b: Pointer[Float64]):
        var xt: Float64 = a[]
        a[] = b[]
        b[] = xt

    @staticmethod
    def atan3(inout x: Float64, inout y: Float64) -> Float64:
        var v: Float64 = atan2(x, y)
        if v < 0.0: v += 2.0 * PI
        return v

    @staticmethod
    def map_profiles(source: Pointer[Float64], nsource: Int, dest: Pointer[Float64], ndest: Int, weights: Pointer[Float64] = Pointer[Float64]()):
        # Take a source array 'source(nsource)' and map the values to 'dest(ndest)'.
        # This method creates an integral-conserved map of values in 'dest' that may have a
        # different number of elements than 'source'. The size of each node within 'source'
        # is optionally specified by the 'weights(nsource)' array. If all elements are of the
        # same size, set weights=(double*)NULL or omit the optional argument.
        var wsize: Pointer[Float64]
        var wtot: Float64 = 0.0
        if weights:
            wsize = Pointer[Float64].alloc(nsource)
            for i in range(nsource):
                wtot += weights[i]
                wsize[i] = weights[i]
        else:
            wsize = Pointer[Float64].alloc(nsource)
            for i in range(nsource):
                wsize[i] = 1.0
            wtot = Float64(nsource)
        var delta_D: Float64 = wtot / Float64(ndest)
        var i: Int = 0
        var ix: Float64 = 0.0
        for j in range(ndest):
            dest[j] = 0.0
            var jx: Float64 = Float64(j + 1) * delta_D
            var jx0: Float64 = Float64(j) * delta_D
            if ix - jx0 > 0:
                dest[j] += (ix - jx0) * source[i - 1]
            while ix < jx:
                ix += wsize[i]
                dest[j] += wsize[i] * source[i]
                i += 1
            if ix > jx:
                dest[j] += -(ix - jx) * source[i - 1]
            dest[j] *= 1.0 / delta_D
        del wsize

    @staticmethod
    def pointInPolygon(poly: List[sp_point], pt: sp_point) -> Bool:
        # This subroutine takes a polynomial array containing L_poly vertices (X,Y,Z) and a
        # single point (X,Y,Z) and determines whether the point lies within the polygon. If so,
        # the algorithm returns TRUE (otherwise FALSE)
        var wind: Int = Toolbox.polywind(poly, pt)
        if wind == -1 or wind == 1:
            return True
        else:
            return False

    @staticmethod
    def projectPolygon(inout poly: List[sp_point], inout plane: PointVect) -> List[sp_point]:
        # Take a polygon with points in three dimensions (X,Y,Z) and project all points onto a plane defined
        # by the point-vector {x,y,z,i,j,k}. The subroutine returns a new polygon with the adjusted points all
        # lying on the plane. The points are also assigned vector values corresponding to the normal vector
        # of the plane that they lie in.
        var dist: Float64
        var A: Float64
        var B: Float64
        var C: Float64
        var D: Float64
        var pt: sp_point
        var Lpoly: Int = poly.size
        var FPoly = List[sp_point](Lpoly)
        A = plane.i
        B = plane.j
        C = plane.k
        var uplane: Vect
        uplane.Set(A, B, C)
        Toolbox.vectmag(uplane)  # This function doesn't return? It modifies? Actually it's void. Just compute magnitude.
        D = -A * plane.x - B * plane.y - C * plane.z
        for i in range(Lpoly):
            pt = poly[i]
            dist = -(A * pt.x + B * pt.y + C * pt.z + D) / Toolbox.vectmag(*plane.vect())
            FPoly[i] = sp_point(pt.x + dist * A, pt.y + dist * B, pt.z + dist * C)
        return FPoly

    @staticmethod
    def polywind(vt: List[sp_point], pt: sp_point) -> Int:
        # Determine the winding number of a polygon with respect to a point.
        var i: Int
        var np: Int
        var wind: Int = 0
        var which_ign: Int
        var d0: Float64 = 0.0
        var d1: Float64 = 0.0
        var p0: Float64 = 0.0
        var p1: Float64 = 0.0
        var pt0: Float64 = 0.0
        var pt1: Float64 = 0.0
        var v1: Vect
        var v2: Vect
        v1.Set(vt[0].x - vt[1].x, vt[0].y - vt[1].y, vt[0].z - vt[1].z)
        v2.Set(vt[2].x - vt[1].x, vt[2].y - vt[1].y, vt[2].z - vt[1].z)
        var pn: Vect = Toolbox.crossprod(v1, v2)
        which_ign = 1
        if fabs(pn.j) > fabs(pn.i):
            which_ign = 1
        if fabs(pn.k) > fabs(pn.j):
            which_ign = 2
        if fabs(pn.i) > fabs(pn.k):
            which_ign = 0
        np = vt.size
        if which_ign == 0:
            pt0 = pt.y
            pt1 = pt.z
            p0 = vt[np - 1].y
            p1 = vt[np - 1].z
        elif which_ign == 1:
            pt0 = pt.x
            pt1 = pt.z
            p0 = vt[np - 1].x
            p1 = vt[np - 1].z
        elif which_ign == 2:
            pt0 = pt.x
            pt1 = pt.y
            p0 = vt[np - 1].x
            p1 = vt[np - 1].y
        for i in range(np):
            if which_ign == 0:
                d0 = vt[i].y
                d1 = vt[i].z
            elif which_ign == 1:
                d0 = vt[i].x
                d1 = vt[i].z
            elif which_ign == 2:
                d0 = vt[i].x
                d1 = vt[i].y
            if p1 <= pt1:
                if d1 > pt1 and (p0 - pt0) * (d1 - pt1) - (p1 - pt1) * (d0 - pt0) > 0:
                    wind += 1
            else:
                if d1 <= pt1 and (p0 - pt0) * (d1 - pt1) - (p1 - pt1) * (d0 - pt0) < 0:
                    wind -= 1
            p0 = d0
            p1 = d1
        return wind

    @staticmethod
    def crossprod(A: Vect, B: Vect) -> Vect:
        var res: Vect
        res.i = A.j * B.k - A.k * B.j
        res.j = A.k * B.i - A.i * B.k
        res.k = A.i * B.j - A.j * B.i
        return res

    @staticmethod
    def crossprod(O: sp_point, A: sp_point, B: sp_point) -> Float64:
        return (A.x - O.x) * (B.y - O.y) - (A.y - O.y) * (B.x - O.x)

    @staticmethod
    def unitvect(inout A: Vect):
        var M: Float64 = Toolbox.vectmag(A)
        if M == 0.0:
            A.i = 0.0
            A.j = 0.0
            A.k = 0.0
            return
        A.i /= M
        A.j /= M
        A.k /= M

    @staticmethod
    def dotprod(A: Vect, B: Vect) -> Float64:
        return (A.i * B.i + A.j * B.j + A.k * B.k)

    @staticmethod
    def dotprod(A: Vect, B: sp_point) -> Float64:
        return (A.i * B.x + A.j * B.y + A.k * B.z)

    @staticmethod
    def vectmag(A: Vect) -> Float64:
        return sqrt(pow(A.i, 2) + pow(A.j, 2) + pow(A.k, 2))

    @staticmethod
    def vectmag(P: sp_point) -> Float64:
        return sqrt(pow(P.x, 2) + pow(P.y, 2) + pow(P.z, 3))

    @staticmethod
    def vectmag(i: Float64, j: Float64, k: Float64) -> Float64:
        return sqrt(pow(i, 2) + pow(j, 2) + pow(k, 2))

    @staticmethod
    def vectangle(A: Vect, B: Vect) -> Float64:
        return acos(Toolbox.dotprod(A, B) / (Toolbox.vectmag(A) * Toolbox.vectmag(B)))

    @staticmethod
    def rotation(theta: Float64, axis: Int, inout V: Vect):
        var p: sp_point
        p.Set(V.i, V.j, V.k)
        Toolbox.rotation(theta, axis, p)
        V.Set(p.x, p.y, p.z)

    @staticmethod
    def rotation(theta: Float64, axis: Int, inout P: sp_point):
        # This method takes a point, a rotation angle, and the axis of rotation and
        # rotates the point about the origin in the specified direction.
        var MR0i: Float64
        var MR0j: Float64
        var MR0k: Float64
        var MR1i: Float64
        var MR1j: Float64
        var MR1k: Float64
        var MR2i: Float64
        var MR2j: Float64
        var MR2k: Float64
        var costheta: Float64 = cos(theta)
        var sintheta: Float64 = sin(theta)
        if axis == 0:  # X axis
            MR0i = 1.0; MR0j = 0.0; MR0k = 0.0
            MR1i = 0.0; MR1j = costheta; MR1k = sintheta
            MR2i = 0.0; MR2j = -sintheta; MR2k = costheta
        elif axis == 1:  # Y axis
            MR0i = costheta; MR0j = 0.0; MR0k = -sintheta
            MR1i = 0.0; MR1j = 1.0; MR1k = 0.0
            MR2i = sintheta; MR2j = 0.0; MR2k = costheta
        elif axis == 2:  # Z axis
            MR0i = costheta; MR0j = sintheta; MR0k = 0.0
            MR1i = -sintheta; MR1j = costheta; MR1k = 0.0
            MR2i = 0.0; MR2j = 0.0; MR2k = 1.0
        else:
            raise spexception("Internal error: invalid axis number specified in rotation() method.")
        var Pcx: Float64 = P.x
        var Pcy: Float64 = P.y
        var Pcz: Float64 = P.z
        P.x = MR0i * Pcx + MR0j * Pcy + MR0k * Pcz
        P.y = MR1i * Pcx + MR1j * Pcy + MR1k * Pcz
        P.z = MR2i * Pcx + MR2j * Pcy + MR2k * Pcz
        return

    @staticmethod
    def plane_intersect(P: sp_point, N: Vect, C: sp_point, L: Vect, Int: sp_point) -> Bool:
        # Determine the intersection point of a line and a plane.
        var PC: List[Float64] = List[Float64](3)
        var LdN: Float64
        var PCdN: Float64
        var d: Float64
        PC[0] = P[0] - C[0]
        PC[1] = P[1] - C[1]
        PC[2] = P[2] - C[2]
        LdN = 0.0
        LdN += L[0] * N[0]
        LdN += L[1] * N[1]
        LdN += L[2] * N[2]
        PCdN = 0.0
        PCdN += PC[0] * N[0]
        PCdN += PC[1] * N[1]
        PCdN += PC[2] * N[2]
        if LdN == 0.0: return False
        d = PCdN / LdN
        Int.x = C.x + d * L.i
        Int.y = C.y + d * L.j
        Int.z = C.z + d * L.k
        return True

    @staticmethod
    def line_norm_intersect(line_p0: sp_point, line_p1: sp_point, P: sp_point, I: sp_point, rad: Float64) -> Bool:
        # Note: 2D implementation (no Z component)
        if line_p0.x == line_p1.x:
            var Iyr: Float64 = (P.y - line_p0.y) / (line_p1.y - line_p0.y)
            if Iyr < 0.0:  # out of bounds on the p0 side
                I.Set(line_p0.x, line_p0.y, 0.0)
                rad = Toolbox.vectmag(I.x - P.x, I.y - P.y, 0.0)
                return False
            elif Iyr > 1.0:
                I.Set(line_p1.x, line_p1.y, 0.0)
                rad = Toolbox.vectmag(I.x - P.x, I.y - P.y, 0.0)
                return False
            I.Set(line_p0.x, P.y, 0.0)
        else:
            var drdx: Float64 = (line_p1.y - line_p0.y) / (line_p1.x - line_p0.x)
            var drdx_sq: Float64 = pow(drdx, 2.0)
            I.x = (P.x + P.y * drdx - line_p0.y * drdx + line_p0.x * drdx_sq) / (1.0 + drdx_sq)
            var Ixr: Float64 = (I.x - line_p0.x) / (line_p1.x - line_p0.x)
            if Ixr < 0.0:  # outside the bounds on the p0 side
                I.x = line_p0.x
                I.y = line_p0.y
                rad = Toolbox.vectmag(I.x - P.x, I.y - P.y, 0.0)
                return False
            elif Ixr > 1.0:
                I.x = line_p1.x
                I.y = line_p1.y
                rad = Toolbox.vectmag(I.x - P.x, I.y - P.y, 0.0)
                return False
            I.y = line_p0.y + (I.x - line_p0.x) * drdx
        rad = Toolbox.vectmag(I.x - P.x, I.y - P.y, 0.0)
        return True

    @staticmethod
    def ellipse_bounding_box(inout A: Float64, inout B: Float64, inout phi: Float64, sides: Pointer[Float64], cx: Float64 = 0.0, cy: Float64 = 0.0):
        var tx: Float64 = atan2(-B * tan(phi), A)
        var txx: Float64 = A * cos(tx) * cos(phi) - B * sin(tx) * sin(phi)
        sides[0] = cx + txx / 2.0
        sides[1] = cx - txx / 2.0
        if sides[1] < sides[0]:
            Toolbox.swap_ptr(sides[0], sides[1])
        var ty: Float64 = atan2(-B, tan(phi) * A)
        var tyy: Float64 = B * sin(ty) * cos(phi) - A * cos(ty) * sin(phi)
        sides[2] = cy + tyy / 2.0
        sides[3] = cy - tyy / 2.0
        if sides[3] < sides[2]:
            Toolbox.swap_ptr(sides[3], sides[2])

    @staticmethod
    def convex_hull(inout points: List[sp_point], inout hull: List[sp_point]):
        # Returns a list of points on the convex hull in counter-clockwise order.
        var n: Int = points.size
        var k: Int = 0
        var H = List[sp_point](2 * n)
        var pointscpy = List[sp_point]()
        pointscpy.reserve(points.size)
        for i in range(points.size):
            pointscpy.append(points[i])
        sort(pointscpy)
        for i in range(n):
            while k >= 2 and Toolbox.crossprod(H[k - 2], H[k - 1], pointscpy[i]) <= 0:
                k -= 1
            H[k] = pointscpy[i]
            k += 1
        var t: Int = k + 1
        for i in range(n - 2, -1, -1):
            while k >= t and Toolbox.crossprod(H[k - 2], H[k - 1], pointscpy[i]) <= 0:
                k -= 1
            H[k] = pointscpy[i]
            k += 1
        # H.resize(k)
        hull = H[:k]

    @staticmethod
    def area_polygon(inout points: List[sp_point]) -> Float64:
        # INPUT: vector<sp_point> a list of 'sp_point' objects.
        # OUTPUT: Return the total area
        if points.size == 0:
            return 0.0
        points.append(points[0])
        var npt: Int = points.size
        var area: Float64 = 0.0
        for i in range(npt - 1):
            var w: Float64 = points[i].x - points[i + 1].x
            var ybar: Float64 = (points[i].y + points[i + 1].y) * 0.5
            area += w * ybar
        points.pop_back()
        return area

    @staticmethod
    def clipPolygon(inout A: List[sp_point], inout B: List[sp_point]) -> List[sp_point]:
        # Compute the polygon that forms the intersection of two polygons
        var P = polyclip()
        return P.clip(A, B)

    @staticmethod
    def BezierQ(inout start: sp_point, inout control: sp_point, inout end: sp_point, t: Float64, inout result: sp_point):
        # Locate a point 'result' along a quadratic Bezier curve.
        var tc: Float64 = 1.0 - t
        result.x = tc * tc * start.x + 2.0 * (1.0 - t) * t * control.x + t * t * end.x
        result.y = tc * tc * start.y + 2.0 * (1.0 - t) * t * control.y + t * t * end.y
        result.z = tc * tc * start.z