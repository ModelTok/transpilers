from sample1 import Factorial, IsPrime
from gtest.gtest import Test, EXPECT_EQ, EXPECT_GT, EXPECT_FALSE, EXPECT_TRUE
from limits import INT_MIN

def Test_FactorialTest_Negative():
    EXPECT_EQ(1, Factorial(-5))
    EXPECT_EQ(1, Factorial(-1))
    EXPECT_GT(Factorial(-10), 0)

def Test_FactorialTest_Zero():
    EXPECT_EQ(1, Factorial(0))

def Test_FactorialTest_Positive():
    EXPECT_EQ(1, Factorial(1))
    EXPECT_EQ(2, Factorial(2))
    EXPECT_EQ(6, Factorial(3))
    EXPECT_EQ(40320, Factorial(8))

def Test_IsPrimeTest_Negative():
    EXPECT_FALSE(IsPrime(-1))
    EXPECT_FALSE(IsPrime(-2))
    EXPECT_FALSE(IsPrime(INT_MIN))

def Test_IsPrimeTest_Trivial():
    EXPECT_FALSE(IsPrime(0))
    EXPECT_FALSE(IsPrime(1))
    EXPECT_TRUE(IsPrime(2))
    EXPECT_TRUE(IsPrime(3))

def Test_IsPrimeTest_Positive():
    EXPECT_FALSE(IsPrime(4))
    EXPECT_TRUE(IsPrime(5))
    EXPECT_FALSE(IsPrime(6))
    EXPECT_TRUE(IsPrime(23))