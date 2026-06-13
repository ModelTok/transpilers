# EXTERNAL DEPS (to wire in glue):
# - json: dict-like JSON representation
# - math: standard math functions

from math import floor, ceil
from collections import Dict
from enum import IntEnum
import json


struct Token:
    alias NONE = 0
    alias END = 1
    alias EXCLAMATION = 2
    alias COMMA = 3
    alias SEMICOLON = 4
    alias STRING = 5
    alias NUMBER = 6
    alias INTEGER = 7


struct IdfParser:
    var cur_line_num: UInt
    var index_into_cur_line: UInt
    var beginning_of_line_index: UInt
    var idf_size: UInt
    var s: String
    var object_type_map: Dict[String, String]
    var errors_: List[String]
    var warnings_: List[String]

    fn __init__(inout self):
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.idf_size = 0
        self.s = ""
        self.object_type_map = Dict[String, String]()
        self.errors_ = List[String]()
        self.warnings_ = List[String]()

    fn decode(
        inout self,
        idf: String,
        schema: Dict[String, Any],
        inout success: List[Bool] = List[Bool](),
        idf_size: UInt = 0,
    ) -> Dict[String, Any]:
        if success.size() == 0:
            success.append(True)
        let _idf_size = idf_size if idf_size > 0 else idf.size()

        success[0] = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.idf_size = _idf_size

        if idf.size() == 0:
            success[0] = False
            return Dict[String, Any]()

        var index: List[UInt] = List[UInt]()
        index.append(0)
        return self.parse_idf(idf, index, success, schema)

    fn encode(
        self, root: Dict[String, Any], schema: Dict[String, Any]
    ) -> String:
        let end_of_field = ",\n  "
        let end_of_object = ";\n\n"
        var encoded = ""

        var obj_keys = root.keys()
        for obj_key in obj_keys:
            var legacy_idd = schema.get("properties", Dict[String, Any]()).get(
                obj_key, Dict[String, Any]()
            )
            var legacy_idd_field = legacy_idd.get("fields", List[String]())
            var extension_key = legacy_idd.get("extension", "")

            var obj_dict = root.get(obj_key, Dict[String, Any]())
            var obj_in_keys = obj_dict.keys()

            for obj_in_key in obj_in_keys:
                encoded += obj_key
                var skipped_fields: UInt = 0

                for entry in legacy_idd_field:
                    if not obj_dict.get(obj_in_key, Dict[String, Any]()).contains(
                        entry
                    ):
                        if entry == "name":
                            encoded += end_of_field + obj_in_key
                        else:
                            skipped_fields += 1
                        continue

                    for _ in range(skipped_fields):
                        encoded += end_of_field
                    skipped_fields = 0
                    encoded += end_of_field

                    var val = obj_dict.get(obj_in_key, Dict[String, Any]()).get(
                        entry, ""
                    )
                    if val isa String:
                        encoded += String(val)
                    elif val isa Int:
                        encoded += str(Int(val))
                    else:
                        encoded += self.dtoa(Float64(val))

                if not obj_dict.get(obj_in_key, Dict[String, Any]()).contains(
                    extension_key
                ):
                    encoded += end_of_object
                    continue

                var extensions = obj_dict.get(obj_in_key, Dict[String, Any]()).get(
                    extension_key, List[Dict[String, Any]]()
                )
                var extensible = legacy_idd.get("extensibles", List[String]())

                for cur_extension_obj in extensions:
                    for i in extensible:
                        let tmp = i
                        if not cur_extension_obj.contains(tmp):
                            skipped_fields += 1
                            continue

                        for _ in range(skipped_fields):
                            encoded += end_of_field
                        skipped_fields = 0
                        encoded += end_of_field

                        var ext_val = cur_extension_obj.get(tmp, "")
                        if ext_val isa String:
                            encoded += String(ext_val)
                        else:
                            encoded += self.dtoa(Float64(ext_val))

                encoded += end_of_object

        return encoded

    fn normalize_object_type(self, object_type: String) -> String:
        if object_type.size() == 0:
            return ""
        let key = self.convert_to_upper(object_type)
        if self.object_type_map.contains(key):
            return self.object_type_map.get(key)
        return ""

    fn errors(self) -> List[String]:
        return self.errors_

    fn warnings(self) -> List[String]:
        return self.warnings_

    fn has_errors(self) -> Bool:
        return self.errors_.size() > 0

    fn parse_idf(
        inout self,
        idf: String,
        inout index: List[UInt],
        inout success: List[Bool],
        schema: Dict[String, Any],
    ) -> Dict[String, Any]:
        var root = Dict[String, Any]()
        var schema_properties = schema.get("properties", Dict[String, Any]())

        self.object_type_map = Dict[String, String]()
        var keys = schema_properties.keys()
        for key in keys:
            let upper_key = self.convert_to_upper(key)
            self.object_type_map[upper_key] = key

        if self.idf_size > 3:
            if (
                idf[0] == "\xEF" and idf[1] == "\xBB" and idf[2] == "\xBF"
            ):
                index[0] += 3
                self.index_into_cur_line += 3

        var idf_object_count: Int = 0
        while True:
            let token = self.look_ahead(idf, index[0])
            if token == Token.END:
                break
            if token == Token.NONE:
                success[0] = False
                return root
            if token == Token.SEMICOLON:
                self.next_token(idf, index)
                continue
            if token == Token.COMMA:
                self.errors_.append(
                    "Line: "
                    + str(self.cur_line_num)
                    + " Index: "
                    + str(self.index_into_cur_line)
                    + " - Extraneous comma found."
                )
                success[0] = False
                return root
            if token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            else:
                idf_object_count += 1
                let parsed_obj_name = self.parse_string(idf, index)
                let obj_name = self.normalize_object_type(parsed_obj_name)
                if obj_name.size() == 0:
                    self.errors_.append(
                        'Line: '
                        + str(self.cur_line_num)
                        + ' Index: '
                        + str(self.index_into_cur_line)
                        + ' - "'
                        + parsed_obj_name
                        + '" is not a valid Object Type.'
                    )
                    var tok = self.next_token(idf, index)
                    while tok != Token.SEMICOLON and tok != Token.END:
                        tok = self.next_token(idf, index)
                    continue

                var object_success = List[Bool]()
                object_success.append(True)
                let obj_loc = schema_properties.get(obj_name, Dict[String, Any]())
                let legacy_idd = obj_loc.get("legacy_idd", Dict[String, Any]())
                var obj = self.parse_object(
                    idf, index, object_success, legacy_idd, obj_loc, idf_object_count
                )

                if not object_success[0]:
                    var line = ""
                    let found_index = idf.find("\n", self.beginning_of_line_index)
                    if found_index != -1:
                        line = idf[
                            self.beginning_of_line_index : found_index - 1
                        ]
                    self.errors_.append(
                        'Line: '
                        + str(self.cur_line_num)
                        + ' Index: '
                        + str(self.index_into_cur_line)
                        + ' - Error parsing "'
                        + obj_name
                        + '". Error in following line.'
                    )
                    self.errors_.append("~~~ " + line)
                    success[0] = False
                    continue

                if not root.contains(obj_name):
                    root[obj_name] = Dict[String, Any]()

                var name = obj_name + " " + str(root.get(obj_name, Dict[String, Any]()).size() + 1)

                if obj.size() > 0:
                    if obj.contains("name"):
                        name = String(obj.get("name"))
                        obj.delete("name")
                    else:
                        if obj_loc.contains("name"):
                            name = ""

                if root.get(obj_name, Dict[String, Any]()).contains(name):
                    self.errors_.append(
                        'Duplicate name found for object of type "'
                        + obj_name
                        + '" named "'
                        + name
                        + '". Overwriting existing object.'
                    )

                var obj_dict = root.get(obj_name, Dict[String, Any]())
                obj_dict[name] = obj
                root[obj_name] = obj_dict

        return root

    fn parse_object(
        inout self,
        idf: String,
        inout index: List[UInt],
        inout success: List[Bool],
        legacy_idd: Dict[String, Any],
        schema_obj_loc: Dict[String, Any],
        idf_object_count: Int,
    ) -> Dict[String, Any]:
        var root = Dict[String, Any]()
        var extensible = Dict[String, Any]()
        var array_of_extensions = List[Dict[String, Any]]()
        var extension_key = ""
        var legacy_idd_index: UInt = 0
        var extensible_index: UInt = 0
        success[0] = True
        var was_value_parsed = False

        let legacy_idd_fields_array = legacy_idd.get("fields", List[String]())
        let legacy_idd_extensibles_iter = legacy_idd.get("extensibles", List[String]())

        let schema_pattern_properties = schema_obj_loc.get(
            "patternProperties", Dict[String, Any]()
        )
        var pattern_property = ""
        if schema_pattern_properties.contains(".*"):
            pattern_property = ".*"
        elif schema_pattern_properties.contains(r"^.*\S.*$"):
            pattern_property = r"^.*\S.*$"
        else:
            raise Error(
                'The patternProperties value is not a valid choice (".*", "^.*\\S.*$")'
            )

        let schema_obj_props = schema_pattern_properties.get(pattern_property, Dict[String, Any]()).get(
            "properties", Dict[String, Any]()
        )
        var extension_key_iter = legacy_idd.get("extension", "")

        var schema_obj_extensions: Dict[String, Any] = Dict[String, Any]()
        if legacy_idd_extensibles_iter.size() > 0:
            if extension_key_iter.size() == 0:
                self.errors_.append(
                    '"extension" key not found in schema. Need to add to list in modify_schema.py.'
                )
                success[0] = False
                return root
            extension_key = extension_key_iter
            schema_obj_extensions = schema_obj_props.get(extension_key, Dict[String, Any]()).get("items", Dict[String, Any]()).get("properties", Dict[String, Any]())

        root["idf_order"] = idf_object_count

        var found_min_fields = schema_obj_loc.get("min_fields", UInt(0))

        index[0] += 1

        while True:
            let token = self.look_ahead(idf, index[0])
            root["idf_max_fields"] = legacy_idd_index
            root["idf_max_extensible_fields"] = extensible_index

            if token == Token.NONE:
                success[0] = False
                return root
            if token == Token.END:
                return root
            if token == Token.COMMA or token == Token.SEMICOLON:
                if not was_value_parsed:
                    var ext_size: UInt = 0
                    if legacy_idd_index >= legacy_idd_fields_array.size():
                        if legacy_idd_extensibles_iter.size() > 0:
                            ext_size = legacy_idd_extensibles_iter.size()
                            extensible_index += 1
                    if ext_size != 0 and extensible_index % ext_size == 0:
                        array_of_extensions.append(extensible)
                        extensible = Dict[String, Any]()

                legacy_idd_index += 1
                was_value_parsed = False
                self.next_token(idf, index)

                if token == Token.SEMICOLON:
                    var min_fields: UInt = 0
                    if found_min_fields != 0:
                        min_fields = UInt(found_min_fields)
                    while legacy_idd_index < min_fields:
                        legacy_idd_index += 1

                    if extensible.size() > 0:
                        array_of_extensions.append(extensible)
                        extensible = Dict[String, Any]()

                    root["idf_max_fields"] = legacy_idd_index
                    root["idf_max_extensible_fields"] = extensible_index
                    break
            elif token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            elif legacy_idd_index >= legacy_idd_fields_array.size():
                if legacy_idd_extensibles_iter.size() == 0:
                    self.errors_.append(
                        "Line: "
                        + str(self.cur_line_num)
                        + " Index: "
                        + str(self.index_into_cur_line)
                        + " - Object contains more field values than maximum number of IDD fields and is not extensible."
                    )
                    success[0] = False
                    return root

                if schema_obj_extensions.size() == 0:
                    self.errors_.append(
                        "Line: "
                        + str(self.cur_line_num)
                        + " Index: "
                        + str(self.index_into_cur_line)
                        + " - Object does not have extensible fields but should. Likely a parsing error."
                    )
                    success[0] = False
                    return root

                let size = legacy_idd_extensibles_iter.size()
                let field_name = legacy_idd_extensibles_iter[int(extensible_index % size)]
                var val = self.parse_value(
                    idf, index, success, schema_obj_extensions.get(field_name, Dict[String, Any]())
                )

                if not success[0]:
                    return root

                extensible[field_name] = val
                was_value_parsed = True
                extensible_index += 1

                if extensible_index != 0 and extensible_index % size == 0:
                    array_of_extensions.append(extensible)
                    extensible = Dict[String, Any]()
            else:
                was_value_parsed = True
                let field = legacy_idd_fields_array[int(legacy_idd_index)]
                var find_field_iter = schema_obj_props.get(field)

                if find_field_iter == None:
                    if field == "name":
                        root[field] = self.parse_string(idf, index)
                    else:
                        self.errors_.append(
                            "Line: "
                            + str(self.cur_line_num)
                            + ' - Field "'
                            + field
                            + '" was not found.'
                        )
                else:
                    var val = self.parse_value(
                        idf, index, success, find_field_iter
                    )
                    if not success[0]:
                        return root
                    root[field] = val

                if not success[0]:
                    return root

        if array_of_extensions.size() > 0:
            root[extension_key] = array_of_extensions

        return root

    fn parse_number(inout self, idf: String, inout index: List[UInt]) -> Any:
        self.eat_whitespace(idf, index)

        var save_i = index[0]
        var running = True
        while running:
            if save_i == self.idf_size:
                break
            let c = idf[int(save_i)]
            if c in "!,;\r\n":
                running = False
            else:
                save_i += 1

        let diff = save_i - index[0]
        let value = idf[int(index[0]) : int(save_i)]
        self.index_into_cur_line += diff
        index[0] = save_i

        return self.convert_int(value)

    fn parse_integer(inout self, idf: String, inout index: List[UInt]) -> Any:
        self.eat_whitespace(idf, index)

        var save_i = index[0]
        var running = True
        while running:
            if save_i == self.idf_size:
                break
            let c = idf[int(save_i)]
            if c in "!,;\r\n":
                running = False
            else:
                save_i += 1

        let diff = save_i - index[0]
        let string_value = idf[int(index[0]) : int(save_i)]
        self.index_into_cur_line += diff
        index[0] = save_i

        try:
            return atol(string_value)
        except:
            var plus_sign: Int = 0
            if string_value.size() > 0 and string_value[0] == "+":
                plus_sign = 1
            try:
                let double_value = atof(string_value[plus_sign:])
                let int_value = int(round(double_value))
                return int_value
            except:
                return self.rtrim(string_value)

    fn parse_value(
        inout self,
        idf: String,
        inout index: List[UInt],
        inout success: List[Bool],
        field_loc: Dict[String, Any],
    ) -> Any:
        var field_type = field_loc.get("type", "")
        var token: Int
        if field_type.size() > 0:
            if field_type == "number":
                token = Token.NUMBER
            elif field_type == "integer":
                token = Token.INTEGER
            else:
                token = Token.STRING
        else:
            token = self.look_ahead(idf, index[0])

        if token == Token.STRING:
            let parsed_string = self.parse_string(idf, index)
            var enum_it = field_loc.get("enum")
            if enum_it != None:
                for enum_str in enum_it:
                    if self.icompare(String(enum_str), parsed_string):
                        return enum_str
            elif self.icompare(parsed_string, "Autosize") or self.icompare(
                parsed_string, "Autocalculate"
            ):
                var default_it = field_loc.get("default")
                var anyOf_it = field_loc.get("anyOf")

                if anyOf_it == None:
                    self.errors_.append(
                        "Line: "
                        + str(self.cur_line_num)
                        + " Index: "
                        + str(self.index_into_cur_line)
                        + " - Field cannot be Autosize or Autocalculate"
                    )
                    return parsed_string

                if default_it != None:
                    return field_loc["anyOf"][1]["enum"][1]
                return field_loc["anyOf"][1]["enum"][0]

            return parsed_string
        elif token == Token.NUMBER:
            return self.parse_number(idf, index)
        elif token == Token.INTEGER:
            return self.parse_integer(idf, index)
        else:
            pass

        success[0] = False
        return None

    fn parse_string(inout self, idf: String, inout index: List[UInt]) -> String:
        self.eat_whitespace(idf, index)

        var s = ""
        while True:
            if index[0] == self.idf_size:
                break

            let c = idf[int(index[0])]
            self.increment_both_index(index)
            if c in ",;!":
                self.decrement_both_index(index)
                break
            s += c

        return self.rtrim(s)

    fn increment_both_index(inout self, inout index: List[UInt]) -> None:
        index[0] += 1
        self.index_into_cur_line += 1

    fn decrement_both_index(inout self, inout index: List[UInt]) -> None:
        index[0] -= 1
        self.index_into_cur_line -= 1

    fn eat_whitespace(inout self, idf: String, inout index: List[UInt]) -> None:
        while index[0] < self.idf_size:
            let c = idf[int(index[0])]
            if c in " \r\t":
                self.increment_both_index(index)
            elif c == "\n":
                self.increment_both_index(index)
                self.cur_line_num += 1
                self.beginning_of_line_index = index[0]
                self.index_into_cur_line = 0
            else:
                return

    fn eat_comment(inout self, idf: String, inout index: List[UInt]) -> None:
        while True:
            if index[0] == self.idf_size:
                break
            if idf[int(index[0])] == "\n":
                self.increment_both_index(index)
                self.cur_line_num += 1
                self.index_into_cur_line = 0
                self.beginning_of_line_index = index[0]
                break
            self.increment_both_index(index)

    fn look_ahead(inout self, idf: String, index: UInt) -> Int:
        let save_index = index
        let save_line_num = self.cur_line_num
        let save_line_index = self.index_into_cur_line

        var temp_index = List[UInt]()
        temp_index.append(save_index)
        let token = self.next_token(idf, temp_index)

        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index

        return token

    fn next_token(inout self, idf: String, inout index: List[UInt]) -> Int:
        self.eat_whitespace(idf, index)

        if index[0] == self.idf_size:
            return Token.END

        let c = idf[int(index[0])]
        self.increment_both_index(index)

        if c == "!":
            return Token.EXCLAMATION
        elif c == ",":
            return Token.COMMA
        elif c == ";":
            return Token.SEMICOLON
        else:
            let numeric = ".-+0123456789"
            if numeric.find_first_of(c) != -1:
                return Token.NUMBER
            return Token.STRING

    fn next_limited_token(inout self, idf: String, inout index: List[UInt]) -> Int:
        if index[0] == self.idf_size:
            return Token.END

        let c = idf[int(index[0])]
        self.increment_both_index(index)

        if c == "!":
            return Token.EXCLAMATION
        elif c == ",":
            return Token.COMMA
        elif c == ";":
            return Token.SEMICOLON
        else:
            return Token.NONE

    fn rtrim(self, s: String) -> String:
        let whitespace = " \t\0"
        if s.size() == 0:
            return ""
        var index: Int = -1
        for i in range(int(s.size()) - 1, -1, -1):
            if whitespace.find_first_of(s[i]) == -1:
                index = i
                break
        if index == -1:
            return ""
        return s[0 : index + 1]

    fn convert_to_upper(self, s: String) -> String:
        var result = ""
        for c in s:
            if "a" <= c <= "z":
                result += chr(ord(c) - 32)
            else:
                result += c
        return result

    fn icompare(self, a: String, b: String) -> Bool:
        return a.size() == b.size() and a.lower() == b.lower()

    fn dtoa(self, val: Float64) -> String:
        return str(val)

    fn convert_int(self, s: String) -> Any:
        try:
            return atol(s)
        except:
            if "." in s or "e" in s or "E" in s:
                return self.convert_double(s)
            return self.rtrim(s)

    fn convert_double(self, s: String) -> Any:
        var plus_sign: Int = 0
        if s.size() > 0 and s[0] == "+":
            plus_sign = 1
        try:
            return atof(s[plus_sign:])
        except:
            return self.rtrim(s)
