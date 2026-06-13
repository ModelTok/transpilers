from Eigen import Array33f, ArrayXf, ArrayXXf

print("A fixed-size array:")
let a1 = Array33f.Zero()
print(a1)
print("\n")
print("A one-dimensional dynamic-size array:")
let a2 = ArrayXf.Zero(3)
print(a2)
print("\n")
print("A two-dimensional dynamic-size array:")
let a3 = ArrayXXf.Zero(3, 4)
print(a3)
print("\n")