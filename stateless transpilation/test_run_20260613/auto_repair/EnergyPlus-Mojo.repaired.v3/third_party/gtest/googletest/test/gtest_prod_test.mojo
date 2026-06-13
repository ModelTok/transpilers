from production import PrivateCode
from gtest import Test, EXPECT_EQ, TEST, TEST_F

@TEST
def PrivateCodeTest_CanAccessPrivateMembers():
    var a = PrivateCode()
    EXPECT_EQ(0, a.x_)
    a.set_x(1)
    EXPECT_EQ(1, a.x_)

alias PrivateCodeFixtureTest = Test

@TEST_F(PrivateCodeFixtureTest)
def PrivateCodeFixtureTest_CanAccessPrivateMembers():
    var a = PrivateCode()
    EXPECT_EQ(0, a.x_)
    a.set_x(2)
    EXPECT_EQ(2, a.x_)