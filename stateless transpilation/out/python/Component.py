# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from typing import Optional, List, Protocol
from dataclasses import dataclass, field
from enum import IntEnum

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: from EnergyPlus.Data.EnergyPlusData (state container with dataPlnt)
# - PlantLocation: from EnergyPlus.Plant.PlantLocation (struct with loopNum, loopSideNum, branchNum, compNum)
# - PlantComponent: from EnergyPlus.Plant.PlantComponent (base class with oneTimeInitFlag and methods)
# - PlantEquipmentType: from EnergyPlus.Plant.Enums (enum with Num, Invalid)
# - CtrlType: from EnergyPlus.Plant.Enums (enum: Invalid, HeatingOp, CoolingOp, DualOp)
# - OpScheme: from EnergyPlus.Plant.Enums (enum with Invalid)
# - HowMet: from EnergyPlus.Plant.Enums (enum with Invalid)
# - FreeCoolControlMode: from EnergyPlus.Plant.Enums (enum with Invalid)
# - LoopFlowStatus: from EnergyPlus.Plant.Enums (enum with Invalid)
# - DataBranchAirLoopPlant.ControlType: enum with Invalid
# - OpSchemePtrData: from EnergyPlus.Plant.EquipAndOperations


class EnergyPlusData(Protocol):
    """External stub: state container"""
    pass


class PlantLocation(Protocol):
    """External stub: plant location with indices"""
    loopNum: int
    loopSideNum: int
    branchNum: int
    compNum: int


class PlantComponent(Protocol):
    """External stub: plant component base class"""
    oneTimeInitFlag: bool

    def onInitLoopEquip(self, state: 'EnergyPlusData', location: 'PlantLocation') -> None: ...
    def getDesignCapacities(self, state: 'EnergyPlusData', location: 'PlantLocation', MaxLoad: float, MinLoad: float, OptLoad: float) -> None: ...
    def getDesignTemperatures(self, TempDesCondIn: float, TempDesEvapOut: float) -> None: ...
    def getSizingFactor(self, SizFac: float) -> None: ...
    def simulate(self, state: 'EnergyPlusData', location: 'PlantLocation', FirstHVACIteration: bool, MyLoad: float, ON: bool) -> None: ...
    def oneTimeInit_new(self, state: 'EnergyPlusData') -> None: ...
    def getDynamicMaxCapacity(self, state: 'EnergyPlusData') -> float: ...


class OpSchemePtrData(Protocol):
    """External stub: operation scheme pointer data"""
    pass


class PlantEquipmentType(IntEnum):
    Invalid = -1
    Num = 105


class CtrlType(IntEnum):
    Invalid = -1
    HeatingOp = 0
    CoolingOp = 1
    DualOp = 2


class OpScheme(IntEnum):
    Invalid = -1


class HowMet(IntEnum):
    Invalid = -1


class FreeCoolControlMode(IntEnum):
    Invalid = -1


class LoopFlowStatus(IntEnum):
    Invalid = -1


class ControlType(IntEnum):
    Invalid = -1


PLANT_EQUIPMENT_TYPE_IS_PUMP = [
    False,  # "Boiler:HotWater"
    False,  # "Boiler:Steam"
    False,  # "Chiller:Absorption"
    False,  # "Chiller:Absorption:Indirect"
    False,  # "Chiller:CombustionTurbine"
    False,  # "Chiller:ConstantCOP"
    False,  # "ChillerHeater:Absorption:DirectFired"
    False,  # "Chiller:Electric"
    False,  # "Chiller:Electric:EIR"
    False,  # "Chiller:Electric:ReformulatedEIR"
    False,  # "Chiller:Electric:ASHRAE205"
    False,  # "Chiller:EngineDriven"
    False,  # "CoolingTower:SingleSpeed"
    False,  # "CoolingTower:TwoSpeed"
    False,  # "CoolingTower:VariableSpeed"
    False,  # "Generator:Fuelcell:ExhaustGastoWaterHeatExchanger"
    False,  # "WaterHeater:HeatPump:PumpedCondenser"
    False,  # "Heatpump:WatertoWater:Equationfit:Cooling"
    False,  # "Heatpump:WatertoWater:Equationfit:Heating"
    False,  # "Heatpump:WatertoWater:ParameterEstimation:Cooling"
    False,  # "Heatpump:WatertoWater:ParameterEstimation:Heating"
    False,  # "Pipe:Adiabatic"
    False,  # "Pipe:Adiabatic:Steam"
    False,  # "Pipe:Outdoor"
    False,  # "Pipe:Indoor"
    False,  # "Pipe:Underground"
    False,  # "DistrictCooling"
    False,  # "DistrictHeating:Water"
    False,  # "ThermalStorage:Ice:Detailed"
    False,  # "ThermalStorage:Ice:Simple"
    False,  # "ThermalStorage:PCM"
    False,  # "TemperingValve"
    False,  # "WaterHeater:Mixed"
    False,  # "WaterHeater:Stratified"
    True,   # "Pump:VariableSpeed"
    True,   # "Pump:ConstantSpeed"
    True,   # "Pump:VariableSpeed:Condensate"
    True,   # "HeaderedPumps:VariableSpeed"
    True,   # "HeaderedPumps:ConstantSpeed"
    False,  # "WaterUse:Connections"
    False,  # "Coil:Cooling:Water"
    False,  # "Coil:Cooling:Water:DetailedGeometry"
    False,  # "Coil:Heating:Water"
    False,  # "Coil:Heating:Steam"
    False,  # "Solarcollector:Flatplate:Water"
    False,  # "LoadProfile:Plant"
    False,  # "GroundHeatExchanger:System"
    False,  # "GroundHeatExchanger:Surface"
    False,  # "GroundHeatExchanger:Pond"
    False,  # "Generator:Microturbine"
    False,  # "Generator:InternalCombustionEngine"
    False,  # "Generator:CombustionTurbine"
    False,  # "Generator:Microchp"
    False,  # "Generator:Fuelcell:StackCooler"
    False,  # "FluidCooler:SingleSpeed"
    False,  # "FluidCooler:TwoSpeed"
    False,  # "EvaporativeFluidCooler:SingleSpeed"
    False,  # "EvaporativeFluidCooler:TwoSpeed"
    False,  # "ThermalStorage:ChilledWater:Mixed"
    False,  # "ThermalStorage:ChilledWater:Stratified"
    False,  # "ThermalStorage:HotWater:Stratified"
    False,  # "SolarCollector:FlatPlate:PhotovoltaicThermal"
    False,  # "ZoneHVAC:Baseboard:Convective:Water"
    False,  # "ZoneHVAC:Baseboard:RadiantConvective:Steam"
    False,  # "ZoneHVAC:Baseboard:RadiantConvective:Water"
    False,  # "ZoneHVAC:LowTemperatureRadiant:VariableFlow"
    False,  # "ZoneHVAC:LowTemperatureRadiant:ConstantFlow"
    False,  # "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
    False,  # "Coil:Heating:WaterToAirHeatPump:EquationFit"
    False,  # "Coil:Cooling:WaterToAirHeatPump:EquationFit"
    False,  # "Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
    False,  # "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
    False,  # "Refrigeration:Condenser:WaterCooled"
    False,  # "Refrigeration:CompressorRack"
    False,  # "AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed"
    False,  # "ChillerHeater:Absorption:DoubleEffect"
    False,  # "PipingSystem:Underground:PipeCircuit"
    False,  # "SolarCollector:IntegralCollectorStorage"
    False,  # "Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit"
    False,  # "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
    False,  # "PlantComponent:UserDefined"
    False,  # "Coil:UserDefined"
    False,  # "ZoneHVAC:ForcedAir:UserDefined"
    False,  # "AirTerminal:SingleDuct:UserDefined"
    False,  # "AirConditioner:VariableRefrigerantFlow"
    False,  # "GroundHeatExchanger:HorizontalTrench"
    False,  # "HeatExchanger:FluidToFluid"
    False,  # "PlantComponent:TemperatureSource"
    False,  # "CentralHeatPumpSystem"
    False,  # "AirLoopHVAC:UnitarySystem"
    False,  # "Coil:Cooling:DX:SingleSpeed:ThermalStorage"
    False,  # "CoolingTower:VariableSpeed:Merkel"
    False,  # "SwimmingPool:Indoor"
    False,  # "GroundHeatExchanger:Slinky"
    False,  # "WaterHeater:HeatPump:WrappedCondenser"
    False,  # "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
    False,  # "ZoneHVAC:CoolingPanel:RadiantConvective:Water"
    False,  # "HeatPump:PlantLoop:EIR:Cooling"
    False,  # "HeatPump:PlantLoop:EIR:Heating"
    False,  # "HEATPUMP:AIRTOWATER:FUELFIRED:COOLING"
    False,  # "HEATPUMP:AIRTOWATER:FUELFIRED:HEATING"
    False,  # "HEATPUMP:AIRTOWATER:COOLING"
    False,  # "HEATPUMP:AIRTOWATER:HEATING"
    False,  # "HEATPUMP:AIRTOWATER"
    False,  # "DistrictHeating:Steam"
]

PLANT_EQUIPMENT_CTRL_TYPE = [
    CtrlType.HeatingOp,  # "Boiler:HotWater"
    CtrlType.HeatingOp,  # "Boiler:Steam"
    CtrlType.CoolingOp,  # "Chiller:Absorption"
    CtrlType.CoolingOp,  # "Chiller:Absorption:Indirect"
    CtrlType.CoolingOp,  # "Chiller:CombustionTurbine"
    CtrlType.CoolingOp,  # "Chiller:ConstantCOP"
    CtrlType.DualOp,     # "ChillerHeater:Absorption:DirectFired"
    CtrlType.CoolingOp,  # "Chiller:Electric"
    CtrlType.CoolingOp,  # "Chiller:Electric:EIR"
    CtrlType.CoolingOp,  # "Chiller:Electric:ReformulatedEIR"
    CtrlType.CoolingOp,  # "Chiller:Electric:ASHRAE205"
    CtrlType.CoolingOp,  # "Chiller:EngineDriven"
    CtrlType.CoolingOp,  # "CoolingTower:SingleSpeed"
    CtrlType.CoolingOp,  # "CoolingTower:TwoSpeed"
    CtrlType.CoolingOp,  # "CoolingTower:VariableSpeed"
    CtrlType.HeatingOp,  # "Generator:Fuelcell:ExhaustGastoWaterHeatExchanger"
    CtrlType.HeatingOp,  # "WaterHeater:HeatPump:PumpedCondenser"
    CtrlType.CoolingOp,  # "Heatpump:WatertoWater:Equationfit:Cooling"
    CtrlType.HeatingOp,  # "Heatpump:WatertoWater:Equationfit:Heating"
    CtrlType.CoolingOp,  # "Heatpump:WatertoWater:ParameterEstimation:Cooling"
    CtrlType.HeatingOp,  # "Heatpump:WatertoWater:ParameterEstimation:Heating"
    CtrlType.Invalid,    # "Pipe:Adiabatic"
    CtrlType.Invalid,    # "Pipe:Adiabatic:Steam"
    CtrlType.Invalid,    # "Pipe:Outdoor"
    CtrlType.Invalid,    # "Pipe:Indoor"
    CtrlType.Invalid,    # "Pipe:Underground"
    CtrlType.CoolingOp,  # "DistrictCooling"
    CtrlType.HeatingOp,  # "DistrictHeating:Water"
    CtrlType.CoolingOp,  # "ThermalStorage:Ice:Detailed"
    CtrlType.CoolingOp,  # "ThermalStorage:Ice:Simple"
    CtrlType.HeatingOp,  # "ThermalStorage:PCM"
    CtrlType.Invalid,    # "TemperingValve"
    CtrlType.HeatingOp,  # "WaterHeater:Mixed"
    CtrlType.HeatingOp,  # "WaterHeater:Stratified"
    CtrlType.Invalid,    # "Pump:VariableSpeed"
    CtrlType.Invalid,    # "Pump:ConstantSpeed"
    CtrlType.Invalid,    # "Pump:VariableSpeed:Condensate"
    CtrlType.Invalid,    # "HeaderedPumps:VariableSpeed"
    CtrlType.Invalid,    # "HeaderedPumps:ConstantSpeed"
    CtrlType.Invalid,    # "WaterUse:Connections"
    CtrlType.Invalid,    # "Coil:Cooling:Water"
    CtrlType.Invalid,    # "Coil:Cooling:Water:DetailedGeometry"
    CtrlType.Invalid,    # "Coil:Heating:Water"
    CtrlType.Invalid,    # "Coil:Heating:Steam"
    CtrlType.HeatingOp,  # "Solarcollector:Flatplate:Water"
    CtrlType.DualOp,     # "LoadProfile:Plant"
    CtrlType.DualOp,     # "GroundHeatExchanger:System"
    CtrlType.DualOp,     # "GroundHeatExchanger:Surface"
    CtrlType.DualOp,     # "GroundHeatExchanger:Pond"
    CtrlType.HeatingOp,  # "Generator:Microturbine"
    CtrlType.HeatingOp,  # "Generator:InternalCombustionEngine"
    CtrlType.HeatingOp,  # "Generator:CombustionTurbine"
    CtrlType.HeatingOp,  # "Generator:Microchp"
    CtrlType.HeatingOp,  # "Generator:Fuelcell:StackCooler"
    CtrlType.CoolingOp,  # "FluidCooler:SingleSpeed"
    CtrlType.CoolingOp,  # "FluidCooler:TwoSpeed"
    CtrlType.CoolingOp,  # "EvaporativeFluidCooler:SingleSpeed"
    CtrlType.CoolingOp,  # "EvaporativeFluidCooler:TwoSpeed"
    CtrlType.CoolingOp,  # "ThermalStorage:ChilledWater:Mixed"
    CtrlType.CoolingOp,  # "ThermalStorage:ChilledWater:Stratified"
    CtrlType.HeatingOp,  # "ThermalStorage:HotWater:Stratified"
    CtrlType.HeatingOp,  # "SolarCollector:FlatPlate:PhotovoltaicThermal"
    CtrlType.Invalid,    # "ZoneHVAC:Baseboard:Convective:Water"
    CtrlType.Invalid,    # "ZoneHVAC:Baseboard:RadiantConvective:Steam"
    CtrlType.Invalid,    # "ZoneHVAC:Baseboard:RadiantConvective:Water"
    CtrlType.Invalid,    # "ZoneHVAC:LowTemperatureRadiant:VariableFlow"
    CtrlType.Invalid,    # "ZoneHVAC:LowTemperatureRadiant:ConstantFlow"
    CtrlType.Invalid,    # "AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
    CtrlType.Invalid,    # "Coil:Heating:WaterToAirHeatPump:EquationFit"
    CtrlType.Invalid,    # "Coil:Cooling:WaterToAirHeatPump:EquationFit"
    CtrlType.Invalid,    # "Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
    CtrlType.Invalid,    # "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
    CtrlType.HeatingOp,  # "Refrigeration:Condenser:WaterCooled"
    CtrlType.Invalid,    # "Refrigeration:CompressorRack"
    CtrlType.Invalid,    # "AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed"
    CtrlType.DualOp,     # "ChillerHeater:Absorption:DoubleEffect"
    CtrlType.Invalid,    # "PipingSystem:Underground:PipeCircuit"
    CtrlType.HeatingOp,  # "SolarCollector:IntegralCollectorStorage"
    CtrlType.Invalid,    # "Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit"
    CtrlType.Invalid,    # "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
    CtrlType.DualOp,     # "PlantComponent:UserDefined"
    CtrlType.Invalid,    # "Coil:UserDefined"
    CtrlType.Invalid,    # "ZoneHVAC:ForcedAir:UserDefined"
    CtrlType.Invalid,    # "AirTerminal:SingleDuct:UserDefined"
    CtrlType.Invalid,    # "AirConditioner:VariableRefrigerantFlow"
    CtrlType.DualOp,     # "GroundHeatExchanger:HorizontalTrench"
    CtrlType.DualOp,     # "HeatExchanger:FluidToFluid"
    CtrlType.DualOp,     # "PlantComponent:TemperatureSource"
    CtrlType.DualOp,     # "CentralHeatPumpSystem"
    CtrlType.Invalid,    # "AirLoopHVAC:UnitarySystem"
    CtrlType.HeatingOp,  # "Coil:Cooling:DX:SingleSpeed:ThermalStorage"
    CtrlType.CoolingOp,  # "CoolingTower:VariableSpeed:Merkel"
    CtrlType.Invalid,    # "SwimmingPool:Indoor"
    CtrlType.DualOp,     # "GroundHeatExchanger:Slinky"
    CtrlType.HeatingOp,  # "WaterHeater:HeatPump:WrappedCondenser"
    CtrlType.Invalid,    # "AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
    CtrlType.Invalid,    # "ZoneHVAC:CoolingPanel:RadiantConvective:Water"
    CtrlType.CoolingOp,  # "HeatPump:PlantLoop:EIR:Cooling"
    CtrlType.HeatingOp,  # "HeatPump:PlantLoop:EIR:Heating"
    CtrlType.CoolingOp,  # "HEATPUMP:AIRTOWATER:FUELFIRED:COOLING"
    CtrlType.HeatingOp,  # "HEATPUMP:AIRTOWATER:FUELFIRED:HEATING"
    CtrlType.CoolingOp,  # "HEATPUMP:AIRTOWATER:COOLING"
    CtrlType.HeatingOp,  # "HEATPUMP:AIRTOWATER:HEATING"
    CtrlType.DualOp,     # "HEATPUMP:AIRTOWATER"
    CtrlType.HeatingOp,  # "DistrictHeating:Steam"
]


@dataclass
class CompData:
    TypeOf: str = ""
    Type: int = -1
    Name: str = ""
    CompNum: int = 0
    FlowCtrl: int = -1
    FlowPriority: int = -1
    ON: bool = False
    Available: bool = False
    NodeNameIn: str = ""
    NodeNameOut: str = ""
    NodeNumIn: int = 0
    NodeNumOut: int = 0
    MyLoad: float = 0.0
    MaxLoad: float = 0.0
    MinLoad: float = 0.0
    OptLoad: float = 0.0
    SizFac: float = 0.0
    CurOpSchemeType: int = -1
    NumOpSchemes: int = 0
    CurCompLevelOpNum: int = 0
    OpScheme: List[OpSchemePtrData] = field(default_factory=list)
    EquipDemand: float = 0.0
    EMSLoadOverrideOn: bool = False
    EMSLoadOverrideValue: float = 0.0
    HowLoadServed: int = -1
    MinOutletTemp: float = 0.0
    MaxOutletTemp: float = 0.0
    FreeCoolCntrlShutDown: bool = False
    FreeCoolCntrlMinCntrlTemp: float = 0.0
    FreeCoolCntrlMode: int = -1
    FreeCoolCntrlNodeNum: int = 0
    IndexInLoopSidePumps: int = 0
    TempDesCondIn: float = 0.0
    TempDesEvapOut: float = 0.0
    compPtr: Optional[PlantComponent] = None
    location: Optional[PlantLocation] = None

    def initLoopEquip(self, state: EnergyPlusData, GetCompSizFac: bool) -> None:
        self.compPtr.onInitLoopEquip(state, self.location)
        self.compPtr.getDesignCapacities(state, self.location, self.MaxLoad, self.MinLoad, self.OptLoad)
        self.compPtr.getDesignTemperatures(self.TempDesCondIn, self.TempDesEvapOut)

        if GetCompSizFac:
            self.compPtr.getSizingFactor(self.SizFac)

    def simulate(self, state: EnergyPlusData, FirstHVACIteration: bool) -> None:
        self.compPtr.simulate(state, self.location, FirstHVACIteration, self.MyLoad, self.ON)

    def oneTimeInit(self, state: EnergyPlusData) -> None:
        if self.compPtr.oneTimeInitFlag:
            self.compPtr.oneTimeInit_new(state)
            self.compPtr.oneTimeInitFlag = False

    @staticmethod
    def getPlantComponent(state: EnergyPlusData, plantLoc: PlantLocation) -> 'CompData':
        return state.dataPlnt.PlantLoop[plantLoc.loopNum].LoopSide[plantLoc.loopSideNum].Branch[plantLoc.branchNum].Comp[plantLoc.compNum]

    def getDynamicMaxCapacity(self, state: EnergyPlusData) -> float:
        if self.compPtr is None:
            return self.MaxLoad
        possibleLoad = self.compPtr.getDynamicMaxCapacity(state)
        return self.MaxLoad if possibleLoad == 0 else possibleLoad
