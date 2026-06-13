module re2:

from algorithm import search, find, find_end
from memory import memcpy as memcpy, memcmp as memcmp
from builtins import str as string, Pointer
from libc import strlen as strlen

struct StringPiece:
    type size_type = UInt
    type difference_type = Int
    type traits_type = CharTraits[Char]
    type value_type = Char
    type pointer = Pointer[Char]
    type const_pointer = Pointer[Char]
    type reference = Char
    type const_reference = Char
    type const_iterator = Pointer[Char]
    type iterator = Pointer[Char]
    type const_reverse_iterator = ReverseIterator[Pointer[Char]]
    type reverse_iterator = ReverseIterator[Pointer[Char]]
    static npos: size_type = size_type(-1)
    
    var data_: const_pointer
    var size_: size_type
    
    def __init__(self):
        self.data_ = const_pointer()
        self.size_ = 0
    
    def __init__(self, str: String):
        self.data_ = str.data()
        self.size_ = str.size()
    
    def __init__(self, str: Pointer[Char]):
        self.data_ = str
        self.size_ = 0 if str.is_null() else strlen(str)
    
    def __init__(self, str: Pointer[Char], len: size_type):
        self.data_ = str
        self.size_ = len
    
    # Conversion from string_view not included (C++17 conditional)
    
    def begin(self) -> const_iterator:
        return self.data_
    
    def end(self) -> const_iterator:
        return self.data_ + self.size_
    
    def rbegin(self) -> const_reverse_iterator:
        return const_reverse_iterator(self.data_ + self.size_)
    
    def rend(self) -> const_reverse_iterator:
        return const_reverse_iterator(self.data_)
    
    def size(self) -> size_type:
        return self.size_
    
    def length(self) -> size_type:
        return self.size_
    
    def empty(self) -> bool:
        return self.size_ == 0
    
    def __getitem__(self, i: size_type) -> const_reference:
        return self.data_[i]
    
    def data(self) -> const_pointer:
        return self.data_
    
    def remove_prefix(self, n: size_type):
        self.data_ += n
        self.size_ -= n
    
    def remove_suffix(self, n: size_type):
        self.size_ -= n
    
    def set(self, str: Pointer[Char]):
        self.data_ = str
        self.size_ = 0 if str.is_null() else strlen(str)
    
    def set(self, str: Pointer[Char], len: size_type):
        self.data_ = str
        self.size_ = len
    
    # Explicit conversion to basic_string - omitted, use as_string instead
    
    def as_string(self) -> String:
        return String(self.data_, self.size_)
    
    def ToString(self) -> String:
        return String(self.data_, self.size_)
    
    def CopyToString(self, target: Pointer[String]):
        target[0].assign(self.data_, self.size_)
    
    def AppendToString(self, target: Pointer[String]):
        target[0].append(self.data_, self.size_)
    
    def copy(self, buf: Pointer[Char], n: size_type, pos: size_type = 0) -> size_type:
        var ret = min(self.size_ - pos, n)
        memcpy(buf, self.data_ + pos, ret)
        return ret
    
    def substr(self, pos: size_type = 0, n: size_type = npos) -> StringPiece:
        var pos_adj = pos if pos <= self.size_ else self.size_
        var n_adj = n if n <= self.size_ - pos_adj else self.size_ - pos_adj
        return StringPiece(self.data_ + pos_adj, n_adj)
    
    def compare(self, x: StringPiece) -> Int:
        var min_size = min(self.size(), x.size())
        if min_size > 0:
            var r = memcmp(self.data(), x.data(), min_size)
            if r < 0:
                return -1
            if r > 0:
                return 1
        if self.size() < x.size():
            return -1
        if self.size() > x.size():
            return 1
        return 0
    
    def starts_with(self, x: StringPiece) -> bool:
        return x.empty() or (self.size() >= x.size() and memcmp(self.data(), x.data(), x.size()) == 0)
    
    def ends_with(self, x: StringPiece) -> bool:
        return x.empty() or (self.size() >= x.size() and memcmp(self.data() + (self.size() - x.size()), x.data(), x.size()) == 0)
    
    def contains(self, s: StringPiece) -> bool:
        return self.find(s) != npos
    
    def find(self, s: StringPiece, pos: size_type = 0) -> size_type:
        if pos > self.size_:
            return npos
        var result = search(self.data_ + pos, self.data_ + self.size_, s.data_, s.data_ + s.size_)
        var xpos = result - self.data_
        return xpos + s.size_ <= self.size_ ? xpos : npos
    
    def find(self, c: Char, pos: size_type = 0) -> size_type:
        if self.size_ <= 0 or pos >= self.size_:
            return npos
        var result = find(self.data_ + pos, self.data_ + self.size_, c)
        return (result - self.data_) if result != self.data_ + self.size_ else npos
    
    def rfind(self, s: StringPiece, pos: size_type = npos) -> size_type:
        if self.size_ < s.size_:
            return npos
        if s.size_ == 0:
            return min(self.size_, pos)
        var last = self.data_ + min(self.size_ - s.size_, pos) + s.size_
        var result = find_end(self.data_, last, s.data_, s.data_ + s.size_)
        return (result - self.data_) if result != last else npos
    
    def rfind(self, c: Char, pos: size_type = npos) -> size_type:
        if self.size_ <= 0:
            return npos
        for i in range(min(pos + 1, self.size_), 0, -1):
            if self.data_[i-1] == c:
                return i-1
        return npos


def operator==(x: StringPiece, y: StringPiece) -> bool:
    let len = x.size()
    if len != y.size():
        return False
    return x.data() == y.data() or len == 0 or memcmp(x.data(), y.data(), len) == 0

def operator!=(x: StringPiece, y: StringPiece) -> bool:
    return not (x == y)

def operator<(x: StringPiece, y: StringPiece) -> bool:
    let min_size = min(x.size(), y.size())
    let r = 0 if min_size == 0 else memcmp(x.data(), y.data(), min_size)
    return (r < 0) or (r == 0 and x.size() < y.size())

def operator>(x: StringPiece, y: StringPiece) -> bool:
    return y < x

def operator<=(x: StringPiece, y: StringPiece) -> bool:
    return not (x > y)

def operator>=(x: StringPiece, y: StringPiece) -> bool:
    return not (x < y)

def operator<<(o: OStream, p: StringPiece) -> OStream:
    o.write(p.data(), p.size())
    return o