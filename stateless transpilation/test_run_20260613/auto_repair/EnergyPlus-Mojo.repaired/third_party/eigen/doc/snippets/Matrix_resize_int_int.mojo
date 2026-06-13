struct MatrixXd:
    var data: List[Float64]
    var rows: Int
    var cols: Int

    def __init__(inout self, r: Int, c: Int):
        self.rows = r
        self.cols = c
        self.data = List[Float64](r * c, 0.0)

    def __lshift__(inout self, values: List[Float64]):
        # Comma initializer fills in column-major order (as Eigen does)
        for i in range(len(values)):
            self.data[i] = values[i]

    def __str__(self) -> String:
        var s = String()
        for i in range(self.rows):
            for j in range(self.cols):
                s += str(self.data[j * self.rows + i]) + " "
            s += "\n"
        return s

    def resize(inout self, new_rows: Int, new_cols: Int):
        # Conservative resize: preserve elements in column-major order
        var old_data = self.data
        var old_rows = self.rows
        var old_cols = self.cols
        var old_size = old_rows * old_cols
        var new_size = new_rows * new_cols
        self.rows = new_rows
        self.cols = new_cols
        self.data = List[Float64](new_size, 0.0)
        if new_size <= old_size:
            for i in range(new_size):
                self.data[i] = old_data[i]
        # If new_size > old_size, the extra elements are uninitialized (left as zero here)

var m = MatrixXd(2,3)
m << [1,2,3,4,5,6]
print("here's the 2x3 matrix m:")
print(m)
print("let's resize m to 3x2. This is a conservative resizing because 2*3==3*2.")
m.resize(3,2)
print("here's the 3x2 matrix m:")
print(m)
print("now let's resize m to size 2x2. This is NOT a conservative resizing, so it becomes uninitialized:")
m.resize(2,2)
print(m)