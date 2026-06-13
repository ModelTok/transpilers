from __future__ import annotations
from enum import Enum, IntEnum
from dataclasses import dataclass, field
from pathlib import Path
from typing import TypeVar, Generic, Optional, Any, Protocol, List, Dict
import io
import json as json_module
import math
from datetime import datetime

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from Data.EnergyPlusData module
# - FileSystem: module with removeFile, getFileType, FileTypes enum
# - InputProcessor: state.dataInputProcessing.inputProcessor
# - ResultsFramework: state.dataResultsFramework.resultsFramework
# - UtilityRoutines: ShowFatalError, Util.makeUPPER
# - nlohmann.json: json module (standard library)


class FormatSyntax(IntEnum):
    INVALID = -1
    FORTRAN = 0
    FMT = 1
    PRINTF = 2
    NUM = 3


def is_fortran_syntax(format_str: str) -> bool:
    within_fmt_str = False
    for c in format_str:
        if c == '{':
            within_fmt_str = True
        elif c == '}':
            within_fmt_str = False
        elif c == 'R':
            if within_fmt_str:
                return True
    return False


def check_syntax(format_str: str) -> FormatSyntax:
    if is_fortran_syntax(format_str):
        return FormatSyntax.FORTRAN
    return FormatSyntax.FMT


@dataclass
class DoubleWrapper:
    value: float

    def __init__(self, val: float):
        self.value = val

    def __float__(self) -> float:
        return self.value

    def __format__(self, format_spec: str) -> str:
        return format_double_wrapper(self.value, format_spec)


def should_be_fixed_output(value: float) -> bool:
    return (value >= 0.099999999999999995 or value <= -0.099999999999999995) or (value == 0.0) or (value == -0.0)


def fixed_will_fit(value: float, places: int) -> bool:
    if -1.0 < value < 1.0:
        return True
    return int(math.log10(abs(value))) < places


def zero_pad_exponent(s: str) -> str:
    if len(s) > 3:
        if s[-3].isdigit() == False:
            s = s[:-2] + '0' + s[-2:]
    return s


def format_double_wrapper(value: float, format_spec: str) -> str:
    if 'R' in format_spec or not format_spec:
        fixed_output = should_be_fixed_output(value)
        if fixed_output:
            if value > 100000.0:
                digits10 = int(math.log10(value))
                if digits10 >= 15:
                    return f"{int(value)}."
                return format(value, 'f')
            if value == 0.0 or value == -0.0:
                return "0.0"
            nudged = value
            for _ in range(3):
                nudged = math.nextafter(nudged, math.inf) if nudged >= 0 else math.nextafter(nudged, -math.inf)
            return format(nudged, 'f')
        else:
            formatted = format(value, 'e')
            return zero_pad_exponent(formatted)
    return format(value, format_spec)


T = TypeVar('T')


@dataclass
class ReadResult(Generic[T]):
    data: T
    eof: bool
    good: bool

    def update(self, other: ReadResult[T]) -> None:
        self.eof = other.eof
        self.good = other.good
        if self.good:
            self.data = other.data


class InputFile:
    def __init__(self, file_path: Path | str):
        self.filePath = Path(file_path) if isinstance(file_path, str) else file_path
        self.file_size: int = 0
        self.is_stream: Optional[io.IOBase] = None

    def close(self) -> None:
        if self.is_stream:
            self.is_stream.close()
        self.is_stream = None

    def good(self) -> bool:
        if self.is_stream is None:
            return False
        try:
            return not self.is_stream.closed
        except:
            return False

    def is_open(self) -> bool:
        if self.is_stream is None:
            return False
        try:
            return not self.is_stream.closed
        except:
            return False

    def backspace(self) -> None:
        if self.is_stream:
            try:
                current_pos = self.is_stream.tell()
                self.is_stream.seek(0)
                start_pos = self.is_stream.tell()
                self.is_stream.seek(current_pos)
                if current_pos > start_pos:
                    current_pos -= 1
                while current_pos > start_pos:
                    current_pos -= 1
                    self.is_stream.seek(current_pos)
                    char = self.is_stream.read(1)
                    if char == '\n':
                        break
            except:
                pass

    def error_state_to_string(self) -> str:
        if not self.is_open():
            return "file not opened"
        if self.is_stream.closed:
            return "irrecoverable stream error"
        return "no error"

    def rdstate(self) -> str:
        if self.is_stream is None:
            return "badbit"
        if self.is_stream.closed:
            return "badbit"
        return "goodbit"

    def ensure_open(self, state: Any, caller: str, output_to_file: bool = True) -> InputFile:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"{caller}: Could not open file {self.filePath} for input (read).")
        return self

    def open(self, *args, **kwargs) -> None:
        try:
            self.file_size = self.filePath.stat().st_size
            self.is_stream = open(self.filePath, 'rb')
        except:
            self.is_stream = None

    def position(self) -> int:
        if self.is_stream:
            return self.is_stream.tell()
        return 0

    def rewind(self) -> None:
        if self.is_stream:
            self.is_stream.seek(0)

    def readLine(self) -> ReadResult[str]:
        if not self.is_stream:
            return ReadResult("", True, False)
        try:
            line = self.is_stream.readline().decode('utf-8', errors='ignore')
            if line.endswith('\r\n'):
                line = line[:-2]
            elif line.endswith('\r'):
                line = line[:-1]
            eof = self.is_stream.tell() >= self.file_size
            return ReadResult(line, eof, True)
        except:
            return ReadResult("", True, False)

    def read(self, typ: type = str) -> ReadResult[Any]:
        if not self.is_stream:
            return ReadResult(None, True, False)
        try:
            if typ == str:
                data = self.is_stream.read().decode('utf-8', errors='ignore')
            else:
                data = typ()
            return ReadResult(data, False, True)
        except:
            return ReadResult(None, True, False)

    def readFile(self) -> str:
        if self.is_stream:
            return self.is_stream.read().decode('utf-8', errors='ignore')
        return ""

    def readJSON(self) -> Dict[str, Any]:
        if self.is_stream:
            content = self.is_stream.read().decode('utf-8', errors='ignore')
            return json_module.loads(content)
        return {}


class InputOutputFile:
    def __init__(self, file_path: Path | str, default_to_stdout: bool = False):
        self.filePath = Path(file_path) if isinstance(file_path, str) else file_path
        self.defaultToStdOut = default_to_stdout
        self.os_stream: Optional[io.IOBase] = None
        self.print_to_dev_null = False

    def close(self) -> None:
        if self.os_stream:
            self.os_stream.close()
        self.os_stream = None

    def del_file(self) -> None:
        if self.os_stream:
            self.os_stream.close()
            self.os_stream = None
        try:
            from FileSystem import removeFile
            removeFile(self.filePath)
        except:
            self.filePath.unlink(missing_ok=True)

    def good(self) -> bool:
        if self.os_stream and self.print_to_dev_null:
            return True
        if self.os_stream:
            try:
                return not self.os_stream.closed
            except:
                return False
        return False

    def ensure_open(self, state: Any, caller: str, output_to_file: bool = True) -> InputOutputFile:
        if not self.good():
            self.open(False, output_to_file)
        if not self.good():
            from UtilityRoutines import ShowFatalError
            ShowFatalError(state, f"{caller}: Could not open file {self.filePath} for output (write).")
        return self

    def open(self, for_append: bool = False, output_to_file: bool = True) -> None:
        if not output_to_file:
            self.os_stream = io.StringIO()
            self.print_to_dev_null = True
        else:
            mode = 'a' if for_append else 'w'
            try:
                self.os_stream = open(self.filePath, mode)
                self.print_to_dev_null = False
            except:
                self.os_stream = None

    def open_as_stringstream(self) -> None:
        self.os_stream = io.StringIO()

    def flush(self) -> None:
        if self.os_stream:
            self.os_stream.flush()

    def get_output(self) -> str:
        if isinstance(self.os_stream, io.StringIO):
            return self.os_stream.getvalue()
        return ""

    def position(self) -> int:
        if self.os_stream:
            return self.os_stream.tell()
        return 0

    def getLines(self) -> List[str]:
        if self.os_stream:
            try:
                self.os_stream.flush()
                last_pos = self.os_stream.tell()
                self.os_stream.seek(0)
                lines = self.os_stream.readlines()
                self.os_stream.seek(last_pos)
                return [line.rstrip('\n\r') for line in lines]
            except:
                return []
        return []


@dataclass
class IOFilePath(Generic[T]):
    filePath: Path

    def open(self, state: Any, caller: str, output_to_file: bool = True) -> T:
        file_obj = self.filePath
        file_obj.ensure_open(state, caller, output_to_file)
        return file_obj

    def try_open(self, output_to_file: bool = True) -> T:
        file_obj = self.filePath
        file_obj.open(False, output_to_file)
        return file_obj


@dataclass
class JsonOutputFilePaths:
    outputJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSHvacJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSZoneJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputYRJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputMNJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputDYJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputHRJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputSMJsonFilePath: Path = field(default_factory=lambda: Path(""))
    outputCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSHvacCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSZoneCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputYRCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputMNCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputDYCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputHRCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputSMCborFilePath: Path = field(default_factory=lambda: Path(""))
    outputMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSHvacMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSZoneMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputTSMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputYRMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputMNMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputDYMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputHRMsgPackFilePath: Path = field(default_factory=lambda: Path(""))
    outputSMMsgPackFilePath: Path = field(default_factory=lambda: Path(""))


class OutputControl:
    def __init__(self):
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

    def write_tabular(self, state: Any) -> bool:
        html_tabular = self.tabular
        json_tabular = self.json and state.dataResultsFramework.resultsFramework.timeSeriesAndTabularEnabled()
        sqlite_tabular = self.sqlite
        return html_tabular or json_tabular or sqlite_tabular

    def getInput(self, state: Any) -> None:
        ip = state.dataInputProcessing.inputProcessor
        instances = ip.epJSON.get("OutputControl:Files")
        
        if instances:
            def find_input(fields: Dict, field_name: str) -> str:
                if field_name in fields:
                    return str(fields[field_name]).upper()
                return ip.getDefaultValue(state, "OutputControl:Files", field_name)

            def boolean_choice(input_str: str) -> bool:
                if input_str == "YES":
                    return True
                if input_str == "NO":
                    return False
                from UtilityRoutines import ShowFatalError
                ShowFatalError(state, "Invalid boolean Yes/No choice input")
                return True

            for key, fields in instances.items():
                ip.markObjectAsUsed("OutputControl:Files", key)
                self.csv = boolean_choice(find_input(fields, "output_csv"))
                self.mtr = boolean_choice(find_input(fields, "output_mtr"))
                self.eso = boolean_choice(find_input(fields, "output_eso"))
                self.eio = boolean_choice(find_input(fields, "output_eio"))
                self.audit = boolean_choice(find_input(fields, "output_audit"))
                self.spsz = boolean_choice(find_input(fields, "output_space_sizing"))
                self.zsz = boolean_choice(find_input(fields, "output_zone_sizing"))
                self.ssz = boolean_choice(find_input(fields, "output_system_sizing"))
                self.dxf = boolean_choice(find_input(fields, "output_dxf"))
                self.bnd = boolean_choice(find_input(fields, "output_bnd"))
                self.rdd = boolean_choice(find_input(fields, "output_rdd"))
                self.mdd = boolean_choice(find_input(fields, "output_mdd"))
                self.mtd = boolean_choice(find_input(fields, "output_mtd"))
                self.end = boolean_choice(find_input(fields, "output_end"))
                self.shd = boolean_choice(find_input(fields, "output_shd"))
                self.dfs = boolean_choice(find_input(fields, "output_dfs"))
                self.delightin = boolean_choice(find_input(fields, "output_delightin"))
                self.delighteldmp = boolean_choice(find_input(fields, "output_delighteldmp"))
                self.delightdfdmp = boolean_choice(find_input(fields, "output_delightdfdmp"))
                self.edd = boolean_choice(find_input(fields, "output_edd"))
                self.dbg = boolean_choice(find_input(fields, "output_dbg"))
                self.perflog = boolean_choice(find_input(fields, "output_perflog"))
                self.sln = boolean_choice(find_input(fields, "output_sln"))
                self.sci = boolean_choice(find_input(fields, "output_sci"))
                self.wrl = boolean_choice(find_input(fields, "output_wrl"))
                self.screen = boolean_choice(find_input(fields, "output_screen"))
                self.tarcog = boolean_choice(find_input(fields, "output_tarcog"))
                self.extshd = boolean_choice(find_input(fields, "output_extshd"))
                self.json = boolean_choice(find_input(fields, "output_json"))
                self.tabular = boolean_choice(find_input(fields, "output_tabular"))
                self.sqlite = boolean_choice(find_input(fields, "output_sqlite"))
                self.psz = boolean_choice(find_input(fields, "output_plant_component_sizing"))

        timestamp_instances = ip.epJSON.get("OutputControl:Timestamp")
        if timestamp_instances:
            for key, fields in timestamp_instances.items():
                ip.markObjectAsUsed("OutputControl:Timestamp", key)
                if "iso_8601_format" in fields:
                    state.dataResultsFramework.resultsFramework.setISO8601(fields["iso_8601_format"] == "Yes")
                if "timestamp_at_beginning_of_interval" in fields:
                    state.dataResultsFramework.resultsFramework.setBeginningOfInterval(
                        fields["timestamp_at_beginning_of_interval"] == "Yes"
                    )


class IOFiles:
    def __init__(self):
        self.outputControl = OutputControl()
        self.audit = InputOutputFile("eplusout.audit")
        self.eio = InputOutputFile("eplusout.eio")
        self.eso = InputOutputFile("eplusout.eso")
        self.zsz = InputOutputFile("")
        self.outputZszCsvFilePath = Path("epluszsz.csv")
        self.outputZszTabFilePath = Path("epluszsz.tab")
        self.outputZszTxtFilePath = Path("epluszsz.txt")
        self.spsz = InputOutputFile("")
        self.outputSpszCsvFilePath = Path("eplusspsz.csv")
        self.outputSpszTabFilePath = Path("eplusspsz.tab")
        self.outputSpszTxtFilePath = Path("eplusspsz.txt")
        self.ssz = InputOutputFile("")
        self.outputSszCsvFilePath = Path("eplusssz.csv")
        self.outputSszTabFilePath = Path("eplusssz.tab")
        self.outputSszTxtFilePath = Path("eplusssz.txt")
        self.psz = InputOutputFile("")
        self.outputPszCsvFilePath = Path("epluspsz.csv")
        self.outputPszTabFilePath = Path("epluspsz.tab")
        self.outputPszTxtFilePath = Path("epluspsz.txt")
        self.map = InputOutputFile("")
        self.outputMapCsvFilePath = Path("eplusmap.csv")
        self.outputMapTabFilePath = Path("eplusmap.tab")
        self.outputMapTxtFilePath = Path("eplusmap.txt")
        self.mtr = InputOutputFile("eplusout.mtr")
        self.bnd = InputOutputFile("eplusout.bnd")
        self.rdd = InputOutputFile("eplusout.rdd")
        self.mdd = InputOutputFile("eplusout.mdd")
        self.debug = InputOutputFile("eplusout.dbg")
        self.dfs = InputOutputFile("eplusout.dfs")
        self.sln = IOFilePath(Path("eplusout.sln"))
        self.dxf = IOFilePath(Path("eplusout.dxf"))
        self.sci = IOFilePath(Path("eplusout.sci"))
        self.wrl = IOFilePath(Path("eplusout.wrl"))
        self.delightIn = IOFilePath(Path("eplusout.delightin"))
        self.mtd = InputOutputFile("eplusout.mtd")
        self.edd = InputOutputFile("eplusout.edd", True)
        self.shade = InputOutputFile("eplusshading.csv")
        self.csv = InputOutputFile("eplusout.csv")
        self.mtr_csv = InputOutputFile("eplusmtr.csv")
        self.screenCsv = IOFilePath(Path("eplusscreen.csv"))
        self.endFile = IOFilePath(Path("eplusout.end"))
        self.iniFile = InputFile("EnergyPlus.ini")
        self.outputDelightEldmpFilePath = InputFile("eplusout.delighteldmp")
        self.outputDelightDfdmpFilePath = InputFile("eplusout.delightdfdmp")
        self.inputWeatherFilePath = InputFile("")
        self.inputWeatherFile = InputFile("")
        self.TempFullFilePath = InputFile("")
        self.inStatFilePath = InputFile("")
        self.outputErrFilePath = Path("eplusout.err")
        self.err_stream: Optional[io.IOBase] = None
        self.json = JsonOutputFilePaths()

    def flushAll(self) -> None:
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


class SharedFileHandle:
    def __init__(self):
        self.file: Optional[InputOutputFile] = None

    def ptr(self) -> InputOutputFile:
        if not self.file:
            self.file = InputOutputFile("")
        return self.file

    def __getattr__(self, name: str) -> Any:
        return getattr(self.ptr(), name)

    def __setattr__(self, name: str, value: Any) -> None:
        if name == 'file':
            super().__setattr__(name, value)
        else:
            setattr(self.ptr(), name, value)


def vprint_stream(os_stream: io.IOBase, format_str: str, *args: Any) -> None:
    try:
        output = format_str.format(*args)
    except (IndexError, KeyError, ValueError):
        from UtilityRoutines import FatalError
        raise FatalError(f"Error with format, '{format_str}', passed {len(args)} args")
    os_stream.write(output)


def vprint_string(format_str: str, *args: Any) -> str:
    try:
        return format_str.format(*args)
    except (IndexError, KeyError, ValueError):
        from UtilityRoutines import FatalError
        raise FatalError(f"Error with format, '{format_str}', passed {len(args)} args")


def print_fortran_syntax(os_stream: io.IOBase, format_str: str, *args: Any) -> None:
    wrapped_args = []
    for arg in args:
        if isinstance(arg, float):
            wrapped_args.append(DoubleWrapper(arg))
        else:
            wrapped_args.append(arg)
    vprint_stream(os_stream, format_str, *wrapped_args)


def format_fortran_syntax(format_str: str, *args: Any) -> str:
    wrapped_args = []
    for arg in args:
        if isinstance(arg, float):
            wrapped_args.append(DoubleWrapper(arg))
        else:
            wrapped_args.append(arg)
    return vprint_string(format_str, *wrapped_args)


def print_to_stream(os_stream: io.IOBase, format_str: str, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: Any) -> None:
    if format_syntax == FormatSyntax.FORTRAN:
        print_fortran_syntax(os_stream, format_str, *args)
    elif format_syntax == FormatSyntax.FMT:
        try:
            output = format_str.format(*args)
            os_stream.write(output)
        except:
            vprint_stream(os_stream, format_str, *args)
    else:
        raise ValueError("Invalid FormatSyntax selection")


def print_to_file(output_file: InputOutputFile, format_str: str, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: Any) -> None:
    if output_file.os_stream:
        output_stream = output_file.os_stream
    elif output_file.defaultToStdOut:
        import sys
        output_stream = sys.stdout
    else:
        raise ValueError("No valid output stream")
    
    print_to_stream(output_stream, format_str, format_syntax, *args)


def format_string(format_str: str, format_syntax: FormatSyntax = FormatSyntax.FORTRAN, *args: Any) -> str:
    if format_syntax == FormatSyntax.FORTRAN:
        return format_fortran_syntax(format_str, *args)
    elif format_syntax == FormatSyntax.FMT:
        return vprint_string(format_str, *args)
    elif format_syntax == FormatSyntax.PRINTF:
        return format_str % args
    else:
        raise ValueError("Invalid FormatSyntax selection")
