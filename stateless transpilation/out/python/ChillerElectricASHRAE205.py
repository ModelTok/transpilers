from typing import Protocol, Optional, Dict, Any, List, Tuple, Callable
from dataclasses import dataclass, field
from enum import Enum, auto
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataIPShortCut, .dataInputProcessing, .dataChillerElectricASHRAE205, etc.
# - PlantLocation: plant loop location/branch/component references
# - DataPlant enums/types: FlowMode, CondenserType, LoopSideLocation, OpScheme, LoopDemandCalcScheme, PlantEquipmentType, CriteriaType, FlowLock
# - Node operations: GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream
# - Scheduling: Sched.Schedule, Sched.GetSchedule
# - Output: SetupOutputVariable
# - Error reporting: ShowSevereError, ShowFatalError, ShowWarningError, ShowContinueError, ShowSevereItemNotFound
# - File/System: DataSystemVariables, FileSystem
# - Input: InputProcessor, epJSON
# - Utilities: GlobalNames, Util, General, PlantUtilities, FluidProperties, Node, EMSManager, OutAirNodeManager
# - ASHRAE205/tk205: RS0001 representation, RSInstanceFactory, EnergyPlusLogger
# - Btwxt: InterpolationMethod enum
# - Constants: Constant.Kelvin, Constant.CWInitConvTemp, Constant.InitConvTemp, various Units

class AmbientTempIndicator(Enum):
    INVALID = -1
    SCHEDULE = 0
    TEMP_ZONE = 1
    OUTSIDE_AIR = 2
    ZONE_AND_OA = 3
    NUM = 4

class InterpolationMethod(Enum):
    LINEAR = 0
    CUBIC = 1

class FlowMode(Enum):
    INVALID = -1
    CONSTANT = 0
    NOT_MODULATED = 1
    LEAVING_SETPOINT_MODULATED = 2

class CondenserType(Enum):
    WATER_COOLED = 0
    AIR_COOLED = 1

class LoopSideLocation(Enum):
    INVALID = -1
    SUPPLY = 0
    DEMAND = 1

class OpScheme(Enum):
    INVALID = -1
    COMP_SET_PT_BASED = 0
    OTHER = 1

class LoopDemandCalcScheme(Enum):
    INVALID = -1
    SINGLE_SET_POINT = 0
    DUAL_SET_POINT_DEAD_BAND = 1

class FlowLock(Enum):
    UNLOCKED = 0
    LOCKED = 1

class CriteriaType(Enum):
    MASS_FLOW_RATE = 0
    TEMPERATURE = 1

@dataclass
class PlantLocation:
    loop_num: int = 0
    loop_side_num: LoopSideLocation = LoopSideLocation.INVALID
    branch_num: int = 0
    comp_num: int = 0
    loop: Optional[Any] = None
    side: Optional[Any] = None
    comp: Optional[Any] = None

@dataclass
class LoopData:
    PlantSizNum: int = 0
    glycol: Optional[Any] = None
    LoopDemandCalcScheme: Optional[Any] = None
    TempSetPointNodeNum: int = 0

@dataclass
class PlantSide:
    FlowLock: FlowLock = FlowLock.UNLOCKED

@dataclass
class PlantComponent:
    FlowCtrl: int = 0
    FlowPriority: int = 0
    CurOpSchemeType: OpScheme = OpScheme.INVALID

@dataclass
class Node:
    Temp: float = 0.0
    MassFlowRate: float = 0.0
    TempSetPoint: float = 0.0
    TempSetPointHi: float = 0.0

@dataclass
class Schedule:
    def get_current_val(self) -> float:
        return 0.0

@dataclass
class RS0001:
    class PerformanceMap:
        def calculate_performance(self, evap_flow: float, evap_temp: float, cond_flow: float, cond_temp: float, seq_num: float, interp_method: InterpolationMethod) -> Dict[str, float]:
            return {
                "net_evaporator_capacity": 0.0,
                "input_power": 0.0,
                "net_condenser_capacity": 0.0,
                "oil_cooler_heat": 0.0,
                "auxiliary_heat": 0.0
            }
        def get_logger(self) -> Any:
            return None
    
    @dataclass
    class Performance:
        performance_map_cooling: PerformanceMap = field(default_factory=PerformanceMap)
        performance_map_standby: PerformanceMap = field(default_factory=PerformanceMap)
        cycling_degradation_coefficient: float = 0.0
        grid_variables: Dict[str, Any] = field(default_factory=dict)
    
    performance: Performance = field(default_factory=Performance)

@dataclass
class EnergyPlusData:
    dataIPShortCut: Optional[Any] = None
    dataInputProcessing: Optional[Any] = None
    dataChillerElectricASHRAE205: Optional[Any] = None
    dataLoopNodes: Optional[Any] = None
    dataGlobal: Optional[Any] = None
    dataPlnt: Optional[Any] = None
    dataSize: Optional[Any] = None
    dataZoneTempPredictorCorrector: Optional[Any] = None
    dataHVACGlobal: Optional[Any] = None
    dataHeatBal: Optional[Any] = None
    dataFaultsMgr: Optional[Any] = None
    dataOutRptPredefined: Optional[Any] = None

@dataclass
class ElectricEIRChillerSpecs:
    Name: str = ""
    ObjectType: str = "Chiller:Electric:ASHRAE205"
    RefCap: float = 0.0
    RefCapWasAutoSized: bool = False
    RefCOP: float = 3.0
    EvapInletNodeNum: int = 0
    EvapOutletNodeNum: int = 0
    EvapVolFlowRate: float = 0.0
    EvapVolFlowRateWasAutoSized: bool = False
    CondInletNodeNum: int = 0
    CondOutletNodeNum: int = 0
    CondVolFlowRate: float = 0.0
    CondVolFlowRateWasAutoSized: bool = False
    FlowMode: FlowMode = FlowMode.NOT_MODULATED
    CondenserType: CondenserType = CondenserType.WATER_COOLED
    SizFac: float = 1.0
    CWPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    CDPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    MyEnvrnFlag: bool = True
    ModulatedFlowSetToLoop: bool = False
    ModulatedFlowErrDone: bool = False
    ChillerPartLoadRatio: float = 0.0
    ChillerCyclingRatio: float = 1.0
    ChillerFalseLoadRate: float = 0.0
    ChillerFalseLoad: float = 0.0
    PossibleSubcooling: bool = False
    EvapMassFlowRateMax: float = 0.0
    EvapMassFlowRate: float = 0.0
    CondMassFlowRateMax: float = 0.0
    CondMassFlowRate: float = 0.0
    CondMassFlowIndex: int = 0
    EquipFlowCtrl: int = 0
    Power: float = 0.0
    QEvaporator: float = 0.0
    QCondenser: float = 0.0
    Energy: float = 0.0
    EvapEnergy: float = 0.0
    CondEnergy: float = 0.0
    EvapInletTemp: float = 0.0
    EvapOutletTemp: float = 0.0
    CondInletTemp: float = 0.0
    CondOutletTemp: float = 0.0
    ActualCOP: float = 0.0
    ChillerCondAvgTemp: float = 0.0
    MinPartLoadRat: float = 0.0
    TempRefCondIn: float = 29.44
    TempRefEvapOut: float = 6.67
    CompPowerToCondenserFrac: float = 0.0
    DeltaTErrCount: int = 0
    DeltaTErrCountIndex: int = 0
    ChillerCapFTError: int = 0

@dataclass
class ASHRAE205ChillerSpecs(ElectricEIRChillerSpecs):
    Representation: Optional[RS0001] = None
    LoggerContext: Tuple[Optional[EnergyPlusData], str] = field(default_factory=lambda: (None, ""))
    InterpolationType: InterpolationMethod = InterpolationMethod.LINEAR
    MinSequenceNumber: float = 1.0
    MaxSequenceNumber: float = 1.0
    OilCoolerInletNode: int = 0
    OilCoolerOutletNode: int = 0
    OilCoolerVolFlowRate: float = 0.0
    OilCoolerMassFlowRate: float = 0.0
    OCPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    AuxiliaryHeatInletNode: int = 0
    AuxiliaryHeatOutletNode: int = 0
    AuxiliaryVolFlowRate: float = 0.0
    AuxiliaryMassFlowRate: float = 0.0
    AHPlantLoc: PlantLocation = field(default_factory=PlantLocation)
    QOilCooler: float = 0.0
    QAuxiliary: float = 0.0
    OilCoolerEnergy: float = 0.0
    AuxiliaryEnergy: float = 0.0
    AmbientTempType: AmbientTempIndicator = AmbientTempIndicator.INVALID
    ambientTempSched: Optional[Schedule] = None
    AmbientTempZone: int = 0
    AmbientTempOutsideAirNode: int = 0
    AmbientTemp: float = 0.0
    AmbientZoneGain: float = 0.0
    AmbientZoneGainEnergy: float = 0.0
    EndUseSubcategory: str = "General"

@dataclass
class ChillerElectricASHRAE205Data:
    getInputFlag: bool = True
    Electric205Chiller: List[ASHRAE205ChillerSpecs] = field(default_factory=list)

AMBIENT_TEMP_NAMES_UC = ["SCHEDULE", "ZONE", "OUTDOORS"]

INTERP_METHODS = {
    "LINEAR": InterpolationMethod.LINEAR,
    "CUBIC": InterpolationMethod.CUBIC
}

def get_chiller_ashrae205_input(state: EnergyPlusData) -> None:
    routine_name = "getChillerASHRAE205Input"
    
    s_ip = state.dataInputProcessing.inputProcessor
    s_ipsc = state.dataIPShortCut
    
    s_ipsc.cCurrentModuleObject = "Chiller:Electric:ASHRAE205"
    num_electric_205_chillers = s_ip.get_num_objects_found(state, s_ipsc.cCurrentModuleObject)
    
    if num_electric_205_chillers <= 0:
        return
    
    state.dataChillerElectricASHRAE205.Electric205Chiller = [ASHRAE205ChillerSpecs() for _ in range(num_electric_205_chillers)]
    
    chiller_instances = s_ip.epJSON.get(s_ipsc.cCurrentModuleObject, {})
    chiller_num = 0
    object_schema_props = s_ip.get_object_schema_props(state, s_ipsc.cCurrentModuleObject)
    
    for instance_name, fields in chiller_instances.items():
        chiller_num += 1
        this_chiller = state.dataChillerElectricASHRAE205.Electric205Chiller[chiller_num - 1]
        this_chiller.Name = instance_name.upper()
        
        rep_file_name = s_ip.get_alpha_field_value(fields, object_schema_props, "representation_file_name")
        this_chiller.TempRefCondIn = 29.44
        this_chiller.TempRefEvapOut = 6.67

def factory(state: EnergyPlusData, chiller_name: str) -> Optional[ASHRAE205ChillerSpecs]:
    if state.dataChillerElectricASHRAE205.getInputFlag:
        get_chiller_ashrae205_input(state)
        state.dataChillerElectricASHRAE205.getInputFlag = False
    
    for chiller in state.dataChillerElectricASHRAE205.Electric205Chiller:
        if chiller.Name == chiller_name:
            return chiller
    
    return None

def one_time_init_new(self: ASHRAE205ChillerSpecs, state: EnergyPlusData) -> None:
    if self.FlowMode == FlowMode.CONSTANT:
        self.CWPlantLoc.comp.FlowPriority = 0
    elif self.FlowMode == FlowMode.LEAVING_SETPOINT_MODULATED:
        self.CWPlantLoc.comp.FlowPriority = 0
        if (state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint == -999999.0 and
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi == -999999.0):
            if not state.dataGlobal.AnyEnergyManagementSystemInModel:
                if not self.ModulatedFlowErrDone:
                    self.ModulatedFlowErrDone = True
            else:
                state.dataLoopNodes.NodeSetpointCheck[self.EvapOutletNodeNum].needsSetpointChecking = False
            
            self.ModulatedFlowSetToLoop = True
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPoint
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPointHi
    
    set_output_variables(self, state)

def initialize(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, run_flag: bool, my_load: float) -> None:
    routine_name = "ASHRAE205ChillerSpecs::initialize"
    
    if self.AmbientTempType == AmbientTempIndicator.SCHEDULE:
        self.AmbientTemp = self.ambientTempSched.get_current_val()
    elif self.AmbientTempType == AmbientTempIndicator.TEMP_ZONE:
        self.AmbientTemp = state.dataZoneTempPredictorCorrector.zoneHeatBalance[self.AmbientTempZone].MAT
    elif self.AmbientTempType == AmbientTempIndicator.OUTSIDE_AIR:
        self.AmbientTemp = state.dataLoopNodes.Node[self.AmbientTempOutsideAirNode].Temp
    
    self.EquipFlowCtrl = self.CWPlantLoc.comp.FlowCtrl
    
    if self.MyEnvrnFlag and state.dataGlobal.BeginEnvrnFlag and state.dataPlnt.PlantFirstSizesOkayToFinalize:
        rho = self.CWPlantLoc.loop.glycol.get_density(state, 4.4, routine_name)
        self.EvapMassFlowRateMax = rho * self.EvapVolFlowRate
        
        if self.CondenserType == CondenserType.WATER_COOLED:
            rho = self.CDPlantLoc.loop.glycol.get_density(state, self.TempRefCondIn, routine_name)
            self.CondMassFlowRateMax = rho * self.CondVolFlowRate
            state.dataLoopNodes.Node[self.CondInletNodeNum].Temp = self.TempRefCondIn
        
        if self.OilCoolerInletNode != 0:
            rho_oil_cooler = self.OCPlantLoc.loop.glycol.get_density(state, 20.0, routine_name)
            self.OilCoolerMassFlowRate = rho_oil_cooler * self.OilCoolerVolFlowRate
        
        if self.AuxiliaryHeatInletNode != 0:
            rho_aux = self.AHPlantLoc.loop.glycol.get_density(state, 20.0, routine_name)
            self.AuxiliaryMassFlowRate = rho_aux * self.AuxiliaryVolFlowRate
    
    if not state.dataGlobal.BeginEnvrnFlag:
        self.MyEnvrnFlag = True
    
    if self.FlowMode == FlowMode.LEAVING_SETPOINT_MODULATED and self.ModulatedFlowSetToLoop:
        state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPoint
        state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPointHi
    
    mdot = self.EvapMassFlowRateMax if (abs(my_load) > 0.0 and run_flag) else 0.0
    mdot_cond = self.CondMassFlowRateMax if (abs(my_load) > 0.0 and run_flag) else 0.0
    
    if self.CondenserType == CondenserType.WATER_COOLED:
        pass

def size(self: ASHRAE205ChillerSpecs, state: EnergyPlusData) -> None:
    routine_name = "SizeElectricASHRAE205Chiller"
    
    tmp_nom_cap = 0.0
    tmp_evap_vol_flow_rate = self.EvapVolFlowRate
    tmp_cond_vol_flow_rate = self.CondVolFlowRate
    
    plt_siz_num = self.CWPlantLoc.loop.PlantSizNum if self.CWPlantLoc.loop else -1
    
    if plt_siz_num > 0:
        pass

def set_output_variables(self: ASHRAE205ChillerSpecs, state: EnergyPlusData) -> None:
    pass

def find_evaporator_mass_flow_rate(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, load: float, cp: float) -> None:
    routine_name = "ASHRAE205ChillerSpecs::findEvaporatorMassFlowRate"
    
    if self.CWPlantLoc.side.FlowLock == FlowLock.UNLOCKED:
        self.PossibleSubcooling = not (self.CWPlantLoc.comp.CurOpSchemeType == OpScheme.COMP_SET_PT_BASED)
        
        evap_delta_temp = 0.0
        
        if self.FlowMode == FlowMode.CONSTANT or self.FlowMode == FlowMode.NOT_MODULATED:
            self.EvapMassFlowRate = self.EvapMassFlowRateMax
            if self.EvapMassFlowRate != 0.0:
                evap_delta_temp = abs(load) / self.EvapMassFlowRate / cp
            else:
                evap_delta_temp = 0.0
            self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp - evap_delta_temp
        elif self.FlowMode == FlowMode.LEAVING_SETPOINT_MODULATED:
            if self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SINGLE_SET_POINT:
                evap_delta_temp = (state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp - 
                                  state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint)
            elif self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DUAL_SET_POINT_DEAD_BAND:
                evap_delta_temp = (state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp - 
                                  state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi)
            
            if evap_delta_temp != 0:
                self.EvapMassFlowRate = max(0.0, abs(load) / cp / evap_delta_temp)
                self.EvapMassFlowRate = min(self.EvapMassFlowRateMax, self.EvapMassFlowRate)
                if self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SINGLE_SET_POINT:
                    self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint
                elif self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DUAL_SET_POINT_DEAD_BAND:
                    self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi
            else:
                self.EvapMassFlowRate = 0.0
                self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp
                self.QEvaporator = 0.0
                self.ChillerPartLoadRatio = 0.0
    else:
        self.EvapMassFlowRate = state.dataLoopNodes.Node[self.EvapInletNodeNum].MassFlowRate
        if self.EvapMassFlowRate == 0.0:
            load = 0.0
            return
    
    rho = self.CWPlantLoc.loop.glycol.get_density(state, 4.4, routine_name)
    self.EvapVolFlowRate = self.EvapMassFlowRate / rho

def calculate(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, my_load: float, run_flag: bool) -> None:
    routine_name = "CalcElecASHRAE205ChillerModel"
    
    self.ChillerPartLoadRatio = 0.0
    self.ChillerCyclingRatio = 1.0
    self.ChillerFalseLoadRate = 0.0
    self.EvapMassFlowRate = 0.0
    self.CondMassFlowRate = 0.0
    self.Power = 0.0
    self.QCondenser = 0.0
    self.QEvaporator = 0.0
    self.QOilCooler = 0.0
    self.QAuxiliary = 0.0
    
    cond_inlet_temp = state.dataLoopNodes.Node[self.CondInletNodeNum].Temp
    self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapOutletNodeNum].Temp
    
    standby_power = self.Representation.performance.performance_map_standby.calculate_performance(
        self.AmbientTemp, self.InterpolationType
    )["input_power"]
    
    if my_load >= 0 or not run_flag:
        if self.CondenserType == CondenserType.WATER_COOLED:
            pass
        self.Power = standby_power
        self.AmbientZoneGain = standby_power
        return
    
    if self.CondenserType == CondenserType.WATER_COOLED:
        self.CondMassFlowRate = self.CondMassFlowRateMax
        if self.CondMassFlowRate < 0.0001:
            my_load = 0.0
            self.Power = standby_power
            self.AmbientZoneGain = standby_power
            self.EvapMassFlowRate = 0.0
            return
    
    evap_outlet_temp_setpoint = 0.0
    if self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.SINGLE_SET_POINT:
        if (self.FlowMode == FlowMode.LEAVING_SETPOINT_MODULATED or
            self.CWPlantLoc.comp.CurOpSchemeType == OpScheme.COMP_SET_PT_BASED or
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint != -999999.0):
            evap_outlet_temp_setpoint = state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPoint
        else:
            evap_outlet_temp_setpoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPoint
    elif self.CWPlantLoc.loop.LoopDemandCalcScheme == LoopDemandCalcScheme.DUAL_SET_POINT_DEAD_BAND:
        if (self.FlowMode == FlowMode.LEAVING_SETPOINT_MODULATED or
            self.CWPlantLoc.comp.CurOpSchemeType == OpScheme.COMP_SET_PT_BASED or
            state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi != -999999.0):
            evap_outlet_temp_setpoint = state.dataLoopNodes.Node[self.EvapOutletNodeNum].TempSetPointHi
        else:
            evap_outlet_temp_setpoint = state.dataLoopNodes.Node[self.CWPlantLoc.loop.TempSetPointNodeNum].TempSetPointHi
    
    self.EvapMassFlowRate = state.dataLoopNodes.Node[self.EvapInletNodeNum].MassFlowRate
    if self.EvapMassFlowRate == 0.0:
        my_load = 0.0
        return
    
    cp_evap = self.CWPlantLoc.loop.glycol.get_specific_heat(
        state, state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp, routine_name
    )
    
    find_evaporator_mass_flow_rate(self, state, my_load, cp_evap)
    
    maximum_chiller_cap = self.Representation.performance.performance_map_cooling.calculate_performance(
        self.EvapVolFlowRate,
        self.EvapOutletTemp + 273.15,
        self.CondVolFlowRate,
        cond_inlet_temp + 273.15,
        self.MaxSequenceNumber,
        self.InterpolationType
    )["net_evaporator_capacity"]
    
    minimum_chiller_cap = self.Representation.performance.performance_map_cooling.calculate_performance(
        self.EvapVolFlowRate,
        self.EvapOutletTemp + 273.15,
        self.CondVolFlowRate,
        cond_inlet_temp + 273.15,
        self.MinSequenceNumber,
        self.InterpolationType
    )["net_evaporator_capacity"]
    
    self.ChillerPartLoadRatio = max(0.0, abs(my_load) / maximum_chiller_cap) if maximum_chiller_cap > 0 else 0.0
    self.MinPartLoadRat = minimum_chiller_cap / maximum_chiller_cap if maximum_chiller_cap > 0 else 0.0
    part_load_seq_num = 0.0
    
    if self.ChillerPartLoadRatio < self.MinPartLoadRat:
        self.ChillerCyclingRatio = self.ChillerPartLoadRatio / self.MinPartLoadRat
        part_load_seq_num = self.MinSequenceNumber
    elif self.ChillerPartLoadRatio < 1.0:
        def f(seq_num: float) -> float:
            result = self.Representation.performance.performance_map_cooling.calculate_performance(
                self.EvapVolFlowRate,
                self.EvapOutletTemp + 273.15,
                self.CondVolFlowRate,
                cond_inlet_temp + 273.15,
                seq_num,
                self.InterpolationType
            )
            self.QEvaporator = result["net_evaporator_capacity"]
            return abs(my_load) - self.QEvaporator
        part_load_seq_num = self._solve_root(f, self.MinSequenceNumber, self.MaxSequenceNumber)
    else:
        self.QEvaporator = maximum_chiller_cap
        part_load_seq_num = self.MaxSequenceNumber
        find_evaporator_mass_flow_rate(self, state, self.QEvaporator, cp_evap)
    
    lookup_variables_cooling = self.Representation.performance.performance_map_cooling.calculate_performance(
        self.EvapVolFlowRate,
        self.EvapOutletTemp + 273.15,
        self.CondVolFlowRate,
        cond_inlet_temp + 273.15,
        part_load_seq_num,
        self.InterpolationType
    )
    self.QEvaporator = lookup_variables_cooling["net_evaporator_capacity"] * self.ChillerCyclingRatio
    
    evap_delta_temp = self.QEvaporator / self.EvapMassFlowRate / cp_evap
    self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp - evap_delta_temp
    
    cd = self.Representation.performance.cycling_degradation_coefficient
    cycling_factor = (1.0 - cd) + (cd * self.ChillerCyclingRatio)
    runtime_factor = self.ChillerCyclingRatio / cycling_factor
    self.Power = lookup_variables_cooling["input_power"] * runtime_factor + ((1 - self.ChillerCyclingRatio) * standby_power)
    self.QCondenser = lookup_variables_cooling["net_condenser_capacity"] * self.ChillerCyclingRatio
    self.QOilCooler = lookup_variables_cooling["oil_cooler_heat"]
    self.QAuxiliary = lookup_variables_cooling["auxiliary_heat"]
    
    q_externally_cooled = 0.0
    if self.OilCoolerInletNode != 0:
        q_externally_cooled += self.QOilCooler
    if self.AuxiliaryHeatInletNode != 0:
        q_externally_cooled += self.QAuxiliary
    
    self.AmbientZoneGain = self.QEvaporator + self.Power - (self.QCondenser + q_externally_cooled)
    
    cp_cond = self.CDPlantLoc.loop.glycol.get_specific_heat(state, cond_inlet_temp, routine_name)
    self.CondOutletTemp = self.QCondenser / self.CondMassFlowRate / cp_cond + cond_inlet_temp
    
    if self.OilCoolerInletNode != 0:
        oil_cooler_delta_temp = 0.0
        cp_oil_cooler = self.OCPlantLoc.loop.glycol.get_specific_heat(
            state, state.dataLoopNodes.Node[self.OilCoolerInletNode].Temp, routine_name
        )
        if self.OilCoolerMassFlowRate != 0.0:
            oil_cooler_delta_temp = self.QOilCooler / (self.OilCoolerMassFlowRate * cp_oil_cooler)
        state.dataLoopNodes.Node[self.OilCoolerOutletNode].Temp = (
            state.dataLoopNodes.Node[self.OilCoolerInletNode].Temp - oil_cooler_delta_temp
        )
    
    if self.AuxiliaryHeatInletNode != 0:
        auxiliary_delta_temp = 0.0
        cp_aux = self.AHPlantLoc.loop.glycol.get_specific_heat(
            state, state.dataLoopNodes.Node[self.AuxiliaryHeatInletNode].Temp, routine_name
        )
        if self.AuxiliaryMassFlowRate != 0.0:
            auxiliary_delta_temp = self.QAuxiliary / (self.AuxiliaryMassFlowRate * cp_aux)
        state.dataLoopNodes.Node[self.AuxiliaryHeatOutletNode].Temp = (
            state.dataLoopNodes.Node[self.AuxiliaryHeatInletNode].Temp - auxiliary_delta_temp
        )

def update(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, my_load: float, run_flag: bool) -> None:
    if my_load >= 0.0 or not run_flag:
        state.dataLoopNodes.Node[self.EvapOutletNodeNum].Temp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp
        state.dataLoopNodes.Node[self.CondOutletNodeNum].Temp = state.dataLoopNodes.Node[self.CondInletNodeNum].Temp
        if self.OilCoolerInletNode != 0:
            state.dataLoopNodes.Node[self.OilCoolerOutletNode].Temp = state.dataLoopNodes.Node[self.OilCoolerInletNode].Temp
        if self.AuxiliaryHeatInletNode != 0:
            state.dataLoopNodes.Node[self.AuxiliaryHeatOutletNode].Temp = state.dataLoopNodes.Node[self.AuxiliaryHeatInletNode].Temp
        
        self.ChillerPartLoadRatio = 0.0
        self.ChillerCyclingRatio = 0.0
        self.ChillerFalseLoadRate = 0.0
        self.ChillerFalseLoad = 0.0
        self.QEvaporator = 0.0
        self.QCondenser = 0.0
        self.Energy = 0.0
        self.EvapEnergy = 0.0
        self.CondEnergy = 0.0
        self.QOilCooler = 0.0
        self.QAuxiliary = 0.0
        self.OilCoolerEnergy = 0.0
        self.AuxiliaryEnergy = 0.0
        self.EvapInletTemp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp
        self.CondInletTemp = state.dataLoopNodes.Node[self.CondInletNodeNum].Temp
        self.CondOutletTemp = state.dataLoopNodes.Node[self.CondOutletNodeNum].Temp
        self.EvapOutletTemp = state.dataLoopNodes.Node[self.EvapOutletNodeNum].Temp
        self.ActualCOP = 0.0
    else:
        state.dataLoopNodes.Node[self.EvapOutletNodeNum].Temp = self.EvapOutletTemp
        state.dataLoopNodes.Node[self.CondOutletNodeNum].Temp = self.CondOutletTemp
        self.EvapEnergy = self.QEvaporator * state.dataHVACGlobal.TimeStepSysSec
        self.CondEnergy = self.QCondenser * state.dataHVACGlobal.TimeStepSysSec
        self.OilCoolerEnergy = self.QOilCooler * state.dataHVACGlobal.TimeStepSysSec
        self.AuxiliaryEnergy = self.QAuxiliary * state.dataHVACGlobal.TimeStepSysSec
        self.EvapInletTemp = state.dataLoopNodes.Node[self.EvapInletNodeNum].Temp
        self.CondInletTemp = state.dataLoopNodes.Node[self.CondInletNodeNum].Temp
        self.CondOutletTemp = state.dataLoopNodes.Node[self.CondOutletNodeNum].Temp
        if self.Power != 0.0:
            self.ActualCOP = self.QEvaporator / self.Power
        else:
            self.ActualCOP = 0.0
    
    self.AmbientZoneGainEnergy = self.AmbientZoneGain * state.dataHVACGlobal.TimeStepSysSec
    self.Energy = self.Power * state.dataHVACGlobal.TimeStepSysSec

def simulate(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, called_from_location: PlantLocation, 
             first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
    if called_from_location.loop_num == self.CWPlantLoc.loop_num:
        initialize(self, state, run_flag, cur_load)
        calculate(self, state, cur_load, run_flag)
        update(self, state, cur_load, run_flag)
    elif called_from_location.loop_num == self.CDPlantLoc.loop_num:
        pass

def get_design_capacities(self: ASHRAE205ChillerSpecs, state: EnergyPlusData, called_from_location: PlantLocation) -> Tuple[float, float, float]:
    if called_from_location.loop_num == self.CWPlantLoc.loop_num:
        min_load = self.Representation.performance.performance_map_cooling.calculate_performance(
            self.EvapVolFlowRate,
            self.TempRefEvapOut + 273.15,
            self.CondVolFlowRate,
            self.TempRefCondIn + 273.15,
            self.MinSequenceNumber,
            self.InterpolationType
        )["net_evaporator_capacity"]
        max_load = self.RefCap
        opt_load = max_load
        return min_load, max_load, opt_load
    else:
        return 0.0, 0.0, 0.0
