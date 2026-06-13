from internal import (
    handmade_aligned_malloc,
    handmade_aligned_free,
    aligned_malloc,
    aligned_free,
    aligned_new,
    aligned_delete,
    UIntPtr,
    random,
    ei_declare_aligned_stack_constructed_variable,
)
from Eigen import Matrix, Vector4f, Vector2f, Matrix4f, MatrixXi, Vector2d, Vector4d, Vector4i

alias EIGEN_MAX_ALIGN_BYTES: Int = 16
alias EIGEN_MAX_STATIC_ALIGN_BYTES: Int = 16

alias ALIGNMENT: Int = EIGEN_MAX_ALIGN_BYTES if EIGEN_MAX_ALIGN_BYTES > 0 else 1

alias Vector8f = Matrix[Float32, 8, 1]

var g_repeat: Int = 100

def CALL_SUBTEST(f: def () -> None):
    f()

def VERIFY(condition: Bool):
    ()(condition)  # assertion

def check_handmade_aligned_malloc():
    for i in range(1, 1000):
        var p_ = handmade_aligned_malloc(i)
        var p = (p_ as BytePointer)
        VERIFY(UIntPtr(p) % ALIGNMENT == 0)
        for j in range(i):
            p.store(j, 0)
        handmade_aligned_free(p)

def check_aligned_malloc():
    for i in range(ALIGNMENT, 1000):
        var p_ = aligned_malloc(i)
        var p = (p_ as BytePointer)
        VERIFY(UIntPtr(p) % ALIGNMENT == 0)
        for j in range(i):
            p.store(j, 0)
        aligned_free(p)

def check_aligned_new():
    for i in range(ALIGNMENT, 1000):
        var p = aligned_new[Float32](i)
        VERIFY(UIntPtr(p) % ALIGNMENT == 0)
        for j in range(i):
            p.store(j, 0.0)
        aligned_delete(p, i)

def check_aligned_stack_alloc():
    for i in range(ALIGNMENT, 400):
        var p = ei_declare_aligned_stack_constructed_variable[Float32](i, 0)
        VERIFY(UIntPtr(p) % ALIGNMENT == 0)
        for j in range(i):
            p.store(j, 0.0)

struct MyStruct:
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW()
    var dummychar: Int8 = 0
    var avec: Vector8f = Vector8f()

class MyClassA:
    EIGEN_MAKE_ALIGNED_OPERATOR_NEW()
    var dummychar: Int8 = 0
    var avec: Vector8f = Vector8f()

    def __init__(inout self):

def check_dynaligned[T: AnyType]():
    if T.SizeAtCompileTime % ALIGNMENT == 0:
        var obj = new T
        VERIFY(T.NeedsToAlign == 1)
        VERIFY(UIntPtr(obj) % ALIGNMENT == 0)
        delete obj

def check_custom_new_delete[T: AnyType]():
    # block 1
    var t = new T
    delete t
    # block 2
    var N = random[UInt64](1, 10)
    var t_arr = new T[N]
    delete[] t_arr
    # conditional block
    if EIGEN_MAX_ALIGN_BYTES > 0:
        var t1 = (T.operator_new)(sizeof[T]) as T
        (T.operator_delete)(t1, sizeof[T])
        var t2 = (T.operator_new)(sizeof[T]) as T
        (T.operator_delete)(t2)

def test_dynalloc():
    CALL_SUBTEST(check_handmade_aligned_malloc)
    CALL_SUBTEST(check_aligned_malloc)
    CALL_SUBTEST(check_aligned_new)
    CALL_SUBTEST(check_aligned_stack_alloc)
    for i in range(g_repeat * 100):
        CALL_SUBTEST(lambda: check_custom_new_delete[Vector4f]())
        CALL_SUBTEST(lambda: check_custom_new_delete[Vector2f]())
        CALL_SUBTEST(lambda: check_custom_new_delete[Matrix4f]())
        CALL_SUBTEST(lambda: check_custom_new_delete[MatrixXi]())
    if EIGEN_MAX_STATIC_ALIGN_BYTES:
        for i in range(g_repeat * 100):
            CALL_SUBTEST(lambda: check_dynaligned[Vector4f]())
            CALL_SUBTEST(lambda: check_dynaligned[Vector2d]())
            CALL_SUBTEST(lambda: check_dynaligned[Matrix4f]())
            CALL_SUBTEST(lambda: check_dynaligned[Vector4d]())
            CALL_SUBTEST(lambda: check_dynaligned[Vector4i]())
            CALL_SUBTEST(lambda: check_dynaligned[Vector8f]())
        # struct/class static checks
        var foo0 = MyStruct()
        VERIFY(UIntPtr(foo0.avec.data()) % ALIGNMENT == 0)
        var fooA = MyClassA()
        VERIFY(UIntPtr(fooA.avec.data()) % ALIGNMENT == 0)
        # heap allocated
        for i in range(g_repeat * 100):
            var foo0h = new MyStruct
            VERIFY(UIntPtr(foo0h.avec.data()) % ALIGNMENT == 0)
            var fooAh = new MyClassA
            VERIFY(UIntPtr(fooAh.avec.data()) % ALIGNMENT == 0)
            delete foo0h
            delete fooAh
        const N: Int = 10
        for i in range(g_repeat * 100):
            var foo0arr = new MyStruct[N]
            VERIFY(UIntPtr(foo0arr.avec.data()) % ALIGNMENT == 0)
            var fooAarr = new MyClassA[N]
            VERIFY(UIntPtr(fooAarr.avec.data()) % ALIGNMENT == 0)
            delete[] foo0arr
            delete[] fooAarr