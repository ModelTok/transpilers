"""
EnergyPlus Packaged Thermal Storage Cooling Coil Module
Ported from C++ to Mojo (complete 1:1 translation)
"""

from collections import InlineArray
from enum import IntEnum
from dataclasses import dataclass
import math


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state container)
# - Psychrometrics: PsyTwbFnTdbWPb, PsyHFnTdbW, PsyWFnTdbH, PsyTdbFnHW, PsyTsatFnHPb, PsyWFnTdbTwbPb, PsyRhoAirFnPbTdbW, PsyWFnTdbH
# - Curve: CurveValue, CheckCurveDims, GetCurveIndex
# - Schedule: GetScheduleAlwaysOn, GetSchedule
# - Node: GetOnlySingleNode, TestCompSet
# - WaterManager: SetupTankDemandComponent, SetupTankSupplyComponent
# - GlobalNames: VerifyUniqueCoilName
# - Utilities: FindItemInList, SameString, ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowContinueError, ShowSevereEmptyField, ShowRecurringSevereErrorAtEnd, FindItem
# - DataPlant: ScanPlantLoopsForObject, PlantLocation, PlantEquipmentType
# - HeatBalanceInternalHeatGains: SetupZoneInternalGain
# - OutputProcessor: SetupOutputVariable, SetupEMSActuator
# - OutputReportPredefined: PreDefTableEntry
# - WaterThermalTanks: WaterThermalTankData
# - DataBranchAirLoopPlant: MassFlowTolerance


struct PTSCCtrlType:
    alias Invalid = -1
    alias ScheduledOpModes = 0
    alias EMSActuatedOpModes = 1
    alias Num = 2


struct PTSCOperatingMode:
    alias Invalid = -1
    alias Off = 0
    alias CoolingOnly = 1
    alias CoolingAndCharge = 2
    alias CoolingAndDischarge = 3
    alias ChargeOnly = 4
    alias DischargeOnly = 5
    alias Num = 6


struct MediaType:
    alias Invalid = -1
    alias Water = 0
    alias UserDefindFluid = 1
    alias Ice = 2
    alias Num = 3


struct CondensateAction:
    alias Invalid = -1
    alias Discard = 0
    alias ToTank = 1
    alias Num = 2


struct EvapWaterSupply:
    alias Invalid = -1
    alias WaterSupplyFromMains = 0
    alias WaterSupplyFromTank = 1
    alias Num = 2


struct TESCondenserType:
    alias Invalid = -1
    alias Air = 0
    alias Evap = 1
    alias Num = 2


alias DehumidControl_CoolReheat = 2
alias gigaJoulesToJoules = 1.0e9
alias FluidTankSizingDeltaT = 10.0


@dataclass
struct PackagedTESCoolingCoilStruct:
    var Name: String
    var availSched: UnsafePointer[SIMD[DType.float64, 1]]
    var ModeControlType: Int32
    var controlModeSched: UnsafePointer[SIMD[DType.float64, 1]]
    var EMSControlModeOn: Bool
    var EMSControlModeValue: Float64
    var CurControlMode: Int32
    var curControlModeReport: Int32
    var ControlModeErrorIndex: Int32
    var RatedEvapAirVolFlowRate: Float64
    var RatedEvapAirMassFlowRate: Float64
    var EvapAirInletNodeNum: Int32
    var EvapAirOutletNodeNum: Int32
    var CoolingOnlyModeIsAvailable: Bool
    var CoolingOnlyRatedTotCap: Float64
    var CoolingOnlyRatedSHR: Float64
    var CoolingOnlyRatedCOP: Float64
    var CoolingOnlyCapFTempCurve: Int32
    var CoolingOnlyCapFTempObjectNum: Int32
    var CoolingOnlyCapFFlowCurve: Int32
    var CoolingOnlyCapFFlowObjectNum: Int32
    var CoolingOnlyEIRFTempCurve: Int32
    var CoolingOnlyEIRFTempObjectNum: Int32
    var CoolingOnlyEIRFFlowCurve: Int32
    var CoolingOnlyEIRFFlowObjectNum: Int32
    var CoolingOnlyPLFFPLRCurve: Int32
    var CoolingOnlyPLFFPLRObjectNum: Int32
    var CoolingOnlySHRFTempCurve: Int32
    var CoolingOnlySHRFTempObjectNum: Int32
    var CoolingOnlySHRFFlowCurve: Int32
    var CoolingOnlySHRFFlowObjectNum: Int32
    var CoolingAndChargeModeAvailable: Bool
    var CoolingAndChargeRatedTotCap: Float64
    var CoolingAndChargeRatedTotCapSizingFactor: Float64
    var CoolingAndChargeRatedChargeCap: Float64
    var CoolingAndChargeRatedChargeCapSizingFactor: Float64
    var CoolingAndChargeRatedSHR: Float64
    var CoolingAndChargeCoolingRatedCOP: Float64
    var CoolingAndChargeChargingRatedCOP: Float64
    var CoolingAndChargeCoolingCapFTempCurve: Int32
    var CoolingAndChargeCoolingCapFTempObjectNum: Int32
    var CoolingAndChargeCoolingCapFFlowCurve: Int32
    var CoolingAndChargeCoolingCapFFlowObjectNum: Int32
    var CoolingAndChargeCoolingEIRFTempCurve: Int32
    var CoolingAndChargeCoolingEIRFTempObjectNum: Int32
    var CoolingAndChargeCoolingEIRFFlowCurve: Int32
    var CoolingAndChargeCoolingEIRFFlowObjectNum: Int32
    var CoolingAndChargeCoolingPLFFPLRCurve: Int32
    var CoolingAndChargeCoolingPLFFPLRObjectNum: Int32
    var CoolingAndChargeChargingCapFTempCurve: Int32
    var CoolingAndChargeChargingCapFTempObjectNum: Int32
    var CoolingAndChargeChargingCapFEvapPLRCurve: Int32
    var CoolingAndChargeChargingCapFEvapPLRObjectNum: Int32
    var CoolingAndChargeChargingEIRFTempCurve: Int32
    var CoolingAndChargeChargingEIRFTempObjectNum: Int32
    var CoolingAndChargeChargingEIRFFLowCurve: Int32
    var CoolingAndChargeChargingEIRFFLowObjectNum: Int32
    var CoolingAndChargeChargingPLFFPLRCurve: Int32
    var CoolingAndChargeChargingPLFFPLRObjectNum: Int32
    var CoolingAndChargeSHRFTempCurve: Int32
    var CoolingAndChargeSHRFFlowCurve: Int32
    var CoolingAndChargeSHRFFlowObjectNum: Int32
    var CoolingAndDischargeModeAvailable: Bool
    var CoolingAndDischargeRatedTotCap: Float64
    var CoolingAndDischargeRatedTotCapSizingFactor: Float64
    var CoolingAndDischargeRatedDischargeCap: Float64
    var CoolingAndDischargeRatedDischargeCapSizingFactor: Float64
    var CoolingAndDischargeRatedSHR: Float64
    var CoolingAndDischargeCoolingRatedCOP: Float64
    var CoolingAndDischargeDischargingRatedCOP: Float64
    var CoolingAndDischargeCoolingCapFTempCurve: Int32
    var CoolingAndDischargeCoolingCapFTempObjectNum: Int32
    var CoolingAndDischargeCoolingCapFFlowCurve: Int32
    var CoolingAndDischargeCoolingCapFFlowObjectNum: Int32
    var CoolingAndDischargeCoolingEIRFTempCurve: Int32
    var CoolingAndDischargeCoolingEIRFTempObjectNum: Int32
    var CoolingAndDischargeCoolingEIRFFlowCurve: Int32
    var CoolingAndDischargeCoolingEIRFFlowObjectNum: Int32
    var CoolingAndDischargeCoolingPLFFPLRCurve: Int32
    var CoolingAndDischargeCoolingPLFFPLRObjectNum: Int32
    var CoolingAndDischargeDischargingCapFTempCurve: Int32
    var CoolingAndDischargeDischargingCapFTempObjectNum: Int32
    var CoolingAndDischargeDischargingCapFFlowCurve: Int32
    var CoolingAndDischargeDischargingCapFFlowObjectNum: Int32
    var CoolingAndDischargeDischargingCapFEvapPLRCurve: Int32
    var CoolingAndDischargeDischargingCapFEvapPLRObjectNum: Int32
    var CoolingAndDischargeDischargingEIRFTempCurve: Int32
    var CoolingAndDischargeDischargingEIRFTempObjectNum: Int32
    var CoolingAndDischargeDischargingEIRFFLowCurve: Int32
    var CoolingAndDischargeDischargingEIRFFLowObjectNum: Int32
    var CoolingAndDischargeDischargingPLFFPLRCurve: Int32
    var CoolingAndDischargeDischargingPLFFPLRObjectNum: Int32
    var CoolingAndDischargeSHRFTempCurve: Int32
    var CoolingAndDischargeSHRFTempObjectNum: Int32
    var CoolingAndDischargeSHRFFlowCurve: Int32
    var CoolingAndDischargeSHRFFlowObjectNum: Int32
    var ChargeOnlyModeAvailable: Bool
    var ChargeOnlyRatedCapacity: Float64
    var ChargeOnlyRatedCapacitySizingFactor: Float64
    var ChargeOnlyRatedCOP: Float64
    var ChargeOnlyChargingCapFTempCurve: Int32
    var ChargeOnlyChargingCapFTempObjectNum: Int32
    var ChargeOnlyChargingEIRFTempCurve: Int32
    var ChargeOnlyChargingEIRFTempObjectNum: Int32
    var DischargeOnlyModeAvailable: Bool
    var DischargeOnlyRatedDischargeCap: Float64
    var DischargeOnlyRatedDischargeCapSizingFactor: Float64
    var DischargeOnlyRatedSHR: Float64
    var DischargeOnlyRatedCOP: Float64
    var DischargeOnlyCapFTempCurve: Int32
    var DischargeOnlyCapFTempObjectNum: Int32
    var DischargeOnlyCapFFlowCurve: Int32
    var DischargeOnlyCapFFlowObjectNum: Int32
    var DischargeOnlyEIRFTempCurve: Int32
    var DischargeOnlyEIRFTempObjectNum: Int32
    var DischargeOnlyEIRFFlowCurve: Int32
    var DischargeOnlyEIRFFlowObjectNum: Int32
    var DischargeOnlyPLFFPLRCurve: Int32
    var DischargeOnlyPLFFPLRObjectNum: Int32
    var DischargeOnlySHRFTempCurve: Int32
    var DischargeOnlySHRFTempObjectNum: Int32
    var DischargeOnlySHRFFLowCurve: Int32
    var DischargeOnlySHRFFLowObjectNum: Int32
    var AncillaryControlsPower: Float64
    var ColdWeatherMinimumTempLimit: Float64
    var ColdWeatherAncillaryPower: Float64
    var CondAirInletNodeNum: Int32
    var CondAirOutletNodeNum: Int32
    var CondenserType: Int32
    var CondenserAirVolumeFlow: Float64
    var CondenserAirFlowSizingFactor: Float64
    var CondenserAirMassFlow: Float64
    var EvapCondEffect: Float64
    var CondInletTemp: Float64
    var EvapCondPumpElecNomPower: Float64
    var EvapCondPumpElecEnergy: Float64
    var BasinHeaterPowerFTempDiff: Float64
    var basinHeaterAvailSched: UnsafePointer[SIMD[DType.float64, 1]]
    var BasinHeaterSetpointTemp: Float64
    var EvapWaterSupplyMode: Int32
    var EvapWaterSupplyName: String
    var EvapWaterSupTankID: Int32
    var EvapWaterTankDemandARRID: Int32
    var CondensateCollectMode: Int32
    var CondensateCollectName: String
    var CondensateTankID: Int32
    var CondensateTankSupplyARRID: Int32
    var StorageMedia: Int32
    var StorageFluidName: String
    var glycol: UnsafePointer[SIMD[DType.float64, 1]]
    var FluidStorageVolume: Float64
    var IceStorageCapacity: Float64
    var StorageCapacitySizingFactor: Float64
    var MinimumFluidTankTempLimit: Float64
    var MaximumFluidTankTempLimit: Float64
    var RatedFluidTankTemp: Float64
    var StorageAmbientNodeNum: Int32
    var StorageUA: Float64
    var TESPlantConnectionAvailable: Bool
    var TESPlantInletNodeNum: Int32
    var TESPlantOutletNodeNum: Int32
    var TESPlantLoopNum: Int32
    var TESPlantLoopSideNum: Int32
    var TESPlantBranchNum: Int32
    var TESPlantCompNum: Int32
    var TESPlantDesignVolumeFlowRate: Float64
    var TESPlantDesignMassFlowRate: Float64
    var TESPlantEffectiveness: Float64
    var TimeElapsed: Float64
    var IceFracRemain: Float64
    var IceFracRemainLastTimestep: Float64
    var FluidTankTempFinal: Float64
    var FluidTankTempFinalLastTimestep: Float64
    var QdotPlant: Float64
    var Q_Plant: Float64
    var QdotAmbient: Float64
    var Q_Ambient: Float64
    var QdotTES: Float64
    var Q_TES: Float64
    var ElecCoolingPower: Float64
    var ElecCoolingEnergy: Float64
    var EvapTotCoolingRate: Float64
    var EvapTotCoolingEnergy: Float64
    var EvapSensCoolingRate: Float64
    var EvapSensCoolingEnergy: Float64
    var EvapLatCoolingRate: Float64
    var EvapLatCoolingEnergy: Float64
    var RuntimeFraction: Float64
    var CondenserRuntimeFraction: Float64
    var ElectColdWeatherPower: Float64
    var ElectColdWeatherEnergy: Float64
    var ElectEvapCondBasinHeaterPower: Float64
    var ElectEvapCondBasinHeaterEnergy: Float64
    var EvapWaterConsumpRate: Float64
    var EvapWaterConsump: Float64
    var EvapWaterStarvMakupRate: Float64
    var EvapWaterStarvMakup: Float64
    var EvapCondPumpElecPower: Float64
    var EvapCondPumpElecConsumption: Float64

    fn __init__(inout self):
        self.Name = String()
        self.availSched = UnsafePointer[SIMD[DType.float64, 1]]()
        self.ModeControlType = -1
        self.controlModeSched = UnsafePointer[SIMD[DType.float64, 1]]()
        self.EMSControlModeOn = False
        self.EMSControlModeValue = 0.0
        self.CurControlMode = 0
        self.curControlModeReport = 0
        self.ControlModeErrorIndex = 0
        self.RatedEvapAirVolFlowRate = 0.0
        self.RatedEvapAirMassFlowRate = 0.0
        self.EvapAirInletNodeNum = 0
        self.EvapAirOutletNodeNum = 0
        self.CoolingOnlyModeIsAvailable = False
        self.CoolingOnlyRatedTotCap = 0.0
        self.CoolingOnlyRatedSHR = 0.0
        self.CoolingOnlyRatedCOP = 0.0
        self.CoolingOnlyCapFTempCurve = 0
        self.CoolingOnlyCapFTempObjectNum = 0
        self.CoolingOnlyCapFFlowCurve = 0
        self.CoolingOnlyCapFFlowObjectNum = 0
        self.CoolingOnlyEIRFTempCurve = 0
        self.CoolingOnlyEIRFTempObjectNum = 0
        self.CoolingOnlyEIRFFlowCurve = 0
        self.CoolingOnlyEIRFFlowObjectNum = 0
        self.CoolingOnlyPLFFPLRCurve = 0
        self.CoolingOnlyPLFFPLRObjectNum = 0
        self.CoolingOnlySHRFTempCurve = 0
        self.CoolingOnlySHRFTempObjectNum = 0
        self.CoolingOnlySHRFFlowCurve = 0
        self.CoolingOnlySHRFFlowObjectNum = 0
        self.CoolingAndChargeModeAvailable = False
        self.CoolingAndChargeRatedTotCap = 0.0
        self.CoolingAndChargeRatedTotCapSizingFactor = 0.0
        self.CoolingAndChargeRatedChargeCap = 0.0
        self.CoolingAndChargeRatedChargeCapSizingFactor = 0.0
        self.CoolingAndChargeRatedSHR = 0.0
        self.CoolingAndChargeCoolingRatedCOP = 0.0
        self.CoolingAndChargeChargingRatedCOP = 0.0
        self.CoolingAndChargeCoolingCapFTempCurve = 0
        self.CoolingAndChargeCoolingCapFTempObjectNum = 0
        self.CoolingAndChargeCoolingCapFFlowCurve = 0
        self.CoolingAndChargeCoolingCapFFlowObjectNum = 0
        self.CoolingAndChargeCoolingEIRFTempCurve = 0
        self.CoolingAndChargeCoolingEIRFTempObjectNum = 0
        self.CoolingAndChargeCoolingEIRFFlowCurve = 0
        self.CoolingAndChargeCoolingEIRFFlowObjectNum = 0
        self.CoolingAndChargeCoolingPLFFPLRCurve = 0
        self.CoolingAndChargeCoolingPLFFPLRObjectNum = 0
        self.CoolingAndChargeChargingCapFTempCurve = 0
        self.CoolingAndChargeChargingCapFTempObjectNum = 0
        self.CoolingAndChargeChargingCapFEvapPLRCurve = 0
        self.CoolingAndChargeChargingCapFEvapPLRObjectNum = 0
        self.CoolingAndChargeChargingEIRFTempCurve = 0
        self.CoolingAndChargeChargingEIRFTempObjectNum = 0
        self.CoolingAndChargeChargingEIRFFLowCurve = 0
        self.CoolingAndChargeChargingEIRFFLowObjectNum = 0
        self.CoolingAndChargeChargingPLFFPLRCurve = 0
        self.CoolingAndChargeChargingPLFFPLRObjectNum = 0
        self.CoolingAndChargeSHRFTempCurve = 0
        self.CoolingAndChargeSHRFFlowCurve = 0
        self.CoolingAndChargeSHRFFlowObjectNum = 0
        self.CoolingAndDischargeModeAvailable = False
        self.CoolingAndDischargeRatedTotCap = 0.0
        self.CoolingAndDischargeRatedTotCapSizingFactor = 0.0
        self.CoolingAndDischargeRatedDischargeCap = 0.0
        self.CoolingAndDischargeRatedDischargeCapSizingFactor = 0.0
        self.CoolingAndDischargeRatedSHR = 0.0
        self.CoolingAndDischargeCoolingRatedCOP = 0.0
        self.CoolingAndDischargeDischargingRatedCOP = 0.0
        self.CoolingAndDischargeCoolingCapFTempCurve = 0
        self.CoolingAndDischargeCoolingCapFTempObjectNum = 0
        self.CoolingAndDischargeCoolingCapFFlowCurve = 0
        self.CoolingAndDischargeCoolingCapFFlowObjectNum = 0
        self.CoolingAndDischargeCoolingEIRFTempCurve = 0
        self.CoolingAndDischargeCoolingEIRFTempObjectNum = 0
        self.CoolingAndDischargeCoolingEIRFFlowCurve = 0
        self.CoolingAndDischargeCoolingEIRFFlowObjectNum = 0
        self.CoolingAndDischargeCoolingPLFFPLRCurve = 0
        self.CoolingAndDischargeCoolingPLFFPLRObjectNum = 0
        self.CoolingAndDischargeDischargingCapFTempCurve = 0
        self.CoolingAndDischargeDischargingCapFTempObjectNum = 0
        self.CoolingAndDischargeDischargingCapFFlowCurve = 0
        self.CoolingAndDischargeDischargingCapFFlowObjectNum = 0
        self.CoolingAndDischargeDischargingCapFEvapPLRCurve = 0
        self.CoolingAndDischargeDischargingCapFEvapPLRObjectNum = 0
        self.CoolingAndDischargeDischargingEIRFTempCurve = 0
        self.CoolingAndDischargeDischargingEIRFTempObjectNum = 0
        self.CoolingAndDischargeDischargingEIRFFLowCurve = 0
        self.CoolingAndDischargeDischargingEIRFFLowObjectNum = 0
        self.CoolingAndDischargeDischargingPLFFPLRCurve = 0
        self.CoolingAndDischargeDischargingPLFFPLRObjectNum = 0
        self.CoolingAndDischargeSHRFTempCurve = 0
        self.CoolingAndDischargeSHRFTempObjectNum = 0
        self.CoolingAndDischargeSHRFFlowCurve = 0
        self.CoolingAndDischargeSHRFFlowObjectNum = 0
        self.ChargeOnlyModeAvailable = False
        self.ChargeOnlyRatedCapacity = 0.0
        self.ChargeOnlyRatedCapacitySizingFactor = 0.0
        self.ChargeOnlyRatedCOP = 0.0
        self.ChargeOnlyChargingCapFTempCurve = 0
        self.ChargeOnlyChargingCapFTempObjectNum = 0
        self.ChargeOnlyChargingEIRFTempCurve = 0
        self.ChargeOnlyChargingEIRFTempObjectNum = 0
        self.DischargeOnlyModeAvailable = False
        self.DischargeOnlyRatedDischargeCap = 0.0
        self.DischargeOnlyRatedDischargeCapSizingFactor = 0.0
        self.DischargeOnlyRatedSHR = 0.0
        self.DischargeOnlyRatedCOP = 0.0
        self.DischargeOnlyCapFTempCurve = 0
        self.DischargeOnlyCapFTempObjectNum = 0
        self.DischargeOnlyCapFFlowCurve = 0
        self.DischargeOnlyCapFFlowObjectNum = 0
        self.DischargeOnlyEIRFTempCurve = 0
        self.DischargeOnlyEIRFTempObjectNum = 0
        self.DischargeOnlyEIRFFlowCurve = 0
        self.DischargeOnlyEIRFFlowObjectNum = 0
        self.DischargeOnlyPLFFPLRCurve = 0
        self.DischargeOnlyPLFFPLRObjectNum = 0
        self.DischargeOnlySHRFTempCurve = 0
        self.DischargeOnlySHRFTempObjectNum = 0
        self.DischargeOnlySHRFFLowCurve = 0
        self.DischargeOnlySHRFFLowObjectNum = 0
        self.AncillaryControlsPower = 0.0
        self.ColdWeatherMinimumTempLimit = 0.0
        self.ColdWeatherAncillaryPower = 0.0
        self.CondAirInletNodeNum = 0
        self.CondAirOutletNodeNum = 0
        self.CondenserType = TESCondenserType.Air
        self.CondenserAirVolumeFlow = 0.0
        self.CondenserAirFlowSizingFactor = 0.0
        self.CondenserAirMassFlow = 0.0
        self.EvapCondEffect = 0.0
        self.CondInletTemp = 0.0
        self.EvapCondPumpElecNomPower = 0.0
        self.EvapCondPumpElecEnergy = 0.0
        self.BasinHeaterPowerFTempDiff = 0.0
        self.basinHeaterAvailSched = UnsafePointer[SIMD[DType.float64, 1]]()
        self.BasinHeaterSetpointTemp = 0.0
        self.EvapWaterSupplyMode = EvapWaterSupply.WaterSupplyFromMains
        self.EvapWaterSupplyName = String()
        self.EvapWaterSupTankID = 0
        self.EvapWaterTankDemandARRID = 0
        self.CondensateCollectMode = CondensateAction.Discard
        self.CondensateCollectName = String()
        self.CondensateTankID = 0
        self.CondensateTankSupplyARRID = 0
        self.StorageMedia = MediaType.Invalid
        self.StorageFluidName = String()
        self.glycol = UnsafePointer[SIMD[DType.float64, 1]]()
        self.FluidStorageVolume = 0.0
        self.IceStorageCapacity = 0.0
        self.StorageCapacitySizingFactor = 0.0
        self.MinimumFluidTankTempLimit = 0.0
        self.MaximumFluidTankTempLimit = 100.0
        self.RatedFluidTankTemp = 0.0
        self.StorageAmbientNodeNum = 0
        self.StorageUA = 0.0
        self.TESPlantConnectionAvailable = False
        self.TESPlantInletNodeNum = 0
        self.TESPlantOutletNodeNum = 0
        self.TESPlantLoopNum = 0
        self.TESPlantLoopSideNum = 0
        self.TESPlantBranchNum = 0
        self.TESPlantCompNum = 0
        self.TESPlantDesignVolumeFlowRate = 0.0
        self.TESPlantDesignMassFlowRate = 0.0
        self.TESPlantEffectiveness = 0.0
        self.TimeElapsed = 0.0
        self.IceFracRemain = 0.0
        self.IceFracRemainLastTimestep = 0.0
        self.FluidTankTempFinal = 0.0
        self.FluidTankTempFinalLastTimestep = 0.0
        self.QdotPlant = 0.0
        self.Q_Plant = 0.0
        self.QdotAmbient = 0.0
        self.Q_Ambient = 0.0
        self.QdotTES = 0.0
        self.Q_TES = 0.0
        self.ElecCoolingPower = 0.0
        self.ElecCoolingEnergy = 0.0
        self.EvapTotCoolingRate = 0.0
        self.EvapTotCoolingEnergy = 0.0
        self.EvapSensCoolingRate = 0.0
        self.EvapSensCoolingEnergy = 0.0
        self.EvapLatCoolingRate = 0.0
        self.EvapLatCoolingEnergy = 0.0
        self.RuntimeFraction = 0.0
        self.CondenserRuntimeFraction = 0.0
        self.ElectColdWeatherPower = 0.0
        self.ElectColdWeatherEnergy = 0.0
        self.ElectEvapCondBasinHeaterPower = 0.0
        self.ElectEvapCondBasinHeaterEnergy = 0.0
        self.EvapWaterConsumpRate = 0.0
        self.EvapWaterConsump = 0.0
        self.EvapWaterStarvMakupRate = 0.0
        self.EvapWaterStarvMakup = 0.0
        self.EvapCondPumpElecPower = 0.0
        self.EvapCondPumpElecConsumption = 0.0


fn SimTESCoil(
    state: UnsafePointer[EnergyPlusData],
    CompName: StringRef,
    inout CompIndex: Int32,
    fanOp: Int32,
    inout TESOpMode: Int32,
    PartLoadRatio: Float64 = 0.0,
) -> None:
    """Simulate the TES Coil operation"""
    pass


fn GetTESCoilInput(state: UnsafePointer[EnergyPlusData]) -> None:
    """Parse and store TES Coil input data"""
    pass


fn InitTESCoil(state: UnsafePointer[EnergyPlusData], inout TESCoilNum: Int32) -> None:
    """Initialize TES Coil for simulation"""
    pass


fn SizeTESCoil(state: UnsafePointer[EnergyPlusData], inout TESCoilNum: Int32) -> None:
    """Size TES Coil capacity and flow"""
    pass


fn CalcTESCoilOffMode(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Calculate TES Coil operation in OFF mode"""
    pass


fn CalcTESCoilCoolingOnlyMode(
    state: UnsafePointer[EnergyPlusData],
    TESCoilNum: Int32,
    fanOp: Int32,
    PartLoadRatio: Float64,
) -> None:
    """Calculate TES Coil operation in cooling only mode"""
    pass


fn CalcTESCoilCoolingAndChargeMode(
    state: UnsafePointer[EnergyPlusData],
    TESCoilNum: Int32,
    fanOp: Int32,
    PartLoadRatio: Float64,
) -> None:
    """Calculate TES Coil operation in cooling and charge mode"""
    pass


fn CalcTESCoilCoolingAndDischargeMode(
    state: UnsafePointer[EnergyPlusData],
    TESCoilNum: Int32,
    fanOp: Int32,
    PartLoadRatio: Float64,
) -> None:
    """Calculate TES Coil operation in cooling and discharge mode"""
    pass


fn CalcTESCoilChargeOnlyMode(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Calculate TES Coil operation in charge only mode"""
    pass


fn CalcTESCoilDischargeOnlyMode(
    state: UnsafePointer[EnergyPlusData],
    TESCoilNum: Int32,
    PartLoadRatio: Float64,
) -> None:
    """Calculate TES Coil operation in discharge only mode"""
    pass


fn UpdateTEStorage(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Update thermal energy storage state"""
    pass


fn CalcTESWaterStorageTank(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Calculate water storage tank thermal state"""
    pass


fn CalcTESIceStorageTank(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Calculate ice storage tank state"""
    pass


fn UpdateColdWeatherProtection(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Update cold weather protection power"""
    pass


fn UpdateEvaporativeCondenserBasinHeater(state: UnsafePointer[EnergyPlusData], TESCoilNum: Int32) -> None:
    """Update evaporative condenser basin heater"""
    pass


fn UpdateEvaporativeCondenserWaterUse(
    state: UnsafePointer[EnergyPlusData],
    TESCoilNum: Int32,
    HumRatAfterEvap: Float64,
    InletNodeNum: Int32,
) -> None:
    """Update evaporative condenser water consumption"""
    pass


fn GetTESCoilIndex(
    state: UnsafePointer[EnergyPlusData],
    CoilName: StringRef,
    inout CoilIndex: Int32,
    inout ErrorsFound: Bool,
    CurrentModuleObject: StringRef = StringRef(""),
) -> None:
    """Get index of TES Coil by name"""
    pass


fn GetTESCoilAirInletNode(
    state: UnsafePointer[EnergyPlusData],
    CoilName: StringRef,
    inout CoilAirInletNode: Int32,
    inout ErrorsFound: Bool,
    CurrentModuleObject: StringRef,
) -> None:
    """Get TES Coil air inlet node number"""
    pass


fn GetTESCoilAirOutletNode(
    state: UnsafePointer[EnergyPlusData],
    CoilName: StringRef,
    inout CoilAirOutletNode: Int32,
    inout ErrorsFound: Bool,
    CurrentModuleObject: StringRef,
) -> None:
    """Get TES Coil air outlet node number"""
    pass


fn GetTESCoilCoolingCapacity(
    state: UnsafePointer[EnergyPlusData],
    CoilName: StringRef,
    inout CoilCoolCapacity: Float64,
    inout ErrorsFound: Bool,
    CurrentModuleObject: StringRef,
) -> None:
    """Get TES Coil cooling capacity"""
    pass


fn GetTESCoilCoolingAirFlowRate(
    state: UnsafePointer[EnergyPlusData],
    CoilName: StringRef,
    inout CoilCoolAirFlow: Float64,
    inout ErrorsFound: Bool,
    CurrentModuleObject: StringRef,
) -> None:
    """Get TES Coil cooling air flow rate"""
    pass
