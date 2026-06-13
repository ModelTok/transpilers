from memory import memset
from math import sqrt, abs, sin, cos, tan, asin, acos, atan, exp, log, pow, floor, ceil, mod
from complex import Complex
from random import random
from sys import print

# Eigen-like matrix types for Mojo
struct Matrix4d:
    var data: SIMD[float64, 16]
    
    def __init__(inout self):
        self.data = SIMD[float64, 16](0.0)
    
    def __init__(inout self, val: SIMD[float64, 16]):
        self.data = val
    
    def __getitem__(self, i: Int, j: Int) -> float64:
        return self.data[i * 4 + j]
    
    def __setitem__(inout self, i: Int, j: Int, val: float64):
        self.data[i * 4 + j] = val
    
    def block[rows: Int, cols: Int](self, start_row: Int, start_col: Int) -> Matrix4d:
        var result = Matrix4d()
        for i in range(rows):
            for j in range(cols):
                result[i, j] = self[start_row + i, start_col + j]
        return result
    
    def block_assign[rows: Int, cols: Int](inout self, start_row: Int, start_col: Int, other: Matrix4d):
        for i in range(rows):
            for j in range(cols):
                self[start_row + i, start_col + j] = other[i, j]

struct Vector4d:
    var data: SIMD[float64, 4]
    
    def __init__(inout self, a: float64, b: float64, c: float64, d: float64):
        self.data = SIMD[float64, 4](a, b, c, d)
    
    def asDiagonal(self) -> Matrix4d:
        var m = Matrix4d()
        for i in range(4):
            m[i, i] = self.data[i]
        return m

def main():
    var m = Vector4d(1.0, 2.0, 3.0, 4.0).asDiagonal()
    print("Here is the matrix m:")
    print(m)
    print("Here is m.fixed<2, 2>(2, 2):")
    print(m.block[2, 2](2, 2))
    m.block_assign[2, 2](2, 0, m.block[2, 2](2, 2))
    print("Now the matrix m is:")
    print(m)