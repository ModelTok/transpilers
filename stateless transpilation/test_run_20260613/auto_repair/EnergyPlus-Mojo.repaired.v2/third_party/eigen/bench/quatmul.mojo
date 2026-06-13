#include <iostream>
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <bench/BenchTimer.h>
template<Quat>
EIGEN_DONT_INLINE void quatmul_default(Quat& a , Quat& b , Quat& c)
{
  c = a * b;
}
template<Quat>
EIGEN_DONT_INLINE void quatmul_novec(Quat& a , Quat& b , Quat& c)
{
  c = internal::quat_product<0, Quat, Quat, Quat::Scalar, Aligned>::run(a,b);
}
template<Quat> void bench(string& label )
{
  int tries = 10;
  int rep = 1000000;
  BenchTimer t;
  Quat a(4, 1, 2, 3);
  Quat b(2, 3, 4, 5);
  Quat c;
  cout.precision(3);
  BENCH(t, tries, rep, quatmul_default(a,b,c));
  cout << label << " default " << 1e3*t.best(CPU_TIMER) << "ms  \t" << 1e-6*double(rep)/(t.best(CPU_TIMER)) << " M mul/s\n";
  BENCH(t, tries, rep, quatmul_novec(a,b,c));
  cout << label << " novec   " << 1e3*t.best(CPU_TIMER) << "ms  \t" << 1e-6*double(rep)/(t.best(CPU_TIMER)) << " M mul/s\n";
}
def main()
{
  bench<Quaternionf>("float ");
  bench<Quaterniond>("double");
  return 0;
}