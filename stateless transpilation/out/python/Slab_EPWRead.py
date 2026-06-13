"""
EPWRead module translation from Fortran.
Complete translation of EnergyPlus EPW file reading functionality.
"""

from dataclasses import dataclass, field
from typing import List, Tuple, Optional
import math
import sys

# EXTERNAL DEPS (to wire in glue):
# - EPWPrecisionGlobals: provides r64 (double precision float alias)

r64 = float

A_FORMAT = '(A)'
BLANK_STRING = ' '
MAX_NAME_LENGTH = 60
SIGMA = 5.6697e-8
T_KELVIN = 273.15
PI = 3.141592653589793

VALID_DIGITS = "0123456789"
END_OF_RECORD = -2
END_OF_FILE = -1
DEFAULT_INPUT_UNIT = 5
DEFAULT_OUTPUT_UNIT = 6
NUMBER_OF_PRECONNECTED_UNITS = 2
PRECONNECTED_UNITS = [5, 6]
MAX_UNIT_NUMBER = 1000


@dataclass
class WeatherDataDetails:
    year: int = 0
    month: int = 0
    day: int = 0
    day_of_year: int = 0
    interval_minute: List[int] = field(default_factory=lambda: [0] * 60)
    data_source_flags: List[List[str]] = field(
        default_factory=lambda: [[' ' * 50 for _ in range(60)] for _ in range(24)]
    )
    dry_bulb: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    dew_point: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    rel_hum: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    stn_pres: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    x_horz_rad: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    x_dir_norm_rad: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    horz_ir_sky: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    glob_horz_rad: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    dir_norm_rad: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    dif_horz_rad: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    glob_horz_illum: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    dir_norm_illum: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    dif_horz_illum: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    zen_lum: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    wind_dir: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    wind_spd: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    tot_sky_cvr: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    opaq_sky_cvr: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    visibility: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    ceiling: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    pres_wth_obs: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    pres_wth_codes: List[List[str]] = field(
        default_factory=lambda: [[' ' * 9 for _ in range(60)] for _ in range(24)]
    )
    precip_water: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    aer_opt_depth: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    snow_depth: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    days_last_snow: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    albedo: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    liquid_precip_depth: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    liquid_precip_rate: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    snow_ind: List[List[int]] = field(
        default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)]
    )
    hum_rat: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    wet_bulb: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    delta_db_range: bool = False
    delta_chg_db: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )
    delta_dp_range: bool = False
    delta_chg_dp: List[List[float]] = field(
        default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)]
    )


@dataclass
class MissingData:
    dry_bulb: float = 0.0
    dew_point: float = 0.0
    rel_humid: int = 0
    stn_pres: float = 0.0
    wind_dir: int = 0
    wind_spd: float = 0.0
    tot_sky_cvr: int = 0
    opaq_sky_cvr: int = 0
    visibility: float = 0.0
    ceiling: int = 0
    precip_water: int = 0
    aer_opt_depth: float = 0.0
    snow_depth: int = 0
    days_last_snow: int = 0
    albedo: float = 0.0
    liquid_precip: float = 0.0


@dataclass
class MissingDataCounts:
    x_horz_rad: int = 0
    x_dir_norm_rad: int = 0
    glo_hor_rad: int = 0
    dir_norm_rad: int = 0
    dif_horz_rad: int = 0
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
    albedo: int = 0
    liquid_precip: int = 0


w_day: List[WeatherDataDetails] = [WeatherDataDetails() for _ in range(366)]
missing: MissingData = MissingData()
missed: MissingDataCounts = MissingDataCounts()
location_name: str = ' ' * (MAX_NAME_LENGTH * 2)
num_data_periods: int = 0
latitude: float = 0.0
longitude: float = 0.0
time_zone: float = 0.0
elevation: float = 0.0
std_baro_press: float = 0.0
stn_wmo: str = ' ' * 10
num_intervals_per_hour: int = 0
num_days: int = 0

_next_unit_number = 10


def get_new_unit_number() -> int:
    global _next_unit_number
    for unit_no in range(1, MAX_UNIT_NUMBER + 1):
        if unit_no == DEFAULT_INPUT_UNIT or unit_no == DEFAULT_OUTPUT_UNIT:
            continue
        if unit_no in PRECONNECTED_UNITS:
            continue
        try:
            with open(f'/dev/null', 'r'):
                pass
            _next_unit_number = unit_no + 1
            return unit_no
        except:
            continue
    _next_unit_number += 1
    return _next_unit_number - 1


def find_non_space(string: str) -> int:
    i_len = len(string.rstrip())
    for i in range(i_len):
        if string[i] != ' ':
            return i + 1
    return 0


def process_number(string: str) -> Tuple[float, bool]:
    valid_numerics = '0123456789.+-EeDd\t'
    pstring = string.strip()
    string_len = len(pstring)
    error_flag = False
    
    if string_len == 0:
        return 0.0, False
    
    for char in pstring:
        if char not in valid_numerics:
            return 0.0, True
    
    try:
        temp = float(pstring)
        return temp, False
    except ValueError:
        return 0.0, True


def psat(t: float) -> float:
    dummy = t + 273.15
    if t < 0.0:
        psat_val = math.exp(
            -5.6745359e3 / dummy
            - 5.1523058e-1
            - 9.6778430e-3 * dummy
            + 6.2215701e-7 * dummy ** 2
            + 2.0747825e-9 * dummy ** 3
            - 9.4840240e-13 * dummy ** 4
            + 4.1635019 * math.log(dummy)
        )
    else:
        psat_val = math.exp(
            -5.8002206e3 / dummy
            - 5.5162560
            - 4.8640239e-2 * dummy
            + 4.1764768e-5 * dummy ** 2
            - 1.4452093e-8 * dummy ** 3
            + 6.5459673 * math.log(dummy)
        )
    return psat_val * 1000.0


def y3(x: float, a0: float, a1: float, a2: float, a3: float) -> float:
    return a0 + x * (a1 + x * (a2 + x * a3))


def y5(
    x: float, a0: float, a1: float, a2: float, a3: float, a4: float, a5: float
) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))


def y6(
    x: float,
    a0: float,
    a1: float,
    a2: float,
    a3: float,
    a4: float,
    a5: float,
    a6: float,
) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))


def y7(
    x: float,
    a0: float,
    a1: float,
    a2: float,
    a3: float,
    a4: float,
    a5: float,
    a6: float,
    a7: float,
) -> float:
    return a0 + x * (
        a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7)))))
    )


def satutp(p: float) -> float:
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    
    pp = p
    
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


def dry_sat_pt(tdb: float) -> float:
    tt = tdb
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


def y4(
    x: float, a0: float, a1: float, a2: float, a3: float, a4: float
) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))


def get_stm(longitude: float) -> float:
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
    
    return -999.0


def process_epw_headers(
    weather_file_unit_number: int, error_message_holder: dict
) -> bool:
    headers = [
        "LOCATION                ",
        "DESIGN CONDITIONS       ",
        "TYPICAL/EXTREME PERIODS ",
        "GROUND TEMPERATURES     ",
        "HOLIDAYS/DAYLIGHT SAVING",
        "COMMENTS 1              ",
        "COMMENTS 2              ",
        "DATA PERIODS            ",
    ]
    
    hd_line = 0
    still_looking = True
    
    try:
        with open(_file_handle, 'r') as f:
            _lines = f.readlines()
            _line_idx = 0
            
            while still_looking and _line_idx < len(_lines):
                line = _lines[_line_idx]
                _line_idx += 1
                pos = find_non_space(line)
                hd_pos = line.find(headers[hd_line].strip())
                if pos - 1 != hd_pos:
                    continue
                process_epw_header(
                    weather_file_unit_number, headers[hd_line], line, error_message_holder
                )
                if error_message_holder.get('error_found', False):
                    return False
                hd_line += 1
                if hd_line == 8:
                    still_looking = False
        return True
    except:
        error_message_holder['message'] = (
            'Unexpected End-of-File on EPW Weather file, while reading header '
            f'information, looking for header={headers[hd_line]}'
        )
        error_message_holder['error_found'] = True
        return False


def process_epw_header(
    weather_file_unit_number: int,
    header_string: str,
    line: str,
    error_message_holder: dict,
) -> None:
    global location_name, stn_wmo, latitude, longitude, time_zone, elevation, num_data_periods, num_intervals_per_hour
    
    pos = line.find(',')
    line = line[pos + 1:]
    
    if header_string.strip() == "LOCATION":
        num_hd_args = 9
        count = 1
        title = ""
        
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos == -1:
                if len(line.strip()) == 0:
                    pos = -1
                else:
                    pos = len(line.rstrip())
            
            if count == 1:
                title = line[:pos]
            elif count in [2, 3, 4]:
                title = title + ' ' + line[:pos]
            elif count in [5, 6, 7, 8, 9]:
                if count == 5:
                    stn_wmo = line[:pos]
                else:
                    number, err_flag = process_number(line[:pos])
                    if not err_flag:
                        if count == 6:
                            latitude = number
                        elif count == 7:
                            longitude = number
                        elif count == 8:
                            time_zone = number
                        elif count == 9:
                            elevation = number
                    else:
                        error_message_holder['message'] = (
                            f'GetEPWHeader:LOCATION, invalid numeric={line[:pos]}'
                        )
                        error_message_holder['error_found'] = True
                        return
            
            line = line[pos + 1:] if pos < len(line) else ""
            count += 1
        
        location_name = title.strip()
    
    elif header_string.strip() == "DESIGN CONDITIONS":
        pass
    
    elif header_string.strip() == "TYPICAL/EXTREME PERIODS":
        pass
    
    elif header_string.strip() == "GROUND TEMPERATURES":
        pass
    
    elif header_string.strip() == "HOLIDAYS/DAYLIGHT SAVING":
        pass
    
    elif header_string.strip() == "COMMENTS 1":
        pass
    
    elif header_string.strip() == "COMMENTS 2":
        pass
    
    elif header_string.strip() == "DATA PERIODS":
        num_hd_args = 2
        count = 1
        
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos == -1:
                if len(line.strip()) == 0:
                    pos = -1
                else:
                    pos = len(line.rstrip())
            
            if count == 1:
                number, _ = process_number(line[:pos])
                num_data_periods = int(number)
            elif count == 2:
                number, _ = process_number(line[:pos])
                num_intervals_per_hour = int(number)
            
            line = line[pos + 1:] if pos < len(line) else ""
            count += 1


_file_handle = None


def read_and_interpret_epw_weather_line(
    input_line: str,
) -> Tuple[
    int,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    int,
    str,
    float,
    float,
    float,
    float,
    float,
    float,
]:
    fields = [''] * 29
    
    for count in range(25):
        pos = input_line.find(',')
        if pos == -1:
            fields[count] = input_line
            input_line = ""
            break
        fields[count] = input_line[:pos]
        input_line = input_line[pos + 1:]
    
    pos = input_line.find(',')
    if pos == -1:
        fields[25] = input_line
    else:
        fields[25] = input_line[:pos]
        input_line = input_line[pos + 1:]
        pos = input_line.find(',')
        if pos == -1:
            fields[26] = input_line
        else:
            fields[26] = input_line[:pos]
            input_line = input_line[pos + 1:]
            pos = input_line.find(',')
            if pos == -1:
                fields[27] = input_line
            else:
                fields[27] = input_line[:pos]
                input_line = input_line[pos + 1:]
                fields[28] = input_line
    
    ios = 0
    
    dry_bulb = 0.0
    if fields[0] != BLANK_STRING:
        try:
            dry_bulb = float(fields[0])
        except ValueError:
            ios = 2
    else:
        dry_bulb = 999.0
    
    dew_point = 0.0
    if fields[1] != BLANK_STRING:
        try:
            dew_point = float(fields[1])
        except ValueError:
            ios = 2
    else:
        dew_point = 999.0
    
    rel_hum = 0.0
    if fields[2] != BLANK_STRING:
        try:
            rel_hum = float(fields[2])
        except ValueError:
            ios = 3
    else:
        rel_hum = 999.0
    
    atm_press = 0.0
    if fields[3] != BLANK_STRING:
        try:
            atm_press = float(fields[3])
        except ValueError:
            ios = 4
    else:
        atm_press = 999999.0
    
    ext_horz_rad = 0.0
    if fields[4] != BLANK_STRING:
        try:
            ext_horz_rad = float(fields[4])
        except ValueError:
            ios = 1
    else:
        ext_horz_rad = 9999.0
    
    ext_dir_norm_rad = 0.0
    if fields[5] != BLANK_STRING:
        try:
            ext_dir_norm_rad = float(fields[5])
        except ValueError:
            ios = 1
    else:
        ext_dir_norm_rad = 9999.0
    
    ir_horiz = 0.0
    if fields[6] != BLANK_STRING:
        try:
            ir_horiz = float(fields[6])
        except ValueError:
            ios = 7
    else:
        ir_horiz = 9999.0
    
    glo_horz_rad = 0.0
    if fields[7] != BLANK_STRING:
        try:
            glo_horz_rad = float(fields[7])
        except ValueError:
            ios = 1
    else:
        glo_horz_rad = 9999.0
    
    dir_norm_rad = 0.0
    if fields[8] != BLANK_STRING:
        try:
            dir_norm_rad = float(fields[8])
        except ValueError:
            ios = 9
    else:
        dir_norm_rad = 9999.0
    
    dif_horz_rad = 0.0
    if fields[9] != BLANK_STRING:
        try:
            dif_horz_rad = float(fields[9])
        except ValueError:
            ios = 10
    else:
        dif_horz_rad = 9999.0
    
    glo_horz_illum = 0.0
    if fields[10] != BLANK_STRING:
        try:
            glo_horz_illum = float(fields[10])
        except ValueError:
            ios = 1
    else:
        glo_horz_illum = 999999.0
    
    dir_norm_illum = 0.0
    if fields[11] != BLANK_STRING:
        try:
            dir_norm_illum = float(fields[11])
        except ValueError:
            ios = 1
    else:
        dir_norm_illum = 999999.0
    
    dif_horz_illum = 0.0
    if fields[12] != BLANK_STRING:
        try:
            dif_horz_illum = float(fields[12])
        except ValueError:
            ios = 1
    else:
        dif_horz_illum = 999999.0
    
    zenith_lum = 0.0
    if fields[13] != BLANK_STRING:
        try:
            zenith_lum = float(fields[13])
        except ValueError:
            ios = 1
    else:
        zenith_lum = 99999.0
    
    wind_dir = 0.0
    if fields[14] != BLANK_STRING:
        try:
            wind_dir = float(fields[14])
        except ValueError:
            ios = 15
    else:
        wind_dir = 999.0
    
    wind_spd = 0.0
    if fields[15] != BLANK_STRING:
        try:
            wind_spd = float(fields[15])
        except ValueError:
            ios = 16
    else:
        wind_spd = 999.0
    
    tot_sky_cvr = 0.0
    if fields[16] != BLANK_STRING:
        try:
            tot_sky_cvr = float(fields[16])
        except ValueError:
            ios = 17
    else:
        tot_sky_cvr = 99.0
    
    opq_sky_cvr = 0.0
    if fields[17] != BLANK_STRING:
        try:
            opq_sky_cvr = float(fields[17])
        except ValueError:
            ios = 18
    else:
        opq_sky_cvr = 99.0
    
    visibility = 0.0
    if fields[18] != BLANK_STRING:
        try:
            visibility = float(fields[18])
        except ValueError:
            ios = 1
    else:
        visibility = 9999.0
    
    ceil_hgt = 0.0
    if fields[19] != BLANK_STRING:
        try:
            ceil_hgt = float(fields[19])
        except ValueError:
            ios = 1
    else:
        ceil_hgt = 99999.0
    
    pres_weath_obs = 0
    if fields[20] != BLANK_STRING:
        try:
            pres_weath_obs = int(float(fields[20]))
        except ValueError:
            ios = 21
    else:
        pres_weath_obs = 9
    
    pres_weath_codes = '999999999'
    if fields[21] != BLANK_STRING:
        pres_weath_codes = fields[21]
    
    prec_wtr = 0.0
    if fields[22] != BLANK_STRING:
        try:
            prec_wtr = float(fields[22])
        except ValueError:
            ios = 23
    else:
        prec_wtr = 999.0
    
    aer_opt_depth = 0.0
    if fields[23] != BLANK_STRING:
        try:
            aer_opt_depth = float(fields[23])
        except ValueError:
            ios = 1
    else:
        aer_opt_depth = 0.999
    
    snow_depth = 0.0
    if fields[24] != BLANK_STRING:
        try:
            snow_depth = float(fields[24])
        except ValueError:
            ios = 25
    else:
        snow_depth = 999.0
    
    days_last_snow = 0.0
    if len(fields) > 25 and fields[25] != BLANK_STRING:
        try:
            days_last_snow = float(fields[25])
        except ValueError:
            ios = 1
    else:
        days_last_snow = 99.0
    
    albedo = 0.1
    if len(fields) > 26 and fields[26] != BLANK_STRING:
        try:
            albedo = float(fields[26])
        except ValueError:
            ios = 1
    
    rain = 0.0
    if len(fields) > 27 and fields[27] != BLANK_STRING:
        try:
            rain = float(fields[27])
        except ValueError:
            ios = 28
    
    rain_rate = 1.0
    if len(fields) > 28 and fields[28] != BLANK_STRING:
        try:
            rain_rate = float(fields[28])
        except ValueError:
            ios = 1
    
    return (
        ios,
        dry_bulb,
        dew_point,
        rel_hum,
        atm_press,
        ext_horz_rad,
        ext_dir_norm_rad,
        ir_horiz,
        glo_horz_rad,
        dir_norm_rad,
        dif_horz_rad,
        glo_horz_illum,
        dir_norm_illum,
        dif_horz_illum,
        zenith_lum,
        wind_dir,
        wind_spd,
        tot_sky_cvr,
        opq_sky_cvr,
        visibility,
        ceil_hgt,
        pres_weath_obs,
        pres_weath_codes,
        prec_wtr,
        aer_opt_depth,
        snow_depth,
        days_last_snow,
        albedo,
        rain,
        rain_rate,
    )


def read_epw(
    input_file: str, error_message_holder: dict
) -> int:
    global w_day, missing, missed, num_days, num_intervals_per_hour, std_baro_press, _file_handle
    
    _file_handle = input_file
    
    errors_found = False
    error_message_holder['message'] = ''
    
    missing.stn_pres = 101325.0
    missing.dry_bulb = 6.0
    missing.dew_point = 3.0
    missing.rel_humid = 50
    missing.wind_spd = 2.5
    missing.wind_dir = 180
    missing.tot_sky_cvr = 5
    missing.opaq_sky_cvr = 5
    missing.visibility = 777.7
    missing.ceiling = 77777
    missing.precip_water = 0
    missing.aer_opt_depth = 0.0
    missing.snow_depth = 0
    missing.days_last_snow = 88
    missing.albedo = 0.0
    missing.liquid_precip = 0.0
    
    missed.x_horz_rad = 0
    missed.x_dir_norm_rad = 0
    missed.glo_hor_rad = 0
    missed.dir_norm_rad = 0
    missed.dif_horz_rad = 0
    missed.stn_pres = 0
    missed.dry_bulb = 0
    missed.dew_point = 0
    missed.rel_humid = 0
    missed.wind_spd = 0
    missed.wind_dir = 0
    missed.tot_sky_cvr = 0
    missed.opaq_sky_cvr = 0
    missed.visibility = 0
    missed.ceiling = 0
    missed.precip_water = 0
    missed.aer_opt_depth = 0
    missed.snow_depth = 0
    missed.days_last_snow = 0
    missed.albedo = 0
    missed.liquid_precip = 0
    
    for count in range(366):
        w_day[count] = WeatherDataDetails()
    
    try:
        with open(input_file, 'r') as f:
            pass
    except FileNotFoundError:
        error_message_holder['message'] = (
            f' *** Could not open EPW file={input_file}'
        )
        errors_found = True
        return 0
    
    num_intervals_per_hour = 1
    
    if not process_epw_headers(10, error_message_holder):
        return 0
    
    std_baro_press = (101.325 * (1.0 - 2.25577e-5 * elevation) ** 5.2559) * 1000.0
    missing.stn_pres = std_baro_press
    
    num_days = 0
    hour = 24
    interval = num_intervals_per_hour
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
            
            for line in lines:
                input_line = line.rstrip('\n')
                if not input_line:
                    break
                
                com5 = [0, 0, 0, 0, 0]
                for count in range(5):
                    pos = input_line.find(',')
                    if pos != -1:
                        com5[count] = pos
                        input_line = (
                            input_line[:pos] + '$' + input_line[pos + 1:]
                        )
                
                comma6 = input_line.find(',')
                if comma6 != -1:
                    source_flags = input_line[com5[4] + 1 : comma6].strip()
                else:
                    source_flags = input_line[com5[4] + 1 :].strip()
                
                source_flags = source_flags.replace(' ', '_')
                if comma6 != -1:
                    input_line = (
                        input_line[:com5[4] + 1]
                        + source_flags
                        + input_line[comma6:]
                    )
                else:
                    input_line = input_line[:com5[4] + 1] + source_flags
                
                for count in range(5):
                    input_line = input_line.replace('$', ',', 1)
                
                parts = input_line.split(',')
                if len(parts) < 6:
                    break
                
                try:
                    w_year = int(parts[0])
                    w_month = int(parts[1])
                    w_day_of_month = int(parts[2])
                    w_hour = int(parts[3])
                    w_minute = float(parts[4])
                    source_flags = parts[5]
                except (ValueError, IndexError):
                    break
                
                input_line = ','.join(parts[6:])
                
                (
                    ios,
                    dry_bulb,
                    dew_point,
                    rel_humid,
                    atm_press,
                    ext_horz_rad,
                    ext_dir_norm_rad,
                    ir_horiz,
                    glo_horz_rad,
                    dir_norm_rad,
                    dif_horz_rad,
                    glo_horz_illum,
                    dir_norm_illum,
                    dif_horz_illum,
                    zenith_lum,
                    wind_dir,
                    wind_spd,
                    tot_sky_cvr,
                    opq_sky_cvr,
                    visibility,
                    ceil_hgt,
                    pres_weath_obs,
                    pres_weath_codes,
                    prec_wtr,
                    aer_opt_depth,
                    snow_depth,
                    days_last_snow,
                    albedo,
                    rain,
                    rain_rate,
                ) = read_and_interpret_epw_weather_line(input_line)
                
                pres_weath_codes = pres_weath_codes.replace("'", ' ')
                pres_weath_codes = pres_weath_codes.replace('"', ' ')
                pres_weath_codes = pres_weath_codes.lstrip()
                
                if len(pres_weath_codes) == 9:
                    pres_codes_list = list(pres_weath_codes)
                    for pos in range(9):
                        if VALID_DIGITS.find(pres_codes_list[pos]) == -1:
                            pres_codes_list[pos] = '9'
                    pres_weath_codes = ''.join(pres_codes_list)
                
                interval += 1
                if interval > num_intervals_per_hour:
                    interval = 1
                    hour += 1
                
                if hour > 24:
                    hour = 1
                    num_days += 1
                
                if hour == 1:
                    w_day[num_days - 1].year = w_year
                    w_day[num_days - 1].month = w_month
                    w_day[num_days - 1].day = w_day_of_month
                
                w_day[num_days - 1].interval_minute[interval - 1] = round(w_minute)
                
                flds = []
                for i in range(0, min(50, len(source_flags)), 2):
                    flds.append(source_flags[i : i + 2])
                while len(flds) < 25:
                    flds.append('')
                
                if ext_horz_rad >= 9999:
                    missed.x_horz_rad += 1
                if ext_dir_norm_rad >= 9999:
                    missed.x_dir_norm_rad += 1
                if glo_horz_rad >= 9999:
                    missed.glo_hor_rad += 1
                if dir_norm_rad >= 9999:
                    missed.dir_norm_rad += 1
                if dif_horz_rad >= 9999:
                    missed.dif_horz_rad += 1
                
                if dry_bulb >= 99.9:
                    dry_bulb = missing.dry_bulb
                    if len(flds) > 9:
                        flds[9] = '*'
                    missed.dry_bulb += 1
                
                if atm_press >= 999999.0:
                    atm_press = missing.stn_pres
                    if len(flds) > 12:
                        flds[12] = '*'
                    missed.stn_pres += 1
                
                rel_humid_missing = False
                if rel_humid >= 999.0:
                    rel_humid = missing.rel_humid
                    if len(flds) > 11:
                        flds[11] = '*'
                    missed.rel_humid += 1
                    rel_humid_missing = True
                
                if dew_point >= 99.9:
                    missed.dew_point += 1
                    if rel_humid_missing:
                        dew_point = missing.dew_point
                        if len(flds) > 10:
                            flds[10] = '*'
                        if dew_point > dry_bulb:
                            dew_point = dry_bulb - 3.0
                    else:
                        pws = psat(dry_bulb)
                        pw = max(rel_humid, 1.0) * 0.01 * pws
                        dew_point = satutp(pw)
                        if len(flds) > 10:
                            flds[10] = '*'
                
                if wind_spd >= 999.0:
                    wind_spd = missing.wind_spd
                    if len(flds) > 14:
                        flds[14] = '*'
                    missed.wind_spd += 1
                
                if wind_dir >= 999.0:
                    wind_dir = missing.wind_dir
                    if len(flds) > 13:
                        flds[13] = '*'
                    missed.wind_dir += 1
                
                i_wind_dir = int(wind_dir)
                
                if visibility >= 9999.0:
                    visibility = missing.visibility
                    if len(flds) > 15:
                        flds[15] = '*'
                    missed.visibility += 1
                
                if aer_opt_depth >= 0.999:
                    aer_opt_depth = missing.aer_opt_depth
                    if len(flds) > 18:
                        flds[18] = '*'
                    missed.aer_opt_depth += 1
                
                if tot_sky_cvr == 99.0:
                    tot_sky_cvr = missing.tot_sky_cvr
                    if len(flds) > 7:
                        flds[7] = '*'
                    missed.tot_sky_cvr += 1
                
                if opq_sky_cvr == 99.0:
                    opq_sky_cvr = missing.opaq_sky_cvr
                    if len(flds) > 8:
                        flds[8] = '*'
                    missed.opaq_sky_cvr += 1
                
                if ceil_hgt >= 99999.0:
                    ceil_hgt = missing.ceiling
                    if len(flds) > 16:
                        flds[16] = '*'
                    missed.ceiling += 1
                
                if prec_wtr >= 999:
                    prec_wtr = missing.precip_water
                    if len(flds) > 17:
                        flds[17] = '*'
                    missed.precip_water += 1
                
                if snow_depth >= 999:
                    snow_depth = missing.snow_depth
                    if len(flds) > 19:
                        flds[19] = '*'
                    missed.snow_depth += 1
                
                if days_last_snow >= 99:
                    days_last_snow = missing.days_last_snow
                    if len(flds) > 20:
                        flds[20] = '*'
                    missed.days_last_snow += 1
                
                if albedo >= 999.0:
                    albedo = 0.0
                    if len(flds) > 21:
                        flds[21] = '*'
                    missed.albedo += 1
                
                if rain >= 999.0:
                    rain = 0.0
                    if len(flds) > 22:
                        flds[22] = '*'
                    missed.liquid_precip += 1
                
                if rain_rate >= 99.0:
                    rain_rate = 99.0
                    if len(flds) > 23:
                        flds[23] = '*'
                
                w_day[num_days - 1].x_horz_rad[hour - 1][interval - 1] = ext_horz_rad
                w_day[num_days - 1].x_dir_norm_rad[hour - 1][interval - 1] = (
                    ext_dir_norm_rad
                )
                w_day[num_days - 1].glob_horz_rad[hour - 1][interval - 1] = (
                    glo_horz_rad
                )
                w_day[num_days - 1].dir_norm_rad[hour - 1][interval - 1] = (
                    dir_norm_rad
                )
                w_day[num_days - 1].dif_horz_rad[hour - 1][interval - 1] = (
                    dif_horz_rad
                )
                w_day[num_days - 1].glob_horz_illum[hour - 1][interval - 1] = (
                    glo_horz_illum
                )
                w_day[num_days - 1].dir_norm_illum[hour - 1][interval - 1] = (
                    dir_norm_illum
                )
                w_day[num_days - 1].dif_horz_illum[hour - 1][interval - 1] = (
                    dif_horz_illum
                )
                w_day[num_days - 1].zen_lum[hour - 1][interval - 1] = zenith_lum
                w_day[num_days - 1].tot_sky_cvr[hour - 1][interval - 1] = int(
                    tot_sky_cvr
                )
                w_day[num_days - 1].opaq_sky_cvr[hour - 1][interval - 1] = int(
                    opq_sky_cvr
                )
                w_day[num_days - 1].dry_bulb[hour - 1][interval - 1] = dry_bulb
                w_day[num_days - 1].dew_point[hour - 1][interval - 1] = dew_point
                w_day[num_days - 1].rel_hum[hour - 1][interval - 1] = rel_humid
                w_day[num_days - 1].stn_pres[hour - 1][interval - 1] = atm_press
                w_day[num_days - 1].wind_dir[hour - 1][interval - 1] = i_wind_dir
                w_day[num_days - 1].wind_spd[hour - 1][interval - 1] = wind_spd
                w_day[num_days - 1].visibility[hour - 1][interval - 1] = visibility
                w_day[num_days - 1].ceiling[hour - 1][interval - 1] = int(ceil_hgt)
                w_day[num_days - 1].pres_wth_obs[hour - 1][interval - 1] = (
                    pres_weath_obs
                )
                w_day[num_days - 1].pres_wth_codes[hour - 1][interval - 1] = (
                    pres_weath_codes
                )
                w_day[num_days - 1].precip_water[hour - 1][interval - 1] = int(
                    prec_wtr
                )
                w_day[num_days - 1].aer_opt_depth[hour - 1][interval - 1] = (
                    aer_opt_depth
                )
                w_day[num_days - 1].snow_depth[hour - 1][interval - 1] = int(
                    snow_depth
                )
                w_day[num_days - 1].days_last_snow[hour - 1][interval - 1] = int(
                    days_last_snow
                )
                w_day[num_days - 1].albedo[hour - 1][interval - 1] = days_last_snow
                w_day[num_days - 1].liquid_precip_depth[hour - 1][interval - 1] = (
                    rain
                )
                w_day[num_days - 1].liquid_precip_rate[hour - 1][interval - 1] = (
                    rain_rate
                )
                
                sat_upt = dry_sat_pt(dry_bulb)
                pdew = rel_humid / 100.0 * sat_upt
                hum_rat = pdew * 0.62198 / (atm_press - pdew)
                w_day[num_days - 1].hum_rat[hour - 1][interval - 1] = hum_rat
                
                t2 = dry_bulb + 273.15
                if dry_bulb < 0.0:
                    pws = math.exp(
                        -5.6745359e3 / t2
                        + 6.3925247
                        - 9.677843e-3 * t2
                        + 6.2215701e-7 * t2 ** 2
                        + 2.0747825e-9 * t2 ** 3
                        - 9.4840240e-13 * t2 ** 4
                        + 4.1635019 * math.log(t2)
                    )
                else:
                    pws = math.exp(
                        -5.8002206e3 / t2
                        + 1.3914993
                        - 4.8640239e-2 * t2
                        + 4.176476e-5 * t2 ** 2
                        - 1.4452093e-8 * t2 ** 3
                        + 6.5459673 * math.log(t2)
                    )
                
                wsstar = 0.62198 * (pws / (atm_press - pws))
                w_day[num_days - 1].wet_bulb[hour - 1][interval - 1] = (
                    (2501.0 + 1.805 * dry_bulb) * hum_rat
                    - 2501.0 * wsstar
                    + dry_bulb
                ) / (4.186 * hum_rat - 2.381 * wsstar + 1.0)
                
                if snow_depth > 0:
                    w_day[num_days - 1].snow_ind[hour - 1][interval - 1] = 1
                else:
                    w_day[num_days - 1].snow_ind[hour - 1][interval - 1] = 0
                
                if ir_horiz <= 0.0 or ir_horiz >= 9999.0:
                    t_dew_k = w_day[num_days - 1].dew_point[hour - 1][interval - 1] + T_KELVIN
                    t_dry_k = (
                        w_day[num_days - 1].dry_bulb[hour - 1][interval - 1]
                        + T_KELVIN
                    )
                    o_sky = w_day[num_days - 1].opaq_sky_cvr[hour - 1][interval - 1]
                    
                    e_sky = (0.787 + 0.764 * math.log(t_dew_k / T_KELVIN)) * (
                        1.0
                        + 0.0224 * o_sky
                        - 0.0035 * (o_sky ** 2)
                        + 0.00028 * (o_sky ** 3)
                    )
                    
                    w_day[num_days - 1].horz_ir_sky[hour - 1][interval - 1] = (
                        e_sky * SIGMA * (t_dry_k ** 4)
                    )
                else:
                    w_day[num_days - 1].horz_ir_sky[hour - 1][interval - 1] = ir_horiz
                
                data_source = ''.join(flds[:21])
                data_source = data_source.replace(' ', '_')
                data_source = data_source.replace(',', '_')
                w_day[num_days - 1].data_source_flags[hour - 1][interval - 1] = (
                    data_source
                )
                
                missing.stn_pres = atm_press
                missing.dry_bulb = dry_bulb
                missing.dew_point = dew_point
                missing.wind_spd = wind_spd
                missing.wind_dir = wind_dir
                missing.tot_sky_cvr = tot_sky_cvr
                missing.opaq_sky_cvr = opq_sky_cvr
                missing.visibility = visibility
                missing.ceiling = ceil_hgt
                missing.precip_water = prec_wtr
                missing.aer_opt_depth = aer_opt_depth
                missing.snow_depth = snow_depth
                missing.days_last_snow = days_last_snow
    
    except Exception:
        error_message_holder['message'] = (
            f' *** Line in error ** Error during processing day #{num_days}'
        )
        return 0
    
    return num_days


def get_loc_data() -> Tuple[float, float, float]:
    return latitude, longitude, elevation
