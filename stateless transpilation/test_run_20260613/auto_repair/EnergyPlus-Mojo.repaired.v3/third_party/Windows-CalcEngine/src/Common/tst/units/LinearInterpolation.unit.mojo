from memory import memory
from testing import Test
from WCECommon import FenestrationCommon

class LinearInterpolationTest(Test):
    def SetUp(self):

def Test1():
    print("Begin Test: Simple linear intepolation.")
    let x1 = 1.0
    let x2 = 2.0
    let y1 = 10.0
    let y2 = 20.0
    let x = 1.5
    let correctY = 15.0
    let evaluatedY = FenestrationCommon.linearInterpolation(x1, x2, y1, y2, x)
    assert abs(correctY - evaluatedY) < 1e-6