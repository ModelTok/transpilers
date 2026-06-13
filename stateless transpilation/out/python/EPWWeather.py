from dataclasses import dataclass, field
from typing import List, Tuple
import math

r64 = float

# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals.r64: REAL(8) double precision type (python float)
# - GetNewUnitNumber(): external function returning available file unit number

A_FORMAT = '(A)'
UPPER_CASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
LOWER_CASE = 'abcdefghijklmnopqrstuvwxyz'
PATH_CHAR = '\\'
PATH_LIMIT = 255
BLANK_STRING = ' '
MAX_NAME_LENGTH = 60
SIGMA = 5.6697e-8
T_KELVIN = 273.15
PI = 3.141592653589793
PI_OVR_2 = PI / 2.0
DEGREES_TO_RADIANS = PI / 180.0
BYTE_2 = 2

WMO_REGION = [
    'Africa                   ',
    'Asia                     ',
    'South America            ',
    'North and Central America',
    'South-west Pacific       ',
    'Europe                   ',
    'Antarctica               ',
    'Unknown                  '
]

INVALID_DATE = -1
MONTH_DAY = 1
NTH_DAY_IN_MONTH = 2
LAST_DAY_IN_MONTH = 3

DAYS_OF_WEEK = [
    "SUNDAY   ", "MONDAY   ", "TUESDAY  ",
    "WEDNESDAY", "THURSDAY ", "FRIDAY   ", "SATURDAY "
]

NUM_DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


@dataclass
class WeatherDataDetails:
    year: int = 0
    month: int = 0
    day: int = 0
    day_of_year: int = 0
    interval_minute: List[int] = field(default_factory=lambda: [0] * 60)
    data_source_flags: List[List[str]] = field(default_factory=lambda: [['*' * 50 for _ in range(60)] for _ in range(24)])
    dry_bulb: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    dew_point: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    wet_bulb: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    rel_hum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    stn_pres: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    x_hor_rad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    x_dir_nor_rad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    hor_ir_sky: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    glob_hor_rad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    dir_nor_rad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    dif_nor_rad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    glob_hor_illum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    dir_nor_illum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    dif_hor_illum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    zen_lum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    wind_dir: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    wind_spd: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    tot_sky_cvr: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    opaq_sky_cvr: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    visibility: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    ceiling: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    pres_wth_obs: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    pres_wth_codes: List[List[str]] = field(default_factory=lambda: [['         ' for _ in range(60)] for _ in range(24)])
    precip_water: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    aer_opt_depth: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    snow_depth: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    days_last_snow: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    snow_ind: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    hum_rat: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])


@dataclass
class MissingData:
    dry_bulb: r64 = 0.0
    dew_point: r64 = 0.0
    rel_humid: int = 0
    stn_pres: r64 = 0.0
    wind_dir: int = 0
    wind_spd: r64 = 0.0
    tot_sky_cvr: int = 0
    opaq_sky_cvr: int = 0
    visibility: r64 = 0.0
    ceiling: int = 0
    precip_water: int = 0
    aer_opt_depth: r64 = 0.0
    snow_depth: int = 0
    days_last_snow: int = 0


@dataclass
class DataPeriodData:
    name: str = ''
    day_of_week: str = ''
    type_string: str = ''
    week_day: int = 0


@dataclass
class MissingDataCounts:
    dry_bulb: int = 0
    dew_point: int = 0
    rel_humid: int = 0
    stn_pres: int = 0
    wind_dir: int = 0
    wind_spd: int = 0
    tot_sky_cvr: int = 0
    opaq_sky_cvr: int = 0
    visibility: int = 0
    ceiling: int = 0
    precip_water: int = 0
    aer_opt_depth: int = 0
    snow_depth: int = 0
    days_last_snow: int = 0


@dataclass
class RangeDataCounts:
    dry_bulb: int = 0
    dew_point: int = 0
    rel_humid: int = 0
    stn_pres: int = 0
    wind_spd: int = 0


@dataclass
class EPWWeatherState:
    w_day: List[WeatherDataDetails] = field(default_factory=lambda: [WeatherDataDetails() for _ in range(366)])
    missing: MissingData = field(default_factory=MissingData)
    missed: MissingDataCounts = field(default_factory=MissingDataCounts)
    out_of_range: RangeDataCounts = field(default_factory=RangeDataCounts)
    num_days: int = 0
    num_intervals_per_hour: int = 0
    location_title: str = ''
    latitude: r64 = 0.0
    longitude: r64 = 0.0
    time_zone: r64 = 0.0
    elevation: r64 = 0.0
    comment_line: str = ''
    stn_wmo: str = ''
    dbg_file: int = 0
    err_stats_file: int = 0
    num_of_warnings: int = 0
    epw_loc_line: str = 'LOCATION,'
    epw_des_cond_line: str = 'DESIGN CONDITIONS,0'
    epw_typ_ext_line: str = 'TYPICAL/EXTREME PERIODS,0'
    epw_grnd_line: str = 'GROUND TEMPERATURES,0'
    epw_holdst_line: str = 'HOLIDAYS/DAYLIGHT SAVINGS,No,0,0,0'
    epw_cmt1_line: str = 'COMMENTS 1,'
    epw_cmt2_line: str = 'COMMENTS 2,'
    epw_data_line: str = 'DATA PERIODS,1,1,Data,Sunday,1/1,12/31'
    design_condition_line: str = ' '
    design_condition_title: str = ' '
    design_condition_header: str = ' '
    design_condition_units: str = ' '
    data_file_path: str = ' '
    path_set: bool = False
    leap_year: bool = False
    daylight_saving: bool = False
    wf_leap_year_ind: int = 0
    num_special_days: int = 0
    num_data_periods: int = 0
    data_periods: List[DataPeriodData] = field(default_factory=list)
    epw_daylight_saving: bool = False
    num_epw_des_cond_sets: int = 0
    num_epw_typ_ext_sets: int = 0
    num_epw_grnd_sets: int = 0
    num_input_epw_grnd_sets: int = 0
    csv_date_time_normal: bool = True
    csv_data_period_header_found: bool = False
    fix_out_of_range_data: bool = False
    num_et_periods: int = 0


def process_number(string: str) -> Tuple[r64, bool]:
    valid_numerics = '0123456789.+-EeDd\t'
    p_string = string.strip()
    if len(p_string) == 0:
        return 0.0, False
    for char in p_string:
        if char not in valid_numerics:
            return 0.0, True
    try:
        temp = float(p_string)
        return temp, False
    except ValueError:
        return 0.0, True


def find_non_space(string: str) -> int:
    ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0


def make_upper_case(input_string: str) -> str:
    result_string = ''
    length_input_string = len(input_string.rstrip())
    for count in range(length_input_string):
        pos = LOWER_CASE.find(input_string[count])
        if pos >= 0:
            result_string += UPPER_CASE[pos]
        else:
            result_string += input_string[count]
    return result_string.rstrip()


def same_string(test_string1: str, test_string2: str) -> bool:
    return make_upper_case(test_string1) == make_upper_case(test_string2)


def find_item(string: str, list_of_items: List[str], num_items: int) -> int:
    for count in range(num_items):
        if same_string(string, list_of_items[count]):
            return count + 1
    return 0


def get_stm(longitude: r64) -> r64:
    longl = {}
    longh = {}
    longl[0] = -7.5
    longh[0] = 7.5
    for i in range(1, 13):
        longl[i] = longl[i - 1] + 15.0
        longh[i] = longh[i - 1] + 15.0
    for i in range(1, 13):
        longl[-i] = longl[-i + 1] - 15.0
        longh[-i] = longh[-i + 1] - 15.0
    temp = longitude
    temp = math.fmod(temp, 360.0)
    if temp > 180.0:
        temp = temp - 180.0
    for i in range(-12, 13):
        if temp > longl[i] and temp <= longh[i]:
            tz = i
            tz = math.fmod(tz, 24.0)
            return tz
    return 0.0


def _y3(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))


def _y4(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))


def _y5(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))


def _y6(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))


def _y7(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64, a7: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))


def psat(t: r64) -> r64:
    dummy = t + 273.15
    if t < 0.0:
        psat_val = math.exp(-5.6745359e+03 / dummy - 5.1523058e-01 - 9.6778430e-03 * dummy + 6.2215701e-07 * dummy**2 + 2.0747825e-09 * dummy**3 - 9.4840240e-13 * dummy**4 + 4.1635019 * math.log(dummy))
    else:
        psat_val = math.exp(-5.8002206e+03 / dummy - 5.5162560 - 4.8640239e-02 * dummy + 4.1764768e-05 * dummy**2 - 1.4452093e-08 * dummy**3 + 6.5459673 * math.log(dummy))
    return psat_val * 1000.0


def satutp(p: r64) -> r64:
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    pp = p
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


def dry_sat_pt(tdb: r64) -> r64:
    tt = tdb
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


def process_epw_headers(weather_file_unit_number: int, state: EPWWeatherState) -> bool:
    header = ["LOCATION                ", "DESIGN CONDITIONS       ", "TYPICAL/EXTREME PERIODS ", "GROUND TEMPERATURES     ", "HOLIDAYS/DAYLIGHT SAVING", "COMMENTS 1              ", "COMMENTS 2              ", "DATA PERIODS            "]
    errors_found = False
    hd_line = 0
    still_looking = True
    while still_looking:
        try:
            line = input()
        except EOFError:
            state.err_stats_file = 1
            errors_found = True
            break
        pos = find_non_space(line)
        hd_pos = line.find(header[hd_line])
        if pos - 1 != hd_pos:
            continue
        process_epw_header(weather_file_unit_number, header[hd_line], line, state)
        hd_line += 1
        if hd_line == 8:
            still_looking = False
    return errors_found


def process_epw_header(weather_file_unit_number: int, header_string: str, line: str, state: EPWWeatherState) -> bool:
    errors_found = False
    pos = line.find(',')
    if pos >= 0:
        line = line[pos + 1:]
    title = ''
    if header_string == 'LOCATION':
        state.epw_loc_line = 'LOCATION,' + line
        num_hd_args = 9
        count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos < 0:
                if len(line.rstrip()) == 0:
                    while pos < 0:
                        try:
                            line = input()
                        except EOFError:
                            break
                        line = line.lstrip()
                        pos = line.find(',')
                else:
                    pos = len(line.rstrip())
            if count == 1:
                title = line[:pos]
            elif count in [2, 3, 4]:
                title = title + ' ' + line[:pos]
            elif count in [5, 6, 7, 8, 9]:
                if count == 5:
                    char_wmo = line[:pos]
                    if state.design_condition_line != BLANK_STRING:
                        state.stn_wmo = char_wmo
                    else:
                        state.stn_wmo = 'unknown'
                else:
                    number, err_flag = process_number(line[:pos])
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
            line = line[pos + 1:]
            count += 1
        state.location_title = title.strip()
    elif header_string == 'DESIGN CONDITIONS':
        state.epw_des_cond_line = 'DESIGN CONDITIONS,' + line
        line = line.lstrip()
        pos = line.find(',')
        if pos < 0:
            if len(line.rstrip()) == 0:
                while pos < 0:
                    try:
                        line = input()
                    except EOFError:
                        break
                    line = line.lstrip()
                    pos = line.find(',')
            else:
                pos = len(line.rstrip())
        state.num_epw_des_cond_sets, _ = process_number(line[:pos])
    elif header_string == 'TYPICAL/EXTREME PERIODS':
        state.epw_typ_ext_line = 'TYPICAL/EXTREME PERIODS,' + line
        line = line.lstrip()
        pos = line.find(',')
        if pos < 0:
            if len(line.rstrip()) == 0:
                while pos < 0:
                    try:
                        line = input()
                    except EOFError:
                        break
                    line = line.lstrip()
                    pos = line.find(',')
            else:
                pos = len(line.rstrip())
        state.num_epw_typ_ext_sets, _ = process_number(line[:pos])
    elif header_string == 'GROUND TEMPERATURES':
        state.epw_grnd_line = 'GROUND TEMPERATURES,' + line
        line = line.lstrip()
        pos = line.find(',')
        if pos < 0:
            if len(line.rstrip()) == 0:
                while pos < 0:
                    try:
                        line = input()
                    except EOFError:
                        break
                    line = line.lstrip()
                    pos = line.find(',')
            else:
                pos = len(line.rstrip())
        state.num_input_epw_grnd_sets, _ = process_number(line[:pos])
    elif header_string == 'HOLIDAYS/DAYLIGHT SAVING':
        state.epw_holdst_line = 'HOLIDAYS/DAYLIGHT SAVING,' + line
        num_hd_args = 4
        count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos < 0:
                if len(line.rstrip()) == 0:
                    while pos < 0:
                        try:
                            line = input()
                        except EOFError:
                            break
                        line = line.lstrip()
                        pos = line.find(',')
                else:
                    pos = len(line.rstrip())
            if count == 1:
                if line[0] == 'Y':
                    state.leap_year = True
                    state.wf_leap_year_ind = 1
                else:
                    state.leap_year = False
                    state.wf_leap_year_ind = 0
            line = line[pos + 1:]
            count += 1
    elif header_string == 'COMMENTS 1':
        state.epw_cmt1_line = 'COMMENTS 1,' + line
    elif header_string == 'COMMENTS 2':
        state.epw_cmt2_line = 'COMMENTS 2,' + line
    elif header_string == 'DATA PERIODS':
        state.epw_data_line = 'DATA PERIODS,' + line
        num_hd_args = 2
        count = 1
        cur_count = 0
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos < 0:
                if len(line.rstrip()) == 0:
                    while pos < 0:
                        try:
                            line = input()
                        except EOFError:
                            break
                        line = line.lstrip()
                        pos = line.find(',')
                else:
                    pos = len(line.rstrip())
            if count == 1:
                state.num_data_periods, _ = process_number(line[:pos])
                state.data_periods = [DataPeriodData() for _ in range(state.num_data_periods)]
                num_hd_args += 4 * state.num_data_periods
            elif count == 2:
                state.num_intervals_per_hour, _ = process_number(line[:pos])
            else:
                cur_one = (count - 3) % 4
                if cur_one == 0:
                    cur_count += 1
                    if cur_count <= state.num_data_periods:
                        state.data_periods[cur_count - 1].name = line[:pos]
                elif cur_one == 1:
                    if cur_count <= state.num_data_periods:
                        state.data_periods[cur_count - 1].day_of_week = line[:pos]
                        state.data_periods[cur_count - 1].week_day = find_item(state.data_periods[cur_count - 1].day_of_week, DAYS_OF_WEEK, 7)
                        if state.data_periods[cur_count - 1].week_day == 0:
                            state.err_stats_file = 1
                            errors_found = True
                elif cur_one == 2:
                    state.data_periods[cur_count - 1].type_string = line[:pos]
                elif cur_one == 3:
                    state.data_periods[cur_count - 1].type_string = state.data_periods[cur_count - 1].type_string + ',' + line[:pos]
            line = line[pos + 1:]
            count += 1
    return errors_found


def read_epw(input_file: str, state: EPWWeatherState) -> Tuple[bool, int]:
    errors_found = False
    n_days = 0
    try:
        unit_no = open(input_file, 'r')
    except IOError:
        state.num_of_warnings += 1
        errors_found = True
        return errors_found, n_days
    state.num_intervals_per_hour = 1
    process_epw_headers(unit_no.fileno(), state)
    num_days = 0
    hour = 24
    interval = state.num_intervals_per_hour
    for input_line in unit_no:
        input_line = input_line.rstrip('\n')
        com5 = [0] * 5
        for count in range(5):
            idx = input_line.find(',')
            if idx >= 0:
                com5[count] = idx
                input_line = input_line[:idx] + '$' + input_line[idx + 1:]
        comma6 = input_line.find(',')
        if comma6 < 0:
            comma6 = len(input_line)
        source_flags = input_line[com5[4] + 1:comma6].strip() if com5[4] < len(input_line) else ''
        source_flags = source_flags.replace(' ', '_')
        input_line = input_line[:com5[4] + 1] + source_flags + input_line[comma6:]
        for count in range(5):
            input_line = input_line[:com5[count]] + ',' + input_line[com5[count] + 1:]
        parts = input_line.split(',')
        if len(parts) < 34:
            continue
        try:
            w_year = int(parts[0])
            w_month = int(parts[1])
            w_day_of_month = int(parts[2])
            w_hour = int(parts[3])
            w_minute = float(parts[4])
            source_flags = parts[5].strip()
            dry_bulb = float(parts[6])
            dew_point = float(parts[7])
            rel_humid = float(parts[8])
            atm_press = float(parts[9])
            ext_hor_rad = float(parts[10])
            ext_dir_nor_rad = float(parts[11])
            ir_horiz = float(parts[12])
            glo_hor_rad = float(parts[13])
            dir_nor_rad = float(parts[14])
            dif_nor_rad = float(parts[15])
            glo_hor_illum = float(parts[16])
            dir_nor_illum = float(parts[17])
            dif_hor_illum = float(parts[18])
            zenith_lum = float(parts[19])
            wind_dir = float(parts[20])
            wind_spd = float(parts[21])
            tot_sky_cvr = float(parts[22])
            opq_sky_cvr = float(parts[23])
            visibility = float(parts[24])
            ceil_hgt = float(parts[25])
            pres_weath_obs = float(parts[26])
            pres_weath_codes = parts[27].strip()
            prec_wtr = float(parts[28])
            aer_opt_depth = float(parts[29])
            snow_depth = float(parts[30])
            days_last_snow = float(parts[31])
        except (ValueError, IndexError):
            continue
        interval = interval + 1
        if interval > state.num_intervals_per_hour:
            interval = 1
            hour = hour + 1
        if hour > 24:
            hour = 1
            num_days = num_days + 1
        if hour == 1:
            state.w_day[num_days].year = w_year
            state.w_day[num_days].month = w_month
            state.w_day[num_days].day = w_day_of_month
        state.w_day[num_days].interval_minute[interval - 1] = int(round(w_minute))
        fld_list = [source_flags[i:i+2] if i < len(source_flags) else '  ' for i in range(0, min(len(source_flags), 44), 2)]
        fld1 = fld_list[0] if len(fld_list) > 0 else '  '
        fld2 = fld_list[1] if len(fld_list) > 1 else '  '
        fld3 = fld_list[2] if len(fld_list) > 2 else '  '
        fld4 = fld_list[3] if len(fld_list) > 3 else '  '
        fld_ir = fld_list[4] if len(fld_list) > 4 else '  '
        fld5 = fld_list[5] if len(fld_list) > 5 else '  '
        fld6 = fld_list[6] if len(fld_list) > 6 else '  '
        fld7 = fld_list[7] if len(fld_list) > 7 else '  '
        fld8 = fld_list[8] if len(fld_list) > 8 else '  '
        fld9 = fld_list[9] if len(fld_list) > 9 else '  '
        fld10 = fld_list[10] if len(fld_list) > 10 else '  '
        fld11 = fld_list[11] if len(fld_list) > 11 else '  '
        fld12 = fld_list[12] if len(fld_list) > 12 else '  '
        fld13 = fld_list[13] if len(fld_list) > 13 else '  '
        fld14 = fld_list[14] if len(fld_list) > 14 else '  '
        fld15 = fld_list[15] if len(fld_list) > 15 else '  '
        fld16 = fld_list[16] if len(fld_list) > 16 else '  '
        fld17 = fld_list[17] if len(fld_list) > 17 else '  '
        fld18 = fld_list[18] if len(fld_list) > 18 else '  '
        fld19 = fld_list[19] if len(fld_list) > 19 else '  '
        fld20 = fld_list[20] if len(fld_list) > 20 else '  '
        fld21 = fld_list[21] if len(fld_list) > 21 else '  '
        if dry_bulb == 99.9:
            dry_bulb = state.missing.dry_bulb
            fld10 = '*' + fld10[1:]
            state.missed.dry_bulb += 1
        if atm_press == 999999.0:
            atm_press = state.missing.stn_pres
            fld13 = '*' + fld13[1:] if len(fld13) > 1 else '*'
            state.missed.stn_pres += 1
        if rel_humid == 999.0:
            rel_humid = state.missing.rel_humid
            fld12 = '*' + fld12[1:]
            state.missed.rel_humid += 1
            rel_humid_missing = True
        else:
            rel_humid_missing = False
        if dew_point == 99.9:
            state.missed.dew_point += 1
            if rel_humid_missing:
                dew_point = state.missing.dew_point
                fld11 = '*' + fld11[1:]
                if dew_point > dry_bulb:
                    dew_point = dry_bulb - 3.0
            else:
                pws = psat(dry_bulb)
                pw = max(rel_humid, 1.0) * 0.01 * pws
                dew_point = satutp(pw)
                fld11 = '*' + fld11[1:]
        if wind_spd == 999.0:
            wind_spd = state.missing.wind_spd
            fld15 = '*' + fld15[1:]
            state.missed.wind_spd += 1
        if wind_dir == 999.0:
            wind_dir = state.missing.wind_dir
            fld14 = '*' + fld14[1:]
            state.missed.wind_dir += 1
        i_wind_dir = int(wind_dir)
        if visibility == 9999.0:
            visibility = state.missing.visibility
            fld16 = '*' + fld16[1:]
            state.missed.visibility += 1
        if aer_opt_depth == 0.999:
            aer_opt_depth = state.missing.aer_opt_depth
            fld19 = '*' + fld19[1:] if len(fld19) > 1 else '*'
            state.missed.aer_opt_depth += 1
        if tot_sky_cvr == 99.0:
            tot_sky_cvr = state.missing.tot_sky_cvr
            fld8 = '*' + fld8[1:]
            state.missed.tot_sky_cvr += 1
        if opq_sky_cvr == 99.0:
            opq_sky_cvr = state.missing.opaq_sky_cvr
            fld9 = '*' + fld9[1:]
            state.missed.opaq_sky_cvr += 1
        if ceil_hgt == 99999.0:
            ceil_hgt = state.missing.ceiling
            fld17 = '*' + fld17[1:]
            state.missed.ceiling += 1
        if prec_wtr == 999:
            prec_wtr = state.missing.precip_water
            fld18 = '*' + fld18[1:]
            state.missed.precip_water += 1
        if snow_depth == 999:
            snow_depth = state.missing.snow_depth
            fld20 = '*' + fld20[1:]
            state.missed.snow_depth += 1
        if days_last_snow == 99:
            days_last_snow = state.missing.days_last_snow
            fld21 = '*' + fld21[1:]
            state.missed.days_last_snow += 1
        state.w_day[num_days].x_hor_rad[hour - 1][interval - 1] = ext_hor_rad
        state.w_day[num_days].x_dir_nor_rad[hour - 1][interval - 1] = ext_dir_nor_rad
        state.w_day[num_days].glob_hor_rad[hour - 1][interval - 1] = glo_hor_rad
        state.w_day[num_days].dir_nor_rad[hour - 1][interval - 1] = dir_nor_rad
        state.w_day[num_days].dif_nor_rad[hour - 1][interval - 1] = dif_nor_rad
        state.w_day[num_days].glob_hor_illum[hour - 1][interval - 1] = glo_hor_illum
        state.w_day[num_days].dir_nor_illum[hour - 1][interval - 1] = dir_nor_illum
        state.w_day[num_days].dif_hor_illum[hour - 1][interval - 1] = dif_hor_illum
        state.w_day[num_days].zen_lum[hour - 1][interval - 1] = zenith_lum
        state.w_day[num_days].tot_sky_cvr[hour - 1][interval - 1] = int(tot_sky_cvr)
        state.w_day[num_days].opaq_sky_cvr[hour - 1][interval - 1] = int(opq_sky_cvr)
        state.w_day[num_days].dry_bulb[hour - 1][interval - 1] = dry_bulb
        state.w_day[num_days].dew_point[hour - 1][interval - 1] = dew_point
        state.w_day[num_days].rel_hum[hour - 1][interval - 1] = rel_humid
        state.w_day[num_days].stn_pres[hour - 1][interval - 1] = atm_press
        state.w_day[num_days].wind_dir[hour - 1][interval - 1] = i_wind_dir
        state.w_day[num_days].wind_spd[hour - 1][interval - 1] = wind_spd
        state.w_day[num_days].visibility[hour - 1][interval - 1] = visibility
        state.w_day[num_days].ceiling[hour - 1][interval - 1] = int(ceil_hgt)
        state.w_day[num_days].pres_wth_obs[hour - 1][interval - 1] = int(pres_weath_obs)
        state.w_day[num_days].pres_wth_codes[hour - 1][interval - 1] = pres_weath_codes
        state.w_day[num_days].precip_water[hour - 1][interval - 1] = int(prec_wtr)
        state.w_day[num_days].aer_opt_depth[hour - 1][interval - 1] = aer_opt_depth
        state.w_day[num_days].snow_depth[hour - 1][interval - 1] = int(snow_depth)
        state.w_day[num_days].days_last_snow[hour - 1][interval - 1] = int(days_last_snow)
        satupt_val = dry_sat_pt(dry_bulb)
        pdew = rel_humid / 100.0 * satupt_val
        hum_rat = pdew * 0.62198 / (atm_press - pdew)
        state.w_day[num_days].hum_rat[hour - 1][interval - 1] = hum_rat
        t2 = dry_bulb + 273.15
        if dry_bulb < 0.0:
            pws = math.exp(-5.6745359e+03 / t2 + 6.3925247 - 9.677843e-03 * t2 + 6.2215701e-07 * t2**2 + 2.0747825e-09 * t2**3 - 9.4840240e-13 * t2**4 + 4.1635019 * math.log(t2))
        else:
            pws = math.exp(-5.8002206e+03 / t2 + 1.3914993 - 4.8640239e-02 * t2 + 4.176476e-05 * t2**2 - 1.4452093e-08 * t2**3 + 6.5459673 * math.log(t2))
        wsstar = 0.62198 * (pws / (atm_press - pws))
        state.w_day[num_days].wet_bulb[hour - 1][interval - 1] = ((2501.0 + 1.805 * dry_bulb) * hum_rat - 2501.0 * wsstar + dry_bulb) / (4.186 * hum_rat - 2.381 * wsstar + 1.0)
        if snow_depth > 0:
            state.w_day[num_days].snow_ind[hour - 1][interval - 1] = 1
        else:
            state.w_day[num_days].snow_ind[hour - 1][interval - 1] = 0
        t_dew_k = state.w_day[num_days].dew_point[hour - 1][interval - 1] + T_KELVIN
        t_dry_k = state.w_day[num_days].dry_bulb[hour - 1][interval - 1] + T_KELVIN
        o_sky = state.w_day[num_days].opaq_sky_cvr[hour - 1][interval - 1]
        e_sky = (0.787 + 0.764 * math.log(t_dew_k / T_KELVIN)) * (1.0 + 0.0224 * o_sky - 0.0035 * (o_sky**2) + 0.00028 * (o_sky**3))
        state.w_day[num_days].hor_ir_sky[hour - 1][interval - 1] = e_sky * SIGMA * (t_dry_k**4)
        state.w_day[num_days].data_source_flags[hour - 1][interval - 1] = fld1 + fld2 + fld3 + fld4 + fld_ir + fld5 + fld6 + fld7 + fld8 + fld9 + fld10 + fld11 + fld12 + fld13 + fld14 + fld15 + fld16 + fld17 + fld18 + fld19 + fld20 + fld21
        lenth = len(state.w_day[num_days].data_source_flags[hour - 1][interval - 1].rstrip())
        pos = state.w_day[num_days].data_source_flags[hour - 1][interval - 1][:lenth].find(' ')
        while pos >= 0:
            state.w_day[num_days].data_source_flags[hour - 1][interval - 1] = state.w_day[num_days].data_source_flags[hour - 1][interval - 1][:pos] + '_' + state.w_day[num_days].data_source_flags[hour - 1][interval - 1][pos + 1:]
            pos = state.w_day[num_days].data_source_flags[hour - 1][interval - 1][:lenth].find(' ')
        state.missing.stn_pres = atm_press
        state.missing.dry_bulb = dry_bulb
        state.missing.dew_point = dew_point
        state.missing.wind_spd = wind_spd
        state.missing.wind_dir = int(wind_dir)
        state.missing.tot_sky_cvr = int(tot_sky_cvr)
        state.missing.opaq_sky_cvr = int(opq_sky_cvr)
        state.missing.visibility = visibility
        state.missing.ceiling = int(ceil_hgt)
        state.missing.precip_water = int(prec_wtr)
        state.missing.aer_opt_depth = aer_opt_depth
        state.missing.snow_depth = int(snow_depth)
        state.missing.days_last_snow = int(days_last_snow)
    unit_no.close()
    state.num_days = num_days
    return errors_found, num_days


def get_epw_weather(day: int, hour: int, state: EPWWeatherState) -> Tuple[r64, r64, r64, r64, r64, r64, r64, r64]:
    interval = 1
    beam = state.w_day[day].dir_nor_rad[hour - 1][interval - 1]
    diffuse = state.w_day[day].dif_nor_rad[hour - 1][interval - 1]
    dry_bulb = state.w_day[day].dry_bulb[hour - 1][interval - 1]
    dew_point = state.w_day[day].dew_point[hour - 1][interval - 1]
    rel_humid = state.w_day[day].rel_hum[hour - 1][interval - 1]
    atm_press = state.w_day[day].stn_pres[hour - 1][interval - 1]
    wind_spd = state.w_day[day].wind_spd[hour - 1][interval - 1]
    snow_depth = state.w_day[day].snow_depth[hour - 1][interval - 1]
    return dry_bulb, atm_press, dew_point, rel_humid, wind_spd, beam, diffuse, snow_depth


def get_loc_data(state: EPWWeatherState) -> Tuple[r64, r64, r64]:
    return state.latitude, state.longitude, state.elevation
