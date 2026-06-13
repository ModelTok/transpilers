from Data.BaseData import BaseGlobalStruct, EnergyPlusData
from DataGlobals import *
from EnergyPlus import *
@value
struct CtrlVarType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Temp = Self(0)
    alias MaxTemp = Self(1)
    alias MinTemp = Self(2)
    alias HumRat = Self(3)
    alias MaxHumRat = Self(4)
    alias MinHumRat = Self(5)
    alias MassFlowRate = Self(6)
    alias MaxMassFlowRate = Self(7)
    alias MinMassFlowRate = Self(8)
    alias Num = Self(9)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias SmallHumRatDiff: Float64 = 1.0E-7
alias SmallTempDiff: Float64 = 1.0E-5
alias SmallMassFlow: Float64 = 0.001
alias VerySmallMassFlow: Float64 = 1.0E-30
alias SmallLoad: Float64 = 1.0
alias TempControlTol: Float64 = 0.1 // temperature control tolerance for packaged equip. [deg C]
alias SmallAirVolFlow: Float64 = 0.001
alias SmallWaterVolFlow: Float64 = 1.0E-9
alias BlankNumeric: Float64 = -99999.0      // indicates numeric input field was blank
alias RetTempMax: Float64 = 60.0            // maximum return air temperature [deg C]
alias RetTempMin: Float64 = -30.0           // minimum return air temperature [deg C]
alias DesCoilHWInletTempMin: Float64 = 46.0 // minimum heating water coil water inlet temp for UA sizing only. [deg C]
alias NumOfSizingTypes: Int32 = 35 // request sizing for cooling air flow rate
alias CoolingAirflowSizing: Int32 = 1                  // request sizing for cooling air flow rate
alias CoolingWaterDesWaterInletTempSizing: Int32 = 6   // request sizing for cooling water coil inlet water temp
alias HeatingAirflowSizing: Int32 = 14                 // request sizing for heating air flow rate
alias SystemAirflowSizing: Int32 = 16                  // request sizing for system air flow rate
alias CoolingCapacitySizing: Int32 = 17                // request sizing for cooling capacity
alias HeatingCapacitySizing: Int32 = 18                // request sizing for heating capacity
alias SystemCapacitySizing: Int32 = 21                 // request sizing for system capacity
alias AutoCalculateSizing: Int32 = 25 // identifies an autocalulate input
@value
struct SetptType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Uncontrolled = Self(0)
    alias SingleHeat = Self(1)
    alias SingleCool = Self(2)
    alias SingleHeatCool = Self(3)
    alias DualHeatCool = Self(4)
    alias Num = Self(5)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias controlledSetptTypes = StaticTuple[SetptType, 4](
    SetptType.SingleHeat, SetptType.SingleCool, SetptType.SingleHeatCool, SetptType.DualHeatCool)
alias setptTypeNames = StaticTuple[StringLiteral, 5](
    "Uncontrolled", "SingleHeating", "SingleCooling", "SingleHeatCool", "DualSetPointWithDeadBand")
@value
struct AirDuctType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Main = Self(0)
    alias Cooling = Self(1)
    alias Heating = Self(2)
    alias Other = Self(3)
    alias RAB = Self(4)
    alias Num = Self(5)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias airDuctTypeNames = StaticTuple[StringLiteral, 5](
    "Main", "Cooling", "Heating", "Other", "Return Air Bypass")
alias Cooling: Int32 = 2
alias Heating: Int32 = 3
@value
struct FanType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Constant = Self(0)
    alias VAV = Self(1)
    alias OnOff = Self(2)
    alias Exhaust = Self(3)
    alias ComponentModel = Self(4)
    alias SystemModel = Self(5)
    alias Num = Self(6)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias fanTypeNames = StaticTuple[StringLiteral, 6](
    "Fan:ConstantVolume", "Fan:VariableVolume", "Fan:OnOff", "Fan:ZoneExhaust", "Fan:ComponentModel", "Fan:SystemModel")
alias fanTypeNamesUC = StaticTuple[StringLiteral, 6](
    "FAN:CONSTANTVOLUME", "FAN:VARIABLEVOLUME", "FAN:ONOFF", "FAN:ZONEEXHAUST", "FAN:COMPONENTMODEL", "FAN:SYSTEMMODEL")
@value
struct FanOp:
    var value: Int32
    alias Invalid = Self(-1)
    alias Cycling = Self(0)
    alias Continuous = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
@value
struct FanPlace:
    var value: Int32
    alias Invalid = Self(-1)
    alias BlowThru = Self(0)
    alias DrawThru = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias fanPlaceNamesUC = StaticTuple[StringLiteral, 2]("BLOWTHROUGH", "DRAWTHROUGH")
alias BypassWhenWithinEconomizerLimits: Int32 = 0   // heat recovery controlled by economizer limits
alias BypassWhenOAFlowGreaterThanMinimum: Int32 = 1 // heat recovery ON at minimum OA in economizer mode
@value
struct EconomizerStagingType:
    var value: Int32
    alias Invalid = Self(-1)
    alias EconomizerFirst = Self(0)
    alias InterlockedWithMechanicalCooling = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias economizerStagingTypeNamesUC = StaticTuple[StringLiteral, 2](
    "ECONOMIZERFIRST",
    "INTERLOCKEDWITHMECHANICALCOOLING",
)
alias economizerStagingTypeNames = StaticTuple[StringLiteral, 2](
    "EconomizerFirst",
    "InterlockedWithMechanicalCooling",
)
@value
struct UnitarySysType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Furnace_HeatOnly = Self(0)
    alias Furnace_HeatCool = Self(1)
    alias Unitary_HeatOnly = Self(2)
    alias Unitary_HeatCool = Self(3)
    alias Unitary_HeatPump_AirToAir = Self(4)
    alias Unitary_HeatPump_WaterToAir = Self(5)
    alias Unitary_AnyCoilType = Self(6)
    alias Num = Self(7)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias unitarySysTypeNames = StaticTuple[StringLiteral, 7](
    "AirLoopHVAC:Unitary:Furnace:HeatOnly",
    "AirLoopHVAC:Unitary:Furnace:HeatCool",
    "AirLoopHVAC:UnitaryHeatOnly",
    "AirLoopHVAC:UnitaryHeatCool",
    "AirLoopHVAC:UnitaryHeatPump:AirToAir",
    "AirLoopHVAC:UnitaryHeatPump:WaterToAir",
    "AirLoopHVAC:UnitarySystem")
alias unitarySysTypeNamesUC = StaticTuple[StringLiteral, 7](
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY",
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL",
    "AIRLOOPHVAC:UNITARYHEATONLY",
    "AIRLOOPHVAC:UNITARYHEATCOOL",
    "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR",
    "AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR",
    "AIRLOOPHVAC:UNITARYSYSTEM")
@value
struct CoilType:
    var value: Int32
    alias Invalid = Self(-1)
    alias CoolingDXSingleSpeed = Self(0)
    alias HeatingDXSingleSpeed = Self(1)
    alias CoolingDXTwoSpeed = Self(2)
    alias CoolingDXHXAssisted = Self(3)
    alias CoolingDXTwoStageWHumControl = Self(4)
    alias WaterHeatingDXPumped = Self(5)
    alias WaterHeatingDXWrapped = Self(6)
    alias CoolingDXMultiSpeed = Self(7)
    alias HeatingDXMultiSpeed = Self(8)
    alias HeatingGasOrOtherFuel = Self(9)
    alias HeatingGasMultiStage = Self(10)
    alias HeatingElectric = Self(11)
    alias HeatingElectricMultiStage = Self(12)
    alias HeatingDesuperheater = Self(13)
    alias CoolingWater = Self(14)
    alias CoolingWaterDetailed = Self(15)
    alias HeatingWater = Self(16)
    alias HeatingSteam = Self(17)
    alias CoolingWaterHXAssisted = Self(18)
    alias CoolingWAHP = Self(19)
    alias HeatingWAHP = Self(20)
    alias CoolingWAHPSimple = Self(21)
    alias HeatingWAHPSimple = Self(22)
    alias CoolingVRF = Self(23)
    alias HeatingVRF = Self(24)
    alias UserDefined = Self(25)
    alias CoolingDXPackagedThermalStorage = Self(26)
    alias CoolingWAHPVariableSpeedEquationFit = Self(27)
    alias HeatingWAHPVariableSpeedEquationFit = Self(28)
    alias CoolingDXVariableSpeed = Self(29)
    alias HeatingDXVariableSpeed = Self(30)
    alias WaterHeatingAWHPVariableSpeed = Self(31)
    alias CoolingVRFFluidTCtrl = Self(32)
    alias HeatingVRFFluidTCtrl = Self(33)
    alias CoolingDX = Self(34)
    alias DXSubcoolReheat = Self(35)
    alias CoolingDXCurveFit = Self(36)
    alias Num = Self(37)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias coilTypeNames = StaticTuple[StringLiteral, 37](
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
    "Coil:Cooling:DX:CurveFit:Speed")
alias coilTypeNamesUC = StaticTuple[StringLiteral, 37](
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
    "COIL:COOLING:DX:CURVEFIT:SPEED")
alias coilTypeIsCooling = StaticTuple[Bool, 37](
    True,  
    False, 
    True,  
    True,  
    True,  
    False, 
    False, 
    True,  
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    True,  
    True,  
    False, 
    False, 
    True,  
    True,  
    False, 
    True,  
    False, 
    True,  
    False, 
    False, 
    True,  
    True,  
    False, 
    True,  
    False, 
    False, 
    True,  
    False, 
    True,  
    True,  
    True)
alias coilTypeIsHeating = StaticTuple[Bool, 37](
    False, 
    True,  
    False, 
    False, 
    False, 
    True,  
    True,  
    False, 
    True,  
    True,  
    True,  
    True,  
    True,  
    True,  
    False, 
    False, 
    True,  
    True,  
    False, 
    False, 
    True,  
    False, 
    True,  
    False, 
    True,  
    False, 
    False, 
    False, 
    True,  
    False, 
    True,  
    True,  
    False, 
    True,  
    False, 
    False, 
    False)
alias coilTypeIsHeatPump = StaticTuple[Bool, 37](
    False, 
    True,  
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    True,  
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    False, 
    True,  
    False, 
    True,  
    False, 
    False, 
    False, 
    False, 
    False, 
    True,  
    False, 
    True,  
    False, 
    False, 
    False, 
    False, 
    False, 
    False)
@value
struct CoilMode:
    var value: Int32
    alias Invalid = Self(-1)
    alias Normal = Self(0)
    alias Enhanced = Self(1)
    alias SubcoolReheat = Self(2)
    alias Num = Self(3)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
@value
struct HeatReclaimType:
    var value: Int32
    alias Invalid = Self(-1)
    alias RefrigeratedCaseCompressorRack = Self(0)
    alias RefrigeratedCaseCondenserAirCooled = Self(1)
    alias RefrigeratedCaseCondenserEvaporativeCooled = Self(2)
    alias RefrigeratedCaseCondenserWaterCooled = Self(3)
    alias CoilCoolDXSingleSpeed = Self(4)
    alias CoilCoolDXTwoSpeed = Self(5)
    alias CoilCoolDXMultiSpeed = Self(6)
    alias CoilCoolDXMultiMode = Self(7)
    alias CoilCoolDXVariableSpeed = Self(8)
    alias CoilCoolDX = Self(9)
    alias CoilCoolWAHPEquationFit = Self(10)
    alias CoilCoolWAHPVariableSpeedEquationFit = Self(11)
    alias Num = Self(12)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias heatReclaimTypeNames = StaticTuple[StringLiteral, 12](
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
    "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit")
alias heatReclaimTypeNamesUC = StaticTuple[StringLiteral, 12](
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
    "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT")
@value
struct WaterFlow:
    var value: Int32
    alias Invalid = Self(-1)
    alias Cycling = Self(0)
    alias Constant = Self(1)
    alias ConstantOnDemand = Self(2)
    alias Num = Self(3)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias waterFlowNames = StaticTuple[StringLiteral, 3]("Cycling", "Constant", "ConstantOnDemand")
alias waterFlowNamesUC = StaticTuple[StringLiteral, 3]("CYCLING", "CONSTANT", "CONSTANTONDEMAND")
alias CoilPerfDX_CoolBypassEmpirical: Int32 = 100
alias MaxRatedVolFlowPerRatedTotCap1: Float64 = 0.00006041 // m3/s per watt = 450 cfm/ton
alias MinRatedVolFlowPerRatedTotCap1: Float64 = 0.00004027 // m3/s per watt = 300 cfm/ton
alias MaxHeatVolFlowPerRatedTotCap1: Float64 = 0.00008056  // m3/s per watt = 600 cfm/ton
alias MaxCoolVolFlowPerRatedTotCap1: Float64 = 0.00006713  // m3/s per watt = 500 cfm/ton
alias MinOperVolFlowPerRatedTotCap1: Float64 = 0.00002684  // m3/s per watt = 200 cfm/ton
alias MaxRatedVolFlowPerRatedTotCap2: Float64 = 0.00003355 // m3/s per watt = 250 cfm/ton
alias MinRatedVolFlowPerRatedTotCap2: Float64 = 0.00001677 // m3/s per watt = 125 cfm/ton
alias MaxHeatVolFlowPerRatedTotCap2: Float64 = 0.00004026  // m3/s per watt = 300 cfm/ton
alias MaxCoolVolFlowPerRatedTotCap2: Float64 = 0.00004026  // m3/s per watt = 300 cfm/ton
alias MinOperVolFlowPerRatedTotCap2: Float64 = 0.00001342  // m3/s per watt = 100 cfm/ton
alias MaxRatedVolFlowPerRatedTotCap = StaticTuple[Float64, 2](MaxRatedVolFlowPerRatedTotCap1, MaxRatedVolFlowPerRatedTotCap2)
alias MinRatedVolFlowPerRatedTotCap = StaticTuple[Float64, 2](MinRatedVolFlowPerRatedTotCap1, MinRatedVolFlowPerRatedTotCap2)
alias MaxHeatVolFlowPerRatedTotCap = StaticTuple[Float64, 2](MaxHeatVolFlowPerRatedTotCap1, MaxHeatVolFlowPerRatedTotCap2)
alias MaxCoolVolFlowPerRatedTotCap = StaticTuple[Float64, 2](MaxCoolVolFlowPerRatedTotCap1, MaxCoolVolFlowPerRatedTotCap2)
alias MinOperVolFlowPerRatedTotCap = StaticTuple[Float64, 2](MinOperVolFlowPerRatedTotCap1, MinOperVolFlowPerRatedTotCap2)
@value
struct DXCoilType:
    var value: Int32
    alias Invalid = Self(-1)
    alias Regular = Self(0)
    alias DOAS = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
@value
struct HXType:
    var value: Int32
    alias Invalid = Self(-1)
    alias AirToAir_FlatPlate = Self(0)
    alias AirToAir_SensAndLatent = Self(1)
    alias Desiccant_Balanced = Self(2)
    alias Num = Self(3)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias hxTypeNames = StaticTuple[StringLiteral, 3](
    "HeatExchanger:AirToAir:FlatPlate", "HeatExchanger:AirToAir:SensibleAndLatent", "HeatExchanger:Desiccant:BalancedFlow")
alias hxTypeNamesUC = StaticTuple[StringLiteral, 3](
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE", "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT", "HEATEXCHANGER:DESICCANT:BALANCEDFLOW")
@value
struct MixerType:
    var value: Int32
    alias Invalid = Self(-1)
    alias InletSide = Self(0)
    alias SupplySide = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias mixerTypeNames = StaticTuple[StringLiteral, 2](
    "AirTerminal:SingleDuct:InletSideMixer",
    "AirTerminal:SingleDuct:SupplySideMixer")
alias mixerTypeNamesUC = StaticTuple[StringLiteral, 2](
    "AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER",
    "AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER")
alias mixerTypeLocNames = StaticTuple[StringLiteral, 2]("InletSide", "SupplySide")
alias mixerTypeLocNamesUC = StaticTuple[StringLiteral, 2]("INLETSIDE", "SUPPLYSIDE")
@value
struct OATType:
    var value: Int32
    alias Invalid = Self(-1)
    alias WetBulb = Self(0)
    alias DryBulb = Self(1)
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
alias oatTypeNames = StaticTuple[StringLiteral, 2]("WetBulbTemperature", "DryBulbTemperature")
alias oatTypeNamesUC = StaticTuple[StringLiteral, 2]("WETBULBTEMPERATURE", "DRYBULBTEMPERATURE")
alias OscillateMagnitude: Float64 = 0.15
alias MaxSpeedLevels: Int32 = 10
@value
struct ComponentSetPtData:
    var EquipmentType: String
    var EquipmentName: String
    var NodeNumIn: Int32 = 0
    var NodeNumOut: Int32 = 0
    var EquipDemand: Float64 = 0.0
    var DesignFlowRate: Float64 = 0.0
    var HeatOrCool: String
    var OpType: Int32 = 0
@value
struct CompressorOp:
    var value: Int32
    alias Invalid = Self(-1)
    alias Off = Self(0) // signal DXCoil that compressor shouldn't run
    alias On = Self(1)  // normal compressor operation
    alias Num = Self(2)
    @staticmethod
    def from_int(val: Int32) -> Self:
        return Self {value: val}
    @staticmethod
    def __init__(val: Int32) -> Self:
        return Self {value: val}
    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    def __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value
    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value
    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value
    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value
    def __int__(self) -> Int32:
        return self.value
@value
struct HVACGlobalsData(BaseGlobalStruct):
    var CompSetPtEquip: DynamicVector[ComponentSetPtData]
    var MSHPMassFlowRateLow: Float64 = 0.0       // Mass flow rate at low speed
    var MSHPMassFlowRateHigh: Float64 = 0.0      // Mass flow rate at high speed
    var MSHPWasteHeat: Float64 = 0.0             // Waste heat
    var PreviousTimeStep: Float64 = 0.0          // The time step length at the previous time step
    var ShortenTimeStepSysRoomAir: Bool = false // Logical flag that triggers shortening of system time step
    var MSUSEconoSpeedNum: Float64 = 0 // Economizer speed
    var deviationFromSetPtThresholdHtg: Float64 = -0.2 // heating threshold for reporting setpoint deviation
    var deviationFromSetPtThresholdClg: Float64 = 0.2  // cooling threshold for reporting setpoint deviation
    var SimAirLoopsFlag: Bool = false           // True when the air loops need to be (re)simulated
    var SimElecCircuitsFlag: Bool = false       // True when electic circuits need to be (re)simulated
    var SimPlantLoopsFlag: Bool = false         // True when the main plant loops need to be (re)simulated
    var SimZoneEquipmentFlag: Bool = false      // True when zone equipment components need to be (re)simulated
    var SimNonZoneEquipmentFlag: Bool = false   // True when non-zone equipment components need to be (re)simulated
    var ZoneMassBalanceHVACReSim: Bool = false  // True when zone air mass flow balance and air loop needs (re)simulated
    var MinAirLoopIterationsAfterFirst: Int32 = 1 // minimum number of HVAC iterations after FirstHVACIteration
    var DXCT: DXCoilType = DXCoilType.Regular // dx coil type: regular DX coil ==1, 100% DOAS DX coil = 2
    var FirstTimeStepSysFlag: Bool = false                 // Set to true at the start of each sub-time step
    var TimeStepSys: Float64 = 0.0                  // System Time Increment - the adaptive time step used by the HVAC simulation (hours)
    var TimeStepSysSec: Float64 = 0.0               // System Time Increment in seconds
    var SysTimeElapsed: Float64 = 0.0               // elapsed system time in zone timestep (hours)
    var FracTimeStepZone: Float64 = 0.0             // System time step divided by the zone time step
    var ShortenTimeStepSys: Bool = false           // Logical flag that triggers shortening of system time step
    var NumOfSysTimeSteps: Int32 = 1                 // for current zone time step, number of system timesteps inside  it
    var NumOfSysTimeStepsLastZoneTimeStep: Int32 = 1 // previous zone time step, num of system timesteps inside
    var LimitNumSysSteps: Int32 = 0
    var UseZoneTimeStepHistory: Bool = true    // triggers use of zone time step history, else system time step history, for ZTM1, ZTMx
    var NumPlantLoops: Int32 = 0                 // Number of plant loops specified in simulation
    var NumCondLoops: Int32 = 0                  // Number of condenser plant loops specified in simulation
    var NumElecCircuits: Int32 = 0               // Number of electric circuits specified in simulation
    var NumGasMeters: Int32 = 0                  // Number of gas meters specified in simulation
    var NumPrimaryAirSys: Int32 = 0              // Number of primary HVAC air systems
    var OnOffFanPartLoadFraction: Float64 = 1.0 // fan part-load fraction (Fan:OnOff)
    var DXCoilTotalCapacity: Float64 = 0.0      // DX coil total cooling capacity (eio report var for HPWHs)
    var DXElecCoolingPower: Float64 = 0.0       // Electric power consumed by DX cooling coil last DX simulation
    var DXElecHeatingPower: Float64 = 0.0       // Electric power consumed by DX heating coil last DX simulation
    var ElecHeatingCoilPower: Float64 = 0.0     // Electric power consumed by electric heating coil
    var SuppHeatingCoilPower: Float64 = 0.0     // Electric power consumed by electric supplemental heating coil
    var AirToAirHXElecPower: Float64 = 0.0      // Electric power consumed by Heat Exchanger:Air To Air (Generic or Flat Plate)
    var DefrostElecPower: Float64 = 0.0         // Electric power consumed by DX heating coil for defrosting (Resistive or ReverseCycle)
    var UnbalExhMassFlow: Float64 = 0.0      // unbalanced zone exhaust from a zone equip component [kg/s]
    var BalancedExhMassFlow: Float64 = 0.0   // balanced zone exhaust (declared as so by user)  [kg/s]
    var PlenumInducedMassFlow: Float64 = 0.0 // secondary air mass flow rate induced from a return plenum [kg/s]
    var TurnFansOn: Bool = false            // If true overrides fan schedule and cycles fans on
    var TurnFansOff: Bool = false           // If True overrides fan schedule and TurnFansOn and forces fans off
    var SetPointErrorFlag: Bool = false     // True if any needed setpoints not set; if true, program terminates
    var DoSetPointTest: Bool = false        // True one time only for sensed node setpoint test
    var NightVentOn: Bool = false           // set TRUE in SimAirServingZone if night ventilation is happening
    var NumTempContComps: Int32 = 0
    var HPWHInletDBTemp: Float64 = 0.0     // Used by curve objects when calculating DX coil performance for HEAT PUMP:WATER HEATER
    var HPWHInletWBTemp: Float64 = 0.0     // Used by curve objects when calculating DX coil performance for HEAT PUMP:WATER HEATER
    var HPWHCrankcaseDBTemp: Float64 = 0.0 // Used for HEAT PUMP:WATER HEATER crankcase heater ambient temperature calculations
    var AirLoopInit: Bool = false         // flag for whether InitAirLoops has been called
    var AirLoopsSimOnce: Bool = false     // True means that the air loops have been simulated once in this environment
    var GetAirPathDataDone: Bool = false  // True means that air loops inputs have been processed
    var StandardRatingsMyOneTimeFlag: Bool = true
    var StandardRatingsMyCoolOneTimeFlag: Bool = true
    var StandardRatingsMyCoolOneTimeFlag2: Bool = true
    var StandardRatingsMyCoolOneTimeFlag3: Bool = true
    var StandardRatingsMyHeatOneTimeFlag: Bool = true
    var StandardRatingsMyHeatOneTimeFlag2: Bool = true
    def init_constant_state(inout self, state: EnergyPlusData):

    def init_state(inout self, state: EnergyPlusData):

    def clear_state(inout self):
        self = HVACGlobalsData()