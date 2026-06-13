var matA = MatrixXf(2, 2);
matA << 1, 2, 3, 4;
var matB = MatrixXf(4, 4);
matB << matA, matA/10, matA/10, matA;
print(matB);