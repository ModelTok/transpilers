from memory import List

struct MatrixXi:
    var data: List[List[Int]]
    var rows_: Int
    var cols_: Int

    def __init__(out self, rows: Int, cols: Int):
        self.rows_ = rows
        self.cols_ = cols
        self.data = List[List[Int]](rows, List[Int](cols, 0))

    def rows(self) -> Int:
        return self.rows_

    def cols(self) -> Int:
        return self.cols_

    def __getitem__(self, i: Int, j: Int) -> Int:
        return self.data[i][j]

    def __setitem__(self, i: Int, j: Int, value: Int):
        self.data[i][j] = value

    def __str__(self) -> String:
        var result = String("")
        for i in range(self.rows_):
            for j in range(self.cols_):
                result += str(self.data[i][j])
                if j < self.cols_ - 1:
                    result += " "
            if i < self.rows_ - 1:
                result += "\n"
        return result

alias VectorXf = List[Float]

def main():
    for size in range(1, 5):         # for (int size=1; size<=4; ++size)
        var m = MatrixXi(size, size+1)  # a (size)x(size+1)-matrix of int's
        for j in range(m.cols()):       # loop over columns
            for i in range(m.rows()):   # loop over rows
                m[i, j] = i + j * size # to access matrix coefficients,
        print(m)
        print()                         # cout << m << "\n\n";
    var v = VectorXf(4, 0.0)            # VectorXf v(4); // a vector of 4 float's
    v[0] = 1.0; v[1] = 2.0; v[2] = 3.0; v[3] = 4.0
    print("\nv:")
    print(v)