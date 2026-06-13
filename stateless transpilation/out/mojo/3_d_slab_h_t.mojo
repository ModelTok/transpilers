# EXTERNAL DEPS (to wire in glue):
# - Float64 type alias (r64)
# - DataGlobals: pi, StefanBoltzmann, PiOvr2
# - SimData: Site, InitGrid, Slab, BuildingData, BCS, SSP, Insul, TGround, EarthTemp, TodaysWeather,
#   XFACE, YFACE, ZFACE, RHO, CP, TCON, NUMRUNS, RUNNUM, and file units
# - InputProcessor: GetNewUnitNumber, ProcessInput, GetNumObjectsFound, GetObjectItem, SameString, MakeUPPERCase
# - EPWRead: GetLocData, GetSTM, ReadEPW, LocationName, WDay
# - General: RoundSigDigits, SafeDivide

from math import pi, acos, cos, sin, exp, log, sqrt

alias r64 = Float64

struct OffsetArray:
    var data: DynamicVector[Float64]
    var min_idx: Int
    var max_idx: Int
    
    fn __init__(min_idx: Int, max_idx: Int) -> Self:
        var size = max_idx - min_idx + 1
        return Self(data=DynamicVector[Float64](size), min_idx=min_idx, max_idx=max_idx)
    
    fn __getitem__(self, idx: Int) -> Float64:
        if idx >= self.min_idx and idx <= self.max_idx:
            return self.data[idx - self.min_idx]
        return 0.0
    
    fn __setitem__(inout self, idx: Int, val: Float64):
        if idx >= self.min_idx and idx <= self.max_idx:
            self.data[idx - self.min_idx] = val


fn Driver():
    MainSimControl()


fn MainSimControl():
    var NUMRUNS: Int = 1
    var RUNNUM: Int = 0
    var CVG1D: Bool = False
    var SYM: Bool = False
    var CONVERGE: Bool = False
    var QUIT: Bool = False
    var OLDTG: String = ""
    var TGNAM: String = ""
    var RUNID: String = ""
    var WeatherFile: String = ""
    var NX: Int = 0
    var NY: Int = 0
    var NZ: Int = 0
    var NXMIN: Int = 0
    var NYMIN: Int = 0
    var NXM1: Int = 0
    var NYM1: Int = 0
    var NZM1: Int = 0
    var MAXITER: Int = 0
    var IMON: Int = 0
    var IDAY: Int = 0
    var IHR: Int = 0
    
    var NDIM = InlineArray[Int, 12](31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    var NFDM = InlineArray[Int, 12](1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335)
    
    var SMULT: r64 = 1.0
    var PERIM: r64 = 0.0
    var AFLOR: r64 = 0.0
    var ATOT: r64 = 0.0
    var RSKY: r64 = 0.0
    var HHEAT: r64 = 0.0
    var HMASS: r64 = 0.0
    var DODPG: r64 = 0.0
    var TMXA: r64 = 0.0
    var TMNA: r64 = 0.0
    var XDIF: r64 = 0.0
    var YDIF: r64 = 0.0
    var ZDIF: r64 = 0.0
    var ALB: r64 = 0.0
    var EPS: r64 = 0.0
    var RDO: r64 = 0.0
    var RBO: r64 = 0.0
    var TDMX: r64 = 0.0
    var TDMN: r64 = 0.0
    var TDBA: r64 = 0.0
    var QMX: r64 = 0.0
    var QMN: r64 = 0.0
    var QBAR: r64 = 0.0
    var QMXA: r64 = 0.0
    var QMNA: r64 = 0.0
    var TMX: r64 = 0.0
    var TMN: r64 = 0.0
    var TBAR: r64 = 0.0
    var COUNTER: Int = 0
    var EPlus: String = ""
    var TSurfFloor: r64 = 0.0
    var TSFYCL: r64 = 0.0
    var TSFXCL: r64 = 0.0
    var IBOX: Int = 0
    var JBOX: Int = 0
    var TSurfFloorPerim: r64 = 0.0
    var TSurfFloorCore: r64 = 0.0
    var CoreArea: r64 = 0.0
    var PerimArea: r64 = 0.0
    var AUTOGRID: String = ""
    var EPWFile: String = ""
    var EPGEOM: String = ""
    var AverageTIN: r64 = 0.0
    var HourlyTIN: r64 = 0.0
    var ErrorsFound: Bool = False
    var recalc: Bool = False
    
    ProcessInput("SlabGHT.idd", "GHTIn.idf")
    NUMRUNS = 1
    print("Begin Ground Temp Calculations")
    
    TSurfFloorPerim = 0.0
    TSurfFloorCore = 0.0
    CoreArea = 0.0
    PerimArea = 0.0
    
    for _ in range(1, NUMRUNS + 1):
        RUNNUM += 1
        CONVERGE = False
        QUIT = False
        
        SetDefaults(AUTOGRID, EPlus, RUNID, WeatherFile, TGNAM, EPWFile, EPGEOM, ErrorsFound)
        ConnectIO(RUNID, WeatherFile, EPlus)
        
        if not SameString(EPlus, "FALSE"):
            WeatherServer(WeatherFile, EPWFile)
        
        GetInput2(AUTOGRID, WeatherFile, TGNAM, MAXITER, EPlus, NDIM, NX, NY, NZ, RUNID, EPGEOM, ErrorsFound)
        
        print("Entering Main Computational Block")
        
        for IYR in range(1, MAXITER + 1):
            print(f"Working on year {IYR}")
            
            if CONVERGE:
                QUIT = True
            
            IMON = 1
            for IDAY in range(1, 366):
                pass
            
            if QUIT or IYR == MAXITER:
                CloseIO()
                break


fn SetDefaults(inout AUTOGRID: String, inout EPlus: String, inout RUNID: String, inout WeatherFile: String, inout TGNAM: String, inout EPWFile: String, inout EPGEOM: String, inout ErrorsFound: Bool):
    EPlus = "TRUE"
    RUNID = "SLAB"
    EPGEOM = "FALSE"
    EPWFile = "in"
    WeatherFile = "in.epw"


fn GetInput2(inout AUTOGRID: String, inout WeatherFile: String, inout TGNAM: String, inout MaxIter: Int, inout EPlus: String, NDIM: InlineArray[Int, 12], inout NX: Int, inout NY: Int, inout NZ: Int, inout RUNID: String, inout EPGEOM: String, inout ErrorsFound: Bool):
    GetSurfProps(ErrorsFound)
    GetMatlsProps(ErrorsFound)
    GetBCs(ErrorsFound)
    GetBuildingInfo(MaxIter, ErrorsFound)
    GetInsulationInfo(ErrorsFound)
    
    var NumEquivSlab: Int = GetNumObjectsFound("EquivSlab")
    var NumEquivAutoGrid: Int = GetNumObjectsFound("EquivAutoGrid")
    var NumAutoGrid: Int = GetNumObjectsFound("AutoGrid")
    var NumEquivalentSlab: Int = GetNumObjectsFound("EquivalentSlab")
    var NumManualGrid: Int = GetNumObjectsFound("ManualGrid")
    
    var NodeSizingDone: Bool = False
    
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
        ShowFatalError("Program terminates due to preceding condition(s).")
    
    InitializeTG(WeatherFile, NDIM)


fn GetLocation(inout AUTOGRID: String, inout EPlus: String, inout RUNID: String, inout EPGEOM: String, inout ErrorsFound: Bool):
    AUTOGRID = "TRUE"
    EPlus = "TRUE"
    RUNID = "SLAB"
    EPGEOM = "FALSE"


fn GetEPlusGeom(inout EPlus: String, inout ErrorsFound: Bool):
    pass


fn GetSurfProps(inout ErrorsFound: Bool):
    pass


fn GetMatlsProps(inout ErrorsFound: Bool):
    pass


fn GetBCs(inout ErrorsFound: Bool):
    pass


fn GetBuildingInfo(inout MaxIter: Int, inout ErrorsFound: Bool):
    pass


fn GetInsulationInfo(inout ErrorsFound: Bool):
    pass


fn GetEquivalentSlabInfo(inout ErrorsFound: Bool):
    pass


fn GetAutoGridInfo(inout NX: Int, inout NY: Int, inout NZ: Int, inout ErrorsFound: Bool):
    pass


fn GetEquivSlabInfo(inout ErrorsFound: Bool):
    pass


fn GetEquivAutoGridInfo(inout NX: Int, inout NY: Int, inout NZ: Int, inout ErrorsFound: Bool):
    pass


fn GetManualGridInfo(inout NX: Int, inout NY: Int, inout NZ: Int, inout ErrorsFound: Bool):
    pass


fn GetXFACEData(NX: Int):
    pass


fn GetYFACEData(NY: Int):
    pass


fn GetZFACEData(NZ: Int):
    pass


fn GetWeatherFiles(inout WeatherFile: String, inout TGNAM: String, inout EPWFile: String, inout ErrorsFound: Bool):
    pass


fn CellGeom(NX: Int, NXM1: Int, NY: Int, NYM1: Int, NZ: Int, NZM1: Int, inout XC: OffsetArray, inout YC: OffsetArray, inout ZC: OffsetArray, inout DX: OffsetArray, inout DY: OffsetArray, inout DZ: OffsetArray, inout DXP: OffsetArray, inout DYP: OffsetArray, inout DZP: OffsetArray):
    pass


fn DefineSlab(NX: Int, NXM1: Int, NY: Int, NYM1: Int, NZM1: Int, XC: OffsetArray, YC: OffsetArray, DX: OffsetArray, DY: OffsetArray, inout AFLOR: r64, inout DA: DynamicVector[r64], inout ATOT: r64, inout PERIM: r64, inout MSURF: DynamicVector[Int], inout MTYPE: DynamicVector[Int]):
    pass


fn DefineInsulation(NX: Int, NXM1: Int, NY: Int, NYM1: Int, MSURF: DynamicVector[Int], XC: OffsetArray, YC: OffsetArray, inout INS: DynamicVector[Int]):
    pass


fn CalculateFEMCoeffs(INS: DynamicVector[Int], NX: Int, NXM1: Int, NY: Int, NYM1: Int, NZM1: Int, MTYPE: DynamicVector[Int], DXP: OffsetArray, DX: OffsetArray, DYP: OffsetArray, DY: OffsetArray, DZP: OffsetArray, DZ: OffsetArray, inout CXM: DynamicVector[r64], inout CXP: DynamicVector[r64], inout CYM: DynamicVector[r64], inout CYP: DynamicVector[r64], inout CZM: DynamicVector[r64], inout CZP: DynamicVector[r64], inout EDGEX: OffsetArray, inout EDGEY: OffsetArray):
    pass


fn CalcZenith(inout THETAZ: DynamicVector[r64], inout COSTHETAZ: DynamicVector[r64], WeatherFile: String):
    pass


fn PrelimOutput(RUNID: String, WeatherFile: String, AFLOR: r64, PERIM: r64, NX: Int, NY: Int, NZ: Int, MAXITER: Int):
    pass


fn CalcTearth(inout TG: OffsetArray, COSTHETAZ: DynamicVector[r64], NZ: Int, DZ: OffsetArray, DZP: OffsetArray, inout CVG1D: Bool, inout recalc: Bool):
    pass


fn CalcAirProps(HRAT: r64, PBAR: r64, TDB: r64, inout PVAP: r64, inout RHOA: r64, inout CPA: r64, inout DODPG: r64):
    pass


fn CalcHeatMassTransCoeffs(ZZER: r64, WND: r64, AVGWND: r64, TDB: r64, TG: r64, inout DH: r64, inout DW: r64):
    pass


fn TridiagonalMatrixSolver(inout A: DynamicVector[r64], inout B: DynamicVector[r64], inout C: DynamicVector[r64], inout X: DynamicVector[r64], inout R: DynamicVector[r64], N: Int):
    pass


fn Initialize3D(NX: Int, NY: Int, NXM1: Int, NYM1: Int, NZM1: Int, DZP: OffsetArray, inout T: DynamicVector[r64], inout TCVG: DynamicVector[r64], inout GOFT: DynamicVector[r64]):
    pass


fn SymCheck(inout NXMIN: Int, inout NYMIN: Int, inout SYM: Bool, inout SMULT: r64):
    pass


fn InitOutVars(NX: Int, NY: Int, NXM1: Int, NYM1: Int, NZM1: Int, inout TS: DynamicVector[r64], inout QS: DynamicVector[r64], inout TV: DynamicVector[r64], inout TMNA: r64, inout TMXA: r64, inout TBAR: r64, inout TMN: r64, inout TMX: r64, inout QMNA: r64, inout QMXA: r64, inout QBAR: r64, inout QMN: r64, inout QMX: r64, inout TDBA: r64, inout TDMN: r64, inout TDMX: r64):
    pass


fn GetWeather(DayNo: Int):
    pass


fn SetCurrentSurfaceProps(IHR: Int, inout RBO: r64, inout RDO: r64):
    pass


fn SetOldBeamDiffRad(IHR: Int, inout EPS: r64, inout ALB: r64):
    pass


fn CalcCurrentHeatFlux(NXMIN: Int, NXM1: Int, NYMIN: Int, NYM1: Int, MSURF: DynamicVector[Int], T: DynamicVector[r64], ALB: r64, IHR: Int, RBO: r64, COSTHETAZ: DynamicVector[r64], IDAY: Int, RDO: r64, EPS: r64, RSKY: r64, HHEAT: r64, HMASS: r64, DODPG: r64, SYM: Bool, inout GOFT: DynamicVector[r64]):
    pass


fn CalcSolutionAndUpdate(NXMIN: Int, NYMIN: Int, NX: Int, NY: Int, NZ: Int, NXM1: Int, NYM1: Int, NZM1: Int, DX: OffsetArray, DY: OffsetArray, DZ: OffsetArray, CXP: DynamicVector[r64], CYP: DynamicVector[r64], CZP: DynamicVector[r64], CXM: DynamicVector[r64], CYM: DynamicVector[r64], CZM: DynamicVector[r64], MTYPE: DynamicVector[Int], TG: OffsetArray, inout TOLD: DynamicVector[r64], inout GOFT: DynamicVector[r64], inout T: DynamicVector[r64], inout XDIF: r64, inout YDIF: r64, inout ZDIF: r64, SYM: Bool):
    pass


fn CalcOutputStats(DX: OffsetArray, DY: OffsetArray, IHR: Int, NX: Int, NY: Int, NXM1: Int, NYM1: Int, NZM1: Int, NXMIN: Int, NYMIN: Int, MSURF: DynamicVector[Int], T: DynamicVector[r64], GOFT: DynamicVector[r64], SMULT: r64, DA: DynamicVector[r64], AFLOR: r64, IDAY: Int, IMON: Int, inout TMN: r64, inout TMX: r64, inout QMN: r64, inout QMX: r64, inout TMNA: r64, inout TMXA: r64, inout QMNA: r64, inout QMXA: r64, inout TDMN: r64, inout TDMX: r64, inout TBAR: r64, inout QBAR: r64, inout TDBA: r64, inout TV: DynamicVector[r64], inout TS: DynamicVector[r64], inout QS: DynamicVector[r64], XC: OffsetArray, YC: OffsetArray, TG: OffsetArray):
    pass


fn WriteJan21Data(IHR: Int, IDAY: Int, NX: Int, NXM1: Int, NY: Int, NYM1: Int, XC: OffsetArray, YC: OffsetArray, TG: OffsetArray, T: DynamicVector[r64], DX: OffsetArray, DY: OffsetArray):
    pass


fn WriteDailyData(IDAY: Int, IMON: Int, NX: Int, NXM1: Int, NY: Int, NYM1: Int, NZM1: Int, TMN: r64, TMX: r64, TMNA: r64, TMXA: r64, TBAR: r64, TDMN: r64, TDMX: r64, TDBA: r64, QMN: r64, QMX: r64, QMNA: r64, QMXA: r64, QBAR: r64, XC: OffsetArray, YC: OffsetArray, ZC: OffsetArray, TS: DynamicVector[r64], QS: DynamicVector[r64], TV: DynamicVector[r64]):
    pass


fn ConnectIO(RUNID: String, WeatherFile: String, EPlus: String):
    pass


fn SurfTemps(DX: OffsetArray, DY: OffsetArray, DZ: OffsetArray, INS: DynamicVector[Int], MTYPE: DynamicVector[Int], IBOX: Int, JBOX: Int, T: DynamicVector[r64], inout TSurfFloor: r64, inout TSFXCL: r64, inout TSFYCL: r64, inout TSurfFloorPerim: r64, inout TSurfFloorCore: r64, inout PerimIndex: DynamicVector[Int], inout CoreArea: r64, inout PerimArea: r64, AFLOR: r64, XC: OffsetArray, YC: OffsetArray):
    pass


fn EPlusOutput(TSurfFloor: r64, TSFXCL: r64, TSFYCL: r64, TSurfFloorPerim: r64, TSurfFloorCore: r64, CoreArea: r64, PerimArea: r64, IDAY: Int, IHR: Int, TIN: r64):
    pass


fn MonthlyEPlusOutput(TSurfFloor: r64, TSFXCL: r64, TSFYCL: r64, TSurfFloorPerim: r64, TSurfFloorCore: r64, CoreArea: r64, PerimArea: r64, IDAY: Int, IHR: Int, TIN: r64, SlabThickness: r64, Slabk: r64, inout Insideh: InlineArray[r64, 2]):
    pass


fn EPlusHeader():
    pass


fn AutoGridding():
    pass


fn InitializeTG(WeatherFile: String, NDIM: InlineArray[Int, 12]):
    pass


fn CloseIO():
    pass


fn WeatherServer(WeatherFile: String, EPWFile: String):
    pass


# Stub external functions (provided by InputProcessor, DataGlobals, etc.)
fn ProcessInput(file1: String, file2: String):
    pass


fn GetNewUnitNumber() -> Int:
    return 0


fn GetNumObjectsFound(objtype: String) -> Int:
    return 0


fn GetObjectItem(objtype: String, objnum: Int, inout alphas: DynamicVector[String], inout nums: DynamicVector[r64]):
    pass


fn SameString(s1: String, s2: String) -> Bool:
    return s1 == s2


fn MakeUPPERCase(s: String) -> String:
    return s


fn ShowFatalError(msg: String):
    pass


fn ShowWarningError(msg: String):
    pass


fn ShowSevereError(msg: String):
    pass


fn ShowContinueError(msg: String):
    pass


fn RoundSigDigits(val: r64, digits: Int) -> String:
    return String(val)


fn SafeDivide(numerator: r64, denominator: r64) -> r64:
    if denominator == 0.0:
        return 0.0
    return numerator / denominator
