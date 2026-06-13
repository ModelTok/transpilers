from Eigen import MatrixXf, HouseholderQR

var A: MatrixXf = MatrixXf.Random(5, 3)
var thinQ: MatrixXf = MatrixXf.Identity(5, 3)
var Q: MatrixXf
A.setRandom()
var qr: HouseholderQR[MatrixXf] = HouseholderQR[MatrixXf](A)
Q = qr.householderQ()
thinQ = qr.householderQ() * thinQ
print("The complete unitary matrix Q is:\n", Q, "\n\n")
print("The thin matrix Q is:\n", thinQ, "\n\n")