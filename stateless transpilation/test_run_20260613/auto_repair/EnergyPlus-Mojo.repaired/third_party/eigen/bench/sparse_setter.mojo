# ifndef SIZE
# define SIZE 100000
# endif
# ifndef NBPERROW
# define NBPERROW 24
# endif
# ifndef REPEAT
# define REPEAT 2
# endif
# ifndef NBTRIES
# define NBTRIES 2
# endif
# ifndef KK
# define KK 10
# endif
# ifndef NOGOOGLE
# define EIGEN_GOOGLEHASH_SUPPORT
# include <google/sparse_hash_map>
# endif
# include "BenchSparseUtil.h"
# define CHECK_MEM
# define BENCH(X) \
  timer.reset(); \
  for (int _j=0; _j<NBTRIES; ++_j) { \
    timer.start(); \
    for (int _k=0; _k<REPEAT; ++_k) { \
        X  \
  } timer.stop(); }
typedef vector<Vector2i> Coordinates;
typedef vector<float> Values;
EIGEN_DONT_INLINE Scalar* setinnerrand_eigen(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_dynamic(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_compact(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_sumeq(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_gnu_hash(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_google_dense(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_eigen_google_sparse(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_scipy(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_ublas_mapped(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_ublas_coord(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_ublas_compressed(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_ublas_genvec(Coordinates& coords , Values& vals );
EIGEN_DONT_INLINE Scalar* setrand_mtl(Coordinates& coords , Values& vals );
def main(argc: int, argv: Pointer[Pointer[UInt8]]):
  var rows: int = SIZE
  var cols: int = SIZE
  var fullyrand: bool = true
  var timer: BenchTimer
  var coords: Coordinates
  var values: Values
  if fullyrand:
    var pool: Coordinates
    pool.reserve(cols*NBPERROW)
    cerr << "fill pool" << "\n"
    for i in range(0, cols*NBPERROW):
      var ij: Vector2i = Vector2i(internal::random<int>(0,rows-1),internal::random<int>(0,cols-1))
      pool.push_back(ij)
    cerr << "pool ok" << "\n"
    var n: int = cols*NBPERROW*KK
    coords.reserve(n)
    values.reserve(n)
    for i in range(0, n):
      var i: int = internal::random<int>(0,pool.size())
      coords.push_back(pool[i])
      values.push_back(internal::random<Scalar>())
  else:
    for j in range(0, cols):
      for i in range(0, NBPERROW):
        coords.push_back(Vector2i(internal::random<int>(0,rows-1),j))
        values.push_back(internal::random<Scalar>())
  cout << "nnz = " << coords.size()  << "\n"
  CHECK_MEM
    # ifdef DENSEMATRIX
    {
      BENCH(setrand_eigen_dense(coords,values);)
      cout << "Eigen Dense\t" << timer.value() << "\n"
    }
    # endif
    {
      BENCH(setrand_eigen_dynamic(coords,values);)
      cout << "Eigen dynamic\t" << timer.value() << "\n"
    }
    {
      BENCH(setrand_eigen_sumeq(coords,values);)
      cout << "Eigen sumeq\t" << timer.value() << "\n"
    }
    {
    }
    {
      BENCH(setrand_scipy(coords,values);)
      cout << "scipy\t" << timer.value() << "\n"
    }
    # ifndef NOGOOGLE
    {
      BENCH(setrand_eigen_google_dense(coords,values);)
      cout << "Eigen google dense\t" << timer.value() << "\n"
    }
    {
      BENCH(setrand_eigen_google_sparse(coords,values);)
      cout << "Eigen google sparse\t" << timer.value() << "\n"
    }
    # endif
    # ifndef NOUBLAS
    {
    }
    {
      BENCH(setrand_ublas_genvec(coords,values);)
      cout << "ublas vecofvec\t" << timer.value() << "\n"
    }
    /*{
      timer.reset();
      timer.start();
      for (int k=0; k<REPEAT; ++k)
        setrand_ublas_compressed(coords,values);
      timer.stop();
      cout << "ublas comp\t" << timer.value() << "\n";
    }
    {
      timer.reset();
      timer.start();
      for (int k=0; k<REPEAT; ++k)
        setrand_ublas_coord(coords,values);
      timer.stop();
      cout << "ublas coord\t" << timer.value() << "\n";
    }*/
    # endif
    # ifndef NOMTL
    {
      BENCH(setrand_mtl(coords,values));
      cout << "MTL\t" << timer.value() << "\n"
    }
    # endif
  return 0
EIGEN_DONT_INLINE Scalar* setinnerrand_eigen(Coordinates& coords , Values& vals ):
  var mat: SparseMatrix[Scalar] = SparseMatrix[Scalar](SIZE,SIZE)
  for i in range(0, coords.size()):
    mat.insert(coords[i].x(), coords[i].y()) = vals[i]
  mat.finalize()
  CHECK_MEM
  return 0
EIGEN_DONT_INLINE Scalar* setrand_eigen_dynamic(Coordinates& coords , Values& vals ):
  var mat: DynamicSparseMatrix[Scalar] = DynamicSparseMatrix[Scalar](SIZE,SIZE)
  mat.reserve(coords.size()/10)
  for i in range(0, coords.size()):
    mat.coeffRef(coords[i].x(), coords[i].y()) += vals[i]
  mat.finalize()
  CHECK_MEM
  return &mat.coeffRef(coords[0].x(), coords[0].y())
EIGEN_DONT_INLINE Scalar* setrand_eigen_sumeq(Coordinates& coords , Values& vals ):
  var n: int = coords.size()/KK
  var mat: DynamicSparseMatrix[Scalar] = DynamicSparseMatrix[Scalar](SIZE,SIZE)
  for j in range(0, KK):
    var aux: DynamicSparseMatrix[Scalar] = DynamicSparseMatrix[Scalar](SIZE,SIZE)
    mat.reserve(n)
    for i in range(j*n, (j+1)*n):
      aux.insert(coords[i].x(), coords[i].y()) += vals[i]
    aux.finalize()
    mat += aux
  return &mat.coeffRef(coords[0].x(), coords[0].y())
EIGEN_DONT_INLINE Scalar* setrand_eigen_compact(Coordinates& coords , Values& vals ):
  var setter: DynamicSparseMatrix[Scalar] = DynamicSparseMatrix[Scalar](SIZE,SIZE)
  setter.reserve(coords.size()/10)
  for i in range(0, coords.size()):
    setter.coeffRef(coords[i].x(), coords[i].y()) += vals[i]
  var mat: SparseMatrix[Scalar] = setter
  CHECK_MEM
  return &mat.coeffRef(coords[0].x(), coords[0].y())
EIGEN_DONT_INLINE Scalar* setrand_eigen_gnu_hash(Coordinates& coords , Values& vals ):
  var mat: SparseMatrix[Scalar] = SparseMatrix[Scalar](SIZE,SIZE)
  {
    var setter: RandomSetter[SparseMatrix[Scalar], StdMapTraits] = RandomSetter[SparseMatrix[Scalar], StdMapTraits](mat)
    for i in range(0, coords.size()):
      setter(coords[i].x(), coords[i].y()) += vals[i]
    CHECK_MEM
  }
  return &mat.coeffRef(coords[0].x(), coords[0].y())
# ifndef NOGOOGLE
EIGEN_DONT_INLINE Scalar* setrand_eigen_google_dense(Coordinates& coords , Values& vals ):
  var mat: SparseMatrix[Scalar] = SparseMatrix[Scalar](SIZE,SIZE)
  {
    var setter: RandomSetter[SparseMatrix[Scalar], GoogleDenseHashMapTraits] = RandomSetter[SparseMatrix[Scalar], GoogleDenseHashMapTraits](mat)
    for i in range(0, coords.size()):
      setter(coords[i].x(), coords[i].y()) += vals[i]
    CHECK_MEM
  }
  return &mat.coeffRef(coords[0].x(), coords[0].y())
EIGEN_DONT_INLINE Scalar* setrand_eigen_google_sparse(Coordinates& coords , Values& vals ):
  var mat: SparseMatrix[Scalar] = SparseMatrix[Scalar](SIZE,SIZE)
  {
    var setter: RandomSetter[SparseMatrix[Scalar], GoogleSparseHashMapTraits] = RandomSetter[SparseMatrix[Scalar], GoogleSparseHashMapTraits](mat)
    for i in range(0, coords.size()):
      setter(coords[i].x(), coords[i].y()) += vals[i]
    CHECK_MEM
  }
  return &mat.coeffRef(coords[0].x(), coords[0].y())
# endif
template <class T>
def coo_tocsr(const n_row: int,
               const n_col: int,
               const nnz: int,
               const Aij: Coordinates,
               const Ax: Values,
                     Bp: Pointer[int],
                     Bj: Pointer[int],
                     Bx: Pointer[T]):
    fill(Bp, Bp + n_row, 0)
    for n in range(0, nnz):
        Bp[Aij[n].x()] += 1
    var cumsum: int = 0
    for i in range(0, n_row):
        var temp: int = Bp[i]
        Bp[i] = cumsum
        cumsum += temp
    Bp[n_row] = nnz
    for n in range(0, nnz):
        var row: int = Aij[n].x()
        var dest: int = Bp[row]
        Bj[dest] = Aij[n].y()
        Bx[dest] = Ax[n]
        Bp[row] += 1
    var last: int = 0
    for i in range(0, n_row + 1):
        var temp: int = Bp[i]
        Bp[i] = last
        last = temp
template< class T1, class T2 >
def kv_pair_less(x: pair[T1,T2], y: pair[T1,T2]) -> bool:
    return x.first < y.first
template<class I, class T>
def csr_sort_indices(const n_row: I,
                      const Ap: Pointer[I],
                            Aj: Pointer[I],
                            Ax: Pointer[T]):
    var temp: vector[ pair[I,T] ]
    for i in range(0, n_row):
        var row_start: I = Ap[i]
        var row_end: I = Ap[i+1]
        temp.clear()
        for jj in range(row_start, row_end):
            temp.push_back(make_pair(Aj[jj],Ax[jj]))
        sort(temp.begin(),temp.end(),kv_pair_less[I,T])
        var n: I = 0
        for jj in range(row_start, row_end):
            Aj[jj] = temp[n].first
            Ax[jj] = temp[n].second
            n += 1
template <class I, class T>
def csr_sum_duplicates(const n_row: I,
                        const n_col: I,
                              Ap: Pointer[I],
                              Aj: Pointer[I],
                              Ax: Pointer[T]):
    var nnz: I = 0
    var row_end: I = 0
    for i in range(0, n_row):
        var jj: I = row_end
        row_end = Ap[i+1]
        while jj < row_end:
            var j: I = Aj[jj]
            var x: T = Ax[jj]
            jj += 1
            while jj < row_end and Aj[jj] == j:
                x += Ax[jj]
                jj += 1
            Aj[nnz] = j
            Ax[nnz] = x
            nnz += 1
        Ap[i+1] = nnz
EIGEN_DONT_INLINE Scalar* setrand_scipy(Coordinates& coords , Values& vals ):
  var mat: SparseMatrix[Scalar] = SparseMatrix[Scalar](SIZE,SIZE)
  mat.resizeNonZeros(coords.size())
  coo_tocsr[Scalar](SIZE,SIZE, coords.size(), coords, vals, mat._outerIndexPtr(), mat._innerIndexPtr(), mat._valuePtr())
  csr_sort_indices(SIZE, mat._outerIndexPtr(), mat._innerIndexPtr(), mat._valuePtr())
  csr_sum_duplicates(SIZE, SIZE, mat._outerIndexPtr(), mat._innerIndexPtr(), mat._valuePtr())
  mat.resizeNonZeros(mat._outerIndexPtr()[SIZE])
  return &mat.coeffRef(coords[0].x(), coords[0].y())
# ifndef NOUBLAS
EIGEN_DONT_INLINE Scalar* setrand_ublas_mapped(Coordinates& coords , Values& vals ):
  var aux: mapped_matrix[Scalar] = mapped_matrix[Scalar](SIZE,SIZE)
  for i in range(0, coords.size()):
    aux(coords[i].x(), coords[i].y()) += vals[i]
  CHECK_MEM
  var mat: compressed_matrix[Scalar] = compressed_matrix[Scalar](aux)
  return 0
/*EIGEN_DONT_INLINE Scalar* setrand_ublas_coord(Coordinates& coords , Values& vals )
{
  coordinate_matrix<Scalar> aux(SIZE,SIZE);
  for (int i=0; i<coords.size(); ++i)
  {
    aux(coords[i].x(), coords[i].y()) = vals[i];
  }
  compressed_matrix<Scalar> mat(aux);
  return 0;//&mat(coords[0].x(), coords[0].y());
}
EIGEN_DONT_INLINE Scalar* setrand_ublas_compressed(Coordinates& coords , Values& vals )
{
  compressed_matrix<Scalar> mat(SIZE,SIZE);
  for (int i=0; i<coords.size(); ++i)
  {
    mat(coords[i].x(), coords[i].y()) = vals[i];
  }
  return 0;//&mat(coords[0].x(), coords[0].y());
}*/
EIGEN_DONT_INLINE Scalar* setrand_ublas_genvec(Coordinates& coords , Values& vals ):
  var aux: generalized_vector_of_vector[Scalar, row_major, ublas::vector[coordinate_vector[Scalar]]] = generalized_vector_of_vector[Scalar, row_major, ublas::vector[coordinate_vector[Scalar]]](SIZE,SIZE)
  for i in range(0, coords.size()):
    aux(coords[i].x(), coords[i].y()) += vals[i]
  CHECK_MEM
  var mat: compressed_matrix[Scalar,row_major] = compressed_matrix[Scalar,row_major](aux)
  return 0
# endif
# ifndef NOMTL
EIGEN_DONT_INLINE def setrand_mtl(Coordinates& coords , Values& vals ):
# endif