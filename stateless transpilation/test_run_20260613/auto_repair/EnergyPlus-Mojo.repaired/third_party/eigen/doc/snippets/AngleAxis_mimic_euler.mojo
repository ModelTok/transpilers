from Eigen import Matrix3f, AngleAxisf, Vector3f, M_PI

var m: Matrix3f
m = AngleAxisf(0.25 * M_PI, Vector3f.UnitX()) * AngleAxisf(0.5 * M_PI, Vector3f.UnitY()) * AngleAxisf(0.33 * M_PI, Vector3f.UnitZ())
print(m, "is unitary:", m.isUnitary())