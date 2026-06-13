from memory import memset, memcpy, memmove
from os import strcmp, strlen, strcat, strcpy
from sys import Int
from utils import StringRef, String

struct Cstring:
    typealias size_type = Int
    typealias Size = Int

    var str_: Pointer[UInt8]

    def __init__(inout self):
        self.str_ = Pointer[UInt8].alloc(1)
        self.str_[0] = 0

    def __init__(inout self, s: Cstring):
        let len = strlen(s.str_) + 1
        self.str_ = Pointer[UInt8].alloc(len)
        memcpy(self.str_, s.str_, len)

    def __init__(inout self, s: Cstring, owned):
        self.str_ = s.str_
        s.str_ = Pointer[UInt8]()  # None

    def __init__(inout self, s: StringRef):
        let len = strlen(s) + 1
        self.str_ = Pointer[UInt8].alloc(len)
        memcpy(self.str_, s, len)

    def __init__(inout self, s: String):
        let len = s.length() + 1
        self.str_ = Pointer[UInt8].alloc(len)
        s.copy(self.str_, len - 1)
        self.str_[len - 1] = 0

    def __init__(inout self, s: Cstring, len: size_type):
        self.str_ = Pointer[UInt8].alloc(len + 1)
        assert(len <= s.length())
        memcpy(self.str_, s.str_, len)
        self.str_[len] = 0

    def __init__(inout self, s: StringRef, len: size_type):
        self.str_ = Pointer[UInt8].alloc(len + 1)
        assert(len <= strlen(s))
        memcpy(self.str_, s, len)
        self.str_[len] = 0

    def __init__(inout self, s: String, len: size_type):
        self.str_ = Pointer[UInt8].alloc(len + 1)
        assert(len <= s.length())
        s.copy(self.str_, len)
        self.str_[len] = 0

    def __init__(inout self, c: UInt8):
        self.str_ = Pointer[UInt8].alloc(2)
        self.str_[0] = c
        self.str_[1] = 0

    def __init__(inout self, len: size_type):
        self.str_ = Pointer[UInt8].alloc(len + 1)
        memset(self.str_, 32, len)
        self.str_[len] = 0

    def __init__(inout self, len: Int):
        self.str_ = Pointer[UInt8].alloc(len + 1)
        memset(self.str_, 32, len)
        self.str_[len] = 0

    def __del__(owned self):
        if self.str_:
            self.str_.free()

    def __getitem__(self, i: size_type) -> UInt8:
        assert(i < strlen(self.str_))
        return self.str_[i]

    def __setitem__(inout self, i: size_type, val: UInt8):
        assert(i < strlen(self.str_))
        self.str_[i] = val

    def __getitem__(self, i: Int) -> UInt8:
        assert(i >= 0)
        assert(Int(i) < strlen(self.str_))
        return self.str_[i]

    def __setitem__(inout self, i: Int, val: UInt8):
        assert(i >= 0)
        assert(Int(i) < strlen(self.str_))
        self.str_[i] = val

    def __eq__(self, other: Cstring) -> Bool:
        return strcmp(self.str_, other.str_) == 0

    def __ne__(self, other: Cstring) -> Bool:
        return strcmp(self.str_, other.str_) != 0

    def __eq__(self, other: StringRef) -> Bool:
        return strcmp(self.str_, other) == 0

    def __ne__(self, other: StringRef) -> Bool:
        return strcmp(self.str_, other) != 0

    def __eq__(self, other: String) -> Bool:
        return self.str_ == other

    def __ne__(self, other: String) -> Bool:
        return self.str_ != other

    def __eq__(self, c: UInt8) -> Bool:
        return (self.length() == 1) and (self.str_[0] == c)

    def __ne__(self, c: UInt8) -> Bool:
        return (self.length() != 1) or (self.str_[0] != c)

    def __add__(self, other: Cstring) -> Cstring:
        let s_len = self.length()
        let t_len = other.length()
        var u = Cstring(s_len + t_len)
        memcpy(u.str_, self.str_, s_len)
        memcpy(u.str_ + s_len, other.str_, t_len + 1)
        return u

    def __add__(self, other: StringRef) -> Cstring:
        let s_len = self.length()
        let t_len = strlen(other)
        var u = Cstring(s_len + t_len)
        memcpy(u.str_, self.str_, s_len)
        memcpy(u.str_ + s_len, other, t_len + 1)
        return u

    def __add__(self, other: String) -> Cstring:
        let s_len = self.length()
        let t_len = other.length()
        var u = Cstring(s_len + t_len)
        memcpy(u.str_, self.str_, s_len)
        other.copy(u.str_ + s_len, t_len)
        return u

    def __add__(self, c: UInt8) -> Cstring:
        let s_len = self.length()
        var u = Cstring(s_len + 1)
        memcpy(u.str_, self.str_, s_len)
        u.str_[s_len] = c
        return u

    def __iadd__(inout self, other: Cstring):
        var tmp = self + other
        self.swap(tmp)

    def __iadd__(inout self, other: StringRef):
        var tmp = self + other
        self.swap(tmp)

    def __iadd__(inout self, other: String):
        var tmp = self + other
        self.swap(tmp)

    def __iadd__(inout self, c: UInt8):
        var tmp = self + c
        self.swap(tmp)

    def __copyinit__(inout self, other: Cstring):
        let len = strlen(other.str_) + 1
        self.str_ = Pointer[UInt8].alloc(len)
        memcpy(self.str_, other.str_, len)

    def __moveinit__(inout self, owned other: Cstring):
        self.str_ = other.str_
        other.str_ = Pointer[UInt8]()

    def __assign__(inout self, other: Cstring):
        if self.str_ != other.str_:
            let len = other.length() + 1
            self.str_.free()
            self.str_ = Pointer[UInt8].alloc(len)
            memcpy(self.str_, other.str_, len)

    def __assign__(inout self, other: StringRef):
        let len = strlen(other) + 1
        self.str_.free()
        self.str_ = Pointer[UInt8].alloc(len)
        memmove(self.str_, other, len)

    def __assign__(inout self, other: String):
        let len = other.length()
        self.str_.free()
        self.str_ = Pointer[UInt8].alloc(len + 1)
        other.copy(self.str_, len)
        self.str_[len] = 0

    def __assign__(inout self, c: UInt8):
        self.str_.free()
        self.str_ = Pointer[UInt8].alloc(2)
        self.str_[0] = c
        self.str_[1] = 0

    def empty(self) -> Bool:
        return strlen(self.str_) == 0

    def is_blank(self) -> Bool:
        return self.len_trim() == 0

    def not_blank(self) -> Bool:
        return self.len_trim() != 0

    def has(self, c: UInt8) -> Bool:
        for i in range(strlen(self.str_)):
            if self.str_[i] == c:
                return True
        return False

    def length(self) -> size_type:
        return strlen(self.str_)

    def len(self) -> size_type:
        return strlen(self.str_)

    def size(self) -> size_type:
        return strlen(self.str_)

    def len_trim(self) -> size_type:
        for i in range(strlen(self.str_), 0, -1):
            if self.str_[i - 1] != 32:
                return i
        return 0

    def find(self, c: UInt8) -> size_type:
        for i in range(strlen(self.str_)):
            if self.str_[i] == c:
                return i
        return npos

    def find_last(self, c: UInt8) -> size_type:
        for i in range(strlen(self.str_), 0, -1):
            if self.str_[i - 1] == c:
                return i
        return npos

    def lowercase(inout self) -> Self:
        for i in range(strlen(self.str_)):
            self.str_[i] = to_lower(self.str_[i])
        return self

    def uppercase(inout self) -> Self:
        for i in range(strlen(self.str_)):
            self.str_[i] = to_upper(self.str_[i])
        return self

    def ljustify(inout self) -> Self:
        let len = strlen(self.str_)
        for i in range(len):
            if self.str_[i] != 32:
                if i > 0:
                    memmove(self.str_, self.str_ + i, len - i)
                    memset(self.str_ + len - i, 32, i)
                return self
        return self

    def rjustify(inout self) -> Self:
        let len = strlen(self.str_)
        for i in range(len, 0, -1):
            if self.str_[i - 1] != 32:
                if i < len:
                    memmove(self.str_ + len - i, self.str_, i)
                    memset(self.str_, 32, len - i)
                return self
        return self

    def trim(inout self) -> Self:
        self.str_[self.len_trim()] = 0
        return self

    def center(inout self) -> Self:
        self.ljustify()
        let len_t = self.len_trim()
        let pad = (self.length() - len_t) // 2
        if pad > 0:
            memmove(self.str_ + pad, self.str_, len_t)
            memset(self.str_, 32, pad)
        return self

    def compress(inout self) -> Self:
        let len = strlen(self.str_)
        var j: size_type = 0
        for i in range(len):
            let c = self.str_[i]
            if (c != 32) and (c != 9) and (c != 0):
                self.str_[j] = c
                j += 1
        if j < len:
            memset(self.str_ + j, 32, len - j)
        return self

    def swap(inout self, inout s: Cstring):
        let tmp = self.str_
        self.str_ = s.str_
        s.str_ = tmp

    def lowercased(self) -> Cstring:
        var tmp = Cstring(self)
        tmp.lowercase()
        return tmp

    def uppercased(self) -> Cstring:
        var tmp = Cstring(self)
        tmp.uppercase()
        return tmp

    def rjustified(self) -> Cstring:
        var tmp = Cstring(self)
        tmp.rjustify()
        return tmp

    def trimmed(self) -> Cstring:
        return Cstring(self, self.len_trim())

    def centered(self) -> Cstring:
        var tmp = Cstring(self)
        tmp.center()
        return tmp

    def compressed(self) -> Cstring:
        var tmp = Cstring(self)
        tmp.compress()
        return tmp

    @staticmethod
    var npos: size_type = -1

def swap(inout s: Cstring, inout t: Cstring):
    let tmp = s.str_
    s.str_ = t.str_
    t.str_ = tmp

def __add__(s: StringRef, t: Cstring) -> Cstring:
    let s_len = strlen(s)
    let t_len = t.length()
    var u = Cstring(s_len + t_len)
    memcpy(u.str_, s, s_len)
    memcpy(u.str_ + s_len, t.str_, t_len + 1)
    return u

def __add__(c: UInt8, t: Cstring) -> Cstring:
    let t_len = t.length()
    var u = Cstring(1 + t_len)
    u.str_[0] = c
    memcpy(u.str_ + 1, t.str_, t_len + 1)
    return u

def __eq__(s: StringRef, t: Cstring) -> Bool:
    return strcmp(t.str_, s) == 0

def __ne__(s: StringRef, t: Cstring) -> Bool:
    return strcmp(t.str_, s) != 0

def __eq__(s: String, t: Cstring) -> Bool:
    return s == t.str_

def __ne__(s: String, t: Cstring) -> Bool:
    return s != t.str_

def __eq__(c: UInt8, s: Cstring) -> Bool:
    return (s.length() == 1) and (s.str_[0] == c)

def __ne__(c: UInt8, s: Cstring) -> Bool:
    return (s.length() != 1) or (s.str_[0] != c)

def equali(s: Cstring, t: Cstring) -> Bool:
    let s_len = s.length()
    if s_len != t.length():
        return False
    else:
        for i in range(s_len):
            if to_lower(s.str_[i]) != to_lower(t.str_[i]):
                return False
        return True

def equali(s: Cstring, t: StringRef) -> Bool:
    let s_len = s.length()
    if s_len != strlen(t):
        return False
    else:
        for i in range(s_len):
            if to_lower(s.str_[i]) != to_lower(t[i]):
                return False
        return True

def equali(s: StringRef, t: Cstring) -> Bool:
    let s_len = strlen(s)
    if s_len != t.length():
        return False
    else:
        for i in range(s_len):
            if to_lower(s[i]) != to_lower(t.str_[i]):
                return False
        return True

def equali(s: Cstring, t: String) -> Bool:
    let s_len = s.length()
    if s_len != t.length():
        return False
    else:
        for i in range(s_len):
            if to_lower(s.str_[i]) != to_lower(t[i]):
                return False
        return True

def equali(s: String, t: Cstring) -> Bool:
    let s_len = s.length()
    if s_len != t.length():
        return False
    else:
        for i in range(s_len):
            if to_lower(s[i]) != to_lower(t.str_[i]):
                return False
        return True

def equali(s: Cstring, c: UInt8) -> Bool:
    return (s.length() == 1) and (to_lower(s.str_[0]) == to_lower(c))

def equali(c: UInt8, s: Cstring) -> Bool:
    return (s.length() == 1) and (to_lower(s.str_[0]) == to_lower(c))

def __rshift__(stream: String, s: Cstring) -> String:
    var buffer = String()
    stream >> buffer
    s = buffer
    return stream

def __lshift__(stream: String, s: Cstring) -> String:
    for i in range(strlen(s.str_)):
        stream << s.str_[i]
    return stream