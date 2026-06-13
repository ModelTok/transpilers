from math import log, exp, fmod
from collections import InlineArray

alias r64 = Float64

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals.r64: REAL(8) double precision type (Mojo Float64)
# - GetNewUnitNumber(): external function returning available file unit number

alias A_FORMAT = "(A)"
alias UPPER_CASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
alias LOWER_CASE = "abcdefghijklmnopqrstuvwxyz"
alias PATH_CHAR = "\\"
alias PATH_LIMIT = 255
alias BLANK_STRING = " "
alias MAX_NAME_LENGTH = 60
alias SIGMA = 5.6697e-8
alias T_KELVIN = 273.15
alias PI = 3.141592653589793
alias PI_OVR_2 = PI / 2.0
alias DEGREES_TO_RADIANS = PI / 180.0
alias BYTE_2 = 2

struct WeatherDataDetails:
    var year: Int
    var month: Int
    var day: Int
    var day_of_year: Int
    var interval_minute: InlineArray[Int, 60]
    var data_source_flags: InlineArray[InlineArray[String, 60], 24]
    var dry_bulb: InlineArray[InlineArray[r64, 60], 24]
    var dew_point: InlineArray[InlineArray[r64, 60], 24]
    var wet_bulb: InlineArray[InlineArray[r64, 60], 24]
    var rel_hum: InlineArray[InlineArray[r64, 60], 24]
    var stn_pres: InlineArray[InlineArray[r64, 60], 24]
    var x_hor_rad: InlineArray[InlineArray[r64, 60], 24]
    var x_dir_nor_rad: InlineArray[InlineArray[r64, 60], 24]
    var hor_ir_sky: InlineArray[InlineArray[r64, 60], 24]
    var glob_hor_rad: InlineArray[InlineArray[r64, 60], 24]
    var dir_nor_rad: InlineArray[InlineArray[r64, 60], 24]
    var dif_nor_rad: InlineArray[InlineArray[r64, 60], 24]
    var glob_hor_illum: InlineArray[InlineArray[r64, 60], 24]
    var dir_nor_illum: InlineArray[InlineArray[r64, 60], 24]
    var dif_hor_illum: InlineArray[InlineArray[r64, 60], 24]
    var zen_lum: InlineArray[InlineArray[r64, 60], 24]
    var wind_dir: InlineArray[InlineArray[Int, 60], 24]
    var wind_spd: InlineArray[InlineArray[r64, 60], 24]
    var tot_sky_cvr: InlineArray[InlineArray[Int, 60], 24]
    var opaq_sky_cvr: InlineArray[InlineArray[Int, 60], 24]
    var visibility: InlineArray[InlineArray[r64, 60], 24]
    var ceiling: InlineArray[InlineArray[Int, 60], 24]
    var pres_wth_obs: InlineArray[InlineArray[Int, 60], 24]
    var pres_wth_codes: InlineArray[InlineArray[String, 60], 24]
    var precip_water: InlineArray[InlineArray[Int, 60], 24]
    var aer_opt_depth: InlineArray[InlineArray[r64, 60], 24]
    var snow_depth: InlineArray[InlineArray[Int, 60], 24]
    var days_last_snow: InlineArray[InlineArray[Int, 60], 24]
    var snow_ind: InlineArray[InlineArray[Int, 60], 24]
    var hum_rat: InlineArray[InlineArray[r64, 60], 24]

    fn __init__(inout self):
        self.year = 0
        self.month = 0
        self.day = 0
        self.day_of_year = 0
        self.interval_minute = InlineArray[Int, 60](fill=0)
        self.data_source_flags = InlineArray[InlineArray[String, 60], 24](fill=InlineArray[String, 60](fill="*" * 50))
        self.dry_bulb = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.dew_point = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.wet_bulb = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.rel_hum = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.stn_pres = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.x_hor_rad = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.x_dir_nor_rad = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.hor_ir_sky = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.glob_hor_rad = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.dir_nor_rad = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.dif_nor_rad = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.glob_hor_illum = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.dir_nor_illum = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.dif_hor_illum = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.zen_lum = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.wind_dir = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.wind_spd = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.tot_sky_cvr = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.opaq_sky_cvr = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.visibility = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.ceiling = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.pres_wth_obs = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.pres_wth_codes = InlineArray[InlineArray[String, 60], 24](fill=InlineArray[String, 60](fill="         "))
        self.precip_water = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.aer_opt_depth = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))
        self.snow_depth = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.days_last_snow = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.snow_ind = InlineArray[InlineArray[Int, 60], 24](fill=InlineArray[Int, 60](fill=0))
        self.hum_rat = InlineArray[InlineArray[r64, 60], 24](fill=InlineArray[r64, 60](fill=0.0))


struct MissingData:
    var dry_bulb: r64
    var dew_point: r64
    var rel_humid: Int
    var stn_pres: r64
    var wind_dir: Int
    var wind_spd: r64
    var tot_sky_cvr: Int
    var opaq_sky_cvr: Int
    var visibility: r64
    var ceiling: Int
    var precip_water: Int
    var aer_opt_depth: r64
    var snow_depth: Int
    var days_last_snow: Int

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


struct DataPeriodData:
    var name: String
    var day_of_week: String
    var type_string: String
    var week_day: Int

    fn __init__(inout self):
        self.name = ""
        self.day_of_week = ""
        self.type_string = ""
        self.week_day = 0


struct MissingDataCounts:
    var dry_bulb: Int
    var dew_point: Int
    var rel_humid: Int
    var stn_pres: Int
    var wind_dir: Int
    var wind_spd: Int
    var tot_sky_cvr: Int
    var opaq_sky_cvr: Int
    var visibility: Int
    var ceiling: Int
    var precip_water: Int
    var aer_opt_depth: Int
    var snow_depth: Int
    var days_last_snow: Int

    fn __init__(inout self):
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


struct RangeDataCounts:
    var dry_bulb: Int
    var dew_point: Int
    var rel_humid: Int
    var stn_pres: Int
    var wind_spd: Int

    fn __init__(inout self):
        self.dry_bulb = 0
        self.dew_point = 0
        self.rel_humid = 0
        self.stn_pres = 0
        self.wind_spd = 0


struct EPWWeatherState:
    var w_day: InlineArray[WeatherDataDetails, 366]
    var missing: MissingData
    var missed: MissingDataCounts
    var out_of_range: RangeDataCounts
    var num_days: Int
    var num_intervals_per_hour: Int
    var location_title: String
    var latitude: r64
    var longitude: r64
    var time_zone: r64
    var elevation: r64
    var comment_line: String
    var stn_wmo: String
    var dbg_file: Int
    var err_stats_file: Int
    var num_of_warnings: Int
    var epw_loc_line: String
    var epw_des_cond_line: String
    var epw_typ_ext_line: String
    var epw_grnd_line: String
    var epw_holdst_line: String
    var epw_cmt1_line: String
    var epw_cmt2_line: String
    var epw_data_line: String
    var design_condition_line: String
    var design_condition_title: String
    var design_condition_header: String
    var design_condition_units: String
    var data_file_path: String
    var path_set: Bool
    var leap_year: Bool
    var daylight_saving: Bool
    var wf_leap_year_ind: Int
    var num_special_days: Int
    var num_data_periods: Int
    var data_periods: List[DataPeriodData]
    var epw_daylight_saving: Bool
    var num_epw_des_cond_sets: Int
    var num_epw_typ_ext_sets: Int
    var num_epw_grnd_sets: Int
    var num_input_epw_grnd_sets: Int
    var csv_date_time_normal: Bool
    var csv_data_period_header_found: Bool
    var fix_out_of_range_data: Bool
    var num_et_periods: Int

    fn __init__(inout self):
        var w_day_temp: InlineArray[WeatherDataDetails, 366]
        self.w_day = w_day_temp
        for i in range(366):
            self.w_day[i] = WeatherDataDetails()
        self.missing = MissingData()
        self.missed = MissingDataCounts()
        self.out_of_range = RangeDataCounts()
        self.num_days = 0
        self.num_intervals_per_hour = 0
        self.location_title = ""
        self.latitude = 0.0
        self.longitude = 0.0
        self.time_zone = 0.0
        self.elevation = 0.0
        self.comment_line = ""
        self.stn_wmo = ""
        self.dbg_file = 0
        self.err_stats_file = 0
        self.num_of_warnings = 0
        self.epw_loc_line = "LOCATION,"
        self.epw_des_cond_line = "DESIGN CONDITIONS,0"
        self.epw_typ_ext_line = "TYPICAL/EXTREME PERIODS,0"
        self.epw_grnd_line = "GROUND TEMPERATURES,0"
        self.epw_holdst_line = "HOLIDAYS/DAYLIGHT SAVINGS,No,0,0,0"
        self.epw_cmt1_line = "COMMENTS 1,"
        self.epw_cmt2_line = "COMMENTS 2,"
        self.epw_data_line = "DATA PERIODS,1,1,Data,Sunday,1/1,12/31"
        self.design_condition_line = " "
        self.design_condition_title = " "
        self.design_condition_header = " "
        self.design_condition_units = " "
        self.data_file_path = " "
        self.path_set = False
        self.leap_year = False
        self.daylight_saving = False
        self.wf_leap_year_ind = 0
        self.num_special_days = 0
        self.num_data_periods = 0
        self.data_periods = List[DataPeriodData]()
        self.epw_daylight_saving = False
        self.num_epw_des_cond_sets = 0
        self.num_epw_typ_ext_sets = 0
        self.num_epw_grnd_sets = 0
        self.num_input_epw_grnd_sets = 0
        self.csv_date_time_normal = True
        self.csv_data_period_header_found = False
        self.fix_out_of_range_data = False
        self.num_et_periods = 0


fn process_number(string: String) -> Tuple[r64, Bool]:
    let valid_numerics = "0123456789.+-EeDd\t"
    let p_string = string.strip()
    if len(p_string) == 0:
        return 0.0, False
    for char in p_string:
        if char not in valid_numerics:
            return 0.0, True
    try:
        let temp = Float64(p_string)
        return temp, False
    except:
        return 0.0, True


fn find_non_space(string: String) -> Int:
    let ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0


fn make_upper_case(input_string: String) -> String:
    var result_string = ""
    let length_input_string = len(input_string.rstrip())
    for count in range(length_input_string):
        let pos = LOWER_CASE.find(input_string[count])
        if pos >= 0:
            result_string += UPPER_CASE[pos]
        else:
            result_string += input_string[count]
    return result_string.rstrip()


fn same_string(test_string1: String, test_string2: String) -> Bool:
    return make_upper_case(test_string1) == make_upper_case(test_string2)


fn find_item(string: String, list_of_items: List[String], num_items: Int) -> Int:
    for count in range(num_items):
        if same_string(string, list_of_items[count]):
            return count + 1
    return 0


fn get_stm(longitude: r64) -> r64:
    var longl = Dict[Int, r64]()
    var longh = Dict[Int, r64]()
    longl[0] = -7.5
    longh[0] = 7.5
    for i in range(1, 13):
        longl[i] = longl[i - 1] + 15.0
        longh[i] = longh[i - 1] + 15.0
    for i in range(1, 13):
        longl[-i] = longl[-i + 1] - 15.0
        longh[-i] = longh[-i + 1] - 15.0
    var temp = longitude
    temp = fmod(temp, 360.0)
    if temp > 180.0:
        temp = temp - 180.0
    for i in range(-12, 13):
        if temp > longl[i] and temp <= longh[i]:
            let tz = i
            return fmod(tz, 24.0)
    return 0.0


@always_inline
fn _y3(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))


@always_inline
fn _y4(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))


@always_inline
fn _y5(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))


@always_inline
fn _y6(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))


@always_inline
fn _y7(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64, a7: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))


fn psat(t: r64) -> r64:
    let dummy = t + 273.15
    if t < 0.0:
        let psat_val = exp(-5.6745359e+03 / dummy - 5.1523058e-01 - 9.6778430e-03 * dummy + 6.2215701e-07 * dummy * dummy + 2.0747825e-09 * dummy * dummy * dummy - 9.4840240e-13 * dummy * dummy * dummy * dummy + 4.1635019 * log(dummy))
        return psat_val * 1000.0
    else:
        let psat_val = exp(-5.8002206e+03 / dummy - 5.5162560 - 4.8640239e-02 * dummy + 4.1764768e-05 * dummy * dummy - 1.4452093e-08 * dummy * dummy * dummy + 6.5459673 * log(dummy))
        return psat_val * 1000.0


fn satutp(p: r64) -> r64:
    let pp = p
    var t: r64 = 0.0
    if p > 2.3366e3:
        if p < 4.2415e3:
            t = _y3(pp, -3.78423, 1.42713e-2, -2.07467e-6, 1.38642e-10)
        elif p < 7.375e3:
            t = _y3(pp, 4.09671, 8.61614e-3, -7.04051e-7, 2.65621e-11)
        elif p < 1.992e4:
            t = _y5(pp, 8.65676, 6.86019e-3, -5.07998e-7, 2.57958e-11, -7.28305e-16, 8.62156e-21)
        elif p < 1.0133e5:
            t = _y6(pp, 2.66453e1, 2.54217e-3, -6.00185e-8, 1.01356e-12, -1.04474e-17, 5.88844e-23, -1.38705e-28)
        else:
            t = _y5(pp, 5.69919e1, 6.37817e-4, -2.85187e-9, 8.77453e-15, -1.48739e-20, 1.04699e-26)
    elif p > 1.227e3:
        if p < 4.2415e3:
            t = _y3(pp, -3.78423, 1.42713e-2, -2.07467e-6, 1.38642e-10)
        else:
            t = _y3(pp, 4.09671, 8.61614e-3, -7.04051e-7, 2.65621e-11)
    elif p > 6.108e2:
        t = _y3(pp, -19.7816, 4.46963e-2, -2.36037e-5, 5.67281e-9)
    elif p > 1.0325e2:
        t = _y3(pp, -11.7426, 2.4662e-2, -6.66598e-6, 8.24255e-10)
    elif p > 12.842:
        t = _y7(pp, -5.35428e1, 1.59311, -5.70202e-2, 1.44012e-3, -2.30578e-5, 2.22628e-7, -1.17867e-9)
    else:
        t = _y5(pp, -67.8912, 9.21677, -1.90385, 2.35588e-1, -1.48075e-2, 3.64517e-4)
    return t


fn dry_sat_pt(tdb: r64) -> r64:
    let tt = tdb
    var psat_val: r64 = 0.0
    if tdb > 20:
        if tdb < 30.0:
            psat_val = _y3(tt, 4.05663e2, 76.8637, -4.47857e-1, 7.15905e-2)
        elif tdb < 40.0:
            psat_val = _y3(tt, -3.58332e2, 1.52167e2, -2.93294, 9.90514e-2)
        else:
            psat_val = _y5(tt, 7.30208e2, 32.987, 1.84658, 1.95497e-2, 3.33617e-4, 2.59343e-6)
    elif tdb > 10.0:
        psat_val = _y3(tt, 5.9088e2, 49.8847, 8.74643e-1, 4.97621e-2)
    elif tdb > 0.0:
        psat_val = _y3(tt, 6.10775e2, 44.4502, 1.38578, 3.3106e-2)
    elif tdb > -20.0:
        psat_val = _y4(tt, 6.10860e2, 50.1255, 1.83622, 3.67769e-2, 3.41421e-4)
    elif tdb > -40.0:
        psat_val = _y4(tt, 5.69275e2, 42.5035, 1.29301, 1.88391e-2, 1.0961e-4)
    else:
        psat_val = _y5(tt, 4.9752e2, 35.3452, 1.04398, 1.5962e-2, 1.2578e-4, 4.0683e-7)
    return psat_val


fn process_epw_headers(weather_file_unit_number: Int, inout state: EPWWeatherState) -> Bool:
    let header = List[String]("LOCATION                ", "DESIGN CONDITIONS       ", "TYPICAL/EXTREME PERIODS ", "GROUND TEMPERATURES     ", "HOLIDAYS/DAYLIGHT SAVING", "COMMENTS 1              ", "COMMENTS 2              ", "DATA PERIODS            ")
    var errors_found = False
    var hd_line = 0
    var still_looking = True
    while still_looking:
        pass
    return errors_found


fn process_epw_header(weather_file_unit_number: Int, header_string: String, inout line: String, inout state: EPWWeatherState) -> Bool:
    var errors_found = False
    let pos = line.find(",")
    if pos >= 0:
        line = line[pos + 1:]
    var title = ""
    if header_string == "LOCATION":
        state.epw_loc_line = "LOCATION," + line
        var num_hd_args = 9
        var count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            var pos_inner = line.find(",")
            if pos_inner < 0:
                if len(line.rstrip()) == 0:
                    while pos_inner < 0:
                        pass
                else:
                    pos_inner = len(line.rstrip())
            if count == 1:
                title = line[:pos_inner]
            elif count in [2, 3, 4]:
                title = title + " " + line[:pos_inner]
            elif count in [5, 6, 7, 8, 9]:
                if count == 5:
                    let char_wmo = line[:pos_inner]
                    if state.design_condition_line != BLANK_STRING:
                        state.stn_wmo = char_wmo
                    else:
                        state.stn_wmo = "unknown"
                else:
                    let number_result = process_number(line[:pos_inner])
                    let number = number_result[0]
                    let err_flag = number_result[1]
                    if not err_flag:
                        if count == 6:
                            state.latitude = number
                        elif count == 7:
                            state.longitude = number
                        elif count == 8:
                            state.time_zone = number
                        elif count == 9:
                            state.elevation = number
                    else:
                        state.err_stats_file = 1
                        errors_found = True
            line = line[pos_inner + 1:]
            count = count + 1
        state.location_title = title.strip()
    elif header_string == "DESIGN CONDITIONS":
        state.epw_des_cond_line = "DESIGN CONDITIONS," + line
        line = line.lstrip()
        var pos_dc = line.find(",")
        if pos_dc < 0:
            if len(line.rstrip()) == 0:
                while pos_dc < 0:
                    pass
            else:
                pos_dc = len(line.rstrip())
        let num_result = process_number(line[:pos_dc])
        state.num_epw_des_cond_sets = Int(num_result[0])
    elif header_string == "TYPICAL/EXTREME PERIODS":
        state.epw_typ_ext_line = "TYPICAL/EXTREME PERIODS," + line
        line = line.lstrip()
        var pos_te = line.find(",")
        if pos_te < 0:
            if len(line.rstrip()) == 0:
                while pos_te < 0:
                    pass
            else:
                pos_te = len(line.rstrip())
        let num_result = process_number(line[:pos_te])
        state.num_epw_typ_ext_sets = Int(num_result[0])
    elif header_string == "GROUND TEMPERATURES":
        state.epw_grnd_line = "GROUND TEMPERATURES," + line
        line = line.lstrip()
        var pos_gt = line.find(",")
        if pos_gt < 0:
            if len(line.rstrip()) == 0:
                while pos_gt < 0:
                    pass
            else:
                pos_gt = len(line.rstrip())
        let num_result = process_number(line[:pos_gt])
        state.num_input_epw_grnd_sets = Int(num_result[0])
    elif header_string == "HOLIDAYS/DAYLIGHT SAVING":
        state.epw_holdst_line = "HOLIDAYS/DAYLIGHT SAVING," + line
        var num_hd_args = 4
        var count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            var pos_hds = line.find(",")
            if pos_hds < 0:
                if len(line.rstrip()) == 0:
                    while pos_hds < 0:
                        pass
                else:
                    pos_hds = len(line.rstrip())
            if count == 1:
                if line[0] == 'Y':
                    state.leap_year = True
                    state.wf_leap_year_ind = 1
                else:
                    state.leap_year = False
                    state.wf_leap_year_ind = 0
            line = line[pos_hds + 1:]
            count = count + 1
    elif header_string == "COMMENTS 1":
        state.epw_cmt1_line = "COMMENTS 1," + line
    elif header_string == "COMMENTS 2":
        state.epw_cmt2_line = "COMMENTS 2," + line
    elif header_string == "DATA PERIODS":
        state.epw_data_line = "DATA PERIODS," + line
        var num_hd_args = 2
        var count = 1
        var cur_count = 0
        while count <= num_hd_args:
            line = line.lstrip()
            var pos_dp = line.find(",")
            if pos_dp < 0:
                if len(line.rstrip()) == 0:
                    while pos_dp < 0:
                        pass
                else:
                    pos_dp = len(line.rstrip())
            if count == 1:
                let num_result = process_number(line[:pos_dp])
                state.num_data_periods = Int(num_result[0])
                for _ in range(state.num_data_periods):
                    state.data_periods.append(DataPeriodData())
                num_hd_args = num_hd_args + 4 * state.num_data_periods
            elif count == 2:
                let num_result = process_number(line[:pos_dp])
                state.num_intervals_per_hour = Int(num_result[0])
            else:
                let cur_one = (count - 3) % 4
                if cur_one == 0:
                    cur_count = cur_count + 1
                    if cur_count <= state.num_data_periods:
                        state.data_periods[cur_count - 1].name = line[:pos_dp]
                elif cur_one == 1:
                    if cur_count <= state.num_data_periods:
                        state.data_periods[cur_count - 1].day_of_week = line[:pos_dp]
                        state.data_periods[cur_count - 1].week_day = find_item(state.data_periods[cur_count - 1].day_of_week, List[String]("SUNDAY   ", "MONDAY   ", "TUESDAY  ", "WEDNESDAY", "THURSDAY ", "FRIDAY   ", "SATURDAY "), 7)
                        if state.data_periods[cur_count - 1].week_day == 0:
                            state.err_stats_file = 1
                            errors_found = True
                elif cur_one == 2:
                    state.data_periods[cur_count - 1].type_string = line[:pos_dp]
                elif cur_one == 3:
                    state.data_periods[cur_count - 1].type_string = state.data_periods[cur_count - 1].type_string + "," + line[:pos_dp]
            line = line[pos_dp + 1:]
            count = count + 1
    return errors_found


fn read_epw(input_file: String, inout state: EPWWeatherState) -> Tuple[Bool, Int]:
    var errors_found = False
    var n_days = 0
    var num_days = 0
    var hour = 24
    var interval = state.num_intervals_per_hour
    return errors_found, n_days


@export
fn get_epw_weather(day: Int, hour: Int, inout state: EPWWeatherState) -> Tuple[r64, r64, r64, r64, r64, r64, r64, r64]:
    let interval = 1
    let beam = state.w_day[day].dir_nor_rad[hour - 1][interval - 1]
    let diffuse = state.w_day[day].dif_nor_rad[hour - 1][interval - 1]
    let dry_bulb = state.w_day[day].dry_bulb[hour - 1][interval - 1]
    let dew_point = state.w_day[day].dew_point[hour - 1][interval - 1]
    let rel_humid = state.w_day[day].rel_hum[hour - 1][interval - 1]
    let atm_press = state.w_day[day].stn_pres[hour - 1][interval - 1]
    let wind_spd = state.w_day[day].wind_spd[hour - 1][interval - 1]
    let snow_depth = state.w_day[day].snow_depth[hour - 1][interval - 1]
    return dry_bulb, atm_press, dew_point, rel_humid, wind_spd, beam, diffuse, Float64(snow_depth)


@export
fn get_loc_data(inout state: EPWWeatherState) -> Tuple[r64, r64, r64]:
    return state.latitude, state.longitude, state.elevation
