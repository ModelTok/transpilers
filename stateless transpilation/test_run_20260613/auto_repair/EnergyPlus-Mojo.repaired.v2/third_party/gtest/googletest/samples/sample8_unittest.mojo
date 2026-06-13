from prime_tables import OnTheFlyPrimeTable, PreCalculatedPrimeTable
from gtest import TestWithParam, Bool, Values, Combine
from gtest import expect_false as EXPECT_FALSE, expect_true as EXPECT_TRUE, expect_eq as EXPECT_EQ
from gtest import register_test_p as TEST_P, instantiate_test_suite_p as INSTANTIATE_TEST_SUITE_P

struct HybridPrimeTable(PrimeTable):
    var on_the_fly_impl_: OnTheFlyPrimeTable
    var precalc_impl_: Optional[PreCalculatedPrimeTable]
    var max_precalculated_: Int

    def __init__(inout self, force_on_the_fly: Bool, max_precalculated: Int):
        self.on_the_fly_impl_ = OnTheFlyPrimeTable()
        if force_on_the_fly:
            self.precalc_impl_ = None
        else:
            self.precalc_impl_ = PreCalculatedPrimeTable(max_precalculated)
        self.max_precalculated_ = max_precalculated

    def __del__(owned self):
        # Destructor equivalent: Mojo automatically destroys members.

    def IsPrime(self, n: Int) -> Bool:
        if self.precalc_impl_ is not None and n < self.max_precalculated_:
            return self.precalc_impl_.value().IsPrime(n)
        else:
            return self.on_the_fly_impl_.IsPrime(n)

    def GetNextPrime(self, p: Int) -> Int:
        var next_prime: Int = -1
        if self.precalc_impl_ is not None and p < self.max_precalculated_:
            next_prime = self.precalc_impl_.value().GetNextPrime(p)
        if next_prime != -1:
            return next_prime
        else:
            return self.on_the_fly_impl_.GetNextPrime(p)

# using declarations translated to direct import
# use ::testing::TestWithParam -> imported
# using ::testing::Bool -> imported
# using ::testing::Values -> imported
# using ::testing::Combine -> imported

struct PrimeTableTest(TestWithParam[Tuple[Bool, Int]]):
    var table_: HybridPrimeTable

    def SetUp(inout self):
        var force_on_the_fly: Bool
        var max_precalculated: Int
        (force_on_the_fly, max_precalculated) = self.GetParam()
        self.table_ = HybridPrimeTable(force_on_the_fly, max_precalculated)

    def TearDown(inout self):
        # No deletion needed; table_ will be destroyed when struct goes out of scope

@TEST_P(PrimeTableTest, ReturnsFalseForNonPrimes)
def PrimeTableTest_ReturnsFalseForNonPrimes():
    var test: PrimeTableTest
    test.SetUp()
    EXPECT_FALSE(test.table_.IsPrime(-5))
    EXPECT_FALSE(test.table_.IsPrime(0))
    EXPECT_FALSE(test.table_.IsPrime(1))
    EXPECT_FALSE(test.table_.IsPrime(4))
    EXPECT_FALSE(test.table_.IsPrime(6))
    EXPECT_FALSE(test.table_.IsPrime(100))
    test.TearDown()

@TEST_P(PrimeTableTest, ReturnsTrueForPrimes)
def PrimeTableTest_ReturnsTrueForPrimes():
    var test: PrimeTableTest
    test.SetUp()
    EXPECT_TRUE(test.table_.IsPrime(2))
    EXPECT_TRUE(test.table_.IsPrime(3))
    EXPECT_TRUE(test.table_.IsPrime(5))
    EXPECT_TRUE(test.table_.IsPrime(7))
    EXPECT_TRUE(test.table_.IsPrime(11))
    EXPECT_TRUE(test.table_.IsPrime(131))
    test.TearDown()

@TEST_P(PrimeTableTest, CanGetNextPrime)
def PrimeTableTest_CanGetNextPrime():
    var test: PrimeTableTest
    test.SetUp()
    EXPECT_EQ(2, test.table_.GetNextPrime(0))
    EXPECT_EQ(3, test.table_.GetNextPrime(2))
    EXPECT_EQ(5, test.table_.GetNextPrime(3))
    EXPECT_EQ(7, test.table_.GetNextPrime(5))
    EXPECT_EQ(11, test.table_.GetNextPrime(7))
    EXPECT_EQ(131, test.table_.GetNextPrime(128))
    test.TearDown()

INSTANTIATE_TEST_SUITE_P(MeaningfulTestParameters, PrimeTableTest, Combine(Bool(), Values(1, 10)))