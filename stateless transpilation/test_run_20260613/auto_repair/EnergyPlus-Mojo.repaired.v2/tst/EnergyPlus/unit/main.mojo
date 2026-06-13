from testing import *
from sys import *

# include <gtest/gtest.h>
# ifdef DEBUG_ARITHM_GCC_OR_CLANG
#     include <EnergyPlus/fenv_missing.h>
# endif
# ifdef DEBUG_ARITHM_MSVC
#     include <cfloat>
# endif

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
# ifdef ENABLE_GTEST_DEBUG_MODE
    testing.GTEST_FLAG(break_on_failure) = true
    testing.GTEST_FLAG(catch_exceptions) = false
# endif
# ifdef ENABLE_GTEST_SHUFFLE
    testing.GTEST_FLAG(shuffle) = true
# endif
    testing.InitGoogleTest(argc, argv)
# ifdef DEBUG_ARITHM_GCC_OR_CLANG
    feenableexcept(FE_DIVBYZERO | FE_INVALID | FE_OVERFLOW)
# endif
# ifdef DEBUG_ARITHM_MSVC
    var fpcntrl: UInt32 = 0
    _controlfp_s(fpcntrl, 0, 0)
    var new_exceptions: UInt32 = _EM_ZERODIVIDE | _EM_INVALID | _EM_OVERFLOW
    var new_control: UInt32 = fpcntrl & ~new_exceptions
    _controlfp_s(fpcntrl, new_control, _MCW_EM)
# endif
    return RUN_ALL_TESTS()