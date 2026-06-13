from gtest import *
from ObjexxFCL.Array1S import *
from ObjexxFCL.Array1D import *
from ObjexxFCL.ArrayS.functions import *
from ObjexxFCL.unit import *

def test_Array1STest_FunctionAbs() raises:
    var A = Array1D_int( [-1, -2, -3] )
    var a = Array1S_int( A( {1,3} ) )
    var E = Array1D_int( [1, 2, 3] )
    EXPECT_TRUE( eq( E, abs( a ) ) )

def test_Array1STest_FunctionNegation() raises:
    var A = Array1D_bool( [True, False, True] )
    var a = Array1S_bool( A( {1,3} ) )
    var E = Array1D_bool( [False, True, False] )
    EXPECT_TRUE( eq( E, !a ) )