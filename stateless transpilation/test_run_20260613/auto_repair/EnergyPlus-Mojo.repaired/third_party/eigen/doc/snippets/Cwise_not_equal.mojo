def main():
    var v = SIMD[Float64, 3](1, 2, 3)
    var w = SIMD[Float64, 3](3, 2, 1)
    print(v != w)