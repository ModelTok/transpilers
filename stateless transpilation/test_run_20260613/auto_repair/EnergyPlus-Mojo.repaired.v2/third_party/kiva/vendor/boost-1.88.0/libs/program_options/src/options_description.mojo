# BOOST_PROGRAM_OPTIONS_SOURCE guard: not needed in Mojo
# include <boost/program_options/config.hpp>
from boost.program_options.config import *
# include <boost/program_options/options_description.hpp>
from options_description import value_semantic, untyped_value, unknown_option, ambiguous_option, error, command_line_style
# include <boost/program_options/parsers.hpp>
from parsers import command_line_style
# include <boost/lexical_cast.hpp>  # not used, but import to satisfy includes
from boost.lexical_cast import *
# include <boost/tokenizer.hpp>
from boost.tokenizer import tokenizer, char_separator
# include <boost/detail/workaround.hpp>
from boost.detail.workaround import *
# include <boost/throw_exception.hpp>
from boost.throw_exception import throw_exception
# include <cassert>, <climits>, <cstring>, <cstdarg>, <sstream>, <iterator> – use Python equivalents
import sys
import math
from typing import Optional, Tuple, List, Iterator

# using namespace std; – drop, use Python builtins

# Helper string tolower
def tolower_(str_: String) -> String:
    result: String = ""
    for ch in str_:
        result += chr(ord(ch.lower()))  # simplified; Python's lower is unicode-safe
    return result

# Define a simple OStream class for output (mimics ostream)
class OStream:
    var buf: String = ""
    def __init__(self):
        self.buf = ""
    def write(self, s: String):
        self.buf += s
    def put(self, c: String):
        self.buf += c
    def str(self) -> String:
        return self.buf
    def __lshift__(self, other: object) -> 'OStream':
        self.write(str(other))
        return self

# Also define shared_ptr wrapper class (simplified, but structurally similar)
class SharedPtr[T]:
    var ptr: T = None
    def __init__(self, p: T):
        self.ptr = p
    def get(self) -> T:
        return self.ptr
    def __bool__(self) -> bool:
        return self.ptr is not None
    def __deref__(self) -> T:
        return self.ptr

# Forward declarations
class option_description:

class options_description_easy_init:

class options_description:

# Enum for match_result (simulated as int constants)
class match_result:
    no_match = 0
    full_match = 1
    approximate_match = 2

# ------------------------------------------------------------
# option_description class
class option_description:
    var m_description: String = ""
    var m_value_semantic: SharedPtr[value_semantic] = SharedPtr(None)
    var m_long_names: List[String] = List[String]()
    var m_short_name: String = ""

    def __init__(self):

    def __init__(self, names: String, s: value_semantic):
        self.m_value_semantic = SharedPtr(s)
        self.set_names(names)

    def __init__(self, names: String, s: value_semantic, description: String):
        self.m_description = description
        self.m_value_semantic = SharedPtr(s)
        self.set_names(names)

    def __del__(self):

    def match(self, option: String, approx: bool, long_ignore_case: bool, short_ignore_case: bool) -> int:
        result: int = match_result.no_match
        local_option: String = tolower_(option) if long_ignore_case else option
        for it in self.m_long_names:
            local_long_name: String = tolower_(it) if long_ignore_case else it
            if local_long_name != "":
                if (result == match_result.no_match) and (local_long_name[-1] == '*'):
                    if local_option.find(local_long_name[0:len(local_long_name)-1]) == 0:
                        result = match_result.approximate_match
                if local_long_name == local_option:
                    result = match_result.full_match
                    break
                elif approx:
                    if local_long_name.find(local_option) == 0:
                        result = match_result.approximate_match
        if result != match_result.full_match:
            local_short_name: String = tolower_(self.m_short_name) if short_ignore_case else self.m_short_name
            if local_short_name == local_option:
                result = match_result.full_match
        return result

    def key(self, option: String) -> String:
        if not self.m_long_names.is_empty():
            first_long_name: String = self.m_long_names[0]
            if first_long_name.find('*') != -1:
                return option
            else:
                return first_long_name
        else:
            return self.m_short_name

    def canonical_display_name(self, prefix_style: int) -> String:
        if not self.m_long_names.is_empty():
            if prefix_style == command_line_style.allow_long:
                return "--" + self.m_long_names[0]
            if prefix_style == command_line_style.allow_long_disguise:
                return "-" + self.m_long_names[0]
        if len(self.m_short_name) == 2:
            if prefix_style == command_line_style.allow_slash_for_short:
                return "/" + self.m_short_name[1]
            if prefix_style == command_line_style.allow_dash_for_short:
                return "-" + self.m_short_name[1]
        if not self.m_long_names.is_empty():
            return self.m_long_names[0]
        else:
            return self.m_short_name

    def long_name(self) -> String:
        empty_string: String = ""
        return empty_string if self.m_long_names.is_empty() else self.m_long_names[0]

    def long_names(self) -> Tuple[Optional[String], int]:
        if self.m_long_names.is_empty():
            return (None, 0)
        else:
            return (self.m_long_names[0], len(self.m_long_names))

    def set_names(self, _names: String) -> 'option_description':
        self.m_long_names = List[String]()
        # Simulate istringstream + getline
        names_list: List[String] = _names.split(',')
        for name in names_list:
            self.m_long_names.append(name)
        assert not self.m_long_names.is_empty() and "No option names were specified"
        try_interpreting_last_name_as_a_switch: bool = len(self.m_long_names) > 1
        if try_interpreting_last_name_as_a_switch:
            last_name: String = self.m_long_names[-1]
            if len(last_name) == 1:
                self.m_short_name = "-" + last_name
                self.m_long_names.pop()
                if len(self.m_long_names) == 1 and self.m_long_names[0] == "":
                    self.m_long_names = List[String]()
        return self

    def description(self) -> String:
        return self.m_description

    def semantic(self) -> SharedPtr[value_semantic]:
        return self.m_value_semantic

    def format_name(self) -> String:
        if not self.m_short_name.is_empty():
            if self.m_long_names.is_empty():
                return self.m_short_name
            else:
                return self.m_short_name + " [ --" + self.m_long_names[0] + " ]"
        return "--" + self.m_long_names[0]

    def format_parameter(self) -> String:
        if self.m_value_semantic.get().max_tokens() != 0:
            return self.m_value_semantic.get().name()
        else:
            return ""

# ------------------------------------------------------------
# options_description_easy_init class
class options_description_easy_init:
    var owner: options_description = None

    def __init__(self, owner: options_description):
        self.owner = owner

    def __call__(self, name: String, description: String) -> 'options_description_easy_init':
        d: SharedPtr[option_description] = SharedPtr(option_description(name, untyped_value(True), description))
        self.owner.add(d)
        return self

    def __call__(self, name: String, s: value_semantic) -> 'options_description_easy_init':
        d: SharedPtr[option_description] = SharedPtr(option_description(name, s))
        self.owner.add(d)
        return self

    def __call__(self, name: String, s: value_semantic, description: String) -> 'options_description_easy_init':
        d: SharedPtr[option_description] = SharedPtr(option_description(name, s, description))
        self.owner.add(d)
        return self

# ------------------------------------------------------------
# options_description class
class options_description:
    var m_default_line_length: int = 80
    var m_line_length: int = 80
    var m_min_description_length: int = 0
    var m_caption: String = ""
    var m_options: List[SharedPtr[option_description]] = List[SharedPtr[option_description]]()
    var belong_to_group: List[bool] = List[bool]()
    var groups: List[SharedPtr[options_description]] = List[SharedPtr[options_description]]()

    def __init__(self, line_length: int = 80, min_description_length: int = 0):
        self.m_line_length = line_length
        self.m_min_description_length = min_description_length
        assert self.m_min_description_length < self.m_line_length - 1

    def __init__(self, caption: String, line_length: int = 80, min_description_length: int = 0):
        self.m_caption = caption
        self.m_line_length = line_length
        self.m_min_description_length = min_description_length
        assert self.m_min_description_length < self.m_line_length - 1

    def add(self, desc: SharedPtr[option_description]):
        self.m_options.append(desc)
        self.belong_to_group.append(False)

    def add(self, desc: 'options_description') -> 'options_description':
        d: SharedPtr[options_description] = SharedPtr(options_description(desc))
        self.groups.append(d)
        for i in range(len(desc.m_options)):
            self.add(desc.m_options[i])
            self.belong_to_group[-1] = True
        return self

    def add_options(self) -> options_description_easy_init:
        return options_description_easy_init(self)

    def find(self, name: String, approx: bool = False, long_ignore_case: bool = False, short_ignore_case: bool = False) -> option_description:
        d: Optional[option_description] = self.find_nothrow(name, approx, long_ignore_case, short_ignore_case)
        if d is None:
            throw_exception(unknown_option())
        return d

    def options(self) -> List[SharedPtr[option_description]]:
        return self.m_options

    def find_nothrow(self, name: String, approx: bool = False, long_ignore_case: bool = False, short_ignore_case: bool = False) -> Optional[option_description]:
        found: Optional[option_description] = None
        had_full_match: bool = False
        approximate_matches: List[String] = List[String]()
        full_matches: List[String] = List[String]()
        for i in range(len(self.m_options)):
            r: int = self.m_options[i].get().match(name, approx, long_ignore_case, short_ignore_case)
            if r == match_result.no_match:
                continue
            if r == match_result.full_match:
                full_matches.append(self.m_options[i].get().key(name))
                found = self.m_options[i].get()
                had_full_match = True
            else:
                approximate_matches.append(self.m_options[i].get().key(name))
                if not had_full_match:
                    found = self.m_options[i].get()
        if len(full_matches) > 1:
            throw_exception(ambiguous_option(full_matches))
        if len(full_matches) == 0 and len(approximate_matches) > 1:
            throw_exception(ambiguous_option(approximate_matches))
        return found

    # Helper: format_paragraph
    @staticmethod
    def _format_paragraph(os: OStream, par: String, indent: int, line_length: int):
        assert indent < line_length
        line_length -= indent
        par_indent: int = par.find('\t')
        if par_indent == -1:
            par_indent = 0
        else:
            if par.count('\t') > 1:
                throw_exception(error("Only one tab per paragraph is allowed in the options description"))
            par = par[:par_indent] + par[par_indent+1:]  # erase tab
            assert par_indent < line_length
            if par_indent >= line_length:
                par_indent = 0
        if len(par) < line_length:
            os.write(par)
        else:
            line_begin: int = 0
            par_end: int = len(par)
            first_line: bool = True
            while line_begin < par_end:
                if not first_line:
                    if par[line_begin] == ' ' and (line_begin + 1 < par_end and par[line_begin + 1] != ' '):
                        line_begin += 1
                remaining: int = par_end - line_begin
                line_end: int = line_begin + (remaining if remaining < line_length else line_length)
                if par[line_end - 1] != ' ' and (line_end < par_end and par[line_end] != ' '):
                    last_space: int = par.rfind(' ', line_begin, line_end)
                    if last_space != -1 and (line_end - last_space < line_length // 2):
                        line_end = last_space
                # output line
                os.write(par[line_begin:line_end])
                if first_line:
                    indent += par_indent
                    line_length -= par_indent
                    first_line = False
                if line_end != par_end:
                    os.write('\n')
                    for _ in range(indent):
                        os.put(' ')
                line_begin = line_end

    # Helper: format_description
    @staticmethod
    def _format_description(os: OStream, desc: String, first_column_width: int, line_length: int):
        assert line_length > 1
        line_length -= 1
        assert line_length > first_column_width
        # Simulate tokenizer with char_separator for newline, keep_empty_tokens
        paragraphs: List[String] = desc.split('\n')
        # tokenizer would keep empty tokens; split already does
        par_iter: int = 0
        while par_iter < len(paragraphs):
            par: String = paragraphs[par_iter]
            options_description._format_paragraph(os, par, first_column_width, line_length)
            par_iter += 1
            if par_iter < len(paragraphs):
                os.write('\n')
                for _ in range(first_column_width):
                    os.put(' ')

    # Helper: format_one
    @staticmethod
    def _format_one(os: OStream, opt: option_description, first_column_width: int, line_length: int):
        ss: OStream = OStream()
        ss.write("  " + opt.format_name() + ' ' + opt.format_parameter())
        os.write(ss.str())
        if not opt.description().is_empty():
            if len(ss.str()) >= first_column_width:
                os.put('\n')
                for _ in range(first_column_width):
                    os.put(' ')
            else:
                for _ in range(first_column_width - len(ss.str())):
                    os.put(' ')
            options_description._format_description(os, opt.description(), first_column_width, line_length)

    def get_option_column_width(self) -> int:
        width: int = 23
        for i in range(len(self.m_options)):
            opt: option_description = self.m_options[i].get()
            ss: OStream = OStream()
            ss.write("  " + opt.format_name() + ' ' + opt.format_parameter())
            width = max(width, len(ss.str()))
        for j in range(len(self.groups)):
            width = max(width, self.groups[j].get().get_option_column_width())
        start_of_description_column: int = self.m_line_length - self.m_min_description_length
        width = min(width, start_of_description_column - 1)
        width += 1
        return width

    def print(self, os: OStream, width: int = 0):
        if not self.m_caption.is_empty():
            os.write(self.m_caption + ":\n")
        if width == 0:
            width = self.get_option_column_width()
        for i in range(len(self.m_options)):
            if self.belong_to_group[i]:
                continue
            opt: option_description = self.m_options[i].get()
            options_description._format_one(os, opt, width, self.m_line_length)
            os.write("\n")
        for j in range(len(self.groups)):
            os.write("\n")
            self.groups[j].get().print(os, width)

# Define operator<< overload (global function)
def operator_shift_left(os: OStream, desc: options_description) -> OStream:
    desc.print(os)
    return os

# BOOST_PROGRAM_OPTIONS_DECL macro (empty)
BOOST_PROGRAM_OPTIONS_DECL = ""