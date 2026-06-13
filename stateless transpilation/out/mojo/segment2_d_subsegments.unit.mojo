# EXTERNAL DEPS (to wire in glue):
# from WCEViewer import CPoint2D, CViewSegment2D

import unittest
from typing import List, Optional

class TestSegment2DSubsegments(unittest.TestCase):
    def setUp(self):
        pass

    def test_segment2d_test1(self):
        import unittest
        from unittest.mock import patch

        with patch('WCEViewer.CPoint2D') as MockCPoint2D, \
             patch('WCEViewer.CViewSegment2D') as MockCViewSegment2D:
            aStartPoint = MockCPoint2D.return_value
            aEndPoint = MockCPoint2D.return_value
            aSegment = MockCViewSegment2D.return_value

            aStartPoint.x.return_value = 0
            aStartPoint.y.return_value = 0
            aEndPoint.x.return_value = 10
            aEndPoint.y.return_value = 10

            aSubSegments = aSegment.subSegments.return_value
            aSubSegments.__iter__.return_value = [
                MockCViewSegment2D.return_value,
                MockCViewSegment2D.return_value,
                MockCViewSegment2D.return_value,
                MockCViewSegment2D.return_value
            ]

            correctStartX = [0, 2.5, 5, 7.5]
            correctEndX = [2.5, 5, 7.5, 10]

            correctStartY = [0, 2.5, 5, 7.5]
            correctEndY = [2.5, 5, 7.5, 10]

            for i, aSubSegment in enumerate(aSubSegments):
                xStart = aSubSegment.startPoint.return_value.x.return_value
                xEnd = aSubSegment.endPoint.return_value.x.return_value
                yStart = aSubSegment.startPoint.return_value.y.return_value
                yEnd = aSubSegment.endPoint.return_value.y.return_value

                self.assertAlmostEqual(correctStartX[i], xStart, places=6)
                self.assertAlmostEqual(correctEndX[i], xEnd, places=6)
                self.assertAlmostEqual(correctStartY[i], yStart, places=6)
                self.assertAlmostEqual(correctEndY[i], yEnd, places=6)

if __name__ == '__main__':
    unittest.main()
