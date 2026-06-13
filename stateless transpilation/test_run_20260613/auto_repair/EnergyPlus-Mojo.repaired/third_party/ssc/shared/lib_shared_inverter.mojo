from lib_sandia import sandia_inverter_t
from lib_pvinv import partload_inverter_t
from lib_ondinv import ond_inverter
from lib_util import util
from 6par_newton import newton
from math import fabs, isfinite

def sortByVoltage(i: List[Float64], j: List[Float64]) -> Bool:
    return i[0] < j[0]

struct SharedInverter:
    alias SANDIA_INVERTER: Int = 0
    alias DATASHEET_INVERTER: Int = 1
    alias PARTLOAD_INVERTER: Int = 2
    alias COEFFICIENT_GENERATOR: Int = 3
    alias OND_INVERTER: Int = 4
    alias NONE: Int = 5
    alias NONE_INVERTER_EFF: Float64 = 0.96

    var StringV: Float64
    var Tdry_C: Float64
    var powerDC_kW: Float64
    var powerAC_kW: Float64
    var efficiencyAC: Float64
    var powerClipLoss_kW: Float64
    var powerConsumptionLoss_kW: Float64
    var powerNightLoss_kW: Float64
    var powerTempLoss_kW: Float64
    var powerLossTotal_kW: Float64
    var dcWiringLoss_ond_kW: Float64
    var acWiringLoss_ond_kW: Float64

    var m_inverterType: Int  # The inverter type
    var m_numInverters: Int  # The number of inverters in the system
    var m_nameplateAC_kW: Float64  # The total nameplate AC capacity for all inverters in kW
    var m_tempEnabled: Bool
    var m_thermalDerateCurves: List[List[Float64]]
    var m_sandiaInverter: sandia_inverter_t*
    var m_partloadInverter: partload_inverter_t*
    var m_ondInverter: ond_inverter*
    var solver_AC: Float64

    def __init__(inout self, inverterType: Int, numberOfInverters: Int,
                sandiaInverter: sandia_inverter_t*, partloadInverter: partload_inverter_t*, ondInverter: ond_inverter*):
        self.m_inverterType = inverterType
        self.m_numInverters = numberOfInverters
        self.m_sandiaInverter = sandiaInverter
        self.m_partloadInverter = partloadInverter
        self.m_ondInverter = ondInverter
        self.m_tempEnabled = False
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            self.m_nameplateAC_kW = self.m_numInverters * self.m_sandiaInverter.Paco * util.watt_to_kilowatt
        elif self.m_inverterType == PARTLOAD_INVERTER:
            self.m_nameplateAC_kW = self.m_numInverters * self.m_partloadInverter.Paco * util.watt_to_kilowatt
        elif self.m_inverterType == OND_INVERTER:
            self.m_nameplateAC_kW = self.m_numInverters * self.m_ondInverter.PMaxOUT * util.watt_to_kilowatt
        self.powerDC_kW = 0.0
        self.powerAC_kW = 0.0
        self.efficiencyAC = 96.0
        self.powerClipLoss_kW = 0.0
        self.powerConsumptionLoss_kW = 0.0
        self.powerNightLoss_kW = 0.0
        self.powerTempLoss_kW = 0.0
        self.powerLossTotal_kW = 0.0
        self.dcWiringLoss_ond_kW = 0.0
        self.acWiringLoss_ond_kW = 0.0

    def __init__(inout self, orig: Self):
        self.m_inverterType = orig.m_inverterType
        self.m_numInverters = orig.m_numInverters
        self.m_nameplateAC_kW = orig.m_nameplateAC_kW
        self.m_tempEnabled = orig.m_tempEnabled
        self.m_thermalDerateCurves = orig.m_thermalDerateCurves
        self.m_sandiaInverter = orig.m_sandiaInverter
        self.m_partloadInverter = orig.m_partloadInverter
        self.m_ondInverter = orig.m_ondInverter
        self.efficiencyAC = orig.efficiencyAC
        self.powerDC_kW = orig.powerDC_kW
        self.powerAC_kW = orig.powerAC_kW
        self.powerClipLoss_kW = orig.powerClipLoss_kW
        self.powerConsumptionLoss_kW = orig.powerConsumptionLoss_kW
        self.powerNightLoss_kW = orig.powerNightLoss_kW
        self.powerTempLoss_kW = orig.powerTempLoss_kW
        self.powerLossTotal_kW = orig.powerLossTotal_kW
        self.dcWiringLoss_ond_kW = orig.dcWiringLoss_ond_kW
        self.acWiringLoss_ond_kW = orig.acWiringLoss_ond_kW

    def setTempDerateCurves(inout self, derateCurves: List[List[Float64]]) -> Int:
        self.m_thermalDerateCurves.clear()
        for r in range(len(derateCurves)):
            if derateCurves[r][0] <= 0.0:
                return r + 1
            tempSlopeEntries = len(derateCurves[r]) - 1
            if tempSlopeEntries % 2 != 0:
                return r + 1
            for p in range(tempSlopeEntries // 2):
                if derateCurves[r][2 * p + 1] <= -273.0 or derateCurves[r][2 * p + 2] > 0.0:
                    return r + 1
            self.m_thermalDerateCurves.append(derateCurves[r])
        self.m_thermalDerateCurves.sort(sortByVoltage)
        if not self.m_thermalDerateCurves.is_empty():
            self.m_tempEnabled = True
        return 0

    def getTempDerateCurves(self) -> List[List[Float64]]:
        return self.m_thermalDerateCurves

    def findPointOnCurve(self, idx: Int, T: Float64, startT: Float64, slope: Float64):
        var p: Int = 0
        while 2 * p + 2 < len(self.m_thermalDerateCurves[idx]) and T >= self.m_thermalDerateCurves[idx][2 * p + 1]:
            p = p + 1
        if 2 * p + 2 >= len(self.m_thermalDerateCurves[idx]):
            p = p - 1
        startT = self.m_thermalDerateCurves[idx][2 * p + 1]
        slope = self.m_thermalDerateCurves[idx][2 * p + 2]

    def calculateTempDerate(self, V: Float64, tempC: Float64, p_dc_rated: Float64, ratio: Float64, loss: Float64):
        if ratio == 0.0 or p_dc_rated == 0.0:
            return
        var slope: Float64 = 0.0
        var startT: Float64 = 0.0
        var Vdc: Float64 = 0.0
        var slope2: Float64 = 0.0
        var startT2: Float64 = 0.0
        var Vdc2: Float64 = 0.0
        var p_dc_max: Float64 = self.getInverterDCMaxPower(p_dc_rated)
        var idx: Int = 0
        var deltaT: Float64 = 0.0
        var slopeInterpolated: Float64 = 0.0
        var startTInterpolated: Float64 = 0.0
        while idx < len(self.m_thermalDerateCurves) and V > self.m_thermalDerateCurves[idx][0]:
            idx = idx + 1
        if len(self.m_thermalDerateCurves) == 1:
            Vdc2 = self.m_thermalDerateCurves[0][0]
            startTInterpolated = self.m_thermalDerateCurves[0][1]
            slopeInterpolated = self.m_thermalDerateCurves[0][2]
        elif idx > 0 and idx < len(self.m_thermalDerateCurves):
            Vdc2 = self.m_thermalDerateCurves[idx][0]
            Vdc = self.m_thermalDerateCurves[idx - 1][0]
            var startTGuess: Float64 = 0.0
            var slopeGuess: Float64 = 0.0
            var n: Int = max(len(self.m_thermalDerateCurves[idx]) // 2, len(self.m_thermalDerateCurves[idx - 1]) // 2)
            var count: Int = 0
            while tempC > startTGuess and count < n:
                self.findPointOnCurve(idx, startT2, startT2, slope2)
                self.findPointOnCurve(idx - 1, startT, startT, slope)
                startTGuess = (startT2 - startT) / (Vdc2 - Vdc) * (V - Vdc2) + startT2
                slopeGuess = (slope2 - slope) / (Vdc2 - Vdc) * (V - Vdc2) + slope2
                if tempC > startTGuess:
                    startTInterpolated = startTGuess
                    slopeInterpolated = slopeGuess
                    count = count + 1
        else:
            if idx == 0:
                Vdc2 = self.m_thermalDerateCurves[idx][0]
                self.findPointOnCurve(idx, -273.0, startT2, slope2)
                Vdc = self.m_thermalDerateCurves[idx + 1][0]
                self.findPointOnCurve(idx + 1, -273.0, startT, slope)
                startTInterpolated = (startT2 - startT) / (Vdc2 - Vdc) * (V - Vdc2) + startT2
                slopeInterpolated = (slope2 - slope) / (Vdc2 - Vdc) * (V - Vdc2) + slope2
            else:
                Vdc2 = self.m_thermalDerateCurves[idx - 1][0]
                self.findPointOnCurve(idx - 1, -273.0, startT2, slope2)
                Vdc = self.m_thermalDerateCurves[idx - 2][0]
                self.findPointOnCurve(idx - 2, -273.0, startT, slope)
                startTInterpolated = (startT2 - startT) / (Vdc2 - Vdc) * (V - Vdc2) + startT2
                slopeInterpolated = (slope2 - slope) / (Vdc2 - Vdc) * (V - Vdc2) + slope2
        deltaT = tempC - startTInterpolated
        if deltaT <= 0:
            return
        if slopeInterpolated >= 0:
            return
        if slopeInterpolated < -1:
            slopeInterpolated = -1
        ratio = ratio + deltaT * slopeInterpolated
        if ratio < 0:
            ratio = 0.0
        var p_dc_limit: Float64 = p_dc_max * ratio
        if p_dc_rated > p_dc_limit:
            loss = p_dc_rated - p_dc_limit
            p_dc_rated = p_dc_limit
        else:
            loss = 0.0

    def getInverterDCMaxPower(self, p_dc_rated: Float64) -> Float64:
        var inv_dc_max_power: Float64
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            inv_dc_max_power = self.m_sandiaInverter.Pdco
        elif self.m_inverterType == PARTLOAD_INVERTER:
            inv_dc_max_power = self.m_partloadInverter.Pdco
        elif self.m_inverterType == OND_INVERTER:
            inv_dc_max_power = self.m_ondInverter.PMaxDC
        elif self.m_inverterType == NONE:
            inv_dc_max_power = p_dc_rated * util.kilowatt_to_watt
        return inv_dc_max_power

    def calculateACPower(inout self, powerDC_kW_in: Float64, DCStringVoltage: Float64, tempC: Float64):
        var P_par: Float64 = 0.0
        var P_lr: Float64 = 0.0
        var negativePower: Bool = powerDC_kW_in < 0.0
        self.dcWiringLoss_ond_kW = 0.0
        self.acWiringLoss_ond_kW = 0.0
        var powerDC_Watts: Float64 = powerDC_kW_in * util.kilowatt_to_watt
        var powerAC_Watts: Float64 = 0.0
        self.Tdry_C = tempC
        self.StringV = DCStringVoltage
        var tempLoss: Float64 = 0.0
        var power_ratio: Float64 = 1.0
        if self.m_tempEnabled:
            self.calculateTempDerate(DCStringVoltage, tempC, powerDC_Watts, power_ratio, tempLoss)
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            self.m_sandiaInverter.acpower(fabs(powerDC_Watts) / self.m_numInverters, DCStringVoltage, &powerAC_Watts, &P_par, &P_lr, &self.efficiencyAC, &self.powerClipLoss_kW, &self.powerConsumptionLoss_kW, &self.powerNightLoss_kW)
        elif self.m_inverterType == PARTLOAD_INVERTER:
            self.m_partloadInverter.acpower(fabs(powerDC_Watts) / self.m_numInverters, &powerAC_Watts, &P_lr, &P_par, &self.efficiencyAC, &self.powerClipLoss_kW, &self.powerNightLoss_kW)
        elif self.m_inverterType == OND_INVERTER:
            self.m_ondInverter.acpower(fabs(powerDC_Watts) / self.m_numInverters, DCStringVoltage, tempC, &powerAC_Watts, &P_par, &P_lr, &self.efficiencyAC, &self.powerClipLoss_kW, &self.powerConsumptionLoss_kW, &self.powerNightLoss_kW, &self.dcWiringLoss_ond_kW, &self.acWiringLoss_ond_kW)
        elif self.m_inverterType == NONE:
            self.powerClipLoss_kW = 0.0
            self.powerConsumptionLoss_kW = 0.0
            self.powerNightLoss_kW = 0.0
            self.efficiencyAC = NONE_INVERTER_EFF
            powerAC_Watts = powerDC_Watts * self.efficiencyAC
        self.powerDC_kW = powerDC_Watts * util.watt_to_kilowatt
        self.convertOutputsToKWandScale(tempLoss, powerAC_Watts)
        if negativePower:
            self.powerAC_kW = -1.0 * fabs(self.powerAC_kW)

    def calculateACPower(inout self, powerDC_kW_in: List[Float64], DCStringVoltage: List[Float64], tempC: Float64):
        var P_par: Float64 = 0.0
        var P_lr: Float64 = 0.0
        var powerDC_Watts_one_inv: List[Float64] = List[Float64]()
        var powerDC_Watts_one_inv_iter: List[Float64] = List[Float64]()
        for i in range(len(powerDC_kW_in)):
            powerDC_Watts_one_inv.append(powerDC_kW_in[i] * util.kilowatt_to_watt / self.m_numInverters)
        self.Tdry_C = tempC
        self.StringV = DCStringVoltage[0]
        var size: Int = len(DCStringVoltage)
        var tempLoss: List[Float64] = List[Float64]()
        for _ in range(size):
            tempLoss.append(0.0)
        var power_ratio: Float64 = 1.0
        if self.m_tempEnabled:
            var avgDCVoltage: Float64 = 0.0
            var avgDCPower_Watts: Float64 = 0.0
            for i in range(len(powerDC_Watts_one_inv)):
                power_ratio = 1.0
                self.calculateTempDerate(DCStringVoltage[i], tempC, powerDC_Watts_one_inv[i], power_ratio, tempLoss[i])
        var powerAC_Watts: Float64 = 0.0
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            self.m_sandiaInverter.acpower(powerDC_Watts_one_inv, DCStringVoltage, &powerAC_Watts, &P_par, &P_lr, &self.efficiencyAC, &self.powerClipLoss_kW, &self.powerConsumptionLoss_kW, &self.powerNightLoss_kW)
        elif self.m_inverterType == PARTLOAD_INVERTER:
            self.m_partloadInverter.acpower(powerDC_Watts_one_inv, &powerAC_Watts, &P_lr, &P_par, &self.efficiencyAC, &self.powerClipLoss_kW, &self.powerNightLoss_kW)
        self.powerDC_kW = 0.0
        var tempLoss_avg: Float64 = 0.0
        for i in range(len(powerDC_Watts_one_inv)):
            self.powerDC_kW = self.powerDC_kW + powerDC_Watts_one_inv[i] * util.watt_to_kilowatt * self.m_numInverters
            tempLoss_avg = tempLoss_avg + tempLoss[i]
        tempLoss_avg = tempLoss_avg / len(tempLoss)
        self.convertOutputsToKWandScale(tempLoss_avg, powerAC_Watts)

    def solve_kwdc_for_kwac(inout self, x: Float64*, f: Float64*):
        self.calculateACPower(x[0], self.StringV, self.Tdry_C)
        f[0] = self.powerAC_kW - self.solver_AC

    def calculateRequiredDCPower(inout self, kwAC: Float64, DCStringV: Float64, tempC: Float64) -> Float64:
        var clone: SharedInverter = SharedInverter(self)
        clone.StringV = DCStringV
        clone.Tdry_C = tempC
        clone.solver_AC = kwAC
        def f(x: Float64*, f_out: Float64*):
            clone.solve_kwdc_for_kwac(x, f_out)
        var x: Float64* = (1.0)  # allocate? need to handle pointer
        var resid: Float64* = (1.0)
        x[0] = kwAC * 1.04
        var check: Bool = False
        newton[Float64, fn(Float64*, Float64*) -> None, 1](x, resid, check, f, 100, 1e-6, 1e-6, 0.7)
        if not isfinite(x[0]):
            x[0] = kwAC
        return x[0]

    def getInverterDCNominalVoltage(self) -> Float64:
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            return self.m_sandiaInverter.Vdco
        elif self.m_inverterType == PARTLOAD_INVERTER:
            return self.m_partloadInverter.Vdco
        elif self.m_inverterType == OND_INVERTER:
            return self.m_ondInverter.VNomEff[1]
        else:
            return 0.0

    def convertOutputsToKWandScale(inout self, tempLoss: Float64, powerAC_watts: Float64):
        self.powerAC_kW = powerAC_watts * self.m_numInverters * util.watt_to_kilowatt
        self.powerClipLoss_kW = self.powerClipLoss_kW * self.m_numInverters * util.watt_to_kilowatt
        self.powerConsumptionLoss_kW = self.powerConsumptionLoss_kW * self.m_numInverters * util.watt_to_kilowatt
        self.powerNightLoss_kW = self.powerNightLoss_kW * self.m_numInverters * util.watt_to_kilowatt
        self.powerTempLoss_kW = tempLoss * self.m_numInverters * util.watt_to_kilowatt
        self.powerLossTotal_kW = self.powerDC_kW - self.powerAC_kW
        self.efficiencyAC = self.efficiencyAC * 100
        self.dcWiringLoss_ond_kW = self.dcWiringLoss_ond_kW * self.m_numInverters * util.watt_to_kilowatt
        self.acWiringLoss_ond_kW = self.acWiringLoss_ond_kW * self.m_numInverters * util.watt_to_kilowatt

    def getMaxPowerEfficiency(inout self) -> Float64:
        if self.m_inverterType == SANDIA_INVERTER or self.m_inverterType == DATASHEET_INVERTER or self.m_inverterType == COEFFICIENT_GENERATOR:
            self.calculateACPower(self.m_sandiaInverter.Paco * util.watt_to_kilowatt, self.m_sandiaInverter.Vdco, 0.0)
        elif self.m_inverterType == PARTLOAD_INVERTER:
            self.calculateACPower(self.m_partloadInverter.Paco * util.watt_to_kilowatt, self.m_partloadInverter.Vdco, 0.0)
        elif self.m_inverterType == OND_INVERTER:
            self.calculateACPower(self.m_ondInverter.PMaxOUT * util.watt_to_kilowatt, self.m_ondInverter.VAbsMax, 0.0)
        return self.efficiencyAC

    def getACNameplateCapacitykW(self) -> Float64:
        return self.m_nameplateAC_kW