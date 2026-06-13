from collections import Dict, List
from memory import Pointers


struct ElecBaseboardParams:
    var EquipName: String
    var EquipType: Int
    var Schedule: String
    var SurfaceName: List[String]
    var SurfacePtr: List[Int]
    var ZonePtr: Int
    var availSched: Pointers[NoneType]
    var TotSurfToDistrib: Int
    var NominalCapacity: Float64
    var BaseboardEfficiency: Float64
    var AirInletTemp: Float64
    var AirInletHumRat: Float64
    var AirOutletTemp: Float64
    var ElecUseLoad: Float64
    var ElecUseRate: Float64
    var FracRadiant: Float64
    var FracConvect: Float64
    var FracDistribPerson: Float64
    var TotPower: Float64
    var Power: Float64
    var ConvPower: Float64
    var RadPower: Float64
    var TotEnergy: Float64
    var Energy: Float64
    var ConvEnergy: Float64
    var RadEnergy: Float64
    var FracDistribToSurf: List[Float64]
    var HeatingCapMethod: Int
    var ScaledHeatingCapacity: Float64
    var MySizeFlag: Bool
    var MyEnvrnFlag: Bool
    var CheckEquipName: Bool
    var ZeroBBSourceSumHATsurf: Float64
    var QBBElecRadSource: Float64
    var QBBElecRadSrcAvg: Float64
    var LastSysTimeElapsed: Float64
    var LastTimeStepSys: Float64
    var LastQBBElecRadSrc: Float64

    fn __init__(inout self):
        self.EquipName = ""
        self.EquipType = 0
        self.Schedule = ""
        self.SurfaceName = List[String]()
        self.SurfacePtr = List[Int]()
        self.ZonePtr = 0
        self.availSched = Pointers[NoneType](0)
        self.TotSurfToDistrib = 0
        self.NominalCapacity = 0.0
        self.BaseboardEfficiency = 0.0
        self.AirInletTemp = 0.0
        self.AirInletHumRat = 0.0
        self.AirOutletTemp = 0.0
        self.ElecUseLoad = 0.0
        self.ElecUseRate = 0.0
        self.FracRadiant = 0.0
        self.FracConvect = 0.0
        self.FracDistribPerson = 0.0
        self.TotPower = 0.0
        self.Power = 0.0
        self.ConvPower = 0.0
        self.RadPower = 0.0
        self.TotEnergy = 0.0
        self.Energy = 0.0
        self.ConvEnergy = 0.0
        self.RadEnergy = 0.0
        self.FracDistribToSurf = List[Float64]()
        self.HeatingCapMethod = 0
        self.ScaledHeatingCapacity = 0.0
        self.MySizeFlag = True
        self.MyEnvrnFlag = True
        self.CheckEquipName = True
        self.ZeroBBSourceSumHATsurf = 0.0
        self.QBBElecRadSource = 0.0
        self.QBBElecRadSrcAvg = 0.0
        self.LastSysTimeElapsed = 0.0
        self.LastTimeStepSys = 0.0
        self.LastQBBElecRadSrc = 0.0


struct ElecBaseboardNumericFieldData:
    var FieldNames: List[String]

    fn __init__(inout self):
        self.FieldNames = List[String]()


fn SimElecBaseboard(state: Pointers[NoneType], EquipName: String, ControlledZoneNum: Int, FirstHVACIteration: Bool, inout PowerMet: Float64, inout CompIndex: Int):
    var NumElecBaseboards: Int = __get_state_data(state, "NumElecBaseboards")

    if __get_state_flag(state, "GetInputFlag"):
        GetElectricBaseboardInput(state)
        __set_state_flag(state, "GetInputFlag", False)

    var BaseboardNum: Int = 0
    if CompIndex == 0:
        BaseboardNum = __find_item_in_list(state, EquipName, "EquipName")
        if BaseboardNum == 0:
            __show_fatal_error(state, "SimElectricBaseboard: Unit not found=" + EquipName)
        CompIndex = BaseboardNum
    else:
        BaseboardNum = CompIndex
        if BaseboardNum > NumElecBaseboards or BaseboardNum < 1:
            __show_fatal_error(state, "SimElectricBaseboard:  Invalid CompIndex passed=" + String(BaseboardNum) + ", Number of Units=" + String(NumElecBaseboards) + ", Entered Unit name=" + EquipName)
        var checkEquipName: Bool = __get_baseboard_field(state, BaseboardNum - 1, "CheckEquipName")
        if checkEquipName:
            var equipName: String = __get_baseboard_field(state, BaseboardNum - 1, "EquipName")
            if EquipName != equipName:
                __show_fatal_error(state, "SimElectricBaseboard: Invalid CompIndex passed=" + String(BaseboardNum) + ", Unit name=" + EquipName + ", stored Unit Name for that index=" + equipName)
            __set_baseboard_field(state, BaseboardNum - 1, "CheckEquipName", False)

    InitElectricBaseboard(state, BaseboardNum, ControlledZoneNum, FirstHVACIteration)
    CalcElectricBaseboard(state, BaseboardNum, ControlledZoneNum)

    PowerMet = __get_baseboard_field(state, BaseboardNum - 1, "TotPower")

    UpdateElectricBaseboard(state, BaseboardNum)
    ReportElectricBaseboard(state, BaseboardNum)


fn GetElectricBaseboardInput(state: Pointers[NoneType]):
    var RoutineName: String = "GetElectricBaseboardInput: "
    var routineName: String = "GetElectricBaseboardInput"
    var MaxFraction: Float64 = 1.0
    var MinFraction: Float64 = 0.0
    var MinDistribSurfaces: Int = 1
    var iHeatDesignCapacityNumericNum: Int = 1
    var iHeatCapacityPerFloorAreaNumericNum: Int = 2
    var iHeatFracOfAutosizedCapacityNumericNum: Int = 3

    var ErrorsFound: Bool = False
    var cCurrentModuleObject: String = "ZoneHVAC:Baseboard:RadiantConvective:Electric"

    var NumElecBaseboards: Int = __get_num_objects_found(state, cCurrentModuleObject)
    __set_state_data(state, "NumElecBaseboards", NumElecBaseboards)

    var ElecBaseboardNumericFields: List[ElecBaseboardNumericFieldData] = List[ElecBaseboardNumericFieldData](NumElecBaseboards)
    var ElecBaseboard: List[ElecBaseboardParams] = List[ElecBaseboardParams](NumElecBaseboards)

    var inputProcessor = __get_input_processor(state)
    var elecBaseboardSchemaProps = __get_schema_props(state, cCurrentModuleObject)
    var elecBaseboardObjects = __get_epjson_objects(state, cCurrentModuleObject)

    var numericFieldNames: List[String] = List[String]()
    numericFieldNames.append("Heating Design Capacity")
    numericFieldNames.append("Heating Design Capacity Per Floor Area")
    numericFieldNames.append("Fraction of Autosized Heating Design Capacity")
    numericFieldNames.append("Efficiency")
    numericFieldNames.append("Fraction Radiant")
    numericFieldNames.append("Fraction of Radiant Energy Incident on People")

    var availabilityScheduleFieldName: String = "Availability Schedule Name"
    var heatingDesignCapacityMethodFieldName: String = "Heating Design Capacity Method"
    var radiantSurfaceFractionFieldName: String = "Fraction of Radiant Energy to Surface"

    if elecBaseboardObjects is not None:
        var BaseboardNum: Int = 0
        for elecBaseboardInstance_key in elecBaseboardObjects:
            var elecBaseboardFields = elecBaseboardObjects[elecBaseboardInstance_key]
            var elecBaseboardName: String = __make_upper(elecBaseboardInstance_key)
            var availabilityScheduleName: String = __get_alpha_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "availability_schedule_name")
            var heatingDesignCapacityMethod: String = __get_alpha_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_method")
            var surfaceFractionsField = __get_surface_fractions_field(elecBaseboardFields)

            __mark_object_as_used(state, cCurrentModuleObject, elecBaseboardInstance_key)

            BaseboardNum += 1
            var elecBaseboard = ElecBaseboardParams()

            var numSurfaceFractions: Int = 0
            if surfaceFractionsField is not None:
                numSurfaceFractions = __len_surface_fractions(surfaceFractionsField)

            ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames = List[String](6 + numSurfaceFractions)
            for fieldNum in range(1, 7):
                ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum - 1] = numericFieldNames[fieldNum - 1]
            for fieldNum in range(1, numSurfaceFractions + 1):
                ElecBaseboardNumericFields[BaseboardNum - 1].FieldNames[fieldNum + 5] = radiantSurfaceFractionFieldName

            __verify_unique_baseboard_name(state, cCurrentModuleObject, elecBaseboardName, ErrorsFound, cCurrentModuleObject + " Name")

            elecBaseboard.EquipName = elecBaseboardName
            elecBaseboard.Schedule = availabilityScheduleName
            if availabilityScheduleName == "":
                elecBaseboard.availSched = __get_schedule_always_on(state)
            else:
                elecBaseboard.availSched = __get_schedule(state, availabilityScheduleName)
                if elecBaseboard.availSched is None:
                    __show_severe_item_not_found(state, routineName, cCurrentModuleObject, elecBaseboardName, availabilityScheduleFieldName, availabilityScheduleName)
                    ErrorsFound = True

            if __same_string(heatingDesignCapacityMethod, "HeatingDesignCapacity"):
                elecBaseboard.HeatingCapMethod = 1
                var heatingDesignCapacityField = __get_field_value(elecBaseboardFields, "heating_design_capacity")
                if heatingDesignCapacityField is not None:
                    elecBaseboard.ScaledHeatingCapacity = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity")
                    if elecBaseboard.ScaledHeatingCapacity < 0.0 and elecBaseboard.ScaledHeatingCapacity != -99999.0:
                        __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        __show_continue_error(state, "Illegal " + numericFieldNames[iHeatDesignCapacityNumericNum - 1] + " = " + String(elecBaseboard.ScaledHeatingCapacity))
                        ErrorsFound = True
                else:
                    __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                    __show_continue_error(state, "Input for " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                    __show_continue_error(state, "Blank field not allowed for " + numericFieldNames[iHeatDesignCapacityNumericNum - 1])
                    ErrorsFound = True
            elif __same_string(heatingDesignCapacityMethod, "CapacityPerFloorArea"):
                elecBaseboard.HeatingCapMethod = 2
                var heatingDesignCapacityPerFloorAreaField = __get_field_value(elecBaseboardFields, "heating_design_capacity_per_floor_area")
                if heatingDesignCapacityPerFloorAreaField is not None:
                    elecBaseboard.ScaledHeatingCapacity = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "heating_design_capacity_per_floor_area")
                    if elecBaseboard.ScaledHeatingCapacity <= 0.0:
                        __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        __show_continue_error(state, "Input for " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                        __show_continue_error(state, "Illegal " + numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1] + " = " + String(elecBaseboard.ScaledHeatingCapacity))
                        ErrorsFound = True
                    elif elecBaseboard.ScaledHeatingCapacity == -99999.0:
                        __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        __show_continue_error(state, "Input for " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                        __show_continue_error(state, "Illegal " + numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1] + " = Autosize")
                        ErrorsFound = True
                else:
                    __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                    __show_continue_error(state, "Input for " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                    __show_continue_error(state, "Blank field not allowed for " + numericFieldNames[iHeatCapacityPerFloorAreaNumericNum - 1])
                    ErrorsFound = True
            elif __same_string(heatingDesignCapacityMethod, "FractionOfAutosizedHeatingCapacity"):
                elecBaseboard.HeatingCapMethod = 3
                var fractionOfAutosizedCapacityField = __get_field_value(elecBaseboardFields, "fraction_of_autosized_heating_design_capacity")
                if fractionOfAutosizedCapacityField is not None:
                    elecBaseboard.ScaledHeatingCapacity = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_autosized_heating_design_capacity")
                    if elecBaseboard.ScaledHeatingCapacity < 0.0:
                        __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                        __show_continue_error(state, "Illegal " + numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1] + " = " + String(elecBaseboard.ScaledHeatingCapacity))
                        ErrorsFound = True
                else:
                    __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                    __show_continue_error(state, "Input for " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                    __show_continue_error(state, "Blank field not allowed for " + numericFieldNames[iHeatFracOfAutosizedCapacityNumericNum - 1])
                    ErrorsFound = True
            else:
                __show_severe_error(state, cCurrentModuleObject + " = " + elecBaseboard.EquipName)
                __show_continue_error(state, "Illegal " + heatingDesignCapacityMethodFieldName + " = " + heatingDesignCapacityMethod)
                ErrorsFound = True

            elecBaseboard.BaseboardEfficiency = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "efficiency")
            elecBaseboard.FracRadiant = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "fraction_radiant")
            if elecBaseboard.FracRadiant < MinFraction:
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[4] + " was lower than the allowable minimum.")
                __show_continue_error(state, "...reset to minimum value=[" + String(MinFraction, 2) + "].")
                elecBaseboard.FracRadiant = MinFraction
            if elecBaseboard.FracRadiant > MaxFraction:
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[4] + " was higher than the allowable maximum.")
                __show_continue_error(state, "...reset to maximum value=[" + String(MaxFraction, 2) + "].")
                elecBaseboard.FracRadiant = MaxFraction

            if elecBaseboard.FracRadiant > MaxFraction:
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Fraction Radiant was higher than the allowable maximum.")
                elecBaseboard.FracRadiant = MaxFraction
                elecBaseboard.FracConvect = 0.0
            else:
                elecBaseboard.FracConvect = 1.0 - elecBaseboard.FracRadiant

            elecBaseboard.FracDistribPerson = __get_real_field_value(state, elecBaseboardFields, elecBaseboardSchemaProps, "fraction_of_radiant_energy_incident_on_people")
            if elecBaseboard.FracDistribPerson < MinFraction:
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[5] + " was lower than the allowable minimum.")
                __show_continue_error(state, "...reset to minimum value=[" + String(MinFraction, 2) + "].")
                elecBaseboard.FracDistribPerson = MinFraction
            if elecBaseboard.FracDistribPerson > MaxFraction:
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + numericFieldNames[5] + " was higher than the allowable maximum.")
                __show_continue_error(state, "...reset to maximum value=[" + String(MaxFraction, 2) + "].")
                elecBaseboard.FracDistribPerson = MaxFraction

            elecBaseboard.TotSurfToDistrib = numSurfaceFractions

            if (elecBaseboard.TotSurfToDistrib < MinDistribSurfaces) and (elecBaseboard.FracRadiant > MinFraction):
                __show_severe_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", the number of surface/radiant fraction groups entered was less than the allowable minimum.")
                __show_continue_error(state, "...the minimum that must be entered=[" + String(MinDistribSurfaces) + "].")
                ErrorsFound = True
                elecBaseboard.TotSurfToDistrib = 0

            elecBaseboard.SurfaceName = List[String](elecBaseboard.TotSurfToDistrib)
            elecBaseboard.SurfacePtr = List[Int](elecBaseboard.TotSurfToDistrib)
            elecBaseboard.FracDistribToSurf = List[Float64](elecBaseboard.TotSurfToDistrib)

            elecBaseboard.ZonePtr = __get_zone_equip_controlled_zone_num(state, 1, elecBaseboard.EquipName)

            var AllFracsSummed: Float64 = elecBaseboard.FracDistribPerson
            if surfaceFractionsField is not None:
                for SurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                    var surfaceFraction = __get_surface_fraction_item(surfaceFractionsField, SurfNum - 1)
                    elecBaseboard.SurfaceName[SurfNum - 1] = __get_alpha_field_value(state, surfaceFraction, __get_surface_fraction_schema_props(state), "surface_name")
                    elecBaseboard.SurfacePtr[SurfNum - 1] = __get_radiant_system_surface(state, cCurrentModuleObject, elecBaseboard.EquipName, elecBaseboard.ZonePtr, elecBaseboard.SurfaceName[SurfNum - 1], ErrorsFound)
                    elecBaseboard.FracDistribToSurf[SurfNum - 1] = __get_real_field_value(state, surfaceFraction, __get_surface_fraction_schema_props(state), "fraction_of_radiant_energy_to_surface")
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] > MaxFraction:
                        __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + radiantSurfaceFractionFieldName + " was greater than the allowable maximum.")
                        __show_continue_error(state, "...reset to maximum value=[" + String(MaxFraction, 2) + "].")
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MaxFraction
                    if elecBaseboard.FracDistribToSurf[SurfNum - 1] < MinFraction:
                        __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", " + radiantSurfaceFractionFieldName + " was less than the allowable minimum.")
                        __show_continue_error(state, "...reset to minimum value=[" + String(MinFraction, 2) + "].")
                        elecBaseboard.FracDistribToSurf[SurfNum - 1] = MinFraction
                    if elecBaseboard.SurfacePtr[SurfNum - 1] != 0:
                        __set_surface_gets_radiant_heat(state, elecBaseboard.SurfacePtr[SurfNum - 1])
                        __append_gets_radiant_heat_surface_list(state, elecBaseboard.SurfacePtr[SurfNum - 1])

                    AllFracsSummed += elecBaseboard.FracDistribToSurf[SurfNum - 1]

            if AllFracsSummed > (MaxFraction + 0.01):
                __show_severe_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Summed radiant fractions for people + surface groups > 1.0")
                ErrorsFound = True
            if (AllFracsSummed < (MaxFraction - 0.01)) and (elecBaseboard.FracRadiant > MinFraction):
                __show_warning_error(state, RoutineName + cCurrentModuleObject + "=\"" + elecBaseboardName + "\", Summed radiant fractions for people + surface groups < 1.0")
                __show_continue_error(state, "The rest of the radiant energy delivered by the baseboard heater will be lost")

            ElecBaseboard[BaseboardNum - 1] = elecBaseboard

    if ErrorsFound:
        __show_fatal_error(state, RoutineName + cCurrentModuleObject + "Errors found getting input. Program terminates.")

    __set_state_data(state, "ElecBaseboardNumericFields", ElecBaseboardNumericFields)
    __set_state_data(state, "ElecBaseboard", ElecBaseboard)

    for elecBaseboard in ElecBaseboard:
        __setup_output_variable(state, "Baseboard Total Heating Rate", elecBaseboard.TotPower, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Convective Heating Rate", elecBaseboard.ConvPower, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Radiant Heating Rate", elecBaseboard.RadPower, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Electricity Energy", elecBaseboard.ElecUseLoad, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Electricity Rate", elecBaseboard.ElecUseRate, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Total Heating Energy", elecBaseboard.TotEnergy, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Convective Heating Energy", elecBaseboard.ConvEnergy, elecBaseboard.EquipName)
        __setup_output_variable(state, "Baseboard Radiant Heating Energy", elecBaseboard.RadEnergy, elecBaseboard.EquipName)


fn InitElectricBaseboard(state: Pointers[NoneType], BaseboardNum: Int, ControlledZoneNum: Int, FirstHVACIteration: Bool):
    var elecBaseboard = __get_baseboard(state, BaseboardNum - 1)

    if not __get_state_flag(state, "SysSizingCalc") and elecBaseboard.MySizeFlag:
        SizeElectricBaseboard(state, BaseboardNum)
        elecBaseboard.MySizeFlag = False

    if __get_state_flag(state, "BeginEnvrnFlag") and elecBaseboard.MyEnvrnFlag:
        elecBaseboard.ZeroBBSourceSumHATsurf = 0.0
        elecBaseboard.QBBElecRadSource = 0.0
        elecBaseboard.QBBElecRadSrcAvg = 0.0
        elecBaseboard.LastQBBElecRadSrc = 0.0
        elecBaseboard.LastSysTimeElapsed = 0.0
        elecBaseboard.LastTimeStepSys = 0.0
        elecBaseboard.MyEnvrnFlag = False

    if not __get_state_flag(state, "BeginEnvrnFlag"):
        elecBaseboard.MyEnvrnFlag = True

    if __get_state_flag(state, "BeginTimeStepFlag") and FirstHVACIteration:
        elecBaseboard.ZeroBBSourceSumHATsurf = __get_zone_sum_hat_surf(state, ControlledZoneNum)
        elecBaseboard.QBBElecRadSrcAvg = 0.0
        elecBaseboard.LastQBBElecRadSrc = 0.0
        elecBaseboard.LastSysTimeElapsed = 0.0
        elecBaseboard.LastTimeStepSys = 0.0

    var ZoneNode: Int = __get_zone_equip_config_zone_node(state, ControlledZoneNum)
    elecBaseboard.AirInletTemp = __get_node_temp(state, ZoneNode)
    elecBaseboard.AirInletHumRat = __get_node_hum_rat(state, ZoneNode)

    elecBaseboard.TotPower = 0.0
    elecBaseboard.Power = 0.0
    elecBaseboard.ConvPower = 0.0
    elecBaseboard.RadPower = 0.0
    elecBaseboard.TotEnergy = 0.0
    elecBaseboard.Energy = 0.0
    elecBaseboard.ConvEnergy = 0.0
    elecBaseboard.RadEnergy = 0.0
    elecBaseboard.ElecUseLoad = 0.0
    elecBaseboard.ElecUseRate = 0.0

    __set_baseboard(state, BaseboardNum - 1, elecBaseboard)


fn SizeElectricBaseboard(state: Pointers[NoneType], BaseboardNum: Int):
    var RoutineName: String = "SizeElectricBaseboard"
    var TempSize: Float64 = 0.0

    if __get_state_data(state, "CurZoneEqNum") > 0:
        var zoneEqSizing = __get_zone_eq_sizing(state, __get_state_data(state, "CurZoneEqNum") - 1)
        var elecBaseboard = __get_baseboard(state, BaseboardNum - 1)
        __set_state_data(state, "DataScalableCapSizingON", False)

        var CompType: String = "ZoneHVAC:Baseboard:RadiantConvective:Electric"
        var CompName: String = elecBaseboard.EquipName
        __set_state_data(state, "DataFracOfAutosizedHeatingCapacity", 1.0)
        __set_state_data(state, "DataZoneNumber", elecBaseboard.ZonePtr)
        var SizingMethod: Int = 1
        var FieldNum: Int = 1
        var SizingString: String = CompName + " [W]"
        var CapSizingMethod: Int = elecBaseboard.HeatingCapMethod
        __set_zone_eq_sizing_method(state, __get_state_data(state, "CurZoneEqNum") - 1, SizingMethod, CapSizingMethod)

        if CapSizingMethod == 1 or CapSizingMethod == 2 or CapSizingMethod == 3:
            var PrintFlag: Bool = True
            if CapSizingMethod == 1:
                if elecBaseboard.ScaledHeatingCapacity == -99999.0:
                    __check_zone_sizing(state, CompType, CompName)
                    __set_zone_eq_sizing_heating_load(state, __get_state_data(state, "CurZoneEqNum") - 1, __get_final_zone_sizing_heat_load(state, __get_state_data(state, "CurZoneEqNum") - 1))
                else:
                    __set_zone_eq_sizing_heating_load(state, __get_state_data(state, "CurZoneEqNum") - 1, elecBaseboard.ScaledHeatingCapacity)
                __set_zone_eq_sizing_heating_capacity(state, __get_state_data(state, "CurZoneEqNum") - 1, True)
                TempSize = elecBaseboard.ScaledHeatingCapacity
            elif CapSizingMethod == 2:
                if __get_state_data(state, "ZoneSizingRunDone"):
                    __set_zone_eq_sizing_heating_capacity(state, __get_state_data(state, "CurZoneEqNum") - 1, True)
                    __set_zone_eq_sizing_heating_load(state, __get_state_data(state, "CurZoneEqNum") - 1, __get_final_zone_sizing_heat_load(state, __get_state_data(state, "CurZoneEqNum") - 1))
                var zone_floor_area: Float64 = __get_zone_floor_area(state, __get_state_data(state, "DataZoneNumber") - 1)
                TempSize = elecBaseboard.ScaledHeatingCapacity * zone_floor_area
                __set_state_data(state, "DataScalableCapSizingON", True)
            elif CapSizingMethod == 3:
                __check_zone_sizing(state, CompType, CompName)
                __set_zone_eq_sizing_heating_capacity(state, __get_state_data(state, "CurZoneEqNum") - 1, True)
                __set_state_data(state, "DataFracOfAutosizedHeatingCapacity", elecBaseboard.ScaledHeatingCapacity)
                __set_zone_eq_sizing_heating_load(state, __get_state_data(state, "CurZoneEqNum") - 1, __get_final_zone_sizing_heat_load(state, __get_state_data(state, "CurZoneEqNum") - 1))
                var FracOfAutoSzCap: Float64 = -99999.0
                var ErrorsFound: Bool = False
                FracOfAutoSzCap = __size_heating_capacity(state, CompType, CompName, PrintFlag, RoutineName, SizingString, FracOfAutoSzCap)
                TempSize = FracOfAutoSzCap
                __set_state_data(state, "DataFracOfAutosizedHeatingCapacity", 1.0)
                __set_state_data(state, "DataScalableCapSizingON", True)
            else:
                TempSize = elecBaseboard.ScaledHeatingCapacity

            var errorsFound: Bool = False
            elecBaseboard.NominalCapacity = __size_heating_capacity(state, CompType, CompName, PrintFlag, RoutineName, SizingString, TempSize)
            __set_state_data(state, "DataScalableCapSizingON", False)

        __set_baseboard(state, BaseboardNum - 1, elecBaseboard)


fn CalcElectricBaseboard(state: Pointers[NoneType], BaseboardNum: Int, ControlledZoneNum: Int):
    var SimpConvAirFlowSpeed: Float64 = 0.5

    var elecBaseboard = __get_baseboard(state, BaseboardNum - 1)

    var ZoneNum: Int = elecBaseboard.ZonePtr
    var QZnReq: Float64 = __get_zone_energy_demand(state, ZoneNum)
    var AirInletTemp: Float64 = elecBaseboard.AirInletTemp
    var AirOutletTemp: Float64 = AirInletTemp
    var CpAir: Float64 = __ps_cp_air_fn_w(elecBaseboard.AirInletHumRat)
    var AirMassFlowRate: Float64 = SimpConvAirFlowSpeed
    var CapacitanceAir: Float64 = CpAir * AirMassFlowRate

    var Effic: Float64 = elecBaseboard.BaseboardEfficiency

    var LoadMet: Float64 = 0.0
    var QBBCap: Float64 = 0.0
    var RadHeat: Float64 = 0.0

    if QZnReq > 10.0 and not __get_cur_deadband_or_setback(state, ZoneNum) and __get_schedule_current_val(elecBaseboard.availSched) > 0.0:
        if QZnReq > elecBaseboard.NominalCapacity:
            QBBCap = elecBaseboard.NominalCapacity
        else:
            QBBCap = QZnReq

        RadHeat = QBBCap * elecBaseboard.FracRadiant
        elecBaseboard.QBBElecRadSource = RadHeat

        if elecBaseboard.FracRadiant > 0.0:
            DistributeBBElecRadGains(state)
            __calc_heat_balance_outside_surf(state, ZoneNum)
            __calc_heat_balance_inside_surf(state, ZoneNum)

            LoadMet = (__get_zone_sum_hat_surf(state, ZoneNum) - elecBaseboard.ZeroBBSourceSumHATsurf) + \
                      (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)

            if LoadMet < 0.0:
                elecBaseboard.QBBElecRadSource = 0.0
                DistributeBBElecRadGains(state)
                __calc_heat_balance_outside_surf(state, ZoneNum)
                __calc_heat_balance_inside_surf(state, ZoneNum)
                var TempZeroBBSourceSumHATsurf: Float64 = __get_zone_sum_hat_surf(state, ZoneNum)

                elecBaseboard.QBBElecRadSource = RadHeat
                DistributeBBElecRadGains(state)
                __calc_heat_balance_outside_surf(state, ZoneNum)
                __calc_heat_balance_inside_surf(state, ZoneNum)

                LoadMet = (__get_zone_sum_hat_surf(state, ZoneNum) - TempZeroBBSourceSumHATsurf) + \
                          (QBBCap * elecBaseboard.FracConvect) + (RadHeat * elecBaseboard.FracDistribPerson)

                if LoadMet < 0.0:
                    UpdateElectricBaseboardOff(LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)
                else:
                    UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
            else:
                UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
        else:
            LoadMet = QBBCap
            UpdateElectricBaseboardOn(AirOutletTemp, elecBaseboard.ElecUseRate, AirInletTemp, QBBCap, CapacitanceAir, Effic)
    else:
        UpdateElectricBaseboardOff(LoadMet, QBBCap, RadHeat, elecBaseboard.QBBElecRadSource, elecBaseboard.ElecUseRate, AirOutletTemp, AirInletTemp)

    elecBaseboard.AirOutletTemp = AirOutletTemp
    elecBaseboard.Power = QBBCap
    elecBaseboard.TotPower = LoadMet
    elecBaseboard.RadPower = RadHeat
    elecBaseboard.ConvPower = QBBCap - RadHeat

    __set_baseboard(state, BaseboardNum - 1, elecBaseboard)


fn UpdateElectricBaseboardOff(inout LoadMet: Float64, inout QBBCap: Float64, inout RadHeat: Float64, inout QBBElecRadSrc: Float64, inout ElecUseRate: Float64, inout AirOutletTemp: Float64, AirInletTemp: Float64):
    QBBCap = 0.0
    LoadMet = 0.0
    RadHeat = 0.0
    AirOutletTemp = AirInletTemp
    QBBElecRadSrc = 0.0
    ElecUseRate = 0.0


fn UpdateElectricBaseboardOn(inout AirOutletTemp: Float64, inout ElecUseRate: Float64, AirInletTemp: Float64, QBBCap: Float64, CapacitanceAir: Float64, Effic: Float64):
    AirOutletTemp = AirInletTemp + QBBCap / CapacitanceAir
    ElecUseRate = QBBCap / Effic


fn UpdateElectricBaseboard(state: Pointers[NoneType], BaseboardNum: Int):
    var SysTimeElapsed: Float64 = __get_sys_time_elapsed(state)
    var TimeStepSys: Float64 = __get_time_step_sys(state)
    var elecBaseboard = __get_baseboard(state, BaseboardNum - 1)

    if elecBaseboard.LastSysTimeElapsed == SysTimeElapsed:
        elecBaseboard.QBBElecRadSrcAvg -= elecBaseboard.LastQBBElecRadSrc * elecBaseboard.LastTimeStepSys / __get_time_step_zone(state)

    elecBaseboard.QBBElecRadSrcAvg += elecBaseboard.QBBElecRadSource * TimeStepSys / __get_time_step_zone(state)

    elecBaseboard.LastQBBElecRadSrc = elecBaseboard.QBBElecRadSource
    elecBaseboard.LastSysTimeElapsed = SysTimeElapsed
    elecBaseboard.LastTimeStepSys = TimeStepSys

    __set_baseboard(state, BaseboardNum - 1, elecBaseboard)


fn UpdateBBElecRadSourceValAvg(state: Pointers[NoneType], inout ElecBaseboardSysOn: Bool):
    ElecBaseboardSysOn = False

    if __get_state_data(state, "NumElecBaseboards") == 0:
        return

    var ElecBoardList = __get_state_data(state, "ElecBaseboard")
    for i in range(len(ElecBoardList)):
        var elecBaseboard = ElecBoardList[i]
        elecBaseboard.QBBElecRadSource = elecBaseboard.QBBElecRadSrcAvg
        if elecBaseboard.QBBElecRadSrcAvg != 0.0:
            ElecBaseboardSysOn = True

    DistributeBBElecRadGains(state)


fn DistributeBBElecRadGains(state: Pointers[NoneType]):
    var SmallestArea: Float64 = 0.001

    var ElecBoardList = __get_state_data(state, "ElecBaseboard")

    for elecBaseboard in ElecBoardList:
        for radSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
            var surfNum: Int = elecBaseboard.SurfacePtr[radSurfNum - 1]
            __set_surface_elec_baseboard_rad(state, surfNum, 0.0)

    __set_zone_q_elec_baseboard_to_person(state, 0.0)

    for elecBaseboard in ElecBoardList:
        if elecBaseboard.ZonePtr > 0:
            var ZoneNum: Int = elecBaseboard.ZonePtr
            __add_zone_q_elec_baseboard_to_person(state, ZoneNum, elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribPerson)

            for RadSurfNum in range(1, elecBaseboard.TotSurfToDistrib + 1):
                var SurfNum: Int = elecBaseboard.SurfacePtr[RadSurfNum - 1]
                var SurfArea: Float64 = __get_surface_area(state, SurfNum)
                if SurfArea > SmallestArea:
                    var ThisSurfIntensity: Float64 = (elecBaseboard.QBBElecRadSource * elecBaseboard.FracDistribToSurf[RadSurfNum - 1] / SurfArea)
                    __add_surface_elec_baseboard_rad(state, SurfNum, ThisSurfIntensity)
                    if ThisSurfIntensity > 10000.0:
                        __show_severe_error(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                        __show_continue_error(state, "Surface = " + __get_surface_name(state, SurfNum))
                        __show_continue_error(state, "Surface area = " + String(SurfArea, 15) + " [m2]")
                        __show_continue_error(state, "Occurs in ZoneHVAC:Baseboard:RadiantConvective:Electric = " + elecBaseboard.EquipName)
                        __show_continue_error(state, "Radiation intensity = " + String(ThisSurfIntensity, 15) + " [W/m2]")
                        __show_continue_error(state, "Assign a larger surface area or more surfaces in ZoneHVAC:Baseboard:RadiantConvective:Electric")
                        __show_fatal_error(state, "DistributeBBElecRadGains:  excessive thermal radiation heat flux intensity detected")
                else:
                    __show_severe_error(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")
                    __show_continue_error(state, "Surface = " + __get_surface_name(state, SurfNum))
                    __show_continue_error(state, "Surface area = " + String(SurfArea, 15) + " [m2]")
                    __show_continue_error(state, "Occurs in ZoneHVAC:Baseboard:RadiantConvective:Electric = " + elecBaseboard.EquipName)
                    __show_continue_error(state, "Assign a larger surface area or more surfaces in ZoneHVAC:Baseboard:RadiantConvective:Electric")
                    __show_fatal_error(state, "DistributeBBElecRadGains:  surface not large enough to receive thermal radiation heat flux")


fn ReportElectricBaseboard(state: Pointers[NoneType], BaseboardNum: Int):
    var TimeStepSysSec: Float64 = __get_time_step_sys_sec(state)
    var elecBaseboard = __get_baseboard(state, BaseboardNum - 1)
    elecBaseboard.ElecUseLoad = elecBaseboard.ElecUseRate * TimeStepSysSec
    elecBaseboard.TotEnergy = elecBaseboard.TotPower * TimeStepSysSec
    elecBaseboard.Energy = elecBaseboard.Power * TimeStepSysSec
    elecBaseboard.ConvEnergy = elecBaseboard.ConvPower * TimeStepSysSec
    elecBaseboard.RadEnergy = elecBaseboard.RadPower * TimeStepSysSec
    __set_baseboard(state, BaseboardNum - 1, elecBaseboard)
