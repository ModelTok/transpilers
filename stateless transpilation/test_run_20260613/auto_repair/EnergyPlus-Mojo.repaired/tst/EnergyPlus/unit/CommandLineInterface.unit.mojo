from testing import *
from EnergyPlus.CommandLineInterface import *
from EnergyPlus.ConfiguredFunctions import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.FileSystem import *
from Fixtures.EnergyPlusFixture import *
from fmt import format as fmt_format
from algorithm import *
from array import *
from iterator import *
from string import *
from thread import *
from type_traits import *
from vector import *
from memory import *
from os import path as fs_path
from sys import *

using EnergyPlus
using EnergyPlus.CommandLineInterface

struct ExpectedParams:
    var AnnualSimulation: Bool = False
    var DDOnlySimulation: Bool = False
    var outDirPath: fs_path
    var inputIddFilePath: fs_path = "Energy+.idd"
    var runExpandObjects: Bool = False
    var runEPMacro: Bool = False
    var runReadVars: Bool = False
    var outputEpJSONConversion: Bool = False
    var outputEpJSONConversionOnly: Bool = False
    var numThread: Int = 1
    var inputWeatherFilePath: fs_path = "in.epw"
    var inputFilePath: fs_path = "in.idf"
    var prefixOutName: String = "eplus"
    var suffixType: String = "L"
    var VerStringVar: String = EnergyPlus.DataStringGlobals.VerString

class CommandLineInterfaceFixture(EnergyPlusFixture):
    var expectedParams: ExpectedParams

    @staticmethod
    def SetUpTestCase():
        EnergyPlusFixture.SetUpTestCase()
        {
            var destPath = FileSystem.getAbsolutePath("in.idf")
            if not fs_path.is_regular_file(destPath):
                var inputFilePath = configured_source_directory() / "tst/EnergyPlus/unit/Resources/UnitaryHybridUnitTest_DOSA.idf"
                fs_path.copy_file(inputFilePath, destPath, fs_path.copy_options.skip_existing)
        }
        {
            var destPath = FileSystem.getAbsolutePath("in.epw")
            if not fs_path.is_regular_file(destPath):
                var inputWeatherFilePath = configured_source_directory() / "weather/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
                fs_path.copy_file(inputWeatherFilePath, destPath, fs_path.copy_options.skip_existing)
        }

    def __init__(inout self):
        EnergyPlusFixture.__init__(self)
        self.state.dataGlobal.eplusRunningViaAPI = True
        self.expectedParams.inputIddFilePath = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(FileSystem.getProgramPath())) / "Energy+.idd"

    def processArgsHelper(inout self, input: List[String]) -> Int:
        input.insert(0, "energyplus")
        return ProcessArgs(self.state, input)

    @staticmethod
    def CompareX[T1: AnyType, T2: AnyType](lhs_expression: String, rhs_expression: String, lhs: T1, rhs: T2, inout ss: StringStream, file: String, line: Int) -> Bool:
        var assertion_result = testing.internal.EqHelper.Compare(lhs_expression, rhs_expression, lhs, rhs)
        if not assertion_result:
            ss << '\n' << assertion_result.message() << '\n' << file << ":" << line
            return False
        return True

    def testExpected(inout self, expectedParams: ExpectedParams) -> testing.AssertionResult:
        var ss = StringStream()
        var result = True
        result &= self.FORMAT_EXPECT_EQ(expectedParams.AnnualSimulation, self.state.dataGlobal.AnnualSimulation, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.DDOnlySimulation, self.state.dataGlobal.DDOnlySimulation, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.outDirPath, self.state.dataStrGlobals.outDirPath, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.inputIddFilePath, self.state.dataStrGlobals.inputIddFilePath, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.runReadVars, self.state.dataGlobal.runReadVars, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.outputEpJSONConversion, self.state.dataGlobal.outputEpJSONConversion, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.outputEpJSONConversionOnly, self.state.dataGlobal.outputEpJSONConversionOnly, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.numThread, self.state.dataGlobal.numThread, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.inputWeatherFilePath, self.state.files.inputWeatherFilePath.filePath, ss)
        result &= self.FORMAT_EXPECT_EQ(expectedParams.inputFilePath, self.state.dataStrGlobals.inputFilePath, ss)
        var tableSuffix: String
        if expectedParams.suffixType == "L":
            tableSuffix = "tbl"
        elif expectedParams.suffixType == "D":
            tableSuffix = "-table"
        elif expectedParams.suffixType == "C":
            tableSuffix = "Table"
        var outputTblHtmFilePath: fs_path = expectedParams.outDirPath / fmt_format("{}{}.htm", expectedParams.prefixOutName, tableSuffix)
        result &= self.FORMAT_EXPECT_EQ(outputTblHtmFilePath, self.state.dataStrGlobals.outputTblHtmFilePath, ss)
        if not result:
            return testing.AssertionFailure() << ss.str()
        return testing.AssertionSuccess()

    def FORMAT_EXPECT_EQ[T1: AnyType, T2: AnyType](inout self, v1: T1, v2: T2, inout ss: StringStream) -> Bool:
        return self.CompareX(String(v1), String(v2), v1, v2, ss, __FILE__, __LINE__)

@fixture
def test_Legacy(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputIddFilePath = "Energy+.idd"
    var exitcode = fixture.processArgsHelper(List[String]())
    assert_eq(Int(ReturnCodes.Success), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream("")
    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_IdfOnly(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputFilePath = configured_source_directory() / "tst/EnergyPlus/unit/Resources/UnitaryHybridUnitTest_DOSA.idf"
    var exitcode = fixture.processArgsHelper(List[String](fixture.expectedParams.inputFilePath.generic_string()))
    assert_eq(Int(ReturnCodes.Success), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream("")
    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_IdfOnly_NativePath(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputFilePath = FileSystem.makeNativePath(configured_source_directory() / "tst/EnergyPlus/unit/Resources/UnitaryHybridUnitTest_DOSA.idf")
    var exitcode = fixture.processArgsHelper(List[String](fixture.expectedParams.inputFilePath.string()))
    assert_eq(Int(ReturnCodes.Success), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream("")
    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_IdfDoesNotExist(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputFilePath = FileSystem.getAbsolutePath("WRONG.IDF")
    var exitcode = fixture.processArgsHelper(List[String](fixture.expectedParams.inputFilePath.generic_string()))
    assert_eq(Int(ReturnCodes.Failure), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream(delimited_string(List[String](
        std_format("input_file: File does not exist: {:g}", fixture.expectedParams.inputFilePath),
        "Run with --help for more information.",
    )))

@fixture
def test_AnnualSimulation(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.AnnualSimulation = True
    for flag in List[String]("-a", "--annual"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_DDSimulation(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.DDOnlySimulation = True
    for flag in List[String]("-D", "--design-day"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_AnnualExcludesDDSimulation(inout fixture: CommandLineInterfaceFixture):
    var exitcode = fixture.processArgsHelper(List[String]("-D", "-a", fixture.expectedParams.inputFilePath.generic_string()))
    assert_eq(Int(ReturnCodes.Failure), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream(delimited_string(List[String](
        "--annual excludes --design-day",
        "Run with --help for more information.",
    )))
    fixture.compare_cerr_stream("")

@fixture
def test_WeatherFileExists(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputWeatherFilePath = configured_source_directory() / "weather/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
    var exitcode = fixture.processArgsHelper(List[String]("-w", fixture.expectedParams.inputWeatherFilePath.generic_string(), fixture.expectedParams.inputFilePath.generic_string()))
    assert_eq(Int(ReturnCodes.Success), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream("")
    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_WeatherFileDoesNotExists(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.inputWeatherFilePath = "WRONG.epw"
    for flag in List[String]("-w", "--weather"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag, fixture.expectedParams.inputWeatherFilePath.generic_string(), fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Failure), exitcode)
            assert_true(fixture.has_cout_output())
            fixture.compare_cerr_stream("")

@fixture
def test_Version(inout fixture: CommandLineInterfaceFixture):
    for flag in List[String]("-v", "--version"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag))
            assert_eq(Int(ReturnCodes.SuccessButHelper), exitcode)
            fixture.compare_cout_stream(delimited_string(List[String](fixture.expectedParams.VerStringVar)))
            fixture.compare_cerr_stream("")

@fixture
def test_Convert(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.outputEpJSONConversion = True
    for flag in List[String]("-c", "--convert"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_ConvertOnly(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.outputEpJSONConversionOnly = True
    var exitcode = fixture.processArgsHelper(List[String]("--convert-only", fixture.expectedParams.inputFilePath.generic_string()))
    assert_eq(Int(ReturnCodes.Success), exitcode)
    fixture.compare_cout_stream("")
    fixture.compare_cerr_stream("")
    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_runReadVars(inout fixture: CommandLineInterfaceFixture):
    fixture.expectedParams.runReadVars = True
    for flag in List[String]("-r", "--readvars"):
        with scoped_trace("Flag: '" + flag + "'"):
            var exitcode = fixture.processArgsHelper(List[String](flag, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_numThread(inout fixture: CommandLineInterfaceFixture):
    if std_getenv("CI") != None:
        return
    struct TestCase:
        var j: Int
        var expectedCorrectedJ: Int
        var errorMessage: String
    var Nproc = Int(std_thread_hardware_concurrency())
    var test_data = List[TestCase](
        TestCase(4, 4, ""),
        TestCase(0, 1, "Invalid value for -j arg. Defaulting to 1."),
        TestCase(100, Nproc, fmt_format("Invalid value for -j arg. Value exceeds num available. Defaulting to num available. -j {}", Nproc)),
    )
    for test_case in test_data:
        with scoped_trace(fmt_format("Passing j={}", test_case.j)):
            fixture.expectedParams.numThread = test_case.expectedCorrectedJ
            for flag in List[String]("-j", "--jobs"):
                with scoped_trace("Flag: '" + flag + "'"):
                    var exitcode = fixture.processArgsHelper(List[String](flag, std_to_string(test_case.j), fixture.expectedParams.inputFilePath.generic_string()))
                    assert_eq(Int(ReturnCodes.Success), exitcode)
                    if test_case.errorMessage.empty():
                        assert_false(fixture.has_cout_output())
                    else:
                        fixture.compare_cout_stream(delimited_string(List[String](test_case.errorMessage)))
                    fixture.compare_cerr_stream("")
                    assert_true(fixture.testExpected(fixture.expectedParams))

@fixture
def test_SuffixPrefix(inout fixture: CommandLineInterfaceFixture):
    {
        with scoped_trace("Short Version"):
            fixture.expectedParams.suffixType = "D"
            fixture.expectedParams.prefixOutName = "prefix"
            var exitcode = fixture.processArgsHelper(List[String]("-s", fixture.expectedParams.suffixType, "-p", fixture.expectedParams.prefixOutName, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))
    }
    {
        with scoped_trace("Long Version"):
            fixture.expectedParams.suffixType = "C"
            fixture.expectedParams.prefixOutName = "other"
            var exitcode = fixture.processArgsHelper(List[String]("--output-suffix", fixture.expectedParams.suffixType, "--output-prefix", fixture.expectedParams.prefixOutName, fixture.expectedParams.inputFilePath.generic_string()))
            assert_eq(Int(ReturnCodes.Success), exitcode)
            fixture.compare_cout_stream("")
            fixture.compare_cerr_stream("")
            assert_true(fixture.testExpected(fixture.expectedParams))
    }