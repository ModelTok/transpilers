from Eigen.Sparse import SparseMatrix, Ref

# #include "../Eigen/Sparse"
# using namespace Eigen;

def call_ref(a: Ref[SparseMatrix[float32]]) raises:

# int main()
def main() raises:
    var a = SparseMatrix[float32](10, 10)
    call_ref(a + a)