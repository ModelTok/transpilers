from gtest.gtest import TEST, testing

@parameter
def TEN_TESTS_(test_case_name: StringLiteral):
    TEST(test_case_name, "T0") {}
    TEST(test_case_name, "T1") {}
    TEST(test_case_name, "T2") {}
    TEST(test_case_name, "T3") {}
    TEST(test_case_name, "T4") {}
    TEST(test_case_name, "T5") {}
    TEST(test_case_name, "T6") {}
    TEST(test_case_name, "T7") {}
    TEST(test_case_name, "T8") {}
    TEST(test_case_name, "T9") {}

@parameter
def HUNDRED_TESTS_(test_case_name_prefix: StringLiteral):
    TEN_TESTS_(test_case_name_prefix + "0")
    TEN_TESTS_(test_case_name_prefix + "1")
    TEN_TESTS_(test_case_name_prefix + "2")
    TEN_TESTS_(test_case_name_prefix + "3")
    TEN_TESTS_(test_case_name_prefix + "4")
    TEN_TESTS_(test_case_name_prefix + "5")
    TEN_TESTS_(test_case_name_prefix + "6")
    TEN_TESTS_(test_case_name_prefix + "7")
    TEN_TESTS_(test_case_name_prefix + "8")
    TEN_TESTS_(test_case_name_prefix + "9")

@parameter
def THOUSAND_TESTS_(test_case_name_prefix: StringLiteral):
    HUNDRED_TESTS_(test_case_name_prefix + "0")
    HUNDRED_TESTS_(test_case_name_prefix + "1")
    HUNDRED_TESTS_(test_case_name_prefix + "2")
    HUNDRED_TESTS_(test_case_name_prefix + "3")
    HUNDRED_TESTS_(test_case_name_prefix + "4")
    HUNDRED_TESTS_(test_case_name_prefix + "5")
    HUNDRED_TESTS_(test_case_name_prefix + "6")
    HUNDRED_TESTS_(test_case_name_prefix + "7")
    HUNDRED_TESTS_(test_case_name_prefix + "8")
    HUNDRED_TESTS_(test_case_name_prefix + "9")

THOUSAND_TESTS_("T")

def main(argc: Int, argv: Pointer[Pointer[UInt8]]):
    testing.InitGoogleTest(argc, argv)
    return 0