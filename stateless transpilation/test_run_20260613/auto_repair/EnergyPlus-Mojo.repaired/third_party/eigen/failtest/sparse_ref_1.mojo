from ...Eigen.Sparse import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
# using namespace Eigen;
def call_ref(a: Ref[SparseMatrix[float32]]): pass
def main():
    var a = SparseMatrix[float32](10, 10)
    # CV_QUALIFIER SparseMatrix<float>& ac(a)
    var ac: Ref[SparseMatrix[float32]] = Ref(a)
    call_ref(ac)