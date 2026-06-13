from prime_tables import PrimeTable, OnTheFlyPrimeTable, PreCalculatedPrimeTable
from gtest import TestWithParam, Values, TEST_P, EXPECT_FALSE, EXPECT_TRUE, EXPECT_EQ, INSTANTIATE_TEST_SUITE_P

type CreatePrimeTableFunc = fn() -> Pointer[PrimeTable]

def CreateOnTheFlyPrimeTable() -> Pointer[PrimeTable]:
    return new OnTheFlyPrimeTable()

def CreatePreCalculatedPrimeTable_1000() -> Pointer[PrimeTable]:
    return new PreCalculatedPrimeTable(1000)

struct PrimeTableTestSmpl7(TestWithParam[CreatePrimeTableFunc]):
    var table_: Pointer[PrimeTable]

    def __del__(owned self):
        delete self.table_

    def SetUp(inout self):
        self.table_ = (self.GetParam())()

    def TearDown(inout self):
        delete self.table_
        self.table_ = Pointer[PrimeTable]()

TEST_P(PrimeTableTestSmpl7, "ReturnsFalseForNonPrimes", fn(self: PrimeTableTestSmpl7):
    EXPECT_FALSE(self.table_.IsPrime(-5))
    EXPECT_FALSE(self.table_.IsPrime(0))
    EXPECT_FALSE(self.table_.IsPrime(1))
    EXPECT_FALSE(self.table_.IsPrime(4))
    EXPECT_FALSE(self.table_.IsPrime(6))
    EXPECT_FALSE(self.table_.IsPrime(100))
)

TEST_P(PrimeTableTestSmpl7, "ReturnsTrueForPrimes", fn(self: PrimeTableTestSmpl7):
    EXPECT_TRUE(self.table_.IsPrime(2))
    EXPECT_TRUE(self.table_.IsPrime(3))
    EXPECT_TRUE(self.table_.IsPrime(5))
    EXPECT_TRUE(self.table_.IsPrime(7))
    EXPECT_TRUE(self.table_.IsPrime(11))
    EXPECT_TRUE(self.table_.IsPrime(131))
)

TEST_P(PrimeTableTestSmpl7, "CanGetNextPrime", fn(self: PrimeTableTestSmpl7):
    EXPECT_EQ(2, self.table_.GetNextPrime(0))
    EXPECT_EQ(3, self.table_.GetNextPrime(2))
    EXPECT_EQ(5, self.table_.GetNextPrime(3))
    EXPECT_EQ(7, self.table_.GetNextPrime(5))
    EXPECT_EQ(11, self.table_.GetNextPrime(7))
    EXPECT_EQ(131, self.table_.GetNextPrime(128))
)

INSTANTIATE_TEST_SUITE_P("OnTheFlyAndPreCalculated", PrimeTableTestSmpl7,
                         Values(CreateOnTheFlyPrimeTable, CreatePreCalculatedPrimeTable_1000))
// namespace