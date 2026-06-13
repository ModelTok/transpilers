// Mojo translation of C++ file third_party/ObjexxFCL/src/ObjexxFCL/IndexRange.cc
// Includes class definition from IndexRange.hh (faithful 1:1 translation)
from Index import Index
from Omit import Omit
from builtins import assert, max, min, swap
from sys import IO  # for stream types (approximation)

@value
struct IndexRange:
    # Type aliases
    typealias size_type = UInt  # size_t
    typealias Size = UInt

    # Data members
    var l_: Int
    var u_: Int
    var size_: size_type

    # Static data
    @static
    var npos: size_type = (UInt(-1))
    @static
    var l_min: Int = -(((UInt(-1) // 2) as Int) - 1)
    @static
    var u_max: Int = (UInt(-1) // 2) as Int

    # --- Creation ---
    def __init__(inout self):
        self.l_ = 1
        self.u_ = 0
        self.size_ = 0u

    def __init__(inout self, I: Self):
        self.l_ = I.l_
        self.u_ = I.u_
        self.size_ = I.size_

    def __init__(inout self, u: Int):
        self.l_ = 1
        self.u_ = clean_u(u, self.l_)
        self.size_ = self.u_
        assert(self.legal())

    def __init__(inout self, l: Int, u: Int):
        self.l_ = l
        self.u_ = clean_u(u, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())

    # Initializer list constructors (approximated with variadic)
    def __init__(inout self, *lu: Int):
        self.l_ = 1
        self.u_ = 0
        self.size_ = 0u
        var n: Int = len(lu)
        assert(n <= 2)
        if n == 0:
            self.l_ = 1
            self.u_ = 0
        elif n == 1:
            self.l_ = Int(lu[0])
            self.u_ = self.l_ - 2  # Unbounded
        else:  # n == 2
            self.l_ = Int(lu[0])
            self.u_ = clean_u(Int(lu[1]), self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())

    def __init__(inout self, *lu: Index):
        self.l_ = 1
        self.u_ = 0
        self.size_ = 0u
        var n: Int = len(lu)
        assert(n <= 2)
        if n == 0:
            self.l_ = 1
            self.u_ = 0
        elif n == 1:
            self.l_ = Int(lu[0]) if lu[0].initialized() else 1
            self.u_ = self.l_ - 2  # Unbounded
        else:  # n == 2
            self.l_ = Int(lu[0]) if lu[0].initialized() else 1
            var u_val: Int = Int(lu[1]) if lu[1].initialized() else (self.l_ - 2)
            self.u_ = clean_u(u_val, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())

    def __init__(inout self, _: Omit):
        self.l_ = 1
        self.u_ = -1
        self.size_ = npos

    def __init__(inout self, l: Int, _: Omit):
        self.l_ = l
        self.u_ = self.l_ - 2
        self.size_ = npos

    def __init__(inout self, _: Omit, u: Int):
        self.l_ = u + 2
        self.u_ = u
        self.size_ = npos
        assert(self.legal())

    def __init__(inout self, _1: Omit, _2: Omit):
        self.l_ = 1
        self.u_ = -1
        self.size_ = npos

    # --- Assignment (mapped to methods due to Mojo limitations) ---
    def assign(inout self, I: Self) -> Self:
        if self != I:  # note: uses object identity; use pointer comparison
            self.l_ = I.l_
            self.u_ = I.u_
            self.size_ = I.size_
        assert(self.legal())
        return self

    def assign(inout self, u: Int) -> Self:
        self.l_ = 1
        self.u_ = clean_u(u, self.l_)
        self.size_ = self.u_
        assert(self.legal())
        return self

    def assign(inout self, l: Int, u: Int) -> Self:
        self.l_ = l
        self.u_ = clean_u(u, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())
        return self

    # Initializer list assignment (approximated)
    def assign(inout self, *lu: Int) -> Self:
        var n: Int = len(lu)
        assert(n <= 2)
        if n == 0:
            self.l_ = 1
            self.u_ = 0
        elif n == 1:
            self.l_ = Int(lu[0])
            self.u_ = self.l_ - 2
        else:  # n == 2
            self.l_ = Int(lu[0])
            self.u_ = clean_u(Int(lu[1]), self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())
        return self

    def assign(inout self, *lu: Index) -> Self:
        var n: Int = len(lu)
        assert(n <= 2)
        if n == 0:
            self.l_ = 1
            self.u_ = 0
        elif n == 1:
            self.l_ = Int(lu[0]) if lu[0].initialized() else 1
            self.u_ = self.l_ - 2
        else:  # n == 2
            self.l_ = Int(lu[0]) if lu[0].initialized() else 1
            var u_val: Int = Int(lu[1]) if lu[1].initialized() else (self.l_ - 2)
            self.u_ = clean_u(u_val, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        assert(self.legal())
        return self

    # --- Subscript ---
    def __call__(self, i: Int) -> Int:  # 1-based indexing
        return self.l_ + (i - 1)

    def __getitem__(self, i: Int) -> Int:  # 0-based indexing
        return self.l_ + i

    # --- Predicate ---
    def legal(self) -> Bool:
        return (self.l_ >= l_min) and (self.u_ <= u_max) and (self.l_ - 2 <= self.u_)

    def bounded(self) -> Bool:
        return (self.l_ - 1 <= self.u_)

    def unbounded(self) -> Bool:
        return (self.l_ - 2 == self.u_)

    def empty(self) -> Bool:
        return (self.l_ - 1 == self.u_)

    def non_empty(self) -> Bool:
        return (self.l_ <= self.u_)

    def positive(self) -> Bool:
        return (self.l_ <= self.u_)

    def contains(self, i: Int) -> Bool:
        return (self.l_ <= i) and ((i <= self.u_) or (self.size_ == npos))

    def contains(self, i: Int, j: Int) -> Bool:
        return self.contains(i) and self.contains(j)

    def contains(self, I: Self) -> Bool

    def intersects(self, I: Self) -> Bool

    # --- Inspector ---
    def l(self) -> Int:
        return self.l_

    def u(self) -> Int:
        return self.u_

    def size(self) -> size_type:
        return self.size_  # Unbounded => npos

    def isize(self) -> Int:
        assert(self.size_ != npos)
        return self.size_ as Int

    def offset(self, i: Int) -> Int:
        return (i - self.l_)

    def last(self) -> Int:
        return max(self.l_, self.u_)

    def next(self, i: Int) -> Int:
        return i + 1

    # --- Modifier ---
    def l(inout self, l: Int) -> Self:
        if self.l_ - 2 == self.u_:  # Unbounded range
            self.l_ = l
            self.u_ = self.l_ - 2
        else:  # Bounded
            self.l_ = l
            self.size_ = computed_size(self.l_, self.u_)
            self.clean()
        return self

    def u(inout self, u: Int) -> Self:
        self.u_ = clean_u(u, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        return self

    def grow(inout self, n: Int = 1) -> Self:
        assert(n >= 0)
        assert(self.u_ <= u_max - n)
        assert(self.u_ >= self.l_ - 1)
        self.u_ += n
        self.size_ = computed_size(self.l_, self.u_)
        return self

    def shrink(inout self, n: Int = 1) -> Self:
        assert(n >= 0)
        assert(self.u_ >= self.l_ - 1)
        self.u_ = clean_u(self.u_ - n, self.l_)
        self.size_ = computed_size(self.l_, self.u_)
        return self

    def contain(inout self, i: Int) -> Self:
        if self.l_ - 1 <= self.u_:  # Bounded
            if self.l_ > i:
                self.l_ = i
            if self.u_ < i:
                self.u_ = i
            self.size_ = computed_size(self.l_, self.u_)
        else:  # Unbounded
            if self.l_ > i:
                self.l_ = i
                self.u_ = self.l_ - 2
        assert(self.legal())
        return self

    def contain(inout self, I: Self) -> Self

    def intersect(inout self, I: Self) -> Self

    def clear(inout self) -> Self:
        self.l_ = 1
        self.u_ = 0
        self.size_ = 0u
        return self

    def clean(inout self) -> Self:
        if self.l_ > self.u_:
            self.l_ = 1
            self.u_ = 0
            self.size_ = 0u
        return self

    def swap(inout self, I: inout Self) -> Self:
        if self != I:
            self.l_, I.l_ = I.l_, self.l_
            self.u_, I.u_ = I.u_, self.u_
            self.size_, I.size_ = I.size_, self.size_
        return self

    # --- Private static helpers ---
    @staticmethod
    def computed_size(l: Int, u: Int) -> size_type:
        return max(u - l + 1, -1) as size_type

    @staticmethod
    def clean_u(u: Int, l: Int) -> Int:
        return max(u, l - 1)

# --- Free functions (from .cc) ---

def IndexRange.contains(self: IndexRange, I: IndexRange) -> Bool:
    if self.l_ <= self.u_:  # Bounded with positive size
        if I.l_ <= I.u_:  # I is bounded with positive size
            return (self.l_ <= I.l_) and (I.u_ <= self.u_)
        elif I.l_ - 1 == I.u_:  # I size is zero
            return true
        else:  # I is unbounded
            return false
    elif self.l_ - 1 == self.u_:  # Zero size
        return (I.l_ - 1 == I.u_)
    else:  # Unbounded
        return (self.l_ <= I.l_)

def IndexRange.intersects(self: IndexRange, I: IndexRange) -> Bool:
    if self.l_ <= self.u_:  # Bounded with positive size
        if I.l_ <= I.u_:  # I is bounded with positive size
            var lhs: Int = self.l_ if self.l_ >= I.l_ else I.l_
            var rhs: Int = self.u_ if self.u_ <= I.u_ else I.u_
            return lhs <= rhs
        elif I.l_ - 1 == I.u_:  # I size is zero
            return false
        else:  # I is unbounded
            return I.l_ <= self.u_
    elif self.l_ - 1 == self.u_:  # Zero size
        return false
    else:  # Unbounded
        if I.l_ <= I.u_:  # I is bounded with positive size
            return self.l_ <= I.u_
        elif I.l_ - 1 == I.u_:  # I size is zero
            return false
        else:  # I is unbounded
            return true

def IndexRange.contain(inout self: IndexRange, I: IndexRange) -> Self:
    if I.positive():
        if self.bounded():  # Bounded
            if self.l_ > I.l_:
                self.l_ = I.l_
            if I.bounded():  # I bounded
                if self.u_ < I.u_:
                    self.u_ = I.u_
                self.size_ = self.u_ - self.l_ + 1
            else:  # I unbounded
                self.u_ = self.l_ - 2
                self.size_ = IndexRange.npos
        else:  # Unbounded
            if self.l_ > I.l_:
                self.l_ = I.l_
                self.u_ = self.l_ - 2
    assert(self.legal())
    return self

def IndexRange.intersect(inout self: IndexRange, I: IndexRange) -> Self:
    if self.intersects(I):  # I and this have positive size
        if self.l_ <= self.u_:  # Bounded with positive size
            if self.l_ < I.l_:
                self.l_ = I.l_
            if (I.l_ <= I.u_) and (self.u_ > I.u_):
                self.u_ = I.u_
            self.size_ = self.u_ - self.l_ + 1
        else:  # Unbounded
            if self.l_ < I.l_:
                self.l_ = I.l_
            if I.l_ <= I.u_:  # I is bounded with positive size
                self.u_ = I.u_
                self.size_ = self.u_ - self.l_ + 1
            else:  # Reset to unbounded
                self.u_ = self.l_ - 2
    else:  # Empty intersection
        self.l_ = 1
        self.u_ = 0
        self.size_ = 0u
    assert(self.legal())
    return self

def operator>>(stream: IO, I: inout IndexRange) -> IO:  # approximate signature
    var l: Int, u: Int
    # stream >> l >> u; assume stream has read method
    stream >> l
    stream >> u
    I.assign(l, u)
    return stream

def operator<<(stream: IO, I: IndexRange) -> IO:  # approximate signature
    if I.bounded():
        stream << '[' << I.l() << ':' << I.u() << ']'
    else:
        stream << '[' << I.l() << ":*]"
    return stream