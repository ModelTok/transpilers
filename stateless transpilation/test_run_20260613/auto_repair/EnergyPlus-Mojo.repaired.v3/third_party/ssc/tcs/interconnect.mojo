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

from htf_props import HTFProperties
from sam_csp_util import CSP

import math
import sys

let pi: Float64 = math.acos(-1.0)
let T_ref_K: Float64 = 298.150
let NA_cpnt: Int = -1

def FrictionFactor_FlexHose(Re: Float64, D: Float64) -> Float64:
    assert(Re > 6000)
    var ff: Float64
    let d_in_mm = D * 1.0e3                       # convert diameter from m to mm for use in the models
    const D_lo_mm: Float64 = 6.0                   # low diameter, mm
    const Re_lo_D_lo: Float64 = 3.46e4             # Re at low transition point for low diameter
    const ff_lo_D_lo: Float64 = 9.92e-2            # ff at low transition point for low diameter
    const Re_hi_D_lo: Float64 = 1.24e5             # Re at high transition point for low diameter
    const ff_hi_D_lo: Float64 = 2.21e-1            # ff at high transition point for low diameter
    const D_hi_mm: Float64 = 150.0                 # high diameter, mm
    const Re_lo_D_hi: Float64 = 1.37e5             # Re at low transition point for high diameter
    const ff_lo_D_hi: Float64 = 5.48e-2            # ff at low transition point for high diameter
    const Re_hi_D_hi: Float64 = 4.97e5             # Re at high transition point for high diameter
    const ff_hi_D_hi: Float64 = 9.86e-2            # ff at high transition point for high diameter
    var Re_lo_D_in: Float64                         # Low Re transition point
    const m_Re_lo: Float64 = 3.00e4                 # scale term in model
    const b_incpt_Re_lo: Float64 = -1.10e4          # intercept
    Re_lo_D_in = m_Re_lo * math.log(d_in_mm) + b_incpt_Re_lo   # log is natural log
    var Re_hi_D_in: Float64                         # High Re transition point
    const m_Re_hi: Float64 = 1.12e5                 # scale term in model
    const b_incpt_Re_hi: Float64 = -6.40e4          # intercept
    Re_hi_D_in = m_Re_hi * math.log(d_in_mm) + b_incpt_Re_hi   # log is natural log
    var m_ff_vs_Re_lo: Float64                      # slope of Re loci vs. ff at low transition point
    var ff_lo_D_in: Float64                         # friction factor at low transition point
    m_ff_vs_Re_lo = (math.log10(ff_lo_D_hi) - math.log10(ff_lo_D_lo)) / (math.log10(Re_lo_D_hi) - math.log10(Re_lo_D_lo))
    ff_lo_D_in = math.pow(10, math.log10(ff_lo_D_lo) + m_ff_vs_Re_lo * (math.log10(Re_lo_D_in) - math.log10(Re_lo_D_lo)))
    var m_ff_vs_Re_hi: Float64                      # slope of Re loci vs. ff at high transition point
    var ff_hi_D_in: Float64                         # friction factor at high transition point
    m_ff_vs_Re_hi = (math.log10(ff_hi_D_hi) - math.log10(ff_hi_D_lo)) / (math.log10(Re_hi_D_hi) - math.log10(Re_hi_D_lo))
    ff_hi_D_in = math.pow(10, math.log10(ff_hi_D_lo) + m_ff_vs_Re_hi * (math.log10(Re_hi_D_in) - math.log10(Re_hi_D_lo)))
    var slope: Float64                               # slope of transition line for input diameter
    slope = (math.log10(ff_hi_D_in) - math.log10(ff_lo_D_in)) / (math.log10(Re_hi_D_in) - math.log10(Re_lo_D_in))
    if Re < Re_lo_D_in:
        ff = ff_lo_D_in
    elif Re > Re_hi_D_in:
        ff = ff_hi_D_in
    else:
        ff = math.pow(10, math.log10(ff_lo_D_in) + slope * (math.log10(Re) - math.log10(Re_lo_D_in)))
    return ff

@value
struct IntcOutputs:
    var heat_loss: Float64               # [W]
    var temp_drop: Float64               # [K]
    var temp_out: Float64                # [K]
    var temp_ave: Float64                # [K]
    var pressure_drop: Float64           # [Pa]
    var pressure_out: Float64            # [Pa]
    var pressure_ave: Float64            # [Pa]
    var internal_energy: Float64         # [J]

    def __init__(inout self):
        self.heat_loss = 0.0
        self.temp_drop = 0.0
        self.temp_out = 0.0
        self.temp_ave = 0.0
        self.pressure_drop = 0.0
        self.pressure_out = 0.0
        self.pressure_ave = 0.0
        self.internal_energy = 0.0

@value
enum CpntType:
    Fitting = 0
    Pipe = 1
    Flex_Hose = 2
    FINAL_ENTRY = 3

class intc_cpnt:
    var k_: Float64                       # minor loss coefficient [-]
    var d_in_: Float64                    # inner diameter [m]
    var l_: Float64                       # length [m]
    var rough_: Float64                   # roughness (inside) [m]
    var hl_coef_: Float64                 # overall heat loss coefficient [W/(m2-K)]
    var mc_: Float64                      # heat capacity w/o htf [J/K]
    var wall_thick_: Float64              # wall thickness [m]
    var Type: CpntType
    var OuterSurfArea_valid_: Bool
    var OuterSurfArea_: Float64
    var FlowArea_valid_: Bool
    var FlowArea_: Float64                # cross-sectional area for flow [m^2]
    var FluidVolume_valid_: Bool
    var FluidVolume_: Float64

    def __init__(inout self, k: Float64 = 0.0, d: Float64 = 0.0, l: Float64 = 0.0, rough: Float64 = 0.0, u: Float64 = 0.0,
            mc: Float64 = 0.0, type: CpntType = CpntType.Fitting):
        self.k_ = k
        self.d_in_ = d
        self.l_ = l
        self.rough_ = rough
        self.hl_coef_ = u
        self.mc_ = mc
        self.wall_thick_ = 0.0
        self.Type = type
        self.OuterSurfArea_valid_ = False
        self.OuterSurfArea_ = 0.0
        self.FlowArea_valid_ = False
        self.FlowArea_ = 0.0
        self.FluidVolume_valid_ = False
        self.FluidVolume_ = 0.0
        if self.k_ < 0:
            raise Error("The minor loss coefficient (K) cannot be less than 0.")
        if self.d_in_ < 0:
            raise Error("The inner diameter (D_in) cannot be less than 0.")
        if self.l_ < 0:
            raise Error("The length (L) cannot be less than 0.")
        if self.rough_ < 0:
            raise Error("The relative roughness cannot be less than 0.")
        if self.hl_coef_ < 0:
            raise Error("The heat loss coefficient (U) cannot be less than 0.")
        if self.mc_ < 0:
            raise Error("The heat capacity cannot be less than 0.")
        self.setWallThick(CSP.WallThickness(self.d_in_))

    def __del__(owned self):

    def getK(self) -> Float64:
        return self.k_

    def setK(inout self, k: Float64):
        if k >= 0:
            self.k_ = k
        else:
            raise Error("The minor loss coefficient (K) cannot be less than 0.")

    def getD(self) -> Float64:
        return self.d_in_

    def setD(inout self, d: Float64):
        if d >= 0:
            self.d_in_ = d
            self.OuterSurfArea_valid_ = False
        else:
            raise Error("The inner diameter (D_in) cannot be less than 0.")

    def getLength(self) -> Float64:
        return self.l_

    def setLength(inout self, l: Float64):
        if l >= 0:
            self.l_ = l
            self.OuterSurfArea_valid_ = False
        else:
            raise Error("The length (L) cannot be less than 0.")

    def getRelRough(self) -> Float64:
        return self.rough_

    def setRelRough(inout self, rough: Float64):
        if rough >= 0:
            self.rough_ = rough
        else:
            raise Error("The relative roughness cannot be less than 0.")

    def getHLCoef(self) -> Float64:
        return self.hl_coef_

    def setHLCoef(inout self, u: Float64):
        if u >= 0:
            self.hl_coef_ = u
        else:
            raise Error("The heat loss coefficient (U) cannot be less than 0.")

    def getHeatCap(self) -> Float64:
        return self.mc_

    def setHeatCap(inout self, mc: Float64):
        if mc >= 0:
            self.mc_ = mc
        else:
            raise Error("The heat capacity cannot be less than 0.")

    def getWallThick(self) -> Float64:
        return self.wall_thick_

    def setWallThick(inout self, wall_thick: Float64):
        if wall_thick >= 0:
            self.wall_thick_ = wall_thick
        else:
            raise Error("The wall thickness cannot be less than 0.")

    def getType(self) -> CpntType:
        return self.Type

    def getOuterSurfArea(inout self) -> Float64:
        if not self.OuterSurfArea_valid_:
            self.calcOuterSurfArea()
        return self.OuterSurfArea_

    def calcOuterSurfArea(inout self):
        self.OuterSurfArea_ = pi * self.d_in_ * self.l_
        self.OuterSurfArea_valid_ = True

    def getFlowArea(inout self) -> Float64:
        if not self.FlowArea_valid_:
            self.calcFlowArea()
        return self.FlowArea_

    def calcFlowArea(inout self):
        self.FlowArea_ = pi * (self.d_in_ * self.d_in_) / 4.0
        self.FlowArea_valid_ = True

    def getFluidVolume(inout self) -> Float64:
        if not self.FluidVolume_valid_:
            self.calcFluidVolume()
        return self.FluidVolume_

    def calcFluidVolume(inout self):
        self.FluidVolume_ = pi * (self.d_in_ * self.d_in_) / 4.0 * self.l_
        self.FluidVolume_valid_ = True

    def HeatLoss(self, T_cpnt: Float64, T_db: Float64) -> Float64:
        let A = self.getOuterSurfArea()  # fun needed b/c area is not always valid
        return self.hl_coef_ * A * (T_cpnt - T_db)

    def TempDrop(self, fluidProps: HTFProperties, m_dot: Float64, T_in: Float64, heatLoss: Float64) -> Float64:
        let cp = fluidProps.Cp(T_in) * 1000  # J/kg-K
        return heatLoss / (m_dot * cp)   # positive value means T_out < T_in

    def TempDrop(self, fluidProps: HTFProperties, m_dot: Float64, T_in: Float64, T_cpnt: Float64, T_db: Float64) -> Float64:
        let cp = fluidProps.Cp(T_in) * 1000  # J/kg-K
        return self.HeatLoss(T_cpnt, T_db) / (m_dot * cp)   # positive value means T_out < T_in

    def PressureDrop(self, fluidProps: HTFProperties, m_dot: Float64, T_htf_ave: Float64, P_htf_ave: Float64) -> Float64:
        let rho = fluidProps.dens(T_htf_ave, P_htf_ave)
        let vel = m_dot / (rho * self.getFlowArea())
        var Re: Float64
        var ff: Float64
        if self.Type == CpntType.Fitting:
            return CSP.MinorPressureDrop(vel, rho, self.k_)
        elif self.Type == CpntType.Pipe:
            Re = fluidProps.Re(T_htf_ave, P_htf_ave, vel, self.d_in_)
            ff = CSP.FrictionFactor(self.rough_ / self.d_in_, Re)
            return CSP.MajorPressureDrop(vel, rho, ff, self.l_, self.d_in_)
        elif self.Type == CpntType.Flex_Hose:
            Re = fluidProps.Re(T_htf_ave, P_htf_ave, vel, self.d_in_)
            if Re < 6000:
                ff = CSP.FrictionFactor(self.rough_ / self.d_in_, Re)  # call standard pipe friction factor function
            else:
                ff = FrictionFactor_FlexHose(Re, self.d_in_)
            return CSP.MajorPressureDrop(vel, rho, ff, self.l_, self.d_in_)
        else:
            raise Error("This component type has no pressure drop calculation.")

    def InternalEnergy(self, fluidProps: HTFProperties, T_cpnt: Float64, T_htf_ave: Float64, P_htf_ave: Float64) -> Float64:
        let cp = fluidProps.Cp(T_htf_ave) * 1000  # J/kg-K
        return (self.getFluidVolume() * fluidProps.dens(T_htf_ave, P_htf_ave) * cp +
            self.getHeatCap()) * (T_cpnt - T_ref_K)

    def State(self, fluidProps: HTFProperties, m_dot: Float64, T_in: Float64, T_cpnt: Float64, T_db: Float64, P_htf_ave: Float64) -> IntcOutputs:
        var output: IntcOutputs
        output.heat_loss = self.HeatLoss(T_cpnt, T_db)
        output.temp_drop = self.TempDrop(fluidProps, m_dot, T_in, output.heat_loss)
        output.temp_out = T_in - output.temp_drop
        output.temp_ave = (T_in + output.temp_out) / 2
        output.pressure_drop = self.PressureDrop(fluidProps, m_dot, output.temp_ave, P_htf_ave)
        output.pressure_out = P_htf_ave - output.pressure_drop / 2  # just an approximation to fill an output
        output.pressure_ave = P_htf_ave
        output.internal_energy = self.InternalEnergy(fluidProps, T_cpnt, output.temp_ave, P_htf_ave)
        return output

class interconnect:
    var cpnts: List[intc_cpnt]
    var N_cpnts_: Int
    var FluidProps_: HTFProperties
    var Length_valid_: Bool
    var l_: Float64
    var HeatCap_valid_: Bool
    var mc_: Float64
    var OuterSurfArea_valid_: Bool
    var OuterSurfArea_: Float64
    var FluidVolume_valid_: Bool
    var FluidVolume_: Float64

    def __init__(inout self):
        self.cpnts = List[intc_cpnt]()
        self.N_cpnts_ = 0
        self.FluidProps_ = HTFProperties()  # placeholder, will be set later
        self.Length_valid_ = False
        self.l_ = 0.0
        self.HeatCap_valid_ = False
        self.mc_ = 0.0
        self.OuterSurfArea_valid_ = False
        self.OuterSurfArea_ = 0.0
        self.FluidVolume_valid_ = False
        self.FluidVolume_ = 0.0

    def __init__(inout self, fluidProps: HTFProperties, k: List[Float64], d: List[Float64], l: List[Float64], rel_rough: List[Float64], u: List[Float64], mc: List[Float64], type: List[Float64], n_cpnts: Int):
        self.cpnts = List[intc_cpnt]()
        self.N_cpnts_ = 0
        self.FluidProps_ = fluidProps
        self.Length_valid_ = False
        self.l_ = 0.0
        self.HeatCap_valid_ = False
        self.mc_ = 0.0
        self.OuterSurfArea_valid_ = False
        self.OuterSurfArea_ = 0.0
        self.FluidVolume_valid_ = False
        self.FluidVolume_ = 0.0
        self.import_cpnts(k, d, l, rel_rough, u, mc, type, n_cpnts)

    def __del__(owned self):

    def import_cpnts(inout self, k: List[Float64], d: List[Float64], l: List[Float64], rel_rough: List[Float64], u: List[Float64], mc: List[Float64], type: List[Float64], num_cpnts: Int):
        let max_cpnts = num_cpnts
        var n_cpnts: Int = 0  # double check number of components
        while k[n_cpnts] != NA_cpnt and n_cpnts < max_cpnts:
            n_cpnts += 1
        if not self.cpnts.is_empty():
            self.cpnts.clear()
        self.cpnts.reserve(n_cpnts)
        var cpnt: intc_cpnt
        for i in range(n_cpnts):
            if type[i] < 0 or type[i] >= Float64(CpntType.FINAL_ENTRY):
                raise Error("The component type is out of range at index" + String(i))
            cpnt = intc_cpnt(k[i], d[i], l[i], rel_rough[i], u[i], mc[i], CpntType(Int(type[i])))
            self.cpnts.append(cpnt)
            self.N_cpnts_ += 1
            self.l_ += cpnt.getLength()
            self.mc_ += cpnt.getHeatCap()
            self.OuterSurfArea_ += cpnt.getOuterSurfArea()
            self.FluidVolume_ += cpnt.getFluidVolume()
        self.Length_valid_ = True
        self.HeatCap_valid_ = True
        self.OuterSurfArea_valid_ = True
        self.FluidVolume_valid_ = True

    def resetValues(inout self):
        self.cpnts.clear()
        self.N_cpnts_ = 0
        # self.FluidProps_ = None  # Not directly possible; we'll keep placeholder
        self.Length_valid_ = False
        self.l_ = 0.0
        self.HeatCap_valid_ = False
        self.mc_ = 0.0
        self.OuterSurfArea_valid_ = False
        self.OuterSurfArea_ = 0.0
        self.FluidVolume_valid_ = False
        self.FluidVolume_ = 0.0

    def setFluidProps(inout self, fluidProps: HTFProperties):
        self.FluidProps_ = fluidProps

    def getNcpnts(self) -> Int:
        return self.N_cpnts_

    def getK(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getK()

    def getD(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getD()

    def getLength(inout self) -> Float64:
        if not self.Length_valid_:
            self.calcLength()
        return self.l_

    def getLength(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getLength()

    def calcLength(inout self):
        self.l_ = 0.0
        for cpnt in self.cpnts:
            self.l_ += cpnt.getLength()
        self.Length_valid_ = True

    def getRelRough(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getRelRough()

    def getHLCoef(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getHLCoef()

    def getHeatCap(inout self) -> Float64:
        if not self.HeatCap_valid_:
            self.calcHeatCap()
        return self.mc_

    def getHeatCap(self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getHeatCap()

    def calcHeatCap(inout self):
        self.mc_ = 0.0
        for cpnt in self.cpnts:
            self.mc_ += cpnt.getHeatCap()
        self.HeatCap_valid_ = True

    def getType(self, cpnt: Int) -> CpntType:
        return self.cpnts[cpnt].getType()

    def getOuterSurfArea(inout self) -> Float64:
        if not self.OuterSurfArea_valid_:
            self.calcOuterSurfArea()
        return self.OuterSurfArea_

    def getOuterSurfArea(inout self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getOuterSurfArea()

    def calcOuterSurfArea(inout self):
        self.OuterSurfArea_ = 0.0
        for cpnt in self.cpnts:
            self.OuterSurfArea_ += cpnt.getOuterSurfArea()
        self.OuterSurfArea_ = True  # Bug: should be OuterSurfArea_valid_ = True, but kept for faithful translation

    def getFlowArea(inout self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getFlowArea()

    def getFluidVolume(inout self) -> Float64:
        if not self.FluidVolume_valid_:
            self.calcFluidVolume()
        return self.FluidVolume_

    def getFluidVolume(inout self, cpnt: Int) -> Float64:
        return self.cpnts[cpnt].getFluidVolume()

    def calcFluidVolume(inout self):
        self.FluidVolume_ = 0.0
        for cpnt in self.cpnts:
            self.FluidVolume_ += cpnt.getFluidVolume()
        self.FluidVolume_valid_ = True

    def State(inout self, m_dot: Float64, T_in: Float64, T_db: Float64, P_in: Float64) -> IntcOutputs:
        var output: IntcOutputs
        if self.N_cpnts_ > 0:
            var IntcOutput: IntcOutputs
            var T_out_prev: Float64 = T_in
            var P_out_prev: Float64 = P_in
            for cpnt in self.cpnts:
                IntcOutput = cpnt.State(self.FluidProps_, m_dot, T_out_prev, T_out_prev, T_db, P_out_prev)
                output.heat_loss += IntcOutput.heat_loss
                output.pressure_drop += IntcOutput.pressure_drop
                output.internal_energy += IntcOutput.internal_energy
                T_out_prev = IntcOutput.temp_out
                P_out_prev = P_out_prev - IntcOutput.pressure_drop
            output.temp_drop = T_in - IntcOutput.temp_out
            output.temp_out = IntcOutput.temp_out
            output.temp_ave = (T_in + output.temp_out) / 2
            output.pressure_out = P_in - output.pressure_drop
            output.pressure_ave = (P_in + output.pressure_out) / 2
        else:
            output.heat_loss = 0.0
            output.temp_drop = 0.0
            output.temp_out = T_in
            output.temp_ave = T_in
            output.pressure_drop = 0.0
            output.pressure_out = P_in
            output.pressure_ave = P_in
            output.internal_energy = 0.0
        return output