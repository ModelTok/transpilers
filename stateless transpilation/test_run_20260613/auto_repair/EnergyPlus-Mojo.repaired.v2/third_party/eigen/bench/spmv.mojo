alias SCALAR = Float64

from sys import args, print
from BenchTimer import BenchTimer
from BenchSparseUtil import EigenSparseMatrix, DenseVector, DenseMatrix, fillMatrix2, eiToDense, eiToCSparse, eiToUblas, eiToGmm, eiToMtl
from oski import oski_matrix_t, oski_vecview_t, oski_Init, oski_CreateMatCSC, oski_CreateVecView, oski_MatMult, oski_SetHintMatMult, oski_TuneMat, oski_DestroyMat, oski_DestroyVecView, oski_Close
from boost.numeric import ublas
from gmm import gmm
from mtl import mtl

# Helper function to replace BENCH macro
def BENCH(t: BenchTimer, tries: Int, repeats: Int, code: fn() -> None):
    t.bench(tries, repeats, code)

# Parameter flags to simulate compile-time defines
@parameter
const DENSEMATRIX = False    // Define this to 1 to enable Dense block
@parameter
const CSPARSE = False       // Define this to 1 to enable CSparse block
@parameter
const OSKI = False          // Define this to 1 to enable OSKI block
@parameter
const NOUBLAS = False       // Define this to 0 to enable ublas block (inverted logic)
@parameter
const NOGMM = False         // Define this to 0 to enable GMM++ block
@parameter
const NOMTL = False         // Define this to 0 to enable MTL4 block

def main():
    var size = 10000
    var rows = size
    var cols = size
    var nnzPerCol = 40
    var tries = 2
    var repeats = 2
    var need_help = False
    var i = 1
    while i < len(args):
        if args[i][0] == 'r':
            rows = int(args[i][1:])
        elif args[i][0] == 'c':
            cols = int(args[i][1:])
        elif args[i][0] == 'n':
            nnzPerCol = int(args[i][1:])
        elif args[i][0] == 't':
            tries = int(args[i][1:])
        elif args[i][0] == 'p':
            repeats = int(args[i][1:])
        else:
            need_help = True
        i += 1
    if need_help:
        print(args[0] + " r<nb rows> c<nb columns> n<non zeros per column> t<nb tries> p<nb repeats>")
        return 1
    print("SpMV " + str(rows) + " x " + str(cols) + " with " + str(nnzPerCol) + " non zeros per column. (" + str(repeats) + " repeats, and " + str(tries) + " tries)\n")
    var sm = EigenSparseMatrix(rows, cols)
    var dv = DenseVector(cols)
    var res = DenseVector(rows)
    dv.setRandom()
    var t = BenchTimer()
    while nnzPerCol >= 4:
        print("nnz: " + str(nnzPerCol) + "\n")
        sm.setZero()
        fillMatrix2(nnzPerCol, rows, cols, sm)
        @parameter
        if DENSEMATRIX:
            # Original: DenseMatrix dm(rows,cols), (rows,cols);
            # Keeping as two separate declarations (original had syntax error)
            var dm = DenseMatrix(rows, cols)
            var dm2 = DenseMatrix(rows, cols)   # second variable name added for clarity, original used unnamed
            eiToDense(sm, dm)
            BENCH(t, tries, repeats, fn() => res.noalias() = dm * sm)
            print("Dense       " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => res.noalias() = dm.transpose() * sm)
            print(str(t.value() / repeats) + "\n")
        # End DENSEMATRIX
        {
            BENCH(t, tries, repeats, fn() => res.noalias() += sm * dv)
            print("Eigen       " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => res.noalias() += sm.transpose() * dv)
            print(str(t.value() / repeats) + "\n")
        }
        @parameter
        if CSPARSE:
            print("CSparse \n")
            var csm: cs_ptr   # assuming cs_ptr is defined
            eiToCSparse(sm, csm)
        # End CSPARSE
        @parameter
        if OSKI:
            var om: oski_matrix_t
            var ov: oski_vecview_t
            var ores: oski_vecview_t
            oski_Init()
            om = oski_CreateMatCSC(sm._outerIndexPtr(), sm._innerIndexPtr(), sm._valuePtr(), rows, cols,
                                   SHARE_INPUTMAT, 1, INDEX_ZERO_BASED)
            ov = oski_CreateVecView(dv.data(), cols, STRIDE_UNIT)
            ores = oski_CreateVecView(res.data(), rows, STRIDE_UNIT)
            BENCH(t, tries, repeats, fn() => oski_MatMult(om, OP_NORMAL, 1, ov, 0, ores))
            print("OSKI        " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => oski_MatMult(om, OP_TRANS, 1, ov, 0, ores))
            print(str(t.value() / repeats) + "\n")
            t.reset()
            t.start()
            oski_SetHintMatMult(om, OP_NORMAL, 1.0, SYMBOLIC_VEC, 0.0, SYMBOLIC_VEC, ALWAYS_TUNE_AGGRESSIVELY)
            oski_TuneMat(om)
            t.stop()
            var tuning = t.value()
            BENCH(t, tries, repeats, fn() => oski_MatMult(om, OP_NORMAL, 1, ov, 0, ores))
            print("OSKI tuned  " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => oski_MatMult(om, OP_TRANS, 1, ov, 0, ores))
            print(str(t.value() / repeats) + "\t(" + str(tuning) +  ")\n")
            oski_DestroyMat(om)
            oski_DestroyVecView(ov)
            oski_DestroyVecView(ores)
            oski_Close()
        # End OSKI
        @parameter
        if not NOUBLAS:
            # using namespace boost::numeric;   // replaced with ublas
            var um = ublas.compressed_matrix[SCALAR](rows, cols)
            eiToUblas(sm, um)
            var uv = ublas.vector[SCALAR](cols)
            var ures = ublas.vector[SCALAR](rows)
            # Map<Matrix<Scalar,Dynamic,1> >(&uv[0], cols) = dv;  // assume dv data can be copied
            # Not directly translatable, assume we can assign from dv
            BENCH(t, tries, repeats, fn() => ublas.axpy_prod(um, uv, ures, True))
            print("ublas       " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => ublas.axpy_prod(ublas.trans(um), uv, ures, True))
            print(str(t.value() / repeats) + "\n")
        # End NOUBLAS
        @parameter
        if not NOGMM:
            var gm = gmm.compressed_matrix[SCALAR](rows, cols)
            eiToGmm(sm, gm)
            var gv = gmm.std_vector[SCALAR](cols)
            var gres = gmm.std_vector[SCALAR](rows)
            # Map<Matrix<Scalar,Dynamic,1> >(&gv[0], cols) = dv; // assume
            BENCH(t, tries, repeats, fn() => gmm.mult(gm, gv, gres))
            print("GMM++       " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => gmm.mult(gmm.transposed(gm), gv, gres))
            print(str(t.value() / repeats) + "\n")
        # End NOGMM
        @parameter
        if not NOMTL:
            var mm = mtl.compressed_matrix[SCALAR](rows, cols)
            eiToMtl(sm, mm)
            var mv = mtl.dense_vector[SCALAR](cols, 1.0)
            var mres = mtl.dense_vector[SCALAR](rows, 1.0)
            BENCH(t, tries, repeats, fn() => mres = mm * mv)
            print("MTL4        " + str(t.value() / repeats) + "\t")
            BENCH(t, tries, repeats, fn() => mres = trans(mm) * mv)
            print(str(t.value() / repeats) + "\n")
        # End NOMTL
        print("\n")
        if nnzPerCol == 1:
            break
        nnzPerCol = nnzPerCol - int(nnzPerCol / 2)
    return 0