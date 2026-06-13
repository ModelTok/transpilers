from math import sqrt

def VERIFY(condition: Bool):
    assert(condition)

struct internal:
    struct true_type:
        @value
        static var value: Bool = True

    struct false_type:
        @value
        static var value: Bool = False

    struct conditional[cond: Bool, T: AnyType, F: AnyType]:
        @value
        static var type: AnyType = T if cond else F

    struct is_same[T: AnyType, U: AnyType]:
        @value
        static var value: Bool = T == U

    struct remove_all[T: AnyType]:
        @value
        static var type: AnyType = T

    struct add_const[T: AnyType]:
        @value
        static var type: AnyType = Const[T]

    struct remove_const[T: AnyType]:
        @value
        static var type: AnyType = T

    struct add_const_on_value_type[T: AnyType]:
        @value
        static var type: AnyType = T

    struct remove_reference[T: AnyType]:
        @value
        static var type: AnyType = T

    struct remove_pointer[T: AnyType]:
        @value
        static var type: AnyType = T

    struct is_convertible[From: AnyType, To: AnyType]:
        @value
        static var value: Bool = True

    struct meta_sqrt[N: Int]:
        @value
        static var ret: Int = _meta_sqrt_impl[N]()

@parameter
def _meta_sqrt_impl[N: Int]() -> Int:
    if N <= 0:
        return 0
    var x: Int = N
    var y: Int = (x + 1) // 2
    while y < x:
        x = y
        y = (x + N // x) // 2
    return x

struct Matrix3f:

struct Array33f:

struct MatrixXf:

struct VectorXf:

def check_is_convertible[From: AnyType, To: AnyType](from: borrowed From, to: borrowed To) -> Bool:
    return internal.is_convertible[From, To].value

def test_meta():
    VERIFY((internal.conditional[(3<4), internal.true_type, internal.false_type].type.value))
    VERIFY(( internal.is_same[Float32, Float32].value))
    VERIFY((!internal.is_same[Float32, Float64].value))
    VERIFY((!internal.is_same[Float32, Reference[Float32]].value))
    VERIFY((!internal.is_same[Float32, Const[Reference[Float32]]].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Const[Reference[Float32]]].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Const[Pointer[Float32]]].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Const[Pointer[Float32]]&].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Pointer[Pointer[Float32]]].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Pointer[Pointer[Float32]]&].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Pointer[Const[Pointer[Float32]]]&].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_all[Pointer[Const[Float32]]].type].value))
    VERIFY(( internal.is_same[ internal.add_const[Float32].type, Const[Float32] ].value))
    VERIFY(( internal.is_same[ internal.add_const[Pointer[Float32]].type, Const[Pointer[Float32]] ].value))
    VERIFY(( internal.is_same[ internal.add_const[Pointer[Const[Float32]]].type, Const[Pointer[Const[Float32]]] ].value))
    VERIFY(( internal.is_same[ internal.add_const[Reference[Float32]].type, Reference[Float32] ].value))
    VERIFY(( internal.is_same[ internal.remove_const[Const[Pointer[Const[Float32]]]].type, Pointer[Const[Float32]] ].value))
    VERIFY(( internal.is_same[ internal.remove_const[Pointer[Const[Float32]]].type, Pointer[Const[Float32]] ].value))
    VERIFY(( internal.is_same[ internal.remove_const[Pointer[Const[Float32]]].type, Pointer[Float32] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Reference[Float32]].type, Const[Reference[Float32]] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Pointer[Float32]].type, Pointer[Const[Float32]] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Float32].type, Const[Float32] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Const[Float32]].type, Const[Float32] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Const[Pointer[Const[Float32]]]].type, Const[Pointer[Const[Float32]]] ].value))
    VERIFY(( internal.is_same[ internal.add_const_on_value_type[Pointer[Const[Float32]]].type, Const[Pointer[Const[Float32]]] ].value))
    VERIFY(( internal.is_same[Float32, internal.remove_reference[Reference[Float32]].type].value))
    VERIFY(( internal.is_same[Const[Float32], internal.remove_reference[Const[Reference[Float32]]].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_pointer[Pointer[Float32]].type].value))
    VERIFY(( internal.is_same[Const[Float32], internal.remove_pointer[Pointer[Const[Float32]]].type].value))
    VERIFY(( internal.is_same[Float32, internal.remove_pointer[Const[Pointer[Float32]]].type].value))
    VERIFY(( internal.is_convertible[Float32, Float64].value ))
    VERIFY(( internal.is_convertible[Int, Float64].value ))
    VERIFY(( internal.is_convertible[Float64, Int].value ))
    VERIFY((!internal.is_convertible[Complex[Float64], Float64].value ))
    VERIFY(( internal.is_convertible[Array33f, Matrix3f].value ))
    VERIFY((!internal.is_convertible[Array33f, Int].value ))
    VERIFY((!internal.is_convertible[MatrixXf, Float32].value ))
    {
        var f: Float32
        var A: MatrixXf
        var B: MatrixXf
        var a: VectorXf
        var b: VectorXf
        VERIFY(( check_is_convertible(a.dot(b), f) ))
        VERIFY(( check_is_convertible(a.transpose()*b, f) ))
        VERIFY((!check_is_convertible(A*B, f) ))
        VERIFY(( check_is_convertible(A*B, A) ))
    }
    VERIFY(internal.meta_sqrt[1].ret == 1)
    #define VERIFY_META_SQRT(X) VERIFY(internal.meta_sqrt<X>::ret == int(sqrt(double(X))))
    def VERIFY_META_SQRT(X: Int):
        VERIFY(internal.meta_sqrt[X].ret == Int(sqrt(Float64(X))))
    VERIFY_META_SQRT(2)
    VERIFY_META_SQRT(3)
    VERIFY_META_SQRT(4)
    VERIFY_META_SQRT(5)
    VERIFY_META_SQRT(6)
    VERIFY_META_SQRT(8)
    VERIFY_META_SQRT(9)
    VERIFY_META_SQRT(15)
    VERIFY_META_SQRT(16)
    VERIFY_META_SQRT(17)
    VERIFY_META_SQRT(255)
    VERIFY_META_SQRT(256)
    VERIFY_META_SQRT(257)
    VERIFY_META_SQRT(1023)
    VERIFY_META_SQRT(1024)
    VERIFY_META_SQRT(1025)