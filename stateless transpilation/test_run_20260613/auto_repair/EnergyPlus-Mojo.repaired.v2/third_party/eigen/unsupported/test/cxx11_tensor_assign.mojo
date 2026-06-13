from main import main, CALL_SUBTEST, VERIFY_IS_EQUAL
from Eigen.CXX11.Tensor import Tensor, RowMajor, TensorMap, TensorFixedSize, Sizes

def test_1d():
    var vec1 = Tensor[int, 1](6)
    var vec2 = Tensor[int, 1, RowMajor](6)
    vec1[0] = 4;  vec2[0] = 0
    vec1[1] = 8;  vec2[1] = 1
    vec1[2] = 15; vec2[2] = 2
    vec1[3] = 16; vec2[3] = 3
    vec1[4] = 23; vec2[4] = 4
    vec1[5] = 42; vec2[5] = 5
    var col_major = Int[6]()
    var row_major = Int[6]()
    memset(col_major, 0, 6*sizeof[Int]())
    memset(row_major, 0, 6*sizeof[Int]())
    var vec3 = TensorMap[Tensor[int, 1]](col_major, 6)
    var vec4 = TensorMap[Tensor[int, 1, RowMajor]](row_major, 6)
    vec3 = vec1
    vec4 = vec2
    VERIFY_IS_EQUAL(vec3[0], 4)
    VERIFY_IS_EQUAL(vec3[1], 8)
    VERIFY_IS_EQUAL(vec3[2], 15)
    VERIFY_IS_EQUAL(vec3[3], 16)
    VERIFY_IS_EQUAL(vec3[4], 23)
    VERIFY_IS_EQUAL(vec3[5], 42)
    VERIFY_IS_EQUAL(vec4[0], 0)
    VERIFY_IS_EQUAL(vec4[1], 1)
    VERIFY_IS_EQUAL(vec4[2], 2)
    VERIFY_IS_EQUAL(vec4[3], 3)
    VERIFY_IS_EQUAL(vec4[4], 4)
    VERIFY_IS_EQUAL(vec4[5], 5)
    vec1.setZero()
    vec2.setZero()
    vec1 = vec3
    vec2 = vec4
    VERIFY_IS_EQUAL(vec1[0], 4)
    VERIFY_IS_EQUAL(vec1[1], 8)
    VERIFY_IS_EQUAL(vec1[2], 15)
    VERIFY_IS_EQUAL(vec1[3], 16)
    VERIFY_IS_EQUAL(vec1[4], 23)
    VERIFY_IS_EQUAL(vec1[5], 42)
    VERIFY_IS_EQUAL(vec2[0], 0)
    VERIFY_IS_EQUAL(vec2[1], 1)
    VERIFY_IS_EQUAL(vec2[2], 2)
    VERIFY_IS_EQUAL(vec2[3], 3)
    VERIFY_IS_EQUAL(vec2[4], 4)
    VERIFY_IS_EQUAL(vec2[5], 5)

def test_2d():
    var mat1 = Tensor[int, 2](2,3)
    var mat2 = Tensor[int, 2, RowMajor](2,3)
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
    var col_major = Int[6]()
    var row_major = Int[6]()
    memset(col_major, 0, 6*sizeof[Int]())
    memset(row_major, 0, 6*sizeof[Int]())
    var mat3 = TensorMap[Tensor[int, 2]](row_major, 2, 3)
    var mat4 = TensorMap[Tensor[int, 2, RowMajor]](col_major, 2, 3)
    mat3 = mat1
    mat4 = mat2
    VERIFY_IS_EQUAL(mat3[0,0], 0)
    VERIFY_IS_EQUAL(mat3[0,1], 1)
    VERIFY_IS_EQUAL(mat3[0,2], 2)
    VERIFY_IS_EQUAL(mat3[1,0], 3)
    VERIFY_IS_EQUAL(mat3[1,1], 4)
    VERIFY_IS_EQUAL(mat3[1,2], 5)
    VERIFY_IS_EQUAL(mat4[0,0], 0)
    VERIFY_IS_EQUAL(mat4[0,1], 1)
    VERIFY_IS_EQUAL(mat4[0,2], 2)
    VERIFY_IS_EQUAL(mat4[1,0], 3)
    VERIFY_IS_EQUAL(mat4[1,1], 4)
    VERIFY_IS_EQUAL(mat4[1,2], 5)
    mat1.setZero()
    mat2.setZero()
    mat1 = mat3
    mat2 = mat4
    VERIFY_IS_EQUAL(mat1[0,0], 0)
    VERIFY_IS_EQUAL(mat1[0,1], 1)
    VERIFY_IS_EQUAL(mat1[0,2], 2)
    VERIFY_IS_EQUAL(mat1[1,0], 3)
    VERIFY_IS_EQUAL(mat1[1,1], 4)
    VERIFY_IS_EQUAL(mat1[1,2], 5)
    VERIFY_IS_EQUAL(mat2[0,0], 0)
    VERIFY_IS_EQUAL(mat2[0,1], 1)
    VERIFY_IS_EQUAL(mat2[0,2], 2)
    VERIFY_IS_EQUAL(mat2[1,0], 3)
    VERIFY_IS_EQUAL(mat2[1,1], 4)
    VERIFY_IS_EQUAL(mat2[1,2], 5)

def test_3d():
    var mat1 = Tensor[int, 3](2,3,7)
    var mat2 = Tensor[int, 3, RowMajor](2,3,7)
    var val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                mat2[i,j,k] = val
                val += 1
    var col_major = Int[2*3*7]()
    var row_major = Int[2*3*7]()
    memset(col_major, 0, 2*3*7*sizeof[Int]())
    memset(row_major, 0, 2*3*7*sizeof[Int]())
    var mat3 = TensorMap[Tensor[int, 3]](col_major, 2, 3, 7)
    var mat4 = TensorMap[Tensor[int, 3, RowMajor]](row_major, 2, 3, 7)
    mat3 = mat1
    mat4 = mat2
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(mat3[i,j,k], val)
                VERIFY_IS_EQUAL(mat4[i,j,k], val)
                val += 1
    mat1.setZero()
    mat2.setZero()
    mat1 = mat3
    mat2 = mat4
    val = 0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(mat1[i,j,k], val)
                VERIFY_IS_EQUAL(mat2[i,j,k], val)
                val += 1

def test_same_type():
    var orig_tensor = Tensor[int, 1](5)
    var dest_tensor = Tensor[int, 1](5)
    orig_tensor.setRandom()
    dest_tensor.setRandom()
    var orig_data = orig_tensor.data()
    var dest_data = dest_tensor.data()
    dest_tensor = orig_tensor
    VERIFY_IS_EQUAL(orig_tensor.data(), orig_data)
    VERIFY_IS_EQUAL(dest_tensor.data(), dest_data)
    for i in range(5):
        VERIFY_IS_EQUAL(dest_tensor[i], orig_tensor[i])
    var orig_array = TensorFixedSize[int, Sizes[5]]()
    var dest_array = TensorFixedSize[int, Sizes[5]]()
    orig_array.setRandom()
    dest_array.setRandom()
    orig_data = orig_array.data()
    dest_data = dest_array.data()
    dest_array = orig_array
    VERIFY_IS_EQUAL(orig_array.data(), orig_data)
    VERIFY_IS_EQUAL(dest_array.data(), dest_data)
    for i in range(5):
        VERIFY_IS_EQUAL(dest_array[i], orig_array[i])
    var orig = Int[5](1, 2, 3, 4, 5)
    var dest = Int[5](6, 7, 8, 9, 10)
    var orig_map = TensorMap[Tensor[int, 1]](orig, 5)
    var dest_map = TensorMap[Tensor[int, 1]](dest, 5)
    orig_data = orig_map.data()
    dest_data = dest_map.data()
    dest_map = orig_map
    VERIFY_IS_EQUAL(orig_map.data(), orig_data)
    VERIFY_IS_EQUAL(dest_map.data(), dest_data)
    for i in range(5):
        VERIFY_IS_EQUAL(dest[i], i+1)

def test_auto_resize():
    var tensor1 = Tensor[int, 1]()
    var tensor2 = Tensor[int, 1](3)
    var tensor3 = Tensor[int, 1](5)
    var tensor4 = Tensor[int, 1](7)
    var new_tensor = Tensor[int, 1](5)
    new_tensor.setRandom()
    tensor1 = tensor2 = tensor3 = tensor4 = new_tensor
    VERIFY_IS_EQUAL(tensor1.dimension(0), new_tensor.dimension(0))
    VERIFY_IS_EQUAL(tensor2.dimension(0), new_tensor.dimension(0))
    VERIFY_IS_EQUAL(tensor3.dimension(0), new_tensor.dimension(0))
    VERIFY_IS_EQUAL(tensor4.dimension(0), new_tensor.dimension(0))
    for i in range(new_tensor.dimension(0)):
        VERIFY_IS_EQUAL(tensor1[i], new_tensor[i])
        VERIFY_IS_EQUAL(tensor2[i], new_tensor[i])
        VERIFY_IS_EQUAL(tensor3[i], new_tensor[i])
        VERIFY_IS_EQUAL(tensor4[i], new_tensor[i])

def test_compound_assign():
    var start_tensor = Tensor[int, 1](10)
    var offset_tensor = Tensor[int, 1](10)
    start_tensor.setRandom()
    offset_tensor.setRandom()
    var tensor = start_tensor
    tensor += offset_tensor
    for i in range(10):
        VERIFY_IS_EQUAL(tensor[i], start_tensor[i] + offset_tensor[i])
    tensor = start_tensor
    tensor -= offset_tensor
    for i in range(10):
        VERIFY_IS_EQUAL(tensor[i], start_tensor[i] - offset_tensor[i])
    tensor = start_tensor
    tensor *= offset_tensor
    for i in range(10):
        VERIFY_IS_EQUAL(tensor[i], start_tensor[i] * offset_tensor[i])
    tensor = start_tensor
    tensor /= offset_tensor
    for i in range(10):
        VERIFY_IS_EQUAL(tensor[i], start_tensor[i] / offset_tensor[i])

def test_std_initializers_tensor():
    var a = Tensor[int, 1](3)
    a.setValues([0, 1, 2])
    VERIFY_IS_EQUAL(a[0], 0)
    VERIFY_IS_EQUAL(a[1], 1)
    VERIFY_IS_EQUAL(a[2], 2)
    a.setValues([10, 20])
    VERIFY_IS_EQUAL(a[0], 10)
    VERIFY_IS_EQUAL(a[1], 20)
    VERIFY_IS_EQUAL(a[2], 2)
    var a2 = Tensor[int, 1](3)
    a2 = a.setValues([100, 200, 300])
    VERIFY_IS_EQUAL(a[0], 100)
    VERIFY_IS_EQUAL(a[1], 200)
    VERIFY_IS_EQUAL(a[2], 300)
    VERIFY_IS_EQUAL(a2[0], 100)
    VERIFY_IS_EQUAL(a2[1], 200)
    VERIFY_IS_EQUAL(a2[2], 300)
    var b = Tensor[int, 2](2, 3)
    b.setValues([[0, 1, 2], [3, 4, 5]])
    VERIFY_IS_EQUAL(b[0, 0], 0)
    VERIFY_IS_EQUAL(b[0, 1], 1)
    VERIFY_IS_EQUAL(b[0, 2], 2)
    VERIFY_IS_EQUAL(b[1, 0], 3)
    VERIFY_IS_EQUAL(b[1, 1], 4)
    VERIFY_IS_EQUAL(b[1, 2], 5)
    b.setValues([[10, 20], [30]])
    VERIFY_IS_EQUAL(b[0, 0], 10)
    VERIFY_IS_EQUAL(b[0, 1], 20)
    VERIFY_IS_EQUAL(b[0, 2], 2)
    VERIFY_IS_EQUAL(b[1, 0], 30)
    VERIFY_IS_EQUAL(b[1, 1], 4)
    VERIFY_IS_EQUAL(b[1, 2], 5)
    var c = Tensor[int, 3](3, 2, 4)
    c.setValues([[[0, 1, 2, 3], [4, 5, 6, 7]],
                 [[10, 11, 12, 13], [14, 15, 16, 17]],
                 [[20, 21, 22, 23], [24, 25, 26, 27]]])
    VERIFY_IS_EQUAL(c[0, 0, 0], 0)
    VERIFY_IS_EQUAL(c[0, 0, 1], 1)
    VERIFY_IS_EQUAL(c[0, 0, 2], 2)
    VERIFY_IS_EQUAL(c[0, 0, 3], 3)
    VERIFY_IS_EQUAL(c[0, 1, 0], 4)
    VERIFY_IS_EQUAL(c[0, 1, 1], 5)
    VERIFY_IS_EQUAL(c[0, 1, 2], 6)
    VERIFY_IS_EQUAL(c[0, 1, 3], 7)
    VERIFY_IS_EQUAL(c[1, 0, 0], 10)
    VERIFY_IS_EQUAL(c[1, 0, 1], 11)
    VERIFY_IS_EQUAL(c[1, 0, 2], 12)
    VERIFY_IS_EQUAL(c[1, 0, 3], 13)
    VERIFY_IS_EQUAL(c[1, 1, 0], 14)
    VERIFY_IS_EQUAL(c[1, 1, 1], 15)
    VERIFY_IS_EQUAL(c[1, 1, 2], 16)
    VERIFY_IS_EQUAL(c[1, 1, 3], 17)
    VERIFY_IS_EQUAL(c[2, 0, 0], 20)
    VERIFY_IS_EQUAL(c[2, 0, 1], 21)
    VERIFY_IS_EQUAL(c[2, 0, 2], 22)
    VERIFY_IS_EQUAL(c[2, 0, 3], 23)
    VERIFY_IS_EQUAL(c[2, 1, 0], 24)
    VERIFY_IS_EQUAL(c[2, 1, 1], 25)
    VERIFY_IS_EQUAL(c[2, 1, 2], 26)
    VERIFY_IS_EQUAL(c[2, 1, 3], 27)

def test_cxx11_tensor_assign():
    CALL_SUBTEST(test_1d())
    CALL_SUBTEST(test_2d())
    CALL_SUBTEST(test_3d())
    CALL_SUBTEST(test_same_type())
    CALL_SUBTEST(test_auto_resize())
    CALL_SUBTEST(test_compound_assign())
    CALL_SUBTEST(test_std_initializers_tensor())