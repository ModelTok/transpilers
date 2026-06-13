from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataDefineEquip import DataDefineEquipment
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.HVACCooledBeam import HVACCooledBeam
from EnergyPlus.OutputReportPredefined import OutputReportPredefined, RetrievePreDefTableEntry
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.ScheduleManager import ScheduleManager as Sched
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from testing import expect_eq as EXPECT_EQ

@value
struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def HVACCooledBeam_reportTerminalUnit(inout self):
        using EnergyPlus.OutputReportPredefined
        var orp = ref self.state.dataOutRptPredefined
        var schedA = Sched.AddScheduleConstant(self.state, "schA")
        var schedB = Sched.AddScheduleConstant(self.state, "schB")
        var adu = ref self.state.dataDefineEquipment.AirDistUnit
        adu.allocate(2)
        adu[0].Name = "ADU a"
        adu[0].TermUnitSizingNum = 1
        var siz = ref self.state.dataSize.TermUnitFinalZoneSizing
        siz.allocate(2)
        siz[0].DesCoolVolFlowMin = 0.15
        siz[0].MinOA = 0.05
        siz[0].CoolDesTemp = 12.5
        siz[0].HeatDesTemp = 40.0
        siz[0].DesHeatLoad = 2000.0
        siz[0].DesCoolLoad = 3000.0
        var cb = ref self.state.dataHVACCooledBeam.CoolBeam
        cb.allocate(2)
        cb[0].ADUNum = 1
        cb[0].UnitType = "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
        cb[0].MaxAirVolFlow = 0.30
        cb[0].CBTypeString = "active"
        cb[0].reportTerminalUnit(self.state)
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinFlow, "ADU a"), "0.15")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinOutdoorFlow, "ADU a"), "0.05")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermSupCoolingSP, "ADU a"), "12.50")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermSupHeatingSP, "ADU a"), "40.00")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermHeatingCap, "ADU a"), "2000.00")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermCoolingCap, "ADU a"), "3000.00")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermTypeInp, "ADU a"), "AirTerminal:SingleDuct:ConstantVolume:CooledBeam")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermPrimFlow, "ADU a"), "0.30")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermSecdFlow, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinFlowSch, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermMaxFlowReh, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermMinOAflowSch, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermHeatCoilType, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermCoolCoilType, "ADU a"), "active")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermFanType, "ADU a"), "n/a")
        EXPECT_EQ(RetrievePreDefTableEntry(self.state, orp.pdchAirTermFanName, "ADU a"), "n/a")

def main():
    var fixture = EnergyPlusFixture()
    fixture.HVACCooledBeam_reportTerminalUnit()