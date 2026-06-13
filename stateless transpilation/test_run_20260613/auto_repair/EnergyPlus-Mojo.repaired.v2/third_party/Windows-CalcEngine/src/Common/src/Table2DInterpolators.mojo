from builtin import Optional, List, Float64, None, Bool, Int, UInt
from Table2D import Table2D

# Helper: lower_bound (binary search) for sorted list, returns index of first element >= value
def lower_bound(arr: List[Float64], value: Float64) -> UInt:
    var lo: UInt = 0
    var hi: UInt = arr.size
    while lo < hi:
        var mid: UInt = lo + (hi - lo) // 2
        if arr[mid] < value:
            lo = mid + 1
        else:
            hi = mid
    return lo

struct point:
    var x: Optional[Float64]
    var y: Optional[Float64]

    def __init__(inout self, x: Optional[Float64] = None, y: Optional[Float64] = None):
        self.x = x
        self.y = y

    def __eq__(self, other: point) -> Bool:
        var x_has_value: Bool = (self.x is not None) == (other.x is not None)
        var y_has_value: Bool = (self.y is not None) == (other.y is not None)
        var result: Bool = x_has_value and y_has_value
        if x_has_value:
            # Unwrap both
            if self.x is not None and other.x is not None:
                var sv = self.x as Float64
                var ov = other.x as Float64
                result = result and sv == ov
        if y_has_value:
            if self.y is not None and other.y is not None:
                var sv = self.y as Float64
                var ov = other.y as Float64
                result = result and sv == ov
        return result

    def __ne__(self, other: point) -> Bool:
        return not (self == other)

    def has_value(self) -> Bool:
        return self.x is not None and self.y is not None

def linearInterpolation(
    x1: Optional[Float64],
    x2: Optional[Float64],
    y1: Optional[Float64],
    y2: Optional[Float64],
    x: Float64
) -> Optional[Float64]:
    if x1 is not None and x2 is not None and y1 is not None and y2 is not None:
        var x1v = x1 as Float64
        var x2v = x2 as Float64
        var y1v = y1 as Float64
        var y2v = y2 as Float64
        if x1v != x2v:
            return y1v + (y2v - y1v) / (x2v - x1v) * (x - x1v)
        else:
            return y1v
    else:
        return None

def columnInterpolation(
    table: Table2D[Optional[Float64]],
    value: Float64
) -> List[point]:
    var x: List[Float64] = table.x_values()
    var lowerIt_index: UInt = lower_bound(x, value)
    var upperIndex: Int = lowerIt_index  # as Int for subtraction
    # Note: lower_bound returns UInt, we need to handle zero case
    var lowIndex: Int = 0 if upperIndex == 0 else upperIndex - 1
    var lowerV: List[Optional[Float64]] = table.column(lowIndex)
    var upperV: List[Optional[Float64]] = table.column(upperIndex)
    var y: List[Float64] = table.y_values()
    var result: List[point] = List[point]()
    for i in range(y.size):
        var i_u: UInt = i
        var val: Optional[Float64] = linearInterpolation(
            x[lowIndex], x[upperIndex], lowerV[i_u], upperV[i_u], value)
        result.append(point(y[i_u], val))
    return result

def tableColumnInterpolation(
    table: List[point],
    value: Float64,
    extrapolate: Extrapolate = Extrapolate.No
) -> Optional[Float64]:
    var result: Optional[Float64] = None
    var p1: point = point()
    var p2: point = point()
    var ptFound: Bool = False
    for pt in table:
        if pt.x is not None:
            var xv = pt.x as Float64
            if xv > value:
                ptFound = True
        if not ptFound:
            p1 = pt
        else:
            p2 = pt
            break
    if p1.has_value() and p2.has_value() and p1 != p2:
        result = linearInterpolation(p1.x, p2.x, p1.y, p2.y, value)
    if result is None and extrapolate == Extrapolate.Yes:
        var firstValue: point = point()
        var foundFirst: Bool = False
        for a in table:
            if a.y is not None:
                firstValue = a
                foundFirst = True
                break
        var lastValue: point = point()
        var foundLast: Bool = False
        for i in range(table.size - 1, -1, -1):
            var a = table[i]
            if a.y is not None:
                lastValue = a
                foundLast = True
                break
        if table[0].x is not None:
            var x0 = table[0].x as Float64
            if x0 > value and foundFirst:
                result = firstValue.y
            else:
                if foundLast:
                    result = lastValue.y
        else:
            if foundLast:
                result = lastValue.y
    return result

enum Extrapolate:
    No = 0
    Yes = 1