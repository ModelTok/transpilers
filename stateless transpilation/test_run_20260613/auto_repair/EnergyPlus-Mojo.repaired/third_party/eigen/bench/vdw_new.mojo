from memory import memset_zero
from math import sqrt, pow, cube, square
from sys import print

# SCALAR type alias
alias SCALAR = Float32

# SIZE constant
alias SIZE = 10000

# REPEAT constant
alias REPEAT = 10000

# Vec type alias
alias Vec = DynamicVector[SCALAR]

def E_VDW(interactions1: Vec, interactions2: Vec) -> SCALAR:
    var result: SCALAR = 0.0
    for i in range(interactions1.size):
        var val = interactions2[i] / interactions1[i]
        val = val * val * val  # cube
        val = val * val        # square
        val = val * val        # square
        result += val
    return result

def main() raises:
    var interactions1 = Vec(SIZE)
    var interactions2 = Vec(SIZE)
    var rab: SCALAR = 1.0
    for i in range(SIZE):
        interactions1[i] = 2.4
        interactions2[i] = rab
    var energy: SCALAR = 0.0
    for i in range(REPEAT):
        energy += E_VDW(interactions1, interactions2)
        energy *= 1 + 1e-20 * i
    print("energy =", energy)