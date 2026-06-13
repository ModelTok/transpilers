#include "main.h"
#include <Eigen/StdList>
#include <Eigen/Geometry>
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Vector4f)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Matrix2f)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Matrix4f)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Matrix4d)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Affine3f)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Affine3d)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Quaternionf)
EIGEN_DEFINE_STL_LIST_SPECIALIZATION(Quaterniond)
template <class Container, class Position>
Container::iterator get(Container & c, Position position)
{
  Container::iterator it = c.begin();
  advance(it, position);
  return it;
}
template <class Container, class Position, class Value>
void set(Container & c, Position position, Value & value )
{
  Container::iterator it = c.begin();
  advance(it, position);
  *it = value;
}
template<MatrixType>
void check_stdlist_matrix(MatrixType& m )
{
  MatrixType::Index rows = m.rows();
  MatrixType::Index cols = m.cols();
  MatrixType x = MatrixType::Random(rows,cols), y = MatrixType::Random(rows,cols);
  list<MatrixType> v(10, MatrixType(rows,cols)), w(20, y);
  list<MatrixType>::iterator itv = get(v, 5);
  list<MatrixType>::iterator itw = get(w, 6);
  *itv = x;
  *itw = *itv;
  VERIFY_IS_APPROX(*itw, *itv);
  v = w;
  itv = v.begin();
  itw = w.begin();
  for(int i = 0; i < 20; i++)
  {
    VERIFY_IS_APPROX(*itw, *itv);
    ++itv;
    ++itw;
  }
  v.resize(21);
  set(v, 20, x);
  VERIFY_IS_APPROX(*get(v, 20), x);
  v.resize(22,y);
  VERIFY_IS_APPROX(*get(v, 21), y);
  v.push_back(x);
  VERIFY_IS_APPROX(*get(v, 22), x);
  MatrixType* ref = &(*get(w, 0));
  for(int i=0; i<30 || ((ref==&(*get(w, 0))) && i<300); ++i)
    v.push_back(*get(w, i%w.size()));
  for(unsigned int i=23; i<v.size(); ++i)
  {
    VERIFY((*get(v, i))==(*get(w, (i-23)%w.size())));
  }
}
template<TransformType>
void check_stdlist_transform(const TransformType&)
{
  typedef TransformType::MatrixType MatrixType;
  TransformType x(MatrixType::Random()), y(MatrixType::Random());
  list<TransformType> v(10), w(20, y);
  list<TransformType>::iterator itv = get(v, 5);
  list<TransformType>::iterator itw = get(w, 6);
  *itv = x;
  *itw = *itv;
  VERIFY_IS_APPROX(*itw, *itv);
  v = w;
  itv = v.begin();
  itw = w.begin();
  for(int i = 0; i < 20; i++)
  {
    VERIFY_IS_APPROX(*itw, *itv);
    ++itv;
    ++itw;
  }
  v.resize(21);
  set(v, 20, x);
  VERIFY_IS_APPROX(*get(v, 20), x);
  v.resize(22,y);
  VERIFY_IS_APPROX(*get(v, 21), y);
  v.push_back(x);
  VERIFY_IS_APPROX(*get(v, 22), x);
  TransformType* ref = &(*get(w, 0));
  for(int i=0; i<30 || ((ref==&(*get(w, 0))) && i<300); ++i)
    v.push_back(*get(w, i%w.size()));
  for(unsigned int i=23; i<v.size(); ++i)
  {
    VERIFY(get(v, i)->matrix()==get(w, (i-23)%w.size())->matrix());
  }
}
template<QuaternionType>
void check_stdlist_quaternion(const QuaternionType&)
{
  typedef QuaternionType::Coefficients Coefficients;
  QuaternionType x(Coefficients::Random()), y(Coefficients::Random());
  list<QuaternionType> v(10), w(20, y);
  list<QuaternionType>::iterator itv = get(v, 5);
  list<QuaternionType>::iterator itw = get(w, 6);
  *itv = x;
  *itw = *itv;
  VERIFY_IS_APPROX(*itw, *itv);
  v = w;
  itv = v.begin();
  itw = w.begin();
  for(int i = 0; i < 20; i++)
  {
    VERIFY_IS_APPROX(*itw, *itv);
    ++itv;
    ++itw;
  }
  v.resize(21);
  set(v, 20, x);
  VERIFY_IS_APPROX(*get(v, 20), x);
  v.resize(22,y);
  VERIFY_IS_APPROX(*get(v, 21), y);
  v.push_back(x);
  VERIFY_IS_APPROX(*get(v, 22), x);
  QuaternionType* ref = &(*get(w, 0));
  for(int i=0; i<30 || ((ref==&(*get(w, 0))) && i<300); ++i)
    v.push_back(*get(w, i%w.size()));
  for(unsigned int i=23; i<v.size(); ++i)
  {
    VERIFY(get(v, i)->coeffs()==get(w, (i-23)%w.size())->coeffs());
  }
}
void test_stdlist_overload()
{
  CALL_SUBTEST_1(check_stdlist_matrix(Vector2f()));
  CALL_SUBTEST_1(check_stdlist_matrix(Matrix3f()));
  CALL_SUBTEST_2(check_stdlist_matrix(Matrix3d()));
  CALL_SUBTEST_1(check_stdlist_matrix(Matrix2f()));
  CALL_SUBTEST_1(check_stdlist_matrix(Vector4f()));
  CALL_SUBTEST_1(check_stdlist_matrix(Matrix4f()));
  CALL_SUBTEST_2(check_stdlist_matrix(Matrix4d()));
  CALL_SUBTEST_3(check_stdlist_matrix(MatrixXd(1,1)));
  CALL_SUBTEST_3(check_stdlist_matrix(VectorXd(20)));
  CALL_SUBTEST_3(check_stdlist_matrix(RowVectorXf(20)));
  CALL_SUBTEST_3(check_stdlist_matrix(MatrixXcf(10,10)));
  CALL_SUBTEST_4(check_stdlist_transform(Affine2f())); // does not need the specialization (2+1)^2 = 9
  CALL_SUBTEST_4(check_stdlist_transform(Affine3f()));
  CALL_SUBTEST_4(check_stdlist_transform(Affine3d()));
  CALL_SUBTEST_5(check_stdlist_quaternion(Quaternionf()));
  CALL_SUBTEST_5(check_stdlist_quaternion(Quaterniond()));
}