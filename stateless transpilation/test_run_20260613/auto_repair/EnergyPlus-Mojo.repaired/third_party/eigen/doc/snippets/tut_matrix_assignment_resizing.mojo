from memory import Pointer

struct MatrixXf:
    var rows_: Int
    var cols_: Int
    var data_: Pointer[Float32]

    def __init__(inout self, rows: Int, cols: Int):
        self.rows_ = rows
        self.cols_ = cols
        self.data_ = Pointer[Float32].alloc(rows * cols)

    def __copyinit__(inout self, other: Self):
        self.rows_ = other.rows_
        self.cols_ = other.cols_
        self.data_ = Pointer[Float32].alloc(self.rows_ * self.cols_)
        for i in range(self.rows_ * self.cols_):
            self.data_[i] = other.data_[i]

    def __moveinit__(inout self, owned other: Self):
        self.rows_ = other.rows_
        self.cols_ = other.cols_
        self.data_ = other.data_
        other.data_ = Pointer[Float32]()
        other.rows_ = 0
        other.cols_ = 0

    def __copyassign__(inout self, other: Self):
        if self.data_ == other.data_:
            return
        self.data_.free()
        self.rows_ = other.rows_
        self.cols_ = other.cols_
        self.data_ = Pointer[Float32].alloc(self.rows_ * self.cols_)
        for i in range(self.rows_ * self.cols_):
            self.data_[i] = other.data_[i]

    def __moveassign__(inout self, owned other: Self):
        if self.data_ == other.data_:
            return
        self.data_.free()
        self.rows_ = other.rows_
        self.cols_ = other.cols_
        self.data_ = other.data_
        other.data_ = Pointer[Float32]()
        other.rows_ = 0
        other.cols_ = 0

    def __del__(owned self):
        self.data_.free()

    def rows(self) -> Int:
        return self.rows_

    def cols(self) -> Int:
        return self.cols_

def main():
    var a = MatrixXf(2, 2)
    print("a is of size " + String(a.rows()) + "x" + String(a.cols()))
    var b = MatrixXf(3, 3)
    a = b
    print("a is now of size " + String(a.rows()) + "x" + String(a.cols()))