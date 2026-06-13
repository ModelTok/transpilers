from gtest import Test, TestFixture, ASSERT_TRUE as gtest_ASSERT_TRUE
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf
from EnergyPlus.BaseboardElectric import BaseboardElectric
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataSizing import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.DataZoneEquipment import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SurfaceGeometry import *

# using namespace EnergyPlus;
# using namespace EnergyPlus::DataPlant;
# using namespace EnergyPlus::DataSizing;
# using namespace EnergyPlus::DataZoneEnergyDemands;

@value
struct EnergyPlusTestFixture(EnergyPlusFixture):

def ExerciseBaseboardElectric():
    var idf_objects: String = delimited_string([
        "ZoneHVAC:Baseboard:Convective:Electric,",
        "Zone1Baseboard,          !- Name",
        ",                        !- Availability Schedule Name",
        "HeatingDesignCapacity,   !- Heating Design Capacity Method",
        "5000,                    !- Heating Design Capacity {W}",
        ",                        !- Heating Design Capacity Per Floor Area {W/m2}",
        ",                        !- Fraction of Autosized Heating Design Capacity",
        "0.97;                    !- Efficiency"
    ])
    gtest_ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)  # state->init_state(*state) in C++
    state.dataZoneEquip.ZoneEquipConfig.allocate(1)
    state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 1  # 1-based -> 0-based
    state.dataLoopNodes.Node.allocate(1)
    state.dataLoopNodes.Node[0].Temp = 25.0
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 100
    var zoneNum: Int = 1
    var powerMet: Real64 = 0.0
    var compIndex: Int = 0
    BaseboardElectric.SimElectricBaseboard(state, "ZONE1BASEBOARD", zoneNum, powerMet, compIndex)

# TEST_F(EnergyPlusFixture, ExerciseBaseboardElectric) -> equivalent
def Test_ExerciseBaseboardElectric():
    var fixture = EnergyPlusFixture()
    fixture.ExerciseBaseboardElectric()

# Note: The above function simulates the test case.
# Actual test registration would be performed by the test framework.
<<<FILE>>>