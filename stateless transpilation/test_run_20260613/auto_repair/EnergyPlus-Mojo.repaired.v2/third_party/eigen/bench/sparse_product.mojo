from typeinfo import typeinfo
from algorithm import algorithm
from BenchTimer import BenchTimer
from BenchUtil import BenchUtil
from BenchSparseUtil import BenchSparseUtil

# ifndef SIZE
# define SIZE 1000000
# endif
# ifndef NNZPERCOL
# define NNZPERCOL 6
# endif
# ifndef REPEAT
# define REPEAT 1
# endif
# ifndef NBTRIES
# define NBTRIES 1
# endif

# define BENCH(X) \
#   timer.reset(); \
#   for (int _j=0; _j<NBTRIES; ++_j) { \
#     timer.start(); \
#     for (int _k=0; _k<REPEAT; ++_k) { \
#         X  \
#   } timer.stop(); }

# ifdef CSPARSE
def cs_sorted_multiply(a: cs, b: cs) -> cs:
    var A: cs = cs_transpose(a, 1)
    var B: cs = cs_transpose(b, 1)
    var D: cs = cs_multiply(B, A)   # D = B'*A'
    cs_spfree(A)
    cs_spfree(B)
    cs_dropzeros(D)      # drop zeros from D
    var C: cs = cs_transpose(D, 1)   # C = D', so that C is sorted
    cs_spfree(D)
    return C

def cs_sorted_multiply2(a: cs, b: cs) -> cs:
    var D: cs = cs_multiply(a, b)
    var E: cs = cs_transpose(D, 1)
    cs_spfree(D)
    var C: cs = cs_transpose(E, 1)
    cs_spfree(E)
    return C
# endif

def bench_sort():

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    var rows: Int = SIZE
    var cols: Int = SIZE
    var density: Float32 = DENSITY
    var sm1: EigenSparseMatrix = EigenSparseMatrix(rows, cols)
    var sm2: EigenSparseMatrix = EigenSparseMatrix(rows, cols)
    var sm3: EigenSparseMatrix = EigenSparseMatrix(rows, cols)
    var sm4: EigenSparseMatrix = EigenSparseMatrix(rows, cols)
    var timer: BenchTimer = BenchTimer()
    var nnzPerCol: Int = NNZPERCOL
    while nnzPerCol > 1:
        sm1.setZero()
        sm2.setZero()
        fillMatrix2(nnzPerCol, rows, cols, sm1)
        fillMatrix2(nnzPerCol, rows, cols, sm2)
        # ifdef DENSEMATRIX
        # {
        #   cout << "Eigen Dense\t" << nnzPerCol << "%\n";
        #   DenseMatrix m1(rows,cols), m2(rows,cols), m3(rows,cols);
        #   eiToDense(sm1, m1);
        #   eiToDense(sm2, m2);
        #   timer.reset();
        #   timer.start();
        #   for (int k=0; k<REPEAT; ++k)
        #     m3 = m1 * m2;
        #   timer.stop();
        #   cout << "   a * b:\t" << timer.value() << endl;
        #   timer.reset();
        #   timer.start();
        #   for (int k=0; k<REPEAT; ++k)
        #     m3 = m1.transpose() * m2;
        #   timer.stop();
        #   cout << "   a' * b:\t" << timer.value() << endl;
        #   timer.reset();
        #   timer.start();
        #   for (int k=0; k<REPEAT; ++k)
        #     m3 = m1.transpose() * m2.transpose();
        #   timer.stop();
        #   cout << "   a' * b':\t" << timer.value() << endl;
        #   timer.reset();
        #   timer.start();
        #   for (int k=0; k<REPEAT; ++k)
        #     m3 = m1 * m2.transpose();
        #   timer.stop();
        #   cout << "   a * b':\t" << timer.value() << endl;
        # }
        # endif
        # {
        #   cout << "Eigen sparse\t" << sm1.nonZeros()/(float(sm1.rows())*float(sm1.cols()))*100 << "% * "
        #             << sm2.nonZeros()/(float(sm2.rows())*float(sm2.cols()))*100 << "%\n";
        #   BENCH(sm3 = sm1 * sm2; )
        #   cout << "   a * b:\t" << timer.value() << endl;
        # }
        # /*{
        #   DynamicSparseMatrix<Scalar> m1(sm1), m2(sm2), m3(sm3);
        #   cout << "Eigen dyn-sparse\t" << m1.nonZeros()/(float(m1.rows())*float(m1.cols()))*100 << "% * "
        #             << m2.nonZeros()/(float(m2.rows())*float(m2.cols()))*100 << "%\n";
        #   BENCH(for (int k=0; k<REPEAT; ++k) m3 = m1 * m2;)
        #   cout << "   a * b:\t" << timer.value() << endl;
        #   timer.reset();
        #   timer.start();
        #   BENCH(for (int k=0; k<REPEAT; ++k) m3 = m1.transpose() * m2;)
        #   cout << "   a' * b:\t" << timer.value() << endl;
        #   BENCH( for (int k=0; k<REPEAT; ++k) m3 = m1.transpose() * m2.transpose(); )
        #   cout << "   a' * b':\t" << timer.value() << endl;
        #   BENCH( for (int k=0; k<REPEAT; ++k) m3 = m1 * m2.transpose(); )
        #   cout << "   a * b' :\t" << timer.value() << endl;
        # }*/
        # ifdef CSPARSE
        # {
        #   cout << "CSparse \t" << nnzPerCol << "%\n";
        #   cs *m1, *m2, *m3;
        #   eiToCSparse(sm1, m1);
        #   eiToCSparse(sm2, m2);
        #   BENCH(
        #   {
        #     m3 = cs_sorted_multiply(m1, m2);
        #     if (!m3)
        #     {
        #       cerr << "cs_multiply failed\n";
        #     }
        #     cs_spfree(m3);
        #   }
        #   );
        #   cout << "   a * b:\t" << timer.value() << endl;
        # }
        # endif
        # ifndef NOUBLAS
        # {
        #   cout << "ublas\t" << nnzPerCol << "%\n";
        #   UBlasSparse m1(rows,cols), m2(rows,cols), m3(rows,cols);
        #   eiToUblas(sm1, m1);
        #   eiToUblas(sm2, m2);
        #   BENCH(boost::numeric::ublas::prod(m1, m2, m3););
        #   cout << "   a * b:\t" << timer.value() << endl;
        # }
        # endif
        # ifndef NOGMM
        # {
        #   cout << "GMM++ sparse\t" << nnzPerCol << "%\n";
        #   GmmDynSparse  gmmT3(rows,cols);
        #   GmmSparse m1(rows,cols), m2(rows,cols), m3(rows,cols);
        #   eiToGmm(sm1, m1);
        #   eiToGmm(sm2, m2);
        #   BENCH(gmm::mult(m1, m2, gmmT3););
        #   cout << "   a * b:\t" << timer.value() << endl;
        # }
        # endif
        # ifndef NOMTL
        # {
        #   cout << "MTL4\t" << nnzPerCol << "%\n";
        #   MtlSparse m1(rows,cols), m2(rows,cols), m3(rows,cols);
        #   eiToMtl(sm1, m1);
        #   eiToMtl(sm2, m2);
        #   BENCH(m3 = m1 * m2;);
        #   cout << "   a * b:\t" << timer.value() << endl;
        # }
        # endif
        print("\n\n")
        nnzPerCol = int(nnzPerCol / 1.1)
    return 0