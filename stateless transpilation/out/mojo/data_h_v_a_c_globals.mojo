# data_h_v_a_c_globals.mojo
# EXTERNAL DEPS (to wire in glue):
# BaseGlobalStruct - from EnergyPlus/Data/BaseData (base class)
# EnergyPlusData - from EnergyPlus/EnergyPlus (state object)

alias CtrlVarType_Invalid = -1
alias CtrlVarType_Temp = 0
alias CtrlVarType_MaxTemp = 1
alias CtrlVarType_MinTemp = 2
alias CtrlVarType_HumRat = 3
alias CtrlVarType_MaxHumRat = 4
alias CtrlVarType_MinHumRat = 5
alias CtrlVarType_MassFlowRate = 6
alias CtrlVarType_MaxMassFlowRate = 7
alias CtrlVarType_MinMassFlowRate = 8
alias CtrlVarType_Num = 9

alias SmallHumRatDiff = 1.0e-7
alias SmallTempDiff = 1.0e-5
alias SmallMassFlow = 0.001
alias VerySmallMassFlow = 1.0e-30
alias SmallLoad = 1.0
alias TempControlTol = 0.1
alias SmallAirVolFlow = 0.001
alias SmallWaterVolFlow = 1.0e-9
alias BlankNumeric = -99999.0
alias RetTempMax = 60.0
alias RetTempMin = -30.0
alias DesCoilHWInletTempMin = 46.0

alias NumOfSizingTypes = 35

alias CoolingAirflowSizing = 1
alias CoolingWaterDesWaterInletTempSizing = 6
alias HeatingAirflowSizing = 14
alias SystemAirflowSizing = 16
alias CoolingCapacitySizing = 17
alias HeatingCapacitySizing = 18
alias SystemCapacitySizing = 21
alias AutoCalculateSizing = 25

alias SetptType_Invalid = -1
alias SetptType_Uncontrolled = 0
alias SetptType_SingleHeat = 1
alias SetptType_SingleCool = 2
alias SetptType_SingleHeatCool = 3
alias SetptType_DualHeatCool = 4
alias SetptType_Num = 5

alias AirDuctType_Invalid = -1
alias AirDuctType_Main = 0
alias AirDuctType_Cooling = 1
alias AirDuctType_Heating = 2
alias AirDuctType_Other = 3
alias AirDuctType_RAB = 4
alias AirDuctType_Num = 5

alias Cooling = 2
alias Heating = 3

alias FanType_Invalid = -1
alias FanType_Constant = 0
alias FanType_VAV = 1
alias FanType_OnOff = 2
alias FanType_Exhaust = 3
alias FanType_ComponentModel = 4
alias FanType_SystemModel = 5
alias FanType_Num = 6

alias FanOp_Invalid = -1
alias FanOp_Cycling = 0
alias FanOp_Continuous = 1
alias FanOp_Num = 2

alias FanPlace_Invalid = -1
alias FanPlace_BlowThru = 0
alias FanPlace_DrawThru = 1
alias FanPlace_Num = 2

alias BypassWhenWithinEconomizerLimits = 0
alias BypassWhenOAFlowGreaterThanMinimum = 1

alias EconomizerStagingType_Invalid = -1
alias EconomizerStagingType_EconomizerFirst = 0
alias EconomizerStagingType_InterlockedWithMechanicalCooling = 1
alias EconomizerStagingType_Num = 2

alias UnitarySysType_Invalid = -1
alias UnitarySysType_Furnace_HeatOnly = 0
alias UnitarySysType_Furnace_HeatCool = 1
alias UnitarySysType_Unitary_HeatOnly = 2
alias UnitarySysType_Unitary_HeatCool = 3
alias UnitarySysType_Unitary_HeatPump_AirToAir = 4
alias UnitarySysType_Unitary_HeatPump_WaterToAir = 5
alias UnitarySysType_Unitary_AnyCoilType = 6
alias UnitarySysType_Num = 7

alias CoilType_Invalid = -1
alias CoilType_CoolingDXSingleSpeed = 0
alias CoilType_HeatingDXSingleSpeed = 1
alias CoilType_CoolingDXTwoSpeed = 2
alias CoilType_CoolingDXHXAssisted = 3
alias CoilType_CoolingDXTwoStageWHumControl = 4
alias CoilType_WaterHeatingDXPumped = 5
alias CoilType_WaterHeatingDXWrapped = 6
alias CoilType_CoolingDXMultiSpeed = 7
alias CoilType_HeatingDXMultiSpeed = 8
alias CoilType_HeatingGasOrOtherFuel = 9
alias CoilType_HeatingGasMultiStage = 10
alias CoilType_HeatingElectric = 11
alias CoilType_HeatingElectricMultiStage = 12
alias CoilType_HeatingDesuperheater = 13
alias CoilType_CoolingWater = 14
alias CoilType_CoolingWaterDetailed = 15
alias CoilType_HeatingWater = 16
alias CoilType_HeatingSteam = 17
alias CoilType_CoolingWaterHXAssisted = 18
alias CoilType_CoolingWAHP = 19
alias CoilType_HeatingWAHP = 20
alias CoilType_CoolingWAHPSimple = 21
alias CoilType_HeatingWAHPSimple = 22
alias CoilType_CoolingVRF = 23
alias CoilType_HeatingVRF = 24
alias CoilType_UserDefined = 25
alias CoilType_CoolingDXPackagedThermalStorage = 26
alias CoilType_CoolingWAHPVariableSpeedEquationFit = 27
alias CoilType_HeatingWAHPVariableSpeedEquationFit = 28
alias CoilType_CoolingDXVariableSpeed = 29
alias CoilType_HeatingDXVariableSpeed = 30
alias CoilType_WaterHeatingAWHPVariableSpeed = 31
alias CoilType_CoolingVRFFluidTCtrl = 32
alias CoilType_HeatingVRFFluidTCtrl = 33
alias CoilType_CoolingDX = 34
alias CoilType_DXSubcoolReheat = 35
alias CoilType_CoolingDXCurveFit = 36
alias CoilType_Num = 37

alias CoilMode_Invalid = -1
alias CoilMode_Normal = 0
alias CoilMode_Enhanced = 1
alias CoilMode_SubcoolReheat = 2
alias CoilMode_Num = 3

alias HeatReclaimType_Invalid = -1
alias HeatReclaimType_RefrigeratedCaseCompressorRack = 0
alias HeatReclaimType_RefrigeratedCaseCondenserAirCooled = 1
alias HeatReclaimType_RefrigeratedCaseCondenserEvaporativeCooled = 2
alias HeatReclaimType_RefrigeratedCaseCondenserWaterCooled = 3
alias HeatReclaimType_CoilCoolDXSingleSpeed = 4
alias HeatReclaimType_CoilCoolDXTwoSpeed = 5
alias HeatReclaimType_CoilCoolDXMultiSpeed = 6
alias HeatReclaimType_CoilCoolDXMultiMode = 7
alias HeatReclaimType_CoilCoolDXVariableSpeed = 8
alias HeatReclaimType_CoilCoolDX = 9
alias HeatReclaimType_CoilCoolWAHPEquationFit = 10
alias HeatReclaimType_CoilCoolWAHPVariableSpeedEquationFit = 11
alias HeatReclaimType_Num = 12

alias WaterFlow_Invalid = -1
alias WaterFlow_Cycling = 0
alias WaterFlow_Constant = 1
alias WaterFlow_ConstantOnDemand = 2
alias WaterFlow_Num = 3

alias CoilPerfDX_CoolBypassEmpirical = 100

alias MaxRatedVolFlowPerRatedTotCap1 = 0.00006041
alias MinRatedVolFlowPerRatedTotCap1 = 0.00004027
alias MaxHeatVolFlowPerRatedTotCap1 = 0.00008056
alias MaxCoolVolFlowPerRatedTotCap1 = 0.00006713
alias MinOperVolFlowPerRatedTotCap1 = 0.00002684

alias MaxRatedVolFlowPerRatedTotCap2 = 0.00003355
alias MinRatedVolFlowPerRatedTotCap2 = 0.00001677
alias MaxHeatVolFlowPerRatedTotCap2 = 0.00004026
alias MaxCoolVolFlowPerRatedTotCap2 = 0.00004026
alias MinOperVolFlowPerRatedTotCap2 = 0.00001342

alias DXCoilType_Invalid = -1
alias DXCoilType_Regular = 0
alias DXCoilType_DOAS = 1
alias DXCoilType_Num = 2

alias HXType_Invalid = -1
alias HXType_AirToAir_FlatPlate = 0
alias HXType_AirToAir_SensAndLatent = 1
alias HXType_Desiccant_Balanced = 2
alias HXType_Num = 3

alias MixerType_Invalid = -1
alias MixerType_InletSide = 0
alias MixerType_SupplySide = 1
alias MixerType_Num = 2

alias OATType_Invalid = -1
alias OATType_WetBulb = 0
alias OATType_DryBulb = 1
alias OATType_Num = 2

alias OscillateMagnitude = 0.15

alias MaxSpeedLevels = 10

struct ComponentSetPtData:
    var equipment_type: String
    var equipment_name: String
    var node_num_in: Int
    var node_num_out: Int
    var equip_demand: Float64
    var design_flow_rate: Float64
    var heat_or_cool: String
    var op_type: Int

    fn __init__(inout self):
        self.equipment_type = ""
        self.equipment_name = ""
        self.node_num_in = 0
        self.node_num_out = 0
        self.equip_demand = 0.0
        self.design_flow_rate = 0.0
        self.heat_or_cool = ""
        self.op_type = 0

alias CompressorOp_Invalid = -1
alias CompressorOp_Off = 0
alias CompressorOp_On = 1
alias CompressorOp_Num = 2

alias fanTypeNames_0 = "Fan:ConstantVolume"
alias fanTypeNames_1 = "Fan:VariableVolume"
alias fanTypeNames_2 = "Fan:OnOff"
alias fanTypeNames_3 = "Fan:ZoneExhaust"
alias fanTypeNames_4 = "Fan:ComponentModel"
alias fanTypeNames_5 = "Fan:SystemModel"

alias fanTypeNamesUC_0 = "FAN:CONSTANTVOLUME"
alias fanTypeNamesUC_1 = "FAN:VARIABLEVOLUME"
alias fanTypeNamesUC_2 = "FAN:ONOFF"
alias fanTypeNamesUC_3 = "FAN:ZONEEXHAUST"
alias fanTypeNamesUC_4 = "FAN:COMPONENTMODEL"
alias fanTypeNamesUC_5 = "FAN:SYSTEMMODEL"

alias unitarySysTypeNames_0 = "AirLoopHVAC:Unitary:Furnace:HeatOnly"
alias unitarySysTypeNames_1 = "AirLoopHVAC:Unitary:Furnace:HeatCool"
alias unitarySysTypeNames_2 = "AirLoopHVAC:UnitaryHeatOnly"
alias unitarySysTypeNames_3 = "AirLoopHVAC:UnitaryHeatCool"
alias unitarySysTypeNames_4 = "AirLoopHVAC:UnitaryHeatPump:AirToAir"
alias unitarySysTypeNames_5 = "AirLoopHVAC:UnitaryHeatPump:WaterToAir"
alias unitarySysTypeNames_6 = "AirLoopHVAC:UnitarySystem"

alias unitarySysTypeNamesUC_0 = "AIRLOOPHVAC:UNITARY:FURNACE:HEATONLY"
alias unitarySysTypeNamesUC_1 = "AIRLOOPHVAC:UNITARY:FURNACE:HEATCOOL"
alias unitarySysTypeNamesUC_2 = "AIRLOOPHVAC:UNITARYHEATONLY"
alias unitarySysTypeNamesUC_3 = "AIRLOOPHVAC:UNITARYHEATCOOL"
alias unitarySysTypeNamesUC_4 = "AIRLOOPHVAC:UNITARYHEATPUMP:AIRTOAIR"
alias unitarySysTypeNamesUC_5 = "AIRLOOPHVAC:UNITARYHEATPUMP:WATERTOAIR"
alias unitarySysTypeNamesUC_6 = "AIRLOOPHVAC:UNITARYSYSTEM"

alias waterFlowNames_0 = "Cycling"
alias waterFlowNames_1 = "Constant"
alias waterFlowNames_2 = "ConstantOnDemand"

alias waterFlowNamesUC_0 = "CYCLING"
alias waterFlowNamesUC_1 = "CONSTANT"
alias waterFlowNamesUC_2 = "CONSTANTONDEMAND"

alias oatTypeNames_0 = "WetBulbTemperature"
alias oatTypeNames_1 = "DryBulbTemperature"

alias oatTypeNamesUC_0 = "WETBULBTEMPERATURE"
alias oatTypeNamesUC_1 = "DRYBULBTEMPERATURE"

alias mixerTypeLocNames_0 = "InletSide"
alias mixerTypeLocNames_1 = "SupplySide"

alias mixerTypeLocNamesUC_0 = "INLETSIDE"
alias mixerTypeLocNamesUC_1 = "SUPPLYSIDE"

alias coilTypeNames_0 = "Coil:Cooling:DX:SingleSpeed"
alias coilTypeNames_1 = "Coil:Heating:DX:SingleSpeed"
alias coilTypeNames_2 = "Coil:Cooling:DX:TwoSpeed"
alias coilTypeNames_3 = "CoilSystem:Cooling:DX:HeatExchangerAssisted"
alias coilTypeNames_4 = "Coil:Cooling:DX:TwoStageWithHumidityControlMode"
alias coilTypeNames_5 = "Coil:WaterHeating:AirToWaterHeatPump:Pumped"
alias coilTypeNames_6 = "Coil:WaterHeating:AirToWaterHeatPump:Wrapped"
alias coilTypeNames_7 = "Coil:Cooling:DX:MultiSpeed"
alias coilTypeNames_8 = "Coil:Heating:DX:MultiSpeed"
alias coilTypeNames_9 = "Coil:Heating:Fuel"
alias coilTypeNames_10 = "Coil:Heating:Gas:MultiStage"
alias coilTypeNames_11 = "Coil:Heating:Electric"
alias coilTypeNames_12 = "Coil:Heating:Electric:MultiStage"
alias coilTypeNames_13 = "Coil:Heating:Desuperheater"
alias coilTypeNames_14 = "Coil:Cooling:Water"
alias coilTypeNames_15 = "Coil:Cooling:Water:DetailedGeometry"
alias coilTypeNames_16 = "Coil:Heating:Water"
alias coilTypeNames_17 = "Coil:Heating:Steam"
alias coilTypeNames_18 = "CoilSystem:Cooling:Water:HeatExchangerAssisted"
alias coilTypeNames_19 = "Coil:Cooling:WaterToAirHeatPump:ParameterEstimation"
alias coilTypeNames_20 = "Coil:Heating:WaterToAirHeatPump:ParameterEstimation"
alias coilTypeNames_21 = "Coil:Cooling:WaterToAirHeatPump:EquationFit"
alias coilTypeNames_22 = "Coil:Heating:WaterToAirHeatPump:EquationFit"
alias coilTypeNames_23 = "Coil:Cooling:DX:VariableRefrigerantFlow"
alias coilTypeNames_24 = "Coil:Heating:DX:VariableRefrigerantFlow"
alias coilTypeNames_25 = "Coil:UserDefined"
alias coilTypeNames_26 = "Coil:Cooling:DX:SingleSpeed:ThermalStorage"
alias coilTypeNames_27 = "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"
alias coilTypeNames_28 = "Coil:Heating:WaterToAirHeatPump:VariableSpeedEquationFit"
alias coilTypeNames_29 = "Coil:Cooling:DX:VariableSpeed"
alias coilTypeNames_30 = "Coil:Heating:DX:VariableSpeed"
alias coilTypeNames_31 = "Coil:WaterHeating:AirToWaterHeatPump:VariableSpeed"
alias coilTypeNames_32 = "Coil:Cooling:DX:VariableRefrigerantFlow:FluidTemperatureControl"
alias coilTypeNames_33 = "Coil:Heating:DX:VariableRefrigerantFlow:FluidTemperatureControl"
alias coilTypeNames_34 = "Coil:Cooling:DX"
alias coilTypeNames_35 = "Coil:Cooling:DX:SubcoolReheat"
alias coilTypeNames_36 = "Coil:Cooling:DX:CurveFit:Speed"

alias coilTypeNamesUC_0 = "COIL:COOLING:DX:SINGLESPEED"
alias coilTypeNamesUC_1 = "COIL:HEATING:DX:SINGLESPEED"
alias coilTypeNamesUC_2 = "COIL:COOLING:DX:TWOSPEED"
alias coilTypeNamesUC_3 = "COILSYSTEM:COOLING:DX:HEATEXCHANGERASSISTED"
alias coilTypeNamesUC_4 = "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"
alias coilTypeNamesUC_5 = "COIL:WATERHEATING:AIRTOWATERHEATPUMP:PUMPED"
alias coilTypeNamesUC_6 = "COIL:WATERHEATING:AIRTOWATERHEATPUMP:WRAPPED"
alias coilTypeNamesUC_7 = "COIL:COOLING:DX:MULTISPEED"
alias coilTypeNamesUC_8 = "COIL:HEATING:DX:MULTISPEED"
alias coilTypeNamesUC_9 = "COIL:HEATING:FUEL"
alias coilTypeNamesUC_10 = "COIL:HEATING:GAS:MULTISTAGE"
alias coilTypeNamesUC_11 = "COIL:HEATING:ELECTRIC"
alias coilTypeNamesUC_12 = "COIL:HEATING:ELECTRIC:MULTISTAGE"
alias coilTypeNamesUC_13 = "COIL:HEATING:DESUPERHEATER"
alias coilTypeNamesUC_14 = "COIL:COOLING:WATER"
alias coilTypeNamesUC_15 = "COIL:COOLING:WATER:DETAILEDGEOMETRY"
alias coilTypeNamesUC_16 = "COIL:HEATING:WATER"
alias coilTypeNamesUC_17 = "COIL:HEATING:STEAM"
alias coilTypeNamesUC_18 = "COILSYSTEM:COOLING:WATER:HEATEXCHANGERASSISTED"
alias coilTypeNamesUC_19 = "COIL:COOLING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION"
alias coilTypeNamesUC_20 = "COIL:HEATING:WATERTOAIRHEATPUMP:PARAMETERESTIMATION"
alias coilTypeNamesUC_21 = "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT"
alias coilTypeNamesUC_22 = "COIL:HEATING:WATERTOAIRHEATPUMP:EQUATIONFIT"
alias coilTypeNamesUC_23 = "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW"
alias coilTypeNamesUC_24 = "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW"
alias coilTypeNamesUC_25 = "COIL:USERDEFINED"
alias coilTypeNamesUC_26 = "COIL:COOLING:DX:SINGLESPEED:THERMALSTORAGE"
alias coilTypeNamesUC_27 = "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT"
alias coilTypeNamesUC_28 = "COIL:HEATING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT"
alias coilTypeNamesUC_29 = "COIL:COOLING:DX:VARIABLESPEED"
alias coilTypeNamesUC_30 = "COIL:HEATING:DX:VARIABLESPEED"
alias coilTypeNamesUC_31 = "COIL:WATERHEATING:AIRTOWATERHEATPUMP:VARIABLESPEED"
alias coilTypeNamesUC_32 = "COIL:COOLING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL"
alias coilTypeNamesUC_33 = "COIL:HEATING:DX:VARIABLEREFRIGERANTFLOW:FLUIDTEMPERATURECONTROL"
alias coilTypeNamesUC_34 = "COIL:COOLING:DX"
alias coilTypeNamesUC_35 = "COIL:COOLING:DX:SUBCOOLREHEAT"
alias coilTypeNamesUC_36 = "COIL:COOLING:DX:CURVEFIT:SPEED"

alias hxTypeNames_0 = "HeatExchanger:AirToAir:FlatPlate"
alias hxTypeNames_1 = "HeatExchanger:AirToAir:SensibleAndLatent"
alias hxTypeNames_2 = "HeatExchanger:Desiccant:BalancedFlow"

alias hxTypeNamesUC_0 = "HEATEXCHANGER:AIRTOAIR:FLATPLATE"
alias hxTypeNamesUC_1 = "HEATEXCHANGER:AIRTOAIR:SENSIBLEANDLATENT"
alias hxTypeNamesUC_2 = "HEATEXCHANGER:DESICCANT:BALANCEDFLOW"

alias mixerTypeNames_0 = "AirTerminal:SingleDuct:InletSideMixer"
alias mixerTypeNames_1 = "AirTerminal:SingleDuct:SupplySideMixer"

alias mixerTypeNamesUC_0 = "AIRTERMINAL:SINGLEDUCT:INLETSIDEMIXER"
alias mixerTypeNamesUC_1 = "AIRTERMINAL:SINGLEDUCT:SUPPLYSIDEMIXER"

alias heatReclaimTypeNames_0 = "Refrigeration:CompressorRack"
alias heatReclaimTypeNames_1 = "Refrigeration:Condenser:AirCooled"
alias heatReclaimTypeNames_2 = "Refrigeration:Condenser:EvaporativeCooled"
alias heatReclaimTypeNames_3 = "Refrigeration:Condenser:WaterCooled"
alias heatReclaimTypeNames_4 = "Coil:Cooling:DX:SingleSpeed"
alias heatReclaimTypeNames_5 = "Coil:Cooling:DX:TwoSpeed"
alias heatReclaimTypeNames_6 = "Coil:Cooling:DX:MultiSpeed"
alias heatReclaimTypeNames_7 = "Coil:Cooling:DX:TwoStageWithHumidityControlMode"
alias heatReclaimTypeNames_8 = "Coil:Cooling:DX:VariableSpeed"
alias heatReclaimTypeNames_9 = "Coil:Cooling:DX"
alias heatReclaimTypeNames_10 = "Coil:Cooling:WaterToAirHeatPump:EquationFit"
alias heatReclaimTypeNames_11 = "Coil:Cooling:WaterToAirHeatPump:VariableSpeedEquationFit"

alias heatReclaimTypeNamesUC_0 = "REFRIGERATION:COMPRESSORRACK"
alias heatReclaimTypeNamesUC_1 = "REFRIGERATION:CONDENSER:AIRCOOLED"
alias heatReclaimTypeNamesUC_2 = "REFRIGERATION:CONDENSER:EVAPORATIVECOOLED"
alias heatReclaimTypeNamesUC_3 = "REFRIGERATION:CONDENSER:WATERCOOLED"
alias heatReclaimTypeNamesUC_4 = "COIL:COOLING:DX:SINGLESPEED"
alias heatReclaimTypeNamesUC_5 = "COIL:COOLING:DX:TWOSPEED"
alias heatReclaimTypeNamesUC_6 = "COIL:COOLING:DX:MULTISPEED"
alias heatReclaimTypeNamesUC_7 = "COIL:COOLING:DX:TWOSTAGEWITHHUMIDITYCONTROLMODE"
alias heatReclaimTypeNamesUC_8 = "COIL:COOLING:DX:VARIABLESPEED"
alias heatReclaimTypeNamesUC_9 = "COIL:COOLING:DX"
alias heatReclaimTypeNamesUC_10 = "COIL:COOLING:WATERTOAIRHEATPUMP:EQUATIONFIT"
alias heatReclaimTypeNamesUC_11 = "COIL:COOLING:WATERTOAIRHEATPUMP:VARIABLESPEEDEQUATIONFIT"

struct HVACGlobalsData:
    var comp_set_pt_equip: List[ComponentSetPtData]
    var mshp_mass_flow_rate_low: Float64
    var mshp_mass_flow_rate_high: Float64
    var mshp_waste_heat: Float64
    var previous_time_step: Float64
    var shorten_time_step_sys_room_air: Bool
    var msus_econo_speed_num: Float64
    var deviation_from_set_pt_threshold_htg: Float64
    var deviation_from_set_pt_threshold_clg: Float64
    var sim_air_loops_flag: Bool
    var sim_elec_circuits_flag: Bool
    var sim_plant_loops_flag: Bool
    var sim_zone_equipment_flag: Bool
    var sim_non_zone_equipment_flag: Bool
    var zone_mass_balance_hvac_re_sim: Bool
    var min_air_loop_iterations_after_first: Int
    var dxct: Int
    var first_time_step_sys_flag: Bool
    var time_step_sys: Float64
    var time_step_sys_sec: Float64
    var sys_time_elapsed: Float64
    var frac_time_step_zone: Float64
    var shorten_time_step_sys: Bool
    var num_of_sys_time_steps: Int
    var num_of_sys_time_steps_last_zone_time_step: Int
    var limit_num_sys_steps: Int
    var use_zone_time_step_history: Bool
    var num_plant_loops: Int
    var num_cond_loops: Int
    var num_elec_circuits: Int
    var num_gas_meters: Int
    var num_primary_air_sys: Int
    var on_off_fan_part_load_fraction: Float64
    var dx_coil_total_capacity: Float64
    var dx_elec_cooling_power: Float64
    var dx_elec_heating_power: Float64
    var elec_heating_coil_power: Float64
    var supp_heating_coil_power: Float64
    var air_to_air_hx_elec_power: Float64
    var defrost_elec_power: Float64
    var unbal_exh_mass_flow: Float64
    var balanced_exh_mass_flow: Float64
    var plenum_induced_mass_flow: Float64
    var turn_fans_on: Bool
    var turn_fans_off: Bool
    var set_point_error_flag: Bool
    var do_set_point_test: Bool
    var night_vent_on: Bool
    var num_temp_cont_comps: Int
    var hpwh_inlet_db_temp: Float64
    var hpwh_inlet_wb_temp: Float64
    var hpwh_crankcase_db_temp: Float64
    var air_loop_init: Bool
    var air_loops_sim_once: Bool
    var get_air_path_data_done: Bool
    var standard_ratings_my_one_time_flag: Bool
    var standard_ratings_my_cool_one_time_flag: Bool
    var standard_ratings_my_cool_one_time_flag2: Bool
    var standard_ratings_my_cool_one_time_flag3: Bool
    var standard_ratings_my_heat_one_time_flag: Bool
    var standard_ratings_my_heat_one_time_flag2: Bool

    fn __init__(inout self):
        self.comp_set_pt_equip = List[ComponentSetPtData]()
        self.mshp_mass_flow_rate_low = 0.0
        self.mshp_mass_flow_rate_high = 0.0
        self.mshp_waste_heat = 0.0
        self.previous_time_step = 0.0
        self.shorten_time_step_sys_room_air = False
        self.msus_econo_speed_num = 0
        self.deviation_from_set_pt_threshold_htg = -0.2
        self.deviation_from_set_pt_threshold_clg = 0.2
        self.sim_air_loops_flag = False
        self.sim_elec_circuits_flag = False
        self.sim_plant_loops_flag = False
        self.sim_zone_equipment_flag = False
        self.sim_non_zone_equipment_flag = False
        self.zone_mass_balance_hvac_re_sim = False
        self.min_air_loop_iterations_after_first = 1
        self.dxct = DXCoilType_Regular
        self.first_time_step_sys_flag = False
        self.time_step_sys = 0.0
        self.time_step_sys_sec = 0.0
        self.sys_time_elapsed = 0.0
        self.frac_time_step_zone = 0.0
        self.shorten_time_step_sys = False
        self.num_of_sys_time_steps = 1
        self.num_of_sys_time_steps_last_zone_time_step = 1
        self.limit_num_sys_steps = 0
        self.use_zone_time_step_history = True
        self.num_plant_loops = 0
        self.num_cond_loops = 0
        self.num_elec_circuits = 0
        self.num_gas_meters = 0
        self.num_primary_air_sys = 0
        self.on_off_fan_part_load_fraction = 1.0
        self.dx_coil_total_capacity = 0.0
        self.dx_elec_cooling_power = 0.0
        self.dx_elec_heating_power = 0.0
        self.elec_heating_coil_power = 0.0
        self.supp_heating_coil_power = 0.0
        self.air_to_air_hx_elec_power = 0.0
        self.defrost_elec_power = 0.0
        self.unbal_exh_mass_flow = 0.0
        self.balanced_exh_mass_flow = 0.0
        self.plenum_induced_mass_flow = 0.0
        self.turn_fans_on = False
        self.turn_fans_off = False
        self.set_point_error_flag = False
        self.do_set_point_test = False
        self.night_vent_on = False
        self.num_temp_cont_comps = 0
        self.hpwh_inlet_db_temp = 0.0
        self.hpwh_inlet_wb_temp = 0.0
        self.hpwh_crankcase_db_temp = 0.0
        self.air_loop_init = False
        self.air_loops_sim_once = False
        self.get_air_path_data_done = False
        self.standard_ratings_my_one_time_flag = True
        self.standard_ratings_my_cool_one_time_flag = True
        self.standard_ratings_my_cool_one_time_flag2 = True
        self.standard_ratings_my_cool_one_time_flag3 = True
        self.standard_ratings_my_heat_one_time_flag = True
        self.standard_ratings_my_heat_one_time_flag2 = True

    fn init_constant_state(inout self, state: Any) -> None:
        pass

    fn init_state(inout self, state: Any) -> None:
        pass

    fn clear_state(inout self) -> None:
        self.__init__()
