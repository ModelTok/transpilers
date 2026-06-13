from ...Data.EnergyPlusData import EnergyPlusData
from ..Enums import PlantEquipmentType, CtrlType, OpScheme, HowMet, FreeCoolControlMode, LoopFlowStatus
from ...DataBranchAirLoopPlant import ControlType
from ..EquipAndOperations import OpSchemePtrData
from ..PlantLocation import PlantLocation
from ..PlantComponent import PlantComponent
from ..DataPlant import DataPlantData  # assume this struct exists

# Begin namespace EnergyPlus::DataPlant
alias DataPlant = __module__

# static arrays (verbatim from header, comments preserved)
var PlantEquipmentTypeIsPump: StaticTuple[Bool, ...] = (
    false, #	"Boiler:HotWater"
    false, #	"Boiler:Steam"
    false, #	"Chiller:Absorption"
    false, #	"Chiller:Absorption:Indirect"
    false, #	"Chiller:CombustionTurbine"
    false, #	"Chiller:ConstantCOP"
    false, #	"ChillerHeater:Absorption:DirectFired"
    false, #	"Chiller:Electric"
    false, #	"Chiller:Electric:EIR"
    false, #	"Chiller:Electric:ReformulatedEIR"
    false, #	"Chiller:Electric:ASHRAE205"
    false, #	"Chiller:EngineDriven"
    false, #	"CoolingTower:SingleSpeed"
    false, #	"CoolingTower:TwoSpeed"
    false, #	"CoolingTower:VariableSpeed"
    false, #	"Generator:Fuelcell:ExhaustGastoWaterHeatExchanger"
    false, #	"WaterHeater:HeatPump:PumpedCondenser"
    false, #	"Heatpump:WatertoWater:Equationfit:Cooling"
    false, #	"Heatpump:WatertoWater:Equationfit:Heating"
    false, #	"Heatpump:WatertoWater:ParameterEstimation:Cooling"
    false, #	"Heatpump:WatertoWater:ParameterEstimation:Heating"
    false, #	"Pipe:Adiabatic"
    false, #	"Pipe:Adiabatic:Steam"
    false, #	"Pipe:Outdoor"
    false, #	"Pipe:Indoor"
    false, #	"Pipe:Underground"
    false, #	"DistrictCooling"
    false, #	"DistrictHeating:Water" (steam is at the end)
    false, #	"ThermalStorage:Ice:Detailed"
    false, #	"ThermalStorage:Ice:Simple"
    false, #   "ThermalStorage:PCM"
    false, #	"TemperingValve"
    false, #	"WaterHeater:Mixed"
    false, #	"WaterHeater:Stratified"
    true,  #	"Pump:VariableSpeed"
    true,  #	"Pump:ConstantSpeed"
    true,  #	"Pump:VariableSpeed:Condensate"
    true,  #	"HeaderedPumps:VariableSpeed"
    true,  #	"HeaderedPumps:ConstantSpeed"
    false, #	"WaterUse:Connections"
    false, #	"Coil:Cooling:Water"
    false, #	"Coil:Cooling:Water:DetailedGeometry"
    false, #	"Coil:Heating:Water"
    false, #	"Coil:Heating:Steam"
    false, #	"Solarcollector:Flatplate:Water"
    false, #	"LoadProfile:Plant"
    false, #	"GroundHeatExchanger:System"
    false, #	"GroundHeatExchanger:Surface"
    false, #	"GroundHeatExchanger:Pond"
    false, #	"Generator:Microturbine"
    false, #	"Generator:InternalCombustionEngine"
    false, #	"Generator:CombustionTurbine"
    false, #	"Generator:Microchp"
    false, #	"Generator:Fuelcell:StackCooler"
    false, #	"FluidCooler:SingleSpeed"
    false, #	"FluidCooler:TwoSpeed"
    false, #	"EvaporativeFluidCooler:SingleSpeed"
    false, #	"EvaporativeFluidCooler:TwoSpeed"
    false, #	"ThermalStorage:ChilledWater:Mixed"
    false, #	"ThermalStorage:ChilledWater:Stratified"
    false, #	"ThermalStorage:HotWater:Stratified"
    false, #	"SolarCollector:FlatPlate:PhotovoltaicThermal"
    false, #	"ZoneHVAC:Baseboard:Convective:Water"
    false, #	"ZoneHVAC:Baseboard:RadiantConvective:Steam"
    false, #	"ZoneHVAC:Baseboard:RadiantConvective:Water"
    false, #	"ZoneHVAC:LowTemperatureRadiant:VariableFlow"
    false, #	"ZoneHVAC:LowTemperatureRadiant:ConstantFlow"
    false, #	"AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
    false, #	"Coil:Heating:WaterToAirHeatPump:EquationFit"
    false, #	"Coil:Cooling:WaterToAirHeatPump:EquationFit"
    false, #	"Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
    false, #	"Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
    false, #	"Refrigeration:Condenser:WaterCooled"
    false, #	"Refrigeration:CompressorRack"
    false, #	"AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed"
    false, #	"ChillerHeater:Absorption:DoubleEffect"
    false, #	"PipingSystem:Underground:PipeCircuit"
    false, #	"SolarCollector:IntegralCollectorStorage"
    false, #	"Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit"
    false, #	"Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
    false, #	"PlantComponent:UserDefined"
    false, #	"Coil:UserDefined"
    false, #	"ZoneHVAC:ForcedAir:UserDefined"
    false, #	"AirTerminal:SingleDuct:UserDefined"
    false, #	"AirConditioner:VariableRefrigerantFlow"
    false, #	"GroundHeatExchanger:HorizontalTrench"
    false, #	"HeatExchanger:FluidToFluid"
    false, #	"PlantComponent:TemperatureSource"
    false, #	"CentralHeatPumpSystem"
    false, #	"AirLoopHVAC:UnitarySystem"
    false, #	"Coil:Cooling:DX:SingleSpeed:ThermalStorage"
    false, #	"CoolingTower:VariableSpeed:Merkel"
    false, #	"SwimmingPool:Indoor"
    false, #	"GroundHeatExchanger:Slinky"
    false, #	"WaterHeater:HeatPump:WrappedCondenser"
    false, #	"AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
    false, #	"ZoneHVAC:CoolingPanel:RadiantConvective:Water"
    false, #	"HeatPump:PlantLoop:EIR:Cooling"
    false, #	"HeatPump:PlantLoop:EIR:Heating"
    false, # "HEATPUMP:AIRTOWATER:FUELFIRED:COOLING",
    false, # "HEATPUMP:AIRTOWATER:FUELFIRED:HEATING",
    false, # "HEATPUMP:AIRTOWATER:COOLING",
    false, # "HEATPUMP:AIRTOWATER:HEATING",
    false, # "HEATPUMP:AIRTOWATER",
    false  #   "DistrictHeating:Steam"
)

var PlantEquipmentCtrlType: StaticTuple[CtrlType, ...] = (
    CtrlType.HeatingOp, #	"Boiler:HotWater"
    CtrlType.HeatingOp, #	"Boiler:Steam"
    CtrlType.CoolingOp, #	"Chiller:Absorption"
    CtrlType.CoolingOp, #	"Chiller:Absorption:Indirect"
    CtrlType.CoolingOp, #	"Chiller:CombustionTurbine"
    CtrlType.CoolingOp, #	"Chiller:ConstantCOP"
    CtrlType.DualOp,    #	"ChillerHeater:Absorption:DirectFired"
    CtrlType.CoolingOp, #	"Chiller:Electric"
    CtrlType.CoolingOp, #	"Chiller:Electric:EIR"
    CtrlType.CoolingOp, #	"Chiller:Electric:ReformulatedEIR"
    CtrlType.CoolingOp, #	"Chiller:Electric:ASHRAE205"
    CtrlType.CoolingOp, #	"Chiller:EngineDriven"
    CtrlType.CoolingOp, #	"CoolingTower:SingleSpeed"
    CtrlType.CoolingOp, #	"CoolingTower:TwoSpeed"
    CtrlType.CoolingOp, #	"CoolingTower:VariableSpeed"
    CtrlType.HeatingOp, #	"Generator:Fuelcell:ExhaustGastoWaterHeatExchanger"
    CtrlType.HeatingOp, #	"WaterHeater:HeatPump:PumpedCondenser"
    CtrlType.CoolingOp, #	"Heatpump:WatertoWater:Equationfit:Cooling"
    CtrlType.HeatingOp, #	"Heatpump:WatertoWater:Equationfit:Heating"
    CtrlType.CoolingOp, #	"Heatpump:WatertoWater:ParameterEstimation:Cooling"
    CtrlType.HeatingOp, #	"Heatpump:WatertoWater:ParameterEstimation:Heating"
    CtrlType.Invalid,   #	"Pipe:Adiabatic"
    CtrlType.Invalid,   #	"Pipe:Adiabatic:Steam"
    CtrlType.Invalid,   #	"Pipe:Outdoor"
    CtrlType.Invalid,   #	"Pipe:Indoor"
    CtrlType.Invalid,   #	"Pipe:Underground"
    CtrlType.CoolingOp, #	"DistrictCooling"
    CtrlType.HeatingOp, #	"DistrictHeating:Water" (steam is at the end)
    CtrlType.CoolingOp, #	"ThermalStorage:Ice:Detailed"
    CtrlType.CoolingOp, #	"ThermalStorage:Ice:Simple"
    CtrlType.HeatingOp, #  "ThermalStorage:PCM"
    CtrlType.Invalid,   #	"TemperingValve"
    CtrlType.HeatingOp, #	"WaterHeater:Mixed"
    CtrlType.HeatingOp, #	"WaterHeater:Stratified"
    CtrlType.Invalid,   #	"Pump:VariableSpeed"
    CtrlType.Invalid,   #	"Pump:ConstantSpeed"
    CtrlType.Invalid,   #	"Pump:VariableSpeed:Condensate"
    CtrlType.Invalid,   #	"HeaderedPumps:VariableSpeed"
    CtrlType.Invalid,   #	"HeaderedPumps:ConstantSpeed"
    CtrlType.Invalid,   #	"WaterUse:Connections"
    CtrlType.Invalid,   #	"Coil:Cooling:Water"
    CtrlType.Invalid,   #	"Coil:Cooling:Water:DetailedGeometry"
    CtrlType.Invalid,   #	"Coil:Heating:Water"
    CtrlType.Invalid,   #	"Coil:Heating:Steam"
    CtrlType.HeatingOp, #	"Solarcollector:Flatplate:Water"
    CtrlType.DualOp,    #	"LoadProfile:Plant"
    CtrlType.DualOp,    #	"GroundHeatExchanger:System"
    CtrlType.DualOp,    #	"GroundHeatExchanger:Surface"
    CtrlType.DualOp,    #	"GroundHeatExchanger:Pond"
    CtrlType.HeatingOp, #	"Generator:Microturbine"
    CtrlType.HeatingOp, #	"Generator:InternalCombustionEngine"
    CtrlType.HeatingOp, #	"Generator:CombustionTurbine"
    CtrlType.HeatingOp, #	"Generator:Microchp"
    CtrlType.HeatingOp, #	"Generator:Fuelcell:StackCooler"
    CtrlType.CoolingOp, #	"FluidCooler:SingleSpeed"
    CtrlType.CoolingOp, #	"FluidCooler:TwoSpeed"
    CtrlType.CoolingOp, #	"EvaporativeFluidCooler:SingleSpeed"
    CtrlType.CoolingOp, #	"EvaporativeFluidCooler:TwoSpeed"
    CtrlType.CoolingOp, #	"ThermalStorage:ChilledWater:Mixed"
    CtrlType.CoolingOp, #	"ThermalStorage:ChilledWater:Stratified"
    CtrlType.HeatingOp, #	"ThermalStorage:HotWater:Stratified"
    CtrlType.HeatingOp, #	"SolarCollector:FlatPlate:PhotovoltaicThermal"
    CtrlType.Invalid,   #	"ZoneHVAC:Baseboard:Convective:Water"
    CtrlType.Invalid,   #	"ZoneHVAC:Baseboard:RadiantConvective:Steam"
    CtrlType.Invalid,   #	"ZoneHVAC:Baseboard:RadiantConvective:Water"
    CtrlType.Invalid,   #	"ZoneHVAC:LowTemperatureRadiant:VariableFlow"
    CtrlType.Invalid,   #	"ZoneHVAC:LowTemperatureRadiant:ConstantFlow"
    CtrlType.Invalid,   #	"AirTerminal:SingleDuct:ConstantVolume:CooledBeam"
    CtrlType.Invalid,   #	"Coil:Heating:WaterToAirHeatPump:EquationFit"
    CtrlType.Invalid,   #	"Coil:Cooling:WaterToAirHeatPump:EquationFit"
    CtrlType.Invalid,   #	"Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
    CtrlType.Invalid,   #	"Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
    CtrlType.HeatingOp, #	"Refrigeration:Condenser:WaterCooled"
    CtrlType.Invalid,   #	"Refrigeration:CompressorRack"
    CtrlType.Invalid,   #	"AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed"
    CtrlType.DualOp,    #	"ChillerHeater:Absorption:DoubleEffect"
    CtrlType.Invalid,   #	"PipingSystem:Underground:PipeCircuit"
    CtrlType.HeatingOp, #	"SolarCollector:IntegralCollectorStorage"
    CtrlType.Invalid,   #	"Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit"
    CtrlType.Invalid,   #	"Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
    CtrlType.DualOp,    #	"PlantComponent:UserDefined"
    CtrlType.Invalid,   #	"Coil:UserDefined"
    CtrlType.Invalid,   #	"ZoneHVAC:ForcedAir:UserDefined"
    CtrlType.Invalid,   #	"AirTerminal:SingleDuct:UserDefined"
    CtrlType.Invalid,   #	"AirConditioner:VariableRefrigerantFlow"
    CtrlType.DualOp,    #	"GroundHeatExchanger:HorizontalTrench"
    CtrlType.DualOp,    #	"HeatExchanger:FluidToFluid"
    CtrlType.DualOp,    #	"PlantComponent:TemperatureSource"
    CtrlType.DualOp,    #	"CentralHeatPumpSystem"
    CtrlType.Invalid,   #	"AirLoopHVAC:UnitarySystem"
    CtrlType.HeatingOp, #	"Coil:Cooling:DX:SingleSpeed:ThermalStorage"
    CtrlType.CoolingOp, #	"CoolingTower:VariableSpeed:Merkel"
    CtrlType.Invalid,   #	"SwimmingPool:Indoor"
    CtrlType.DualOp,    #	"GroundHeatExchanger:Slinky"
    CtrlType.HeatingOp, #	"WaterHeater:HeatPump:WrappedCondenser"
    CtrlType.Invalid,   #	"AirTerminal:SingleDuct:ConstantVolume:FourPipeBeam"
    CtrlType.Invalid,   #	"ZoneHVAC:CoolingPanel:RadiantConvective:Water"
    CtrlType.CoolingOp, #	"HeatPump:PlantLoop:EIR:Cooling"
    CtrlType.HeatingOp, #	"HeatPump:PlantLoop:EIR:Heating"
    CtrlType.CoolingOp, # "HEATPUMP:AIRTOWATER:FUELFIRED:COOLING",
    CtrlType.HeatingOp, # "HEATPUMP:AIRTOWATER:FUELFIRED:HEATING",
    CtrlType.CoolingOp, # "HEATPUMP:AIRTOWATER:COOLING",
    CtrlType.HeatingOp, # "HEATPUMP:AIRTOWATER:HEATING",
    CtrlType.DualOp,    # "HEATPUMP:AIRTOWATER",
    CtrlType.HeatingOp  #   "DistrictHeating:Steam"
)

# Struct CompData (verbatim from header, with Mojo adaptations)
@register_passable("trivial")
struct CompData:
    var TypeOf: String                             # The 'keyWord' identifying  component type
    var Type: PlantEquipmentType                   # Reference the "TypeOf" parameters in DataPlant
    var Name: String                               # Component name
    var CompNum: Int                               # Component ID number
    var FlowCtrl: ControlType                      # flow control for splitter/mixer (ACTIVE/PASSIVE/BYPASS)
    var FlowPriority: LoopFlowStatus               # status for overall loop flow determination
    var ON: Bool                                   # TRUE = designated component or operation scheme available
    var Available: Bool                            # TRUE = designated component or operation scheme available
    var NodeNameIn: String                         # Component inlet node name
    var NodeNameOut: String                        # Component outlet node name
    var NodeNumIn: Int                             # Component inlet node number
    var NodeNumOut: Int                            # Component outlet node number
    var MyLoad: Float64                            # Distributed Load
    var MaxLoad: Float64                           # Maximum load
    var MinLoad: Float64                           # Minimum Load
    var OptLoad: Float64                           # Optimal Load
    var SizFac: Float64                            # Sizing Fraction
    var CurOpSchemeType: OpScheme                  # updated pointer to
    var NumOpSchemes: Int                          # number of schemes held in the pointer array
    var CurCompLevelOpNum: Int                     # pointer to the OpScheme array defined next
    var OpScheme: DynamicVector[OpSchemePtrData]   # Pointers to component on lists (1-based -> 0-based)
    var EquipDemand: Float64                       # Component load request based on inlet temp and outlet SP
    var EMSLoadOverrideOn: Bool                    # EMS is calling to override load dispatched to component
    var EMSLoadOverrideValue: Float64              # EMS value to use for load when overridden [W] always positive.
    var HowLoadServed: HowMet                      # nature of component in terms of how it can meet load
    var MinOutletTemp: Float64                     # Component exit lower limit temperature
    var MaxOutletTemp: Float64                     # Component exit upper limit temperature
    var FreeCoolCntrlShutDown: Bool                # true if component was shut down because of free cooling
    var FreeCoolCntrlMinCntrlTemp: Float64         # current control temp value for free cooling controls
    var FreeCoolCntrlMode: FreeCoolControlMode     # type of sensor used for free cooling controls
    var FreeCoolCntrlNodeNum: Int                  # chiller condenser inlet node number for free cooling controls
    var IndexInLoopSidePumps: Int                  # If I'm a pump, this tells my index in PL(:)%LS(:)%Pumps
    var TempDesCondIn: Float64
    var TempDesEvapOut: Float64
    var compPtr: Pointer[PlantComponent]
    var location: PlantLocation

    # Constructor
    def __init__(inout self):
        self.TypeOf = String("")
        self.Type = PlantEquipmentType.Invalid
        self.Name = String("")
        self.CompNum = 0
        self.FlowCtrl = ControlType.Invalid
        self.FlowPriority = LoopFlowStatus.Invalid
        self.ON = False
        self.Available = False
        self.NodeNameIn = String("")
        self.NodeNameOut = String("")
        self.NodeNumIn = 0
        self.NodeNumOut = 0
        self.MyLoad = 0.0
        self.MaxLoad = 0.0
        self.MinLoad = 0.0
        self.OptLoad = 0.0
        self.SizFac = 0.0
        self.CurOpSchemeType = OpScheme.Invalid
        self.NumOpSchemes = 0
        self.CurCompLevelOpNum = 0
        self.OpScheme = DynamicVector[OpSchemePtrData]()
        self.EquipDemand = 0.0
        self.EMSLoadOverrideOn = False
        self.EMSLoadOverrideValue = 0.0
        self.HowLoadServed = HowMet.Invalid
        self.MinOutletTemp = 0.0
        self.MaxOutletTemp = 0.0
        self.FreeCoolCntrlShutDown = False
        self.FreeCoolCntrlMinCntrlTemp = 0.0
        self.FreeCoolCntrlMode = FreeCoolControlMode.Invalid
        self.FreeCoolCntrlNodeNum = 0
        self.IndexInLoopSidePumps = 0
        self.TempDesCondIn = 0.0
        self.TempDesEvapOut = 0.0
        self.compPtr = Pointer[PlantComponent]()
        self.location = PlantLocation()

    # Methods
    def initLoopEquip(inout self, inout state: EnergyPlusData, GetCompSizFac: Bool):
        self.compPtr[].onInitLoopEquip(state, self.location)
        self.compPtr[].getDesignCapacities(state, self.location, self.MaxLoad, self.MinLoad, self.OptLoad)
        self.compPtr[].getDesignTemperatures(self.TempDesCondIn, self.TempDesEvapOut)
        if GetCompSizFac:
            self.compPtr[].getSizingFactor(self.SizFac)

    def simulate(inout self, inout state: EnergyPlusData, FirstHVACIteration: Bool):
        self.compPtr[].simulate(state, self.location, FirstHVACIteration, self.MyLoad, self.ON)

    def oneTimeInit(inout self, inout state: EnergyPlusData):
        if self.compPtr[].oneTimeInitFlag:
            self.compPtr[].oneTimeInit_new(state)
            self.compPtr[].oneTimeInitFlag = False

    @staticmethod
    def getPlantComponent(inout state: EnergyPlusData, plantLoc: PlantLocation) -> Pointer[CompData]:
        # Convert 1-based indices to 0-based (ObjexxFCL convention)
        var loopIdx = plantLoc.loopNum - 1
        var sideIdx = plantLoc.loopSideNum - 1
        var branchIdx = plantLoc.branchNum - 1
        var compIdx = plantLoc.compNum - 1
        # Assume state.dataPlnt has PlantLoop array, each with LoopSide, Branch, Comp
        return state.dataPlnt.PlantLoop[loopIdx].LoopSide[sideIdx].Branch[branchIdx].Comp[compIdx] as Pointer[CompData]

    def getDynamicMaxCapacity(self, inout state: EnergyPlusData) -> Float64:
        if self.compPtr.is_null():
            return self.MaxLoad
        var possibleLoad = self.compPtr[].getDynamicMaxCapacity(state)
        return self.MaxLoad if possibleLoad == 0 else possibleLoad

# End namespace EnergyPlus::DataPlant