from math import abs


# EXTERNAL DEPS (to wire in glue):
# - DeflectionData.getWNData() from WCETarcog.hpp - returns a table of (x,y) points
# - Table.columnInterpolation(tbl, value) from WCETarcog.hpp - performs column interpolation
# - Each result item has x() and y() accessors that return objects with a .value() method


trait ValueProvider:
    fn value(self) -> Float64:
        ...


trait XYItem:
    fn x(self) -> ValueProvider:
        ...

    fn y(self) -> ValueProvider:
        ...


struct DeflectionData:
    @staticmethod
    fn getWNData() -> List[List[XYItem]]:
        ...


struct Table:
    @staticmethod
    fn columnInterpolation(tbl: List[List[XYItem]], value: Float64) -> List[XYItem]:
        ...


fn assert_eq(actual: Int, expected: Int) raises:
    if actual != expected:
        raise Error("Expected " + String(expected) + " but got " + String(actual))


fn assert_near(actual: Float64, expected: Float64, tolerance: Float64) raises:
    if abs(actual - expected) > tolerance:
        raise Error(
            "Expected " + String(expected) + " but got " + String(actual) +
            " (tolerance: " + String(tolerance) + ")"
        )


@always_inline
fn _get_correct_x() -> InlineArray[Float64, 6]:
    var result = InlineArray[Float64, 6](fill=0.0)
    result[0] = -5.0
    result[1] = -2.6
    result[2] = -0.2
    result[3] = 2.2
    result[4] = 4.6
    result[5] = 7.0
    return result


@always_inline
fn _get_correct_y(test_id: Int) -> InlineArray[Float64, 6]:
    var result = InlineArray[Float64, 6](fill=0.0)
    if test_id == 0:
        result[0] = -4.25694
        result[1] = -1.85765
        result[2] = 0.47293
        result[3] = 2.08248
        result[4] = 3.14455
        result[5] = 4.69143
    elif test_id == 1:
        result[0] = -5.296
        result[1] = -2.8966
        result[2] = -0.5569
        result[3] = 1.067
        result[4] = 2.1892
        result[5] = 3.2125
    elif test_id == 2:
        result[0] = -4.1207
        result[1] = -1.7207
        result[2] = 0.6846
        result[3] = 3.1262
        result[4] = 4.7056
        result[5] = 6.23315
    return result


struct TestDeflectionDataInterpolation:
    fn set_up(inout self):
        pass

    fn test_InterpolationAtMidPoint(inout self) raises:
        let tbl = DeflectionData.getWNData()
        let interpolation_value: Float64 = 2.5
        let col = Table.columnInterpolation(tbl, interpolation_value)

        let correct_x = _get_correct_x()
        let correct_y = _get_correct_y(0)

        assert_eq(len(col), 6)
        for i in range(len(correct_y)):
            assert_near(col[i].x().value(), correct_x[i], 1e-5)
            assert_near(col[i].y().value(), correct_y[i], 1e-5)

    fn test_InterpolationAtStartPoint(inout self) raises:
        let tbl = DeflectionData.getWNData()
        let interpolation_value: Float64 = 1.0
        let col = Table.columnInterpolation(tbl, interpolation_value)

        let correct_x = _get_correct_x()
        let correct_y = _get_correct_y(1)

        assert_eq(len(col), 6)
        for i in range(len(correct_y)):
            assert_near(col[i].x().value(), correct_x[i], 1e-5)
            assert_near(col[i].y().value(), correct_y[i], 1e-5)

    fn test_InterpolationAtEndPoint(inout self) raises:
        let tbl = DeflectionData.getWNData()
        let interpolation_value: Float64 = 10.0
        let col = Table.columnInterpolation(tbl, interpolation_value)

        let correct_x = _get_correct_x()
        let correct_y = _get_correct_y(2)

        assert_eq(len(col), 6)
        for i in range(len(correct_y)):
            assert_near(col[i].x().value(), correct_x[i], 1e-5)
            assert_near(col[i].y().value(), correct_y[i], 1e-5)
