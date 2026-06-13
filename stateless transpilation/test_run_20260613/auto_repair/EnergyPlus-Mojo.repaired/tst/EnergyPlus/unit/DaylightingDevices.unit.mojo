from gtest import Test, TestFixture, EXPECT_NEAR
from array import array
from ObjexxFCL.Array1D import Array1D
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataDaylighting import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DaylightingDevices import adjustViewFactorsWithShelf
from EnergyPlus.DaylightingManager import *
from EnergyPlus.General import *

using EnergyPlus
using EnergyPlus.Dayltg
using EnergyPlus.DataSurfaces

@fixture
class DaylightingDevices_adjustViewFactorsWithShelfTest(EnergyPlusFixture):
    def TestBody(self):
        var vfShelfSet: Real64
        var vfSkySet: Real64
        var vfGroundSet: Real64
        var vfShelfResult: Real64
        var vfSkyResult: Real64
        var vfGroundResult: Real64
        var acceptableTolerance: Real64 = 0.00001
        var WinSurf: Int = 1
        var ShelfNum: Int = 1
        state.dataSurface.Surface.allocate(2)
        state.dataDaylightingDevicesData.Shelf.allocate(1)
        state.dataSurface.Surface[0].Vertex.allocate(4)
        state.dataSurface.Surface[1].Vertex.allocate(4)
        state.dataDaylightingDevicesData.Shelf[ShelfNum - 1].OutSurf = 2
        state.dataDaylightingDevicesData.Shelf[0].Name = "Skywalker"
        state.dataSurface.Surface[0].Sides = 4
        state.dataSurface.Surface[1].Sides = 4
        vfShelfSet = 0.67
        vfSkySet = -0.1
        vfGroundSet = -0.1
        vfShelfResult = 0.67
        vfSkyResult = 0.0
        vfGroundResult = 0.0
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 1.1
        vfSkySet = -0.1
        vfGroundSet = -0.1
        vfShelfResult = 1.0
        vfSkyResult = 0.0
        vfGroundResult = 0.0
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = -0.1
        vfSkySet = 0.4
        vfGroundSet = 0.4
        vfShelfResult = 0.0
        vfSkyResult = 0.4
        vfGroundResult = 0.4
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = -0.1
        vfSkySet = 0.8
        vfGroundSet = 0.4
        vfShelfResult = 0.0
        vfSkyResult = 2.0 / 3.0
        vfGroundResult = 1.0 / 3.0
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 0.2
        vfSkySet = 0.3
        vfGroundSet = 0.4
        vfShelfResult = 0.2
        vfSkyResult = 0.3
        vfGroundResult = 0.4
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 0.4
        vfSkySet = 0.5
        vfGroundSet = 0.5
        vfShelfResult = 0.4
        vfSkyResult = 0.5
        vfGroundResult = 0.1
        state.dataSurface.Surface[0].Vertex[0].z = 1.0
        state.dataSurface.Surface[0].Vertex[1].z = 1.0
        state.dataSurface.Surface[0].Vertex[2].z = 2.5
        state.dataSurface.Surface[0].Vertex[3].z = 2.5
        state.dataSurface.Surface[1].Vertex[0].z = 0.5
        state.dataSurface.Surface[1].Vertex[1].z = 0.5
        state.dataSurface.Surface[1].Vertex[2].z = 0.5
        state.dataSurface.Surface[1].Vertex[3].z = 0.5
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 0.4
        vfSkySet = 0.5
        vfGroundSet = 0.5
        vfShelfResult = 0.4
        vfSkyResult = 0.1
        vfGroundResult = 0.5
        state.dataSurface.Surface[0].Vertex[0].z = 1.0
        state.dataSurface.Surface[0].Vertex[1].z = 1.0
        state.dataSurface.Surface[0].Vertex[2].z = 2.5
        state.dataSurface.Surface[0].Vertex[3].z = 2.5
        state.dataSurface.Surface[1].Vertex[0].z = 3.0
        state.dataSurface.Surface[1].Vertex[1].z = 3.0
        state.dataSurface.Surface[1].Vertex[2].z = 3.0
        state.dataSurface.Surface[1].Vertex[3].z = 3.0
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 0.4
        vfSkySet = 0.25
        vfGroundSet = 0.5
        vfShelfResult = 0.4
        vfSkyResult = 0.18
        vfGroundResult = 0.42
        state.dataSurface.Surface[0].Vertex[0].z = 1.0
        state.dataSurface.Surface[0].Vertex[1].z = 1.0
        state.dataSurface.Surface[0].Vertex[2].z = 2.5
        state.dataSurface.Surface[0].Vertex[3].z = 2.5
        state.dataSurface.Surface[1].Vertex[0].z = 2.2
        state.dataSurface.Surface[1].Vertex[1].z = 2.2
        state.dataSurface.Surface[1].Vertex[2].z = 2.2
        state.dataSurface.Surface[1].Vertex[3].z = 2.2
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)
        vfShelfSet = 0.4
        vfSkySet = 0.5
        vfGroundSet = 0.25
        vfShelfResult = 0.4
        vfSkyResult = 0.40
        vfGroundResult = 0.20
        state.dataSurface.Surface[0].Vertex[0].z = 1.0
        state.dataSurface.Surface[0].Vertex[1].z = 1.0
        state.dataSurface.Surface[0].Vertex[2].z = 2.5
        state.dataSurface.Surface[0].Vertex[3].z = 2.5
        state.dataSurface.Surface[1].Vertex[0].z = 2.2
        state.dataSurface.Surface[1].Vertex[1].z = 2.2
        state.dataSurface.Surface[1].Vertex[2].z = 2.2
        state.dataSurface.Surface[1].Vertex[3].z = 2.2
        adjustViewFactorsWithShelf(state[], vfShelfSet, vfSkySet, vfGroundSet, WinSurf, ShelfNum)
        EXPECT_NEAR(vfShelfSet, vfShelfResult, acceptableTolerance)
        EXPECT_NEAR(vfSkySet, vfSkyResult, acceptableTolerance)
        EXPECT_NEAR(vfGroundSet, vfGroundResult, acceptableTolerance)