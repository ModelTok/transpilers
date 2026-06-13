from ...Eigen.QR import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define SCALAR int
# else
# define SCALAR float
# endif
# using namespace Eigen
def main():
    var qr = FullPivHouseholderQR[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10,10))