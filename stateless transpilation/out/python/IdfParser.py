# EXTERNAL DEPS (to wire in glue):
# - json: standard library dict/list representation
# - math: standard library

import json
import math
from typing import Any, Dict, List, Optional, Tuple, Union
from enum import IntEnum


class Token(IntEnum):
    NONE = 0
    END = 1
    EXCLAMATION = 2
    COMMA = 3
    SEMICOLON = 4
    STRING = 5
    NUMBER = 6
    INTEGER = 7


class IdfParser:
    def __init__(self):
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.idf_size = 0
        self.s = ""
        self.object_type_map: Dict[str, str] = {}
        self.errors_: List[str] = []
        self.warnings_: List[str] = []

    def decode(
        self,
        idf: str,
        schema: Dict[str, Any],
        success: Optional[List[bool]] = None,
        idf_size: Optional[int] = None,
    ) -> Dict[str, Any]:
        if success is None:
            success = [True]
        if idf_size is None:
            idf_size = len(idf)

        success[0] = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.idf_size = idf_size

        if not idf:
            success[0] = False
            return None

        index = 0
        return self.parse_idf(idf, index, success, schema)

    def encode(self, root: Dict[str, Any], schema: Dict[str, Any]) -> str:
        end_of_field = ",\n  "
        end_of_object = ";\n\n"

        encoded = ""
        if self.idf_size > 0:
            # Pre-allocate if possible
            pass

        for obj_key in root:
            legacy_idd = schema.get("properties", {}).get(obj_key, {}).get("legacy_idd", {})
            legacy_idd_field = legacy_idd.get("fields", [])
            extension_key = legacy_idd.get("extension", "")

            for obj_in_key in root[obj_key]:
                encoded += obj_key
                skipped_fields = 0

                for entry in legacy_idd_field:
                    if entry not in root[obj_key][obj_in_key]:
                        if entry == "name":
                            encoded += end_of_field + obj_in_key
                        else:
                            skipped_fields += 1
                        continue

                    for _ in range(skipped_fields):
                        encoded += end_of_field
                    skipped_fields = 0
                    encoded += end_of_field

                    val = root[obj_key][obj_in_key][entry]
                    if isinstance(val, str):
                        encoded += val
                    elif isinstance(val, int):
                        encoded += str(val)
                    else:
                        encoded += self._dtoa(float(val))

                if extension_key not in root[obj_key][obj_in_key]:
                    encoded += end_of_object
                    continue

                extensions = root[obj_key][obj_in_key].get(extension_key, [])
                extensible = legacy_idd.get("extensibles", [])

                for cur_extension_obj in extensions:
                    for i in extensible:
                        tmp = i
                        if tmp not in cur_extension_obj:
                            skipped_fields += 1
                            continue

                        for _ in range(skipped_fields):
                            encoded += end_of_field
                        skipped_fields = 0
                        encoded += end_of_field

                        if isinstance(cur_extension_obj[tmp], str):
                            encoded += cur_extension_obj[tmp]
                        else:
                            encoded += self._dtoa(float(cur_extension_obj[tmp]))

                encoded += end_of_object

        return encoded

    def normalize_object_type(self, object_type: str) -> str:
        if not object_type:
            return ""
        key = self._convert_to_upper(object_type)
        return self.object_type_map.get(key, "")

    def errors(self) -> List[str]:
        return self.errors_

    def warnings(self) -> List[str]:
        return self.warnings_

    def has_errors(self) -> bool:
        return len(self.errors_) > 0

    def parse_idf(
        self, idf: str, index: List[int], success: List[bool], schema: Dict[str, Any]
    ) -> Dict[str, Any]:
        root: Dict[str, Any] = {}
        schema_properties = schema.get("properties", {})

        self.object_type_map.clear()
        for key in schema_properties:
            upper_key = self._convert_to_upper(key)
            self.object_type_map[upper_key] = key

        if self.idf_size > 3:
            if (
                idf[0] == "\xEF" and idf[1] == "\xBB" and idf[2] == "\xBF"
            ):
                index[0] += 3
                self.index_into_cur_line += 3

        idf_object_count = 0
        while True:
            token = self.look_ahead(idf, index[0])
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
                    f"Line: {self.cur_line_num} Index: {self.index_into_cur_line} - Extraneous comma found."
                )
                success[0] = False
                return root
            if token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            else:
                idf_object_count += 1
                parsed_obj_name = self.parse_string(idf, index)
                obj_name = self.normalize_object_type(parsed_obj_name)
                if not obj_name:
                    self.errors_.append(
                        f'Line: {self.cur_line_num} Index: {self.index_into_cur_line} - "{parsed_obj_name}" is not a valid Object Type.'
                    )
                    token = self.next_token(idf, index)
                    while token != Token.SEMICOLON and token != Token.END:
                        token = self.next_token(idf, index)
                    continue

                object_success = [True]
                obj_loc = schema_properties.get(obj_name, {})
                legacy_idd = obj_loc.get("legacy_idd", {})
                obj = self.parse_object(
                    idf, index, object_success, legacy_idd, obj_loc, idf_object_count
                )

                if not object_success[0]:
                    line = ""
                    found_index = idf.find("\n", self.beginning_of_line_index)
                    if found_index != -1:
                        line = idf[
                            self.beginning_of_line_index : found_index - 1
                        ]
                    self.errors_.append(
                        f'Line: {self.cur_line_num} Index: {self.index_into_cur_line} - Error parsing "{obj_name}". Error in following line.'
                    )
                    self.errors_.append(f"~~~ {line}")
                    success[0] = False
                    continue

                if obj_name not in root:
                    root[obj_name] = {}

                name = f"{obj_name} {len(root[obj_name]) + 1}"

                if obj is not None:
                    if "name" in obj:
                        name = obj["name"]
                        del obj["name"]
                    else:
                        if "name" in obj_loc:
                            name = ""

                if name in root[obj_name]:
                    self.errors_.append(
                        f'Duplicate name found for object of type "{obj_name}" named "{name}". Overwriting existing object.'
                    )

                root[obj_name][name] = obj

        return root

    def parse_object(
        self,
        idf: str,
        index: List[int],
        success: List[bool],
        legacy_idd: Dict[str, Any],
        schema_obj_loc: Dict[str, Any],
        idf_object_count: int,
    ) -> Dict[str, Any]:
        root: Dict[str, Any] = {}
        extensible: Dict[str, Any] = {}
        array_of_extensions: List[Dict[str, Any]] = []
        extension_key = ""
        legacy_idd_index = 0
        extensible_index = 0
        success[0] = True
        was_value_parsed = False

        legacy_idd_fields_array = legacy_idd.get("fields", [])
        legacy_idd_extensibles_iter = legacy_idd.get("extensibles")

        schema_pattern_properties = schema_obj_loc.get("patternProperties", {})
        pattern_property = ""
        if ".*" in schema_pattern_properties:
            pattern_property = ".*"
        elif r"^.*\S.*$" in schema_pattern_properties:
            pattern_property = r"^.*\S.*$"
        else:
            raise RuntimeError(
                'The patternProperties value is not a valid choice (".*", "^.*\\S.*$")'
            )

        schema_obj_props = schema_pattern_properties.get(pattern_property, {}).get(
            "properties", {}
        )
        extension_key_iter = legacy_idd.get("extension")

        schema_obj_extensions = None
        if legacy_idd_extensibles_iter is not None:
            if extension_key_iter is None:
                self.errors_.append(
                    '"extension" key not found in schema. Need to add to list in modify_schema.py.'
                )
                success[0] = False
                return root
            extension_key = extension_key_iter
            schema_obj_extensions = (
                schema_obj_props.get(extension_key, {})
                .get("items", {})
                .get("properties", {})
            )

        root["idf_order"] = idf_object_count

        found_min_fields = schema_obj_loc.get("min_fields")

        index[0] += 1

        while True:
            token = self.look_ahead(idf, index[0])
            root["idf_max_fields"] = legacy_idd_index
            root["idf_max_extensible_fields"] = extensible_index

            if token == Token.NONE:
                success[0] = False
                return root
            if token == Token.END:
                return root
            if token == Token.COMMA or token == Token.SEMICOLON:
                if not was_value_parsed:
                    ext_size = 0
                    if legacy_idd_index >= len(legacy_idd_fields_array):
                        if legacy_idd_extensibles_iter is not None:
                            ext_size = len(legacy_idd_extensibles_iter)
                            extensible_index += 1
                    if ext_size != 0 and extensible_index % ext_size == 0:
                        array_of_extensions.append(extensible.copy())
                        extensible.clear()

                legacy_idd_index += 1
                was_value_parsed = False
                self.next_token(idf, index)

                if token == Token.SEMICOLON:
                    min_fields = 0
                    if found_min_fields is not None:
                        min_fields = found_min_fields
                    while legacy_idd_index < min_fields:
                        legacy_idd_index += 1

                    if extensible:
                        array_of_extensions.append(extensible)
                        extensible.clear()

                    root["idf_max_fields"] = legacy_idd_index
                    root["idf_max_extensible_fields"] = extensible_index
                    break
            elif token == Token.EXCLAMATION:
                self.eat_comment(idf, index)
            elif legacy_idd_index >= len(legacy_idd_fields_array):
                if legacy_idd_extensibles_iter is None:
                    self.errors_.append(
                        f"Line: {self.cur_line_num} Index: {self.index_into_cur_line} - Object contains more field values than maximum number of IDD fields and is not extensible."
                    )
                    success[0] = False
                    return root

                if schema_obj_extensions is None:
                    self.errors_.append(
                        f"Line: {self.cur_line_num} Index: {self.index_into_cur_line} - Object does not have extensible fields but should. Likely a parsing error."
                    )
                    success[0] = False
                    return root

                size = len(legacy_idd_extensibles_iter)
                field_name = legacy_idd_extensibles_iter[extensible_index % size]
                val = self.parse_value(idf, index, success, schema_obj_extensions[field_name])

                if not success[0]:
                    return root

                extensible[field_name] = val
                was_value_parsed = True
                extensible_index += 1

                if extensible_index != 0 and extensible_index % size == 0:
                    array_of_extensions.append(extensible.copy())
                    extensible.clear()
            else:
                was_value_parsed = True
                field = legacy_idd_fields_array[legacy_idd_index]
                find_field_iter = schema_obj_props.get(field)

                if find_field_iter is None:
                    if field == "name":
                        root[field] = self.parse_string(idf, index)
                    else:
                        self.errors_.append(f'Line: {self.cur_line_num} - Field "{field}" was not found.')
                else:
                    val = self.parse_value(idf, index, success, find_field_iter)
                    if not success[0]:
                        return root
                    root[field] = val

                if not success[0]:
                    return root

        if array_of_extensions:
            root[extension_key] = array_of_extensions

        return root

    def parse_number(self, idf: str, index: List[int]) -> Union[int, float, str]:
        self.eat_whitespace(idf, index)

        save_i = index[0]
        running = True
        while running:
            if save_i == self.idf_size:
                break
            c = idf[save_i]
            if c in "!,;\r\n":
                running = False
            else:
                save_i += 1

        diff = save_i - index[0]
        value = idf[index[0] : save_i]
        self.index_into_cur_line += diff
        index[0] = save_i

        def convert_double(s: str) -> Union[float, str]:
            plus_sign = 0
            if s and s[0] == "+":
                plus_sign = 1
            try:
                val = float(s[plus_sign:])
                return val
            except ValueError:
                return self._rtrim(s)

        def convert_int(s: str) -> Union[int, float, str]:
            try:
                val = int(s)
                return val
            except ValueError:
                if "." in s or "e" in s or "E" in s:
                    return convert_double(s)
                return self._rtrim(s)

        return convert_int(value)

    def parse_integer(self, idf: str, index: List[int]) -> Union[int, str]:
        self.eat_whitespace(idf, index)

        save_i = index[0]
        running = True
        while running:
            if save_i == self.idf_size:
                break
            c = idf[save_i]
            if c in "!,;\r\n":
                running = False
            else:
                save_i += 1

        diff = save_i - index[0]
        string_value = idf[index[0] : save_i]
        self.index_into_cur_line += diff
        index[0] = save_i

        try:
            int_value = int(string_value)
            return int_value
        except ValueError:
            plus_sign = 0
            if string_value and string_value[0] == "+":
                plus_sign = 1
            try:
                double_value = float(string_value[plus_sign:])
                int_value = int(round(double_value))
                return int_value
            except ValueError:
                return self._rtrim(string_value)

    def parse_value(
        self,
        idf: str,
        index: List[int],
        success: List[bool],
        field_loc: Dict[str, Any],
    ) -> Union[str, int, float, None]:
        field_type = field_loc.get("type")
        if field_type is not None:
            if field_type == "number":
                token = Token.NUMBER
            elif field_type == "integer":
                token = Token.INTEGER
            else:
                token = Token.STRING
        else:
            token = self.look_ahead(idf, index[0])

        if token == Token.STRING:
            parsed_string = self.parse_string(idf, index)
            enum_it = field_loc.get("enum")
            if enum_it is not None:
                for enum_str in enum_it:
                    if self._icompare(enum_str, parsed_string):
                        return enum_str
            elif self._icompare(parsed_string, "Autosize") or self._icompare(
                parsed_string, "Autocalculate"
            ):
                default_it = field_loc.get("default")
                anyOf_it = field_loc.get("anyOf")

                if anyOf_it is None:
                    self.errors_.append(
                        f"Line: {self.cur_line_num} Index: {self.index_into_cur_line} - Field cannot be Autosize or Autocalculate"
                    )
                    return parsed_string

                if default_it is not None:
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

    def parse_string(self, idf: str, index: List[int]) -> str:
        self.eat_whitespace(idf, index)

        s = ""
        while True:
            if index[0] == self.idf_size:
                break

            c = idf[index[0]]
            self._increment_both_index(index)
            if c in ",;!":
                self._decrement_both_index(index)
                break
            s += c

        return self._rtrim(s)

    def _increment_both_index(self, index: List[int]) -> None:
        index[0] += 1
        self.index_into_cur_line += 1

    def _decrement_both_index(self, index: List[int]) -> None:
        index[0] -= 1
        self.index_into_cur_line -= 1

    def eat_whitespace(self, idf: str, index: List[int]) -> None:
        while index[0] < self.idf_size:
            c = idf[index[0]]
            if c in " \r\t":
                self._increment_both_index(index)
            elif c == "\n":
                self._increment_both_index(index)
                self.cur_line_num += 1
                self.beginning_of_line_index = index[0]
                self.index_into_cur_line = 0
            else:
                return

    def eat_comment(self, idf: str, index: List[int]) -> None:
        while True:
            if index[0] == self.idf_size:
                break
            if idf[index[0]] == "\n":
                self._increment_both_index(index)
                self.cur_line_num += 1
                self.index_into_cur_line = 0
                self.beginning_of_line_index = index[0]
                break
            self._increment_both_index(index)

    def look_ahead(self, idf: str, index: int) -> Token:
        save_index = index
        save_line_num = self.cur_line_num
        save_line_index = self.index_into_cur_line

        temp_index = [save_index]
        token = self.next_token(idf, temp_index)

        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index

        return token

    def next_token(self, idf: str, index: List[int]) -> Token:
        self.eat_whitespace(idf, index)

        if index[0] == self.idf_size:
            return Token.END

        c = idf[index[0]]
        self._increment_both_index(index)

        if c == "!":
            return Token.EXCLAMATION
        elif c == ",":
            return Token.COMMA
        elif c == ";":
            return Token.SEMICOLON
        else:
            numeric = ".-+0123456789"
            if c in numeric:
                return Token.NUMBER
            return Token.STRING

    def next_limited_token(self, idf: str, index: List[int]) -> Token:
        if index[0] == self.idf_size:
            return Token.END

        c = idf[index[0]]
        self._increment_both_index(index)

        if c == "!":
            return Token.EXCLAMATION
        elif c == ",":
            return Token.COMMA
        elif c == ";":
            return Token.SEMICOLON
        else:
            return Token.NONE

    @staticmethod
    def _rtrim(s: str) -> str:
        whitespace = " \t\0"
        if not s:
            return ""
        index = -1
        for i in range(len(s) - 1, -1, -1):
            if s[i] not in whitespace:
                index = i
                break
        if index == -1:
            return ""
        return s[: index + 1]

    @staticmethod
    def _convert_to_upper(s: str) -> str:
        return s.upper()

    @staticmethod
    def _icompare(a: str, b: str) -> bool:
        return len(a) == len(b) and a.lower() == b.lower()

    @staticmethod
    def _dtoa(val: float) -> str:
        return str(val)
