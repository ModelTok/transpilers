#include <Eigen/Dense>
#include <iostream>
void copyUpperTriangularPart(MatrixXf& dst, MatrixXf& src )
{
  dst.triangularView<Upper>() = src.triangularView<Upper>();
}
int main()
{
  MatrixXf m1 = MatrixXf::Ones(4,4);
  MatrixXf m2 = MatrixXf::Random(4,4);
  cout << "m2 before copy:" << endl;
  cout << m2 << endl << endl;
  copyUpperTriangularPart(m2, m1);
  cout << "m2 after copy:" << endl;
  cout << m2 << endl << endl;
}