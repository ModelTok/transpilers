from BenchUtil import DISABLE_SSE_EXCEPTIONS, initMatrix_identity, initMatrix_random, BenchTimer, cerr
from basicbenchmark import LazyEval, EarlyEval, OmpEval, benchBasic, benchBasic_loop
from io import print as cpp_std_cout  # to mimic cout, but we'll use print directly
from memory import stack_allocation

def main() -> Int32:
    DISABLE_SSE_EXCEPTIONS()
    # define MODES as a sequence of tuples (type_str, size, iterations)
    # original MODES: ((3d)(3)(4000000)) ((4d)(4)(1000000)) ((Xd)(4)(1000000)) ((Xd)(20)(10000))
    alias MODES = [("3d", 3, 4000000), ("4d", 4, 1000000), ("Xd", 4, 1000000), ("Xd", 20, 10000)]
    # print header (replicate _GENERATE_HEADER expansion)
    for each in MODES:
        var type_str = each[0]
        var size = each[1]
        print(type_str, "-", str(size), "x", str(size), "   /   ", end="")
    print()  # endl
    const tries = 10

    # _RUN_BENCH with LazyEval
    for each in MODES:
        var type_str = each[0]
        var size = each[1]
        var iterations = each[2]
        # construct matrix of appropriate type
        var mat: ...  # placeholder, we need to instantiate based on type_str
        if type_str == "3d":
            var m3 = Matrix3d(size, size)
            var I3 = Matrix3d(size, size)
            initMatrix_identity(I3)
            initMatrix_random(m3)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[LazyEval, Matrix3d](I3, m3, iterations)
            timer.stop()
            cerr(m3)
            print(timer.value, end="   ")
        elif type_str == "4d":
            var m4 = Matrix4d(size, size)
            var I4 = Matrix4d(size, size)
            initMatrix_identity(I4)
            initMatrix_random(m4)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[LazyEval, Matrix4d](I4, m4, iterations)
            timer.stop()
            cerr(m4)
            print(timer.value, end="   ")
        elif type_str == "Xd":
            var mX = MatrixXd(size, size)
            var IX = MatrixXd(size, size)
            initMatrix_identity(IX)
            initMatrix_random(mX)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[LazyEval, MatrixXd](IX, mX, iterations)
            timer.stop()
            cerr(mX)
            print(timer.value, end="   ")
    print()

    # _RUN_BENCH with EarlyEval
    for each in MODES:
        var type_str = each[0]
        var size = each[1]
        var iterations = each[2]
        if type_str == "3d":
            var m3 = Matrix3d(size, size)
            var I3 = Matrix3d(size, size)
            initMatrix_identity(I3)
            initMatrix_random(m3)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[EarlyEval, Matrix3d](I3, m3, iterations)
            timer.stop()
            cerr(m3)
            print(timer.value, end="   ")
        elif type_str == "4d":
            var m4 = Matrix4d(size, size)
            var I4 = Matrix4d(size, size)
            initMatrix_identity(I4)
            initMatrix_random(m4)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[EarlyEval, Matrix4d](I4, m4, iterations)
            timer.stop()
            cerr(m4)
            print(timer.value, end="   ")
        elif type_str == "Xd":
            var mX = MatrixXd(size, size)
            var IX = MatrixXd(size, size)
            initMatrix_identity(IX)
            initMatrix_random(mX)
            var timer = BenchTimer()
            timer.start()
            benchBasic_loop[EarlyEval, MatrixXd](IX, mX, iterations)
            timer.stop()
            cerr(mX)
            print(timer.value, end="   ")
    print()
    return 0