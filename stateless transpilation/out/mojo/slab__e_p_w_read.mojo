from math import (
    exp, log, fmod, floor, ceil
)

# EXTERNAL DEPS (to wire in glue):
# - EPWPrecisionGlobals: provides r64 (double precision float alias)

alias r64 = Float64

alias A_FORMAT = "(A)"
alias BLANK_STRING = " "
alias MAX_NAME_LENGTH = 60
alias SIGMA = 5.6697e-8
alias T_KELVIN = 273.15
alias PI = 3.141592653589793

alias VALID_DIGITS = "0123456789"
alias END_OF_RECORD = -2
alias END_OF_FILE = -1
alias DEFAULT_INPUT_UNIT = 5
alias DEFAULT_OUTPUT_UNIT = 6
alias NUMBER_OF_PRECONNECTED_UNITS = 2
alias MAX_UNIT_NUMBER = 1000


struct WeatherDataDetails:
    var year: Int32
    var month: Int32
    var day: Int32
    var day_of_year: Int32
    var interval_minute: DynamicVector[Int32]
    var data_source_flags: DynamicVector[DynamicVector[String]]
    var dry_bulb: DynamicVector[DynamicVector[Float64]]
    var dew_point: DynamicVector[DynamicVector[Float64]]
    var rel_hum: DynamicVector[DynamicVector[Float64]]
    var stn_pres: DynamicVector[DynamicVector[Float64]]
    var x_horz_rad: DynamicVector[DynamicVector[Float64]]
    var x_dir_norm_rad: DynamicVector[DynamicVector[Float64]]
    var horz_ir_sky: DynamicVector[DynamicVector[Float64]]
    var glob_horz_rad: DynamicVector[DynamicVector[Float64]]
    var dir_norm_rad: DynamicVector[DynamicVector[Float64]]
    var dif_horz_rad: DynamicVector[DynamicVector[Float64]]
    var glob_horz_illum: DynamicVector[DynamicVector[Float64]]
    var dir_norm_illum: DynamicVector[DynamicVector[Float64]]
    var dif_horz_illum: DynamicVector[DynamicVector[Float64]]
    var zen_lum: DynamicVector[DynamicVector[Float64]]
    var wind_dir: DynamicVector[DynamicVector[Int32]]
    var wind_spd: DynamicVector[DynamicVector[Float64]]
    var tot_sky_cvr: DynamicVector[DynamicVector[Int32]]
    var opaq_sky_cvr: DynamicVector[DynamicVector[Int32]]
    var visibility: DynamicVector[DynamicVector[Float64]]
    var ceiling: DynamicVector[DynamicVector[Int32]]
    var pres_wth_obs: DynamicVector[DynamicVector[Int32]]
    var pres_wth_codes: DynamicVector[DynamicVector[String]]
    var precip_water: DynamicVector[DynamicVector[Int32]]
    var aer_opt_depth: DynamicVector[DynamicVector[Float64]]
    var snow_depth: DynamicVector[DynamicVector[Int32]]
    var days_last_snow: DynamicVector[DynamicVector[Int32]]
    var albedo: DynamicVector[DynamicVector[Float64]]
    var liquid_precip_depth: DynamicVector[DynamicVector[Float64]]
    var liquid_precip_rate: DynamicVector[DynamicVector[Float64]]
    var snow_ind: DynamicVector[DynamicVector[Int32]]
    var hum_rat: DynamicVector[DynamicVector[Float64]]
    var wet_bulb: DynamicVector[DynamicVector[Float64]]
    var delta_db_range: Bool
    var delta_chg_db: DynamicVector[DynamicVector[Float64]]
    var delta_dp_range: Bool
    var delta_chg_dp: DynamicVector[DynamicVector[Float64]]

    fn __init__(inout self):
        self.year = 0
        self.month = 0
        self.day = 0
        self.day_of_year = 0
        self.interval_minute = DynamicVector[Int32](capacity=60)
        for _ in range(60):
            self.interval_minute.push_back(0)
        self.data_source_flags = DynamicVector[DynamicVector[String]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[String](capacity=60)
            for _ in range(60):
                row.push_back(" " * 50)
            self.data_source_flags.push_back(row)
        self.dry_bulb = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dry_bulb.push_back(row)
        self.dew_point = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dew_point.push_back(row)
        self.rel_hum = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.rel_hum.push_back(row)
        self.stn_pres = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.stn_pres.push_back(row)
        self.x_horz_rad = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.x_horz_rad.push_back(row)
        self.x_dir_norm_rad = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.x_dir_norm_rad.push_back(row)
        self.horz_ir_sky = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.horz_ir_sky.push_back(row)
        self.glob_horz_rad = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.glob_horz_rad.push_back(row)
        self.dir_norm_rad = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dir_norm_rad.push_back(row)
        self.dif_horz_rad = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dif_horz_rad.push_back(row)
        self.glob_horz_illum = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.glob_horz_illum.push_back(row)
        self.dir_norm_illum = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dir_norm_illum.push_back(row)
        self.dif_horz_illum = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.dif_horz_illum.push_back(row)
        self.zen_lum = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.zen_lum.push_back(row)
        self.wind_dir = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.wind_dir.push_back(row)
        self.wind_spd = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.wind_spd.push_back(row)
        self.tot_sky_cvr = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.tot_sky_cvr.push_back(row)
        self.opaq_sky_cvr = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.opaq_sky_cvr.push_back(row)
        self.visibility = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.visibility.push_back(row)
        self.ceiling = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.ceiling.push_back(row)
        self.pres_wth_obs = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.pres_wth_obs.push_back(row)
        self.pres_wth_codes = DynamicVector[DynamicVector[String]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[String](capacity=60)
            for _ in range(60):
                row.push_back(" " * 9)
            self.pres_wth_codes.push_back(row)
        self.precip_water = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.precip_water.push_back(row)
        self.aer_opt_depth = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.aer_opt_depth.push_back(row)
        self.snow_depth = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.snow_depth.push_back(row)
        self.days_last_snow = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.days_last_snow.push_back(row)
        self.albedo = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.albedo.push_back(row)
        self.liquid_precip_depth = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.liquid_precip_depth.push_back(row)
        self.liquid_precip_rate = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.liquid_precip_rate.push_back(row)
        self.snow_ind = DynamicVector[DynamicVector[Int32]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Int32](capacity=60)
            for _ in range(60):
                row.push_back(0)
            self.snow_ind.push_back(row)
        self.hum_rat = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.hum_rat.push_back(row)
        self.wet_bulb = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.wet_bulb.push_back(row)
        self.delta_db_range = False
        self.delta_chg_db = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.delta_chg_db.push_back(row)
        self.delta_dp_range = False
        self.delta_chg_dp = DynamicVector[DynamicVector[Float64]](capacity=24)
        for _ in range(24):
            var row = DynamicVector[Float64](capacity=60)
            for _ in range(60):
                row.push_back(0.0)
            self.delta_chg_dp.push_back(row)


struct MissingData:
    var dry_bulb: Float64
    var dew_point: Float64
    var rel_humid: Int32
    var stn_pres: Float64
    var wind_dir: Int32
    var wind_spd: Float64
    var tot_sky_cvr: Int32
    var opaq_sky_cvr: Int32
    var visibility: Float64
    var ceiling: Int32
    var precip_water: Int32
    var aer_opt_depth: Float64
    var snow_depth: Int32
    var days_last_snow: Int32
    var albedo: Float64
    var liquid_precip: Float64

    fn __init__(inout self):
        self.dry_bulb = 0.0
        self.dew_point = 0.0
        self.rel_humid = 0
        self.stn_pres = 0.0
        self.wind_dir = 0
        self.wind_spd = 0.0
        self.tot_sky_cvr = 0
        self.opaq_sky_cvr = 0
        self.visibility = 0.0
        self.ceiling = 0
        self.precip_water = 0
        self.aer_opt_depth = 0.0
        self.snow_depth = 0
        self.days_last_snow = 0
        self.albedo = 0.0
        self.liquid_precip = 0.0


struct MissingDataCounts:
    var x_horz_rad: Int32
    var x_dir_norm_rad: Int32
    var glo_hor_rad: Int32
    var dir_norm_rad: Int32
    var dif_horz_rad: Int32
    var dry_bulb: Int32
    var dew_point: Int32
    var rel_humid: Int32
    var stn_pres: Int32
    var wind_dir: Int32
    var wind_spd: Int32
    var tot_sky_cvr: Int32
    var opaq_sky_cvr: Int32
    var visibility: Int32
    var ceiling: Int32
    var precip_water: Int32
    var aer_opt_depth: Int32
    var snow_depth: Int32
    var days_last_snow: Int32
    var albedo: Int32
    var liquid_precip: Int32

    fn __init__(inout self):
        self.x_horz_rad = 0
        self.x_dir_norm_rad = 0
        self.glo_hor_rad = 0
        self.dir_norm_rad = 0
        self.dif_horz_rad = 0
        self.dry_bulb = 0
        self.dew_point = 0
        self.rel_humid = 0
        self.stn_pres = 0
        self.wind_dir = 0
        self.wind_spd = 0
        self.tot_sky_cvr = 0
        self.opaq_sky_cvr = 0
        self.visibility = 0
        self.ceiling = 0
        self.precip_water = 0
        self.aer_opt_depth = 0
        self.snow_depth = 0
        self.days_last_snow = 0
        self.albedo = 0
        self.liquid_precip = 0


var w_day: DynamicVector[WeatherDataDetails] = DynamicVector[WeatherDataDetails](capacity=366)
var missing: MissingData = MissingData()
var missed: MissingDataCounts = MissingDataCounts()
var location_name: String = " " * (MAX_NAME_LENGTH * 2)
var num_data_periods: Int32 = 0
var latitude: Float64 = 0.0
var longitude: Float64 = 0.0
var time_zone: Float64 = 0.0
var elevation: Float64 = 0.0
var std_baro_press: Float64 = 0.0
var stn_wmo: String = " " * 10
var num_intervals_per_hour: Int32 = 0
var num_days: Int32 = 0

fn find_non_space(string: String) -> Int32:
    var i_len = len(string.strip())
    for i in range(i_len):
        if string[i] != ' ':
            return Int32(i + 1)
    return 0


fn process_number(string: String) -> Tuple[Float64, Bool]:
    var valid_numerics = "0123456789.+-EeDd\t"
    var pstring = string.strip()
    var string_len = len(pstring)
    var error_flag = False
    
    if string_len == 0:
        return (0.0, False)
    
    for i in range(string_len):
        if valid_numerics.find(pstring[i]) == -1:
            return (0.0, True)
    
    try:
        var temp = atof(pstring)
        return (temp, False)
    except:
        return (0.0, True)


fn psat(t: Float64) -> Float64:
    var dummy = t + 273.15
    var psat_val: Float64
    if t < 0.0:
        psat_val = exp(
            -5.6745359e3 / dummy
            - 5.1523058e-1
            - 9.6778430e-3 * dummy
            + 6.2215701e-7 * dummy * dummy
            + 2.0747825e-9 * dummy * dummy * dummy
            - 9.4840240e-13 * dummy * dummy * dummy * dummy
            + 4.1635019 * log(dummy)
        )
    else:
        psat_val = exp(
            -5.8002206e3 / dummy
            - 5.5162560
            - 4.8640239e-2 * dummy
            + 4.1764768e-5 * dummy * dummy
            - 1.4452093e-8 * dummy * dummy * dummy
            + 6.5459673 * log(dummy)
        )
    return psat_val * 1000.0


fn y3(x: Float64, a0: Float64, a1: Float64, a2: Float64, a3: Float64) -> Float64:
    return a0 + x * (a1 + x * (a2 + x * a3))


fn y5(
    x: Float64, a0: Float64, a1: Float64, a2: Float64, a3: Float64, a4: Float64, a5: Float64
) -> Float64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))


fn y6(
    x: Float64,
    a0: Float64,
    a1: Float64,
    a2: Float64,
    a3: Float64,
    a4: Float64,
    a5: Float64,
    a6: Float64,
) -> Float64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))


fn y7(
    x: Float64,
    a0: Float64,
    a1: Float64,
    a2: Float64,
    a3: Float64,
    a4: Float64,
    a5: Float64,
    a6: Float64,
    a7: Float64,
) -> Float64:
    return a0 + x * (
        a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7)))))
    )


fn y4(
    x: Float64, a0: Float64, a1: Float64, a2: Float64, a3: Float64, a4: Float64
) -> Float64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))


fn satutp(p: Float64) -> Float64:
    var pp = p
    var t: Float64 = 0.0

    if p > 2.3366e3:
        if p < 4.2415e3:
            t = y5(pp, -67.8912, 9.21677, -1.90385, 2.35588e-1, -1.48075e-2, 3.64517e-4)
        elif p < 7.375e3:
            t = y7(pp, -5.35428e1, 1.59311, -5.70202e-2, 1.44012e-3, -2.30578e-5, 2.22628e-7, -1.17867e-9, 2.62131e-12)
        elif p < 1.992e4:
            t = y6(pp, -3.59131e1, 2.31311e-1, -1.00453e-3, 2.99919e-6, -5.38184e-9, 5.22567e-12, -2.10354e-15)
        elif p < 1.0133e5:
            t = y5(pp, 8.65676, 6.86019e-3, -5.07998e-7, 2.57958e-11, -7.28305e-16, 8.62156e-21)
        else:
            t = y5(pp, 5.69919e1, 6.37817e-4, -2.85187e-9, 8.77453e-15, -1.48739e-20, 1.04699e-26)
    elif p > 1.227e3:
        t = y3(pp, -11.7426, 2.4662e-2, -6.66598e-6, 8.24255e-10)
    elif p > 6.108e2:
        t = y3(pp, -19.7816, 4.46963e-2, -2.36037e-5, 5.67281e-9)
    elif p > 1.0325e2:
        t = y3(pp, -3.78423, 1.42713e-2, -2.07467e-6, 1.38642e-10)
    elif p > 12.842:
        t = y3(pp, 4.09671, 8.61614e-3, -7.04051e-7, 2.65621e-11)
    else:
        t = y5(pp, -67.8912, 9.21677, -1.90385, 2.35588e-1, -1.48075e-2, 3.64517e-4)
    
    return t


fn dry_sat_pt(tdb: Float64) -> Float64:
    var tt = tdb
    var psat_val: Float64 = 0.0
    
    if tdb > 20:
        if tdb < 30.0:
            psat_val = y3(tt, 4.05663e2, 76.8637, -4.47857e-1, 7.15905e-2)
        elif tdb < 40.0:
            psat_val = y3(tt, -3.58332e2, 1.52167e2, -2.93294, 9.90514e-2)
        elif tdb < 80.0:
            psat_val = y5(tt, 7.30208e2, 32.987, 1.84658, 1.95497e-2, 3.33617e-4, 2.59343e-6)
        else:
            psat_val = y5(tt, 6.91607e2, 10.703, 3.01092, -2.57247e-3, 5.19714e-4, 2.00552e-6)
    elif tdb > 10.0:
        psat_val = y3(tt, 5.9088e2, 49.8847, 8.74643e-1, 4.97621e-2)
    elif tdb > 0.0:
        psat_val = y3(tt, 6.10775e2, 44.4502, 1.38578, 3.3106e-2)
    elif tdb > -20.0:
        psat_val = y4(tt, 6.10860e2, 50.1255, 1.83622, 3.67769e-2, 3.41421e-4)
    elif tdb > -40.0:
        psat_val = y4(tt, 5.69275e2, 42.5035, 1.29301, 1.88391e-2, 1.0961e-4)
    else:
        psat_val = y5(tt, 4.9752e2, 35.3452, 1.04398, 1.5962e-2, 1.2578e-4, 4.0683e-7)
    
    return psat_val


fn get_stm(longitude: Float64) -> Float64:
    var longl = DynamicVector[Float64](capacity=25)
    var longh = DynamicVector[Float64](capacity=25)
    
    for i in range(25):
        longl.push_back(0.0)
        longh.push_back(0.0)
    
    longl[12] = -7.5
    longh[12] = 7.5
    
    for i in range(1, 13):
        longl[12 + i] = longl[12 + i - 1] + 15.0
        longh[12 + i] = longh[12 + i - 1] + 15.0
    
    for i in range(1, 13):
        longl[12 - i] = longl[12 - i + 1] - 15.0
        longh[12 - i] = longh[12 - i + 1] - 15.0
    
    var temp = longitude
    temp = fmod(temp, 360.0)
    if temp > 180.0:
        temp = temp - 180.0
    
    for i in range(-12, 13):
        if temp > longl[12 + i] and temp <= longh[12 + i]:
            var tz = Float64(i)
            tz = fmod(tz, 24.0)
            return tz
    
    return -999.0


fn get_loc_data() -> Tuple[Float64, Float64, Float64]:
    return (latitude, longitude, elevation)
