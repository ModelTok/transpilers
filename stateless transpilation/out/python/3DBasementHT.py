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

import math
import os
import sys
import numpy as np
from typing import Optional, List, Tuple, Any

# Constants
SIGMA = 5.6697e-8
pi = 3.1415926535
NDIM = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
NFDM = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

# External module stubs - these would be imported from the actual modules
# in the full EnergyPlus codebase
class DataPrecisionGlobals:
    pass

r64 = np.float64

class DataGlobals:
    MaxNameLength = 100
    @staticmethod
    def ShowSevereError(msg): print("SEVERE:", msg)
    @staticmethod
    def ShowContinueError(msg): print("CONTINUE:", msg)
    @staticmethod
    def ShowFatalError(msg): print("FATAL:", msg); sys.exit(1)
    @staticmethod
    def ShowWarningError(msg): print("WARNING:", msg)

# BasementSimData derived types and module-level variables
class SiteInfo:
    LONG = 0.0
    LAT = 0.0
    MSTD = 0.0
    ELEV = 0.0
    AHH = 0
    ACH = 0

class SimParams:
    F = 0.1
    IYRS = 15
    TSTEP = 1.0

class BCS:
    OLDTG = 'FALSE'
    TGNAM = 'GrTemp'
    TWRITE = 'FALSE'
    TREAD = 'FALSE'
    TINIT = 'Tinit'
    FIXBC = 'TRUE'
    NMAT = 6

class Insul:
    REXT = 0.0
    RINT = 0.0
    INSFULL = 'FALSE'
    RSID = 0.0
    RSILL = 0.0
    RCEIL = 0.0
    RSNOW = 'TRUE'

class Interior:
    HIN = np.zeros(6)
    COND = 'TRUE'
    TIN = np.zeros(2)

class SP:
    PET = 'FALSE'
    VEGHT = np.zeros(2)
    EPSLN = np.zeros(2)
    ALBEDO = np.zeros(2)

class BuildingData:
    DWALL = 0.2
    DSLAB = 0.1
    DGRAVXY = 0.3
    DGRAVZN = 0.2
    DGRAVZP = 0.1

# Module-level state
AUTOGRID = 'TRUE'
EquivSizing = 'FALSE'
TBasementAve = 0.0
TBasementDailyAmp = 0.0
EPlus = 'TRUE'
ComBldg = 'TRUE'
WeatherFile = 'TMYWeath'
EPWFile = 'in'
RHO = np.zeros(20)
CP = np.zeros(20)
TCON = np.zeros(20)
APRatio = 0.0
SLABX = 6.0
SLABY = 6.0
CLEARANCE = 0.0
ConcAGHeight = 0.0
SlabDepth = 0.0
BaseDepth = 0.0
ZFACEINIT = np.zeros(136)
ZFACE = np.zeros(136)
XFACE = np.zeros(101)
YFACE = np.zeros(101)
NZAG = 0
NZBG = 0
NX = 0
NY = 0
IBASE = 0
JBASE = 0
KBASE = 0
NXM1 = 0
NYM1 = 0
NZBGM1 = 0
COUNT1 = 0
COUNT2 = 0
COUNT3 = 0
NUM = 0
IDAY = 0
IHR = 0
IMON = 0
TREAD = 'FALSE'
TWRITE = 'FALSE'
TINIT = 'Tinit'
TDeadBandUp = 0.0
TDeadBandLow = 0.0
TDeadBandUp_val = 0.0
TDeadBandLow_val = 0.0
Elapsed_Time = 0.0

# File unit numbers
Weather = 0
GroundTemp = 0
SolarFile = 0
AvgTG = 0
DebugOutFile = 0
InputEcho = 0
QHouseFile = 0
DOUT = 0
DYFLX = 0
LoadFile = 0
Ceil121 = 0
Flor121 = 0
RMJS121 = 0
RMJW121 = 0
SILS121 = 0
SILW121 = 0
WALS121 = 0
WALW121 = 0
CeilD21 = 0
FlorD21 = 0
RMJSD21 = 0
RMJWD21 = 0
SILSD21 = 0
SILWD21 = 0
WALSD21 = 0
WALWD21 = 0
XZYZero = 0
XZYHalf = 0
XZYFull = 0
XZWallTs = 0
YZWallTs = 0
FloorTs = 0
Centerline = 0
YZWallSplit = 0
XZWallSplit = 0
FloorSplit = 0
EPMonthly = 0
EPObjects = 0

# TodaysWeather and FullYearWeather structures
class TodaysWeather:
    TDB = np.zeros(24)
    TWB = np.zeros(24)
    PBAR = np.zeros(24)
    HRAT = np.zeros(24)
    WND = np.zeros(24)
    RBEAM = np.zeros(24)
    RDIFH = np.zeros(24)
    ISNW = np.zeros(24, dtype=int)
    DSNOW = np.zeros(24)

class FullYearWeatherDay:
    def __init__(self):
        self.TDB = np.zeros(24)
        self.TWB = np.zeros(24)
        self.PBAR = np.zeros(24)
        self.HRAT = np.zeros(24)
        self.WND = np.zeros(24)
        self.RBEAM = np.zeros(24)
        self.RDIFH = np.zeros(24)
        self.ISNW = np.zeros(24, dtype=int)
        self.DSNOW = np.zeros(24)

FullYearWeather = [FullYearWeatherDay() for _ in range(366)]
TodaysWeather = TodaysWeather()

MATL_TYPES = ["Undefined", "FoundationWall", "FloorSlab", "Ceiling", "Soil", "Gravel", "Wood", "Air"]

# ============================================================
# Module: General
# ============================================================

def IsNAN(val):
    """Check if value is NaN"""
    return math.isnan(val)

def r64RoundSigDigits(RealValue, SigDigits):
    """R64 round to significant digits"""
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    s = str(RealValue)
    EPos = s.find('E')
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    else:
        EString = ' '
    DotPos = s.find('.')
    SLen = len(s.rstrip())
    IncludeDot = SigDigits > 0 or EString != ' '
    if IncludeDot:
        end = min(DotPos + SigDigits, SLen)
        s = s[:end] + EString
    else:
        s = s[:DotPos-1] if DotPos > 0 else s
    if IsNAN(RealValue):
        s = 'NAN'
    return s.lstrip()

def rRoundSigDigits(RealValue, SigDigits):
    """Real round to significant digits"""
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    s = str(RealValue)
    EPos = s.find('E')
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    else:
        EString = ' '
    DotPos = s.find('.')
    SLen = len(s.rstrip())
    IncludeDot = SigDigits > 0 or EString != ' '
    if IncludeDot:
        end = min(DotPos + SigDigits, SLen)
        s = s[:end] + EString
    else:
        s = s[:DotPos-1] if DotPos > 0 else s
    if IsNAN(RealValue):
        s = 'NAN'
    return s.lstrip()

def iRoundSigDigits(IntegerValue, SigDigits):
    """Integer round to significant digits"""
    s = str(IntegerValue)
    return s.lstrip()

def r64TrimSigDigits(RealValue, SigDigits):
    """R64 trim to significant digits"""
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    s = str(RealValue)
    EPos = s.find('E')
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    else:
        EString = ' '
    DotPos = s.find('.')
    SLen = len(s.rstrip())
    IncludeDot = SigDigits > 0 or EString != ' '
    if IncludeDot:
        end = min(DotPos + SigDigits, SLen)
        s = s[:end] + EString
    else:
        s = s[:DotPos-1] if DotPos > 0 else s
    if IsNAN(RealValue):
        s = 'NAN'
    return s.lstrip()

def rTrimSigDigits(RealValue, SigDigits):
    """Real trim to significant digits"""
    if RealValue == 0.0:
        return "0.000000000000000000000000000"
    s = str(RealValue)
    EPos = s.find('E')
    if EPos > 0:
        EString = s[EPos:]
        s = s[:EPos]
    else:
        EString = ' '
    DotPos = s.find('.')
    SLen = len(s.rstrip())
    IncludeDot = SigDigits > 0 or EString != ' '
    if IncludeDot:
        end = min(DotPos + SigDigits, SLen)
        s = s[:end] + EString
    else:
        s = s[:DotPos-1] if DotPos > 0 else s
    if IsNAN(RealValue):
        s = 'NAN'
    return s.lstrip()

def iTrimSigDigits(IntegerValue, SigDigits):
    """Integer trim to significant digits"""
    s = str(IntegerValue)
    return s.lstrip()

def RoundSigDigits(RealValue, SigDigits):
    """Generic round - dispatches based on type"""
    if isinstance(RealValue, (int, np.integer)):
        return iRoundSigDigits(RealValue, SigDigits)
    elif isinstance(RealValue, np.floating):
        return r64RoundSigDigits(float(RealValue), SigDigits)
    else:
        return rRoundSigDigits(float(RealValue), SigDigits)

def TrimSigDigits(RealValue, SigDigits):
    """Generic trim - dispatches based on type"""
    if isinstance(RealValue, (int, np.integer)):
        return iTrimSigDigits(RealValue, SigDigits)
    elif isinstance(RealValue, np.floating):
        return r64TrimSigDigits(float(RealValue), SigDigits)
    else:
        return rTrimSigDigits(float(RealValue), SigDigits)

def MakeUPPERCase(s):
    """Convert string to uppercase"""
    return s.upper() if s else s

def SameString(s1, s2):
    """Compare two strings case-insensitively"""
    if s1 is None and s2 is None:
        return True
    if s1 is None or s2 is None:
        return False
    return s1.upper() == s2.upper()

def dSafeDivide(a, b):
    """Double precision safe divide"""
    SMALL = 1.0e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        sign = 1.0 if b >= 0 else -1.0
        return a / (sign * SMALL)

def rSafeDivide(a, b):
    """Real safe divide"""
    SMALL = 1.0e-10
    if abs(b) >= SMALL:
        return a / b
    else:
        sign = 1.0 if b >= 0 else -1.0
        return a / (sign * SMALL)

def SafeDivide(a, b):
    """Generic safe divide"""
    return dSafeDivide(a, b)

def QsortPartition(Reals):
    """Partition for quicksort"""
    n = len(Reals)
    rpivot = Reals[0]
    i = 0
    j = n
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
            rtemp = Reals[i]
            Reals[i] = Reals[j]
            Reals[j] = rtemp
        elif i == j:
            return i + 1
        else:
            return i

def QsortR(Reals):
    """Recursive quicksort for reals"""
    if len(Reals) > 1:
        marker = QsortPartition(Reals)
        QsortR(Reals[:marker-1])
        QsortR(Reals[marker:])

# ============================================================
# Module: BASE3D
# ============================================================

# Global arrays used in BASE3D (declared as module-level for state)
T = None  # 3D temperature field
TCVG = None
CONST = None
CXA = None
CXP = None
CYM = None
CYP = None
CZM = None
CZP = None
A = None
B = None
C = None
R = None
AA = None
BB = None
CC = None
RR = None
X = None
U = None
V = None
VEXT = None
UEXT = None
MTYPE = None
GOFT = None
GOFTAV = None
GOFTSUM = None
RSOLV = None
RSOLH = None
RDIRH = None
RDIRHO = None
RDIFH = None
RDIFHO = None
DTC21 = None
DTF21 = None
DTRS21 = None
DTRW21 = None
DQC21 = None
DQF21 = None
DQRS21 = None
DQRW21 = None
QC = None
QF = None
TC = None
TF = None
TRS = None
TRW = None
TSS = None
TSW = None
TWS = None
TWW = None
QEXT = None
TEXT = None
QRS = None
QRW = None
QSS = None
QSW = None
QWS = None
QWW = None
TG = None

def Base3Ddriver():
    """Driver subroutine"""
    SimController()

def PrelimInput(RUNID):
    """Preliminary input retrieval"""
    GetSimParams(RUNID)

def GetInput(RUNID, TG):
    """Main input retrieval driver"""
    global OLDTG
    # CALL GetLocation - not needed
    GetBoundConds()
    GetMatlsProps()
    GetInsulationProps()
    GetSurfaceProps()
    GetBuildingInfo()
    GetInteriorInfo()
    if not SameString(ComBldg, 'FALSE'):
        GetComBldgIndoorTemp()
    if not SameString(EquivSizing, 'FALSE'):
        if not SameString(AUTOGRID, 'FALSE'):
            GetEquivAutoGridInfo()
        else:
            GetAutoGridInfo()
    else:
        GetManualGridInfo()
    if not SameString(BCS.OLDTG, 'FALSE'):
        InitializeTG(TG)

def GetSimParams(RUNID):
    """Get simulation parameters"""
    global SimParams
    SimParams.F = 0.1
    SimParams.IYRS = 15
    # CALL GetObjectItem - stubbed
    AUTOGRID = 'TRUE'
    EPlus = 'TRUE'
    WeatherFile = 'TMYWeath'
    RUNID = 'Run'
    ComBldg = 'TRUE'
    EPWFile = 'in'
    SimParams.F = 0.1  # Would come from NumArray
    if SimParams.F <= 0.0 or SimParams.F > 0.3:
        DataGlobals.ShowSevereError('GetSimParams: "F: Multiplier for the ADI solution" > .3, Set to .1 for this run.')
        SimParams.F = 0.1
    SimParams.IYRS = 15  # Would come from NumArray
    # Environment variable check - stubbed
    if SimParams.IYRS <= 0.0:
        DataGlobals.ShowSevereError('GetSimParams: Entered "IYRS: Maximum number of yearly iterations:" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(SimParams.IYRS, 4)) + '], 15 will be used.')
        SimParams.IYRS = 15
    SimParams.TSTEP = 1.0

def GetLocation():
    """Get location information"""
    SiteInfo.LONG = -110
    SiteInfo.LAT = 0.0
    SiteInfo.MSTD = 75
    SiteInfo.ELEV = 0.0

def GetBoundConds():
    """Get boundary conditions"""
    BCS.OLDTG = 'FALSE'
    BCS.TGNAM = 'GrTemp'
    BCS.TWRITE = 'FALSE'
    BCS.TREAD = 'FALSE'
    BCS.TINIT = 'Tinit'
    BCS.FIXBC = 'TRUE'

def GetMatlsProps():
    """Get materials properties"""
    global RHO, CP, TCON
    BCS.NMAT = 6
    RHO[1] = 2243.0; RHO[2] = 2243.0; RHO[3] = 311.0
    RHO[4] = 1500.0; RHO[5] = 2000.0; RHO[6] = 449.0; RHO[7] = 1.25
    CP[1] = 880.0; CP[2] = 880.0; CP[3] = 1530.0
    CP[4] = 840.0; CP[5] = 720.0; CP[6] = 1530.0; CP[7] = 1012.0
    TCON[1] = 1.4; TCON[2] = 1.4; TCON[3] = 0.09
    TCON[4] = 1.1; TCON[5] = 1.9; TCON[6] = 0.12; TCON[7] = 0.025
    # CALL GetObjectItem - would update from input
    BCS.NMAT = 6
    RHO[1] = 2243.0; RHO[2] = 2243.0; RHO[3] = 311.0
    RHO[4] = 1500.0; RHO[5] = 2000.0; RHO[6] = 449.0; RHO[7] = 1.25
    CP[1] = 880.0; CP[2] = 880.0; CP[3] = 1530.0
    CP[4] = 840.0; CP[5] = 720.0; CP[6] = 1530.0; CP[7] = 1012.0
    TCON[1] = 1.4; TCON[2] = 1.4; TCON[3] = 0.09
    TCON[4] = 1.1; TCON[5] = 1.9; TCON[6] = 0.12; TCON[7] = 0.025

def GetInsulationProps():
    """Get insulation properties"""
    global Insul
    Insul.REXT = 0.0  # Would come from NumArray
    if Insul.REXT <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "REXT: R Value of any exterior insulation" choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Insul.REXT, 4)) + '], .001 will be used.')
        Insul.REXT = 0.001
    Insul.RINT = 0.0
    Insul.INSFULL = MakeUPPERCase('')  # Would come from AlphArray
    if not (SameString('', 'TRUE') or SameString('', 'FALSE')):
        DataGlobals.ShowWarningError('GetInsulationProps: Entered "INSFULL: Flag: Is the wall fully insulated?" choice is not valid.' +
            ' Entered value="' + '' + '", FALSE will be used.')
        Insul.INSFULL = 'FALSE'
    Insul.RSID = 0.0
    Insul.RSILL = 0.0
    Insul.RCEIL = 0.0
    Insul.RSNOW = 'TRUE'

def GetSurfaceProps():
    """Get surface properties"""
    global SP
    SP.ALBEDO[0] = 0.16; SP.ALBEDO[1] = 0.40
    SP.EPSLN[0] = 0.94; SP.EPSLN[1] = 0.86
    SP.VEGHT[0] = 6.0; SP.VEGHT[1] = 0.25
    SP.PET = 'FALSE'
    # CALL GetObjectItem - would update
    SP.ALBEDO[0] = 0.16; SP.ALBEDO[1] = 0.40
    SP.EPSLN[0] = 0.94; SP.EPSLN[1] = 0.86
    SP.VEGHT[0] = 6.0; SP.VEGHT[1] = 0.25
    SP.PET = MakeUPPERCase('')  # From AlphArray
    if not (SameString(SP.PET, 'TRUE') or SameString(SP.PET, 'FALSE')):
        DataGlobals.ShowWarningError('GetSurfaceProps: "PET: Flag, Potential evapotranspiration on?" choice is not valid' +
            ' Entered value="' + '' + '", FALSE will be used.')
        SP.PET = 'FALSE'

def GetBuildingInfo():
    """Get building info"""
    global BuildingData
    BuildingData.DWALL = 0.2
    BuildingData.DSLAB = 0.1
    BuildingData.DGRAVXY = 0.3
    BuildingData.DGRAVZN = 0.2
    BuildingData.DGRAVZP = 0.1
    # CALL GetObjectItem - would update
    BuildingData.DWALL = 0.2  # NumArray
    if BuildingData.DWALL < 0.2:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DWALL: Wall thickness" choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(BuildingData.DWALL, 4)) + '], .2 will be used.')
        BuildingData.DWALL = 0.2
    BuildingData.DSLAB = 0.1
    if BuildingData.DSLAB <= 0.0 or BuildingData.DSLAB > 0.25:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DSLAB: Floor slab thickness" choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(BuildingData.DSLAB, 4)) + '], .1 will be used.')
        BuildingData.DSLAB = 0.1
    BuildingData.DGRAVXY = 0.3
    if BuildingData.DGRAVXY <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVXY: Width of gravel pit beside basement wall" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(BuildingData.DGRAVXY, 4)) + '], .3 will be used.')
        BuildingData.DGRAVXY = 0.3
    BuildingData.DGRAVZN = 0.2
    if BuildingData.DGRAVZN <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVZN: Gravel depth extending above the floor slab" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(BuildingData.DGRAVZN, 4)) + '], .2 will be used.')
        BuildingData.DGRAVZN = 0.2
    BuildingData.DGRAVZP = 0.1
    if BuildingData.DGRAVZP <= 0.0:
        DataGlobals.ShowSevereError('GetInsulationProps: Entered "DGRAVZP: Gravel depth below the floor slab" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(BuildingData.DGRAVZP, 4)) + '], .1 will be used.')
        BuildingData.DGRAVZP = 0.1

def GetInteriorInfo():
    """Get interior info"""
    global Interior
    Interior.HIN[0] = 0.92; Interior.HIN[1] = 4.04; Interior.HIN[2] = 3.08
    Interior.HIN[3] = 6.13; Interior.HIN[4] = 9.26; Interior.HIN[5] = 8.29
    # CALL GetObjectItem - would update
    Interior.COND = ''  # From AlphArray
    if not (SameString(Interior.COND, 'TRUE') or SameString(Interior.COND, 'FALSE')):
        DataGlobals.ShowWarningError('GetInteriorInfo: "COND: Flag: Is the basement conditioned?" choice is not valid' +
            ' Entered value="' + '' + '", TRUE will be used.')
        Interior.COND = 'TRUE'
    Interior.HIN[0] = 0.92
    if Interior.HIN[0] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Downward convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[0], 4)) + '], .92 will be used.')
        Interior.HIN[0] = 0.92
    Interior.HIN[1] = 4.04
    if Interior.HIN[1] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Upward convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[1], 4)) + '], 4.04 will be used.')
        Interior.HIN[0] = 4.04
    Interior.HIN[2] = 3.08
    if Interior.HIN[2] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered "HIN: Horizontal convection only heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[2], 4)) + '], 3.08 will be used.')
        Interior.HIN[2] = 3.08
    Interior.HIN[3] = 6.13
    if Interior.HIN[3] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Downward combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[3], 4)) + '], 6.13 will be used.')
        Interior.HIN[3] = 6.13
    Interior.HIN[4] = 9.26
    if Interior.HIN[4] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Upward combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[4], 4)) + '], 9.26 will be used.')
        Interior.HIN[4] = 9.26
    Interior.HIN[5] = 8.29
    if Interior.HIN[5] <= 0.0:
        DataGlobals.ShowSevereError('GetInteriorInfo: Entered ' +
            '"HIN: Horizontal combined (convection and radiation) heat transfer coefficient" ' +
            'choice is not valid.' +
            ' Entered value=[' + str(RoundSigDigits(Interior.HIN[5], 4)) + '], 8.29 will be used.')
        Interior.HIN[5] = 8.29

def GetComBldgIndoorTemp():
    """Get commercial building indoor temperature"""
    global TBasementAve, TBasementDailyAmp
    # CALL GetObjectItem
    NumNums = 0  # Would be set
    if NumNums < 12:
        TBasementAve = 0.0
        TBasementDailyAmp = 0.0
        DataGlobals.ShowWarningError('GetComBldgIndoorTemp: Not all monthly average temperature entered. ' +
            'Average temperature is set to [' + str(RoundSigDigits(Interior.HIN[5], 4)) + '].')
    else:
        TBasementAve = np.zeros(12)  # NumArray
        TBasementDailyAmp = 0.0

def GetResBldgIndoorTemp():
    """Get residential building indoor temperature"""
    Interior.TIN[0] = 0.0
    Interior.TIN[1] = 0.0
    global TDeadBandUp, TDeadBandLow
    TDeadBandUp = 0.0
    TDeadBandLow = 0.0

def GetEquivSlabInfo():
    """Get equivalent slab info"""
    global APRatio, SLABX, SLABY, EquivSizing
    errFound = False
    NumNums = 0  # GetNumObjectsFound
    if NumNums <= 0:
        return
    APRatio = 0.0  # NumArray
    if APRatio < 0.0:
        DataGlobals.ShowSevereError('GetEquivSlabInfo: APRatio =[' + str(RoundSigDigits(APRatio, 3)) +
            '] less than zero.')
        errFound = True
    EquivSizing = MakeUPPERCase('')  # AlphArray
    if not (SameString('', 'TRUE') or SameString('', 'FALSE')):
        DataGlobals.ShowWarningError('GetEquivSlabInfo: Entered "EquivSizing: Flag" choice is not valid.' +
            ' Entered value="' + '' + '", TRUE will be used.')
        EquivSizing = 'TRUE'
    L = 4.0 * APRatio
    if L < 6.0:
        SLABX = 6.0
        SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
    else:
        SLABX = L
        SLABY = L
    if errFound:
        DataGlobals.ShowFatalError('GetEquivSlabInfo: program terminates due to previous condition.')

def GetEquivAutoGridInfo():
    """Get equivalent auto grid info"""
    global CLEARANCE, ConcAGHeight, SlabDepth, BaseDepth
    NumNums = 0  # GetNumObjectsFound
    if NumNums > 0:
        CLEARANCE = 0.0
        ConcAGHeight = 0.0
        SlabDepth = 0.0
        BaseDepth = 0.0
        AutoGridding()

def GetAutoGridInfo():
    """Get auto grid info"""
    global CLEARANCE, SLABX, SLABY, ConcAGHeight, SlabDepth, BaseDepth
    NumNums = 0  # GetNumObjectsFound
    if NumNums > 0:
        CLEARANCE = 0.0
        SLABX = 0.0
        SLABY = 0.0
        ConcAGHeight = 0.0
        SlabDepth = 0.0
        BaseDepth = 0.0
        AutoGridding()

def GetManualGridInfo():
    """Get manual grid info"""
    global NX, NY, NZAG, NZBG, IBASE, JBASE, KBASE
    NumNums = 0  # GetNumObjectsFound
    if NumNums > 0:
        NX = 0; NY = 0; NZAG = 0; NZBG = 0
        IBASE = 0; JBASE = 0; KBASE = 0
        GetXFACEData()
        GetYFACEData()
        GetZFACEData()

def GetXFACEData():
    """Get XFACE data"""
    global XFACE
    # XFACE = NumArray

def GetYFACEData():
    """Get YFACE data"""
    global YFACE
    # YFACE = NumArray

def GetZFACEData():
    """Get ZFACE data"""
    global ZFACE
    # ZFACE = NumArray

def GetEPlusGeom():
    """Get EnergyPlus geometry"""
    global SLABX, SLABY, APRatio, EquivSizing
    SurfType = ''  # AlphArray
    FloorArea = 0.0
    if SurfType == 'FLOOR':
        X1 = 0.0; X2 = 0.0; X3 = 0.0; X4 = 0.0
        Y1 = 0.0; Y2 = 0.0; Y3 = 0.0; Y4 = 0.0
        DIMX1 = 0.0; DIMX2 = 0.0; DIMY1 = 0.0; DIMY2 = 0.0
        Perimeter = DIMX1 + DIMX2 + DIMY1 + DIMY2
        APRatio = FloorArea / Perimeter
    if not SameString(EPlus, 'FALSE') and APRatio != 0.0:
        L = 4.0 * APRatio
        if L < 6.0:
            SLABX = 6.0
            SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
        else:
            SLABX = L
            SLABY = L
    else:
        NumNums = 0  # GetNumObjectsFound
        if NumNums > 0:
            APRatio = 0.0
            EquivSizing = ''  # AlphArray
            L = 4.0 * APRatio
            if L < 6.0:
                SLABX = 6.0
                SLABY = (2.0 * APRatio * SLABX) / (1.0 - (2.0 * APRatio))
            else:
                SLABX = L
                SLABY = L
        else:
            APRatio = 0.0
            EquivSizing = 'FALSE'
            L = 0.0
            SLABX = 0.0
            SLABY = 0.0

def SimController():
    """Simulation controller"""
    global NUMRUNS, NUM, OldTG, RUNID
    NUMRUNS = 1
    EPObjects = 1  # GetNewUnitNumber
    for NUM in range(1, NUMRUNS + 1):
        CVG = False
        QUIT = False
        RUNID = 'Run'
        PrelimInput(RUNID)
        WeatherServer()
        TG = np.zeros(101)
        GetInput(RUNID, TG)
        ConnectIO(RUNID)
        XDIM = IBASE + 3
        YDIM = JBASE + 3
        ZDIM = KBASE + 2
        BasementSimulator(RUNID, 6, CVG, XDIM, YDIM, ZDIM, TG)
        CloseIO()

def BasementSimulator(RUNID, NMAT, CVG, XDIM, YDIM, ZDIM, TG):
    """Main basement simulation"""
    global T, TCVG, A, B, C, R, CONST, CXA, CXP, CYM, CYP, CZM, CZP, U, V, VEXT, UEXT, MTYPE, GOFT, GOFTAV, GOFTSUM, RSOLV, RDIRH, RDIRHO, RDIFH, RDIFHO
    # ... extensive implementation following the Fortran code structure
    # This is a stub for the very large simulation routine
    pass

def ConnectIO(RUNID):
    """Connect I/O files"""
    global DebugOutFile, InputEcho, GroundTemp, SolarFile, AvgTG
    DebugOutFile = 1  # GetNewUnitNumber
    InputEcho = 2
    GroundTemp = 3
    SolarFile = 4
    AvgTG = 5
    EPMonthly = 6
    # ... rest of file connections omitted for brevity

def FDMCoefficients(NXM1, NYM1, NZBGM1, INSFULL, REXT, DX, DY, DZ, DXP, DYP, DZP, MTYPE, CXM, CYM, CZM, CXP, CYP, CZP, ZC, INS):
    """Calculate FDM coefficients"""
    # Initialize
    for c2 in range(0, NYM1 + 1):
        for c3 in range(-NZAG, NZBGM1 + 1):
            for c1 in range(1, NXM1 + 1):
                CXM[c1, c2, c3] = 0.0
                CXP[c1, c2, c3] = 0.0
    for c2 in range(0, NYM1 + 1):
        for c3 in range(-NZAG, NZBGM1 + 1):
            for c1 in range(1, NXM1 + 1):
                if MTYPE[c1, c2, c3] == 7:
                    XK = 0.0
                elif MTYPE[c1, c2, c3] == MTYPE[c1-1, c2, c3]:
                    XK = TCON[MTYPE[c1, c2, c3]]
                elif MTYPE[c1, c2, c3] != 7 and MTYPE[c1-1, c2, c3] == 7:
                    XK = TCON[MTYPE[c1, c2, c3]]
                elif ((MTYPE[c1, c2, c3] == 4 or MTYPE[c1, c2, c3] == 5) and
                      MTYPE[c1-1, c2, c3] == 1 and not SameString(INSFULL, 'FALSE') and
                      c3 <= KBASE):
                    XK = (DX[c1] + DX[c1-1]) / (DX[c1] / TCON[MTYPE[c1, c2, c3]] +
                          DX[c1-1] / TCON[MTYPE[c1-1, c2, c3]] + REXT)
                elif ((MTYPE[c1, c2, c3] == 4 or MTYPE[c1, c2, c3] == 5) and
                      MTYPE[c1-1, c2, c3] == 1 and SameString(INSFULL, 'FALSE') and
                      ZC[c3] <= ZC[1 + (KBASE - NZAG) // 2]):
                    XK = (DX[c1] + DX[c1-1]) / (DX[c1] / TCON[MTYPE[c1, c2, c3]] +
                          DX[c1-1] / TCON[MTYPE[c1-1, c2, c3]] + REXT)
                else:
                    XK = (DX[c1] + DX[c1-1]) / (DX[c1] / TCON[MTYPE[c1, c2, c3]] +
                          DX[c1-1] / TCON[MTYPE[c1-1, c2, c3]])
                CXM[c1, c2, c3] = XK / DX[c1] / DXP[c1-1]
                CXP[c1-1, c2, c3] = XK / DX[c1-1] / DXP[c1-1]
            CXM[0, c2, c3] = TCON[MTYPE[0, c2, c3]] / DX[0] / DX[0]
            CXP[NXM1, c2, c3] = TCON[MTYPE[NXM1, c2, c3]] / DX[NXM1] / DX[NXM1]
    # Similar for Y and Z directions
    # ... (full implementation continues)

def CalcTearth(IEXT, JEXT, DZ, DZP, TG, CVG):
    """Calculate 1D ground temperature profile"""
    global TCVG
    SoilDens = RHO[4]
    CG = CP[4]
    TCOND = TCON[4]
    PET = SP.PET
    VEGHT = SP.VEGHT
    EPSLN = SP.EPSLN
    ALBEDO = SP.ALBEDO
    FIXBC = BCS.FIXBC
    RSNOW = Insul.RSNOW
    LAT = SiteInfo.LAT
    LONG = SiteInfo.LONG
    MSTD = SiteInfo.MSTD
    ELEV = SiteInfo.ELEV
    CVG = False
    MAXYR = 20
    # ... (full implementation follows the Fortran code)

def AIRPROPS(HRAT, PBAR, TDB, ELEV, PVAP, RHOA, CPA, DODPG):
    """Calculate air properties"""
    PVAP = (HRAT / (HRAT + 0.62198)) * PBAR
    RHOA = (PBAR - 0.3780 * PVAP) / (287.055 * (TDB + 273.15))
    CPA = 1007.0 + 863.0 * PVAP / PBAR
    DODPG = (0.395643 + 0.17092e-01 * TDB - 0.140959e-03 * TDB * TDB +
             0.309091e-04 * ELEV + 0.822511e-09 * ELEV * ELEV -
             0.472208e-06 * TDB * ELEV)

def CalcHeatMassTransCoeffs(VEGHTCM, WND, AVGWND, TDB, TG, DH, DW):
    """Calculate heat and mass transfer coefficients"""
    monethird = -1.0 / 3.0
    G = 9.81
    VONKAR = 0.41
    ZEROD = 0.67 * VEGHTCM
    ZOM = 0.123 * VEGHTCM
    ZOV = 0.1 * ZOM
    if WND == 0.0:
        WND2 = AVGWND * (math.log((200.0 - ZEROD) / ZOM)) / (math.log((1000.0 - ZEROD) / ZOM))
    else:
        WND2 = WND * (math.log((200.0 - ZEROD) / ZOM)) / (math.log((1000.0 - ZEROD) / ZOM))
    RI = 2.0 * (G / (TDB + 273.15)) * math.log((200.0 - ZEROD) / ZOM) * (TDB - TG) / (WND2 * WND2)
    PHI = 0.0
    if TDB <= TG:
        PHI = (1.0 - 18.0 * RI) ** (-0.250)
    CPHI = 0.0
    if TDB <= TG:
        CPHI = (PHI - 1.0) * math.log((200.0 - ZEROD) / ZOM)
    DM = (VONKAR * VONKAR * WND2) / ((CPHI + math.log((200.0 - ZEROD) / ZOM)) *
         (CPHI + math.log((200.0 - ZEROD) / ZOV)))
    if TDB <= TG:
        DH = DM
        DW = DM
    else:
        DH = DM * (1.0 - 14.0 * (TG - TDB) / (WND2 * WND2)) ** monethird
        DW = DH

def SOLAR(LONG, LAT, MSTD, ALB, EPS, RBEAM, RDIFH, RDIRH, RSOLV, IEXT, JEXT, DZ, IDAY, IHR, TDB, PVAP, TG):
    """Calculate solar radiation"""
    B = 360.0 * (IDAY - 81.0) / 364.0
    ET = (9.87 * SIND(2.0 * B) - 7.53 * COSD(B) - 1.5 * SIND(B)) / 60.0
    TSOL = IHR + (MSTD - LONG) / 15.0 + ET
    DELTA = ASIND(-SIND(23.45) * COSD(360.0 * (IDAY + 10.0) / 365.25)) / 15.0
    H = abs(TSOL - 12.0) * 15.0
    BETA = ASIND(COSD(LAT) * COSD(H) * COSD(DELTA) + SIND(LAT) * SIND(DELTA))
    PHIARG = (SIND(BETA) * SIND(LAT) - SIND(DELTA)) / (COSD(BETA) * COSD(LAT))
    if PHIARG > 1.0:
        PHIARG = 1.0
    elif PHIARG < -1.0:
        PHIARG = -1.0
    PHI = ACOSD(PHIARG)
    if TSOL <= 12.0:
        PHI = -PHI
    GAMMAN = PHI - 180.0
    GAMMAE = PHI - (-90.0)
    GAMMAS = PHI - 0.0
    GAMMAW = PHI - 90.0
    THETAH = ACOSD(SIND(BETA))
    THETAVN = ACOSD(COSD(BETA) * COSD(GAMMAN))
    THETAVE = ACOSD(COSD(BETA) * COSD(GAMMAE))
    THETAVS = ACOSD(COSD(BETA) * COSD(GAMMAS))
    THETAVW = ACOSD(COSD(BETA) * COSD(GAMMAW))
    RDIRH = RBEAM * COSD(THETAH)
    if COSD(THETAVN) > 0.0:
        RDIRVN = RBEAM * COSD(THETAVN)
    else:
        RDIRVN = 0.0
    if COSD(THETAVE) > 0.0:
        RDIRVE = RBEAM * COSD(THETAVE)
    else:
        RDIRVE = 0.0
    if COSD(THETAVS) > 0.0:
        RDIRVS = RBEAM * COSD(THETAVS)
    else:
        RDIRVS = 0.0
    if COSD(THETAVW) > 0.0:
        RDIRVW = RBEAM * COSD(THETAVW)
    else:
        RDIRVW = 0.0
    RREFL = (RDIRH + RDIFH) * ALB / 2.0
    if COSD(THETAVN) > -0.2:
        RDIFVN = RDIFH * (0.55 + 0.437 * COSD(THETAVN) + 0.313 * (COSD(THETAVN)) ** 2)
    else:
        RDIFVN = RDIFH * 0.45
    if COSD(THETAVE) > -0.2:
        RDIFVE = RDIFH * (0.55 + 0.437 * COSD(THETAVE) + 0.313 * (COSD(THETAVE)) ** 2)
    else:
        RDIFVE = RDIFH * 0.45
    if COSD(THETAVS) > -0.2:
        RDIFVS = RDIFH * (0.55 + 0.437 * COSD(THETAVS) + 0.313 * (COSD(THETAVS)) ** 2)
    else:
        RDIFVS = RDIFH * 0.45
    if COSD(THETAVW) > -0.2:
        RDIFVW = RDIFH * (0.55 + 0.437 * COSD(THETAVW) + 0.313 * (COSD(THETAVW)) ** 2)
    else:
        RDIFVW = RDIFH * 0.45
    RSKY = 0.96 * SIGMA * ((TDB + 273.15) ** 4) * (0.820 - 0.250 * math.exp(-2.3 * 0.094 * 0.01 * PVAP)) / 2.0
    RGRND = (EPS * SIGMA * ((TG + 273.15) ** 4)) / 2.0
    DZAG = 0.0
    for c1 in range(-NZAG, 0):
        DZAG = DZAG + DZ[c1]
    RSOLV = (IEXT * (0.6 * (RDIRVE + RDIRVW + RDIFVE + RDIFVW + 2.0 * RREFL) / 2.0 + RSKY + RGRND) +
             JEXT * (0.6 * (RDIRVN + RDIRVS + RDIFVN + RDIFVS + 2.0 * RREFL) / 2.0 + RSKY + RGRND)) / (IEXT + JEXT)

def TRIDI1D(A, B, C, X, R, N):
    """1D tridiagonal solver"""
    A[N-1] = A[N-1] / B[N-1]
    R[N-1] = R[N-1] / B[N-1]
    for c1 in range(2, N + 1):
        II = -c1 + N + 2
        BN = 1.0 / (B[II-2] - A[c1-1] * C[II-2])
        A[c1-2] = A[c1-2] * BN
        R[c1-2] = (R[c1-2] - C[II-2] * R[c1-1]) * BN
    X[0] = R[0]
    for c1 in range(2, N + 1):
        X[c1-1] = R[c1-1] - A[c1-1] * X[c1-2]

def PrelimOutput(ACEIL, AFLOOR, ARIM, ASILL, AWALL, PERIM, RUNID, TDBH, TDBC):
    """Preliminary output"""
    # Writes to InputEcho file
    pass

def GetWeatherData(Today):
    """Get weather data for a day"""
    global TodaysWeather
    if Today > 365:
        return
    TodaysWeather.TDB = FullYearWeather[Today].TDB
    TodaysWeather.TWB = FullYearWeather[Today].TWB
    TodaysWeather.PBAR = FullYearWeather[Today].PBAR
    TodaysWeather.HRAT = FullYearWeather[Today].HRAT
    TodaysWeather.WND = FullYearWeather[Today].WND
    TodaysWeather.RBEAM = FullYearWeather[Today].RBEAM
    TodaysWeather.RDIFH = FullYearWeather[Today].RDIFH
    TodaysWeather.ISNW = FullYearWeather[Today].ISNW
    TodaysWeather.DSNOW = FullYearWeather[Today].DSNOW

def BasementHeatBalance(TB, TC, TF, TRS, TRW, TSS, TSW, TWS, TWW, HIN, DX, DY, DZ, XDIM, YDIM, ZDIM):
    """Calculate basement heat balance"""
    C1 = 0.0; C2 = 0.0; F1 = 0.0; F2 = 0.0
    RS1 = 0.0; RS2 = 0.0; RW1 = 0.0; RW2 = 0.0
    SS1 = 0.0; SS2 = 0.0; SW1 = 0.0; SW2 = 0.0
    WS1 = 0.0; WS2 = 0.0; WW1 = 0.0; WW2 = 0.0
    QC1 = np.zeros((XDIM + 1, YDIM + 1))
    QC2 = np.zeros((XDIM + 1, YDIM + 1))
    QF1 = np.zeros((XDIM + 1, YDIM + 1))
    QF2 = np.zeros((XDIM + 1, YDIM + 1))
    QRS1 = np.zeros(YDIM + 1)
    QRS2 = np.zeros(YDIM + 1)
    QRW1 = np.zeros(XDIM + 1)
    QRW2 = np.zeros(XDIM + 1)
    QSS1 = np.zeros((XDIM + 1, YDIM + 1))
    QSS2 = np.zeros((XDIM + 1, YDIM + 1))
    QSW1 = np.zeros((XDIM + 1, YDIM + 1))
    QSW2 = np.zeros((XDIM + 1, YDIM + 1))
    QWS1 = np.zeros((YDIM + 1, 2 * 35 + ZDIM + 1))
    QWS2 = np.zeros((YDIM + 1, 2 * 35 + ZDIM + 1))
    QWW1 = np.zeros((XDIM + 1, 2 * 35 + ZDIM + 1))
    QWW2 = np.zeros((XDIM + 1, 2 * 35 + ZDIM + 1))
    for c1 in range(0, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            if TB >= TC[c1, c2]:
                HINC = HIN[1]
            else:
                HINC = HIN[0]
            QC1[c1, c2] = HINC * DX[c1] * DY[c2] * TC[c1, c2]
            QC2[c1, c2] = HINC * DX[c1] * DY[c2]
            C1 += QC1[c1, c2]
            C2 += QC2[c1, c2]
    for c1 in range(0, IBASE):
        for c2 in range(0, JBASE):
            if TB > TF[c1, c2]:
                HINF = HIN[0]
            else:
                HINF = HIN[1]
            QF1[c1, c2] = HINF * DX[c1] * DY[c2] * TF[c1, c2]
            QF2[c1, c2] = HINF * DX[c1] * DY[c2]
            F1 += QF1[c1, c2]
            F2 += QF2[c1, c2]
    for c2 in range(0, JBASE + 2):
        QRS1[c2] = HIN[2] * DY[c2] * DZ[-NZAG + 1] * TRS[c2]
        QRS2[c2] = HIN[2] * DY[c2] * DZ[-NZAG + 1]
        RS1 += QRS1[c2]
        RS2 += QRS2[c2]
    for c1 in range(0, IBASE + 2):
        QRW1[c1] = HIN[2] * DX[c1] * DZ[-NZAG + 1] * TRW[c1]
        QRW2[c1] = HIN[2] * DX[c1] * DZ[-NZAG + 1]
        RW1 += QRW1[c1]
        RW2 += QRW2[c1]
    for c1 in range(IBASE, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            if TB > TSS[c1, c2]:
                HINSS = HIN[0]
            else:
                HINSS = HIN[1]
            QSS1[c1, c2] = HINSS * DX[c1] * DY[c2] * TSS[c1, c2]
            QSS2[c1, c2] = HINSS * DX[c1] * DY[c2]
            SS1 += QSS1[c1, c2]
            SS2 += QSS2[c1, c2]
    for c2 in range(JBASE, JBASE + 2):
        for c1 in range(0, IBASE):
            if TB > TSW[c1, c2]:
                HINSW = HIN[0]
            else:
                HINSW = HIN[1]
            QSW1[c1, c2] = HINSW * DX[c1] * DY[c2] * TSW[c1, c2]
            QSW2[c1, c2] = HINSW * DX[c1] * DY[c2]
            SW1 += QSW1[c1, c2]
            SW2 += QSW2[c1, c2]
    for c2 in range(0, JBASE):
        for c3 in range(-NZAG + 2, KBASE):
            QWS1[c2, c3] = HIN[2] * DY[c2] * DZ[c3] * TWS[c2, c3]
            QWS2[c2, c3] = HIN[2] * DY[c2] * DZ[c3]
            WS1 += QWS1[c2, c3]
            WS2 += QWS2[c2, c3]
    for c1 in range(0, IBASE):
        for c3 in range(-NZAG + 2, KBASE):
            QWW1[c1, c3] = HIN[2] * DX[c1] * DZ[c3] * TWW[c1, c3]
            QWW2[c1, c3] = HIN[2] * DX[c1] * DZ[c3]
            WW1 += QWW1[c1, c3]
            WW2 += QWW2[c1, c3]
    if C2 + F2 + RS2 + RW2 + SS2 + SW2 + WS2 + WW2 != 0:
        TB = (C1 + F1 + RS1 + RW1 + SS1 + SW1 + WS1 + WW1) / (C2 + F2 + RS2 + RW2 + SS2 + SW2 + WS2 + WW2)

def TRIDI3D(AA, BB, CC, RR, N, X):
    """3D tridiagonal solver"""
    AA[N-1] = AA[N-1] / BB[N-1]
    RR[N-1] = RR[N-1] / BB[N-1]
    for L in range(2, N + 1):
        LL = -L + N + 2
        BN = 1.0 / (BB[LL-2] - AA[L-1] * CC[LL-2])
        AA[LL-2] = AA[LL-2] * BN
        RR[LL-2] = (RR[LL-2] - CC[LL-2] * RR[L-1]) * BN
    X[0] = RR[0]
    for L in range(2, N + 1):
        X[L-1] = RR[L-1] - AA[L-1] * X[L-2]

def Jan21Output(IHR, TC, TF, TRS, TRW, TSS, TSW, TWS, TWW, XDIM, YDIM, ZDIM, XC, YC, ZC):
    """January 21st output"""
    for c1 in range(0, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            pass  # WRITE to Ceil121
    for c1 in range(0, IBASE):
        for c2 in range(0, JBASE):
            pass  # WRITE to Flor121
    for c2 in range(0, JBASE + 2):
        pass  # WRITE to RMJS121
    for c1 in range(0, IBASE + 2):
        pass  # WRITE to RMJW121
    for c1 in range(IBASE, IBASE + 2):
        for c2 in range(0, JBASE + 2):
            pass  # WRITE to SILS121
    for c1 in range(0, IBASE):
        for c2 in range(JBASE, JBASE + 2):
            pass  # WRITE to SILW121
    for c2 in range(0, JBASE):
        for c3 in range(-NZAG + 2, KBASE):
            pass  # WRITE to WALS121
    for c1 in range(0, IBASE):
        for c3 in range(-NZAG + 2, KBASE):
            pass  # WRITE to WALW121

def OutputLoads(HLOAD, CLOAD, CONDITION):
    """Output loads"""
    pass  # WRITE to LOADFile

def MainOutput(TCMN, TCMX, TFMN, TFMX, TRMN, TRMX, TSMN, TSMX, TWMN, TWMX,
               QCMN, QCMX, QFMN, QFMX, QRMN, QRMX, QSMN, QSMX, QWMN, QWMX,
               DTCA, DTFA, DTRA, DTSA, DTWA, DQCA, DQFA, DQRA, DQSA, DQWA, DTDBA, DTBA):
    """Main output"""
    pass  # WRITE to DOUT

def HouseLoadOutput(QHOUSE, EFFECT):
    """House load output"""
    pass  # WRITE to QHouseFile

def Day21Output(IMON, IBASE, JBASE, KBASE, NZAG, DTRW21, DTRS21, DTC21,
                DTWW21, DTWS21, DTSW21, DTSS21, DQWW21, DQWS21, DQSW21, DQSS21,
                DQRW21, DQRS21, DQF21, DQC21, DTF21, TV1, TV2, TV3, NXM1, NZBGM1,
                XDIM, YDIM, ZDIM, XC, YC, ZC):
    """Day 21 output"""
    pass  # WRITE to multiple output files

def DailyOutput(DQCSUM, DQFSUM, DQRSUM, DQSSUM, DQWSUM):
    """Daily output"""
    pass  # WRITE to DYFLX

def YearlyOutput(YHLOAD, YCLOAD, YQCSUM, YQFSUM, YQRSUM, YQSSUM, YQWSUM, YQBSUM):
    """Yearly output"""
    pass  # WRITE to LOADFile and DYFLX

def InitializeTemps(NXM1, NZBGM1, NYM1, T):
    """Initialize temperatures"""
    for c1 in range(0, NXM1 + 1):
        for c2 in range(0, NYM1 + 1):
            for c3 in range(-NZAG, NZBGM1 + 1):
                pass  # WRITE to unit 75

def AutoGridding():
    """Auto gridding"""
    global XFACE, YFACE, ZFACEINIT, IBASE, JBASE, KBASE, NX, NY, NZAG, NZBG
    DWALL = BuildingData.DWALL
    DGRAVXY = BuildingData.DGRAVXY
    DGRAVZN = BuildingData.DGRAVZN
    DSLAB = BuildingData.DSLAB
    EDGE1 = SLABX / 2.0
    EDGE2 = SLABY / 2.0
    EDGE1M3 = EDGE1 - 3.0
    EDGE2M3 = EDGE2 - 3.0
    DOMAINEDGEX = EDGE1 + CLEARANCE + DWALL + DGRAVXY
    DOMAINEDGEY = EDGE2 + CLEARANCE + DWALL + DGRAVXY
    ODD = False
    if EDGE1M3 % 2.0 != 0.0:
        NX1 = int(EDGE1M3) // 2 + 1
        ODD = True
    else:
        NX1 = int(EDGE1M3) // 2
        ODD = False
    NX2 = 4; NX3 = 1; NX4 = 3; NX5 = 3; NX6 = 2
    NX7 = 4; NX8 = 2; NX9 = 1
    NX10 = int((CLEARANCE - 3) / 2)
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
    c1 = 1
    while c1 <= NX:
        if XFACE[c1] < XFACE[c1 - 1]:
            NX = NX - 1
        else:
            c1 += 1
    for c1 in range(IBASE + NX5 + NX6 + NX7 + NX8 + NX9 + 1, NX):
        XFACE[c1] = XFACE[c1 - 1] + 2.0
    for c1 in range(NX + 1, 51):
        XFACE[c1] = 0.0
    # Similar for Y direction
    if EDGE2M3 % 2.0 != 0.0:
        NY1 = int(EDGE2M3) // 2 + 1
        ODD = True
    else:
        NY1 = int(EDGE2M3) // 2
        ODD = False
    NY2 = 4; NY3 = 1; NY4 = 3; NY5 = 3; NY6 = 2
    NY7 = 4; NY8 = 2; NY9 = 1
    NY10 = int((CLEARANCE - 3) / 2)
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
    for c1 in range(NY + 1, 51):
        YFACE[c1] = 0.0
    # Z direction
    CeilThick = 0.044
    RimJoistHeight = 0.235
    SillPlateHeight = 0.038
    if ((ConcAGHeight / 0.2) - int(ConcAGHeight / 0.2)) > 0.001:
        NZP = int(ConcAGHeight / 0.2) + 1
    else:
        NZP = int(ConcAGHeight / 0.2)
    if NZP == 0:
        NZAG = 4
    else:
        NZAG = NZP + 3
    if BaseDepth % 0.2 > 0.0005:
        NZ1 = int(BaseDepth / 0.2) + 1
    else:
        NZ1 = int(BaseDepth / 0.2)
    NZ2 = 1; NZ3 = 1; NZ4 = 4; NZ5 = 2; NZ6 = 7
    NZBG = NZ1 + NZ2 + NZ3 + NZ4 + NZ5 + NZ6
    if NZBG > 100:
        DataGlobals.ShowSevereError('AutoGrid BaseDepth is too high, reduce it below 17.0 meters')
        DataGlobals.ShowContinueError('BaseDepth=[' + str(RoundSigDigits(BaseDepth, 4)) + '], ' +
            'resulting  NZBG=[' + str(RoundSigDigits(NZBG, 0)) + '] (max 100).')
        DataGlobals.ShowFatalError('Program terminates due to preceding condition(s).')
    ZFACEINIT[-NZAG + 3] = -ConcAGHeight
    ZFACEINIT[-NZAG + 2] = ZFACEINIT[-NZAG + 3] - SillPlateHeight
    ZFACEINIT[-NZAG + 1] = ZFACEINIT[-NZAG + 2] - RimJoistHeight
    ZFACEINIT[-NZAG] = ZFACEINIT[-NZAG + 1] - CeilThick
    for c3 in range(-NZAG + 4, 1):
        if NZAG == 4:
            ZFACEINIT[c3] = 0.0
        elif c3 == -NZAG + 4:
            ZFACEINIT[c3] = ZFACEINIT[-NZAG + 3] + (ConcAGHeight % 0.2)
        else:
            ZFACEINIT[c3] = ZFACEINIT[c3 - 1] + 0.2
        if c3 == 0:
            ZFACEINIT[c3] = 0.0
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

def CalcDZmin(DX, DY, DZINIT):
    """Calculate minimum DZ"""
    global ZFACE
    TSTEP = SimParams.TSTEP * 3600.0
    F = SimParams.F
    RHOUSED = RHO[4]
    CPUSED = CP[4]
    TCONUSED = TCON[4]
    DZMIN = np.zeros((NX, NY, 136))
    DZACT = np.zeros(136)
    for c1 in range(0, NX):
        for c2 in range(0, NY):
            for c3 in range(-NZAG, NZBG):
                SqrtArg = 1.0 / ((0.75 * RHOUSED * CPUSED) / (F * TCONUSED * TSTEP) -
                                  (1.0 / DX[c1] ** 2) - (1.0 / DY[c2] ** 2))
                if SqrtArg < 0.0 and abs(SqrtArg) <= 0.2:
                    SqrtArg = 0.0
                elif SqrtArg < 0.0:
                    DataGlobals.ShowSevereError('CalcDZmin: Argument [' + str(RoundSigDigits(SqrtArg, 3)) + '] to Sqrt < min threshold.')
                    DataGlobals.ShowContinueError('Check autogridding and ADI factor inputs for accuracy.')
                    DataGlobals.ShowFatalError('Program terminates due to preceding condition.')
                DZMIN[c1, c2, c3] = math.sqrt(SqrtArg)
                if DZINIT[c3] < DZMIN[c1, c2, c3]:
                    DZACT[c3] = DZMIN[c1, c2, c3]
                else:
                    DZACT[c3] = DZINIT[c3]
    ZFACE[-NZAG] = ZFACEINIT[-NZAG]
    ZFACE[-NZAG + 1] = ZFACEINIT[-NZAG + 1]
    ZFACE[-NZAG + 2] = ZFACEINIT[-NZAG + 2]
    ZFACE[-NZAG + 3] = ZFACEINIT[-NZAG + 3]
    ZFACE[0] = 0.0
    for c3 in range(-NZAG, NZBG + 1):
        if DZACT[c3] != DZINIT[c3]:
            ZFACE[c3] = ZFACE[c3 - 1] + DZACT[c3]
            if c3 == NZ1:
                ZFACE[c3] = ZFACEINIT[NZ1]
        else:
            ZFACE[c3] = ZFACEINIT[c3]

def SurfaceTemps(T, DX, DY, DZ, MTYPE, INS, TSurfWallXZ, TSurfWallYZ, TSurfFloor,
                 TSWallYZIn, TSWallXZIn, TSFloorIn, TSYZCL, TSXZCL, TSFXCL, TSFYCL,
                 XC, YC, ZC, TSurfWallYZUpper, TSurfWallYZUpperIn, TSurfWallXZUpper,
                 TSurfWallXZUpperIn, TSurfWallYZLower, TSurfWallYZLowerIn,
                 TSurfWallXZLower, TSurfWallXZLowerIn, DAPerim, DACore, DAYZUpperSum,
                 DAYZLowerSum, DAXZUpperSum, DAXZLowerSum, TSurfFloorPerim,
                 TSurfFloorPerimIn, TSurfFloorCore, TSurfFloorCoreIn, TWW, TWS, TF,
                 XDIM, YDIM, ZDIM, DAXZSum, DAYZSum, DAXYSum):
    """Calculate surface temperatures for EnergyPlus"""
    REXT = Insul.REXT
    DGRAVZP = BuildingData.DGRAVZP
    DGRAVZN = BuildingData.DGRAVZN
    DSLAB = BuildingData.DSLAB
    KEXT = ZFACE[KBASE] + DSLAB
    TSWYZ = np.zeros((101, 136))
    TSWXZ = np.zeros((101, 136))
    TSF = np.zeros((101, 101))
    TSWYZSum = 0.0; TSWXZSum = 0.0; TSFSum = 0.0
    DAYZSum = 0.0; DAXZSum = 0.0; DAXYSum = 0.0
    TYZSumIn = 0.0; TXZSumIn = 0.0; TXYSumIn = 0.0
    TSYZCLSum = 0.0; TSXZCLSum = 0.0
    TSFXCLSum = 0.0; TSFYCLSum = 0.0
    TSWYZLowerSum = 0.0; TSWYZUpperSum = 0.0
    TSWXZLowerSum = 0.0; TSWXZUpperSum = 0.0
    TSurfPerimSum = 0.0; TSFPerimInSum = 0.0
    TSurfCoreSum = 0.0; TSFCoreInSum = 0.0
    DAYZUpperSum = 0.0; DAYZLowerSum = 0.0
    DAXZUpperSum = 0.0; DAXZLowerSum = 0.0
    DAPerim = 0.0; DACore = 0.0
    for c2 in range(0, JBASE):
        for c3 in range(0, KBASE):
            if abs(TCON[MTYPE[IBASE + 3, c2, c3]]) > 1.0e-10:
                Rleft = (DX[IBASE + 3] / 2.0) / TCON[MTYPE[IBASE + 3, c2, c3]]
            else:
                DataGlobals.ShowSevereError('Thermal conductivity too small. Safe divide used.')
                Rleft = (DX[IBASE + 3] / 2.0) / 1.0e-10
            if abs(TCON[MTYPE[IBASE + 4, c2, c3]]) > 1.0e-10:
                Rright = (DX[IBASE + 4] / 2.0) / TCON[MTYPE[IBASE + 4, c2, c3]] + INS[IBASE + 3, c2, c3] * REXT
            else:
                Rright = (DX[IBASE + 4] / 2.0) / 1.0e-10
            Tleft = T[IBASE + 3, c2, c3]
            Tright = T[IBASE + 4, c2, c3]
            TSWYZ[c2, c3] = (Tleft * Rright + Tright * Rleft) / (Rleft + Rright)
            TSWYZSum += TSWYZ[c2, c3] * DY[c2] * DZ[c3]
            TYZSumIn += TWS[c2, c3] * DY[c2] * DZ[c3]
            DAYZSum += DY[c2] * DZ[c3]
            if NZAG == 4:
                if ZC[c3] <= ZC[1 + (KBASE - NZAG) // 2]:
                    TSWYZUpperSum += TSWYZ[c2, c3] * DY[c2] * DZ[c3]
                    TSWYZUpperSumIn += TWS[c2, c3] * DY[c2] * DZ[c3]
                    DAYZUpperSum += DY[c2] * DZ[c3]
                else:
                    TSWYZLowerSum += TSWYZ[c2, c3] * DY[c2] * DZ[c3]
                    TSWYZLowerSumIn += TWS[c2, c3] * DY[c2] * DZ[c3]
                    DAYZLowerSum += DY[c2] * DZ[c3]
            else:
                if ZC[c3] <= (KEXT + DGRAVZP - DGRAVZN) / 2.0:
                    TSWYZUpperSum += TSWYZ[c2, c3] * DY[c2] * DZ[c3]
                    TSWYZUpperSumIn += TWS[c2, c3] * DY[c2] * DZ[c3]
                    DAYZUpperSum += DY[c2] * DZ[c3]
                else:
                    TSWYZLowerSum += TSWYZ[c2, c3] * DY[c2] * DZ[c3]
                    TSWYZLowerSumIn += TWS[c2, c3] * DY[c2] * DZ[c3]
                    DAYZLowerSum += DY[c2] * DZ[c3]
    TSurfWallYZ = TSWYZSum / DAYZSum
    TSWallYZIn = TYZSumIn / DAYZSum
    TSurfWallYZUpper = TSWYZUpperSum / DAYZUpperSum
    TSurfWallYZUpperIn = TSWYZUpperSumIn / DAYZUpperSum
    TSurfWallYZLower = TSWYZLowerSum / DAYZLowerSum
    TSurfWallYZLowerIn = TSWYZLowerSumIn / DAYZLowerSum
    TSYZCL = 0.0
    TSYZCLSum = 0.0
    for c3 in range(0, KBASE):
        TSYZCLSum += TSWYZ[(JBASE // 2), c3]
    TSYZCL = TSYZCLSum / KBASE
    for c1 in range(0, IBASE):
        for c3 in range(0, KBASE):
            TSWXZ[c1, c3] = (T[c1, JBASE + 3, c3] * (1.0 / (INS[c1, JBASE + 3, c3] * REXT +
                (DY[JBASE + 3] / 2.0) / TCON[MTYPE[c1, JBASE + 3, c3]])) +
                T[c1, JBASE + 4, c3] * (TCON[MTYPE[c1, JBASE + 4, c3]] / (DY[JBASE + 4] / 2.0))) / \
                ((1.0 / (INS[c1, JBASE + 3, c3] * REXT + (DY[JBASE + 3] / 2.0) /
                TCON[MTYPE[c1, JBASE + 3, c3]])) + (TCON[MTYPE[c1, JBASE + 4, c3]] / (DY[JBASE + 4] / 2.0)))
            TSWXZSum += TSWXZ[c1, c3] * DX[c1] * DZ[c3]
            TXZSumIn += TWW[c1, c3] * DX[c1] * DZ[c3]
            DAXZSum += DX[c1] * DZ[c3]
            if NZAG == 4:
                if ZC[c3] <= ZC[1 + (KBASE - NZAG) // 2]:
                    TSWXZUpperSum += TSWXZ[c1, c3] * DX[c1] * DZ[c3]
                    TSWXZUpperSumIn += TWW[c1, c3] * DX[c1] * DZ[c3]
                    DAXZUpperSum += DX[c1] * DZ[c3]
                else:
                    TSWXZLowerSum += TSWXZ[c1, c3] * DX[c1] * DZ[c3]
                    TSWXZLowerSumIn += TWW[c1, c3] * DX[c1] * DZ[c3]
                    DAXZLowerSum += DX[c1] * DZ[c3]
            else:
                if ZC[c3] <= (KEXT + DGRAVZP - DGRAVZN) / 2.0:
                    TSWXZUpperSum += TSWXZ[c1, c3] * DX[c1] * DZ[c3]
                    TSWXZUpperSumIn += TWW[c1, c3] * DX[c1] * DZ[c3]
                    DAXZUpperSum += DX[c1] * DZ[c3]
                else:
                    TSWXZLowerSum += TSWXZ[c1, c3] * DX[c1] * DZ[c3]
                    TSWXZLowerSumIn += TWW[c1, c3] * DX[c1] * DZ[c3]
                    DAXZLowerSum += DX[c1] * DZ[c3]
    TSurfWallXZ = TSWXZSum / DAXZSum
    TSWallXZIn = TXZSumIn / DAXZSum
    TSurfWallXZUpper = TSWXZUpperSum / DAXZUpperSum
    TSurfWallXZUpperIn = TSWXZUpperSumIn / DAXZUpperSum
    TSurfWallXZLower = TSWXZLowerSum / DAXZLowerSum
    TSurfWallXZLowerIn = TSWXZLowerSumIn / DAXZLowerSum
    TSXZCL = 0.0
    TSXZCLSum = 0.0
    for c3 in range(0, KBASE):
        TSXZCLSum += TSWXZ[IBASE // 2, c3]
    TSXZCL = TSXZCLSum / (KBASE + 1)
    for c1 in range(0, IBASE):
        for c2 in range(0, JBASE):
            TSF[c1, c2] = ((T[c1, c2, KBASE + 1] * TCON[MTYPE[c1, c2, KBASE + 1]]) / (DZ[KBASE + 1] / 2.0) +
                (T[c1, c2, KBASE + 2] * TCON[MTYPE[c1, c2, KBASE + 2]]) / (DZ[KBASE + 2] / 2.0)) / \
                ((TCON[MTYPE[c1, c2, KBASE + 1]] / (DZ[KBASE + 1] / 2.0)) +
                (TCON[MTYPE[c1, c2, KBASE + 2]] / (DZ[KBASE + 2] / 2.0)))
            TSFSum += TSF[c1, c2] * DX[c1] * DY[c2]
            TXYSumIn += TF[c1, c2] * DX[c1] * DY[c2]
            DAXYSum += DX[c1] * DY[c2]
            if abs(XC[c1]) > (XFACE[IBASE] - 2.0) or abs(YC[c2]) > (YFACE[JBASE] - 2.0):
                TSurfPerimSum += TSF[c1, c2] * DX[c1] * DY[c2]
                TSFPerimInSum += TF[c1, c2] * DX[c1] * DY[c2]
                DAPerim += DX[c1] * DY[c2]
            else:
                TSurfCoreSum += TSF[c1, c2] * DX[c1] * DY[c2]
                TSFCoreInSum += TF[c1, c2] * DX[c1] * DY[c2]
                DACore += DX[c1] * DY[c2]
    TSurfFloor = TSFSum / DAXYSum
    TSFloorIn = TXYSumIn / DAXYSum
    TSurfFloorPerim = TSurfPerimSum / DAPerim
    TSurfFloorPerimIn = TSFPerimInSum / DAPerim
    TSurfFloorCore = TSurfCoreSum / DACore
    TSurfFloorCoreIn = TSFCoreInSum / DACore
    TSFXCL = 0.0
    TSFXCLSum = 0.0
    TSFYCL = 0.0
    TSFYCLSum = 0.0
    for c2 in range(0, JBASE):
        TSFXCLSum += TSF[0, c2]
    TSFXCL = TSFXCLSum / JBASE
    for c1 in range(0, IBASE):
        TSFYCLSum += TSF[c1, 0]
    TSFYCL = TSFYCLSum / IBASE

def EPlusOutput(IHR, IDAY, TSurfWallXZ, TSurfWallYZ, TSurfFloor, TSWallYZIn,
                TSWallXZIn, TSFloorIn, TSYZCL, TSXZCL, TSFXCL, TSFYCL, TSurfWallYZUpper,
                TSurfWallYZUpperIn, TSurfWallXZUpper, TSurfWallXZUpperIn,
                TSurfWallYZLower, TSurfWallYZLowerIn, TSurfWallXZLower,
                TSurfWallXZLowerIn, TSurfFloorPerim, TSurfFloorPerimIn, TSurfFloorCore,
                TSurfFloorCoreIn, FloorHeatFlux, CoreHeatFlux, PerimHeatFlux,
                XZWallHeatFlux, YZWallHeatFlux, UpperXZWallFlux, UpperYZWallFlux,
                LowerXZWallFlux, LowerYZWallFlux, TB, TCON_LOCAL):
    """EnergyPlus output"""
    LastDayInMonth = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    DaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    # Monthly averaging logic here
    pass

def COSD(degree_value):
    return math.cos(degree_value * pi / 180.0)

def ACOSD(degree_value):
    return math.acos(max(-1.0, min(1.0, degree_value))) * 180.0 / pi

def SIND(degree_value):
    return math.sin(degree_value * pi / 180.0)

def ASIND(degree_value):
    return math.asin(max(-1.0, min(1.0, degree_value))) * 180.0 / pi

def EPlusHeader():
    """Write EPlus headers"""
    pass  # Writes headers to output files

def AvgHeatFlux(DACore, DAPerim, XC, YC, ZC, DX, DY, DZ, QWS, QWW, QF, XDIM, YDIM, ZDIM,
                FloorHeatFlux, CoreHeatFlux, PerimHeatFlux, XZWallHeatFlux, YZWallHeatFlux,
                UpperXZWallFlux, UpperYZWallFlux, LowerXZWallFlux, LowerYZWallFlux,
                DAYZUpperSum, DAYZLowerSum, DAXZUpperSum, DAXZLowerSum, DAXZSum, DAYZSum, DAXYSum):
    """Calculate average heat fluxes"""
    DGRAVZP = BuildingData.DGRAVZP
    DGRAVZN = BuildingData.DGRAVZN
    DSLAB = BuildingData.DSLAB
    KEXT = ZFACE[KBASE] + DSLAB
    QFloorSum = 0.0; QFloorPerimSum = 0.0; QFloorCoreSum = 0.0
    QXZWallUpperSum = 0.0; QXZWallLowerSum = 0.0
    QYZWallUpperSum = 0.0; QYZWallLowerSum = 0.0
    QXZWallSum = 0.0; QYZWallSum = 0.0
    for c1 in range(0, IBASE):
        for c2 in range(0, JBASE):
            QFloorSum += QF[c1, c2] * DX[c1] * DY[c2]
            if abs(XC[c1]) > (XFACE[IBASE] - 2.0) or abs(YC[c2]) > (YFACE[JBASE] - 2.0):
                QFloorPerimSum += QF[c1, c2] * DX[c1] * DY[c2]
            else:
                QFloorCoreSum += QF[c1, c2] * DX[c1] * DY[c2]
    FloorHeatFlux = QFloorSum / DAXYSum
    CoreHeatFlux = QFloorCoreSum / DACore
    PerimHeatFlux = QFloorPerimSum / DAPerim
    for c1 in range(0, IBASE):
        for c3 in range(0, KBASE):
            QXZWallSum += QWW[c1, c3] * DX[c1] * DZ[c3]
            if NZAG == 4:
                if ZC[c3] <= ZC[1 + (KBASE - NZAG) // 2]:
                    QXZWallUpperSum += QWW[c1, c3] * DX[c1] * DZ[c3]
                else:
                    QXZWallLowerSum += QWW[c1, c3] * DX[c1] * DZ[c3]
            else:
                if ZC[c3] <= (KEXT + DGRAVZP - DGRAVZN) / 2.0:
                    QXZWallUpperSum += QWW[c1, c3] * DX[c1] * DZ[c3]
                else:
                    QXZWallLowerSum += QWW[c1, c3] * DX[c1] * DZ[c3]
    XZWallHeatFlux = QXZWallSum / DAXZSum
    UpperXZWallFlux = QXZWallUpperSum / DAXZUpperSum
    LowerXZWallFlux = QXZWallLowerSum / DAXZLowerSum
    for c2 in range(0, JBASE):
        for c3 in range(0, KBASE):
            QYZWallSum += QWS[c2, c3] * DY[c2] * DZ[c3]
            if NZAG == 4:
                if ZC[c3] <= ZC[1 + (KBASE - NZAG) // 2]:
                    QYZWallUpperSum += QWS[c2, c3] * DY[c2] * DZ[c3]
                else:
                    QYZWallLowerSum += QWS[c2, c3] * DY[c2] * DZ[c3]
            else:
                if ZC[c3] <= (KEXT + DGRAVZP - DGRAVZN) / 2.0:
                    QYZWallUpperSum += QWS[c2, c3] * DY[c2] * DZ[c3]
                else:
                    QYZWallLowerSum += QWS[c2, c3] * DY[c2] * DZ[c3]
    YZWallHeatFlux = QYZWallSum / DAYZSum
    UpperYZWallFlux = QYZWallUpperSum / DAYZUpperSum
    LowerYZWallFlux = QYZWallLowerSum / DAYZLowerSum

def CloseIO():
    """Close I/O files"""
    pass  # Close all opened files

def InitializeTG(TG):
    """Initialize ground temperature"""
    ZFACEUsed = ZFACEINIT.copy()
    HTDB = np.zeros(8760)
    IHrStart = 1
    IHrEnd = 24
    for IDAY in range(1, 366):
        GetWeatherData(IDAY)
        TDB = TodaysWeather.TDB
        HTDB[IHrStart - 1:IHrEnd] = TDB
        IHrStart += 24
        IHrEnd += 24
    # Compute monthly averages
    HourNum = 0
    ACHSum = 0
    AHHSum = 0
    for IHR in range(1, 8760):
        if HTDB[IHR - 1] > TDeadBandUp:
            ACHSum += 1
        elif HTDB[IHR - 1] < TDeadBandLow:
            AHHSum += 1
    SiteInfo.ACH = ACHSum
    SiteInfo.AHH = AHHSum
    TAVG = np.zeros(12)
    for IMON in range(1, 13):
        TempSum = 0.0
        for IDAY in range(1, NDIM[IMON - 1] + 1):
            for IHR in range(1, 25):
                HourNum += 1
                TempSum += HTDB[HourNum - 1]
            TAVG[IMON - 1] = TempSum / (IDAY * 24)
    TmSum = 0.0
    TAvgMax = -99999.0
    TAvgMin = 99999.0
    for IMON in range(1, 13):
        TmSum += TAVG[IMON - 1]
        TAvgMax = max(TAvgMax, TAVG[IMON - 1])
        TAvgMin = min(TAvgMin, TAVG[IMON - 1])
    Tm = TmSum / 12.0
    As = (TAvgMax - TAvgMin) / 2.0
    for c1 in range(0, NZBG + 1):
        TG[c1] = Tm - As * math.exp(-0.4464 * ZFACEUsed[c1]) * COSD(0.5236 * (-1.0 - 0.8525 * ZFACEUsed[c1]))
        if c1 == 20:
            TG[c1] = Tm

def WeatherServer():
    """Weather server - parse EPW file"""
    # ReadEPW would be called here
    SiteInfo.LONG = 0.0
    SiteInfo.LAT = 0.0
    SiteInfo.MSTD = 0.0
    SiteInfo.ELEV = 0.0
    for IDAY in range(1, 366):
        for IHR in range(1, 25):
            ISNW = np.zeros(24, dtype=int)
            DSNOW = np.zeros(24)
            if IDAY <= 365:
                # WDAY would be read from EPW file
                if FullYearWeather[IDAY].DSNOW[IHR - 1] > 0 and FullYearWeather[IDAY].DSNOW[IHR - 1] < 999.0:
                    ISNW[IHR - 1] = 1
                    DSNOW[IHR - 1] = FullYearWeather[IDAY].DSNOW[IHR - 1]
                else:
                    ISNW[IHR - 1] = 0
                    DSNOW[IHR - 1] = 0.0
        if IDAY == 366:
            continue
        FullYearWeather[IDAY].TDB = np.zeros(24)
        FullYearWeather[IDAY].TWB = np.zeros(24)
        FullYearWeather[IDAY].PBAR = np.zeros(24)
        FullYearWeather[IDAY].HRAT = np.zeros(24)
        FullYearWeather[IDAY].WND = np.zeros(24)
        FullYearWeather[IDAY].RBEAM = np.zeros(24)
        FullYearWeather[IDAY].RDIFH = np.zeros(24)
        FullYearWeather[IDAY].ISNW = ISNW
        FullYearWeather[IDAY].DSNOW = DSNOW

def DrySatPt(SATUPT, TDB):
    """Calculate dry air saturation pressure"""
    TT = float(TDB)
    PSAT = 0.0
    if TDB > 20:
        if TDB < 30:
            PSAT = 6.10775e2 + 44.4502 * TT + 1.38578 * TT**2 + 3.3106e-2 * TT**3
        elif TDB < 40:
            PSAT = 4.05663e2 + 76.8637 * TT - 0.447857 * TT**2 + 7.15905e-2 * TT**3
        elif TDB < 80:
            PSAT = 7.30208e2 + 32.987 * TT + 1.84658 * TT**2 + 1.95497e-2 * TT**3 + 3.33617e-4 * TT**4 + 2.59343e-6 * TT**5
        else:
            PSAT = 6.91607e2 + 10.703 * TT + 3.01092 * TT**2 - 2.57247e-3 * TT**3 + 5.19714e-4 * TT**4 + 2.00552e-6 * TT**5
    elif TDB > 10:
        PSAT = 5.9088e2 + 49.8847 * TT + 0.874643 * TT**2 + 4.97621e-2 * TT**3
    elif TDB > 0:
        PSAT = 6.10775e2 + 44.4502 * TT + 1.38578 * TT**2 + 3.3106e-2 * TT**3
    elif TDB > -20:
        PSAT = 6.10860e2 + 50.1255 * TT + 1.83622 * TT**2 + 3.67769e-2 * TT**3 + 3.41421e-4 * TT**4
    elif TDB > -40:
        PSAT = 5.69275e2 + 42.5035 * TT + 1.29301 * TT**2 + 1.88391e-2 * TT**3 + 1.0961e-4 * TT**4
    else:
        PSAT = 4.9752e2 + 35.3452 * TT + 1.04398 * TT**2 + 1.5962e-2 * TT**3 + 1.2578e-4 * TT**4 + 4.0683e-7 * TT**5
    SATUPT = PSAT

def GetField(InputString, Fldno, ReturnString, Delimiter=','):
    """Get field from delimited string"""
    ReturnString = ' '
    Fld = 1
    LastPos = 1
    delim = Delimiter if Delimiter else ','
    pos = -1
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
    return ReturnString.strip()


# ============================================================
# Main Program
# ============================================================
def BasementModel():
    """Main program"""
    Time_Start = 0.0
    Time_Finish = 0.0
    Base3Ddriver()
    # EndEnergyPlus would be called here

if __name__ == "__main__":
    BasementModel()
