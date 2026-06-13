import math
from dataclasses import dataclass, field
from typing import List, Tuple

# EXTERNAL DEPS (to wire in glue):
# - GetNewUnitNumber: needs file handle management (using Python's built-in open)
# - Psat, SATUTP: self-contained weather functions
# - ProcessNumber, FindNonSpace: utility functions
# - ProcessEPWHeader, ProcessEPWHeaders: header parsing (file-based, uses unit numbers mapped to file handles)

A_FORMAT = '(A)'
BLANK_STRING = ' '
MAX_NAME_LENGTH = 60
SIGMA = 5.6697e-8
T_KELVIN = 273.15
PI = 3.141592653589793

@dataclass
class WeatherDataDetails:
    year: int = 0
    month: int = 0
    day: int = 0
    day_of_year: int = 0
    interval_minute: List[int] = field(default_factory=lambda: [0]*60)
    data_source_flags: List[List[str]] = field(default_factory=lambda: [[BLANK_STRING]*60 for _ in range(24)])
    dry_bulb: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    dew_point: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    rel_hum: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    stn_pres: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    x_horz_rad: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    x_dir_norm_rad: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    horz_ir_sky: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    glob_horz_rad: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    dir_norm_rad: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    dif_horz_rad: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    glob_horz_illum: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    dir_norm_illum: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    dif_horz_illum: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    zen_lum: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    wind_dir: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    wind_spd: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    tot_sky_cvr: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    opaq_sky_cvr: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    visibility: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    ceiling: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    pres_wth_obs: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    pres_wth_codes: List[List[str]] = field(default_factory=lambda: [[BLANK_STRING]*60 for _ in range(24)])
    precip_water: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    aer_opt_depth: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    snow_depth: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    days_last_snow: List[List[int]] = field(default_factory=lambda: [[0]*60 for _ in range(24)])
    delta_db_range: bool = False
    delta_chg_db: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])
    delta_dp_range: bool = False
    delta_chg_dp: List[List[float]] = field(default_factory=lambda: [[0.0]*60 for _ in range(24)])

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

@dataclass
class MissingDataCounts:
    x_horz_rad: int = 0
    x_dir_norm_rad: int = 0
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

w_day: List[WeatherDataDetails] = [WeatherDataDetails() for _ in range(366)]
missing: MissingData = MissingData()
missed: MissingDataCounts = MissingDataCounts()

num_data_periods: int = 0
latitude: float = 0.0
longitude: float = 0.0
time_zone: float = 0.0
elevation: float = 0.0
std_baro_press: float = 0.0
stn_wmo: str = ' '
num_intervals_per_hour: int = 0
num_days: int = 0

_unit_map: dict = {}
_next_unit: int = 1

def get_new_unit_number() -> int:
    global _next_unit
    while _next_unit in _unit_map:
        _next_unit += 1
    return _next_unit

def process_number(string: str) -> Tuple[float, bool]:
    valid_numerics = '0123456789.+-EeDd\t'
    ps = string.strip()
    if len(ps) == 0:
        return 0.0, False
    
    error_flag = False
    for c in ps:
        if c not in valid_numerics:
            error_flag = True
            break
    
    if not error_flag:
        try:
            temp = float(ps)
            return temp, False
        except ValueError:
            return 0.0, True
    else:
        return 0.0, True

def find_non_space(string: str) -> int:
    ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0

def psat(t: float) -> float:
    dummy = t + 273.15
    if t < 0.0:
        psat_val = math.exp(-5.6745359e+03/dummy
                           - 5.1523058e-01
                           - 9.6778430e-03 * dummy
                           + 6.2215701e-07 * dummy**2
                           + 2.0747825e-09 * dummy**3
                           - 9.4840240e-13 * dummy**4
                           + 4.1635019 * math.log(dummy))
    else:
        psat_val = math.exp(-5.8002206e+03/dummy
                           - 5.5162560
                           - 4.8640239e-02 * dummy
                           + 4.1764768e-05 * dummy**2
                           - 1.4452093e-08 * dummy**3
                           + 6.5459673 * math.log(dummy))
    return psat_val * 1000.0

def _y3(x: float, a0: float, a1: float, a2: float, a3: float) -> float:
    return a0 + x * (a1 + x * (a2 + x * a3))

def _y5(x: float, a0: float, a1: float, a2: float, a3: float, a4: float, a5: float) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

def _y6(x: float, a0: float, a1: float, a2: float, a3: float, a4: float, a5: float, a6: float) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))

def _y7(x: float, a0: float, a1: float, a2: float, a3: float, a4: float, a5: float, a6: float, a7: float) -> float:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))

def satutp(p: float) -> float:
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    
    pp = p
    
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

def read_epw(input_file: str) -> Tuple[bool, str]:
    global num_days, num_intervals_per_hour, missing, missed, w_day, std_baro_press, elevation, stn_wmo
    
    errors_found = False
    error_message = ''
    
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
    
    for count in range(366):
        w_day[count] = WeatherDataDetails()
    
    num_days = 0
    num_intervals_per_hour = 0
    
    try:
        with open(input_file, 'r') as f:
            unit_no = get_new_unit_number()
            _unit_map[unit_no] = f
    except IOError:
        return True, ' *** Could not open EPW file=' + input_file
    
    num_intervals_per_hour = 1
    
    errors_found, error_message = process_epw_headers(unit_no)
    if errors_found:
        return errors_found, error_message
    
    std_baro_press = (101.325 * (1 - 2.25577e-05 * elevation)**5.2559) * 1000.0
    missing.stn_pres = std_baro_press
    
    num_days = 0
    hour = 24
    interval = num_intervals_per_hour
    
    try:
        f = _unit_map[unit_no]
        for line in f:
            input_line = line.rstrip('\n\r')
            if input_line == BLANK_STRING or len(input_line) == 0:
                break
            
            com5 = [0]*5
            for cnt in range(5):
                com5[cnt] = input_line.find(',')
                if com5[cnt] >= 0:
                    input_line = input_line[:com5[cnt]] + '$' + input_line[com5[cnt]+1:]
            
            comma6 = input_line.find(',')
            if comma6 >= 0 and com5[4] >= 0:
                source_flags = input_line[com5[4]+1:comma6].strip()
                source_flags = source_flags.replace(' ', '_')
                input_line = input_line[:com5[4]+1] + source_flags + input_line[comma6:]
            
            for cnt in range(5):
                if com5[cnt] >= 0:
                    input_line = input_line[:com5[cnt]] + ',' + input_line[com5[cnt]+1:]
            
            parts = input_line.split(',')
            if len(parts) < 35:
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
                ext_horz_rad = float(parts[10])
                ext_dir_norm_rad = float(parts[11])
                ir_horiz = float(parts[12])
                glo_horz_rad = float(parts[13])
                dir_norm_rad = float(parts[14])
                dif_horz_rad = float(parts[15])
                glo_horz_illum = float(parts[16])
                dir_norm_illum = float(parts[17])
                dif_horz_illum = float(parts[18])
                zenith_lum = float(parts[19])
                wind_dir = float(parts[20])
                wind_spd = float(parts[21])
                tot_sky_cvr = float(parts[22])
                opq_sky_cvr = float(parts[23])
                visibility = float(parts[24])
                ceil_hgt = float(parts[25])
                pres_weath_obs = float(parts[26])
                pres_weath_codes = parts[27] if len(parts) > 27 else ''
                prec_wtr = float(parts[28]) if len(parts) > 28 else 0.0
                aer_opt_depth = float(parts[29]) if len(parts) > 29 else 0.0
                snow_depth = float(parts[30]) if len(parts) > 30 else 0.0
                days_last_snow = float(parts[31]) if len(parts) > 31 else 0.0
            except (ValueError, IndexError):
                continue
            
            interval += 1
            if interval > num_intervals_per_hour:
                interval = 1
                hour += 1
            if hour > 24:
                hour = 1
                num_days += 1
            
            if hour == 1:
                w_day[num_days].year = w_year
                w_day[num_days].month = w_month
                w_day[num_days].day = w_day_of_month
            
            w_day[num_days].interval_minute[interval - 1] = round(w_minute)
            
            fld_list = [source_flags[i:i+2] if i+1 < len(source_flags) else source_flags[i:] for i in range(0, len(source_flags), 2)]
            while len(fld_list) < 22:
                fld_list.append('')
            
            if ext_horz_rad >= 9999:
                missed.x_horz_rad += 1
            if ext_dir_norm_rad >= 9999:
                missed.x_dir_norm_rad += 1
            if dir_norm_rad >= 9999:
                missed.dir_norm_rad += 1
            if dif_horz_rad >= 9999:
                missed.dif_horz_rad += 1
            
            if dry_bulb >= 99.9:
                dry_bulb = missing.dry_bulb
                missed.dry_bulb += 1
            
            if atm_press >= 999999.0:
                atm_press = missing.stn_pres
                missed.stn_pres += 1
            
            rel_humid_missing = False
            if rel_humid >= 999.0:
                rel_humid = missing.rel_humid
                missed.rel_humid += 1
                rel_humid_missing = True
            
            if dew_point >= 99.9:
                missed.dew_point += 1
                if rel_humid_missing:
                    dew_point = missing.dew_point
                    if dew_point > dry_bulb:
                        dew_point = dry_bulb - 3.0
                else:
                    pws = psat(dry_bulb)
                    pw = max(rel_humid, 1.0) * 0.01 * pws
                    dew_point = satutp(pw)
            
            if wind_spd >= 999.0:
                wind_spd = missing.wind_spd
                missed.wind_spd += 1
            
            if wind_dir >= 999.0:
                wind_dir = missing.wind_dir
                missed.wind_dir += 1
            
            i_wind_dir = int(wind_dir)
            
            if visibility >= 9999.0:
                visibility = missing.visibility
                missed.visibility += 1
            
            if aer_opt_depth >= 0.999:
                aer_opt_depth = missing.aer_opt_depth
                missed.aer_opt_depth += 1
            
            if tot_sky_cvr == 99.0:
                tot_sky_cvr = missing.tot_sky_cvr
                missed.tot_sky_cvr += 1
            if opq_sky_cvr == 99.0:
                opq_sky_cvr = missing.opaq_sky_cvr
                missed.opaq_sky_cvr += 1
            if ceil_hgt >= 99999.0:
                ceil_hgt = missing.ceiling
                missed.ceiling += 1
            if prec_wtr >= 999:
                prec_wtr = missing.precip_water
                missed.precip_water += 1
            if snow_depth >= 999:
                snow_depth = missing.snow_depth
                missed.snow_depth += 1
            if days_last_snow >= 99:
                days_last_snow = missing.days_last_snow
                missed.days_last_snow += 1
            
            w_day[num_days].x_horz_rad[hour - 1][interval - 1] = ext_horz_rad
            w_day[num_days].x_dir_norm_rad[hour - 1][interval - 1] = ext_dir_norm_rad
            w_day[num_days].glob_horz_rad[hour - 1][interval - 1] = glo_horz_rad
            w_day[num_days].dir_norm_rad[hour - 1][interval - 1] = dir_norm_rad
            w_day[num_days].dif_horz_rad[hour - 1][interval - 1] = dif_horz_rad
            w_day[num_days].glob_horz_illum[hour - 1][interval - 1] = glo_horz_illum
            w_day[num_days].dir_norm_illum[hour - 1][interval - 1] = dir_norm_illum
            w_day[num_days].dif_horz_illum[hour - 1][interval - 1] = dif_horz_illum
            w_day[num_days].zen_lum[hour - 1][interval - 1] = zenith_lum
            w_day[num_days].tot_sky_cvr[hour - 1][interval - 1] = int(tot_sky_cvr)
            w_day[num_days].opaq_sky_cvr[hour - 1][interval - 1] = int(opq_sky_cvr)
            w_day[num_days].dry_bulb[hour - 1][interval - 1] = dry_bulb
            w_day[num_days].dew_point[hour - 1][interval - 1] = dew_point
            w_day[num_days].rel_hum[hour - 1][interval - 1] = rel_humid
            w_day[num_days].stn_pres[hour - 1][interval - 1] = atm_press
            w_day[num_days].wind_dir[hour - 1][interval - 1] = i_wind_dir
            w_day[num_days].wind_spd[hour - 1][interval - 1] = wind_spd
            w_day[num_days].visibility[hour - 1][interval - 1] = visibility
            w_day[num_days].ceiling[hour - 1][interval - 1] = int(ceil_hgt)
            w_day[num_days].pres_wth_obs[hour - 1][interval - 1] = int(pres_weath_obs)
            w_day[num_days].pres_wth_codes[hour - 1][interval - 1] = pres_weath_codes
            w_day[num_days].precip_water[hour - 1][interval - 1] = int(prec_wtr)
            w_day[num_days].aer_opt_depth[hour - 1][interval - 1] = aer_opt_depth
            w_day[num_days].snow_depth[hour - 1][interval - 1] = int(snow_depth)
            w_day[num_days].days_last_snow[hour - 1][interval - 1] = int(days_last_snow)
            
            if ir_horiz <= 0.0 or ir_horiz >= 9999.0:
                t_dew_k = w_day[num_days].dew_point[hour - 1][interval - 1] + T_KELVIN
                t_dry_k = w_day[num_days].dry_bulb[hour - 1][interval - 1] + T_KELVIN
                o_sky = w_day[num_days].opaq_sky_cvr[hour - 1][interval - 1]
                e_sky = (0.787 + 0.764 * math.log(t_dew_k / T_KELVIN)) * (1.0 + 0.0224 * o_sky - 0.0035 * (o_sky**2) + 0.00028 * (o_sky**3))
                w_day[num_days].horz_ir_sky[hour - 1][interval - 1] = e_sky * SIGMA * (t_dry_k**4)
            else:
                w_day[num_days].horz_ir_sky[hour - 1][interval - 1] = ir_horiz
            
            data_source_str = ''.join(fld_list[:22])
            data_source_str = data_source_str.replace(' ', '_').replace(',', '_')
            w_day[num_days].data_source_flags[hour - 1][interval - 1] = data_source_str
            
            missing.stn_pres = atm_press
            missing.dry_bulb = dry_bulb
            missing.dew_point = dew_point
            missing.wind_spd = wind_spd
            missing.wind_dir = wind_dir
            missing.tot_sky_cvr = int(tot_sky_cvr)
            missing.opaq_sky_cvr = int(opq_sky_cvr)
            missing.visibility = visibility
            missing.ceiling = int(ceil_hgt)
            missing.precip_water = int(prec_wtr)
            missing.aer_opt_depth = aer_opt_depth
            missing.snow_depth = int(snow_depth)
            missing.days_last_snow = int(days_last_snow)
        
        del _unit_map[unit_no]
    except Exception as e:
        return True, ' *** Error during processing day #' + str(num_days)
    
    return errors_found, error_message

def process_epw_headers(weather_file_unit_number: int) -> Tuple[bool, str]:
    global num_data_periods, num_intervals_per_hour
    
    headers = ["LOCATION                ", "DESIGN CONDITIONS       ",
               "TYPICAL/EXTREME PERIODS ", "GROUND TEMPERATURES     ",
               "HOLIDAYS/DAYLIGHT SAVING", "COMMENTS 1              ",
               "COMMENTS 2              ", "DATA PERIODS            "]
    
    errors_found = False
    error_message = ''
    
    hd_line = 0
    still_looking = True
    
    try:
        f = _unit_map[weather_file_unit_number]
        while still_looking:
            line = f.readline()
            if not line:
                error_message = 'Unexpected End-of-File on EPW Weather file, while reading header information, looking for header=' + headers[hd_line]
                errors_found = True
                break
            
            line = line.rstrip('\n\r')
            pos = find_non_space(line)
            hd_pos = line.find(headers[hd_line].rstrip())
            
            if pos - 1 == hd_pos or (pos > 0 and line[pos-1:].startswith(headers[hd_line].rstrip())):
                errors_found, error_message = process_epw_header(weather_file_unit_number, headers[hd_line], line)
                if errors_found:
                    return errors_found, error_message
                hd_line += 1
                if hd_line == 8:
                    still_looking = False
    except Exception as e:
        return True, 'Error reading EPW headers'
    
    return errors_found, error_message

def process_epw_header(weather_file_unit_number: int, header_string: str, line: str) -> Tuple[bool, str]:
    global latitude, longitude, time_zone, elevation, stn_wmo, num_data_periods, num_intervals_per_hour
    
    errors_found = False
    error_message = ''
    
    pos = line.find(',')
    if pos >= 0:
        line = line[pos + 1:]
    
    header_str = header_string.strip()
    
    if header_str == 'LOCATION':
        num_hd_args = 9
        count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos < 0:
                if len(line.strip()) == 0:
                    try:
                        f = _unit_map[weather_file_unit_number]
                        while pos < 0:
                            line = f.readline().rstrip('\n\r')
                            line = line.lstrip()
                            pos = line.find(',')
                    except:
                        pass
                else:
                    pos = len(line.rstrip())
            
            if count == 1:
                title = line[:pos]
            elif count in [2, 3, 4]:
                title = title + ' ' + line[:pos]
            elif count == 5:
                stn_wmo = line[:pos]
            elif count in [6, 7, 8, 9]:
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
                    error_message = 'GetEPWHeader:LOCATION, invalid numeric=' + line[:pos]
                    errors_found = True
                    return errors_found, error_message
            
            line = line[pos + 1:] if pos + 1 < len(line) else ''
            count += 1
    
    elif header_str == 'DATA PERIODS':
        num_hd_args = 2
        count = 1
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos < 0:
                if len(line.strip()) == 0:
                    try:
                        f = _unit_map[weather_file_unit_number]
                        while pos < 0:
                            line = f.readline().rstrip('\n\r')
                            line = line.lstrip()
                            pos = line.find(',')
                    except:
                        pass
                else:
                    pos = len(line.rstrip())
            
            if count == 1:
                num_data_periods, _ = process_number(line[:pos])
            elif count == 2:
                num_intervals_per_hour, _ = process_number(line[:pos])
            
            line = line[pos + 1:] if pos + 1 < len(line) else ''
            count += 1
    
    return errors_found, error_message
