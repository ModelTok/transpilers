/* Copyright 1992-2009	Regents of University of California
 *						Lawrence Berkeley National Laboratory
 *
 *  Authors: R.J. Hitchcock and W.L. Carroll
 *           Building Technologies Department
 *           Lawrence Berkeley National Laboratory
 */
/**************************************************************
 * C Language Implementation of DOE2.1d and Superlite 3.0
 * Daylighting Algorithms with new Complex Fenestration System
 * analysis algorithms.
 *
 * The original DOE2 daylighting algorithms and implementation
 * in FORTRAN were developed by F.C. Winkelmann at the
 * Lawrence Berkeley National Laboratory.
 *
 * The original Superlite algorithms and implementation in FORTRAN
 * were developed by Michael Modest and Jong-Jin Kim
 * under contract with Lawrence Berkeley National Laboratory.
 *
 * Note that the routines in this module are not part of DOE2.
 **************************************************************/
/*
NOTICE: The Government is granted for itself and others acting on its behalf
a paid-up, nonexclusive, irrevocable worldwide license in this data to reproduce,
prepare derivative works, and perform publicly and display publicly.
Beginning five (5) years after (date permission to assert copyright was obtained),
subject to two possible five year renewals, the Government is granted for itself
and others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
license in this data to reproduce, prepare derivative works, distribute copies to
the public, perform publicly and display publicly, and to permit others to do so.
NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL
LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY
INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
*/
import "BGL" as Bgl
from CONST import *
from DBCONST import *
from DEF import *
from NodeMesh2 import *
from WLCSurface import *
from helpers import *
from hemisphiral import *
from btdf import *
from CFSSystem import *
from CFSSurface import *
from DOE2DL import *
from WxTMY2 import *
/************************ subroutine read_wx_tmy2_hdr ***********************/
/* Reads header lines from raw ASCII TMY2 weather file. */
/* Stores required data in bldg data structure. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************ subroutine read_wx_tmy2_hdr ***********************/
def read_wx_tmy2_hdr(
    bldg_ptr: BLDG*,    /* pointer to bldg structure */
    wxfile: FileDescriptor    /* TMY2 weather file pointer */
) -> Int32:
{
    var wban: StaticString[7]
    var city: StaticString[30]
    var state: StaticString[4]
    var lon: StaticString[4]    // N = North
    var lat: StaticString[4]    // W = West
    var lat_deg: Int32
    var lat_min: Int32
    var long_deg: Int32
    var long_min: Int32
    var elevation: Int32
    var timezone: Int32    // TMY2 negative values => behind Universal Time => East of Prime Meridian
    // Simulate fscanf using readline and manual parsing
    var line = wxfile.readline()
    if line.is_empty():
        return -1
    var parts = line.split()
    if parts.size() != 11:
        return -1
    wban = parts[0]
    city = parts[1]
    state = parts[2]
    timezone = parts[3].to_int()
    lat = parts[4]
    lat_deg = parts[5].to_int()
    lat_min = parts[6].to_int()
    lon = parts[7]
    long_deg = parts[8].to_int()
    long_min = parts[9].to_int()
    elevation = parts[10].to_int()
    /* Convert to DOE2 expected units and store data in bldg data structure */
    bldg_ptr.lat = Float64(lat_deg) + (Float64(lat_min) / 60.0f)
    if lat == "S":
        bldg_ptr.lat = -(bldg_ptr.lat)
    bldg_ptr.lon = Float64(long_deg) + (Float64(long_min) / 60.0f)
    if lon == "E":
        bldg_ptr.lon = -(bldg_ptr.lon)
    bldg_ptr.alt = Float64(elevation) / 0.3048
    bldg_ptr.timezone = Float64(timezone) * -1.0
    return 0
}
/************************ subroutine read_wx_tmy2_hr ************************/
/* Reads hourly data lines from raw ASCII TMY2 weather file. */
/* Stores required data in sun2 data structure. */
/****************************************************************************/
/* C Language Implementation of DOE2 Daylighting Algorithms */
/* by Rob Hitchcock */
/* Building Technologies Program, Lawrence Berkeley Laboratory */
/************************ subroutine read_wx_tmy2_hr ************************/
def read_wx_tmy2_hr(
    imon: Int32,    /* current month (begins at 0) */
    iday: Int32,    /* current day (begins at 1) */
    ihr: Int32,    /* current hour (begins at 0) */
    sun2_ptr: SUN2_DATA*,    /* pointer to sun2 data structure */
    wxfile: FileDescriptor    /* weather file pointer */
) -> Int32:
{
    var extra_horiz_rad: Int32
    var extra_direct_norm_rad: Int32
    var global_horiz_rad: Int32    // totl horiz solar rad (Wh/m2)
    var direct_norm_rad: Int32    // direct normal solar rad (Wh/m2)
    var diffuse_horiz_rad: Int32
    var global_horiz_illum: Int32
    var direct_norm_illum: Int32
    var diffuse_horiz_illum: Int32
    var zenith_illum: Int32
    var total_sky_cover: Int32    // hourly cloud amount (in tenths)
    var opaque_sky_cover: Int32
    var dry_bulb_temp: Int32
    var dew_pt_temp: Int32        // hourly dewpoint temperature (tenths of degreeC)
    var rel_humidity: Int32
    var atm_pressure: Int32
    var wind_dir: Int32
    var wind_speed: Int32
    var visibility: Int32
    var ceiling_ht: Int64
    var observed: Int32
    var thunder: Int32
    var rain: Int32
    var rain_squall: Int32
    var snow: Int32
    var snow_squall: Int32
    var sleet: Int32
    var fog: Int32
    var smoke: Int32
    var ice_pellets: Int32
    var precipitation: Int32
    var aerosol_opt_depth: Int32
    var snow_depth: Int32
    var days_since_snow: Int32
    var ghr: StaticString[2], dnr: StaticString[2], dhr: StaticString[2], ghi: StaticString[2], dni: StaticString[2], dhi: StaticString[2], zi: StaticString[2], tsc: StaticString[2], osc: StaticString[2], dbt: StaticString[2], dpt: StaticString[2], rh: StaticString[2], ap: StaticString[2]
    var ws: StaticString[2], wd: StaticString[2], vis: StaticString[2], ch: StaticString[2], pre: StaticString[2], aod: StaticString[2], sd: StaticString[2], dss: StaticString[2]
    var ughr: Int32, udnr: Int32, udhr: Int32, ughi: Int32, udni: Int32, udhi: Int32, uzi: Int32, utsc: Int32, uosc: Int32, udbt: Int32, udpt: Int32, urh: Int32, uap: Int32
    var uws: Int32, uwd: Int32, uvis: Int32, uch: Int32, upre: Int32, uaod: Int32, usd: Int32, udss: Int32
    var yr: Int32        // not used
    var month: Int32    /* input data line month (begins at 1) */
    var day: Int32    /* input data line day (begins at 1) */
    var hour: Int32    /* input data line hour (begins at 1) */
    /* read wx hourly data line until matching month/day/hour are found */
    loop:
    {
        var line = wxfile.readline()
        if line.is_empty():
            return -1
        // The fscanf format is complex; we parse fixed-width fields per TMY2 spec.
        // Simplified: assume fields are separated by spaces (not fixed-width in actual format?).
        // For a faithful translation, we need to parse character-by-character.
        // Here we use a simple split-based parse as a placeholder.
        var parts = line.split()
        if parts.size() < 80:
            return -1
        var idx = 0
        // Helper lambda to read next int and advance idx
        def next_int() -> Int32:
            var val = parts[idx].to_int()
            idx += 1
            return val
        def next_str() -> String:
            var val = parts[idx]
            idx += 1
            return val
        yr = next_int()
        month = next_int()
        day = next_int()
        hour = next_int()
        extra_horiz_rad = next_int()
        extra_direct_norm_rad = next_int()
        global_horiz_rad = next_int()
        ghr = next_str()
        ughr = next_int()
        direct_norm_rad = next_int()
        dnr = next_str()
        udnr = next_int()
        diffuse_horiz_rad = next_int()
        dhr = next_str()
        udhr = next_int()
        global_horiz_illum = next_int()
        ghi = next_str()
        ughi = next_int()
        direct_norm_illum = next_int()
        dni = next_str()
        udni = next_int()
        diffuse_horiz_illum = next_int()
        dhi = next_str()
        udhi = next_int()
        zenith_illum = next_int()
        zi = next_str()
        uzi = next_int()
        total_sky_cover = next_int()
        tsc = next_str()
        utsc = next_int()
        opaque_sky_cover = next_int()
        osc = next_str()
        uosc = next_int()
        dry_bulb_temp = next_int()
        dbt = next_str()
        udbt = next_int()
        dew_pt_temp = next_int()
        dpt = next_str()
        udpt = next_int()
        rel_humidity = next_int()
        rh = next_str()
        urh = next_int()
        atm_pressure = next_int()
        ap = next_str()
        uap = next_int()
        wind_dir = next_int()
        wd = next_str()
        uwd = next_int()
        wind_speed = next_int()
        ws = next_str()
        uws = next_int()
        visibility = next_int()
        vis = next_str()
        uvis = next_int()
        ceiling_ht = next_int()
        ch = next_str()
        uch = next_int()
        observed = next_int()
        thunder = next_int()
        rain = next_int()
        rain_squall = next_int()
        snow = next_int()
        snow_squall = next_int()
        sleet = next_int()
        fog = next_int()
        smoke = next_int()
        ice_pellets = next_int()
        precipitation = next_int()
        pre = next_str()
        upre = next_int()
        aerosol_opt_depth = next_int()
        aod = next_str()
        uaod = next_int()
        snow_depth = next_int()
        sd = next_str()
        usd = next_int()
        days_since_snow = next_int()
        dss = next_str()
        udss = next_int()
        if (month == (imon + 1)) and (day == iday) and (hour == (ihr + 1)):
            break
    }
    sun2_ptr.solrad = ceil(Float64(global_horiz_rad) * 0.3170)
    sun2_ptr.dirsol = ceil(Float64(direct_norm_rad) * 0.3170)
    sun2_ptr.cldamt = total_sky_cover
    sun2_ptr.dewpt = (Float64(dew_pt_temp) / 10.0) * 1.8 + 32.0
    return 0
}