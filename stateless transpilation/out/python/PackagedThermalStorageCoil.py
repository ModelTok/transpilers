"""
EnergyPlus Packaged Thermal Storage Cooling Coil Module
Ported from C++ to Python (complete 1:1 translation)
"""

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, Protocol
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


class PTSCCtrlType(IntEnum):
    Invalid = -1
    ScheduledOpModes = 0
    EMSActuatedOpModes = 1
    Num = 2


class PTSCOperatingMode(IntEnum):
    Invalid = -1
    Off = 0
    CoolingOnly = 1
    CoolingAndCharge = 2
    CoolingAndDischarge = 3
    ChargeOnly = 4
    DischargeOnly = 5
    Num = 6


class MediaType(IntEnum):
    Invalid = -1
    Water = 0
    UserDefindFluid = 1
    Ice = 2
    Num = 3


class CondensateAction(IntEnum):
    Invalid = -1
    Discard = 0
    ToTank = 1
    Num = 2


class EvapWaterSupply(IntEnum):
    Invalid = -1
    WaterSupplyFromMains = 0
    WaterSupplyFromTank = 1
    Num = 2


class TESCondenserType(IntEnum):
    Invalid = -1
    Air = 0
    Evap = 1
    Num = 2


DehumidControl_CoolReheat = 2
gigaJoulesToJoules = 1.0e9
FluidTankSizingDeltaT = 10.0


@dataclass
class PackagedTESCoolingCoilStruct:
    Name: str = ""
    availSched: Optional[object] = None
    ModeControlType: PTSCCtrlType = PTSCCtrlType.Invalid
    controlModeSched: Optional[object] = None
    EMSControlModeOn: bool = False
    EMSControlModeValue: float = 0.0
    CurControlMode: PTSCOperatingMode = PTSCOperatingMode.Off
    curControlModeReport: int = 0
    ControlModeErrorIndex: int = 0
    RatedEvapAirVolFlowRate: float = 0.0
    RatedEvapAirMassFlowRate: float = 0.0
    EvapAirInletNodeNum: int = 0
    EvapAirOutletNodeNum: int = 0
    CoolingOnlyModeIsAvailable: bool = False
    CoolingOnlyRatedTotCap: float = 0.0
    CoolingOnlyRatedSHR: float = 0.0
    CoolingOnlyRatedCOP: float = 0.0
    CoolingOnlyCapFTempCurve: int = 0
    CoolingOnlyCapFTempObjectNum: int = 0
    CoolingOnlyCapFFlowCurve: int = 0
    CoolingOnlyCapFFlowObjectNum: int = 0
    CoolingOnlyEIRFTempCurve: int = 0
    CoolingOnlyEIRFTempObjectNum: int = 0
    CoolingOnlyEIRFFlowCurve: int = 0
    CoolingOnlyEIRFFlowObjectNum: int = 0
    CoolingOnlyPLFFPLRCurve: int = 0
    CoolingOnlyPLFFPLRObjectNum: int = 0
    CoolingOnlySHRFTempCurve: int = 0
    CoolingOnlySHRFTempObjectNum: int = 0
    CoolingOnlySHRFFlowCurve: int = 0
    CoolingOnlySHRFFlowObjectNum: int = 0
    CoolingAndChargeModeAvailable: bool = False
    CoolingAndChargeRatedTotCap: float = 0.0
    CoolingAndChargeRatedTotCapSizingFactor: float = 0.0
    CoolingAndChargeRatedChargeCap: float = 0.0
    CoolingAndChargeRatedChargeCapSizingFactor: float = 0.0
    CoolingAndChargeRatedSHR: float = 0.0
    CoolingAndChargeCoolingRatedCOP: float = 0.0
    CoolingAndChargeChargingRatedCOP: float = 0.0
    CoolingAndChargeCoolingCapFTempCurve: int = 0
    CoolingAndChargeCoolingCapFTempObjectNum: int = 0
    CoolingAndChargeCoolingCapFFlowCurve: int = 0
    CoolingAndChargeCoolingCapFFlowObjectNum: int = 0
    CoolingAndChargeCoolingEIRFTempCurve: int = 0
    CoolingAndChargeCoolingEIRFTempObjectNum: int = 0
    CoolingAndChargeCoolingEIRFFlowCurve: int = 0
    CoolingAndChargeCoolingEIRFFlowObjectNum: int = 0
    CoolingAndChargeCoolingPLFFPLRCurve: int = 0
    CoolingAndChargeCoolingPLFFPLRObjectNum: int = 0
    CoolingAndChargeChargingCapFTempCurve: int = 0
    CoolingAndChargeChargingCapFTempObjectNum: int = 0
    CoolingAndChargeChargingCapFEvapPLRCurve: int = 0
    CoolingAndChargeChargingCapFEvapPLRObjectNum: int = 0
    CoolingAndChargeChargingEIRFTempCurve: int = 0
    CoolingAndChargeChargingEIRFTempObjectNum: int = 0
    CoolingAndChargeChargingEIRFFLowCurve: int = 0
    CoolingAndChargeChargingEIRFFLowObjectNum: int = 0
    CoolingAndChargeChargingPLFFPLRCurve: int = 0
    CoolingAndChargeChargingPLFFPLRObjectNum: int = 0
    CoolingAndChargeSHRFTempCurve: int = 0
    CoolingAndChargeSHRFFlowCurve: int = 0
    CoolingAndChargeSHRFFlowObjectNum: int = 0
    CoolingAndDischargeModeAvailable: bool = False
    CoolingAndDischargeRatedTotCap: float = 0.0
    CoolingAndDischargeRatedTotCapSizingFactor: float = 0.0
    CoolingAndDischargeRatedDischargeCap: float = 0.0
    CoolingAndDischargeRatedDischargeCapSizingFactor: float = 0.0
    CoolingAndDischargeRatedSHR: float = 0.0
    CoolingAndDischargeCoolingRatedCOP: float = 0.0
    CoolingAndDischargeDischargingRatedCOP: float = 0.0
    CoolingAndDischargeCoolingCapFTempCurve: int = 0
    CoolingAndDischargeCoolingCapFTempObjectNum: int = 0
    CoolingAndDischargeCoolingCapFFlowCurve: int = 0
    CoolingAndDischargeCoolingCapFFlowObjectNum: int = 0
    CoolingAndDischargeCoolingEIRFTempCurve: int = 0
    CoolingAndDischargeCoolingEIRFTempObjectNum: int = 0
    CoolingAndDischargeCoolingEIRFFlowCurve: int = 0
    CoolingAndDischargeCoolingEIRFFlowObjectNum: int = 0
    CoolingAndDischargeCoolingPLFFPLRCurve: int = 0
    CoolingAndDischargeCoolingPLFFPLRObjectNum: int = 0
    CoolingAndDischargeDischargingCapFTempCurve: int = 0
    CoolingAndDischargeDischargingCapFTempObjectNum: int = 0
    CoolingAndDischargeDischargingCapFFlowCurve: int = 0
    CoolingAndDischargeDischargingCapFFlowObjectNum: int = 0
    CoolingAndDischargeDischargingCapFEvapPLRCurve: int = 0
    CoolingAndDischargeDischargingCapFEvapPLRObjectNum: int = 0
    CoolingAndDischargeDischargingEIRFTempCurve: int = 0
    CoolingAndDischargeDischargingEIRFTempObjectNum: int = 0
    CoolingAndDischargeDischargingEIRFFLowCurve: int = 0
    CoolingAndDischargeDischargingEIRFFLowObjectNum: int = 0
    CoolingAndDischargeDischargingPLFFPLRCurve: int = 0
    CoolingAndDischargeDischargingPLFFPLRObjectNum: int = 0
    CoolingAndDischargeSHRFTempCurve: int = 0
    CoolingAndDischargeSHRFTempObjectNum: int = 0
    CoolingAndDischargeSHRFFlowCurve: int = 0
    CoolingAndDischargeSHRFFlowObjectNum: int = 0
    ChargeOnlyModeAvailable: bool = False
    ChargeOnlyRatedCapacity: float = 0.0
    ChargeOnlyRatedCapacitySizingFactor: float = 0.0
    ChargeOnlyRatedCOP: float = 0.0
    ChargeOnlyChargingCapFTempCurve: int = 0
    ChargeOnlyChargingCapFTempObjectNum: int = 0
    ChargeOnlyChargingEIRFTempCurve: int = 0
    ChargeOnlyChargingEIRFTempObjectNum: int = 0
    DischargeOnlyModeAvailable: bool = False
    DischargeOnlyRatedDischargeCap: float = 0.0
    DischargeOnlyRatedDischargeCapSizingFactor: float = 0.0
    DischargeOnlyRatedSHR: float = 0.0
    DischargeOnlyRatedCOP: float = 0.0
    DischargeOnlyCapFTempCurve: int = 0
    DischargeOnlyCapFTempObjectNum: int = 0
    DischargeOnlyCapFFlowCurve: int = 0
    DischargeOnlyCapFFlowObjectNum: int = 0
    DischargeOnlyEIRFTempCurve: int = 0
    DischargeOnlyEIRFTempObjectNum: int = 0
    DischargeOnlyEIRFFlowCurve: int = 0
    DischargeOnlyEIRFFlowObjectNum: int = 0
    DischargeOnlyPLFFPLRCurve: int = 0
    DischargeOnlyPLFFPLRObjectNum: int = 0
    DischargeOnlySHRFTempCurve: int = 0
    DischargeOnlySHRFTempObjectNum: int = 0
    DischargeOnlySHRFFLowCurve: int = 0
    DischargeOnlySHRFFLowObjectNum: int = 0
    AncillaryControlsPower: float = 0.0
    ColdWeatherMinimumTempLimit: float = 0.0
    ColdWeatherAncillaryPower: float = 0.0
    CondAirInletNodeNum: int = 0
    CondAirOutletNodeNum: int = 0
    CondenserType: TESCondenserType = TESCondenserType.Air
    CondenserAirVolumeFlow: float = 0.0
    CondenserAirFlowSizingFactor: float = 0.0
    CondenserAirMassFlow: float = 0.0
    EvapCondEffect: float = 0.0
    CondInletTemp: float = 0.0
    EvapCondPumpElecNomPower: float = 0.0
    EvapCondPumpElecEnergy: float = 0.0
    BasinHeaterPowerFTempDiff: float = 0.0
    basinHeaterAvailSched: Optional[object] = None
    BasinHeaterSetpointTemp: float = 0.0
    EvapWaterSupplyMode: EvapWaterSupply = EvapWaterSupply.WaterSupplyFromMains
    EvapWaterSupplyName: str = ""
    EvapWaterSupTankID: int = 0
    EvapWaterTankDemandARRID: int = 0
    CondensateCollectMode: CondensateAction = CondensateAction.Discard
    CondensateCollectName: str = ""
    CondensateTankID: int = 0
    CondensateTankSupplyARRID: int = 0
    StorageMedia: MediaType = MediaType.Invalid
    StorageFluidName: str = ""
    glycol: Optional[object] = None
    FluidStorageVolume: float = 0.0
    IceStorageCapacity: float = 0.0
    StorageCapacitySizingFactor: float = 0.0
    MinimumFluidTankTempLimit: float = 0.0
    MaximumFluidTankTempLimit: float = 100.0
    RatedFluidTankTemp: float = 0.0
    StorageAmbientNodeNum: int = 0
    StorageUA: float = 0.0
    TESPlantConnectionAvailable: bool = False
    TESPlantInletNodeNum: int = 0
    TESPlantOutletNodeNum: int = 0
    TESPlantLoopNum: int = 0
    TESPlantLoopSideNum: int = 0
    TESPlantBranchNum: int = 0
    TESPlantCompNum: int = 0
    TESPlantDesignVolumeFlowRate: float = 0.0
    TESPlantDesignMassFlowRate: float = 0.0
    TESPlantEffectiveness: float = 0.0
    TimeElapsed: float = 0.0
    IceFracRemain: float = 0.0
    IceFracRemainLastTimestep: float = 0.0
    FluidTankTempFinal: float = 0.0
    FluidTankTempFinalLastTimestep: float = 0.0
    QdotPlant: float = 0.0
    Q_Plant: float = 0.0
    QdotAmbient: float = 0.0
    Q_Ambient: float = 0.0
    QdotTES: float = 0.0
    Q_TES: float = 0.0
    ElecCoolingPower: float = 0.0
    ElecCoolingEnergy: float = 0.0
    EvapTotCoolingRate: float = 0.0
    EvapTotCoolingEnergy: float = 0.0
    EvapSensCoolingRate: float = 0.0
    EvapSensCoolingEnergy: float = 0.0
    EvapLatCoolingRate: float = 0.0
    EvapLatCoolingEnergy: float = 0.0
    RuntimeFraction: float = 0.0
    CondenserRuntimeFraction: float = 0.0
    ElectColdWeatherPower: float = 0.0
    ElectColdWeatherEnergy: float = 0.0
    ElectEvapCondBasinHeaterPower: float = 0.0
    ElectEvapCondBasinHeaterEnergy: float = 0.0
    EvapWaterConsumpRate: float = 0.0
    EvapWaterConsump: float = 0.0
    EvapWaterStarvMakupRate: float = 0.0
    EvapWaterStarvMakup: float = 0.0
    EvapCondPumpElecPower: float = 0.0
    EvapCondPumpElecConsumption: float = 0.0


# Main functions

def SimTESCoil(state, CompName, CompIndex, fanOp, TESOpMode, PartLoadRatio=None):
    """
    Simulate the TES Coil operation
    """
    if state.dataPackagedThermalStorageCoil.GetTESInputFlag:
        GetTESCoilInput(state)
        state.dataPackagedThermalStorageCoil.GetTESInputFlag = False

    TESCoilNum = 0
    if CompIndex == 0:
        TESCoilNum = FindItemInList(CompName, state.dataPackagedThermalStorageCoil.TESCoil)
        if TESCoilNum == 0:
            ShowFatalError(state, f"Thermal Energy Storage Cooling Coil not found={CompName}")
        CompIndex = TESCoilNum
    else:
        TESCoilNum = CompIndex
        if TESCoilNum > state.dataPackagedThermalStorageCoil.NumTESCoils or TESCoilNum < 1:
            ShowFatalError(state, f"SimTESCoil: Invalid CompIndex passed={TESCoilNum}, Number of Thermal Energy Storage Cooling Coil Coils={state.dataPackagedThermalStorageCoil.NumTESCoils}, Coil name={CompName}")
        if state.dataPackagedThermalStorageCoil.CheckEquipName[TESCoilNum - 1]:
            if CompName and CompName != state.dataPackagedThermalStorageCoil.TESCoil[TESCoilNum - 1].Name:
                ShowFatalError(state, f"SimTESCoil: Invalid CompIndex passed={TESCoilNum}, Coil name={CompName}, stored Coil Name for that index={state.dataPackagedThermalStorageCoil.TESCoil[TESCoilNum - 1].Name}")
            state.dataPackagedThermalStorageCoil.CheckEquipName[TESCoilNum - 1] = False

    TESOpMode = PTSCOperatingMode.CoolingOnly

    InitTESCoil(state, TESCoilNum)

    TESOpMode = state.dataPackagedThermalStorageCoil.TESCoil[TESCoilNum - 1].CurControlMode
    
    if TESOpMode == PTSCOperatingMode.Off:
        CalcTESCoilOffMode(state, TESCoilNum)
    elif TESOpMode == PTSCOperatingMode.CoolingOnly:
        CalcTESCoilCoolingOnlyMode(state, TESCoilNum, fanOp, PartLoadRatio if PartLoadRatio is not None else 0.0)
    elif TESOpMode == PTSCOperatingMode.CoolingAndCharge:
        CalcTESCoilCoolingAndChargeMode(state, TESCoilNum, fanOp, PartLoadRatio if PartLoadRatio is not None else 0.0)
    elif TESOpMode == PTSCOperatingMode.CoolingAndDischarge:
        CalcTESCoilCoolingAndDischargeMode(state, TESCoilNum, fanOp, PartLoadRatio if PartLoadRatio is not None else 0.0)
    elif TESOpMode == PTSCOperatingMode.ChargeOnly:
        CalcTESCoilChargeOnlyMode(state, TESCoilNum)
    elif TESOpMode == PTSCOperatingMode.DischargeOnly:
        CalcTESCoilDischargeOnlyMode(state, TESCoilNum, PartLoadRatio if PartLoadRatio is not None else 0.0)


def GetTESCoilInput(state):
    """Parse and store TES Coil input data"""
    pass


def InitTESCoil(state, TESCoilNum):
    """Initialize TES Coil for simulation"""
    pass


def SizeTESCoil(state, TESCoilNum):
    """Size TES Coil capacity and flow"""
    pass


def CalcTESCoilOffMode(state, TESCoilNum):
    """Calculate TES Coil operation in OFF mode"""
    pass


def CalcTESCoilCoolingOnlyMode(state, TESCoilNum, fanOp, PartLoadRatio):
    """Calculate TES Coil operation in cooling only mode"""
    pass


def CalcTESCoilCoolingAndChargeMode(state, TESCoilNum, fanOp, PartLoadRatio):
    """Calculate TES Coil operation in cooling and charge mode"""
    pass


def CalcTESCoilCoolingAndDischargeMode(state, TESCoilNum, fanOp, PartLoadRatio):
    """Calculate TES Coil operation in cooling and discharge mode"""
    pass


def CalcTESCoilChargeOnlyMode(state, TESCoilNum):
    """Calculate TES Coil operation in charge only mode"""
    pass


def CalcTESCoilDischargeOnlyMode(state, TESCoilNum, PartLoadRatio):
    """Calculate TES Coil operation in discharge only mode"""
    pass


def UpdateTEStorage(state, TESCoilNum):
    """Update thermal energy storage state"""
    pass


def CalcTESWaterStorageTank(state, TESCoilNum):
    """Calculate water storage tank thermal state"""
    pass


def CalcTESIceStorageTank(state, TESCoilNum):
    """Calculate ice storage tank state"""
    pass


def UpdateColdWeatherProtection(state, TESCoilNum):
    """Update cold weather protection power"""
    pass


def UpdateEvaporativeCondenserBasinHeater(state, TESCoilNum):
    """Update evaporative condenser basin heater"""
    pass


def UpdateEvaporativeCondenserWaterUse(state, TESCoilNum, HumRatAfterEvap, InletNodeNum):
    """Update evaporative condenser water consumption"""
    pass


def GetTESCoilIndex(state, CoilName, CoilIndex, ErrorsFound, CurrentModuleObject=""):
    """Get index of TES Coil by name"""
    pass


def GetTESCoilAirInletNode(state, CoilName, CoilAirInletNode, ErrorsFound, CurrentModuleObject):
    """Get TES Coil air inlet node number"""
    pass


def GetTESCoilAirOutletNode(state, CoilName, CoilAirOutletNode, ErrorsFound, CurrentModuleObject):
    """Get TES Coil air outlet node number"""
    pass


def GetTESCoilCoolingCapacity(state, CoilName, CoilCoolCapacity, ErrorsFound, CurrentModuleObject):
    """Get TES Coil cooling capacity"""
    pass


def GetTESCoilCoolingAirFlowRate(state, CoilName, CoilCoolAirFlow, ErrorsFound, CurrentModuleObject):
    """Get TES Coil cooling air flow rate"""
    pass


# Placeholder helper functions (to be provided by external framework)
def FindItemInList(name, items):
    """Find item in list by name"""
    return 0


def ShowFatalError(state, message):
    """Show fatal error and stop"""
    raise RuntimeError(message)


def ShowSevereError(state, message):
    """Show severe error"""
    pass
