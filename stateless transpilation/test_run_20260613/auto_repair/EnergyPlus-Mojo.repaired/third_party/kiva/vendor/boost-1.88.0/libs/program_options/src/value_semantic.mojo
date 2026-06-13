# Mojo translation of value_semantic.cpp
# No direct equivalent of BOOST_PROGRAM_OPTIONS_SOURCE guard - assume always defined
# config, value_semantic, convert, cmdline headers are imported from corresponding .mojo files
from boost.program_options.config import *
from boost.program_options.value_semantic import *
from boost.program_options.detail.convert import *
from boost.program_options.detail.cmdline import *
from cctype import *
# BOOST_NO_STD_WSTRING not defined in Mojo - assume wstring support present

namespace boost:
    namespace program_options:
        # using namespace std; - implicit in Mojo? skip

        # Helper function for wstring conversion
        def convert_value(s: std.std_wstring) -> std.std_string:
            try:
                return to_local_8_bit(s)
            except std.std_exception:
                return "<unrepresentable unicode string>"

        # value_semantic_codecvt_helper<char>
        def parse(self: value_semantic_codecvt_helper[std.std_string], value_store: inout any, new_tokens: std.std_vector[std.std_string], utf8: bool) raises:
            if utf8:
                var local_tokens: std.std_vector[std.std_string] = std.std_vector[std.std_string]()
                for i in range(new_tokens.size()):
                    let w: std.std_wstring = from_utf8(new_tokens[i])
                    local_tokens.push_back(to_local_8_bit(w))
                xparse(self, value_store, local_tokens)
            else:
                xparse(self, value_store, new_tokens)

        # value_semantic_codecvt_helper<wchar_t>
        def parse(self: value_semantic_codecvt_helper[std.std_wstring], value_store: inout any, new_tokens: std.std_vector[std.std_string], utf8: bool) raises:
            var tokens: std.std_vector[std.std_wstring] = std.std_vector[std.std_wstring]()
            if utf8:
                for i in range(new_tokens.size()):
                    tokens.push_back(from_utf8(new_tokens[i]))
            else:
                for i in range(new_tokens.size()):
                    tokens.push_back(from_local_8_bit(new_tokens[i]))
            xparse(self, value_store, tokens)

        var arg: std.std_string = "arg"

        def name(self: untyped_value) -> std.std_string:
            return arg

        def min_tokens(self: untyped_value) -> std_unsigned_int:
            if m_zero_tokens:
                return 0
            else:
                return 1

        def max_tokens(self: untyped_value) -> std_unsigned_int:
            if m_zero_tokens:
                return 0
            else:
                return 1

        def xparse(self: untyped_value, value_store: inout any, new_tokens: std.std_vector[std.std_string]) raises:
            if not value_store.empty():
                boost.throw_exception(multiple_occurrences())
            if new_tokens.size() > 1:
                boost.throw_exception(multiple_values())
            if new_tokens.empty():
                value_store = any("")
            else:
                value_store = any(new_tokens.front())

        def bool_switch() -> typed_value[bool]*:
            return bool_switch(0)

        def bool_switch(v: bool*) -> typed_value[bool]*:
            let r: typed_value[bool]* = typed_value[bool](v)
            r.default_value(0)
            r.zero_tokens()
            return r

        def validate(v: inout any, xs: std.std_vector[std.std_string], # unused: bool*, # unused: int) raises:
            check_first_occurrence(v)
            var s: std.std_string = get_single_string(xs, true)
            for i in range(s.size()):
                s[i] = char(tolower(s[i]))
            if s.empty() or s == "on" or s == "yes" or s == "1" or s == "true":
                v = any(true)
            elif s == "off" or s == "no" or s == "0" or s == "false":
                v = any(false)
            else:
                boost.throw_exception(invalid_bool_value(s))

        def validate(v: inout any, xs: std.std_vector[std.std_wstring], # unused: bool*, # unused: int) raises:
            check_first_occurrence(v)
            var s: std.std_wstring = get_single_string(xs, true)
            for i in range(s.size()):
                s[i] = wchar_t(tolower(s[i]))
            if s.empty() or s == L"on" or s == L"yes" or s == L"1" or s == L"true":
                v = any(true)
            elif s == L"off" or s == L"no" or s == L"0" or s == L"false":
                v = any(false)
            else:
                boost.throw_exception(invalid_bool_value(convert_value(s)))

        def validate(v: inout any, xs: std.std_vector[std.std_string], # unused: std.string*, # unused: int) raises:
            check_first_occurrence(v)
            v = any(get_single_string(xs))

        def validate(v: inout any, xs: std.std_vector[std.std_wstring], # unused: std.string*, # unused: int) raises:
            check_first_occurrence(v)
            v = any(get_single_string(xs))

        namespace validators:
            def check_first_occurrence(value: any) raises:
                if not value.empty():
                    boost.throw_exception(multiple_occurrences())

        def invalid_option_value(bad_value: std.std_string) -> invalid_option_value:
            let result: invalid_option_value = invalid_option_value(validation_error.invalid_option_value)
            result.set_substitute("value", bad_value)
            return result

        def invalid_option_value(bad_value: std.std_wstring) -> invalid_option_value:
            let result: invalid_option_value = invalid_option_value(validation_error.invalid_option_value)
            result.set_substitute("value", convert_value(bad_value))
            return result

        def invalid_bool_value(bad_value: std.std_string) -> invalid_bool_value:
            let result: invalid_bool_value = invalid_bool_value(validation_error.invalid_bool_value)
            result.set_substitute("value", bad_value)
            return result

        def error_with_option_name(template_: std.std_string, option_name: std.std_string, original_token: std.std_string, option_style: int) -> error_with_option_name:
            let result: error_with_option_name = error_with_option_name(template_)
            result.m_option_style = option_style
            result.m_error_template = template_
            result.set_substitute_default("canonical_option", "option '%canonical_option%'", "option")
            result.set_substitute_default("value", "argument ('%value%')", "argument")
            result.set_substitute_default("prefix", "%prefix%", "")
            result.m_substitutions["option"] = option_name
            result.m_substitutions["original_token"] = original_token
            return result

        def what(self: error_with_option_name) -> const_char_ptr:
            substitute_placeholders(self, self.m_error_template)
            return self.m_message.c_str()

        def replace_token(self: inout error_with_option_name, from_str: std.std_string, to_str: std.std_string):
            while True:
                let pos: std_size_t = self.m_message.find(from_str.c_str(), 0, from_str.length())
                if pos == std.std_string.npos:
                    return
                self.m_message.replace(pos, from_str.length(), to_str)

        def get_canonical_option_prefix(self: error_with_option_name) -> std.std_string:
            if self.m_option_style == command_line_style.allow_dash_for_short:
                return "-"
            elif self.m_option_style == command_line_style.allow_slash_for_short:
                return "/"
            elif self.m_option_style == command_line_style.allow_long_disguise:
                return "-"
            elif self.m_option_style == command_line_style.allow_long:
                return "--"
            elif self.m_option_style == 0:
                return ""
            else:
                raise std.logic_error("error_with_option_name::m_option_style can only be one of [0, allow_dash_for_short, allow_slash_for_short, allow_long_disguise or allow_long]")

        def get_canonical_option_name(self: error_with_option_name) -> std.std_string:
            if not self.m_substitutions.find("option").second.length():
                return self.m_substitutions.find("original_token").second
            var original_token: std.std_string = strip_prefixes(self.m_substitutions.find("original_token").second)
            var option_name: std.std_string = strip_prefixes(self.m_substitutions.find("option").second)
            if self.m_option_style == command_line_style.allow_long or self.m_option_style == command_line_style.allow_long_disguise:
                return get_canonical_option_prefix(self) + option_name
            if self.m_option_style and original_token.length():
                return get_canonical_option_prefix(self) + original_token[0]
            return option_name

        def substitute_placeholders(self: inout error_with_option_name, error_template: std.std_string):
            self.m_message = error_template
            var substitutions: std.std_map[std.std_string, std.std_string] = std.std_map[std.std_string, std.std_string](self.m_substitutions)
            substitutions["canonical_option"] = get_canonical_option_name(self)
            substitutions["prefix"] = get_canonical_option_prefix(self)
            for iter in self.m_substitution_defaults:
                if substitutions.count(iter.first) == 0 or substitutions[iter.first].length() == 0:
                    replace_token(self, iter.second.first, iter.second.second)
            for iter in substitutions:
                replace_token(self, '%' + iter.first + '%', iter.second)

        def substitute_placeholders(self: inout ambiguous_option, original_error_template: std.std_string):
            if self.m_option_style == command_line_style.allow_dash_for_short or self.m_option_style == command_line_style.allow_slash_for_short:
                error_with_option_name.substitute_placeholders(self, original_error_template)
                return
            var error_template: std.std_string = original_error_template
            var alternatives_set: Set[std.std_string] = Set[std.std_string](self.m_alternatives.begin(), self.m_alternatives.end())
            var alternatives_vec: std.std_vector[std.std_string] = std.std_vector[std.std_string](alternatives_set.begin(), alternatives_set.end())
            error_template += " and matches "
            if alternatives_vec.size() > 1:
                for i in range(alternatives_vec.size() - 1):
                    error_template += "'%prefix%" + alternatives_vec[i] + "', "
                error_template += "and "
            if self.m_alternatives.size() > 1 and alternatives_vec.size() == 1:
                error_template += "different versions of "
            error_template += "'%prefix%" + alternatives_vec.back() + "'"
            error_with_option_name.substitute_placeholders(self, error_template)

        def get_template(kind: validation_error.kind_t) -> std.std_string:
            var msg: const_char_ptr
            if kind == validation_error.invalid_bool_value:
                msg = "the argument ('%value%') for option '%canonical_option%' is invalid. Valid choices are 'on|off', 'yes|no', '1|0' and 'true|false'"
            elif kind == validation_error.invalid_option_value:
                msg = "the argument ('%value%') for option '%canonical_option%' is invalid"
            elif kind == validation_error.multiple_values_not_allowed:
                msg = "option '%canonical_option%' only takes a single argument"
            elif kind == validation_error.at_least_one_value_required:
                msg = "option '%canonical_option%' requires at least one argument"
            elif kind == validation_error.invalid_option:
                msg = "option '%canonical_option%' is not valid"
            else:
                msg = "unknown error"
            return std.std_string(msg)