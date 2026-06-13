from memory import DTypePointer
from math import log, exp
from collections import InlineArray

alias MAX_NAME_LENGTH = 60
alias BLANK_STRING = " "
alias SIGMA = 5.6697e-8
alias T_KELVIN = 273.15
alias PI = 3.141592653589793

struct WeatherDataDetails:
    var year: Int32
    var month: Int32
    var day: Int32
    var day_of_year: Int32
    var interval_minute: InlineArray[Int32, 60]
    var data_source_flags: InlineArray[InlineArray[StringLiteral, 60], 24]
    var dry_bulb: InlineArray[InlineArray[Float32, 60], 24]
    var dew_point: InlineArray[InlineArray[Float32, 60], 24]
    var rel_hum: InlineArray[InlineArray[Float32, 60], 24]
    var stn_pres: InlineArray[InlineArray[Float32, 60], 24]
    var x_horz_rad: InlineArray[InlineArray[Float32, 60], 24]
    var x_dir_norm_rad: InlineArray[InlineArray[Float32, 60], 24]
    var horz_ir_sky: InlineArray[InlineArray[Float32, 60], 24]
    var glob_horz_rad: InlineArray[InlineArray[Float32, 60], 24]
    var dir_norm_rad: InlineArray[InlineArray[Float32, 60], 24]
    var dif_horz_rad: InlineArray[InlineArray[Float32, 60], 24]
    var glob_horz_illum: InlineArray[InlineArray[Float32, 60], 24]
    var dir_norm_illum: InlineArray[InlineArray[Float32, 60], 24]
    var dif_horz_illum: InlineArray[InlineArray[Float32, 60], 24]
    var zen_lum: InlineArray[InlineArray[Float32, 60], 24]
    var wind_dir: InlineArray[InlineArray[Int32, 60], 24]
    var wind_spd: InlineArray[InlineArray[Float32, 60], 24]
    var tot_sky_cvr: InlineArray[InlineArray[Int32, 60], 24]
    var opaq_sky_cvr: InlineArray[InlineArray[Int32, 60], 24]
    var visibility: InlineArray[InlineArray[Float32, 60], 24]
    var ceiling: InlineArray[InlineArray[Int32, 60], 24]
    var pres_wth_obs: InlineArray[InlineArray[Int32, 60], 24]
    var pres_wth_codes: InlineArray[InlineArray[StringLiteral, 60], 24]
    var precip_water: InlineArray[InlineArray[Int32, 60], 24]
    var aer_opt_depth: InlineArray[InlineArray[Float32, 60], 24]
    var snow_depth: InlineArray[InlineArray[Int32, 60], 24]
    var days_last_snow: InlineArray[InlineArray[Int32, 60], 24]
    var delta_db_range: Bool
    var delta_chg_db: InlineArray[InlineArray[Float32, 60], 24]
    var delta_dp_range: Bool
    var delta_chg_dp: InlineArray[InlineArray[Float32, 60], 24]
    
    fn __init__(inout self):
        self.year = 0
        self.month = 0
        self.day = 0
        self.day_of_year = 0
        self.interval_minute = InlineArray[Int32, 60](fill=0)
        self.data_source_flags = InlineArray[InlineArray[StringLiteral, 60], 24]()
        self.dry_bulb = InlineArray[InlineArray[Float32, 60], 24]()
        self.dew_point = InlineArray[InlineArray[Float32, 60], 24]()
        self.rel_hum = InlineArray[InlineArray[Float32, 60], 24]()
        self.stn_pres = InlineArray[InlineArray[Float32, 60], 24]()
        self.x_horz_rad = InlineArray[InlineArray[Float32, 60], 24]()
        self.x_dir_norm_rad = InlineArray[InlineArray[Float32, 60], 24]()
        self.horz_ir_sky = InlineArray[InlineArray[Float32, 60], 24]()
        self.glob_horz_rad = InlineArray[InlineArray[Float32, 60], 24]()
        self.dir_norm_rad = InlineArray[InlineArray[Float32, 60], 24]()
        self.dif_horz_rad = InlineArray[InlineArray[Float32, 60], 24]()
        self.glob_horz_illum = InlineArray[InlineArray[Float32, 60], 24]()
        self.dir_norm_illum = InlineArray[InlineArray[Float32, 60], 24]()
        self.dif_horz_illum = InlineArray[InlineArray[Float32, 60], 24]()
        self.zen_lum = InlineArray[InlineArray[Float32, 60], 24]()
        self.wind_dir = InlineArray[InlineArray[Int32, 60], 24]()
        self.wind_spd = InlineArray[InlineArray[Float32, 60], 24]()
        self.tot_sky_cvr = InlineArray[InlineArray[Int32, 60], 24]()
        self.opaq_sky_cvr = InlineArray[InlineArray[Int32, 60], 24]()
        self.visibility = InlineArray[InlineArray[Float32, 60], 24]()
        self.ceiling = InlineArray[InlineArray[Int32, 60], 24]()
        self.pres_wth_obs = InlineArray[InlineArray[Int32, 60], 24]()
        self.pres_wth_codes = InlineArray[InlineArray[StringLiteral, 60], 24]()
        self.precip_water = InlineArray[InlineArray[Int32, 60], 24]()
        self.aer_opt_depth = InlineArray[InlineArray[Float32, 60], 24]()
        self.snow_depth = InlineArray[InlineArray[Int32, 60], 24]()
        self.days_last_snow = InlineArray[InlineArray[Int32, 60], 24]()
        self.delta_db_range = False
        self.delta_chg_db = InlineArray[InlineArray[Float32, 60], 24]()
        self.delta_dp_range = False
        self.delta_chg_dp = InlineArray[InlineArray[Float32, 60], 24]()

struct MissingData:
    var dry_bulb: Float32
    var dew_point: Float32
    var rel_humid: Int32
    var stn_pres: Float32
    var wind_dir: Int32
    var wind_spd: Float32
    var tot_sky_cvr: Int32
    var opaq_sky_cvr: Int32
    var visibility: Float32
    var ceiling: Int32
    var precip_water: Int32
    var aer_opt_depth: Float32
    var snow_depth: Int32
    var days_last_snow: Int32
    
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

struct MissingDataCounts:
    var x_horz_rad: Int32
    var x_dir_norm_rad: Int32
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
    
    fn __init__(inout self):
        self.x_horz_rad = 0
        self.x_dir_norm_rad = 0
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

fn process_number(string: StringLiteral) -> Tuple[Float32, Bool]:
    var ps = string
    var error_flag: Bool = False
    
    if len(ps) == 0:
        return (0.0, False)
    
    var valid_numerics = "0123456789.+-EeDd\t"
    
    for c in ps:
        var found = False
        for vc in valid_numerics:
            if c == vc:
                found = True
                break
        if not found:
            error_flag = True
            break
    
    if not error_flag:
        try:
            var temp: Float32 = atof(ps)
            return (temp, False)
        except:
            return (0.0, True)
    else:
        return (0.0, True)

fn find_non_space(string: StringLiteral) -> Int32:
    var ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0

fn psat(t: Float32) -> Float32:
    var dummy = t + T_KELVIN
    var psat_val: Float32
    
    if t < 0.0:
        psat_val = exp(-5.6745359e+03/dummy
                       - 5.1523058e-01
                       - 9.6778430e-03 * dummy
                       + 6.2215701e-07 * dummy**2
                       + 2.0747825e-09 * dummy**3
                       - 9.4840240e-13 * dummy**4
                       + 4.1635019 * log(dummy))
    else:
        psat_val = exp(-5.8002206e+03/dummy
                       - 5.5162560
                       - 4.8640239e-02 * dummy
                       + 4.1764768e-05 * dummy**2
                       - 1.4452093e-08 * dummy**3
                       + 6.5459673 * log(dummy))
    
    return psat_val * 1000.0

fn _y3(x: Float32, a0: Float32, a1: Float32, a2: Float32, a3: Float32) -> Float32:
    return a0 + x * (a1 + x * (a2 + x * a3))

fn _y5(x: Float32, a0: Float32, a1: Float32, a2: Float32, a3: Float32, a4: Float32, a5: Float32) -> Float32:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

fn _y6(x: Float32, a0: Float32, a1: Float32, a2: Float32, a3: Float32, a4: Float32, a5: Float32, a6: Float32) -> Float32:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))

fn _y7(x: Float32, a0: Float32, a1: Float32, a2: Float32, a3: Float32, a4: Float32, a5: Float32, a6: Float32, a7: Float32) -> Float32:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))

fn satutp(p: Float32) -> Float32:
    var t: Float32
    var pp = p
    
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    
    if p > 2.3366e3:
        if p < 4.2415e3:
            if p < 7.375e3:
                if p < 1.992e4:
                    if p < 1.0133e5:
                        t = _y6(pp, 2.66453e+01, 2.54217e-03, -6.00185e-08, 1.01356e-12, -1.04474e-17, 5.88844e-23, -1.38705e-28)
                    else:
                        t = _y5(pp, 5.69919e+01, 6.37817e-04, -2.85187e-09, 8.77453e-15, -1.48739e-20, 1.04699e-26)
                else:
                    t = _y5(pp, 8.65676e+00, 6.86019e-03, -5.07998e-07, 2.57958e-11, -7.28305e-16, 8.62156e-21)
            else:
                t = _y3(pp, 4.09671e+00, 8.61614e-03, -7.04051e-07, 2.65621e-11)
        else:
            t = _y3(pp, -3.78423e+00, 1.42713e-02, -2.07467e-06, 1.38642e-10)
    else:
        if p > 1.227e3:
            if p > 6.108e2:
                if p > 1.0325e2:
                    if p > 12.842:
                        t = _y3(pp, -11.7426e+00, 2.4662e-02, -6.66598e-06, 8.24255e-10)
                    else:
                        t = _y3(pp, -19.7816e+00, 4.46963e-02, -2.36037e-05, 5.67281e-09)
                else:
                    t = _y6(pp, -3.59131e+01, 2.31311e-01, -1.00453e-03, 2.99919e-06, -5.38184e-09, 5.22567e-12, -2.10354e-15)
            else:
                t = _y7(pp, -5.35428e+01, 1.59311e+00, -5.70202e-02, 1.44012e-03, -2.30578e-05, 2.22628e-07, -1.17867e-09, 2.62131e-12)
        else:
            t = _y5(pp, -67.8912e+00, 9.21677e+00, -1.90385e+00, 2.35588e-01, -1.48075e-02, 3.64517e-04)
    
    return t

fn read_epw(input_file: StringLiteral, inout errors_found: Bool, inout error_message: StringLiteral):
    errors_found = False
    error_message = ""

fn process_epw_headers(weather_file_unit_number: Int32, inout errors_found: Bool, inout error_message: StringLiteral):
    errors_found = False
    error_message = ""

fn process_epw_header(weather_file_unit_number: Int32, header_string: StringLiteral, inout line: StringLiteral, inout errors_found: Bool, inout error_message: StringLiteral):
    errors_found = False
    error_message = ""
