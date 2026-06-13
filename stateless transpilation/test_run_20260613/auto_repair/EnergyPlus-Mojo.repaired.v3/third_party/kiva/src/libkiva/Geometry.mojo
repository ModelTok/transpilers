/* Copyright (c) 2012-2022 Big Ladder Software LLC. All rights reserved.
 * See the LICENSE file for additional terms and conditions. */

from Geometry import Point, Polygon, Ring, MultiPolygon, MultiPoint, Line, Box, Point3, Polygon3, geom, Direction, Turn, isRectilinear, offset, getDirectionIn, getDirectionOut, getTurn, mirrorX, mirrorY, symmetricUnit, isXSymmetric, isYSymmetric, isCounterClockWise, getXmin, getYmin, getXmax, getYmax, comparePointsX, comparePointsY, pointOnPoly, isConvex, getDistance, getAngle
from Errors import showMessage, MSG_ERR
from Functions import isEqual, isLessThan, isGreaterThan

from memory.unsafe import Pointer
from math import sqrt, acos, atan, max, min

static const PI: Float64 = 4.0 * atan(1.0)

def isCounterClockWise(poly: Polygon) -> Bool:
    var area = boost.geometry.area(poly)
    if area < 0:
        return False
    return True

def isRectilinear(poly: Polygon) -> Bool:
    for v in range(poly.outer().size()):
        var x = poly.outer()[v].get<0>()
        var y = poly.outer()[v].get<1>()
        var xNext: Float64
        var yNext: Float64
        if v == poly.outer().size() - 1:
            xNext = poly.outer()[0].get<0>()
            yNext = poly.outer()[0].get<1>()
        else:
            xNext = poly.outer()[v + 1].get<0>()
            yNext = poly.outer()[v + 1].get<1>()
        if isEqual(x, xNext) or isEqual(y, yNext):

        else:
            return False
    return True

def offset(poly: Polygon, dist: Float64) -> Polygon:
    static const join_strategy = boost.geometry.strategy.buffer.join_miter()
    var distance_strategy = boost.geometry.strategy.buffer.distance_symmetric[Float64](dist)
    static const end_strategy = boost.geometry.strategy.buffer.end_flat()
    static const side_strategy = boost.geometry.strategy.buffer.side_straight()
    static const point_strategy = boost.geometry.strategy.buffer.point_square()
    var offset = MultiPolygon()
    boost.geometry.buffer(poly, offset, distance_strategy, side_strategy, join_strategy, end_strategy, point_strategy)
    return offset[0]

def getDirectionIn(poly: Polygon, vertex: Int) -> geom.Direction:
    if not isRectilinear(poly):
        showMessage(MSG_ERR, "Cannot get direction of vertex for non-rectilinear polygon.")
    var xPrev: Float64
    var yPrev: Float64
    var x: Float64
    var y: Float64
    var nV = poly.outer().size()
    if vertex == 0:
        xPrev = poly.outer()[nV - 1].get<0>()
        yPrev = poly.outer()[nV - 1].get<1>()
    else:
        xPrev = poly.outer()[vertex - 1].get<0>()
        yPrev = poly.outer()[vertex - 1].get<1>()
    x = poly.outer()[vertex].get<0>()
    y = poly.outer()[vertex].get<1>()
    if isLessThan(x, xPrev):
        return geom.X_NEG
    elif isGreaterThan(x, xPrev):
        return geom.X_POS
    elif isLessThan(y, yPrev):
        return geom.Y_NEG
    else:
        return geom.Y_POS

def getDirectionOut(poly: Polygon, vertex: Int) -> geom.Direction:
    if not isRectilinear(poly):
        showMessage(MSG_ERR, "Cannot get direction of vertex for non-rectilinear polygon.")
    var xNext: Float64
    var yNext: Float64
    var x: Float64
    var y: Float64
    var nV = poly.outer().size()
    if vertex == nV - 1:
        xNext = poly.outer()[0].get<0>()
        yNext = poly.outer()[0].get<1>()
    else:
        xNext = poly.outer()[vertex + 1].get<0>()
        yNext = poly.outer()[vertex + 1].get<1>()
    x = poly.outer()[vertex].get<0>()
    y = poly.outer()[vertex].get<1>()
    if isLessThan(xNext, x):
        return geom.X_NEG
    elif isGreaterThan(xNext, x):
        return geom.X_POS
    elif isLessThan(yNext, y):
        return geom.Y_NEG
    else:
        return geom.Y_POS

def getTurn(poly: Polygon, vertex: Int) -> geom.Turn:
    var dirIn = getDirectionIn(poly, vertex)
    var dirOut = getDirectionOut(poly, vertex)
    if dirIn == geom.X_NEG:
        if dirOut == geom.Y_POS:
            return geom.RIGHT
        else:
            return geom.LEFT
    elif dirIn == geom.X_POS:
        if dirOut == geom.Y_POS:
            return geom.LEFT
        else:
            return geom.RIGHT
    elif dirIn == geom.Y_NEG:
        if dirOut == geom.X_POS:
            return geom.LEFT
        else:
            return geom.RIGHT
    else: # case geom.Y_POS
        if dirOut == geom.X_POS:
            return geom.RIGHT
        else:
            return geom.LEFT

def mirrorX(poly: MultiPolygon, x: Float64) -> MultiPolygon:
    var transform = boost.geometry.strategy.transform.matrix_transformer[Float64, 2, 2](-1, 0, 2 * x, 0, 1, 0, 0, 0, 1)
    var mirror = MultiPolygon()
    boost.geometry.transform(poly, mirror, transform)
    boost.geometry.reverse(mirror)
    return mirror

def mirrorY(poly: MultiPolygon, y: Float64) -> MultiPolygon:
    var transform = boost.geometry.strategy.transform.matrix_transformer[Float64, 2, 2](1, 0, 0, 0, -1, 2 * y, 0, 0, 1)
    var mirror = MultiPolygon()
    boost.geometry.transform(poly, mirror, transform)
    boost.geometry.reverse(mirror)
    return mirror

def isXSymmetric(poly: Polygon) -> Bool:
    var centroid = Point()
    boost.geometry.centroid(poly, centroid)
    var centroidX = centroid.get<0>()
    var bb = Box()
    boost.geometry.envelope(poly, bb)
    var bbLeft = Box(bb.min_corner(), Point(centroidX, bb.max_corner().get<1>()))
    var bbRight = Box(Point(centroidX, bb.min_corner().get<1>()), bb.max_corner())
    var left = MultiPolygon()
    var right = MultiPolygon()
    boost.geometry.intersection(poly, bbLeft, left)
    boost.geometry.intersection(poly, bbRight, right)
    right = mirrorX(right, centroidX)
    var intersection = MultiPolygon()
    boost.geometry.intersection(left, right, intersection)
    return isEqual(boost.geometry.area(left), boost.geometry.area(intersection), 1e-4)

def isYSymmetric(poly: Polygon) -> Bool:
    var centroid = Point()
    boost.geometry.centroid(poly, centroid)
    var centroidY = centroid.get<1>()
    var bb = Box()
    boost.geometry.envelope(poly, bb)
    var bbBottom = Box(bb.min_corner(), Point(bb.max_corner().get<0>(), centroidY))
    var bbTop = Box(Point(bb.min_corner().get<0>(), centroidY), bb.max_corner())
    var bottom = MultiPolygon()
    var top = MultiPolygon()
    boost.geometry.intersection(poly, bbTop, top)
    boost.geometry.intersection(poly, bbBottom, bottom)
    top = mirrorY(top, centroidY)
    var intersection = MultiPolygon()
    boost.geometry.intersection(bottom, top, intersection)
    return isEqual(boost.geometry.area(bottom), boost.geometry.area(intersection), 1e-4)

def symmetricUnit(poly: Polygon) -> Polygon:
    var symPolys = MultiPolygon()
    symPolys.push_back(poly)
    var bb = Box()
    boost.geometry.envelope(poly, bb)
    var isXsymm = isXSymmetric(poly)
    var isYsymm = isYSymmetric(poly)
    if isXsymm:
        var centroid = Point()
        boost.geometry.centroid(poly, centroid)
        var centroidX = centroid.get<0>()
        var bbRight = Box(Point(centroidX, bb.min_corner().get<1>()), bb.max_corner())
        var xSymPolys = MultiPolygon()
        var right = Polygon()
        boost.geometry.convert(bbRight, right)
        boost.geometry.intersection(symPolys[0], right, xSymPolys)
        symPolys = xSymPolys
    if isYsymm:
        var centroid = Point()
        boost.geometry.centroid(poly, centroid)
        var centroidY = centroid.get<1>()
        var bbTop = Box(Point(bb.min_corner().get<0>(), centroidY), bb.max_corner())
        var ySymPolys = MultiPolygon()
        var top = Polygon()
        boost.geometry.convert(bbTop, top)
        boost.geometry.intersection(symPolys[0], top, ySymPolys)
        symPolys = ySymPolys
    return symPolys[0]

def getXmax(poly: Polygon, vertex: Int) -> Float64:
    var x = poly.outer()[vertex].get<0>()
    var xNext: Float64
    var nV = poly.outer().size()
    if vertex == nV - 1:
        xNext = poly.outer()[0].get<0>()
    else:
        xNext = poly.outer()[vertex + 1].get<0>()
    return max(x, xNext)

def getYmax(poly: Polygon, vertex: Int) -> Float64:
    var y = poly.outer()[vertex].get<1>()
    var yNext: Float64
    var nV = poly.outer().size()
    if vertex == nV - 1:
        yNext = poly.outer()[0].get<1>()
    else:
        yNext = poly.outer()[vertex + 1].get<1>()
    return max(y, yNext)

def getXmin(poly: Polygon, vertex: Int) -> Float64:
    var x = poly.outer()[vertex].get<0>()
    var xNext: Float64
    var nV = poly.outer().size()
    if vertex == nV - 1:
        xNext = poly.outer()[0].get<0>()
    else:
        xNext = poly.outer()[vertex + 1].get<0>()
    return min(x, xNext)

def getYmin(poly: Polygon, vertex: Int) -> Float64:
    var y = poly.outer()[vertex].get<1>()
    var yNext: Float64
    var nV = poly.outer().size()
    if vertex == nV - 1:
        yNext = poly.outer()[0].get<1>()
    else:
        yNext = poly.outer()[vertex + 1].get<1>()
    return min(y, yNext)

def comparePointsX(first: Point, second: Point) -> Bool:
    return first.get<0>() < second.get<0>()

def comparePointsY(first: Point, second: Point) -> Bool:
    return first.get<1>() < second.get<1>()

def pointOnPoly(point: Point, poly: Polygon) -> Bool:
    return boost.geometry.intersects(point, poly)

def isConvex(poly: Polygon) -> Bool:
    var hull = Polygon()
    boost.geometry.convex_hull(poly, hull)
    return boost.geometry.equals(poly, hull)

def getDistance(a: Point, b: Point) -> Float64:
    var ax = a.get<0>()
    var ay = a.get<1>()
    var bx = b.get<0>()
    var by = b.get<1>()
    var x = bx - ax
    var y = by - ay
    return sqrt(x * x + y * y)

def getAngle(a: Point, b: Point, c: Point) -> Float64:
    var angle: Float64
    var A = getDistance(a, b)
    var B = getDistance(b, c)
    var C = getDistance(c, a)
    var ax = a.get<0>()
    var ay = a.get<1>()
    var bx = b.get<0>()
    var by = b.get<1>()
    var cx = c.get<0>()
    var cy = c.get<1>()
    var sign = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay)
    angle = acos((A * A + B * B - C * C) / (2 * A * B))
    if sign < 0:
        angle += PI
    return angle