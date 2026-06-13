from ...Eigen import MatrixXf

var m = MatrixXf.Random(3,5)
print("Here is the matrix m:")
print(m)
var ker = m.fullPivLu().kernel()
print("Here is a matrix whose columns form a basis of the kernel of m:")
print(ker)
print("By definition of the kernel, m*ker is zero:")
print(m*ker)