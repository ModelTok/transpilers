from third_party.eigen.Eigen import Matrix4i, cout, endl

def main():
    var m = Matrix4i.Random()
    m.row(1).setOnes()
    cout << m << endl