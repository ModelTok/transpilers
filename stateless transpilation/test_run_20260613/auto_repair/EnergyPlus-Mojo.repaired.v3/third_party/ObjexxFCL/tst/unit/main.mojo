from gtest import testing, RUN_ALL_TESTS

alias _WIN32 = False

@parameter
if not _WIN32:
    from ObjexxFCL.command import __argc, __argv

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    if not _WIN32:
        __argc = argc
        __argv = argv
    testing.InitGoogleTest(&argc, argv)
    return RUN_ALL_TESTS()