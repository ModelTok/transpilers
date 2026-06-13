#define EIGEN_STACK_ALLOCATION_LIMIT 0
#define EIGEN_RUNTIME_NO_MALLOC
#include "main.h"
#include <Eigen/SVD>
#include <iostream>
#include <Eigen/LU>
#define SVD_DEFAULT(M) BDCSVD<M>
#define SVD_FOR_MIN_NORM(M) BDCSVD<M>
#include "svd_common.h"
template<MatrixType>
def bdcsvd(a: MatrixType = MatrixType(), pickrandom: bool = true):
  var m: MatrixType = a
  if pickrandom:
    svd_fill_random(m)
  CALL_SUBTEST(( svd_test_all_computation_options<BDCSVD<MatrixType> >(m, false)  ))
end

template<MatrixType>
def bdcsvd_method():
  enum Size = MatrixType.RowsAtCompileTime
  typedef MatrixType.RealScalar RealScalar
  typedef Matrix<RealScalar, Size, 1> RealVecType
  var m: MatrixType = MatrixType.Identity()
  VERIFY_IS_APPROX(m.bdcSvd().singularValues(), RealVecType.Ones())
  VERIFY_RAISES_ASSERT(m.bdcSvd().matrixU())
  VERIFY_RAISES_ASSERT(m.bdcSvd().matrixV())
  VERIFY_IS_APPROX(m.bdcSvd(ComputeFullU|ComputeFullV).solve(m), m)
end

template<MatrixType> 
def compare_bdc_jacobi(a: MatrixType = MatrixType(), computationOptions: UInt32 = 0):
  var m: MatrixType = MatrixType.Random(a.rows(), a.cols())
  var bdc_svd: BDCSVD<MatrixType> = BDCSVD<MatrixType>(m)
  var jacobi_svd: JacobiSVD<MatrixType> = JacobiSVD<MatrixType>(m)
  VERIFY_IS_APPROX(bdc_svd.singularValues(), jacobi_svd.singularValues())
  if computationOptions & ComputeFullU: VERIFY_IS_APPROX(bdc_svd.matrixU(), jacobi_svd.matrixU())
  if computationOptions & ComputeThinU: VERIFY_IS_APPROX(bdc_svd.matrixU(), jacobi_svd.matrixU())
  if computationOptions & ComputeFullV: VERIFY_IS_APPROX(bdc_svd.matrixV(), jacobi_svd.matrixV())
  if computationOptions & ComputeThinV: VERIFY_IS_APPROX(bdc_svd.matrixV(), jacobi_svd.matrixV())
end

def test_bdcsvd():
  CALL_SUBTEST_3(( svd_verify_assert<BDCSVD<Matrix3f>  >(Matrix3f()) ))
  CALL_SUBTEST_4(( svd_verify_assert<BDCSVD<Matrix4d>  >(Matrix4d()) ))
  CALL_SUBTEST_7(( svd_verify_assert<BDCSVD<MatrixXf>  >(MatrixXf(10,12)) ))
  CALL_SUBTEST_8(( svd_verify_assert<BDCSVD<MatrixXcd> >(MatrixXcd(7,5)) ))
  CALL_SUBTEST_101(( svd_all_trivial_2x2(bdcsvd<Matrix2cd>) ))
  CALL_SUBTEST_102(( svd_all_trivial_2x2(bdcsvd<Matrix2d>) ))
  for i in range(0, g_repeat):
    CALL_SUBTEST_3(( bdcsvd<Matrix3f>() ))
    CALL_SUBTEST_4(( bdcsvd<Matrix4d>() ))
    CALL_SUBTEST_5(( bdcsvd<Matrix<float,3,5> >() ))
    var r: Int = internal.random<Int>(1, EIGEN_TEST_MAX_SIZE/2)
    var c: Int = internal.random<Int>(1, EIGEN_TEST_MAX_SIZE/2)
    TEST_SET_BUT_UNUSED_VARIABLE(r)
    TEST_SET_BUT_UNUSED_VARIABLE(c)
    CALL_SUBTEST_6((  bdcsvd(Matrix<double,Dynamic,2>(r,2)) ))
    CALL_SUBTEST_7((  bdcsvd(MatrixXf(r,c)) ))
    CALL_SUBTEST_7((  compare_bdc_jacobi(MatrixXf(r,c)) ))
    CALL_SUBTEST_10(( bdcsvd(MatrixXd(r,c)) ))
    CALL_SUBTEST_10(( compare_bdc_jacobi(MatrixXd(r,c)) ))
    CALL_SUBTEST_8((  bdcsvd(MatrixXcd(r,c)) ))
    CALL_SUBTEST_8((  compare_bdc_jacobi(MatrixXcd(r,c)) ))
    CALL_SUBTEST_7(  (svd_inf_nan<BDCSVD<MatrixXf>, MatrixXf>()) )
    CALL_SUBTEST_10( (svd_inf_nan<BDCSVD<MatrixXd>, MatrixXd>()) )
  end
  CALL_SUBTEST_1(( bdcsvd_method<Matrix2cd>() ))
  CALL_SUBTEST_3(( bdcsvd_method<Matrix3f>() ))
  CALL_SUBTEST_7( BDCSVD<MatrixXf>(10,10) )
  CALL_SUBTEST_2( svd_underoverflow<void>() )
end