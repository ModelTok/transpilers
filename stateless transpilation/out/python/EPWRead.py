# EXTERNAL DEPS (to wire in glue):
# - EPWPrecisionGlobals: r64 type (float64)

from typing import List, Optional, Tuple
from dataclasses import dataclass, field
import math

r64 = float

A_FORMAT = '(A)'
BLANK_STRING = ' '
MAX_NAME_LENGTH = 60
SIGMA = 5.6697e-8
T_KELVIN = 273.15
PI = 3.141592653589793

VALID_DIGITS = "0123456789"
VALID_NUMERICS = "0123456789.+-EeDd\t"

END_OF_RECORD = -2
END_OF_FILE = -1
DEFAULT_INPUT_UNIT = 5
DEFAULT_OUTPUT_UNIT = 6
NUMBER_OF_PRECONNECTED_UNITS = 2
PRECONNECTED_UNITS = [5, 6]
MAX_UNIT_NUMBER = 1000

@dataclass
class WeatherDataDetails:
    Year: int = 0
    Month: int = 0
    Day: int = 0
    DayOfYear: int = 0
    IntervalMinute: List[int] = field(default_factory=lambda: [0] * 60)
    DataSourceFlags: List[List[str]] = field(default_factory=lambda: [[' ' * 50 for _ in range(60)] for _ in range(24)])
    DryBulb: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DewPoint: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    RelHum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    StnPres: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    xHorzRad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    xDirNormRad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    HorzIRSky: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    GlobHorzRad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DirNormRad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DifHorzRad: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    GlobHorzIllum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DirNormIllum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DifHorzIllum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    ZenLum: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    WindDir: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    WindSpd: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    TotSkyCvr: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    OpaqSkyCvr: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    Visibility: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    Ceiling: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    PresWthObs: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    PresWthCodes: List[List[str]] = field(default_factory=lambda: [[' ' * 9 for _ in range(60)] for _ in range(24)])
    PrecipWater: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    AerOptDepth: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    SnowDepth: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    DaysLastSnow: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    Albedo: List[List[float]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    LiquidPrecipDepth: List[List[float]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    LiquidPrecipRate: List[List[float]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    SnowInd: List[List[int]] = field(default_factory=lambda: [[0 for _ in range(60)] for _ in range(24)])
    HumRat: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    WetBulb: List[List[r64]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DeltaDBRange: bool = False
    DeltaChgDB: List[List[float]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])
    DeltaDPRange: bool = False
    DeltaChgDP: List[List[float]] = field(default_factory=lambda: [[0.0 for _ in range(60)] for _ in range(24)])

@dataclass
class MissingData:
    DryBulb: r64 = 0.0
    DewPoint: r64 = 0.0
    RelHumid: int = 0
    StnPres: r64 = 0.0
    WindDir: int = 0
    WindSpd: r64 = 0.0
    TotSkyCvr: int = 0
    OpaqSkyCvr: int = 0
    Visibility: r64 = 0.0
    Ceiling: int = 0
    PrecipWater: int = 0
    AerOptDepth: r64 = 0.0
    SnowDepth: int = 0
    DaysLastSnow: int = 0
    Albedo: float = 0.0
    LiquidPrecip: float = 0.0

@dataclass
class MissingDataCounts:
    xHorzRad: int = 0
    xDirNormRad: int = 0
    GloHorRad: int = 0
    DirNormRad: int = 0
    DifHorzRad: int = 0
    DryBulb: int = 0
    DewPoint: int = 0
    RelHumid: int = 0
    StnPres: int = 0
    WindDir: int = 0
    WindSpd: int = 0
    TotSkyCvr: int = 0
    OpaqSkyCvr: int = 0
    Visibility: int = 0
    Ceiling: int = 0
    PrecipWater: int = 0
    AerOptDepth: int = 0
    SnowDepth: int = 0
    DaysLastSnow: int = 0
    Albedo: int = 0
    LiquidPrecip: int = 0

@dataclass
class EPWReadState:
    WDay: List[WeatherDataDetails] = field(default_factory=lambda: [WeatherDataDetails() for _ in range(366)])
    Missing: MissingData = field(default_factory=MissingData)
    Missed: MissingDataCounts = field(default_factory=MissingDataCounts)
    LocationName: str = ' ' * (MAX_NAME_LENGTH * 2)
    NumDataPeriods: int = 0
    Latitude: r64 = 0.0
    Longitude: r64 = 0.0
    TimeZone: r64 = 0.0
    Elevation: r64 = 0.0
    StdBaroPress: r64 = 0.0
    StnWMO: str = ' ' * 10
    NumIntervalsPerHour: int = 0
    NumDays: int = 0

def find_non_space(string: str) -> int:
    ilen = len(string.rstrip())
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0

def get_new_unit_number() -> int:
    for unit_number in range(1, MAX_UNIT_NUMBER + 1):
        if unit_number == DEFAULT_INPUT_UNIT or unit_number == DEFAULT_OUTPUT_UNIT:
            continue
        if unit_number in PRECONNECTED_UNITS:
            continue
        try:
            with open(f'/dev/null', 'r'):
                pass
            return unit_number
        except:
            pass
    return -1

def process_number(string: str) -> Tuple[r64, bool]:
    pstring = string.strip()
    if len(pstring) == 0:
        return (0.0, False)
    
    ver_number = -1
    for i, c in enumerate(pstring):
        if c not in VALID_NUMERICS:
            ver_number = i
            break
    
    if ver_number == -1:
        try:
            temp = float(pstring)
            return (temp, False)
        except ValueError:
            return (0.0, True)
    else:
        return (0.0, True)

def y3_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))

def y5_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

def y6_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))

def y7_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64, a7: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))

def satutp(p: r64) -> r64:
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    
    pp = p
    
    if p > 2.3366e3:
        if p < 4.2415e3:
            t = y5_satutp(pp, -5.35428e1, 1.59311, -5.70202e-2, 1.44012e-3, -2.30578e-5, 2.22628e-7)
        elif p < 7.375e3:
            t = y5_satutp(pp, -5.35428e1, 1.59311, -5.70202e-2, 1.44012e-3, -2.30578e-5, 2.22628e-7)
        elif p < 1.992e4:
            t = y5_satutp(pp, 8.65676, 6.86019e-3, -5.07998e-7, 2.57958e-11, -7.28305e-16, 8.62156e-21)
        elif p < 1.0133e5:
            t = y6_satutp(pp, 2.66453e1, 2.54217e-3, -6.00185e-8, 1.01356e-12, -1.04474e-17, 5.88844e-23)
        else:
            t = y5_satutp(pp, 5.69919e1, 6.37817e-4, -2.85187e-9, 8.77453e-15, -1.48739e-20, 1.04699e-26)
    elif p > 1.227e3:
        t = y3_satutp(pp, -11.7426, 2.4662e-2, -6.66598e-6, 8.24255e-10)
    elif p > 6.108e2:
        t = y3_satutp(pp, -19.7816, 4.46963e-2, -2.36037e-5, 5.67281e-9)
    elif p > 1.0325e2:
        t = y6_satutp(pp, -3.59131e1, 2.31311e-1, -1.00453e-3, 2.99919e-6, -5.38184e-9, 5.22567e-12)
    elif p > 12.842:
        t = y7_satutp(pp, -5.35428e1, 1.59311, -5.70202e-2, 1.44012e-3, -2.30578e-5, 2.22628e-7, -1.17867e-9)
    else:
        t = y5_satutp(pp, -67.8912, 9.21677, -1.90385, 2.35588e-1, -1.48075e-2, 3.64517e-4)
    
    return t

def y3_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))

def y4_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))

def y5_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

def dry_sat_pt(tdb: r64) -> r64:
    tt = tdb
    
    if tdb > 20:
        if tdb < 30.0:
            psat = y3_drysat(tt, 4.05663e2, 76.8637, -4.47857e-1, 7.15905e-2)
        elif tdb < 40.0:
            psat = y3_drysat(tt, -3.58332e2, 1.52167e2, -2.93294, 9.90514e-2)
        else:
            psat = y5_drysat(tt, 7.30208e2, 32.987, 1.84658, 1.95497e-2, 3.33617e-4, 2.59343e-6)
    elif tdb > 10.0:
        psat = y3_drysat(tt, 5.9088e2, 49.8847, 8.74643e-1, 4.97621e-2)
    elif tdb > 0.0:
        psat = y3_drysat(tt, 6.10775e2, 44.4502, 1.38578, 3.3106e-2)
    elif tdb > -20.0:
        psat = y4_drysat(tt, 6.10860e2, 50.1255, 1.83622, 3.67769e-2, 3.41421e-4)
    elif tdb > -40.0:
        psat = y4_drysat(tt, 5.69275e2, 42.5035, 1.29301, 1.88391e-2, 1.0961e-4)
    else:
        psat = y5_drysat(tt, 4.9752e2, 35.3452, 1.04398, 1.5962e-2, 1.2578e-4, 4.0683e-7)
    
    return psat

def psat(t: r64) -> r64:
    dummy = t + 273.15
    if t < 0.0:
        psat_val = math.exp(-5.6745359e3 / dummy
                  - 5.1523058e-1
                  - 9.6778430e-3 * dummy
                  + 6.2215701e-7 * dummy**2
                  + 2.0747825e-9 * dummy**3
                  - 9.4840240e-13 * dummy**4
                  + 4.1635019 * math.log(dummy))
    else:
        psat_val = math.exp(-5.8002206e3 / dummy
                  - 5.5162560
                  - 4.8640239e-2 * dummy
                  + 4.1764768e-5 * dummy**2
                  - 1.4452093e-8 * dummy**3
                  + 6.5459673 * math.log(dummy))
    return psat_val * 1000.0

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
            tz = float(i)
            tz = math.fmod(tz, 24.0)
            return tz
    return -999.0

def get_loc_data(state: EPWReadState) -> Tuple[r64, r64, r64]:
    return (state.Latitude, state.Longitude, state.Elevation)

def read_and_interpret_epw_weather_line(input_line: str) -> Tuple[int, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, r64, int, str, r64, r64, r64, r64, r64, r64]:
    fields = [''] * 29
    line = input_line
    
    for count in range(25):
        pos = line.find(',')
        if pos >= 0:
            fields[count] = line[:pos]
            line = line[pos + 1:]
        else:
            fields[count] = line
            line = ''
    
    pos = line.find(',')
    if pos == -1:
        fields[25] = line
    else:
        fields[25] = line[:pos]
        line = line[pos + 1:]
        pos = line.find(',')
        if pos == -1:
            fields[26] = line
        else:
            fields[26] = line[:pos]
            line = line[pos + 1:]
            pos = line.find(',')
            if pos == -1:
                fields[27] = line
            else:
                fields[27] = line[:pos]
                line = line[pos + 1:]
                fields[28] = line
    
    ios = 0
    
    if fields[0] != BLANK_STRING:
        try:
            dry_bulb = float(fields[0])
        except:
            dry_bulb = 999.0
            ios = 2
    else:
        dry_bulb = 999.0
    
    if fields[1] != BLANK_STRING:
        try:
            dew_point = float(fields[1])
        except:
            dew_point = 999.0
            ios = 2
    else:
        dew_point = 999.0
    
    if fields[2] != BLANK_STRING:
        try:
            rel_hum = float(fields[2])
        except:
            rel_hum = 999.0
            ios = 3
    else:
        rel_hum = 999.0
    
    if fields[3] != BLANK_STRING:
        try:
            atm_press = float(fields[3])
        except:
            atm_press = 999999.0
            ios = 4
    else:
        atm_press = 999999.0
    
    if fields[4] != BLANK_STRING:
        try:
            ext_horz_rad = float(fields[4])
        except:
            ext_horz_rad = 9999.0
            ios = 1
    else:
        ext_horz_rad = 9999.0
    
    if fields[5] != BLANK_STRING:
        try:
            ext_dir_norm_rad = float(fields[5])
        except:
            ext_dir_norm_rad = 9999.0
            ios = 1
    else:
        ext_dir_norm_rad = 9999.0
    
    if fields[6] != BLANK_STRING:
        try:
            ir_horiz = float(fields[6])
        except:
            ir_horiz = 9999.0
            ios = 7
    else:
        ir_horiz = 9999.0
    
    if fields[7] != BLANK_STRING:
        try:
            glo_horz_rad = float(fields[7])
        except:
            glo_horz_rad = 9999.0
            ios = 1
    else:
        glo_horz_rad = 9999.0
    
    if fields[8] != BLANK_STRING:
        try:
            dir_norm_rad = float(fields[8])
        except:
            dir_norm_rad = 9999.0
            ios = 9
    else:
        dir_norm_rad = 9999.0
    
    if fields[9] != BLANK_STRING:
        try:
            dif_horz_rad = float(fields[9])
        except:
            dif_horz_rad = 9999.0
            ios = 10
    else:
        dif_horz_rad = 9999.0
    
    if fields[10] != BLANK_STRING:
        try:
            glo_horz_illum = float(fields[10])
        except:
            glo_horz_illum = 999999.0
            ios = 1
    else:
        glo_horz_illum = 999999.0
    
    if fields[11] != BLANK_STRING:
        try:
            dir_norm_illum = float(fields[11])
        except:
            dir_norm_illum = 999999.0
            ios = 1
    else:
        dir_norm_illum = 999999.0
    
    if fields[12] != BLANK_STRING:
        try:
            dif_horz_illum = float(fields[12])
        except:
            dif_horz_illum = 999999.0
            ios = 1
    else:
        dif_horz_illum = 999999.0
    
    if fields[13] != BLANK_STRING:
        try:
            zenith_lum = float(fields[13])
        except:
            zenith_lum = 99999.0
            ios = 1
    else:
        zenith_lum = 99999.0
    
    if fields[14] != BLANK_STRING:
        try:
            wind_dir = float(fields[14])
        except:
            wind_dir = 999.0
            ios = 15
    else:
        wind_dir = 999.0
    
    if fields[15] != BLANK_STRING:
        try:
            wind_spd = float(fields[15])
        except:
            wind_spd = 999.0
            ios = 16
    else:
        wind_spd = 999.0
    
    if fields[16] != BLANK_STRING:
        try:
            tot_sky_cvr = float(fields[16])
        except:
            tot_sky_cvr = 99.0
            ios = 17
    else:
        tot_sky_cvr = 99.0
    
    if fields[17] != BLANK_STRING:
        try:
            opq_sky_cvr = float(fields[17])
        except:
            opq_sky_cvr = 99.0
            ios = 18
    else:
        opq_sky_cvr = 99.0
    
    if fields[18] != BLANK_STRING:
        try:
            visibility = float(fields[18])
        except:
            visibility = 9999.0
            ios = 1
    else:
        visibility = 9999.0
    
    if fields[19] != BLANK_STRING:
        try:
            ceil_hgt = float(fields[19])
        except:
            ceil_hgt = 99999.0
            ios = 1
    else:
        ceil_hgt = 99999.0
    
    if fields[20] != BLANK_STRING:
        try:
            pres_weath_obs = int(float(fields[20]))
        except:
            pres_weath_obs = 9
            ios = 21
    else:
        pres_weath_obs = 9
    
    if fields[21] != BLANK_STRING:
        pres_weath_codes = fields[21]
    else:
        pres_weath_codes = '999999999'
    
    if fields[22] != BLANK_STRING:
        try:
            prec_wtr = float(fields[22])
        except:
            prec_wtr = 999.0
            ios = 23
    else:
        prec_wtr = 999.0
    
    if fields[23] != BLANK_STRING:
        try:
            aer_opt_depth = float(fields[23])
        except:
            aer_opt_depth = 0.999
            ios = 1
    else:
        aer_opt_depth = 0.999
    
    if fields[24] != BLANK_STRING:
        try:
            snow_depth = float(fields[24])
        except:
            snow_depth = 999.0
            ios = 25
    else:
        snow_depth = 999.0
    
    if fields[25] != BLANK_STRING:
        try:
            days_last_snow = float(fields[25])
        except:
            days_last_snow = 99.0
            ios = 1
    else:
        days_last_snow = 99.0
    
    if fields[26] != BLANK_STRING:
        try:
            albedo = float(fields[26])
        except:
            albedo = 0.1
            ios = 1
    else:
        albedo = 0.1
    
    if fields[27] != BLANK_STRING:
        try:
            rain = float(fields[27])
        except:
            rain = 0.0
            ios = 28
    else:
        rain = 0.0
    
    if fields[28] != BLANK_STRING:
        try:
            rain_rate = float(fields[28])
        except:
            rain_rate = 1.0
            ios = 1
    else:
        rain_rate = 1.0
    
    return (ios, dry_bulb, dew_point, rel_hum, atm_press, ext_horz_rad, ext_dir_norm_rad, 
            ir_horiz, glo_horz_rad, dir_norm_rad, dif_horz_rad, glo_horz_illum, dir_norm_illum, 
            dif_horz_illum, zenith_lum, wind_dir, wind_spd, tot_sky_cvr, opq_sky_cvr, visibility, 
            ceil_hgt, pres_weath_obs, pres_weath_codes, prec_wtr, aer_opt_depth, snow_depth, 
            days_last_snow, albedo, rain, rain_rate)

def process_epw_header(weather_file_unit_number: int, header_string: str, line: str, 
                       state: EPWReadState) -> Tuple[bool, str]:
    errors_found = False
    error_message = ''
    
    pos = line.find(',')
    if pos >= 0:
        line = line[pos + 1:]
    
    if header_string == 'LOCATION':
        num_hd_args = 9
        count = 1
        title = ''
        
        while count <= num_hd_args:
            line = line.lstrip()
            pos = line.find(',')
            if pos == -1:
                if len(line.strip()) == 0:
                    while pos == -1:
                        try:
                            with open('/dev/stdin', 'r') as f:
                                line = f.readline()
                                line = line.lstrip()
                                pos = line.find(',')
                        except:
                            break
                else:
                    pos = len(line)
            
            if count == 1:
                title = line[:pos].strip()
            elif count in [2, 3, 4]:
                title = title + ' ' + line[:pos].strip()
            elif count == 5:
                state.StnWMO = line[:pos].strip().ljust(10)
            else:
                number, err_flag = process_number(line[:pos].strip())
                if not err_flag:
                    if count == 6:
                        state.Latitude = number
                    elif count == 7:
                        state.Longitude = number
                    elif count == 8:
                        state.TimeZone = number
                    elif count == 9:
                        state.Elevation = number
                else:
                    error_message = 'GetEPWHeader:LOCATION, invalid numeric=' + line[:pos].strip()
                    errors_found = True
                    return (errors_found, error_message)
            
            if pos >= 0 and pos < len(line):
                line = line[pos + 1:]
            else:
                line = ''
            count += 1
        
        state.LocationName = title.strip().ljust(MAX_NAME_LENGTH * 2)
    
    return (errors_found, error_message)

def process_epw_headers(weather_file_unit_number: int, state: EPWReadState) -> Tuple[bool, str]:
    errors_found = False
    error_message = ''
    
    headers = ["LOCATION                ", "DESIGN CONDITIONS       ",
               "TYPICAL/EXTREME PERIODS ", "GROUND TEMPERATURES     ",
               "HOLIDAYS/DAYLIGHT SAVING", "COMMENTS 1              ",
               "COMMENTS 2              ", "DATA PERIODS            "]
    
    try:
        with open('/dev/stdin', 'r') as f:
            hd_line = 1
            still_looking = True
            
            while still_looking:
                try:
                    line = f.readline()
                    if not line:
                        error_message = ('Unexpected End-of-File on EPW Weather file, ' +
                                       'while reading header information, looking for header=' +
                                       headers[hd_line - 1].strip())
                        errors_found = True
                        return (errors_found, error_message)
                    
                    line = line.rstrip('\n')
                    pos = find_non_space(line)
                    hd_pos = line.find(headers[hd_line - 1].strip())
                    
                    if pos - 1 != hd_pos:
                        continue
                    
                    errors_found_temp, error_message_temp = process_epw_header(
                        weather_file_unit_number, headers[hd_line - 1].strip(), line, state)
                    
                    if errors_found_temp:
                        return (errors_found_temp, error_message_temp)
                    
                    hd_line += 1
                    if hd_line == 9:
                        still_looking = False
                
                except Exception as e:
                    error_message = str(e)
                    errors_found = True
                    return (errors_found, error_message)
    
    except Exception as e:
        error_message = str(e)
        errors_found = True
        return (errors_found, error_message)
    
    return (errors_found, error_message)

def read_epw(input_file: str, state: EPWReadState) -> Tuple[bool, str, int]:
    errors_found = False
    error_message = ''
    number_of_days = 0
    
    state.Missing.StnPres = 101325.0
    state.Missing.DryBulb = 6.0
    state.Missing.DewPoint = 3.0
    state.Missing.RelHumid = 50
    state.Missing.WindSpd = 2.5
    state.Missing.WindDir = 180
    state.Missing.TotSkyCvr = 5
    state.Missing.OpaqSkyCvr = 5
    state.Missing.Visibility = 777.7
    state.Missing.Ceiling = 77777
    state.Missing.PrecipWater = 0
    state.Missing.AerOptDepth = 0.0
    state.Missing.SnowDepth = 0
    state.Missing.DaysLastSnow = 88
    state.Missing.Albedo = 0.0
    state.Missing.LiquidPrecip = 0.0
    
    state.Missed.xHorzRad = 0
    state.Missed.xDirNormRad = 0
    state.Missed.GloHorRad = 0
    state.Missed.DirNormRad = 0
    state.Missed.DifHorzRad = 0
    state.Missed.StnPres = 0
    state.Missed.DryBulb = 0
    state.Missed.DewPoint = 0
    state.Missed.RelHumid = 0
    state.Missed.WindSpd = 0
    state.Missed.WindDir = 0
    state.Missed.TotSkyCvr = 0
    state.Missed.OpaqSkyCvr = 0
    state.Missed.Visibility = 0
    state.Missed.Ceiling = 0
    state.Missed.PrecipWater = 0
    state.Missed.AerOptDepth = 0
    state.Missed.SnowDepth = 0
    state.Missed.DaysLastSnow = 0
    state.Missed.Albedo = 0
    state.Missed.LiquidPrecip = 0
    
    for count in range(1, 367):
        state.WDay[count - 1] = WeatherDataDetails()
    
    try:
        with open(input_file, 'r') as f:
            state.NumIntervalsPerHour = 1
            
            errors_found_temp, error_message_temp = process_epw_headers(0, state)
            if errors_found_temp:
                return (errors_found_temp, error_message_temp, 0)
            
            state.StdBaroPress = (101.325 * (1.0 - 2.25577e-05 * state.Elevation) ** 5.2559) * 1000.0
            state.Missing.StnPres = state.StdBaroPress
            
            state.NumDays = 0
            hour = 24
            interval = state.NumIntervalsPerHour
            
            for line in f:
                line = line.rstrip('\n')
                if not line:
                    break
                
                com5 = [0] * 5
                input_line = line
                
                for count in range(5):
                    pos = input_line.find(',')
                    if pos >= 0:
                        com5[count] = pos
                        input_line = input_line[:pos] + '$' + input_line[pos + 1:]
                
                comma6 = input_line.find(',')
                if comma6 == -1:
                    comma6 = len(input_line)
                
                source_flags = input_line[com5[4] + 1:comma6].strip()
                source_flags = source_flags.replace(' ', '_')
                input_line = input_line[:com5[4] + 1] + source_flags + input_line[comma6:]
                
                for count in range(5):
                    input_line = input_line[:com5[count]] + ',' + input_line[com5[count] + 1:]
                
                parts = input_line[:comma6].split(',')
                if len(parts) < 6:
                    error_message = f' *** Line in error={input_line} ** Error during processing day #{state.NumDays}'
                    errors_found = True
                    return (errors_found, error_message, 0)
                
                try:
                    wyear = int(parts[0])
                    wmonth = int(parts[1])
                    wday_of_month = int(parts[2])
                    whour = int(parts[3])
                    wminute = float(parts[4])
                    source_flags = parts[5]
                except:
                    error_message = f' *** Line in error={input_line} ** Error during processing day #{state.NumDays}'
                    errors_found = True
                    return (errors_found, error_message, 0)
                
                input_line = input_line[comma6 + 1:]
                
                (ios, dry_bulb, dew_point, rel_humid, atm_press, ext_horz_rad, ext_dir_norm_rad,
                 ir_horiz, glo_horz_rad, dir_norm_rad, dif_horz_rad, glo_horz_illum, dir_norm_illum,
                 dif_horz_illum, zenith_lum, wind_dir, wind_spd, tot_sky_cvr, opq_sky_cvr,
                 visibility, ceil_hgt, pres_weath_obs, pres_weath_codes, prec_wtr, aer_opt_depth,
                 snow_depth, days_last_snow, albedo, rain, rain_rate) = read_and_interpret_epw_weather_line(input_line)
                
                pres_weath_codes = pres_weath_codes.replace("'", ' ').replace('"', ' ').strip()
                
                if len(pres_weath_codes) == 9:
                    pres_weath_codes_list = list(pres_weath_codes)
                    for pos in range(9):
                        if pres_weath_codes_list[pos] not in VALID_DIGITS:
                            pres_weath_codes_list[pos] = '9'
                    pres_weath_codes = ''.join(pres_weath_codes_list)
                
                interval += 1
                if interval > state.NumIntervalsPerHour:
                    interval = 1
                    hour += 1
                if hour > 24:
                    hour = 1
                    state.NumDays += 1
                
                if hour == 1:
                    state.WDay[state.NumDays - 1].Year = wyear
                    state.WDay[state.NumDays - 1].Month = wmonth
                    state.WDay[state.NumDays - 1].Day = wday_of_month
                
                state.WDay[state.NumDays - 1].IntervalMinute[interval - 1] = round(wminute)
                
                fld1, fld2, fld3, fld4, fld_ir = source_flags[0:2], source_flags[2:4], source_flags[4:6], source_flags[6:8], source_flags[8:10]
                fld5, fld6, fld7, fld8, fld9 = source_flags[10:12], source_flags[12:14], source_flags[14:16], source_flags[16:18], source_flags[18:20]
                fld10, fld11, fld12, fld13, fld14 = source_flags[20:22], source_flags[22:24], source_flags[24:26], source_flags[26:28], source_flags[28:30]
                fld15, fld16, fld17, fld18, fld19 = source_flags[30:32], source_flags[32:34], source_flags[34:36], source_flags[36:38], source_flags[38:40]
                fld20, fld21, fld22, fld23, fld24 = source_flags[40:42], source_flags[42:44], source_flags[44:46], source_flags[46:48], source_flags[48:50] if len(source_flags) >= 50 else ''
                
                if ext_horz_rad >= 9999:
                    state.Missed.xHorzRad += 1
                if ext_dir_norm_rad >= 9999:
                    state.Missed.xDirNormRad += 1
                if glo_horz_rad >= 9999:
                    state.Missed.GloHorRad += 1
                if dir_norm_rad >= 9999:
                    state.Missed.DirNormRad += 1
                if dif_horz_rad >= 9999:
                    state.Missed.DifHorzRad += 1
                
                if dry_bulb >= 99.9:
                    dry_bulb = state.Missing.DryBulb
                    fld10 = '*' + fld10[1:] if len(fld10) > 1 else '*'
                    state.Missed.DryBulb += 1
                
                if atm_press >= 999999.0:
                    atm_press = state.Missing.StnPres
                    fld13 = '*'
                    state.Missed.StnPres += 1
                
                rel_humid_missing = False
                if rel_humid >= 999.0:
                    rel_humid = state.Missing.RelHumid
                    fld12 = '*' + fld12[1:] if len(fld12) > 1 else '*'
                    state.Missed.RelHumid += 1
                    rel_humid_missing = True
                
                if dew_point >= 99.9:
                    state.Missed.DewPoint += 1
                    if rel_humid_missing:
                        dew_point = state.Missing.DewPoint
                        fld11 = '*' + fld11[1:] if len(fld11) > 1 else '*'
                        if dew_point > dry_bulb:
                            dew_point = dry_bulb - 3.0
                    else:
                        pws = psat(float(dry_bulb))
                        pw = max(rel_humid, 1.0) * 0.01 * pws
                        dew_point = satutp(pw)
                        fld11 = '*' + fld11[1:] if len(fld11) > 1 else '*'
                
                if wind_spd >= 999.0:
                    wind_spd = state.Missing.WindSpd
                    fld15 = '*' + fld15[1:] if len(fld15) > 1 else '*'
                    state.Missed.WindSpd += 1
                
                if wind_dir >= 999.0:
                    wind_dir = state.Missing.WindDir
                    fld14 = '*' + fld14[1:] if len(fld14) > 1 else '*'
                    state.Missed.WindDir += 1
                
                i_wind_dir = int(wind_dir)
                
                if visibility >= 9999.0:
                    visibility = state.Missing.Visibility
                    fld16 = '*' + fld16[1:] if len(fld16) > 1 else '*'
                    state.Missed.Visibility += 1
                
                if aer_opt_depth >= 0.999:
                    aer_opt_depth = state.Missing.AerOptDepth
                    fld19 = '*'
                    state.Missed.AerOptDepth += 1
                
                if tot_sky_cvr == 99.0:
                    tot_sky_cvr = state.Missing.TotSkyCvr
                    fld8 = '*' + fld8[1:] if len(fld8) > 1 else '*'
                    state.Missed.TotSkyCvr += 1
                if opq_sky_cvr == 99.0:
                    opq_sky_cvr = state.Missing.OpaqSkyCvr
                    fld9 = '*' + fld9[1:] if len(fld9) > 1 else '*'
                    state.Missed.OpaqSkyCvr += 1
                if ceil_hgt >= 99999.0:
                    ceil_hgt = state.Missing.Ceiling
                    fld17 = '*' + fld17[1:] if len(fld17) > 1 else '*'
                    state.Missed.Ceiling += 1
                if prec_wtr >= 999:
                    prec_wtr = state.Missing.PrecipWater
                    fld18 = '*' + fld18[1:] if len(fld18) > 1 else '*'
                    state.Missed.PrecipWater += 1
                if snow_depth >= 999:
                    snow_depth = state.Missing.SnowDepth
                    fld20 = '*' + fld20[1:] if len(fld20) > 1 else '*'
                    state.Missed.SnowDepth += 1
                if days_last_snow >= 99:
                    days_last_snow = state.Missing.DaysLastSnow
                    fld21 = '*' + fld21[1:] if len(fld21) > 1 else '*'
                    state.Missed.DaysLastSnow += 1
                if albedo >= 999.0:
                    albedo = 0.0
                    fld22 = '*' + fld22[1:] if len(fld22) > 1 else '*'
                    state.Missed.Albedo += 1
                if rain >= 999.0:
                    rain = 0.0
                    fld23 = '*' + fld23[1:] if len(fld23) > 1 else '*'
                    state.Missed.LiquidPrecip += 1
                if rain_rate >= 99.0:
                    rain_rate = 99.0
                    fld24 = '*' + fld24[1:] if len(fld24) > 1 else '*'
                
                state.WDay[state.NumDays - 1].xHorzRad[hour - 1][interval - 1] = ext_horz_rad
                state.WDay[state.NumDays - 1].xDirNormRad[hour - 1][interval - 1] = ext_dir_norm_rad
                state.WDay[state.NumDays - 1].GlobHorzRad[hour - 1][interval - 1] = glo_horz_rad
                state.WDay[state.NumDays - 1].DirNormRad[hour - 1][interval - 1] = dir_norm_rad
                state.WDay[state.NumDays - 1].DifHorzRad[hour - 1][interval - 1] = dif_horz_rad
                state.WDay[state.NumDays - 1].GlobHorzIllum[hour - 1][interval - 1] = glo_horz_illum
                state.WDay[state.NumDays - 1].DirNormIllum[hour - 1][interval - 1] = dir_norm_illum
                state.WDay[state.NumDays - 1].DifHorzIllum[hour - 1][interval - 1] = dif_horz_illum
                state.WDay[state.NumDays - 1].ZenLum[hour - 1][interval - 1] = zenith_lum
                state.WDay[state.NumDays - 1].TotSkyCvr[hour - 1][interval - 1] = int(tot_sky_cvr)
                state.WDay[state.NumDays - 1].OpaqSkyCvr[hour - 1][interval - 1] = int(opq_sky_cvr)
                state.WDay[state.NumDays - 1].DryBulb[hour - 1][interval - 1] = dry_bulb
                state.WDay[state.NumDays - 1].DewPoint[hour - 1][interval - 1] = dew_point
                state.WDay[state.NumDays - 1].RelHum[hour - 1][interval - 1] = rel_humid
                state.WDay[state.NumDays - 1].StnPres[hour - 1][interval - 1] = atm_press
                state.WDay[state.NumDays - 1].WindDir[hour - 1][interval - 1] = i_wind_dir
                state.WDay[state.NumDays - 1].WindSpd[hour - 1][interval - 1] = wind_spd
                state.WDay[state.NumDays - 1].Visibility[hour - 1][interval - 1] = visibility
                state.WDay[state.NumDays - 1].Ceiling[hour - 1][interval - 1] = int(ceil_hgt)
                state.WDay[state.NumDays - 1].PresWthObs[hour - 1][interval - 1] = pres_weath_obs
                state.WDay[state.NumDays - 1].PresWthCodes[hour - 1][interval - 1] = pres_weath_codes.ljust(9)
                state.WDay[state.NumDays - 1].PrecipWater[hour - 1][interval - 1] = int(prec_wtr)
                state.WDay[state.NumDays - 1].AerOptDepth[hour - 1][interval - 1] = aer_opt_depth
                state.WDay[state.NumDays - 1].SnowDepth[hour - 1][interval - 1] = int(snow_depth)
                state.WDay[state.NumDays - 1].DaysLastSnow[hour - 1][interval - 1] = int(days_last_snow)
                state.WDay[state.NumDays - 1].Albedo[hour - 1][interval - 1] = int(days_last_snow)
                state.WDay[state.NumDays - 1].LiquidPrecipDepth[hour - 1][interval - 1] = rain
                state.WDay[state.NumDays - 1].LiquidPrecipRate[hour - 1][interval - 1] = rain_rate
                
                satupt_val = dry_sat_pt(dry_bulb)
                pdew = rel_humid / 100.0 * satupt_val
                hum_rat = pdew * 0.62198 / (atm_press - pdew)
                state.WDay[state.NumDays - 1].HumRat[hour - 1][interval - 1] = hum_rat
                
                t2 = dry_bulb + 273.15
                if dry_bulb < 0.0:
                    pws = math.exp(-5.6745359e3 / t2 + 6.3925247 - 9.677843e-03 * t2 +
                                  6.2215701e-07 * t2**2 + 2.0747825e-09 * t2**3 -
                                  9.4840240e-13 * t2**4 + 4.1635019 * math.log(t2))
                else:
                    pws = math.exp(-5.8002206e3 / t2 + 1.3914993 - 4.8640239e-02 * t2 +
                                  4.176476e-05 * t2**2 - 1.4452093e-08 * t2**3 +
                                  6.5459673 * math.log(t2))
                
                wsstar = 0.62198 * (pws / (atm_press - pws))
                state.WDay[state.NumDays - 1].WetBulb[hour - 1][interval - 1] = (
                    (2501.0 + 1.805 * dry_bulb) * hum_rat - 2501.0 * wsstar + dry_bulb) / (
                    4.186 * hum_rat - 2.381 * wsstar + 1.0)
                
                if snow_depth > 0:
                    state.WDay[state.NumDays - 1].SnowInd[hour - 1][interval - 1] = 1
                else:
                    state.WDay[state.NumDays - 1].SnowInd[hour - 1][interval - 1] = 0
                
                if ir_horiz <= 0.0 or ir_horiz >= 9999.0:
                    t_dew_k = state.WDay[state.NumDays - 1].DewPoint[hour - 1][interval - 1] + T_KELVIN
                    t_dry_k = state.WDay[state.NumDays - 1].DryBulb[hour - 1][interval - 1] + T_KELVIN
                    o_sky = state.WDay[state.NumDays - 1].OpaqSkyCvr[hour - 1][interval - 1]
                    e_sky = (0.787 + 0.764 * math.log(t_dew_k / T_KELVIN)) * (
                        1.0 + 0.0224 * o_sky - 0.0035 * (o_sky**2) + 0.00028 * (o_sky**3))
                    
                    state.WDay[state.NumDays - 1].HorzIRSky[hour - 1][interval - 1] = (
                        e_sky * SIGMA * (t_dry_k**4))
                else:
                    state.WDay[state.NumDays - 1].HorzIRSky[hour - 1][interval - 1] = ir_horiz
                
                data_source_flags = fld1 + fld2 + fld3 + fld4 + fld_ir + fld5 + fld6 + fld7 + fld8 + fld9 + fld10 + fld11 + fld12 + fld13 + fld14 + fld15 + fld16 + fld17 + fld18 + fld19 + fld20 + fld21
                data_source_flags = data_source_flags.replace(' ', '_').replace(',', '_')
                state.WDay[state.NumDays - 1].DataSourceFlags[hour - 1][interval - 1] = data_source_flags.ljust(50)
                
                state.Missing.StnPres = atm_press
                state.Missing.DryBulb = dry_bulb
                state.Missing.DewPoint = dew_point
                state.Missing.WindSpd = wind_spd
                state.Missing.WindDir = int(wind_dir)
                state.Missing.TotSkyCvr = int(tot_sky_cvr)
                state.Missing.OpaqSkyCvr = int(opq_sky_cvr)
                state.Missing.Visibility = visibility
                state.Missing.Ceiling = int(ceil_hgt)
                state.Missing.PrecipWater = int(prec_wtr)
                state.Missing.AerOptDepth = aer_opt_depth
                state.Missing.SnowDepth = int(snow_depth)
                state.Missing.DaysLastSnow = int(days_last_snow)
    
    except FileNotFoundError:
        error_message = ' *** Could not open EPW file=' + input_file
        errors_found = True
        return (errors_found, error_message, 0)
    except Exception as e:
        error_message = ' *** Line in error ** Error during processing'
        errors_found = True
        return (errors_found, error_message, 0)
    
    number_of_days = state.NumDays
    return (errors_found, error_message, number_of_days)
