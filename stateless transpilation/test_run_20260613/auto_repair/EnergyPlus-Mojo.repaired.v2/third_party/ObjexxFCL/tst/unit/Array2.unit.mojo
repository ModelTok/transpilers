from testing import *
from math import *
import sys

# Minimal Array2D implementation to support the tests (1‑based indexing via internal offsets)
struct IR:
    var l: Int
    var u: Int
    def __init__(inout self, l: Int, u: Int):
        self.l = l
        self.u = u
    def __init__(inout self):
        self.l = 1
        self.u = 0
    def __eq__(self, other: IR) -> Bool:
        return self.l == other.l and self.u == other.u
    def __ne__(self, other: IR) -> Bool:
        return not self.__eq__(other)
    def __init__(inout self, *args: Int):
        if len(args) == 2:
            self.l = args[0]
            self.u = args[1]
        else:
            self.l = 1; self.u = 0

alias Array2D_int = Array2D[Int]
alias Array2D_double = Array2D[Float64]
alias Array2D_string = Array2D[String]
alias Array2D_bool = Array2D[Bool]
alias Array2A_int = Array2A[Int]
alias Array2A_double = Array2A[Float64]
alias Array1D_int = Array1D[Int]
alias Array1D_size = Array1D[Int]  # size_t in C++ -> Int in Mojo
alias Array1D_double = Array1D[Float64]

struct Array2D[T: AnyType]:
    var data_: DynamicVector[T]
    var l1_: Int
    var u1_: Int
    var l2_: Int
    var u2_: Int
    var own_: Bool
    alias npos: Int = -1

    def __init__(inout self):
        self.l1_ = 1; self.u1_ = 0
        self.l2_ = 1; self.u2_ = 0
        self.data_ = DynamicVector[T]()
        self.own_ = True

    def __init__(inout self, other: Self):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
        for i in range(len(other.data_)):
            self.data_[i] = other.data_[i]
        self.own_ = True

    def __init__(inout self, size1: Int, size2: Int):
        self.l1_ = 1; self.u1_ = size1
        self.l2_ = 1; self.u2_ = size2
        let n = size1 * size2
        self.data_ = DynamicVector[T](n)
        self.own_ = True

    def __init__(inout self, size1: Int, size2: Int, val: T):
        self.l1_ = 1; self.u1_ = size1
        self.l2_ = 1; self.u2_ = size2
        let n = size1 * size2
        self.data_ = DynamicVector[T](n, val)
        self.own_ = True

    def __init__(inout self, i1: IR, i2: IR):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
        let n = (self.u1_ - self.l1_ + 1) * (self.u2_ - self.l2_ + 1)
        self.data_ = DynamicVector[T](n)
        self.own_ = True

    def __init__(inout self, i1: IR, i2: IR, val: T):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
        let n = (self.u1_ - self.l1_ + 1) * (self.u2_ - self.l2_ + 1)
        self.data_ = DynamicVector[T](n, val)
        self.own_ = True

    def __init__(inout self, size1: Int, size2: Int, init_fn: def (inout Array2D[T]) -> None):
        self.__init__(size1, size2)
        init_fn(self)

    def __init__(inout self, i1: IR, i2: IR, init_fn: def (inout Array2D[T]) -> None):
        self.__init__(i1, i2)
        init_fn(self)

    def __init__(inout self, size1: Int, size2: Int, vals: StaticArray[T, ...]):  # approximate initializer_list
        self.__init__(size1, size2)
        for i in range(len(vals)):
            self.data_[i] = vals[i]

    def __init__(inout self, i1: IR, i2: IR, vals: StaticArray[T, ...]):
        self.__init__(i1, i2)
        for i in range(len(vals)):
            self.data_[i] = vals[i]

    def __copyinit__(inout self, other: Self):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
        for i in range(len(other.data_)):
            self.data_[i] = other.data_[i]
        self.own_ = True

    def __del__(owned self):

    # 1‑based indexing access
    def __getitem__(self, i1: Int, i2: Int) -> T:
        let idx = (i1 - self.l1_) * (self.u2_ - self.l2_ + 1) + (i2 - self.l2_)
        return self.data_[idx]

    def __setitem__(inout self, i1: Int, i2: Int, val: T):
        let idx = (i1 - self.l1_) * (self.u2_ - self.l2_ + 1) + (i2 - self.l2_)
        self.data_[idx] = val

    # Flat indexing (0‑based)
    def __getitem__(self, i: Int) -> T:
        return self.data_[i]

    def __setitem__(inout self, i: Int, val: T):
        self.data_[i] = val

    def __eq__(self, other: Self) -> Bool:
        if self.size() != other.size(): return False
        for i in range(self.size()):
            if self.data_[i] != other.data_[i]: return False
        return True

    def __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    # Inspectors
    def size(self) -> Int:
        return len(self.data_)
    def size1(self) -> Int:
        if self.empty(): return 0
        return self.u1_ - self.l1_ + 1
    def size2(self) -> Int:
        if self.empty(): return 0
        return self.u2_ - self.l2_ + 1
    def l1(self) -> Int:
        return self.l1_
    def u1(self) -> Int:
        return self.u1_
    def l2(self) -> Int:
        return self.l2_
    def u2(self) -> Int:
        return self.u2_
    def I1(self) -> IR:
        return IR(self.l1_, self.u1_)
    def I2(self) -> IR:
        return IR(self.l2_, self.u2_)
    def rank(self) -> Int:
        return 2
    def capacity(self) -> Int:
        return len(self.data_)
    def size(self, dim: Int) -> Int:
        if dim == 1: return self.size1()
        elif dim == 2: return self.size2()
        else: return 0
    def I(self, dim: Int) -> IR:
        if dim == 1: return self.I1()
        elif dim == 2: return self.I2()
        else: return IR()
    def l(self, dim: Int) -> Int:
        if dim == 1: return self.l1_
        elif dim == 2: return self.l2_
        else: return 0
    def u(self, dim: Int) -> Int:
        if dim == 1: return self.u1_
        elif dim == 2: return self.u2_
        else: return 0
    def data(self) -> DTypePointer:  # simplified
        if self.empty(): return DTypePointer()
        return self.data_.data()
    def data_beg(self) -> DTypePointer:
        return self.data()
    def data_end(self) -> DTypePointer:
        if self.empty(): return DTypePointer()
        return self.data_.data() + self.size()

    # Predicates
    def active(self) -> Bool:
        return not self.empty()
    def allocated(self) -> Bool:
        return self.own_ and not self.empty()
    def empty(self) -> Bool:
        return self.size() == 0
    def owner(self) -> Bool:
        return self.own_
    def proxy(self) -> Bool:
        return not self.own_
    def contains(self, i1: Int, i2: Int) -> Bool:
        return i1 >= self.l1_ and i1 <= self.u1_ and i2 >= self.l2_ and i2 <= self.u2_
    def conformable(self, other: Self) -> Bool:
        return self.size1() == other.size1() and self.size2() == other.size2()
    def equal_dimensions(self, other: Self) -> Bool:
        return self.l1() == other.l1() and self.u1() == other.u1() and self.l2() == other.l2() and self.u2() == other.u2()
    def is_identity(self) -> Bool:
        if self.size1() != self.size2(): return False
        for i1 in range(self.l1_, self.u1_+1):
            for i2 in range(self.l2_, self.u2_+1):
                if i1 == i2:
                    if self[i1,i2] != T(1): return False
                else:
                    if self[i1,i2] != T(0): return False
        return True
    def symmetric(self) -> Bool:
        if self.size1() != self.size2(): return False
        for i1 in range(self.l1_, self.u1_+1):
            for i2 in range(self.l2_, self.u2_+1):
                if self[i1,i2] != self[i2,i1]: return False
        return True

    # Modifiers
    def clear(inout self):
        self.l1_ = 1; self.u1_ = 0
        self.l2_ = 1; self.u2_ = 0
        self.data_.clear()
    def allocate(inout self, size1: Int, size2: Int):
        self.l1_ = 1; self.u1_ = size1
        self.l2_ = 1; self.u2_ = size2
        self.data_ = DynamicVector[T](size1*size2)
    def allocate(inout self, other: Self):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
    def deallocate(inout self):
        self.clear()
    def index(self, i1: Int, i2: Int) -> Int:
        return (i1 - self.l1_) * (self.u2_ - self.l2_ + 1) + (i2 - self.l2_)
    def dimension(inout self, i1: IR, i2: IR):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
        let n = (self.u1_ - self.l1_ + 1) * (self.u2_ - self.l2_ + 1)
        # If data_ size differs, reallocate (keep values if possible? Here we preserve data size; simplified)
        if len(self.data_) != n:
            self.data_ = DynamicVector[T](n)
    def dimension(inout self, i1: IR, i2: IR, val: T):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
        let n = (self.u1_ - self.l1_ + 1) * (self.u2_ - self.l2_ + 1)
        self.data_ = DynamicVector[T](n, val)
    def dimension(inout self, i1: IR, i2: IR, init_fn: def (inout Array2D[T]) -> None):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
        let n = (self.u1_ - self.l1_ + 1) * (self.u2_ - self.l2_ + 1)
        self.data_ = DynamicVector[T](n)
        init_fn(self)
    def dimension(inout self, other: Self):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        let n = len(other.data_)
        if len(self.data_) != n:
            self.data_ = DynamicVector[T](n)
    def dimension(inout self, other: Self, val: T):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        let n = len(other.data_)
        self.data_ = DynamicVector[T](n, val)
    def dimension(inout self, other: Self, init_fn: def (inout Array2D[T]) -> None):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        let n = len(other.data_)
        self.data_ = DynamicVector[T](n)
        init_fn(self)
    def swap(inout self, other: inout Self):
        let tmp = self
        self = other
        other = tmp
    def to_identity(inout self):
        for i1 in range(self.l1_, self.u1_+1):
            for i2 in range(self.l2_, self.u2_+1):
                self[i1,i2] = T(1) if i1 == i2 else T(0)
    def to_diag(inout self, val: T):
        for i1 in range(self.l1_, self.u1_+1):
            for i2 in range(self.l2_, self.u2_+1):
                self[i1,i2] = val if (i1 - self.l1_) == (i2 - self.l2_) else T(0)
    def transpose(inout self):
        # For square matrices only? This test uses transpose in place on 2x2; implement general
        let n1 = self.size1()
        let n2 = self.size2()
        # Create a new array with swapped dimensions
        var res = Array2D[T](n2, n1)
        for i1 in range(self.l1_, self.u1_+1):
            for i2 in range(self.l2_, self.u2_+1):
                res[i2 - self.l2_ + 1, i1 - self.l1_ + 1] = self[i1,i2]
        # Move assignment to self
        self.__init__(res)

    # Static constructors
    @staticmethod
    def range(other: Self) -> Self:
        return Array2D[T](other.size1(), other.size2())
    @staticmethod
    def range(other: Self, val: T) -> Self:
        return Array2D[T](other.size1(), other.size2(), val)
    @staticmethod
    def one_based(other: Self) -> Self:
        # Already 1‑based in our implementation; just copy dimensions
        return Array2D[T](other.size1(), other.size2())
    @staticmethod
    def diag(n: Int, val: T) -> Self:
        var res = Array2D[T](n, n, T(0))
        for i in range(1, n+1):
            res[i,i] = val
        return res
    @staticmethod
    def identity(n: Int) -> Self:
        var res = Array2D[T](n, n, T(0))
        for i in range(1, n+1):
            res[i,i] = T(1)
        return res

# Array2A proxy (simplified, non‑owning view)
struct Array2A[T: AnyType]:
    var l1_: Int
    var u1_: Int
    var l2_: Int
    var u2_: Int
    var data_: DynamicVector[T]  # reference to original's data? For simplicity we copy.
    var own_: Bool
    alias npos: Int = -1

    def __init__(inout self):
        self.l1_ = 1; self.u1_ = 0
        self.l2_ = 1; self.u2_ = 0
        self.data_ = DynamicVector[T]()
        self.own_ = False

    def __init__(inout self, other: Array2D[T]):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
        for i in range(len(other.data_)):
            self.data_[i] = other.data_[i]
        self.own_ = False

    def __init__(inout self, other: Array2D[T], size1: Int, size2: Int):
        # For constructing from a sub‑array? Approximate as full copy of other
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
        for i in range(len(other.data_)):
            self.data_[i] = other.data_[i]
        self.own_ = False

    # Copy constructor
    def __copyinit__(inout self, other: Self):
        self.l1_ = other.l1_; self.u1_ = other.u1_
        self.l2_ = other.l2_; self.u2_ = other.u2_
        self.data_ = DynamicVector[T](len(other.data_))
        for i in range(len(other.data_)):
            self.data_[i] = other.data_[i]
        self.own_ = False

    def __getitem__(self, i1: Int, i2: Int) -> T:
        let idx = (i1 - self.l1_) * (self.u2_ - self.l2_ + 1) + (i2 - self.l2_)
        return self.data_[idx]
    def __setitem__(inout self, i1: Int, i2: Int, val: T):
        let idx = (i1 - self.l1_) * (self.u2_ - self.l2_ + 1) + (i2 - self.l2_)
        self.data_[idx] = val

    def size(self) -> Int:
        return len(self.data_)
    def size1(self) -> Int:
        if self.empty(): return 0
        return self.u1_ - self.l1_ + 1
    def size2(self) -> Int:
        if self.empty(): return 0
        return self.u2_ - self.l2_ + 1
    def l1(self) -> Int:
        return self.l1_
    def u1(self) -> Int:
        return self.u1_
    def l2(self) -> Int:
        return self.l2_
    def u2(self) -> Int:
        return self.u2_
    def I1(self) -> IR:
        return IR(self.l1_, self.u1_)
    def I2(self) -> IR:
        return IR(self.l2_, self.u2_)
    def empty(self) -> Bool:
        return self.size() == 0
    def dim(inout self, i1: IR, i2: IR):
        self.l1_ = i1.l; self.u1_ = i1.u
        self.l2_ = i2.l; self.u2_ = i2.u
    def dim(inout self, size1: Int, size2: Int):
        self.l1_ = 1; self.u1_ = size1
        self.l2_ = 1; self.u2_ = size2
        # If data_ size differs, we don't reallocate (proxy)
    def conformable(self, other: Array2A[T]) -> Bool:
        return self.size1() == other.size1() and self.size2() == other.size2()
    def __eq__(self, other: Array2A[T]) -> Bool:
        if self.size() != other.size(): return False
        for i in range(self.size()):
            if self.data_[i] != other.data_[i]: return False
        return True
    def __ne__(self, other: Array2A[T]) -> Bool:
        return not self.__eq__(other)

# Free functions corresponding to ObjexxFCL free functions
def conformable[T](a: Array2D[T], b: Array2D[T]) -> Bool:
    return a.conformable(b)
def equal_dimensions[T](a: Array2D[T], b: Array2D[T]) -> Bool:
    return a.equal_dimensions(b)
def eq[T](a: Array2D[T], b: Array2D[T]) -> Bool:
    return a == b
def eq[T](a: Array2D[T], val: T) -> Bool:
    for i in range(a.size()):
        if a.data_[i] != val: return False
    return True
def eq[T](val: T, a: Array2D[T]) -> Bool:
    return eq(a, val)
def allocated[T](a: Array2D[T]) -> Bool:
    return a.allocated()

# Additional free functions for this test
def transpose[T](a: Array2D[T]) -> Array2D[T]:
    let n1 = a.size1()
    let n2 = a.size2()
    var res = Array2D[T](n2, n1)
    for i1 in range(a.l1(), a.u1()+1):
        for i2 in range(a.l2(), a.u2()+1):
            res[i2, i1] = a[i1, i2]
    return res

def transposed[T](a: Array2D[T]) -> Array2D[T]:
    return transpose(a)

def pow(a: Array2D[Int], exp: Int) -> Array2D[Int]:
    var res = Array2D[Int](a.size1(), a.size2())
    for i1 in range(a.l1(), a.u1()+1):
        for i2 in range(a.l2(), a.u2()+1):
            res[i1,i2] = int(math.pow(float64(a[i1,i2]), float64(exp)))
    return res

def sign(a: Array2D[Int], s: Int) -> Array2D[Int]:
    var res = Array2D[Int](a.size1(), a.size2())
    for i1 in range(a.l1(), a.u1()+1):
        for i2 in range(a.l2(), a.u2()+1):
            if s > 0:
                res[i1,i2] = abs(a[i1,i2])
            elif s < 0:
                res[i1,i2] = -abs(a[i1,i2])
            else:
                res[i1,i2] = 0
    return res

def sign(s: Int, a: Array2D[Int]) -> Array2D[Int]:
    var res = Array2D[Int](a.size1(), a.size2())
    for i1 in range(a.l1(), a.u1()+1):
        for i2 in range(a.l2(), a.u2()+1):
            if a[i1,i2] > 0:
                res[i1,i2] = 1 if s > 0 else (-1 if s < 0 else 0)
            elif a[i1,i2] < 0:
                res[i1,i2] = -1 if s > 0 else (1 if s < 0 else 0)
            else:
                res[i1,i2] = 0
    return res

def count(a: Array2D[Bool]) -> Int:
    var c = 0
    for i in range(a.size()):
        if a.data_[i]: c += 1
    return c

def count(a: Array2D[Bool], dim: Int) -> Array1D[Int]:
    let n1 = a.size1()
    let n2 = a.size2()
    if dim == 1:
        var res = Array1D[Int](n2)
        for i2 in range(1, n2+1):
            var s = 0
            for i1 in range(1, n1+1):
                if a[i1,i2]: s += 1
            res[i2-1] = s  # using 0‑based internal in Array1D? We'll treat Array1D as 0‑based
        return res
    else:
        var res = Array1D[Int](n1)
        for i1 in range(1, n1+1):
            var s = 0
            for i2 in range(1, n2+1):
                if a[i1,i2]: s += 1
            res[i1-1] = s
        return res

def sum(a: Array2D[Int]) -> Int:
    var s = 0
    for i in range(a.size()):
        s += a.data_[i]
    return s

def sum(a: Array2D[Int], dim: Int) -> Array1D[Int]:
    let n1 = a.size1()
    let n2 = a.size2()
    if dim == 1:
        var res = Array1D[Int](n2)
        for i2 in range(1, n2+1):
            var s = 0
            for i1 in range(1, n1+1):
                s += a[i1,i2]
            res[i2-1] = s
        return res
    else:
        var res = Array1D[Int](n1)
        for i1 in range(1, n1+1):
            var s = 0
            for i2 in range(1, n2+1):
                s += a[i1,i2]
            res[i1-1] = s
        return res

# Simple Array1D for tests (0‑based)
struct Array1D[T: AnyType]:
    var data_: DynamicVector[T]
    def __init__(inout self, n: Int):
        self.data_ = DynamicVector[T](n)
    def __init__(inout self, n: Int, val: T):
        self.data_ = DynamicVector[T](n, val)
    def __init__(inout self, n: Int, vals: StaticArray[T, ...]):
        self.data_ = DynamicVector[T](n)
        for i in range(n):
            self.data_[i] = vals[i]
    def __getitem__(self, i: Int) -> T:
        return self.data_[i]
    def __setitem__(inout self, i: Int, val: T):
        self.data_[i] = val
    def size(self) -> Int:
        return len(self.data_)
    def __eq__(self, other: Self) -> Bool:
        if self.size() != other.size(): return False
        for i in range(self.size()):
            if self.data_[i] != other.data_[i]: return False
        return True
    def __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

# Helper for initializer lists: we'll use StaticArray literals in tests
# The test functions themselves

def initializer_function_int(inout A: Array2D_int):
    for i1 in range(A.l1(), A.u1()+1):
        for i2 in range(A.l2(), A.u2()+1):
            A[i1,i2] = i1 * 10 + i2

def initializer_function_double(inout A: Array2D_double):
    for i1 in range(A.l1(), A.u1()+1):
        for i2 in range(A.l2(), A.u2()+1):
            A[i1,i2] = i1 + i2 * 0.1

def dimension_initializer_function(inout A1: Array2D_int):
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            A1[i1,i2] = i1 * 10 + i2

# Tests
@(Test)
def ConstructDefault():
    var A1 = Array2D_int()
    assert_eq(0, A1.size())
    assert_eq(0, A1.size1())
    assert_eq(0, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(1, A1.l2())
    assert_eq(0, A1.u1())
    assert_eq(0, A1.u2())
    assert_eq(Array2D_int.IR(), A1.I1())
    assert_eq(Array2D_int.IR(), A1.I2())
    let C1 = Array2D_int()
    assert_eq(0, C1.size())
    assert_eq(0, C1.size1())
    assert_eq(0, C1.size2())
    assert_eq(1, C1.l1())
    assert_eq(1, C1.l2())
    assert_eq(0, C1.u1())
    assert_eq(0, C1.u2())
    assert_eq(Array2D_int.IR(), C1.I1())
    assert_eq(Array2D_int.IR(), C1.I2())

@(Test)
def ConstructCopy():
    var A1 = Array2D_int()
    var A2 = Array2D_int(A1)
    assert_eq(A1.size(), A2.size())
    assert_eq(A1.size1(), A2.size1())
    assert_eq(A1.size2(), A2.size2())
    assert_eq(A1.l1(), A2.l1())
    assert_eq(A1.u1(), A2.u1())
    assert_eq(A1.l2(), A2.l2())
    assert_eq(A1.u2(), A2.u2())
    assert_eq(A1.I1(), A2.I1())
    assert_eq(A1.I2(), A2.I2())
    assert_true(conformable(A1, A2))
    assert_true(equal_dimensions(A1, A2))
    assert_true(eq(A1, A2))
    let C1 = Array2D_int()
    let C2 = Array2D_int(C1)
    assert_eq(C1.size(), C2.size())
    assert_eq(C1.size1(), C2.size1())
    assert_eq(C1.size2(), C2.size2())
    assert_eq(C1.l2(), C2.l2())
    assert_eq(C1.u2(), C2.u2())
    assert_eq(C1.l1(), C2.l1())
    assert_eq(C1.u1(), C2.u1())
    assert_eq(C1.I1(), C2.I1())
    assert_eq(C1.I2(), C2.I2())
    assert_true(eq(C1, C2))

@(Test)
def ConstructOtherData():
    var A1 = Array2D_double(2, 3)
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            A1[i1,i2] = i1 + i2
    var A2 = Array2D_int(A1)
    assert_eq(A1.size(), A2.size())
    assert_eq(A1.size1(), A2.size1())
    assert_eq(A1.size2(), A2.size2())
    assert_eq(A1.l1(), A2.l1())
    assert_eq(A1.u1(), A2.u1())
    assert_eq(A1.l2(), A2.l2())
    assert_eq(A1.u2(), A2.u2())
    assert_eq(A1.I1(), A2.I1())
    assert_eq(A1.I2(), A2.I2())
    assert_true(conformable(A1, A2))
    assert_true(equal_dimensions(A1, A2))
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            assert_eq(int(A1[i1,i2]), A2[i1,i2])
            assert_true(double(A2[i1,i2]) == A1[i1,i2])  # Works because they are all integer values

@(Test)
def ConstructArgument():
    var A1 = Array2D_int(2, 3, 31459)
    var A2 = Array2A_int(A1)
    var A3 = Array2D_int(A2)
    assert_eq(A2.size(), A3.size())
    assert_eq(A2.size1(), A3.size1())
    assert_eq(A2.size2(), A3.size2())
    assert_eq(A2.I1(), A3.I1())
    assert_eq(A2.I2(), A3.I2())
    assert_eq(A2.l1(), A3.l1())
    assert_eq(A2.u1(), A3.u1())
    assert_eq(A2.l2(), A3.l2())
    assert_eq(A2.u2(), A3.u2())
    assert_true(conformable(A1, A3))
    assert_true(equal_dimensions(A1, A3))
    assert_true(eq(A2, A3))
    let C1 = Array2D_int(2, 3, 31459)
    let C2 = Array2A_int(C1)
    let C3 = Array2D_int(C2)
    assert_eq(C2.size(), C3.size())
    assert_eq(C2.size1(), C3.size1())
    assert_eq(C2.size2(), C3.size2())
    assert_eq(C2.l1(), C3.l1())
    assert_eq(C2.l2(), C3.l2())
    assert_eq(C2.u1(), C3.u1())
    assert_eq(C2.u2(), C3.u2())
    assert_true(conformable(C1, C3))
    assert_true(equal_dimensions(C1, C3))
    assert_true(eq(C2, C3))
    var E1 = Array2D_int(2, 3, 31459)
    var E2 = Array2A_int(E1, 2, 2)  # simplified: just copies full E1
    assert_eq(Array2A_int.npos, E2.size())
    assert_eq(Array2A_int.npos, E2.size1())
    assert_eq(1, E2.size2())
    assert_eq(1, E2.l1())
    assert_eq(-1, E2.u1())
    assert_eq(1, E2.l2())
    assert_eq(1, E2.u2())
    assert_eq(31459, E2[1,1])
    assert_eq(31459, E2[2,1])
    E2.dim(_, 1)
    assert_eq(1, E2.size2())
    assert_eq(1, E2.l1())
    assert_eq(-1, E2.u1())
    assert_eq(1, E2.l2())
    assert_eq(1, E2.u2())
    assert_eq(31459, E2[1,1])
    assert_eq(31459, E2[2,1])
    E2.dim(1, 2)
    assert_eq(2, E2.size2())
    assert_eq(1, E2.l1())
    assert_eq(1, E2.u1())
    assert_eq(1, E2.l2())
    assert_eq(2, E2.u2())
    assert_eq(31459, E2[1,1])
    assert_eq(31459, E2[1,2])
    # EXPECT_DEBUG_DEATH skipped
    var F1 = Array2D_int(3, 3, 31459)
    var F2 = Array2A_int(F1, 2, 2)
    assert_eq(4, F2.size())
    assert_eq(2, F2.size1())
    assert_eq(2, F2.size2())
    assert_eq(1, F2.l1())
    assert_eq(2, F2.u1())
    assert_eq(1, F2.l2())
    assert_eq(2, F2.u2())
    assert_true(eq(F2, 31459))

@(Test)
def ConstructIndexes():
    var A1 = Array2D_int(8, 10)
    assert_eq(80, A1.size())
    assert_eq(8, A1.size1())
    assert_eq(10, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(8, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(10, A1.u2())
    assert_eq(Array2D_int.IR(1,8), A1.I1())
    assert_eq(Array2D_int.IR(1,10), A1.I2())
    let C1 = Array2D_int(8, 10)
    assert_eq(80, C1.size())
    assert_eq(8, C1.size1())
    assert_eq(10, C1.size2())
    assert_eq(1, C1.l1())
    assert_eq(8, C1.u1())
    assert_eq(1, C1.l1())
    assert_eq(10, C1.u2())
    assert_eq(Array2D_int.IR(1,8), A1.I1())
    assert_eq(Array2D_int.IR(1,10), A1.I2())

@(Test)
def ConstructIndexRange():
    var A11 = Array2D_int(IR(2,5), IR(3,7))
    assert_eq(20, A11.size())
    assert_eq(4, A11.size1())
    assert_eq(5, A11.size2())
    assert_eq(2, A11.l1())
    assert_eq(5, A11.u1())
    assert_eq(3, A11.l2())
    assert_eq(7, A11.u2())
    assert_eq(Array2D_int.IR(2,5), A11.I1())
    assert_eq(Array2D_int.IR(3,7), A11.I2())
    var A12 = Array2D_int(IR(-5,-2), IR(-7,-3))
    assert_eq(20, A12.size())
    assert_eq(4, A12.size1())
    assert_eq(5, A12.size2())
    assert_eq(-5, A12.l1())
    assert_eq(-2, A12.u1())
    assert_eq(-7, A12.l2())
    assert_eq(-3, A12.u2())
    assert_eq(Array2D_int.IR(-5,-2), A12.I1())
    assert_eq(Array2D_int.IR(-7,-3), A12.I2())
    var A13 = Array2D_int(IR(-3,3), IR(-2,2))
    assert_eq(35, A13.size())
    assert_eq(7, A13.size1())
    assert_eq(5, A13.size2())
    assert_eq(-3, A13.l1())
    assert_eq(3, A13.u1())
    assert_eq(-2, A13.l2())
    assert_eq(2, A13.u2())
    assert_eq(Array2D_int.IR(-3,3), A13.I1())
    assert_eq(Array2D_int.IR(-2,2), A13.I2())
    # Using brace initializer lists (not fully implemented; using StaticArray)
    var A21 = Array2D_int({2,5}, {3,7})
    assert_eq(20, A21.size())
    assert_eq(4, A21.size1())
    assert_eq(5, A21.size2())
    assert_eq(2, A21.l1())
    assert_eq(5, A21.u1())
    assert_eq(3, A21.l2())
    assert_eq(7, A21.u2())
    assert_eq(Array2D_int.IR(2,5), A21.I1())
    assert_eq(Array2D_int.IR(3,7), A21.I2())
    var A22 = Array2D_int({-5,-2}, {-7,-3})
    assert_eq(20, A22.size())
    assert_eq(4, A22.size1())
    assert_eq(5, A22.size2())
    assert_eq(-5, A22.l1())
    assert_eq(-2, A22.u1())
    assert_eq(-7, A22.l2())
    assert_eq(-3, A22.u2())
    assert_eq(Array2D_int.IR(-5,-2), A22.I1())
    assert_eq(Array2D_int.IR(-7,-3), A22.I2())
    var A23 = Array2D_int({-3,3}, {-2,2})
    assert_eq(35, A23.size())
    assert_eq(7, A23.size1())
    assert_eq(5, A23.size2())
    assert_eq(-3, A23.l1())
    assert_eq(3, A23.u1())
    assert_eq(-2, A23.l2())
    assert_eq(2, A23.u2())
    assert_eq(Array2D_int.IR(-3,3), A23.I1())
    assert_eq(Array2D_int.IR(-2,2), A23.I2())

@(Test)
def ConstructIndexesInitializerValue():
    var A1 = Array2D_int(8, 10, 31459)
    assert_eq(80, A1.size())
    assert_eq(8, A1.size1())
    assert_eq(10, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(8, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(10, A1.u2())
    assert_eq(Array2D_int.IR(1,8), A1.I1())
    assert_eq(Array2D_int.IR(1,10), A1.I2())
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(31459, A1[i1,i2])
    let C1 = Array2D_int(8, 10, 31459)
    assert_eq(80, C1.size())
    assert_eq(8, C1.size1())
    assert_eq(10, C1.size2())
    assert_eq(1, C1.l1())
    assert_eq(8, C1.u1())
    assert_eq(1, C1.l2())
    assert_eq(10, C1.u2())
    assert_eq(Array2D_int.IR(1,8), C1.I1())
    assert_eq(Array2D_int.IR(1,10), C1.I2())
    for i1 in range(C1.l1(), C1.u1()+1):
        for i2 in range(C1.l2(), C1.u2()+1):
            assert_eq(31459, C1[i1,i2])

@(Test)
def ConstructIndexRangeInitializerValue():
    var A11 = Array2D_int(IR(2,5), IR(3,7), 31459)
    assert_eq(20, A11.size())
    assert_eq(4, A11.size1())
    assert_eq(5, A11.size2())
    assert_eq(2, A11.l1())
    assert_eq(5, A11.u1())
    assert_eq(3, A11.l2())
    assert_eq(7, A11.u2())
    assert_eq(Array2D_int.IR(2,5), A11.I1())
    assert_eq(Array2D_int.IR(3,7), A11.I2())
    for i1 in range(A11.l1(), A11.u1()+1):
        for i2 in range(A11.l2(), A11.u2()+1):
            assert_eq(31459, A11[i1,i2])
    var A12 = Array2D_int(IR(-3,3), IR(-2,2), -31459)
    assert_eq(35, A12.size())
    assert_eq(7, A12.size1())
    assert_eq(5, A12.size2())
    assert_eq(-3, A12.l1())
    assert_eq(3, A12.u1())
    assert_eq(-2, A12.l2())
    assert_eq(2, A12.u2())
    assert_eq(Array2D_int.IR(-3,3), A12.I1())
    assert_eq(Array2D_int.IR(-2,2), A12.I2())
    for i1 in range(A12.l1(), A12.u1()+1):
        for i2 in range(A12.l2(), A12.u2()+1):
            assert_eq(-31459, A12[i1,i2])
    var A21 = Array2D_int({2,5}, {3,7}, 2718)
    assert_eq(20, A21.size())
    assert_eq(4, A21.size1())
    assert_eq(5, A21.size2())
    assert_eq(2, A21.l1())
    assert_eq(5, A21.u1())
    assert_eq(3, A21.l2())
    assert_eq(7, A21.u2())
    assert_eq(Array2D_int.IR(2,5), A21.I1())
    assert_eq(Array2D_int.IR(3,7), A21.I2())
    for i1 in range(A21.l1(), A21.u1()+1):
        for i2 in range(A21.l2(), A21.u2()+1):
            assert_eq(2718, A21[i1,i2])
    var A22 = Array2D_int({-3,3}, {-2,2}, -2718)
    assert_eq(35, A22.size())
    assert_eq(7, A22.size1())
    assert_eq(5, A22.size2())
    assert_eq(-3, A22.l1())
    assert_eq(3, A22.u1())
    assert_eq(-2, A22.l2())
    assert_eq(2, A22.u2())
    assert_eq(Array2D_int.IR(-3,3), A22.I1())
    assert_eq(Array2D_int.IR(-2,2), A22.I2())
    for i1 in range(A22.l1(), A22.u1()+1):
        for i2 in range(A22.l2(), A22.u2()+1):
            assert_eq(-2718, A22[i1,i2])

@(Test)
def ConstructIndexesInitializerFunction():
    var A1 = Array2D_int(2, 3, initializer_function_int)
    assert_true(eq(Array2D_int(2, 3, {11,12,13,21,22,23}), A1))
    var A2 = Array2D_double(2, 3, initializer_function_double)
    assert_true(eq(Array2D_double(2, 3, {1.1,1.2,1.3,2.1,2.2,2.3}), A2))
    let C1 = Array2D_int(2, 3, initializer_function_int)
    assert_true(eq(Array2D_int(2, 3, {11,12,13,21,22,23}), C1))
    let C2 = Array2D_double(2, 3, initializer_function_double)
    assert_true(eq(Array2D_double(2, 3, {1.1,1.2,1.3,2.1,2.2,2.3}), C2))

@(Test)
def ConstructIndexRangeInitializerFunction():
    var A1 = Array2D_int({0,1}, {-1,1}, initializer_function_int)
    assert_true(eq(Array2D_int({0,1}, {-1,1}, {-1,0,1,9,10,11}), A1))
    var A2 = Array2D_double({0,1}, {-1,1}, initializer_function_double)
    assert_true(eq(Array2D_double({0,1}, {-1,1}, {-0.1,0.0,0.1,0.9,1.0,1.1}), A2))
    let C1 = Array2D_int({0,1}, {-1,1}, initializer_function_int)
    assert_true(eq(Array2D_int({0,1}, {-1,1}, {-1,0,1,9,10,11}), C1))
    let C2 = Array2D_double({0,1}, {-1,1}, initializer_function_double)
    assert_true(eq(Array2D_double({0,1}, {-1,1}, {-0.1,0.0,0.1,0.9,1.0,1.1}), C2))

@(Test)
def ConstructIndexesInitializerList():
    var A1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_eq(6, A1.size())
    assert_eq(2, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(2, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(3, A1.u2())
    assert_eq(Array2D_int.IR(1,2), A1.I1())
    assert_eq(Array2D_int.IR(1,3), A1.I2())
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(i1*10 + i2, A1[i1,i2])
    var A2 = Array2D[Int](2, 3, {11,12,13,21,22,23})  # using Int
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(2, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(3, A2.u2())
    assert_eq(Array2D_int.IR(1,2), A2.I1())
    assert_eq(Array2D_int.IR(1,3), A2.I2())
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            assert_eq(unsigned(i1*10 + i2), A2[i1,i2])
    var A3 = Array2D_double(2, 3, {1.1,1.2,1.3,2.1,2.2,2.3})
    assert_eq(6, A3.size())
    assert_eq(2, A3.size1())
    assert_eq(3, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(2, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(3, A3.u2())
    assert_eq(Array2D_int.IR(1,2), A3.I1())
    assert_eq(Array2D_int.IR(1,3), A3.I2())
    for i1 in range(A3.l1(), A3.u1()+1):
        for i2 in range(A3.l2(), A3.u2()+1):
            assert_true(i1 + i2 * 0.1 == A3[i1,i2])
    var A4 = Array2D_string(2, 3, {"1,1","1,2","1,3","2,1","2,2","2,3"})
    assert_eq(6, A4.size())
    assert_eq(2, A4.size1())
    assert_eq(3, A4.size2())
    assert_eq(1, A4.l1())
    assert_eq(2, A4.u1())
    assert_eq(1, A4.l2())
    assert_eq(3, A4.u2())
    assert_eq(Array2D_int.IR(1,2), A4.I1())
    assert_eq(Array2D_int.IR(1,3), A4.I2())
    let chars = ["", "1", "2", "3"]
    for i1 in range(A4.l1(), A4.u1()+1):
        for i2 in range(A4.l2(), A4.u2()+1):
            let c1 = chars[i1]
            let c2 = chars[i2]
            assert_eq(c1 + "," + c2, A4[i1,i2])

@(Test)
def ConstructIndexRangeInitializerList():
    var A1 = Array2D_int({0,1}, {-1,1}, {-1,0,1,9,10,11})
    assert_eq(6, A1.size())
    assert_eq(2, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(0, A1.l1())
    assert_eq(1, A1.u1())
    assert_eq(-1, A1.l2())
    assert_eq(1, A1.u2())
    assert_eq(Array2D_int.IR(0,1), A1.I1())
    assert_eq(Array2D_int.IR(-1,1), A1.I2())
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(i1*10 + i2, A1[i1,i2])
    var A2 = Array2D_string({0,1}, {-1,1}, {"0,-1","0,0","0,1","1,-1","1,0","1,1"})
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(0, A2.l1())
    assert_eq(1, A2.u1())
    assert_eq(-1, A2.l2())
    assert_eq(1, A2.u2())
    assert_eq(Array2D_int.IR(0,1), A2.I1())
    assert_eq(Array2D_int.IR(-1,1), A2.I2())
    let chars1 = ["0", "1"]
    let chars2 = ["-1", "0", "1"]
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            let c1 = chars1[i1]
            let c2 = chars2[i2 + 1]
            assert_eq(c1 + "," + c2, A2[i1,i2])

@(Test)
def ConstructRange():
    var A1 = Array2D_int(2, 3)
    var A2 = Array2D_int.range(A1)
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(2, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(3, A2.u2())
    assert_eq(Array2D_int.IR(1,2), A2.I1())
    assert_eq(Array2D_int.IR(1,3), A2.I2())
    var A3 = Array2D_int.range(A1, 31459)
    assert_eq(6, A3.size())
    assert_eq(2, A3.size1())
    assert_eq(3, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(2, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(3, A3.u2())
    assert_eq(Array2D_int.IR(1,2), A3.I1())
    assert_eq(Array2D_int.IR(1,3), A3.I2())
    for i1 in range(1, 3):
        for i2 in range(1, 4):
            assert_eq(31459, A3[i1,i2])

@(Test)
def ConstructOneBased():
    var A1 = Array2D_int(2, 3)
    var A2 = Array2D_int.one_based(A1)
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(2, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(3, A2.u2())
    assert_eq(Array2D_int.IR(1,2), A2.I1())
    assert_eq(Array2D_int.IR(1,3), A2.I2())

@(Test)
def ConstructDiag():
    var A1 = Array2D_int.diag(3, 31459)
    assert_eq(9, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(3, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(3, A1.u2())
    assert_eq(Array2D_int.IR(1,3), A1.I1())
    assert_eq(Array2D_int.IR(1,3), A1.I2())
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(31459 if i1 == i2 else 0, A1[i1,i2])

@(Test)
def ConstructIdentity():
    var A1 = Array2D_int.identity(3)
    assert_eq(9, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(3, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(3, A1.u2())
    assert_eq(Array2D_int.IR(1,3), A1.I1())
    assert_eq(Array2D_int.IR(1,3), A1.I2())
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(1 if i1 == i2 else 0, A1[i1,i2])

@(Test)
def AssignmentCopy():
    var A1 = Array2D_double(2, 3, 3.1459)
    let A2 = Array2D_double(2, 3, 2.718)
    assert_false(eq(A1, A2))
    A1 = A2
    assert_true(eq(A1, A2))
    A1 = 3.1459
    for i1 in range(1, 3):
        for i2 in range(1, 4):
            assert_eq(3.1459, A1[i1,i2])
    A1 = {1.1, 1.2, 1.3, 2.1, 2.2, 2.3}
    for i1 in range(1, 3):
        for i2 in range(1, 4):
            assert_eq(i1 + i2 * 0.1, A1[i1,i2])

@(Test)
def AssignmentMove():
    var A1 = Array2D_double(2, 3, 3.1459)
    A1 = Array2D_double(3, 3, 2.25)
    assert_eq(3, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(9, A1.size())
    assert_true(eq(A1, 2.25))
    var A2 = Array2D_double(4, 2, 3.5)
    A1 = std.move(A2)  # simplified: not exactly move, copy
    assert_eq(0, A2.size())
    assert_eq(8, A1.size())
    assert_eq(4, A1.size1())
    assert_eq(2, A1.size2())
    assert_true(eq(A1, 3.5))

@(Test)
def AssignmentOtherDataType():
    var A1 = Array2D_int(2, 3, 31459)
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(31459, A1[i1,i2])
    let A2 = Array2D_double(2, 3, 3.1459)
    A1 = A2
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(3, A1[i1,i2])
    A1 = 2.718
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(2, A1[i1,i2])
    A1 = {1.1, 1.2, 1.3, 2.1, 2.2, 2.3}
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(i1, A1[i1,i2])

@(Test)
def AssignmentArgument():
    var A1 = Array2D_int(2, 3, 31459)
    var A2 = Array2A_int(A1)
    var A3 = Array2D_int(2, 3, 2718)
    for i1 in range(A1.l1(), A1.u1()+1):
        for i2 in range(A1.l2(), A1.u2()+1):
            assert_eq(31459, A1[i1,i2])
    A3 = A2
    for i1 in range(A3.l1(), A3.u1()+1):
        for i2 in range(A3.l2(), A3.u2()+1):
            assert_eq(31459, A3[i1,i2])

@(Test)
def AssignmentArithmetic():
    var A1 = Array2D_int(2, 3, 11)
    let A2 = Array2D_int(2, 3, 10)
    assert_true(eq(Array2D_int(2, 3, 11), A1))
    A1 += A2
    assert_true(eq(Array2D_int(2, 3, 21), A1))
    A1 -= A2
    assert_true(eq(Array2D_int(2, 3, 11), A1))
    A1 += 33
    assert_true(eq(Array2D_int(2, 3, 44), A1))
    A1 -= 33
    assert_true(eq(Array2D_int(2, 3, 11), A1))
    A1 *= A2
    assert_true(eq(Array2D_int(2, 3, 110), A1))

@(Test)
def AssignmentArithmeticArgument():
    var A1 = Array2D_int(2, 3, 11)
    let A2 = Array2D_int(2, 3, 10)
    var A3 = Array2A_int(A2)
    A1 += A3
    assert_true(eq(Array2D_int(2, 3, 21), A1))
    A1 -= A3
    assert_true(eq(Array2D_int(2, 3, 11), A1))
    A1 += 33
    assert_true(eq(Array2D_int(2, 3, 44), A1))
    A1 -= 33
    assert_true(eq(Array2D_int(2, 3, 11), A1))
    A1 *= A3
    assert_true(eq(Array2D_int(2, 3, 110), A1))

@(Test)
def RangeBasedFor():
    var A = Array2D_int(2, 3, {1,2,3,4,5,6})
    var v = 0
    for e in A:
        v += 1
        assert_eq(v, e)

@(Test)
def SubscriptIndex():
    var A1 = Array2D_int(2, 3)
    assert_eq(0, A1.index(1,1))
    assert_eq(1, A1.index(1,2))
    assert_eq(2, A1.index(1,3))
    assert_eq(3, A1.index(2,1))
    assert_eq(4, A1.index(2,2))
    assert_eq(5, A1.index(2,3))
    let C1 = Array2D_int(2, 3)
    assert_eq(0, C1.index(1,1))
    assert_eq(1, C1.index(1,2))
    assert_eq(2, C1.index(1,3))
    assert_eq(3, C1.index(2,1))
    assert_eq(4, C1.index(2,2))
    assert_eq(5, C1.index(2,3))

@(Test)
def SubscriptOperator():
    var A1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_eq(6, A1.size())
    assert_eq(11, A1[0])
    assert_eq(12, A1[1])
    assert_eq(13, A1[2])
    assert_eq(21, A1[3])
    assert_eq(22, A1[4])
    assert_eq(23, A1[5])
    for i in range(A1.size()):
        A1[i] = int(i * 10)
    assert_eq(0, A1[0])
    assert_eq(10, A1[1])
    assert_eq(20, A1[2])
    assert_eq(30, A1[3])
    assert_eq(40, A1[4])
    assert_eq(50, A1[5])
    let C1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_eq(11, C1[0])
    assert_eq(12, C1[1])
    assert_eq(13, C1[2])
    assert_eq(21, C1[3])
    assert_eq(22, C1[4])
    assert_eq(23, C1[5])

@(Test)
def Predicates():
    var A1 = Array2D_int()
    assert_false(A1.active())
    assert_false(A1.allocated())
    assert_true(A1.empty())
    assert_true(A1.size_bounded())
    assert_true(A1.owner())
    assert_false(A1.proxy())
    var A2 = Array2D_int(2, 3)
    assert_true(A2.active())
    assert_true(A2.allocated())
    assert_false(A2.empty())
    assert_true(A2.owner())
    assert_false(A2.proxy())
    var A3 = Array2D_int(2, 3, 31459)
    assert_true(A3.active())
    assert_true(A3.allocated())
    assert_false(A3.empty())
    assert_true(A3.owner())
    assert_false(A3.proxy())
    var A4 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_true(A4.active())
    assert_true(A4.allocated())
    assert_false(A4.empty())
    assert_true(A4.owner())
    assert_false(A4.proxy())

@(Test)
def PredicateComparisonsValues():
    var A1 = Array2D_int()
    assert_true(eq(A1, 0) and eq(0, A1))
    var A2 = Array2D_int(2, 3, 31459)
    assert_true(eq(A2, 31459) and eq(31459, A1))
    var A3 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_false(eq(A3, 11) or eq(23, A3))

@(Test)
def PredicateComparisonArrays():
    var A1 = Array2D_int()
    assert_true(eq(A1, A1))
    var A2 = Array2D_int(2, 3, 20)
    assert_true(eq(A2, A2))
    var A3 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_true(eq(A3, A3))
    assert_false(eq(A2, A3) or eq(A3, A2))
    var A4 = Array2D_int(2, 3, {11,12,12,21,21,22})
    assert_false(eq(A3, A4) or eq(A4, A3))
    var A5 = Array2D_int(2, 3, {11,12,14,21,23,24})
    assert_false(eq(A3, A4) or eq(A4, A3))

@(Test)
def PredicateContains():
    var A1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_true(A1.contains(1,1) and A1.contains(2,3))
    assert_false(A1.contains(3,3) and A1.contains(2,4))
    assert_false(A1.contains(0,1) and A1.contains(1,0))
    var A2 = Array2D_int({-3,-2}, {-1,1}, {11,12,13,21,22,23})
    assert_true(A2.contains(-3,-1) and A2.contains(-2,1))
    assert_false(A2.contains(0,1) and A2.contains(-2,2))
    assert_false(A2.contains(-4,-1) and A2.contains(-3,-2))
    let C1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_true(C1.contains(1,1) and C1.contains(2,3))
    assert_false(C1.contains(3,3) and C1.contains(2,4))
    assert_false(C1.contains(0,1) and C1.contains(1,0))
    let C2 = Array2D_int({-3,-2}, {-1,1}, {11,12,13,21,22,23})
    assert_true(C2.contains(-3,-1) and C2.contains(-2,1))
    assert_false(C2.contains(0,1) and C2.contains(-2,2))
    assert_false(C2.contains(-4,-1) and C2.contains(-3,-2))

@(Test)
def PredicateConformable():
    var A1 = Array2D_int()
    var A2 = Array2D_int(2, 3)
    var A3 = Array2D_int(2, 4)
    var A4 = Array2D_int({2,3}, {2,4})
    assert_false(A1.conformable(A2) or A2.conformable(A1))
    assert_false(A1.conformable(A3) or A3.conformable(A1))
    assert_false(A1.conformable(A4) or A4.conformable(A1))
    assert_false(A2.conformable(A3) or A3.conformable(A2))
    assert_true(A2.conformable(A4) and A4.conformable(A2))
    assert_false(A3.conformable(A4) or A4.conformable(A3))
    let C1 = Array2D_int()
    let C2 = Array2D_int(2, 3)
    let C3 = Array2D_int(2, 4)
    let C4 = Array2D_int({2,3}, {2,4})
    assert_false(C1.conformable(C2) or C2.conformable(C1))
    assert_false(C1.conformable(C3) or C3.conformable(C1))
    assert_false(C1.conformable(C4) or C4.conformable(C1))
    assert_false(C2.conformable(C3) or C3.conformable(C2))
    assert_true(C2.conformable(C4) and C4.conformable(C2))
    assert_false(C3.conformable(C4) or C4.conformable(C3))

@(Test)
def PredicateConformableOtherData():
    var A1 = Array2D_int(2, 3)
    var A2 = Array2D_double(2, 3)
    var A3 = Array2D_string(2, 3)
    assert_true(A1.conformable(A2) and A2.conformable(A1))
    assert_true(A1.conformable(A3) and A3.conformable(A1))
    assert_true(A2.conformable(A3) and A3.conformable(A2))
    let C1 = Array2D_int(2, 3)
    let C2 = Array2D_double(2, 3)
    let C3 = Array2D_string(2, 3)
    assert_true(C1.conformable(C2) and C2.conformable(C1))
    assert_true(C1.conformable(C3) and C3.conformable(C1))
    assert_true(C2.conformable(C3) and C3.conformable(C2))

@(Test)
def PredicateConformableOtherArray():
    var A1 = Array2D_int(2, 3)
    var A2 = Array2A_int(A1)
    var A3 = Array2D_int(2, 3)
    assert_true(A1.conformable(A2) and A2.conformable(A1))
    assert_true(A2.conformable(A3) and A3.conformable(A2))
    let C1 = Array2D_int(2, 3)
    let C2 = Array2A_int(C1)
    let C3 = Array2D_int(2, 3)
    assert_true(C1.conformable(C2) and C2.conformable(C1))
    assert_true(C2.conformable(C3) and C3.conformable(C2))

@(Test)
def PredicateEqualDimensions():
    var A1 = Array2D_int()
    var A2 = Array2D_int(2, 3)
    var A3 = Array2D_int(2, 4)
    var A4 = Array2D_int({2,3}, {2,4})
    assert_false(A1.equal_dimensions(A2) or A2.equal_dimensions(A1))
    assert_false(A1.equal_dimensions(A3) or A3.equal_dimensions(A1))
    assert_false(A1.equal_dimensions(A4) or A4.equal_dimensions(A1))
    assert_false(A2.equal_dimensions(A3) or A3.equal_dimensions(A2))
    assert_false(A2.equal_dimensions(A4) or A4.equal_dimensions(A2))
    assert_false(A3.equal_dimensions(A4) or A4.equal_dimensions(A3))
    var A5 = Array2D_int(2, 3, 31459)
    assert_true(A2.equal_dimensions(A5) and A5.equal_dimensions(A2))
    let C1 = Array2D_int()
    let C2 = Array2D_int(2, 3)
    let C3 = Array2D_int(2, 4)
    let C4 = Array2D_int({2,3}, {2,4})
    assert_false(C1.equal_dimensions(C2) or C2.equal_dimensions(C1))
    assert_false(C1.equal_dimensions(C3) or C3.equal_dimensions(C1))
    assert_false(C1.equal_dimensions(C4) or C4.equal_dimensions(C1))
    assert_false(C2.equal_dimensions(C3) or C3.equal_dimensions(C2))
    assert_false(C2.equal_dimensions(C4) or C4.equal_dimensions(C2))
    assert_false(C3.equal_dimensions(C4) or C4.equal_dimensions(C3))
    var C5 = Array2D_int(2, 3, 31459)
    assert_true(C2.equal_dimensions(C5) and C5.equal_dimensions(C2))

@(Test)
def PredicateIdentity():
    var A1 = Array2D_int()
    assert_true(A1.is_identity())
    var A2 = Array2D_int(1, 1, 1)
    assert_true(A2.is_identity())
    var A3 = Array2D_int(1, 1, 2)
    assert_false(A3.is_identity())
    var A4 = Array2D_int(2, 2, 1)
    assert_false(A4.is_identity())
    var A5 = Array2D_int(2, 2, 2)
    assert_false(A5.is_identity())
    var A6 = Array2D_int(2, 2, {1,2,2,1})
    assert_false(A6.is_identity())
    var A7 = Array2D_int(2, 2, {1,0,0,1})
    assert_true(A7.is_identity())

@(Test)
def PredicateSymmetric():
    var A1 = Array2D_int()
    assert_true(A1.symmetric())
    var A2 = Array2D_int(1, 1, 1)
    assert_true(A2.symmetric())
    var A3 = Array2D_int(1, 1, 2)
    assert_true(A3.symmetric())
    var A4 = Array2D_int(2, 2, 1)
    assert_true(A4.symmetric())
    var A5 = Array2D_int(2, 2, 2)
    assert_true(A5.symmetric())
    var A6 = Array2D_int(2, 2, {1,2,3,1})
    assert_false(A6.symmetric())
    var A7 = Array2D_int(2, 2, {1,2,2,1})
    assert_true(A7.symmetric())

@(Test)
def Inspectors():
    let C1 = Array2D_int()
    assert_eq(2, C1.rank())
    assert_eq(0, C1.size())
    assert_eq(0, C1.capacity())
    assert_eq(0, C1.size(1))
    assert_eq(C1.size1(), C1.size(1))
    assert_eq(0, C1.size(2))
    assert_eq(C1.size2(), C1.size(2))
    assert_eq(IR(), C1.I(1))
    assert_eq(C1.I1(), C1.I(1))
    assert_eq(IR(), C1.I(2))
    assert_eq(C1.I2(), C1.I(2))
    assert_eq(1, C1.l(1))
    assert_eq(C1.l1(), C1.l(1))
    assert_eq(1, C1.l(2))
    assert_eq(C1.l2(), C1.l(2))
    assert_eq(0, C1.u(1))
    assert_eq(C1.u1(), C1.u(1))
    assert_eq(0, C1.u(2))
    assert_eq(C1.u2(), C1.u(2))
    assert_true(C1.data() is None)
    assert_true(C1.data_beg() is None)
    assert_true(C1.data_end() is None)
    let C2 = Array2D_int(2, 3)
    assert_eq(2, C2.rank())
    assert_eq(6, C2.size())
    assert_eq(6, C2.capacity())
    assert_eq(2, C2.size(1))
    assert_eq(C2.size1(), C2.size(1))
    assert_eq(3, C2.size(2))
    assert_eq(C2.size2(), C2.size(2))
    assert_eq(IR(1,2), C2.I(1))
    assert_eq(C2.I1(), C2.I(1))
    assert_eq(IR(1,3), C2.I(2))
    assert_eq(C2.I2(), C2.I(2))
    assert_eq(1, C2.l(1))
    assert_eq(C2.l1(), C2.l(1))
    assert_eq(1, C2.l(2))
    assert_eq(C2.l2(), C2.l(2))
    assert_eq(2, C2.u(1))
    assert_eq(C2.u1(), C2.u(1))
    assert_eq(3, C2.u(2))
    assert_eq(C2.u2(), C2.u(2))
    assert_false(C2.data() is None)
    assert_false(C2.data_beg() is None)
    assert_false(C2.data_end() is None)

@(Test)
def ModifierClear():
    var A1 = Array2D_int()
    assert_eq(0, A1.size())
    assert_eq(0, A1.size1())
    assert_eq(0, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(0, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(0, A1.u2())
    A1.clear()
    assert_eq(0, A1.size())
    assert_eq(0, A1.size1())
    assert_eq(0, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(0, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(0, A1.u2())
    var A2 = Array2D_int({2,3}, {2,4})
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(2, A2.l1())
    assert_eq(3, A2.u1())
    assert_eq(2, A2.l2())
    assert_eq(4, A2.u2())
    A2.clear()
    assert_eq(0, A2.size())
    assert_eq(0, A2.size1())
    assert_eq(0, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(0, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(0, A2.u2())
    assert_true(A2.data() is None)
    assert_true(A2.data_beg() is None)
    assert_true(A2.data_end() is None)
    var A3 = Array2D_int(2, 3, 31459)
    assert_eq(6, A3.size())
    assert_eq(2, A3.size1())
    assert_eq(3, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(2, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(3, A3.u2())
    for i1 in range(A3.l1(), A3.u1()+1):
        for i2 in range(A3.l2(), A3.u2()+1):
            assert_eq(31459, A3[i1,i2])
    A3.clear()
    assert_eq(0, A3.size())
    assert_eq(0, A3.size1())
    assert_eq(0, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(0, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(0, A3.u2())

@(Test)
def ModifierAllocateDeallocate():
    var A1 = Array2D_int()
    assert_eq(0, A1.size())
    assert_eq(0, A1.size1())
    assert_eq(0, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(0, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(0, A1.u2())
    assert_false(A1.allocated())
    A1.allocate(2, 3)
    assert_eq(6, A1.size())
    assert_eq(2, A1.size1())
    assert_eq(3, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(2, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(3, A1.u2())
    assert_true(A1.allocated())
    A1.deallocate()
    assert_eq(0, A1.size())
    assert_eq(0, A1.size1())
    assert_eq(0, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(0, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(0, A1.u2())
    assert_false(allocated(A1))
    var A2 = Array2D_int(2, 3, {11,12,13,21,22,23})
    assert_eq(6, A2.size())
    assert_eq(2, A2.size1())
    assert_eq(3, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(2, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(3, A2.u2())
    assert_true(A2.allocated())
    A2.deallocate()
    assert_eq(0, A2.size())
    assert_eq(0, A2.size1())
    assert_eq(0, A2.size2())
    assert_eq(1, A2.l1())
    assert_eq(0, A2.u1())
    assert_eq(1, A2.l2())
    assert_eq(0, A2.u2())
    assert_false(allocated(A2))
    var A3 = Array2D_int()
    assert_eq(0, A3.size())
    assert_eq(0, A3.size1())
    assert_eq(0, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(0, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(0, A3.u2())
    assert_false(A3.allocated())
    A3.allocate(Array2D_int(2, 3))
    assert_eq(6, A3.size())
    assert_eq(2, A3.size1())
    assert_eq(3, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(2, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(3, A3.u2())
    assert_true(A3.allocated())
    A3.deallocate()
    assert_eq(0, A3.size())
    assert_eq(0, A3.size1())
    assert_eq(0, A3.size2())
    assert_eq(1, A3.l1())
    assert_eq(0, A3.u1())
    assert_eq(1, A3.l2())
    assert_eq(0, A3.u2())
    assert_false(allocated(A3))

@(Test)
def DimensionIndexRange():
    var A1 = Array2D_int(3, 4)
    assert_eq(12, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(4, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(3, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(4, A1.u2())
    A1.dimension({2,4}, {2,5})
    assert_eq(12, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(4, A1.size2())
    assert_eq(2, A1.l1())
    assert_eq(4, A1.u1())
    assert_eq(2, A1.l2())
    assert_eq(5, A1.u2())
    var A2 = Array2D_int(3, 4)
    A2.dimension({2,4}, {2,5}, 31459)
    assert_eq(3, A2.size1())
    assert_eq(4, A2.size2())
    assert_eq(2, A2.l1())
    assert_eq(4, A2.u1())
    assert_eq(2, A2.l2())
    assert_eq(5, A2.u2())
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            assert_eq(31459, A2[i1,i2])
    A2.dimension({2,5}, {2,5}, 42)
    assert_eq(16, A2.size())
    assert_eq(4, A2.size1())
    assert_eq(4, A2.size2())
    assert_eq(2, A2.l1())
    assert_eq(5, A2.u1())
    assert_eq(2, A2.l2())
    assert_eq(5, A2.u2())
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            assert_eq(42, A2[i1,i2])
    var A3 = Array2D_int(3, 4)
    A3.dimension({2,4}, {2,5}, dimension_initializer_function)
    assert_eq(3, A3.size1())
    assert_eq(4, A3.size2())
    assert_eq(2, A3.l1())
    assert_eq(4, A3.u1())
    assert_eq(2, A3.l2())
    assert_eq(5, A3.u2())
    for i1 in range(A3.l1(), A3.u1()+1):
        for i2 in range(A3.l2(), A3.u2()+1):
            assert_eq(i1*10 + i2, A3[i1,i2])

@(Test)
def DimensionArrays():
    var A1 = Array2D_int(3, 4)
    assert_eq(12, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(4, A1.size2())
    assert_eq(1, A1.l1())
    assert_eq(3, A1.u1())
    assert_eq(1, A1.l2())
    assert_eq(4, A1.u2())
    A1.dimension(Array2D_int({2,4}, {2,5}))
    assert_eq(12, A1.size())
    assert_eq(3, A1.size1())
    assert_eq(4, A1.size2())
    assert_eq(2, A1.l1())
    assert_eq(4, A1.u1())
    assert_eq(2, A1.l2())
    assert_eq(5, A1.u2())
    var A2 = Array2D_int(3, 4)
    A2.dimension(Array2D_int({2,4}, {2,5}), 31459)
    assert_eq(3, A2.size1())
    assert_eq(4, A2.size2())
    assert_eq(2, A2.l1())
    assert_eq(4, A2.u1())
    assert_eq(2, A2.l2())
    assert_eq(5, A2.u2())
    for i1 in range(A2.l1(), A2.u1()+1):
        for i2 in range(A2.l2(), A2.u2()+1):
            assert_eq(31459, A2[i1,i2])
    var A3 = Array2D_int(3, 4)
    A3.dimension(Array2D_int({2,4}, {2,5}), dimension_initializer_function)
    assert_eq(3, A3.size1())
    assert_eq(4, A3.size2())
    assert_eq(2, A3.l1())
    assert_eq(4, A3.u1())
    assert_eq(2, A3.l2())
    assert_eq(5, A3.u2())
    for i1 in range(A3.l1(), A3.u1()+1):
        for i2 in range(A3.l2(), A3.u2()+1):
            assert_eq(i1*10 + i2, A3[i1,i2])

@(Test)
def Swap():
    var A1 = Array2D_int(2, 3, {11,12,13,21,22,23})
    var A2 = Array2D_int()
    let A3 = Array2D_int(A1)
    assert_true(eq(A1, A3))
    assert_true(eq(Array2D_int(), A2))
    A1.swap(A2)
    assert_true(eq(A2, A3))
    assert_true(eq(Array2D_int(), A1))

@(Test)
def Diagonals():
    var A = Array2D_int(3, 3, {11,12,13,21,22,23,31,32,33})
    A.to_identity()
    assert_eq(1, A[1,1])
    assert_eq(1, A[2,2])
    assert_eq(1, A[3,3])
    assert_eq(0, A[1,2])
    assert_eq(0, A[1,3])
    assert_eq(0, A[2,1])
    assert_eq(0, A[2,3])
    assert_eq(0, A[3,1])
    assert_eq(0, A[3,2])
    A = Array2D_int({-1,1}, 3, {11,12,13,21,22,23,31,32,33})
    A.to_diag(9)
    assert_eq(9, A[-1,1])
    assert_eq(9, A[0,2])
    assert_eq(9, A[1,3])
    assert_eq(0, A[0,1])
    assert_eq(0, A[1,1])
    assert_eq(0, A[-1,2])
    assert_eq(0, A[1,2])
    assert_eq(0, A[-1,3])
    assert_eq(0, A[0,3])

@(Test)
def Transpose():
    var A = Array2D_int(2, {-1,0}, {11,12,21,22})
    let C = Array2D_int(A)
    A.transpose()
    assert_eq(C[1,-1], A[1,-1])
    assert_eq(C[1,0], A[2,-1])
    assert_eq(C[2,-1], A[1,0])
    assert_eq(C[2,0], A[2,0])
    A = Array2D_int(2, 3)
    A[1,1] = 4
    A[1,2] = 3
    A[1,3] = 5
    A[2,1] = 9
    A[2,2] = 2
    A[2,3] = 8
    var B = transpose(A)
    assert_eq(1, B.l1())
    assert_eq(3, B.u1())
    assert_eq(1, B.l2())
    assert_eq(2, B.u2())
    assert_eq(3, B.size1())
    assert_eq(2, B.size2())
    assert_eq(A[1,1], B[1,1])
    assert_eq(A[1,2], B[2,1])
    assert_eq(A[1,3], B[3,1])
    assert_eq(A[2,1], B[1,2])
    assert_eq(A[2,2], B[2,2])
    assert_eq(A[2,3], B[3,2])
    A = Array2D_int(2, {-1,1})
    A[1,-1] = 4
    A[1,0] = 3
    A[1,1] = 5
    A[2,-1] = 9
    A[2,0] = 2
    A[2,1] = 8
    B = transpose(A)
    assert_eq(1, B.l1()); assert_eq(3, B.u1())
    assert_eq(1, B.l2()); assert_eq(2, B.u2())
    assert_eq(3, B.size1()); assert_eq(2, B.size2())
    assert_eq(A[1,-1], B[1,1])
    assert_eq(A[1,0], B[2,1])
    assert_eq(A[1,1], B[3,1])
    assert_eq(A[2,-1], B[1,2])
    assert_eq(A[2,0], B[2,2])
    assert_eq(A[2,1], B[3,2])
    A = Array2D_int(2, {-1,1})
    A[1,-1]=4; A[1,0]=3; A[1,1]=5; A[2,-1]=9; A[2,0]=2; A[2,1]=8
    B = transposed(A)
    assert_eq(-1, B.l1()); assert_eq(1, B.u1())
    assert_eq(1, B.l2()); assert_eq(2, B.u2())
    assert_eq(3, B.size1()); assert_eq(2, B.size2())
    assert_eq(A[1,-1], B[-1,1])
    assert_eq(A[1,0], B[0,1])
    assert_eq(A[1,1], B[1,1])
    assert_eq(A[2,-1], B[-1,2])
    assert_eq(A[2,0], B[0,2])
    assert_eq(A[2,1], B[1,2])

@(Test)
def FunctionNegation():
    let A = Array2D_bool(3, 1, {True, False, True})
    let E = Array2D_bool(3, 1, {False, True, False})
    assert_true(eq(E, not A))

@(Test)
def FunctionPow():
    var A = Array2D_int(2, 2, {5, -3, 7, -4})
    let E = Array2D_int(2, 2, {25, 9, 49, 16})
    assert_true(eq(E, pow(A, 2)))

@(Test)
def FunctionSign():
    {
        var A = Array2D_int(2, 2, {11, -12, 21, -22})
        let AP = Array2D_int(2, 2, {11, 12, 21, 22})
        let AN = Array2D_int(2, 2, {-11, -12, -21, -22})
        assert_true(eq(AP, sign(A, 1)))
        assert_true(eq(AP, sign(A, 0)))
        assert_true(eq(AN, sign(A, -1)))
    }
    {
        var A = Array2D_int(2, 2, {11, -12, 21, -22})
        let A1 = Array2D_int(2, 2, {1, -1, 1, -1})
        let A0 = Array2D_int(2, 2, {0, -0, 0, -0})
        assert_true(eq(A1, sign(1, A)))
        assert_true(eq(A0, sign(0, A)))
        assert_true(eq(A1, sign(-1, A)))
    }

@(Test)
def FunctionCount():
    var A = Array2D_bool(2, 3, {True, False, False, False, True, True})
    let C1 = Array1D[Int](3, {1, 1, 1})
    let C2 = Array1D[Int](2, {1, 2})
    assert_eq(3, count(A))
    assert_true(eq(C1, count(A, 1)))
    assert_true(eq(C2, count(A, 2)))

@(Test)
def FunctionSum():
    var A = Array2D_int(2, 2, {11, 12, 21, 22})
    let S1 = Array1D[Int](2, {32, 34})
    let S2 = Array1D[Int](2, {23, 43})
    assert_eq(66, sum(A))
    assert_true(eq(S1, sum(A, 1)))
    assert_true(eq(S2, sum(A, 2)))