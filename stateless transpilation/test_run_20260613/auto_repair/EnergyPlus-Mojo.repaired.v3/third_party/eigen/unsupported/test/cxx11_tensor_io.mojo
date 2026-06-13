from main import VERIFY_IS_EQUAL, CALL_SUBTEST  # Assuming these are defined in the test framework
from Eigen.CXX11.Tensor import Tensor, TensorMap, ColMajor, RowMajor
from string import String
from sys import print

# Simulate stringstream
class StringStream:
    var buffer: String
    def __init__(inout self):
        self.buffer = String()
    def write[T: AnyType](inout self, value: T):
        self.buffer += value.to_string()
    def str(self) -> String:
        return self.buffer
    # Overload for Tensor (assumes tensor has to_string)
    def write_tensor(inout self, tensor: AnyType):
        self.write(tensor)

# Helper to write Tensor to stream (mimics os << tensor)
def write_tensor(inout os: StringStream, tensor: AnyType):
    # Use tensor's __str__ or to_string
    os.write(tensor.to_string())

template[int DataLayout]
def test_output_0d():
    var tensor = Tensor[int, 0, DataLayout]()
    tensor.set_from_index(0, 123)  # assuming constructor-like? In C++ tensor() = 123
    # Workaround: tensor() = 123; we need to set scalar.
    # We'll assume there's a set_value method.
    tensor.set_value(123)
    var os = StringStream()
    write_tensor(os, tensor)
    var expected = String("123")
    VERIFY_IS_EQUAL(os.str(), expected)

template[int DataLayout]
def test_output_1d():
    var tensor = Tensor[int, 1, DataLayout](5)
    for i in range(5):
        tensor[i] = i
    var os = StringStream()
    write_tensor(os, tensor)
    var expected = String("0\n1\n2\n3\n4")
    VERIFY_IS_EQUAL(os.str(), expected)
    var empty_tensor = Tensor[float64, 1, DataLayout](0)
    var empty_os = StringStream()
    write_tensor(empty_os, empty_tensor)
    var empty_string = String()
    VERIFY_IS_EQUAL(empty_os.str(), empty_string)

template[int DataLayout]
def test_output_2d():
    var tensor = Tensor[int, 2, DataLayout](5, 3)
    for i in range(5):
        for j in range(3):
            tensor[i, j] = i * j
    var os = StringStream()
    write_tensor(os, tensor)
    var expected = String("0  0  0\n0  1  2\n0  2  4\n0  3  6\n0  4  8")
    VERIFY_IS_EQUAL(os.str(), expected)

template[int DataLayout]
def test_output_expr():
    var tensor1 = Tensor[int, 1, DataLayout](5)
    var tensor2 = Tensor[int, 1, DataLayout](5)
    for i in range(5):
        tensor1[i] = i
        tensor2[i] = 7
    var sum = tensor1 + tensor2
    var os = StringStream()
    write_tensor(os, sum)
    var expected = String(" 7\n 8\n 9\n10\n11")
    VERIFY_IS_EQUAL(os.str(), expected)

template[int DataLayout]
def test_output_string():
    var tensor = Tensor[String, 2, DataLayout](5, 3)
    tensor.set_constant(String("foo"))
    print(tensor)
    var os = StringStream()
    write_tensor(os, tensor)
    var expected = String("foo  foo  foo\nfoo  foo  foo\nfoo  foo  foo\nfoo  foo  foo\nfoo  foo  foo")
    VERIFY_IS_EQUAL(os.str(), expected)

template[int DataLayout]
def test_output_const():
    var tensor = Tensor[int, 1, DataLayout](5)
    for i in range(5):
        tensor[i] = i
    var tensor_map = TensorMap[Tensor[const int, 1, DataLayout]](tensor.data(), 5)
    var os = StringStream()
    write_tensor(os, tensor_map)
    var expected = String("0\n1\n2\n3\n4")
    VERIFY_IS_EQUAL(os.str(), expected)

def test_cxx11_tensor_io():
    CALL_SUBTEST(test_output_0d[ColMajor]())
    CALL_SUBTEST(test_output_0d[RowMajor]())
    CALL_SUBTEST(test_output_1d[ColMajor]())
    CALL_SUBTEST(test_output_1d[RowMajor]())
    CALL_SUBTEST(test_output_2d[ColMajor]())
    CALL_SUBTEST(test_output_2d[RowMajor]())
    CALL_SUBTEST(test_output_expr[ColMajor]())
    CALL_SUBTEST(test_output_expr[RowMajor]())
    CALL_SUBTEST(test_output_string[ColMajor]())
    CALL_SUBTEST(test_output_string[RowMajor]())
    CALL_SUBTEST(test_output_const[ColMajor]())
    CALL_SUBTEST(test_output_const[RowMajor]())