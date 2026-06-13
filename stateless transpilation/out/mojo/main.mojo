# EXTERNAL DEPS (to wire in glue):
# - EnergyPlus.DataStringGlobals.MatchVersion (str)
# - EnergyPlus.DataStringGlobals.VerString (str)
# - EnergyPlus.FileSystem (module: file_exists, readFile, readJSON, writeFile, getFileType, is_all_json_type, is_idf_type, makeDirectory, makeNativePath, replaceFileExtension, getParentDirectoryPath, getFileName, FileTypes enum)
# - IdfParser (class: decode, encode, errors, warnings, hasErrors)
# - Validation (class: validate, errors, warnings)
# - EnergyPlus.EmbeddedEpJSONSchema.embeddedEpJSONSchema (function returning CBOR bytes)

from collections import InlineArray
from pathlib import Path


@export
fn enum_output_types() -> Int:
    alias DEFAULT = 0
    alias IDF = 1
    alias EPJSON = 2
    alias CBOR = 3
    alias MSGPACK = 4
    alias UBJSON = 5
    alias BSON = 6
    alias NUM = 7
    return NUM


struct OutputTypes:
    var value: Int

    fn __init__(inout self, val: Int) -> None:
        self.value = val


var OUTPUT_TYPE_STRS = InlineArray[String, 7](
    "default", "IDF", "epJSON", "CBOR", "MsgPack", "UBJSON", "BSON"
)


fn display_message(str_format: String, *args: String) -> None:
    if args.__len__() > 0:
        print(str_format, args)
    else:
        print(str_format)


fn check_version_match(ep_json: String) -> Bool:
    return True


fn check_for_unsupported_objects(ep_json: String, convert_hvac_template: Bool) -> Bool:
    var errors_found = False
    var hvac_template_objects = InlineArray[String, 32](
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

    if not convert_hvac_template:
        var object_found = False
        for count in range(hvac_template_objects.__len__()):
            var object_type = hvac_template_objects[count]
            if object_type in ep_json:
                object_found = True
                break
        if object_found:
            display_message("HVACTemplate:* objects found. These objects are not supported directly by EnergyPlus.")
            display_message("You must run the ExpandObjects program on this input.")
            errors_found = True

    var ground_ht_objects = InlineArray[String, 26](
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

    object_found = False
    for count in range(ground_ht_objects.__len__()):
        var object_type = ground_ht_objects[count]
        if object_type in ep_json:
            object_found = True
            break
    if object_found:
        display_message("GroundHeatTransfer:* objects found. These objects are not supported directly by EnergyPlus.")
        display_message("You must run the ExpandObjects program on this input.")
        errors_found = True

    var parametric_objects = InlineArray[String, 4](
        "Parametric:SetValueForRun", "Parametric:Logic", "Parametric:RunControl", "Parametric:FileNameSuffix"
    )

    object_found = False
    for count in range(parametric_objects.__len__()):
        var object_type = parametric_objects[count]
        if object_type in ep_json:
            object_found = True
            break
    if object_found:
        display_message("Parametric:* objects found. These objects are not supported directly by EnergyPlus.")
        display_message("You must run the ParametricPreprocesor program on this input.")
        errors_found = True

    return errors_found


fn process_errors(idf_parser: String, validation: String, is_ddy: Bool) -> Bool:
    return False


fn clean_epjson(inout epjson: String) -> None:
    pass


fn process_input(
    input_file_path: String,
    schema: String,
    output_type: Int,
    output_dir_path: String,
    inout output_type_str: String,
    convert_hvac_template: Bool,
) -> Bool:
    return True


fn parse_input_paths(input_file_path: String) -> List[String]:
    var input_paths = List[String]()
    return input_paths


@export
fn main() -> Int:
    return 0
