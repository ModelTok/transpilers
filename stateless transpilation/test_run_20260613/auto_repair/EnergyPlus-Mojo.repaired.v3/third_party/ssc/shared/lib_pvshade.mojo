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
from lib_util import sind, cosd, tand, DTOR
from math import atan2, atan, cos, sin, tan, exp, pow, sqrt, fabs, fmin, fmax, ceil, floor, M_PI
import math
import sys

struct ssinputs:
    var nstrx: Int
    var nmodx: Int
    var nmody: Int
    var nrows: Int
    var length: Float64
    var width: Float64
    var mod_orient: Int
    var str_orient: Int
    var row_space: Float64
    var ndiode: Int
    var Vmp: Float64
    var mask_angle_calc_method: Int
    var FF0: Float64

    def __init__(inout self):
        self.nstrx = 0
        self.nmodx = 0
        self.nmody = 0
        self.nrows = 0
        self.length = 0
        self.width = 0
        self.mod_orient = 0
        self.str_orient = 0
        self.row_space = 0
        self.ndiode = 0
        self.Vmp = 0
        self.mask_angle_calc_method = 0
        self.FF0 = 0

struct ssoutputs:
    var m_dc_derate: Float64
    var m_reduced_diffuse: Float64
    var m_reduced_reflected: Float64
    var m_diffuse_derate: Float64
    var m_reflected_derate: Float64
    var m_shade_frac_fixed: Float64

    def __init__(inout self):
        self.m_dc_derate = 0.0
        self.m_reduced_diffuse = 0.0
        self.m_reduced_reflected = 0.0
        self.m_diffuse_derate = 0.0
        self.m_reflected_derate = 0.0
        self.m_shade_frac_fixed = 0.0

@value
class sssky_diffuse_table:
    var derates_table: Dict[String, Float64]
    var gcr: Float64

    def __init__(inout self):
        self.derates_table = Dict[String, Float64]()
        self.gcr = 0.0

    def init(inout self, surface_tilt: Float64, groundCoverageRatio: Float64):
        self.gcr = groundCoverageRatio
        self.compute(surface_tilt)

    def lookup(inout self, surface_tilt: Float64) -> Float64:
        var buf: String
        buf = String(format("%.3f", surface_tilt))
        if buf in self.derates_table:
            return self.derates_table[buf]
        return self.compute(surface_tilt)

    def compute(inout self, surface_tilt: Float64) -> Float64:
        if self.gcr == 0:
            print("sssky_diffuse_table::compute error: gcr required in initialization")
            sys.exit(1)
        var step: Float64 = 1.0 / 1000.0
        var skydiff: Float64 = 0.0
        var tand_stilt: Float64 = tand(surface_tilt)
        var sind_stilt: Float64 = sind(surface_tilt)
        var Asky: Float64 = M_PI + M_PI / pow((1 + pow(tand_stilt, 2)), 0.5)
        var arg = DynamicVector[Float64](1000)
        var gamma = DynamicVector[Float64](1000)
        var tan_tilt_gamma = DynamicVector[Float64](1000)
        var Asky_shade = DynamicVector[Float64](1000)
        for n in range(1000):
            if surface_tilt != 0:
                arg[n] = (1 / tand_stilt) - (1 / (self.gcr * sind_stilt * (1 - n * step)))
                gamma[n] = (-M_PI / 2) + atan(arg[n])
                tan_tilt_gamma[n] = tan(surface_tilt * DTOR + gamma[n])
                Asky_shade[n] = M_PI + M_PI / pow((1 + tan_tilt_gamma[n] * tan_tilt_gamma[n]), 0.5)
                if (surface_tilt * DTOR + gamma[n]) > (M_PI / 2):
                    Asky_shade[n] = 2 * M_PI - Asky_shade[n]
                skydiff += (Asky_shade[n] / Asky) * step
            else:
                arg[n] = Float64(math.nan)
                gamma[n] = Float64(math.nan)
                tan_tilt_gamma[n] = Float64(math.nan)
                Asky_shade[n] = Asky
                skydiff += step
        var buf: String
        buf = String(format("%.3f", surface_tilt))
        self.derates_table[buf] = skydiff
        return skydiff

def mask_angle_func(x: Float64, R: Float64, B: Float64, tilt_eff: Float64) -> Float64:
    return atan2((B - x) * sind(tilt_eff), (R - B * cosd(tilt_eff) + x * cosd(tilt_eff)))

alias EPS: Float64 = 1.0e-6
alias JMAX: Int = 20
alias JMAXP: Int = (JMAX + 1)
alias K: Int = 5

def trapzd(func: fn(Float64, Float64, Float64, Float64) -> Float64, a: Float64, b: Float64, R: Float64, B: Float64, tilt: Float64, n: Int) -> Float64:
    var x: Float64
    var tnm: Float64
    var sum: Float64
    var del: Float64
    var s: Float64 = 0.0
    var it: Int
    var j: Int
    if n == 1:
        s = 0.5 * (b - a) * (func(a, R, B, tilt) + func(b, R, B, tilt))
        return s
    else:
        it = 1
        for j in range(1, n - 1):
            it <<= 1
        tnm = Float64(it)
        del = (b - a) / tnm
        x = a + 0.5 * del
        sum = 0.0
        for j in range(1, it + 1):
            sum += func(x, R, B, tilt)
            x += del
        s = 0.5 * (s + (b - a) * sum / tnm)
        return s

def polint(xa: DynamicVector[Float64], ya: DynamicVector[Float64], n: Int, x: Float64, y: Float64, dy: Float64):
    var i: Int
    var m: Int
    var ns: Int = 1
    var den: Float64
    var dif: Float64
    var dift: Float64
    var ho: Float64
    var hp: Float64
    var w: Float64
    var c = DynamicVector[Float64](n + 1)
    var d = DynamicVector[Float64](n + 1)
    dif = fabs(x - xa[1])
    for i in range(1, n + 1):
        dift = fabs(x - xa[i])
        if dift < dif:
            ns = i
            dif = dift
        c[i] = ya[i]
        d[i] = ya[i]
    y = ya[ns]
    ns -= 1
    for m in range(1, n):
        for i in range(1, n - m + 1):
            ho = xa[i] - x
            hp = xa[i + m] - x
            w = c[i + 1] - d[i]
            den = ho - hp
            if den != 0:
                den = w / den
            d[i] = hp * den
            c[i] = ho * den
        if 2 * ns < (n - m):
            dy = c[ns + 1]
            y += c[ns + 1]
        else:
            dy = d[ns]
            y += d[ns]
            ns -= 1

def qromb(func: fn(Float64, Float64, Float64, Float64) -> Float64, a: Float64, b: Float64, R: Float64, B: Float64, tilt: Float64) -> Float64:
    var ss: Float64
    var dss: Float64
    var s_arr = DynamicVector[Float64](JMAXP)
    var h_arr = DynamicVector[Float64](JMAXP + 1)
    var j: Int
    h_arr[1] = 1.0
    for j in range(1, JMAX + 1):
        s_arr[j] = trapzd(func, a, b, R, B, tilt, j)
        if j >= K:
            polint(h_arr.slice(j - K, j + 1), s_arr.slice(j - K, j + 1), K, 0.0, ss, dss)
            if fabs(dss) <= EPS * fabs(ss):
                return ss
        h_arr[j + 1] = 0.25 * h_arr[j]
    return 0.0

def diffuse_reduce(
    solzen: Float64,
    stilt: Float64,
    Gb_nor: Float64,
    Gdh: Float64,
    poa_sky: Float64,
    poa_gnd: Float64,
    gcr: Float64,
    alb: Float64,
    nrows: Float64,
    skydiffderates: sssky_diffuse_table,
    reduced_skydiff: Float64,
    Fskydiff: Float64,
    reduced_gnddiff: Float64,
    Fgnddiff: Float64):
    var Gd_poa: Float64 = poa_sky + poa_gnd
    if Gd_poa < 0.1:
        Fskydiff = 1.0
        Fgnddiff = 1.0
        return
    var Gbh: Float64 = Gb_nor * cosd(solzen)
    var B: Float64 = 1.0
    var R: Float64 = B / gcr
    Fskydiff = skydiffderates.lookup(stilt)
    reduced_skydiff = Fskydiff * poa_sky
    var solalt: Float64 = 90 - solzen
    var F1: Float64 = alb * pow(sind(stilt / 2.0), 2)
    var Y1: Float64 = R - B * sind(180.0 - solalt - stilt) / sind(solalt)
    Y1 = fmax(0.00001, Y1)
    var F2: Float64 = 0.5 * (1.0 + Y1 / B - sqrt(pow(Y1, 2) / pow(B, 2) - 2 * Y1 / B * cosd(180 - stilt) + 1.0))
    var F3: Float64 = 0.5 * (1.0 + R / B - sqrt(pow(R, 2) / pow(B, 2) - 2 * R / B * cosd(180 - stilt) + 1.0))
    var Gr1: Float64 = F1 * (Gbh + Gdh)
    var reduced_gnddiff_iso: Float64 = ((F1 + (nrows - 1) * F1 * F2) / nrows) * Gbh + ((F1 + (nrows - 1) * F1 * F3) / nrows) * Gdh
    Fgnddiff = 1.0
    if Gr1 > 0:
        Fgnddiff = reduced_gnddiff_iso / Gr1
    reduced_gnddiff = Fgnddiff * reduced_gnddiff_iso

def selfshade_dc_derate(X: Float64, S: Float64, FF0: Float64, dbh_ratio: Float64, m_d: Float64, Vmp: Float64) -> Float64:
    var Xtemp: Float64 = fmin(X, 0.65)
    var c1: Float64 = (109 * FF0 - 54.3) * exp(-4.5 * X)
    var c2: Float64 = -6 * pow(Xtemp, 2) + 5 * Xtemp + 0.28
    var c3_0: Float64 = (-0.05 * dbh_ratio - 0.01) * X + (0.85 * FF0 - 0.7) * dbh_ratio - 0.085 * FF0 + 0.05
    var c3: Float64 = fmax(c3_0, dbh_ratio - 1.0)
    var eqn5: Float64 = 1.0 - c1 * pow(S, 2) - c2 * S
    var eqn9: Float64 = 0
    if X != 0:
        eqn9 = (X - S * (1 + 0.5 / (Vmp / m_d))) / X
    var eqn10: Float64 = c3 * (S - 1.0) + dbh_ratio
    var reduc: Float64 = fmax(eqn5, eqn9)
    reduc = fmax(reduc, eqn10)
    reduc = X * reduc + (1.0 - X)
    if reduc > 1:
        reduc = 1.0
    if reduc < 0:
        reduc = 0.0
    return reduc

def selfshade_xs_horstr(landscape: Bool,
    W: Float64,
    L: Float64,
    r: Int,
    m: Int,
    n: Int,
    ndiode: Int,
    Fshad: Float64,
    X: Float64,
    S: Float64):
    var g: Float64 = 0
    if landscape:
        var Hs: Float64 = Fshad * Float64(m) * W
        if Hs <= W:
            X = (ceil(Hs / W) / (Float64(m) * Float64(r))) * (Float64(r) - 1.0)
            S = (ceil(Hs * Float64(ndiode) / W) / Float64(ndiode)) * (1.0 - floor(g / L) / Float64(n))
        else:
            X = (ceil(Hs / W) / (Float64(m) * Float64(r))) * (Float64(r) - 1.0)
            S = 1.0
    else:
        var Hs: Float64 = Fshad * Float64(m) * L
        X = (ceil(Hs / L) / (Float64(m) * Float64(r))) * (Float64(r) - 1.0)
        S = 1.0 - (floor(g * Float64(ndiode) / W) / (Float64(ndiode) * Float64(n)))

def ss_exec(
    inputs: ssinputs,
    tilt: Float64,
    azimuth: Float64,
    solzen: Float64,
    solazi: Float64,
    Gb_nor: Float64,
    Gdh: Float64,
    Gb_poa: Float64,
    poa_sky: Float64,
    poa_gnd: Float64,
    albedo: Float64,
    trackmode: Bool,
    linear: Bool,
    shade_frac_1x: Float64,
    skydiffs: sssky_diffuse_table,
    outputs: ssoutputs) -> Bool:
    var m_m: Float64 = Float64(inputs.nmody)
    var m_n: Float64 = Float64(inputs.nmodx)
    var m_d: Float64 = Float64(inputs.ndiode)
    var m_W: Float64 = inputs.width
    var m_L: Float64 = inputs.length
    var m_r: Float64 = Float64(inputs.nrows)
    var m_R: Float64 = inputs.row_space
    if m_R < 0.00001:
        m_R = 0.00001
    var m_B: Float64
    if inputs.mod_orient == 0:
        m_B = m_L * m_m
    else:
        m_B = m_W * m_m
    var m_row_length: Float64
    if inputs.mod_orient == 0:
        m_row_length = m_n * m_W
    else:
        m_row_length = m_n * m_L
    var m_A: Float64 = m_B
    var px: Float64
    var py: Float64
    var S: Float64
    var X: Float64
    var g: Float64
    var Hs: Float64
    var az_eff: Float64 = solazi - azimuth
    if (solzen < 90.0) and (tilt != 0) and (fabs(az_eff) < 90.0):
        py = m_A * (cosd(tilt) + (cosd(az_eff) * sind(tilt) / tand(90.0 - solzen)))
        px = m_A * sind(tilt) * sind(az_eff) / tand(90.0 - solzen)
    else:
        py = 0
        px = 0
    if py == 0:
        g = 0
    else:
        g = m_R * px / py
    g = fmax(g, 0)
    g = fmin(g, m_row_length)
    if (inputs.str_orient == 1) and (inputs.nstrx > 1):
        g = 0
    if py == 0:
        Hs = 0
    else:
        Hs = m_A * (1.0 - m_R / py)
    if trackmode:
        Hs = shade_frac_1x * m_B
    Hs = fmax(Hs, 0.0)
    Hs = fmin(Hs, m_B)
    var relative_shaded_area: Float64 = Hs * (m_row_length - g) / (m_A * m_row_length)
    outputs.m_shade_frac_fixed = relative_shaded_area
    if linear:
        diffuse_reduce(solzen, tilt, Gb_nor, Gdh, poa_sky, poa_gnd, m_B / m_R, albedo, m_r, skydiffs,
            outputs.m_reduced_diffuse, outputs.m_diffuse_derate, outputs.m_reduced_reflected, outputs.m_reflected_derate)
        return True
    if inputs.str_orient == 1:
        if inputs.mod_orient == 1:
            if Hs <= m_W:
                X = (ceil(Hs / m_W) / (m_m * m_r)) * (m_r - 1.0)
                S = (ceil(Hs * m_d / m_W) / m_d) * (1.0 - floor(g / m_L) / m_n)
            else:
                X = (ceil(Hs / m_W) / (m_m * m_r)) * (m_r - 1.0)
                S = 1.0
        else:
            X = (ceil(Hs / m_L) / (m_m * m_r)) * (m_r - 1.0)
            S = 1.0 - (floor(g * m_d / m_W) / (m_d * m_n))
    else:
        if inputs.mod_orient == 0:
            X = 1.0 - (floor(g / m_W) / m_n)
            S = (ceil(Hs / m_L) / (m_m * m_r)) * (m_r - 1.0)
        else:
            X = 1.0 - (floor(g / m_L) / m_n)
            S = (ceil(Hs * m_d / m_W) / (m_d * m_m * m_r)) * (m_r - 1.0)
    if trackmode:
        S = 1
    diffuse_reduce(solzen, tilt, Gb_nor, Gdh, poa_sky, poa_gnd, m_B / m_R, albedo, m_r, skydiffs,
        outputs.m_reduced_diffuse, outputs.m_diffuse_derate, outputs.m_reduced_reflected, outputs.m_reflected_derate)
    var inc_total: Float64 = (Gb_poa + outputs.m_reduced_diffuse + outputs.m_reduced_reflected) / 1000
    var inc_diff: Float64 = (outputs.m_reduced_diffuse + outputs.m_reduced_reflected) / 1000
    var diffuse_globhoriz: Float64 = 0
    if inc_total != 0:
        diffuse_globhoriz = inc_diff / inc_total
    outputs.m_dc_derate = selfshade_dc_derate(X, S, inputs.FF0, diffuse_globhoriz, m_d, inputs.Vmp)
    return True