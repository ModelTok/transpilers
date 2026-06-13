from EnergyPlus.DataStringGlobals import MatchVersion, VerString
from EnergyPlus.FileSystem import (
    getParentDirectoryPath,
    getFileType,
    is_all_json_type,
    is_idf_type,
    fileExists,
    readFile,
    readJSON,
    makeNativePath,
    replaceFileExtension,
    writeFile,
    FileTypes,
    makeDirectory,
    getFileName,
)
from EnergyPlus.InputProcessing.IdfParser import IdfParser
from EnergyPlus.InputProcessing.InputValidation import Validation
from embedded.EmbeddedEpJSONSchema import embeddedEpJSONSchema
from CLI import App, Option, ParseError, CheckedTransformer, ignore_case, ExistingFile
from fmt import print as fmt_print, format as fmt_format, join as fmt_join
from json import JSON  # nlohmann::json equivalent
from String import String, format as str_format
from List import List
from Dict import Dict
from Tuple import StaticTuple
from Path import Path
from FileHandle import open as file_open
from os import getenv  # for hypothetical OpenMP detection
_OPENMP = False  # placeholder, set to True if OpenMP is available
import array
import threading  # for thread
alias json = JSON
enum OutputTypes:
    Default = 0
    IDF = 1
    epJSON = 2
    CBOR = 3
    MsgPack = 4
    UBJSON = 5
    BSON = 6
    Num = 7
let outputTypeStrs: StaticTuple[String, 7] = StaticTuple(
    "default", "IDF", "epJSON", "CBOR", "MsgPack", "UBJSON", "BSON"
)
let outputTypeExperimentalStart = OutputTypes.CBOR
def displayMessage[Args: AnyVariadic](str_format: String, *args: Args):
    fmt_print(stdout, str_format, *args)
    stdout.write("\n", 1)
def checkVersionMatch(epJSON: json) -> Bool:
    let it = epJSON.find("Version")
    if it != epJSON.end():
        for version in it.value():
            let v: String = version["version_identifier"].get[String]()
            if v.empty():
                displayMessage("Input errors occurred and version ID was left blank, verify file version")
            else:
                var lenVer: Int = len(EnergyPlus::DataStringGlobals::MatchVersion)
                var Which: Int
                if (lenVer > 0) and (EnergyPlus::DataStringGlobals::MatchVersion[lenVer - 1] == '0'):
                    Which = Int(
                        index(v.substr(0, lenVer - 2), EnergyPlus::DataStringGlobals::MatchVersion.substr(0, lenVer - 2))
                    )
                else:
                    Which = Int(index(v, EnergyPlus::DataStringGlobals::MatchVersion))
                if Which != 0:
                    displayMessage(
                        "Version: in IDF=\"{}\" not the same as expected=\"{}\"",
                        v,
                        EnergyPlus::DataStringGlobals::MatchVersion,
                    )
                    return False
    return True
def checkForUnsupportedObjects(epJSON: json, convertHVACTemplate: Bool) -> Bool:
    var errorsFound = False
    let hvacTemplateObjects: StaticTuple[String, 32] = StaticTuple(
        "HVACTemplate:Thermostat",
        "HVACTemplate:Zone:IdealLoadsAirSystem",
        "HVACTemplate:Zone:BaseboardHeat",
        "HVACTemplate:Zone:FanCoil",
        "HVACTemplate:Zone:PTAC",
        "HVACTemplate:Zone:PTHP",
        "HVACTemplate:Zone:WaterToAirHeatPump",
        "HVACTemplate:Zone:VRF",
        "HVACTemplate:Zone:Unitary",
        "HVACTemplate:Zone:VAV",
        "HVACTemplate:Zone:VAV:FanPowered",
        "HVACTemplate:Zone:VAV:HeatAndCool",
        "HVACTemplate:Zone:ConstantVolume",
        "HVACTemplate:Zone:DualDuct",
        "HVACTemplate:System:VRF",
        "HVACTemplate:System:Unitary",
        "HVACTemplate:System:UnitaryHeatPump:AirToAir",
        "HVACTemplate:System:UnitarySystem",
        "HVACTemplate:System:VAV",
        "HVACTemplate:System:PackagedVAV",
        "HVACTemplate:System:ConstantVolume",
        "HVACTemplate:System:DualDuct",
        "HVACTemplate:System:DedicatedOutdoorAir",
        "HVACTemplate:Plant:ChilledWaterLoop",
        "HVACTemplate:Plant:Chiller",
        "HVACTemplate:Plant:Chiller:ObjectReference",
        "HVACTemplate:Plant:Tower",
        "HVACTemplate:Plant:Tower:ObjectReference",
        "HVACTemplate:Plant:HotWaterLoop",
        "HVACTemplate:Plant:Boiler",
        "HVACTemplate:Plant:Boiler:ObjectReference",
        "HVACTemplate:Plant:MixedWaterLoop",
    )
    var objectFound = False
    var objectType: String
    if not convertHVACTemplate:
        for count in range(len(hvacTemplateObjects)):
            objectType = hvacTemplateObjects[count]
            let it = epJSON.find(objectType)
            if it != epJSON.end():
                objectFound = True
                break
        if objectFound:
            displayMessage("HVACTemplate:* objects found. These objects are not supported directly by EnergyPlus.")
            displayMessage("You must run the ExpandObjects program on this input.")
            errorsFound = True
    let groundHTObjects: StaticTuple[String, 26] = StaticTuple(
        "GroundHeatTransfer:Control",
        "GroundHeatTransfer:Slab:Materials",
        "GroundHeatTransfer:Slab:MatlProps",
        "GroundHeatTransfer:Slab:BoundConds",
        "GroundHeatTransfer:Slab:BldgProps",
        "GroundHeatTransfer:Slab:Insulation",
        "GroundHeatTransfer:Slab:EquivalentSlab",
        "GroundHeatTransfer:Slab:AutoGrid",
        "GroundHeatTransfer:Slab:ManualGrid",
        "GroundHeatTransfer:Slab:XFACE",
        "GroundHeatTransfer:Slab:YFACE",
        "GroundHeatTransfer:Slab:ZFACE",
        "GroundHeatTransfer:Basement:SimParameters",
        "GroundHeatTransfer:Basement:MatlProps",
        "GroundHeatTransfer:Basement:Insulation",
        "GroundHeatTransfer:Basement:SurfaceProps",
        "GroundHeatTransfer:Basement:BldgData",
        "GroundHeatTransfer:Basement:Interior",
        "GroundHeatTransfer:Basement:ComBldg",
        "GroundHeatTransfer:Basement:EquivSlab",
        "GroundHeatTransfer:Basement:EquivAutoGrid",
        "GroundHeatTransfer:Basement:AutoGrid",
        "GroundHeatTransfer:Basement:ManualGrid",
        "GroundHeatTransfer:Basement:XFACE",
        "GroundHeatTransfer:Basement:YFACE",
        "GroundHeatTransfer:Basement:ZFACE",
    )
    objectFound = False
    for count in range(len(groundHTObjects)):
        objectType = groundHTObjects[count]
        let it = epJSON.find(objectType)
        if it != epJSON.end():
            objectFound = True
            break
    if objectFound:
        displayMessage("GroundHeatTransfer:* objects found. These objects are not supported directly by EnergyPlus.")
        displayMessage("You must run the ExpandObjects program on this input.")
        errorsFound = True
    let parametricObjects: StaticTuple[String, 4] = StaticTuple(
        "Parametric:SetValueForRun", "Parametric:Logic", "Parametric:RunControl", "Parametric:FileNameSuffix"
    )
    objectFound = False
    for count in range(len(parametricObjects)):
        objectType = parametricObjects[count]
        let it = epJSON.find(objectType)
        if it != epJSON.end():
            objectFound = True
            break
    if objectFound:
        displayMessage("Parametric:* objects found. These objects are not supported directly by EnergyPlus.")
        displayMessage("You must run the ParametricPreprocesor program on this input.")
        errorsFound = True
    return errorsFound
def processErrors(
    idf_parser: IdfParser,
    validation: Validation,
    isDDY: Bool,
) -> Bool:
    let idf_parser_errors = idf_parser.errors()
    let idf_parser_warnings = idf_parser.warnings()
    let validation_errors = validation.errors()
    var hasValidationErrors = False
    let validation_warnings = validation.warnings()
    for error in idf_parser_errors:
        displayMessage(error)
    for warning in idf_parser_warnings:
        displayMessage(warning)
    for error in validation_errors:
        let missing_building = error.find("Missing required property 'Building'") != -1
        let missing_geometry = error.find("Missing required property 'GlobalGeometryRules'") != -1
        if missing_building or missing_geometry:
            if isDDY:  # for DDY files just ignore it completely
                continue
            displayMessage(error)
            continue
        hasValidationErrors = True
        displayMessage(error)
    for warning in validation_warnings:
        displayMessage(warning)
    return hasValidationErrors or idf_parser.hasErrors()
def cleanEPJSON(inout epjson: json):
    if epjson.type() == json.value_t.object:
        epjson.erase("idf_order")
        epjson.erase("idf_max_fields")
        epjson.erase("idf_max_extensible_fields")
        for it in epjson.items():
            cleanEPJSON(epjson[it.key()])
def processInput(
    inputFilePath: Path,
    schema: json,
    outputType: OutputTypes,
    outputDirPath: Path,
    inout outputTypeStr: String,
    convertHVACTemplate: Bool,
) -> Bool:
    var validation = Validation(&schema)
    var idf_parser = IdfParser()
    var epJSON: json
    let inputDirPath = EnergyPlus::FileSystem::getParentDirectoryPath(inputFilePath)
    if outputDirPath.empty():
        outputDirPath = inputDirPath
    let inputFileType = EnergyPlus::FileSystem::getFileType(inputFilePath)
    let isEpJSON = EnergyPlus::FileSystem::is_all_json_type(inputFileType)
    let isCBOR = (inputFileType == EnergyPlus::FileSystem::FileTypes::CBOR)
    let isMsgPack = (inputFileType == EnergyPlus::FileSystem::FileTypes::MsgPack)
    let isUBJSON = (inputFileType == EnergyPlus::FileSystem::FileTypes::UBJSON)
    let isBSON = (inputFileType == EnergyPlus::FileSystem::FileTypes::BSON)
    let isIDForIMF = EnergyPlus::FileSystem::is_idf_type(inputFileType)  # IDF or IMF
    let isDDY = (inputFileType == EnergyPlus::FileSystem::FileTypes::DDY)
    if not (isEpJSON or isIDForIMF or isDDY):
        displayMessage("ERROR: Input file must have IDF, IMF, DDY, or epJSON extension.")
        return False
    if (outputType == OutputTypes::epJSON) and (
        (inputFileType == EnergyPlus::FileSystem::FileTypes::EpJSON) or (inputFileType == EnergyPlus::FileSystem::FileTypes::JSON)
    ):
        displayMessage("Same output format as input format requested (epJSON). Skipping conversion and moving to next file.")
        return False
    elif (outputType == OutputTypes::IDF) and (isIDForIMF or isDDY):
        displayMessage("Same output format as input format requested (IDF). Skipping conversion and moving to next file.")
        return False
    elif (outputType == OutputTypes::CBOR) and isCBOR:
        displayMessage("Same output format as input format requested (CBOR). Skipping conversion and moving to next file.")
        return False
    elif (outputType == OutputTypes::MsgPack) and isMsgPack:
        displayMessage("Same output format as input format requested (MsgPack). Skipping conversion and moving to next file.")
        return False
    elif (outputType == OutputTypes::UBJSON) and isUBJSON:
        displayMessage("Same output format as input format requested (UBJSON). Skipping conversion and moving to next file.")
        return False
    elif (outputType == OutputTypes::BSON) and isBSON:
        displayMessage("Same output format as input format requested (BSON). Skipping conversion and moving to next file.")
        return False
    if not EnergyPlus::FileSystem::fileExists(inputFilePath):
        displayMessage("Input file path {} not found", inputFilePath.generic_string())
        return False
    try:
        if not isEpJSON:
            let input_file = EnergyPlus::FileSystem::readFile(inputFilePath)
            var success = True
            epJSON = idf_parser.decode(input_file, schema, success)
            cleanEPJSON(epJSON)
        else:
            epJSON = EnergyPlus::FileSystem::readJSON(inputFilePath)
    except Exception as e:
        displayMessage(e.what())
        displayMessage("Errors occurred when processing input file. Preceding condition(s) cause termination.")
        return False
    let is_valid = validation.validate(epJSON)
    let hasErrors = processErrors(idf_parser, validation, isDDY)
    if isDDY and not hasErrors:
        is_valid = True
    let versionMatch = checkVersionMatch(epJSON)
    let unsupportedFound = checkForUnsupportedObjects(epJSON, convertHVACTemplate)
    if not is_valid or hasErrors or unsupportedFound:
        displayMessage("Errors occurred when validating input file. Preceding condition(s) cause termination.")
        return False
    if isEpJSON and not versionMatch:
        displayMessage("Skipping conversion of input file to IDF due to mismatched Version.")
        return False
    let outputFilePathWithOriExtension = outputDirPath / EnergyPlus::FileSystem::getFileName(inputFilePath)
    if (outputType == OutputTypes::Default or outputType == OutputTypes::IDF) and isEpJSON:
        let input_file = idf_parser.encode(epJSON, schema)
        var convertedEpJSON = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".idf")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::IDF](convertedEpJSON, input_file)
        outputTypeStr = "IDF"
    elif (outputType == OutputTypes::Default or outputType == OutputTypes::epJSON) and not isEpJSON:
        var convertedIDF = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".epJSON")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::EpJSON](convertedIDF, epJSON)
        outputTypeStr = "EPJSON"
    elif outputType == OutputTypes::CBOR:
        var convertedCBOR = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".cbor")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::CBOR](convertedCBOR, epJSON)
    elif outputType == OutputTypes::MsgPack:
        var convertedMsgPack = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".msgpack")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::MsgPack](convertedMsgPack, epJSON)
    elif outputType == OutputTypes::UBJSON:
        var convertedUBJSON = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".ubjson")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::UBJSON](convertedUBJSON, epJSON)
    elif outputType == OutputTypes::BSON:
        var convertedBSON = EnergyPlus::FileSystem::makeNativePath(
            EnergyPlus::FileSystem::replaceFileExtension(outputFilePathWithOriExtension, ".bson")
        )
        EnergyPlus::FileSystem::writeFile[EnergyPlus::FileSystem::FileTypes::BSON](convertedBSON, epJSON)
    else:
        return False
    return True
def parse_input_paths(inputFilePath: Path) -> List[Path]:
    let input_paths_stream = file_open(inputFilePath, "r")
    if not input_paths_stream.is_open():
        displayMessage("Could not open file: {}", inputFilePath.generic_string())
        return List[Path]()
    var input_paths = List[Path]()
    var line: String
    while input_paths_stream.read_line(line):
        if line.empty():
            continue
        var input_file = Path(line)
        if not input_file.is_regular_file():
            input_file = inputFilePath.parent_path() / input_file
            if not input_file.is_regular_file():
                displayMessage("Input file does not exist: {}", line)
                continue
        input_paths.append(input_file)
    return input_paths
def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    var app = CLI::App("ConvertInputFormat")
    argv = app.ensure_utf8(argv)
    app.description("Run input file conversion tool")
    app.set_version_flag("-v,--version", EnergyPlus::DataStringGlobals::VerString)
    if _OPENMP:
        var number_of_threads = threading.hardware_concurrency()
    else:
        var number_of_threads = 1
    @parameter
    if not _OPENMP:
        let nproc_opt: CLI::Option = app.add_option("-j", number_of_threads, fmt_format("Number of threads [Default: {}]", number_of_threads)).option_text("N")
        if not _OPENMP:
            nproc_opt.group("")
    var inputFilePath: Path
    app.add_option("-i,--input", inputFilePath, "Text file with list of input files to convert (newline delimited)") \
        .required(False) \
        .option_text("LSTFILE") \
        .check(CLI::ExistingFile)
    var outputDirectoryPath: Path
    app.add_option("-o,--output", outputDirectoryPath, "Output directory. Will use input file location by default") \
        .option_text("DIR") \
        .required(False)
    let outputTypeMap: Dict[String, OutputTypes] = {
        "default": OutputTypes.Default,
        "idf": OutputTypes.IDF,
        "epjson": OutputTypes.epJSON,
        "cbor": OutputTypes.CBOR,
        "msgpack": OutputTypes.MsgPack,
        "ubjson": OutputTypes.UBJSON,
        "bson": OutputTypes.BSON,
    }
    var outputType: OutputTypes = OutputTypes.Default
    let help_message = fmt_format(
        """Output format.
Default means IDF->epJSON or epJSON->IDF
Select one (case insensitive):
[{}]""",
        fmt_join(outputTypeStrs, ","),
    )
    app.add_option("-f,--format", outputType, help_message) \
        .option_text("FORMAT") \
        .required(False) \
        .transform(CLI::CheckedTransformer(outputTypeMap, CLI::ignore_case))
    var noConvertHVACTemplate = False
    app.add_flag("-n,--noHVACTemplate", noConvertHVACTemplate, "Do not convert HVACTemplate objects")
    var files: List[Path]
    app.add_option("input_file", files, "Multiple input files to be translated") \
        .required(False) \
        .check(CLI::ExistingFile)
    app.footer("Example: ConvertInputFormat in.idf")
    try:
        app.parse(argc, argv)
    except CLI::ParseError as e:
        return app.exit(e)
    let convertHVACTemplate = not noConvertHVACTemplate
    if not outputDirectoryPath.empty():
        EnergyPlus::FileSystem::makeDirectory(outputDirectoryPath)
    if not inputFilePath.empty():
        var list_files = parse_input_paths(inputFilePath)
        files.extend(list_files)
    var outputTypeStr = outputTypeStrs[Int(outputType)]
    if outputType >= outputTypeExperimentalStart:
        displayMessage("{} input format is experimental.", outputTypeStr)
    if files.empty():
        displayMessage("No valid files found. Either specify --input or pass files as extra arguments")
        return 1
    files.sort()
    var it = files.unique()
    files.resize(files.begin().distance(it))
    let embeddedEpJSONSchema = EnergyPlus::EmbeddedEpJSONSchema.embeddedEpJSONSchema()
    let schema = json.from_cbor(embeddedEpJSONSchema)
    let number_files = Int(len(files))
    var fileCount: Int = 0
    if _OPENMP:
        omp_set_num_threads(number_of_threads)
        {
            for i in range(number_files):
                let successful = processInput(files[i], schema, outputType, outputDirectoryPath, outputTypeStr, convertHVACTemplate)
                fileCount += 1
                if successful:
                    displayMessage(
                        "Input file converted to {} successfully | {}/{} | {}",
                        outputTypeStr,
                        fileCount,
                        number_files,
                        files[i].generic_string(),
                    )
                else:
                    displayMessage(
                        "Input file conversion failed: | {}/{} | {}",
                        fileCount,
                        number_files,
                        files[i].generic_string(),
                    )
        }
    else:
        if number_of_threads > 1:
            displayMessage(
                "ConvertInputFormat is not compiled with OpenMP. Only running on 1 thread, not requested {} threads.",
                number_of_threads,
            )
        for file in files:
            let successful = processInput(file, schema, outputType, outputDirectoryPath, outputTypeStr, convertHVACTemplate)
            fileCount += 1
            if successful:
                displayMessage(
                    "Input file converted to {} successfully | {}/{} | {}",
                    outputTypeStr,
                    fileCount,
                    number_files,
                    file.generic_string(),
                )
            else:
                displayMessage(
                    "Input file conversion failed: | {}/{} | {}",
                    fileCount,
                    number_files,
                    file.generic_string(),
                )
    return 0