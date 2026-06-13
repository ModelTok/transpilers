# Mojo translation of unalignedassert.cpp
# Conditional compilation based on EIGEN_TEST_PART parameter
@parameter
if EIGEN_TEST_PART == 1:
    # No extra defines, default alignment (16)
    alias EIGEN_MAX_STATIC_ALIGN_BYTES = 16
    alias EIGEN_MAX_ALIGN_BYTES = 16
elif EIGEN_TEST_PART == 2:
    alias EIGEN_MAX_STATIC_ALIGN_BYTES = 16
    alias EIGEN_MAX_ALIGN_BYTES = 16
elif EIGEN_TEST_PART == 3:
    alias EIGEN_MAX_STATIC_ALIGN_BYTES = 32
    alias EIGEN_MAX_ALIGN_BYTES = 32
elif EIGEN_TEST_PART == 4:
    alias EIGEN_MAX_STATIC_ALIGN_BYTES = 64
    alias EIGEN_MAX_ALIGN_BYTES = 64
else:
    # Default to part 1 behavior
    alias EIGEN_MAX_STATIC_ALIGN_BYTES = 16
    alias EIGEN_MAX_ALIGN_BYTES = 16

# Include main test utilities
from main import VERIFY_RAISES_ASSERT, CALL_SUBTEST

# Import Eigen types
from ...Eigen import (
    Matrix, MatrixXd, Matrix3d, Matrix4f, Matrix2f, Matrix3f, Matrix4d, Matrix2d,
    Vector2f, Vector3f, Vector4f, Vector6f, Vector8f, Vector12f,
    Vector2d, Vector3d, Vector4d, Vector5d, Vector6d, Vector7d, Vector8d, Vector9d, Vector10d, Vector12d,
    Vector2cf, Vector3cf, Vector2cd, Vector3cd,
    Vector4i,
    DontAlign,
    internal
)

# Typedefs (aliases)
alias Vector6f = Matrix[float32, 6, 1]
alias Vector8f = Matrix[float32, 8, 1]
alias Vector12f = Matrix[float32, 12, 1]
alias Vector5d = Matrix[float64, 5, 1]
alias Vector6d = Matrix[float64, 6, 1]
alias Vector7d = Matrix[float64, 7, 1]
alias Vector8d = Matrix[float64, 8, 1]
alias Vector9d = Matrix[float64, 9, 1]
alias Vector10d = Matrix[float64, 10, 1]
alias Vector12d = Matrix[float64, 12, 1]

# Structs
struct TestNew1:
    var m: MatrixXd  # good: m will allocate its own array, taking care of alignment.
    def __init__(inout self):
        self.m = MatrixXd(20, 20)

struct TestNew2:
    var m: Matrix3d  # good: m's size isn't a multiple of 16 bytes, so m doesn't have to be 16-byte aligned,

struct TestNew3:
    var m: Vector2f  # good: m's size isn't a multiple of 16 bytes, so m doesn't have to be 16-byte aligned

struct TestNew4:
    # EIGEN_MAKE_ALIGNED_OPERATOR_NEW
    var m: Vector2d
    var f: float32  # make the struct have sizeof%16!=0 to make it a little more tricky when we allow an array of 2 such objects

struct TestNew5:
    # EIGEN_MAKE_ALIGNED_OPERATOR_NEW
    var f: float32  # try the f at first -- the EIGEN_ALIGN_MAX attribute of m should make that still work
    var m: Matrix4f

struct TestNew6:
    var m: Matrix[float32, 2, 2, DontAlign]  # good: no alignment requested
    var f: float32

struct Depends[Align: Bool]:
    # EIGEN_MAKE_ALIGNED_OPERATOR_NEW_IF(Align)
    var m: Vector2d
    var f: float32

# Helper function
def check_unalignedassert_good[T: AnyType]():
    var x: T
    var y: T
    x = T()
    del x
    y = T[2]()
    del y

# Conditional function
@parameter
if EIGEN_MAX_STATIC_ALIGN_BYTES > 0:
    def construct_at_boundary[T: AnyType](boundary: Int):
        var buf = Array[UInt8, sizeof[T] + 256]()
        var _buf: Int = int(pointer.address(buf))
        _buf += (EIGEN_MAX_ALIGN_BYTES - (_buf % EIGEN_MAX_ALIGN_BYTES))  # make 16/32/...-byte aligned
        _buf += boundary  # make exact boundary-aligned
        var x: T = new (reinterpret[Pointer[NoneType]](_buf)) T
        x[0].setZero()  # just in order to silence warnings
        x.~T()

def unalignedassert():
    @parameter
    if EIGEN_MAX_STATIC_ALIGN_BYTES > 0:
        construct_at_boundary[Vector2f](4)
        construct_at_boundary[Vector3f](4)
        construct_at_boundary[Vector4f](16)
        construct_at_boundary[Vector6f](4)
        construct_at_boundary[Vector8f](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector12f](16)
        construct_at_boundary[Matrix2f](16)
        construct_at_boundary[Matrix3f](4)
        construct_at_boundary[Matrix4f](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector2d](16)
        construct_at_boundary[Vector3d](4)
        construct_at_boundary[Vector4d](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector5d](4)
        construct_at_boundary[Vector6d](16)
        construct_at_boundary[Vector7d](4)
        construct_at_boundary[Vector8d](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector9d](4)
        construct_at_boundary[Vector10d](16)
        construct_at_boundary[Vector12d](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Matrix2d](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Matrix3d](4)
        construct_at_boundary[Matrix4d](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector2cf](16)
        construct_at_boundary[Vector3cf](4)
        construct_at_boundary[Vector2cd](EIGEN_MAX_ALIGN_BYTES)
        construct_at_boundary[Vector3cd](16)

    check_unalignedassert_good[TestNew1]()
    check_unalignedassert_good[TestNew2]()
    check_unalignedassert_good[TestNew3]()
    check_unalignedassert_good[TestNew4]()
    check_unalignedassert_good[TestNew5]()
    check_unalignedassert_good[TestNew6]()
    check_unalignedassert_good[Depends[True]]()

    @parameter
    if EIGEN_MAX_STATIC_ALIGN_BYTES > 0:
        if EIGEN_MAX_ALIGN_BYTES >= 16:
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector4f](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector8f](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector12f](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector2d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector4d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector6d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector8d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector10d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector12d](8))
            VERIFY_RAISES_ASSERT(construct_at_boundary[Vector4i](8))

        for b in range(8, EIGEN_MAX_ALIGN_BYTES, 8):
            if b < 32:
                VERIFY_RAISES_ASSERT(construct_at_boundary[Vector8f](b))
            if b < 64:
                VERIFY_RAISES_ASSERT(construct_at_boundary[Matrix4f](b))
            if b < 32:
                VERIFY_RAISES_ASSERT(construct_at_boundary[Vector4d](b))
            if b < 32:
                VERIFY_RAISES_ASSERT(construct_at_boundary[Matrix2d](b))
            if b < 128:
                VERIFY_RAISES_ASSERT(construct_at_boundary[Matrix4d](b))

def test_unalignedassert():
    CALL_SUBTEST(unalignedassert())