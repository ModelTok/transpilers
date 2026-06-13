# EXTERNAL DEPS (to wire in glue):
# - state.dataHighTempRadSys: Container for HighTempRadiantSystemData array and global flags
# - state.dataInputProcessing.inputProcessor: Input processor for reading object items
# - state.dataIPShortCut: Short cuts for input processing (cAlphaArgs, rNumericArgs, etc.)
# - state.dataHeatBal: Heat balance data including Zone array
# - state.dataSurface: Surface data
# - state.dataHeatBalFanSys: Heat balance fan system data with radiant distribution arrays
# - state.dataZoneTempPredictorCorrector: Zone heat balance state (MAT, MRT)
# - state.dataHVACGlobal: Global HVAC state (SysTimeElapsed, TimeStepSys, TimeStepZone)
# - state.dataGlobal: Global state flags and NumOfZones
# - state.dataSize: Sizing arrays and methods
# - state.dataZoneEquip: Zone equipment state
# - Constant: Resource type enumeration (NaturalGas, Electricity, eResourceNamesUC)
# - DataSizing: Sizing type enumeration (DesignSizingType, DesignSizingTypeNamesUC)
# - Sched: Schedule interface (GetScheduleAlwaysOn, GetSchedule, Schedule)
# - Util: Utility functions (FindItemInList)
# - HeatBalanceIntRadExchange: GetRadiantSystemSurface function
# - HeatBalanceSurfaceManager: CalcHeatBalanceOutsideSurf, CalcHeatBalanceInsideSurf
# - OutputProcessor: Output variable setup and units
# - Error reporting: ShowFatalError, ShowSevereError, ShowWarningError, ShowContinueError, etc.
# - HeatingCapacitySizer: Sizing class for heating capacity
# - HVAC: Sizing method constants

from enum import IntEnum
from typing import Optional, List
from dataclasses import dataclass, field
import math


class RadControlType(IntEnum):
    Invalid = -1
    MATControl = 0
    MRTControl = 1
    OperativeControl = 2
    MATSPControl = 3
    MRTSPControl = 4
    OperativeSPControl = 5
    Num = 6


RAD_CONTROL_TYPE_NAMES_UC = [
    "MEANAIRTEMPERATURE",
    "MEANRADIANTTEMPERATURE",
    "OPERATIVETEMPERATURE",
    "MEANAIRTEMPERATURESETPOINT",
    "MEANRADIANTTEMPERATURESETPOINT",
    "OPERATIVETEMPERATURESETPOINT"
]


@dataclass
class HighTempRadiantSystemData:
    Name: str = ""
    availSched: Optional[object] = None
    ZonePtr: int = 0
    HeaterType: object = None
    MaxPowerCapac: float = 0.0
    CombustionEffic: float = 0.0
    FracRadiant: float = 0.0
    FracLatent: float = 0.0
    FracLost: float = 0.0
    FracConvect: float = 0.0
    ControlType: RadControlType = RadControlType.Invalid
    ThrottlRange: float = 0.0
    setptSched: Optional[object] = None
    FracDistribPerson: float = 0.0
    TotSurfToDistrib: int = 0
    SurfaceName: List[str] = field(default_factory=list)
    SurfacePtr: List[int] = field(default_factory=list)
    FracDistribToSurf: List[float] = field(default_factory=list)
    
    ZeroHTRSourceSumHATsurf: float = 0.0
    QHTRRadSource: float = 0.0
    QHTRRadSrcAvg: float = 0.0
    LastSysTimeElapsed: float = 0.0
    LastTimeStepSys: float = 0.0
    LastQHTRRadSrc: float = 0.0
    
    ElecPower: float = 0.0
    ElecEnergy: float = 0.0
    GasPower: float = 0.0
    GasEnergy: float = 0.0
    HeatPower: float = 0.0
    HeatEnergy: float = 0.0
    HeatingCapMethod: object = None
    ScaledHeatingCapacity: float = 0.0


@dataclass
class HighTempRadSysNumericFieldData:
    FieldNames: List[str] = field(default_factory=list)


def get_enum_value(names_uc: List[str], name: str) -> int:
    """Helper to get enum value from uppercase names list."""
    try:
        return names_uc.index(name.upper())
    except ValueError:
        return -1


def sim_high_temp_radiant_system(state, comp_name: str, first_hvac_iteration: bool):
    """
    Main manager subroutine for high temperature radiant system.
    """
    if state.dataHighTempRadSys.GetInputFlag:
        errors_found = False
        get_high_temp_radiant_system(state, errors_found)
        if errors_found:
            state.show_fatal_error(state, "GetHighTempRadiantSystem: Errors found in input. Preceding condition(s) cause termination.")
        state.dataHighTempRadSys.GetInputFlag = False
    
    # Find system by name if CompIndex is 0
    rad_sys_num = None
    for i, sys in enumerate(state.dataHighTempRadSys.HighTempRadSys):
        if sys.Name == comp_name:
            rad_sys_num = i
            break
    
    if rad_sys_num is None:
        state.show_fatal_error(state, f"SimHighTempRadiantSystem: Unit not found={comp_name}")
    
    init_high_temp_radiant_system(state, first_hvac_iteration, rad_sys_num)
    
    rad_sys = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    if rad_sys.ControlType in [RadControlType.MATControl, RadControlType.MRTControl, RadControlType.OperativeControl]:
        calc_high_temp_radiant_system(state, rad_sys_num)
    elif rad_sys.ControlType in [RadControlType.MATSPControl, RadControlType.MRTSPControl, RadControlType.OperativeSPControl]:
        calc_high_temp_radiant_system_sp(state, first_hvac_iteration, rad_sys_num)
    
    load_met = update_high_temp_radiant_system(state, rad_sys_num)
    report_high_temp_radiant_system(state, rad_sys_num)
    
    return load_met


def get_high_temp_radiant_system(state, errors_found: bool):
    """
    Read high temperature radiant system input from input file.
    """
    routine_name = "GetHighTempRadiantSystem"
    
    MAX_COMBUSTION_EFFIC = 1.0
    MAX_FRACTION = 1.0
    MIN_COMBUSTION_EFFIC = 0.01
    MIN_FRACTION = 0.0
    MIN_THROTTLING_RANGE = 0.5
    
    num_of_systems = state.dataInputProcessing.inputProcessor.get_num_objects_found(state, "ZoneHVAC:HighTemperatureRadiant")
    
    state.dataHighTempRadSys.NumOfHighTempRadSys = num_of_systems
    state.dataHighTempRadSys.HighTempRadSys = [HighTempRadiantSystemData() for _ in range(num_of_systems)]
    state.dataHighTempRadSys.CheckEquipName = [True] * num_of_systems
    state.dataHighTempRadSys.HighTempRadSysNumericFields = [HighTempRadSysNumericFieldData() for _ in range(num_of_systems)]
    
    for item_idx in range(num_of_systems):
        high_temp_rad_sys = state.dataHighTempRadSys.HighTempRadSys[item_idx]
        
        # Get object item from input processor
        alpha_args, num_args, num_alphas, num_numbers = state.dataInputProcessing.inputProcessor.get_object_item(
            state, "ZoneHVAC:HighTemperatureRadiant", item_idx
        )
        
        state.dataHighTempRadSys.HighTempRadSysNumericFields[item_idx].FieldNames = []
        
        high_temp_rad_sys.Name = alpha_args[0] if len(alpha_args) > 0 else ""
        
        # Availability schedule
        if not alpha_args[1]:
            high_temp_rad_sys.availSched = state.sched_get_schedule_always_on(state)
        else:
            high_temp_rad_sys.availSched = state.sched_get_schedule(state, alpha_args[1])
            if high_temp_rad_sys.availSched is None:
                errors_found = True
        
        # Zone pointer
        high_temp_rad_sys.ZonePtr = state.util_find_item_in_list(alpha_args[2], state.dataHeatBal.Zone)
        if high_temp_rad_sys.ZonePtr < 0:
            errors_found = True
        
        # Heating capacity method
        if len(alpha_args) > 3:
            high_temp_rad_sys.HeatingCapMethod = get_enum_value(state.DataSizing.DesignSizingTypeNamesUC, alpha_args[3])
            
            if high_temp_rad_sys.HeatingCapMethod == state.DataSizing.HeatingDesignCapacity:
                if len(num_args) > 0 and num_args[0] is not None:
                    high_temp_rad_sys.ScaledHeatingCapacity = num_args[0]
                    if high_temp_rad_sys.ScaledHeatingCapacity < 0.0 and high_temp_rad_sys.ScaledHeatingCapacity != state.DataSizing.AutoSize:
                        errors_found = True
                else:
                    errors_found = True
            elif high_temp_rad_sys.HeatingCapMethod == state.DataSizing.CapacityPerFloorArea:
                if len(num_args) > 1 and num_args[1] is not None:
                    high_temp_rad_sys.ScaledHeatingCapacity = num_args[1]
                    if high_temp_rad_sys.ScaledHeatingCapacity <= 0.0:
                        errors_found = True
                    elif high_temp_rad_sys.ScaledHeatingCapacity == state.DataSizing.AutoSize:
                        errors_found = True
                else:
                    errors_found = True
            elif high_temp_rad_sys.HeatingCapMethod == state.DataSizing.FractionOfAutosizedHeatingCapacity:
                if len(num_args) > 2 and num_args[2] is not None:
                    high_temp_rad_sys.ScaledHeatingCapacity = num_args[2]
                    if high_temp_rad_sys.ScaledHeatingCapacity < 0.0:
                        errors_found = True
                else:
                    errors_found = True
        
        # Heater type
        if len(alpha_args) > 4:
            high_temp_rad_sys.HeaterType = alpha_args[4]
            
            if high_temp_rad_sys.HeaterType == "NaturalGas":
                if len(num_args) > 3 and num_args[3] is not None:
                    high_temp_rad_sys.CombustionEffic = num_args[3]
                    if high_temp_rad_sys.CombustionEffic < MIN_COMBUSTION_EFFIC:
                        high_temp_rad_sys.CombustionEffic = MIN_COMBUSTION_EFFIC
                    if high_temp_rad_sys.CombustionEffic > MAX_COMBUSTION_EFFIC:
                        high_temp_rad_sys.CombustionEffic = MAX_COMBUSTION_EFFIC
            else:
                high_temp_rad_sys.CombustionEffic = MAX_COMBUSTION_EFFIC
        
        # Fraction radiant
        if len(num_args) > 4 and num_args[4] is not None:
            high_temp_rad_sys.FracRadiant = num_args[4]
            if high_temp_rad_sys.FracRadiant < MIN_FRACTION:
                high_temp_rad_sys.FracRadiant = MIN_FRACTION
            if high_temp_rad_sys.FracRadiant > MAX_FRACTION:
                high_temp_rad_sys.FracRadiant = MAX_FRACTION
        
        # Fraction latent
        if len(num_args) > 5 and num_args[5] is not None:
            high_temp_rad_sys.FracLatent = num_args[5]
            if high_temp_rad_sys.FracLatent < MIN_FRACTION:
                high_temp_rad_sys.FracLatent = MIN_FRACTION
            if high_temp_rad_sys.FracLatent > MAX_FRACTION:
                high_temp_rad_sys.FracLatent = MAX_FRACTION
        
        # Fraction lost
        if len(num_args) > 6 and num_args[6] is not None:
            high_temp_rad_sys.FracLost = num_args[6]
            if high_temp_rad_sys.FracLost < MIN_FRACTION:
                high_temp_rad_sys.FracLost = MIN_FRACTION
            if high_temp_rad_sys.FracLost > MAX_FRACTION:
                high_temp_rad_sys.FracLost = MAX_FRACTION
        
        # Compute fraction convective
        all_fracs_summed = high_temp_rad_sys.FracRadiant + high_temp_rad_sys.FracLatent + high_temp_rad_sys.FracLost
        if all_fracs_summed > MAX_FRACTION:
            errors_found = True
            high_temp_rad_sys.FracConvect = 0.0
        else:
            high_temp_rad_sys.FracConvect = 1.0 - all_fracs_summed
        
        # Control type
        if len(alpha_args) > 5 and alpha_args[5]:
            high_temp_rad_sys.ControlType = RadControlType(get_enum_value(RAD_CONTROL_TYPE_NAMES_UC, alpha_args[5]))
        else:
            high_temp_rad_sys.ControlType = RadControlType.OperativeControl
        
        # Throttling range
        if len(num_args) > 7 and num_args[7] is not None:
            high_temp_rad_sys.ThrottlRange = num_args[7]
            if high_temp_rad_sys.ThrottlRange < MIN_THROTTLING_RANGE:
                high_temp_rad_sys.ThrottlRange = 1.0
        
        # Setpoint schedule
        if len(alpha_args) > 6 and alpha_args[6]:
            high_temp_rad_sys.setptSched = state.sched_get_schedule(state, alpha_args[6])
            if high_temp_rad_sys.setptSched is None:
                errors_found = True
        else:
            errors_found = True
        
        # Fraction to people
        if len(num_args) > 8 and num_args[8] is not None:
            high_temp_rad_sys.FracDistribPerson = num_args[8]
            if high_temp_rad_sys.FracDistribPerson < MIN_FRACTION:
                high_temp_rad_sys.FracDistribPerson = MIN_FRACTION
            if high_temp_rad_sys.FracDistribPerson > MAX_FRACTION:
                high_temp_rad_sys.FracDistribPerson = MAX_FRACTION
        
        # Surfaces to distribute to
        high_temp_rad_sys.TotSurfToDistrib = len(num_args) - 9
        high_temp_rad_sys.SurfaceName = []
        high_temp_rad_sys.SurfacePtr = []
        high_temp_rad_sys.FracDistribToSurf = []
        
        all_fracs_summed = high_temp_rad_sys.FracDistribPerson
        for surf_num_idx in range(high_temp_rad_sys.TotSurfToDistrib):
            if len(alpha_args) > 7 + surf_num_idx:
                high_temp_rad_sys.SurfaceName.append(alpha_args[7 + surf_num_idx])
            
            if len(num_args) > 9 + surf_num_idx and num_args[9 + surf_num_idx] is not None:
                frac = num_args[9 + surf_num_idx]
                if frac < MIN_FRACTION:
                    frac = MIN_FRACTION
                if frac > MAX_FRACTION:
                    frac = MAX_FRACTION
                high_temp_rad_sys.FracDistribToSurf.append(frac)
                all_fracs_summed += frac
            else:
                high_temp_rad_sys.FracDistribToSurf.append(0.0)
                high_temp_rad_sys.SurfacePtr.append(0)
                continue
            
            surf_ptr = state.heat_balance_int_rad_exchange_get_radiant_system_surface(
                state, "ZoneHVAC:HighTemperatureRadiant", high_temp_rad_sys.Name,
                high_temp_rad_sys.ZonePtr, high_temp_rad_sys.SurfaceName[-1]
            )
            high_temp_rad_sys.SurfacePtr.append(surf_ptr)
            
            if surf_ptr > 0:
                state.dataSurface.set_gets_radiant_heat(surf_ptr)
        
        if all_fracs_summed > (MAX_FRACTION + 0.01):
            errors_found = True
        if all_fracs_summed < (MAX_FRACTION - 0.01):
            errors_found = True
    
    # Setup output variables
    for item_idx in range(num_of_systems):
        high_temp_rad_sys = state.dataHighTempRadSys.HighTempRadSys[item_idx]
        state.setup_output_variable(state, "Zone Radiant HVAC Heating Rate", "W", high_temp_rad_sys.Name)
        state.setup_output_variable(state, "Zone Radiant HVAC Heating Energy", "J", high_temp_rad_sys.Name)
        
        if high_temp_rad_sys.HeaterType == "NaturalGas":
            state.setup_output_variable(state, "Zone Radiant HVAC NaturalGas Rate", "W", high_temp_rad_sys.Name)
            state.setup_output_variable(state, "Zone Radiant HVAC NaturalGas Energy", "J", high_temp_rad_sys.Name)
        elif high_temp_rad_sys.HeaterType == "Electricity":
            state.setup_output_variable(state, "Zone Radiant HVAC Electricity Rate", "W", high_temp_rad_sys.Name)
            state.setup_output_variable(state, "Zone Radiant HVAC Electricity Energy", "J", high_temp_rad_sys.Name)


def init_high_temp_radiant_system(state, first_hvac_iteration: bool, rad_sys_num: int):
    """
    Initialize high temperature radiant system variables.
    """
    if state.dataHighTempRadSys.firstTime:
        state.dataHighTempRadSys.MySizeFlag = [True] * state.dataHighTempRadSys.NumOfHighTempRadSys
        state.dataHighTempRadSys.firstTime = False
    
    # Check zone equipment list
    if not state.dataHighTempRadSys.ZoneEquipmentListChecked and state.dataZoneEquip.ZoneEquipInputsFilled:
        state.dataHighTempRadSys.ZoneEquipmentListChecked = True
        for this_htr_sys in state.dataHighTempRadSys.HighTempRadSys:
            if not state.check_zone_equipment_list(state, "ZoneHVAC:HighTemperatureRadiant", this_htr_sys.Name):
                state.show_severe_error(state,
                    f"InitHighTempRadiantSystem: Unit=[ZoneHVAC:HighTemperatureRadiant,{this_htr_sys.Name}] is not on any ZoneHVAC:EquipmentList.")
    
    # Do sizing once
    if not state.dataGlobal.SysSizingCalc and state.dataHighTempRadSys.MySizeFlag[rad_sys_num]:
        size_high_temp_radiant_system(state, rad_sys_num)
        state.dataHighTempRadSys.MySizeFlag[rad_sys_num] = False
    
    # Initialize environment variables
    if state.dataGlobal.BeginEnvrnFlag and state.dataHighTempRadSys.MyEnvrnFlag:
        for this_htr in state.dataHighTempRadSys.HighTempRadSys:
            this_htr.ZeroHTRSourceSumHATsurf = 0.0
            this_htr.QHTRRadSource = 0.0
            this_htr.QHTRRadSrcAvg = 0.0
            this_htr.LastQHTRRadSrc = 0.0
            this_htr.LastSysTimeElapsed = 0.0
            this_htr.LastTimeStepSys = 0.0
        state.dataHighTempRadSys.MyEnvrnFlag = False
    
    if not state.dataGlobal.BeginEnvrnFlag:
        state.dataHighTempRadSys.MyEnvrnFlag = True
    
    # Initialize timestep variables
    if state.dataGlobal.BeginTimeStepFlag and first_hvac_iteration:
        this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
        this_htr.ZeroHTRSourceSumHATsurf = state.dataHeatBal.Zone[this_htr.ZonePtr].sumHATsurf(state)
        this_htr.QHTRRadSource = 0.0
        this_htr.QHTRRadSrcAvg = 0.0
        this_htr.LastQHTRRadSrc = 0.0
        this_htr.LastSysTimeElapsed = 0.0
        this_htr.LastTimeStepSys = 0.0


def size_high_temp_radiant_system(state, rad_sys_num: int):
    """
    Size high temperature radiant system heating capacity.
    """
    this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    cur_zone_eq_num = state.dataSize.CurZoneEqNum
    
    if cur_zone_eq_num > 0:
        zone_eq_sizing = state.dataSize.ZoneEqSizing[cur_zone_eq_num]
        
        state.dataSize.DataFracOfAutosizedHeatingCapacity = 1.0
        state.dataSize.DataZoneNumber = this_htr.ZonePtr
        
        cap_sizing_method = int(this_htr.HeatingCapMethod) if this_htr.HeatingCapMethod else -1
        
        if cap_sizing_method in [0, 1, 2]:  # Valid sizing methods
            comp_type = "ZoneHVAC:HighTemperatureRadiant"
            comp_name = this_htr.Name
            
            if cap_sizing_method == 0:  # HeatingDesignCapacity
                if this_htr.ScaledHeatingCapacity == state.DataSizing.AutoSize:
                    state.check_zone_sizing(state, comp_type, comp_name)
                    zone_eq_sizing.DesHeatingLoad = (
                        state.dataSize.FinalZoneSizing[cur_zone_eq_num].NonAirSysDesHeatLoad /
                        (this_htr.FracRadiant + this_htr.FracConvect)
                    )
                else:
                    zone_eq_sizing.DesHeatingLoad = this_htr.ScaledHeatingCapacity
                zone_eq_sizing.HeatingCapacity = True
                temp_size = zone_eq_sizing.DesHeatingLoad
            elif cap_sizing_method == 1:  # CapacityPerFloorArea
                zone_eq_sizing.HeatingCapacity = True
                zone_eq_sizing.DesHeatingLoad = (
                    this_htr.ScaledHeatingCapacity *
                    state.dataHeatBal.Zone[state.dataSize.DataZoneNumber].FloorArea
                )
                temp_size = zone_eq_sizing.DesHeatingLoad
                state.dataSize.DataScalableCapSizingON = True
            elif cap_sizing_method == 2:  # FractionOfAutosizedHeatingCapacity
                state.check_zone_sizing(state, comp_type, comp_name)
                zone_eq_sizing.HeatingCapacity = True
                state.dataSize.DataFracOfAutosizedHeatingCapacity = this_htr.ScaledHeatingCapacity
                zone_eq_sizing.DesHeatingLoad = (
                    state.dataSize.FinalZoneSizing[cur_zone_eq_num].NonAirSysDesHeatLoad /
                    (this_htr.FracRadiant + this_htr.FracConvect)
                )
                temp_size = state.DataSizing.AutoSize
                state.dataSize.DataScalableCapSizingON = True
            else:
                temp_size = this_htr.ScaledHeatingCapacity
            
            # Use heating capacity sizer
            this_htr.MaxPowerCapac = state.size_heating_capacity(state, temp_size, comp_type, comp_name)
            state.dataSize.DataScalableCapSizingON = False


def calc_high_temp_radiant_system(state, rad_sys_num: int):
    """
    Calculate high temperature radiant system output with control.
    """
    this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    zone_num = this_htr.ZonePtr
    heat_frac = 0.0
    
    if this_htr.availSched.get_current_val() <= 0.0:
        this_htr.QHTRRadSource = 0.0
    else:
        set_pt_temp = this_htr.setptSched.get_current_val()
        off_temp = set_pt_temp + 0.5 * this_htr.ThrottlRange
        
        zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]
        mat = zone_hb.MAT
        mrt = zone_hb.MRT
        
        if this_htr.ControlType == RadControlType.MATControl:
            heat_frac = (off_temp - mat) / this_htr.ThrottlRange
        elif this_htr.ControlType == RadControlType.MRTControl:
            heat_frac = (off_temp - mrt) / this_htr.ThrottlRange
        elif this_htr.ControlType == RadControlType.OperativeControl:
            op_temp = 0.5 * (mat + mrt)
            heat_frac = (off_temp - op_temp) / this_htr.ThrottlRange
        
        if heat_frac < 0.0:
            heat_frac = 0.0
        if heat_frac > 1.0:
            heat_frac = 1.0
        
        this_htr.QHTRRadSource = heat_frac * this_htr.MaxPowerCapac


def calc_high_temp_radiant_system_sp(state, first_hvac_iteration: bool, rad_sys_num: int):
    """
    Calculate high temperature radiant system with setpoint control.
    """
    this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    TEMP_CONV_TOLER = 0.1
    MAX_ITERATIONS = 10
    
    zone_num = this_htr.ZonePtr
    this_htr.QHTRRadSource = 0.0
    
    if this_htr.availSched.get_current_val() > 0.0:
        set_pt_temp = this_htr.setptSched.get_current_val()
        
        distribute_ht_rad_gains(state)
        state.calc_heat_balance_outside_surf(state, zone_num)
        state.calc_heat_balance_inside_surf(state, zone_num)
        
        zone_hb = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]
        
        if this_htr.ControlType == RadControlType.MATSPControl:
            zone_temp = zone_hb.MAT
        elif this_htr.ControlType == RadControlType.MRTSPControl:
            zone_temp = zone_hb.MRT
        elif this_htr.ControlType == RadControlType.OperativeSPControl:
            zone_temp = 0.5 * (zone_hb.MAT + zone_hb.MRT)
        else:
            zone_temp = 0.0
        
        if zone_temp < (set_pt_temp - TEMP_CONV_TOLER):
            iter_num = 0
            converg_flag = False
            heat_frac_max = 1.0
            heat_frac_min = 0.0
            
            while iter_num <= MAX_ITERATIONS and not converg_flag:
                if iter_num == 0:
                    heat_frac = 1.0
                else:
                    heat_frac = (heat_frac_min + heat_frac_max) / 2.0
                
                this_htr.QHTRRadSource = heat_frac * this_htr.MaxPowerCapac
                
                distribute_ht_rad_gains(state)
                state.calc_heat_balance_outside_surf(state, zone_num)
                state.calc_heat_balance_inside_surf(state, zone_num)
                
                zone_hb_mod = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num]
                
                if this_htr.ControlType == RadControlType.MATSPControl:
                    zone_temp = zone_hb_mod.MAT
                elif this_htr.ControlType == RadControlType.MRTSPControl:
                    zone_temp = zone_hb_mod.MRT
                elif this_htr.ControlType == RadControlType.OperativeSPControl:
                    zone_temp = 0.5 * (zone_hb_mod.MAT + zone_hb_mod.MRT)
                
                if abs(zone_temp - set_pt_temp) <= TEMP_CONV_TOLER:
                    converg_flag = True
                elif zone_temp < set_pt_temp:
                    if iter_num == 0:
                        converg_flag = True
                    else:
                        heat_frac_min = heat_frac
                else:
                    if iter_num > 0:
                        heat_frac_max = heat_frac
                
                iter_num += 1


def update_high_temp_radiant_system(state, rad_sys_num: int) -> float:
    """
    Update high temperature radiant system and return load met.
    """
    sys_time_elapsed = state.dataHVACGlobal.SysTimeElapsed
    time_step_sys = state.dataHVACGlobal.TimeStepSys
    this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    # Update running average
    if this_htr.LastSysTimeElapsed == sys_time_elapsed:
        this_htr.QHTRRadSrcAvg -= (
            this_htr.LastQHTRRadSrc * this_htr.LastTimeStepSys / state.dataGlobal.TimeStepZone
        )
    
    this_htr.QHTRRadSrcAvg += (
        this_htr.QHTRRadSource * time_step_sys / state.dataGlobal.TimeStepZone
    )
    
    this_htr.LastQHTRRadSrc = this_htr.QHTRRadSource
    this_htr.LastSysTimeElapsed = sys_time_elapsed
    this_htr.LastTimeStepSys = time_step_sys
    
    # Recalculate heat balance for non-SP controls
    if this_htr.ControlType in [RadControlType.MATControl, RadControlType.MRTControl, RadControlType.OperativeControl]:
        distribute_ht_rad_gains(state)
        zone_num = this_htr.ZonePtr
        state.calc_heat_balance_outside_surf(state, zone_num)
        state.calc_heat_balance_inside_surf(state, zone_num)
    
    # Calculate load met
    if this_htr.QHTRRadSource <= 0.0:
        load_met = 0.0
    else:
        zone_num = this_htr.ZonePtr
        load_met = (
            state.dataHeatBal.Zone[zone_num].sumHATsurf(state) - this_htr.ZeroHTRSourceSumHATsurf +
            state.dataHeatBalFanSys.SumConvHTRadSys[zone_num]
        )
    
    return load_met


def update_ht_rad_source_val_avg(state) -> bool:
    """
    Transfer average radiant source to heat balance and return whether system is on.
    """
    high_temp_rad_sys_on = False
    
    if state.dataHighTempRadSys.NumOfHighTempRadSys == 0:
        return high_temp_rad_sys_on
    
    for this_htr in state.dataHighTempRadSys.HighTempRadSys:
        this_htr.QHTRRadSource = this_htr.QHTRRadSrcAvg
        if this_htr.QHTRRadSrcAvg != 0.0:
            high_temp_rad_sys_on = True
    
    distribute_ht_rad_gains(state)
    
    return high_temp_rad_sys_on


def distribute_ht_rad_gains(state):
    """
    Distribute radiant gains from high temperature heaters to surfaces and people.
    """
    SMALLEST_AREA = 0.001
    
    # Initialize arrays
    state.dataHeatBalFanSys.SumConvHTRadSys = [0.0] * state.dataGlobal.NumOfZones
    state.dataHeatBalFanSys.SumLatentHTRadSys = [0.0] * state.dataGlobal.NumOfZones
    
    for this_htr in state.dataHighTempRadSys.HighTempRadSys:
        for rad_surf_num in range(this_htr.TotSurfToDistrib):
            surf_num = this_htr.SurfacePtr[rad_surf_num]
            state.dataHeatBalFanSys.surfQRadFromHVAC[surf_num].HTRadSys = 0.0
    
    state.dataHeatBalFanSys.ZoneQHTRadSysToPerson = [0.0] * state.dataGlobal.NumOfZones
    
    for this_htr in state.dataHighTempRadSys.HighTempRadSys:
        zone_num = this_htr.ZonePtr
        
        state.dataHeatBalFanSys.ZoneQHTRadSysToPerson[zone_num] = (
            this_htr.QHTRRadSource * this_htr.FracRadiant * this_htr.FracDistribPerson
        )
        state.dataHeatBalFanSys.SumConvHTRadSys[zone_num] += (
            this_htr.QHTRRadSource * this_htr.FracConvect
        )
        state.dataHeatBalFanSys.SumLatentHTRadSys[zone_num] += (
            this_htr.QHTRRadSource * this_htr.FracLatent
        )
        
        for rad_surf_num in range(this_htr.TotSurfToDistrib):
            surf_num = this_htr.SurfacePtr[rad_surf_num]
            surf_area = state.dataSurface.Surface[surf_num].Area
            
            if surf_area > SMALLEST_AREA:
                this_surf_intensity = (
                    this_htr.QHTRRadSource * this_htr.FracRadiant *
                    this_htr.FracDistribToSurf[rad_surf_num] / surf_area
                )
                state.dataHeatBalFanSys.surfQRadFromHVAC[surf_num].HTRadSys += this_surf_intensity
                
                if this_surf_intensity > state.DataHeatBalFanSys.MaxRadHeatFlux:
                    state.show_severe_error(state, "DistributeHTRadGains: excessive thermal radiation heat flux intensity detected")
                    state.show_fatal_error(state, "DistributeHTRadGains: excessive thermal radiation heat flux intensity detected")
            else:
                state.show_severe_error(state, "DistributeHTRadGains: surface not large enough to receive thermal radiation heat flux")
                state.show_fatal_error(state, "DistributeHTRadGains: surface not large enough to receive thermal radiation heat flux")
    
    # Add radiant energy to people to convective
    for zone_num in range(state.dataGlobal.NumOfZones):
        state.dataHeatBalFanSys.SumConvHTRadSys[zone_num] += state.dataHeatBalFanSys.ZoneQHTRadSysToPerson[zone_num]


def report_high_temp_radiant_system(state, rad_sys_num: int):
    """
    Report high temperature radiant system output.
    """
    time_step_sys_sec = state.dataHVACGlobal.TimeStepSysSec
    this_htr = state.dataHighTempRadSys.HighTempRadSys[rad_sys_num]
    
    if this_htr.HeaterType == "NaturalGas":
        this_htr.GasPower = this_htr.QHTRRadSource / this_htr.CombustionEffic
        this_htr.GasEnergy = this_htr.GasPower * time_step_sys_sec
        this_htr.ElecPower = 0.0
        this_htr.ElecEnergy = 0.0
    elif this_htr.HeaterType == "Electricity":
        this_htr.GasPower = 0.0
        this_htr.GasEnergy = 0.0
        this_htr.ElecPower = this_htr.QHTRRadSource
        this_htr.ElecEnergy = this_htr.ElecPower * time_step_sys_sec
    else:
        state.show_warning_error(state, "Someone forgot to add a high temperature radiant heater type to the reporting subroutine")
    
    this_htr.HeatPower = this_htr.QHTRRadSource
    this_htr.HeatEnergy = this_htr.HeatPower * time_step_sys_sec
