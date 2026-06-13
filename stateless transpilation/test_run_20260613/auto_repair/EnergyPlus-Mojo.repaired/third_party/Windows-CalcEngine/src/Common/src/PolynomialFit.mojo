from PolynomialFit import PolynomialFit
from memory import memset_zero
from math import pow as std_pow
from vector import DynamicVector as std_vector
from utils import Pair as std_pair

def PolynomialFit.PolynomialFit(inout self, t_Order: size_t):
    self.m_Order = t_Order

def PolynomialFit.getCoefficients(self, t_Table: std_vector[std_pair[float64, float64]]) -> std_vector[float64]:
    var n: int = int(self.m_Order)
    var x: std_vector[float64] = std_vector[float64](2 * n + 1)
    var i: int = 0
    while i < 2 * n + 1:
        x[i] = 0.0
        var j: int = 0
        while j < int(t_Table.size):
            x[i] = x[i] + std_pow(t_Table[j].first, i)
            j += 1
        i += 1
    var B: std_vector[std_vector[float64]] = std_vector[std_vector[float64]](n + 1)
    var vec_idx: int = 0
    while vec_idx < len(B):
        B[vec_idx] = std_vector[float64](n + 2)
        vec_idx += 1
    var a: std_vector[float64] = std_vector[float64](n + 1)
    i = 0
    while i <= n:
        var j: int = 0
        while j <= n:
            B[i][j] = x[i + j]
            j += 1
        i += 1
    var Y: std_vector[float64] = std_vector[float64](n + 1)
    i = 0
    while i < n + 1:
        Y[i] = 0.0
        var j: int = 0
        while j < int(t_Table.size):
            Y[i] = Y[i] + std_pow(t_Table[j].first, i) * t_Table[j].second
            j += 1
        i += 1
    i = 0
    while i <= n:
        B[i][n + 1] = Y[i]
        i += 1
    n += 1
    i = 0
    while i < n:
        var k: int = i + 1
        while k < n:
            if B[i][i] < B[k][i]:
                var j: int = 0
                while j <= n:
                    var temp: float64 = B[i][j]
                    B[i][j] = B[k][j]
                    B[k][j] = temp
                    j += 1
            k += 1
        i += 1
    i = 0
    while i < n - 1:
        var k: int = i + 1
        while k < n:
            var t: float64 = B[k][i] / B[i][i]
            var j: int = 0
            while j <= n:
                B[k][j] = B[k][j] - t * B[i][j]
                j += 1
            k += 1
        i += 1
    i = n - 1
    while i >= 0:
        a[i] = B[i][n]
        var j: int = 0
        while j < n:
            if j != i:
                a[i] = a[i] - B[i][j] * a[j]
            j += 1
        a[i] = a[i] / B[i][i]
        i -= 1
    return a