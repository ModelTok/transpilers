// Converted from third_party/eigen/bench/geometry.cpp

from ...Eigen.Geometry import (
    Matrix, Transform, NumTraits, Quaternion, Isometry, Affine, AffineCompact, Projective, Dynamic
)
from ...bench.BenchTimer import BenchTimer

// using namespace std;
// using namespace Eigen;

// #ifndef SCALAR
// #define SCALAR float
// #endif
alias SCALAR = Float32
// #define SIZE 8
alias SIZE = 8

type Scalar = SCALAR
type RealScalar = NumTraits[Scalar].Real
type A = Matrix[RealScalar, Dynamic, Dynamic]
type B = Matrix[Scalar, Dynamic, Dynamic]
type C = Matrix[Scalar, Dynamic, Dynamic]
type M = Matrix[RealScalar, Dynamic, Dynamic]

@inline(never)
def transform[Transformation: AnyType, Data: AnyType](t: Transformation, ref data: Data):
    // EIGEN_ASM_COMMENT("begin")
    data = t * data
    // EIGEN_ASM_COMMENT("end")

@inline(never)
def transform[Scalar: AnyType, Data: AnyType](t: Quaternion[Scalar], ref data: Data):
    // EIGEN_ASM_COMMENT("begin quat")
    for i in range(data.cols()):
        data.col(i) = t * data.col(i)
    // EIGEN_ASM_COMMENT("end quat")

struct ToRotationMatrixWrapper[T: AnyType]:
    // enum {Dim = T::Dim}
    static let Dim: Int = T.Dim
    type Scalar = T.Scalar
    var object: T

    def __init__(out self, o: T):
        self.object = o

@inline(never)
def transform[QType: AnyType, Data: AnyType](t: ToRotationMatrixWrapper[QType], ref data: Data):
    // EIGEN_ASM_COMMENT("begin quat via mat")
    data = t.object.toRotationMatrix() * data
    // EIGEN_ASM_COMMENT("end quat via mat")

@inline(never)
def transform[Scalar: AnyType, Dim: Int, Data: AnyType](t: Transform[Scalar, Dim, Projective], ref data: Data):
    data = (t * data.colwise().homogeneous()).template block[Dim, Data.ColsAtCompileTime](0, 0)

struct get_dim[T: AnyType]:
    static let Dim: Int = T.Dim

struct get_dim[Matrix[S, R, C, O, MR, MC]]:
    static let Dim: Int = R

struct bench_impl[Transformation: AnyType, N: Int]:
    @staticmethod
    @inline(never)
    def run(t: Transformation):
        var data = Matrix[Transformation.Scalar, get_dim[Transformation].Dim, N]()
        data.setRandom()
        bench_impl[Transformation, N - 1].run(t)
        var timer = BenchTimer()
        // BENCH(timer, 10, 100000, transform(t, data))
        // Placeholder: the macro is not available, so we just call transform once.
        transform(t, data)
        var best_time: Float64 = 0.0
        best_time = timer.best()
        // cout.width(9)
        print(best_time.str().rjust(9), end=" ")

struct bench_impl[Transformation: AnyType, 0]:
    @staticmethod
    @inline(never)
    def run(t: Transformation):

@inline(never)
def bench[Transformation: AnyType](msg: String, t: Transformation):
    print(msg, end=" ")
    bench_impl[Transformation, SIZE].run(t)
    print()

def main() raises:
    var mat34 = Matrix[Scalar, 3, 4]()
    mat34.setRandom()
    var iso3 = Transform[Scalar, 3, Isometry](mat34)
    var aff3 = Transform[Scalar, 3, Affine](mat34)
    var caff3 = Transform[Scalar, 3, AffineCompact](mat34)
    var proj3 = Transform[Scalar, 3, Projective](mat34)
    var quat = Quaternion[Scalar]()
    quat.setIdentity()
    var quatmat = ToRotationMatrixWrapper[Quaternion[Scalar]](quat)
    var mat33 = Matrix[Scalar, 3, 3]()
    mat33.setRandom()
    // cout.precision(4)
    print("N          ", end="")
    for i in range(SIZE):
        // cout.width(9)
        print((i + 1).str().rjust(9), end=" ")
    print()
    bench[Matrix[Scalar, 3, 3]]("matrix 3x3", mat33)
    bench[Quaternion[Scalar]]("quaternion", quat)
    bench[ToRotationMatrixWrapper[Quaternion[Scalar]]]("quat-mat  ", quatmat)
    bench[Transform[Scalar, 3, Isometry]]("isometry3 ", iso3)
    bench[Transform[Scalar, 3, Affine]]("affine3   ", aff3)
    bench[Transform[Scalar, 3, AffineCompact]]("c affine3 ", caff3)
    bench[Transform[Scalar, 3, Projective]]("proj3     ", proj3)