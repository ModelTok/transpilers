from Eigen import Matrix4d, HessenbergDecomposition, Vector3d
from iostream import cout, endl

let A = Matrix4d.Random(4,4)
cout << "Here is a random 4x4 matrix:" << endl << A << endl
let hessOfA = HessenbergDecomposition[Matrix4d](A)
let pm = hessOfA.packedMatrix()
cout << "The packed matrix M is:" << endl << pm << endl
cout << "The upper Hessenberg part corresponds to the matrix H, which is:" << endl << hessOfA.matrixH() << endl
let hc = hessOfA.householderCoefficients()
cout << "The vector of Householder coefficients is:" << endl << hc << endl