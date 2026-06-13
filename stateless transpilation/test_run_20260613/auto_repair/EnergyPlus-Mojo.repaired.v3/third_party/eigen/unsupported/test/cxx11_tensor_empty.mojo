# Minimal Eigen-like tensor types for Mojo test translation

struct Sizes[N: Int]:
    var size: Int = N

struct Tensor[Scalar, Rank: Int]:
    var data: List[List[Scalar]]

    def __init__(inout self):
        self.data = List[List[Scalar]]()

    def __init__(inout self, other: Self):
        self.data = other.data.copy()

    def __copyinit__(inout self, other: Self):
        self.data = other.data.copy()

    def __moveinit__(inout self, owned other: Self):
        self.data = other.data^

    def __del__(owned self):

    def operator=(inout self, other: Self) -> Self:
        self.data = other.data.copy()
        return self

struct TensorFixedSize[Scalar, Dims: AnyType]:
    var data: List[Scalar]

    def __init__(inout self):
        self.data = List[Scalar]()

    def __init__(inout self, other: Self):
        self.data = other.data.copy()

    def __copyinit__(inout self, other: Self):
        self.data = other.data.copy()

    def __moveinit__(inout self, owned other: Self):
        self.data = other.data^

    def __del__(owned self):

    def operator=(inout self, other: Self) -> Self:
        self.data = other.data.copy()
        return self

alias Sizes0 = Sizes[0]

def test_empty_tensor():
    var source: Tensor[Float32, 2] = Tensor[Float32, 2]()
    var tgt1: Tensor[Float32, 2] = source
    var tgt2: Tensor[Float32, 2] = Tensor[Float32, 2](source)
    var tgt3: Tensor[Float32, 2] = Tensor[Float32, 2]()
    tgt3 = tgt1
    tgt3 = tgt2

def test_empty_fixed_size_tensor():
    var source: TensorFixedSize[Float32, Sizes0] = TensorFixedSize[Float32, Sizes0]()
    var tgt1: TensorFixedSize[Float32, Sizes0] = source
    var tgt2: TensorFixedSize[Float32, Sizes0] = TensorFixedSize[Float32, Sizes0](source)
    var tgt3: TensorFixedSize[Float32, Sizes0] = TensorFixedSize[Float32, Sizes0]()
    tgt3 = tgt1
    tgt3 = tgt2

def test_cxx11_tensor_empty():
    test_empty_tensor()
    test_empty_fixed_size_tensor()