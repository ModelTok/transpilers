from Eigen.CXX11.ThreadPool import NonBlockingThreadPool
from main import *
from memory import Atomic
from sys import int_type

def test_create_destroy_empty_pool() raises:
    for i in range(16):
        var tp = NonBlockingThreadPool(i)

def test_parallelism() raises:
    const kThreads: int_type = 16  # code below expects that this is a multiple of 4
    var tp = NonBlockingThreadPool(kThreads)
    VERIFY_IS_EQUAL(tp.NumThreads(), kThreads)
    VERIFY_IS_EQUAL(tp.CurrentThreadId(), -1)
    for iter in range(100):
        var running = Atomic[int_type](0)
        var done = Atomic[int_type](0)
        var phase = Atomic[int_type](0)
        for i in range(kThreads):
            tp.Schedule(lambda: raises():
                var thread_id = tp.CurrentThreadId()
                VERIFY_GE(thread_id, 0)
                VERIFY_LE(thread_id, kThreads - 1)
                running.fetch_add(1)
                while phase.load() < 1:

                done.fetch_add(1)
            )
        while running.load() != kThreads:

        running.store(0)
        phase.store(1)
        for i in range(kThreads):
            tp.Schedule(lambda i=i: raises():
                running.fetch_add(1)
                while phase.load() < 2:

                if i < kThreads // 2:

                elif i < 3 * kThreads // 4:
                    running.fetch_add(1)
                    while phase.load() < 3:

                    done.fetch_add(1)
                else:
                    for j in range(2):
                        tp.Schedule(lambda: raises():
                            running.fetch_add(1)
                            while phase.load() < 3:

                            done.fetch_add(1)
                        )
                done.fetch_add(1)
            )
        while running.load() != kThreads:

        running.store(0)
        phase.store(2)
        for i in range(kThreads // 4):
            tp.Schedule(lambda: raises():
                running.fetch_add(1)
                while phase.load() < 3:

                done.fetch_add(1)
            )
        while running.load() != kThreads:

        phase.store(3)
        while done.load() != 3 * kThreads:

def test_cxx11_non_blocking_thread_pool() raises:
    CALL_SUBTEST(test_create_destroy_empty_pool())
    CALL_SUBTEST(test_parallelism())