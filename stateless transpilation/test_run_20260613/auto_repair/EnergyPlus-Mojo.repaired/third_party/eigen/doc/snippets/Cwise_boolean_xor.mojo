from builtins import print

def main():
    var v = SIMD[f64, 3](-1, 2, 1)
    var w = SIMD[f64, 3](-3, 2, 3)
    print((v < w) ^ (v < 0))