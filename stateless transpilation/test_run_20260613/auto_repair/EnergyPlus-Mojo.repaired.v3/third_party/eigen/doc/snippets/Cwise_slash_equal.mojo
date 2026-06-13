from builtin import print

def main():
    var v = SIMD[Float64, 3](3, 2, 4)
    var w = SIMD[Float64, 3](5, 4, 2)
    v /= w
    print(v)