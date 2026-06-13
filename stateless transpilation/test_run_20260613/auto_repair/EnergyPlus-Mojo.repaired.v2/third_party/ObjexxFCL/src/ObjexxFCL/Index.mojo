from builtin import atoi, print, String, Bool, Int, assert

struct Index:
    var init_: Bool
    var i_: Int

    def __init__(inout self):
        self.init_ = False
        self.i_ = 0

    def __init__(inout self, other: Index):
        self.init_ = other.init_
        self.i_ = other.i_

    def __init__(inout self, i: Int):
        self.init_ = True
        self.i_ = i

    def __del__(inout self):

    def __copyinit__(inout self, other: Index):
        self.init_ = other.init_
        self.i_ = other.i_

    def __moveinit__(inout self, owned other: Index):
        self.init_ = other.init_
        self.i_ = other.i_

    def __assign__(inout self, other: Self) -> Self:
        fatal("Index assignment from Index not defined")
        return self

    def __assign__(inout self, i: Int) -> Self:
        self.init_ = True
        self.i_ = i
        return self

    def __int__(self) -> Int:
        assert(self.init_)
        return self.i_

    def initialized(self) -> Bool:
        return self.init_

    def i(self) -> Int:
        assert(self.init_)
        return self.i_

    def clear(inout self):
        self.init_ = False
        self.i_ = 0

    def i(inout self, i: Int) -> Self:
        self.init_ = True
        self.i_ = i
        return self

    def swap(inout self, inout other: Index):
        var tmp_init = self.init_
        var tmp_i = self.i_
        self.init_ = other.init_
        self.i_ = other.i_
        other.init_ = tmp_init
        other.i_ = tmp_i

def swap(inout a: Index, inout b: Index):
    a.swap(b)

def operator ==(a: Index, b: Index) -> Bool:
    return (a.initialized() and b.initialized()) ? (a.i() == b.i()) : not (a.initialized() or b.initialized())

def operator !=(a: Index, b: Index) -> Bool:
    return not (a == b)

def operator ==(a: Index, b: Int) -> Bool:
    return (a.initialized() and (a.i() == b))

def operator !=(a: Index, b: Int) -> Bool:
    return not (a == b)

def operator ==(a: Int, b: Index) -> Bool:
    return (b.initialized() and (a == b.i()))

def operator !=(a: Int, b: Index) -> Bool:
    return not (a == b)

# Stream operators – translated from C++ using String for simplicity.
# The original istream / ostream are not directly available in Mojo;
# these implementations parse from / format to a String.
def operator>>(inout stream: String, inout a: Index):
    var i: Int = atoi(stream)
    a.i(i)
    # stream consumption not implemented (original would advance stream)

def operator<<(stream: String, a: Index) -> String:
    if a.initialized():
        return stream + "[" + String(a.i()) + "]"
    else:
        return stream + "[]"