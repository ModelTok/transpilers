from memory import Pointer
from testing import Test
from WCECommon import Polynom

class TestCalcPolynom(Test):
    def SetUp(self):

def Test1():
    print("Begin Test: Calculate polynom test 1.")
    let input = Pointer[Float64](-6.75, 8.65, -0.75)
    var poly = Polynom(input)
    assert abs(-10.95 - poly.valueAt(12)) < 1e-6

def Test2():
    print("Begin Test: Calculate polynom test 2.")
    let input = Pointer[Float64](-6.75, 8.65, -0.75)
    var poly = Polynom(input)
    assert abs(1.15 - poly.valueAt(1)) < 1e-6

def Test3():
    print("Begin Test: Calculate polynom test 3.")
    let input = Pointer[Float64](
      -9.27348E-06, 2.288300764, 1.646894009, -15.39761441, 26.12276881, -19.1483186, 5.322076488)
    var poly = Polynom(input)
    assert abs(0.807353444 - poly.valueAt(0.7)) < 1e-6