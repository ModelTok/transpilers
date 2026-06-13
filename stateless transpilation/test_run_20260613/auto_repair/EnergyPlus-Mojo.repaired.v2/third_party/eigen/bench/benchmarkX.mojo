
alias MATTYPE = MatrixX
alias MATSIZE = 400
alias REPEAT = 100

struct MatrixX:
    var rows: Int
    var cols: Int
    var data: List[Float64]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[Float64](0.0 for _ in range(rows * cols))

    @staticmethod
    def Ones(rows: Int, cols: Int) -> MatrixX:
        var mat = MatrixX(rows, cols)
        for i in range(rows * cols):
            mat.data[i] = 1.0
        return mat

    def __getitem__(self, i: Int, j: Int) -> Float64:
        return self.data[i * self.cols + j]

    def __setitem__(self, i: Int, j: Int, value: Float64):
        self.data[i * self.cols + j] = value

    def __add__(self, other: MatrixX) -> MatrixX:
        var result = MatrixX(self.rows, self.cols)
        for i in range(self.rows * self.cols):
            result.data[i] = self.data[i] + other.data[i]
        return result

    def __mul__(self, other: MatrixX) -> MatrixX:
        var result = MatrixX(self.rows, other.cols)
        for i in range(self.rows):
            for j in range(other.cols):
                var sum: Float64 = 0.0
                for k in range(self.cols):
                    sum += self.data[i * self.cols + k] * other.data[k * other.cols + j]
                result.data[i * result.cols + j] = sum
        return result

    def __rmul__(self, scalar: Float64) -> MatrixX:
        var result = MatrixX(self.rows, self.cols)
        for i in range(self.rows * self.cols):
            result.data[i] = scalar * self.data[i]
        return result

def main() raises:
    var I = MATTYPE.Ones(MATSIZE, MATSIZE)
    var m = MATTYPE(MATSIZE, MATSIZE)
    for i in range(MATSIZE):
        for j in range(MATSIZE):
            m[i, j] = Float64((i + j + 1) // (MATSIZE * MATSIZE))
    for a in range(REPEAT):
        m = I + 0.0001 * (m + m * m)
    print(m[0, 0])