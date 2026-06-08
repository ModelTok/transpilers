// EnergyPlus / ObjexxFCL domain declarations for transpiler snippet parsing.
// Point $TRANSPILERS_CPP_PREAMBLE_FILE at this when transpiling EnergyPlus code.
typedef double Real64;
typedef long long Int64;
typedef int Int;
// ObjexxFCL integer-power helpers (mapped to ** by the Mojo backend).
double pow_2(double); double pow_3(double); double pow_4(double);
double pow_5(double); double pow_6(double); double pow_7(double);
// ObjexxFCL integer-root helpers: root_4(x)==x^(1/4)==sqrt(sqrt(x)),
// root_8(x)==x^(1/8) (Fmath.hh). Mapped to nested sqrt by the Mojo backend.
double root_4(double); double root_8(double);
// ObjexxFCL / Fortran scalar intrinsics (mapped by the Mojo backend).
double mod(double, double); int mod(int, int);
double sign(double, double); int sign(int, int);
// `assert` — declared so debug-build precondition checks parse; the Mojo
// backend drops the call (assert is compiled out under NDEBUG and never affects
// the returned value), and the verification oracle is built with -DNDEBUG.
void assert(bool);
// EnergyPlus `Constant::` physical constants (exact values from Constant.hh) so
// functions referencing them parse AND the verification oracle links with the
// real values. libclang constant-folds these into literals in the AST.
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
// EnergyPlus `DataPrecisionGlobals::` constants (exact values from
// DataPrecisionGlobals.hh). libclang constant-folds these into literals.
namespace DataPrecisionGlobals {
    constexpr double constant_zero = 0.0;
    constexpr double constant_one = 1.0;
    constexpr double constant_minusone = -1.0;
    constexpr double constant_twenty = 20.0;
    constexpr double constant_pointfive = 0.5;
    constexpr double EXP_LowerLimit = -20.0;
    constexpr double EXP_UpperLimit = 40.0;
}
