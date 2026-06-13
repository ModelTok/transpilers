# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state.dataGlobal (TimeStepZone, TimeStepZoneSec), state.dataMaterial, state.dataConstruction,
#   state.dataHeatBal (MaxSolidWinLayers), state.dataOutRptPredefined, state.files
# - Material: Group, SurfaceRoughness, surfaceRoughnessNames, MaxSlatAngs, BlindDfTAR, BlindDfTARGS, MaterialBase
# - DataConversions: CFU, CFL, CFK, CFD, CFC
# - DataHeatBalance: HighDiffusivityThreshold, ThinMaterialLayerThreshold
# - Window: maxPolyCoef
# - DataWindowEquivalentLayer: CFSMAXNL, Orientation
# - DataBSDFWindow: BSDFWindowInputStruct
# - Sched: Schedule
# - Constant: rTinyValue
# - ShowSevereError, ShowContinueError, ShowFatalError, ShowWarningError, DisplayString, print, PreDefTableEntry

from math import sqrt, log, pow as fpow, floor, ceil


alias MaxCTFTerms = 19
alias MaxLayersInConstruct = 11
alias MaxSlatAngs = 19
alias MaxPolyCoef = 6
alias CFSMAXNL = 2000


struct Array1D:
    """1-based single dimension array wrapper."""
    var data: List[Float64]
    
    fn __init__(inout self, size: Int, fill_value: Float64 = 0.0):
        self.data = List[Float64](capacity=size + 1)
        for _ in range(size + 1):
            self.data.append(fill_value)
    
    fn __getitem__(self, i: Int) -> Float64:
        return self.data[i]
    
    fn __setitem__(inout self, i: Int, val: Float64):
        self.data[i] = val
    
    fn fill(inout self, val: Float64):
        for i in range(len(self.data)):
            self.data[i] = val
    
    fn allocate(inout self, size: Int):
        self.data = List[Float64](capacity=size + 1)
        for _ in range(size + 1):
            self.data.append(0.0)
    
    fn deallocate(inout self):
        self.data = List[Float64]()
    
    fn len(self) -> Int:
        return len(self.data)


struct Array2D:
    """1-based 2D array wrapper."""
    var rows: Int
    var cols: Int
    var data: List[List[Float64]]
    
    fn __init__(inout self, rows: Int, cols: Int, fill_value: Float64 = 0.0):
        self.rows = rows
        self.cols = cols
        self.data = List[List[Float64]](capacity=rows + 1)
        for _ in range(rows + 1):
            var row = List[Float64](capacity=cols + 1)
            for _ in range(cols + 1):
                row.append(fill_value)
            self.data.append(row)
    
    fn __getitem__(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]
    
    fn __setitem__(inout self, i: Int, j: Int, val: Float64):
        self.data[i][j] = val
    
    fn fill(inout self, val: Float64):
        for i in range(1, self.rows + 1):
            for j in range(1, self.cols + 1):
                self.data[i][j] = val
    
    fn allocate(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[List[Float64]](capacity=rows + 1)
        for _ in range(rows + 1):
            var row = List[Float64](capacity=cols + 1)
            for _ in range(cols + 1):
                row.append(0.0)
            self.data.append(row)
    
    fn deallocate(inout self):
        self.data = List[List[Float64]]()


struct Array3D:
    """1-based 3D array wrapper."""
    var d1: Int
    var d2: Int
    var d3: Int
    var data: List[List[List[Float64]]]
    
    fn __init__(inout self, d1: Int, d2: Int, d3: Int, fill_value: Float64 = 0.0):
        self.d1 = d1
        self.d2 = d2
        self.d3 = d3
        self.data = List[List[List[Float64]]](capacity=d1 + 1)
        for _ in range(d1 + 1):
            var mat = List[List[Float64]](capacity=d2 + 1)
            for _ in range(d2 + 1):
                var row = List[Float64](capacity=d3 + 1)
                for _ in range(d3 + 1):
                    row.append(fill_value)
                mat.append(row)
            self.data.append(mat)
    
    fn __getitem__(self, i: Int, j: Int, k: Int) -> Float64:
        return self.data[i][j][k]
    
    fn __setitem__(inout self, i: Int, j: Int, k: Int, val: Float64):
        self.data[i][j][k] = val
    
    fn fill(inout self, val: Float64):
        for i in range(1, self.d1 + 1):
            for j in range(1, self.d2 + 1):
                for k in range(1, self.d3 + 1):
                    self.data[i][j][k] = val
    
    fn allocate(inout self, d1: Int, d2: Int, d3: Int):
        self.d1 = d1
        self.d2 = d2
        self.d3 = d3
        self.data = List[List[List[Float64]]](capacity=d1 + 1)
        for _ in range(d1 + 1):
            var mat = List[List[Float64]](capacity=d2 + 1)
            for _ in range(d2 + 1):
                var row = List[Float64](capacity=d3 + 1)
                for _ in range(d3 + 1):
                    row.append(0.0)
                mat.append(row)
            self.data.append(mat)
    
    fn deallocate(inout self):
        self.data = List[List[List[Float64]]]()


struct BlindDfAbs:
    """Blind diffuse absorptance."""
    var Abs: Float64
    var AbsGnd: Float64
    var AbsSky: Float64
    
    fn __init__(inout self):
        self.Abs = 0.0
        self.AbsGnd = 0.0
        self.AbsSky = 0.0


struct BlindSolVis:
    """Blind solar-visible transmittance."""
    var Sol_Ft_Df: Pointer[Float64]
    var Sol_Bk_Df: Pointer[Float64]
    var Vis_Ft_Df: Pointer[Float64]
    var Vis_Bk_Df: Pointer[Float64]
    
    fn __init__(inout self):
        self.Sol_Ft_Df = Pointer[Float64]()
        self.Sol_Bk_Df = Pointer[Float64]()
        self.Vis_Ft_Df = Pointer[Float64]()
        self.Vis_Bk_Df = Pointer[Float64]()


struct BlindSolDfAbs:
    """Blind solar diffuse absorptance."""
    var Sol_Ft_Df: BlindDfAbs
    var Sol_Bk_Df: BlindDfAbs
    
    fn __init__(inout self):
        self.Sol_Ft_Df = BlindDfAbs()
        self.Sol_Bk_Df = BlindDfAbs()


struct TCLayer:
    """Thermochromic layer."""
    var constrNum: Int
    var specTemp: Float64
    
    fn __init__(inout self):
        self.constrNum = 0
        self.specTemp = 0.0


struct ConstructionProps:
    """Main Construction properties struct."""
    var Name: String
    var TotLayers: Int
    var TotSolidLayers: Int
    var TotGlassLayers: Int
    var LayerPoint: Array1D
    var IsUsed: Bool
    var IsUsedCTF: Bool
    var IsCondFD: Bool
    var InsideAbsorpVis: Float64
    var OutsideAbsorpVis: Float64
    var InsideAbsorpSolar: Float64
    var OutsideAbsorpSolar: Float64
    var InsideAbsorpThermal: Float64
    var OutsideAbsorpThermal: Float64
    var OutsideRoughness: Int
    var DayltPropPtr: Int
    var W5FrameDivider: Int
    var CTFCross: InlineArray[Float64, MaxCTFTerms]
    var CTFFlux: InlineArray[Float64, MaxCTFTerms]
    var CTFInside: InlineArray[Float64, MaxCTFTerms]
    var CTFOutside: InlineArray[Float64, MaxCTFTerms]
    var CTFSourceIn: InlineArray[Float64, MaxCTFTerms]
    var CTFSourceOut: InlineArray[Float64, MaxCTFTerms]
    var CTFTimeStep: Float64
    var CTFTSourceOut: InlineArray[Float64, MaxCTFTerms]
    var CTFTSourceIn: InlineArray[Float64, MaxCTFTerms]
    var CTFTSourceQ: InlineArray[Float64, MaxCTFTerms]
    var CTFTUserOut: InlineArray[Float64, MaxCTFTerms]
    var CTFTUserIn: InlineArray[Float64, MaxCTFTerms]
    var CTFTUserSource: InlineArray[Float64, MaxCTFTerms]
    var NumHistories: Int
    var NumCTFTerms: Int
    var UValue: Float64
    var SolutionDimensions: Int
    var SourceAfterLayer: Int
    var TempAfterLayer: Int
    var ThicknessPerpend: Float64
    var userTemperatureLocationPerpendicular: Float64
    var AbsDiffIn: Float64
    var AbsDiffOut: Float64
    var AbsDiff: Array1D
    var AbsDiffBack: Array1D
    var effShadeBlindEmi: InlineArray[Float64, MaxSlatAngs]
    var effGlassEmi: InlineArray[Float64, MaxSlatAngs]
    var blindTARs: List[BlindSolVis]
    var layerSlatBlindDfAbs: List[BlindSolDfAbs]
    var AbsDiffShade: Float64
    var AbsDiffBackShade: Float64
    var ShadeAbsorpThermal: Float64
    var AbsBeamCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var AbsBeamBackCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var AbsBeamShadeCoef: InlineArray[Float64, MaxPolyCoef]
    var TransDiff: Float64
    var TransDiffVis: Float64
    var ReflectSolDiffBack: Float64
    var ReflectSolDiffFront: Float64
    var ReflectVisDiffBack: Float64
    var ReflectVisDiffFront: Float64
    var TransSolBeamCoef: InlineArray[Float64, MaxPolyCoef]
    var TransVisBeamCoef: InlineArray[Float64, MaxPolyCoef]
    var ReflSolBeamFrontCoef: InlineArray[Float64, MaxPolyCoef]
    var ReflSolBeamBackCoef: InlineArray[Float64, MaxPolyCoef]
    var tBareSolCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var tBareVisCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var rfBareSolCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var rfBareVisCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var rbBareSolCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var rbBareVisCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var afBareSolCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var abBareSolCoef: List[InlineArray[Float64, MaxPolyCoef]]
    var tBareSolDiff: Array1D
    var tBareVisDiff: Array1D
    var rfBareSolDiff: Array1D
    var rfBareVisDiff: Array1D
    var rbBareSolDiff: Array1D
    var rbBareVisDiff: Array1D
    var afBareSolDiff: Array1D
    var abBareSolDiff: Array1D
    var FromWindow5DataFile: Bool
    var W5FileMullionWidth: Float64
    var W5FileMullionOrientation: Int
    var W5FileGlazingSysWidth: Float64
    var W5FileGlazingSysHeight: Float64
    var SummerSHGC: Float64
    var VisTransNorm: Float64
    var SolTransNorm: Float64
    var SourceSinkPresent: Bool
    var TypeIsWindow: Bool
    var WindowTypeBSDF: Bool
    var TypeIsEcoRoof: Bool
    var TypeIsIRT: Bool
    var TypeIsCfactorWall: Bool
    var TypeIsFfactorFloor: Bool
    var isTCWindow: Bool
    var isTCMaster: Bool
    var TCMasterConstrNum: Int
    var TCMasterMatNum: Int
    var TCLayerNum: Int
    var TCGlassNum: Int
    var numTCChildConstrs: Int
    var TCChildConstrs: List[TCLayer]
    var specTemp: Float64
    var CFactor: Float64
    var Height: Float64
    var FFactor: Float64
    var Area: Float64
    var PerimeterExposed: Float64
    var ReverseConstructionNumLayersWarning: Bool
    var ReverseConstructionLayersOrderWarning: Bool
    var BSDFInput: Pointer[UInt8]
    var WindowTypeEQL: Bool
    var EQLConsPtr: Int
    var AbsDiffFrontEQL: Array1D
    var AbsDiffBackEQL: Array1D
    var TransDiffFrontEQL: Float64
    var TransDiffBackEQL: Float64
    var TypeIsAirBoundary: Bool
    var TypeIsAirBoundaryMixing: Bool
    var AirBoundaryACH: Float64
    var airBoundaryMixingSched: Pointer[UInt8]
    var rcmax: Int
    var AExp: Array2D
    var AInv: Array2D
    var AMat: Array2D
    var BMat: Array1D
    var CMat: Array1D
    var DMat: Array1D
    var e: Array1D
    var Gamma1: Array2D
    var Gamma2: Array2D
    var s: Array3D
    var s0: Array2D
    var IdenMatrix: Array2D
    var NumOfPerpendNodes: Int
    var NodeSource: Int
    var NodeUserTemp: Int
    
    fn __init__(inout self):
        self.Name = String()
        self.TotLayers = 0
        self.TotSolidLayers = 0
        self.TotGlassLayers = 0
        self.LayerPoint = Array1D(MaxLayersInConstruct, 0.0)
        self.IsUsed = False
        self.IsUsedCTF = False
        self.IsCondFD = False
        self.InsideAbsorpVis = 0.0
        self.OutsideAbsorpVis = 0.0
        self.InsideAbsorpSolar = 0.0
        self.OutsideAbsorpSolar = 0.0
        self.InsideAbsorpThermal = 0.0
        self.OutsideAbsorpThermal = 0.0
        self.OutsideRoughness = 0
        self.DayltPropPtr = 0
        self.W5FrameDivider = 0
        self.CTFCross = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFFlux = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFInside = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFOutside = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFSourceIn = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFSourceOut = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTimeStep = 0.0
        self.CTFTSourceOut = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTSourceIn = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTSourceQ = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTUserOut = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTUserIn = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.CTFTUserSource = InlineArray[Float64, MaxCTFTerms](fill=0.0)
        self.NumHistories = 0
        self.NumCTFTerms = 0
        self.UValue = 0.0
        self.SolutionDimensions = 0
        self.SourceAfterLayer = 0
        self.TempAfterLayer = 0
        self.ThicknessPerpend = 0.0
        self.userTemperatureLocationPerpendicular = 0.0
        self.AbsDiffIn = 0.0
        self.AbsDiffOut = 0.0
        self.AbsDiff = Array1D(100, 0.0)
        self.AbsDiffBack = Array1D(100, 0.0)
        self.effShadeBlindEmi = InlineArray[Float64, MaxSlatAngs](fill=0.0)
        self.effGlassEmi = InlineArray[Float64, MaxSlatAngs](fill=0.0)
        self.blindTARs = List[BlindSolVis]()
        self.layerSlatBlindDfAbs = List[BlindSolDfAbs]()
        self.AbsDiffShade = 0.0
        self.AbsDiffBackShade = 0.0
        self.ShadeAbsorpThermal = 0.0
        self.AbsBeamCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.AbsBeamBackCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.AbsBeamShadeCoef = InlineArray[Float64, MaxPolyCoef](fill=0.0)
        self.TransDiff = 0.0
        self.TransDiffVis = 0.0
        self.ReflectSolDiffBack = 0.0
        self.ReflectSolDiffFront = 0.0
        self.ReflectVisDiffBack = 0.0
        self.ReflectVisDiffFront = 0.0
        self.TransSolBeamCoef = InlineArray[Float64, MaxPolyCoef](fill=0.0)
        self.TransVisBeamCoef = InlineArray[Float64, MaxPolyCoef](fill=0.0)
        self.ReflSolBeamFrontCoef = InlineArray[Float64, MaxPolyCoef](fill=0.0)
        self.ReflSolBeamBackCoef = InlineArray[Float64, MaxPolyCoef](fill=0.0)
        self.tBareSolCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.tBareVisCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.rfBareSolCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.rfBareVisCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.rbBareSolCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.rbBareVisCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.afBareSolCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.abBareSolCoef = List[InlineArray[Float64, MaxPolyCoef]]()
        self.tBareSolDiff = Array1D(5, 0.0)
        self.tBareVisDiff = Array1D(5, 0.0)
        self.rfBareSolDiff = Array1D(5, 0.0)
        self.rfBareVisDiff = Array1D(5, 0.0)
        self.rbBareSolDiff = Array1D(5, 0.0)
        self.rbBareVisDiff = Array1D(5, 0.0)
        self.afBareSolDiff = Array1D(5, 0.0)
        self.abBareSolDiff = Array1D(5, 0.0)
        self.FromWindow5DataFile = False
        self.W5FileMullionWidth = 0.0
        self.W5FileMullionOrientation = 0
        self.W5FileGlazingSysWidth = 0.0
        self.W5FileGlazingSysHeight = 0.0
        self.SummerSHGC = 0.0
        self.VisTransNorm = 0.0
        self.SolTransNorm = 0.0
        self.SourceSinkPresent = False
        self.TypeIsWindow = False
        self.WindowTypeBSDF = False
        self.TypeIsEcoRoof = False
        self.TypeIsIRT = False
        self.TypeIsCfactorWall = False
        self.TypeIsFfactorFloor = False
        self.isTCWindow = False
        self.isTCMaster = False
        self.TCMasterConstrNum = 0
        self.TCMasterMatNum = 0
        self.TCLayerNum = 0
        self.TCGlassNum = 0
        self.numTCChildConstrs = 0
        self.TCChildConstrs = List[TCLayer]()
        self.specTemp = 0.0
        self.CFactor = 0.0
        self.Height = 0.0
        self.FFactor = 0.0
        self.Area = 0.0
        self.PerimeterExposed = 0.0
        self.ReverseConstructionNumLayersWarning = False
        self.ReverseConstructionLayersOrderWarning = False
        self.BSDFInput = Pointer[UInt8]()
        self.WindowTypeEQL = False
        self.EQLConsPtr = 0
        self.AbsDiffFrontEQL = Array1D(CFSMAXNL, 0.0)
        self.AbsDiffBackEQL = Array1D(CFSMAXNL, 0.0)
        self.TransDiffFrontEQL = 0.0
        self.TransDiffBackEQL = 0.0
        self.TypeIsAirBoundary = False
        self.TypeIsAirBoundaryMixing = False
        self.AirBoundaryACH = 0.0
        self.airBoundaryMixingSched = Pointer[UInt8]()
        self.rcmax = 0
        self.AExp = Array2D(100, 100, 0.0)
        self.AInv = Array2D(100, 100, 0.0)
        self.AMat = Array2D(100, 100, 0.0)
        self.BMat = Array1D(3, 0.0)
        self.CMat = Array1D(2, 0.0)
        self.DMat = Array1D(2, 0.0)
        self.e = Array1D(100, 0.0)
        self.Gamma1 = Array2D(3, 100, 0.0)
        self.Gamma2 = Array2D(3, 100, 0.0)
        self.s = Array3D(3, 4, 100, 0.0)
        self.s0 = Array2D(3, 4, 0.0)
        self.IdenMatrix = Array2D(100, 100, 0.0)
        self.NumOfPerpendNodes = 7
        self.NodeSource = 0
        self.NodeUserTemp = 0
    
    fn calculateTransferFunction(inout self, state: UInt8, ErrorsFound: Pointer[Bool], DoCTFErrorReport: Pointer[Bool]):
        pass
    
    fn calculateExponentialMatrix(inout self):
        pass
    
    fn calculateInverseMatrix(inout self):
        pass
    
    fn calculateGammas(inout self):
        pass
    
    fn calculateFinalCoefficients(inout self):
        pass
    
    fn reportTransferFunction(inout self, state: UInt8, cCounter: Int):
        pass
    
    fn reportLayers(inout self, state: UInt8):
        pass
    
    fn isGlazingConstruction(self, state: UInt8) -> Bool:
        return False
    
    fn setThicknessPerpendicular(inout self, state: UInt8, userValue: Float64) -> Float64:
        var returnValue: Float64 = userValue / 2.0
        if returnValue <= 0.001:
            returnValue = 0.075
        elif returnValue > 0.5:
            pass
        return returnValue
    
    fn setUserTemperatureLocationPerpendicular(inout self, state: UInt8, userValue: Float64) -> Float64:
        if userValue < 0.0:
            return 0.0
        if userValue > 1.0:
            return 1.0
        return userValue
    
    fn setNodeSourceAndUserTemp(inout self, Nodes: Array1D):
        self.NodeSource = 0
        self.NodeUserTemp = 0
        if not self.SourceSinkPresent:
            return
        
        for Layer in range(1, self.SourceAfterLayer + 1):
            self.NodeSource += Int(Nodes[Layer])
        
        if (self.NodeSource > 0) and (self.SolutionDimensions > 1):
            self.NodeSource = (self.NodeSource - 1) * self.NumOfPerpendNodes + 1
        
        for Layer in range(1, self.TempAfterLayer + 1):
            self.NodeUserTemp += Int(Nodes[Layer])
        
        if (self.NodeUserTemp > 0) and (self.SolutionDimensions > 1):
            var node_offset = Int(self.userTemperatureLocationPerpendicular * Float64(self.NumOfPerpendNodes - 1))
            self.NodeUserTemp = (self.NodeUserTemp - 1) * self.NumOfPerpendNodes + node_offset + 1
    
    fn setArraysBasedOnMaxSolidWinLayers(inout self, state: UInt8):
        pass


struct ConstructionData:
    """Construction module data."""
    var Construct: List[ConstructionProps]
    var LayerPoint: Array1D
    
    fn __init__(inout self):
        self.Construct = List[ConstructionProps]()
        self.LayerPoint = Array1D(MaxLayersInConstruct, 0.0)
    
    fn init_constant_state(inout self, state: UInt8):
        pass
    
    fn init_state(inout self, state: UInt8):
        pass
    
    fn clear_state(inout self):
        self.__init__()
