from io import *
from Eigen import *

alias SCALAR = Float32
alias SCALARA = SCALAR
alias SCALARB = SCALAR
alias Scalar = SCALAR
alias RealScalar = NumTraits[Scalar].Real
alias A = Matrix[SCALARA, Dynamic, Dynamic]
alias B = Matrix[SCALARB, Dynamic, Dynamic]
alias C = Matrix[Scalar, Dynamic, Dynamic]
alias M = Matrix[RealScalar, Dynamic, Dynamic]

#[if HAVE_BLAS]
extern {
  #include <Eigen/src/misc/blas.h>
}
var fone: Float32 = 1
var fzero: Float32 = 0
var done: Float64 = 1
var szero: Float64 = 0
var cfone: ComplexFloat32 = 1
var cfzero: ComplexFloat32 = 0
var cdone: ComplexFloat64 = 1
var cdzero: ComplexFloat64 = 0
var notrans: Int8 = 'N'
var trans: Int8 = 'T'
var nonunit: Int8 = 'N'
var lower: Int8 = 'L'
var right: Int8 = 'R'
var intone: Int = 1

def blas_gemm(a: MatrixXf, b: MatrixXf, c: MatrixXf):
    var M: Int = c.rows()
    var N: Int = c.cols()
    var K: Int = a.cols()
    var lda: Int = a.rows()
    var ldb: Int = b.rows()
    var ldc: Int = c.rows()
    sgemm_(&notrans, &notrans, &M, &N, &K, &fone,
           const_cast[Pointer[Float32]](a.data()), &lda,
           const_cast[Pointer[Float32]](b.data()), &ldb, &fone,
           c.data(), &ldc)

EIGEN_DONT_INLINE def blas_gemm(a: MatrixXd, b: MatrixXd, c: MatrixXd):
    var M: Int = c.rows()
    var N: Int = c.cols()
    var K: Int = a.cols()
    var lda: Int = a.rows()
    var ldb: Int = b.rows()
    var ldc: Int = c.rows()
    dgemm_(&notrans, &notrans, &M, &N, &K, &done,
           const_cast[Pointer[Float64]](a.data()), &lda,
           const_cast[Pointer[Float64]](b.data()), &ldb, &done,
           c.data(), &ldc)

def blas_gemm(a: MatrixXcf, b: MatrixXcf, c: MatrixXcf):
    var M: Int = c.rows()
    var N: Int = c.cols()
    var K: Int = a.cols()
    var lda: Int = a.rows()
    var ldb: Int = b.rows()
    var ldc: Int = c.rows()
    cgemm_(&notrans, &notrans, &M, &N, &K, (Pointer[Float32])(&cfone),
           const_cast[Pointer[Float32]]((Pointer[Float32])(a.data())), &lda,
           const_cast[Pointer[Float32]]((Pointer[Float32])(b.data())), &ldb, (Pointer[Float32])(&cfone),
           (Pointer[Float32])(c.data()), &ldc)

def blas_gemm(a: MatrixXcd, b: MatrixXcd, c: MatrixXcd):
    var M: Int = c.rows()
    var N: Int = c.cols()
    var K: Int = a.cols()
    var lda: Int = a.rows()
    var ldb: Int = b.rows()
    var ldc: Int = c.rows()
    zgemm_(&notrans, &notrans, &M, &N, &K, (Pointer[Float64])(&cdone),
           const_cast[Pointer[Float64]]((Pointer[Float64])(a.data())), &lda,
           const_cast[Pointer[Float64]]((Pointer[Float64])(b.data())), &ldb, (Pointer[Float64])(&cdone),
           (Pointer[Float64])(c.data()), &ldc)
#else
def matlab_cplx_cplx(ar: M, ai: M, br: M, bi: M, cr: M, ci: M):
    cr.noalias() += ar * br
    cr.noalias() -= ai * bi
    ci.noalias() += ar * bi
    ci.noalias() += ai * br

def matlab_real_cplx(a: M, br: M, bi: M, cr: M, ci: M):
    cr.noalias() += a * br
    ci.noalias() += a * bi

def matlab_cplx_real(ar: M, ai: M, b: M, cr: M, ci: M):
    cr.noalias() += ar * b
    ci.noalias() += ai * b

def gemm[A: Matrix, B: Matrix, C: Matrix](a: A, b: B, c: C):
 c.noalias() += a * b

def main(argc: Int, argv: Pointer[Pointer[Int8]]) -> Int:
  var l1: Int = internal.queryL1CacheSize()
  var l2: Int = internal.queryTopLevelCacheSize()
  print("L1 cache size     = ", (l1>0 ? l1/1024 : -1), " KB")
  print("L2/L3 cache size  = ", (l2>0 ? l2/1024 : -1), " KB")
  alias Traits = internal.gebp_traits[Scalar, Scalar]
  print("Register blocking = ", Traits.mr, " x ", Traits.nr)
  var rep: Int = 1
  var tries: Int = 2
  var s: Int = 2048
  var m: Int = s
  var n: Int = s
  var p: Int = s
  var cache_size1: Int = -1
  var cache_size2: Int = l2
  var cache_size3: Int = 0
  var need_help: Bool = False
  var i: Int = 1
  while i < argc:
    if argv[i][0] == '-':
      if argv[i][1] == 's':
        i += 1
        s = atoi(argv[i])
        i += 1
        m = n = p = s
        if argv[i][0] != '-':
          n = atoi(argv[i])
          i += 1
          p = atoi(argv[i])
          i += 1
      elif argv[i][1] == 'c':
        i += 1
        cache_size1 = atoi(argv[i])
        i += 1
        if argv[i][0] != '-':
          cache_size2 = atoi(argv[i])
          i += 1
          if argv[i][0] != '-':
            cache_size3 = atoi(argv[i])
            i += 1
      elif argv[i][1] == 't':
        i += 1
        tries = atoi(argv[i])
        i += 1
      elif argv[i][1] == 'p':
        i += 1
        rep = atoi(argv[i])
        i += 1
      else:
        break
    else:
      need_help = True
      break
  if need_help:
    print(argv[0], " -s <matrix sizes> -c <cache sizes> -t <nb tries> -p <nb repeats>")
    print("   <matrix sizes> : size")
    print("   <matrix sizes> : rows columns depth")
    return 1
  #[if EIGEN_VERSION_AT_LEAST(3,2,90)]
  if cache_size1 > 0:
    setCpuCacheSizes(cache_size1, cache_size2, cache_size3)
  #end
  var a: A(m, p)
  a.setRandom()
  var b: B(p, n)
  b.setRandom()
  var c: C(m, n)
  c.setOnes()
  var rc: C = c
  print("Matrix sizes = ", m, "x", p, " * ", p, "x", n)
  var mc: Int = m
  var nc: Int = n
  var kc: Int = p
  internal.computeProductBlockingSizes[Scalar, Scalar](kc, mc, nc)
  print("blocking size (mc x kc) = ", mc, " x ", kc)
  var r: C = c
  #[if defined EIGEN_HAS_OPENMP]
  Eigen.initParallel()
  var procs: Int = omp_get_max_threads()
  if procs > 1:
    #[ifdef HAVE_BLAS]
    blas_gemm(a, b, r)
    #else
    omp_set_num_threads(1)
    r.noalias() += a * b
    omp_set_num_threads(procs)
    #end
    c.noalias() += a * b
    if !r.isApprox(c):
      eprint("Warning, your parallel product is crap!\n\n")
  #elif defined HAVE_BLAS
    blas_gemm(a, b, r)
    c.noalias() += a * b
    if !r.isApprox(c):
      print(r - c)
      eprint("Warning, your product is crap!\n\n")
  #else
    if 1.0 * m * n * p < 2000.0 * 2000.0 * 2000.0:
      gemm(a, b, c)
      r.noalias() += a.cast[Scalar]().lazyProduct(b.cast[Scalar]())
      if !r.isApprox(c):
        print(r - c)
        eprint("Warning, your product is crap!\n\n")
  #end
  #[ifdef HAVE_BLAS]
  var tblas: BenchTimer
  c = rc
  BENCH(tblas, tries, rep, blas_gemm(a, b, c))
  print("blas  cpu         ", tblas.best(CPU_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/tblas.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", tblas.total(CPU_TIMER),  "s)")
  print("blas  real        ", tblas.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/tblas.best(REAL_TIMER))*1e-9,  " GFLOPS \t(", tblas.total(REAL_TIMER),  "s)")
  #end
  var tmt: BenchTimer
  c = rc
  BENCH(tmt, tries, rep, gemm(a, b, c))
  print("eigen cpu         ", tmt.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/tmt.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", tmt.total(CPU_TIMER),  "s)")
  print("eigen real        ", tmt.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/tmt.best(REAL_TIMER))*1e-9, " GFLOPS \t(", tmt.total(REAL_TIMER), "s)")
  #[ifdef EIGEN_HAS_OPENMP]
  if procs > 1:
    var tmono: BenchTimer
    omp_set_num_threads(1)
    Eigen.setNbThreads(1)
    c = rc
    BENCH(tmono, tries, rep, gemm(a, b, c))
    print("eigen mono cpu    ", tmono.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/tmono.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", tmono.total(CPU_TIMER),  "s)")
    print("eigen mono real   ", tmono.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/tmono.best(REAL_TIMER))*1e-9, " GFLOPS \t(", tmono.total(REAL_TIMER), "s)")
    print("mt speed up x", tmono.best(CPU_TIMER) / tmt.best(REAL_TIMER),  " => ", (100.0*tmono.best(CPU_TIMER) / tmt.best(REAL_TIMER))/procs, "%")
  #end
  if 1.0 * m * n * p < 30.0 * 30.0 * 30.0:
      var tmt: BenchTimer
      c = rc
      BENCH(tmt, tries, rep, c.noalias() += a.lazyProduct(b))
      print("lazy cpu         ", tmt.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/tmt.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", tmt.total(CPU_TIMER),  "s)")
      print("lazy real        ", tmt.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/tmt.best(REAL_TIMER))*1e-9, " GFLOPS \t(", tmt.total(REAL_TIMER), "s)")
  #[ifdef DECOUPLED]
  if (NumTraits[A.Scalar].IsComplex) and (NumTraits[B.Scalar].IsComplex):
    var ar: M(m,p)
    ar.setRandom()
    var ai: M(m,p)
    ai.setRandom()
    var br: M(p,n)
    br.setRandom()
    var bi: M(p,n)
    bi.setRandom()
    var cr: M(m,n)
    cr.setRandom()
    var ci: M(m,n)
    ci.setRandom()
    var t: BenchTimer
    BENCH(t, tries, rep, matlab_cplx_cplx(ar, ai, br, bi, cr, ci))
    print("\"matlab\" cpu    ", t.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/t.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", t.total(CPU_TIMER),  "s)")
    print("\"matlab\" real   ", t.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/t.best(REAL_TIMER))*1e-9, " GFLOPS \t(", t.total(REAL_TIMER), "s)")
  if (!NumTraits[A.Scalar].IsComplex) and (NumTraits[B.Scalar].IsComplex):
    var a: M(m,p)
    a.setRandom()
    var br: M(p,n)
    br.setRandom()
    var bi: M(p,n)
    bi.setRandom()
    var cr: M(m,n)
    cr.setRandom()
    var ci: M(m,n)
    ci.setRandom()
    var t: BenchTimer
    BENCH(t, tries, rep, matlab_real_cplx(a, br, bi, cr, ci))
    print("\"matlab\" cpu    ", t.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/t.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", t.total(CPU_TIMER),  "s)")
    print("\"matlab\" real   ", t.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/t.best(REAL_TIMER))*1e-9, " GFLOPS \t(", t.total(REAL_TIMER), "s)")
  if (NumTraits[A.Scalar].IsComplex) and (!NumTraits[B.Scalar].IsComplex):
    var ar: M(m,p)
    ar.setRandom()
    var ai: M(m,p)
    ai.setRandom()
    var b: M(p,n)
    b.setRandom()
    var cr: M(m,n)
    cr.setRandom()
    var ci: M(m,n)
    ci.setRandom()
    var t: BenchTimer
    BENCH(t, tries, rep, matlab_cplx_real(ar, ai, b, cr, ci))
    print("\"matlab\" cpu    ", t.best(CPU_TIMER)/rep,  "s  \t", (Float64(m)*n*p*rep*2/t.best(CPU_TIMER))*1e-9,  " GFLOPS \t(", t.total(CPU_TIMER),  "s)")
    print("\"matlab\" real   ", t.best(REAL_TIMER)/rep, "s  \t", (Float64(m)*n*p*rep*2/t.best(REAL_TIMER))*1e-9, " GFLOPS \t(", t.total(REAL_TIMER), "s)")
  #end
  return 0