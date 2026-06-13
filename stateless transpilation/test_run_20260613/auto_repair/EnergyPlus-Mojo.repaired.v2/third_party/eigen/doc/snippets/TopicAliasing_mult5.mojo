from third_party.eigen.doc.snippets.MatrixXf import MatrixXf

def main():
    var A = MatrixXf(2, 2)
    var B = MatrixXf(3, 2)
    B << 2, 0,  0, 3, 1, 1
    A << 2, 0, 0, -2
    A = (B * A).eval().cwiseAbs()
    print(A)