from testing import *
from Eigen.CXX11.Tensor import Tensor
from Eigen.CXX11.TensorSymmetry import SGroup, DynamicSGroup, StaticSGroup, Symmetry, AntiSymmetry, Hermiticity, AntiHermiticity, NegationFlag, ConjugationFlag, GlobalZeroFlag, GlobalRealFlag, GlobalImagFlag
from math import swap

using Map = Map
using Set = Set

def isDynGroup[Sym: ...](dummy: StaticSGroup[Sym]) -> Bool:
  _ = dummy
  return False

def isDynGroup(dummy: DynamicSGroup) -> Bool:
  _ = dummy
  return True

struct checkIdx:
  @staticmethod
  def doCheck_[ArrType](e: ArrType, flags: Int, dummy: Int, found: Set[UInt64], expected: Map[UInt64, Int]) -> Int:
    value = e[0]
    for i in range(1, len(e)):
      value = value * 10 + e[i]
    it = expected.get(value)
    VERIFY(it.is_some())
    VERIFY_IS_EQUAL(it.value(), flags)
    p = found.insert(value)
    VERIFY(p.second)
    return dummy

  @staticmethod
  def run(e: List[Int], flags: Int, dummy: Int, found: Set[UInt64], expected: Map[UInt64, Int]) -> Int:
    return checkIdx.doCheck_(e, flags, dummy, found, expected)

  @staticmethod
  def run[N: Int](e: StaticIntTuple[N], flags: Int, dummy: Int, found: Set[UInt64], expected: Map[UInt64, Int]) -> Int:
    return checkIdx.doCheck_(e, flags, dummy, found, expected)

def test_symgroups_static():
  var identity: StaticIntTuple[7] = StaticIntTuple[7](0,1,2,3,4,5,6)
  var group = StaticSGroup[
    AntiSymmetry[0,1],
    Hermiticity[0,2]
  ]()
  var found = Set[UInt64]()
  var expected = Map[UInt64, Int]()
  expected[123456] = 0
  expected[1023456] = NegationFlag
  expected[2103456] = ConjugationFlag
  expected[1203456] = ConjugationFlag | NegationFlag
  expected[2013456] = ConjugationFlag | NegationFlag
  expected[213456] = ConjugationFlag
  VERIFY_IS_EQUAL(group.size(), 6)
  VERIFY_IS_EQUAL(group.globalFlags(), GlobalImagFlag)
  group.apply[checkIdx, Int](identity, 0, found, expected)
  VERIFY_IS_EQUAL(len(found), 6)

def test_symgroups_dynamic():
  var identity = List[Int]()
  for i in range(0, 7):
    identity.append(i)
  var group = DynamicSGroup()
  group.add(0, 1, NegationFlag)
  group.add(0, 2, ConjugationFlag)
  VERIFY_IS_EQUAL(group.size(), 6)
  VERIFY_IS_EQUAL(group.globalFlags(), GlobalImagFlag)
  var found = Set[UInt64]()
  var expected = Map[UInt64, Int]()
  expected[123456] = 0
  expected[1023456] = NegationFlag
  expected[2103456] = ConjugationFlag
  expected[1203456] = ConjugationFlag | NegationFlag
  expected[2013456] = ConjugationFlag | NegationFlag
  expected[213456] = ConjugationFlag
  VERIFY_IS_EQUAL(group.size(), 6)
  VERIFY_IS_EQUAL(group.globalFlags(), GlobalImagFlag)
  group.apply[checkIdx, Int](identity, 0, found, expected)
  VERIFY_IS_EQUAL(len(found), 6)

def test_symgroups_selection():
  var identity7: StaticIntTuple[7] = StaticIntTuple[7](0,1,2,3,4,5,6)
  var identity10: StaticIntTuple[10] = StaticIntTuple[10](0,1,2,3,4,5,6,7,8,9)

  # Block 1
  # TODO

  # Block 2
  # TODO

  # Block 3
  # TODO

def test_tensor_epsilon():
  var sym = SGroup[AntiSymmetry[0,1], AntiSymmetry[1,2]]()
  var epsilon = Tensor[Int32, 3](3, 3, 3)
  epsilon.setZero()
  sym(epsilon, 0, 1, 2) = 1
  for i in range(0, 3):
    for j in range(0, 3):
      for k in range(0, 3):
        VERIFY_IS_EQUAL((epsilon[i, j, k]), (- (j - i) * (k - j) * (i - k) // 2))

def test_tensor_sym():
  var sym = SGroup[Symmetry[0,1], Symmetry[2,3]]()
  var t = Tensor[Int32, 4](10, 10, 10, 10)
  t.setZero()
  for l in range(0, 10):
    for k in range(l, 10):
      for j in range(0, 10):
        for i in range(j, 10):
          sym(t, i, j, k, l) = (i + j) * (k + l)
  for l in range(0, 10):
    for k in range(0, 10):
      for j in range(0, 10):
        for i in range(0, 10):
          VERIFY_IS_EQUAL((t[i, j, k, l]), ((i + j) * (k + l)))

def test_tensor_asym():
  var sym = SGroup[AntiSymmetry[0,1], AntiSymmetry[2,3]]()
  var t = Tensor[Int32, 4](10, 10, 10, 10)
  t.setZero()
  for l in range(0, 10):
    for k in range(l + 1, 10):
      for j in range(0, 10):
        for i in range(j + 1, 10):
          sym(t, i, j, k, l) = ((i * j) + (k * l))
  for l in range(0, 10):
    for k in range(0, 10):
      for j in range(0, 10):
        for i in range(0, 10):
          if i < j and k < l:
            VERIFY_IS_EQUAL((t[i, j, k, l]), (((i * j) + (k * l))))
          elif i > j and k > l:
            VERIFY_IS_EQUAL((t[i, j, k, l]), (((i * j) + (k * l))))
          elif i < j and k > l:
            VERIFY_IS_EQUAL((t[i, j, k, l]), (- ((i * j) + (k * l))))
          elif i > j and k < l:
            VERIFY_IS_EQUAL((t[i, j, k, l]), (- ((i * j) + (k * l))))
          else:
            VERIFY_IS_EQUAL((t[i, j, k, l]), 0)

def test_tensor_dynsym():
  var sym = DynamicSGroup()
  sym.addSymmetry(0, 1)
  sym.addSymmetry(2, 3)
  var t = Tensor[Int32, 4](10, 10, 10, 10)
  t.setZero()
  for l in range(0, 10):
    for k in range(l, 10):
      for j in range(0, 10):
        for i in range(j, 10):
          sym(t, i, j, k, l) = (i + j) * (k + l)
  for l in range(0, 10):
    for k in range(0, 10):
      for j in range(0, 10):
        for i in range(0, 10):
          VERIFY_IS_EQUAL((t[i, j, k, l]), ((i + j) * (k + l)))

def test_tensor_randacc():
  var sym = SGroup[Symmetry[0,1], Symmetry[2,3]]()
  var t = Tensor[Int32, 4](10, 10, 10, 10)
  t.setZero()
  for n in range(0, 1000000):
    var i = rand() % 10
    var j = rand() % 10
    var k = rand() % 10
    var l = rand() % 10
    if i < j:
      swap(i, j)
    if k < l:
      swap(k, l)
    sym(t, i, j, k, l) = (i + j) * (k + l)
  for l in range(0, 10):
    for k in range(0, 10):
      for j in range(0, 10):
        for i in range(0, 10):
          VERIFY_IS_EQUAL((t[i, j, k, l]), ((i + j) * (k + l)))

def test_cxx11_tensor_symmetry():
  CALL_SUBTEST(test_symgroups_static())
  CALL_SUBTEST(test_symgroups_dynamic())
  CALL_SUBTEST(test_symgroups_selection())
  CALL_SUBTEST(test_tensor_epsilon())
  CALL_SUBTEST(test_sym)
  CALL_SUBTEST(test_tensor_asym())
  CALL_SUBTEST(test_tensor_dynsym())
  CALL_SUBTEST(test_tensor_randacc())