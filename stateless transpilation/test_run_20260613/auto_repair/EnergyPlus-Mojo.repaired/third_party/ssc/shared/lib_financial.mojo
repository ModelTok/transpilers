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
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL THE COPYRIGHT HOLDER, CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES
DEPARTMENT OF ENERGY, NOR ANY OF THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

from math import pow, exp, log, abs
from sys import max_int, min_int

# financial code here
# ported from http://code.google.com/p/irr-newtonraphson-calculator/
def is_valid_iter_bound(estimatedReturnRate: Float64) -> Bool:
    return estimatedReturnRate != -1 and (estimatedReturnRate < max_int) and (estimatedReturnRate > min_int)

def irr_poly_sum(estimatedReturnRate: Float64, CashFlows: List[Float64], Count: Int) -> Float64:
    var sumOfPolynomial: Float64 = 0
    if is_valid_iter_bound(estimatedReturnRate):
        for j in range(Count):
            if j >= len(CashFlows):
                break
            var val: Float64 = pow((1 + estimatedReturnRate), j)
            if val != 0.0:
                sumOfPolynomial += CashFlows[j] / val
            else:
                break
    return sumOfPolynomial

def irr_derivative_sum(estimatedReturnRate: Float64, CashFlows: List[Float64], Count: Int) -> Float64:
    var sumOfDerivative: Float64 = 0
    if is_valid_iter_bound(estimatedReturnRate):
        for i in range(1, Count):
            if i >= len(CashFlows):
                break
            sumOfDerivative += CashFlows[i] * i / pow((1 + estimatedReturnRate), i)
    return sumOfDerivative * -1

def irr(tolerance: Float64, maxIterations: Int, CashFlows: List[Float64], Count: Int) -> Float64:
    # Validation check - can write to log if move to FinModel or include SimModel
    # if ((count < 2) || (CashFlows[0] > 0))
    # {
    #     Messages.Add( "Cash flow for the first period  must be negative and there should");
    # }
    var numberOfIterations: Int = 0
    var calculatedIRR: Float64 = 0
    var initialGuess: Float64 = 0.1  # 10% is default used in Excel IRR function
    if len(CashFlows) < 3:
        return initialGuess
    if (Count > 1) and (CashFlows[0] <= 0):
        var deriv_sum: Float64 = irr_derivative_sum(initialGuess, CashFlows, Count)
        if deriv_sum != 0:
            calculatedIRR = initialGuess - irr_poly_sum(initialGuess, CashFlows, Count) / deriv_sum
        else:
            return initialGuess
        numberOfIterations += 1
        while not (abs(irr_poly_sum(calculatedIRR, CashFlows, Count)) <= tolerance) and (numberOfIterations < maxIterations):
            deriv_sum = irr_derivative_sum(initialGuess, CashFlows, Count)
            if deriv_sum != 0.0:
                calculatedIRR = calculatedIRR - irr_poly_sum(calculatedIRR, CashFlows, Count) / deriv_sum
            else:
                break
            numberOfIterations += 1
    return calculatedIRR

# ported directly from Delphi simple geometric sum
def npv(Rate: Float64, CashFlows: List[Float64], Count: Int) -> Float64:
    # { Caution: The sign of NPV is reversed from what would be expected for standard
    #    cash flows!}
    if Rate <= -1.0:
        return -999
    var cnt: Int = Count
    if cnt > len(CashFlows):
        cnt = len(CashFlows)
    var rr: Float64 = 1 / (1 + Rate)
    var result: Float64 = 0
    for i in range(cnt - 1, 0, -1):
        result = rr * result + CashFlows[i]
    return result * rr  # assumes end of period payments!!

def payback(CumulativePayback: List[Float64], Payback: List[Float64], Count: Int) -> Float64:
    # Return payback in years of inputs streams
    # Payback occures when cumulative stream is > 0
    # Find exact payback by subtracting cumulative / payback
    var dPayback: Float64 = 1e99  # report as > analysis period
    var bolPayback: Bool = False
    var iPayback: Int = 0
    var i: Int = 1
    while (i < Count) and (not bolPayback):
        if CumulativePayback[i] > 0:
            bolPayback = True
            iPayback = i
        i += 1
    if bolPayback:
        if Payback[iPayback] != 0:
            dPayback = iPayback - CumulativePayback[iPayback] / Payback[iPayback]
        else:
            dPayback = iPayback
    return dPayback

# code source http://www.linkedin.com/answers/technology/software-development/TCH_SFT/445353-4527099?browseCategory=TCH_SFT
# Returns the payment on the principal for a given period for an investment based on periodic, constant payments and a constant interest rate.
# Syntax
# PPMT(rate,per,nper,pv,fv,type)
# For a more complete description of the arguments in PPMT, see PV.
# Rate   is the interest rate per period.
# Per   specifies the period and must be in the range 1 to nper.
# Nper   is the total number of payment periods in an annuity.
# Pv   is the present value  the total amount that a series of future payments is worth now.
# Fv   is the future value, or a cash balance you want to attain after the last payment is made. If fv is omitted, it is assumed to be 0 (zero), that is, the future value of a loan is 0.
# Type   is the number 0 or 1 and indicates when payments are due.
# Set type equal to If payments are due
# 0 or omitted At the end of the period
# 1 At the beginning of the period
# Remark
# Make sure that you are consistent about the units you use for specifying rate and nper. If you make monthly payments on a four-year loan at 12 percent annual interest, use 12%/12 for rate and 4*12 for nper. If you make annual payments on the same loan, use 12% for rate and 4 for nper.

def pow1pm1(x: Float64, y: Float64) -> Float64:
    return pow(1 + x, y) - 1 if (x <= -1) else exp(y * log(1.0 + x)) - 1

def pow1p(x: Float64, y: Float64) -> Float64:
    return pow(1 + x, y) if (abs(x) > 0.5) else exp(y * log(1.0 + x))

def fvifa(rate: Float64, nper: Float64) -> Float64:
    return nper if (rate == 0) else pow1pm1(rate, nper) / rate

def pvif(rate: Float64, nper: Float64) -> Float64:
    return pow1p(rate, nper)

def pmt(rate: Float64, nper: Float64, pv: Float64, fv: Float64, type: Int) -> Float64:
    return (-pv * pvif(rate, nper) - fv) / ((1.0 + rate * type) * fvifa(rate, nper))

def ipmt(rate: Float64, per: Float64, nper: Float64, pv: Float64, fv: Float64, type: Int) -> Float64:
    var p: Float64 = pmt(rate, nper, pv, fv, 0)
    var ip: Float64 = -(pv * pow1p(rate, per - 1) * rate + p * pow1pm1(rate, per - 1))
    return ip if (type == 0) else ip / (1 + rate)

def ppmt(rate: Float64, per: Float64, nper: Float64, pv: Float64, fv: Float64, type: Int) -> Float64:
    if nper == 0:
        return 0.0
    var p: Float64 = pmt(rate, nper, pv, fv, type)
    var ip: Float64 = ipmt(rate, per, nper, pv, fv, type)
    return p - ip

def round_irs(number: Float64) -> Int:
    return (number + 0.5) if (number >= 0) else (number - 0.5)