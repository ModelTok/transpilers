from testing import *
from ObjexxFCL import *
from ObjexxFCL.ArrayS.all import *
from ObjexxFCL.Array1A import Array1A_int, Array2A_int
from ObjexxFCL.Array.functions import *
from ObjexxFCL.unit import *
from io import StringWriter, StringReader

@test
def ArraySTest_Array1SBasic():
    a = Array1D_int(5, (1, 2, 3, 4, 5))
    s = Array1S_int(a[1:3])  # {2,3} -> 0-based [1:3]
    expect_eq(s.size(), 2)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 2)
    expect_eq(s(1), 2)
    expect_eq(s(2), 3)

@test
def ArraySTest_Array1SSingleIndexSlice():
    a = Array1D_int(5, (1, 2, 3, 4, 5))
    # VC++ workaround: use {2,_} or {2} equivalent
    s = Array1S_int(a[1:])  # {2,_} or {2} -> from index 2 to end
    expect_eq(s.size(), 4)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 4)
    expect_eq(s(1), 2)
    expect_eq(s(2), 3)
    expect_eq(s(3), 4)
    expect_eq(s(4), 5)

@test
def ArraySTest_Array1SEmptySlice():
    a = Array1D_int(5, (1, 2, 3, 4, 5))
    s = Array1S_int(a[1:0])  # {2,-2} -> empty slice (start>end)
    expect_eq(s.size(), 0)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 0)
    expect_eq(s.size(), 0)

@test
def ArraySTest_Array1SEmptySliceOfEmptyArray():
    a = Array1D_int((5, -5))  # Empty array
    s = Array1S_int(a[4:0])  # {5,-5} -> empty slice
    expect_eq(s.size(), 0)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 0)
    expect_eq(s.size(), 0)

@test
def ArraySTest_Array1SSliceOfUnboundedArray():
    a = Array1D_int(5, (1, 2, 3, 4, 5))
    u = Array1A_int(a(2))  # 1-based index 2 -> a[1]
    s = Array1S_int(u[1:4])  # {2,4} -> 0-based [1:4]
    expect_eq(s.size(), 3)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 3)
    expect_eq(s(1), 3)
    expect_eq(s(2), 4)
    expect_eq(s(3), 5)

@test
def ArraySTest_Array2SSingleIndexSlice():
    A = Array2D_int(2, 2, (11, 12, 21, 22))
    S = Array2S_int(A[1:, 0:])  # {2,_} -> rows from 2, {1,_} -> cols from 1? Actually {2,_} first dim, {1,_} second dim -> rows 1: end, cols 0: end? In 1-based: rows 2 to end, cols 1 to end. In 0-based: rows[1:], cols[0:]. That gives one row (index 1), two cols -> correct.
    expect_eq(S.size(), 2)
    expect_eq(S.l1(), 1)
    expect_eq(S.u1(), 1)
    expect_eq(S.l2(), 1)
    expect_eq(S.u2(), 2)
    expect_eq(S(1, 1), 21)
    expect_eq(S(1, 2), 22)

@test
def ArraySTest_Array2D1SSlice():
    A = Array2D_int(2, 2, (11, 12, 21, 22))
    S = Array1S_int(A[:, 1])  # ( _, 2 ) -> all rows, column 2 (1-based) -> col index 1 (0-based)
    expect_eq(S.size(), 2)
    expect_eq(S.l(), 1)
    expect_eq(S.u(), 2)
    expect_eq(S.l1(), 1)
    expect_eq(S.u1(), 2)
    expect_eq(S(1), 12)
    expect_eq(S(2), 22)

@test
def ArraySTest_Array2D1SSlice65():
    A = Array2D_int(6, 5, 999)
    S = Array1S_int(A[:, 1])  # ( _, 2 )
    expect_eq(S.size(), 6)
    expect_eq(S.l(), 1)
    expect_eq(S.u(), 6)
    expect_eq(S.l1(), 1)
    expect_eq(S.u1(), 6)

@test
def ArraySTest_Array2D2SSlice():
    A = Array2D_int(3, 3, (11, 12, 13, 21, 22, 23, 31, 32, 33))
    S = Array2S_int(A[0:2, :])  # {1,2} -> rows 0 and 1 (0-based), all cols
    expect_eq(S.size(), 6)
    expect_eq(S.l1(), 1)
    expect_eq(S.u1(), 2)
    expect_eq(S.l2(), 1)
    expect_eq(S.u2(), 3)
    expect_eq(S(1, 1), 11)
    expect_eq(S(1, 2), 12)
    expect_eq(S(1, 3), 13)
    expect_eq(S(2, 1), 21)
    expect_eq(S(2, 2), 22)
    expect_eq(S(2, 3), 23)

    P = Array2A_int(S)  # OK because slice is contiguous
    expect_eq(P.l1(), 1)
    expect_eq(P.u1(), 2)
    expect_eq(P.l2(), 1)
    expect_eq(P.u2(), 3)
    expect_eq(P(1, 1), 11)
    expect_eq(P(1, 2), 12)
    expect_eq(P(1, 3), 13)
    expect_eq(P(2, 1), 21)
    expect_eq(P(2, 2), 22)
    expect_eq(P(2, 3), 23)

    # Can't make arg array from non-contiguous slice
    try:
        _ = Array2A_int(A[0:3:2, :])  # {1,3,2} -> stride 2, non-contiguous
        fail("Expected assertion")
    except:

    S2 = Array2S_int(A[1:3, :])  # {2,3} -> rows 1 and 2 (0-based)
    P2 = Array2A_int(S2)  # OK because slice is contiguous
    expect_eq(P2.l1(), 1)
    expect_eq(P2.u1(), 2)
    expect_eq(P2.l2(), 1)
    expect_eq(P2.u2(), 3)
    expect_eq(P2(1, 1), 21)
    expect_eq(P2(1, 2), 22)
    expect_eq(P2(1, 3), 23)
    expect_eq(P2(2, 1), 31)
    expect_eq(P2(2, 2), 32)
    expect_eq(P2(2, 3), 33)

@test
def ArraySTest_Array2D1DOTFSlice():
    A = Array2D_int(2, 2, (11, 12, 21, 22))
    B = Array1D_int(A[0:2, 1])  # {1,2}, 2 -> rows 0,1 and column 1 (0-based)
    expect_eq(B.l(), 1)
    expect_eq(B.u(), 2)
    expect_eq(B(1), 12)
    expect_eq(B(2), 22)

@test
def ArraySTest_Array1SWholeArraySlice():
    a = Array1D_int((-2, 2), (1, 2, 3, 4, 5))
    s = Array1S_int(a)  # whole array slice
    expect_eq(s.size(), 5)
    expect_eq(s.l(), 1)
    expect_eq(s.u(), 5)
    expect_eq(s(1), 1)
    expect_eq(s(2), 2)
    expect_eq(s(3), 3)
    expect_eq(s(4), 4)
    expect_eq(s(5), 5)

@test
def ArraySTest_Array2SWholeArraySlice():
    a = Array2D_int((-1, 1), (-1, 1), (1, 2, 3, 4, 5, 6, 7, 8, 9))
    s = Array2S_int(a)  # whole array slice
    expect_eq(s.size(), 9)
    expect_eq(s.l1(), 1)
    expect_eq(s.l2(), 1)
    expect_eq(s.u1(), 3)
    expect_eq(s.u2(), 3)
    expect_eq(s(1, 1), 1)
    expect_eq(s(1, 2), 2)
    expect_eq(s(1, 3), 3)
    expect_eq(s(2, 1), 4)
    expect_eq(s(2, 2), 5)
    expect_eq(s(2, 3), 6)
    expect_eq(s(3, 1), 7)
    expect_eq(s(3, 2), 8)
    expect_eq(s(3, 3), 9)

@test
def ArraySTest_Array3SWholeArraySlice():
    a = Array3D_int((-1, 0), (1, 2), (0, 1), (1, 2, 3, 4, 5, 6, 7, 8))
    s = Array3S[int](a)  # whole array slice
    expect_eq(s.size(), 8)
    expect_eq(s.l1(), 1)
    expect_eq(s.l2(), 1)
    expect_eq(s.l3(), 1)
    expect_eq(s.u1(), 2)
    expect_eq(s.u2(), 2)
    expect_eq(s.u3(), 2)
    expect_eq(s(1, 1, 1), 1)
    expect_eq(s(1, 1, 2), 2)
    expect_eq(s(1, 2, 1), 3)
    expect_eq(s(1, 2, 2), 4)
    expect_eq(s(2, 1, 1), 5)
    expect_eq(s(2, 1, 2), 6)
    expect_eq(s(2, 2, 1), 7)
    expect_eq(s(2, 2, 2), 8)

@test
def ArraySTest_Array2SSlice3D():
    M = Array3D_int(9, 9, 9)
    for i in range(9*9*9):
        M[i] = i  # Memory offset values
    S = Array2S_int(M(6, (7, 1, -2), (7, 1, -2)))  # 7, {8,2,-2}, {8,2,-2}? Actually 7 is first index, then slices. 1-based: first dim index 7 -> 0-based 6. Second dim slice {8,2,-2} -> start 8, end 2, step -2 -> reversed? Actually step -2 means backwards. In C++, {8,2,-2} means from 8 down to 2 step -2. In 0-based, that is from index 7 down to 1 step -2. So we need to express as slice. Hard to express in Python slicing because step negative requires start>end. We'll use a slice in Mojo: M[6, 7:1:-2, 7:1:-2] but careful: in C++, {8,2,-2} includes indices 8,6,4,2 (4 elements). In 0-based, that is 7,5,3,1. So M[6, 7:1:-2, 7:1:-2] gives that. Let's verify: Python slice [7:1:-2] gives indices 7,5,3,1 (4 elements). Good.
    S = Array2S_int(M[6, 7:1:-2, 7:1:-2])
    expect_eq(S.l1(), 1)
    expect_eq(S.u1(), 4)
    expect_eq(S.size1(), 4)
    expect_eq(S.l2(), 1)
    expect_eq(S.u2(), 4)
    expect_eq(S.size2(), 4)
    expect_eq(S.size(), 16)

    SF = Array2D_int(4, 4, (
        556, 554, 552, 550,
        538, 536, 534, 532,
        520, 518, 516, 514,
        502, 500, 498, 496
    ))
    expect_true(eq(S, SF))

    r = Array1S_int(S(2, :))  # 3rd row? Actually S(3, _) in C++ is row index 3 (1-based) -> 2 (0-based). So S[2, :] gives row 2 (0-based) -> third row.
    expect_eq(r.l(), 1)
    expect_eq(r.u(), 4)
    expect_eq(r.size(), 4)
    expect_true(eq(r, Array1D_int(4, (520, 518, 516, 514))))

@test
def ArraySTest_AnyOp2D():
    A = Array2D_int(3, 3, (1, 2, 3, 4, 5, 6, 7, 8, 9))
    S = Array2S_int(A)
    expect_true(any_eq(S, 6))
    expect_false(any_eq(S, 22))
    expect_true(any_ne(S, 6))
    expect_true(any_lt(S, 2))
    expect_true(any_ge(S, 9))
    expect_false(any_lt(S, 1))
    expect_false(any_gt(S, 9))

@test
def ArraySTest_AllOp2D():
    A = Array2D_int(3, 3, (1, 2, 3, 4, 5, 6, 7, 8, 9))
    S = Array2S_int(A)
    expect_true(all_ne(S, 22))
    expect_false(all_ne(S, 2))
    expect_false(all_lt(S, 2))
    expect_false(all_ge(S, 9))
    expect_true(all_lt(S, 11))
    expect_true(all_gt(S, 0))

@test
def ArraySTest_CountOp2D():
    A = Array2D_int(3, 3, (1, 2, 2, 3, 3, 3, 7, 8, 9))
    S = Array2S_int(A)
    expect_eq(count_eq(S, 0), 0)
    expect_eq(count_eq(S, 1), 1)
    expect_eq(count_eq(S, 2), 2)
    expect_eq(count_eq(S, 3), 3)
    expect_eq(count_lt(S, 7), 6)
    expect_eq(count_ge(S, 9), 1)
    expect_eq(count_lt(S, 11), 9)
    expect_eq(count_gt(S, 3), 3)

@test
def ArraySTest_Functions1D():
    U = Array1D_int((1, 2, 3))
    V = Array1D_int((2, 3, 4))
    u = Array1S_int(U)
    v = Array1S_int(V)
    expect_eq(magnitude_squared(u), 14)
    expect_eq(distance_squared(u, v), 3)
    expect_eq(dot(u, v), 20)

@test
def ArraySTest_StreamOut():
    A = Array1D_int(3, (1, 2, 3))
    S = Array1S_int(A)
    stream = StringWriter()
    stream.write(S.to_string())  # assuming to_string returns the formatted string
    expect_eq(stream.to_string(), "           1            2            3 ")

@test
def ArraySTest_StreamIn():
    A = Array1D_int(3, (1, 2, 3))
    S = Array1S_int(A)
    text = "1  2  3"
    stream = StringReader(text)
    stream.read(S)  # assuming read method populates S
    expect_true(eq(A, S))