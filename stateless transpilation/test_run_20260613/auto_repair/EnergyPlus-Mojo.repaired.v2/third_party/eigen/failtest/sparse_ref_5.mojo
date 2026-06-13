// #include "../Eigen/Sparse"
// using namespace Eigen;

// Minimal stubs for Eigen-like types to reproduce the fail test behavior
struct SparseMatrix[type: AnyRegType]:
    var rows: Int
    var cols: Int
    def __init__(inout self, rows: Int, cols: Int):
        self.rows = rows
        self.cols = cols

struct SparseMatrixBase[T: AnyRegType]:
    var ptr: UnsafePointer[T]
    def __init__(inout self, inout obj: T):
        self.ptr = UnsafePointer[T].address_of(obj)
    def derived(inout self) -> ref[T]:
        return self.ptr[]

struct Ref[T: AnyRegType]:
    var ptr: UnsafePointer[T]
    def __init__(inout self, inout obj: T):
        self.ptr = UnsafePointer[T].address_of(obj)

def call_ref(a: Ref[SparseMatrix[Float32]]):

#  ifdef EIGEN_SHOULD_FAIL_TO_BUILD
alias EIGEN_SHOULD_FAIL_TO_BUILD = False
#  else
#  endif

def main():
    var a = SparseMatrix[Float32](10, 10)
    var ac = SparseMatrixBase[SparseMatrix[Float32]](a)
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        #  call_ref(ac)
        call_ref(ac)
    else:
        #  call_ref(ac.derived())
        call_ref(ac.derived())