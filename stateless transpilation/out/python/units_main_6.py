import sys
import os

# EXTERNAL DEPS (to wire in glue):
# - testing.GTEST_FLAG: gtest flag setter (source: gtest C++ library)
# - testing.InitGoogleTest: gtest initializer (source: gtest C++ library)
# - testing.RUN_ALL_TESTS: gtest test runner (source: gtest C++ library)

ENABLE_GTEST_DEBUG_MODE = bool(os.environ.get("ENABLE_GTEST_DEBUG_MODE"))

def main(argc: int, argv: list[str]) -> int:
    if ENABLE_GTEST_DEBUG_MODE:
        testing.GTEST_FLAG("break_on_failure", True)
        testing.GTEST_FLAG("catch_exceptions", False)
    
    testing.InitGoogleTest(argc, argv)
    return testing.RUN_ALL_TESTS()

if __name__ == "__main__":
    sys.exit(main(len(sys.argv), sys.argv))
