/*
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
from lib_physics import PI, Pa_PER_Atm, R_GAS_DRY_AIR, CelciusToKelvin, AIR_DENSITY_SEA_LEVEL
from lib_util import windTurbine
from lib_windwakemodel import wakeModelBase
from math import exp, log, pow, floor, sqrt, abs as fabs
from stdlib.pointer import Pointer
from stdlib.list import List

def max_of(a: Float64, b: Float64) -> Float64:
    return (a > b) ? a : b

def min_of(a: Float64, b: Float64) -> Float64:
    return (a < b) ? a : b

struct windPowerCalculator:
    var wakeModel: Pointer[wakeModelBase] = Pointer[wakeModelBase]()
    var windTurb: Pointer[windTurbine] = Pointer[windTurbine]()
    var nTurbines: Int = 0
    var turbulenceIntensity: Float64 = 0.0
    var errDetails: String = ""
    var XCoords: List[Float64] = List[Float64]()
    var YCoords: List[Float64] = List[Float64]()

    static let MAX_WIND_TURBINES: Int = 300
    static let MIN_DIAM_EV: Int = 2
    static let EV_SCALE: Int = 1

    def GetMaxTurbines(self) -> Int:
        return MAX_WIND_TURBINES

    def InitializeModel(self, inout selectedWakeModel: Pointer[wakeModelBase]) -> Bool:
        if selectedWakeModel:
            self.wakeModel = selectedWakeModel
            return True
        return False

    def GetWakeModelName(self) -> String:
        if self.wakeModel:
            return self.wakeModel.getModelName()
        return "NA"

    def GetErrorDetails(self) -> String:
        return self.errDetails

    def gammaln(self, x: Float64) -> Float64:
        var z: Float64
        var w: Float64
        var s: Float64
        var p: Float64
        var mantissa: Float64
        var expo: Float64
        var cf: List[Float64] = List[Float64](capacity=15)
        const DOUBLEPI: Float64 = 2.0 * PI
        const G_: Float64 = 607.0 / 128.0
        z = x - 1.0
        cf.append(0.999999999999997)
        cf.append(57.1562356658629)
        cf.append(-59.5979603554755)
        cf.append(14.1360979747417)
        cf.append(-0.49191381609762)
        cf.append(3.39946499848119E-05)
        cf.append(4.65236289270486E-05)
        cf.append(-9.83744753048796E-05)
        cf.append(1.58088703224912E-04)
        cf.append(-2.10264441724105E-04)
        cf.append(2.17439618115213E-04)
        cf.append(-1.64318106536764E-04)
        cf.append(8.44182239838528E-05)
        cf.append(-2.61908384015814E-05)
        cf.append(3.68991826595316E-06)
        w = exp(G_) / sqrt(DOUBLEPI)
        s = cf[0]
        for i in range(1, 15):
            s += cf[i] / (z + Float64(i))
        s = s / w
        p = log((z + G_ + 0.5) / exp(1.0)) * (z + 0.5) / log(10.0)
        expo = floor(p)
        p = p - floor(p)
        mantissa = pow(10.0, p) * s
        p = floor(log(mantissa) / log(10.0))
        mantissa = mantissa * pow(10.0, -p)
        expo = expo + p
        return log(mantissa) + expo * log(10.0)

    def coordtrans(self, metersNorth: Float64, metersEast: Float64, windDirDegrees: Float64, metersDownwind: Pointer[Float64], metersCrosswind: Pointer[Float64]):
        var wdir: Float64 = windDirDegrees + 90.0
        var fWind_dir_radians: Float64 = wdir * PI / 180.0
        metersDownwind[] = metersEast * cos(fWind_dir_radians) - (metersNorth * sin(fWind_dir_radians))
        metersCrosswind[] = metersEast * sin(fWind_dir_radians) + (metersNorth * cos(fWind_dir_radians))

    def windPowerUsingResource(self, windSpeed: Float64, windDirDeg: Float64, airPressureAtm: Float64, TdryC: Float64,
                              farmPower: Pointer[Float64], farmPowerGross: Pointer[Float64], power: Pointer[Float64],
                              thrust: Pointer[Float64], eff: Pointer[Float64], adWindSpeed: Pointer[Float64],
                              TI: Pointer[Float64], distanceDownwind: Pointer[Float64], distanceCrosswind: Pointer[Float64]) -> Int:
        if not self.wakeModel:
            self.errDetails = "Wake model not initialized."
            return 0
        if (self.nTurbines > MAX_WIND_TURBINES) or (self.nTurbines < 1):
            self.errDetails = "The number of wind turbines was greater than the maximum allowed in the wake model."
            return 0
        var i: Int, j: Int
        var wt_id: List[Int] = List[Int](capacity=self.nTurbines)
        var wid: Int
        for i in range(self.nTurbines):
            wt_id.append(i)
        var fAirDensity: Float64 = (airPressureAtm * Pa_PER_Atm) / (R_GAS_DRY_AIR * CelciusToKelvin(TdryC))
        var fTurbine_output: Float64 = 0.0
        var fThrust_coeff: Float64 = 0.0
        var fTurbine_gross: Float64 = 0.0
        self.windTurb.turbinePower(windSpeed, fAirDensity, Pointer[Float64].address_of(fTurbine_output), Pointer[Float64].address_of(fTurbine_gross), Pointer[Float64].address_of(fThrust_coeff))
        if len(self.windTurb.errDetails) > 0:
            self.errDetails = self.windTurb.errDetails
            return 0
        farmPowerGross[] = fTurbine_gross * Float64(self.nTurbines)
        for i in range(self.nTurbines):
            power[i] = 0.0
            thrust[i] = 0.0
            eff[i] = 0.0
            adWindSpeed[i] = windSpeed
            TI[i] = self.turbulenceIntensity
        if self.nTurbines < 2:
            farmPower[] = fTurbine_output
            return 1
        if fTurbine_output <= 0.0:
            farmPower[] = 0.0
            return self.nTurbines
        if self.wakeModel.getModelName() == "Constant":
            self.wakeModel.wakeCalculations(fAirDensity, distanceDownwind, distanceCrosswind, power, eff, thrust, adWindSpeed, TI)
            farmPower[] = power[0] * Float64(self.nTurbines)
            return self.nTurbines
        var d: Float64 = 0.0, c: Float64 = 0.0
        for i in range(self.nTurbines):
            var d_ptr: Pointer[Float64] = Pointer[Float64].address_of(d)
            var c_ptr: Pointer[Float64] = Pointer[Float64].address_of(c)
            self.coordtrans(self.YCoords[i], self.XCoords[i], windDirDeg, d_ptr, c_ptr)
            distanceDownwind[i] = d
            distanceCrosswind[i] = c
        var Dmin: Float64 = distanceDownwind[0]
        var Cmin: Float64 = distanceCrosswind[0]
        for j in range(1, self.nTurbines):
            Dmin = min_of(distanceDownwind[j], Dmin)
            Cmin = min_of(distanceCrosswind[j], Cmin)
        for j in range(self.nTurbines):
            distanceDownwind[j] = distanceDownwind[j] - Dmin
            distanceCrosswind[j] = distanceCrosswind[j] - Cmin
        for i in range(self.nTurbines):
            distanceDownwind[i] = 2.0 * distanceDownwind[i] / self.windTurb.rotorDiameter
            distanceCrosswind[i] = 2.0 * distanceCrosswind[i] / self.windTurb.rotorDiameter
        power[0] = fTurbine_output
        thrust[0] = fThrust_coeff
        eff[0] = 0.0 if fTurbine_output < 1.0 else 100.0
        for j in range(1, self.nTurbines):
            d = distanceDownwind[j]
            c = distanceCrosswind[j]
            wid = wt_id[j]
            i = j
            while i > 0 and distanceDownwind[i - 1] > d:
                distanceDownwind[i] = distanceDownwind[i - 1]
                distanceCrosswind[i] = distanceCrosswind[i - 1]
                wt_id[i] = wt_id[i - 1]
                i -= 1
            distanceDownwind[i] = d
            distanceCrosswind[i] = c
            wt_id[i] = wid
        self.wakeModel.wakeCalculations(fAirDensity, distanceDownwind, distanceCrosswind, power, eff, thrust, adWindSpeed, TI)
        if len(self.wakeModel.errDetails) > 0:
            self.errDetails = self.wakeModel.errDetails
            return 0
        farmPower[] = 0.0
        for i in range(self.nTurbines):
            farmPower[] += power[i]
        distanceDownwind[0] *= self.windTurb.rotorDiameter / 2.0
        distanceCrosswind[0] *= self.windTurb.rotorDiameter / 2.0
        var p: Float64 = 0.0, t: Float64 = 0.0, e: Float64 = 0.0, w: Float64 = 0.0, b: Float64 = 0.0, dd: Float64 = 0.0, dc: Float64 = 0.0
        for j in range(1, self.nTurbines):
            p = power[j]
            t = thrust[j]
            e = eff[j]
            w = adWindSpeed[j]
            b = TI[j]
            dd = distanceDownwind[j] * self.windTurb.rotorDiameter / 2.0
            dc = distanceCrosswind[j] * self.windTurb.rotorDiameter / 2.0
            wid = wt_id[j]
            i = j
            while i > 0 and wt_id[i - 1] > wid:
                power[i] = power[i - 1]
                thrust[i] = thrust[i - 1]
                eff[i] = eff[i - 1]
                adWindSpeed[i] = adWindSpeed[i - 1]
                TI[i] = TI[i - 1]
                distanceDownwind[i] = distanceDownwind[i - 1]
                distanceCrosswind[i] = distanceCrosswind[i - 1]
                wt_id[i] = wt_id[i - 1]
                i -= 1
            power[i] = p
            thrust[i] = t
            eff[i] = e
            adWindSpeed[i] = w
            TI[i] = b
            distanceDownwind[i] = dd
            distanceCrosswind[i] = dc
            wt_id[i] = wid
        return self.nTurbines

    def windPowerUsingWeibull(self, weibull_k: Float64, avg_speed: Float64, ref_height: Float64, energy_turbine: Pointer[Float64]) -> Float64:
        var hub_ht_windspeed: Float64 = pow((self.windTurb.hubHeight / ref_height), self.windTurb.shearExponent) * avg_speed
        var denom: Float64 = exp(self.gammaln(1.0 + (1.0 / weibull_k)))
        var lambda: Float64 = hub_ht_windspeed / denom
        var total_energy_turbine: Float64 = 0.0
        var weibull_cummulative: List[Float64] = List[Float64](repeating=0.0, count=self.windTurb.powerCurveArrayLength)
        var weibull_bin: List[Float64] = List[Float64](repeating=0.0, count=self.windTurb.powerCurveArrayLength)
        weibull_cummulative[0] = 1.0 - exp(-pow((0.125) / lambda, weibull_k))
        weibull_bin[0] = weibull_cummulative[0]
        energy_turbine[0] = 0.0
        for i in range(1, self.windTurb.powerCurveArrayLength):
            weibull_cummulative[i] = 1.0 - exp(-pow((self.windTurb.getPowerCurveWS()[i] + 0.125) / lambda, weibull_k))
            weibull_bin[i] = weibull_cummulative[i] - weibull_cummulative[i - 1]
            energy_turbine[i] = (8760.0 * weibull_bin[i]) * self.windTurb.getPowerCurveKW()[i]
            total_energy_turbine += energy_turbine[i]
        return total_energy_turbine

    def windPowerUsingDistribution(self, inout wind_dist: List[List[Float64]], farmPower: Pointer[Float64], farmPowerGross: Pointer[Float64]) -> Bool:
        if not self.wakeModel:
            self.errDetails = "Wake model not initialized."
            return False
        if (self.nTurbines > MAX_WIND_TURBINES) or (self.nTurbines < 1):
            self.errDetails = "The number of wind turbines was greater than the maximum allowed in the wake model."
            return False
        var i: Int, j: Int
        var wt_id: List[Int] = List[Int](capacity=self.nTurbines)
        var wid: Int
        for i in range(self.nTurbines):
            wt_id.append(i)
        var freq_total: Float64 = 0.0
        var farmpower: Float64 = 0.0
        var farmgross: Float64 = 0.0
        for row in wind_dist:
            var windSpeed: Float64 = row[0]
            var windDirDeg: Float64 = row[1]
            freq_total += row[2]
            var fTurbine_output: Float64 = 0.0
            var fThrust_coeff: Float64 = 0.0
            var fTurbine_gross: Float64 = 0.0
            self.windTurb.turbinePower(windSpeed, AIR_DENSITY_SEA_LEVEL, Pointer[Float64].address_of(fTurbine_output), Pointer[Float64].address_of(fTurbine_gross), Pointer[Float64].address_of(fThrust_coeff))
            if len(self.windTurb.errDetails) > 0:
                self.errDetails = self.windTurb.errDetails
                return False
            if self.nTurbines < 2:
                farmpower += fTurbine_output
                continue
            if fTurbine_output <= 0.0:
                continue
            var d: Float64 = 0.0, c: Float64 = 0.0
            var distanceDownwind: List[Float64] = List[Float64](capacity=self.nTurbines)
            var distanceCrosswind: List[Float64] = List[Float64](capacity=self.nTurbines)
            for _ in range(self.nTurbines):
                distanceDownwind.append(0.0)
                distanceCrosswind.append(0.0)
            for i in range(self.nTurbines):
                var d_ptr: Pointer[Float64] = Pointer[Float64].address_of(d)
                var c_ptr: Pointer[Float64] = Pointer[Float64].address_of(c)
                self.coordtrans(self.YCoords[i], self.XCoords[i], windDirDeg, d_ptr, c_ptr)
                distanceDownwind[i] = d
                distanceCrosswind[i] = c
            var Dmin: Float64 = distanceDownwind[0]
            var Cmin: Float64 = distanceCrosswind[0]
            for j in range(1, self.nTurbines):
                Dmin = min_of(distanceDownwind[j], Dmin)
                Cmin = min_of(distanceCrosswind[j], Cmin)
            for j in range(self.nTurbines):
                distanceDownwind[j] = distanceDownwind[j] - Dmin
                distanceCrosswind[j] = distanceCrosswind[j] - Cmin
            for i in range(self.nTurbines):
                distanceDownwind[i] = 2.0 * distanceDownwind[i] / self.windTurb.rotorDiameter
                distanceCrosswind[i] = 2.0 * distanceCrosswind[i] / self.windTurb.rotorDiameter
            for j in range(1, self.nTurbines):
                d = distanceDownwind[j]
                c = distanceCrosswind[j]
                wid = wt_id[j]
                i = j
                while i > 0 and distanceDownwind[i - 1] > d:
                    distanceDownwind[i] = distanceDownwind[i - 1]
                    distanceCrosswind[i] = distanceCrosswind[i - 1]
                    wt_id[i] = wt_id[i - 1]
                    i -= 1
                distanceDownwind[i] = d
                distanceCrosswind[i] = c
                wt_id[i] = wid
            var power: List[Float64] = List[Float64](repeating=fTurbine_output, count=self.nTurbines)
            var eff: List[Float64] = List[Float64](repeating=0.0, count=self.nTurbines)
            var thrust: List[Float64] = List[Float64](repeating=0.0, count=self.nTurbines)
            var adWindSpeed: List[Float64] = List[Float64](repeating=windSpeed, count=self.nTurbines)
            var TI: List[Float64] = List[Float64](repeating=self.turbulenceIntensity, count=self.nTurbines)
            self.wakeModel.wakeCalculations(AIR_DENSITY_SEA_LEVEL, Pointer[Float64](distanceDownwind.data()), Pointer[Float64](distanceCrosswind.data()), Pointer[Float64](power.data()), Pointer[Float64](eff.data()), Pointer[Float64](thrust.data()), Pointer[Float64](adWindSpeed.data()), Pointer[Float64](TI.data()))
            if len(self.wakeModel.errDetails) > 0:
                self.errDetails = self.wakeModel.errDetails
                return False
            var freq: Float64 = 8760.0 * row[2]
            for i in range(self.nTurbines):
                farmpower += freq * power[i]
            farmgross += freq * fTurbine_gross * Float64(self.nTurbines)
        if fabs(freq_total - 1.0) > 0.01:
            self.errDetails = "Sum of wind resource distribution frequencies must be 1."
            return False
        farmPower[] = farmpower
        farmPowerGross[] = farmgross
        return True