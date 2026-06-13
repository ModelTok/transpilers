from typing import Protocol, Optional, List, Any
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing dataDaylightingDevicesData, dataDaylightingDevices,
#   dataSurface, dataConstruction, dataInputProcessing, dataIPShortCut, dataHeatBal,
#   dataSolarShading, dataSysVars, dataGlobal, dataDayltg, dataConstruction, files
# - RadType enum: VisibleBeam, SolarBeam, SolarAniso, SolarIso
# - SurfaceClass enum: TDD_Dome, TDD_Diffuser, Window, Shading
# - Constant namespace: DegToRad, Pi, PiOvr2, iHoursInDay, Units
# - DisplayString, ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError
# - Util functions: FindItemInList, SafeDivide
# - Window module: POLYF
# - Fluid module: FindArrayIndex
# - HeatBalanceInternalHeatGains: SetupZoneInternalGain
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType
# - DataHeatBalance: IntGainType
# - distance, print functions for file I/O


@dataclass
class DaylightingDevicesData:
    COSAngle: List[float] = field(default_factory=lambda: [0.0] * 37)  # NumOfAngles = 37
    ShelfReported: bool = False
    GetTDDInputErrorsFound: bool = False
    GetShelfInputErrorsFound: bool = False
    MyEnvrnFlag: bool = True

    def init_constant_state(self, state: 'EnergyPlusData') -> None:
        pass

    def init_state(self, state: 'EnergyPlusData') -> None:
        pass

    def clear_state(self) -> None:
        self.COSAngle = [0.0] * 37
        self.ShelfReported = False
        self.GetTDDInputErrorsFound = False
        self.GetShelfInputErrorsFound = False
        self.MyEnvrnFlag = True


class EnergyPlusData(Protocol):
    dataDaylightingDevicesData: Any
    dataDaylightingDevices: DaylightingDevicesData
    dataSurface: Any
    dataConstruction: Any
    dataInputProcessing: Any
    dataIPShortCut: Any
    dataHeatBal: Any
    dataSolarShading: Any
    dataSysVars: Any
    dataGlobal: Any
    dataDayltg: Any
    files: Any


class RadType:
    VisibleBeam = 1
    SolarBeam = 2
    SolarAniso = 3
    SolarIso = 4


class Constant:
    DegToRad = math.pi / 180.0
    Pi = math.pi
    PiOvr2 = math.pi / 2.0
    iHoursInDay = 24


NumOfAngles = 37
MaxTZones = 10


def init_daylighting_devices(state: 'EnergyPlusData') -> None:
    """Initialize all daylighting devices: TDD pipes and daylighting shelves."""
    
    @dataclass
    class TDDPipeStoredData:
        AspectRatio: float = 0.0
        Reflectance: float = 0.0
        TransBeam: List[float] = field(default_factory=lambda: [0.0] * NumOfAngles)

    TDDPipeStored: List[TDDPipeStoredData] = []

    get_tdd_input(state)

    if len(state.dataDaylightingDevicesData.TDDPipe) > 0:
        display_string(state, "Initializing Tubular Daylighting Devices")
        
        state.dataDaylightingDevices.COSAngle[0] = 0.0
        state.dataDaylightingDevices.COSAngle[NumOfAngles - 1] = 1.0

        dTheta = 90.0 * Constant.DegToRad / (NumOfAngles - 1.0)
        Theta = 90.0 * Constant.DegToRad
        
        for AngleNum in range(1, NumOfAngles - 1):
            Theta -= dTheta
            state.dataDaylightingDevices.COSAngle[AngleNum] = math.cos(Theta)

        TDDPipeStored = [TDDPipeStoredData() for _ in range(len(state.dataDaylightingDevicesData.TDDPipe) * 2)]

        for PipeNum in range(len(state.dataDaylightingDevicesData.TDDPipe)):
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].AspectRatio = (
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TotLength /
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diameter
            )
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].ReflectVis = (
                1.0 - state.dataConstruction.Construct[
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].Construction
                ].InsideAbsorpVis
            )
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].ReflectSol = (
                1.0 - state.dataConstruction.Construct[
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].Construction
                ].InsideAbsorpSolar
            )

            Reflectance = state.dataDaylightingDevicesData.TDDPipe[PipeNum].ReflectVis
            NumStored = 0
            
            for Loop in range(2):
                Found = False
                StoredNum = 0
                
                for StoredNum in range(NumStored):
                    if (TDDPipeStored[StoredNum].AspectRatio !=
                        state.dataDaylightingDevicesData.TDDPipe[PipeNum].AspectRatio):
                        continue
                    if TDDPipeStored[StoredNum].Reflectance == Reflectance:
                        Found = True
                        break

                if not Found:
                    TDDPipeStored[NumStored] = TDDPipeStoredData()
                    TDDPipeStored[NumStored].AspectRatio = (
                        state.dataDaylightingDevicesData.TDDPipe[PipeNum].AspectRatio
                    )
                    TDDPipeStored[NumStored].Reflectance = Reflectance
                    TDDPipeStored[NumStored].TransBeam[0] = 0.0
                    TDDPipeStored[NumStored].TransBeam[NumOfAngles - 1] = 1.0

                    Theta = 90.0 * Constant.DegToRad
                    for AngleNum in range(1, NumOfAngles - 1):
                        Theta -= dTheta
                        TDDPipeStored[NumStored].TransBeam[AngleNum] = calc_pipe_trans_beam(
                            Reflectance,
                            state.dataDaylightingDevicesData.TDDPipe[PipeNum].AspectRatio,
                            Theta
                        )

                    StoredNum = NumStored
                    NumStored += 1

                if Loop == 0:
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeTransVisBeam = (
                        TDDPipeStored[StoredNum].TransBeam[:]
                    )
                else:
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeTransSolBeam = (
                        TDDPipeStored[StoredNum].TransBeam[:]
                    )

                Reflectance = state.dataDaylightingDevicesData.TDDPipe[PipeNum].ReflectSol

            state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolIso = (
                calc_tdd_trans_sol_iso(state, PipeNum)
            )
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolHorizon = (
                calc_tdd_trans_sol_horizon(state, PipeNum)
            )

            SumTZoneLengths = 0.0
            for TZoneNum in range(state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones):
                SumTZoneLengths += state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneLength[TZoneNum]
                setup_zone_internal_gain(
                    state,
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZone[TZoneNum],
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name,
                    1,  # IntGainType::DaylightingDeviceTubular
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneHeatGain[TZoneNum]
                )

            state.dataDaylightingDevicesData.TDDPipe[PipeNum].ExtLength = (
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TotLength - SumTZoneLengths
            )

            setup_output_variable(state, "Tubular Daylighting Device Transmitted Solar Radiation Rate",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransmittedSolar,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Pipe Absorbed Solar Radiation Rate",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeAbsorbedSolar,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Heat Gain Rate",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].HeatGain,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Heat Loss Rate",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].HeatLoss,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Beam Solar Transmittance",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolBeam,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Beam Visible Transmittance",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransVisBeam,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Diffuse Solar Transmittance",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolDiff,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)
            setup_output_variable(state, "Tubular Daylighting Device Diffuse Visible Transmittance",
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransVisDiff,
                                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name)

    get_shelf_input(state)

    if len(state.dataDaylightingDevicesData.Shelf) > 0:
        display_string(state, "Initializing Light Shelf Daylighting Devices")

    for ShelfNum in range(len(state.dataDaylightingDevicesData.Shelf)):
        WinSurf = state.dataDaylightingDevicesData.Shelf[ShelfNum].Window

        ShelfSurf = state.dataDaylightingDevicesData.Shelf[ShelfNum].InSurf
        if ShelfSurf > 0:
            state.dataSurface.Surface[ShelfSurf].Area *= 2.0
            state.dataGlobal.AnyInsideShelf = True

        ShelfSurf = state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf
        if ShelfSurf > 0:
            state.dataDaylightingDevicesData.Shelf[ShelfNum].OutReflectVis = (
                1.0 - state.dataConstruction.Construct[
                    state.dataDaylightingDevicesData.Shelf[ShelfNum].Construction
                ].OutsideAbsorpVis
            )
            state.dataDaylightingDevicesData.Shelf[ShelfNum].OutReflectSol = (
                1.0 - state.dataConstruction.Construct[
                    state.dataDaylightingDevicesData.Shelf[ShelfNum].Construction
                ].OutsideAbsorpSolar
            )

            if state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor < 0:
                calc_view_factor_to_shelf(state, ShelfNum)

            adjust_view_factors_with_shelf(
                state,
                state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor,
                state.dataSurface.Surface[WinSurf].ViewFactorSky,
                state.dataSurface.Surface[WinSurf].ViewFactorGround,
                WinSurf,
                ShelfNum
            )

            if not state.dataDaylightingDevices.ShelfReported:
                print_eio(state, "! <Shelf Details>,Name,View Factor to Outside Shelf,Window Name,Window View Factor to Sky,Window View Factor to Ground\n")
                state.dataDaylightingDevices.ShelfReported = True
            
            print_eio(state, f"Shelf Details,{state.dataDaylightingDevicesData.Shelf[ShelfNum].Name},"
                     f"{state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor:.2f},"
                     f"{state.dataSurface.Surface[WinSurf].Name},"
                     f"{state.dataSurface.Surface[WinSurf].ViewFactorSky:.2f},"
                     f"{state.dataSurface.Surface[WinSurf].ViewFactorGround:.2f}\n")

    if (state.dataSurface.CalcSolRefl and
        (len(state.dataDaylightingDevicesData.TDDPipe) > 0 or len(state.dataDaylightingDevicesData.Shelf) > 0)):
        show_warning_error(state, "InitDaylightingDevices: Solar Distribution Model includes Solar Reflection calculations;")
        show_continue_error(state, "the resulting reflected solar values will not be used in the")
        show_continue_error(state, "DaylightingDevice:Shelf or DaylightingDevice:Tubular calculations.")


def get_tdd_input(state: 'EnergyPlusData') -> None:
    """Gets the input for TDD pipes and does some error checking."""
    
    ipsc = state.dataIPShortCut
    cCurrentModuleObject = "DaylightingDevice:Tubular"
    NumOfTDDPipes = get_num_objects_found(state, cCurrentModuleObject)

    if NumOfTDDPipes > 0:
        state.dataDaylightingDevicesData.TDDPipe = [None] * NumOfTDDPipes
        
        for PipeNum in range(NumOfTDDPipes):
            get_object_item(state, cCurrentModuleObject, PipeNum,
                          ipsc.cAlphaArgs, ipsc.rNumericArgs, ipsc.lNumericFieldBlanks)
            
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].Name = ipsc.cAlphaArgs[0]

            SurfNum = find_item_in_list(ipsc.cAlphaArgs[1], state.dataSurface.Surface)

            if SurfNum == 0:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} not found.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True
            else:
                if find_tdd_pipe(state, SurfNum) > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} is referenced by more than one TDD.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].Class != 1:  # SurfaceClass::TDD_Dome
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} is not of surface type TubularDaylightDome.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].TotGlassLayers > 1:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} construction ({state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].Name}) must have only 1 glass layer.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].HasShadeControl:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} must not have a shading control.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].FrameDivider > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} must not have a frame/divider.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].WindowTypeEQL:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} Equivalent Layer Window is not supported.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if not state.dataSurface.Surface[SurfNum].ExtSolar:
                    show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome {ipsc.cAlphaArgs[1]} is not exposed to exterior radiation.")

                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome = SurfNum
                state.dataSurface.SurfWinTDDPipeNum[SurfNum] = PipeNum

            SurfNum = find_item_in_list(ipsc.cAlphaArgs[2], state.dataSurface.Surface)

            if SurfNum == 0:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} not found.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True
            else:
                if find_tdd_pipe(state, SurfNum) > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} is referenced by more than one TDD.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].OriginalClass != 2:  # SurfaceClass::TDD_Diffuser
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} is not of surface type TubularDaylightDiffuser.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].TotGlassLayers > 1:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} construction ({state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].Name}) must have only 1 glass layer.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].TransDiff <= 1.0e-10:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} construction ({state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].Name}) invalid value.")
                    show_continue_error(state, f"Diffuse solar transmittance of construction [{state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].TransDiff:.4f}] too small for calculations.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if (state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome > 0 and
                    abs(state.dataSurface.Surface[SurfNum].Area -
                        state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area) > 0.1):
                    ratio = safe_divide(
                        abs(state.dataSurface.Surface[SurfNum].Area -
                            state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area),
                        state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area
                    )
                    if ratio > 0.1:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome and diffuser areas are significantly different (>10%).")
                        show_continue_error(state, f"...Diffuser Area=[{state.dataSurface.Surface[SurfNum].Area:.4f}]; Dome Area=[{state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area:.4f}].")
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                    else:
                        show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Dome and diffuser areas differ by > .1 m2.")
                        show_continue_error(state, f"...Diffuser Area=[{state.dataSurface.Surface[SurfNum].Area:.4f}]; Dome Area=[{state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area:.4f}].")

                if state.dataSurface.Surface[SurfNum].HasShadeControl:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} must not have a shading control.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].FrameDivider > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} must not have a frame/divider.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].WindowTypeEQL:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Diffuser {ipsc.cAlphaArgs[2]} Equivalent Layer Window is not supported.")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diffuser = SurfNum
                state.dataSurface.SurfWinTDDPipeNum[SurfNum] = PipeNum

            state.dataDaylightingDevicesData.TDDPipe[PipeNum].Construction = find_item_in_list(
                ipsc.cAlphaArgs[3], state.dataConstruction.Construct
            )

            if state.dataDaylightingDevicesData.TDDPipe[PipeNum].Construction == 0:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Pipe construction {ipsc.cAlphaArgs[3]} not found.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True
            else:
                state.dataConstruction.Construct[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Construction].IsUsed = True

            if ipsc.rNumericArgs[0] > 0:
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diameter = ipsc.rNumericArgs[0]
            else:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Pipe diameter must be greater than zero.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True

            PipeArea = 0.25 * Constant.Pi * (state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diameter ** 2)
            if (state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome > 0 and
                abs(PipeArea - state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area) > 0.1):
                ratio = safe_divide(
                    abs(PipeArea - state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area),
                    state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area
                )
                if ratio > 0.1:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Pipe and dome/diffuser areas are significantly different (>10%).")
                    show_continue_error(state, f"...Pipe Area=[{PipeArea:.4f}]; Dome/Diffuser Area=[{state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area:.4f}].")
                    state.dataDaylightingDevices.GetTDDInputErrorsFound = True
                else:
                    show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Pipe and dome/diffuser areas differ by > .1 m2.")
                    show_continue_error(state, f"...Pipe Area=[{PipeArea:.4f}]; Dome/Diffuser Area=[{state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Area:.4f}].")

            if ipsc.rNumericArgs[1] > 0:
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TotLength = ipsc.rNumericArgs[1]
            else:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Pipe length must be greater than zero.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True

            if ipsc.rNumericArgs[2] > 0:
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].Reff = ipsc.rNumericArgs[2]
            else:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Effective thermal resistance (R value) must be greater than zero.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True

            state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones = len(ipsc.cAlphaArgs) - 4

            if state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones < 1:
                show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: No transition zones specified. All pipe absorbed solar goes to exterior.")
            elif state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones > MaxTZones:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Maximum number of transition zones exceeded.")
                state.dataDaylightingDevices.GetTDDInputErrorsFound = True
            else:
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZone = [0] * state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneLength = [0.0] * state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones
                state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneHeatGain = [0.0] * state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones

                for TZoneNum in range(state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones):
                    TZoneName = ipsc.cAlphaArgs[TZoneNum + 4]
                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZone[TZoneNum] = find_item_in_list(TZoneName, state.dataHeatBal.Zone)
                    if state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZone[TZoneNum] == 0:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Transition zone {TZoneName} not found.")
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True

                    state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneLength[TZoneNum] = ipsc.rNumericArgs[TZoneNum + 3]
                    if state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneLength[TZoneNum] < 0:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Transition zone length for {TZoneName} must be zero or greater.")
                        state.dataDaylightingDevices.GetTDDInputErrorsFound = True

        if state.dataDaylightingDevices.GetTDDInputErrorsFound:
            show_fatal_error(state, "Errors in DaylightingDevice:Tubular input.")

        state.dataDayltg.TDDTransVisBeam = [[0.0] * NumOfTDDPipes for _ in range(Constant.iHoursInDay)]
        state.dataDayltg.TDDFluxInc = [[None] * NumOfTDDPipes for _ in range(Constant.iHoursInDay)]
        state.dataDayltg.TDDFluxTrans = [[None] * NumOfTDDPipes for _ in range(Constant.iHoursInDay)]
        for hr in range(Constant.iHoursInDay):
            for tddNum in range(NumOfTDDPipes):
                state.dataDayltg.TDDTransVisBeam[hr][tddNum] = 0.0
                state.dataDayltg.TDDFluxInc[hr][tddNum] = illums_default()
                state.dataDayltg.TDDFluxTrans[hr][tddNum] = illums_default()


def get_shelf_input(state: 'EnergyPlusData') -> None:
    """Gets the input for light shelves and does some error checking."""
    
    ipsc = state.dataIPShortCut
    cCurrentModuleObject = "DaylightingDevice:Shelf"
    NumOfShelf = get_num_objects_found(state, cCurrentModuleObject)

    if NumOfShelf > 0:
        state.dataDaylightingDevicesData.Shelf = [None] * NumOfShelf

        for ShelfNum in range(NumOfShelf):
            get_object_item(state, cCurrentModuleObject, ShelfNum,
                          ipsc.cAlphaArgs, ipsc.rNumericArgs, ipsc.lNumericFieldBlanks)
            
            state.dataDaylightingDevicesData.Shelf[ShelfNum].Name = ipsc.cAlphaArgs[0]

            SurfNum = find_item_in_list(ipsc.cAlphaArgs[1], state.dataSurface.Surface)

            if SurfNum == 0:
                show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} not found.")
                state.dataDaylightingDevices.GetShelfInputErrorsFound = True
            else:
                if state.dataSurface.Surface[SurfNum].Class != 5:  # SurfaceClass::Window
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} is not of surface type WINDOW.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                if state.dataSurface.SurfDaylightingShelfInd[SurfNum] > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} is referenced by more than one shelf.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].HasShadeControl:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} must not have a shading control.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].FrameDivider > 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} must not have a frame/divider.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                if state.dataSurface.Surface[SurfNum].Sides != 4:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} must have 4 sides.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].WindowTypeEQL:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Window {ipsc.cAlphaArgs[1]} Equivalent Layer Window is not supported.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                state.dataDaylightingDevicesData.Shelf[ShelfNum].Window = SurfNum
                state.dataSurface.SurfDaylightingShelfInd[SurfNum] = ShelfNum

            if len(ipsc.cAlphaArgs) > 2 and ipsc.cAlphaArgs[2]:
                SurfNum = find_item_in_list(ipsc.cAlphaArgs[2], state.dataSurface.Surface)

                if SurfNum == 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Inside shelf {ipsc.cAlphaArgs[2]} not found.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                else:
                    if state.dataSurface.Surface[SurfNum].ExtBoundCond != SurfNum:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Inside shelf {ipsc.cAlphaArgs[2]} must be its own Outside Boundary Condition Object.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    if state.dataSurface.Surface[SurfNum].Sides != 4:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Inside shelf {ipsc.cAlphaArgs[2]} must have 4 sides.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    state.dataDaylightingDevicesData.Shelf[ShelfNum].InSurf = SurfNum

            if len(ipsc.cAlphaArgs) > 3 and ipsc.cAlphaArgs[3]:
                SurfNum = find_item_in_list(ipsc.cAlphaArgs[3], state.dataSurface.Surface)

                if SurfNum == 0:
                    show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf {ipsc.cAlphaArgs[3]} not found.")
                    state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                else:
                    if state.dataSurface.Surface[SurfNum].Class != 3:  # SurfaceClass::Shading
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf {ipsc.cAlphaArgs[3]} is not a Shading:Zone:Detailed object.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    if state.dataSurface.Surface[SurfNum].shadowSurfSched is not None:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf {ipsc.cAlphaArgs[3]} must not have a transmittance schedule.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    if state.dataSurface.Surface[SurfNum].Sides != 4:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf {ipsc.cAlphaArgs[3]} must have 4 sides.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    ConstrNum = 0
                    if len(ipsc.cAlphaArgs) > 4 and ipsc.cAlphaArgs[4]:
                        ConstrNum = find_item_in_list(ipsc.cAlphaArgs[4], state.dataConstruction.Construct)

                        if ConstrNum == 0:
                            show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf construction {ipsc.cAlphaArgs[4]} not found.")
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        elif state.dataConstruction.Construct[ConstrNum].TypeIsWindow:
                            show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf construction {ipsc.cAlphaArgs[4]} must not have WindowMaterial:Glazing.")
                            state.dataDaylightingDevices.GetShelfInputErrorsFound = True
                        else:
                            state.dataDaylightingDevicesData.Shelf[ShelfNum].Construction = ConstrNum
                            state.dataConstruction.Construct[ConstrNum].IsUsed = True
                    else:
                        show_severe_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: Outside shelf requires an outside shelf construction to be specified.")
                        state.dataDaylightingDevices.GetShelfInputErrorsFound = True

                    if len(ipsc.rNumericArgs) > 0:
                        state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor = ipsc.rNumericArgs[0]

                        if ipsc.rNumericArgs[0] == 0.0:
                            show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: View factor to outside shelf is zero. Shelf does not reflect on window.")
                    else:
                        state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor = -1.0

                    state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf = SurfNum

                    state.dataSurface.Surface[SurfNum].BaseSurf = SurfNum
                    state.dataSurface.Surface[SurfNum].HeatTransSurf = True
                    state.dataSurface.AllHTSurfaceList.append(SurfNum)
                    state.dataSurface.Surface[SurfNum].Construction = ConstrNum
                    state.dataSurface.SurfActiveConstruction[SurfNum] = ConstrNum
                    state.dataConstruction.Construct[ConstrNum].IsUsed = True

            if state.dataDaylightingDevicesData.Shelf[ShelfNum].InSurf == 0 and state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf == 0:
                show_warning_error(state, f"{cCurrentModuleObject} = {ipsc.cAlphaArgs[0]}: No inside shelf or outside shelf was specified.")

        if state.dataDaylightingDevices.GetShelfInputErrorsFound:
            show_fatal_error(state, "Errors in DaylightingDevice:Shelf input.")


def calc_pipe_trans_beam(R: float, A: float, Theta: float) -> float:
    """Calculates the numerical integral for the transmittance of a reflective cylinder."""
    
    N = 100000.0
    xTol = 150.0
    myLocalTiny = 1e-30

    CalcPipeTransBeam = 0.0

    T = 0.0
    i = 1.0 / N

    xLimit = (math.log(N * N * myLocalTiny) / math.log(R)) / xTol

    c1 = A * math.tan(Theta)
    c2 = 4.0 / Constant.Pi

    s = i
    while s < (1.0 - i):
        x = c1 / s

        if x < xLimit:
            dT = c2 * (R ** int(x)) * (1.0 - (1.0 - R) * (x - int(x))) * (s * s) / math.sqrt(1.0 - s * s)
            T += dT

        s += i

    T /= (N - 1.0)

    CalcPipeTransBeam = T

    return CalcPipeTransBeam


def calc_tdd_trans_sol_iso(state: 'EnergyPlusData', PipeNum: int) -> float:
    """Calculates the transmittance of sky isotropic radiation."""
    
    NPH = 1000

    FluxInc = 0.0
    FluxTrans = 0.0

    dPH = 90.0 * Constant.DegToRad / NPH
    PH = 0.5 * dPH

    for N in range(1, NPH + 1):
        COSI = math.cos(Constant.PiOvr2 - PH)
        SINI = math.sin(Constant.PiOvr2 - PH)

        P = COSI

        trans = trans_tdd(state, PipeNum, COSI, RadType.SolarBeam)

        FluxInc += P * SINI * dPH
        FluxTrans += trans * P * SINI * dPH

        PH += dPH

    CalcTDDTransSolIso = FluxTrans / FluxInc if FluxInc != 0 else 0.0

    return CalcTDDTransSolIso


def calc_tdd_trans_sol_horizon(state: 'EnergyPlusData', PipeNum: int) -> float:
    """Calculates the transmittance of sky horizon radiation."""
    
    NTH = 18

    FluxInc = 0.0
    FluxTrans = 0.0

    DomeSurf = state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome
    CosPhi = math.cos(Constant.PiOvr2 - 
                      state.dataSurface.Surface[DomeSurf].Tilt * Constant.DegToRad)
    Theta = state.dataSurface.Surface[DomeSurf].Azimuth * Constant.DegToRad

    if CosPhi > 0.01:
        THMIN = Theta - Constant.PiOvr2
        dTH = 180.0 * Constant.DegToRad / NTH
        TH = THMIN + 0.5 * dTH

        for N in range(1, NTH + 1):
            COSI = CosPhi * math.cos(TH - Theta)
            trans = trans_tdd(state, PipeNum, COSI, RadType.SolarBeam)

            FluxInc += COSI * dTH
            FluxTrans += trans * COSI * dTH

            TH += dTH

        CalcTDDTransSolHorizon = FluxTrans / FluxInc if FluxInc != 0 else 0.0
    else:
        CalcTDDTransSolHorizon = 0.0

    return CalcTDDTransSolHorizon


def calc_tdd_trans_sol_aniso(state: 'EnergyPlusData', PipeNum: int, COSI: float) -> float:
    """Calculates the transmittance of the anisotropic sky."""
    
    DomeSurf = state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome

    if (not state.dataSysVars.DetailedSkyDiffuseAlgorithm or
        not state.dataSurface.ShadingTransmittanceVaries or
        state.dataHeatBal.SolarDistribution == 0):  # Minimal
        IsoSkyRad = (state.dataSolarShading.SurfMultIsoSky[DomeSurf] *
                    state.dataSolarShading.SurfDifShdgRatioIsoSky[DomeSurf])
        HorizonRad = (state.dataSolarShading.SurfMultHorizonZenith[DomeSurf] *
                     state.dataSolarShading.SurfDifShdgRatioHoriz[DomeSurf])
    else:
        IsoSkyRad = (state.dataSolarShading.SurfMultIsoSky[DomeSurf] *
                    state.dataSolarShading.SurfCurDifShdgRatioIsoSky[DomeSurf])
        HorizonRad = (state.dataSolarShading.SurfMultHorizonZenith[DomeSurf] *
                     state.dataSolarShading.SurfDifShdgRatioHorizHRTS[
                         state.dataGlobal.TimeStep,
                         state.dataGlobal.HourOfDay,
                         DomeSurf])

    CircumSolarRad = (state.dataSolarShading.SurfMultCircumSolar[DomeSurf] *
                     state.dataHeatBal.SurfSunlitFrac[
                         state.dataGlobal.HourOfDay,
                         state.dataGlobal.TimeStep,
                         DomeSurf])

    AnisoSkyTDDMult = (state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolIso * IsoSkyRad +
                      trans_tdd(state, PipeNum, COSI, RadType.SolarBeam) * CircumSolarRad +
                      state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolHorizon * HorizonRad)

    if state.dataSolarShading.SurfAnisoSkyMult[DomeSurf] > 0.0:
        CalcTDDTransSolAniso = AnisoSkyTDDMult / state.dataSolarShading.SurfAnisoSkyMult[DomeSurf]
    else:
        CalcTDDTransSolAniso = 0.0

    return CalcTDDTransSolAniso


def trans_tdd(state: 'EnergyPlusData', PipeNum: int, COSI: float, RadiationType: int) -> float:
    """Calculates the total transmittance of the TDD for specified radiation type."""
    
    TransTDD = 0.0

    constDome = state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome].Construction
    constDiff = state.dataSurface.Surface[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diffuser].Construction

    if RadiationType == RadType.VisibleBeam:
        transDome = polyf(COSI, state.dataConstruction.Construct[constDome].TransVisBeamCoef)
        transPipe = interpolate_pipe_trans_beam(state, COSI, state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeTransVisBeam)
        transDiff = state.dataConstruction.Construct[constDiff].TransDiffVis

        TransTDD = transDome * transPipe * transDiff

    elif RadiationType == RadType.SolarBeam:
        transDome = polyf(COSI, state.dataConstruction.Construct[constDome].TransSolBeamCoef)
        transPipe = interpolate_pipe_trans_beam(state, COSI, state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeTransSolBeam)
        transDiff = state.dataConstruction.Construct[constDiff].TransDiff

        TransTDD = transDome * transPipe * transDiff

    elif RadiationType == RadType.SolarAniso:
        TransTDD = calc_tdd_trans_sol_aniso(state, PipeNum, COSI)

    elif RadiationType == RadType.SolarIso:
        TransTDD = state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolIso

    return TransTDD


def interpolate_pipe_trans_beam(state: 'EnergyPlusData', COSI: float, transBeam: List[float]) -> float:
    """Interpolates the beam transmittance vs. cosine angle table."""
    
    InterpolatePipeTransBeam = 0.0

    Lo = find_array_index(COSI, state.dataDaylightingDevices.COSAngle)
    Hi = Lo + 1

    if Lo >= 0 and Hi < NumOfAngles:
        m = (transBeam[Hi] - transBeam[Lo]) / (state.dataDaylightingDevices.COSAngle[Hi] - state.dataDaylightingDevices.COSAngle[Lo])
        b = transBeam[Lo] - m * state.dataDaylightingDevices.COSAngle[Lo]

        InterpolatePipeTransBeam = m * COSI + b
    else:
        InterpolatePipeTransBeam = 0.0

    return InterpolatePipeTransBeam


def find_tdd_pipe(state: 'EnergyPlusData', WinNum: int) -> int:
    """Given the TDD:DOME or TDD:DIFFUSER object number, returns TDD pipe number."""
    
    FindTDDPipe = 0

    if len(state.dataDaylightingDevicesData.TDDPipe) <= 0:
        show_fatal_error(state,
                        f"FindTDDPipe: Surface={state.dataSurface.Surface[WinNum].Name}, TDD:Dome object does not reference a valid Diffuser object....needs DaylightingDevice:Tubular of same name as Surface.")

    for PipeNum in range(len(state.dataDaylightingDevicesData.TDDPipe)):
        if ((WinNum == state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome) or
            (WinNum == state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diffuser)):
            FindTDDPipe = PipeNum + 1
            break

    return FindTDDPipe


def distribute_tdd_absorbed_solar(state: 'EnergyPlusData') -> None:
    """Sums the absorbed solar gains from TDD pipes that pass through transition zones."""
    
    for PipeNum in range(len(state.dataDaylightingDevicesData.TDDPipe)):
        DiffSurf = state.dataDaylightingDevicesData.TDDPipe[PipeNum].Diffuser
        transDiff = state.dataConstruction.Construct[state.dataSurface.Surface[DiffSurf].Construction].TransDiff

        QRefl = ((state.dataHeatBal.SurfQRadSWOutIncident[DiffSurf] -
                 state.dataHeatBal.SurfWinQRadSWwinAbsTot[DiffSurf]) *
                state.dataSurface.Surface[DiffSurf].Area -
                state.dataSurface.SurfWinTransSolar[DiffSurf])

        QRefl += (state.dataHeatBal.EnclSolQSWRad[state.dataSurface.Surface[DiffSurf].SolarEnclIndex] *
                 state.dataSurface.Surface[DiffSurf].Area * transDiff)

        TotTDDPipeGain = (state.dataSurface.SurfWinTransSolar[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome] -
                         state.dataHeatBal.SurfQRadSWOutIncident[DiffSurf] * state.dataSurface.Surface[DiffSurf].Area +
                         QRefl * (1.0 - state.dataDaylightingDevicesData.TDDPipe[PipeNum].TransSolIso / transDiff) +
                         state.dataHeatBal.SurfWinQRadSWwinAbs[state.dataDaylightingDevicesData.TDDPipe[PipeNum].Dome, 0] *
                             state.dataSurface.Surface[DiffSurf].Area / 2.0 +
                         state.dataHeatBal.SurfWinQRadSWwinAbs[DiffSurf, 0] * state.dataSurface.Surface[DiffSurf].Area / 2.0)
        
        state.dataDaylightingDevicesData.TDDPipe[PipeNum].PipeAbsorbedSolar = max(0.0, TotTDDPipeGain)

        for TZoneNum in range(state.dataDaylightingDevicesData.TDDPipe[PipeNum].NumOfTZones):
            state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneHeatGain[TZoneNum] = (
                TotTDDPipeGain * (state.dataDaylightingDevicesData.TDDPipe[PipeNum].TZoneLength[TZoneNum] /
                                 state.dataDaylightingDevicesData.TDDPipe[PipeNum].TotLength))


def calc_view_factor_to_shelf(state: 'EnergyPlusData', ShelfNum: int) -> None:
    """Attempts to calculate exact analytical view factor from window to outside shelf."""
    
    W = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].Window].Width
    H = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].Window].Height

    if state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf].Width == W:
        L = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf].Height
    elif state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf].Height == W:
        L = state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf].Width
    else:
        show_fatal_error(state,
                        f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Width of window and outside shelf do not match.")

    NumMatch = 0
    for VWin in range(4):
        for VShelf in range(4):
            if (distance(state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].Window].Vertex[VWin],
                        state.dataSurface.Surface[state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf].Vertex[VShelf]) == 0.0):
                NumMatch += 1

    if NumMatch < 2:
        show_warning_error(state,
                          f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Window and outside shelf must share two vertices. View factor calculation may be inaccurate.")
    elif NumMatch > 2:
        show_fatal_error(state,
                        f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Window and outside shelf share too many vertices.")

    M = H / W
    N = L / W

    E1 = M * math.atan(1.0 / M) + N * math.atan(1.0 / N) - math.sqrt(N*N + M*M) * math.atan(1.0 / math.sqrt(N*N + M*M))
    E2 = ((1.0 + M*M) * (1.0 + N*N)) / (1.0 + M*M + N*N)
    E3 = ((M*M * (1.0 + M*M + N*N)) / ((1.0 + M*M) * (M*M + N*N))) ** M
    E4 = ((N*N * (1.0 + M*M + N*N)) / ((1.0 + N*N) * (M*M + N*N))) ** N

    state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor = (1.0 / (Constant.Pi * M)) * (E1 + 0.25 * math.log(E2 * E3 * E4))


def adjust_view_factors_with_shelf(state: 'EnergyPlusData', viewFactorToShelf: float,
                                   viewFactorToSky: float, viewFactorToGround: float,
                                   WinSurf: int, ShelfNum: int) -> None:
    """Adjusts view factors when a shelf is present."""
    
    if viewFactorToSky <= 0.0:
        viewFactorToSky = 0.0
    if viewFactorToGround <= 0.0:
        viewFactorToGround = 0.0
    
    if viewFactorToShelf <= 0.0:
        show_warning_error(state, f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Window view factor to shelf was less than 0. This should not happen.")
        show_continue_error(state, "The view factor has been reset to zero.")
        viewFactorToShelf = 0.0
        if (viewFactorToGround + viewFactorToSky) > 1.0:
            viewFactorToGround = viewFactorToGround / (viewFactorToGround + viewFactorToSky)
            viewFactorToSky = 1.0 - viewFactorToGround
            show_warning_error(state, f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: The sum of the window view factors to ground and sky were greater than 1. This should not happen.")
            show_continue_error(state, "The view factors have been reset to so that they do not exceed 1. Check/fix your input file data to avoid this issue.")
        return
    
    if viewFactorToShelf + viewFactorToSky + viewFactorToGround <= 1.0:
        return
    
    if viewFactorToShelf >= 1.0:
        show_warning_error(state, f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Window view factor to shelf was greater than 1. This should not happen.")
        show_continue_error(state, "The view factor has been reset to 1 and the other view factors to sky and ground have been set to 0.")
        viewFactorToShelf = 1.0
        viewFactorToGround = 0.0
        viewFactorToSky = 0.0
        return

    ShelfSurf = state.dataDaylightingDevicesData.Shelf[ShelfNum].OutSurf
    zShelfMax = state.dataSurface.Surface[ShelfSurf].Vertex[0].z
    zShelfMin = zShelfMax
    for vertex in range(1, state.dataSurface.Surface[ShelfSurf].Sides):
        if state.dataSurface.Surface[ShelfSurf].Vertex[vertex].z > zShelfMax:
            zShelfMax = state.dataSurface.Surface[ShelfSurf].Vertex[vertex].z
        if state.dataSurface.Surface[ShelfSurf].Vertex[vertex].z < zShelfMin:
            zShelfMin = state.dataSurface.Surface[ShelfSurf].Vertex[vertex].z
    
    zWinMax = state.dataSurface.Surface[WinSurf].Vertex[0].z
    zWinMin = zWinMax
    for vertex in range(1, state.dataSurface.Surface[WinSurf].Sides):
        if state.dataSurface.Surface[WinSurf].Vertex[vertex].z > zWinMax:
            zWinMax = state.dataSurface.Surface[WinSurf].Vertex[vertex].z
        if state.dataSurface.Surface[WinSurf].Vertex[vertex].z < zWinMin:
            zWinMin = state.dataSurface.Surface[WinSurf].Vertex[vertex].z

    leftoverViewFactor = 0.0
    show_warning_error(state, f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: Window view factor to shelf [{state.dataDaylightingDevicesData.Shelf[ShelfNum].ViewFactor:.2f}] results in a sum of view factors greater than 1.")
    
    if zWinMin >= zShelfMax:
        show_continue_error(state, "Since the light shelf is below the window to which it is associated, the view factor of the window to the ground was reduced")
        show_continue_error(state, "and possibly also the view factor to the sky. Check you input and/or consider turning off autosizing of the view factors.")
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
        show_continue_error(state, "Since the light shelf is above the window to which it is associated, the view factor of the window to the sky was reduced")
        show_continue_error(state, "and possibly also the view factor to the ground. Check you input and/or consider turning off autosizing of the view factors.")
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
        show_continue_error(state, "Since the light shelf is neither fully above or fully below the window to which it is associated, the view factor of the window")
        show_continue_error(state, "to the ground and sky were both potentially reduced. Check you input and/or consider turning off autosizing of the view factors.")
        
        zShelfAvg = 0.0
        if ((zShelfMin >= zWinMin and zShelfMax <= zWinMax) or
            (zShelfMin < zWinMin and zShelfMax > zWinMax)):
            zShelfAvg = 0.5 * (zShelfMin + zShelfMax)
        elif zShelfMin < zWinMin:
            fracAbove = 0.0
            if zShelfMax > zShelfMin:
                fracAbove = (zShelfMax - zWinMin) / (zShelfMax - zShelfMin)
                if fracAbove > 1.0:
                    fracAbove = 1.0
            zShelfAvg = zWinMin + fracAbove * (zShelfMax - zWinMin)
        else:
            fracBelow = 0.0
            if zShelfMax > zShelfMin:
                fracBelow = (zWinMax - zShelfMin) / (zShelfMax - zShelfMin)
            zShelfAvg = zWinMax - fracBelow * (zWinMax - zShelfMin)

        heightRatio = 0.0
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
        vfGroundAdjustMax = 0.0
        vfGroundAdjustMin = 0.0
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

    show_warning_error(state, f"DaylightingDevice:Shelf = {state.dataDaylightingDevicesData.Shelf[ShelfNum].Name}: As a result of user input (see previous messages), at least one view factor but possibly more than one was reduced.")
    show_continue_error(state, "These include the view factors to the ground, the sky, and the exterior light shelf. Note that views to other exterior surfaces could further complicated this.")
    show_continue_error(state, "Please consider manually calculating or adjusting view factors to avoid this problem.")


def figure_tdd_zone_gains(state: 'EnergyPlusData') -> None:
    """Initialize zone gains at begin new environment."""
    
    if len(state.dataDaylightingDevicesData.TDDPipe) == 0:
        return

    if state.dataGlobal.BeginEnvrnFlag and state.dataDaylightingDevices.MyEnvrnFlag:
        for Loop in range(len(state.dataDaylightingDevicesData.TDDPipe)):
            state.dataDaylightingDevicesData.TDDPipe[Loop].TZoneHeatGain = [0.0] * state.dataDaylightingDevicesData.TDDPipe[Loop].NumOfTZones
        state.dataDaylightingDevices.MyEnvrnFlag = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataDaylightingDevices.MyEnvrnFlag = True


def display_string(state: 'EnergyPlusData', msg: str) -> None:
    """Display a string message."""
    print(msg)


def show_severe_error(state: 'EnergyPlusData', msg: str) -> None:
    """Show a severe error message."""
    print(f"** Severe **: {msg}")


def show_warning_error(state: 'EnergyPlusData', msg: str) -> None:
    """Show a warning error message."""
    print(f"** Warning **: {msg}")


def show_continue_error(state: 'EnergyPlusData', msg: str) -> None:
    """Show a continuation error message."""
    print(f"   >>>  {msg}")


def show_fatal_error(state: 'EnergyPlusData', msg: str) -> None:
    """Show a fatal error message and exit."""
    print(f"** Fatal **: {msg}")
    raise RuntimeError(msg)


def print_eio(state: 'EnergyPlusData', msg: str) -> None:
    """Print to EIO file."""
    if hasattr(state.files, 'eio'):
        state.files.eio.write(msg)


def setup_zone_internal_gain(state: 'EnergyPlusData', zone: int, name: str, gain_type: int, gain_val: Any) -> None:
    """Setup an internal heat gain for a zone."""
    pass


def setup_output_variable(state: 'EnergyPlusData', var_name: str, var_ref: Any, obj_name: str) -> None:
    """Setup an output variable."""
    pass


def get_num_objects_found(state: 'EnergyPlusData', obj_type: str) -> int:
    """Get number of objects of specified type."""
    return 0


def get_object_item(state: 'EnergyPlusData', obj_type: str, obj_index: int,
                    alpha_args: list, numeric_args: list, blank_flags: list) -> None:
    """Get an input object item."""
    pass


def find_item_in_list(name: str, list_obj: Any) -> int:
    """Find an item in a list by name."""
    return 0


def safe_divide(num: float, denom: float) -> float:
    """Safely divide with zero protection."""
    if denom != 0:
        return num / denom
    return 0.0


def distance(v1: Any, v2: Any) -> float:
    """Calculate distance between two vertices."""
    return 0.0


def polyf(x: float, coeffs: list) -> float:
    """Evaluate a polynomial using coefficients."""
    result = 0.0
    for coeff in coeffs:
        result = result * x + coeff
    return result


def find_array_index(val: float, arr: list) -> int:
    """Find the index in an array where value would be inserted."""
    for i in range(len(arr) - 1):
        if val >= arr[i] and val <= arr[i + 1]:
            return i
    return 0


def illums_default() -> Any:
    """Create default Illums object."""
    return None
