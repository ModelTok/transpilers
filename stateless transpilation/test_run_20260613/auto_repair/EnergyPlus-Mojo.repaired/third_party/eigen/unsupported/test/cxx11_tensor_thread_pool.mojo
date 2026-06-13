# EIGEN_USE_THREADS
from main import *
from Eigen.CXX11.Tensor import *
import "iostream"
using Eigen.Tensor

def test_multithread_elementwise():
    var in1 = Tensor[float32, 3](2, 3, 7)
    var in2 = Tensor[float32, 3](2, 3, 7)
    var out = Tensor[float32, 3](2, 3, 7)
    in1.setRandom()
    in2.setRandom()
    var tp = Eigen.ThreadPool(internal.random[int](3, 11))
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, internal.random[int](3, 11))
    out.device(thread_pool_device) = in1 + in2 * 3.14
    for i in range(0, 2):
        for j in range(0, 3):
            for k in range(0, 7):
                VERIFY_IS_APPROX(out[i, j, k], in1[i, j, k] + in2[i, j, k] * 3.14)

def test_multithread_compound_assignment():
    var in1 = Tensor[float32, 3](2, 3, 7)
    var in2 = Tensor[float32, 3](2, 3, 7)
    var out = Tensor[float32, 3](2, 3, 7)
    in1.setRandom()
    in2.setRandom()
    var tp = Eigen.ThreadPool(internal.random[int](3, 11))
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, internal.random[int](3, 11))
    out.device(thread_pool_device) = in1
    out.device(thread_pool_device) += in2 * 3.14
    for i in range(0, 2):
        for j in range(0, 3):
            for k in range(0, 7):
                VERIFY_IS_APPROX(out[i, j, k], in1[i, j, k] + in2[i, j, k] * 3.14)

def test_multithread_contraction[DataLayout: Int]():
    var t_left = Tensor[float32, 4, DataLayout](30, 50, 37, 31)
    var t_right = Tensor[float32, 5, DataLayout](37, 31, 70, 2, 10)
    var t_result = Tensor[float32, 5, DataLayout](30, 50, 70, 2, 10)
    t_left.setRandom()
    t_right.setRandom()
    typedef DimPair = Tensor[float32, 1].DimensionPair
    var dims = Eigen.array[DimPair, 2]([DimPair(2, 0), DimPair(3, 1)])
    typedef MapXf = Map[Matrix[float32, Dynamic, Dynamic, DataLayout]]
    var m_left = MapXf(t_left.data(), 1500, 1147)
    var m_right = MapXf(t_right.data(), 1147, 1400)
    var m_result = Matrix[float32, Dynamic, Dynamic, DataLayout](1500, 1400)
    var tp = Eigen.ThreadPool(4)
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, 4)
    t_result.device(thread_pool_device) = t_left.contract(t_right, dims)
    m_result = m_left * m_right
    for i in range(0, t_result.size()):
        VERIFY(&t_result.data()[i] != &m_result.data()[i])
        if fabsf(t_result(i) - m_result(i)) < 1e-4:
            continue
        if Eigen.internal.isApprox(t_result(i), m_result(i), 1e-4):
            continue
        std.cout << "mismatch detected at index " << i << ": " << t_result(i) << " vs " << m_result(i) << std.endl
        assert(False)

def test_contraction_corner_cases[DataLayout: Int]():
    var t_left = Tensor[float32, 2, DataLayout](32, 500)
    var t_right = Tensor[float32, 2, DataLayout](32, 28*28)
    var t_result = Tensor[float32, 2, DataLayout](500, 28*28)
    t_left = (t_left.constant(-0.5) + t_left.random()) * 2.0
    t_right = (t_right.constant(-0.6) + t_right.random()) * 2.0
    t_result = t_result.constant(NAN)
    typedef DimPair = Tensor[float32, 1].DimensionPair
    var dims = Eigen.array[DimPair, 1]([DimPair(0, 0)])
    typedef MapXf = Map[Matrix[float32, Dynamic, Dynamic, DataLayout]]
    var m_left = MapXf(t_left.data(), 32, 500)
    var m_right = MapXf(t_right.data(), 32, 28*28)
    var m_result = Matrix[float32, Dynamic, Dynamic, DataLayout](500, 28*28)
    var tp = Eigen.ThreadPool(12)
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, 12)
    t_result.device(thread_pool_device) = t_left.contract(t_right, dims)
    m_result = m_left.transpose() * m_right
    for i in range(0, t_result.size()):
        assert(not (numext.isnan)(t_result.data()[i]))
        if fabsf(t_result.data()[i] - m_result.data()[i]) >= 1e-4:
            std.cout << "mismatch detected at index " << i << " : " << t_result.data()[i] << " vs " << m_result.data()[i] << std.endl
            assert(False)
    t_left.resize(32, 1)
    t_left = (t_left.constant(-0.5) + t_left.random()) * 2.0
    t_result.resize(1, 28*28)
    t_result = t_result.constant(NAN)
    t_result.device(thread_pool_device) = t_left.contract(t_right, dims)
    new(&m_left) MapXf(t_left.data(), 32, 1)
    m_result = m_left.transpose() * m_right
    for i in range(0, t_result.size()):
        assert(not (numext.isnan)(t_result.data()[i]))
        if fabsf(t_result.data()[i] - m_result.data()[i]) >= 1e-4:
            std.cout << "mismatch detected: " << t_result.data()[i] << " vs " << m_result.data()[i] << std.endl
            assert(False)
    t_left.resize(32, 500)
    t_right.resize(32, 4)
    t_left = (t_left.constant(-0.5) + t_left.random()) * 2.0
    t_right = (t_right.constant(-0.6) + t_right.random()) * 2.0
    t_result.resize(500, 4)
    t_result = t_result.constant(NAN)
    t_result.device(thread_pool_device) = t_left.contract(t_right, dims)
    new(&m_left) MapXf(t_left.data(), 32, 500)
    new(&m_right) MapXf(t_right.data(), 32, 4)
    m_result = m_left.transpose() * m_right
    for i in range(0, t_result.size()):
        assert(not (numext.isnan)(t_result.data()[i]))
        if fabsf(t_result.data()[i] - m_result.data()[i]) >= 1e-4:
            std.cout << "mismatch detected: " << t_result.data()[i] << " vs " << m_result.data()[i] << std.endl
            assert(False)
    t_left.resize(32, 1)
    t_right.resize(32, 4)
    t_left = (t_left.constant(-0.5) + t_left.random()) * 2.0
    t_right = (t_right.constant(-0.6) + t_right.random()) * 2.0
    t_result.resize(1, 4)
    t_result = t_result.constant(NAN)
    t_result.device(thread_pool_device) = t_left.contract(t_right, dims)
    new(&m_left) MapXf(t_left.data(), 32, 1)
    new(&m_right) MapXf(t_right.data(), 32, 4)
    m_result = m_left.transpose() * m_right
    for i in range(0, t_result.size()):
        assert(not (numext.isnan)(t_result.data()[i]))
        if fabsf(t_result.data()[i] - m_result.data()[i]) >= 1e-4:
            std.cout << "mismatch detected: " << t_result.data()[i] << " vs " << m_result.data()[i] << std.endl
            assert(False)

def test_multithread_contraction_agrees_with_singlethread[DataLayout: Int]():
    var contract_size = internal.random[int](1, 5000)
    var left = Tensor[float32, 3, DataLayout](internal.random[int](1, 80), contract_size, internal.random[int](1, 100))
    var right = Tensor[float32, 4, DataLayout](internal.random[int](1, 25), internal.random[int](1, 37), contract_size, internal.random[int](1, 51))
    left.setRandom()
    right.setRandom()
    left += left.constant(1.5)
    right += right.constant(1.5)
    typedef DimPair = Tensor[float32, 1].DimensionPair
    var dims = Eigen.array[DimPair, 1]([DimPair(1, 2)])
    var tp = Eigen.ThreadPool(internal.random[int](2, 11))
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, internal.random[int](2, 11))
    var st_result = Tensor[float32, 5, DataLayout]()
    st_result = left.contract(right, dims)
    var tp_result = Tensor[float32, 5, DataLayout](st_result.dimensions())
    tp_result.device(thread_pool_device) = left.contract(right, dims)
    VERIFY(dimensions_match(st_result.dimensions(), tp_result.dimensions()))
    for i in range(0, st_result.size()):
        if numext.abs(st_result.data()[i] - tp_result.data()[i]) >= 1e-4:
            VERIFY_IS_APPROX(st_result.data()[i], tp_result.data()[i])

def test_full_contraction[DataLayout: Int]():
    var contract_size1 = internal.random[int](1, 500)
    var contract_size2 = internal.random[int](1, 500)
    var left = Tensor[float32, 2, DataLayout](contract_size1, contract_size2)
    var right = Tensor[float32, 2, DataLayout](contract_size1, contract_size2)
    left.setRandom()
    right.setRandom()
    left += left.constant(1.5)
    right += right.constant(1.5)
    typedef DimPair = Tensor[float32, 2].DimensionPair
    var dims = Eigen.array[DimPair, 2]([DimPair(0, 0), DimPair(1, 1)])
    var tp = Eigen.ThreadPool(internal.random[int](2, 11))
    var thread_pool_device = Eigen.ThreadPoolDevice(&tp, internal.random[int](2, 11))
    var st_result = Tensor[float32, 0, DataLayout]()
    st_result = left.contract(right, dims)
    var tp_result = Tensor[float32, 0, DataLayout]()
    tp_result.device(thread_pool_device) = left.contract(right, dims)
    VERIFY(dimensions_match(st_result.dimensions(), tp_result.dimensions()))
    if numext.abs(st_result() - tp_result()) >= 1e-4:
        VERIFY_IS_APPROX(st_result(), tp_result())

def test_multithreaded_reductions[DataLayout: Int]():
    var num_threads = internal.random[int](3, 11)
    var thread_pool = ThreadPool(num_threads)
    var thread_pool_device = Eigen.ThreadPoolDevice(&thread_pool, num_threads)
    var num_rows = internal.random[int](13, 732)
    var num_cols = internal.random[int](13, 732)
    var t1 = Tensor[float32, 2, DataLayout](num_rows, num_cols)
    t1.setRandom()
    var full_redux = Tensor[float32, 0, DataLayout]()
    full_redux = t1.sum()
    var full_redux_tp = Tensor[float32, 0, DataLayout]()
    full_redux_tp.device(thread_pool_device) = t1.sum()
    VERIFY_IS_APPROX(full_redux(), full_redux_tp())

def test_memcpy():
    for i in range(0, 5):
        var num_threads = internal.random[int](3, 11)
        var tp = Eigen.ThreadPool(num_threads)
        var thread_pool_device = Eigen.ThreadPoolDevice(&tp, num_threads)
        var size = internal.random[int](13, 7632)
        var t1 = Tensor[float32, 1](size)
        t1.setRandom()
        var result = std.vector[float32](size)
        thread_pool_device.memcpy(&result[0], t1.data(), size * sizeof[float32]())
        for j in range(0, size):
            VERIFY_IS_EQUAL(t1(j), result[j])

def test_multithread_random():
    var tp = Eigen.ThreadPool(2)
    var device = Eigen.ThreadPoolDevice(&tp, 2)
    var t = Tensor[float32, 1](1 << 20)
    t.device(device) = t.random[Eigen.internal.NormalRandomGenerator[float32]]()

def test_multithread_shuffle[DataLayout: Int]():
    var tensor = Tensor[float32, 4, DataLayout](17, 5, 7, 11)
    tensor.setRandom()
    var num_threads = internal.random[int](2, 11)
    var threads = ThreadPool(num_threads)
    var device = Eigen.ThreadPoolDevice(&threads, num_threads)
    var shuffle = Tensor[float32, 4, DataLayout](7, 5, 11, 17)
    var shuffles = array[ptrdiff_t, 4]([2, 1, 3, 0])
    shuffle.device(device) = tensor.shuffle(shuffles)
    for i in range(0, 17):
        for j in range(0, 5):
            for k in range(0, 7):
                for l in range(0, 11):
                    VERIFY_IS_EQUAL(tensor[i, j, k, l], shuffle[k, j, l, i])

def test_cxx11_tensor_thread_pool():
    CALL_SUBTEST_1(test_multithread_elementwise())
    CALL_SUBTEST_1(test_multithread_compound_assignment())
    CALL_SUBTEST_2(test_multithread_contraction[ColMajor]())
    CALL_SUBTEST_2(test_multithread_contraction[RowMajor]())
    CALL_SUBTEST_3(test_multithread_contraction_agrees_with_singlethread[ColMajor]())
    CALL_SUBTEST_3(test_multithread_contraction_agrees_with_singlethread[RowMajor]())
    CALL_SUBTEST_4(test_contraction_corner_cases[ColMajor]())
    CALL_SUBTEST_4(test_contraction_corner_cases[RowMajor]())
    CALL_SUBTEST_4(test_full_contraction[ColMajor]())
    CALL_SUBTEST_4(test_full_contraction[RowMajor]())
    CALL_SUBTEST_5(test_multithreaded_reductions[ColMajor]())
    CALL_SUBTEST_5(test_multithreaded_reductions[RowMajor]())
    CALL_SUBTEST_6(test_memcpy())
    CALL_SUBTEST_6(test_multithread_random())
    CALL_SUBTEST_6(test_multithread_shuffle[ColMajor]())
    CALL_SUBTEST_6(test_multithread_shuffle[RowMajor]())