from sample4 import Counter
from gtest.gtest import EXPECT_EQ

def test_Counter_Increment():
    var c: Counter
    EXPECT_EQ(0, c.Decrement())
    EXPECT_EQ(0, c.Increment())
    EXPECT_EQ(1, c.Increment())
    EXPECT_EQ(2, c.Increment())
    EXPECT_EQ(3, c.Decrement())