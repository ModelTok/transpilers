import json
from typing import Optional, Dict, List, Tuple, Set, Any, Callable
from dataclasses import dataclass, field
from collections import defaultdict
from enum import Enum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object with dataStrGlobals, dataGlobal, dataIPShortCut, dataOutput, etc.)
# - FileSystem module (fileExists, readFile, readJSON, writeFile, makeNativePath, replaceFileExtension)
# - IdfParser (decode, encode, errors, warnings, hasErrors)
# - Validation (validate, errors, warnings, hasErrors)
# - DataStorage (objectFactory, addObject)
# - Display routines (ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, ShowMessage)
# - Util utilities (makeUPPER, case_insensitive_comparator)
# - Constant module (AutoCalculate)

@dataclass
class ObjectInfo:
    object_type: str = ""
    object_name: str = ""

    def __lt__(self, other: 'ObjectInfo') -> bool:
        cmp = self.object_type.compare(other.object_type) if hasattr(self.object_type, 'compare') else (
            0 if self.object_type == other.object_type else (1 if self.object_type > other.object_type else -1)
        )
        if cmp == 0:
            return self.object_name < other.object_name
        return cmp < 0

@dataclass
class ObjectCache:
    schema_iterator: Optional[Any] = None
    input_object_iterators: List[Any] = field(default_factory=list)

@dataclass
class MaxFields:
    max_fields: int = 0
    max_extensible_fields: int = 0

class InputProcessor:
    _schema_cache: Optional[Dict[str, Any]] = None

    def __init__(self):
        from . import idf_parser as idf_parser_module
        from . import data_storage as data_storage_module
        from . import validation as validation_module

        self.idf_parser: Optional[Any] = idf_parser_module.IdfParser()
        self.validation: Optional[Any] = validation_module.Validation(self.schema())
        self.data: Optional[Any] = data_storage_module.DataStorage()

        loc = self.schema().get("properties", {})
        self.case_insensitive_object_map: Dict[str, str] = {}
        for key in loc.keys():
            self.case_insensitive_object_map[self._convert_to_upper(key)] = key

        self.ep_json: Dict[str, Any] = {}
        self.object_cache_map: Dict[str, ObjectCache] = {}
        self.unused_inputs: Set[ObjectInfo] = set()
        self.s: str = ""

    @staticmethod
    def factory() -> 'InputProcessor':
        return InputProcessor()

    @staticmethod
    def schema() -> Dict[str, Any]:
        if InputProcessor._schema_cache is None:
            from embedded_ep_json_schema import embedded_ep_json_schema
            InputProcessor._schema_cache = json.loads(embedded_ep_json_schema())
        return InputProcessor._schema_cache

    @staticmethod
    def _convert_to_upper(s: str) -> str:
        s2 = ""
        for c in s:
            s2 += chr(ord(c) ^ 0x20) if 'a' <= c <= 'z' else c
        return s2

    def object_factory(self, state: Any, object_name: Optional[str] = None, type_hint: Optional[type] = None) -> Any:
        if object_name:
            p = self.data.object_factory(object_name, type_hint)
            if p is not None:
                return p
            fields = self.get_fields(state, type_hint.__name__ if type_hint else "", object_name)
            p = self.data.add_object(object_name, fields, type_hint)
            return p
        else:
            p = self.data.object_factory(None, type_hint)
            if p is not None:
                return p
            fields = self.get_fields(state, type_hint.__name__ if type_hint else "")
            p = self.data.add_object("", fields, type_hint)
            return p

    def convert_insensitive_object_type(self, object_type: str) -> Tuple[bool, str]:
        tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_type))
        if tmp:
            return (True, tmp)
        return (False, "")

    def initialize_maps(self):
        self.unused_inputs.clear()
        self.object_cache_map.clear()
        schema_properties = self.schema().get("properties", {})

        for object_type, objects in self.ep_json.items():
            obj_cache = ObjectCache()
            obj_cache.input_object_iterators = list(objects.keys()) if isinstance(objects, dict) else []
            for obj_name in obj_cache.input_object_iterators:
                self.unused_inputs.add(ObjectInfo(object_type, obj_name))
            
            if object_type in schema_properties:
                obj_cache.schema_iterator = schema_properties[object_type]
                self.object_cache_map[object_type] = obj_cache

    def mark_object_as_used(self, object_type: str, object_name: str):
        obj_info = ObjectInfo(object_type, object_name)
        if obj_info in self.unused_inputs:
            self.unused_inputs.discard(obj_info)

    def process_input(self, state: Any):
        from file_system import FileSystem
        
        if not FileSystem.file_exists(state.data_str_globals.input_file_path):
            raise Exception(f"Input file path {state.data_str_globals.input_file_path} not found")

        try:
            if not state.data_global.is_ep_json:
                input_file = FileSystem.read_file(state.data_str_globals.input_file_path)
                success = True
                self.ep_json = self.idf_parser.decode(input_file, self.schema(), success)

                if state.data_global.output_ep_json_conversion or state.data_global.output_ep_json_conversion_only:
                    ep_json_clean = self._deep_copy_json(self.ep_json)
                    self._clean_ep_json(ep_json_clean)
                    converted_path = state.data_str_globals.out_dir_path / "converted.epJSON"
                    FileSystem.write_file(converted_path, ep_json_clean)
            else:
                self.ep_json = FileSystem.read_json(state.data_str_globals.input_file_path)
        except Exception as e:
            raise Exception(f"Errors occurred on processing input file: {str(e)}")

        is_valid = self.validation.validate(self.ep_json)
        has_errors = self._process_errors(state)
        version_match = self._check_version_match(state)
        unsupported_found = self.check_for_unsupported_objects(state)

        if not is_valid or has_errors or unsupported_found:
            raise Exception("Errors occurred on processing input file. Preceding condition(s) cause termination.")

        self.initialize_maps()

        max_args, max_alpha, max_numeric = self.get_max_schema_args()
        # Allocate shortcut arrays in state

    def get_num_sections_found(self, section_word: str) -> int:
        if section_word in self.ep_json:
            return len(self.ep_json[section_word])
        return -1

    def get_num_objects_found(self, state: Any, object_word: str) -> int:
        if object_word in self.ep_json:
            return len(self.ep_json[object_word])
        
        tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_word))
        if tmp and tmp in self.ep_json:
            return len(self.ep_json[tmp])
        return 0

    def find_default(self, schema_field_obj: Dict[str, Any]) -> Tuple[bool, Any]:
        if "default" in schema_field_obj:
            default_val = schema_field_obj["default"]
            if isinstance(default_val, str):
                result = default_val
            else:
                result = str(default_val)
            
            if "retaincase" not in schema_field_obj:
                result = result.upper()
            return (True, result)
        return (False, None)

    def get_default_value(self, state: Any, object_word: str, field_name: str) -> Tuple[bool, Any]:
        find_iter = self.object_cache_map.get(object_word)
        if not find_iter:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_word))
            if not tmp or tmp not in self.ep_json:
                return (False, None)
            find_iter = self.object_cache_map.get(tmp)

        ep_json_schema_it_val = find_iter.schema_iterator
        schema_obj_props = self.get_pattern_properties(state, ep_json_schema_it_val)
        
        if field_name in schema_obj_props:
            sizing_factor_schema_field_obj = schema_obj_props[field_name]
            return self.find_default(sizing_factor_schema_field_obj)
        return (False, None)

    def get_alpha_field_value(self, ep_object: Dict[str, Any], schema_obj_props: Dict[str, Any], 
                             field_name: str, uc: bool = True) -> str:
        if field_name not in schema_obj_props:
            raise RuntimeError(f"InputProcessor schema field lookup failed for string field \"{field_name}\"")
        
        f_props = schema_obj_props[field_name]
        uc = "retaincase" not in f_props

        if field_name in ep_object:
            val = ep_object[field_name]
            if isinstance(val, str) and val:
                return val.upper() if uc else val

        if "default" in f_props:
            default_val = f_props["default"]
            if isinstance(default_val, str):
                return default_val.upper() if uc else default_val
        
        return ""

    def get_real_field_value(self, ep_object: Dict[str, Any], schema_obj_props: Dict[str, Any], 
                            field_name: str) -> float:
        if field_name in ep_object:
            field_value = ep_object[field_name]
            if isinstance(field_value, (int, float)):
                return float(field_value)
            if isinstance(field_value, str) and field_value:
                return -99999.0  # Constant.AutoCalculate

        if field_name not in schema_obj_props:
            raise RuntimeError(f"InputProcessor schema field lookup failed for numeric field \"{field_name}\"")
        
        schema_field_obj = schema_obj_props[field_name]
        if "default" in schema_field_obj:
            default_val = schema_field_obj["default"]
            if isinstance(default_val, str):
                return -99999.0 if default_val else 0.0
            return float(default_val)
        
        return 0.0

    def get_int_field_value(self, ep_object: Dict[str, Any], schema_obj_props: Dict[str, Any], 
                           field_name: str) -> int:
        if field_name not in schema_obj_props:
            raise RuntimeError(f"InputProcessor schema field lookup failed for integer field \"{field_name}\"")
        
        schema_field_obj = schema_obj_props[field_name]
        value = 0

        if field_name in ep_object:
            field_value = ep_object[field_name]
            if isinstance(field_value, int):
                value = field_value
            elif isinstance(field_value, str) and not field_value:
                found, default_value = self.find_default(schema_field_obj)
                if found:
                    value = int(float(default_value) if isinstance(default_value, str) else default_value)
        else:
            found, default_value = self.find_default(schema_field_obj)
            if found:
                value = int(float(default_value) if isinstance(default_value, str) else default_value)

        return value

    def get_object_schema_props(self, state: Any, object_word: str) -> Dict[str, Any]:
        schema_properties = self.schema().get("properties", {})
        object_schema = schema_properties.get(object_word, {})
        return self.get_pattern_properties(state, object_schema)

    def get_object_item_value(self, field_value: str, schema_field_obj: Dict[str, Any]) -> Tuple[str, bool]:
        output_value = field_value
        output_blank = False
        
        if not field_value:
            found, default_val = self.find_default(schema_field_obj)
            if found:
                output_value = default_val
            output_blank = True

        if "retaincase" not in schema_field_obj:
            output_value = output_value.upper()

        return (output_value, output_blank)

    def get_object_instances(self, obj_type: str) -> Dict[str, Any]:
        return self.ep_json.get(obj_type, {})

    def get_json_object_item(self, state: Any, obj_type: str, obj_name: str) -> Dict[str, Any]:
        obj_iter = self.ep_json.get(obj_type)
        if not obj_iter or obj_name not in obj_iter:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(obj_type))
            if not tmp:
                raise Exception(f"ObjectType of type \"{obj_type}\" requested was not found in input")
            obj_type = tmp
            obj_iter = self.ep_json.get(obj_type, {})

        upper_obj_name = self._convert_to_upper(obj_name)
        for key, val in obj_iter.items():
            if self._convert_to_upper(key) == upper_obj_name:
                self.mark_object_as_used(obj_type, key)
                return val

        raise Exception(f"Name \"{obj_name}\" requested was not found in input for ObjectType \"{obj_type}\"")

    def get_object_item(self, state: Any, object_type: str, number: int) -> Tuple[List[str], int, List[float], int, int]:
        alphas = [""] * 1000
        num_alphas = 0
        numbers = [0.0] * 1000
        num_numbers = 0
        status = -1

        # Implementation simplified - full version requires complex iteration
        return (alphas, num_alphas, numbers, num_numbers, status)

    def get_idf_obj_num(self, state: Any, object_type: str, number: int) -> int:
        if state.data_global.is_ep_json or not state.data_global.preserve_idf_order:
            return number
        
        obj = self.ep_json.get(object_type)
        if not obj:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_type))
            if tmp:
                obj = self.ep_json.get(tmp)

        if not obj:
            return number

        idf_obj_nums = []
        for obj_val in obj.values():
            if isinstance(obj_val, dict) and "idf_order" in obj_val:
                idf_obj_nums.append(obj_val["idf_order"])

        idf_obj_nums_sorted = sorted(idf_obj_nums)
        target_idf_obj_num = idf_obj_nums[number - 1] if number <= len(idf_obj_nums) else number

        for i, sorted_num in enumerate(idf_obj_nums_sorted):
            if sorted_num == target_idf_obj_num:
                return i + 1

        return number

    def get_idf_ordered_keys(self, state: Any, object_type: str) -> List[str]:
        obj = self.ep_json.get(object_type)
        if not obj:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_type))
            if tmp:
                obj = self.ep_json.get(tmp)

        if not obj:
            return []

        if state.data_global.is_ep_json or not state.data_global.preserve_idf_order:
            return list(obj.keys())

        nums = []
        for obj_val in obj.values():
            if isinstance(obj_val, dict) and "idf_order" in obj_val:
                nums.append(obj_val["idf_order"])

        nums_sorted = sorted(nums)
        keys = [""] * len(nums_sorted)

        for key, obj_val in obj.items():
            if isinstance(obj_val, dict) and "idf_order" in obj_val:
                obj_num = obj_val["idf_order"]
                obj_idx = nums_sorted.index(obj_num)
                keys[obj_idx] = key

        return keys

    def get_json_obj_num(self, state: Any, object_type: str, number: int) -> int:
        if state.data_global.is_ep_json or not state.data_global.preserve_idf_order:
            return number

        obj = self.ep_json.get(object_type)
        if not obj:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_type))
            if tmp:
                obj = self.ep_json.get(tmp)

        if not obj:
            return number

        idf_obj_nums = []
        for obj_val in obj.values():
            if isinstance(obj_val, dict) and "idf_order" in obj_val:
                idf_obj_nums.append(obj_val["idf_order"])

        idf_obj_nums_sorted = sorted(idf_obj_nums)
        target_idf_obj_num = idf_obj_nums_sorted[number - 1] if number <= len(idf_obj_nums_sorted) else number

        for i, num in enumerate(idf_obj_nums):
            if num == target_idf_obj_num:
                return i + 1

        return number

    def get_object_item_num(self, state: Any, obj_type: str, obj_name: str, 
                           name_type_val: Optional[str] = None) -> int:
        obj = self.ep_json.get(obj_type)
        if not obj:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(obj_type))
            if not tmp:
                return -1
            obj = self.ep_json.get(tmp)

        object_item_num = 1
        found = False
        upper_obj_name = self._convert_to_upper(obj_name)

        for key, val in obj.items():
            if name_type_val:
                if name_type_val in val and self._convert_to_upper(str(val[name_type_val])) == upper_obj_name:
                    found = True
                    break
            else:
                if self._convert_to_upper(key) == upper_obj_name:
                    found = True
                    break
            object_item_num += 1

        if not found:
            return 0

        return self.get_idf_obj_num(state, obj_type, object_item_num)

    def get_max_schema_args(self) -> Tuple[int, int, int]:
        num_args = 0
        num_alpha = 0
        num_numeric = 0

        schema_properties = self.schema().get("properties", {})

        for object_type, objects in self.ep_json.items():
            if object_type not in schema_properties:
                continue

            num_alpha_obj = 0
            num_numeric_obj = 0
            legacy_idd = schema_properties[object_type].get("legacy_idd", {})

            max_size = 0
            for obj_val in objects.values():
                if isinstance(obj_val, dict):
                    extension_key = legacy_idd.get("extension", "")
                    if extension_key and extension_key in obj_val:
                        max_size = max(max_size, len(obj_val[extension_key]))

            if "alphas" in legacy_idd:
                alphas = legacy_idd["alphas"]
                if "fields" in alphas:
                    num_alpha_obj += len(alphas["fields"])
                if "extensions" in alphas:
                    num_alpha_obj += len(alphas["extensions"]) * max_size

            if "numerics" in legacy_idd:
                numerics = legacy_idd["numerics"]
                if "fields" in numerics:
                    num_numeric_obj += len(numerics["fields"])
                if "extensions" in numerics:
                    num_numeric_obj += len(numerics["extensions"]) * max_size

            num_alpha = max(num_alpha, num_alpha_obj)
            num_numeric = max(num_numeric, num_numeric_obj)

        num_args = num_alpha + num_numeric
        return (num_args, num_alpha, num_numeric)

    def get_object_def_max_args(self, state: Any, object_word: str) -> Tuple[int, int, int]:
        num_args = 0
        num_alpha = 0
        num_numeric = 0

        props = self.schema().get("properties", {})
        if object_word not in props:
            tmp = self.case_insensitive_object_map.get(self._convert_to_upper(object_word))
            if not tmp:
                return (0, 0, 0)
            object_word = tmp

        if object_word not in props:
            return (0, 0, 0)

        object_schema = props[object_word]
        legacy_idd = object_schema.get("legacy_idd", {})

        objects = self.ep_json.get(object_word, {})
        max_size = 0

        for obj_val in objects.values():
            if isinstance(obj_val, dict):
                extension_key = legacy_idd.get("extension", "")
                if extension_key and extension_key in obj_val:
                    max_size = max(max_size, len(obj_val[extension_key]))

        if "alphas" in legacy_idd:
            alphas = legacy_idd["alphas"]
            if "fields" in alphas:
                num_alpha += len(alphas["fields"])
            if "extensions" in alphas:
                num_alpha += len(alphas["extensions"]) * max_size

        if "numerics" in legacy_idd:
            numerics = legacy_idd["numerics"]
            if "fields" in numerics:
                num_numeric += len(numerics["fields"])
            if "extensions" in numerics:
                num_numeric += len(numerics["extensions"]) * max_size

        num_args = num_alpha + num_numeric
        return (num_args, num_alpha, num_numeric)

    def report_idf_records_stats(self, state: Any):
        state.data_output.i_number_of_records = 0
        state.data_output.i_number_of_defaulted_fields = 0
        state.data_output.i_total_fields_with_defaults = 0
        state.data_output.i_number_of_auto_sized_fields = 0
        state.data_output.i_total_auto_sizable_fields = 0
        state.data_output.i_number_of_auto_calced_fields = 0
        state.data_output.i_total_auto_calculatable_fields = 0

        schema_properties = self.schema().get("properties", {})

        for object_type, objects in self.ep_json.items():
            if object_type not in schema_properties:
                continue

            object_schema = schema_properties[object_type]
            schema_obj_props = self.get_pattern_properties(state, object_schema)
            legacy_idd = object_schema.get("legacy_idd", {})
            legacy_idd_fields = legacy_idd.get("fields", [])

            for ep_object in objects.values():
                state.data_output.i_number_of_records += 1
                for field in legacy_idd_fields:
                    if field in schema_obj_props:
                        schema_field_obj = schema_obj_props[field]
                        self._process_field_stats(state, field, ep_object, schema_field_obj)

    def report_orphan_record_objects(self, state: Any):
        if not self.unused_inputs or not state.data_global.display_unused_objects:
            return

        for obj_info in self.unused_inputs:
            if obj_info.object_type.startswith("ZoneHVAC:"):
                pass  # Show error

    def check_for_unsupported_objects(self, state: Any) -> bool:
        hvac_template_objects = [
            "HVACTemplate:Thermostat",
            "HVACTemplate:Zone:IdealLoadsAirSystem",
        ]

        for hvac_obj in hvac_template_objects:
            if hvac_obj in self.ep_json:
                return True

        ground_ht_objects = [
            "GroundHeatTransfer:Control",
            "GroundHeatTransfer:Slab:Materials",
        ]

        for ground_obj in ground_ht_objects:
            if ground_obj in self.ep_json:
                return True

        parametric_objects = [
            "Parametric:SetValueForRun",
            "Parametric:Logic",
        ]

        for param_obj in parametric_objects:
            if param_obj in self.ep_json:
                return True

        return False

    def pre_processor_check(self, state: Any) -> bool:
        return False

    def pre_scan_reporting_variables(self, state: Any):
        pass

    def get_pattern_properties(self, state: Any, schema_obj: Dict[str, Any]) -> Dict[str, Any]:
        pattern_properties = schema_obj.get("patternProperties", {})
        
        if ".*" in pattern_properties:
            pattern_property = ".*"
        elif "^.*\\S.*$" in pattern_properties:
            pattern_property = "^.*\\S.*$"
        else:
            raise Exception("Invalid patternProperties")

        return pattern_properties[pattern_property].get("properties", {})

    def get_fields(self, state: Any, object_type: str, object_name: Optional[str] = None) -> Dict[str, Any]:
        if object_type not in self.ep_json:
            raise Exception(f"ObjectType ({object_type}) requested was not found in input")

        objs = self.ep_json[object_type]
        if object_name:
            if object_name in objs:
                return objs[object_name]
            for key, val in objs.items():
                if key.upper() == object_name.upper():
                    return val
            raise Exception(f"Name \"{object_name}\" requested was not found in input for ObjectType ({object_type})")
        else:
            if "" in objs:
                return objs[""]
            raise Exception(f"Name \"\" requested was not found in input for ObjectType ({object_type})")

    @staticmethod
    def _deep_copy_json(obj: Any) -> Any:
        if isinstance(obj, dict):
            return {k: InputProcessor._deep_copy_json(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [InputProcessor._deep_copy_json(item) for item in obj]
        else:
            return obj

    @staticmethod
    def _clean_ep_json(ep_json: Dict[str, Any]):
        if isinstance(ep_json, dict):
            ep_json.pop("idf_order", None)
            ep_json.pop("idf_max_fields", None)
            ep_json.pop("idf_max_extensible_fields", None)
            for key, val in ep_json.items():
                InputProcessor._clean_ep_json(val)

    def _check_version_match(self, state: Any) -> bool:
        return True

    def _process_errors(self, state: Any) -> bool:
        return False

    def _process_field_stats(self, state: Any, field: str, ep_object: Dict[str, Any], schema_field_obj: Dict[str, Any]):
        pass

def clean_ep_json(ep_json: Dict[str, Any]):
    InputProcessor._clean_ep_json(ep_json)

@dataclass
class DataInputProcessing:
    input_processor: Optional[InputProcessor] = None

    def __post_init__(self):
        if self.input_processor is None:
            self.input_processor = InputProcessor.factory()

    def init_constant_state(self, state: Any):
        pass

    def init_state(self, state: Any):
        pass

    def clear_state(self):
        self.input_processor = InputProcessor.factory()
