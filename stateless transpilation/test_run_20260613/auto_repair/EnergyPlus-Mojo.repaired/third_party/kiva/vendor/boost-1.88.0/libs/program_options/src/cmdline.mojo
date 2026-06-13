// Translated from C++ to Mojo (faithful 1:1, no refactoring)
// Original: third_party/kiva/vendor/boost-1.88.0/libs/program_options/src/cmdline.cpp

// #ifndef BOOST_PROGRAM_OPTIONS_SOURCE
// # define BOOST_PROGRAM_OPTIONS_SOURCE
// #endif
alias BOOST_PROGRAM_OPTIONS_SOURCE = True

// #include <boost/program_options/config.hpp>
from boost.program_options.config import *
// #include <boost/config.hpp>
from boost.config import *
// #include <boost/program_options/detail/cmdline.hpp>
from boost.program_options.detail.cmdline import *
// #include <boost/program_options/errors.hpp>
from boost.program_options.errors import *
// #include <boost/program_options/value_semantic.hpp>
from boost.program_options.value_semantic import *
// #include <boost/program_options/options_description.hpp>
from boost.program_options.options_description import *
// #include <boost/program_options/positional_options.hpp>
from boost.program_options.positional_options import *
// #include <boost/throw_exception.hpp>
from boost.throw_exception import *
// #include <boost/bind/bind.hpp>
from boost.bind.bind import *
// #include <string>
from builtin import String as string
// #include <utility>
from builtin import Pair as pair
// #include <vector>
from builtin import List as vector
// #include <cassert>
// #include <cstring>
// #include <cctype>
// #include <climits>
// #include <cstdio>
// #include <iostream>
from builtin import print as cout // placeholder

// using namespace boost::placeholders;
// (imported via boost/bind/bind)

namespace boost:
    namespace program_options:
        // using namespace std;
        // using namespace boost::program_options::command_line_style;
        // (assumed imported)

        string 
        invalid_syntax.get_template(kind_t kind):
            const msg: String
            if kind == empty_adjacent_parameter:
                msg = "the argument for option '%canonical_option%' should follow immediately after the equal sign"
            elif kind == missing_parameter:
                msg = "the required argument for option '%canonical_option%' is missing"
            elif kind == unrecognized_line:
                msg = "the options configuration file contains an invalid line '%invalid_line%'"
            elif kind == long_not_allowed:
                msg = "the unabbreviated option '%canonical_option%' is not valid"
            elif kind == long_adjacent_not_allowed:
                msg = "the unabbreviated option '%canonical_option%' does not take any arguments"
            elif kind == short_adjacent_not_allowed:
                msg = "the abbreviated option '%canonical_option%' does not take any arguments"
            elif kind == extra_parameter:
                msg = "option '%canonical_option%' does not take any arguments"
            else:
                msg = "unknown command line syntax error for '%s'"
            return msg

namespace boost:
    namespace program_options:
        namespace detail:
            // #if BOOST_WORKAROUND(_MSC_VER, < 1300)
            //     using namespace std;
            //     using namespace program_options;
            // #endif
            // (assume not needed)

            struct cmdline:
                var m_args: vector[string]
                var m_style: style_t
                var m_desc: options_description*
                var m_positional: positional_options_description*
                var m_allow_unregistered: Bool
                var m_style_parser: style_parser
                var m_additional_parser: additional_parser

                def __init__(inout self, args: vector[string]):
                    self.init(args)

                def __init__(inout self, argc: Int, argv: Pointer[Pointer[UInt8]]):
                    // #if defined(BOOST_NO_TEMPLATED_ITERATOR_CONSTRUCTORS)
                    //     vector<string> args;
                    //     copy(argv+1, argv+argc+!argc, inserter(args, args.end()));
                    //     init(args);
                    // #else
                    //     init(vector<string>(argv+1, argv+argc+!argc));
                    // #endif
                    // Use the simpler version
                    var args = vector[string]()
                    for i in range(1, argc + (1 if argc == 0 else 0)):
                        args.append(String(argv[i]))
                    self.init(args)

                def init(inout self, args: vector[string]):
                    self.m_args = args
                    self.m_style = command_line_style.default_style
                    self.m_desc = None
                    self.m_positional = None
                    self.m_allow_unregistered = False

                def style(inout self, style: Int):
                    if style == 0:
                        style = default_style
                    self.check_style(style)
                    self.m_style = style_t(style)

                def allow_unregistered(inout self):
                    self.m_allow_unregistered = True

                def check_style(self, style: Int):
                    var allow_some_long = (style & allow_long) or (style & allow_long_disguise)
                    var error: String = None
                    if allow_some_long and not (style & long_allow_adjacent) and not (style & long_allow_next):
                        error = "boost::program_options misconfiguration: choose one or other of 'command_line_style::long_allow_next' (whitespace separated arguments) or 'command_line_style::long_allow_adjacent' ('=' separated arguments) for long options."
                    if not error and (style & allow_short) and not (style & short_allow_adjacent) and not (style & short_allow_next):
                        error = "boost::program_options misconfiguration: choose one or other of 'command_line_style::short_allow_next' (whitespace separated arguments) or 'command_line_style::short_allow_adjacent' ('=' separated arguments) for short options."
                    if not error and (style & allow_short) and not (style & allow_dash_for_short) and not (style & allow_slash_for_short):
                        error = "boost::program_options misconfiguration: choose one or other of 'command_line_style::allow_slash_for_short' (slashes) or 'command_line_style::allow_dash_for_short' (dashes) for short options."
                    if error:
                        boost.throw_exception(invalid_command_line_style(error))

                def is_style_active(self, style: style_t) -> Bool:
                    return (self.m_style & style) != 0

                def set_options_description(inout self, desc: options_description):
                    self.m_desc = &desc

                def set_positional_options(inout self, positional: positional_options_description):
                    self.m_positional = &positional

                def get_canonical_option_prefix(self) -> Int:
                    if self.m_style & allow_long:
                        return allow_long
                    if self.m_style & allow_long_disguise:
                        return allow_long_disguise
                    if (self.m_style & allow_short) and (self.m_style & allow_dash_for_short):
                        return allow_dash_for_short
                    if (self.m_style & allow_short) and (self.m_style & allow_slash_for_short):
                        return allow_slash_for_short
                    return 0

                def run(inout self) -> vector[option]:
                    assert(self.m_desc)
                    var style_parsers = vector[style_parser]()
                    if self.m_style_parser:
                        style_parsers.append(self.m_style_parser)
                    if self.m_additional_parser:
                        style_parsers.append(boost.bind(&cmdline.handle_additional_parser, self, _1))
                    if self.m_style & allow_long:
                        style_parsers.append(boost.bind(&cmdline.parse_long_option, self, _1))
                    if (self.m_style & allow_long_disguise):
                        style_parsers.append(boost.bind(&cmdline.parse_disguised_long_option, self, _1))
                    if (self.m_style & allow_short) and (self.m_style & allow_dash_for_short):
                        style_parsers.append(boost.bind(&cmdline.parse_short_option, self, _1))
                    if (self.m_style & allow_short) and (self.m_style & allow_slash_for_short):
                        style_parsers.append(boost.bind(&cmdline.parse_dos_option, self, _1))
                    style_parsers.append(boost.bind(&cmdline.parse_terminator, self, _1))

                    var result = vector[option]()
                    var args = self.m_args
                    while not args.empty():
                        var ok = False
                        for i in range(len(style_parsers)):
                            var current_size = len(args)
                            var next = style_parsers[i](args)
                            if not next.empty():
                                var e = vector[string]()
                                for k in range(len(next)-1):
                                    self.finish_option(next[k], e, style_parsers)
                                self.finish_option(next[-1], args, style_parsers)
                                for j in range(len(next)):
                                    result.append(next[j])
                            if len(args) != current_size:
                                ok = True
                                break
                        if not ok:
                            var opt = option()
                            opt.value.append(args[0])
                            opt.original_tokens.append(args[0])
                            result.append(opt)
                            args.erase(args.begin())

                    // If an key option is followed by a positional option, can can consume more tokens...
                    var result2 = vector[option]()
                    var i = 0
                    while i < len(result):
                        result2.append(result[i])
                        var opt = result2[-1]
                        if opt.string_key.empty():
                            i += 1
                            continue
                        var xd: option_description*
                        try:
                            xd = self.m_desc.find_nothrow(opt.string_key, 
                                self.is_style_active(allow_guessing),
                                self.is_style_active(long_case_insensitive),
                                self.is_style_active(short_case_insensitive))
                        except error_with_option_name as e:
                            e.add_context(opt.string_key, opt.original_tokens[0], self.get_canonical_option_prefix())
                            raise e
                        if not xd:
                            i += 1
                            continue
                        var min_tokens = xd.semantic().min_tokens()
                        var max_tokens = xd.semantic().max_tokens()
                        if min_tokens < max_tokens and len(opt.value) < max_tokens:
                            var can_take_more = max_tokens - len(opt.value)
                            var j = i+1
                            while can_take_more and j < len(result):
                                var opt2 = result[j]
                                if not opt2.string_key.empty():
                                    break
                                if opt2.position_key == INT_MAX:
                                    break
                                assert(len(opt2.value) == 1)
                                opt.value.append(opt2.value[0])
                                assert(len(opt2.original_tokens) == 1)
                                opt.original_tokens.append(opt2.original_tokens[0])
                                can_take_more -= 1
                                j += 1
                            i = j-1
                        i += 1
                    result.swap(result2)

                    var position_key = 0
                    for i in range(len(result)):
                        if result[i].string_key.empty():
                            result[i].position_key = position_key
                            position_key += 1

                    if self.m_positional:
                        var position = 0
                        for i in range(len(result)):
                            var opt = result[i]
                            if opt.position_key != -1:
                                if position >= self.m_positional.max_total_count():
                                    boost.throw_exception(too_many_positional_options_error())
                                opt.string_key = self.m_positional.name_for_position(position)
                                position += 1

                    for i in range(len(result)):
                        if len(result[i].string_key) > 2 or (len(result[i].string_key) > 1 and result[i].string_key[0] != '-'):
                            result[i].case_insensitive = self.is_style_active(long_case_insensitive)
                        else:
                            result[i].case_insensitive = self.is_style_active(short_case_insensitive)

                    return result

                def finish_option(inout self, inout opt: option, inout other_tokens: vector[string], style_parsers: vector[style_parser]):
                    if opt.string_key.empty():
                        return
                    var original_token_for_exceptions = opt.string_key
                    if len(opt.original_tokens) > 0:
                        original_token_for_exceptions = opt.original_tokens[0]
                    try:
                        var xd = self.m_desc.find_nothrow(opt.string_key, 
                            self.is_style_active(allow_guessing),
                            self.is_style_active(long_case_insensitive),
                            self.is_style_active(short_case_insensitive))
                        if not xd:
                            if self.m_allow_unregistered:
                                opt.unregistered = True
                                return
                            else:
                                boost.throw_exception(unknown_option())
                        var d = *xd
                        opt.string_key = d.key(opt.string_key)
                        var min_tokens = d.semantic().min_tokens()
                        var max_tokens = d.semantic().max_tokens()
                        var present_tokens = len(opt.value) + len(other_tokens)
                        if present_tokens >= min_tokens:
                            if not opt.value.empty() and max_tokens == 0:
                                boost.throw_exception(
                                    invalid_command_line_syntax(invalid_command_line_syntax.extra_parameter))
                            if len(opt.value) <= min_tokens:
                                min_tokens -= len(opt.value)
                            else:
                                min_tokens = 0
                            while not other_tokens.empty() and min_tokens > 0:
                                var followed_option = vector[option]()
                                var next_token = vector[string](1, other_tokens[0])
                                for i in range(len(style_parsers)):
                                    if not followed_option.empty():
                                        break
                                    followed_option = style_parsers[i](next_token)
                                if not followed_option.empty():
                                    original_token_for_exceptions = other_tokens[0]
                                    var od = self.m_desc.find_nothrow(other_tokens[0], 
                                        self.is_style_active(allow_guessing),
                                        self.is_style_active(long_case_insensitive),
                                        self.is_style_active(short_case_insensitive))
                                    if od:
                                        boost.throw_exception(
                                            invalid_command_line_syntax(invalid_command_line_syntax.missing_parameter))
                                opt.value.append(other_tokens[0])
                                opt.original_tokens.append(other_tokens[0])
                                other_tokens.erase(other_tokens.begin())
                                min_tokens -= 1
                        else:
                            boost.throw_exception(
                                invalid_command_line_syntax(invalid_command_line_syntax.missing_parameter))
                    except error_with_option_name as e:
                        e.add_context(opt.string_key, original_token_for_exceptions, self.get_canonical_option_prefix())
                        raise e

                def parse_long_option(inout self, inout args: vector[string]) -> vector[option]:
                    var result = vector[option]()
                    var tok = args[0]
                    if len(tok) >= 3 and tok[0] == '-' and tok[1] == '-':
                        var name: string
                        var adjacent: string
                        var p = tok.find('=')
                        if p != -1:
                            name = tok[2:p]
                            adjacent = tok[p+1:]
                            if adjacent.empty():
                                boost.throw_exception(invalid_command_line_syntax(
                                    invalid_command_line_syntax.empty_adjacent_parameter, 
                                    name, name, self.get_canonical_option_prefix()))
                        else:
                            name = tok[2:]
                        var opt = option()
                        opt.string_key = name
                        if not adjacent.empty():
                            opt.value.append(adjacent)
                        opt.original_tokens.append(tok)
                        result.append(opt)
                        args.erase(args.begin())
                    return result

                def parse_short_option(inout self, inout args: vector[string]) -> vector[option]:
                    var tok = args[0]
                    if len(tok) >= 2 and tok[0] == '-' and tok[1] != '-':
                        var result = vector[option]()
                        var name = tok[0:2]
                        var adjacent = tok[2:]
                        while True:
                            var d: option_description*
                            try:
                                d = self.m_desc.find_nothrow(name, False, False,
                                    self.is_style_active(short_case_insensitive))
                            except error_with_option_name as e:
                                e.add_context(name, name, self.get_canonical_option_prefix())
                                raise e
                            if d and (self.m_style & allow_sticky) and d.semantic().max_tokens() == 0 and not adjacent.empty():
                                var opt = option()
                                opt.string_key = name
                                result.append(opt)
                                if adjacent.empty():
                                    args.erase(args.begin())
                                    break
                                name = "-" + adjacent[0]
                                adjacent = adjacent[1:]
                            else:
                                var opt = option()
                                opt.string_key = name
                                opt.original_tokens.append(tok)
                                if not adjacent.empty():
                                    opt.value.append(adjacent)
                                result.append(opt)
                                args.erase(args.begin())
                                break
                        return result
                    return vector[option]()

                def parse_dos_option(inout self, inout args: vector[string]) -> vector[option]:
                    var result = vector[option]()
                    var tok = args[0]
                    if len(tok) >= 2 and tok[0] == '/':
                        var name = "-" + tok[1:2]
                        var adjacent = tok[2:]
                        var opt = option()
                        opt.string_key = name
                        if not adjacent.empty():
                            opt.value.append(adjacent)
                        opt.original_tokens.append(tok)
                        result.append(opt)
                        args.erase(args.begin())
                    return result

                def parse_disguised_long_option(inout self, inout args: vector[string]) -> vector[option]:
                    var tok = args[0]
                    if len(tok) >= 2 and ((tok[0] == '-' and tok[1] != '-') or ((self.m_style & allow_slash_for_short) and tok[0] == '/')):
                        try:
                            if self.m_desc.find_nothrow(tok[1:tok.find('=')], 
                                self.is_style_active(allow_guessing),
                                self.is_style_active(long_case_insensitive),
                                self.is_style_active(short_case_insensitive)):
                                args[0] = "-" + args[0]
                                if args[0][1] == '/':
                                    args[0] = args[0][0] + '-' + args[0][2:]
                                return self.parse_long_option(args)
                        except error_with_option_name as e:
                            e.add_context(tok, tok, self.get_canonical_option_prefix())
                            raise e
                    return vector[option]()

                def parse_terminator(inout self, inout args: vector[string]) -> vector[option]:
                    var result = vector[option]()
                    var tok = args[0]
                    if tok == "--":
                        for i in range(1, len(args)):
                            var opt = option()
                            opt.value.append(args[i])
                            opt.original_tokens.append(args[i])
                            opt.position_key = INT_MAX
                            result.append(opt)
                        args.clear()
                    return result

                def handle_additional_parser(inout self, inout args: vector[string]) -> vector[option]:
                    var result = vector[option]()
                    var r = self.m_additional_parser(args[0])
                    if not r.first.empty():
                        var next = option()
                        next.string_key = r.first
                        if not r.second.empty():
                            next.value.append(r.second)
                        result.append(next)
                        args.erase(args.begin())
                    return result

                def set_additional_parser(inout self, p: additional_parser):
                    self.m_additional_parser = p

                def extra_style_parser(inout self, s: style_parser):
                    self.m_style_parser = s