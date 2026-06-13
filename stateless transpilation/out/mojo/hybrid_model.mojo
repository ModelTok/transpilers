# EXTERNAL DEPS (to wire in glue):
# - Sched.Schedule (type from EnergyPlus.ScheduleManager)
# - Sched.GetSchedule(state, schedule_name: StringRef) -> Optional[Pointer[Schedule]]
# - Util.SameString(str1: StringRef, str2: StringRef) -> Bool
# - Util.FindItemInList(item: StringRef, array) -> Int32 (returns 1-indexed position, 0 if not found)
# - state.dataInputProcessing.inputProcessor (object with getNumObjectsFound, getObjectItem methods)
# - state.dataHeatBal.Zone (1-indexed array of zone objects)
# - state.dataHeatBal.ZoneAirMassFlow (object with EnforceZoneMassBalance attribute)
# - state.dataHeatBal.doSpaceHeatBalanceSimulation (Bool)
# - state.dataHeatBal.doSpaceHeatBalanceSizing (Bool)
# - state.dataGlobal.NumOfZones (Int32)
# - state.dataRoomAir.AirModel (1-indexed array)
# - state.dataHybridModel (HybridModelData object)
# - ShowSevereError(state, message: String) -> None
# - ShowWarningError(state, message: String) -> None
# - ShowContinueError(state, message: String) -> None
# - ShowFatalError(state, message: String) -> None
# - SetupOutputVariable(state, name: String, units, variable, time_step_type, store_type, zone_name: String) -> None
# - OutputProcessor.TimeStepType.Zone, OutputProcessor.StoreType.Average (constants)
# - Constant.Units (namespace with ach, kg_s, None members)
# - RoomAir.RoomAirModel.Mixing (constant)

from collections import Optional

struct Schedule:
    pass

struct HybridModelZone:
    var Name: String
    var measuredTempSched: Optional[Pointer[Schedule]]
    var measuredHumRatSched: Optional[Pointer[Schedule]]
    var measuredCO2ConcSched: Optional[Pointer[Schedule]]
    
    var peopleActivityLevelSched: Optional[Pointer[Schedule]]
    var peopleSensibleFracSched: Optional[Pointer[Schedule]]
    var peopleRadiantFracSched: Optional[Pointer[Schedule]]
    var peopleCO2GenRateSched: Optional[Pointer[Schedule]]
    
    var supplyAirTempSched: Optional[Pointer[Schedule]]
    var supplyAirMassFlowRateSched: Optional[Pointer[Schedule]]
    var supplyAirHumRatSched: Optional[Pointer[Schedule]]
    var supplyAirCO2ConcSched: Optional[Pointer[Schedule]]
    
    var InternalThermalMassCalc_T: Bool
    var InfiltrationCalc_T: Bool
    var InfiltrationCalc_H: Bool
    var InfiltrationCalc_C: Bool
    var PeopleCountCalc_T: Bool
    var PeopleCountCalc_H: Bool
    var PeopleCountCalc_C: Bool
    var IncludeSystemSupplyParameters: Bool
    
    var measuredTempStartMonth: Int32
    var measuredTempStartDate: Int32
    var measuredTempEndMonth: Int32
    var measuredTempEndDate: Int32
    var HybridStartDayOfYear: Int32
    var HybridEndDayOfYear: Int32
    
    fn __init__(inout self):
        self.Name = ""
        self.measuredTempSched = None
        self.measuredHumRatSched = None
        self.measuredCO2ConcSched = None
        self.peopleActivityLevelSched = None
        self.peopleSensibleFracSched = None
        self.peopleRadiantFracSched = None
        self.peopleCO2GenRateSched = None
        self.supplyAirTempSched = None
        self.supplyAirMassFlowRateSched = None
        self.supplyAirHumRatSched = None
        self.supplyAirCO2ConcSched = None
        self.InternalThermalMassCalc_T = False
        self.InfiltrationCalc_T = False
        self.InfiltrationCalc_H = False
        self.InfiltrationCalc_C = False
        self.PeopleCountCalc_T = False
        self.PeopleCountCalc_H = False
        self.PeopleCountCalc_C = False
        self.IncludeSystemSupplyParameters = False
        self.measuredTempStartMonth = 0
        self.measuredTempStartDate = 0
        self.measuredTempEndMonth = 0
        self.measuredTempEndDate = 0
        self.HybridStartDayOfYear = 0
        self.HybridEndDayOfYear = 0

struct HybridModelData:
    var FlagHybridModel: Bool
    var FlagHybridModel_TM: Bool
    var FlagHybridModel_AI: Bool
    var FlagHybridModel_PC: Bool
    
    var NumOfHybridModelZones: Int32
    var CurrentModuleObject: String
    
    var hybridModelZones: DynamicVector[HybridModelZone]
    
    fn __init__(inout self):
        self.FlagHybridModel = False
        self.FlagHybridModel_TM = False
        self.FlagHybridModel_AI = False
        self.FlagHybridModel_PC = False
        self.NumOfHybridModelZones = 0
        self.CurrentModuleObject = ""
        self.hybridModelZones = DynamicVector[HybridModelZone]()
    
    fn clear_state(inout self):
        self.FlagHybridModel = False
        self.FlagHybridModel_TM = False
        self.FlagHybridModel_AI = False
        self.FlagHybridModel_PC = False
        self.NumOfHybridModelZones = 0
        self.CurrentModuleObject = ""
        self.hybridModelZones.clear()

fn GetHybridModelZone(inout state: EnergyPlusData):
    var l_alpha_field_blanks = InlineArray[Bool, 16](fill=False)
    var l_numeric_field_blanks = InlineArray[Bool, 4](fill=False)
    var current_module_object = "HybridModel:Zone"
    var c_alpha_args = InlineArray[String, 16](fill="")
    var c_alpha_field_names = InlineArray[String, 16](fill="")
    var c_numeric_field_names = InlineArray[String, 4](fill="")
    var r_numeric_args = InlineArray[Float64, 4](fill=0.0)
    
    state.dataHybridModel.NumOfHybridModelZones = (
        state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, current_module_object)
    )
    
    if state.dataHybridModel.NumOfHybridModelZones > 0:
        state.dataHybridModel.hybridModelZones.reserve(state.dataGlobal.NumOfZones + 1)
        for _ in range(state.dataGlobal.NumOfZones + 1):
            state.dataHybridModel.hybridModelZones.push_back(HybridModelZone())
        
        var errors_found = False
        var num_alphas: Int32 = 0
        var num_numbers: Int32 = 0
        var io_status: Int32 = 0
        
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
            
            var zone_ptr = Util.FindItemInList(c_alpha_args[1], state.dataHeatBal.Zone)
            
            if zone_ptr > 0:
                var hm_zone = Pointer[HybridModelZone](state.dataHybridModel.hybridModelZones[zone_ptr])
                hm_zone[].Name = c_alpha_args[0]
                state.dataHybridModel.FlagHybridModel_TM = Util.SameString(c_alpha_args[2], "Yes")
                state.dataHybridModel.FlagHybridModel_AI = Util.SameString(c_alpha_args[3], "Yes")
                state.dataHybridModel.FlagHybridModel_PC = Util.SameString(c_alpha_args[4], "Yes")
                
                var temperature_sched = Sched.GetSchedule(state, c_alpha_args[5])
                var humidity_ratio_sched = Sched.GetSchedule(state, c_alpha_args[6])
                var co2_concentration_sched = Sched.GetSchedule(state, c_alpha_args[7])
                
                var people_activity_level_sched = Sched.GetSchedule(state, c_alpha_args[8])
                var people_sensible_fraction_sched = Sched.GetSchedule(state, c_alpha_args[9])
                var people_radiant_fraction_sched = Sched.GetSchedule(state, c_alpha_args[10])
                var people_co2_gen_rate_sched = Sched.GetSchedule(state, c_alpha_args[11])
                
                var supply_air_temperature_sched = Sched.GetSchedule(state, c_alpha_args[12])
                var supply_air_mass_flow_rate_sched = Sched.GetSchedule(state, c_alpha_args[13])
                var supply_air_humidity_ratio_sched = Sched.GetSchedule(state, c_alpha_args[14])
                var supply_air_co2_concentration_sched = Sched.GetSchedule(state, c_alpha_args[15])
                
                hm_zone[].InternalThermalMassCalc_T = False
                hm_zone[].InfiltrationCalc_T = False
                hm_zone[].InfiltrationCalc_H = False
                hm_zone[].InfiltrationCalc_C = False
                hm_zone[].PeopleCountCalc_T = False
                hm_zone[].PeopleCountCalc_H = False
                hm_zone[].PeopleCountCalc_C = False
                
                if state.dataHybridModel.FlagHybridModel_TM:
                    if state.dataHybridModel.FlagHybridModel_AI:
                        ShowSevereError(
                            state,
                            String.format_string(
                                'Field "{}" and "{}" cannot be both set to YES.',
                                c_alpha_field_names[2],
                                c_alpha_field_names[3],
                            ),
                        )
                        errors_found = True
                    
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(
                            state,
                            String.format_string(
                                'Field "{}" and "{}" cannot be both set to YES.',
                                c_alpha_field_names[2],
                                c_alpha_field_names[4],
                            ),
                        )
                        errors_found = True
                    
                    if temperature_sched.__bool__() == False:
                        ShowSevereError(
                            state,
                            String.format_string(
                                "Measured Zone Air Temperature Schedule is not defined for: {}",
                                current_module_object,
                            ),
                        )
                        errors_found = True
                    else:
                        hm_zone[].InternalThermalMassCalc_T = True
                
                if state.dataHybridModel.FlagHybridModel_AI:
                    if state.dataHybridModel.FlagHybridModel_PC:
                        ShowSevereError(
                            state,
                            String.format_string(
                                'Field "{}" and "{}" cannot be both set to YES.',
                                c_alpha_field_names[3],
                                c_alpha_field_names[4],
                            ),
                        )
                        errors_found = True
                    
                    if (
                        temperature_sched.__bool__() == False
                        and humidity_ratio_sched.__bool__() == False
                        and co2_concentration_sched.__bool__() == False
                    ):
                        ShowSevereError(
                            state,
                            String.format_string(
                                "No measured environmental parameter is provided for: {}",
                                current_module_object,
                            ),
                        )
                        ShowContinueError(
                            state,
                            String.format_string(
                                'One of the field "{}", "{}", or "{}" must be provided for the HybridModel:Zone.',
                                c_alpha_field_names[5],
                                c_alpha_field_names[6],
                                c_alpha_field_names[7],
                            ),
                        )
                        errors_found = True
                    else:
                        if (
                            temperature_sched.__bool__() == True
                            and state.dataHybridModel.FlagHybridModel_TM == False
                        ):
                            hm_zone[].InfiltrationCalc_T = True
                            if humidity_ratio_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    String.format_string(
                                        'Field "{}" is provided.',
                                        c_alpha_field_names[5],
                                    ),
                                )
                                ShowContinueError(
                                    state,
                                    String.format_string(
                                        'Field "{}" will not be used.',
                                        c_alpha_field_names[6],
                                    ),
                                )
                            if co2_concentration_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    String.format_string(
                                        'Field "{}" is provided.',
                                        c_alpha_field_names[5],
                                    ),
                                )
                                ShowContinueError(
                                    state,
                                    String.format_string(
                                        'Field "{}" will not be used.',
                                        c_alpha_field_names[7],
                                    ),
                                )
                        
                        if (
                            humidity_ratio_sched.__bool__() == True
                            and temperature_sched.__bool__() == False
                        ):
                            hm_zone[].InfiltrationCalc_H = True
                            if co2_concentration_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    String.format_string(
                                        'Field "{}" is provided.',
                                        c_alpha_field_names[6],
                                    ),
                                )
                                ShowContinueError(
                                    state,
                                    String.format_string(
                                        'Field "{}" will not be used.',
                                        c_alpha_field_names[7],
                                    ),
                                )
                        
                        if (
                            co2_concentration_sched.__bool__() == True
                            and temperature_sched.__bool__() == False
                            and humidity_ratio_sched.__bool__() == False
                        ):
                            hm_zone[].InfiltrationCalc_C = True
                
                if state.dataHybridModel.FlagHybridModel_PC:
                    if (
                        temperature_sched.__bool__() == False
                        and humidity_ratio_sched.__bool__() == False
                        and co2_concentration_sched.__bool__() == False
                    ):
                        ShowSevereError(
                            state,
                            String.format_string(
                                "No measured environmental parameter is provided for: {}",
                                current_module_object,
                            ),
                        )
                        ShowContinueError(
                            state,
                            String.format_string(
                                'One of the field "{}", "{}", or "{}" must be provided for the HybridModel:Zone.',
                                c_alpha_field_names[5],
                                c_alpha_field_names[6],
                                c_alpha_field_names[7],
                            ),
                        )
                        errors_found = True
                    else:
                        if (
                            temperature_sched.__bool__() == True
                            and state.dataHybridModel.FlagHybridModel_TM == False
                        ):
                            hm_zone[].PeopleCountCalc_T = True
                            if humidity_ratio_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    "The measured air humidity ratio schedule will not be used since measured air temperature is provided.",
                                )
                            if co2_concentration_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    "The measured air CO2 concentration schedule will not be used since measured air temperature is provided.",
                                )
                        
                        if (
                            humidity_ratio_sched.__bool__() == True
                            and temperature_sched.__bool__() == False
                        ):
                            hm_zone[].PeopleCountCalc_H = True
                            if co2_concentration_sched.__bool__() == True:
                                ShowWarningError(
                                    state,
                                    "The measured air CO2 concentration schedule will not be used since measured air humidity ratio is provided.",
                                )
                        
                        if (
                            co2_concentration_sched.__bool__() == True
                            and temperature_sched.__bool__() == False
                            and humidity_ratio_sched.__bool__() == False
                        ):
                            hm_zone[].PeopleCountCalc_C = True
                
                if (
                    supply_air_temperature_sched.__bool__() == True
                    and supply_air_mass_flow_rate_sched.__bool__() == True
                    and supply_air_humidity_ratio_sched.__bool__() == True
                ):
                    if hm_zone[].InfiltrationCalc_T or hm_zone[].PeopleCountCalc_T:
                        hm_zone[].IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}", {}, and "{}" will not be used in the inverse balance equation.',
                                c_alpha_field_names[12],
                                c_alpha_field_names[13],
                                c_alpha_field_names[14],
                            ),
                        )
                
                if (
                    supply_air_humidity_ratio_sched.__bool__() == True
                    and supply_air_mass_flow_rate_sched.__bool__() == True
                ):
                    if hm_zone[].InfiltrationCalc_H or hm_zone[].PeopleCountCalc_H:
                        hm_zone[].IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}" and "{}" will not be used in the inverse balance equation.',
                                c_alpha_field_names[14],
                                c_alpha_field_names[13],
                            ),
                        )
                
                if (
                    supply_air_co2_concentration_sched.__bool__() == True
                    and supply_air_mass_flow_rate_sched.__bool__() == True
                ):
                    if hm_zone[].InfiltrationCalc_C or hm_zone[].PeopleCountCalc_C:
                        hm_zone[].IncludeSystemSupplyParameters = True
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}" and "{}" will not be used in the inverse balance equation.',
                                c_alpha_field_names[15],
                                c_alpha_field_names[13],
                            ),
                        )
                
                state.dataHybridModel.FlagHybridModel = (
                    hm_zone[].InternalThermalMassCalc_T
                    or hm_zone[].InfiltrationCalc_T
                    or hm_zone[].InfiltrationCalc_H
                    or hm_zone[].InfiltrationCalc_C
                    or hm_zone[].PeopleCountCalc_T
                    or hm_zone[].PeopleCountCalc_H
                    or hm_zone[].PeopleCountCalc_C
                )
                
                if (
                    hm_zone[].InternalThermalMassCalc_T
                    or hm_zone[].InfiltrationCalc_T
                    or hm_zone[].PeopleCountCalc_T
                ):
                    hm_zone[].measuredTempSched = temperature_sched
                
                if hm_zone[].InfiltrationCalc_H or hm_zone[].PeopleCountCalc_H:
                    hm_zone[].measuredHumRatSched = humidity_ratio_sched
                
                if hm_zone[].InfiltrationCalc_C or hm_zone[].PeopleCountCalc_C:
                    hm_zone[].measuredCO2ConcSched = co2_concentration_sched
                
                if hm_zone[].IncludeSystemSupplyParameters:
                    hm_zone[].supplyAirTempSched = supply_air_temperature_sched
                    hm_zone[].supplyAirMassFlowRateSched = supply_air_mass_flow_rate_sched
                    hm_zone[].supplyAirHumRatSched = supply_air_humidity_ratio_sched
                    hm_zone[].supplyAirCO2ConcSched = supply_air_co2_concentration_sched
                
                if (
                    hm_zone[].PeopleCountCalc_T
                    or hm_zone[].PeopleCountCalc_H
                    or hm_zone[].PeopleCountCalc_C
                ):
                    if people_activity_level_sched.__bool__() == True:
                        hm_zone[].peopleActivityLevelSched = people_activity_level_sched
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}": default people activity level is not provided, default value of 130W/person will be used.',
                                c_alpha_field_names[8],
                            ),
                        )
                    
                    if people_sensible_fraction_sched.__bool__() == True:
                        hm_zone[].peopleSensibleFracSched = people_sensible_fraction_sched
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}": default people sensible heat rate is not provided, default value of 0.6 will be used.',
                                c_alpha_field_names[9],
                            ),
                        )
                    
                    if people_radiant_fraction_sched.__bool__() == True:
                        hm_zone[].peopleRadiantFracSched = people_radiant_fraction_sched
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}": default people radiant heat portion (of sensible heat) is not provided, default value of 0.7 will be used.',
                                c_alpha_field_names[10],
                            ),
                        )
                    
                    if people_co2_gen_rate_sched.__bool__() == True:
                        hm_zone[].peopleCO2GenRateSched = people_co2_gen_rate_sched
                    else:
                        ShowWarningError(
                            state,
                            String.format_string(
                                'Field "{}": default people CO2 generation rate is not provided, default value of 0.0000000382 kg/W will be used.',
                                c_alpha_field_names[11],
                            ),
                        )
                
                if state.dataHybridModel.FlagHybridModel:
                    hm_zone[].measuredTempStartMonth = Int32(r_numeric_args[0])
                    hm_zone[].measuredTempStartDate = Int32(r_numeric_args[1])
                    hm_zone[].measuredTempEndMonth = Int32(r_numeric_args[2])
                    hm_zone[].measuredTempEndDate = Int32(r_numeric_args[3])
                    
                    var HM_DAY_ARR = InlineArray[Int32, 12](0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
                    
                    var hybrid_model_start_month = hm_zone[].measuredTempStartMonth
                    var hybrid_model_start_date = hm_zone[].measuredTempStartDate
                    var hybrid_model_end_month = hm_zone[].measuredTempEndMonth
                    var hybrid_model_end_date = hm_zone[].measuredTempEndDate
                    
                    var hm_start_day: Int32 = 0
                    var hm_end_day: Int32 = 0
                    
                    if hybrid_model_start_month >= 1 and hybrid_model_start_month <= 12:
                        hm_start_day = HM_DAY_ARR[Int(hybrid_model_start_month - 1)]
                    
                    if hybrid_model_end_month >= 1 and hybrid_model_end_month <= 12:
                        hm_end_day = HM_DAY_ARR[Int(hybrid_model_end_month - 1)]
                    
                    hm_zone[].HybridStartDayOfYear = hm_start_day + hybrid_model_start_date
                    hm_zone[].HybridEndDayOfYear = hm_end_day + hybrid_model_end_date
                
                if (
                    hm_zone[].InfiltrationCalc_T
                    or hm_zone[].InfiltrationCalc_H
                    or hm_zone[].InfiltrationCalc_C
                ):
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
                
                if (
                    hm_zone[].PeopleCountCalc_T
                    or hm_zone[].PeopleCountCalc_H
                    or hm_zone[].PeopleCountCalc_C
                ):
                    SetupOutputVariable(
                        state,
                        "Zone Hybrid Model People Count",
                        Constant.Units.None,
                        state.dataHeatBal.Zone[zone_ptr].NumOccHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                
                if hm_zone[].InternalThermalMassCalc_T:
                    SetupOutputVariable(
                        state,
                        "Zone Hybrid Model Thermal Mass Multiplier",
                        Constant.Units.None,
                        state.dataHeatBal.Zone[zone_ptr].ZoneVolCapMultpSensHM,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        state.dataHeatBal.Zone[zone_ptr].Name,
                    )
                
                if (
                    hm_zone[].InfiltrationCalc_T
                    and state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance
                ):
                    state.dataHeatBal.ZoneAirMassFlow.EnforceZoneMassBalance = False
                    ShowWarningError(
                        state,
                        "ZoneAirMassFlowConservation is deactivated when Hybrid Modeling is performed.",
                    )
            else:
                ShowSevereError(
                    state,
                    String.format_string(
                        'HybridModel:Zone="{}" invalid {}="{}" not found.',
                        c_alpha_args[0],
                        c_alpha_field_names[1],
                        c_alpha_args[1],
                    ),
                )
                errors_found = True
        
        if state.dataHybridModel.FlagHybridModel:
            for zone_ptr in range(1, state.dataGlobal.NumOfZones + 1):
                var hm_zone = Pointer[HybridModelZone](state.dataHybridModel.hybridModelZones[zone_ptr])
                if (hm_zone[].InternalThermalMassCalc_T or hm_zone[].InfiltrationCalc_T) and (
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
            ShowFatalError(
                state,
                "Errors getting Hybrid Model input data. Preceding condition(s) cause termination.",
            )
