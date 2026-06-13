from stdlib import (
    JSON,
    JSONArray,
    JSONObject,
    JSONNull,
    JSONNumber,
    JSONString,
    JSONBool,
    Float64,
    String,
    StringRef,
    List,
    Tuple,
    Dict,
    UInt,
    Int,
    UInt8,
    Error,
    hasattr,
)
from math import is_nan

alias size_t = Int

struct from_chars_result:
    var ec: errc
    var ptr: Int

enum errc:
    invalid_argument
    result_out_of_range

struct json:
    var inner: JSON

    def __init__(inout self, val: JSON):
        self.inner = val

    @staticmethod
    def array() -> json:
        return json(JSON([]))

    @staticmethod
    def value_t() -> ValueType:
        return ValueType()

    struct ValueType:
        var null: json = json(JSONNull())

    def __getitem__(self, key: String) -> json:
        if self.inner.is_object():
            return json(self.inner.get(key))
        else:
            return json(JSONNull())

    def __setitem__(inout self, key: String, val: json):
        if self.inner.is_object():
            self.inner.set(key, val.inner)
        else:
            self.inner = JSONObject({key: val.inner})

    def __getitem__(self, index: Int) -> json:
        if self.inner.is_array():
            return json(self.inner[index])
        else:
            return json(JSONNull())

    def __setitem__(inout self, index: Int, val: json):
        if self.inner.is_array():
            self.inner[index] = val.inner

    def push_back(inout self, val: json):
        if not self.inner.is_array():
            self.inner = JSON([])
        self.inner.push_back(val.inner)

    def size(self) -> Int:
        if self.inner.is_array():
            return self.inner.length()
        else:
            return 0

    def at(self, index: Int) -> json:
        return self[index]

    def is_array(self) -> Bool:
        return self.inner.is_array()

    def is_object(self) -> Bool:
        return self.inner.is_object()

    def is_null(self) -> Bool:
        return self.inner.is_null()

    def emplace_back(inout self, val: json):
        self.push_back(val)

    @staticmethod
    def null() -> json:
        return json(JSONNull())

def json_array() -> json:
    return json.array()

struct CsvParser:
    friend class EnergyPlus_InputProcessorFixture

    alias json = json

    var success: Bool = False
    var cur_line_num: size_t = 1
    var index_into_cur_line: size_t = 0
    var beginning_of_line_index: size_t = 0
    var csv_size: size_t = 0
    var delimiter: UInt8 = ord(',')
    var rows_to_skip: Int = 0
    var s: StaticTuple[129, UInt8] = StaticTuple[129, UInt8]()
    var errors_: List[Tuple[String, Bool]] = List[Tuple[String, Bool]]()
    var warnings_: List[Tuple[String, Bool]] = List[Tuple[String, Bool]]()

    def __init__(inout self):

    def errors(self) -> ref[List[Tuple[String, Bool]]]:
        return self.errors_

    def hasErrors(self) -> Bool:
        return not self.errors_.is_empty()

    def warnings(self) -> ref[List[Tuple[String, Bool]]]:
        return self.warnings_

    def hasWarnings(self) -> Bool:
        return not self.warnings_.is_empty()

    def decode(inout self, csv: String, t_delimiter: UInt8 = ord(','), t_rows_to_skip: Int = 0) -> json:
        if csv.is_empty():
            self.errors_.append(("CSV File is empty", False))
            self.success = False
            return json.null()
        self.success = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.delimiter = t_delimiter
        self.rows_to_skip = t_rows_to_skip
        self.csv_size = csv.length()
        var index: size_t = 0
        return self.parse_csv(csv, index)

    def skip_rows(inout self, csv: String, inout index: size_t):
        var token: Token
        var rows_skipped: Int = 0
        while True:
            token = self.next_token(csv, index)
            if token == Token.FILE_END:
                break
            if token == Token.LINE_END:
                rows_skipped += 1
                if rows_skipped == self.rows_to_skip:
                    break

    def find_number_columns(inout self, csv: String, inout index: size_t) -> Int:
        var token: Token
        var prev_token: Token
        var num_columns: Int = 0
        var save_index: size_t = index
        var save_line_num: size_t = self.cur_line_num
        var save_line_index: size_t = self.index_into_cur_line
        var save_beginning_of_line_index: size_t = self.beginning_of_line_index
        while True:
            token = self.next_token(csv, save_index)
            if token == Token.FILE_END:
                break
            if token == Token.DELIMITER:
                num_columns += 1
            elif token == Token.LINE_END:
                if prev_token != Token.DELIMITER:
                    num_columns += 1
                break
            prev_token = token
        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index
        self.beginning_of_line_index = save_beginning_of_line_index
        return num_columns

    def parse_csv(inout self, csv: String, inout index: size_t) -> json:
        var root = json(JSON({"header": json.array(), "values": json.array()}))
        var check_first_row: Bool = True
        var has_header: Bool = (self.rows_to_skip == 1)
        const reservedSize: size_t = 8764 * 4
        if self.csv_size > 3:
            if csv[0] == '\xEF' and csv[1] == '\xBB' and csv[2] == '\xBF':
                index += 3
                self.index_into_cur_line += 3
        if self.rows_to_skip > 1:
            self.skip_rows(csv, index)
        var header = root["header"]
        var columns = root["values"]
        while True:
            if index == self.csv_size:
                break
            if check_first_row:
                if has_header:
                    self.parse_header(csv, index, header)
                var num_columns = self.find_number_columns(csv, index)
                check_first_row = False
                for i in range(num_columns):
                    var arr = List[json]()  # (THIS_AUTO_OK)
                    # arr.reserve(reservedSize) # Mojo List does not have reserve
                    columns.push_back(json(JSON(arr)))
                continue
            self.parse_line(csv, index, columns)
            if not self.success:
                break # Bail early
        return root

    def parse_header(inout self, csv: String, inout index: size_t, inout header: json):
        var token: Token
        while True:
            token = self.look_ahead(csv, index)
            if token == Token.LINE_END or token == Token.FILE_END:
                self.next_token(csv, index)
                return
            if token == Token.DELIMITER:
                self.next_token(csv, index)
            else:
                header.push_back(self.parse_value(csv, index))

    def parse_line(inout self, csv: String, inout index: size_t, inout columns: json):
        var token: Token
        var column_num: size_t = 0
        var parsed_values: Int = 0
        var num_columns: Int = columns.size() # Csv isn't empty, so we know it's at least 1
        var has_extra_columns: Bool = False
        var this_cur_line_num: size_t = self.cur_line_num
        var this_beginning_of_line_index: size_t = self.beginning_of_line_index
        var getCurrentLine = fn() -> String:
            var found_index: Int = csv.find_first_of("\r\n", this_beginning_of_line_index)
            var line: String
            if found_index != -1:
                line = csv[this_beginning_of_line_index: found_index]
            return line
        while True:
            token = self.look_ahead(csv, index)
            if token == Token.LINE_END or token == Token.FILE_END:
                if has_extra_columns:
                    self.warnings_.append(
                        (String("CsvParser - Line {} - Expected {} columns, got {}. Ignored extra columns. Error in following line.").format(
                            this_cur_line_num, num_columns, parsed_values),
                         False))
                    self.warnings_.append((getCurrentLine(), True))
                elif parsed_values != num_columns:
                    var found_index: Int = csv.find_first_of("\r\n", this_beginning_of_line_index)
                    var line: String
                    if found_index != -1:
                        line = csv[this_beginning_of_line_index: found_index]
                    var last_line: Bool = False
                    if token == Token.FILE_END or (found_index + 1 == self.csv_size) or (found_index + 2 == self.csv_size):
                        last_line = True
                    if not line.is_empty() or not last_line:
                        self.success = False
                        self.errors_.append(
                            (String("CsvParser - Line {} - Expected {} columns, got {}. Error in following line.").format(
                                this_cur_line_num, num_columns, parsed_values),
                             False))
                        self.errors_.append((line, True))
                self.next_token(csv, index)
                return
            if token == Token.DELIMITER:
                self.next_token(csv, index)
                token = self.look_ahead(csv, index)
                if token == Token.DELIMITER:
                    var next_col: size_t = column_num + 1
                    if next_col < num_columns:
                        columns.at(next_col).push_back(json.value_t().null)  # push null
                        self.warnings_.append(
                            (String("CsvParser - Line {} Column {} - Blank value found, setting to null. Error in following line.").format(
                                this_cur_line_num, next_col + 1),
                             False))
                        self.warnings_.append((getCurrentLine(), True))
                    else:
                        has_extra_columns = True
                    parsed_values += 1
                column_num += 1
            else:
                if column_num < num_columns:
                    columns.at(column_num).push_back(self.parse_value(csv, index))
                else:
                    self.parse_value(csv, index)
                    has_extra_columns = True
                parsed_values += 1

    def parse_value(inout self, csv: String, inout index: size_t) -> json:
        self.eat_whitespace(csv, index)
        var save_i: size_t = index
        while True:
            if save_i == self.csv_size:
                break
            var c: UInt8 = csv[save_i]
            if c == self.delimiter or c == ord('\n') or c == ord('\r'):
                break
            save_i += 1
        var diff: size_t = save_i - index
        var value: String = csv[index: save_i]
        self.index_into_cur_line += diff
        index = save_i
        var plus_sign: size_t = 0
        if value[0] == ord('+'):
            plus_sign = 1
        var value_end: Int = value.data() + value.length() # have to do this for MSVC // (AUTO_OK_ITER)
        var val: Float64 = 0.0
        var result = self.from_chars(value, plus_sign, value_end, val)
        if result.ec == errc.invalid_argument or result.ec == errc.result_out_of_range:
            return json(JSONString(self.rtrim(value)))
        if result.ptr != value_end:
            var initial_ptr: Int = result.ptr # (THIS_AUTO_OK)
            while self.delimiter != ord(' ') and result.ptr != value_end:
                if csv[result.ptr] != ord(' '):
                    break
                result.ptr += 1
            if result.ptr == value_end:
                index -= (value_end - initial_ptr)
                self.index_into_cur_line -= (value_end - initial_ptr)
                return json(JSONNumber(val))
            return json(JSONString(self.rtrim(value)))
        return json(JSONNumber(val))

    def look_ahead(inout self, csv: String, index: size_t) -> Token:
        var save_index: size_t = index
        var save_line_num: size_t = self.cur_line_num
        var save_line_index: size_t = self.index_into_cur_line
        var save_beginning_of_line_index: size_t = self.beginning_of_line_index
        var token: Token = self.next_token(csv, save_index)
        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index
        self.beginning_of_line_index = save_beginning_of_line_index
        return token

    def next_token(inout self, csv: String, inout index: size_t) -> Token:
        self.eat_whitespace(csv, index)
        if index == self.csv_size:
            return Token.FILE_END
        var c: UInt8 = csv[index]
        if c == self.delimiter:
            self.increment_both_index(index, self.index_into_cur_line)
            return Token.DELIMITER
        if c == ord('\n'):
            self.increment_both_index(index, self.cur_line_num)
            self.beginning_of_line_index = index
            self.index_into_cur_line = 0
            return Token.LINE_END
        self.increment_both_index(index, self.index_into_cur_line)
        return Token.VALUE

    def rtrim(self, str: String) -> String:
        const whitespace: String = " \t"
        if str.is_empty():
            return str
        var index: Int = str.find_last_not_of(whitespace)
        if index == -1:
            str = str[0:0]
            return str
        if index + 1 < str.length():
            return str[0: index + 1]
        return str

    @staticmethod
    def increment_both_index(inout index: size_t, inout line_index: size_t):
        index += 1
        line_index += 1

    @staticmethod
    def decrement_both_index(inout index: size_t, inout line_index: size_t):
        index -= 1
        line_index -= 1

    def eat_whitespace(inout self, csv: String, inout index: size_t):
        while index < self.csv_size:
            var ch: UInt8 = csv[index]
            if (self.delimiter != ord(' ') and ch == ord(' ')) or (self.delimiter != ord('\t') and ch == ord('\t')) or ch == ord('\r'):
                self.increment_both_index(index, self.index_into_cur_line)
                continue
            return

    def from_chars(self, s: String, plus_sign: size_t, end: Int, out val: Float64) -> from_chars_result:
        # Simple conversion using Float64.parse
        var substr: String = s[plus_sign: s.length()] if plus_sign > 0 else s
        var converted: Float64 = 0.0
        var remaining: String = ""
        var ok: Bool = Float64.parse(substr, converted, remaining)
        if not ok:
            return from_chars_result(errc.invalid_argument, 0)
        if not remaining.is_empty():
            # partial conversion
            val = converted
            return from_chars_result(errc(), plus_sign + (substr.length() - remaining.length()))
        else:
            val = converted
            return from_chars_result(errc(), end)

    # static method
    @staticmethod
    def convertToUpper(str: String) -> String:
        var len: size_t = str.length()
        var result: String = str
        for i in range(len):
            var c: UInt8 = str[i]
            var new_c: UInt8 = c
            if ord('a') <= c and c <= ord('z'):
                new_c = c ^ 0x20
            result[i] = new_c
        return result

enum Token: size_t:
    NONE
    FILE_END
    DELIMITER
    LINE_END
    VALUE
    Num

# Helper to create a JSON object from literal
def json_object(lit: Dict[String, json]) -> json:
    return json(JSON(lit))