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
from math import exp, pow, nan, fabs

# ifndef __pvmodulemodel_h (not needed in Mojo)

const AOI_MIN = 0.5
const AOI_MAX = 89.5

const M_PI = 3.14159265358979323846264338327

# --- Classes from header ---

class pvcelltemp_t:
    var m_err: String
    def __init__(inout self):

    def __del__(owned self):

    def error(self) -> String:
        return self.m_err
    def __call__(inout self, input: inout pvinput_t, module: inout pvmodule_t, opvoltage: Float64, Tcell: inout Float64) -> Bool:
        class pvmodule_t:
    var m_err: String
    def __init__(inout self):

    def __del__(owned self):

    def error(self) -> String:
        return self.m_err
    def AreaRef(self) -> Float64:
        def VmpRef(self) -> Float64:
        def ImpRef(self) -> Float64:
        def VocRef(self) -> Float64:
        def IscRef(self) -> Float64:
        def __call__(inout self, input: inout pvinput_t, TcellC: Float64, opvoltage: Float64, output: inout pvoutput_t) -> Bool:
        class pvinput_t:
    var Ibeam: Float64
    var Idiff: Float64
    var Ignd: Float64
    var Irear: Float64
    var poaIrr: Float64
    var Tdry: Float64
    var Tdew: Float64
    var Wspd: Float64
    var Wdir: Float64
    var Patm: Float64
    var Zenith: Float64
    var IncAng: Float64
    var Elev: Float64
    var Tilt: Float64
    var Azimuth: Float64
    var HourOfDay: Float64
    var radmode: Int
    var usePOAFromWF: Bool

    def __init__(inout self):
        self.Ibeam = nan
        self.Idiff = nan
        self.Ignd = nan
        self.Irear = nan
        self.poaIrr = nan
        self.Tdry = nan
        self.Tdew = nan
        self.Wspd = nan
        self.Wdir = nan
        self.Patm = nan
        self.Zenith = nan
        self.IncAng = nan
        self.Elev = nan
        self.Tilt = nan
        self.Azimuth = nan
        self.HourOfDay = nan
        self.radmode = 0
        self.usePOAFromWF = False

    def __init__(inout self, ib: Float64, id: Float64, ig: Float64, irear: Float64, ip: Float64,
        ta: Float64, td: Float64, ws: Float64, wd: Float64, patm: Float64,
        zen: Float64, inc: Float64,
        elv: Float64, tlt: Float64, azi: Float64,
        hrday: Float64, rmode: Int, up: Bool):
        self.Ibeam = ib
        self.Idiff = id
        self.Ignd = ig
        self.Irear = irear
        self.poaIrr = ip
        self.Tdry = ta
        self.Tdew = td
        self.Wspd = ws
        self.Wdir = wd
        self.Patm = patm
        self.Zenith = zen
        self.IncAng = inc
        self.Elev = elv
        self.Tilt = tlt
        self.Azimuth = azi
        self.HourOfDay = hrday
        self.radmode = rmode
        self.usePOAFromWF = up

class pvoutput_t:
    var Power: Float64
    var Voltage: Float64
    var Current: Float64
    var Efficiency: Float64
    var Voc_oper: Float64
    var Isc_oper: Float64
    var CellTemp: Float64
    var AOIModifier: Float64

    def __init__(inout self):
        self.Power = nan
        self.Voltage = nan
        self.Current = nan
        self.Efficiency = nan
        self.Voc_oper = nan
        self.Isc_oper = nan
        self.CellTemp = nan
        self.AOIModifier = nan

    def __init__(inout self, p: Float64, v: Float64,
        c: Float64, e: Float64,
        voc: Float64, isc: Float64, t: Float64, aoi_modifier: Float64):
        self.Power = p
        self.Voltage = v
        self.Current = c
        self.Efficiency = e
        self.Voc_oper = voc
        self.Isc_oper = isc
        self.CellTemp = t
        self.AOIModifier = aoi_modifier

class spe_module_t(pvmodule_t):
    var VmpNominal: Float64
    var VocNominal: Float64
    var Area: Float64
    var Gamma: Float64
    var Reference: Int
    var fd: Float64
    var Eff: StaticTuple[Float64, 5]
    var Rad: StaticTuple[Float64, 5]

    def __init__(inout self):
        self.VmpNominal = 0.0
        self.VocNominal = 0.0
        self.Area = 0.0
        self.Gamma = 0.0
        self.Reference = 0
        self.fd = 1.0
        for i in range(5):
            self.Eff[i] = 0.0
            self.Rad[i] = 0.0

    @staticmethod
    def eff_interpolate(irrad: Float64, rad: StaticTuple[Float64, 5], eff: StaticTuple[Float64, 5]) -> Float64:
        if irrad < rad[0]:
            return eff[0]
        elif irrad > rad[4]:
            return eff[4]
        var i = 1
        for i in range(1, 5):
            if irrad < rad[i]:
                break
        var i1 = i - 1
        var wx = (irrad - rad[i1]) / (rad[i] - rad[i1])
        return (1 - wx) * eff[i1] + wx * eff[i]

    def WattsStc(self) -> Float64:
        return self.Eff[self.Reference] * self.Rad[self.Reference] * self.Area

    def AreaRef(self) -> Float64 override:
        return self.Area

    def VmpRef(self) -> Float64 override:
        return self.VmpNominal

    def ImpRef(self) -> Float64 override:
        return self.WattsStc() / self.VmpRef()

    def VocRef(self) -> Float64 override:
        return self.VocNominal

    def IscRef(self) -> Float64 override:
        return self.ImpRef() * 1.3

    def __call__(inout self, input: inout pvinput_t, TcellC: Float64, opvoltage: Float64, output: inout pvoutput_t) -> Bool override:
        var idiff = self.fd * (input.Idiff + input.Ignd)
        var dceff: Float64
        var dcpwr: Float64
        if input.radmode != 3 or not input.usePOAFromWF:
            dceff = self.eff_interpolate(input.Ibeam + idiff + input.Irear, self.Rad, self.Eff)
            dcpwr = dceff * (input.Ibeam + idiff + input.Irear) * self.Area
        else:
            dceff = self.eff_interpolate(input.poaIrr, self.Rad, self.Eff)
            dcpwr = dceff * (input.poaIrr) * self.Area
        dcpwr += dcpwr * (self.Gamma / 100.0) * (TcellC - 25.0)
        if dcpwr < 0:
            dcpwr = 0.0
        output.CellTemp = TcellC
        output.Efficiency = dceff
        output.Power = dcpwr
        output.Voltage = self.VmpRef()
        output.Current = output.Power / output.Voltage
        output.Isc_oper = self.IscRef()
        output.Voc_oper = self.VocRef()
        output.AOIModifier = 1.0   # No model for cover effects in simple efficiency model 
        return True

# -------- NR3 GOLDEN METHOD CODE (functions) --------

def shft_3(a: inout Float64, b: inout Float64, c: inout Float64, d: Float64):
    a = b
    b = c
    c = d

def shft_2(a: inout Float64, b: inout Float64, c: Float64):
    a = b
    b = c

def shft_3b(a: inout Float64, b: inout Float64, c: inout Float64, d: Float64):
    a = b
    b = c
    c = d

def fmax(a: Float64, b: Float64) -> Float64:
    return a if a > b else b

def sign(a: Float64, b: Float64) -> Float64:
    return fabs(a) if b >= 0.0 else -fabs(a)

# BEGIN GOLDEN METHOD CODE FROM NR3
var GOLD = 1.618034
var GLIMIT = 100.0
var TINY = 1.0e-20

def mnbrak(ax: inout Float64, bx: inout Float64, cx: inout Float64, fa: inout Float64, fb: inout Float64, fc: inout Float64, f: fn(Float64) -> Float64):
    var ulim: Float64
    var u: Float64
    var r: Float64
    var q: Float64
    var fu: Float64
    var dum: Float64
    fa = f(ax)
    fb = f(bx)
    if fb > fa:
        shft_3(dum, ax, bx, dum)
        shft_3(dum, fb, fa, dum)
    cx = bx + GOLD * (bx - ax)
    fc = f(cx)
    while fb > fc:
        r = (bx - ax) * (fb - fc)
        q = (bx - cx) * (fb - fa)
        u = bx - ((bx - cx) * q - (bx - ax) * r) / (2.0 * sign(fmax(fabs(q - r), TINY), q - r))
        ulim = bx + GLIMIT * (cx - bx)
        if (bx - u) * (u - cx) > 0.0:
            fu = f(u)
            if fu < fc:
                ax = bx
                bx = u
                fa = fb
                fb = fu
                return
            elif fu > fb:
                cx = u
                fc = fu
                return
            u = cx + GOLD * (cx - bx)
            fu = f(u)
        elif (cx - u) * (u - ulim) > 0.0:
            fu = f(u)
            if fu < fc:
                shft_3(bx, cx, u, cx + GOLD * (cx - bx))
                shft_3(fb, fc, fu, f(u))
        elif (u - ulim) * (ulim - cx) >= 0.0:
            u = ulim
            fu = f(u)
        else:
            u = cx + GOLD * (cx - bx)
            fu = f(u)
        shft_3(ax, bx, cx, u)
        shft_3(fa, fb, fc, fu)

var R = 0.61803399
var C = 1.0 - R

def golden(ax: Float64, bx: Float64, f: fn(Float64) -> Float64, tol: Float64, xmin: inout Float64, Result: inout Float64, maxiter: Int) -> Bool:
    var f1: Float64
    var f2: Float64
    var x0: Float64
    var x1: Float64
    var x2: Float64
    var x3: Float64
    var cx: Float64
    var fa: Float64
    var fb: Float64
    var fc: Float64
    var ni = 0
    var ax0 = ax
    var bx0 = bx
    mnbrak(ax, bx, cx, fa, fb, fc, f)
    if ax < ax0:
        ax = ax0
    if ax > bx0:
        ax = bx0
    if bx < ax0:
        bx = ax0
    if bx > bx0:
        bx = bx0
    x0 = ax
    x3 = cx
    if fabs(cx - bx) > fabs(bx - ax):
        x1 = bx
        x2 = bx + C * (cx - bx)
    else:
        x2 = bx
        x1 = bx - C * (bx - ax)
    f1 = f(x1)
    f2 = f(x2)
    while fabs(x3 - x0) > tol * (fabs(x1) + fabs(x2)):
        if f2 < f1:
            shft_3b(x0, x1, x2, R * x1 + C * x3)
            shft_2(f1, f2, f(x2))
        else:
            shft_3b(x3, x2, x1, R * x2 + C * x0)
            shft_2(f2, f1, f(x1))
        if ni > maxiter:
            return False
        ni += 1
    if f1 < f2:
        xmin = x1
        Result = f1
        return True
    else:
        xmin = x2
        Result = f2
        return True

# -------- END GOLDEN METHOD CODE --------

# -------- Five-parameter model functions --------

def max(a: Float64, b: Float64) -> Float64:
    return a if a > b else b

def current_5par(V: Float64, IMR: Float64, A: Float64, IL: Float64, IO: Float64, RS: Float64, RSH: Float64) -> Float64:
    /*
    C     Iterative solution for current as a function of voltage using
    C     equations from the five-parameter model.  Newton's method is used
    C     to converge on a value.  Max power at reference conditions is initial
    C     guess. 
    */
    var IOLD = 0.0
    var V_MODULE = V
    var INEW = IMR
    const maxit = 4000
    var it = 0
    while fabs(INEW - IOLD) > 0.0001:
        IOLD = INEW
        var F = IL - IOLD - IO * (exp((V_MODULE + IOLD * RS) / A) - 1.0) - (V_MODULE + IOLD * RS) / RSH
        var FPRIME = -1.0 - IO * (RS / A) * exp((V_MODULE + IOLD * RS) / A) - (RS / RSH)
        INEW = max(0.0, (IOLD - (F / FPRIME)))
        if it == maxit:
            return -1.0
        it += 1
    return INEW

def current_5par_rec(V: Float64, IMR: Float64, A: Float64, IL: Float64, IO: Float64, RS: Float64, RSH: Float64, D2MuTau: Float64, Vbi: Float64) -> Float64:
    /*
    C     Iterative solution for current as a function of voltage using
    C     equations from the five-parameter model.  Newton's method is used
    C     to converge on a value.  Max power at reference conditions is initial
    C     guess.
    C     2018-04-15 (TR): Added functionality to consider recombination losses
    */
    var IOLD = 0.0
    var V_MODULE = V
    var INEW = IMR
    const maxit = 4000
    var it = 0
    while fabs(INEW - IOLD) > 0.0001:
        IOLD = INEW
        var IREC = IL * D2MuTau / (Vbi - (V_MODULE + IOLD * RS))
        var IREC_DER = (IL * D2MuTau * RS) / pow((Vbi - (V_MODULE + IOLD * RS)), 2)
        var F = IL - IOLD - IO * (exp((V_MODULE + IOLD * RS) / A) - 1.0) - (V_MODULE + IOLD * RS) / RSH - IREC
        var FPRIME = -1.0 - IO * (RS / A) * exp((V_MODULE + IOLD * RS) / A) - (RS / RSH) - IREC_DER
        INEW = max(0.0, (IOLD - (F / FPRIME)))
        if it == maxit:
            return -1.0
        it += 1
    return INEW

def openvoltage_5par(Voc0: Float64, a: Float64, IL: Float64, IO: Float64, Rsh: Float64) -> Float64:
    /*
    C     Iterative solution for open-circuit voltage.  Explicit algebraic solution
    C     not possible in 5-parameter model
    */
    var VocLow = 0.0
    var VocHigh = Voc0 * 1.5
    var Voc = Voc0   # initial guess
    var niter = 0
    while fabs(VocHigh - VocLow) > 0.001:
        var I = IL - IO * (exp(Voc / a) - 1.0) - Voc / Rsh
        if I < 0:
            VocHigh = Voc
        if I > 0:
            VocLow = Voc
        Voc = (VocHigh + VocLow) / 2
        if niter > 5000:
            return -1.0
        niter += 1
    return Voc

def openvoltage_5par_rec(Voc0: Float64, a: Float64, IL: Float64, IO: Float64, Rsh: Float64, D2MuTau: Float64, Vbi: Float64) -> Float64:
    /*
    C     Iterative solution for open-circuit voltage.  Explicit algebraic solution
    C     not possible in 5-parameter model
    C     2018-04-15 (TR): Added functionality to consider recombination losses
    */
    var VocLow = 0.0
    var VocHigh = Voc0 * 1.5
    var Voc = Voc0   # initial guess
    var niter = 0
    while fabs(VocHigh - VocLow) > 0.001:
        var I = IL - IO * (exp(Voc / a) - 1.0) - Voc / Rsh - IL * D2MuTau / (Vbi - Voc)
        if I < 0:
            VocHigh = Voc
        if I > 0:
            VocLow = Voc
        Voc = (VocHigh + VocLow) / 2
        if niter > 5000:
            return -1.0
        niter += 1
    return Voc

struct refparm:
    var a: Float64
    var Il: Float64
    var Io: Float64
    var Rs: Float64
    var Rsh: Float64

struct refparm_rec:
    var a: Float64
    var Il: Float64
    var Io: Float64
    var Rs: Float64
    var Rsh: Float64
    var D2MuTau: Float64
    var Vbi: Float64

def maxpower_5par(Voc_ubound: Float64, a: Float64, Il: Float64, Io: Float64, Rs: Float64, Rsh: Float64,
    __Vmp: inout Float64, __Imp: inout Float64) -> Float64:
    var P: Float64
    var V: Float64
    var I: Float64
    var refdata = refparm(a, Il, Io, Rs, Rsh)
    var powerfunc = fn(v: Float64) -> Float64:
        return -v * current_5par(v, 0.9 * refdata.Il, refdata.a, refdata.Il, refdata.Io, refdata.Rs, refdata.Rsh)
    var maxiter = 5000
    if golden(0.0, Voc_ubound, powerfunc, 1e-4, V, P, maxiter):
        P = -P
        I = 0.0
        if V != 0.0:
            I = P / V
    else:
        P = -999.0
        V = -999.0
        I = -999.0
    __Vmp = V
    __Imp = I
    return P

def maxpower_5par_rec(Voc_ubound: Float64, a: Float64, Il: Float64, Io: Float64, Rs: Float64, Rsh: Float64,
    D2MuTau: Float64, Vbi: Float64, __Vmp: inout Float64, __Imp: inout Float64) -> Float64:
    var P: Float64
    var V: Float64
    var I: Float64
    var refdata = refparm_rec(a, Il, Io, Rs, Rsh, D2MuTau, Vbi)
    var powerfunc_rec = fn(v: Float64) -> Float64:
        return -v * current_5par_rec(v, 0.9 * refdata.Il, refdata.a, refdata.Il, refdata.Io, refdata.Rs, refdata.Rsh, refdata.D2MuTau, refdata.Vbi)
    var maxiter = 5000
    if golden(0.0, Voc_ubound, powerfunc_rec, 1e-4, V, P, maxiter):
        P = -P
        I = 0.0
        if V != 0.0:
            I = P / V
    else:
        P = -999.0
        V = -999.0
        I = -999.0
    __Vmp = V
    __Imp = I
    return P