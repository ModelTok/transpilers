# EXTERNAL DEPS (to wire in glue):
# Schedule (ScheduleManager) — Schedule type and GetSchedule() function
# Constant.eFuel enum and eFuelNamesUC, eFuelNames mappings, eFuel2eResource (DataGlobalConstants)
# Constant.Units, Constant.eResource, Constant.KindOfSim enums (DataGlobalConstants)
# OutputProcessor.SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat (OutputProcessor)
# OutputReportPredefined.PreDefTableEntry and pdchExLtPower, pdchExLtClock, pdchExLtSchd (OutputReportPredefined)
# EMSManager.SetupEMSActuator (EMSManager)
# InputProcessor interface with getNumObjectsFound, epJSON, getObjectSchemaProps, getAlphaFieldValue, getRealFieldValue, markObjectAsUsed (InputProcessing)
# GlobalNames.VerifyUniqueInterObjectName (GlobalNames)
# Util.makeUPPER, Util.SameString (UtilityRoutines)
# Error functions: ShowSevereEmptyField, ShowSevereItemNotFound, ShowSevereCustom, ShowSevereInvalidKey, ShowFatalError (UtilityRoutines)
# ErrorObjectHeader (UtilityRoutines)
# EnergyPlusData state with .dataExteriorEnergyUse, .dataInputProcessing, .dataGlobal, .dataEnvrn, .dataOutRptPredefined (Data.EnergyPlusData)

from enum import IntEnum
from dataclasses import dataclass, field
from typing import Optional, Dict, List, Any


class LightControlType(IntEnum):
    Invalid = -1
    ScheduleOnly = 1
    AstroClockOverride = 2
    Num = 3


@dataclass
class ExteriorLightUsage:
    Name: str = ""
    sched: Optional[Any] = None
    DesignLevel: float = 0.0
    Power: float = 0.0
    CurrentUse: float = 0.0
    ControlMode: LightControlType = LightControlType.ScheduleOnly
    ManageDemand: bool = False
    DemandLimit: float = 0.0
    PowerActuatorOn: bool = False
    PowerActuatorValue: float = 0.0
    SumConsumption: float = 0.0
    SumTimeNotZeroCons: float = 0.0


@dataclass
class ExteriorEquipmentUsage:
    Name: str = ""
    FuelType: Any = None
    sched: Optional[Any] = None
    DesignLevel: float = 0.0
    Power: float = 0.0
    CurrentUse: float = 0.0
    ManageDemand: bool = False
    DemandLimit: float = 0.0


@dataclass
class ExteriorEnergyUseData:
    NumExteriorLights: int = 0
    NumExteriorEqs: int = 0
    ExteriorLights: List[ExteriorLightUsage] = field(default_factory=list)
    ExteriorEquipment: List[ExteriorEquipmentUsage] = field(default_factory=list)
    UniqueExteriorEquipNames: Dict[str, str] = field(default_factory=dict)
    GetExteriorEnergyInputFlag: bool = True
    sumDesignLevel: float = 0.0

    def clear_state(self) -> None:
        self.NumExteriorLights = 0
        self.NumExteriorEqs = 0
        self.ExteriorLights = []
        self.ExteriorEquipment = []
        self.UniqueExteriorEquipNames.clear()
        self.GetExteriorEnergyInputFlag = True
        self.sumDesignLevel = 0.0


def ManageExteriorEnergyUse(state: Any) -> None:
    if state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag:
        GetExteriorEnergyUseInput(state)
        state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag = False

    ReportExteriorEnergyUse(state)


def GetExteriorEnergyUseInput(state: Any) -> None:
    routine_name = "GetExteriorEnergyUseInput"

    errors_found = False
    end_use_subcategory_name = ""
    input_processor = state.dataInputProcessing.inputProcessor

    state.dataExteriorEnergyUse.NumExteriorLights = input_processor.getNumObjectsFound(state, "Exterior:Lights")
    state.dataExteriorEnergyUse.ExteriorLights = [ExteriorLightUsage() for _ in range(state.dataExteriorEnergyUse.NumExteriorLights)]

    num_fuel_eq = input_processor.getNumObjectsFound(state, "Exterior:FuelEquipment")
    num_wtr_eq = input_processor.getNumObjectsFound(state, "Exterior:WaterEquipment")
    state.dataExteriorEnergyUse.ExteriorEquipment = [ExteriorEquipmentUsage() for _ in range(num_fuel_eq + num_wtr_eq)]
    state.dataExteriorEnergyUse.UniqueExteriorEquipNames = {}

    state.dataExteriorEnergyUse.GetExteriorEnergyInputFlag = False
    state.dataExteriorEnergyUse.NumExteriorEqs = 0

    # Get Exterior Lights
    current_module_object = "Exterior:Lights"
    exterior_lights_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
    exterior_lights_objects = input_processor.epJSON.get(current_module_object)
    
    if exterior_lights_objects is not None:
        item = 0
        for light_name_raw, light_fields in exterior_lights_objects.items():
            light_name = light_name_raw.upper()
            schedule_name = input_processor.getAlphaFieldValue(light_fields, exterior_lights_schema_props, "schedule_name")
            control_option = light_fields.get("control_option")
            if control_option:
                control_option = input_processor.getAlphaFieldValue(light_fields, exterior_lights_schema_props, "control_option")
            else:
                control_option = ""

            input_processor.markObjectAsUsed(current_module_object, light_name_raw)

            eoh = (routine_name, current_module_object, light_name)

            state.dataExteriorEnergyUse.ExteriorLights[item].Name = light_name

            if not schedule_name:
                ShowSevereEmptyField(state, eoh, "schedule_name")
                errors_found = True
            else:
                sched = GetSchedule(state, schedule_name)
                if sched is None:
                    ShowSevereItemNotFound(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    state.dataExteriorEnergyUse.ExteriorLights[item].sched = sched
                    sch_min = sched.getMinVal(state)
                    if sch_min < 0.0:
                        ShowSevereCustom(state, eoh, f"schedule_name = {schedule_name} minimum is [{sch_min}]. Values must be >= 0.0.")
                        errors_found = True

            if not control_option:
                state.dataExteriorEnergyUse.ExteriorLights[item].ControlMode = LightControlType.ScheduleOnly
            elif SameString(control_option, "ScheduleNameOnly"):
                state.dataExteriorEnergyUse.ExteriorLights[item].ControlMode = LightControlType.ScheduleOnly
            elif SameString(control_option, "AstronomicalClock"):
                state.dataExteriorEnergyUse.ExteriorLights[item].ControlMode = LightControlType.AstroClockOverride
            else:
                ShowSevereInvalidKey(state, eoh, "control_option", control_option)

            if "end_use_subcategory" in light_fields:
                end_use_subcategory_name = input_processor.getAlphaFieldValue(light_fields, exterior_lights_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            state.dataExteriorEnergyUse.ExteriorLights[item].DesignLevel = input_processor.getRealFieldValue(light_fields, exterior_lights_schema_props, "design_level")
            
            if state.dataGlobal.AnyEnergyManagementSystemInModel:
                SetupEMSActuator(state,
                                "ExteriorLights",
                                state.dataExteriorEnergyUse.ExteriorLights[item].Name,
                                "Electricity Rate",
                                "W",
                                state.dataExteriorEnergyUse.ExteriorLights[item].PowerActuatorOn,
                                state.dataExteriorEnergyUse.ExteriorLights[item].PowerActuatorValue)

            SetupOutputVariable(state,
                               "Exterior Lights Electricity Rate",
                               Units.W,
                               state.dataExteriorEnergyUse.ExteriorLights[item].Power,
                               TimeStepType.Zone,
                               StoreType.Average,
                               state.dataExteriorEnergyUse.ExteriorLights[item].Name)

            SetupOutputVariable(state,
                               "Exterior Lights Electricity Energy",
                               Units.J,
                               state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse,
                               TimeStepType.Zone,
                               StoreType.Sum,
                               state.dataExteriorEnergyUse.ExteriorLights[item].Name,
                               eResource.Electricity,
                               Group.Invalid,
                               EndUseCat.ExteriorLights,
                               end_use_subcategory_name)

            PreDefTableEntry(state,
                            state.dataOutRptPredefined.pdchExLtPower,
                            state.dataExteriorEnergyUse.ExteriorLights[item].Name,
                            state.dataExteriorEnergyUse.ExteriorLights[item].DesignLevel)
            state.dataExteriorEnergyUse.sumDesignLevel += state.dataExteriorEnergyUse.ExteriorLights[item].DesignLevel
            
            if state.dataExteriorEnergyUse.ExteriorLights[item].ControlMode == LightControlType.AstroClockOverride:
                PreDefTableEntry(state,
                                state.dataOutRptPredefined.pdchExLtClock,
                                state.dataExteriorEnergyUse.ExteriorLights[item].Name,
                                "AstronomicalClock")
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtSchd, state.dataExteriorEnergyUse.ExteriorLights[item].Name, "-")
            else:
                PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtClock, state.dataExteriorEnergyUse.ExteriorLights[item].Name, "Schedule")
                PreDefTableEntry(state,
                                state.dataOutRptPredefined.pdchExLtSchd,
                                state.dataExteriorEnergyUse.ExteriorLights[item].Name,
                                state.dataExteriorEnergyUse.ExteriorLights[item].sched.Name)
            item += 1

    PreDefTableEntry(state, state.dataOutRptPredefined.pdchExLtPower, "Exterior Lighting Total", state.dataExteriorEnergyUse.sumDesignLevel)

    # Get Exterior Fuel Equipment
    current_module_object = "Exterior:FuelEquipment"
    exterior_fuel_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
    exterior_fuel_objects = input_processor.epJSON.get(current_module_object)
    
    if exterior_fuel_objects is not None:
        for fuel_equip_name_raw, fuel_equip_fields in exterior_fuel_objects.items():
            equip_name = fuel_equip_name_raw.upper()
            fuel_use_type = input_processor.getAlphaFieldValue(fuel_equip_fields, exterior_fuel_schema_props, "fuel_use_type")
            schedule_name = input_processor.getAlphaFieldValue(fuel_equip_fields, exterior_fuel_schema_props, "schedule_name")

            input_processor.markObjectAsUsed(current_module_object, fuel_equip_name_raw)
            VerifyUniqueInterObjectName(state, state.dataExteriorEnergyUse.UniqueExteriorEquipNames, equip_name, current_module_object, "Name", errors_found)

            eoh = (routine_name, current_module_object, equip_name)

            state.dataExteriorEnergyUse.NumExteriorEqs += 1

            exterior_equip = state.dataExteriorEnergyUse.ExteriorEquipment[state.dataExteriorEnergyUse.NumExteriorEqs - 1]
            exterior_equip.Name = equip_name

            if "end_use_subcategory" in fuel_equip_fields:
                end_use_subcategory_name = input_processor.getAlphaFieldValue(fuel_equip_fields, exterior_fuel_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            if not fuel_use_type:
                ShowSevereEmptyField(state, eoh, "fuel_use_type")
                errors_found = True
            else:
                fuel_type_val = getEnumValue(eFuelNamesUC, fuel_use_type)
                if fuel_type_val == eFuel.Invalid:
                    ShowSevereInvalidKey(state, eoh, "fuel_use_type", fuel_use_type)
                    errors_found = True
                else:
                    exterior_equip.FuelType = fuel_type_val
                    if exterior_equip.FuelType != eFuel.Water:
                        SetupOutputVariable(state,
                                           "Exterior Equipment Fuel Rate",
                                           Units.W,
                                           exterior_equip.Power,
                                           TimeStepType.Zone,
                                           StoreType.Average,
                                           exterior_equip.Name)
                        SetupOutputVariable(state,
                                           f"Exterior Equipment {eFuelNames[int(exterior_equip.FuelType)]} Energy",
                                           Units.J,
                                           exterior_equip.CurrentUse,
                                           TimeStepType.Zone,
                                           StoreType.Sum,
                                           exterior_equip.Name,
                                           eFuel2eResource[int(exterior_equip.FuelType)],
                                           Group.Invalid,
                                           EndUseCat.ExteriorEquipment,
                                           end_use_subcategory_name)
                    else:
                        SetupOutputVariable(state,
                                           "Exterior Equipment Water Volume Flow Rate",
                                           Units.m3_s,
                                           exterior_equip.Power,
                                           TimeStepType.Zone,
                                           StoreType.Average,
                                           exterior_equip.Name)
                        SetupOutputVariable(state,
                                           f"Exterior Equipment {eFuelNames[int(exterior_equip.FuelType)]} Volume",
                                           Units.m3,
                                           exterior_equip.CurrentUse,
                                           TimeStepType.Zone,
                                           StoreType.Sum,
                                           exterior_equip.Name,
                                           eFuel2eResource[int(exterior_equip.FuelType)],
                                           Group.Invalid,
                                           EndUseCat.ExteriorEquipment,
                                           end_use_subcategory_name)

            if not schedule_name:
                ShowSevereEmptyField(state, eoh, "schedule_name")
                errors_found = True
            else:
                sched = GetSchedule(state, schedule_name)
                if sched is None:
                    ShowSevereItemNotFound(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    exterior_equip.sched = sched
                    sch_min = sched.getMinVal(state)
                    if sch_min < 0.0:
                        ShowSevereCustom(state, eoh, f"schedule_name = {schedule_name} minimum is [{sch_min}]. Values must be >= 0.0.")
                        errors_found = True
            
            exterior_equip.DesignLevel = input_processor.getRealFieldValue(fuel_equip_fields, exterior_fuel_schema_props, "design_level")

    # Get Exterior Water Equipment
    current_module_object = "Exterior:WaterEquipment"
    exterior_water_schema_props = input_processor.getObjectSchemaProps(state, current_module_object)
    exterior_water_objects = input_processor.epJSON.get(current_module_object)
    
    if exterior_water_objects is not None:
        for water_equip_name_raw, water_equip_fields in exterior_water_objects.items():
            equip_name = water_equip_name_raw.upper()
            schedule_name = input_processor.getAlphaFieldValue(water_equip_fields, exterior_water_schema_props, "schedule_name")

            input_processor.markObjectAsUsed(current_module_object, water_equip_name_raw)

            eoh = (routine_name, current_module_object, equip_name)

            VerifyUniqueInterObjectName(state, state.dataExteriorEnergyUse.UniqueExteriorEquipNames, equip_name, current_module_object, "Name", errors_found)

            state.dataExteriorEnergyUse.NumExteriorEqs += 1

            exterior_equip = state.dataExteriorEnergyUse.ExteriorEquipment[state.dataExteriorEnergyUse.NumExteriorEqs - 1]
            exterior_equip.Name = equip_name
            exterior_equip.FuelType = eFuel.Water

            if not schedule_name:
                ShowSevereEmptyField(state, eoh, "schedule_name")
                errors_found = True
            else:
                sched = GetSchedule(state, schedule_name)
                if sched is None:
                    ShowSevereItemNotFound(state, eoh, "schedule_name", schedule_name)
                    errors_found = True
                else:
                    exterior_equip.sched = sched
                    sch_min = sched.getMinVal(state)
                    if sch_min < 0.0:
                        ShowSevereCustom(state, eoh, f"schedule_name = {schedule_name} minimum is [{sch_min}]. Values must be >= 0.0.")
                        errors_found = True

            if "end_use_subcategory" in water_equip_fields:
                end_use_subcategory_name = input_processor.getAlphaFieldValue(water_equip_fields, exterior_water_schema_props, "end_use_subcategory")
            else:
                end_use_subcategory_name = "General"

            exterior_equip.DesignLevel = input_processor.getRealFieldValue(water_equip_fields, exterior_water_schema_props, "design_level")

            SetupOutputVariable(state,
                               "Exterior Equipment Water Volume Flow Rate",
                               Units.m3_s,
                               exterior_equip.Power,
                               TimeStepType.Zone,
                               StoreType.Average,
                               exterior_equip.Name)

            SetupOutputVariable(state,
                               "Exterior Equipment Water Volume",
                               Units.m3,
                               exterior_equip.CurrentUse,
                               TimeStepType.Zone,
                               StoreType.Sum,
                               exterior_equip.Name,
                               eResource.Water,
                               Group.Invalid,
                               EndUseCat.ExteriorEquipment,
                               end_use_subcategory_name)
            SetupOutputVariable(state,
                               "Exterior Equipment Mains Water Volume",
                               Units.m3,
                               exterior_equip.CurrentUse,
                               TimeStepType.Zone,
                               StoreType.Sum,
                               exterior_equip.Name,
                               eResource.MainsWater,
                               Group.Invalid,
                               EndUseCat.ExteriorEquipment,
                               end_use_subcategory_name)

    if errors_found:
        ShowFatalError(state, f"{routine_name}Errors found in input.  Program terminates.")


def ReportExteriorEnergyUse(state: Any) -> None:
    for item in range(state.dataExteriorEnergyUse.NumExteriorLights):
        control_mode = state.dataExteriorEnergyUse.ExteriorLights[item].ControlMode
        
        if control_mode == LightControlType.ScheduleOnly:
            state.dataExteriorEnergyUse.ExteriorLights[item].Power = (
                state.dataExteriorEnergyUse.ExteriorLights[item].DesignLevel *
                state.dataExteriorEnergyUse.ExteriorLights[item].sched.getCurrentVal()
            )
            state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse = (
                state.dataExteriorEnergyUse.ExteriorLights[item].Power *
                state.dataGlobal.TimeStepZoneSec
            )
        elif control_mode == LightControlType.AstroClockOverride:
            if state.dataEnvrn.SunIsUp:
                state.dataExteriorEnergyUse.ExteriorLights[item].Power = 0.0
                state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse = 0.0
            else:
                state.dataExteriorEnergyUse.ExteriorLights[item].Power = (
                    state.dataExteriorEnergyUse.ExteriorLights[item].DesignLevel *
                    state.dataExteriorEnergyUse.ExteriorLights[item].sched.getCurrentVal()
                )
                state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse = (
                    state.dataExteriorEnergyUse.ExteriorLights[item].Power *
                    state.dataGlobal.TimeStepZoneSec
                )

        if (state.dataExteriorEnergyUse.ExteriorLights[item].ManageDemand and
            state.dataExteriorEnergyUse.ExteriorLights[item].Power > state.dataExteriorEnergyUse.ExteriorLights[item].DemandLimit):
            state.dataExteriorEnergyUse.ExteriorLights[item].Power = state.dataExteriorEnergyUse.ExteriorLights[item].DemandLimit
            state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse = (
                state.dataExteriorEnergyUse.ExteriorLights[item].Power *
                state.dataGlobal.TimeStepZoneSec
            )
        
        if state.dataExteriorEnergyUse.ExteriorLights[item].PowerActuatorOn:
            state.dataExteriorEnergyUse.ExteriorLights[item].Power = state.dataExteriorEnergyUse.ExteriorLights[item].PowerActuatorValue

        state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse = (
            state.dataExteriorEnergyUse.ExteriorLights[item].Power *
            state.dataGlobal.TimeStepZoneSec
        )

        if not state.dataGlobal.WarmupFlag:
            if (state.dataGlobal.DoOutputReporting and
                state.dataGlobal.KindOfSim == KindOfSim.RunPeriodWeather):
                state.dataExteriorEnergyUse.ExteriorLights[item].SumConsumption += state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse
                if state.dataExteriorEnergyUse.ExteriorLights[item].CurrentUse > 0.01:
                    state.dataExteriorEnergyUse.ExteriorLights[item].SumTimeNotZeroCons += state.dataGlobal.TimeStepZone

    for item in range(state.dataExteriorEnergyUse.NumExteriorEqs):
        state.dataExteriorEnergyUse.ExteriorEquipment[item].Power = (
            state.dataExteriorEnergyUse.ExteriorEquipment[item].DesignLevel *
            state.dataExteriorEnergyUse.ExteriorEquipment[item].sched.getCurrentVal()
        )
        state.dataExteriorEnergyUse.ExteriorEquipment[item].CurrentUse = (
            state.dataExteriorEnergyUse.ExteriorEquipment[item].Power *
            state.dataGlobal.TimeStepZoneSec
        )


def GetSchedule(state: Any, schedule_name: str) -> Optional[Any]:
    pass

def SetupOutputVariable(state: Any, *args: Any) -> None:
    pass

def SetupEMSActuator(state: Any, *args: Any) -> None:
    pass

def PreDefTableEntry(state: Any, *args: Any) -> None:
    pass

def ShowSevereEmptyField(state: Any, eoh: Any, field: str) -> None:
    pass

def ShowSevereItemNotFound(state: Any, eoh: Any, field: str, value: str) -> None:
    pass

def ShowSevereCustom(state: Any, eoh: Any, msg: str) -> None:
    pass

def ShowSevereInvalidKey(state: Any, eoh: Any, field: str, value: str) -> None:
    pass

def ShowFatalError(state: Any, msg: str) -> None:
    pass

def VerifyUniqueInterObjectName(state: Any, names_dict: Dict[str, str], name: str, module: str, field: str, errors_found: bool) -> None:
    pass

def SameString(s1: str, s2: str) -> bool:
    return s1.upper() == s2.upper()

def getEnumValue(names_uc: Dict[str, int], name: str) -> int:
    return names_uc.get(name.upper(), -1)

class Units:
    W = "W"
    J = "J"
    m3_s = "m3/s"
    m3 = "m3"

class TimeStepType:
    Zone = 1

class StoreType:
    Average = 1
    Sum = 2

class Group:
    Invalid = 0

class EndUseCat:
    ExteriorLights = 1
    ExteriorEquipment = 2

class eResource:
    Electricity = 1
    Water = 2
    MainsWater = 3

class KindOfSim:
    RunPeriodWeather = 1

class eFuel:
    Invalid = -1
    Water = 1

eFuelNames = {-1: "Invalid", 1: "Water"}
eFuelNamesUC = {"WATER": 1}
eFuel2eResource = {-1: 0, 1: 2}
