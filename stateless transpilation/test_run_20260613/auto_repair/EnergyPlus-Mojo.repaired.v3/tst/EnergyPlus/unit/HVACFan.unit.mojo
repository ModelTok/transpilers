from testing import assert_approx_eq, assert_false, assert_true
from ..Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string
from ......EnergyPlus.CurveManager import CurveManager
from ......EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ......EnergyPlus.DataEnvironment import DataEnvironment
from ......EnergyPlus.DataSizing import DataSizing
from ......EnergyPlus.EMSManager import EMSManager, CheckIfAnyEMS, ManageEMS
from ......EnergyPlus.Fans import Fans

alias Real64 = Float64

# Dummy placeholder to mimic ObjexxFCL Optional_int_const
def Optional_int_const() -> None:
    return None

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def process_idf(self, idf_str: String) -> Bool:
        # Placeholder: actual implementation should parse IDF
        return True

    def init_state(self):
        self.state.init_state(self.state)

    # Test functions (each corresponds to a TEST_F)
    def SystemFanObj_TestGetFunctions1(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    1.0 ,                        !- Design Maximum Air Flow Rate",
            "    Discrete ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                       !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    AUTOSIZE,                    !- Design Electric Power Consumption",
            "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
            "    ,                            !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    0.50;                        !- Fan Total Efficiency",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)  # triggers sizing call
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate  # get function
        assert_approx_eq(locFanSizeVdot, 1.0000, 1e-8)
        let locDesignTempRise: Real64 = fanSystem.getDesignTemperatureRise(self.state)
        assert_approx_eq(locDesignTempRise, 0.166, 0.001)
        let locDesignHeatGain: Real64 = fanSystem.getDesignHeatGain(self.state, locFanSizeVdot)
        assert_approx_eq(locDesignHeatGain, 200.0, 0.1)
        assert_false(fanSystem.speedControl == Fans.SpeedControl.Continuous)

    def SystemFanObj_FanSizing1(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    AUTOSIZE ,                   !- Design Maximum Air Flow Rate",
            "    Discrete ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    75.0,                        !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    AUTOSIZE,                    !- Design Electric Power Consumption",
            "    TotalEfficiencyAndPressure,  !- Design Power Sizing Method",
            "    ,                            !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    0.50;                        !- Fan Total Efficiency",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        self.state.dataEnvrn.StdRhoAir = 1.0
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataSize.DataNonZoneNonAirloopValue = 1.00635
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)  # triggers sizing call
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate  # get function
        assert_approx_eq(locFanSizeVdot, 1.00635, 1e-5)
        self.state.dataSize.DataNonZoneNonAirloopValue = 0.0

    def SystemFanObj_TwoSpeedFanPowerCalc1(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    1.0 ,                        !- Design Maximum Air Flow Rate",
            "    Discrete ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                       !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    100.0,                    !- Design Electric Power Consumption",
            "    ,                      !- Design Power Sizing Method",
            "    ,                      !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                        !- Fan Total Efficiency",
            "  , !- Electric Power Function of Flow Fraction Curve Name",
            "  , !- Night Ventilation Mode Pressure Rise",
            "  , !- Night Ventilation Mode Flow Fraction",
            "  , !- Motor Loss Zone Name",
            "  , !- Motor Loss Radiative Fraction ",
            "  Fan Energy, !- End-Use Subcategory",
            "  2, !- Number of Speeds",
            "  0.5, !- Speed 1 Flow Fraction",
            "  0.125, !- Speed 1 Electric Power Fraction",
            "  1.0, !- Speed 2 Flow Fraction",
            "  1.0; !- Speed 2 Electric Power Fraction",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate  # get function
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        fanSystem.simulate(self.state, False, None, None, 0.75)  # call for flow fraction of 0.75
        let locFanElecPower: Real64 = fanSystem.totalPower
        let locExpectPower: Real64 = (0.5 * 0.125 * 100.0) + (0.5 * 1.0 * 100.0)
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        fanSystem.simulate(self.state, False, None, None, 0.5)  # call for flow fraction of 0.5
        locFanElecPower = fanSystem.totalPower
        locExpectPower = 0.125 * 100.0
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)

    def SystemFanObj_TwoSpeedFanPowerCalc2(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    1.0 ,                        !- Design Maximum Air Flow Rate",
            "    Discrete ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                       !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    100.0,                    !- Design Electric Power Consumption",
            "    ,                      !- Design Power Sizing Method",
            "    ,                      !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                        !- Fan Total Efficiency",
            "  simple cubic, !- Electric Power Function of Flow Fraction Curve Name",
            "  , !- Night Ventilation Mode Pressure Rise",
            "  , !- Night Ventilation Mode Flow Fraction",
            "  , !- Motor Loss Zone Name",
            "  , !- Motor Loss Radiative Fraction ",
            "  Fan Energy, !- End-Use Subcategory",
            "  2, !- Number of Speeds",
            "  0.5, !- Speed 1 Flow Fraction",
            "  , !- Speed 1 Electric Power Fraction",
            "  1.0, !- Speed 2 Flow Fraction",
            "  ; !- Speed 2 Electric Power Fraction",
            "  Curve:Cubic,",
            "    simple cubic,  !- Name",
            "    0.0,                    !- Coefficient1 Constant",
            "    0.0,                     !- Coefficient2 x",
            "    0.0,                     !- Coefficient3 x**2",
            "    1.0,                    !- Coefficient4 x**3",
            "    0.0,                     !- Minimum Value of x",
            "    1.0,                     !- Maximum Value of x",
            "    0.0,                     !- Minimum Curve Output",
            "    1.0,                     !- Maximum Curve Output",
            "    Dimensionless,           !- Input Unit Type for X",
            "    Dimensionless;           !- Output Unit Type",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        fanSystem.simulate(self.state, False, None, None, 0.75)  # call for flow fraction of 0.75
        let locFanElecPower: Real64 = fanSystem.totalPower
        let locExpectPower: Real64 = (0.5 * 0.125 * 100.0) + (0.5 * 1.0 * 100.0)
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        fanSystem.simulate(self.state, False, None, None, 0.5)  # call for flow fraction of 0.5
        locFanElecPower = self.state.dataFans.fans(1).totalPower  # Note: 1-based -> 0-based in title? Keep as is? Actually need to keep 1-based? but Mojo array is 0-based. Use subscript [0].
        # Original: state->dataFans->fans(1)->totalPower. In Mojo: self.state.dataFans.fans[0].totalPower
        locFanElecPower = self.state.dataFans.fans[0].totalPower
        locExpectPower = 0.125 * 100.0
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)

    def SystemFanObj_TwoSpeedFanPowerCalc3(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    1.0 ,                        !- Design Maximum Air Flow Rate",
            "    Discrete ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                       !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    100.0,                    !- Design Electric Power Consumption",
            "    ,                      !- Design Power Sizing Method",
            "    ,                      !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                        !- Fan Total Efficiency",
            "  , !- Electric Power Function of Flow Fraction Curve Name",
            "  , !- Night Ventilation Mode Pressure Rise",
            "  , !- Night Ventilation Mode Flow Fraction",
            "  , !- Motor Loss Zone Name",
            "  , !- Motor Loss Radiative Fraction ",
            "  Fan Energy, !- End-Use Subcategory",
            "  2, !- Number of Speeds",
            "  0.5, !- Speed 1 Flow Fraction",
            "  0.125, !- Speed 1 Electric Power Fraction",
            "  1.0, !- Speed 2 Flow Fraction",
            "  1.0; !- Speed 2 Electric Power Fraction",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate  # get function
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        let designMassFlowRate: Real64 = locFanSizeVdot * self.state.dataEnvrn.StdRhoAir
        let massFlow1: Real64 = 0.5 * designMassFlowRate
        let massFlow2: Real64 = designMassFlowRate
        let runTimeFrac1: Real64 = 0.5
        let runTimeFrac2: Real64 = 0.5
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        let locFanElecPower: Real64 = fanSystem.totalPower
        let locExpectPower: Real64 = (runTimeFrac1 * 0.125 * 100.0) + (runTimeFrac2 * 1.0 * 100.0)
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 0.75 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = fanSystem.designElecPower  # expect full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 0.85
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = 0.85 * fanSystem.designElecPower  # expect 85% of full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        fanSystem.simulate(self.state, False, None, None, None, massFlow2, runTimeFrac2, massFlow1, runTimeFrac1)
        locFanElecPower = fanSystem.totalPower
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)

    def SystemFanObj_TwoSpeedFanPowerCalc4(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,                   !- Name",
            "    ,                            !- Availability Schedule Name",
            "    TestFanAirInletNode,         !- Air Inlet Node Name",
            "    TestFanOutletNode,           !- Air Outlet Node Name",
            "    1.0 ,                        !- Design Maximum Air Flow Rate",
            "    Continuous ,                   !- Speed Control Method",
            "    0.0,                         !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                       !- Design Pressure Rise",
            "    0.9 ,                        !- Motor Efficiency",
            "    1.0 ,                        !- Motor In Air Stream Fraction",
            "    100.0,                    !- Design Electric Power Consumption",
            "    ,                      !- Design Power Sizing Method",
            "    ,                      !- Electric Power Per Unit Flow Rate",
            "    ,                            !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                        !- Fan Total Efficiency",
            "  simple cubic; !- Electric Power Function of Flow Fraction Curve Name",
            "  Curve:Cubic,",
            "    simple cubic,  !- Name",
            "    0.0,                    !- Coefficient1 Constant",
            "    0.0,                     !- Coefficient2 x",
            "    0.0,                     !- Coefficient3 x**2",
            "    1.0,                    !- Coefficient4 x**3",
            "    0.0,                     !- Minimum Value of x",
            "    1.0,                     !- Maximum Value of x",
            "    0.0,                     !- Minimum Curve Output",
            "    1.0,                     !- Maximum Curve Output",
            "    Dimensionless,           !- Input Unit Type for X",
            "    Dimensionless;           !- Output Unit Type",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        let designMassFlowRate: Real64 = locFanSizeVdot * self.state.dataEnvrn.StdRhoAir
        let massFlow1: Real64 = 0.5 * designMassFlowRate
        let massFlow2: Real64 = designMassFlowRate
        let runTimeFrac1: Real64 = 0.5
        let runTimeFrac2: Real64 = 0.5
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        var locFanElecPower: Real64 = fanSystem.totalPower
        var locExpectPower: Real64 = (0.5 * pow(0.5, 3) + 0.5 * 1.0) * fanSystem.designElecPower
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 0.75 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = pow(0.75, 3) * fanSystem.designElecPower
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = fanSystem.designElecPower  # expect full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 0.85
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = 0.85 * fanSystem.designElecPower  # expect 85% of full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)

    def SystemFanObj_FanEnergyIndex(self):
        var designFlow: Real64
        var designPower: Real64
        var designDeltaP: Real64
        var testFEI: Real64
        var expectedAnswer: Real64
        let allowedTolerance: Real64 = 0.001
        designFlow = 1.0
        designPower = 1000.0
        designDeltaP = 100.0
        expectedAnswer = 0.4892
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        designFlow = 1.0
        designPower = 0.0
        designDeltaP = 100.0
        expectedAnswer = 0.0
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        designFlow = 1.0
        designPower = -1000.0
        designDeltaP = 100.0
        expectedAnswer = 0.0
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        designFlow = 1.0
        designPower = 500.0
        designDeltaP = 100.0
        expectedAnswer = 0.9784
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        designFlow = 0.5
        designPower = 1000.0
        designDeltaP = 100.0
        expectedAnswer = 0.2990
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        designFlow = 1.0
        designPower = 1000.0
        designDeltaP = 50.0
        expectedAnswer = 0.3833
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        self.state.dataEnvrn.StdBaroPress = 82000.0
        designFlow = 1.0
        designPower = 1000.0
        designDeltaP = 100.0
        expectedAnswer = 0.4491
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)
        self.state.dataEnvrn.StdBaroPress = 82000.0
        designFlow = 100.0
        designPower = 5000000.0
        designDeltaP = 10000.0
        expectedAnswer = 0.3311
        testFEI = Fans.FanSystem.report_fei(self.state, designFlow, designPower, designDeltaP)
        assert_approx_eq(testFEI, expectedAnswer, allowedTolerance)

    def SystemFanObj_DiscreteMode_noPowerFFlowCurve(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan ,              !- Name",
            "    ,                       !- Availability Schedule Name",
            "    TestFanAirInletNode,    !- Air Inlet Node Name",
            "    TestFanOutletNode,      !- Air Outlet Node Name",
            "    1.0 ,                   !- Design Maximum Air Flow Rate",
            "    Discrete,               !- Speed Control Method",
            "    0.0,                    !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                  !- Design Pressure Rise",
            "    0.9 ,                   !- Motor Efficiency",
            "    1.0 ,                   !- Motor In Air Stream Fraction",
            "    100.0,                  !- Design Electric Power Consumption",
            "    ,                       !- Design Power Sizing Method",
            "    ,                       !- Electric Power Per Unit Flow Rate",
            "    ,                       !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                       !- Fan Total Efficiency",
            "    ;                       !- Electric Power Function of Flow Fraction Curve Name",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.2
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        let designMassFlowRate: Real64 = locFanSizeVdot * self.state.dataEnvrn.StdRhoAir
        var massFlow1: Real64 = 0.5 * designMassFlowRate
        var massFlow2: Real64 = designMassFlowRate
        var runTimeFrac1: Real64 = 0.5
        var runTimeFrac2: Real64 = 0.5
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        var locFanElecPower: Real64 = fanSystem.totalPower
        var locExpectPower: Real64 = (0.5 * 0.5 + 0.5 * 1.0) * fanSystem.designElecPower  # expect 75% of power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 0.75 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = (0.0 * 0.0 + 1.0 * 0.75) * fanSystem.designElecPower  # expect 75% of power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 1.0
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = (0.0 * 0.0 + 1.0 * 1.0) * fanSystem.designElecPower  # expect full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        massFlow1 = 0.0
        massFlow2 = 1.0 * designMassFlowRate
        runTimeFrac1 = 0.0
        runTimeFrac2 = 0.85
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = (0.0 * 0.25 + 0.85 * 1.0) * fanSystem.designElecPower  # expect 85% of full power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)

    def SystemFanObj_DiscreteMode_EMSPressureRiseResetTest(self):
        let idf_objects = delimited_string(
            "  Fan:SystemModel,",
            "    Test Fan,                       !- Name",
            "    ,                               !- Availability Schedule Name",
            "    TestFanAirInletNode,            !- Air Inlet Node Name",
            "    TestFanOutletNode,              !- Air Outlet Node Name",
            "    1.0 ,                           !- Design Maximum Air Flow Rate",
            "    Discrete,                       !- Speed Control Method",
            "    0.0,                            !- Electric Power Minimum Flow Rate Fraction",
            "    100.0,                          !- Design Pressure Rise",
            "    0.9 ,                           !- Motor Efficiency",
            "    1.0 ,                           !- Motor In Air Stream Fraction",
            "    100.0,                          !- Design Electric Power Consumption",
            "    ,                               !- Design Power Sizing Method",
            "    ,                               !- Electric Power Per Unit Flow Rate",
            "    ,                               !- Electric Power Per Unit Flow Rate Per Unit Pressure",
            "    ,                               !- Fan Total Efficiency",
            "    ;                               !- Electric Power Function of Flow Fraction Curve Name",
            "    EnergyManagementSystem:Actuator,",
            "      FanPressureRise_ResetValue,   !- Name",
            "      TEST FAN,                     !- Actuated Component Unique Name",
            "      Fan,                          !- Actuated Component Type",
            "      Fan Pressure Rise;            !- Actuated Component Control Type",
            "    EnergyManagementSystem:Program,",
            "      ResetFanPressureRise,                     !- Name",
            "      SET FanPressureRise_ResetValue = -100.0;  !- <none>",
            "    EnergyManagementSystem:ProgramCallingManager,",
            "      FanSystemModel_FanMainManager,  !- Name",
            "      BeginTimestepBeforePredictor,   !- EnergyPlus Model Calling Point",
            "      ResetFanPressureRise;           !- Program Name 1",
        )
        assert_true(self.process_idf(idf_objects))
        self.state.init_state(self.state)
        EMSManager.CheckIfAnyEMS(self.state)
        self.state.dataEMSMgr.FinishProcessingUserInput = True
        Fans.GetFanInput(self.state)
        self.state.dataSize.CurZoneEqNum = 0
        self.state.dataSize.CurSysNum = 0
        self.state.dataSize.CurOASysNum = 0
        self.state.dataEnvrn.StdRhoAir = 1.0
        let fanSystem = self.state.dataFans.fans[0] as Fans.FanSystem
        assert_true(fanSystem != None)
        fanSystem.simulate(self.state, False, None, None)
        let locFanSizeVdot: Real64 = fanSystem.maxAirFlowRate
        assert_approx_eq(locFanSizeVdot, 1.00, 1e-5)
        let designMassFlowRate: Real64 = locFanSizeVdot * self.state.dataEnvrn.StdRhoAir
        let massFlow1: Real64 = 0.5 * designMassFlowRate
        let massFlow2: Real64 = designMassFlowRate
        let runTimeFrac1: Real64 = 0.5
        let runTimeFrac2: Real64 = 0.5
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        var locFanElecPower: Real64 = fanSystem.totalPower
        var locExpectPower: Real64 = (0.5 * 0.5 + 0.5 * 1.0) * fanSystem.designElecPower  # expect 75% of power
        assert_approx_eq(locFanElecPower, locExpectPower, 0.01)
        var anyRan: Bool = False
        EMSManager.ManageEMS(self.state, EMSManager.EMSCallFrom.SetupSimulation, anyRan, Optional_int_const())
        EMSManager.ManageEMS(self.state, EMSManager.EMSCallFrom.BeginTimestepBeforePredictor, anyRan, Optional_int_const())
        assert_true(anyRan)
        fanSystem.simulate(self.state, False, None, None, None, massFlow1, runTimeFrac1, massFlow2, runTimeFrac2)
        locFanElecPower = fanSystem.totalPower
        locExpectPower = 0.0
        assert_approx_eq(locFanElecPower, locExpectPower, 1e-15)  # EXPECT_DOUBLE_EQ -> use very tight tolerance