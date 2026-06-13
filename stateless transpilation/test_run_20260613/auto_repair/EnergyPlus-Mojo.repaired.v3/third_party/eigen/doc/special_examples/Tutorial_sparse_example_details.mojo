from Eigen import SparseMatrix, Triplet, VectorXd, ArrayXd, Array
from QtGui import QImage, qRgb

typealias SpMat = SparseMatrix[Float64]  # declares a column-major sparse matrix type of double
typealias T = Triplet[Float64]

def insertCoefficient(id: Int, i: Int, j: Int, w: Float64, inout coeffs: List[T], inout b: Vector[Float64], boundary: Vector[Float64]) -> None:
    let n = boundary.size()
    let id1 = i + j * n
    if i == -1 or i == n:
        b[id] -= w * boundary[j]  # constrained coefficient
    else if j == -1 or j == n:
        b[id] -= w * boundary[i]  # constrained coefficient
    else:
        coeffs.append(T(id, id1, w))  # unknown coefficient

def buildProblem(inout coefficients: List[T], inout b: Vector[Float64], n: Int) -> None:
    b.setZero()
    let boundary = ArrayXd.LinSpaced(n, 0, M_PI).sin().pow(2)
    for j in range(n):
        for i in range(n):
            let id = i + j * n
            insertCoefficient(id, i-1, j, -1, coefficients, b, boundary)
            insertCoefficient(id, i+1, j, -1, coefficients, b, boundary)
            insertCoefficient(id, i, j-1, -1, coefficients, b, boundary)
            insertCoefficient(id, i, j+1, -1, coefficients, b, boundary)
            insertCoefficient(id, i, j, 4, coefficients, b, boundary)

def saveAsBitmap(x: Vector[Float64], n: Int, filename: String) -> None:
    let bits = (x * 255).cast[UInt8]()  # Eigen::Array<unsigned char,Eigen::Dynamic,Eigen::Dynamic> bits = (x*255).cast<unsigned char>();
    let img = QImage(bits.data(), n, n, QImage.Format_Indexed8)
    img.setColorCount(256)
    for i in range(256):
        img.setColor(i, qRgb(i, i, i))
    img.save(filename)