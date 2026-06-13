from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, EXPECT_ENUM_EQ, ASSERT_TRUE, ASSERT_FALSE
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalFanSys import DataHeatBalFanSys
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.DataZoneEnergyDemands import DataZoneEnergyDemands
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.EvaporativeCoolers import EvaporativeCoolers
from EnergyPlus.Fans import Fans
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.OutAirNodeManager import OutAirNodeManager
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.DataZoneEquipment import ZoneEquipType
from EnergyPlus.HVAC import FanOp
from EnergyPlus.EvaporativeCoolers import ControlType

class ZoneHVACEvapCoolerUnitTest(EnergyPlusFixture):
    var UnitNum: Int = 1
    var EvapCoolNum: Int = 1
    var NumOfNodes: Int = 10
    var ErrorsFound: Bool = False
    var FirstHVACIteration: Bool = True

    def SetUp(self):
        EnergyPlusFixture.SetUp(self)
        self.state.dataSize.ZoneEqSizing.allocate(1)
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.StdRhoAir = Psychrometrics.PsyRhoAirFnPbTdbW(self.state, self.state.dataEnvrn.OutBaroPress, 20.0, 0.0)
        self.state.dataEnvrn.OutDryBulbTemp = 20.0
        self.state.dataEnvrn.OutHumRat = 0.0075
        self.state.dataEnvrn.OutWetBulbTemp = Psychrometrics.PsyTwbFnTdbWPb(self.state, self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat, self.state.dataEnvrn.OutBaroPress)
        self.state.dataGlobal.NumOfZones = 1
        self.state.dataHeatBal.Zone.allocate(self.state.dataGlobal.NumOfZones)
        self.state.dataZoneEquip.ZoneEquipConfig.allocate(self.state.dataGlobal.NumOfZones)
        self.state.dataZoneEquip.ZoneEquipList.allocate(self.state.dataGlobal.NumOfZones)
        self.state.dataLoopNodes.Node.allocate(self.NumOfNodes)
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand.allocate(1)
        self.state.dataHeatBalFanSys.zoneTstatSetpts.allocate(1)
        self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName = "One Zone"
        self.state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 1
        self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode.allocate(1)
        self.state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 3
        self.state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
        self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode.allocate(1)
        self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 4
        self.state.dataZoneEquip.ZoneEquipConfig[0].NumReturnNodes = 1
        self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode.allocate(1)
        self.state.dataZoneEquip.ZoneEquipConfig[0].ReturnNode[0] = 9
        self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode = 10
        self.state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = True
        self.state.dataHeatBal.Zone[0].Name = self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneName
        self.state.dataHeatBal.Zone[0].Multiplier = 1.0
        self.state.dataHeatBal.Zone[0].Volume = 1000.0
        self.state.dataHeatBal.Zone[0].SystemZoneNodeNumber = self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode
        self.state.dataHeatBal.Zone[0].ZoneVolCapMultpMoist = 1.0
        self.state.dataZoneEquip.ZoneEquipList[0].Name = "ZONEHVACEVAPEQUIPMENT"
        self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes = 1
        self.state.dataZoneEquip.ZoneEquipList[0].EquipTypeName.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].EquipType.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].EquipName.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].EquipIndex.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].EquipIndex = 1
        self.state.dataZoneEquip.ZoneEquipList[0].EquipData.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].CoolingPriority.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].HeatingPriority.allocate(self.state.dataZoneEquip.ZoneEquipList[0].NumOfEquipTypes)
        self.state.dataZoneEquip.ZoneEquipList[0].EquipTypeName[0] = "ZoneHVAC:EvaporativeCoolerUnit"
        self.state.dataZoneEquip.ZoneEquipList[0].CoolingPriority[0] = 1
        self.state.dataZoneEquip.ZoneEquipList[0].HeatingPriority[0] = 1
        self.state.dataZoneEquip.ZoneEquipList[0].EquipType[0] = ZoneEquipType.EvaporativeCooler

    def TearDown(self):
        EnergyPlusFixture.TearDown(self)

@Test
def DirectCelDekPad_CyclingUnit_Sim(self: ZoneHVACEvapCoolerUnitTest):
    var ActualZoneNum: Int = 1
    var ZoneEquipIndex: Int = 1
    var SensOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var idf_objects: String = delimited_string([
        " ZoneHVAC:EvaporativeCoolerUnit,",
        "   ZoneEvapCooler Unit,          !- Name",
        "   ,                             !- Availability Schedule Name",
        "   ,                             !- Availability Manager List Name",
        "   ZoneEvapCool OA Inlet,        !- Outdoor Air Inlet Node Name",
        "   ZoneEvapCool Inlet Node,      !- Cooler Outlet Node Name",
        "   ZoneEvapCool Relief Node,     !- Zone Relief Air Node Name",
        "   Fan:OnOff,                    !- Supply Air Fan Object Type",
        "   ZoneEvapCool Supply Fan,      !- Supply Air Fan Name",
        "   1.0,                          !- Design Supply Air Flow Rate {m3/s}",
        "   BlowThrough,                  !- Fan Placement",
        "   ZoneTemperatureDeadbandOnOffCycling,  !- Cooler Unit Control Method",
        "   1.0,                          !- Throttling Range Temperature Difference {deltaC}",
        "   100.0,                        !- Cooling Load Control Threshold Heat Transfer Rate {W}",
        "   EvaporativeCooler:Direct:CelDekPad,  !- First Evaporative Cooler Object Type",
        "   Direct CelDekPad EvapCooler;  !- First Evaporative Cooler Object Name",
        " Fan:OnOff,",
        "    ZoneEvapCool Supply Fan,     !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Fan Total Efficiency",
        "    300.0,                       !- Pressure Rise {Pa}",
        "    1.0,                         !- Maximum Flow Rate {m3/s}",
        "    0.9,                         !- Motor Efficiency",
        "    1.0,                         !- Motor In Airstream Fraction",
        "    ZoneEvapCool OA Inlet,       !- Air Inlet Node Name",
        "    ZoneEvapCool Fan outlet;     !- Air Outlet Node Name",
        " EvaporativeCooler:Direct:CelDekPad,",
        "    Direct CelDekPad EvapCooler, !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.6,                         !- Direct Pad Area {m2}",
        "    0.17,                        !- Direct Pad Depth {m}",
        "    55,                          !- Recirculating Water Pump Power Consumption {W}",
        "    ZoneEvapCool Fan outlet,     !- Air Inlet Node Name",
        "    ZoneEvapCool Inlet Node,     !- Air Outlet Node Name",
        "    ;                            !- Control Type",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    Fans.GetFanInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetEvapInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetInputZoneEvaporativeCoolerUnit(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    self.state.dataGlobal.BeginEnvrnFlag = True
    self.state.dataZoneEquip.ZoneEquipInputsFilled = True
    var thisZoneEvapCooler = self.state.dataEvapCoolers.ZoneEvapUnit[self.UnitNum - 1]
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = thisZoneEvapCooler.UnitReliefNodeNum
    self.state.dataLoopNodes.Node.redimension(self.NumOfNodes)
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp = 24.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat = 0.0080
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat)
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Temp = self.state.dataEnvrn.OutDryBulbTemp
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].HumRat = self.state.dataEnvrn.OutHumRat
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat)
    self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    self.state.dataZoneEquip.ZoneEquipList[0].EquipName[0] = thisZoneEvapCooler.Name
    EXPECT_EQ(Int(thisZoneEvapCooler.fanOp), Int(FanOp.Cycling))
    EXPECT_ENUM_EQ(thisZoneEvapCooler.ControlSchemeType, ControlType.ZoneTemperatureDeadBandOnOffCycling)
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    var FullSensibleOutput: Float64 = 0.0
    var FullLatentOutput: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    var HalfOfFullLoad: Float64 = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.4747010, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)
    thisZoneEvapCooler.ControlSchemeType = ControlType.ZoneCoolingLoadOnOffCycling
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    PartLoadRatio = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    HalfOfFullLoad = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.4747010, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)

@Test
def DirectResearchSpecial_CyclingUnit_Sim(self: ZoneHVACEvapCoolerUnitTest):
    var ActualZoneNum: Int = 1
    var ZoneEquipIndex: Int = 1
    var SensOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var idf_objects: String = delimited_string([
        " ZoneHVAC:EvaporativeCoolerUnit,",
        "   ZoneEvapCooler Unit,          !- Name",
        "   ,                             !- Availability Schedule Name",
        "   ,                             !- Availability Manager List Name",
        "   ZoneEvapCool OA Inlet,        !- Outdoor Air Inlet Node Name",
        "   ZoneEvapCool Inlet Node,      !- Cooler Outlet Node Name",
        "   ZoneEvapCool Relief Node,     !- Zone Relief Air Node Name",
        "   Fan:OnOff,                    !- Supply Air Fan Object Type",
        "   ZoneEvapCool Supply Fan,      !- Supply Air Fan Name",
        "   1.0,                          !- Design Supply Air Flow Rate {m3/s}",
        "   BlowThrough,                  !- Fan Placement",
        "   ZoneTemperatureDeadbandOnOffCycling,  !- Cooler Unit Control Method",
        "   1.0,                          !- Throttling Range Temperature Difference {deltaC}",
        "   100.0,                        !- Cooling Load Control Threshold Heat Transfer Rate {W}",
        "   EvaporativeCooler:Direct:ResearchSpecial,  !- First Evaporative Cooler Object Type",
        "   Direct ResearchSpecial EvapCooler;  !- First Evaporative Cooler Object Name",
        " Fan:OnOff,",
        "    ZoneEvapCool Supply Fan,     !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Fan Total Efficiency",
        "    300.0,                       !- Pressure Rise {Pa}",
        "    1.0,                         !- Maximum Flow Rate {m3/s}",
        "    0.9,                         !- Motor Efficiency",
        "    1.0,                         !- Motor In Airstream Fraction",
        "    ZoneEvapCool OA Inlet,       !- Air Inlet Node Name",
        "    ZoneEvapCool Fan outlet;     !- Air Outlet Node Name",
        " EvaporativeCooler:Direct:ResearchSpecial,",
        "   Direct ResearchSpecial EvapCooler,  !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Cooler Design Effectiveness",
        "    ,                            !- Effectiveness Flow Ratio Modifier Curve Name",
        "    1.0,                         !- Primary Air Design Flow Rate {m3/s}",
        "    55,                          !- Recirculating Water Pump Power Consumption {W}",
        "    ,                            !- Water Pump Power Sizing Factor {W/(m3/s)}",
        "    ,                            !- Water Pump Power Modifier Curve Name",
        "    ZoneEvapCool Fan outlet,     !- Air Inlet Node Name",
        "    ZoneEvapCool Inlet Node,     !- Air Outlet Node Name",
        "    ZoneEvapCool Inlet Node;     !- Sensor Node Name",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    Fans.GetFanInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetEvapInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetInputZoneEvaporativeCoolerUnit(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    self.state.dataGlobal.BeginEnvrnFlag = True
    self.state.dataZoneEquip.ZoneEquipInputsFilled = True
    var thisZoneEvapCooler = self.state.dataEvapCoolers.ZoneEvapUnit[self.UnitNum - 1]
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = thisZoneEvapCooler.UnitReliefNodeNum
    self.state.dataLoopNodes.Node.redimension(self.NumOfNodes)
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp = 24.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat = 0.0080
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat)
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Temp = self.state.dataEnvrn.OutDryBulbTemp
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].HumRat = self.state.dataEnvrn.OutHumRat
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat)
    self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    self.state.dataZoneEquip.ZoneEquipList[0].EquipName[0] = thisZoneEvapCooler.Name
    EXPECT_ENUM_EQ(thisZoneEvapCooler.fanOp, FanOp.Cycling)
    EXPECT_ENUM_EQ(thisZoneEvapCooler.ControlSchemeType, ControlType.ZoneTemperatureDeadBandOnOffCycling)
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    var FullSensibleOutput: Float64 = 0.0
    var FullLatentOutput: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    var HalfOfFullLoad: Float64 = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.500000, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)
    thisZoneEvapCooler.ControlSchemeType = ControlType.ZoneCoolingLoadOnOffCycling
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    PartLoadRatio = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    HalfOfFullLoad = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.500000, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)

@Test
def IndirectWetCoil_CyclingUnit_Sim(self: ZoneHVACEvapCoolerUnitTest):
    var ActualZoneNum: Int = 1
    var ZoneEquipIndex: Int = 1
    var SensOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var idf_objects: String = delimited_string([
        " ZoneHVAC:EvaporativeCoolerUnit,",
        "   ZoneEvapCooler Unit,          !- Name",
        "   ,                             !- Availability Schedule Name",
        "   ,                             !- Availability Manager List Name",
        "   ZoneEvapCool OA Inlet,        !- Outdoor Air Inlet Node Name",
        "   ZoneEvapCool Inlet Node,      !- Cooler Outlet Node Name",
        "   ZoneEvapCool Relief Node,     !- Zone Relief Air Node Name",
        "   Fan:OnOff,                    !- Supply Air Fan Object Type",
        "   ZoneEvapCool Supply Fan,      !- Supply Air Fan Name",
        "   1.0,                          !- Design Supply Air Flow Rate {m3/s}",
        "   BlowThrough,                  !- Fan Placement",
        "   ZoneTemperatureDeadbandOnOffCycling,  !- Cooler Unit Control Method",
        "   1.0,                          !- Throttling Range Temperature Difference {deltaC}",
        "   100.0,                        !- Cooling Load Control Threshold Heat Transfer Rate {W}",
        "   EvaporativeCooler:Indirect:WetCoil,  !- First Evaporative Cooler Object Type",
        "   Indirect WetCoil EvapCooler;  !- First Evaporative Cooler Object Name",
        " Fan:OnOff,",
        "    ZoneEvapCool Supply Fan,     !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Fan Total Efficiency",
        "    300.0,                       !- Pressure Rise {Pa}",
        "    1.0,                         !- Maximum Flow Rate {m3/s}",
        "    0.9,                         !- Motor Efficiency",
        "    1.0,                         !- Motor In Airstream Fraction",
        "    ZoneEvapCool OA Inlet,       !- Air Inlet Node Name",
        "    ZoneEvapCool Fan outlet;     !- Air Outlet Node Name",
        " EvaporativeCooler:Indirect:WetCoil,",
        "   Indirect WetCoil EvapCooler,  !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Coil Maximum Efficiency",
        "    ,                            !- Coil Flow Ratio",
        "    55,                          !- Recirculating Water Pump Power Consumption {W}",
        "    1.0,                         !- Secondary Air Fan Flow Rate {m3/s}",
        "    0.7,                         !- Secondary Air Fan Total Efficiency",
        "    300,                         !- Secondary Air Fan Delta Pressure {Pa}",
        "    ZoneEvapCool Fan outlet,     !- Primary Air Inlet Node Name",
        "    ZoneEvapCool Inlet Node,     !- Primary Air Outlet Node Name",
        "    ,                            !- Control Type",
        "    ,                            !- Water Supply Storage Tank Name",
        "    Secondary OA inlet node;     !- Secondary Air Inlet Node Name",
        "    OutdoorAir:Node,",
        "    Secondary OA inlet node;     !- Name",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    Fans.GetFanInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetEvapInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetInputZoneEvaporativeCoolerUnit(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    OutAirNodeManager.SetOutAirNodes(self.state)
    self.state.dataGlobal.BeginEnvrnFlag = True
    self.state.dataZoneEquip.ZoneEquipInputsFilled = True
    var thisZoneEvapCooler = self.state.dataEvapCoolers.ZoneEvapUnit[self.UnitNum - 1]
    var thisEvapCooler = self.state.dataEvapCoolers.EvapCond[self.EvapCoolNum - 1]
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = thisZoneEvapCooler.UnitReliefNodeNum
    self.state.dataLoopNodes.Node.redimension(self.NumOfNodes)
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp = 24.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat = 0.0080
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat)
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Temp = self.state.dataEnvrn.OutDryBulbTemp
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].HumRat = self.state.dataEnvrn.OutHumRat
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat)
    self.state.dataLoopNodes.Node[thisEvapCooler.SecondaryInletNode - 1].Temp = self.state.dataEnvrn.OutDryBulbTemp
    self.state.dataLoopNodes.Node[thisEvapCooler.SecondaryInletNode - 1].HumRat = self.state.dataEnvrn.OutHumRat
    self.state.dataLoopNodes.Node[thisEvapCooler.SecondaryInletNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat)
    self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    self.state.dataZoneEquip.ZoneEquipList[0].EquipName[0] = thisZoneEvapCooler.Name
    EXPECT_EQ(Int(thisZoneEvapCooler.fanOp), Int(FanOp.Cycling))
    EXPECT_ENUM_EQ(thisZoneEvapCooler.ControlSchemeType, ControlType.ZoneTemperatureDeadBandOnOffCycling)
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    var FullSensibleOutput: Float64 = 0.0
    var FullLatentOutput: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    var HalfOfFullLoad: Float64 = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.500000, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)
    thisZoneEvapCooler.ControlSchemeType = ControlType.ZoneCoolingLoadOnOffCycling
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    PartLoadRatio = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    EXPECT_NEAR(FullSensibleOutput, SensOutputProvided, 0.01)
    EXPECT_NEAR(FullSensibleOutput, -thisZoneEvapCooler.UnitSensibleCoolingRate, 0.01)
    HalfOfFullLoad = 0.50 * FullSensibleOutput
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = HalfOfFullLoad
    EvaporativeCoolers.ControlZoneEvapUnitOutput(self.state, self.UnitNum, HalfOfFullLoad)
    EXPECT_NEAR(0.500000, thisZoneEvapCooler.UnitPartLoadRatio, 0.000001)
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, thisZoneEvapCooler.UnitPartLoadRatio, SensOutputProvided, LatOutputProvided)
    EXPECT_NEAR(HalfOfFullLoad, SensOutputProvided, 0.01)

@Test
def RHcontrol(self: ZoneHVACEvapCoolerUnitTest):
    var ActualZoneNum: Int = 1
    var ZoneEquipIndex: Int = 1
    var SensOutputProvided: Float64 = 0.0
    var LatOutputProvided: Float64 = 0.0
    var idf_objects: String = delimited_string([
        " ZoneHVAC:EvaporativeCoolerUnit,",
        "   ZoneEvapCooler Unit,          !- Name",
        "   ,                             !- Availability Schedule Name",
        "   ,                             !- Availability Manager List Name",
        "   ZoneEvapCool OA Inlet,        !- Outdoor Air Inlet Node Name",
        "   ZoneEvapCool Inlet Node,      !- Cooler Outlet Node Name",
        "   ZoneEvapCool Relief Node,     !- Zone Relief Air Node Name",
        "   Fan:OnOff,                    !- Supply Air Fan Object Type",
        "   ZoneEvapCool Supply Fan,      !- Supply Air Fan Name",
        "   1.0,                          !- Design Supply Air Flow Rate {m3/s}",
        "   BlowThrough,                  !- Fan Placement",
        "   ZoneTemperatureDeadbandOnOffCycling,  !- Cooler Unit Control Method",
        "   1.0,                          !- Throttling Range Temperature Difference {deltaC}",
        "   100.0,                        !- Cooling Load Control Threshold Heat Transfer Rate {W}",
        "   EvaporativeCooler:Direct:CelDekPad,  !- First Evaporative Cooler Object Type",
        "   Direct CelDekPad EvapCooler,  !- First Evaporative Cooler Object Name",
        "   ,",
        "   ,",
        "   ,",
        "   40;                           !- Shut Off Relative Humidity",
        " Fan:OnOff,",
        "    ZoneEvapCool Supply Fan,     !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.7,                         !- Fan Total Efficiency",
        "    300.0,                       !- Pressure Rise {Pa}",
        "    1.0,                         !- Maximum Flow Rate {m3/s}",
        "    0.9,                         !- Motor Efficiency",
        "    1.0,                         !- Motor In Airstream Fraction",
        "    ZoneEvapCool OA Inlet,       !- Air Inlet Node Name",
        "    ZoneEvapCool Fan outlet;     !- Air Outlet Node Name",
        " EvaporativeCooler:Direct:CelDekPad,",
        "    Direct CelDekPad EvapCooler, !- Name",
        "    ,                            !- Availability Schedule Name",
        "    0.6,                         !- Direct Pad Area {m2}",
        "    0.17,                        !- Direct Pad Depth {m}",
        "    55,                          !- Recirculating Water Pump Power Consumption {W}",
        "    ZoneEvapCool Fan outlet,     !- Air Inlet Node Name",
        "    ZoneEvapCool Inlet Node,     !- Air Outlet Node Name",
        "    ;                            !- Control Type",
        "    OutdoorAir:Node,",
        "    Secondary OA inlet node;     !- Name",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    Fans.GetFanInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetEvapInput(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    EvaporativeCoolers.GetInputZoneEvaporativeCoolerUnit(self.state)
    ASSERT_FALSE(self.ErrorsFound)
    OutAirNodeManager.SetOutAirNodes(self.state)
    self.state.dataGlobal.BeginEnvrnFlag = True
    self.state.dataZoneEquip.ZoneEquipInputsFilled = True
    var thisZoneEvapCooler = self.state.dataEvapCoolers.ZoneEvapUnit[self.UnitNum - 1]
    self.state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = thisZoneEvapCooler.UnitReliefNodeNum
    self.state.dataLoopNodes.Node.redimension(self.NumOfNodes)
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp = 24.0
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat = 0.0080
    self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat)
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Temp = self.state.dataEnvrn.OutDryBulbTemp
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].HumRat = self.state.dataEnvrn.OutHumRat
    self.state.dataLoopNodes.Node[thisZoneEvapCooler.OAInletNodeNum - 1].Enthalpy = Psychrometrics.PsyHFnTdbW(self.state.dataEnvrn.OutDryBulbTemp, self.state.dataEnvrn.OutHumRat)
    self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToHeatSP = 0.0
    self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].RemainingOutputReqToCoolSP = -15000.0
    self.state.dataZoneEquip.ZoneEquipList[0].EquipName[0] = thisZoneEvapCooler.Name
    EvaporativeCoolers.SimZoneEvaporativeCoolerUnit(self.state, thisZoneEvapCooler.Name, ActualZoneNum, SensOutputProvided, LatOutputProvided, ZoneEquipIndex)
    var FullSensibleOutput: Float64 = 0.0
    var FullLatentOutput: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    EvaporativeCoolers.CalcZoneEvapUnitOutput(self.state, self.UnitNum, PartLoadRatio, FullSensibleOutput, FullLatentOutput)
    var relativeHumidity: Float64 = 100.0 * Psychrometrics.PsyRhFnTdbWPb(self.state, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].Temp, self.state.dataLoopNodes.Node[self.state.dataZoneEquip.ZoneEquipConfig[0].ZoneNode - 1].HumRat, self.state.dataEnvrn.OutBaroPress, "CalcZoneEvaporativeCoolerUnit")
    EXPECT_EQ(thisZoneEvapCooler.ShutOffRelativeHumidity, 40)
    ASSERT_TRUE(relativeHumidity > thisZoneEvapCooler.ShutOffRelativeHumidity)
    EXPECT_FALSE(thisZoneEvapCooler.IsOnThisTimestep)