#ifndef BOOST_PROGRAM_OPTIONS_SOURCE
# define BOOST_PROGRAM_OPTIONS_SOURCE
#endif
from os import isspace
from parsers import to_internal, from_utf8
from stdlib import List

struct WString:
    var s: String
    def __init__(inout self, s: String):
        self.s = s

def split_winmain(input: String) -> List[String]:
    var result = List[String]()
    var i = 0
    var e = len(input)
    for(; i < e; i += 1):
        if not isspace(input[i]):
            break
    if i < e:
        var current = String()
        var inside_quoted = False
        var empty_quote = False
        var backslash_count = 0
        for(; i < e; i += 1):
            if input[i] == '"':
                if backslash_count % 2 == 0:
                    current.append("\\" * (backslash_count // 2))
                    empty_quote = inside_quoted and (len(current) == 0)
                    inside_quoted = not inside_quoted
                else:
                    current.append("\\" * (backslash_count // 2))
                    current += '"'
                backslash_count = 0
            elif input[i] == '\\':
                backslash_count += 1
            else:
                if backslash_count != 0:
                    current.append("\\" * backslash_count)
                    backslash_count = 0
                if isspace(input[i]) and not inside_quoted:
                    result.append(current)
                    current = String()
                    empty_quote = False
                    for(; i < e and isspace(input[i]); i += 1):

                    i -= 1
                else:
                    current += input[i]
        if backslash_count != 0:
            current.append("\\" * backslash_count)
        if (len(current) != 0) or inside_quoted or empty_quote:
            result.append(current)
    return result

#ifndef BOOST_NO_STD_WSTRING
def split_winmain(cmdline: WString) -> List[WString]:
    var result = List[WString]()
    var aux = split_winmain(to_internal(cmdline))
    for i in range(len(aux)):
        result.append(from_utf8(aux[i]))
    return result
#endif