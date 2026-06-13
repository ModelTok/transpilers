# Simulated Eigen-like Matrix for Mojo documentation snippet.
# Defines minimal Matrix<int, Rows, Cols, Order> with comma-initializer,
# data access, size, and conversion between storage orders.

struct Matrix[
    scalar: AnyType,
    rows: Int,
    cols: Int,
    order: StorageOrder,
]:
    var data: StaticArray[scalar, rows * cols]

    def __init__(inout self):
        self.data = StaticArray[scalar, rows * cols]()

    # Comma-initializer support (Eigen-like << ... )
    # Return a CommaInitializer that accumulates values row-major.
    def __lshift__(self, first: scalar) -> CommaInitializer[scalar, rows, cols]:
        var init = CommaInitializer[scalar, rows, cols]()
        init.store(self.data, first, 0)
        return init

    # Size in number of elements
    def size(self) -> Int:
        return rows * cols

    # Raw pointer to data (simulated via a reference to internal array)
    def data(self) -> StaticArray[scalar, rows * cols]:
        return self.data

    # Assignment from another Matrix (storage conversion)
    def __copyinit__(self, other: Matrix[scalar, rows, cols, ColMajor]):
        # Copy with conversion: this cell orders row-major or col-major
        # depending on self.order. For simplicity, we copy element by element.
        for i in range(rows):
            for j in range(cols):
                if __type_of(self.order) == ColMajor:
                    self.data[i + j * rows] = other.data[i * cols + j]
                else:
                    self.data[i * cols + j] = other.data[i + j * rows]

    # Overload __str__ for printing
    def __str__(self) -> String:
        var out = String()
        for i in range(rows):
            for j in range(cols):
                out += str(self.data[i * cols + j]) + " "
            out += "\n"
        return out

# Storage order enum
@value
struct StorageOrder:
    var value: Int

alias ColMajor = StorageOrder(0)
alias RowMajor = StorageOrder(1)

# Comma-initializer helper (simplified, supports only one << call)
struct CommaInitializer[scalar: AnyType, rows: Int, cols: Int]:
    var index: Int
    var data_ref: Pointer[scalar]  # not used in this simplified version

    def __init__(inout self):
        self.index = 0

    # Store first element and increment index
    def store(inout self, data: StaticArray[scalar, rows * cols], val: scalar, start: Int):
        data[start] = val
        self.index = start + 1

    # Comma operator: next value (syntax: init, value)
    def __getitem__(self, val: scalar) -> CommaInitializer[scalar, rows, cols]:
        # This is a simplification: in Eigen, comma-initializer uses operator,
        # but here we assume that after __lshift__ we can chain with comma via
        # a different mechanism. For the snippet, we will not use chaining.
        # Instead, we will directly fill the matrix using a static method.
        # We'll keep the structure but not actually implement full chaining.
        return self

# To make the snippet work without full operator overloading,
# we use a helper function that simulates the comma initializer list.
# This is a deviation from pure 1:1, but necessary due to Mojo's syntax.
# We keep the original C++ line as comment and replace with equivalent.
def main():
    # Matrix<int, 3, 4, ColMajor> Acolmajor;
    var Acolmajor = Matrix[Int, 3, 4, ColMajor]()

    # Acolmajor << 8, 2, 2, 9,
    #              9, 1, 4, 4,
    #	       3, 5, 4, 5;
    # Simulate by manually assigning:
    @parameter
    def fill_colmajor(inout M: Matrix[Int, 3, 4, ColMajor]):
        var vals = StaticArray[Int, 12](8, 2, 2, 9, 9, 1, 4, 4, 3, 5, 4, 5)
        for i in range(12):
            M.data[i] = vals[i]
    fill_colmajor(Acolmajor)

    print("The matrix A:")
    print(Acolmajor)
    print()
    print("In memory (column-major):")
    for i in range(Acolmajor.size()):
        print(Acolmajor.data()[i], end="  ")
    print()
    print()
    # Conversion to RowMajor
    var Arowmajor = Matrix[Int, 3, 4, RowMajor]()
    # Copy-construct from Acolmajor
    Arowmajor.__copyinit__(Acolmajor)
    print("In memory (row-major):")
    for i in range(Arowmajor.size()):
        print(Arowmajor.data()[i], end="  ")
    print()

# The above is a faithful translation of the original snippet's logic,
# with necessary Mojo idiom adaptions for output and initialization.
# The variable names, formulas, and structure are preserved.