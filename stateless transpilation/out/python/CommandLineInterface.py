from enum import IntEnum
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional, List, Protocol, Any
import subprocess
import os
import sys
from io import StringIO

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (from EnergyPlus/Data/EnergyPlusData)
# - InputFile: file wrapper with good(), rewind(), readLine() (from EnergyPlus)
# - FileSystem: utilities - fileExists, getFileName, getParentDirectoryPath, 
#   getAbsolutePath, getFileType, makeNativePath, appendSuffixToPath,
#   getParentDirectoryPath, makeDirectory, systemCall, linkFile, removeFile, moveFile,
#   getParentDirectoryPath, toString, exeExtension (from EnergyPlus)
# - DataStringGlobals: constants/utilities - VerString, BuildPlatformString, pathChar
#   (from EnergyPlus)
# - DisplayString: display message to user (from EnergyPlus)
# - ShowFatalError: fatal error handler (from EnergyPlus)
# - PluginManagement.pythonStringForUsage: get Python version info (from EnergyPlus)
# - EnergyPlus module with version info (from EnergyPlus)
# - ConvertCaseToLower: string utility (from EnergyPlus)
# - strip, stripped, index, has, len: string utilities (from EnergyPlus)

class ReturnCodes(IntEnum):
    INVALID = -1
    SUCCESS = 0
    FAILURE = 1
    SUCCESS_BUT_HELPER = 2
    NUM = 3


class InputFileProtocol(Protocol):
    """Protocol for InputFile interface"""
    filePath: Path
    
    def good(self) -> bool:
        ...
    
    def rewind(self) -> None:
        ...
    
    def readLine(self) -> 'ReadResult':
        ...


class ReadResult:
    """Result from reading a line"""
    def __init__(self, data: str = "", eof: bool = False):
        self.data = data
        self.eof = eof


class FileSystemProtocol(Protocol):
    """Protocol for FileSystem utilities"""
    exeExtension: str
    
    @staticmethod
    def fileExists(path: Path) -> bool:
        ...
    
    @staticmethod
    def getFileName(path: Path) -> Path:
        ...
    
    @staticmethod
    def getParentDirectoryPath(path: Path) -> Path:
        ...
    
    @staticmethod
    def getAbsolutePath(path: Path) -> Path:
        ...
    
    @staticmethod
    def makeNativePath(path: Path) -> Path:
        ...
    
    @staticmethod
    def appendSuffixToPath(path: Path, suffix: str) -> Path:
        ...
    
    @staticmethod
    def makeDirectory(path: Path) -> None:
        ...
    
    @staticmethod
    def systemCall(command: str) -> int:
        ...
    
    @staticmethod
    def linkFile(src: Path, dst: Path) -> None:
        ...
    
    @staticmethod
    def removeFile(path: Path) -> None:
        ...
    
    @staticmethod
    def moveFile(src: Path, dst: Path) -> None:
        ...
    
    @staticmethod
    def toString(path: Path) -> str:
        ...
    
    @staticmethod
    def getFileType(path: Path) -> 'FileType':
        ...
    
    @staticmethod
    def is_all_json_type(ft: 'FileType') -> bool:
        ...
    
    @staticmethod
    def getProgramPath() -> Path:
        ...


class FileType(IntEnum):
    IDF = 0
    IMF = 1
    EpJSON = 2
    JSON = 3
    CBOR = 4
    MsgPack = 5
    UBJSON = 6
    BSON = 7


def process_args(state: Any, args: List[str]) -> int:
    """Process command line arguments for EnergyPlus"""
    
    dash = "-"
    arguments = []
    
    for input_arg in args:
        double_dash_pos = input_arg.find("--")
        equals_pos = input_arg.find("=")
        
        if double_dash_pos == 0 and equals_pos != -1:
            arguments.append(input_arg[:equals_pos])
            arguments.append(input_arg[equals_pos + 1:])
        elif double_dash_pos == 0 and len(input_arg) == 2:
            pass
        elif len(input_arg) > 2 and input_arg[0] == '-' and input_arg[1] != '-':
            for c in range(1, len(input_arg)):
                arguments.append(dash + input_arg[c])
        else:
            arguments.append(input_arg)
    
    program_name = arguments.pop(0) if arguments else "energyplus"
    arg_count = len(arguments)
    legacy_mode = (arg_count == 0)
    
    if not state.dataGlobal.installRootOverride:
        state.dataStrGlobals.exeDirectoryPath = FileSystem.getParentDirectoryPath(
            FileSystem.getAbsolutePath(FileSystem.getProgramPath())
        )
    
    debug_cli = any(arg == "--debug-cli" for arg in args)
    
    state.dataStrGlobals.inputFilePath = "in.idf"
    state.dataStrGlobals.outDirPath = Path(".")
    state.files.inputWeatherFilePath.filePath = "in.epw"
    
    if legacy_mode:
        state.dataStrGlobals.inputIddFilePath = "Energy+.idd"
    else:
        state.dataStrGlobals.inputIddFilePath = state.dataStrGlobals.exeDirectoryPath / "Energy+.idd"
    
    annual_simulation = False
    dd_only_simulation = False
    run_epmacro = False
    prefix_out_name = "eplus"
    suffix_type = "L"
    run_expand_objects = False
    
    i = 0
    while i < len(arguments):
        arg = arguments[i]
        
        if arg in ["-a", "--annual"]:
            annual_simulation = True
            state.dataGlobal.AnnualSimulation = True
        elif arg in ["-D", "--design-day"]:
            dd_only_simulation = True
            state.dataGlobal.DDOnlySimulation = True
        elif arg in ["-d", "--output-directory"]:
            if i + 1 < len(arguments):
                i += 1
                state.dataStrGlobals.outDirPath = Path(arguments[i])
        elif arg in ["-i", "--idd"]:
            if i + 1 < len(arguments):
                i += 1
                state.dataStrGlobals.inputIddFilePath = Path(arguments[i])
        elif arg in ["-m", "--epmacro"]:
            run_epmacro = True
        elif arg in ["-p", "--output-prefix"]:
            if i + 1 < len(arguments):
                i += 1
                prefix_out_name = arguments[i]
        elif arg in ["-r", "--readvars"]:
            state.dataGlobal.runReadVars = True
        elif arg in ["-c", "--convert"]:
            state.dataGlobal.outputEpJSONConversion = True
        elif arg in ["--convert-only"]:
            state.dataGlobal.outputEpJSONConversionOnly = True
        elif arg in ["-s", "--output-suffix"]:
            if i + 1 < len(arguments):
                i += 1
                suffix_type = arguments[i].upper()
        elif arg in ["-j", "--jobs"]:
            if i + 1 < len(arguments):
                i += 1
                try:
                    num_threads = int(arguments[i])
                    max_n = os.cpu_count() or 1
                    if num_threads <= 0:
                        num_threads = 1
                    elif num_threads > max_n:
                        num_threads = max_n
                    state.dataGlobal.numThread = num_threads
                except ValueError:
                    state.dataGlobal.numThread = 1
        elif arg in ["-w", "--weather"]:
            if i + 1 < len(arguments):
                i += 1
                state.files.inputWeatherFilePath.filePath = Path(arguments[i])
        elif arg in ["-x", "--expandobjects"]:
            run_expand_objects = True
        elif arg in ["-v", "--version"]:
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.SUCCESS_BUT_HELPER)
            sys.exit(0)
        elif arg in ["--debug-cli"]:
            pass
        elif not arg.startswith("-"):
            state.dataStrGlobals.inputFilePath = Path(arg)
        
        i += 1
    
    state.dataStrGlobals.inputFilePath = FileSystem.makeNativePath(state.dataStrGlobals.inputFilePath)
    state.files.inputWeatherFilePath.filePath = FileSystem.makeNativePath(state.files.inputWeatherFilePath.filePath)
    state.dataStrGlobals.inputIddFilePath = FileSystem.makeNativePath(state.dataStrGlobals.inputIddFilePath)
    state.dataStrGlobals.outDirPath = FileSystem.makeNativePath(state.dataStrGlobals.outDirPath)
    
    state.dataStrGlobals.inputFilePathNameOnly = FileSystem.getFileName(state.dataStrGlobals.inputFilePath)
    state.dataStrGlobals.inputDirPath = FileSystem.getParentDirectoryPath(state.dataStrGlobals.inputFilePath)
    
    file_type = FileSystem.getFileType(state.dataStrGlobals.inputFilePath)
    state.dataGlobal.isEpJSON = FileSystem.is_all_json_type(file_type)
    
    if file_type not in [FileType.IDF, FileType.IMF, FileType.EpJSON, FileType.JSON]:
        if file_type == FileType.CBOR:
            DisplayString(state, "CBOR input format is experimental and unsupported.")
        elif file_type == FileType.MsgPack:
            DisplayString(state, "MsgPack input format is experimental and unsupported.")
        elif file_type == FileType.UBJSON:
            DisplayString(state, "UBJSON input format is experimental and unsupported.")
        elif file_type == FileType.BSON:
            DisplayString(state, "BSON input format is experimental and unsupported.")
        else:
            DisplayString(state, f"ERROR: Input file must have IDF, IMF, or epJSON extension: {state.dataStrGlobals.inputFilePath}")
        
        if state.dataGlobal.eplusRunningViaAPI:
            return int(ReturnCodes.FAILURE)
        sys.exit(1)
    
    if state.dataStrGlobals.outDirPath:
        FileSystem.makeDirectory(state.dataStrGlobals.outDirPath)
    
    output_file_prefix_full_path = state.dataStrGlobals.outDirPath / prefix_out_name
    
    normal_suffix = ""
    table_suffix = ""
    map_suffix = ""
    zsz_suffix = ""
    spsz_suffix = ""
    ssz_suffix = ""
    psz_suffix = ""
    meter_suffix = ""
    sqlite_suffix = ""
    ads_suffix = ""
    screen_suffix = ""
    shd_suffix = ""
    
    if suffix_type == "L":
        normal_suffix = "out"
        table_suffix = "tbl"
        map_suffix = "map"
        zsz_suffix = "zsz"
        spsz_suffix = "spsz"
        ssz_suffix = "ssz"
        psz_suffix = "psz"
        meter_suffix = "mtr"
        sqlite_suffix = "sqlite"
        ads_suffix = "ADS"
        screen_suffix = "screen"
        shd_suffix = "shading"
    elif suffix_type == "D":
        normal_suffix = ""
        table_suffix = "-table"
        map_suffix = "-map"
        zsz_suffix = "-zsz"
        spsz_suffix = "-spsz"
        ssz_suffix = "-ssz"
        psz_suffix = "-psz"
        meter_suffix = "-meter"
        sqlite_suffix = "-sqlite"
        ads_suffix = "-ads"
        screen_suffix = "-screen"
        shd_suffix = "-shading"
    elif suffix_type == "C":
        normal_suffix = ""
        table_suffix = "Table"
        map_suffix = "Map"
        zsz_suffix = "Zsz"
        spsz_suffix = "Spsz"
        ssz_suffix = "Ssz"
        psz_suffix = "Psz"
        meter_suffix = "Meter"
        sqlite_suffix = "Sqlite"
        ads_suffix = "Ads"
        screen_suffix = "Screen"
        shd_suffix = "Shading"
    
    def compose_path(suffix: str) -> Path:
        return FileSystem.appendSuffixToPath(output_file_prefix_full_path, suffix)
    
    state.files.audit.filePath = compose_path(normal_suffix + ".audit")
    state.files.bnd.filePath = compose_path(normal_suffix + ".bnd")
    state.files.dxf.filePath = compose_path(normal_suffix + ".dxf")
    state.files.eio.filePath = compose_path(normal_suffix + ".eio")
    state.files.endFile.filePath = compose_path(normal_suffix + ".end")
    state.files.outputErrFilePath = compose_path(normal_suffix + ".err")
    state.files.eso.filePath = compose_path(normal_suffix + ".eso")
    
    state.files.json.outputJsonFilePath = compose_path(normal_suffix + ".json")
    state.files.json.outputTSZoneJsonFilePath = compose_path(normal_suffix + "_detailed_zone.json")
    state.files.json.outputTSHvacJsonFilePath = compose_path(normal_suffix + "_detailed_HVAC.json")
    state.files.json.outputTSJsonFilePath = compose_path(normal_suffix + "_timestep.json")
    state.files.json.outputYRJsonFilePath = compose_path(normal_suffix + "_yearly.json")
    state.files.json.outputMNJsonFilePath = compose_path(normal_suffix + "_monthly.json")
    state.files.json.outputDYJsonFilePath = compose_path(normal_suffix + "_daily.json")
    state.files.json.outputHRJsonFilePath = compose_path(normal_suffix + "_hourly.json")
    state.files.json.outputSMJsonFilePath = compose_path(normal_suffix + "_runperiod.json")
    state.files.json.outputCborFilePath = compose_path(normal_suffix + ".cbor")
    state.files.json.outputTSZoneCborFilePath = compose_path(normal_suffix + "_detailed_zone.cbor")
    state.files.json.outputTSHvacCborFilePath = compose_path(normal_suffix + "_detailed_HVAC.cbor")
    state.files.json.outputTSCborFilePath = compose_path(normal_suffix + "_timestep.cbor")
    state.files.json.outputYRCborFilePath = compose_path(normal_suffix + "_yearly.cbor")
    state.files.json.outputMNCborFilePath = compose_path(normal_suffix + "_monthly.cbor")
    state.files.json.outputDYCborFilePath = compose_path(normal_suffix + "_daily.cbor")
    state.files.json.outputHRCborFilePath = compose_path(normal_suffix + "_hourly.cbor")
    state.files.json.outputSMCborFilePath = compose_path(normal_suffix + "_runperiod.cbor")
    state.files.json.outputMsgPackFilePath = compose_path(normal_suffix + ".msgpack")
    state.files.json.outputTSZoneMsgPackFilePath = compose_path(normal_suffix + "_detailed_zone.msgpack")
    state.files.json.outputTSHvacMsgPackFilePath = compose_path(normal_suffix + "_detailed_HVAC.msgpack")
    state.files.json.outputTSMsgPackFilePath = compose_path(normal_suffix + "_timestep.msgpack")
    state.files.json.outputYRMsgPackFilePath = compose_path(normal_suffix + "_yearly.msgpack")
    state.files.json.outputMNMsgPackFilePath = compose_path(normal_suffix + "_monthly.msgpack")
    state.files.json.outputDYMsgPackFilePath = compose_path(normal_suffix + "_daily.msgpack")
    state.files.json.outputHRMsgPackFilePath = compose_path(normal_suffix + "_hourly.msgpack")
    state.files.json.outputSMMsgPackFilePath = compose_path(normal_suffix + "_runperiod.msgpack")
    
    state.files.mtd.filePath = compose_path(normal_suffix + ".mtd")
    state.files.mdd.filePath = compose_path(normal_suffix + ".mdd")
    state.files.mtr.filePath = compose_path(normal_suffix + ".mtr")
    state.files.rdd.filePath = compose_path(normal_suffix + ".rdd")
    state.dataStrGlobals.outputShdFilePath = compose_path(normal_suffix + ".shd")
    state.files.dfs.filePath = compose_path(normal_suffix + ".dfs")
    state.dataStrGlobals.outputGLHEFilePath = compose_path(normal_suffix + ".glhe")
    state.files.edd.filePath = compose_path(normal_suffix + ".edd")
    state.dataStrGlobals.outputIperrFilePath = compose_path(normal_suffix + ".iperr")
    state.files.sln.filePath = compose_path(normal_suffix + ".sln")
    state.files.sci.filePath = compose_path(normal_suffix + ".sci")
    state.files.wrl.filePath = compose_path(normal_suffix + ".wrl")
    state.dataStrGlobals.outputSqlFilePath = compose_path(normal_suffix + ".sql")
    state.files.debug.filePath = compose_path(normal_suffix + ".dbg")
    state.dataStrGlobals.outputPerfLogFilePath = compose_path(normal_suffix + "_perflog.csv")
    state.dataStrGlobals.outputTblCsvFilePath = compose_path(table_suffix + ".csv")
    state.dataStrGlobals.outputTblHtmFilePath = compose_path(table_suffix + ".htm")
    state.dataStrGlobals.outputTblTabFilePath = compose_path(table_suffix + ".tab")
    state.dataStrGlobals.outputTblTxtFilePath = compose_path(table_suffix + ".txt")
    state.dataStrGlobals.outputTblXmlFilePath = compose_path(table_suffix + ".xml")
    state.files.outputMapTabFilePath = compose_path(map_suffix + ".tab")
    state.files.outputMapCsvFilePath = compose_path(map_suffix + ".csv")
    state.files.outputMapTxtFilePath = compose_path(map_suffix + ".txt")
    state.files.outputZszCsvFilePath = compose_path(zsz_suffix + ".csv")
    state.files.outputZszTabFilePath = compose_path(zsz_suffix + ".tab")
    state.files.outputZszTxtFilePath = compose_path(zsz_suffix + ".txt")
    state.files.outputSpszCsvFilePath = compose_path(spsz_suffix + ".csv")
    state.files.outputSpszTabFilePath = compose_path(spsz_suffix + ".tab")
    state.files.outputSpszTxtFilePath = compose_path(spsz_suffix + ".txt")
    state.files.outputSszCsvFilePath = compose_path(ssz_suffix + ".csv")
    state.files.outputSszTabFilePath = compose_path(ssz_suffix + ".tab")
    state.files.outputSszTxtFilePath = compose_path(ssz_suffix + ".txt")
    state.files.outputPszCsvFilePath = compose_path(psz_suffix + ".csv")
    state.files.outputPszTabFilePath = compose_path(psz_suffix + ".tab")
    state.files.outputPszTxtFilePath = compose_path(psz_suffix + ".txt")
    state.dataStrGlobals.outputAdsFilePath = compose_path(ads_suffix + ".out")
    state.files.shade.filePath = compose_path(shd_suffix + ".csv")
    
    if suffix_type == "L":
        state.dataStrGlobals.outputSqliteErrFilePath = state.dataStrGlobals.outDirPath / (sqlite_suffix + ".err")
    else:
        state.dataStrGlobals.outputSqliteErrFilePath = compose_path(sqlite_suffix + ".err")
    
    state.files.screenCsv.filePath = compose_path(screen_suffix + ".csv")
    state.files.delightIn.filePath = Path("eplusout.delightin")
    state.dataStrGlobals.outputDelightOutFilePath = Path("eplusout.delightout")
    state.files.iniFile.filePath = Path("Energy+.ini")
    
    state.files.inStatFilePath.filePath = state.files.inputWeatherFilePath.filePath
    if hasattr(state.files.inStatFilePath.filePath, 'with_suffix'):
        state.files.inStatFilePath.filePath = state.files.inStatFilePath.filePath.with_suffix(".stat")
    
    state.dataStrGlobals.eplusADSFilePath = state.dataStrGlobals.inputDirPath / "eplusADS.inp"
    
    state.files.csv.filePath = compose_path(normal_suffix + ".csv")
    state.files.mtr_csv.filePath = compose_path(meter_suffix + ".csv")
    state.dataStrGlobals.outputRvauditFilePath = compose_path(normal_suffix + ".rvaudit")
    
    output_epmdet_file_path = compose_path(normal_suffix + ".epmdet")
    output_epmidf_file_path = compose_path(normal_suffix + ".epmidf")
    output_expidf_file_path = compose_path(normal_suffix + ".expidf")
    output_experr_file_path = compose_path(normal_suffix + ".experr")
    
    if FileSystem.fileExists(state.files.iniFile.filePath):
        ini_file = state.files.iniFile.try_open()
        if not ini_file.good():
            DisplayString(state, f"ERROR: Could not open file {ini_file.filePath} for input (read).")
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.FAILURE)
            sys.exit(1)
        
        state.dataStrGlobals.CurrentWorkingFolder = ini_file.filePath
        program_path_str = ""
        read_ini_file(ini_file, "program", "dir", program_path_str)
        
        if program_path_str:
            state.dataStrGlobals.ProgramPath = Path(program_path_str)
            state.dataStrGlobals.inputIddFilePath = state.dataStrGlobals.ProgramPath / "Energy+.idd"
    
    if not FileSystem.fileExists(state.dataStrGlobals.inputFilePath):
        DisplayString(state, f"ERROR: Could not find input data file: {FileSystem.getAbsolutePath(state.dataStrGlobals.inputFilePath)}.")
        DisplayString(state, "Type 'energyplus --help' for usage.")
        if state.dataGlobal.eplusRunningViaAPI:
            return int(ReturnCodes.FAILURE)
        sys.exit(1)
    
    if not state.dataGlobal.DDOnlySimulation:
        if not FileSystem.fileExists(state.files.inputWeatherFilePath.filePath):
            DisplayString(state, f"ERROR: Could not find weather file: {FileSystem.getAbsolutePath(state.files.inputWeatherFilePath.filePath)}.")
            DisplayString(state, "Type 'energyplus --help' for usage.")
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.FAILURE)
            sys.exit(1)
    
    if run_epmacro:
        ep_macro_path = state.dataStrGlobals.exeDirectoryPath / ("EPMacro" + FileSystem.exeExtension)
        if not FileSystem.fileExists(ep_macro_path):
            DisplayString(state, f"ERROR: Could not find EPMacro executable: {FileSystem.getAbsolutePath(ep_macro_path)}.")
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.FAILURE)
            sys.exit(1)
        
        ep_macro_command = '"' + FileSystem.toString(ep_macro_path) + '"'
        input_file_is_in_imf = (FileSystem.getAbsolutePath(state.dataStrGlobals.inputFilePath) == FileSystem.getAbsolutePath(Path("in.imf")))
        
        if not input_file_is_in_imf:
            FileSystem.linkFile(state.dataStrGlobals.inputFilePath, Path("in.imf"))
        
        DisplayString(state, "Running EPMacro...")
        FileSystem.systemCall(ep_macro_command)
        
        if not input_file_is_in_imf:
            FileSystem.removeFile(Path("in.imf"))
        
        FileSystem.moveFile(Path("audit.out"), output_epmdet_file_path)
        FileSystem.moveFile(Path("out.idf"), output_epmidf_file_path)
        state.dataStrGlobals.inputFilePath = output_epmidf_file_path
    
    if run_expand_objects:
        expand_objects_path = state.dataStrGlobals.exeDirectoryPath / ("ExpandObjects" + FileSystem.exeExtension)
        if not FileSystem.fileExists(expand_objects_path):
            DisplayString(state, f"ERROR: Could not find ExpandObjects executable: {FileSystem.getAbsolutePath(expand_objects_path)}.")
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.FAILURE)
            sys.exit(1)
        
        if not FileSystem.fileExists(state.dataStrGlobals.inputIddFilePath):
            DisplayString(state, f"ERROR: Could not find input data dictionary: {FileSystem.getAbsolutePath(state.dataStrGlobals.inputIddFilePath)}.")
            DisplayString(state, "Type 'energyplus --help' for usage.")
            if state.dataGlobal.eplusRunningViaAPI:
                return int(ReturnCodes.FAILURE)
            sys.exit(1)
        
        expand_objects_command = '"' + FileSystem.toString(expand_objects_path) + '"'
        input_file_is_in_idf = (FileSystem.getAbsolutePath(state.dataStrGlobals.inputFilePath) == FileSystem.getAbsolutePath(Path("in.idf")))
        idd_file_is_energy = (FileSystem.getAbsolutePath(state.dataStrGlobals.inputIddFilePath) == FileSystem.getAbsolutePath(Path("Energy+.idd")))
        
        if not input_file_is_in_idf:
            FileSystem.linkFile(state.dataStrGlobals.inputFilePath, Path("in.idf"))
        if not idd_file_is_energy:
            FileSystem.linkFile(state.dataStrGlobals.inputIddFilePath, Path("Energy+.idd"))
        
        FileSystem.systemCall(expand_objects_command)
        
        if not input_file_is_in_idf:
            FileSystem.removeFile(Path("in.idf"))
        if not idd_file_is_energy:
            FileSystem.removeFile(Path("Energy+.idd"))
        
        FileSystem.moveFile(Path("expandedidf.err"), output_experr_file_path)
        if FileSystem.fileExists(Path("expanded.idf")):
            FileSystem.moveFile(Path("expanded.idf"), output_expidf_file_path)
            state.dataStrGlobals.inputFilePath = output_expidf_file_path
    
    return int(ReturnCodes.SUCCESS)


def read_ini_file(input_file: InputFileProtocol, heading: str, kind_of_parameter: str, data_out: Any) -> None:
    """Read INI file and retrieve parameter values"""
    
    param = kind_of_parameter.strip()
    input_file.rewind()
    found = False
    new_heading = False
    
    while input_file.good() and not found:
        read_result = input_file.readLine()
        
        if read_result.eof:
            break
        
        if not read_result.data:
            continue
        
        line_out = read_result.data.lower()
        
        if heading not in line_out:
            continue
        
        ilb = line_out.find('[')
        irb = line_out.find(']')
        
        if ilb == -1 and irb == -1:
            continue
        
        if '[' + heading + ']' not in line_out:
            continue
        
        while input_file.good() and not new_heading:
            inner_read_result = input_file.readLine()
            if inner_read_result.eof:
                break
            
            line = inner_read_result.data.strip()
            
            if not line:
                continue
            
            line_out = line.lower()
            
            ilb = line_out.find('[')
            irb = line_out.find(']')
            new_heading = (ilb != -1 and irb != -1)
            
            ieq = line_out.find('=')
            ipar = line_out.find(param)
            
            if ieq == -1:
                continue
            if ipar == -1:
                continue
            if ipar != 0:
                continue
            if param + '=' not in line_out:
                continue
            if ipar > ieq:
                continue
            
            data_out = line[ieq + 1:].strip()
            found = True
            break
    
    if param == "dir":
        if data_out:
            if data_out[-1] != '/':
                data_out += '/'


def run_read_vars_eso(state: Any) -> int:
    """Run ReadVarsESO tool"""
    
    read_vars_path = state.dataStrGlobals.exeDirectoryPath / ("ReadVarsESO" + FileSystem.exeExtension)
    
    if not FileSystem.fileExists(read_vars_path):
        read_vars_path = state.dataStrGlobals.exeDirectoryPath / "PostProcess" / ("ReadVarsESO" + FileSystem.exeExtension)
        if not FileSystem.fileExists(read_vars_path):
            if state.dataGlobal.eplusRunningViaAPI:
                DisplayString(state, "ERROR: Could not find ReadVarsESO executable.  When calling through C API, make sure to call setEnergyPlusRootDirectory")
            else:
                DisplayString(state, f"ERROR: Could not find ReadVarsESO executable: {FileSystem.getAbsolutePath(read_vars_path)}.")
            return int(ReturnCodes.FAILURE)
    
    rvi_file = (state.dataStrGlobals.inputDirPath / state.dataStrGlobals.inputFilePathNameOnly).with_suffix(".rvi")
    mvi_file = (state.dataStrGlobals.inputDirPath / state.dataStrGlobals.inputFilePathNameOnly).with_suffix(".mvi")
    
    rvi_file_exists = FileSystem.fileExists(rvi_file)
    if not rvi_file_exists:
        with open(rvi_file, 'w') as ofs:
            ofs.write(FileSystem.toString(state.files.eso.filePath) + '\n')
            ofs.write(FileSystem.toString(state.files.csv.filePath) + '\n')
    
    mvi_file_exists = FileSystem.fileExists(mvi_file)
    if not mvi_file_exists:
        with open(mvi_file, 'w') as ofs:
            ofs.write(FileSystem.toString(state.files.mtr.filePath) + '\n')
            ofs.write(FileSystem.toString(state.files.mtr_csv.filePath) + '\n')
    
    read_vars_rvi_command = '"' + FileSystem.toString(read_vars_path) + '" "' + FileSystem.toString(rvi_file) + '" unlimited'
    read_vars_mvi_command = '"' + FileSystem.toString(read_vars_path) + '" "' + FileSystem.toString(mvi_file) + '" unlimited'
    
    FileSystem.systemCall(read_vars_rvi_command)
    FileSystem.systemCall(read_vars_mvi_command)
    
    if not rvi_file_exists:
        FileSystem.removeFile(rvi_file)
    
    if not mvi_file_exists:
        FileSystem.removeFile(mvi_file)
    
    FileSystem.moveFile(Path("readvars.audit"), state.dataStrGlobals.outputRvauditFilePath)
    return int(ReturnCodes.SUCCESS)
