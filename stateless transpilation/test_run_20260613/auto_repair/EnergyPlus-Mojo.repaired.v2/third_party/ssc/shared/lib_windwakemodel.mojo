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
from lib_physics import AIR_DENSITY_SEA_LEVEL, PI
from lib_util import matrix_t, interpolate, max_of, min_of
from lib_windwatts import *
from lib_windwakemodel import windTurbine, wakeModelBase, simpleWakeModel, parkWakeModel, eddyViscosityWakeModel, constantWakeModel

# The following implementations are from lib_windwakemodel.cpp

def windTurbine.setPowerCurve(self: Self, windSpeeds: List[Float64], powerOutput: List[Float64]) -> Bool:
    if windSpeeds.size() == powerOutput.size():
        self.powerCurveArrayLength = windSpeeds.size()
    else:
        self.errDetails = "Turbine power curve array sizes are unequal."
        return 0
    
    self.powerCurveWS = windSpeeds
    self.powerCurveKW = powerOutput
    self.densityCorrectedWS = self.powerCurveWS
    self.powerCurveRPM = List[Float64]()
    for _ in range(self.powerCurveArrayLength):
        self.powerCurveRPM.append(-1.0)
    return 1

def windTurbine.tipSpeedRatio(self: Self, windSpeed: Float64) -> Float64:
    if self.powerCurveRPM[0] == -1.0:
        return 7.0
    var rpm: Float64 = 0.0
    if (windSpeed > self.powerCurveWS[0]) and (windSpeed < self.powerCurveWS[self.powerCurveArrayLength - 1]):
        var j: Int = 1
        while self.powerCurveWS[j] <= windSpeed:
            j += 1  # find first m_adPowerCurveRPM > fWindSpeedAtHubHeight
        rpm = interpolate(self.powerCurveWS[j - 1], self.powerCurveRPM[j - 1], self.powerCurveWS[j], self.powerCurveRPM[j], windSpeed)
    else:
        if windSpeed == self.powerCurveWS[self.powerCurveArrayLength - 1]:
            rpm = self.powerCurveRPM[self.powerCurveArrayLength - 1]  # rpm -> zero if wind speed greater than maximum in the array
    return (rpm > 0.0) ? rpm * self.rotorDiameter * PI / (windSpeed * 60.0) : 7.0

def windTurbine.turbinePower(self: Self, windVelocity: Float64, airDensity: Float64, turbineOutput: *Float64, turbineGross: *Float64, thrustCoefficient: *Float64):
    if not self.isInitialized():
        self.errDetails = "windTurbine not initialized with necessary data"
        return
    
    thrustCoefficient[] = 0.0
    turbineOutput[] = 0.0
    
    if fabs(airDensity - self.previousAirDensity) > 0.001:
        var correction = pow((AIR_DENSITY_SEA_LEVEL / airDensity), (1.0 / 3.0))
        for i in range(self.densityCorrectedWS.size()):
            self.densityCorrectedWS[i] = self.powerCurveWS[i] * correction
        self.previousAirDensity = airDensity
    
    var i: Int = 0
    while self.powerCurveKW[i] == 0.0:
        i += 1  # find the index of the first non-zero power output in the power curve
    
    self.cutInSpeed = self.densityCorrectedWS[i - 1]
    # We will continue not to check cut-out speed because currently the model will interpolate between the last non-zero power point and zero, and we don't have a better definition of where the power cutoff should be.
    # i = m_adPowerCurveKW.size() - 1; //last index in the array
    # while (m_adPowerCurveKW[i] == 0)
    # i--; //find the index of the last non-zero power output in the power curve
    # m_dCutOutSpeed = m_adPowerCurveWS[i]; //unlike cut in speed, we want power to hard cut AFTER this wind speed value
    
    var out_pwr: Float64 = 0.0
    if (windVelocity > self.densityCorrectedWS[0]) and (windVelocity < self.densityCorrectedWS[self.powerCurveArrayLength - 1]):
        var j: Int = 1
        while self.densityCorrectedWS[j] <= windVelocity:
            j += 1  # find first m_adPowerCurveWS > windVelocity
        out_pwr = interpolate(self.densityCorrectedWS[j - 1], self.powerCurveKW[j - 1], self.densityCorrectedWS[j], self.powerCurveKW[j], windVelocity)
    else:
        if windVelocity == self.densityCorrectedWS[self.powerCurveArrayLength - 1]:
            out_pwr = self.powerCurveKW[self.powerCurveArrayLength - 1]
    
    if windVelocity < self.cutInSpeed:
        out_pwr = 0.0  # this is effectively redundant, because the power at the cut-in speed is defined to be 0, above, so anything below that will also be 0, but leave in for completeness
    
    if out_pwr > 0.0:
        if turbineGross:
            turbineGross[] = out_pwr
        var pden: Float64 = 0.5 * airDensity * pow(windVelocity, 3.0)
        var area: Float64 = PI / 4.0 * self.rotorDiameter * self.rotorDiameter
        var fPowerCoefficient: Float64 = max_of(0.0, 1000.0 * out_pwr / (pden * area))
        turbineOutput[] = out_pwr
        if fPowerCoefficient >= 0.0:
            thrustCoefficient[] = max_of(0.0, -1.453989e-2 + 1.473506 * fPowerCoefficient - 2.330823 * pow(fPowerCoefficient, 2) + 3.885123 * pow(fPowerCoefficient, 3))
    # out_pwr > (rated power * 0.001)
    return

def simpleWakeModel.velDeltaPQ(self: Self, radiiCrosswind: Float64, axialDistInRadii: Float64, thrustCoeff: Float64, newTurbulenceIntensity: *Float64) -> Float64:
    if radiiCrosswind > 20.0 or newTurbulenceIntensity[] <= 0.0 or axialDistInRadii <= 0.0 or thrustCoeff <= 0.0:
        return 0.0
    
    var fAddedTurbulence: Float64 = (thrustCoeff / 7.0) * (1.0 - (2.0 / 5.0) * log(2.0 * axialDistInRadii))
    newTurbulenceIntensity[] = sqrt(pow(fAddedTurbulence, 2.0) + pow(newTurbulenceIntensity[], 2.0))
    
    var AA: Float64 = pow(newTurbulenceIntensity[], 2.0) * pow(axialDistInRadii, 2.0)
    var fExp: Float64 = max_of(-99.0, (-pow(radiiCrosswind, 2.0) / (2.0 * AA)))
    var dVelocityDeficit: Float64 = (thrustCoeff / (4.0 * AA)) * exp(fExp)
    return max_of(min_of(dVelocityDeficit, 1.0), 0.0)  # limit result from zero to one

def simpleWakeModel.wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
    power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
    for i in range(1, self.nTurbines):  # loop through all turbines, starting with most upwind turbine. i=0 has already been done
        var dDeficit: Float64 = 1.0
        for j in range(i):  # loop through all turbines upwind of turbine[i]
            var fDistanceDownwind: Float64 = fabs(distanceDownwind[j] - distanceDownwind[i])
            var fDistanceCrosswind: Float64 = fabs(distanceCrosswind[j] - distanceCrosswind[i])
            var vdef: Float64 = self.velDeltaPQ(fDistanceCrosswind, fDistanceDownwind, thrust[j], turbulenceIntensity[i].__ref__())
            dDeficit *= (1.0 - vdef)
        # turbulenceIntensity[i] already modified via pointer in velDeltaPQ
        windSpeed[i] = windSpeed[i] * dDeficit
        self.wTurbine.turbinePower(windSpeed[i], airDensity, power[i].__ref__(), None, thrust[i].__ref__())
        if self.wTurbine.errDetails.length() > 0:
            self.errDetails = self.wTurbine.errDetails
            return
        eff[i] = self.wTurbine.calculateEff(power[i], power[0])
    eff[0] = 100.0

def parkWakeModel.circle_overlap(self: Self, dist_center_to_center: Float64, rad1: Float64, rad2: Float64) -> Float64:
    # Source: http://mathworld.wolfram.com/Circle-CircleIntersection.html, equation 14
    if dist_center_to_center < 0.0 or rad1 < 0.0 or rad2 < 0.0:
        return 0.0
    if dist_center_to_center >= rad1 + rad2:
        return 0.0
    if rad1 >= dist_center_to_center + rad2:
        return PI * pow(rad2, 2)  # overlap = area of circle 2
    if rad2 >= dist_center_to_center + rad1:
        return PI * pow(rad1, 2)  # overlap = area of circle 1 ( if rad1 is turbine, it's completely inside wake)
    var t1: Float64 = pow(rad1, 2) * acos((pow(dist_center_to_center, 2) + pow(rad1, 2) - pow(rad2, 2)) / (2 * dist_center_to_center * rad1))
    var t2: Float64 = pow(rad2, 2) * acos((pow(dist_center_to_center, 2) + pow(rad2, 2) - pow(rad1, 2)) / (2 * dist_center_to_center * rad2))
    var t3: Float64 = 0.5 * sqrt((-dist_center_to_center + rad1 + rad2) * (dist_center_to_center + rad1 - rad2) * (dist_center_to_center - rad1 + rad2) * (dist_center_to_center + rad1 + rad2))
    return t1 + t2 - t3

def parkWakeModel.delta_V_Park(self: Self, Uo: Float64, Ui: Float64, distCrosswind: Float64, distDownwind: Float64, dRadiusUpstream: Float64, dRadiusDownstream: Float64, dThrustCoeff: Float64) -> Float64:
    var Ct: Float64 = max_of(min_of(0.999, dThrustCoeff), self.minThrustCoeff)
    var k: Float64 = self.wakeDecayCoefficient
    var dRadiusOfWake: Float64 = dRadiusUpstream + (k * distDownwind)  # radius of circle formed by wake from upwind rotor
    var dAreaOverlap: Float64 = self.circle_overlap(distCrosswind, dRadiusDownstream, dRadiusOfWake)
    if dAreaOverlap <= 0.0:
        return Uo
    var dDef: Float64 = (1.0 - sqrt(1.0 - Ct)) * pow(dRadiusUpstream / dRadiusOfWake, 2) * (dAreaOverlap / (PI * dRadiusDownstream * dRadiusDownstream))
    return Ui * (1.0 - dDef)

def parkWakeModel.wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
    power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
    var turbineRadius: Float64 = self.wTurbine.rotorDiameter / 2.0
    for i in range(1, self.nTurbines):  # downwind turbines, i=0 has already been done
        var newSpeed: Float64 = windSpeed[0]
        for j in range(i):  # upwind turbines
            var distanceDownwindMeters: Float64 = turbineRadius * fabs(distanceDownwind[i] - distanceDownwind[j])
            var distanceCrosswindMeters: Float64 = turbineRadius * fabs(distanceCrosswind[i] - distanceCrosswind[j])
            newSpeed = min_of(newSpeed, self.delta_V_Park(windSpeed[0], windSpeed[j], distanceCrosswindMeters, distanceDownwindMeters, turbineRadius, turbineRadius, thrust[j]))
        windSpeed[i] = newSpeed
        self.wTurbine.turbinePower(windSpeed[i], airDensity, power[i].__ref__(), None, thrust[i].__ref__())
        if self.wTurbine.errDetails.length() > 0:
            self.errDetails = self.wTurbine.errDetails
            return
        eff[i] = self.wTurbine.calculateEff(power[i], power[0])
    eff[0] = 100.0

def eddyViscosityWakeModel.getVelocityDeficit(self: Self, upwindTurbine: Int, axialDistanceInDiameters: Float64) -> Float64:
    var dDistPastMin: Float64 = axialDistanceInDiameters - self.MIN_DIAM_EV  # in diameters
    if dDistPastMin < 0.0:
        return self.rotorDiameter * self.matEVWakeDeficits.at(upwindTurbine, 0)
    var dDistInResolutionUnits: Float64 = dDistPastMin / self.axialResolution
    var iLowerIndex: Int = Int(dDistInResolutionUnits)
    var iUpperIndex: Int = iLowerIndex + 1
    if iUpperIndex >= self.matEVWakeDeficits.ncols():
        return 0.0
    dDistInResolutionUnits -= Float64(iLowerIndex)
    return (self.matEVWakeDeficits.at(upwindTurbine, iLowerIndex) * (1.0 - dDistInResolutionUnits)) + (self.matEVWakeDeficits.at(upwindTurbine, iUpperIndex) * dDistInResolutionUnits)  # in meters

def eddyViscosityWakeModel.wakeDeficit(self: Self, upwindTurbine: Int, distCrosswind: Float64, distDownwind: Float64) -> Float64:
    var dDef: Float64 = self.getVelocityDeficit(upwindTurbine, distDownwind)
    if dDef <= 0.0:
        return 0.0
    var dSteps: Float64 = 25.0
    var dCrossWindDistanceInMeters: Float64 = distCrosswind * self.rotorDiameter
    var dWidth: Float64 = self.getWakeWidth(upwindTurbine, distDownwind)
    var dRadius: Float64 = self.rotorDiameter / 2.0
    var dStep: Float64 = self.rotorDiameter / dSteps
    var dTotal: Float64 = 0.0
    var y: Float64 = dCrossWindDistanceInMeters - dRadius
    while y <= dCrossWindDistanceInMeters + dRadius:
        dTotal += dDef * exp(-3.56 * (((y * y)) / (dWidth * dWidth)))  # exp term ranges from >zero to one
        y += dStep
    dTotal /= (dSteps + 1.0)  # average of all terms above will be zero to dDef
    return dTotal

def eddyViscosityWakeModel.getWakeWidth(self: Self, upwindTurbine: Int, axialDistanceInDiameters: Float64) -> Float64:
    var dDistPastMin: Float64 = axialDistanceInDiameters - self.MIN_DIAM_EV  # in diameters
    if dDistPastMin < 0.0:
        return self.rotorDiameter * self.matEVWakeWidths.at(upwindTurbine, 0)
    var dDistInResolutionUnits: Float64 = dDistPastMin / self.axialResolution
    var iLowerIndex: Int = Int(dDistInResolutionUnits)
    var iUpperIndex: Int = iLowerIndex + 1
    dDistInResolutionUnits -= Float64(iLowerIndex)
    if iUpperIndex >= self.matEVWakeWidths.ncols():
        return 0.0
    return self.rotorDiameter * max_of(1.0, (self.matEVWakeWidths.at(upwindTurbine, iLowerIndex) * (1.0 - dDistInResolutionUnits) + self.matEVWakeWidths.at(upwindTurbine, iUpperIndex) * dDistInResolutionUnits))  # in meters

def eddyViscosityWakeModel.addedTurbulenceIntensity(self: Self, Ct: Float64, deltaX: Float64) -> Float64:
    if deltaX == 0.0:
        return 0.0
    return max_of(0.0, (Ct / 7.0) * (1.0 - (2.0 / 5.0) * log(deltaX / self.rotorDiameter)))

def eddyViscosityWakeModel.nearWakeRegionLength(self: Self, U: Float64, Ii: Float64, Ct: Float64, airDensity: Float64, vmln: VMLN):
    Ct = max_of(min_of(0.999, Ct), self.minThrustCoeff)
    var dr_dx: Float64
    var m: Float64 = 1.0 / sqrt(1.0 - Ct)
    var r0: Float64 = 0.5 * self.rotorDiameter * sqrt((m + 1.0) / 2.0)
    var t1: Float64 = sqrt(0.214 + 0.144 * m)
    var t2: Float64 = sqrt(0.134 + 0.124 * m)
    var n: Float64 = (t1 * (1.0 - t2)) / ((1.0 - t1) * t2)
    var dr_dx_A: Float64 = Ii < 2.0 ? 0.05 * Ii : 0.025 * Ii + 0.05  # from original TNO report
    var dr_dx_M: Float64 = ((1.0 - m) * sqrt(1.49 + m)) / ((1.0 + m) * 9.76)
    var dr_dx_L: Float64 = 0.012 * Float64(self.nBlades) * self.wTurbine.tipSpeedRatio(U)
    dr_dx = sqrt(dr_dx_A * dr_dx_A + dr_dx_M * dr_dx_M + dr_dx_L * dr_dx_L)  # wake growth rate
    vmln.m = m
    vmln.diam = self.rotorDiameter
    vmln.Xh = r0 / dr_dx  # end of region 1
    vmln.Xn = n * vmln.Xh  # end of region 2
    return

def eddyViscosityWakeModel.simpleIntersect(self: Self, distToCenter: Float64, radiusTurbine: Float64, radiusWake: Float64) -> Float64:
    # returns the fraction of overlap, NOT an area
    if distToCenter < 0.0 or radiusTurbine < 0.0 or radiusWake < 0.0:
        return 0.0
    if distToCenter > radiusTurbine + radiusWake:
        return 0.0
    if radiusWake >= distToCenter + radiusTurbine:
        return 1.0  # turbine completely inside wake
    return min_of(1.0, max_of(0.0, (radiusTurbine + radiusWake - distToCenter) / (2.0 * radiusTurbine)))

def eddyViscosityWakeModel.totalTurbulenceIntensity(self: Self, ambientTI: Float64, additionalTI: Float64, Uo: Float64, Uw: Float64, partial: Float64) -> Float64:
    if Uw <= 0.0:
        return ambientTI
    var f: Float64 = max_of(0.0, ambientTI * ambientTI + additionalTI * additionalTI)
    f = sqrt(f) * Uo / Uw
    return (1.0 - partial) * ambientTI + partial * f

def eddyViscosityWakeModel.fillWakeArrays(self: Self, turbineIndex: Int, ambientVelocity: Float64, velocityAtTurbine: Float64, power: Float64, thrustCoeff: Float64, turbulenceIntensity: Float64, metersToFurthestDownwindTurbine: Float64) -> Bool:
    if power <= 0.0:
        return True  # no wake effect - wind speed is below cut-in, or above cut-out
    if thrustCoeff <= 0.0:
        return True  # i.e. there is no wake (both arrays were initialized with zeros, so they just stay that way)
    thrustCoeff = max_of(min_of(0.999, thrustCoeff), self.minThrustCoeff)
    turbulenceIntensity = min_of(turbulenceIntensity, 50.0)  # to avoid turbines with high TIs having no wake
    var Dm: Float64
    var Dmi: Float64
    const K: Float64 = 0.4  # Ainslee 1988 (notation)
    const K1: Float64 = 0.015  # Ainslee 1988 (page 217: input parameters)
    var F: Float64
    var x: Float64 = self.MIN_DIAM_EV  # actual distance in rotor diameters
    if x >= 5.5 or not self.useFilterFx:
        F = 1.0
    else:
        F = 0.65 - pow(-(x - 4.5) / 23.32, 1.0 / 3.0) if x < 4.5 else 0.65 + pow((x - 4.5) / 23.32, 1.0 / 3.0)
    var Km: Float64 = F * K * K * turbulenceIntensity / 100.0  # also known as the ambient eddy viscosity???
    Dm = max_of(0.0, thrustCoeff - 0.05 - ((16.0 * thrustCoeff - 0.5) * turbulenceIntensity / 1000.0))  # Ainslee 1988 (5)
    Dmi = Dm
    if Dmi <= 0.0:
        return True
    var Uc: Float64 = velocityAtTurbine - Dmi * velocityAtTurbine  # assuming Uc is the initial centreline velocity at 2 diameters downstream
    Dm = (ambientVelocity - Uc) / ambientVelocity
    Dmi = Dm
    var Bw: Float64 = sqrt(3.56 * thrustCoeff / (8.0 * Dmi * (1.0 - 0.5 * Dmi)))  # Ainslee 1988 (6)
    var E: Float64 = F * K1 * Bw * Dm * Float64(self.EV_SCALE) + Km
    var m_d2U: List[Float64] = List[Float64](self.matEVWakeDeficits.ncols())
    for idx in range(self.matEVWakeDeficits.ncols()):
        m_d2U.append(0.0)  # placeholder, will be assigned
    m_d2U[0] = Float64(self.EV_SCALE) * (1.0 - Dmi)
    self.matEVWakeDeficits.at(turbineIndex, 0) = Dmi
    self.matEVWakeWidths.at(turbineIndex, 0) = Bw
    for j in range(self.matEVWakeDeficits.ncols() - 1):
        x = Float64(self.MIN_DIAM_EV) + Float64(j) * self.axialResolution
        if x >= 5.5 or not self.useFilterFx:
            F = 1.0
        else:
            F = 0.65 - pow(-(x - 4.5) / 23.32, 1.0 / 3.0) if x < 4.5 else 0.65 + pow((x - 4.5) / 23.32, 1.0 / 3.0)  # for some reason pow() does not deal with -ve numbers even though excel does
        Km = F * K * K * turbulenceIntensity / 100.0
        E = F * K1 * Bw * (Dm * Float64(self.EV_SCALE)) + Km
        var dUdX: Float64 = 16.0 * (pow(m_d2U[j], 3.0) - pow(m_d2U[j], 2.0) - m_d2U[j] + 1.0) * E / (m_d2U[j] * thrustCoeff)
        m_d2U[j + 1] = m_d2U[j] + dUdX * self.axialResolution
        Dm = (Float64(self.EV_SCALE) - m_d2U[j + 1]) / Float64(self.EV_SCALE)
        Bw = sqrt(3.56 * thrustCoeff / (8.0 * Dm * (1.0 - 0.5 * Dm)))
        self.matEVWakeDeficits.at(turbineIndex, j + 1) = Dm  # fractional deficit
        self.matEVWakeWidths.at(turbineIndex, j + 1) = Bw  # diameters
        if Dm <= self.minDeficit or x > metersToFurthestDownwindTurbine + self.axialResolution or j >= self.matEVWakeDeficits.ncols() - 2:
            break
    return True

def eddyViscosityWakeModel.wakeCalculations(self: Self, air_density: Float64, aDistanceDownwind: List[Float64], aDistanceCrosswind: List[Float64],
    power: List[Float64], eff: List[Float64], Thrust: List[Float64], adWindSpeed: List[Float64], aTurbulence_intensity: List[Float64]):
    var dTurbineRadius: Float64 = self.rotorDiameter / 2.0
    self.matEVWakeDeficits.fill(0.0)
    self.matEVWakeWidths.fill(0.0)
    var vmln: List[VMLN] = List[VMLN]()
    for _ in range(self.nTurbines):
        vmln.append(VMLN())
    var Iamb: List[Float64] = List[Float64]()
    for _ in range(self.nTurbines):
        Iamb.append(self.turbulenceCoeff)
    for i in range(self.nTurbines):  # downwind turbines, but starting with most upwind and working downwind
        var dDeficit: Float64 = 0.0
        var Iadd: Float64 = 0.0
        var dTotalTI: Float64 = aTurbulence_intensity[i]
        for j in range(i):  # upwind turbines - turbines upwind of turbine[i]
            var dDistAxialInDiameters: Float64 = fabs(aDistanceDownwind[i] - aDistanceDownwind[j]) / 2.0
            if fabs(dDistAxialInDiameters) <= 0.0001:
                continue  # if this turbine isn't really upwind, move on to the next
            var dDistRadialInDiameters: Float64 = fabs(aDistanceCrosswind[i] - aDistanceCrosswind[j]) / 2.0
            var dWakeRadiusMeters: Float64 = self.getWakeWidth(Int(j), dDistAxialInDiameters)  # the radius of the wake
            if dWakeRadiusMeters <= 0.0:
                continue
            var dDef: Float64 = self.wakeDeficit(Int(j), dDistRadialInDiameters, dDistAxialInDiameters)
            var dWindSpeedWaked: Float64 = adWindSpeed[0] * (1.0 - dDef)  # wind speed = free stream * (1-deficit)
            dDeficit = max_of(dDeficit, dDef)
            Iadd = self.addedTurbulenceIntensity(Thrust[j], dDistAxialInDiameters * self.rotorDiameter)
            var dFractionOfOverlap: Float64 = self.simpleIntersect(dDistRadialInDiameters * self.rotorDiameter, dTurbineRadius, dWakeRadiusMeters)
            dTotalTI = max_of(dTotalTI, self.totalTurbulenceIntensity(aTurbulence_intensity[i], Iadd, adWindSpeed[0], dWindSpeedWaked, dFractionOfOverlap))
        adWindSpeed[i] = adWindSpeed[0] * (1.0 - dDeficit)
        aTurbulence_intensity[i] = dTotalTI
        self.wTurbine.turbinePower(adWindSpeed[i], air_density, power[i].__ref__(), None, Thrust[i].__ref__())
        if self.wTurbine.errDetails.length() > 0:
            self.errDetails = self.wTurbine.errDetails
            return
        eff[i] = self.wTurbine.calculateEff(power[i], power[0])
        if not self.fillWakeArrays(Int(i), adWindSpeed[0], adWindSpeed[i], power[i], Thrust[i], aTurbulence_intensity[i], fabs(aDistanceDownwind[self.nTurbines - 1] - aDistanceDownwind[i]) * dTurbineRadius):
            if self.errDetails.length() == 0:
                self.errDetails = "Could not calculate the turbine wake arrays in the Eddy-Viscosity model."
        self.nearWakeRegionLength(adWindSpeed[i], Iamb[i], Thrust[i], air_density, vmln[i])

def constantWakeModel.wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
    power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
    var turbPower: Float64 = 0.0
    var turbThrust: Float64 = 0.0
    self.wTurbine.turbinePower(windSpeed[0], airDensity, turbPower.__ref__(), None, turbThrust.__ref__())
    if self.wTurbine.errDetails.length() > 0:
        self.errDetails = self.wTurbine.errDetails
        return
    turbPower *= self.derate
    for i in range(self.nTurbines):
        power[i] = turbPower
        thrust[i] = turbThrust
        eff[i] = 100.0

# Note: The following struct definitions are expected to be provided by lib_windwakemodel.mojo (the header part)
# but since we are translating the implementation only, we assume they are already defined.
# To keep the file self-contained, we include them here.

struct VMLN:
    var m: Float64 = 0.0
    var Ro: Float64 = 0.0
    var Xh: Float64 = 0.0
    var Xn: Float64 = 0.0
    var Rh: Float64 = 0.0
    var Rn: Float64 = 0.0
    var Xf: Float64 = 0.0
    var Rf: Float64 = 0.0
    var dUc_Uinf_Xn: Float64 = 0.0
    var diam: Float64 = 0.0
    def __init__(self): pass
    def __del__(self): pass

trait WakeModelBase:
    def getModelName(self) -> String
    def wakeCalculations(self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
        power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64])

struct windTurbine:
    var powerCurveWS: List[Float64] = List[Float64]()
    var powerCurveKW: List[Float64] = List[Float64]()
    var densityCorrectedWS: List[Float64] = List[Float64]()
    var powerCurveRPM: List[Float64] = List[Float64]()
    var cutInSpeed: Float64 = 0.0
    var previousAirDensity: Float64 = 0.0
    var powerCurveArrayLength: Int = 0
    var rotorDiameter: Float64 = -999.0
    var hubHeight: Float64 = -999.0
    var measurementHeight: Float64 = -999.0
    var shearExponent: Float64 = -999.0
    var errDetails: String = ""
    
    def __init__(self):
        self.shearExponent = -999.0
        self.measurementHeight = -999.0
        self.hubHeight = -999.0
        self.rotorDiameter = -999.0
        self.previousAirDensity = AIR_DENSITY_SEA_LEVEL
    
    def __del__(self): pass

    def setPowerCurve(self: Self, windSpeeds: List[Float64], powerOutput: List[Float64]) -> Bool:
        if windSpeeds.size() == powerOutput.size():
            self.powerCurveArrayLength = windSpeeds.size()
        else:
            self.errDetails = "Turbine power curve array sizes are unequal."
            return 0
        self.powerCurveWS = windSpeeds
        self.powerCurveKW = powerOutput
        self.densityCorrectedWS = self.powerCurveWS
        self.powerCurveRPM = List[Float64]()
        for _ in range(self.powerCurveArrayLength):
            self.powerCurveRPM.append(-1.0)
        return 1

    def tipSpeedRatio(self: Self, windSpeed: Float64) -> Float64:
        if self.powerCurveRPM[0] == -1.0:
            return 7.0
        var rpm: Float64 = 0.0
        if (windSpeed > self.powerCurveWS[0]) and (windSpeed < self.powerCurveWS[self.powerCurveArrayLength - 1]):
            var j: Int = 1
            while self.powerCurveWS[j] <= windSpeed:
                j += 1
            rpm = interpolate(self.powerCurveWS[j - 1], self.powerCurveRPM[j - 1], self.powerCurveWS[j], self.powerCurveRPM[j], windSpeed)
        else:
            if windSpeed == self.powerCurveWS[self.powerCurveArrayLength - 1]:
                rpm = self.powerCurveRPM[self.powerCurveArrayLength - 1]
        return (rpm > 0.0) ? rpm * self.rotorDiameter * PI / (windSpeed * 60.0) : 7.0

    def isInitialized(self: Self) -> Bool:
        if self.shearExponent != -999.0 and self.measurementHeight != -999.0 and self.hubHeight != -999.0 and self.rotorDiameter != -999.0:
            if self.powerCurveArrayLength > 0:
                return True
        return False

    def turbinePower(self: Self, windVelocity: Float64, airDensity: Float64, turbineOutput: *Float64, turbineGross: *Float64, thrustCoefficient: *Float64):
        if not self.isInitialized():
            self.errDetails = "windTurbine not initialized with necessary data"
            return
        thrustCoefficient[] = 0.0
        turbineOutput[] = 0.0
        if fabs(airDensity - self.previousAirDensity) > 0.001:
            var correction = pow((AIR_DENSITY_SEA_LEVEL / airDensity), (1.0 / 3.0))
            for i in range(self.densityCorrectedWS.size()):
                self.densityCorrectedWS[i] = self.powerCurveWS[i] * correction
            self.previousAirDensity = airDensity
        var i: Int = 0
        while self.powerCurveKW[i] == 0.0:
            i += 1
        self.cutInSpeed = self.densityCorrectedWS[i - 1]
        var out_pwr: Float64 = 0.0
        if (windVelocity > self.densityCorrectedWS[0]) and (windVelocity < self.densityCorrectedWS[self.powerCurveArrayLength - 1]):
            var j: Int = 1
            while self.densityCorrectedWS[j] <= windVelocity:
                j += 1
            out_pwr = interpolate(self.densityCorrectedWS[j - 1], self.powerCurveKW[j - 1], self.densityCorrectedWS[j], self.powerCurveKW[j], windVelocity)
        else:
            if windVelocity == self.densityCorrectedWS[self.powerCurveArrayLength - 1]:
                out_pwr = self.powerCurveKW[self.powerCurveArrayLength - 1]
        if windVelocity < self.cutInSpeed:
            out_pwr = 0.0
        if out_pwr > 0.0:
            if turbineGross:
                turbineGross[] = out_pwr
            var pden: Float64 = 0.5 * airDensity * pow(windVelocity, 3.0)
            var area: Float64 = PI / 4.0 * self.rotorDiameter * self.rotorDiameter
            var fPowerCoefficient: Float64 = max_of(0.0, 1000.0 * out_pwr / (pden * area))
            turbineOutput[] = out_pwr
            if fPowerCoefficient >= 0.0:
                thrustCoefficient[] = max_of(0.0, -1.453989e-2 + 1.473506 * fPowerCoefficient - 2.330823 * pow(fPowerCoefficient, 2) + 3.885123 * pow(fPowerCoefficient, 3))
        return

    def calculateEff(self: Self, reducedPower: Float64, originalPower: Float64) -> Float64:
        var Eff: Float64 = 0.0
        if originalPower < 0.0:
            Eff = 0.0
        else:
            Eff = 100.0 * (reducedPower + 0.0001) / (originalPower + 0.0001)
        return Eff

struct simpleWakeModel(WakeModelBase):
    var nTurbines: Int = 0
    var wTurbine: windTurbine
    var errDetails: String = ""

    def __init__(self):
        self.nTurbines = 0
        # wTurbine will be set later
    def __init__(self, numberOfTurbinesInFarm: Int, wt: windTurbine):
        self.nTurbines = numberOfTurbinesInFarm
        self.wTurbine = wt
    def __del__(self): pass

    def getModelName(self: Self) -> String:
        return "PQ"

    def wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
        power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
        for i in range(1, self.nTurbines):
            var dDeficit: Float64 = 1.0
            for j in range(i):
                var fDistanceDownwind: Float64 = fabs(distanceDownwind[j] - distanceDownwind[i])
                var fDistanceCrosswind: Float64 = fabs(distanceCrosswind[j] - distanceCrosswind[i])
                var vdef: Float64 = self.velDeltaPQ(fDistanceCrosswind, fDistanceDownwind, thrust[j], turbulenceIntensity[i].__ref__())
                dDeficit *= (1.0 - vdef)
            windSpeed[i] = windSpeed[i] * dDeficit
            self.wTurbine.turbinePower(windSpeed[i], airDensity, power[i].__ref__(), None, thrust[i].__ref__())
            if self.wTurbine.errDetails.length() > 0:
                self.errDetails = self.wTurbine.errDetails
                return
            eff[i] = self.wTurbine.calculateEff(power[i], power[0])
        eff[0] = 100.0

    def velDeltaPQ(self: Self, radiiCrosswind: Float64, axialDistInRadii: Float64, thrustCoeff: Float64, newTurbulenceIntensity: *Float64) -> Float64:
        if radiiCrosswind > 20.0 or newTurbulenceIntensity[] <= 0.0 or axialDistInRadii <= 0.0 or thrustCoeff <= 0.0:
            return 0.0
        var fAddedTurbulence: Float64 = (thrustCoeff / 7.0) * (1.0 - (2.0 / 5.0) * log(2.0 * axialDistInRadii))
        newTurbulenceIntensity[] = sqrt(pow(fAddedTurbulence, 2.0) + pow(newTurbulenceIntensity[], 2.0))
        var AA: Float64 = pow(newTurbulenceIntensity[], 2.0) * pow(axialDistInRadii, 2.0)
        var fExp: Float64 = max_of(-99.0, (-pow(radiiCrosswind, 2.0) / (2.0 * AA)))
        var dVelocityDeficit: Float64 = (thrustCoeff / (4.0 * AA)) * exp(fExp)
        return max_of(min_of(dVelocityDeficit, 1.0), 0.0)

struct parkWakeModel(WakeModelBase):
    var nTurbines: Int = 0
    var wTurbine: windTurbine
    var errDetails: String = ""
    var rotorDiameter: Float64 = 0.0
    var wakeDecayCoefficient: Float64 = 0.07
    var minThrustCoeff: Float64 = 0.02

    def __init__(self):
        self.nTurbines = 0
    def __init__(self, numberOfTurbinesInFarm: Int, wt: windTurbine):
        self.nTurbines = numberOfTurbinesInFarm
        self.wTurbine = wt
    def __del__(self): pass

    def getModelName(self: Self) -> String:
        return "Park"

    def setRotorDiameter(self: Self, d: Float64):
        self.rotorDiameter = d

    def wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
        power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
        var turbineRadius: Float64 = self.wTurbine.rotorDiameter / 2.0
        for i in range(1, self.nTurbines):
            var newSpeed: Float64 = windSpeed[0]
            for j in range(i):
                var distanceDownwindMeters: Float64 = turbineRadius * fabs(distanceDownwind[i] - distanceDownwind[j])
                var distanceCrosswindMeters: Float64 = turbineRadius * fabs(distanceCrosswind[i] - distanceCrosswind[j])
                newSpeed = min_of(newSpeed, self.delta_V_Park(windSpeed[0], windSpeed[j], distanceCrosswindMeters, distanceDownwindMeters, turbineRadius, turbineRadius, thrust[j]))
            windSpeed[i] = newSpeed
            self.wTurbine.turbinePower(windSpeed[i], airDensity, power[i].__ref__(), None, thrust[i].__ref__())
            if self.wTurbine.errDetails.length() > 0:
                self.errDetails = self.wTurbine.errDetails
                return
            eff[i] = self.wTurbine.calculateEff(power[i], power[0])
        eff[0] = 100.0

    def circle_overlap(self: Self, dist_center_to_center: Float64, rad1: Float64, rad2: Float64) -> Float64:
        if dist_center_to_center < 0.0 or rad1 < 0.0 or rad2 < 0.0:
            return 0.0
        if dist_center_to_center >= rad1 + rad2:
            return 0.0
        if rad1 >= dist_center_to_center + rad2:
            return PI * pow(rad2, 2)
        if rad2 >= dist_center_to_center + rad1:
            return PI * pow(rad1, 2)
        var t1: Float64 = pow(rad1, 2) * acos((pow(dist_center_to_center, 2) + pow(rad1, 2) - pow(rad2, 2)) / (2.0 * dist_center_to_center * rad1))
        var t2: Float64 = pow(rad2, 2) * acos((pow(dist_center_to_center, 2) + pow(rad2, 2) - pow(rad1, 2)) / (2.0 * dist_center_to_center * rad2))
        var t3: Float64 = 0.5 * sqrt((-dist_center_to_center + rad1 + rad2) * (dist_center_to_center + rad1 - rad2) * (dist_center_to_center - rad1 + rad2) * (dist_center_to_center + rad1 + rad2))
        return t1 + t2 - t3

    def delta_V_Park(self: Self, Uo: Float64, Ui: Float64, distCrosswind: Float64, distDownwind: Float64, dRadiusUpstream: Float64, dRadiusDownstream: Float64, dThrustCoeff: Float64) -> Float64:
        var Ct: Float64 = max_of(min_of(0.999, dThrustCoeff), self.minThrustCoeff)
        var k: Float64 = self.wakeDecayCoefficient
        var dRadiusOfWake: Float64 = dRadiusUpstream + (k * distDownwind)
        var dAreaOverlap: Float64 = self.circle_overlap(distCrosswind, dRadiusDownstream, dRadiusOfWake)
        if dAreaOverlap <= 0.0:
            return Uo
        var dDef: Float64 = (1.0 - sqrt(1.0 - Ct)) * pow(dRadiusUpstream / dRadiusOfWake, 2) * (dAreaOverlap / (PI * dRadiusDownstream * dRadiusDownstream))
        return Ui * (1.0 - dDef)

struct eddyViscosityWakeModel(WakeModelBase):
    var nTurbines: Int = 0
    var wTurbine: windTurbine
    var errDetails: String = ""
    var rotorDiameter: Float64 = 0.0
    var turbulenceCoeff: Float64 = 0.10
    var axialResolution: Float64 = 0.5
    var minThrustCoeff: Float64 = 0.02
    var nBlades: Float64 = 3.0
    var minDeficit: Float64 = 0.0002
    var MIN_DIAM_EV: Int = 2
    var EV_SCALE: Int = 1
    var MAX_WIND_TURBINES: Int = 300
    var useFilterFx: Bool = True
    var matEVWakeDeficits: matrix_t[Float64]
    var matEVWakeWidths: matrix_t[Float64]

    def __init__(self):
        self.nTurbines = 0
    def __init__(self, numberOfTurbinesInFarm: Int, wt: windTurbine, turbCoeff: Float64):
        self.wTurbine = wt
        self.rotorDiameter = wt.rotorDiameter
        if turbCoeff >= 0.0 and turbCoeff <= 1.0:
            self.turbulenceCoeff = turbCoeff
        else:
            self.turbulenceCoeff = 0.10
        self.nTurbines = numberOfTurbinesInFarm
        self.axialResolution = 0.5
        self.minThrustCoeff = 0.02
        self.nBlades = 3.0
        self.minDeficit = 0.0002
        self.MIN_DIAM_EV = 2
        self.EV_SCALE = 1
        self.MAX_WIND_TURBINES = 300
        self.axialResolution = 0.5
        var maxRotorDiameters: Float64 = 50.0
        self.useFilterFx = True
        self.matEVWakeDeficits = matrix_t[Float64]()
        self.matEVWakeDeficits.resize_fill(self.nTurbines, Int(maxRotorDiameters / self.axialResolution) + 1, 0.0)
        self.matEVWakeWidths = matrix_t[Float64]()
        self.matEVWakeWidths.resize_fill(self.nTurbines, Int(maxRotorDiameters / self.axialResolution) + 1, 0.0)
    def __del__(self): pass

    def getModelName(self: Self) -> String:
        return "FastEV"

    def wakeCalculations(self: Self, air_density: Float64, aDistanceDownwind: List[Float64], aDistanceCrosswind: List[Float64],
        power: List[Float64], eff: List[Float64], Thrust: List[Float64], adWindSpeed: List[Float64], aTurbulence_intensity: List[Float64]):
        var dTurbineRadius: Float64 = self.rotorDiameter / 2.0
        self.matEVWakeDeficits.fill(0.0)
        self.matEVWakeWidths.fill(0.0)
        var vmln: List[VMLN] = List[VMLN]()
        for _ in range(self.nTurbines):
            vmln.append(VMLN())
        var Iamb: List[Float64] = List[Float64]()
        for _ in range(self.nTurbines):
            Iamb.append(self.turbulenceCoeff)
        for i in range(self.nTurbines):
            var dDeficit: Float64 = 0.0
            var Iadd: Float64 = 0.0
            var dTotalTI: Float64 = aTurbulence_intensity[i]
            for j in range(i):
                var dDistAxialInDiameters: Float64 = fabs(aDistanceDownwind[i] - aDistanceDownwind[j]) / 2.0
                if fabs(dDistAxialInDiameters) <= 0.0001:
                    continue
                var dDistRadialInDiameters: Float64 = fabs(aDistanceCrosswind[i] - aDistanceCrosswind[j]) / 2.0
                var dWakeRadiusMeters: Float64 = self.getWakeWidth(Int(j), dDistAxialInDiameters)
                if dWakeRadiusMeters <= 0.0:
                    continue
                var dDef: Float64 = self.wakeDeficit(Int(j), dDistRadialInDiameters, dDistAxialInDiameters)
                var dWindSpeedWaked: Float64 = adWindSpeed[0] * (1.0 - dDef)
                dDeficit = max_of(dDeficit, dDef)
                Iadd = self.addedTurbulenceIntensity(Thrust[j], dDistAxialInDiameters * self.rotorDiameter)
                var dFractionOfOverlap: Float64 = self.simpleIntersect(dDistRadialInDiameters * self.rotorDiameter, dTurbineRadius, dWakeRadiusMeters)
                dTotalTI = max_of(dTotalTI, self.totalTurbulenceIntensity(aTurbulence_intensity[i], Iadd, adWindSpeed[0], dWindSpeedWaked, dFractionOfOverlap))
            adWindSpeed[i] = adWindSpeed[0] * (1.0 - dDeficit)
            aTurbulence_intensity[i] = dTotalTI
            self.wTurbine.turbinePower(adWindSpeed[i], air_density, power[i].__ref__(), None, Thrust[i].__ref__())
            if self.wTurbine.errDetails.length() > 0:
                self.errDetails = self.wTurbine.errDetails
                return
            eff[i] = self.wTurbine.calculateEff(power[i], power[0])
            if not self.fillWakeArrays(Int(i), adWindSpeed[0], adWindSpeed[i], power[i], Thrust[i], aTurbulence_intensity[i], fabs(aDistanceDownwind[self.nTurbines - 1] - aDistanceDownwind[i]) * dTurbineRadius):
                if self.errDetails.length() == 0:
                    self.errDetails = "Could not calculate the turbine wake arrays in the Eddy-Viscosity model."
            self.nearWakeRegionLength(adWindSpeed[i], Iamb[i], Thrust[i], air_density, vmln[i])

    def getVelocityDeficit(self: Self, upwindTurbine: Int, axialDistanceInDiameters: Float64) -> Float64:
        var dDistPastMin: Float64 = axialDistanceInDiameters - Float64(self.MIN_DIAM_EV)
        if dDistPastMin < 0.0:
            return self.rotorDiameter * self.matEVWakeDeficits.at(upwindTurbine, 0)
        var dDistInResolutionUnits: Float64 = dDistPastMin / self.axialResolution
        var iLowerIndex: Int = Int(dDistInResolutionUnits)
        var iUpperIndex: Int = iLowerIndex + 1
        if iUpperIndex >= self.matEVWakeDeficits.ncols():
            return 0.0
        dDistInResolutionUnits -= Float64(iLowerIndex)
        return (self.matEVWakeDeficits.at(upwindTurbine, iLowerIndex) * (1.0 - dDistInResolutionUnits)) + (self.matEVWakeDeficits.at(upwindTurbine, iUpperIndex) * dDistInResolutionUnits)

    def getWakeWidth(self: Self, upwindTurbine: Int, axialDistanceInDiameters: Float64) -> Float64:
        var dDistPastMin: Float64 = axialDistanceInDiameters - Float64(self.MIN_DIAM_EV)
        if dDistPastMin < 0.0:
            return self.rotorDiameter * self.matEVWakeWidths.at(upwindTurbine, 0)
        var dDistInResolutionUnits: Float64 = dDistPastMin / self.axialResolution
        var iLowerIndex: Int = Int(dDistInResolutionUnits)
        var iUpperIndex: Int = iLowerIndex + 1
        dDistInResolutionUnits -= Float64(iLowerIndex)
        if iUpperIndex >= self.matEVWakeWidths.ncols():
            return 0.0
        return self.rotorDiameter * max_of(1.0, (self.matEVWakeWidths.at(upwindTurbine, iLowerIndex) * (1.0 - dDistInResolutionUnits) + self.matEVWakeWidths.at(upwindTurbine, iUpperIndex) * dDistInResolutionUnits))

    def wakeDeficit(self: Self, upwindTurbine: Int, distCrosswind: Float64, distDownwind: Float64) -> Float64:
        var dDef: Float64 = self.getVelocityDeficit(upwindTurbine, distDownwind)
        if dDef <= 0.0:
            return 0.0
        var dSteps: Float64 = 25.0
        var dCrossWindDistanceInMeters: Float64 = distCrosswind * self.rotorDiameter
        var dWidth: Float64 = self.getWakeWidth(upwindTurbine, distDownwind)
        var dRadius: Float64 = self.rotorDiameter / 2.0
        var dStep: Float64 = self.rotorDiameter / dSteps
        var dTotal: Float64 = 0.0
        var y: Float64 = dCrossWindDistanceInMeters - dRadius
        while y <= dCrossWindDistanceInMeters + dRadius:
            dTotal += dDef * exp(-3.56 * (((y * y)) / (dWidth * dWidth)))
            y += dStep
        dTotal /= (dSteps + 1.0)
        return dTotal

    def addedTurbulenceIntensity(self: Self, Ct: Float64, deltaX: Float64) -> Float64:
        if deltaX == 0.0:
            return 0.0
        return max_of(0.0, (Ct / 7.0) * (1.0 - (2.0 / 5.0) * log(deltaX / self.rotorDiameter)))

    def nearWakeRegionLength(self: Self, U: Float64, Ii: Float64, Ct: Float64, airDensity: Float64, vmln: VMLN):
        Ct = max_of(min_of(0.999, Ct), self.minThrustCoeff)
        var dr_dx: Float64
        var m: Float64 = 1.0 / sqrt(1.0 - Ct)
        var r0: Float64 = 0.5 * self.rotorDiameter * sqrt((m + 1.0) / 2.0)
        var t1: Float64 = sqrt(0.214 + 0.144 * m)
        var t2: Float64 = sqrt(0.134 + 0.124 * m)
        var n: Float64 = (t1 * (1.0 - t2)) / ((1.0 - t1) * t2)
        var dr_dx_A: Float64 = Ii < 2.0 ? 0.05 * Ii : 0.025 * Ii + 0.05
        var dr_dx_M: Float64 = ((1.0 - m) * sqrt(1.49 + m)) / ((1.0 + m) * 9.76)
        var dr_dx_L: Float64 = 0.012 * self.nBlades * self.wTurbine.tipSpeedRatio(U)
        dr_dx = sqrt(dr_dx_A * dr_dx_A + dr_dx_M * dr_dx_M + dr_dx_L * dr_dx_L)
        vmln.m = m
        vmln.diam = self.rotorDiameter
        vmln.Xh = r0 / dr_dx
        vmln.Xn = n * vmln.Xh
        return

    def simpleIntersect(self: Self, distToCenter: Float64, radiusTurbine: Float64, radiusWake: Float64) -> Float64:
        if distToCenter < 0.0 or radiusTurbine < 0.0 or radiusWake < 0.0:
            return 0.0
        if distToCenter > radiusTurbine + radiusWake:
            return 0.0
        if radiusWake >= distToCenter + radiusTurbine:
            return 1.0
        return min_of(1.0, max_of(0.0, (radiusTurbine + radiusWake - distToCenter) / (2.0 * radiusTurbine)))

    def totalTurbulenceIntensity(self: Self, ambientTI: Float64, additionalTI: Float64, Uo: Float64, Uw: Float64, partial: Float64) -> Float64:
        if Uw <= 0.0:
            return ambientTI
        var f: Float64 = max_of(0.0, ambientTI * ambientTI + additionalTI * additionalTI)
        f = sqrt(f) * Uo / Uw
        return (1.0 - partial) * ambientTI + partial * f

    def fillWakeArrays(self: Self, turbineIndex: Int, ambientVelocity: Float64, velocityAtTurbine: Float64, power: Float64, thrustCoeff: Float64, turbulenceIntensity: Float64, metersToFurthestDownwindTurbine: Float64) -> Bool:
        if power <= 0.0:
            return True
        if thrustCoeff <= 0.0:
            return True
        thrustCoeff = max_of(min_of(0.999, thrustCoeff), self.minThrustCoeff)
        turbulenceIntensity = min_of(turbulenceIntensity, 50.0)
        var Dm: Float64
        var Dmi: Float64
        const K: Float64 = 0.4
        const K1: Float64 = 0.015
        var F: Float64
        var x: Float64 = Float64(self.MIN_DIAM_EV)
        if x >= 5.5 or not self.useFilterFx:
            F = 1.0
        else:
            F = 0.65 - pow(-(x - 4.5) / 23.32, 1.0 / 3.0) if x < 4.5 else 0.65 + pow((x - 4.5) / 23.32, 1.0 / 3.0)
        var Km: Float64 = F * K * K * turbulenceIntensity / 100.0
        Dm = max_of(0.0, thrustCoeff - 0.05 - ((16.0 * thrustCoeff - 0.5) * turbulenceIntensity / 1000.0))
        Dmi = Dm
        if Dmi <= 0.0:
            return True
        var Uc: Float64 = velocityAtTurbine - Dmi * velocityAtTurbine
        Dm = (ambientVelocity - Uc) / ambientVelocity
        Dmi = Dm
        var Bw: Float64 = sqrt(3.56 * thrustCoeff / (8.0 * Dmi * (1.0 - 0.5 * Dmi)))
        var E: Float64 = F * K1 * Bw * Dm * Float64(self.EV_SCALE) + Km
        var m_d2U: List[Float64] = List[Float64]()
        for idx in range(self.matEVWakeDeficits.ncols()):
            m_d2U.append(0.0)
        m_d2U[0] = Float64(self.EV_SCALE) * (1.0 - Dmi)
        self.matEVWakeDeficits.at(turbineIndex, 0) = Dmi
        self.matEVWakeWidths.at(turbineIndex, 0) = Bw
        for j in range(self.matEVWakeDeficits.ncols() - 1):
            x = Float64(self.MIN_DIAM_EV) + Float64(j) * self.axialResolution
            if x >= 5.5 or not self.useFilterFx:
                F = 1.0
            else:
                F = 0.65 - pow(-(x - 4.5) / 23.32, 1.0 / 3.0) if x < 4.5 else 0.65 + pow((x - 4.5) / 23.32, 1.0 / 3.0)
            Km = F * K * K * turbulenceIntensity / 100.0
            E = F * K1 * Bw * (Dm * Float64(self.EV_SCALE)) + Km
            var dUdX: Float64 = 16.0 * (pow(m_d2U[j], 3.0) - pow(m_d2U[j], 2.0) - m_d2U[j] + 1.0) * E / (m_d2U[j] * thrustCoeff)
            m_d2U[j + 1] = m_d2U[j] + dUdX * self.axialResolution
            Dm = (Float64(self.EV_SCALE) - m_d2U[j + 1]) / Float64(self.EV_SCALE)
            Bw = sqrt(3.56 * thrustCoeff / (8.0 * Dm * (1.0 - 0.5 * Dm)))
            self.matEVWakeDeficits.at(turbineIndex, j + 1) = Dm
            self.matEVWakeWidths.at(turbineIndex, j + 1) = Bw
            if Dm <= self.minDeficit or x > metersToFurthestDownwindTurbine + self.axialResolution or j >= self.matEVWakeDeficits.ncols() - 2:
                break
        return True

struct constantWakeModel(WakeModelBase):
    var nTurbines: Int = 0
    var wTurbine: windTurbine
    var errDetails: String = ""
    var derate: Float64 = 0.0

    def __init__(self, nTurbs: Int, wt: windTurbine, derate_multiplier: Float64):
        self.nTurbines = nTurbs
        self.wTurbine = wt
        self.derate = derate_multiplier
    def __del__(self): pass

    def getModelName(self: Self) -> String:
        return "Constant"

    def wakeCalculations(self: Self, airDensity: Float64, distanceDownwind: List[Float64], distanceCrosswind: List[Float64],
        power: List[Float64], eff: List[Float64], thrust: List[Float64], windSpeed: List[Float64], turbulenceIntensity: List[Float64]):
        var turbPower: Float64 = 0.0
        var turbThrust: Float64 = 0.0
        self.wTurbine.turbinePower(windSpeed[0], airDensity, turbPower.__ref__(), None, turbThrust.__ref__())
        if self.wTurbine.errDetails.length() > 0:
            self.errDetails = self.wTurbine.errDetails
            return
        turbPower *= self.derate
        for i in range(self.nTurbines):
            power[i] = turbPower
            thrust[i] = turbThrust
            eff[i] = 100.0