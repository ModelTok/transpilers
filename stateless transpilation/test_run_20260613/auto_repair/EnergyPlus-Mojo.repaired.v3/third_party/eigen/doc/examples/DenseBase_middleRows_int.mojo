from random import randint

struct MatrixXi:
    var rows: Int
    var cols: Int
    var data: List[List[Int]]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[List[Int]](capacity=rows)
        for i in range(rows):
            self.data.append(List[Int](capacity=cols))
            for j in range(cols):
                self.data[i].append(0)

    def __str__(self) -> String:
        var out = String()
        for i in range(self.rows):
            for j in range(self.cols):
                if j != 0:
                    out += " "
                out += str(self.data[i][j])
            if i != self.rows - 1:
                out += "\n"
        return out

    def setRandom(inout self):
        for i in range(self.rows):
            for j in range(self.cols):
                self.data[i][j] = randint(-100, 100)

    def middleRows(self, start: Int, nrows: Int) -> Self:
        var result = MatrixXi(nrows, self.cols)
        for i in range(nrows):
            for j in range(self.cols):
                result.data[i][j] = self.data[start + i][j]
        return result


def main():
    let N: Int = 5
    var A = MatrixXi(N, N)
    A.setRandom()
    print("A =\n")
    print(A)
    print()
    print("A(2..3,:) =")
    print(A.middleRows(2, 2))
    print()