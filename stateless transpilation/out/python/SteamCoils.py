# EXTERNAL DEPS (to wire in):
# - EnergyPlusData: main state object
# - state.dataSteamCoils: SteamCoilsData object
# - state.dataLoopNodes: Node array/lookup
# - state.dataGlobal: BeginEnvrnFlag, WarmupFlag, DoingSizing, KickOffSimulation, SysSizingCalc, BeginEnvrnFlag
# - state.dataEnvrn: StdBaroPress, EnvironmentData
# - state.dataHVACGlobals: TimeStepSysSec, FanOp enum
# - state.dataInputProcessing: inputProcessor
# - state.dataSize: CurSysNum, CurZoneEqNum, etc.
# - state.dataFaultsMgr: FaultsCoilSATSensor
# - state.dataFans: fans array
# - state.dataAirSystemsData: PrimaryAirSystems
# - state.dataContaminantBalance: Contaminant flags
# - state.dataPlnt: PlantLoop
# - Psychrometrics functions: PsyRhoAirFnPbTdbW, PsyCpAirFnW, PsyHFnTdbW, PsyCpAirFnW
# - FluidProperties: RefrigProps, GetSteam
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, ScanPlantLoopsForObject, MyPlantSizingIndex, RegisterPlantCompDesignFlow
# - GlobalNames: VerifyUniqueCoilName
# - Node module: GetOnlySingleNode, TestCompSet
# - ScheduleManager: GetScheduleAlwaysOn, GetSchedule, Schedule
# - OutputProcessor functions: SetupOutputVariable
# - ReportCoilSelection functions
# - UtilityRoutines functions: FindItemInList, SameString, FindItem, makeUPPER, getEnumValue
# - FaultsManager functions
# - Autosizing functions

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, List
import math


class CoilControlType(IntEnum):
    Invalid = -1
    TemperatureSetPoint = 0
    ZoneLoadControl = 1
    Num = 2


coilControlTypeNames = ["TEMPERATURESETPOINTCONTROL", "ZONELOADCONTROL"]


@dataclass
class SteamCoilEquipConditions:
    Name: str = ""
    coilType: int = -1  # HVAC::CoilType::Invalid
    coilReportNum: int = -1
    availSched: Optional[object] = None
    InletAirMassFlowRate: float = 0.0
    OutletAirMassFlowRate: float = 0.0
    InletAirTemp: float = 0.0
    OutletAirTemp: float = 0.0
    InletAirHumRat: float = 0.0
    OutletAirHumRat: float = 0.0
    InletAirEnthalpy: float = 0.0
    OutletAirEnthalpy: float = 0.0
    TotSteamCoilLoad: float = 0.0
    SenSteamCoilLoad: float = 0.0
    TotSteamHeatingCoilEnergy: float = 0.0
    TotSteamCoolingCoilEnergy: float = 0.0
    SenSteamCoolingCoilEnergy: float = 0.0
    TotSteamHeatingCoilRate: float = 0.0
    LoopLoss: float = 0.0
    TotSteamCoolingCoilRate: float = 0.0
    SenSteamCoolingCoilRate: float = 0.0
    LeavingRelHum: float = 0.0
    DesiredOutletTemp: float = 0.0
    DesiredOutletHumRat: float = 0.0
    InletSteamTemp: float = 0.0
    OutletSteamTemp: float = 0.0
    InletSteamMassFlowRate: float = 0.0
    OutletSteamMassFlowRate: float = 0.0
    MaxSteamVolFlowRate: float = 0.0
    MaxSteamMassFlowRate: float = 0.0
    InletSteamEnthalpy: float = 0.0
    OutletWaterEnthalpy: float = 0.0
    InletSteamPress: float = 0.0
    InletSteamQuality: float = 0.0
    OutletSteamQuality: float = 0.0
    DegOfSubcooling: float = 0.0
    LoopSubcoolReturn: float = 0.0
    AirInletNodeNum: int = 0
    AirOutletNodeNum: int = 0
    SteamInletNodeNum: int = 0
    SteamOutletNodeNum: int = 0
    TempSetPointNodeNum: int = 0
    TypeOfCoil: CoilControlType = CoilControlType.Invalid
    steam: Optional[object] = None
    plantLoc: Optional[dict] = None
    CoilType: int = -1  # DataPlant::PlantEquipmentType::Invalid
    OperatingCapacity: float = 0.0
    DesiccantRegenerationCoil: bool = False
    DesiccantDehumNum: int = 0
    FaultyCoilSATFlag: bool = False
    FaultyCoilSATIndex: int = 0
    FaultyCoilSATOffset: float = 0.0
    reportCoilFinalSizes: bool = True
    DesCoilCapacity: float = 0.0
    DesAirVolFlow: float = 0.0


@dataclass
class SteamCoilsData:
    NumSteamCoils: int = 0
    MySizeFlag: List[bool] = field(default_factory=list)
    CoilWarningOnceFlag: List[bool] = field(default_factory=list)
    CheckEquipName: List[bool] = field(default_factory=list)
    GetSteamCoilsInputFlag: bool = True
    MyOneTimeFlag: bool = True
    MyEnvrnFlag: List[bool] = field(default_factory=list)
    MyPlantScanFlag: List[bool] = field(default_factory=list)
    ErrCount: int = 0
    SteamCoil: List[SteamCoilEquipConditions] = field(default_factory=list)


def SimulateSteamCoilComponents(state, comp_name, first_hvac_iteration, comp_index, q_coil_req=None, q_coil_actual=None, fan_op=None, part_load_ratio=None):
    real64_result = [0.0]
    
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if comp_index[0] == 0:
        coil_num = _find_item_in_list(comp_name, state.dataSteamCoils.SteamCoil)
        if coil_num < 0:
            raise RuntimeError(f"SimulateSteamCoilComponents: Coil not found={comp_name}")
        comp_index[0] = coil_num
    else:
        coil_num = comp_index[0]
        if coil_num >= state.dataSteamCoils.NumSteamCoils or coil_num < 0:
            raise RuntimeError(f"SimulateSteamCoilComponents: Invalid CompIndex passed={coil_num}, Number of Steam Coils={state.dataSteamCoils.NumSteamCoils}, Coil name={comp_name}")
        if state.dataSteamCoils.CheckEquipName[coil_num]:
            if comp_name != state.dataSteamCoils.SteamCoil[coil_num].Name:
                raise RuntimeError(f"SimulateSteamCoilComponents: Invalid CompIndex passed={coil_num}, Coil name={comp_name}, stored Coil Name for that index={state.dataSteamCoils.SteamCoil[coil_num].Name}")
            state.dataSteamCoils.CheckEquipName[coil_num] = False
    
    InitSteamCoil(state, coil_num, first_hvac_iteration)
    
    fan_op_val = fan_op if fan_op is not None else 0
    part_load_frac = part_load_ratio if part_load_ratio is not None else 1.0
    q_coil_req_local = q_coil_req if q_coil_req is not None else 0.0
    
    CalcSteamAirCoil(state, coil_num, q_coil_req_local, real64_result, fan_op_val, part_load_frac)
    
    if q_coil_actual is not None:
        q_coil_actual[0] = real64_result[0]
    
    UpdateSteamCoil(state, coil_num)
    ReportSteamCoil(state, coil_num)


def GetSteamCoilInput(state):
    routine_name = "GetSteamCoilInput"
    current_module_object = "Coil:Heating:Steam"
    num_stm_heat = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    state.dataSteamCoils.NumSteamCoils = num_stm_heat
    
    if state.dataSteamCoils.NumSteamCoils > 0:
        state.dataSteamCoils.SteamCoil = [SteamCoilEquipConditions() for _ in range(state.dataSteamCoils.NumSteamCoils)]
        state.dataSteamCoils.CheckEquipName = [True] * state.dataSteamCoils.NumSteamCoils
    
    total_args = [0]
    num_alphas = [0]
    num_nums = [0]
    state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, current_module_object, total_args, num_alphas, num_nums)
    
    for stm_heat_num in range(num_stm_heat):
        coil_num = stm_heat_num
        alph_array = [""] * num_alphas[0]
        num_array = [0.0] * num_nums[0]
        io_stat = [0]
        l_numeric_blanks = [True] * num_nums[0]
        l_alpha_blanks = [True] * num_alphas[0]
        c_alpha_fields = [""] * num_alphas[0]
        c_numeric_fields = [""] * num_nums[0]
        
        state.dataInputProcessing.inputProcessor.getObjectItem(state, current_module_object, stm_heat_num, alph_array, num_alphas, num_array, num_nums, io_stat, l_numeric_blanks, l_alpha_blanks, c_alpha_fields, c_numeric_fields)
        
        steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
        steam_coil.Name = alph_array[0]
        steam_coil.coilType = 1  # HVAC::CoilType::HeatingSteam
        
        if l_alpha_blanks[1]:
            steam_coil.availSched = state.dataSchedules.GetScheduleAlwaysOn(state)
        else:
            steam_coil.availSched = state.dataSchedules.GetSchedule(state, alph_array[1])
        
        steam_coil.CoilType = 1  # DataPlant::PlantEquipmentType::CoilSteamAirHeating
        steam_coil.MaxSteamVolFlowRate = num_array[0]
        steam_coil.DegOfSubcooling = num_array[1]
        steam_coil.LoopSubcoolReturn = num_array[2]
        
        steam_coil.SteamInletNodeNum = state.dataNodeInputMgr.GetOnlySingleNode(state, alph_array[2], False, "CoilHeatingSteam", alph_array[0], "Steam", "Inlet", "Secondary", False)
        steam_coil.SteamOutletNodeNum = state.dataNodeInputMgr.GetOnlySingleNode(state, alph_array[3], False, "CoilHeatingSteam", alph_array[0], "Steam", "Outlet", "Secondary", False)
        steam_coil.AirInletNodeNum = state.dataNodeInputMgr.GetOnlySingleNode(state, alph_array[4], False, "CoilHeatingSteam", alph_array[0], "Air", "Inlet", "Primary", False)
        steam_coil.AirOutletNodeNum = state.dataNodeInputMgr.GetOnlySingleNode(state, alph_array[5], False, "CoilHeatingSteam", alph_array[0], "Air", "Outlet", "Primary", False)
        
        control_mode = alph_array[6].upper()
        steam_coil.TypeOfCoil = CoilControlType(_find_enum_value(coilControlTypeNames, control_mode))
        
        if steam_coil.TypeOfCoil == CoilControlType.TemperatureSetPoint:
            steam_coil.TempSetPointNodeNum = state.dataNodeInputMgr.GetOnlySingleNode(state, alph_array[7], False, "CoilHeatingSteam", alph_array[0], "Air", "Sensor", "Primary", False)
            if steam_coil.TempSetPointNodeNum == 0:
                raise RuntimeError(f"Temperature Setpoint Node not found for {alph_array[0]}")
        elif steam_coil.TypeOfCoil == CoilControlType.ZoneLoadControl:
            if not l_alpha_blanks[7]:
                steam_coil.TempSetPointNodeNum = 0
        
        steam_coil.steam = state.dataFluidProps.GetSteam(state)


def InitSteamCoil(state, coil_num, first_hvac_iteration):
    routine_name = "InitSteamCoil"
    
    if state.dataSteamCoils.MyOneTimeFlag:
        state.dataSteamCoils.MyEnvrnFlag = [True] * state.dataSteamCoils.NumSteamCoils
        state.dataSteamCoils.MySizeFlag = [True] * state.dataSteamCoils.NumSteamCoils
        state.dataSteamCoils.CoilWarningOnceFlag = [True] * state.dataSteamCoils.NumSteamCoils
        state.dataSteamCoils.MyPlantScanFlag = [True] * state.dataSteamCoils.NumSteamCoils
        state.dataSteamCoils.MyOneTimeFlag = False
    
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
    
    if state.dataSteamCoils.MyPlantScanFlag[coil_num]:
        err_flag = [False]
        state.dataPlantUtilities.ScanPlantLoopsForObject(state, steam_coil.Name, steam_coil.CoilType, steam_coil.plantLoc, err_flag)
        if err_flag[0]:
            raise RuntimeError("InitSteamCoil: Program terminated for previous conditions.")
        state.dataSteamCoils.MyPlantScanFlag[coil_num] = False
    
    if not state.dataGlobal.SysSizingCalc and state.dataSteamCoils.MySizeFlag[coil_num]:
        SizeSteamCoil(state, coil_num)
        state.dataSteamCoils.MySizeFlag[coil_num] = False
    
    if state.dataGlobal.BeginEnvrnFlag and state.dataSteamCoils.MyEnvrnFlag[coil_num]:
        steam_coil.TotSteamHeatingCoilEnergy = 0.0
        steam_coil.TotSteamCoolingCoilEnergy = 0.0
        steam_coil.SenSteamCoolingCoilEnergy = 0.0
        steam_coil.TotSteamHeatingCoilRate = 0.0
        steam_coil.TotSteamCoolingCoilRate = 0.0
        steam_coil.SenSteamCoolingCoilRate = 0.0
        steam_coil.InletAirMassFlowRate = 0.0
        steam_coil.OutletAirMassFlowRate = 0.0
        steam_coil.InletAirTemp = 0.0
        steam_coil.OutletAirTemp = 0.0
        steam_coil.InletAirHumRat = 0.0
        steam_coil.OutletAirHumRat = 0.0
        steam_coil.InletAirEnthalpy = 0.0
        steam_coil.OutletAirEnthalpy = 0.0
        steam_coil.TotSteamCoilLoad = 0.0
        steam_coil.SenSteamCoilLoad = 0.0
        steam_coil.LoopLoss = 0.0
        steam_coil.LeavingRelHum = 0.0
        steam_coil.DesiredOutletTemp = 0.0
        steam_coil.DesiredOutletHumRat = 0.0
        steam_coil.InletSteamTemp = 0.0
        steam_coil.OutletSteamTemp = 0.0
        steam_coil.InletSteamMassFlowRate = 0.0
        steam_coil.OutletSteamMassFlowRate = 0.0
        steam_coil.InletSteamEnthalpy = 0.0
        steam_coil.OutletWaterEnthalpy = 0.0
        steam_coil.InletSteamPress = 0.0
        steam_coil.InletSteamQuality = 0.0
        steam_coil.OutletSteamQuality = 0.0
        
        steam_inlet_node = steam_coil.SteamInletNodeNum
        state.dataLoopNodes.Node[steam_inlet_node].Temp = 100.0
        state.dataLoopNodes.Node[steam_inlet_node].Press = 101325.0
        steam = state.dataFluidProps.GetSteam(state)
        steam_density = steam.getSatDensity(state, state.dataLoopNodes.Node[steam_inlet_node].Temp, 1.0, routine_name)
        start_enth_steam = steam.getSatEnthalpy(state, state.dataLoopNodes.Node[steam_inlet_node].Temp, 1.0, routine_name)
        state.dataLoopNodes.Node[steam_inlet_node].Enthalpy = start_enth_steam
        state.dataLoopNodes.Node[steam_inlet_node].Quality = 1.0
        state.dataLoopNodes.Node[steam_inlet_node].HumRat = 0.0
        steam_coil.MaxSteamMassFlowRate = steam_density * steam_coil.MaxSteamVolFlowRate
        state.dataPlantUtilities.InitComponentNodes(state, 0.0, steam_coil.MaxSteamMassFlowRate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum)
        state.dataSteamCoils.MyEnvrnFlag[coil_num] = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataSteamCoils.MyEnvrnFlag[coil_num] = True
    
    air_inlet_node = steam_coil.AirInletNodeNum
    steam_inlet_node = steam_coil.SteamInletNodeNum
    control_node = steam_coil.TempSetPointNodeNum
    air_outlet_node = steam_coil.AirOutletNodeNum
    
    if control_node == 0:
        steam_coil.DesiredOutletTemp = 0.0
    elif control_node == air_outlet_node:
        steam_coil.DesiredOutletTemp = state.dataLoopNodes.Node[control_node].TempSetPoint
    else:
        steam_coil.DesiredOutletTemp = state.dataLoopNodes.Node[control_node].TempSetPoint - (state.dataLoopNodes.Node[control_node].Temp - state.dataLoopNodes.Node[air_outlet_node].Temp)
    
    steam_coil.InletAirMassFlowRate = state.dataLoopNodes.Node[air_inlet_node].MassFlowRate
    steam_coil.InletAirTemp = state.dataLoopNodes.Node[air_inlet_node].Temp
    steam_coil.InletAirHumRat = state.dataLoopNodes.Node[air_inlet_node].HumRat
    steam_coil.InletAirEnthalpy = state.dataLoopNodes.Node[air_inlet_node].Enthalpy
    
    if first_hvac_iteration:
        steam_coil.InletSteamMassFlowRate = steam_coil.MaxSteamMassFlowRate
    else:
        steam_coil.InletSteamMassFlowRate = state.dataLoopNodes.Node[steam_inlet_node].MassFlowRate
    
    steam_coil.InletSteamTemp = state.dataLoopNodes.Node[steam_inlet_node].Temp
    steam_coil.InletSteamEnthalpy = state.dataLoopNodes.Node[steam_inlet_node].Enthalpy
    steam_coil.InletSteamPress = state.dataLoopNodes.Node[steam_inlet_node].Press
    steam_coil.InletSteamQuality = state.dataLoopNodes.Node[steam_inlet_node].Quality
    steam_coil.TotSteamHeatingCoilRate = 0.0
    steam_coil.TotSteamCoolingCoilRate = 0.0
    steam_coil.SenSteamCoolingCoilRate = 0.0


def SizeSteamCoil(state, coil_num):
    routine_name = "SizeSteamCoil"
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
    # Sizing logic implementation would go here
    pass


def CalcSteamAirCoil(state, coil_num, q_coil_requested, q_coil_actual, fan_op, part_load_ratio):
    routine_name = "CalcSteamAirCoil"
    routine_name_size_steam_coil = "SizeSteamCoil"
    
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
    
    q_coil_req = q_coil_requested
    temp_air_in = steam_coil.InletAirTemp
    win = steam_coil.InletAirHumRat
    temp_steam_in = steam_coil.InletSteamTemp
    coil_press = steam_coil.InletSteamPress
    subcool_delta_temp = steam_coil.DegOfSubcooling
    temp_set_point = steam_coil.DesiredOutletTemp
    
    if steam_coil.FaultyCoilSATFlag and not state.dataGlobal.WarmupFlag and not state.dataGlobal.DoingSizing and not state.dataGlobal.KickOffSimulation:
        fault_index = steam_coil.FaultyCoilSATIndex
        steam_coil.FaultyCoilSATOffset = state.dataFaultsMgr.FaultsCoilSATSensor[fault_index].CalFaultOffsetAct(state)
        temp_set_point -= steam_coil.FaultyCoilSATOffset
    
    if fan_op == 1:  # HVAC::FanOp::Cycling
        if part_load_ratio > 0.0:
            air_mass_flow = steam_coil.InletAirMassFlowRate / part_load_ratio
            steam_mass_flow_rate = min(steam_coil.InletSteamMassFlowRate / part_load_ratio, steam_coil.MaxSteamMassFlowRate)
            q_coil_req /= part_load_ratio
        else:
            air_mass_flow = 0.0
            steam_mass_flow_rate = 0.0
    else:
        air_mass_flow = steam_coil.InletAirMassFlowRate
        steam_mass_flow_rate = steam_coil.InletSteamMassFlowRate
    
    if air_mass_flow > 0.0:
        capacitance_air = state.dataPsychrometrics.PsyCpAirFnW(win) * air_mass_flow
    else:
        capacitance_air = 0.0
    
    temp_air_out = temp_air_in
    temp_water_out = temp_steam_in
    heating_coil_load = 0.0
    
    if steam_coil.TypeOfCoil == CoilControlType.ZoneLoadControl:
        if capacitance_air > 0.0 and steam_coil.InletSteamMassFlowRate > 0.0 and (steam_coil.availSched.getCurrentVal() > 0.0 or state.dataSteamCoils.MySizeFlag[coil_num]) and q_coil_req > 0.0:
            enth_steam_in_dry = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 1.0, routine_name)
            enth_steam_out_wet = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 0.0, routine_name)
            latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
            cp_water = steam_coil.steam.getSatSpecificHeat(state, temp_steam_in, 0.0, routine_name_size_steam_coil)
            q_steam_coil_max_ht = steam_coil.MaxSteamMassFlowRate * (latent_heat_steam + subcool_delta_temp * cp_water)
            steam_coil.OperatingCapacity = q_steam_coil_max_ht
            
            if q_coil_req > q_steam_coil_max_ht:
                q_coil_cap = q_steam_coil_max_ht
            else:
                q_coil_cap = q_coil_req
            
            steam_mass_flow_rate = q_coil_cap / (latent_heat_steam + subcool_delta_temp * cp_water)
            state.dataPlantUtilities.SetComponentFlowRate(state, steam_mass_flow_rate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum, steam_coil.plantLoc)
            q_coil_cap = steam_mass_flow_rate * (latent_heat_steam + subcool_delta_temp * cp_water)
            temp_water_out = temp_steam_in - subcool_delta_temp
            heating_coil_load = q_coil_cap
            temp_air_out = temp_air_in + q_coil_cap / (air_mass_flow * state.dataPsychrometrics.PsyCpAirFnW(win))
            steam_coil.OutletSteamMassFlowRate = steam_mass_flow_rate
            steam_coil.InletSteamMassFlowRate = steam_mass_flow_rate
            
            temp_water_atm_press = steam_coil.steam.getSatTemperature(state, state.dataEnvrn.StdBaroPress, routine_name)
            temp_loop_out_to_pump = temp_water_atm_press - steam_coil.LoopSubcoolReturn
            enth_coil_outlet = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 0.0, routine_name) - cp_water * subcool_delta_temp
            enth_at_atm_press = steam_coil.steam.getSatEnthalpy(state, temp_water_atm_press, 0.0, routine_name)
            cp_water = steam_coil.steam.getSatSpecificHeat(state, temp_loop_out_to_pump, 0.0, routine_name_size_steam_coil)
            enth_pump_inlet = enth_at_atm_press - cp_water * steam_coil.LoopSubcoolReturn
            steam_coil.OutletWaterEnthalpy = enth_pump_inlet
            energy_loss_to_environment = steam_mass_flow_rate * (enth_coil_outlet - enth_pump_inlet)
            steam_coil.LoopLoss = energy_loss_to_environment
        else:
            temp_air_out = temp_air_in
            temp_water_out = temp_steam_in
            heating_coil_load = 0.0
            steam_coil.OutletWaterEnthalpy = steam_coil.InletSteamEnthalpy
            steam_coil.OutletSteamMassFlowRate = 0.0
            steam_coil.OutletSteamQuality = 0.0
            steam_coil.LoopLoss = 0.0
    elif steam_coil.TypeOfCoil == CoilControlType.TemperatureSetPoint:
        temp_control_tol = 0.001
        if capacitance_air > 0.0 and steam_coil.InletSteamMassFlowRate > 0.0 and (steam_coil.availSched.getCurrentVal() > 0.0 or state.dataSteamCoils.MySizeFlag[coil_num]) and abs(temp_set_point - temp_air_in) > temp_control_tol:
            enth_steam_in_dry = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 1.0, routine_name)
            enth_steam_out_wet = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 0.0, routine_name)
            latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
            cp_water = steam_coil.steam.getSatSpecificHeat(state, temp_steam_in, 0.0, routine_name_size_steam_coil)
            q_steam_coil_max_ht = steam_coil.MaxSteamMassFlowRate * (latent_heat_steam + subcool_delta_temp * cp_water)
            q_coil_cap = capacitance_air * (temp_set_point - temp_air_in)
            
            if q_coil_cap <= 0.0:
                q_coil_cap = 0.0
                temp_air_out = temp_air_in
                steam_mass_flow_rate = 0.0
                state.dataPlantUtilities.SetComponentFlowRate(state, steam_mass_flow_rate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum, steam_coil.plantLoc)
                temp_water_out = temp_steam_in
                heating_coil_load = q_coil_cap
                steam_coil.OutletWaterEnthalpy = steam_coil.InletSteamEnthalpy
                steam_coil.OutletSteamMassFlowRate = steam_mass_flow_rate
                steam_coil.InletSteamMassFlowRate = steam_mass_flow_rate
            elif q_coil_cap > q_steam_coil_max_ht:
                q_coil_cap = q_steam_coil_max_ht
                temp_water_out = temp_steam_in - subcool_delta_temp
                steam_mass_flow_rate = q_coil_cap / (latent_heat_steam + subcool_delta_temp * cp_water)
                state.dataPlantUtilities.SetComponentFlowRate(state, steam_mass_flow_rate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum, steam_coil.plantLoc)
                q_coil_cap = steam_mass_flow_rate * (latent_heat_steam + subcool_delta_temp * cp_water)
                temp_air_out = temp_air_in + q_coil_cap / (air_mass_flow * state.dataPsychrometrics.PsyCpAirFnW(win))
                heating_coil_load = q_coil_cap
                steam_coil.OutletWaterEnthalpy = steam_coil.InletSteamEnthalpy - heating_coil_load / steam_mass_flow_rate
                steam_coil.OutletSteamMassFlowRate = steam_mass_flow_rate
                steam_coil.InletSteamMassFlowRate = steam_mass_flow_rate
            else:
                temp_water_out = temp_steam_in - subcool_delta_temp
                steam_mass_flow_rate = q_coil_cap / (latent_heat_steam + subcool_delta_temp * cp_water)
                state.dataPlantUtilities.SetComponentFlowRate(state, steam_mass_flow_rate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum, steam_coil.plantLoc)
                q_coil_cap = steam_mass_flow_rate * (latent_heat_steam + subcool_delta_temp * cp_water)
                temp_air_out = temp_air_in + q_coil_cap / (air_mass_flow * state.dataPsychrometrics.PsyCpAirFnW(win))
                heating_coil_load = q_coil_cap
                steam_coil.OutletSteamMassFlowRate = steam_mass_flow_rate
                steam_coil.InletSteamMassFlowRate = steam_mass_flow_rate
                
                temp_water_atm_press = steam_coil.steam.getSatTemperature(state, state.dataEnvrn.StdBaroPress, routine_name)
                temp_loop_out_to_pump = temp_water_atm_press - steam_coil.LoopSubcoolReturn
                enth_coil_outlet = steam_coil.steam.getSatEnthalpy(state, temp_steam_in, 0.0, routine_name) - cp_water * subcool_delta_temp
                enth_at_atm_press = steam_coil.steam.getSatEnthalpy(state, temp_water_atm_press, 0.0, routine_name)
                cp_water = steam_coil.steam.getSatSpecificHeat(state, temp_loop_out_to_pump, 0.0, routine_name_size_steam_coil)
                enth_pump_inlet = enth_at_atm_press - cp_water * steam_coil.LoopSubcoolReturn
                steam_coil.OutletWaterEnthalpy = enth_pump_inlet
                energy_loss_to_environment = steam_mass_flow_rate * (enth_coil_outlet - enth_pump_inlet)
                steam_coil.LoopLoss = energy_loss_to_environment
        else:
            steam_mass_flow_rate = 0.0
            state.dataPlantUtilities.SetComponentFlowRate(state, steam_mass_flow_rate, steam_coil.SteamInletNodeNum, steam_coil.SteamOutletNodeNum, steam_coil.plantLoc)
            temp_air_out = temp_air_in
            temp_water_out = temp_steam_in
            heating_coil_load = 0.0
            steam_coil.OutletWaterEnthalpy = steam_coil.InletSteamEnthalpy
            steam_coil.OutletSteamMassFlowRate = 0.0
            steam_coil.OutletSteamQuality = 0.0
            steam_coil.LoopLoss = 0.0
    
    if fan_op == 1:  # HVAC::FanOp::Cycling
        heating_coil_load *= part_load_ratio
    
    steam_coil.TotSteamHeatingCoilRate = heating_coil_load
    steam_coil.OutletAirTemp = temp_air_out
    steam_coil.OutletSteamTemp = temp_water_out
    steam_coil.OutletSteamQuality = 0.0
    q_coil_actual[0] = heating_coil_load
    steam_coil.OutletAirHumRat = steam_coil.InletAirHumRat
    steam_coil.OutletAirMassFlowRate = steam_coil.InletAirMassFlowRate
    steam_coil.OutletAirEnthalpy = state.dataPsychrometrics.PsyHFnTdbW(steam_coil.OutletAirTemp, steam_coil.OutletAirHumRat)


def UpdateSteamCoil(state, coil_num):
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
    
    air_inlet_node = steam_coil.AirInletNodeNum
    steam_inlet_node = steam_coil.SteamInletNodeNum
    air_outlet_node = steam_coil.AirOutletNodeNum
    steam_outlet_node = steam_coil.SteamOutletNodeNum
    
    state.dataLoopNodes.Node[air_outlet_node].MassFlowRate = steam_coil.OutletAirMassFlowRate
    state.dataLoopNodes.Node[air_outlet_node].Temp = steam_coil.OutletAirTemp
    state.dataLoopNodes.Node[air_outlet_node].HumRat = steam_coil.OutletAirHumRat
    state.dataLoopNodes.Node[air_outlet_node].Enthalpy = steam_coil.OutletAirEnthalpy
    
    state.dataPlantUtilities.SafeCopyPlantNode(state, steam_inlet_node, steam_outlet_node)
    
    state.dataLoopNodes.Node[steam_outlet_node].Temp = steam_coil.OutletSteamTemp
    state.dataLoopNodes.Node[steam_outlet_node].Enthalpy = steam_coil.OutletWaterEnthalpy
    state.dataLoopNodes.Node[steam_outlet_node].Quality = steam_coil.OutletSteamQuality
    
    state.dataLoopNodes.Node[air_outlet_node].Quality = state.dataLoopNodes.Node[air_inlet_node].Quality
    state.dataLoopNodes.Node[air_outlet_node].Press = state.dataLoopNodes.Node[air_inlet_node].Press
    state.dataLoopNodes.Node[air_outlet_node].MassFlowRateMin = state.dataLoopNodes.Node[air_inlet_node].MassFlowRateMin
    state.dataLoopNodes.Node[air_outlet_node].MassFlowRateMax = state.dataLoopNodes.Node[air_inlet_node].MassFlowRateMax
    state.dataLoopNodes.Node[air_outlet_node].MassFlowRateMinAvail = state.dataLoopNodes.Node[air_inlet_node].MassFlowRateMinAvail
    state.dataLoopNodes.Node[air_outlet_node].MassFlowRateMaxAvail = state.dataLoopNodes.Node[air_inlet_node].MassFlowRateMaxAvail
    
    if state.dataContaminantBalance.Contaminant.CO2Simulation:
        state.dataLoopNodes.Node[air_outlet_node].CO2 = state.dataLoopNodes.Node[air_inlet_node].CO2
    if state.dataContaminantBalance.Contaminant.GenericContamSimulation:
        state.dataLoopNodes.Node[air_outlet_node].GenContam = state.dataLoopNodes.Node[air_inlet_node].GenContam


def ReportSteamCoil(state, coil_num):
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
    steam_coil.TotSteamHeatingCoilEnergy = steam_coil.TotSteamHeatingCoilRate * state.dataHVACGlobal.TimeStepSysSec


def GetSteamCoilIndex(state, coil_type, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if coil_type == "COIL:HEATING:STEAM":
        index_num = _find_item_in_list(coil_name, state.dataSteamCoils.SteamCoil)
    else:
        index_num = -1
    
    if index_num < 0:
        raise RuntimeError(f"GetSteamCoilIndex: Could not find CoilType=\"{coil_type}\" with Name=\"{coil_name}\"")
    
    return index_num


def GetCompIndex(state, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    index_num = _find_item_in_list(coil_name, state.dataSteamCoils.SteamCoil)
    
    if index_num < 0:
        raise RuntimeError(f"GetSteamCoilIndex: Could not find CoilType = Coil:Heating:Steam with Name = \"{coil_name}\"")
    
    return index_num


def CheckSteamCoilSchedule(state, comp_type, comp_name, value, comp_index):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if comp_index[0] == 0:
        coil_num = _find_item_in_list(comp_name, state.dataSteamCoils.SteamCoil)
        if coil_num < 0:
            raise RuntimeError(f"CheckSteamCoilSchedule: Coil not found={comp_name}")
        comp_index[0] = coil_num
        steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
        value[0] = steam_coil.availSched.getCurrentVal()
    else:
        coil_num = comp_index[0]
        if coil_num >= state.dataSteamCoils.NumSteamCoils or coil_num < 0:
            raise RuntimeError(f"SimulateSteamCoilComponents: Invalid CompIndex passed={coil_num}, Number of Steam Coils={state.dataSteamCoils.NumSteamCoils}, Coil name={comp_name}")
        steam_coil = state.dataSteamCoils.SteamCoil[coil_num]
        if comp_name != steam_coil.Name:
            raise RuntimeError(f"SimulateSteamCoilComponents: Invalid CompIndex passed={coil_num}, Coil name={comp_name}, stored Coil Name for that index={steam_coil.Name}")
        value[0] = steam_coil.availSched.getCurrentVal()


def GetCoilMaxWaterFlowRate(state, coil_type, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if _same_string(coil_type, "Coil:Heating:Steam"):
        which_coil = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if which_coil >= 0:
            max_water_flow_rate = 0.0
    else:
        which_coil = -1
    
    if which_coil < 0:
        raise RuntimeError(f"GetCoilMaxWaterFlowRate: Could not find CoilType=\"{coil_type}\" with Name=\"{coil_name}\"")
    
    return max_water_flow_rate


def GetCoilMaxSteamFlowRate(state, coil_index):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if coil_index <= 0:
        raise RuntimeError("GetCoilMaxSteamFlowRate: Could not find CoilType = \"Coil:Heating:Steam\"")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].MaxSteamVolFlowRate


def GetCoilAirInletNode(state, coil_index, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if coil_index <= 0:
        raise RuntimeError(f"GetCoilAirInletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].AirInletNodeNum


def GetCoilAirOutletNode(state, coil_index, coil_name=None):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if isinstance(coil_index, str):
        coil_type = coil_index
        index_num = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if index_num < 0:
            return 0
        return state.dataSteamCoils.SteamCoil[index_num].AirOutletNodeNum
    
    if coil_index <= 0:
        raise RuntimeError(f"GetCoilAirOutletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].AirOutletNodeNum


def GetCoilSteamInletNode(state, coil_index, coil_name=None):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if isinstance(coil_index, str):
        coil_type = coil_index
        index_num = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if index_num < 0:
            raise RuntimeError(f"GetCoilSteamInletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
        return state.dataSteamCoils.SteamCoil[index_num].SteamInletNodeNum
    
    if coil_index <= 0:
        raise RuntimeError(f"GetCoilSteamInletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].SteamInletNodeNum


def GetCoilSteamOutletNode(state, coil_index, coil_name=None):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if isinstance(coil_index, str):
        coil_type = coil_index
        index_num = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if index_num < 0:
            raise RuntimeError(f"GetCoilSteamOutletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
        return state.dataSteamCoils.SteamCoil[index_num].SteamOutletNodeNum
    
    if coil_index <= 0:
        raise RuntimeError(f"GetCoilSteamInletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].SteamOutletNodeNum


def GetCoilCapacity(state, coil_type, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if _same_string(coil_type, "Coil:Heating:Steam"):
        which_coil = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if which_coil >= 0:
            capacity = state.dataSteamCoils.SteamCoil[which_coil].OperatingCapacity
        else:
            which_coil = -1
    else:
        which_coil = -1
    
    if which_coil < 0:
        raise RuntimeError(f"GetCoilSteamInletNode: Could not find CoilType=\"{coil_type}\" with Name=\"{coil_name}\"")
    
    return capacity


def GetTypeOfCoil(state, coil_index, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if coil_index <= 0:
        raise RuntimeError(f"GetCoilSteamInletNode: Could not find CoilType = \"Coil:Heating:Steam\" with Name = {coil_name}")
    
    return state.dataSteamCoils.SteamCoil[coil_index - 1].TypeOfCoil


def GetSteamCoilControlNodeNum(state, coil_type, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    node_number = 0
    if _same_string(coil_type, "Coil:Heating:Steam"):
        which_coil = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if which_coil >= 0:
            node_number = state.dataSteamCoils.SteamCoil[which_coil].TempSetPointNodeNum
    
    if which_coil < 0:
        raise RuntimeError(f"GetSteamCoilControlNodeNum: Could not find Coil, Type=\"{coil_type}\" Name=\"{coil_name}\"")
    
    return node_number


def GetSteamCoilAvailSchedule(state, coil_type, coil_name):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    avail_sch_index = 0
    if _same_string(coil_type, "Coil:Heating:Steam"):
        which_coil = _find_item(coil_name, state.dataSteamCoils.SteamCoil)
        if which_coil >= 0:
            avail_sch_index = state.dataSteamCoils.SteamCoil[which_coil].availSched.Num
    
    if which_coil < 0:
        raise RuntimeError(f"GetCoilAvailScheduleIndex: Could not find Coil, Type=\"{coil_type}\" Name=\"{coil_name}\"")
    
    return avail_sch_index


def SetSteamCoilData(state, coil_num, desiccant_regeneration_coil=None, desiccant_dehum_index=None):
    if state.dataSteamCoils.GetSteamCoilsInputFlag:
        GetSteamCoilInput(state)
        state.dataSteamCoils.GetSteamCoilsInputFlag = False
    
    if coil_num <= 0 or coil_num > state.dataSteamCoils.NumSteamCoils:
        raise RuntimeError(f"SetHeatingCoilData: called with heating coil Number out of range={coil_num} should be >0 and <{state.dataSteamCoils.NumSteamCoils}")
    
    steam_coil = state.dataSteamCoils.SteamCoil[coil_num - 1]
    if desiccant_regeneration_coil is not None:
        steam_coil.DesiccantRegenerationCoil = desiccant_regeneration_coil
    if desiccant_dehum_index is not None:
        steam_coil.DesiccantDehumNum = desiccant_dehum_index


# Helper functions
def _find_item_in_list(name, items):
    for i, item in enumerate(items):
        if item.Name == name:
            return i
    return -1


def _find_item(name, items):
    for i, item in enumerate(items):
        if item.Name == name:
            return i
    return -1


def _same_string(str1, str2):
    return str1.upper() == str2.upper()


def _find_enum_value(enum_list, value):
    for i, item in enumerate(enum_list):
        if item.upper() == value.upper():
            return i
    return -1
