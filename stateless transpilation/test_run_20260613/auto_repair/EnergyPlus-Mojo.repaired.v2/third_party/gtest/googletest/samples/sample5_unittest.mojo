from gtest import *
from sample1 import *
from sample3-inl import *

@value
class QuickTest(testing.Test):
    var start_time_: time_t

    def SetUp(self):
        self.start_time_ = time(None)

    def TearDown(self):
        let end_time: time_t = time(None)
        EXPECT_TRUE(end_time - self.start_time_ <= 5) << "The test took too long."

@value
class IntegerFunctionTest(QuickTest):

TEST_F(IntegerFunctionTest, Factorial):
    EXPECT_EQ(1, Factorial(-5))
    EXPECT_EQ(1, Factorial(-1))
    EXPECT_GT(Factorial(-10), 0)
    EXPECT_EQ(1, Factorial(0))
    EXPECT_EQ(1, Factorial(1))
    EXPECT_EQ(2, Factorial(2))
    EXPECT_EQ(6, Factorial(3))
    EXPECT_EQ(40320, Factorial(8))

TEST_F(IntegerFunctionTest, IsPrime):
    EXPECT_FALSE(IsPrime(-1))
    EXPECT_FALSE(IsPrime(-2))
    EXPECT_FALSE(IsPrime(INT_MIN))
    EXPECT_FALSE(IsPrime(0))
    EXPECT_FALSE(IsPrime(1))
    EXPECT_TRUE(IsPrime(2))
    EXPECT_TRUE(IsPrime(3))
    EXPECT_FALSE(IsPrime(4))
    EXPECT_TRUE(IsPrime(5))
    EXPECT_FALSE(IsPrime(6))
    EXPECT_TRUE(IsPrime(23))

@value
class QueueTest(QuickTest):
    var q0_: Queue[Int]
    var q1_: Queue[Int]
    var q2_: Queue[Int]

    def SetUp(self):
        QuickTest.SetUp(self)
        self.q1_.Enqueue(1)
        self.q2_.Enqueue(2)
        self.q2_.Enqueue(3)

TEST_F(QueueTest, DefaultConstructor):
    EXPECT_EQ(0u, self.q0_.Size())

TEST_F(QueueTest, Dequeue):
    var n: Int* = self.q0_.Dequeue()
    EXPECT_TRUE(n == None)
    n = self.q1_.Dequeue()
    EXPECT_TRUE(n != None)
    EXPECT_EQ(1, *n)
    EXPECT_EQ(0u, self.q1_.Size())
    delete n
    n = self.q2_.Dequeue()
    EXPECT_TRUE(n != None)
    EXPECT_EQ(2, *n)
    EXPECT_EQ(1u, self.q2_.Size())
    delete n