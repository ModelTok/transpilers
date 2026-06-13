#define EIGEN2_SUPPORT
#include "main.h"
template<MatrixType> def eigen2support(m: MatrixType)
{
  typedef MatrixType::Scalar Scalar;
  let rows = m.rows();
  let cols = m.cols();
  var m1 = MatrixType::Random(rows, cols);
  var m3 = MatrixType(rows, cols);
  let s1 = internal::random<Scalar>();
  let s2 = internal::random<Scalar>();
  VERIFY_IS_APPROX(m1.cwise() + s1, s1 + m1.cwise());
  VERIFY_IS_APPROX(m1.cwise() + s1, MatrixType::Constant(rows,cols,s1) + m1);
  VERIFY_IS_APPROX((m1*Scalar(2)).cwise() - s2, (m1+m1) - MatrixType::Constant(rows,cols,s2) );
  m3 = m1;
  m3.cwise() += s2;
  VERIFY_IS_APPROX(m3, m1.cwise() + s2);
  m3 = m1;
  m3.cwise() -= s1;
  VERIFY_IS_APPROX(m3, m1.cwise() - s1);
  VERIFY_IS_EQUAL((m1.corner(TopLeft,1,1)), (m1.block(0,0,1,1)));
  VERIFY_IS_EQUAL((m1.template corner<1,1>(TopLeft)), (m1.template block<1,1>(0,0)));
  VERIFY_IS_EQUAL((m1.col(0).start(1)), (m1.col(0).segment(0,1)));
  VERIFY_IS_EQUAL((m1.col(0).template start<1>()), (m1.col(0).segment(0,1)));
  VERIFY_IS_EQUAL((m1.col(0).end(1)), (m1.col(0).segment(rows-1,1)));
  VERIFY_IS_EQUAL((m1.col(0).template end<1>()), (m1.col(0).segment(rows-1,1)));
  using cos;
  using numext::real;
  using numext::abs2;
  VERIFY_IS_EQUAL(ei_cos(s1), cos(s1));
  VERIFY_IS_EQUAL(ei_real(s1), real(s1));
  VERIFY_IS_EQUAL(ei_abs2(s1), abs2(s1));
  m1.minor(0,0);
}
def test_eigen2support()
{
  for i in range(0, g_repeat) {
    CALL_SUBTEST_1( eigen2support(Matrix<double,1,1>()) );
    CALL_SUBTEST_2( eigen2support(MatrixXd(1,1)) );
    CALL_SUBTEST_4( eigen2support(Matrix3f()) );
    CALL_SUBTEST_5( eigen2support(Matrix4d()) );
    CALL_SUBTEST_2( eigen2support(MatrixXf(200,200)) );
    CALL_SUBTEST_6( eigen2support(MatrixXcd(100,100)) );
  }
}