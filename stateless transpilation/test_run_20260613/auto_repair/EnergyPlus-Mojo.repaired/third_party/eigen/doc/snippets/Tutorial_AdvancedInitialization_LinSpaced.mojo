from memory import memset_zero
from math import pi
from sys import print

def main() raises:
    var table = ArrayXXf(10, 4)
    table.col(0) = ArrayXf.LinSpaced(10, 0, 90)
    table.col(1) = pi / 180 * table.col(0)
    table.col(2) = table.col(1).sin()
    table.col(3) = table.col(1).cos()
    print("  Degrees   Radians      Sine    Cosine")
    print(table)