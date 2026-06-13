from third_party.eigen.Eigen import Matrix4i, Matrix4i_Zero, Matrix4i_Block

def main():
    var m = Matrix4i_Zero()
    m.block[3,3](1,0).setIdentity()
    print(m)