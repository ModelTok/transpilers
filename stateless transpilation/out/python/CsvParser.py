from enum import Enum
from typing import Tuple, List, Dict, Any, Optional

class Token(Enum):
    NONE = 0
    FILE_END = 1
    DELIMITER = 2
    LINE_END = 3
    VALUE = 4
    Num = 5


class CsvParser:
    def __init__(self):
        self.success: bool = False
        self.cur_line_num: int = 1
        self.index_into_cur_line: int = 0
        self.beginning_of_line_index: int = 0
        self.csv_size: int = 0
        self.delimiter: str = ','
        self.rows_to_skip: int = 0
        self.errors_: List[Tuple[str, bool]] = []
        self.warnings_: List[Tuple[str, bool]] = []

    def errors(self) -> List[Tuple[str, bool]]:
        return self.errors_

    def hasErrors(self) -> bool:
        return len(self.errors_) > 0

    def warnings(self) -> List[Tuple[str, bool]]:
        return self.warnings_

    def hasWarnings(self) -> bool:
        return len(self.warnings_) > 0

    def decode(self, csv: str, t_delimiter: str = ',', t_rows_to_skip: int = 0) -> Dict[str, Any]:
        if not csv:
            self.errors_.append(("CSV File is empty", False))
            self.success = False
            return None

        self.success = True
        self.cur_line_num = 1
        self.index_into_cur_line = 0
        self.beginning_of_line_index = 0
        self.delimiter = t_delimiter
        self.rows_to_skip = t_rows_to_skip
        self.csv_size = len(csv)

        index = [0]
        return self._parse_csv(csv, index)

    @staticmethod
    def _increment_both_index(index: List[int], line_index: List[int]) -> None:
        index[0] += 1
        line_index[0] += 1

    @staticmethod
    def _decrement_both_index(index: List[int], line_index: List[int]) -> None:
        index[0] -= 1
        line_index[0] -= 1

    def _skip_rows(self, csv: str, index: List[int]) -> None:
        rows_skipped = 0
        while True:
            token = self._next_token(csv, index)
            if token == Token.FILE_END:
                break
            if token == Token.LINE_END:
                rows_skipped += 1
                if rows_skipped == self.rows_to_skip:
                    break

    def _find_number_columns(self, csv: str, index: List[int]) -> int:
        prev_token: Optional[Token] = None
        num_columns = 0

        save_index = index[0]
        save_line_num = self.cur_line_num
        save_line_index = self.index_into_cur_line
        save_beginning_of_line_index = self.beginning_of_line_index

        temp_index = [save_index]
        while True:
            token = self._next_token(csv, temp_index)
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

    def _parse_csv(self, csv: str, index: List[int]) -> Dict[str, Any]:
        root: Dict[str, Any] = {"header": [], "values": []}
        check_first_row = True
        has_header = (self.rows_to_skip == 1)

        if self.csv_size > 3:
            if csv[0] == '\xEF' and csv[1] == '\xBB' and csv[2] == '\xBF':
                index[0] += 3
                self.index_into_cur_line += 3

        if self.rows_to_skip > 1:
            self._skip_rows(csv, index)

        header = root["header"]
        columns = root["values"]

        while True:
            if index[0] == self.csv_size:
                break

            if check_first_row:
                if has_header:
                    self._parse_header(csv, index, header)

                num_columns = self._find_number_columns(csv, index)
                check_first_row = False

                for _ in range(num_columns):
                    columns.append([])

                continue

            self._parse_line(csv, index, columns)
            if not self.success:
                break

        return root

    def _parse_header(self, csv: str, index: List[int], header: List[Any]) -> None:
        while True:
            token = self._look_ahead(csv, index[0])
            if token == Token.LINE_END or token == Token.FILE_END:
                self._next_token(csv, index)
                return
            if token == Token.DELIMITER:
                self._next_token(csv, index)
            else:
                header.append(self._parse_value(csv, index))

    def _parse_line(self, csv: str, index: List[int], columns: List[List[Any]]) -> None:
        column_num = 0
        parsed_values = 0
        num_columns = len(columns)

        has_extra_columns = False

        this_cur_line_num = self.cur_line_num
        this_beginning_of_line_index = self.beginning_of_line_index

        def get_current_line() -> str:
            found_index = csv.find('\n', this_beginning_of_line_index)
            if found_index != -1:
                end = found_index
                if end > this_beginning_of_line_index and csv[end - 1] == '\r':
                    end -= 1
                return csv[this_beginning_of_line_index:end]
            return ""

        while True:
            token = self._look_ahead(csv, index[0])
            if token == Token.LINE_END or token == Token.FILE_END:
                if has_extra_columns:
                    self.warnings_.append(
                        (f"CsvParser - Line {this_cur_line_num} - Expected {num_columns} columns, got {parsed_values}. Ignored extra columns. Error in following line.", False)
                    )
                    self.warnings_.append((get_current_line(), True))
                elif parsed_values != num_columns:
                    found_index = csv.find('\n', this_beginning_of_line_index)
                    if found_index == -1:
                        found_index = self.csv_size

                    line = ""
                    if found_index != -1 and found_index > this_beginning_of_line_index:
                        end = found_index
                        if end > this_beginning_of_line_index and csv[end - 1] == '\r':
                            end -= 1
                        line = csv[this_beginning_of_line_index:end]

                    last_line = False
                    if token == Token.FILE_END or (found_index + 1 == self.csv_size) or (found_index + 2 == self.csv_size):
                        last_line = True

                    if line or not last_line:
                        self.success = False
                        self.errors_.append(
                            (f"CsvParser - Line {this_cur_line_num} - Expected {num_columns} columns, got {parsed_values}. Error in following line.", False)
                        )
                        self.errors_.append((line, True))

                self._next_token(csv, index)
                return

            if token == Token.DELIMITER:
                self._next_token(csv, index)
                token = self._look_ahead(csv, index[0])
                if token == Token.DELIMITER:
                    next_col = column_num + 1
                    if next_col < num_columns:
                        columns[next_col].append(None)
                        self.warnings_.append(
                            (f"CsvParser - Line {this_cur_line_num} Column {next_col + 1} - Blank value found, setting to null. Error in following line.", False)
                        )
                        self.warnings_.append((get_current_line(), True))
                    else:
                        has_extra_columns = True
                    parsed_values += 1
                column_num += 1
            else:
                if column_num < num_columns:
                    columns[column_num].append(self._parse_value(csv, index))
                else:
                    self._parse_value(csv, index)
                    has_extra_columns = True
                parsed_values += 1

    def _parse_value(self, csv: str, index: List[int]) -> Any:
        self._eat_whitespace(csv, index)

        save_i = index[0]

        while True:
            if save_i == self.csv_size:
                break

            c = csv[save_i]
            if c == self.delimiter or c == '\n' or c == '\r':
                break
            save_i += 1

        diff = save_i - index[0]
        value = csv[index[0]:save_i]
        self.index_into_cur_line += diff
        index[0] = save_i

        if not value:
            return self._rtrim(value)

        plus_sign = 0
        if value[0] == '+':
            plus_sign = 1

        value_to_parse = value[plus_sign:]

        try:
            val = float(value_to_parse)
            # Check if there's trailing non-space content after the parsed number
            # For simplicity, accept the float if parsing succeeded
            return val
        except ValueError:
            return self._rtrim(value)

    def _look_ahead(self, csv: str, index: int) -> Token:
        save_index = index
        save_line_num = self.cur_line_num
        save_line_index = self.index_into_cur_line
        save_beginning_of_line_index = self.beginning_of_line_index

        temp_index = [save_index]
        token = self._next_token(csv, temp_index)

        self.cur_line_num = save_line_num
        self.index_into_cur_line = save_line_index
        self.beginning_of_line_index = save_beginning_of_line_index

        return token

    def _next_token(self, csv: str, index: List[int]) -> Token:
        self._eat_whitespace(csv, index)

        if index[0] == self.csv_size:
            return Token.FILE_END

        c = csv[index[0]]
        if c == self.delimiter:
            index[0] += 1
            self.index_into_cur_line += 1
            return Token.DELIMITER
        if c == '\n':
            index[0] += 1
            self.cur_line_num += 1
            self.beginning_of_line_index = index[0]
            self.index_into_cur_line = 0
            return Token.LINE_END

        index[0] += 1
        self.index_into_cur_line += 1
        return Token.VALUE

    @staticmethod
    def _rtrim(s: str) -> str:
        whitespace = " \t"
        if not s:
            return s
        index = -1
        for i in range(len(s) - 1, -1, -1):
            if s[i] not in whitespace:
                index = i
                break
        if index == -1:
            return ""
        return s[:index + 1]

    def _eat_whitespace(self, csv: str, index: List[int]) -> None:
        while index[0] < self.csv_size:
            c = csv[index[0]]
            if (self.delimiter != ' ' and c == ' ') or (self.delimiter != '\t' and c == '\t') or c == '\r':
                index[0] += 1
                self.index_into_cur_line += 1
                continue
            return

    @staticmethod
    def _convert_to_upper(s: str) -> str:
        result = []
        for c in s:
            if 'a' <= c <= 'z':
                result.append(chr(ord(c) ^ 0x20))
            else:
                result.append(c)
        return ''.join(result)
