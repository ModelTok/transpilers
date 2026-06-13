from Eigen.Core import Array4d
from unsupported.Eigen.SpecialFunctions import lgamma
from iostream import std
using Eigen

def main():
    var v = Array4d(0.5, 10, 0, -1)
    std.cout << v.lgamma() << std.endl