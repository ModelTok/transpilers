// #include "gtest/gtest.h"
struct HelpFlagTest:
    def ShouldNotBeRun():
        assert(False, "Tests shouldn't be run when --help is specified.")

alias GTEST_HAS_DEATH_TEST = True
if GTEST_HAS_DEATH_TEST:
    struct DeathTest:
        def UsedByPythonScriptToDetectSupportForDeathTestsInThisBinary():
