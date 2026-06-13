from ObjexxFCL.random import (
    RANDOM_NUMBER,
    RANDOM,
    RAND,
    RANF,
    DRANDM,
    DRAND,
    RANDU,
    IRANDM,
    IRAND,
    RANDOM_SEED,
    SRAND,
)
from ObjexxFCL.Array1D import Array1D
from testing import expect_true

_ = None

struct RandomTest:
    @staticmethod
    def RandomNumber():
        var r: Float64
        RANDOM_NUMBER(r)
        expect_true(0.0 <= r)
        expect_true(r < 1.0)
        var a = Array1D[Float32](3)
        RANDOM_NUMBER(a)
        for i in range(a.l(), a.u()+1):
            expect_true(0.0f <= a[i])
            expect_true(a[i] < 1.0f)

    @staticmethod
    def Random():
        var r: Float32
        RANDOM(r)
        expect_true(0.0f <= r)
        expect_true(r < 1.0f)
        var r2: Float32 = RANDOM(42)
        expect_true(0.0f <= r2)
        expect_true(r2 < 1.0f)

    @staticmethod
    def Rand():
        var r: Float32 = RAND()
        expect_true(0.0f <= r)
        expect_true(r < 1.0f)
        var r2: Float32 = RAND(42)
        expect_true(0.0f <= r2)
        expect_true(r2 < 1.0f)

    @staticmethod
    def Ranf():
        var r: Float32 = RANF()
        expect_true(0.0 <= r)
        expect_true(r < 2147483647.0)
        var r2: Float32 = RANF(42)
        expect_true(0.0 <= r2)
        expect_true(r2 < 2147483647.0)

    @staticmethod
    def DRandm():
        var r: Float64 = DRANDM(42)
        expect_true(0.0 <= r)
        expect_true(r < 1.0)

    @staticmethod
    def DRand():
        var r: Float64 = DRAND(42)
        expect_true(0.0 <= r)
        expect_true(r < 1.0)

    @staticmethod
    def Randu():
        var r: Float32
        RANDU(24, 42, r)
        expect_true(0.0f <= r)
        expect_true(r < 1.0f)

    @staticmethod
    def Irandm():
        var r: Int32 = IRANDM()
        expect_true(0 <= r)
        expect_true(r <= 32767)
        var r2: Int32 = IRANDM(42)
        expect_true(0 <= r2)
        expect_true(r2 <= 2147483647)

    @staticmethod
    def Irand():
        var r: Int32 = IRAND()
        expect_true(0 <= r)
        expect_true(r <= 32767)
        var r2: Int32 = IRAND(42)
        expect_true(0 <= r2)
        expect_true(r2 <= 2147483647)

    @staticmethod
    def RandomSeed():
        var size: Int32 = 0
        var put = Array1D[Int32]([11, 22, 33])
        var get = Array1D[Int32](3)
        RANDOM_SEED()
        RANDOM_SEED(size)
        RANDOM_SEED(_, put)
        RANDOM_SEED(_, _, get)

    @staticmethod
    def Srand():
        SRAND(42)