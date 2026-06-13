from boost.config import *
from boost.program_options.config import *
from parsers import *
from options_description import *
from positional_options import *
from cmdline import *
from config_file import *
from boost.program_options.environment_iterator import *
from convert import *
from boost.bind.bind import *
from boost.throw_exception import *
from cctype import *
from fstream import *
from istream import *
from stdlib import *
from unistd import *
from cstdlib import *
namespace boost:
    namespace program_options:
        #ifndef BOOST_NO_STD_WSTRING
        namespace:
            def woption_from_option(opt: option) -> woption:
                var result: woption
                result.string_key = opt.string_key
                result.position_key = opt.position_key
                result.unregistered = opt.unregistered
                std.transform(opt.value.begin(), opt.value.end(),
                               back_inserter(result.value),
                               boost.bind(from_utf8, _1))
                std.transform(opt.original_tokens.begin(), 
                               opt.original_tokens.end(),
                               back_inserter(result.original_tokens),
                               boost.bind(from_utf8, _1))
                return result

        basic_parsed_options[wchar_t].__init__(self, po: parsed_options):
            self.description = po.description
            self.utf8_encoded_options = po
            self.m_options_prefix = po.m_options_prefix
            for i in range(0, po.options.size()):
                self.options.push_back(woption_from_option(po.options[i]))
        #endif

        @staticmethod
        def parse_config_file[charT](is: std.basic_istream[charT], 
                                    desc: options_description,
                                    allow_unregistered: bool) -> basic_parsed_options[charT]:
            var allowed_options: set[string]
            var options: vector[shared_ptr[option_description]] = desc.options()
            for i in range(0, options.size()):
                var d: option_description = *options[i]
                if d.long_name().empty():
                    boost.throw_exception(
                        error("abbreviated option names are not permitted in options configuration files"))
                allowed_options.insert(d.long_name())
            var result: parsed_options = parsed_options(&desc)
            copy(detail.basic_config_file_iterator[charT](
                     is, allowed_options, allow_unregistered), 
                 detail.basic_config_file_iterator[charT](), 
                 back_inserter(result.options))
            return basic_parsed_options[charT](result)

        @staticmethod
        def parse_config_file(is: std.basic_istream[char], 
                             desc: options_description,
                             allow_unregistered: bool) -> basic_parsed_options[char]:
            ...

        #ifndef BOOST_NO_STD_WSTRING
        @staticmethod
        def parse_config_file(is: std.basic_istream[wchar_t], 
                             desc: options_description,
                             allow_unregistered: bool) -> basic_parsed_options[wchar_t]:
            ...
        #endif

        @staticmethod
        def parse_config_file[charT](filename: char*, 
                                    desc: options_description,
                                    allow_unregistered: bool) -> basic_parsed_options[charT]:
            var strm: std.basic_ifstream[charT] = std.basic_ifstream[charT](filename)
            if not strm:
                boost.throw_exception(reading_file(filename))
            var result: basic_parsed_options[charT] = parse_config_file(strm, desc, allow_unregistered)
            if strm.bad():
                boost.throw_exception(reading_file(filename))
            return result

        @staticmethod
        def parse_config_file(filename: char*, 
                             desc: options_description,
                             allow_unregistered: bool) -> basic_parsed_options[char]:
            ...

        #ifndef BOOST_NO_STD_WSTRING
        @staticmethod
        def parse_config_file(filename: char*, 
                             desc: options_description,
                             allow_unregistered: bool) -> basic_parsed_options[wchar_t]:
            ...
        #endif

        #if 0
        @staticmethod
        def parse_config_file(is: istream) -> parsed_options:
            var cf: detail.config_file_iterator = detail.config_file_iterator(is, false)
            var result: parsed_options = parsed_options(0)
            copy(cf, detail.config_file_iterator(), 
                 back_inserter(result.options))
            return result
        #endif

        @staticmethod
        def parse_environment(desc: options_description, 
                             name_mapper: function1[string, string]) -> parsed_options:
            var result: parsed_options = parsed_options(&desc)
            var i: environment_iterator = environment_iterator(environ)
            var e: environment_iterator
            while i != e:
                var option_name: string = name_mapper(i.first)
                if not option_name.empty():
                    var n: option
                    n.string_key = option_name
                    n.value.push_back(i.second)
                    result.options.push_back(n)
                i += 1
            return result

        namespace detail:
            class prefix_name_mapper:
                def __init__(self, prefix: std.string):
                    self.prefix = prefix

                def __call__(self, s: std.string) -> std.string:
                    var result: string
                    if s.find(self.prefix) == 0:
                        var n: string.size_type = self.prefix.size()
                        while n < s.size():
                            result += static_cast[char](tolower(s[n]))
                            n += 1
                    return result

                private:
                    var prefix: std.string

        @staticmethod
        def parse_environment(desc: options_description, 
                             prefix: std.string) -> parsed_options:
            return parse_environment(desc, detail.prefix_name_mapper(prefix))

        @staticmethod
        def parse_environment(desc: options_description, prefix: char*) -> parsed_options:
            return parse_environment(desc, string(prefix))