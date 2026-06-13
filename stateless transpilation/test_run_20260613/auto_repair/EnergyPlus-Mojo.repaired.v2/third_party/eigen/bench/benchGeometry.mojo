from Eigen import Transform, Matrix, Isometry, Projective, AutoAlign, DontAlign
from time import time as bench_time

alias REPEAT = 1000000

enum func_opt:
    TV = 0
    TMATV = 1
    TMATVMAT = 2

struct func[res: Type, arg1: Type, arg2: Type, opt: Int]:
    @staticmethod
    def run(a1: arg1, a2: arg2) -> res:
        asm("")
        if opt == func_opt.TV:
            return a1 * a2
        elif opt == func_opt.TMATV:
            return a1.matrix() * a2
        elif opt == func_opt.TMATVMAT:
            return res(a1.matrix() * a2.matrix())
        else:
            return res()

struct BenchTimer:
    var _start: Float64
    var _stop: Float64
    var _elapsed: Float64

    def __init__(inout self):
        self._start = 0.0
        self._stop = 0.0
        self._elapsed = 0.0

    def reset(inout self):
        self._start = 0.0
        self._stop = 0.0
        self._elapsed = 0.0

    def start(inout self):
        self._start = bench_time()

    def stop(inout self):
        self._stop = bench_time()
        self._elapsed += self._stop - self._start

    def value(self) -> Float64:
        return self._elapsed

struct test_transform[func: Type, arg1: Type, arg2: Type]:
    @staticmethod
    def run():
        var a1: arg1
        a1.setIdentity()
        var a2: arg2
        a2.setIdentity()
        var timer = BenchTimer()
        timer.reset()
        for k in range(10):
            timer.start()
            for kk in range(REPEAT):
                a2 = func.run(a1, a2)
            timer.stop()
        print(String(format("{:.4f}s", timer.value())))

def run_vec(op: Int, scalar: type, mode: type, option: type, vsize: Int):
    var scalar_name = "float" if scalar == Float32 else "double"
    print(scalar_name + "\t " + str(mode) + "\t " + str(option) + " " + str(vsize))
    alias Trans = Transform[scalar, 3, mode, option]
    alias Vec = Matrix[scalar, vsize, 1, option]
    alias Func = func[Vec, Trans, Vec, op]
    test_transform[Func, Trans, Vec].run()

def run_trans(op: Int, scalar: type, mode: type, option: type):
    var scalar_name = "float" if scalar == Float32 else "double"
    print(scalar_name + "\t " + str(mode) + "\t " + str(option))
    alias Trans = Transform[scalar, 3, mode, option]
    alias Func = func[Trans, Trans, Trans, op]
    test_transform[Func, Trans, Trans].run()

def main(argv: List[String]) raises:
    print("vec = trans * vec")
    run_vec(func_opt.TV, Float32, Isometry, AutoAlign, 3)
    run_vec(func_opt.TV, Float32, Isometry, DontAlign, 3)
    run_vec(func_opt.TV, Float32, Isometry, AutoAlign, 4)
    run_vec(func_opt.TV, Float32, Isometry, DontAlign, 4)
    run_vec(func_opt.TV, Float32, Projective, AutoAlign, 4)
    run_vec(func_opt.TV, Float32, Projective, DontAlign, 4)
    run_vec(func_opt.TV, Float64, Isometry, AutoAlign, 3)
    run_vec(func_opt.TV, Float64, Isometry, DontAlign, 3)
    run_vec(func_opt.TV, Float64, Isometry, AutoAlign, 4)
    run_vec(func_opt.TV, Float64, Isometry, DontAlign, 4)
    run_vec(func_opt.TV, Float64, Projective, AutoAlign, 4)
    run_vec(func_opt.TV, Float64, Projective, DontAlign, 4)
    print("vec = trans.matrix() * vec")
    run_vec(func_opt.TMATV, Float32, Isometry, AutoAlign, 4)
    run_vec(func_opt.TMATV, Float32, Isometry, DontAlign, 4)
    run_vec(func_opt.TMATV, Float64, Isometry, AutoAlign, 4)
    run_vec(func_opt.TMATV, Float64, Isometry, DontAlign, 4)
    print("trans = trans1 * trans")
    run_trans(func_opt.TV, Float32, Isometry, AutoAlign)
    run_trans(func_opt.TV, Float32, Isometry, DontAlign)
    run_trans(func_opt.TV, Float64, Isometry, AutoAlign)
    run_trans(func_opt.TV, Float64, Isometry, DontAlign)
    run_trans(func_opt.TV, Float32, Projective, AutoAlign)
    run_trans(func_opt.TV, Float32, Projective, DontAlign)
    run_trans(func_opt.TV, Float64, Projective, AutoAlign)
    run_trans(func_opt.TV, Float64, Projective, DontAlign)
    print("trans = trans1.matrix() * trans.matrix()")
    run_trans(func_opt.TMATVMAT, Float32, Isometry, AutoAlign)
    run_trans(func_opt.TMATVMAT, Float32, Isometry, DontAlign)
    run_trans(func_opt.TMATVMAT, Float64, Isometry, AutoAlign)
    run_trans(func_opt.TMATVMAT, Float64, Isometry, DontAlign)