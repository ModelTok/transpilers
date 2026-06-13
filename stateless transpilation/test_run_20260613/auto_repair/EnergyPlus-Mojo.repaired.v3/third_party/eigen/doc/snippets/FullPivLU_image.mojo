from Eigen import Matrix3d, FullPivLU

var m = Matrix3d(1,1,0, 1,3,2, 0,1,1)
print("Here is the matrix m:")
print(m)
print("Notice that the middle column is the sum of the two others, so the columns are linearly dependent.")
print("Here is a matrix whose columns have the same span but are linearly independent:")
print(m.fullPivLu().image(m))