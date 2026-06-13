from main import *
from Eigen import Matrix, MatrixXi, Matrix3d, Matrix4d, Vector3d, Map, RowMajor, Dynamic

def test_blocks[M1: Int, M2: Int, N1: Int, N2: Int]() raises:
  var m_fixed = Matrix[Int, M1+M2, N1+N2]()
  var m_dynamic = MatrixXi(M1+M2, N1+N2)
  var mat11 = Matrix[Int, M1, N1](); mat11.setRandom()
  var mat12 = Matrix[Int, M1, N2](); mat12.setRandom()
  var mat21 = Matrix[Int, M2, N1](); mat21.setRandom()
  var mat22 = Matrix[Int, M2, N2](); mat22.setRandom()
  var matx11 = mat11; var matx12 = mat12; var matx21 = mat21; var matx22 = mat22
  # Use temporary for comma-initializer result
  var tmp1 = m_fixed.__comma_init__(mat11, mat12, mat21, matx22).finished()
  var tmp2 = m_dynamic.__comma_init__(mat11, matx12, mat21, matx22).finished()
  VERIFY_IS_EQUAL(tmp1, tmp2)
  VERIFY_IS_EQUAL(m_fixed.template topLeftCorner[M1, N1](), mat11)
  VERIFY_IS_EQUAL(m_fixed.template topRightCorner[M1, N2](), mat12)
  VERIFY_IS_EQUAL(m_fixed.template bottomLeftCorner[M2, N1](), mat21)
  VERIFY_IS_EQUAL(m_fixed.template bottomRightCorner[M2, N2](), mat22)
  var tmp3 = m_fixed.__comma_init__(mat12, mat11, matx21, mat22).finished()
  var tmp4 = m_dynamic.__comma_init__(mat12, matx11, matx21, mat22).finished()
  VERIFY_IS_EQUAL(tmp3, tmp4)
  if N1 > 0:
    VERIFY_RAISES_ASSERT(m_fixed.__comma_init__(mat11, mat12, mat11, mat21, mat22))
    VERIFY_RAISES_ASSERT(m_fixed.__comma_init__(mat11, mat12, mat21, mat21, mat22))
  else:
    var tmp5 = m_fixed.__comma_init__(mat11, mat12, mat11, mat11, mat21, mat21, mat22).finished()
    var tmp6 = m_dynamic.__comma_init__(mat12, mat22).finished()
    VERIFY_IS_EQUAL(tmp5, tmp6)
  if M1 != M2:
    VERIFY_RAISES_ASSERT(m_fixed.__comma_init__(mat11, mat21, mat12, mat22))

def test_block_recursion_run[N: Int]() raises:
  test_blocks[(N>>6)&3, (N>>4)&3, (N>>2)&3, N & 3]()
  test_block_recursion_run[N-1]()

def test_block_recursion_run_neg1() raises:

def test_commainitializer() raises:
  var m3 = Matrix3d()
  var m4 = Matrix4d()
  VERIFY_RAISES_ASSERT(m3.__comma_init__(1, 2, 3, 4, 5, 6, 7, 8))
  #ifndef _MSC_VER
  VERIFY_RAISES_ASSERT(m3.__comma_init__(1, 2, 3, 4, 5, 6, 7, 8, 9, 10))
  #endif
  var data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  var ref = Map[Matrix[Float64, 3, 3, RowMajor]](data)
  m3 = Matrix3d.Random()
  m3.__comma_init__(1, 2, 3, 4, 5, 6, 7, 8, 9)
  VERIFY_IS_APPROX(m3, ref)
  var vec = Vector3d[3]()
  vec[0].__comma_init__(1, 4, 7)
  vec[1].__comma_init__(2, 5, 8)
  vec[2].__comma_init__(3, 6, 9)
  m3 = Matrix3d.Random()
  m3.__comma_init__(vec[0], vec[1], vec[2])
  VERIFY_IS_APPROX(m3, ref)
  vec[0].__comma_init__(1, 2, 3)
  vec[1].__comma_init__(4, 5, 6)
  vec[2].__comma_init__(7, 8, 9)
  m3 = Matrix3d.Random()
  m3.__comma_init__(vec[0].transpose(), 4, 5, 6, vec[2].transpose())
  VERIFY_IS_APPROX(m3, ref)
  test_block_recursion_run[(1<<8) - 1]()