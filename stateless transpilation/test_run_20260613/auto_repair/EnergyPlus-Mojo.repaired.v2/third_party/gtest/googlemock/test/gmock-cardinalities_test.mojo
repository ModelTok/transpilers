from gmock import (
    AnyNumber,
    AtLeast,
    AtMost,
    Between,
    Cardinality,
    CardinalityInterface,
    Exactly,
    MakeCardinality,
    MOCK_METHOD0,
)
from gtest import (
    TEST,
    EXPECT_TRUE,
    EXPECT_FALSE,
    EXPECT_EQ,
    EXPECT_NONFATAL_FAILURE,
    EXPECT_PRED_FORMAT2,
    IsSubstring,
)
from gtest.gtest-spi import (
    # No imports needed; macros are available
)
from std import String, StringBuilder, Int

# Mock class
class MockFoo:
    def __init__(inout self):

    # MOCK_METHOD0(Bar, int())
    def Bar(self) -> Int:
        # Mock implementation placeholder
        return 0

    # GTEST_DISALLOW_COPY_AND_ASSIGN_(MockFoo) - omitted in Mojo

# Test cases
TEST(CardinalityTest, IsDefaultConstructable):
    var c: Cardinality = Cardinality()

TEST(CardinalityTest, IsCopyable):
    var c: Cardinality = Exactly(1)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(1))
    EXPECT_TRUE(c.IsSaturatedByCallCount(1))
    c = Exactly(2)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(1))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_TRUE(c.IsSaturatedByCallCount(2))

TEST(CardinalityTest, IsOverSaturatedByCallCountWorks):
    var c: Cardinality = AtMost(5)
    EXPECT_FALSE(c.IsOverSaturatedByCallCount(4))
    EXPECT_FALSE(c.IsOverSaturatedByCallCount(5))
    EXPECT_TRUE(c.IsOverSaturatedByCallCount(6))

TEST(CardinalityTest, CanDescribeActualCallCount):
    var ss0: String = String()
    Cardinality.DescribeActualCallCountTo(0, &ss0)
    EXPECT_EQ("never called", ss0)
    var ss1: String = String()
    Cardinality.DescribeActualCallCountTo(1, &ss1)
    EXPECT_EQ("called once", ss1)
    var ss2: String = String()
    Cardinality.DescribeActualCallCountTo(2, &ss2)
    EXPECT_EQ("called twice", ss2)
    var ss3: String = String()
    Cardinality.DescribeActualCallCountTo(3, &ss3)
    EXPECT_EQ("called 3 times", ss3)

TEST(AnyNumber, Works):
    var c: Cardinality = AnyNumber()
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(1))
    EXPECT_FALSE(c.IsSaturatedByCallCount(1))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(9))
    EXPECT_FALSE(c.IsSaturatedByCallCount(9))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "called any number of times", ss)

TEST(AnyNumberTest, HasCorrectBounds):
    var c: Cardinality = AnyNumber()
    EXPECT_EQ(0, c.ConservativeLowerBound())
    EXPECT_EQ(Int.MAX, c.ConservativeUpperBound())

TEST(AtLeastTest, OnNegativeNumber):
    EXPECT_NONFATAL_FAILURE({
        AtLeast(-1)
    }, "The invocation lower bound must be >= 0")

TEST(AtLeastTest, OnZero):
    var c: Cardinality = AtLeast(0)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(1))
    EXPECT_FALSE(c.IsSaturatedByCallCount(1))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "any number of times", ss)

TEST(AtLeastTest, OnPositiveNumber):
    var c: Cardinality = AtLeast(2)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(1))
    EXPECT_FALSE(c.IsSaturatedByCallCount(1))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_FALSE(c.IsSaturatedByCallCount(2))
    var ss1: String = String()
    AtLeast(1).DescribeTo(&ss1)
    EXPECT_PRED_FORMAT2(IsSubstring, "at least once", ss1)
    var ss2: String = String()
    c.DescribeTo(&ss2)
    EXPECT_PRED_FORMAT2(IsSubstring, "at least twice", ss2)
    var ss3: String = String()
    AtLeast(3).DescribeTo(&ss3)
    EXPECT_PRED_FORMAT2(IsSubstring, "at least 3 times", ss3)

TEST(AtLeastTest, HasCorrectBounds):
    var c: Cardinality = AtLeast(2)
    EXPECT_EQ(2, c.ConservativeLowerBound())
    EXPECT_EQ(Int.MAX, c.ConservativeUpperBound())

TEST(AtMostTest, OnNegativeNumber):
    EXPECT_NONFATAL_FAILURE({
        AtMost(-1)
    }, "The invocation upper bound must be >= 0")

TEST(AtMostTest, OnZero):
    var c: Cardinality = AtMost(0)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_TRUE(c.IsSaturatedByCallCount(0))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(1))
    EXPECT_TRUE(c.IsSaturatedByCallCount(1))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "never called", ss)

TEST(AtMostTest, OnPositiveNumber):
    var c: Cardinality = AtMost(2)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(1))
    EXPECT_FALSE(c.IsSaturatedByCallCount(1))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_TRUE(c.IsSaturatedByCallCount(2))
    var ss1: String = String()
    AtMost(1).DescribeTo(&ss1)
    EXPECT_PRED_FORMAT2(IsSubstring, "called at most once", ss1)
    var ss2: String = String()
    c.DescribeTo(&ss2)
    EXPECT_PRED_FORMAT2(IsSubstring, "called at most twice", ss2)
    var ss3: String = String()
    AtMost(3).DescribeTo(&ss3)
    EXPECT_PRED_FORMAT2(IsSubstring, "called at most 3 times", ss3)

TEST(AtMostTest, HasCorrectBounds):
    var c: Cardinality = AtMost(2)
    EXPECT_EQ(0, c.ConservativeLowerBound())
    EXPECT_EQ(2, c.ConservativeUpperBound())

TEST(BetweenTest, OnNegativeStart):
    EXPECT_NONFATAL_FAILURE({
        Between(-1, 2)
    }, "The invocation lower bound must be >= 0, but is actually -1")

TEST(BetweenTest, OnNegativeEnd):
    EXPECT_NONFATAL_FAILURE({
        Between(1, -2)
    }, "The invocation upper bound must be >= 0, but is actually -2")

TEST(BetweenTest, OnStartBiggerThanEnd):
    EXPECT_NONFATAL_FAILURE({
        Between(2, 1)
    }, "The invocation upper bound (1) must be >= the invocation lower bound (2)")

TEST(BetweenTest, OnZeroStartAndZeroEnd):
    var c: Cardinality = Between(0, 0)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_TRUE(c.IsSaturatedByCallCount(0))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(1))
    EXPECT_TRUE(c.IsSaturatedByCallCount(1))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "never called", ss)

TEST(BetweenTest, OnZeroStartAndNonZeroEnd):
    var c: Cardinality = Between(0, 2)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_TRUE(c.IsSaturatedByCallCount(2))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(4))
    EXPECT_TRUE(c.IsSaturatedByCallCount(4))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "called at most twice", ss)

TEST(BetweenTest, OnSameStartAndEnd):
    var c: Cardinality = Between(3, 3)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(2))
    EXPECT_FALSE(c.IsSaturatedByCallCount(2))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(3))
    EXPECT_TRUE(c.IsSaturatedByCallCount(3))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(4))
    EXPECT_TRUE(c.IsSaturatedByCallCount(4))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "called 3 times", ss)

TEST(BetweenTest, OnDifferentStartAndEnd):
    var c: Cardinality = Between(3, 5)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(2))
    EXPECT_FALSE(c.IsSaturatedByCallCount(2))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(3))
    EXPECT_FALSE(c.IsSaturatedByCallCount(3))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(5))
    EXPECT_TRUE(c.IsSaturatedByCallCount(5))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(6))
    EXPECT_TRUE(c.IsSaturatedByCallCount(6))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "called between 3 and 5 times", ss)

TEST(BetweenTest, HasCorrectBounds):
    var c: Cardinality = Between(3, 5)
    EXPECT_EQ(3, c.ConservativeLowerBound())
    EXPECT_EQ(5, c.ConservativeUpperBound())

TEST(ExactlyTest, OnNegativeNumber):
    EXPECT_NONFATAL_FAILURE({
        Exactly(-1)
    }, "The invocation lower bound must be >= 0")

TEST(ExactlyTest, OnZero):
    var c: Cardinality = Exactly(0)
    EXPECT_TRUE(c.IsSatisfiedByCallCount(0))
    EXPECT_TRUE(c.IsSaturatedByCallCount(0))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(1))
    EXPECT_TRUE(c.IsSaturatedByCallCount(1))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_PRED_FORMAT2(IsSubstring, "never called", ss)

TEST(ExactlyTest, OnPositiveNumber):
    var c: Cardinality = Exactly(2)
    EXPECT_FALSE(c.IsSatisfiedByCallCount(0))
    EXPECT_FALSE(c.IsSaturatedByCallCount(0))
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_TRUE(c.IsSaturatedByCallCount(2))
    var ss1: String = String()
    Exactly(1).DescribeTo(&ss1)
    EXPECT_PRED_FORMAT2(IsSubstring, "called once", ss1)
    var ss2: String = String()
    c.DescribeTo(&ss2)
    EXPECT_PRED_FORMAT2(IsSubstring, "called twice", ss2)
    var ss3: String = String()
    Exactly(3).DescribeTo(&ss3)
    EXPECT_PRED_FORMAT2(IsSubstring, "called 3 times", ss3)

TEST(ExactlyTest, HasCorrectBounds):
    var c: Cardinality = Exactly(3)
    EXPECT_EQ(3, c.ConservativeLowerBound())
    EXPECT_EQ(3, c.ConservativeUpperBound())

class EvenCardinality(CardinalityInterface):
    def IsSatisfiedByCallCount(self, call_count: Int) -> Bool:
        return (call_count % 2 == 0)

    def IsSaturatedByCallCount(self, call_count: Int) -> Bool:
        return False

    def DescribeTo(self, ss: inout String):
        ss += "called even number of times"

TEST(MakeCardinalityTest, ConstructsCardinalityFromInterface):
    var c: Cardinality = MakeCardinality(EvenCardinality())
    EXPECT_TRUE(c.IsSatisfiedByCallCount(2))
    EXPECT_FALSE(c.IsSatisfiedByCallCount(3))
    EXPECT_FALSE(c.IsSaturatedByCallCount(10000))
    var ss: String = String()
    c.DescribeTo(&ss)
    EXPECT_EQ("called even number of times", ss)