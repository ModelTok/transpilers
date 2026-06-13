from typing import Optional, List, Any, Tuple
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state object (state.dataLoopNodes, state.dataEnvrn, state.dataIPShortCut, etc.)
# - PlantComponent: base class stub
# - Curve: curve object with value(state, x) -> float method
# - PlantLocation: object with .loop reference containing .glycol
# - Constant.eFuel: fuel type enum and eFuelNames, eFuelNamesUC lists
# - Constant.eFuel2eResource: mapping of fuel types to resource types
# - Constant.Units: output variable units enum
# - Constant.eResource: resource type enum
# - Constant.InitConvTemp: constant for initialization temperature
# - Node utilities: GetOnlySingleNode, TestCompSet, ConnectionObjectType, FluidType, ConnectionType, CompFluidStream, ObjectIsNotParent
# - Curve.GetCurve(state, name) -> Optional[Curve]
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, RegisterPlantDesignFlow, ScanPlantLoopsForObject
# - OutputProcessor: SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
# - UtilityRoutines: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowWarningError, ShowContinueError
# - DataEnvironment: OutDryBulbTemp, BeginEnvrnFlag
# - DataLoopNode: Node objects with .Temp, .MassFlowRate attributes
# - DataHVACGlobals: TimeStepSysSec
# - DataPlant: PlantEquipmentType
# - OutAirNodeManager: CheckOutAirNodeNumber
# - Util.makeUPPER(s) -> str
# - InputProcessor: getNumObjectsFound, getObjectSchemaProps, epJSON, getAlphaFieldValue, getRealFieldValue, markObjectAsUsed
# - ErrorObjectHeader: error context object
# - getEnumValue: utility to get enum value from name

class GeneratorType:
    CombTurbine = 0

@dataclass
class CTGeneratorData:
    Name: str = ""
    TypeOf: str = "Generator:CombustionTurbine"
    CompType_Num: int = GeneratorType.CombTurbine
    FuelType: int = -1
    RatedPowerOutput: float = 0.0
    ElectricCircuitNode: int = 0
    MinPartLoadRat: float = 0.0
    MaxPartLoadRat: float = 0.0
    OptPartLoadRat: float = 0.0
    FuelEnergyUseRate: float = 0.0
    FuelEnergy: float = 0.0
    PLBasedFuelInputCurve: Optional[Any] = None
    TempBasedFuelInputCurve: Optional[Any] = None
    ExhaustFlow: float = 0.0
    ExhaustFlowCurve: Optional[Any] = None
    ExhaustTemp: float = 0.0
    PLBasedExhaustTempCurve: Optional[Any] = None
    TempBasedExhaustTempCurve: Optional[Any] = None
    QLubeOilRecovered: float = 0.0
    QExhaustRecovered: float = 0.0
    QTotalHeatRecovered: float = 0.0
    LubeOilEnergyRec: float = 0.0
    ExhaustEnergyRec: float = 0.0
    TotalHeatEnergyRec: float = 0.0
    QLubeOilRecoveredCurve: Optional[Any] = None
    UA: float = 0.0
    UACoef: List[float] = field(default_factory=lambda: [0.0, 0.0])
    MaxExhaustperCTPower: float = 0.0
    DesignHeatRecVolFlowRate: float = 0.0
    DesignHeatRecMassFlowRate: float = 0.0
    DesignMinExitGasTemp: float = 0.0
    DesignAirInletTemp: float = 0.0
    ExhaustStackTemp: float = 0.0
    HeatRecActive: bool = False
    HeatRecInletNodeNum: int = 0
    HeatRecOutletNodeNum: int = 0
    HeatRecInletTemp: float = 0.0
    HeatRecOutletTemp: float = 0.0
    HeatRecMdot: float = 0.0
    HRPlantLoc: Optional[Any] = None
    FuelMdot: float = 0.0
    FuelHeatingValue: float = 0.0
    ElecPowerGenerated: float = 0.0
    ElecEnergyGenerated: float = 0.0
    HeatRecMaxTemp: float = 0.0
    OAInletNode: int = 0
    MyEnvrnFlag: bool = True
    MyPlantScanFlag: bool = True
    MySizeAndNodeInitFlag: bool = True
    CheckEquipName: bool = True
    MyFlag: bool = True

    def simulate(self, state: Any, called_from_location: Any, first_hvac_iteration: bool, 
                 cur_load: float, run_flag: bool) -> None:
        pass

    def setup_output_vars(self, state: Any) -> None:
        s_fuel_type = state.Constant_eFuelNames[int(self.FuelType)]
        
        state.SetupOutputVariable(
            "Generator Produced AC Electricity Rate",
            state.Constant_Units_W,
            self.ElecPowerGenerated,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        state.SetupOutputVariable(
            "Generator Produced AC Electricity Energy",
            state.Constant_Units_J,
            self.ElecEnergyGenerated,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Sum,
            self.Name,
            state.Constant_eResource_ElectricityProduced,
            state.OutputProcessor_Group_Plant,
            state.OutputProcessor_EndUseCat_Cogeneration
        )

        state.SetupOutputVariable(
            f"Generator {s_fuel_type} Rate",
            state.Constant_Units_W,
            self.FuelEnergyUseRate,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        state.SetupOutputVariable(
            f"Generator {s_fuel_type} Energy",
            state.Constant_Units_J,
            self.FuelEnergy,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Sum,
            self.Name,
            state.Constant_eFuel2eResource[int(self.FuelType)],
            state.OutputProcessor_Group_Plant,
            state.OutputProcessor_EndUseCat_Cogeneration
        )

        state.SetupOutputVariable(
            "Generator Fuel HHV Basis Rate",
            state.Constant_Units_W,
            self.FuelEnergyUseRate,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        state.SetupOutputVariable(
            "Generator Fuel HHV Basis Energy",
            state.Constant_Units_J,
            self.FuelEnergy,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Sum,
            self.Name
        )

        state.SetupOutputVariable(
            f"Generator {s_fuel_type} Mass Flow Rate",
            state.Constant_Units_kg_s,
            self.FuelMdot,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        state.SetupOutputVariable(
            "Generator Exhaust Air Temperature",
            state.Constant_Units_C,
            self.ExhaustStackTemp,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        if self.HeatRecActive:
            state.SetupOutputVariable(
                "Generator Exhaust Heat Recovery Rate",
                state.Constant_Units_W,
                self.QExhaustRecovered,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Exhaust Heat Recovery Energy",
                state.Constant_Units_J,
                self.ExhaustEnergyRec,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Sum,
                self.Name,
                state.Constant_eResource_EnergyTransfer,
                state.OutputProcessor_Group_Plant,
                state.OutputProcessor_EndUseCat_HeatRecovery
            )

            state.SetupOutputVariable(
                "Generator Lube Heat Recovery Rate",
                state.Constant_Units_W,
                self.QLubeOilRecovered,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Lube Heat Recovery Energy",
                state.Constant_Units_J,
                self.LubeOilEnergyRec,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Sum,
                self.Name,
                state.Constant_eResource_EnergyTransfer,
                state.OutputProcessor_Group_Plant,
                state.OutputProcessor_EndUseCat_HeatRecovery
            )

            state.SetupOutputVariable(
                "Generator Produced Thermal Rate",
                state.Constant_Units_W,
                self.QTotalHeatRecovered,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Produced Thermal Energy",
                state.Constant_Units_J,
                self.TotalHeatEnergyRec,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Sum,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Heat Recovery Inlet Temperature",
                state.Constant_Units_C,
                self.HeatRecInletTemp,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Heat Recovery Outlet Temperature",
                state.Constant_Units_C,
                self.HeatRecOutletTemp,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

            state.SetupOutputVariable(
                "Generator Heat Recovery Mass Flow Rate",
                state.Constant_Units_kg_s,
                self.HeatRecMdot,
                state.OutputProcessor_TimeStepType_System,
                state.OutputProcessor_StoreType_Average,
                self.Name
            )

    def calc_ct_generator_model(self, state: Any, run_flag: bool, my_load: float, first_hvac_iteration: bool) -> None:
        exhaust_cp = 1.047
        kj_to_j = 1000.0

        min_part_load_rat = self.MinPartLoadRat
        max_part_load_rat = self.MaxPartLoadRat
        rated_power_output = self.RatedPowerOutput
        max_exhaust_per_ct_power = self.MaxExhaustperCTPower
        design_air_inlet_temp = self.DesignAirInletTemp

        if self.HeatRecActive:
            heat_rec_in_node = self.HeatRecInletNodeNum
            heat_rec_in_temp = state.dataLoopNodes.Node[heat_rec_in_node].Temp
            heat_rec_cp = self.HRPlantLoc.loop.glycol.getSpecificHeat(state, heat_rec_in_temp, "CalcCTGeneratorModel")
            if first_hvac_iteration and run_flag:
                heat_rec_mdot = self.DesignHeatRecMassFlowRate
            else:
                heat_rec_mdot = state.dataLoopNodes.Node[heat_rec_in_node].MassFlowRate
        else:
            heat_rec_in_temp = 0.0
            heat_rec_cp = 0.0
            heat_rec_mdot = 0.0

        if not run_flag:
            self.ElecPowerGenerated = 0.0
            self.ElecEnergyGenerated = 0.0
            self.HeatRecInletTemp = heat_rec_in_temp
            self.HeatRecOutletTemp = heat_rec_in_temp
            self.HeatRecMdot = 0.0
            self.QLubeOilRecovered = 0.0
            self.QExhaustRecovered = 0.0
            self.QTotalHeatRecovered = 0.0
            self.LubeOilEnergyRec = 0.0
            self.ExhaustEnergyRec = 0.0
            self.TotalHeatEnergyRec = 0.0
            self.FuelEnergyUseRate = 0.0
            self.FuelEnergy = 0.0
            self.FuelMdot = 0.0
            self.ExhaustStackTemp = 0.0
            return

        elec_power_generated = min(my_load, rated_power_output)
        elec_power_generated = max(elec_power_generated, 0.0)

        plr = min(elec_power_generated / rated_power_output, max_part_load_rat)
        plr = max(plr, min_part_load_rat)
        elec_power_generated = plr * rated_power_output

        if self.OAInletNode == 0:
            ambient_delta_t = state.dataEnvrn.OutDryBulbTemp - design_air_inlet_temp
        else:
            ambient_delta_t = state.dataLoopNodes.Node[self.OAInletNode].Temp - design_air_inlet_temp

        fuel_use_rate = (elec_power_generated * self.PLBasedFuelInputCurve.value(state, plr) * 
                        self.TempBasedFuelInputCurve.value(state, ambient_delta_t))

        exhaust_flow = rated_power_output * self.ExhaustFlowCurve.value(state, ambient_delta_t)

        if (plr > 0.0) and ((exhaust_flow > 0.0) or (max_exhaust_per_ct_power > 0.0)):
            exhaust_temp = (self.PLBasedExhaustTempCurve.value(state, plr) * 
                           self.TempBasedExhaustTempCurve.value(state, ambient_delta_t))
            ua_loc = self.UACoef[0] * math.pow(rated_power_output, self.UACoef[1])
            design_min_exit_gas_temp = self.DesignMinExitGasTemp
            exhaust_stack_temp = design_min_exit_gas_temp + ((exhaust_temp - design_min_exit_gas_temp) / 
                                  math.exp(ua_loc / (max(exhaust_flow, max_exhaust_per_ct_power * rated_power_output) * exhaust_cp)))
            q_exhaust_rec = max(exhaust_flow * exhaust_cp * (exhaust_temp - exhaust_stack_temp), 0.0)
        else:
            exhaust_stack_temp = self.DesignMinExitGasTemp
            q_exhaust_rec = 0.0

        q_lube_oil_rec = elec_power_generated * self.QLubeOilRecoveredCurve.value(state, plr)

        if (heat_rec_mdot > 0.0) and (heat_rec_cp > 0.0):
            heat_rec_out_temp = (q_exhaust_rec + q_lube_oil_rec) / (heat_rec_mdot * heat_rec_cp) + heat_rec_in_temp
        else:
            heat_rec_mdot = 0.0
            heat_rec_out_temp = heat_rec_in_temp
            q_exhaust_rec = 0.0
            q_lube_oil_rec = 0.0

        min_heat_rec_mdot = 0.0
        if heat_rec_out_temp > self.HeatRecMaxTemp:
            if self.HeatRecMaxTemp != heat_rec_in_temp:
                min_heat_rec_mdot = (q_exhaust_rec + q_lube_oil_rec) / (heat_rec_cp * (self.HeatRecMaxTemp - heat_rec_in_temp))
                if min_heat_rec_mdot < 0.0:
                    min_heat_rec_mdot = 0.0

            if (min_heat_rec_mdot > 0.0) and (heat_rec_cp > 0.0):
                heat_rec_out_temp = (q_exhaust_rec + q_lube_oil_rec) / (min_heat_rec_mdot * heat_rec_cp) + heat_rec_in_temp
                h_rec_ratio = heat_rec_mdot / min_heat_rec_mdot
            else:
                heat_rec_out_temp = heat_rec_in_temp
                h_rec_ratio = 0.0
            q_lube_oil_rec *= h_rec_ratio
            q_exhaust_rec *= h_rec_ratio

        electric_energy_gen = elec_power_generated * state.dataHVACGlobal.TimeStepSysSec
        fuel_energy_used = fuel_use_rate * state.dataHVACGlobal.TimeStepSysSec
        lube_oil_energy_rec = q_lube_oil_rec * state.dataHVACGlobal.TimeStepSysSec
        exhaust_energy_rec = q_exhaust_rec * state.dataHVACGlobal.TimeStepSysSec

        self.ElecPowerGenerated = elec_power_generated
        self.ElecEnergyGenerated = electric_energy_gen
        self.HeatRecInletTemp = heat_rec_in_temp
        self.HeatRecOutletTemp = heat_rec_out_temp
        self.HeatRecMdot = heat_rec_mdot
        self.QExhaustRecovered = q_exhaust_rec
        self.QLubeOilRecovered = q_lube_oil_rec
        self.QTotalHeatRecovered = q_exhaust_rec + q_lube_oil_rec
        self.FuelEnergyUseRate = abs(fuel_use_rate)
        self.ExhaustEnergyRec = exhaust_energy_rec
        self.LubeOilEnergyRec = lube_oil_energy_rec
        self.TotalHeatEnergyRec = exhaust_energy_rec + lube_oil_energy_rec
        self.FuelEnergy = abs(fuel_energy_used)

        fuel_heating_value = self.FuelHeatingValue
        self.FuelMdot = abs(fuel_use_rate) / (fuel_heating_value * kj_to_j)
        self.ExhaustStackTemp = exhaust_stack_temp

        if self.HeatRecActive:
            heat_rec_outlet_node = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[heat_rec_outlet_node].Temp = self.HeatRecOutletTemp

    def init_ct_generators(self, state: Any, run_flag: bool, first_hvac_iteration: bool) -> None:
        self.one_time_init(state)

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and self.HeatRecActive:
            heat_rec_inlet_node = self.HeatRecInletNodeNum
            heat_rec_outlet_node = self.HeatRecOutletNodeNum
            state.dataLoopNodes.Node[heat_rec_inlet_node].Temp = 20.0
            state.dataLoopNodes.Node[heat_rec_outlet_node].Temp = 20.0
            state.PlantUtilities_InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, 
                                                     heat_rec_inlet_node, heat_rec_outlet_node)
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        if self.HeatRecActive:
            if first_hvac_iteration:
                mdot = self.DesignHeatRecMassFlowRate if run_flag else 0.0
                state.PlantUtilities_SetComponentFlowRate(state, mdot, self.HeatRecInletNodeNum, 
                                                          self.HeatRecOutletNodeNum, self.HRPlantLoc)
            else:
                state.PlantUtilities_SetComponentFlowRate(state, self.HeatRecMdot, self.HeatRecInletNodeNum, 
                                                          self.HeatRecOutletNodeNum, self.HRPlantLoc)

    def one_time_init(self, state: Any) -> None:
        if self.MyPlantScanFlag:
            if state.dataPlnt.PlantLoop and self.HeatRecActive:
                err_flag = False
                state.PlantUtilities_ScanPlantLoopsForObject(
                    state, self.Name, state.DataPlant_PlantEquipmentType_Generator_CTurbine, 
                    self.HRPlantLoc, err_flag
                )
                if err_flag:
                    state.ShowFatalError(state, "InitCTGenerators: Program terminated due to previous condition(s).")

            self.MyPlantScanFlag = False

        if self.MyFlag:
            self.setup_output_vars(state)
            self.MyFlag = False

        if self.MySizeAndNodeInitFlag and not self.MyPlantScanFlag and self.HeatRecActive:
            heat_rec_inlet_node = self.HeatRecInletNodeNum
            heat_rec_outlet_node = self.HeatRecOutletNodeNum

            rho = self.HRPlantLoc.loop.glycol.getDensity(state, state.Constant_InitConvTemp, "InitICEngineGenerators")
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate

            state.PlantUtilities_InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, 
                                                     heat_rec_inlet_node, heat_rec_outlet_node)
            self.MySizeAndNodeInitFlag = False

    @staticmethod
    def factory(state: Any, object_name: str) -> 'CTGeneratorData':
        if state.dataCTElectricGenerator.get_ct_input_flag:
            get_ct_generator_input(state)
            state.dataCTElectricGenerator.get_ct_input_flag = False

        for ct_gen in state.dataCTElectricGenerator.ct_generator:
            if ct_gen.Name == object_name:
                return ct_gen

        state.ShowFatalError(state, f"LocalCombustionTurbineGeneratorFactory: Error getting inputs for combustion turbine generator named: {object_name}")
        return None

@dataclass
class CTElectricGeneratorData:
    get_ct_input_flag: bool = True
    ct_generator: List[CTGeneratorData] = field(default_factory=list)

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.get_ct_input_flag = True
        self.ct_generator = []

def get_ct_generator_input(state: Any) -> None:
    errors_found = False

    state.dataIPShortCut.cCurrentModuleObject = "Generator:CombustionTurbine"
    input_processor = state.dataInputProcessing.inputProcessor

    num_ct_generators = input_processor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)

    if num_ct_generators <= 0:
        state.ShowSevereError(state, f"No {state.dataIPShortCut.cCurrentModuleObject} equipment specified in input file")
        errors_found = True

    state.dataCTElectricGenerator.ct_generator = [CTGeneratorData() for _ in range(num_ct_generators)]

    object_schema_props = input_processor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    generator_objects = input_processor.epJSON.get(state.dataIPShortCut.cCurrentModuleObject, {})

    gen_num = 0
    for generator_name, generator_fields in generator_objects.items():
        generator_name_upper = state.Util_makeUPPER(generator_name)
        
        electric_circuit_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "electric_circuit_node_name")
        part_load_based_fuel_input_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "part_load_based_fuel_input_curve_name")
        temperature_based_fuel_input_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "temperature_based_fuel_input_curve_name")
        exhaust_flow_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "exhaust_flow_curve_name")
        part_load_based_exhaust_temperature_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "part_load_based_exhaust_temperature_curve_name")
        temperature_based_exhaust_temperature_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "temperature_based_exhaust_temperature_curve_name")
        heat_recovery_lube_energy_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_lube_energy_curve_name")

        heat_recovery_inlet_node_name = ""
        if "heat_recovery_inlet_node_name" in generator_fields:
            heat_recovery_inlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_inlet_node_name")

        heat_recovery_outlet_node_name = ""
        if "heat_recovery_outlet_node_name" in generator_fields:
            heat_recovery_outlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_outlet_node_name")

        fuel_type = "NaturalGas"
        if "fuel_type" in generator_fields:
            fuel_type = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "fuel_type")

        outdoor_air_inlet_node_name = ""
        if "outdoor_air_inlet_node_name" in generator_fields:
            outdoor_air_inlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "outdoor_air_inlet_node_name")

        input_processor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, generator_name)

        eoh = state.ErrorObjectHeader("GetCTGeneratorInput", state.dataIPShortCut.cCurrentModuleObject, generator_name_upper)

        state.dataCTElectricGenerator.ct_generator[gen_num].Name = generator_name_upper

        state.dataCTElectricGenerator.ct_generator[gen_num].RatedPowerOutput = input_processor.getRealFieldValue(generator_fields, object_schema_props, "rated_power_output")
        if state.dataCTElectricGenerator.ct_generator[gen_num].RatedPowerOutput == 0.0:
            state.ShowSevereError(state, f"Invalid rated_power_output={0.0:.2f}")
            state.ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={generator_name_upper}")
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].ElectricCircuitNode = state.Node_GetOnlySingleNode(
            state, electric_circuit_node_name, errors_found,
            state.Node_ConnectionObjectType_GeneratorCombustionTurbine, generator_name_upper,
            state.Node_FluidType_Electric, state.Node_ConnectionType_Electric,
            state.Node_CompFluidStream_Primary, state.Node_ObjectIsNotParent
        )

        state.dataCTElectricGenerator.ct_generator[gen_num].MinPartLoadRat = input_processor.getRealFieldValue(generator_fields, object_schema_props, "minimum_part_load_ratio")
        state.dataCTElectricGenerator.ct_generator[gen_num].MaxPartLoadRat = input_processor.getRealFieldValue(generator_fields, object_schema_props, "maximum_part_load_ratio")
        state.dataCTElectricGenerator.ct_generator[gen_num].OptPartLoadRat = input_processor.getRealFieldValue(generator_fields, object_schema_props, "optimum_part_load_ratio")

        state.dataCTElectricGenerator.ct_generator[gen_num].PLBasedFuelInputCurve = state.Curve_GetCurve(state, part_load_based_fuel_input_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].PLBasedFuelInputCurve == 0:
            state.ShowSevereItemNotFound(state, eoh, "part_load_based_fuel_input_curve_name", part_load_based_fuel_input_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].TempBasedFuelInputCurve = state.Curve_GetCurve(state, temperature_based_fuel_input_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].TempBasedFuelInputCurve is None:
            state.ShowSevereItemNotFound(state, eoh, "temperature_based_fuel_input_curve_name", temperature_based_fuel_input_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].ExhaustFlowCurve = state.Curve_GetCurve(state, exhaust_flow_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].ExhaustFlowCurve is None:
            state.ShowSevereItemNotFound(state, eoh, "exhaust_flow_curve_name", exhaust_flow_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].PLBasedExhaustTempCurve = state.Curve_GetCurve(state, part_load_based_exhaust_temperature_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].PLBasedExhaustTempCurve is None:
            state.ShowSevereItemNotFound(state, eoh, "part_load_based_exhaust_temperature_curve_name", part_load_based_exhaust_temperature_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].TempBasedExhaustTempCurve = state.Curve_GetCurve(state, temperature_based_exhaust_temperature_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].TempBasedExhaustTempCurve is None:
            state.ShowSevereItemNotFound(state, eoh, "temperature_based_exhaust_temperature_curve_name", temperature_based_exhaust_temperature_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].QLubeOilRecoveredCurve = state.Curve_GetCurve(state, heat_recovery_lube_energy_curve_name)
        if state.dataCTElectricGenerator.ct_generator[gen_num].QLubeOilRecoveredCurve is None:
            state.ShowSevereItemNotFound(state, eoh, "heat_recovery_lube_energy_curve_name", heat_recovery_lube_energy_curve_name)
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].UACoef[0] = input_processor.getRealFieldValue(generator_fields, object_schema_props, "coefficient_1_of_u_factor_times_area_curve")
        state.dataCTElectricGenerator.ct_generator[gen_num].UACoef[1] = input_processor.getRealFieldValue(generator_fields, object_schema_props, "coefficient_2_of_u_factor_times_area_curve")

        state.dataCTElectricGenerator.ct_generator[gen_num].MaxExhaustperCTPower = input_processor.getRealFieldValue(generator_fields, object_schema_props, "maximum_exhaust_flow_per_unit_of_power_output")
        state.dataCTElectricGenerator.ct_generator[gen_num].DesignMinExitGasTemp = input_processor.getRealFieldValue(generator_fields, object_schema_props, "design_minimum_exhaust_temperature")
        state.dataCTElectricGenerator.ct_generator[gen_num].DesignAirInletTemp = input_processor.getRealFieldValue(generator_fields, object_schema_props, "design_air_inlet_temperature")
        state.dataCTElectricGenerator.ct_generator[gen_num].FuelHeatingValue = input_processor.getRealFieldValue(generator_fields, object_schema_props, "fuel_higher_heating_value")
        state.dataCTElectricGenerator.ct_generator[gen_num].DesignHeatRecVolFlowRate = input_processor.getRealFieldValue(generator_fields, object_schema_props, "design_heat_recovery_water_flow_rate")

        if state.dataCTElectricGenerator.ct_generator[gen_num].DesignHeatRecVolFlowRate > 0.0:
            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecActive = True
            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecInletNodeNum = state.Node_GetOnlySingleNode(
                state, heat_recovery_inlet_node_name, errors_found,
                state.Node_ConnectionObjectType_GeneratorCombustionTurbine, generator_name_upper,
                state.Node_FluidType_Water, state.Node_ConnectionType_Inlet,
                state.Node_CompFluidStream_Primary, state.Node_ObjectIsNotParent
            )
            if state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecInletNodeNum == 0:
                state.ShowSevereError(state, f"Missing Node Name, Heat Recovery Inlet, for {state.dataIPShortCut.cCurrentModuleObject}={generator_name_upper}")
                errors_found = True

            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecOutletNodeNum = state.Node_GetOnlySingleNode(
                state, heat_recovery_outlet_node_name, errors_found,
                state.Node_ConnectionObjectType_GeneratorCombustionTurbine, generator_name_upper,
                state.Node_FluidType_Water, state.Node_ConnectionType_Outlet,
                state.Node_CompFluidStream_Primary, state.Node_ObjectIsNotParent
            )
            if state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecOutletNodeNum == 0:
                state.ShowSevereError(state, f"Missing Node Name, Heat Recovery Outlet, for {state.dataIPShortCut.cCurrentModuleObject}={generator_name_upper}")
                errors_found = True

            state.Node_TestCompSet(
                state, state.dataIPShortCut.cCurrentModuleObject, generator_name_upper,
                heat_recovery_inlet_node_name, heat_recovery_outlet_node_name, "Heat Recovery Nodes"
            )
            state.PlantUtilities_RegisterPlantCompDesignFlow(
                state, state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecInletNodeNum,
                state.dataCTElectricGenerator.ct_generator[gen_num].DesignHeatRecVolFlowRate
            )
        else:
            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecActive = False
            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecInletNodeNum = 0
            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecOutletNodeNum = 0
            if heat_recovery_inlet_node_name or heat_recovery_outlet_node_name:
                state.ShowWarningError(state, f"Since Design Heat Flow Rate = 0.0, Heat Recovery inactive for {state.dataIPShortCut.cCurrentModuleObject}={generator_name_upper}")
                state.ShowContinueError(state, "However, Node names were specified for Heat Recovery inlet or outlet nodes")

        state.dataCTElectricGenerator.ct_generator[gen_num].FuelType = state.getEnumValue(state.Constant_eFuelNamesUC, fuel_type)
        if state.dataCTElectricGenerator.ct_generator[gen_num].FuelType == state.Constant_eFuel_Invalid:
            state.ShowSevereError(state, f"Invalid fuel_type={fuel_type}")
            state.ShowContinueError(state, f"Entered in {state.dataIPShortCut.cCurrentModuleObject}={generator_name_upper}")
            errors_found = True

        state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecMaxTemp = input_processor.getRealFieldValue(generator_fields, object_schema_props, "heat_recovery_maximum_temperature")

        if not outdoor_air_inlet_node_name:
            state.dataCTElectricGenerator.ct_generator[gen_num].OAInletNode = 0
        else:
            state.dataCTElectricGenerator.ct_generator[gen_num].OAInletNode = state.Node_GetOnlySingleNode(
                state, outdoor_air_inlet_node_name, errors_found,
                state.Node_ConnectionObjectType_GeneratorCombustionTurbine, generator_name_upper,
                state.Node_FluidType_Air, state.Node_ConnectionType_OutsideAirReference,
                state.Node_CompFluidStream_Primary, state.Node_ObjectIsNotParent
            )
            if not state.OutAirNodeManager_CheckOutAirNodeNumber(state, state.dataCTElectricGenerator.ct_generator[gen_num].OAInletNode):
                state.ShowSevereError(state, f"{state.dataIPShortCut.cCurrentModuleObject}, \"{state.dataCTElectricGenerator.ct_generator[gen_num].Name}\" Outdoor Air Inlet Node Name not valid Outdoor Air Node= {outdoor_air_inlet_node_name}")
                state.ShowContinueError(state, "...does not appear in an OutdoorAir:NodeList or as an OutdoorAir:Node.")
                errors_found = True

        gen_num += 1

    if errors_found:
        state.ShowFatalError(state, f"Errors found in processing input for {state.dataIPShortCut.cCurrentModuleObject}")
