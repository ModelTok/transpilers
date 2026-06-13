from gtest import Test, TestFixture, EXPECT_EQ
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.ExteriorEnergyUse import ExteriorEnergyUse, ReportExteriorEnergyUse
from EnergyPlus.ScheduleManager import Sched
from EnergyPlus.UtilityRoutines import UtilityRoutines
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

using EnergyPlus
using EnergyPlus.ExteriorEnergyUse

@fixture
class EnergyPlusFixture(TestFixture):
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def init_state(inout self, state: EnergyPlusData):

    def SetUp(inout self):
        self.state = EnergyPlusData()
        self.state.init_state(self.state)

    def TearDown(inout self):

def ExteriorEquipmentTest_Test1(inout self: EnergyPlusFixture):
    self.state.dataGlobal.TimeStepZone = 0.25
    self.state.dataGlobal.TimeStepZoneSec = self.state.dataGlobal.TimeStepZone * Constant.rSecsInHour
    self.state.init_state(self.state)
    self.state.dataExteriorEnergyUse.NumExteriorLights = 0
    self.state.dataExteriorEnergyUse.NumExteriorEqs = 2
    self.state.dataExteriorEnergyUse.ExteriorEquipment.allocate(self.state.dataExteriorEnergyUse.NumExteriorEqs)
    self.state.dataExteriorEnergyUse.ExteriorEquipment[0].DesignLevel = 1000.0
    self.state.dataExteriorEnergyUse.ExteriorEquipment[1].DesignLevel = 0.0
    self.state.dataExteriorEnergyUse.ExteriorEquipment[0].sched = Sched.GetScheduleAlwaysOn(self.state)
    self.state.dataExteriorEnergyUse.ExteriorEquipment[1].sched = Sched.GetScheduleAlwaysOn(self.state)
    ReportExteriorEnergyUse(self.state)
    EXPECT_EQ(1000.0, self.state.dataExteriorEnergyUse.ExteriorEquipment[0].Power)
    EXPECT_EQ(0.0, self.state.dataExteriorEnergyUse.ExteriorEquipment[1].Power)
    EXPECT_EQ(900000.0, self.state.dataExteriorEnergyUse.ExteriorEquipment[0].CurrentUse)
    EXPECT_EQ(0.0, self.state.dataExteriorEnergyUse.ExteriorEquipment[1].CurrentUse)