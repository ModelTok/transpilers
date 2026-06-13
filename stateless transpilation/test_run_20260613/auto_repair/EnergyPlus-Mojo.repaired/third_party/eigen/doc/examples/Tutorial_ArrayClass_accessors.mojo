struct ArrayXXf:
    var data: List[List[Float64]]

    def __init__(inout self, rows: Int, cols: Int):
        self.data = List[List[Float64]]()
        for r in range(rows):
            var row = List[Float64]()
            for c in range(cols):
                row.append(0.0)
            self.data.append(row)

    def __getitem__(self, i: Int, j: Int) -> Float64:
        return self.data[i][j]

    def __setitem__(inout self, i: Int, j: Int, val: Float64):
        self.data[i][j] = val

    def __lshift__(inout self, values: List[Float64]) -> Self:
        var idx: Int = 0
        for r in range(len(self.data)):
            for c in range(len(self.data[0])):
                self.data[r][c] = values[idx]
                idx += 1
        return self

    def __str__(self) -> String:
        var result = String()
        for r in range(len(self.data)):
            for c in range(len(self.data[0])):
                if c > 0:
                    result += " "
                result += str(self.data[r][c])
            result += "\n"
        return result

def main():
    var m = ArrayXXf(2, 2)
    m[0, 0] = 1.0; m[0, 1] = 2.0
    m[1, 0] = 3.0; m[1, 1] = m[0, 1] + m[1, 0]
    print(m, end="")
    print()
    m << [1.0, 2.0, 3.0, 4.0]
    print(m, end="")