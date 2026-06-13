// Equivalent Mojo translation of Eigen DenseBase_template_int_middleRows.cpp
// Uses a custom MatrixXi class to replicate Eigen::MatrixXi behavior.
from python import Python

struct MatrixXi:
    var data: List[List[Int]]
    var rows: Int
    var cols: Int

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[List[Int]]()
        for i in range(rows):
            var row = List[Int]()
            for j in range(cols):
                row.append(0)
            self.data.append(row)

    def setRandom(inout self):
        let py = Python.import("random")
        for i in range(self.rows):
            for j in range(self.cols):
                self.data[i][j] = py.randint(-100, 100)  # arbitrary range

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

    def middleRows[N: Int](self, start: Int) -> MatrixXi:
        var new_mat = MatrixXi(N, self.cols)
        for i in range(N):
            for j in range(self.cols):
                new_mat.data[i][j] = self.data[start + i][j]
        return new_mat

def main() raises:
    let N: Int = 5
    var A = MatrixXi(N, N)
    A.setRandom()
    print("A =\n" + str(A) + "\n")
    print("A(1..3,:) =\n" + str(A.middleRows[3](1)) + "\n")