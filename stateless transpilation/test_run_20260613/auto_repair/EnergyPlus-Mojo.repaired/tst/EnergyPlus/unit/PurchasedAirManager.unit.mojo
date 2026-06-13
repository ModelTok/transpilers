from testing import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import StdRhoAir
from EnergyPlus.DataHVACGlobals import SetptType, LimitType, HumControl, OpMode, HVAC
from EnergyPlus.DataHeatBalFanSys import zoneTstatSetpts, TempControlType
from EnergyPlus.DataHeatBalance import MassConservation, ZoneIntGain, spaceIntGain, spaceIntGainDevices, RefrigCaseCredit, AllocateHeatBalArrays, space
from EnergyPlus.DataLoopNodes import Node
from EnergyPlus.DataRuntimeLanguage import *
from EnergyPlus.DataSizing import FinalZoneSizing, ZoneEqSizing, CurZoneEqNum, CurSysNum, ZoneSizingRunDone
from EnergyPlus.DataSurfaces import SurfaceWindow
from EnergyPlus.DataZoneEnergyDemands import ZoneSysEnergyDemand, ZoneSysMoistureDemand, CurDeadBandOrSetback, DeadBandOrSetback
from EnergyPlus.DataZoneEquipment import ZoneEquipInputsFilled, ZoneEquipConfig
from EnergyPlus.EMSManager import CheckIfAnyEMS, GetEMSInput, ManageEMS, EMSManager
from EnergyPlus.HeatBalanceManager import GetZoneData
from EnergyPlus.Psychrometrics import PsyHFnTdbW
from EnergyPlus.PurchasedAirManager import PurchasedAirManager as PurchasedAirManagerModule, SizePurchasedAir, GetPurchasedAir, CalcPurchAirMixedAir, CalcPurchAirLoads, InitPurchasedAir, ReportPurchasedAir
from EnergyPlus.RuntimeLanguageProcessor import *
from EnergyPlus.ScheduleManager import Sched, GetScheduleAlwaysOn
from EnergyPlus.SizingManager import GetOARequirements
from EnergyPlus.ZoneEquipmentManager import GetZoneEquipment, ManageZoneEquipment
from EnergyPlus.ZonePlenum import ZoneRetPlenCond
from EnergyPlus.ZoneTempPredictorCorrector import zoneHeatBalance
from EnergyPlus.Constant import eFuel
from EnergyPlus.Autosizing import AutoSize
from EnergyPlus.ObjexxFCL import delimited_string, process_idf
from EnergyPlus.DataGlobal import TimeStepZone, DoWeathSim

var gtest_assertions: Dict[String, Bool] = dict()

def EXPECT_DOUBLE_EQ(expected: Float64, actual: Float64, msg: String = ""):
    if expected != actual:
        assert false, "EXPECT_DOUBLE_EQ failed: expected " + str(expected) + " but got " + str(actual) + " " + msg

def EXPECT_NEAR(expected: Float64, actual: Float64, tolerance: Float64, msg: String = ""):
    if abs(expected - actual) > tolerance:
        assert false, "EXPECT_NEAR failed: expected " + str(expected) + " but got " + str(actual) + " (tolerance " + str(tolerance) + ") " + msg

def EXPECT_EQ(left: AnyType, right: AnyType, msg: String = ""):
    if left != right:
        assert false, "EXPECT_EQ failed: " + str(left) + " != " + str(right) + " " + msg

def EXPECT_FALSE(condition: Bool, msg: String = ""):
    if condition:
        assert false, "EXPECT_FALSE failed: condition was true " + msg

def EXPECT_TRUE(condition: Bool, msg: String = ""):
    if not condition:
        assert false, "EXPECT_TRUE failed: condition was false " + msg

def EXPECT_ENUM_EQ(left: Int, right: Int, msg: String = ""):
    if left != right:
        assert false, "EXPECT_ENUM_EQ failed: " + str(left) + " != " + str(right) + " " + msg

def EXPECT_GT(left: AnyType, right: AnyType, msg: String = ""):
    if left <= right:
        assert false, "EXPECT_GT failed: " + str(left) + " <= " + str(right) + " " + msg

# ------------------------------------------------------------------------------
# EnergyPlusFixture base struct (minimal representation)
struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def SetUp(inout self):
        # Base setup - called by derived fixture
        self.state.dataHeatBalFanSys.zoneTstatSetpts = List[type(self.state.dataHeatBalFanSys.zoneTstatSetpts[0])](1)
        self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9
        self.state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 23.0
        self.state.dataSize.FinalZoneSizing = List[type(self.state.dataSize.FinalZoneSizing[0])](1)
        self.state.dataSize.ZoneEqSizing = List[type(self.state.dataSize.ZoneEqSizing[0])](1)
        self.state.dataSize.CurZoneEqNum = 1
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.ZoneEqSizing[self.state.dataSize.CurZoneEqNum - 1].SizingMethod = List[Int](25)
        self.state.dataSize.ZoneSizingRunDone = true
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand = List[type(self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0])](1)
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 1000.0
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].OutputRequiredToHeatingSP = 1000.0
        self.state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].OutputRequiredToCoolingSP = 2000.0
        self.state.dataZoneEnergyDemand.ZoneSysMoistureDemand = List[type(self.state.dataZoneEnergyDemand.ZoneSysMoistureDemand[0])](1)
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance = List[type(self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0])](1)
        self.state.dataHeatBal.MassConservation = List[type(self.state.dataHeatBal.MassConservation[0])](1)
        self.state.dataHeatBal.ZoneIntGain = List[type(self.state.dataHeatBal.ZoneIntGain[0])](1)
        self.state.dataHeatBal.spaceIntGain = List[type(self.state.dataHeatBal.spaceIntGain[0])](1)
        self.state.dataHeatBal.spaceIntGainDevices = List[type(self.state.dataHeatBal.spaceIntGainDevices[0])](1)
        self.state.dataSurface.SurfaceWindow = List[type(self.state.dataSurface.SurfaceWindow[0])](1)
        self.state.dataHeatBal.RefrigCaseCredit = List[type(self.state.dataHeatBal.RefrigCaseCredit[0])](1)
        self.state.dataHeatBalFanSys.TempControlType = List[type(self.state.dataHeatBalFanSys.TempControlType[0])](1)
        self.state.dataHeatBalFanSys.TempControlType[0] = 1  # HVAC::SetptType::SingleHeat -> 1 as placeholder
        self.state.dataZoneEnergyDemand.CurDeadBandOrSetback = List[Bool](1)
        self.state.dataZoneEnergyDemand.DeadBandOrSetback = List[Bool](1)
        self.state.dataZoneEnergyDemand.DeadBandOrSetback[0] = false
        self.state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.07
        self.state.dataZoneEquip.ZoneEquipInputsFilled = false

    def TearDown(inout self):
        # Base teardown

# ------------------------------------------------------------------------------
# ZoneIdealLoadsTest derived struct
struct ZoneIdealLoadsTest:
    var parent: EnergyPlusFixture
    var IdealLoadsSysNum: Int
    var NumNodes: Int
    var ErrorsFound: Bool

    def __init__(inout self):
        self.parent = EnergyPlusFixture()
        self.parent.SetUp()
        self.IdealLoadsSysNum = 1
        self.NumNodes = 1
        self.ErrorsFound = false

    def SetUp(inout self):
        self.parent.SetUp()
        var state = self.parent.state
        state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9
        state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 23.0
        state.dataSize.FinalZoneSizing = List[type(state.dataSize.FinalZoneSizing[0])](1)
        state.dataSize.ZoneEqSizing = List[type(state.dataSize.ZoneEqSizing[0])](1)
        state.dataSize.CurZoneEqNum = 1
        state.dataSize.CurSysNum = 0
        state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = List[Int](25)
        state.dataSize.ZoneSizingRunDone = true
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand = List[type(state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0])](1)
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 1000.0
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].OutputRequiredToHeatingSP = 1000.0
        state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].OutputRequiredToCoolingSP = 2000.0
        state.dataZoneEnergyDemand.ZoneSysMoistureDemand = List[type(state.dataZoneEnergyDemand.ZoneSysMoistureDemand[0])](1)
        state.dataZoneTempPredictorCorrector.zoneHeatBalance = List[type(state.dataZoneTempPredictorCorrector.zoneHeatBalance[0])](1)
        state.dataHeatBal.MassConservation = List[type(state.dataHeatBal.MassConservation[0])](1)
        state.dataHeatBal.ZoneIntGain = List[type(state.dataHeatBal.ZoneIntGain[0])](1)
        state.dataHeatBal.spaceIntGain = List[type(state.dataHeatBal.spaceIntGain[0])](1)
        state.dataHeatBal.spaceIntGainDevices = List[type(state.dataHeatBal.spaceIntGainDevices[0])](1)
        state.dataSurface.SurfaceWindow = List[type(state.dataSurface.SurfaceWindow[0])](1)
        state.dataHeatBal.RefrigCaseCredit = List[type(state.dataHeatBal.RefrigCaseCredit[0])](1)
        state.dataHeatBalFanSys.TempControlType = List[type(state.dataHeatBalFanSys.TempControlType[0])](1)
        state.dataHeatBalFanSys.TempControlType[0] = 1  # SingleHeat
        state.dataZoneEnergyDemand.CurDeadBandOrSetback = List[Bool](1)
        state.dataZoneEnergyDemand.DeadBandOrSetback = List[Bool](1)
        state.dataZoneEnergyDemand.DeadBandOrSetback[0] = false
        state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].airHumRat = 0.07
        state.dataZoneEquip.ZoneEquipInputsFilled = false

    def TearDown(inout self):
        self.parent.TearDown()

# ------------------------------------------------------------------------------
# Test functions
# Note: we use the test structs and call test logic inside functions
# to keep naming as close as possible.

def SizePurchasedAirTest_Test1():
    var test = EnergyPlusFixture()
    test.SetUp()
    var state = test.state
    var PurchAirNum: Int = 1
    state.dataSize.ZoneEqSizing = List[type(state.dataSize.ZoneEqSizing[0])](1)
    state.dataSize.CurZoneEqNum = 1
    state.dataEnvrn.StdRhoAir = 1.0  # Prevent divide by zero in Sizer
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = List[Int](24)
    state.dataSize.CurSysNum = 0
    state.dataSize.FinalZoneSizing = List[type(state.dataSize.FinalZoneSizing[0])](1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA = 0.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutTempAtHeatPeak = 5.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow = 1.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInTemp = 30.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneTempAtHeatPeak = 30.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesTemp = 80.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesHumRat = 0.008
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatMassFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow * state.dataEnvrn.StdRhoAir
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolCoilInTemp = 60.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutTempAtCoolPeak = 70.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].CoolDesTemp = 50.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].CoolDesHumRat = 0.008
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolCoilInHumRat = 0.010
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow * state.dataEnvrn.StdRhoAir
    state.dataPurchasedAirMgr.PurchAir = List[type(state.dataPurchasedAirMgr.PurchAir[0])](10)
    state.dataPurchasedAirMgr.PurchAirNumericFields = List[type(state.dataPurchasedAirMgr.PurchAirNumericFields[0])](10)
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames = List[String](8)
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[4] = "Maximum Heating Air Flow Rate"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[5] = "Maximum Sensible Heating Capacity"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[6] = "Maximum Cooling Air Flow Rate"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[7] = "Maximum Total Cooling Capacity"
    state.dataSize.ZoneSizingRunDone = true
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].HeatingLimit = 2  # LimitType::FlowRateAndCapacity
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatVolFlowRate = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatSensCap = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].CoolingLimit = 2  # LimitType::FlowRateAndCapacity
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolVolFlowRate = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolTotCap = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].cObjectName = "ZONEHVAC:IDEALLOADSAIRSYSTEM"
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].Name = "Ideal Loads 1"
    SizePurchasedAir(state, PurchAirNum)
    EXPECT_DOUBLE_EQ(1.0, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatVolFlowRate)
    EXPECT_NEAR(50985.58, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatSensCap, 0.1)
    EXPECT_DOUBLE_EQ(2.0, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolVolFlowRate)
    EXPECT_NEAR(30844.14, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolTotCap, 0.1)
    test.TearDown()

def SizePurchasedAirTest_Test2():
    var test = EnergyPlusFixture()
    test.SetUp()
    var state = test.state
    var PurchAirNum: Int = 1
    state.dataSize.ZoneEqSizing = List[type(state.dataSize.ZoneEqSizing[0])](1)
    state.dataSize.CurZoneEqNum = 1
    state.dataEnvrn.StdRhoAir = 1.0  # Prevent divide by zero in Sizer
    state.dataSize.ZoneEqSizing[state.dataSize.CurZoneEqNum - 1].SizingMethod = List[Int](24)
    state.dataSize.CurSysNum = 0
    state.dataSize.FinalZoneSizing = List[type(state.dataSize.FinalZoneSizing[0])](1)
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].MinOA = 0.5
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutTempAtHeatPeak = 5.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow = 1.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatCoilInTemp = 30.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].ZoneTempAtHeatPeak = 30.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesTemp = 80.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].HeatDesHumRat = 0.008
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatMassFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesHeatVolFlow * state.dataEnvrn.StdRhoAir
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = 2.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolCoilInTemp = 65.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].OutTempAtCoolPeak = 70.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].CoolDesTemp = 50.0
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].CoolDesHumRat = 0.008
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolCoilInHumRat = 0.010
    state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolMassFlow = state.dataSize.FinalZoneSizing[state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow * state.dataEnvrn.StdRhoAir
    state.dataPurchasedAirMgr.PurchAir = List[type(state.dataPurchasedAirMgr.PurchAir[0])](10)
    state.dataPurchasedAirMgr.PurchAirNumericFields = List[type(state.dataPurchasedAirMgr.PurchAirNumericFields[0])](10)
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames = List[String](8)
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[4] = "Maximum Heating Air Flow Rate"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[5] = "Maximum Sensible Heating Capacity"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[6] = "Maximum Cooling Air Flow Rate"
    state.dataPurchasedAirMgr.PurchAirNumericFields[PurchAirNum - 1].FieldNames[7] = "Maximum Total Cooling Capacity"
    state.dataSize.ZoneSizingRunDone = true
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].HeatingLimit = 2
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatVolFlowRate = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatSensCap = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].CoolingLimit = 2
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolVolFlowRate = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolTotCap = AutoSize
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].cObjectName = "ZONEHVAC:IDEALLOADSAIRSYSTEM"
    state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].Name = "Ideal Loads 1"
    SizePurchasedAir(state, PurchAirNum)
    EXPECT_DOUBLE_EQ(1.0, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatVolFlowRate)
    EXPECT_NEAR(63731.97, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxHeatSensCap, 0.1)
    EXPECT_DOUBLE_EQ(2.0, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolVolFlowRate)
    EXPECT_NEAR(41078.43, state.dataPurchasedAirMgr.PurchAir[PurchAirNum - 1].MaxCoolTotCap, 0.1)
    test.TearDown()

def IdealLoadsAirSystem_GetInput():
    var test = EnergyPlusFixture()
    test.SetUp()
    var state = test.state
    var idf_objects: String = delimited_string(
        "ZoneHVAC:IdealLoadsAirSystem,",
        "ZONE 1 Ideal Loads, !- Name",
        ", !- Availability Schedule Name",
        "ZONE 1 INLETS, !- Zone Supply Air Node Name",
        ", !- Zone Exhaust Air Node Name",
        ", !- System Inlet Air Node Name",
        "50, !- Maximum Heating Supply Air Temperature{ C }",
        "13, !- Minimum Cooling Supply Air Temperature{ C }",
        "0.015, !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "0.009, !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "NoLimit, !- Heating Limit",
        "autosize, !- Maximum Heating Air Flow Rate{ m3 / s }",
        ", !- Maximum Sensible Heating Capacity{ W }",
        "NoLimit, !- Cooling Limit",
        "autosize, !- Maximum Cooling Air Flow Rate{ m3 / s }",
        ", !- Maximum Total Cooling Capacity{ W }",
        ", !- Heating Availability Schedule Name",
        ", !- Cooling Availability Schedule Name",
        "ConstantSupplyHumidityRatio, !- Dehumidification Control Type",
        ", !- Cooling Sensible Heat Ratio{ dimensionless }",
        "ConstantSupplyHumidityRatio, !- Humidification Control Type",
        ", !- Design Specification Outdoor Air Object Name",
        ", !- Outdoor Air Inlet Node Name",
        ", !- Demand Controlled Ventilation Type",
        ", !- Outdoor Air Economizer Type",
        ", !- Heat Recovery Type",
        ", !- Sensible Heat Recovery Effectiveness{ dimensionless }",
        "; !- Latent Heat Recovery Effectiveness{ dimensionless }",
    )
    EXPECT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = true
    GetPurchasedAir(state)
    var PurchAir = state.dataPurchasedAirMgr.PurchAir
    EXPECT_EQ(PurchAir.size, 1)
    EXPECT_EQ(PurchAir[0].Name, "ZONE 1 IDEAL LOADS")
    EXPECT_EQ(PurchAir[0].MaxHeatSuppAirTemp, 50.0)
    EXPECT_EQ(PurchAir[0].MinCoolSuppAirTemp, 13.0)
    EXPECT_EQ(PurchAir[0].MaxHeatSuppAirHumRat, 0.015)
    EXPECT_EQ(PurchAir[0].MinCoolSuppAirHumRat, 0.009)
    EXPECT_ENUM_EQ(PurchAir[0].HeatingLimit, 0)  # LimitType::None
    EXPECT_ENUM_EQ(PurchAir[0].CoolingLimit, 0)  # LimitType::None
    EXPECT_ENUM_EQ(PurchAir[0].DehumidCtrlType, 2)  # HumControl::ConstantSupplyHumidityRatio
    EXPECT_ENUM_EQ(PurchAir[0].HumidCtrlType, 2)  # HumControl::ConstantSupplyHumidityRatio
    EXPECT_EQ(PurchAir[0].heatFuelEffSched, Sched.GetScheduleAlwaysOn(state))
    EXPECT_EQ(PurchAir[0].coolFuelEffSched, Sched.GetScheduleAlwaysOn(state))
    EXPECT_EQ(PurchAir[0].heatFuelEffSched.getCurrentVal(), 1.0)
    EXPECT_EQ(PurchAir[0].coolFuelEffSched.getCurrentVal(), 1.0)
    test.TearDown()

def IdealLoads_PlenumTest():
    var test = ZoneIdealLoadsTest()
    test.SetUp()
    var state = test.parent.state
    var idf_objects: String = delimited_string(
        "Zone,",
        "  EAST ZONE,                      !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "Zone,",
        "  PLENUM ZONE,                    !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "ZoneHVAC:IdealLoadsAirSystem,",
        "  ZONE 1 IDEAL LOADS,             !- Name",
        "  ,                               !- Availability Schedule Name",
        "  Zone Inlet Node,                !- Zone Supply Air Node Name",
        "  Zone Exhaust Node,              !- Zone Exhaust Air Node Name",
        "  Plenum Outlet Node,             !- System Inlet Air Node Name",
        "  50,                             !- Maximum Heating Supply Air Temperature{ C }",
        "  13,                             !- Minimum Cooling Supply Air Temperature{ C }",
        "  0.015,                          !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  0.009,                          !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  NoLimit,                        !- Heating Limit",
        "  autosize,                       !- Maximum Heating Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Sensible Heating Capacity{ W }",
        "  NoLimit,                        !- Cooling Limit",
        "  autosize,                       !- Maximum Cooling Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Total Cooling Capacity{ W }",
        "  ,                               !- Heating Availability Schedule Name",
        "  ,                               !- Cooling Availability Schedule Name",
        "  ConstantSupplyHumidityRatio,    !- Dehumidification Control Type",
        "  ,                               !- Cooling Sensible Heat Ratio{ dimensionless }",
        "  ConstantSupplyHumidityRatio,    !- Humidification Control Type",
        "  ,                               !- Design Specification Outdoor Air Object Name",
        "  ,                               !- Outdoor Air Inlet Node Name",
        "  ,                               !- Demand Controlled Ventilation Type",
        "  ,                               !- Outdoor Air Economizer Type",
        "  ,                               !- Heat Recovery Type",
        "  ,                               !- Sensible Heat Recovery Effectiveness{ dimensionless }",
        "  ;                               !- Latent Heat Recovery Effectiveness{ dimensionless }",
        "ZoneHVAC:EquipmentConnections,",
        "  EAST ZONE,                      !- Zone Name",
        "  ZoneEquipment,                  !- Zone Conditioning Equipment List Name",
        "  Zone Inlet Node,                !- Zone Air Inlet Node or NodeList Name",
        "  Zone Exhaust Node,              !- Zone Air Exhaust Node or NodeList Name",
        "  Zone Node,                      !- Zone Air Node Name",
        "  Zone Outlet Node;               !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  ZoneEquipment,                  !- Name",
        "  SequentialLoad,                 !- Load Distribution Scheme",
        "  ZoneHVAC:IdealLoadsAirSystem,   !- Zone Equipment 1 Object Type",
        "  ZONE 1 IDEAL LOADS,             !- Zone Equipment 1 Name",
        "  1,                              !- Zone Equipment 1 Cooling Sequence",
        "  1;                              !- Zone Equipment 1 Heating or No - Load Sequence",
        "AirLoopHVAC:ReturnPlenum,",
        "  DOAS Zone Return Plenum,        !- Name",
        "  PLENUM ZONE,                    !- Zone Name",
        "  Plenum Node,                    !- Zone Node Name",
        "  Plenum Outlet Node,             !- Outlet Node Name",
        "  ,                               !- Induced Air Outlet Node or NodeList Name",
        "  Zone Exhaust Node;              !- Inlet 1 Node Name",
    )
    EXPECT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 1
    state.dataEnvrn.StdRhoAir = 1.0
    AllocateHeatBalArrays(state)
    EXPECT_FALSE(ErrorsFound)
    var FirstHVACIteration: Bool = true
    var SimZone: Bool = true
    var SimAir: Bool = false
    GetZoneEquipment(state)
    ManageZoneEquipment(state, FirstHVACIteration, SimZone, SimAir)
    var PurchAir = state.dataPurchasedAirMgr.PurchAir
    EXPECT_EQ(PurchAir[0].Name, "ZONE 1 IDEAL LOADS")
    EXPECT_EQ(PurchAir[0].ReturnPlenumIndex, 1)
    EXPECT_EQ(PurchAir[0].PlenumExhaustAirNodeNum, state.dataZonePlenum.ZoneRetPlenCond[0].OutletNode)
    EXPECT_EQ(PurchAir[0].ZoneSupplyAirNodeNum, state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0])
    EXPECT_EQ(PurchAir[0].ZoneExhaustAirNodeNum, state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0])
    EXPECT_EQ(state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0], state.dataZonePlenum.ZoneRetPlenCond[0].InletNode[0])
    EXPECT_GT(PurchAir[0].SupplyAirMassFlowRate, 0.0)
    EXPECT_EQ(PurchAir[0].SupplyAirMassFlowRate, state.dataLoopNodes.Node[PurchAir[0].ZoneSupplyAirNodeNum - 1].MassFlowRate)
    EXPECT_EQ(PurchAir[0].SupplyAirMassFlowRate, state.dataLoopNodes.Node[PurchAir[0].ZoneExhaustAirNodeNum - 1].MassFlowRate)
    EXPECT_EQ(PurchAir[0].SupplyAirMassFlowRate, state.dataLoopNodes.Node[PurchAir[0].PlenumExhaustAirNodeNum - 1].MassFlowRate)
    test.TearDown()

def IdealLoads_ExhaustNodeTest():
    var test = ZoneIdealLoadsTest()
    test.SetUp()
    var state = test.parent.state
    var idf_objects: String = delimited_string(
        "Zone,",
        "  EAST ZONE,                      !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "ZoneHVAC:IdealLoadsAirSystem,",
        "  ZONE 1 IDEAL LOADS,             !- Name",
        "  ,                               !- Availability Schedule Name",
        "  Zone Inlet Node,                !- Zone Supply Air Node Name",
        "  Zone Exhaust Node,              !- Zone Exhaust Air Node Name",
        "  ,             !- System Inlet Air Node Name",
        "  50,                             !- Maximum Heating Supply Air Temperature{ C }",
        "  13,                             !- Minimum Cooling Supply Air Temperature{ C }",
        "  0.015,                          !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  0.009,                          !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  NoLimit,                        !- Heating Limit",
        "  autosize,                       !- Maximum Heating Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Sensible Heating Capacity{ W }",
        "  NoLimit,                        !- Cooling Limit",
        "  autosize,                       !- Maximum Cooling Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Total Cooling Capacity{ W }",
        "  ,                               !- Heating Availability Schedule Name",
        "  ,                               !- Cooling Availability Schedule Name",
        "  ConstantSupplyHumidityRatio,    !- Dehumidification Control Type",
        "  ,                               !- Cooling Sensible Heat Ratio{ dimensionless }",
        "  ConstantSupplyHumidityRatio,    !- Humidification Control Type",
        "  ,                               !- Design Specification Outdoor Air Object Name",
        "  ,                               !- Outdoor Air Inlet Node Name",
        "  ,                               !- Demand Controlled Ventilation Type",
        "  ,                               !- Outdoor Air Economizer Type",
        "  ,                               !- Heat Recovery Type",
        "  ,                               !- Sensible Heat Recovery Effectiveness{ dimensionless }",
        "  ,                               !- Latent Heat Recovery Effectiveness{ dimensionless }",
        "  ,                               !- Design Specification ZoneHVAC Sizing Object Name }",
        "  DXHeatingCoilFuelEffSched,      !- Heating Fuel Efficiency Schedule Name",
        "  Electricity,                    !- Heating Fuel Type",
        "  DXCoolingCoilFuelEffSched,      !- Cooling Fuel Efficiency Schedule Name",
        "  Electricity;                    !- Cooling Fuel Type",
        "ZoneHVAC:EquipmentConnections,",
        "  EAST ZONE,                      !- Zone Name",
        "  ZoneEquipment,                  !- Zone Conditioning Equipment List Name",
        "  Zone Inlet Node,                !- Zone Air Inlet Node or NodeList Name",
        "  Zone Exhaust Node,              !- Zone Air Exhaust Node or NodeList Name",
        "  Zone Node,                      !- Zone Air Node Name",
        "  Zone Outlet Node;               !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  ZoneEquipment,                  !- Name",
        "  SequentialLoad,                 !- Load Distribution Scheme",
        "  ZoneHVAC:IdealLoadsAirSystem,   !- Zone Equipment 1 Object Type",
        "  ZONE 1 IDEAL LOADS,             !- Zone Equipment 1 Name",
        "  1,                              !- Zone Equipment 1 Cooling Sequence",
        "  1;                              !- Zone Equipment 1 Heating or No - Load Sequence",
        "AirLoopHVAC:ReturnPlenum,",
        "  DOAS Zone Return Plenum,        !- Name",
        "  PLENUM ZONE,                    !- Zone Name",
        "  Plenum Node,                    !- Zone Node Name",
        "  Plenum Outlet Node,             !- Outlet Node Name",
        "  ,                               !- Induced Air Outlet Node or NodeList Name",
        "  Zone Exhaust Node;              !- Inlet 1 Node Name",
        "  Schedule:Constant,",
        "    DXHeatingCoilFuelEffSched,    !- Name",
        "    AnyValue,                     !- Schedule Type Limits Name",
        "    2.0;                          !- Field 1",
        "  Schedule:Constant,",
        "    DXCoolingCoilFuelEffSched,    !- Name",
        "    AnyValue,                     !- Schedule Type Limits Name",
        "    3.0;                          !- Field 1",
    )
    EXPECT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 1
    state.dataEnvrn.StdRhoAir = 1.0
    AllocateHeatBalArrays(state)
    EXPECT_FALSE(ErrorsFound)
    var FirstHVACIteration: Bool = true
    var SimZone: Bool = true
    var SimAir: Bool = false
    GetZoneEquipment(state)
    ManageZoneEquipment(state, FirstHVACIteration, SimZone, SimAir)
    var PurchAir = state.dataPurchasedAirMgr.PurchAir[0]
    EXPECT_EQ(PurchAir.Name, "ZONE 1 IDEAL LOADS")
    EXPECT_EQ(PurchAir.SupplyAirMassFlowRate, state.dataLoopNodes.Node[PurchAir.ZoneSupplyAirNodeNum - 1].MassFlowRate)
    EXPECT_EQ(PurchAir.SupplyAirMassFlowRate, state.dataLoopNodes.Node[PurchAir.ZoneExhaustAirNodeNum - 1].MassFlowRate)
    EXPECT_ENUM_EQ(PurchAir.heatingFuelType, eFuel.Electricity)
    EXPECT_EQ(PurchAir.heatFuelEffSched.getCurrentVal(), 2.0)
    EXPECT_ENUM_EQ(PurchAir.coolingFuelType, eFuel.Electricity)
    EXPECT_EQ(PurchAir.coolFuelEffSched.getCurrentVal(), 3.0)
    test.TearDown()

def IdealLoads_IntermediateOutputVarsTest():
    var test = ZoneIdealLoadsTest()
    test.SetUp()
    var state = test.parent.state
    var idf_objects: String = delimited_string(
        "Zone,",
        "  EAST ZONE,                      !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "ZoneHVAC:IdealLoadsAirSystem,",
        "  ZONE 1 IDEAL LOADS,             !- Name",
        "  ,                               !- Availability Schedule Name",
        "  Zone Inlet Node,                !- Zone Supply Air Node Name",
        "  Zone Exhaust Node,              !- Zone Exhaust Air Node Name",
        "  ,                               !- System Inlet Air Node Name",
        "  50,                             !- Maximum Heating Supply Air Temperature{ C }",
        "  13,                             !- Minimum Cooling Supply Air Temperature{ C }",
        "  0.015,                          !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  0.009,                          !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  NoLimit,                        !- Heating Limit",
        "  autosize,                       !- Maximum Heating Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Sensible Heating Capacity{ W }",
        "  NoLimit,                        !- Cooling Limit",
        "  autosize,                       !- Maximum Cooling Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Total Cooling Capacity{ W }",
        "  ,                               !- Heating Availability Schedule Name",
        "  ,                               !- Cooling Availability Schedule Name",
        "  ConstantSupplyHumidityRatio,    !- Dehumidification Control Type",
        "  ,                               !- Cooling Sensible Heat Ratio{ dimensionless }",
        "  ConstantSupplyHumidityRatio,    !- Humidification Control Type",
        "  Office Outdoor Air Spec,        !- Design Specification Outdoor Air Object Name",
        "  ,                               !- Outdoor Air Inlet Node Name",
        "  ,                               !- Demand Controlled Ventilation Type",
        "  NoEconomizer,                   !- Outdoor Air Economizer Type",
        "  Sensible,                       !- Heat Recovery Type",
        "  0.7,                            !- Sensible Heat Recovery Effectiveness{ dimensionless }",
        "  0.65;                           !- Latent Heat Recovery Effectiveness{ dimensionless }",
        "DesignSpecification:OutdoorAir,",
        "  Office Outdoor Air Spec,        !- Name",
        "  Flow/Zone,                      !- Outdoor Air Method",
        "  0.0,                            !- Outdoor Air Flow per Person {m3/s-person}",
        "  0.00305,                        !- Outdoor Air Flow per Zone Floor Area {m3/s-m2}",
        "  0.0,                            !- Outdoor Air Flow per Zone {m3/s}",
        "  0.0,                            !- Outdoor Air Flow Air Changes per Hour {1/hr}",
        "  Min OA Sched;                   !- Outdoor Air Schedule Name",
        "Schedule:Compact,",
        "  Min OA Sched,                   !- Name",
        "  Fraction,                       !- Schedule Type Limits Name",
        "  Through: 12/31,                 !- Field 1",
        "  For: WeekDays CustomDay1 CustomDay2, !- Field 2",
        "  Until: 8:00,0.0,                !- Field 3",
        "  Until: 21:00,1.0,               !- Field 5",
        "  Until: 24:00,0.0,               !- Field 7",
        "  For: Weekends Holiday,          !- Field 9",
        "  Until: 24:00,0.0,               !- Field 10",
        "  For: SummerDesignDay,           !- Field 12",
        "  Until: 24:00,1.0,               !- Field 13",
        "  For: WinterDesignDay,           !- Field 15",
        "  Until: 24:00,1.0;               !- Field 16",
        "ZoneHVAC:EquipmentConnections,",
        "  EAST ZONE,                      !- Zone Name",
        "  ZoneEquipment,                  !- Zone Conditioning Equipment List Name",
        "  Zone Inlet Node,                !- Zone Air Inlet Node or NodeList Name",
        "  Zone Exhaust Node,              !- Zone Air Exhaust Node or NodeList Name",
        "  Zone Node,                      !- Zone Air Node Name",
        "  Zone Outlet Node;               !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  ZoneEquipment,                  !- Name",
        "  SequentialLoad,                 !- Load Distribution Scheme",
        "  ZoneHVAC:IdealLoadsAirSystem,   !- Zone Equipment 1 Object Type",
        "  ZONE 1 IDEAL LOADS,             !- Zone Equipment 1 Name",
        "  1,                              !- Zone Equipment 1 Cooling Sequence",
        "  1;                              !- Zone Equipment 1 Heating or No - Load Sequence",
        "AirLoopHVAC:ReturnPlenum,",
        "  DOAS Zone Return Plenum,        !- Name",
        "  PLENUM ZONE,                    !- Zone Name",
        "  Plenum Node,                    !- Zone Node Name",
        "  Plenum Outlet Node,             !- Outlet Node Name",
        "  ,                               !- Induced Air Outlet Node or NodeList Name",
        "  Zone Exhaust Node;              !- Inlet 1 Node Name",
    )
    EXPECT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 1
    state.dataEnvrn.StdRhoAir = 1.0
    AllocateHeatBalArrays(state)
    EXPECT_FALSE(ErrorsFound)
    var PurchAir = state.dataPurchasedAirMgr.PurchAir
    var FirstHVACIteration: Bool = true
    var SimZone: Bool = true
    var SimAir: Bool = false
    GetOARequirements(state)
    GetZoneEquipment(state)
    ManageZoneEquipment(state, FirstHVACIteration, SimZone, SimAir)
    EXPECT_EQ(PurchAir[0].Name, "ZONE 1 IDEAL LOADS")
    EXPECT_EQ(PurchAir[0].SupplyTemp, state.dataLoopNodes.Node[PurchAir[0].ZoneSupplyAirNodeNum - 1].Temp)
    EXPECT_EQ(PurchAir[0].SupplyHumRat, state.dataLoopNodes.Node[PurchAir[0].ZoneSupplyAirNodeNum - 1].HumRat)
    state.dataLoopNodes.Node[PurchAir[0].ZoneRecircAirNodeNum - 1].Temp = 24
    state.dataLoopNodes.Node[PurchAir[0].ZoneRecircAirNodeNum - 1].HumRat = 0.00929
    state.dataLoopNodes.Node[PurchAir[0].ZoneRecircAirNodeNum - 1].Enthalpy = PsyHFnTdbW(
        state.dataLoopNodes.Node[PurchAir[0].ZoneRecircAirNodeNum - 1].Temp, state.dataLoopNodes.Node[PurchAir[0].ZoneRecircAirNodeNum - 1].HumRat)
    state.dataLoopNodes.Node[PurchAir[0].OutdoorAirNodeNum - 1].Temp = 3
    state.dataLoopNodes.Node[PurchAir[0].OutdoorAirNodeNum - 1].HumRat = 0.004586
    state.dataLoopNodes.Node[PurchAir[0].OutdoorAirNodeNum - 1].Enthalpy = PsyHFnTdbW(
        state.dataLoopNodes.Node[PurchAir[0].OutdoorAirNodeNum - 1].Temp, state.dataLoopNodes.Node[PurchAir[0].OutdoorAirNodeNum - 1].HumRat)
    PurchAir[0].MixedAirTemp = 0
    PurchAir[0].MixedAirHumRat = 0
    var MixedAirEnthalpy: Float64 = 0
    var OAMassFlowRate: Float64 = 10
    var SupplyMassFlowRate: Float64 = 11
    CalcPurchAirMixedAir(state,
                         1,
                         OAMassFlowRate,
                         SupplyMassFlowRate,
                         PurchAir[0].MixedAirTemp,
                         PurchAir[0].MixedAirHumRat,
                         MixedAirEnthalpy,
                         2  # OpMode::Cool
    )
    EXPECT_EQ(PurchAir[0].MixedAirTemp, 4.9240554165264818)
    EXPECT_EQ(PurchAir[0].MixedAirHumRat, 0.0050136363636363633)
    test.TearDown()

def IdealLoads_EMSOverrideTest():
    var test = ZoneIdealLoadsTest()
    test.SetUp()
    var state = test.parent.state
    var idf_objects: String = delimited_string(
        "Zone,",
        "  EAST ZONE,                      !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "ZoneHVAC:IdealLoadsAirSystem,",
        "  ZONE 1 IDEAL LOADS,             !- Name",
        "  ,                               !- Availability Schedule Name",
        "  Zone Inlet Node,                !- Zone Supply Air Node Name",
        "  Zone Exhaust Node,              !- Zone Exhaust Air Node Name",
        "  ,             !- System Inlet Air Node Name",
        "  50,                             !- Maximum Heating Supply Air Temperature{ C }",
        "  13,                             !- Minimum Cooling Supply Air Temperature{ C }",
        "  0.015,                          !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  0.009,                          !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  NoLimit,                        !- Heating Limit",
        "  autosize,                       !- Maximum Heating Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Sensible Heating Capacity{ W }",
        "  NoLimit,                        !- Cooling Limit",
        "  autosize,                       !- Maximum Cooling Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Total Cooling Capacity{ W }",
        "  ,                               !- Heating Availability Schedule Name",
        "  ,                               !- Cooling Availability Schedule Name",
        "  ConstantSupplyHumidityRatio,    !- Dehumidification Control Type",
        "  ,                               !- Cooling Sensible Heat Ratio{ dimensionless }",
        "  ConstantSupplyHumidityRatio,    !- Humidification Control Type",
        "  ,                               !- Design Specification Outdoor Air Object Name",
        "  ,                               !- Outdoor Air Inlet Node Name",
        "  ,                               !- Demand Controlled Ventilation Type",
        "  ,                               !- Outdoor Air Economizer Type",
        "  ,                               !- Heat Recovery Type",
        "  ,                               !- Sensible Heat Recovery Effectiveness{ dimensionless }",
        "  ;                               !- Latent Heat Recovery Effectiveness{ dimensionless }",
        "ZoneHVAC:EquipmentConnections,",
        "  EAST ZONE,                      !- Zone Name",
        "  ZoneEquipment,                  !- Zone Conditioning Equipment List Name",
        "  Zone Inlet Node,                !- Zone Air Inlet Node or NodeList Name",
        "  Zone Exhaust Node,              !- Zone Air Exhaust Node or NodeList Name",
        "  Zone Node,                      !- Zone Air Node Name",
        "  Zone Outlet Node;               !- Zone Return Air Node Name",
        "ZoneHVAC:EquipmentList,",
        "  ZoneEquipment,                  !- Name",
        "  SequentialLoad,                 !- Load Distribution Scheme",
        "  ZoneHVAC:IdealLoadsAirSystem,   !- Zone Equipment 1 Object Type",
        "  ZONE 1 IDEAL LOADS,             !- Zone Equipment 1 Name",
        "  1,                              !- Zone Equipment 1 Cooling Sequence",
        "  1;                              !- Zone Equipment 1 Heating or No - Load Sequence",
        "  Output:EnergyManagementSystem,                                                                ",
        "    Verbose,                 !- Actuator Availability Dictionary Reporting                      ",
        "    Verbose,                 !- Internal Variable Availability Dictionary Reporting             ",
        "    Verbose;                 !- EMS Runtime Language Debug Output Level                         ",
        "EnergyManagementSystem:Actuator,",
        "Mdot,",
        "ZONE 1 IDEAL LOADS,",
        "Ideal Loads Air System,",
        "Air Mass Flow Rate;",
        "EnergyManagementSystem:Actuator,",
        "Tsupply,",
        "ZONE 1 IDEAL LOADS,",
        "Ideal Loads Air System,",
        "Air TEMPERATURE;",
        "EnergyManagementSystem:Sensor,",
        "ZoneAirTemp,",
        "EAST ZONE,",
        "Zone Mean Air Temperature;",
        "EnergyManagementSystem:OutputVariable,",
        "MassstromIdealLoad_EMS, ! - Name",
        "Mdot, ! - EMS Variable Name",
        "Averaged, ! - Type of Data in Variable",
        "SystemTimeStep; ! - Update Frequency",
        "EnergyManagementSystem:OutputVariable,",
        "SupplyTempIdealLoad_EMS, ! - Name",
        "Tsupply, ! - EMS Variable Name",
        "Averaged, ! - Type of Data in Variable",
        "SystemTimeStep; ! - Update Frequency",
        "EnergyManagementSystem:ProgramCallingManager,",
        "Test inside HVAC system iteration Loop,",
        "InsideHVACSystemIterationLoop,",
        "Test_InsideHVACSystemIterationLoop;",
        "EnergyManagementSystem:Program,",
        "Test_InsideHVACSystemIterationLoop,",
        "set Mdot = 0.1;",
    )
    EXPECT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = true
    var ErrorsFound: Bool = false
    GetZoneData(state, ErrorsFound)
    state.dataHeatBal.space[0].HTSurfaceFirst = 1
    state.dataHeatBal.space[0].HTSurfaceLast = 1
    state.dataEnvrn.StdRhoAir = 1.0
    AllocateHeatBalArrays(state)
    EXPECT_FALSE(ErrorsFound)
    state.dataZoneEquip.ZoneEquipConfig = List[type(state.dataZoneEquip.ZoneEquipConfig[0])](1)
    state.dataZoneEquip.ZoneEquipConfig[0].IsControlled = true
    state.dataZoneEquip.ZoneEquipConfig[0].NumInletNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode = List[Int](1)
    state.dataZoneEquip.ZoneEquipConfig[0].InletNode[0] = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode = List[Int](1)
    state.dataZoneEquip.ZoneEquipConfig[0].NumExhaustNodes = 1
    state.dataZoneEquip.ZoneEquipConfig[0].ExhaustNode[0] = 2
    state.dataGlobal.TimeStepZone = 0.25
    CheckIfAnyEMS(state)
    GetEMSInput(state)
    state.dataEMSMgr.FinishProcessingUserInput = true
    if state.dataPurchasedAirMgr.GetPurchAirInputFlag:
        GetPurchasedAir(state)
        state.dataPurchasedAirMgr.GetPurchAirInputFlag = false
    state.dataPurchasedAirMgr.PurchAir[0].EMSOverrideMdotOn = true
    state.dataPurchasedAirMgr.PurchAir[0].EMSOverrideSupplyTempOn = true
    state.dataLoopNodes.Node[1].Temp = 25.0
    state.dataLoopNodes.Node[1].HumRat = 0.001
    InitPurchasedAir(state, 1, 1)
    var SysOutputProvided: Float64
    var MoistOutputProvided: Float64
    CalcPurchAirLoads(state, 1, SysOutputProvided, MoistOutputProvided, 1)
    EXPECT_EQ(state.dataPurchasedAirMgr.PurchAir[0].EMSValueMassFlowRate, 0.0)
    EXPECT_EQ(state.dataPurchasedAirMgr.PurchAir[0].EMSValueSupplyTemp, 0.0)
    test.TearDown()

def IdealLoads_NoCapacityTest():
    var test = ZoneIdealLoadsTest()
    test.SetUp()
    var state = test.parent.state
    var idf_objects: String = delimited_string(
        "Zone,",
        "  EAST ZONE,                      !- Name",
        "  0,                              !- Direction of Relative North{ deg }",
        "  0,                              !- X Origin{ m }",
        "  0,                              !- Y Origin{ m }",
        "  0,                              !- Z Origin{ m }",
        "  1,                              !- Type",
        "  1,                              !- Multiplier",
        "  autocalculate,                  !- Ceiling Height{ m }",
        "  autocalculate;                  !- Volume{ m3 }",
        "ZoneHVAC:IdealLoadsAirSystem,",
        "  ZONE 1 IDEAL LOADS,             !- Name",
        "  ,                               !- Availability Schedule Name",
        "  Zone Inlet Node,                !- Zone Supply Air Node Name",
        "  Zone Exhaust Node,              !- Zone Exhaust Air Node Name",
        "  ,                               !- System Inlet Air Node Name",
        "  50,                             !- Maximum Heating Supply Air Temperature{ C }",
        "  13,                             !- Minimum Cooling Supply Air Temperature{ C }",
        "  0.015,                          !- Maximum Heating Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  0.009,                          !- Minimum Cooling Supply Air Humidity Ratio{ kgWater / kgDryAir }",
        "  LimitCapacity,                  !- Heating Limit",
        "  ,                               !- Maximum Heating Air Flow Rate{ m3 / s }",
        "  0,                              !- Maximum Sensible Heating Capacity{ W }",
        "  NoLimit,                        !- Cooling Limit",
        "  ,                               !- Maximum Cooling Air Flow Rate{ m3 / s }",
        "  ,                               !- Maximum Total Cooling Capacity{ W }",
        "  ,                               !- Heating Availability Schedule Name",
        "  ,                               !- Cooling Availability Schedule Name",
        "  ConstantSupplyHumidityRatio,    !- Dehumidification Control Type",
        "  ,                               !- Cooling Sensible Heat Ratio{ dimensionless }",
        "  ConstantSupplyHumidityRatio,    !- Humidification Control Type",
