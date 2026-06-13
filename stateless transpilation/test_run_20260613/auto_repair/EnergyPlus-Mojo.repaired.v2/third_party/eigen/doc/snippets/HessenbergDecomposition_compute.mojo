var A = MatrixXcf.Random(4,4)
var hd = HessenbergDecomposition[MatrixXcf](4)
hd.compute(A)
print("The matrix H in the decomposition of A is:")
print(hd.matrixH())
hd.compute(2*A) # re-use hd to compute and store decomposition of 2A
print("The matrix H in the decomposition of 2A is:")
print(hd.matrixH())