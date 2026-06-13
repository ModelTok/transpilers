from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from Data.EnergyPlusData import EnergyPlusData
from DataHeatBalSurface import SurfTempIn, etc # Placeholder for actual imports
from DataHeatBalance import SurfTempEffBulkAir, etc
from DataRoomAirModel import *
from DataSurfaces import SurfaceClass, SurfIntConv, etc
from DisplacementVentMgr import HcDispVent3Node, calculateThirdOrderFloorTemperature
from HeatBalanceAirManager import *
from testing import assert_approx_equal

@test
def DisplacementVentMgr_HcUCSDDV_Door_Test() raises:
    state.dataGlobal.NumOfZones = 1
    var TotSurfaces: Int = 3
    state.dataRoomAir.IsZoneDispVent3Node.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.IsZoneDispVent3Node[0] = True
    state.dataSurface.Surface.allocate(TotSurfaces)
    state.dataHeatBal.SurfTempEffBulkAir.allocate(TotSurfaces)
    state.dataHeatBalSurf.SurfTempIn.allocate(TotSurfaces)
    state.dataRoomAir.DispVent3NodeHcIn.allocate(TotSurfaces)
    state.dataRoomAir.ZTMX.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.ZTOC.allocate(state.dataGlobal.NumOfZones)

    state.dataSurface.Surface[0].Name = "Class1_Wall_6_0_0_0_0_0_Subsurface"
    state.dataSurface.Surface[0].Class = SurfaceClass.Door
    state.dataSurface.Surface[0].Zone = 1
    state.dataSurface.Surface[0].HeatTransSurf = True
    state.dataSurface.Surface[0].Construction = 1
    state.dataSurface.Surface[0].BaseSurf = 1
    state.dataSurface.Surface[0].Sides = 4
    state.dataSurface.Surface[0].Area = 10.0
    state.dataSurface.Surface[0].Azimuth = 0.0
    state.dataSurface.Surface[0].Tilt = 90.0
    state.dataSurface.Surface[0].Vertex.allocate(state.dataSurface.Surface[0].Sides)
    state.dataSurface.Surface[0].Vertex[0].x = -11.57740998
    state.dataSurface.Surface[0].Vertex[0].y = -12.31054602
    state.dataSurface.Surface[0].Vertex[0].z = 4.9804
    state.dataSurface.Surface[0].Vertex[1].x = -10.95990365
    state.dataSurface.Surface[0].Vertex[1].y = -12.31054602
    state.dataSurface.Surface[0].Vertex[1].z = 4.9804
    state.dataSurface.Surface[0].Vertex[2].x = -10.95990365
    state.dataSurface.Surface[0].Vertex[2].y = -12.31054602
    state.dataSurface.Surface[0].Vertex[2].z = 5.54536
    state.dataSurface.Surface[0].Vertex[3].x = -11.57740998
    state.dataSurface.Surface[0].Vertex[3].y = -12.31054602
    state.dataSurface.Surface[0].Vertex[3].z = 5.54536

    state.dataSurface.Surface[1].Name = "Class1_Floor_9_0_8_0_8_0_Subsurface"
    state.dataSurface.Surface[1].Class = SurfaceClass.Door
    state.dataSurface.Surface[1].Zone = 1
    state.dataSurface.Surface[1].HeatTransSurf = True
    state.dataSurface.Surface[1].Construction = 1
    state.dataSurface.Surface[1].BaseSurf = 1
    state.dataSurface.Surface[1].Sides = 4
    state.dataSurface.Surface[1].Area = 10.0
    state.dataSurface.Surface[1].Azimuth = 0.0
    state.dataSurface.Surface[1].Tilt = 180.0
    state.dataSurface.Surface[1].Vertex.allocate(state.dataSurface.Surface[0].Sides)  # Uses Surface(1).Sides? original uses Surface(1).Sides, which is 4
    state.dataSurface.Surface[1].Vertex[0].x = -4.80163552
    state.dataSurface.Surface[1].Vertex[0].y = -9.86732154
    state.dataSurface.Surface[1].Vertex[0].z = 4.9784
    state.dataSurface.Surface[1].Vertex[1].x = -13.28288246
    state.dataSurface.Surface[1].Vertex[1].y = -9.86732154
    state.dataSurface.Surface[1].Vertex[1].z = 4.9784
    state.dataSurface.Surface[1].Vertex[2].x = -13.28288246
    state.dataSurface.Surface[1].Vertex[2].y = -1.66421151
    state.dataSurface.Surface[1].Vertex[2].z = 4.9784
    state.dataSurface.Surface[1].Vertex[3].x = -4.80163552
    state.dataSurface.Surface[1].Vertex[3].y = -1.66421151
    state.dataSurface.Surface[1].Vertex[3].z = 4.9784

    state.dataSurface.Surface[2].Name = "Class1_Ceiling_0_0_9_0_9_0_Subsurface"
    state.dataSurface.Surface[2].HeatTransSurf = True
    state.dataSurface.Surface[2].Zone = 1
    state.dataSurface.Surface[2].Class = SurfaceClass.Door
    state.dataSurface.Surface[2].Construction = 1
    state.dataSurface.Surface[2].BaseSurf = 1
    state.dataSurface.Surface[2].Sides = 4
    state.dataSurface.Surface[2].Area = 10.0
    state.dataSurface.Surface[2].Azimuth = 0.0
    state.dataSurface.Surface[2].Tilt = 0.0
    state.dataSurface.Surface[2].Vertex.allocate(state.dataSurface.Surface[0].Sides)
    state.dataSurface.Surface[2].Vertex[0].x = -12.19542308
    state.dataSurface.Surface[2].Vertex[0].y = -9.84254602
    state.dataSurface.Surface[2].Vertex[0].z = 8.5343999852
    state.dataSurface.Surface[2].Vertex[1].x = -3.83980708
    state.dataSurface.Surface[2].Vertex[1].y = -9.84254602
    state.dataSurface.Surface[2].Vertex[1].z = 8.5343999852
    state.dataSurface.Surface[2].Vertex[2].x = -3.83980708
    state.dataSurface.Surface[2].Vertex[2].y = -1.48693002
    state.dataSurface.Surface[2].Vertex[2].z = 8.5343999852
    state.dataSurface.Surface[2].Vertex[3].x = -12.19542308
    state.dataSurface.Surface[2].Vertex[3].y = -1.48693002
    state.dataSurface.Surface[2].Vertex[3].z = 8.5343999852

    state.dataSurface.surfIntConv.allocate(TotSurfaces)
    fill(state.dataSurface.surfIntConv, SurfIntConv())
    state.dataSurface.SurfTAirRef.dimension(TotSurfaces, 0)
    state.dataSurface.SurfTAirRefRpt.dimension(TotSurfaces, 0)

    state.dataRoomAir.AirModel.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.AirModel[0].AirModel = RoomAir.RoomAirModel.DispVent3Node

    state.dataRoomAir.APos_Wall.allocate(TotSurfaces)
    state.dataRoomAir.APos_Floor.allocate(TotSurfaces)
    state.dataRoomAir.APos_Ceiling.allocate(TotSurfaces)
    state.dataRoomAir.PosZ_Wall.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.PosZ_Floor.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.PosZ_Ceiling.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.APos_Window.allocate(TotSurfaces)
    state.dataRoomAir.APos_Door.allocate(TotSurfaces)
    state.dataRoomAir.APos_Internal.allocate(TotSurfaces)
    state.dataRoomAir.PosZ_Window.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.PosZ_Door.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.PosZ_Internal.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.HCeiling.allocate(TotSurfaces)
    state.dataRoomAir.HWall.allocate(TotSurfaces)
    state.dataRoomAir.HFloor.allocate(TotSurfaces)
    state.dataRoomAir.HInternal.allocate(TotSurfaces)
    state.dataRoomAir.HWindow.allocate(TotSurfaces)
    state.dataRoomAir.HDoor.allocate(TotSurfaces)
    state.dataRoomAir.ZoneCeilingHeight1.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.ZoneCeilingHeight2.allocate(state.dataGlobal.NumOfZones)

    state.dataRoomAir.ZoneCeilingHeight1[0] = 4.9784
    state.dataRoomAir.ZoneCeilingHeight2[0] = 4.9784

    state.dataRoomAir.APos_Wall = 0
    state.dataRoomAir.APos_Floor = 0
    state.dataRoomAir.APos_Ceiling = 0
    state.dataRoomAir.PosZ_Wall[0].beg = 1
    state.dataRoomAir.PosZ_Wall[0].end = 0
    state.dataRoomAir.PosZ_Floor[0].beg = 1
    state.dataRoomAir.PosZ_Floor[0].end = 0
    state.dataRoomAir.PosZ_Ceiling[0].beg = 1
    state.dataRoomAir.PosZ_Ceiling[0].end = 0
    state.dataRoomAir.APos_Window = 0
    state.dataRoomAir.APos_Door = 0
    state.dataRoomAir.APos_Internal = 0
    state.dataRoomAir.PosZ_Window[0].beg = 1
    state.dataRoomAir.PosZ_Window[0].end = 0
    state.dataRoomAir.PosZ_Door[0].beg = 1
    state.dataRoomAir.PosZ_Door[0].end = 3
    state.dataRoomAir.PosZ_Internal[0].beg = 1
    state.dataRoomAir.PosZ_Internal[0].end = 0
    state.dataRoomAir.HCeiling = 0.0
    state.dataRoomAir.HWall = 0.0
    state.dataRoomAir.HFloor = 0.0
    state.dataRoomAir.HInternal = 0.0
    state.dataRoomAir.HWindow = 0.0
    state.dataRoomAir.HDoor = 0.0

    state.dataRoomAir.ZoneCrossVent.allocate(state.dataGlobal.NumOfZones)
    state.dataRoomAir.ZoneCrossVent[0].ZonePtr = 1

    state.dataRoomAir.PosZ_Door[0].beg = 1
    state.dataRoomAir.PosZ_Door[0].end = 3
    state.dataRoomAir.APos_Door[0] = 1
    state.dataRoomAir.APos_Door[1] = 2
    state.dataRoomAir.APos_Door[2] = 3

    state.dataRoomAir.ZTMX[0] = 20.0
    state.dataRoomAir.ZTOC[0] = 21.0
    state.dataHeatBalSurf.SurfTempIn[0] = 23.0
    state.dataHeatBalSurf.SurfTempIn[1] = 23.0
    state.dataHeatBalSurf.SurfTempIn[2] = 23.0

    HcDispVent3Node(state, 1, 0.5)

    assert_approx_equal(state.dataRoomAir.DispVent3NodeHcIn[0], 1.889346, 0.0001)
    assert_approx_equal(state.dataRoomAir.DispVent3NodeHcIn[1], 1.650496, 0.0001)
    assert_approx_equal(state.dataRoomAir.DispVent3NodeHcIn[2], 1.889346, 0.0001)
    assert_approx_equal(state.dataDispVentMgr.HAT_OC, 379.614212, 0.0001)
    assert_approx_equal(state.dataDispVentMgr.HA_OC, 16.504965, 0.0001)
    assert_approx_equal(state.dataDispVentMgr.HAT_MX, 869.099591, 0.0001)
    assert_approx_equal(state.dataDispVentMgr.HA_MX, 37.786938, 0.0001)

    state.dataRoomAir.IsZoneDispVent3Node.deallocate()
    state.dataSurface.Surface.deallocate()
    state.dataHeatBal.SurfTempEffBulkAir.deallocate()
    state.dataHeatBalSurf.SurfTempIn.deallocate()
    state.dataRoomAir.DispVent3NodeHcIn.deallocate()
    state.dataRoomAir.ZTMX.deallocate()
    state.dataRoomAir.ZTOC.deallocate()
    state.dataRoomAir.AirModel.deallocate()
    state.dataRoomAir.APos_Wall.deallocate()
    state.dataRoomAir.APos_Floor.deallocate()
    state.dataRoomAir.APos_Ceiling.deallocate()
    state.dataRoomAir.PosZ_Wall.deallocate()
    state.dataRoomAir.PosZ_Floor.deallocate()
    state.dataRoomAir.PosZ_Ceiling.deallocate()
    state.dataRoomAir.APos_Window.deallocate()
    state.dataRoomAir.APos_Door.deallocate()
    state.dataRoomAir.APos_Internal.deallocate()
    state.dataRoomAir.PosZ_Window.deallocate()
    state.dataRoomAir.PosZ_Door.deallocate()
    state.dataRoomAir.PosZ_Internal.deallocate()
    state.dataRoomAir.HCeiling.deallocate()
    state.dataRoomAir.HWall.deallocate()
    state.dataRoomAir.HFloor.deallocate()
    state.dataRoomAir.HInternal.deallocate()
    state.dataRoomAir.HWindow.deallocate()
    state.dataRoomAir.HDoor.deallocate()
    state.dataRoomAir.ZoneCeilingHeight1.deallocate()
    state.dataRoomAir.ZoneCeilingHeight2.deallocate()
    state.dataRoomAir.ZoneCrossVent.deallocate()

@test
def DVThirdOrderFloorTempCalculation() raises:
    let tempHistoryTerm: Real64 = 0  # no history
    let HAT_floor: Real64 = 20
    let HA_floor: Real64 = 1
    let MCpT_Total: Real64 = 40
    let MCp_Total: Real64 = 2
    let occupiedTemp: Real64 = 25
    let nonAirSystemResponse: Real64 = 0
    let zoneMultiplier: Real64 = 1
    let airCap: Real64 = 100
    var temp: Real64 = calculateThirdOrderFloorTemperature(
        tempHistoryTerm, HAT_floor, HA_floor, MCpT_Total, MCp_Total, occupiedTemp, nonAirSystemResponse, zoneMultiplier, airCap
    )
    assert_approx_equal(temp, 0.4799, 0.0001)