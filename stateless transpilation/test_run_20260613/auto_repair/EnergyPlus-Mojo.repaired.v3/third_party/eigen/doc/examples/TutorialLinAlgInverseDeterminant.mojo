from std import print

struct Matrix3f:
    var data: StaticArray[Float32, 9]

    def __init__(out self, *values: Float32):
        self.data = StaticArray[Float32, 9](*values)

    def determinant(self) -> Float32:
        let a11 = self.data[0]; let a12 = self.data[1]; let a13 = self.data[2]
        let a21 = self.data[3]; let a22 = self.data[4]; let a23 = self.data[5]
        let a31 = self.data[6]; let a32 = self.data[7]; let a33 = self.data[8]
        return a11 * (a22 * a33 - a23 * a32) - a12 * (a21 * a33 - a23 * a31) + a13 * (a21 * a32 - a22 * a31)

    def inverse(self) -> Matrix3f:
        let det = self.determinant()
        let inv_det = 1.0 / det
        let a11 = self.data[0]; let a12 = self.data[1]; let a13 = self.data[2]
        let a21 = self.data[3]; let a22 = self.data[4]; let a23 = self.data[5]
        let a31 = self.data[6]; let a32 = self.data[7]; let a33 = self.data[8]
        let b11 = (a22 * a33 - a23 * a32) * inv_det
        let b12 = (a13 * a32 - a12 * a33) * inv_det
        let b13 = (a12 * a23 - a13 * a22) * inv_det
        let b21 = (a23 * a31 - a21 * a33) * inv_det
        let b22 = (a11 * a33 - a13 * a31) * inv_det
        let b23 = (a13 * a21 - a11 * a23) * inv_det
        let b31 = (a21 * a32 - a22 * a31) * inv_det
        let b32 = (a12 * a31 - a11 * a32) * inv_det
        let b33 = (a11 * a22 - a12 * a21) * inv_det
        return Matrix3f(b11, b12, b13, b21, b22, b23, b31, b32, b33)

    def __str__(self) -> String:
        var s = String("")
        for i in range(3):
            let row_start = i * 3
            s += (self.data[row_start].__str__() + " " + self.data[row_start+1].__str__() + " " + self.data[row_start+2].__str__() + "\n")
        return s

def main():
    var A = Matrix3f(1.0, 2.0, 1.0, 2.0, 1.0, 0.0, -1.0, 1.0, 2.0)
    print("Here is the matrix A:")
    print(A)
    print("The determinant of A is", A.determinant())
    print("The inverse of A is:")
    print(A.inverse())