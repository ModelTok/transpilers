from Data.BaseData import BaseGlobalStruct
from DataGlobals import *
from EnergyPlus import *
from DataErrorTracking import *
from DataEnvironment import *
from DataReportingFlags import *
from DataStringGlobals import *
from DataSystemVariables import *
from BranchInputManager import *
from BranchNodeConnections import *
from DaylightingManager import *
from ExternalInterface import *
from FileSystem import *
from General import *
from GeneralRoutines import *
from NodeInputManager import *
from OutputReports import *
from Plant.PlantManager import *
from ResultsFramework import *
from SQLiteProcedures import *
from SimulationManager import *
from SolarShading import *
from SystemReports import *
from Timer import *
from UtilityRoutines import *
from FMI.main import *
from fast_float import *
from ObjexxFCL.Array1D import *
from ObjexxFCL.Array1S import *
from ObjexxFCL.char_functions import *
from ObjexxFCL.string_functions import *
from stdlib import *
from math import *

alias Real64 = Float64
alias Array1_string = Array1D[String]
alias Array1S_string = Array1S[String]
alias Array1D_string = Array1D[String]
alias OptionalOutputFileRef = Optional[Ref[InputOutputFile]]

struct ErrorMessageCategory:
    var value: Int32
    def __init__(self, val: Int32):
        self.value = val
    @staticmethod
    def Invalid() -> Self: return Self(-1)
    @staticmethod
    def Unclassified() -> Self: return Self(0)
    @staticmethod
    def Input_invalid() -> Self: return Self(1)
    @staticmethod
    def Input_field_not_found() -> Self: return Self(2)
    @staticmethod
    def Input_field_blank() -> Self: return Self(3)
    @staticmethod
    def Input_object_not_found() -> Self: return Self(4)
    @staticmethod
    def Input_cannot_find_object() -> Self: return Self(5)
    @staticmethod
    def Input_topology_problem() -> Self: return Self(6)
    @staticmethod
    def Input_unused() -> Self: return Self(7)
    @staticmethod
    def Input_fatal() -> Self: return Self(8)
    @staticmethod
    def Runtime_general() -> Self: return Self(9)
    @staticmethod
    def Runtime_flow_out_of_range() -> Self: return Self(10)
    @staticmethod
    def Runtime_temp_out_of_range() -> Self: return Self(11)
    @staticmethod
    def Runtime_airflow_network() -> Self: return Self(12)
    @staticmethod
    def Fatal_general() -> Self: return Self(13)
    @staticmethod
    def Developer_general() -> Self: return Self(14)
    @staticmethod
    def Developer_invalid_index() -> Self: return Self(15)
    @staticmethod
    def Num() -> Self: return Self(16)

struct Clusive:
    var value: Int32
    def __init__(self, val: Int32):
        self.value = val
    @staticmethod
    def Invalid() -> Self: return Self(-1)
    @staticmethod
    def In() -> Self: return Self(0)
    @staticmethod
    def Ex() -> Self: return Self(1)
    @staticmethod
    def Num() -> Self: return Self(2)

struct ErrorCountIndex:
    var index: Int32 = 0
    var count: Int32 = 0

struct ErrorObjectHeader:
    var routineName: StringLiteral
    var objectType: StringLiteral
    var objectName: StringLiteral

struct UtilityRoutinesData(BaseGlobalStruct):
    var outputErrorHeader: Bool = True
    var appendPerfLog_headerRow: String = ""
    var appendPerfLog_valuesRow: String = ""
    var GetMatrixInputFlag: Bool = True

    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self.outputErrorHeader = True
        self.appendPerfLog_headerRow = ""
        self.appendPerfLog_valuesRow = ""
        self.GetMatrixInputFlag = True

    def __init__(inout self):

def pow2[T: Arithmeticable](x: T) -> T:
    return x * x

def pow3[T: Arithmeticable](x: T) -> T:
    return x * x * x

def pow4[T: Arithmeticable](x: T) -> T:
    var y: T = x * x
    return y * y

def pow5[T: Arithmeticable](x: T) -> T:
    var y: T = x * x
    y *= y
    return y * x

def pow6[T: Arithmeticable](x: T) -> T:
    var y: T = x * x
    y *= y
    return y * y

def pow7[T: Arithmeticable](x: T) -> T:
    var y: T = x * x
    y *= y
    y *= y
    return y * x

def env_var_on(env_var_str: String) -> Bool:
    return ((not env_var_str.empty()) and is_any_of(env_var_str[0], "YyTt"))

def emitErrorMessage(inout state: EnergyPlusData, category: ErrorMessageCategory, msg: String, shouldFatal: Bool):
    if not shouldFatal:
        ShowSevereError(state, msg)
    else:
        ShowFatalError(state, msg)

def emitErrorMessages(inout state: EnergyPlusData, category: ErrorMessageCategory, msgs: List[String], shouldFatal: Bool, zeroBasedTimeStampIndex: Int32 = -1):
    for i in range(len(msgs)):
        var msg = msgs[i]
        if i == zeroBasedTimeStampIndex:
            ShowContinueErrorTimeStamp(state, msg)
            continue
        if i == 0:
            ShowSevereError(state, msg)
        elif i == len(msgs) - 1 and shouldFatal:
            ShowFatalError(state, msg)
        else:
            ShowContinueError(state, msg)

def emitWarningMessage(inout state: EnergyPlusData, category: ErrorMessageCategory, msg: String, countAsError: Bool = False):
    if countAsError:
        ShowWarningError(state, msg)
    else:
        ShowWarningMessage(state, msg)

def emitWarningMessages(inout state: EnergyPlusData, category: ErrorMessageCategory, msgs: List[String], countAsError: Bool = False):
    for i in range(len(msgs)):
        var msg = msgs[i]
        if i == 0:
            if countAsError:
                ShowWarningError(state, msg)
            else:
                ShowWarningMessage(state, msg)
        else:
            ShowContinueError(state, msg)

def ShowFatalError(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    ShowErrorMessage(state, format(" **  Fatal  ** {}", ErrorMessage), OutUnit1, OutUnit2)
    DisplayString(state, "**FATAL:" + ErrorMessage)
    ShowErrorMessage(state, " ...Summary of Errors that led to program termination:", OutUnit1, OutUnit2)
    ShowErrorMessage(state, format(" ..... Reference severe error count={}", state.dataErrTracking.TotalSevereErrors), OutUnit1, OutUnit2)
    ShowErrorMessage(state, format(" ..... Last severe error={}", state.dataErrTracking.LastSevereError), OutUnit1, OutUnit2)
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 2, ErrorMessage, 1)
        if state.dataSQLiteProcedures.sqlite.sqliteWithinTransaction():
            state.dataSQLiteProcedures.sqlite.sqliteCommit()
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Fatal, ErrorMessage)
    raise FatalError(ErrorMessage)

def ShowSevereError(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(ErrorMessage, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
    state.dataErrTracking.TotalSevereErrors += 1
    if state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation and not state.dataErrTracking.AbortProcessing:
        state.dataErrTracking.TotalSevereErrorsDuringWarmup += 1
    if state.dataGlobal.DoingSizing:
        state.dataErrTracking.TotalSevereErrorsDuringSizing += 1
    ShowErrorMessage(state, format(" ** Severe  ** {}", ErrorMessage), OutUnit1, OutUnit2)
    state.dataErrTracking.LastSevereError = ErrorMessage
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, ErrorMessage, 1)
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Severe, ErrorMessage)

def ShowSevereMessage(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(ErrorMessage, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
    ShowErrorMessage(state, format(" ** Severe  ** {}", ErrorMessage), OutUnit1, OutUnit2)
    state.dataErrTracking.LastSevereError = ErrorMessage
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, ErrorMessage, 0)
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Severe, ErrorMessage)

def ShowContinueError(inout state: EnergyPlusData, Message: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    ShowErrorMessage(state, format(" **   ~~~   ** {}", Message), OutUnit1, OutUnit2)
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(Message)
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Continue, Message)

def ShowContinueErrorTimeStamp(inout state: EnergyPlusData, Message: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    var cEnvHeader: String
    if state.dataGlobal.WarmupFlag:
        if not state.dataGlobal.SetupFlag:
            if not state.dataGlobal.DoingSizing:
                cEnvHeader = " During Warmup, Environment="
            else:
                cEnvHeader = " During Warmup & Sizing, Environment="
        else:
            if not state.dataGlobal.DoingSizing:
                cEnvHeader = " During Setup, Environment="
            else:
                cEnvHeader = " During Setup & Sizing, Environment="
    else:
        if not state.dataGlobal.DoingSizing:
            cEnvHeader = " Environment="
        else:
            cEnvHeader = " During Sizing, Environment="
    if len(Message) < 50:
        var m = format("{}{}{}, at Simulation time={} {}", Message, cEnvHeader, state.dataEnvrn.EnvironmentName, state.dataEnvrn.CurMnDy, General.CreateSysTimeIntervalString(state))
        ShowErrorMessage(state, format(" **   ~~~   ** {}", m), OutUnit1, OutUnit2)
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(m)
        if state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback(Error.Continue, m)
    else:
        var postfix = format("{}{}, at Simulation time={} {}", cEnvHeader, state.dataEnvrn.EnvironmentName, state.dataEnvrn.CurMnDy, General.CreateSysTimeIntervalString(state))
        ShowErrorMessage(state, format(" **   ~~~   ** {}", Message))
        ShowErrorMessage(state, format(" **   ~~~   ** {}", postfix), OutUnit1, OutUnit2)
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(Message)
        if state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback(Error.Continue, Message)
            state.dataGlobal.errorCallback(Error.Continue, postfix)

def ShowMessage(inout state: EnergyPlusData, Message: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    if Message.empty():
        ShowErrorMessage(state, " *************", OutUnit1, OutUnit2)
    else:
        ShowErrorMessage(state, format(" ************* {}", Message), OutUnit1, OutUnit2)
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, -1, Message, 0)
        if state.dataGlobal.errorCallback:
            state.dataGlobal.errorCallback(Error.Info, Message)

def ShowWarningError(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(ErrorMessage, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
    state.dataErrTracking.TotalWarningErrors += 1
    if state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation and not state.dataErrTracking.AbortProcessing:
        state.dataErrTracking.TotalWarningErrorsDuringWarmup += 1
    if state.dataGlobal.DoingSizing:
        state.dataErrTracking.TotalWarningErrorsDuringSizing += 1
    ShowErrorMessage(state, format(" ** Warning ** {}", ErrorMessage), OutUnit1, OutUnit2)
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, ErrorMessage, 1)
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Warning, ErrorMessage)

def ShowWarningMessage(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(ErrorMessage, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
    ShowErrorMessage(state, format(" ** Warning ** {}", ErrorMessage), OutUnit1, OutUnit2)
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, ErrorMessage, 0)
    if state.dataGlobal.errorCallback:
        state.dataGlobal.errorCallback(Error.Warning, ErrorMessage)

def ShowRecurringSevereErrorAtEnd(inout state: EnergyPlusData, Message: String, inout MsgIndex: Int32, ReportMaxOf: Optional[Real64] = Optional[Real64](), ReportMinOf: Optional[Real64] = Optional[Real64](), ReportSumOf: Optional[Real64] = Optional[Real64](), ReportMaxUnits: String = "", ReportMinUnits: String = "", ReportSumUnits: String = ""):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(Message, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
            break
    var bNewMessageFound = True
    for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
        if Util.SameString(state.dataErrTracking.RecurringErrors[Loop].Message, " ** Severe  ** " + Message):
            bNewMessageFound = False
            MsgIndex = Loop
            break
    if bNewMessageFound:
        MsgIndex = 0
    state.dataErrTracking.TotalSevereErrors += 1
    StoreRecurringErrorMessage(state, " ** Severe  ** " + Message, MsgIndex, ReportMaxOf, ReportMinOf, ReportSumOf, ReportMaxUnits, ReportMinUnits, ReportSumUnits)

def ShowRecurringSevereErrorAtEnd(inout state: EnergyPlusData, Message: String, inout MsgIndex: Int32, val: Real64, units: String):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(Message, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
            break
    var bNewMessageFound = True
    for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
        if Util.SameString(state.dataErrTracking.RecurringErrors[Loop].Message, " ** Severe  ** " + Message):
            bNewMessageFound = False
            MsgIndex = Loop
            break
    if bNewMessageFound:
        MsgIndex = 0
    state.dataErrTracking.TotalSevereErrors += 1
    StoreRecurringErrorMessage(state, " ** Severe  ** " + Message, MsgIndex, val, val, Optional[Real64](), units, units, "")

def ShowRecurringWarningErrorAtEnd(inout state: EnergyPlusData, Message: String, inout MsgIndex: Int32, ReportMaxOf: Optional[Real64] = Optional[Real64](), ReportMinOf: Optional[Real64] = Optional[Real64](), ReportSumOf: Optional[Real64] = Optional[Real64](), ReportMaxUnits: String = "", ReportMinUnits: String = "", ReportSumUnits: String = ""):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(Message, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
            break
    var bNewMessageFound = True
    for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
        if Util.SameString(state.dataErrTracking.RecurringErrors[Loop].Message, " ** Warning ** " + Message):
            bNewMessageFound = False
            MsgIndex = Loop
            break
    if bNewMessageFound:
        MsgIndex = 0
    state.dataErrTracking.TotalWarningErrors += 1
    StoreRecurringErrorMessage(state, " ** Warning ** " + Message, MsgIndex, ReportMaxOf, ReportMinOf, ReportSumOf, ReportMaxUnits, ReportMinUnits, ReportSumUnits)

def ShowRecurringWarningErrorAtEnd(inout state: EnergyPlusData, Message: String, inout MsgIndex: Int32, val: Real64, units: String):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(Message, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
            break
    var bNewMessageFound = True
    for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
        if Util.SameString(state.dataErrTracking.RecurringErrors[Loop].Message, " ** Warning ** " + Message):
            bNewMessageFound = False
            MsgIndex = Loop
            break
    if bNewMessageFound:
        MsgIndex = 0
    state.dataErrTracking.TotalWarningErrors += 1
    StoreRecurringErrorMessage(state, " ** Warning ** " + Message, MsgIndex, val, val, Optional[Real64](), units, units, "")

def ShowRecurringContinueErrorAtEnd(inout state: EnergyPlusData, Message: String, inout MsgIndex: Int32, ReportMaxOf: Optional[Real64] = Optional[Real64](), ReportMinOf: Optional[Real64] = Optional[Real64](), ReportSumOf: Optional[Real64] = Optional[Real64](), ReportMaxUnits: String = "", ReportMinUnits: String = "", ReportSumUnits: String = ""):
    for Loop in range(1, DataErrorTracking.SearchCounts + 1):
        if has(Message, DataErrorTracking.MessageSearch[Loop]):
            state.dataErrTracking.MatchCounts[Loop] += 1
            break
    var bNewMessageFound = True
    for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
        if Util.SameString(state.dataErrTracking.RecurringErrors[Loop].Message, " **   ~~~   ** " + Message):
            bNewMessageFound = False
            MsgIndex = Loop
            break
    if bNewMessageFound:
        MsgIndex = 0
    StoreRecurringErrorMessage(state, " **   ~~~   ** " + Message, MsgIndex, ReportMaxOf, ReportMinOf, ReportSumOf, ReportMaxUnits, ReportMinUnits, ReportSumUnits)

def StoreRecurringErrorMessage(inout state: EnergyPlusData, ErrorMessage: String, inout ErrorMsgIndex: Int32, ErrorReportMaxOf: Optional[Real64] = Optional[Real64](), ErrorReportMinOf: Optional[Real64] = Optional[Real64](), ErrorReportSumOf: Optional[Real64] = Optional[Real64](), ErrorReportMaxUnits: String = "", ErrorReportMinUnits: String = "", ErrorReportSumUnits: String = ""):
    if ErrorMsgIndex == 0:
        state.dataErrTracking.NumRecurringErrors += 1
        state.dataErrTracking.RecurringErrors.redimension(state.dataErrTracking.NumRecurringErrors)
        ErrorMsgIndex = state.dataErrTracking.NumRecurringErrors
        state.dataErrTracking.RecurringErrors[ErrorMsgIndex].Message = ErrorMessage
        state.dataErrTracking.RecurringErrors[ErrorMsgIndex].Count = 1
        if state.dataGlobal.WarmupFlag:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].WarmupCount = 1
        if state.dataGlobal.DoingSizing:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].SizingCount = 1
        if ErrorReportMaxOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MaxValue = ErrorReportMaxOf.value()
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportMax = True
            if not ErrorReportMaxUnits.empty():
                state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MaxUnits = ErrorReportMaxUnits
        if ErrorReportMinOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MinValue = ErrorReportMinOf.value()
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportMin = True
            if not ErrorReportMinUnits.empty():
                state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MinUnits = ErrorReportMinUnits
        if ErrorReportSumOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].SumValue = ErrorReportSumOf.value()
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportSum = True
            if not ErrorReportSumUnits.empty():
                state.dataErrTracking.RecurringErrors[ErrorMsgIndex].SumUnits = ErrorReportSumUnits
    elif ErrorMsgIndex > 0:
        state.dataErrTracking.RecurringErrors[ErrorMsgIndex].Count += 1
        if state.dataGlobal.WarmupFlag:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].WarmupCount += 1
        if state.dataGlobal.DoingSizing:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].SizingCount += 1
        if ErrorReportMaxOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MaxValue = max(ErrorReportMaxOf.value(), state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MaxValue)
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportMax = True
        if ErrorReportMinOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MinValue = min(ErrorReportMinOf.value(), state.dataErrTracking.RecurringErrors[ErrorMsgIndex].MinValue)
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportMin = True
        if ErrorReportSumOf:
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].SumValue += ErrorReportSumOf.value()
            state.dataErrTracking.RecurringErrors[ErrorMsgIndex].ReportSum = True
    else:

def ShowErrorMessage(inout state: EnergyPlusData, ErrorMessage: String, OutUnit1: OptionalOutputFileRef = OptionalOutputFileRef(), OutUnit2: OptionalOutputFileRef = OptionalOutputFileRef()):
    var err_stream = state.files.err_stream.get()
    if state.dataUtilityRoutines.outputErrorHeader and (err_stream != None):
        err_stream.write("Program Version," + state.dataStrGlobals.VerStringVar + ',' + state.dataStrGlobals.IDDVerString + '\n')
        state.dataUtilityRoutines.outputErrorHeader = False
    if not state.dataGlobal.DoingInputProcessing:
        if err_stream != None:
            err_stream.write("  " + ErrorMessage + '\n')
    else:
        if state.dataGlobal.printConsoleOutput:
            print(ErrorMessage)
    if OutUnit1:
        print(OutUnit1.value(), "  {}", ErrorMessage)
    if OutUnit2:
        print(OutUnit2.value(), "  {}", ErrorMessage)

def SummarizeErrors(inout state: EnergyPlusData):
    var StartC: Int
    var EndC: Int
    if any_gt(state.dataErrTracking.MatchCounts, 0):
        ShowMessage(state, "")
        ShowMessage(state, "===== Final Error Summary =====")
        ShowMessage(state, "The following error categories occurred.  Consider correcting or noting.")
        for Loop in range(1, DataErrorTracking.SearchCounts + 1):
            if state.dataErrTracking.MatchCounts[Loop] > 0:
                ShowMessage(state, DataErrorTracking.Summaries[Loop])
                var thisMoreDetails = DataErrorTracking.MoreDetails[Loop]
                if not thisMoreDetails.empty():
                    StartC = 0
                    EndC = len(thisMoreDetails) - 1
                    while EndC != -1:
                        EndC = index(thisMoreDetails[StartC:], "<CR")
                        ShowMessage(state, format("..{}", thisMoreDetails[StartC:StartC + EndC]))
                        if thisMoreDetails[StartC + EndC:StartC + EndC + 5] == "<CRE>":
                            break
                        StartC += EndC + 4
                        EndC = len(thisMoreDetails[StartC:]) - 1
        ShowMessage(state, "")

def ShowRecurringErrors(inout state: EnergyPlusData):
    var StatMessageStart: StringLiteral = " **   ~~~   ** "
    if state.dataErrTracking.NumRecurringErrors > 0:
        ShowMessage(state, "")
        ShowMessage(state, "===== Recurring Error Summary =====")
        ShowMessage(state, "The following recurring error messages occurred.")
        for Loop in range(1, state.dataErrTracking.NumRecurringErrors + 1):
            var error = state.dataErrTracking.RecurringErrors[Loop]
            if has_prefix(error.Message, " **   ~~~   ** "):
                ShowMessage(state, error.Message)
                if state.dataSQLiteProcedures.sqlite:
                    state.dataSQLiteProcedures.sqlite.updateSQLiteErrorRecord(error.Message)
                if state.dataGlobal.errorCallback:
                    state.dataGlobal.errorCallback(Error.Continue, error.Message)
            else:
                var warning = has_prefix(error.Message, " ** Warning ** ")
                var severe = has_prefix(error.Message, " ** Severe  ** ")
                ShowMessage(state, "")
                ShowMessage(state, error.Message)
                ShowMessage(state, format("{}  This error occurred {} total times;", StatMessageStart, error.Count))
                ShowMessage(state, format("{}  during Warmup {} times;", StatMessageStart, error.WarmupCount))
                ShowMessage(state, format("{}  during Sizing {} times.", StatMessageStart, error.SizingCount))
                if state.dataSQLiteProcedures.sqlite:
                    if warning:
                        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 0, error.Message[15:], error.Count)
                    elif severe:
                        state.dataSQLiteProcedures.sqlite.createSQLiteErrorRecord(1, 1, error.Message[15:], error.Count)
                if state.dataGlobal.errorCallback:
                    var level = Error.Warning
                    if severe:
                        level = Error.Severe
                    state.dataGlobal.errorCallback(level, error.Message)
                    state.dataGlobal.errorCallback(Error.Continue, "")
            var StatMessage: String = ""
            if error.ReportMax:
                var MaxOut = format("{:.6f}", error.MaxValue)
                StatMessage += "  Max=" + MaxOut
                if not error.MaxUnits.empty():
                    StatMessage += ' ' + error.MaxUnits
            if error.ReportMin:
                var MinOut = format("{:.6f}", error.MinValue)
                StatMessage += "  Min=" + MinOut
                if not error.MinUnits.empty():
                    StatMessage += ' ' + error.MinUnits
            if error.ReportSum:
                var SumOut = format("{:.6f}", error.SumValue)
                StatMessage += "  Sum=" + SumOut
                if not error.SumUnits.empty():
                    StatMessage += ' ' + error.SumUnits
            if error.ReportMax or error.ReportMin or error.ReportSum:
                ShowMessage(state, format("{}{}", StatMessageStart, StatMessage))
        ShowMessage(state, "")

def ShowSevereDuplicateName(inout state: EnergyPlusData, eoh: ErrorObjectHeader):
    ShowSevereError(state, format("{}: {} = {}, duplicate name.", eoh.routineName, eoh.objectType, eoh.objectName))

def ShowSevereEmptyField(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, depFieldName: StringLiteral = "", depFieldVal: StringLiteral = ""):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} cannot be empty{}.", fieldName, "" if depFieldName.empty() else format(" when {} = {}", depFieldName, depFieldVal)))

def ShowSevereItemNotFound(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, item not found.", fieldName, fieldVal))

def ShowDetailedSevereItemNotFound(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}, item not found.", eoh.routineName, fieldName, fieldVal))
    ShowContinueError(state, format("{} = {}, item not found.", fieldName, fieldVal))

def ShowSevereItemNotFoundAudit(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName), OptionalOutputFileRef(state.files.audit))
    ShowContinueError(state, format("{} = {}, item not found.", fieldName, fieldVal), OptionalOutputFileRef(state.files.audit))

def ShowSevereDuplicateAssignment(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, prevVal: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, field previously assigned to {}.", fieldName, fieldVal, prevVal))

def ShowSevereInvalidKey(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, msg: StringLiteral = ""):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, invalid key.", fieldName, fieldVal))
    if not msg.empty():
        ShowContinueError(state, format(msg))

def ShowSevereInvalidBool(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, invalid boolean (\"Yes\"/\"No\").", fieldName, fieldVal))

def ShowSevereCustom(inout state: EnergyPlusData, eoh: ErrorObjectHeader, msg: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{}", msg))

def ShowSevereCustomAudit(inout state: EnergyPlusData, eoh: ErrorObjectHeader, msg: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName), OptionalOutputFileRef(state.files.audit))
    ShowContinueError(state, format("{}", msg), OptionalOutputFileRef(state.files.audit))

def ShowSevereCustomField(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldValue: StringLiteral, msg: StringLiteral):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, {}", fieldName, fieldValue, msg))

def ShowSevereBadMin(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMin: Clusive, minVal: Real64, msg: StringLiteral = ""):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, but must be {} {}", fieldName, fieldVal, ">=" if cluMin.value == Clusive.In().value else ">", minVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def ShowSevereBadMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMax: Clusive, maxVal: Real64, msg: StringLiteral = ""):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, but must be {} {}", fieldName, fieldVal, "<=" if cluMax.value == Clusive.In().value else "<", maxVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def ShowSevereBadMinMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMin: Clusive, minVal: Real64, cluMax: Clusive, maxVal: Real64, msg: StringLiteral = ""):
    ShowSevereError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, but must be {} {} and {} {}", fieldName, fieldVal, ">=" if cluMin.value == Clusive.In().value else ">", minVal, "<=" if cluMax.value == Clusive.In().value else "<", maxVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def ShowWarningItemNotFound(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, item not found", fieldName, fieldVal))

def ShowWarningCustom(inout state: EnergyPlusData, eoh: ErrorObjectHeader, msg: StringLiteral):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{}", msg))

def ShowWarningCustomField(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldValue: StringLiteral, msg: StringLiteral):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, {}", fieldName, fieldValue, msg))

def ShowWarningInvalidKey(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, defaultVal: StringLiteral, msg: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, invalid key, {} will be used.", fieldName, fieldVal, defaultVal))
    if not msg.empty():
        ShowContinueError(state, format(msg))

def ShowWarningInvalidBool(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, defaultVal: StringLiteral):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, invalid boolean (\"Yes\"/\"No\"), {} will be used.", fieldName, fieldVal, defaultVal))

def ShowWarningEmptyField(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, defaultVal: StringLiteral = "", depFieldName: StringLiteral = "", depFieldVal: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} is empty.", fieldName))
    if not depFieldName.empty():
        ShowContinueError(state, format("Cannot be empty when {} = {}", depFieldName, depFieldVal))
    if not defaultVal.empty():
        ShowContinueError(state, format("{} will be used.", defaultVal))

def ShowWarningNonEmptyField(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, depFieldName: StringLiteral = "", depFieldValue: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} is not empty.", fieldName))
    if not depFieldName.empty():
        ShowContinueError(state, format("{} is ignored when {} = {}.", fieldName, depFieldName, depFieldValue))

def ShowWarningItemNotFound(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: StringLiteral, defaultVal: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    if defaultVal.empty():
        ShowContinueError(state, format("{} = {}, item not found.", fieldName, fieldVal))
    else:
        ShowContinueError(state, format("{} = {}, item not found, {} will be used.", fieldName, fieldVal, defaultVal))

def ShowWarningBadMin(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMin: Clusive, minVal: Real64, msg: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {:.2R}, but must be {} {:.2R}", fieldName, fieldVal, ">=" if cluMin.value == Clusive.In().value else ">", minVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def ShowWarningBadMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMax: Clusive, maxVal: Real64, msg: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {:.2R}, but must be {} {:.2R}", fieldName, fieldVal, "<=" if cluMax.value == Clusive.In().value else "<", maxVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def ShowWarningBadMinMax(inout state: EnergyPlusData, eoh: ErrorObjectHeader, fieldName: StringLiteral, fieldVal: Real64, cluMin: Clusive, minVal: Real64, cluMax: Clusive, maxVal: Real64, msg: StringLiteral = ""):
    ShowWarningError(state, format("{}: {} = {}", eoh.routineName, eoh.objectType, eoh.objectName))
    ShowContinueError(state, format("{} = {}, but must be {} {} and {} {}", fieldName, fieldVal, ">=" if cluMin.value == Clusive.In().value else ">", minVal, "<=" if cluMax.value == Clusive.In().value else "<", maxVal))
    if not msg.empty():
        ShowContinueError(state, format("{}", msg))

def AbortEnergyPlus(inout state: EnergyPlusData) -> Int32:
    var NumWarnings: String
    var NumSevere: String
    var NumWarningsDuringWarmup: String
    var NumSevereDuringWarmup: String
    var NumWarningsDuringSizing: String
    var NumSevereDuringSizing: String
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteSimulationRecord(True, False)
    state.dataErrTracking.AbortProcessing = True
    if state.dataErrTracking.AskForConnectionsReport:
        state.dataErrTracking.AskForConnectionsReport = False
        ShowMessage(state, "Fatal error -- final processing.  More error messages may appear.")
        Node.SetupNodeVarsForReporting(state)
        var ErrFound = False
        var TerminalError = False
        BranchInputManager.TestBranchIntegrity(state, ErrFound)
        if ErrFound:
            TerminalError = True
        TestAirPathIntegrity(state, ErrFound)
        if ErrFound:
            TerminalError = True
        Node.CheckMarkedNodes(state, ErrFound)
        if ErrFound:
            TerminalError = True
        Node.CheckNodeConnections(state, ErrFound)
        if ErrFound:
            TerminalError = True
        Node.TestCompSetInletOutletNodes(state, ErrFound)
        if ErrFound:
            TerminalError = True
        if not TerminalError:
            SystemReports.ReportAirLoopConnections(state)
            SimulationManager.ReportLoopConnections(state)
    elif not state.dataErrTracking.ExitDuringSimulations:
        ShowMessage(state, "Warning:  Node connection errors not checked - most system input has not been read (see previous warning).")
        ShowMessage(state, "Fatal error -- final processing.  Program exited before simulations began.  See previous error messages.")
    if state.dataErrTracking.AskForSurfacesReport:
        ReportSurfaces(state)
    SolarShading.ReportSurfaceErrors(state)
    PlantManager.CheckPlantOnAbort(state)
    ShowRecurringErrors(state)
    SummarizeErrors(state)
    CloseMiscOpenFiles(state)
    NumWarnings = str(state.dataErrTracking.TotalWarningErrors)
    NumSevere = str(state.dataErrTracking.TotalSevereErrors)
    NumWarningsDuringWarmup = str(state.dataErrTracking.TotalWarningErrorsDuringWarmup)
    NumSevereDuringWarmup = str(state.dataErrTracking.TotalSevereErrorsDuringWarmup)
    NumWarningsDuringSizing = str(state.dataErrTracking.TotalWarningErrorsDuringSizing)
    NumSevereDuringSizing = str(state.dataErrTracking.TotalSevereErrorsDuringSizing)
    state.dataSysVars.runtimeTimer.tock()
    var Elapsed = state.dataSysVars.runtimeTimer.formatAsHourMinSecs()
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime(Elapsed)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup(NumWarningsDuringWarmup, NumSevereDuringWarmup)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing(NumWarningsDuringSizing, NumSevereDuringSizing)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary(NumWarnings, NumSevere)
    ShowMessage(state, format("EnergyPlus Warmup Error Summary. During Warmup: {} Warning; {} Severe Errors.", NumWarningsDuringWarmup, NumSevereDuringWarmup))
    ShowMessage(state, format("EnergyPlus Sizing Error Summary. During Sizing: {} Warning; {} Severe Errors.", NumWarningsDuringSizing, NumSevereDuringSizing))
    ShowMessage(state, format("EnergyPlus Terminated--Fatal Error Detected. {} Warning; {} Severe Errors; Elapsed Time={}", NumWarnings, NumSevere, Elapsed))
    DisplayString(state, "EnergyPlus Run Time=" + Elapsed)
    var tempfl = state.files.endFile.try_open(state.files.outputControl.end)
    if not tempfl.good():
        DisplayString(state, format("AbortEnergyPlus: Could not open file {} for output (write).", tempfl.filePath))
    print(tempfl, "EnergyPlus Terminated--Fatal Error Detected. {} Warning; {} Severe Errors; Elapsed Time={}\n", NumWarnings, NumSevere, Elapsed)
    state.dataResultsFramework.resultsFramework.writeOutputs(state)
    print("Program terminated: EnergyPlus Terminated--Error(s) Detected.")
    if state.dataExternalInterface.NumExternalInterfaces > 0:
        ExternalInterface.CloseSocket(state, -1)
    if state.dataGlobal.eplusRunningViaAPI:
        state.files.flushAll()
    state.files.audit.close()
    return 1

def CloseMiscOpenFiles(inout state: EnergyPlusData):
    Dayltg.CloseReportIllumMaps(state)
    Dayltg.CloseDFSFile(state)
    if state.dataReportFlag.DebugOutput or (state.files.debug.good() and state.files.debug.position() > 0):
        state.files.debug.close()
    else:
        state.files.debug.del()

def EndEnergyPlus(inout state: EnergyPlusData) -> Int32:
    var NumWarnings: String
    var NumSevere: String
    var NumWarningsDuringWarmup: String
    var NumSevereDuringWarmup: String
    var NumWarningsDuringSizing: String
    var NumSevereDuringSizing: String
    if state.dataSQLiteProcedures.sqlite:
        state.dataSQLiteProcedures.sqlite.updateSQLiteSimulationRecord(True, True)
    SolarShading.ReportSurfaceErrors(state)
    ShowRecurringErrors(state)
    SummarizeErrors(state)
    CloseMiscOpenFiles(state)
    NumWarnings = str(state.dataErrTracking.TotalWarningErrors)
    strip(NumWarnings)
    NumSevere = str(state.dataErrTracking.TotalSevereErrors)
    strip(NumSevere)
    NumWarningsDuringWarmup = str(state.dataErrTracking.TotalWarningErrorsDuringWarmup)
    strip(NumWarningsDuringWarmup)
    NumSevereDuringWarmup = str(state.dataErrTracking.TotalSevereErrorsDuringWarmup)
    strip(NumSevereDuringWarmup)
    NumWarningsDuringSizing = str(state.dataErrTracking.TotalWarningErrorsDuringSizing)
    strip(NumWarningsDuringSizing)
    NumSevereDuringSizing = str(state.dataErrTracking.TotalSevereErrorsDuringSizing)
    strip(NumSevereDuringSizing)
    state.dataSysVars.runtimeTimer.tock()
    if state.dataGlobal.createPerfLog:
        Util.appendPerfLog(state, "Run Time [seconds]", format("{:.2R}", state.dataSysVars.runtimeTimer.elapsedSeconds()))
    var Elapsed = state.dataSysVars.runtimeTimer.formatAsHourMinSecs()
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime(Elapsed)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup(NumWarningsDuringWarmup, NumSevereDuringWarmup)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing(NumWarningsDuringSizing, NumSevereDuringSizing)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary(NumWarnings, NumSevere)
    if state.dataGlobal.createPerfLog:
        Util.appendPerfLog(state, "Run Time [string]", Elapsed)
        Util.appendPerfLog(state, "Number of Warnings", NumWarnings)
        Util.appendPerfLog(state, "Number of Severe", NumSevere, True)
    ShowMessage(state, format("EnergyPlus Warmup Error Summary. During Warmup: {} Warning; {} Severe Errors.", NumWarningsDuringWarmup, NumSevereDuringWarmup))
    ShowMessage(state, format("EnergyPlus Sizing Error Summary. During Sizing: {} Warning; {} Severe Errors.", NumWarningsDuringSizing, NumSevereDuringSizing))
    ShowMessage(state, format("EnergyPlus Completed Successfully-- {} Warning; {} Severe Errors; Elapsed Time={}", NumWarnings, NumSevere, Elapsed))
    DisplayString(state, "EnergyPlus Run Time=" + Elapsed)
    var tempfl = state.files.endFile.try_open(state.files.outputControl.end)
    if not tempfl.good():
        DisplayString(state, format("EndEnergyPlus: Could not open file {} for output (write).", tempfl.filePath))
    print(tempfl, "EnergyPlus Completed Successfully-- {} Warning; {} Severe Errors; Elapsed Time={}\n", NumWarnings, NumSevere, Elapsed)
    state.dataResultsFramework.resultsFramework.writeOutputs(state)
    if state.dataGlobal.printConsoleOutput:
        print("EnergyPlus Completed Successfully.")
    if (state.dataExternalInterface.NumExternalInterfaces > 0) and state.dataExternalInterface.haveExternalInterfaceBCVTB:
        ExternalInterface.CloseSocket(state, 1)
    if state.dataGlobal.fProgressPtr != None:
        state.dataGlobal.fProgressPtr(100)
    if state.dataGlobal.progressCallback:
        state.dataGlobal.progressCallback(100)
    if state.dataGlobal.eplusRunningViaAPI:
        state.files.flushAll()
    state.files.audit.close()
    return 0

def ConvertCaseToUpper(InputString: StringLiteral, inout OutputString: String):
    var UpperCase: StringLiteral = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ"
    var LowerCase: StringLiteral = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    OutputString = InputString
    for A in range(len(InputString)):
        var B = index(LowerCase, InputString[A])
        if B != -1:
            OutputString[A] = UpperCase[B]

def ConvertCaseToLower(InputString: StringLiteral, inout OutputString: String):
    var UpperCase: StringLiteral = "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ"
    var LowerCase: StringLiteral = "abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüý"
    OutputString = InputString
    for A in range(len(InputString)):
        var B = index(UpperCase, InputString[A])
        if B != -1:
            OutputString[A] = LowerCase[B]

def FindNonSpace(String: String) -> Int:
    return String.find_first_not_of(' ')

def getEnumValue(sList: Span[StringLiteral], s: StringLiteral) -> Int32:
    for i in range(len(sList)):
        if sList[i] == s:
            return i
    return -1

def getYesNoValue(s: StringLiteral) -> BooleanSwitch:
    return BooleanSwitch(getEnumValue(yesNoNamesUC, s))

def fclamp(v: Real64, min: Real64, max: Real64) -> Real64:
    return min if v < min else (max if v > max else v)

namespace Util:
    var MonthNamesCC: StaticArray[StringLiteral, 12] = StaticArray[StringLiteral, 12]("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")
    var MonthNamesUC: StaticArray[StringLiteral, 12] = StaticArray[StringLiteral, 12]("JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER")

    def ProcessNumber(String: StringLiteral, inout ErrorFlag: Bool) -> Real64:
        var rProcessNumber: Real64 = 0.0
        ErrorFlag = False
        if String.empty():
            return rProcessNumber
        var front_trim = String.find_first_not_of(' ')
        var back_trim = String.find_last_not_of(' ')
        if front_trim == -1 or back_trim == -1:
            return rProcessNumber
        var trimmed = String[front_trim:back_trim + 1]
        var result = fast_float.from_chars(trimmed.data(), trimmed.data() + trimmed.size(), rProcessNumber)
        var remaining_size = result.ptr - trimmed.data()
        if result.ec == std.errc.result_out_of_range or result.ec == std.errc.invalid_argument:
            rProcessNumber = 0.0
            ErrorFlag = True
        elif remaining_size != trimmed.size():
            if result.ptr[0] == '+' or result.ptr[0] == '-':
                result.ptr += 1
                remaining_size = result.ptr - trimmed.data()
                if remaining_size == trimmed.size():
                    rProcessNumber = 0.0
                    ErrorFlag = True
            if result.ptr[0] == 'd' or result.ptr[0] == 'D':
                var str = String(trimmed)
                str = str.replace("D", "e").replace("d", "e")
                return ProcessNumber(str, ErrorFlag)
            if result.ptr[0] == 'e' or result.ptr[0] == 'E':
                result.ptr += 1
                remaining_size = result.ptr - trimmed.data()
                for i in range(remaining_size, trimmed.size()):
                    if not isdigit(result.ptr[0]):
                        rProcessNumber = 0.0
                        ErrorFlag = True
                        return rProcessNumber
                    result.ptr += 1
            else:
                rProcessNumber = 0.0
                ErrorFlag = True
        elif not isfinite(rProcessNumber):
            rProcessNumber = 0.0
            ErrorFlag = True
        return rProcessNumber

    def FindItemInList(String: StringLiteral, ListOfItems: Array1_string, NumItems: Int32) -> Int32:
        for Count in range(1, NumItems + 1):
            if String == ListOfItems[Count]:
                return Count
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: Array1S_string, NumItems: Int32) -> Int32:
        for Count in range(1, NumItems + 1):
            if String == ListOfItems[Count]:
                return Count
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: Array1_string) -> Int32:
        return Util.FindItemInList(String, ListOfItems, ListOfItems.isize())

    def FindItemInList(String: StringLiteral, ListOfItems: Array1S_string) -> Int32:
        return Util.FindItemInList(String, ListOfItems, ListOfItems.isize())

    def FindIntInList(inout list: Array1_int, item: Int32) -> Int32:
        var it = list.find(item)
        return -1 if it == -1 else it

    def FindIntInList(inout list: List[Int32], item: Int32) -> Int32:
        var it = list.find(item)
        return -1 if it == -1 else it

    def FindItemInList(String: StringLiteral, ListOfItems: Array1S_string, NumItems: Int32) -> Int32:
        for Count in range(1, NumItems + 1):
            if String == ListOfItems[Count]:
                return Count
        return 0

    def FindItemInList(str: StringLiteral, first: Pointer[String], last: Pointer[String]) -> Int32:
        var it = first
        var idx = 0
        while it < last:
            if str == it[0]:
                return idx + 1
            it += 1
            idx += 1
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: Array1S_string) -> Int32:
        return Util.FindItemInList(String, ListOfItems, ListOfItems.isize())

    def FindItemInList(String: StringLiteral, ListOfItems: MArray1[A, String], NumItems: Int32) -> Int32:
        for Count in range(1, NumItems + 1):
            if String == ListOfItems[Count]:
                return Count
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: MArray1[A, String]) -> Int32:
        return Util.FindItemInList(String, ListOfItems, ListOfItems.isize())

    def FindItemInList(String: StringLiteral, ListOfItems: Container, NumItems: Int32) -> Int32:
        for i in range(NumItems):
            if String == ListOfItems[i].Name:
                return i + 1
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: Container) -> Int32:
        return Util.FindItemInList(String, ListOfItems, ListOfItems.isize())

    def FindItemInList(String: StringLiteral, ListOfItems: Container, name_p: Pointer[String], NumItems: Int32) -> Int32:
        for i in range(NumItems):
            if String == ListOfItems[i].*name_p:
                return i + 1
        return 0

    def FindItemInList(String: StringLiteral, ListOfItems: Container, name_p: Pointer[String]) -> Int32:
        return Util.FindItemInList(String, ListOfItems, name_p, ListOfItems.isize())

    def FindItem(first: Pointer[Container], last: Pointer[Container], str: StringLiteral, false_type: Bool) -> Int32:
        var it = first
        var idx = 0
        while it < last:
            if it[0].name == str:
                return idx + 1
            it += 1
            idx += 1
        it = first
        idx = 0
        while it < last:
            if equali(it[0].name, str):
                return idx + 1
            it += 1
            idx += 1
        return 0

    def FindItem(first: Pointer[Pointer[Container]], last: Pointer[Pointer[Container]], str: StringLiteral, true_type: Bool) -> Int32:
        var it = first
        var idx = 0
        while it < last:
            if it[0][].name == str:
                return idx + 1
            it += 1
            idx += 1
        it = first
        idx = 0
        while it < last:
            if equali(it[0][].name, str):
                return idx + 1
            it += 1
            idx += 1
        return 0

    def FindItem(first: Pointer[Container], last: Pointer[Container], str: StringLiteral) -> Int32:
        return FindItem(first, last, str, is_shared_ptr[Container]())

    def FindItem(String: StringLiteral, ListOfItems: Array1D_string, NumItems: Int32) -> Int32:
        var FindItem = Util.FindItemInList(String, ListOfItems, NumItems)
        if FindItem != 0:
            return FindItem
        for Count in range(1, NumItems + 1):
            if equali(String, ListOfItems[Count]):
                return Count
        return 0

    def FindItem(String: StringLiteral, ListOfItems: Array1D_string) -> Int32:
        return FindItem(String, ListOfItems, ListOfItems.isize())

    def FindItem(String: StringLiteral, ListOfItems: Array1S_string, NumItems: Int32) -> Int32:
        var FindItem = Util.FindItemInList(String, ListOfItems, NumItems)
        if FindItem != 0:
            return FindItem
        for Count in range(1, NumItems + 1):
            if equali(String, ListOfItems[Count]):
                return Count
        return 0

    def FindItem(String: StringLiteral, ListOfItems: Array1S_string) -> Int32:
        return FindItem(String, ListOfItems, ListOfItems.isize())

    def FindItem(String: StringLiteral, ListOfItems: MArray1[A, String], NumItems: Int32) -> Int32:
        var item_number = Util.FindItemInList(String, ListOfItems, NumItems)
        if item_number != 0:
            return item_number
        for Count in range(1, NumItems + 1):
            if equali(String, ListOfItems[Count]):
                return Count
        return 0

    def FindItem(String: StringLiteral, ListOfItems: MArray1[A, String]) -> Int32:
        return FindItem(String, ListOfItems, ListOfItems.isize())

    def FindItem(String: StringLiteral, ListOfItems: Container, NumItems: Int32) -> Int32:
        var item_number = Util.FindItemInList(String, ListOfItems, NumItems)
        if item_number != 0:
            return item_number
        for i in range(NumItems):
            if equali(String, ListOfItems[i].Name):
                return i + 1
        return 0

    def FindItem(String: StringLiteral, ListOfItems: Container) -> Int32:
        return FindItem(String, ListOfItems, ListOfItems.isize())

    def FindItem(String: StringLiteral, ListOfItems: Container, name_p: Pointer[String], NumItems: Int32) -> Int32:
        var item_number = Util.FindItemInList(String, ListOfItems, name_p, NumItems)
        if item_number != 0:
            return item_number
        for i in range(NumItems):
            if equali(String, ListOfItems[i].*name_p):
                return i + 1
        return 0

    def FindItem(String: StringLiteral, ListOfItems: Container, name_p: Pointer[String]) -> Int32:
        return FindItem(String, ListOfItems, name_p, ListOfItems.isize())

    def makeUPPER(InputString: StringLiteral) -> String:
        var ResultString = String(InputString)
        for i in range(len(InputString)):
            var curCharVal = Int32(InputString[i])
            if (97 <= curCharVal and curCharVal <= 122) or (224 <= curCharVal and curCharVal <= 255):
                ResultString[i] = chr(curCharVal - 32)
        return ResultString

    def SameString(s: StringLiteral, t: StringLiteral) -> Bool:
        return equali(s, t)

    def setDesignObjectNameAndPointer(inout state: EnergyPlusData, inout nameToBeSet: String, inout ptrToBeSet: Int32, userName: String, listOfNames: Array1S_string, itemType: String, itemName: String, inout errorFound: Bool):
        nameToBeSet = userName
        ptrToBeSet = FindItemInList(nameToBeSet, listOfNames)
        if ptrToBeSet <= 0:
            errorFound = True
            ShowSevereError(state, format("Object = {} with the Name = {} has an invalid Design Object Name = {}.", itemType, itemName, nameToBeSet))
            ShowContinueError(state, "  The Design Object Name was not found or was left blank.  This is not allowed.")
            ShowContinueError(state, format("  A valid Design Object Name must be provided for any {} object.", itemType))

    struct case_insensitive_hasher:
        def __call__(self, key: StringLiteral) -> Int:
            var keyCopy = makeUPPER(key)
            return hash(keyCopy)

    struct case_insensitive_comparator:
        def __call__(self, a: StringLiteral, b: StringLiteral) -> Bool:
            return lessthani(a, b)

    def appendPerfLog(inout state: EnergyPlusData, colHeader: String, colValue: String, finalColumn: Bool = False):
        if colHeader == "RESET" and colValue == "RESET":
            state.dataUtilityRoutines.appendPerfLog_headerRow = ""
            state.dataUtilityRoutines.appendPerfLog_valuesRow = ""
            return
        state.dataUtilityRoutines.appendPerfLog_headerRow = state.dataUtilityRoutines.appendPerfLog_headerRow + colHeader + ","
        state.dataUtilityRoutines.appendPerfLog_valuesRow = state.dataUtilityRoutines.appendPerfLog_valuesRow + colValue + ","
        if finalColumn:
            var fsPerfLog: FStream
            if not FileSystem.fileExists(state.dataStrGlobals.outputPerfLogFilePath):
                if state.files.outputControl.perflog:
                    fsPerfLog.open(state.dataStrGlobals.outputPerfLogFilePath, FStream.out)
                    if not fsPerfLog:
                        ShowFatalError(state, format("appendPerfLog: Could not open file \"{}\" for output (write).", state.dataStrGlobals.outputPerfLogFilePath))
                    fsPerfLog.write(state.dataUtilityRoutines.appendPerfLog_headerRow + "\n")
                    fsPerfLog.write(state.dataUtilityRoutines.appendPerfLog_valuesRow + "\n")
            else:
                if state.files.outputControl.perflog:
                    fsPerfLog.open(state.dataStrGlobals.outputPerfLogFilePath, FStream.app)
                    if not fsPerfLog:
                        ShowFatalError(state, format("appendPerfLog: Could not open file \"{}\" for output (append).", state.dataStrGlobals.outputPerfLogFilePath))
                    fsPerfLog.write(state.dataUtilityRoutines.appendPerfLog_valuesRow + "\n")
            fsPerfLog.close()