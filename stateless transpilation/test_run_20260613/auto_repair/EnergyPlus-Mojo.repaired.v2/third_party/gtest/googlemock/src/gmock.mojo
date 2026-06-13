from ...include.gmock.gmock import GMOCK_FLAG_catch_leaked_mocks, GMOCK_FLAG_verbose, GMOCK_FLAG_default_mock_behavior
from ...include.gmock.internal.gmock-port import kWarningVerbosity, ParseInt32
from ...test.googletest.include.gtest.gtest import InitGoogleTest, StreamableToString, Message

alias GMOCK_FLAG_catch_leaked_mocks: Bool = True
alias GMOCK_FLAG_verbose: String = kWarningVerbosity
alias GMOCK_FLAG_default_mock_behavior: Int32 = 1

def ParseGoogleMockFlagValue(str: StringRef, flag: StringRef, def_optional: Bool) -> StringRef?:
    if str is None or flag is None:
        return None
    let flag_str = "--gmock_" + flag
    let flag_len = flag_str.length()
    if strncmp(str, flag_str.data(), flag_len) != 0:
        return None
    let flag_end = str + flag_len
    if def_optional and flag_end[0] == '\0':
        return flag_end
    if flag_end[0] != '=':
        return None
    return flag_end + 1

def ParseGoogleMockBoolFlag(str: StringRef, flag: StringRef, value: Pointer[Bool]) -> Bool:
    let value_str = ParseGoogleMockFlagValue(str, flag, True)
    if value_str is None:
        return False
    value[] = not (value_str[0] == '0' or value_str[0] == 'f' or value_str[0] == 'F')
    return True

def ParseGoogleMockStringFlag(str: StringRef, flag: StringRef, value: Pointer[String]) -> Bool:
    let value_str = ParseGoogleMockFlagValue(str, flag, False)
    if value_str is None:
        return False
    value[] = String(value_str)
    return True

def ParseGoogleMockIntFlag(str: StringRef, flag: StringRef, value: Pointer[Int32]) -> Bool:
    let value_str = ParseGoogleMockFlagValue(str, flag, True)
    if value_str is None:
        return False
    return ParseInt32(Message() << "The value of flag --" << flag, value_str, value)

def InitGoogleMockImpl[CharType: AnyRegType](argc: Pointer[Int32], argv: Pointer[Pointer[CharType]]):
    InitGoogleTest(argc, argv)
    if argc[] <= 0:
        return
    var i: Int32 = 1
    while i != argc[]:
        let arg_string = StreamableToString(argv[i])
        let arg = arg_string.data()
        if ParseGoogleMockBoolFlag(arg, "catch_leaked_mocks", Pointer[Bool](addressof GMOCK_FLAG_catch_leaked_mocks)) or
           ParseGoogleMockStringFlag(arg, "verbose", Pointer[String](addressof GMOCK_FLAG_verbose)) or
           ParseGoogleMockIntFlag(arg, "default_mock_behavior", Pointer[Int32](addressof GMOCK_FLAG_default_mock_behavior)):
            for j in range(i, argc[]):
                argv[j] = argv[j + 1]
            argc[] -= 1
            i -= 1
        i += 1

def InitGoogleMock(argc: Pointer[Int32], argv: Pointer[Pointer[UInt8]]):
    InitGoogleMockImpl(argc, argv)

def InitGoogleMock(argc: Pointer[Int32], argv: Pointer[Pointer[WChar]]):
    InitGoogleMockImpl(argc, argv)

def InitGoogleMock():
    var argc: Int32 = 1
    let arg0 = "dummy"
    var argv0: Pointer[UInt8] = Pointer[UInt8](addressof arg0[0])
    var argv: Pointer[Pointer[UInt8]] = Pointer[Pointer[UInt8]](addressof argv0)
    InitGoogleMockImpl(Pointer[Int32](addressof argc), argv)