from collections import InlineArray
from math import pow, exp
from collections import Dict, List

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: main state struct with nested data members
# - PlantComponent: base trait for plant components
# - Curve: struct with value(state: EnergyPlusData, x: Float64) -> Float64 method
# - PlantLocation: struct with loop reference containing glycol
# - Constant.eFuel: fuel type enum values
# - Constant.eFuelNames: list of fuel type names
# - Constant.eFuelNamesUC: list of fuel type names in uppercase
# - Constant.eFuel2eResource: mapping array from fuel types to resource types
# - Constant.Units: output variable units
# - Constant.eResource: resource type enum
# - Constant.InitConvTemp: float constant for initialization temperature
# - Node utilities: GetOnlySingleNode, TestCompSet, various enums for connection types
# - Curve.GetCurve(state: EnergyPlusData, name: String) -> Curve
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, RegisterPlantDesignFlow, ScanPlantLoopsForObject
# - OutputProcessor: SetupOutputVariable and related types
# - UtilityRoutines: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowWarningError, ShowContinueError
# - DataEnvironment: OutDryBulbTemp, BeginEnvrnFlag
# - DataLoopNode: Node structs with Temp, MassFlowRate fields
# - DataHVACGlobals: TimeStepSysSec
# - DataPlant: PlantEquipmentType enum
# - OutAirNodeManager: CheckOutAirNodeNumber
# - Util.makeUPPER(s: String) -> String
# - InputProcessor: getNumObjectsFound, getObjectSchemaProps, epJSON, getAlphaFieldValue, getRealFieldValue, markObjectAsUsed
# - ErrorObjectHeader: error context struct
# - getEnumValue: utility function for enum lookup

struct GeneratorType:
    var CombTurbine: Int32 = 0

struct CTGeneratorData:
    var Name: String
    var TypeOf: String
    var CompType_Num: Int32
    var FuelType: Int32
    var RatedPowerOutput: Float64
    var ElectricCircuitNode: Int32
    var MinPartLoadRat: Float64
    var MaxPartLoadRat: Float64
    var OptPartLoadRat: Float64
    var FuelEnergyUseRate: Float64
    var FuelEnergy: Float64
    var PLBasedFuelInputCurve: Curve
    var TempBasedFuelInputCurve: Curve
    var ExhaustFlow: Float64
    var ExhaustFlowCurve: Curve
    var ExhaustTemp: Float64
    var PLBasedExhaustTempCurve: Curve
    var TempBasedExhaustTempCurve: Curve
    var QLubeOilRecovered: Float64
    var QExhaustRecovered: Float64
    var QTotalHeatRecovered: Float64
    var LubeOilEnergyRec: Float64
    var ExhaustEnergyRec: Float64
    var TotalHeatEnergyRec: Float64
    var QLubeOilRecoveredCurve: Curve
    var UA: Float64
    var UACoef: InlineArray[Float64, 2]
    var MaxExhaustperCTPower: Float64
    var DesignHeatRecVolFlowRate: Float64
    var DesignHeatRecMassFlowRate: Float64
    var DesignMinExitGasTemp: Float64
    var DesignAirInletTemp: Float64
    var ExhaustStackTemp: Float64
    var HeatRecActive: Bool
    var HeatRecInletNodeNum: Int32
    var HeatRecOutletNodeNum: Int32
    var HeatRecInletTemp: Float64
    var HeatRecOutletTemp: Float64
    var HeatRecMdot: Float64
    var HRPlantLoc: PlantLocation
    var FuelMdot: Float64
    var FuelHeatingValue: Float64
    var ElecPowerGenerated: Float64
    var ElecEnergyGenerated: Float64
    var HeatRecMaxTemp: Float64
    var OAInletNode: Int32
    var MyEnvrnFlag: Bool
    var MyPlantScanFlag: Bool
    var MySizeAndNodeInitFlag: Bool
    var CheckEquipName: Bool
    var MyFlag: Bool

    fn __init__(inout self):
        self.Name = ""
        self.TypeOf = "Generator:CombustionTurbine"
        self.CompType_Num = GeneratorType.CombTurbine
        self.FuelType = -1
        self.RatedPowerOutput = 0.0
        self.ElectricCircuitNode = 0
        self.MinPartLoadRat = 0.0
        self.MaxPartLoadRat = 0.0
        self.OptPartLoadRat = 0.0
        self.FuelEnergyUseRate = 0.0
        self.FuelEnergy = 0.0
        self.ExhaustFlow = 0.0
        self.ExhaustTemp = 0.0
        self.QLubeOilRecovered = 0.0
        self.QExhaustRecovered = 0.0
        self.QTotalHeatRecovered = 0.0
        self.LubeOilEnergyRec = 0.0
        self.ExhaustEnergyRec = 0.0
        self.TotalHeatEnergyRec = 0.0
        self.UA = 0.0
        self.UACoef = InlineArray[Float64, 2](fill=0.0)
        self.MaxExhaustperCTPower = 0.0
        self.DesignHeatRecVolFlowRate = 0.0
        self.DesignHeatRecMassFlowRate = 0.0
        self.DesignMinExitGasTemp = 0.0
        self.DesignAirInletTemp = 0.0
        self.ExhaustStackTemp = 0.0
        self.HeatRecActive = False
        self.HeatRecInletNodeNum = 0
        self.HeatRecOutletNodeNum = 0
        self.HeatRecInletTemp = 0.0
        self.HeatRecOutletTemp = 0.0
        self.HeatRecMdot = 0.0
        self.FuelMdot = 0.0
        self.FuelHeatingValue = 0.0
        self.ElecPowerGenerated = 0.0
        self.ElecEnergyGenerated = 0.0
        self.HeatRecMaxTemp = 0.0
        self.OAInletNode = 0
        self.MyEnvrnFlag = True
        self.MyPlantScanFlag = True
        self.MySizeAndNodeInitFlag = True
        self.CheckEquipName = True
        self.MyFlag = True

    fn simulate(inout self, state: EnergyPlusData, called_from_location: PlantLocation, 
                first_hvac_iteration: Bool, cur_load: Float64, run_flag: Bool) -> None:
        pass

    fn setup_output_vars(inout self, state: EnergyPlusData) -> None:
        var s_fuel_type = state.Constant_eFuelNames[Int(self.FuelType)]
        
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

        var fuel_type_str = s_fuel_type
        state.SetupOutputVariable(
            "Generator " + fuel_type_str + " Rate",
            state.Constant_Units_W,
            self.FuelEnergyUseRate,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Average,
            self.Name
        )

        state.SetupOutputVariable(
            "Generator " + fuel_type_str + " Energy",
            state.Constant_Units_J,
            self.FuelEnergy,
            state.OutputProcessor_TimeStepType_System,
            state.OutputProcessor_StoreType_Sum,
            self.Name,
            state.Constant_eFuel2eResource[Int(self.FuelType)],
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
            "Generator " + fuel_type_str + " Mass Flow Rate",
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

    fn calc_ct_generator_model(inout self, state: EnergyPlusData, run_flag: Bool, my_load: Float64, 
                               first_hvac_iteration: Bool) -> None:
        let exhaust_cp: Float64 = 1.047
        let kj_to_j: Float64 = 1000.0

        var min_part_load_rat = self.MinPartLoadRat
        var max_part_load_rat = self.MaxPartLoadRat
        var rated_power_output = self.RatedPowerOutput
        var max_exhaust_per_ct_power = self.MaxExhaustperCTPower
        var design_air_inlet_temp = self.DesignAirInletTemp

        var heat_rec_in_temp: Float64
        var heat_rec_cp: Float64
        var heat_rec_mdot: Float64

        if self.HeatRecActive:
            var heat_rec_in_node = self.HeatRecInletNodeNum
            heat_rec_in_temp = state.dataLoopNodes[heat_rec_in_node].Temp
            heat_rec_cp = self.HRPlantLoc.loop.glycol.getSpecificHeat(state, heat_rec_in_temp, "CalcCTGeneratorModel")
            if first_hvac_iteration and run_flag:
                heat_rec_mdot = self.DesignHeatRecMassFlowRate
            else:
                heat_rec_mdot = state.dataLoopNodes[heat_rec_in_node].MassFlowRate
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

        var elec_power_generated = min(my_load, rated_power_output)
        elec_power_generated = max(elec_power_generated, 0.0)

        var plr = min(elec_power_generated / rated_power_output, max_part_load_rat)
        plr = max(plr, min_part_load_rat)
        elec_power_generated = plr * rated_power_output

        var ambient_delta_t: Float64
        if self.OAInletNode == 0:
            ambient_delta_t = state.dataEnvrn.OutDryBulbTemp - design_air_inlet_temp
        else:
            ambient_delta_t = state.dataLoopNodes[self.OAInletNode].Temp - design_air_inlet_temp

        var fuel_use_rate = (elec_power_generated * self.PLBasedFuelInputCurve.value(state, plr) * 
                             self.TempBasedFuelInputCurve.value(state, ambient_delta_t))

        var exhaust_flow = rated_power_output * self.ExhaustFlowCurve.value(state, ambient_delta_t)

        var q_exhaust_rec: Float64
        var exhaust_stack_temp: Float64

        if (plr > 0.0) and ((exhaust_flow > 0.0) or (max_exhaust_per_ct_power > 0.0)):
            var exhaust_temp = (self.PLBasedExhaustTempCurve.value(state, plr) * 
                               self.TempBasedExhaustTempCurve.value(state, ambient_delta_t))
            var ua_loc = self.UACoef[0] * pow(rated_power_output, self.UACoef[1])
            var design_min_exit_gas_temp = self.DesignMinExitGasTemp
            exhaust_stack_temp = design_min_exit_gas_temp + ((exhaust_temp - design_min_exit_gas_temp) / 
                                 exp(ua_loc / (max(exhaust_flow, max_exhaust_per_ct_power * rated_power_output) * exhaust_cp)))
            q_exhaust_rec = max(exhaust_flow * exhaust_cp * (exhaust_temp - exhaust_stack_temp), 0.0)
        else:
            exhaust_stack_temp = self.DesignMinExitGasTemp
            q_exhaust_rec = 0.0

        var q_lube_oil_rec = elec_power_generated * self.QLubeOilRecoveredCurve.value(state, plr)

        var heat_rec_out_temp: Float64
        if (heat_rec_mdot > 0.0) and (heat_rec_cp > 0.0):
            heat_rec_out_temp = (q_exhaust_rec + q_lube_oil_rec) / (heat_rec_mdot * heat_rec_cp) + heat_rec_in_temp
        else:
            heat_rec_mdot = 0.0
            heat_rec_out_temp = heat_rec_in_temp
            q_exhaust_rec = 0.0
            q_lube_oil_rec = 0.0

        var min_heat_rec_mdot: Float64 = 0.0

        if heat_rec_out_temp > self.HeatRecMaxTemp:
            if self.HeatRecMaxTemp != heat_rec_in_temp:
                min_heat_rec_mdot = (q_exhaust_rec + q_lube_oil_rec) / (heat_rec_cp * (self.HeatRecMaxTemp - heat_rec_in_temp))
                if min_heat_rec_mdot < 0.0:
                    min_heat_rec_mdot = 0.0

            var h_rec_ratio: Float64
            if (min_heat_rec_mdot > 0.0) and (heat_rec_cp > 0.0):
                heat_rec_out_temp = (q_exhaust_rec + q_lube_oil_rec) / (min_heat_rec_mdot * heat_rec_cp) + heat_rec_in_temp
                h_rec_ratio = heat_rec_mdot / min_heat_rec_mdot
            else:
                heat_rec_out_temp = heat_rec_in_temp
                h_rec_ratio = 0.0
            q_lube_oil_rec *= h_rec_ratio
            q_exhaust_rec *= h_rec_ratio

        var electric_energy_gen = elec_power_generated * state.dataHVACGlobal.TimeStepSysSec
        var fuel_energy_used = fuel_use_rate * state.dataHVACGlobal.TimeStepSysSec
        var lube_oil_energy_rec = q_lube_oil_rec * state.dataHVACGlobal.TimeStepSysSec
        var exhaust_energy_rec = q_exhaust_rec * state.dataHVACGlobal.TimeStepSysSec

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

        var fuel_heating_value = self.FuelHeatingValue
        self.FuelMdot = abs(fuel_use_rate) / (fuel_heating_value * kj_to_j)
        self.ExhaustStackTemp = exhaust_stack_temp

        if self.HeatRecActive:
            var heat_rec_outlet_node = self.HeatRecOutletNodeNum
            state.dataLoopNodes[heat_rec_outlet_node].Temp = self.HeatRecOutletTemp

    fn init_ct_generators(inout self, state: EnergyPlusData, run_flag: Bool, first_hvac_iteration: Bool) -> None:
        self.one_time_init(state)

        if state.dataGlobal.BeginEnvrnFlag and self.MyEnvrnFlag and self.HeatRecActive:
            var heat_rec_inlet_node = self.HeatRecInletNodeNum
            var heat_rec_outlet_node = self.HeatRecOutletNodeNum
            state.dataLoopNodes[heat_rec_inlet_node].Temp = 20.0
            state.dataLoopNodes[heat_rec_outlet_node].Temp = 20.0
            state.PlantUtilities_InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, 
                                                     heat_rec_inlet_node, heat_rec_outlet_node)
            self.MyEnvrnFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.MyEnvrnFlag = True

        if self.HeatRecActive:
            if first_hvac_iteration:
                var mdot = self.DesignHeatRecMassFlowRate if run_flag else 0.0
                state.PlantUtilities_SetComponentFlowRate(state, mdot, self.HeatRecInletNodeNum, 
                                                          self.HeatRecOutletNodeNum, self.HRPlantLoc)
            else:
                state.PlantUtilities_SetComponentFlowRate(state, self.HeatRecMdot, self.HeatRecInletNodeNum, 
                                                          self.HeatRecOutletNodeNum, self.HRPlantLoc)

    fn one_time_init(inout self, state: EnergyPlusData) -> None:
        if self.MyPlantScanFlag:
            if state.dataPlnt.PlantLoop and self.HeatRecActive:
                var err_flag = False
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
            var heat_rec_inlet_node = self.HeatRecInletNodeNum
            var heat_rec_outlet_node = self.HeatRecOutletNodeNum

            var rho = self.HRPlantLoc.loop.glycol.getDensity(state, state.Constant_InitConvTemp, "InitICEngineGenerators")
            self.DesignHeatRecMassFlowRate = rho * self.DesignHeatRecVolFlowRate

            state.PlantUtilities_InitComponentNodes(state, 0.0, self.DesignHeatRecMassFlowRate, 
                                                     heat_rec_inlet_node, heat_rec_outlet_node)
            self.MySizeAndNodeInitFlag = False

    @staticmethod
    fn factory(state: EnergyPlusData, object_name: String) -> CTGeneratorData:
        if state.dataCTElectricGenerator.get_ct_input_flag:
            get_ct_generator_input(state)
            state.dataCTElectricGenerator.get_ct_input_flag = False

        for ct_gen in state.dataCTElectricGenerator.ct_generator:
            if ct_gen.Name == object_name:
                return ct_gen

        state.ShowFatalError(state, "LocalCombustionTurbineGeneratorFactory: Error getting inputs for combustion turbine generator named: " + object_name)
        var dummy: CTGeneratorData
        return dummy

struct CTElectricGeneratorData:
    var get_ct_input_flag: Bool
    var ct_generator: List[CTGeneratorData]

    fn __init__(inout self):
        self.get_ct_input_flag = True
        self.ct_generator = List[CTGeneratorData]()

    fn init_constant_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn init_state(inout self, state: EnergyPlusData) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.get_ct_input_flag = True
        self.ct_generator = List[CTGeneratorData]()

fn get_ct_generator_input(inout state: EnergyPlusData) -> None:
    var errors_found = False

    state.dataIPShortCut.cCurrentModuleObject = "Generator:CombustionTurbine"
    var input_processor = state.dataInputProcessing.inputProcessor

    var num_ct_generators = input_processor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)

    if num_ct_generators <= 0:
        state.ShowSevereError(state, "No " + state.dataIPShortCut.cCurrentModuleObject + " equipment specified in input file")
        errors_found = True

    for _ in range(num_ct_generators):
        var gen: CTGeneratorData
        state.dataCTElectricGenerator.ct_generator.append(gen)

    var object_schema_props = input_processor.getObjectSchemaProps(state, state.dataIPShortCut.cCurrentModuleObject)
    var generator_objects = input_processor.epJSON.get(state.dataIPShortCut.cCurrentModuleObject, Dict[String, Any]())

    var gen_num = 0
    for generator_name in generator_objects:
        var generator_fields = generator_objects[generator_name]
        var generator_name_upper = state.Util_makeUPPER(generator_name)
        
        var electric_circuit_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "electric_circuit_node_name")
        var part_load_based_fuel_input_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "part_load_based_fuel_input_curve_name")
        var temperature_based_fuel_input_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "temperature_based_fuel_input_curve_name")
        var exhaust_flow_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "exhaust_flow_curve_name")
        var part_load_based_exhaust_temperature_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "part_load_based_exhaust_temperature_curve_name")
        var temperature_based_exhaust_temperature_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "temperature_based_exhaust_temperature_curve_name")
        var heat_recovery_lube_energy_curve_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_lube_energy_curve_name")

        var heat_recovery_inlet_node_name = ""
        if generator_fields.contains("heat_recovery_inlet_node_name"):
            heat_recovery_inlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_inlet_node_name")

        var heat_recovery_outlet_node_name = ""
        if generator_fields.contains("heat_recovery_outlet_node_name"):
            heat_recovery_outlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "heat_recovery_outlet_node_name")

        var fuel_type = "NaturalGas"
        if generator_fields.contains("fuel_type"):
            fuel_type = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "fuel_type")

        var outdoor_air_inlet_node_name = ""
        if generator_fields.contains("outdoor_air_inlet_node_name"):
            outdoor_air_inlet_node_name = input_processor.getAlphaFieldValue(generator_fields, object_schema_props, "outdoor_air_inlet_node_name")

        input_processor.markObjectAsUsed(state.dataIPShortCut.cCurrentModuleObject, generator_name)

        var eoh = state.ErrorObjectHeader("GetCTGeneratorInput", state.dataIPShortCut.cCurrentModuleObject, generator_name_upper)

        state.dataCTElectricGenerator.ct_generator[gen_num].Name = generator_name_upper

        state.dataCTElectricGenerator.ct_generator[gen_num].RatedPowerOutput = input_processor.getRealFieldValue(generator_fields, object_schema_props, "rated_power_output")
        if state.dataCTElectricGenerator.ct_generator[gen_num].RatedPowerOutput == 0.0:
            state.ShowSevereError(state, "Invalid rated_power_output=0.00")
            state.ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + generator_name_upper)
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
                state.ShowSevereError(state, "Missing Node Name, Heat Recovery Inlet, for " + state.dataIPShortCut.cCurrentModuleObject + "=" + generator_name_upper)
                errors_found = True

            state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecOutletNodeNum = state.Node_GetOnlySingleNode(
                state, heat_recovery_outlet_node_name, errors_found,
                state.Node_ConnectionObjectType_GeneratorCombustionTurbine, generator_name_upper,
                state.Node_FluidType_Water, state.Node_ConnectionType_Outlet,
                state.Node_CompFluidStream_Primary, state.Node_ObjectIsNotParent
            )
            if state.dataCTElectricGenerator.ct_generator[gen_num].HeatRecOutletNodeNum == 0:
                state.ShowSevereError(state, "Missing Node Name, Heat Recovery Outlet, for " + state.dataIPShortCut.cCurrentModuleObject + "=" + generator_name_upper)
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
                state.ShowWarningError(state, "Since Design Heat Flow Rate = 0.0, Heat Recovery inactive for " + state.dataIPShortCut.cCurrentModuleObject + "=" + generator_name_upper)
                state.ShowContinueError(state, "However, Node names were specified for Heat Recovery inlet or outlet nodes")

        state.dataCTElectricGenerator.ct_generator[gen_num].FuelType = state.getEnumValue(state.Constant_eFuelNamesUC, fuel_type)
        if state.dataCTElectricGenerator.ct_generator[gen_num].FuelType == state.Constant_eFuel_Invalid:
            state.ShowSevereError(state, "Invalid fuel_type=" + fuel_type)
            state.ShowContinueError(state, "Entered in " + state.dataIPShortCut.cCurrentModuleObject + "=" + generator_name_upper)
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
                state.ShowSevereError(state, state.dataIPShortCut.cCurrentModuleObject + ", \"" + state.dataCTElectricGenerator.ct_generator[gen_num].Name + "\" Outdoor Air Inlet Node Name not valid Outdoor Air Node= " + outdoor_air_inlet_node_name)
                state.ShowContinueError(state, "...does not appear in an OutdoorAir:NodeList or as an OutdoorAir:Node.")
                errors_found = True

        gen_num += 1

    if errors_found:
        state.ShowFatalError(state, "Errors found in processing input for " + state.dataIPShortCut.cCurrentModuleObject)
