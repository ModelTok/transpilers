# EXTERNAL DEPS (to wire in glue):
# - EnergyPlus.DataStringGlobals.MatchVersion (str)
# - EnergyPlus.DataStringGlobals.VerString (str)
# - EnergyPlus.FileSystem (module: file_exists, readFile, readJSON, writeFile, getFileType, is_all_json_type, is_idf_type, makeDirectory, makeNativePath, replaceFileExtension, getParentDirectoryPath, getFileName, FileTypes enum)
# - IdfParser (class: decode, encode, errors, warnings, hasErrors)
# - Validation (class: validate, errors, warnings)
# - EnergyPlus.EmbeddedEpJSONSchema.embeddedEpJSONSchema (function returning CBOR bytes)

import argparse
import json
import pathlib
import sys
from enum import IntEnum
from typing import Any, Dict, List

try:
    from energyplus import DataStringGlobals, FileSystem, EmbeddedEpJSONSchema
    from energyplus.input_processing import IdfParser, Validation
except ImportError:
    pass


class OutputTypes(IntEnum):
    DEFAULT = 0
    IDF = 1
    EPJSON = 2
    CBOR = 3
    MSGPACK = 4
    UBJSON = 5
    BSON = 6
    NUM = 7


OUTPUT_TYPE_STRS = ["default", "IDF", "epJSON", "CBOR", "MsgPack", "UBJSON", "BSON"]
OUTPUT_TYPE_EXPERIMENTAL_START = OutputTypes.CBOR


def display_message(str_format: str, *args: Any) -> None:
    if args:
        message = str_format.format(*args)
    else:
        message = str_format
    print(message)


def check_version_match(ep_json: Dict[str, Any]) -> bool:
    if "Version" in ep_json:
        for version_entry in ep_json["Version"]:
            v = version_entry.get("version_identifier", "")
            if not v:
                display_message("Input errors occurred and version ID was left blank, verify file version")
            else:
                len_ver = len(DataStringGlobals.MatchVersion)
                if len_ver > 0 and DataStringGlobals.MatchVersion[len_ver - 1] == '0':
                    which = int(FileSystem.index(v[0:len_ver - 2], DataStringGlobals.MatchVersion[0:len_ver - 2]))
                else:
                    which = int(FileSystem.index(v, DataStringGlobals.MatchVersion))
                if which != 0:
                    display_message('Version: in IDF="{}" not the same as expected="{}"', v, DataStringGlobals.MatchVersion)
                    return False
    return True


def check_for_unsupported_objects(ep_json: Dict[str, Any], convert_hvac_template: bool) -> bool:
    errors_found = False
    hvac_template_objects = [
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
    ]

    if not convert_hvac_template:
        object_found = False
        for count in range(len(hvac_template_objects)):
            object_type = hvac_template_objects[count]
            if object_type in ep_json:
                object_found = True
                break
        if object_found:
            display_message("HVACTemplate:* objects found. These objects are not supported directly by EnergyPlus.")
            display_message("You must run the ExpandObjects program on this input.")
            errors_found = True

    ground_ht_objects = [
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
    ]

    object_found = False
    for count in range(len(ground_ht_objects)):
        object_type = ground_ht_objects[count]
        if object_type in ep_json:
            object_found = True
            break
    if object_found:
        display_message("GroundHeatTransfer:* objects found. These objects are not supported directly by EnergyPlus.")
        display_message("You must run the ExpandObjects program on this input.")
        errors_found = True

    parametric_objects = ["Parametric:SetValueForRun", "Parametric:Logic", "Parametric:RunControl", "Parametric:FileNameSuffix"]

    object_found = False
    for count in range(len(parametric_objects)):
        object_type = parametric_objects[count]
        if object_type in ep_json:
            object_found = True
            break
    if object_found:
        display_message("Parametric:* objects found. These objects are not supported directly by EnergyPlus.")
        display_message("You must run the ParametricPreprocesor program on this input.")
        errors_found = True

    return errors_found


def process_errors(idf_parser: Any, validation: Any, is_ddy: bool) -> bool:
    idf_parser_errors = idf_parser.errors()
    idf_parser_warnings = idf_parser.warnings()
    validation_errors = validation.errors()
    validation_warnings = validation.warnings()

    has_validation_errors = False

    for error in idf_parser_errors:
        display_message(error)
    for warning in idf_parser_warnings:
        display_message(warning)
    for error in validation_errors:
        missing_building = "Missing required property 'Building'" in error
        missing_geometry = "Missing required property 'GlobalGeometryRules'" in error
        if missing_building or missing_geometry:
            if is_ddy:
                continue
            display_message(error)
            continue
        has_validation_errors = True
        display_message(error)
    for warning in validation_warnings:
        display_message(warning)

    return has_validation_errors or idf_parser.has_errors()


def clean_epjson(epjson: Any) -> None:
    if isinstance(epjson, dict):
        epjson.pop("idf_order", None)
        epjson.pop("idf_max_fields", None)
        epjson.pop("idf_max_extensible_fields", None)
        for it_key in list(epjson.keys()):
            clean_epjson(epjson[it_key])


def process_input(
    input_file_path: pathlib.Path,
    schema: Dict[str, Any],
    output_type: OutputTypes,
    output_dir_path: pathlib.Path,
    output_type_str: List[str],
    convert_hvac_template: bool,
) -> bool:
    validation = Validation(schema)
    idf_parser = IdfParser()
    ep_json: Dict[str, Any] = {}

    input_dir_path = FileSystem.get_parent_directory_path(input_file_path)

    if not output_dir_path or str(output_dir_path).strip() == "":
        output_dir_path = input_dir_path

    input_file_type = FileSystem.get_file_type(input_file_path)

    is_ep_json = FileSystem.is_all_json_type(input_file_type)
    is_cbor = input_file_type == FileSystem.FileTypes.CBOR
    is_msgpack = input_file_type == FileSystem.FileTypes.MSGPACK
    is_ubjson = input_file_type == FileSystem.FileTypes.UBJSON
    is_bson = input_file_type == FileSystem.FileTypes.BSON
    is_idf_or_imf = FileSystem.is_idf_type(input_file_type)
    is_ddy = input_file_type == FileSystem.FileTypes.DDY

    if not (is_ep_json or is_idf_or_imf or is_ddy):
        display_message("ERROR: Input file must have IDF, IMF, DDY, or epJSON extension.")
        return False

    if output_type == OutputTypes.EPJSON and (
        input_file_type == FileSystem.FileTypes.EPJSON or input_file_type == FileSystem.FileTypes.JSON
    ):
        display_message("Same output format as input format requested (epJSON). Skipping conversion and moving to next file.")
        return False
    elif output_type == OutputTypes.IDF and (is_idf_or_imf or is_ddy):
        display_message("Same output format as input format requested (IDF). Skipping conversion and moving to next file.")
        return False
    elif output_type == OutputTypes.CBOR and is_cbor:
        display_message("Same output format as input format requested (CBOR). Skipping conversion and moving to next file.")
        return False
    elif output_type == OutputTypes.MSGPACK and is_msgpack:
        display_message("Same output format as input format requested (MsgPack). Skipping conversion and moving to next file.")
        return False
    elif output_type == OutputTypes.UBJSON and is_ubjson:
        display_message("Same output format as input format requested (UBJSON). Skipping conversion and moving to next file.")
        return False
    elif output_type == OutputTypes.BSON and is_bson:
        display_message("Same output format as input format requested (BSON). Skipping conversion and moving to next file.")
        return False

    if not FileSystem.file_exists(input_file_path):
        display_message("Input file path {} not found", input_file_path.as_posix())
        return False

    try:
        if not is_ep_json:
            input_file = FileSystem.read_file(input_file_path)
            success = True
            ep_json = idf_parser.decode(input_file, schema, success)
            clean_epjson(ep_json)
        else:
            ep_json = FileSystem.read_json(input_file_path)
    except Exception as e:
        display_message(str(e))
        display_message("Errors occurred when processing input file. Preceding condition(s) cause termination.")
        return False

    is_valid = validation.validate(ep_json)
    has_errors = process_errors(idf_parser, validation, is_ddy)
    if is_ddy and not has_errors:
        is_valid = True
    version_match = check_version_match(ep_json)
    unsupported_found = check_for_unsupported_objects(ep_json, convert_hvac_template)

    if not is_valid or has_errors or unsupported_found:
        display_message("Errors occurred when validating input file. Preceding condition(s) cause termination.")
        return False

    if is_ep_json and not version_match:
        display_message("Skipping conversion of input file to IDF due to mismatched Version.")
        return False

    output_file_path_with_ori_extension = output_dir_path / FileSystem.get_file_name(input_file_path)

    if (output_type == OutputTypes.DEFAULT or output_type == OutputTypes.IDF) and is_ep_json:
        input_file = idf_parser.encode(ep_json, schema)
        converted_ep_json = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".idf")
        )
        FileSystem.write_file(converted_ep_json, input_file, FileSystem.FileTypes.IDF)
        output_type_str[0] = "IDF"
    elif (output_type == OutputTypes.DEFAULT or output_type == OutputTypes.EPJSON) and not is_ep_json:
        converted_idf = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".epJSON")
        )
        FileSystem.write_file(converted_idf, ep_json, FileSystem.FileTypes.EPJSON)
        output_type_str[0] = "EPJSON"
    elif output_type == OutputTypes.CBOR:
        converted_cbor = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".cbor")
        )
        FileSystem.write_file(converted_cbor, ep_json, FileSystem.FileTypes.CBOR)
    elif output_type == OutputTypes.MSGPACK:
        converted_msgpack = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".msgpack")
        )
        FileSystem.write_file(converted_msgpack, ep_json, FileSystem.FileTypes.MSGPACK)
    elif output_type == OutputTypes.UBJSON:
        converted_ubjson = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".ubjson")
        )
        FileSystem.write_file(converted_ubjson, ep_json, FileSystem.FileTypes.UBJSON)
    elif output_type == OutputTypes.BSON:
        converted_bson = FileSystem.make_native_path(
            FileSystem.replace_file_extension(output_file_path_with_ori_extension, ".bson")
        )
        FileSystem.write_file(converted_bson, ep_json, FileSystem.FileTypes.BSON)
    else:
        return False

    return True


def parse_input_paths(input_file_path: pathlib.Path) -> List[pathlib.Path]:
    try:
        input_paths_stream = open(input_file_path)
    except Exception:
        display_message("Could not open file: {}", input_file_path.as_posix())
        return []

    input_paths: List[pathlib.Path] = []
    for line in input_paths_stream:
        if not line or line.strip() == "":
            continue
        input_file = pathlib.Path(line.rstrip('\n\r'))
        if not input_file.is_file():
            input_file = input_file_path.parent / input_file
            if not input_file.is_file():
                display_message("Input file does not exist: {}", line.rstrip('\n\r'))
                continue
        input_paths.append(input_file)
    input_paths_stream.close()
    return input_paths


def main() -> int:
    app = argparse.ArgumentParser(
        description="Run input file conversion tool",
        prog="ConvertInputFormat",
        epilog="Example: ConvertInputFormat in.idf"
    )
    app.add_argument("-v", "--version", action="version", version=DataStringGlobals.VerString)

    number_of_threads = 1
    try:
        import os
        number_of_threads = os.cpu_count() or 1
    except Exception:
        number_of_threads = 1

    app.add_argument("-j", type=int, default=number_of_threads, metavar="N", help=f"Number of threads [Default: {number_of_threads}]")

    app.add_argument(
        "-i", "--input",
        type=pathlib.Path,
        metavar="LSTFILE",
        help="Text file with list of input files to convert (newline delimited)"
    )

    app.add_argument(
        "-o", "--output",
        type=pathlib.Path,
        metavar="DIR",
        help="Output directory. Will use input file location by default"
    )

    output_type_map = {
        "default": OutputTypes.DEFAULT,
        "idf": OutputTypes.IDF,
        "epjson": OutputTypes.EPJSON,
        "cbor": OutputTypes.CBOR,
        "msgpack": OutputTypes.MSGPACK,
        "ubjson": OutputTypes.UBJSON,
        "bson": OutputTypes.BSON,
    }

    help_message = f"""Output format.
Default means IDF->epJSON or epJSON->IDF
Select one (case insensitive):
[{','.join(OUTPUT_TYPE_STRS)}]"""

    app.add_argument(
        "-f", "--format",
        type=str,
        default="default",
        metavar="FORMAT",
        help=help_message
    )

    app.add_argument(
        "-n", "--noHVACTemplate",
        action="store_true",
        help="Do not convert HVACTemplate objects"
    )

    app.add_argument(
        "input_file",
        nargs="*",
        help="Multiple input files to be translated"
    )

    args = app.parse_args()

    convert_hvac_template = not args.noHVACTemplate

    output_type = output_type_map.get(args.format.lower(), OutputTypes.DEFAULT)

    output_directory_path = args.output if args.output else pathlib.Path()

    if output_directory_path and str(output_directory_path).strip():
        FileSystem.make_directory(output_directory_path)

    files: List[pathlib.Path] = []
    if args.input:
        list_files = parse_input_paths(args.input)
        files.extend(list_files)

    if args.input_file:
        files.extend(pathlib.Path(f) for f in args.input_file)

    output_type_str = [OUTPUT_TYPE_STRS[output_type]]
    if output_type >= OUTPUT_TYPE_EXPERIMENTAL_START:
        display_message("{} input format is experimental.", output_type_str[0])

    if not files:
        display_message("No valid files found. Either specify --input or pass files as extra arguments")
        return 1

    files.sort()
    files = list(dict.fromkeys(files))

    embedded_ep_json_schema = EmbeddedEpJSONSchema.embedded_ep_json_schema()
    schema = json.loads(embedded_ep_json_schema)

    number_files = len(files)
    file_count = [0]

    for file in files:
        successful = process_input(file, schema, output_type, output_directory_path, output_type_str, convert_hvac_template)
        file_count[0] += 1
        if successful:
            display_message(
                "Input file converted to {} successfully | {}/{} | {}",
                output_type_str[0],
                file_count[0],
                number_files,
                file.as_posix()
            )
        else:
            display_message(
                "Input file conversion failed: | {}/{} | {}",
                file_count[0],
                number_files,
                file.as_posix()
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
