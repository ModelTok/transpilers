from main import *
from Eigen.Core import *
from <random> import std_random
from <iostream> import std_cout

def equalsIdentity[MatrixType: AnyType](A: MatrixType) -> Bool:
    alias Scalar = MatrixType.Scalar
    var zero: Scalar = static_cast[Scalar](0)
    var offDiagOK: Bool = True
    for i in range(0, A.rows()):
        for j in range(i+1, A.cols()):
            offDiagOK = offDiagOK and (A(i,j) == zero)
    for i in range(0, A.rows()):
        for j in range(0, min(i, A.cols())):
            offDiagOK = offDiagOK and (A(i,j) == zero)
    var diagOK: Bool = (A.diagonal().array() == 1).all()
    return offDiagOK and diagOK

def check_extremity_accuracy[VectorType: AnyType](v: VectorType, low: VectorType.Scalar, high: VectorType.Scalar):
    alias Scalar = VectorType.Scalar
    alias RealScalar = VectorType.RealScalar
    var prec: RealScalar = NumTraits[RealScalar].dummy_precision()*10 if internal.is_same[RealScalar, float32]() else NumTraits[RealScalar].dummy_precision()/10
    var size: Index = v.size()
    if size < 20:
        return
    for i in range(0, size):
        if i < 5 or i > size-6:
            var ref: Scalar = (low*RealScalar(size-i-1))/RealScalar(size-1) + (high*RealScalar(i))/RealScalar(size-1)
            if std.abs(ref) > 1:
                if not internal.isApprox(v(i), ref, prec):
                    std_cout << v(i) << " != " << ref << "  ; relative error: " << std.abs((v(i)-ref)/ref) << "  ; required precision: " << prec << "  ; range: " << low << "," << high << "  ; i: " << i << "\n"
                VERIFY(internal.isApprox(v(i), (low*RealScalar(size-i-1))/RealScalar(size-1) + (high*RealScalar(i))/RealScalar(size-1), prec))

def testVectorType[VectorType: AnyType](base: VectorType):
    alias Scalar = VectorType.Scalar
    alias RealScalar = VectorType.RealScalar
    var size: Index = base.size()
    var high: Scalar = internal.random[Scalar](-500,500)
    var low: Scalar = high if (size == 1) else internal.random[Scalar](-500,500)
    if low > high:
        std.swap(low,high)
    if internal.random[float32](0.0,1.0) < 0.05:
        low = high
    elif size > 2 and std.numeric_limits[RealScalar].max_exponent10 > 0 and internal.random[float32](0.0,1.0) < 0.1:
        low = -internal.random[Scalar](1,2) * RealScalar(std.pow(RealScalar(10), std.numeric_limits[RealScalar].max_exponent10/2))
    var step: Scalar = (1 if (size == 1) else (high-low)/(size-1))
    var m: VectorType = base
    m.setLinSpaced(size,low,high)
    if not NumTraits[Scalar].IsInteger:
        var n: VectorType = VectorType(size)
        for i in range(0, size):
            n(i) = low + i*step
        VERIFY_IS_APPROX(m,n)
        CALL_SUBTEST(check_extremity_accuracy(m, low, high))
    if (not NumTraits[Scalar].IsInteger) or ((high-low)>=size and (Index(high-low)%(size-1))==0) or (Index(high-low+1)<size and (size%Index(high-low+1))==0):
        var n: VectorType = VectorType(size)
        if (not NumTraits[Scalar].IsInteger) or (high-low>=size):
            for i in range(0, size):
                n(i) = low if size==1 else (low + ((high-low)*Scalar(i))/(size-1))
        else:
            for i in range(0, size):
                n(i) = low if size==1 else low + Scalar((float64(high-low+1)*float64(i))/float64(size))
        VERIFY_IS_APPROX(m,n)
        m = VectorType.LinSpaced(size,low,high)
        VERIFY_IS_APPROX(m,n)
        VERIFY( internal.isApprox(m(m.size()-1),high) )
        VERIFY( size==1 or internal.isApprox(m(0),low) )
        VERIFY_IS_EQUAL(m(m.size()-1), high)
        if not NumTraits[Scalar].IsInteger:
            CALL_SUBTEST(check_extremity_accuracy(m, low, high))
    VERIFY( m(m.size()-1) <= high )
    VERIFY( (m.array() <= high).all() )
    VERIFY( (m.array() >= low).all() )
    VERIFY( m(m.size()-1) >= low )
    if size>=1:
        VERIFY( internal.isApprox(m(0),low) )
        VERIFY_IS_EQUAL(m(0), low)
    var row_vector: Matrix[Scalar, Dynamic, 1] = Matrix[Scalar, Dynamic, 1](size)
    var col_vector: Matrix[Scalar, 1, Dynamic] = Matrix[Scalar, 1, Dynamic](size)
    row_vector.setLinSpaced(size,low,high)
    col_vector.setLinSpaced(size,low,high)
    VERIFY( row_vector.isApprox(col_vector.transpose(), Scalar(2)*NumTraits[Scalar].epsilon()))
    var size_changer: Matrix[Scalar, Dynamic, 1] = Matrix[Scalar, Dynamic, 1](size+50)
    size_changer.setLinSpaced(size,low,high)
    VERIFY( size_changer.size() == size )
    alias ScalarMatrix = Matrix[Scalar, 1, 1]
    var scalar: ScalarMatrix = ScalarMatrix()
    scalar.setLinSpaced(1,low,high)
    VERIFY_IS_APPROX( scalar, ScalarMatrix.Constant(high) )
    VERIFY_IS_APPROX( ScalarMatrix.LinSpaced(1,low,high), ScalarMatrix.Constant(high) )
    if size > 1 and (not NumTraits[Scalar].IsInteger):
        m.tail(size-1).setLinSpaced(low, high)
        VERIFY_IS_APPROX(m(size-1), high)
    var n0: Index = 0 if VectorType.SizeAtCompileTime==Dynamic else VectorType.SizeAtCompileTime
    low = internal.random[Scalar]()
    m = VectorType.LinSpaced(n0,low,low-1)
    VERIFY(m.size()==n0)
    if VectorType.SizeAtCompileTime==Dynamic:
        VERIFY_IS_EQUAL(VectorType.LinSpaced(n0,0,Scalar(n0-1)).sum(),Scalar(0))
        VERIFY_IS_EQUAL(VectorType.LinSpaced(n0,low,low-1).sum(),Scalar(0))
    m.setLinSpaced(n0,0,Scalar(n0-1))
    VERIFY(m.size()==n0)
    m.setLinSpaced(n0,low,low-1)
    VERIFY(m.size()==n0)
    VERIFY_IS_APPROX(VectorType.LinSpaced(size,low,low),VectorType.Constant(size,low))
    m.setLinSpaced(size,low,low)
    VERIFY_IS_APPROX(m,VectorType.Constant(size,low))
    if NumTraits[Scalar].IsInteger:
        VERIFY_IS_APPROX( VectorType.LinSpaced(size,low,Scalar(low+size-1)), VectorType.LinSpaced(size,Scalar(low+size-1),low).reverse() )
        if VectorType.SizeAtCompileTime==Dynamic:
            for k in range(1,5):
                VERIFY_IS_APPROX( VectorType.LinSpaced(size,low,Scalar(low+(size-1)*k)), VectorType.LinSpaced(size,Scalar(low+(size-1)*k),low).reverse() )
            for k in range(1,5):
                VERIFY_IS_APPROX( VectorType.LinSpaced(size*k,low,Scalar(low+size-1)), VectorType.LinSpaced(size*k,Scalar(low+size-1),low).reverse() )

def testMatrixType[MatrixType: AnyType](m: MatrixType):
    alias abs = std.abs
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    var s1: Scalar
    s1 = internal.random[Scalar]()
    while abs(s1) < RealScalar(1e-5) and (not NumTraits[Scalar].IsInteger):
        s1 = internal.random[Scalar]()
    var A: MatrixType
    A.setIdentity(rows, cols)
    VERIFY(equalsIdentity(A))
    VERIFY(equalsIdentity(MatrixType.Identity(rows, cols)))
    A = MatrixType.Constant(rows,cols,s1)
    var i: Index = internal.random[Index](0,rows-1)
    var j: Index = internal.random[Index](0,cols-1)
    VERIFY_IS_APPROX( MatrixType.Constant(rows,cols,s1)(i,j), s1 )
    VERIFY_IS_APPROX( MatrixType.Constant(rows,cols,s1).coeff(i,j), s1 )
    VERIFY_IS_APPROX( A(i,j), s1 )

def test_nullary():
    CALL_SUBTEST_1( testMatrixType(Matrix2d()) )
    CALL_SUBTEST_2( testMatrixType(MatrixXcf(internal.random[int](1,300),internal.random[int](1,300))) )
    CALL_SUBTEST_3( testMatrixType(MatrixXf(internal.random[int](1,300),internal.random[int](1,300))) )
    for i in range(0, g_repeat*10):
        CALL_SUBTEST_4( testVectorType(VectorXd(internal.random[int](1,30000))) )
        CALL_SUBTEST_5( testVectorType(Vector4d()) )
        CALL_SUBTEST_6( testVectorType(Vector3d()) )
        CALL_SUBTEST_7( testVectorType(VectorXf(internal.random[int](1,30000))) )
        CALL_SUBTEST_8( testVectorType(Vector3f()) )
        CALL_SUBTEST_8( testVectorType(Vector4f()) )
        CALL_SUBTEST_8( testVectorType(Matrix[float32,8,1]()) )
        CALL_SUBTEST_8( testVectorType(Matrix[float32,1,1]()) )
        CALL_SUBTEST_9( testVectorType(VectorXi(internal.random[int](1,10))) )
        CALL_SUBTEST_9( testVectorType(VectorXi(internal.random[int](9,300))) )
        CALL_SUBTEST_9( testVectorType(Matrix[int32,1,1]()) )
    if defined("EIGEN_TEST_PART_6"):
        VERIFY( (MatrixXd(RowVectorXd.LinSpaced(3, 0, 1)) - RowVector3d(0, 0.5, 1)).norm() < std.numeric_limits[float64].epsilon() )
    if defined("EIGEN_TEST_PART_9"):
        var n: int32 = 60000
        var a1: ArrayXi = ArrayXi(n)
        var a2: ArrayXi = ArrayXi(n)
        a1.setLinSpaced(n, 0, n-1)
        for i in range(0, n):
            a2(i) = i
        VERIFY_IS_APPROX(a1,a2)
    if defined("EIGEN_TEST_PART_10"):
        VERIFY((  internal.has_nullary_operator[internal.scalar_constant_op[float64]]() ))
        VERIFY(( not internal.has_unary_operator[internal.scalar_constant_op[float64]]() ))
        VERIFY(( not internal.has_binary_operator[internal.scalar_constant_op[float64]]() ))
        VERIFY((  internal.functor_has_linear_access[internal.scalar_constant_op[float64]]() .ret ))
        VERIFY(( not internal.has_nullary_operator[internal.scalar_identity_op[float64]]() ))
        VERIFY(( not internal.has_unary_operator[internal.scalar_identity_op[float64]]() ))
        VERIFY((  internal.has_binary_operator[internal.scalar_identity_op[float64]]() ))
        VERIFY(( not internal.functor_has_linear_access[internal.scalar_identity_op[float64]]() .ret ))
        VERIFY(( not internal.has_nullary_operator[internal.linspaced_op[float32,float32]]() ))
        VERIFY((  internal.has_unary_operator[internal.linspaced_op[float32,float32]]() ))
        VERIFY(( not internal.has_binary_operator[internal.linspaced_op[float32,float32]]() ))
        VERIFY((  internal.functor_has_linear_access[internal.linspaced_op[float32,float32]]() .ret ))
        var A: MatrixXf = MatrixXf.Random(3,3)
        var R: Ref[const[MatrixXf]] = 2.0*A
        VERIFY_IS_APPROX(R, A+A)
        var R1: Ref[const[MatrixXf]] = MatrixXf.Random(3,3)+A
        var V: VectorXi = VectorXi.Random(3)
        var R2: Ref[const[VectorXi]] = VectorXi.LinSpaced(3,1,3)+V
        VERIFY_IS_APPROX(R2, V+Vector3i(1,2,3))
        VERIFY((  internal.has_nullary_operator[internal.scalar_constant_op[float32]]() ))
        VERIFY(( not internal.has_unary_operator[internal.scalar_constant_op[float32]]() ))
        VERIFY(( not internal.has_binary_operator[internal.scalar_constant_op[float32]]() ))
        VERIFY((  internal.functor_has_linear_access[internal.scalar_constant_op[float32]]() .ret ))
        VERIFY(( not internal.has_nullary_operator[internal.linspaced_op[int32,int32]]() ))
        VERIFY((  internal.has_unary_operator[internal.linspaced_op[int32,int32]]() ))
        VERIFY(( not internal.has_binary_operator[internal.linspaced_op[int32,int32]]() ))
        VERIFY((  internal.functor_has_linear_access[internal.linspaced_op[int32,int32]]() .ret ))