// This is a translation of the C++ test file. Mojo does not have gtest,
// so EXPECT_EQ, EXPECT_TRUE, EXPECT_FALSE are kept as function calls.
// They must be provided by the test framework.
// Includes translated to imports.
from EnergyPlus.EnergyPlusData import EnergyPlusData
from EnergyPlus.MixerComponent import MixerComponent, GetZoneMixerIndex

// #include <gtest/gtest.h>  // Not available in Mojo, kept as comment
// #include "Fixtures/EnergyPlusFixture.hh" // Not directly imported, we simulate fixture by local state

def GetZoneMixerIndex():
    var CurrentModuleObject: String
    var LINE: String
    var errFlag: Bool
    var MixerIndex: Int
    CurrentModuleObject = "AirLoopHVAC:ZoneMixer"
    state.dataMixerComponent.NumMixers = 3
    errFlag = false
    state.dataMixerComponent.MixerCond.allocate(state.dataMixerComponent.NumMixers)
    state.dataMixerComponent.MixerCond[0].MixerName = "SPACE1-1 ATU Mixer"
    state.dataMixerComponent.MixerCond[1].MixerName = "SPACE2-1 ATU Mixer"
    state.dataMixerComponent.MixerCond[2].MixerName = "SPACE3-1 ATU Mixer"
    GetZoneMixerIndex(state, state.dataMixerComponent.MixerCond[1].MixerName, MixerIndex, errFlag, CurrentModuleObject)
    EXPECT_EQ(2, MixerIndex)
    EXPECT_FALSE(errFlag)
    GetZoneMixerIndex(state, "SPACE3-3 ATU Mixer", MixerIndex, errFlag, CurrentModuleObject)
    EXPECT_EQ(0, MixerIndex)
    EXPECT_TRUE(errFlag)