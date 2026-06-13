from enum import IntEnum
from dataclasses import dataclass, field
from typing import Protocol, Optional, List, Any
from abc import ABC, abstractmethod

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state (passed as parameter, type Protocol)
# - Sched module (Schedule objects with getCurrentVal(), GetSchedule(), GetScheduleAlwaysOn())
# - InputProcessor (getNumObjectsFound, getObjectItem)
# - Various data containers (dataWaterCoils, dataHeatingCoils, dataSteamCoils, etc.)
# - Util module (SameString, FindItemInList, makeUPPER)
# - HVAC module (FanType enum)
# - DataPlant module (PlantEquipmentType, CondenserType, PlantEquipTypeNames)
# - Fans module (GetFanIndex, FanComponent)
# - CurveManager module (GetCurveIndex, CurveValue)
# - Error reporting functions (ShowSevereError, ShowWarningError, ShowSevereItemNotFound, ShowFatalError, etc.)

# Enum: FouledCoil
class FouledCoil(IntEnum):
    Invalid = -1
    UARated = 0
    FoulingFactor = 1
    Num = 2


# Enum: FaultType
class FaultType(IntEnum):
    Invalid = -1
    TemperatureSensorOffset_OutdoorAir = 0
    HumiditySensorOffset_OutdoorAir = 1
    EnthalpySensorOffset_OutdoorAir = 2
    TemperatureSensorOffset_ReturnAir = 3
    EnthalpySensorOffset_ReturnAir = 4
    Fouling_Coil = 5
    ThermostatOffset = 6
    HumidistatOffset = 7
    Fouling_AirFilter = 8
    TemperatureSensorOffset_ChillerSupplyWater = 9
    TemperatureSensorOffset_CondenserSupplyWater = 10
    Fouling_Tower = 11
    TemperatureSensorOffset_CoilSupplyAir = 12
    Fouling_Boiler = 13
    Fouling_Chiller = 14
    Fouling_EvapCooler = 15
    Num = 16


iController_AirEconomizer = 1001

# Fault type strings
cFaults = [
    "FaultModel:TemperatureSensorOffset:OutdoorAir",
    "FaultModel:HumiditySensorOffset:OutdoorAir",
    "FaultModel:EnthalpySensorOffset:OutdoorAir",
    "FaultModel:TemperatureSensorOffset:ReturnAir",
    "FaultModel:EnthalpySensorOffset:ReturnAir",
    "FaultModel:Fouling:Coil",
    "FaultModel:ThermostatOffset",
    "FaultModel:HumidistatOffset",
    "FaultModel:Fouling:AirFilter",
    "FaultModel:TemperatureSensorOffset:ChillerSupplyWater",
    "FaultModel:TemperatureSensorOffset:CondenserSupplyWater",
    "FaultModel:Fouling:CoolingTower",
    "FaultModel:TemperatureSensorOffset:CoilSupplyAir",
    "FaultModel:Fouling:Boiler",
    "FaultModel:Fouling:Chiller",
    "FaultModel:Fouling:EvaporativeCooler",
]

# Chiller type enum
class ChillerType(IntEnum):
    Invalid = -1
    ChillerElectric = 0
    ChillerElectricEIR = 1
    ChillerElectricReformulatedEIR = 2
    ChillerConstantCOP = 3
    ChillerEngineDriven = 4
    ChillerCombustionTurbine = 5
    ChillerAbsorption = 6
    ChillerAbsorptionIndirect = 7
    Num = 8


# Coil type enum
class CoilType(IntEnum):
    Invalid = -1
    CoilHeatingElectric = 0
    CoilHeatingFuel = 1
    CoilHeatingDesuperheater = 2
    CoilHeatingSteam = 3
    CoilHeatingWater = 4
    CoilCoolingWater = 5
    CoilCoolingWaterDetailedgeometry = 6
    CoilSystemCoolingDX = 7
    CoilSystemHeatingDX = 8
    AirLoopHVACUnitarySystem = 9
    Num = 10


ChillerTypeNamesUC = [
    "CHILLER:ELECTRIC",
    "CHILLER:ELECTRIC:EIR",
    "CHILLER:ELECTRIC:REFORMULATEDEIR",
    "CHILLER:CONSTANTCOP",
    "CHILLER:ENGINEDRIVEN",
    "CHILLER:COMBUSTIONTURBINE",
    "CHILLER:ABSORPTION",
    "CHILLER:ABSORPTION:INDIRECT",
]

CoilTypeNamesUC = [
    "COIL:HEATING:ELECTRIC",
    "COIL:HEATING:FUEL",
    "COIL:HEATING:DESUPERHEATER",
    "COIL:HEATING:STEAM",
    "COIL:HEATING:WATER",
    "COIL:COOLING:WATER",
    "COIL:COOLING:WATER:DETAILEDGEOMETRY",
    "COILSYSTEM:COOLING:DX",
    "COILSYSTEM:HEATING:DX",
    "AIRLOOPHVAC:UNITARYSYSTEM",
]

FouledCoilNamesUC = [
    "FOULEDUARATED",
    "FOULINGFACTOR",
]


# Protocol for Schedule interface
class Schedule(Protocol):
    def getCurrentVal(self) -> float:
        ...


# Protocol for state parameter
class EnergyPlusDataProtocol(Protocol):
    pass


@dataclass
class FaultProperties:
    """Base class for operational faults"""
    Name: str = ""
    type: FaultType = FaultType.Invalid
    availSched: Optional[Schedule] = None
    severitySched: Optional[Schedule] = None
    Offset: float = 0.0
    Status: bool = False

    def CalFaultOffsetAct(self, state: Any) -> float:
        FaultFac = 0.0
        if self.availSched and self.availSched.getCurrentVal() > 0.0:
            FaultFac = self.severitySched.getCurrentVal() if self.severitySched else 1.0
        return FaultFac * self.Offset


@dataclass
class FaultPropertiesEconomizer(FaultProperties):
    """Class for fault models related with economizer"""
    ControllerTypeEnum: int = 0
    ControllerID: int = 0
    ControllerType: str = ""
    ControllerName: str = ""


@dataclass
class FaultPropertiesThermostat(FaultProperties):
    """Class for FaultModel:ThermostatOffset"""
    FaultyThermostatName: str = ""


@dataclass
class FaultPropertiesHumidistat(FaultProperties):
    """Class for FaultModel:HumidistatOffset"""
    FaultyThermostatName: str = ""
    FaultyHumidistatName: str = ""
    FaultyHumidistatType: str = ""


@dataclass
class FaultPropertiesFoulingCoil(FaultProperties):
    """Class for FaultModel:Fouling:Coil"""
    FouledCoilName: str = ""
    FouledCoilType: Any = None
    FouledCoilNum: int = 0
    FoulingInputMethod: FouledCoil = FouledCoil.Invalid
    UAFouled: float = 0.0
    Rfw: float = 0.0
    Rfa: float = 0.0
    Aout: float = 0.0
    Aratio: float = 0.0

    def FaultFraction(self, state: Any) -> float:
        if self.availSched and self.availSched.getCurrentVal() > 0.0:
            return self.severitySched.getCurrentVal() if self.severitySched else 1.0
        return 0.0


@dataclass
class FaultPropertiesAirFilter(FaultProperties):
    """Class for FaultModel:Fouling:AirFilter"""
    fanName: str = ""
    fanNum: int = 0
    fanType: Any = None
    fanCurveNum: int = 0
    pressFracSched: Optional[Schedule] = None
    fanPressInc: float = 0.0
    fanFlowDec: float = 0.0

    def CheckFaultyAirFilterFanCurve(self, state: Any) -> bool:
        from importlib import import_module
        fan = state.dataFans.fans[self.fanNum - 1]
        Curve = import_module('Curve')
        deltaPressCal = Curve.CurveValue(state, self.fanCurveNum, fan.maxAirFlowRate)
        return (deltaPressCal > 0.95 * fan.deltaPress) and (deltaPressCal < 1.05 * fan.deltaPress)


@dataclass
class FaultPropertiesCoilSAT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:CoilSupplyAir"""
    CoilType: str = ""
    CoilName: str = ""
    WaterCoilControllerName: str = ""


@dataclass
class FaultPropertiesChillerSWT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:ChillerSupplyWater"""
    ChillerType: str = ""
    ChillerName: str = ""

    def CalFaultChillerSWT(
        self,
        FlagVariableFlow: bool,
        FaultyChillerSWTOffset: float,
        Cp: float,
        EvapInletTemp: float,
        EvapOutletTemp: float,
        EvapMassFlowRate: float,
        QEvaporator: float,
    ) -> tuple:
        EvapOutletTemp_ff = EvapOutletTemp
        EvapMassFlowRate_ff = EvapMassFlowRate
        QEvaporator_ff = QEvaporator

        if not FlagVariableFlow:
            EvapOutletTemp_f = EvapOutletTemp_ff - FaultyChillerSWTOffset
            if (EvapInletTemp > EvapOutletTemp_f) and (EvapMassFlowRate_ff > 0):
                QEvaporator_f = EvapMassFlowRate_ff * Cp * (EvapInletTemp - EvapOutletTemp_f)
            else:
                EvapMassFlowRate_f = 0.0
                QEvaporator_f = 0.0
        else:
            EvapOutletTemp_f = EvapOutletTemp_ff - FaultyChillerSWTOffset
            if (EvapInletTemp > EvapOutletTemp_f) and (Cp > 0) and (EvapMassFlowRate_ff > 0):
                EvapMassFlowRate_f = QEvaporator_ff / Cp / (EvapInletTemp - EvapOutletTemp_ff)
                QEvaporator_f = EvapMassFlowRate_f * Cp * (EvapInletTemp - EvapOutletTemp_f)
            else:
                EvapMassFlowRate_f = 0.0
                QEvaporator_f = 0.0

        EvapMassFlowRate_f = EvapMassFlowRate_f if not FlagVariableFlow else EvapMassFlowRate_f
        return EvapOutletTemp_f, EvapMassFlowRate_f, QEvaporator_f


@dataclass
class FaultPropertiesCondenserSWT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:CondenserSupplyWater"""
    TowerType: str = ""
    TowerName: str = ""


@dataclass
class FaultPropertiesTowerFouling(FaultProperties):
    """Class for FaultModel:Fouling:CoolingTower"""
    TowerType: str = ""
    TowerName: str = ""
    UAReductionFactor: float = 1.0

    def CalFaultyTowerFoulingFactor(self, state: Any) -> float:
        FaultFac = 0.0
        if self.availSched and self.availSched.getCurrentVal() > 0.0:
            FaultFac = self.severitySched.getCurrentVal() if self.severitySched else 1.0
        UAReductionFactorAct = 1.0
        if FaultFac > 0.0:
            UAReductionFactorAct = min(self.UAReductionFactor / FaultFac, 1.0)
        return UAReductionFactorAct


@dataclass
class FaultPropertiesFouling(FaultProperties):
    """Class for FaultModel:Fouling"""
    FoulingFactor: float = 1.0

    def CalFoulingFactor(self, state: Any) -> float:
        FaultFac = 0.0
        if self.availSched and self.availSched.getCurrentVal() > 0.0:
            FaultFac = self.severitySched.getCurrentVal() if self.severitySched else 1.0
        FoulingFactor = 1.0
        if FaultFac > 0.0:
            FoulingFactor = min(self.FoulingFactor / FaultFac, 1.0)
        return FoulingFactor


@dataclass
class FaultPropertiesBoilerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:Boiler"""
    BoilerType: str = ""
    BoilerName: str = ""


@dataclass
class FaultPropertiesChillerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:Chiller"""
    ChillerType: str = ""
    ChillerName: str = ""


@dataclass
class FaultPropertiesEvapCoolerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:EvaporativeCooler"""
    EvapCoolerType: str = ""
    EvapCoolerName: str = ""


def get_enum_value(names_uc: List[str], search_str: str) -> int:
    """Helper to find enum value from uppercase names list"""
    try:
        return names_uc.index(search_str.upper())
    except ValueError:
        return -1


def CheckAndReadFaults(state: Any) -> None:
    """Check and read fault input"""
    if state.dataFaultsMgr.RunFaultMgrOnceFlag:
        return

    state.dataFaultsMgr.NumFaults = 0
    state.dataFaultsMgr.NumFaultyEconomizer = 0

    for i in range(16):
        NumFaultsTemp = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cFaults[i])
        state.dataFaultsMgr.NumFaults += NumFaultsTemp

        if i <= 4:
            state.dataFaultsMgr.NumFaultyEconomizer += NumFaultsTemp
        elif i == 5:
            state.dataFaultsMgr.NumFouledCoil = NumFaultsTemp
        elif i == 6:
            state.dataFaultsMgr.NumFaultyThermostat = NumFaultsTemp
        elif i == 7:
            state.dataFaultsMgr.NumFaultyHumidistat = NumFaultsTemp
        elif i == 8:
            state.dataFaultsMgr.NumFaultyAirFilter = NumFaultsTemp
        elif i == 9:
            state.dataFaultsMgr.NumFaultyChillerSWTSensor = NumFaultsTemp
        elif i == 10:
            state.dataFaultsMgr.NumFaultyCondenserSWTSensor = NumFaultsTemp
        elif i == 11:
            state.dataFaultsMgr.NumFaultyTowerFouling = NumFaultsTemp
        elif i == 12:
            state.dataFaultsMgr.NumFaultyCoilSATSensor = NumFaultsTemp
        elif i == 13:
            state.dataFaultsMgr.NumFaultyBoilerFouling = NumFaultsTemp
        elif i == 14:
            state.dataFaultsMgr.NumFaultyChillerFouling = NumFaultsTemp
        elif i == 15:
            state.dataFaultsMgr.NumFaultyEvapCoolerFouling = NumFaultsTemp

    if state.dataFaultsMgr.NumFaults > 0:
        state.dataFaultsMgr.AnyFaultsInModel = True
    else:
        state.dataFaultsMgr.AnyFaultsInModel = False

    if not state.dataFaultsMgr.AnyFaultsInModel:
        state.dataFaultsMgr.RunFaultMgrOnceFlag = True
        return

    if state.dataFaultsMgr.NumFaultyEconomizer > 0:
        state.dataFaultsMgr.FaultsEconomizer = [FaultPropertiesEconomizer() for _ in range(state.dataFaultsMgr.NumFaultyEconomizer)]
    if state.dataFaultsMgr.NumFouledCoil > 0:
        state.dataFaultsMgr.FouledCoils = [FaultPropertiesFoulingCoil() for _ in range(state.dataFaultsMgr.NumFouledCoil)]
    if state.dataFaultsMgr.NumFaultyThermostat > 0:
        state.dataFaultsMgr.FaultsThermostatOffset = [FaultPropertiesThermostat() for _ in range(state.dataFaultsMgr.NumFaultyThermostat)]
    if state.dataFaultsMgr.NumFaultyHumidistat > 0:
        state.dataFaultsMgr.FaultsHumidistatOffset = [FaultPropertiesHumidistat() for _ in range(state.dataFaultsMgr.NumFaultyHumidistat)]
    if state.dataFaultsMgr.NumFaultyAirFilter > 0:
        state.dataFaultsMgr.FaultsFouledAirFilters = [FaultPropertiesAirFilter() for _ in range(state.dataFaultsMgr.NumFaultyAirFilter)]
    if state.dataFaultsMgr.NumFaultyChillerSWTSensor > 0:
        state.dataFaultsMgr.FaultsChillerSWTSensor = [FaultPropertiesChillerSWT() for _ in range(state.dataFaultsMgr.NumFaultyChillerSWTSensor)]
    if state.dataFaultsMgr.NumFaultyCondenserSWTSensor > 0:
        state.dataFaultsMgr.FaultsCondenserSWTSensor = [FaultPropertiesCondenserSWT() for _ in range(state.dataFaultsMgr.NumFaultyCondenserSWTSensor)]
    if state.dataFaultsMgr.NumFaultyTowerFouling > 0:
        state.dataFaultsMgr.FaultsTowerFouling = [FaultPropertiesTowerFouling() for _ in range(state.dataFaultsMgr.NumFaultyTowerFouling)]
    if state.dataFaultsMgr.NumFaultyCoilSATSensor > 0:
        state.dataFaultsMgr.FaultsCoilSATSensor = [FaultPropertiesCoilSAT() for _ in range(state.dataFaultsMgr.NumFaultyCoilSATSensor)]
    if state.dataFaultsMgr.NumFaultyBoilerFouling > 0:
        state.dataFaultsMgr.FaultsBoilerFouling = [FaultPropertiesBoilerFouling() for _ in range(state.dataFaultsMgr.NumFaultyBoilerFouling)]
    if state.dataFaultsMgr.NumFaultyChillerFouling > 0:
        state.dataFaultsMgr.FaultsChillerFouling = [FaultPropertiesChillerFouling() for _ in range(state.dataFaultsMgr.NumFaultyChillerFouling)]
    if state.dataFaultsMgr.NumFaultyEvapCoolerFouling > 0:
        state.dataFaultsMgr.FaultsEvapCoolerFouling = [FaultPropertiesEvapCoolerFouling() for _ in range(state.dataFaultsMgr.NumFaultyEvapCoolerFouling)]

    state.dataFaultsMgr.RunFaultMgrOnceFlag = True


def SetFaultyCoilSATSensor(
    state: Any, CompType: str, CompName: str
) -> tuple:
    """Set faulty coil SAT sensor flags"""
    FaultyCoilSATFlag = False
    FaultyCoilSATIndex = 0
    if state.dataFaultsMgr.NumFaultyCoilSATSensor == 0:
        return FaultyCoilSATFlag, FaultyCoilSATIndex
    for jFault_CoilSAT in range(1, state.dataFaultsMgr.NumFaultyCoilSATSensor + 1):
        fault = state.dataFaultsMgr.FaultsCoilSATSensor[jFault_CoilSAT - 1]
        if fault.CoilType.upper() == CompType.upper() and fault.CoilName.upper() == CompName.upper():
            FaultyCoilSATFlag = True
            FaultyCoilSATIndex = jFault_CoilSAT
            break
    return FaultyCoilSATFlag, FaultyCoilSATIndex
