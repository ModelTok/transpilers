from main import *
from Eigen.Geometry import *

def homogeneous[Scalar: AnyType, Size: Int]() raises:
    """this test covers the following files:
       Homogeneous.h
    """
    alias MatrixType = Matrix[Scalar, Size, Size]
    alias VectorType = Matrix[Scalar, Size, 1, ColMajor]
    alias HMatrixType = Matrix[Scalar, Size+1, Size]
    alias HVectorType = Matrix[Scalar, Size+1, 1]
    alias T1MatrixType = Matrix[Scalar, Size, Size+1]
    alias T2MatrixType = Matrix[Scalar, Size+1, Size+1]
    alias T3MatrixType = Matrix[Scalar, Size+1, Size]
    var v0 = VectorType.Random()
    var ones = VectorType.Ones()
    var hv0 = HVectorType.Random()
    var m0 = MatrixType.Random()
    var hm0 = HMatrixType.Random()
    hv0 << v0, 1
    VERIFY_IS_APPROX(v0.homogeneous(), hv0)
    VERIFY_IS_APPROX(v0, hv0.hnormalized())
    VERIFY_IS_APPROX(v0.homogeneous().sum(), hv0.sum())
    VERIFY_IS_APPROX(v0.homogeneous().minCoeff(), hv0.minCoeff())
    VERIFY_IS_APPROX(v0.homogeneous().maxCoeff(), hv0.maxCoeff())
    hm0 << m0, ones.transpose()
    VERIFY_IS_APPROX(m0.colwise().homogeneous(), hm0)
    VERIFY_IS_APPROX(m0, hm0.colwise().hnormalized())
    hm0.row(Size-1).setRandom()
    for j in range(Size):
        m0.col(j) = hm0.col(j).head(Size) / hm0(Size,j)
    VERIFY_IS_APPROX(m0, hm0.colwise().hnormalized())
    var t1 = T1MatrixType.Random()
    VERIFY_IS_APPROX(t1 * (v0.homogeneous().eval()), t1 * v0.homogeneous())
    VERIFY_IS_APPROX(t1 * (m0.colwise().homogeneous().eval()), t1 * m0.colwise().homogeneous())
    var t2 = T2MatrixType.Random()
    VERIFY_IS_APPROX(t2 * (v0.homogeneous().eval()), t2 * v0.homogeneous())
    VERIFY_IS_APPROX(t2 * (m0.colwise().homogeneous().eval()), t2 * m0.colwise().homogeneous())
    VERIFY_IS_APPROX(t2 * (v0.homogeneous().asDiagonal()), t2 * hv0.asDiagonal())
    VERIFY_IS_APPROX((v0.homogeneous().asDiagonal()) * t2, hv0.asDiagonal() * t2)
    VERIFY_IS_APPROX((v0.transpose().rowwise().homogeneous().eval()) * t2,
                      v0.transpose().rowwise().homogeneous() * t2)
    VERIFY_IS_APPROX((m0.transpose().rowwise().homogeneous().eval()) * t2,
                      m0.transpose().rowwise().homogeneous() * t2)
    var t3 = T3MatrixType.Random()
    VERIFY_IS_APPROX((v0.transpose().rowwise().homogeneous().eval()) * t3,
                      v0.transpose().rowwise().homogeneous() * t3)
    VERIFY_IS_APPROX((m0.transpose().rowwise().homogeneous().eval()) * t3,
                      m0.transpose().rowwise().homogeneous() * t3)
    var aff = Transform[Scalar, Size, Affine]()
    var caff = Transform[Scalar, Size, AffineCompact]()
    var proj = Transform[Scalar, Size, Projective]()
    var pts = Matrix[Scalar, Size, Dynamic]()
    var pts1 = Matrix[Scalar, Size+1, Dynamic]()
    var pts2 = Matrix[Scalar, Size+1, Dynamic]()
    aff.affine().setRandom()
    proj = caff = aff
    pts.setRandom(Size, internal.random[int](1,20))
    pts1 = pts.colwise().homogeneous()
    VERIFY_IS_APPROX(aff  * pts.colwise().homogeneous(), (aff  * pts1).colwise().hnormalized())
    VERIFY_IS_APPROX(caff * pts.colwise().homogeneous(), (caff * pts1).colwise().hnormalized())
    VERIFY_IS_APPROX(proj * pts.colwise().homogeneous(), (proj * pts1))
    VERIFY_IS_APPROX((aff  * pts1).colwise().hnormalized(),  aff  * pts)
    VERIFY_IS_APPROX((caff * pts1).colwise().hnormalized(), caff * pts)
    pts2 = pts1
    pts2.row(Size).setRandom()
    VERIFY_IS_APPROX((aff  * pts2).colwise().hnormalized(), aff  * pts2.colwise().hnormalized())
    VERIFY_IS_APPROX((caff * pts2).colwise().hnormalized(), caff * pts2.colwise().hnormalized())
    VERIFY_IS_APPROX((proj * pts2).colwise().hnormalized(), (proj * pts2.colwise().hnormalized().colwise().homogeneous()).colwise().hnormalized())
    VERIFY_IS_APPROX( (t2 * v0.homogeneous()).hnormalized(),
                         (t2.template topLeftCorner[Size,Size]() * v0 + t2.template topRightCorner[Size,1]())
                       / ((t2.template bottomLeftCorner[1,Size]()*v0).value() + t2(Size,Size)) )
    VERIFY_IS_APPROX( (t2 * pts.colwise().homogeneous()).colwise().hnormalized(),
                      (Matrix[Scalar, Size+1, Dynamic](t2 * pts1).colwise().hnormalized()) )
    VERIFY_IS_APPROX( (t2 .lazyProduct( v0.homogeneous() )).hnormalized(), (t2 * v0.homogeneous()).hnormalized() )
    VERIFY_IS_APPROX( (t2 .lazyProduct  ( pts.colwise().homogeneous() )).colwise().hnormalized(), (t2 * pts1).colwise().hnormalized() )
    VERIFY_IS_APPROX( (v0.transpose().homogeneous() .lazyProduct( t2 )).hnormalized(), (v0.transpose().homogeneous()*t2).hnormalized() )
    VERIFY_IS_APPROX( (pts.transpose().rowwise().homogeneous() .lazyProduct( t2 )).rowwise().hnormalized(), (pts1.transpose()*t2).rowwise().hnormalized() )
    VERIFY_IS_APPROX( (t2.template triangularView[Lower]() * v0.homogeneous()).eval(), (t2.template triangularView[Lower]()*hv0) )

def test_geo_homogeneous() raises:
    for i in range(g_repeat):
        CALL_SUBTEST_1(( homogeneous[float32,1]() ))
        CALL_SUBTEST_2(( homogeneous[float64,3]() ))
        CALL_SUBTEST_3(( homogeneous[float64,8]() ))