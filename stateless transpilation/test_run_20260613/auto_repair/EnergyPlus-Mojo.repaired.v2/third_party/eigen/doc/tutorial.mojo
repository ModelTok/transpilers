from memory import memset_zero
from math import cos
from sys import info as sys_info

def main() raises:
    print_precision(2)
    var m3 = Matrix3f.random()
    var m4 = Matrix4f.identity()
    print("*** Step 1 ***\nm3:\n", m3, "\nm4:\n", m4)
    m4.setZero()
    m3.diagonal().setOnes()
    print("*** Step 2 ***\nm3:\n", m3, "\nm4:\n", m4)
    m4.block[3,3](0,1) = m3
    m3.row(2) = m4.block[1,3](2,0)
    print("*** Step 3 ***\nm3:\n", m3, "\nm4:\n", m4)
    {
        var rows = 3
        var cols = 3
        m4.block(0,1,3,3).setIdentity()
        print("*** Step 4 ***\nm4:\n", m4)
    }
    m4.diagonal().block(1,2).setOnes()
    print("*** Step 5 ***\nm4.diagonal():\n", m4.diagonal())
    print("m4.diagonal().start(3)\n", m4.diagonal().start(3))
    m4 = m4.cwise() * m4
    m3 = m3.cwise().cos()
    print("*** Step 6 ***\nm3:\n", m3, "\nm4:\n", m4)
    print("*** Step 7 ***\n m4.sum(): ", m4.sum())
    print("m4.col(2).sum(): ", m4.col(2).sum())
    print("m4.colwise().sum():\n", m4.colwise().sum())
    print("m4.rowwise().sum():\n", m4.rowwise().sum())
    m4 = m4 * m4
    var other = (m4 * m4).lazy()
    m4 = m4 + m4
    m4 = -m4 + m4 + 5 * m4
    m4 = m4 * (m4 + m4)
    m3 = m3 * m4.block[3,3](1,1)
    m4 = m4 * m4.transpose()
    m4 = m4 * m4.transpose().eval()
    print("*** Step 8 ***\nm3:\n", m3, "\nm4:\n", m4)