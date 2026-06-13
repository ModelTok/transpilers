from math import sqrt
from random import rand, seed
# Simulate Eigen types

struct Matrix2f:
    var m00: Float32
    var m01: Float32
    var m10: Float32
    var m11: Float32

    @staticmethod
    def Random() -> Matrix2f:
        # random between -1 and 1
        seed()  # ensure different random each run
        return Matrix2f(
            rand() * 2.0 - 1.0,
            rand() * 2.0 - 1.0,
            rand() * 2.0 - 1.0,
            rand() * 2.0 - 1.0,
        )

    def adjoint(self) -> Matrix2f:
        return Matrix2f(self.m00, self.m10, self.m01, self.m11)

    def __getitem__(self, i: Int, j: Int) -> Float32:
        if i == 0:
            if j == 0:
                return self.m00
            elif j == 1:
                return self.m01
        elif i == 1:
            if j == 0:
                return self.m10
            elif j == 1:
                return self.m11
        return Float32(0.0)  # out of bounds

    def __setitem__(self, i: Int, j: Int, val: Float32):
        if i == 0:
            if j == 0:
                self.m00 = val
            elif j == 1:
                self.m01 = val
        elif i == 1:
            if j == 0:
                self.m10 = val
            elif j == 1:
                self.m11 = val

    def applyOnTheLeft(self, p: Int, q: Int, J: JacobiRotation[Float32]):
        # Apply Jacobi rotation on left (rows p and q)
        # new row p = c * row_p + s * row_q
        # new row q = -s * row_p + c * row_q
        var row_p0 = self[p,0]
        var row_p1 = self[p,1]
        var row_q0 = self[q,0]
        var row_q1 = self[q,1]
        self[p,0] = J.c * row_p0 + J.s * row_q0
        self[p,1] = J.c * row_p1 + J.s * row_q1
        self[q,0] = -J.s * row_p0 + J.c * row_q0
        self[q,1] = -J.s * row_p1 + J.c * row_q1

    def applyOnTheRight(self, p: Int, q: Int, J: JacobiRotation[Float32]):
        # Apply Jacobi rotation on right (columns p and q)
        # new col p = c * col_p + s * col_q
        # new col q = -s * col_p + c * col_q
        var col_p0 = self[0,p]
        var col_p1 = self[1,p]
        var col_q0 = self[0,q]
        var col_q1 = self[1,q]
        self[0,p] = J.c * col_p0 + J.s * col_q0
        self[1,p] = J.c * col_p1 + J.s * col_q1
        self[0,q] = -J.s * col_p0 + J.c * col_q0
        self[1,q] = -J.s * col_p1 + J.c * col_q1


struct JacobiRotation[type: DType = DType.float32]:
    var c: Float32
    var s: Float32

    def makeJacobi(self, m: Matrix2f, p: Int, q: Int):
        # Computes Jacobi rotation such that off-diagonal element becomes zero
        # for symmetric matrix m
        var tau = (m[q,q] - m[p,p]) / (2.0 * m[p,q])
        var t: Float32
        if tau >= 0.0:
            t = 1.0 / (tau + sqrt(1.0 + tau*tau))
        else:
            t = -1.0 / (-tau + sqrt(1.0 + tau*tau))
        self.c = 1.0 / sqrt(1.0 + t*t)
        self.s = self.c * t

    def adjoint(self) -> JacobiRotation[type]:
        return JacobiRotation[type](self.c, -self.s)


def main():
    var m: Matrix2f = Matrix2f.Random()
    m = (m + m.adjoint()).__init__()  # evaluate to symmetric
    var J: JacobiRotation[float] = JacobiRotation[float]()
    J.makeJacobi(m, 0, 1)
    print("Here is the matrix m:")
    print(m.m00, m.m01)
    print(m.m10, m.m11)
    m.applyOnTheLeft(0, 1, J.adjoint())
    m.applyOnTheRight(0, 1, J)
    print("Here is the matrix J' * m * J:")
    print(m.m00, m.m01)
    print(m.m10, m.m11)