from math import cos, sqrt, log

alias CJET1 = 1.873
alias CJET2 = 0.243
alias CREC1 = 0.591
alias CREC2 = 0.070
alias CJET_TEMP = 0.849
alias CREC_TEMP = 1.385
alias CREC_FLOW1 = 0.415
alias CREC_FLOW2 = 0.466
alias MIN_UIN = 0.2


struct RangeIndex:
    var beg: Int32
    var end: Int32


struct Vector3:
    var x: Float64
    var y: Float64
    var z: Float64
    
    @always_inline
    fn __iadd__(inout self, other: Vector3):
        self.x += other.x
        self.y += other.y
        self.z += other.z
    
    @always_inline
    fn __itruediv__(inout self, scalar: Float64):
        self.x /= scalar
        self.y /= scalar
        self.z /= scalar


struct CrossVentJetRecFlow:
    var Area: Float64
    var Fin: Float64
    var Uin: Float64
    var FlowFlag: Int32
    var Vjet: Float64
    var Yjet: Float64
    var Yrec: Float64
    var YQrec: Float64
    var Ujet: Float64
    var Urec: Float64
    var Qrec: Float64
    
    fn __init__(inout self):
        self.Area = 0.0
        self.Fin = 0.0
        self.Uin = 0.0
        self.FlowFlag = 0
        self.Vjet = 0.0
        self.Yjet = 0.0
        self.Yrec = 0.0
        self.YQrec = 0.0
        self.Ujet = 0.0
        self.Urec = 0.0
        self.Qrec = 0.0


struct CrossVentMgrData:
    var HAT_J: Float64
    var HA_J: Float64
    var HAT_R: Float64
    var HA_R: Float64
    var InitUCSDCV_MyOneTimeFlag: Bool
    var InitUCSDCV_MyEnvrnFlag: DynamicVector[Bool]
    
    fn __init__(inout self):
        self.HAT_J = 0.0
        self.HA_J = 0.0
        self.HAT_R = 0.0
        self.HA_R = 0.0
        self.InitUCSDCV_MyOneTimeFlag = True
        self.InitUCSDCV_MyEnvrnFlag = DynamicVector[Bool]()
    
    fn init_constant_state(inout self, state):
        pass
    
    fn init_state(inout self, state):
        pass
    
    fn clear_state(inout self):
        self.__init__()


fn manage_cross_vent(inout state, zone_num: Int32):
    init_cross_vent(state, zone_num)
    calc_cross_vent(state, zone_num)


fn init_cross_vent(inout state, zone_num: Int32):
    if state.dataCrossVentMgr.InitUCSDCV_MyOneTimeFlag:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag = DynamicVector[Bool]()
        for _ in range(state.dataGlobal.NumOfZones + 1):
            state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag.push_back(True)
        state.dataCrossVentMgr.InitUCSDCV_MyOneTimeFlag = False
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[zone_num]:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[zone_num] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataCrossVentMgr.InitUCSDCV_MyEnvrnFlag[zone_num] = True


@always_inline
fn hc_cross_vent_wall_loop(inout state, zone_num: Int32, zone_jet_rec_area_ratio: Float64):
    var pos_wall = state.dataRoomAir.PosZ_Wall[zone_num]
    for ctd in range(pos_wall.beg - 1, pos_wall.end):
        var surf_num = state.dataRoomAir.APos_Wall[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
        state.dataRoomAir.HWall[ctd] = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[surf_num] * state.dataRoomAir.HWall[ctd]
        state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HWall[ctd]


@always_inline
fn hc_cross_vent_window_loop(inout state, zone_num: Int32, zone_jet_rec_area_ratio: Float64):
    var pos_window = state.dataRoomAir.PosZ_Window[zone_num]
    for ctd in range(pos_window.beg - 1, pos_window.end):
        var surf_num = state.dataRoomAir.APos_Window[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        if 10.0 < surf.Tilt < 170.0:
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
            state.dataSurface.CalcDetailedHcInForDVModel(
                state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            state.dataRoomAir.HWindow[ctd] = state.dataRoomAir.CrossVentHcIn[surf_num]
            state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[surf_num] * state.dataRoomAir.HWindow[ctd]
            state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HWindow[ctd]
        if surf.Tilt <= 10.0:
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTJET[zone_num]
            state.dataSurface.CalcDetailedHcInForDVModel(
                state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
            var hjet = state.dataRoomAir.CrossVentHcIn[surf_num]
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
            state.dataSurface.CalcDetailedHcInForDVModel(
                state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            var hrec = state.dataRoomAir.CrossVentHcIn[surf_num]
            state.dataRoomAir.HWindow[ctd] = zone_jet_rec_area_ratio * hjet + (1 - zone_jet_rec_area_ratio) * hrec
            state.dataCrossVentMgr.HAT_R += surf.Area * (1.0 - zone_jet_rec_area_ratio) * state.dataHeatBalSurf.SurfTempIn[surf_num] * hrec
            state.dataCrossVentMgr.HA_R += surf.Area * (1.0 - zone_jet_rec_area_ratio) * hrec
            state.dataCrossVentMgr.HAT_J += surf.Area * zone_jet_rec_area_ratio * state.dataHeatBalSurf.SurfTempIn[surf_num] * hjet
            state.dataCrossVentMgr.HA_J += surf.Area * zone_jet_rec_area_ratio * hjet
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = (
                zone_jet_rec_area_ratio * state.dataRoomAir.ZTJET[zone_num] + 
                (1 - zone_jet_rec_area_ratio) * state.dataRoomAir.ZTREC[zone_num])
        if surf.Tilt >= 170.0:
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTJET[zone_num]
            state.dataSurface.CalcDetailedHcInForDVModel(
                state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
            var hjet = state.dataRoomAir.CrossVentHcIn[surf_num]
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
            state.dataSurface.CalcDetailedHcInForDVModel(
                state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
            var hrec = state.dataRoomAir.CrossVentHcIn[surf_num]
            state.dataRoomAir.HWindow[ctd] = zone_jet_rec_area_ratio * hjet + (1 - zone_jet_rec_area_ratio) * hrec
            state.dataCrossVentMgr.HAT_R += surf.Area * (1.0 - zone_jet_rec_area_ratio) * state.dataHeatBalSurf.SurfTempIn[surf_num] * hrec
            state.dataCrossVentMgr.HA_R += surf.Area * (1.0 - zone_jet_rec_area_ratio) * hrec
            state.dataCrossVentMgr.HAT_J += surf.Area * zone_jet_rec_area_ratio * state.dataHeatBalSurf.SurfTempIn[surf_num] * hjet
            state.dataCrossVentMgr.HA_J += surf.Area * zone_jet_rec_area_ratio * hjet
            state.dataHeatBal.SurfTempEffBulkAir[surf_num] = (
                zone_jet_rec_area_ratio * state.dataRoomAir.ZTJET[zone_num] + 
                (1 - zone_jet_rec_area_ratio) * state.dataRoomAir.ZTREC[zone_num])
        state.dataRoomAir.CrossVentHcIn[surf_num] = state.dataRoomAir.HWindow[ctd]


@always_inline
fn hc_cross_vent_door_loop(inout state, zone_num: Int32):
    var pos_door = state.dataRoomAir.PosZ_Door[zone_num]
    for ctd in range(pos_door.beg - 1, pos_door.end):
        var surf_num = state.dataRoomAir.APos_Door[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
        state.dataRoomAir.HDoor[ctd] = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[surf_num] * state.dataRoomAir.HDoor[ctd]
        state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HDoor[ctd]


@always_inline
fn hc_cross_vent_internal_loop(inout state, zone_num: Int32):
    var pos_internal = state.dataRoomAir.PosZ_Internal[zone_num]
    for ctd in range(pos_internal.beg - 1, pos_internal.end):
        var surf_num = state.dataRoomAir.APos_Internal[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
        state.dataRoomAir.HInternal[ctd] = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataCrossVentMgr.HAT_R += surf.Area * state.dataHeatBalSurf.SurfTempIn[surf_num] * state.dataRoomAir.HInternal[ctd]
        state.dataCrossVentMgr.HA_R += surf.Area * state.dataRoomAir.HInternal[ctd]


@always_inline
fn hc_cross_vent_ceiling_loop(inout state, zone_num: Int32, zone_jet_rec_area_ratio: Float64):
    var pos_ceiling = state.dataRoomAir.PosZ_Ceiling[zone_num]
    for ctd in range(pos_ceiling.beg - 1, pos_ceiling.end):
        var surf_num = state.dataRoomAir.APos_Ceiling[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTJET[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
        var hjet = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
        var hrec = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataRoomAir.HCeiling[ctd] = zone_jet_rec_area_ratio * hjet + (1 - zone_jet_rec_area_ratio) * hrec
        state.dataCrossVentMgr.HAT_R += surf.Area * (1 - zone_jet_rec_area_ratio) * state.dataHeatBalSurf.SurfTempIn[surf_num] * hrec
        state.dataCrossVentMgr.HA_R += surf.Area * (1 - zone_jet_rec_area_ratio) * hrec
        state.dataCrossVentMgr.HAT_J += surf.Area * zone_jet_rec_area_ratio * state.dataHeatBalSurf.SurfTempIn[surf_num] * hjet
        state.dataCrossVentMgr.HA_J += surf.Area * zone_jet_rec_area_ratio * hjet
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = (
            zone_jet_rec_area_ratio * state.dataRoomAir.ZTJET[zone_num] + 
            (1 - zone_jet_rec_area_ratio) * state.dataRoomAir.ZTREC[zone_num])
        state.dataRoomAir.CrossVentHcIn[surf_num] = state.dataRoomAir.HCeiling[ctd]


@always_inline
fn hc_cross_vent_floor_loop(inout state, zone_num: Int32, zone_jet_rec_area_ratio: Float64):
    var pos_floor = state.dataRoomAir.PosZ_Floor[zone_num]
    for ctd in range(pos_floor.beg - 1, pos_floor.end):
        var surf_num = state.dataRoomAir.APos_Floor[ctd]
        if surf_num == 0:
            continue
        var surf = state.dataSurface.Surface[surf_num]
        state.dataSurface.SurfTAirRef[surf_num] = state.dataSurface.RefAirTemp_AdjacentAirTemp
        state.dataSurface.SurfTAirRefRpt[surf_num] = state.dataSurface.SurfTAirRefReportVals[state.dataSurface.SurfTAirRef[surf_num]]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTJET[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Ujet)
        var hjet = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = state.dataRoomAir.ZTREC[zone_num]
        state.dataSurface.CalcDetailedHcInForDVModel(
            state, surf_num, state.dataHeatBalSurf.SurfTempIn, state.dataRoomAir.CrossVentHcIn, state.dataRoomAir.Urec)
        var hrec = state.dataRoomAir.CrossVentHcIn[surf_num]
        state.dataRoomAir.HFloor[ctd] = zone_jet_rec_area_ratio * hjet + (1 - zone_jet_rec_area_ratio) * hrec
        state.dataCrossVentMgr.HAT_R += surf.Area * (1 - zone_jet_rec_area_ratio) * state.dataHeatBalSurf.SurfTempIn[surf_num] * hrec
        state.dataCrossVentMgr.HA_R += surf.Area * (1 - zone_jet_rec_area_ratio) * hrec
        state.dataCrossVentMgr.HAT_J += surf.Area * zone_jet_rec_area_ratio * state.dataHeatBalSurf.SurfTempIn[surf_num] * hjet
        state.dataCrossVentMgr.HA_J += surf.Area * zone_jet_rec_area_ratio * hjet
        state.dataHeatBal.SurfTempEffBulkAir[surf_num] = (
            zone_jet_rec_area_ratio * state.dataRoomAir.ZTJET[zone_num] + 
            (1 - zone_jet_rec_area_ratio) * state.dataRoomAir.ZTREC[zone_num])
        state.dataRoomAir.CrossVentHcIn[surf_num] = state.dataRoomAir.HFloor[ctd]


fn hc_cross_vent(inout state, zone_num: Int32):
    state.dataCrossVentMgr.HAT_J = 0.0
    state.dataCrossVentMgr.HAT_R = 0.0
    state.dataCrossVentMgr.HA_J = 0.0
    state.dataCrossVentMgr.HA_R = 0.0
    
    if not state.dataRoomAir.IsZoneCrossVent[zone_num]:
        return
    
    var zone_jet_rec_area_ratio = state.dataRoomAir.JetRecAreaRatio[zone_num]
    
    hc_cross_vent_wall_loop(state, zone_num, zone_jet_rec_area_ratio)
    hc_cross_vent_window_loop(state, zone_num, zone_jet_rec_area_ratio)
    hc_cross_vent_door_loop(state, zone_num)
    hc_cross_vent_internal_loop(state, zone_num)
    hc_cross_vent_ceiling_loop(state, zone_num, zone_jet_rec_area_ratio)
    hc_cross_vent_floor_loop(state, zone_num, zone_jet_rec_area_ratio)


fn evolve_para_cross_vent(inout state, zone_num: Int32):
    var uin: Float64 = 0.0
    var cos_phi: Float64 = 0.0
    var surf_norm: Float64 = 0.0
    var max_flux: Float64 = 0.0
    var max_surf: Int32 = 0
    var active_surf_num: Float64 = 0.0
    var nsides: Int32 = 0
    var wroom: Float64 = 0.0
    var aroom: Float64 = 0.0
    
    debug_assert(state.dataRoomAir.AirModel is not None)
    state.dataRoomAir.RecInflowRatio[zone_num] = 0.0
    var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]
    
    max_surf = state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num]
    var surf_num_afn = state.afn.MultizoneSurfaceData[max_surf].SurfNum
    var this_surface = state.dataSurface.Surface[surf_num_afn]
    var afn_surf_num1 = state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num]
    
    if this_surface.Zone == zone_num:
        var max_flux = state.afn.AirflowNetworkLinkSimu[afn_surf_num1].VolFLOW2
    else:
        var max_flux = state.afn.AirflowNetworkLinkSimu[afn_surf_num1].VolFLOW
    
    for ctd2 in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var afn_surf_num = state.dataRoomAir.AFNSurfaceCrossVent[ctd2, zone_num]
        if state.dataSurface.Surface[state.afn.MultizoneSurfaceData[afn_surf_num].SurfNum].Zone == zone_num:
            if state.afn.AirflowNetworkLinkSimu[afn_surf_num].VolFLOW2 > max_flux:
                max_flux = state.afn.AirflowNetworkLinkSimu[afn_surf_num].VolFLOW2
                max_surf = afn_surf_num
        else:
            if state.afn.AirflowNetworkLinkSimu[afn_surf_num].VolFLOW > max_flux:
                max_flux = state.afn.AirflowNetworkLinkSimu[afn_surf_num].VolFLOW
                max_surf = afn_surf_num
    
    surf_norm = this_surface.Azimuth
    cos_phi = cos((state.dataEnvrn.WindDir - surf_norm) * state.Constant_DegToRad)
    
    if cos_phi <= 0:
        state.dataRoomAir.AirModel[zone_num].SimAirModel = False
        for i in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Ujet = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Urec = 0.0
        state.dataRoomAir.Urec[zone_num] = 0.0
        state.dataRoomAir.Ujet[zone_num] = 0.0
        state.dataRoomAir.Qrec[zone_num] = 0.0
        if this_surface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                state.dataSurface.Surface[this_surface.ExtBoundCond].Zone].MAT
        elif this_surface.ExtBoundCond == state.ExternalEnvironment:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.Ground:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.OtherSideCoefNoCalcExt or this_surface.ExtBoundCond == state.OtherSideCoefCalcExt:
            var this_osc = state.dataSurface.OSC[this_surface.OSCPtr]
            this_osc.OSCTempCalc = (
                this_osc.ZoneAirTempCoef * this_zone_hb.MAT +
                this_osc.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn] +
                this_osc.ConstTempCoef * this_osc.ConstTemp +
                this_osc.GroundTempCoef * state.dataEnvrn.GroundTemp[int(state.GroundTempType_BuildingSurface)] +
                this_osc.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surf_num_afn] * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
            )
            state.dataRoomAir.Tin[zone_num] = this_osc.OSCTempCalc
        else:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        return
    
    for ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var jet_rec_flows = state.dataRoomAir.CrossVentJetRecFlows[ctd, zone_num]
        var c_comp_num = state.afn.AirflowNetworkLinkageData[ctd].CompNum
        
        if state.afn.AirflowNetworkCompData[c_comp_num].CompTypeNum == state.AirflowNetwork_iComponentTypeNum_DOP:
            var surf_params = state.dataRoomAir.SurfParametersCrossDispVent[ctd]
            jet_rec_flows.Area = surf_params.Width * surf_params.Height * state.afn.MultizoneSurfaceData[ctd].OpenFactor
        elif state.afn.AirflowNetworkCompData[c_comp_num].CompTypeNum == state.AirflowNetwork_iComponentTypeNum_SCR:
            var surf_params = state.dataRoomAir.SurfParametersCrossDispVent[ctd]
            jet_rec_flows.Area = surf_params.Width * surf_params.Height
        else:
            state.ShowSevereError(state,
                "RoomAirModelCrossVent:EvolveParaUCSDCV: Illegal leakage component referenced in the cross ventilation room air model")
            state.ShowFatalError(state, "Previous severe error causes program termination")
    
    var base_centroid: Vector3 = Vector3(0.0, 0.0, 0.0)
    wroom = state.dataHeatBal.Zone[zone_num].Volume / state.dataHeatBal.Zone[zone_num].FloorArea
    var base_surface = state.dataSurface.Surface[this_surface.BaseSurf]
    
    if base_surface.Sides == 3 or base_surface.Sides == 4:
        base_centroid = base_surface.Centroid
    else:
        nsides = base_surface.Sides
        debug_assert(nsides > 0)
        for i in range(1, nsides + 1):
            base_centroid += base_surface.Vertex(i)
        base_centroid /= Float64(nsides)
    
    var wroom_2 = wroom * wroom
    for ctd in range(state.dataRoomAir.PosZ_Wall[zone_num].beg - 1, state.dataRoomAir.PosZ_Wall[zone_num].end):
        var wall_surface = state.dataSurface.Surface[state.dataRoomAir.APos_Wall[ctd]]
        var wall_centroid: Vector3 = Vector3(0.0, 0.0, 0.0)
        if wall_surface.Sides == 3 or wall_surface.Sides == 4:
            wall_centroid = wall_surface.Centroid
        else:
            nsides = wall_surface.Sides
            debug_assert(nsides > 0)
            for i in range(1, nsides + 1):
                wall_centroid += wall_surface.Vertex(i)
            wall_centroid /= Float64(nsides)
        
        var dx = base_centroid.x - wall_centroid.x
        var dy = base_centroid.y - wall_centroid.y
        var dz = base_centroid.z - wall_centroid.z
        var droom_temp = sqrt(dx * dx + dy * dy + dz * dz)
        if droom_temp > state.dataRoomAir.Droom[zone_num]:
            state.dataRoomAir.Droom[zone_num] = droom_temp
        state.dataRoomAir.Dstar[zone_num] = min(
            state.dataRoomAir.Droom[zone_num] / cos_phi,
            sqrt(wroom_2 + state.dataRoomAir.Droom[zone_num] * state.dataRoomAir.Droom[zone_num]))
    
    aroom = state.dataHeatBal.Zone[zone_num].Volume / state.dataRoomAir.Droom[zone_num]
    
    for ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var jet_rec_flows = state.dataRoomAir.CrossVentJetRecFlows[ctd, zone_num]
        if state.dataSurface.Surface[state.afn.MultizoneSurfaceData[ctd].SurfNum].Zone == zone_num:
            jet_rec_flows.Fin = state.afn.AirflowNetworkLinkSimu[state.dataRoomAir.AFNSurfaceCrossVent[ctd, zone_num]].VolFLOW2
        else:
            jet_rec_flows.Fin = state.afn.AirflowNetworkLinkSimu[state.dataRoomAir.AFNSurfaceCrossVent[ctd, zone_num]].VolFLOW
        
        if jet_rec_flows.Area != 0:
            jet_rec_flows.Uin = jet_rec_flows.Fin / jet_rec_flows.Area
        else:
            jet_rec_flows.Uin = 0.0
    
    active_surf_num = 0.0
    state.dataRoomAir.Ain[zone_num] = 0.0
    for ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var jet_rec_flows = state.dataRoomAir.CrossVentJetRecFlows[ctd, zone_num]
        jet_rec_flows.FlowFlag = int(jet_rec_flows.Uin > MIN_UIN)
        active_surf_num += Float64(jet_rec_flows.FlowFlag)
        state.dataRoomAir.Ain[zone_num] += jet_rec_flows.Area * Float64(jet_rec_flows.FlowFlag)
    
    if active_surf_num == 0:
        state.dataRoomAir.AirModel[zone_num].SimAirModel = False
        if this_surface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                state.dataSurface.Surface[this_surface.ExtBoundCond].Zone].MAT
        elif this_surface.ExtBoundCond == state.ExternalEnvironment:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.Ground:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.OtherSideCoefNoCalcExt or this_surface.ExtBoundCond == state.OtherSideCoefCalcExt:
            var this_osc = state.dataSurface.OSC[this_surface.OSCPtr]
            this_osc.OSCTempCalc = (
                this_osc.ZoneAirTempCoef * this_zone_hb.MAT +
                this_osc.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn] +
                this_osc.ConstTempCoef * this_osc.ConstTemp +
                this_osc.GroundTempCoef * state.dataEnvrn.GroundTemp[int(state.GroundTempType_BuildingSurface)] +
                this_osc.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surf_num_afn] * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
            )
            state.dataRoomAir.Tin[zone_num] = this_osc.OSCTempCalc
        else:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        state.dataRoomAir.Urec[zone_num] = 0.0
        state.dataRoomAir.Ujet[zone_num] = 0.0
        state.dataRoomAir.Qrec[zone_num] = 0.0
        for i in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Ujet = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Urec = 0.0
        return
    
    uin = 0.0
    for ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var jet_rec_flows = state.dataRoomAir.CrossVentJetRecFlows[ctd, zone_num]
        uin += jet_rec_flows.Area * jet_rec_flows.Uin * Float64(jet_rec_flows.FlowFlag) / state.dataRoomAir.Ain[zone_num]
    
    if uin < MIN_UIN:
        state.dataRoomAir.AirModel[zone_num].SimAirModel = False
        state.dataRoomAir.Urec[zone_num] = 0.0
        state.dataRoomAir.Ujet[zone_num] = 0.0
        state.dataRoomAir.Qrec[zone_num] = 0.0
        state.dataRoomAir.RecInflowRatio[zone_num] = 0.0
        for i in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Ujet = 0.0
            state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Urec = 0.0
        if this_surface.ExtBoundCond > 0:
            state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                state.dataSurface.Surface[this_surface.ExtBoundCond].Zone].MAT
        elif this_surface.ExtBoundCond == state.ExternalEnvironment:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.Ground:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.OtherSideCoefNoCalcExt or this_surface.ExtBoundCond == state.OtherSideCoefCalcExt:
            var this_osc = state.dataSurface.OSC[this_surface.OSCPtr]
            this_osc.OSCTempCalc = (
                this_osc.ZoneAirTempCoef * this_zone_hb.MAT +
                this_osc.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn] +
                this_osc.ConstTempCoef * this_osc.ConstTemp +
                this_osc.GroundTempCoef * state.dataEnvrn.GroundTemp[int(state.GroundTempType_BuildingSurface)] +
                this_osc.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surf_num_afn] * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
            )
            state.dataRoomAir.Tin[zone_num] = this_osc.OSCTempCalc
        else:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        return
    
    for ctd in range(1, state.dataRoomAir.TotCrossVent + 1):
        if zone_num == state.dataRoomAir.ZoneCrossVent[ctd].ZonePtr:
            if state.dataRoomAir.Ain[zone_num] / aroom > 0.5:
                state.dataRoomAir.JetRecAreaRatio[zone_num] = 1.0
            else:
                state.dataRoomAir.JetRecAreaRatio[zone_num] = sqrt(state.dataRoomAir.Ain[zone_num] / aroom)
    
    state.dataRoomAir.AirModel[zone_num].SimAirModel = True
    state.dataRoomAir.Ujet[zone_num] = 0.0
    state.dataRoomAir.Urec[zone_num] = 0.0
    state.dataRoomAir.Qrec[zone_num] = 0.0
    state.dataRoomAir.Qtot[zone_num] = 0.0
    for i in range(len(state.dataRoomAir.CrossVentJetRecFlows)):
        state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Ujet = 0.0
        state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Urec = 0.0
        state.dataRoomAir.CrossVentJetRecFlows[i, zone_num].Qrec = 0.0
    
    for ctd in range(1, state.dataRoomAir.AFNSurfaceCrossVent[0, zone_num] + 1):
        var jet_rec_flows = state.dataRoomAir.CrossVentJetRecFlows[ctd, zone_num]
        if jet_rec_flows.Uin == 0:
            continue
        
        var dstar_exp = max(state.dataRoomAir.Dstar[zone_num] / (6.0 * sqrt(jet_rec_flows.Area)), 1.0)
        jet_rec_flows.Vjet = (
            jet_rec_flows.Uin * sqrt(jet_rec_flows.Area) * 6.3 * log(dstar_exp) / state.dataRoomAir.Dstar[zone_num]
        )
        jet_rec_flows.Yjet = (
            CJET1 * sqrt(jet_rec_flows.Area / aroom) * jet_rec_flows.Vjet / jet_rec_flows.Uin + CJET2
        )
        jet_rec_flows.Yrec = (
            CREC1 * sqrt(jet_rec_flows.Area / aroom) * jet_rec_flows.Vjet / jet_rec_flows.Uin + CREC2
        )
        jet_rec_flows.YQrec = (
            CREC_FLOW1 * sqrt(jet_rec_flows.Area * aroom) * jet_rec_flows.Vjet / jet_rec_flows.Uin + CREC_FLOW2
        )
        jet_rec_flows.Ujet = Float64(jet_rec_flows.FlowFlag) * jet_rec_flows.Yjet / jet_rec_flows.Uin
        jet_rec_flows.Urec = Float64(jet_rec_flows.FlowFlag) * jet_rec_flows.Yrec / jet_rec_flows.Uin
        jet_rec_flows.Qrec = Float64(jet_rec_flows.FlowFlag) * jet_rec_flows.YQrec / jet_rec_flows.Uin
        state.dataRoomAir.Ujet[zone_num] += jet_rec_flows.Area * jet_rec_flows.Ujet / state.dataRoomAir.Ain[zone_num]
        state.dataRoomAir.Urec[zone_num] += jet_rec_flows.Area * jet_rec_flows.Urec / state.dataRoomAir.Ain[zone_num]
        state.dataRoomAir.Qrec[zone_num] += jet_rec_flows.Qrec
        state.dataRoomAir.Qtot[zone_num] += jet_rec_flows.Fin * Float64(jet_rec_flows.FlowFlag)
        state.dataRoomAir.Urec[zone_num] += jet_rec_flows.Area * jet_rec_flows.Urec / state.dataRoomAir.Ain[zone_num]
    
    if state.dataRoomAir.Qtot[zone_num] != 0:
        state.dataRoomAir.RecInflowRatio[zone_num] = state.dataRoomAir.Qrec[zone_num] / state.dataRoomAir.Qtot[zone_num]
    else:
        state.dataRoomAir.RecInflowRatio[zone_num] = 0.0
    
    if this_surface.ExtBoundCond <= 0:
        if this_surface.ExtBoundCond == state.ExternalEnvironment:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.Ground:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
        elif this_surface.ExtBoundCond == state.OtherSideCoefNoCalcExt or this_surface.ExtBoundCond == state.OtherSideCoefCalcExt:
            var this_osc = state.dataSurface.OSC[this_surface.OSCPtr]
            this_osc.OSCTempCalc = (
                this_osc.ZoneAirTempCoef * this_zone_hb.MAT +
                this_osc.ExtDryBulbCoef * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn] +
                this_osc.ConstTempCoef * this_osc.ConstTemp +
                this_osc.GroundTempCoef * state.dataEnvrn.GroundTemp[int(state.GroundTempType_BuildingSurface)] +
                this_osc.WindSpeedCoef * state.dataSurface.SurfOutWindSpeed[surf_num_afn] * state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
            )
            state.dataRoomAir.Tin[zone_num] = this_osc.OSCTempCalc
        else:
            state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
    else:
        if surf_num_afn == this_surface.ExtBoundCond:
            var node_num1 = state.afn.AirflowNetworkLinkageData[max_surf].NodeNums[0]
            var node_num2 = state.afn.AirflowNetworkLinkageData[max_surf].NodeNums[1]
            if this_surface.Zone == zone_num:
                if state.afn.AirflowNetworkNodeData[node_num1].EPlusZoneNum <= 0:
                    state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
                elif state.dataRoomAir.AirModel[state.afn.AirflowNetworkNodeData[node_num1].EPlusZoneNum].AirModel == state.RoomAirModel_CrossVent:
                    state.dataRoomAir.Tin[zone_num] = state.dataRoomAir.RoomOutflowTemp[
                        state.afn.AirflowNetworkNodeData[node_num1].EPlusZoneNum]
                else:
                    state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                        state.afn.AirflowNetworkNodeData[node_num1].EPlusZoneNum].MAT
            else:
                if state.afn.AirflowNetworkNodeData[node_num2].EPlusZoneNum <= 0:
                    state.dataRoomAir.Tin[zone_num] = state.dataSurface.SurfOutDryBulbTemp[surf_num_afn]
                elif state.dataRoomAir.AirModel[state.afn.AirflowNetworkNodeData[node_num2].EPlusZoneNum].AirModel == state.RoomAirModel_CrossVent:
                    state.dataRoomAir.Tin[zone_num] = state.dataRoomAir.RoomOutflowTemp[
                        state.afn.AirflowNetworkNodeData[node_num2].EPlusZoneNum]
                else:
                    state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                        state.afn.AirflowNetworkNodeData[node_num2].EPlusZoneNum].MAT
        elif (this_surface.Zone == zone_num and
              state.dataRoomAir.AirModel[state.dataSurface.Surface[this_surface.ExtBoundCond].Zone].AirModel == state.RoomAirModel_CrossVent):
            state.dataRoomAir.Tin[zone_num] = state.dataRoomAir.RoomOutflowTemp[
                state.dataSurface.Surface[this_surface.ExtBoundCond].Zone]
        elif (this_surface.Zone != zone_num and
              state.dataRoomAir.AirModel[this_surface.Zone].AirModel == state.RoomAirModel_CrossVent):
            state.dataRoomAir.Tin[zone_num] = state.dataRoomAir.RoomOutflowTemp[surf_num_afn]
        else:
            if this_surface.Zone == zone_num:
                state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                    state.dataSurface.Surface[this_surface.ExtBoundCond].Zone].MAT
            else:
                state.dataRoomAir.Tin[zone_num] = state.dataZoneTempPredictorCorrector.zoneHeatBalance[
                    this_surface.Zone].MAT


fn calc_cross_vent(inout state, zone_num: Int32):
    var zone = state.dataHeatBal.Zone[zone_num]
    var gains_frac: Float64 = 0.0
    var zone_mult = zone.Multiplier * zone.ListMultiplier
    var this_zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]
    
    for ctd in range(1, state.dataRoomAir.TotCrossVent + 1):
        if zone_num == state.dataRoomAir.ZoneCrossVent[ctd].ZonePtr:
            gains_frac = state.dataRoomAir.ZoneCrossVent[ctd].gainsSched.getCurrentVal()
    
    var conv_gains = state.zoneSumAllInternalConvectionGains(state, zone_num)
    conv_gains += (state.dataHeatBalFanSys.SumConvHTRadSys[zone_num] +
                   state.dataHeatBalFanSys.SumConvPool[zone_num] +
                   this_zone_hb.SysDepZoneLoadsLagged +
                   this_zone_hb.NonAirSystemResponse / zone_mult)
    
    if zone.NoHeatToReturnAir:
        var ret_air_conv_gain = state.zoneSumAllReturnAirConvectionGains(state, zone_num, 0)
        conv_gains += ret_air_conv_gain
    
    var conv_gains_jet = conv_gains * gains_frac
    var conv_gains_rec = conv_gains * (1.0 - gains_frac)
    var mcp_total = (this_zone_hb.MCPI + this_zone_hb.MCPV + this_zone_hb.MCPM +
                     this_zone_hb.MCPE + this_zone_hb.MCPC + this_zone_hb.MDotCPOA)
    var mcpt_total = (this_zone_hb.MCPTI + this_zone_hb.MCPTV + this_zone_hb.MCPTM +
                      this_zone_hb.MCPTE + this_zone_hb.MCPTC +
                      this_zone_hb.MDotCPOA * zone.OutDryBulbTemp)
    
    if state.afn.simulation_control.type == state.ControlType_MultizoneWithoutDistribution:
        mcp_total = (state.afn.exchangeData[zone_num].SumMCp +
                    state.afn.exchangeData[zone_num].SumMVCp +
                    state.afn.exchangeData[zone_num].SumMMCp)
        mcpt_total = (state.afn.exchangeData[zone_num].SumMCpT +
                     state.afn.exchangeData[zone_num].SumMVCpT +
                     state.afn.exchangeData[zone_num].SumMMCpT)
    
    evolve_para_cross_vent(state, zone_num)
    
    if state.dataRoomAir.AirModel[zone_num].SimAirModel:
        state.dataRoomAir.ZoneCrossVentIsMixing[zone_num] = 0.0
        state.dataRoomAir.ZoneCrossVentHasREC[zone_num] = 1.0
        for ctd in range(1, 5):
            hc_cross_vent(state, zone_num)
            if state.dataRoomAir.JetRecAreaRatio[zone_num] != 1.0:
                state.dataRoomAir.ZTREC[zone_num] = (
                    (conv_gains_rec * CREC_TEMP + CREC_TEMP * state.dataCrossVentMgr.HAT_R +
                     state.dataRoomAir.Tin[zone_num] * mcp_total) /
                    (CREC_TEMP * state.dataCrossVentMgr.HA_R + mcp_total)
                )
            state.dataRoomAir.ZTJET[zone_num] = (
                (conv_gains_jet * CJET_TEMP + conv_gains_rec * CJET_TEMP +
                 CJET_TEMP * state.dataCrossVentMgr.HAT_J +
                 CJET_TEMP * state.dataCrossVentMgr.HAT_R +
                 state.dataRoomAir.Tin[zone_num] * mcp_total -
                 CJET_TEMP * state.dataCrossVentMgr.HA_R * state.dataRoomAir.ZTREC[zone_num]) /
                (CJET_TEMP * state.dataCrossVentMgr.HA_J + mcp_total)
            )
            state.dataRoomAir.RoomOutflowTemp[zone_num] = (
                (conv_gains_jet + conv_gains_rec + state.dataCrossVentMgr.HAT_J +
                 state.dataCrossVentMgr.HAT_R + state.dataRoomAir.Tin[zone_num] * mcp_total -
                 state.dataCrossVentMgr.HA_J * state.dataRoomAir.ZTJET[zone_num] -
                 state.dataCrossVentMgr.HA_R * state.dataRoomAir.ZTREC[zone_num]) /
                mcp_total
            )
        
        if state.dataRoomAir.JetRecAreaRatio[zone_num] == 1.0:
            state.dataRoomAir.ZoneCrossVentHasREC[zone_num] = 0.0
            state.dataRoomAir.ZTREC[zone_num] = state.dataRoomAir.RoomOutflowTemp[zone_num]
            state.dataRoomAir.ZTREC[zone_num] = state.dataRoomAir.ZTJET[zone_num]
            state.dataRoomAir.ZTREC[zone_num] = state.dataRoomAir.ZTJET[zone_num]
        
        if state.dataRoomAir.RoomOutflowTemp[zone_num] - state.dataRoomAir.Tin[zone_num] > 1.5:
            state.dataRoomAir.ZoneCrossVentIsMixing[zone_num] = 1.0
            state.dataRoomAir.ZoneCrossVentHasREC[zone_num] = 0.0
            state.dataRoomAir.AirModel[zone_num].SimAirModel = False
            state.dataRoomAir.Ujet[zone_num] = 0.0
            state.dataRoomAir.Urec[zone_num] = 0.0
            state.dataRoomAir.Qrec[zone_num] = 0.0
            state.dataRoomAir.RecInflowRatio[zone_num] = 0.0
            for e in state.dataRoomAir.CrossVentJetRecFlows:
                e.Ujet = 0.0
                e.Urec = 0.0
            for ctd in range(1, 4):
                var zt_averaged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num].MAT
                state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
                state.dataRoomAir.ZTJET[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
                state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
                state.dataRoomAir.ZTJET[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
                hc_cross_vent(state, zone_num)
                zt_averaged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num].MAT
                state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
                state.dataRoomAir.ZTJET[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
                state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
                state.dataRoomAir.ZTJET[zone_num] = zt_averaged
                state.dataRoomAir.ZTREC[zone_num] = zt_averaged
    else:
        state.dataRoomAir.ZoneCrossVentIsMixing[zone_num] = 1.0
        state.dataRoomAir.ZoneCrossVentHasREC[zone_num] = 0.0
        state.dataRoomAir.Ujet[zone_num] = 0.0
        state.dataRoomAir.Urec[zone_num] = 0.0
        state.dataRoomAir.Qrec[zone_num] = 0.0
        state.dataRoomAir.RecInflowRatio[zone_num] = 0.0
        for e in state.dataRoomAir.CrossVentJetRecFlows:
            e.Ujet = 0.0
            e.Urec = 0.0
        for ctd in range(1, 4):
            var zt_averaged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num].MAT
            state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
            state.dataRoomAir.ZTJET[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
            state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
            state.dataRoomAir.ZTJET[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
            hc_cross_vent(state, zone_num)
            zt_averaged = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num].MAT
            state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
            state.dataRoomAir.ZTJET[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
            state.dataRoomAir.RoomOutflowTemp[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
            state.dataRoomAir.ZTJET[zone_num] = zt_averaged
            state.dataRoomAir.ZTREC[zone_num] = zt_averaged
