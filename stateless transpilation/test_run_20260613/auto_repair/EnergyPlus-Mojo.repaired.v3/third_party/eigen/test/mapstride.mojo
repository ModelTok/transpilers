from main import VERIFY, VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6
from Eigen import *
from internal import aligned_new, aligned_delete, random, IntPtr, UIntPtr, packet_traits, NumTraits

alias Aligned = 0
alias Unaligned = 1
alias Dynamic = -1
alias EIGEN_MAX_ALIGN_BYTES = 32  # typical value

def map_class_vector[Alignment: Int, VectorType: AnyType](m: VectorType):
    typealias Scalar = VectorType.Scalar
    var size: Index = m.size()
    var v = VectorType.Random(size)
    var arraysize: Index = 3 * size
    var a_array = aligned_new[Scalar](arraysize + 1)
    var array = a_array
    if Alignment != Aligned:
        array = (Scalar *)(IntPtr(a_array) + (packet_traits[Scalar].AlignedOnScalar ? sizeof(Scalar) : sizeof(NumTraits[Scalar].Real)))
    # scope 1
    var map = Map[VectorType, Alignment, InnerStride[3]](array, size)
    map = v
    for i in range(size):
        VERIFY(array[3 * i] == v[i])
        VERIFY(map[i] == v[i])
    # scope 2
    var map2 = Map[VectorType, Unaligned, InnerStride[Dynamic]](array, size, InnerStride[Dynamic](2))
    map2 = v
    for i in range(size):
        VERIFY(array[2 * i] == v[i])
        VERIFY(map2[i] == v[i])
    aligned_delete(a_array, arraysize + 1)

def map_class_matrix[Alignment: Int, MatrixType: AnyType](_m: MatrixType):
    typealias Scalar = MatrixType.Scalar
    var rows: Index = _m.rows()
    var cols: Index = _m.cols()
    var m = MatrixType.Random(rows, cols)
    var s1 = random[Scalar]()
    var arraysize: Index = 4 * (rows + 4) * (cols + 4)
    var a_array1 = aligned_new[Scalar](arraysize + 1)
    var array1 = a_array1
    if Alignment != Aligned:
        array1 = (Scalar *)(IntPtr(a_array1) + (packet_traits[Scalar].AlignedOnScalar ? sizeof(Scalar) : sizeof(NumTraits[Scalar].Real)))
    var a_array2: Scalar[256]
    var array2 = a_array2
    if Alignment != Aligned:
        array2 = (Scalar *)(IntPtr(a_array2) + (packet_traits[Scalar].AlignedOnScalar ? sizeof(Scalar) : sizeof(NumTraits[Scalar].Real)))
    else:
        array2 = (Scalar *)((UIntPtr(a_array2) + EIGEN_MAX_ALIGN_BYTES - 1) // EIGEN_MAX_ALIGN_BYTES * EIGEN_MAX_ALIGN_BYTES)
    var maxsize2: Index = a_array2 - array2 + 256
    for k in range(2):
        if k == 1 and (m.innerSize() + 1) * m.outerSize() > maxsize2:
            break
        var array = (k == 0 ? array1 : array2)
        var map = Map[MatrixType, Alignment, OuterStride[Dynamic]](array, rows, cols, OuterStride[Dynamic](m.innerSize() + 1))
        map = m
        VERIFY(map.outerStride() == map.innerSize() + 1)
        for i in range(m.outerSize()):
            for j in range(m.innerSize()):
                VERIFY(array[map.outerStride() * i + j] == m.coeffByOuterInner(i, j))
                VERIFY(map.coeffByOuterInner(i, j) == m.coeffByOuterInner(i, j))
        VERIFY_IS_APPROX(s1 * map, s1 * m)
        map *= s1
        VERIFY_IS_APPROX(map, s1 * m)
    for k in range(2):
        if k == 1 and (m.innerSize() + 4) * m.outerSize() > maxsize2:
            break
        var array = (k == 0 ? array1 : array2)
        alias InnerSize = MatrixType.InnerSizeAtCompileTime
        alias OuterStrideAtCompileTime = InnerSize == Dynamic ? Dynamic : InnerSize + 4
        var map = Map[MatrixType, Alignment, OuterStride[OuterStrideAtCompileTime]](
            array, rows, cols, OuterStride[OuterStrideAtCompileTime](m.innerSize() + 4))
        map = m
        VERIFY(map.outerStride() == map.innerSize() + 4)
        for i in range(m.outerSize()):
            for j in range(m.innerSize()):
                VERIFY(array[map.outerStride() * i + j] == m.coeffByOuterInner(i, j))
                VERIFY(map.coeffByOuterInner(i, j) == m.coeffByOuterInner(i, j))
        VERIFY_IS_APPROX(s1 * map, s1 * m)
        map *= s1
        VERIFY_IS_APPROX(map, s1 * m)
    for k in range(2):
        if k == 1 and (2 * m.innerSize() + 1) * (m.outerSize() * 2) > maxsize2:
            break
        var array = (k == 0 ? array1 : array2)
        var map = Map[MatrixType, Alignment, Stride[Dynamic, Dynamic]](
            array, rows, cols, Stride[Dynamic, Dynamic](2 * m.innerSize() + 1, 2))
        map = m
        VERIFY(map.outerStride() == 2 * map.innerSize() + 1)
        VERIFY(map.innerStride() == 2)
        for i in range(m.outerSize()):
            for j in range(m.innerSize()):
                VERIFY(array[map.outerStride() * i + map.innerStride() * j] == m.coeffByOuterInner(i, j))
                VERIFY(map.coeffByOuterInner(i, j) == m.coeffByOuterInner(i, j))
        VERIFY_IS_APPROX(s1 * map, s1 * m)
        map *= s1
        VERIFY_IS_APPROX(map, s1 * m)
    for k in range(2):
        if k == 1 and (m.innerSize() * 2) * m.outerSize() > maxsize2:
            break
        var array = (k == 0 ? array1 : array2)
        var map = Map[MatrixType, Alignment, InnerStride[Dynamic]](array, rows, cols, InnerStride[Dynamic](2))
        map = m
        VERIFY(map.outerStride() == map.innerSize() * 2)
        for i in range(m.outerSize()):
            for j in range(m.innerSize()):
                VERIFY(array[map.innerSize() * i * 2 + j * 2] == m.coeffByOuterInner(i, j))
                VERIFY(map.coeffByOuterInner(i, j) == m.coeffByOuterInner(i, j))
        VERIFY_IS_APPROX(s1 * map, s1 * m)
        map *= s1
        VERIFY_IS_APPROX(map, s1 * m)
    aligned_delete(a_array1, arraysize + 1)

def bug1453[_0: Int]():
    var data = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]
    typealias RowMatrixXi = Matrix[Int, Dynamic, Dynamic, RowMajor]
    typealias ColMatrix23i = Matrix[Int, 2, 3, ColMajor]
    typealias ColMatrix32i = Matrix[Int, 3, 2, ColMajor]
    typealias RowMatrix23i = Matrix[Int, 2, 3, RowMajor]
    typealias RowMatrix32i = Matrix[Int, 3, 2, RowMajor]
    VERIFY_IS_APPROX(MatrixXi.Map(data, 2, 3, InnerStride[2]()), MatrixXi.Map(data, 2, 3, Stride[4,2]()))
    VERIFY_IS_APPROX(MatrixXi.Map(data, 2, 3, InnerStride[Dynamic](2)), MatrixXi.Map(data, 2, 3, Stride[4,2]()))
    VERIFY_IS_APPROX(MatrixXi.Map(data, 3, 2, InnerStride[2]()), MatrixXi.Map(data, 3, 2, Stride[6,2]()))
    VERIFY_IS_APPROX(MatrixXi.Map(data, 3, 2, InnerStride[Dynamic](2)), MatrixXi.Map(data, 3, 2, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrixXi.Map(data, 2, 3, InnerStride[2]()), RowMatrixXi.Map(data, 2, 3, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrixXi.Map(data, 2, 3, InnerStride[Dynamic](2)), RowMatrixXi.Map(data, 2, 3, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrixXi.Map(data, 3, 2, InnerStride[2]()), RowMatrixXi.Map(data, 3, 2, Stride[4,2]()))
    VERIFY_IS_APPROX(RowMatrixXi.Map(data, 3, 2, InnerStride[Dynamic](2)), RowMatrixXi.Map(data, 3, 2, Stride[4,2]()))
    VERIFY_IS_APPROX(ColMatrix23i.Map(data, InnerStride[2]()), MatrixXi.Map(data, 2, 3, Stride[4,2]()))
    VERIFY_IS_APPROX(ColMatrix23i.Map(data, InnerStride[Dynamic](2)), MatrixXi.Map(data, 2, 3, Stride[4,2]()))
    VERIFY_IS_APPROX(ColMatrix32i.Map(data, InnerStride[2]()), MatrixXi.Map(data, 3, 2, Stride[6,2]()))
    VERIFY_IS_APPROX(ColMatrix32i.Map(data, InnerStride[Dynamic](2)), MatrixXi.Map(data, 3, 2, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrix23i.Map(data, InnerStride[2]()), RowMatrixXi.Map(data, 2, 3, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrix23i.Map(data, InnerStride[Dynamic](2)), RowMatrixXi.Map(data, 2, 3, Stride[6,2]()))
    VERIFY_IS_APPROX(RowMatrix32i.Map(data, InnerStride[2]()), RowMatrixXi.Map(data, 3, 2, Stride[4,2]()))
    VERIFY_IS_APPROX(RowMatrix32i.Map(data, InnerStride[Dynamic](2)), RowMatrixXi.Map(data, 3, 2, Stride[4,2]()))

def test_mapstride():
    for i in range(g_repeat):
        var maxn: Int = 30
        CALL_SUBTEST_1(fn() => map_class_vector[Aligned](Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_1(fn() => map_class_vector[Unaligned](Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_2(fn() => map_class_vector[Aligned](Vector4d()))
        CALL_SUBTEST_2(fn() => map_class_vector[Unaligned](Vector4d()))
        CALL_SUBTEST_3(fn() => map_class_vector[Aligned](RowVector4f()))
        CALL_SUBTEST_3(fn() => map_class_vector[Unaligned](RowVector4f()))
        CALL_SUBTEST_4(fn() => map_class_vector[Aligned](VectorXcf(random[Int](1, maxn))))
        CALL_SUBTEST_4(fn() => map_class_vector[Unaligned](VectorXcf(random[Int](1, maxn))))
        CALL_SUBTEST_5(fn() => map_class_vector[Aligned](VectorXi(random[Int](1, maxn))))
        CALL_SUBTEST_5(fn() => map_class_vector[Unaligned](VectorXi(random[Int](1, maxn))))
        CALL_SUBTEST_1(fn() => map_class_matrix[Aligned](Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_1(fn() => map_class_matrix[Unaligned](Matrix[Float32, 1, 1]()))
        CALL_SUBTEST_2(fn() => map_class_matrix[Aligned](Matrix4d()))
        CALL_SUBTEST_2(fn() => map_class_matrix[Unaligned](Matrix4d()))
        CALL_SUBTEST_3(fn() => map_class_matrix[Aligned](Matrix[Float32, 3, 5]()))
        CALL_SUBTEST_3(fn() => map_class_matrix[Unaligned](Matrix[Float32, 3, 5]()))
        CALL_SUBTEST_3(fn() => map_class_matrix[Aligned](Matrix[Float32, 4, 8]()))
        CALL_SUBTEST_3(fn() => map_class_matrix[Unaligned](Matrix[Float32, 4, 8]()))
        CALL_SUBTEST_4(fn() => map_class_matrix[Aligned](MatrixXcf(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_4(fn() => map_class_matrix[Unaligned](MatrixXcf(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_5(fn() => map_class_matrix[Aligned](MatrixXi(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_5(fn() => map_class_matrix[Unaligned](MatrixXi(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_6(fn() => map_class_matrix[Aligned](MatrixXcd(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_6(fn() => map_class_matrix[Unaligned](MatrixXcd(random[Int](1, maxn), random[Int](1, maxn))))
        CALL_SUBTEST_5(fn() => bug1453[0]())
        var _ = maxn  # TEST_SET_BUT_UNUSED_VARIABLE