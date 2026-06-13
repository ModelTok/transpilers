from main import *
from Eigen import *

def product_extra[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RowVectorType = Matrix[Scalar, 1, Dynamic]
    alias ColVectorType = Matrix[Scalar, Dynamic, 1]
    alias OtherMajorMatrixType = Matrix[Scalar, Dynamic, Dynamic, MatrixType.Flags & RowMajorBit]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    var mzero = MatrixType.Zero(rows, cols)
    var identity = MatrixType.Identity(rows, rows)
    var square = MatrixType.Random(rows, rows)
    var res = MatrixType.Random(rows, rows)
    var square2 = MatrixType.Random(cols, cols)
    var res2 = MatrixType.Random(cols, cols)
    var v1 = RowVectorType.Random(rows)
    var vrres = RowVectorType(rows)
    var vc2 = ColVectorType.Random(cols)
    var vcres = ColVectorType(cols)
    var tm1 = OtherMajorMatrixType(m1)
    var s1 = internal.random[Scalar]()
    var s2 = internal.random[Scalar]()
    var s3 = internal.random[Scalar]()
    VERIFY_IS_APPROX(m3.noalias() = m1 * m2.adjoint(), m1 * m2.adjoint().eval())
    VERIFY_IS_APPROX(m3.noalias() = m1.adjoint() * square.adjoint(), m1.adjoint().eval() * square.adjoint().eval())
    VERIFY_IS_APPROX(m3.noalias() = m1.adjoint() * m2, m1.adjoint().eval() * m2)
    VERIFY_IS_APPROX(m3.noalias() = (s1 * m1.adjoint()) * m2, (s1 * m1.adjoint()).eval() * m2)
    VERIFY_IS_APPROX(m3.noalias() = ((s1 * m1).adjoint()) * m2, (numext.conj(s1) * m1.adjoint()).eval() * m2)
    VERIFY_IS_APPROX(m3.noalias() = (- m1.adjoint() * s1) * (s3 * m2), (- m1.adjoint()  * s1).eval() * (s3 * m2).eval())
    VERIFY_IS_APPROX(m3.noalias() = (s2 * m1.adjoint() * s1) * m2, (s2 * m1.adjoint()  * s1).eval() * m2)
    VERIFY_IS_APPROX(m3.noalias() = (-m1*s2) * s1*m2.adjoint(), (-m1*s2).eval() * (s1*m2.adjoint()).eval())
    VERIFY_IS_APPROX(m1.adjoint() * (s1*m2).conjugate(), (m1.adjoint()).eval() * ((s1*m2).conjugate()).eval())
    VERIFY_IS_APPROX((-m1.conjugate() * s2) * (s1 * vc2), (-m1.conjugate()*s2).eval() * (s1 * vc2).eval())
    VERIFY_IS_APPROX((-m1 * s2) * (s1 * vc2.conjugate()), (-m1*s2).eval() * (s1 * vc2.conjugate()).eval())
    VERIFY_IS_APPROX((-m1.conjugate() * s2) * (s1 * vc2.conjugate()), (-m1.conjugate()*s2).eval() * (s1 * vc2.conjugate()).eval())
    VERIFY_IS_APPROX((s1 * vc2.transpose()) * (-m1.adjoint() * s2), (s1 * vc2.transpose()).eval() * (-m1.adjoint()*s2).eval())
    VERIFY_IS_APPROX((s1 * vc2.adjoint()) * (-m1.transpose() * s2), (s1 * vc2.adjoint()).eval() * (-m1.transpose()*s2).eval())
    VERIFY_IS_APPROX((s1 * vc2.adjoint()) * (-m1.adjoint() * s2), (s1 * vc2.adjoint()).eval() * (-m1.adjoint()*s2).eval())
    VERIFY_IS_APPROX((-m1.adjoint() * s2) * (s1 * v1.transpose()), (-m1.adjoint()*s2).eval() * (s1 * v1.transpose()).eval())
    VERIFY_IS_APPROX((-m1.transpose() * s2) * (s1 * v1.adjoint()), (-m1.transpose()*s2).eval() * (s1 * v1.adjoint()).eval())
    VERIFY_IS_APPROX((-m1.adjoint() * s2) * (s1 * v1.adjoint()), (-m1.adjoint()*s2).eval() * (s1 * v1.adjoint()).eval())
    VERIFY_IS_APPROX((s1 * v1) * (-m1.conjugate() * s2), (s1 * v1).eval() * (-m1.conjugate()*s2).eval())
    VERIFY_IS_APPROX((s1 * v1.conjugate()) * (-m1 * s2), (s1 * v1.conjugate()).eval() * (-m1*s2).eval())
    VERIFY_IS_APPROX((s1 * v1.conjugate()) * (-m1.conjugate() * s2), (s1 * v1.conjugate()).eval() * (-m1.conjugate()*s2).eval())
    VERIFY_IS_APPROX((-m1.adjoint() * s2) * (s1 * v1.adjoint()), (-m1.adjoint()*s2).eval() * (s1 * v1.adjoint()).eval())
    var i = internal.random[Index](0, m1.rows()-2)
    var j = internal.random[Index](0, m1.cols()-2)
    var r = internal.random[Index](1, m1.rows()-i)
    var c = internal.random[Index](1, m1.cols()-j)
    var i2 = internal.random[Index](0, m1.rows()-1)
    var j2 = internal.random[Index](0, m1.cols()-1)
    VERIFY_IS_APPROX(m1.col(j2).adjoint() * m1.block(0, j, m1.rows(), c), m1.col(j2).adjoint().eval() * m1.block(0, j, m1.rows(), c).eval())
    VERIFY_IS_APPROX(m1.block(i, 0, r, m1.cols()) * m1.row(i2).adjoint(), m1.block(i, 0, r, m1.cols()).eval() * m1.row(i2).adjoint().eval())
    var tmp = m1 * m1.adjoint() * s1
    VERIFY_IS_APPROX(tmp, m1 * m1.adjoint() * s1)
    var a1 = Array[Scalar, Dynamic, 1](m1 * vc2)
    VERIFY_IS_APPROX(a1.matrix(), m1*vc2)
    var a2 = Array[Scalar, Dynamic, 1](s1 * (m1 * vc2))
    VERIFY_IS_APPROX(a2.matrix(), s1*m1*vc2)
    var a3 = Array[Scalar, 1, Dynamic](v1 * m1)
    VERIFY_IS_APPROX(a3.matrix(), v1*m1)
    var a4 = Array[Scalar, Dynamic, Dynamic](m1 * m2.adjoint())
    VERIFY_IS_APPROX(a4.matrix(), m1*m2.adjoint())

def mat_mat_scalar_scalar_product():
    var dNdxy = Eigen.Matrix2Xd(2, 3)
    dNdxy << -0.5, 0.5, 0, -0.3, 0, 0.3
    var det = 6.0
    var wt = 0.5
    VERIFY_IS_APPROX(dNdxy.transpose()*dNdxy*det*wt, det*wt*dNdxy.transpose()*dNdxy)

def zero_sized_objects[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias PacketSize = internal.packet_traits[Scalar].size
    alias PacketSize1 = PacketSize>1 ? PacketSize-1 : 1
    var rows = m.rows()
    var cols = m.cols()
    {
        var res = MatrixType()
        var a = MatrixType(rows, 0)
        var b = MatrixType(0, cols)
        VERIFY_IS_APPROX((res=a*b), MatrixType.Zero(rows, cols))
        VERIFY_IS_APPROX((res=a*a.transpose()), MatrixType.Zero(rows, rows))
        VERIFY_IS_APPROX((res=b.transpose()*b), MatrixType.Zero(cols, cols))
        VERIFY_IS_APPROX((res=b.transpose()*a.transpose()), MatrixType.Zero(cols, rows))
    }
    {
        var res = MatrixType()
        var a = MatrixType(rows, cols)
        var b = MatrixType(cols, 0)
        res = a*b
        VERIFY(res.rows()==rows and res.cols()==0)
        b.resize(0, rows)
        res = b*a
        VERIFY(res.rows()==0 and res.cols()==cols)
    }
    {
        var a = Matrix[Scalar, PacketSize, 0]()
        var b = Matrix[Scalar, 0, 1]()
        var res = Matrix[Scalar, PacketSize, 1]()
        VERIFY_IS_APPROX((res=a*b), MatrixType.Zero(PacketSize, 1))
        VERIFY_IS_APPROX((res=a.lazyProduct(b)), MatrixType.Zero(PacketSize, 1))
    }
    {
        var a = Matrix[Scalar, PacketSize1, 0]()
        var b = Matrix[Scalar, 0, 1]()
        var res = Matrix[Scalar, PacketSize1, 1]()
        VERIFY_IS_APPROX((res=a*b), MatrixType.Zero(PacketSize1, 1))
        VERIFY_IS_APPROX((res=a.lazyProduct(b)), MatrixType.Zero(PacketSize1, 1))
    }
    {
        var a = Matrix[Scalar, PacketSize, Dynamic](PacketSize, 0)
        var b = Matrix[Scalar, Dynamic, 1](0, 1)
        var res = Matrix[Scalar, PacketSize, 1]()
        VERIFY_IS_APPROX((res=a*b), MatrixType.Zero(PacketSize, 1))
        VERIFY_IS_APPROX((res=a.lazyProduct(b)), MatrixType.Zero(PacketSize, 1))
    }
    {
        var a = Matrix[Scalar, PacketSize1, Dynamic](PacketSize1, 0)
        var b = Matrix[Scalar, Dynamic, 1](0, 1)
        var res = Matrix[Scalar, PacketSize1, 1]()
        VERIFY_IS_APPROX((res=a*b), MatrixType.Zero(PacketSize1, 1))
        VERIFY_IS_APPROX((res=a.lazyProduct(b)), MatrixType.Zero(PacketSize1, 1))
    }

def bug_127[_: Int]():
    var a = Matrix[float32, 1, Dynamic, RowMajor, 1, 5](1, 4)
    var b = Matrix[float32, Dynamic, Dynamic, ColMajor, 5, 1](4, 0)
    a*b

def bug_817[_ : Int]():
    var B = ArrayXXf.Random(10, 10)
    var C = ArrayXXf()
    var x = VectorXf.Random(10)
    C = (x.transpose()*B.matrix())
    B = (x.transpose()*B.matrix())
    VERIFY_IS_APPROX(B, C)

def unaligned_objects[_ : Int]():
    for m in range(450, 460):
        for n in range(8, 12):
            var M = MatrixXf(m, n)
            var v1 = VectorXf(n)
            var r1 = VectorXf(500)
            var v2 = RowVectorXf(m)
            var r2 = RowVectorXf(16)
            M.setRandom()
            v1.setRandom()
            v2.setRandom()
            for o in range(0, 4):
                r1.segment(o, m).noalias() = M * v1
                VERIFY_IS_APPROX(r1.segment(o, m), M * MatrixXf(v1))
                r2.segment(o, n).noalias() = v2 * M
                VERIFY_IS_APPROX(r2.segment(o, n), MatrixXf(v2) * M)

def test_compute_block_size[T: AnyType](m: Index, n: Index, k: Index) -> Index:
    var mc = m
    var nc = n
    var kc = k
    internal.computeProductBlockingSizes[T, T](kc, mc, nc)
    return kc+mc+nc

def compute_block_size[T: AnyType]() -> Index:
    var ret = 0
    ret += test_compute_block_size[T](0, 1, 1)
    ret += test_compute_block_size[T](1, 0, 1)
    ret += test_compute_block_size[T](1, 1, 0)
    ret += test_compute_block_size[T](0, 0, 1)
    ret += test_compute_block_size[T](0, 1, 0)
    ret += test_compute_block_size[T](1, 0, 0)
    ret += test_compute_block_size[T](0, 0, 0)
    return ret

def aliasing_with_resize[_ : AnyType]():
    var m = internal.random[Index](10, 50)
    var n = internal.random[Index](10, 50)
    var A = MatrixXd()
    var B = MatrixXd()
    var C = MatrixXd(m, n)
    var D = MatrixXd(m, m)
    var a = VectorXd()
    var b = VectorXd()
    var c = VectorXd(n)
    C.setRandom()
    D.setRandom()
    c.setRandom()
    var s = internal.random[float64](1, 10)
    A = C
    B = A * A.transpose()
    A = A * A.transpose()
    VERIFY_IS_APPROX(A, B)
    A = C
    B = (A * A.transpose())/s
    A = (A * A.transpose())/s
    VERIFY_IS_APPROX(A, B)
    A = C
    B = (A * A.transpose()) + D
    A = (A * A.transpose()) + D
    VERIFY_IS_APPROX(A, B)
    A = C
    B = D + (A * A.transpose())
    A = D + (A * A.transpose())
    VERIFY_IS_APPROX(A, B)
    A = C
    B = s * (A * A.transpose())
    A = s * (A * A.transpose())
    VERIFY_IS_APPROX(A, B)
    A = C
    a = c
    b = (A * a)/s
    a = (A * a)/s
    VERIFY_IS_APPROX(a, b)

def bug_1308[_ : Int]():
    var n = 10
    var r = MatrixXd(n, n)
    var v = VectorXd.Random(n)
    r = v * RowVectorXd.Ones(n)
    VERIFY_IS_APPROX(r, v.rowwise().replicate(n))
    r = VectorXd.Ones(n) * v.transpose()
    VERIFY_IS_APPROX(r, v.rowwise().replicate(n).transpose())
    var ones44 = Matrix4d.Ones()
    var m44 = Matrix4d.Ones() * Matrix4d.Ones()
    VERIFY_IS_APPROX(m44, Matrix4d.Constant(4))
    VERIFY_IS_APPROX(m44.noalias()=ones44*Matrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(m44.noalias()=ones44.transpose()*Matrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(m44.noalias()=Matrix4d.Ones()*ones44, Matrix4d.Constant(4))
    VERIFY_IS_APPROX(m44.noalias()=Matrix4d.Ones()*ones44.transpose(), Matrix4d.Constant(4))
    alias RMatrix4d = Matrix[float64, 4, 4, RowMajor]
    var r44 = Matrix4d.Ones() * Matrix4d.Ones()
    VERIFY_IS_APPROX(r44, Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=ones44*Matrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=ones44.transpose()*Matrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=Matrix4d.Ones()*ones44, Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=Matrix4d.Ones()*ones44.transpose(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=ones44*RMatrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=ones44.transpose()*RMatrix4d.Ones(), Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=RMatrix4d.Ones()*ones44, Matrix4d.Constant(4))
    VERIFY_IS_APPROX(r44.noalias()=RMatrix4d.Ones()*ones44.transpose(), Matrix4d.Constant(4))
    m44.setOnes()
    r44.setZero()
    VERIFY_IS_APPROX(r44.noalias() += m44.row(0).transpose() * RowVector4d.Ones(), ones44)
    r44.setZero()
    VERIFY_IS_APPROX(r44.noalias() += m44.col(0) * RowVector4d.Ones(), ones44)
    r44.setZero()
    VERIFY_IS_APPROX(r44.noalias() += Vector4d.Ones() * m44.row(0), ones44)
    r44.setZero()
    VERIFY_IS_APPROX(r44.noalias() += Vector4d.Ones() * m44.col(0).transpose(), ones44)

def test_product_extra():
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(product_extra[MatrixXf](MatrixXf(internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2(product_extra[MatrixXd](MatrixXd(internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2(mat_mat_scalar_scalar_product())
        CALL_SUBTEST_3(product_extra[MatrixXcf](MatrixXcf(internal.random[int](1, EIGEN_TEST_MAX_SIZE/2), internal.random[int](1, EIGEN_TEST_MAX_SIZE/2))))
        CALL_SUBTEST_4(product_extra[MatrixXcd](MatrixXcd(internal.random[int](1, EIGEN_TEST_MAX_SIZE/2), internal.random[int](1, EIGEN_TEST_MAX_SIZE/2))))
        CALL_SUBTEST_1(zero_sized_objects[MatrixXf](MatrixXf(internal.random[int](1, EIGEN_TEST_MAX_SIZE), internal.random[int](1, EIGEN_TEST_MAX_SIZE))))
    CALL_SUBTEST_5(bug_127[0]())
    CALL_SUBTEST_5(bug_817[0]())
    CALL_SUBTEST_5(bug_1308[0]())
    CALL_SUBTEST_6(unaligned_objects[0]())
    CALL_SUBTEST_7(compute_block_size[float32]())
    CALL_SUBTEST_7(compute_block_size[float64]())
    CALL_SUBTEST_7(compute_block_size[ComplexFloat64]())
    CALL_SUBTEST_8(aliasing_with_resize[None]())