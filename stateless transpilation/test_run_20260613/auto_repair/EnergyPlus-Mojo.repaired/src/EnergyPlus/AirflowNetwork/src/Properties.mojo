/* EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
 The Regents of the University of California, through Lawrence Berkeley National Laboratory
 (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
 National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
 contributors. All rights reserved.
 NOTICE: This Software was developed under funding from the U.S. Department of Energy and the
 U.S. Government consequently retains certain rights. As such, the U.S. Government has been
 granted for itself and others acting on its behalf a paid-up, nonexclusive, irrevocable,
 worldwide license in the Software to reproduce, distribute copies to the public, prepare
 derivative works, and perform publicly and display publicly, and to permit others to do so.
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 (1) Redistributions of source code must retain the above copyright notice, this list of
     conditions and the following disclaimer.
 (2) Redistributions in binary form must reproduce the above copyright notice, this list of
     conditions and the following disclaimer in the documentation and/or other materials
     provided with the distribution.
 (3) Neither the name of the University of California, Lawrence Berkeley National Laboratory,
     the University of Illinois, U.S. Dept. of Energy nor the names of its contributors may be
     used to endorse or promote products derived from this software without specific prior
     written permission.
 (4) Use of EnergyPlus(TM) Name. If Licensee (i) distributes the software in stand-alone form
     without changes from the version obtained under this License, or (ii) Licensee makes a
     reference solely to the software portion of its product, Licensee must refer to the
     software as "EnergyPlus version X" software, where "X" is the version number Licensee
     obtained under this License and may not use a different name for the software. Except as
     specifically required in this Section (4), Licensee shall not use in a company name, a
     product name, in advertising, publicity, or other promotional activities any name, trade
     name, trademark, logo, or other designation of "EnergyPlus", "E+", "e+" or confusingly
     similar designation, without the U.S. Department of Energy's prior written consent.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/
from ...Psychrometrics import PsyRhoAirFnPbTdbW
from ...Psychrometrics import AIRDENSITY_CONSTEXPR, AIRDYNAMICVISCOSITY_CONSTEXPR, AIRCP
from ...UtilityRoutines import ShowWarningMessage, ShowRecurringWarningErrorAtEnd, format
from math import sqrt
def pow_2(x: Float64) -> Float64:
    return x * x
struct AirState:
    var temperature: Float64
    var humidity_ratio: Float64
    var density: Float64
    var sqrt_density: Float64
    var viscosity: Float64
    def __init__(inout self, density: Float64):
        self.temperature = 20.0
        self.humidity_ratio = 0.0
        self.density = density
        self.sqrt_density = sqrt(density)
        self.viscosity = AIRDYNAMICVISCOSITY_CONSTEXPR(20.0)
    def __init__(inout self):
        self.temperature = 20.0
        self.humidity_ratio = 0.0
        self.density = AIRDENSITY_CONSTEXPR(101325.0, 20.0, 0.0)
        self.sqrt_density = sqrt(AIRDENSITY_CONSTEXPR(101325.0, 20.0, 0.0))
        self.viscosity = AIRDYNAMICVISCOSITY_CONSTEXPR(20.0)
struct AirProperties:
    var m_state: Pointer[None]  // opaque, placeholder; actual type unknown
    var lowerLimitErrIdx: Int
    var upperLimitErrIdx: Int
    def __init__(inout self):
        self.m_state = Pointer[None]()
        self.lowerLimitErrIdx = 0
        self.upperLimitErrIdx = 0
    def density(self, P: Float64, T: Float64, W: Float64) -> Float64:
        return PsyRhoAirFnPbTdbW(self.m_state, P, T, W)
    def thermal_conductivity(self, T: Float64) -> Float64:
        var LowerLimit: Float64 = -20.0
        var UpperLimit: Float64 = 70.0
        var a: Float64 = 0.02364
        var b: Float64 = 0.0000754772569209165
        var c: Float64 = -2.40977632412045e-8
        var T_local = T
        if T_local < LowerLimit:
            if self.lowerLimitErrIdx == 0:
                ShowWarningMessage(self.m_state, "Air temperature below lower limit of -20C for conductivity calculation")
            ShowRecurringWarningErrorAtEnd(
                self.m_state,
                format("Air temperature below lower limit of -20C for conductivity calculation. Air temperature of {:.1R} "
                       "used for conductivity calculation.",
                       LowerLimit),
                self.lowerLimitErrIdx)
            T_local = LowerLimit
        elif T_local > UpperLimit:
            if self.upperLimitErrIdx == 0:
                ShowWarningMessage(self.m_state, "Air temperature above upper limit of 70C for conductivity calculation")
            ShowRecurringWarningErrorAtEnd(
                self.m_state,
                format("Air temperature above upper limit of 70C for conductivity calculation. Air temperature of {:.1R} "
                       "used for conductivity calculation.",
                       UpperLimit),
                self.upperLimitErrIdx)
            T_local = UpperLimit
        return a + b * T_local + c * pow_2(T_local)
    def dynamic_viscosity(self, T: Float64) -> Float64:
        return 1.71432e-5 + 4.828e-8 * T
    def kinematic_viscosity(self, P: Float64, T: Float64, W: Float64) -> Float64:
        var LowerLimit: Float64 = -20.0
        var UpperLimit: Float64 = 70.0
        var T_local = T
        if T_local < LowerLimit:
            T_local = LowerLimit
        elif T_local > UpperLimit:
            T_local = UpperLimit
        return self.dynamic_viscosity(T_local) / PsyRhoAirFnPbTdbW(self.m_state, P, T_local, W)
    def thermal_diffusivity(self, P: Float64, T: Float64, W: Float64) -> Float64:
        var LowerLimit: Float64 = -20.0
        var UpperLimit: Float64 = 70.0
        var T_local = T
        if T_local < LowerLimit:
            T_local = LowerLimit
        elif T_local > UpperLimit:
            T_local = UpperLimit
        return self.thermal_conductivity(T_local) / (AIRCP(W) * PsyRhoAirFnPbTdbW(self.m_state, P, T_local, W))
    def prandtl_number(self, P: Float64, T: Float64, W: Float64) -> Float64:
        var LowerLimit: Float64 = -20.0
        var UpperLimit: Float64 = 70.0
        var T_local = T
        if T_local < LowerLimit:
            T_local = LowerLimit
        elif T_local > UpperLimit:
            T_local = UpperLimit
        return self.kinematic_viscosity(P, T_local, W) / self.thermal_diffusivity(P, T_local, W)