from python import gtest as testing
from sys import exit

def _CrtSetReportFile(a: Int, b: Int): pass
def _CrtSetReportMode(a: Int, b: Int): pass

const _CRT_ERROR: Int = 0
const _CRTDBG_MODE_FILE: Int = 0
const _CRTDBG_MODE_DEBUG: Int = 0
const _CRTDBG_FILE_STDERR: Int = 0
const _CRT_ASSERT: Int = 0

const SEM_FAILCRITICALERRORS: Int = 0
const SEM_NOGPFAULTERRORBOX: Int = 0
const SEM_NOOPENFILEERRORBOX: Int = 0

def SetErrorMode(mode: Int): Int = 0

def main(argc: Int, argv: Pointer[UInt8]) -> Int:
    @parameter if __WIN32__:
        SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX)

    _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG)
    _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR)
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE | _CRTDBG_MODE_DEBUG)
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR)

    try:
        testing.InitGoogleTest(&argc, argv)
        testing.FLAGS_gtest_death_test_style = "threadsafe"
        return testing.RUN_ALL_TESTS()
    except:

    return EXIT_FAILURE

const EXIT_FAILURE: Int = 1