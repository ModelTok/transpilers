from collections import InlineArray
from pathlib import Path

alias RETURN_CODE_INVALID = -1
alias RETURN_CODE_SUCCESS = 0
alias RETURN_CODE_FAILURE = 1
alias RETURN_CODE_SUCCESS_BUT_HELPER = 2
alias RETURN_CODE_NUM = 3

struct FileType:
    alias IDF = 0
    alias IMF = 1
    alias EpJSON = 2
    alias JSON = 3
    alias CBOR = 4
    alias MsgPack = 5
    alias UBJSON = 6
    alias BSON = 7

struct ReadResult:
    var data: String
    var eof: Bool
    
    fn __init__(inout self, data: String = "", eof: Bool = False):
        self.data = data
        self.eof = eof

struct FilePath:
    var path: String
    
    fn __init__(inout self, path: String = ""):
        self.path = path

struct InputFileData:
    var filePath: String
    
    fn __init__(inout self, filePath: String = ""):
        self.filePath = filePath

struct JsonOutputFiles:
    var outputJsonFilePath: String
    var outputTSZoneJsonFilePath: String
    var outputTSHvacJsonFilePath: String
    var outputTSJsonFilePath: String
    var outputYRJsonFilePath: String
    var outputMNJsonFilePath: String
    var outputDYJsonFilePath: String
    var outputHRJsonFilePath: String
    var outputSMJsonFilePath: String
    var outputCborFilePath: String
    var outputTSZoneCborFilePath: String
    var outputTSHvacCborFilePath: String
    var outputTSCborFilePath: String
    var outputYRCborFilePath: String
    var outputMNCborFilePath: String
    var outputDYCborFilePath: String
    var outputHRCborFilePath: String
    var outputSMCborFilePath: String
    var outputMsgPackFilePath: String
    var outputTSZoneMsgPackFilePath: String
    var outputTSHvacMsgPackFilePath: String
    var outputTSMsgPackFilePath: String
    var outputYRMsgPackFilePath: String
    var outputMNMsgPackFilePath: String
    var outputDYMsgPackFilePath: String
    var outputHRMsgPackFilePath: String
    var outputSMMsgPackFilePath: String
    
    fn __init__(inout self):
        self.outputJsonFilePath = ""
        self.outputTSZoneJsonFilePath = ""
        self.outputTSHvacJsonFilePath = ""
        self.outputTSJsonFilePath = ""
        self.outputYRJsonFilePath = ""
        self.outputMNJsonFilePath = ""
        self.outputDYJsonFilePath = ""
        self.outputHRJsonFilePath = ""
        self.outputSMJsonFilePath = ""
        self.outputCborFilePath = ""
        self.outputTSZoneCborFilePath = ""
        self.outputTSHvacCborFilePath = ""
        self.outputTSCborFilePath = ""
        self.outputYRCborFilePath = ""
        self.outputMNCborFilePath = ""
        self.outputDYCborFilePath = ""
        self.outputHRCborFilePath = ""
        self.outputSMCborFilePath = ""
        self.outputMsgPackFilePath = ""
        self.outputTSZoneMsgPackFilePath = ""
        self.outputTSHvacMsgPackFilePath = ""
        self.outputTSMsgPackFilePath = ""
        self.outputYRMsgPackFilePath = ""
        self.outputMNMsgPackFilePath = ""
        self.outputDYMsgPackFilePath = ""
        self.outputHRMsgPackFilePath = ""
        self.outputSMMsgPackFilePath = ""

struct DataGlobal:
    var AnnualSimulation: Bool
    var DDOnlySimulation: Bool
    var runReadVars: Bool
    var outputEpJSONConversion: Bool
    var outputEpJSONConversionOnly: Bool
    var numThread: Int32
    var isEpJSON: Bool
    var eplusRunningViaAPI: Bool
    var installRootOverride: Bool
    
    fn __init__(inout self):
        self.AnnualSimulation = False
        self.DDOnlySimulation = False
        self.runReadVars = False
        self.outputEpJSONConversion = False
        self.outputEpJSONConversionOnly = False
        self.numThread = 1
        self.isEpJSON = False
        self.eplusRunningViaAPI = False
        self.installRootOverride = False

struct DataStringGlobals:
    var inputFilePath: String
    var inputFilePathNameOnly: String
    var inputDirPath: String
    var inputIddFilePath: String
    var outDirPath: String
    var exeDirectoryPath: String
    var CurrentWorkingFolder: String
    var ProgramPath: String
    var outputShdFilePath: String
    var outputGLHEFilePath: String
    var outputIperrFilePath: String
    var outputDelightOutFilePath: String
    var outputSqlFilePath: String
    var outputPerfLogFilePath: String
    var outputTblCsvFilePath: String
    var outputTblHtmFilePath: String
    var outputTblTabFilePath: String
    var outputTblTxtFilePath: String
    var outputTblXmlFilePath: String
    var outputAdsFilePath: String
    var outputRvauditFilePath: String
    var outputSqliteErrFilePath: String
    var eplusADSFilePath: String
    var VerStringVar: String
    
    fn __init__(inout self):
        self.inputFilePath = ""
        self.inputFilePathNameOnly = ""
        self.inputDirPath = ""
        self.inputIddFilePath = ""
        self.outDirPath = ""
        self.exeDirectoryPath = ""
        self.CurrentWorkingFolder = ""
        self.ProgramPath = ""
        self.outputShdFilePath = ""
        self.outputGLHEFilePath = ""
        self.outputIperrFilePath = ""
        self.outputDelightOutFilePath = ""
        self.outputSqlFilePath = ""
        self.outputPerfLogFilePath = ""
        self.outputTblCsvFilePath = ""
        self.outputTblHtmFilePath = ""
        self.outputTblTabFilePath = ""
        self.outputTblTxtFilePath = ""
        self.outputTblXmlFilePath = ""
        self.outputAdsFilePath = ""
        self.outputRvauditFilePath = ""
        self.outputSqliteErrFilePath = ""
        self.eplusADSFilePath = ""
        self.VerStringVar = ""

struct FileInfo:
    var audit: FilePath
    var bnd: FilePath
    var dxf: FilePath
    var eio: FilePath
    var endFile: FilePath
    var outputErrFilePath: String
    var eso: FilePath
    var json: JsonOutputFiles
    var mtd: FilePath
    var mdd: FilePath
    var mtr: FilePath
    var rdd: FilePath
    var dfs: FilePath
    var edd: FilePath
    var sln: FilePath
    var sci: FilePath
    var wrl: FilePath
    var debug: FilePath
    var screenCsv: FilePath
    var delightIn: FilePath
    var iniFile: FilePath
    var inStatFilePath: FilePath
    var csv: FilePath
    var mtr_csv: FilePath
    var inputWeatherFilePath: FilePath
    var outputMapTabFilePath: String
    var outputMapCsvFilePath: String
    var outputMapTxtFilePath: String
    var outputZszCsvFilePath: String
    var outputZszTabFilePath: String
    var outputZszTxtFilePath: String
    var outputSpszCsvFilePath: String
    var outputSpszTabFilePath: String
    var outputSpszTxtFilePath: String
    var outputSszCsvFilePath: String
    var outputSszTabFilePath: String
    var outputSszTxtFilePath: String
    var outputPszCsvFilePath: String
    var outputPszTabFilePath: String
    var outputPszTxtFilePath: String
    var shade: FilePath
    
    fn __init__(inout self):
        self.audit = FilePath()
        self.bnd = FilePath()
        self.dxf = FilePath()
        self.eio = FilePath()
        self.endFile = FilePath()
        self.outputErrFilePath = ""
        self.eso = FilePath()
        self.json = JsonOutputFiles()
        self.mtd = FilePath()
        self.mdd = FilePath()
        self.mtr = FilePath()
        self.rdd = FilePath()
        self.dfs = FilePath()
        self.edd = FilePath()
        self.sln = FilePath()
        self.sci = FilePath()
        self.wrl = FilePath()
        self.debug = FilePath()
        self.screenCsv = FilePath()
        self.delightIn = FilePath()
        self.iniFile = FilePath()
        self.inStatFilePath = FilePath()
        self.csv = FilePath()
        self.mtr_csv = FilePath()
        self.inputWeatherFilePath = FilePath()
        self.outputMapTabFilePath = ""
        self.outputMapCsvFilePath = ""
        self.outputMapTxtFilePath = ""
        self.outputZszCsvFilePath = ""
        self.outputZszTabFilePath = ""
        self.outputZszTxtFilePath = ""
        self.outputSpszCsvFilePath = ""
        self.outputSpszTabFilePath = ""
        self.outputSpszTxtFilePath = ""
        self.outputSszCsvFilePath = ""
        self.outputSszTabFilePath = ""
        self.outputSszTxtFilePath = ""
        self.outputPszCsvFilePath = ""
        self.outputPszTabFilePath = ""
        self.outputPszTxtFilePath = ""
        self.shade = FilePath()

struct EnergyPlusData:
    var dataGlobal: DataGlobal
    var dataStrGlobals: DataStringGlobals
    var files: FileInfo
    
    fn __init__(inout self):
        self.dataGlobal = DataGlobal()
        self.dataStrGlobals = DataStringGlobals()
        self.files = FileInfo()

# EXTERNAL DEPS (to wire in glue):
# - FileSystem: utilities for path operations (from EnergyPlus)
# - DisplayString: display messages (from EnergyPlus)
# - ShowFatalError: fatal error handler (from EnergyPlus)
# - PluginManagement.pythonStringForUsage: get Python version info (from EnergyPlus)

@export
fn process_args(state: EnergyPlusData, args: List[String]) -> Int32:
    """Process command line arguments for EnergyPlus"""
    
    var dash = "-"
    var arguments = List[String]()
    
    for input_arg in args:
        var double_dash_pos = input_arg.find("--")
        var equals_pos = input_arg.find("=")
        
        if double_dash_pos == 0 and equals_pos != Int(-1):
            arguments.append(input_arg[:equals_pos])
            arguments.append(input_arg[equals_pos + 1:])
        elif double_dash_pos == 0 and len(input_arg) == 2:
            pass
        elif len(input_arg) > 2 and input_arg[0] == '-' and input_arg[1] != '-':
            for c in range(1, len(input_arg)):
                arguments.append(dash + input_arg[c])
        else:
            arguments.append(input_arg)
    
    if len(arguments) > 0:
        _ = arguments.pop(0)
    
    var arg_count = len(arguments)
    var legacy_mode = (arg_count == 0)
    
    state.dataStrGlobals.inputFilePath = "in.idf"
    state.dataStrGlobals.outDirPath = "."
    state.files.inputWeatherFilePath.path = "in.epw"
    
    if legacy_mode:
        state.dataStrGlobals.inputIddFilePath = "Energy+.idd"
    
    var run_epmacro = False
    var prefix_out_name = "eplus"
    var suffix_type = "L"
    var run_expand_objects = False
    
    var i = 0
    while i < len(arguments):
        var arg = arguments[i]
        
        if arg == "-a" or arg == "--annual":
            state.dataGlobal.AnnualSimulation = True
        elif arg == "-D" or arg == "--design-day":
            state.dataGlobal.DDOnlySimulation = True
        elif arg == "-d" or arg == "--output-directory":
            if i + 1 < len(arguments):
                i += 1
                state.dataStrGlobals.outDirPath = arguments[i]
        elif arg == "-i" or arg == "--idd":
            if i + 1 < len(arguments):
                i += 1
                state.dataStrGlobals.inputIddFilePath = arguments[i]
        elif arg == "-m" or arg == "--epmacro":
            run_epmacro = True
        elif arg == "-p" or arg == "--output-prefix":
            if i + 1 < len(arguments):
                i += 1
                prefix_out_name = arguments[i]
        elif arg == "-r" or arg == "--readvars":
            state.dataGlobal.runReadVars = True
        elif arg == "-c" or arg == "--convert":
            state.dataGlobal.outputEpJSONConversion = True
        elif arg == "--convert-only":
            state.dataGlobal.outputEpJSONConversionOnly = True
        elif arg == "-s" or arg == "--output-suffix":
            if i + 1 < len(arguments):
                i += 1
                suffix_type = arguments[i]
        elif arg == "-j" or arg == "--jobs":
            if i + 1 < len(arguments):
                i += 1
                try:
                    var num_threads: Int32 = atol(arguments[i])
                    if num_threads <= 0:
                        state.dataGlobal.numThread = 1
                    else:
                        state.dataGlobal.numThread = num_threads
                except:
                    state.dataGlobal.numThread = 1
        elif arg == "-w" or arg == "--weather":
            if i + 1 < len(arguments):
                i += 1
                state.files.inputWeatherFilePath.path = arguments[i]
        elif arg == "-x" or arg == "--expandobjects":
            run_expand_objects = True
        elif arg == "-v" or arg == "--version":
            if state.dataGlobal.eplusRunningViaAPI:
                return RETURN_CODE_SUCCESS_BUT_HELPER
        elif arg == "--debug-cli":
            pass
        elif not arg.startswith("-"):
            state.dataStrGlobals.inputFilePath = arg
        
        i += 1
    
    return RETURN_CODE_SUCCESS

@export
fn read_ini_file(input_file: String, heading: String, kind_of_parameter: String, data_out: String) -> None:
    """Read INI file and retrieve parameter values"""
    var param = kind_of_parameter
    var found = False
    var new_heading = False
    var data_result = ""
    
    if kind_of_parameter == "dir":
        if len(data_out) > 0:
            if data_out[-1] != '/':
                data_result = data_out + "/"
            else:
                data_result = data_out

@export
fn run_read_vars_eso(state: EnergyPlusData) -> Int32:
    """Run ReadVarsESO tool"""
    return RETURN_CODE_SUCCESS
