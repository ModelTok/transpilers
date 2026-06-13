import unittest


# EXTERNAL DEPS (to wire in glue):
# - DeflectionData.getWNData() from WCETarcog.hpp - returns a table of (x,y) points
# - Table.columnInterpolation(tbl, value) from WCETarcog.hpp - performs column interpolation
# - Each result item has .x.value() and .y.value() methods returning float values


class DeflectionData:
    @staticmethod
    def getWNData():
        raise NotImplementedError(
            "DeflectionData.getWNData() must be provided by glue code"
        )


class Table:
    @staticmethod
    def columnInterpolation(tbl, value):
        raise NotImplementedError(
            "Table.columnInterpolation() must be provided by glue code"
        )


class TestDeflectionDataInterpolation(unittest.TestCase):
    def setUp(self):
        pass

    def test_InterpolationAtMidPoint(self):
        tbl = DeflectionData.getWNData()
        interpolation_value = 2.5
        col = Table.columnInterpolation(tbl, interpolation_value)

        correct_x = [-5, -2.6, -0.2, 2.2, 4.6, 7]
        correct_y = [-4.25694, -1.85765, 0.47293, 2.08248, 3.14455, 4.69143]

        self.assertEqual(len(col), 6)
        for i in range(len(correct_y)):
            self.assertAlmostEqual(col[i].x.value(), correct_x[i], places=5)
            self.assertAlmostEqual(col[i].y.value(), correct_y[i], places=5)

    def test_InterpolationAtStartPoint(self):
        tbl = DeflectionData.getWNData()
        interpolation_value = 1.0
        col = Table.columnInterpolation(tbl, interpolation_value)

        correct_x = [-5, -2.6, -0.2, 2.2, 4.6, 7]
        correct_y = [-5.296, -2.8966, -0.5569, 1.067, 2.1892, 3.2125]

        self.assertEqual(len(col), 6)
        for i in range(len(correct_y)):
            self.assertAlmostEqual(col[i].x.value(), correct_x[i], places=5)
            self.assertAlmostEqual(col[i].y.value(), correct_y[i], places=5)

    def test_InterpolationAtEndPoint(self):
        tbl = DeflectionData.getWNData()
        interpolation_value = 10.0
        col = Table.columnInterpolation(tbl, interpolation_value)

        correct_x = [-5, -2.6, -0.2, 2.2, 4.6, 7]
        correct_y = [-4.1207, -1.7207, 0.6846, 3.1262, 4.7056, 6.23315]

        self.assertEqual(len(col), 6)
        for i in range(len(correct_y)):
            self.assertAlmostEqual(col[i].x.value(), correct_x[i], places=5)
            self.assertAlmostEqual(col[i].y.value(), correct_y[i], places=5)
