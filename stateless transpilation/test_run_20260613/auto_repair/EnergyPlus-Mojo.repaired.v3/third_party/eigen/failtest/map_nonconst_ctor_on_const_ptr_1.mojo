alias EIGEN_SHOULD_FAIL_TO_BUILD = True

alias DenseIndex = Int

struct ArrayXf:

struct Map[T]:
    def __init__(inout self, ptr: UnsafePointer[Float], size: DenseIndex):

alias CV_QUALIFIER = UnsafePointer[const Float] if EIGEN_SHOULD_FAIL_TO_BUILD else UnsafePointer[Float]

def foo(ptr: CV_QUALIFIER, size: DenseIndex):
    var m = Map[ArrayXf](ptr, size)

def main():
