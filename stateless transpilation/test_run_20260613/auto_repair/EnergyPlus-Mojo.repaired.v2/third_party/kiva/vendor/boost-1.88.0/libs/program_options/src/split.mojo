from parsers import *
from boost.tokenizer import *
from string import String
from vector import Vector

namespace boost.program_options.detail:
    def split_unix[charT: AnyType](
        cmdline: String[charT],
        seperator: String[charT],
        quote: String[charT],
        escape: String[charT]
    ) -> Vector[String[charT]]:
        alias tokenizerT = boost.tokenizer[
            boost.escaped_list_separator[charT],
            String[charT].iterator,
            String[charT]
        ]
        var tok = tokenizerT(
            cmdline.begin(), cmdline.end(),
            boost.escaped_list_separator[charT](escape, seperator, quote)
        )
        var result = Vector[String[charT]]()
        var cur_token = tok.begin()
        var end_token = tok.end()
        while cur_token != end_token:
            if not cur_token[].empty():
                result.push_back(cur_token[])
            cur_token += 1
        return result

namespace boost.program_options:
    @export
    def split_unix(
        cmdline: String,
        seperator: String,
        quote: String,
        escape: String
    ) -> Vector[String]:
        return detail.split_unix[char](cmdline, seperator, quote, escape)

    @export
    def split_unix(
        cmdline: WString,
        seperator: WString,
        quote: WString,
        escape: WString
    ) -> Vector[WString]:
        return detail.split_unix[wchar_t](cmdline, seperator, quote, escape)