import sys
import os

# EXTERNAL DEPS (to wire in glue):
# - testing.GTEST_FLAG: gtest flag setter (source: gtest C++ library)
# - testing.InitGoogleTest: gtest initializer (source: gtest C++ library)
# - testing.RUN_ALL_TESTS: gtest test runner (source: gtest C++ library)

fn main() -> Int:
    let enable_gtest_debug_mode = bool(os.environ.get("ENABLE_GTEST_DEBUG_MODE", ""))
    
    if enable_gtest_debug_mode:
        testing.GTEST_FLAG("break_on_failure", True)
        testing.GTEST_FLAG("catch_exceptions", False)
    
    testing.InitGoogleTest(len(sys.argv), sys.argv)
    return testing.RUN_ALL_TESTS()
