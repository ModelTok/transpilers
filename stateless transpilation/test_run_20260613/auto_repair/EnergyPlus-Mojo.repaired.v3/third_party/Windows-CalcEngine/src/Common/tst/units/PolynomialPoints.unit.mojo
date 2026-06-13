from ...WCECommon import Polynom, PolynomialPoints360deg

def expect_near(expected: Float64, actual: Float64, tolerance: Float64):
    if abs(expected - actual) > tolerance:
        print("FAIL: expected", expected, "but got", actual, "diff", abs(expected - actual))
    else:
        print("PASS: expected", expected, "got", actual)

def scoped_trace(message: String):
    print(message)

struct PolynomialPointsTest:
    var m_Points: PolynomialPoints360deg

    def __init__(inout self):
        self.m_Points = PolynomialPoints360deg()

    def SetUp(inout self):
        let poly1 = Polynom(List[Float64](-6.75, 8.65, -0.75))
        let poly2 = Polynom(List[Float64](1.5, -2.5, 0.3))
        let poly3 = Polynom(List[Float64](2.4, 20, 1.3, -0.24))
        self.m_Points.storePoint(10, poly1)
        self.m_Points.storePoint(20, poly2)
        self.m_Points.storePoint(30, poly3)

    def getPoints(self) -> PolynomialPoints360deg:
        return self.m_Points

def TestClosestPointInRange():
    scoped_trace("Begin Test: Polynomial points.")
    var testObj = PolynomialPointsTest()
    testObj.SetUp()
    let val = testObj.getPoints().valueAt(15, 12)
    expect_near(1.875, val, 1e-6)

def TestClosestPointOnLowerRange():
    scoped_trace("Begin Test: Polynomial points.")
    var testObj = PolynomialPointsTest()
    testObj.SetUp()
    let val = testObj.getPoints().valueAt(5, 12)
    expect_near(-10.570147, val, 1e-6)

def TestClosestPointHigerRange():
    scoped_trace("Begin Test: Polynomial points.")
    var testObj = PolynomialPointsTest()
    testObj.SetUp()
    let val = testObj.getPoints().valueAt(150, 12)
    expect_near(5.763529, val, 1e-6)

def main():
    TestClosestPointInRange()
    TestClosestPointOnLowerRange()
    TestClosestPointHigerRange()