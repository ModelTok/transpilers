#define EIGEN_USE_THREADS
from main import *
# include <stdlib.h>
# include <Eigen/CXX11/Tensor>
#if EIGEN_OS_WIN || EIGEN_OS_WIN64
# include <windows.h>
#else
# include <unistd.h>
#endif
namespace:
def WaitAndAdd(n: Notification, counter: Pointer[Int32]):
    n.Wait()
    counter.store(counter.load() + 1)


def test_notification_single():
    var thread_pool: ThreadPool = ThreadPool(1)
    var counter: Int32 = 0
    var n: Notification = Notification()
    var func: fn() -> None = lambda: WaitAndAdd(n, Pointer[Int32](address_of(counter)))
    thread_pool.Schedule(func)
    sleep(1)
    VERIFY_IS_EQUAL(counter, 0)
    n.Notify()
    sleep(1)
    VERIFY_IS_EQUAL(counter, 1)


def test_notification_multiple():
    var thread_pool: ThreadPool = ThreadPool(1)
    var counter: Int32 = 0
    var n: Notification = Notification()
    var func: fn() -> None = lambda: WaitAndAdd(n, Pointer[Int32](address_of(counter)))
    thread_pool.Schedule(func)
    thread_pool.Schedule(func)
    thread_pool.Schedule(func)
    thread_pool.Schedule(func)
    sleep(1)
    VERIFY_IS_EQUAL(counter, 0)
    n.Notify()
    sleep(1)
    VERIFY_IS_EQUAL(counter, 4)


def test_cxx11_tensor_notification():
    CALL_SUBTEST(test_notification_single())
    CALL_SUBTEST(test_notification_multiple())