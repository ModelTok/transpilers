from python import Python
from math import acos, cos, sin, pi as std_pi

# Helper to expose Python modules for matrix operations
np = Python.import_module("numpy")
scipy_linalg = Python.import_module("scipy.linalg")

# Define a module 'std' to mimic  namespace
struct std:
    @staticmethod
    def acos(x: Float64) -> Float64:
        return acos(x)

    class cout:
        var buffer: String
        def __init__(inout self):
            self.buffer = String("")
        def __lshift__(inout self, value: String) -> Self:
            self.buffer += value
            return self
        def __lshift__(inout self, value: Int) -> Self:
            self.buffer += str(value)
            return self
        def __lshift__(inout self, value: Float64) -> Self:
            self.buffer += str(value)
            return self
        def __lshift__(inout self, value: Self) -> Self:
            self.buffer += value.buffer
            return self
        def __lshift__(inout self, value: Matrix3d) -> Self:
            # Convert numpy matrix to string
            self.buffer += str(value.data.tolist())  # simplified
            return self
        def __lshift__(inout self, value: __endl_type) -> Self:
            print(self.buffer)
            self.buffer = String("")
            return self

    struct endl_type:

    var endl = endl_type()

# Define Matrix3d class
class Matrix3d:
    var data: PythonObject  # holds a numpy 3x3 array

    def __init__(inout self):
        self.data = np.zeros((3, 3), dtype=np.float64)

    def __init__(inout self, other: Self):
        self.data = np.copy(other.data)

    # The comma initializer via << - we use a helper initializer object
    def __rlshift__(inout self, values: List[Float64]) -> Matrix3dInitializer:
        return Matrix3dInitializer(self, values)

    def __lshift__(inout self, values: PythonObject) -> Matrix3dInitializer:
        # If values is a list, start initializer
        if isinstance(values, PythonObject) and not isinstance(values, Matrix3dInitializer):
            return Matrix3dInitializer(self, values)
        else:
            return self

    def pow(inout self, exponent: Float64) -> Self:
        # Use scipy fractional matrix power
        result_data = scipy_linalg.fractional_matrix_power(self.data, exponent)
        var result = Self()
        result.data = result_data
        return result

    def __str__(self) -> String:
        # Pretty print 3x3 matrix
        var s = String("")
        for i in range(3):
            s += "["
            for j in range(3):
                s += str(self.data[i, j])
                if j < 2:
                    s += ", "
            s += "]"
            if i < 2:
                s += "\n"
        return s

# Helper class for comma initializer
class Matrix3dInitializer:
    var mat: Matrix3d
    var idx: Int

    def __init__(inout self, mat: Matrix3d, values: PythonObject):
        self.mat = mat
        self.idx = 0
        # Convert values to flat list if needed
        if isinstance(values, PythonObject):
            flat = [float(v) for v in values]  # assume values is iterable
            for i in range(3):
                for j in range(3):
                    if self.idx < len(flat):
                        self.mat.data[i, j] = flat[self.idx]
                        self.idx += 1
                    else:
                        break

    def __lshift__(inout self, value: Float64) -> Self:
        # Continue initializing
        row = self.idx // 3
        col = self.idx % 3
        if row < 3 and col < 3:
            self.mat.data[row, col] = value
            self.idx += 1
        return self

    def __iter__(self):
        return self

    def __next__(inout self) -> Float64:
        if self.idx >= 9:
            raise StopIteration()
        row = self.idx // 3
        col = self.idx % 3
        val = self.mat.data[row, col]
        self.idx += 1
        return val

# Main function
def main():
    var pi = std.acos(-1.0)
    var A = Matrix3d()
    # Emulate A << cos(1), -sin(1), 0, sin(1), cos(1), 0, 0, 0, 1;
    var init = A << [cos(1), -sin(1), 0, sin(1), cos(1), 0, 0, 0, 1]
    # The above line uses the initializer and sets A's data
    A = init.mat  # actually init already modifies A, but ensure
    std.cout << "The matrix A is:\n" << A << "\n\n" << "The matrix power A^(pi/4) is:\n" << A.pow(pi / 4) << std.endl