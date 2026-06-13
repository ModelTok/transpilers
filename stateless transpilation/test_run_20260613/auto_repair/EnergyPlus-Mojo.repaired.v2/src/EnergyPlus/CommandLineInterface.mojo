from sys import exit
from os import path, getenv
from threading import hardware_concurrency  # approximate mapping
from CLI import App, Success, ParseError, ExistingFile, IsMember, ignore_case, detail  # assume Mojo CLI package
from EnergyPlus.api.API import EnergyPlusAPI  # stub import
from EnergyPlus.Data import EnergyPlusData
from EnergyPlus.DataStringGlobals import VerString, BuildPlatformString, VerStringVar
from DisplayRoutines import DisplayString
from EnergyPlus.EnergyPlus import EnergyPlus
from FileSystem import (
    getParentDirectoryPath,
    getAbsolutePath,
    getProgramPath,
    makeNativePath,
    getFileName,
    getFileType,
    is_all_json_type,
    fileExists,
    makeDirectory,
    appendSuffixToPath,
    toString,
    linkFile,
    removeFile,
    moveFile,
    systemCall,
    exeExtension,
    FileTypes,
    pathChar,
)
from PluginManager import PluginManagement
from PythonEngine import PythonEngine
from UtilityRoutines import ShowFatalError, strip, ConvertCaseToLower, has, index, len, stripped
@value
struct ReturnCodes:
    Invalid = -1
    Success = 0
    Failure = 1
    SuccessButHelper = 2
    Num = 3
def ProcessArgs(inout state: EnergyPlusData, args: List[String]) -> Int:
    using size_type = Int
    var arguments = List[String]()
    let dash = "-"
    for inputArg in args:
        let doubleDashPosition = inputArg.find("--")
        let equalsPosition = inputArg.find("=")
        if doubleDashPosition == 0 and equalsPosition != -1:
            arguments.append(inputArg[0:equalsPosition])
            arguments.append(inputArg[equalsPosition+1: inputArg.size()-1])
        elif doubleDashPosition == 0 and inputArg.size() == 2:

        elif (inputArg.size() > 2) and (inputArg[0] == '-') and (inputArg[1] != '-'):
            var c = 1
            while c < inputArg.size():
                arguments.append(dash + inputArg[c])
                c += 1
        else:
            arguments.append(inputArg)
    let programName = arguments.pop(0)
    let argCount = arguments.size()
    let legacyMode = (argCount == 0)
    if not state.dataGlobal.installRootOverride:
        state.dataStrGlobals.exeDirectoryPath = getParentDirectoryPath(getAbsolutePath(getProgramPath()))
    let app = App("energyplus", programName)
    app.set_version_flag("-v,--version", VerString)
    let description = String.format(
        "{}\nPythonLinkage: {}\nBuilt on Platform: {}\n",
        state.dataStrGlobals.VerStringVar,
        PluginManagement.pythonStringForUsage(state),
        BuildPlatformString
    )
    app.description(description)
    let annualOpt = app.add_flag("-a,--annual", state.dataGlobal.AnnualSimulation, "Force annual simulation")
    app.add_flag("-D,--design-day", state.dataGlobal.DDOnlySimulation, "Force design-day-only simulation").excludes(annualOpt)
    app.add_option("-d,--output-directory", state.dataStrGlobals.outDirPath, "Output directory path (default: current directory)").option_text("DIR").required(false)
    if legacyMode:
        state.dataStrGlobals.inputIddFilePath = "Energy+.idd"
    else:
        state.dataStrGlobals.inputIddFilePath = state.dataStrGlobals.exeDirectoryPath / "Energy+.idd"
    app.add_option("-i,--idd", state.dataStrGlobals.inputIddFilePath, "Input data dictionary path (default: Energy+.idd in executable directory)").required(false).option_text("IDD").check(ExistingFile())
    var runEPMacro = False
    app.add_flag("-m,--epmacro", runEPMacro, "Run EPMacro prior to simulation")
    var prefixOutName = "eplus"
    app.add_option("-p,--output-prefix", prefixOutName, "Prefix for output file names (default: eplus)").required(false).option_text("PRE")
    app.add_flag("-r,--readvars", state.dataGlobal.runReadVars, "Run ReadVarsESO after simulation")
    app.add_flag("-c,--convert", state.dataGlobal.outputEpJSONConversion, "Output IDF->epJSON or epJSON->IDF, dependent on input file type")
    app.add_flag("--convert-only", state.dataGlobal.outputEpJSONConversionOnly, "Only convert IDF->epJSON or epJSON->IDF, dependent on input file type. No simulation")
    var suffixType = "L"
    let suffixHelp = """Suffix style for output file names (default: L)
   L: Legacy (e.g., eplustbl.csv)
   C: Capital (e.g., eplusTable.csv)
   D: Dash (e.g., eplus-table.csv)"""
    app.add_option("-s,--output-suffix", suffixType, suffixHelp).option_text("SUFFIX").required(false).check(IsMember({"L", "C", "D"}, ignore_case))
    let MAX_N = Int(hardware_concurrency())
    app.add_option("-j,--jobs", state.dataGlobal.numThread, "Multi-thread with N threads; 1 thread with no arg. (Currently only for G-Function generation)").option_text("N").transform(lambda input: String {
        var number_of_threads = -1
        let converted = detail.lexical_cast(input, number_of_threads)
        if not converted:
            return String.format("Argument should be an integer, not '{}'", input)
        if number_of_threads <= 0:
            DisplayString(state, "Invalid value for -j arg. Defaulting to 1.")
            return "1"
        if number_of_threads > MAX_N:
            DisplayString(state, String.format("Invalid value for -j arg. Value exceeds num available. Defaulting to num available. -j {}", MAX_N))
            return String(MAX_N)
        return input
    })
    state.files.inputWeatherFilePath.filePath = "in.epw"
    let weatherPathOpt = app.add_option("-w,--weather", state.files.inputWeatherFilePath.filePath, "Weather file path (default: in.epw in current directory)").required(false).option_text("EPW")
    var runExpandObjects = False
    app.add_flag("-x,--expandobjects", runExpandObjects, "Run ExpandObjects prior to simulation")
    state.dataStrGlobals.inputFilePath = "in.idf"
    app.add_option("input_file", state.dataStrGlobals.inputFilePath, "Input file (default: in.idf in current directory)").required(false).check(ExistingFile())
    var debugCLI = False
    for arg in args:
        if arg == "--debug-cli":
            debugCLI = True
            break
    if debugCLI:
        print("ProcessArgs: received args")
        var na = 0
        for a in args:
            print("* {}: '{}'".format(na, a))
            na += 1
        print("\nAfter massaging/expanding of args")
        na = 0
        for a in arguments:
            print("* {}: '{}'".format(na, a))
            na += 1
        print("")
    app.add_flag("--debug-cli", debugCLI, "Print the result of the CLI assignments to the console and exit").group("")
    let auxiliaryToolsSubcommand = app.add_subcommand("auxiliary", "Run Auxiliary Python Tools")
    auxiliaryToolsSubcommand.require_subcommand()
    var python_fwd_args = List[String]()
    let epLaunchSubCommand = auxiliaryToolsSubcommand.add_subcommand("eplaunch", "EnergyPlus Launch")
    epLaunchSubCommand.add_option("args", python_fwd_args, "Extra Arguments forwarded to EnergyPlus Launch").option_text("ARG ...")
    epLaunchSubCommand.positionals_at_end(True)
    epLaunchSubCommand.footer("You can pass extra arguments after the eplaunch keyword, they will be forwarded to EnergyPlus Launch.")
    epLaunchSubCommand.callback(lambda: {
        let engine = PythonEngine(state)
        var cmd = PythonEngine.getTclPreppedPreamble(python_fwd_args)
        cmd += """python
from eplaunch.tk_runner import main_gui
main_gui(True)
"""
        engine.exec(cmd)
        exit(0)
    })
    let updaterSubCommand = auxiliaryToolsSubcommand.add_subcommand("updater", "IDF Version Updater")
    updaterSubCommand.add_option("args", python_fwd_args, "Extra Arguments forwarded to IDF Version Updater").option_text("ARG ...")
    updaterSubCommand.positionals_at_end(True)
    updaterSubCommand.footer("You can pass extra arguments after the updater keyword, they will be forwarded to IDF Version Updater.")
    updaterSubCommand.callback(lambda: {
        let engine = PythonEngine(state)
        var cmd = PythonEngine.getTclPreppedPreamble(python_fwd_args)
        cmd += """python
from energyplus_transition.runner import main_gui
main_gui(True)
"""
        engine.exec(cmd)
        exit(0)
    })
    let gheDesignerSubCommand = auxiliaryToolsSubcommand.add_subcommand("ghedesigner", "GHEDesigner Operation")
    gheDesignerSubCommand.add_option("args", python_fwd_args, "Extra Arguments forwarded to GHEDesigner").option_text("ARG ...")
    gheDesignerSubCommand.positionals_at_end(True)
    gheDesignerSubCommand.footer("You can pass extra arguments after the ghedesigner keyword, they should be the input file and output directory.")
    gheDesignerSubCommand.callback(lambda: {
        let engine = PythonEngine(state)
        var cmd = PythonEngine.getTclPreppedPreamble(python_fwd_args)
        cmd += """python
from ghedesigner.main import run_manager_from_cli
run_manager_from_cli()
"""
        try:
            engine.exec(cmd)
            exit(0)
        except Error:
            exit(1)
    })
    app.footer("Example: energyplus -w weather.epw -r input.idf")
    let eplusRunningViaAPI = state.dataGlobal.eplusRunningViaAPI
    try:
        arguments.reverse()
        app.parse(arguments)
    except Success as e:
        let return_code = app.exit(e)
        if eplusRunningViaAPI:
            return ReturnCodes.SuccessButHelper
        exit(return_code)
    except ParseError as e:
        let return_code = app.exit(e)
        if eplusRunningViaAPI:
            return ReturnCodes.Failure
        exit(return_code)
    if debugCLI:
        print(
            "state.dataGlobal.AnnualSimulation = {}\n"
            "state.dataGlobal.DDOnlySimulation = {}\n"
            "state.dataStrGlobals.outDirPath = '{}'\n"
            "state.dataStrGlobals.inputIddFilePath= '{}'\n"
            "runEPMacro = {}\n"
            "prefixOutName = {}\n"
            "state.dataGlobal.runReadVars={}\n"
            "state.dataGlobal.outputEpJSONConversion={}\n"
            "state.dataGlobal.outputEpJSONConversionOnly={}\n"
            "suffixType={}\n"
            "state.dataGlobal.numThread={}\n"
            "state.files.inputWeatherFilePath.filePath='{}'\n"
            "state.dataStrGlobals.inputFilePath='{}'\n".format(
                state.dataGlobal.AnnualSimulation,
                state.dataGlobal.DDOnlySimulation,
                state.dataStrGlobals.outDirPath,
                state.dataStrGlobals.inputIddFilePath,
                runEPMacro,
                prefixOutName,
                state.dataGlobal.runReadVars,
                state.dataGlobal.outputEpJSONConversion,
                state.dataGlobal.outputEpJSONConversionOnly,
                suffixType,
                state.dataGlobal.numThread,
                state.files.inputWeatherFilePath.filePath,
                state.dataStrGlobals.inputFilePath
            )
        )
        print("--debug-cli passed: exiting early\n")
        exit(0)
    state.dataStrGlobals.inputFilePath = makeNativePath(state.dataStrGlobals.inputFilePath)
    state.files.inputWeatherFilePath.filePath = makeNativePath(state.files.inputWeatherFilePath.filePath)
    state.dataStrGlobals.inputIddFilePath = makeNativePath(state.dataStrGlobals.inputIddFilePath)
    state.dataStrGlobals.outDirPath = makeNativePath(state.dataStrGlobals.outDirPath)
    state.dataStrGlobals.inputFilePathNameOnly = getFileName(state.dataStrGlobals.inputFilePath)
    state.dataStrGlobals.inputDirPath = getParentDirectoryPath(state.dataStrGlobals.inputFilePath)
    let fileType = getFileType(state.dataStrGlobals.inputFilePath)
    state.dataGlobal.isEpJSON = is_all_json_type(fileType)
    if fileType == FileTypes.IDF or fileType == FileTypes.IMF or fileType == FileTypes.EpJSON or fileType == FileTypes.JSON:

    elif fileType == FileTypes.CBOR:
        DisplayString(state, "CBOR input format is experimental and unsupported.")
    elif fileType == FileTypes.MsgPack:
        DisplayString(state, "MsgPack input format is experimental and unsupported.")
    elif fileType == FileTypes.UBJSON:
        DisplayString(state, "UBJSON input format is experimental and unsupported.")
    elif fileType == FileTypes.BSON:
        DisplayString(state, "BSON input format is experimental and unsupported.")
    else:
        DisplayString(state, String.format("ERROR: Input file must have IDF, IMF, or epJSON extension: {}", state.dataStrGlobals.inputFilePath.generic_string()))
        if eplusRunningViaAPI:
            return ReturnCodes.Failure
        exit(EXIT_FAILURE)
    if not state.dataStrGlobals.outDirPath.empty():
        makeDirectory(state.dataStrGlobals.outDirPath)
    let outputFilePrefixFullPath = state.dataStrGlobals.outDirPath / prefixOutName
    var outputEpmdetFilePath: Path = ""
    var outputEpmidfFilePath: Path = ""
    var outputExpidfFilePath: Path = ""
    var outputExperrFilePath: Path = ""
    var normalSuffix = ""
    var tableSuffix = ""
    var mapSuffix = ""
    var zszSuffix = ""
    var spszSuffix = ""
    var sszSuffix = ""
    var pszSuffix = ""
    var meterSuffix = ""
    var sqliteSuffix = ""
    var adsSuffix = ""
    var screenSuffix = ""
    var shdSuffix = ""
    let errorFollowUp = "Type 'energyplus --help' for usage."
    suffixType = suffixType.upper()
    if suffixType == "L":
        normalSuffix = "out"
        tableSuffix = "tbl"
        mapSuffix = "map"
        zszSuffix = "zsz"
        spszSuffix = "spsz"
        sszSuffix = "ssz"
        pszSuffix = "psz"
        meterSuffix = "mtr"
        sqliteSuffix = "sqlite"
        adsSuffix = "ADS"
        screenSuffix = "screen"
        shdSuffix = "shading"
    elif suffixType == "D":
        normalSuffix = ""
        tableSuffix = "-table"
        mapSuffix = "-map"
        zszSuffix = "-zsz"
        spszSuffix = "-spsz"
        sszSuffix = "-ssz"
        pszSuffix = "-psz"
        meterSuffix = "-meter"
        sqliteSuffix = "-sqlite"
        adsSuffix = "-ads"
        screenSuffix = "-screen"
        shdSuffix = "-shading"
    elif suffixType == "C":
        normalSuffix = ""
        tableSuffix = "Table"
        mapSuffix = "Map"
        zszSuffix = "Zsz"
        spszSuffix = "Spsz"
        sszSuffix = "Ssz"
        pszSuffix = "Psz"
        meterSuffix = "Meter"
        sqliteSuffix = "Sqlite"
        adsSuffix = "Ads"
        screenSuffix = "Screen"
        shdSuffix = "Shading"
    def composePath(suffix: String) -> Path:
        return appendSuffixToPath(outputFilePrefixFullPath, suffix)
    state.files.audit.filePath = composePath(normalSuffix + ".audit")
    state.files.bnd.filePath = composePath(normalSuffix + ".bnd")
    state.files.dxf.filePath = composePath(normalSuffix + ".dxf")
    state.files.eio.filePath = composePath(normalSuffix + ".eio")
    state.files.endFile.filePath = composePath(normalSuffix + ".end")
    state.files.outputErrFilePath = composePath(normalSuffix + ".err")
    state.files.eso.filePath = composePath(normalSuffix + ".eso")
    state.files.json.outputJsonFilePath = composePath(normalSuffix + ".json")
    state.files.json.outputTSZoneJsonFilePath = composePath(normalSuffix + "_detailed_zone.json")
    state.files.json.outputTSHvacJsonFilePath = composePath(normalSuffix + "_detailed_HVAC.json")
    state.files.json.outputTSJsonFilePath = composePath(normalSuffix + "_timestep.json")
    state.files.json.outputYRJsonFilePath = composePath(normalSuffix + "_yearly.json")
    state.files.json.outputMNJsonFilePath = composePath(normalSuffix + "_monthly.json")
    state.files.json.outputDYJsonFilePath = composePath(normalSuffix + "_daily.json")
    state.files.json.outputHRJsonFilePath = composePath(normalSuffix + "_hourly.json")
    state.files.json.outputSMJsonFilePath = composePath(normalSuffix + "_runperiod.json")
    state.files.json.outputCborFilePath = composePath(normalSuffix + ".cbor")
    state.files.json.outputTSZoneCborFilePath = composePath(normalSuffix + "_detailed_zone.cbor")
    state.files.json.outputTSHvacCborFilePath = composePath(normalSuffix + "_detailed_HVAC.cbor")
    state.files.json.outputTSCborFilePath = composePath(normalSuffix + "_timestep.cbor")
    state.files.json.outputYRCborFilePath = composePath(normalSuffix + "_yearly.cbor")
    state.files.json.outputMNCborFilePath = composePath(normalSuffix + "_monthly.cbor")
    state.files.json.outputDYCborFilePath = composePath(normalSuffix + "_daily.cbor")
    state.files.json.outputHRCborFilePath = composePath(normalSuffix + "_hourly.cbor")
    state.files.json.outputSMCborFilePath = composePath(normalSuffix + "_runperiod.cbor")
    state.files.json.outputMsgPackFilePath = composePath(normalSuffix + ".msgpack")
    state.files.json.outputTSZoneMsgPackFilePath = composePath(normalSuffix + "_detailed_zone.msgpack")
    state.files.json.outputTSHvacMsgPackFilePath = composePath(normalSuffix + "_detailed_HVAC.msgpack")
    state.files.json.outputTSMsgPackFilePath = composePath(normalSuffix + "_timestep.msgpack")
    state.files.json.outputYRMsgPackFilePath = composePath(normalSuffix + "_yearly.msgpack")
    state.files.json.outputMNMsgPackFilePath = composePath(normalSuffix + "_monthly.msgpack")
    state.files.json.outputDYMsgPackFilePath = composePath(normalSuffix + "_daily.msgpack")
    state.files.json.outputHRMsgPackFilePath = composePath(normalSuffix + "_hourly.msgpack")
    state.files.json.outputSMMsgPackFilePath = composePath(normalSuffix + "_runperiod.msgpack")
    state.files.mtd.filePath = composePath(normalSuffix + ".mtd")
    state.files.mdd.filePath = composePath(normalSuffix + ".mdd")
    state.files.mtr.filePath = composePath(normalSuffix + ".mtr")
    state.files.rdd.filePath = composePath(normalSuffix + ".rdd")
    state.dataStrGlobals.outputShdFilePath = composePath(normalSuffix + ".shd")
    state.files.dfs.filePath = composePath(normalSuffix + ".dfs")
    state.dataStrGlobals.outputGLHEFilePath = composePath(normalSuffix + ".glhe")
    state.files.edd.filePath = composePath(normalSuffix + ".edd")
    state.dataStrGlobals.outputIperrFilePath = composePath(normalSuffix + ".iperr")
    state.files.sln.filePath = composePath(normalSuffix + ".sln")
    state.files.sci.filePath = composePath(normalSuffix + ".sci")
    state.files.wrl.filePath = composePath(normalSuffix + ".wrl")
    state.dataStrGlobals.outputSqlFilePath = composePath(normalSuffix + ".sql")
    state.files.debug.filePath = composePath(normalSuffix + ".dbg")
    state.dataStrGlobals.outputPerfLogFilePath = composePath(normalSuffix + "_perflog.csv")
    state.dataStrGlobals.outputTblCsvFilePath = composePath(tableSuffix + ".csv")
    state.dataStrGlobals.outputTblHtmFilePath = composePath(tableSuffix + ".htm")
    state.dataStrGlobals.outputTblTabFilePath = composePath(tableSuffix + ".tab")
    state.dataStrGlobals.outputTblTxtFilePath = composePath(tableSuffix + ".txt")
    state.dataStrGlobals.outputTblXmlFilePath = composePath(tableSuffix + ".xml")
    state.files.outputMapTabFilePath = composePath(mapSuffix + ".tab")
    state.files.outputMapCsvFilePath = composePath(mapSuffix + ".csv")
    state.files.outputMapTxtFilePath = composePath(mapSuffix + ".txt")
    state.files.outputZszCsvFilePath = composePath(zszSuffix + ".csv")
    state.files.outputZszTabFilePath = composePath(zszSuffix + ".tab")
    state.files.outputZszTxtFilePath = composePath(zszSuffix + ".txt")
    state.files.outputSpszCsvFilePath = composePath(spszSuffix + ".csv")
    state.files.outputSpszTabFilePath = composePath(spszSuffix + ".tab")
    state.files.outputSpszTxtFilePath = composePath(spszSuffix + ".txt")
    state.files.outputSszCsvFilePath = composePath(sszSuffix + ".csv")
    state.files.outputSszTabFilePath = composePath(sszSuffix + ".tab")
    state.files.outputSszTxtFilePath = composePath(sszSuffix + ".txt")
    state.files.outputPszCsvFilePath = composePath(pszSuffix + ".csv")
    state.files.outputPszTabFilePath = composePath(pszSuffix + ".tab")
    state.files.outputPszTxtFilePath = composePath(pszSuffix + ".txt")
    state.dataStrGlobals.outputAdsFilePath = composePath(adsSuffix + ".out")
    state.files.shade.filePath = composePath(shdSuffix + ".csv")
    if suffixType == "L":
        state.dataStrGlobals.outputSqliteErrFilePath = state.dataStrGlobals.outDirPath / Path(sqliteSuffix + ".err")
    else:
        state.dataStrGlobals.outputSqliteErrFilePath = composePath(sqliteSuffix + ".err")
    state.files.screenCsv.filePath = composePath(screenSuffix + ".csv")
    state.files.delightIn.filePath = "eplusout.delightin"
    state.dataStrGlobals.outputDelightOutFilePath = "eplusout.delightout"
    state.files.iniFile.filePath = "Energy+.ini"
    state.files.inStatFilePath.filePath = state.files.inputWeatherFilePath.filePath
    state.files.inStatFilePath.filePath.replace_extension(".stat")
    state.dataStrGlobals.eplusADSFilePath = state.dataStrGlobals.inputDirPath / "eplusADS.inp"
    state.files.csv.filePath = composePath(normalSuffix + ".csv")
    state.files.mtr_csv.filePath = composePath(meterSuffix + ".csv")
    state.dataStrGlobals.outputRvauditFilePath = composePath(normalSuffix + ".rvaudit")
    outputEpmdetFilePath = composePath(normalSuffix + ".epmdet")
    outputEpmidfFilePath = composePath(normalSuffix + ".epmidf")
    outputExpidfFilePath = composePath(normalSuffix + ".expidf")
    outputExperrFilePath = composePath(normalSuffix + ".experr")
    if fileExists(state.files.iniFile.filePath):
        var iniFile = state.files.iniFile.try_open()
        if not iniFile.good():
            DisplayString(state, String.format("ERROR: Could not open file {} for input (read).", iniFile.filePath.string()))
            if eplusRunningViaAPI:
                return ReturnCodes.Failure
            exit(EXIT_FAILURE)
        state.dataStrGlobals.CurrentWorkingFolder = iniFile.filePath
        var programPathStr: String
        ReadINIFile(iniFile, "program", "dir", programPathStr)
        if not programPathStr.empty():
            state.dataStrGlobals.ProgramPath = Path(programPathStr)
            state.dataStrGlobals.inputIddFilePath = state.dataStrGlobals.ProgramPath / "Energy+.idd"
    if not fileExists(state.dataStrGlobals.inputFilePath):
        DisplayString(state, String.format("ERROR: Could not find input data file: {}.", getAbsolutePath(state.dataStrGlobals.inputFilePath).string()))
        DisplayString(state, errorFollowUp)
        if eplusRunningViaAPI:
            return ReturnCodes.Failure
        exit(EXIT_FAILURE)
    if (weatherPathOpt.count() > 0) and not state.dataGlobal.DDOnlySimulation:
        if not fileExists(state.files.inputWeatherFilePath.filePath):
            DisplayString(state, String.format("ERROR: Could not find weather file: {}.", getAbsolutePath(state.files.inputWeatherFilePath.filePath).string()))
            DisplayString(state, errorFollowUp)
            if eplusRunningViaAPI:
                return ReturnCodes.Failure
            exit(EXIT_FAILURE)
    if runEPMacro:
        let epMacroPath = (state.dataStrGlobals.exeDirectoryPath / "EPMacro").replace_extension(exeExtension)
        if not fileExists(epMacroPath):
            DisplayString(state, String.format("ERROR: Could not find EPMacro executable: {}.", getAbsolutePath(epMacroPath).string()))
            if eplusRunningViaAPI:
                return ReturnCodes.Failure
            exit(EXIT_FAILURE)
        let epMacroCommand = "\"" + toString(epMacroPath) + "\""
        let inputFilePathdIn = (getAbsolutePath(state.dataStrGlobals.inputFilePath) == getAbsolutePath("in.imf"))
        if not inputFilePathdIn:
            linkFile(state.dataStrGlobals.inputFilePath, "in.imf")
        DisplayString(state, "Running EPMacro...")
        systemCall(epMacroCommand)
        if not inputFilePathdIn:
            removeFile("in.imf")
        moveFile("audit.out", outputEpmdetFilePath)
        moveFile("out.idf", outputEpmidfFilePath)
        state.dataStrGlobals.inputFilePath = outputEpmidfFilePath
    if runExpandObjects:
        let expandObjectsPath = (state.dataStrGlobals.exeDirectoryPath / Path("ExpandObjects")).replace_extension(exeExtension)
        if not fileExists(expandObjectsPath):
            DisplayString(state, String.format("ERROR: Could not find ExpandObjects executable: {}.", getAbsolutePath(expandObjectsPath).string()))
            if eplusRunningViaAPI:
                return ReturnCodes.Failure
            exit(EXIT_FAILURE)
        let expandObjectsCommand = "\"" + toString(expandObjectsPath) + "\""
        let inputFilePathdIn = (getAbsolutePath(state.dataStrGlobals.inputFilePath) == getAbsolutePath("in.idf"))
        if not fileExists(state.dataStrGlobals.inputIddFilePath):
            DisplayString(state, String.format("ERROR: Could not find input data dictionary: {}.", getAbsolutePath(state.dataStrGlobals.inputIddFilePath).string()))
            DisplayString(state, errorFollowUp)
            if eplusRunningViaAPI:
                return ReturnCodes.Failure
            exit(EXIT_FAILURE)
        let iddFilePathdEnergy = (getAbsolutePath(state.dataStrGlobals.inputIddFilePath) == getAbsolutePath("Energy+.idd"))
        if not inputFilePathdIn:
            linkFile(state.dataStrGlobals.inputFilePath, "in.idf")
        if not iddFilePathdEnergy:
            linkFile(state.dataStrGlobals.inputIddFilePath, "Energy+.idd")
        systemCall(expandObjectsCommand)
        if not inputFilePathdIn:
            removeFile("in.idf")
        if not iddFilePathdEnergy:
            removeFile("Energy+.idd")
        moveFile("expandedidf.err", outputExperrFilePath)
        if fileExists("expanded.idf"):
            moveFile("expanded.idf", outputExpidfFilePath)
            state.dataStrGlobals.inputFilePath = outputExpidfFilePath
    return ReturnCodes.Success
def ReadINIFile(inout inputFile: InputFile, Heading: String, KindofParameter: String, inout DataOut: String):
    var Param = ""
    var ILB: size_type = 0
    var IRB: size_type = 0
    var IEQ: size_type = 0
    var IPAR: size_type = 0
    var IPOS: size_type = 0
    DataOut.clear()
    Param = KindofParameter
    strip(Param)
    inputFile.rewind()
    var Found = False
    var NewHeading = False
    while inputFile.good() and not Found:
        let readResult = inputFile.readLine()
        if readResult.eof:
            break
        if readResult.data.empty():
            continue
        var LINEOut = ""
        ConvertCaseToLower(readResult.data, LINEOut)
        if not has(LINEOut, Heading):
            continue
        ILB = index(LINEOut, '[')
        IRB = index(LINEOut, ']')
        if ILB == -1 and IRB == -1:
            continue
        if not has(LINEOut, '[' + Heading + ']'):
            continue
        while inputFile.good() and not NewHeading:
            let innerReadResult = inputFile.readLine()
            if innerReadResult.eof:
                break
            var line = innerReadResult.data
            strip(line)
            if line.empty():
                continue
            ConvertCaseToLower(line, LINEOut)
            ILB = index(LINEOut, '[')
            IRB = index(LINEOut, ']')
            NewHeading = (ILB != -1 and IRB != -1)
            IEQ = index(LINEOut, '=')
            IPAR = index(LINEOut, Param)
            if IEQ == -1:
                continue
            if IPAR == -1:
                continue
            if IPAR != 0:
                continue
            if not has(LINEOut, Param + '='):
                continue
            if IPAR > IEQ:
                continue
            DataOut = stripped(line.substr(IEQ + 1))
            Found = True
            break
    if Param == "dir":
        IPOS = len(DataOut)
        if IPOS != 0:
            if DataOut[IPOS - 1] != pathChar:
                DataOut += pathChar
def runReadVarsESO(inout state: EnergyPlusData) -> Int:
    var readVarsPath = (state.dataStrGlobals.exeDirectoryPath / "ReadVarsESO").replace_extension(exeExtension)
    if not fileExists(readVarsPath):
        readVarsPath = (state.dataStrGlobals.exeDirectoryPath / "PostProcess" / "ReadVarsESO").replace_extension(exeExtension)
        if not fileExists(readVarsPath):
            if state.dataGlobal.eplusRunningViaAPI:
                DisplayString(state, "ERROR: Could not find ReadVarsESO executable.  When calling through C API, make sure to call setEnergyPlusRootDirectory")
            else:
                DisplayString(state, String.format("ERROR: Could not find ReadVarsESO executable: {}.", getAbsolutePath(readVarsPath).string()))
            return ReturnCodes.Failure
    let RVIfile = (state.dataStrGlobals.inputDirPath / state.dataStrGlobals.inputFilePathNameOnly).replace_extension(".rvi")
    let MVIfile = (state.dataStrGlobals.inputDirPath / state.dataStrGlobals.inputFilePathNameOnly).replace_extension(".mvi")
    let rviFileExists = fileExists(RVIfile)
    if not rviFileExists:
        let ofs = open(RVIfile, "w")
        if not ofs.good():
            ShowFatalError(state, String.format("EnergyPlus: Could not open file \"{}\" for output (write).", RVIfile.string()))
        else:
            ofs.write(toString(state.files.eso.filePath) + "\n")
            ofs.write(toString(state.files.csv.filePath) + "\n")
        ofs.close()
    let mviFileExists = fileExists(MVIfile)
    if not mviFileExists:
        let ofs = open(MVIfile, "w")
        if not ofs.good():
            ShowFatalError(state, String.format("EnergyPlus: Could not open file \"{}\" for output (write).", RVIfile.string()))
        else:
            ofs.write(toString(state.files.mtr.filePath) + "\n")
            ofs.write(toString(state.files.mtr_csv.filePath) + "\n")
        ofs.close()
    let readVarsRviCommand = "\"" + toString(readVarsPath) + "\" \"" + toString(RVIfile) + "\" unlimited"
    let readVarsMviCommand = "\"" + toString(readVarsPath) + "\" \"" + toString(MVIfile) + "\" unlimited"
    systemCall(readVarsRviCommand)
    systemCall(readVarsMviCommand)
    if not rviFileExists:
        removeFile(RVIfile)
    if not mviFileExists:
        removeFile(MVIfile)
    moveFile("readvars.audit", state.dataStrGlobals.outputRvauditFilePath)
    return ReturnCodes.Success