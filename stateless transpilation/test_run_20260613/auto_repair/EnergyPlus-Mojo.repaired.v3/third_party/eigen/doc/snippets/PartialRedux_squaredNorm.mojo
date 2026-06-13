from stdlib import matrix
from stdlib.random import random
from stdlib.print import print

def main() raises:
    var m = matrix.Matrix[float64](3, 3)
    for i in range(3):
        for j in range(3):
            m[i, j] = random() * 2.0 - 1.0
    print("Here is the matrix m:")
    print(m)
    print("Here is the square norm of each row:")
    var row_norms = matrix.Matrix[float64](3, 1)
    for i in range(3):
        var sum_sq = 0.0
        for j in range(3):
            sum_sq += m[i, j] * m[i, j]
        row_norms[i, 0] = sum_sq
    print(row_norms)