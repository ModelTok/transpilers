typedef double Real64;
typedef long long Int64;
typedef int Int;
double pow_2(double); double pow_3(double); double pow_4(double);
double pow_5(double); double pow_6(double); double pow_7(double);
double root_4(double); double root_8(double);
double mod(double, double); int mod(int, int);
double sign(double, double); int sign(int, int);
void assert(bool);
namespace Constant {
    constexpr double MaxEXPArg = 709.78;
    constexpr double Pi = 3.14159265358979324;
    constexpr double PiOvr2 = Pi / 2.0;
    constexpr double TwoPi = 2.0 * Pi;
    constexpr double Gravity = 9.807;
    constexpr double DegToRad = Pi / 180.0;
    constexpr double RadToDeg = 180.0 / Pi;
    constexpr double Kelvin = 273.15;
    constexpr double TriplePointOfWaterTempKelvin = 273.16;
    constexpr double StefanBoltzmann = 5.6697E-8;
}
namespace DataPrecisionGlobals {
    constexpr double constant_zero = 0.0;
    constexpr double constant_one = 1.0;
    constexpr double constant_minusone = -1.0;
    constexpr double constant_twenty = 20.0;
    constexpr double constant_pointfive = 0.5;
    constexpr double EXP_LowerLimit = -20.0;
    constexpr double EXP_UpperLimit = 40.0;
}
