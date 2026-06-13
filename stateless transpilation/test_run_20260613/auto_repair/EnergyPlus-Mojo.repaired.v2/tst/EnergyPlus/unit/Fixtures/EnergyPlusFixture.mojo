from gtest import testing, Test, EXPECT_EQ, EXPECT_TRUE, UnitTest, TestInfo
from nlohmann.json import json
from mem import unique_ptr, ostringstream, ostream, streambuf
from algorithm import replace
from .........EnergyPlus.DataStringGlobals import DataStringGlobals
from .........EnergyPlus.EnergyPlus import EnergyPlusData, ShowMessage
from .........EnergyPlus.FileSystem import fs
from .........EnergyPlus.UtilityRoutines import ShowMessage
from .........EnergyPlus.Data.CommonIncludes import CommonIncludes  # placeholder
from .........EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from .........EnergyPlus.DataIPShortCuts import DataIPShortCuts
from .........EnergyPlus.FluidProperties import FluidProperties  # placeholder
from .........EnergyPlus.InputProcessing.IdfParser import IdfParser
from .........EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from .........EnergyPlus.InputProcessing.InputValidation import InputValidation
from .........EnergyPlus.Psychrometrics import Psychrometrics  # placeholder
from .........EnergyPlus.ReportCoilSelection import ReportCoilSelection  # placeholder
from .........EnergyPlus.SQLiteProcedures import SQLiteProcedures, ParseSQLiteInput
from .........EnergyPlus.SimulationManager import SimulationManager
from ......TestHelpers.CustomMatchers import CustomMatchers  # placeholder, not used directly

def operator<<[T: AnyType](stream: ostream, e: T) -> ostream:
    stream << int(e)
    return stream

struct RedirectCout:
    var m_old_buffer: unique_ptr[streambuf]
    def __init__(self, m_buffer: unique_ptr[ostringstream]):
        self.m_old_buffer = cout.rdbuf(m_buffer->rdbuf())
    def __del__(self):
        cout.rdbuf(self.m_old_buffer.release())

struct RedirectCerr:
    var m_old_buffer: unique_ptr[streambuf]
    def __init__(self, m_buffer: unique_ptr[ostringstream]):
        self.m_old_buffer = cerr.rdbuf(m_buffer->rdbuf())
    def __del__(self):
        cerr.rdbuf(self.m_old_buffer.release())

class EnergyPlusFixture(Test):
    var state: EnergyPlusData
    var err_stream: ostringstream
    var m_cout_buffer: unique_ptr[ostringstream]
    var m_cerr_buffer: unique_ptr[ostringstream]
    var m_delightin_stream: unique_ptr[ostringstream]
    var m_redirect_cout: unique_ptr[RedirectCout]
    var m_redirect_cerr: unique_ptr[RedirectCerr]

    @staticmethod
    def TearDownTestCase():

    @overridden
    def SetUp(self):
        self.state = EnergyPlusData()
        self.show_message()
        self.openOutputFiles(self.state)
        self.err_stream = ostringstream()
        self.state.files.err_stream = unique_ptr[ostream](self.err_stream)
        self.m_cout_buffer = unique_ptr[ostringstream](ostringstream())
        self.m_redirect_cout = unique_ptr[RedirectCout](RedirectCout(self.m_cout_buffer))
        self.m_cerr_buffer = unique_ptr[ostringstream](ostringstream())
        self.m_redirect_cerr = unique_ptr[RedirectCerr](RedirectCerr(self.m_cerr_buffer))
        self.state.dataUtilityRoutines.outputErrorHeader = False
        self.state.init_constant_state(self.state)
        self.state.dataEnvrn.StdRhoAir = 1.2

    @overridden
    def TearDown(self):
        self.state.files.mtd.del()
        self.state.files.eso.del()
        self.state.files.err_stream.reset()
        self.state.files.eio.del()
        self.state.files.debug.del()
        self.state.files.zsz.del()
        self.state.files.spsz.del()
        self.state.files.ssz.del()
        self.state.files.mtr.del()
        self.state.files.bnd.del()
        self.state.files.shade.del()
        self.state.clear_state()
        del self.state

    def show_message(self):
        var test_info: TestInfo = UnitTest.GetInstance().current_test_info()
        ShowMessage(self.state, "Begin Test: " + String(test_info.test_case_name()) + ", " + String(test_info.name()))

    @staticmethod
    def delimited_string(strings: List[String], delimiter: String = "\n") -> String:
        var compare_text: ostringstream
        for str in strings:
            compare_text << str << delimiter
        return compare_text.str()

    def read_lines_in_file(self, filePath: fs.path) -> List[String]:
        var infile: ifstream = ifstream(filePath)
        var lines: List[String]
        var line: String
        while True:
            if not getline(infile, line):
                break
            lines.push_back(line)
        return lines

    def compare_eso_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.state.files.eso.get_output()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.state.files.eso.open_as_stringstream()
        return are_equal

    def compare_eio_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.state.files.eio.get_output()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.state.files.eio.open_as_stringstream()
        return are_equal

    def compare_eio_stream_substring(self, search_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.state.files.eio.get_output()
        var found: Bool = stream_str.find(search_string) != npos
        EXPECT_TRUE(found)
        if reset_stream:
            self.state.files.eio.open_as_stringstream()
        return found

    def compare_mtr_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.state.files.mtr.get_output()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.state.files.mtr.open_as_stringstream()
        return are_equal

    def compare_err_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.err_stream.str()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.err_stream.str(String())
        return are_equal

    def compare_err_stream_substring(self, search_string: String, reset_stream: Bool = True, call_expect: Bool = True) -> Bool:
        var stream_str: String = self.err_stream.str()
        var found: Bool = stream_str.find(search_string) != npos
        if call_expect:
            EXPECT_TRUE(found) << "Not found in:" << "\n" << stream_str
        if reset_stream:
            self.err_stream.str(String())
        return found

    def compare_cout_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.m_cout_buffer.str()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.m_cout_buffer.str(String())
        return are_equal

    def compare_cout_stream_substring(self, search_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.m_cout_buffer.str()
        var found: Bool = stream_str.find(search_string) != npos
        if reset_stream:
            self.m_cout_buffer.str(String())
        return found

    def compare_cerr_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.m_cerr_buffer.str()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.m_cerr_buffer.str(String())
        return are_equal

    def compare_dfs_stream(self, expected_string: String, reset_stream: Bool = True) -> Bool:
        var stream_str: String = self.state.files.dfs.get_output()
        EXPECT_EQ(expected_string, stream_str)
        var are_equal: Bool = (expected_string == stream_str)
        if reset_stream:
            self.state.files.dfs.open_as_stringstream()
        return are_equal

    def has_eso_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.state.files.eso.get_output().empty()
        if reset_stream:
            self.state.files.eso.open_as_stringstream()
        return has_output

    def has_eio_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.state.files.eio.get_output().empty()
        if reset_stream:
            self.state.files.eio.open_as_stringstream()
        return has_output

    def has_mtr_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.state.files.mtr.get_output().empty()
        if reset_stream:
            self.state.files.mtr.open_as_stringstream()
        return has_output

    def has_err_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.err_stream.str().empty()
        if reset_stream:
            self.err_stream.str(String())
        return has_output

    def has_cout_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.m_cout_buffer.str().empty()
        if reset_stream:
            self.m_cout_buffer.str(String())
        return has_output

    def has_cerr_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.m_cerr_buffer.str().empty()
        if reset_stream:
            self.m_cerr_buffer.str(String())
        return has_output

    def has_dfs_output(self, reset_stream: Bool = True) -> Bool:
        var has_output: Bool = not self.state.files.dfs.get_output().empty()
        if reset_stream:
            self.state.files.dfs.open_as_stringstream()
        return has_output

    def match_err_stream(self, expected_match: String, use_regex: Bool = False, reset_stream: Bool = False) -> Bool:
        var stream_str: String = self.err_stream.str()
        var match_found: Bool
        if use_regex:
            match_found = regex_match(stream_str, Regex(expected_match))
        else:
            match_found = stream_str.find(expected_match) != npos
        if reset_stream:
            self.err_stream.str(String())
        return match_found

    def process_idf(self, idf_snippet: String, use_assertions: Bool = True) -> Bool:
        var success: Bool = True
        var inputProcessor = self.state.dataInputProcessing.inputProcessor
        inputProcessor.epJSON = inputProcessor.idf_parser.decode(idf_snippet, inputProcessor.schema(), success)
        if inputProcessor.epJSON.find("Timestep") == inputProcessor.epJSON.end():
            inputProcessor.epJSON["Timestep"] = {"": {{"idf_order", 0}, {"number_of_timesteps_per_hour", 4}}}
        if inputProcessor.epJSON.find("Version") == inputProcessor.epJSON.end():
            inputProcessor.epJSON["Version"] = {"": {{"idf_order", 0}, {"version_identifier", DataStringGlobals.MatchVersion}}}
        if inputProcessor.epJSON.find("Building") == inputProcessor.epJSON.end():
            inputProcessor.epJSON["Building"] = {"Bldg":
                {{"idf_order", 0},
                 {"north_axis", 0.0},
                 {"terrain", "Suburbs"},
                 {"loads_convergence_tolerance_value", 0.04},
                 {"temperature_convergence_tolerance_value", 0.4000},
                 {"solar_distribution", "FullExterior"},
                 {"maximum_number_of_warmup_days", 25},
                 {"minimum_number_of_warmup_days", 6}}}
        if inputProcessor.epJSON.find("GlobalGeometryRules") == inputProcessor.epJSON.end():
            inputProcessor.epJSON["GlobalGeometryRules"] = {"",
                {{"idf_order", 0},
                 {"starting_vertex_position", "UpperLeftCorner"},
                 {"vertex_entry_direction", "Counterclockwise"},
                 {"coordinate_system", "Relative"},
                 {"daylighting_reference_point_coordinate_system", "Relative"},
                 {"rectangular_surface_coordinate_system", "Relative"}}}
        var MaxArgs: Int = 0
        var MaxAlpha: Int = 0
        var MaxNumeric: Int = 0
        inputProcessor.getMaxSchemaArgs(MaxArgs, MaxAlpha, MaxNumeric)
        self.state.dataIPShortCut.cAlphaFieldNames.allocate(MaxAlpha)
        self.state.dataIPShortCut.cAlphaArgs.allocate(MaxAlpha)
        self.state.dataIPShortCut.lAlphaFieldBlanks.dimension(MaxAlpha, False)
        self.state.dataIPShortCut.cNumericFieldNames.allocate(MaxNumeric)
        self.state.dataIPShortCut.rNumericArgs.dimension(MaxNumeric, 0.0)
        self.state.dataIPShortCut.lNumericFieldBlanks.dimension(MaxNumeric, False)
        var is_valid: Bool = inputProcessor.validation.validate(inputProcessor.epJSON)
        var hasErrors: Bool = inputProcessor.processErrors(self.state)
        inputProcessor.initializeMaps()
        SimulationManager.PostIPProcessing(self.state)
        if self.state.dataSQLiteProcedures.sqlite:
            var writeOutputToSQLite: Bool = False
            var writeTabularDataToSQLite: Bool = False
            ParseSQLiteInput(self.state, writeOutputToSQLite, writeTabularDataToSQLite)
        var successful_processing: Bool = success and is_valid and not hasErrors
        if not successful_processing and use_assertions:
            EXPECT_TRUE(self.compare_err_stream(""))
        return successful_processing

    def openOutputFiles(self, state: EnergyPlusData):
        state.files.eio.open_as_stringstream()
        state.files.mtr.open_as_stringstream()
        state.files.eso.open_as_stringstream()
        state.files.audit.open_as_stringstream()
        state.files.bnd.open_as_stringstream()
        state.files.debug.open_as_stringstream()
        state.files.mtd.open_as_stringstream()
        state.files.edd.open_as_stringstream()
        state.files.zsz.open_as_stringstream()
        state.files.spsz.open_as_stringstream()
        state.files.ssz.open_as_stringstream()

    def replace_pipes_with_spaces(self, stringLiteral: String):
        replace(stringLiteral.begin(), stringLiteral.end(), '|', ' ')

    def compare_containers[T: AnyType, T2: AnyType](self, expected_container: T, actual_container: T2) -> Bool:
        var is_valid: Bool = (expected_container.size() == actual_container.size())
        EXPECT_EQ(expected_container.size(), actual_container.size()) << "Containers are not equal size."
        var expected = expected_container.begin()
        var actual = actual_container.begin()
        while expected != expected_container.end():
            EXPECT_EQ(*expected, *actual) << "Incorrect 0-based index: " << (expected - expected_container.begin())
            is_valid = (*expected == *actual)
            expected += 1
            actual += 1
        return is_valid