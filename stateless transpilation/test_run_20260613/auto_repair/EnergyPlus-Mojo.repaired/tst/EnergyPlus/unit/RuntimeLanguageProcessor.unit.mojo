from testing import assert_true, assert_false, assert_equal, assert_almost_equal
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataRuntimeLanguage import DataRuntimeLanguage
from EnergyPlus.EMSManager import EMSManager
from EnergyPlus.RuntimeLanguageProcessor import RuntimeLanguageProcessor


@test
def ERLExpression_TestExponentials():
    state.dataGlobal.DoingSizing = False
    state.dataGlobal.KickOffSimulation = False
    state.dataEMSMgr.FinishProcessingUserInput = False
    var errorsFound = False
    state.dataRuntimeLang.ErlExpression = List[DataRuntimeLanguage.ErlExpressionType](1)
    var erlExpression = state.dataRuntimeLang.ErlExpression[0]
    erlExpression.Operator = DataRuntimeLanguage.ErlFunc.Exp
    erlExpression.NumOperands = 1
    erlExpression.Operand = List[DataRuntimeLanguage.ErlOperand](1)
    erlExpression.Operand[0].Number = -25
    var response1 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_false(errorsFound)
    assert_equal(0, response1.Number)
    erlExpression.Operand[0].Number = -20
    var response2 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_false(errorsFound)
    assert_equal(0, response2.Number)
    erlExpression.Operand[0].Number = -3
    var response3 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_false(errorsFound)
    assert_almost_equal(0.05, response3.Number, 0.001)
    erlExpression.Operand[0].Number = 0
    var response4 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_false(errorsFound)
    assert_almost_equal(1, response4.Number, 0.001)
    erlExpression.Operand[0].Number = 3
    var response5 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_false(errorsFound)
    assert_almost_equal(20.08, response5.Number, 0.01)
    erlExpression.Operand[0].Number = 700
    var response6 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_true(errorsFound)
    assert_equal(0, response6.Number)
    erlExpression.Operand[0].Number = 710
    var response7 = RuntimeLanguageProcessor.EvaluateExpression(state, 1, errorsFound)
    assert_true(errorsFound)
    assert_equal(0, response7.Number)


@test
def TestOutOfRangeAlphaFields():
    var idf_objects = delimited_string(
        [
            "EnergyManagementSystem:Sensor,",
            "  EMSSensor,",
            "  *,",
            "  Electricity:Facility;",
            "EnergyManagementSystem:Program,",
            "  DummyProgram,",
            "  SET N = EMSSensor;",
            "EnergyManagementSystem:ProgramCallingManager,",
            "  DummyManager,",
            "  BeginTimestepBeforePredictor,",
            "  DummyProgram;",
            "EnergyManagementSystem:MeteredOutputVariable,",
            "  MyLongMeteredOutputVariable,",
            "  EMSSensor,",
            "  ZoneTimeStep,",
            "  ,",
            "  Electricity,",
            "  Building,",
            "  ExteriorEquipment,",
            "  Transformer,",
            "  J;",
        ]
    )
    assert_true(process_idf(idf_objects))
    RuntimeLanguageProcessor.GetRuntimeLanguageUserInput(state)


def main():
    run_tests()