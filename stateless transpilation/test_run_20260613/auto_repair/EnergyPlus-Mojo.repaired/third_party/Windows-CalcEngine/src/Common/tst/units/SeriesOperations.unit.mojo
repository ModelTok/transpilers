from WCECommon import CSeries
from memory import try, except as catch, Error

struct TestSeriesOperations:
    var m_Series1: CSeries
    var m_Series2: CSeries

    def __init__(inout self):
        self.m_Series1 = CSeries()
        self.m_Series2 = CSeries()

    def SetUp(inout self):
        self.m_Series1 = CSeries({{0.50, 3.3}, {0.51, 5.2}, {0.52, 8.9}, {0.53, 10.1}, {0.54, 11.4}})
        self.m_Series2 = CSeries({{0.50, 1.2}, {0.51, 6.1}, {0.52, 7.3}, {0.53, 9.5}, {0.54, 10.4}})

    def getSeries1(self) -> CSeries:
        return self.m_Series1

    def getSeries2(self) -> CSeries:
        return self.m_Series2

def TestSeriesMultiplication():
    print("Begin Test: Test multiplication over the range of data.")
    var fixture = TestSeriesOperations()
    fixture.SetUp()
    var ser1 = fixture.getSeries1()
    var ser2 = fixture.getSeries2()
    var result = ser1 * ser2
    var correctResults = List[Float64](3.96, 31.72, 64.97, 95.95, 118.56)
    assert len(result) == len(correctResults)
    for i in range(len(result)):
        assert abs(correctResults[i] - result[i].value()) < 1e-6

def TestSeriesAddition():
    print("Begin Test: Test addition over the range of data.")
    var fixture = TestSeriesOperations()
    fixture.SetUp()
    var ser1 = fixture.getSeries1()
    var ser2 = fixture.getSeries2()
    var result = ser1 + ser2
    var correctResults = List[Float64](4.5, 11.3, 16.2, 19.6, 21.8)
    assert len(result) == len(correctResults)
    for i in range(len(result)):
        assert abs(correctResults[i] - result[i].value()) < 1e-6

def TestSeriesSubtraction():
    print("Begin Test: Test subtraction over the range of data.")
    var fixture = TestSeriesOperations()
    fixture.SetUp()
    var ser1 = fixture.getSeries1()
    var ser2 = fixture.getSeries2()
    var result = ser1 - ser2
    var correctResults = List[Float64](2.1, -0.9, 1.6, 0.6, 1.0)
    assert len(result) == len(correctResults)
    for i in range(len(result)):
        assert abs(correctResults[i] - result[i].value()) < 1e-6

def TestSeriesSubractionWithConstant():
    print("Begin Test: Test subtraction over the range of data.")
    var val: Float64 = 1.0
    var fixture = TestSeriesOperations()
    fixture.SetUp()
    var ser2 = fixture.getSeries2()
    var result = val - ser2
    var correctResults = List[Float64](-0.2, -5.1, -6.3, -8.5, -9.4)
    assert len(result) == len(correctResults)
    for i in range(len(result)):
        assert abs(correctResults[i] - result[i].value()) < 1e-6

def TestSeriesMultiplicationException():
    print("Begin Test: Test multiplication with exception.")
    var first = CSeries()
    first.addProperty(1, 12)
    var second = CSeries()
    second.addProperty(2, 11)
    second.addProperty(5, 34)
    try:
        var result = first * second
    catch e as Error:
        assert str(e) == "Wavelengths of two vectors are not the same. Cannot preform multiplication."