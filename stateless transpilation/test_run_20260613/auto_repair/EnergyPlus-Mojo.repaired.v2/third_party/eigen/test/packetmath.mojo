from main import *
from unsupported.Eigen.SpecialFunctions import *
# if defined __GNUC__ and __GNUC__>=6
#   #pragma GCC diagnostic ignored "-Wignored-attributes"
# endif
# ifdef EIGEN_VECTORIZE_SSE
alias g_vectorize_sse: Bool = True
# else
alias g_vectorize_sse: Bool = False
# endif

namespace Eigen:
    namespace internal:
        def negate[T](x: T) -> T:
            return -x

def isApproxAbs[Scalar: AnyType](a: Scalar, b: Scalar, refvalue: NumTraits[Scalar].Real) -> Bool:
    return internal.isMuchSmallerThan(a - b, refvalue)

def areApproxAbs[Scalar: AnyType](a: Scalar*, b: Scalar*, size: Int, refvalue: NumTraits[Scalar].Real) -> Bool:
    for i in range(size):
        if not isApproxAbs(a[i], b[i], refvalue):
            print("ref: [", Map[const Matrix[Scalar, 1, Dynamic]](a, size), "] != vec: [", Map[const Matrix[Scalar, 1, Dynamic]](b, size), "]\n")
            return False
    return True

def areApprox[Scalar: AnyType](a: Scalar*, b: Scalar*, size: Int) -> Bool:
    for i in range(size):
        if a[i] != b[i] and not internal.isApprox(a[i], b[i]):
            print("ref: [", Map[const Matrix[Scalar, 1, Dynamic]](a, size), "] != vec: [", Map[const Matrix[Scalar, 1, Dynamic]](b, size), "]\n")
            return False
    return True

@parameter
def CHECK_CWISE1[REFOP: fn(Scalar) -> Scalar, POP: fn(Packet) -> Packet]():
    for i in range(PacketSize):
        ref[i] = REFOP(data1[i])
    internal.pstore(data2, POP(internal.pload[Packet](data1)))
    VERIFY(areApprox(ref, data2, PacketSize) and stringify(POP))

struct packet_helper[Cond: Bool, Packet: AnyType]:
    def load[T: AnyType](self, from: T*) -> Packet:
        return internal.pload[Packet](from)
    def store[T: AnyType](self, to: T*, x: Packet):
        internal.pstore(to, x)

struct packet_helper[Cond: Bool where Cond == False, Packet: AnyType]:
    def load[T: AnyType](self, from: T*) -> T:
        return from[0]
    def store[T: AnyType](self, to: T*, x: T):
        to[0] = x

@parameter
def CHECK_CWISE1_IF[COND: Bool, REFOP: fn(Scalar) -> Scalar, POP: fn(Packet) -> Packet]():
    if COND:
        var h: packet_helper[COND, Packet]
        for i in range(PacketSize):
            ref[i] = REFOP(data1[i])
        h.store(data2, POP(h.load(data1)))
        VERIFY(areApprox(ref, data2, PacketSize) and stringify(POP))

@parameter
def CHECK_CWISE2_IF[COND: Bool, REFOP: fn(Scalar, Scalar) -> Scalar, POP: fn(Packet, Packet) -> Packet]():
    if COND:
        var h: packet_helper[COND, Packet]
        for i in range(PacketSize):
            ref[i] = REFOP(data1[i], data1[i + PacketSize])
        h.store(data2, POP(h.load(data1), h.load(data1 + PacketSize)))
        VERIFY(areApprox(ref, data2, PacketSize) and stringify(POP))

alias REF_ADD = fn(a, b) -> (a + b)
alias REF_SUB = fn(a, b) -> (a - b)
alias REF_MUL = fn(a, b) -> (a * b)
alias REF_DIV = fn(a, b) -> (a / b)

def packetmath[Scalar: AnyType]():
    using std.abs
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias PacketSize: Int = PacketTraits.size
    alias RealScalar: AnyType = NumTraits[Scalar].Real
    alias max_size: Int = 4 if PacketSize > 4 else PacketSize
    alias size: Int = PacketSize * max_size
    @align(max) var data1: Scalar[size]
    @align(max) var data2: Scalar[size]
    @align(max) var packets: Packet[PacketSize * 2]
    @align(max) var ref: Scalar[size]
    var refvalue: RealScalar = 0
    for i in range(size):
        data1[i] = internal.random[Scalar]() / RealScalar(PacketSize)
        data2[i] = internal.random[Scalar]() / RealScalar(PacketSize)
        refvalue = std.max(refvalue, abs(data1[i]))
    internal.pstore(data2, internal.pload[Packet](data1))
    VERIFY(areApprox(data1, data2, PacketSize) and "aligned load/store")
    for offset in range(PacketSize):
        internal.pstore(data2, internal.ploadu[Packet](data1 + offset))
        VERIFY(areApprox(data1 + offset, data2, PacketSize) and "internal.ploadu")
    for offset in range(PacketSize):
        internal.pstoreu(data2 + offset, internal.pload[Packet](data1))
        VERIFY(areApprox(data1, data2 + offset, PacketSize) and "internal.pstoreu")
    for offset in range(PacketSize):
        packets[0] = internal.pload[Packet](data1)
        packets[1] = internal.pload[Packet](data1 + PacketSize)
        if offset == 0: internal.palign[0](packets[0], packets[1])
        elif offset == 1: internal.palign[1](packets[0], packets[1])
        elif offset == 2: internal.palign[2](packets[0], packets[1])
        elif offset == 3: internal.palign[3](packets[0], packets[1])
        elif offset == 4: internal.palign[4](packets[0], packets[1])
        elif offset == 5: internal.palign[5](packets[0], packets[1])
        elif offset == 6: internal.palign[6](packets[0], packets[1])
        elif offset == 7: internal.palign[7](packets[0], packets[1])
        elif offset == 8: internal.palign[8](packets[0], packets[1])
        elif offset == 9: internal.palign[9](packets[0], packets[1])
        elif offset == 10: internal.palign[10](packets[0], packets[1])
        elif offset == 11: internal.palign[11](packets[0], packets[1])
        elif offset == 12: internal.palign[12](packets[0], packets[1])
        elif offset == 13: internal.palign[13](packets[0], packets[1])
        elif offset == 14: internal.palign[14](packets[0], packets[1])
        elif offset == 15: internal.palign[15](packets[0], packets[1])
        internal.pstore(data2, packets[0])
        for i in range(PacketSize):
            ref[i] = data1[i + offset]
        VERIFY(areApprox(ref, data2, PacketSize) and "internal.palign")
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasAdd)
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasSub)
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasMul)
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasNegate)
    VERIFY((internal.is_same[Scalar, Int]()) or (not PacketTraits.Vectorizable) or PacketTraits.HasDiv)
    CHECK_CWISE2_IF[PacketTraits.HasAdd, REF_ADD, internal.padd]()
    CHECK_CWISE2_IF[PacketTraits.HasSub, REF_SUB, internal.psub]()
    CHECK_CWISE2_IF[PacketTraits.HasMul, REF_MUL, internal.pmul]()
    CHECK_CWISE2_IF[PacketTraits.HasDiv, REF_DIV, internal.pdiv]()
    CHECK_CWISE1[internal.negate, internal.pnegate]()
    CHECK_CWISE1[numext.conj, internal.pconj]()
    for offset in range(3):
        for i in range(PacketSize):
            ref[i] = data1[offset]
        internal.pstore(data2, internal.pset1[Packet](data1[offset]))
        VERIFY(areApprox(ref, data2, PacketSize) and "internal.pset1")
    {
        for i in range(PacketSize * 4):
            ref[i] = data1[i // PacketSize]
        var A0: Packet
        var A1: Packet
        var A2: Packet
        var A3: Packet
        internal.pbroadcast4[Packet](data1, A0, A1, A2, A3)
        internal.pstore(data2 + 0 * PacketSize, A0)
        internal.pstore(data2 + 1 * PacketSize, A1)
        internal.pstore(data2 + 2 * PacketSize, A2)
        internal.pstore(data2 + 3 * PacketSize, A3)
        VERIFY(areApprox(ref, data2, 4 * PacketSize) and "internal.pbroadcast4")
    }
    {
        for i in range(PacketSize * 2):
            ref[i] = data1[i // PacketSize]
        var A0: Packet
        var A1: Packet
        internal.pbroadcast2[Packet](data1, A0, A1)
        internal.pstore(data2 + 0 * PacketSize, A0)
        internal.pstore(data2 + 1 * PacketSize, A1)
        VERIFY(areApprox(ref, data2, 2 * PacketSize) and "internal.pbroadcast2")
    }
    VERIFY(internal.isApprox(data1[0], internal.pfirst(internal.pload[Packet](data1))) and "internal.pfirst")
    if PacketSize > 1:
        for offset in range(4):
            for i in range(PacketSize // 2):
                ref[2 * i + 0] = ref[2 * i + 1] = data1[offset + i]
            internal.pstore(data2, internal.ploaddup[Packet](data1 + offset))
            VERIFY(areApprox(ref, data2, PacketSize) and "ploaddup")
    if PacketSize > 2:
        for offset in range(4):
            for i in range(PacketSize // 4):
                ref[4 * i + 0] = ref[4 * i + 1] = ref[4 * i + 2] = ref[4 * i + 3] = data1[offset + i]
            internal.pstore(data2, internal.ploadquad[Packet](data1 + offset))
            VERIFY(areApprox(ref, data2, PacketSize) and "ploadquad")
    ref[0] = 0
    for i in range(PacketSize):
        ref[0] += data1[i]
    VERIFY(isApproxAbs(ref[0], internal.predux(internal.pload[Packet](data1)), refvalue) and "internal.predux")
    {
        for i in range(4):
            ref[i] = 0
        for i in range(PacketSize):
            ref[i % 4] += data1[i]
        internal.pstore(data2, internal.predux_downto4(internal.pload[Packet](data1)))
        VERIFY(areApprox(ref, data2, PacketSize // 2 if PacketSize > 4 else PacketSize) and "internal.predux_downto4")
    }
    ref[0] = 1
    for i in range(PacketSize):
        ref[0] *= data1[i]
    VERIFY(internal.isApprox(ref[0], internal.predux_mul(internal.pload[Packet](data1))) and "internal.predux_mul")
    for j in range(PacketSize):
        ref[j] = 0
        for i in range(PacketSize):
            ref[j] += data1[i + j * PacketSize]
        packets[j] = internal.pload[Packet](data1 + j * PacketSize)
    internal.pstore(data2, internal.preduxp(packets))
    VERIFY(areApproxAbs(ref, data2, PacketSize, refvalue) and "internal.preduxp")
    for i in range(PacketSize):
        ref[i] = data1[PacketSize - i - 1]
    internal.pstore(data2, internal.preverse(internal.pload[Packet](data1)))
    VERIFY(areApprox(ref, data2, PacketSize) and "internal.preverse")
    var kernel: internal.PacketBlock[Packet]
    for i in range(PacketSize):
        kernel.packet[i] = internal.pload[Packet](data1 + i * PacketSize)
    ptranspose(kernel)
    for i in range(PacketSize):
        internal.pstore(data2, kernel.packet[i])
        for j in range(PacketSize):
            VERIFY(isApproxAbs(data2[j], data1[i + j * PacketSize], refvalue) and "ptranspose")
    if PacketTraits.HasBlend:
        var thenPacket: Packet = internal.pload[Packet](data1)
        var elsePacket: Packet = internal.pload[Packet](data2)
        @align(max) var selector: internal.Selector[PacketSize]
        for i in range(PacketSize):
            selector.select[i] = i
        var blend: Packet = internal.pblend(selector, thenPacket, elsePacket)
        @align(max) var result: Scalar[size]
        internal.pstore(result, blend)
        for i in range(PacketSize):
            VERIFY(isApproxAbs(result[i], data1[i] if selector.select[i] else data2[i], refvalue))
    if PacketTraits.HasBlend or g_vectorize_sse:
        for i in range(PacketSize):
            ref[i] = data1[i]
        var s: Scalar = internal.random[Scalar]()
        ref[0] = s
        internal.pstore(data2, internal.pinsertfirst(internal.pload[Packet](data1), s))
        VERIFY(areApprox(ref, data2, PacketSize) and "internal.pinsertfirst")
    if PacketTraits.HasBlend or g_vectorize_sse:
        for i in range(PacketSize):
            ref[i] = data1[i]
        var s: Scalar = internal.random[Scalar]()
        ref[PacketSize - 1] = s
        internal.pstore(data2, internal.pinsertlast(internal.pload[Packet](data1), s))
        VERIFY(areApprox(ref, data2, PacketSize) and "internal.pinsertlast")

def packetmath_real[Scalar: AnyType]():
    using std.abs
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias PacketSize: Int = PacketTraits.size
    alias size: Int = PacketSize * 4
    @align(max) var data1: Scalar[PacketTraits.size * 4]
    @align(max) var data2: Scalar[PacketTraits.size * 4]
    @align(max) var ref: Scalar[PacketTraits.size * 4]
    for i in range(size):
        data1[i] = internal.random[Scalar](-1, 1) * std.pow(Scalar(10), internal.random[Scalar](-3, 3))
        data2[i] = internal.random[Scalar](-1, 1) * std.pow(Scalar(10), internal.random[Scalar](-3, 3))
    CHECK_CWISE1_IF[PacketTraits.HasSin, std.sin, internal.psin]()
    CHECK_CWISE1_IF[PacketTraits.HasCos, std.cos, internal.pcos]()
    CHECK_CWISE1_IF[PacketTraits.HasTan, std.tan, internal.ptan]()
    CHECK_CWISE1_IF[PacketTraits.HasRound, numext.round, internal.pround]()
    CHECK_CWISE1_IF[PacketTraits.HasCeil, numext.ceil, internal.pceil]()
    CHECK_CWISE1_IF[PacketTraits.HasFloor, numext.floor, internal.pfloor]()
    for i in range(size):
        data1[i] = internal.random[Scalar](-1, 1)
        data2[i] = internal.random[Scalar](-1, 1)
    CHECK_CWISE1_IF[PacketTraits.HasASin, std.asin, internal.pasin]()
    CHECK_CWISE1_IF[PacketTraits.HasACos, std.acos, internal.pacos]()
    for i in range(size):
        data1[i] = internal.random[Scalar](-87, 88)
        data2[i] = internal.random[Scalar](-87, 88)
    CHECK_CWISE1_IF[PacketTraits.HasExp, std.exp, internal.pexp]()
    for i in range(size):
        data1[i] = internal.random[Scalar](-1, 1) * std.pow(Scalar(10), internal.random[Scalar](-6, 6))
        data2[i] = internal.random[Scalar](-1, 1) * std.pow(Scalar(10), internal.random[Scalar](-6, 6))
    CHECK_CWISE1_IF[PacketTraits.HasTanh, std.tanh, internal.ptanh]()
    if PacketTraits.HasExp and PacketTraits.size >= 2:
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        data1[1] = std.numeric_limits[Scalar].epsilon()
        var h: packet_helper[PacketTraits.HasExp, Packet]
        h.store(data2, internal.pexp(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
        VERIFY_IS_EQUAL(std.exp(std.numeric_limits[Scalar].epsilon()), data2[1])
        data1[0] = -std.numeric_limits[Scalar].epsilon()
        data1[1] = 0
        h.store(data2, internal.pexp(h.load(data1)))
        VERIFY_IS_EQUAL(std.exp(-std.numeric_limits[Scalar].epsilon()), data2[0])
        VERIFY_IS_EQUAL(std.exp(Scalar(0)), data2[1])
        data1[0] = std.numeric_limits[Scalar].min()
        data1[1] = -(std.numeric_limits[Scalar].min())
        h.store(data2, internal.pexp(h.load(data1)))
        VERIFY_IS_EQUAL(std.exp(std.numeric_limits[Scalar].min()), data2[0])
        VERIFY_IS_EQUAL(std.exp(-(std.numeric_limits[Scalar].min())), data2[1])
        data1[0] = std.numeric_limits[Scalar].denorm_min()
        data1[1] = -std.numeric_limits[Scalar].denorm_min()
        h.store(data2, internal.pexp(h.load(data1)))
        VERIFY_IS_EQUAL(std.exp(std.numeric_limits[Scalar].denorm_min()), data2[0])
        VERIFY_IS_EQUAL(std.exp(-std.numeric_limits[Scalar].denorm_min()), data2[1])
    if PacketTraits.HasTanh:
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        var h: packet_helper[internal.packet_traits[Scalar].HasTanh, Packet]
        h.store(data2, internal.ptanh(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
    #if EIGEN_HAS_C99_MATH:
    {
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        var h: packet_helper[internal.packet_traits[Scalar].HasLGamma, Packet]
        h.store(data2, internal.plgamma(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
    }
    {
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        var h: packet_helper[internal.packet_traits[Scalar].HasErf, Packet]
        h.store(data2, internal.perf(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
    }
    {
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        var h: packet_helper[internal.packet_traits[Scalar].HasErfc, Packet]
        h.store(data2, internal.perfc(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
    }
    #endif  // EIGEN_HAS_C99_MATH
    for i in range(size):
        data1[i] = internal.random[Scalar](0, 1) * std.pow(Scalar(10), internal.random[Scalar](-6, 6))
        data2[i] = internal.random[Scalar](0, 1) * std.pow(Scalar(10), internal.random[Scalar](-6, 6))
    if internal.random[float](0, 1) < 0.1f:
        data1[internal.random[Int](0, PacketSize)] = 0
    CHECK_CWISE1_IF[PacketTraits.HasSqrt, std.sqrt, internal.psqrt]()
    CHECK_CWISE1_IF[PacketTraits.HasLog, std.log, internal.plog]()
    #if EIGEN_HAS_C99_MATH and (__cplusplus > 199711L):
    CHECK_CWISE1_IF[PacketTraits.HasLog1p, std.log1p, internal.plog1p]()
    CHECK_CWISE1_IF[internal.packet_traits[Scalar].HasLGamma, std.lgamma, internal.plgamma]()
    CHECK_CWISE1_IF[internal.packet_traits[Scalar].HasErf, std.erf, internal.perf]()
    CHECK_CWISE1_IF[internal.packet_traits[Scalar].HasErfc, std.erfc, internal.perfc]()
    #endif
    if PacketTraits.HasLog and PacketTraits.size >= 2:
        data1[0] = std.numeric_limits[Scalar].quiet_NaN()
        data1[1] = std.numeric_limits[Scalar].epsilon()
        var h: packet_helper[PacketTraits.HasLog, Packet]
        h.store(data2, internal.plog(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
        VERIFY_IS_EQUAL(std.log(std.numeric_limits[Scalar].epsilon()), data2[1])
        data1[0] = -std.numeric_limits[Scalar].epsilon()
        data1[1] = 0
        h.store(data2, internal.plog(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
        VERIFY_IS_EQUAL(std.log(Scalar(0)), data2[1])
        data1[0] = std.numeric_limits[Scalar].min()
        data1[1] = -(std.numeric_limits[Scalar].min())
        h.store(data2, internal.plog(h.load(data1)))
        VERIFY_IS_EQUAL(std.log(std.numeric_limits[Scalar].min()), data2[0])
        VERIFY(numext.isnan(data2[1]))
        data1[0] = std.numeric_limits[Scalar].denorm_min()
        data1[1] = -std.numeric_limits[Scalar].denorm_min()
        h.store(data2, internal.plog(h.load(data1)))
        VERIFY(numext.isnan(data2[1]))
        data1[0] = Scalar(-1.0f)
        h.store(data2, internal.plog(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
        h.store(data2, internal.psqrt(h.load(data1)))
        VERIFY(numext.isnan(data2[0]))
        VERIFY(numext.isnan(data2[1]))

def packetmath_notcomplex[Scalar: AnyType]():
    using std.abs
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias PacketSize: Int = PacketTraits.size
    @align(max) var data1: Scalar[PacketTraits.size * 4]
    @align(max) var data2: Scalar[PacketTraits.size * 4]
    @align(max) var ref: Scalar[PacketTraits.size * 4]
    Array[Scalar, Dynamic, 1].Map(data1, PacketTraits.size * 4).setRandom()
    ref[0] = data1[0]
    for i in range(PacketSize):
        ref[0] = std.min(ref[0], data1[i])
    VERIFY(internal.isApprox(ref[0], internal.predux_min(internal.pload[Packet](data1))) and "internal.predux_min")
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasMin)
    VERIFY((not PacketTraits.Vectorizable) or PacketTraits.HasMax)
    CHECK_CWISE2_IF[PacketTraits.HasMin, std.min, internal.pmin]()
    CHECK_CWISE2_IF[PacketTraits.HasMax, std.max, internal.pmax]()
    CHECK_CWISE1[abs, internal.pabs]()
    ref[0] = data1[0]
    for i in range(PacketSize):
        ref[0] = std.max(ref[0], data1[i])
    VERIFY(internal.isApprox(ref[0], internal.predux_max(internal.pload[Packet](data1))) and "internal.predux_max")
    for i in range(PacketSize):
        ref[i] = data1[0] + Scalar(i)
    internal.pstore(data2, internal.plset[Packet](data1[0]))
    VERIFY(areApprox(ref, data2, PacketSize) and "internal.plset")

def test_conj_helper[Scalar: AnyType, ConjLhs: Bool, ConjRhs: Bool](data1: Scalar*, data2: Scalar*, ref: Scalar*, pval: Scalar*):
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias PacketSize: Int = PacketTraits.size
    var cj0: internal.conj_if[ConjLhs]
    var cj1: internal.conj_if[ConjRhs]
    var cj: internal.conj_helper[Scalar, Scalar, ConjLhs, ConjRhs]
    var pcj: internal.conj_helper[Packet, Packet, ConjLhs, ConjRhs]
    for i in range(PacketSize):
        ref[i] = cj0(data1[i]) * cj1(data2[i])
        VERIFY(internal.isApprox(ref[i], cj.pmul(data1[i], data2[i])) and "conj_helper pmul")
    internal.pstore(pval, pcj.pmul(internal.pload[Packet](data1), internal.pload[Packet](data2)))
    VERIFY(areApprox(ref, pval, PacketSize) and "conj_helper pmul")
    for i in range(PacketSize):
        var tmp: Scalar = ref[i]
        ref[i] += cj0(data1[i]) * cj1(data2[i])
        VERIFY(internal.isApprox(ref[i], cj.pmadd(data1[i], data2[i], tmp)) and "conj_helper pmadd")
    internal.pstore(pval, pcj.pmadd(internal.pload[Packet](data1), internal.pload[Packet](data2), internal.pload[Packet](pval)))
    VERIFY(areApprox(ref, pval, PacketSize) and "conj_helper pmadd")

def packetmath_complex[Scalar: AnyType]():
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias PacketSize: Int = PacketTraits.size
    alias size: Int = PacketSize * 4
    @align(max) var data1: Scalar[PacketSize * 4]
    @align(max) var data2: Scalar[PacketSize * 4]
    @align(max) var ref: Scalar[PacketSize * 4]
    @align(max) var pval: Scalar[PacketSize * 4]
    for i in range(size):
        data1[i] = internal.random[Scalar]() * Scalar(1e2)
        data2[i] = internal.random[Scalar]() * Scalar(1e2)
    test_conj_helper[Scalar, False, False](data1, data2, ref, pval)
    test_conj_helper[Scalar, False, True](data1, data2, ref, pval)
    test_conj_helper[Scalar, True, False](data1, data2, ref, pval)
    test_conj_helper[Scalar, True, True](data1, data2, ref, pval)
    {
        for i in range(PacketSize):
            ref[i] = Scalar(std.imag(data1[i]), std.real(data1[i]))
        internal.pstore(pval, internal.pcplxflip(internal.pload[Packet](data1)))
        VERIFY(areApprox(ref, pval, PacketSize) and "pcplxflip")
    }

def packetmath_scatter_gather[Scalar: AnyType]():
    alias PacketTraits: AnyType = internal.packet_traits[Scalar]
    alias Packet: AnyType = PacketTraits.type
    alias RealScalar: AnyType = NumTraits[Scalar].Real
    alias PacketSize: Int = PacketTraits.size
    @align(max) var data1: Scalar[PacketSize]
    var refvalue: RealScalar = 0
    for i in range(PacketSize):
        data1[i] = internal.random[Scalar]() / RealScalar(PacketSize)
    var stride: Int = internal.random[Int](1, 20)
    @align(max) var buffer: Scalar[PacketSize * 20]
    memset(buffer, 0, 20 * PacketSize * sizeof(Scalar))
    var packet: Packet = internal.pload[Packet](data1)
    internal.pscatter[Scalar, Packet](buffer, packet, stride)
    for i in range(PacketSize * 20):
        if (i % stride) == 0 and i < stride * PacketSize:
            VERIFY(isApproxAbs(buffer[i], data1[i // stride], refvalue) and "pscatter")
        else:
            VERIFY(isApproxAbs(buffer[i], Scalar(0), refvalue) and "pscatter")
    for i in range(PacketSize * 7):
        buffer[i] = internal.random[Scalar]() / RealScalar(PacketSize)
    packet = internal.pgather[Scalar, Packet](buffer, 7)
    internal.pstore(data1, packet)
    for i in range(PacketSize):
        VERIFY(isApproxAbs(data1[i], buffer[i * 7], refvalue) and "pgather")

def test_packetmath():
    for i in range(g_repeat):
        CALL_SUBTEST_1(packetmath[float]())
        CALL_SUBTEST_2(packetmath[double]())
        CALL_SUBTEST_3(packetmath[Int]())
        CALL_SUBTEST_4(packetmath[std.complex[float]]())
        CALL_SUBTEST_5(packetmath[std.complex[double]]())
        CALL_SUBTEST_1(packetmath_notcomplex[float]())
        CALL_SUBTEST_2(packetmath_notcomplex[double]())
        CALL_SUBTEST_3(packetmath_notcomplex[Int]())
        CALL_SUBTEST_1(packetmath_real[float]())
        CALL_SUBTEST_2(packetmath_real[double]())
        CALL_SUBTEST_4(packetmath_complex[std.complex[float]]())
        CALL_SUBTEST_5(packetmath_complex[std.complex[double]]())
        CALL_SUBTEST_1(packetmath_scatter_gather[float]())
        CALL_SUBTEST_2(packetmath_scatter_gather[double]())
        CALL_SUBTEST_3(packetmath_scatter_gather[Int]())
        CALL_SUBTEST_4(packetmath_scatter_gather[std.complex[float]]())
        CALL_SUBTEST_5(packetmath_scatter_gather[std.complex[double]]())