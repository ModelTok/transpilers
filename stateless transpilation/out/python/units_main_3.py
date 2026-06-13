# EXTERNAL DEPS (to wire in glue):
# None identified in this snippet

import sys
import unittest

def main(argv):
    # EXTERNAL DEPS (to wire in glue):
    # None identified in this snippet

    # Equivalent to ENABLE_GTEST_DEBUG_MODE macro check
    if 'ENABLE_GTEST_DEBUG_MODE' in globals() and ENABLE_GTEST_DEBUG_MODE:
        unittest.TestLoader.testMethodPrefix = 'test'
        unittest.main.exit = False

    unittest.main(argv=argv)

if __name__ == '__main__':
    main(sys.argv)
