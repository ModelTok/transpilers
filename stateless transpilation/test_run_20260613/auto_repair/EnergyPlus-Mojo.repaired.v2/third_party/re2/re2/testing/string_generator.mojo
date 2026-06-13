from builtin import StringRef

# ==============================
# Minimal LCG: minstd_rand0
# ==============================
struct MinstdRand0:
    var state: Int

    def __init__(inout self):
        self.state = 1  # Default seed from C++

    def seed(inout self, seed: Int32):
        self.state = seed

    def __call__(inout self) -> Int32:
        # Multiplier = 48271, Modulus = 2147483647 (2^31 - 1)
        self.state = (self.state * 48271) % 2147483647
        return self.state

# ==============================
# Minimal uniform_int_distribution
# ==============================
struct uniform_int_distribution:
    var a: Int
    var b: Int
    var range: Int

    def __init__(inout self, a: Int, b: Int):
        self.a = a
        self.b = b
        self.range = b - a + 1

    def __call__(inout self, inout gen: MinstdRand0) -> Int:
        # Rejection sampling to avoid bias (like typical C++ implementation)
        let max_val = (2147483647 // self.range) * self.range
        var val: Int
        while True:
            val = gen()
            if val < max_val:
                break
        return self.a + (val % self.range)

# ==============================
# CHECK macros (simplified)
# ==============================
def CHECK(cond: Bool):
    assert(cond)

def CHECK_EQ(a: Int, b: Int):
    assert(a == b)

def CHECK_GE(a: Int, b: Int):
    assert(a >= b)

def CHECK_LE(a: Int, b: Int):
    assert(a <= b)

# ==============================
# StringPiece alias (use StringRef)
# ==============================
alias StringPiece = StringRef

# ==============================
# StringGenerator class
# ==============================
struct StringGenerator:
    var maxlen_: Int
    var alphabet_: List[String]
    var sp_: StringPiece
    var s_: String
    var hasnext_: Bool
    var digits_: List[Int]
    var generate_null_: Bool
    var random_: Bool
    var nrandom_: Int
    var rng_: MinstdRand0

    def __init__(inout self, maxlen: Int, alphabet: List[String]):
        self.maxlen_ = maxlen
        self.alphabet_ = alphabet
        self.generate_null_ = False
        self.random_ = False
        self.nrandom_ = 0
        if len(self.alphabet_) == 0:
            self.maxlen_ = 0
        self.hasnext_ = True
        # Initialize other members to default
        self.sp_ = StringPiece()
        self.s_ = String()
        self.digits_ = List[Int]()
        self.rng_ = MinstdRand0()

    def __del__(owned self):

    def Reset(inout self):
        self.digits_.clear()
        self.hasnext_ = True
        self.random_ = False
        self.nrandom_ = 0
        self.generate_null_ = False

    def IncrementDigits(inout self) -> Bool:
        var i = len(self.digits_) - 1
        while i >= 0:
            self.digits_[i] += 1
            if self.digits_[i] < len(self.alphabet_):
                return True
            self.digits_[i] = 0
            i -= 1
        if len(self.digits_) < self.maxlen_:
            self.digits_.push_back(0)
            return True
        return False

    def RandomDigits(inout self) -> Bool:
        self.nrandom_ -= 1
        if self.nrandom_ <= 0:
            return False
        var random_len = uniform_int_distribution(0, self.maxlen_)
        var random_alphabet_index = uniform_int_distribution(
            0, len(self.alphabet_) - 1
        )
        var len_val = random_len(self.rng_)
        self.digits_.resize(len_val)
        var i = 0
        while i < len_val:
            self.digits_[i] = random_alphabet_index(self.rng_)
            i += 1
        return True

    def Next(inout self) -> StringPiece:
        CHECK(self.hasnext_)
        if self.generate_null_:
            self.generate_null_ = False
            self.sp_ = StringPiece()
            return self.sp_
        self.s_.clear()
        var i = 0
        while i < len(self.digits_):
            self.s_ += self.alphabet_[self.digits_[i]]
            i += 1
        if self.random_:
            self.hasnext_ = self.RandomDigits()
        else:
            self.hasnext_ = self.IncrementDigits()
        self.sp_ = self.s_.as_string_ref()
        return self.sp_

    def Random(inout self, seed: Int32, n: Int):
        self.rng_.seed(seed)
        self.random_ = True
        self.nrandom_ = n
        self.hasnext_ = self.nrandom_ > 0

    def GenerateNULL(inout self):
        self.generate_null_ = True
        self.hasnext_ = True

    # Delete copy constructor and assignment (not needed, Mojo struct default prevents copy)
    # Not implemented.

# ==============================
# DeBruijnString function
# ==============================
def DeBruijnString(n: Int) -> String:
    CHECK_GE(n, 1)
    CHECK_LE(n, 29)
    let size: Int = 1 << n
    let mask: Int = size - 1
    var did = List[Bool](size, False)
    var s = String()
    s.reserve((n - 1) + size)
    var i: Int = 0
    while i < (n - 1):
        s += '0'
        i += 1
    var bits: Int = 0
    i = 0
    while i < size:
        bits <<= 1
        bits &= mask
        if not did[bits | 1]:
            bits |= 1
            s += '1'
        else:
            s += '0'
        CHECK(not did[bits])
        did[bits] = True
        i += 1
    CHECK_EQ(len(s), (n - 1) + size)
    return s