// EnergyPlus / ObjexxFCL domain declarations for transpiler snippet parsing.
// Point $TRANSPILERS_CPP_PREAMBLE_FILE at this when transpiling EnergyPlus code.
typedef double Real64;
typedef long long Int64;
typedef int Int;
// ObjexxFCL integer-power helpers (mapped to ** by the Mojo backend).
double pow_2(double); double pow_3(double); double pow_4(double);
double pow_5(double); double pow_6(double); double pow_7(double);
// ObjexxFCL / Fortran scalar intrinsics (mapped by the Mojo backend).
double mod(double, double); int mod(int, int);
double sign(double, double); int sign(int, int);
