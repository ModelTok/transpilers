# This is a faithful 1:1 translation of the C++ file to Mojo.
# It assumes the existence of an Eigen module providing types like Matrix, Vector, Map, etc.
# and internal functions like aligned_new, aligned_delete, random, UIntPtr, packet_traits.
# The test macros are defined locally.

from Eigen import (
    Matrix, Vector, Map, AlignedMax, Dynamic, OuterStride,
    internal, EIGEN_MAX_ALIGN_BYTES, EIGEN_VECTORIZE
)

# Constants
alias EIGEN_TESTMAP_MAX_SIZE = 256

# Test macros (simple assertions)
def VERIFY(condition: Bool):
    assert(condition, "VERIFY failed")

def VERIFY_IS_EQUAL(a: AnyType, b: AnyType):
    assert(a == b, "VERIFY_IS_EQUAL failed")

def VERIFY_IS_APPROX(a: AnyType, b: AnyType):
    # Approximate equality: use a simple tolerance
    assert(abs(a - b) < 1e-6, "VERIFY_IS_APPROX failed")

def VERIFY_RAISES_ASSERT(code: def () -> None):
    try:
        code()
        assert(False, "Expected assertion but none raised")
    except:

# Helper to simulate CALL_SUBTEST_1 etc. (just call the function)
def CALL_SUBTEST_1(f: def () -> None):
    f()

def CALL_SUBTEST_2(f: def () -> None):
    f()

def CALL_SUBTEST_3(f: def () -> None):
    f()

def CALL_SUBTEST_4(f: def () -> None):
    f()

def CALL_SUBTEST_5(f: def () -> None):
    f()

def CALL_SUBTEST_6(f: def () -> None):
    f()

def CALL_SUBTEST_7(f: def () -> None):
    f()

def CALL_SUBTEST_8(f: def () -> None):
    f()

def CALL_SUBTEST_9(f: def () -> None):
    f()

def CALL_SUBTEST_10(f: def () -> None):
    f()

def CALL_SUBTEST_11(f: def () -> None):
    f()

# Global repeat count (from main.h)
var g_repeat: Int = 1  # placeholder

# Template functions
def map_class_vector[VectorType: AnyType](m: VectorType):
    alias Scalar = VectorType.Scalar
    var size: Index = m.size()
    var array1: Scalar* = internal.aligned_new[Scalar](size)
    var array2: Scalar* = internal.aligned_new[Scalar](size)
    var array3: Scalar* = Scalar[size+1]()
    var array3unaligned: Scalar* = (internal.UIntPtr(array3) % EIGEN_MAX_ALIGN_BYTES) == 0 ? array3 + 1 : array3
    var array4: Scalar[EIGEN_TESTMAP_MAX_SIZE] = Scalar[EIGEN_TESTMAP_MAX_SIZE]()
    Map[VectorType, AlignedMax](array1, size) = VectorType.Random(size)
    Map[VectorType, AlignedMax](array2, size) = Map[VectorType, AlignedMax](array1, size)
    Map[VectorType](array3unaligned, size) = Map[VectorType](array1, size)
    Map[VectorType](array4, size) = Map[VectorType, AlignedMax](array1, size)
    var ma1: VectorType = Map[VectorType, AlignedMax](array1, size)
    var ma2: VectorType = Map[VectorType, AlignedMax](array2, size)
    var ma3: VectorType = Map[VectorType](array3unaligned, size)
    var ma4: VectorType = Map[VectorType](array4, size)
    VERIFY_IS_EQUAL(ma1, ma2)
    VERIFY_IS_EQUAL(ma1, ma3)
    VERIFY_IS_EQUAL(ma1, ma4)
    if EIGEN_VECTORIZE:
        if internal.packet_traits[Scalar].Vectorizable and size >= AlignedMax:
            VERIFY_RAISES_ASSERT(def ():
                Map[VectorType, AlignedMax](array3unaligned, size)
            )
    internal.aligned_delete(array1, size)
    internal.aligned_delete(array2, size)
    del array3

def map_class_matrix[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var size: Index = rows * cols
    var s1: Scalar = internal.random[Scalar]()
    var array1: Scalar* = internal.aligned_new[Scalar](size)
    for i in range(size):
        array1[i] = Scalar(1)
    var array2: Scalar* = internal.aligned_new[Scalar](size)
    for i in range(size):
        array2[i] = Scalar(1)
    var array3: Scalar* = Scalar[size+1]()
    var sizep1: Index = size + 1
    for i in range(sizep1):
        array3[i] = Scalar(1)
    var array3unaligned: Scalar* = (internal.UIntPtr(array3) % EIGEN_MAX_ALIGN_BYTES) == 0 ? array3 + 1 : array3
    var array4: Scalar[256] = Scalar[256]()
    if size <= 256:
        for i in range(size):
            array4[i] = Scalar(1)
    var map1: Map[MatrixType] = Map[MatrixType](array1, rows, cols)
    var map2: Map[MatrixType, AlignedMax] = Map[MatrixType, AlignedMax](array2, rows, cols)
    var map3: Map[MatrixType] = Map[MatrixType](array3unaligned, rows, cols)
    var map4: Map[MatrixType] = Map[MatrixType](array4, rows, cols)
    VERIFY_IS_EQUAL(map1, MatrixType.Ones(rows, cols))
    VERIFY_IS_EQUAL(map2, MatrixType.Ones(rows, cols))
    VERIFY_IS_EQUAL(map3, MatrixType.Ones(rows, cols))
    map1 = MatrixType.Random(rows, cols)
    map2 = map1
    map3 = map1
    var ma1: MatrixType = map1
    var ma2: MatrixType = map2
    var ma3: MatrixType = map3
    VERIFY_IS_EQUAL(map1, map2)
    VERIFY_IS_EQUAL(map1, map3)
    VERIFY_IS_EQUAL(ma1, ma2)
    VERIFY_IS_EQUAL(ma1, ma3)
    VERIFY_IS_EQUAL(ma1, map3)
    VERIFY_IS_APPROX(s1 * map1, s1 * map2)
    VERIFY_IS_APPROX(s1 * ma1, s1 * ma2)
    VERIFY_IS_EQUAL(s1 * ma1, s1 * ma3)
    VERIFY_IS_APPROX(s1 * map1, s1 * map3)
    map2 *= s1
    map3 *= s1
    VERIFY_IS_APPROX(s1 * map1, map2)
    VERIFY_IS_APPROX(s1 * map1, map3)
    if size <= 256:
        VERIFY_IS_EQUAL(map4, MatrixType.Ones(rows, cols))
        map4 = map1
        var ma4: MatrixType = map4
        VERIFY_IS_EQUAL(map1, map4)
        VERIFY_IS_EQUAL(ma1, map4)
        VERIFY_IS_EQUAL(ma1, ma4)
        VERIFY_IS_APPROX(s1 * map1, s1 * map4)
        map4 *= s1
        VERIFY_IS_APPROX(s1 * map1, map4)
    internal.aligned_delete(array1, size)
    internal.aligned_delete(array2, size)
    del array3

def map_static_methods[VectorType: AnyType](m: VectorType):
    alias Scalar = VectorType.Scalar
    var size: Index = m.size()
    var array1: Scalar* = internal.aligned_new[Scalar](size)
    var array2: Scalar* = internal.aligned_new[Scalar](size)
    var array3: Scalar* = Scalar[size+1]()
    var array3unaligned: Scalar* = internal.UIntPtr(array3) % EIGEN_MAX_ALIGN_BYTES == 0 ? array3 + 1 : array3
    VectorType.MapAligned(array1, size) = VectorType.Random(size)
    VectorType.Map(array2, size) = VectorType.Map(array1, size)
    VectorType.Map(array3unaligned, size) = VectorType.Map(array1, size)
    var ma1: VectorType = VectorType.Map(array1, size)
    var ma2: VectorType = VectorType.MapAligned(array2, size)
    var ma3: VectorType = VectorType.Map(array3unaligned, size)
    VERIFY_IS_EQUAL(ma1, ma2)
    VERIFY_IS_EQUAL(ma1, ma3)
    internal.aligned_delete(array1, size)
    internal.aligned_delete(array2, size)
    del array3

def check_const_correctness[PlainObjectType: AnyType](_: PlainObjectType):
    alias ConstPlainObjectType = internal.add_const[PlainObjectType]
    VERIFY(not (internal.traits[Map[ConstPlainObjectType]].Flags & LvalueBit))
    VERIFY(not (internal.traits[Map[ConstPlainObjectType, AlignedMax]].Flags & LvalueBit))
    VERIFY(not (Map[ConstPlainObjectType].Flags & LvalueBit))
    VERIFY(not (Map[ConstPlainObjectType, AlignedMax].Flags & LvalueBit))

def map_not_aligned_on_scalar[Scalar: AnyType]():
    alias MatrixType = Matrix[Scalar, Dynamic, Dynamic]
    var size: Index = 11
    var array1: Scalar* = internal.aligned_new[Scalar]((size+1)*(size+1)+1)
    var array2: Scalar* = reinterpret[Scalar*](sizeof[Scalar]()/2 + std.size_t(array1))
    var map2: Map[MatrixType, 0, OuterStride[]] = Map[MatrixType, 0, OuterStride[]](array2, size, size, OuterStride[](size+1))
    var m2: MatrixType = MatrixType.Random(size, size)
    map2 = m2
    VERIFY_IS_EQUAL(m2, map2)
    alias VectorType = Matrix[Scalar, Dynamic, 1]
    var map3: Map[VectorType] = Map[VectorType](array2, size)
    var v3: VectorType = VectorType.Random(size)
    map3 = v3
    VERIFY_IS_EQUAL(v3, map3)
    internal.aligned_delete(array1, (size+1)*(size+1)+1)

def test_mapped_matrix():
    for i in range(g_repeat):
        CALL_SUBTEST_1(def ():
            map_class_vector[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]())
        )
        CALL_SUBTEST_1(def ():
            check_const_correctness[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]())
        )
        CALL_SUBTEST_2(def ():
            map_class_vector[Vector4d](Vector4d())
        )
        CALL_SUBTEST_2(def ():
            map_class_vector[VectorXd](VectorXd(13))
        )
        CALL_SUBTEST_2(def ():
            check_const_correctness[Matrix4d](Matrix4d())
        )
        CALL_SUBTEST_3(def ():
            map_class_vector[RowVector4f](RowVector4f())
        )
        CALL_SUBTEST_4(def ():
            map_class_vector[VectorXcf](VectorXcf(8))
        )
        CALL_SUBTEST_5(def ():
            map_class_vector[VectorXi](VectorXi(12))
        )
        CALL_SUBTEST_5(def ():
            check_const_correctness[VectorXi](VectorXi(12))
        )
        CALL_SUBTEST_1(def ():
            map_class_matrix[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]())
        )
        CALL_SUBTEST_2(def ():
            map_class_matrix[Matrix4d](Matrix4d())
        )
        CALL_SUBTEST_11(def ():
            map_class_matrix[Matrix[float32, 3, 5]](Matrix[float32, 3, 5]())
        )
        CALL_SUBTEST_4(def ():
            map_class_matrix[MatrixXcf](MatrixXcf(internal.random[Int](1,10), internal.random[Int](1,10)))
        )
        CALL_SUBTEST_5(def ():
            map_class_matrix[MatrixXi](MatrixXi(internal.random[Int](1,10), internal.random[Int](1,10)))
        )
        CALL_SUBTEST_6(def ():
            map_static_methods[Matrix[float64, 1, 1]](Matrix[float64, 1, 1]())
        )
        CALL_SUBTEST_7(def ():
            map_static_methods[Vector3f](Vector3f())
        )
        CALL_SUBTEST_8(def ():
            map_static_methods[RowVector3d](RowVector3d())
        )
        CALL_SUBTEST_9(def ():
            map_static_methods[VectorXcd](VectorXcd(8))
        )
        CALL_SUBTEST_10(def ():
            map_static_methods[VectorXf](VectorXf(12))
        )
        CALL_SUBTEST_11(def ():
            map_not_aligned_on_scalar[float64]()
        )