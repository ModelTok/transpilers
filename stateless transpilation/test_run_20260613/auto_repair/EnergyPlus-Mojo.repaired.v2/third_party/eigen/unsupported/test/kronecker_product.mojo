# EIGEN_TEST_PART_1
from sparse import *
from Eigen.SparseExtra import *
from Eigen.KroneckerProduct import *

def check_dimension[MatrixType: AnyType](ab: MatrixType, rows: Int, cols: Int):
    VERIFY_IS_EQUAL(ab.rows(), rows)
    VERIFY_IS_EQUAL(ab.cols(), cols)

def check_kronecker_product[MatrixType: AnyType](ab: MatrixType):
    VERIFY_IS_EQUAL(ab.rows(), 6)
    VERIFY_IS_EQUAL(ab.cols(), 6)
    VERIFY_IS_EQUAL(ab.nonZeros(), 36)
    VERIFY_IS_APPROX(ab.coeff(0,0), -0.4017367630386106)
    VERIFY_IS_APPROX(ab.coeff(0,1), 0.1056863433932735)
    VERIFY_IS_APPROX(ab.coeff(0,2), -0.7255206194554212)
    VERIFY_IS_APPROX(ab.coeff(0,3), 0.1908653336744706)
    VERIFY_IS_APPROX(ab.coeff(0,4), 0.350864567234111)
    VERIFY_IS_APPROX(ab.coeff(0,5), -0.0923032108308013)
    VERIFY_IS_APPROX(ab.coeff(1,0), 0.415417514804677)
    VERIFY_IS_APPROX(ab.coeff(1,1), -0.2369227701722048)
    VERIFY_IS_APPROX(ab.coeff(1,2), 0.7502275131458511)
    VERIFY_IS_APPROX(ab.coeff(1,3), -0.4278731019742696)
    VERIFY_IS_APPROX(ab.coeff(1,4), -0.3628129162264507)
    VERIFY_IS_APPROX(ab.coeff(1,5), 0.2069210808481275)
    VERIFY_IS_APPROX(ab.coeff(2,0), 0.05465890160863986)
    VERIFY_IS_APPROX(ab.coeff(2,1), -0.2634092511419858)
    VERIFY_IS_APPROX(ab.coeff(2,2), 0.09871180285793758)
    VERIFY_IS_APPROX(ab.coeff(2,3), -0.4757066334017702)
    VERIFY_IS_APPROX(ab.coeff(2,4), -0.04773740823058334)
    VERIFY_IS_APPROX(ab.coeff(2,5), 0.2300535609645254)
    VERIFY_IS_APPROX(ab.coeff(3,0), -0.8172945853260133)
    VERIFY_IS_APPROX(ab.coeff(3,1), 0.2150086428359221)
    VERIFY_IS_APPROX(ab.coeff(3,2), 0.5825113847292743)
    VERIFY_IS_APPROX(ab.coeff(3,3), -0.1532433770097174)
    VERIFY_IS_APPROX(ab.coeff(3,4), -0.329383387282399)
    VERIFY_IS_APPROX(ab.coeff(3,5), 0.08665207912033064)
    VERIFY_IS_APPROX(ab.coeff(4,0), 0.8451267514863225)
    VERIFY_IS_APPROX(ab.coeff(4,1), -0.481996458918977)
    VERIFY_IS_APPROX(ab.coeff(4,2), -0.6023482390791535)
    VERIFY_IS_APPROX(ab.coeff(4,3), 0.3435339347164565)
    VERIFY_IS_APPROX(ab.coeff(4,4), 0.3406002157428891)
    VERIFY_IS_APPROX(ab.coeff(4,5), -0.1942526344200915)
    VERIFY_IS_APPROX(ab.coeff(5,0), 0.1111982482925399)
    VERIFY_IS_APPROX(ab.coeff(5,1), -0.5358806424754169)
    VERIFY_IS_APPROX(ab.coeff(5,2), -0.07925446559335647)
    VERIFY_IS_APPROX(ab.coeff(5,3), 0.3819388757769038)
    VERIFY_IS_APPROX(ab.coeff(5,4), 0.04481475387219876)
    VERIFY_IS_APPROX(ab.coeff(5,5), -0.2159688616158057)

def check_sparse_kronecker_product[MatrixType: AnyType](ab: MatrixType):
    VERIFY_IS_EQUAL(ab.rows(), 12)
    VERIFY_IS_EQUAL(ab.cols(), 10)
    VERIFY_IS_EQUAL(ab.nonZeros(), 3*2)
    VERIFY_IS_APPROX(ab.coeff(3,0), -0.04)
    VERIFY_IS_APPROX(ab.coeff(5,1), 0.05)
    VERIFY_IS_APPROX(ab.coeff(0,6), -0.08)
    VERIFY_IS_APPROX(ab.coeff(2,7), 0.10)
    VERIFY_IS_APPROX(ab.coeff(6,8), 0.12)
    VERIFY_IS_APPROX(ab.coeff(8,9), -0.15)

def test_kronecker_product():
    var DM_a: Matrix[float64, 2, 3]
    var SM_a: SparseMatrix[float64] = SparseMatrix[float64](2,3)
    SM_a.insert(0,0) = DM_a.coeffRef(0,0) = -0.4461540300782201
    SM_a.insert(0,1) = DM_a.coeffRef(0,1) = -0.8057364375283049
    SM_a.insert(0,2) = DM_a.coeffRef(0,2) = 0.3896572459516341
    SM_a.insert(1,0) = DM_a.coeffRef(1,0) = -0.9076572187376921
    SM_a.insert(1,1) = DM_a.coeffRef(1,1) = 0.6469156566545853
    SM_a.insert(1,2) = DM_a.coeffRef(1,2) = -0.3658010398782789
    var DM_b: MatrixXd = MatrixXd(3,2)
    var SM_b: SparseMatrix[float64] = SparseMatrix[float64](3,2)
    SM_b.insert(0,0) = DM_b.coeffRef(0,0) = 0.9004440976767099
    SM_b.insert(0,1) = DM_b.coeffRef(0,1) = -0.2368830858139832
    SM_b.insert(1,0) = DM_b.coeffRef(1,0) = -0.9311078389941825
    SM_b.insert(1,1) = DM_b.coeffRef(1,1) = 0.5310335762980047
    SM_b.insert(2,0) = DM_b.coeffRef(2,0) = -0.1225112806872035
    SM_b.insert(2,1) = DM_b.coeffRef(2,1) = 0.5903998022741264
    var SM_row_a: SparseMatrix[float64, RowMajor] = SparseMatrix[float64, RowMajor](SM_a)
    var SM_row_b: SparseMatrix[float64, RowMajor] = SparseMatrix[float64, RowMajor](SM_b)
    var DM_fix_ab: Matrix[float64, 6, 6] = kroneckerProduct(DM_a.topLeftCorner[2,3](), DM_b)
    CALL_SUBTEST(check_kronecker_product(DM_fix_ab))
    CALL_SUBTEST(check_kronecker_product(kroneckerProduct(DM_a.topLeftCorner[2,3](), DM_b)))
    for i in range(DM_fix_ab.rows()):
        for j in range(DM_fix_ab.cols()):
            VERIFY_IS_APPROX(kroneckerProduct(DM_a, DM_b).coeff(i, j), DM_fix_ab(i, j))
    var DM_block_ab: MatrixXd = MatrixXd(10,15)
    DM_block_ab.block[6,6](2,5) = kroneckerProduct(DM_a, DM_b)
    CALL_SUBTEST(check_kronecker_product(DM_block_ab.block[6,6](2,5)))
    var DM_ab: MatrixXd = kroneckerProduct(DM_a, DM_b)
    CALL_SUBTEST(check_kronecker_product(DM_ab))
    CALL_SUBTEST(check_kronecker_product(kroneckerProduct(DM_a, DM_b)))
    var SM_ab: SparseMatrix[float64] = kroneckerProduct(SM_a, DM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab))
    var SM_ab2: SparseMatrix[float64, RowMajor] = kroneckerProduct(SM_a, DM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab2))
    CALL_SUBTEST(check_kronecker_product(kroneckerProduct(SM_a, DM_b)))
    SM_ab.setZero()
    SM_ab.insert(0,0) = 37.0
    SM_ab = kroneckerProduct(DM_a, SM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab))
    SM_ab2.setZero()
    SM_ab2.insert(0,0) = 37.0
    SM_ab2 = kroneckerProduct(DM_a, SM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab2))
    CALL_SUBTEST(check_kronecker_product(kroneckerProduct(DM_a, SM_b)))
    SM_ab.resize(2,33)
    SM_ab.insert(0,0) = 37.0
    SM_ab = kroneckerProduct(SM_a, SM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab))
    SM_ab2.resize(5,11)
    SM_ab2.insert(0,0) = 37.0
    SM_ab2 = kroneckerProduct(SM_a, SM_b)
    CALL_SUBTEST(check_kronecker_product(SM_ab2))
    CALL_SUBTEST(check_kronecker_product(kroneckerProduct(SM_a, SM_b)))
    SM_a.resize(4,5)
    SM_b.resize(3,2)
    SM_a.resizeNonZeros(0)
    SM_b.resizeNonZeros(0)
    SM_a.insert(1,0) = -0.1
    SM_a.insert(0,3) = -0.2
    SM_a.insert(2,4) = 0.3
    SM_a.finalize()
    SM_b.insert(0,0) = 0.4
    SM_b.insert(2,1) = -0.5
    SM_b.finalize()
    SM_ab.resize(1,1)
    SM_ab.insert(0,0) = 37.0
    SM_ab = kroneckerProduct(SM_a, SM_b)
    CALL_SUBTEST(check_sparse_kronecker_product(SM_ab))
    var DM_a2: MatrixXd = MatrixXd(2,1)
    var DM_b2: MatrixXd = MatrixXd(5,4)
    var DM_ab2: MatrixXd = kroneckerProduct(DM_a2, DM_b2)
    CALL_SUBTEST(check_dimension(DM_ab2, 2*5, 1*4))
    DM_a2.resize(10,9)
    DM_b2.resize(4,8)
    DM_ab2 = kroneckerProduct(DM_a2, DM_b2)
    CALL_SUBTEST(check_dimension(DM_ab2, 10*4, 9*8))
    for i in range(g_repeat):
        var density: float64 = Eigen.internal.random[float64](0.01, 0.5)
        var ra: Int = Eigen.internal.random[Int](1, 50)
        var ca: Int = Eigen.internal.random[Int](1, 50)
        var rb: Int = Eigen.internal.random[Int](1, 50)
        var cb: Int = Eigen.internal.random[Int](1, 50)
        var sA: SparseMatrix[float32, ColMajor] = SparseMatrix[float32, ColMajor](ra, ca)
        var sB: SparseMatrix[float32, ColMajor] = SparseMatrix[float32, ColMajor](rb, cb)
        var sC: SparseMatrix[float32, ColMajor]
        var sC2: SparseMatrix[float32, RowMajor]
        var dA: MatrixXf = MatrixXf(ra, ca)
        var dB: MatrixXf = MatrixXf(rb, cb)
        var dC: MatrixXf
        initSparse(density, dA, sA)
        initSparse(density, dB, sB)
        sC = kroneckerProduct(sA, sB)
        dC = kroneckerProduct(dA, dB)
        VERIFY_IS_APPROX(MatrixXf(sC), dC)
        sC = kroneckerProduct(sA.transpose(), sB)
        dC = kroneckerProduct(dA.transpose(), dB)
        VERIFY_IS_APPROX(MatrixXf(sC), dC)
        sC = kroneckerProduct(sA.transpose(), sB.transpose())
        dC = kroneckerProduct(dA.transpose(), dB.transpose())
        VERIFY_IS_APPROX(MatrixXf(sC), dC)
        sC = kroneckerProduct(sA, sB.transpose())
        dC = kroneckerProduct(dA, dB.transpose())
        VERIFY_IS_APPROX(MatrixXf(sC), dC)
        sC2 = kroneckerProduct(sA, sB)
        dC = kroneckerProduct(dA, dB)
        VERIFY_IS_APPROX(MatrixXf(sC2), dC)
        sC2 = kroneckerProduct(dA, sB)
        dC = kroneckerProduct(dA, dB)
        VERIFY_IS_APPROX(MatrixXf(sC2), dC)
        sC2 = kroneckerProduct(sA, dB)
        dC = kroneckerProduct(dA, dB)
        VERIFY_IS_APPROX(MatrixXf(sC2), dC)
        sC2 = kroneckerProduct(2*sA, sB)
        dC = kroneckerProduct(2*dA, dB)
        VERIFY_IS_APPROX(MatrixXf(sC2), dC)

# EIGEN_TEST_PART_2
from main import *
from Eigen.KroneckerProduct import *

def test_kronecker_product():
    var a: MatrixXd = MatrixXd(2,2)
    var b: MatrixXd = MatrixXd(3,3)
    var c: MatrixXd
    a.setRandom()
    b.setRandom()
    c = kroneckerProduct(a, b)
    VERIFY_IS_APPROX(c.block(3,3,3,3), a(1,1)*b)