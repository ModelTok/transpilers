from testing import assert_eq, assert_true
from ......ObjexxFCL.member.functions import sum, minval, maxval, sum_sub, sum_product_sub, array_sub, minloc, maxloc, eq
from ......ObjexxFCL.Array1D import Array1D, Array1S

struct S:
    var i: Int
    def __init__(self):
        self.i = 5
    def __init__(self, ii: Int):
        self.i = ii

def SumContainer():
    let a = Array1D[S](5, S(2))
    assert_eq(10, sum(a, fn(s: S) -> Int: return s.i))

def SumIterator():
    let a = Array1D[S](5, S(2))
    assert_eq(10, sum(a.begin(), a.end(), fn(s: S) -> Int: return s.i))
    assert_eq(10, sum(a.begin(), a.end(), fn(s: S) -> Int: return s.i))

def SumSlice():
    let a = Array1D[S](5, S(2))
    let s = a[1:4]
    assert_eq(6, sum(s, fn(s: S) -> Int: return s.i))

def SumSub():
    let a = Array1D[S]([S(1), S(2), S(3), S(4), S(5)])
    let sub = Array1D[Int]([2, 3, 4])
    assert_eq(9, sum_sub(a, fn(s: S) -> Int: return s.i, sub))

def SumProductSub1Array():
    let a = Array1D[S]([S(1), S(2), S(3), S(4), S(5)])
    let sub = Array1D[Int]([2, 3, 4])
    assert_eq(29, sum_product_sub(a, fn(s: S) -> Int: return s.i, fn(s: S) -> Int: return s.i, sub))

def SumProductSub2Array():
    let a = Array1D[Int]([1, 2, 1, 2, 1])
    let b = Array1D[S]([S(1), S(2), S(3), S(4), S(5)])
    let sub = Array1D[Int]([2, 3, 4])
    assert_eq(15, sum_product_sub(a, b, fn(s: S) -> Int: return s.i, sub))

def ArraySub():
    let a = Array1D[S]([S(1), S(2), S(3), S(4), S(5)])
    let sub = Array1D[Int]([2, 3, 4])
    let result = array_sub(a, fn(s: S) -> Int: return s.i, sub)
    let expected = Array1D[Int]([2, 3, 4])
    assert_true(eq(result, expected))

def MinvalContainer():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(2, minval(a, fn(s: S) -> Int: return s.i))

def MinvalIterator():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(2, minval(a.begin(), a.end(), fn(s: S) -> Int: return s.i))
    assert_eq(2, minval(a.begin(), a.end(), fn(s: S) -> Int: return s.i))

def MinvalSlice():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    let s = a[1:4]
    assert_eq(2, minval(s, fn(s: S) -> Int: return s.i))

def MaxvalContainer():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(6, maxval(a, fn(s: S) -> Int: return s.i))

def MaxvalIterator():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(6, maxval(a.begin(), a.end(), fn(s: S) -> Int: return s.i))
    assert_eq(6, maxval(a.begin(), a.end(), fn(s: S) -> Int: return s.i))

def MaxvalSlice():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    let s = a[1:4]
    assert_eq(5, maxval(s, fn(s: S) -> Int: return s.i))

def Minloc():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(4, minloc(a, fn(s: S) -> Int: return s.i))
    let s = a[1:4]
    assert_eq(3, minloc(s, fn(s: S) -> Int: return s.i))

def Maxloc():
    let a = Array1D[S]([S(3), S(5), S(3), S(2), S(6)])
    assert_eq(5, maxloc(a, fn(s: S) -> Int: return s.i))
    let s = a[1:4]
    assert_eq(1, maxloc(s, fn(s: S) -> Int: return s.i))

def main():
    SumContainer()
    SumIterator()
    SumSlice()
    SumSub()
    SumProductSub1Array()
    SumProductSub2Array()
    ArraySub()
    MinvalContainer()
    MinvalIterator()
    MinvalSlice()
    MaxvalContainer()
    MaxvalIterator()
    MaxvalSlice()
    Minloc()
    Maxloc()