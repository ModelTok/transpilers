from Eigen.Dense import ArrayXXf
from iostream import cout
from Eigen import *
from std import *

def main():
    var a = ArrayXXf(2, 2)
    var b = ArrayXXf(2, 2)
    a << 1, 2,
         3, 4
    b << 5, 6,
         7, 8
    cout << "a * b = " << endl << a * b << endl