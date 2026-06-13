from ObjexxFCL.string.functions import has, is_any_of
from EnergyPlus.UtilityRoutines import ShowSevereError, ShowContinueError
namespace EnergyPlus:
    namespace DataRuntimeLanguage:
        def ValidateEMSVariableName(
            inout state: EnergyPlusData,
            cModuleObject: String,
            cFieldValue: String,
            cFieldName: String,
            inout errFlag: Bool,
            inout ErrorsFound: Bool
        ):
            alias InvalidStartCharacters = "0123456789"
            errFlag = False
            if has(cFieldValue, ' '):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used as EMS variables cannot contain spaces", cFieldName))
                errFlag = True
                ErrorsFound = True
            if has(cFieldValue, '-'):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used as EMS variables cannot contain \"-\" characters.", cFieldName))
                errFlag = True
                ErrorsFound = True
            if has(cFieldValue, '+'):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used as EMS variables cannot contain \"+\" characters.", cFieldName))
                errFlag = True
                ErrorsFound = True
            if has(cFieldValue, '.'):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used as EMS variables cannot contain \".\" characters.", cFieldName))
                errFlag = True
                ErrorsFound = True
            if (len(cFieldValue) > 0) and is_any_of(cFieldValue[0], InvalidStartCharacters):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used as EMS variables cannot start with numeric characters.", cFieldName))
                errFlag = True
                ErrorsFound = True
        def ValidateEMSProgramName(
            inout state: EnergyPlusData,
            cModuleObject: String,
            cFieldValue: String,
            cFieldName: String,
            cSubType: String,
            inout errFlag: Bool,
            inout ErrorsFound: Bool
        ):
            errFlag = False
            if has(cFieldValue, ' '):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used for EMS {} cannot contain spaces", cFieldName, cSubType))
                errFlag = True
                ErrorsFound = True
            if has(cFieldValue, '-'):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used for EMS {} cannot contain \"-\" characters.", cFieldName, cSubType))
                errFlag = True
                ErrorsFound = True
            if has(cFieldValue, '+'):
                ShowSevereError(state, String.format("{}=\"{}\", Invalid variable name entered.", cModuleObject, cFieldValue))
                ShowContinueError(state, String.format("...{}; Names used for EMS {} cannot contain \"+\" characters.", cFieldName, cSubType))
                errFlag = True
                ErrorsFound = True