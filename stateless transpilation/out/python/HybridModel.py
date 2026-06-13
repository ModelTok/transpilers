# EXTERNAL DEPS (to wire in glue):
# - Sched.Schedule (type from EnergyPlus.ScheduleManager)
# - Sched.GetSchedule(state, schedule_name: str) -> Schedule | None
# - Util.SameString(str1: str, str2: str) -> bool
# - Util.FindItemInList(item: str, array) -> int (returns 1-indexed position, 0 if not found)
# - state.dataInputProcessing.inputProcessor (object with getNumObjectsFound, getObjectItem methods)
# - state.dataHeatBal.Zone (1-indexed array of zone objects)
# - state.dataHeatBal.ZoneAirMassFlow (object with EnforceZoneMassBalance attribute)
# - state.dataHeatBal.doSpaceHeatBalanceSimulation (bool)
# - state.dataHeatBal.doSpaceHeatBalanceSizing (bool)
# - state.dataGlobal.NumOfZones (int)
# - state.dataRoomAir.AirModel (1-indexed array)
# - state.dataHybridModel (HybridModelData object)
# - ShowSevereError(state, message: str) -> None
# - ShowWarningError(state, message: str) -> None
# - ShowContinueError(state, message: str) -> None
# - ShowFatalError(state, message: str) -> None
# - SetupOutputVariable(state, name: str, units, variable, time_step_type, store_type, zone_name: str) -> None
# - OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average (constants)
# - Constant.Units (namespace with ach, kg_s, None members)
# - RoomAir.RoomAirModel.Mixing (constant)

from typing import Optional, List, Any
from dataclasses import dataclass, field

class Schedule:
    pass

@dataclass
class HybridModelZone:
    Name: str = ""
    measuredTempSched: Optional[Schedule] = None
    measuredHumRatSched: Optional[Schedule] = None
    measuredCO2ConcSched: Optional[Schedule] = None
    
    peopleActivityLevelSched: Optional[Schedule] = None
    peopleSensibleFracSched: Optional[Schedule] = None
    peopleRadiantFracSched: Optional[Schedule] = None
    peopleCO2GenRateSched: Optional[Schedule] = None
    
    supplyAirTempSched: Optional[Schedule] = None
    supplyAirMassFlowRateSched: Optional[Schedule] = None
    supplyAirHumRatSched: Optional[Schedule] = None
    supplyAirCO2ConcSched: Optional[Schedule] = None
    
    InternalThermalMassCalc_T: bool = False
    InfiltrationCalc_T: bool = False
    InfiltrationCalc_H: bool = False
    InfiltrationCalc_C: bool = False
    PeopleCountCalc_T: bool = False
    PeopleCountCalc_H: bool = False
    PeopleCountCalc_C: bool = False
    IncludeSystemSupplyParameters: bool = False
    
    measuredTempStartMonth: int = 0
    measuredTempStartDate: int = 0
    measuredTempEndMonth: int = 0
    measuredTempEndDate: int = 0
    HybridStartDayOfYear: int = 0
    HybridEndDayOfYear: int = 0

@dataclass
class HybridModelData:
    FlagHybridModel: bool = False
    FlagHybridModel_TM: bool = False
    FlagHybridModel_AI: bool = False
    FlagHybridModel_PC: bool = False
    
    NumOfHybridModelZones: int = 0
    CurrentModuleObject: str = ""
    
    hybridModelZones: List[HybridModelZone] = field(default_factory=list)
    
    def clear_state(self) -> None:
        self.FlagHybridModel = False
        self.FlagHybridModel_TM = False
        self.FlagHybridModel_AI = False
        self.FlagHybridModel_PC = False
        self.NumOfHybridModelZones = 0
        self.CurrentModuleObject = ""
        self.hybridModelZones.clear()

def GetHybridModelZone(state: Any) -> None:
    l_alpha_field_blanks = [False] * 16
    l_numeric_field_blanks = [False] * 4
    current_module_object = "HybridModel:Zone"
    c_alpha_args = [""] * 16
    c_alpha_field_names = [""] * 16
    c_numeric_field_names = [""] * 4
    r_numeric_args = [0.0] * 4
    
    state.dataHybridModel.NumOfHybridModelZones = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    )
    
    if state.dataHybridModel.NumOfHybridModelZones > 0:
        state.dataHybridModel.hybridModelZones = [
            HybridModelZone() for _ in range(state.dataGlobal.NumOfZones + 1)
        ]
        errors_found = False
        num_alphas = 0
        num_numbers = 0
        io_status = 0
        
        for hybrid_model_num in range(1, state.dataHybridModel.NumOfHybridModelZones + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                current_module_object,
                hybrid_model_num,
                c_alpha_args,
                num_alphas,
                r_numeric_args,
                num_numbers,
                io_status,
                l_numeric_field_blanks,
                l_alpha_field_blanks,
                c_alpha_field_names,
                c_numeric_field_names,
            )
            
            zone_ptr = Util.FindItemInList(c_alpha_args[1], state.dataHeatBal.Zone)
            
            if zone_ptr > 0:
                hm_zone = state.dataHybridModel.hybridModelZones[zone_ptr]
                hm_zone.Name = c_alpha_args[0]
                state.dataHybridModel.FlagHybridModel_TM = Util.SameString(c_alpha_args[2], "Yes")
                state.dataHybridModel.FlagHybridModel_AI = Util.SameString(c_alpha_args[3], "Yes")
                state.dataHybridModel.FlagHybridModel_PC = Util.SameString(c_alpha_args[4], "Yes")
                
                temperature_sched = Sched.GetSchedule(state, c_alpha_args[5])
                humidity_ratio_sched = Sched.GetSchedule(state, c_alpha_args[6])
                co2_concentration_sched = Sched.GetSchedule(state, c_alpha_args[7])
                
                people_activity_level_sched = Sched.GetSchedule(state, c_alpha_args[8])
                people_sensible_fraction_sched = Sched.GetSchedule(state, c_alpha_args[9])
                people_radiant_fraction_sched = Sched.GetSchedule(state, c_alpha_args[10])
                people_co2_gen_rate_sched = Sched.GetSchedule(state, c_alpha_args[11])
                
                supply_air_temperature_sched = Sched.GetSchedule(state, c_alpha_args[12])
                supply_air_mass_flow_rate_sched = Sched.GetSchedule(state, c_alpha_args[13])
                supply_air_humidity_ratio_sched = Sched.GetSchedule(state, c_alpha_args[14])
                supply_air_co2_concentration_sched = Sched.GetSchedule(state, c_alpha_args[15])
                
                hm_zone.InternalThermalMassCalc_T = False
                hm_zone.InfiltrationCalc_T = False
                hm_zone.InfiltrationCalc_H = False
                hm_zone.InfiltrationCalc_C = False
                hm_zone.PeopleCountCalc_T = False
                hm_zone.PeopleCountCalc_H = False
                hm_zone.PeopleCountCalc_C = False
                
                if state.dataHybridModel.FlagHybridModel_TM:
                    if state.dataHybridModel.FlagHybridModel_AI:
                        ShowSevereError(
                            state,
                            f'Field "{c_alpha_field_names[2]}" and "{c_alpha_field_names[3]}" cannot be both set to YES.',
                        )
                        errors_found = True
                    
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(
                            state,
                            f'Field "{c_alpha_field_names[2]}" and "{c_alpha_field_names[4]}" cannot be both set to YES.',
                        )
                        errors_found = True
                    
                    if temperature_sched is None:
                        ShowSevereError(
                            state,
                            f"Measured Zone Air Temperature Schedule is not defined for: {current_module_object}",
                        )
                        errors_found = True
                    else:
                        hm_zone.InternalThermalMassCalc_T = True
                
                if state.dataHybridModel.FlagHybridModel_AI:
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(
                            state,
                            f'Field "{c_alpha_field_names[3]}" and "{c_alpha_field_names[4]}" cannot be both set to YES.',
                        )
                        errors_found = True
                    
                    if temperature_sched is None and humidity_ratio_sched is None and co2_concentration_sched is None:
                        ShowSevereError(
                            state,
                            f"No measured environmental parameter is provided for: {current_module_object}",
                        )
                        ShowContinueError(
                            state,
                            f'One of the field "{c_alpha_field_names[5]}", "{c_alpha_field_names[6]}", or "{c_alpha_field_names[7]}" must be provided for the HybridModel:Zone.',
                        )
                        errors_found = True
                    else:
                        if temperature_sched is not None and not state.dataHybridModel.FlagHybridModel_TM:
                            hm_zone.InfiltrationCalc_T = True
                            if humidity_ratio_sched is not None:
                                ShowWarningError(
                                    state,
                                    f'Field "{c_alpha_field_names[5]}" is provided.',
                                )
                                ShowContinueError(
                                    state,
                                    f'Field "{c_alpha_field_names[6]}" will not be used.',
                                )
                            if co2_concentration_sched is not None:
                                ShowWarningError(
                                    state,
                                    f'Field "{c_alpha_field_names[5]}" is provided.',
                                )
                                ShowContinueError(
                                    state,
                                    f'Field "{c_alpha_field_names[7]}" will not be used.',
                                )
                        
                        if humidity_ratio_sched is not None and temperature_sched is None:
                            hm_zone.InfiltrationCalc_H = True
                            if co2_concentration_sched is not None:
                                ShowWarningError(
                                    state,
                                    f'Field "{c_alpha_field_names[6]}" is provided.',
                                )
                                ShowContinueError(
                                    state,
                                    f'Field "{c_alpha_field_names[7]}" will not be used.',
                                )
                        
                        if (
                            co2_concentration_sched is not None
                            and temperature_sched is None
                            and humidity_ratio_sched is None
                        ):
                            hm_zone.InfiltrationCalc_C = True
                
                if state.dataHybridModel.FlagHybridModel_PC:
                    if temperature_sched is None and humidity_ratio_sched is None and co2_concentration_sched is None:
                        ShowSevereError(
                            state,
                            f"No measured environmental parameter is provided for: {current_module_object}",
                        )
                        ShowContinueError(
                            state,
                            f'One of the field "{c_alpha_field_names[5]}", "{c_alpha_field_names[6]}", or "{c_alpha_field_names[7]}" must be provided for the HybridModel:Zone.',
                        )
                        errors_found = True
                    else:
                        if temperature_sched is not None and not state.dataHybridModel.FlagHybridModel_TM:
                            hm_zone.PeopleCountCalc_T = True
                            if humidity_ratio_sched is not None:
                                ShowWarningError(
                                    state,
                                    "The measured air humidity ratio schedule will not be used since measured air temperature is provided.",
                                )
                            if co2_concentration_sched is not None:
                                ShowWarningError(
                                    state,
                                    "The measured air CO2 concentration schedule will not be used since measured air temperature is provided.",
                                )
                        
                        if humidity_ratio_sched is not None and temperature_sched is None:
                            hm_zone.PeopleCountCalc_H = True
                            if co2_concentration_sched is not None:
                                ShowWarningError(
                                    state,
                                    "The measured air CO2 concentration schedule will not be used since measured air humidity ratio is provided.",
                                )
                        
                        if (
                            co2_concentration_sched is not None
                            and temperature_sched is None
                            and humidity_ratio_sched is None
                        ):
                            hm_zone.PeopleCountCalc_C = True
                
                if (
                    supply_air_temperature_sched is not None
                    and supply_air_mass_flow_rate_sched is not None
                    and supply_air_humidity_ratio_sched is not None
                ):
                    if hm_zone.InfiltrationCalc_T or hm_zone.PeopleCountCalc_T:
                        hm_zone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[12]}", "{c_alpha_field_names[13]}", and "{c_alpha_field_names[14]}" will not be used in the inverse balance equation.',
                        )
                
                if supply_air_humidity_ratio_sched is not None and supply_air_mass_flow_rate_sched is not None:
                    if hm_zone.InfiltrationCalc_H or hm_zone.PeopleCountCalc_H:
                        hm_zone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[14]}" and "{c_alpha_field_names[13]}" will not be used in the inverse balance equation.',
                        )
                
                if supply_air_co2_concentration_sched is not None and supply_air_mass_flow_rate_sched is not None:
                    if hm_zone.InfiltrationCalc_C or hm_zone.PeopleCountCalc_C:
                        hm_zone.IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[15]}" and "{c_alpha_field_names[13]}" will not be used in the inverse balance equation.',
                        )
                
                state.dataHybridModel.FlagHybridModel = (
                    hm_zone.InternalThermalMassCalc_T
                    or hm_zone.InfiltrationCalc_T
                    or hm_zone.InfiltrationCalc_H
                    or hm_zone.InfiltrationCalc_C
                    or hm_zone.PeopleCountCalc_T
                    or hm_zone.PeopleCountCalc_H
                    or hm_zone.PeopleCountCalc_C
                )
                
                if hm_zone.InternalThermalMassCalc_T or hm_zone.InfiltrationCalc_T or hm_zone.PeopleCountCalc_T:
                    hm_zone.measuredTempSched = temperature_sched
                
                if hm_zone.InfiltrationCalc_H or hm_zone.PeopleCountCalc_H:
                    hm_zone.measuredHumRatSched = humidity_ratio_sched
                
                if hm_zone.InfiltrationCalc_C or hm_zone.PeopleCountCalc_C:
                    hm_zone.measuredCO2ConcSched = co2_concentration_sched
                
                if hm_zone.IncludeSystemSupplyParameters:
                    hm_zone.supplyAirTempSched = supply_air_temperature_sched
                    hm_zone.supplyAirMassFlowRateSched = supply_air_mass_flow_rate_sched
                    hm_zone.supplyAirHumRatSched = supply_air_humidity_ratio_sched
                    hm_zone.supplyAirCO2ConcSched = supply_air_co2_concentration_sched
                
                if hm_zone.PeopleCountCalc_T or hm_zone.PeopleCountCalc_H or hm_zone.PeopleCountCalc_C:
                    if people_activity_level_sched is not None:
                        hm_zone.peopleActivityLevelSched = people_activity_level_sched
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[8]}": default people activity level is not provided, default value of 130W/person will be used.',
                        )
                    
                    if people_sensible_fraction_sched is not None:
                        hm_zone.peopleSensibleFracSched = people_sensible_fraction_sched
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[9]}": default people sensible heat rate is not provided, default value of 0.6 will be used.',
                        )
                    
                    if people_radiant_fraction_sched is not None:
                        hm_zone.peopleRadiantFracSched = people_radiant_fraction_sched
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[10]}": default people radiant heat portion (of sensible heat) is not provided, default value of 0.7 will be used.',
                        )
                    
                    if people_co2_gen_rate_sched is not None:
                        hm_zone.peopleCO2GenRateSched = people_co2_gen_rate_sched
                    else:
                        ShowWarningError(
                            state,
                            f'Field "{c_alpha_field_names[11]}": default people CO2 generation rate is not provided, default value of 0.0000000382 kg/W will be used.',
                        )
                
                if state.dataHybridModel.FlagHybridModel:
                    hm_zone.measuredTempStartMonth = int(r_numeric_args[0])
                    hm_zone.measuredTempStartDate = int(r_numeric_args[1])
                    hm_zone.measuredTempEndMonth = int(r_numeric_args[2])
                    hm_zone.measuredTempEndDate = int(r_numeric_args[3])
                    
                    HM_DAY_ARR = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
                    
                    hybrid_model_start_month = hm_zone.measuredTempStartMonth
                    hybrid_model_start_date = hm_zone.measuredTempStartDate
                    hybrid_model_end_month = hm_zone.measuredTempEndMonth
                    hybrid_model_end_date = hm_zone.measuredTempEndDate
                    
                    hm_start_day = 0
                    hm_end_day = 0
                    
                    if 1 <= hybrid_model_start_month <= 12:
                        hm_start_day = HM_DAY_ARR[hybrid_model_start_month - 1]
                    
                    if 1 <= hybrid_model_end_month <= 12:
                        hm_end_day = HM_DAY_ARR[hybrid_model_end_month - 1]
                    
                    hm_zone.HybridStartDayOfYear = hm_start_day + hybrid_model_start_date
                    hm_zone.HybridEndDayOfYear = hm_end_day + hybrid_model_end_date
                
                if hm_zone.InfiltrationCalc_T or hm_zone.InfiltrationCalc_H or hm_zone.InfiltrationCalc_C:
                    SetupOutputVariable(
                        state,
                        "Zone Infiltration Hybrid Model Air Change Rate",
                        Constant.Units.ach,
                        state.dataHeatBal.Zone[zone_ptr].InfilOAAirChangeRateHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                    SetupOutputVariable(
                        state,
                        "Zone Infiltration Hybrid Model Mass Flow Rate",
                        Constant.Units.kg_s,
                        state.dataHeatBal.Zone[zone_ptr].MCPIHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                
                if hm_zone.PeopleCountCalc_T or hm_zone.PeopleCountCalc_H or hm_zone.PeopleCountCalc_C:
                    SetupOutputVariable(
                        state,
                        "Zone Hybrid Model People Count",
                        Constant.Units.None,
                        state.dataHeatBal.Zone[zone_ptr].NumOccHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                
                if hm_zone.InternalThermalMassCalc_T:
                    SetupOutputVariable(
                        state,
                        "Zone Hybrid Model Thermal Mass Multiplier",
                        Constant.Units.None,
                        state.dataHeatBal.Zone[zone_ptr].ZoneVolCapMultpSensHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                
                if hm_zone.InfiltrationCalc_T and state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance:
                    state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = False
                    ShowWarningError(state, "ZoneAirMassFlowConservation is deactivated when Hybrid Modeling is performed.")
            else:
                ShowSevereError(
                    state,
                    f'HybridModel:Zone="{c_alpha_args[0]}" invalid {c_alpha_field_names[1]}="{c_alpha_args[1]}" not found.',
                )
                errors_found = True
        
        if state.dataHybridModel.FlagHybridModel:
            for zone_ptr in range(1, state.dataGlobal.NumOfZones + 1):
                hm_zone = state.dataHybridModel.hybridModelZones[zone_ptr]
                if (hm_zone.InternalThermalMassCalc_T or hm_zone.InfiltrationCalc_T) and (
                    state.dataRoomAir.AirModel[zone_ptr].AirModel != RoomAir.RoomAirModel.Mixing
                ):
                    state.dataRoomAir.AirModel[zone_ptr].AirModel = RoomAir.RoomAirModel.Mixing
                    ShowWarningError(
                        state,
                        "Room Air Model Type should be Mixing if Hybrid Modeling is performed for the zone.",
                    )
            
            if state.dataHeatBal.doSpaceHeatBalanceSimulation or state.dataHeatBal.doSpaceHeatBalanceSizing:
                ShowSevereError(
                    state,
                    "Hybrid Modeling is not supported with ZoneAirHeatBalanceAlgorithm Space Heat Balance.",
                )
                errors_found = True
        
        if errors_found:
            ShowFatalError(state, "Errors getting Hybrid Model input data. Preceding condition(s) cause termination.")
