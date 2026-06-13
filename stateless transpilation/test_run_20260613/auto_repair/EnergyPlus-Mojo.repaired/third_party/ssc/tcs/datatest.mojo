"""
BSD-3-Clause
Copyright 2019 Alliance for Sustainable Energy, LLC
Redistribution and use in source and binary forms, with or without modification, are permitted provided 
that the following conditions are met :
1. Redistributions of source code must retain the above copyright notice, this list of conditions 
and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

from tcstype import (
    tcscontext, tcstypeinfo, tcstypeinterface, tcsvalue, tcsvarinfo,
    TCS_INPUT, TCS_NUMBER, TCS_ARRAY, TCS_MATRIX,
    TCS_OUTPUT, TCS_STRING, TCS_INVALID,
    TCS_MATRIX_INDEX,
)

let I_IN1: Int = 0
let I_IN2: Int = 1
let I_IN3: Int = 2
let I_IN4: Int = 3
let I_SCALE: Int = 4
let I_VEC: Int = 5
let I_MAT: Int = 6
let O_SUM: Int = 7
let O_VEC: Int = 8
let O_MAT: Int = 9
let O_STR: Int = 10
let N_MAX: Int = 11

var datatest_variables: List[tcsvarinfo] = List[tcsvarinfo](
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IN1, "input1", "Data 1", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IN2, "input2", "Data 2", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IN3, "input3", "Data 3", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_IN4, "input4", "Data 4", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_SCALE, "scale", "Scale", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_ARRAY, I_VEC, "vec_in", "ArrayI", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_MATRIX, I_MAT, "mat_in", "Matrix", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_SUM, "sum", "Sum", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_ARRAY, O_VEC, "vec_out", "Array", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_MATRIX, O_MAT, "mat_out", "Matrix", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_STRING, O_STR, "str_out", "String", "", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, None, None, None, None, None, None),
)

class datatest(tcstypeinterface):
    def __init__(inout self, cxt: tcscontext, ti: tcstypeinfo):
        super().__init__(cxt, ti)

    def __del__(owned self):

    def init(self) -> Int:
        var len: Int
        var vec = self.value(I_VEC, &len)
        self.allocate(O_VEC, 4)
        var nrows: Int
        var ncols: Int
        var mat = self.value(I_MAT, &nrows, &ncols)
        if mat and nrows > 0 and ncols > 0:
            self.allocate(O_MAT, nrows, ncols)
        return 0

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        var v: StaticFloat64[4] = StaticFloat64[4]()
        var scale = self.value(I_SCALE)
        v[0] = self.value(I_IN1)
        v[1] = self.value(I_IN2)
        v[2] = self.value(I_IN3)
        v[3] = self.value(I_IN4)

        var sum: Float64 = 0
        for i in range(4):
            sum += v[i]
        sum *= scale

        self.value(O_SUM, sum)

        var len: Int
        var vec = self.value(O_VEC, &len)
        if vec and len == 4:
            for i in range(4):
                vec[i] = v[3 - i]

        var inr: Int
        var inc: Int
        var onr: Int
        var onc: Int
        self.value(I_MAT, &inr, &inc)
        self.value(O_MAT, &onr, &onc)

        var imat = self.var(I_MAT)
        var omat = self.var(O_MAT)

        var matsum: Float64 = 0
        if omat and inr == onr and inc == onc and imat != None:
            for r in range(inr):
                for c in range(inc):
                    matsum += TCS_MATRIX_INDEX(imat, r, c)
                    TCS_MATRIX_INDEX(omat, r, c) = TCS_MATRIX_INDEX(imat, r, c) * scale

        var buf = String(" {:.2f} : {:.1f}, {:.1f}, {:.1f},{:.1f}".format(matsum, v[0], v[1], v[2], v[3]))
        self.value_str(O_STR, buf)

        return 0

TCS_IMPLEMENT_TYPE[datatest]("Data test", "Aron Dobos", 1, datatest_variables, None, 0)