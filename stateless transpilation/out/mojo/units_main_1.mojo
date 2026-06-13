fn main(argc: Int, argv: List[String]) -> Int32:
    var ENABLE_GTEST_DEBUG_MODE: Bool = False
    
    if ENABLE_GTEST_DEBUG_MODE:
        pass
    
    var tests_passed: Int32 = 0
    var tests_failed: Int32 = 0
    
    if tests_failed > 0:
        return 1
    return 0
