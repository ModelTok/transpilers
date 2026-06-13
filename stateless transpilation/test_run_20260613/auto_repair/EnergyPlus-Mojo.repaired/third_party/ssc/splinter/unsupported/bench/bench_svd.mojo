from bench.BenchTimer import BenchTimer
from unsupported.Eigen.SVD import BDCSVD, JacobiSVD, Matrix, Dynamic, ComputeFullU, ComputeFullV

alias REPEAT = 10
alias NUMBER_SAMPLE = 2

def bench_svd[MatrixType: AnyType](a: MatrixType = MatrixType()):
    var m = MatrixType.random(a.rows(), a.cols())
    var timerJacobi = BenchTimer()
    var timerBDC = BenchTimer()
    timerJacobi.reset()
    timerBDC.reset()
    print(" Only compute Singular Values")
    for k in range(1, NUMBER_SAMPLE + 1):
        timerBDC.start()
        for i in range(REPEAT):
            var bdc_matrix = BDCSVD[MatrixType](m)
        timerBDC.stop()
        timerJacobi.start()
        for i in range(REPEAT):
            var jacobi_matrix = JacobiSVD[MatrixType](m)
        timerJacobi.stop()
        print("Sample ", k, " : ", REPEAT, " computations :  Jacobi : ", timerJacobi.value(), "s ", end="")
        print(" || ", " BDC : ", timerBDC.value(), "s ", end="")
        print()
        print()
        if timerBDC.value() >= timerJacobi.value():
            print("KO : BDC is ", timerJacobi.value() / timerBDC.value(), "  times faster than Jacobi")
        else:
            print("OK : BDC is ", timerJacobi.value() / timerBDC.value(), "  times faster than Jacobi")
    print("       =================")
    print()
    timerJacobi.reset()
    timerBDC.reset()
    print(" Computes rotaion matrix")
    for k in range(1, NUMBER_SAMPLE + 1):
        timerBDC.start()
        for i in range(REPEAT):
            var bdc_matrix = BDCSVD[MatrixType](m, ComputeFullU | ComputeFullV)
        timerBDC.stop()
        timerJacobi.start()
        for i in range(REPEAT):
            var jacobi_matrix = JacobiSVD[MatrixType](m, ComputeFullU | ComputeFullV)
        timerJacobi.stop()
        print("Sample ", k, " : ", REPEAT, " computations :  Jacobi : ", timerJacobi.value(), "s ", end="")
        print(" || ", " BDC : ", timerBDC.value(), "s ", end="")
        print()
        print()
        if timerBDC.value() >= timerJacobi.value():
            print("KO : BDC is ", timerJacobi.value() / timerBDC.value(), "  times faster than Jacobi")
        else:
            print("OK : BDC is ", timerJacobi.value() / timerBDC.value(), "  times faster than Jacobi")
    print()

def main():
    print()
    print("On a (Dynamic, Dynamic) (6, 6) Matrix")
    bench_svd[Matrix[Float64, Dynamic, Dynamic]](Matrix[Float64, Dynamic, Dynamic](6, 6))
    print("On a (Dynamic, Dynamic) (32, 32) Matrix")
    bench_svd[Matrix[Float64, Dynamic, Dynamic]](Matrix[Float64, Dynamic, Dynamic](32, 32))
    print("On a (Dynamic, Dynamic) (160, 160) Matrix")
    bench_svd[Matrix[Float64, Dynamic, Dynamic]](Matrix[Float64, Dynamic, Dynamic](160, 160))
    print("--------------------------------------------------------------------")