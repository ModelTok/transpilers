from Eigen import Matrix2d, Matrix2f

var md = Matrix2d.Identity() * 0.45
var mf = Matrix2f.Identity()
print(md + mf.cast[Float64]())