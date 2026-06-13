# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object from EnergyPlus.Data.EnergyPlusData
# - CompressorType: enum (local)
# - DataPlant.PlantEquipmentType: from EnergyPlus.Plant.DataPlant
# - DataPlant.CompData: from EnergyPlus.Plant.DataPlant
# - HVAC.FanOp, HVAC.CompressorOp: from EnergyPlus.DataHVACGlobals
# - Fluid.RefrigProps, Fluid.GlycolProps, Fluid.GlycolNum_Water: from EnergyPlus.FluidProperties
# - Sched.Schedule: from EnergyPlus.Schedules
# - PlantLocation: from EnergyPlus.Plant.PlantLocation
# - Psychrometrics: module from EnergyPlus
# - Curve: module from EnergyPlus.CurveManager
# - PlantUtilities: module from EnergyPlus
# - Node: module from EnergyPlus.NodeInputManager
# - General.SolveRoot2, General.SOLVEROOT_ERROR_ITER: from EnergyPlus.General
# - Util: module from EnergyPlus.UtilityRoutines
# - OutputProcessor, OutputReportPredefined: from EnergyPlus output modules
# - Error functions (ShowFatalError, etc.): from EnergyPlus.UtilityRoutines
# - Constant: module from EnergyPlus.Data.Constants
# - math module for pow, exp, expm1

from enum import Enum
import math
from dataclasses import dataclass, field
from typing import Optional, Any


class CompressorType(Enum):
    Invalid = -1
    Reciprocating = 0
    Rotary = 1
    Scroll = 2
    Num = 3


@dataclass
class WatertoAirHPEquipConditions:
    Name: str = ""
    availSched: Optional[Any] = None
    WatertoAirHPType: str = ""
    WAHPType: Optional[Any] = None
    Refrigerant: str = ""
    refrig: Optional[Any] = None
    SimFlag: bool = False
    InletAirMassFlowRate: float = 0.0
    OutletAirMassFlowRate: float = 0.0
    InletAirDBTemp: float = 0.0
    InletAirHumRat: float = 0.0
    OutletAirDBTemp: float = 0.0
    OutletAirHumRat: float = 0.0
    InletAirEnthalpy: float = 0.0
    OutletAirEnthalpy: float = 0.0
    InletWaterTemp: float = 0.0
    OutletWaterTemp: float = 0.0
    InletWaterMassFlowRate: float = 0.0
    OutletWaterMassFlowRate: float = 0.0
    DesignWaterMassFlowRate: float = 0.0
    DesignWaterVolFlowRate: float = 0.0
    InletWaterEnthalpy: float = 0.0
    OutletWaterEnthalpy: float = 0.0
    Power: float = 0.0
    Energy: float = 0.0
    QSensible: float = 0.0
    QLatent: float = 0.0
    QSource: float = 0.0
    EnergySensible: float = 0.0
    EnergyLatent: float = 0.0
    EnergySource: float = 0.0
    RunFrac: float = 0.0
    PartLoadRatio: float = 0.0
    HeatingCapacity: float = 0.0
    CoolingCapacity: float = 0.0
    QLoadTotal: float = 0.0
    EnergyLoadTotal: float = 0.0
    Twet_Rated: float = 0.0
    Gamma_Rated: float = 0.0
    MaxONOFFCyclesperHour: float = 0.0
    LatentCapacityTimeConstant: float = 0.0
    FanDelayTime: float = 0.0
    SourceSideUACoeff: float = 0.0
    LoadSideTotalUACoeff: float = 0.0
    LoadSideOutsideUACoeff: float = 0.0
    CompPistonDisp: float = 0.0
    CompClearanceFactor: float = 0.0
    CompSucPressDrop: float = 0.0
    SuperheatTemp: float = 0.0
    PowerLosses: float = 0.0
    LossFactor: float = 0.0
    RefVolFlowRate: float = 0.0
    VolumeRatio: float = 0.0
    LeakRateCoeff: float = 0.0
    SourceSideHTR1: float = 0.0
    SourceSideHTR2: float = 0.0
    PLFCurveIndex: int = 0
    HighPressCutoff: float = 0.0
    LowPressCutoff: float = 0.0
    compressorType: CompressorType = CompressorType.Invalid
    AirInletNodeNum: int = 0
    AirOutletNodeNum: int = 0
    WaterInletNodeNum: int = 0
    WaterOutletNodeNum: int = 0
    LowPressClgError: int = 0
    HighPressClgError: int = 0
    LowPressHtgError: int = 0
    HighPressHtgError: int = 0
    plantLoc: Optional[Any] = None
    solveRootStats: Optional[Any] = None


@dataclass
class WaterToAirHeatPumpData:
    NumWatertoAirHPs: int = 0
    CheckEquipName: list = field(default_factory=list)
    GetCoilsInputFlag: bool = True
    MyOneTimeFlag: bool = True
    firstTime: bool = True
    WatertoAirHP: list = field(default_factory=list)
    initialQSource: float = 0.0
    initialQLoad: float = 0.0
    MyPlantScanFlag: list = field(default_factory=list)
    MyEnvrnFlag: list = field(default_factory=list)
    initialQSource_calc: float = 0.0
    initialQLoadTotal_calc: float = 0.0
    CompSuctionTemp: float = 0.0
    LoadSideInletDBTemp_Init: float = 0.0
    LoadSideInletHumRat_Init: float = 0.0
    LoadSideAirInletEnth_Init: float = 0.0


def SimWatertoAirHP(state, CompName, CompIndex, DesignAirflow, fanOp, FirstHVACIteration, InitFlag, SensLoad, LatentLoad, compressorOp, PartLoadRatio):
    if state.dataWaterToAirHeatPump.GetCoilsInputFlag:
        GetWatertoAirHPInput(state)
        state.dataWaterToAirHeatPump.GetCoilsInputFlag = False

    if CompIndex == 0:
        HPNum = Util_FindItemInList(CompName, state.dataWaterToAirHeatPump.WatertoAirHP)
        if HPNum == 0:
            ShowFatalError(state, f"WaterToAir HP not found={CompName}")
        CompIndex = HPNum
    else:
        HPNum = CompIndex
        if HPNum > state.dataWaterToAirHeatPump.NumWatertoAirHPs or HPNum < 1:
            ShowFatalError(state, f"SimWatertoAirHP: Invalid CompIndex passed={HPNum}, Number of Water to Air HPs={state.dataWaterToAirHeatPump.NumWatertoAirHPs}, WaterToAir HP name={CompName}")
        if state.dataWaterToAirHeatPump.CheckEquipName[HPNum - 1]:
            if CompName and CompName != state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Name:
                ShowFatalError(state, f"SimWatertoAirHP: Invalid CompIndex passed={HPNum}, WaterToAir HP name={CompName}, stored WaterToAir HP Name for that index={state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Name}")
            state.dataWaterToAirHeatPump.CheckEquipName[HPNum - 1] = False

    if state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WAHPType == "CoilWAHPCoolingParamEst":
        InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
        CalcWatertoAirHPCooling(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
        UpdateWatertoAirHP(state, HPNum)
    elif state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WAHPType == "CoilWAHPHeatingParamEst":
        InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
        CalcWatertoAirHPHeating(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
        UpdateWatertoAirHP(state, HPNum)
    else:
        ShowFatalError(state, "SimWatertoAirHP: AirtoAir heatpump not in either HEATING or COOLING")


def GetWatertoAirHPInput(state):
    pass


def InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirFlow, PartLoadRatio):
    pass


def CalcWatertoAirHPCooling(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensDemand, compressorOp, PartLoadRatio):
    pass


def CalcWatertoAirHPHeating(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensDemand, compressorOp, PartLoadRatio):
    pass


def UpdateWatertoAirHP(state, HPNum):
    pass


def CalcEffectiveSHR(state, HPNum, SHRss, fanOp, RTF, QLatRated, QLatActual, EnteringDB, EnteringWB):
    pass


def DegradF(state, glycol, Temp):
    pass


def GetCoilIndex(state, CoilType, CoilName, ErrorsFound):
    pass


def GetCoilCapacity(state, CoilType, CoilName, ErrorsFound):
    pass


def GetCoilInletNode(state, CoilType, CoilName, ErrorsFound):
    pass


def GetCoilOutletNode(state, CoilType, CoilName, ErrorsFound):
    pass


def Util_FindItemInList(name, items):
    for i, item in enumerate(items):
        if item.Name == name:
            return i + 1
    return 0


def ShowFatalError(state, msg):
    raise RuntimeError(msg)
