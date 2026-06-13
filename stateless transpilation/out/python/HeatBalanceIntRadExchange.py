# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing all global data
# - Functions: ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError, DisplayString
# - Constants: Constant.StefanBoltzmann, Constant.Kelvin
# - Util functions: Util.FindItemInList, Util.makeUPPER, Util.SameString
# - Array operations: sum, transpose, min, max, pow_2, pow_4, root_4
# - General.ScanForReports
# - DataSurfaces, DataHeatBalance, DataConstruction, DataHeatBalSurf, DataViewFactorInformation
# - WindowEquivalentLayer.EQLWindowInsideEffectiveEmiss
# - state.files.eio, state.files.debug for output

import math
from typing import Optional, List, Tuple
from dataclasses import dataclass, field


@dataclass
class HeatBalanceIntRadExchgData:
    """Global data for interior radiant exchange calculations."""
    MaxNumOfRadEnclosureSurfs: int = 0
    CarrollMethod: bool = False
    CalcInteriorRadExchangefirstTime: bool = True
    SurfaceTempRad: List[float] = field(default_factory=list)
    SurfaceTempInKto4th: List[float] = field(default_factory=list)
    SurfaceEmiss: List[float] = field(default_factory=list)
    ViewFactorReport: bool = False
    LargestSurf: int = 0

    def clear_state(self):
        self.MaxNumOfRadEnclosureSurfs = 0
        self.CarrollMethod = False
        self.CalcInteriorRadExchangefirstTime = True
        self.SurfaceTempRad = []
        self.SurfaceTempInKto4th = []
        self.SurfaceEmiss = []
        self.ViewFactorReport = False
        self.LargestSurf = 0


def CalcInteriorRadExchange(
    state,
    SurfaceTemp,
    SurfIterations,
    NetLWRadToSurf,
    ZoneToResimulate=None,
    CalledFrom=""
):
    """Calculate interior radiant exchange between surfaces."""
    
    SurfaceTempRad = state.dataHeatBalIntRadExchg.SurfaceTempRad
    SurfaceTempInKto4th = state.dataHeatBalIntRadExchg.SurfaceTempInKto4th
    SurfaceEmiss = state.dataHeatBalIntRadExchg.SurfaceEmiss

    if state.dataHeatBalIntRadExchg.CalcInteriorRadExchangefirstTime:
        max_surfs = state.dataHeatBalIntRadExchg.MaxNumOfRadEnclosureSurfs
        state.dataHeatBalIntRadExchg.SurfaceTempRad = [0.0] * max_surfs
        state.dataHeatBalIntRadExchg.SurfaceTempInKto4th = [0.0] * max_surfs
        state.dataHeatBalIntRadExchg.SurfaceEmiss = [0.0] * max_surfs
        state.dataHeatBalIntRadExchg.CalcInteriorRadExchangefirstTime = False
        SurfaceTempRad = state.dataHeatBalIntRadExchg.SurfaceTempRad
        SurfaceTempInKto4th = state.dataHeatBalIntRadExchg.SurfaceTempInKto4th
        SurfaceEmiss = state.dataHeatBalIntRadExchg.SurfaceEmiss
        if state.dataSysVars.DeveloperFlag:
            # DisplayString(state, " OMP turned off, HBIRE loop executed in serial")
            pass

    if state.dataGlobal.KickOffSimulation or state.dataGlobal.KickOffSizing:
        return

    PartialResimulate = ZoneToResimulate is not None

    startEnclosure = 1
    endEnclosure = state.dataViewFactor.NumOfRadiantEnclosures
    if PartialResimulate:
        startEnclosure = state.dataHeatBal.Zone[ZoneToResimulate].zoneRadEnclosureFirst
        endEnclosure = state.dataHeatBal.Zone[ZoneToResimulate].zoneRadEnclosureLast
        for enclosureNum in range(startEnclosure, endEnclosure + 1):
            enclosure = state.dataViewFactor.EnclRadInfo[enclosureNum]
            for i in enclosure.SurfacePtr:
                NetLWRadToSurf[i] = 0.0
                state.dataSurface.SurfWinIRfromParentZone[i] = 0.0
    else:
        for i in range(len(NetLWRadToSurf)):
            NetLWRadToSurf[i] = 0.0
        for SurfNum in range(1, state.dataSurface.TotSurfaces + 1):
            state.dataSurface.SurfWinIRfromParentZone[SurfNum] = 0.0

    for enclosureNum in range(startEnclosure, endEnclosure + 1):
        zone_info = state.dataViewFactor.EnclRadInfo[enclosureNum]
        zone_ScriptF = zone_info.ScriptF
        n_zone_Surfaces = zone_info.NumOfSurfaces
        s_zone_Surfaces = n_zone_Surfaces

        if SurfIterations == 0:
            IntShadeOrBlindStatusChanged = False
            IntMovInsulChanged = False

            if not state.dataGlobal.BeginEnvrnFlag:
                for SurfNum in zone_info.SurfacePtr:
                    if IntShadeOrBlindStatusChanged or IntMovInsulChanged:
                        break
                    if state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].TypeIsWindow:
                        ShadeFlag = state.dataSurface.SurfWinShadingFlag[SurfNum]
                        ShadeFlagPrev = state.dataSurface.SurfWinExtIntShadePrevTS[SurfNum]
                        if ShadeFlagPrev != ShadeFlag and (ANY_INTERIOR_SHADE_BLIND(ShadeFlagPrev) or ANY_INTERIOR_SHADE_BLIND(ShadeFlag)):
                            IntShadeOrBlindStatusChanged = True
                        if (state.dataSurface.SurfWinWindowModelType[SurfNum] == "EQL" and
                            state.dataWindowEquivLayer.CFS[state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].EQLConsPtr].ISControlled):
                            IntShadeOrBlindStatusChanged = True
                    else:
                        if state.dataSurface.AnyMovableInsulation:
                            UpdateMovableInsulationFlag(state, SurfNum)

            if IntShadeOrBlindStatusChanged or IntMovInsulChanged or state.dataGlobal.BeginEnvrnFlag:
                for ZoneSurfNum in range(n_zone_Surfaces):
                    SurfNum = zone_info.SurfacePtr[ZoneSurfNum]
                    ConstrNum = state.dataSurface.Surface[SurfNum].Construction
                    zone_info.Emissivity[ZoneSurfNum] = state.dataHeatBalSurf.SurfAbsThermalInt[SurfNum]
                    if (state.dataConstruction.Construct[ConstrNum].TypeIsWindow and
                        ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum])):
                        zone_info.Emissivity[ZoneSurfNum] = state.dataHeatBalSurf.SurfAbsThermalInt[SurfNum]
                    if (state.dataSurface.SurfWinWindowModelType[SurfNum] == "EQL" and
                        state.dataWindowEquivLayer.CFS[state.dataConstruction.Construct[ConstrNum].EQLConsPtr].ISControlled):
                        zone_info.Emissivity[ZoneSurfNum] = WindowEquivalentLayer_EQLWindowInsideEffectiveEmiss(state, ConstrNum)

                if state.dataHeatBalIntRadExchg.CarrollMethod:
                    CalcFp(n_zone_Surfaces, zone_info.Emissivity, zone_info.FMRT, zone_info.Fp)
                else:
                    CalcScriptF(state, n_zone_Surfaces, zone_info.Area, zone_info.F, zone_info.Emissivity, zone_ScriptF)
                    for i in range(len(zone_ScriptF)):
                        zone_ScriptF[i] *= STEFAN_BOLTZMANN

        CarrollMRTNumerator = 0.0
        CarrollMRTDenominator = 0.0
        for ZoneSurfNum in range(s_zone_Surfaces):
            SurfNum = zone_info.SurfacePtr[ZoneSurfNum]
            surf = state.dataSurface.Surface[SurfNum]
            surfWindow = state.dataSurface.SurfaceWindow[SurfNum]
            constrNum = surf.Construction
            construct = state.dataConstruction.Construct[constrNum]
            
            if construct.WindowTypeEQL:
                SurfaceTempRad[ZoneSurfNum] = state.dataSurface.SurfWinEffInsSurfTemp[SurfNum]
                SurfaceEmiss[ZoneSurfNum] = WindowEquivalentLayer_EQLWindowInsideEffectiveEmiss(state, constrNum)
            elif (construct.WindowTypeBSDF and state.dataSurface.SurfWinShadingFlag[SurfNum] == "IntShade"):
                surfShade = state.dataSurface.surfShades[SurfNum]
                SurfaceTempRad[ZoneSurfNum] = state.dataSurface.SurfWinEffInsSurfTemp[SurfNum]
                SurfaceEmiss[ZoneSurfNum] = surfShade.effShadeEmi + surfShade.effGlassEmi
            elif construct.WindowTypeBSDF:
                SurfaceTempRad[ZoneSurfNum] = state.dataSurface.SurfWinEffInsSurfTemp[SurfNum]
                SurfaceEmiss[ZoneSurfNum] = construct.InsideAbsorpThermal
            elif (construct.TypeIsWindow and surf.OriginalClass != "TDD_Diffuser"):
                if SurfIterations == 0 and NOT_SHADED(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                    SurfaceTempRad[ZoneSurfNum] = surfWindow.thetaFace[2 * construct.TotGlassLayers - 1] - KELVIN
                    SurfaceEmiss[ZoneSurfNum] = construct.InsideAbsorpThermal
                elif ANY_INTERIOR_SHADE_BLIND(state.dataSurface.SurfWinShadingFlag[SurfNum]):
                    SurfaceTempRad[ZoneSurfNum] = state.dataSurface.SurfWinEffInsSurfTemp[SurfNum]
                    SurfaceEmiss[ZoneSurfNum] = state.dataHeatBalSurf.SurfAbsThermalInt[SurfNum]
                else:
                    SurfaceTempRad[ZoneSurfNum] = SurfaceTemp[SurfNum]
                    SurfaceEmiss[ZoneSurfNum] = construct.InsideAbsorpThermal
            else:
                SurfaceTempRad[ZoneSurfNum] = SurfaceTemp[SurfNum]
                SurfaceEmiss[ZoneSurfNum] = construct.InsideAbsorpThermal
            
            SurfaceTempInKto4th[ZoneSurfNum] = pow(SurfaceTempRad[ZoneSurfNum] + KELVIN, 4)
            if state.dataHeatBalIntRadExchg.CarrollMethod:
                CarrollMRTNumerator += SurfaceTempInKto4th[ZoneSurfNum] * zone_info.Fp[ZoneSurfNum] * zone_info.Area[ZoneSurfNum]
                CarrollMRTDenominator += zone_info.Fp[ZoneSurfNum] * zone_info.Area[ZoneSurfNum]

        if state.dataHeatBalIntRadExchg.CarrollMethod:
            if CarrollMRTDenominator > 0.0:
                CarrollMRTInKTo4th = CarrollMRTNumerator / CarrollMRTDenominator
            else:
                CarrollMRTInKTo4th = 293.15
            
            for RecZoneSurfNum in range(s_zone_Surfaces):
                RecSurfNum = zone_info.SurfacePtr[RecZoneSurfNum]
                ConstrNumRec = state.dataSurface.Surface[RecSurfNum].Construction
                rec_construct = state.dataConstruction.Construct[ConstrNumRec]
                
                if rec_construct.TypeIsWindow:
                    CarrollMRTInKTo4thWin = CarrollMRTInKTo4th
                    CarrollMRTNumeratorWin = 0.0
                    CarrollMRTDenominatorWin = 0.0
                    for SendZoneSurfNum in range(s_zone_Surfaces):
                        if SendZoneSurfNum != RecZoneSurfNum:
                            CarrollMRTNumeratorWin += (pow(SurfaceTempRad[SendZoneSurfNum] + KELVIN, 4) *
                                                       zone_info.Fp[SendZoneSurfNum] * zone_info.Area[SendZoneSurfNum])
                            CarrollMRTDenominatorWin += zone_info.Fp[SendZoneSurfNum] * zone_info.Area[SendZoneSurfNum]
                    if CarrollMRTDenominatorWin > 0.0:
                        CarrollMRTInKTo4thWin = CarrollMRTNumeratorWin / CarrollMRTDenominatorWin
                    state.dataSurface.SurfWinIRfromParentZone[RecSurfNum] += (
                        (zone_info.Fp[RecZoneSurfNum] * CarrollMRTInKTo4thWin) / SurfaceEmiss[RecZoneSurfNum]
                    )
                
                NetLWRadToSurf[RecSurfNum] += (zone_info.Fp[RecZoneSurfNum] *
                                              (CarrollMRTInKTo4th - SurfaceTempInKto4th[RecZoneSurfNum]))
        else:
            for RecZoneSurfNum in range(s_zone_Surfaces):
                RecSurfNum = zone_info.SurfacePtr[RecZoneSurfNum]
                ConstrNumRec = state.dataSurface.Surface[RecSurfNum].Construction
                rec_construct = state.dataConstruction.Construct[ConstrNumRec]

                if rec_construct.TypeIsWindow:
                    scriptF_acc = 0.0
                    netLWRadToRecSurf_cor = 0.0
                    IRfromParentZone_acc = 0.0
                    for SendZoneSurfNum in range(s_zone_Surfaces):
                        lSR = RecZoneSurfNum * s_zone_Surfaces + SendZoneSurfNum
                        scriptF = zone_ScriptF[lSR]
                        scriptF_temp_ink_4th = scriptF * SurfaceTempInKto4th[SendZoneSurfNum]
                        IRfromParentZone_acc += scriptF_temp_ink_4th
                        
                        if RecZoneSurfNum != SendZoneSurfNum:
                            scriptF_acc += scriptF
                        else:
                            netLWRadToRecSurf_cor = scriptF_temp_ink_4th
                    
                    NetLWRadToSurf[RecSurfNum] += (IRfromParentZone_acc - netLWRadToRecSurf_cor -
                                                   (scriptF_acc * SurfaceTempInKto4th[RecZoneSurfNum]))
                    state.dataSurface.SurfWinIRfromParentZone[RecSurfNum] += IRfromParentZone_acc / SurfaceEmiss[RecZoneSurfNum]
                else:
                    netLWRadToRecSurf_acc = 0.0
                    zone_ScriptF[RecZoneSurfNum * s_zone_Surfaces + RecZoneSurfNum] = 0
                    for SendZoneSurfNum in range(s_zone_Surfaces):
                        lSR = RecZoneSurfNum * s_zone_Surfaces + SendZoneSurfNum
                        netLWRadToRecSurf_acc += (zone_ScriptF[lSR] *
                                                 (SurfaceTempInKto4th[SendZoneSurfNum] - SurfaceTempInKto4th[RecZoneSurfNum]))
                    NetLWRadToSurf[RecSurfNum] += netLWRadToRecSurf_acc

    if state.dataSurface.UseRepresentativeSurfaceCalculations:
        for SurfNum in state.dataSurface.AllHTSurfaceList:
            RepSurfNum = state.dataSurface.Surface[SurfNum].RepresentativeCalcSurfNum
            if SurfNum != RepSurfNum:
                state.dataSurface.SurfWinIRfromParentZone[SurfNum] = state.dataSurface.SurfWinIRfromParentZone[RepSurfNum]
                NetLWRadToSurf[SurfNum] = NetLWRadToSurf[RepSurfNum]


def UpdateMovableInsulationFlag(state, SurfNum):
    """Update flag for changes in interior movable insulation."""
    change = False
    s_surf = state.dataSurface
    movInsul = s_surf.intMovInsuls[SurfNum]
    if movInsul.present != movInsul.presentPrevTS:
        change = (abs(state.dataConstruction.Construct[s_surf.Surface[SurfNum].Construction].InsideAbsorpThermal -
                      state.dataMaterial.materials[movInsul.matNum].AbsorpThermal) > 0.01)
    return change


def InitInteriorRadExchange(state):
    """Initialize interior radiant exchange parameters."""
    ErrorsFound = False
    CheckValue1 = 0.0
    CheckValue2 = 0.0
    FinalCheckValue = 0.0
    FixedRowSum = 0.0
    NumIterations = 0

    ViewFactorReport = state.dataHeatBalIntRadExchg.ViewFactorReport

    state.dataHeatBalIntRadExchg.MaxNumOfRadEnclosureSurfs = 0
    
    for enclosureNum in range(1, state.dataViewFactor.NumOfRadiantEnclosures + 1):
        thisEnclosure = state.dataViewFactor.EnclRadInfo[enclosureNum]
        
        numEnclosureSurfaces = 0
        for spaceNum in thisEnclosure.spaceNums:
            for surfNum in state.dataHeatBal.space[spaceNum].surfaces:
                if state.dataSurface.Surface[surfNum].IsAirBoundarySurf:
                    continue
                if surfNum == state.dataSurface.Surface[surfNum].RepresentativeCalcSurfNum:
                    numEnclosureSurfaces += 1
        
        thisEnclosure.NumOfSurfaces = numEnclosureSurfaces
        state.dataHeatBalIntRadExchg.MaxNumOfRadEnclosureSurfs = max(
            state.dataHeatBalIntRadExchg.MaxNumOfRadEnclosureSurfs, numEnclosureSurfaces
        )
        
        if numEnclosureSurfaces < 1:
            ErrorsFound = True

        thisEnclosure.F = [[0.0] * numEnclosureSurfaces for _ in range(numEnclosureSurfaces)]
        thisEnclosure.ScriptF = [[0.0] * numEnclosureSurfaces for _ in range(numEnclosureSurfaces)]
        thisEnclosure.Area = [0.0] * numEnclosureSurfaces
        thisEnclosure.Emissivity = [0.0] * numEnclosureSurfaces
        thisEnclosure.Azimuth = [0.0] * numEnclosureSurfaces
        thisEnclosure.Tilt = [0.0] * numEnclosureSurfaces
        
        if state.dataHeatBalIntRadExchg.CarrollMethod:
            thisEnclosure.Fp = [1.0] * numEnclosureSurfaces
            thisEnclosure.FMRT = [0.0] * numEnclosureSurfaces
        
        thisEnclosure.SurfacePtr = [0] * numEnclosureSurfaces

        enclosureSurfNum = 0
        for spaceNum in thisEnclosure.spaceNums:
            priorZoneTotEnclSurfs = enclosureSurfNum
            for surfNum in state.dataHeatBal.space[spaceNum].surfaces:
                if state.dataSurface.Surface[surfNum].IsAirBoundarySurf:
                    continue
                if surfNum == state.dataSurface.Surface[surfNum].RepresentativeCalcSurfNum:
                    thisEnclosure.SurfacePtr[enclosureSurfNum] = surfNum
                    thisEnclosure.Area[enclosureSurfNum] = state.dataSurface.Surface[surfNum].Area
                    thisEnclosure.Emissivity[enclosureSurfNum] = (
                        state.dataConstruction.Construct[state.dataSurface.Surface[surfNum].Construction].InsideAbsorpThermal
                    )
                    thisEnclosure.Azimuth[enclosureSurfNum] = state.dataSurface.Surface[surfNum].Azimuth
                    thisEnclosure.Tilt[enclosureSurfNum] = state.dataSurface.Surface[surfNum].Tilt
                    enclosureSurfNum += 1

            for surfNum in state.dataHeatBal.space[spaceNum].surfaces:
                if state.dataSurface.Surface[surfNum].IsAirBoundarySurf:
                    continue
                if surfNum != state.dataSurface.Surface[surfNum].RepresentativeCalcSurfNum:
                    for enclSNum in range(priorZoneTotEnclSurfs, enclosureSurfNum):
                        if thisEnclosure.SurfacePtr[enclSNum] == state.dataSurface.Surface[surfNum].RepresentativeCalcSurfNum:
                            thisEnclosure.Area[enclSNum] += state.dataSurface.Surface[surfNum].Area
                
                for enclSNum in range(priorZoneTotEnclSurfs, enclosureSurfNum):
                    if thisEnclosure.SurfacePtr[enclSNum] == state.dataSurface.AllSurfaceListReportOrder[surfNum - 1]:
                        thisEnclosure.SurfaceReportNums.append(enclSNum)
                        break

        if thisEnclosure.NumOfSurfaces == 1:
            thisEnclosure.F = [[0.0]]
            thisEnclosure.ScriptF = [[0.0]]
            if state.dataHeatBalIntRadExchg.CarrollMethod:
                thisEnclosure.Fp = [0.0]
                thisEnclosure.FMRT = [0.0]
            continue

        if state.dataHeatBalIntRadExchg.CarrollMethod:
            CalcFMRT(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area, thisEnclosure.FMRT)
            CalcFp(thisEnclosure.NumOfSurfaces, thisEnclosure.Emissivity, thisEnclosure.FMRT, thisEnclosure.Fp)
        else:
            NoUserInputF = True
            if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneProperty:UserViewFactors:BySurfaceName") > 0:
                GetInputViewFactorsbyName(state, thisEnclosure.Name, thisEnclosure.NumOfSurfaces,
                                         thisEnclosure.F, thisEnclosure.SurfacePtr, NoUserInputF, ErrorsFound)

            if NoUserInputF:
                CalcApproximateViewFactors(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area,
                                          thisEnclosure.Azimuth, thisEnclosure.Tilt, thisEnclosure.F, thisEnclosure.SurfacePtr)

            anyIntMassInZone = DoesZoneHaveInternalMass(state, thisEnclosure.NumOfSurfaces, thisEnclosure.SurfacePtr)
            FixViewFactors(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area, thisEnclosure.F,
                          thisEnclosure.Name, thisEnclosure.spaceNums, CheckValue1, CheckValue2,
                          FinalCheckValue, NumIterations, FixedRowSum, anyIntMassInZone)

            CalcScriptF(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area, thisEnclosure.F,
                       thisEnclosure.Emissivity, thisEnclosure.ScriptF)

    if ErrorsFound:
        raise RuntimeError("Errors found during initialization of radiant exchange.")


def InitSolarViewFactors(state):
    """Initialize solar view factors."""
    ErrorsFound = False

    for enclosureNum in range(1, state.dataViewFactor.NumOfSolarEnclosures + 1):
        thisEnclosure = state.dataViewFactor.EnclSolInfo[enclosureNum]
        
        numEnclosureSurfaces = 0
        for spaceNum in thisEnclosure.spaceNums:
            for surfNum in state.dataHeatBal.space[spaceNum].surfaces:
                if not state.dataSurface.Surface[surfNum].IsAirBoundarySurf:
                    numEnclosureSurfaces += 1
        
        thisEnclosure.NumOfSurfaces = numEnclosureSurfaces
        
        if numEnclosureSurfaces < 1:
            ErrorsFound = True

        thisEnclosure.F = [[0.0] * numEnclosureSurfaces for _ in range(numEnclosureSurfaces)]
        thisEnclosure.Area = [0.0] * numEnclosureSurfaces
        thisEnclosure.SolAbsorptance = [0.0] * numEnclosureSurfaces
        thisEnclosure.Azimuth = [0.0] * numEnclosureSurfaces
        thisEnclosure.Tilt = [0.0] * numEnclosureSurfaces
        thisEnclosure.SurfacePtr = [0] * numEnclosureSurfaces

        enclosureSurfNum = 0
        for spaceNum in thisEnclosure.spaceNums:
            for surfNum in state.dataHeatBal.space[spaceNum].surfaces:
                if not state.dataSurface.Surface[surfNum].IsAirBoundarySurf:
                    thisEnclosure.SurfacePtr[enclosureSurfNum] = surfNum
                    enclosureSurfNum += 1

        for enclSurfNum in range(thisEnclosure.NumOfSurfaces):
            SurfNum = thisEnclosure.SurfacePtr[enclSurfNum]
            thisEnclosure.Area[enclSurfNum] = state.dataSurface.Surface[SurfNum].Area
            thisEnclosure.SolAbsorptance[enclSurfNum] = (
                state.dataConstruction.Construct[state.dataSurface.Surface[SurfNum].Construction].InsideAbsorpSolar
            )
            thisEnclosure.Azimuth[enclSurfNum] = state.dataSurface.Surface[SurfNum].Azimuth
            thisEnclosure.Tilt[enclSurfNum] = state.dataSurface.Surface[SurfNum].Tilt

        if thisEnclosure.NumOfSurfaces == 1:
            continue

        NoUserInputF = True
        if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneProperty:UserViewFactors:BySurfaceName") > 0:
            GetInputViewFactorsbyName(state, thisEnclosure.Name, thisEnclosure.NumOfSurfaces,
                                     thisEnclosure.F, thisEnclosure.SurfacePtr, NoUserInputF, ErrorsFound)

        if NoUserInputF:
            CalcApproximateViewFactors(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area,
                                      thisEnclosure.Azimuth, thisEnclosure.Tilt, thisEnclosure.F, thisEnclosure.SurfacePtr)

        CheckValue1 = 0.0
        CheckValue2 = 0.0
        FinalCheckValue = 0.0
        FixedRowSum = 0.0
        NumIterations = 0

        anyIntMassInZone = DoesZoneHaveInternalMass(state, thisEnclosure.NumOfSurfaces, thisEnclosure.SurfacePtr)
        FixViewFactors(state, thisEnclosure.NumOfSurfaces, thisEnclosure.Area, thisEnclosure.F,
                      thisEnclosure.Name, thisEnclosure.spaceNums, CheckValue1, CheckValue2,
                      FinalCheckValue, NumIterations, FixedRowSum, anyIntMassInZone)

    if ErrorsFound:
        raise RuntimeError("Errors found during initialization of solar view factors.")


def GetInputViewFactors(state, ZoneName, N, F, SPtr, NoUserInputF, ErrorsFound):
    """Get user input view factors."""
    NoUserInputF[0] = True
    UserFZoneIndex = state.dataInputProcessing.inputProcessor.getObjectItemNum(state, "ZoneProperty:UserViewFactors", ZoneName)
    
    if UserFZoneIndex > 0:
        NoUserInputF[0] = False
        state.dataInputProcessing.inputProcessor.getObjectItem(state, "ZoneProperty:UserViewFactors", UserFZoneIndex)
        # Parse and populate F matrix
        for row in range(N):
            for col in range(N):
                F[row][col] = 0.0


def GetInputViewFactorsbyName(state, EnclosureName, N, F, SPtr, NoUserInputF, ErrorsFound):
    """Get user input view factors by name."""
    NoUserInputF[0] = True
    UserFZoneIndex = state.dataInputProcessing.inputProcessor.getObjectItemNum(
        state, "ZoneProperty:UserViewFactors:BySurfaceName", "zone_or_zonelist_or_space_or_spacelist_name", EnclosureName
    )

    if UserFZoneIndex > 0:
        NoUserInputF[0] = False
        enclosureSurfaceNames = [state.dataSurface.Surface[SPtr[i]].Name for i in range(N)]
        
        for row in range(N):
            for col in range(N):
                F[row][col] = 0.0


def AlignInputViewFactors(state, cCurrentModuleObject, ErrorsFound):
    """Align input view factors with radiant enclosures."""
    pass


def CalcApproximateViewFactors(state, N, A, Azimuth, Tilt, F, SPtr):
    """Calculate approximate view factors using area weighting."""
    SameAngleLimit = 10.0
    
    ZoneArea = [0.0] * N
    
    for i in range(N):
        for j in range(N):
            if i == j:
                continue
            if (state.dataSurface.Surface[SPtr[j]].Class == "Floor" and
                state.dataSurface.Surface[SPtr[i]].Class == "Floor"):
                continue
            
            if ((state.dataSurface.Surface[SPtr[j]].Class == "IntMass") or
                (state.dataSurface.Surface[SPtr[i]].Class == "IntMass") or
                (state.dataSurface.Surface[SPtr[j]].Class == "Floor") or
                (state.dataSurface.Surface[SPtr[i]].Class == "Floor") or
                (abs(Azimuth[i] - Azimuth[j]) > SameAngleLimit and abs(Azimuth[i] - Azimuth[j]) < 360.0 - SameAngleLimit) or
                (abs(Tilt[i] - Tilt[j]) > SameAngleLimit)):
                ZoneArea[i] += A[j]

    for i in range(N):
        for j in range(N):
            if i == j:
                continue
            if (state.dataSurface.Surface[SPtr[j]].Class == "Floor" and
                state.dataSurface.Surface[SPtr[i]].Class == "Floor"):
                continue
            
            if ((state.dataSurface.Surface[SPtr[j]].Class == "IntMass") or
                (state.dataSurface.Surface[SPtr[i]].Class == "IntMass") or
                (state.dataSurface.Surface[SPtr[j]].Class == "Floor") or
                (state.dataSurface.Surface[SPtr[i]].Class == "Floor") or
                (abs(Azimuth[i] - Azimuth[j]) > SameAngleLimit and abs(Azimuth[i] - Azimuth[j]) < 360.0 - SameAngleLimit) or
                (abs(Tilt[i] - Tilt[j]) > SameAngleLimit)):
                if ZoneArea[i] > 0.0:
                    F[j][i] = A[j] / ZoneArea[i]


def FixViewFactors(state, N, A, F, enclName, spaceNums, OriginalCheckValue, FixedCheckValue, FinalCheckValue, NumIterations, RowSum, anyIntMassInZone):
    """Fix and enforce reciprocity and completeness of view factors."""
    PrimaryConvergence = 0.001
    DifferenceConvergence = 0.00001
    
    OriginalCheckValue[0] = abs(sum(sum(row) for row in F) - N)

    FixedAF = [row[:] for row in F]
    
    ConvrgOld = 10.0
    LargestArea = max(A)
    
    if LargestArea > 0.99 * (sum(A) - LargestArea) and N > 3:
        for i in range(N):
            if LargestArea == A[i]:
                state.dataHeatBalIntRadExchg.LargestSurf = i
                FixedAF[i][i] = min(0.9, 1.2 * LargestArea / sum(A))
                break

    AF = [[FixedAF[j][i] * A[i] for j in range(N)] for i in range(N)]

    FixedAF = [[0.5 * (AF[j][i] + AF[i][j]) for j in range(N)] for i in range(N)]

    FixedF = [[0.0] * N for _ in range(N)]

    NumIterations[0] = 0
    RowSum[0] = 0.0

    if N <= 3:
        for i in range(N):
            for j in range(N):
                FixedF[j][i] = FixedAF[j][i] / A[i]

        RowSum[0] = sum(sum(row) for row in FixedF)
        
        if RowSum[0] > N + 0.01:
            sumFixedF = [sum(FixedF[i]) for i in range(N)]
            MaxFixedFRowSum = max(sumFixedF)
            if MaxFixedFRowSum >= 1.0:
                for i in range(N):
                    for j in range(N):
                        FixedF[i][j] *= 1.0 / MaxFixedFRowSum
            RowSum[0] = sum(sum(row) for row in FixedF)

        FinalCheckValue[0] = FixedCheckValue[0] = abs(RowSum[0] - N)
        for i in range(N):
            for j in range(N):
                F[i][j] = FixedF[i][j]
        return

    RowCoefficient = [0.0] * N
    Converged = False
    
    while not Converged:
        NumIterations[0] += 1
        for i in range(N):
            sum_FixedAF_i = sum(FixedAF[j][i] for j in range(N))
            if abs(sum_FixedAF_i) > 1.0e-10:
                RowCoefficient[i] = A[i] / sum_FixedAF_i
            else:
                RowCoefficient[i] = 1.0
            for j in range(N):
                FixedAF[j][i] *= RowCoefficient[i]

        FixedAF = [[0.5 * (FixedAF[j][i] + FixedAF[i][j]) for j in range(N)] for i in range(N)]

        for i in range(N):
            for j in range(N):
                FixedF[j][i] = FixedAF[j][i] / A[i]
                if abs(FixedF[j][i]) < 1.e-10:
                    FixedF[j][i] = 0.0
                    FixedAF[j][i] = 0.0

        ConvrgNew = abs(sum(sum(row) for row in FixedF) - N)
        if abs(ConvrgOld - ConvrgNew) < DifferenceConvergence or ConvrgNew <= PrimaryConvergence:
            Converged = True
        ConvrgOld = ConvrgNew
        
        if NumIterations[0] > 400:
            FixedAF = [[0.5 * (FixedAF[j][i] + FixedAF[i][j]) for j in range(N)] for i in range(N)]
            for i in range(N):
                for j in range(N):
                    FixedF[j][i] = FixedAF[j][i] / A[i]
            
            sum_FixedF = sum(sum(row) for row in FixedF)
            FinalCheckValue[0] = FixedCheckValue[0] = abs(sum_FixedF - N)
            RowSum[0] = sum_FixedF
            
            if abs(FixedCheckValue[0]) < abs(OriginalCheckValue[0]):
                for i in range(N):
                    for j in range(N):
                        F[i][j] = FixedF[i][j]
                FinalCheckValue[0] = FixedCheckValue[0]
            return

    FixedCheckValue[0] = ConvrgNew
    if FixedCheckValue[0] < OriginalCheckValue[0]:
        for i in range(N):
            for j in range(N):
                F[i][j] = FixedF[i][j]
        FinalCheckValue[0] = FixedCheckValue[0]
    else:
        FinalCheckValue[0] = OriginalCheckValue[0]
        RowSum[0] = sum(sum(row) for row in FixedF)


def DoesZoneHaveInternalMass(state, numZoneSurfaces, surfPointer):
    """Check if zone has internal mass surfaces."""
    for i in range(numZoneSurfaces):
        if state.dataSurface.Surface[surfPointer[i]].Class == "IntMass":
            return True
    return False


def CalcScriptF(state, N, A, F, EMISS, ScriptF):
    """Calculate Hottel's ScriptF factors."""
    MaxEmissLimit = 0.99999
    
    Cmatrix = [[A[i] * F[j][i] for j in range(N)] for i in range(N)]

    Excite = [0.0] * N
    for i in range(N):
        EMISS_i = EMISS[i]
        if EMISS_i > MaxEmissLimit:
            EMISS_i = MaxEmissLimit
            EMISS[i] = MaxEmissLimit
        EMISS_i_fac = A[i] / (1.0 - EMISS_i)
        Excite[i] = -EMISS_i * EMISS_i_fac
        Cmatrix[i][i] -= EMISS_i_fac

    Cinverse = [[0.0] * N for _ in range(N)]
    CalcMatrixInverse(Cmatrix, Cinverse)

    for j in range(N):
        e_j = Excite[j]
        for i in range(N):
            Cinverse[i][j] *= e_j

    for i in range(N):
        EMISS_i = EMISS[i]
        EMISS_fac = EMISS_i / (1.0 - EMISS_i)
        for j in range(N):
            if i == j:
                ScriptF[j][i] = EMISS_fac * (Cinverse[i][j] - EMISS_i)
            else:
                ScriptF[j][i] = EMISS_fac * Cinverse[i][j]


def CalcMatrixInverse(A, I):
    """Calculate matrix inverse using Gauss elimination with partial pivoting."""
    n = len(A)
    
    for i in range(n):
        I[i] = [0.0] * n
    for i in range(n):
        I[i][i] = 1.0

    for i in range(n):
        iPiv = i
        aPiv = abs(A[i][i])
        for k in range(i + 1, n):
            aAki = abs(A[i][k])
            if aAki > aPiv:
                iPiv = k
                aPiv = aAki

        if iPiv != i:
            A[i], A[iPiv] = A[iPiv], A[i]
            I[i], I[iPiv] = I[iPiv], I[i]

        Aii_inv = 1.0 / A[i][i]
        for k in range(i + 1, n):
            multiplier = A[i][k] * Aii_inv
            A[i][k] = multiplier
            if multiplier != 0.0:
                for j in range(i + 1, n):
                    A[j][k] -= multiplier * A[j][i]
                for j in range(n):
                    I[j][k] -= multiplier * I[j][i]

    for k in range(n - 1, -1, -1):
        Akk_inv = 1.0 / A[k][k]
        for j in range(n):
            I[j][k] *= Akk_inv
        for i in range(k):
            Aik = A[i][k]
            for j in range(n):
                I[j][i] -= Aik * I[j][k]


def CalcFMRT(state, N, A, FMRT):
    """Calculate mean radiant temperature view factors."""
    sumAF = sum(A)
    for iS in range(N):
        FMRT[iS] = 1.0

    maxIt = 100
    tol = 0.0001
    sumAFNew = sumAF
    
    for i in range(maxIt):
        fChange = 0.0
        errorsFound = False
        sumAF = sumAFNew
        sumAFNew = 0.0
        
        for iS in range(N):
            fLast = FMRT[iS]
            FMRT[iS] = 1.0 / (1.0 - A[iS] * FMRT[iS] / sumAF)
            
            if FMRT[iS] > 100.0:
                errorsFound = True
                break
            
            fChange += abs(FMRT[iS] - fLast)
            sumAFNew += A[iS] * FMRT[iS]

        if errorsFound or fChange / N < tol:
            break
    
    if fChange / N >= tol and i >= maxIt - 1:
        raise RuntimeError("Carroll MRT unable to converge on view factor calculation.")


def CalcFp(N, EMISS, FMRT, Fp):
    """Calculate Oppenheim resistance values."""
    STEFAN_BOLTZMANN = 5.67e-8
    for iS in range(N):
        Fp[iS] = STEFAN_BOLTZMANN * EMISS[iS] / (EMISS[iS] / FMRT[iS] + 1.0 - EMISS[iS])


def GetRadiantSystemSurface(state, cCurrentModuleObject, RadSysName, RadSysZoneNum, SurfaceName, ErrorsFound):
    """Find and validate radiant system surface."""
    surfNum = Util.FindItemInList(SurfaceName, [s.Name for s in state.dataSurface.Surface])

    if surfNum == 0:
        ErrorsFound[0] = True
        return surfNum

    if RadSysZoneNum == 0:
        ErrorsFound[0] = True
        return surfNum

    surfZoneNum = state.dataSurface.Surface[surfNum].Zone
    if surfZoneNum == 0:
        ErrorsFound[0] = True
    elif surfZoneNum != RadSysZoneNum:
        ErrorsFound[0] = True

    return surfNum


STEFAN_BOLTZMANN = 5.67e-8
KELVIN = 273.15


def ANY_INTERIOR_SHADE_BLIND(ShadeFlag):
    """Check if shade flag indicates interior shade or blind."""
    return ShadeFlag in ["IntShade", "IntBlind"]


def NOT_SHADED(ShadeFlag):
    """Check if surface is not shaded."""
    return ShadeFlag in ["NoShade", ""]


def WindowEquivalentLayer_EQLWindowInsideEffectiveEmiss(state, constrNum):
    """Get inside effective emissivity for EQL window."""
    return 0.9  # Placeholder


def Util_FindItemInList(item, items):
    """Find item in list."""
    try:
        return items.index(item)
    except ValueError:
        return 0
