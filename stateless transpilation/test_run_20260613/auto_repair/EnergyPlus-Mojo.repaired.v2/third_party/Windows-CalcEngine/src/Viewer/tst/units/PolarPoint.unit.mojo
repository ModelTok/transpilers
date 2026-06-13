from WCEViewer import CPolarPoint2D

def EXPECT_NEAR(expected: Float64, actual: Float64, tolerance: Float64) raises:
    if abs(expected - actual) > tolerance:
        print("EXPECT_NEAR failed: expected", expected, "actual", actual, "tolerance", tolerance)
        raise Error("assertion")

def SCOPED_TRACE(message: String):
    print(message)

struct TestPolarPoint:
    def SetUp(self): pass

def PolarPointTest1() raises:
    var test = TestPolarPoint()
    test.SetUp()
    SCOPED_TRACE("Begin Test: Polar point conversions (1).")
    var aPoint = CPolarPoint2D(90, 1)
    var x = aPoint.x()
    var y = aPoint.y()
    EXPECT_NEAR(0, x, 1e-6)
    EXPECT_NEAR(1, y, 1e-6)
    aPoint.setCartesian(0, -1)
    var theta = aPoint.theta()
    var radius = aPoint.radius()
    EXPECT_NEAR(270, theta, 1e-6)
    EXPECT_NEAR(1, radius, 1e-6)
    aPoint.setCartesian(0, 0)
    theta = aPoint.theta()
    radius = aPoint.radius()
    EXPECT_NEAR(0, theta, 1e-6)
    EXPECT_NEAR(0, radius, 1e-6)
    aPoint.setCartesian(1, 1)
    theta = aPoint.theta()
    radius = aPoint.radius()
    EXPECT_NEAR(45, theta, 1e-6)
    EXPECT_NEAR(1.41421356, radius, 1e-6)
    aPoint.setCartesian(1, -1)
    theta = aPoint.theta()
    radius = aPoint.radius()
    EXPECT_NEAR(-45, theta, 1e-6)
    EXPECT_NEAR(1.41421356, radius, 1e-6)

def PolarPointTest2() raises:
    var test = TestPolarPoint()
    test.SetUp()
    SCOPED_TRACE("Begin Test: Polar point conversions (2).")
    var aPoint = CPolarPoint2D(259, 1.58)
    var x = aPoint.x()
    var y = aPoint.y()
    EXPECT_NEAR(-0.301478213, x, 1e-6)
    EXPECT_NEAR(-1.55097095, y, 1e-6)

def PolarPointTest3() raises:
    var test = TestPolarPoint()
    test.SetUp()
    SCOPED_TRACE("Begin Test: Polar point conversions (3).")
    var aPoint = CPolarPoint2D(43, 0.76)
    var x = aPoint.x()
    var y = aPoint.y()
    EXPECT_NEAR(0.555828813, x, 1e-6)
    EXPECT_NEAR(0.518318754, y, 1e-6)

def main() raises:
    PolarPointTest1()
    PolarPointTest2()
    PolarPointTest3()