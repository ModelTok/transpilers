# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from dataclasses import dataclass, field
from typing import Optional, Dict, Any, Protocol
from abc import ABC, abstractmethod
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object carrying all module data
# - PlantComponent: abstract base class for plant equipment
# - BaseGlobalStruct: abstract base class for global data structs
# - DataPlant.PlantEquipmentType: enum for equipment types
# - DataPlant.PlantLocation: location struct for plant loop topology
# - PlantUtilities: InitComponentNodes, SetComponentFlowRate, ScanPlantLoopsForObject, RegisterPlantCompDesignFlow
# - Sched.Schedule: schedule object type
# - Sched.GetScheduleAlwaysOn, Sched.GetSchedule: schedule retrieval
# - Node.GetOnlySingleNode, Node.TestCompSet: node management
# - Node.ConnectionObjectType, Node.FluidType, Node.ConnectionType, Node.CompFluidStream: node enums
# - InputProcessor: getNumObjectsFound, getObjectItem
# - OutputProcessor: SetupOutputVariable, EndUseCat
# - GlobalNames.VerifyUniqueInterObjectName: name verification
# - FluidProperties: glycol/steam property objects with methods
# - ScheduleManager: GetScheduleAlwaysOn, GetSchedule
# - EnergyPlus utilities: ShowFatalError, ShowSevereError, ShowSevereItemNotFound, ShowMessage, ShowContinueError, ShowWarningBadMin
# - Constant: InitConvTemp, eResource, Units enum values
# - DataSizing.AutoSize, DataEnvironment.StdPressureSeaLevel, DataHVACGlobals.TimeStepSysSec
# - BaseSizer.reportSizerOutput
# - Array1D: 1-D array type
# - ErrorObjectHeader: error tracking structure
# - Clusive enum: for inclusive/exclusive comparisons


class PlantComponent(ABC):
    @abstractmethod
    def simulate(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation',
                 first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
        pass

    @abstractmethod
    def onInitLoopEquip(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation') -> None:
        pass

    @abstractmethod
    def getDesignCapacities(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation') -> tuple:
        pass

    @abstractmethod
    def oneTimeInit(self, state: 'EnergyPlusData') -> None:
        pass

    @abstractmethod
    def oneTimeInit_new(self, state: 'EnergyPlusData') -> None:
        pass


class BaseGlobalStruct(ABC):
    @abstractmethod
    def init_constant_state(self, state: 'EnergyPlusData') -> None:
        pass

    @abstractmethod
    def init_state(self, state: 'EnergyPlusData') -> None:
        pass

    @abstractmethod
    def clear_state(self) -> None:
        pass


@dataclass
class OutsideEnergySourceSpecs(PlantComponent):
    Name: str = ""
    NomCap: float = 0.0
    NomCapWasAutoSized: bool = False
    capFractionSched: Optional[Any] = None
    InletNodeNum: int = 0
    OutletNodeNum: int = 0
    EnergyTransfer: float = 0.0
    EnergyRate: float = 0.0
    EnergyType: Any = None
    plantLoc: Optional['PlantLocation'] = None
    BeginEnvrnInitFlag: bool = True
    CheckEquipName: bool = True
    MassFlowRate: float = 0.0
    InletTemp: float = 0.0
    OutletTemp: float = 0.0
    OutletSteamQuality: float = 0.0

    def __post_init__(self):
        if self.plantLoc is None:
            self.plantLoc = create_plant_location()
        if self.EnergyType is None:
            self.EnergyType = get_invalid_equipment_type()

    @staticmethod
    def factory(state: 'EnergyPlusData', object_type: Any, object_name: str) -> Optional['OutsideEnergySourceSpecs']:
        if state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag:
            GetOutsideEnergySourcesInput(state)
            state.dataOutsideEnergySrcs.SimOutsideEnergyGetInputFlag = False

        for source in state.dataOutsideEnergySrcs.EnergySource:
            if source.EnergyType == object_type and source.Name == object_name:
                return source

        ShowFatalError(state, f"OutsideEnergySourceSpecsFactory: Error getting inputs for source named: {object_name}")
        return None

    def simulate(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation',
                 first_hvac_iteration: bool, cur_load: float, run_flag: bool) -> None:
        self.initialize(state, cur_load)
        self.calculate(state, run_flag, cur_load)

    def onInitLoopEquip(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation') -> None:
        self.initialize(state, 0.0)
        self.size(state)

    def getDesignCapacities(self, state: 'EnergyPlusData', called_from_location: 'PlantLocation') -> tuple:
        min_load = 0.0
        max_load = self.NomCap
        opt_load = self.NomCap
        return (max_load, min_load, opt_load)

    def initialize(self, state: 'EnergyPlusData', my_load: float) -> None:
        loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]

        if state.dataGlobal.BeginEnvrnFlag and self.BeginEnvrnInitFlag:
            PlantUtilities_InitComponentNodes(state, loop.MinMassFlowRate, loop.MaxMassFlowRate,
                                             self.InletNodeNum, self.OutletNodeNum)
            self.BeginEnvrnInitFlag = False

        if not state.dataGlobal.BeginEnvrnFlag:
            self.BeginEnvrnInitFlag = True

        temp_plant_mass_flow = 0.0
        if abs(my_load) > 0.0:
            temp_plant_mass_flow = loop.MaxMassFlowRate

        PlantUtilities_SetComponentFlowRate(state, temp_plant_mass_flow, self.InletNodeNum,
                                           self.OutletNodeNum, self.plantLoc)

        self.InletTemp = state.dataLoopNodes.Node[self.InletNodeNum].Temp
        self.MassFlowRate = temp_plant_mass_flow

    def size(self, state: 'EnergyPlusData') -> None:
        errors_found = False

        type_name = get_plant_equip_type_name(self.EnergyType)

        loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]
        plt_siz_num = loop.PlantSizNum

        if plt_siz_num > 0:
            if (self.EnergyType == get_purch_chilled_water_type() or
                self.EnergyType == get_purch_hot_water_type()):
                rho = loop.glycol.getDensity(state, get_init_conv_temp(), f"Size {type_name}")
                cp = loop.glycol.getSpecificHeat(state, get_init_conv_temp(), f"Size {type_name}")
                nom_cap_des = cp * rho * state.dataSize.PlantSizData[plt_siz_num].DeltaT * \
                              state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate
            else:
                temp_steam = loop.steam.getSatTemperature(state, get_std_baro_press(), f"Size {type_name}")
                rho_steam = loop.steam.getSatDensity(state, temp_steam, 1.0, f"Size {type_name}")
                enth_steam_dry = loop.steam.getSatEnthalpy(state, temp_steam, 1.0, f"Size {type_name}")
                enth_steam_wet = loop.steam.getSatEnthalpy(state, temp_steam, 0.0, f"Size {type_name}")
                latent_heat_steam = enth_steam_dry - enth_steam_wet
                nom_cap_des = rho_steam * state.dataSize.PlantSizData[plt_siz_num].DesVolFlowRate * latent_heat_steam

            if state.dataPlnt.PlantFirstSizesOkayToFinalize:
                if self.NomCapWasAutoSized:
                    self.NomCap = nom_cap_des
                    if state.dataPlnt.PlantFinalSizesOkayToReport:
                        BaseSizer_reportSizerOutput(state, type_name, self.Name,
                                                   "Design Size Nominal Capacity [W]", nom_cap_des)
                    if state.dataPlnt.PlantFirstSizesOkayToReport:
                        BaseSizer_reportSizerOutput(state, type_name, self.Name,
                                                   "Initial Design Size Nominal Capacity [W]", nom_cap_des)
                else:
                    if self.NomCap > 0.0 and nom_cap_des > 0.0:
                        nom_cap_user = self.NomCap
                        if state.dataPlnt.PlantFinalSizesOkayToReport:
                            BaseSizer_reportSizerOutput(state, type_name, self.Name,
                                                       "Design Size Nominal Capacity [W]", nom_cap_des,
                                                       "User-Specified Nominal Capacity [W]", nom_cap_user)
                            if state.dataGlobal.DisplayExtraWarnings:
                                if (abs(nom_cap_des - nom_cap_user) / nom_cap_user) > state.dataSize.AutoVsHardSizingThreshold:
                                    ShowMessage(state, f"Size {type_name}: Potential issue with equipment sizing for {self.Name}")
                                    ShowContinueError(state, f"User-Specified Nominal Capacity of {nom_cap_user:.2e} [W]")
                                    ShowContinueError(state, f"differs from Design Size Nominal Capacity of {nom_cap_des:.2e} [W]")
                                    ShowContinueError(state, "This may, or may not, indicate mismatched component sizes.")
                                    ShowContinueError(state, "Verify that the value entered is intended and is consistent with other components.")
        else:
            if self.NomCapWasAutoSized and state.dataPlnt.PlantFirstSizesOkayToFinalize:
                ShowSevereError(state, f"Autosizing of {type_name} nominal capacity requires a loop Sizing:Plant object")
                ShowContinueError(state, f"Occurs in {type_name} object={self.Name}")
                errors_found = True
            if not self.NomCapWasAutoSized and self.NomCap > 0.0 and state.dataPlnt.PlantFinalSizesOkayToReport:
                BaseSizer_reportSizerOutput(state, type_name, self.Name, "User-Specified Nominal Capacity [W]", self.NomCap)

        if errors_found:
            ShowFatalError(state, "Preceding sizing errors cause program termination")

    def calculate(self, state: 'EnergyPlusData', run_flag: bool, my_load: float) -> None:
        loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]

        loop_num = self.plantLoc.loopNum
        loop_min_temp = state.dataPlnt.PlantLoop[loop_num].MinTemp
        loop_max_temp = state.dataPlnt.PlantLoop[loop_num].MaxTemp
        loop_min_mdot = state.dataPlnt.PlantLoop[loop_num].MinMassFlowRate
        loop_max_mdot = state.dataPlnt.PlantLoop[loop_num].MaxMassFlowRate

        cap_fraction = self.capFractionSched.getCurrentVal()
        cap_fraction = max(0.0, cap_fraction)
        current_cap = self.NomCap * cap_fraction
        if abs(my_load) > current_cap:
            my_load = math.copysign(current_cap, my_load)

        if self.EnergyType == get_purch_chilled_water_type():
            if my_load > 0.0:
                my_load = 0.0
        elif self.EnergyType == get_purch_hot_water_type() or self.EnergyType == get_purch_steam_type():
            if my_load < 0.0:
                my_load = 0.0

        if self.MassFlowRate > 0.0 and run_flag:
            if (self.EnergyType == get_purch_chilled_water_type() or
                self.EnergyType == get_purch_hot_water_type()):
                cp = state.dataPlnt.PlantLoop[loop_num].glycol.getSpecificHeat(state, self.InletTemp, "SimDistrictEnergy")
                self.OutletTemp = (my_load + self.MassFlowRate * cp * self.InletTemp) / (self.MassFlowRate * cp)

                if self.OutletTemp < loop_min_temp:
                    self.OutletTemp = max(self.OutletTemp, loop_min_temp)
                    my_load = self.MassFlowRate * cp * (self.OutletTemp - self.InletTemp)
                if self.OutletTemp > loop_max_temp:
                    self.OutletTemp = min(self.OutletTemp, loop_max_temp)
                    my_load = self.MassFlowRate * cp * (self.OutletTemp - self.InletTemp)

            elif self.EnergyType == get_purch_steam_type():
                sat_temp_atm_press = loop.steam.getSatTemperature(state, get_std_pressure_sea_level(), "SimDistrictEnergy")
                cp_condensate = loop.glycol.getSpecificHeat(state, self.InletTemp, "SimDistrictEnergy")
                delta_t_sensible = sat_temp_atm_press - self.InletTemp
                enth_steam_in_dry = loop.steam.getSatEnthalpy(state, self.InletTemp, 1.0, "SimDistrictEnergy")
                enth_steam_out_wet = loop.steam.getSatEnthalpy(state, self.InletTemp, 0.0, "SimDistrictEnergy")
                latent_heat_steam = enth_steam_in_dry - enth_steam_out_wet
                self.MassFlowRate = my_load / (latent_heat_steam + (cp_condensate * delta_t_sensible))
                PlantUtilities_SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum,
                                                   self.OutletNodeNum, self.plantLoc)
                self.OutletTemp = state.dataLoopNodes.Node[loop.TempSetPointNodeNum].TempSetPoint
                self.OutletSteamQuality = 0.0

                if self.MassFlowRate < loop_min_mdot:
                    self.MassFlowRate = max(self.MassFlowRate, loop_min_mdot)
                    PlantUtilities_SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum,
                                                       self.OutletNodeNum, self.plantLoc)
                    my_load = self.MassFlowRate * latent_heat_steam
                if self.MassFlowRate > loop_max_mdot:
                    self.MassFlowRate = min(self.MassFlowRate, loop_max_mdot)
                    PlantUtilities_SetComponentFlowRate(state, self.MassFlowRate, self.InletNodeNum,
                                                       self.OutletNodeNum, self.plantLoc)
                    my_load = self.MassFlowRate * latent_heat_steam

                state.dataLoopNodes.Node[self.OutletNodeNum].Quality = 1.0
        else:
            self.OutletTemp = self.InletTemp
            my_load = 0.0

        outlet_node = self.OutletNodeNum
        state.dataLoopNodes.Node[outlet_node].Temp = self.OutletTemp
        self.EnergyRate = abs(my_load)
        self.EnergyTransfer = self.EnergyRate * state.dataHVACGlobal.TimeStepSysSec

    def oneTimeInit(self, state: 'EnergyPlusData') -> None:
        pass

    def oneTimeInit_new(self, state: 'EnergyPlusData') -> None:
        err_flag = False
        PlantUtilities_ScanPlantLoopsForObject(state, self.Name, self.EnergyType, self.plantLoc, err_flag)

        if err_flag:
            ShowFatalError(state, "InitSimVars: Program terminated due to previous condition(s).")

        loop = state.dataPlnt.PlantLoop[self.plantLoc.loopNum]
        get_plant_component(state, self.plantLoc).MinOutletTemp = loop.MinTemp
        get_plant_component(state, self.plantLoc).MaxOutletTemp = loop.MaxTemp
        PlantUtilities_RegisterPlantCompDesignFlow(state, self.InletNodeNum, loop.MaxVolFlowRate)

        report_var_prefix = "District Heating Water "
        heating_or_cooling = get_heating_end_use_cat()
        meter_type_key = get_district_heating_water_resource()

        if self.EnergyType == get_purch_chilled_water_type():
            report_var_prefix = "District Cooling Water "
            heating_or_cooling = get_cooling_end_use_cat()
            meter_type_key = get_district_cooling_resource()
        elif self.EnergyType == get_purch_steam_type():
            report_var_prefix = "District Heating Steam "
            heating_or_cooling = get_heating_end_use_cat()
            meter_type_key = get_district_heating_steam_resource()

        SetupOutputVariable(state, f"{report_var_prefix}Energy", "J", self.EnergyTransfer,
                           "System", "Sum", self.Name, meter_type_key, "Plant", heating_or_cooling)
        SetupOutputVariable(state, f"{report_var_prefix}Rate", "W", self.EnergyRate,
                           "System", "Average", self.Name)
        SetupOutputVariable(state, f"{report_var_prefix}Inlet Temperature", "C", self.InletTemp,
                           "System", "Average", self.Name)
        SetupOutputVariable(state, f"{report_var_prefix}Outlet Temperature", "C", self.OutletTemp,
                           "System", "Average", self.Name)
        SetupOutputVariable(state, f"{report_var_prefix}Mass Flow Rate", "kg/s", self.MassFlowRate,
                           "System", "Average", self.Name)


def GetOutsideEnergySourcesInput(state: 'EnergyPlusData') -> None:
    num_district_units_heat_water = InputProcessor_getNumObjectsFound(state, "DistrictHeating:Water")
    num_district_units_cool = InputProcessor_getNumObjectsFound(state, "DistrictCooling")
    num_district_units_heat_steam = InputProcessor_getNumObjectsFound(state, "DistrictHeating:Steam")
    state.dataOutsideEnergySrcs.NumDistrictUnits = num_district_units_heat_water + num_district_units_cool + num_district_units_heat_steam

    if len(state.dataOutsideEnergySrcs.EnergySource) > 0:
        return

    state.dataOutsideEnergySrcs.EnergySource = [
        OutsideEnergySourceSpecs() for _ in range(state.dataOutsideEnergySrcs.NumDistrictUnits)
    ]

    errors_found = False
    heat_water_index = 0
    cool_index = 0
    heat_steam_index = 0

    for energy_source_num in range(state.dataOutsideEnergySrcs.NumDistrictUnits):
        if energy_source_num < num_district_units_heat_water:
            current_module_object = "DistrictHeating:Water"
            obj_type = get_connection_object_type_heat_water()
            node_names = "Hot Water Nodes"
            energy_type = get_purch_hot_water_type()
            heat_water_index += 1
            this_index = heat_water_index
        elif energy_source_num < num_district_units_heat_water + num_district_units_cool:
            current_module_object = "DistrictCooling"
            obj_type = get_connection_object_type_cool()
            node_names = "Chilled Water Nodes"
            energy_type = get_purch_chilled_water_type()
            cool_index += 1
            this_index = cool_index
        else:
            current_module_object = "DistrictHeating:Steam"
            obj_type = get_connection_object_type_heat_steam()
            node_names = "Steam Nodes"
            energy_type = get_purch_steam_type()
            heat_steam_index += 1
            this_index = heat_steam_index

        alpha_args, num_alphas, num_nums = InputProcessor_getObjectItem(
            state, current_module_object, this_index)

        eoh = ErrorObjectHeader(current_module_object, alpha_args[0])

        if energy_source_num > 0:
            GlobalNames_VerifyUniqueInterObjectName(state,
                                                   state.dataOutsideEnergySrcs.EnergySourceUniqueNames,
                                                   alpha_args[0],
                                                   current_module_object,
                                                   errors_found)

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].Name = alpha_args[0]

        if energy_source_num < num_district_units_heat_water + num_district_units_cool:
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].InletNodeNum = Node_GetOnlySingleNode(
                state, alpha_args[1], errors_found, obj_type, alpha_args[0],
                get_fluid_type_water(), get_connection_type_inlet(),
                get_comp_fluid_stream_primary())
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].OutletNodeNum = Node_GetOnlySingleNode(
                state, alpha_args[2], errors_found, obj_type, alpha_args[0],
                get_fluid_type_water(), get_connection_type_outlet(),
                get_comp_fluid_stream_primary())
        else:
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].InletNodeNum = Node_GetOnlySingleNode(
                state, alpha_args[1], errors_found, obj_type, alpha_args[0],
                get_fluid_type_steam(), get_connection_type_inlet(),
                get_comp_fluid_stream_primary())
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].OutletNodeNum = Node_GetOnlySingleNode(
                state, alpha_args[2], errors_found, obj_type, alpha_args[0],
                get_fluid_type_steam(), get_connection_type_outlet(),
                get_comp_fluid_stream_primary())

        Node_TestCompSet(state, current_module_object, alpha_args[0], alpha_args[1], alpha_args[2], node_names)

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].NomCap = get_numeric_arg(state, 0)
        if state.dataOutsideEnergySrcs.EnergySource[energy_source_num].NomCap == get_auto_size():
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].NomCapWasAutoSized = True

        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyTransfer = 0.0
        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyRate = 0.0
        state.dataOutsideEnergySrcs.EnergySource[energy_source_num].EnergyType = energy_type

        if is_alpha_field_blank(state, 3):
            state.dataOutsideEnergySrcs.EnergySource[energy_source_num].capFractionSched = \
                Sched_GetScheduleAlwaysOn(state)
        else:
            sched = Sched_GetSchedule(state, alpha_args[3])
            if sched is None:
                ShowSevereItemNotFound(state, eoh, "Capacity Fraction Schedule Name", alpha_args[3])
                errors_found = True
            else:
                state.dataOutsideEnergySrcs.EnergySource[energy_source_num].capFractionSched = sched
                if not sched.checkMinVal(state, 0.0):
                    Sched_ShowWarningBadMin(state, eoh, "Capacity Fraction Schedule Name", alpha_args[3], 0.0,
                                           "Negative values will be treated as zero, and the simulation continues.")

    if errors_found:
        ShowFatalError(state, f"Errors found in processing input for {current_module_object}, "
                              f"Preceding condition caused termination.")


@dataclass
class OutsideEnergySourcesData(BaseGlobalStruct):
    NumDistrictUnits: int = 0
    SimOutsideEnergyGetInputFlag: bool = True
    EnergySource: list = field(default_factory=list)
    EnergySourceUniqueNames: Dict[str, str] = field(default_factory=dict)

    def init_constant_state(self, state: 'EnergyPlusData') -> None:
        pass

    def init_state(self, state: 'EnergyPlusData') -> None:
        pass

    def clear_state(self) -> None:
        self.NumDistrictUnits = 0
        self.SimOutsideEnergyGetInputFlag = True
        self.EnergySource = []
        self.EnergySourceUniqueNames.clear()


def InitSimVars(energy_source_num: int, my_load: float) -> None:
    pass


def PlantUtilities_InitComponentNodes(state: 'EnergyPlusData', min_mass_flow: float, max_mass_flow: float,
                                      inlet_node: int, outlet_node: int) -> None:
    pass


def PlantUtilities_SetComponentFlowRate(state: 'EnergyPlusData', flow_rate: float, inlet_node: int,
                                        outlet_node: int, plant_loc: 'PlantLocation') -> None:
    pass


def PlantUtilities_ScanPlantLoopsForObject(state: 'EnergyPlusData', name: str, equip_type: Any,
                                          plant_loc: 'PlantLocation', err_flag: bool) -> None:
    pass


def PlantUtilities_RegisterPlantCompDesignFlow(state: 'EnergyPlusData', node_num: int, design_vol_flow: float) -> None:
    pass


def InputProcessor_getNumObjectsFound(state: 'EnergyPlusData', obj_name: str) -> int:
    return 0


def InputProcessor_getObjectItem(state: 'EnergyPlusData', obj_type: str, obj_index: int) -> tuple:
    return ([], 0, 0)


def Node_GetOnlySingleNode(state: 'EnergyPlusData', node_name: str, errors_found: bool, obj_type: Any,
                          obj_name: str, fluid_type: Any, connection_type: Any,
                          comp_fluid_stream: Any) -> int:
    return 0


def Node_TestCompSet(state: 'EnergyPlusData', obj_type: str, obj_name: str, inlet: str, outlet: str, node_names: str) -> None:
    pass


def GlobalNames_VerifyUniqueInterObjectName(state: 'EnergyPlusData', name_dict: Dict[str, str],
                                           name: str, obj_type: str, errors_found: bool) -> None:
    pass


def Sched_GetScheduleAlwaysOn(state: 'EnergyPlusData') -> Any:
    return None


def Sched_GetSchedule(state: 'EnergyPlusData', sched_name: str) -> Any:
    return None


def ShowFatalError(state: 'EnergyPlusData', msg: str) -> None:
    raise RuntimeError(msg)


def ShowSevereError(state: 'EnergyPlusData', msg: str) -> None:
    pass


def ShowSevereItemNotFound(state: 'EnergyPlusData', eoh: 'ErrorObjectHeader', field_name: str, field_value: str) -> None:
    pass


def ShowMessage(state: 'EnergyPlusData', msg: str) -> None:
    pass


def ShowContinueError(state: 'EnergyPlusData', msg: str) -> None:
    pass


def BaseSizer_reportSizerOutput(state: 'EnergyPlusData', type_name: str, obj_name: str, *args) -> None:
    pass


def SetupOutputVariable(state: 'EnergyPlusData', var_name: str, *args) -> None:
    pass


def get_plant_location() -> 'PlantLocation':
    return None


def create_plant_location() -> 'PlantLocation':
    return None


def get_invalid_equipment_type() -> Any:
    return None


def get_purch_hot_water_type() -> Any:
    return None


def get_purch_chilled_water_type() -> Any:
    return None


def get_purch_steam_type() -> Any:
    return None


def get_plant_equip_type_name(equip_type: Any) -> str:
    return ""


def get_init_conv_temp() -> float:
    return 20.0


def get_std_baro_press() -> float:
    return 101325.0


def get_std_pressure_sea_level() -> float:
    return 101325.0


def get_heating_end_use_cat() -> Any:
    return None


def get_cooling_end_use_cat() -> Any:
    return None


def get_district_heating_water_resource() -> Any:
    return None


def get_district_cooling_resource() -> Any:
    return None


def get_district_heating_steam_resource() -> Any:
    return None


def get_connection_object_type_heat_water() -> Any:
    return None


def get_connection_object_type_cool() -> Any:
    return None


def get_connection_object_type_heat_steam() -> Any:
    return None


def get_fluid_type_water() -> Any:
    return None


def get_fluid_type_steam() -> Any:
    return None


def get_connection_type_inlet() -> Any:
    return None


def get_connection_type_outlet() -> Any:
    return None


def get_comp_fluid_stream_primary() -> Any:
    return None


def get_auto_size() -> float:
    return -99999.0


def get_numeric_arg(state: 'EnergyPlusData', index: int) -> float:
    return 0.0


def is_alpha_field_blank(state: 'EnergyPlusData', index: int) -> bool:
    return False


def get_plant_component(state: 'EnergyPlusData', plant_loc: 'PlantLocation') -> Any:
    return None


class ErrorObjectHeader:
    def __init__(self, obj_type: str, obj_name: str):
        self.ObjectType = obj_type
        self.ObjectName = obj_name


class PlantLocation:
    def __init__(self, loop_num: int = 0, loop_side_num: int = 0, branch_num: int = 0, comp_num: int = 0):
        self.loopNum = loop_num
        self.loopSideNum = loop_side_num
        self.branchNum = branch_num
        self.compNum = comp_num
