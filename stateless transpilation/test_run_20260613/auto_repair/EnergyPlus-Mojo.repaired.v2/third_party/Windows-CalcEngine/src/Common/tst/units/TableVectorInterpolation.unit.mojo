from ......WCECommon import Table

# Mimic gtest testing::Test base class
class Test:

# Helper assertion functions to replace gtest macros
def EXPECT_NEAR(actual: Float64, expected: Float64, abs_error: Float64):
    if abs(actual - expected) > abs_error:
        abort("EXPECT_NEAR failed: actual={} expected={} error={}".format(actual, expected, abs_error))

def EXPECT_EQ(actual: Bool, expected: Bool):
    if actual != expected:
        abort("EXPECT_EQ failed: actual={} expected={}".format(actual, expected))

def ASSERT_EQ(actual: Bool, expected: Bool):
    if actual != expected:
        abort("ASSERT_EQ failed: actual={} expected={}".format(actual, expected))

class TestTableVectorInterpolation(Test):
    var m_Table: List[Table.point]

    def __init__(inout self):
        self.m_Table = List[Table.point](
            Table.point(1, 2),
            Table.point(2, 4),
            Table.point(3, 8),
        )

    def SetUp(inout self):

    def getTable(self) -> List[Table.point]:
        return self.m_Table

class InterpolationAtMidPoint(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = self.getTable()
        let interpolationValue = 1.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue)
        let correctVal = 3.0
        ASSERT_EQ(val.has_value(), True)
        EXPECT_NEAR(val.value(), correctVal, 1e-6)

class InterpolationBeforeTheStartPoint(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = self.getTable()
        let interpolationValue = 0.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue)
        EXPECT_EQ(val.has_value(), False)

class InterpolationAfterTheEndPoint(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = self.getTable()
        let interpolationValue = 3.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue)
        EXPECT_EQ(val.has_value(), False)

class InterpolationBeforeTheStartPointWithExtrapolation(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = self.getTable()
        let interpolationValue = 0.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue, Table.Extrapolate.Yes)
        let correctVal = 2.0
        EXPECT_NEAR(val.value(), correctVal, 1e-6)

class InterpolationAfterTheEndPointWithExtrapolation(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = self.getTable()
        let interpolationValue = 3.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue, Table.Extrapolate.Yes)
        let correctVal = 8.0
        EXPECT_NEAR(val.value(), correctVal, 1e-6)

class InterpolationBeforeTheStartPointWithExtrapolationWithNull(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = List[Table.point](
            Table.point(1, Optional[Float64]()),
            Table.point(2, 4),
            Table.point(3.5, 6),
            Table.point(3, 8),
        )
        let interpolationValue = 0.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue, Table.Extrapolate.Yes)
        let correctVal = 4.0
        EXPECT_NEAR(val.value(), correctVal, 1e-6)

class InterpolationAfterTheEndPointWithExtrapolationWithNull(TestTableVectorInterpolation):
    def __init__(inout self):
        super().__init__()
        self.SetUp()

    def run(self):
        let tbl = List[Table.point](
            Table.point(1, 2),
            Table.point(2, 4),
            Table.point(3.5, 6),
            Table.point(3, Optional[Float64]()),
        )
        let interpolationValue = 3.5
        let val = Table.tableColumnInterpolation(tbl, interpolationValue, Table.Extrapolate.Yes)
        let correctVal = 6.0
        EXPECT_NEAR(val.value(), correctVal, 1e-6)

def main():
    InterpolationAtMidPoint().run()
    InterpolationBeforeTheStartPoint().run()
    InterpolationAfterTheEndPoint().run()
    InterpolationBeforeTheStartPointWithExtrapolation().run()
    InterpolationAfterTheEndPointWithExtrapolation().run()
    InterpolationBeforeTheStartPointWithExtrapolationWithNull().run()
    InterpolationAfterTheEndPointWithExtrapolationWithNull().run()
<<<FILE>>>