from collections import InlineArray
from math import min as math_min

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData state (passed as parameter)
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
@export
struct FouledCoil:
    alias Invalid = -1
    alias UARated = 0
    alias FoulingFactor = 1
    alias Num = 2


# Enum: FaultType
@export
struct FaultType:
    alias Invalid = -1
    alias TemperatureSensorOffset_OutdoorAir = 0
    alias HumiditySensorOffset_OutdoorAir = 1
    alias EnthalpySensorOffset_OutdoorAir = 2
    alias TemperatureSensorOffset_ReturnAir = 3
    alias EnthalpySensorOffset_ReturnAir = 4
    alias Fouling_Coil = 5
    alias ThermostatOffset = 6
    alias HumidistatOffset = 7
    alias Fouling_AirFilter = 8
    alias TemperatureSensorOffset_ChillerSupplyWater = 9
    alias TemperatureSensorOffset_CondenserSupplyWater = 10
    alias Fouling_Tower = 11
    alias TemperatureSensorOffset_CoilSupplyAir = 12
    alias Fouling_Boiler = 13
    alias Fouling_Chiller = 14
    alias Fouling_EvapCooler = 15
    alias Num = 16


alias iController_AirEconomizer = 1001


# Enum: ChillerType
@export
struct ChillerType:
    alias Invalid = -1
    alias ChillerElectric = 0
    alias ChillerElectricEIR = 1
    alias ChillerElectricReformulatedEIR = 2
    alias ChillerConstantCOP = 3
    alias ChillerEngineDriven = 4
    alias ChillerCombustionTurbine = 5
    alias ChillerAbsorption = 6
    alias ChillerAbsorptionIndirect = 7
    alias Num = 8


# Enum: CoilType
@export
struct CoilType:
    alias Invalid = -1
    alias CoilHeatingElectric = 0
    alias CoilHeatingFuel = 1
    alias CoilHeatingDesuperheater = 2
    alias CoilHeatingSteam = 3
    alias CoilHeatingWater = 4
    alias CoilCoolingWater = 5
    alias CoilCoolingWaterDetailedgeometry = 6
    alias CoilSystemCoolingDX = 7
    alias CoilSystemHeatingDX = 8
    alias AirLoopHVACUnitarySystem = 9
    alias Num = 10


@always_inline
fn get_cfaults_string(i: Int) -> StringLiteral:
    if i == 0:
        return "FaultModel:TemperatureSensorOffset:OutdoorAir"
    elif i == 1:
        return "FaultModel:HumiditySensorOffset:OutdoorAir"
    elif i == 2:
        return "FaultModel:EnthalpySensorOffset:OutdoorAir"
    elif i == 3:
        return "FaultModel:TemperatureSensorOffset:ReturnAir"
    elif i == 4:
        return "FaultModel:EnthalpySensorOffset:ReturnAir"
    elif i == 5:
        return "FaultModel:Fouling:Coil"
    elif i == 6:
        return "FaultModel:ThermostatOffset"
    elif i == 7:
        return "FaultModel:HumidistatOffset"
    elif i == 8:
        return "FaultModel:Fouling:AirFilter"
    elif i == 9:
        return "FaultModel:TemperatureSensorOffset:ChillerSupplyWater"
    elif i == 10:
        return "FaultModel:TemperatureSensorOffset:CondenserSupplyWater"
    elif i == 11:
        return "FaultModel:Fouling:CoolingTower"
    elif i == 12:
        return "FaultModel:TemperatureSensorOffset:CoilSupplyAir"
    elif i == 13:
        return "FaultModel:Fouling:Boiler"
    elif i == 14:
        return "FaultModel:Fouling:Chiller"
    else:
        return "FaultModel:Fouling:EvaporativeCooler"


@always_inline
fn get_chiller_type_name_uc(i: Int) -> StringLiteral:
    if i == 0:
        return "CHILLER:ELECTRIC"
    elif i == 1:
        return "CHILLER:ELECTRIC:EIR"
    elif i == 2:
        return "CHILLER:ELECTRIC:REFORMULATEDEIR"
    elif i == 3:
        return "CHILLER:CONSTANTCOP"
    elif i == 4:
        return "CHILLER:ENGINEDRIVEN"
    elif i == 5:
        return "CHILLER:COMBUSTIONTURBINE"
    elif i == 6:
        return "CHILLER:ABSORPTION"
    else:
        return "CHILLER:ABSORPTION:INDIRECT"


@always_inline
fn get_coil_type_name_uc(i: Int) -> StringLiteral:
    if i == 0:
        return "COIL:HEATING:ELECTRIC"
    elif i == 1:
        return "COIL:HEATING:FUEL"
    elif i == 2:
        return "COIL:HEATING:DESUPERHEATER"
    elif i == 3:
        return "COIL:HEATING:STEAM"
    elif i == 4:
        return "COIL:HEATING:WATER"
    elif i == 5:
        return "COIL:COOLING:WATER"
    elif i == 6:
        return "COIL:COOLING:WATER:DETAILEDGEOMETRY"
    elif i == 7:
        return "COILSYSTEM:COOLING:DX"
    elif i == 8:
        return "COILSYSTEM:HEATING:DX"
    else:
        return "AIRLOOPHVAC:UNITARYSYSTEM"


@always_inline
fn get_fouled_coil_name_uc(i: Int) -> StringLiteral:
    if i == 0:
        return "FOULEDUARATED"
    else:
        return "FOULINGFACTOR"


struct Schedule:
    """Placeholder for schedule interface"""
    pass


struct FaultProperties:
    """Base class for operational faults"""
    var Name: String
    var type: Int
    var availSched: OpaquePointer
    var severitySched: OpaquePointer
    var Offset: Float64
    var Status: Bool

    fn __init__(inout self):
        self.Name = String()
        self.type = FaultType.Invalid
        self.availSched = OpaquePointer()
        self.severitySched = OpaquePointer()
        self.Offset = 0.0
        self.Status = False

    fn CalFaultOffsetAct(inout self, state: OpaquePointer) -> Float64:
        var FaultFac: Float64 = 0.0
        if self.availSched != OpaquePointer() and self._getCurrentVal(self.availSched) > 0.0:
            if self.severitySched != OpaquePointer():
                FaultFac = self._getCurrentVal(self.severitySched)
            else:
                FaultFac = 1.0
        return FaultFac * self.Offset

    @always_inline
    fn _getCurrentVal(self, sched: OpaquePointer) -> Float64:
        return 0.0


struct FaultPropertiesEconomizer(FaultProperties):
    """Class for fault models related with economizer"""
    var ControllerTypeEnum: Int32
    var ControllerID: Int32
    var ControllerType: String
    var ControllerName: String

    fn __init__(inout self):
        super().__init__()
        self.ControllerTypeEnum = 0
        self.ControllerID = 0
        self.ControllerType = String()
        self.ControllerName = String()


struct FaultPropertiesThermostat(FaultProperties):
    """Class for FaultModel:ThermostatOffset"""
    var FaultyThermostatName: String

    fn __init__(inout self):
        super().__init__()
        self.FaultyThermostatName = String()


struct FaultPropertiesHumidistat(FaultProperties):
    """Class for FaultModel:HumidistatOffset"""
    var FaultyThermostatName: String
    var FaultyHumidistatName: String
    var FaultyHumidistatType: String

    fn __init__(inout self):
        super().__init__()
        self.FaultyThermostatName = String()
        self.FaultyHumidistatName = String()
        self.FaultyHumidistatType = String()


struct FaultPropertiesFoulingCoil(FaultProperties):
    """Class for FaultModel:Fouling:Coil"""
    var FouledCoilName: String
    var FouledCoilType: Int
    var FouledCoilNum: Int32
    var FoulingInputMethod: Int
    var UAFouled: Float64
    var Rfw: Float64
    var Rfa: Float64
    var Aout: Float64
    var Aratio: Float64

    fn __init__(inout self):
        super().__init__()
        self.FouledCoilName = String()
        self.FouledCoilType = -1
        self.FouledCoilNum = 0
        self.FoulingInputMethod = FouledCoil.Invalid
        self.UAFouled = 0.0
        self.Rfw = 0.0
        self.Rfa = 0.0
        self.Aout = 0.0
        self.Aratio = 0.0

    fn FaultFraction(inout self, state: OpaquePointer) -> Float64:
        if self.availSched != OpaquePointer() and self._getCurrentVal(self.availSched) > 0.0:
            if self.severitySched != OpaquePointer():
                return self._getCurrentVal(self.severitySched)
            else:
                return 1.0
        return 0.0


struct FaultPropertiesAirFilter(FaultProperties):
    """Class for FaultModel:Fouling:AirFilter"""
    var fanName: String
    var fanNum: Int32
    var fanType: Int
    var fanCurveNum: Int32
    var pressFracSched: OpaquePointer
    var fanPressInc: Float64
    var fanFlowDec: Float64

    fn __init__(inout self):
        super().__init__()
        self.fanName = String()
        self.fanNum = 0
        self.fanType = -1
        self.fanCurveNum = 0
        self.pressFracSched = OpaquePointer()
        self.fanPressInc = 0.0
        self.fanFlowDec = 0.0

    fn CheckFaultyAirFilterFanCurve(inout self, state: OpaquePointer) -> Bool:
        return True


struct FaultPropertiesCoilSAT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:CoilSupplyAir"""
    var CoilType: String
    var CoilName: String
    var WaterCoilControllerName: String

    fn __init__(inout self):
        super().__init__()
        self.CoilType = String()
        self.CoilName = String()
        self.WaterCoilControllerName = String()


struct FaultPropertiesChillerSWT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:ChillerSupplyWater"""
    var ChillerType: String
    var ChillerName: String

    fn __init__(inout self):
        super().__init__()
        self.ChillerType = String()
        self.ChillerName = String()

    fn CalFaultChillerSWT(
        inout self,
        FlagVariableFlow: Bool,
        FaultyChillerSWTOffset: Float64,
        Cp: Float64,
        EvapInletTemp: Float64,
        inout EvapOutletTemp: Float64,
        inout EvapMassFlowRate: Float64,
        inout QEvaporator: Float64,
    ):
        var EvapOutletTemp_ff: Float64 = EvapOutletTemp
        var EvapMassFlowRate_ff: Float64 = EvapMassFlowRate
        var QEvaporator_ff: Float64 = QEvaporator

        var EvapOutletTemp_f: Float64
        var EvapMassFlowRate_f: Float64
        var QEvaporator_f: Float64

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

        EvapOutletTemp = EvapOutletTemp_f
        EvapMassFlowRate = EvapMassFlowRate_f
        QEvaporator = QEvaporator_f


struct FaultPropertiesCondenserSWT(FaultProperties):
    """Class for FaultModel:TemperatureSensorOffset:CondenserSupplyWater"""
    var TowerType: String
    var TowerName: String

    fn __init__(inout self):
        super().__init__()
        self.TowerType = String()
        self.TowerName = String()


struct FaultPropertiesTowerFouling(FaultProperties):
    """Class for FaultModel:Fouling:CoolingTower"""
    var TowerType: String
    var TowerName: String
    var UAReductionFactor: Float64

    fn __init__(inout self):
        super().__init__()
        self.TowerType = String()
        self.TowerName = String()
        self.UAReductionFactor = 1.0

    fn CalFaultyTowerFoulingFactor(inout self, state: OpaquePointer) -> Float64:
        var FaultFac: Float64 = 0.0
        if self.availSched != OpaquePointer() and self._getCurrentVal(self.availSched) > 0.0:
            if self.severitySched != OpaquePointer():
                FaultFac = self._getCurrentVal(self.severitySched)
            else:
                FaultFac = 1.0

        var UAReductionFactorAct: Float64 = 1.0
        if FaultFac > 0.0:
            UAReductionFactorAct = math_min(self.UAReductionFactor / FaultFac, 1.0)
        return UAReductionFactorAct


struct FaultPropertiesFouling(FaultProperties):
    """Class for FaultModel:Fouling"""
    var FoulingFactor: Float64

    fn __init__(inout self):
        super().__init__()
        self.FoulingFactor = 1.0

    fn CalFoulingFactor(inout self, state: OpaquePointer) -> Float64:
        var FaultFac: Float64 = 0.0
        if self.availSched != OpaquePointer() and self._getCurrentVal(self.availSched) > 0.0:
            if self.severitySched != OpaquePointer():
                FaultFac = self._getCurrentVal(self.severitySched)
            else:
                FaultFac = 1.0

        var FoulingFactor: Float64 = 1.0
        if FaultFac > 0.0:
            FoulingFactor = math_min(self.FoulingFactor / FaultFac, 1.0)
        return FoulingFactor


struct FaultPropertiesBoilerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:Boiler"""
    var BoilerType: String
    var BoilerName: String

    fn __init__(inout self):
        super().__init__()
        self.BoilerType = String()
        self.BoilerName = String()


struct FaultPropertiesChillerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:Chiller"""
    var ChillerType: String
    var ChillerName: String

    fn __init__(inout self):
        super().__init__()
        self.ChillerType = String()
        self.ChillerName = String()


struct FaultPropertiesEvapCoolerFouling(FaultPropertiesFouling):
    """Class for FaultModel:Fouling:EvaporativeCooler"""
    var EvapCoolerType: String
    var EvapCoolerName: String

    fn __init__(inout self):
        super().__init__()
        self.EvapCoolerType = String()
        self.EvapCoolerName = String()


fn CheckAndReadFaults(state: OpaquePointer) -> None:
    """Check and read fault input"""
    pass


fn SetFaultyCoilSATSensor(
    state: OpaquePointer, CompType: StringRef, CompName: StringRef, inout FaultyCoilSATFlag: Bool, inout FaultyCoilSATIndex: Int32
) -> None:
    """Set faulty coil SAT sensor flags"""
    FaultyCoilSATFlag = False
    FaultyCoilSATIndex = 0
    pass
