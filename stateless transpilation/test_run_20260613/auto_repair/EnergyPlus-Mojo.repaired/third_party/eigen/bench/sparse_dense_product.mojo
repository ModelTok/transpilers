# ifndef SIZE
# define SIZE 650000
# endif
# ifndef DENSITY
# define DENSITY 0.01
# endif
# ifndef REPEAT
# define REPEAT 1
# endif
# include "BenchSparseUtil.h"
# ifndef MINDENSITY
# define MINDENSITY 0.0004
# endif
# ifndef NBTRIES
# define NBTRIES 10
# endif
# define BENCH(X) \
  timer.reset(); \
  for (int _j=0; _j<NBTRIES; ++_j) { \
    timer.start(); \
    for (int _k=0; _k<REPEAT; ++_k) { \
        X  \
  } timer.stop(); }
# ifdef CSPARSE
cs* cs_sorted_multiply(cs* a , cs* b )
{
  cs* A = cs_transpose (a, 1) ;
  cs* B = cs_transpose (b, 1) ;
  cs* D = cs_multiply (B,A) ;   /* D = B'*A' */
  cs_spfree (A) ;
  cs_spfree (B) ;
  cs_dropzeros (D) ;      /* drop zeros from D */
  cs* C = cs_transpose (D, 1) ;   /* C = D', so that C is sorted */
  cs_spfree (D) ;
  return C;
}
# endif
def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
  var rows: Int = SIZE
  var cols: Int = SIZE
  var density: Float32 = DENSITY
  var sm1: EigenSparseMatrix = EigenSparseMatrix(rows,cols)
  var v1: DenseVector = DenseVector(cols)
  var v2: DenseVector = DenseVector(cols)
  v1.setRandom()
  var timer: BenchTimer = BenchTimer()
  for density in range(DENSITY, MINDENSITY, 0.5):
  {
    fillMatrix2(7, rows, cols, sm1)
    # ifdef DENSEMATRIX
    {
      print("Eigen Dense\t", density*100, "%")
      var m1: DenseMatrix = DenseMatrix(rows,cols)
      eiToDense(sm1, m1)
      timer.reset()
      timer.start()
      for k in range(0, REPEAT):
        v2 = m1 * v1
      timer.stop()
      print("   a * v:\t", timer.best(), "  ", double(REPEAT)/timer.best(), " * / sec ", endl)
      timer.reset()
      timer.start()
      for k in range(0, REPEAT):
        v2 = m1.transpose() * v1
      timer.stop()
      print("   a' * v:\t", timer.best())
    }
    # endif
    {
      print("Eigen sparse\t", sm1.nonZeros()/float(sm1.rows()*sm1.cols())*100, "%")
      BENCH(asm("#myc"); v2 = sm1 * v1; asm("#myd");)
      print("   a * v:\t", timer.best()/REPEAT, "  ", double(REPEAT)/timer.best(REAL_TIMER), " * / sec ", endl)
      BENCH( { asm("#mya"); v2 = sm1.transpose() * v1; asm("#myb"); })
      print("   a' * v:\t", timer.best()/REPEAT)
    }
    # ifndef NOGMM
    {
      print("GMM++ sparse\t", density*100, "%")
      var m1: GmmSparse = GmmSparse(rows,cols)
      eiToGmm(sm1, m1)
      var gmmV1: std.vector[Scalar] = std.vector[Scalar](cols)
      var gmmV2: std.vector[Scalar] = std.vector[Scalar](cols)
      Map[Matrix[Scalar,Dynamic,1]](&gmmV1[0], cols) = v1
      Map[Matrix[Scalar,Dynamic,1]](&gmmV2[0], cols) = v2
      BENCH( asm("#myx"); gmm::mult(m1, gmmV1, gmmV2); asm("#myy"); )
      print("   a * v:\t", timer.value())
      BENCH( gmm::mult(gmm::transposed(m1), gmmV1, gmmV2); )
      print("   a' * v:\t", timer.value())
    }
    # endif
    # ifndef NOUBLAS
    {
      print("ublas sparse\t", density*100, "%")
      var m1: UBlasSparse = UBlasSparse(rows,cols)
      eiToUblas(sm1, m1)
      var uv1: boost.numeric.ublas.vector[Scalar]
      var uv2: boost.numeric.ublas.vector[Scalar]
      eiToUblasVec(v1,uv1)
      eiToUblasVec(v2,uv2)
      BENCH( uv2 = boost.numeric.ublas.prod(m1, uv1); )
      print("   a * v:\t", timer.value())
    }
    # endif
    # ifndef NOMTL
    {
      print("MTL4\t", density*100, "%")
      var m1: MtlSparse = MtlSparse(rows,cols)
      eiToMtl(sm1, m1)
      var mtlV1: mtl.dense_vector[Scalar] = mtl.dense_vector[Scalar](cols, 1.0)
      var mtlV2: mtl.dense_vector[Scalar] = mtl.dense_vector[Scalar](cols, 1.0)
      timer.reset()
      timer.start()
      for k in range(0, REPEAT):
        mtlV2 = m1 * mtlV1
      timer.stop()
      print("   a * v:\t", timer.value())
      timer.reset()
      timer.start()
      for k in range(0, REPEAT):
        mtlV2 = trans(m1) * mtlV1
      timer.stop()
      print("   a' * v:\t", timer.value())
    }
    # endif
    print("\n\n")
  }
  return 0