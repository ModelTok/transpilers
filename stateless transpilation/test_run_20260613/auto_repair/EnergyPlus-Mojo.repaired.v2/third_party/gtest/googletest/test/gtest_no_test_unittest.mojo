from gtest import testing, EXPECT_EQ, RUN_ALL_TESTS

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
  testing.InitGoogleTest(&argc, argv)
  EXPECT_EQ(1, 2)
  return RUN_ALL_TESTS() ? 0 : 1