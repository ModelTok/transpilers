# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state struct from EnergyPlus.Data.EnergyPlusData
# - PlantComponent: base struct from EnergyPlus.PlantComponent
# - PlantLocation: struct from EnergyPlus.Plant.PlantLocation
# - Schedule: struct from EnergyPlus.ScheduleManager
# - Node operations: GetOnlySingleNode, TestCompSet from EnergyPlus.NodeInputManager
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, ScanPlantLoopsForObject, RegisterPlantCompDesignFlow
# - InputProcessor: getNumObjectsFound, getObjectItem
# - OutputProcessor: SetupOutputVariable, SetupEMSActuator, TimeStepType, StoreType
# - DataSizing: AutoSize constant
# - DataLoopNode: Node array access
# - DataHVACGlobals: TimeStepSysSec
# - General utilities: ShowFatalError, ShowSevereError, ShowMessage, ShowContinueError, format
# - FluidProperties: getDensity, getSpecificHeat
# - Constants: InitConvTemp, BigNumber
# - BaseSizer: reportSizerOutput
# - ErrorObjectHeader: from error handling
# - Enums: DataPlant.PlantEquipmentType, Node.ConnectionObjectType, Node.FluidType, Node.ConnectionType, Node.CompFluidStream, Node.ObjectIsNotParent
# - math: abs, min

from math import abs as math_abs, min as math_min


@value
struct TempSpecType:
    """Temperature specification type enumeration"""
    alias Invalid = -1
    alias Constant = 0
    alias Schedule = 1
    alias Num = 2


@value
struct WaterSourceSpecs:
    """Water source specifications struct extending PlantComponent"""
    
    var name: String
    var inlet_node_num: Int32
    var outlet_node_num: Int32
    var des_vol_flow_rate: Float64
    var des_vol_flow_rate_was_autosized: Bool
    var mass_flow_rate_max: Float64
    var ems_override_on_mass_flow_rate_max: Bool
    var ems_override_value_mass_flow_rate_max: Float64
    var mass_flow_rate: Float64
    var temp_spec_type: Int32
    var temp_spec_sched: UnsafePointer[UInt8]
    var boundary_temp: Float64
    var outlet_temp: Float64
    var inlet_temp: Float64
    var heat_rate: Float64
    var heat_energy: Float64
    var plant_loc: PlantLocation
    var siz_fac: Float64
    var check_equip_name: Bool
    var my_flag: Bool
    var my_environ_flag: Bool
    var is_this_sized: Bool
    
    fn __init__(inout self):
        self.name = String()
        self.inlet_node_num = 0
        self.outlet_node_num = 0
        self.des_vol_flow_rate = 0.0
        self.des_vol_flow_rate_was_autosized = False
        self.mass_flow_rate_max = 0.0
        self.ems_override_on_mass_flow_rate_max = False
        self.ems_override_value_mass_flow_rate_max = 0.0
        self.mass_flow_rate = 0.0
        self.temp_spec_type = TempSpecType.Invalid
        self.temp_spec_sched = UnsafePointer[UInt8]()
        self.boundary_temp = 0.0
        self.outlet_temp = 0.0
        self.inlet_temp = 0.0
        self.heat_rate = 0.0
        self.heat_energy = 0.0
        self.plant_loc = PlantLocation()
        self.siz_fac = 0.0
        self.check_equip_name = True
        self.my_flag = True
        self.my_environ_flag = True
        self.is_this_sized = False
    
    fn factory(inout self, state: UnsafePointer[EnergyPlusData], object_name: String) -> UnsafePointer[WaterSourceSpecs]:
        """Factory method to get or create a water source by name"""
        if state[].data_plant_comp_temp_src.get_water_source_input:
            GetWaterSourceInput(state)
            state[].data_plant_comp_temp_src.get_water_source_input = False
        
        for i in range(state[].data_plant_comp_temp_src.water_source.size()):
            if state[].data_plant_comp_temp_src.water_source[i].name == object_name:
                return UnsafePointer.address_of(state[].data_plant_comp_temp_src.water_source[i])
        
        ShowFatalError(state, format("LocalTemperatureSourceFactory: Error getting inputs for temperature source named: {}", object_name))
        return UnsafePointer[WaterSourceSpecs]()
    
    fn initialize(inout self, state: UnsafePointer[EnergyPlusData], my_load: Float64) -> None:
        """Initialize water source for simulation step"""
        let routine_name = StringLiteral("InitWaterSource")
        
        self.oneTimeInit(state)
        
        if self.my_environ_flag and state[].data_global.begin_envrnflag and state[].data_plnt.plant_first_sizes_okay_to_finalize:
            let rho = self.plant_loc.loop.glycol.getDensity(state, Constant.InitConvTemp, routine_name)
            self.mass_flow_rate_max = self.des_vol_flow_rate * rho
            InitComponentNodes(state, 0.0, self.mass_flow_rate_max, self.inlet_node_num, self.outlet_node_num)
            self.my_environ_flag = False
        
        if not state[].data_global.begin_envrnflag:
            self.my_environ_flag = True
        
        self.inlet_temp = state[].data_loop_nodes.node[self.inlet_node_num].temp
        if self.temp_spec_type == TempSpecType.Schedule:
            self.boundary_temp = self.temp_spec_sched[].getCurrentVal()
        
        let cp = self.plant_loc.loop.glycol.getSpecificHeat(state, self.boundary_temp, routine_name)
        
        let delta_temp = self.boundary_temp - self.inlet_temp
        
        if math_abs(delta_temp) < 0.001:
            if math_abs(my_load) < 0.001:
                self.mass_flow_rate = 0.0
            else:
                self.mass_flow_rate = self.mass_flow_rate_max
        else:
            self.mass_flow_rate = my_load / (cp * delta_temp)
        
        if self.mass_flow_rate < 0:
            self.mass_flow_rate = 0.0
        else:
            if not self.ems_override_on_mass_flow_rate_max:
                self.mass_flow_rate = math_min(self.mass_flow_rate, self.mass_flow_rate_max)
            else:
                self.mass_flow_rate = math_min(self.mass_flow_rate, self.ems_override_value_mass_flow_rate_max)
        
        SetComponentFlowRate(state, self.mass_flow_rate, self.inlet_node_num, self.outlet_node_num, self.plant_loc)
    
    fn setupOutputVars(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Setup output variables for tracking"""
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Mass Flow Rate",
            Constant.Units.kg_s,
            UnsafePointer.address_of(self.mass_flow_rate),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Inlet Temperature",
            Constant.Units.C,
            UnsafePointer.address_of(self.inlet_temp),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Outlet Temperature",
            Constant.Units.C,
            UnsafePointer.address_of(self.outlet_temp),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Source Temperature",
            Constant.Units.C,
            UnsafePointer.address_of(self.boundary_temp),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Heat Transfer Rate",
            Constant.Units.W,
            UnsafePointer.address_of(self.heat_rate),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Average,
            self.name
        )
        SetupOutputVariable(
            state,
            "Plant Temperature Source Component Heat Transfer Energy",
            Constant.Units.J,
            UnsafePointer.address_of(self.heat_energy),
            OutputProcessor.TimeStepType.System,
            OutputProcessor.StoreType.Sum,
            self.name
        )
        
        if state[].data_global.any_energy_management_system_in_model:
            SetupEMSActuator(
                state,
                "PlantComponent:TemperatureSource",
                self.name,
                "Maximum Mass Flow Rate",
                "[kg/s]",
                UnsafePointer.address_of(self.ems_override_on_mass_flow_rate_max),
                UnsafePointer.address_of(self.ems_override_value_mass_flow_rate_max)
            )
    
    fn autosize(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Autosize design flow rate"""
        var errors_found = False
        var des_vol_flow_rate_user: Float64 = 0.0
        var tmp_vol_flow_rate = self.des_vol_flow_rate
        let plt_siz_num = self.plant_loc.loop.plant_siz_num
        
        if plt_siz_num > 0:
            if state[].data_size.plant_siz_data[plt_siz_num - 1].des_vol_flow_rate >= HVAC.SmallWaterVolFlow:
                tmp_vol_flow_rate = state[].data_size.plant_siz_data[plt_siz_num - 1].des_vol_flow_rate
                if not self.des_vol_flow_rate_was_autosized:
                    tmp_vol_flow_rate = self.des_vol_flow_rate
            else:
                if self.des_vol_flow_rate_was_autosized:
                    tmp_vol_flow_rate = 0.0
            
            if state[].data_plnt.plant_first_sizes_okay_to_finalize:
                if self.des_vol_flow_rate_was_autosized:
                    self.des_vol_flow_rate = tmp_vol_flow_rate
                    if state[].data_plnt.plant_final_sizes_okay_to_report:
                        BaseSizer.reportSizerOutput(
                            state, "PlantComponent:TemperatureSource", self.name,
                            "Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate
                        )
                    if state[].data_plnt.plant_first_sizes_okay_to_report:
                        BaseSizer.reportSizerOutput(
                            state, "PlantComponent:TemperatureSource", self.name,
                            "Initial Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate
                        )
                else:
                    if self.des_vol_flow_rate > 0.0 and tmp_vol_flow_rate > 0.0:
                        des_vol_flow_rate_user = self.des_vol_flow_rate
                        if state[].data_plnt.plant_final_sizes_okay_to_report:
                            BaseSizer.reportSizerOutput(
                                state, "PlantComponent:TemperatureSource", self.name,
                                "Design Size Design Fluid Flow Rate [m3/s]", tmp_vol_flow_rate,
                                "User-Specified Design Fluid Flow Rate [m3/s]", des_vol_flow_rate_user
                            )
                            if state[].data_global.display_extra_warnings:
                                if (math_abs(tmp_vol_flow_rate - des_vol_flow_rate_user) / des_vol_flow_rate_user) > state[].data_size.auto_vs_hard_sizing_threshold:
                                    ShowMessage(state, format("SizePlantComponentTemperatureSource: Potential issue with equipment sizing for {}", self.name))
                                    ShowContinueError(state, format("User-Specified Design Fluid Flow Rate of {:.5R} [m3/s]", des_vol_flow_rate_user))
                                    ShowContinueError(state, format("differs from Design Size Design Fluid Flow Rate of {:.5R} [m3/s]", tmp_vol_flow_rate))
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
                        tmp_vol_flow_rate = des_vol_flow_rate_user
        else:
            if self.des_vol_flow_rate_was_autosized and state[].data_plnt.plant_first_sizes_okay_to_finalize:
                ShowSevereError(state, "Autosizing of plant component temperature source flow rate requires a loop Sizing:Plant object")
                ShowContinueError(state, format("Occurs in PlantComponent:TemperatureSource object={}", self.name))
                errors_found = True
            if not self.des_vol_flow_rate_was_autosized and state[].data_plnt.plant_final_sizes_okay_to_report:
                if self.des_vol_flow_rate > 0.0:
                    BaseSizer.reportSizerOutput(
                        state, "PlantComponent:TemperatureSource", self.name,
                        "User-Specified Design Fluid Flow Rate [m3/s]", self.des_vol_flow_rate
                    )
        
        RegisterPlantCompDesignFlow(state, self.inlet_node_num, tmp_vol_flow_rate)
        
        if errors_found:
            ShowFatalError(state, "Preceding sizing errors cause program termination")
    
    fn calculate(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Calculate outlet temperature and heat transfer"""
        let routine_name = StringLiteral("CalcWaterSource")
        
        if self.mass_flow_rate > 0.0:
            self.outlet_temp = self.boundary_temp
            let cp = self.plant_loc.loop.glycol.getSpecificHeat(state, self.boundary_temp, routine_name)
            self.heat_rate = self.mass_flow_rate * cp * (self.outlet_temp - self.inlet_temp)
            self.heat_energy = self.heat_rate * state[].data_hvac_global.time_step_sys_sec
        else:
            self.outlet_temp = self.boundary_temp
            self.heat_rate = 0.0
            self.heat_energy = 0.0
    
    fn update(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Update node with outlet temperature"""
        state[].data_loop_nodes.node[self.outlet_node_num].temp = self.outlet_temp
    
    fn simulate(inout self, state: UnsafePointer[EnergyPlusData], called_from_location: PlantLocation, first_hvac_iteration: Bool, cur_load: Float64, run_flag: Bool) -> None:
        """Simulate the water source component"""
        self.initialize(state, cur_load)
        self.calculate(state)
        self.update(state)
    
    fn getDesignCapacities(inout self, state: UnsafePointer[EnergyPlusData], called_from_location: PlantLocation) -> Tuple[Float64, Float64, Float64]:
        """Get design capacity bounds"""
        return (Constant.BigNumber, 0.0, Constant.BigNumber)
    
    fn getSizingFactor(inout self) -> Float64:
        """Get sizing factor"""
        return self.siz_fac
    
    fn onInitLoopEquip(inout self, state: UnsafePointer[EnergyPlusData], called_from_location: PlantLocation) -> None:
        """Initialize on loop equipment setup"""
        var my_load: Float64 = 0.0
        self.initialize(state, my_load)
        self.autosize(state)
    
    fn oneTimeInit(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """One-time initialization"""
        let routine_name = StringLiteral("InitWaterSource")
        
        if self.my_flag:
            self.setupOutputVars(state)
            var err_flag = False
            ScanPlantLoopsForObject(
                state, self.name, DataPlant.PlantEquipmentType.WaterSource, UnsafePointer.address_of(self.plant_loc), err_flag,
                UnsafePointer[Int32](), UnsafePointer[Int32](), UnsafePointer[Int32](), self.inlet_node_num, UnsafePointer[Int32]()
            )
            if err_flag:
                ShowFatalError(state, format("{}: Program terminated due to previous condition(s).", routine_name))
            self.my_flag = False


@value
struct PlantCompTempSrcData:
    """Global data structure for plant component temperature sources"""
    
    var num_sources: Int32
    var get_water_source_input: Bool
    var water_source: DynamicVector[WaterSourceSpecs]
    
    fn __init__(inout self):
        self.num_sources = 0
        self.get_water_source_input = True
        self.water_source = DynamicVector[WaterSourceSpecs]()
    
    fn init_constant_state(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Initialize constant state"""
        pass
    
    fn init_state(inout self, state: UnsafePointer[EnergyPlusData]) -> None:
        """Initialize state"""
        pass
    
    fn clear_state(inout self) -> None:
        """Clear state"""
        self.num_sources = 0
        self.get_water_source_input = True
        self.water_source = DynamicVector[WaterSourceSpecs]()


fn GetWaterSourceInput(state: UnsafePointer[EnergyPlusData]) -> None:
    """Get water source input from input file"""
    let routine_name = StringLiteral("GetWaterSourceInput")
    let c_current_module_object = StringLiteral("PlantComponent:TemperatureSource")
    
    state[].data_plant_comp_temp_src.num_sources = state[].data_input_processing.input_processor.getNumObjectsFound(
        state, c_current_module_object
    )
    
    if state[].data_plant_comp_temp_src.num_sources <= 0:
        ShowSevereError(state, format("No {} equipment specified in input file", c_current_module_object))
        return
    
    if state[].data_plant_comp_temp_src.water_source.size() > 0:
        return
    
    for i in range(state[].data_plant_comp_temp_src.num_sources):
        state[].data_plant_comp_temp_src.water_source.push_back(WaterSourceSpecs())
    
    for source_num in range(state[].data_plant_comp_temp_src.num_sources):
        let c_alpha_args = state[].data_input_processing.input_processor.getObjectItemAlpha(
            state, c_current_module_object, source_num + 1
        )
        let r_numeric_args = state[].data_input_processing.input_processor.getObjectItemNumeric(
            state, c_current_module_object, source_num + 1
        )
        
        state[].data_plant_comp_temp_src.water_source[source_num].name = c_alpha_args[0]
        
        state[].data_plant_comp_temp_src.water_source[source_num].inlet_node_num = GetOnlySingleNode(
            state, c_alpha_args[1], False, "PlantComponentTemperatureSource",
            c_alpha_args[0], "Water", "Inlet", "Primary", "NotParent"
        )
        
        state[].data_plant_comp_temp_src.water_source[source_num].outlet_node_num = GetOnlySingleNode(
            state, c_alpha_args[2], False, "PlantComponentTemperatureSource",
            c_alpha_args[0], "Water", "Outlet", "Primary", "NotParent"
        )
        
        TestCompSet(
            state, c_current_module_object, c_alpha_args[0],
            c_alpha_args[1], c_alpha_args[2], "Chilled Water Nodes"
        )
        
        state[].data_plant_comp_temp_src.water_source[source_num].des_vol_flow_rate = r_numeric_args[0]
        if state[].data_plant_comp_temp_src.water_source[source_num].des_vol_flow_rate == DataSizing.AutoSize:
            state[].data_plant_comp_temp_src.water_source[source_num].des_vol_flow_rate_was_autosized = True
        
        if c_alpha_args[3] == "CONSTANT":
            state[].data_plant_comp_temp_src.water_source[source_num].temp_spec_type = TempSpecType.Constant
            state[].data_plant_comp_temp_src.water_source[source_num].boundary_temp = r_numeric_args[1]
        elif c_alpha_args[3] == "SCHEDULED":
            state[].data_plant_comp_temp_src.water_source[source_num].temp_spec_type = TempSpecType.Schedule
            let sched = GetSchedule(state, c_alpha_args[4])
            if sched == UnsafePointer[Schedule]():
                ShowSevereItemNotFound(state, routine_name, c_current_module_object, c_alpha_args[4])
            else:
                state[].data_plant_comp_temp_src.water_source[source_num].temp_spec_sched = sched
        else:
            ShowSevereError(state, format("Input error for {}={}", c_current_module_object, c_alpha_args[0]))
            ShowContinueError(
                state,
                format(
                    'Invalid temperature specification type.  Expected either "Constant" or "Scheduled". Encountered {}',
                    c_alpha_args[3]
                )
            )
