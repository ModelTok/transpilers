from core import *
from lib_weatherfile import weatherfile, weather_header, weather_record
from lib_irradproc import *
from lib_pvwatts import *
from lib_pvshade import *
from lib_util import *

const DTOR = 3.14159265358979323846 / 180.0  # degrees to radians factor
const M_PI = 3.14159265358979323846

# Static global arrays and variables (from C++ static)
var nday: StaticArray[Int32, 12] = StaticArray[Int32, 12](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

# Functions (static in C++)

def transpoa(poa: Float64, dn: Float64, inc: Float64) -> Float64:
    """Calculates the irradiance transmitted thru a PV module cover."""
    var b0: Float64 = 1.0
    var b1: Float64 = -2.438e-3
    var b2: Float64 = 3.103e-4
    var b3: Float64 = -1.246e-5
    var b4: Float64 = 2.112e-7
    var b5: Float64 = -1.359e-9
    var x: Float64
    var inc_deg: Float64 = inc / DTOR  # convert radians to degrees
    if inc_deg > 50.0 and inc_deg < 90.0:
        x = b0 + b1*inc_deg + b2*inc_deg*inc_deg + b3*inc_deg*inc_deg*inc_deg + b4*inc_deg*inc_deg*inc_deg*inc_deg + b5*inc_deg*inc_deg*inc_deg*inc_deg*inc_deg
        poa = poa - (1.0 - x)*dn*cos(inc_deg*DTOR)
        if poa < 0.0:
            poa = 0.0
    return poa

# Global statics for celltemp
var celltemp_iflagc: Int32 = 0
var celltemp_suno: Float64 = 0.0
var celltemp_tmodo: Float64 = 293.15

def celltemp(inoct: Float64, height: Float64, poa: StaticArray[Float64, 24], ambt: StaticArray[Float64, 24], wind: StaticArray[Float64, 24], pvt: StaticArray[Float64, 24]):
    """Estimates the array temperature given the poa radiation, ambient temperature, and wind speed."""
    var i: Int32
    var j: Int32
    var absorb: Float64 = 0.83
    var backrt: Float64
    var boltz: Float64 = 5.669e-8
    var cap: Float64 = 0
    var capo: Float64 = 11000.0
    var conair: Float64
    var convrt: Float64 = 0
    var denair: Float64
    var dtime: Float64
    var eigen: Float64
    var emmis: Float64 = 0.84
    var grashf: Float64
    var hconv: Float64
    var hforce: Float64
    var hfree: Float64
    var hgrnd: Float64
    var reynld: Float64
    var sunn: Float64
    var suno: Float64
    var tamb: Float64
    var tave: Float64
    var tgrat: Float64 = 0
    var tgrnd: Float64
    var tmod: Float64
    var tmodo: Float64
    var tsky: Float64
    var visair: Float64
    var windmd: Float64
    var xlen: Float64 = 0.5
    var hsky: Float64
    var ex: Float64
    dtime = 12.0
    suno = celltemp_suno
    tmodo = celltemp_tmodo
    if celltemp_iflagc != 1:
        windmd = 1.0
        tave = (inoct + 293.15) / 2.0
        denair = 0.003484 * 101325.0 / tave
        visair = 0.24237e-6 * pow(tave, 0.76) / denair
        conair = 2.1695e-4 * pow(tave, 0.84)
        reynld = windmd * xlen / visair
        hforce = 0.8600 / pow(reynld, 0.5) * denair * windmd * 1007.0 / pow(0.71, 0.67)
        grashf = 9.8 / tave * (inoct - 293.15) * pow(xlen, 3.0) / pow(visair, 2.0) * 0.5
        hfree = 0.21 * pow(grashf * 0.71, 0.32) * conair / xlen
        hconv = pow(pow(hfree, 3.0) + pow(hforce, 3.0), 1.0/3.0)
        hgrnd = emmis * boltz * (pow(inoct, 2.0) + pow(293.15, 2.0)) * (inoct + 293.15)
        backrt = (absorb * 800.0 - emmis * boltz * (pow(inoct, 4.0) - pow(282.21, 4.0)) - hconv * (inoct - 293.15)) / ((hgrnd + hconv) * (inoct - 293.15))
        tgrnd = pow(pow(inoct, 4.0) - backrt * (pow(inoct, 4.0) - pow(293.15, 4.0)), 0.25)
        if tgrnd > inoct:
            tgrnd = inoct
        if tgrnd < 293.15:
            tgrnd = 293.15
        tgrat = (tgrnd - 293.15) / (inoct - 293.15)
        convrt = (absorb * 800.0 - emmis * boltz * (2.0 * pow(inoct, 4.0) - pow(282.21, 4.0) - pow(tgrnd, 4.0))) / (hconv * (inoct - 293.15))
        cap = capo
        if inoct > 321.15:
            cap = cap * (1.0 + (inoct - 321.15) / 12.0)
        celltemp_iflagc = 1
    for i in range(24):
        if poa[i] > 0.0:
            tamb = ambt[i] + 273.15
            sunn = poa[i] * absorb
            tsky = 0.68 * (0.0552 * pow(tamb, 1.5)) + 0.32 * tamb
            windmd = wind[i] * pow(height / 9.144, 0.2) + 0.0001
            tmod = tmodo
            for j in range(10):
                tave = (tmod + tamb) / 2.0
                denair = 0.003484 * 101325.0 / tave
                visair = 0.24237e-6 * pow(tave, 0.76) / denair
                conair = 2.1695e-4 * pow(tave, 0.84)
                reynld = windmd * xlen / visair
                hforce = 0.8600 / pow(reynld, 0.5) * denair * windmd * 1007.0 / pow(0.71, 0.67)
                if reynld > 1.2e5:
                    hforce = 0.0282 / pow(reynld, 0.2) * denair * windmd * 1007.0 / pow(0.71, 0.4)
                grashf = 9.8 / tave * (tmod - tamb).abs() * pow(xlen, 3.0) / pow(visair, 2.0) * 0.5
                hfree = 0.21 * pow(grashf * 0.71, 0.32) * conair / xlen
                hconv = convrt * pow(pow(hfree, 3.0) + pow(hforce, 3.0), 1.0/3.0)
                hsky = emmis * boltz * (pow(tmod, 2.0) + pow(tsky, 2.0)) * (tmod + tsky)
                tgrnd = tamb + tgrat * (tmod - tamb)
                hgrnd = emmis * boltz * (tmod * tmod + tgrnd * tgrnd) * (tmod + tgrnd)
                eigen = -(hconv + hsky + hgrnd) / cap * dtime * 3600.0
                ex = 0.0
                if eigen > -10.0:
                    ex = exp(eigen)
                tmod = tmodo * ex + ((1.0 - ex) * (hconv * tamb + hsky * tsky + hgrnd * tgrnd + suno + (sunn - suno) / eigen) + sunn - suno) / (hconv + hsky + hgrnd)
            tmodo = tmod
            suno = sunn
            dtime = 1.0
            pvt[i] = tmod - 273.15
        else:
            pvt[i] = 999.0
    celltemp_suno = suno
    celltemp_tmodo = tmodo

def dcpowr(reftem: Float64, refpwr: Float64, pwrdgr: Float64, tmloss: Float64, poa: StaticArray[Float64, 24], pvt: StaticArray[Float64, 24], dc: StaticArray[Float64, 24]):
    """Computes the dc power from the array."""
    var i: Int32
    var dcpwr1: Float64
    for i in range(24):
        if poa[i] > 125.0:
            dcpwr1 = refpwr * (1.0 + pwrdgr * (pvt[i] - reftem)) * poa[i] / 1000.0
        elif poa[i] > 0.1:
            dcpwr1 = refpwr * (1.0 + pwrdgr * (pvt[i] - reftem)) * 0.008 * poa[i] * poa[i] / 1000.0
        else:
            dcpwr1 = 0.0
        dc[i] = dcpwr1 * (1.0 - tmloss)

def dctoac(pcrate: Float64, efffp: Float64, dc: StaticArray[Float64, 24], ac: StaticArray[Float64, 24]):
    """Computes the ac energy from the inverter system."""
    var i: Int32
    var dcrtng: Float64
    var effrf: Float64
    var percfl: Float64
    var rateff: Float64
    rateff = efffp / 0.91
    dcrtng = pcrate / efffp
    for i in range(24):
        if dc[i] > 0.0:
            percfl = dc[i] / dcrtng
            if percfl <= 1.0:
                if percfl >= 0.1:
                    effrf = 0.774 + (0.663 * percfl) + (-0.952 * percfl * percfl) + (0.426 * percfl * percfl * percfl)
                    if effrf > 0.925:
                        effrf = 0.925
                else:
                    effrf = (8.46 * percfl) - 0.015
                    if effrf < 0.0:
                        effrf = 0.0
                effrf = effrf * rateff
                ac[i] = dc[i] * effrf
            else:
                ac[i] = pcrate
        else:
            ac[i] = 0.0

def julian(yr: Int32, month: Int32, day: Int32) -> Int32:
    """Calculates julian day of year."""
    var i: Int32 = 1
    var jday: Int32 = 0
    var k: Int32
    if yr % 4 == 0:
        k = 1
    else:
        k = 0
    while i < month:
        jday = jday + nday[i-1]
        i = i + 1
    if month > 2:
        jday = jday + k + day
    else:
        jday = jday + day
    return jday

def solarpos_v0(year: Int32, month: Int32, day: Int32, hour: Int32, minute: Float64, lat: Float64, lng: Float64, tz: Float64, sunn: StaticArray[Float64, 8]):
    """Solar position function based on Michalsky (1988)."""
    var jday: Int32
    var delta: Int32
    var leap: Int32
    var zulu: Float64
    var jd: Float64
    var time: Float64
    var mnlong: Float64
    var mnanom: Float64
    var eclong: Float64
    var oblqec: Float64
    var num: Float64
    var den: Float64
    var ra: Float64
    var dec: Float64
    var gmst: Float64
    var lmst: Float64
    var ha: Float64
    var elv: Float64
    var azm: Float64
    var refrac: Float64
    var E: Float64
    var ws: Float64
    var sunrise: Float64
    var sunset: Float64
    var Eo: Float64
    var tst: Float64
    var arg: Float64

    jday = julian(year, month, day)
    zulu = hour + minute / 60.0 - tz
    if zulu < 0.0:
        zulu = zulu + 24.0
        jday = jday - 1
    elif zulu > 24.0:
        zulu = zulu - 24.0
        jday = jday + 1
    delta = year - 1949
    leap = delta / 4
    jd = 32916.5 + delta * 365 + leap + jday + zulu / 24.0
    time = jd - 51545.0
    mnlong = 280.46 + 0.9856474 * time
    mnlong = mnlong.fmod(360.0)
    if mnlong < 0.0:
        mnlong = mnlong + 360.0
    mnanom = 357.528 + 0.9856003 * time
    mnanom = mnanom.fmod(360.0)
    if mnanom < 0.0:
        mnanom = mnanom + 360.0
    mnanom = mnanom * DTOR
    eclong = mnlong + 1.915 * sin(mnanom) + 0.020 * sin(2.0 * mnanom)
    eclong = eclong.fmod(360.0)
    if eclong < 0.0:
        eclong = eclong + 360.0
    eclong = eclong * DTOR
    oblqec = (23.439 - 0.0000004 * time) * DTOR
    num = cos(oblqec) * sin(eclong)
    den = cos(eclong)
    ra = atan(num / den)
    if den < 0.0:
        ra = ra + M_PI
    elif num < 0.0:
        ra = ra + 2.0 * M_PI
    dec = asin(sin(oblqec) * sin(eclong))
    gmst = 6.697375 + 0.0657098242 * time + zulu
    gmst = gmst.fmod(24.0)
    if gmst < 0.0:
        gmst = gmst + 24.0
    lmst = gmst + lng / 15.0
    lmst = lmst.fmod(24.0)
    if lmst < 0.0:
        lmst = lmst + 24.0
    lmst = lmst * 15.0 * DTOR
    ha = lmst - ra
    if ha < -M_PI:
        ha = ha + 2.0 * M_PI
    elif ha > M_PI:
        ha = ha - 2.0 * M_PI
    lat = lat * DTOR
    arg = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha)
    if arg > 1.0:
        elv = M_PI / 2.0
    elif arg < -1.0:
        elv = -M_PI / 2.0
    else:
        elv = asin(arg)
    if cos(elv) == 0.0:
        azm = M_PI
    else:
        arg = (sin(elv) * sin(lat) - sin(dec)) / (cos(elv) * cos(lat))
        if arg > 1.0:
            azm = 0.0
        elif arg < -1.0:
            azm = M_PI
        else:
            azm = acos(arg)
        if (ha <= 0.0 and ha >= -M_PI) or ha >= M_PI:
            azm = M_PI - azm
        else:
            azm = M_PI + azm
    elv = elv / DTOR
    if elv > -0.56:
        refrac = 3.51561 * (0.1594 + 0.0196 * elv + 0.00002 * elv * elv) / (1.0 + 0.505 * elv + 0.0845 * elv * elv)
    else:
        refrac = 0.56
    if elv + refrac > 90.0:
        elv = 90.0 * DTOR
    else:
        elv = (elv + refrac) * DTOR
    E = (mnlong - ra / DTOR) / 15.0
    if E < -0.33:
        E = E + 24.0
    elif E > 0.33:
        E = E - 24.0
    arg = -tan(lat) * tan(dec)
    if arg >= 1.0:
        ws = 0.0
    elif arg <= -1.0:
        ws = M_PI
    else:
        ws = acos(arg)
    sunrise = 12.0 - (ws / DTOR) / 15.0 - (lng / 15.0 - tz) - E
    sunset = 12.0 + (ws / DTOR) / 15.0 - (lng / 15.0 - tz) - E
    Eo = 1.00014 - 0.01671 * cos(mnanom) - 0.00014 * cos(2.0 * mnanom)
    Eo = 1.0 / (Eo * Eo)
    tst = hour + minute / 60.0 + (lng / 15.0 - tz) + E
    sunn[0] = azm
    sunn[1] = 0.5 * M_PI - elv
    sunn[2] = elv
    sunn[3] = dec
    sunn[4] = sunrise
    sunn[5] = sunset
    sunn[6] = Eo
    sunn[7] = tst

def incident2(mode: Int32, tilt: Float64, sazm: Float64, rlim: Float64, zen: Float64, azm: Float64, angle: StaticArray[Float64, 3]):
    """Calculates the incident angle of direct beam radiation to a surface."""
    var arg: Float64
    var inc: Float64 = 0
    var xsazm: Float64
    var xtilt: Float64
    var rot: Float64
    if mode == 0:
        tilt = tilt * DTOR
        sazm = sazm * DTOR
        arg = sin(zen) * cos(azm - sazm) * sin(tilt) + cos(zen) * cos(tilt)
        if arg < -1.0:
            inc = M_PI
        elif arg > 1.0:
            inc = 0.0
        else:
            inc = acos(arg)
    elif mode == 1:
        xtilt = tilt * DTOR
        xsazm = sazm * DTOR
        rlim = rlim * DTOR
        if cos(xtilt).abs() < 0.001745:
            if xsazm <= M_PI:
                if azm <= xsazm + M_PI:
                    rot = azm - xsazm
                else:
                    rot = azm - xsazm - 2.0 * M_PI
            else:
                if azm >= xsazm - M_PI:
                    rot = azm - xsazm
                else:
                    rot = azm - xsazm + 2.0 * M_PI
        else:
            arg = sin(zen) * sin(azm - xsazm) / (sin(zen) * cos(azm - xsazm) * sin(xtilt) + cos(zen) * cos(xtilt))
            if arg < -99999.9:
                rot = -M_PI / 2.0
            elif arg > 99999.9:
                rot = M_PI / 2.0
            else:
                rot = atan(arg)
            if xsazm <= M_PI:
                if azm > xsazm and azm <= xsazm + M_PI:
                    if rot < 0.0:
                        rot = M_PI + rot
                else:
                    if rot > 0.0:
                        rot = rot - M_PI
            else:
                if azm < xsazm and azm >= xsazm - M_PI:
                    if rot > 0.0:
                        rot = rot - M_PI
                else:
                    if rot < 0.0:
                        rot = M_PI + rot
        if rot < -rlim:
            rot = -rlim
        elif rot > rlim:
            rot = rlim
        arg = cos(xtilt) * cos(rot)
        if arg < -1.0:
            tilt = M_PI
        elif arg > 1.0:
            tilt = 0.0
        else:
            tilt = acos(arg)
        if tilt == 0.0:
            sazm = M_PI
        else:
            arg = sin(rot) / sin(tilt)
            if arg < -1.0:
                sazm = 1.5 * M_PI + xsazm
            elif arg > 1.0:
                sazm = 0.5 * M_PI + xsazm
            elif rot < -0.5 * M_PI:
                sazm = xsazm - M_PI - asin(arg)
            elif rot > 0.5 * M_PI:
                sazm = xsazm + M_PI - asin(arg)
            else:
                sazm = asin(arg) + xsazm
            if sazm > 2.0 * M_PI:
                sazm = sazm - 2.0 * M_PI
            elif sazm < 0.0:
                sazm = sazm + 2.0 * M_PI
        arg = sin(zen) * cos(azm - sazm) * sin(tilt) + cos(zen) * cos(tilt)
        if arg < -1.0:
            inc = M_PI
        elif arg > 1.0:
            inc = 0.0
        else:
            inc = acos(arg)
    elif mode == 2:
        tilt = zen
        sazm = azm
        inc = 0.0
    angle[0] = inc
    angle[1] = tilt
    angle[2] = sazm

def perez(dn: Float64, df: Float64, alb: Float64, inc: Float64, tilt: Float64, zen: Float64) -> Float64:
    """Perez function for calculating diffuse + direct + ground reflected radiation."""
    var F11R: StaticArray[Float64, 8] = StaticArray[Float64, 8](-0.0083117, 0.1299457, 0.3296958, 0.5682053, 0.8730280, 1.1326077, 1.0601591, 0.6777470)
    var F12R: StaticArray[Float64, 8] = StaticArray[Float64, 8](0.5877285, 0.6825954, 0.4868735, 0.1874525, -0.3920403, -1.2367284, -1.5999137, -0.3272588)
    var F13R: StaticArray[Float64, 8] = StaticArray[Float64, 8](-0.0620636, -0.1513752, -0.2210958, -0.2951290, -0.3616149, -0.4118494, -0.3589221, -0.2504286)
    var F21R: StaticArray[Float64, 8] = StaticArray[Float64, 8](-0.0596012, -0.0189325, 0.0554140, 0.1088631, 0.2255647, 0.2877813, 0.2642124, 0.1561313)
    var F22R: StaticArray[Float64, 8] = StaticArray[Float64, 8](0.0721249, 0.0659650, -0.0639588, -0.1519229, -0.4620442, -0.8230357, -1.1272340, -1.3765031)
    var F23R: StaticArray[Float64, 8] = StaticArray[Float64, 8](-0.0220216, -0.0288748, -0.0260542, -0.0139754, 0.0012448, 0.0558651, 0.1310694, 0.2506212)
    var EPSBINS: StaticArray[Float64, 7] = StaticArray[Float64, 7](1.065, 1.23, 1.5, 1.95, 2.8, 4.5, 6.2)
    var B2: Float64 = 0.000005534
    var EPS: Float64
    var T: Float64
    var D: Float64
    var DELTA: Float64
    var A: Float64
    var B: Float64
    var C: Float64
    var ZH: Float64
    var F1: Float64
    var F2: Float64
    var COSINC: Float64
    var poa: Float64
    var x: Float64
    var CZ: Float64
    var ZC: Float64
    var ZENITH: Float64
    var AIRMASS: Float64
    var i: Int32

    if dn < 0.0:
        dn = 0.0
    if zen < 0.0 or zen > 1.5271631:
        if df < 0.0:
            df = 0.0
        if cos(inc) > 0.0 and zen < 1.5707963:
            poa = df * (1.0 + cos(tilt)) / 2.0 + dn * cos(inc)
            return poa
        else:
            poa = df * (1.0 + cos(tilt)) / 2.0
            return poa
    else:
        CZ = cos(zen)
        ZH = CZ if CZ > 0.0871557 else 0.0871557
        D = df
        if D <= 0.0:
            if cos(inc) > 0.0:
                poa = 0.0 + dn * cos(inc)
                return poa
            else:
                poa = 0.0
                return poa
        else:
            ZENITH = zen / DTOR
            AIRMASS = 1.0 / (CZ + 0.15 * pow(93.9 - ZENITH, -1.253))
            DELTA = D * AIRMASS / 1367.0
            T = pow(ZENITH, 3.0)
            EPS = (dn + D) / D
            EPS = (EPS + T * B2) / (1.0 + T * B2)
            i = 0
            while i < 7 and EPS > EPSBINS[i]:
                i = i + 1
            x = F11R[i] + F12R[i] * DELTA + F13R[i] * zen
            F1 = 0.0 if 0.0 > x else x
            F2 = F21R[i] + F22R[i] * DELTA + F23R[i] * zen
            COSINC = cos(inc)
            if COSINC < 0.0:
                ZC = 0.0
            else:
                ZC = COSINC
            A = D * (1.0 + cos(tilt)) / 2.0
            B = ZC / ZH * D - A
            C = D * sin(tilt)
            poa = A + F1 * B + F2 * C + alb * (dn * CZ + D) * (1.0 - cos(tilt)) / 2.0 + dn * ZC
            return poa

# The var_info table
var _cm_vtab_pvwattsv0: StaticArray[var_info, 16] = [
    var_info(SSC_INPUT, SSC_STRING, "file_name", "local weather file path", "", "", "Weather", "*", "LOCAL_FILE", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "system_size", "Nameplate capacity", "kW", "", "PVWatts", "*", "", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "derate", "System derate value", "frac", "", "PVWatts", "*", "MIN=0,MAX=1", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "track_mode", "Tracking mode", "0/1/2/3", "Fixed,1Axis,2Axis,AziAxis", "PVWatts", "*", "MIN=0,MAX=3,INTEGER", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "azimuth", "Azimuth angle", "deg", "E=90,S=180,W=270", "PVWatts", "*", "MIN=0,MAX=360", ""),
    var_info(SSC_INPUT, SSC_NUMBER, "tilt", "Tilt angle", "deg", "H=0,V=90", "PVWatts", "naof:tilt_eq_lat", "MIN=0,MAX=90", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dn", "Beam irradiance", "W/m2", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "df", "Diffuse irradiance", "W/m2", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tamb", "Ambient temperature", "C", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tdew", "Dew point temperature", "C", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "wspd", "Wind speed", "m/s", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "poa", "Plane of array irradiance", "W/m2", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "tcell", "Module temperature", "C", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "dc", "DC array output", "Wdc", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "ac", "AC system output", "Wac", "", "PVWatts", "*", "LENGTH=8760", ""),
    var_info(SSC_OUTPUT, SSC_ARRAY, "sunup", "Sun up over horizon", "0/1", "", "PVWatts", "*", "LENGTH=8760", ""),
]

class cm_pvwattsv0(compute_module):
    def __init__(inout self):
        self.add_var_info(_cm_vtab_pvwattsv0)

    def exec(inout self):
        var file: String = self.as_string("file_name")
        var wfile: weatherfile = weatherfile(file)
        if not wfile.ok():
            raise exec_error("pvwattsv1", wfile.message())
        if wfile.has_message():
            self.log(wfile.message(), SSC_WARNING)
        var dcrate: Float64 = self.as_double("system_size")
        var derate: Float64 = self.as_double("derate")
        var mode: Int32 = self.as_integer("track_mode")
        var tilt: Float64 = self.as_double("tilt")
        var sazm: Float64 = self.as_double("azimuth")
        var tmp: Float64
        var tmp2: Float64
        var inoct: Float64
        var height: Float64
        var yr: Int32
        var mn: Int32
        var dy: Int32
        var i: Int32
        var m: Int32
        var n: Int32
        var sunup: StaticArray[Int32, 24] = StaticArray[Int32, 24](0)
        var beghr: Int32
        var endhr: Int32
        var jday: Int32
        var cur_hour: Int32
        var lat: Float64
        var lng: Float64
        var tz: Float64
        var minute: Float64
        var sunn: StaticArray[Float64, 8] = StaticArray[Float64, 8](0.0)
        var angle: StaticArray[Float64, 3] = StaticArray[Float64, 3](0.0)
        var sunrise: Float64
        var sunset: Float64
        var dn: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var df: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var alb: Float64
        var poa: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var ambt: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var wind: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var pvt: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var dc: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var ac: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var tpoa: StaticArray[Float64, 24] = StaticArray[Float64, 24](0.0)
        var reftem: Float64
        var refpwr: Float64
        var pwrdgr: Float64
        var tmloss: Float64
        var pcrate: Float64
        var efffp: Float64
        var rlim: Float64 = 45.0

        var p_dn: Pointer[ssc_number_t] = self.allocate("dn", 8760)
        var p_df: Pointer[ssc_number_t] = self.allocate("df", 8760)
        var p_tamb: Pointer[ssc_number_t] = self.allocate("tamb", 8760)
        var p_wspd: Pointer[ssc_number_t] = self.allocate("wspd", 8760)
        var p_dc: Pointer[ssc_number_t] = self.allocate("dc", 8760)
        var p_ac: Pointer[ssc_number_t] = self.allocate("ac", 8760)
        var p_tcell: Pointer[ssc_number_t] = self.allocate("tcell", 8760)
        var p_poa: Pointer[ssc_number_t] = self.allocate("poa", 8760)
        var p_sunup: Pointer[ssc_number_t] = self.allocate("sunup", 8760)

        inoct = 45.0 + 273.15
        height = 5.0
        reftem = 25.0
        pwrdgr = -0.005
        efffp = 0.92

        var hdr: weather_header
        wfile.header(addr hdr)
        lat = hdr.lat
        lng = hdr.lon
        tz = hdr.tz

        if dcrate < 0.49999 or dcrate > 99999.9:
            dcrate = 4.0
        if derate < 0.0 or derate > 1.0:
            derate = 0.77
        pcrate = dcrate * 1000.0
        refpwr = dcrate * 1000.0
        tmloss = 1.0 - derate / efffp
        if mode < 0 or mode > 2:
            mode = 0
        if tilt < -0.0001 or tilt > 90.0001:
            tilt = lat
        if sazm < -0.0001 or sazm > 360.0001:
            sazm = 180.0

        cur_hour = 0
        jday = 0
        yr = 0
        mn = 0
        dy = 0

        var wf: weather_record
        for m in range(12):
            for n in range(1, nday[m] + 1):
                jday = jday + 1
                for i in range(24):
                    wfile.read(addr wf)
                    yr = wf.year
                    mn = wf.month
                    dy = wf.day
                    dn[i] = wf.dn
                    df[i] = wf.df
                    ambt[i] = wf.tdry
                    wind[i] = wf.wspd
                    poa[i] = 0.0
                    tpoa[i] = 0.0
                    dc[i] = 0.0
                    ac[i] = 0.0
                    sunup[i] = 0

                if wf.snow <= 0 or wf.snow > 150:
                    alb = 0.2
                else:
                    alb = 0.6

                solarpos_v0(yr, mn, dy, 12, 0.0, lat, lng, tz, sunn)
                sunrise = sunn[4]
                sunset = sunn[5]
                beghr = Int32(sunrise) + 24
                endhr = Int32(sunset - 0.01) + 24
                if sunset - sunrise > 0.01:
                    for i in range(beghr, endhr + 1):
                        sunup[i % 24] = 1
                beghr = beghr % 24
                endhr = endhr % 24
                if sunrise < 0.0:
                    sunrise = sunrise + 24.0
                if sunset > 24.0:
                    sunset = sunset - 24.0

                for i in range(24):
                    if sunup[i]:
                        minute = 30.0
                        if beghr != endhr:
                            if i == beghr:
                                minute = 60.0 * (1.0 - 0.5 * (i + 1.0 - sunrise))
                            elif i == endhr:
                                minute = 60.0 * 0.5 * (sunset - i)
                            solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                        elif i == beghr and (sunset - sunrise).abs() > 0.01:
                            if sunset > sunrise:
                                minute = 60.0 * (sunrise + 0.25 * (sunset - sunrise) - i)
                                solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                                tmp = sunn[1]
                                minute = 60.0 * (sunrise + 0.5 * (sunset - sunrise) - i)
                                solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                                sunn[1] = tmp
                            else:
                                tmp = 0.0
                                tmp2 = 0.0
                                minute = 60.0 * (1.0 - 0.5 * (i + 1.0 - sunrise))
                                solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                                tmp = tmp + sunn[1]
                                if sunn[0] / DTOR < 180.0:
                                    sunn[0] = sunn[0] + 360.0 * DTOR
                                tmp2 = tmp2 + sunn[0]
                                minute = 60.0 * 0.5 * (sunset - i)
                                solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                                tmp = tmp + sunn[1]
                                tmp2 = tmp2 + sunn[0]
                                sunn[1] = tmp / 2.0
                                sunn[0] = tmp2 / 2.0
                                if sunn[0] / DTOR > 360.0:
                                    sunn[0] = sunn[0] - 360.0 * DTOR
                        else:
                            solarpos_v0(yr, mn, dy, i, minute, lat, lng, tz, sunn)
                        incident2(mode, tilt, sazm, rlim, sunn[1], sunn[0], angle)
                        poa[i] = perez(dn[i], df[i], alb, angle[0], angle[1], sunn[1])
                        tpoa[i] = transpoa(poa[i], dn[i], angle[0])

                celltemp(inoct, height, poa, ambt, wind, pvt)
                dcpowr(reftem, refpwr, pwrdgr, tmloss, tpoa, pvt, dc)
                dctoac(pcrate, efffp, dc, ac)

                for i in range(24):
                    if cur_hour < 8760:
                        p_dn[cur_hour] = dn[i]
                        p_df[cur_hour] = df[i]
                        p_tamb[cur_hour] = ambt[i]
                        p_wspd[cur_hour] = wind[i]
                        p_dc[cur_hour] = dc[i]
                        p_ac[cur_hour] = ac[i]
                        p_tcell[cur_hour] = pvt[i]
                        p_poa[cur_hour] = poa[i]
                        p_sunup[cur_hour] = sunup[i]
                        cur_hour = cur_hour + 1

# DEFINE_MODULE_ENTRY( pvwattsv0, "PVWatts V.0 - TMY2 pvwatts version v1, consistent with online tool.", 0 )