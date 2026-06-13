module EnergyPlus.DaylightingDevices:
from .DataDaylightingDevices import *
from .DataDaylighting import *
from DataHeatBalance import *
from .DataIPShortCuts import *
from DataSurfaces import *
from DataSystemVariables import *
from DaylightingManager import *
from DisplayRoutines import *
from FluidProperties import *
from General import *
from HeatBalanceInternalHeatGains import *
from .InputProcessing import InputProcessor
from OutputProcessor import *
from SolarShading import *
from UtilityRoutines import *
from Construction import *
from .Data import *
from  import Constant
from  import Window
from math import cos, sin, tan, sqrt, log, abs, atan, pow
from memory import DynamicVector
struct BaseGlobalStruct:

struct DaylightingDevicesData(BaseGlobalStruct):
    var COSAngle: DynamicVector[Float64] = DynamicVector[Float64](NumOfAngles, 0.0) // List of cosines of incident angle
    var ShelfReported: Bool = False
    var GetTDDInputErrorsFound: Bool = False   // Set to true if errors in input, fatal at end of routine
    var GetShelfInputErrorsFound: Bool = False // Set to true if errors in input, fatal at end of routine
    var MyEnvrnFlag: Bool = True
    def init_constant_state(inout self, state: EnergyPlusData) raises:

    def init_state(inout self, state: EnergyPlusData) raises:

    def clear_state(inout self) raises:
        self.COSAngle = DynamicVector[Float64](NumOfAngles, 0.0)
        self.ShelfReported = False
        self.GetTDDInputErrorsFound = False
        self.GetShelfInputErrorsFound = False
        self.MyEnvrnFlag = True
struct Dayltg:
    using DataSurfaces.ExternalEnvironment
    using DataSurfaces.SurfaceClass
    def InitDaylightingDevices(state: EnergyPlusData) raises:
        struct TDDPipeStoredData:
            var AspectRatio: Float64
            var Reflectance: Float64
            var TransBeam: DynamicVector[Float64]
            def __init__(inout self):
                self.AspectRatio = 0.0
                self.Reflectance = 0.0
                self.TransBeam = DynamicVector[Float64](NumOfAngles, 0.0)
        var TDDPipeStored: DynamicVector[TDDPipeStoredData]
        GetTDDInput(state)
        if state.dataDaylightingDevicesData.TDDPipe.size > 0:
            DisplayString(state, "Initializing Tubular Daylighting Devices")
            state.dataDaylightingDevices.COSAngle[0] = 0.0
            state.dataDaylightingDevices.COSAngle[NumOfAngles - 1] = 1.0
            var dTheta: Float64 = 90.0 * Constant.DegToRad / (NumOfAngles - 1.0)
            var Theta: Float64 = 90.0 * Constant.DegToRad
            for var AngleNum = 2
                AngleNum <= NumOfAngles - 1
                AngleNum += 1:
                Theta -= dTheta
                state.dataDaylightingDevices.COSAngle[AngleNum - 1] = cos(Theta)
            TDDPipeStored = DynamicVector[TDDPipeStoredData](state.dataDaylightingDevicesData.TDDPipe.size * 2)
            for var PipeNum = 1
                PipeNum <= state.dataDaylightingDevicesData.TDDPipe.size
                PipeNum += 1:
                var idx = PipeNum - 1
                state.dataDaylightingDevicesData.TDDPipe[idx].AspectRatio =
                    state.dataDaylightingDevicesData.TDDPipe[idx].TotLength / state.dataDaylightingDevicesData.TDDPipe[idx].Diameter
                state.dataDaylightingDevicesData.TDDPipe[idx].ReflectVis =
                    1.0 - state.dataConstruction.Construct(state.dataDaylightingDevicesData.TDDPipe[idx].Construction).InsideAbsorpVis
                state.dataDaylightingDevicesData.TDDPipe[idx].ReflectSol =
                    1.0 - state.dataConstruction.Construct(state.dataDaylightingDevicesData.TDDPipe[idx].Construction).InsideAbsorpSolar
                var Reflectance: Float64 = state.dataDaylightingDevicesData.TDDPipe[idx].ReflectVis
                var NumStored: Int = 0
                var StoredNum: Int = 0
                for var Loop = 1
                    Loop <= 2
                    Loop += 1:
                    var Found: Bool = False
                    for StoredNum = 1
                        StoredNum <= NumStored
                        StoredNum += 1:
                        if TDDPipeStored[StoredNum - 1].AspectRatio != state.dataDaylightingDevicesData.TDDPipe[idx].AspectRatio:
                            continue
                        if TDDPipeStored[StoredNum - 1].Reflectance == Reflectance:
                            Found = True
                            break
                    if not Found:
                        NumStored += 1
                        TDDPipeStored[NumStored - 1].AspectRatio = state.dataDaylightingDevicesData.TDDPipe[idx].AspectRatio
                        TDDPipeStored[NumStored - 1].Reflectance = Reflectance
                        TDDPipeStored[NumStored - 1].TransBeam[0] = 0.0
                        TDDPipeStored[NumStored - 1].TransBeam[NumOfAngles - 1] = 1.0
                        Theta = 90.0 * Constant.DegToRad
                        for var AngleNum = 2
                            AngleNum <= NumOfAngles - 1
                            AngleNum += 1:
                            Theta -= dTheta
                            TDDPipeStored[NumStored - 1].TransBeam[AngleNum - 1] =
                                CalcPipeTransBeam(Reflectance, state.dataDaylightingDevicesData.TDDPipe[idx].AspectRatio, Theta)
                        StoredNum = NumStored
                    if Loop == 1:
                        state.dataDaylightingDevicesData.TDDPipe[idx].PipeTransVisBeam = TDDPipeStored[StoredNum - 1].TransBeam
                    else:
                        state.dataDaylightingDevicesData.TDDPipe[idx].PipeTransSolBeam = TDDPipeStored[StoredNum - 1].TransBeam
                    Reflectance = state.dataDaylightingDevicesData.TDDPipe[idx].ReflectSol
                state.dataDaylightingDevicesData.TDDPipe[idx].TransSolIso = CalcTDDTransSolIso(state, PipeNum)
                state.dataDaylightingDevicesData.TDDPipe[idx].TransSolHorizon = CalcTDDTransSolHorizon(state, PipeNum)
                var SumTZoneLengths: Float64 = 0.0
                for var TZoneNum = 1
                    TZoneNum <= state.dataDaylightingDevicesData.TDDPipe[idx].NumOfTZones
                    TZoneNum += 1:
                    SumTZoneLengths += state.dataDaylightingDevicesData.TDDPipe[idx].TZoneLength[TZoneNum - 1]
                    SetupZoneInternalGain(state,
                                          state.dataDaylightingDevicesData.TDDPipe[idx].TZone[TZoneNum - 1],
                                          state.dataDaylightingDevicesData.TDDPipe[idx].Name,
                                          DataHeatBalance.IntGainType.DaylightingDeviceTubular,
                                          &state.dataDaylightingDevicesData.TDDPipe[idx].TZoneHeatGain[TZoneNum - 1])
                state.dataDaylightingDevicesData.TDDPipe[idx].ExtLength =
                    state.dataDaylightingDevicesData.TDDPipe[idx].TotLength - SumTZoneLengths
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Transmitted Solar Radiation Rate",
                                    Constant.Units.W,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].TransmittedSolar,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Pipe Absorbed Solar Radiation Rate",
                                    Constant.Units.W,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].PipeAbsorbedSolar,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Heat Gain Rate",
                                    Constant.Units.W,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].HeatGain,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Heat Loss Rate",
                                    Constant.Units.W,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].HeatLoss,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Beam Solar Transmittance",
                                    Constant.Units.None,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].TransSolBeam,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Beam Visible Transmittance",
                                    Constant.Units.None,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].TransVisBeam,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Diffuse Solar Transmittance",
                                    Constant.Units.None,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].TransSolDiff,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
                SetupOutputVariable(state,
                                    "Tubular Daylighting Device Diffuse Visible Transmittance",
                                    Constant.Units.None,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].TransVisDiff,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    state.dataDaylightingDevicesData.TDDPipe[idx].Name)
        GetShelfInput(state)
        if state.dataDaylightingDevicesData.Shelf.size > 0:
            DisplayString(state, "Initializing Light Shelf Daylighting Devices")
        for var ShelfNum = 1
            ShelfNum <= state.dataDaylightingDevicesData.Shelf.size
            ShelfNum += 1:
            var sIdx = ShelfNum - 1
            var WinSurf: Int = state.dataDaylightingDevicesData.Shelf[sIdx].Window
            var ShelfSurf: Int = state.dataDaylightingDevicesData.Shelf[sIdx].InSurf
            if ShelfSurf > 0:
                state.dataSurface.Surface[ShelfSurf - 1].Area *= 2.0
                state.dataGlobal.AnyInsideShelf = True
            ShelfSurf = state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf
            if ShelfSurf > 0:
                state.dataDaylightingDevicesData.Shelf[sIdx].OutReflectVis =
                    1.0 - state.dataConstruction.Construct(state.dataDaylightingDevicesData.Shelf[sIdx].Construction).OutsideAbsorpVis
                state.dataDaylightingDevicesData.Shelf[sIdx].OutReflectSol =
                    1.0 - state.dataConstruction.Construct(state.dataDaylightingDevicesData.Shelf[sIdx].Construction).OutsideAbsorpSolar
                if state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor < 0:
                    CalcViewFactorToShelf(state, ShelfNum)
                adjustViewFactorsWithShelf(state,
                                           state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor,
                                           state.dataSurface.Surface[WinSurf - 1].ViewFactorSky,
                                           state.dataSurface.Surface[WinSurf - 1].ViewFactorGround,
                                           WinSurf,
                                           ShelfNum)
                if not state.dataDaylightingDevices.ShelfReported:
                    print(state.files.eio,
                          "! <Shelf Details>,Name,View Factor to Outside Shelf,Window Name,Window View Factor to Sky,Window View Factor to Ground\n")
                    state.dataDaylightingDevices.ShelfReported = True
                print(state.files.eio,
                      "Shelf Details,{},{:.2f},{},{:.2f},{:.2f}\n".format(
                          state.dataDaylightingDevicesData.Shelf[sIdx].Name,
                          state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor,
                          state.dataSurface.Surface[WinSurf - 1].Name,
                          state.dataSurface.Surface[WinSurf - 1].ViewFactorSky,
                          state.dataSurface.Surface[WinSurf - 1].ViewFactorGround))
        if state.dataSurface.CalcSolRefl and \
           (state.dataDaylightingDevicesData.TDDPipe.size > 0 or state.dataDaylightingDevicesData.Shelf.size > 0):
            ShowWarningError(state, "InitDaylightingDevices: Solar Distribution Model includes Solar Reflection calculations;")
            ShowContinueError(state, "the resulting reflected solar values will not be used in the")
            ShowContinueError(state, "DaylightingDevice:Shelf or DaylightingDevice:Tubular calculations.")
    def GetTDDInput(state: EnergyPlusData) raises:
        var ipsc = state.dataIPShortCut
        var cCurrentModuleObject = ipsc.cCurrentModuleObject
        cCurrentModuleObject = "DaylightingDevice:Tubular"
        var NumOfTDDPipes: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        if NumOfTDDPipes > 0:
            state.dataDaylightingDevicesData.TDDPipe = DynamicVector[TDDPipeData](NumOfTDDPipes)
            var IOStatus: Int
            var NumAlphas: Int
            var NumNumbers: Int
            for var PipeNum = 1
                PipeNum <= NumOfTDDPipes
                PipeNum += 1:
                var pIdx = PipeNum - 1
                state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                       cCurrentModuleObject,
                                                                       PipeNum,
                                                                       ipsc.cAlphaArgs,
                                                                       NumAlphas,
                                                                       ipsc.rNumericArgs,
                                                                       NumNumbers,
                                                                       IOStatus,
                                                                       ipsc.lNumericFieldBlanks,
                                                                       ipsc.lAlphaFieldBlanks,
                                                                       ipsc.cAlphaFieldNames,
                                                                       ipsc.cNumericFieldNames)
                state.dataDaylightingDevicesData.TDDPipe[pIdx].Name = ipsc.cAlphaArgs[0]
                var SurfNum: Int = Util.FindItemInList(ipsc.cAlphaArgs[1], state.dataSurface.Surface)
                if SurfNum == 0:
                    ShowSevereError(state,
                                    format("{} = {}:  Dome {} not found.", cCurrentModuleObject, ipsc.cAlphaArgs[0], ipsc.cAlphaArgs[1]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                else:
                    if FindTDDPipe(state, SurfNum) > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} is referenced by more than one TDD.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].Class != SurfaceClass.TDD_Dome:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} is not of surface type TubularDaylightDome.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).TotGlassLayers > 1:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} construction ({}) must have only 1 glass layer.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1],
                                                state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).Name))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].HasShadeControl:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} must not have a shading control.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].FrameDivider > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} must not have a frame/divider.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).WindowTypeEQL:
                        ShowSevereError(state,
                                        format("{} = {}:  Dome {} Equivalent Layer Window is not supported.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if not state.dataSurface.Surface[SurfNum - 1].ExtSolar:
                        ShowWarningError(state,
                                         format("{} = {}:  Dome {} is not exposed to exterior radiation.",
                                                 cCurrentModuleObject,
                                                 ipsc.cAlphaArgs[0],
                                                 ipsc.cAlphaArgs[1]))
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome = SurfNum
                    state.dataSurface.SurfWinTDDPipeNum[SurfNum - 1] = PipeNum
                SurfNum = Util.FindItemInList(ipsc.cAlphaArgs[2], state.dataSurface.Surface)
                if SurfNum == 0:
                    ShowSevereError(state,
                                    format("{} = {}:  Diffuser {} not found.", cCurrentModuleObject, ipsc.cAlphaArgs[0], ipsc.cAlphaArgs[2]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                else:
                    if FindTDDPipe(state, SurfNum) > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} is referenced by more than one TDD.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].OriginalClass != SurfaceClass.TDD_Diffuser:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} is not of surface type TubularDaylightDiffuser.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).TotGlassLayers > 1:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} construction ({}) must have only 1 glass layer.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2],
                                                state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).Name))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).TransDiff <= 1.0e-10:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} construction ({}) invalid value.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2],
                                                state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).Name))
                        ShowContinueError(state,
                                          format("Diffuse solar transmittance of construction [{:.4f}] too small for calculations.",
                                                  state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).TransDiff))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome > 0 and \
                       abs(state.dataSurface.Surface[SurfNum - 1].Area -
                           state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area) > 0.1:
                        if General.SafeDivide(abs(state.dataSurface.Surface[SurfNum - 1].Area -
                                                  state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area),
                                              state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area) > 0.1:
                            ShowSevereError(state,
                                            format("{} = {}:  Dome and diffuser areas are significantly different (>10%).",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0]))
                            ShowContinueError(state,
                                              format("...Diffuser Area=[{:.4f}]; Dome Area=[{:.4f}].",
                                                      state.dataSurface.Surface[SurfNum - 1].Area,
                                                      state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area))
                            state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                        else:
                            ShowWarningError(state,
                                            format("{} = {}:  Dome and diffuser areas differ by > .1 m2.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0]))
                            ShowContinueError(state,
                                              format("...Diffuser Area=[{:.4f}]; Dome Area=[{:.4f}].",
                                                      state.dataSurface.Surface[SurfNum - 1].Area,
                                                      state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area))
                    if state.dataSurface.Surface[SurfNum - 1].HasShadeControl:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} must not have a shading control.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].FrameDivider > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} must not have a frame/divider.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).WindowTypeEQL:
                        ShowSevereError(state,
                                        format("{} = {}:  Diffuser {} Equivalent Layer Window is not supported.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].Diffuser = SurfNum
                    state.dataSurface.SurfWinTDDPipeNum[SurfNum - 1] = PipeNum
                state.dataDaylightingDevicesData.TDDPipe[pIdx].Construction =
                    Util.FindItemInList(ipsc.cAlphaArgs[3], state.dataConstruction.Construct)
                if state.dataDaylightingDevicesData.TDDPipe[pIdx].Construction == 0:
                    ShowSevereError(state,
                                    format("{} = {}:  Pipe construction {} not found.", cCurrentModuleObject, ipsc.cAlphaArgs[0], ipsc.cAlphaArgs[3]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                else:
                    state.dataConstruction.Construct(state.dataDaylightingDevicesData.TDDPipe[pIdx].Construction).IsUsed = True
                if ipsc.rNumericArgs[0] > 0:
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].Diameter = ipsc.rNumericArgs[0]
                else:
                    ShowSevereError(state,
                                    format("{} = {}:  Pipe diameter must be greater than zero.", cCurrentModuleObject, ipsc.cAlphaArgs[0]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                var PipeArea: Float64 = 0.25 * Constant.Pi * state.dataDaylightingDevicesData.TDDPipe[pIdx].Diameter * state.dataDaylightingDevicesData.TDDPipe[pIdx].Diameter
                if state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome > 0 and \
                   abs(PipeArea - state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area) > 0.1:
                    if General.SafeDivide(abs(PipeArea - state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area),
                                          state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area) > 0.1:
                        ShowSevereError(state,
                                        format("{} = {}:  Pipe and dome/diffuser areas are significantly different (>10%).",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0]))
                        ShowContinueError(state,
                                          format("...Pipe Area=[{:.4f}]; Dome/Diffuser Area=[{:.4f}].",
                                                  PipeArea,
                                                  state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area))
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    else:
                        ShowWarningError(state,
                                        format("{} = {}:  Pipe and dome/diffuser areas differ by > .1 m2.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0]))
                        ShowContinueError(state,
                                          format("...Pipe Area=[{:.4f}]; Dome/Diffuser Area=[{:.4f}].",
                                                  PipeArea,
                                                  state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1].Area))
                if ipsc.rNumericArgs[1] > 0:
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].TotLength = ipsc.rNumericArgs[1]
                else:
                    ShowSevereError(state,
                                    format("{} = {}:  Pipe length must be greater than zero.", cCurrentModuleObject, ipsc.cAlphaArgs[0]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                if ipsc.rNumericArgs[2] > 0:
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].Reff = ipsc.rNumericArgs[2]
                else:
                    ShowSevereError(state,
                                    format("{} = {}:  Effective thermal resistance (R value) must be greater than zero.",
                                            cCurrentModuleObject,
                                            ipsc.cAlphaArgs[0]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones = NumAlphas - 4
                if state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones < 1:
                    ShowWarningError(state,
                                     format("{} = {}:  No transition zones specified.  All pipe absorbed solar goes to exterior.",
                                             cCurrentModuleObject,
                                             ipsc.cAlphaArgs[0]))
                elif state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones > MaxTZones:
                    ShowSevereError(state,
                                    format("{} = {}:  Maximum number of transition zones exceeded.", cCurrentModuleObject, ipsc.cAlphaArgs[0]))
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                else:
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].TZone = DynamicVector[Int](state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones)
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneLength = DynamicVector[Float64](state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones, 0.0)
                    state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneHeatGain = DynamicVector[Float64](state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones, 0.0)
                    for var i in range(state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones):
                        state.dataDaylightingDevicesData.TDDPipe[pIdx].TZone[i] = 0
                        state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneLength[i] = 0.0
                        state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneHeatGain[i] = 0.0
                    for var TZoneNum = 1
                        TZoneNum <= state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones
                        TZoneNum += 1:
                        var tIdx = TZoneNum - 1
                        var TZoneName: String = ipsc.cAlphaArgs[TZoneNum + 3] // cAlphaArgs 0-indexed: index 4 -> 4-1=3? Actually cAlphaArgs in C++ index from 1, we store 0-indexed. The TZoneNum+4 in C++ means index (TZoneNum+4-1) = TZoneNum+3 in zero-based.
                        state.dataDaylightingDevicesData.TDDPipe[pIdx].TZone[tIdx] = Util.FindItemInList(TZoneName, state.dataHeatBal.Zone)
                        if state.dataDaylightingDevicesData.TDDPipe[pIdx].TZone[tIdx] == 0:
                            ShowSevereError(state,
                                            format("{} = {}:  Transition zone {} not found.", cCurrentModuleObject, ipsc.cAlphaArgs[0], TZoneName))
                            state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                        state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneLength[tIdx] = ipsc.rNumericArgs[tIdx + 3] // zero-based index of numericArgs: TZoneNum+3 -> (tIdx)
                        if state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneLength[tIdx] < 0:
                            ShowSevereError(state,
                                            format("{} = {}:  Transition zone length for {} must be zero or greater.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    TZoneName))
                            state.dataDaylightingDevices.GetTDDInputErrorsFound = True
            if state.dataDaylightingDevices.GetTDDInputErrorsFound:
                ShowFatalError(state, "Errors in DaylightingDevice:Tubular input.")
            state.dataDayltg.TDDTransVisBeam = DynamicVector[DynamicVector[Float64]](Constant.iHoursInDay, DynamicVector[Float64](NumOfTDDPipes, 0.0))
            state.dataDayltg.TDDFluxInc = DynamicVector[DynamicVector[Illums]](Constant.iHoursInDay, DynamicVector[Illums](NumOfTDDPipes))
            state.dataDayltg.TDDFluxTrans = DynamicVector[DynamicVector[Illums]](Constant.iHoursInDay, DynamicVector[Illums](NumOfTDDPipes))
            for var hr = 1
                hr <= Constant.iHoursInDay
                hr += 1:
                var hIdx = hr - 1
                for var tddNum = 1
                    tddNum <= NumOfTDDPipes
                    tddNum += 1:
                    var tddIdx = tddNum - 1
                    state.dataDayltg.TDDTransVisBeam[hIdx][tddIdx] = 0.0
                    state.dataDayltg.TDDFluxInc[hIdx][tddIdx] = Illums()
                    state.dataDayltg.TDDFluxTrans[hIdx][tddIdx] = Illums()
    def GetShelfInput(state: EnergyPlusData) raises:
        var ipsc = state.dataIPShortCut
        var cCurrentModuleObject = ipsc.cCurrentModuleObject
        cCurrentModuleObject = "DaylightingDevice:Shelf"
        var NumOfShelf: Int = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        if NumOfShelf > 0:
            state.dataDaylightingDevicesData.Shelf = DynamicVector[ShelfData](NumOfShelf)
            var NumAlphas: Int
            var NumNumbers: Int
            var IOStatus: Int
            for var ShelfNum = 1
                ShelfNum <= NumOfShelf
                ShelfNum += 1:
                var sIdx = ShelfNum - 1
                state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                       cCurrentModuleObject,
                                                                       ShelfNum,
                                                                       ipsc.cAlphaArgs,
                                                                       NumAlphas,
                                                                       ipsc.rNumericArgs,
                                                                       NumNumbers,
                                                                       IOStatus,
                                                                       ipsc.lNumericFieldBlanks,
                                                                       ipsc.lAlphaFieldBlanks,
                                                                       ipsc.cAlphaFieldNames,
                                                                       ipsc.cNumericFieldNames)
                state.dataDaylightingDevicesData.Shelf[sIdx].Name = ipsc.cAlphaArgs[0]
                var SurfNum: Int = Util.FindItemInList(ipsc.cAlphaArgs[1], state.dataSurface.Surface)
                if SurfNum == 0:
                    ShowSevereError(state,
                                    format("{} = {}:  Window {} not found.", cCurrentModuleObject, ipsc.cAlphaArgs[0], ipsc.cAlphaArgs[1]))
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                else:
                    if state.dataSurface.Surface[SurfNum - 1].Class != SurfaceClass.Window:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} is not of surface type WINDOW.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    if state.dataSurface.SurfDaylightingShelfInd[SurfNum - 1] > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} is referenced by more than one shelf.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].HasShadeControl:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} must not have a shading control.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].FrameDivider > 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} must not have a frame/divider.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    if state.dataSurface.Surface[SurfNum - 1].Sides != 4:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} must have 4 sides.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    if state.dataConstruction.Construct(state.dataSurface.Surface[SurfNum - 1].Construction).WindowTypeEQL:
                        ShowSevereError(state,
                                        format("{} = {}:  Window {} Equivalent Layer Window is not supported.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[1]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    state.dataDaylightingDevicesData.Shelf[sIdx].Window = SurfNum
                    state.dataSurface.SurfDaylightingShelfInd[SurfNum - 1] = ShelfNum
                if not ipsc.cAlphaArgs[2].empty():
                    SurfNum = Util.FindItemInList(ipsc.cAlphaArgs[2], state.dataSurface.Surface)
                    if SurfNum == 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Inside shelf {} not found.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[2]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    else:
                        if state.dataSurface.Surface[SurfNum - 1].ExtBoundCond != SurfNum:
                            ShowSevereError(state,
                                            format("{} = {}:  Inside shelf {} must be its own Outside Boundary Condition Object.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    ipsc.cAlphaArgs[2]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        if state.dataSurface.Surface[SurfNum - 1].Sides != 4:
                            ShowSevereError(state,
                                            format("{} = {}:  Inside shelf {} must have 4 sides.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    ipsc.cAlphaArgs[2]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        state.dataDaylightingDevicesData.Shelf[sIdx].InSurf = SurfNum
                if not ipsc.cAlphaArgs[3].empty():
                    SurfNum = Util.FindItemInList(ipsc.cAlphaArgs[3], state.dataSurface.Surface)
                    if SurfNum == 0:
                        ShowSevereError(state,
                                        format("{} = {}:  Outside shelf {} not found.",
                                                cCurrentModuleObject,
                                                ipsc.cAlphaArgs[0],
                                                ipsc.cAlphaArgs[3]))
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                    else:
                        if state.dataSurface.Surface[SurfNum - 1].Class != SurfaceClass.Shading:
                            ShowSevereError(state,
                                            format("{} = {}:  Outside shelf {} is not a Shading:Zone:Detailed object.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    ipsc.cAlphaArgs[3]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        if state.dataSurface.Surface[SurfNum - 1].shadowSurfSched != None:
                            ShowSevereError(state,
                                            format("{} = {}:  Outside shelf {} must not have a transmittance schedule.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    ipsc.cAlphaArgs[3]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        if state.dataSurface.Surface[SurfNum - 1].Sides != 4:
                            ShowSevereError(state,
                                            format("{} = {}:  Outside shelf {} must have 4 sides.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0],
                                                    ipsc.cAlphaArgs[3]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        var ConstrNum: Int = 0
                        if not ipsc.cAlphaArgs[4].empty():
                            ConstrNum = Util.FindItemInList(ipsc.cAlphaArgs[4], state.dataConstruction.Construct)
                            if ConstrNum == 0:
                                ShowSevereError(state,
                                                format("{} = {}:  Outside shelf construction {} not found.",
                                                        cCurrentModuleObject,
                                                        ipsc.cAlphaArgs[0],
                                                        ipsc.cAlphaArgs[4]))
                                state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                            elif state.dataConstruction.Construct[ConstrNum - 1].TypeIsWindow:
                                ShowSevereError(state,
                                                format("{} = {}:  Outside shelf construction {} must not have WindowMaterial:Glazing.",
                                                        cCurrentModuleObject,
                                                        ipsc.cAlphaArgs[0],
                                                        ipsc.cAlphaArgs[4]))
                                state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                            else:
                                state.dataDaylightingDevicesData.Shelf[sIdx].Construction = ConstrNum
                                state.dataConstruction.Construct[ConstrNum - 1].IsUsed = True
                        else:
                            ShowSevereError(state,
                                            format("{} = {}:  Outside shelf requires an outside shelf construction to be specified.",
                                                    cCurrentModuleObject,
                                                    ipsc.cAlphaArgs[0]))
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        if NumNumbers > 0:
                            state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor = ipsc.rNumericArgs[0]
                            if ipsc.rNumericArgs[0] == 0.0:
                                ShowWarningError(state,
                                                 format("{} = {}:  View factor to outside shelf is zero.  Shelf does not reflect on window.",
                                                         cCurrentModuleObject,
                                                         ipsc.cAlphaArgs[0]))
                        else:
                            state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor = -1.0
                        state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf = SurfNum
                        state.dataSurface.Surface[SurfNum - 1].BaseSurf = SurfNum
                        state.dataSurface.Surface[SurfNum - 1].HeatTransSurf = True
                        state.dataSurface.AllHTSurfaceList.append(SurfNum)
                        state.dataSurface.Surface[SurfNum - 1].Construction = ConstrNum
                        state.dataSurface.SurfActiveConstruction[SurfNum - 1] = ConstrNum
                        state.dataConstruction.Construct[ConstrNum - 1].IsUsed = True
                if state.dataDaylightingDevicesData.Shelf[sIdx].InSurf == 0 and state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf == 0:
                    ShowWarningError(state,
                                     format("{} = {}:  No inside shelf or outside shelf was specified.",
                                             cCurrentModuleObject,
                                             ipsc.cAlphaArgs[0]))
            if state.dataDaylightingDevices.GetShelfInputErrorsFound:
                ShowFatalError(state, "Errors in DaylightingDevice:Shelf input.")
    def CalcPipeTransBeam(R: Float64, A: Float64, Theta: Float64) raises -> Float64:
        var CalcPipeTransBeam: Float64
        var N: Float64 = 100000.0 // number of intervals for integration
        var xTol: Float64 = 150.0 // tolerance for power series truncation
        var myLocalTiny: Float64 = Tiny(1.0)
        var i: Float64
        var s: Float64
        var dT: Float64
        var T: Float64
        var x: Float64
        var c1: Float64
        var c2: Float64
        var xLimit: Float64
        CalcPipeTransBeam = 0.0
        T = 0.0
        i = 1.0 / N
        xLimit = (log(N * N * myLocalTiny) / log(R)) / xTol
        c1 = A * tan(Theta)
        c2 = 4.0 / Constant.Pi
        s = i
        while s < (1.0 - i):
            x = c1 / s
            if x < xLimit:
                dT = c2 * pow(R, x) * (1.0 - (1.0 - R) * (x - int(x))) * s * s / sqrt(1.0 - s * s)
                T += dT
            s += i
        T /= (N - 1.0)
        CalcPipeTransBeam = T
        return CalcPipeTransBeam
    def CalcTDDTransSolIso(state: EnergyPlusData, PipeNum: Int) raises -> Float64:
        var CalcTDDTransSolIso: Float64
        var NPH: Int = 1000
        var FluxInc: Float64 = 0.0
        var FluxTrans: Float64 = 0.0
        var trans: Float64
        var COSI: Float64
        var SINI: Float64
        var dPH: Float64 = 90.0 * Constant.DegToRad / NPH
        var PH: Float64 = 0.5 * dPH
        for var N = 1
            N <= NPH
            N += 1:
            COSI = cos(Constant.PiOvr2 - PH)
            SINI = sin(Constant.PiOvr2 - PH)
            var P: Float64 = COSI
            trans = TransTDD(state, PipeNum, COSI, RadType.SolarBeam)
            FluxInc += P * SINI * dPH
            FluxTrans += trans * P * SINI * dPH
            PH += dPH
        CalcTDDTransSolIso = FluxTrans / FluxInc
        return CalcTDDTransSolIso
    def CalcTDDTransSolHorizon(state: EnergyPlusData, PipeNum: Int) raises -> Float64:
        var CalcTDDTransSolHorizon: Float64
        var NTH: Int = 18
        var FluxInc: Float64 = 0.0
        var FluxTrans: Float64 = 0.0
        var CosPhi: Float64
        var Theta: Float64
        var idx = PipeNum - 1
        CosPhi = cos(Constant.PiOvr2 -
                      state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[idx].Dome - 1].Tilt * Constant.DegToRad)
        Theta = state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[idx].Dome - 1].Azimuth * Constant.DegToRad
        if CosPhi > 0.01:
            var THMIN: Float64 = Theta - Constant.PiOvr2
            var dTH: Float64 = 180.0 * Constant.DegToRad / NTH
            var TH: Float64 = THMIN + 0.5 * dTH
            for var N = 1
                N <= NTH
                N += 1:
                var COSI: Float64 = CosPhi * cos(TH - Theta)
                var trans: Float64 = TransTDD(state, PipeNum, COSI, RadType.SolarBeam)
                FluxInc += COSI * dTH
                FluxTrans += trans * COSI * dTH
                TH += dTH
            CalcTDDTransSolHorizon = FluxTrans / FluxInc
        else:
            CalcTDDTransSolHorizon = 0.0
        return CalcTDDTransSolHorizon
    def CalcTDDTransSolAniso(state: EnergyPlusData, PipeNum: Int, COSI: Float64) raises -> Float64:
        var CalcTDDTransSolAniso: Float64
        var DomeSurf: Int
        var IsoSkyRad: Float64
        var CircumSolarRad: Float64
        var HorizonRad: Float64
        var AnisoSkyTDDMult: Float64
        var idx = PipeNum - 1
        DomeSurf = state.dataDaylightingDevicesData.TDDPipe[idx].Dome
        if not state.dataSysVars.DetailedSkyDiffuseAlgorithm or not state.dataSurface.ShadingTransmittanceVaries or \
           state.dataHeatBal.SolarDistribution == DataHeatBalance.Shadowing.Minimal:
            IsoSkyRad = state.dataSolarShading.SurfMultIsoSky[DomeSurf - 1] * state.dataSolarShading.SurfDifShdgRatioIsoSky[DomeSurf - 1]
            HorizonRad = state.dataSolarShading.SurfMultHorizonZenith[DomeSurf - 1] * state.dataSolarShading.SurfDifShdgRatioHoriz[DomeSurf - 1]
        else:
            IsoSkyRad = state.dataSolarShading.SurfMultIsoSky[DomeSurf - 1] * state.dataSolarShading.SurfCurDifShdgRatioIsoSky[DomeSurf - 1]
            HorizonRad = state.dataSolarShading.SurfMultHorizonZenith[DomeSurf - 1] * \
                         state.dataSolarShading.SurfDifShdgRatioHorizHRTS[state.dataGlobal.TimeStep - 1][state.dataGlobal.HourOfDay - 1][DomeSurf - 1]
        CircumSolarRad = state.dataSolarShading.SurfMultCircumSolar[DomeSurf - 1] * \
                         state.dataHeatBal.SurfSunlitFrac[state.dataGlobal.HourOfDay - 1][state.dataGlobal.TimeStep - 1][DomeSurf - 1]
        AnisoSkyTDDMult = state.dataDaylightingDevicesData.TDDPipe[idx].TransSolIso * IsoSkyRad +
                          TransTDD(state, PipeNum, COSI, RadType.SolarBeam) * CircumSolarRad +
                          state.dataDaylightingDevicesData.TDDPipe[idx].TransSolHorizon * HorizonRad
        if state.dataSolarShading.SurfAnisoSkyMult[DomeSurf - 1] > 0.0:
            CalcTDDTransSolAniso = AnisoSkyTDDMult / state.dataSolarShading.SurfAnisoSkyMult[DomeSurf - 1]
        else:
            CalcTDDTransSolAniso = 0.0
        return CalcTDDTransSolAniso
    def TransTDD(state: EnergyPlusData, PipeNum: Int, COSI: Float64, RadiationType: RadType) raises -> Float64:
        var TransTDD: Float64
        var constDome: Int
        var constDiff: Int
        var transDome: Float64
        var transPipe: Float64
        var transDiff: Float64
        TransTDD = 0.0
        var idx = PipeNum - 1
        constDome = state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[idx].Dome - 1].Construction
        constDiff = state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[idx].Diffuser - 1].Construction
        if RadiationType == RadType.VisibleBeam:
            transDome = Window.POLYF(COSI, state.dataConstruction.Construct(constDome - 1).TransVisBeamCoef)
            transPipe = InterpolatePipeTransBeam(state, COSI, state.dataDaylightingDevicesData.TDDPipe[idx].PipeTransVisBeam)
            transDiff = state.dataConstruction.Construct(constDiff - 1).TransDiffVis
            TransTDD = transDome * transPipe * transDiff
        elif RadiationType == RadType.SolarBeam:
            transDome = Window.POLYF(COSI, state.dataConstruction.Construct(constDome - 1).TransSolBeamCoef)
            transPipe = InterpolatePipeTransBeam(state, COSI, state.dataDaylightingDevicesData.TDDPipe[idx].PipeTransSolBeam)
            transDiff = state.dataConstruction.Construct(constDiff - 1).TransDiff
            TransTDD = transDome * transPipe * transDiff
        elif RadiationType == RadType.SolarAniso:
            TransTDD = CalcTDDTransSolAniso(state, PipeNum, COSI)
        elif RadiationType == RadType.SolarIso:
            TransTDD = state.dataDaylightingDevicesData.TDDPipe[idx].TransSolIso
        else:

        return TransTDD
    def InterpolatePipeTransBeam(state: EnergyPlusData, COSI: Float64, transBeam: DynamicVector[Float64]) raises -> Float64:
        var InterpolatePipeTransBeam: Float64
        if transBeam.size != NumOfAngles:

        var Lo: Int
        var Hi: Int
        var m: Float64
        var b: Float64
        InterpolatePipeTransBeam = 0.0
        Lo = Fluid.FindArrayIndex(COSI, state.dataDaylightingDevices.COSAngle)
        Hi = Lo + 1
        if Lo > 0 and Hi <= NumOfAngles:
            m = (transBeam[Hi - 1] - transBeam[Lo - 1]) / (state.dataDaylightingDevices.COSAngle[Hi - 1] - state.dataDaylightingDevices.COSAngle[Lo - 1])
            b = transBeam[Lo - 1] - m * state.dataDaylightingDevices.COSAngle[Lo - 1]
            InterpolatePipeTransBeam = m * COSI + b
        else:
            InterpolatePipeTransBeam = 0.0
        return InterpolatePipeTransBeam
    def FindTDDPipe(state: EnergyPlusData, WinNum: Int) raises -> Int:
        var FindTDDPipe: Int
        var PipeNum: Int
        FindTDDPipe = 0
        if state.dataDaylightingDevicesData.TDDPipe.size <= 0:
            ShowFatalError(state,
                           format("FindTDDPipe: Surface={}, TDD:Dome object does not reference a valid Diffuser object....needs "
                                   "DaylightingDevice:Tubular of same name as Surface.",
                                   state.dataSurface.Surface[WinNum - 1].Name))
        for PipeNum = 1
            PipeNum <= state.dataDaylightingDevicesData.TDDPipe.size
            PipeNum += 1:
            var pIdx = PipeNum - 1
            if (WinNum == state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome) or \
               (WinNum == state.dataDaylightingDevicesData.TDDPipe[pIdx].Diffuser):
                FindTDDPipe = PipeNum
                break
        return FindTDDPipe
    def DistributeTDDAbsorbedSolar(state: EnergyPlusData) raises:
        for var PipeNum = 1
            PipeNum <= state.dataDaylightingDevicesData.TDDPipe.size
            PipeNum += 1:
            var pIdx = PipeNum - 1
            var DiffSurf: Int = state.dataDaylightingDevicesData.TDDPipe[pIdx].Diffuser
            var transDiff: Float64 = state.dataConstruction.Construct(state.dataSurface.Surface[DiffSurf - 1].Construction).TransDiff
            var QRefl: Float64 = (state.dataHeatBal.SurfQRadSWOutIncident[DiffSurf - 1] - state.dataHeatBal.SurfWinQRadSWwinAbsTot[DiffSurf - 1]) * \
                                  state.dataSurface.Surface[DiffSurf - 1].Area - \
                                  state.dataSurface.SurfWinTransSolar[DiffSurf - 1]
            QRefl += state.dataHeatBal.EnclSolQSWRad[state.dataSurface.Surface[DiffSurf - 1].SolarEnclIndex - 1] * \
                     state.dataSurface.Surface[DiffSurf - 1].Area * transDiff
            var TotTDDPipeGain: Float64 = state.dataSurface.SurfWinTransSolar[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1] -
                                          state.dataHeatBal.SurfQRadSWOutIncident[DiffSurf - 1] * state.dataSurface.Surface[DiffSurf - 1].Area +
                                          QRefl * (1.0 - state.dataDaylightingDevicesData.TDDPipe[pIdx].TransSolIso / transDiff) +
                                          state.dataHeatBal.SurfWinQRadSWwinAbs[state.dataDaylightingDevicesData.TDDPipe[pIdx].Dome - 1][0] * \
                                              state.dataSurface.Surface[DiffSurf - 1].Area / 2.0 +
                                          state.dataHeatBal.SurfWinQRadSWwinAbs[DiffSurf - 1][0] * state.dataSurface.Surface[DiffSurf - 1].Area / 2.0
            state.dataDaylightingDevicesData.TDDPipe[pIdx].PipeAbsorbedSolar = max(0.0, TotTDDPipeGain)
            for var TZoneNum = 1
                TZoneNum <= state.dataDaylightingDevicesData.TDDPipe[pIdx].NumOfTZones
                TZoneNum += 1:
                var tIdx = TZoneNum - 1
                state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneHeatGain[tIdx] =
                    TotTDDPipeGain * (state.dataDaylightingDevicesData.TDDPipe[pIdx].TZoneLength[tIdx] /
                                      state.dataDaylightingDevicesData.TDDPipe[pIdx].TotLength)
    def CalcViewFactorToShelf(state: EnergyPlusData, ShelfNum: Int) raises:
        var sIdx = ShelfNum - 1
        var W: Float64
        var H: Float64
        var L: Float64
        var M: Float64
        var N: Float64
        var E1: Float64
        var E2: Float64
        var E3: Float64
        var E4: Float64
        var VWin: Int
        var VShelf: Int
        var NumMatch: Int
        W = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].Window - 1].Width
        H = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].Window - 1].Height
        if state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf - 1].Width == W:
            L = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf - 1].Height
        elif state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf - 1].Height == W:
            L = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf - 1].Width
        else:
            ShowFatalError(state,
                           format("DaylightingDevice:Shelf = {}:  Width of window and outside shelf do not match.",
                                   state.dataDaylightingDevicesData.Shelf[sIdx].Name))
        NumMatch = 0
        for VWin = 1
            VWin <= 4
            VWin += 1:
            for VShelf = 1
                VShelf <= 4
                VShelf += 1:
                if distance(state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].Window - 1].Vertex[VWin - 1],
                            state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[sIdx].OutSurf - 1].Vertex[VShelf - 1]) == 0.0:
                    NumMatch += 1
        if NumMatch < 2:
            ShowWarningError(state,
                             format("DaylightingDevice:Shelf = {}:  Window and outside shelf must share two vertices.  View factor calculation may be inaccurate.",
                                     state.dataDaylightingDevicesData.Shelf[sIdx].Name))
        elif NumMatch > 2:
            ShowFatalError(state,
                           format("DaylightingDevice:Shelf = {}:  Window and outside shelf share too many vertices.",
                                   state.dataDaylightingDevicesData.Shelf[sIdx].Name))
        M = H / W
        N = L / W
        E1 = M * atan(1.0 / M) + N * atan(1.0 / N) - sqrt(N * N + M * M) * atan(1.0 / sqrt(N * N + M * M))
        E2 = ((1.0 + M * M) * (1.0 + N * N)) / (1.0 + M * M + N * N)
        E3 = pow(M * M * (1.0 + M * M + N * N) / ((1.0 + M * M) * (M * M + N * N)), M * M)
        E4 = pow(N * N * (1.0 + M * M + N * N) / ((1.0 + N * N) * (M * M + N * N)), N * N)
        state.dataDaylightingDevicesData.Shelf[sIdx].ViewFactor = (1.0 / (Constant.Pi * M)) * (E1 + 0.25 * log(E2 * E3 * E4))
    def adjustViewFactorsWithShelf(state: EnergyPlusData,
                                   inout viewFactorToShelf: Float64,
                                   inout viewFactorToSky: Float64,
                                   inout viewFactorToGround: Float64,
                                   WinSurf: Int,
                                   ShelfNum: Int) raises:
        if viewFactorToSky <= 0.0:
            viewFactorToSky = 0.0
        if viewFactorToGround <= 0.0:
            viewFactorToGround = 0.0
        if viewFactorToShelf <= 0.0:
            ShowWarningError(state,
                             format("DaylightingDevice:Shelf = {}:  Window view factor to shelf was less than 0.  This should not happen.",
                                     state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].Name))
            ShowContinueError(state, "The view factor has been reset to zero.")
            viewFactorToShelf = 0.0
            if (viewFactorToGround + viewFactorToSky) > 1.0:
                viewFactorToGround = viewFactorToGround / (viewFactorToGround + viewFactorToSky)
                viewFactorToSky = 1.0 - viewFactorToGround
                ShowWarningError(state,
                                 format("DaylightingDevice:Shelf = {}:  The sum of the window view factors to ground and sky were greater than 1.  "
                                         "This should not happen.",
                                         state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].Name))
                ShowContinueError(state,
                                  "The view factors have been reset to so that they do not exceed 1.  Check/fix your input file data to avoid this issue.")
            return
        if viewFactorToShelf + viewFactorToSky + viewFactorToGround <= 1.0:
            return
        if viewFactorToShelf >= 1.0:
            ShowWarningError(state,
                             format("DaylightingDevice:Shelf = {}:  Window view factor to shelf was greater than 1.  This should not happen.",
                                     state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].Name))
            ShowContinueError(state, "The view factor has been reset to 1 and the other view factors to sky and ground have been set to 0.")
            viewFactorToShelf = 1.0
            viewFactorToGround = 0.0
            viewFactorToSky = 0.0
            return
        var ShelfSurf: Int = state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].OutSurf
        var zShelfMax: Float64 = state.dataSurface.Surface[ShelfSurf - 1].Vertex[0].z
        var zShelfMin: Float64 = zShelfMax
        for var vertex = 2
            vertex <= state.dataSurface.Surface[ShelfSurf - 1].Sides
            vertex += 1:
            var vIdx = vertex - 1
            if state.dataSurface.Surface[ShelfSurf - 1].Vertex[vIdx].z > zShelfMax:
                zShelfMax = state.dataSurface.Surface[ShelfSurf - 1].Vertex[vIdx].z
            if state.dataSurface.Surface[ShelfSurf - 1].Vertex[vIdx].z < zShelfMin:
                zShelfMin = state.dataSurface.Surface[ShelfSurf - 1].Vertex[vIdx].z
        var zWinMax: Float64 = state.dataSurface.Surface[WinSurf - 1].Vertex[0].z
        var zWinMin: Float64 = zWinMax
        for var vertex = 2
            vertex <= state.dataSurface.Surface[WinSurf - 1].Sides
            vertex += 1:
            var vIdx = vertex - 1
            if state.dataSurface.Surface[WinSurf - 1].Vertex[vIdx].z > zWinMax:
                zWinMax = state.dataSurface.Surface[WinSurf - 1].Vertex[vIdx].z
            if state.dataSurface.Surface[WinSurf - 1].Vertex[vIdx].z < zWinMin:
                zWinMin = state.dataSurface.Surface[WinSurf - 1].Vertex[vIdx].z
        var leftoverViewFactor: Float64
        ShowWarningError(state,
                         format("DaylightingDevice:Shelf = {}:  Window view factor to shelf [{:.2f}] results in a sum of view factors greater than 1.",
                                 state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].Name,
                                 state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].ViewFactor))
        if zWinMin >= zShelfMax:
            ShowContinueError(state,
                              "Since the light shelf is below the window to which it is associated, the view factor of the window to the ground was reduced")
            ShowContinueError(state,
                              "and possibly also the view factor to the sky. Check you input and/or consider turning off autosizing of the view factors.")
            leftoverViewFactor = 1.0 - viewFactorToShelf - viewFactorToSky
            if leftoverViewFactor >= 0.0:
                viewFactorToGround = leftoverViewFactor
            else:
                viewFactorToGround = 0.0
                viewFactorToSky = 1.0 - viewFactorToShelf
                if viewFactorToSky < 0.0:
                    viewFactorToSky = 0.0
                    viewFactorToShelf = 1.0
        elif zShelfMin >= zWinMax:
            ShowContinueError(state,
                              "Since the light shelf is above the window to which it is associated, the view factor of the window to the sky was reduced")
            ShowContinueError(state,
                              "and possibly also the view factor to the ground. Check you input and/or consider turning off autosizing of the view factors.")
            leftoverViewFactor = 1.0 - viewFactorToShelf - viewFactorToGround
            if leftoverViewFactor >= 0.0:
                viewFactorToSky = leftoverViewFactor
            else:
                viewFactorToSky = 0.0
                viewFactorToGround = 1.0 - viewFactorToShelf
                if viewFactorToGround < 0.0:
                    viewFactorToGround = 0.0
                    viewFactorToShelf = 1.0
        else:
            ShowContinueError(state,
                              "Since the light shelf is neither fully above or fully below the window to which it is associated, the view factor of the window")
            ShowContinueError(state,
                              "to the ground and sky were both potentially reduced. Check you input and/or consider turning off autosizing of the view factors.")
            var zShelfAvg: Float64
            if ((zShelfMin >= zWinMin) and (zShelfMax <= zWinMax)) or \
               ((zShelfMin < zWinMin) and (zShelfMax > zWinMax)):
                zShelfAvg = 0.5 * (zShelfMin + zShelfMax)
            elif zShelfMin < zWinMin:
                var fracAbove: Float64 = 0.0
                if zShelfMax > zShelfMin:
                    fracAbove = (zShelfMax - zWinMin) / (zShelfMax - zShelfMin)
                    if fracAbove > 1.0:
                        fracAbove = 1.0
                zShelfAvg = zWinMin + fracAbove * (zShelfMax - zWinMin)
            else:
                var fracBelow: Float64 = 0.0
                if zShelfMax > zShelfMin:
                    fracBelow = (zWinMax - zShelfMin) / (zShelfMax - zShelfMin)
                zShelfAvg = zWinMax - fracBelow * (zWinMax - zShelfMin)
            var heightRatio: Float64
            if zWinMax > zWinMin:
                heightRatio = (zShelfAvg - zWinMin) / (zWinMax - zWinMin)
                heightRatio = min(heightRatio, 1.0)
                heightRatio = max(heightRatio, 0.0)
            else:
                if zShelfAvg > zWinMax:
                    heightRatio = 1.0
                else:
                    heightRatio = 0.0
            leftoverViewFactor = 1.0 - viewFactorToShelf
            var vfGroundAdjustMax: Float64
            var vfGroundAdjustMin: Float64
            if viewFactorToGround > viewFactorToShelf:
                vfGroundAdjustMin = viewFactorToGround - viewFactorToShelf
            else:
                vfGroundAdjustMin = 0.0
            if viewFactorToGround > leftoverViewFactor:
                vfGroundAdjustMax = leftoverViewFactor
            else:
                vfGroundAdjustMax = viewFactorToGround
            viewFactorToGround = vfGroundAdjustMin + heightRatio * (vfGroundAdjustMax - vfGroundAdjustMin)
            viewFactorToSky = leftoverViewFactor - viewFactorToGround
        ShowWarningError(state,
                         format("DaylightingDevice:Shelf = {}:  As a result of user input (see previous messages), at least one view factor but "
                                 "possibly more than one was reduced.",
                                 state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].Name))
        ShowContinueError(state,
                          "These include the view factors to the ground, the sky, and the exterior light shelf.  Note that views to other exterior "
                          "surfaces could further complicated this.")
        ShowContinueError(state, "Please consider manually calculating or adjusting view factors to avoid this problem.")
    def FigureTDDZoneGains(state: EnergyPlusData) raises:
        if state.dataDaylightingDevicesData.TDDPipe.size == 0:
            return
        if state.dataGlobal.BeginEnvrnFlag and state.dataDaylightingDevices.MyEnvrnFlag:
            for var Loop = 1
                Loop <= state.dataDaylightingDevicesData.TDDPipe.size
                Loop += 1:
                var lIdx = Loop - 1
                var numZones = state.dataDaylightingDevicesData.TDDPipe[lIdx].TZoneHeatGain.size
                for var i = 0
                    i < numZones
                    i += 1:
                    state.dataDaylightingDevicesData.TDDPipe[lIdx].TZoneHeatGain[i] = 0.0
            state.dataDaylightingDevices.MyEnvrnFlag = False
        if not state.dataGlobal.BeginEnvrnFlag:
            state.dataDaylightingDevices.MyEnvrnFlag = True