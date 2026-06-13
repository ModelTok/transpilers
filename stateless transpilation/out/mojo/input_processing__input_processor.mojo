from collections import Dict, Set, List
from memory.unsafe import Pointer
import json

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state object)
# - FileSystem module
# - IdfParser 
# - Validation
# - DataStorage
# - Display routines
# - Util utilities
# - Constant module

@value
struct ObjectInfo:
    var object_type: String
    var object_name: String

    fn __init__(inout self, object_type: String = "", object_name: String = ""):
        self.object_type = object_type
        self.object_name = object_name

    fn __lt__(self, other: ObjectInfo) -> Bool:
        if self.object_type < other.object_type:
            return True
        elif self.object_type == other.object_type:
            return self.object_name < other.object_name
        return False

@value
struct ObjectCache:
    var schema_iterator: Int
    var input_object_iterators: List[Int]

    fn __init__(inout self, schema_iterator: Int = 0):
        self.schema_iterator = schema_iterator
        self.input_object_iterators = List[Int]()

@value
struct MaxFields:
    var max_fields: UInt
    var max_extensible_fields: UInt

    fn __init__(inout self):
        self.max_fields = 0
        self.max_extensible_fields = 0

struct InputProcessor:
    var idf_parser: Pointer[UInt8]
    var validation: Pointer[UInt8]
    var data: Pointer[UInt8]
    var ep_json: Dict[String, Dict[String, UInt8]]
    var case_insensitive_object_map: Dict[String, String]
    var object_cache_map: Dict[String, ObjectCache]
    var unused_inputs: Set[ObjectInfo]
    var s: String

    fn __init__(inout self):
        self.idf_parser = Pointer[UInt8]()
        self.validation = Pointer[UInt8]()
        self.data = Pointer[UInt8]()
        self.ep_json = Dict[String, Dict[String, UInt8]]()
        self.case_insensitive_object_map = Dict[String, String]()
        self.object_cache_map = Dict[String, ObjectCache]()
        self.unused_inputs = Set[ObjectInfo]()
        self.s = ""

        let schema = Self.schema()
        let loc = schema.get("properties")
        for key in loc.keys():
            self.case_insensitive_object_map[Self.convert_to_upper(key)] = key

    @staticmethod
    fn factory() -> InputProcessor:
        var processor = InputProcessor()
        return processor

    @staticmethod
    fn schema() -> Dict[String, UInt8]:
        var empty_dict = Dict[String, UInt8]()
        return empty_dict

    @staticmethod
    fn convert_to_upper(s: String) -> String:
        var s2 = String()
        for c in s:
            if c >= 'a' and c <= 'z':
                s2.append(chr(ord(c) ^ 0x20))
            else:
                s2.append(c)
        return s2

    fn convert_insensitive_object_type(inout self, object_type: String) -> (Bool, String):
        let upper = Self.convert_to_upper(object_type)
        if let val = self.case_insensitive_object_map.get(upper):
            return (True, val)
        return (False, "")

    fn initialize_maps(inout self):
        self.unused_inputs = Set[ObjectInfo]()
        self.object_cache_map = Dict[String, ObjectCache]()

        for item in self.ep_json.items():
            let object_type = item.key
            let objects = item.value
            
            var obj_cache = ObjectCache(schema_iterator: 0)
            var input_iters = List[Int]()
            
            for obj_name in objects.keys():
                input_iters.append(0)
                var obj_info = ObjectInfo(object_type: object_type, object_name: obj_name)
                self.unused_inputs.add(obj_info)
            
            obj_cache.input_object_iterators = input_iters
            self.object_cache_map[object_type] = obj_cache

    fn mark_object_as_used(inout self, object_type: String, object_name: String):
        var obj_info = ObjectInfo(object_type: object_type, object_name: object_name)
        if self.unused_inputs.contains(obj_info):
            self.unused_inputs.discard(obj_info)

    fn process_input(inout self, state: Pointer[UInt8]):
        pass

    fn get_num_sections_found(self, section_word: String) -> Int:
        if let sect = self.ep_json.get(section_word):
            return sect.size()
        return -1

    fn get_num_objects_found(inout self, state: Pointer[UInt8], object_word: String) -> Int:
        if let objs = self.ep_json.get(object_word):
            return objs.size()
        
        let upper = Self.convert_to_upper(object_word)
        if let val = self.case_insensitive_object_map.get(upper):
            if let objs = self.ep_json.get(val):
                return objs.size()
        return 0

    fn find_default(self, schema_field_obj: Dict[String, UInt8]) -> (Bool, String):
        if let default_val = schema_field_obj.get("default"):
            var result = String(default_val)
            if schema_field_obj.get("retaincase") == None:
                result = Self.convert_to_upper(result)
            return (True, result)
        return (False, "")

    fn get_default_value(inout self, state: Pointer[UInt8], object_word: String, field_name: String) -> (Bool, String):
        var find_iter = self.object_cache_map.get(object_word)
        if find_iter == None:
            let upper = Self.convert_to_upper(object_word)
            if let val = self.case_insensitive_object_map.get(upper):
                find_iter = self.object_cache_map.get(val)

        if find_iter == None:
            return (False, "")

        let cached = find_iter.value()
        let schema_obj_props = self.get_pattern_properties(state, Dict[String, UInt8]())
        
        if let sizing_factor_schema_field_obj = schema_obj_props.get(field_name):
            return self.find_default(sizing_factor_schema_field_obj)
        
        return (False, "")

    fn get_alpha_field_value(self, ep_object: Dict[String, UInt8], schema_obj_props: Dict[String, UInt8], 
                            field_name: String, uc: Bool = True) -> String:
        if schema_obj_props.get(field_name) == None:
            var msg = String("InputProcessor schema field lookup failed for string field \"")
            msg.append(field_name)
            msg.append("\"")
            _ = msg
        
        if let val = ep_object.get(field_name):
            var str_val = String(val)
            if str_val.size() > 0:
                if uc:
                    return Self.convert_to_upper(str_val)
                return str_val

        if let default_val = schema_obj_props.get("default"):
            var str_default = String(default_val)
            if uc:
                return Self.convert_to_upper(str_default)
            return str_default

        return ""

    fn get_real_field_value(self, ep_object: Dict[String, UInt8], schema_obj_props: Dict[String, UInt8], 
                           field_name: String) -> Float64:
        if let field_value = ep_object.get(field_name):
            return Float64(field_value)

        if schema_obj_props.get(field_name) == None:
            var msg = String("InputProcessor schema field lookup failed for numeric field \"")
            msg.append(field_name)
            msg.append("\"")
            _ = msg

        if let default_val = schema_obj_props.get("default"):
            return Float64(default_val)

        return 0.0

    fn get_int_field_value(self, ep_object: Dict[String, UInt8], schema_obj_props: Dict[String, UInt8], 
                          field_name: String) -> Int:
        if schema_obj_props.get(field_name) == None:
            var msg = String("InputProcessor schema field lookup failed for integer field \"")
            msg.append(field_name)
            msg.append("\"")
            _ = msg

        var value: Int = 0

        if let field_value = ep_object.get(field_name):
            value = Int(field_value)

        return value

    fn get_object_schema_props(inout self, state: Pointer[UInt8], object_word: String) -> Dict[String, UInt8]:
        let schema = Self.schema()
        if let props = schema.get("properties"):
            if let object_schema = props.get(object_word):
                return self.get_pattern_properties(state, object_schema)
        return Dict[String, UInt8]()

    fn get_object_item_value(self, field_value: String, schema_field_obj: Dict[String, UInt8]) -> (String, Bool):
        var output_value = field_value
        var output_blank: Bool = False

        if field_value.size() == 0:
            let (found, default_val) = self.find_default(schema_field_obj)
            if found:
                output_value = default_val
            output_blank = True

        if schema_field_obj.get("retaincase") == None:
            output_value = Self.convert_to_upper(output_value)

        return (output_value, output_blank)

    fn get_object_instances(self, obj_type: String) -> Dict[String, UInt8]:
        if let instances = self.ep_json.get(obj_type):
            return instances
        return Dict[String, UInt8]()

    fn get_json_object_item(inout self, state: Pointer[UInt8], obj_type: String, obj_name: String) -> Dict[String, UInt8]:
        var obj_type_mut = obj_type
        
        if self.ep_json.get(obj_type_mut) == None:
            let upper = Self.convert_to_upper(obj_type)
            if let val = self.case_insensitive_object_map.get(upper):
                obj_type_mut = val

        if let obj_iter = self.ep_json.get(obj_type_mut):
            let upper_obj_name = Self.convert_to_upper(obj_name)
            for item in obj_iter.items():
                if Self.convert_to_upper(item.key) == upper_obj_name:
                    return item.value

        return Dict[String, UInt8]()

    fn get_idf_obj_num(inout self, state: Pointer[UInt8], object_type: String, number: Int) -> Int:
        return number

    fn get_idf_ordered_keys(inout self, state: Pointer[UInt8], object_type: String) -> List[String]:
        var keys = List[String]()
        return keys

    fn get_json_obj_num(inout self, state: Pointer[UInt8], object_type: String, number: Int) -> Int:
        return number

    fn get_object_item_num(inout self, state: Pointer[UInt8], obj_type: String, obj_name: String) -> Int:
        return 0

    fn get_max_schema_args(inout self) -> (Int, Int, Int):
        var num_args: Int = 0
        var num_alpha: Int = 0
        var num_numeric: Int = 0
        return (num_args, num_alpha, num_numeric)

    fn get_object_def_max_args(inout self, state: Pointer[UInt8], object_word: String) -> (Int, Int, Int):
        var num_args: Int = 0
        var num_alpha: Int = 0
        var num_numeric: Int = 0
        return (num_args, num_alpha, num_numeric)

    fn report_idf_records_stats(inout self, state: Pointer[UInt8]):
        pass

    fn report_orphan_record_objects(inout self, state: Pointer[UInt8]):
        pass

    fn check_for_unsupported_objects(inout self, state: Pointer[UInt8]) -> Bool:
        return False

    fn pre_processor_check(inout self, state: Pointer[UInt8]) -> Bool:
        return False

    fn pre_scan_reporting_variables(inout self, state: Pointer[UInt8]):
        pass

    fn get_pattern_properties(inout self, state: Pointer[UInt8], schema_obj: Dict[String, UInt8]) -> Dict[String, UInt8]:
        return Dict[String, UInt8]()

    fn get_fields(inout self, state: Pointer[UInt8], object_type: String, object_name: String = "") -> Dict[String, UInt8]:
        if let objs = self.ep_json.get(object_type):
            if object_name.size() > 0:
                if let obj = objs.get(object_name):
                    return obj
            elif let obj = objs.get(""):
                return obj
        return Dict[String, UInt8]()

fn clean_ep_json(inout ep_json: Dict[String, UInt8]):
    pass

@value
struct DataInputProcessing:
    var input_processor: InputProcessor

    fn __init__(inout self):
        self.input_processor = InputProcessor.factory()

    fn init_constant_state(inout self, state: Pointer[UInt8]):
        pass

    fn init_state(inout self, state: Pointer[UInt8]):
        pass

    fn clear_state(inout self):
        self.input_processor = InputProcessor.factory()
