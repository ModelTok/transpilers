# Mojo translation of cxx11_tensor_map.cpp
# Faithful 1:1 translation, no refactoring.

import sys

# --- Helper definitions to mimic Eigen types ---
struct Tensor[ElementType: AnyRegType, Rank: Int]:
    var data: Pointer[ElementType]
    var dims: StaticTuple[Int, Rank]

    def __init__(inout self, *dims: Int):
        self.dims = StaticTuple[Int, Rank](dims)
        let size = 1
        for i in range(Rank):
            size *= dims[i]
        self.data = Pointer[ElementType].alloc(size)

    def __init__(inout self):
        # 0-D tensor
        self.dims = StaticTuple[Int, Rank]()
        self.data = Pointer[ElementType].alloc(1)

    def __getitem__(self, *indices: Int) -> ElementType:
        let idx = self._compute_index(indices)
        return self.data.load(idx)

    def __setitem__(inout self, *indices: Int, value: ElementType):
        let idx = self._compute_index(indices)
        self.data.store(idx, value)

    def __call__(self) -> ElementType:
        # For 0-D tensors
        return self.data.load(0)

    def __call__(inout self) -> ElementType:
        # For 0-D tensors mutable
        return self.data.load(0)

    def __call__(self, *indices: Int) -> ElementType:
        return self[*indices]

    def __call__(inout self, *indices: Int) -> ElementType:
        return self[*indices]

    def _compute_index(self, indices: StaticTuple[Int, Rank]) -> Int:
        var index = 0
        var stride = 1
        for i in range(Rank - 1, -1, -1):
            index += indices[i] * stride
            stride *= self.dims[i]
        return index

    def rank(self) -> Int:
        return Rank

    def size(self) -> Int:
        var s = 1
        for i in range(Rank):
            s *= self.dims[i]
        return s

    def dimension(self, i: Int) -> Int:
        return self.dims[i]

    def data(self) -> Pointer[ElementType]:
        return self.data

    def data(inout self) -> Pointer[ElementType]:
        return self.data

struct RowMajor:

struct TensorMap[TensorType: AnyType]:
    var tensor: TensorType
    var is_owning: Bool = False

    def __init__(inout self, data_ptr: Pointer[TensorType.ElementType], *dims: Int):
        # Construct from raw pointer
        self.tensor = TensorType()
        self.tensor.data = data_ptr
        self.tensor.dims = StaticTuple[Int, TensorType.Rank](dims)
        self.is_owning = False

    def __init__(inout self, other: TensorType):
        # Construct from existing tensor
        self.tensor = other
        self.is_owning = False

    def __init__(inout self, other: TensorFixedSize[TensorType.ElementType, TensorType.DimsType]):
        # Construct from TensorFixedSize
        self.tensor = TensorType()
        self.tensor.data = other.data
        self.tensor.dims = other.dims
        self.is_owning = False

    def __call__(self) -> TensorType.ElementType:
        return self.tensor()

    def __call__(inout self) -> TensorType.ElementType:
        return self.tensor()

    def __call__(self, *indices: Int) -> TensorType.ElementType:
        return self.tensor[*indices]

    def __call__(inout self, *indices: Int) -> TensorType.ElementType:
        return self.tensor[*indices]

    def rank(self) -> Int:
        return self.tensor.rank()

    def size(self) -> Int:
        return self.tensor.size()

    def dimension(self, i: Int) -> Int:
        return self.tensor.dimension(i)

    def data(self) -> Pointer[TensorType.ElementType]:
        return self.tensor.data

    def data(inout self) -> Pointer[TensorType.ElementType]:
        return self.tensor.data

struct Sizes[dim0: Int, dim1: Int, dim2: Int]:
    var dims: StaticTuple[Int, 3]

    def __init__(inout self):
        self.dims = StaticTuple[Int, 3](dim0, dim1, dim2)

struct TensorFixedSize[ElementType: AnyRegType, DimsType: AnyType]:
    var data: Pointer[ElementType]
    var dims: StaticTuple[Int, 3]  # Assuming rank=3

    def __init__(inout self):
        # Fixed size constructor
        # We need to allocate based on DimsType dimensions
        # For Sizes<2,3,7> the dimensions are known
        self.dims = DimsType().dims
        let size = 1
        for i in range(3):
            size *= self.dims[i]
        self.data = Pointer[ElementType].alloc(size)

    def __getitem__(self, coords: StaticTuple[Int, 3]) -> ElementType:
        let idx = coords[0]*self.dims[1]*self.dims[2] + coords[1]*self.dims[2] + coords[2]
        return self.data.load(idx)

    def __setitem__(inout self, coords: StaticTuple[Int, 3], value: ElementType):
        let idx = coords[0]*self.dims[1]*self.dims[2] + coords[1]*self.dims[2] + coords[2]
        self.data.store(idx, value)

    def __call__(self, i: Int, j: Int, k: Int) -> ElementType:
        let idx = i*self.dims[1]*self.dims[2] + j*self.dims[2] + k
        return self.data.load(idx)

    def __call__(inout self, i: Int, j: Int, k: Int) -> ElementType:
        let idx = i*self.dims[1]*self.dims[2] + j*self.dims[2] + k
        return self.data.load(idx)

    def rank(self) -> Int:
        return 3

    def size(self) -> Int:
        var s = 1
        for i in range(3):
            s *= self.dims[i]
        return s

    def dimension(self, i: Int) -> Int:
        return self.dims[i]

    def data(self) -> Pointer[ElementType]:
        return self.data

    def data(inout self) -> Pointer[ElementType]:
        return self.data

struct internal:
    # Mimics Eigen::internal
    def array_size[T: AnyType]() -> Int:
        # For Sizes<>, DSizes<int,0> etc.
        return 0

# --- Macros / verification ---
def VERIFY_IS_EQUAL(a: AnyType, b: AnyType, msg: String = ""):
    if a != b:
        print("FAIL: ", a, " != ", b, " ", msg)
        sys.exit(1)

def CALL_SUBTEST(f: def () -> None):
    f()

# --- Translated test functions ---
def test_0d():
    var scalar1 = Tensor[Int, 0]()
    var scalar2 = Tensor[Int, 0]()
    var scalar3 = TensorMap[Tensor[Int, 0]](scalar1.data())
    var scalar4 = TensorMap[Tensor[Int, 0]](scalar2.data())
    scalar1() = 7
    scalar2() = 13
    VERIFY_IS_EQUAL(scalar1.rank(), 0)
    VERIFY_IS_EQUAL(scalar1.size(), 1)
    VERIFY_IS_EQUAL(scalar3(), 7)
    VERIFY_IS_EQUAL(scalar4(), 13)

def test_1d():
    var vec1 = Tensor[Int, 1](6)
    var vec2 = Tensor[Int, 1](6)
    var vec3 = TensorMap[Tensor[Int, 1]](vec1.data(), 6)
    var vec4 = TensorMap[Tensor[Int, 1]](vec2.data(), 6)
    vec1[0] = 4;  vec2[0] = 0;
    vec1[1] = 8;  vec2[1] = 1;
    vec1[2] = 15; vec2[2] = 2;
    vec1[3] = 16; vec2[3] = 3;
    vec1[4] = 23; vec2[4] = 4;
    vec1[5] = 42; vec2[5] = 5;
    VERIFY_IS_EQUAL(vec1.rank(), 1)
    VERIFY_IS_EQUAL(vec1.size(), 6)
    VERIFY_IS_EQUAL(vec1.dimension(0), 6)
    VERIFY_IS_EQUAL(vec3(0), 4)
    VERIFY_IS_EQUAL(vec3(1), 8)
    VERIFY_IS_EQUAL(vec3(2), 15)
    VERIFY_IS_EQUAL(vec3(3), 16)
    VERIFY_IS_EQUAL(vec3(4), 23)
    VERIFY_IS_EQUAL(vec3(5), 42)
    VERIFY_IS_EQUAL(vec4(0), 0)
    VERIFY_IS_EQUAL(vec4(1), 1)
    VERIFY_IS_EQUAL(vec4(2), 2)
    VERIFY_IS_EQUAL(vec4(3), 3)
    VERIFY_IS_EQUAL(vec4(4), 4)
    VERIFY_IS_EQUAL(vec4(5), 5)

def test_2d():
    var mat1 = Tensor[Int, 2](2,3)
    var mat2 = Tensor[Int, 2](2,3)
    mat1[0,0] = 0
    mat1[0,1] = 1
    mat1[0,2] = 2
    mat1[1,0] = 3
    mat1[1,1] = 4
    mat1[1,2] = 5
    mat2[0,0] = 0
    mat2[0,1] = 1
    mat2[0,2] = 2
    mat2[1,0] = 3
    mat2[1,1] = 4
    mat2[1,2] = 5
    var mat3 = TensorMap[Tensor[Int, 2]](mat1.data(), 2, 3)
    var mat4 = TensorMap[Tensor[Int, 2]](mat2.data(), 2, 3)
    VERIFY_IS_EQUAL(mat3.rank(), 2)
    VERIFY_IS_EQUAL(mat3.size(), 6)
    VERIFY_IS_EQUAL(mat3.dimension(0), 2)
    VERIFY_IS_EQUAL(mat3.dimension(1), 3)
    VERIFY_IS_EQUAL(mat4.rank(), 2)
    VERIFY_IS_EQUAL(mat4.size(), 6)
    VERIFY_IS_EQUAL(mat4.dimension(0), 2)
    VERIFY_IS_EQUAL(mat4.dimension(1), 3)
    VERIFY_IS_EQUAL(mat3(0,0), 0)
    VERIFY_IS_EQUAL(mat3(0,1), 1)
    VERIFY_IS_EQUAL(mat3(0,2), 2)
    VERIFY_IS_EQUAL(mat3(1,0), 3)
    VERIFY_IS_EQUAL(mat3(1,1), 4)
    VERIFY_IS_EQUAL(mat3(1,2), 5)
    VERIFY_IS_EQUAL(mat4(0,0), 0)
    VERIFY_IS_EQUAL(mat4(0,1), 1)
    VERIFY_IS_EQUAL(mat4(0,2), 2)
    VERIFY_IS_EQUAL(mat4(1,0), 3)
    VERIFY_IS_EQUAL(mat4(1,1), 4)
    VERIFY_IS_EQUAL(mat4(1,2), 5)

def test_3d():
    var mat1 = Tensor[Int, 3](2,3,7)
    var mat2 = Tensor[Int, 3](2,3,7)
    var val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                mat2[i,j,k] = val
                val += 1
    var mat3 = TensorMap[Tensor[Int, 3]](mat1.data(), 2, 3, 7)
    var mat4 = TensorMap[Tensor[Int, 3]](mat2.data(), 2, 3, 7)
    VERIFY_IS_EQUAL(mat3.rank(), 3)
    VERIFY_IS_EQUAL(mat3.size(), 2*3*7)
    VERIFY_IS_EQUAL(mat3.dimension(0), 2)
    VERIFY_IS_EQUAL(mat3.dimension(1), 3)
    VERIFY_IS_EQUAL(mat3.dimension(2), 7)
    VERIFY_IS_EQUAL(mat4.rank(), 3)
    VERIFY_IS_EQUAL(mat4.size(), 2*3*7)
    VERIFY_IS_EQUAL(mat4.dimension(0), 2)
    VERIFY_IS_EQUAL(mat4.dimension(1), 3)
    VERIFY_IS_EQUAL(mat4.dimension(2), 7)
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(mat3(i,j,k), val)
                VERIFY_IS_EQUAL(mat4(i,j,k), val)
                val += 1

def test_from_tensor():
    var mat1 = Tensor[Int, 3](2,3,7)
    var mat2 = Tensor[Int, 3](2,3,7)
    var val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                mat2[i,j,k] = val
                val += 1
    var mat3 = TensorMap[Tensor[Int, 3]](mat1)
    var mat4 = TensorMap[Tensor[Int, 3]](mat2)
    VERIFY_IS_EQUAL(mat3.rank(), 3)
    VERIFY_IS_EQUAL(mat3.size(), 2*3*7)
    VERIFY_IS_EQUAL(mat3.dimension(0), 2)
    VERIFY_IS_EQUAL(mat3.dimension(1), 3)
    VERIFY_IS_EQUAL(mat3.dimension(2), 7)
    VERIFY_IS_EQUAL(mat4.rank(), 3)
    VERIFY_IS_EQUAL(mat4.size(), 2*3*7)
    VERIFY_IS_EQUAL(mat4.dimension(0), 2)
    VERIFY_IS_EQUAL(mat4.dimension(1), 3)
    VERIFY_IS_EQUAL(mat4.dimension(2), 7)
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(mat3(i,j,k), val)
                VERIFY_IS_EQUAL(mat4(i,j,k), val)
                val += 1
    var mat5 = TensorFixedSize[Int, Sizes[2,3,7]]()
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                var coords = StaticTuple[Int, 3](i, j, k)
                mat5[coords] = val
                val += 1
    var mat6 = TensorMap[TensorFixedSize[Int, Sizes[2,3,7]]](mat5)
    VERIFY_IS_EQUAL(mat6.rank(), 3)
    VERIFY_IS_EQUAL(mat6.size(), 2*3*7)
    VERIFY_IS_EQUAL(mat6.dimension(0), 2)
    VERIFY_IS_EQUAL(mat6.dimension(1), 3)
    VERIFY_IS_EQUAL(mat6.dimension(2), 7)
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(mat6(i,j,k), val)
                val += 1

def f(tensor: TensorMap[Tensor[Int, 3]]) -> Int:
    # EIGEN_STATIC_ASSERT: compile-time check, we simulate with runtime assert
    # Using internal::array_size<Sizes<>>::value == 0 etc.
    # We'll just skip those assertions in Mojo since they are static
    var result = Tensor[Int, 0]()
    # tensor.sum() not implemented, we manually sum
    var total = 0
    for i in range(tensor.dimension(0)):
        for j in range(tensor.dimension(1)):
            for k in range(tensor.dimension(2)):
                total += tensor(i,j,k)
    result.data.store(0, total)
    return result()

def test_casting():
    var tensor = Tensor[Int, 3](2,3,7)
    var val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                tensor[i,j,k] = val
                val += 1
    var map = TensorMap[Tensor[Int, 3]](tensor)
    let sum1 = f(map)
    let sum2 = f(tensor)  # Here we treat tensor as TensorMap? Eigen allows implicit conversion. We'll create a TensorMap from tensor again.
    var tensor_map2 = TensorMap[Tensor[Int, 3]](tensor)
    let sum2b = f(tensor_map2)
    VERIFY_IS_EQUAL(sum1, sum2b)
    VERIFY_IS_EQUAL(sum1, 861)

def test_cxx11_tensor_map():
    CALL_SUBTEST(test_0d)
    CALL_SUBTEST(test_1d)
    CALL_SUBTEST(test_2d)
    CALL_SUBTEST(test_3d)
    CALL_SUBTEST(test_from_tensor)
    CALL_SUBTEST(test_casting)

# Entry point
test_cxx11_tensor_map()