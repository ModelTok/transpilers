from memory import UnsafePointer
from collections import OptionalReg
import math

alias r64 = Float64

alias A_FORMAT = "(A)"
alias BLANK_STRING = " "
alias MAX_NAME_LENGTH = 60
alias SIGMA = 5.6697e-8
alias T_KELVIN = 273.15
alias PI = 3.141592653589793

alias VALID_DIGITS = "0123456789"
alias VALID_NUMERICS = "0123456789.+-EeDd\t"

alias END_OF_RECORD = -2
alias END_OF_FILE = -1
alias DEFAULT_INPUT_UNIT = 5
alias DEFAULT_OUTPUT_UNIT = 6
alias NUMBER_OF_PRECONNECTED_UNITS = 2
alias MAX_UNIT_NUMBER = 1000

struct WeatherDataDetails:
    var Year: Int
    var Month: Int
    var Day: Int
    var DayOfYear: Int
    var IntervalMinute: List[Int]
    var DataSourceFlags: List[List[String]]
    var DryBulb: List[List[r64]]
    var DewPoint: List[List[r64]]
    var RelHum: List[List[r64]]
    var StnPres: List[List[r64]]
    var xHorzRad: List[List[r64]]
    var xDirNormRad: List[List[r64]]
    var HorzIRSky: List[List[r64]]
    var GlobHorzRad: List[List[r64]]
    var DirNormRad: List[List[r64]]
    var DifHorzRad: List[List[r64]]
    var GlobHorzIllum: List[List[r64]]
    var DirNormIllum: List[List[r64]]
    var DifHorzIllum: List[List[r64]]
    var ZenLum: List[List[r64]]
    var WindDir: List[List[Int]]
    var WindSpd: List[List[r64]]
    var TotSkyCvr: List[List[Int]]
    var OpaqSkyCvr: List[List[Int]]
    var Visibility: List[List[r64]]
    var Ceiling: List[List[Int]]
    var PresWthObs: List[List[Int]]
    var PresWthCodes: List[List[String]]
    var PrecipWater: List[List[Int]]
    var AerOptDepth: List[List[r64]]
    var SnowDepth: List[List[Int]]
    var DaysLastSnow: List[List[Int]]
    var Albedo: List[List[Float32]]
    var LiquidPrecipDepth: List[List[Float32]]
    var LiquidPrecipRate: List[List[Float32]]
    var SnowInd: List[List[Int]]
    var HumRat: List[List[r64]]
    var WetBulb: List[List[r64]]
    var DeltaDBRange: Bool
    var DeltaChgDB: List[List[Float32]]
    var DeltaDPRange: Bool
    var DeltaChgDP: List[List[Float32]]
    
    fn __init__(inout self):
        self.Year = 0
        self.Month = 0
        self.Day = 0
        self.DayOfYear = 0
        self.IntervalMinute = List[Int]()
        for i in range(60):
            self.IntervalMinute.append(0)
        self.DataSourceFlags = List[List[String]]()
        for i in range(24):
            var row = List[String]()
            for j in range(60):
                row.append(" " * 50)
            self.DataSourceFlags.append(row)
        self.DryBulb = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DryBulb.append(row)
        self.DewPoint = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DewPoint.append(row)
        self.RelHum = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.RelHum.append(row)
        self.StnPres = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.StnPres.append(row)
        self.xHorzRad = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.xHorzRad.append(row)
        self.xDirNormRad = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.xDirNormRad.append(row)
        self.HorzIRSky = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.HorzIRSky.append(row)
        self.GlobHorzRad = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.GlobHorzRad.append(row)
        self.DirNormRad = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DirNormRad.append(row)
        self.DifHorzRad = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DifHorzRad.append(row)
        self.GlobHorzIllum = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.GlobHorzIllum.append(row)
        self.DirNormIllum = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DirNormIllum.append(row)
        self.DifHorzIllum = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.DifHorzIllum.append(row)
        self.ZenLum = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.ZenLum.append(row)
        self.WindDir = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.WindDir.append(row)
        self.WindSpd = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.WindSpd.append(row)
        self.TotSkyCvr = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.TotSkyCvr.append(row)
        self.OpaqSkyCvr = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.OpaqSkyCvr.append(row)
        self.Visibility = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.Visibility.append(row)
        self.Ceiling = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.Ceiling.append(row)
        self.PresWthObs = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.PresWthObs.append(row)
        self.PresWthCodes = List[List[String]]()
        for i in range(24):
            var row = List[String]()
            for j in range(60):
                row.append(" " * 9)
            self.PresWthCodes.append(row)
        self.PrecipWater = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.PrecipWater.append(row)
        self.AerOptDepth = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.AerOptDepth.append(row)
        self.SnowDepth = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.SnowDepth.append(row)
        self.DaysLastSnow = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.DaysLastSnow.append(row)
        self.Albedo = List[List[Float32]]()
        for i in range(24):
            var row = List[Float32]()
            for j in range(60):
                row.append(0.0)
            self.Albedo.append(row)
        self.LiquidPrecipDepth = List[List[Float32]]()
        for i in range(24):
            var row = List[Float32]()
            for j in range(60):
                row.append(0.0)
            self.LiquidPrecipDepth.append(row)
        self.LiquidPrecipRate = List[List[Float32]]()
        for i in range(24):
            var row = List[Float32]()
            for j in range(60):
                row.append(0.0)
            self.LiquidPrecipRate.append(row)
        self.SnowInd = List[List[Int]]()
        for i in range(24):
            var row = List[Int]()
            for j in range(60):
                row.append(0)
            self.SnowInd.append(row)
        self.HumRat = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.HumRat.append(row)
        self.WetBulb = List[List[r64]]()
        for i in range(24):
            var row = List[r64]()
            for j in range(60):
                row.append(0.0)
            self.WetBulb.append(row)
        self.DeltaDBRange = False
        self.DeltaChgDB = List[List[Float32]]()
        for i in range(24):
            var row = List[Float32]()
            for j in range(60):
                row.append(0.0)
            self.DeltaChgDB.append(row)
        self.DeltaDPRange = False
        self.DeltaChgDP = List[List[Float32]]()
        for i in range(24):
            var row = List[Float32]()
            for j in range(60):
                row.append(0.0)
            self.DeltaChgDP.append(row)

struct MissingData:
    var DryBulb: r64
    var DewPoint: r64
    var RelHumid: Int
    var StnPres: r64
    var WindDir: Int
    var WindSpd: r64
    var TotSkyCvr: Int
    var OpaqSkyCvr: Int
    var Visibility: r64
    var Ceiling: Int
    var PrecipWater: Int
    var AerOptDepth: r64
    var SnowDepth: Int
    var DaysLastSnow: Int
    var Albedo: Float32
    var LiquidPrecip: Float32
    
    fn __init__(inout self):
        self.DryBulb = 0.0
        self.DewPoint = 0.0
        self.RelHumid = 0
        self.StnPres = 0.0
        self.WindDir = 0
        self.WindSpd = 0.0
        self.TotSkyCvr = 0
        self.OpaqSkyCvr = 0
        self.Visibility = 0.0
        self.Ceiling = 0
        self.PrecipWater = 0
        self.AerOptDepth = 0.0
        self.SnowDepth = 0
        self.DaysLastSnow = 0
        self.Albedo = 0.0
        self.LiquidPrecip = 0.0

struct MissingDataCounts:
    var xHorzRad: Int
    var xDirNormRad: Int
    var GloHorRad: Int
    var DirNormRad: Int
    var DifHorzRad: Int
    var DryBulb: Int
    var DewPoint: Int
    var RelHumid: Int
    var StnPres: Int
    var WindDir: Int
    var WindSpd: Int
    var TotSkyCvr: Int
    var OpaqSkyCvr: Int
    var Visibility: Int
    var Ceiling: Int
    var PrecipWater: Int
    var AerOptDepth: Int
    var SnowDepth: Int
    var DaysLastSnow: Int
    var Albedo: Int
    var LiquidPrecip: Int
    
    fn __init__(inout self):
        self.xHorzRad = 0
        self.xDirNormRad = 0
        self.GloHorRad = 0
        self.DirNormRad = 0
        self.DifHorzRad = 0
        self.DryBulb = 0
        self.DewPoint = 0
        self.RelHumid = 0
        self.StnPres = 0
        self.WindDir = 0
        self.WindSpd = 0
        self.TotSkyCvr = 0
        self.OpaqSkyCvr = 0
        self.Visibility = 0
        self.Ceiling = 0
        self.PrecipWater = 0
        self.AerOptDepth = 0
        self.SnowDepth = 0
        self.DaysLastSnow = 0
        self.Albedo = 0
        self.LiquidPrecip = 0

struct EPWReadState:
    var WDay: List[WeatherDataDetails]
    var Missing: MissingData
    var Missed: MissingDataCounts
    var LocationName: String
    var NumDataPeriods: Int
    var Latitude: r64
    var Longitude: r64
    var TimeZone: r64
    var Elevation: r64
    var StdBaroPress: r64
    var StnWMO: String
    var NumIntervalsPerHour: Int
    var NumDays: Int
    
    fn __init__(inout self):
        self.WDay = List[WeatherDataDetails]()
        for i in range(366):
            self.WDay.append(WeatherDataDetails())
        self.Missing = MissingData()
        self.Missed = MissingDataCounts()
        self.LocationName = " " * (MAX_NAME_LENGTH * 2)
        self.NumDataPeriods = 0
        self.Latitude = 0.0
        self.Longitude = 0.0
        self.TimeZone = 0.0
        self.Elevation = 0.0
        self.StdBaroPress = 0.0
        self.StnWMO = " " * 10
        self.NumIntervalsPerHour = 0
        self.NumDays = 0

fn find_non_space(string: String) -> Int:
    var ilen = len(string)
    for i in range(ilen):
        if string[i] != ' ':
            return i + 1
    return 0

fn process_number(string: String) -> Tuple[r64, Bool]:
    var pstring = string.strip()
    if len(pstring) == 0:
        return (0.0, False)
    
    var ver_number = -1
    for i in range(len(pstring)):
        var c = pstring[i]
        var found = False
        for valid_c in VALID_NUMERICS:
            if c == valid_c:
                found = True
                break
        if not found:
            ver_number = i
            break
    
    if ver_number == -1:
        try:
            var temp = Float64(pstring)
            return (temp, False)
        except:
            return (0.0, True)
    else:
        return (0.0, True)

@always_inline
fn y3_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))

@always_inline
fn y5_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

@always_inline
fn y6_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * a6)))))

@always_inline
fn y7_satutp(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64, a6: r64, a7: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * (a5 + x * (a6 + x * a7))))))

fn satutp(p: r64) -> r64:
    if p <= 1.0813 or p >= 1.0133e5:
        pass
    
    var pp = p
    var t: r64
    
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

@always_inline
fn y3_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * a3))

@always_inline
fn y4_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * a4)))

@always_inline
fn y5_drysat(x: r64, a0: r64, a1: r64, a2: r64, a3: r64, a4: r64, a5: r64) -> r64:
    return a0 + x * (a1 + x * (a2 + x * (a3 + x * (a4 + x * a5))))

fn dry_sat_pt(tdb: r64) -> r64:
    var tt = tdb
    var psat: r64
    
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

fn psat(t: r64) -> r64:
    var dummy = t + 273.15
    var psat_val: r64
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

fn get_stm(longitude: r64) -> r64:
    var longl = List[r64]()
    var longh = List[r64]()
    for i in range(25):
        longl.append(0.0)
        longh.append(0.0)
    
    longl[12] = -7.5
    longh[12] = 7.5
    for i in range(1, 13):
        longl[12 + i] = longl[12 + i - 1] + 15.0
        longh[12 + i] = longh[12 + i - 1] + 15.0
    for i in range(1, 13):
        longl[12 - i] = longl[12 - i + 1] - 15.0
        longh[12 - i] = longh[12 - i + 1] - 15.0
    
    var temp = longitude
    temp = math.fmod(temp, 360.0)
    if temp > 180.0:
        temp = temp - 180.0
    
    for i in range(-12, 13):
        if temp > longl[12 + i] and temp <= longh[12 + i]:
            var tz = Float64(i)
            tz = math.fmod(tz, 24.0)
            return tz
    return -999.0

fn get_loc_data(state: inout EPWReadState) -> Tuple[r64, r64, r64]:
    return (state.Latitude, state.Longitude, state.Elevation)

fn read_epw(input_file: String, state: inout EPWReadState) -> Tuple[Bool, String, Int]:
    var errors_found = False
    var error_message = ""
    var number_of_days = 0
    
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
    
    for count in range(366):
        state.WDay[count] = WeatherDataDetails()
    
    state.NumIntervalsPerHour = 1
    
    state.StdBaroPress = (101.325 * math.pow(1.0 - 2.25577e-05 * state.Elevation, 5.2559)) * 1000.0
    state.Missing.StnPres = state.StdBaroPress
    
    state.NumDays = 0
    var hour = 24
    var interval = state.NumIntervalsPerHour
    
    return (errors_found, error_message, number_of_days)
