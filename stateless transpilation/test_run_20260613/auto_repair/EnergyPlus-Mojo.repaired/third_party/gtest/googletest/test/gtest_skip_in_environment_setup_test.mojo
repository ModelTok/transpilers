from gtest import testing, GTEST_SKIP, EXPECT_EQ, InitGoogleTest, AddGlobalTestEnvironment, RUN_ALL_TESTS, TEST

class SetupEnvironment(testing.Environment):
    def SetUp(self):
        GTEST_SKIP() << "Skipping the entire environment"

TEST(Test, AlwaysFails):
    EXPECT_EQ(true, false)

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    testing.InitGoogleTest(&argc, argv)
    testing.AddGlobalTestEnvironment(SetupEnvironment())
    return RUN_ALL_TESTS()