// C++ oracle: DEFINES the EnergyPlus/ObjexxFCL domain helpers (mirror of
// ep_prelude.mojo) so real EP functions compile+run standalone for reference
// outputs. Stubs for external functions match the Mojo shim so the test
// isolates the model's BODY translation.
#include <cmath>
#include <vector>
typedef double Real64; typedef long long Int64; typedef int Int;
static const double SMALL = 1e-10;
inline double pow_2(double x){return x*x;}
inline double pow_3(double x){return x*x*x;}
inline double pow_4(double x){return (x*x)*(x*x);}
inline double pow_5(double x){return (x*x)*(x*x)*x;}
inline double pow_6(double x){return (x*x*x)*(x*x*x);}
inline double pow_7(double x){return (x*x*x)*(x*x*x)*x;}
inline double root_4(double x){return std::sqrt(std::sqrt(x));}
inline double root_8(double x){return std::sqrt(std::sqrt(std::sqrt(x)));}
inline double mod(double a,double b){return a - b*std::trunc(a/b);}
inline double sign(double a,double b){return b>=0.0? std::fabs(a):-std::fabs(a);}
inline double radians(double x){return x*0.0174532925199432958;}
inline double pvstar(double T){return 611.65;}   // stub matching Mojo shim
namespace Constant{
  const double Pi=3.14159265358979324, TwoPi=6.28318530717958648, PiOvr2=1.57079632679489662;
  const double Kelvin=273.15, StefanBoltzmann=5.6697e-8, Sigma=5.6697e-8, DegToRad=0.0174532925199432958, RadToDeg=57.2957795130823209;
  const double UniversalGasConstant=8314.462175, Gravity=9.807;
}
namespace DataPrecisionGlobals{ const double EXP_LowerLimit=-20.0, constant_zero=0.0, constant_one=1.0; }
namespace TARCOGParams{ const int MMax=100, NMax=100; }

// ObjexxFCL-style 1-based dense arrays (mirror ep_prelude.mojo). C++ keeps the
// `a(i)` / `a(i,j)` call syntax used by real EP code; semantics are 1-based.
struct Array1D {
  std::vector<double> _d;
  Array1D(int n=0, double fill=0.0): _d(n, fill) {}
  double& operator()(int i){ return _d[i-1]; }
  double operator()(int i) const { return _d[i-1]; }
  int size() const { return (int)_d.size(); }
};
struct Array2D {
  std::vector<double> _d; int _rows, _cols;
  Array2D(int rows=0, int cols=0, double fill=0.0): _d(rows*cols, fill), _rows(rows), _cols(cols) {}
  double& operator()(int i,int j){ return _d[(i-1)*_cols+(j-1)]; }
  double operator()(int i,int j) const { return _d[(i-1)*_cols+(j-1)]; }
  int size() const { return (int)_d.size(); }
};
