from nlohmann.json import json
from ..FromChars import FromChars
from fast_float import fast_float
from milo.dtoa import dtoa
from milo.itoa import itoa
from memory import memset
from math import round
from string import String
from utils import StringRef, StringView, format, to_upper, to_lower

@value
struct IdfParser:
    var cur_line_num: UInt = 1
    var index_into_cur_line: UInt = 0
    var beginning_of_line_index: UInt = 0
    var idf_size: UInt = 0
    var s: StaticArray[UInt8, 129] = StaticArray[UInt8, 129]()
    var objectTypeMap: Dict[String, String] = Dict[String, String]()
    var errors_: List[String] = List[String]()
    var warnings_: List[String] = List[String]()

    @staticmethod
    def increment_both_index(inout index: UInt, inout line_index: UInt):
        index += 1
        line_index += 1

    @staticmethod
    def decrement_both_index(inout index: UInt, inout line_index: UInt):
        index -= 1
        line_index -= 1

    def parse_idf(inout self, idf: StringView, inout index: UInt, inout success: Bool, schema: json) -> json:
        var root: json
        var token: Token
        var schema_properties = schema["properties"]
        self.objectTypeMap.reserve(schema_properties.size())
        for it in schema_properties.items():
            var key = self.convertToUpper(it.key())
            self.objectTypeMap[key] = it.key()
        if self.idf_size > 3:
            if idf[0] == '\xEF' and idf[1] == '\xBB' and idf[2] == '\xBF':
                index += 3
                self.index_into_cur_line += 3
        var idfObjectCount: Int = 0
        while True:
            token = self.look_ahead(idf, index)
            if token == Token.END:
                break
            if token == Token.NONE:
                success = False
                return root
            if token == Token.SEMICOLON:
                self.next_token(idf, index)
                continue
            if token == Token.COMMA:
                self.errors_.append(format("Line: {} Index: {} - Extraneous comma found.", self.cur_line_num, self.index_into_cur_line))
                success = False
                return root
            if token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            else:
                idfObjectCount += 1
                var parsed_obj_name = self.parse_string(idf, index)
                var obj_name = self.normalizeObjectType(parsed_obj_name)
                if obj_name == "":
                    self.errors_.append(format("Line: {} Index: {} - \"{}\" is not a valid Object Type.", self.cur_line_num, self.index_into_cur_line, parsed_obj_name))
                    while token != Token.SEMICOLON and token != Token.END:
                        token = self.next_token(idf, index)
                    continue
                var object_success: Bool = True
                var obj_loc = schema_properties[obj_name]
                var legacy_idd = obj_loc["legacy_idd"]
                var obj = self.parse_object(idf, index, object_success, legacy_idd, obj_loc, idfObjectCount)
                if not object_success:
                    var found_index = idf.find_first_of('\n', self.beginning_of_line_index)
                    var line: String
                    if found_index != -1:
                        line = idf.substr(self.beginning_of_line_index, found_index - self.beginning_of_line_index - 1)
                    self.errors_.append(format("Line: {} Index: {} - Error parsing \"{}\". Error in following line.", self.cur_line_num, self.index_into_cur_line, obj_name))
                    self.errors_.append(format("~~~ {}", line))
                    success = False
                    continue
                var name = format("{} {}", obj_name, root[obj_name].size() + 1)
                if not obj.is_null():
                    var name_iter = obj.find("name")
                    if name_iter != obj.end():
                        name = name_iter.value().get_string()
                        obj.erase(name_iter)
                    else:
                        var it = obj_loc.find("name")
                        if it != obj_loc.end():
                            name = ""
                if root[obj_name].find(name) != root[obj_name].end():
                    self.errors_.append(format("Duplicate name found for object of type \"{}\" named \"{}\". Overwriting existing object.", obj_name, name))
                root[obj_name][name] = obj
        return root

    def parse_object(inout self, idf: StringView, inout index: UInt, inout success: Bool, legacy_idd: json, schema_obj_loc: json, idfObjectCount: Int) -> json:
        var root = json.object()
        var extensible = json.object()
        var array_of_extensions = json.array()
        var token: Token
        var extension_key: String
        var legacy_idd_index: UInt = 0
        var extensible_index: UInt = 0
        success = True
        var was_value_parsed: Bool = False
        var legacy_idd_fields_array = legacy_idd["fields"]
        var legacy_idd_extensibles_iter = legacy_idd.find("extensibles")
        var schema_patternProperties = schema_obj_loc["patternProperties"]
        var patternProperty: String
        var dot_star_present: Int = schema_patternProperties.count(".*")
        var no_whitespace_present: Int = schema_patternProperties.count("^.*\\S.*$")
        if dot_star_present != 0:
            patternProperty = ".*"
        elif no_whitespace_present != 0:
            patternProperty = "^.*\\S.*$"
        else:
            raise Error("The patternProperties value is not a valid choice (\".*\", \"^.*\\S.*$\")")
        var schema_obj_props = schema_patternProperties[patternProperty]["properties"]
        var key = legacy_idd.find("extension")
        var schema_obj_extensions: json = None
        if legacy_idd_extensibles_iter != legacy_idd.end():
            if key == legacy_idd.end():
                self.errors_.append("\"extension\" key not found in schema. Need to add to list in modify_schema.py.")
                success = False
                return root
            extension_key = key.value().get_string()
            schema_obj_extensions = schema_obj_props[extension_key]["items"]["properties"]
        root["idf_order"] = idfObjectCount
        var found_min_fields = schema_obj_loc.find("min_fields")
        index += 1
        while True:
            token = self.look_ahead(idf, index)
            root["idf_max_fields"] = legacy_idd_index
            root["idf_max_extensible_fields"] = extensible_index
            if token == Token.NONE:
                success = False
                return root
            if token == Token.END:
                return root
            if token == Token.COMMA or token == Token.SEMICOLON:
                if not was_value_parsed:
                    var ext_size: Int = 0
                    if legacy_idd_index < legacy_idd_fields_array.size():

                    else:
                        var legacy_idd_extensibles_array = legacy_idd_extensibles_iter.value()
                        ext_size = legacy_idd_extensibles_array.size().to_int()
                        extensible_index += 1
                    if (ext_size != 0) and extensible_index % ext_size == 0:
                        array_of_extensions.push_back(extensible)
                        extensible.clear()
                legacy_idd_index += 1
                was_value_parsed = False
                self.next_token(idf, index)
                if token == Token.SEMICOLON:
                    var min_fields: UInt = 0
                    if found_min_fields != schema_obj_loc.end():
                        min_fields = found_min_fields.value().get_uint()
                    while legacy_idd_index < min_fields:
                        legacy_idd_index += 1
                    if not extensible.empty():
                        array_of_extensions.push_back(extensible)
                        extensible.clear()
                    root["idf_max_fields"] = legacy_idd_index
                    root["idf_max_extensible_fields"] = extensible_index
                    break
            elif token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            elif legacy_idd_index >= legacy_idd_fields_array.size():
                if legacy_idd_extensibles_iter == legacy_idd.end():
                    self.errors_.append(format("Line: {} Index: {} - Object contains more field values than maximum number of IDD fields and is not extensible.", self.cur_line_num, self.index_into_cur_line))
                    success = False
                    return root
                if schema_obj_extensions == None:
                    self.errors_.append(format("Line: {} Index: {} - Object does not have extensible fields but should. Likely a parsing error.", self.cur_line_num, self.index_into_cur_line))
                    success = False
                    return root
                var legacy_idd_extensibles_array = legacy_idd_extensibles_iter.value()
                var size = legacy_idd_extensibles_array.size()
                var field_name = legacy_idd_extensibles_array[extensible_index % size].get_string()
                var val = self.parse_value(idf, index, success, schema_obj_extensions[field_name])
                if not success:
                    return root
                extensible[field_name] = val
                was_value_parsed = True
                extensible_index += 1
                if (extensible_index != 0) and extensible_index % size == 0:
                    array_of_extensions.push_back(extensible)
                    extensible.clear()
            else:
                was_value_parsed = True
                var field = legacy_idd_fields_array[legacy_idd_index].get_string()
                var find_field_iter = schema_obj_props.find(field)
                if find_field_iter == schema_obj_props.end():
                    if field == "name":
                        root[field] = self.parse_string(idf, index)
                    else:
                        self.errors_.append(format("Line: {} - Field \"{}\" was not found.", self.cur_line_num, field))
                else:
                    var val = self.parse_value(idf, index, success, find_field_iter.value())
                    if not success:
                        return root
                    root[field] = val
                if not success:
                    return root
        if not array_of_extensions.empty():
            root[extension_key] = array_of_extensions
            array_of_extensions = None
        return root

    def parse_number(inout self, idf: StringView, inout index: UInt) -> json:
        self.eat_whitespace(idf, index)
        var save_i = index
        var running = True
        while running:
            if save_i == self.idf_size:
                break
            var c = idf[save_i]
            if c == '!' or c == ',' or c == ';' or c == '\r' or c == '\n':
                running = False
            else:
                save_i += 1
        var diff = save_i - index
        var value = idf.substr(index, diff)
        self.index_into_cur_line += diff
        index = save_i
        def convert_double(str: StringView, inout index: UInt, inout self: IdfParser) -> json:
            var plus_sign: UInt = 0
            if str.front() == '+':
                plus_sign = 1
            var str_end = str.data() + str.size()
            var val: Float64
            var result = fast_float.from_chars(str.data() + plus_sign, str.data() + str.size(), val)
            if result.ec == std.errc.invalid_argument or result.ec == std.errc.result_out_of_range:
                return self.rtrim(str)
            if result.ptr != str_end:
                var initial_ptr = result.ptr
                while result.ptr != str_end:
                    if result.ptr[] != ' ':
                        break
                    result.ptr += 1
                if result.ptr == str_end:
                    index -= (str_end - initial_ptr)
                    self.index_into_cur_line -= (str_end - initial_ptr)
                    return val
                return self.rtrim(str)
            return val
        def convert_int(str: StringView, inout index: UInt, inout self: IdfParser) -> json:
            var str_end = str.data() + str.size()
            var val: Int
            var result = FromChars.from_chars(str.data(), str.data() + str.size(), val)
            if result.ec == std.errc.result_out_of_range or result.ec == std.errc.invalid_argument:
                return convert_double(str, index, self)
            if result.ptr != str_end:
                if result.ptr[] == '.' or result.ptr[] == 'e' or result.ptr[] == 'E':
                    return convert_double(str, index, self)
                var initial_ptr = result.ptr
                while result.ptr != str_end:
                    if result.ptr[] != ' ':
                        break
                    result.ptr += 1
                if result.ptr == str_end:
                    index -= (str_end - initial_ptr)
                    self.index_into_cur_line -= (str_end - initial_ptr)
                    return val
                return self.rtrim(str)
            return val
        return convert_int(value, index, self)

    def parse_integer(inout self, idf: StringView, inout index: UInt) -> json:
        self.eat_whitespace(idf, index)
        var save_i = index
        var running = True
        while running:
            if save_i == self.idf_size:
                break
            var c = idf[save_i]
            if c == '!' or c == ',' or c == ';' or c == '\r' or c == '\n':
                running = False
            else:
                save_i += 1
        var diff = save_i - index
        var string_value = idf.substr(index, diff)
        self.index_into_cur_line += diff
        index = save_i
        var string_end = string_value.data() + string_value.size()
        var int_value: Int
        var result = FromChars.from_chars(string_value.data(), string_value.data() + string_value.size(), int_value)
        if result.ec == std.errc.result_out_of_range or result.ec == std.errc.invalid_argument:
            return self.rtrim(string_value)
        if result.ptr != string_end:
            var plus_sign: UInt = 0
            if string_value.front() == '+':
                plus_sign = 1
            var double_value: Float64
            var fresult = fast_float.from_chars(string_value.data() + plus_sign, string_value.data() + string_value.size(), double_value)
            if fresult.ec == std.errc.invalid_argument or fresult.ec == std.errc.result_out_of_range:
                return self.rtrim(string_value)
            int_value = round(double_value).to_int()
        return int_value

    def parse_value(inout self, idf: StringView, inout index: UInt, inout success: Bool, field_loc: json) -> json:
        var token: Token
        var field_type = field_loc.find("type")
        if field_type != field_loc.end():
            if field_type.value() == "number":
                token = Token.NUMBER
            elif field_type.value() == "integer":
                token = Token.INTEGER
            else:
                token = Token.STRING
        else:
            token = self.look_ahead(idf, index)
        if token == Token.STRING:
            var parsed_string = self.parse_string(idf, index)
            var enum_it = field_loc.find("enum")
            if enum_it != field_loc.end():
                for enum_str in enum_it.value():
                    var str = enum_str.get_string()
                    if icompare(str, parsed_string):
                        return str
            elif icompare(parsed_string, "Autosize") or icompare(parsed_string, "Autocalculate"):
                var default_it = field_loc.find("default")
                var anyOf_it = field_loc.find("anyOf")
                if anyOf_it == field_loc.end():
                    self.errors_.append(format("Line: {} Index: {} - Field cannot be Autosize or Autocalculate", self.cur_line_num, self.index_into_cur_line))
                    return parsed_string
                if default_it != field_loc.end():
                    return field_loc["anyOf"][1]["enum"][1]
                return field_loc["anyOf"][1]["enum"][0]
            return parsed_string
        elif token == Token.NUMBER:
            return self.parse_number(idf, index)
        elif token == Token.INTEGER:
            return self.parse_integer(idf, index)
        else:
            success = False
            return None

    def parse_string(inout self, idf: StringView, inout index: UInt) -> String:
        self.eat_whitespace(idf, index)
        var str: String
        while True:
            if index == self.idf_size:
                break
            var c = idf[index]
            self.increment_both_index(index, self.index_into_cur_line)
            if c == ',' or c == ';' or c == '!':
                self.decrement_both_index(index, self.index_into_cur_line)
                break
            str += c
        return self.rtrim(str)

    def eat_whitespace(inout self, idf: StringView, inout index: UInt):
        while index < self.idf_size:
            var c = idf[index]
            if c == ' ' or c == '\r' or c == '\t':
                self.increment_both_index(index, self.index_into_cur_line)
                continue
            elif c == '\n':
                self.increment_both_index(index, self.cur_line_num)
                self.beginning_of_line_index = index
                self.index_into_cur_line = 0
                continue
            else:
                return

    def eat_comment(inout self, idf: StringView, inout index: UInt):
        while True:
            if index == self.idf_size:
                break
            if idf[index] == '\n':
                self.increment_both_index(index, self.cur_line_num)
                self.index_into_cur_line = 0
                self.beginning_of_line_index = index
                break
            self.increment_both_index(index, self.index_into_cur_line)

    def look_ahead(inout self, idf: StringView, index: UInt) -> Token:
        var save_index = index
        var save_line_num = self.cur_line_num
        var save_line_index = self.index_into_cur_line
        var token = self.next_token(idf, save_index)
        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index
        return token

    def next_token(inout self, idf: StringView, inout index: UInt) -> Token:
        self.eat_whitespace(idf, index)
        if index == self.idf_size:
            return Token.END
        var c = idf[index]
        self.increment_both_index(index, self.index_into_cur_line)
        if c == '!':
            return Token.EXCLAMATION
        elif c == ',':
            return Token.COMMA
        elif c == ';':
            return Token.SEMICOLON
        else:
            var numeric = ".-+0123456789"
            if numeric.find_first_of(c) != -1:
                return Token.NUMBER
            return Token.STRING
        self.decrement_both_index(index, self.index_into_cur_line)
        return Token.NONE

    def next_limited_token(inout self, idf: StringView, inout index: UInt) -> Token:
        if index == self.idf_size:
            return Token.END
        var c = idf[index]
        self.increment_both_index(index, self.index_into_cur_line)
        if c == '!':
            return Token.EXCLAMATION
        elif c == ',':
            return Token.COMMA
        elif c == ';':
            return Token.SEMICOLON
        else:
            return Token.NONE

    @staticmethod
    def rtrim(str: StringView) -> String:
        var whitespace = " \t\0"
        if str.empty():
            return String()
        var index = str.find_last_not_of(whitespace)
        if index == -1:
            return String()
        if index + 1 < str.length():
            return String(str.substr(0, index + 1))
        return String(str)

    @staticmethod
    def convertToUpper(str: String) -> String:
        var len = str.size()
        var result = str
        for i in range(len):
            var c = str[i]
            if 'a' <= c and c <= 'z':
                result[i] = c ^ 0x20
        return result

    def decode(inout self, idf: StringView, schema: json) -> json:
        var success: Bool = True
        return self.decode(idf, idf.size(), schema, success)

    def decode(inout self, idf: StringView, schema: json, inout success: Bool) -> json:
        return self.decode(idf, idf.size(), schema, success)

    def decode(inout self, idf: StringView, _idf_size: UInt, schema: json) -> json:
        var success: Bool = True
        return self.decode(idf, _idf_size, schema, success)

    def decode(inout self, idf: StringView, _idf_size: UInt, schema: json, inout success: Bool) -> json:
        success = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.idf_size = _idf_size
        if idf.empty():
            success = False
            return None
        var index: UInt = 0
        return self.parse_idf(idf, index, success, schema)

    def encode(inout self, root: json, schema: json) -> String:
        var end_of_field = ",\n  "
        var end_of_object = ";\n\n"
        var encoded: String
        var extension_key: String
        if self.idf_size > 0:
            encoded.reserve(self.idf_size)
        else:
            encoded.reserve(root.size() * 1024)
        for obj in root.items():
            var legacy_idd = schema["properties"][obj.key()]["legacy_idd"]
            var legacy_idd_field = legacy_idd["fields"]
            var key = legacy_idd.find("extension")
            if key != legacy_idd.end():
                extension_key = key.value().get_string()
            for obj_in in obj.value().items():
                encoded += obj.key()
                var skipped_fields: UInt = 0
                for i in legacy_idd_field:
                    var entry = i.get_string()
                    if obj_in.value().find(entry) == obj_in.value().end():
                        if entry == "name":
                            encoded += end_of_field + obj_in.key()
                        else:
                            skipped_fields += 1
                        continue
                    for j in range(skipped_fields):
                        encoded += end_of_field
                    skipped_fields = 0
                    encoded += end_of_field
                    var val = obj_in.value()[entry]
                    if val.is_string():
                        encoded += val.get_string()
                    elif val.is_number_integer():
                        encoded += str(val.get_int())
                    else:
                        dtoa(val.get_float64(), self.s)
                        encoded += String(self.s)
                if obj_in.value().find(extension_key) == obj_in.value().end():
                    encoded += end_of_object
                    continue
                var extensions = obj_in.value()[extension_key]
                for cur_extension_obj in extensions:
                    var extensible = schema["properties"][obj.key()]["legacy_idd"]["extensibles"]
                    for i in extensible:
                        var tmp = i.get_string()
                        if cur_extension_obj.find(tmp) == cur_extension_obj.end():
                            skipped_fields += 1
                            continue
                        for j in range(skipped_fields):
                            encoded += end_of_field
                        skipped_fields = 0
                        encoded += end_of_field
                        if cur_extension_obj[tmp].is_string():
                            encoded += cur_extension_obj[tmp].get_string()
                        else:
                            dtoa(cur_extension_obj[tmp].get_float64(), self.s)
                            encoded += String(self.s)
                encoded += end_of_object
        return encoded

    def normalizeObjectType(inout self, objectType: String) -> String:
        if objectType.empty():
            return String()
        var key = self.convertToUpper(objectType)
        var tmp_umit = self.objectTypeMap.find(key)
        if tmp_umit != self.objectTypeMap.end():
            return tmp_umit.value()
        return String()

    def errors(inout self) -> List[String]:
        return self.errors_

    def warnings(inout self) -> List[String]:
        return self.warnings_

    def hasErrors(inout self) -> Bool:
        return not self.errors_.empty()

    enum Token:
        NONE = 0
        END = 1
        EXCLAMATION = 2
        COMMA = 3
        SEMICOLON = 4
        STRING = 5
        NUMBER = 6
        INTEGER = 7

def icompare(a: StringView, b: StringView) -> Bool:
    if a.length() == b.length():
        for i in range(a.length()):
            if to_lower(a[i]) != to_lower(b[i]):
                return False
        return True
    return False