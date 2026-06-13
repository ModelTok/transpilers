from testing import assert_true, assert_false, test
from ...EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from ...EnergyPlus.DataRuntimeLanguage import ValidateEMSVariableName, ValidateEMSProgramName
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture

@test
def ValidateEMSVariableName():
    var error: Bool = False
    var weirdSecondErrFlag: Bool = False
    var fieldValue: String = "GoodName"
    ValidateEMSVariableName(EnergyPlusFixture.state, "ObjectName", fieldValue, "FieldName", error, weirdSecondErrFlag)
    assert_false(error)
    fieldValue = "1 .-+"
    ValidateEMSVariableName(EnergyPlusFixture.state, "ObjectName", fieldValue, "FieldName", error, weirdSecondErrFlag)
    assert_true(error)

@test
def ValidateEMSProgramName():
    var error: Bool = False
    var weirdSecondErrFlag: Bool = False
    var fieldValue: String = "GoodName"
    ValidateEMSProgramName(EnergyPlusFixture.state, "ObjectName", fieldValue, "FieldName", "subType", error, weirdSecondErrFlag)
    assert_false(error)
    fieldValue = "1 .-+"
    ValidateEMSProgramName(EnergyPlusFixture.state, "ObjectName", fieldValue, "FieldName", "subType", error, weirdSecondErrFlag)
    assert_true(error)