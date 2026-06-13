from Data.EnergyPlusData import EnergyPlusData
from DataBranchNodeConnections import (
    NodeConnectionDef,
    EqNodeConnectionDef,
    CompSetData,
    ParentNodeListData,
)
from NodeInputManager import (
    ConnectionObjectType,
    ConnectionType,
    CompFluidStream,
    ConnectionObjectTypeNames as NodeConnectionObjectTypeNames,
    ConnectionTypeNames as NodeConnectionTypeNames,
    ConnectionObjectTypeNamesUC as NodeConnectionObjectTypeNamesUC,
)
from UtilityRoutines import (
    ShowSevereError,
    ShowContinueError,
    SameString,
    FindItemInList,
    makeUPPER,
    has_prefixi,
    getEnumValue,
)

alias undefined = "UNDEFINED"

var ConnectionObjectTypeNames: List[StringLiteral] = List[StringLiteral](
    "Undefined",
    "AirConditioner:VariableRefrigerantFlow",
    "AirLoopHVAC",
    "AirLoopHVAC:DedicatedOutdoorAirSystem",
    "AirLoopHVAC:ExhaustSystem",
    "AirLoopHVAC:Mixer",
    "AirLoopHVAC:OutdoorAirSystem",
    "AirLoopHVAC:ReturnPath",
    "AirLoopHVAC:ReturnPlenum",
    "AirLoopHVAC:Splitter",
    "AirLoopHVAC:SupplyPath",
    "AirLoopHVAC:SupplyPlenum",
    "AirLoopHVAC:Unitary:Furnace:HeatCool",
    "AirLoopHVAC:Unitary:Furnace:HeatOnly",
    "AirLoopHVAC:UnitaryHeatCool",
    "AirLoopHVAC:UnitaryHeatCool:VAVChangeoverBypass",
    "AirLoopHVAC:UnitaryHeatOnly",
    "AirLoopHVAC:UnitaryHeatPump:AirToAir",
    "AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed",
    "AirLoopHVAC:UnitaryHeatPump:WaterToAir",
    "AirLoopHVAC:UnitarySystem",
    "AirLoopHVAC:ZoneMixer",
    "AirLoopHVAC:ZoneSplitter",
    "AirTerminal:DualDuct:ConstantVolume",
    "AirTerminal:DualDuct:ConstantVolume:Cool",
    "AirTerminal:DualDuct:ConstantVolume:Heat",
    "AirTerminal:DualDuct:VAV",
    "AirTerminal:DualDuct:VAV:Cool",
    "AirTerminal:DualDuct:VAV:Heat",
    "AirTerminal:DualDuct:VAV:OutdoorAir",
    "AirTerminal:DualDuct:VAV:OutdoorAir:OutdoorAir",
    "AirTerminal:DualDuct:VAV:OutdoorAir:RecirculatedAir",
    "AirTerminal:SingleDuct:ConstantVolume:CooledBeam",
    "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam",
    "AirTerminal:SingleDuct:ConstantVolume:FourPipeInduction",
    "AirTerminal:SingleDuct:ConstantVolume:NoReheat",
    "AirTerminal:SingleDuct:ConstantVolume:Reheat",
    "AirTerminal:SingleDuct:Mixer",
    "AirTerminal:SingleDuct:ParallelPIU:Reheat",
    "AirTerminal:SingleDuct:SeriesPIU:Reheat",
    "AirTerminal:SingleDuct:UserDefined",
    "AirTerminal:SingleDuct:VAV:HeatAndCool:NoReheat",
    "AirTerminal:SingleDuct:VAV:HeatAndCool:Reheat",
    "AirTerminal:SingleDuct:VAV:NoReheat",
    "AirTerminal:SingleDuct:VAV:Reheat",
    "AirTerminal:SingleDuct:VAV:Reheat:VariableSpeedFan",
    "AvailabilityManager:DifferentialThermostat",
    "AvailabilityManager:HighTemperatureTurnOff",
    "AvailabilityManager:HighTemperatureTurnOn",
    "AvailabilityManager:LowTemperatureTurnOff",
    "AvailabilityManager:LowTemperatureTurnOn",
    "Boiler:HotWater",
    "Boiler:Steam",
    "Branch",
    "CentralHeatPumpSystem",
    "Chiller:Absorption",
    "Chiller:Absorption:Indirect",
    "Chiller:CombustionTurbine",
    "Chiller:ConstantCOP",
    "Chiller:Electric",
    "Chiller:Electric:EIR",
    "Chiller:Electric:ReformulatedEIR",
    "Chiller:Electric:ASHRAE205",
    "Chiller:EngineDriven",
    "ChillerHeater:Absorption:DirectFired",
    "ChillerHeater:Absorption:DoubleEffect",
    "Coil:Cooling:DX",
    "Coil:Cooling:DX:CurveFit:Speed",
    "Coil:Cooling:DX:MultiSpeed",
    "Coil:Cooling:DX:SingleSpeed",
    "Coil:Cooling:DX:SingleSpeed:ThermalStorage",
    "Coil:Cooling:DX:SubcoolReheat",
    "Coil:Cooling:DX:TwoSpeed",
    "Coil:Cooling:DX:TwoStageWithHumidityControlMode",
    "Coil:Cooling:DX:VariableRefrigerantFlow",
    "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl",
    "Coil:Cooling:DX:VariableSpeed",
    "Coil:Cooling:Water",
    "Coil:Cooling:Water:DetailedGeometry",
    "Coil:Cooling:WaterToAirHeatPump:EquationFit",
    "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation",
    "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit",
    "Coil:Heating:DX:MultiSpeed",
    "Coil:Heating:DX:SingleSpeed",
    "Coil:Heating:DX:VariableRefrigerantFlow",
    "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl",
    "Coil:Heating:DX:VariableSpeed",
    "Coil:Heating:Desuperheater",
    "Coil:Heating:Electric",
    "Coil:Heating:Electric:MultiStage",
    "Coil:Heating:Fuel",
    "Coil:Heating:Gas:MultiStage",
    "Coil:Heating:Steam",
    "Coil:Heating:Water",
    "Coil:Heating:WaterToAirHeatPump:EquationFit",
    "Coil:Heating:WaterToAirHeatPump:ParameterEstimation",
    "Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit",
    "Coil:UserDefined",
    "Coil:WaterHeating:AirToWaterHeatPump:Pumped",
    "Coil:WaterHeating:AirToWaterHeatPump:VariableSpeed",
    "Coil:WaterHeating:AirToWaterHeatPump:Wrapped",
    "Coil:WaterHeating:Desuperheater",
    "CoilSystem:Cooling:DX",
    "CoilSystem:Cooling:DX:HeatExchangerAssisted",
    "CoilSystem:Cooling:Water",
    "CoilSystem:Cooling:Water:HeatExchangerAssisted",
    "CoilSystem:Heating:DX",
    "CoilSystem:IntegratedHeatPump:AirSource",
    "Condenser",
    "CondenserLoop",
    "Connector:Mixer",
    "Connector:Splitter",
    "Controller:OutdoorAir",
    "Controller:WaterCoil",
    "CoolingTower:SingleSpeed",
    "CoolingTower:TwoSpeed",
    "CoolingTower:VariableSpeed",
    "CoolingTower:VariableSpeed:Merkel",
    "Dehumidifier:Desiccant:NoFans",
    "Dehumidifier:Desiccant:System",
    "DistrictCooling",
    "DistrictHeating:Water",
    "DistrictHeating:Steam",
    "Duct",
    "ElectricEquipment:ITE:AirCooled",
    "EvaporativeCooler:Direct:CelDekPad",
    "EvaporativeCooler:Direct:ResearchSpecial",
    "EvaporativeCooler:Indirect:CelDekPad",
    "EvaporativeCooler:Indirect:ResearchSpecial",
    "EvaporativeCooler:Indirect:WetCoil",
    "EvaporativeFluidCooler:SingleSpeed",
    "EvaporativeFluidCooler:TwoSpeed",
    "Fan:ComponentModel",
    "Fan:ConstantVolume",
    "Fan:OnOff",
    "Fan:SystemModel",
    "Fan:VariableVolume",
    "Fan:ZoneExhaust",
    "FluidCooler:SingleSpeed",
    "FluidCooler:TwoSpeed",
    "Generator:CombustionTurbine",
    "Generator:FuelCell:AirSupply",
    "Generator:FuelCell:ExhaustGasToWaterHeatExchanger",
    "Generator:FuelCell:PowerModule",
    "Generator:FuelCell:StackCooler",
    "Generator:FuelCell:WaterSupply",
    "Generator:FuelSupply",
    "Generator:InternalCombustionEngine",
    "Generator:MicroCHP",
    "Generator:MicroTurbine",
    "GroundHeatExchanger:HorizontalTrench",
    "GroundHeatExchanger:Pond",
    "GroundHeatExchanger:Slinky",
    "GroundHeatExchanger:Surface",
    "GroundHeatExchanger:System",
    "HeaderedPumps:ConstantSpeed",
    "HeaderedPumps:VariableSpeed",
    "HeatExchanger:AirToAir:FlatPlate",
    "HeatExchanger:AirToAir:SensibleAndLatent",
    "HeatExchanger:Desiccant:BalancedFlow",
    "HeatExchanger:FluidToFluid",
    "HeatPump:AirToWater:FuelFired:Cooling",
    "HeatPump:AirToWater:FuelFired:Heating",
    "HeatPump:PlantLoop:EIR:Cooling",
    "HeatPump:PlantLoop:EIR:Heating",
    "HeatPump:AirToWater:Cooling",
    "HeatPump:AirToWater:Heating",
    "HeatPump:AirToWater",
    "HeatPump:WaterToWater:EquationFit:Cooling",
    "HeatPump:WaterToWater:EquationFit:Heating",
    "HeatPump:WaterToWater:ParameterEstimation:Cooling",
    "HeatPump:WaterToWater:ParameterEstimation:Heating",
    "Humidifier:Steam:Electric",
    "Humidifier:Steam:Gas",
    "Lights",
    "LoadProfile:Plant",
    "OutdoorAir:Mixer",
    "OutdoorAir:Node",
    "OutdoorAir:NodeList",
    "Pipe:Adiabatic",
    "Pipe:Adiabatic:Steam",
    "Pipe:Indoor",
    "Pipe:Outdoor",
    "Pipe:Underground",
    "PipingSystem:Underground:PipeCircuit",
    "PlantComponent:TemperatureSource",
    "PlantComponent:UserDefined",
    "PlantEquipmentOperation:ChillerHeaterChangeover",
    "PlantEquipmentOperation:ComponentSetpoint",
    "PlantEquipmentOperation:OutdoorDewpointDifference",
    "PlantEquipmentOperation:OutdoorDrybulbDifference",
    "PlantEquipmentOperation:OutdoorWetbulbDifference",
    "PlantEquipmentOperation:ThermalEnergyStorage",
    "PlantLoop",
    "Pump:ConstantSpeed",
    "Pump:ConstantVolume",
    "Pump:VariableSpeed",
    "Pump:VariableSpeed:Condensate",
    "Refrigeration:CompressorRack",
    "Refrigeration:Condenser:AirCooled",
    "Refrigeration:Condenser:EvaporativeCooled",
    "Refrigeration:Condenser:WaterCooled",
    "Refrigeration:GasCooler:AirCooled",
    "SetpointManager:Coldest",
    "SetpointManager:CondenserEnteringReset",
    "SetpointManager:CondenserEnteringReset:Ideal",
    "SetpointManager:FollowGroundTemperature",
    "SetpointManager:FollowOutdoorAirTemperature",
    "SetpointManager:FollowSystemNodeTemperature",
    "SetpointManager:MixedAir",
    "SetpointManager:MultiZone:Cooling:Average",
    "SetpointManager:MultiZone:Heating:Average",
    "SetpointManager:MultiZone:Humidity:Maximum",
    "SetpointManager:MultiZone:Humidity:Minimum",
    "SetpointManager:MultiZone:MaximumHumidity:Average",
    "SetpointManager:MultiZone:MinimumHumidity:Average",
    "SetpointManager:OutdoorAirPretreat",
    "SetpointManager:OutdoorAirReset",
    "SetpointManager:ReturnTemperature:ChilledWater",
    "SetpointManager:ReturnTemperature:HotWater",
    "SetpointManager:Scheduled",
    "SetpointManager:Scheduled:DualSetpoint",
    "SetpointManager:SingleZone:Cooling",
    "SetpointManager:SingleZone:Heating",
    "SetpointManager:SingleZone:Humidity:Maximum",
    "SetpointManager:SingleZone:Humidity:Minimum",
    "SetpointManager:SingleZone:OneStageCooling",
    "SetpointManager:SingleZone:OneStageHeating",
    "SetpointManager:SingleZone:Reheat",
    "SetpointManager:SystemNodeReset:Temperature",
    "SetpointManager:SystemNodeReset:Humidity",
    "SetpointManager:Warmest",
    "SetpointManager:WarmestTemperatureFlow",
    "SolarCollector:FlatPlate:PhotovoltaicThermal",
    "SolarCollector:FlatPlate:Water",
    "SolarCollector:IntegralCollectorStorage",
    "SolarCollector:UnglazedTranspired",
    "SurfaceProperty:LocalEnvironment",
    "SwimmingPool:Indoor",
    "TemperingValve",
    "ThermalStorage:ChilledWater:Mixed",
    "ThermalStorage:ChilledWater:Stratified",
    "ThermalStorage:HotWater:Stratified",
    "ThermalStorage:Ice:Detailed",
    "ThermalStorage:Ice:Simple",
    "ThermalStorage:PCM",
    "WaterHeater:HeatPump",
    "WaterHeater:HeatPump:PumpedCondenser",
    "WaterHeater:HeatPump:WrappedCondenser",
    "WaterHeater:Mixed",
    "WaterHeater:Stratified",
    "WaterUse:Connections",
    "ZoneHVAC:AirDistributionUnit",
    "ZoneHVAC:Baseboard:Convective:Electric",
    "ZoneHVAC:Baseboard:Convective:Water",
    "ZoneHVAC:Baseboard:RadiantConvective:Electric",
    "ZoneHVAC:Baseboard:RadiantConvective:Steam",
    "ZoneHVAC:Baseboard:RadiantConvective:Water",
    "ZoneHVAC:CoolingPanel:RadiantConvective:Water",
    "ZoneHVAC:Dehumidifier:DX",
    "ZoneHVAC:EnergyRecoveryVentilator",
    "ZoneHVAC:EquipmentConnections",
    "ZoneHVAC:EvaporativeCoolerUnit",
    "ZoneHVAC:ExhaustControl",
    "ZoneHVAC:ForcedAir:UserDefined",
    "ZoneHVAC:FourPipeFanCoil",
    "ZoneHVAC:HighTemperatureRadiant",
    "ZoneHVAC:HybridUnitaryHVAC",
    "ZoneHVAC:IdealLoadsAirSystem",
    "ZoneHVAC:LowTemperatureRadiant:ConstantFlow",
    "ZoneHVAC:LowTemperatureRadiant:VariableFlow",
    "ZoneHVAC:OutdoorAirUnit",
    "ZoneHVAC:PackagedTerminalAirConditioner",
    "ZoneHVAC:PackagedTerminalHeatPump",
    "ZoneHVAC:RefrigerationChillerSet",
    "ZoneHVAC:TerminalUnit:VariableRefrigerantFlow",
    "ZoneHVAC:UnitHeater",
    "ZoneHVAC:UnitVentilator",
    "ZoneHVAC:VentilatedSlab",
    "ZoneHVAC:WaterToAirHeatPump",
    "ZoneHVAC:WindowAirConditioner",
    "ZoneProperty:LocalEnvironment",
    "SpaceHVAC:EquipmentConnections",
    "SpaceHVAC:ZoneEquipmentSplitter",
    "SpaceHVAC:ZoneEquipmentMixer",
)

var ConnectionObjectTypeNamesUC: List[StringLiteral] = List[StringLiteral](
    undefined,
    "AIRCONDITIONER:VARIABLEREFRIGERANTFLOW",
    "AIRLOOPHVAC",
    "AIRLOOPHVAC:DEDICATEDOUTDOORAIRSYSTEM",
    "AIRLOOPHVAC:EXHAUSTSYSTEM",
    "AIRLOOPHVAC:MIXER",
    "AIRLOOPHVAC:OUTDOORAIRSYSTEM",
    "AIRLOOPHVAC:RETURNPATH",
    "AIRLOOPHVAC:RETURNPLENUM",
    "AIALOOPHVAC:SPLITTER",
    "AIRLOOPHVAC:SUPPLYPATH",
    "AIRLOOPHVAC:SUPPLYPLENUM",
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL",
    "AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY",
    "AIRLOOPHVAC:UNITARYHEATCOOL",
    "AIRLOOPHVAC:UNITARYHEATCOOL:VAVCHANGEOVERBYPASS",
    "AIRLOOPHVAC:UNITARYHEATONLY",
    "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR",
    "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR:MULTISPEED",
    "AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR",
    "AIRLOOPHVAC:UNITARYSYSTEM",
    "AIRLOOPHVAC:ZONEMIXER",
    "AIRLOOPHVAC:ZONESPLITTER",
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME",
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME:COOL",
    "AIRTERMINAL:DUALDUCT:CONSTANTVOLUME:HEAT",
    "AIRTERMINAL:DUALDUCT:VAV",
    "AIRTERMINAL:DUALDUCT:VAV:COOL",
    "AIRTERMINAL:DUALDUCT:VAV:HEAT",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR:OUTDOORAIR",
    "AIRTERMINAL:DUALDUCT:VAV:OUTDOORAIR:RECIRCULATEDAIR",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:COOLEDBEAM",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEBEAM",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:FOURPIPEINDUCTION",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:CONSTANTVOLUME:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:MIXER",
    "AIRTERMINAL:SINGLEDUCT:PARALLELPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:SERIESPIU:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:USERDEFINED",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:HEATANDCOOL:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:NOREHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT",
    "AIRTERMINAL:SINGLEDUCT:VAV:REHEAT:VARIABLESPEEDFAN",
    "AVAILABILITYMANAGER:DIFFERENTIALTHERMOSTAT",
    "AVAILABILITYMANAGER:HIGHTEMPERATURETURNOFF",
    "AVAILABILITYMANAGER:HIGHTEMPERATURETURNON",
    "AVAILABILITYMANAGER:LOWTEMPERATURETURNOFF",
    "AVAILABILITYMANAGER:LOWTEMPERATURETURNON",
    "BOILER:HOTWATER",
    "BOILER:STEAM",
    "BRANCH",
    "CENTRALHEATPUMPSYSTEM",
    "CHILLER:ABSORPTION",
    "CHILLER:ABSORPTION:INDIRECT",
    "CHILLER:COMBUSTIONTURBINE",
    "CHILLER:CONSTANTCOP",
    "CHILLER:ELECTRIC",
    "CHILLER:ELECTRIC:EIR",
    "CHILLER:ELECTRIC:REFORMULATEDEIR",
    "CHILLER:ELECTRIC:ASHRAE205",
    "CHILLER:ENGINEDRIVEN",
    "CHILLERHEATER:ABSORPTION:DIRECTFIRED",
    "CHILLERHEATER:ABSORPTION:DOUBLEEFFECT",
    "COIL:COOLING:DX",
    "COIL:COOLING:DX:CURVEFIT:SPEED",
    "COIL:COOLING:DX:MULTISPEED",
    "COIL:COOLING:DX:SINGLESPEED",
    "COIL:COOLING:DX:SINGLESPEED:THERMALSTORAGE",
    "COIL:COOLING:DX:SUBCOOLREHEAT",
    "COIL:COOLING:DX:TWOSPEED",
    "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE",
    "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW",
    "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL",
    "COIL:COOLING:DX:VARIABLESPEED",
    "COIL:COOLING:WATER",
    "COIL:COOLING:WATER:DETAILEDGEOMETRY",
    "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT",
    "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION",
    "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT",
    "COIL:HEATING:DX:MULTISPEED",
    "COIL:HEATING:DX:SINGLESPEED",
    "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW",
    "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL",
    "COIL:HEATING:DX:VARIABLESPEED",
    "COIL:HEATING:DESUPERHEATER",
    "COIL:HEATING:ELECTRIC",
    "COIL:HEATING:ELECTRIC:MULTISTAGE",
    "COIL:HEATING:FUEL",
    "COIL:HEATING:GAS:MULTISTAGE",
    "COIL:HEATING:STEAM",
    "COIL:HEATING:WATER",
    "COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT",
    "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION",
    "COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT",
    "COIL:USERDEFINED",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED",
    "COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED",
    "COIL:WATERHEATING:DESUPERHEATER",
    "COILSYSTEM:COOLING:DX",
    "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED",
    "COILSYSTEM:COOLING:WATER",
    "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED",
    "COILSYSTEM:HEATING:DX",
    "COILSYSTEM:INTEGRATEDHEATPUMP:AIRSOURCE",
    "CONDENSER",
    "CONDENSERLOOP",
    "CONNECTOR:MIXER",
    "CONNECTOR:SPLITTER",
    "CONTROLLER:OUTDOORAIR",
    "CONTROLLER:WATERCOIL",
    "COOLINGTOWER:SINGLESPEED",
    "COOLINGTOWER:TWOSPEED",
    "COOLINGTOWER:VARIABLESPEED",
    "COOLINGTOWER:VARIABLESPEED:MERKEL",
    "DEHUMIDIFIER:DESICCANT:NOFANS",
    "DEHUMIDIFIER:DESICCANT:SYSTEM",
    "DISTRICTCOOLING",
    "DISTRICTHEATING:WATER",
    "DISTRICTHEATING:STEAM",
    "DUCT",
    "ELECTRICEQUIPMENT:ITE:AIRCOOLED",
    "EVAPORATIVECOOLER:DIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:DIRECT:RESEARCHSPECIAL",
    "EVAPORATIVECOOLER:INDIRECT:CELDEKPAD",
    "EVAPORATIVECOOLER:INDIRECT:RESEARCHSPECIAL",
    "EVAPORATIVECOOLER:INDIRECT:WETCOIL",
    "EVAPORATIVEFLUIDCOOLER:SINGLESPEED",
    "EVAPORATIVEFLUIDCOOLER:TWOSPEED",
    "FAN:COMPONENTMODEL",
    "FAN:CONSTANTVOLUME",
    "FAN:ONOFF",
    "FAN:SYSTEMMODEL",
    "FAN:VARIABLEVOLUME",
    "FAN:ZONEEXHAUST",
    "FLUIDCOOLER:SINGLESPEED",
    "FLUIDCOOLER:TWOSPEED",
    "GENERATOR:COMBUSTIONTURBINE",
    "GENERATOR:FUELCELL:AIRSUPPLY",
    "GENERATOR:FUELCELL:EXHAUSTGASTOWATERHEATEXCHANGER",
    "GENERATOR:FUELCELL:POWERMODULE",
    "GENERATOR:FUELCELL:STACKCOOLER",
    "GENERATOR:FUELCELL:WATERSUPPLY",
    "GENERATOR:FUELSUPPLY",
    "GENERATOR:INTERNALCOMBUSTIONENGINE",
    "GENERATOR:MICROCHP",
    "GENERATOR:MICROTURBINE",
    "GROUNDHEATEXCHANGER:HORIZONTALTRENCH",
    "GROUNDHEATEXCHANGER:POND",
    "GROUNDHEATEXCHANGER:SLINKY",
    "GROUNDHEATEXCHANGER:SURFACE",
    "GROUNDHEATEXCHANGER:SYSTEM",
    "HEADEREDPUMPS:CONSTANTSPEED",
    "HEADEREDPUMPS:VARIABLESPEED",
    "HEATEXCHANGER:AIRTOAIR:FLATPLATE",
    "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT",
    "HEATEXCHANGER:DESICCANT:BALANCEDFLOW",
    "HEATEXCHANGER:FLUIDTOFLUID",
    "HEATPUMP:AIRTOWATER:FUELFIRED:COOLING",
    "HEATPUMP:AIRTOWATER:FUELFIRED:HEATING",
    "HEATPUMP:PLANTLOOP:EIR:COOLING",
    "HEATPUMP:PLANTLOOP:EIR:HEATING",
    "HEATPUMP:AIRTOWATER:COOLING",
    "HEATPUMP:AIRTOWATER:HEATING",
    "HEATPUMP:AIRTOWATER",
    "HEATPUMP:WATERTOWATER:EQUATIONFIT:COOLING",
    "HEATPUMP:WATERTOWATER:EQUATIONFIT:HEATING",
    "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:COOLING",
    "HEATPUMP:WATERTOWATER:PARAMETERESTIMATION:HEATING",
    "HUMIDIFIER:STEAM:ELECTRIC",
    "HUMIDIFIER:STEAM:GAS",
    "LIGHTS",
    "LOADPROFILE:PLANT",
    "OUTDOORAIR:MIXER",
    "OUTDOORAIR:NODE",
    "OUTDOORAIR:NODELIST",
    "PIPE:ADIABATIC",
    "PIPE:ADIABATIC:STEAM",
    "PIPE:INDOOR",
    "PIPE:OUTDOOR",
    "PIPE:UNDERGROUND",
    "PIPINGSYSTEM:UNDERGROUND:PIPECIRCUIT",
    "PLANTCOMPONENT:TEMPERATURESOURCE",
    "PLANTCOMPONENT:USERDEFINED",
    "PLANTEQUIPMENTOPERATION:CHILLERHEATERCHANGEOVER",
    "PLANTEQUIPMENTOPERATION:COMPONENTSETPOINT",
    "PLANTEQUIPMENTOPERATION:OUTDOORDEWPOINTDIFFERENCE",
    "PLANTEQUIPMENTOPERATION:OUTDOORDRYBULBDIFFERENCE",
    "PLANTEQUIPMENTOPERATION:OUTDOORWETBULBDIFFERENCE",
    "PLANTEQUIPMENTOPERATION:THERMALENERGYSTORAGE",
    "PLANTLOOP",
    "PUMP:CONSTANTSPEED",
    "PUMP:CONSTANTVOLUME",
    "PUMP:VARIABLESPEED",
    "PUMP:VARIABLESPEED:CONDENSATE",
    "REFRIGERATION:COMPRESSORRACK",
    "REFRIGERATION:CONDENSER:AIRCOOLED",
    "REFRIGERATION:CONDENSER:EVAPORATIVECOOLED",
    "REFRIGERATION:CONDENSER:WATERCOOLED",
    "REFRIGERATION:GASCOOLER:AIRCOOLED",
    "SETPOINTMANAGER:COLDEST",
    "SETPOINTMANAGER:CONDENSERENTERINGRESET",
    "SETPOINTMANAGER:CONDENSERENTERINGRESET:IDEAL",
    "SETPOINTMANAGER:FOLLOWGROUNDTEMPERATURE",
    "SETPOINTMANAGER:FOLLOWOUTDOORAIRTEMPERATURE",
    "SETPOINTMANAGER:FOLLOWSYSTEMNODETEMPERATURE",
    "SETPOINTMANAGER:MIXEDAIR",
    "SETPOINTMANAGER:MULTIZONE:COOLING:AVERAGE",
    "SETPOINTMANAGER:MULTIZONE:HEATING:AVERAGE",
    "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MAXIMUM",
    "SETPOINTMANAGER:MULTIZONE:HUMIDITY:MINIMUM",
    "SETPOINTMANAGER:MULTIZONE:MAXIMUMHUMIDITY:AVERAGE",
    "SETPOINTMANAGER:MULTIZONE:MINIMUMHUMIDITY:AVERAGE",
    "SETPOINTMANAGER:OUTDOORAIRPRETREAT",
    "SETPOINTMANAGER:OUTDOORAIRRESET",
    "SETPOINTMANAGER:RETURNTEMPERATURE:CHILLEDWATER",
    "SETPOINTMANAGER:RETURNTEMPERATURE:HOTWATER",
    "SETPOINTMANAGER:SCHEDULED",
    "SETPOINTMANAGER:SCHEDULED:DUALSETPOINT",
    "SETPOINTMANAGER:SINGLEZONE:COOLING",
    "SETPOINTMANAGER:SINGLEZONE:HEATING",
    "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MAXIMUM",
    "SETPOINTMANAGER:SINGLEZONE:HUMIDITY:MINIMUM",
    "SETPOINTMANAGER:SINGLEZONE:ONESTAGECOOLING",
    "SETPOINTMANAGER:SINGLEZONE:ONESTAGEHEATING",
    "SETPOINTMANAGER:SINGLEZONE:REHEAT",
    "SETPOINTMANAGER:SYSTEMNODERESET:TEMPERATURE",
    "SETPOINTMANAGER:SYSTEMNODERESET:HUMIDITY",
    "SETPOINTMANAGER:WARMEST",
    "SETPOINTMANAGER:WARMESTTEMPERATUREFLOW",
    "SOLARCOLLECTOR:FLATPLATE:PHOTOVOLTAICTHERMAL",
    "SOLARCOLLECTOR:FLATPLATE:WATER",
    "SOLARCOLLECTOR:INTEGRALCOLLECTORSTORAGE",
    "SOLARCOLLECTOR:UNGLAZEDTRANSPIRED",
    "SURFACEPROPERTY:LOCALENVIRONMENT",
    "SWIMMINGPOOL:INDOOR",
    "TEMPERINGVALVE",
    "THERMALSTORAGE:CHILLEDWATER:MIXED",
    "THERMALSTORAGE:CHILLEDWATER:STRATIFIED",
    "THERMALSTORAGE:HOTWATER:STRATIFIED",
    "THERMALSTORAGE:ICE:DETAILED",
    "THERMALSTORAGE:ICE:SIMPLE",
    "THERMALSTORAGE:PCM",
    "WATERHEATER:HEATPUMP",
    "WATERHEATER:HEATPUMP:PUMPEDCONDENSER",
    "WATERHEATER:HEATPUMP:WRAPPEDCONDENSER",
    "WATERHEATER:MIXED",
    "WATERHEATER:STRATIFIED",
    "WATERUSE:CONNECTIONS",
    "ZONEHVAC:AIRDISTRIBUTIONUNIT",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC",
    "ZONEHVAC:BASEBOARD:CONVECTIVE:WATER",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:ELECTRIC",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:STEAM",
    "ZONEHVAC:BASEBOARD:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:COOLINGPANEL:RADIANTCONVECTIVE:WATER",
    "ZONEHVAC:DEHUMIDIFIER:DX",
    "ZONEHVAC:ENERGYRECOVERYVENTILATOR",
    "ZONEHVAC:EQUIPMENTCONNECTIONS",
    "ZONEHVAC:EVAPORATIVECOOLERUNIT",
    "ZONEHVAC:EXHAUSTCONTROL",
    "ZONEHVAC:FORCEDAIR:USERDEFINED",
    "ZONEHVAC:FOURPIPEFANCOIL",
    "ZONEHVAC:HIGHTEMPERATURERADIANT",
    "ZONEHVAC:HYBRIDUNITARYHVAC",
    "ZONEHVAC:IDEALLOADSAIRSYSTEM",
    "ZONEHVAC:LOWTEMPERATURERADIANT:CONSTANTFLOW",
    "ZONEHVAC:LOWTEMPERATURERADIANT:VARIABLEFLOW",
    "ZONEHVAC:OUTDOORAIRUNIT",
    "ZONEHVAC:PACKAGEDTERMINALAIRCONDITIONER",
    "ZONEHVAC:PACKAGEDTERMINALHEATPUMP",
    "ZONEHVAC:REFRIGERATIONCHILLERSET",
    "ZONEHVAC:TERMINALUNIT:VARIABLEREFRIGERANTFLOW",
    "ZONEHVAC:UNITHEATER",
    "ZONEHVAC:UNITVENTILATOR",
    "ZONEHVAC:VENTILATEDSLAB",
    "ZONEHVAC:WATERTOAIRHEATPUMP",
    "ZONEHVAC:WINDOWAIRCONDITIONER",
    "ZONEPROPERTY:LOCALENVIRONMENT",
    "SPACEHVAC:EQUIPMENTCONNECTIONS",
    "SPACEHVAC:ZONEEQUIPMENTSPLITTER",
    "SPACEHVAC:ZONEEQUIPMENTMIXER",
)

struct Node:
    @staticmethod
    def RegisterNodeConnection(
        inout state: EnergyPlusData,
        NodeNumber: Int,
        NodeName: String,
        ObjectType: ConnectionObjectType,
        ObjectName: String,
        ConnectionType: ConnectionType,
        FluidStream: CompFluidStream,
        IsParent: Bool,
        inout errFlag: Bool,
        InputFieldName: String = String(),
    ):
        alias RoutineName = "RegisterNodeConnection: "
        var ErrorsFoundHere: Bool = False
        if (ObjectType == ConnectionObjectType.Invalid) or (ObjectType == ConnectionObjectType.Num):
            ShowSevereError(state, "Developer Error: Invalid ObjectType")
            ShowContinueError(state, String.format("Occurs for Node={}, ObjectName={}", NodeName, ObjectName))
            ErrorsFoundHere = True
        var objTypeStr: String = ConnectionObjectTypeNames[Int(ObjectType)]
        var conTypeStr: String = NodeConnectionTypeNames[Int(ConnectionType)]
        if (ConnectionType == ConnectionType.Invalid) or (ConnectionType == ConnectionType.Num):
            ShowSevereError(state, String.format("{}Invalid ConnectionType={}", RoutineName, Int(ConnectionType)))
            ShowContinueError(state, String.format("Occurs for Node={}, ObjectType={}, ObjectName={}", NodeName, objTypeStr, ObjectName))
            ErrorsFoundHere = True
        var MakeNew: Bool = True
        for Count in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Count].NodeNumber != NodeNumber:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].ObjectType != ObjectType:
                continue
            if not SameString(state.dataBranchNodeConnections.NodeConnections[Count].ObjectName, ObjectName):
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].ConnectionType != ConnectionType:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].FluidStream != FluidStream:
                continue
            if (state.dataBranchNodeConnections.NodeConnections[Count].ObjectIsParent and not IsParent) or (not state.dataBranchNodeConnections.NodeConnections[Count].ObjectIsParent and IsParent):
                ShowSevereError(state, String.format("{}{}", RoutineName, "Node registered for both Parent and \"not\" Parent"))
                ShowContinueError(state, String.format("{}{}{}{}{}{}", "Occurs for Node=", NodeName, ", ObjectType=", objTypeStr, ", ObjectName=", ObjectName))
                ErrorsFoundHere = True
            MakeNew = False
        if MakeNew:
            alias NodeConnectionAlloc: Int = 1000
            state.dataBranchNodeConnections.NumOfNodeConnections += 1
            if state.dataBranchNodeConnections.NumOfNodeConnections > 1 and state.dataBranchNodeConnections.NumOfNodeConnections > state.dataBranchNodeConnections.MaxNumOfNodeConnections:
                state.dataBranchNodeConnections.MaxNumOfNodeConnections += NodeConnectionAlloc
                # resize NodeConnections to new MaxNumOfNodeConnections
                while len(state.dataBranchNodeConnections.NodeConnections) < state.dataBranchNodeConnections.MaxNumOfNodeConnections:
                    state.dataBranchNodeConnections.NodeConnections.append(NodeConnectionDef())
            elif state.dataBranchNodeConnections.NumOfNodeConnections == 1:
                # allocate initial block
                state.dataBranchNodeConnections.MaxNumOfNodeConnections = NodeConnectionAlloc
                for _ in range(NodeConnectionAlloc):
                    state.dataBranchNodeConnections.NodeConnections.append(NodeConnectionDef())
            # assign values at index NumOfNodeConnections-1
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].NodeNumber = NodeNumber
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].NodeName = NodeName
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].ObjectType = ObjectType
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].ObjectName = ObjectName
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].ConnectionType = ConnectionType
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].FluidStream = FluidStream
            state.dataBranchNodeConnections.NodeConnections[state.dataBranchNodeConnections.NumOfNodeConnections - 1].ObjectIsParent = IsParent
        if has_prefixi(objTypeStr, "AirTerminal:"):
            if not InputFieldName.empty():
                state.dataBranchNodeConnections.NumOfAirTerminalNodes += 1
                alias EqNodeConnectionAlloc: Int = 100
                if state.dataBranchNodeConnections.NumOfAirTerminalNodes > 1 and state.dataBranchNodeConnections.NumOfAirTerminalNodes > state.dataBranchNodeConnections.MaxNumOfAirTerminalNodes:
                    state.dataBranchNodeConnections.MaxNumOfAirTerminalNodes += EqNodeConnectionAlloc
                    while len(state.dataBranchNodeConnections.AirTerminalNodeConnections) < state.dataBranchNodeConnections.MaxNumOfAirTerminalNodes:
                        state.dataBranchNodeConnections.AirTerminalNodeConnections.append(EqNodeConnectionDef())
                elif state.dataBranchNodeConnections.NumOfAirTerminalNodes == 1:
                    state.dataBranchNodeConnections.MaxNumOfAirTerminalNodes = EqNodeConnectionAlloc
                    for _ in range(EqNodeConnectionAlloc):
                        state.dataBranchNodeConnections.AirTerminalNodeConnections.append(EqNodeConnectionDef())
                var Found: Int = FindItemInList(
                    NodeName,
                    state.dataBranchNodeConnections.AirTerminalNodeConnections,
                    Int.__getattribute__(state.dataBranchNodeConnections.AirTerminalNodeConnections[0], "NodeName"),
                    state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1,
                )
                if Found != 0:
                    ShowSevereError(state, String.format("{}{}=\"{}\" node name duplicated", RoutineName, objTypeStr, ObjectName))
                    ShowContinueError(state, String.format("NodeName=\"{}\", entered as type={}", NodeName, conTypeStr))
                    ShowContinueError(state, String.format("In Field={}", InputFieldName))
                    ShowContinueError(state, String.format("NodeName=\"{}\", entered as type={}", NodeName, NodeConnectionTypeNamesUC[Int(ConnectionType)]))
                    ShowContinueError(state, String.format("In Field={}", InputFieldName))
                    ShowContinueError(state, String.format("Already used in {}=\"{}\".", objTypeStr, state.dataBranchNodeConnections.AirTerminalNodeConnections[Found - 1].ObjectName))
                    ShowContinueError(state, String.format(" as type={}, In Field={}", NodeConnectionTypeNamesUC[Int(state.dataBranchNodeConnections.AirTerminalNodeConnections[Found - 1].ConnectionType)], state.dataBranchNodeConnections.AirTerminalNodeConnections[Found - 1].InputFieldName))
                    ErrorsFoundHere = True
                else:
                    state.dataBranchNodeConnections.AirTerminalNodeConnections[state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1].NodeName = NodeName
                    state.dataBranchNodeConnections.AirTerminalNodeConnections[state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1].ObjectType = ObjectType
                    state.dataBranchNodeConnections.AirTerminalNodeConnections[state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1].ObjectName = ObjectName
                    state.dataBranchNodeConnections.AirTerminalNodeConnections[state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1].ConnectionType = ConnectionType
                    state.dataBranchNodeConnections.AirTerminalNodeConnections[state.dataBranchNodeConnections.NumOfAirTerminalNodes - 1].InputFieldName = InputFieldName
            else:
                ShowSevereError(state, String.Format("{}{} , Developer Error: Input Field Name not included.", RoutineName, objTypeStr))
                ShowContinueError(state, "Node names not checked for duplication.")
        if ErrorsFoundHere:
            errFlag = True

    @staticmethod
    def OverrideNodeConnectionType(
        inout state: EnergyPlusData,
        NodeNumber: Int,
        NodeName: String,
        ObjectType: ConnectionObjectType,
        ObjectName: String,
        ConnectionType: ConnectionType,
        FluidStream: CompFluidStream,
        IsParent: Bool,
        inout errFlag: Bool,
    ):
        alias RoutineName = "ModifyNodeConnectionType: "
        var objTypeStr: String = ConnectionObjectTypeNames[Int(ObjectType)]
        if (ConnectionType == ConnectionType.Invalid) or (ConnectionType == ConnectionType.Num):
            ShowSevereError(state, String.format("{}Invalid ConnectionType={}", RoutineName, Int(ConnectionType)))
            ShowContinueError(state, String.format("Occurs for Node={}, ObjectType={}, ObjectName={}", NodeName, objTypeStr, ObjectName))
            errFlag = True
        var Found: Int = 0
        for Count in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Count].NodeNumber != NodeNumber:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].ObjectType != ObjectType:
                continue
            if not SameString(state.dataBranchNodeConnections.NodeConnections[Count].ObjectName, ObjectName):
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].FluidStream != FluidStream:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Count].ObjectIsParent != IsParent:
                continue
            Found = Count + 1
            break
        if Found > 0:
            state.dataBranchNodeConnections.NodeConnections[Found - 1].ConnectionType = ConnectionType
        else:
            ShowSevereError(state, String.format("{}{}", RoutineName, "Existing node connection not found."))
            ShowContinueError(state, String.format("Occurs for Node={}, ObjectType={}, ObjectName={}", NodeName, objTypeStr, ObjectName))
            errFlag = True

    @staticmethod
    def CheckNodeConnections(inout state: EnergyPlusData, inout ErrorsFound: Bool):
        var IsValid: Bool
        var IsInlet: Bool
        var IsOutlet: Bool
        var MatchedAtLeastOne: Bool
        var ErrorCounter: Int
        var FluidStreamInletCount: List[Int]
        var FluidStreamOutletCount: List[Int]
        var NodeObjects: List[Int]
        var FluidStreamCounts: List[Bool]
        ErrorCounter = 0
        # First loop: Sensor
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.Sensor:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Actuator) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Sensor):
                    continue
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", Sensor node did not find a matching node of appropriate type (other than Actuator or Sensor).", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
                ErrorsFound = True
        # Second loop: Actuator
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.Actuator:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Actuator) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Sensor) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.OutsideAir):
                    continue
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", Actuator node did not find a matching node of appropriate type (other than Actuator, Sensor, OutsideAir).", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
                ErrorsFound = True
        # Third loop: SetPoint
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.SetPoint:
                continue
            IsValid = False
            IsInlet = False
            IsOutlet = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.SetPoint) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.OutsideAir):
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Inlet:
                    IsInlet = True
                elif state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Outlet:
                    IsOutlet = True
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", Setpoint node did not find a matching node of appropriate type (other than Setpoint, OutsideAir).", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
                ErrorsFound = True
            if not IsInlet and not IsOutlet:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", Setpoint node did not find a matching node of type Inlet or Outlet.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, "It appears this node is not part of the HVAC system.")
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
        # Fourth loop: ZoneInlet
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.ZoneInlet:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.Outlet:
                    continue
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", ZoneInlet node did not find an outlet node.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
        # Fifth loop: ZoneExhaust
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.ZoneExhaust:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.Inlet:
                    continue
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", ZoneExhaust node did not find a matching inlet node.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
        # Sixth loop: InducedAir
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.InducedAir:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.Inlet:
                    continue
                IsValid = True
            if not IsValid:
                ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", Return plenum induced air outlet node did not find a matching inlet node.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
                ErrorsFound = True
        # Seventh loop: Inlet (non-loop)
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.Inlet:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType == ConnectionObjectType.AirLoopHVAC or state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType == ConnectionObjectType.CondenserLoop or state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType == ConnectionObjectType.PlantLoop:
                continue
            IsValid = False
            MatchedAtLeastOne = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Outlet) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.ZoneReturn) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.ZoneExhaust) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.InducedAir) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.ReliefAir) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.OutsideAir):
                    MatchedAtLeastOne = True
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Inlet and (state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType == ConnectionObjectType.AirLoopHVAC or state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType == ConnectionObjectType.CondenserLoop or state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType == ConnectionObjectType.PlantLoop):
                    MatchedAtLeastOne = True
                    continue
                IsValid = False
            if not IsValid and not MatchedAtLeastOne:
                ShowSevereError(state, String.format("{}{}{}", "Node Connection Error, Node=\"", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName, "\", Inlet node did not find an appropriate matching \"outlet\" node."))
                ShowContinueError(state, "If this is an outdoor air inlet node, it must be listed in an OutdoorAir:Node or OutdoorAir:NodeList object.")
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
        # Eighth loop: duplicate non-parent Inlet nodes
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectIsParent:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.Inlet:
                continue
            for Loop2 in range(Loop1, state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectIsParent:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.Inlet:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber == state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber:
                    ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", The same node appears as a non-parent Inlet node more than once.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                    ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                    ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectName))
                    ErrorCounter += 1
                    break
        # Ninth loop: duplicate non-parent Outlet nodes
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectIsParent:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.Outlet:
                continue
            IsValid = True
            for Loop2 in range(Loop1, state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectIsParent:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.Outlet:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber == state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber:
                    ShowSevereError(state, String.format("Node Connection Error, Node=\"{}\", The same node appears as a non-parent Outlet node more than once.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                    ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                    ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectName))
                    ErrorCounter += 1
                    break
        # Tenth loop: OutsideAirReference
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.OutsideAirReference:
                continue
            IsValid = False
            for Loop2 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeNumber != state.dataBranchNodeConnections.NodeConnections[Loop2].NodeNumber:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType != ConnectionType.OutsideAir:
                    continue
                IsValid = True
                break
            if not IsValid:
                ShowSevereError(state, String.format("{}{}{}", "Node Connection Error, Node=\"", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName, "\", Outdoor Air Reference did not find an appropriate \"outdoor air\" node."))
                ShowContinueError(state, "This node must be listed in an OutdoorAir:Node or OutdoorAir:NodeList object in order to set its conditions.")
                ShowContinueError(state, String.format("Reference Object={}, Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                ErrorCounter += 1
        # FluidStream consistency check
        if state.dataBranchNodeConnections.NumOfNodeConnections > 0:
            var MaxFluidStream: Int = 0
            for i in range(state.dataBranchNodeConnections.NumOfNodeConnections):
                if Int(state.dataBranchNodeConnections.NodeConnections[i].FluidStream) > MaxFluidStream:
                    MaxFluidStream = Int(state.dataBranchNodeConnections.NodeConnections[i].FluidStream)
            # allocate lists 1-based to match C++ (indices 1..MaxFluidStream)
            FluidStreamInletCount = List[Int]([0]) * (MaxFluidStream + 1)  # index 0 unused
            FluidStreamOutletCount = List[Int]([0]) * (MaxFluidStream + 1)
            FluidStreamCounts = List[Bool]([False]) * (MaxFluidStream + 1)
            NodeObjects = List[Int]()
            NodeObjects.append(0)  # dummy for 1-based
            # Build NodeObjects (1-based indices)
            var Object: Int = 1
            var EndConnect: Int = 0
            var NumObjects: Int = 2
            NodeObjects.append(1)
            while Object < state.dataBranchNodeConnections.NumOfNodeConnections:
                if (state.dataBranchNodeConnections.NodeConnections[Object - 1].ObjectType != state.dataBranchNodeConnections.NodeConnections[Object].ObjectType) or (state.dataBranchNodeConnections.NodeConnections[Object - 1].ObjectName != state.dataBranchNodeConnections.NodeConnections[Object].ObjectName):
                    EndConnect = Object + 1
                    NodeObjects.append(EndConnect)
                    NumObjects += 1
                Object += 1
            NodeObjects.append(state.dataBranchNodeConnections.NumOfNodeConnections + 1)
            for Object in range(1, NumObjects):
                IsValid = True
                # reset counts (1-based)
                for i in range(1, MaxFluidStream + 1):
                    FluidStreamInletCount[i] = 0
                    FluidStreamOutletCount[i] = 0
                    FluidStreamCounts[i] = False
                var Loop1: Int = NodeObjects[Object - 1]
                if state.dataBranchNodeConnections.NumOfNodeConnections < 2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].ObjectIsParent:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].ConnectionType == ConnectionType.Inlet:
                    FluidStreamInletCount[Int(state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].FluidStream)] += 1
                elif state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].ConnectionType == ConnectionType.Outlet:
                    FluidStreamOutletCount[Int(state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].FluidStream)] += 1
                for Loop2 in range(Loop1, NodeObjects[Object] - 1):
                    if state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectIsParent:
                        continue
                    if state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Inlet:
                        FluidStreamInletCount[Int(state.dataBranchNodeConnections.NodeConnections[Loop2].FluidStream)] += 1
                    elif state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Outlet:
                        FluidStreamOutletCount[Int(state.dataBranchNodeConnections.NodeConnections[Loop2].FluidStream)] += 1
                for Loop2 in range(1, MaxFluidStream + 1):
                    if FluidStreamInletCount[Loop2] > 1 and FluidStreamOutletCount[Loop2] > 1:
                        IsValid = False
                        FluidStreamCounts[Loop2] = True
                if not IsValid:
                    ShowSevereError(state, String.format("(Developer) Node Connection Error, Object={}:{}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1 - 1].ObjectName))
                    ShowContinueError(state, "Object has multiple connections on both inlet and outlet fluid streams.")
                    for Loop2 in range(1, MaxFluidStream + 1):
                        if FluidStreamCounts[Loop2]:
                            ShowContinueError(state, String.format("...occurs in Fluid Stream [{}].", Loop2))
                    ErrorCounter += 1
                    ErrorsFound = True
        # Eleventh loop: ZoneNode duplicates
        for Loop1 in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop1].ConnectionType != ConnectionType.ZoneNode:
                continue
            IsValid = True
            for Loop2 in range(Loop1, state.dataBranchNodeConnections.NumOfNodeConnections):
                if Loop1 == Loop2:
                    continue
                if state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName == state.dataBranchNodeConnections.NodeConnections[Loop2].NodeName:
                    if (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Actuator) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.Sensor) or (state.dataBranchNodeConnections.NodeConnections[Loop2].ConnectionType == ConnectionType.SetPoint):
                        continue
                    ShowSevereError(state, String.format("Node Connection Error, Node Name=\"{}\", The same zone node appears more than once.", state.dataBranchNodeConnections.NodeConnections[Loop1].NodeName))
                    ShowContinueError(state, String.format("Reference Object={}, Object Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop1].ObjectName))
                    ShowContinueError(state, String.format("Reference Object={}, Object Name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectType)], state.dataBranchNodeConnections.NodeConnections[Loop2].ObjectName))
                    ErrorCounter += 1
                    ErrorsFound = True
        state.dataBranchNodeConnections.NumNodeConnectionErrors += ErrorCounter

    @staticmethod
    def IsParentObject(state: EnergyPlusData, ComponentType: ConnectionObjectType, ComponentName: String) -> Bool:
        var IsParent: Bool = False
        for Loop in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Loop].ObjectType == ComponentType and state.dataBranchNodeConnections.NodeConnections[Loop].ObjectName == ComponentName:
                if state.dataBranchNodeConnections.NodeConnections[Loop].ObjectIsParent:
                    IsParent = True
                break
        if not IsParent:
            IsParent = Node.IsParentObjectCompSet(state, ComponentType, ComponentName)
        return IsParent

    @staticmethod
    def WhichParentSet(state: EnergyPlusData, ComponentType: ConnectionObjectType, ComponentName: String) -> Int:
        var WhichOne: Int = 0
        for Loop in range(state.dataBranchNodeConnections.NumOfActualParents):
            if state.dataBranchNodeConnections.ParentNodeList[Loop].ComponentType == ComponentType and state.dataBranchNodeConnections.ParentNodeList[Loop].ComponentName == ComponentName:
                WhichOne = Loop + 1
                break
        return WhichOne

    @staticmethod
    def GetParentData(
        state: EnergyPlusData,
        ComponentType: ConnectionObjectType,
        ComponentName: String,
        inout InletNodeName: String,
        inout InletNodeNum: Int,
        inout OutletNodeName: String,
        inout OutletNodeNum: Int,
        inout ErrorsFound: Bool,
    ):
        var ErrInObject: Bool = False
        InletNodeName = String()
        InletNodeNum = 0
        OutletNodeName = String()
        OutletNodeNum = 0
        ErrInObject = False
        var Which: Int = Node.WhichParentSet(state, ComponentType, ComponentName)
        if Which != 0:
            InletNodeName = state.dataBranchNodeConnections.ParentNodeList[Which - 1].InletNodeName
            OutletNodeName = state.dataBranchNodeConnections.ParentNodeList[Which - 1].OutletNodeName
            InletNodeNum = FindItemInList(InletNodeName, state.dataLoopNodes.NodeID[0:state.dataLoopNodes.NumOfNodes], state.dataLoopNodes.NumOfNodes)
            OutletNodeNum = FindItemInList(OutletNodeName, state.dataLoopNodes.NodeID[0:state.dataLoopNodes.NumOfNodes], state.dataLoopNodes.NumOfNodes)
        elif Node.IsParentObjectCompSet(state, ComponentType, ComponentName):
            Which = Node.WhichCompSet(state, ComponentType, ComponentName)
            if Which != 0:
                InletNodeName = state.dataBranchNodeConnections.CompSets[Which - 1].InletNodeName
                OutletNodeName = state.dataBranchNodeConnections.CompSets[Which - 1].OutletNodeName
                InletNodeNum = FindItemInList(InletNodeName, state.dataLoopNodes.NodeID[0:state.dataLoopNodes.NumOfNodes], state.dataLoopNodes.NumOfNodes)
                OutletNodeNum = FindItemInList(OutletNodeName, state.dataLoopNodes.NodeID[0:state.dataLoopNodes.NumOfNodes], state.dataLoopNodes.NumOfNodes)
            else:
                ErrInObject = True
                ShowWarningError(state, String.format("GetParentData: Component Type={}, Component Name={} not found.", ConnectionObjectTypeNames[Int(ComponentType)], ComponentName))
        else:
            ErrInObject = True
            ShowWarningError(state, String.format("GetParentData: Component Type={}, Component Name={} not found.", ConnectionObjectTypeNames[Int(ComponentType)], ComponentName))
        if ErrInObject:
            ErrorsFound = True

    @staticmethod
    def IsParentObjectCompSet(state: EnergyPlusData, ComponentType: ConnectionObjectType, ComponentName: String) -> Bool:
        var IsParent: Bool = False
        for Loop in range(state.dataBranchNodeConnections.NumCompSets):
            if state.dataBranchNodeConnections.CompSets[Loop].ParentObjectType == ComponentType and state.dataBranchNodeConnections.CompSets[Loop].ParentCName == ComponentName:
                IsParent = True
                break
        return IsParent

    @staticmethod
    def WhichCompSet(state: EnergyPlusData, ComponentType: ConnectionObjectType, ComponentName: String) -> Int:
        var WhichOne: Int = 0
        for Loop in range(state.dataBranchNodeConnections.NumCompSets):
            if state.dataBranchNodeConnections.CompSets[Loop].ComponentObjectType == ComponentType and state.dataBranchNodeConnections.CompSets[Loop].CName == ComponentName:
                WhichOne = Loop + 1
                break
        return WhichOne

    @staticmethod
    def GetNumChildren(state: EnergyPlusData, ComponentType: ConnectionObjectType, ComponentName: String) -> Int:
        var NumChildren: Int = 0
        if Node.IsParentObject(state, ComponentType, ComponentName):
            for Loop in range(state.dataBranchNodeConnections.NumCompSets):
                if state.dataBranchNodeConnections.CompSets[Loop].ParentObjectType == ComponentType and state.dataBranchNodeConnections.CompSets[Loop].ParentCName == ComponentName:
                    NumChildren += 1
        return NumChildren

    @staticmethod
    def GetComponentData(
        state: EnergyPlusData,
        ComponentType: ConnectionObjectType,
        ComponentName: String,
        inout IsParent: Bool,
        inout NumInlets: Int,
        inout InletNodeNames: List[String],
        inout InletNodeNums: List[Int],
        inout InletFluidStreams: List[CompFluidStream],
        inout NumOutlets: Int,
        inout OutletNodeNames: List[String],
        inout OutletNodeNums: List[Int],
        inout OutletFluidStreams: List[CompFluidStream],
    ):
        # deallocate if previously allocated (Mojo list uses clear)
        InletNodeNames = List[String]()
        InletNodeNums = List[Int]()
        InletFluidStreams = List[CompFluidStream]()
        OutletNodeNames = List[String]()
        OutletNodeNums = List[Int]()
        OutletFluidStreams = List[CompFluidStream]()
        NumInlets = 0
        NumOutlets = 0
        IsParent = False
        for Which in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Which].ObjectType != ComponentType or state.dataBranchNodeConnections.NodeConnections[Which].ObjectName != ComponentName:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Which].ObjectIsParent:
                IsParent = True
            if state.dataBranchNodeConnections.NodeConnections[Which].ConnectionType == ConnectionType.Inlet:
                NumInlets += 1
            elif state.dataBranchNodeConnections.NodeConnections[Which].ConnectionType == ConnectionType.Outlet:
                NumOutlets += 1
        # allocate lists with default values
        InletNodeNames = List[String]([String()]) * NumInlets
        InletNodeNums = List[Int]([0]) * NumInlets
        InletFluidStreams = List[CompFluidStream]([CompFluidStream.Invalid]) * NumInlets
        OutletNodeNames = List[String]([String()]) * NumOutlets
        OutletNodeNums = List[Int]([0]) * NumOutlets
        OutletFluidStreams = List[CompFluidStream]([CompFluidStream.Invalid]) * NumOutlets
        NumInlets = 0
        NumOutlets = 0
        for Which in range(state.dataBranchNodeConnections.NumOfNodeConnections):
            if state.dataBranchNodeConnections.NodeConnections[Which].ObjectType != ComponentType or state.dataBranchNodeConnections.NodeConnections[Which].ObjectName != ComponentName:
                continue
            if state.dataBranchNodeConnections.NodeConnections[Which].ConnectionType == ConnectionType.Inlet:
                InletNodeNames[NumInlets] = state.dataBranchNodeConnections.NodeConnections[Which].NodeName
                InletNodeNums[NumInlets] = state.dataBranchNodeConnections.NodeConnections[Which].NodeNumber
                InletFluidStreams[NumInlets] = state.dataBranchNodeConnections.NodeConnections[Which].FluidStream
                NumInlets += 1
            elif state.dataBranchNodeConnections.NodeConnections[Which].ConnectionType == ConnectionType.Outlet:
                OutletNodeNames[NumOutlets] = state.dataBranchNodeConnections.NodeConnections[Which].NodeName
                OutletNodeNums[NumOutlets] = state.dataBranchNodeConnections.NodeConnections[Which].NodeNumber
                OutletFluidStreams[NumOutlets] = state.dataBranchNodeConnections.NodeConnections[Which].FluidStream
                NumOutlets += 1

    @staticmethod
    def GetChildrenData(
        state: EnergyPlusData,
        ComponentType: ConnectionObjectType,
        ComponentName: String,
        inout NumChildren: Int,
        inout ChildrenCType: List[ConnectionObjectType],
        inout ChildrenCName: List[String],
        inout InletNodeName: List[String],
        inout InletNodeNum: List[Int],
        inout OutletNodeName: List[String],
        inout OutletNodeNum: List[Int],
        inout ErrorsFound: Bool,
    ):
        var ChildCType: List[ConnectionObjectType]
        var ChildCName: List[String]
        var ChildInNodeName: List[String]
        var ChildOutNodeName: List[String]
        var ChildInNodeNum: List[Int]
        var ChildOutNodeNum: List[Int]
        var ChildMatched: List[Bool]
        var ErrInObject: Bool = False
        # fill output arrays with defaults
        for i in range(len(ChildrenCType)):
            ChildrenCType[i] = ConnectionObjectType.Invalid
        for i in range(len(ChildrenCName)):
            ChildrenCName[i] = String()
        for i in range(len(InletNodeName)):
            InletNodeName[i] = String()
        for i in range(len(InletNodeNum)):
            InletNodeNum[i] = 0
        for i in range(len(OutletNodeName)):
            OutletNodeName[i] = String()
        for i in range(len(OutletNodeNum)):
            OutletNodeNum[i] = 0
        if not Node.IsParentObject(state, ComponentType, ComponentName):
            ShowWarningError(state, String.format("GetChildrenData: Requested Children Data for non Parent Node={}:{}.", ConnectionObjectTypeNames[Int(ComponentType)], ComponentName))
            ErrorsFound = True
        elif (Node.GetNumChildren(state, ComponentType, ComponentName)) == 0:
            NumChildren = 0
            ShowWarningError(state, String.format("GetChildrenData: Parent Node has no children, node={}:{}.", ConnectionObjectTypeNames[Int(ComponentType)], ComponentName))
        else:
            NumChildren = Node.GetNumChildren(state, ComponentType, ComponentName)
            var ParentInletNodeNum: Int
            var ParentOutletNodeNum: Int
            var ParentInletNodeName: String
            var ParentOutletNodeName: String
            Node.GetParentData(state, ComponentType, ComponentName, ParentInletNodeName, ParentInletNodeNum, ParentOutletNodeName, ParentOutletNodeNum, ErrInObject)
            ChildCType = List[ConnectionObjectType]([ConnectionObjectType.Invalid]) * NumChildren
            ChildCName = List[String]([String()]) * NumChildren
            ChildInNodeName = List[String]([String()]) * NumChildren
            ChildOutNodeName = List[String]([String()]) * NumChildren
            ChildInNodeNum = List[Int]([0]) * NumChildren
            ChildOutNodeNum = List[Int]([0]) * NumChildren
            ChildMatched = List[Bool]([False]) * NumChildren
            var CountNum: Int = 0
            for Loop in range(state.dataBranchNodeConnections.NumCompSets):
                var compSet = state.dataBranchNodeConnections.CompSets[Loop]
                if compSet.ParentObjectType == ComponentType and compSet.ParentCName == ComponentName:
                    ChildCType[CountNum] = compSet.ComponentObjectType
                    ChildCName[CountNum] = compSet.CName
                    ChildInNodeName[CountNum] = compSet.InletNodeName
                    ChildOutNodeName[CountNum] = compSet.OutletNodeName
                    ChildInNodeNum[CountNum] = FindItemInList(ChildInNodeName[CountNum], state.dataLoopNodes.NodeID)
                    ChildOutNodeNum[CountNum] = FindItemInList(ChildOutNodeName[CountNum], state.dataLoopNodes.NodeID)
                    CountNum += 1
            if CountNum != NumChildren:
                ShowSevereError(state, "GetChildrenData: Counted nodes not equal to GetNumChildren count")
                ErrorsFound = True
            else:
                var ParentInletNodeIndex: Int = 0
                for Loop in range(NumChildren):
                    if ChildInNodeNum[Loop] == ParentInletNodeNum:
                        ParentInletNodeIndex = Loop + 1
                        break
                var ParentOutletNodeIndex: Int = 0
                for Loop in range(NumChildren):
                    if ChildOutNodeNum[Loop] == ParentOutletNodeNum:
                        ParentOutletNodeIndex = Loop + 1
                        break
                if ParentInletNodeIndex > 0:
                    var MatchInNodeNum: Int = ParentInletNodeNum
                    CountNum = 0
                    while CountNum < NumChildren:
                        var MatchInNodeIndex: Int = 0
                        for Loop in range(NumChildren):
                            if ChildInNodeNum[Loop] == MatchInNodeNum and not ChildMatched[Loop]:
                                MatchInNodeIndex = Loop + 1
                                break
                        if MatchInNodeIndex == 0:
                            break
                        CountNum += 1
                        ChildrenCType[CountNum - 1] = ChildCType[MatchInNodeIndex - 1]
                        ChildrenCName[CountNum - 1] = ChildCName[MatchInNodeIndex - 1]
                        InletNodeName[CountNum - 1] = ChildInNodeName[MatchInNodeIndex - 1]
                        InletNodeNum[CountNum - 1] = ChildInNodeNum[MatchInNodeIndex - 1]
                        OutletNodeName[CountNum - 1] = ChildOutNodeName[MatchInNodeIndex - 1]
                        OutletNodeNum[CountNum - 1] = ChildOutNodeNum[MatchInNodeIndex - 1]
                        ChildMatched[MatchInNodeIndex - 1] = True
                        MatchInNodeNum = ChildOutNodeNum[MatchInNodeIndex - 1]
                    for Loop in range(NumChildren):
                        if ChildMatched[Loop]:
                            continue
                        CountNum += 1
                        ChildrenCType[CountNum - 1] = ChildCType[Loop]
                        ChildrenCName[CountNum - 1] = ChildCName[Loop]
                        InletNodeName[CountNum - 1] = ChildInNodeName[Loop]
                        InletNodeNum[CountNum - 1] = ChildInNodeNum[Loop]
                        OutletNodeName[CountNum - 1] = ChildOutNodeName[Loop]
                        OutletNodeNum[CountNum - 1] = ChildOutNodeNum[Loop]
                elif ParentOutletNodeIndex > 0:
                    var MatchOutNodeNum: Int = ParentOutletNodeNum
                    CountNum = NumChildren + 1
                    while CountNum > 1:
                        var MatchOutNodeIndex: Int = 0
                        for Loop in range(NumChildren):
                            if ChildOutNodeNum[Loop] == MatchOutNodeNum and not ChildMatched[Loop]:
                                MatchOutNodeIndex = Loop + 1
                                break
                        if MatchOutNodeIndex == 0:
                            break
                        CountNum -= 1
                        ChildrenCType[CountNum - 1] = ChildCType[MatchOutNodeIndex - 1]
                        ChildrenCName[CountNum - 1] = ChildCName[MatchOutNodeIndex - 1]
                        InletNodeName[CountNum - 1] = ChildInNodeName[MatchOutNodeIndex - 1]
                        InletNodeNum[CountNum - 1] = ChildInNodeNum[MatchOutNodeIndex - 1]
                        OutletNodeName[CountNum - 1] = ChildOutNodeName[MatchOutNodeIndex - 1]
                        OutletNodeNum[CountNum - 1] = ChildOutNodeNum[MatchOutNodeIndex - 1]
                        ChildMatched[MatchOutNodeIndex - 1] = True
                        MatchOutNodeNum = ChildInNodeNum[MatchOutNodeIndex - 1]
                    CountNum = 0
                    for Loop in range(NumChildren):
                        if ChildMatched[Loop]:
                            continue
                        ChildrenCType[CountNum] = ChildCType[Loop]
                        ChildrenCName[CountNum] = ChildCName[Loop]
                        InletNodeName[CountNum] = ChildInNodeName[Loop]
                        InletNodeNum[CountNum] = ChildInNodeNum[Loop]
                        OutletNodeName[CountNum] = ChildOutNodeName[Loop]
                        OutletNodeNum[CountNum] = ChildOutNodeNum[Loop]
                        CountNum += 1
                else:
                    for Loop in range(NumChildren):
                        if ChildMatched[Loop]:
                            continue
                        ChildrenCType[Loop] = ChildCType[Loop]
                        ChildrenCName[Loop] = ChildCName[Loop]
                        InletNodeName[Loop] = ChildInNodeName[Loop]
                        InletNodeNum[Loop] = ChildInNodeNum[Loop]
                        OutletNodeName[Loop] = ChildOutNodeName[Loop]
                        OutletNodeNum[Loop] = ChildOutNodeNum[Loop]
        if ErrInObject:
            ErrorsFound = True

    @staticmethod
    def SetUpCompSets(
        inout state: EnergyPlusData,
        ParentType: String,
        ParentName: String,
        CompType: String,
        CompName: String,
        InletNode: String,
        OutletNode: String,
        Description: String = String(),
    ):
        var ParentTypeUC: String = makeUPPER(ParentType)
        var CompTypeUC: String = makeUPPER(CompType)
        var ParentTypeEnum: ConnectionObjectType = ConnectionObjectType(getEnumValue(ConnectionObjectTypeNamesUC, ParentTypeUC))
        # assert
        if ParentTypeEnum == ConnectionObjectType.Invalid:
            print("Assertion failed: ParentTypeEnum != Invalid")
            # In Mojo, we can't easily halt, but we can raise an error or use __assert_fail
        var ComponentTypeEnum: ConnectionObjectType = ConnectionObjectType(getEnumValue(ConnectionObjectTypeNamesUC, CompTypeUC))
        if ComponentTypeEnum == ConnectionObjectType.Invalid:
            print("Assertion failed: ComponentTypeEnum != Invalid")
        var Found: Int = 0
        for Count in range(state.dataBranchNodeConnections.NumCompSets):
            if CompName != state.dataBranchNodeConnections.CompSets[Count].CName:
                continue
            if ComponentTypeEnum != ConnectionObjectType.Undefined:
                if ComponentTypeEnum != state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType:
                    continue
            if InletNode != undefined:
                if state.dataBranchNodeConnections.CompSets[Count].InletNodeName != undefined:
                    if InletNode != state.dataBranchNodeConnections.CompSets[Count].InletNodeName:
                        continue
                else:
                    state.dataBranchNodeConnections.CompSets[Count].InletNodeName = InletNode
            if OutletNode != undefined:
                if state.dataBranchNodeConnections.CompSets[Count].OutletNodeName != undefined:
                    if OutletNode != state.dataBranchNodeConnections.CompSets[Count].OutletNodeName:
                        continue
                else:
                    state.dataBranchNodeConnections.CompSets[Count].OutletNodeName = OutletNode
            if state.dataBranchNodeConnections.CompSets[Count].ParentObjectType == ConnectionObjectType.Undefined and state.dataBranchNodeConnections.CompSets[Count].ParentCName == undefined:
                state.dataBranchNodeConnections.CompSets[Count].ParentObjectType = ParentTypeEnum
                state.dataBranchNodeConnections.CompSets[Count].ParentCName = ParentName
                if not Description.empty():
                    state.dataBranchNodeConnections.CompSets[Count].Description = Description
                Found = Count + 1
                break
        if Found == 0:
            for Count in range(state.dataBranchNodeConnections.NumCompSets):
                Found = 0
                if InletNode != state.dataBranchNodeConnections.CompSets[Count].InletNodeName:
                    continue
                if (ParentTypeEnum == ConnectionObjectType.Undefined) or (state.dataBranchNodeConnections.CompSets[Count].ParentObjectType == ConnectionObjectType.Undefined):

                elif InletNode != undefined:
                    if (ParentTypeEnum == state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType) and (ParentName == state.dataBranchNodeConnections.CompSets[Count].CName):

                    elif (ComponentTypeEnum == state.dataBranchNodeConnections.CompSets[Count].ParentObjectType) and (CompName == state.dataBranchNodeConnections.CompSets[Count].ParentCName):

                    else:
                        var Found2: Int = 0
                        for Count2 in range(state.dataBranchNodeConnections.NumCompSets):
                            if (state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType == state.dataBranchNodeConnections.CompSets[Count2].ParentObjectType) and (state.dataBranchNodeConnections.CompSets[Count].CName == state.dataBranchNodeConnections.CompSets[Count2].ParentCName):
                                Found2 = 1
                            if (ComponentTypeEnum == state.dataBranchNodeConnections.CompSets[Count2].ParentObjectType) and (CompName == state.dataBranchNodeConnections.CompSets[Count2].ParentCName):
                                Found2 = 1
                        if Found2 == 0:
                            ShowWarningError(state, String.format("Node used as an inlet more than once: {}", InletNode))
                            ShowContinueError(state, String.format("  Used by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Count].ParentCName))
                            ShowContinueError(state, String.format("  as inlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Count].CName))
                            ShowContinueError(state, String.format("{}{}{}", "  and  by     : ", ParentTypeUC + ", name=" + ParentName))
                            ShowContinueError(state, String.format("{}{}{}", "  as inlet for: ", CompTypeUC + ", name=" + CompName))
                if OutletNode != state.dataBranchNodeConnections.CompSets[Count].OutletNodeName:
                    continue
                if (ParentTypeEnum == ConnectionObjectType.Undefined) or (state.dataBranchNodeConnections.CompSets[Count].ParentObjectType == ConnectionObjectType.Undefined):

                elif OutletNode != undefined:
                    if (ParentTypeEnum == state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType) and (ParentName == state.dataBranchNodeConnections.CompSets[Count].CName):

                    elif (ComponentTypeEnum == state.dataBranchNodeConnections.CompSets[Count].ParentObjectType) and (CompName == state.dataBranchNodeConnections.CompSets[Count].ParentCName):

                    else:
                        var Found2: Int = 0
                        for Count2 in range(state.dataBranchNodeConnections.NumCompSets):
                            if (state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType == state.dataBranchNodeConnections.CompSets[Count2].ParentObjectType) and (state.dataBranchNodeConnections.CompSets[Count].CName == state.dataBranchNodeConnections.CompSets[Count2].ParentCName):
                                Found2 = 1
                            if (ComponentTypeEnum == state.dataBranchNodeConnections.CompSets[Count2].ParentObjectType) and (CompName == state.dataBranchNodeConnections.CompSets[Count2].ParentCName):
                                Found2 = 1
                        if Found2 == 0:
                            var CType: String = ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)]
                            if (not has_prefixi(CType, "AirTerminal:DualDuct:")) and (not has_prefixi(CompTypeUC, "AirTerminal:DualDuct:")):
                                ShowWarningError(state, String.format("Node used as an outlet more than once: {}", OutletNode))
                                ShowContinueError(state, String.format("  Used by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Count].ParentCName))
                                ShowContinueError(state, String.format("  as outlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Count].CName))
                                ShowContinueError(state, String.format("{}{}{}", "  and  by     : ", ParentTypeUC + ", name=" + ParentName))
                                ShowContinueError(state, String.format("{}{}{}", "  as outlet for: ", CompTypeUC + ", name=" + CompName))
                if ComponentTypeEnum != state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType and ComponentTypeEnum != ConnectionObjectType.Undefined:
                    continue
                if CompName != state.dataBranchNodeConnections.CompSets[Count].CName:
                    continue
                Found = Count + 1
                break
        if Found == 0:
            state.dataBranchNodeConnections.NumCompSets += 1
            state.dataBranchNodeConnections.CompSets.append(CompSetData())
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].ParentObjectType = ParentTypeEnum
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].ParentCName = ParentName
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].ComponentObjectType = ComponentTypeEnum
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].CName = CompName
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].InletNodeName = makeUPPER(InletNode)
            state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].OutletNodeName = makeUPPER(OutletNode)
            if not Description.empty():
                state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].Description = Description
            else:
                state.dataBranchNodeConnections.CompSets[state.dataBranchNodeConnections.NumCompSets - 1].Description = undefined

    @staticmethod
    def TestInletOutletNodes(state: EnergyPlusData):
        var AlreadyNoted: List[Bool] = List[Bool]([False]) * state.dataBranchNodeConnections.NumCompSets
        for Count in range(state.dataBranchNodeConnections.NumCompSets):
            for Other in range(state.dataBranchNodeConnections.NumCompSets):
                if Count == Other:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].InletNodeName != state.dataBranchNodeConnections.CompSets[Other].InletNodeName:
                    continue
                if AlreadyNoted[Count]:
                    continue
                if (state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType != state.dataBranchNodeConnections.CompSets[Other].ComponentObjectType) or (state.dataBranchNodeConnections.CompSets[Count].CName != state.dataBranchNodeConnections.CompSets[Other].CName) or (state.dataBranchNodeConnections.CompSets[Count].OutletNodeName != state.dataBranchNodeConnections.CompSets[Other].OutletNodeName):
                    AlreadyNoted[Other] = True
                    ShowWarningError(state, String.format("Node used as an inlet more than once: {}", state.dataBranchNodeConnections.CompSets[Count].InletNodeName))
                    ShowContinueError(state, String.format("  Used by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Count].ParentCName))
                    ShowContinueError(state, String.format("  as inlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Other].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Other].CName))
                    ShowContinueError(state, String.format("  and by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Other].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Other].ParentCName))
                    ShowContinueError(state, String.format("  as inlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Count].CName))
        # reset AlreadyNoted
        AlreadyNoted = List[Bool]([False]) * state.dataBranchNodeConnections.NumCompSets
        for Count in range(state.dataBranchNodeConnections.NumCompSets):
            for Other in range(state.dataBranchNodeConnections.NumCompSets):
                if Count == Other:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].OutletNodeName != state.dataBranchNodeConnections.CompSets[Other].OutletNodeName:
                    continue
                if AlreadyNoted[Count]:
                    continue
                if (state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType != state.dataBranchNodeConnections.CompSets[Other].ComponentObjectType) or (state.dataBranchNodeConnections.CompSets[Count].CName != state.dataBranchNodeConnections.CompSets[Other].CName) or (state.dataBranchNodeConnections.CompSets[Count].InletNodeName != state.dataBranchNodeConnections.CompSets[Other].InletNodeName):
                    AlreadyNoted[Other] = True
                    ShowWarningError(state, String.format("Node used as an outlet more than once: {}", state.dataBranchNodeConnections.CompSets[Count].OutletNodeName))
                    ShowContinueError(state, String.format("  Used by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Count].ParentCName))
                    ShowContinueError(state, String.format("  as outlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Other].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Other].CName))
                    ShowContinueError(state, String.format("  and by: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Other].ParentObjectType)], state.dataBranchNodeConnections.CompSets[Other].ParentCName))
                    ShowContinueError(state, String.format("  as outlet for: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Count].CName))

    @staticmethod
    def TestCompSet(
        state: EnergyPlusData,
        CompType: String,
        CompName: String,
        InletNode: String,
        OutletNode: String,
        Description: String,
    ):
        var CompTypeUC: String = makeUPPER(CompType)
        var ComponentTypeEnum: ConnectionObjectType = ConnectionObjectType(getEnumValue(ConnectionObjectTypeNamesUC, CompTypeUC))
        if ComponentTypeEnum == ConnectionObjectType.Invalid:
            print("Assertion failed: ComponentTypeEnum != Invalid")
        var Found: Int = 0
        for Count in range(state.dataBranchNodeConnections.NumCompSets):
            if (ComponentTypeEnum != state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType) and (state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType != ConnectionObjectType.Undefined):
                continue
            if CompName != state.dataBranchNodeConnections.CompSets[Count].CName:
                continue
            if (InletNode != state.dataBranchNodeConnections.CompSets[Count].InletNodeName) and (state.dataBranchNodeConnections.CompSets[Count].InletNodeName != undefined) and (InletNode != undefined):
                continue
            if (OutletNode != state.dataBranchNodeConnections.CompSets[Count].OutletNodeName) and (state.dataBranchNodeConnections.CompSets[Count].OutletNodeName != undefined) and (OutletNode != undefined):
                continue
            Found = Count + 1
            break
        if Found == 0:
            Node.SetUpCompSets(state, undefined, undefined, CompType, CompName, InletNode, OutletNode, Description)
        else:
            if state.dataBranchNodeConnections.CompSets[Found - 1].ComponentObjectType == ConnectionObjectType.Undefined:
                state.dataBranchNodeConnections.CompSets[Found - 1].ComponentObjectType = ComponentTypeEnum
            if state.dataBranchNodeConnections.CompSets[Found - 1].InletNodeName == undefined:
                state.dataBranchNodeConnections.CompSets[Found - 1].InletNodeName = InletNode
            if state.dataBranchNodeConnections.CompSets[Found - 1].OutletNodeName == undefined:
                state.dataBranchNodeConnections.CompSets[Found - 1].OutletNodeName = OutletNode
            if state.dataBranchNodeConnections.CompSets[Found - 1].Description == undefined:
                state.dataBranchNodeConnections.CompSets[Found - 1].Description = Description

    @staticmethod
    def TestCompSetInletOutletNodes(state: EnergyPlusData, inout ErrorsFound: Bool):
        var AlreadyNoted: List[Bool] = List[Bool]([False]) * state.dataBranchNodeConnections.NumCompSets
        for Count in range(state.dataBranchNodeConnections.NumCompSets):
            for Other in range(state.dataBranchNodeConnections.NumCompSets):
                if Count == Other:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType == ConnectionObjectType.SolarCollectorUnglazedTranspired:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType != state.dataBranchNodeConnections.CompSets[Other].ComponentObjectType or state.dataBranchNodeConnections.CompSets[Count].CName != state.dataBranchNodeConnections.CompSets[Other].CName:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].Description != state.dataBranchNodeConnections.CompSets[Other].Description:
                    if state.dataBranchNodeConnections.CompSets[Count].Description != undefined and state.dataBranchNodeConnections.CompSets[Other].Description != undefined:
                        continue
                if state.dataBranchNodeConnections.CompSets[Count].InletNodeName == state.dataBranchNodeConnections.CompSets[Other].InletNodeName:
                    continue
                if state.dataBranchNodeConnections.CompSets[Count].OutletNodeName == state.dataBranchNodeConnections.CompSets[Other].OutletNodeName:
                    continue
                if AlreadyNoted[Count]:
                    continue
                AlreadyNoted[Other] = True
                ShowSevereError(state, "Same component name and type has differing Node Names.")
                ShowContinueError(state, String.format("  Component: {}, name={}", ConnectionObjectTypeNames[Int(state.dataBranchNodeConnections.CompSets[Count].ComponentObjectType)], state.dataBranchNodeConnections.CompSets[Count].CName))
                ShowContinueError(state, String.format("   Nodes, inlet: {}, outlet: {}", state.dataBranchNodeConnections.CompSets[Count].InletNodeName, state.dataBranchNodeConnections.CompSets[Count].OutletNodeName))
                ShowContinueError(state, String.format(" & Nodes, inlet: {}, outlet: {}", state.dataBranchNodeConnections.CompSets[Other].InletNodeName, state.dataBranchNodeConnections.CompSets[Other].OutletNodeName))
                ShowContinueError(state, String.format("   Node Types:   {} & {}", state.dataBranchNodeConnections.CompSets[Count].Description, state.dataBranchNodeConnections.CompSets[Other].Description))
                ErrorsFound = True

    @staticmethod
    def GetNodeConnectionType(
        state: EnergyPlusData,
        NodeNumber: Int,
        inout NodeConnectType: List[ConnectionType],
        inout errFlag: Bool,
    ):
        var ListArray: List[Int]
        var ConnectionTypes: List[String] = List[String]([String()]) * 15
        for nodetype in range(1, Int(ConnectionType.Num)):
            ConnectionTypes[nodetype - 1] = NodeConnectionTypeNames[nodetype]
        NodeConnectType = List[ConnectionType]()
        var NumInList: Int = 0
        Node.FindAllNodeNumbersInList(NodeNumber, state.dataBranchNodeConnections.NodeConnections, state.dataBranchNodeConnections.NumOfNodeConnections, NumInList, ListArray)
        NodeConnectType = List[ConnectionType]([ConnectionType.Invalid]) * NumInList
        if NumInList > 0:
            for NodeConnectIndex in range(NumInList):
                NodeConnectType[NodeConnectIndex] = state.dataBranchNodeConnections.NodeConnections[ListArray[NodeConnectIndex] - 1].ConnectionType
        else:
            if NodeNumber > 0:
                ShowWarningError(state, String.format("Node not found = {}.", state.dataLoopNodes.NodeID[NodeNumber - 1]))
            else:
                ShowWarningError(state, "Invalid node number passed = 0.")
            errFlag = True

    @staticmethod
    def FindAllNodeNumbersInList(
        WhichNumber: Int,
        NodeConnections: List[NodeConnectionDef],
        NumItems: Int,
        inout CountOfItems: Int,
        inout AllNumbersInList: List[Int],
    ):
        CountOfItems = 0
        AllNumbersInList = List[Int]()
        for Count in range(NumItems):
            if WhichNumber == NodeConnections[Count].NodeNumber:
                CountOfItems += 1
        if CountOfItems > 0:
            AllNumbersInList = List[Int]([0]) * CountOfItems
            CountOfItems = 0
            for Count in range(NumItems):
                if WhichNumber == NodeConnections[Count].NodeNumber:
                    AllNumbersInList[CountOfItems] = Count + 1
                    CountOfItems += 1