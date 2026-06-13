from main import *

module Eigen:
    @def prod[Lhs: AnyType, Rhs: AnyType](lhs: Lhs, rhs: Rhs) -> Product[Lhs, Rhs]:
        return Product[Lhs, Rhs](lhs, rhs)

    @def lazyprod[Lhs: AnyType, Rhs: AnyType](lhs: Lhs, rhs: Rhs) -> Product[Lhs, Rhs, LazyProduct]:
        return Product[Lhs, Rhs, LazyProduct](lhs, rhs)

    @def copy_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: EigenBase[DstXprType], src: SrcXprType) -> DstXprType&:
        call_assignment(dst.const_cast_derived(), src.derived(), internal.assign_op[DstXprType.Scalar, SrcXprType.Scalar]())
        return dst.const_cast_derived()

    @def copy_using_evaluator[DstXprType: AnyType, StorageBase: AnyType, SrcXprType: AnyType](dst: NoAlias[DstXprType, StorageBase], src: SrcXprType) -> DstXprType&:
        call_assignment(dst, src.derived(), internal.assign_op[DstXprType.Scalar, SrcXprType.Scalar]())
        return dst.expression()

    @def copy_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: PlainObjectBase[DstXprType], src: SrcXprType) -> DstXprType&:
        #ifdef EIGEN_NO_AUTOMATIC_RESIZING
        eigen_assert((dst.size()==0 || (IsVectorAtCompileTime ? (dst.size() == src.size())
                                                              : (dst.rows() == src.rows() && dst.cols() == src.cols())))
                    && "Size mismatch. Automatic resizing is disabled because EIGEN_NO_AUTOMATIC_RESIZING is defined");
        #else
        dst.const_cast_derived().resizeLike(src.derived())
        #endif
        call_assignment(dst.const_cast_derived(), src.derived(), internal.assign_op[DstXprType.Scalar, SrcXprType.Scalar]())
        return dst.const_cast_derived()

    @def add_assign_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: DstXprType, src: SrcXprType):
        alias Scalar = DstXprType.Scalar
        call_assignment(const_cast[DstXprType&](dst), src.derived(), internal.add_assign_op[Scalar, SrcXprType.Scalar]())

    @def subtract_assign_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: DstXprType, src: SrcXprType):
        alias Scalar = DstXprType.Scalar
        call_assignment(const_cast[DstXprType&](dst), src.derived(), internal.sub_assign_op[Scalar, SrcXprType.Scalar]())

    @def multiply_assign_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: DstXprType, src: SrcXprType):
        alias Scalar = DstXprType.Scalar
        call_assignment(dst.const_cast_derived(), src.derived(), internal.mul_assign_op[Scalar, SrcXprType.Scalar]())

    @def divide_assign_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: DstXprType, src: SrcXprType):
        alias Scalar = DstXprType.Scalar
        call_assignment(dst.const_cast_derived(), src.derived(), internal.div_assign_op[Scalar, SrcXprType.Scalar]())

    @def swap_using_evaluator[DstXprType: AnyType, SrcXprType: AnyType](dst: DstXprType, src: SrcXprType):
        alias Scalar = DstXprType.Scalar
        call_assignment(dst.const_cast_derived(), src.const_cast_derived(), internal.swap_assign_op[Scalar]())

    module internal:
        @def call_assignment[Dst: AnyType, StorageBase: AnyType, Src: AnyType, Func: AnyType](dst: NoAlias[Dst, StorageBase], src: Src, func: Func):
            call_assignment_no_alias(dst.expression(), src, func)

def get_cost[XprType: AnyType](xpr: XprType) -> Int64:
    return Eigen.internal.evaluator[XprType].CoeffReadCost

def VERIFY_IS_APPROX_EVALUATOR[DEST: AnyType, EXPR: AnyType](dest: DEST, expr: EXPR):
    VERIFY_IS_APPROX(copy_using_evaluator(dest, expr), expr.eval())

def VERIFY_IS_APPROX_EVALUATOR2[DEST: AnyType, EXPR: AnyType, REF: AnyType](dest: DEST, expr: EXPR, ref: REF):
    VERIFY_IS_APPROX(copy_using_evaluator(dest, expr), ref.eval())

def test_evaluators():
    var v: Vector2d = Vector2d.Random()
    let v_const: Vector2d = v
    var v2: Vector2d
    var w: RowVector2d
    VERIFY_IS_APPROX_EVALUATOR(v2, v)
    VERIFY_IS_APPROX_EVALUATOR(v2, v_const)
    VERIFY_IS_APPROX_EVALUATOR(w, v.transpose())  # Transpose as rvalue
    VERIFY_IS_APPROX_EVALUATOR(w, v_const.transpose())
    copy_using_evaluator(w.transpose(), v)  # Transpose as lvalue
    VERIFY_IS_APPROX(w, v.transpose().eval())
    copy_using_evaluator(w.transpose(), v_const)
    VERIFY_IS_APPROX(w, v_const.transpose().eval())
    {
        var a: ArrayXXf = ArrayXXf(2, 3)
        var b: ArrayXXf = ArrayXXf(3, 2)
        a << 1,2,3, 4,5,6
        let a_const: ArrayXXf = a
        VERIFY_IS_APPROX_EVALUATOR(b, a.transpose())
        VERIFY_IS_APPROX_EVALUATOR(b, a_const.transpose())
        copy_using_evaluator(w, RowVector2d.Random())
        VERIFY((w.array() >= -1).all() and (w.array() <= 1).all())  # not easy to test ...
        VERIFY_IS_APPROX_EVALUATOR(w, RowVector2d.Zero())
        VERIFY_IS_APPROX_EVALUATOR(w, RowVector2d.Constant(3))
        VERIFY_IS_APPROX_EVALUATOR(w, Vector2d.Zero().transpose())
    }
    {
        var s: Int32 = internal.random[Int32](1, 100)
        var a: MatrixXf = MatrixXf(s, s)
        var b: MatrixXf = MatrixXf(s, s)
        var c: MatrixXf = MatrixXf(s, s)
        var d: MatrixXf = MatrixXf(s, s)
        a.setRandom()
        b.setRandom()
        c.setRandom()
        d.setRandom()
        VERIFY_IS_APPROX_EVALUATOR(d, (a + b))
        VERIFY_IS_APPROX_EVALUATOR(d, (a + b).transpose())
        VERIFY_IS_APPROX_EVALUATOR2(d, prod(a, b), a * b)
        VERIFY_IS_APPROX_EVALUATOR2(d.noalias(), prod(a, b), a * b)
        VERIFY_IS_APPROX_EVALUATOR2(d, prod(a, b) + c, a * b + c)
        VERIFY_IS_APPROX_EVALUATOR2(d, s * prod(a, b), s * a * b)
        VERIFY_IS_APPROX_EVALUATOR2(d, prod(a, b).transpose(), (a * b).transpose())
        VERIFY_IS_APPROX_EVALUATOR2(d, prod(a, b) + prod(b, c), a * b + b * c)
        c = a * a
        copy_using_evaluator(a, prod(a, a))
        VERIFY_IS_APPROX(a, c)
        d = c
        add_assign_using_evaluator(c.noalias(), prod(a, b))
        d.noalias() += a * b
        VERIFY_IS_APPROX(c, d)
        d = c
        subtract_assign_using_evaluator(c.noalias(), prod(a, b))
        d.noalias() -= a * b
        VERIFY_IS_APPROX(c, d)
    }
    {
        var s: Int32 = internal.random[Int32](1, 100)
        var m11: Matrix[Float32, 1, 1] = Matrix[Float32, 1, 1]()
        var res11: Matrix[Float32, 1, 1] = Matrix[Float32, 1, 1]()
        m11.setRandom(1, 1)
        var m14: Matrix[Float32, 1, 4] = Matrix[Float32, 1, 4]()
        var res14: Matrix[Float32, 1, 4] = Matrix[Float32, 1, 4]()
        m14.setRandom(1, 4)
        var m1X: Matrix[Float32, 1, Dynamic] = Matrix[Float32, 1, Dynamic]()
        var res1X: Matrix[Float32, 1, Dynamic] = Matrix[Float32, 1, Dynamic]()
        m1X.setRandom(1, s)
        var m41: Matrix[Float32, 4, 1] = Matrix[Float32, 4, 1]()
        var res41: Matrix[Float32, 4, 1] = Matrix[Float32, 4, 1]()
        m41.setRandom(4, 1)
        var m44: Matrix[Float32, 4, 4] = Matrix[Float32, 4, 4]()
        var res44: Matrix[Float32, 4, 4] = Matrix[Float32, 4, 4]()
        m44.setRandom(4, 4)
        var m4X: Matrix[Float32, 4, Dynamic] = Matrix[Float32, 4, Dynamic]()
        var res4X: Matrix[Float32, 4, Dynamic] = Matrix[Float32, 4, Dynamic]()
        m4X.setRandom(4, s)
        var mX1: Matrix[Float32, Dynamic, 1] = Matrix[Float32, Dynamic, 1]()
        var resX1: Matrix[Float32, Dynamic, 1] = Matrix[Float32, Dynamic, 1]()
        mX1.setRandom(s, 1)
        var mX4: Matrix[Float32, Dynamic, 4] = Matrix[Float32, Dynamic, 4]()
        var resX4: Matrix[Float32, Dynamic, 4] = Matrix[Float32, Dynamic, 4]()
        mX4.setRandom(s, 4)
        var mXX: Matrix[Float32, Dynamic, Dynamic] = Matrix[Float32, Dynamic, Dynamic]()
        var resXX: Matrix[Float32, Dynamic, Dynamic] = Matrix[Float32, Dynamic, Dynamic]()
        mXX.setRandom(s, s)
        VERIFY_IS_APPROX_EVALUATOR2(res11, prod(m11, m11), m11 * m11)
        VERIFY_IS_APPROX_EVALUATOR2(res11, prod(m14, m41), m14 * m41)
        VERIFY_IS_APPROX_EVALUATOR2(res11, prod(m1X, mX1), m1X * mX1)
        VERIFY_IS_APPROX_EVALUATOR2(res14, prod(m11, m14), m11 * m14)
        VERIFY_IS_APPROX_EVALUATOR2(res14, prod(m14, m44), m14 * m44)
        VERIFY_IS_APPROX_EVALUATOR2(res14, prod(m1X, mX4), m1X * mX4)
        VERIFY_IS_APPROX_EVALUATOR2(res1X, prod(m11, m1X), m11 * m1X)
        VERIFY_IS_APPROX_EVALUATOR2(res1X, prod(m14, m4X), m14 * m4X)
        VERIFY_IS_APPROX_EVALUATOR2(res1X, prod(m1X, mXX), m1X * mXX)
        VERIFY_IS_APPROX_EVALUATOR2(res41, prod(m41, m11), m41 * m11)
        VERIFY_IS_APPROX_EVALUATOR2(res41, prod(m44, m41), m44 * m41)
        VERIFY_IS_APPROX_EVALUATOR2(res41, prod(m4X, mX1), m4X * mX1)
        VERIFY_IS_APPROX_EVALUATOR2(res44, prod(m41, m14), m41 * m14)
        VERIFY_IS_APPROX_EVALUATOR2(res44, prod(m44, m44), m44 * m44)
        VERIFY_IS_APPROX_EVALUATOR2(res44, prod(m4X, mX4), m4X * mX4)
        VERIFY_IS_APPROX_EVALUATOR2(res4X, prod(m41, m1X), m41 * m1X)
        VERIFY_IS_APPROX_EVALUATOR2(res4X, prod(m44, m4X), m44 * m4X)
        VERIFY_IS_APPROX_EVALUATOR2(res4X, prod(m4X, mXX), m4X * mXX)
        VERIFY_IS_APPROX_EVALUATOR2(resX1, prod(mX1, m11), mX1 * m11)
        VERIFY_IS_APPROX_EVALUATOR2(resX1, prod(mX4, m41), mX4 * m41)
        VERIFY_IS_APPROX_EVALUATOR2(resX1, prod(mXX, mX1), mXX * mX1)
        VERIFY_IS_APPROX_EVALUATOR2(resX4, prod(mX1, m14), mX1 * m14)
        VERIFY_IS_APPROX_EVALUATOR2(resX4, prod(mX4, m44), mX4 * m44)
        VERIFY_IS_APPROX_EVALUATOR2(resX4, prod(mXX, mX4), mXX * mX4)
        VERIFY_IS_APPROX_EVALUATOR2(resXX, prod(mX1, m1X), mX1 * m1X)
        VERIFY_IS_APPROX_EVALUATOR2(resXX, prod(mX4, m4X), mX4 * m4X)
        VERIFY_IS_APPROX_EVALUATOR2(resXX, prod(mXX, mXX), mXX * mXX)
    }
    {
        var a: ArrayXXf = ArrayXXf(2, 3)
        var b: ArrayXXf = ArrayXXf(3, 2)
        a << 1,2,3, 4,5,6
        let a_const: ArrayXXf = a
        VERIFY_IS_APPROX_EVALUATOR(v2, 3 * v)
        VERIFY_IS_APPROX_EVALUATOR(w, (3 * v).transpose())
        VERIFY_IS_APPROX_EVALUATOR(b, (a + 3).transpose())
        VERIFY_IS_APPROX_EVALUATOR(b, (2 * a_const + 3).transpose())
        VERIFY_IS_APPROX_EVALUATOR(v2, v + Vector2d.Ones())
        VERIFY_IS_APPROX_EVALUATOR(w, (v + Vector2d.Ones()).transpose().cwiseProduct(RowVector2d.Constant(3)))
        var mat1: MatrixXd = MatrixXd(6, 6)
        var mat2: MatrixXd = MatrixXd(6, 6)
        VERIFY_IS_APPROX_EVALUATOR(mat1, MatrixXd.Identity(6, 6))
        VERIFY_IS_APPROX_EVALUATOR(mat2, mat1)
        copy_using_evaluator(mat2.transpose(), mat1)
        VERIFY_IS_APPROX(mat2.transpose(), mat1)
        var arr1: ArrayXXd = ArrayXXd(6, 6)
        var arr2: ArrayXXd = ArrayXXd(6, 6)
        VERIFY_IS_APPROX_EVALUATOR(arr1, ArrayXXd.Constant(6, 6, 3.0))
        VERIFY_IS_APPROX_EVALUATOR(arr2, arr1)
        mat2.resize(3, 3)
        VERIFY_IS_APPROX_EVALUATOR(mat2, mat1)
        arr2.resize(9, 9)
        VERIFY_IS_APPROX_EVALUATOR(arr2, arr1)
        var m3: Matrix3f = Matrix3f()
        var a3: Array33f = Array33f()
        VERIFY_IS_APPROX_EVALUATOR(m3, Matrix3f.Identity())  # matrix, nullary
        VERIFY_IS_APPROX_EVALUATOR(m3.transpose(), Matrix3f.Identity().transpose())  # transpose
        VERIFY_IS_APPROX_EVALUATOR(m3, 2 * Matrix3f.Identity())  # unary
        VERIFY_IS_APPROX_EVALUATOR(m3, Matrix3f.Identity() + Matrix3f.Zero())  # binary
        VERIFY_IS_APPROX_EVALUATOR(m3.block(0, 0, 2, 2), Matrix3f.Identity().block(1, 1, 2, 2))  # block
        VERIFY_IS_APPROX_EVALUATOR(m3, Matrix3f.Zero())  # matrix, nullary
        VERIFY_IS_APPROX_EVALUATOR(a3, Array33f.Zero())  # array
        VERIFY_IS_APPROX_EVALUATOR(m3.transpose(), Matrix3f.Zero().transpose())  # transpose
        VERIFY_IS_APPROX_EVALUATOR(m3, 2 * Matrix3f.Zero())  # unary
        VERIFY_IS_APPROX_EVALUATOR(m3, Matrix3f.Zero() + m3)  # binary
        var m4: Matrix4f = Matrix4f()
        var m4src: Matrix4f = Matrix4f.Random()
        var a4: Array44f = Array44f()
        var a4src: Array44f = Matrix4f.Random()
        VERIFY_IS_APPROX_EVALUATOR(m4, m4src)  # matrix
        VERIFY_IS_APPROX_EVALUATOR(a4, a4src)  # array
        VERIFY_IS_APPROX_EVALUATOR(m4.transpose(), m4src.transpose())  # transpose
        VERIFY_IS_APPROX_EVALUATOR(m4, 2 * m4src)  # unary
        VERIFY_IS_APPROX_EVALUATOR(m4, m4src + m4src)  # binary
        var mX: MatrixXf = MatrixXf(6, 6)
        var mXsrc: MatrixXf = MatrixXf.Random(6, 6)
        var aX: ArrayXXf = ArrayXXf(6, 6)
        var aXsrc: ArrayXXf = ArrayXXf.Random(6, 6)
        VERIFY_IS_APPROX_EVALUATOR(mX, mXsrc)  # matrix
        VERIFY_IS_APPROX_EVALUATOR(aX, aXsrc)  # array
        VERIFY_IS_APPROX_EVALUATOR(mX.transpose(), mXsrc.transpose())  # transpose
        VERIFY_IS_APPROX_EVALUATOR(mX, MatrixXf.Zero(6, 6))  # nullary
        VERIFY_IS_APPROX_EVALUATOR(mX, 2 * mXsrc)  # unary
        VERIFY_IS_APPROX_EVALUATOR(mX, mXsrc + mXsrc)  # binary
        VERIFY_IS_APPROX_EVALUATOR(m4, (mXsrc.block[4, 4](1, 0)))
        VERIFY_IS_APPROX_EVALUATOR(aX, ArrayXXf.Constant(10, 10, 3.0).block(2, 3, 6, 6))
        var m4ref: Matrix4f = m4
        copy_using_evaluator(m4.block(1, 1, 2, 3), m3.bottomRows(2))
        m4ref.block(1, 1, 2, 3) = m3.bottomRows(2)
        VERIFY_IS_APPROX(m4, m4ref)
        mX.setIdentity(20, 20)
        var mXref: MatrixXf = MatrixXf.Identity(20, 20)
        mXsrc = MatrixXf.Random(9, 12)
        copy_using_evaluator(mX.block(4, 4, 9, 12), mXsrc)
        mXref.block(4, 4, 9, 12) = mXsrc
        VERIFY_IS_APPROX(mX, mXref)
        let raw: Float32[3] = [1, 2, 3]
        var buffer: Float32[3] = [0, 0, 0]
        var v3: Vector3f = Vector3f()
        var a3f: Array3f = Array3f()
        VERIFY_IS_APPROX_EVALUATOR(v3, Map[Vector3f](raw))
        VERIFY_IS_APPROX_EVALUATOR(a3f, Map[Array3f](raw))
        Vector3f.Map(buffer) = 2 * v3
        VERIFY(buffer[0] == 2)
        VERIFY(buffer[1] == 4)
        VERIFY(buffer[2] == 6)
        mat1.setRandom()
        mat2.setIdentity()
        var matXcd: MatrixXcd = MatrixXcd(6, 6)
        var matXcd_ref: MatrixXcd = MatrixXcd(6, 6)
        copy_using_evaluator(matXcd.real(), mat1)
        copy_using_evaluator(matXcd.imag(), mat2)
        matXcd_ref.real() = mat1
        matXcd_ref.imag() = mat2
        VERIFY_IS_APPROX(matXcd, matXcd_ref)
        VERIFY_IS_APPROX_EVALUATOR(aX, (aXsrc > 0).select(aXsrc, -aXsrc))
        mXsrc = MatrixXf.Random(6, 6)
        var vX: VectorXf = VectorXf.Random(6)
        mX.resize(6, 6)
        VERIFY_IS_APPROX_EVALUATOR(mX, mXsrc.colwise() + vX)
        matXcd.resize(12, 12)
        VERIFY_IS_APPROX_EVALUATOR(matXcd, matXcd_ref.replicate(2, 2))
        VERIFY_IS_APPROX_EVALUATOR(matXcd, (matXcd_ref.replicate[2, 2]()))
        var vec1: VectorXd = VectorXd(6)
        VERIFY_IS_APPROX_EVALUATOR(vec1, mat1.rowwise().sum())
        VERIFY_IS_APPROX_EVALUATOR(vec1, mat1.colwise().sum().transpose())
        mat1.setRandom(6, 6)
        arr1.setRandom(6, 6)
        VERIFY_IS_APPROX_EVALUATOR(mat2, arr1.matrix())
        VERIFY_IS_APPROX_EVALUATOR(arr2, mat1.array())
        VERIFY_IS_APPROX_EVALUATOR(mat2, (arr1 + 2).matrix())
        VERIFY_IS_APPROX_EVALUATOR(arr2, mat1.array() + 2)
        mat2.array() = arr1 * arr1
        VERIFY_IS_APPROX(mat2, (arr1 * arr1).matrix())
        arr2.matrix() = MatrixXd.Identity(6, 6)
        VERIFY_IS_APPROX(arr2, MatrixXd.Identity(6, 6).array())
        VERIFY_IS_APPROX_EVALUATOR(arr2, arr1.reverse())
        VERIFY_IS_APPROX_EVALUATOR(arr2, arr1.colwise().reverse())
        VERIFY_IS_APPROX_EVALUATOR(arr2, arr1.rowwise().reverse())
        arr2.reverse() = arr1
        VERIFY_IS_APPROX(arr2, arr1.reverse())
        mat2.array() = mat1.array().reverse()
        VERIFY_IS_APPROX(mat2.array(), mat1.array().reverse())
        VERIFY_IS_APPROX_EVALUATOR(vec1, mat1.diagonal())
        vec1.resize(5)
        VERIFY_IS_APPROX_EVALUATOR(vec1, mat1.diagonal(1))
        VERIFY_IS_APPROX_EVALUATOR(vec1, mat1.diagonal[-1]())
        vec1.setRandom()
        mat2 = mat1
        copy_using_evaluator(mat1.diagonal(1), vec1)
        mat2.diagonal(1) = vec1
        VERIFY_IS_APPROX(mat1, mat2)
        copy_using_evaluator(mat1.diagonal[-1](), mat1.diagonal(1))
        mat2.diagonal[-1]() = mat2.diagonal(1)
        VERIFY_IS_APPROX(mat1, mat2)
    }
    {
        var mat1: MatrixXd = MatrixXd()
        var mat2: MatrixXd = MatrixXd()
        var mat1ref: MatrixXd = MatrixXd()
        var mat2ref: MatrixXd = MatrixXd()
        mat1ref = mat1 = MatrixXd.Random(6, 6)
        mat2ref = mat2 = 2 * mat1 + MatrixXd.Identity(6, 6)
        swap_using_evaluator(mat1, mat2)
        mat1ref.swap(mat2ref)
        VERIFY_IS_APPROX(mat1, mat1ref)
        VERIFY_IS_APPROX(mat2, mat2ref)
        swap_using_evaluator(mat1.block(0, 0, 3, 3), mat2.block(3, 3, 3, 3))
        mat1ref.block(0, 0, 3, 3).swap(mat2ref.block(3, 3, 3, 3))
        VERIFY_IS_APPROX(mat1, mat1ref)
        VERIFY_IS_APPROX(mat2, mat2ref)
        swap_using_evaluator(mat1.row(2), mat2.col(3).transpose())
        mat1.row(2).swap(mat2.col(3).transpose())
        VERIFY_IS_APPROX(mat1, mat1ref)
        VERIFY_IS_APPROX(mat2, mat2ref)
    }
    {
        let mat_const: Matrix4d = Matrix4d.Random()
        var mat: Matrix4d = Matrix4d()
        var mat_ref: Matrix4d = Matrix4d()
        mat = mat_ref = Matrix4d.Identity()
        add_assign_using_evaluator(mat, mat_const)
        mat_ref += mat_const
        VERIFY_IS_APPROX(mat, mat_ref)
        subtract_assign_using_evaluator(mat.row(1), 2 * mat.row(2))
        mat_ref.row(1) -= 2 * mat_ref.row(2)
        VERIFY_IS_APPROX(mat, mat_ref)
        let arr_const: ArrayXXf = ArrayXXf.Random(5, 3)
        var arr: ArrayXXf = ArrayXXf()
        var arr_ref: ArrayXXf = ArrayXXf()
        arr = arr_ref = ArrayXXf.Constant(5, 3, 0.5)
        multiply_assign_using_evaluator(arr, arr_const)
        arr_ref *= arr_const
        VERIFY_IS_APPROX(arr, arr_ref)
        divide_assign_using_evaluator(arr.row(1), arr.row(2) + 1)
        arr_ref.row(1) /= (arr_ref.row(2) + 1)
        VERIFY_IS_APPROX(arr, arr_ref)
    }
    {
        var A: MatrixXd = MatrixXd.Random(6, 6)
        var B: MatrixXd = MatrixXd(6, 6)
        var C: MatrixXd = MatrixXd(6, 6)
        var D: MatrixXd = MatrixXd(6, 6)
        A.setRandom()
        B.setRandom()
        VERIFY_IS_APPROX_EVALUATOR2(B, A.triangularView[Upper](), MatrixXd(A.triangularView[Upper]()))
        A.setRandom()
        B.setRandom()
        VERIFY_IS_APPROX_EVALUATOR2(B, A.triangularView[UnitLower](), MatrixXd(A.triangularView[UnitLower]()))
        A.setRandom()
        B.setRandom()
        VERIFY_IS_APPROX_EVALUATOR2(B, A.triangularView[UnitUpper](), MatrixXd(A.triangularView[UnitUpper]()))
        A.setRandom()
        B.setRandom()
        C = B
        C.triangularView[Upper]() = A
        copy_using_evaluator(B.triangularView[Upper](), A)
        VERIFY(B.isApprox(C) and "copy_using_evaluator(B.triangularView<Upper>(), A)")
        A.setRandom()
        B.setRandom()
        C = B
        C.triangularView[Lower]() = A.triangularView[Lower]()
        copy_using_evaluator(B.triangularView[Lower](), A.triangularView[Lower]())
        VERIFY(B.isApprox(C) and "copy_using_evaluator(B.triangularView<Lower>(), A.triangularView<Lower>())")
        A.setRandom()
        B.setRandom()
        C = B
        C.triangularView[Lower]() = A.triangularView[Upper]().transpose()
        copy_using_evaluator(B.triangularView[Lower](), A.triangularView[Upper]().transpose())
        VERIFY(B.isApprox(C) and "copy_using_evaluator(B.triangularView<Lower>(), A.triangularView<Lower>().transpose())")
        A.setRandom()
        B.setRandom()
        C = B
        D = A
        C.triangularView[Upper]().swap(D.triangularView[Upper]())
        swap_using_evaluator(B.triangularView[Upper](), A.triangularView[Upper]())
        VERIFY(B.isApprox(C) and "swap_using_evaluator(B.triangularView<Upper>(), A.triangularView<Upper>())")
        VERIFY_IS_APPROX_EVALUATOR2(B, prod(A.triangularView[Upper](), A), MatrixXd(A.triangularView[Upper]() * A))
        VERIFY_IS_APPROX_EVALUATOR2(B, prod(A.selfadjointView[Upper](), A), MatrixXd(A.selfadjointView[Upper]() * A))
    }
    {
        var d: VectorXd = VectorXd.Random(6)
        var A: MatrixXd = MatrixXd.Random(6, 6)
        var B: MatrixXd = MatrixXd(6, 6)
        A.setRandom()
        B.setRandom()
        VERIFY_IS_APPROX_EVALUATOR2(B, lazyprod(d.asDiagonal(), A), MatrixXd(d.asDiagonal() * A))
        VERIFY_IS_APPROX_EVALUATOR2(B, lazyprod(A, d.asDiagonal()), MatrixXd(A * d.asDiagonal()))
    }
    {
        var a: Matrix4d = Matrix4d()
        var b: Matrix4d = Matrix4d()
        VERIFY_IS_EQUAL(get_cost(a), 1)
        VERIFY_IS_EQUAL(get_cost(a + b), 3)
        VERIFY_IS_EQUAL(get_cost(2 * a + b), 4)
        VERIFY_IS_EQUAL(get_cost(a * b), 1)
        VERIFY_IS_EQUAL(get_cost(a.lazyProduct(b)), 15)
        VERIFY_IS_EQUAL(get_cost(a * (a * b)), 1)
        VERIFY_IS_EQUAL(get_cost(a.lazyProduct(a * b)), 15)
        VERIFY_IS_EQUAL(get_cost(a * (a + b)), 1)
        VERIFY_IS_EQUAL(get_cost(a.lazyProduct(a + b)), 15)
    }