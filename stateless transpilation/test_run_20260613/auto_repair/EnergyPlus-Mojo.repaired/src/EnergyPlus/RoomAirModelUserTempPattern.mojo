# Mojo translation of RoomAirModelUserTempPattern.cc
# Faithful 1:1 translation, no refactoring.

from Data.BaseData import BaseGlobalStruct
from Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import state.dataEnvrn
from DataErrorTracking import state.dataErrTracking
from DataHVACGlobals import state.dataHVACGlobal
from DataHeatBalFanSys import state.dataHeatBalFanSys
from DataHeatBalance import state.dataHeatBal
from DataLoopNode import state.dataLoopNodes
from DataRoomAirModel import (
    state.dataRoomAir,
    UserDefinedPatternType,
    UserDefinedPatternMode,
    TemperaturePattern,
)
from DataSurfaces import (
    state.dataSurface,
    DataSurfaces,
    SurfaceClass,
    WindowAirFlowDestination,
    RefAirTemp,
    Vector3,
)
from DataZoneEnergyDemands import state.dataZoneEnergyDemand
from DataZoneEquipment import state.dataZoneEquip
from FluidProperties import Fluid
from General import General
from InternalHeatGains import InternalHeatGains
from OutputProcessor import (
    SetupOutputVariable,
    OutputProcessor,
    Constant,
)
from Psychrometrics import Psychrometrics
from ScheduleManager import state.dataScheduleManager
from UtilityRoutines import (
    ShowFatalError,
    ShowWarningError,
    ShowContinueError,
)
from ZoneTempPredictorCorrector import state.dataZoneTempPredictorCorrector
from HVAC import HVAC

struct RoomAirModelUserTempPatternData(BaseGlobalStruct):
    var MyOneTimeFlag: Bool = True  # one time setup flag
    var MyOneTimeFlag2: Bool = True
    var MyEnvrnFlag: List[Bool]  # flag for init once at start of environment
    var SetupOutputFlag: List[Bool]  # flag to set up output variable one-time if 2-grad model used

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.MyOneTimeFlag = True
        self.MyOneTimeFlag2 = True
        self.MyEnvrnFlag.clear()
        self.SetupOutputFlag.clear()

namespace EnergyPlus::RoomAir:

    def ManageUserDefinedPatterns(state: EnergyPlusData, ZoneNum: Int):
        InitTempDistModel(state, ZoneNum)
        GetSurfHBDataForTempDistModel(state, ZoneNum)
        CalcTempDistModel(state, ZoneNum)
        SetSurfHBDataForTempDistModel(state, ZoneNum)

    def InitTempDistModel(state: EnergyPlusData, ZoneNum: Int):
        if state.dataRoomAirModelTempPattern.MyOneTimeFlag:
            state.dataRoomAirModelTempPattern.MyEnvrnFlag = [True] * state.dataGlobal.NumOfZones
            state.dataRoomAirModelTempPattern.MyOneTimeFlag = False
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]  # 0-based
        if state.dataGlobal.BeginEnvrnFlag and state.dataRoomAirModelTempPattern.MyEnvrnFlag[ZoneNum - 1]:
            patternZoneInfo.TairMean = 23.0
            patternZoneInfo.Tstat = 23.0
            patternZoneInfo.Tleaving = 23.0
            patternZoneInfo.Texhaust = 23.0
            patternZoneInfo.Gradient = 0.0
            for SurfNum in range(patternZoneInfo.totNumSurfs):
                patternZoneInfo.Surf[SurfNum].TadjacentAir = 23.0
            state.dataRoomAirModelTempPattern.MyEnvrnFlag[ZoneNum - 1] = False
        if not state.dataGlobal.BeginEnvrnFlag:
            state.dataRoomAirModelTempPattern.MyEnvrnFlag[ZoneNum - 1] = True
        patternZoneInfo.Gradient = 0.0

    def GetSurfHBDataForTempDistModel(state: EnergyPlusData, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var zoneHeatBal = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
        patternZoneInfo.Tstat = zoneHeatBal.MAT
        patternZoneInfo.Tleaving = zoneHeatBal.MAT
        patternZoneInfo.Texhaust = zoneHeatBal.MAT
        for e in patternZoneInfo.Surf:
            e.TadjacentAir = zoneHeatBal.MAT
        patternZoneInfo.TairMean = zoneHeatBal.MAT  # this is lagged from previous corrector result

    def CalcTempDistModel(state: EnergyPlusData, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var AvailTest = patternZoneInfo.availSched.getCurrentVal()
        if (AvailTest != 1.0) or (not patternZoneInfo.IsUsed):
            patternZoneInfo.Tstat = patternZoneInfo.TairMean
            patternZoneInfo.Tleaving = patternZoneInfo.TairMean
            patternZoneInfo.Texhaust = patternZoneInfo.TairMean
            for e in patternZoneInfo.Surf:
                e.TadjacentAir = patternZoneInfo.TairMean
            return
        # choose pattern and call subroutine
        var CurntPatternKey = patternZoneInfo.patternSched.getCurrentVal()
        var CurPatrnID = General.FindNumberInList(CurntPatternKey, state.dataRoomAir.AirPattern, TemperaturePattern.PatrnID)
        if CurPatrnID == 0:
            ShowFatalError(state, "User defined room air pattern index not found: {}".format(CurntPatternKey))
            return
        switch state.dataRoomAir.AirPattern[CurPatrnID - 1].PatternMode:
            case UserDefinedPatternType.ConstGradTemp:
                FigureConstGradPattern(state, CurPatrnID, ZoneNum)
            case UserDefinedPatternType.TwoGradInterp:
                FigureTwoGradInterpPattern(state, CurPatrnID, ZoneNum)
            case UserDefinedPatternType.NonDimenHeight:
                FigureHeightPattern(state, CurPatrnID, ZoneNum)
            case UserDefinedPatternType.SurfMapTemp:
                FigureSurfMapPattern(state, CurPatrnID, ZoneNum)
            case _:
                assert(False)

    def FigureSurfMapPattern(state: EnergyPlusData, PattrnID: Int, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var pattern = state.dataRoomAir.AirPattern[PattrnID - 1]
        var Tmean = patternZoneInfo.TairMean
        for i in range(patternZoneInfo.totNumSurfs):
            var found = General.FindNumberInList(patternZoneInfo.Surf[i].SurfID, pattern.MapPatrn.SurfID, pattern.MapPatrn.NumSurfs)
            if found != 0:  # if surf is in map then assign, else give it MAT
                patternZoneInfo.Surf[i].TadjacentAir = pattern.MapPatrn.DeltaTai[found - 1] + Tmean
            else:
                patternZoneInfo.Surf[i].TadjacentAir = Tmean
        patternZoneInfo.Tstat = pattern.DeltaTstat + Tmean
        patternZoneInfo.Tleaving = pattern.DeltaTleaving + Tmean
        patternZoneInfo.Texhaust = pattern.DeltaTexhaust + Tmean

    def FigureHeightPattern(state: EnergyPlusData, PattrnID: Int, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var pattern = state.dataRoomAir.AirPattern[PattrnID - 1]
        var tmpDeltaTai = 0.0
        var Tmean = patternZoneInfo.TairMean
        for i in range(patternZoneInfo.totNumSurfs):
            var zeta = patternZoneInfo.Surf[i].Zeta
            var lowSideID = Fluid.FindArrayIndex(zeta, pattern.VertPatrn.ZetaPatrn)
            var highSideID = lowSideID + 1
            if lowSideID == 0:
                lowSideID = 1  # protect against array bounds
            var lowSideZeta = pattern.VertPatrn.ZetaPatrn[lowSideID - 1]
            var hiSideZeta = pattern.VertPatrn.ZetaPatrn[highSideID - 1] if highSideID <= len(pattern.VertPatrn.ZetaPatrn) else lowSideZeta
            if (hiSideZeta - lowSideZeta) != 0.0:
                var fractBtwn = (zeta - lowSideZeta) / (hiSideZeta - lowSideZeta)
                tmpDeltaTai = pattern.VertPatrn.DeltaTaiPatrn[lowSideID - 1] + fractBtwn * (pattern.VertPatrn.DeltaTaiPatrn[highSideID - 1] - pattern.VertPatrn.DeltaTaiPatrn[lowSideID - 1])
            else:  # would divide by zero, using low side value
                tmpDeltaTai = pattern.VertPatrn.DeltaTaiPatrn[lowSideID - 1]
            patternZoneInfo.Surf[i].TadjacentAir = tmpDeltaTai + Tmean
        # surfaces in this zone
        patternZoneInfo.Tstat = pattern.DeltaTstat + Tmean
        patternZoneInfo.Tleaving = pattern.DeltaTleaving + Tmean
        patternZoneInfo.Texhaust = pattern.DeltaTexhaust + Tmean

    def FigureTwoGradInterpPattern(state: EnergyPlusData, PattrnID: Int, ZoneNum: Int):
        var Grad: Float64  # vertical temperature gradient C/m
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var pattern = state.dataRoomAir.AirPattern[PattrnID - 1]
        if state.dataRoomAirModelTempPattern.MyOneTimeFlag2:
            state.dataRoomAirModelTempPattern.SetupOutputFlag = [True] * state.dataGlobal.NumOfZones  # init
            state.dataRoomAirModelTempPattern.MyOneTimeFlag2 = False
        if state.dataRoomAirModelTempPattern.SetupOutputFlag[ZoneNum - 1]:
            SetupOutputVariable(state,
                                "Room Air Zone Vertical Temperature Gradient",
                                Constant.Units.K_m,
                                patternZoneInfo.Gradient,
                                OutputProcessor.TimeStepType.System,
                                OutputProcessor.StoreType.Average,
                                patternZoneInfo.ZoneName)
            state.dataRoomAirModelTempPattern.SetupOutputFlag[ZoneNum - 1] = False
        var Tmean = patternZoneInfo.TairMean
        var twoGrad = pattern.TwoGradPatrn
        switch pattern.TwoGradPatrn.InterpolationMode:
            case UserDefinedPatternMode.OutdoorDryBulb:
                Grad = OutdoorDryBulbGrad(state.dataHeatBal.Zone[ZoneNum - 1].OutDryBulbTemp,
                                          twoGrad.UpperBoundTempScale,
                                          twoGrad.HiGradient,
                                          twoGrad.LowerBoundTempScale,
                                          twoGrad.LowGradient)
            case UserDefinedPatternMode.ZoneAirTemp:
                if Tmean >= twoGrad.UpperBoundTempScale:
                    Grad = twoGrad.HiGradient
                elif Tmean <= twoGrad.LowerBoundTempScale:
                    Grad = twoGrad.LowGradient
                elif (twoGrad.UpperBoundTempScale - twoGrad.LowerBoundTempScale) == 0.0:
                    Grad = twoGrad.LowGradient
                else:
                    Grad = twoGrad.LowGradient + ((Tmean - twoGrad.LowerBoundTempScale) / (twoGrad.UpperBoundTempScale - twoGrad.LowerBoundTempScale)) * (twoGrad.HiGradient - twoGrad.LowGradient)
            case UserDefinedPatternMode.DeltaOutdoorZone:
                var DeltaT = state.dataHeatBal.Zone[ZoneNum - 1].OutDryBulbTemp - Tmean
                if DeltaT >= twoGrad.UpperBoundTempScale:
                    Grad = twoGrad.HiGradient
                elif DeltaT <= twoGrad.LowerBoundTempScale:
                    Grad = twoGrad.LowGradient
                elif (twoGrad.UpperBoundTempScale - twoGrad.LowerBoundTempScale) == 0.0:
                    Grad = twoGrad.LowGradient
                else:
                    Grad = twoGrad.LowGradient + ((DeltaT - twoGrad.LowerBoundTempScale) / (twoGrad.UpperBoundTempScale - twoGrad.LowerBoundTempScale)) * (twoGrad.HiGradient - twoGrad.LowGradient)
            case UserDefinedPatternMode.SensibleCooling:
                var CoolLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].airSysCoolRate
                if CoolLoad >= twoGrad.UpperBoundHeatRateScale:
                    Grad = twoGrad.HiGradient
                elif CoolLoad <= twoGrad.LowerBoundHeatRateScale:
                    Grad = twoGrad.LowGradient
                else:  # interpolate
                    if (twoGrad.UpperBoundHeatRateScale - twoGrad.LowerBoundHeatRateScale) == 0.0:
                        Grad = twoGrad.LowGradient
                    else:
                        Grad = twoGrad.LowGradient + ((CoolLoad - twoGrad.LowerBoundHeatRateScale) / (twoGrad.UpperBoundHeatRateScale - twoGrad.LowerBoundHeatRateScale)) * (twoGrad.HiGradient - twoGrad.LowGradient)
            case UserDefinedPatternMode.SensibleHeating:
                var HeatLoad = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[ZoneNum - 1].airSysHeatRate
                if HeatLoad >= twoGrad.UpperBoundHeatRateScale:
                    Grad = twoGrad.HiGradient
                elif HeatLoad <= twoGrad.LowerBoundHeatRateScale:
                    Grad = twoGrad.LowGradient
                elif (twoGrad.UpperBoundHeatRateScale - twoGrad.LowerBoundHeatRateScale) == 0.0:
                    Grad = twoGrad.LowGradient
                else:
                    Grad = twoGrad.LowGradient + ((HeatLoad - twoGrad.LowerBoundHeatRateScale) / (twoGrad.UpperBoundHeatRateScale - twoGrad.LowerBoundHeatRateScale)) * (twoGrad.HiGradient - twoGrad.LowGradient)
            case _:

        var ZetaTmean = 0.5  # by definition,
        for i in range(patternZoneInfo.totNumSurfs):
            var zeta = patternZoneInfo.Surf[i].Zeta
            var DeltaHeight = -1.0 * (ZetaTmean - zeta) * patternZoneInfo.ZoneHeight
            patternZoneInfo.Surf[i].TadjacentAir = (DeltaHeight * Grad) + Tmean
        patternZoneInfo.Tstat = -1.0 * (0.5 * patternZoneInfo.ZoneHeight - twoGrad.TstatHeight) * Grad + Tmean
        patternZoneInfo.Tleaving = -1.0 * (0.5 * patternZoneInfo.ZoneHeight - twoGrad.TleavingHeight) * Grad + Tmean
        patternZoneInfo.Texhaust = -1.0 * (0.5 * patternZoneInfo.ZoneHeight - twoGrad.TexhaustHeight) * Grad + Tmean
        patternZoneInfo.Gradient = Grad

    def OutdoorDryBulbGrad(DryBulbTemp: Float64,  # Zone(ZoneNum).OutDryBulbTemp
                          UpperBound: Float64,   # RoomAirPattern(PattrnID).TwoGradPatrn.UpperBoundTempScale
                          HiGradient: Float64,   # RoomAirPattern(PattrnID).TwoGradPatrn.HiGradient
                          LowerBound: Float64,   # RoomAirPattern(PattrnID).TwoGradPatrn.LowerBoundTempScale
                          LowGradient: Float64   # RoomAirPattern(PattrnID).TwoGradPatrn.LowGradient
    ) -> Float64:
        if DryBulbTemp >= UpperBound:
            return HiGradient
        if DryBulbTemp <= LowerBound:
            return LowGradient
        if (UpperBound - LowerBound) == 0.0:
            return LowGradient
        return LowGradient + ((DryBulbTemp - LowerBound) / (UpperBound - LowerBound)) * (HiGradient - LowGradient)

    def FigureConstGradPattern(state: EnergyPlusData, PattrnID: Int, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        var pattern = state.dataRoomAir.AirPattern[PattrnID - 1]
        var Tmean = patternZoneInfo.TairMean  # MAT
        var Grad = pattern.GradPatrn.Gradient  # Vertical temperature gradient
        var ZetaTmean = 0.5  # non-dimensional height for MAT
        for i in range(patternZoneInfo.totNumSurfs):
            var zeta = patternZoneInfo.Surf[i].Zeta
            var DeltaHeight = -1.0 * (ZetaTmean - zeta) * patternZoneInfo.ZoneHeight
            patternZoneInfo.Surf[i].TadjacentAir = DeltaHeight * Grad + Tmean
        patternZoneInfo.Tstat = pattern.DeltaTstat + Tmean
        patternZoneInfo.Tleaving = pattern.DeltaTleaving + Tmean
        patternZoneInfo.Texhaust = pattern.DeltaTexhaust + Tmean

    def FigureNDheightInZone(state: EnergyPlusData, thisHBsurf: Int) -> Float64:  # index in main Surface array
        var TolValue: Float64 = 0.0001
        var Zcm = state.dataSurface.Surface[thisHBsurf - 1].Centroid.z
        var zone = state.dataHeatBal.Zone[state.dataSurface.Surface[thisHBsurf - 1].Zone - 1]
        var FloorCount = 0
        var ZFlrAvg = 0.0
        var ZMax = 0.0
        var ZMin = 0.0
        var Count = 0
        for spaceNum in zone.spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum - 1]
            for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                var surf = state.dataSurface.Surface[SurfNum - 1]
                if surf.Class == DataSurfaces.SurfaceClass.Floor:
                    FloorCount += 1
                    var Z1 = min([v.z for v in surf.Vertex])
                    var Z2 = max([v.z for v in surf.Vertex])
                    ZFlrAvg += (Z1 + Z2) / 2.0
                elif surf.Class == DataSurfaces.SurfaceClass.Wall:
                    Count += 1
                    if Count == 1:
                        ZMax = surf.Vertex[0].z
                        ZMin = ZMax
                    ZMax = max(ZMax, max([v.z for v in surf.Vertex]))
                    ZMin = min(ZMin, min([v.z for v in surf.Vertex]))
        ZFlrAvg = (ZFlrAvg / FloorCount) if FloorCount > 0 else ZMin
        var ZoneZorig = ZFlrAvg  # Z floor  [M]
        var ZoneCeilHeight = zone.CeilingHeight
        var SurfMinZ = min([v.z for v in state.dataSurface.Surface[thisHBsurf - 1].Vertex])
        var SurfMaxZ = max([v.z for v in state.dataSurface.Surface[thisHBsurf - 1].Vertex])
        if SurfMinZ < (ZoneZorig - TolValue):
            if state.dataGlobal.DisplayExtraWarnings:
                ShowWarningError(state, "RoomAirModelUserTempPattern: Problem in non-dimensional height calculation")
                ShowContinueError(state, "too low surface: {} in zone: {}".format(state.dataSurface.Surface[thisHBsurf - 1].Name, zone.Name))
                ShowContinueError(state, "**** Average floor height of zone is: {:.3f}".format(ZoneZorig))
                ShowContinueError(state, "**** Surface minimum height is: {:.3f}".format(SurfMinZ))
            else:
                state.dataErrTracking.TotalRoomAirPatternTooLow += 1
        if SurfMaxZ > (ZoneZorig + ZoneCeilHeight + TolValue):
            if state.dataGlobal.DisplayExtraWarnings:
                ShowWarningError(state, "RoomAirModelUserTempPattern: Problem in non-dimensional height calculation")
                ShowContinueError(state, " too high surface: {} in zone: {}".format(state.dataSurface.Surface[thisHBsurf - 1].Name, zone.Name))
                ShowContinueError(state, "**** Average Ceiling height of zone is: {:.3f}".format((ZoneZorig + ZoneCeilHeight)))
                ShowContinueError(state, "**** Surface Maximum height is: {:.3f}".format(SurfMaxZ))
            else:
                state.dataErrTracking.TotalRoomAirPatternTooHigh += 1
        var Zeta = (Zcm - ZoneZorig) / ZoneCeilHeight
        if Zeta > 0.99:
            Zeta = 0.99
        elif Zeta < 0.01:
            Zeta = 0.01
        return Zeta

    def SetSurfHBDataForTempDistModel(state: EnergyPlusData, ZoneNum: Int):
        var patternZoneInfo = state.dataRoomAir.AirPatternZoneInfo[ZoneNum - 1]
        if patternZoneInfo.ZoneNodeID != 0:
            state.dataLoopNodes.Node[patternZoneInfo.ZoneNodeID - 1].Temp = patternZoneInfo.Tleaving
        var zoneNode = state.dataLoopNodes.Node[patternZoneInfo.ZoneNodeID - 1]
        var zone = state.dataHeatBal.Zone[ZoneNum - 1]
        var zoneHeatBal = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
        var ZoneMult = zone.Multiplier * zone.ListMultiplier
        for returnNodeNum in state.dataZoneEquip.ZoneEquipConfig[ZoneNum - 1].ReturnNode:
            var returnNode = state.dataLoopNodes.Node[returnNodeNum - 1]
            var QRetAir = InternalHeatGains.zoneSumAllReturnAirConvectionGains(state, ZoneNum, returnNodeNum)
            var CpAir = Psychrometrics.PsyCpAirFnW(zoneNode.HumRat)
            var MassFlowRA = returnNode.MassFlowRate / ZoneMult
            var TempZoneAir = patternZoneInfo.Tleaving  # key difference from
            var TempRetAir = TempZoneAir
            var WinGapFlowToRA = 0.0
            var WinGapTtoRA = 0.0
            var WinGapFlowTtoRA = 0.0
            if zone.HasAirFlowWindowReturn:
                for spaceNum in zone.spaceIndexes:
                    var thisSpace = state.dataHeatBal.space[spaceNum - 1]
                    for SurfNum in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                        if state.dataSurface.SurfWinAirflowThisTS[SurfNum - 1] > 0.0 and state.dataSurface.SurfWinAirflowDestination[SurfNum - 1] == DataSurfaces.WindowAirFlowDestination.Return:
                            var FlowThisTS = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataSurface.SurfWinTAirflowGapOutlet[SurfNum - 1], zoneNode.HumRat) * state.dataSurface.SurfWinAirflowThisTS[SurfNum - 1] * state.dataSurface.Surface[SurfNum - 1].Width
                            WinGapFlowToRA += FlowThisTS
                            WinGapFlowTtoRA += FlowThisTS * state.dataSurface.SurfWinTAirflowGapOutlet[SurfNum - 1]
            if WinGapFlowToRA > 0.0:
                WinGapTtoRA = WinGapFlowTtoRA / WinGapFlowToRA
            if not zone.NoHeatToReturnAir:
                if MassFlowRA > 0.0:
                    if WinGapFlowToRA > 0.0:
                        if MassFlowRA >= WinGapFlowToRA:
                            TempRetAir = (WinGapFlowTtoRA + (MassFlowRA - WinGapFlowToRA) * TempZoneAir) / MassFlowRA
                        else:
                            TempRetAir = WinGapTtoRA
                            zoneHeatBal.SysDepZoneLoads += (WinGapFlowToRA - MassFlowRA) * CpAir * (WinGapTtoRA - TempZoneAir)
                    TempRetAir += QRetAir / (MassFlowRA * CpAir)
                    if TempRetAir > HVAC.RetTempMax:
                        returnNode.Temp = HVAC.RetTempMax
                        if not state.dataGlobal.ZoneSizingCalc:
                            zoneHeatBal.SysDepZoneLoads += CpAir * MassFlowRA * (TempRetAir - HVAC.RetTempMax)
                    elif TempRetAir < HVAC.RetTempMin:
                        returnNode.Temp = HVAC.RetTempMin
                        if not state.dataGlobal.ZoneSizingCalc:
                            zoneHeatBal.SysDepZoneLoads += CpAir * MassFlowRA * (TempRetAir - HVAC.RetTempMin)
                    else:
                        returnNode.Temp = TempRetAir
                else:  # No return air flow
                    if WinGapFlowToRA > 0.0:
                        zoneHeatBal.SysDepZoneLoads += WinGapFlowToRA * CpAir * (WinGapTtoRA - TempZoneAir)
                    if QRetAir > 0.0:
                        zoneHeatBal.SysDepZoneLoads += QRetAir
                    returnNode.Temp = zoneNode.Temp
            else:
                returnNode.Temp = zoneNode.Temp
            returnNode.Press = zoneNode.Press
            var H2OHtOfVap = Psychrometrics.PsyHgAirFnWTdb(zoneNode.HumRat, returnNode.Temp)
            if not zone.NoHeatToReturnAir:
                if MassFlowRA > 0:
                    var SumRetAirLatentGainRate = InternalHeatGains.SumAllReturnAirLatentGains(state, ZoneNum, returnNodeNum)
                    returnNode.HumRat = zoneNode.HumRat + (SumRetAirLatentGainRate / (H2OHtOfVap * MassFlowRA))
                else:
                    returnNode.HumRat = zoneNode.HumRat
                    state.dataHeatBal.RefrigCaseCredit[ZoneNum - 1].LatCaseCreditToZone += state.dataHeatBal.RefrigCaseCredit[ZoneNum - 1].LatCaseCreditToHVAC
                    var SumRetAirLatentGainRate = InternalHeatGains.SumAllReturnAirLatentGains(state, ZoneNum, 0)
                    zoneHeatBal.latentGain += SumRetAirLatentGainRate
            else:
                returnNode.HumRat = zoneNode.HumRat
                state.dataHeatBal.RefrigCaseCredit[ZoneNum - 1].LatCaseCreditToZone += state.dataHeatBal.RefrigCaseCredit[ZoneNum - 1].LatCaseCreditToHVAC
                zoneHeatBal.latentGain += InternalHeatGains.SumAllReturnAirLatentGains(state, ZoneNum, returnNodeNum)
            returnNode.Enthalpy = Psychrometrics.PsyHFnTdbW(returnNode.Temp, returnNode.HumRat)
        if allocated(patternZoneInfo.ExhaustAirNodeID):
            for exhaustAirNodeID in patternZoneInfo.ExhaustAirNodeID:
                state.dataLoopNodes.Node[exhaustAirNodeID - 1].Temp = patternZoneInfo.Texhaust
        state.dataHeatBalFanSys.TempTstatAir[ZoneNum - 1] = patternZoneInfo.Tstat
        for spaceNum in zone.spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum - 1]
            var j = 0
            for i in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                state.dataHeatBal.SurfTempEffBulkAir[i - 1] = patternZoneInfo.Surf[j].TadjacentAir
                j += 1
        for spaceNum in zone.spaceIndexes:
            var thisSpace = state.dataHeatBal.space[spaceNum - 1]
            for i in range(thisSpace.HTSurfaceFirst, thisSpace.HTSurfaceLast + 1):
                state.dataSurface.SurfTAirRef[i - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
                state.dataSurface.SurfTAirRefRpt[i - 1] = DataSurfaces.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[i - 1]]