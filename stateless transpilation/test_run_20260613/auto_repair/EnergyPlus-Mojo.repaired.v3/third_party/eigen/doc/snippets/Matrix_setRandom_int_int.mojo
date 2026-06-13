from random import random

struct MatrixXf:
    var rows: Int
    var cols: Int
    var data: List[List[Float32]]

    def __init__(inout self):
        self.rows = 0
        self.cols = 0
        self.data = List[List[Float32]]()

    def setRandom(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols
        self.data = List[List[Float32]]()
        for i in range(rows):
            var row = List[Float32]()
            for j in range(cols):
                row.append((random() * 2.0) - 1.0)
            self.data.append(row)

    def __str__(self) -> String:
        var s = ""
        for i in range(self.rows):
            for j in range(self.cols):
                s += str(self.data[i][j]) + " "
            s += "\n"
        return s

var m = MatrixXf()
m.setRandom(3, 3)
print(m)