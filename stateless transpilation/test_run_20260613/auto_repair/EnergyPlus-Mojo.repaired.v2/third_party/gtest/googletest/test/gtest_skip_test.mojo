from gtest.gtest import Test, TEST, TEST_F, GTEST_SKIP, EXPECT_EQ

TEST("SkipTest", "DoesSkip", fn() {
    GTEST_SKIP() << "skipping single test"
    EXPECT_EQ(0, 1)
})

struct Fixture(Test):
    def SetUp(self):
        GTEST_SKIP() << "skipping all tests for this fixture"

TEST_F(Fixture, "SkipsOneTest", fn() {
    EXPECT_EQ(5, 7)
})

TEST_F(Fixture, "SkipsAnotherTest", fn() {
    EXPECT_EQ(99, 100)
})