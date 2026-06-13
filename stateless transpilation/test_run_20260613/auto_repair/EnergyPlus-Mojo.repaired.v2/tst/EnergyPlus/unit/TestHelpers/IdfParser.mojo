from IdfParser import IdfParser

@value
struct IdfParser:
    enum Token(UInt):
        NONE = 0
        END = 1
        EXCLAMATION = 2
        COMMA = 3
        SEMICOLON = 4
        STRING = 5
        Num = 6

    @staticmethod
    def decode(idf: String) -> List[List[String]]:
        var success: Bool = True
        return IdfParser.decode(idf, success)

    @staticmethod
    def decode(idf: String, success: Bool) -> List[List[String]]:
        success = True
        if idf == "":
            return List[List[String]]()
        var index: UInt = 0
        return IdfParser.parse_idf(idf, index, success)

    @staticmethod
    def encode(idf_list: List[List[String]]) -> String:
        var idf: String = ""
        for object in idf_list:
            var size: UInt = len(object)
            for i in range(size - 1):
                idf += object[i] + ","
            idf += object[size - 1] + ";" + "\n"
        return idf

    @staticmethod
    def parse_idf(idf: String, index: UInt, success: Bool) -> List[List[String]]:
        var obj: List[List[String]] = List[List[String]]()
        var token: Token
        var done: Bool = False
        while not done:
            token = IdfParser.look_ahead(idf, index)
            if token == Token.END:
                break
            if token == Token.NONE:
                success = False
                return List[List[String]]()
            if token == Token.EXCLAMATION:
                IdfParser.eat_comment(idf, index)
            else:
                var array = IdfParser.parse_object(idf, index, success)
                if len(array) != 0:
                    obj.append(array)
        return obj

    @staticmethod
    def parse_object(idf: String, index: UInt, success: Bool) -> List[String]:
        var array: List[String] = List[String]()
        var token: Token
        var done: Bool = False
        while not done:
            token = IdfParser.look_ahead(idf, index)
            if token == Token.NONE:
                success = False
                return List[String]()
            if token == Token.COMMA:
                IdfParser.next_token(idf, index)
                token = IdfParser.look_ahead(idf, index)
                if Token.EXCLAMATION == token:
                    IdfParser.eat_comment(idf, index)
                token = IdfParser.look_ahead(idf, index)
                if Token.COMMA == token:
                    array.append("")
                elif Token.SEMICOLON == token:
                    array.append("")
                    break
            elif token == Token.SEMICOLON:
                IdfParser.next_token(idf, index)
                break
            elif token == Token.EXCLAMATION:
                IdfParser.eat_comment(idf, index)
            else:
                var value: String = IdfParser.parse_value(idf, index, success)
                if not success:
                    return List[String]()
                array.append(value)
        return array

    @staticmethod
    def parse_value(idf: String, index: UInt, success: Bool) -> String:
        var la = IdfParser.look_ahead(idf, index)
        if la == Token.STRING:
            return IdfParser.parse_string(idf, index, success)
        elif la == Token.NONE or la == Token.END or la == Token.EXCLAMATION or la == Token.COMMA or la == Token.SEMICOLON:

        else:

        success = False
        return String()

    @staticmethod
    def parse_string(idf: String, index: UInt, success: Bool) -> String:
        IdfParser.eat_whitespace(idf, index)
        var s: String = ""
        var c: UInt8
        var idf_size: UInt = len(idf)
        var complete: Bool = False
        while not complete:
            if index == idf_size:
                complete = True
                break
            c = idf[index]
            index += 1
            if c == ord(','):
                complete = True
                index -= 1
                break
            if c == ord(';'):
                complete = True
                index -= 1
                break
            if c == ord('!'):
                complete = True
                index -= 1
                break
            if c == ord('\\'):
                if index == idf_size:
                    break
                c = idf[index]
                index += 1
                if c == ord('"'):
                    s += '"'
                elif c == ord('\\'):
                    s += '\\'
                elif c == ord('/'):
                    s += '/'
                elif c == ord('b'):
                    s += '\b'
                elif c == ord('t'):
                    s += '\t'
                elif c == ord('n'):
                    complete = False
                    break
                elif c == ord('r'):
                    complete = False
                    break
            else:
                s += chr(c)
        if not complete:
            success = False
            return String()
        return s

    @staticmethod
    def eat_whitespace(idf: String, index: UInt):
        while index < len(idf):
            var c = idf[index]
            if c == ord(' ') or c == ord('\n') or c == ord('\r') or c == ord('\t'):
                index += 1
                continue
            else:
                return

    @staticmethod
    def eat_comment(idf: String, index: UInt):
        var idf_size: UInt = len(idf)
        while True:
            if index == idf_size:
                break
            if idf[index] == ord('\n'):
                index += 1
                break
            index += 1

    @staticmethod
    def look_ahead(idf: String, index: UInt) -> Token:
        var save_index: UInt = index
        return IdfParser.next_token(idf, save_index)

    @staticmethod
    def next_token(idf: String, index: UInt) -> Token:
        IdfParser.eat_whitespace(idf, index)
        if index == len(idf):
            return Token.END
        var c: UInt8 = idf[index]
        index += 1
        if c == ord('!'):
            return Token.EXCLAMATION
        elif c == ord(','):
            return Token.COMMA
        elif c == ord(';'):
            return Token.SEMICOLON
        else:
            var search_chars: String = "-:.#/\\[]{}_@$%^&*()|+=<>?'\"~"
            if (c >= ord('a') and c <= ord('z')) or (c >= ord('A') and c <= ord('Z')) or (c >= ord('0') and c <= ord('9')):
                return Token.STRING
            elif search_chars.find_first_of(chr(c)) != -1:
                return Token.STRING
        index -= 1
        return Token.NONE