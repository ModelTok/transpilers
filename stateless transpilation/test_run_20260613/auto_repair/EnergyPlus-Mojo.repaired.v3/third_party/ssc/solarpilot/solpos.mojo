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
/*============================================================================
*    Contains:
*        S_solpos     (computes solar position and intensity
*                      from time and place)
*
*            INPUTS:     (via posdata struct) year, daynum, hour,
*                        minute, second, latitude, longitude, timezone,
*                        intervl
*            OPTIONAL:   (via posdata struct) month, day, press, temp, tilt,
*                        aspect, function
*            OUTPUTS:    EVERY variable in the struct posdata
*                            (defined in solpos.h)
*
*                       NOTE: Certain conditions exist during which some of
*                       the output variables are undefined or cannot be
*                       calculated.  In these cases, the variables are
*                       returned with flag values indicating such.  In other
*                       cases, the variables may return a realistic, though
*                       invalid, value. These variables and the flag values
*                       or invalid conditions are listed below:
*
*                       amass     -1.0 at zenetr angles greater than 93.0
*                                 degrees
*                       ampress   -1.0 at zenetr angles greater than 93.0
*                                 degrees
*                       azim      invalid at zenetr angle 0.0 or latitude
*                                 +/-90.0 or at night
*                       elevetr   limited to -9 degrees at night
*                       etr       0.0 at night
*                       etrn      0.0 at night
*                       etrtilt   0.0 when cosinc is less than 0
*                       prime     invalid at zenetr angles greater than 93.0
*                                 degrees
*                       sretr     +/- 2999.0 during periods of 24 hour sunup or
*                                 sundown
*                       ssetr     +/- 2999.0 during periods of 24 hour sunup or
*                                 sundown
*                       ssha      invalid at the North and South Poles
*                       unprime   invalid at zenetr angles greater than 93.0
*                                 degrees
*                       zenetr    limited to 99.0 degrees at night
*
*        S_init       (optional initialization for all input parameters in
*                      the posdata struct)
*           INPUTS:     struct posdata*
*           OUTPUTS:    struct posdata*
*
*                     (Note: initializes the required S_solpos INPUTS above
*                      to out-of-bounds conditions, forcing the user to
*                      supply the parameters; initializes the OPTIONAL
*                      S_solpos inputs above to nominal values.)
*
*       S_decode      (optional utility for decoding the S_solpos return code)
*           INPUTS:     long integer S_solpos return value, struct posdata*
*           OUTPUTS:    text to stderr
*
*    Usage:
*         In calling program, just after other 'includes', insert:
*
*              #include "solpos00.h"
*
*         Function calls:
*              S_init(struct posdata*)  [optional]
*              .
*              .
*              [set time and location parameters before S_solpos call]
*              .
*              .
*              int retval = S_solpos(struct posdata*)
*              S_decode(int retval, struct posdata*) [optional]
*                  (Note: you should always look at the S_solpos return
*                   value, which contains error codes. S_decode is one option
*                   for examining these codes.  It can also serve as a
*                   template for building your own application-specific
*                   decoder.)
*
*    Martin Rymes
*    National Renewable Energy Laboratory
*    25 March 1998
*
*    27 April 1999 REVISION:  Corrected leap year in S_date.
*    13 January 2000 REVISION:  SMW converted to structure posdata parameter
*                               and subdivided into functions.
*    01 February 2001 REVISION: SMW corrected ecobli calculation 
*                               (changed sign). Error is small (max 0.015 deg
*                               in calculation of declination angle)
*----------------------------------------------------------------------------*/

# === Mojo imports and const definitions ===
from math import sin, cos, tan, asin, acos, atan2, exp, pow, abs
from sys import stderr

# Constants (simulating solpos00.h defines)
# Error bit positions
let S_YEAR_ERROR: Int = 1
let S_MONTH_ERROR: Int = 2
let S_DAY_ERROR: Int = 3
let S_DOY_ERROR: Int = 4
let S_HOUR_ERROR: Int = 5
let S_MINUTE_ERROR: Int = 6
let S_SECOND_ERROR: Int = 7
let S_TZONE_ERROR: Int = 8
let S_INTRVL_ERROR: Int = 9
let S_LAT_ERROR: Int = 10
let S_LON_ERROR: Int = 11
let S_TEMP_ERROR: Int = 12
let S_PRESS_ERROR: Int = 13
let S_TILT_ERROR: Int = 14
let S_ASPECT_ERROR: Int = 15
let S_SBWID_ERROR: Int = 16
let S_SBRAD_ERROR: Int = 17
let S_SBSKY_ERROR: Int = 18

# Function masks (bit flags)
let S_DOY:   Int = 1
let L_DOY:   Int = 1
let L_GEOM:  Int = 2
let L_ZENETR:Int = 4
let L_SSHA:  Int = 8
let L_SBCF:  Int = 16
let L_TST:   Int = 32
let L_SRSS:  Int = 64
let L_SOLAZM:Int = 128
let L_REFRAC:Int = 256
let L_AMASS: Int = 512
let L_PRIME: Int = 1024
let L_ETR:   Int = 2048
let L_TILT:  Int = 4096
let S_ALL:   Int = 8191  # combination of all L_ flags

# Trig masks for localtrig
let SD_MASK: Int = L_ZENETR | L_SSHA | L_SBCF | L_SOLAZM
let SL_MASK: Int = L_ZENETR | L_SSHA | L_SBCF | L_SOLAZM
let CL_MASK: Int = L_ZENETR | L_SSHA | L_SBCF | L_SOLAZM
let CD_MASK: Int = L_ZENETR | L_SSHA | L_SBCF
let CH_MASK: Int = L_ZENETR

# === Struct definitions ===

struct trigdata:  # used to pass calculated values locally
    var cd: Float64   # cosine of the declination
    var ch: Float64   # cosine of the hour angle
    var cl: Float64   # cosine of the latitude
    var sd: Float64   # sine of the declination
    var sl: Float64   # sine of the latitude

struct posdata:
    # Inputs
    var day: Int32 = -99
    var daynum: Int32 = -999
    var hour: Int32 = -99
    var minute: Int32 = -99
    var month: Int32 = -99
    var second: Int32 = -99
    var year: Int32 = -99
    var interval: Int32 = 0
    var aspect: Float64 = 180.0
    var latitude: Float64 = -99.0
    var longitude: Float64 = -999.0
    var press: Float64 = 1013.0
    var solcon: Float64 = 1367.0
    var temp: Float64 = 15.0
    var tilt: Float64 = 0.0
    var timezone: Float64 = -99.0
    var sbwid: Float64 = 7.6
    var sbrad: Float64 = 31.7
    var sbsky: Float64 = 0.04
    var function: Int32 = S_ALL  # bit mask

    # Outputs (set by S_solpos)
    var dayang: Float64 = 0.0
    var erv: Float64 = 0.0
    var utime: Float64 = 0.0
    var julday: Float64 = 0.0
    var ectime: Float64 = 0.0
    var mnlong: Float64 = 0.0
    var mnanom: Float64 = 0.0
    var eclong: Float64 = 0.0
    var ecobli: Float64 = 0.0
    var declin: Float64 = 0.0
    var rascen: Float64 = 0.0
    var gmst: Float64 = 0.0
    var lmst: Float64 = 0.0
    var hrang: Float64 = 0.0
    var zenetr: Float64 = 0.0
    var elevetr: Float64 = 0.0
    var ssha: Float64 = 0.0
    var sbcf: Float64 = 0.0
    var tst: Float64 = 0.0
    var tstfix: Float64 = 0.0
    var eqntim: Float64 = 0.0
    var sretr: Float64 = 0.0
    var ssetr: Float64 = 0.0
    var azim: Float64 = 0.0
    var elevref: Float64 = 0.0
    var zenref: Float64 = 0.0
    var coszen: Float64 = 0.0
    var amass: Float64 = 0.0
    var ampress: Float64 = 0.0
    var unprime: Float64 = 0.0
    var prime: Float64 = 0.0
    var etrn: Float64 = 0.0
    var etr: Float64 = 0.0
    var cosinc: Float64 = 0.0
    var etrtilt: Float64 = 0.0

# === Module‑level static variables ===

# cumulative number of days prior to beginning of month
var month_days: List[List[Int32]] = List(
    List(0, 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334),
    List(0, 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335)
)
var degrad: Float64 = 57.295779513  # converts from radians to degrees
var raddeg: Float64 = 0.0174532925  # converts from degrees to radians

# === Local function prototypes ===
def validate(pdat: posdata) -> Int:
    ...

def dom2doy(pdat: posdata):
    ...

def doy2dom(pdat: posdata):
    ...

def geometry(pdat: posdata):
    ...

def zen_no_ref(pdat: posdata, tdat: trigdata):
    ...

def ssha(pdat: posdata, tdat: trigdata):
    ...

def sbcf(pdat: posdata, tdat: trigdata):
    ...

def tst(pdat: posdata):
    ...

def srss(pdat: posdata):
    ...

def sazm(pdat: posdata, tdat: trigdata):
    ...

def refrac(pdat: posdata):
    ...

def amass(pdat: posdata):
    ...

def prime(pdat: posdata):
    ...

def etr(pdat: posdata):
    ...

def localtrig(pdat: posdata, tdat: trigdata):
    ...

def tilt(pdat: posdata):
    ...

# === Public functions ===

def S_solpos(pdat: posdata) -> Int:
    var retval: Int
    var trigdat: trigdata
    tdat = pointer_address(trigdat)
    # initialize the trig structure
    tdat.sd = -999.0   # flag to force calculation of trig data
    tdat.cd = 1.0
    tdat.ch = 1.0      # set the rest of these to something safe
    tdat.cl = 1.0
    tdat.sl = 1.0
    retval = validate(pdat)
    if retval != 0:
        return retval
    if pdat.function & L_DOY != 0:
        doy2dom(pdat)
    else:
        dom2doy(pdat)
    if pdat.function & L_GEOM != 0:
        geometry(pdat)
    if pdat.function & L_ZENETR != 0:
        zen_no_ref(pdat, tdat)
    if pdat.function & L_SSHA != 0:
        ssha(pdat, tdat)
    if pdat.function & L_SBCF != 0:
        sbcf(pdat, tdat)
    if pdat.function & L_TST != 0:
        tst(pdat)
    if pdat.function & L_SRSS != 0:
        srss(pdat)
    if pdat.function & L_SOLAZM != 0:
        sazm(pdat, tdat)
    if pdat.function & L_REFRAC != 0:
        refrac(pdat)
    if pdat.function & L_AMASS != 0:
        amass(pdat)
    if pdat.function & L_PRIME != 0:
        prime(pdat)
    if pdat.function & L_ETR != 0:
        etr(pdat)
    if pdat.function & L_TILT != 0:
        tilt(pdat)
    return 0

# (Need to adjust the pointer usage – in Mojo we pass trigdata by reference)
# I will rewrite S_solpos using reference instead of pointer.

# Let's rewrite S_solpos properly with references:

def S_solpos(pdat: posdata) -> Int:
    var retval: Int
    var trigdat: trigdata
    tdat := &trigdat
    tdat.sd = -999.0
    tdat.cd = 1.0
    tdat.ch = 1.0
    tdat.cl = 1.0
    tdat.sl = 1.0
    retval = validate(pdat)
    if retval != 0:
        return retval
    if pdat.function & L_DOY != 0:
        doy2dom(pdat)
    else:
        dom2doy(pdat)
    if pdat.function & L_GEOM != 0:
        geometry(pdat)
    if pdat.function & L_ZENETR != 0:
        zen_no_ref(pdat, tdat)
    if pdat.function & L_SSHA != 0:
        ssha(pdat, tdat)
    if pdat.function & L_SBCF != 0:
        sbcf(pdat, tdat)
    if pdat.function & L_TST != 0:
        tst(pdat)
    if pdat.function & L_SRSS != 0:
        srss(pdat)
    if pdat.function & L_SOLAZM != 0:
        sazm(pdat, tdat)
    if pdat.function & L_REFRAC != 0:
        refrac(pdat)
    if pdat.function & L_AMASS != 0:
        amass(pdat)
    if pdat.function & L_PRIME != 0:
        prime(pdat)
    if pdat.function & L_ETR != 0:
        etr(pdat)
    if pdat.function & L_TILT != 0:
        tilt(pdat)
    return 0

# (Note: In Mojo we can't take address of a var like that; we'll change all functions that take pointer to take reference. I'll adjust the prototypes accordingly.)

# I'll rewrite the whole file with proper Mojo references. Since the original C used pointers, we'll change to references (&). The logic is identical.

# Let's define all functions with & for posdata and trigdata where applicable.

def validate(pdat: &posdata) -> Int:
    var retval: Int = 0
    if pdat.function & L_GEOM != 0:
        if pdat.year < 1950 or pdat.year > 2050:
            retval |= (1 << S_YEAR_ERROR)
        if (pdat.function & S_DOY) == 0 and (pdat.month < 1 or pdat.month > 12):
            retval |= (1 << S_MONTH_ERROR)
        if (pdat.function & S_DOY) == 0 and (pdat.day < 1 or pdat.day > 31):
            retval |= (1 << S_DAY_ERROR)
        if (pdat.function & S_DOY) != 0 and (pdat.daynum < 1 or pdat.daynum > 366):
            retval |= (1 << S_DOY_ERROR)
        if pdat.hour < 0 or pdat.hour > 24:
            retval |= (1 << S_HOUR_ERROR)
        if pdat.minute < 0 or pdat.minute > 59:
            retval |= (1 << S_MINUTE_ERROR)
        if pdat.second < 0 or pdat.second > 59:
            retval |= (1 << S_SECOND_ERROR)
        if pdat.hour == 24 and pdat.minute > 0:
            retval |= ((1 << S_HOUR_ERROR) | (1 << S_MINUTE_ERROR))
        if pdat.hour == 24 and pdat.second > 0:
            retval |= ((1 << S_HOUR_ERROR) | (1 << S_SECOND_ERROR))
        if abs(pdat.timezone) > 12.0:
            retval |= (1 << S_TZONE_ERROR)
        if pdat.interval < 0 or pdat.interval > 28800:
            retval |= (1 << S_INTRVL_ERROR)
        if abs(pdat.longitude) > 180.0:
            retval |= (1 << S_LON_ERROR)
        if abs(pdat.latitude) > 90.0:
            retval |= (1 << S_LAT_ERROR)
    if (pdat.function & L_REFRAC) != 0 and abs(pdat.temp) > 100.0:
        retval |= (1 << S_TEMP_ERROR)
    if (pdat.function & L_REFRAC) != 0 and (pdat.press < 0.0 or pdat.press > 2000.0):
        retval |= (1 << S_PRESS_ERROR)
    if (pdat.function & L_TILT) != 0 and abs(pdat.tilt) > 180.0:
        retval |= (1 << S_TILT_ERROR)
    if (pdat.function & L_TILT) != 0 and abs(pdat.aspect) > 360.0:
        retval |= (1 << S_ASPECT_ERROR)
    if (pdat.function & L_SBCF) != 0 and (pdat.sbwid < 1.0 or pdat.sbwid > 100.0):
        retval |= (1 << S_SBWID_ERROR)
    if (pdat.function & L_SBCF) != 0 and (pdat.sbrad < 1.0 or pdat.sbrad > 100.0):
        retval |= (1 << S_SBRAD_ERROR)
    if (pdat.function & L_SBCF) != 0 and abs(pdat.sbsky) > 1.0:
        retval |= (1 << S_SBSKY_ERROR)
    return retval

def dom2doy(pdat: &posdata):
    pdat.daynum = pdat.day + month_days[0][pdat.month]
    if ((pdat.year % 4) == 0) and (((pdat.year % 100) != 0) or ((pdat.year % 400) == 0)) and (pdat.month > 2):
        pdat.daynum += 1

def doy2dom(pdat: &posdata):
    var imon: Int32
    var leap: Int32
    if ((pdat.year % 4) == 0) and (((pdat.year % 100) != 0) or ((pdat.year % 400) == 0)):
        leap = 1
    else:
        leap = 0
    imon = 12
    while pdat.daynum <= month_days[leap][imon]:
        imon -= 1
    pdat.month = imon
    pdat.day = pdat.daynum - month_days[leap][imon]

def geometry(pdat: &posdata):
    var bottom: Float64
    var c2: Float64
    var cd: Float64
    var d2: Float64
    var delta: Float64
    var s2: Float64
    var sd: Float64
    var top: Float64
    var leap: Int32
    pdat.dayang = 360.0 * (pdat.daynum - 1) / 365.0
    sd = sin(raddeg * pdat.dayang)
    cd = cos(raddeg * pdat.dayang)
    d2 = 2.0 * pdat.dayang
    c2 = cos(raddeg * d2)
    s2 = sin(raddeg * d2)
    pdat.erv = 1.000110 + 0.034221 * cd + 0.001280 * sd
    pdat.erv += 0.000719 * c2 + 0.000077 * s2
    pdat.utime = pdat.hour * 3600.0 + pdat.minute * 60.0 + pdat.second - pdat.interval / 2.0
    pdat.utime = pdat.utime / 3600.0 - pdat.timezone
    delta = pdat.year - 1949
    leap = int(delta / 4.0)
    pdat.julday = 32916.5 + delta * 365.0 + leap + pdat.daynum + pdat.utime / 24.0
    pdat.ectime = pdat.julday - 51545.0
    pdat.mnlong = 280.460 + 0.9856474 * pdat.ectime
    pdat.mnlong -= 360.0 * int(pdat.mnlong / 360.0)
    if pdat.mnlong < 0.0:
        pdat.mnlong += 360.0
    pdat.mnanom = 357.528 + 0.9856003 * pdat.ectime
    pdat.mnanom -= 360.0 * int(pdat.mnanom / 360.0)
    if pdat.mnanom < 0.0:
        pdat.mnanom += 360.0
    pdat.eclong = pdat.mnlong + 1.915 * sin(pdat.mnanom * raddeg) + 0.020 * sin(2.0 * pdat.mnanom * raddeg)
    pdat.eclong -= 360.0 * int(pdat.eclong / 360.0)
    if pdat.eclong < 0.0:
        pdat.eclong += 360.0
    pdat.ecobli = 23.439 - 4.0e-07 * pdat.ectime
    pdat.declin = degrad * asin(sin(pdat.ecobli * raddeg) * sin(pdat.eclong * raddeg))
    top = cos(raddeg * pdat.ecobli) * sin(raddeg * pdat.eclong)
    bottom = cos(raddeg * pdat.eclong)
    pdat.rascen = degrad * atan2(top, bottom)
    if pdat.rascen < 0.0:
        pdat.rascen += 360.0
    pdat.gmst = 6.697375 + 0.0657098242 * pdat.ectime + pdat.utime
    pdat.gmst -= 24.0 * int(pdat.gmst / 24.0)
    if pdat.gmst < 0.0:
        pdat.gmst += 24.0
    pdat.lmst = pdat.gmst * 15.0 + pdat.longitude
    pdat.lmst -= 360.0 * int(pdat.lmst / 360.0)
    if pdat.lmst < 0.0:
        pdat.lmst += 360.0
    pdat.hrang = pdat.lmst - pdat.rascen
    if pdat.hrang < -180.0:
        pdat.hrang += 360.0
    elif pdat.hrang > 180.0:
        pdat.hrang -= 360.0

def zen_no_ref(pdat: &posdata, tdat: &trigdata):
    var cz: Float64
    localtrig(pdat, tdat)
    cz = tdat.sd * tdat.sl + tdat.cd * tdat.cl * tdat.ch
    if abs(cz) > 1.0:
        if cz >= 0.0:
            cz = 1.0
        else:
            cz = -1.0
    pdat.zenetr = acos(cz) * degrad
    if pdat.zenetr > 99.0:
        pdat.zenetr = 99.0
    pdat.elevetr = 90.0 - pdat.zenetr

def ssha(pdat: &posdata, tdat: &trigdata):
    var cssha: Float64
    var cdcl: Float64
    localtrig(pdat, tdat)
    cdcl = tdat.cd * tdat.cl
    if abs(cdcl) >= 0.001:
        cssha = -tdat.sl * tdat.sd / cdcl
        if cssha < -1.0:
            pdat.ssha = 180.0
        elif cssha > 1.0:
            pdat.ssha = 0.0
        else:
            pdat.ssha = degrad * acos(cssha)
    elif (pdat.declin >= 0.0 and pdat.latitude > 0.0) or (pdat.declin < 0.0 and pdat.latitude < 0.0):
        pdat.ssha = 180.0
    else:
        pdat.ssha = 0.0

def sbcf(pdat: &posdata, tdat: &trigdata):
    var p: Float64
    var t1: Float64
    var t2: Float64
    localtrig(pdat, tdat)
    p = 0.6366198 * pdat.sbwid / pdat.sbrad * pow(tdat.cd, 3)
    t1 = tdat.sl * tdat.sd * pdat.ssha * raddeg
    t2 = tdat.cl * tdat.cd * sin(pdat.ssha * raddeg)
    pdat.sbcf = pdat.sbsky + 1.0 / (1.0 - p * (t1 + t2))

def tst(pdat: &posdata):
    pdat.tst = (180.0 + pdat.hrang) * 4.0
    pdat.tstfix = pdat.tst - pdat.hour * 60.0 - pdat.minute - pdat.second / 60.0 + pdat.interval / 120.0
    while pdat.tstfix > 720.0:
        pdat.tstfix -= 1440.0
    while pdat.tstfix < -720.0:
        pdat.tstfix += 1440.0
    pdat.eqntim = pdat.tstfix + 60.0 * pdat.timezone - 4.0 * pdat.longitude

def srss(pdat: &posdata):
    if pdat.ssha <= 1.0:
        pdat.sretr = 2999.0
        pdat.ssetr = -2999.0
    elif pdat.ssha >= 179.0:
        pdat.sretr = -2999.0
        pdat.ssetr = 2999.0
    else:
        pdat.sretr = 720.0 - 4.0 * pdat.ssha - pdat.tstfix
        pdat.ssetr = 720.0 + 4.0 * pdat.ssha - pdat.tstfix

def sazm(pdat: &posdata, tdat: &trigdata):
    var ca: Float64
    var ce: Float64
    var cecl: Float64
    var se: Float64
    localtrig(pdat, tdat)
    ce = cos(raddeg * pdat.elevetr)
    se = sin(raddeg * pdat.elevetr)
    pdat.azim = 180.0
    cecl = ce * tdat.cl
    if abs(cecl) >= 0.001:
        ca = (se * tdat.sl - tdat.sd) / cecl
        if ca > 1.0:
            ca = 1.0
        elif ca < -1.0:
            ca = -1.0
        pdat.azim = 180.0 - acos(ca) * degrad
        if pdat.hrang > 0:
            pdat.azim = 360.0 - pdat.azim

def refrac(pdat: &posdata):
    var prestemp: Float64
    var refcor: Float64
    var tanelev: Float64
    if pdat.elevetr > 85.0:
        refcor = 0.0
    else:
        tanelev = tan(raddeg * pdat.elevetr)
        if pdat.elevetr >= 5.0:
            refcor = 58.1 / tanelev - 0.07 / (pow(tanelev, 3)) + 0.000086 / (pow(tanelev, 5))
        elif pdat.elevetr >= -0.575:
            refcor = 1735.0 + pdat.elevetr * (-518.2 + pdat.elevetr * (103.4 + pdat.elevetr * (-12.79 + pdat.elevetr * 0.711)))
        else:
            refcor = -20.774 / tanelev
        prestemp = (pdat.press * 283.0) / (1013.0 * (273.0 + pdat.temp))
        refcor *= prestemp / 3600.0
    pdat.elevref = pdat.elevetr + refcor
    if pdat.elevref < -9.0:
        pdat.elevref = -9.0
    pdat.zenref = 90.0 - pdat.elevref
    pdat.coszen = cos(raddeg * pdat.zenref)

def amass(pdat: &posdata):
    if pdat.zenref > 93.0:
        pdat.amass = -1.0
        pdat.ampress = -1.0
    else:
        pdat.amass = 1.0 / (cos(raddeg * pdat.zenref) + 0.50572 * pow((96.07995 - pdat.zenref), -1.6364))
        pdat.ampress = pdat.amass * pdat.press / 1013.0

def prime(pdat: &posdata):
    pdat.unprime = 1.031 * exp(-1.4 / (0.9 + 9.4 / pdat.amass)) + 0.1
    pdat.prime = 1.0 / pdat.unprime

def etr(pdat: &posdata):
    if pdat.coszen > 0.0:
        pdat.etrn = pdat.solcon * pdat.erv
        pdat.etr = pdat.etrn * pdat.coszen
    else:
        pdat.etrn = 0.0
        pdat.etr = 0.0

def localtrig(pdat: &posdata, tdat: &trigdata):
    if tdat.sd < -900.0:  # sd was initialized -999 as flag
        tdat.sd = 1.0  # reflag as having completed calculations
        if (pdat.function | CD_MASK) != 0:
            tdat.cd = cos(raddeg * pdat.declin)
        if (pdat.function | CH_MASK) != 0:
            tdat.ch = cos(raddeg * pdat.hrang)
        if (pdat.function | CL_MASK) != 0:
            tdat.cl = cos(raddeg * pdat.latitude)
        if (pdat.function | SD_MASK) != 0:
            tdat.sd = sin(raddeg * pdat.declin)
        if (pdat.function | SL_MASK) != 0:
            tdat.sl = sin(raddeg * pdat.latitude)

def tilt(pdat: &posdata):
    var ca: Float64
    var cp: Float64
    var ct: Float64
    var sa: Float64
    var sp: Float64
    var st: Float64
    var sz: Float64
    ca = cos(raddeg * pdat.azim)
    cp = cos(raddeg * pdat.aspect)
    ct = cos(raddeg * pdat.tilt)
    sa = sin(raddeg * pdat.azim)
    sp = sin(raddeg * pdat.aspect)
    st = sin(raddeg * pdat.tilt)
    sz = sin(raddeg * pdat.zenref)
    pdat.cosinc = pdat.coszen * ct + sz * st * (ca * cp + sa * sp)
    if pdat.cosinc > 0.0:
        pdat.etrtilt = pdat.etrn * pdat.cosinc
    else:
        pdat.etrtilt = 0.0

def S_init(pdat: &posdata):
    pdat.day = -99
    pdat.daynum = -999
    pdat.hour = -99
    pdat.minute = -99
    pdat.month = -99
    pdat.second = -99
    pdat.year = -99
    pdat.interval = 0
    pdat.aspect = 180.0
    pdat.latitude = -99.0
    pdat.longitude = -999.0
    pdat.press = 1013.0
    pdat.solcon = 1367.0
    pdat.temp = 15.0
    pdat.tilt = 0.0
    pdat.timezone = -99.0
    pdat.sbwid = 7.6
    pdat.sbrad = 31.7
    pdat.sbsky = 0.04
    pdat.function = S_ALL

def S_decode(code: Int, pdat: &posdata):
    if code & (1 << S_YEAR_ERROR) != 0:
        print("S_decode ==> Please fix the year: ", pdat.year, " [1950-2050]", file=stderr)
    if code & (1 << S_MONTH_ERROR) != 0:
        print("S_decode ==> Please fix the month: ", pdat.month, file=stderr)
    if code & (1 << S_DAY_ERROR) != 0:
        print("S_decode ==> Please fix the day-of-month: ", pdat.day, file=stderr)
    if code & (1 << S_DOY_ERROR) != 0:
        print("S_decode ==> Please fix the day-of-year: ", pdat.daynum, file=stderr)
    if code & (1 << S_HOUR_ERROR) != 0:
        print("S_decode ==> Please fix the hour: ", pdat.hour, file=stderr)
    if code & (1 << S_MINUTE_ERROR) != 0:
        print("S_decode ==> Please fix the minute: ", pdat.minute, file=stderr)
    if code & (1 << S_SECOND_ERROR) != 0:
        print("S_decode ==> Please fix the second: ", pdat.second, file=stderr)
    if code & (1 << S_TZONE_ERROR) != 0:
        print("S_decode ==> Please fix the time zone: ", pdat.timezone, file=stderr)
    if code & (1 << S_INTRVL_ERROR) != 0:
        print("S_decode ==> Please fix the interval: ", pdat.interval, file=stderr)
    if code & (1 << S_LAT_ERROR) != 0:
        print("S_decode ==> Please fix the latitude: ", pdat.latitude, file=stderr)
    if code & (1 << S_LON_ERROR) != 0:
        print("S_decode ==> Please fix the longitude: ", pdat.longitude, file=stderr)
    if code & (1 << S_TEMP_ERROR) != 0:
        print("S_decode ==> Please fix the temperature: ", pdat.temp, file=stderr)
    if code & (1 << S_PRESS_ERROR) != 0:
        print("S_decode ==> Please fix the pressure: ", pdat.press, file=stderr)
    if code & (1 << S_TILT_ERROR) != 0:
        print("S_decode ==> Please fix the tilt: ", pdat.tilt, file=stderr)
    if code & (1 << S_ASPECT_ERROR) != 0:
        print("S_decode ==> Please fix the aspect: ", pdat.aspect, file=stderr)
    if code & (1 << S_SBWID_ERROR) != 0:
        print("S_decode ==> Please fix the shadowband width: ", pdat.sbwid, file=stderr)
    if code & (1 << S_SBRAD_ERROR) != 0:
        print("S_decode ==> Please fix the shadowband radius: ", pdat.sbrad, file=stderr)
    if code & (1 << S_SBSKY_ERROR) != 0:
        print("S_decode ==> Please fix the shadowband sky factor: ", pdat.sbsky, file=stderr)
