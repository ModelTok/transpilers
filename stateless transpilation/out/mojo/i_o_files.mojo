from math import log10, nextafter, inf, fabs, isnan, isinf
from sys import stdout, stderr
import json


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from Data.EnergyPlusData module
# - FileSystem: module with removeFile, getFileType, FileTypes enum
# - InputProcessor: state.dataInputProcessing.inputProcessor
# - ResultsFramework: state.dataResultsFramework.resultsFramework
# - UtilityRoutines: ShowFatalError, Util.makeUPPER


@value
struct FormatSyntax:
    var value: Int32

    alias INVALID = Self(-1)
    alias FORTRAN = Self(0)
    alias FMT = Self(1)
    alias PRINTF = Self(2)
    alias NUM = Self(3)


fn is_fortran_syntax(format_str: StringRef) -> Bool:
    var within_fmt_str: Bool = False
    for i in range(len(format_str)):
        var c = format_str[i]
        if c == ord('{'):
            within_fmt_str = True
        elif c == ord('}'):
            within_fmt_str = False
        elif c == ord('R'):
            if within_fmt_str:
                return True
    return False


fn check_syntax(format_str: StringRef) -> FormatSyntax:
    if is_fortran_syntax(format_str):
        return FormatSyntax.FORTRAN
    return FormatSyntax.FMT


struct DoubleWrapper:
    var value: Float64

    fn __init__(inout self, val: Float64):
        self.value = val

    fn __float__(self) -> Float64:
        return self.value


fn should_be_fixed_output(value: Float64) -> Bool:
    return (value >= 0.099999999999999995 or value <= -0.099999999999999995) or (value == 0.0) or (value == -0.0)


fn fixed_will_fit(value: Float64, places: Int32) -> Bool:
    if -1.0 < value < 1.0:
        return True
    return Int32(log10(fabs(value))) < places


fn zero_pad_exponent(inout s: String) -> String:
    if len(s) > 3:
        var is_digit: Bool = False
        if s[len(s) - 3] >= ord('0') and s[len(s) - 3] <= ord('9'):
            is_digit = True
        if not is_digit:
            var before = s[:len(s) - 2]
            var after = s[len(s) - 2:]
            s = before + "0" + after
    return s


fn format_double_wrapper(value: Float64, format_spec: StringRef) -> String:
    if format_spec.find("R") >= 0 or len(format_spec) == 0:
        var fixed_output = should_be_fixed_output(value)
        if fixed_output:
            if value > 100000.0:
                var digits10: Int32 = Int32(log10(value))
                if digits10 >= 15:
                    return String(Int32(value)) + "."
                return str(value)
            if value == 0.0 or value == -0.0:
                return "0.0"
            var nudged: Float64 = value
            for _ in range(3):
                if nudged >= 0:
                    nudged = nextafter(nudged, inf)
                else:
                    nudged = nextafter(nudged, -inf)
            return str(nudged)
        else:
            var formatted: String = str(value)
            return zero_pad_exponent(formatted)
    return str(value)


struct ReadResult[T: AnyType]:
    var data: T
    var eof: Bool
    var good: Bool

    fn __init__(inout self, data: T, eof: Bool, good: Bool):
        self.data = data
        self.eof = eof
        self.good = good

    fn update(inout self, owned other: ReadResult[T]) -> None:
        self.eof = other.eof
        self.good = other.good
        if self.good:
            self.data = other.data


struct InputFile:
    var filePath: String
    var file_size: Int
    var is_stream: String

    fn __init__(inout self, file_path: StringRef):
        self.filePath = String(file_path)
        self.file_size = 0
        self.is_stream = ""

    fn close(inout self) -> None:
        self.is_stream = ""

    fn good(self) -> Bool:
        return len(self.is_stream) > 0

    fn is_open(self) -> Bool:
        return len(self.is_stream) > 0

    fn backspace(inout self) -> None:
        pass

    fn error_state_to_string(self) -> String:
        if not self.is_open():
            return "file not opened"
        return "no error"

    fn rdstate(self) -> String:
        if not self.good():
            return "badbit"
        return "goodbit"

    fn ensure_open(inout self, state: UnsafePointer[AnyType], caller: StringRef, output_to_file: Bool = True) -> Self:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            pass
        return self

    fn open(inout self, owned args: Bool = False) -> None:
        pass

    fn position(self) -> Int:
        return 0

    fn rewind(inout self) -> None:
        pass

    fn readLine(inout self) -> ReadResult[String]:
        return ReadResult("", True, False)

    fn read[T: AnyType](inout self) -> ReadResult[T]:
        return ReadResult(T(), True, False)

    fn readFile(inout self) -> String:
        return ""

    fn readJSON(inout self) -> String:
        return ""


struct InputOutputFile:
    var filePath: String
    var defaultToStdOut: Bool
    var os_stream: String
    var print_to_dev_null: Bool

    fn __init__(inout self, file_path: StringRef, default_to_stdout: Bool = False):
        self.filePath = String(file_path)
        self.defaultToStdOut = default_to_stdout
        self.os_stream = ""
        self.print_to_dev_null = False

    fn close(inout self) -> None:
        self.os_stream = ""

    fn del_file(inout self) -> None:
        self.os_stream = ""

    fn good(self) -> Bool:
        if self.print_to_dev_null and len(self.os_stream) > 0:
            return True
        return len(self.os_stream) > 0

    fn ensure_open(inout self, state: UnsafePointer[AnyType], caller: StringRef, output_to_file: Bool = True) -> Self:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            pass
        return self

    fn open(inout self, for_append: Bool = False, output_to_file: Bool = True) -> None:
        if not output_to_file:
            self.os_stream = ""
            self.print_to_dev_null = True
        else:
            self.os_stream = ""
            self.print_to_dev_null = False

    fn open_as_stringstream(inout self) -> None:
        self.os_stream = ""

    fn flush(inout self) -> None:
        pass

    fn get_output(self) -> String:
        return self.os_stream

    fn position(self) -> Int:
        return 0

    fn getLines(self) -> List[String]:
        return List[String]()


struct IOFilePath[T: AnyType]:
    var filePath: String

    fn __init__(inout self, file_path: StringRef):
        self.filePath = String(file_path)

    fn open(inout self, state: UnsafePointer[AnyType], caller: StringRef, output_to_file: Bool = True) -> T:
        return T()

    fn try_open(inout self, output_to_file: Bool = True) -> T:
        return T()


struct JsonOutputFilePaths:
    var outputJsonFilePath: String
    var outputTSHvacJsonFilePath: String
    var outputTSZoneJsonFilePath: String
    var outputTSJsonFilePath: String
    var outputYRJsonFilePath: String
    var outputMNJsonFilePath: String
    var outputDYJsonFilePath: String
    var outputHRJsonFilePath: String
    var outputSMJsonFilePath: String
    var outputCborFilePath: String
    var outputTSHvacCborFilePath: String
    var outputTSZoneCborFilePath: String
    var outputTSCborFilePath: String
    var outputYRCborFilePath: String
    var outputMNCborFilePath: String
    var outputDYCborFilePath: String
    var outputHRCborFilePath: String
    var outputSMCborFilePath: String
    var outputMsgPackFilePath: String
    var outputTSHvacMsgPackFilePath: String
    var outputTSZoneMsgPackFilePath: String
    var outputTSMsgPackFilePath: String
    var outputYRMsgPackFilePath: String
    var outputMNMsgPackFilePath: String
    var outputDYMsgPackFilePath: String
    var outputHRMsgPackFilePath: String
    var outputSMMsgPackFilePath: String

    fn __init__(inout self):
        self.outputJsonFilePath = ""
        self.outputTSHvacJsonFilePath = ""
        self.outputTSZoneJsonFilePath = ""
        self.outputTSJsonFilePath = ""
        self.outputYRJsonFilePath = ""
        self.outputMNJsonFilePath = ""
        self.outputDYJsonFilePath = ""
        self.outputHRJsonFilePath = ""
        self.outputSMJsonFilePath = ""
        self.outputCborFilePath = ""
        self.outputTSHvacCborFilePath = ""
        self.outputTSZoneCborFilePath = ""
        self.outputTSCborFilePath = ""
        self.outputYRCborFilePath = ""
        self.outputMNCborFilePath = ""
        self.outputDYCborFilePath = ""
        self.outputHRCborFilePath = ""
        self.outputSMCborFilePath = ""
        self.outputMsgPackFilePath = ""
        self.outputTSHvacMsgPackFilePath = ""
        self.outputTSZoneMsgPackFilePath = ""
        self.outputTSMsgPackFilePath = ""
        self.outputYRMsgPackFilePath = ""
        self.outputMNMsgPackFilePath = ""
        self.outputDYMsgPackFilePath = ""
        self.outputHRMsgPackFilePath = ""
        self.outputSMMsgPackFilePath = ""


struct OutputControl:
    var csv: Bool
    var mtr: Bool
    var eso: Bool
    var eio: Bool
    var audit: Bool
    var spsz: Bool
    var zsz: Bool
    var ssz: Bool
    var psz: Bool
    var dxf: Bool
    var bnd: Bool
    var rdd: Bool
    var mdd: Bool
    var mtd: Bool
    var end: Bool
    var shd: Bool
    var dfs: Bool
    var delightin: Bool
    var delighteldmp: Bool
    var delightdfdmp: Bool
    var edd: Bool
    var dbg: Bool
    var perflog: Bool
    var sln: Bool
    var sci: Bool
    var wrl: Bool
    var screen: Bool
    var tarcog: Bool
    var extshd: Bool
    var json: Bool
    var tabular: Bool
    var sqlite: Bool

    fn __init__(inout self):
        self.csv = False
        self.mtr = True
        self.eso = True
        self.eio = True
        self.audit = True
        self.spsz = True
        self.zsz = True
        self.ssz = True
        self.psz = True
        self.dxf = True
        self.bnd = True
        self.rdd = True
        self.mdd = True
        self.mtd = True
        self.end = True
        self.shd = True
        self.dfs = True
        self.delightin = True
        self.delighteldmp = True
        self.delightdfdmp = True
        self.edd = True
        self.dbg = True
        self.perflog = True
        self.sln = True
        self.sci = True
        self.wrl = True
        self.screen = True
        self.tarcog = True
        self.extshd = True
        self.json = True
        self.tabular = True
        self.sqlite = True

    fn write_tabular(self, state: UnsafePointer[AnyType]) -> Bool:
        return True

    fn getInput(inout self, state: UnsafePointer[AnyType]) -> None:
        pass


struct IOFiles:
    var outputControl: OutputControl
    var audit: InputOutputFile
    var eio: InputOutputFile
    var eso: InputOutputFile
    var zsz: InputOutputFile
    var outputZszCsvFilePath: String
    var outputZszTabFilePath: String
    var outputZszTxtFilePath: String
    var spsz: InputOutputFile
    var outputSpszCsvFilePath: String
    var outputSpszTabFilePath: String
    var outputSpszTxtFilePath: String
    var ssz: InputOutputFile
    var outputSszCsvFilePath: String
    var outputSszTabFilePath: String
    var outputSszTxtFilePath: String
    var psz: InputOutputFile
    var outputPszCsvFilePath: String
    var outputPszTabFilePath: String
    var outputPszTxtFilePath: String
    var map: InputOutputFile
    var outputMapCsvFilePath: String
    var outputMapTabFilePath: String
    var outputMapTxtFilePath: String
    var mtr: InputOutputFile
    var bnd: InputOutputFile
    var rdd: InputOutputFile
    var mdd: InputOutputFile
    var debug: InputOutputFile
    var dfs: InputOutputFile
    var sln: IOFilePath[InputOutputFile]
    var dxf: IOFilePath[InputOutputFile]
    var sci: IOFilePath[InputOutputFile]
    var wrl: IOFilePath[InputOutputFile]
    var delightIn: IOFilePath[InputOutputFile]
    var mtd: InputOutputFile
    var edd: InputOutputFile
    var shade: InputOutputFile
    var csv: InputOutputFile
    var mtr_csv: InputOutputFile
    var screenCsv: IOFilePath[InputOutputFile]
    var endFile: IOFilePath[InputOutputFile]
    var iniFile: InputFile
    var outputDelightEldmpFilePath: InputFile
    var outputDelightDfdmpFilePath: InputFile
    var inputWeatherFilePath: InputFile
    var inputWeatherFile: InputFile
    var TempFullFilePath: InputFile
    var inStatFilePath: InputFile
    var outputErrFilePath: String
    var err_stream: String
    var json: JsonOutputFilePaths

    fn __init__(inout self):
        self.outputControl = OutputControl()
        self.audit = InputOutputFile("eplusout.audit")
        self.eio = InputOutputFile("eplusout.eio")
        self.eso = InputOutputFile("eplusout.eso")
        self.zsz = InputOutputFile("")
        self.outputZszCsvFilePath = "epluszsz.csv"
        self.outputZszTabFilePath = "epluszsz.tab"
        self.outputZszTxtFilePath = "epluszsz.txt"
        self.spsz = InputOutputFile("")
        self.outputSpszCsvFilePath = "eplusspsz.csv"
        self.outputSpszTabFilePath = "eplusspsz.tab"
        self.outputSpszTxtFilePath = "eplusspsz.txt"
        self.ssz = InputOutputFile("")
        self.outputSszCsvFilePath = "eplusssz.csv"
        self.outputSszTabFilePath = "eplusssz.tab"
        self.outputSszTxtFilePath = "eplusssz.txt"
        self.psz = InputOutputFile("")
        self.outputPszCsvFilePath = "epluspsz.csv"
        self.outputPszTabFilePath = "epluspsz.tab"
        self.outputPszTxtFilePath = "epluspsz.txt"
        self.map = InputOutputFile("")
        self.outputMapCsvFilePath = "eplusmap.csv"
        self.outputMapTabFilePath = "eplusmap.tab"
        self.outputMapTxtFilePath = "eplusmap.txt"
        self.mtr = InputOutputFile("eplusout.mtr")
        self.bnd = InputOutputFile("eplusout.bnd")
        self.rdd = InputOutputFile("eplusout.rdd")
        self.mdd = InputOutputFile("eplusout.mdd")
        self.debug = InputOutputFile("eplusout.dbg")
        self.dfs = InputOutputFile("eplusout.dfs")
        self.sln = IOFilePath[InputOutputFile]("eplusout.sln")
        self.dxf = IOFilePath[InputOutputFile]("eplusout.dxf")
        self.sci = IOFilePath[InputOutputFile]("eplusout.sci")
        self.wrl = IOFilePath[InputOutputFile]("eplusout.wrl")
        self.delightIn = IOFilePath[InputOutputFile]("eplusout.delightin")
        self.mtd = InputOutputFile("eplusout.mtd")
        self.edd = InputOutputFile("eplusout.edd", True)
        self.shade = InputOutputFile("eplusshading.csv")
        self.csv = InputOutputFile("eplusout.csv")
        self.mtr_csv = InputOutputFile("eplusmtr.csv")
        self.screenCsv = IOFilePath[InputOutputFile]("eplusscreen.csv")
        self.endFile = IOFilePath[InputOutputFile]("eplusout.end")
        self.iniFile = InputFile("EnergyPlus.ini")
        self.outputDelightEldmpFilePath = InputFile("eplusout.delighteldmp")
        self.outputDelightDfdmpFilePath = InputFile("eplusout.delightdfdmp")
        self.inputWeatherFilePath = InputFile("")
        self.inputWeatherFile = InputFile("")
        self.TempFullFilePath = InputFile("")
        self.inStatFilePath = InputFile("")
        self.outputErrFilePath = "eplusout.err"
        self.err_stream = ""
        self.json = JsonOutputFilePaths()

    fn flushAll(inout self) -> None:
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


struct SharedFileHandle:
    var file: UnsafePointer[InputOutputFile]

    fn __init__(inout self):
        self.file = UnsafePointer[InputOutputFile].alloc(1)
        self.file.init_pointee_copy(InputOutputFile(""))

    fn ptr(inout self) -> UnsafePointer[InputOutputFile]:
        return self.file

    fn __moveinit__(inout self, owned other: Self):
        self.file = other.file

    fn __del__(owned self):
        self.file.destroy_pointee()
        self.file.free()


fn vprint_stream(os_stream: UnsafePointer[AnyType], format_str: StringRef, *args: VariadicPack[AnyType]) -> None:
    pass


fn vprint_string(format_str: StringRef, *args: VariadicPack[AnyType]) -> String:
    return String(format_str)


fn print_fortran_syntax(os_stream: UnsafePointer[AnyType], format_str: StringRef, *args: VariadicPack[AnyType]) -> None:
    vprint_stream(os_stream, format_str, args)


fn format_fortran_syntax(format_str: StringRef, *args: VariadicPack[AnyType]) -> String:
    return vprint_string(format_str, args)


fn print_to_stream(os_stream: UnsafePointer[AnyType], format_str: StringRef, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: VariadicPack[AnyType]) -> None:
    if format_syntax.value == FormatSyntax.FORTRAN.value:
        print_fortran_syntax(os_stream, format_str, args)
    elif format_syntax.value == FormatSyntax.FMT.value:
        vprint_stream(os_stream, format_str, args)


fn print_to_file(output_file: InputOutputFile, format_str: StringRef, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: VariadicPack[AnyType]) -> None:
    pass


fn format_string(format_str: StringRef, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: VariadicPack[AnyType]) -> String:
    if format_syntax.value == FormatSyntax.FORTRAN.value:
        return format_fortran_syntax(format_str, args)
    elif format_syntax.value == FormatSyntax.FMT.value:
        return vprint_string(format_str, args)
    return String(format_str)
