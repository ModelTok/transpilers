from testing import test, assertEqual, assertTrue, assertFalse, assertAlmostEqual
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataStringGlobals import DataStringGlobals
from EnergyPlus.DisplayRoutines import DisplayString
from EnergyPlus.FileSystem import fs, File
from EnergyPlus.UtilityRoutines import ShowRecurringWarningErrorAtEnd, ShowRecurringContinueErrorAtEnd, ShowRecurringSevereErrorAtEnd, Util, ShowDetailedSevereItemNotFound, ShowSevereItemNotFound
from .Fixtures.EnergyPlusFixture import has_cout_output, compare_err_stream, delimited_string, ErrorObjectHeader

@test
def RecurringWarningTest():
    var state = EnergyPlusData()
    var myMessage1 = "Test message 1"
    var ErrIndex1 = 0
    ShowRecurringWarningErrorAtEnd(state, myMessage1, ErrIndex1)
    assertEqual(ErrIndex1, 1)
    assertEqual(len(state.dataErrTracking.RecurringErrors), 1)
    assertEqual(" ** Warning ** " + myMessage1, state.dataErrTracking.RecurringErrors[0].Message)
    assertEqual(1, state.dataErrTracking.RecurringErrors[0].Count)
    var myMessage2 = "Test message 2"
    var ErrIndex2 = 6
    ShowRecurringWarningErrorAtEnd(state, myMessage2, ErrIndex2)
    assertEqual(ErrIndex2, 2)
    assertEqual(len(state.dataErrTracking.RecurringErrors), 2)
    assertEqual(" ** Warning ** " + myMessage2, state.dataErrTracking.RecurringErrors[1].Message)
    assertEqual(1, state.dataErrTracking.RecurringErrors[1].Count)
    ErrIndex2 = 6
    ShowRecurringWarningErrorAtEnd(state, myMessage2, ErrIndex2)
    assertEqual(ErrIndex2, 2)
    assertEqual(len(state.dataErrTracking.RecurringErrors), 2)
    assertEqual(" ** Warning ** " + myMessage2, state.dataErrTracking.RecurringErrors[1].Message)
    assertEqual(2, state.dataErrTracking.RecurringErrors[1].Count)
    var myMessage3 = "Test message 3"
    ShowRecurringContinueErrorAtEnd(state, myMessage3, ErrIndex1)
    assertEqual(ErrIndex1, 3)
    assertEqual(len(state.dataErrTracking.RecurringErrors), 3)
    assertEqual(" **   ~~~   ** " + myMessage3, state.dataErrTracking.RecurringErrors[2].Message)
    assertEqual(1, state.dataErrTracking.RecurringErrors[2].Count)
    var myMessage4 = "Test message 4"
    ShowRecurringSevereErrorAtEnd(state, myMessage4, ErrIndex1)
    assertEqual(ErrIndex1, 4)
    assertEqual(len(state.dataErrTracking.RecurringErrors), 4)
    assertEqual(" ** Severe  ** " + myMessage4, state.dataErrTracking.RecurringErrors[3].Message)
    assertEqual(1, state.dataErrTracking.RecurringErrors[3].Count)
    ShowRecurringWarningErrorAtEnd(state, myMessage4, ErrIndex1)
    assertEqual(ErrIndex1, 5)
    assertEqual(" ** Warning ** " + myMessage4, state.dataErrTracking.RecurringErrors[4].Message)

@test
def DisplayMessageTest():
    var state = EnergyPlusData()
    DisplayString(state, "Testing")
    assertTrue(has_cout_output(True))
    DisplayString(state, "Testing")
    assertTrue(has_cout_output(True))
    assertFalse(has_cout_output(True))
    DisplayString(state, "Testing")
    assertTrue(has_cout_output(True))

@test
def UtilityRoutines_appendPerfLog1():
    var state = EnergyPlusData()
    state.dataStrGlobals.outputPerfLogFilePath = "eplusout_1_perflog.csv"
    fs.remove(state.dataStrGlobals.outputPerfLogFilePath)
    Util.appendPerfLog(state, "RESET", "RESET")
    Util.appendPerfLog(state, "header1", "value1-1")
    Util.appendPerfLog(state, "header2", "value1-2")
    Util.appendPerfLog(state, "header3", "value1-3", True)
    var perfLogFile = File(state.dataStrGlobals.outputPerfLogFilePath, "r")
    var perfLogContents = perfLogFile.read()
    perfLogFile.close()
    var expectedContents = "header1,header2,header3,\n" +
                           "value1-1,value1-2,value1-3,\n"
    assertEqual(perfLogContents, expectedContents)
    fs.remove(state.dataStrGlobals.outputPerfLogFilePath)

@test
def UtilityRoutines_appendPerfLog2():
    var state = EnergyPlusData()
    Util.appendPerfLog(state, "RESET", "RESET")
    state.dataStrGlobals.outputPerfLogFilePath = "eplusout_2_perflog.csv"
    var initPerfLogFile = File(state.dataStrGlobals.outputPerfLogFilePath, "w")
    initPerfLogFile.write("header1,header2,header3,\n")
    initPerfLogFile.write("value1-1,value1-2,value1-3,\n")
    initPerfLogFile.close()
    Util.appendPerfLog(state, "ignored1", "value2-1")
    Util.appendPerfLog(state, "ignored2", "value2-2")
    Util.appendPerfLog(state, "ignored3", "value2-3", True)
    var perfLogFile = File(state.dataStrGlobals.outputPerfLogFilePath, "r")
    var perfLogContents = perfLogFile.read()
    perfLogFile.close()
    var expectedContents = "header1,header2,header3,\n" +
                           "value1-1,value1-2,value1-3,\n" +
                           "value2-1,value2-2,value2-3,\n"
    assertEqual(perfLogContents, expectedContents)
    fs.remove(state.dataStrGlobals.outputPerfLogFilePath)

@test
def UtilityRoutines_ProcessNumber():
    var goodString = "3.14159"
    var expectedVal = 3.14159
    var expectedError = False
    assertAlmostEqual(Util.ProcessNumber(goodString, expectedError), expectedVal, delta=1E-5)
    assertFalse(expectedError)
    goodString = "3.14159+E0"
    assertAlmostEqual(Util.ProcessNumber(goodString, expectedError), expectedVal, delta=1E-5)
    assertFalse(expectedError)
    goodString = "3.14159+e0"
    assertAlmostEqual(Util.ProcessNumber(goodString, expectedError), expectedVal, delta=1E-5)
    assertFalse(expectedError)
    goodString = "3.14159+D0"
    assertAlmostEqual(Util.ProcessNumber(goodString, expectedError), expectedVal, delta=1E-5)
    assertFalse(expectedError)
    goodString = "3.14159+d0"
    assertAlmostEqual(Util.ProcessNumber(goodString, expectedError), expectedVal, delta=1E-5)
    assertFalse(expectedError)
    var badString = "É.14159"
    expectedVal = 0.0
    assertAlmostEqual(Util.ProcessNumber(badString, expectedError), expectedVal, delta=1E-5)
    assertTrue(expectedError)
    badString = "3.14159É0"
    expectedVal = 0.0
    assertAlmostEqual(Util.ProcessNumber(badString, expectedError), expectedVal, delta=1E-5)
    assertTrue(expectedError)
    badString = "3.14159 0"
    expectedVal = 0.0
    assertAlmostEqual(Util.ProcessNumber(badString, expectedError), expectedVal, delta=1E-5)
    assertTrue(expectedError)
    badString = "E3.14159"
    expectedVal = 0.0
    assertAlmostEqual(Util.ProcessNumber(badString, expectedError), expectedVal, delta=1E-5)
    assertTrue(expectedError)
    badString = "1E5000"
    expectedVal = 0.0
    assertAlmostEqual(Util.ProcessNumber(badString, expectedError), expectedVal, delta=1E-5)
    assertTrue(expectedError)

@test
def UtilityRoutines_setDesignObjectNameAndPointerTest():
    var state = EnergyPlusData()
    var nameResult: String
    var expectedName: String
    var ptrResult = -99
    var expectedPtr = -99
    var userName: String
    var userNames = ["First Name", "Second Name", "Third Name", "Fourth Name"]
    var objectType: String
    var objectName: String
    var gotErrors = False
    userName = "Second Name"
    expectedName = "Second Name"
    expectedPtr = 2
    objectType = "ZoneHVAC:LowTemperatureRadiant:VariableFlow"
    objectName = "MyVarFlowRadSys"
    gotErrors = False
    Util.setDesignObjectNameAndPointer(state, nameResult, ptrResult, userName, userNames, objectType, objectName, gotErrors)
    assertFalse(gotErrors)
    assertEqual(nameResult, expectedName)
    assertEqual(ptrResult, expectedPtr)
    userName = "No Name"
    expectedName = ""
    expectedPtr = 0
    objectType = "ZoneHVAC:Baseboard:RadiantConvective:Water"
    objectName = "MyWaterBB"
    gotErrors = False
    Util.setDesignObjectNameAndPointer(state, nameResult, ptrResult, userName, userNames, objectType, objectName, gotErrors)
    var error_stringTest2 = delimited_string([
        "   ** Severe  ** Object = ZoneHVAC:Baseboard:RadiantConvective:Water with the Name = MyWaterBB has an invalid Design Object Name = No Name.",
        "   **   ~~~   **   The Design Object Name was not found or was left blank.  This is not allowed.",
        "   **   ~~~   **   A valid Design Object Name must be provided for any ZoneHVAC:Baseboard:RadiantConvective:Water object.",
    ])
    assertTrue(compare_err_stream(error_stringTest2, True))
    assertTrue(gotErrors)
    userName = ""
    expectedName = ""
    expectedPtr = 0
    objectType = "ZoneHVAC:Baseboard:RadiantConvective:Steam"
    objectName = "MySteamBB"
    gotErrors = False
    Util.setDesignObjectNameAndPointer(state, nameResult, ptrResult, userName, userNames, objectType, objectName, gotErrors)
    var error_stringTest3 = delimited_string([
        "   ** Severe  ** Object = ZoneHVAC:Baseboard:RadiantConvective:Steam with the Name = MySteamBB has an invalid Design Object Name = .",
        "   **   ~~~   **   The Design Object Name was not found or was left blank.  This is not allowed.",
        "   **   ~~~   **   A valid Design Object Name must be provided for any ZoneHVAC:Baseboard:RadiantConvective:Steam object.",
    ])
    assertTrue(compare_err_stream(error_stringTest3, True))
    assertTrue(gotErrors)

@test
def UtilityRoutines_ShowDetailedSevereItemNotFound():
    var state = EnergyPlusData()
    var detailed_error_message = "TestRoutine: MissingField = CanNotBeFound, item not found."
    var error_message = "TestRoutine:  ="
    var eoh = ErrorObjectHeader("TestRoutine", "", "")
    ShowDetailedSevereItemNotFound(state, eoh, "MissingField", "CanNotBeFound")
    assertTrue(state.dataErrTracking.LastSevereError.find(detailed_error_message) != -1)
    ShowSevereItemNotFound(state, eoh, "MissingField", "CanNotBeFound")
    assertTrue(state.dataErrTracking.LastSevereError.find(error_message) != -1)