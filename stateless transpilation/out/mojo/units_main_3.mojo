# EXTERNAL DEPS (to wire in glue):
# None identified in this snippet

from unittest import TestCase, main

fn main(argv: [String]) -> Int {
    // EXTERNAL DEPS (to wire in glue):
    // None identified in this snippet

    // Equivalent to ENABLE_GTEST_DEBUG_MODE macro check
    if ENABLE_GTEST_DEBUG_MODE {
        TestCase.testMethodPrefix = "test"
        main.exit = false
    }

    main(argv: argv)
    return 0
}
