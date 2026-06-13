from Fixtures.EnergyPlusFixture import state
from AirflowNetwork.Elements import iComponentTypeNum
from EnergyPlus.CrossVentMgr import EvolveParaCrossVent
from math import approx_eq

def CrossVentMgr_EvolveParaUCSDCV_Test():
    state.dataGlobal.NumOfZones = 2
    var MaxSurf: Int = 2
    state.dataRoomAir.RecInflowRatio = [0.0] * state.dataGlobal.NumOfZones
    state.dataZoneTempPredictorCorrector.zoneHeatBalance = [0.0] * state.dataGlobal.NumOfZones
    # AFNSurfaceCrossVent: 3 rows (0..2), 2 cols (1..2) -> Mojo [3][2]
    state.dataRoomAir.AFNSurfaceCrossVent = [[0 for _ in range(2)] for __ in range(3)]
    state.dataRoomAir.AFNSurfaceCrossVent[1][0] = 1  # (1,1)
    state.dataRoomAir.AFNSurfaceCrossVent[0][0] = 1  # (0,1)
    state.dataRoomAir.AFNSurfaceCrossVent[0][1] = 2  # (0,2)
    state.afn.MultizoneSurfaceData = [MultizoneSurfaceData() for _ in range(MaxSurf)]
    state.afn.MultizoneSurfaceData[0].SurfNum = 6
    state.afn.MultizoneSurfaceData[0].OpenFactor = 1.0
    state.afn.MultizoneSurfaceData[1].SurfNum = 9
    state.afn.MultizoneSurfaceData[1].OpenFactor = 1.0
    state.dataSurface.Surface = [Surface() for _ in range(10)]
    state.dataSurface.Surface[5].Zone = 1  # index 6 -> 5
    state.dataSurface.Surface[5].Azimuth = 0.0
    state.dataSurface.Surface[5].BaseSurf = 5
    state.dataSurface.Surface[4].Sides = 4  # index 5 -> 4
    state.dataSurface.Surface[4].Centroid.x = 13.143481000000001
    state.dataSurface.Surface[4].Centroid.y = 13.264719000000003
    state.dataSurface.Surface[4].Centroid.z = 1.6002000000000001
    state.dataSurface.Surface[6].Sides = 4  # index 7 -> 6
    state.dataSurface.Surface[6].Centroid.x = 25.415490999999996
    state.dataSurface.Surface[6].Centroid.y = 7.1687189999999994
    state.dataSurface.Surface[6].Centroid.z = 1.6763999999999999
    state.dataSurface.Surface[7].Sides = 4  # index 8 -> 7
    state.dataSurface.Surface[7].Centroid.x = 13.223490999999997
    state.dataSurface.Surface[7].Centroid.y = 1.0727189999999998
    state.dataSurface.Surface[7].Centroid.z = 1.6763999999999999
    state.dataSurface.Surface[9].Sides = 4  # index 10 -> 9
    state.dataSurface.Surface[9].Centroid.x = 1.0314909999999999
    state.dataSurface.Surface[9].Centroid.y = 7.1687189999999994
    state.dataSurface.Surface[9].Centroid.z = 1.6763999999999999
    state.dataSurface.SurfOutDryBulbTemp = [0.0] * 10
    state.dataSurface.SurfOutWindSpeed = [0.0] * 10
    state.dataHeatBal.Zone = [Zone() for _ in range(1)]
    state.dataHeatBal.Zone[0].Volume = 996.75300003839993
    state.dataHeatBal.Zone[0].FloorArea = 297.28972800000003
    state.afn.AirflowNetworkLinkSimu = [AirflowNetworkLinkSimu() for _ in range(1)]
    state.afn.AirflowNetworkLinkSimu[0].VolFLOW2 = 27.142934345451458
    state.dataEnvrn.WindDir = 271.66666666666669
    state.dataRoomAir.AirModel = [AirModel() for _ in range(state.dataGlobal.NumOfZones)]
    state.afn.AirflowNetworkLinkageData = [AirflowNetworkLinkageData() for _ in range(2)]
    state.afn.AirflowNetworkLinkageData[0].CompNum = 1
    state.afn.AirflowNetworkLinkageData[1].CompNum = 1
    state.afn.AirflowNetworkCompData = [AirflowNetworkCompData() for _ in range(3)]
    state.afn.AirflowNetworkCompData[0].TypeNum = 1
    state.afn.AirflowNetworkCompData[0].CompTypeNum = iComponentTypeNum.DOP
    state.afn.AirflowNetworkCompData[1].TypeNum = 1
    state.afn.AirflowNetworkCompData[1].CompTypeNum = iComponentTypeNum.SCR
    state.afn.AirflowNetworkCompData[2].TypeNum = 2
    state.afn.AirflowNetworkCompData[2].CompTypeNum = iComponentTypeNum.SOP
    state.dataRoomAir.SurfParametersCrossDispVent = [SurfParametersCrossDispVent() for _ in range(2)]
    state.dataRoomAir.SurfParametersCrossDispVent[0].Width = 22.715219999999999
    state.dataRoomAir.SurfParametersCrossDispVent[0].Height = 1.3715999999999999
    state.dataRoomAir.SurfParametersCrossDispVent[1].Width = 22.869143999999999
    state.dataRoomAir.SurfParametersCrossDispVent[1].Height = 1.3715999999999999
    state.dataRoomAir.CrossVentJetRecFlows = [[CrossVentJetRecFlows() for _ in range(1)] for __ in range(3)]
    state.dataRoomAir.PosZ_Wall = [PosZ_Wall() for _ in range(1)]
    state.dataRoomAir.PosZ_Wall[0].beg = 1
    state.dataRoomAir.PosZ_Wall[0].end = 4
    state.dataRoomAir.APos_Wall = [0] * 12
    state.dataRoomAir.APos_Wall[0] = 5  # index 1 -> 0
    state.dataRoomAir.APos_Wall[1] = 7
    state.dataRoomAir.APos_Wall[2] = 8
    state.dataRoomAir.APos_Wall[3] = 10
    state.dataRoomAir.Droom = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Droom[0] = 13.631070390838719
    state.dataRoomAir.Dstar = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Ain = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.ZoneCrossVent = [ZoneCrossVent() for _ in range(state.dataGlobal.NumOfZones)]
    state.dataRoomAir.ZoneCrossVent[0].ZonePtr = 1
    state.dataRoomAir.JetRecAreaRatio = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Ujet = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Urec = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Qrec = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Qtot = [0.0] * state.dataGlobal.NumOfZones
    state.dataRoomAir.Tin = [0.0] * state.dataGlobal.NumOfZones
    EvolveParaCrossVent(state, 0)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Fin, 27.14, 0.01)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Uin, 0.871, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Vjet, 0.000, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Yjet, 0.243, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Ujet, 0.279, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Yrec, 0.070, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Urec, 0.080, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].YQrec, 0.466, 0.001)
    assert approx_eq(state.dataRoomAir.CrossVentJetRecFlows[1][0].Qrec, 0.535, 0.001)