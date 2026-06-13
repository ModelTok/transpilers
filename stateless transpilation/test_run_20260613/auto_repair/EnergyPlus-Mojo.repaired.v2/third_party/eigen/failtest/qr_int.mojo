from ...Eigen.QR import *
alias EIGEN_SHOULD_FAIL_TO_BUILD = True
alias SCALAR = Int32
def main():
  var qr = HouseholderQR[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10,10))