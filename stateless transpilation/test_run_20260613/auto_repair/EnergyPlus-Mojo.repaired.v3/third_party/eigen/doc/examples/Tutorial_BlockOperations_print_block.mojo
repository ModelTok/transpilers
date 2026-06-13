struct MatrixXf:
    var data: List[List[Float32]]

    def __init__(inout self, rows: Int, cols: Int):
        self.data = List[List[Float32]]()
        for i in range(rows):
            var row = List[Float32]()
            for j in range(cols):
                row.append(0.0)
            self.data.append(row)

    def __init__(inout self, init_data: List[List[Float32]]):
        self.data = init_data

    def __repr__(self) -> String:
        var out = String("")
        for i in range(len(self.data)):
            for j in range(len(self.data[i])):
                if j > 0:
                    out += " "
                out += str(self.data[i][j])
            out += "\n"
        return out

    def block[R: Int, C: Int](self, row: Int, col: Int) -> MatrixXf:
        var sub = MatrixXf(R, C)
        for i in range(R):
            for j in range(C):
                sub.data[i][j] = self.data[row + i][col + j]
        return sub

    def block(self, row: Int, col: Int, rows: Int, cols: Int) -> MatrixXf:
        var sub = MatrixXf(rows, cols)
        for i in range(rows):
            for j in range(cols):
                sub.data[i][j] = self.data[row + i][col + j]
        return sub

def main():
    var m = MatrixXf(List[List[Float32]](
        [1.0, 2.0, 3.0, 4.0],
        [5.0, 6.0, 7.0, 8.0],
        [9.0, 10.0, 11.0, 12.0],
        [13.0, 14.0, 15.0, 16.0]
    ))

    print("Block in the middle")
    print(m.block[2, 2](1, 1))
    print()

    for i in range(1, 4):
        print("Block of size", i, "x", i)
        print(m.block(0, 0, i, i))
        print()