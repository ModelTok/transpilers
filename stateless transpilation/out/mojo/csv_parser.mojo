from collections import Dict, List
from enum import Enum
from math import isnan


@value
struct Token(EqualityComparable):
    var value: UInt32

    alias NONE = Token(0)
    alias FILE_END = Token(1)
    alias DELIMITER = Token(2)
    alias LINE_END = Token(3)
    alias VALUE = Token(4)
    alias Num = Token(5)

    fn __eq__(self, other: Token) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Token) -> Bool:
        return self.value != other.value


struct CsvParser:
    var success: Bool
    var cur_line_num: Int
    var index_into_cur_line: Int
    var beginning_of_line_index: Int
    var csv_size: Int
    var delimiter: String
    var rows_to_skip: Int
    var errors_: List[Tuple[String, Bool]]
    var warnings_: List[Tuple[String, Bool]]

    fn __init__(inout self):
        self.success = False
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.csv_size = 0
        self.delimiter = ","
        self.rows_to_skip = 0
        self.errors_ = List[Tuple[String, Bool]]()
        self.warnings_ = List[Tuple[String, Bool]]()

    fn errors(self) -> List[Tuple[String, Bool]]:
        return self.errors_

    fn hasErrors(self) -> Bool:
        return len(self.errors_) > 0

    fn warnings(self) -> List[Tuple[String, Bool]]:
        return self.warnings_

    fn hasWarnings(self) -> Bool:
        return len(self.warnings_) > 0

    fn decode(
        inout self, csv: String, t_delimiter: String = ",", t_rows_to_skip: Int = 0
    ) -> Dict[String, List]:
        if len(csv) == 0:
            self.errors_.append((String("CSV File is empty"), False))
            self.success = False
            return Dict[String, List]()

        self.success = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.delimiter = t_delimiter
        self.rows_to_skip = t_rows_to_skip
        self.csv_size = len(csv)

        var index: Int = 0
        return self._parse_csv(csv, index)

    @staticmethod
    fn _increment_both_index(inout index: Int, inout line_index: Int) -> None:
        index += 1
        line_index += 1

    @staticmethod
    fn _decrement_both_index(inout index: Int, inout line_index: Int) -> None:
        index -= 1
        line_index -= 1

    fn _skip_rows(inout self, csv: String, inout index: Int) -> None:
        var rows_skipped: Int = 0
        while True:
            var token = self._next_token(csv, index)
            if token == Token.FILE_END:
                break
            if token == Token.LINE_END:
                rows_skipped += 1
                if rows_skipped == self.rows_to_skip:
                    break

    fn _find_number_columns(inout self, csv: String, inout index: Int) -> Int:
        var prev_token: Token = Token.NONE
        var num_columns: Int = 0

        var save_index: Int = index
        var save_line_num: Int = self.cur_line_num
        var save_line_index: Int = self.index_into_cur_line
        var save_beginning_of_line_index: Int = self.beginning_of_line_index

        var temp_index: Int = save_index
        while True:
            var token = self._next_token(csv, temp_index)
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

    fn _parse_csv(inout self, csv: String, inout index: Int) -> Dict[String, List]:
        var root = Dict[String, List]()
        var header = List()
        var columns = List()
        root["header"] = header
        root["values"] = columns

        var check_first_row: Bool = True
        var has_header: Bool = self.rows_to_skip == 1

        if self.csv_size > 3:
            if (
                ord(csv[0]) == 0xEF
                and ord(csv[1]) == 0xBB
                and ord(csv[2]) == 0xBF
            ):
                index += 3
                self.index_into_cur_line += 3

        if self.rows_to_skip > 1:
            self._skip_rows(csv, index)

        while True:
            if index == self.csv_size:
                break

            if check_first_row:
                if has_header:
                    self._parse_header(csv, index, header)

                var num_columns: Int = self._find_number_columns(csv, index)
                check_first_row = False

                for _ in range(num_columns):
                    columns.append(List())

                continue

            self._parse_line(csv, index, columns)
            if not self.success:
                break

        return root

    fn _parse_header(
        inout self, csv: String, inout index: Int, inout header: List
    ) -> None:
        while True:
            var token = self._look_ahead(csv, index)
            if token == Token.LINE_END or token == Token.FILE_END:
                self._next_token(csv, index)
                return
            if token == Token.DELIMITER:
                self._next_token(csv, index)
            else:
                var value = self._parse_value(csv, index)
                header.append(value)

    fn _parse_line(
        inout self, csv: String, inout index: Int, inout columns: List
    ) -> None:
        var column_num: Int = 0
        var parsed_values: Int = 0
        var num_columns: Int = len(columns)

        var has_extra_columns: Bool = False

        var this_cur_line_num: Int = self.cur_line_num
        var this_beginning_of_line_index: Int = self.beginning_of_line_index

        while True:
            var token = self._look_ahead(csv, index)
            if token == Token.LINE_END or token == Token.FILE_END:
                if has_extra_columns:
                    var msg = String("CsvParser - Line ")
                    msg += String(this_cur_line_num)
                    msg += String(
                        " - Expected " + String(num_columns) + " columns, got "
                        + String(parsed_values)
                        + ". Ignored extra columns. Error in following line."
                    )
                    self.warnings_.append((msg, False))
                    # TODO: append current line
                elif parsed_values != num_columns:
                    var found_index: Int = -1
                    for i in range(
                        this_beginning_of_line_index, len(csv)
                    ):
                        if csv[i] == "\n":
                            found_index = i
                            break

                    var line: String = String()
                    if found_index != -1 and found_index > this_beginning_of_line_index:
                        var end: Int = found_index
                        if end > this_beginning_of_line_index and csv[end - 1] == "\r":
                            end -= 1
                        line = csv[this_beginning_of_line_index : end]

                    var last_line: Bool = False
                    if (
                        token == Token.FILE_END
                        or (found_index + 1 == self.csv_size)
                        or (found_index + 2 == self.csv_size)
                    ):
                        last_line = True

                    if len(line) > 0 or not last_line:
                        self.success = False
                        var msg = String("CsvParser - Line ")
                        msg += String(this_cur_line_num)
                        msg += String(
                            " - Expected " + String(num_columns) + " columns, got "
                            + String(parsed_values)
                            + ". Error in following line."
                        )
                        self.errors_.append((msg, False))
                        self.errors_.append((line, True))

                self._next_token(csv, index)
                return

            if token == Token.DELIMITER:
                self._next_token(csv, index)
                token = self._look_ahead(csv, index)
                if token == Token.DELIMITER:
                    var next_col: Int = column_num + 1
                    if next_col < num_columns:
                        var col_list = columns[next_col]
                        col_list.append(None)
                        var msg = String("CsvParser - Line ")
                        msg += String(this_cur_line_num)
                        msg += String(" Column ")
                        msg += String(next_col + 1)
                        msg += String(
                            " - Blank value found, setting to null. Error in following line."
                        )
                        self.warnings_.append((msg, False))
                        # TODO: append current line
                    else:
                        has_extra_columns = True
                    parsed_values += 1
                column_num += 1
            else:
                if column_num < num_columns:
                    var value = self._parse_value(csv, index)
                    var col_list = columns[column_num]
                    col_list.append(value)
                else:
                    self._parse_value(csv, index)
                    has_extra_columns = True
                parsed_values += 1

    fn _parse_value(inout self, csv: String, inout index: Int) -> String | Float64:
        self._eat_whitespace(csv, index)

        var save_i: Int = index

        while True:
            if save_i == self.csv_size:
                break

            var c: String = csv[save_i]
            if c == self.delimiter or c == "\n" or c == "\r":
                break
            save_i += 1

        var diff: Int = save_i - index
        var value: String = csv[index : save_i]
        self.index_into_cur_line += diff
        index = save_i

        if len(value) == 0:
            return self._rtrim(value)

        var plus_sign: Int = 0
        if value[0] == "+":
            plus_sign = 1

        var value_to_parse: String = value[plus_sign : len(value)]

        try:
            var val: Float64 = atof(value_to_parse)
            return val
        except:
            return self._rtrim(value)

    fn _look_ahead(inout self, csv: String, index: Int) -> Token:
        var save_index: Int = index
        var save_line_num: Int = self.cur_line_num
        var save_line_index: Int = self.index_into_cur_line
        var save_beginning_of_line_index: Int = self.beginning_of_line_index

        var temp_index: Int = save_index
        var token = self._next_token(csv, temp_index)

        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index
        self.beginning_of_line_index = save_beginning_of_line_index

        return token

    fn _next_token(inout self, csv: String, inout index: Int) -> Token:
        self._eat_whitespace(csv, index)

        if index == self.csv_size:
            return Token.FILE_END

        var c: String = csv[index]
        if c == self.delimiter:
            index += 1
            self.index_into_cur_line += 1
            return Token.DELIMITER
        if c == "\n":
            index += 1
            self.cur_line_num += 1
            self.beginning_of_line_index = index
            self.index_into_cur_line = 0
            return Token.LINE_END

        index += 1
        self.index_into_cur_line += 1
        return Token.VALUE

    @staticmethod
    fn _rtrim(s: String) -> String:
        if len(s) == 0:
            return s
        var index: Int = -1
        for i in range(len(s) - 1, -1, -1):
            if s[i] != " " and s[i] != "\t":
                index = i
                break
        if index == -1:
            return String()
        return s[0 : index + 1]

    fn _eat_whitespace(inout self, csv: String, inout index: Int) -> None:
        while index < self.csv_size:
            var c: String = csv[index]
            if (
                (self.delimiter != " " and c == " ")
                or (self.delimiter != "\t" and c == "\t")
                or c == "\r"
            ):
                index += 1
                self.index_into_cur_line += 1
                continue
            return

    @staticmethod
    fn _convert_to_upper(s: String) -> String:
        var result: List[String] = List[String]()
        for c in s:
            if c >= "a" and c <= "z":
                var code: Int = ord(c)
                result.append(chr(code ^ 0x20))
            else:
                result.append(c)
        var out: String = String()
        for item in result:
            out += item
        return out
