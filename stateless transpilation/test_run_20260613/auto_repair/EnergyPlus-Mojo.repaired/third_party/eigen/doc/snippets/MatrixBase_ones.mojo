struct Matrix2d:
    var data: ((Float64, Float64), (Float64, Float64))

    @staticmethod
    def Ones() -> Matrix2d:
        return Matrix2d{data = ((1.0, 1.0), (1.0, 1.0))}

    def __repr__(self) -> String:
        var s = String("")
        for i in range(2):
            if i > 0:
                s += "\n"
            s += str(self.data[i][0]) + " " + str(self.data[i][1])
        return s

struct RowVector4i:
    var data: (Int, Int, Int, Int)

    @staticmethod
    def Ones() -> RowVector4i:
        return RowVector4i{data = (1, 1, 1, 1)}

    def __rmul__(self, scalar: Int) -> RowVector4i:
        return RowVector4i{
            data = (self.data[0]*scalar, self.data[1]*scalar, self.data[2]*scalar, self.data[3]*scalar)
        }

    def __repr__(self) -> String:
        var s = String("")
        for i in range(4):
            if i > 0:
                s += " "
            s += str(self.data[i])
        return s

print(Matrix2d.Ones())
print(6 * RowVector4i.Ones())