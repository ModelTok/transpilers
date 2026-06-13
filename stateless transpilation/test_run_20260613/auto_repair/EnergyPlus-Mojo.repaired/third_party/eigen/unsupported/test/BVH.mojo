from Eigen.Core import Matrix
from Eigen.Geometry import AlignedBox
from unsupported.Eigen.BVH import KdBVH, BVIntersect, BVMinimize
from random import random_float64
from math import sqrt, inf

# Define g_repeat as a global variable (simulating Eigen's test framework)
var g_repeat: Int = 1

# Define bounding_box for VectorType in Eigen namespace
def bounding_box[Scalar: AnyType, Dim: Int](v: Matrix[Scalar, Dim, 1]) -> AlignedBox[Scalar, Dim]:
    return AlignedBox[Scalar, Dim](v)

struct Ball[Dim: Int]:
    var center: Matrix[float64, Dim, 1]
    var radius: float64

    def __init__(inout self):

    def __init__(inout self, c: Matrix[float64, Dim, 1], r: float64):
        self.center = c
        self.radius = r

def bounding_box[Dim: Int](b: Ball[Dim]) -> AlignedBox[float64, Dim]:
    return AlignedBox[float64, Dim](b.center.array() - b.radius, b.center.array() + b.radius)

def SQR(x: float64) -> float64:
    return x * x

struct BallPointStuff[Dim: Int]:
    var p: Matrix[float64, Dim, 1]
    var calls: Int
    var count: Int

    def __init__(inout self):
        self.calls = 0
        self.count = 0

    def __init__(inout self, inP: Matrix[float64, Dim, 1]):
        self.p = inP
        self.calls = 0
        self.count = 0

    def intersectVolume(inout self, r: AlignedBox[float64, Dim]) -> Bool:
        self.calls += 1
        return r.contains(self.p)

    def intersectObject(inout self, b: Ball[Dim]) -> Bool:
        self.calls += 1
        if (b.center - self.p).squaredNorm() < SQR(b.radius):
            self.count += 1
        return False

    def intersectVolumeVolume(inout self, r1: AlignedBox[float64, Dim], r2: AlignedBox[float64, Dim]) -> Bool:
        self.calls += 1
        return not (r1.intersection(r2)).isNull()

    def intersectVolumeObject(inout self, r: AlignedBox[float64, Dim], b: Ball[Dim]) -> Bool:
        self.calls += 1
        return r.squaredExteriorDistance(b.center) < SQR(b.radius)

    def intersectObjectVolume(inout self, b: Ball[Dim], r: AlignedBox[float64, Dim]) -> Bool:
        self.calls += 1
        return r.squaredExteriorDistance(b.center) < SQR(b.radius)

    def intersectObjectObject(inout self, b1: Ball[Dim], b2: Ball[Dim]) -> Bool:
        self.calls += 1
        if (b1.center - b2.center).norm() < b1.radius + b2.radius:
            self.count += 1
        return False

    def intersectVolumeObject(inout self, r: AlignedBox[float64, Dim], v: Matrix[float64, Dim, 1]) -> Bool:
        self.calls += 1
        return r.contains(v)

    def intersectObjectObject(inout self, b: Ball[Dim], v: Matrix[float64, Dim, 1]) -> Bool:
        self.calls += 1
        if (b.center - v).squaredNorm() < SQR(b.radius):
            self.count += 1
        return False

    def minimumOnVolume(inout self, r: AlignedBox[float64, Dim]) -> float64:
        self.calls += 1
        return r.squaredExteriorDistance(self.p)

    def minimumOnObject(inout self, b: Ball[Dim]) -> float64:
        self.calls += 1
        return max(0.0, (b.center - self.p).squaredNorm() - SQR(b.radius))

    def minimumOnVolumeVolume(inout self, r1: AlignedBox[float64, Dim], r2: AlignedBox[float64, Dim]) -> float64:
        self.calls += 1
        return r1.squaredExteriorDistance(r2)

    def minimumOnVolumeObject(inout self, r: AlignedBox[float64, Dim], b: Ball[Dim]) -> float64:
        self.calls += 1
        return SQR(max(0.0, r.exteriorDistance(b.center) - b.radius))

    def minimumOnObjectVolume(inout self, b: Ball[Dim], r: AlignedBox[float64, Dim]) -> float64:
        self.calls += 1
        return SQR(max(0.0, r.exteriorDistance(b.center) - b.radius))

    def minimumOnObjectObject(inout self, b1: Ball[Dim], b2: Ball[Dim]) -> float64:
        self.calls += 1
        return SQR(max(0.0, (b1.center - b2.center).norm() - b1.radius - b2.radius))

    def minimumOnVolumeObject(inout self, r: AlignedBox[float64, Dim], v: Matrix[float64, Dim, 1]) -> float64:
        self.calls += 1
        return r.squaredExteriorDistance(v)

    def minimumOnObjectObject(inout self, b: Ball[Dim], v: Matrix[float64, Dim, 1]) -> float64:
        self.calls += 1
        return SQR(max(0.0, (b.center - v).norm() - b.radius))

struct TreeTest[Dim: Int]:
    alias VectorType = Matrix[float64, Dim, 1]
    alias VectorTypeList = List[VectorType]
    alias BallType = Ball[Dim]
    alias BallTypeList = List[BallType]
    alias BoxType = AlignedBox[float64, Dim]

    def testIntersect1(inout self):
        var b = BallTypeList()
        for i in range(500):
            b.append(BallType(VectorType.random(), 0.5 * random_float64()))
        var tree = KdBVH[float64, Dim, BallType](b.begin(), b.end())
        var pt = VectorType.random()
        var i1 = BallPointStuff[Dim](pt)
        var i2 = BallPointStuff[Dim](pt)
        for i in range(b.size):
            i1.intersectObject(b[i])
        BVIntersect(tree, i2)
        assert(i1.count == i2.count)

    def testMinimize1(inout self):
        var b = BallTypeList()
        for i in range(500):
            b.append(BallType(VectorType.random(), 0.01 * random_float64()))
        var tree = KdBVH[float64, Dim, BallType](b.begin(), b.end())
        var pt = VectorType.random()
        var i1 = BallPointStuff[Dim](pt)
        var i2 = BallPointStuff[Dim](pt)
        var m1 = float64.max
        var m2 = m1
        for i in range(b.size):
            m1 = min(m1, i1.minimumOnObject(b[i]))
        m2 = BVMinimize(tree, i2)
        assert(abs(m1 - m2) < 1e-6)

    def testIntersect2(inout self):
        var b = BallTypeList()
        var v = VectorTypeList()
        for i in range(50):
            b.append(BallType(VectorType.random(), 0.5 * random_float64()))
            for j in range(3):
                v.append(VectorType.random())
        var tree = KdBVH[float64, Dim, BallType](b.begin(), b.end())
        var vTree = KdBVH[float64, Dim, VectorType](v.begin(), v.end())
        var i1 = BallPointStuff[Dim]()
        var i2 = BallPointStuff[Dim]()
        for i in range(b.size):
            for j in range(v.size):
                i1.intersectObjectObject(b[i], v[j])
        BVIntersect(tree, vTree, i2)
        assert(i1.count == i2.count)

    def testMinimize2(inout self):
        var b = BallTypeList()
        var v = VectorTypeList()
        for i in range(50):
            b.append(BallType(VectorType.random(), 1e-7 + 1e-6 * random_float64()))
            for j in range(3):
                v.append(VectorType.random())
        var tree = KdBVH[float64, Dim, BallType](b.begin(), b.end())
        var vTree = KdBVH[float64, Dim, VectorType](v.begin(), v.end())
        var i1 = BallPointStuff[Dim]()
        var i2 = BallPointStuff[Dim]()
        var m1 = float64.max
        var m2 = m1
        for i in range(b.size):
            for j in range(v.size):
                m1 = min(m1, i1.minimumOnObjectObject(b[i], v[j]))
        m2 = BVMinimize(tree, vTree, i2)
        assert(abs(m1 - m2) < 1e-6)

def test_BVH():
    for i in range(g_repeat):
        @parameter
        if True:  # EIGEN_TEST_PART_1
            var test2 = TreeTest[2]()
            test2.testIntersect1()
            test2.testMinimize1()
            test2.testIntersect2()
            test2.testMinimize2()
        @parameter
        if True:  # EIGEN_TEST_PART_2
            var test3 = TreeTest[3]()
            test3.testIntersect1()
            test3.testMinimize1()
            test3.testIntersect2()
            test3.testMinimize2()
        @parameter
        if True:  # EIGEN_TEST_PART_3
            var test4 = TreeTest[4]()
            test4.testIntersect1()
            test4.testMinimize1()
            test4.testIntersect2()
            test4.testMinimize2()