from ...Eigen import Matrix3d, IOFormat, StreamPrecision, DontAlignCols, FullPrecision

var sep: String = "\n----------------------------------------\n"
var m1: Matrix3d
m1 = Matrix3d(1.111111, 2, 3.33333, 4, 5, 6, 7, 8.888888, 9)
var CommaInitFmt: IOFormat = IOFormat(StreamPrecision, DontAlignCols, ", ", ", ", "", "", " << ", ";")
var CleanFmt: IOFormat = IOFormat(4, 0, ", ", "\n", "[", "]")
var OctaveFmt: IOFormat = IOFormat(StreamPrecision, 0, ", ", ";\n", "", "", "[", "]")
var HeavyFmt: IOFormat = IOFormat(FullPrecision, 0, ", ", ";\n", "[", "]", "[", "]")
print(m1, end="")
print(sep, end="")
print(m1.format(CommaInitFmt), end="")
print(sep, end="")
print(m1.format(CleanFmt), end="")
print(sep, end="")
print(m1.format(OctaveFmt), end="")
print(sep, end="")
print(m1.format(HeavyFmt), end="")
print(sep, end="")