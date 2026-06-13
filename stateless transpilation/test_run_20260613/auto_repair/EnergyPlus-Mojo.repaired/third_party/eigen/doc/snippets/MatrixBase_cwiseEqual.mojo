# Mojo translation of MatrixBase_cwiseEqual.cpp
# Requires a MatrixXi type with cwiseEqual, Identity, count methods.

struct MatrixXi:
    var rows: Int
    var cols: Int
    var data: List[List[Int]]

    def __init__(inout self, r: Int, c: Int):
        self.rows = r
        self.cols = c
        self.data = List[List[Int]]()
        for i in range(r):
            var row = List[Int]()
            for j in range(c):
                row.append(0)
            self.data.append(row)

    def __getitem__(self, i: Int, j: Int) -> Int:
        return self.data[i][j]

    def __setitem__(inout self, i: Int, j: Int, val: Int):
        self.data[i][j] = val

    def __str__(self) -> String:
        var s = String()
        for i in range(self.rows):
            for j in range(self.cols):
                s += str(self.data[i][j])
                if j < self.cols - 1:
                    s += " "
            if i < self.rows - 1:
                s += "\n"
        return s

    @staticmethod
    def Identity(n: Int) -> MatrixXi:
        var mat = MatrixXi(n, n)
        for i in range(n):
            mat[i, i] = 1
        return mat

    def cwiseEqual(self, other: MatrixXi) -> MatrixXi:
        var result = MatrixXi(self.rows, self.cols)
        for i in range(self.rows):
            for j in range(self.cols):
                if self.data[i][j] == other.data[i][j]:
                    result[i, j] = 1
                else:
                    result[i, j] = 0
        return result

    def count(self) -> Int:
        var cnt = 0
        for i in range(self.rows):
            for j in range(self.cols):
                if self.data[i][j] != 0:
                    cnt += 1
        return cnt


def main():
    var m = MatrixXi(2, 2)
    m[0, 0] = 1
    m[0, 1] = 0
    m[1, 0] = 1
    m[1, 1] = 1
    print("Comparing m with identity matrix:")
    print(m.cwiseEqual(MatrixXi.Identity(2, 2)))
    var count: Int = m.cwiseEqual(MatrixXi.Identity(2, 2)).count()
    print("Number of coefficients that are equal: ", count)