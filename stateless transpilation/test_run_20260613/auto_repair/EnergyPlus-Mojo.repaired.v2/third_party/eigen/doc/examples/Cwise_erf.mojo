from Eigen.Core import Array4d
from unsupported.Eigen.SpecialFunctions import *

def main():
    let v = Array4d(-0.5, 2, 0, -7)
    print(v.erf())