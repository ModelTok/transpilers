from ...Eigen import MatrixXi

m = MatrixXi.Random(3, 4)
print("Here is the matrix m:")
print(m)
print("Here is the reverse of m:")
print(m.reverse())
print("Here is the coefficient (1,0) in the reverse of m:")
print(m.reverse()[1, 0])
print("Let us overwrite this coefficient with the value 4.")
m.reverse()[1, 0] = 4
print("Now the matrix m is:")
print(m)