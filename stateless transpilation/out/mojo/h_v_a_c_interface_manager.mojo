"""
EnergyPlus HVAC Interface Manager - Mojo Port
Port of HVACInterfaceManager.hh/.cc
"""

from math import exp, fabs
from collections import InlineArray

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state container, source: EnergyPlus/Data/EnergyPlusData.hh)
# - DataConvergParams (convergence parameters, source: EnergyPlus/DataConvergParams.hh)
# - DataLoopNodes (loop nodes, source: EnergyPlus/DataLoopNodes.hh)
# - DataPlant (plant loop data, source: EnergyPlus/Plant/DataPlant.hh)
# - DataAirLoop (air loop data, source: EnergyPlus/DataAirLoop.hh)
# - DataContaminantBalance (contaminant balance, source: EnergyPlus/DataContaminantBalance.hh)
# - DataHVACGlobals (HVAC globals, source: EnergyPlus/DataHVACGlobals.hh)
# - DataBranchAirLoopPlant (branch constants, source: EnergyPlus/DataBranchAirLoopPlant.hh)
# - FluidProperties (glycol properties, source: EnergyPlus/FluidProperties.hh)
# - PlantUtilities (SetActuatedBranchFlowRate, source: EnergyPlus/PlantUtilities.hh)
# - OutputProcessor (SetupOutputVariable, source: EnergyPlus/OutputProcessor.hh)
# - UtilityRoutines (ShowWarningError, source: EnergyPlus/UtilityRoutines.hh)
# - PlantLocation (struct, source: EnergyPlus/Plant/PlantLocation.hh)

# Constants for Common Pipe Recirc Flow Directions
alias NoRecircFlow = 0
alias PrimaryRecirc = 1
alias SecondaryRecirc = 2

# Convergence log stack depth
alias CONVER_LOG_STACK_DEPTH = 6

# Tolerance constants
alias HVAC_CP_APPROX = 1006.0
alias HVAC_FLOW_RATE_TOLER = 0.01
alias HVAC_HUM_RAT_TOLER = 0.0001
alias HVAC_TEMPERATURE_TOLER = 0.01
alias HVAC_ENERGY_TOLER = 100000.0
alias HVAC_ENTHALPY_TOLER = 100000.0
alias HVAC_PRESS_TOLER = 1.0
alias HVAC_CO2_TOLER = 0.1
alias HVAC_GENCONTAM_TOLER = 1e-8
alias PLANT_FLOW_RATE_TOLER = 0.001
alias PLANT_TEMPERATURE_TOLER = 0.01
alias PLANT_DELTA_TEMP_TOL = 0.01
alias PLANT_MASS_FLOW_TOLERANCE = 0.001


@value
struct FlowType:
    """Flow type enumeration"""
    value: Int32
    
    alias Invalid = FlowType(-1)
    alias Constant = FlowType(0)
    alias Variable = FlowType(1)
    alias Num = FlowType(2)


@value
struct LoopSideLocation:
    """Loop side location enumeration"""
    value: Int32
    
    alias Supply = LoopSideLocation(0)
    alias Demand = LoopSideLocation(1)


@value
struct CommonPipeType:
    """Common pipe type enumeration"""
    value: Int32
    
    alias No = CommonPipeType(0)
    alias Single = CommonPipeType(1)
    alias TwoWay = CommonPipeType(2)


struct CommonPipeData:
    """Common pipe data structure"""
    var CommonPipeType: Int32
    var SupplySideInletPumpType: Int32
    var DemandSideInletPumpType: Int32
    var FlowDir: Int32
    var Flow: Float64
    var Temp: Float64
    var SecCPLegFlow: Float64
    var PriCPLegFlow: Float64
    var SecToPriFlow: Float64
    var PriToSecFlow: Float64
    var PriInTemp: Float64
    var PriOutTemp: Float64
    var SecInTemp: Float64
    var SecOutTemp: Float64
    var PriInletSetPoint: Float64
    var SecInletSetPoint: Float64
    var PriInletControlled: Bool
    var SecInletControlled: Bool
    var PriFlowRequest: Float64
    var MyEnvrnFlag: Bool
    
    fn __init__(inout self):
        self.CommonPipeType = 0
        self.SupplySideInletPumpType = -1
        self.DemandSideInletPumpType = -1
        self.FlowDir = 0
        self.Flow = 0.0
        self.Temp = 0.0
        self.SecCPLegFlow = 0.0
        self.PriCPLegFlow = 0.0
        self.SecToPriFlow = 0.0
        self.PriToSecFlow = 0.0
        self.PriInTemp = 0.0
        self.PriOutTemp = 0.0
        self.SecInTemp = 0.0
        self.SecOutTemp = 0.0
        self.PriInletSetPoint = 0.0
        self.SecInletSetPoint = 0.0
        self.PriInletControlled = False
        self.SecInletControlled = False
        self.PriFlowRequest = 0.0
        self.MyEnvrnFlag = True


struct HVACInterfaceManagerData:
    """Global data for HVAC Interface Manager"""
    var CommonPipeSetupFinished: Bool
    var TmpRealARR: InlineArray[Float64, CONVER_LOG_STACK_DEPTH]
    var PlantCommonPipe: List[CommonPipeData]
    
    fn __init__(inout self):
        self.CommonPipeSetupFinished = False
        self.TmpRealARR = InlineArray[Float64, CONVER_LOG_STACK_DEPTH]()
        self.PlantCommonPipe = List[CommonPipeData]()


# Trait for loop nodes
trait Node:
    fn get_mass_flow_rate(self) -> Float64:
        ...
    
    fn set_mass_flow_rate(inout self, val: Float64):
        ...
    
    fn get_mass_flow_rate_min_avail(self) -> Float64:
        ...
    
    fn set_mass_flow_rate_min_avail(inout self, val: Float64):
        ...
    
    fn get_mass_flow_rate_max_avail(self) -> Float64:
        ...
    
    fn set_mass_flow_rate_max_avail(inout self, val: Float64):
        ...
    
    fn get_temp(self) -> Float64:
        ...
    
    fn set_temp(inout self, val: Float64):
        ...
    
    fn get_hum_rat(self) -> Float64:
        ...
    
    fn set_hum_rat(inout self, val: Float64):
        ...
    
    fn get_enthalpy(self) -> Float64:
        ...
    
    fn set_enthalpy(inout self, val: Float64):
        ...
    
    fn get_quality(self) -> Float64:
        ...
    
    fn set_quality(inout self, val: Float64):
        ...
    
    fn get_press(self) -> Float64:
        ...
    
    fn set_press(inout self, val: Float64):
        ...
    
    fn get_co2(self) -> Float64:
        ...
    
    fn set_co2(inout self, val: Float64):
        ...
    
    fn get_gen_contam(self) -> Float64:
        ...
    
    fn set_gen_contam(inout self, val: Float64):
        ...
    
    fn get_temp_set_point(self) -> Float64:
        ...
    
    fn set_temp_set_point(inout self, val: Float64):
        ...


trait LoopNodes:
    fn node(self, index: Int32) -> Node:
        ...


trait AirLoopConvergence:
    pass


trait PlantConvergence:
    pass


trait Contaminant:
    fn get_co2_simulation(self) -> Bool:
        ...
    
    fn get_generic_contam_simulation(self) -> Bool:
        ...


trait Glycol:
    fn get_specific_heat(inout self, state: EnergyPlusData, temp: Float64, routine_name: String) -> Float64:
        ...


trait LoopSide:
    pass


trait PlantLoop:
    pass


trait PlantData:
    pass


trait ConvergeParams:
    pass


trait AirLoop:
    pass


trait ContaminantBalance:
    pass


trait HVACGlobals:
    pass


trait GlobalData:
    pass


trait PlantLocation:
    fn get_loop_num(self) -> Int32:
        ...
    
    fn get_loop_side_num(self) -> Int32:
        ...


trait EnergyPlusData:
    pass


@always_inline
fn rshift1(inout arr: InlineArray[Float64, CONVER_LOG_STACK_DEPTH]):
    """In-place right shift by 1 of array elements"""
    var last_val = arr[CONVER_LOG_STACK_DEPTH - 1]
    for i in range(CONVER_LOG_STACK_DEPTH - 1, 0, -1):
        arr[i] = arr[i - 1]
    arr[0] = last_val


fn update_hvac_interface(inout state: EnergyPlusData,
                        air_loop_num: Int32,
                        called_from: Int32,
                        outlet_node: Int32,
                        inlet_node: Int32,
                        inout out_of_tolerance_flag: Bool) -> None:
    """Update HVAC interface between air loop sides"""
    
    var tmp_real_arr: InlineArray[Float64, CONVER_LOG_STACK_DEPTH]
    var air_loop_conv = state.dataConvergeParams.air_loop_convergence(air_loop_num)
    var this_inlet_node = state.dataLoopNodes.node(inlet_node)
    var i_call = called_from
    
    if called_from == 1 and outlet_node == 0:
        # Air loop has no return path
        var tot_demand_side_mass_flow: Float64 = 0.0
        var tot_demand_side_min_avail: Float64 = 0.0
        var tot_demand_side_max_avail: Float64 = 0.0
        
        var air_to_zone_info = state.dataAirLoop.air_to_zone_node_info(air_loop_num)
        for dem_in in range(1, air_to_zone_info.num_supply_nodes() + 1):
            var dem_in_node = air_to_zone_info.zone_equip_supply_node_num(dem_in)
            var node = state.dataLoopNodes.node(dem_in_node)
            tot_demand_side_mass_flow += node.get_mass_flow_rate()
            tot_demand_side_min_avail += node.get_mass_flow_rate_min_avail()
            tot_demand_side_max_avail += node.get_mass_flow_rate_max_avail()
        
        var outlet_node_flow = state.dataLoopNodes.node(outlet_node).get_mass_flow_rate()
        var inlet_node_flow = this_inlet_node.get_mass_flow_rate()
        var flow_diff = fabs(tot_demand_side_mass_flow - inlet_node_flow)
        
        if flow_diff > HVAC_FLOW_RATE_TOLER:
            out_of_tolerance_flag = True
        
        this_inlet_node.set_mass_flow_rate(tot_demand_side_mass_flow)
        this_inlet_node.set_mass_flow_rate_min_avail(tot_demand_side_min_avail)
        this_inlet_node.set_mass_flow_rate_max_avail(tot_demand_side_max_avail)
        return
    
    var delta_energy = (HVAC_CP_APPROX * 
                       (state.dataLoopNodes.node(outlet_node).get_mass_flow_rate() * 
                        state.dataLoopNodes.node(outlet_node).get_temp() -
                        this_inlet_node.get_mass_flow_rate() * this_inlet_node.get_temp()))
    
    if called_from == 1 and outlet_node > 0:
        # AirSystemDemandSide with outlet node
        var outlet_mass_flow = state.dataLoopNodes.node(outlet_node).get_mass_flow_rate()
        var inlet_mass_flow = this_inlet_node.get_mass_flow_rate()
        var outlet_hum_rat = state.dataLoopNodes.node(outlet_node).get_hum_rat()
        var inlet_hum_rat = this_inlet_node.get_hum_rat()
        var outlet_temp = state.dataLoopNodes.node(outlet_node).get_temp()
        var inlet_temp = this_inlet_node.get_temp()
        var outlet_enthalpy = state.dataLoopNodes.node(outlet_node).get_enthalpy()
        var inlet_enthalpy = this_inlet_node.get_enthalpy()
        var outlet_press = state.dataLoopNodes.node(outlet_node).get_press()
        var inlet_press = this_inlet_node.get_press()
        
        if fabs(outlet_mass_flow - inlet_mass_flow) > HVAC_FLOW_RATE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_hum_rat - inlet_hum_rat) > HVAC_HUM_RAT_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_temp - inlet_temp) > HVAC_TEMPERATURE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(delta_energy) > HVAC_ENERGY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_enthalpy - inlet_enthalpy) > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_press - inlet_press) > HVAC_PRESS_TOLER:
            out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_co2_simulation():
            var outlet_co2 = state.dataLoopNodes.node(outlet_node).get_co2()
            var inlet_co2 = this_inlet_node.get_co2()
            if fabs(outlet_co2 - inlet_co2) > HVAC_CO2_TOLER:
                out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_generic_contam_simulation():
            var outlet_gen_contam = state.dataLoopNodes.node(outlet_node).get_gen_contam()
            var inlet_gen_contam = this_inlet_node.get_gen_contam()
            if fabs(outlet_gen_contam - inlet_gen_contam) > HVAC_GENCONTAM_TOLER:
                out_of_tolerance_flag = True
    
    elif called_from == 2:
        # AirSystemSupplySideDeck1
        var outlet_mass_flow = state.dataLoopNodes.node(outlet_node).get_mass_flow_rate()
        var inlet_mass_flow = this_inlet_node.get_mass_flow_rate()
        var outlet_hum_rat = state.dataLoopNodes.node(outlet_node).get_hum_rat()
        var inlet_hum_rat = this_inlet_node.get_hum_rat()
        var outlet_temp = state.dataLoopNodes.node(outlet_node).get_temp()
        var inlet_temp = this_inlet_node.get_temp()
        var outlet_enthalpy = state.dataLoopNodes.node(outlet_node).get_enthalpy()
        var inlet_enthalpy = this_inlet_node.get_enthalpy()
        var outlet_press = state.dataLoopNodes.node(outlet_node).get_press()
        var inlet_press = this_inlet_node.get_press()
        
        if fabs(outlet_mass_flow - inlet_mass_flow) > HVAC_FLOW_RATE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_hum_rat - inlet_hum_rat) > HVAC_HUM_RAT_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_temp - inlet_temp) > HVAC_TEMPERATURE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(delta_energy) > HVAC_ENERGY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_enthalpy - inlet_enthalpy) > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_press - inlet_press) > HVAC_PRESS_TOLER:
            out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_co2_simulation():
            var outlet_co2 = state.dataLoopNodes.node(outlet_node).get_co2()
            var inlet_co2 = this_inlet_node.get_co2()
            if fabs(outlet_co2 - inlet_co2) > HVAC_CO2_TOLER:
                out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_generic_contam_simulation():
            var outlet_gen_contam = state.dataLoopNodes.node(outlet_node).get_gen_contam()
            var inlet_gen_contam = this_inlet_node.get_gen_contam()
            if fabs(outlet_gen_contam - inlet_gen_contam) > HVAC_GENCONTAM_TOLER:
                out_of_tolerance_flag = True
    
    elif called_from == 3:
        # AirSystemSupplySideDeck2
        var outlet_mass_flow = state.dataLoopNodes.node(outlet_node).get_mass_flow_rate()
        var inlet_mass_flow = this_inlet_node.get_mass_flow_rate()
        var outlet_hum_rat = state.dataLoopNodes.node(outlet_node).get_hum_rat()
        var inlet_hum_rat = this_inlet_node.get_hum_rat()
        var outlet_temp = state.dataLoopNodes.node(outlet_node).get_temp()
        var inlet_temp = this_inlet_node.get_temp()
        var outlet_enthalpy = state.dataLoopNodes.node(outlet_node).get_enthalpy()
        var inlet_enthalpy = this_inlet_node.get_enthalpy()
        var outlet_press = state.dataLoopNodes.node(outlet_node).get_press()
        var inlet_press = this_inlet_node.get_press()
        
        if fabs(outlet_mass_flow - inlet_mass_flow) > HVAC_FLOW_RATE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_hum_rat - inlet_hum_rat) > HVAC_HUM_RAT_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_temp - inlet_temp) > HVAC_TEMPERATURE_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(delta_energy) > HVAC_ENERGY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_enthalpy - inlet_enthalpy) > HVAC_ENTHALPY_TOLER:
            out_of_tolerance_flag = True
        
        if fabs(outlet_press - inlet_press) > HVAC_PRESS_TOLER:
            out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_co2_simulation():
            var outlet_co2 = state.dataLoopNodes.node(outlet_node).get_co2()
            var inlet_co2 = this_inlet_node.get_co2()
            if fabs(outlet_co2 - inlet_co2) > HVAC_CO2_TOLER:
                out_of_tolerance_flag = True
        
        if state.dataContaminantBalance.contaminant().get_generic_contam_simulation():
            var outlet_gen_contam = state.dataLoopNodes.node(outlet_node).get_gen_contam()
            var inlet_gen_contam = this_inlet_node.get_gen_contam()
            if fabs(outlet_gen_contam - inlet_gen_contam) > HVAC_GENCONTAM_TOLER:
                out_of_tolerance_flag = True
    
    # Always update inlet conditions
    this_inlet_node.set_temp(state.dataLoopNodes.node(outlet_node).get_temp())
    this_inlet_node.set_mass_flow_rate(state.dataLoopNodes.node(outlet_node).get_mass_flow_rate())
    this_inlet_node.set_mass_flow_rate_min_avail(state.dataLoopNodes.node(outlet_node).get_mass_flow_rate_min_avail())
    this_inlet_node.set_mass_flow_rate_max_avail(state.dataLoopNodes.node(outlet_node).get_mass_flow_rate_max_avail())
    this_inlet_node.set_quality(state.dataLoopNodes.node(outlet_node).get_quality())
    this_inlet_node.set_press(state.dataLoopNodes.node(outlet_node).get_press())
    this_inlet_node.set_enthalpy(state.dataLoopNodes.node(outlet_node).get_enthalpy())
    this_inlet_node.set_hum_rat(state.dataLoopNodes.node(outlet_node).get_hum_rat())
    
    if state.dataContaminantBalance.contaminant().get_co2_simulation():
        this_inlet_node.set_co2(state.dataLoopNodes.node(outlet_node).get_co2())
    
    if state.dataContaminantBalance.contaminant().get_generic_contam_simulation():
        this_inlet_node.set_gen_contam(state.dataLoopNodes.node(outlet_node).get_gen_contam())


fn update_plant_loop_interface(inout state: EnergyPlusData,
                               plant_loc: PlantLocation,
                               this_loop_side_outlet_node: Int32,
                               other_loop_side_inlet_node: Int32,
                               inout out_of_tolerance_flag: Bool,
                               common_pipe_type: Int32) -> None:
    """Update plant loop interface"""
    pass


fn update_half_loop_inlet_temp(inout state: EnergyPlusData,
                               loop_num: Int32,
                               tank_inlet_loop_side: Int32,
                               inout tank_outlet_temp: Float64) -> None:
    """Update half loop inlet temperature based on capacitance"""
    pass


fn update_common_pipe(inout state: EnergyPlusData,
                     tank_inlet_plant_loc: PlantLocation,
                     common_pipe_type: Int32,
                     inout mixed_outlet_temp: Float64) -> None:
    """Update common pipe temperatures and flow rates"""
    pass


fn manage_single_common_pipe(inout state: EnergyPlusData,
                             loop_num: Int32,
                             loop_side: Int32,
                             tank_outlet_temp: Float64,
                             inout mixed_outlet_temp: Float64) -> None:
    """Manage single common pipe flow and temperature"""
    pass


fn manage_two_way_common_pipe(inout state: EnergyPlusData,
                              plant_loc: PlantLocation,
                              tank_outlet_temp: Float64) -> None:
    """Manage two-way common pipe with iterative solution"""
    pass


fn setup_common_pipes(inout state: EnergyPlusData) -> None:
    """Set up common pipes and output variables"""
    pass
