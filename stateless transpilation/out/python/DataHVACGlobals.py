# DataHVACGlobals.py
# EXTERNAL DEPS (to wire in glue):
# BaseGlobalStruct - from EnergyPlus/Data/BaseData (base class)
# EnergyPlusData - from EnergyPlus/EnergyPlus (state object)

from enum import IntEnum
from dataclasses import dataclass
from typing import List, Tuple, Any

class CtrlVarType(IntEnum):
    Invalid = -1
    Temp = 0
    MaxTemp = 1
    MinTemp = 2
    HumRat = 3
    MaxHumRat = 4
    MinHumRat = 5
    MassFlowRate = 6
    MaxMassFlowRate = 7
    MinMassFlowRate = 8
    Num = 9

SmallHumRatDiff = 1.0E-7
SmallTempDiff = 1.0E-5
SmallMassFlow = 0.001
VerySmallMassFlow = 1.0E-30
SmallLoad = 1.0
TempControlTol = 0.1
SmallAirVolFlow = 0.001
SmallWaterVolFlow = 1.0E-9
BlankNumeric = -99999.0
RetTempMax = 60.0
RetTempMin = -30.0
DesCoilHWInletTempMin = 46.0

NumOfSizingTypes = 35

CoolingAirflowSizing = 1
CoolingWaterDesWaterInletTempSizing = 6
HeatingAirflowSizing = 14
SystemAirflowSizing = 16
CoolingCapacitySizing = 17
HeatingCapacitySizing = 18
SystemCapacitySizing = 21
AutoCalculateSizing = 25

class SetptType(IntEnum):
    Invalid = -1
    Uncontrolled = 0
    SingleHeat = 1
    SingleCool = 2
    SingleHeatCool = 3
    DualHeatCool = 4
    Num = 5

controlledSetptTypes = (
    SetptType.SingleHeat, SetptType.SingleCool, SetptType.SingleHeatCool, SetptType.DualHeatCool
)

setptTypeNames = (
    "Uncontrolled", "SingleHeating", "SingleCooling", "SingleHeatCool", "DualSetPointWithDeadBand"
)

class AirDuctType(IntEnum):
    Invalid = -1
    Main = 0
    Cooling = 1
    Heating = 2
    Other = 3
    RAB = 4
    Num = 5

airDuctTypeNames = (
    "Main", "Cooling", "Heating", "Other", "Return Air Bypass"
)

Cooling = 2
Heating = 3

class FanType(IntEnum):
    Invalid = -1
    Constant = 0
    VAV = 1
    OnOff = 2
    Exhaust = 3
    ComponentModel = 4
    SystemModel = 5
    Num = 6

fanTypeNames: Tuple[str, ...] = ()
fanTypeNamesUC: Tuple[str, ...] = ()

class FanOp(IntEnum):
    Invalid = -1
    Cycling = 0
    Continuous = 1
    Num = 2

class FanPlace(IntEnum):
    Invalid = -1
    BlowThru = 0
    DrawThru = 1
    Num = 2

fanPlaceNamesUC = ("BLOWTHROUGH", "DRAWTHROUGH")

BypassWhenWithinEconomizerLimits = 0
BypassWhenOAFlowGreaterThanMinimum = 1

class EconomizerStagingType(IntEnum):
    Invalid = -1
    EconomizerFirst = 0
    InterlockedWithMechanicalCooling = 1
    Num = 2

economizerStagingTypeNamesUC = (
    "ECONOMIZERFIRST",
    "INTERLOCKEDWITHMECHANICALCOOLING",
)

economizerStagingTypeNames = (
    "EconomizerFirst",
    "InterlockedWithMechanicalCooling",
)

class UnitarySysType(IntEnum):
    Invalid = -1
    Furnace_HeatOnly = 0
    Furnace_HeatCool = 1
    Unitary_HeatOnly = 2
    Unitary_HeatCool = 3
    Unitary_HeatPump_AirToAir = 4
    Unitary_HeatPump_WaterToAir = 5
    Unitary_AnyCoilType = 6
    Num = 7

unitarySysTypeNames: Tuple[str, ...] = ()
unitarySysTypeNamesUC: Tuple[str, ...] = ()

class CoilType(IntEnum):
    Invalid = -1
    CoolingDXSingleSpeed = 0
    HeatingDXSingleSpeed = 1
    CoolingDXTwoSpeed = 2
    CoolingDXHXAssisted = 3
    CoolingDXTwoStageWHumControl = 4
    WaterHeatingDXPumped = 5
    WaterHeatingDXWrapped = 6
    CoolingDXMultiSpeed = 7
    HeatingDXMultiSpeed = 8
    HeatingGasOrOtherFuel = 9
    HeatingGasMultiStage = 10
    HeatingElectric = 11
    HeatingElectricMultiStage = 12
    HeatingDesuperheater = 13
    CoolingWater = 14
    CoolingWaterDetailed = 15
    HeatingWater = 16
    HeatingSteam = 17
    CoolingWaterHXAssisted = 18
    CoolingWAHP = 19
    HeatingWAHP = 20
    CoolingWAHPSimple = 21
    HeatingWAHPSimple = 22
    CoolingVRF = 23
    HeatingVRF = 24
    UserDefined = 25
    CoolingDXPackagedThermalStorage = 26
    CoolingWAHPVariableSpeedEquationFit = 27
    HeatingWAHPVariableSpeedEquationFit = 28
    CoolingDXVariableSpeed = 29
    HeatingDXVariableSpeed = 30
    WaterHeatingAWHPVariableSpeed = 31
    CoolingVRFFluidTCtrl = 32
    HeatingVRFFluidTCtrl = 33
    CoolingDX = 34
    DXSubcoolReheat = 35
    CoolingDXCurveFit = 36
    Num = 37

coilTypeNames: Tuple[str, ...] = ()
coilTypeNamesUC: Tuple[str, ...] = ()
coilTypeIsHeating: Tuple[bool, ...] = ()
coilTypeIsCooling: Tuple[bool, ...] = ()
coilTypeIsHeatPump: Tuple[bool, ...] = ()

class CoilMode(IntEnum):
    Invalid = -1
    Normal = 0
    Enhanced = 1
    SubcoolReheat = 2
    Num = 3

class HeatReclaimType(IntEnum):
    Invalid = -1
    RefrigeratedCaseCompressorRack = 0
    RefrigeratedCaseCondenserAirCooled = 1
    RefrigeratedCaseCondenserEvaporativeCooled = 2
    RefrigeratedCaseCondenserWaterCooled = 3
    CoilCoolDXSingleSpeed = 4
    CoilCoolDXTwoSpeed = 5
    CoilCoolDXMultiSpeed = 6
    CoilCoolDXMultiMode = 7
    CoilCoolDXVariableSpeed = 8
    CoilCoolDX = 9
    CoilCoolWAHPEquationFit = 10
    CoilCoolWAHPVariableSpeedEquationFit = 11
    Num = 12

heatReclaimTypeNames = (
    "Refrigeration:CompressorRack",
    "Refrigeration:Condenser:AirCooled",
    "Refrigeration:Condenser:EvaporativeCooled",
    "Refrigeration:Condenser:WaterCooled",
    "Coil:Cooling:DX:SingleSpeed",
    "Coil:Cooling:DX:TwoSpeed",
    "Coil:Cooling:DX:MultiSpeed",
    "Coil:Cooling:DX:TwoStageWithHumidityControlMode",
    "Coil:Cooling:DX:VariableSpeed",
    "Coil:Cooling:DX",
    "Coil:Cooling:WaterToAirHeatPump:EquationFit",
    "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
)

heatReclaimTypeNamesUC = (
    "REFRIGERATION:COMPRESSORRACK",
    "REFRIGERATION:CONDENSER:AIRCOOLED",
    "REFRIGERATION:CONDENSER:EVAPORATIVECOOLED",
    "REFRIGERATION:CONDENSER:WATERCOOLED",
    "COIL:COOLING:DX:SINGLESPEED",
    "COIL:COOLING:DX:TWOSPEED",
    "COIL:COOLING:DX:MULTISPEED",
    "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE",
    "COIL:COOLING:DX:VARIABLESPEED",
    "COIL:COOLING:DX",
    "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT",
    "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT"
)

class WaterFlow(IntEnum):
    Invalid = -1
    Cycling = 0
    Constant = 1
    ConstantOnDemand = 2
    Num = 3

waterFlowNames: Tuple[str, ...] = ()
waterFlowNamesUC: Tuple[str, ...] = ()

CoilPerfDX_CoolBypassEmpirical = 100

MaxRatedVolFlowPerRatedTotCap1 = 0.00006041
MinRatedVolFlowPerRatedTotCap1 = 0.00004027
MaxHeatVolFlowPerRatedTotCap1 = 0.00008056
MaxCoolVolFlowPerRatedTotCap1 = 0.00006713
MinOperVolFlowPerRatedTotCap1 = 0.00002684

MaxRatedVolFlowPerRatedTotCap2 = 0.00003355
MinRatedVolFlowPerRatedTotCap2 = 0.00001677
MaxHeatVolFlowPerRatedTotCap2 = 0.00004026
MaxCoolVolFlowPerRatedTotCap2 = 0.00004026
MinOperVolFlowPerRatedTotCap2 = 0.00001342

MaxRatedVolFlowPerRatedTotCap = (MaxRatedVolFlowPerRatedTotCap1, MaxRatedVolFlowPerRatedTotCap2)
MinRatedVolFlowPerRatedTotCap = (MinRatedVolFlowPerRatedTotCap1, MinRatedVolFlowPerRatedTotCap2)
MaxHeatVolFlowPerRatedTotCap = (MaxHeatVolFlowPerRatedTotCap1, MaxHeatVolFlowPerRatedTotCap2)
MaxCoolVolFlowPerRatedTotCap = (MaxCoolVolFlowPerRatedTotCap1, MaxCoolVolFlowPerRatedTotCap2)
MinOperVolFlowPerRatedTotCap = (MinOperVolFlowPerRatedTotCap1, MinOperVolFlowPerRatedTotCap2)

class DXCoilType(IntEnum):
    Invalid = -1
    Regular = 0
    DOAS = 1
    Num = 2

class HXType(IntEnum):
    Invalid = -1
    AirToAir_FlatPlate = 0
    AirToAir_SensAndLatent = 1
    Desiccant_Balanced = 2
    Num = 3

hxTypeNames: Tuple[str, ...] = ()
hxTypeNamesUC: Tuple[str, ...] = ()

class MixerType(IntEnum):
    Invalid = -1
    InletSide = 0
    SupplySide = 1
    Num = 2

mixerTypeNames: Tuple[str, ...] = ()
mixerTypeNamesUC: Tuple[str, ...] = ()
mixerTypeLocNames: Tuple[str, ...] = ()
mixerTypeLocNamesUC: Tuple[str, ...] = ()

class OATType(IntEnum):
    Invalid = -1
    WetBulb = 0
    DryBulb = 1
    Num = 2

oatTypeNames: Tuple[str, ...] = ()
oatTypeNamesUC: Tuple[str, ...] = ()

OscillateMagnitude = 0.15

MaxSpeedLevels = 10

@dataclass
class ComponentSetPtData:
    EquipmentType: str = ""
    EquipmentName: str = ""
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    EquipDemand: float = 0.0
    DesignFlowRate: float = 0.0
    HeatOrCool: str = ""
    OpType: int = 0

class CompressorOp(IntEnum):
    Invalid = -1
    Off = 0
    On = 1
    Num = 2

fanTypeNames = (
    "Fan:ConstantVolume", "Fan:VariableVolume", "Fan:OnOff", "Fan:ZoneExhaust",
    "Fan:ComponentModel", "Fan:SystemModel"
)

fanTypeNamesUC = (
    "FAN:CONSTANTVOLUME", "FAN:VARIABLEVOLUME", "FAN:ONOFF", "FAN:ZONEEXHAUST",
    "FAN:COMPONENTMODEL", "FAN:SYSTEMMODEL"
)

unitarySysTypeNames = (
    "AirLoopHVAC:Unitary:Furnace:HeatOnly",
    "AirLoopHVAC:Unitary:Furnace:HeatCool",
    "AirLoopHVAC:UnitaryHeatOnly",
    "AirLoopHVAC:UnitaryHeatCool",
    "AirLoopHVAC:UnitaryHeatPump:AirToAir",
    "AirLoopHVAC:UnitaryHeatPump:WaterToAir",
    "AirLoopHVAC:UnitarySystem"
)

unitarySysTypeNamesUC = (
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY",
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL",
    "AIRLOOPHVAC:UNITARYHEATONLY",
    "AIRLOOPHVAC:UNITARYHEATCOOL",
    "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR",
    "AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR",
    "AIRLOOPHVAC:UNITARYSYSTEM"
)

waterFlowNames = ("Cycling", "Constant", "ConstantOnDemand")

waterFlowNamesUC = ("CYCLING", "CONSTANT", "CONSTANTONDEMAND")

oatTypeNames = ("WetBulbTemperature", "DryBulbTemperature")
oatTypeNamesUC = ("WETBULBTEMPERATURE", "DRYBULBTEMPERATURE")

mixerTypeLocNames = ("InletSide", "SupplySide")
mixerTypeLocNamesUC = ("INLETSIDE", "SUPPLYSIDE")

coilTypeNames = (
    "Coil:Cooling:DX:SingleSpeed",
    "Coil:Heating:DX:SingleSpeed",
    "Coil:Cooling:DX:TwoSpeed",
    "CoilSystem:Cooling:DX:HeatExchangerAssisted",
    "Coil:Cooling:DX:TwoStageWithHumidityControlMode",
    "Coil:WaterHeating:AirToWaterHeatPump:Pumped",
    "Coil:WaterHeating:AirToWaterHeatPump:Wrapped",
    "Coil:Cooling:DX:MultiSpeed",
    "Coil:Heating:DX:MultiSpeed",
    "Coil:Heating:Fuel",
    "Coil:Heating:Gas:MultiStage",
    "Coil:Heating:Electric",
    "Coil:Heating:Electric:MultiStage",
    "Coil:Heating:Desuperheater",
    "Coil:Cooling:Water",
    "Coil:Cooling:Water:DetailedGeometry",
    "Coil:Heating:Water",
    "Coil:Heating:Steam",
    "CoilSystem:Cooling:Water:HeatExchangerAssisted",
    "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation",
    "Coil:Heating:WaterToAirHeatPump:ParameterEstimation",
    "Coil:Cooling:WaterToAirHeatPump:EquationFit",
    "Coil:Heating:WaterToAirHeatPump:EquationFit",
    "Coil:Cooling:DX:VariableRefrigerantFlow",
    "Coil:Heating:DX:VariableRefrigerantFlow",
    "Coil:UserDefined",
    "Coil:Cooling:DX:SingleSpeed:ThermalStorage",
    "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit",
    "Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit",
    "Coil:Cooling:DX:VariableSpeed",
    "Coil:Heating:DX:VariableSpeed",
    "Coil:WaterHeating:AirToWaterHeatPump:VariableSpeed",
    "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl",
    "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl",
    "Coil:Cooling:DX",
    "Coil:Cooling:DX:SubcoolReheat",
    "Coil:Cooling:DX:CurveFit:Speed"
)

coilTypeNamesUC = (
    "COIL:COOLING:DX:SINGLESPEED",
    "COIL:HEATING:DX:SINGLESPEED",
    "COIL:COOLING:DX:TWOSPEED",
    "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED",
    "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED",
    "COIL:COOLING:DX:MULTISPEED",
    "COIL:HEATING:DX:MULTISPEED",
    "COIL:HEATING:FUEL",
    "COIL:HEATING:GAS:MULTISTAGE",
    "COIL:HEATING:ELECTRIC",
    "COIL:HEATING:ELECTRIC:MULTISTAGE",
    "COIL:HEATING:DESUPERHEATER",
    "COIL:COOLING:WATER",
    "COIL:COOLING:WATER:DETAILEDGEOMETRY",
    "COIL:HEATING:WATER",
    "COIL:HEATING:STEAM",
    "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED",
    "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION",
    "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION",
    "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT",
    "COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT",
    "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW",
    "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW",
    "COIL:USERDEFINED",
    "COIL:COOLING:DX:SINGLESPEED:THERMALSTORAGE",
    "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT",
    "COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT",
    "COIL:COOLING:DX:VARIABLESPEED",
    "COIL:HEATING:DX:VARIABLESPEED",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED",
    "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL",
    "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL",
    "COIL:COOLING:DX",
    "COIL:COOLING:DX:SUBCOOLREHEAT",
    "COIL:COOLING:DX:CURVEFIT:SPEED"
)

coilTypeIsCooling = (
    True, False, True, True, True, False, False, True, False, False, False, False, False, False,
    True, True, False, False, True, True, False, True, False, True, False, False, True, True, False,
    True, False, False, True, False, True, True, True
)

coilTypeIsHeating = (
    False, True, False, False, False, True, True, False, True, True, True, True, True, True,
    False, False, True, True, False, False, True, False, True, False, True, False, False, False,
    True, False, True, False, True, False, False, False
)

coilTypeIsHeatPump = (
    False, True, False, False, False, False, False, False, True, False, False, False, False, False,
    False, False, False, False, False, False, True, False, True, False, False, False, False, False,
    True, False, True, False, False, False, False, False
)

hxTypeNames = (
    "HeatExchanger:AirToAir:FlatPlate",
    "HeatExchanger:AirToAir:SensibleAndLatent",
    "HeatExchanger:Desiccant:BalancedFlow"
)

hxTypeNamesUC = (
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT",
    "HEATEXCHANGER:DESICCANT:BALANCEDFLOW"
)

mixerTypeNames = (
    "AirTerminal:SingleDuct:InletSideMixer",
    "AirTerminal:SingleDuct:SupplySideMixer"
)

mixerTypeNamesUC = (
    "AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER",
    "AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER"
)


class HVACGlobalsData:
    def __init__(self):
        self.CompSetPtEquip: List[ComponentSetPtData] = []
        self.MSHPMassFlowRateLow = 0.0
        self.MSHPMassFlowRateHigh = 0.0
        self.MSHPWasteHeat = 0.0
        self.PreviousTimeStep = 0.0
        self.ShortenTimeStepSysRoomAir = False
        self.MSUSEconoSpeedNum = 0
        self.deviationFromSetPtThresholdHtg = -0.2
        self.deviationFromSetPtThresholdClg = 0.2
        self.SimAirLoopsFlag = False
        self.SimElecCircuitsFlag = False
        self.SimPlantLoopsFlag = False
        self.SimZoneEquipmentFlag = False
        self.SimNonZoneEquipmentFlag = False
        self.ZoneMassBalanceHVACReSim = False
        self.MinAirLoopIterationsAfterFirst = 1
        self.DXCT = DXCoilType.Regular
        self.FirstTimeStepSysFlag = False
        self.TimeStepSys = 0.0
        self.TimeStepSysSec = 0.0
        self.SysTimeElapsed = 0.0
        self.FracTimeStepZone = 0.0
        self.ShortenTimeStepSys = False
        self.NumOfSysTimeSteps = 1
        self.NumOfSysTimeStepsLastZoneTimeStep = 1
        self.LimitNumSysSteps = 0
        self.UseZoneTimeStepHistory = True
        self.NumPlantLoops = 0
        self.NumCondLoops = 0
        self.NumElecCircuits = 0
        self.NumGasMeters = 0
        self.NumPrimaryAirSys = 0
        self.OnOffFanPartLoadFraction = 1.0
        self.DXCoilTotalCapacity = 0.0
        self.DXElecCoolingPower = 0.0
        self.DXElecHeatingPower = 0.0
        self.ElecHeatingCoilPower = 0.0
        self.SuppHeatingCoilPower = 0.0
        self.AirToAirHXElecPower = 0.0
        self.DefrostElecPower = 0.0
        self.UnbalExhMassFlow = 0.0
        self.BalancedExhMassFlow = 0.0
        self.PlenumInducedMassFlow = 0.0
        self.TurnFansOn = False
        self.TurnFansOff = False
        self.SetPointErrorFlag = False
        self.DoSetPointTest = False
        self.NightVentOn = False
        self.NumTempContComps = 0
        self.HPWHInletDBTemp = 0.0
        self.HPWHInletWBTemp = 0.0
        self.HPWHCrankcaseDBTemp = 0.0
        self.AirLoopInit = False
        self.AirLoopsSimOnce = False
        self.GetAirPathDataDone = False
        self.StandardRatingsMyOneTimeFlag = True
        self.StandardRatingsMyCoolOneTimeFlag = True
        self.StandardRatingsMyCoolOneTimeFlag2 = True
        self.StandardRatingsMyCoolOneTimeFlag3 = True
        self.StandardRatingsMyHeatOneTimeFlag = True
        self.StandardRatingsMyHeatOneTimeFlag2 = True

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.__init__()
