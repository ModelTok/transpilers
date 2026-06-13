#define EIGEN_NO_STATIC_ASSERT
#include "main.h"
template<T>
struct other_matrix_type
{
  typedef int type;
};
template<_Scalar, int _Rows, int _Cols, int _Options, int _MaxRows, int _MaxCols>
struct other_matrix_type<Matrix<_Scalar, _Rows, _Cols, _Options, _MaxRows, _MaxCols> >
{
  typedef Matrix<_Scalar, _Rows, _Cols, _Options^RowMajor, _MaxRows, _MaxCols> type;
};
template<MatrixType> void swap(MatrixType& m )
{
  typedef other_matrix_type<MatrixType>::type OtherMatrixType;
  typedef MatrixType::Scalar Scalar;
  eigen_assert((!internal::is_same<MatrixType,OtherMatrixType>::value));
  MatrixType::Index rows = m.rows();
  MatrixType::Index cols = m.cols();
  MatrixType m1 = MatrixType::Random(rows,cols);
  MatrixType m2 = MatrixType::Random(rows,cols) + Scalar(100) * MatrixType::Identity(rows,cols);
  OtherMatrixType m3 = OtherMatrixType::Random(rows,cols) + Scalar(200) * OtherMatrixType::Identity(rows,cols);
  MatrixType m1_copy = m1;
  MatrixType m2_copy = m2;
  OtherMatrixType m3_copy = m3;
  Scalar *d1=m1.data(), *d2=m2.data();
  m1.swap(m2);
  VERIFY_IS_APPROX(m1,m2_copy);
  VERIFY_IS_APPROX(m2,m1_copy);
  if(MatrixType::SizeAtCompileTime==Dynamic)
  {
    VERIFY(m1.data()==d2);
    VERIFY(m2.data()==d1);
  }
  m1 = m1_copy;
  m2 = m2_copy;
  m1.swap(m3);
  VERIFY_IS_APPROX(m1,m3_copy);
  VERIFY_IS_APPROX(m3,m1_copy);
  m1 = m1_copy;
  m3 = m3_copy;
  m1.swap(m2.block(0,0,rows,cols));
  VERIFY_IS_APPROX(m1,m2_copy);
  VERIFY_IS_APPROX(m2,m1_copy);
  m1 = m1_copy;
  m2 = m2_copy;
  m1.transpose().swap(m3.transpose());
  VERIFY_IS_APPROX(m1,m3_copy);
  VERIFY_IS_APPROX(m3,m1_copy);
  m1 = m1_copy;
  m3 = m3_copy;
  if(m1.rows()>1)
  {
    VERIFY_RAISES_ASSERT(m1.swap(m1.row(0)));
    VERIFY_RAISES_ASSERT(m1.row(0).swap(m1));
  }
}
void test_swap()
{
  int s = internal::random<int>(1,EIGEN_TEST_MAX_SIZE);
  CALL_SUBTEST_1( swap(Matrix3f()) ); // fixed size, no vectorization 
  CALL_SUBTEST_2( swap(Matrix4d()) ); // fixed size, possible vectorization 
  CALL_SUBTEST_3( swap(MatrixXd(s,s)) ); // dyn size, no vectorization 
  CALL_SUBTEST_4( swap(MatrixXf(s,s)) ); // dyn size, possible vectorization 
  TEST_SET_BUT_UNUSED_VARIABLE(s)
}