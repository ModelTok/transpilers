struct DiagonalVector:
    var data: List[Int32]

    def __init__(inout self, data: List[Int32]):
        self.data = data

    def transpose(self) -> DiagonalVector:
        return self

struct Matrix4i:
    var data: List[List[Int32]]

    def __init__(inout self):
        self.data = List[List[Int32]](4)
        for i in range(4):
            self.data[i] = List[Int32](4)

    def Random() -> Matrix4i:
        var m = Matrix4i()
        # Fill with arbitrary values (mimicking Eigen's Random)
        m.data[0][0] =  1; m.data[0][1] =  2; m.data[0][2] =  3; m.data[0][3] =  4
        m.data[1][0] =  5; m.data[1][1] =  6; m.data[1][2] =  7; m.data[1][3] =  8
        m.data[2][0] =  9; m.data[2][1] = 10; m.data[2][2] = 11; m.data[2][3] = 12
        m.data[3][0] = 13; m.data[3][1] = 14; m.data[3][2] = 15; m.data[3][3] = 16
        return m

    def diagonal(self, k: Int) -> DiagonalVector:
        var diag = List[Int32]()
        if k >= 0:
            for i in range(4 - k):
                diag.append(self.data[i][i + k])
        else:
            for i in range(4 + k):
                diag.append(self.data[i - k][i])
        return DiagonalVector(diag)

var m = Matrix4i.Random()
print("Here is the matrix m:")
for i in range(4):
    var line = ""
    for j in range(4):
        line += str(m.data[i][j]) + " "
    print(line)
print("Here are the coefficients on the 1st super-diagonal and 2nd sub-diagonal of m:")
var d1 = m.diagonal(1).transpose()
var d2 = m.diagonal(-2).transpose()
for vec in [d1, d2]:
    var line = ""
    for val in vec.data:
        line += str(val) + " "
    print(line)