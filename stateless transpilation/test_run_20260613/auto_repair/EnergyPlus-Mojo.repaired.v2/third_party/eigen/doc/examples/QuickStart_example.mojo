struct MatrixXd:
    var data: List[List[Float64]]
    var rows: Int
    var cols: Int

    def __init__(inout self, r: Int, c: Int):
        self.rows = r
        self.cols = c
        self.data = List[List[Float64]]()
        for i in range(r):
            var row = List[Float64]()
            for j in range(c):
                row.append(0.0)
            self.data.append(row)

    def __getitem__(self, key: Tuple[Int, Int]) -> Float64:
        return self.data[key.get[0, Int]()][key.get[1, Int]()]

    def __setitem__(inout self, key: Tuple[Int, Int], value: Float64):
        self.data[key.get[0, Int]()][key.get[1, Int]()] = value

    def __str__(self) -> String:
        var s = String()
        for i in range(self.rows):
            for j in range(self.cols):
                if j > 0:
                    s += " "
                s += str(self.data[i][j])
            if i < self.rows - 1:
                s += "\n"
        return s

def main():
    var m = MatrixXd(2, 2)
    m[0,0] = 3.0
    m[1,0] = 2.5
    m[0,1] = -1.0
    m[1,1] = m[1,0] + m[0,1]
    print(m)