from ......Eigen.CXX11.ThreadPool import RunQueue
from python import Python
from memory import UnsafePointer
from random import randint
from thread import Thread, Atomic, AtomicInt
from vector import DynamicVector

# Define test macros as functions
def VERIFY(condition: Bool):
    if not condition:
        print("VERIFY failed")
        abort()

def VERIFY_IS_EQUAL(a: Int, b: Int):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)
        abort()

def VERIFY_IS_EQUAL(a: UInt, b: UInt):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)
        abort()

def VERIFY_IS_NOT_EQUAL(a: Int, b: Int):
    if a == b:
        print("VERIFY_IS_NOT_EQUAL failed: ", a, " == ", b)
        abort()

def VERIFY_GE(a: Int, b: Int):
    if a < b:
        print("VERIFY_GE failed: ", a, " < ", b)
        abort()

def VERIFY_LE(a: Int, b: Int):
    if a > b:
        print("VERIFY_LE failed: ", a, " > ", b)
        abort()

def CALL_SUBTEST_1(f: fn() -> None):
    f()

def CALL_SUBTEST_2(f: fn() -> None):
    f()

def CALL_SUBTEST_3(f: fn() -> None):
    f()

# Thread yield macro
def EIGEN_THREAD_YIELD():
    # Mojo doesn't have a direct yield, use sleep(0) or similar
    Python.sleep(0)

# Reentrant random function (thread-safe)
def rand_reentrant(s: UnsafePointer[UInt32]) -> Int:
    # Use Python's random for simplicity (not thread-safe but test uses it)
    return randint(0, 2147483647)  # approximate rand() range

def test_basic_runqueue():
    var q = RunQueue[Int, 4]()
    VERIFY(q.Empty())
    VERIFY_IS_EQUAL(0u, q.Size())
    VERIFY_IS_EQUAL(0, q.PopFront())
    var stolen = DynamicVector[Int]()
    VERIFY_IS_EQUAL(0u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(0u, stolen.size())
    VERIFY_IS_EQUAL(0, q.PushFront(1))
    VERIFY_IS_EQUAL(1u, q.Size())
    VERIFY_IS_EQUAL(1, q.PopFront())
    VERIFY_IS_EQUAL(0u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushFront(2))
    VERIFY_IS_EQUAL(1u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushFront(3))
    VERIFY_IS_EQUAL(2u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushFront(4))
    VERIFY_IS_EQUAL(3u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushFront(5))
    VERIFY_IS_EQUAL(4u, q.Size())
    VERIFY_IS_EQUAL(6, q.PushFront(6))
    VERIFY_IS_EQUAL(4u, q.Size())
    VERIFY_IS_EQUAL(5, q.PopFront())
    VERIFY_IS_EQUAL(3u, q.Size())
    VERIFY_IS_EQUAL(4, q.PopFront())
    VERIFY_IS_EQUAL(2u, q.Size())
    VERIFY_IS_EQUAL(3, q.PopFront())
    VERIFY_IS_EQUAL(1u, q.Size())
    VERIFY_IS_EQUAL(2, q.PopFront())
    VERIFY_IS_EQUAL(0u, q.Size())
    VERIFY_IS_EQUAL(0, q.PopFront())
    VERIFY_IS_EQUAL(0, q.PushBack(7))
    VERIFY_IS_EQUAL(1u, q.Size())
    VERIFY_IS_EQUAL(1u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(1u, stolen.size())
    VERIFY_IS_EQUAL(7, stolen[0])
    VERIFY_IS_EQUAL(0u, q.Size())
    stolen.clear()
    VERIFY_IS_EQUAL(0, q.PushBack(8))
    VERIFY_IS_EQUAL(1u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushBack(9))
    VERIFY_IS_EQUAL(2u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushBack(10))
    VERIFY_IS_EQUAL(3u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushBack(11))
    VERIFY_IS_EQUAL(4u, q.Size())
    VERIFY_IS_EQUAL(12, q.PushBack(12))
    VERIFY_IS_EQUAL(4u, q.Size())
    VERIFY_IS_EQUAL(2u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(2u, stolen.size())
    VERIFY_IS_EQUAL(10, stolen[0])
    VERIFY_IS_EQUAL(11, stolen[1])
    VERIFY_IS_EQUAL(2u, q.Size())
    stolen.clear()
    VERIFY_IS_EQUAL(1u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(1u, stolen.size())
    VERIFY_IS_EQUAL(9, stolen[0])
    VERIFY_IS_EQUAL(1u, q.Size())
    stolen.clear()
    VERIFY_IS_EQUAL(1u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(1u, stolen.size())
    VERIFY_IS_EQUAL(8, stolen[0])
    stolen.clear()
    VERIFY_IS_EQUAL(0u, q.PopBackHalf(&stolen))
    VERIFY_IS_EQUAL(0u, stolen.size())
    VERIFY(q.Empty())
    VERIFY_IS_EQUAL(0u, q.Size())
    VERIFY_IS_EQUAL(0, q.PushFront(1))
    VERIFY_IS_EQUAL(0, q.PushFront(2))
    VERIFY_IS_EQUAL(0, q.PushFront(3))
    VERIFY_IS_EQUAL(1, q.PopBack())
    VERIFY_IS_EQUAL(2, q.PopBack())
    VERIFY_IS_EQUAL(3, q.PopBack())
    VERIFY(q.Empty())
    VERIFY_IS_EQUAL(0u, q.Size())

def test_empty_runqueue():
    var q = RunQueue[Int, 4]()
    q.PushFront(1)
    var done = Atomic[Bool](False)
    var mutator = Thread(fn[&q, &done]():
        var rnd: UInt32 = 0
        var stolen = DynamicVector[Int]()
        for i in range(0, 1 << 18):
            if rand_reentrant(UnsafePointer[UInt32].address_of(rnd)) % 2:
                VERIFY_IS_EQUAL(0, q.PushFront(1))
            else:
                VERIFY_IS_EQUAL(0, q.PushBack(1))
            if rand_reentrant(UnsafePointer[UInt32].address_of(rnd)) % 2:
                VERIFY_IS_EQUAL(1, q.PopFront())
            else:
                while True:
                    if q.PopBackHalf(&stolen) == 1:
                        stolen.clear()
                        break
                    VERIFY_IS_EQUAL(0u, stolen.size())
        done.store(True)
    )
    while not done.load():
        VERIFY(not q.Empty())
        var size = q.Size()
        VERIFY_GE(size, 1)
        VERIFY_LE(size, 2)
    VERIFY_IS_EQUAL(1, q.PopFront())
    mutator.join()

def test_stress_runqueue():
    var kEvents = 1 << 18
    var q = RunQueue[Int, 8]()
    var total = AtomicInt(0)
    var threads = DynamicVector[Thread]()
    threads.append(Thread(fn[&q, &total]():
        var sum = 0
        var pushed = 1
        var popped = 1
        while pushed < kEvents or popped < kEvents:
            if pushed < kEvents:
                if q.PushFront(pushed) == 0:
                    sum += pushed
                    pushed += 1
            if popped < kEvents:
                var v = q.PopFront()
                if v != 0:
                    sum -= v
                    popped += 1
        total.fetch_add(sum)
    ))
    for i in range(0, 2):
        threads.append(Thread(fn[&q, &total]():
            var sum = 0
            for j in range(1, kEvents):
                if q.PushBack(j) == 0:
                    sum += j
                    continue
                EIGEN_THREAD_YIELD()
                j -= 1
            total.fetch_add(sum)
        ))
        threads.append(Thread(fn[&q, &total]():
            var sum = 0
            var stolen = DynamicVector[Int]()
            var j = 1
            while j < kEvents:
                if q.PopBackHalf(&stolen) == 0:
                    EIGEN_THREAD_YIELD()
                    continue
                while stolen.size() > 0 and j < kEvents:
                    var v = stolen.back()
                    stolen.pop_back()
                    VERIFY_IS_NOT_EQUAL(v, 0)
                    sum += v
                    j += 1
            while stolen.size() > 0:
                var v = stolen.back()
                stolen.pop_back()
                VERIFY_IS_NOT_EQUAL(v, 0)
                while (v = q.PushBack(v)) != 0:
                    EIGEN_THREAD_YIELD()
            total.fetch_sub(sum)
        ))
    for i in range(0, threads.size()):
        threads[i].join()
    VERIFY(q.Empty())
    VERIFY(total.load() == 0)

def test_cxx11_runqueue():
    CALL_SUBTEST_1(test_basic_runqueue)
    CALL_SUBTEST_2(test_empty_runqueue)
    CALL_SUBTEST_3(test_stress_runqueue)