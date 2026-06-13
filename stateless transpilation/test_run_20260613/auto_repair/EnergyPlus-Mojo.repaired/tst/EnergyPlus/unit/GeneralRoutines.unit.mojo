from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_FALSE, EXPECT_DOUBLE_EQ, EXPECT_NEAR
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.GeneralRoutines import BBConvergeCheck, CalcComponentSensibleLatentOutput
from EnergyPlus.Psychrometrics import PsyHFnTdbW
from Fixtures.EnergyPlusFixture import EnergyPlusFixture

struct TestGeneralRoutines(EnergyPlusFixture):
    def TestBody_BBConvergeCheckTest(self):
        var SimCompNum: Int
        var MaxFlow: Float64
        var MinFlow: Float64
        var FunctionResult: Bool
        SimCompNum = 1
        MaxFlow = 1.0
        MinFlow = 0.99999999
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_FALSE(FunctionResult)
        SimCompNum = 10
        MaxFlow = 1.0
        MinFlow = 0.99999999
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_FALSE(FunctionResult)
        SimCompNum = 5
        MaxFlow = 1.0
        MinFlow = 0.9
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_FALSE(FunctionResult)
        SimCompNum = 5
        MaxFlow = 1.0
        MinFlow = 0.9999999
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_TRUE(FunctionResult)
        SimCompNum = 6
        MaxFlow = 1.0
        MinFlow = 0.9
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_FALSE(FunctionResult)
        SimCompNum = 6
        MaxFlow = 1.0
        MinFlow = 0.9999999
        FunctionResult = BBConvergeCheck(SimCompNum, MaxFlow, MinFlow)
        EXPECT_TRUE(FunctionResult)

    def TestBody_CalcComponentSensibleLatentOutputTest(self):
        var MassFlowRate: Float64 = 0.0
        var CoilInletTemp: Float64 = 0.0
        var CoilOutletTemp: Float64 = 0.0
        var CoilInletHumRat: Float64 = 0.0
        var CoilOutletHumRat: Float64 = 0.0
        var totaloutput: Float64 = 0.0
        var sensibleoutput: Float64 = 0.0
        var latentoutput: Float64 = 0.0
        var results_totaloutput: Float64 = 0.0
        var results_sensibleoutput: Float64 = 0.0
        var results_latentoutput: Float64 = 0.0
        MassFlowRate = 0.0
        CalcComponentSensibleLatentOutput(
            MassFlowRate, CoilOutletTemp, CoilOutletHumRat, CoilInletTemp, CoilInletHumRat, sensibleoutput, latentoutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_totaloutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_sensibleoutput, sensibleoutput)
        EXPECT_DOUBLE_EQ(results_latentoutput, latentoutput)
        MassFlowRate = 1.0
        CoilInletTemp = 24.0
        CoilOutletTemp = 12.0
        CoilInletHumRat = 0.00850
        CoilOutletHumRat = 0.00750
        results_totaloutput = MassFlowRate * (PsyHFnTdbW(CoilOutletTemp, CoilOutletHumRat) - PsyHFnTdbW(CoilInletTemp, CoilInletHumRat))
        results_sensibleoutput = MassFlowRate * (1.00484e3 + min(CoilInletHumRat, CoilOutletHumRat) * 1.85895e3) * (CoilOutletTemp - CoilInletTemp)
        results_latentoutput = results_totaloutput - results_sensibleoutput
        CalcComponentSensibleLatentOutput(
            MassFlowRate, CoilOutletTemp, CoilOutletHumRat, CoilInletTemp, CoilInletHumRat, sensibleoutput, latentoutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_totaloutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_sensibleoutput, sensibleoutput)
        EXPECT_DOUBLE_EQ(results_latentoutput, latentoutput)
        MassFlowRate = 1.0
        CoilInletTemp = 20.0
        CoilOutletTemp = 32.0
        CoilInletHumRat = 0.00750
        CoilOutletHumRat = 0.00750
        results_totaloutput = MassFlowRate * (PsyHFnTdbW(CoilOutletTemp, CoilOutletHumRat) - PsyHFnTdbW(CoilInletTemp, CoilInletHumRat))
        results_sensibleoutput = MassFlowRate * (1.00484e3 + min(CoilInletHumRat, CoilOutletHumRat) * 1.85895e3) * (CoilOutletTemp - CoilInletTemp)
        results_latentoutput = results_totaloutput - results_sensibleoutput
        CalcComponentSensibleLatentOutput(
            MassFlowRate, CoilOutletTemp, CoilOutletHumRat, CoilInletTemp, CoilInletHumRat, sensibleoutput, latentoutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_totaloutput, totaloutput)
        EXPECT_DOUBLE_EQ(results_sensibleoutput, sensibleoutput)
        EXPECT_NEAR(results_latentoutput, latentoutput, 1.0E-10)