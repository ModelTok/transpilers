/**
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
from optimize import testoptclass
from math import sqrt, pow, fabs
from random import rand, srand
from time import time
from memory import memset_zero
from utils import Vector, VectorVector

@value
struct testoptclass:
    var call_count: Int

    def __init__(inout self):
        self.call_count = 0
        srand(UInt32(time()))

    def reset_counter(inout self):
        self.call_count = 0

    def random_start(inout self, inout x: Vector[Float64], inout range: VectorVector[Float64]):
        var n = Int(x.size)
        for i in range(n):
            var rmax = range[i][1]
            var rmin = range[i][0]
            var r = rand()
            var fr = Float64(r) / Float64(RAND_MAX)
            x[i] = rmin + fr * (rmax - rmin)

    def memfunc(inout self, n: UInt, x: Pointer[Float64, 0], grad: Pointer[Float64, 0], my_func_data: Pointer[None, 0]) -> Float64:
        self.call_count += 1
        return sqrt(x[1])

    def styb_tang_test(inout self, n: UInt, x: Pointer[Float64, 0], grad: Pointer[Float64, 0], data: Pointer[None, 0]) -> Float64:
        /* x* = {-2.903534, .....}, f(x*) = -39.16599*n */
        var y = 0.0
        for i in range(n):
            y += pow(x[i], 4) - 16.0 * pow(x[i], 2) + 5.0 * x[i]
        y *= 0.5
        self.call_count += 1
        return y

    def rosenbrock_test(inout self, n: UInt, x: Pointer[Float64, 0], grad: Pointer[Float64, 0], data: Pointer[None, 0]) -> Float64:
        var y = 0.0
        for i in range(1, n):
            y += pow(x[i] - pow(x[i-1], 2), 2) + pow(x[i-1] - 1.0, 2)
        self.call_count += 1
        return y

    def matyas_test(inout self, n: UInt, x: Pointer[Float64, 0], grad: Pointer[Float64, 0], data: Pointer[None, 0]) -> Float64:
        /* Convex.. Valid from -10..10. */
        self.call_count += 1
        var y = 0.0
        for i in range(n):
            y += 0.26 * pow(fabs(x[i]), Float64(n))
        var xx = 0.48
        for i in range(n):
            xx *= x[i]
        y += -xx
        return y

    def get_call_count(self) -> Int:
        return self.call_count