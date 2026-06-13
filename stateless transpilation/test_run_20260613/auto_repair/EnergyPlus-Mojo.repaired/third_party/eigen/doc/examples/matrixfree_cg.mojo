from Eigen.Core import *
from Eigen.Dense import *
from Eigen.IterativeLinearSolvers import *
from unsupported.Eigen.IterativeSolvers import *

class MatrixReplacement(Eigen.EigenBase[MatrixReplacement]):
    alias Scalar = Float64
    alias RealScalar = Float64
    alias StorageIndex = Int32
    enum ColsAtCompileTime: Eigen.Dynamic
    enum MaxColsAtCompileTime: Eigen.Dynamic
    enum IsRowMajor: False

    def rows(self) -> Index:
        return self.mp_mat.rows()

    def cols(self) -> Index:
        return self.mp_mat.cols()

    def __mul__(self, x: Eigen.MatrixBase[Rhs]) -> Eigen.Product[MatrixReplacement, Rhs, Eigen.AliasFreeProduct]:
        return Eigen.Product[MatrixReplacement, Rhs, Eigen.AliasFreeProduct](self, x.derived())

    def __init__(self):
        self.mp_mat = None

    def attachMyMatrix(self, mat: SparseMatrix[Float64]):
        self.mp_mat = mat

    def my_matrix(self) -> SparseMatrix[Float64]:
        return *self.mp_mat

    var mp_mat: SparseMatrix[Float64]*

namespace Eigen:
    namespace internal:
        struct traits[MatrixReplacement](
            Eigen.internal.traits[Eigen.SparseMatrix[Float64]]
        ):

namespace Eigen:
    namespace internal:
        struct generic_product_impl[MatrixReplacement, Rhs, SparseShape, DenseShape, GemvProduct]:
            alias Scalar = Float64
            def scaleAndAddTo[Dest](dst: Dest, lhs: MatrixReplacement, rhs: Rhs, alpha: Scalar):
                assert(alpha == Scalar(1), "scaling is not implemented")
                for i in range(lhs.cols()):
                    dst += rhs(i) * lhs.my_matrix().col(i)

def main():
    let n: Int32 = 10
    var S: SparseMatrix[Float64] = Eigen.MatrixXd.Random(n, n).sparseView(0.5, 1)
    S = S.transpose() * S
    var A: MatrixReplacement
    A.attachMyMatrix(S)
    var b: Eigen.VectorXd(n)
    var x: Eigen.VectorXd
    b.setRandom()

    {
        var cg: Eigen.ConjugateGradient[MatrixReplacement, Eigen.Lower | Eigen.Upper, Eigen.IdentityPreconditioner]
        cg.compute(A)
        x = cg.solve(b)
        print("CG:       #iterations: " + string(cg.iterations()) + ", estimated error: " + string(cg.error()))
    }
    {
        var bicg: Eigen.BiCGSTAB[MatrixReplacement, Eigen.IdentityPreconditioner]
        bicg.compute(A)
        x = bicg.solve(b)
        print("BiCGSTAB: #iterations: " + string(bicg.iterations()) + ", estimated error: " + string(bicg.error()))
    }
    {
        var gmres: Eigen.GMRES[MatrixReplacement, Eigen.IdentityPreconditioner]
        gmres.compute(A)
        x = gmres.solve(b)
        print("GMRES:    #iterations: " + string(gmres.iterations()) + ", estimated error: " + string(gmres.error()))
    }
    {
        var gmres_d: Eigen.DGMRES[MatrixReplacement, Eigen.IdentityPreconditioner]
        gmres_d.compute(A)
        x = gmres_d.solve(b)
        print("DGMRES:   #iterations: " + string(gmres_d.iterations()) + ", estimated error: " + string(gmres_d.error()))
    }
    {
        var minres: Eigen.MINRES[MatrixReplacement, Eigen.Lower | Eigen.Upper, Eigen.IdentityPreconditioner]
        minres.compute(A)
        x = minres.solve(b)
        print("MINRES:   #iterations: " + string(minres.iterations()) + ", estimated error: " + string(minres.error()))
    }