from main import main, VERIFY_IS_NOT_EQUAL, VERIFY_IS_EQUAL, CALL_SUBTEST
from tensor import Tensor, DenseIndex
from eigen import internal

def test_default() raises:
    var vec = Tensor[f32, 1](6)
    vec.setRandom()
    for i in range(1, 6):
        VERIFY_IS_NOT_EQUAL(vec(i), vec(i-1))

def test_normal() raises:
    var vec = Tensor[f32, 1](6)
    vec.setRandom[Eigen.internal.NormalRandomGenerator[f32]]()
    for i in range(1, 6):
        VERIFY_IS_NOT_EQUAL(vec(i), vec(i-1))

struct MyGenerator:
    def __init__(inout self):

    def __init__(inout self, other: MyGenerator):

    def __call__(self, element_location: DenseIndex, unused: DenseIndex = 0) -> Int:
        return static_cast[Int](3 * element_location)
    def packetOp(self, packet_location: DenseIndex, unused: DenseIndex = 0) -> internal.packet_traits[Int].type:
        var packetSize = internal.packet_traits[Int].size
        var values = EIGEN_ALIGN_MAX Int[packetSize]
        for i in range(packetSize):
            values[i] = static_cast[Int](3 * (packet_location + i))
        return internal.pload[internal.packet_traits[Int].type](values)

def test_custom() raises:
    var vec = Tensor[Int, 1](6)
    vec.setRandom[MyGenerator]()
    for i in range(6):
        VERIFY_IS_EQUAL(vec(i), 3*i)

def test_cxx11_tensor_random() raises:
    CALL_SUBTEST(test_default())
    CALL_SUBTEST(test_normal())
    CALL_SUBTEST(test_custom())