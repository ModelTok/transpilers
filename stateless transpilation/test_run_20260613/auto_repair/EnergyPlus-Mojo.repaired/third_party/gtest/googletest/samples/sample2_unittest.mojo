from sample2 import MyString
from gtest import TEST, EXPECT_STREQ, EXPECT_EQ

TEST(MyString, DefaultConstructor):
    var s = MyString()
    EXPECT_STREQ(None, s.c_string())
    EXPECT_EQ(0u, s.Length())

let kHelloString: String = "Hello, world!"

TEST(MyString, ConstructorFromCString):
    var s = MyString(kHelloString)
    EXPECT_EQ(0, strcmp(s.c_string(), kHelloString))
    EXPECT_EQ(sizeof(kHelloString)/sizeof(kHelloString[0]) - 1, s.Length())

TEST(MyString, CopyConstructor):
    var s1 = MyString(kHelloString)
    var s2 = s1
    EXPECT_EQ(0, strcmp(s2.c_string(), kHelloString))

TEST(MyString, Set):
    var s = MyString()
    s.Set(kHelloString)
    EXPECT_EQ(0, strcmp(s.c_string(), kHelloString))
    s.Set(s.c_string())
    EXPECT_EQ(0, strcmp(s.c_string(), kHelloString))
    s.Set(None)
    EXPECT_STREQ(None, s.c_string())