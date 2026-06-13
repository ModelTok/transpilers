# This is a faithful translation of the C++ Eigen snippet to Mojo using Python's numpy for matrix operations.
# The original Eigen code uses MatrixXf and Map. Here we use numpy arrays with appropriate storage orders.

from python import Python
let np = Python.import_module("numpy")

# MatrixXf M1(3,3);    // Column-major storage
# M1 << 1, 2, 3,
#       4, 5, 6,
#       7, 8, 9;
var M1 = np.array([[1.0, 2.0, 3.0],
                   [4.0, 5.0, 6.0],
                   [7.0, 8.0, 9.0]], dtype=np.float32, order='F')  # Fortran (column-major) order

# Map<RowVectorXf> v1(M1.data(), M1.size());
# In numpy, we can flatten the array in the memory order (preserving the order in memory)
var v1 = M1.reshape(-1, order='A')  # 'A' means preserve order, which is column-major for M1

# cout << "v1:" << endl << v1 << endl;
print("v1:")
print(v1)

# Matrix<float,Dynamic,Dynamic,RowMajor> M2(M1);
# Create a copy of M1 in row-major order (C order)
var M2 = np.array(M1, dtype=np.float32, order='C')

# Map<RowVectorXf> v2(M2.data(), M2.size());
var v2 = M2.reshape(-1, order='A')

# cout << "v2:" << endl << v2 << endl;
print("v2:")
print(v2)