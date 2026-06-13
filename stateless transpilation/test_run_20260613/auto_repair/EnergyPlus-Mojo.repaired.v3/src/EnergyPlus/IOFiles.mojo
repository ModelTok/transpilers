from algorithm import *
from format import *
from memory import *
from embedded.EmbeddedEpJSONSchema import *
from IOFiles import *
from .Data.EnergyPlusData import *
from DataStringGlobals import *
from FileSystem import *
from .InputProcessing.InputProcessor import *
from ResultsFramework import *
from UtilityRoutines import *

@value
struct DoubleWrapper:
    var value: Float64
    def __init__(inout self, val: Float64):
        self.value = val
    def __get_value(self) -> Float64:
        return self.value
    def __set_value(inout self, other: Float64):
        self.value = other

def should_be_fixed_output(value: Float64) -> Bool:
    return (value >= 0.099999999999999995 or value <= -0.099999999999999995) or (value == 0.0) or (value == -0.0)

def fixed_will_fit(value: Float64, places: Int) -> Bool:
    if value < 1.0 and value > -1.0:
        return True
    return Int(math.log10(math.abs(value))) < places

def zero_pad_exponent(inout str: String) -> String:
    if len(str) > 3:
        if str[len(str) - 3].isdigit() == False:
            str = str[:len(str) - 2] + "0" + str[len(str) - 2:]
    return str

def is_fortran_syntax(format_str: String) -> Bool:
    var within_fmt_str: Bool = False
    for c in format_str:
        if c == '{':
            within_fmt_str = True
        elif c == '}':
            within_fmt_str = False
        elif c == 'R':
            if within_fmt_str:
                return True
    return False

def check_syntax(format_str: String) -> FormatSyntax:
    if is_fortran_syntax(format_str):
        return FormatSyntax.Fortran
    return FormatSyntax.FMT

@value
struct ReadResult[T: AnyType]:
    var data: T
    var eof: Bool
    var good: Bool
    def __init__(inout self, data_: T, eof_: Bool, good_: Bool):
        self.data = data_
        self.eof = eof_
        self.good = good_
    def update(inout self, other: ReadResult[T]):
        self.eof = other.eof
        self.good = other.good
        if self.good:
            self.data = other.data

@value
struct InputFile:
    var filePath: fs.path
    var file_size: UInt64 = 0
    var is: Optional[__islocal__ std.istream] = None

    def ensure_open(inout self, state: EnergyPlusData, caller: String, output_to_file: Bool = True) -> Self:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            ShowFatalError(state, "{}: Could not open file {} for input (read).".format(caller, self.filePath))
        return self

    def good(self) -> Bool:
        if self.is:
            return self.is.good()
        return False

    def close(inout self):
        self.is = None

    def readLine(inout self) -> ReadResult[String]:
        if not self.is:
            return ReadResult[String]("", True, False)
        var line: String
        if std.getline(self.is, line):
            if len(line) > 0 and line[-1] == '\r':
                line = line[:-1]
            return ReadResult[String](line, self.is.eof(), bool(self.is))
        return ReadResult[String]("", self.is.eof(), False)

    def readFile(inout self) -> String:
        var result = String(self.file_size, '\0')
        self.is.read(result.data(), self.file_size)
        return result

    def readJSON(inout self) -> nlohmann.json:
        var ext = FileSystem.getFileType(self.filePath)
        if ext == FileSystem.FileTypes.EpJSON or ext == FileSystem.FileTypes.JSON or ext == FileSystem.FileTypes.GLHE:
            return nlohmann.json.parse(self.is, None, True, True)
        elif ext == FileSystem.FileTypes.CBOR:
            return nlohmann.json.from_cbor(self.is)
        elif ext == FileSystem.FileTypes.MsgPack:
            return nlohmann.json.from_msgpack(self.is)
        elif ext == FileSystem.FileTypes.UBJSON:
            return nlohmann.json.from_ubjson(self.is)
        elif ext == FileSystem.FileTypes.BSON:
            return nlohmann.json.from_bson(self.is)
        else:
            raise FatalError("Invalid file extension. Must be epJSON, JSON, or other experimental extensions")

    def __init__(inout self, FilePath: fs.path):
        self.filePath = FilePath

    def position(self) -> std.ostream.pos_type:
        return self.is.tellg()

    def open(inout self, _: Bool = False, _: Bool = True):
        self.file_size = fs.file_size(self.filePath)
        self.is = std.make_unique[std.fstream](self.filePath.c_str(), std.ios_base.in | std.ios_base.binary)

    def error_state_to_string(self) -> String:
        var state = self.rdstate()
        if not self.is_open():
            return "file not opened'"
        if state == std.ios_base.failbit:
            return "io operation failed"
        if state == std.ios_base.badbit:
            return "irrecoverable stream error"
        if state == std.ios_base.eofbit:
            return "end of file reached"
        return "no error"

    def rdstate(self) -> std.istream.iostate:
        if self.is:
            return self.is.rdstate()
        return std.ios_base.badbit

    def is_open(self) -> Bool:
        if self.is:
            var ss = dynamic_cast[std.ifstream](self.is.get())
            if ss != None:
                return ss.is_open()
            return True
        return False

    def backspace(inout self):
        if self.is:
            self.is.clear()
            var g1 = self.is.tellg()
            self.is.seekg(0, std.ios.beg)
            var g0 = self.is.tellg()
            self.is.seekg(g1, std.ios.beg)
            if g1 > g0:
                g1 -= 1
            while g1 > g0:
                g1 -= 1
                self.is.seekg(g1, std.ios.beg)
                if self.is.peek() == '\n':
                    g1 += 1
                    self.is.seekg(g1, std.ios.beg)
                    break

@value
struct InputOutputFile:
    var filePath: fs.path
    var defaultToStdOut: Bool = False
    var os: Optional[__islocal__ std.iostream] = None
    var print_to_dev_null: Bool = False

    def ensure_open(inout self, state: EnergyPlusData, caller: String, output_to_file: Bool = True) -> Self:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            ShowFatalError(state, "{}: Could not open file {} for output (write).".format(caller, self.filePath))
        return self

    def good(self) -> Bool:
        if self.os and self.print_to_dev_null and self.os.bad():
            return True
        if self.os:
            return self.os.good()
        return False

    def close(inout self):
        self.os = None

    def del(inout self):
        if self.os:
            self.os = None
            FileSystem.removeFile(self.filePath)

    def open_as_stringstream(inout self):
        self.os = std.make_unique[std.stringstream]()

    def flush(inout self):
        if self.os:
            self.os.flush()

    def get_output(inout self) -> String:
        var ss = dynamic_cast[std.stringstream](self.os.get())
        if ss != None:
            return ss.str()
        return ""

    def __init__(inout self, FilePath: fs.path, DefaultToStdOut: Bool = False):
        self.filePath = FilePath
        self.defaultToStdOut = DefaultToStdOut

    def position(self) -> std.ostream.pos_type:
        return self.os.tellg()

    def open(inout self, forAppend: Bool = False, output_to_file: Bool = True):
        var appendMode = std.ios_base.trunc
        if forAppend:
            appendMode = std.ios_base.app
        if not output_to_file:
            self.os = std.make_unique[std.iostream](None)
            self.print_to_dev_null = True
        else:
            self.os = std.make_unique[std.fstream](self.filePath.c_str(), std.ios_base.in | std.ios_base.out | appendMode)
            self.print_to_dev_null = False

    def getLines(inout self) -> List[String]:
        if self.os:
            self.os.flush()
            var last_pos = self.os.tellg()
            var line: String
            var lines = List[String]()
            self.os.seekg(0)
            while std.getline(self.os, line):
                lines.append(line)
            self.os.clear()
            self.os.seekg(last_pos)
            return lines
        return List[String]()

@value
struct IOFilePath[FileType: AnyType]:
    var filePath: fs.path
    def open(inout self, state: EnergyPlusData, caller: String, output_to_file: Bool = True) -> FileType:
        var file = FileType(self.filePath)
        file.ensure_open(state, caller, output_to_file)
        return file
    def try_open(inout self, output_to_file: Bool = True) -> FileType:
        var file = FileType(self.filePath)
        file.open(False, output_to_file)
        return file

alias InputOutputFilePath = IOFilePath[InputOutputFile]
alias InputFilePath = IOFilePath[InputFile]

@value
struct JsonOutputFilePaths:
    var outputJsonFilePath: fs.path
    var outputTSHvacJsonFilePath: fs.path
    var outputTSZoneJsonFilePath: fs.path
    var outputTSJsonFilePath: fs.path
    var outputYRJsonFilePath: fs.path
    var outputMNJsonFilePath: fs.path
    var outputDYJsonFilePath: fs.path
    var outputHRJsonFilePath: fs.path
    var outputSMJsonFilePath: fs.path
    var outputCborFilePath: fs.path
    var outputTSHvacCborFilePath: fs.path
    var outputTSZoneCborFilePath: fs.path
    var outputTSCborFilePath: fs.path
    var outputYRCborFilePath: fs.path
    var outputMNCborFilePath: fs.path
    var outputDYCborFilePath: fs.path
    var outputHRCborFilePath: fs.path
    var outputSMCborFilePath: fs.path
    var outputMsgPackFilePath: fs.path
    var outputTSHvacMsgPackFilePath: fs.path
    var outputTSZoneMsgPackFilePath: fs.path
    var outputTSMsgPackFilePath: fs.path
    var outputYRMsgPackFilePath: fs.path
    var outputMNMsgPackFilePath: fs.path
    var outputDYMsgPackFilePath: fs.path
    var outputHRMsgPackFilePath: fs.path
    var outputSMMsgPackFilePath: fs.path

@value
struct IOFiles:
    @value
    struct OutputControl:
        var csv: Bool = False
        var mtr: Bool = True
        var eso: Bool = True
        var eio: Bool = True
        var audit: Bool = True
        var spsz: Bool = True
        var zsz: Bool = True
        var ssz: Bool = True
        var psz: Bool = True
        var dxf: Bool = True
        var bnd: Bool = True
        var rdd: Bool = True
        var mdd: Bool = True
        var mtd: Bool = True
        var end: Bool = True
        var shd: Bool = True
        var dfs: Bool = True
        var delightin: Bool = True
        var delighteldmp: Bool = True
        var delightdfdmp: Bool = True
        var edd: Bool = True
        var dbg: Bool = True
        var perflog: Bool = True
        var sln: Bool = True
        var sci: Bool = True
        var wrl: Bool = True
        var screen: Bool = True
        var tarcog: Bool = True
        var extshd: Bool = True
        var json: Bool = True
        var tabular: Bool = True
        var sqlite: Bool = True

        def __init__(inout self): pass

        def writeTabular(inout self, state: EnergyPlusData) -> Bool:
            var htmlTabular = state.files.outputControl.tabular
            var jsonTabular = state.files.outputControl.json and state.dataResultsFramework.resultsFramework.timeSeriesAndTabularEnabled()
            var sqliteTabular = state.files.outputControl.sqlite
            return (htmlTabular or jsonTabular or sqliteTabular)

        def getInput(inout self, state: EnergyPlusData):
            var ip = state.dataInputProcessing.inputProcessor
            var instances = ip.epJSON.find("OutputControl:Files")
            if instances != ip.epJSON.end():
                def find_input(fields: nlohmann.json, field_name: String, state: EnergyPlusData) -> String:
                    var input: String
                    var found = fields.find(field_name)
                    if found != fields.end():
                        input = found.value().get[String]()
                        input = Util.makeUPPER(input)
                    else:
                        state.dataInputProcessing.inputProcessor.getDefaultValue(state, "OutputControl:Files", field_name, input)
                    return input
                def boolean_choice(input: String, state: EnergyPlusData) -> Bool:
                    if input == "YES":
                        return True
                    if input == "NO":
                        return False
                    ShowFatalError(state, "Invalid boolean Yes/No choice input")
                    return True
                var instancesValue = instances.value()
                for instance in instancesValue:
                    var fields = instance.value()
                    ip.markObjectAsUsed("OutputControl:Files", instance.key())
                    self.csv = boolean_choice(find_input(fields, "output_csv", state), state)
                    self.mtr = boolean_choice(find_input(fields, "output_mtr", state), state)
                    self.eso = boolean_choice(find_input(fields, "output_eso", state), state)
                    self.eio = boolean_choice(find_input(fields, "output_eio", state), state)
                    self.audit = boolean_choice(find_input(fields, "output_audit", state), state)
                    self.spsz = boolean_choice(find_input(fields, "output_space_sizing", state), state)
                    self.zsz = boolean_choice(find_input(fields, "output_zone_sizing", state), state)
                    self.ssz = boolean_choice(find_input(fields, "output_system_sizing", state), state)
                    self.dxf = boolean_choice(find_input(fields, "output_dxf", state), state)
                    self.bnd = boolean_choice(find_input(fields, "output_bnd", state), state)
                    self.rdd = boolean_choice(find_input(fields, "output_rdd", state), state)
                    self.mdd = boolean_choice(find_input(fields, "output_mdd", state), state)
                    self.mtd = boolean_choice(find_input(fields, "output_mtd", state), state)
                    self.end = boolean_choice(find_input(fields, "output_end", state), state)
                    self.shd = boolean_choice(find_input(fields, "output_shd", state), state)
                    self.dfs = boolean_choice(find_input(fields, "output_dfs", state), state)
                    self.delightin = boolean_choice(find_input(fields, "output_delightin", state), state)
                    self.delighteldmp = boolean_choice(find_input(fields, "output_delighteldmp", state), state)
                    self.delightdfdmp = boolean_choice(find_input(fields, "output_delightdfdmp", state), state)
                    self.edd = boolean_choice(find_input(fields, "output_edd", state), state)
                    self.dbg = boolean_choice(find_input(fields, "output_dbg", state), state)
                    self.perflog = boolean_choice(find_input(fields, "output_perflog", state), state)
                    self.sln = boolean_choice(find_input(fields, "output_sln", state), state)
                    self.sci = boolean_choice(find_input(fields, "output_sci", state), state)
                    self.wrl = boolean_choice(find_input(fields, "output_wrl", state), state)
                    self.screen = boolean_choice(find_input(fields, "output_screen", state), state)
                    self.tarcog = boolean_choice(find_input(fields, "output_tarcog", state), state)
                    self.extshd = boolean_choice(find_input(fields, "output_extshd", state), state)
                    self.json = boolean_choice(find_input(fields, "output_json", state), state)
                    self.tabular = boolean_choice(find_input(fields, "output_tabular", state), state)
                    self.sqlite = boolean_choice(find_input(fields, "output_sqlite", state), state)
                    self.psz = boolean_choice(find_input(fields, "output_plant_component_sizing", state), state)
            var timestamp_instances = ip.epJSON.find("OutputControl:Timestamp")
            if timestamp_instances != ip.epJSON.end():
                var instancesValue = timestamp_instances.value()
                for instance in instancesValue:
                    var fields = instance.value()
                    ip.markObjectAsUsed("OutputControl:Timestamp", instance.key())
                    var item = fields.find("iso_8601_format")
                    if item != fields.end():
                        state.dataResultsFramework.resultsFramework.setISO8601(item.get[String]() == "Yes")
                    item = fields.find("timestamp_at_beginning_of_interval")
                    if item != fields.end():
                        state.dataResultsFramework.resultsFramework.setBeginningOfInterval(item.get[String]() == "Yes")

    var outputControl: OutputControl
    var audit: InputOutputFile = InputOutputFile(fs.path("eplusout.audit"))
    var eio: InputOutputFile = InputOutputFile(fs.path("eplusout.eio"))
    var eso: InputOutputFile = InputOutputFile(fs.path("eplusout.eso"))
    var zsz: InputOutputFile = InputOutputFile(fs.path(""))
    var outputZszCsvFilePath: fs.path = fs.path("epluszsz.csv")
    var outputZszTabFilePath: fs.path = fs.path("epluszsz.tab")
    var outputZszTxtFilePath: fs.path = fs.path("epluszsz.txt")
    var spsz: InputOutputFile = InputOutputFile(fs.path(""))
    var outputSpszCsvFilePath: fs.path = fs.path("eplusspsz.csv")
    var outputSpszTabFilePath: fs.path = fs.path("eplusspsz.tab")
    var outputSpszTxtFilePath: fs.path = fs.path("eplusspsz.txt")
    var ssz: InputOutputFile = InputOutputFile(fs.path(""))
    var outputSszCsvFilePath: fs.path = fs.path("eplusssz.csv")
    var outputSszTabFilePath: fs.path = fs.path("eplusssz.tab")
    var outputSszTxtFilePath: fs.path = fs.path("eplusssz.txt")
    var psz: InputOutputFile = InputOutputFile(fs.path(""))
    var outputPszCsvFilePath: fs.path = fs.path("epluspsz.csv")
    var outputPszTabFilePath: fs.path = fs.path("epluspsz.tab")
    var outputPszTxtFilePath: fs.path = fs.path("epluspsz.txt")
    var map: InputOutputFile = InputOutputFile(fs.path(""))
    var outputMapCsvFilePath: fs.path = fs.path("eplusmap.csv")
    var outputMapTabFilePath: fs.path = fs.path("eplusmap.tab")
    var outputMapTxtFilePath: fs.path = fs.path("eplusmap.txt")
    var mtr: InputOutputFile = InputOutputFile(fs.path("eplusout.mtr"))
    var bnd: InputOutputFile = InputOutputFile(fs.path("eplusout.bnd"))
    var rdd: InputOutputFile = InputOutputFile(fs.path("eplusout.rdd"))
    var mdd: InputOutputFile = InputOutputFile(fs.path("eplusout.mdd"))
    var debug: InputOutputFile = InputOutputFile(fs.path("eplusout.dbg"))
    var dfs: InputOutputFile = InputOutputFile(fs.path("eplusout.dfs"))
    var sln: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.sln"))
    var dxf: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.dxf"))
    var sci: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.sci"))
    var wrl: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.wrl"))
    var delightIn: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.delightin"))
    var mtd: InputOutputFile = InputOutputFile(fs.path("eplusout.mtd"))
    var edd: InputOutputFile = InputOutputFile(fs.path("eplusout.edd"), True)
    var shade: InputOutputFile = InputOutputFile(fs.path("eplusshading.csv"))
    var csv: InputOutputFile = InputOutputFile(fs.path("eplusout.csv"))
    var mtr_csv: InputOutputFile = InputOutputFile(fs.path("eplusmtr.csv"))
    var screenCsv: InputOutputFilePath = InputOutputFilePath(fs.path("eplusscreen.csv"))
    var endFile: InputOutputFilePath = InputOutputFilePath(fs.path("eplusout.end"))
    var iniFile: InputFilePath = InputFilePath(fs.path("EnergyPlus.ini"))
    var outputDelightEldmpFilePath: InputFilePath = InputFilePath(fs.path("eplusout.delighteldmp"))
    var outputDelightDfdmpFilePath: InputFilePath = InputFilePath(fs.path("eplusout.delightdfdmp"))
    var inputWeatherFilePath: InputFilePath = InputFilePath(fs.path(""))
    var inputWeatherFile: InputFile = InputFile(fs.path(""))
    var TempFullFilePath: InputFilePath = InputFilePath(fs.path(""))
    var inStatFilePath: InputFilePath = InputFilePath(fs.path(""))
    var outputErrFilePath: fs.path = fs.path("eplusout.err")
    var err_stream: Optional[__islocal__ std.ostream] = None
    var json: JsonOutputFilePaths

    def __init__(inout self):

    def flushAll(inout self):
        self.audit.flush()
        self.eio.flush()
        self.eso.flush()
        self.zsz.flush()
        self.spsz.flush()
        self.ssz.flush()
        self.map.flush()
        self.mtr.flush()
        self.bnd.flush()
        self.rdd.flush()
        self.mdd.flush()
        self.debug.flush()
        self.dfs.flush()
        self.mtd.flush()
        self.edd.flush()
        self.shade.flush()
        self.csv.flush()
        if self.err_stream:
            self.err_stream.flush()

@value
struct SharedFileHandle:
    var file: Optional[__shared__ InputOutputFile] = None

    def ptr(inout self) -> InputOutputFile:
        if not self.file:
            self.file = InputOutputFile(fs.path(""))
        return self.file

    def __getitem__(inout self) -> InputOutputFile:
        return self.ptr()

    def __getattr__(inout self, name: String) -> InputOutputFile:
        return self.ptr()

def vprint[T: AnyVariadic](inout os: std.ostream, format_str: String, args: T):
    var buffer = fmt.memory_buffer()
    try:
        fmt.format_to(std.back_inserter(buffer), fmt.runtime(format_str), args)
    except fmt.format_error:
        raise EnergyPlus.FatalError("Error with format, '{}', passed {} args".format(format_str, len(args)))
    os.write(buffer.data(), len(buffer))

def vprint[T: AnyVariadic](format_str: String, args: T) -> String:
    var buffer = fmt.memory_buffer()
    try:
        fmt.format_to(std.back_inserter(buffer), fmt.runtime(format_str), args)
    except fmt.format_error:
        raise EnergyPlus.FatalError("Error with format, '{}', passed {} args".format(format_str, len(args)))
    return fmt.to_string(buffer)

def print_fortran_syntax[T: AnyVariadic](inout os: std.ostream, format_str: String, args: T):
    vprint[__type_map[T, DoubleWrapper if __type_is[T, Float64] else T]...](os, format_str, args)

def format_fortran_syntax[T: AnyVariadic](format_str: String, args: T) -> String:
    return vprint[__type_map[T, DoubleWrapper if __type_is[T, Float64] else T]...](format_str, args)

def print[formatSyntax: FormatSyntax = FormatSyntax.Fortran, T: AnyVariadic](inout os: std.ostream, format_str: String, args: T):
    if formatSyntax == FormatSyntax.Fortran:
        print_fortran_syntax(os, format_str, args)
    elif formatSyntax == FormatSyntax.FMT:
        fmt.print(os, fmt.runtime(format_str), args)
    else:
        static_assert(False, "Invalid FormatSyntax selection")

def print[formatSyntax: FormatSyntax, T: AnyVariadic](inout outputFile: InputOutputFile, format_str: String, args: T):
    var outputStream: std.ostream
    if outputFile.os:
        outputStream = outputFile.os
    elif outputFile.defaultToStdOut:
        outputStream = std.cout
    else:
        assert(outputFile.os)
    if formatSyntax == FormatSyntax.Fortran:
        print_fortran_syntax(outputStream, format_str, args)
    elif formatSyntax == FormatSyntax.FMT:
        fmt.print(outputStream, format_str, args)
    else:
        static_assert(False, "Invalid FormatSyntax selection")

def format[formatSyntax: FormatSyntax = FormatSyntax.Fortran, T: AnyVariadic](format_str: String, args: T) -> String:
    if formatSyntax == FormatSyntax.Fortran:
        return format_fortran_syntax(format_str, args)
    elif formatSyntax == FormatSyntax.FMT:
        return fmt.format(fmt.runtime(format_str), args)
    elif formatSyntax == FormatSyntax.Printf:
        return fmt.sprintf(format_str, args)