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

from lib_physics import *
from lib_weatherfile import *
from lib_powerblock import *
from util import hours_in_month, to_string as util_to_string
from math import *
from memory import Pointer

# --- Enums ---

alias calculationBasis = Int32
let NO_CALCULATION_BASIS: calculationBasis = 0
let POWER_SALES: calculationBasis = 1
let NUMBER_OF_WELLS: calculationBasis = 2

alias conversionTypes = Int32
let NO_CONVERSION_TYPE: conversionTypes = 0
let BINARY: conversionTypes = 1
let FLASH: conversionTypes = 2

alias resourceTypes = Int32
let NO_RESOURCE_TYPE: resourceTypes = 0
let HYDROTHERMAL: resourceTypes = 1
let EGS: resourceTypes = 2

alias flashTypes = Int32
let NO_FLASH_SUBTYPE: flashTypes = 0
let SINGLE_FLASH_NO_TEMP_CONSTRAINT: flashTypes = 1
let SINGLE_FLASH_WITH_TEMP_CONSTRAINT: flashTypes = 2
let DUAL_FLASH_NO_TEMP_CONSTRAINT: flashTypes = 3
let DUAL_FLASH_WITH_TEMP_CONSTRAINT: flashTypes = 4

alias tempDeclineMethod = Int32
let NO_TEMPERATURE_DECLINE_METHOD: tempDeclineMethod = 0
let ENTER_RATE: tempDeclineMethod = 1
let CALCULATE_RATE: tempDeclineMethod = 2

alias makeupAlgorithmType = Int32
let NO_MAKEUP_ALGORITHM: makeupAlgorithmType = 0
let MA_BINARY: makeupAlgorithmType = 1
let MA_FLASH: makeupAlgorithmType = 2
let MA_EGS: makeupAlgorithmType = 3

alias condenserTypes = Int32
let NO_CONDENSER_TYPE: condenserTypes = 0
let SURFACE: condenserTypes = 1
let DIRECT_CONTACT: condenserTypes = 2

alias ncgRemovalTypes = Int32
let NO_NCG_TYPE: ncgRemovalTypes = 0
let JET: ncgRemovalTypes = 1
let VAC_PUMP: ncgRemovalTypes = 2
let HYBRID: ncgRemovalTypes = 3

alias wellCostCurveChoices = Int32
let NO_COST_CURVE: wellCostCurveChoices = 0
let LOW: wellCostCurveChoices = 1
let MED: wellCostCurveChoices = 2
let HIGH: wellCostCurveChoices = 3

alias depthCalculationForEGS = Int32
let NOT_CHOSEN: depthCalculationForEGS = 0
let DEPTH: depthCalculationForEGS = 1
let TEMPERATURE: depthCalculationForEGS = 2

alias reservoirPressureChangeCalculation = Int32
let NO_PC_CHOICE: reservoirPressureChangeCalculation = 0
let ENTER_PC: reservoirPressureChangeCalculation = 1
let SIMPLE_FRACTURE: reservoirPressureChangeCalculation = 2
let K_AREA: reservoirPressureChangeCalculation = 3

# --- Struct SGeothermal_Inputs ---

@value
struct SGeothermal_Inputs:
    var me_cb: calculationBasis
    var me_ct: conversionTypes
    var me_ft: flashTypes
    var me_tdm: tempDeclineMethod
    var me_rt: resourceTypes
    var me_dc: depthCalculationForEGS
    var me_pc: reservoirPressureChangeCalculation
    var mi_ModelChoice: Int32
    var mb_CalculatePumpWork: Bool
    var mi_ProjectLifeYears: size_t
    var mi_MakeupCalculationsPerYear: size_t
    var mi_TotalMakeupCalculations: size_t
    var md_DesiredSalesCapacityKW: Float64
    var md_NumberOfWells: Float64
    var md_PlantEfficiency: Float64
    var md_TemperatureDeclineRate: Float64
    var md_MaxTempDeclineC: Float64
    var md_TemperatureWetBulbC: Float64
    var md_PressureAmbientPSI: Float64
    var md_ProductionFlowRateKgPerS: Float64
    var md_GFPumpEfficiency: Float64
    var md_PressureChangeAcrossSurfaceEquipmentPSI: Float64
    var md_ExcessPressureBar: Float64
    var md_DiameterProductionWellInches: Float64
    var md_DiameterPumpCasingInches: Float64
    var md_DiameterInjectionWellInches: Float64
    var md_UserSpecifiedPumpWorkKW: Float64
    var md_PotentialResourceMW: Float64
    var md_ResourceDepthM: Float64
    var md_TemperatureResourceC: Float64
    var md_TemperaturePlantDesignC: Float64
    var md_EGSThermalConductivity: Float64
    var md_EGSSpecificHeatConstant: Float64
    var md_EGSRockDensity: Float64
    var md_ReservoirDeltaPressure: Float64
    var md_ReservoirWidthM: Float64
    var md_ReservoirHeightM: Float64
    var md_ReservoirPermeability: Float64
    var md_DistanceBetweenProductionInjectionWellsM: Float64
    var md_WaterLossPercent: Float64
    var md_EGSFractureAperature: Float64
    var md_EGSNumberOfFractures: Float64
    var md_EGSFractureWidthM: Float64
    var md_EGSFractureAngle: Float64
    var md_TemperatureEGSAmbientC: Float64
    var md_RatioInjectionToProduction: Float64
    var md_AdditionalPressure: Float64
    var mc_WeatherFileName: String
    var mia_tou: Pointer[Int32]                # time of use array

    def __init__(inout self):
        self.me_cb = NO_CALCULATION_BASIS
        self.me_ct = NO_CONVERSION_TYPE
        self.me_ft = NO_FLASH_SUBTYPE
        self.me_tdm = NO_TEMPERATURE_DECLINE_METHOD
        self.me_rt = NO_RESOURCE_TYPE
        self.me_dc = NOT_CHOSEN
        self.me_pc = NO_PC_CHOICE
        self.mi_ModelChoice = -1
        self.mb_CalculatePumpWork = True
        self.mi_ProjectLifeYears = 0
        self.mi_MakeupCalculationsPerYear = 0
        self.mi_TotalMakeupCalculations = 0
        self.md_DesiredSalesCapacityKW = 0.0
        self.md_NumberOfWells = 0.0
        self.md_PlantEfficiency = 0.0
        self.md_TemperatureDeclineRate = 0.0
        self.md_MaxTempDeclineC = 0.0
        self.md_TemperatureWetBulbC = 0.0
        self.md_PressureAmbientPSI = 0.0
        self.md_ProductionFlowRateKgPerS = 0.0
        self.md_GFPumpEfficiency = 0.0
        self.md_PressureChangeAcrossSurfaceEquipmentPSI = 0.0
        self.md_ExcessPressureBar = 0.0
        self.md_DiameterProductionWellInches = 0.0
        self.md_DiameterPumpCasingInches = 0.0
        self.md_DiameterInjectionWellInches = 0.0
        self.md_UserSpecifiedPumpWorkKW = 0.0
        self.md_PotentialResourceMW = 0.0
        self.md_ResourceDepthM = 0.0
        self.md_TemperatureResourceC = 0.0
        self.md_TemperaturePlantDesignC = 0.0
        self.md_EGSThermalConductivity = 0.0
        self.md_EGSSpecificHeatConstant = 0.0
        self.md_EGSRockDensity = 0.0
        self.md_ReservoirDeltaPressure = 0.0
        self.md_ReservoirWidthM = 0.0
        self.md_ReservoirHeightM = 0.0
        self.md_ReservoirPermeability = 0.0
        self.md_DistanceBetweenProductionInjectionWellsM = 0.0
        self.md_WaterLossPercent = 0.0
        self.md_EGSFractureAperature = 0.0
        self.md_EGSNumberOfFractures = 0.0
        self.md_EGSFractureWidthM = 0.0
        self.md_EGSFractureAngle = 0.0
        self.md_TemperatureEGSAmbientC = 0.0
        self.md_RatioInjectionToProduction = 0.0
        self.md_AdditionalPressure = 1.0
        self.mc_WeatherFileName = String("")
        self.mia_tou = Pointer[Int32]()         # null pointer

# --- Struct SGeothermal_Outputs ---

@value
struct SGeothermal_Outputs:
    var md_NumberOfWells: Float64
    var md_PumpWorkKW: Float64
    var eff_secondlaw: Float64               #Overall Plant 2nd Law Efficiency 
    var qRejectedTotal: Float64              #Used in calculating Cooling Tower Cost - Flash Plant Type
    var condenser_q: Float64                 #Condenser heat rejected - used in calculating Surface type condenser cost in cmod_geothermal_costs
    var v_stage_1: Float64                   #Vacuum Stage 1 Pump Power
    var v_stage_2: Float64
    var v_stage_3: Float64
    var GF_flowrate: Float64                 #GF Flow Rate Total
    var qRejectByStage_1: Float64            #Used in NCG Condenser Cost Calculation 
    var qRejectByStage_2: Float64
    var qRejectByStage_3: Float64
    var ncg_condensate_pump: Float64         #For calculating ncg pump cost
    var cw_pump_work: Float64               #For calculating ncg pump cost
    var pressure_ratio_1: Float64            #Suction steam ratio used in calculation of NCG Ejector Cost
    var pressure_ratio_2: Float64
    var pressure_ratio_3: Float64
    var condensate_pump_power: Float64       #kW
    var cwflow: Float64                     # lb/h
    var cw_pump_head: Float64               #ft
    var flash_temperature: Float64           #Storing Value of HP Flash Temperature for Calculating Flash Vessel in cmod_geothermal_costs
    var flash_temperature_lp: Float64        #Storing Value of LP Flash Temperature for Calculating Flash Vessel in cmod_geothermal_costs
    var spec_vol: Float64
    var spec_vol_lp: Float64                #HP Specific Volume & LP Specific Volume used in Flash Vessel Cost Calculation
    var getX_hp: Float64
    var getX_lp: Float64
    var flash_count: Float64
    var max_secondlaw: Float64              #Max 2nd Law efficiency
    var mb_BrineEffectivenessCalculated: Bool
    var md_FlashBrineEffectiveness: Float64
    var mb_FlashPressuresCalculated: Bool
    var md_PressureHPFlashPSI: Float64
    var md_PressureLPFlashPSI: Float64
    var md_PlantBrineEffectiveness: Float64
    var md_GrossPlantOutputMW: Float64
    var md_PumpDepthFt: Float64
    var md_PumpHorsePower: Float64
    var md_PressureChangeAcrossReservoir: Float64
    var md_AverageReservoirTemperatureF: Float64
    var md_BottomHolePressure: Float64
    var maf_ReplacementsByYear: Pointer[Float64]          # array of ones and zero's over time, years
    var maf_monthly_resource_temp: Pointer[Float64]
    var maf_monthly_power: Pointer[Float64]               # monthly values, even if timestep is hourly
    var maf_monthly_energy: Pointer[Float64]
    var maf_timestep_resource_temp: Pointer[Float64]
    var maf_timestep_power: Pointer[Float64]              # could be hourly or monthly
    var maf_timestep_test_values: Pointer[Float64]
    var maf_timestep_pressure: Pointer[Float64]
    var maf_timestep_dry_bulb: Pointer[Float64]
    var maf_timestep_wet_bulb: Pointer[Float64]
    var maf_hourly_power: Pointer[Float64]                # hourly values even if timestep is monthly

    def __init__(inout self):
        self.md_NumberOfWells = 0.0
        self.md_PumpWorkKW = 0.0
        self.eff_secondlaw = 0.0
        self.qRejectedTotal = 0.0
        self.condenser_q = 0.0
        self.v_stage_1 = 0.0
        self.v_stage_2 = 0.0
        self.v_stage_3 = 0.0
        self.GF_flowrate = 0.0
        self.qRejectByStage_1 = 0.0
        self.qRejectByStage_2 = 0.0
        self.qRejectByStage_3 = 0.0
        self.ncg_condensate_pump = 0.0
        self.cw_pump_work = 0.0
        self.pressure_ratio_1 = 0.0
        self.pressure_ratio_2 = 0.0
        self.pressure_ratio_3 = 0.0
        self.condensate_pump_power = 0.0
        self.cwflow = 0.0
        self.cw_pump_head = 0.0
        self.flash_temperature = 0.0
        self.flash_temperature_lp = 0.0
        self.spec_vol = 0.0
        self.spec_vol_lp = 0.0
        self.getX_hp = 0.0
        self.getX_lp = 0.0
        self.flash_count = 0.0
        self.max_secondlaw = 0.0
        self.mb_BrineEffectivenessCalculated = False
        self.md_FlashBrineEffectiveness = 0.0
        self.mb_FlashPressuresCalculated = False
        self.md_PressureHPFlashPSI = 0.0
        self.md_PressureLPFlashPSI = 0.0
        self.md_PlantBrineEffectiveness = 0.0
        self.md_GrossPlantOutputMW = 0.0
        self.md_PumpDepthFt = 0.0
        self.md_PumpHorsePower = 0.0
        self.md_PressureChangeAcrossReservoir = 0.0
        self.md_AverageReservoirTemperatureF = 0.0
        self.md_BottomHolePressure = 0.0
        self.maf_ReplacementsByYear = Pointer[Float64]()
        self.maf_monthly_resource_temp = Pointer[Float64]()
        self.maf_monthly_power = Pointer[Float64]()
        self.maf_monthly_energy = Pointer[Float64]()
        self.maf_timestep_resource_temp = Pointer[Float64]()
        self.maf_timestep_power = Pointer[Float64]()
        self.maf_timestep_test_values = Pointer[Float64]()
        self.maf_timestep_pressure = Pointer[Float64]()
        self.maf_timestep_dry_bulb = Pointer[Float64]()
        self.maf_timestep_wet_bulb = Pointer[Float64]()
        self.maf_hourly_power = Pointer[Float64]()

# --- Namespace geothermal ---

let MAX_TEMP_RATIO: Float64 = 1.134324   # max valid value for (resource temp)/(plant design temp) both in Kelvin
let DEFAULT_AMBIENT_TEMPC_BINARY: Float64 = 10.0          # degrees C
let ADDITIONAL_PRESSURE_REQUIRED: Bool = True
let EGS_THERMAL_CONDUCTIVITY: Float64 = 3 * 3600 * 24                # J/m-day-C
let TEMPERATURE_EGS_INJECTIONC: Float64 = 76.1                    # degrees C
let TEMPERATURE_EGS_AMBIENT_C: Float64 = 15.0                    # Note in GETEM spreadsheet says that this is only used in calculating resource temp or depth. ...
let CONST_CT: Float64 = 0.0009                                 # these are both inputs that are shaded out in GETEM
let CONST_CP: Float64 = 0.000000000464                          # "		"			"			"			"
let WATER_LOSS_PERCENT: Float64 = 0.02                          # 2%
let EGS_TIME_INPUT: Float64 = 3.076                            # years
let FRACTURE_LENGTH_ADJUSTMENT: Float64 = 2                    # used for one instance
let DELTA_PRESSURE_HP_FLASH_PSI: Float64 = 1.0                 #Was 2.2 -> now changed to 1.0
let DELTA_PRESSURE_LP_FLASH_PSI: Float64 = 1.0
let DELTA_TEMPERATURE_CWF: Float64 = 25.0                      # (degrees F) Was 30.0 -> now changed to 25.0
let TEMPERATURE_PINCH_PT_CONDENSER_F: Float64 = 7.5            #Was 10.0 -> now changed to 7.5
let TEMPERATURE_PINCH_PT_COOLING_TOWER_F: Float64 = 5          #Was 15 -> now changed to 5.0
let PRESSURE_CONDENSER_NCG_PARTIAL_INHG: Float64 = 0.32        # (inches of Mercury) was 0.5 -> now changed to 0.32
let GEOTHERMAL_FLUID_FOR_FLASH: Float64 = 1000                 # D67 in "5C.Flash-Steam Plant Perf"
let EFFICIENCY_TURBINE: Float64 = 0.80                         #Was 0.825 -> now changed to 0.80
let EFFICIENCY_GENERATOR: Float64 = 0.98
let EFFICIENCY_PUMP_FLASH: Float64 = 0.7
let NCG_REMOVAL_TYPE: ncgRemovalTypes = HYBRID                #Always type JET??
let NUMBER_OF_COOLING_STAGES: Int32 = 3                         # 1,2, or 3
let NCG_LEVEL_PPM: Float64 = 2000                            #Was 100 -> now changed to 2000
let MOLE_WEIGHT_NCG: Float64 = 44.0
let MOLE_WEIGHT_H2O: Float64 = 18.0
let BASE_CW_PUMP_HEAD_FT: Float64 = 65.0                      #Was 60.0 -> now changed to 65.0
let CONDENSER_TYPE: condenserTypes = SURFACE
let INJECTION_PUMPING_CYCLES: Float64 = 5.0                    #Was 6.0 -> now changed to 5.0 - cell #D133
let ADDITIONAL_CW_PUMP_HEAD_SURFACE: Float64 = 10 * 144 / WATER_DENSITY
let FINAL_YEARS_WITH_NO_REPLACEMENT: Float64 = 5
let IMITATE_GETEM: Bool = False
let GETEM_FT_IN_METER: Float64 = (IMITATE_GETEM ? 3.28083 : FT_PER_METER)    # feet per meter
let GETEM_PSI_PER_BAR: Float64 = (IMITATE_GETEM ? 14.50377 : PSI_PER_BAR)    # psi per bar
let GETEM_PSI_PER_INHG: Float64 = (IMITATE_GETEM ? 0.49115 : PSI_PER_INHG)    # psi per inch of mercury
let GETEM_KGM3_PER_LBF3: Float64 = (IMITATE_GETEM ? (35.3146 / 2.20462) : KGM3_PER_LBF3)    # lbs/ft^3 per kg/m^3 
let GETEM_LB_PER_KG: Float64 = (IMITATE_GETEM ? 2.20462 : LB_PER_KG)    # pounds per kilogram
let GETEM_KW_PER_HP: Float64 = (IMITATE_GETEM ? 0.7457 : KW_PER_HP)    # kilowatts per unit horsepower
let GRAVITY_MS2: Float64 = (IMITATE_GETEM ? 9.807 : GRAVITY_MS2)    # meters per second^2; varies
let DAYS_PER_YEAR: Float64 = 365.25

def MetersToFeet(m: Float64) -> Float64:
    return m * GETEM_FT_IN_METER

def FeetToMeters(ft: Float64) -> Float64:
    return ft / GETEM_FT_IN_METER

def M2ToFeet2(mSquared: Float64) -> Float64:
    return (IMITATE_GETEM ? mSquared * 10.76391 : mSquared * pow(GETEM_FT_IN_METER, 2))

def InHgToPsi(inHg: Float64) -> Float64:
    return inHg * GETEM_PSI_PER_INHG

def PsiToInHg(psi: Float64) -> Float64:
    return psi / GETEM_PSI_PER_INHG

def BarToPsi(bar: Float64) -> Float64:
    return bar * GETEM_PSI_PER_BAR

def KgPerM3ToLbPerCf(kgPerM3: Float64) -> Float64:
    return kgPerM3 / GETEM_KGM3_PER_LBF3

def LbPerCfToKgPerM3(lbPerCf: Float64) -> Float64:
    return lbPerCf * GETEM_KGM3_PER_LBF3

def LbPerCfToKgPerM3_B(lbPerCf: Float64) -> Float64:
    return (IMITATE_GETEM ? lbPerCf * 16.01846 : lbPerCf * GETEM_KGM3_PER_LBF3)

def KgToLb(kg: Float64) -> Float64:
    return kg * GETEM_LB_PER_KG

def LbToKg(lb: Float64) -> Float64:
    return lb / GETEM_LB_PER_KG

def HPtoKW(hp: Float64) -> Float64:
    return hp * GETEM_KW_PER_HP

def KWtoHP(kw: Float64) -> Float64:
    return kw / GETEM_KW_PER_HP

def PSItoFTB(psi: Float64) -> Float64:
    return (IMITATE_GETEM ? psi * 144 / 62 : PSItoFT(psi))   # convert PSI to pump 'head' in feet. assumes water density ~62 lb/ft^3 if imitating GETEM

def pumpSizeInHP(flow_LbPerHr: Float64, head_Ft: Float64, eff: Float64, inout sErr: String) -> Float64:
    if eff <= 0:
        sErr = "Pump efficiency <= 0 in 'pumpSizeInHP'."
        return 0
    return (flow_LbPerHr * head_Ft) / (60 * 33000 * eff)

def pumpWorkInWattHr(flow_LbPerHr: Float64, head_Ft: Float64, eff: Float64, inout sErr: String) -> Float64:
    return HPtoKW(1000 * pumpSizeInHP(flow_LbPerHr, head_Ft, eff, sErr))

def calcEGSTemperatureConstant(tempC: Float64, maxSecondLawEff: Float64) -> Float64:
    # not explained. a constant used to calculate the 'average water temp' for EGS resource
    var c1: Float64 = (-0.0006 * tempC) - 0.0681
    var c2: Float64 = (-0.0004 * tempC) + 1.0166
    var c3: Float64 = (maxSecondLawEff * c1) + c2
    var c4: Float64 = (-0.0002 * tempC) + 0.9117
    var c5: Float64 = (-0.001 * tempC) + 0.55
    return (tempC < 150 ? c3 : (maxSecondLawEff < c5 ? c3 : c4))

def calcEGSAverageWaterTemperatureC(temp1C: Float64, temp2C: Float64, maxEff: Float64) -> Float64:
    return KelvinToCelcius(CelciusToKelvin(temp1C) * calcEGSTemperatureConstant(temp2C, maxEff))

def gauss_error_function(x: Float64) -> Float64:
    var i: Int32
    var u: Float64
    var a0: Float64
    var a1: Float64
    var a2: Float64
    var b0: Float64
    var B1: Float64
    var b2: Float64
    var g: Float64
    var t: Float64
    var p: Float64
    var s: Float64
    var f1: Float64
    var f2: Float64 = 0
    var d: Float64
    var y: Float64
    var yc: Float64
    let maxloop: Int32 = 2000
    let tiny: Float64 = 10e-15
    u = abs(x)   #10.11.06 fix bug for x<<0. Thanks to Michael Hautus
    if u <= 2:
        t = 2 * u * u
        p = 1
        s = 1
        i = 3
        while i <= maxloop:
            p = p * t / Float64(i)
            s = s + p
            if p < tiny:
                break
            i = i + 2
        y = 2 * s * u * exp(-u * u) / sqrt(PI)
        if x < 0:
            y = -y
        yc = 1 - y
    else:
        a0 = 1
        b0 = 0
        a1 = 0
        B1 = 1
        f1 = 0
        i = 1
        while i <= maxloop:
            g = 2 - fmod(Float64(i), 2.0)
            a2 = g * u * a1 + Float64(i) * a0
            b2 = g * u * B1 + Float64(i) * b0
            f2 = a2 / b2
            d = abs(f2 - f1)
            if d < tiny:
                break
            a0 = a1 / b2
            b0 = B1 / b2
            a1 = a2 / b2
            B1 = 1
            f1 = f2
            i = i + 1
        yc = 2 * exp(-u * u) / (2 * u + f2) / sqrt(PI)
        y = 1 - yc
        if x < 0:
            y = -y
            yc = 2 - yc
    return yc    # y = err function, yc = complimentary error function

def evaluatePolynomial(x: Float64, c0: Float64, c1: Float64, c2: Float64, c3: Float64, c4: Float64, c5: Float64, c6: Float64) -> Float64:
    return (c0 + (c1 * x) + (c2 * pow(x, 2)) + (c3 * pow(x, 3)) + (c4 * pow(x, 4)) + (c5 * pow(x, 5)) + (c6 * pow(x, 6)))

def FrictionFactor(Re: Float64) -> Float64:
    return pow((0.79 * log(Re) - 1.640), -2)

# --- CPolynomial class ---

@value
struct CPolynomial:
    var md1: Float64
    var md2: Float64
    var md3: Float64
    var md4: Float64
    var md5: Float64
    var md6: Float64
    var md7: Float64

    def __init__():
        return CPolynomial {md1: 0.0, md2: 0.0, md3: 0.0, md4: 0.0, md5: 0.0, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64):
        return CPolynomial {md1: c1, md2: 0.0, md3: 0.0, md4: 0.0, md5: 0.0, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64, c2: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: 0.0, md4: 0.0, md5: 0.0, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64, c2: Float64, c3: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: c3, md4: 0.0, md5: 0.0, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64, c2: Float64, c3: Float64, c4: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: c3, md4: c4, md5: 0.0, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64, c2: Float64, c3: Float64, c4: Float64, c5: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: c3, md4: c4, md5: c5, md6: 0.0, md7: 0.0}

    def __init__(c1: Float64, c2: Float64, c3: Float64, c4: Float64, c5: Float64, c6: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: c3, md4: c4, md5: c5, md6: c6, md7: 0.0}

    def __init__(c1: Float64, c2: Float64, c3: Float64, c4: Float64, c5: Float64, c6: Float64, c7: Float64):
        return CPolynomial {md1: c1, md2: c2, md3: c3, md4: c4, md5: c5, md6: c6, md7: c7}

    def evaluate(self, val: Float64) -> Float64:
        return evaluatePolynomial(val, self.md1, self.md2, self.md3, self.md4, self.md5, self.md6, self.md7)

# --- CPolynomial instances ---

var oAmbientEnthalpyConstants = CPolynomial(-31.76958886, 0.997066497, 0.00001087)
var oAmbientEntropyConstants = CPolynomial(-0.067875028480951, 0.002201824618666, -0.000002665154152, 0.000000004390426, -0.000000000004355)
var oBinaryEnthalpyConstants = CPolynomial(-24.113934502, 0.83827719984, 0.0013462856545, -5.9760546933E-6, 1.4924845946E-8, -1.8805783302E-11, 1.0122595469E-14)
var oBinaryEntropyConstants = CPolynomial(-0.060089552413, 0.0020324314656, -1.2026247967E-6, -1.8419111147E-09, 8.8430105661E-12, -1.2945213491E-14, 7.3991541798E-18)
var oFlashEnthalpyConstants = CPolynomial(-32.232886, 1.0112508, -0.00013079803, 0.00000050269721, -0.00000000050170088, 1.5041709E-13, 7.0459062E-16)
var oFlashEntropyConstants = CPolynomial(-0.067756238, 0.0021979159, -0.0000026352004, 0.0000000045293969, -6.5394475E-12, 6.2185729E-15, -2.2525163E-18)
var oSVC = CPolynomial(0.017070951786, -0.000023968043944, 0.00000022418007508, -9.1528222658E-10, 2.1775771856E-12, -2.6995711458E-15, 1.4068205291E-18)
var oPC = CPolynomial(8.0894106754, -0.19788525656, 0.0019695373372, -0.0000091909636468, 0.000000024121846658, -2.5517506351E-12)
var oPressureAmbientConstants = CPolynomial(0.320593729630411, -0.0156410175570826, 0.0003545452343917, -0.0000027120923771, 0.0000000136666056)
var oDensityConstants = CPolynomial(62.329, 0.0072343, -0.00012456, 0.00000020215, -0.00000000017845)
var oFlashTempConstants = CPolynomial(113.186, -2.48032, 0.0209139, -0.0000557641, 0.0000000542893)
var oFlashConstants1 = CPolynomial(-1.306483, 0.2198881, -0.003125628, 0.0000173028, -0.00000003258986)
var oFlashConstants2 = CPolynomial(0.01897203, -0.0002054368, 0.000002824477, -0.00000001427949, 0.00000000002405238)
var oPSatConstants = CPolynomial(0.0588213, -0.0018299913, 0.00010459209, -0.00000084085735, 0.0000000086940123)
var oEGSDensity = CPolynomial(0.001003773308, -0.00000043857183, 0.00000001365689, -0.00000000006419, 0.00000000000013)
var oEGSSpecificHeat = CPolynomial(4.301651536642, -0.011554722573, 0.00020328187235, -0.0000011433197, 0.00000000217642)
var oMinimumTemperatureQuartz = CPolynomial(-159.597976, 0.69792956, 0.00035129)
var oMinimumTemperatureChalcedony = CPolynomial(-127.71, 0.8229)
var oDHaUnder150 = CPolynomial(60.251233, -0.28682223, 0.0049745244, -0.000050841601, 0.00000026431087, -0.00000000054076309)
var oDHa150To1500 = CPolynomial(53.67656, -0.02861559, 0.0000469389, -0.000000047788062, 0.000000000024733176, -5.0493347E-15)
var oDHaOver1500 = CPolynomial(123.86562, -0.18362579, 0.00016780015, -0.000000077555328, 0.000000000017815452, -1.6323827E-15)
var oDHbUnder150 = CPolynomial(-2.1991099, 1.4133748, -0.019163136, 0.0001766481, -0.00000087079731, 0.0000000017257066)
var oDHb150To1500 = CPolynomial(33.304544, 0.27192791, -0.00045591346, 0.000000443209, -0.00000000022501399, 4.5323448E-14)
var oDHbOver1500 = CPolynomial(740.43412, -1.5040745, 0.0014334909, -0.00000067364263, 0.00000000015600207, -1.4371477E-14)
var oFlashEnthalpyFUnder125 = CPolynomial(-32.479184, 1.0234315, -0.00034115062, 0.0000020320904, -0.000000004480902)
var oFlashEnthalpyF125To325 = CPolynomial(-31.760088, 0.9998551, -0.000027703224, 0.000000073480055, 0.00000000025563678)
var oFlashEnthalpyF325To675 = CPolynomial(-1137.0718729, 13.426933583, -0.055373746094, 0.00012227602697, -0.00000013378773724, 5.8634263518E-11)
var oFlashEnthalpyFOver675 = CPolynomial(-5658291651.7, 41194401.715, -119960.00955, 174.6587566, -0.12714518982, 0.000037021613128)
var oFlashEnthalpyGUnder125 = CPolynomial(1061.0996074, 0.44148580795, -0.000030268712038, -0.00000015844186585, -7.2150559138E-10)
var oFlashEnthalpyG125To325 = CPolynomial(1061.9537518, 0.42367961566, 0.000099006018886, -0.00000051596852593, -0.0000000005035389718)
var oFlashEnthalpyG325To675 = CPolynomial(-3413.791688, 60.38391862, -0.33157805684, 0.00096963380389, -0.0000015842735401, 0.0000000013698021251, -4.9118123157E-13)
var oFlashEnthalpyGOver675 = CPolynomial(7355226428.1, -53551582.984, 155953.29919, -227.07686319, 0.16531315908, -0.000048138033984)
var oFlashTemperatureUnder2 = CPolynomial(14.788238833, 255.85632577, -403.56297354, 400.57269432, -222.30982965, 63.304761377, -7.1864066799)
var oFlashTemperature2To20 = CPolynomial(78.871966537, 31.491049082, -4.8016701723, 0.49468791547, -0.029734376328, 0.00094358038872, -0.000012178121702)
var oFlashTemperature20To200 = CPolynomial(161.40853789, 4.3688747745, -0.062604066919, 0.00061292292067, -0.0000034988475881, 0.00000001053096688, -1.2878309875E-11)
var oFlashTemperature200To1000 = CPolynomial(256.29706201, 0.93056131917, -0.0020724712921, 0.0000034048164769, -0.0000000034275245432, 1.8867165569E-12, -4.3371351471E-16)
var oFlashTemperatureOver1000 = CPolynomial(342.90613285, 0.33345911089, -0.00020256473758, 0.000000094407417758, -2.7823504188E-11, 4.589696886E-15, -3.2288675486E-19)
var oSecondLawConstantsBinary = CPolynomial(130.8952, -426.5406, 462.9957, -166.3503) # ("6Ab. Makeup-Annl%").Range("R24:R27")
var oSecondLawConstantsSingleFlash = CPolynomial(-3637.06, 25.7411, -0.0684072, 0.0000808782, -0.0000000359423) # ("6Ef.Flash Makeup").Range("R20:V20")
var oSecondLawConstantsDualFlashNoTempConstraint = CPolynomial(-2762.4048, 18.637876, -0.047198813, 0.000053163057, -0.000000022497296) # ("6Ef.Flash Makeup").Range("R22:V22")
var oSecondLawConstantsDualFlashWithTempConstraint = CPolynomial(-4424.6599, 31.149268, -0.082103498, 0.000096016499, -0.00000004211223) # ("6Ef.Flash Makeup").Range("R21:V21")
var specVolUnder125 = CPolynomial(11678.605, -464.41472, 8.9931223, -0.1033793, 0.00071596466, -0.0000027557218, 0.0000000045215227)
var specVol125to325 = CPolynomial(3890.919, -83.834081, 0.78482148, -0.0040132715, 0.000011692082, -0.000000018270648, 0.000000000011909478)
var specVol325to675 = CPolynomial(268.32894, -2.7389634, 0.011958041, -0.000028277928, 0.000000037948334, -0.000000000027284644, 8.187709e-15)
var specVolOver675 = CPolynomial(1786.8983, 10.645163, -0.023769687, 0.000023582903, -0.0000000087731388)

def EGSWaterDensity(tempC: Float64) -> Float64:
    return 1 / oEGSDensity.evaluate(tempC)          # kg/m^3

def EGSSpecificHeat(tempC: Float64) -> Float64:
    return oEGSSpecificHeat.evaluate(tempC) * 1000  # J/kg-C

def GetDHa(pressurePSI: Float64) -> Float64:
    if pressurePSI > 1500:
        return oDHaOver1500.evaluate(pressurePSI)
    elif pressurePSI > 150:
        return oDHa150To1500.evaluate(pressurePSI)
    else:
        return oDHaUnder150.evaluate(pressurePSI)

def GetDHb(pressurePSI: Float64) -> Float64:
    if pressurePSI > 1500:
        return oDHbOver1500.evaluate(pressurePSI)
    elif pressurePSI > 150:
        return oDHb150To1500.evaluate(pressurePSI)
    else:
        return oDHbUnder150.evaluate(pressurePSI)

def GetFlashEnthalpyF(temperatureF: Float64) -> Float64:
    if temperatureF > 675:
        return oFlashEnthalpyFOver675.evaluate(temperatureF)
    elif temperatureF > 325:
        return oFlashEnthalpyF325To675.evaluate(temperatureF)
    elif temperatureF > 125:
        return oFlashEnthalpyF125To325.evaluate(temperatureF)
    else:
        return oFlashEnthalpyFUnder125.evaluate(temperatureF)

def GetFlashEnthalpyG(temperatureF: Float64) -> Float64:
    if temperatureF > 675:
        return oFlashEnthalpyGOver675.evaluate(temperatureF)
    elif temperatureF > 325:
        return oFlashEnthalpyG325To675.evaluate(temperatureF)
    elif temperatureF > 125:
        return oFlashEnthalpyG125To325.evaluate(temperatureF)
    else:
        return oFlashEnthalpyGUnder125.evaluate(temperatureF)

def GetFlashTemperature(pressurePSI: Float64) -> Float64:
    if pressurePSI > 1000:
        return oFlashTemperatureOver1000.evaluate(pressurePSI)
    elif pressurePSI > 200:
        return oFlashTemperature200To1000.evaluate(pressurePSI)
    elif pressurePSI > 20:
        return oFlashTemperature20To200.evaluate(pressurePSI)
    elif pressurePSI > 2:
        return oFlashTemperature2To20.evaluate(pressurePSI)
    else:
        return oFlashTemperatureUnder2.evaluate(pressurePSI)

def getSpecVol(flashTempF: Float64) -> Float64:
    if flashTempF > 675:
        return specVolOver675.evaluate(flashTempF)
    elif flashTempF > 325:
        return specVol325to675.evaluate(flashTempF)
    elif flashTempF > 125:
        return specVol125to325.evaluate(flashTempF)
    else:
        return specVolUnder125.evaluate(flashTempF)

def GetSiPrecipitationTemperatureF(geoFluidTempF: Float64) -> Float64:
    return (geoFluidTempF >= 356 ? oMinimumTemperatureQuartz.evaluate(geoFluidTempF) : oMinimumTemperatureChalcedony.evaluate(geoFluidTempF))

# --- CGeoFluidContainer2 class (nested style) ---

@value
struct CGeoFluidContainer2:
    def GetAEForBinaryWattHr(self, tempF: Float64, ambientTempF: Float64) -> Float64:
        return toWattHr(self.GetAEForBinaryBTU(tempF, ambientTempF))

    def GetAEForFlashWattHr(self, tempF: Float64, ambientTempF: Float64) -> Float64:
        return toWattHr(self.GetAEForFlashBTU(tempF, ambientTempF))

    def GetAEForBinaryWattHrUsingC(self, tempC: Float64, ambientTempC: Float64) -> Float64:
        return self.GetAEForBinaryWattHr(CelciusToFarenheit(tempC), CelciusToFarenheit(ambientTempC))

    def GetAEForFlashWattHrUsingC(self, tempC: Float64, ambientTempC: Float64) -> Float64:
        return self.GetAEForFlashWattHr(CelciusToFarenheit(tempC), CelciusToFarenheit(ambientTempC))

    def GetAEForBinaryBTU(self, tempHighF: Float64, tempLowF: Float64) -> Float64:
        return (oBinaryEnthalpyConstants.evaluate(tempHighF) - oAmbientEnthalpyConstants.evaluate(tempLowF)) - ((tempLowF + 460) * (oBinaryEntropyConstants.evaluate(tempHighF) - oAmbientEntropyConstants.evaluate(tempLowF)))

    def GetAEForFlashBTU(self, tempHighF: Float64, tempLowF: Float64) -> Float64:
        return (oFlashEnthalpyConstants.evaluate(tempHighF) - oAmbientEnthalpyConstants.evaluate(tempLowF)) - ((tempLowF + 460) * (oFlashEntropyConstants.evaluate(tempHighF) - oAmbientEntropyConstants.evaluate(tempLowF)))

var oGFC = CGeoFluidContainer2()


# --- Class CGeothermalAnalyzer ---

type update_fn[T: AnyType] = fn(f: Float32, data: T) -> Bool

@value
struct CGeothermalAnalyzer:
    var mp_geo_out: Pointer[SGeothermal_Outputs]
    var mo_geo_in: SGeothermal_Inputs
    var mo_pb_p: SPowerBlockParameters
    var mo_pb_in: SPowerBlockInputs
    var mo_PowerBlock: CPowerBlock_Type224
    var ms_ErrorString: String
    var mf_LastIntervalDone: Float32    # used to display "% done" to user
    var m_wFile: weatherfile
    var m_hdr: weather_header
    var m_wf: weather_record
    var mb_WeatherFileOpen: Bool
    var ml_ReadCount: Int32              # resource file reads through the year, 1 to 8760
    var ml_HourCount: Int32              # hour of analysis (zero to yearsX8760); used to tell Power Block how many seconds passed.
    var me_makeup: makeupAlgorithmType   # { NO_MAKEUP_ALGORITHM, MA_BINARY, MA_FLASH, MA_EGS }
    var mi_ReservoirReplacements: Int32  # how many times the reservoir has been 'replaced' (holes redrilled)
    var md_WorkingTemperatureC: Float64  # current working temp of the fluid coming out of the ground
    var md_LastProductionTemperatureC: Float64  # store the last temperature before calculating new one
    var md_TimeOfLastReservoirReplacement: Float64  # for EGS calcs

   # constructor with two arguments
    def __init__(inout self, gti: SGeothermal_Inputs, inout gto: SGeothermal_Outputs):
        self.mp_geo_out = Pointer[address_of(gto)]
        self.mo_geo_in = gti
        self.init()

   # constructor with four arguments
    def __init__(inout self, pbp: SPowerBlockParameters, inout pbi: SPowerBlockInputs, gti: SGeothermal_Inputs, inout gto: SGeothermal_Outputs):
        self.mp_geo_out = Pointer[address_of(gto)]
        self.mo_geo_in = gti
        self.mo_pb_p = pbp
        self.mo_pb_in = pbi
        self.init()

   # destructor (empty)
    def __del__(owned self):

   # init common code
    def init(inout self):
        self.ms_ErrorString = String("")
        self.mf_LastIntervalDone = 0.0
        self.mb_WeatherFileOpen = False
        self.ml_ReadCount = 0
        self.ml_HourCount = 0
        self.me_makeup = NO_MAKEUP_ALGORITHM
        self.mi_ReservoirReplacements = 0
        self.md_WorkingTemperatureC = 0.0
        self.md_LastProductionTemperatureC = 0.0
        self.md_TimeOfLastReservoirReplacement = 0.0

    def IsHourly(self) -> Bool:
        return (self.mo_geo_in.mi_MakeupCalculationsPerYear == 8760)

    def PlantGrossPowerkW(self) -> Float64:
        var dPlantBrineEfficiency: Float64 = 0.0   # plant Brine Efficiency as a function of temperature
        if self.me_makeup == MA_BINARY:
            dPlantBrineEfficiency = self.MaxSecondLawEfficiency() * self.mo_geo_in.md_PlantEfficiency * ((IMITATE_GETEM) ? self.GetAEBinary() : self.GetAE())   #MaxSecondLawEfficiency() * FractionOfMaxEfficiency() * GetAEBinaryAtTemp(md_WorkingTemperatureC);
        elif self.me_makeup == MA_FLASH:
            dPlantBrineEfficiency = self.MaxSecondLawEfficiency() * self.FractionOfMaxEfficiency() * self.GetAEFlashAtTemp(self.md_WorkingTemperatureC)
        elif self.me_makeup == MA_EGS:
            dPlantBrineEfficiency = self.MaxSecondLawEfficiency() * self.FractionOfMaxEfficiency() * self.GetAEBinaryAtTemp(self.md_WorkingTemperatureC)
        else:
            self.ms_ErrorString = "Invalid make up technology in CGeothermalAnalyzer::PlantGrossPowerkW"
            return 0
        return dPlantBrineEfficiency * self.flowRateTotal() / 1000.0

    def MaxSecondLawEfficiency(self) -> Float64:
        var dGetemAEForSecondLaw: Float64 = (IMITATE_GETEM) ? self.GetAEBinary() : self.GetAE() # GETEM uses correct ambient temp, always Binary constants
        # 2nd law efficiency used in direct plant cost calculations. This is NOT the same as the MAX 2nd law efficiency.
        self.mp_geo_out[].eff_secondlaw = self.GetPlantBrineEffectiveness() / dGetemAEForSecondLaw
        if self.me_makeup == MA_BINARY:
            return (self.mp_geo_out[].max_secondlaw)
        else:
            return (self.GetPlantBrineEffectiveness() / dGetemAEForSecondLaw)

    def FractionOfMaxEfficiency(self) -> Float64:
        var dTemperatureRatio: Float64 = 0.0
        if self.me_makeup == MA_EGS:
            dTemperatureRatio = CelciusToKelvin(self.md_LastProductionTemperatureC) / CelciusToKelvin(self.GetTemperaturePlantDesignC())
        else:
            dTemperatureRatio = CelciusToKelvin(self.md_WorkingTemperatureC) / CelciusToKelvin(self.GetTemperaturePlantDesignC())
        if self.me_makeup == MA_FLASH:
            if self.mo_geo_in.me_ft == SINGLE_FLASH_NO_TEMP_CONSTRAINT or self.mo_geo_in.me_ft == SINGLE_FLASH_WITH_TEMP_CONSTRAINT:
                return (1.1 - (0.1 * pow(dTemperatureRatio, oSecondLawConstantsSingleFlash.evaluate(CelciusToKelvin(self.GetResourceTemperatureC())))))
            elif self.mo_geo_in.me_ft == DUAL_FLASH_NO_TEMP_CONSTRAINT:
                return (1.1 - (0.1 * pow(dTemperatureRatio, oSecondLawConstantsDualFlashNoTempConstraint.evaluate(CelciusToKelvin(self.GetResourceTemperatureC())))))
            elif self.mo_geo_in.me_ft == DUAL_FLASH_WITH_TEMP_CONSTRAINT:
                return (1.1 - (0.1 * pow(dTemperatureRatio, oSecondLawConstantsDualFlashWithTempConstraint.evaluate(CelciusToKelvin(self.GetResourceTemperatureC())))))
            else:
                self.ms_ErrorString = "Invalid flash technology in CGeothermalAnalyzer::FractionOfMaxEfficiency"
                return 0
        else:
            # Binary and EGS
            return (oSecondLawConstantsBinary.evaluate(dTemperatureRatio) if dTemperatureRatio > 0.98 else 1.0177 * pow(dTemperatureRatio, 2.6237))

    def CanReplaceReservoir(self, dTimePassedInYears: Float64) -> Bool:
        return ((self.mi_ReservoirReplacements < self.NumberOfReservoirs()) and (dTimePassedInYears + FINAL_YEARS_WITH_NO_REPLACEMENT <= self.mo_geo_in.mi_ProjectLifeYears))

    def CalculateNewTemperature(inout self, dElapsedTimeInYears: Float64):
        if self.me_makeup != MA_EGS:
            self.md_WorkingTemperatureC = self.md_WorkingTemperatureC * (1 - (self.mo_geo_in.md_TemperatureDeclineRate / 12))
        else:
            self.md_LastProductionTemperatureC = self.md_WorkingTemperatureC
            var dAverageReservoirTempC: Float64 = calcEGSAverageWaterTemperatureC(self.md_LastProductionTemperatureC, self.md_LastProductionTemperatureC, self.MaxSecondLawEfficiency())
            var dDaysSinceLastReDrill: Float64 = (dElapsedTimeInYears - self.md_TimeOfLastReservoirReplacement) * DAYS_PER_YEAR
            var dFunctionOfRockProperties: Float64 = self.EGSReservoirConstant(dAverageReservoirTempC, dDaysSinceLastReDrill) #[6Bb.Makeup-EGS HX] column AG
            var tempBrineEfficiencyC: Float64 = KelvinToCelcius(exp((-0.42 * log(self.md_LastProductionTemperatureC) + 1.4745) * self.MaxSecondLawEfficiency() * self.FractionOfMaxEfficiency()) * CelciusToKelvin(self.md_LastProductionTemperatureC))
            var tempSILimitC: Float64 = FarenheitToCelcius(GetSiPrecipitationTemperatureF(CelciusToFarenheit(self.md_LastProductionTemperatureC)))
            var dNewInjectionTemperatureC: Float64 = max(tempBrineEfficiencyC, tempSILimitC)
            var dNewEGSProductionTemperatureC: Float64 = self.GetResourceTemperatureC() + ((dNewInjectionTemperatureC - self.GetResourceTemperatureC()) * dFunctionOfRockProperties)
            self.md_WorkingTemperatureC = dNewEGSProductionTemperatureC

    def GetPumpWorkKW(self) -> Float64:
        return (self.GetPumpWorkWattHrPerLb() * self.flowRateTotal() / 1000.0) if self.mo_geo_in.mb_CalculatePumpWork else self.mo_geo_in.md_UserSpecifiedPumpWorkKW

    def NumberOfReservoirs(self) -> Float64:
        var d1: Float64 = self.GetAEBinary()
        if (d1 == 0) and (IMITATE_GETEM):
            self.ms_ErrorString = "GetAEBinary returned zero in CGeothermalAnalyzer::NumberOfReservoirs. Could not calculate the number of reservoirs."
            return 0
        var dFactor: Float64 = (self.GetAE() / d1) if IMITATE_GETEM else 1
        var dPlantOutputKW: Float64 = dFactor * self.flowRateTotal() * self.GetPlantBrineEffectiveness() / 1000.0 # KW = (watt-hr/lb)*(lbs/hr) / 1000
        if dPlantOutputKW == 0:
            self.ms_ErrorString = "The Plant Output was zero in CGeothermalAnalyzer::NumberOfReservoirs. Could not calculate the number of reservoirs."
            return 0
        return floor(self.mo_geo_in.md_PotentialResourceMW * 1000 / dPlantOutputKW)

    def CalculatePumpWorkInKW(self, dFlowLbPerHr: Float64, dPumpHeadFt: Float64) -> Float64:
        return HPtoKW((dFlowLbPerHr * dPumpHeadFt) / (60 * 33000 * EFFICIENCY_PUMP_FLASH))

    def GetPumpWorkWattHrPerLb(self) -> Float64:
        # Enter 1 for flow to Get power per lb of flow
        var dProductionPumpPower: Float64 = pumpWorkInWattHr(1, self.pumpHeadFt(), self.mo_geo_in.md_GFPumpEfficiency, self.ms_ErrorString)
        if not self.ms_ErrorString.is_empty():
            return 0
        var dInjectionPumpPower: Float64 = 0
        if ADDITIONAL_PRESSURE_REQUIRED:
            var dWaterLoss: Float64 = (1 / (1 - WATER_LOSS_PERCENT)) # G130 - lb/hr
            var dFractionOfInletGFInjected: Float64 = 1.0
            if self.mo_geo_in.me_rt == EGS:
                dFractionOfInletGFInjected = (1 + WATER_LOSS_PERCENT)
            elif self.mo_geo_in.me_ct == FLASH:
                self.calculateFlashPressures()
                var dWaterLossFractionOfGF: Float64 = self.waterLoss() / GEOTHERMAL_FLUID_FOR_FLASH
                return (1 - dWaterLossFractionOfGF)
            var dInjectionPressure: Float64 = self.mo_geo_in.md_AdditionalPressure + BarToPsi(self.mo_geo_in.md_ExcessPressureBar) + self.GetPressureChangeAcrossReservoir()
            if self.mo_geo_in.md_AdditionalPressure < 0:

            var dInjectionPumpHeadFt: Float64 = dInjectionPressure * 144 / self.InjectionDensity() # G129
            dInjectionPumpPower = pumpWorkInWattHr(dWaterLoss, dInjectionPumpHeadFt, self.mo_geo_in.md_GFPumpEfficiency, self.ms_ErrorString) * dFractionOfInletGFInjected # ft-lbs/hr
        var retVal: Float64 = dProductionPumpPower + dInjectionPumpPower # watt-hr per lb of flow
        if retVal < 0:
            self.ms_ErrorString = "CGeothermalAnalyzer::GetPumpWorkWattHrPerLb calculated a value < 0"
            return 0
        return retVal

    def GetCalculatedPumpDepthInFeet(self) -> Float64:
        # Calculate the pumpSetDepth
        var dInectionPumpHeadUsed: Float64 = 0 # [2B.Resource&Well Input].D162
        if self.mo_geo_in.me_rt == EGS:
            self.mp_geo_out[].md_BottomHolePressure = (self.pressureInjectionWellBottomHolePSI() + dInectionPumpHeadUsed) - self.GetPressureChangeAcrossReservoir()
        else:
            self.mp_geo_out[].md_BottomHolePressure = self.pressureHydrostaticPSI() - self.GetPressureChangeAcrossReservoir()
        var pressureDiff: Float64 = self.mp_geo_out[].md_BottomHolePressure - self.pressureWellHeadPSI()
        var dDiameterProductionWellFt: Float64 = self.mo_geo_in.md_DiameterProductionWellInches / 12
        var areaWell: Float64 = areaCircle(dDiameterProductionWellFt / 2) # ft^2
        var velocityWell: Float64 = self.productionFlowRate() / areaWell # [7A.GF Pumps].G70
        var ReWell: Float64 = dDiameterProductionWellFt * velocityWell * self.productionDensity() / self.productionViscosity()
        var frictionHeadLossWell: Float64 = (FrictionFactor(ReWell) / dDiameterProductionWellFt) * pow(velocityWell, 2) / (2 * GRAVITY_FTS2)
        var pumpSetting: Float64 = ((pressureDiff * 144) / self.productionDensity()) * (1 - frictionHeadLossWell)   # [7A.GF Pumps].D89
        return 0 if (MetersToFeet(self.GetResourceDepthM()) - pumpSetting < 0) else (MetersToFeet(self.GetResourceDepthM()) - pumpSetting) # feet - [7A.GF Pumps].D90

    def pumpHeadFt(self) -> Float64:
        # calculate the friction head loss of the casing
        var dDiameterPumpCasingFt: Float64 = self.mo_geo_in.md_DiameterPumpCasingInches / 12
        var areaCasing: Float64 = areaCircle(dDiameterPumpCasingFt / 2) # ft^2
        var velocityCasing: Float64 = self.productionFlowRate() / areaCasing
        var dReCasing: Float64 = dDiameterPumpCasingFt * velocityCasing * self.productionDensity() / self.productionViscosity()
        var frictionHeadLossCasing: Float64 = (FrictionFactor(dReCasing) * self.GetCalculatedPumpDepthInFeet() / dDiameterPumpCasingFt) * pow(velocityCasing, 2) / (2 * GRAVITY_FTS2) #feet
        return frictionHeadLossCasing + self.GetCalculatedPumpDepthInFeet()

    def ReplaceReservoir(inout self, dElapsedTimeInYears: Float64):
        self.mi_ReservoirReplacements += 1
        self.md_WorkingTemperatureC = self.GetResourceTemperatureC()
        if self.me_makeup == MA_EGS:
            # have to keep track of the last temperature of the working fluid, and the last time the reservoir was "replaced" (re-drilled)
            self.md_LastProductionTemperatureC = self.md_WorkingTemperatureC
            var dYearsAtNextTimeStep: Float64 = dElapsedTimeInYears + (1.0 / 12.0)
            if dElapsedTimeInYears > 0:
                self.md_TimeOfLastReservoirReplacement = dYearsAtNextTimeStep - (self.EGSTimeStar(self.EGSAverageWaterTemperatureC2()) / DAYS_PER_YEAR)

    def GetTemperatureGradient(self) -> Float64:
        # degrees C per km
        if self.mo_geo_in.me_rt == HYDROTHERMAL:
            return ((self.mo_geo_in.md_TemperatureResourceC - self.GetAmbientTemperatureC(BINARY)) / self.mo_geo_in.md_ResourceDepthM) * 1000
        return ((self.mo_geo_in.md_TemperatureResourceC - self.mo_geo_in.md_TemperatureEGSAmbientC) / self.mo_geo_in.md_ResourceDepthM) * 1000

    def GetResourceTemperatureC(self) -> Float64:
        # degrees C
        if (self.mo_geo_in.me_rt == EGS) and (self.mo_geo_in.me_dc == DEPTH):
            return ((self.mo_geo_in.md_ResourceDepthM / 1000) * self.GetTemperatureGradient()) + self.mo_geo_in.md_TemperatureEGSAmbientC
        return self.mo_geo_in.md_TemperatureResourceC

    def GetTemperaturePlantDesignC(self) -> Float64:
        return self.mo_geo_in.md_TemperaturePlantDesignC if self.mo_geo_in.me_rt == EGS else self.GetResourceTemperatureC()

    def GetResourceDepthM(self) -> Float64:
        # meters
        if (self.mo_geo_in.me_rt == EGS) and (self.mo_geo_in.me_dc == TEMPERATURE):
            return 1000 * (self.mo_geo_in.md_TemperatureResourceC - self.mo_geo_in.md_TemperatureEGSAmbientC) / self.GetTemperatureGradient()
        return self.mo_geo_in.md_ResourceDepthM

    def GetAmbientTemperatureC(self, ct: conversionTypes = NO_CONVERSION_TYPE) -> Float64:
        var ct_: conversionTypes = ct
        if ct_ == NO_CONVERSION_TYPE:
            ct_ = self.mo_geo_in.me_ct
        return (DEFAULT_AMBIENT_TEMPC_BINARY if ct_ == BINARY else (1.3842 * self.mo_geo_in.md_TemperatureWetBulbC) + 5.1772)

    def InjectionTemperatureC(self) -> Float64:
        # calculate injection temperature in degrees C
        # Plant design temp AND resource temp have to be Set correctly!!!
        if (self.GetTemperaturePlantDesignC() != self.GetResourceTemperature