from main import *
from memory import Pointer
from sys import Exception

struct Foo:
    var object_count: Index = 0
    var object_limit: Index = 0
    var dummy: Int

    def __init__(inout self):
        #if EIGEN_EXCEPTIONS
        if Foo.object_count > Foo.object_limit:
            print("\nThrow!\n")
            raise Foo.Fail()
        #endif
        print('+')
        Foo.object_count += 1

    def __del__(owned self):
        print('-')
        Foo.object_count -= 1

    struct Fail(Exception):

# Static members initialized outside struct
var Foo_object_count: Index = 0
var Foo_object_limit: Index = 0

#undef EIGEN_TEST_MAX_SIZE
#def EIGEN_TEST_MAX_SIZE 3

def test_ctorleak():
    alias MatrixX = Matrix[Foo, Dynamic, Dynamic]
    alias VectorX = Matrix[Foo, Dynamic, 1]
    Foo.object_count = 0
    for i in range(g_repeat):
        var rows: Index = internal.random[Index](2, 3)
        var cols: Index = internal.random[Index](2, 3)
        Foo.object_limit = internal.random[Index](0, rows*cols - 2)
        print("object_limit =", Foo.object_limit)
        #if EIGEN_EXCEPTIONS
        try:
        #endif
            print("\nMatrixX m(", rows, ", ", cols, ");\n")
            var m = MatrixX(rows, cols)
        #if EIGEN_EXCEPTIONS
            VERIFY(False)  // not reached if exceptions are enabled
        except Foo.Fail:
            pass  # ignore
        #endif
        VERIFY_IS_EQUAL(Index(0), Foo.object_count)
        #{
            Foo.object_limit = (rows+1)*(cols+1)
            var A = MatrixX(rows, cols)
            VERIFY_IS_EQUAL(Foo.object_count, rows*cols)
            var v = A.row(0)
            VERIFY_IS_EQUAL(Foo.object_count, (rows+1)*cols)
            v = A.col(0)
            VERIFY_IS_EQUAL(Foo.object_count, rows*(cols+1))
        #}
        VERIFY_IS_EQUAL(Index(0), Foo.object_count)