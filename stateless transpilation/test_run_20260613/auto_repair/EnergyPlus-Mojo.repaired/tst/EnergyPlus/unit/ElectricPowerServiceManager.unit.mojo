from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_EQ, EXPECT_NEAR, ASSERT_TRUE, ASSERT_THROW, ASSERT_NEAR
from memory import unique_ptr, make_unique
from EnergyPlus.CurveManager import Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.ElectricPowerServiceManager import (
    ElectPowerLoadCenter,
    ElectricStorage,
    DCtoACInverter,
    ElectricTransformer,
    createFacilityElectricPowerServiceObject,
    checkUserEfficiencyInput,
    checkChargeDischargeVoltageCurves,
)
from EnergyPlus.General import General
from EnergyPlus.ScheduleManager import Sched
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, delimited_string, compare_err_stream
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.Constant import Constant

using EnergyPlus

@fixture
class EnergyPlusFixture(TestFixture):
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def setup(inout self):
        self.state.init_state(self.state)

    def teardown(inout self):

def test_ManageElectricPowerTest_BatteryDischargeTest(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "ElectricLoadCenter:Distribution,",
        "    PV Array Load Center,    !- Name",
        "    Generator List,          !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    DirectCurrentWithInverterDCStorage,  !- Electrical Buss Type",
        "    PV Inverter,             !- Inverter Object Name",
        "    Kibam;                   !- Electrical Storage Object Name",
        "  Curve:DoubleExponentialDecay,",
        "    Doubleexponential,       !- Name",
        "    1380,                    !- Coefficient1 C1",
        "    6834,                    !- Coefficient2 C2",
        "    -8.75,                   !- Coefficient3 C3",
        "    6747,                    !- Coefficient4 C4",
        "    -6.22,                   !- Coefficient5 C5",
        "    0,                       !- Minimum Value of x",
        "    1,                       !- Maximum Value of x",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Dimensionless,           !- Input Unit Type for x",
        "    Dimensionless;           !- Output Unit Type",
        "  ElectricLoadCenter:Storage:Battery,",
        "    Kibam,                   !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    ,                        !- Zone Name",
        "    0,                       !- Radiative Fraction",
        "    10,                      !- Number of Battery Modules in Parallel",
        "    10,                      !- Number of Battery Modules in Series",
        "    86.1,                    !- Maximum Module Capacity {Ah}",
        "    0.7,                     !- Initial Fractional State of Charge",
        "    0.37,                    !- Fraction of Available Charge Capacity",
        "    0.5874,                  !- Change Rate from Bound Charge to Available Charge {1/hr}",
        "    12.6,                    !- Fully Charged Module Open Circuit Voltage {V}",
        "    12.4,                    !- Fully Discharged Module Open Circuit Voltage {V}",
        "    charging,                !- Voltage Change Curve Name for Charging",
        "    discharging,             !- Voltage Change Curve Name for Discharging",
        "    0.054,                   !- Module Internal Electrical Resistance {ohms}",
        "    100,                     !- Maximum Module Discharging Current {A}",
        "    10,                      !- Module Cut-off Voltage {V}",
        "    1,                       !- Module Charge Rate Limit",
        "    Yes,                     !- Battery Life Calculation",
        "    5,                       !- Number of Cycle Bins",
        "    Doubleexponential;       !- Battery Life Curve Name",
        "  Curve:RectangularHyperbola2,",
        "    charging,                !- Name",
        "    -.2765,                  !- Coefficient1 C1",
        "    -93.27,                  !- Coefficient2 C2",
        "    0.0068,                  !- Coefficient3 C3",
        "    0,                       !- Minimum Value of x",
        "    1,                       !- Maximum Value of x",
        "    -100,                    !- Minimum Curve Output",
        "    100,                     !- Maximum Curve Output",
        "    Dimensionless,           !- Input Unit Type for x",
        "    Dimensionless;           !- Output Unit Type",
        "  Curve:RectangularHyperbola2,",
        "    discharging,             !- Name",
        "    0.0899,                  !- Coefficient1 C1",
        "    -98.24,                  !- Coefficient2 C2",
        "    -.0082,                  !- Coefficient3 C3",
        "    0,                       !- Minimum Value of x",
        "    1,                       !- Maximum Value of x",
        "    -100,                    !- Minimum Curve Output",
        "    100,                     !- Maximum Curve Output",
        "    Dimensionless,           !- Input Unit Type for x",
        "    Dimensionless;           !- Output Unit Type",
        "  ElectricLoadCenter:Inverter:LookUpTable,",
        "    PV Inverter,             !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    ,                        !- Zone Name",
        "    0.25,                    !- Radiative Fraction",
        "    14000,                   !- Rated Maximum Continuous Output Power {W}",
        "    200.0,                   !- Night Tare Loss Power {W}",
        "    368,                     !- Nominal Voltage Input {V}",
        "    0.839,                   !- Efficiency at 10% Power and Nominal Voltage",
        "    0.897,                   !- Efficiency at 20% Power and Nominal Voltage",
        "    0.916,                   !- Efficiency at 30% Power and Nominal Voltage",
        "    0.931,                   !- Efficiency at 50% Power and Nominal Voltage",
        "    0.934,                   !- Efficiency at 75% Power and Nominal Voltage",
        "    0.930;                   !- Efficiency at 100% Power and Nominal Voltage",
        "  ElectricLoadCenter:Generators,",
        "    Generator List,          !- Name",
        "    PV:ZN_1_FLR_1_SEC_1_Ceiling,  !- Generator 1 Name",
        "    Generator:Photovoltaic,  !- Generator 1 Object Type",
        "    9000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ;                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "  Generator:Photovoltaic,",
        "    PV:ZN_1_FLR_1_SEC_1_Ceiling,  !- Name",
        "    ZN_1_FLR_1_SEC_1_Ceiling,!- Surface Name",
        "    PhotovoltaicPerformance:Simple,  !- Photovoltaic Performance Object Type",
        "    20percentEffPVhalfArea,  !- Module Performance Name",
        "    Decoupled,               !- Heat Transfer Integration Mode",
        "    1.0,                     !- Number of Series Strings in Parallel {dimensionless}",
        "    1.0;                     !- Number of Modules in Series {dimensionless}",
        "  PhotovoltaicPerformance:Simple,",
        "    20percentEffPVhalfArea,  !- Name",
        "    0.5,                     !- Fraction of Surface Area with Active Solar Cells {dimensionless}",
        "    Fixed,                   !- Conversion Efficiency Input Mode",
        "    0.20,                    !- Value for Cell Efficiency if Fixed",
        "    ;                        !- Efficiency Schedule Name",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    var curve1: Curve.Curve = self.state.dataCurveManager.curves[0]  # 1-based -> 0-based
    var k: Float64 = 0.5874
    var c: Float64 = 0.37
    var qmax: Float64 = 86.1
    var E0c: Float64 = 12.6
    var InternalR: Float64 = 0.054
    var I0: Float64 = 0.159
    var T0: Float64 = 537.9
    var Volt: Float64 = 12.59
    var Pw: Float64 = 2.0
    var q0: Float64 = 60.2
    EXPECT_TRUE(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storageObj.determineCurrentForBatteryDischarge(
        self.state, I0, T0, Volt, Pw, q0, curve1, k, c, qmax, E0c, InternalR))
    I0 = -222.7
    T0 = -0.145
    Volt = 24.54
    Pw = 48000
    q0 = 0
    EXPECT_FALSE(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storageObj.determineCurrentForBatteryDischarge(
        self.state, I0, T0, Volt, Pw, q0, curve1, k, c, qmax, E0c, InternalR))

def test_ManageElectricPowerTest_UpdateLoadCenterRecords_Case1(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,    !- Name",
        "    Test Generator List,          !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    AlternatingCurrent,                  !- Electrical Buss Type",
        "    ,                        !- Inverter Object Name",
        "    ;                        !- Electrical Storage Object Name",
        "  ElectricLoadCenter:Generators,",
        "    Test Generator List,          !- Name",
        "    Test Gen 1,  !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,  !- Generator 2 Name",
        "    Generator:WindTurbine,  !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].bussType = ElectPowerLoadCenter.ElectricBussType.ACBuss
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electProdRate = 1000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electProdRate = 2000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electricityProd = 1000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electricityProd = 2000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermProdRate = 500.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermProdRate = 750.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermalProd = 500.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermalProd = 750.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectProdRate, 3000.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectricProd, 3000.0 * 3600.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].thermalProdRate, 1250.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].thermalProd, 1250.0 * 3600.0, 0.1)

def test_ManageElectricPowerTest_UpdateLoadCenterRecords_Case2(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,        !- Name",
        "    Test Generator List,     !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    AlternatingCurrentWithStorage,                  !- Electrical Buss Type",
        "     ,                        !- Inverter Object Name",
        "    Test Storage Bank;       !- Electrical Storage Object Name",
        "  ElectricLoadCenter:Storage:Simple,",
        "    Test Storage Bank,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 , !- Nominal Energetic Efficiency for Charging",
        "    1.0,  !- Nominal Discharging Energetic efficiency",
        "    1.0E9, !- Maximum storage capacity",
        "    5000.0, !- Maximum Power for Discharging",
        "    5000.0, !- Maximum Power for Charging",
        "    1.0E9; !- initial stat of charge",
        "  ElectricLoadCenter:Generators,",
        "    Test Generator List,     !- Name",
        "    Test Gen 1,              !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,              !- Generator 2 Name",
        "    Generator:WindTurbine,   !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].bussType = ElectPowerLoadCenter.ElectricBussType.ACBussStorage
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storageObj = make_unique[ElectricStorage](self.state, "TEST STORAGE BANK")
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electProdRate = 1000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electProdRate = 2000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electricityProd = 1000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electricityProd = 2000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermProdRate = 500.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermProdRate = 750.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermalProd = 500.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermalProd = 750.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storOpCVDischargeRate = 200.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storOpCVChargeRate = 150.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectProdRate, 3000.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectricProd, 3000.0 * 3600.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelFeedInRate, 3050.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelDrawRate, 0.0, 0.1)

def test_ManageElectricPowerTest_UpdateLoadCenterRecords_Case3(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,        !- Name",
        "    Test Generator List,     !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    DirectCurrentWithInverter,    !- Electrical Buss Type",
        "    Test Inverter ,          !- Inverter Object Name",
        "    ,                        !- Electrical Storage Object Name",
        "    ,                        !- Transformer Object Name",
        "    ,                        !- Storage Operation Scheme",
        "    ,                        !- Storage Control Track Meter Name",
        "    ,                        !- Storage Converter Object Name",
        "    ,                        !- Maximum Storage State of Charge Fraction",
        "    ,                        !- Minimum Storage State of Charge Fraction",
        "    100000,                  !- Design Storage Control Charge Power",
        "    ,                        !- Storage Charge Power Fraction Schedule Name",
        "    100000,                  !- Design Storage Control Discharge Power",
        "    ,                        !- Storage Discharge Power Fraction Schedule Name",
        "    ,                        !- Storage Control Utility Demand Target",
        "    ;                        !- Storage Control Utility Demand Target Fraction Schedule Name  ",
        "  ElectricLoadCenter:Inverter:Simple,",
        "    Test Inverter,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 ; !- Inverter efficiency",
        "  ElectricLoadCenter:Generators,",
        "    Test Generator List,     !- Name",
        "    Test Gen 1,              !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,              !- Generator 2 Name",
        "    Generator:WindTurbine,   !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
    self.state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].bussType = ElectPowerLoadCenter.ElectricBussType.DCBussInverter
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj = make_unique[DCtoACInverter](self.state, "TEST INVERTER")
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterPresent = true
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electProdRate = 1000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electProdRate = 2000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electricityProd = 1000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electricityProd = 2000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj.simulate(self.state, 3000.0)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectProdRate, 3000.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectricProd, 3000.0 * 3600.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelFeedInRate, 3000.0, 0.1)

def test_ManageElectricPowerTest_UpdateLoadCenterRecords_Case4(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,        !- Name",
        "    Test Generator List,     !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    DirectCurrentWithInverterDCStorage,                  !- Electrical Buss Type",
        "    Test Inverter ,                        !- Inverter Object Name",
        "    Test Storage Bank,       !- Electrical Storage Object Name",
        "    ,                        !- Transformer Object Name",
        "    TrackFacilityElectricDemandStoreExcessOnSite,  !- Storage Operation Scheme",
        "    ,                        !- Storage Control Track Meter Name",
        "    ,                        !- Storage Converter Object Name",
        "    ,                        !- Maximum Storage State of Charge Fraction",
        "    ,                        !- Minimum Storage State of Charge Fraction",
        "    100000,                  !- Design Storage Control Charge Power",
        "    ,                        !- Storage Charge Power Fraction Schedule Name",
        "    100000,                  !- Design Storage Control Discharge Power",
        "    ,                        !- Storage Discharge Power Fraction Schedule Name",
        "    ,                        !- Storage Control Utility Demand Target",
        "    ;                        !- Storage Control Utility Demand Target Fraction Schedule Name  ",
        "  ElectricLoadCenter:Inverter:Simple,",
        "    Test Inverter,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 ; !- Inverter efficiency",
        "  ElectricLoadCenter:Storage:Simple,",
        "    Test Storage Bank,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 , !- Nominal Energetic Efficiency for Charging",
        "    1.0,  !- Nominal Discharging Energetic efficiency",
        "    1.0E9, !- Maximum storage capacity",
        "    5000.0, !- Maximum Power for Discharging",
        "    5000.0, !- Maximum Power for Charging",
        "    1.0E9; !- initial stat of charge",
        "  ElectricLoadCenter:Generators,",
        "    Test Generator List,     !- Name",
        "    Test Gen 1,              !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,              !- Generator 2 Name",
        "    Generator:WindTurbine,   !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
    self.state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].bussType = ElectPowerLoadCenter.ElectricBussType.DCBussInverterDCStorage
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj = make_unique[DCtoACInverter](self.state, "TEST INVERTER")
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterPresent = true
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electProdRate = 2000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electProdRate = 3000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electricityProd = 2000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electricityProd = 3000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj.simulate(self.state, 5000.0)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectProdRate, 5000.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].genElectricProd, 5000.0 * 3600.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelFeedInRate, 5000.0, 0.1)

def test_ManageElectricPowerTest_UpdateLoadCenterRecords_Case5(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,        !- Name",
        "    Test Generator List,     !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    0,                       !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    DirectCurrentWithInverterACStorage,                  !- Electrical Buss Type",
        "    Test Inverter ,                        !- Inverter Object Name",
        "    Test Storage Bank;       !- Electrical Storage Object Name",
        "  ElectricLoadCenter:Inverter:Simple,",
        "    Test Inverter,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 ; !- Inverter efficiency",
        "  ElectricLoadCenter:Storage:Simple,",
        "    Test Storage Bank,",
        "    CONSTANT-1.0, !- availability schedule",
        "    , !- zone name",
        "    , !- radiative fraction",
        "    1.0 , !- Nominal Energetic Efficiency for Charging",
        "    1.0,  !- Nominal Discharging Energetic efficiency",
        "    1.0E9, !- Maximum storage capacity",
        "    5000.0, !- Maximum Power for Discharging",
        "    5000.0, !- Maximum Power for Charging",
        "    1.0E9; !- initial stat of charge",
        "  ElectricLoadCenter:Generators,",
        "    Test Generator List,     !- Name",
        "    Test Gen 1,              !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,              !- Generator 2 Name",
        "    Generator:WindTurbine,   !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataGlobal.TimeStepsInHour = 1    # must initialize this to get schedules initialized
    self.state.dataGlobal.MinutesInTimeStep = 60 # must initialize this to get schedules initialized
    self.state.init_state(self.state)
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].bussType = ElectPowerLoadCenter.ElectricBussType.DCBussInverterACStorage
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj = make_unique[DCtoACInverter](self.state, "TEST INVERTER")
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterPresent = true
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storageObj = make_unique[ElectricStorage](self.state, "TEST STORAGE BANK")
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storOpCVDischargeRate = 200.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].storOpCVChargeRate = 150.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electProdRate = 2000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electProdRate = 3000.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].electricityProd = 2000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].electricityProd = 3000.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermProdRate = 500.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermProdRate = 750.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0].thermalProd = 500.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[1].thermalProd = 750.0 * 3600.0
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].inverterObj.simulate(self.state, 5000.0)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].updateLoadCenterGeneratorRecords(self.state)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelFeedInRate, 5050.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].subpanelDrawRate, 0.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].thermalProdRate, 1250.0, 0.1)
    EXPECT_NEAR(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].thermalProd, 1250.0 * 3600.0, 0.1)

def test_ManageElectricPowerTest_CheckOutputReporting(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  LoadProfile:Plant,",
        "    Campus Load Profile, !- Name",
        "    Node 41, !- Inlet Node Name",
        "    Node 42, !- Outlet Node Name",
        "    Campus output Load, !- Load Schedule Name",
        "    0.320003570569675, !- Peak Flow Rate{ m3 / s }",
        "    Campus output Flow Frac;         !- Flow Rate Fraction Schedule Name",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataHVACGlobal.TimeStepSys = 1.0
    self.state.dataHVACGlobal.TimeStepSysSec = 3600.0
    self.state.dataGlobal.TimeStepZoneSec = 3600.0
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    var SimElecCircuitsFlag: Bool = false
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.manageElectricPowerService(self.state, true, SimElecCircuitsFlag, false)
    EXPECT_TRUE(SimElecCircuitsFlag)
    EXPECT_EQ(self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].numGenerators, 0) # dummy generator has been added and report variables are available

def test_ManageElectricPowerTest_TransformerLossTest(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "  ElectricLoadCenter:Distribution,",
        "    Test Load Center,        !- Name",
        "    Generator List,          !- Generator List Name",
        "    TrackElectrical,         !- Generator Operation Scheme Type",
        "    10000.0,                 !- Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "    ,                        !- Track Schedule Name Scheme Schedule Name",
        "    ,                        !- Track Meter Scheme Meter Name",
        "    AlternatingCurrent,      !- Electrical Buss Type",
        "    Test Inverter,           !- Inverter Object Name",
        "    Test Storage Bank,       !- Electrical Storage Object Name",
        "    Transformer;             !- Transformer Object Name",
        "  ElectricLoadCenter:Inverter:Simple,",
        "    Test Inverter,",
        "    CONSTANT-1.0,               !- availability schedule",
        "    ,                        !- zone name",
        "    ,                        !- radiative fraction",
        "    1.0;                     !- Inverter efficiency",
        "  ElectricLoadCenter:Storage:Simple,",
        "    Test Storage Bank,",
        "    CONSTANT-1.0,               !- availability schedule",
        "    ,                        !- zone name",
        "    ,                        !- radiative fraction",
        "    1.0,                     !- Nominal Energetic Efficiency for Charging",
        "    1.0,                     !- Nominal Discharging Energetic efficiency",
        "    1.0E9,                   !- Maximum storage capacity",
        "    5000.0,                  !- Maximum Power for Discharging",
        "    5000.0,                  !- Maximum Power for Charging",
        "    1.0E9;                   !- initial stat of charge",
        "  ElectricLoadCenter:Generators,",
        "    Generator List,          !- Name",
        "    Test Gen 1,              !- Generator 1 Name",
        "    Generator:InternalCombustionEngine,  !- Generator 1 Object Type",
        "    1000.0,                  !- Generator 1 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 1 Availability Schedule Name",
        "    ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "    Test Gen 2,              !- Generator 2 Name",
        "    Generator:WindTurbine,   !- Generator 2 Object Type",
        "    2000.0,                  !- Generator 2 Rated Electric Power Output {W}",
        "    CONSTANT-1.0,               !- Generator 2 Availability Schedule Name",
        "    ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
        "  ElectricLoadCenter:Transformer,",
        "    Transformer,             !- Name",
        "    CONSTANT-1.0,               !- Availability Schedule Name",
        "    PowerOutToGrid,          !- Transformer Usage",
        "    ,                        !- Zone Name",
        "    ,                        !- Radiative Fraction",
        "    ,                        !- Rated Capacity {VA}",
        "    3,                       !- Phase",
        "    Aluminum,                !- Conductor Material",
        "    150,                     !- Full Load Temperature Rise {C}",
        "    0.1,                     !- Fraction of Eddy Current Losses",
        "    RatedLosses,             !- Performance Input Method",
        "    300,                     !- Rated No Load Loss {W}",
        "    2000,                    !- Rated Load Loss {W}",
        "    ,                        !- Nameplate Efficiency",
        "    ,                        !- Per Unit Load for Nameplate Efficiency",
        "    ,                        !- Reference Temperature for Nameplate Efficiency {C}",
        "    ,                        !- Per Unit Load for Maximum Efficiency",
        "    ;                        !- Consider Transformer Loss for Utility Cost",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.init_state(self.state)
    self.state.dataGlobal.HourOfDay = 1
    self.state.dataGlobal.TimeStep = 1
    self.state.dataEnvrn.Month = 1
    self.state.dataEnvrn.DayOfMonth = 21
    self.state.dataHVACGlobal.TimeStepSys = 1.0
    self.state.dataHVACGlobal.TimeStepSysSec = self.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    self.state.dataEnvrn.DSTIndicator = 0
    self.state.dataEnvrn.DayOfWeek = 2
    self.state.dataEnvrn.HolidayIndex = 0
    self.state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(self.state.dataEnvrn.Month, self.state.dataEnvrn.DayOfMonth, 1)
    Sched.UpdateScheduleVals(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].transformerObj = make_unique[ElectricTransformer](self.state, "TRANSFORMER")
    var expectedtransformerObjLossRate: Float64 = self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].transformerObj.getLossRateForOutputPower(self.state, 2000.0)
    EXPECT_EQ(expectedtransformerObjLossRate, 0.0)

def test_ElectricLoadCenter_WarnAvailabilitySchedule_Photovoltaic_Simple(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "ElectricLoadCenter:Distribution,",
        "  PV Electric Load Center, !- Name",
        "  PV Generator List,       !- Generator List Name",
        "  Baseload,                !- Generator Operation Scheme Type",
        "  0,                       !- Generator Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "  ,                        !- Generator Track Schedule Name Scheme Schedule Name",
        "  ,                        !- Generator Track Meter Scheme Meter Name",
        "  DirectCurrentWithInverter,  !- Electrical Buss Type",
        "  Simple Ideal Inverter;   !- Inverter Name",
        "ElectricLoadCenter:Inverter:Simple,",
        "  Simple Ideal Inverter,   !- Name",
        "  PV_ON,                   !- Availability Schedule Name",
        "  ,                        !- Zone Name",
        "  0.0,                     !- Radiative Fraction",
        "  1.0;                     !- Inverter Efficiency",
        "ScheduleTypeLimits,",
        "  OnOff,                   !- Name",
        "  0,                       !- Lower Limit Value",
        "  1,                       !- Upper Limit Value",
        "  Discrete;                !- Numeric Type",
        "Schedule:Compact,",
        "  PV_ON,                   !- Name",
        "  OnOff,                   !- Schedule Type Limits Name",
        "  Through: 12/31,          !- Field 1",
        "  For: AllDays,            !- Field 2",
        "  Until: 11:00,            !- Field 3",
        "  0.0,                     !- Field 4",
        "  Until: 15:00,            !- Field 5",
        "  1.0,                     !- Field 6",
        "  Until: 24:00,            !- Field 7",
        "  0.0;                     !- Field 8",
        "ElectricLoadCenter:Generators,",
        "  PV Generator List,       !- Name",
        "  SimplePV,                !- Generator 1 Name",
        "  Generator:Photovoltaic,  !- Generator 1 Object Type",
        "  20000,                   !- Generator 1 Rated Electric Power Output {W}",
        "  PV_ON,                   !- Generator 1 Availability Schedule Name",
        "  ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "  SimplePV2,               !- Generator 2 Name",
        "  Generator:Photovoltaic,  !- Generator 2 Object Type",
        "  20000,                   !- Generator 2 Rated Electric Power Output {W}",
        "  ,                        !- Generator 2 Availability Schedule Name",
        "  ,                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
        "  TRNSYSPV INTEGRATED PV,  !- Generator 3 Name",
        "  Generator:Photovoltaic,  !- Generator 3 Object Type",
        "  20000,                   !- Generator 3 Rated Electric Power Output {W}",
        "  ,                        !- Generator 3 Availability Schedule Name",
        "  ;                        !- Generator 3 Rated Thermal to Electrical Power Ratio",
        "Shading:Site:Detailed,",
        "  FlatSurface,             !- Name",
        "  ,                        !- Transmittance Schedule Name",
        "  4,                       !- Number of Vertices",
        "  40.0,2.0,0.0,  !- X,Y,Z ==> Vertex 1 {m}",
        "  40.0,0.00,0.0,  !- X,Y,Z ==> Vertex 2 {m}",
        "  45.0,0.00,0.0,  !- X,Y,Z ==> Vertex 3 {m}",
        "  45.0,2.0,0.0;  !- X,Y,Z ==> Vertex 4 {m}",
        "PhotovoltaicPerformance:Simple,",
        "  12percentEffPVFullArea,  !- Name",
        "  1.0,                     !- Fraction of Surface Area with Active Solar Cells {dimensionless}",
        "  Fixed,                   !- Conversion Efficiency Input Mode",
        "  0.12;                    !- Value for Cell Efficiency if Fixed",
        "Generator:Photovoltaic,",
        "  SimplePV,                !- Name",
        "  FlatSurface,             !- Surface Name",
        "  PhotovoltaicPerformance:Simple,  !- Photovoltaic Performance Object Type",
        "  12percentEffPVFullArea,  !- Module Performance Name",
        "  Decoupled,               !- Heat Transfer Integration Mode",
        "  1.0,                     !- Number of Series Strings in Parallel {dimensionless}",
        "  1.0;                     !- Number of Modules in Series {dimensionless}",
        "Generator:Photovoltaic,",
        "  SimplePV2,               !- Name",
        "  FlatSurface,             !- Surface Name",
        "  PhotovoltaicPerformance:Simple,  !- Photovoltaic Performance Object Type",
        "  12percentEffPVFullArea,  !- Module Performance Name",
        "  Decoupled,               !- Heat Transfer Integration Mode",
        "  1.0,                     !- Number of Series Strings in Parallel {dimensionless}",
        "  1.0;                     !- Number of Modules in Series {dimensionless}",
        "Generator:Photovoltaic,",
        "  TRNSYSPV INTEGRATED PV,  !- Name",
        "  FlatSurface,          !- Surface Name",
        "  PhotovoltaicPerformance:EquivalentOne-Diode,  !- Photovoltaic Performance Object Type",
        "  Example PV Model Inputs, !- Module Performance Name",
        "  IntegratedSurfaceOutsideFace,  !- Heat Transfer Integration Mode",
        "  3.0,                     !- Number of Series Strings in Parallel {dimensionless}",
        "  6.0;                     !- Number of Modules in Series {dimensionless}",
        "PhotovoltaicPerformance:EquivalentOne-Diode,",
        "  Example PV Model Inputs, !- Name",
        "  CrystallineSilicon,      !- Cell type",
        "  36,                      !- Number of Cells in Series {dimensionless}",
        "  0.63,                    !- Active Area {m2}",
        "  0.9,                     !- Transmittance Absorptance Product {dimensionless}",
        "  1.12,                    !- Semiconductor Bandgap {eV}",
        "  1000000,                 !- Shunt Resistance {ohms}",
        "  4.75,                    !- Short Circuit Current {A}",
        "  21.4,                    !- Open Circuit Voltage {V}",
        "  25.0,                    !- Reference Temperature {C}",
        "  1000.0,                  !- Reference Insolation {W/m2}",
        "  4.45,                    !- Module Current at Maximum Power {A}",
        "  17,                      !- Module Voltage at Maximum Power {V}",
        "  0.00065,                 !- Temperature Coefficient of Short Circuit Current {A/K}",
        "  -0.08,                   !- Temperature Coefficient of Open Circuit Voltage {V/K}",
        "  20,                      !- Nominal Operating Cell Temperature Test Ambient Temperature {C}",
        "  47,                      !- Nominal Operating Cell Temperature Test Cell Temperature {C}",
        "  800.0,                   !- Nominal Operating Cell Temperature Test Insolation {W/m2}",
        "  30.0,                    !- Module Heat Loss Coefficient {W/m2-K}",
        "  50000;                   !- Total Heat Capacity {J/m2-K}",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    var error_string: String = delimited_string([
        "   ** Warning ** GeneratorController constructor : GENERATOR:PHOTOVOLTAIC = SIMPLEPV",
        "   **   ~~~   ** Availability Schedule will be ignored (runs all the time).",
        "   **   ~~~   ** To limit this Generator:Photovoltaic's output, please use the Inverter's availability schedule instead.",
    ])
    EXPECT_TRUE(compare_err_stream(error_string, true))

def test_ElectricLoadCenter_WarnAvailabilitySchedule_PVWatts(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "ElectricLoadCenter:Distribution,",
        "  PVWatts Electric Load Center,  !- Name",
        "  PVWatts Generator List,  !- Generator List Name",
        "  Baseload,                !- Generator Operation Scheme Type",
        "  0,                       !- Generator Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "  ,                        !- Generator Track Schedule Name Scheme Schedule Name",
        "  ,                        !- Generator Track Meter Scheme Meter Name",
        "  DirectCurrentWithInverter,  !- Electrical Buss Type",
        "  PVWatts Inverter;        !- Inverter Name",
        "ElectricLoadCenter:Inverter:PVWatts,",
        "  PVWatts Inverter,        !- Name",
        "  1.10,                    !- DC to AC Size Ratio",
        "  0.96;                    !- Inverter Efficiency",
        "ScheduleTypeLimits,",
        "  OnOff,                   !- Name",
        "  0,                       !- Lower Limit Value",
        "  1,                       !- Upper Limit Value",
        "  Discrete;                !- Numeric Type",
        "Schedule:Compact,",
        "  PV_ON,                   !- Name",
        "  OnOff,                   !- Schedule Type Limits Name",
        "  Through: 12/31,          !- Field 1",
        "  For: AllDays,            !- Field 2",
        "  Until: 11:00,            !- Field 3",
        "  0.0,                     !- Field 4",
        "  Until: 15:00,            !- Field 5",
        "  1.0,                     !- Field 6",
        "  Until: 24:00,            !- Field 7",
        "  0.0;                     !- Field 8",
        "ElectricLoadCenter:Generators,",
        "  PVWatts Generator List,  !- Name",
        "  PVWatts1,                !- Generator 1 Name",
        "  Generator:PVWatts,       !- Generator 1 Object Type",
        "  4000,                    !- Generator 1 Rated Electric Power Output {W}",
        "  PV_ON,                   !- Generator 1 Availability Schedule Name",
        "  ,                        !- Generator 1 Rated Thermal to Electrical Power Ratio",
        "  PVWatts2,                !- Generator 2 Name",
        "  Generator:PVWatts,       !- Generator 2 Object Type",
        "  3000,                    !- Generator 2 Rated Electric Power Output {W}",
        "  ,                        !- Generator 2 Availability Schedule Name",
        "  ;                        !- Generator 2 Rated Thermal to Electrical Power Ratio",
        "Generator:PVWatts,",
        "  PVWatts1,                !- Name",
        "  5,                       !- PVWatts Version",
        "  4000,                    !- DC System Capacity {W}",
        "  Standard,                !- Module Type",
        "  FixedOpenRack,           !- Array Type",
        "  0.14,                    !- System Losses",
        "  TiltAzimuth,             !- Array Geometry Type",
        "  20,                      !- Tilt Angle {deg}",
        "  180;                     !- Azimuth Angle {deg}",
        "Generator:PVWatts,",
        "  PVWatts2,                !- Name",
        "  5,                       !- PVWatts Version",
        "  4000,                    !- DC System Capacity {W}",
        "  Standard,                !- Module Type",
        "  FixedOpenRack,           !- Array Type",
        "  0.14,                    !- System Losses",
        "  TiltAzimuth,             !- Array Geometry Type",
        "  20,                      !- Tilt Angle {deg}",
        "  180;                     !- Azimuth Angle {deg}",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    createFacilityElectricPowerServiceObject(self.state)
    self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs.append(ElectPowerLoadCenter(self.state, 1))
    var error_string: String = delimited_string([
        "   ** Warning ** GeneratorController constructor : GENERATOR:PVWATTS = PVWATTS1",
        "   **   ~~~   ** Availability Schedule will be ignored (runs all the time).",
    ])
    EXPECT_TRUE(compare_err_stream(error_string, true))

def test_Battery_LiIonNmc_Constructor(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "ElectricLoadCenter:Storage:LiIonNMCBattery,",
        "  Battery1,       !- Name",
        "  ,               !- Availability Schedule Name",
        "  ,               !- Zone Name",
        "  ,               !- Radiative Fraction",
        "  KandlerSmith,   !- Lifetime Model",
        "  139,            !- Number of Cells in Series",
        "  8,              !- Number of Strings in Parallel",
        "  0.95,           !- Initial Fractional State of Charge",
        "  ,               !- DC to DC Charging Efficiency",
        "  100,            !- Battery Mass",
        "  0.75,           !- Battery Surface Area",
        "  1500,           !- Battery Specific Heat Capacity",
        "  8.1;            !- Heat Transfer Coefficient Between Battery and Ambient",
        "ElectricLoadCenter:Storage:LiIonNMCBattery,",
        "  Battery2,       !- Name",
        "  ,               !- Availability Schedule Name",
        "  ,               !- Zone Name",
        "  ,               !- Radiative Fraction",
        "  None,           !- Lifetime Model",
        "  139,            !- Number of Cells in Series",
        "  10,             !- Number of Strings in Parallel",
        "  0.5,            !- Initial Fractional State of Charge",
        "  ,               !- DC to DC Charging Efficiency",
        "  100,            !- Battery Mass",
        "  0.75,           !- Battery Surface Area",
        "  ,               !- Battery Specific Heat Capacity",
        "  ,               !- Heat Transfer Coefficient Between Battery and Ambient",
        "  1,              !- Fully Charged Cell Voltage",
        "  2,              !- Cell Voltage at End of Exponential Zone",
        "  3,              !- Cell Voltage at End of Nominal Zone",
        "  ,               !- Default Nominal Cell Voltage",
        "  ,               !- Fully Charged Cell Capacity",
        "  0.9,            !- Fraction of Cell Capacity Removed at the End of Exponential Zone",
        "  0.8;            !- Fraction of Cell Capacity Removed at the End of Nominal Zone",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.init_state(self.state)
    var battery1: ElectricStorage = ElectricStorage(self.state, "Battery1")
    ASSERT_TRUE(Util.SameString(battery1.name(), "Battery1"))
    ASSERT_THROW(ElectricStorage(self.state, "Battery2"), EnergyPlus.FatalError)
    var error_string: String = delimited_string([
        "   ** Severe  ** ElectricStorage constructor ElectricLoadCenter:Storage:LiIonNMCBattery=\"BATTERY2\", invalid entry.",
        "   **   ~~~   ** Fully Charged Cell Voltage must be greater than Cell Voltage at End of Exponential Zone,",
        "   **   ~~~   ** which must be greater than Cell Voltage at End of Nominal Zone.",
        "   **   ~~~   ** Fully Charged Cell Voltage = 1.00000",
        "   **   ~~~   ** Cell Voltage at End of Exponential Zone = 2.00000",
        "   **   ~~~   ** Cell Voltage at End of Nominal Zone = 3.00000",
        "   ** Severe  ** ElectricStorage constructor ElectricLoadCenter:Storage:LiIonNMCBattery=\"BATTERY2\", invalid entry.",
        "   **   ~~~   ** Fraction of Cell Capacity Removed at the End of Nominal Zone must be greater than Fraction of Cell Capacity Removed at the End of Exponential Zone.",
        "   **   ~~~   ** Fraction of Cell Capacity Removed at the End of Exponential Zone = 0.90000",
        "   **   ~~~   ** Fraction of Cell Capacity Removed at the End of Nominal Zone = 0.80000",
        "   **  Fatal  ** ElectricStorage constructor Preceding errors terminate program.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=2",
        "   ..... Last severe error=ElectricStorage constructor ElectricLoadCenter:Storage:LiIonNMCBattery=\"BATTERY2\", invalid entry.",
    ])
    EXPECT_TRUE(compare_err_stream(error_string, true))

def test_Battery_LiIonNmc_Simulate(inout self: EnergyPlusFixture):
    var idf_objects: String = delimited_string([
        "ElectricLoadCenter:Storage:LiIonNMCBattery,",
        "  Battery1,       !- Name",
        "  ,               !- Availability Schedule Name",
        "  ,               !- Zone Name",
        "  ,               !- Radiative Fraction",
        "  KandlerSmith,   !- Lifetime Model",
        "  139,            !- Number of Cells in Series",
        "  8,              !- Number of Strings in Parallel",
        "  0.95,           !- Initial Fractional State of Charge",
        "  ,               !- DC to DC Charging Efficiency",
        "  100,            !- Battery Mass",
        "  0.75,           !- Battery Surface Area",
        "  ,               !- Battery Specific Heat Capacity",
        "  ;               !- Heat Transfer Coefficient Between Battery and Ambient",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    self.state.dataHVACGlobal.TimeStepSys = 0.25
    self.state.dataHVACGlobal.TimeStepSysSec = self.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    self.state.init_state(self.state)
    var battery: ElectricStorage = ElectricStorage(self.state, "Battery1")
    self.state.dataEnvrn.OutDryBulbTemp = 23.0
    var socMin: Float64 = 0.1
    var socMax: Float64 = 0.95
    var powerCharge: Float64 = 0.0
    var powerDischarge: Float64 = 3000.0
    var charging: Bool = false
    var discharging: Bool = true
    battery.simulate(self.state, powerCharge, powerDischarge, charging, discharging, socMax, socMin)
    ASSERT_NEAR(battery.storedPower(), 0.0, 0.1)
    ASSERT_NEAR(battery.storedEnergy(), 0.0, 0.1)
    ASSERT_NEAR(battery.drawnPower(), powerDischarge, 0.1)
    ASSERT_NEAR(battery.drawnEnergy(), powerDischarge * 15 * 60, 0.1)
    ASSERT_NEAR(battery.stateOfChargeFraction(), 0.90, 0.01)
    ASSERT_NEAR(battery.batteryTemperature(), 20.1, 0.1)
    self.state.dataHVACGlobal.SysTimeElapsed += self.state.dataHVACGlobal.TimeStepSys
    powerDischarge = 0.0
    powerCharge = 5000.0
    charging = true
    discharging = false
    battery.timeCheckAndUpdate(self.state)
    battery.simulate(self.state, powerCharge, powerDischarge, charging, discharging, socMax, socMin)
    ASSERT_NEAR(battery.storedPower(), 3148.85, 0.1)
    ASSERT_NEAR(battery.storedEnergy(), 2833963.14, 0.1)
    ASSERT_NEAR(battery.drawnPower(), 0.0, 0.1)
    ASSERT_NEAR(battery.drawnEnergy(), 0.0