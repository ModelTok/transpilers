// C++ oracle: DEFINES the EnergyPlus/ObjexxFCL domain helpers (mirror of
// ep_prelude.mojo) so real EP functions compile+run standalone for reference
// outputs. Stubs for external functions match the Mojo shim so the test
// isolates the model's BODY translation.
#include <cmath>
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
  const double Kelvin=273.15, StefanBoltzmann=5.6697e-8, DegToRad=0.0174532925199432958, RadToDeg=57.2957795130823209;
}
namespace DataPrecisionGlobals{ const double EXP_LowerLimit=-20.0, constant_zero=0.0, constant_one=1.0; }
namespace TARCOGParams{ const int MMax=100, NMax=100; }
