from memory import memset
from random import randint
from sys import info
from utils import print

def main() raises:
    let N: Int = 5
    var A = MatrixXi(N, N)
    A.setRandom()
    print("A =\n", A, "\n")
    print("A(:,1..3) =\n", A.middleCols[3](1))