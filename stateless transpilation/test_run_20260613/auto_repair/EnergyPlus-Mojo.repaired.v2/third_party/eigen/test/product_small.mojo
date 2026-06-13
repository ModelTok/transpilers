from product import product
from Eigen.LU import *
from Eigen.Core import *

def product1x1[_: Int]():
  var matAstatic = Matrix[float32, 1, 3]()
  var matBstatic = Matrix[float32, 3, 1]()
  matAstatic.setRandom()
  matBstatic.setRandom()
  VERIFY_IS_APPROX( (matAstatic * matBstatic).coeff(0,0), 
                    matAstatic.cwiseProduct(matBstatic.transpose()).sum() )
  var matAdynamic = MatrixXf(1,3)
  var matBdynamic = MatrixXf(3,1)
  matAdynamic.setRandom()
  matBdynamic.setRandom()
  VERIFY_IS_APPROX( (matAdynamic * matBdynamic).coeff(0,0), 
                    matAdynamic.cwiseProduct(matBdynamic.transpose()).sum() )

def ref_prod[TC: DType, TA: DType, TB: DType](C: Ref[Matrix[TC, Dynamic, Dynamic]], A: Ref[Matrix[TA, Dynamic, Dynamic]], B: Ref[Matrix[TB, Dynamic, Dynamic]]) -> Ref[Matrix[TC, Dynamic, Dynamic]]:
  for i in range(C.rows()):
    for j in range(C.cols()):
      for k in range(A.cols()):
        C.coeffRef(i,j) += A.coeff(i,k) * B.coeff(k,j)
  return C

def test_lazy_single[T: DType, Rows: Int, Cols: Int, Depth: Int, OC: Int, OA: Int, OB: Int](rows: Int, cols: Int, depth: Int):
  if not ( (Rows ==1 and Depth!=1 and OA==ColMajor)
        or (Depth==1 and Rows !=1 and OA==RowMajor)
        or (Cols ==1 and Depth!=1 and OB==RowMajor)
        or (Depth==1 and Cols !=1 and OB==ColMajor)
        or (Rows ==1 and Cols !=1 and OC==ColMajor)
        or (Cols ==1 and Rows !=1 and OC==RowMajor) ):
    var A = Matrix[T, Rows, Depth, OA](rows, depth)
    A.setRandom()
    var B = Matrix[T, Depth, Cols, OB](depth, cols)
    B.setRandom()
    var C = Matrix[T, Rows, Cols, OC](rows, cols)
    C.setRandom()
    var D = Matrix[T, Rows, Cols, OC](C)
    VERIFY_IS_APPROX(C += A.lazyProduct(B), ref_prod(D, A, B))

def test_lazy_all_layout[T: DType, Rows: Int, Cols: Int, Depth: Int](rows: Int = Rows, cols: Int = Cols, depth: Int = Depth):
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,ColMajor,ColMajor,ColMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,RowMajor,ColMajor,ColMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,ColMajor,RowMajor,ColMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,RowMajor,RowMajor,ColMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,ColMajor,ColMajor,RowMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,RowMajor,ColMajor,RowMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,ColMajor,RowMajor,RowMajor](rows,cols,depth) ))
  CALL_SUBTEST(( test_lazy_single[T,Rows,Cols,Depth,RowMajor,RowMajor,RowMajor](rows,cols,depth) ))

def test_lazy_l1[T: DType]():
  var rows = internal.random[Int](1,12)
  var cols = internal.random[Int](1,12)
  var depth = internal.random[Int](1,12)
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,3]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,8]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,9]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,1,-1](1,1,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,2,1,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,2,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,2,2,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,3,3,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,4,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,8,1]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,-1,1](4,cols) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,7,-1,1](7,cols) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,8,1](rows) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,3,1](rows) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,-1,1](rows,cols) ))

def test_lazy_l2[T: DType]():
  var rows = internal.random[Int](1,12)
  var cols = internal.random[Int](1,12)
  var depth = internal.random[Int](1,12)
  CALL_SUBTEST(( test_lazy_all_layout[T,2,1,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,2,1,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,1,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,1,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,5,1,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,1,5]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,1,6]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,6,1,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,8,1,8]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,1,4](rows) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,1,-1](4,1,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,1,-1](rows,1,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,2,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,2,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,4,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,4,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,5,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,4,5]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,4,6]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,6,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,8,8]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,-1, 4](1,cols) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1, 4,-1](1,4,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,1,-1,-1](1,cols,depth) ))

def test_lazy_l3[T: DType]():
  var rows = internal.random[Int](1,12)
  var cols = internal.random[Int](1,12)
  var depth = internal.random[Int](1,12)
  CALL_SUBTEST(( test_lazy_all_layout[T,2,4,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,2,6,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,3,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,8,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,5,6,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,2,5]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,7,6]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,6,8,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,8,3,8]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,6,4](rows) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,3,-1](4,3,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,-1,6,-1](rows,6,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,8,2,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,5,2,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,4,2]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,8,4,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,6,5,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,4,5]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,3,4,6]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,2,6,4]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,7,8,8]() ))
  CALL_SUBTEST(( test_lazy_all_layout[T,8,-1, 4](8,cols) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,3, 4,-1](3,4,depth) ))
  CALL_SUBTEST(( test_lazy_all_layout[T,4,-1,-1](4,cols,depth) ))

def test_linear_but_not_vectorizable[T: DType, N: Int, M: Int, K: Int]():
  var n = N if N != Dynamic else internal.random[Index](1,32)
  var m = M if M != Dynamic else internal.random[Index](1,32)
  var k = K if K != Dynamic else internal.random[Index](1,32)
  {
    var A = Matrix[T, N, M+1]()
    A.setRandom(n, m+1)
    var B = Matrix[T, M*2, K]()
    B.setRandom(m*2, k)
    var C = Matrix[T, 1, K]()
    var R = Matrix[T, 1, K]()
    C.noalias() = A.template topLeftCorner[1, M]() * (B.template topRows[M]() + B.template bottomRows[M]())
    R.noalias() = A.template topLeftCorner[1, M]() * (B.template topRows[M]() + B.template bottomRows[M]()).eval()
    VERIFY_IS_APPROX(C, R)
  }
  {
    var A = Matrix[T, M+1, N, RowMajor]()
    A.setRandom(m+1, n)
    var B = Matrix[T, K, M*2, RowMajor]()
    B.setRandom(k, m*2)
    var C = Matrix[T, K, 1]()
    var R = Matrix[T, K, 1]()
    C.noalias() = (B.template leftCols[M]() + B.template rightCols[M]()) * A.template topLeftCorner[M, 1]()
    R.noalias() = (B.template leftCols[M]() + B.template rightCols[M]()).eval() * A.template topLeftCorner[M, 1]()
    VERIFY_IS_APPROX(C, R)
  }

def bug_1311[Rows: Int]():
  var A = Matrix[float64, Rows, 2]()
  A.setRandom()
  var b = Vector2d.Random()
  var res = Matrix[float64, Rows, 1]()
  res.noalias() = 1. * (A * b)
  VERIFY_IS_APPROX(res, A*b)
  res.noalias() = 1.*A * b
  VERIFY_IS_APPROX(res, A*b)
  res.noalias() = (1.*A).lazyProduct(b)
  VERIFY_IS_APPROX(res, A*b)
  res.noalias() = (1.*A).lazyProduct(1.*b)
  VERIFY_IS_APPROX(res, A*b)
  res.noalias() = (A).lazyProduct(1.*b)
  VERIFY_IS_APPROX(res, A*b)

def test_product_small():
  for i in range(g_repeat):
    CALL_SUBTEST_1( product(Matrix[float32, 3, 2]()) )
    CALL_SUBTEST_2( product(Matrix[int32, 3, 17]()) )
    CALL_SUBTEST_8( product(Matrix[float64, 3, 17]()) )
    CALL_SUBTEST_3( product(Matrix3d()) )
    CALL_SUBTEST_4( product(Matrix4d()) )
    CALL_SUBTEST_5( product(Matrix4f()) )
    CALL_SUBTEST_6( product1x1[0]() )
    CALL_SUBTEST_11( test_lazy_l1[float32]() )
    CALL_SUBTEST_12( test_lazy_l2[float32]() )
    CALL_SUBTEST_13( test_lazy_l3[float32]() )
    CALL_SUBTEST_21( test_lazy_l1[float64]() )
    CALL_SUBTEST_22( test_lazy_l2[float64]() )
    CALL_SUBTEST_23( test_lazy_l3[float64]() )
    CALL_SUBTEST_31( test_lazy_l1[ComplexFloat32]() )
    CALL_SUBTEST_32( test_lazy_l2[ComplexFloat32]() )
    CALL_SUBTEST_33( test_lazy_l3[ComplexFloat32]() )
    CALL_SUBTEST_41( test_lazy_l1[ComplexFloat64]() )
    CALL_SUBTEST_42( test_lazy_l2[ComplexFloat64]() )
    CALL_SUBTEST_43( test_lazy_l3[ComplexFloat64]() )
    CALL_SUBTEST_7(( test_linear_but_not_vectorizable[float32,2,1,Dynamic]() ))
    CALL_SUBTEST_7(( test_linear_but_not_vectorizable[float32,3,1,Dynamic]() ))
    CALL_SUBTEST_7(( test_linear_but_not_vectorizable[float32,2,1,16]() ))
    CALL_SUBTEST_6( bug_1311[3]() )
    CALL_SUBTEST_6( bug_1311[5]() )
  #ifdef EIGEN_TEST_PART_6
  {
    var v = Vector3f.Random()
    VERIFY_IS_APPROX( (v * v.transpose()) * v, (v * v.transpose()).eval() * v)
  }
  {
    var A = Eigen.Matrix[float64, 1, 1]()
    A.setRandom()
    var B = Eigen.Matrix[float64, 18, 1]()
    B.setRandom()
    var C = Eigen.Matrix[float64, 1, 18]()
    C.setRandom()
    VERIFY_IS_APPROX(B * A.inverse(), B * A.inverse()[0])
    VERIFY_IS_APPROX(A.inverse() * C, A.inverse()[0] * C)
  }
  {
    var A = Eigen.Matrix[float64, 10, 10]()
    var B = Eigen.Matrix[float64, 10, 10]()
    var C = Eigen.Matrix[float64, 10, 10]()
    A.setRandom()
    C = A
    for k in range(79):
      C = C * A
    B.noalias() = (((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A)) * ((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A)))
                * (((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A)) * ((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A))*((A*A)*(A*A)))
    VERIFY_IS_APPROX(B, C)
  }
  #endif