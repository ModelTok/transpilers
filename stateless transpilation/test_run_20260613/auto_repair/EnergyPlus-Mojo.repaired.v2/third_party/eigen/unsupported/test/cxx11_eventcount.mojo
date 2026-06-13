// #define EIGEN_USE_THREADS
from main import CALL_SUBTEST, VERIFY_IS_EQUAL, VERIFY_GE, VERIFY_LE, EIGEN_THREAD_YIELD
from ......Eigen.CXX11.ThreadPool import EventCount, MaxSizeVector

# In Mojo we define a constant to mimic the C++ preprocessor branch
alias EIGEN_COMP_MSVC_STRICT = False

def rand_reentrant(s: Pointer[UInt32]) -> Int:
    # Original C++ had:
    # #ifdef EIGEN_COMP_MSVC_STRICT
    #   EIGEN_UNUSED_VARIABLE(s);
    #   return rand();
    # #else
    #   return rand_r(s);
    # #endif
    # We implement a compatible LCG for both branches.
    var seed: UInt32 = s.load()
    # LCG from glibc rand_r
    seed = (seed * 1103515245 + 12345) & 0x7fffffff
    s.store(seed)
    return Int(seed)

def test_basic_eventcount():
    var waiters = MaxSizeVector[EventCount.Waiter](1)
    waiters.resize(1)
    var ec = EventCount(waiters)
    var w = waiters[0]
    ec.Notify(False)
    ec.Prewait(Pointer[EventCount.Waiter](w))
    ec.Notify(True)
    ec.CommitWait(Pointer[EventCount.Waiter](w))
    ec.Prewait(Pointer[EventCount.Waiter](w))
    ec.CancelWait(Pointer[EventCount.Waiter](w))

struct TestQueue:
    var val_: Atomic[Int]
    static var kQueueSize: Int = 10

    def __init__(inout self):
        self.val_ = Atomic[Int]()
    def __del__(owned self):
        VERIFY_IS_EQUAL(self.val_.load(memory_order_relaxed), 0)

    def Push(self) -> Bool:
        var val = self.val_.load(memory_order_relaxed)
        while True:
            VERIFY_GE(val, 0)
            VERIFY_LE(val, TestQueue.kQueueSize)
            if val == TestQueue.kQueueSize:
                return False
            if self.val_.compare_exchange_weak(Pointer[Int](val), val + 1, memory_order_relaxed):
                return True

    def Pop(self) -> Bool:
        var val = self.val_.load(memory_order_relaxed)
        while True:
            VERIFY_GE(val, 0)
            VERIFY_LE(val, TestQueue.kQueueSize)
            if val == 0:
                return False
            if self.val_.compare_exchange_weak(Pointer[Int](val), val - 1, memory_order_relaxed):
                return True

    def Empty(self) -> Bool:
        return self.val_.load(memory_order_relaxed) == 0

def test_stress_eventcount():
    let kThreads = Python.int(Python.os.cpu_count())  # approximate thread::hardware_concurrency()
    static let kEvents = 1 << 16
    static let kQueues = 10
    var waiters = MaxSizeVector[EventCount.Waiter](kThreads)
    waiters.resize(kThreads)
    var ec = EventCount(waiters)
    var queues = Python.list[TestQueue]([TestQueue() for _ in range(kQueues)])
    var producer_threads = Python.list[Python.threading.Thread]()
    for i in range(kThreads):
        var t = Python.threading.Thread(target = lambda: producer_func(ec, queues, kEvents, kQueues))
        producer_threads.append(t)
        t.start()
    var consumer_threads = Python.list[Python.threading.Thread]()
    for i in range(kThreads):
        # Capture i for waiter index
        var idx = i
        var t = Python.threading.Thread(target = lambda: consumer_func(ec, queues, waiters, idx, kEvents, kQueues))
        consumer_threads.append(t)
        t.start()
    for i in range(kThreads):
        producer_threads[i].join()
        consumer_threads[i].join()

def producer_func(ec: EventCount, queues: Python.list[TestQueue], kEvents: Int, kQueues: Int):
    var rnd = UInt32(Python.hash(Python.threading.current_thread().ident))
    for j in range(kEvents):
        var idx = rand_reentrant(Pointer[UInt32](rnd)) % kQueues
        if queues[idx].Push():
            ec.Notify(False)
            continue
        EIGEN_THREAD_YIELD()
        j -= 1

def consumer_func(ec: EventCount, queues: Python.list[TestQueue], waiters: MaxSizeVector[EventCount.Waiter], i: Int, kEvents: Int, kQueues: Int):
    var w = waiters[i]
    var rnd = UInt32(Python.hash(Python.threading.current_thread().ident))
    for j in range(kEvents):
        var idx = rand_reentrant(Pointer[UInt32](rnd)) % kQueues
        if queues[idx].Pop():
            continue
        j -= 1
        ec.Prewait(Pointer[EventCount.Waiter](w))
        var empty = True
        for q in range(kQueues):
            if not queues[q].Empty():
                empty = False
                break
        if not empty:
            ec.CancelWait(Pointer[EventCount.Waiter](w))
            continue
        ec.CommitWait(Pointer[EventCount.Waiter](w))

def test_cxx11_eventcount():
    CALL_SUBTEST(test_basic_eventcount())
    CALL_SUBTEST(test_stress_eventcount())