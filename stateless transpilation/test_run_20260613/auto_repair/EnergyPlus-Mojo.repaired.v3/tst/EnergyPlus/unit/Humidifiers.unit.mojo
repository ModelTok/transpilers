from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string
from EnergyPlus.CurveManager import Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataSizing import DataSizing, FinalSysSizing, AutoSize
from EnergyPlus.DataWater import DataWater
from EnergyPlus.Humidifiers import HumidifierData, HumidType, GetHumidifierInput
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.Curve import Curve as CurveModule
from EnergyPlus.Constant import Constant
from EnergyPlus.Sched import Sched

# Test assertion helpers (faithful names)
def EXPECT_DOUBLE_EQ(expected: Float64, actual: Float64):
    assert expected == actual, "EXPECT_DOUBLE_EQ failed: expected " + str(expected) + " got " + str(actual)

def EXPECT_NEAR(expected: Float64, actual: Float64, tol: Float64):
    assert abs(expected - actual) <= tol, "EXPECT_NEAR failed: expected " + str(expected) + " got " + str(actual) + " tolerance " + str(tol)

def ASSERT_TRUE(cond: Bool):
    assert cond, "ASSERT_TRUE failed"

def ASSERT_EQ(expected: Int, actual: Int):
    assert expected == actual, "ASSERT_EQ failed: expected " + str(expected) + " got " + str(actual)

def EXPECT_EQ(expected: Int, actual: Int):
    assert expected == actual, "EXPECT_EQ failed: expected " + str(expected) + " got " + str(actual)

# Test cases
def Humidifiers_Sizing():
    var fixture = EnergyPlusFixture()
    fixture.state.init_state(fixture.state)
    fixture.state.dataSize.SysSizingRunDone = True
    fixture.state.dataSize.CurSysNum = 1
    fixture.state.dataHumidifiers.NumElecSteamHums = 0
    fixture.state.dataHumidifiers.NumGasSteamHums = 1
    fixture.state.dataHumidifiers.NumHumidifiers = 1
    var thisHum = HumidifierData()
    thisHum.HumType = HumidType.Gas
    thisHum.NomCapVol = 4.00e-5
    thisHum.NomPower = AutoSize
    thisHum.ThermalEffRated = 1.0
    thisHum.FanPower = 0.0
    thisHum.StandbyPower = 0.0
    thisHum.availSched = Sched.GetScheduleAlwaysOn(fixture.state)
    fixture.state.dataSize.FinalSysSizing = Array[FinalSysSizing](fixture.state.dataSize.CurSysNum)
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 30.0
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.090
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].DesMainVolFlow = 1.60894
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatMixHumRat = 0.05
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.07
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatSupHumRat = 0.10
    fixture.state.dataEnvrn.OutBaroPress = 101325.0
    thisHum.SizeHumidifier(fixture.state)
    EXPECT_DOUBLE_EQ(4.00e-5, thisHum.NomCapVol)
    EXPECT_DOUBLE_EQ(0.040000010708118504, thisHum.NomCap)
    EXPECT_DOUBLE_EQ(103710.42776358133, thisHum.NomPower)

def Humidifiers_AutoSizing():
    var fixture = EnergyPlusFixture()
    fixture.state.init_state(fixture.state)
    fixture.state.dataSize.SysSizingRunDone = True
    fixture.state.dataSize.CurSysNum = 1
    fixture.state.dataHumidifiers.NumElecSteamHums = 0
    fixture.state.dataHumidifiers.NumGasSteamHums = 1
    fixture.state.dataHumidifiers.NumHumidifiers = 1
    var thisHum = HumidifierData()
    thisHum.HumType = HumidType.Gas
    thisHum.NomCapVol = AutoSize
    thisHum.NomPower = AutoSize
    thisHum.ThermalEffRated = 0.80
    thisHum.FanPower = 0.0
    thisHum.StandbyPower = 0.0
    thisHum.availSched = Sched.GetScheduleAlwaysOn(fixture.state)
    fixture.state.dataSize.FinalSysSizing = Array[FinalSysSizing](fixture.state.dataSize.CurSysNum)
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 30.0
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.090
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].DesMainVolFlow = 1.60894
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatMixHumRat = 0.05
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.07
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatSupHumRat = 0.10
    fixture.state.dataEnvrn.OutBaroPress = 101325.0
    thisHum.NomCapVol = AutoSize
    fixture.state.dataSize.CurZoneEqNum = 0
    thisHum.SizeHumidifier(fixture.state)
    EXPECT_NEAR(8.185e-05, thisHum.NomCapVol, 1.0e-06)
    EXPECT_NEAR(0.0818, thisHum.NomCap, 1.0e-04)
    EXPECT_NEAR(265257.67, thisHum.NomPower, 1.0e-02)

def Humidifiers_EnergyUse():
    var fixture = EnergyPlusFixture()
    fixture.state.init_state(fixture.state)
    var thisHum = HumidifierData()
    fixture.state.dataHVACGlobal.TimeStepSys = 0.25
    fixture.state.dataHVACGlobal.TimeStepSysSec = fixture.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    fixture.state.dataSize.SysSizingRunDone = True
    fixture.state.dataSize.CurSysNum = 1
    fixture.state.dataHumidifiers.NumElecSteamHums = 0
    fixture.state.dataHumidifiers.NumGasSteamHums = 1
    fixture.state.dataHumidifiers.NumHumidifiers = 1
    fixture.state.dataHumidifiers.Humidifier = Array[HumidifierData](fixture.state.dataHumidifiers.NumGasSteamHums)
    thisHum.HumType = HumidType.Gas
    thisHum.NomCapVol = 4.00e-5
    thisHum.NomPower = 103710.0
    thisHum.ThermalEffRated = 1.0
    thisHum.FanPower = 0.0
    thisHum.StandbyPower = 0.0
    thisHum.availSched = Sched.GetScheduleAlwaysOn(fixture.state)
    fixture.state.dataSize.FinalSysSizing = Array[FinalSysSizing](fixture.state.dataSize.CurSysNum)
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 20.0
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.00089
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].DesMainVolFlow = 1.60894
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatMixHumRat = 0.05
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.07
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatSupHumRat = 0.10
    thisHum.NomCapVol = 4.00e-5
    thisHum.NomPower = 103710
    fixture.state.dataEnvrn.OutBaroPress = 101325.0
    thisHum.SizeHumidifier(fixture.state)
    EXPECT_DOUBLE_EQ(0.040000010708118504, thisHum.NomCap)
    EXPECT_DOUBLE_EQ(103710.42776358133, thisHum.NomPower)
    thisHum.AirInMassFlowRate = 1.8919
    thisHum.AirInTemp = 20.0
    thisHum.AirInEnthalpy = 25000.0
    thisHum.InletWaterTempOption = InletWaterTemp.Fixed
    thisHum.CurMakeupWaterTemp = 20.0
    fixture.state.dataEnvrn.OutBaroPress = 101325.0
    thisHum.CalcGasSteamHumidifier(fixture.state, 0.040000010708118504)
    EXPECT_DOUBLE_EQ(103710.42776358133, thisHum.GasUseRate)
    thisHum.ReportHumidifier(fixture.state)
    EXPECT_DOUBLE_EQ(93339384.987223208, thisHum.GasUseEnergy)
    thisHum.WaterTankDemandARRID = 1
    thisHum.WaterTankID = 1
    fixture.state.dataWaterData.WaterStorage = Array[WaterStorage](1)
    fixture.state.dataWaterData.WaterStorage[0].VdotRequestDemand = Array[Float64](1)
    fixture.state.dataWaterData.WaterStorage[0].VdotAvailDemand = Array[Float64](1)
    fixture.state.dataWaterData.WaterStorage[0].VdotAvailDemand[0] = 5.0e-5
    thisHum.SuppliedByWaterSystem = True
    thisHum.UpdateReportWaterSystem(fixture.state)
    EXPECT_NEAR(thisHum.WaterConsRate, thisHum.TankSupplyVdot, 1.0e-7)
    EXPECT_NEAR(0.00004, thisHum.TankSupplyVdot, 1.0e-7)
    EXPECT_NEAR(0.0, thisHum.StarvedSupplyVdot, 1.0e-7)
    EXPECT_NEAR(0.0, thisHum.StarvedSupplyVol, 1.0e-7)
    fixture.state.dataWaterData.WaterStorage[0].VdotAvailDemand[0] = 3.0e-5
    thisHum.UpdateReportWaterSystem(fixture.state)
    EXPECT_NEAR(0.00003, thisHum.TankSupplyVdot, 1.0e-7)
    EXPECT_NEAR(0.00001, thisHum.StarvedSupplyVdot, 1.0e-7)
    EXPECT_NEAR(0.009, thisHum.StarvedSupplyVol, 1.0e-7)

def Humidifiers_GetHumidifierInput():
    var fixture = EnergyPlusFixture()
    var idf_objects = delimited_string([
        "Humidifier:Steam:Gas,",
        "  Main Gas Humidifier,     !- Name",
        "  ,                        !- Availability Schedule Name",
        "  autosize,                !- Rated Capacity {m3/s}",
        "  autosize,                !- Rated Gas Use Rate {W}",
        "  0.80,                    !- Thermal Efficiency {-} ",
        "  ThermalEfficiencyFPLR,   !- Thermal Efficiency Modifier Curve Name",
        "  0,                       !- Rated Fan Power {W}",
        "  0,                       !- Auxiliary Electric Power {W}",
        "  Mixed Air Node 1,        !- Air Inlet Node Name",
        "  Main Humidifier Outlet Node,  !- Air Outlet Node Name",
        "  ;                        !- Water Storage Tank Name",
        "  Curve:Cubic,",
        "    ThermalEfficiencyFPLR,   !- Name",
        "    1.0,                     !- Coefficient1 Constant",
        "    0.0,                     !- Coefficient2 x",
        "    0.0,                     !- Coefficient3 x**2",
        "    0.0,                     !- Coefficient4 x**3",
        "    0.0,                     !- Minimum Value of x",
        "    1.5,                     !- Maximum Value of x",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Dimensionless,           !- Input Unit Type for X",
        "    Dimensionless;           !- Output Unit Type",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    GetHumidifierInput(fixture.state)
    ASSERT_EQ(1, fixture.state.dataHumidifiers.NumHumidifiers)
    EXPECT_EQ(1, fixture.state.dataHumidifiers.Humidifier[0].EfficiencyCurvePtr)

def Humidifiers_ThermalEfficiency():
    var fixture = EnergyPlusFixture()
    var thisHum = HumidifierData()
    fixture.state.dataHVACGlobal.TimeStepSys = 0.25
    fixture.state.dataHVACGlobal.TimeStepSysSec = fixture.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    fixture.state.dataSize.SysSizingRunDone = True
    fixture.state.dataSize.CurSysNum = 1
    fixture.state.dataHumidifiers.NumElecSteamHums = 0
    fixture.state.dataHumidifiers.NumGasSteamHums = 1
    fixture.state.dataHumidifiers.NumHumidifiers = 1
    fixture.state.dataHumidifiers.Humidifier = Array[HumidifierData](fixture.state.dataHumidifiers.NumGasSteamHums)
    thisHum.HumType = HumidType.Gas
    thisHum.NomCapVol = 4.00e-5
    thisHum.NomCap = 4.00e-2
    thisHum.NomPower = 103720.0
    thisHum.ThermalEffRated = 0.80
    thisHum.FanPower = 0.0
    thisHum.StandbyPower = 0.0
    thisHum.availSched = Sched.GetScheduleAlwaysOn(fixture.state)
    fixture.state.dataSize.FinalSysSizing = Array[FinalSysSizing](fixture.state.dataSize.CurSysNum)
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixTempAtCoolPeak = 20.0
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].MixHumRatAtCoolPeak = 0.00089
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].DesMainVolFlow = 1.60894
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatMixHumRat = 0.05
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].CoolSupHumRat = 0.07
    fixture.state.dataSize.FinalSysSizing[fixture.state.dataSize.CurSysNum - 1].HeatSupHumRat = 0.10
    thisHum.AirInMassFlowRate = 1.8919
    thisHum.AirInTemp = 20.0
    thisHum.AirInEnthalpy = 25000.0
    thisHum.InletWaterTempOption = InletWaterTemp.Fixed
    thisHum.CurMakeupWaterTemp = 20.0
    fixture.state.dataEnvrn.OutBaroPress = 101325.0
    var idf_objects = delimited_string([
        "  Curve:Quadratic,",
        "    ThermalEfficiencyFPLR,   !- Name",
        "    0.9375,                  !- Coefficient1 Constant",
        "    0.0625,                  !- Coefficient2 x",
        "    -7.0E-15,                !- Coefficient3 x**2",
        "    0.0,                     !- Minimum Value of x",
        "    1.2;                     !- Maximum Value of x",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    fixture.state.init_state(fixture.state)
    thisHum.EfficiencyCurvePtr = Curve.GetCurveIndex(fixture.state, "THERMALEFFICIENCYFPLR")
    thisHum.CalcGasSteamHumidifier(fixture.state, 0.030)
    EXPECT_NEAR(0.7875, thisHum.ThermalEff, 0.001)