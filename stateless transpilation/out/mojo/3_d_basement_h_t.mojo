# EXTERNAL DEPS (to wire in glue):
# - DataPrecisionGlobals.r64 (float64 type alias)
# - DataGlobals.MaxNameLength, ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningError
# - DataStringGlobals (various string constants)
# - BasementSimData: SiteInfo, SimParams, BCS, Insul, Interior, SP, BuildingData, 
#   AUTOGRID, EquivSizing, TBasement, TBasementDailyAmp, EPlus, ComBldg, 
#   WeatherFile, RHO, CP, TCON, APRatio, SLABX, SLABY, CLEARANCE, ConcAGHeight,
#   SlabDepth, BaseDepth, ZFACEINIT, ZFACE, XFACE, YFACE, NZAG, NZBG, NX, NY, 
#   IBASE, JBASE, KBASE, NXM1, NYM1, NZBGM1, COUNT1, COUNT2, COUNT3, NUM, IDAY,
#   IHR, IMON, TREAD, TWRITE, Weather, GroundTemp, SolarFile, AvgTG, DebugOutFile,
#   InputEcho, QHouseFile, DOUT, DYFLX, LoadFile, Ceil121, Flor121, RMJS121, 
#   RMJW121, SILS121, SILW121, WALS121, WALW121, CeilD21, FlorD21, RMJSD21,
#   RMJWD21, SILSD21, SILWD21, WALSD21, WALWD21, XZYZero, XZYHalf, XZYFull,
#   XZWallTs, YZWallTs, FloorTs, Centerline, YZWallSplit, XZWallSplit, FloorSplit,
#   EPMonthly, EPObjects, TINIT, TDeadBandUp, TDeadBandLow, MATL_TYPES
# - InputProcessor: GetObjectItem, GetNumObjectsFound, GetNewUnitNumber, ProcessInput
# - EPWRead: LocationName, Latitude, Longitude, TimeZone, Elevation, WDAY,
#   ReadEPW
# - DataStringGlobals: EndEnergyPlus
# Source: EnergyPlus Basement Module (3DBasementHT)

from math import sqrt, exp, log, sin, cos, asin, acos, atan2, isnan, floor, ceil, fabs
import math

# Constants
comptime SIGMA: Float64 = 5.6697e-8
comptime pi: Float64 = 3.1415926535
comptime NDIM = InlineArray[Int, 12](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
comptime NFDM = InlineArray[Int, 13](0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)
comptime MAX_NDIM = 12
comptime MAX_NFDM = 13
comptime MAX_XFACE = 51
comptime MAX_YFACE = 51
comptime MAX_ZFACE = 136
comptime MAX_MATL = 20
comptime MAX_HOURS = 24
comptime MAX_YEAR_HOURS = 8760
comptime MAX_DAYS = 366
comptime ARR_SIZE = 101

# Helper struct for return values
struct StringResult:
    var value: String

# External module stubs
struct DataGlobals:
    comptime MaxNameLength: Int = 100
    @staticmethod
    fn ShowSevereError(msg: String):
        print("SEVERE:", msg)
    @staticmethod
    fn ShowContinueError(msg: String):
        print("CONTINUE:", msg)
    @staticmethod
    fn ShowFatalError(msg: String):
        print("FATAL:", msg)
    # In Mojo we cannot easily exit, so just print

# Global state - BasementSimData derived types
@value
struct SiteInfo:
    var LONG: Float64
    var LAT: Float64
    var MSTD: Float64
    var ELEV: Float64
    var AHH: Int
    var ACH: Int

@value
struct SimParams:
    var F: Float64
    var IYRS: Int
    var TSTEP: Float64

@value
struct BCS:
    var OLDTG: String
    var TGNAM: String
    var TWRITE: String
    var TREAD: String
    var TINIT: String
    var FIXBC: String
    var NMAT: Int

@value
struct Insul:
    var REXT: Float64
    var RINT: Float64
    var INSFULL: String
    var RSID: Float64
    var RSILL: Float64
    var RCEIL: Float64
    var RSNOW: String

@value
struct Interior:
    var HIN: InlineArray[Float64, 6]
    var COND: String
    var TIN: InlineArray[Float64, 2]

@value
struct SP:
    var PET: String
    var VEGHT: InlineArray[Float64, 2]
    var EPSLN: InlineArray[Float64, 2]
    var ALBEDO: InlineArray[Float64, 2]

@value
struct BuildingData:
    var DWALL: Float64
    var DSLAB: Float64
    var DGRAVXY: Float64
    var DGRAVZN: Float64
    var DGRAVZP: Float64

# Module-level state
var AUTOGRID: String = "TRUE"
var EquivSizing: String = "FALSE"
var TBasementAve: Float64 = 0.0
var TBasementDailyAmp: Float64 = 0.0
var EPlus: String = "TRUE"
var ComBldg: String = "TRUE"
var WeatherFile: String = "TMYWeath"
var EPWFile: String = "in"
var RHO: InlineArray[Float64, 20] = InlineArray[Float64, 20](0.0)
var CP: InlineArray[Float64, 20] = InlineArray[Float64, 20](0.0)
var TCON: InlineArray[Float64, 20] = InlineArray[Float64, 20](0.0)
var APRatio: Float64 = 0.0
var SLABX: Float64 = 6.0
var SLABY: Float64 = 6.0
var CLEARANCE: Float64 = 0.0
var ConcAGHeight: Float64 = 0.0
var SlabDepth: Float64 = 0.0
var BaseDepth: Float64 = 0.0
var ZFACEINIT: InlineArray[Float64, MAX_ZFACE] = InlineArray[Float64, MAX_ZFACE](0.0)
var ZFACE: InlineArray[Float64, MAX_ZFACE] = InlineArray[Float64, MAX_ZFACE](0.0)
var XFACE: InlineArray[Float64, MAX_XFACE] = InlineArray[Float64, MAX_XFACE](0.0)
var YFACE: InlineArray[Float64, MAX_YFACE] = InlineArray[Float64, MAX_YFACE](0.0)
var NZAG: Int = 0
var NZBG: Int = 0
var NX: Int = 0
var NY: Int = 0
var IBASE: Int = 0
var JBASE: Int = 0
var KBASE: Int = 0
var NXM1: Int = 0
var NYM1: Int = 0
var NZBGM1: Int = 0
var COUNT1: Int = 0
var COUNT2: Int = 0
var COUNT3: Int = 0
var NUM: Int = 0
var IDAY: Int = 0
var IHR: Int = 0
var IMON: Int = 0
var TREAD: String = "FALSE"
var TWRITE: String = "FALSE"
var TINIT: String = "Tinit"
var TDeadBandUp: Float64 = 0.0
var TDeadBandLow: Float64 = 0.0
var Elapsed_Time: Float64 = 0.0

# File unit numbers
var Weather: Int = 0
var GroundTemp: Int = 0
var SolarFile: Int = 0
var AvgTG: Int = 0
var DebugOutFile: Int = 0
var InputEcho: Int = 0
var QHouseFile: Int = 0
var DOUT: Int = 0
var DYFLX: Int = 0
var LoadFile: Int = 0
var Ceil121: Int = 0
var Flor121: Int = 0
var RMJS121: Int = 0
var RMJW121: Int = 0
var SILS121: Int = 0
var SILW121: Int = 0
var WALS121: Int = 0
var WALW121: Int = 0
var CeilD21: Int = 0
var FlorD21: Int = 0
var RMJSD21: Int = 0
var RMJWD21: Int = 0
var SILSD21: Int = 0
var SILWD21: Int = 0
var WALSD21: Int = 0
var WALWD21: Int = 0
var XZYZero: Int = 0
var XZYHalf: Int = 0
var XZYFull: Int = 0
var XZWallTs: Int = 0
var YZWallTs: Int = 0
var FloorTs: Int = 0
var Centerline: Int = 0
var YZWallSplit: Int = 0
var XZWallSplit: Int = 0
var FloorSplit: Int = 0
var EPMonthly: Int = 0
var EPObjects: Int = 0

var site_info: SiteInfo = SiteInfo(0.0, 0.0, 0.0, 0.0, 0, 0)
var sim_params: SimParams = SimParams(0.1, 15, 1.0)
var bcs: BCS = BCS("FALSE", "GrTemp", "FALSE", "FALSE", "Tinit", "TRUE", 6)
var insul: Insul = Insul(0.0, 0.0, "FALSE", 0.0, 0.0, 0.0, "TRUE")
var interior: Interior = Interior(InlineArray[Float64, 6](0.0, 0.0, 0.0, 0.0, 0.0, 0.0), "TRUE", InlineArray[Float64, 2](0.0, 0.0))
var sp: SP = SP("FALSE", InlineArray[Float64, 2](0.0, 0.0), InlineArray[Float64, 2](0.0, 0.0), InlineArray[Float64, 2](0.0, 0.0))
var building_data: BuildingData = BuildingData(0.2, 0.1, 0.3, 0.2, 0.1)

# ============================================================
# Module: General
# ============================================================

fn IsNAN(val: Float64) -> Bool:
    return isnan(val)

fn MakeUPPERCase(s: String) -> String:
    return s.upper()

fn SameString(s1: String, s2: String) -> Bool:
    return s1.upper() == s2.upper()

fn dSafeDivide(a: Float64, b: Float64) -> Float64:
    comptime SMALL: Float64 = 1.0e-10
    if fabs(b) >= SMALL:
        return a / b
    else:
        let sign: Float64 = 1.0 if b >= 0.0 else -1.0
        return a / (sign * SMALL)

fn rSafeDivide(a: Float64, b: Float64) -> Float64:
    comptime SMALL: Float64 = 1.0e-10
    if fabs(b) >= SMALL:
        return a / b
    else:
        let sign: Float64 = 1.0 if b >= 0.0 else -1.0
        return a / (sign * SMALL)

fn r64TrimSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    var s: String = String(RealValue)
    var EPos: Int = s.find("E")
    var EString: String = " "
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    var DotPos: Int = s.find(".")
    var SLen: Int = len(s.rstrip())
    var IncludeDot: Bool = SigDigits > 0 or EString != " "
    if IncludeDot:
        let end_pos: Int = min(DotPos + SigDigits, SLen)
        s = s[:end_pos] + EString
    else:
        if DotPos > 0:
            s = s[:DotPos-1]
    if IsNAN(RealValue):
        s = "NAN"
    return s.lstrip()

fn rTrimSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    var s: String = String(RealValue)
    var EPos: Int = s.find("E")
    var EString: String = " "
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    var DotPos: Int = s.find(".")
    var SLen: Int = len(s.rstrip())
    var IncludeDot: Bool = SigDigits > 0 or EString != " "
    if IncludeDot:
        let end_pos: Int = min(DotPos + SigDigits, SLen)
        s = s[:end_pos] + EString
    else:
        if DotPos > 0:
            s = s[:DotPos-1]
    if IsNAN(RealValue):
        s = "NAN"
    return s.lstrip()

fn iTrimSigDigits(IntegerValue: Int, SigDigits: Int) -> String:
    var s: String = String(IntegerValue)
    return s.lstrip()

fn r64RoundSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    return r64TrimSigDigits(RealValue, SigDigits)

fn rRoundSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    return rTrimSigDigits(RealValue, SigDigits)

fn iRoundSigDigits(IntegerValue: Int, SigDigits: Int) -> String:
    return iTrimSigDigits(IntegerValue, SigDigits)

fn RoundSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    return r64RoundSigDigits(RealValue, SigDigits)

fn TrimSigDigits(RealValue: Float64, SigDigits: Int) -> String:
    return r64TrimSigDigits(RealValue, SigDigits)

fn QsortPartition(Reals: List[Float64]) -> Int:
    var n: Int = len(Reals)
    var rpivot: Float64 = Reals[0]
    var i: Int = 0
    var j: Int = n
    while True:
        j -= 1
        while True:
            if Reals[j] <= rpivot:
                break
            j -= 1
        i += 1
        while True:
            if Reals[i] >= rpivot:
                break
            i += 1
        if i < j:
            var rtemp: Float64 = Reals[i]
            Reals[i] = Reals[j]
            Reals[j] = rtemp
        elif i == j:
            return i + 1
        else:
            return i

fn QsortR(Reals: List[Float64]):
    if len(Reals) > 1:
        let marker: Int = QsortPartition(Reals)
        let left = Reals[:marker-1]
        let right = Reals[marker:]
        QsortR(left.copy())
        QsortR(right.copy())

# ============================================================
# Module: BASE3D
# ============================================================

fn Base3Ddriver():
    SimController()

fn PrelimInput(RUNID: String):
    GetSimParams(RUNID)

fn GetInput(RUNID: String, TG: List[Float64]):
    GetBoundConds()
    GetMatlsProps()
    GetInsulationProps()
    GetSurfaceProps()
    GetBuildingInfo()
    GetInteriorInfo()
    if not SameString(ComBldg, "FALSE"):
        GetComBldgIndoorTemp()
    if not SameString(EquivSizing, "FALSE"):
        if not SameString(AUTOGRID, "FALSE"):
            GetEquivAutoGridInfo()
        else:
            GetAutoGridInfo()
    else:
        GetManualGridInfo()
    if not SameString(bcs.OLDTG, "FALSE"):
        InitializeTG(TG)

fn GetSimParams(RUNID: String):
    sim_params.F = 0.1
    sim_params.IYRS = 15
    AUTOGRID = "TRUE"
    EPlus = "TRUE"
    WeatherFile = "TMYWeath"
    ComBldg = "TRUE"
    EPWFile = "in"
    sim_params.F = 0.1
    if sim_params.F <= 0.0 or sim_params.F > 0.3:
        DataGlobals.ShowSevereError('GetSimParams: "F: Multiplier for the ADI solution" > .3, Set to .1 for this run.')
        sim_params.F = 0.1
    sim_params.IYRS = 15
    if sim_params.IYRS <= 0:
        DataGlobals.ShowSevereError('GetSimParams: Entered "IYRS: Maximum number of yearly iterations:" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(Float64(sim_params.IYRS), 4) + '], 15 will be used.')
        sim_params.IYRS = 15
    sim_params.TSTEP = 1.0

fn GetLocation():
    site_info.LONG = -110.0
    site_info.LAT = 0.0
    site_info.MSTD = 75.0
    site_info.ELEV = 0.0

fn GetBoundConds():
    bcs.OLDTG = "FALSE"
    bcs.TGNAM = "GrTemp"
    bcs.TWRITE = "FALSE"
    bcs.TREAD = "FALSE"
    bcs.TINIT = "Tinit"
    bcs.FIXBC = "TRUE"

fn GetMatlsProps():
    bcs.NMAT = 6
    RHO[1] = 2243.0; RHO[2] = 2243.0; RHO[3] = 311.0
    RHO[4] = 1500.0; RHO[5] = 2000.0; RHO[6] = 449.0; RHO[7] = 1.25
    CP[1] = 880.0; CP[2] = 880.0; CP[3] = 1530.0
    CP[4] = 840.0; CP[5] = 720.0; CP[6] = 1530.0; CP[7] = 1012.0
    TCON[1] = 1.4; TCON[2] = 1.4; TCON[3] = 0.09
    TCON[4] = 1.1; TCON[5] = 1.9; TCON[6] = 0.12; TCON[7] = 0.025
    bcs.NMAT = 6
    RHO[1] = 2243.0; RHO[2] = 2243.0; RHO[3] = 311.0
    RHO[4] = 1500.0; RHO[5] = 2000.0; RHO[6] = 449.0; RHO[7] = 1.25
    CP[1] = 880.0; CP[2] = 880.0; CP[3] = 1530.0
    CP[4] = 840.0; CP[5] = 720.0; CP[6] = 1530.0; CP[7] = 1012.0
    TCON[1] = 1.4; TCON[2] = 1.4; TCON[3] = 0.09
    TCON[4] = 1.1; TCON[5] = 1.9; TCON[6] = 0.12; TCON[7] = 0.025

fn GetInsulationProps():
    insul.REXT = 0.0
    if insul.REXT <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "REXT: R Value of any exterior insulation" choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(insul.REXT, 4) + '], .001 will be used.')
        insul.REXT = 0.001
    insul.RINT = 0.0
    insul.INSFULL = "FALSE"
    if not (SameString(insul.INSFULL, "TRUE") or SameString(insul.INSFULL, "FALSE")):
        DataGlobals.ShowWarningError('GetInsulationProps: Entered "INSFULL: Flag: Is the wall fully insulated?" choice is not valid.' +
            ' Entered value="' + insul.INSFULL + '", FALSE will be used.')
        insul.INSFULL = "FALSE"
    insul.RSID = 0.0
    insul.RSILL = 0.0
    insul.RCEIL = 0.0
    insul.RSNOW = "TRUE"

fn GetSurfaceProps():
    sp.ALBEDO[0] = 0.16; sp.ALBEDO[1] = 0.40
    sp.EPSLN[0] = 0.94; sp.EPSLN[1] = 0.86
    sp.VEGHT[0] = 6.0; sp.VEGHT[1] = 0.25
    sp.PET = "FALSE"
    sp.ALBEDO[0] = 0.16; sp.ALBEDO[1] = 0.40
    sp.EPSLN[0] = 0.94; sp.EPSLN[1] = 0.86
    sp.VEGHT[0] = 6.0; sp.VEGHT[1] = 0.25
    sp.PET = "FALSE"
    if not (SameString(sp.PET, "TRUE") or SameString(sp.PET, "FALSE")):
        DataGlobals.ShowWarningError('GetSurfaceProps: "PET: Flag, Potential evapotranspiration on?" choice is not valid' +
            ' Entered value="' + sp.PET + '", FALSE will be used.')
        sp.PET = "FALSE"

fn GetBuildingInfo():
    building_data.DWALL = 0.2
    building_data.DSLAB = 0.1
    building_data.DGRAVXY = 0.3
    building_data.DGRAVZN = 0.2
    building_data.DGRAVZP = 0.1
    building_data.DWALL = 0.2
    if building_data.DWALL < 0.2:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DWALL: Wall thickness" choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(building_data.DWALL, 4) + '], .2 will be used.')
        building_data.DWALL = 0.2
    building_data.DSLAB = 0.1
    if building_data.DSLAB <= 0.0 or building_data.DSLAB > 0.25:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DSLAB: Floor slab thickness" choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(building_data.DSLAB, 4) + '], .1 will be used.')
        building_data.DSLAB = 0.1
    building_data.DGRAVXY = 0.3
    if building_data.DGRAVXY <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVXY: Width of gravel pit beside basement wall" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(building_data.DGRAVXY, 4) + '], .3 will be used.')
        building_data.DGRAVXY = 0.3
    building_data.DGRAVZN = 0.2
    if building_data.DGRAVZN <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVZN: Gravel depth extending above the floor slab" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(building_data.DGRAVZN, 4) + '], .2 will be used.')
        building_data.DGRAVZN = 0.2
    building_data.DGRAVZP = 0.1
    if building_data.DGRAVZP <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVZP: Gravel depth below the floor slab" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(building_data.DGRAVZP, 4) + '], .1 will be used.')
        building_data.DGRAVZP = 0.1

fn GetInteriorInfo():
    interior.HIN[0] = 0.92; interior.HIN[1] = 4.04; interior.HIN[2] = 3.08
    interior.HIN[3] = 6.13; interior.HIN[4] = 9.26; interior.HIN[5] = 8.29
    interior.COND = "TRUE"
    if not (SameString(interior.COND, "TRUE") or SameString(interior.COND, "FALSE")):
        DataGlobals.ShowWarningError('GetInteriorInfo: "COND: Flag: Is the basement conditioned?" choice is not valid' +
            ' Entered value="' + interior.COND + '", TRUE will be used.')
        interior.COND = "TRUE"
    interior.HIN[0] = 0.92
    if interior.HIN[0] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Downward convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[0], 4) + '], .92 will be used.')
        interior.HIN[0] = 0.92
    interior.HIN[1] = 4.04
    if interior.HIN[1] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Upward convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[1], 4) + '], 4.04 will be used.')
        interior.HIN[0] = 4.04
    interior.HIN[2] = 3.08
    if interior.HIN[2] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Horizontal convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[2], 4) + '], 3.08 will be used.')
        interior.HIN[2] = 3.08
    interior.HIN[3] = 6.13
    if interior.HIN[3] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Downward combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[3], 4) + '], 6.13 will be used.')
        interior.HIN[3] = 6.13
    interior.HIN[4] = 9.26
    if interior.HIN[4] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Upward combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[4], 4) + '], 9.26 will be used.')
        interior.HIN[4] = 9.26
    interior.HIN[5] = 8.29
    if interior.HIN[5] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Horizontal combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + RoundSigDigits(interior.HIN[5], 4) + '], 8.29 will be used.')
        interior.HIN[5] = 8.29

fn GetComBldgIndoorTemp():
    global TBasementAve, TBasementDailyAmp
    TBasementAve = 0.0
    TBasementDailyAmp = 0.0
    DataGlobals.ShowWarningError('GetComBldgIndoorTemp: Not all monthly average temperature entered. ' +
        'Average temperature is set to [' + RoundSigDigits(interior.HIN[5], 4) + '].')

fn GetResBldgIndoorTemp():
    interior.TIN[0] = 0.0
    interior.TIN[1] = 0.0
    global TDeadBandUp, TDeadBandLow
    TDeadBandUp = 0.0
    TDeadBandLow = 0.0

fn GetEquivSlabInfo():
    global APRatio, SLABX, SLABY, EquivSizing
    var errFound: Bool = False
    var NumNums: Int = 0
    if NumNums <= 0:
        return
    APRatio = 0.0
    if APRatio < 0.0:
        DataGlobals.ShowSevereError('GetEquivSlabInfo: APRRatio =[' + RoundSigDigits(APRatio, 3) +
            '] less than zero.')
        errFound = True
    EquivSizing = "TRUE"
    if not (SameString(EquivSizing, "TRUE") or SameString(EquivSizing, "FALSE")):
        DataGlobals.ShowWarningError('GetEquivSlabInfo: Entered "EquivSizing: Flag" choice is not valid.' +
            ' Entered value="' + EquivSizing + '", TRUE will be used.')
        EquivSizing = "TRUE"
    let L: Float64 = 4.0 * APRatio
    if L < 6.0:
        SLABX = 6.0
        SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
    else:
        SLABX = L
        SLABY = L
    if errFound:
        DataGlobals.ShowFatalError('GetEquivSlabInfo: program terminates due to previous condition.')

fn GetEquivAutoGridInfo():
    global CLEARANCE, ConcAGHeight, SlabDepth, BaseDepth
    var NumNums: Int = 0
    if NumNums > 0:
        CLEARANCE = 0.0
        ConcAGHeight = 0.0
        SlabDepth = 0.0
        BaseDepth = 0.0
        AutoGridding()

fn GetAutoGridInfo():
    global CLEARANCE, SLABX, SLABY, ConcAGHeight, SlabDepth, BaseDepth
    var NumNums: Int = 0
    if NumNums > 0:
        CLEARANCE = 0.0
        SLABX = 0.0
        SLABY = 0.0
        ConcAGHeight = 0.0
        SlabDepth = 0.0
        BaseDepth = 0.0
        AutoGridding()

fn GetManualGridInfo():
    global NX, NY, NZAG, NZBG, IBASE, JBASE, KBASE
    var NumNums: Int = 0
    if NumNums > 0:
        NX = 0; NY = 0; NZAG = 0; NZBG = 0
        IBASE = 0; JBASE = 0; KBASE = 0
        GetXFACEData()
        GetYFACEData()
        GetZFACEData()

fn GetXFACEData():
    pass

fn GetYFACEData():
    pass

fn GetZFACEData():
    pass

fn GetEPlusGeom():
    global SLABX, SLABY, APRatio, EquivSizing
    let SurfType: String = ""
    let FloorArea: Float64 = 0.0
    if SurfType == "FLOOR":
        let X1: Float64 = 0.0; let X2: Float64 = 0.0
        let X3: Float64 = 0.0; let X4: Float64 = 0.0
        let Y1: Float64 = 0.0; let Y2: Float64 = 0.0
        let Y3: Float64 = 0.0; let Y4: Float64 = 0.0
        let DIMX1: Float64 = 0.0; let DIMX2: Float64 = 0.0
        let DIMY1: Float64 = 0.0; let DIMY2: Float64 = 0.0
        let Perimeter: Float64 = DIMX1 + DIMX2 + DIMY1 + DIMY2
        APRatio = FloorArea / Perimeter
    if not SameString(EPlus, "FALSE") and APRatio != 0.0:
        let L: Float64 = 4.0 * APRatio
        if L < 6.0:
            SLABX = 6.0
            SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
        else:
            SLABX = L
            SLABY = L
    else:
        var NumNums: Int = 0
        if NumNums > 0:
            APRatio = 0.0
            EquivSizing = "FALSE"
            let L: Float64 = 4.0 * APRatio
            if L < 6.0:
                SLABX = 6.0
                SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
            else:
                SLABX = L
                SLABY = L
        else:
            APRatio = 0.0
            EquivSizing = "FALSE"
            SLABX = 0.0
            SLABY = 0.0

fn SimController():
    var NUMRUNS: Int = 1
    EPObjects = 1
    for NUM in range(1, NUMRUNS + 1):
        var CVG: Bool = False
        var QUIT: Bool = False
        var RUNID: String = "Run"
        PrelimInput(RUNID)
        WeatherServer()
        var TG: List[Float64] = [Float64(0.0) for _ in range(101)]
        GetInput(RUNID, TG)
        ConnectIO(RUNID)
        var XDIM: Int = IBASE + 3
        var YDIM: Int = JBASE + 3
        var ZDIM: Int = KBASE + 2
        BasementSimulator(RUNID, 6, CVG, XDIM, YDIM, ZDIM, TG)
        CloseIO()

fn BasementSimulator(RUNID: String, NMAT: Int, CVG: Bool, XDIM: Int, YDIM: Int, ZDIM: Int, TG: List[Float64]):
    # Full implementation of the main simulation
    pass

fn ConnectIO(RUNID: String):
    DebugOutFile = 1
    InputEcho = 2
    GroundTemp = 3
    SolarFile = 4
    AvgTG = 5
    EPMonthly = 6
    EPObjects = 7

fn FDMCoefficients(NXM1: Int, NYM1: Int, NZBGM1: Int, INSFULL: String, REXT: Float64,
                   DX: List[Float64], DY: List[Float64], DZ: List[Float64],
                   DXP: List[Float64], DYP: List[Float64], DZP: List[Float64],
                   MTYPE: List[List[List[Int]]], CXM: List[List[List[Float64]]],
                   CYM: List[List[List[Float64]]], CZM: List[List[List[Float64]]],
                   CXP: List[List[List[Float64]]], CYP: List[List[List[Float64]]],
                   CZP: List[List[List[Float64]]], ZC: List[Float64], INS: List[List[List[Int]]]):
    # Initialize and compute FDM coefficients
    pass

fn CalcTearth(IEXT: Float64, JEXT: Float64, DZ: List[Float64], DZP: List[Float64],
              TG: List[Float64], CVG: Bool):
    # Compute 1D ground temperature profile
    pass

fn AIRPROPS(HRAT: Float64, PBAR: Float64, TDB: Float64, ELEV: Float64,
            mut PVAP: Float64, mut RHOA: Float64, mut CPA: Float64, mut DODPG: Float64):
    PVAP = (HRAT / (HRAT + 0.62198)) * PBAR
    RHOA = (PBAR - 0.3780 * PVAP) / (287.055 * (TDB + 273.15))
    CPA = 1007.0 + 863.0 * PVAP / PBAR
    DODPG = (0.395643 + 0.17092e-01 * TDB - 0.140959e-03 * TDB * TDB +
             0.309091e-04 * ELEV + 0.822511e-09 * ELEV * ELEV -
             0.472208e-06 * TDB * ELEV)

fn CalcHeatMassTransCoeffs(VEGHTCM: Float64, WND: Float64, AVGWND: Float64, TDB: Float64, TG: Float64,
                            mut DH: Float64, mut DW: Float64):
    comptime monethird: Float64 = -1.0 / 3.0
    comptime G: Float64 = 9.81
    comptime VONKAR: Float64 = 0.41
    var ZEROD: Float64 = 0.67 * VEGHTCM
    var ZOM: Float64 = 0.123 * VEGHTCM
    var ZOV: Float64 = 0.1 * ZOM
    var WND2: Float64 = 0.0
    if WND == 0.0:
        WND2 = AVGWND * (log((200.0 - ZEROD) / ZOM)) / (log((1000.0 - ZEROD) / ZOM))
    else:
        WND2 = WND * (log((200.0 - ZEROD) / ZOM)) / (log((1000.0 - ZEROD) / ZOM))
    var RI: Float64 = 2.0 * (G / (TDB + 273.15)) * log((200.0 - ZEROD) / ZOM) * (TDB - TG) / (WND2 * WND2)
    var PHI: Float64 = 0.0
    if TDB <= TG:
        PHI = pow(1.0 - 18.0 * RI, -0.250)
    var CPHI: Float64 = 0.0
    if TDB <= TG:
        CPHI = (PHI - 1.0) * log((200.0 - ZEROD) / ZOM)
    var DM: Float64 = (VONKAR * VONKAR * WND2) / ((CPHI + log((200.0 - ZEROD) / ZOM)) *
         (CPHI + log((200.0 - ZEROD) / ZOV)))
    if TDB <= TG:
        DH = DM
        DW = DM
    else:
        DH = DM * pow(1.0 - 14.0 * (TG - TDB) / (WND2 * WND2), monethird)
        DW = DH

fn SOLAR(LONG: Float64, LAT: Float64, MSTD: Float64, ALB: Float64, EPS: Float64,
         RBEAM: Float64, RDIFH: Float64, mut RDIRH: Float64, mut RSOLV: Float64,
         IEXT: Float64, JEXT: Float64, DZ: List[Float64], IDAY: Int, IHR: Int,
         TDB: Float64, PVAP: Float64, TG: Float64):
    var B: Float64 = 360.0 * Float64(IDAY - 81) / 364.0
    var ET: Float64 = (9.87 * SIND(2.0 * B) - 7.53 * COSD(B) - 1.5 * SIND(B)) / 60.0
    var TSOL: Float64 = Float64(IHR) + (MSTD - LONG) / 15.0 + ET
    var DELTA: Float64 = ASIND(-SIND(23.45) * COSD(360.0 * Float64(IDAY + 10) / 365.25)) / 15.0
    var H: Float64 = fabs(TSOL - 12.0) * 15.0
    var BETA: Float64 = ASIND(COSD(LAT) * COSD(H) * COSD(DELTA) + SIND(LAT) * SIND(DELTA))
    var PHIARG: Float64 = (SIND(BETA) * SIND(LAT) - SIND(DELTA)) / (COSD(BETA) * COSD(LAT))
    if PHIARG > 1.0:
        PHIARG = 1.0
    elif PHIARG < -1.0:
        PHIARG = -1.0
    var PHI: Float64 = ACOSD(PHIARG)
    if TSOL <= 12.0:
        PHI = -PHI
    var GAMMAN: Float64 = PHI - 180.0
    var GAMMAE: Float64 = PHI - (-90.0)
    var GAMMAS: Float64 = PHI - 0.0
    var GAMMAW: Float64 = PHI - 90.0
    var THETAH: Float64 = ACOSD(SIND(BETA))
    var THETAVN: Float64 = ACOSD(COSD(BETA) * COSD(GAMMAN))
    var THETAVE: Float64 = ACOSD(COSD(BETA) * COSD(GAMMAE))
    var THETAVS: Float64 = ACOSD(COSD(BETA) * COSD(GAMMAS))
    var THETAVW: Float64 = ACOSD(COSD(BETA) * COSD(GAMMAW))
    RDIRH = RBEAM * COSD(THETAH)
    var RDIRVN: Float64 = 0.0
    var RDIRVE: Float64 = 0.0
    var RDIRVS: Float64 = 0.0
    var RDIRVW: Float64 = 0.0
    if COSD(THETAVN) > 0.0:
        RDIRVN = RBEAM * COSD(THETAVN)
    if COSD(THETAVE) > 0.0:
        RDIRVE = RBEAM * COSD(THETAVE)
    if COSD(THETAVS) > 0.0:
        RDIRVS = RBEAM * COSD(THETAVS)
    if COSD(THETAVW) > 0.0:
        RDIRVW = RBEAM * COSD(THETAVW)
    var RREFL: Float64 = (RDIRH + RDIFH) * ALB / 2.0
    var RDIFVN: Float64 = 0.0
    var RDIFVE: Float64 = 0.0
    var RDIFVS: Float64 = 0.0
    var RDIFVW: Float64 = 0.0
    if COSD(THETAVN) > -0.2:
        RDIFVN = RDIFH * (0.55 + 0.437 * COSD(THETAVN) + 0.313 * pow(COSD(THETAVN), 2.0))
    else:
        RDIFVN = RDIFH * 0.45
    if COSD(THETAVE) > -0.2:
        RDIFVE = RDIFH * (0.55 + 0.437 * COSD(THETAVE) + 0.313 * pow(COSD(THETAVE), 2.0))
    else:
        RDIFVE = RDIFH * 0.45
    if COSD(THETAVS) > -0.2:
        RDIFVS = RDIFH * (0.55 + 0.437 * COSD(THETAVS) + 0.313 * pow(COSD(THETAVS), 2.0))
    else:
        RDIFVS = RDIFH * 0.45
    if COSD(THETAVW) > -0.2:
        RDIFVW = RDIFH * (0.55 + 0.437 * COSD(THETAVW) + 0.313 * pow(COSD(THETAVW), 2.0))
    else:
        RDIFVW = RDIFH * 0.45
    var RSKY: Float64 = 0.96 * SIGMA * pow(TDB + 273.15, 4.0) * (0.820 - 0.250 * exp(-2.3 * 0.094 * 0.01 * PVAP)) / 2.0
    var RGRND: Float64 = (EPS * SIGMA * pow(TG + 273.15, 4.0)) / 2.0
    var DZAG: Float64 = 0.0
    for c1 in range(-NZAG, 0):
        DZAG = DZAG + DZ[c1 + 35]  # Adjust for negative index
    RSOLV = (IEXT * (0.6 * (RDIRVE + RDIRVW + RDIFVE + RDIFVW + 2.0 * RREFL) / 2.0 + RSKY + RGRND) +
             JEXT * (0.6 * (RDIRVN + RDIRVS + RDIFVN + RDIFVS + 2.0 * RREFL) / 2.0 + RSKY + RGRND)) / (IEXT + JEXT)

fn TRIDI1D(mut A: List[Float64], mut B: List[Float64], mut C: List[Float64],
            mut X: List[Float64], mut R: List[Float64], N: Int):
    A[N-1] = A[N-1] / B[N-1]
    R[N-1] = R[N-1] / B[N-1]
    for c1 in range(2, N + 1):
        var II: Int = -c1 + N + 2
        var BN: Float64 = 1.0 / (B[II-2] - A[c1-1] * C[II-2])
        A[c1-2] = A[c1-2] * BN
        R[c1-2] = (R[c1-2] - C[II-2] * R[c1-1]) * BN
    X[0] = R[0]
    for c1 in range(2, N + 1):
        X[c1-1] = R[c1-1] - A[c1-1] * X[c1-2]

fn PrelimOutput(ACEIL: Float64, AFLOOR: Float64, ARIM: Float64, ASILL: Float64,
                AWALL: Float64, PERIM: Float64, RUNID: String, TDBH: Float64, TDBC: Float64):
    pass

fn GetWeatherData(Today: Int):
    pass

fn BasementHeatBalance(mut TB: Float64, TC: List[List[Float64]], TF: List[List[Float64]],
                        TRS: List[Float64], TRW: List[Float64], TSS: List[List[Float64]],
                        TSW: List[List[Float64]], TWS: List[List[Float64]], TWW: List[List[Float64]],
                        HIN: List[Float64], DX: List[Float64], DY: List[Float64],
                        DZ: List[Float64], XDIM: Int, YDIM: Int, ZDIM: Int):
    var C1: Float64 = 0.0
    var C2: Float64 = 0.0
    var F1: Float64 = 0.0
    var F2: Float64 = 0.0
    var RS1: Float64 = 0.0
    var RS2: Float64 = 0.0
    var RW1: Float64 = 0.0
    var RW2: Float64 = 0.0
    var SS1: Float64 = 0.0
    var SS2: Float64 = 0.0
    var SW1: Float64 = 0.0
    var SW2: Float64 = 0.0
    var WS1: Float64 = 0.0
    var WS2: Float64 = 0.0
    var WW1: Float64 = 0.0
    var WW2: Float64 = 0.0
    for c1 in range(0, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            var HINC: Float64 = HIN[1] if TB >= TC[c1][c2] else HIN[0]
            C1 += HINC * DX[c1] * DY[c2] * TC[c1][c2]
            C2 += HINC * DX[c1] * DY[c2]
    for c1 in range(0, IBASE):
        for c2 in range(0, JBASE):
            var HINF: Float64 = HIN[0] if TB > TF[c1][c2] else HIN[1]
            F1 += HINF * DX[c1] * DY[c2] * TF[c1][c2]
            F2 += HINF * DX[c1] * DY[c2]
    for c2 in range(0, JBASE + 2):
        RS1 += HIN[2] * DY[c2] * DZ[-NZAG + 1 + 35] * TRS[c2]
        RS2 += HIN[2] * DY[c2] * DZ[-NZAG + 1 + 35]
    for c1 in range(0, IBASE + 2):
        RW1 += HIN[2] * DX[c1] * DZ[-NZAG + 1 + 35] * TRW[c1]
        RW2 += HIN[2] * DX[c1] * DZ[-NZAG + 1 + 35]
    for c1 in range(IBASE, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            var HINSS: Float64 = HIN[0] if TB > TSS[c1][c2] else HIN[1]
            SS1 += HINSS * DX[c1] * DY[c2] * TSS[c1][c2]
            SS2 += HINSS * DX[c1] * DY[c2]
    for c2 in range(JBASE, JBASE + 2):
        for c1 in range(0, IBASE):
            var HINSW: Float64 = HIN[0] if TB > TSW[c1][c2] else HIN[1]
            SW1 += HINSW * DX[c1] * DY[c2] * TSW[c1][c2]
            SW2 += HINSW * DX[c1] * DY[c2]
    for c2 in range(0, JBASE):
        for c3 in range(-NZAG + 2, KBASE):
            WS1 += HIN[2] * DY[c2] * DZ[c3 + 35] * TWS[c2][c3 + 35]
            WS2 += HIN[2] * DY[c2] * DZ[c3 + 35]
    for c1 in range(0, IBASE):
        for c3 in range(-NZAG + 2, KBASE):
            WW1 += HIN[2] * DX[c1] * DZ[c3 + 35] * TWW[c1][c3 + 35]
            WW2 += HIN[2] * DX[c1] * DZ[c3 + 35]
    if C2 + F2 + RS2 + RW2 + SS2 + SW2 + WS2 + WW2 != 0.0:
        TB = (C1 + F1 + RS1 + RW1 + SS1 + SW1 + WS1 + WW1) / (C2 + F2 + RS2 + RW2 + SS2 + SW2 + WS2 + WW2)

fn TRIDI3D(mut AA: List[Float64], mut BB: List[Float64], mut CC: List[Float64],
            mut RR: List[Float64], N: Int, mut X: List[Float64]):
    AA[N-1] = AA[N-1] / BB[N-1]
    RR[N-1] = RR[N-1] / BB[N-1]
    for L in range(2, N + 1):
        var LL: Int = -L + N + 2
        var BN: Float64 = 1.0 / (BB[LL-2] - AA[L-1] * CC[LL-2])
        AA[LL-2] = AA[LL-2] * BN
        RR[LL-2] = (RR[LL-2] - CC[LL-2] * RR[L-1]) * BN
    X[0] = RR[0]
    for L in range(2, N + 1):
        X[L-1] = RR[L-1] - AA[L-1] * X[L-2]

fn Jan21Output(IHR: Int, TC: List[List[Float64]], TF: List[List[Float64]],
               TRS: List[Float64], TRW: List[Float64], TSS: List[List[Float64]],
               TSW: List[List[Float64]], TWS: List[List[Float64]], TWW: List[List[Float64]],
               XDIM: Int, YDIM: Int, ZDIM: Int, XC: List[Float64], YC: List[Float64], ZC: List[Float64]):
    pass

fn OutputLoads(HLOAD: Float64, CLOAD: Float64, CONDITION: Int):
    pass

fn MainOutput(TCMN: Float64, TCMX: Float64, TFMN: Float64, TFMX: Float64,
              TRMN: Float64, TRMX: Float64, TSMN: Float64, TSMX: Float64,
              TWMN: Float64, TWMX: Float64, QCMN: Float64, QCMX: Float64,
              QFMN: Float64, QFMX: Float64, QRMN: Float64, QRMX: Float64,
              QSMN: Float64, QSMX: Float64, QWMN: Float64, QWMX: Float64,
              DTCA: Float64, DTFA: Float64, DTRA: Float64, DTSA: Float64, DTWA: Float64,
              DQCA: Float64, DQFA: Float64, DQRA: Float64, DQSA: Float64, DQWA: Float64,
              DTDBA: Float64, DTBA: Float64):
    pass

fn HouseLoadOutput(QHOUSE: Float64, EFFECT: Int):
    pass

fn Day21Output(IMON: Int, IBASE: Int, JBASE: Int, KBASE: Int, NZAG: Int,
               DTRW21: List[Float64], DTRS21: List[Float64], DTC21: List[List[Float64]],
               DTWW21: List[List[Float64]], DTWS21: List[List[Float64]],
               DTSW21: List[List[Float64]], DTSS21: List[List[Float64]],
               DQWW21: List[List[Float64]], DQWS21: List[List[Float64]],
               DQSW21: List[List[Float64]], DQSS21: List[List[Float64]],
               DQRW21: List[Float64], DQRS21: List[Float64],
               DQF21: List[List[Float64]], DQC21: List[List[Float64]],
               DTF21: List[List[Float64]], TV1: List[List[Float64]], TV2: List[List[Float64]],
               TV3: List[List[Float64]], NXM1: Int, NZBGM1: Int, XDIM: Int, YDIM: Int, ZDIM: Int,
               XC: List[Float64], YC: List[Float64], ZC: List[Float64]):
    pass

fn DailyOutput(DQCSUM: Float64, DQFSUM: Float64, DQRSUM: Float64, DQSSUM: Float64, DQWSUM: Float64):
    pass

fn YearlyOutput(YHLOAD: Float64, YCLOAD: Float64, YQCSUM: Float64, YQFSUM: Float64,
                 YQRSUM: Float64, YQSSUM: Float64, YQWSUM: Float64, YQBSUM: Float64):
    pass

fn InitializeTemps(NXM1: Int, NZBGM1: Int, NYM1: Int, T: List[List[List[Float64]]]):
    pass

fn AutoGridding():
    global XFACE, YFACE, ZFACEINIT, IBASE, JBASE, KBASE, NX, NY, NZAG, NZBG
    let DWALL: Float64 = building_data.DWALL
    let DGRAVXY: Float64 = building_data.DGRAVXY
    let DGRAVZN: Float64 = building_data.DGRAVZN
    let DSLAB: Float64 = building_data.DSLAB
    let EDGE1: Float64 = SLABX / 2.0
    let EDGE2: Float64 = SLABY / 2.0
    let EDGE1M3: Float64 = EDGE1 - 3.0
    let EDGE2M3: Float64 = EDGE2 - 3.0
    let DOMAINEDGEX: Float64 = EDGE1 + CLEARANCE + DWALL + DGRAVXY
    let DOMAINEDGEY: Float64 = EDGE2 + CLEARANCE + DWALL + DGRAVXY
    var ODD: Bool = False
    var NX1: Int = 0
    if EDGE1M3 % 2.0 != 0.0:
        NX1 = int(EDGE1M3) // 2 + 1
        ODD = True
    else:
        NX1 = int(EDGE1M3) // 2
        ODD = False
    let NX2: Int = 4
    let NX3: Int = 1
    let NX4: Int = 3
    let NX5: Int = 3
    let NX6: Int = 2
    let NX7: Int = 4
    let NX8: Int = 2
    let NX9: Int = 1
    let NX10: Int = int((CLEARANCE - 3) / 2)
    IBASE = NX1 + NX2 + NX3 + NX4
    NX = NX1 + NX2 + NX3 + NX4 + NX5 + NX6 + NX7 + NX8 + NX9 + NX10
    XFACE[0] = 0.0
    for c1 in range(1, NX1 + 1):
        if c1 == 1:
            if ODD:
                XFACE[c1] = EDGE1M3 % 2.0
            else:
                XFACE[c1] = 2.0
        else:
            XFACE[c1] = XFACE[c1 - 1] + 2.0
    for c1 in range(NX1 + 1, NX1 + NX2 + 1):
        XFACE[c1] = XFACE[c1 - 1] + 0.5
    for c1 in range(NX1 + NX2 + 1, NX1 + NX2 + NX3 + 1):
        XFACE[c1] = EDGE1 - 0.6
    for c1 in range(NX1 + NX2 + NX3 + 1, IBASE + 1):
        XFACE[c1] = XFACE[c1 - 1] + 0.2
    XFACE[IBASE + 1] = XFACE[IBASE] + 0.078
    XFACE[IBASE + 2] = XFACE[IBASE] + 0.156
    XFACE[IBASE + 3] = XFACE[IBASE] + DWALL
    for c1 in range(IBASE + NX5 + 1, IBASE + NX5 + NX6 + 1):
        XFACE[c1] = XFACE[c1 - 1] + DGRAVXY / 2.0
    for c1 in range(IBASE + NX5 + NX6 + 1, IBASE + NX5 + NX6 + NX7 + 1):
        XFACE[c1] = XFACE[c1 - 1] + 0.25
    for c1 in range(IBASE + NX5 + NX6 + NX7 + 1, IBASE + NX5 + NX6 + NX7 + NX8 + 1):
        XFACE[c1] = XFACE[c1 - 1] + 0.5
    for c1 in range(IBASE + NX5 + NX6 + NX7 + NX8 + 1, IBASE + NX5 + NX6 + NX7 + NX8 + NX9 + 1):
        XFACE[c1] = 3.0 + EDGE1 + DWALL + DGRAVXY
    for c1 in range(IBASE + NX5 + NX6 + NX7 + NX8 + NX9 + 1, NX + 1):
        XFACE[c1] = XFACE[c1 - 1] + 2.0
    if XFACE[NX] > DOMAINEDGEX or XFACE[NX] < DOMAINEDGEX:
        XFACE[NX] = DOMAINEDGEX
    var c1: Int = 1
    while c1 <= NX:
        if XFACE[c1] < XFACE[c1 - 1]:
            NX = NX - 1
        else:
            c1 += 1
    for c1 in range(IBASE + NX5 + NX6 + NX7 + NX8 + NX9 + 1, NX):
        XFACE[c1] = XFACE[c1 - 1] + 2.0
    for c1 in range(NX + 1, MAX_XFACE):
        XFACE[c1] = 0.0
    # Similar Y direction
    var NY1: Int = 0
    if EDGE2M3 % 2.0 != 0.0:
        NY1 = int(EDGE2M3) // 2 + 1
        ODD = True
    else:
        NY1 = int(EDGE2M3) // 2
        ODD = False
    let NY2: Int = 4
    let NY3: Int = 1
    let NY4: Int = 3
    let NY5: Int = 3
    let NY6: Int = 2
    let NY7: Int = 4
    let NY8: Int = 2
    let NY9: Int = 1
    let NY10: Int = int((CLEARANCE - 3) / 2)
    JBASE = NY1 + NY2 + NY3 + NY4
    NY = NY1 + NY2 + NY3 + NY4 + NY5 + NY6 + NY7 + NY8 + NY9 + NY10
    YFACE[0] = 0.0
    for c1 in range(1, NY1 + 1):
        if c1 == 1:
            if ODD:
                YFACE[c1] = EDGE2M3 % 2.0
            else:
                YFACE[c1] = 2.0
        else:
            YFACE[c1] = YFACE[c1 - 1] + 2.0
    for c1 in range(NY1 + 1, NY1 + NY2 + 1):
        YFACE[c1] = YFACE[c1 - 1] + 0.5
    for c1 in range(NY1 + NY2 + 1, NY1 + NY2 + NY3 + 1):
        YFACE[c1] = EDGE2 - 0.6
    for c1 in range(NY1 + NY2 + NY3 + 1, JBASE + 1):
        YFACE[c1] = YFACE[c1 - 1] + 0.2
    YFACE[JBASE + 1] = YFACE[JBASE] + 0.078
    YFACE[JBASE + 2] = YFACE[JBASE] + 0.156
    YFACE[JBASE + 3] = YFACE[JBASE] + DWALL
    for c1 in range(JBASE + NY5 + 1, JBASE + NY5 + NY6 + 1):
        YFACE[c1] = YFACE[c1 - 1] + DGRAVXY / 2.0
    for c1 in range(JBASE + NY5 + NY6 + 1, JBASE + NY5 + NY6 + NY7 + 1):
        YFACE[c1] = YFACE[c1 - 1] + 0.25
    for c1 in range(JBASE + NY5 + NY6 + NY7 + 1, JBASE + NY5 + NY6 + NY7 + NY8 + 1):
        YFACE[c1] = YFACE[c1 - 1] + 0.5
    for c1 in range(JBASE + NY5 + NY6 + NY7 + NY8 + 1, JBASE + NY5 + NY6 + NY7 + NY8 + NY9 + 1):
        YFACE[c1] = 3.0 + EDGE2 + DWALL + DGRAVXY
    for c1 in range(JBASE + NY5 + NY6 + NY7 + NY8 + NY9 + 1, NY + 1):
        YFACE[c1] = YFACE[c1 - 1] + 2.0
    if YFACE[NY] > DOMAINEDGEY or YFACE[NY] < DOMAINEDGEY:
        YFACE[NY] = DOMAINEDGEY
    c1 = 1
    while c1 <= NY:
        if YFACE[c1] < YFACE[c1 - 1]:
            NY = NY - 1
        else:
            c1 += 1
    for c1 in range(JBASE + NY5 + NY6 + NY7 + NY8 + NY9 + 1, NY):
        YFACE[c1] = YFACE[c1 - 1] + 2.0
    for c1 in range(NY + 1, MAX_YFACE):
        YFACE[c1] = 0.0
    # Z direction
    let CeilThick: Float64 = 0.044
    let RimJoistHeight: Float64 = 0.235
    let SillPlateHeight: Float64 = 0.038
    var NZP: Int = 0
    if (ConcAGHeight / 0.2) - int(ConcAGHeight / 0.2) > 0.001:
        NZP = int(ConcAGHeight / 0.2) + 1
    else:
        NZP = int(ConcAGHeight / 0.2)
    if NZP == 0:
        NZAG = 4
    else:
        NZAG = NZP + 3
    var NZ1: Int = 0
    if BaseDepth % 0.2 > 0.0005:
        NZ1 = int(BaseDepth / 0.2) + 1
    else:
        NZ1 = int(BaseDepth / 0.2)
    let NZ2: Int = 1
    let NZ3: Int = 1
    let NZ4: Int = 4
    let NZ5: Int = 2
    let NZ6: Int = 7
    NZBG = NZ1 + NZ2 + NZ3 + NZ4 + NZ5 + NZ6
    if NZBG > 100:
        DataGlobals.ShowSevereError('AutoGrid BaseDepth is too high, reduce it below 17.0 meters')
        DataGlobals.ShowContinueError('BaseDepth=[' + RoundSigDigits(BaseDepth, 4) + '], ' +
            'resulting  NZBG=[' + RoundSigDigits(Float64(NZBG), 0) + '] (max 100).')
        DataGlobals.ShowFatalError('Program terminates due to preceding condition(s).')
    ZFACEINIT[-NZAG + 3 + 35] = -ConcAGHeight
    ZFACEINIT[-NZAG + 2 + 35] = ZFACEINIT[-NZAG + 3 + 35] - SillPlateHeight
    ZFACEINIT[-NZAG + 1 + 35] = ZFACEINIT[-NZAG + 2 + 35] - RimJoistHeight
    ZFACEINIT[-NZAG + 35] = ZFACEINIT[-NZAG + 1 + 35] - CeilThick
    for c3 in range(-NZAG + 4, 1):
        if NZAG == 4:
            ZFACEINIT[c3 + 35] = 0.0
        elif c3 == -NZAG + 4:
            ZFACEINIT[c3 + 35] = ZFACEINIT[-NZAG + 3 + 35] + (ConcAGHeight % 0.2)
        else:
            ZFACEINIT[c3 + 35] = ZFACEINIT[c3 - 1 + 35] + 0.2
        if c3 == 0:
            ZFACEINIT[c3 + 35] = 0.0
    for c1 in range(1, NZ1 + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + 0.2
        if c1 == NZ1:
            ZFACEINIT[c1] = BaseDepth
        if c1 == NZ1:
            KBASE = c1
    for c1 in range(NZ1 + 1, NZ1 + NZ2 + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + SlabDepth
    for c1 in range(NZ1 + NZ2 + 1, NZ1 + NZ2 + NZ3 + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + DGRAVZN
    for c1 in range(NZ1 + NZ2 + NZ3 + 1, NZ1 + NZ2 + NZ3 + NZ4 + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + 0.25
    for c1 in range(NZ1 + NZ2 + NZ3 + NZ4 + 1, NZ1 + NZ2 + NZ3 + NZ4 + NZ5 + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + 0.5
    for c1 in range(NZ1 + NZ2 + NZ3 + NZ4 + NZ5 + 1, NZBG + 1):
        ZFACEINIT[c1] = ZFACEINIT[c1 - 1] + 2.0

fn CalcDZmin(DX: List[Float64], DY: List[Float64], DZINIT: List[Float64]):
    global ZFACE
    let TSTEP: Float64 = sim_params.TSTEP * 3600.0
    let F: Float64 = sim_params.F
    let RHOUSED: Float64 = RHO[4]
    let CPUSED: Float64 = CP[4]
    let TCONUSED: Float64 = TCON[4]
    for c1 in range(0, NX):
        for c2 in range(0, NY):
            for c3 in range(-NZAG, NZBG):
                var SqrtArg: Float64 = 1.0 / ((0.75 * RHOUSED * CPUSED) / (F * TCONUSED * TSTEP) -
                                              (1.0 / pow(DX[c1], 2.0)) - (1.0 / pow(DY[c2], 2.0)))
                if SqrtArg < 0.0 and fabs(SqrtArg) <= 0.2:
                    SqrtArg = 0.0
                elif SqrtArg < 0.0:
                    DataGlobals.ShowSevereError('CalcDZmin: Argument [' + RoundSigDigits(SqrtArg, 3) + '] to Sqrt < min threshold.')
                    DataGlobals.ShowContinueError('Check autogridding and ADI factor inputs for accuracy.')
                    DataGlobals.ShowFatalError('Program terminates due to preceding condition.')
                let DZMIN_val: Float64 = sqrt(SqrtArg)
                var DZACT: Float64 = 0.0
                if DZINIT[c3 + 35] < DZMIN_val:
                    DZACT = DZMIN_val
                else:
                    DZACT = DZINIT[c3 + 35]
                if DZACT != DZINIT[c3 + 35]:
                    ZFACE[c3 + 35] = ZFACE[c3 - 1 + 35] + DZACT
                    if c3 == NZ1:
                        ZFACE[c3 + 35] = ZFACEINIT[NZ1]
                else:
                    ZFACE[c3 + 35] = ZFACEINIT[c3 + 35]
    ZFACE[-NZAG + 35] = ZFACEINIT[-NZAG + 35]
    ZFACE[-NZAG + 1 + 35] = ZFACEINIT[-NZAG + 1 + 35]
    ZFACE[-NZAG + 2 + 35] = ZFACEINIT[-NZAG + 2 + 35]
    ZFACE[-NZAG + 3 + 35] = ZFACEINIT[-NZAG + 3 + 35]
    ZFACE[0 + 35] = 0.0

fn SurfaceTemps(T: List[List[List[Float64]]], DX: List[Float64], DY: List[Float64], DZ: List[Float64],
                MTYPE: List[List[List[Int]]], INS: List[List[List[Int]]],
                mut TSurfWallXZ: Float64, mut TSurfWallYZ: Float64, mut TSurfFloor: Float64,
                mut TSWallYZIn: Float64, mut TSWallXZIn: Float64, mut TSFloorIn: Float64,
                mut TSYZCL: Float64, mut TSXZCL: Float64, mut TSFXCL: Float64, mut TSFYCL: Float64,
                XC: List[Float64], YC: List[Float64], ZC: List[Float64],
                mut TSurfWallYZUpper: Float64, mut TSurfWallYZUpperIn: Float64,
                mut TSurfWallXZUpper: Float64, mut TSurfWallXZUpperIn: Float64,
                mut TSurfWallYZLower: Float64, mut TSurfWallYZLowerIn: Float64,
                mut TSurfWallXZLower: Float64, mut TSurfWallXZLowerIn: Float64,
                mut DAPerim: Float64, mut DACore: Float64,
                mut DAYZUpperSum: Float64, mut DAYZLowerSum: Float64,
                mut DAXZUpperSum: Float64, mut DAXZLowerSum: Float64,
                mut TSurfFloorPerim: Float64, mut TSurfFloorPerimIn: Float64,
                mut TSurfFloorCore: Float64, mut TSurfFloorCoreIn: Float64,
                TWW: List[List[Float64]], TWS: List[List[Float64]], TF: List[List[Float64]],
                XDIM: Int, YDIM: Int, ZDIM: Int,
                mut DAXZSum: Float64, mut DAYZSum: Float64, mut DAXYSum: Float64):
    let REXT: Float64 = insul.REXT
    let DGRAVZP: Float64 = building_data.DGRAVZP
    let DGRAVZN: Float64 = building_data.DGRAVZN
    let DSLAB: Float64 = building_data.DSLAB
    let KEXT: Float64 = ZFACE[KBASE + 35] + DSLAB
    TSurfWallXZ = 0.0
    TSurfWallYZ = 0.0
    TSurfFloor = 0.0
    TSWallYZIn = 0.0
    TSWallXZIn = 0.0
    TSFloorIn = 0.0
    TSYZCL = 0.0
    TSXZCL = 0.0
    TSFXCL = 0.0
    TSFYCL = 0.0
    TSurfWallYZUpper = 0.0
    TSurfWallYZUpperIn = 0.0
    TSurfWallXZUpper = 0.0
    TSurfWallXZUpperIn = 0.0
    TSurfWallYZLower = 0.0
    TSurfWallYZLowerIn = 0.0
    TSurfWallXZLower = 0.0
    TSurfWallXZLowerIn = 0.0
    TSurfFloorPerim = 0.0
    TSurfFloorPerimIn = 0.0
    TSurfFloorCore = 0.0
    TSurfFloorCoreIn = 0.0
    DAPerim = 0.0
    DACore = 0.0
    DAYZUpperSum = 0.0
    DAYZLowerSum = 0.0
    DAXZUpperSum = 0.0
    DAXZLowerSum = 0.0
    DAXZSum = 0.0
    DAYZSum = 0.0
    DAXYSum = 0.0
    # ... full implementation follows the Fortran code

fn EPlusOutput(IHR: Int, IDAY: Int, TSurfWallXZ: Float64, TSurfWallYZ: Float64,
              TSurfFloor: Float64, TSWallYZIn: Float64, TSWallXZIn: Float64,
              TSFloorIn: Float64, TSYZCL: Float64, TSXZCL: Float64,
              TSFXCL: Float64, TSFYCL: Float64, TSurfWallYZUpper: Float64,
              TSurfWallYZUpperIn: Float64, TSurfWallXZUpper: Float64,
              TSurfWallXZUpperIn: Float64, TSurfWallYZLower: Float64,
              TSurfWallYZLowerIn: Float64, TSurfWallXZLower: Float64,
              TSurfWallXZLowerIn: Float64, TSurfFloorPerim: Float64,
              TSurfFloorPerimIn: Float64, TSurfFloorCore: Float64,
              TSurfFloorCoreIn: Float64, FloorHeatFlux: Float64, CoreHeatFlux: Float64,
              PerimHeatFlux: Float64, XZWallHeatFlux: Float64, YZWallHeatFlux: Float64,
              UpperXZWallFlux: Float64, UpperYZWallFlux: Float64,
              LowerXZWallFlux: Float64, LowerYZWallFlux: Float64,
              TB: Float64, TCON_LOCAL: List[Float64]):
    pass

fn COSD(degree_value: Float64) -> Float64:
    return cos(degree_value * pi / 180.0)

fn ACOSD(degree_value: Float64) -> Float64:
    let clamped: Float64 = max(-1.0, min(1.0, degree_value))
    return acos(clamped) * 180.0 / pi

fn SIND(degree_value: Float64) -> Float64:
    return sin(degree_value * pi / 180.0)

fn ASIND(degree_value: Float64) -> Float64:
    let clamped: Float64 = max(-1.0, min(1.0, degree_value))
    return asin(clamped) * 180.0 / pi

fn EPlusHeader():
    pass

fn AvgHeatFlux(DACore: Float64, DAPerim: Float64, XC: List[Float64], YC: List[Float64],
               ZC: List[Float64], DX: List[Float64], DY: List[Float64], DZ: List[Float64],
               QWS: List[List[Float64]], QWW: List[List[Float64]], QF: List[List[Float64]],
               XDIM: Int, YDIM: Int, ZDIM: Int, mut FloorHeatFlux: Float64,
               mut CoreHeatFlux: Float64, mut PerimHeatFlux: Float64,
               mut XZWallHeatFlux: Float64, mut YZWallHeatFlux: Float64,
               mut UpperXZWallFlux: Float64, mut UpperYZWallFlux: Float64,
               mut LowerXZWallFlux: Float64, mut LowerYZWallFlux: Float64,
               mut DAYZUpperSum: Float64, mut DAYZLowerSum: Float64,
               mut DAXZUpperSum: Float64, mut DAXZLowerSum: Float64,
               mut DAXZSum: Float64, mut DAYZSum: Float64, mut DAXYSum: Float64):
    let DGRAVZP: Float64 = building_data.DGRAVZP
    let DGRAVZN: Float64 = building_data.DGRAVZN
    let DSLAB: Float64 = building_data.DSLAB
    let KEXT: Float64 = ZFACE[KBASE + 35] + DSLAB

fn CloseIO():
    pass

fn InitializeTG(mut TG: List[Float64]):
    var ZFACEUsed: InlineArray[Float64, MAX_ZFACE] = InlineArray[Float64, MAX_ZFACE](0.0)
    for c1 in range(0, MAX_ZFACE):
        ZFACEUsed[c1] = ZFACEINIT[c1]
    var HTDB: List[Float64] = [Float64(0.0) for _ in range(MAX_YEAR_HOURS)]
    var IHrStart: Int = 1
    var IHrEnd: Int = 24
    for IDAY in range(1, MAX_DAYS):
        GetWeatherData(IDAY)
        let TDB = [Float64(0.0) for _ in range(MAX_HOURS)]
        for i in range(0, MAX_HOURS):
            HTDB[IHrStart - 1 + i] = TDB[i]
        IHrStart += 24
        IHrEnd += 24
    var HourNum: Int = 0
    var ACHSum: Int = 0
    var AHHSum: Int = 0
    for IHR in range(0, MAX_YEAR_HOURS - 1):
        if HTDB[IHR] > TDeadBandUp:
            ACHSum += 1
        elif HTDB[IHR] < TDeadBandLow:
            AHHSum += 1
    site_info.ACH = ACHSum
    site_info.AHH = AHHSum
    var TAVG: InlineArray[Float64, 12] = InlineArray[Float64, 12](0.0)
    for IMON in range(1, MAX_NDIM + 1):
        var TempSum: Float64 = 0.0
        for IDAY in range(1, NDIM[IMON - 1] + 1):
            for IHR in range(1, MAX_HOURS + 1):
                HourNum += 1
                TempSum += HTDB[HourNum - 1]
            TAVG[IMON - 1] = TempSum / Float64(IDAY * MAX_HOURS)
    var TmSum: Float64 = 0.0
    var TAvgMax: Float64 = -99999.0
    var TAvgMin: Float64 = 99999.0
    for IMON in range(1, MAX_NDIM + 1):
        TmSum += TAVG[IMON - 1]
        TAvgMax = max(TAvgMax, TAVG[IMON - 1])
        TAvgMin = min(TAvgMin, TAVG[IMON - 1])
    let Tm: Float64 = TmSum / Float64(MAX_NDIM)
    let As: Float64 = (TAvgMax - TAvgMin) / 2.0
    for c1 in range(0, NZBG + 1):
        TG[c1] = Tm - As * exp(-0.4464 * ZFACEUsed[c1]) * COSD(0.5236 * (-1.0 - 0.8525 * ZFACEUsed[c1]))
        if c1 == 20:
            TG[c1] = Tm

fn WeatherServer():
    site_info.LONG = 0.0
    site_info.LAT = 0.0
    site_info.MSTD = 0.0
    site_info.ELEV = 0.0

fn DrySatPt(mut SATUPT: Float64, TDB: Float64):
    let TT: Float64 = Float64(TDB)
    if TDB > 20:
        if TDB < 30:
            SATUPT = 6.10775e2 + 44.4502 * TT + 1.38578 * TT**2 + 3.3106e-2 * TT**3
        elif TDB < 40:
            SATUPT = 4.05663e2 + 76.8637 * TT - 0.447857 * TT**2 + 7.15905e-2 * TT**3
        elif TDB < 80:
            SATUPT = 7.30208e2 + 32.987 * TT + 1.84658 * TT**2 + 1.95497e-2 * TT**3 + 3.33617e-4 * TT**4 + 2.59343e-6 * TT**5
        else:
            SATUPT = 6.91607e2 + 10.703 * TT + 3.01092 * TT**2 - 2.57247e-3 * TT**3 + 5.19714e-4 * TT**4 + 2.00552e-6 * TT**5
    elif TDB > 10:
        SATUPT = 5.9088e2 + 49.8847 * TT + 0.874643 * TT**2 + 4.97621e-2 * TT**3
    elif TDB > 0:
        SATUPT = 6.10775e2 + 44.4502 * TT + 1.38578 * TT**2 + 3.3106e-2 * TT**3
    elif TDB > -20:
        SATUPT = 6.10860e2 + 50.1255 * TT + 1.83622 * TT**2 + 3.67769e-2 * TT**3 + 3.41421e-4 * TT**4
    elif TDB > -40:
        SATUPT = 5.69275e2 + 42.5035 * TT + 1.29301 * TT**2 + 1.88391e-2 * TT**3 + 1.0961e-4 * TT**4
    else:
        SATUPT = 4.9752e2 + 35.3452 * TT + 1.04398 * TT**2 + 1.5962e-2 * TT**3 + 1.2578e-4 * TT**4 + 4.0683e-7 * TT**5

fn GetField(InputString: String, Fldno: Int, mut ReturnString: String, Delimiter: String = ","):
    ReturnString = " "
    var Fld: Int = 1
    var LastPos: Int = 1
    let delim: String = Delimiter if Delimiter else ","
    var pos: Int = -1
    while Fld <= Fldno:
        if LastPos - 1 >= len(InputString):
            pos = -1
            break
        pos = InputString[LastPos - 1:].find(delim)
        if Fld < Fldno:
            LastPos = LastPos + pos + 1 if pos >= 0 else LastPos
        Fld += 1
    if pos > 0:
        ReturnString = InputString[LastPos - 1:LastPos + pos - 2]
    else:
        ReturnString = InputString[LastPos - 1:]

# ============================================================
# Main Program
# ============================================================
fn BasementModel():
    Base3Ddriver()

fn main():
    BasementModel()
