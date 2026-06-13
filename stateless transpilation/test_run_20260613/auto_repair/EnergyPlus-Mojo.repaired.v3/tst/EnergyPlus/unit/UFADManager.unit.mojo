from gtest import Test, TestFixture, EXPECT_NEAR
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.UFADManager import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture

@register_test(EnergyPlusFixture)
def test_sumUFADConvGainPerPlume():
    var dataHB = state.dataHeatBal
    dataHB.ZoneElectric.allocate(5)
    dataHB.ZoneGas.allocate(5)
    dataHB.ZoneOtherEq.allocate(5)
    dataHB.ZoneHWEq.allocate(5)
    dataHB.ZoneSteamEq.allocate(5)
    dataHB.ZoneElectric[0].DesignLevel = 11.0
    dataHB.ZoneElectric[1].DesignLevel = 12.0
    dataHB.ZoneElectric[2].DesignLevel = 13.0
    dataHB.ZoneElectric[3].DesignLevel = 14.0
    dataHB.ZoneElectric[4].DesignLevel = 15.0
    dataHB.ZoneElectric[0].FractionConvected = 0.11
    dataHB.ZoneElectric[1].FractionConvected = 0.21
    dataHB.ZoneElectric[2].FractionConvected = 0.31
    dataHB.ZoneElectric[3].FractionConvected = 0.41
    dataHB.ZoneElectric[4].FractionConvected = 0.51
    dataHB.ZoneElectric[0].ZonePtr = 1
    dataHB.ZoneElectric[1].ZonePtr = 1
    dataHB.ZoneElectric[2].ZonePtr = 2
    dataHB.ZoneElectric[3].ZonePtr = 2
    dataHB.ZoneElectric[4].ZonePtr = 3
    dataHB.ZoneGas[0].DesignLevel = 21.0
    dataHB.ZoneGas[1].DesignLevel = 22.0
    dataHB.ZoneGas[2].DesignLevel = 23.0
    dataHB.ZoneGas[3].DesignLevel = 24.0
    dataHB.ZoneGas[4].DesignLevel = 25.0
    dataHB.ZoneGas[0].FractionConvected = 0.12
    dataHB.ZoneGas[1].FractionConvected = 0.22
    dataHB.ZoneGas[2].FractionConvected = 0.32
    dataHB.ZoneGas[3].FractionConvected = 0.42
    dataHB.ZoneGas[4].FractionConvected = 0.52
    dataHB.ZoneGas[0].ZonePtr = 1
    dataHB.ZoneGas[1].ZonePtr = 2
    dataHB.ZoneGas[2].ZonePtr = 3
    dataHB.ZoneGas[3].ZonePtr = 1
    dataHB.ZoneGas[4].ZonePtr = 2
    dataHB.ZoneOtherEq[0].DesignLevel = 31.0
    dataHB.ZoneOtherEq[1].DesignLevel = 32.0
    dataHB.ZoneOtherEq[2].DesignLevel = 33.0
    dataHB.ZoneOtherEq[3].DesignLevel = 34.0
    dataHB.ZoneOtherEq[4].DesignLevel = 35.0
    dataHB.ZoneOtherEq[0].FractionConvected = 0.13
    dataHB.ZoneOtherEq[1].FractionConvected = 0.23
    dataHB.ZoneOtherEq[2].FractionConvected = 0.33
    dataHB.ZoneOtherEq[3].FractionConvected = 0.43
    dataHB.ZoneOtherEq[4].FractionConvected = 0.53
    dataHB.ZoneOtherEq[0].ZonePtr = 3
    dataHB.ZoneOtherEq[1].ZonePtr = 3
    dataHB.ZoneOtherEq[2].ZonePtr = 4
    dataHB.ZoneOtherEq[3].ZonePtr = 4
    dataHB.ZoneOtherEq[4].ZonePtr = 5
    dataHB.ZoneHWEq[0].DesignLevel = 41.0
    dataHB.ZoneHWEq[1].DesignLevel = 42.0
    dataHB.ZoneHWEq[2].DesignLevel = 43.0
    dataHB.ZoneHWEq[3].DesignLevel = 44.0
    dataHB.ZoneHWEq[4].DesignLevel = 45.0
    dataHB.ZoneHWEq[0].FractionConvected = 0.14
    dataHB.ZoneHWEq[1].FractionConvected = 0.24
    dataHB.ZoneHWEq[2].FractionConvected = 0.34
    dataHB.ZoneHWEq[3].FractionConvected = 0.44
    dataHB.ZoneHWEq[4].FractionConvected = 0.54
    dataHB.ZoneHWEq[0].ZonePtr = 5
    dataHB.ZoneHWEq[1].ZonePtr = 5
    dataHB.ZoneHWEq[2].ZonePtr = 6
    dataHB.ZoneHWEq[3].ZonePtr = 6
    dataHB.ZoneHWEq[4].ZonePtr = 7
    dataHB.ZoneSteamEq[0].DesignLevel = 51.0
    dataHB.ZoneSteamEq[1].DesignLevel = 52.0
    dataHB.ZoneSteamEq[2].DesignLevel = 53.0
    dataHB.ZoneSteamEq[3].DesignLevel = 54.0
    dataHB.ZoneSteamEq[4].DesignLevel = 55.0
    dataHB.ZoneSteamEq[0].FractionConvected = 0.15
    dataHB.ZoneSteamEq[1].FractionConvected = 0.25
    dataHB.ZoneSteamEq[2].FractionConvected = 0.35
    dataHB.ZoneSteamEq[3].FractionConvected = 0.45
    dataHB.ZoneSteamEq[4].FractionConvected = 0.55
    dataHB.ZoneSteamEq[0].ZonePtr = 7
    dataHB.ZoneSteamEq[1].ZonePtr = 7
    dataHB.ZoneSteamEq[2].ZonePtr = 8
    dataHB.ZoneSteamEq[3].ZonePtr = 8
    dataHB.ZoneSteamEq[4].ZonePtr = 8
    var numOccupants: Float64 = 10.0
    var expectedAnswer = Float64(74.633, 75.761, 75.64, 75.551, 76.437, 76.398, 77.495, 80.31)
    var allowedTolerance: Float64 = 0.00001
    for testNum in range(1, 9):
        var actualAnswer = RoomAir.sumUFADConvGainPerPlume(state, testNum, numOccupants)
        EXPECT_NEAR(actualAnswer, expectedAnswer[testNum - 1], allowedTolerance)