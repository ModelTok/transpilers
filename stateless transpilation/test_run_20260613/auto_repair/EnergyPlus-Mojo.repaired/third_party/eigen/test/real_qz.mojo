#define EIGEN_RUNTIME_NO_MALLOC
#include "main.h"
#include <limits>
#include <Eigen/Eigenvalues>
template<MatrixType> def real_qz(m: MatrixType):
  /* this test covers the following files:
     RealQZ.h
  */
  using abs
  typedef MatrixType::Scalar Scalar
  Index dim = m.cols()
  MatrixType A = MatrixType::Random(dim,dim),
             B = MatrixType::Random(dim,dim)
  Index k=internal::random<Index>(0, dim-1)
  switch(internal::random<int>(0,10)):
  case 0:
    A.row(k).setZero(); break
  case 1:
    A.col(k).setZero(); break
  case 2:
    B.row(k).setZero(); break
  case 3:
    B.col(k).setZero(); break
  default:
    break
  
  RealQZ<MatrixType> qz(dim)
  qz.compute(A,B)
  VERIFY_IS_EQUAL(qz.info(), Success)
  var all_zeros: Bool = true
  for i in range(0, A.cols()):
    for j in range(0, i):
      if abs(qz.matrixT()[i,j])!=Scalar(0.0):
        cerr << "Error: T(" << i << "," << j << ") = " << qz.matrixT()[i,j] << endl
        all_zeros = false
      
      if j<i-1 and abs(qz.matrixS()[i,j])!=Scalar(0.0):
        cerr << "Error: S(" << i << "," << j << ") = " << qz.matrixS()[i,j] << endl
        all_zeros = false
      
      if j==i-1 and j>0 and abs(qz.matrixS()[i,j])!=Scalar(0.0) and abs(qz.matrixS()[i-1,j-1])!=Scalar(0.0):
        cerr << "Error: S(" << i << "," << j << ") = " << qz.matrixS()[i,j]  << " && S(" << i-1 << "," << j-1 << ") = " << qz.matrixS()[i-1,j-1] << endl
        all_zeros = false
      
    
  
  VERIFY_IS_EQUAL(all_zeros, true)
  VERIFY_IS_APPROX(qz.matrixQ()*qz.matrixS()*qz.matrixZ(), A)
  VERIFY_IS_APPROX(qz.matrixQ()*qz.matrixT()*qz.matrixZ(), B)
  VERIFY_IS_APPROX(qz.matrixQ()*qz.matrixQ().adjoint(), MatrixType::Identity(dim,dim))
  VERIFY_IS_APPROX(qz.matrixZ()*qz.matrixZ().adjoint(), MatrixType::Identity(dim,dim))

def test_real_qz():
  var s: int = 0
  for i in range(0, g_repeat):
    CALL_SUBTEST_1( real_qz(Matrix4f()) )
    s = internal::random<int>(1,EIGEN_TEST_MAX_SIZE/4)
    CALL_SUBTEST_2( real_qz(MatrixXd(s,s)) )
    CALL_SUBTEST_2( real_qz(MatrixXd(1,1)) )
    CALL_SUBTEST_2( real_qz(MatrixXd(2,2)) )
    CALL_SUBTEST_3( real_qz(Matrix<double,1,1>()) )
    CALL_SUBTEST_4( real_qz(Matrix2d()) )
  
  TEST_SET_BUT_UNUSED_VARIABLE(s)