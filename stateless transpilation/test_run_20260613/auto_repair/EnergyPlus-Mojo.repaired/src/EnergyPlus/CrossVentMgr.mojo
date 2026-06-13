from builtin import assert
from math import sqrt, cos, log
from AirflowNetwork.Solver import *
from EnergyPlus.ConvectionCoefficients import *
from EnergyPlus.CrossVentMgr import *  // Actually this file defines the struct, but we will define it below.
from EnergyPlus.Data.BaseData import BaseGlobalStruct
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataRoomAir import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.InternalHeatGains import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.ZoneTempPredictorCorrector import *
def pow_2(x: Float64) -> Float64:
    return x * x
const DegToRad: Float64 = 3.141592653589793 / 180.0
struct Vector3[T: AnyType]:
    var x: T
    var y: T
    var z: T
struct Array1D_bool:
    var data: DynamicVector[Bool]
    def __init__(inout self):
        self.data = DynamicVector[Bool]()
    def dimension(inout self, n: Int, val: Bool):
        self.data = DynamicVector[Bool](n, val)
    def __getitem__(self, idx: Int) -> Bool:
        return self.data[idx - 1]
    def __setitem__(inout self, idx: Int, val: Bool):
        self.data[idx - 1] = val
struct CrossVentMgrData:
    var HAT_J: Float64 = 0.0
    var HA_J: Float64 = 0.0
    var HAT_R: Float64 = 0.0
    var HA_R: Float64 = 0.0
    var InitUCSDCV_MyOneTimeFlag: Bool = True
    var InitUCSDCV_MyEnvrnFlag: Array1D_bool = Array1D_bool()
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = CrossVentMgrData()
const Cjet1: Float64 = 1.873
const Cjet2: Float64 = 0.243
const Crec1: Float64 = 0.591
const Crec2: Float64 = 0.070
const CjetTemp: Float64 = 0.849
const CrecTemp: Float64 = 1.385
const CrecFlow1: Float64 = 0.415
const CrecFlow2: Float64 = 0.466
def ManageCrossVent(inout state: EnergyPlusData, ZoneNum: Int):
    InitCrossVent(state, ZoneNum)
    CalcCrossVent(state, ZoneNum)
def InitCrossVent(inout state: EnergyPlusData, ZoneNum: Int):
    if state.dataCrossVentMgr.InitUCSDCV_MyOneTimeFlag:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag.dimension(state.dataGlobal.NumOfZones, True)
        state.dataCrossVentMgr.InitUCSDCV_MyOneTimeFlag = False
    if state.dataGlobal.BeginEnvrnFlag and state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[ZoneNum]:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[ZoneNum] = False
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[ZoneNum] = True
def HcCrossVent(inout state: EnergyPlusData, ZoneNum: Int):
    state.dataCrossVentMgr.HAT_J = 0.0
    state.dataCrossVentMgr.HAT_R = 0.0
    state.dataCrossVentMgr.HA_J = 0.0
    state.dataCrossVentMgr.HA_R = 0.0
    if state.dataRoomAir.IsZoneCrossVent[ZoneNum - 1]:
        let zoneJetRecAreaRatio: Float64 = state.dataRoomAir.JetRecAreaRatio[ZoneNum - 1]
        let _beg_wall = state.dataRoomAir.PosZ_Wall[ZoneNum - 1].beg
        let _end_wall = state.dataRoomAir.PosZ_Wall[ZoneNum - 1].end
        for Ctd in range(_beg_wall - 1, _end_wall):
            let SurfNum: Int = state.dataRoomAir.APos_Wall[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            state.dataRoomAir.HWall[Ctd] = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * state.dataRoomAir.HWall[Ctd]
            state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HWall[Ctd]
        let _beg_win = state.dataRoomAir.PosZ_Window[ZoneNum - 1].beg
        let _end_win = state.dataRoomAir.PosZ_Window[ZoneNum - 1].end
        for Ctd in range(_beg_win - 1, _end_win):
            let SurfNum: Int = state.dataRoomAir.APos_Window[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            if surf.Tilt > 10.0 and surf.Tilt < 170.0:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
                state.dataRoomAir.HWindow[Ctd] = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
                state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * state.dataRoomAir.HWindow[Ctd]
                state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HWindow[Ctd]
            if surf.Tilt <= 10.0:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
                let Hjet: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
                let Hrec: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
                state.dataRoomAir.HWindow[Ctd] = zoneJetRecAreaRatio * Hjet + (1 - zoneJetRecAreaRatio) * Hrec
                state.dataCrossVentMgr.HAT_R += surf.Area * (1.0 - zoneJetRecAreaRatio) * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hrec
                state.dataCrossVentMgr.HA_R += surf.Area * (1.0 - zoneJetRecAreaRatio) * Hrec
                state.dataCrossVentMgr.HAT_J += surf.Area * zoneJetRecAreaRatio * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hjet
                state.dataCrossVentMgr.HA_J += surf.Area * zoneJetRecAreaRatio * Hjet
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = zoneJetRecAreaRatio * state.dataRoomAir.ZTJET[ZoneNum - 1] + (1 - zoneJetRecAreaRatio) * state.dataRoomAir.ZTREC[ZoneNum - 1]
            if surf.Tilt >= 170.0:
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
                let Hjet: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
                CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
                let Hrec: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
                state.dataRoomAir.HWindow[Ctd] = zoneJetRecAreaRatio * Hjet + (1 - zoneJetRecAreaRatio) * Hrec
                state.dataCrossVentMgr.HAT_R += surf.Area * (1.0 - zoneJetRecAreaRatio) * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hrec
                state.dataCrossVentMgr.HA_R += surf.Area * (1.0 - zoneJetRecAreaRatio) * Hrec
                state.dataCrossVentMgr.HAT_J += surf.Area * zoneJetRecAreaRatio * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hjet
                state.dataCrossVentMgr.HA_J += surf.Area * zoneJetRecAreaRatio * Hjet
                state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = zoneJetRecAreaRatio * state.dataRoomAir.ZTJET[ZoneNum - 1] + (1 - zoneJetRecAreaRatio) * state.dataRoomAir.ZTREC[ZoneNum - 1]
            state.dataRoomAir.CrossVentHcIn[SurfNum - 1] = state.dataRoomAir.HWindow[Ctd]
        let _beg_door = state.dataRoomAir.PosZ_Door[ZoneNum - 1].beg
        let _end_door = state.dataRoomAir.PosZ_Door[ZoneNum - 1].end
        for Ctd in range(_beg_door - 1, _end_door):
            let SurfNum: Int = state.dataRoomAir.APos_Door[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            state.dataRoomAir.HDoor[Ctd] = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * state.dataRoomAir.HDoor[Ctd]
            state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HDoor[Ctd]
        let _beg_int = state.dataRoomAir.PosZ_Internal[ZoneNum - 1].beg
        let _end_int = state.dataRoomAir.PosZ_Internal[ZoneNum - 1].end
        for Ctd in range(_beg_int - 1, _end_int):
            let SurfNum: Int = state.dataRoomAir.APos_Internal[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            state.dataRoomAir.HInternal[Ctd] = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * state.dataRoomAir.HInternal[Ctd]
            state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HInternal[Ctd]
        let _beg_ceil = state.dataRoomAir.PosZ_Ceiling[ZoneNum - 1].beg
        let _end_ceil = state.dataRoomAir.PosZ_Ceiling[ZoneNum - 1].end
        for Ctd in range(_beg_ceil - 1, _end_ceil):
            let SurfNum: Int = state.dataRoomAir.APos_Ceiling[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
            let Hjet: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            let Hrec: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataRoomAir.HCeiling[Ctd] = zoneJetRecAreaRatio * Hjet + (1 - zoneJetRecAreaRatio) * Hrec
            state.dataCrossVentMgr.HAT_R += surf.Area * (1 - zoneJetRecAreaRatio) * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hrec
            state.dataCrossVentMgr.HA_R += surf.Area * (1 - zoneJetRecAreaRatio) * Hrec
            state.dataCrossVentMgr.HAT_J += surf.Area * zoneJetRecAreaRatio * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hjet
            state.dataCrossVentMgr.HA_J += surf.Area * zoneJetRecAreaRatio * Hjet
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = zoneJetRecAreaRatio * state.dataRoomAir.ZTJET[ZoneNum - 1] + (1 - zoneJetRecAreaRatio) * state.dataRoomAir.ZTREC[ZoneNum - 1]
            state.dataRoomAir.CrossVentHcIn[SurfNum - 1] = state.dataRoomAir.HCeiling[Ctd]
        let _beg_floor = state.dataRoomAir.PosZ_Floor[ZoneNum - 1].beg
        let _end_floor = state.dataRoomAir.PosZ_Floor[ZoneNum - 1].end
        for Ctd in range(_beg_floor - 1, _end_floor):
            let SurfNum: Int = state.dataRoomAir.APos_Floor[Ctd]
            if SurfNum == 0:
                continue
            let surf = state.dataSurface.Surface[SurfNum - 1]
            state.dataSurface.SurfTAirRef[SurfNum - 1] = DataSurfaces.RefAirTemp.AdjacentAirTemp
            state.dataSurface.SurfTAirRefRpt[SurfNum - 1] = DataSurfaces.SurfTAirRefReportVals[Int(state.dataSurface.SurfTAirRef[SurfNum - 1])]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
            let Hjet: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = state.dataRoomAir.ZTREC[ZoneNum - 1]
            CalcDetailedHcInForDVModel(state, SurfNum, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            let Hrec: Float64 = state.dataRoomAir.CrossVentHcIn[SurfNum - 1]
            state.dataRoomAir.HFloor[Ctd] = zoneJetRecAreaRatio * Hjet + (1 - zoneJetRecAreaRatio) * Hrec
            state.dataCrossVentMgr.HAT_R += surf.Area * (1 - zoneJetRecAreaRatio) * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hrec
            state.dataCrossVentMgr.HA_R += surf.Area * (1 - zoneJetRecAreaRatio) * Hrec
            state.dataCrossVentMgr.HAT_J += surf.Area * zoneJetRecAreaRatio * state.dataHeatBalSurf.SurfTempIn[SurfNum - 1] * Hjet
            state.dataCrossVentMgr.HA_J += surf.Area * zoneJetRecAreaRatio * Hjet
            state.dataHeatBal.SurfTempEffBulkAir[SurfNum - 1] = zoneJetRecAreaRatio * state.dataRoomAir.ZTJET[ZoneNum - 1] + (1 - zoneJetRecAreaRatio) * state.dataRoomAir.ZTREC[ZoneNum - 1]
            state.dataRoomAir.CrossVentHcIn[SurfNum - 1] = state.dataRoomAir.HFloor[Ctd]
def EvolveParaCrossVent(inout state: EnergyPlusData, ZoneNum: Int):
    let MinUin: Float64 = 0.2
    var Uin: Float64
    var CosPhi: Float64
    var SurfNorm: Float64
    var SumToZone: Float64 = 0.0
    var MaxFlux: Float64 = 0.0
    var MaxSurf: Int = 0
    var ActiveSurfNum: Float64
    var NSides: Int
    var Wroom: Float64
    var Aroom: Float64
    assert(state.dataRoomAir.AirModel.allocated())
    state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = 0.0
    let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
    MaxSurf = state.dataRoomAir.AFNSurfaceCrossVent[1][ZoneNum - 1]
    let surfNum: Int = state.afn.MultizoneSurfaceData[MaxSurf - 1].SurfNum
    let thisSurface = state.dataSurface.Surface[surfNum - 1]
    let afnSurfNum1: Int = state.dataRoomAir.AFNSurfaceCrossVent[1][ZoneNum - 1]
    if thisSurface.Zone == ZoneNum:
        SumToZone = state.afn.AirflowNetworkLinkSimu[afnSurfNum1 - 1].VolFLOW2
        MaxFlux = state.afn.AirflowNetworkLinkSimu[afnSurfNum1 - 1].VolFLOW2
    else:
        SumToZone = state.afn.AirflowNetworkLinkSimu[afnSurfNum1 - 1].VolFLOW
        MaxFlux = state.afn.AirflowNetworkLinkSimu[afnSurfNum1 - 1].VolFLOW
    for Ctd2 in range(2, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        let afnSurfNum: Int = state.dataRoomAir.AFNSurfaceCrossVent[Ctd2][ZoneNum - 1]
        if state.dataSurface.Surface[state.afn.MultizoneSurfaceData[afnSurfNum - 1].SurfNum - 1].Zone == ZoneNum:
            if state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW2 > MaxFlux:
                MaxFlux = state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW2
                MaxSurf = afnSurfNum
            SumToZone += state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW2
        else:
            if state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW > MaxFlux:
                MaxFlux = state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW
                MaxSurf = afnSurfNum
            SumToZone += state.afn.AirflowNetworkLinkSimu[afnSurfNum - 1].VolFLOW
    SurfNorm = thisSurface.Azimuth
    CosPhi = cos((state.dataEnvrn.WindDir - SurfNorm) * DegToRad)
    if CosPhi <= 0:
        state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = False
        let nFlows = state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1]
        for i in range(1, nFlows + 1):
            var e = state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1]
            e.Ujet = 0.0
            e.Urec = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1] = e
        state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
        state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
        state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
        if thisSurface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1].MAT
        elif thisSurface.ExtBoundCond == ExternalEnvironment:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == Ground:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == OtherSideCoefNoCalcExt or thisSurface.ExtBoundCond == OtherSideCoefCalcExt:
            var thisOSC = state.dataSurface.OSC[thisSurface.OSCPtr]
            thisOSC.OSCTempCalc = (thisOSC.ZoneAirTempCoef * thisZoneHB.MAT + thisOSC.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1] + thisOSC.ConstTempCoef * thisOSC.ConstTemp + thisOSC.GroundTempCoef * state.dataEnvrn.GroundTemp[int(DataEnvironment.GroundTempType.BuildingSurface)] + thisOSC.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surfNum - 1] * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1])
            state.dataRoomAir.Tin[ZoneNum - 1] = thisOSC.OSCTempCalc
        else:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        return
    for Ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        var jetRecFlows = state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1]
        let surfParams = state.dataRoomAir.SurfParametersCrossDispVent[Ctd - 1]
        let cCompNum = state.afn.AirflowNetworkLinkageData[Ctd - 1].CompNum
        if state.afn.AirflowNetworkCompData[cCompNum - 1].CompTypeNum == AirflowNetwork.iComponentTypeNum.DOP:
            jetRecFlows.Area = surfParams.Width * surfParams.Height * state.afn.MultizoneSurfaceData[Ctd - 1].OpenFactor
        elif state.afn.AirflowNetworkCompData[cCompNum - 1].CompTypeNum == AirflowNetwork.iComponentTypeNum.SCR:
            jetRecFlows.Area = surfParams.Width * surfParams.Height
        else:
            ShowSevereError(state, "RoomAirModelCrossVent:EvolveParaUCSDCV: Illegal leakage component referenced in the cross ventilation room air model")
            ShowContinueError(state, format("Surface {} in zone {} uses leakage component {}", state.afn.AirflowNetworkLinkageData[Ctd - 1].Name, state.dataHeatBal.Zone[ZoneNum - 1].Name, state.afn.AirflowNetworkLinkageData[Ctd - 1].CompName))
            ShowContinueError(state, "Only leakage component types AirflowNetwork:MultiZone:Component:DetailedOpening and ")
            ShowContinueError(state, "AirflowNetwork:MultiZone:Surface:Crack can be used with the cross ventilation room air model")
            ShowFatalError(state, "Previous severe error causes program termination")
        state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1] = jetRecFlows
    var baseCentroid: Vector3[Float64]
    Wroom = state.dataHeatBal.Zone[ZoneNum - 1].Volume / state.dataHeatBal.Zone[ZoneNum - 1].FloorArea
    let baseSurface = state.dataSurface.Surface[thisSurface.BaseSurf - 1]
    if (baseSurface.Sides == 3) or (baseSurface.Sides == 4):
        baseCentroid = baseSurface.Centroid
    else:
        NSides = baseSurface.Sides
        assert(NSides > 0)
        baseCentroid = Vector3[Float64](0.0, 0.0, 0.0)
        for i in range(1, NSides + 1):
            baseCentroid.x += baseSurface.Vertex[i - 1].x
            baseCentroid.y += baseSurface.Vertex[i - 1].y
            baseCentroid.z += baseSurface.Vertex[i - 1].z
        baseCentroid.x /= Float64(NSides)
        baseCentroid.y /= Float64(NSides)
        baseCentroid.z /= Float64(NSides)
    var wallCentroid: Vector3[Float64]
    let Wroom_2 = pow_2(Wroom)
    let _beg_wall = state.dataRoomAir.PosZ_Wall[ZoneNum - 1].beg
    let _end_wall = state.dataRoomAir.PosZ_Wall[ZoneNum - 1].end
    for Ctd in range(_beg_wall - 1, _end_wall):
        let APos = state.dataRoomAir.APos_Wall[Ctd]
        let surfSides = state.dataSurface.Surface[APos - 1].Sides
        if (surfSides == 3) or (surfSides == 4):
            wallCentroid = state.dataSurface.Surface[APos - 1].Centroid
        else:
            NSides = surfSides
            assert(NSides > 0)
            wallCentroid = Vector3[Float64](0.0, 0.0, 0.0)
            for i in range(1, NSides + 1):
                wallCentroid.x += state.dataSurface.Surface[APos - 1].Vertex[i - 1].x
                wallCentroid.y += state.dataSurface.Surface[APos - 1].Vertex[i - 1].y
                wallCentroid.z += state.dataSurface.Surface[APos - 1].Vertex[i - 1].z
            wallCentroid.x /= Float64(NSides)
            wallCentroid.y /= Float64(NSides)
            wallCentroid.z /= Float64(NSides)
        let DroomTemp = sqrt(pow_2(baseCentroid.x - wallCentroid.x) + pow_2(baseCentroid.y - wallCentroid.y) + pow_2(baseCentroid.z - wallCentroid.z))
        if DroomTemp > state.dataRoomAir.Droom[ZoneNum - 1]:
            state.dataRoomAir.Droom[ZoneNum - 1] = DroomTemp
        state.dataRoomAir.Dstar[ZoneNum - 1] = min(state.dataRoomAir.Droom[ZoneNum - 1] / CosPhi, sqrt(Wroom_2 + pow_2(state.dataRoomAir.Droom[ZoneNum - 1])))
    Aroom = state.dataHeatBal.Zone[ZoneNum - 1].Volume / state.dataRoomAir.Droom[ZoneNum - 1]
    for Ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        var jetRecFlows = state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1]
        if state.dataSurface.Surface[state.afn.MultizoneSurfaceData[Ctd - 1].SurfNum - 1].Zone == ZoneNum:
            jetRecFlows.Fin = state.afn.AirflowNetworkLinkSimu[state.dataRoomAir.AFNSurfaceCrossVent[Ctd][ZoneNum - 1] - 1].VolFLOW2
        else:
            jetRecFlows.Fin = state.afn.AirflowNetworkLinkSimu[state.dataRoomAir.AFNSurfaceCrossVent[Ctd][ZoneNum - 1] - 1].VolFLOW
        if jetRecFlows.Area != 0:
            jetRecFlows.Uin = jetRecFlows.Fin / jetRecFlows.Area
        else:
            jetRecFlows.Uin = 0.0
        state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1] = jetRecFlows
    ActiveSurfNum = 0.0
    state.dataRoomAir.Ain[ZoneNum - 1] = 0.0
    for Ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        var jetRecFlows = state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1]
        jetRecFlows.FlowFlag = Int(jetRecFlows.Uin > MinUin)
        ActiveSurfNum += Float64(jetRecFlows.FlowFlag)
        state.dataRoomAir.Ain[ZoneNum - 1] += jetRecFlows.Area * Float64(jetRecFlows.FlowFlag)
        state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1] = jetRecFlows
    if ActiveSurfNum == 0:
        state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = False
        if thisSurface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1].MAT
        elif thisSurface.ExtBoundCond == ExternalEnvironment:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == Ground:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == OtherSideCoefNoCalcExt or thisSurface.ExtBoundCond == OtherSideCoefCalcExt:
            var thisOSC = state.dataSurface.OSC[thisSurface.OSCPtr]
            thisOSC.OSCTempCalc = (thisOSC.ZoneAirTempCoef * thisZoneHB.MAT + thisOSC.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1] + thisOSC.ConstTempCoef * thisOSC.ConstTemp + thisOSC.GroundTempCoef * state.dataEnvrn.GroundTemp[int(DataEnvironment.GroundTempType.BuildingSurface)] + thisOSC.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surfNum - 1] * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1])
            state.dataRoomAir.Tin[ZoneNum - 1] = thisOSC.OSCTempCalc
        else:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
        state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
        state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
        let nFlows = state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1]
        for i in range(1, nFlows + 1):
            var e = state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1]
            e.Ujet = 0.0
            e.Urec = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1] = e
        return
    Uin = 0.0
    for Ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        let jetRecFlows = state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1]
        Uin += jetRecFlows.Area * jetRecFlows.Uin * Float64(jetRecFlows.FlowFlag) / state.dataRoomAir.Ain[ZoneNum - 1]
    if Uin < MinUin:
        state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = False
        state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
        state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
        state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
        state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = 0.0
        let nFlows = state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1]
        for i in range(1, nFlows + 1):
            var e = state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1]
            e.Ujet = 0.0
            e.Urec = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1] = e
        if thisSurface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1].MAT
        elif thisSurface.ExtBoundCond == ExternalEnvironment:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == Ground:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == OtherSideCoefNoCalcExt or thisSurface.ExtBoundCond == OtherSideCoefCalcExt:
            var thisOSC = state.dataSurface.OSC[thisSurface.OSCPtr]
            thisOSC.OSCTempCalc = (thisOSC.ZoneAirTempCoef * thisZoneHB.MAT + thisOSC.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1] + thisOSC.ConstTempCoef * thisOSC.ConstTemp + thisOSC.GroundTempCoef * state.dataEnvrn.GroundTemp[int(DataEnvironment.GroundTempType.BuildingSurface)] + thisOSC.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surfNum - 1] * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1])
            state.dataRoomAir.Tin[ZoneNum - 1] = thisOSC.OSCTempCalc
        else:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        return
    for Ctd in range(1, state.dataRoomAir.TotCrossVent + 1):
        if ZoneNum == state.dataRoomAir.ZoneCrossVent[Ctd - 1].ZonePtr:
            if state.dataRoomAir.Ain[ZoneNum - 1] / Aroom > 1.0 / 2.0:
                state.dataRoomAir.JetRecAreaRatio[ZoneNum - 1] = 1.0
            else:
                state.dataRoomAir.JetRecAreaRatio[ZoneNum - 1] = sqrt(state.dataRoomAir.Ain[ZoneNum - 1] / Aroom)
    state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = True
    state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
    state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
    state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
    state.dataRoomAir.Qtot[ZoneNum - 1] = 0.0
    let nFlows = state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1]
    for i in range(1, nFlows + 1):
        var e = state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1]
        e.Ujet = 0.0
        e.Urec = 0.0
        e.Qrec = 0.0
        state.dataRoomAir.CrossVentJetRecFlows[i - 1][ZoneNum - 1] = e
    for Ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0][ZoneNum - 1] + 1):
        var jetRecFlows = state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1]
        if jetRecFlows.Uin == 0:
            continue
        let dstarexp = max(state.dataRoomAir.Dstar[ZoneNum - 1] / (6.0 * sqrt(jetRecFlows.Area)), 1.0)
        jetRecFlows.Vjet = jetRecFlows.Uin * sqrt(jetRecFlows.Area) * 6.3 * log(dstarexp) / state.dataRoomAir.Dstar[ZoneNum - 1]
        jetRecFlows.Yjet = Cjet1 * sqrt(jetRecFlows.Area / Aroom) * jetRecFlows.Vjet / jetRecFlows.Uin + Cjet2
        jetRecFlows.Yrec = Crec1 * sqrt(jetRecFlows.Area / Aroom) * jetRecFlows.Vjet / jetRecFlows.Uin + Crec2
        jetRecFlows.YQrec = CrecFlow1 * sqrt(jetRecFlows.Area * Aroom) * jetRecFlows.Vjet / jetRecFlows.Uin + CrecFlow2
        jetRecFlows.Ujet = Float64(jetRecFlows.FlowFlag) * jetRecFlows.Yjet / jetRecFlows.Uin
        jetRecFlows.Urec = Float64(jetRecFlows.FlowFlag) * jetRecFlows.Yrec / jetRecFlows.Uin
        jetRecFlows.Qrec = Float64(jetRecFlows.FlowFlag) * jetRecFlows.YQrec / jetRecFlows.Uin
        state.dataRoomAir.Ujet[ZoneNum - 1] += jetRecFlows.Area * jetRecFlows.Ujet / state.dataRoomAir.Ain[ZoneNum - 1]
        state.dataRoomAir.Urec[ZoneNum - 1] += jetRecFlows.Area * jetRecFlows.Urec / state.dataRoomAir.Ain[ZoneNum - 1]
        state.dataRoomAir.Qrec[ZoneNum - 1] += jetRecFlows.Qrec
        state.dataRoomAir.Qtot[ZoneNum - 1] += jetRecFlows.Fin * Float64(jetRecFlows.FlowFlag)
        state.dataRoomAir.Urec[ZoneNum - 1] += jetRecFlows.Area * jetRecFlows.Urec / state.dataRoomAir.Ain[ZoneNum - 1]
        state.dataRoomAir.CrossVentJetRecFlows[Ctd - 1][ZoneNum - 1] = jetRecFlows
    if state.dataRoomAir.Qtot[ZoneNum - 1] != 0:
        state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = state.dataRoomAir.Qrec[ZoneNum - 1] / state.dataRoomAir.Qtot[ZoneNum - 1]
    else:
        state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = 0.0
    if thisSurface.ExtBoundCond <= 0:
        if thisSurface.ExtBoundCond == ExternalEnvironment:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == Ground:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
        elif thisSurface.ExtBoundCond == OtherSideCoefNoCalcExt or thisSurface.ExtBoundCond == OtherSideCoefCalcExt:
            var thisOSC = state.dataSurface.OSC[thisSurface.OSCPtr]
            thisOSC.OSCTempCalc = (thisOSC.ZoneAirTempCoef * thisZoneHB.MAT + thisOSC.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1] + thisOSC.ConstTempCoef * thisOSC.ConstTemp + thisOSC.GroundTempCoef * state.dataEnvrn.GroundTemp[int(DataEnvironment.GroundTempType.BuildingSurface)] + thisOSC.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surfNum - 1] * state.dataSurface.SurfOutDryBulbTemp[surfNum - 1])
            state.dataRoomAir.Tin[ZoneNum - 1] = thisOSC.OSCTempCalc
        else:
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
    else:
        if surfNum == thisSurface.ExtBoundCond:
            let NodeNum1 = state.afn.AirflowNetworkLinkageData[MaxSurf - 1].NodeNums[0]
            let NodeNum2 = state.afn.AirflowNetworkLinkageData[MaxSurf - 1].NodeNums[1]
            if thisSurface.Zone == ZoneNum:
                if state.afn.AirflowNetworkNodeData[NodeNum1].EPlusZoneNum <= 0:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
                elif state.dataRoomAir.AirModel[state.afn.AirflowNetworkNodeData[NodeNum1].EPlusZoneNum - 1].AirModel == RoomAir.RoomAirModel.CrossVent:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataRoomAir.RoomOutflowTemp[state.afn.AirflowNetworkNodeData[NodeNum1].EPlusZoneNum - 1]
                else:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum1].EPlusZoneNum - 1].MAT
            else:
                if state.afn.AirflowNetworkNodeData[NodeNum2].EPlusZoneNum <= 0:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataSurface.SurfOutDryBulbTemp[surfNum - 1]
                elif state.dataRoomAir.AirModel[state.afn.AirflowNetworkNodeData[NodeNum2].EPlusZoneNum - 1].AirModel == RoomAir.RoomAirModel.CrossVent:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataRoomAir.RoomOutflowTemp[state.afn.AirflowNetworkNodeData[NodeNum2].EPlusZoneNum - 1]
                else:
                    state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.afn.AirflowNetworkNodeData[NodeNum2].EPlusZoneNum - 1].MAT
        elif (thisSurface.Zone == ZoneNum) and (state.dataRoomAir.AirModel[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1].AirModel == RoomAir.RoomAirModel.CrossVent):
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataRoomAir.RoomOutflowTemp[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1]
        elif (thisSurface.Zone != ZoneNum) and (state.dataRoomAir.AirModel[thisSurface.Zone - 1].AirModel == RoomAir.RoomAirModel.CrossVent):
            state.dataRoomAir.Tin[ZoneNum - 1] = state.dataRoomAir.RoomOutflowTemp[surfNum - 1]
        else:
            if thisSurface.Zone == ZoneNum:
                state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[state.dataSurface.Surface[thisSurface.ExtBoundCond - 1].Zone - 1].MAT
            else:
                state.dataRoomAir.Tin[ZoneNum - 1] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[thisSurface.Zone - 1].MAT
def CalcCrossVent(inout state: EnergyPlusData, ZoneNum: Int):
    let zone = state.dataHeatBal.Zone[ZoneNum - 1]
    var GainsFrac: Float64 = 0.0
    let ZoneMult: Float64 = zone.Multiplier * zone.ListMultiplier
    let thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1]
    for Ctd in range(1, state.dataRoomAir.TotCrossVent + 1):
        if ZoneNum == state.dataRoomAir.ZoneCrossVent[Ctd - 1].ZonePtr:
            GainsFrac = state.dataRoomAir.ZoneCrossVent[Ctd - 1].gainsSched.getCurrentVal()
    var ConvGains = InternalHeatGains.zoneSumAllInternalConvectionGains(state, ZoneNum)
    ConvGains += state.dataHeatBalFanSys.SumConvHTRadSys[ZoneNum - 1] + state.dataHeatBalFanSys.SumConvPool[ZoneNum - 1] + thisZoneHB.SysDepZoneLoadsLagged + thisZoneHB.NonAirSystemResponse / ZoneMult
    if zone.NoHeatToReturnAir:
        let RetAirConvGain = InternalHeatGains.zoneSumAllReturnAirConvectionGains(state, ZoneNum, 0)
        ConvGains += RetAirConvGain
    let ConvGainsJet = ConvGains * GainsFrac
    let ConvGainsRec = ConvGains * (1.0 - GainsFrac)
    var MCp_Total = thisZoneHB.MCPI + thisZoneHB.MCPV + thisZoneHB.MCPM + thisZoneHB.MCPE + thisZoneHB.MCPC + thisZoneHB.MDotCPOA
    var MCpT_Total = thisZoneHB.MCPTI + thisZoneHB.MCPTV + thisZoneHB.MCPTM + thisZoneHB.MCPTE + thisZoneHB.MCPTC + thisZoneHB.MDotCPOA * zone.OutDryBulbTemp
    if state.afn.simulation_control.type == AirflowNetwork.ControlType.MultizoneWithoutDistribution:
        MCp_Total = state.afn.exchangeData[ZoneNum - 1].SumMCp + state.afn.exchangeData[ZoneNum - 1].SumMVCp + state.afn.exchangeData[ZoneNum - 1].SumMMCp
        MCpT_Total = state.afn.exchangeData[ZoneNum - 1].SumMCpT + state.afn.exchangeData[ZoneNum - 1].SumMVCpT + state.afn.exchangeData[ZoneNum - 1].SumMMCpT
    EvolveParaCrossVent(state, ZoneNum)
    if state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel:
        state.dataRoomAir.ZoneCrossVentIsMixing[ZoneNum - 1] = 0.0
        state.dataRoomAir.ZoneCrossVentHasREC[ZoneNum - 1] = 1.0
        for Ctd in range(1, 5):
            HcCrossVent(state, ZoneNum)
            if state.dataRoomAir.JetRecAreaRatio[ZoneNum - 1] != 1.0:
                state.dataRoomAir.ZTREC[ZoneNum - 1] = (
                    ConvGainsRec * CrecTemp + CrecTemp * state.dataCrossVentMgr.HAT_R + state.dataRoomAir.Tin[ZoneNum - 1] * MCp_Total
                ) / (CrecTemp * state.dataCrossVentMgr.HA_R + MCp_Total)
            state.dataRoomAir.ZTJET[ZoneNum - 1] = (
                ConvGainsJet * CjetTemp + ConvGainsRec * CjetTemp + CjetTemp * state.dataCrossVentMgr.HAT_J +
                CjetTemp * state.dataCrossVentMgr.HAT_R + state.dataRoomAir.Tin[ZoneNum - 1] * MCp_Total -
                CjetTemp * state.dataCrossVentMgr.HA_R * state.dataRoomAir.ZTREC[ZoneNum - 1]
            ) / (CjetTemp * state.dataCrossVentMgr.HA_J + MCp_Total)
            state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = (
                ConvGainsJet + ConvGainsRec + state.dataCrossVentMgr.HAT_J + state.dataCrossVentMgr.HAT_R +
                state.dataRoomAir.Tin[ZoneNum - 1] * MCp_Total - state.dataCrossVentMgr.HA_J * state.dataRoomAir.ZTJET[ZoneNum - 1] -
                state.dataCrossVentMgr.HA_R * state.dataRoomAir.ZTREC[ZoneNum - 1]
            ) / MCp_Total
        if state.dataRoomAir.JetRecAreaRatio[ZoneNum - 1] == 1.0:
            state.dataRoomAir.ZoneCrossVentHasREC[ZoneNum - 1] = 0.0
            state.dataRoomAir.ZTREC[ZoneNum - 1] = state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1]
            state.dataRoomAir.ZTREC[ZoneNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
            state.dataRoomAir.ZTREC[ZoneNum - 1] = state.dataRoomAir.ZTJET[ZoneNum - 1]
        if state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] - state.dataRoomAir.Tin[ZoneNum - 1] > 1.5:
            state.dataRoomAir.ZoneCrossVentIsMixing[ZoneNum - 1] = 1.0
            state.dataRoomAir.ZoneCrossVentHasREC[ZoneNum - 1] = 0.0
            state.dataRoomAir.AirModel[ZoneNum - 1].SimAirModel = False
            state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
            state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
            state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
            state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = 0.0
            for row in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
                for col in range(len(state.dataRoomAir.CrossVentJetRecFlows[row])):
                    state.dataRoomAir.CrossVentJetRecFlows[row][col].Ujet = 0.0
                    state.dataRoomAir.CrossVentJetRecFlows[row][col].Urec = 0.0
            for Ctd in range(1, 4):
                var ZTAveraged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT
                state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
                HcCrossVent(state, ZoneNum)
                ZTAveraged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT
                state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
                state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
    else:
        state.dataRoomAir.ZoneCrossVentIsMixing[ZoneNum - 1] = 1.0
        state.dataRoomAir.ZoneCrossVentHasREC[ZoneNum - 1] = 0.0
        state.dataRoomAir.Ujet[ZoneNum - 1] = 0.0
        state.dataRoomAir.Urec[ZoneNum - 1] = 0.0
        state.dataRoomAir.Qrec[ZoneNum - 1] = 0.0
        state.dataRoomAir.RecInflowRatio[ZoneNum - 1] = 0.0
        for row in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
            for col in range(len(state.dataRoomAir.CrossVentJetRecFlows[row])):
                state.dataRoomAir.CrossVentJetRecFlows[row][col].Ujet = 0.0
                state.dataRoomAir.CrossVentJetRecFlows[row][col].Urec = 0.0
        for Ctd in range(1, 4):
            var ZTAveraged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT
            state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
            HcCrossVent(state, ZoneNum)
            ZTAveraged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneNum - 1].MAT
            state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.RoomOutflowTemp[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTJET[ZoneNum - 1] = ZTAveraged
            state.dataRoomAir.ZTREC[ZoneNum - 1] = ZTAveraged