from math import sqrt, min
from memory import List
from random import random_float64

# Define Vector2d as a simple 2D vector
struct Vector2d:
    var x: Float64
    var y: Float64

    def __init__(inout self, x: Float64, y: Float64):
        self.x = x
        self.y = y

    def __sub__(self, other: Vector2d) -> Vector2d:
        return Vector2d(self.x - other.x, self.y - other.y)

    def squaredNorm(self) -> Float64:
        return self.x * self.x + self.y * self.y

    @staticmethod
    def Random() -> Vector2d:
        return Vector2d(random_float64() * 2.0 - 1.0, random_float64() * 2.0 - 1.0)

# Define AlignedBox for 2D
struct AlignedBox(dim: Int):
    var min: Vector2d
    var max: Vector2d

    def __init__(inout self, v: Vector2d):
        self.min = v
        self.max = v

    def __init__(inout self, v1: Vector2d, v2: Vector2d):
        self.min = v1
        self.max = v2

    def squaredExteriorDistance(self, other: AlignedBox[2]) -> Float64:
        # Simplified: compute squared distance between two boxes
        var dx = max(0.0, self.min.x - other.max.x, other.min.x - self.max.x)
        var dy = max(0.0, self.min.y - other.max.y, other.min.y - self.max.y)
        return dx * dx + dy * dy

    def squaredExteriorDistance(self, v: Vector2d) -> Float64:
        var dx = max(0.0, self.min.x - v.x, v.x - self.max.x)
        var dy = max(0.0, self.min.y - v.y, v.y - self.max.y)
        return dx * dx + dy * dy

# Define Box2d alias
type Box2d = AlignedBox[2]

# bounding_box function (as in namespace Eigen)
def bounding_box(v: Vector2d) -> Box2d:
    return Box2d(v, v)  # compute the bounding box of a single point

# PointPointMinimizer struct
struct PointPointMinimizer:
    var calls: Int

    def __init__(inout self):
        self.calls = 0

    type Scalar = Float64

    def minimumOnVolumeVolume(inout self, r1: Box2d, r2: Box2d) -> Float64:
        self.calls += 1
        return r1.squaredExteriorDistance(r2)

    def minimumOnVolumeObject(inout self, r: Box2d, v: Vector2d) -> Float64:
        self.calls += 1
        return r.squaredExteriorDistance(v)

    def minimumOnObjectVolume(inout self, v: Vector2d, r: Box2d) -> Float64:
        self.calls += 1
        return r.squaredExteriorDistance(v)

    def minimumOnObjectObject(inout self, v1: Vector2d, v2: Vector2d) -> Float64:
        self.calls += 1
        return (v1 - v2).squaredNorm()

# KdBVH tree (simplified stub)
struct KdBVH(ScalarType: type, Dim: Int, ObjectType: type):
    var objects: List[ObjectType]

    def __init__(inout self, begin: List[ObjectType], end: List[ObjectType]):
        # In a real implementation, build the tree; here just store all objects
        self.objects = List[ObjectType]()
        for i in range(len(begin)):
            self.objects.append(begin[i])

    def __init__(inout self, objects: List[ObjectType]):
        self.objects = objects

# BVMinimize function (simplified stub)
def BVMinimize(
    redTree: KdBVH[Float64, 2, Vector2d],
    blueTree: KdBVH[Float64, 2, Vector2d],
    inout minimizer: PointPointMinimizer
) -> Float64:
    # Brute-force fallback for simplicity
    var minDistSq = Float64.MAX
    for i in range(len(redTree.objects)):
        for j in range(len(blueTree.objects)):
            minDistSq = min(minDistSq, minimizer.minimumOnObjectObject(redTree.objects[i], blueTree.objects[j]))
    return minDistSq

def main():
    type StdVectorOfVector2d = List[Vector2d]
    var redPoints = StdVectorOfVector2d()
    var bluePoints = StdVectorOfVector2d()
    for i in range(100):  # initialize random set of red points and blue points
        redPoints.append(Vector2d.Random())
        bluePoints.append(Vector2d.Random())

    var minimizer = PointPointMinimizer()
    var minDistSq = Float64.MAX
    for i in range(len(redPoints)):
        for j in range(len(bluePoints)):
            minDistSq = min(minDistSq, minimizer.minimumOnObjectObject(redPoints[i], bluePoints[j]))
    print("Brute force distance = ", sqrt(minDistSq), ", calls = ", minimizer.calls)

    minimizer.calls = 0
    var redTree = KdBVH[Float64, 2, Vector2d](redPoints)
    var blueTree = KdBVH[Float64, 2, Vector2d](bluePoints)  # construct the trees
    minDistSq = BVMinimize(redTree, blueTree, minimizer)  # actual BVH minimization call
    print("BVH distance         = ", sqrt(minDistSq), ", calls = ", minimizer.calls)