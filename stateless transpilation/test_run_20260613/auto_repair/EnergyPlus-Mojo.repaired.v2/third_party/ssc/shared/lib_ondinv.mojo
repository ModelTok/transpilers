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
/*******************************************************************************************************
*  Copyright 2018 - pvyield GmbH / Timo Richert
*  Copyright 2017 Alliance for Sustainable Energy, LLC
*
*  NOTICE: This software was developed at least in part by Alliance for Sustainable Energy, LLC
*  ("Alliance") under Contract No. DE-AC36-08GO28308 with the U.S. Department of Energy and the U.S.
*  The Government retains for itself and others acting on its behalf a nonexclusive, paid-up,
*  irrevocable worldwide license in the software to reproduce, prepare derivative works, distribute
*  copies to the public, perform publicly and display publicly, and to permit others to do so.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer.
*
*  2. Redistributions in binary form must reproduce the above copyright notice, the above government
*  rights notice, this list of conditions and the following disclaimer in the documentation and/or
*  other materials provided with the distribution.
*
*  3. The entire corresponding source code of any redistribution, with or without modification, by a
*  research entity, including but not limited to any contracting manager/operator of a United States
*  National Laboratory, any institution of higher learning, and any non-profit organization, must be
*  made publicly available under this license for as long as the redistribution is made available by
*  the research entity.
*
*  4. Redistribution of this software, without modification, must refer to the software by the same
*  designation. Redistribution of a modified version of this software (i) may not refer to the modified
*  version by the same designation, or by any confusingly similar designation, and (ii) must refer to
*  the underlying software originally provided by Alliance as "System Advisor Model" or "SAM". Except
*  to comply with the foregoing, the terms "System Advisor Model", "SAM", or any confusingly similar
*  designation may not be used to refer to any modified version of this software or any modified
*  version of the underlying software originally provided by Alliance without the prior written consent
*  of Alliance.
*
*  5. The name of the copyright holder, contributors, the United States Government, the United States
*  Department of Energy, or any of their employees may not be used to endorse or promote products
*  derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER,
*  CONTRIBUTORS, UNITED STATES GOVERNMENT OR UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF THEIR
*  EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
*  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************************************/
/*******************************************************************************************************
* Implementation of an inverter model based on OND files
*******************************************************************************************************/
from math import atan, min, max
from bspline import BSpline
from datatable import DataTable, DenseVector

const TEMP_DERATE_ARRAY_LENGTH: Int = 6

struct ond_inverter:
    # public members
    var PNomConv: Float64  # [W]
    var PMaxOUT: Float64  # [W]
    var VOutConv: Float64  # [W]
    var VMppMin: Float64  # [V]
    var VMPPMax: Float64  # [V]
    var VAbsMax: Float64  # [V]
    var PSeuil: Float64  # [W]
    var ModeOper: String  # [-]
    var CompPMax: String  # [-]
    var CompVMax: String  # [-]
    var ModeAffEnum: String  # [-]
    var PNomDC: Float64  # [W]
    var PMaxDC: Float64  # [W]
    var IMaxDC: Float64  # [A]
    var INomDC: Float64  # [A]
    var INomAC: Float64  # [A]
    var IMaxAC: Float64  # [A]
    var TPNom: Float64  # [°C]
    var TPMax: Float64  # [°C]
    var TPLim1: Float64  # [°C]
    var TPLimAbs: Float64  # [°C]
    var PLim1: Float64  # [kW]
    var PLimAbs: Float64  # [kW]
    var VNomEff: StaticTuple[Float64, 3]  # [V]
    var NbInputs: Int  # [-]
    var NbMPPT: Int  # [-]
    var Aux_Loss: Float64  # [W]
    var Night_Loss: Float64  # [W]
    var lossRDc: Float64  # [V/A]
    var lossRAc: Float64  # [A]
    var effCurve_elements: Int  # [-]
    var effCurve_Pdc: StaticTuple[StaticTuple[Float64, 100], 3]  # [W]
    var effCurve_Pac: StaticTuple[StaticTuple[Float64, 100], 3]  # [W]
    var effCurve_eta: StaticTuple[StaticTuple[Float64, 100], 3]  # [-]
    var doAllowOverpower: Int  # [-] // ADDED TO CONSIDER MAX POWER USAGE [2018-06-23, TR]
    var doUseTemperatureLimit: Int  # [-] // ADDED TO CONSIDER TEMPERATURE LIMIT USAGE [2018-06-23, TR]

    # private members
    var ondIsInitialized: Bool
    var noOfEfficiencyCurves: Int
    var m_bspline3: StaticTuple[BSpline, 3]
    var x_max: StaticTuple[Float64, 3]
    var x_lim: StaticTuple[Float64, 3]
    var Pdc_threshold: Float64
    var a: StaticTuple[Float64, 3]
    var b: StaticTuple[Float64, 3]
    var PNomDC_eff: Float64
    var PMaxDC_eff: Float64
    var INomDC_eff: Float64
    var IMaxDC_eff: Float64
    var T_array: StaticTuple[Float64, 6]
    var PAC_array: StaticTuple[Float64, 6]

    def __init__(inout self):
        self.PNomConv = Float64.NaN
        self.PMaxOUT = Float64.NaN
        self.VOutConv = Float64.NaN
        self.VMppMin = Float64.NaN
        self.VMPPMax = Float64.NaN
        self.VAbsMax = Float64.NaN
        self.PSeuil = Float64.NaN
        self.PNomDC = Float64.NaN
        self.PMaxDC = Float64.NaN
        self.IMaxDC = Float64.NaN
        self.INomDC = Float64.NaN
        self.INomAC = Float64.NaN
        self.IMaxAC = Float64.NaN
        self.TPNom = Float64.NaN
        self.TPMax = Float64.NaN
        self.TPLim1 = Float64.NaN
        self.TPLimAbs = Float64.NaN
        self.PLim1 = Float64.NaN
        self.PLimAbs = Float64.NaN
        self.Aux_Loss = Float64.NaN
        self.Night_Loss = Float64.NaN
        self.lossRDc = Float64.NaN
        self.lossRAc = Float64.NaN
        self.ModeOper = ""
        self.CompPMax = ""
        self.CompVMax = ""
        self.ModeAffEnum = ""
        self.NbInputs = 0
        self.NbMPPT = 0
        self.ondIsInitialized = False
        self.doAllowOverpower = 1
        self.doUseTemperatureLimit = 1

    def __del__(owned self):

    def initializeManual(inout self):
        if not self.ondIsInitialized:
            if self.ModeOper != "MPPT":
                raise Error("Invalid ModeOper, only 'MPPT' is supported.")
            if self.CompPMax != "Lim":
                raise Error("Invalid CompPMax, only 'Lim' is supported.")
            if self.CompVMax != "Lim":
                raise Error("Invalid CompVMax, only 'Lim' is supported.")
            if self.ModeAffEnum != "Efficiencyf_PIn":
                raise Error("Invalid ModeAffEnum, only 'Efficiencyf_PIn' is supported.")
            var PlimAbs_eff: Float64
            var PLim1_eff: Float64
            var PMaxOUT_eff: Float64
            if self.PLimAbs < 0.001 * self.PNomConv:
                PlimAbs_eff = 0.0
            else:
                PlimAbs_eff = self.PLimAbs
            if self.PLim1 < 0.001 * self.PNomConv:
                PLim1_eff = 0.0
            else:
                PLim1_eff = self.PLim1
            if self.PMaxOUT < 0.001 * self.PNomConv:
                PMaxOUT_eff = self.PNomConv
            else:
                PMaxOUT_eff = self.PMaxOUT
            var T_array_init: StaticTuple[Float64, 6] = (-300.0, self.TPMax, self.TPNom, self.TPLim1, self.TPLimAbs, self.TPLimAbs)
            var PAC_array_init: StaticTuple[Float64, 6] = (PMaxOUT_eff, PMaxOUT_eff, self.PNomConv, PLim1_eff, PlimAbs_eff, 0.0)
            for j in range(TEMP_DERATE_ARRAY_LENGTH):
                self.T_array[j] = T_array_init[j]
                self.PAC_array[j] = PAC_array_init[j]
            if self.PNomDC < 0.0001 * self.PNomConv:
                self.PNomDC_eff = self.PNomConv
            else:
                self.PNomDC_eff = self.PNomDC
            if self.PMaxDC < 0.0001 * self.PMaxOUT:
                self.PMaxDC_eff = self.PMaxOUT
            else:
                self.PMaxDC_eff = self.PMaxDC
            if self.INomDC < 0.0001 * (self.PNomConv / self.VMPPMax):
                self.INomDC_eff = self.PNomDC_eff / self.VMppMin
            else:
                self.INomDC_eff = self.INomDC
            if self.IMaxDC < 0.0001 * (self.PNomConv / self.VMPPMax):
                self.IMaxDC_eff = self.INomDC_eff * (self.PMaxDC_eff / self.PNomDC_eff)
            else:
                self.IMaxDC_eff = self.IMaxDC
            self.Pdc_threshold = 2.0
            var ondspl_X = List[Float64]()
            var ondspl_Y = List[Float64]()
            var xSamples = DenseVector(1)
            var samples = DataTable()
            if self.VNomEff[2] > 0.0:
                self.noOfEfficiencyCurves = 3
            else:
                self.noOfEfficiencyCurves = 1
            for j in range(self.noOfEfficiencyCurves):
                ondspl_X.clear()
                ondspl_Y.clear()
                var atX: StaticTuple[Float64, 3]
                var atY: StaticTuple[Float64, 3]
                const MAX_ELEMENTS: Int = 100  # = effCurve_elements + 5;
                @parameter
                for i in range(MAX_ELEMENTS):
                    if i <= 2:  # atan
                        atX[i] = self.effCurve_Pdc[j][i]
                        atY[i] = self.effCurve_eta[j][i]
                        if i == 2:
                            self.x_lim[j] = self.effCurve_Pdc[j][i]
                            var adder: Float64
                            var err: Float64
                            self.b[j] = 10.0
                            adder = 40.0
                            for k in range(101):
                                self.a[j] = atY[2] / atan(self.b[j] * atX[2] / self.PNomDC_eff)
                                err = (self.a[j] * atan(self.b[j] * atX[1] / self.PNomDC_eff)) - atY[1]
                                if err > 0.0:
                                    self.b[j] = self.b[j] - adder
                                    adder = adder / 2.0
                                else:
                                    self.b[j] = self.b[j] + adder
                    if (i >= 2) and (i < MAX_ELEMENTS) and (self.effCurve_Pdc[j][i] > 0.0):  # && effCurve_eta[j][i] > 0
                        # spline
                        ondspl_X.append(self.effCurve_Pdc[j][i])
                        ondspl_Y.append(self.effCurve_eta[j][i])
                # /* Spline
                # bool doCubicSpline[2];
                # doCubicSpline[0] = true;
                # doCubicSpline[1] = true;
                # for (int i = 0; i <= 1; i = i + 1) {
                # 	if (i == 0 || (i == 1 && Pdc_threshold < 0.8)) {
                # 		effSpline[i][j].set_points(ondspl_X[i], ondspl_Y[i], doCubicSpline[i]);
                # 	}
                # }
                # */
                samples.clear()
                self.x_max[j] = ondspl_X.back()
                var k_lim = min(len(ondspl_X), len(ondspl_Y))
                for k in range(k_lim):
                    xSamples[0] = ondspl_X[k]
                    samples.addSample(xSamples, ondspl_Y[k])
                self.m_bspline3[j] = BSpline.Builder(samples).degree(3).build()
            self.ondIsInitialized = True

    def calcEfficiency(inout self, Pdc: Float64, index_eta: Int) -> Float64:
        var eta: Float64
        var x = DenseVector(1)
        if Pdc > self.x_max[index_eta]:
            Pdc = self.x_max[index_eta]
        if Pdc <= 0.0:
            eta = 0.0
        elif Pdc >= self.x_lim[index_eta]:
            x[0] = Pdc
            eta = self.m_bspline3[index_eta].eval(x)
        else:
            eta = self.a[index_eta] * atan(self.b[index_eta] * Pdc / self.PNomDC_eff)
        return eta

    def tempDerateAC(inout self, arrayT: StaticTuple[Float64, 6], arrayPAC: StaticTuple[Float64, 6], T: Float64) -> Float64:
        var PAC_max: Float64
        var T_low: Float64
        var T_high: Float64
        var PAC_low: Float64
        var PAC_high: Float64
        const PAC_MAX_INIT: Float64 = -10 ^ 10
        PAC_max = PAC_MAX_INIT
        for i in range(TEMP_DERATE_ARRAY_LENGTH):
            if i == 0:
                if T <= arrayT[0]:
                    PAC_max = arrayPAC[0]
                    break
                elif T > arrayT[TEMP_DERATE_ARRAY_LENGTH - 1]:
                    PAC_max = arrayPAC[TEMP_DERATE_ARRAY_LENGTH - 1]
                    break
            else:
                if (T > arrayT[i - 1]) and (T <= arrayT[i]):
                    T_low = arrayT[i - 1]
                    T_high = arrayT[i]
                    PAC_low = arrayPAC[i - 1]
                    PAC_high = arrayPAC[i]
                    PAC_max = PAC_low + (PAC_high - PAC_low) * (T - T_low) / (T_high - T_low)
                    break
        if (self.doAllowOverpower == 0) and (self.doUseTemperatureLimit == 0):
            PAC_max = self.PNomConv
        elif (self.doAllowOverpower == 1) and (self.doUseTemperatureLimit == 0):
            PAC_max = max(PAC_max, self.PNomConv)
        elif (self.doAllowOverpower == 0) and (self.doUseTemperatureLimit == 1):
            PAC_max = min(PAC_max, self.PNomConv)
        elif self.doAllowOverpower and self.doUseTemperatureLimit:

        if PAC_max == PAC_MAX_INIT:
            raise Error("PAC_max has not been set.")
        return PAC_max

    def acpower(
        inout self,
        Pdc: Float64,
        Vdc: Float64,
        Tamb: Float64,
        inout Pac: Float64,
        inout Ppar: Float64,
        inout Plr: Float64,
        inout Eff: Float64,
        inout Pcliploss: Float64,
        inout Psoloss: Float64,
        inout Pntloss: Float64,
        inout dcloss: Float64,
        inout acloss: Float64
    ) -> Bool:
        var Pac_max_T: Float64
        Pac_max_T = self.tempDerateAC(self.T_array, self.PAC_array, Tamb)
        var Pac_max_I: Float64 = 0.0
        var dV_dcLoss: Float64
        var Vdc_eff: Float64
        var Pdc_eff: Float64
        var Idc_eff: Float64
        Pdc_eff = min(Pdc, Pac_max_T)  # Limit Pdc to temperature limit
        Vdc_eff = Vdc
        dV_dcLoss = 0.0
        if Vdc > 0.0 and Pdc > 0.0:
            for i in range(3):
                Idc_eff = Pdc_eff / Vdc_eff
                dV_dcLoss = self.lossRDc * Idc_eff
                dcloss = dV_dcLoss * Idc_eff
                Vdc_eff = Vdc - dV_dcLoss
                Pac_max_I = Vdc_eff * self.IMaxDC_eff
                if Pdc > Pac_max_I:
                    Pdc = Pac_max_I  # Limit Pdc to current limit
                Pdc_eff = Pdc - dcloss
        var V_eta_arr: StaticTuple[Float64, 2]
        var eta_arr: StaticTuple[Float64, 2]
        var index_shift: Int
        var index_eta: Int
        if Pdc > 0.0:
            if self.noOfEfficiencyCurves == 3:
                if Vdc_eff < self.VNomEff[1]:
                    index_shift = 0
                else:
                    index_shift = 1
                for i in range(2):
                    index_eta = index_shift + i
                    V_eta_arr[i] = self.VNomEff[index_eta]
                    eta_arr[i] = self.calcEfficiency(Pdc_eff, index_eta)  # effSpline[splineIndex][index_eta](Pdc_eff);
                Eff = eta_arr[0] + (eta_arr[1] - eta_arr[0]) * (Vdc_eff - V_eta_arr[0]) / (V_eta_arr[1] - V_eta_arr[0])
            elif self.noOfEfficiencyCurves == 1:
                Eff = self.calcEfficiency(Pdc_eff, 0)
            if Eff < 0.0:
                Eff = 0.0
            Pac = Eff * Pdc_eff
            Pcliploss = 0.0
            var PacNoClip: Float64 = Pac
            if (Pac > Pac_max_T) or (Pac > Pac_max_I):
                Pac = min(Pac_max_T, Pac_max_I)
                Pcliploss = PacNoClip - Pac
        else:
            Eff = 0.0
            Pac = 0.0
        Psoloss = 0.0  # Self-consumption during operation
        Ppar = 0.0
        Pntloss = 0.0
        if Pdc_eff <= self.PSeuil:
            Pac = -self.Night_Loss
            Ppar = self.Night_Loss
            Pntloss = self.Night_Loss
        else:
            var PacNoPso: Float64 = Pac + self.Aux_Loss
            Psoloss = PacNoPso - Pac
        var Iac: Float64
        Iac = Pac / self.VOutConv
        acloss = self.lossRAc * Iac * Iac
        Plr = Pdc_eff / self.PNomDC_eff
        return True