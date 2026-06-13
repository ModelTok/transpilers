from gtest import Test, TestFixture, EXPECT_NEAR, EXPECT_DOUBLE_EQ, EXPECT_TRUE, EXPECT_LT, EXPECT_GT, EXPECT_LE, EXPECT_EQ
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.Psychrometrics import Psychrometrics, PsyTsatFnHPb_raw, PsyTsatFnHPb, PsyTsatFnPb_raw, PsyTsatFnPb, PsyWFnTdpPb, PsyCpAirFnW, PsyHFnTdbW, PsychrometricFunction, delimited_string, compare_err_stream

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyTsatFnHPb_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var H: Real64 = 7.5223e4 - 1.78637e4
        var PB: Real64 = 1.01325e5
        var result: Real64 = PsyTsatFnHPb_raw(self.state, H, PB)
        var actual_result: Real64 = 20.0
        EXPECT_NEAR(actual_result, result, 0.001)
        var cache_miss_result: Real64 = PsyTsatFnHPb(self.state, H, PB)
        EXPECT_NEAR(actual_result, cache_miss_result, 0.001)
        H = 2.7298e4 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 0.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = -6.7011e2 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = -20.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = -2.21379e4 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = -40.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = -4.2399e4 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = -60.0
        EXPECT_NEAR(actual_result, result, 0.1)
        H = -5.2399e4 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = -60.0
        EXPECT_NEAR(actual_result, result, 0.1)
        H = 1.8379e5 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 40.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = 4.7577e5 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 60.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = 1.5445e6 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 80.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = 3.8353e6 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 90.0
        EXPECT_NEAR(actual_result, result, 0.001)
        H = 4.5866e7 - 1.78637e4
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 100.0
        EXPECT_NEAR(actual_result, result, 1)
        H = 7.5223e4 - 1.78637e4
        PB = 0.91325e5
        result = PsyTsatFnHPb_raw(self.state, H, PB)
        actual_result = 18.819
        EXPECT_NEAR(actual_result, result, 0.001)
        H = 7.5223e4 - 1.78637e4
        PB = 1.0133e5
        actual_result = 20.0
        var cache_hit_result: Real64 = PsyTsatFnHPb(self.state, H, PB)
        EXPECT_NEAR(actual_result, cache_hit_result, 0.001)

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyTsatFnPb_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var PB: Real64 = 101325.0
        var result: Real64 = PsyTsatFnPb_raw(self.state, PB)
        var actual_result: Real64 = 99.974
        EXPECT_NEAR(actual_result, result, 0.001)
        PB = 101325.0
        var cache_result: Real64 = PsyTsatFnPb(self.state, PB)
        EXPECT_NEAR(actual_result, cache_result, 0.001)
        PB = 1555000.0
        result = PsyTsatFnPb_raw(self.state, PB)
        actual_result = 200.0
        EXPECT_DOUBLE_EQ(actual_result, result)
        PB = 0.0017
        result = PsyTsatFnPb_raw(self.state, PB)
        actual_result = -100.0
        EXPECT_DOUBLE_EQ(actual_result, result)
        PB = 611.1
        result = PsyTsatFnPb_raw(self.state, PB)
        actual_result = 0.0
        EXPECT_DOUBLE_EQ(actual_result, result)
        PB = 101325.0
        actual_result = 99.974
        EXPECT_NEAR(actual_result, cache_result, 0.001)

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyWFnTdpPb_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        var TDP: Real64
        var PB: Real64 = 101325.0
        var W: Real64
        TDP = 99.0
        W = Psychrometrics.PsyWFnTdpPb(self.state, TDP, PB)
        EXPECT_NEAR(17.5250143, W, 0.0001)
        var error_string: String = delimited_string([
            "   ** Warning ** Calculated partial vapor pressure is greater than the barometric pressure, so that calculated humidity ratio is invalid (PsyWFnTdpPb).",
            "   **   ~~~   **  Routine=Unknown, Environment=, at Simulation time= 00:00 - 00:00",
            "   **   ~~~   **  Dew-Point= 100.00 Barometric Pressure= 101325.00",
            "   **   ~~~   ** Instead, calculated Humidity Ratio at 99.0 (1 degree less) = 17.5250 will be used. Simulation continues.",
        ])
        TDP = 100.0
        W = Psychrometrics.PsyWFnTdpPb(self.state, TDP, PB)
        EXPECT_NEAR(17.5250143, W, 0.0001)
        EXPECT_TRUE(compare_err_stream(error_string, true))
        PB = 81000.0
        var error_string1: String = delimited_string([
            "   ** Warning ** Calculated partial vapor pressure is greater than the barometric pressure, so that calculated humidity ratio is invalid (PsyWFnTdpPb).",
            "   **   ~~~   **  Routine=Unknown, Environment=, at Simulation time= 00:00 - 00:00",
            "   **   ~~~   **  Dew-Point= 100.00 Barometric Pressure= 81000.00",
            "   **   ~~~   ** Instead, calculated Humidity Ratio at 93.0 (7 degree less) = 20.0794 will be used. Simulation continues.",
        ])
        self.state.dataPsychrometrics.iPsyErrIndex[Int(PsychrometricFunction.WFnTdpPb)] = 0
        W = Psychrometrics.PsyWFnTdpPb(self.state, TDP, PB)
        EXPECT_NEAR(20.07942181, W, 0.0001)
        EXPECT_TRUE(compare_err_stream(error_string1, true))

def PsyCpAirFnWTdb(dw: Real64, T: Real64) -> Real64:
    var dwSave: Real64 = -100.0
    var Tsave: Real64 = -100.0
    var cpaSave: Real64 = -100.0
    if (Tsave == T) and (dwSave == dw):
        return cpaSave
    var w: Real64 = max(dw, 1.0e-5)
    var cpa: Real64 = (PsyHFnTdbW(T + 0.1, w) - PsyHFnTdbW(T, w)) * 10.0
    dwSave = dw
    Tsave = T
    cpaSave = cpa
    return cpa

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyCpAirFn_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var W: Real64 = 0.0080
        var T: Real64 = 24.0
        var local_result: Real64 = 1.00484e3 + W * 1.85895e3
        var analytic_result: Real64 = PsyCpAirFnW(W)
        EXPECT_DOUBLE_EQ(analytic_result, local_result)
        W = 0.0085
        T = 26.0
        analytic_result = PsyCpAirFnW(W)
        var numerical_result: Real64 = PsyCpAirFnWTdb(W, T)
        EXPECT_NEAR(analytic_result, numerical_result, 1.0E-010)
        W = 0.007
        T = 10.0
        analytic_result = PsyCpAirFnW(W)
        numerical_result = PsyCpAirFnWTdb(W, T)
        EXPECT_NEAR(analytic_result, numerical_result, 1.0E-010)
        W = 0.0
        T = 20.0
        analytic_result = PsyCpAirFnW(W)
        numerical_result = PsyCpAirFnWTdb(W, T)
        EXPECT_NEAR(analytic_result, numerical_result, 1.0E-010)
        var SSE: Real64 = 0.0
        var Error: Real64 = 0.0
        var Error_sum: Real64 = 0.0
        var Error_min: Real64 = 100.0
        var Error_max: Real64 = -100.0
        var Tmax: Real64 = 50.0
        var Wmax: Real64 = 0.030
        analytic_result = 0.0
        numerical_result = 0.0
        for TLoop in range(0, 101):
            T = Tmax - (Tmax / 100.0) * TLoop
            for WLoop in range(0, 101):
                W = Wmax - (Wmax / 100.0) * WLoop
                analytic_result = PsyCpAirFnW(W)
                numerical_result = PsyCpAirFnWTdb(W, T)
                Error = numerical_result - analytic_result
                Error_min = min(Error, Error_min)
                Error_max = max(Error, Error_max)
                SSE += Error * Error
                Error_sum += Error
        var StdError: Real64 = sqrt(SSE / 100)
        var Error_avg: Real64 = Error_sum / 101
        EXPECT_LT(Error_min, 0.0)
        EXPECT_GT(Error_max, 0.0)
        EXPECT_GT(Error_avg, 0.0)
        EXPECT_GT(StdError, 0.0)

@register_test(EnergyPlusFixture)
class Psychrometrics_CpAirValue_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var W1: Real64 = 0.0030
        var T1: Real64 = 24.0
        var W2: Real64 = 0.0030
        var T2: Real64 = 20.0
        var MassFlowRate: Real64 = 5.0
        var CpAir: Real64 = 1.00484e3 + W1 * 1.85895e3
        var CpAir1: Real64 = PsyCpAirFnW(W1)
        var CpAir2: Real64 = PsyCpAirFnW(W2)
        EXPECT_DOUBLE_EQ(W1, W2)
        EXPECT_DOUBLE_EQ(CpAir, CpAir1)
        EXPECT_DOUBLE_EQ(CpAir, CpAir2)
        var Qfrom_mdot_CpAir_DeltaT: Real64 = MassFlowRate * CpAir * (T1 - T2)
        var H1: Real64 = PsyHFnTdbW(T1, W1)
        var H2: Real64 = PsyHFnTdbW(T2, W2)
        var Qfrom_mdot_DeltaH: Real64 = MassFlowRate * (H1 - H2)
        EXPECT_DOUBLE_EQ(Qfrom_mdot_CpAir_DeltaT, Qfrom_mdot_DeltaH)
        T1 = 10.0
        T2 = 20.0
        CpAir = 1.00484e3 + W1 * 1.85895e3
        Qfrom_mdot_CpAir_DeltaT = MassFlowRate * CpAir * (T2 - T1)
        H1 = PsyHFnTdbW(T1, W1)
        H2 = PsyHFnTdbW(T2, W2)
        Qfrom_mdot_DeltaH = MassFlowRate * (H2 - H1)
        EXPECT_DOUBLE_EQ(Qfrom_mdot_CpAir_DeltaT, Qfrom_mdot_DeltaH)

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyTwbFnTdbWPb_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var TDB: Real64 = 1
        var W: Real64 = 0.002
        var Pb: Real64 = 101325.0
        var result: Real64 = Psychrometrics.PsyTwbFnTdbWPb(self.state, TDB, W, Pb)
        var expected_result: Real64 = -2.200
        EXPECT_NEAR(result, expected_result, 0.001)

@register_test(EnergyPlusFixture)
class Psychrometrics_CpAirAverageValue_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var W1: Real64 = 0.0030
        var W2: Real64 = 0.0030
        var CpAirIn: Real64 = PsyCpAirFnW(W1)
        var CpAirOut: Real64 = PsyCpAirFnW(W2)
        var CpAir_result: Real64 = PsyCpAirFnW(0.5 * (W1 + W2))
        var CpAir_average: Real64 = (CpAirIn + CpAirOut) / 2
        EXPECT_DOUBLE_EQ(CpAirIn, 1.00484e3 + W1 * 1.85895e3)
        EXPECT_DOUBLE_EQ(CpAirOut, 1.00484e3 + W2 * 1.85895e3)
        EXPECT_DOUBLE_EQ(CpAir_result, CpAir_average)
        W1 = 0.010
        W2 = 0.008
        CpAirIn = PsyCpAirFnW(W1)
        CpAirOut = PsyCpAirFnW(W2)
        CpAir_result = PsyCpAirFnW(0.5 * (W1 + W2))
        CpAir_average = (CpAirIn + CpAirOut) / 2
        EXPECT_DOUBLE_EQ(CpAirIn, 1.00484e3 + W1 * 1.85895e3)
        EXPECT_DOUBLE_EQ(CpAirOut, 1.00484e3 + W2 * 1.85895e3)
        EXPECT_DOUBLE_EQ(CpAir_result, CpAir_average)

@register_test(EnergyPlusFixture)
class Psychrometrics_Interpolation_Sample_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var tsat_psy: Real64
        var error: Real64 = 0.0
        var i: Int
        for i in range(1, 1651):
            var tsat_fn_pb_pressure: Int = i * 64
            tsat_psy = PsyTsatFnPb(self.state, tsat_fn_pb_pressure)
            error = max(abs(tsat_psy - tsat_fn_pb_y[i]), error)
        EXPECT_LE(error, 1E-7)

@register_test(EnergyPlusFixture)
class Psychrometrics_CSpline_Test(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        var tsat_psy: Real64
        var tsat_cspline: Real64
        var Press_test: Real64
        var Press_test_smallchange: Real64
        var error: Real64 = 0.0
        var i: Int
        for i in range(0, 701):
            self.state.dataPsychrometrics.useInterpolationPsychTsatFnPb = false
            Press_test = 50000 + i * 100
            tsat_psy = PsyTsatFnPb_raw(self.state, Press_test)
            self.state.dataPsychrometrics.useInterpolationPsychTsatFnPb = true
            Press_test_smallchange = Press_test + 1e-60
            tsat_cspline = PsyTsatFnPb_raw(self.state, Press_test_smallchange)
            error = max(abs(tsat_psy - tsat_cspline), error)
        EXPECT_LE(error, 1E-5)

@register_test(EnergyPlusFixture)
class Psychrometrics_PsyTwbFnTdbWPb_Test_Discontinuity(Test):
    def __init__(inout self, state: EnergyPlusData):
        self.state = state

    def run(self):
        self.state.init_state(self.state)
        self.state.dataGlobal.WarmupFlag = true
        var TDB: Real64 = 1.4333333333333331
        var W: Real64 = 0.0031902374172088472
        var Pb: Real64 = 101400.00000000001
        var result: Real64 = Psychrometrics.PsyTwbFnTdbWPb(self.state, TDB, W, Pb)
        var expected_result: Real64 = -0.1027
        EXPECT_NEAR(result, expected_result, 0.001)
        EXPECT_EQ(self.state.dataErrTracking.TotalSevereErrors, 0)
        EXPECT_EQ(self.state.dataErrTracking.TotalWarningErrors, 1)