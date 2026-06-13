from Index import Index
from Omit import Omit
from memory import sizeof
from sys import int_type
from utils import StringRef, String
from io import FileHandle, FileReader, FileWriter

@value
struct IndexSlice:
    # Types
    type size_type = UInt
    type Size = UInt

    # Creation
    def __init__(inout self):
        self.l_init_ = False
        self.u_init_ = False
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = 1
        self.size_ = 0

    def __init__(inout self, other: IndexSlice):
        self.l_init_ = other.l_init_
        self.u_init_ = other.u_init_
        self.scalar_ = other.scalar_
        self.l_ = other.l_
        self.u_ = other.u_
        self.s_ = other.s_
        self.size_ = other.size_
        assert self.size_ == self.computed_size()

    def __init__(inout self, i: Int):
        self.l_init_ = True
        self.u_init_ = True
        self.scalar_ = True
        self.l_ = i
        self.u_ = i
        self.s_ = 1
        self.size_ = 1

    def __init__(inout self, l: Int, u: Int, s: Int = 1):
        self.l_init_ = True
        self.u_init_ = True
        self.scalar_ = False
        self.l_ = l
        self.u_ = u
        self.s_ = s
        self.size_ = self.computed_size()
        assert self.s_ != 0

    def __init__(inout self, lus: List[Int]):
        n = len(lus)
        assert n <= 3
        self.l_init_ = n > 0
        self.u_init_ = n > 1
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = 1
        self.size_ = 0
        if n == 0:
            self.l_ = 1
            self.u_ = 0
            self.s_ = 1
        elif n == 1:
            self.l_ = lus[0]
            self.u_ = 0
            self.s_ = 1
        elif n == 2:
            self.l_ = lus[0]
            self.u_ = lus[1]
            self.s_ = 1
        elif n == 3:
            self.l_ = lus[0]
            self.u_ = lus[1]
            self.s_ = lus[2]
        assert self.s_ != 0
        self.size_ = self.computed_size()

    def __init__(inout self, lus: List[Index]):
        n = len(lus)
        assert n <= 3
        self.l_init_ = (n > 0) and lus[0].initialized()
        self.u_init_ = (n > 1) and lus[1].initialized()
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = 1
        self.size_ = 0
        if n == 0:
            self.l_ = 1
            self.u_ = 0
            self.s_ = 1
        elif n == 1:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = 0
            self.s_ = 1
        elif n == 2:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = lus[1].initialized() ? Int(lus[1]) : 0
            self.s_ = 1
        elif n == 3:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = lus[1].initialized() ? Int(lus[1]) : 0
            self.s_ = lus[2].initialized() ? Int(lus[2]) : 1
        assert self.s_ != 0
        self.size_ = self.computed_size()

    def __init__(inout self, omit: Omit):
        self.l_init_ = False
        self.u_init_ = False
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = 1
        self.size_ = 0
        assert self.s_ != 0

    def __init__(inout self, l: Int, omit: Omit, s: Int = 1):
        self.l_init_ = True
        self.u_init_ = False
        self.scalar_ = False
        self.l_ = l
        self.u_ = 0
        self.s_ = s
        self.size_ = 0
        assert self.s_ != 0

    def __init__(inout self, omit: Omit, u: Int, s: Int = 1):
        self.l_init_ = False
        self.u_init_ = True
        self.scalar_ = False
        self.l_ = 1
        self.u_ = u
        self.s_ = s
        self.size_ = 0
        assert self.s_ != 0

    def __init__(inout self, omit1: Omit, omit2: Omit, s: Int = 1):
        self.l_init_ = False
        self.u_init_ = False
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = s
        self.size_ = 0
        assert self.s_ != 0

    def __del__(owned self):

    # Assignment
    def __setitem__(inout self, i: Int):
        self.l_init_ = True
        self.u_init_ = True
        self.scalar_ = True
        self.l_ = i
        self.u_ = i
        self.s_ = 1
        self.size_ = 1

    def __setitem__(inout self, lus: List[Int]):
        n = len(lus)
        assert n <= 3
        self.l_init_ = n > 0
        self.u_init_ = n > 1
        self.scalar_ = False
        if n == 0:
            self.l_ = 1
            self.u_ = 0
            self.s_ = 1
        elif n == 1:
            self.l_ = lus[0]
            self.u_ = 0
            self.s_ = 1
        elif n == 2:
            self.l_ = lus[0]
            self.u_ = lus[1]
            self.s_ = 1
        elif n == 3:
            self.l_ = lus[0]
            self.u_ = lus[1]
            self.s_ = lus[2]
        assert self.s_ != 0
        self.size_ = self.computed_size()

    def __setitem__(inout self, lus: List[Index]):
        n = len(lus)
        assert n <= 3
        self.l_init_ = (n > 0) and lus[0].initialized()
        self.u_init_ = (n > 1) and lus[1].initialized()
        self.scalar_ = False
        if n == 0:
            self.l_ = 1
            self.u_ = 0
            self.s_ = 1
        elif n == 1:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = 0
            self.s_ = 1
        elif n == 2:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = lus[1].initialized() ? Int(lus[1]) : 0
            self.s_ = 1
        elif n == 3:
            self.l_ = lus[0].initialized() ? Int(lus[0]) : 1
            self.u_ = lus[1].initialized() ? Int(lus[1]) : 0
            self.s_ = lus[2].initialized() ? Int(lus[2]) : 1
        assert self.s_ != 0
        self.size_ = self.computed_size()

    def assign(inout self, l: Int, u: Int, s: Int = 1) -> Self:
        self.l_init_ = True
        self.u_init_ = True
        self.scalar_ = False
        self.l_ = l
        self.u_ = u
        self.s_ = s
        self.size_ = self.computed_size()
        return self

    # Subscript
    def __getitem__(self, i: Int) -> Int:
        assert self.l_init_
        return self.l_ if self.scalar_ else self.l_ + (i - 1) * self.s_ # Doesn't check that i <= size of slice

    # Predicate
    def initialized(self) -> Bool:
        return self.l_init_ and self.u_init_

    def l_initialized(self) -> Bool:
        return self.l_init_

    def u_initialized(self) -> Bool:
        return self.u_init_

    def scalar(self) -> Bool:
        return self.scalar_

    def contains(self, i: Int) -> Bool:
        assert self.l_init_ and self.u_init_
        return (i == self.l_) if self.scalar_ else ((min(self.l_, self.u_) <= i) and (i <= max(self.l_, self.u_)) and (((i - self.l_) % self.s_) == 0))

    # Inspector
    def l(self) -> Int:
        assert self.l_initialized()
        return self.l_

    def u(self) -> Int:
        assert self.u_initialized()
        return self.u_

    def s(self) -> Int:
        return self.s_

    def size(self) -> size_type:
        return self.size_

    def isize(self) -> Int:
        return Int(self.size_)

    def last(self) -> Int:
        assert self.initialized()
        assert self.s_ != 0
        return self.l_ + (self.s_ * (Int(self.size_ - 1) if self.size_ > 0 else 0)) # Get l_ if size==0

    def next(self, i: Int) -> Int:
        assert self.l_init_
        assert self.contains(i)
        return self.l_ if self.scalar_ else i + self.s_ # Doesn't check that this is a valid index

    def min(self) -> Int:
        assert self.initialized()
        return min(self.l_, self.last())

    def max(self) -> Int:
        assert self.initialized()
        return max(self.l_, self.last())

    def empty(self) -> Bool:
        return self.size_ == 0

    def non_empty(self) -> Bool:
        return self.size_ > 0

    # Modifier
    def clear(inout self):
        self.l_init_ = False
        self.u_init_ = False
        self.scalar_ = False
        self.l_ = 1
        self.u_ = 0
        self.s_ = 1
        self.size_ = 0

    def i(inout self, i: Int) -> Self:
        self.l_init_ = True
        self.u_init_ = True
        self.scalar_ = True
        self.l_ = i
        self.u_ = i
        self.s_ = 1
        self.size_ = 1
        return self

    def l(inout self, l: Int) -> Self:
        self.l_init_ = True
        self.scalar_ = False
        self.l_ = l
        self.size_ = self.computed_size()
        return self

    def u(inout self, u: Int) -> Self:
        self.u_init_ = True
        self.scalar_ = False
        self.u_ = u
        self.size_ = self.computed_size()
        return self

    def lud(inout self, l: Int, u: Int):
        if not self.l_init_:
            self.l_ = l
            self.l_init_ = True
        if (not self.u_init_) and (l - 1 <= u):
            self.u_ = u
            self.u_init_ = True
        self.scalar_ = False
        self.size_ = self.computed_size()

    def swap(inout self, other: IndexSlice):
        if self != other:
            self.l_init_, other.l_init_ = other.l_init_, self.l_init_
            self.u_init_, other.u_init_ = other.u_init_, self.u_init_
            self.scalar_, other.scalar_ = other.scalar_, self.scalar_
            self.l_, other.l_ = other.l_, self.l_
            self.u_, other.u_ = other.u_, self.u_
            self.s_, other.s_ = other.s_, self.s_
            self.size_, other.size_ = other.size_, self.size_

    # Comparison
    def __eq__(self, other: IndexSlice) -> Bool:
        return (self.l_init_ == other.l_init_) and (self.u_init_ == other.u_init_) and (self.scalar_ == other.scalar_) and (self.l_ == other.l_) and (self.u_ == other.u_) and (self.s_ == other.s_)

    def __ne__(self, other: IndexSlice) -> Bool:
        return not (self == other)

    # I/O
    def __str__(self) -> String:
        var result = String()
        if self.s_ == 1:
            if self.initialized():
                result = "[" + str(self.l_) + ":" + str(self.u_) + "]"
            elif self.l_initialized():
                result = "[" + str(self.l_) + ":]"
            elif self.u_initialized():
                result = "[:" + str(self.u_) + "]"
            else:
                result = "[:]"
        else:
            if self.initialized():
                result = "[" + str(self.l_) + ":" + str(self.u_) + ":" + str(self.s_) + "]"
            elif self.l_initialized():
                result = "[" + str(self.l_) + "::" + str(self.s_) + "]"
            elif self.u_initialized():
                result = "[:" + str(self.u_) + ":" + str(self.s_) + "]"
            else:
                result = "[::" + str(self.s_) + "]"
        return result

    # Private
    def computed_size(self) -> size_type:
        assert self.s_ != 0 or not self.l_init_ or not self.u_init_
        return max((self.u_ - self.l_ + self.s_) // self.s_, 0) if (self.l_init_ and self.u_init_) else 0

    # Data
    var l_init_: Bool
    var u_init_: Bool
    var scalar_: Bool
    var l_: Int
    var u_: Int
    var s_: Int
    var size_: size_type

# Free functions
def swap(inout a: IndexSlice, inout b: IndexSlice):
    a.swap(b)

def operator==(I: IndexSlice, J: IndexSlice) -> Bool:
    return I == J

def operator!=(I: IndexSlice, J: IndexSlice) -> Bool:
    return I != J

def operator>>(stream: FileReader, inout I: IndexSlice) -> FileReader:
    var l: Int
    var u: Int
    var s: Int
    stream >> l >> u >> s
    I.assign(l, u, s)
    return stream

def operator<<(stream: FileWriter, I: IndexSlice) -> FileWriter:
    if I.s_ == 1:
        if I.initialized():
            stream << '[' << I.l_ << ':' << I.u_ << ']'
        elif I.l_initialized():
            stream << '[' << I.l_ << ":]"
        elif I.u_initialized():
            stream << "[:" << I.u_ << ']'
        else:
            stream << "[:]"
    else:
        if I.initialized():
            stream << '[' << I.l_ << ':' << I.u_ << ':' << I.s_ << ']'
        elif I.l_initialized():
            stream << '[' << I.l_ << "::" << I.s_ << ']'
        elif I.u_initialized():
            stream << "[:" << I.u_ << ':' << I.s_ << ']'
        else:
            stream << "[::" << I.s_ << ']'
    return stream

alias ISlice = IndexSlice