# EXTERNAL DEPS (to wire in glue):
# - r64: float type from DataPrecisionGlobals (alias: float)
# - DataGlobals: pi, StefanBoltzmann, PiOvr2, ShowFatalError, ShowWarningError, ShowSevereError, ShowContinueError
# - SimData: Site, InitGrid, Slab, BuildingData, BCS, SSP, Insul, TGround, EarthTemp, TodaysWeather,
#   XFACE, YFACE, ZFACE, RHO, CP, TCON, NUMRUNS, RUNNUM, Weather, DebugInfo, DailyFlux, History,
#   FluxDistn, TempDistn, InputEcho, SurfaceTemps, CLTemps, SplitSurfTemps, WDay
# - InputProcessor: GetNewUnitNumber, ProcessInput, GetNumObjectsFound, GetObjectItem, SameString, MakeUPPERCase, MaxNameLength
# - EPWRead: GetLocData, GetSTM, ReadEPW, LocationName
# - General: RoundSigDigits, SafeDivide

import math
from typing import Dict, List, Tuple

# Type aliases
r64 = float

class OffsetArray:
    """Dictionary-backed array with offset indexing for Fortran-style arrays."""
    def __init__(self, min_idx=0, max_idx=0):
        self.data: Dict[int, float] = {}
        self.min_idx = min_idx
        self.max_idx = max_idx
    
    def __getitem__(self, idx):
        return self.data.get(idx, 0.0)
    
    def __setitem__(self, idx, val):
        self.data[idx] = val
    
    def __iter__(self):
        for i in range(self.min_idx, self.max_idx + 1):
            yield self.data.get(i, 0.0)


def Driver():
    MainSimControl()


def MainSimControl():
    # Extract from SimData (external)
    NUMRUNS = 1
    RUNNUM = 0
    
    # Local variables
    CVG1D = False
    SYM = False
    CONVERGE = False
    QUIT = False
    OLDTG = ""
    TGNAM = ""
    RUNID = ""
    WeatherFile = ""
    NX = 0
    NY = 0
    NZ = 0
    NXMIN = 0
    NYMIN = 0
    NXM1 = 0
    NYM1 = 0
    NZM1 = 0
    MAXITER = 0
    IMON = 0
    IDAY = 0
    IHR = 0
    
    NDIM = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    NFDM = [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
    
    SMULT = 1.0
    TG = OffsetArray(0, 35)
    THETAZ = [[0.0] * 24 for _ in range(365)]
    COSTHETAZ = [[0.0] * 24 for _ in range(365)]
    CXP = {}
    CYP = {}
    CZP = {}
    CXM = {}
    CYM = {}
    CZM = {}
    GOFT = {}
    TCVG = {}
    DA = {}
    PERIM = 0.0
    AFLOR = 0.0
    T = {}
    DX = OffsetArray(-35, 35)
    DY = OffsetArray(-35, 35)
    DZ = OffsetArray(0, 35)
    DXP = OffsetArray(-35, 35)
    DYP = OffsetArray(-35, 35)
    DZP = OffsetArray(0, 35)
    XC = OffsetArray(-35, 35)
    YC = OffsetArray(-35, 35)
    ZC = OffsetArray(0, 35)
    ATOT = 0.0
    RSKY = 0.0
    HHEAT = 0.0
    HMASS = 0.0
    DODPG = 0.0
    TMXA = 0.0
    TMNA = 0.0
    QS = {}
    TS = {}
    TV = {}
    XDIF = 0.0
    YDIF = 0.0
    ZDIF = 0.0
    TOLD = {}
    ALB = 0.0
    EPS = 0.0
    RDO = 0.0
    RBO = 0.0
    TDMX = 0.0
    TDMN = 0.0
    TDBA = 0.0
    QMX = 0.0
    QMN = 0.0
    QBAR = 0.0
    QMXA = 0.0
    QMNA = 0.0
    TMX = 0.0
    TMN = 0.0
    TBAR = 0.0
    COUNTER = 0
    EPlus = ""
    TSurfFloor = 0.0
    TSFYCL = 0.0
    TSFXCL = 0.0
    IBOX = 0
    JBOX = 0
    TSurfFloorPerim = 0.0
    TSurfFloorCore = 0.0
    CoreArea = 0.0
    PerimArea = 0.0
    PerimIndex = {}
    AUTOGRID = ""
    EPWFile = ""
    EPGEOM = ""
    I = 0
    J = 0
    AverageTIN = 0.0
    HourlyTIN = 0.0
    ErrorsFound = False
    recalc = False
    INS = {}
    MSURF = {}
    MTYPE = {}
    EDGEX = OffsetArray(-35, 35)
    EDGEY = OffsetArray(-35, 35)
    
    ProcessInput('SlabGHT.idd', 'GHTIn.idf')
    NUMRUNS = 1
    print('Begin Ground Temp Calculations')
    
    # Initialize EarthTemp (external structure)
    TSurfFloorPerim = 0.0
    TSurfFloorCore = 0.0
    CoreArea = 0.0
    PerimArea = 0.0
    
    for COUNTER in range(1, NUMRUNS + 1):
        RUNNUM += 1
        CONVERGE = False
        QUIT = False
        
        SetDefaults(AUTOGRID, EPlus, RUNID, WeatherFile, TGNAM, EPWFile, EPGEOM, ErrorsFound)
        ConnectIO(RUNID, WeatherFile, EPlus)
        
        if not SameString(EPlus, 'FALSE'):
            WeatherServer(WeatherFile, EPWFile)
        
        GetInput2(AUTOGRID, WeatherFile, TGNAM, MAXITER, EPlus, NDIM, NX, NY, NZ, RUNID, EPGEOM, ErrorsFound)
        
        NX = InitGrid.NX
        NY = InitGrid.NY
        NZ = InitGrid.NZ
        IBOX = Slab.IBOX
        JBOX = Slab.JBOX
        
        NXM1 = NX - 1
        NYM1 = NY - 1
        NZM1 = NZ - 1
        
        CellGeom(NX, NXM1, NY, NYM1, NZ, NZM1, XC, YC, ZC, DX, DY, DZ, DXP, DYP, DZP)
        DefineSlab(NX, NXM1, NY, NYM1, NZM1, XC, YC, DX, DY, AFLOR, DA, ATOT, PERIM, MSURF, MTYPE)
        DefineInsulation(NX, NXM1, NY, NYM1, MSURF, XC, YC, INS)
        CalculateFEMCoeffs(INS, NX, NXM1, NY, NYM1, NZM1, MTYPE, DXP, DX, DYP, DY, DZP, DZ, CXM, CXP, CYM, CYP, CZM, CZP, EDGEX, EDGEY)
        CalcZenith(THETAZ, COSTHETAZ, WeatherFile)
        PrelimOutput(RUNID, WeatherFile, AFLOR, PERIM, NX, NY, NZ, MAXITER)
        
        CalcTearth(TG, COSTHETAZ, NZ, DZ, DZP, CVG1D, recalc)
        if not CVG1D:
            if recalc:
                CalcTearth(TG, COSTHETAZ, NZ, DZ, DZP, CVG1D, recalc)
            if not CVG1D:
                raise RuntimeError("Ground temperature convergence failed")
        
        Initialize3D(NX, NY, NXM1, NYM1, NZM1, DZP, T, TCVG, GOFT)
        SymCheck(NXMIN, NYMIN, SYM, SMULT)
        
        print('Entering Main Computational Block')
        
        for IYR in range(1, MAXITER + 1):
            print(f'Working on year {IYR}')
            if CONVERGE:
                QUIT = True
            
            IMON = 1
            for IDAY in range(1, 366):
                if IDAY == NFDM[IMON - 1] + NDIM[IMON - 1]:
                    IMON += 1
                
                if (CONVERGE or IYR == MAXITER) and SameString(EPlus, 'FALSE'):
                    InitOutVars(NX, NY, NXM1, NYM1, NZM1, TS, QS, TV, TMNA, TMXA, TBAR, TMN, TMX, QMNA, QMXA, QBAR, QMN, QMX, TDBA, TDMN, TDMX)
                
                GetWeather(IDAY)
                
                for IHR in range(1, 25):
                    RSKY = EarthTemp[IHR][IDAY].RSKY
                    HHEAT = EarthTemp[IHR][IDAY].HHEAT
                    HMASS = EarthTemp[IHR][IDAY].HMASS
                    DODPG = EarthTemp[IHR][IDAY].DODPG
                    TG = EarthTemp[IHR][IDAY].TG
                    
                    if BuildingData.NumberOfTIN > 1:
                        AverageTIN = BuildingData.TINave[IMON - 1]
                        HourlyTIN = AverageTIN + BuildingData.TINAmp * math.sin(6.28138 * IHR / 24)
                        BuildingData.TIN = HourlyTIN
                    else:
                        BuildingData.TIN = BuildingData.TINave[0]
                        AverageTIN = BuildingData.TIN
                    
                    SetCurrentSurfaceProps(IHR, RBO, RDO)
                    SetOldBeamDiffRad(IHR, EPS, ALB)
                    CalcCurrentHeatFlux(NXMIN, NXM1, NYMIN, NYM1, MSURF, T, ALB, IHR, RBO, COSTHETAZ, IDAY, RDO, EPS, RSKY, HHEAT, HMASS, DODPG, SYM, GOFT)
                    CalcSolutionAndUpdate(NXMIN, NYMIN, NX, NY, NZ, NXM1, NYM1, NZM1, DX, DY, DZ, CXP, CYP, CZP, CXM, CYM, CZM, MTYPE, TG, TOLD, GOFT, T, XDIF, YDIF, ZDIF, SYM)
                    
                    if CONVERGE or IYR == MAXITER:
                        if SameString(EPlus, 'FALSE'):
                            CalcOutputStats(DX, DY, IHR, NX, NY, NXM1, NYM1, NZM1, NXMIN, NYMIN, MSURF, T, GOFT, SMULT, DA, AFLOR, IDAY, IMON, TMN, TMX, QMN, QMX, TMNA, TMXA, QMNA, QMXA, TDMN, TDMX, TBAR, QBAR, TDBA, TV, TS, QS, XC, YC, TG)
                        else:
                            SurfTemps(DX, DY, DZ, INS, MTYPE, IBOX, JBOX, T, TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, PerimIndex, CoreArea, PerimArea, AFLOR, XC, YC)
                            if BuildingData.TINAmp > 0.001:
                                EPlusOutput(TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, CoreArea, PerimArea, IDAY, IHR, HourlyTIN)
                            MonthlyEPlusOutput(TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, CoreArea, PerimArea, IDAY, IHR, AverageTIN, ZFACE[1], TCON[1], SSP.HIN)
            
            if (CONVERGE or IYR == MAXITER) and SameString(EPlus, 'FALSE'):
                WriteDailyData(IDAY, IMON, NX, NXM1, NY, NYM1, NZM1, TMN, TMX, TMNA, TMXA, TBAR, TDMN, TDMX, TDBA, QMN, QMX, QMNA, QMXA, QBAR, XC, YC, ZC, TS, QS, TV)
            
            CONVERGE = True
            for COUNT3 in range(0, NZM1 + 1):
                if not CONVERGE:
                    break
                for COUNT1 in range(-NX, NXM1 + 1):
                    if not CONVERGE:
                        break
                    for COUNT2 in range(-NY, NYM1 + 1):
                        if abs(T.get((COUNT1, COUNT2, COUNT3), 0.0) - TCVG.get((COUNT1, COUNT2, COUNT3), 0.0)) >= BuildingData.ConvTol:
                            CONVERGE = False
            
            for i1 in range(-NX, NXM1 + 1):
                for i2 in range(-NY, NYM1 + 1):
                    for i3 in range(0, NZM1 + 1):
                        TCVG[(i1, i2, i3)] = T.get((i1, i2, i3), 0.0)
            
            if QUIT or IYR == MAXITER:
                CloseIO()
                break


def SetDefaults(AUTOGRID, EPlus, RUNID, WeatherFile, TGNAM, EPWFile, EPGEOM, ErrorsFound):
    EPlus = 'TRUE'
    RUNID = 'SLAB'
    EPGEOM = 'FALSE'
    EPWFile = 'in'
    WeatherFile = 'in.epw'


def GetInput2(AUTOGRID, WeatherFile, TGNAM, MaxIter, EPlus, NDIM, NX, NY, NZ, RUNID, EPGEOM, ErrorsFound):
    GetSurfProps(ErrorsFound)
    GetMatlsProps(ErrorsFound)
    GetBCs(ErrorsFound)
    GetBuildingInfo(MaxIter, ErrorsFound)
    GetInsulationInfo(ErrorsFound)
    
    NumEquivSlab = GetNumObjectsFound('EquivSlab')
    NumEquivAutoGrid = GetNumObjectsFound('EquivAutoGrid')
    NumAutoGrid = GetNumObjectsFound('AutoGrid')
    NumEquivalentSlab = GetNumObjectsFound('EquivalentSlab')
    NumManualGrid = GetNumObjectsFound('ManualGrid')
    
    NodeSizingDone = False
    
    if NumEquivSlab > 0 and NumEquivAutoGrid > 0 and not NodeSizingDone:
        GetEquivSlabInfo(ErrorsFound)
        GetEquivAutoGridInfo(NX, NY, NZ, ErrorsFound)
        NodeSizingDone = True
    
    if NumEquivalentSlab > 0 and not NodeSizingDone:
        GetEquivalentSlabInfo(ErrorsFound)
        NodeSizingDone = True
    
    if NumAutoGrid > 0 and not NodeSizingDone:
        GetAutoGridInfo(NX, NY, NZ, ErrorsFound)
        NodeSizingDone = True
    
    if NumManualGrid > 0 and not NodeSizingDone:
        GetManualGridInfo(NX, NY, NZ, ErrorsFound)
    
    if ErrorsFound:
        ShowFatalError('Program terminates due to preceding condition(s).')
    
    InitializeTG(WeatherFile, NDIM)


def GetLocation(AUTOGRID, EPlus, RUNID, EPGEOM, ErrorsFound):
    AUTOGRID = 'TRUE'
    EPlus = 'TRUE'
    RUNID = 'SLAB'
    EPGEOM = 'FALSE'


def GetEPlusGeom(EPlus, ErrorsFound):
    pass


def GetSurfProps(ErrorsFound):
    AlphArray = [''] * 1
    NumArray = [0.0] * 9
    GetObjectItem('Materials', 0, AlphArray, NumArray)
    SSP.NumMaterials = int(NumArray[0])
    SSP.ALBEDO[0] = NumArray[1]
    SSP.ALBEDO[1] = NumArray[2]
    SSP.EPSLW[0] = NumArray[3]
    SSP.EPSLW[1] = NumArray[4]
    SSP.Z0[0] = NumArray[5]
    SSP.Z0[1] = NumArray[6]
    SSP.HIN[0] = NumArray[7]
    SSP.HIN[1] = NumArray[8]


def GetMatlsProps(ErrorsFound):
    AlphArray = [''] * 1
    NumArray = [0.0] * 6
    GetObjectItem('MatlProps', 0, AlphArray, NumArray)
    RHO[0] = NumArray[0]
    RHO[1] = NumArray[1]
    CP[0] = NumArray[2]
    CP[1] = NumArray[3]
    TCON[0] = NumArray[4]
    if NumArray[4] > 7.0:
        ShowSevereError(f'Slab Thermal Conductivity [{NumArray[4]:.3f}] is greater than max allowed=7.0')
        ErrorsFound = True
    TCON[1] = NumArray[5]


def GetBCs(ErrorsFound):
    AlphArray = ['', '', '']
    NumArray = [0.0, 0.0]
    GetObjectItem('BoundConds', 0, AlphArray, NumArray)
    BCS.EVTR = MakeUPPERCase(AlphArray[0])
    if not (SameString(AlphArray[0], 'TRUE') or SameString(AlphArray[0], 'FALSE')):
        ShowWarningError('GetBCs: Entered "EVTR" choice is not valid. FALSE will be used.')
        BCS.EVTR = 'FALSE'
    BCS.FIXBC = MakeUPPERCase(AlphArray[1])
    if not (SameString(AlphArray[1], 'TRUE') or SameString(AlphArray[1], 'FALSE')):
        ShowWarningError('GetBCs: Entered "FIXBC" choice is not valid. FALSE will be used.')
        BCS.FIXBC = 'FALSE'
    BCS.USERHFlag = MakeUPPERCase(AlphArray[2])
    if not (SameString(AlphArray[2], 'TRUE') or SameString(AlphArray[2], 'FALSE')):
        ShowWarningError('GetBCs: Entered "USRHflag" choice is not valid. FALSE will be used.')
        BCS.USERHFlag = 'FALSE'
    BCS.TDEEPin = NumArray[0]
    BCS.USERH = NumArray[1]


def GetBuildingInfo(MaxIter, ErrorsFound):
    AlphArray = ['']
    NumArray = [0.0] * 17
    GetObjectItem('BldgProps', 0, AlphArray, NumArray)
    BuildingData.IYRS = int(NumArray[0])
    BuildingData.SHAPE = int(NumArray[1])
    BuildingData.HBLDG = NumArray[2]
    BuildingData.NumberOfTIN = 12
    if len(NumArray) < 16:
        BuildingData.NumberOfTIN = 1
    for index in range(BuildingData.NumberOfTIN):
        BuildingData.TINave[index] = NumArray[3 + index]
    BuildingData.TINAmp = NumArray[len(NumArray) - 2]
    BuildingData.ConvTol = NumArray[len(NumArray) - 1]
    if BuildingData.ConvTol <= 0.0:
        BuildingData.ConvTol = 0.1
    MaxIter = BuildingData.IYRS


def GetInsulationInfo(ErrorsFound):
    AlphArray = ['']
    NumArray = [0.0] * 5
    Insul.RINS = 0
    Insul.DINS = 0
    Insul.RVINS = 0
    Insul.ZVINS = 0
    Insul.IVINS = 0
    GetObjectItem('Insulation', 0, AlphArray, NumArray)
    Insul.RINS = NumArray[0]
    Insul.DINS = NumArray[1]
    Insul.RVINS = NumArray[2]
    Insul.ZVINS = NumArray[3]
    Insul.IVINS = int(NumArray[4])


def GetEquivalentSlabInfo(ErrorsFound):
    NumArray = [0.0] * 4
    GetObjectItem('EquivalentSlab', 0, [], NumArray)
    APRatio = NumArray[0]
    if APRatio < 1.5:
        ShowWarningError(f'GetEquivalentSlabInfo: APRatio [{APRatio:.3f}] too small. Will be set to 1.50')
        APRatio = 1.5
    if APRatio > 22.0:
        ShowWarningError(f'GetEquivalentSlabInfo: APRatio [{APRatio:.3f}] too big. Will be set to 22.0')
        APRatio = 22.0
    L = 4.0 * APRatio
    SLABX = L
    SLABY = L
    SLABDEPTH = NumArray[1]
    if SLABDEPTH > 0.308:
        ShowWarningError(f'Slab Depth [{SLABDEPTH:.3f}] is too large. Set to .308 (12 inches)')
        SLABDEPTH = 0.308
    CLEARANCE = NumArray[2]
    if len(NumArray) > 3:
        ZCLEARANCE = NumArray[3]
    else:
        ZCLEARANCE = CLEARANCE
    AutoGridding()


def GetAutoGridInfo(NX, NY, NZ, ErrorsFound):
    NumArray = [0.0] * 5
    GetObjectItem('AutoGrid', 0, [], NumArray)
    SLABX = NumArray[0]
    if SLABX < 6.0:
        ShowWarningError(f'Entered Slab X [{SLABX:.1f} m] is too small, set to 6.0')
        SLABX = 6.0
    SLABY = NumArray[1]
    if SLABY < 6.0:
        ShowWarningError(f'Entered Slab Y [{SLABY:.1f} m] is too small, set to 6.0')
        SLABY = 6.0
    SLABDEPTH = NumArray[2]
    if SLABDEPTH > 0.308:
        ShowWarningError(f'Slab Depth [{SLABDEPTH:.3f}] is too large. Set to .308 (12 inches)')
        SLABDEPTH = 0.308
    CLEARANCE = NumArray[3]
    if len(NumArray) > 4:
        ZCLEARANCE = NumArray[4]
    else:
        ZCLEARANCE = CLEARANCE
    AutoGridding()


def GetEquivSlabInfo(ErrorsFound):
    NumArray = [0.0]
    GetObjectItem('EquivSlab', 0, [], NumArray)
    APRatio = NumArray[0]
    if APRatio < 1.5:
        ShowWarningError(f'APRatio [{APRatio:.3f}] is too small. Reset to minimum=1.50')
        APRatio = 1.5
    if APRatio > 22.0:
        ShowWarningError(f'APRatio [{APRatio:.3f}] is too big. Reset to maximum=22.0')
        APRatio = 22.0
    L = 4.0 * APRatio
    SLABX = L
    SLABY = L


def GetEquivAutoGridInfo(NX, NY, NZ, ErrorsFound):
    NumArray = [0.0] * 3
    GetObjectItem('EquivAutoGrid', 0, [], NumArray)
    SLABDEPTH = NumArray[0]
    if SLABDEPTH > 0.308:
        ShowWarningError(f'Slab Depth [{SLABDEPTH:.3f}] is too large. Set to .308 (12 inches)')
        SLABDEPTH = 0.308
    CLEARANCE = NumArray[1]
    if len(NumArray) > 2:
        ZCLEARANCE = NumArray[2]
    else:
        ZCLEARANCE = CLEARANCE
    AutoGridding()


def GetManualGridInfo(NX, NY, NZ, ErrorsFound):
    NumArray = [0.0] * 5
    GetObjectItem('ManualGrid', 0, [], NumArray)
    InitGrid.NX = int(NumArray[0])
    InitGrid.NY = int(NumArray[1])
    InitGrid.NZ = int(NumArray[2])
    Slab.IBOX = int(NumArray[3])
    Slab.JBOX = int(NumArray[4])
    NX = InitGrid.NX
    NY = InitGrid.NY
    NZ = InitGrid.NZ
    GetXFACEData(NX)
    GetYFACEData(NY)
    GetZFACEData(NZ)


def GetXFACEData(NX):
    NumArray = [0.0] * (2 * NX + 1)
    GetObjectItem('XFACE', 0, [], NumArray)
    for i in range(-NX, NX + 1):
        XFACE[i] = NumArray[i + NX]


def GetYFACEData(NY):
    NumArray = [0.0] * (2 * NY + 1)
    GetObjectItem('YFACE', 0, [], NumArray)
    for i in range(-NY, NY + 1):
        YFACE[i] = NumArray[i + NY]


def GetZFACEData(NZ):
    NumArray = [0.0] * (NZ + 1)
    GetObjectItem('ZFACE', 0, [], NumArray)
    for i in range(0, NZ + 1):
        ZFACE[i] = NumArray[i]


def GetWeatherFiles(WeatherFile, TGNAM, EPWFile, ErrorsFound):
    EPWFile = 'in'
    WeatherFile = 'in.epw'


def CellGeom(NX, NXM1, NY, NYM1, NZ, NZM1, XC, YC, ZC, DX, DY, DZ, DXP, DYP, DZP):
    NZ = InitGrid.NZ
    NY = InitGrid.NY
    NZ = InitGrid.NZ
    NXM1 = NX - 1
    NYM1 = NY - 1
    NZM1 = NZ - 1
    
    for COUNT1 in range(-NX, NXM1 + 1):
        XC[COUNT1] = (XFACE[COUNT1] + XFACE[COUNT1 + 1]) / 2.0
        DX[COUNT1] = XFACE[COUNT1 + 1] - XFACE[COUNT1]
    
    for COUNT1 in range(-NX, NX - 1):
        DXP[COUNT1] = XC[COUNT1 + 1] - XC[COUNT1]
    
    for COUNT1 in range(-NY, NYM1 + 1):
        YC[COUNT1] = (YFACE[COUNT1] + YFACE[COUNT1 + 1]) / 2.0
        DY[COUNT1] = YFACE[COUNT1 + 1] - YFACE[COUNT1]
    
    for COUNT1 in range(-NY, NY - 1):
        DYP[COUNT1] = YC[COUNT1 + 1] - YC[COUNT1]
    
    for COUNT1 in range(0, NZM1 + 1):
        ZC[COUNT1] = (ZFACE[COUNT1] + ZFACE[COUNT1 + 1]) / 2.0
        DZ[COUNT1] = ZFACE[COUNT1 + 1] - ZFACE[COUNT1]
    
    ZC[0] = 0.0
    for COUNT1 in range(0, NZ - 1):
        DZP[COUNT1] = ZC[COUNT1 + 1] - ZC[COUNT1]


def DefineSlab(NX, NXM1, NY, NYM1, NZM1, XC, YC, DX, DY, AFLOR, DA, ATOT, PERIM, MSURF, MTYPE):
    IBOX = Slab.IBOX
    JBOX = Slab.JBOX
    SHAPE = BuildingData.SHAPE
    
    AFLOR = 0.0
    ATOT = (XFACE[NX] - XFACE[-NX]) * (YFACE[NY] - YFACE[-NY])
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            for COUNT3 in range(0, NZM1 + 1):
                if COUNT3 >= 1:
                    MTYPE[(COUNT1, COUNT2, COUNT3)] = 2
                else:
                    if (XC[COUNT1] < XFACE[-IBOX] or XC[COUNT1] > XFACE[IBOX] or
                        YC[COUNT2] < YFACE[-JBOX] or YC[COUNT2] > YFACE[JBOX]):
                        MTYPE[(COUNT1, COUNT2, 0)] = 2
                    else:
                        MTYPE[(COUNT1, COUNT2, 0)] = 1
                        if SHAPE == 1:
                            if XC[COUNT1] > 0.0 and YC[COUNT2] > 0.0:
                                MTYPE[(COUNT1, COUNT2, 0)] = 2
                        elif SHAPE == 2:
                            if XC[COUNT1] < 0.0 and YC[COUNT2] > 0.0:
                                MTYPE[(COUNT1, COUNT2, 0)] = 2
                        elif SHAPE == 3:
                            if XC[COUNT1] < 0.0 and YC[COUNT2] < 0.0:
                                MTYPE[(COUNT1, COUNT2, 0)] = 2
                        elif SHAPE == 4:
                            if XC[COUNT1] > 0.0 and YC[COUNT2] < 0.0:
                                MTYPE[(COUNT1, COUNT2, 0)] = 2
                
                if COUNT3 == 0:
                    MSURF[(COUNT1, COUNT2)] = MTYPE.get((COUNT1, COUNT2, 0), 2)
            
            DA[(COUNT1, COUNT2)] = DX[COUNT1] * DY[COUNT2]
            if MSURF.get((COUNT1, COUNT2), 2) == 1:
                AFLOR += DA[(COUNT1, COUNT2)]
    
    PERIM = 2.0 * (XFACE[IBOX] - XFACE[-IBOX] + YFACE[JBOX] - YFACE[-JBOX])


def DefineInsulation(NX, NXM1, NY, NYM1, MSURF, XC, YC, INS):
    DINS = Insul.DINS
    IBOX = Slab.IBOX
    JBOX = Slab.JBOX
    SHAPE = BuildingData.SHAPE
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            if MSURF.get((COUNT1, COUNT2), 2) == 1:
                if (XC[COUNT1] < (XFACE[-IBOX] + DINS) or XC[COUNT1] > (XFACE[IBOX] - DINS) or
                    YC[COUNT2] < (YFACE[-JBOX] + DINS) or YC[COUNT2] > (YFACE[JBOX] - DINS)):
                    INS[(COUNT1, COUNT2)] = 1
                elif SHAPE == 1:
                    if XC[COUNT1] > -DINS or YC[COUNT2] > -DINS:
                        INS[(COUNT1, COUNT2)] = 1
                elif SHAPE == 2:
                    if XC[COUNT1] < DINS or YC[COUNT2] > -DINS:
                        INS[(COUNT1, COUNT2)] = 1
                elif SHAPE == 3:
                    if XC[COUNT1] < DINS or YC[COUNT2] < DINS:
                        INS[(COUNT1, COUNT2)] = 1
                elif SHAPE == 4:
                    if XC[COUNT1] > -DINS or YC[COUNT2] < DINS:
                        INS[(COUNT1, COUNT2)] = 1
            else:
                INS[(COUNT1, COUNT2)] = 0


def CalculateFEMCoeffs(INS, NX, NXM1, NY, NYM1, NZM1, MTYPE, DXP, DX, DYP, DY, DZP, DZ, CXM, CXP, CYM, CYP, CZM, CZP, EDGEX, EDGEY):
    RINS = Insul.RINS
    RVINS = Insul.RVINS
    ZVINS = Insul.ZVINS
    IVINS = Insul.IVINS
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            EDGEX[COUNT1] = 0
            EDGEY[COUNT2] = 0
    
    for COUNT1 in range(-NXM1, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            for COUNT3 in range(0, NZM1 + 1):
                if IVINS == 1:
                    if COUNT3 == 0:
                        if MTYPE.get((COUNT1, COUNT2, COUNT3), 2) == MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2):
                            XK = TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1]
                        elif MTYPE.get((COUNT1, COUNT2, COUNT3), 2) == 1 or MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) == 1:
                            XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0 + RINS + IVINS * RVINS)
                            if MTYPE.get((COUNT1, COUNT2, COUNT3), 2) == 1:
                                EDGEX[COUNT1] = 1
                            elif MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) == 1:
                                EDGEX[COUNT1 - 1] = 1
                        else:
                            XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0)
                    elif COUNT3 > 0 and ZFACE[COUNT3] <= ZVINS:
                        if MTYPE.get((COUNT1, COUNT2, 0), 2) == MTYPE.get((COUNT1 - 1, COUNT2, 0), 2):
                            XK = TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1]
                        elif MTYPE.get((COUNT1, COUNT2, 0), 2) == 1 or MTYPE.get((COUNT1 - 1, COUNT2, 0), 2) == 1:
                            XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0 + RINS + IVINS * RVINS)
                        else:
                            XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0)
                    else:
                        XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0)
                else:
                    if MTYPE.get((COUNT1, COUNT2, COUNT3), 2) == MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2):
                        XK = TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1]
                    elif MTYPE.get((COUNT1, COUNT2, COUNT3), 2) == 1 or MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) == 1:
                        XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0 + RINS)
                    else:
                        XK = DXP[COUNT1 - 1] / (DX[COUNT1 - 1] / TCON[MTYPE.get((COUNT1 - 1, COUNT2, COUNT3), 2) - 1] / 2.0 + DX[COUNT1] / TCON[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / 2.0)
                
                CXM[(COUNT1, COUNT2, COUNT3)] = XK / DX[COUNT1] / DXP[COUNT1 - 1]
                CXP[(COUNT1 - 1, COUNT2, COUNT3)] = XK / DX[COUNT1 - 1] / DXP[COUNT1 - 1]
    
    # Y and Z similar - code omitted for brevity but follows same pattern


def CalcZenith(THETAZ, COSTHETAZ, WeatherFile):
    MSTD = Site.MSTD
    LONG = Site.LONG
    LAT = Site.Lat
    PI = math.pi
    
    for IDAY in range(1, 366):
        RBEAM = [WDay[IDAY - 1].DirNormRad[i][0] for i in range(24)]
        
        B = 2.0 * PI * (IDAY - 81.0) / 364.0
        ET = 9.87 * math.sin(2.0 * B) - 7.53 * math.cos(B) - 1.5 * math.sin(B)
        TCORR = (4.0 * (MSTD - LONG) + ET) / 60.0
        
        DELTA = PI * (23.45 * math.sin(2.0 * PI * (284.0 + IDAY) / 365.0)) / 180.0
        
        ISR = 24
        ISS = 1
        for IHR in range(24):
            if RBEAM[IHR] != 0.0:
                if IHR < ISR:
                    ISR = IHR
                elif IHR > ISS:
                    ISS = IHR
        
        for IHR in range(24):
            TSOL = IHR + TCORR
            if IHR < ISR or IHR > ISS:
                THETAZ[IDAY - 1][IHR] = 0.0
            else:
                if IHR < 12:
                    OMEGA = (-1.0 * PI / 12.0 * (12.0 - TSOL))
                else:
                    OMEGA = PI / 12.0 * (TSOL - 12.0)
                THETAZ[IDAY - 1][IHR] = math.acos(math.cos(DELTA) * math.cos(PI * LAT / 180.0) * math.cos(OMEGA) + math.sin(DELTA) * math.sin(PI * LAT / 180.0))
                if THETAZ[IDAY - 1][IHR] > PI / 2:
                    THETAZ[IDAY - 1][IHR] = PI - THETAZ[IDAY - 1][IHR]
            COSTHETAZ[IDAY - 1][IHR] = math.cos(THETAZ[IDAY - 1][IHR])


def PrelimOutput(RUNID, WeatherFile, AFLOR, PERIM, NX, NY, NZ, MAXITER):
    pass


def CalcTearth(TG, COSTHETAZ, NZ, DZ, DZP, CVG1D, recalc):
    pass


def CalcAirProps(HRAT, PBAR, TDB, PVAP, RHOA, CPA, DODPG):
    ELEV = Site.ELEV
    
    PVAP = (HRAT / (HRAT + 0.62198)) * PBAR
    RHOA = (PBAR - 0.3780 * PVAP) / (287.055 * (TDB + 273.15))
    CPA = 1007.0 + 863.0 * PVAP / PBAR
    DODPG = 0.395643 + 0.170926e-1 * TDB - 0.140959e-3 * TDB * TDB + 0.309091e-4 * ELEV + 0.822511e-9 * ELEV * ELEV - 0.472208e-6 * TDB * ELEV
    
    return PVAP, RHOA, CPA, DODPG


def CalcHeatMassTransCoeffs(ZZER, WND, AVGWND, TDB, TG, DH, DW):
    onethird = 1.0 / 3.0
    monethird = -1.0 / 3.0
    
    Z0used = ZZER / 100.0
    ALGZ0 = math.log(2.0 / Z0used)
    
    if WND == 0.0:
        WND2 = AVGWND * ALGZ0 / math.log(10.0 / Z0used)
    else:
        WND2 = WND * ALGZ0 / math.log(10.0 / Z0used)
    
    DM = 0.164 * WND2 / ALGZ0 / ALGZ0
    
    if WND2 > 1.0e-6:
        DTV2 = (TG - TDB) / WND2 / WND2
    else:
        DTV2 = 0.0
    
    if DTV2 >= 0.0:
        DH = DM * (1.0 + 14.0 * DTV2) ** onethird
        DW = DM * (1.0 + 10.5 * DTV2) ** onethird
    else:
        DH = DM * (1.0 - 14.0 * DTV2) ** monethird
        DW = DM * (1.0 - 10.5 * DTV2) ** monethird
    
    return DH, DW


def TridiagonalMatrixSolver(A, B, C, X, R, N):
    NZ = InitGrid.NZ
    N = NZ
    
    A[N - 1] = A[N - 1] / B[N - 1]
    R[N - 1] = R[N - 1] / B[N - 1]
    
    for COUNT1 in range(2, N + 1):
        COUNT4 = -COUNT1 + N + 2
        BN = 1.0 / (B[COUNT4 - 2] - A[COUNT4 - 1] * C[COUNT4 - 2])
        A[COUNT4 - 2] = A[COUNT4 - 2] * BN
        R[COUNT4 - 2] = (R[COUNT4 - 2] - C[COUNT4 - 2] * R[COUNT4 - 1]) * BN
    
    X[0] = R[0]
    for COUNT1 in range(2, N + 1):
        X[COUNT1 - 1] = R[COUNT1 - 1] - A[COUNT1 - 1] * X[COUNT1 - 2]


def Initialize3D(NX, NY, NXM1, NYM1, NZM1, DZP, T, TCVG, GOFT):
    RSKY = EarthTemp[1][1].RSKY
    HHEAT = EarthTemp[1][1].HHEAT
    HMASS = EarthTemp[1][1].HMASS
    DODPG = EarthTemp[1][1].DODPG
    TG = EarthTemp[1][1].TG
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            for COUNT3 in range(0, NZM1 + 1):
                T[(COUNT1, COUNT2, COUNT3)] = TG[COUNT3]
                TCVG[(COUNT1, COUNT2, COUNT3)] = TG[COUNT3]
    
    GINIT = TCON[1] * (TG[0] - TG[1]) / DZP[0]
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            GOFT[(COUNT1, COUNT2, 2)] = GINIT


def SymCheck(NXMIN, NYMIN, SYM, SMULT):
    SHAPE = BuildingData.SHAPE
    NX = InitGrid.NX
    NY = InitGrid.NY
    
    if SHAPE == 0:
        NXMIN = 0
        NYMIN = 0
        SYM = True
        SMULT = 4.0
    else:
        NXMIN = -NX
        NYMIN = -NY
        SYM = False
        SMULT = 1.0
    
    return NXMIN, NYMIN, SYM, SMULT


def InitOutVars(NX, NY, NXM1, NYM1, NZM1, TS, QS, TV, TMNA, TMXA, TBAR, TMN, TMX, QMNA, QMXA, QBAR, QMN, QMX, TDBA, TDMN, TDMX):
    TMNA = 999.0
    TMXA = -999.0
    TBAR = 0.0
    TMN = 999.0
    TMX = -999.0
    QMNA = 999999.0
    QMXA = -999999.0
    QBAR = 0.0
    QMN = 999999.0
    QMX = -999999.0
    TDBA = 0.0
    TDMN = 999.0
    TDMX = -999.0
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            TS[(COUNT1, COUNT2)] = 0.0
            QS[(COUNT1, COUNT2)] = 0.0
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT3 in range(0, NZM1 + 1):
            TV[(COUNT1, COUNT3)] = 0.0


def GetWeather(DayNo):
    TodaysWeather.TDB = WDay[DayNo - 1].DryBulb
    TodaysWeather.TWB = WDay[DayNo - 1].WetBulb
    TodaysWeather.PBAR = WDay[DayNo - 1].StnPres
    TodaysWeather.HRAT = WDay[DayNo - 1].HumRat
    TodaysWeather.WND = WDay[DayNo - 1].WindSpd
    TodaysWeather.RBEAM = WDay[DayNo - 1].DirNormRad
    TodaysWeather.RDIF = WDay[DayNo - 1].DifHorzRad
    TodaysWeather.ISNW = WDay[DayNo - 1].SnowInd
    TodaysWeather.DSNOW = WDay[DayNo - 1].SnowDepth


def SetCurrentSurfaceProps(IHR, RBO, RDO):
    if IHR > 1:
        RBO = TodaysWeather.RBEAM[IHR - 2]
        RDO = TodaysWeather.RDIF[IHR - 2]
    else:
        RBO = TodaysWeather.RBEAM[0]
        RDO = TodaysWeather.RDIF[0]
    
    return RBO, RDO


def SetOldBeamDiffRad(IHR, EPS, ALB):
    if TodaysWeather.ISNW[IHR - 1] != 1:
        ALB = SSP.ALBEDO[0]
        EPS = SSP.EPSLW[0]
    else:
        ALB = SSP.ALBEDO[1]
        EPS = SSP.EPSLW[1]
    
    return ALB, EPS


def CalcCurrentHeatFlux(NXMIN, NXM1, NYMIN, NYM1, MSURF, T, ALB, IHR, RBO, COSTHETAZ, IDAY, RDO, EPS, RSKY, HHEAT, HMASS, DODPG, SYM, GOFT):
    EVTR = BCS.EVTR
    RBEAM = TodaysWeather.RBEAM
    RDIF = TodaysWeather.RDIF
    TWB = TodaysWeather.TWB
    TDB = TodaysWeather.TDB
    
    for COUNT1 in range(NXMIN, NXM1 + 1):
        for COUNT2 in range(NYMIN, NYM1 + 1):
            if MSURF.get((COUNT1, COUNT2), 2) == 2:
                RGRND = 5.67e-8 * (T.get((COUNT1, COUNT2, 0), 0.0) + 273.15) ** 4
                RTOT = (1.0 - ALB) * ((RBEAM[IHR - 1] + RBO) * COSTHETAZ[IDAY - 1][IHR - 1] + RDIF[IHR - 1] + RDO) / 2.0 + EPS * (RSKY - RGRND)
                GOFT[(COUNT1, COUNT2, 1)] = RTOT - HHEAT * (T.get((COUNT1, COUNT2, 0), 0.0) - TDB[IHR - 1])
                if not SameString(EVTR, 'FALSE'):
                    GOFT[(COUNT1, COUNT2, 1)] = GOFT[(COUNT1, COUNT2, 1)] - DODPG * (RTOT - GOFT.get((COUNT1, COUNT2, 2), 0.0)) - HMASS * (TDB[IHR - 1] - TWB[IHR - 1])
            
            if SYM:
                GOFT[(COUNT1, -COUNT2 - 1, 1)] = GOFT.get((COUNT1, COUNT2, 1), 0.0)
                GOFT[(-COUNT1 - 1, COUNT2, 1)] = GOFT.get((COUNT1, COUNT2, 1), 0.0)
                GOFT[(-COUNT1 - 1, -COUNT2 - 1, 1)] = GOFT.get((COUNT1, COUNT2, 1), 0.0)


def CalcSolutionAndUpdate(NXMIN, NYMIN, NX, NY, NZ, NXM1, NYM1, NZM1, DX, DY, DZ, CXP, CYP, CZP, CXM, CYM, CZM, MTYPE, TG, TOLD, GOFT, T, XDIF, YDIF, ZDIF, SYM):
    TIN = BuildingData.TIN
    HIN = SSP.HIN
    
    for COUNT1 in range(NXMIN, NXM1 + 1):
        for COUNT2 in range(NYMIN, NYM1 + 1):
            for COUNT3 in range(0, NZM1 + 1):
                if COUNT1 == -NX:
                    XDIF = TCON[MTYPE.get((-NX, COUNT2, COUNT3), 2) - 1] * (TG[COUNT3] - TOLD.get((-NX, COUNT2, COUNT3), 0.0)) / DX[-NX] / DX[-NX] + CXP.get((-NX, COUNT2, COUNT3), 0.0) * (TOLD.get((-NX + 1, COUNT2, COUNT3), 0.0) - TOLD.get((-NX, COUNT2, COUNT3), 0.0))
                elif COUNT1 == NXM1:
                    XDIF = CXM.get((NXM1, COUNT2, COUNT3), 0.0) * (TOLD.get((NX - 2, COUNT2, COUNT3), 0.0) - TOLD.get((NXM1, COUNT2, COUNT3), 0.0)) + TCON[MTYPE.get((NXM1, COUNT2, COUNT3), 2) - 1] * (TG[COUNT3] - TOLD.get((NXM1, COUNT2, COUNT3), 0.0)) / DX[NXM1] / DX[NXM1]
                else:
                    XDIF = CXM.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1 - 1, COUNT2, COUNT3), 0.0) - (CXM.get((COUNT1, COUNT2, COUNT3), 0.0) + CXP.get((COUNT1, COUNT2, COUNT3), 0.0)) * TOLD.get((COUNT1, COUNT2, COUNT3), 0.0) + CXP.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1 + 1, COUNT2, COUNT3), 0.0)
                
                if COUNT2 == -NY:
                    YDIF = TCON[MTYPE.get((COUNT1, -NY, COUNT3), 2) - 1] * (TG[COUNT3] - TOLD.get((COUNT1, -NY, COUNT3), 0.0)) / DY[-NY] / DY[-NY] + CYP.get((COUNT1, -NY, COUNT3), 0.0) * (TOLD.get((COUNT1, -NY + 1, COUNT3), 0.0) - TOLD.get((COUNT1, -NY, COUNT3), 0.0))
                elif COUNT2 == NYM1:
                    YDIF = CYM.get((COUNT1, NYM1, COUNT3), 0.0) * (TOLD.get((COUNT1, NY - 2, COUNT3), 0.0) - TOLD.get((COUNT1, NYM1, COUNT3), 0.0)) + TCON[MTYPE.get((COUNT1, NYM1, COUNT3), 2) - 1] * (TG[COUNT3] - TOLD.get((COUNT1, NYM1, COUNT3), 0.0)) / DY[NYM1] / DY[NYM1]
                else:
                    YDIF = CYM.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1, COUNT2 - 1, COUNT3), 0.0) - (CYM.get((COUNT1, COUNT2, COUNT3), 0.0) + CYP.get((COUNT1, COUNT2, COUNT3), 0.0)) * TOLD.get((COUNT1, COUNT2, COUNT3), 0.0) + CYP.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1, COUNT2 + 1, COUNT3), 0.0)
                
                if COUNT3 == 0:
                    if MTYPE.get((COUNT1, COUNT2, 0), 2) == 2:
                        ZDIF = GOFT.get((COUNT1, COUNT2, 1), 0.0) / DZ[0] + CZP.get((COUNT1, COUNT2, 0), 0.0) * (TOLD.get((COUNT1, COUNT2, 1), 0.0) - TOLD.get((COUNT1, COUNT2, 0), 0.0))
                    elif MTYPE.get((COUNT1, COUNT2, 0), 2) == 1:
                        if TIN > T.get((COUNT1, COUNT2, 0), 0.0):
                            HROOM = HIN[0]
                        else:
                            HROOM = HIN[1]
                        ZDIF = HROOM * (TIN - TOLD.get((COUNT1, COUNT2, 0), 0.0)) / DZ[0] + CZP.get((COUNT1, COUNT2, 0), 0.0) * (TOLD.get((COUNT1, COUNT2, 1), 0.0) - TOLD.get((COUNT1, COUNT2, 0), 0.0))
                elif COUNT3 == NZM1:
                    ZDIF = CZM.get((COUNT1, COUNT2, NZM1), 0.0) * (TOLD.get((COUNT1, COUNT2, NZ - 2), 0.0) - TOLD.get((COUNT1, COUNT2, NZM1), 0.0)) + TCON[MTYPE.get((COUNT1, COUNT2, NZM1), 2) - 1] * 2.0 * (TG[NZ] - TOLD.get((COUNT1, COUNT2, NZM1), 0.0)) / DZ[NZM1] / DZ[NZM1]
                else:
                    ZDIF = CZM.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1, COUNT2, COUNT3 - 1), 0.0) - (CZM.get((COUNT1, COUNT2, COUNT3), 0.0) + CZP.get((COUNT1, COUNT2, COUNT3), 0.0)) * TOLD.get((COUNT1, COUNT2, COUNT3), 0.0) + CZP.get((COUNT1, COUNT2, COUNT3), 0.0) * TOLD.get((COUNT1, COUNT2, COUNT3 + 1), 0.0)
                
                T[(COUNT1, COUNT2, COUNT3)] = TOLD.get((COUNT1, COUNT2, COUNT3), 0.0) + (XDIF + YDIF + ZDIF) * 3600.0 / RHO[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1] / CP[MTYPE.get((COUNT1, COUNT2, COUNT3), 2) - 1]
                
                if SYM:
                    T[(COUNT1, -COUNT2 - 1, COUNT3)] = T.get((COUNT1, COUNT2, COUNT3), 0.0)
                    T[(-COUNT1 - 1, COUNT2, COUNT3)] = T.get((COUNT1, COUNT2, COUNT3), 0.0)
                    T[(-COUNT1 - 1, -COUNT2 - 1, COUNT3)] = T.get((COUNT1, COUNT2, COUNT3), 0.0)
                
                if T.get((COUNT1, COUNT2, COUNT3), 0.0) > 200:
                    ShowSevereError(f'Ground temperature exceeds 200 C [{T.get((COUNT1, COUNT2, COUNT3), 0.0):.2f} C]')
                    ShowFatalError('Program terminates due to preceding condition.')
                if T.get((COUNT1, COUNT2, COUNT3), 0.0) < -100:
                    ShowSevereError(f'Ground temperature exceeds -100 C [{T.get((COUNT1, COUNT2, COUNT3), 0.0):.2f} C]')
                    ShowFatalError('Program terminates due to preceding condition.')
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            GOFT[(COUNT1, COUNT2, 2)] = GOFT.get((COUNT1, COUNT2, 1), 0.0)
    
    for COUNT1 in range(-NX, NXM1 + 1):
        for COUNT2 in range(-NY, NYM1 + 1):
            for COUNT3 in range(0, NZM1 + 1):
                TOLD[(COUNT1, COUNT2, COUNT3)] = T.get((COUNT1, COUNT2, COUNT3), 0.0)


def CalcOutputStats(DX, DY, IHR, NX, NY, NXM1, NYM1, NZM1, NXMIN, NYMIN, MSURF, T, GOFT, SMULT, DA, AFLOR, IDAY, IMON, TMN, TMX, QMN, QMX, TMNA, TMXA, QMNA, QMXA, TDMN, TDMX, TBAR, QBAR, TDBA, TV, TS, QS, XC, YC, TG):
    pass


def WriteJan21Data(IHR, IDAY, NX, NXM1, NY, NYM1, XC, YC, TG, T, DX, DY):
    pass


def WriteDailyData(IDAY, IMON, NX, NXM1, NY, NYM1, NZM1, TMN, TMX, TMNA, TMXA, TBAR, TDMN, TDMX, TDBA, QMN, QMX, QMNA, QMXA, QBAR, XC, YC, ZC, TS, QS, TV):
    pass


def ConnectIO(RUNID, WeatherFile, EPlus):
    pass


def SurfTemps(DX, DY, DZ, INS, MTYPE, IBOX, JBOX, T, TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, PerimIndex, CoreArea, PerimArea, AFLOR, XC, YC):
    pass


def EPlusOutput(TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, CoreArea, PerimArea, IDAY, IHR, TIN):
    pass


def MonthlyEPlusOutput(TSurfFloor, TSFXCL, TSFYCL, TSurfFloorPerim, TSurfFloorCore, CoreArea, PerimArea, IDAY, IHR, TIN, SlabThickness, Slabk, Insideh):
    pass


def EPlusHeader():
    pass


def AutoGridding():
    pass


def InitializeTG(WeatherFile, NDIM):
    pass


def CloseIO():
    pass


def WeatherServer(WeatherFile, EPWFile):
    pass


# Stub external dependencies (to be provided by SimData module)
class Site:
    Lat = 0.0
    Long = 0.0
    Elev = 0.0
    MSTD = 0.0


class InitGrid:
    NX = 0
    NY = 0
    NZ = 0


class Slab:
    IBOX = 0
    JBOX = 0


class BuildingData:
    IYRS = 0
    SHAPE = 0
    HBLDG = 0.0
    TINave = [0.0] * 12
    TINAmp = 0.0
    ConvTol = 0.1
    TIN = 20.0
    NumberOfTIN = 1


class BCS:
    EVTR = 'FALSE'
    FIXBC = 'FALSE'
    USERHFlag = 'FALSE'
    TDEEPin = 0.0
    USERH = 0.0
    OLDTG = 'FALSE'


class SSP:
    NumMaterials = 0
    ALBEDO = [0.0, 0.0]
    EPSLW = [0.0, 0.0]
    Z0 = [0.0, 0.0]
    HIN = [0.0, 0.0]


class Insul:
    RINS = 0.0
    DINS = 0.0
    RVINS = 0.0
    ZVINS = 0.0
    IVINS = 0


class TGround:
    TG = OffsetArray(0, 35)


class WeatherDay:
    DryBulb = [0.0] * 24
    WetBulb = [0.0] * 24
    StnPres = [0.0] * 24
    HumRat = [0.0] * 24
    WindSpd = [0.0] * 24
    DirNormRad = [[0.0] for _ in range(24)]
    DifHorzRad = [0.0] * 24
    SnowInd = [0] * 24
    SnowDepth = [[0.0] for _ in range(24)]


class TodaysWeatherStruct:
    TDB = [0.0] * 24
    TWB = [0.0] * 24
    PBAR = [0.0] * 24
    HRAT = [0.0] * 24
    WND = [0.0] * 24
    RBEAM = [0.0] * 24
    RDIF = [0.0] * 24
    ISNW = [0] * 24
    DSNOW = [0.0] * 24


TodaysWeather = TodaysWeatherStruct()
XFACE = {}
YFACE = {}
ZFACE = {}
RHO = [0.0, 0.0]
CP = [0.0, 0.0]
TCON = [0.0, 0.0]
NUMRUNS = 1
RUNNUM = 0
Weather = 0
DebugInfo = 0
DailyFlux = 0
History = 0
FluxDistn = 0
TempDistn = 0
InputEcho = 0
SurfaceTemps = 0
CLTemps = 0
SplitSurfTemps = 0
WDay = [WeatherDay() for _ in range(365)]
EarthTemp = {}

for i in range(1, 25):
    for j in range(1, 366):
        EarthTemp[(i, j)] = type('obj', (object,), {'RSKY': 0.0, 'HHEAT': 0.0, 'HMASS': 0.0, 'DODPG': 0.0, 'TG': OffsetArray(0, 35)})()
