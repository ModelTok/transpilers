// BSD-3-Clause
// Copyright 2019 Alliance for Sustainable Energy, LLC
// Redistribution and use in source and binary forms, with or without modification, are permitted provided 
// that the following conditions are met :
// 1.	Redistributions of source code must retain the above copyright notice, this list of conditions 
// and the following disclaimer.
// 2.	Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
// and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3.	Neither the name of the copyright holder nor the names of its contributors may be used to endorse 
// or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES 
// DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
// OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from tcstype import (
    tcscontext, tcstypeinfo, tcstypeinterface, tcsvarinfo,
    TCS_INPUT, TCS_OUTPUT, TCS_NUMBER, TCS_INVALID,
    TCS_ERROR, TCS_IMPLEMENT_TYPE
)

alias I_A = 0
alias I_B = 1
alias O_S = 2
alias O_P = 3
alias N_MAX = 4

alias sumprod_variables = List[tcsvarinfo](
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_A, "a", "Data 1", "", "", "", ""),
    tcsvarinfo(TCS_INPUT, TCS_NUMBER, I_B, "b", "Data 2", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_S, "sum", "Result of A+B", "", "", "", ""),
    tcsvarinfo(TCS_OUTPUT, TCS_NUMBER, O_P, "product", "Result of A*B", "", "", "", ""),
    tcsvarinfo(TCS_INVALID, TCS_INVALID, N_MAX, None, None, None, None, None, None)
)

class sumprod(tcstypeinterface):
    def __init__(self, cxt: tcscontext, ti: tcstypeinfo):
        super().__init__(cxt, ti)

    def init(self) -> Int:
        return 0

    def call(self, time: Float64, step: Float64, ncall: Int) -> Int:
        var a: Float64 = self.value(I_A)
        var b: Float64 = self.value(I_B)
        if a < -999:
            self.message(TCS_ERROR, f"invalid value for a: {a}")
            return -1
        self.value(O_S, a + b)
        self.value(O_P, a * b)
        return 0

TCS_IMPLEMENT_TYPE(sumprod, "Sums and Products", "Aron", 123, sumprod_variables, None, 0)