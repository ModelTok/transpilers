import sys
import unittest


def main(argc: int, argv: list[str]) -> int:
    ENABLE_GTEST_DEBUG_MODE = False
    
    if ENABLE_GTEST_DEBUG_MODE:
        pass
    
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    sys.exit(main(len(sys.argv), sys.argv))
