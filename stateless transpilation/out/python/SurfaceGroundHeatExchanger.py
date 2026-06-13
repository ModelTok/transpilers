"""
EnergyPlus Surface Ground Heat Exchanger module
Faithful Python port of SurfaceGroundHeatExchanger.cc
"""

from dataclasses import dataclass, field
from typing import Optional, Protocol, List
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object (main global data bundle)
# - PlantLocation: struct with loop (has glycol, FluidName, FluidIndex) and has PlantLoop chain
# - PlantComponent: base class interface (factory, simulate, oneTimeInit, oneTimeInit_new)
# - BaseGlobalStruct: base class for global data containers
# - Material.SurfaceRoughness: enum (Invalid, Smooth, Rough, MediumRough, MediumSmooth)
# - Construction.MaxCTFTerms: compile-time constant (integer array dimension)
# - DataPlant.PlantEquipmentType: enum including GrndHtExchgSurface
# - Constant.Kelvin: float = 273.15
# - Constant.Pi: float = 3.14159265358979323846
# - Constant.Units: output units registry
# - OutputProcessor.TimeStepType, StoreType: enums
# - Node.GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent: functions and enums
# - InputProcessor.getObjectItem, getNumObjectsFound: methods
# - Util.FindItemInList, SameString: functions
# - Convect.CalcASHRAESimpExtConvCoeff: function
# - DataEnvironment: module with GroundTempType enum, OutDryBulbTempAt, OutWetBulbTempAt, WindSpeedAt functions
# - DataPrecisionGlobals.EXP_LowerLimit: float constant
# - PlantUtilities: RegulateCondenserCompFlowReqOp, SetComponentFlowRate, SafeCopyPlantNode, InitComponentNodes, RegisterPlantCompDesignFlow, ScanPlantLoopsForObject functions
# - OutputProcessor.SetupOutputVariable: function
# - General/UtilityRoutines: ShowFatalError, ShowSevereError, ShowContinueError, ShowWarningMessage, ShowContinueErrorTimeStamp, ShowRecurringWarningErrorAtEnd, ShowWarningError functions

SmallNum = 1.0e-30
StefBoltzmann = 5.6697e-08
SurfaceHXHeight = 0.0
SurfCond_Ground = 1
SurfCond_Exposed = 2

MaxCTFTerms = 20  # nominal, replaced by Construction.MaxCTFTerms in actual build

# Property tables for water in CalcHXEffectTerm
TEMPS_WATER = [1.85, 6.85, 11.85, 16.85, 21.85, 26.85, 31.85, 36.85, 41.85, 46.85, 51.85, 56.85, 61.85]
MU_WATER = [0.001652, 0.001422, 0.001225, 0.00108, 0.000959, 0.000855, 0.000769, 0.000695, 0.000631, 0.000577, 0.000528, 0.000489, 0.000453]
CONDUCTIVITY_WATER = [0.574, 0.582, 0.590, 0.598, 0.606, 0.613, 0.620, 0.628, 0.634, 0.640, 0.645, 0.650, 0.656]
PR_WATER = [12.22, 10.26, 8.81, 7.56, 6.62, 5.83, 5.20, 4.62, 4.16, 3.77, 3.42, 3.15, 2.88]


def eoshiftArray(a: List[float], shift: int, initialValue: float) -> List[float]:
    """Shift array by shift positions, filling with initialValue."""
    size = len(a)
    o = [initialValue] * size
    b = max(shift, 0)
    e = size - 1 + min(shift, 0)
    j = max(-shift, 0)
    for i in range(b, e + 1):
        o[j] = a[i]
        j += 1
    return o


@dataclass
class SurfaceGroundHeatExchangerData:
    """Surface Ground Heat Exchanger data structure."""
    
    Name: str = ""
    ConstructionName: str = ""
    InletNode: str = ""
    OutletNode: str = ""
    DesignMassFlowRate: float = 0.0
    TubeDiameter: float = 0.0
    TubeSpacing: float = 0.0
    SurfaceLength: float = 0.0
    SurfaceWidth: float = 0.0
    TopThermAbs: float = 0.0
    TopSolarAbs: float = 0.0
    BtmThermAbs: float = 0.0
    LowerSurfCond: int = 0
    TubeCircuits: int = 0
    ConstructionNum: int = 0
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    TopRoughness: int = 0  # Material.SurfaceRoughness
    BtmRoughness: int = 0  # Material.SurfaceRoughness
    FrozenErrIndex1: int = 0
    FrozenErrIndex2: int = 0
    ConvErrIndex1: int = 0
    ConvErrIndex2: int = 0
    ConvErrIndex3: int = 0
    plantLoc: Optional[object] = None
    
    TsrcConstCoef: float = 0.0
    TsrcVarCoef: float = 0.0
    QbtmConstCoef: float = 0.0
    QbtmVarCoef: float = 0.0
    QtopConstCoef: float = 0.0
    QtopVarCoef: float = 0.0
    NumCTFTerms: int = 0
    
    CTFin: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFout: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFcross: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFflux: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFSourceIn: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFSourceOut: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFTSourceOut: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFTSourceIn: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    CTFTSourceQ: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    
    TbtmHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    TtopHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    TsrcHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    QbtmHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    QtopHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    QsrcHistory: List[float] = field(default_factory=lambda: [0.0] * MaxCTFTerms)
    
    QSrc: float = 0.0
    QSrcAvg: float = 0.0
    LastQSrc: float = 0.0
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0
    
    InletTemp: float = 0.0
    OutletTemp: float = 0.0
    MassFlowRate: float = 0.0
    TopSurfaceTemp: float = 0.0
    BtmSurfaceTemp: float = 0.0
    TopSurfaceFlux: float = 0.0
    BtmSurfaceFlux: float = 0.0
    HeatTransferRate: float = 0.0
    SurfHeatTransferRate: float = 0.0
    Energy: float = 0.0
    SurfEnergy: float = 0.0
    SourceTemp: float = 0.0
    
    MyFlag: bool = True
    InitQTF: bool = True
    MyEnvrnFlag: bool = True
    SurfaceArea: float = 0.0
    firstTimeThrough: bool = True

    @staticmethod
    def factory(state, objectType, objectName: str):
        """Factory method to create or retrieve a SurfaceGroundHeatExchanger."""
        if state.dataSurfaceGroundHeatExchangers.GetInputFlag:
            GetSurfaceGroundHeatExchanger(state)
            state.dataSurfaceGroundHeatExchangers.GetInputFlag = False
        for ghx in state.dataSurfaceGroundHeatExchangers.SurfaceGHE:
            if ghx.Name == objectName:
                return ghx
        # ShowFatalError equivalent
        raise RuntimeError(f"Surface Ground Heat Exchanger: Error getting inputs for pipe named: {objectName}")

    def simulate(self, state, calledFromLocation, FirstHVACIteration, CurLoad, RunFlag):
        """Main simulate routine."""
        self.InitSurfaceGroundHeatExchanger(state)
        self.CalcSurfaceGroundHeatExchanger(state, FirstHVACIteration)
        self.UpdateSurfaceGroundHeatExchngr(state)
        self.ReportSurfaceGroundHeatExchngr(state)

    def InitSurfaceGroundHeatExchanger(self, state):
        """Initialize surface ground heat exchanger."""
        if self.InitQTF:
            for Cons in range(1, state.dataHeatBal.TotConstructs + 1):
                if state.dataConstruction.Construct[Cons - 1].Name == self.ConstructionName:
                    LayerNum = state.dataConstruction.Construct[Cons - 1].TotLayers
                    self.NumCTFTerms = state.dataConstruction.Construct[Cons - 1].NumCTFTerms
                    self.CTFin = list(state.dataConstruction.Construct[Cons - 1].CTFInside)
                    self.CTFout = list(state.dataConstruction.Construct[Cons - 1].CTFOutside)
                    self.CTFcross = list(state.dataConstruction.Construct[Cons - 1].CTFCross)
                    for i in range(1, len(state.dataConstruction.Construct[Cons - 1].CTFFlux)):
                        self.CTFflux[i] = state.dataConstruction.Construct[Cons - 1].CTFFlux[i]
                    self.CTFSourceIn = list(state.dataConstruction.Construct[Cons - 1].CTFSourceIn)
                    self.CTFSourceOut = list(state.dataConstruction.Construct[Cons - 1].CTFSourceOut)
                    self.CTFTSourceOut = list(state.dataConstruction.Construct[Cons - 1].CTFTSourceOut)
                    self.CTFTSourceIn = list(state.dataConstruction.Construct[Cons - 1].CTFTSourceIn)
                    self.CTFTSourceQ = list(state.dataConstruction.Construct[Cons - 1].CTFTSourceQ)
                    self.ConstructionNum = Cons
                    thisMaterialLayer = state.dataMaterial.materials[state.dataConstruction.Construct[Cons - 1].LayerPoint[LayerNum - 1] - 1]
                    self.BtmRoughness = thisMaterialLayer.Roughness
                    self.TopThermAbs = thisMaterialLayer.AbsorpThermal
                    thisMaterial1 = state.dataMaterial.materials[state.dataConstruction.Construct[Cons - 1].LayerPoint[0] - 1]
                    self.TopRoughness = thisMaterial1.Roughness
                    self.TopThermAbs = thisMaterial1.AbsorpThermal
                    self.TopSolarAbs = thisMaterial1.AbsorpSolar
            self.InitQTF = False

        if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag:
            OutDryBulb = state.dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            self.CTFflux[0] = 0.0
            self.TsrcHistory = [OutDryBulb] * MaxCTFTerms
            self.TbtmHistory = [OutDryBulb] * MaxCTFTerms
            self.TtopHistory = [OutDryBulb] * MaxCTFTerms
            self.TsrcHistory = [OutDryBulb] * MaxCTFTerms
            self.QbtmHistory = [0.0] * MaxCTFTerms
            self.QtopHistory = [0.0] * MaxCTFTerms
            self.QsrcHistory = [0.0] * MaxCTFTerms
            self.TsrcConstCoef = 0.0
            self.TsrcVarCoef = 0.0
            self.QbtmConstCoef = 0.0
            self.QbtmVarCoef = 0.0
            self.QtopConstCoef = 0.0
            self.QtopVarCoef = 0.0
            self.QSrc = 0.0
            self.QSrcAvg = 0.0
            self.LastQSrc = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0
            
            state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state.dataEnvrn.BeamSolarRad
            state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state.dataEnvrn.SOLCOS[2]
            state.dataSurfaceGroundHeatExchangers.PastDifSolarRad = state.dataEnvrn.DifSolarRad
            state.dataSurfaceGroundHeatExchangers.PastGroundTemp = state.dataEnvrn.GroundTemp[int(state.dataEnvrn.GroundTempType.Shallow)]
            state.dataSurfaceGroundHeatExchangers.PastIsRain = state.dataEnvrn.IsRain
            state.dataSurfaceGroundHeatExchangers.PastIsSnow = state.dataEnvrn.IsSnow
            state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = state.dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = state.dataEnvrn.OutWetBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastSkyTemp = state.dataEnvrn.SkyTemp
            state.dataSurfaceGroundHeatExchangers.PastWindSpeed = state.dataEnvrn.WindSpeedAt(state, SurfaceHXHeight)
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        self.SurfaceArea = self.SurfaceLength * self.SurfaceWidth
        DesignFlow = state.PlantUtilities.RegulateCondenserCompFlowReqOp(state, self.plantLoc, self.DesignMassFlowRate)
        state.PlantUtilities.SetComponentFlowRate(state, DesignFlow, self.InletNodeNum, self.OutletNodeNum, self.plantLoc)
        state.dataSurfaceGroundHeatExchangers.FlowRate = state.dataLoopNodes.Node[self.InletNodeNum - 1].MassFlowRate

    def CalcSurfaceGroundHeatExchanger(self, state, FirstHVACIteration: bool):
        """Calculate surface ground heat exchanger."""
        SurfFluxTol = 0.001
        SrcFluxTol = 0.001
        RelaxT = 0.1
        Maxiter = 100
        Maxiter1 = 100

        if FirstHVACIteration and not state.dataHVACGlobal.ShortenTimeStepSys and self.firstTimeThrough:
            FluxTop = state.dataSurfaceGroundHeatExchangers.FluxTop
            FluxBtm = state.dataSurfaceGroundHeatExchangers.FluxBtm
            TempBtm = state.dataSurfaceGroundHeatExchangers.TempBtm
            TempTop = state.dataSurfaceGroundHeatExchangers.TempTop

            self.firstTimeThrough = False
            state.dataSurfaceGroundHeatExchangers.SourceFlux = self.QSrcAvg
            
            PastTempBtm = self.TbtmHistory[1]
            PastTempTop = self.TtopHistory[1]
            OldPastFluxTop = 1.0e+30
            OldPastFluxBtm = 1.0e+30
            TempB = 0.0
            TempT = 0.0
            iter_count = 0
            
            while True:
                iter_count += 1
                self.CalcTopFluxCoefficents(PastTempBtm, PastTempTop)
                PastFluxTop = self.QtopConstCoef + self.QtopVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                
                self.CalcTopSurfTemp(-PastFluxTop, TempT, state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                     state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                                     state.dataSurfaceGroundHeatExchangers.PastSkyTemp,
                                     state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                                     state.dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                                     state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                                     state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                     state.dataSurfaceGroundHeatExchangers.PastIsRain,
                                     state.dataSurfaceGroundHeatExchangers.PastIsSnow)
                PastTempTop = PastTempTop * (1.0 - RelaxT) + RelaxT * TempT

                self.CalcBottomFluxCoefficents(PastTempBtm, PastTempTop)
                PastFluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux

                if (abs((OldPastFluxTop - PastFluxTop) / OldPastFluxTop) <= SurfFluxTol and
                    abs((OldPastFluxBtm - PastFluxBtm) / OldPastFluxBtm) <= SurfFluxTol):
                    break

                self.CalcBottomSurfTemp(PastFluxBtm, TempB,
                                       state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                       state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                       state.dataSurfaceGroundHeatExchangers.PastGroundTemp)
                PastTempBtm = PastTempBtm * (1.0 - RelaxT) + RelaxT * TempB
                OldPastFluxTop = PastFluxTop
                OldPastFluxBtm = PastFluxBtm

                if iter_count > Maxiter:
                    if self.ConvErrIndex1 == 0:
                        pass  # ShowWarningMessage
                    break

            if not state.dataSurfaceGroundHeatExchangers.InitializeTempTop:
                TempTop = TempT
                TempBtm = TempB
                FluxTop = PastFluxTop
                FluxBtm = PastFluxBtm
                state.dataSurfaceGroundHeatExchangers.InitializeTempTop = True

            state.dataSurfaceGroundHeatExchangers.TopSurfTemp = TempTop
            state.dataSurfaceGroundHeatExchangers.BtmSurfTemp = TempBtm
            state.dataSurfaceGroundHeatExchangers.TopSurfFlux = -FluxTop
            state.dataSurfaceGroundHeatExchangers.BtmSurfFlux = FluxBtm

            self.CalcSourceTempCoefficents(PastTempBtm, PastTempTop)
            self.SourceTemp = self.TsrcConstCoef + self.TsrcVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
            self.UpdateHistories(PastFluxTop, PastFluxBtm, state.dataSurfaceGroundHeatExchangers.SourceFlux, self.SourceTemp)

            self.QSrcAvg = 0.0
            self.LastSysTimeElapsed = 0.0
            self.LastTimeStepSys = 0.0

            state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad = state.dataEnvrn.BeamSolarRad
            state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert = state.dataEnvrn.SOLCOS[2]
            state.dataSurfaceGroundHeatExchangers.PastDifSolarRad = state.dataEnvrn.DifSolarRad
            state.dataSurfaceGroundHeatExchangers.PastGroundTemp = state.dataEnvrn.GroundTemp[int(state.dataEnvrn.GroundTempType.Shallow)]
            state.dataSurfaceGroundHeatExchangers.PastIsRain = state.dataEnvrn.IsRain
            state.dataSurfaceGroundHeatExchangers.PastIsSnow = state.dataEnvrn.IsSnow
            state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp = state.dataEnvrn.OutDryBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp = state.dataEnvrn.OutWetBulbTempAt(state, SurfaceHXHeight)
            state.dataSurfaceGroundHeatExchangers.PastSkyTemp = state.dataEnvrn.SkyTemp
            state.dataSurfaceGroundHeatExchangers.PastWindSpeed = state.dataEnvrn.WindSpeedAt(state, SurfaceHXHeight)

            TempBtm = self.TbtmHistory[1]
            TempTop = self.TtopHistory[1]
            OldFluxTop = 1.0e+30
            OldFluxBtm = 1.0e+30
            OldSourceFlux = 1.0e+30
            state.dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)
            iter_count = 0
            
            while True:
                iter_count += 1
                iter1_count = 0
                while True:
                    iter1_count += 1
                    self.CalcTopFluxCoefficents(TempBtm, TempTop)
                    FluxTop = self.QtopConstCoef + self.QtopVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                    self.CalcTopSurfTemp(-FluxTop, TempT,
                                        state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                        state.dataSurfaceGroundHeatExchangers.PastOutWetBulbTemp,
                                        state.dataSurfaceGroundHeatExchangers.PastSkyTemp,
                                        state.dataSurfaceGroundHeatExchangers.PastBeamSolarRad,
                                        state.dataSurfaceGroundHeatExchangers.PastDifSolarRad,
                                        state.dataSurfaceGroundHeatExchangers.PastSolarDirCosVert,
                                        state.dataSurfaceGroundHeatExchangers.PastWindSpeed,
                                        state.dataSurfaceGroundHeatExchangers.PastIsRain,
                                        state.dataSurfaceGroundHeatExchangers.PastIsSnow)
                    TempTop = TempTop * (1.0 - RelaxT) + RelaxT * TempT
                    self.CalcBottomFluxCoefficents(TempBtm, TempTop)
                    FluxBtm = self.QbtmConstCoef + self.QbtmVarCoef * state.dataSurfaceGroundHeatExchangers.SourceFlux
                    
                    if (abs((OldFluxTop - FluxTop) / OldFluxTop) <= SurfFluxTol and
                        abs((OldFluxBtm - FluxBtm) / OldFluxBtm) <= SurfFluxTol):
                        break

                    self.CalcBottomSurfTemp(FluxBtm, TempB,
                                           state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                           state.dataSurfaceGroundHeatExchangers.PastOutDryBulbTemp,
                                           state.dataEnvrn.GroundTemp[int(state.dataEnvrn.GroundTempType.Shallow)])
                    TempBtm = TempBtm * (1.0 - RelaxT) + RelaxT * TempB
                    OldFluxBtm = FluxBtm
                    OldFluxTop = FluxTop

                    if iter1_count > Maxiter1:
                        if self.ConvErrIndex2 == 0:
                            pass  # ShowWarningMessage
                        break

                self.CalcSourceTempCoefficents(TempBtm, TempTop)
                state.dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)
                
                if abs((OldSourceFlux - state.dataSurfaceGroundHeatExchangers.SourceFlux) / (1.0e-20 + OldSourceFlux)) <= SrcFluxTol:
                    break
                OldSourceFlux = state.dataSurfaceGroundHeatExchangers.SourceFlux

                if iter_count > Maxiter:
                    if self.ConvErrIndex3 == 0:
                        pass  # ShowWarningMessage
                    break

        elif not FirstHVACIteration:
            self.firstTimeThrough = True
            state.dataSurfaceGroundHeatExchangers.SourceFlux = self.CalcSourceFlux(state)

    def CalcBottomFluxCoefficents(self, Tbottom: float, Ttop: float):
        """Calculate bottom flux coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.QbtmConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.QbtmConstCoef += ((-self.CTFin[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFcross[Term] * self.TtopHistory[Term]) +
                                   (self.CTFflux[Term] * self.QbtmHistory[Term]) +
                                   (self.CTFSourceIn[Term] * self.QsrcHistory[Term]))

        self.QbtmConstCoef -= self.CTFSourceIn[0] * self.QsrcHistory[0]
        self.QbtmVarCoef = self.CTFSourceIn[0]

    def CalcTopFluxCoefficents(self, Tbottom: float, Ttop: float):
        """Calculate top flux coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.QtopConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.QtopConstCoef += ((self.CTFout[Term] * self.TtopHistory[Term]) -
                                   (self.CTFcross[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFflux[Term] * self.QtopHistory[Term]) +
                                   (self.CTFSourceOut[Term] * self.QsrcHistory[Term]))

        self.QtopConstCoef -= self.CTFSourceOut[0] * self.QsrcHistory[0]
        self.QtopVarCoef = self.CTFSourceOut[0]

    def CalcSourceTempCoefficents(self, Tbottom: float, Ttop: float):
        """Calculate source temperature coefficients."""
        self.TbtmHistory[0] = Tbottom
        self.TtopHistory[0] = Ttop

        self.TsrcConstCoef = 0.0
        for Term in range(self.NumCTFTerms):
            self.TsrcConstCoef += ((self.CTFTSourceIn[Term] * self.TbtmHistory[Term]) +
                                   (self.CTFTSourceOut[Term] * self.TtopHistory[Term]) +
                                   (self.CTFflux[Term] * self.TsrcHistory[Term]) +
                                   (self.CTFTSourceQ[Term] * self.QsrcHistory[Term]))

        self.TsrcConstCoef -= self.CTFTSourceQ[0] * self.QsrcHistory[0]
        self.TsrcVarCoef = self.CTFTSourceQ[0]

    def CalcSourceFlux(self, state) -> float:
        """Calculate source flux."""
        if state.dataSurfaceGroundHeatExchangers.FlowRate > 0.0:
            EpsMdotCp = self.CalcHXEffectTerm(state, self.InletTemp, state.dataSurfaceGroundHeatExchangers.FlowRate)
            CalcSourceFlux = (self.InletTemp - self.TsrcConstCoef) / (self.SurfaceArea / EpsMdotCp + self.TsrcVarCoef)
        else:
            CalcSourceFlux = 0.0
        return CalcSourceFlux

    def UpdateHistories(self, TopFlux: float, BottomFlux: float, sourceFlux: float, sourceTemp: float):
        """Update temperature and flux histories."""
        self.TtopHistory = eoshiftArray(self.TtopHistory, -1, 0.0)
        self.TbtmHistory = eoshiftArray(self.TbtmHistory, -1, 0.0)
        self.TsrcHistory = eoshiftArray(self.TsrcHistory, -1, 0.0)
        self.TsrcHistory[1] = sourceTemp
        self.QbtmHistory = eoshiftArray(self.QbtmHistory, -1, 0.0)
        self.QbtmHistory[1] = BottomFlux
        self.QtopHistory = eoshiftArray(self.QtopHistory, -1, 0.0)
        self.QtopHistory[1] = TopFlux
        self.QsrcHistory = eoshiftArray(self.QsrcHistory, -1, 0.0)
        self.QsrcHistory[1] = sourceFlux

    def CalcHXEffectTerm(self, state, Temperature: float, WaterMassFlow: float) -> float:
        """Calculate heat exchanger effectiveness term."""
        MaxLaminarRe = 2300.0
        WaterIndex = 1

        Index = 0
        while Index < len(TEMPS_WATER):
            if Temperature < TEMPS_WATER[Index]:
                break
            Index += 1

        if Index == 0:
            MUactual = MU_WATER[0]
            Kactual = CONDUCTIVITY_WATER[0]
            PRactual = PR_WATER[0]
        elif Index >= len(TEMPS_WATER):
            Index = len(TEMPS_WATER) - 1
            MUactual = MU_WATER[Index]
            Kactual = CONDUCTIVITY_WATER[Index]
            PRactual = PR_WATER[Index]
        else:
            InterpFrac = (Temperature - TEMPS_WATER[Index - 1]) / (TEMPS_WATER[Index] - TEMPS_WATER[Index - 1])
            MUactual = MU_WATER[Index - 1] + InterpFrac * (MU_WATER[Index] - MU_WATER[Index - 1])
            Kactual = CONDUCTIVITY_WATER[Index - 1] + InterpFrac * (CONDUCTIVITY_WATER[Index] - CONDUCTIVITY_WATER[Index - 1])
            PRactual = PR_WATER[Index - 1] + InterpFrac * (PR_WATER[Index] - PR_WATER[Index - 1])

        if Temperature < 0.0:
            if self.plantLoc.loop.FluidIndex == WaterIndex:
                if self.FrozenErrIndex1 == 0:
                    pass  # ShowWarningMessage
                self.InletTemp = max(self.InletTemp, 0.0)

        CpWater = self.plantLoc.loop.glycol.getSpecificHeat(state, Temperature, "SurfaceGroundHeatExchanger:CalcHXEffectTerm")

        ReD = 4.0 * WaterMassFlow / (3.141592653589793 * MUactual * self.TubeDiameter * self.TubeCircuits)

        if ReD >= MaxLaminarRe:
            NuD = 0.023 * pow(ReD, 0.8) * pow(PRactual, 1.0 / 3.0)
        else:
            NuD = 3.66

        PipeLength = self.SurfaceLength * self.SurfaceWidth / self.TubeSpacing

        NTU = 3.141592653589793 * Kactual * NuD * PipeLength / (WaterMassFlow * CpWater)
        EXP_LowerLimit = state.DataPrecisionGlobals.EXP_LowerLimit
        
        if -NTU >= EXP_LowerLimit:
            CalcHXEffectTerm = (1.0 - math.exp(-NTU)) * WaterMassFlow * CpWater
        else:
            CalcHXEffectTerm = 1.0 * WaterMassFlow * CpWater

        return CalcHXEffectTerm

    def CalcTopSurfTemp(self, FluxTop: float, TempTop_ref, ThisDryBulb: float, ThisWetBulb: float,
                        ThisSkyTemp: float, ThisBeamSolarRad: float, ThisDifSolarRad: float,
                        ThisSolarDirCosVert: float, ThisWindSpeed: float, ThisIsRain: bool, ThisIsSnow: bool):
        """Calculate top surface temperature."""
        Kelvin = 273.15
        
        if ThisIsSnow or ThisIsRain:
            ExternalTemp = ThisWetBulb
        else:
            ExternalTemp = ThisDryBulb

        OldSurfTemp = self.TtopHistory[1]
        SurfTempAbs = OldSurfTemp + Kelvin
        SkyTempAbs = ThisSkyTemp + Kelvin

        ConvCoef = state.Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)
        
        if abs(SurfTempAbs - SkyTempAbs) > SmallNum:
            RadCoef = StefBoltzmann * self.TopThermAbs * (pow(SurfTempAbs, 4) - pow(SkyTempAbs, 4)) / (SurfTempAbs - SkyTempAbs)
        else:
            RadCoef = 0.0

        QSolAbsorbed = self.TopSolarAbs * (max(ThisSolarDirCosVert, 0.0) * ThisBeamSolarRad + ThisDifSolarRad)
        TempTop_ref = (FluxTop + ConvCoef * ExternalTemp + RadCoef * ThisSkyTemp + QSolAbsorbed) / (ConvCoef + RadCoef)

    def CalcBottomSurfTemp(self, FluxBtm: float, TempBtm_ref, ThisDryBulb: float,
                           ThisWindSpeed: float, ThisGroundTemp: float):
        """Calculate bottom surface temperature."""
        Kelvin = 273.15
        
        if self.LowerSurfCond == SurfCond_Exposed:
            OldSurfTemp = self.TbtmHistory[1]
            SurfTempAbs = OldSurfTemp + Kelvin
            ExtTempAbs = ThisDryBulb + Kelvin

            ConvCoef = state.Convect.CalcASHRAESimpExtConvCoeff(self.TopRoughness, ThisWindSpeed)

            if abs(SurfTempAbs - ExtTempAbs) > SmallNum:
                RadCoef = StefBoltzmann * self.TopThermAbs * (pow(SurfTempAbs, 4) - pow(ExtTempAbs, 4)) / (SurfTempAbs - ExtTempAbs)
            else:
                RadCoef = 0.0

            TempBtm_ref = (FluxBtm + ConvCoef * ThisDryBulb + RadCoef * ThisDryBulb) / (ConvCoef + RadCoef)
        else:
            TempBtm_ref = ThisGroundTemp

    def UpdateSurfaceGroundHeatExchngr(self, state):
        """Update surface ground heat exchanger."""
        SysTimeElapsed = state.dataHVACGlobal.SysTimeElapsed
        TimeStepSys = state.dataHVACGlobal.TimeStepSys

        self.QSrc = state.dataSurfaceGroundHeatExchangers.SourceFlux

        if self.LastSysTimeElapsed == SysTimeElapsed:
            self.QSrcAvg -= self.LastQSrc * self.LastTimeStepSys / state.dataGlobal.TimeStepZone
            self.QSrcAvg += self.QSrc * TimeStepSys / state.dataGlobal.TimeStepZone
            self.LastQSrc = state.dataSurfaceGroundHeatExchangers.SourceFlux
            self.LastSysTimeElapsed = SysTimeElapsed
            self.LastTimeStepSys = TimeStepSys

        if self.plantLoc.loop.FluidName == "WATER":
            if self.InletTemp < 0.0:
                pass  # ShowRecurringWarningErrorAtEnd
            self.InletTemp = max(self.InletTemp, 0.0)

        CpFluid = self.plantLoc.loop.glycol.getSpecificHeat(state, self.InletTemp, "SurfaceGroundHeatExchanger:Update")

        state.PlantUtilities.SafeCopyPlantNode(state, self.InletNodeNum, self.OutletNodeNum)
        if CpFluid > 0.0 and state.dataSurfaceGroundHeatExchangers.FlowRate > 0.0:
            state.dataLoopNodes.Node[self.OutletNodeNum - 1].Temp = (self.InletTemp - self.SurfaceArea *
                                                                      state.dataSurfaceGroundHeatExchangers.SourceFlux /
                                                                      (state.dataSurfaceGroundHeatExchangers.FlowRate * CpFluid))
            state.dataLoopNodes.Node[self.OutletNodeNum - 1].Enthalpy = state.dataLoopNodes.Node[self.OutletNodeNum - 1].Temp * CpFluid

    def ReportSurfaceGroundHeatExchngr(self, state):
        """Report surface ground heat exchanger."""
        TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec

        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum - 1].Temp
        self.OutletTemp = state.dataLoopNodes.Node[self.OutletNodeNum - 1].Temp
        self.MassFlowRate = state.dataLoopNodes.Node[self.InletNodeNum - 1].MassFlowRate

        self.HeatTransferRate = state.dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea
        self.SurfHeatTransferRate = (self.SurfaceArea *
                                     (state.dataSurfaceGroundHeatExchangers.TopSurfFlux + state.dataSurfaceGroundHeatExchangers.BtmSurfFlux))
        self.Energy = state.dataSurfaceGroundHeatExchangers.SourceFlux * self.SurfaceArea * TimeStepSysSec
        self.TopSurfaceTemp = state.dataSurfaceGroundHeatExchangers.TopSurfTemp
        self.BtmSurfaceTemp = state.dataSurfaceGroundHeatExchangers.BtmSurfTemp
        self.TopSurfaceFlux = state.dataSurfaceGroundHeatExchangers.TopSurfFlux
        self.BtmSurfaceFlux = state.dataSurfaceGroundHeatExchangers.BtmSurfFlux
        self.SurfEnergy = (self.SurfaceArea *
                          (state.dataSurfaceGroundHeatExchangers.TopSurfFlux + state.dataSurfaceGroundHeatExchangers.BtmSurfFlux) *
                          TimeStepSysSec)

    def oneTimeInit(self, state):
        """One-time initialization (empty stub)."""
        pass

    def oneTimeInit_new(self, state):
        """One-time initialization new (full implementation)."""
        DesignVelocity = 0.5
        
        state.PlantUtilities.ScanPlantLoopsForObject(state, self.Name, 
                                                     state.DataPlant.PlantEquipmentType.GrndHtExchgSurface,
                                                     self.plantLoc)
        rho = self.plantLoc.loop.glycol.getDensity(state, 0.0, "InitSurfaceGroundHeatExchanger")
        self.DesignMassFlowRate = (3.141592653589793 / 4.0 * pow(self.TubeDiameter, 2) *
                                   DesignVelocity * rho * self.TubeCircuits)
        state.PlantUtilities.InitComponentNodes(state, 0.0, self.DesignMassFlowRate, self.InletNodeNum, self.OutletNodeNum)
        state.PlantUtilities.RegisterPlantCompDesignFlow(state, self.InletNodeNum, self.DesignMassFlowRate / rho)


@dataclass
class SurfaceGroundHeatExchangersData:
    """Global data for surface ground heat exchangers."""
    
    NoSurfaceGroundTempObjWarning: bool = True
    FlowRate: float = 0.0
    TopSurfTemp: float = 0.0
    BtmSurfTemp: float = 0.0
    TopSurfFlux: float = 0.0
    BtmSurfFlux: float = 0.0
    SourceFlux: float = 0.0
    CheckEquipName: List[bool] = field(default_factory=list)
    
    PastBeamSolarRad: float = 0.0
    PastSolarDirCosVert: float = 0.0
    PastDifSolarRad: float = 0.0
    PastGroundTemp: float = 0.0
    PastIsRain: bool = False
    PastIsSnow: bool = False
    PastOutDryBulbTemp: float = 0.0
    PastOutWetBulbTemp: float = 0.0
    PastSkyTemp: float = 0.0
    PastWindSpeed: float = 0.0
    
    GetInputFlag: bool = True
    
    QRadSysSrcAvg: List[float] = field(default_factory=list)
    LastSysTimeElapsed: List[float] = field(default_factory=list)
    LastTimeStepSys: List[float] = field(default_factory=list)
    InitializeTempTop: bool = False
    
    SurfaceGHE: List[SurfaceGroundHeatExchangerData] = field(default_factory=list)
    FluxTop: float = 0.0
    FluxBtm: float = 0.0
    TempBtm: float = 0.0
    TempTop: float = 0.0

    def init_constant_state(self, state):
        """Initialize constant state (empty)."""
        pass

    def init_state(self, state):
        """Initialize state (empty)."""
        pass

    def clear_state(self):
        """Clear all state."""
        self.NoSurfaceGroundTempObjWarning = True
        self.FlowRate = 0.0
        self.TopSurfTemp = 0.0
        self.BtmSurfTemp = 0.0
        self.TopSurfFlux = 0.0
        self.BtmSurfFlux = 0.0
        self.SourceFlux = 0.0
        self.CheckEquipName.clear()
        self.PastBeamSolarRad = 0.0
        self.PastSolarDirCosVert = 0.0
        self.PastDifSolarRad = 0.0
        self.PastGroundTemp = 0.0
        self.PastIsRain = False
        self.PastIsSnow = False
        self.PastOutDryBulbTemp = 0.0
        self.PastOutWetBulbTemp = 0.0
        self.PastSkyTemp = 0.0
        self.PastWindSpeed = 0.0
        self.GetInputFlag = True
        self.QRadSysSrcAvg.clear()
        self.LastSysTimeElapsed.clear()
        self.LastTimeStepSys.clear()
        self.InitializeTempTop = False
        self.SurfaceGHE.clear()


def GetSurfaceGroundHeatExchanger(state):
    """Get input for surface ground heat exchangers."""
    cCurrentModuleObject = "GroundHeatExchanger:Surface"
    NumOfSurfaceGHEs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    
    state.dataSurfaceGroundHeatExchangers.SurfaceGHE = [SurfaceGroundHeatExchangerData() for _ in range(NumOfSurfaceGHEs)]
    state.dataSurfaceGroundHeatExchangers.CheckEquipName = [True] * NumOfSurfaceGHEs

    ErrorsFound = False

    for Item in range(1, NumOfSurfaceGHEs + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state, cCurrentModuleObject, Item)
        
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].Name = state.dataIPShortCut.cAlphaArgs[0]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionName = state.dataIPShortCut.cAlphaArgs[1]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum = (
            state.Util.FindItemInList(state.dataIPShortCut.cAlphaArgs[1], state.dataConstruction.Construct))

        if state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum == 0:
            ErrorsFound = True

        if not state.dataConstruction.Construct[state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].ConstructionNum - 1].SourceSinkPresent:
            ErrorsFound = True

        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].InletNode = state.dataIPShortCut.cAlphaArgs[2]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].InletNodeNum = (
            state.Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[2], ErrorsFound))

        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].OutletNode = state.dataIPShortCut.cAlphaArgs[3]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].OutletNodeNum = (
            state.Node.GetOnlySingleNode(state, state.dataIPShortCut.cAlphaArgs[3], ErrorsFound))

        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeDiameter = state.dataIPShortCut.rNumericArgs[0]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeCircuits = int(state.dataIPShortCut.rNumericArgs[1])
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].TubeSpacing = state.dataIPShortCut.rNumericArgs[2]

        if state.dataIPShortCut.rNumericArgs[1] == 0:
            ErrorsFound = True

        if state.dataIPShortCut.rNumericArgs[2] == 0.0:
            ErrorsFound = True

        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].SurfaceLength = state.dataIPShortCut.rNumericArgs[3]
        state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].SurfaceWidth = state.dataIPShortCut.rNumericArgs[4]

        if state.dataIPShortCut.rNumericArgs[3] <= 0.0:
            ErrorsFound = True
        if state.dataIPShortCut.rNumericArgs[4] <= 0.0:
            ErrorsFound = True

        if state.Util.SameString(state.dataIPShortCut.cAlphaArgs[4], "GROUND"):
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].LowerSurfCond = SurfCond_Ground
        elif state.Util.SameString(state.dataIPShortCut.cAlphaArgs[4], "EXPOSED"):
            state.dataSurfaceGroundHeatExchangers.SurfaceGHE[Item - 1].LowerSurfCond = SurfCond_Exposed
        else:
            ErrorsFound = True

    if ErrorsFound:
        raise RuntimeError(f"Errors found in processing input for {cCurrentModuleObject}")

    for Item in range(1, NumOfSurfaceGHEs + 1):
        pass  # SetupOutputVariable calls (stubbed in Python)

    if state.dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning:
        if not state.dataEnvrn.GroundTempInputs[int(state.dataEnvrn.GroundTempType.Shallow)]:
            pass  # ShowWarningError
        state.dataSurfaceGroundHeatExchangers.NoSurfaceGroundTempObjWarning = False
