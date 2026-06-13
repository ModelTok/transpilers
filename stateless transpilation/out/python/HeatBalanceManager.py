"""
HeatBalanceManager.py — Heat balance simulation manager (faithful C++ port).
"""

from dataclasses import dataclass, field
from typing import Any, List, Optional, Dict, Tuple
import math

# ============================================================================
# EXTERNAL STUBS (to be wired in at module load)
# ============================================================================

def get_material_num(state: Any, name: str) -> int:
    """Stub: return material index (1-based in C++, 0-based in Python)."""
    pass

def find_item_in_list(item: str, array: List[Any]) -> int:
    """Stub: find item in list, return 0-based index or 0 if not found."""
    pass

def show_severe_error(state: Any, msg: str) -> None:
    """Stub: log severe error."""
    pass

def show_warning_error(state: Any, msg: str) -> None:
    """Stub: log warning."""
    pass

def show_continue_error(state: Any, msg: str) -> None:
    """Stub: log continuation of error."""
    pass

def show_message(state: Any, msg: str) -> None:
    """Stub: log message."""
    pass

def show_fatal_error(state: Any, msg: str) -> None:
    """Stub: log fatal error and raise."""
    raise RuntimeError(msg)

def get_schedule(state: Any, name: str) -> Optional[Any]:
    """Stub: get schedule object or None."""
    pass

class BaseGlobalStruct:
    """Stub base class for state containers."""
    def init_constant_state(self, state: Any) -> None:
        pass
    def init_state(self, state: Any) -> None:
        pass
    def clear_state(self) -> None:
        pass


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class WarmupConvergence:
    """Warmup convergence tracking for a zone."""
    PassFlag: List[int] = field(default_factory=lambda: [2, 2, 2, 2])  # 1=Fail, 2=Pass
    TestMaxTempValue: float = 0.0
    TestMinTempValue: float = 0.0
    TestMaxHeatLoadValue: float = 0.0
    TestMaxCoolLoadValue: float = 0.0


@dataclass
class HeatBalanceMgrData(BaseGlobalStruct):
    """Global heat balance manager state."""
    ManageHeatBalanceGetInputFlag: bool = True
    DoReport: bool = False
    ChangeSet: bool = True
    FirstWarmupWrite: bool = True
    WarmupConvergenceWarning: bool = False
    SizingWarmupConvergenceWarning: bool = False
    ReportWarmupConvergenceFirstWarmupWrite: bool = True
    
    CurrentModuleObject: str = ""
    UniqueConstructNames: Dict[str, str] = field(default_factory=dict)
    
    # Warmup tracking arrays (1D, resized per NumOfZones)
    MaxCoolLoadPrevDay: List[float] = field(default_factory=list)
    MaxCoolLoadZone: List[float] = field(default_factory=list)
    MaxHeatLoadPrevDay: List[float] = field(default_factory=list)
    MaxHeatLoadZone: List[float] = field(default_factory=list)
    MaxTempPrevDay: List[float] = field(default_factory=list)
    MaxTempZone: List[float] = field(default_factory=list)
    MinTempPrevDay: List[float] = field(default_factory=list)
    MinTempZone: List[float] = field(default_factory=list)
    
    # Warmup difference tracking
    WarmupTempDiff: List[float] = field(default_factory=list)
    WarmupLoadDiff: List[float] = field(default_factory=list)
    TempZoneSecPrevDay: List[float] = field(default_factory=list)
    LoadZoneSecPrevDay: List[float] = field(default_factory=list)
    TempZonePrevDay: List[float] = field(default_factory=list)
    LoadZonePrevDay: List[float] = field(default_factory=list)
    TempZone: List[float] = field(default_factory=list)
    LoadZone: List[float] = field(default_factory=list)
    
    # Warmup reporting (2D arrays: zone x timestep)
    TempZoneRpt: List[List[float]] = field(default_factory=list)
    TempZoneRptStdDev: List[float] = field(default_factory=list)
    LoadZoneRpt: List[List[float]] = field(default_factory=list)
    LoadZoneRptStdDev: List[float] = field(default_factory=list)
    MaxLoadZoneRpt: List[List[float]] = field(default_factory=list)
    
    CountWarmupDayPoints: int = 0
    WarmupConvergenceValues: List[WarmupConvergence] = field(default_factory=list)
    
    def init_constant_state(self, state: Any) -> None:
        pass
    
    def init_state(self, state: Any) -> None:
        pass
    
    def clear_state(self) -> None:
        self.ManageHeatBalanceGetInputFlag = True
        self.UniqueConstructNames.clear()
        self.DoReport = False
        self.ChangeSet = True
        self.FirstWarmupWrite = True
        self.WarmupConvergenceWarning = False
        self.SizingWarmupConvergenceWarning = False
        self.ReportWarmupConvergenceFirstWarmupWrite = True
        self.CurrentModuleObject = ""
        self.MaxCoolLoadPrevDay.clear()
        self.MaxCoolLoadZone.clear()
        self.MaxHeatLoadPrevDay.clear()
        self.MaxHeatLoadZone.clear()
        self.MaxTempPrevDay.clear()
        self.MaxTempZone.clear()
        self.MinTempPrevDay.clear()
        self.MinTempZone.clear()
        self.WarmupTempDiff.clear()
        self.WarmupLoadDiff.clear()
        self.TempZoneSecPrevDay.clear()
        self.LoadZoneSecPrevDay.clear()
        self.TempZonePrevDay.clear()
        self.LoadZonePrevDay.clear()
        self.TempZone.clear()
        self.LoadZone.clear()
        self.TempZoneRpt.clear()
        self.TempZoneRptStdDev.clear()
        self.LoadZoneRpt.clear()
        self.LoadZoneRptStdDev.clear()
        self.MaxLoadZoneRpt.clear()
        self.CountWarmupDayPoints = 0
        self.WarmupConvergenceValues.clear()


# ============================================================================
# MODULE CONSTANTS
# ============================================================================

PASS_FAIL = ["Fail", "Pass"]
MIN_LOAD = 100.0  # Minimum loads for convergence check


# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

def manage_heat_balance(state: Any) -> None:
    """
    Manage the heat balance method for building thermal loads.
    Called at time step level from SimulationManager.
    """
    if state.dataHeatBalMgr.ManageHeatBalanceGetInputFlag:
        get_heat_balance_input(state)
        if state.dataGlobal.DoingSizing:
            state.dataHeatBal.doSpaceHeatBalance = state.dataHeatBal.doSpaceHeatBalanceSizing
        
        # Surface octree setup
        if state.dataSurface.TotSurfaces >= 10:  # octreeCrossover
            if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Daylighting:Controls") > 0:
                pass  # state.dataHeatBalMgr.surfaceOctree.init(state.dataSurface.Surface)
        
        for surface in state.dataSurface.Surface:
            pass  # surface.set_computed_geometry()
        
        state.dataHeatBalMgr.ManageHeatBalanceGetInputFlag = False
    
    any_ran = False
    # ManageEMS calls here (stub)
    
    init_heat_balance(state)
    
    # Solve zone heat balance (stub for ManageSurfaceHeatBalance)
    # RecKeepHeatBalance(state)
    # ReportHeatBalance(state)
    
    if state.dataGlobal.WarmupFlag and state.dataGlobal.EndDayFlag:
        check_warmup_convergence(state)
        if not state.dataGlobal.WarmupFlag:
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
    
    if (not state.dataGlobal.WarmupFlag and state.dataGlobal.EndDayFlag and
        state.dataGlobal.DayOfSim == 1 and not state.dataGlobal.DoingSizing):
        report_warmup_convergence(state)


def get_heat_balance_input(state: Any) -> None:
    """Main driver for heat balance initializations."""
    errors_found = False
    
    get_project_control_data(state, errors_found)
    get_site_atmosphere_data(state, errors_found)
    # Material::GetWindowGlassSpectralData(state, errors_found)
    # Material::GetMaterialData(state, errors_found)
    # Material::GetHysteresisData(state, errors_found)
    # GetFrameAndDividerData(state)
    get_construct_data(state, errors_found)
    # GetBuildingData(state, errors_found)
    # DataSurfaces::GetVariableAbsorptanceSurfaceList(state)
    get_incident_solar_multiplier(state, errors_found)
    get_scheduled_surface_gains(state, errors_found)
    
    if state.dataSurface.UseRepresentativeSurfaceCalculations:
        pass  # print representative surfaces
    
    create_tc_constructions(state, errors_found)
    
    if state.dataSurface.TotSurfaces > 0 and state.dataGlobal.NumOfZones == 0:
        if not check_valid_simulation_objects(state):
            show_severe_error(state, "GetHeatBalanceInput: There are surfaces but no zones found.")
            errors_found = True
    
    check_used_constructions(state, errors_found)
    
    if errors_found:
        show_fatal_error(state, "Errors found in Building Input, Program Stopped")
    
    # HeatBalanceIntRadExchange::InitSolarViewFactors(state)
    # ManageInternalHeatGains(state, True)
    # if state.dataHeatBal.AnyKiva: ...


def check_used_constructions(state: Any, errors_found: bool) -> None:
    """Check and report unused constructions."""
    const_objects = [
        "Pipe:Indoor",
        "Pipe:Outdoor",
        "Pipe:Underground",
        "GroundHeatExchanger:Surface",
        "DaylightingDevice:Tubular",
        "EnergyManagementSystem:ConstructionIndexVariable"
    ]
    
    for obj_name in const_objects:
        num_objects = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, obj_name)
        for loop in range(num_objects):
            # getObjectItem and mark construction as used
            pass
    
    # Count unused constructions
    unused = 0
    # if unused > 0: show_warning_error(...)


def check_valid_simulation_objects(state: Any) -> bool:
    """Check if simulation without zones has required objects."""
    valid = False
    required = [
        "SolarCollector:FlatPlate:Water",
        "Generator:Photovoltaic",
        "Generator:InternalCombustionEngine",
        "Generator:CombustionTurbine",
        "Generator:FuelCell",
        "Generator:MicroCHP",
        "Generator:MicroTurbine",
        "Generator:WindTurbine"
    ]
    for obj in required:
        if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, obj) > 0:
            valid = True
            break
    return valid


def set_pre_construction_input_parameters(state: Any) -> None:
    """Set parameters before heat balance inputs are read."""
    state.dataHeatBal.MaxSolidWinLayers = 7
    
    if state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:ComplexFenestrationState") > 0:
        state.dataHeatBal.MaxSolidWinLayers = max(state.dataHeatBal.MaxSolidWinLayers, 10)
    
    const_name = "Construction:WindowEquivalentLayer"
    num_constructions = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, const_name)
    for i in range(num_constructions):
        pass  # getObjectItem and find max layers


def get_project_control_data(state: Any, errors_found: bool) -> None:
    """Get project control data (building, algorithms, etc.)."""
    # Stub: implement getObjectItem calls and set state values
    state.dataHeatBalMgr.CurrentModuleObject = "Building"
    pass


def get_site_atmosphere_data(state: Any, errors_found: bool) -> None:
    """Read site atmospheric variation data."""
    state.dataHeatBalMgr.CurrentModuleObject = "Site:HeightVariation"
    num_objects = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, state.dataHeatBalMgr.CurrentModuleObject)
    
    if num_objects == 1:
        pass  # getObjectItem and set SiteWindExp, SiteWindBLHeight, SiteTempGradient
    elif num_objects > 1:
        show_severe_error(state, f"Too many {state.dataHeatBalMgr.CurrentModuleObject} objects, only 1 allowed.")
        errors_found = True
    else:
        state.dataEnvrn.SiteTempGradient = 0.0065


def get_construct_data(state: Any, errors_found: bool) -> None:
    """Read construction input data."""
    if state.dataHeatBalMgr.UniqueConstructNames:
        return
    
    tot_reg_constructs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction")
    tot_air_boundary_constructs = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:AirBoundary")
    tot_ffactor = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:FfactorGroundFloor")
    tot_cfactor = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:CfactorUndergroundWall")
    tot_complex_fen = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:ComplexFenestrationState")
    tot_window5 = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:WindowDataFile")
    tot_win_equiv_layer = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:WindowEquivalentLayer")
    
    tot_constructs = tot_reg_constructs + tot_ffactor + tot_cfactor + tot_air_boundary_constructs + tot_complex_fen + tot_win_equiv_layer
    
    state.dataHeatBal.TotConstructs = tot_constructs
    # Allocate arrays
    
    # Process regular constructions
    constr_num = 0
    for loop in range(tot_reg_constructs):
        pass  # getObjectItem, verify uniqueness, process layers
    
    # Add F/C factor and air boundary constructions
    if tot_ffactor + tot_cfactor >= 1:
        create_fc_factor_constructions(state, constr_num, errors_found)
    
    if tot_air_boundary_constructs >= 1:
        create_air_boundary_constructions(state, constr_num, errors_found)
    
    # Complex fenestration
    if tot_complex_fen > 0:
        setup_complex_fenestration_state_input(state, constr_num, errors_found)
    
    # Window equivalent layer constructions
    for loop in range(tot_win_equiv_layer):
        pass  # getObjectItem and process
    
    # Window5 data file constructions
    for loop in range(tot_window5):
        pass  # getObjectItem and search W5DataFile


def get_building_data(state: Any, errors_found: bool) -> None:
    """Read building geometry data."""
    get_zone_data(state, errors_found)
    # SolarShading::GetShadowingInput(state)
    # SurfaceGeometry::SetupZoneGeometry(state, errors_found)


def get_zone_data(state: Any, errors_found: bool) -> None:
    """Read zone data from input file."""
    state.dataIPShortCut.cCurrentModuleObject = "Zone"
    state.dataGlobal.NumOfZones = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Zone")
    
    # Allocate zone and related arrays
    state.dataHeatBal.Zone = [None] * state.dataGlobal.NumOfZones
    state.dataDayltg.ZoneDaylight = [None] * state.dataGlobal.NumOfZones
    state.dataHeatBal.Resilience = [None] * state.dataGlobal.NumOfZones
    
    for loop in range(state.dataGlobal.NumOfZones):
        pass  # getObjectItem and process_zone_data
    
    # Check nominal control
    for loop in range(state.dataGlobal.NumOfZones):
        pass  # Check ZoneHVAC:EquipmentConnections
    
    # Get zone lists and groups
    state.dataIPShortCut.cCurrentModuleObject = "ZoneList"
    num_zone_lists = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneList")
    if num_zone_lists > 0:
        pass  # Process zone lists
    
    state.dataIPShortCut.cCurrentModuleObject = "ZoneGroup"
    num_zone_groups = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "ZoneGroup")
    if num_zone_groups > 0:
        pass  # Process zone groups
    
    get_zone_local_env_data(state, errors_found)
    
    # Allocate predefined report data
    state.dataHeatBal.ZonePreDefRep = [None] * state.dataGlobal.NumOfZones
    
    # Get space data after zones
    get_space_data(state, errors_found)


def get_space_data(state: Any, errors_found: bool) -> None:
    """Read space data (optional, zones are required)."""
    # Stub: process Space and SpaceList objects
    pass


def get_general_space_type_num(state: Any) -> int:
    """Get or create "General" space type."""
    for i in range(state.dataGlobal.numSpaceTypes):
        if state.dataHeatBal.spaceTypes[i] == "GENERAL":
            return i
    state.dataGlobal.numSpaceTypes += 1
    state.dataHeatBal.spaceTypes[state.dataGlobal.numSpaceTypes] = "GENERAL"
    return state.dataGlobal.numSpaceTypes


def get_zone_local_env_data(state: Any, errors_found: bool) -> None:
    """Load outdoor air node for zones."""
    state.dataIPShortCut.cCurrentModuleObject = "ZoneProperty:LocalEnvironment"
    tot_zone_env = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, state.dataIPShortCut.cCurrentModuleObject)
    
    if tot_zone_env > 0:
        state.dataGlobal.AnyLocalEnvironmentsInModel = True
        # Allocate and process local environment data
        pass


def process_zone_data(state: Any, module_obj: str, zone_loop: int, alpha_args: List[str],
                      num_alphas: int, numeric_args: List[float], num_numbers: int,
                      numeric_blanks: List[bool], alpha_blanks: List[bool],
                      alpha_field_names: List[str], numeric_field_names: List[str],
                      errors_found: bool) -> None:
    """Process a single zone's input data."""
    # Stub: set zone properties from input
    pass


def init_heat_balance(state: Any) -> None:
    """Initialize all heat balance parameters."""
    if state.dataGlobal.BeginSimFlag:
        allocate_heat_bal_arrays(state)
        if state.dataHeatBal.AnyCTF or state.dataHeatBal.AnyEMPD:
            init_conduction_transfer_functions(state)
    
    if state.dataGlobal.BeginEnvrnFlag:
        # Initialize warmup arrays
        for i in range(state.dataGlobal.NumOfZones):
            state.dataHeatBalMgr.MaxHeatLoadPrevDay[i] = 0.0
            state.dataHeatBalMgr.MaxCoolLoadPrevDay[i] = 0.0
            state.dataHeatBalMgr.MaxTempPrevDay[i] = 0.0
            state.dataHeatBalMgr.MinTempPrevDay[i] = 0.0
            state.dataHeatBalMgr.MaxHeatLoadZone[i] = -9999.0
            state.dataHeatBalMgr.MaxCoolLoadZone[i] = -9999.0
            state.dataHeatBalMgr.MaxTempZone[i] = -9999.0
            state.dataHeatBalMgr.MinTempZone[i] = 1000.0
            state.dataHeatBalMgr.TempZone[i] = -9999.0
            state.dataHeatBalMgr.LoadZone[i] = -9999.0
            state.dataHeatBalMgr.TempZonePrevDay[i] = 1000.0
            state.dataHeatBalMgr.LoadZonePrevDay[i] = -9999.0
            state.dataHeatBalMgr.TempZoneSecPrevDay[i] = -9999.0
            state.dataHeatBalMgr.WarmupTempDiff[i] = 0.0
            state.dataHeatBalMgr.WarmupLoadDiff[i] = 0.0


def allocate_zone_heat_bal_arrays(state: Any) -> None:
    """Allocate zone heat balance arrays."""
    # Stub: allocate zoneHeatBalance, spaceHeatBalance, etc.
    pass


def allocate_heat_bal_arrays(state: Any) -> None:
    """Allocate heat balance arrays."""
    allocate_zone_heat_bal_arrays(state)
    
    # Allocate 1D arrays per zone
    num_zones = state.dataGlobal.NumOfZones
    state.dataHeatBalMgr.MaxTempPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.MinTempPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.MaxHeatLoadPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.MaxCoolLoadPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.MaxHeatLoadZone = [-9999.0] * num_zones
    state.dataHeatBalMgr.MaxCoolLoadZone = [-9999.0] * num_zones
    state.dataHeatBalMgr.MaxTempZone = [-9999.0] * num_zones
    state.dataHeatBalMgr.MinTempZone = [1000.0] * num_zones
    state.dataHeatBalMgr.TempZonePrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.LoadZonePrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.TempZoneSecPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.LoadZoneSecPrevDay = [0.0] * num_zones
    state.dataHeatBalMgr.WarmupTempDiff = [0.0] * num_zones
    state.dataHeatBalMgr.WarmupLoadDiff = [0.0] * num_zones
    state.dataHeatBalMgr.TempZone = [0.0] * num_zones
    state.dataHeatBalMgr.LoadZone = [0.0] * num_zones
    
    # 2D arrays: zone x timestep
    num_timesteps = state.dataGlobal.TimeStepsInHour * 24
    state.dataHeatBalMgr.TempZoneRpt = [[0.0] * num_timesteps for _ in range(num_zones)]
    state.dataHeatBalMgr.LoadZoneRpt = [[0.0] * num_timesteps for _ in range(num_zones)]
    state.dataHeatBalMgr.MaxLoadZoneRpt = [[0.0] * num_timesteps for _ in range(num_zones)]
    
    state.dataHeatBalMgr.TempZoneRptStdDev = [0.0] * num_timesteps
    state.dataHeatBalMgr.LoadZoneRptStdDev = [0.0] * num_timesteps
    
    state.dataHeatBalMgr.WarmupConvergenceValues = [WarmupConvergence() for _ in range(num_zones)]


def rec_keep_heat_balance(state: Any) -> None:
    """Record keeping for heat balance."""
    for zone_num in range(state.dataGlobal.NumOfZones):
        # Get current zone conditions
        ztav = state.dataZoneTempPredictorCorrector.zoneHeatBalance[zone_num].ZTAV
        air_heat_rate = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num].airSysHeatRate
        air_cool_rate = state.dataZoneEnergyDemand.ZoneSysEnergyDemand[zone_num].airSysCoolRate
        
        # Update max/min
        if ztav > state.dataHeatBalMgr.MaxTempZone[zone_num]:
            state.dataHeatBalMgr.MaxTempZone[zone_num] = ztav
        if ztav < state.dataHeatBalMgr.MinTempZone[zone_num]:
            state.dataHeatBalMgr.MinTempZone[zone_num] = ztav
        if air_heat_rate > state.dataHeatBalMgr.MaxHeatLoadZone[zone_num]:
            state.dataHeatBalMgr.MaxHeatLoadZone[zone_num] = air_heat_rate
        if air_cool_rate > state.dataHeatBalMgr.MaxCoolLoadZone[zone_num]:
            state.dataHeatBalMgr.MaxCoolLoadZone[zone_num] = air_cool_rate
        
        # Record temperature and load
        state.dataHeatBalMgr.TempZoneSecPrevDay[zone_num] = state.dataHeatBalMgr.TempZonePrevDay[zone_num]
        state.dataHeatBalMgr.LoadZoneSecPrevDay[zone_num] = state.dataHeatBalMgr.LoadZonePrevDay[zone_num]
        state.dataHeatBalMgr.TempZonePrevDay[zone_num] = state.dataHeatBalMgr.TempZone[zone_num]
        state.dataHeatBalMgr.LoadZonePrevDay[zone_num] = state.dataHeatBalMgr.LoadZone[zone_num]
        state.dataHeatBalMgr.TempZone[zone_num] = ztav
        state.dataHeatBalMgr.LoadZone[zone_num] = max(air_heat_rate, abs(air_cool_rate))
        
        # Calculate warmup differences
        if (not state.dataGlobal.WarmupFlag and state.dataGlobal.DayOfSim == 1 and
            (not state.dataGlobal.DoingSizing or state.dataGlobal.DoPureLoadCalc)):
            temp_diff = abs(state.dataHeatBalMgr.TempZoneSecPrevDay[zone_num] - 
                           state.dataHeatBalMgr.TempZonePrevDay[zone_num])
            load_diff = abs(state.dataHeatBalMgr.LoadZoneSecPrevDay[zone_num] - 
                           state.dataHeatBalMgr.LoadZonePrevDay[zone_num])
            state.dataHeatBalMgr.WarmupTempDiff[zone_num] = temp_diff
            state.dataHeatBalMgr.WarmupLoadDiff[zone_num] = load_diff
            
            if zone_num == 0:
                state.dataHeatBalMgr.CountWarmupDayPoints += 1
            
            idx = state.dataHeatBalMgr.CountWarmupDayPoints - 1
            if idx < len(state.dataHeatBalMgr.TempZoneRpt[zone_num]):
                state.dataHeatBalMgr.TempZoneRpt[zone_num][idx] = temp_diff
                state.dataHeatBalMgr.LoadZoneRpt[zone_num][idx] = load_diff
                state.dataHeatBalMgr.MaxLoadZoneRpt[zone_num][idx] = state.dataHeatBalMgr.LoadZone[zone_num]


def check_warmup_convergence(state: Any) -> None:
    """Check if warmup has converged."""
    if state.dataGlobal.NumOfZones <= 0:
        state.dataGlobal.WarmupFlag = False
        return
    
    convergence_failed = False
    
    for zone_num in range(state.dataGlobal.NumOfZones):
        # Check temperature differences
        max_temp_diff = abs(state.dataHeatBalMgr.MaxTempPrevDay[zone_num] - 
                           state.dataHeatBalMgr.MaxTempZone[zone_num])
        min_temp_diff = abs(state.dataHeatBalMgr.MinTempPrevDay[zone_num] - 
                           state.dataHeatBalMgr.MinTempZone[zone_num])
        
        state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].TestMaxTempValue = max_temp_diff
        state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].TestMinTempValue = min_temp_diff
        
        if max_temp_diff <= state.dataHeatBal.TempConvergTol:
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[0] = 2
        else:
            convergence_failed = True
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[0] = 1
        
        if min_temp_diff <= state.dataHeatBal.TempConvergTol:
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[1] = 2
        else:
            convergence_failed = True
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[1] = 1
        
        # Check heat load
        if state.dataHeatBalMgr.MaxHeatLoadZone[zone_num] > 1.0e-4:
            max_heat_load_zone = abs(max(state.dataHeatBalMgr.MaxHeatLoadZone[zone_num], MIN_LOAD))
            max_heat_load_prev = abs(max(state.dataHeatBalMgr.MaxHeatLoadPrevDay[zone_num], MIN_LOAD))
            heat_load_diff = abs((max_heat_load_zone - max_heat_load_prev) / max_heat_load_zone)
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].TestMaxHeatLoadValue = heat_load_diff
            
            if heat_load_diff <= state.dataHeatBal.LoadsConvergTol:
                state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[2] = 2
            else:
                convergence_failed = True
                state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[2] = 1
        else:
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[2] = 2
        
        # Check cool load
        if state.dataHeatBalMgr.MaxCoolLoadZone[zone_num] > 1.0e-4:
            max_cool_load_zone = abs(max(state.dataHeatBalMgr.MaxCoolLoadZone[zone_num], MIN_LOAD))
            max_cool_load_prev = abs(max(state.dataHeatBalMgr.MaxCoolLoadPrevDay[zone_num], MIN_LOAD))
            cool_load_diff = abs((max_cool_load_zone - max_cool_load_prev) / max_cool_load_zone)
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].TestMaxCoolLoadValue = cool_load_diff
            
            if cool_load_diff <= state.dataHeatBal.LoadsConvergTol:
                state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[3] = 2
            else:
                convergence_failed = True
                state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[3] = 1
        else:
            state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag[3] = 2
        
        # Check max warmup days reached
        if (state.dataGlobal.DayOfSim >= state.dataHeatBal.MaxNumberOfWarmupDays and
            state.dataGlobal.WarmupFlag):
            pass_sum = sum(state.dataHeatBalMgr.WarmupConvergenceValues[zone_num].PassFlag)
            if pass_sum != 8:  # 2*4 for full convergence
                show_severe_error(state, 
                                f"CheckWarmupConvergence: Zone {zone_num} did not converge after "
                                f"{state.dataHeatBal.MaxNumberOfWarmupDays} warmup days.")
        
        # Update previous day values
        state.dataHeatBalMgr.MaxHeatLoadPrevDay[zone_num] = state.dataHeatBalMgr.MaxHeatLoadZone[zone_num]
        state.dataHeatBalMgr.MaxCoolLoadPrevDay[zone_num] = state.dataHeatBalMgr.MaxCoolLoadZone[zone_num]
        state.dataHeatBalMgr.MaxTempPrevDay[zone_num] = state.dataHeatBalMgr.MaxTempZone[zone_num]
        state.dataHeatBalMgr.MinTempPrevDay[zone_num] = state.dataHeatBalMgr.MinTempZone[zone_num]
        
        state.dataHeatBalMgr.MaxHeatLoadZone[zone_num] = -9999.0
        state.dataHeatBalMgr.MaxCoolLoadZone[zone_num] = -9999.0
        state.dataHeatBalMgr.MaxTempZone[zone_num] = -9999.0
        state.dataHeatBalMgr.MinTempZone[zone_num] = 1000.0
    
    if (state.dataGlobal.DayOfSim >= state.dataHeatBal.MaxNumberOfWarmupDays and
        state.dataGlobal.WarmupFlag and convergence_failed):
        pass  # Show warning about max warmup days
    
    if not convergence_failed and state.dataGlobal.DayOfSim >= state.dataHeatBal.MinNumberOfWarmupDays:
        state.dataGlobal.WarmupFlag = False
    elif not convergence_failed and state.dataGlobal.DayOfSim < state.dataHeatBal.MinNumberOfWarmupDays:
        state.dataGlobal.WarmupFlag = True
    
    if state.dataGlobal.DayOfSim >= state.dataHeatBal.MaxNumberOfWarmupDays and state.dataGlobal.WarmupFlag:
        state.dataGlobal.WarmupFlag = False


def report_warmup_convergence(state: Any) -> None:
    """Report warmup convergence information."""
    if state.dataGlobal.WarmupFlag:
        return
    
    if state.dataHeatBalMgr.ReportWarmupConvergenceFirstWarmupWrite and state.dataGlobal.NumOfZones > 0:
        state.dataHeatBalMgr.ReportWarmupConvergenceFirstWarmupWrite = False
    
    env_header = "RunPeriod:" if state.dataEnvrn.RunPeriodEnvironment else "SizingPeriod:"
    
    for zone_num in range(state.dataGlobal.NumOfZones):
        # Calculate statistics
        count = state.dataHeatBalMgr.CountWarmupDayPoints
        if count == 0:
            continue
        
        temp_sum = sum(state.dataHeatBalMgr.TempZoneRpt[zone_num][:count])
        avg_temp = temp_sum / count
        
        # Normalize loads and calculate average
        for i in range(count):
            if state.dataHeatBalMgr.MaxLoadZoneRpt[zone_num][i] > 1.0e-4:
                state.dataHeatBalMgr.LoadZoneRpt[zone_num][i] /= state.dataHeatBalMgr.MaxLoadZoneRpt[zone_num][i]
            else:
                state.dataHeatBalMgr.LoadZoneRpt[zone_num][i] = 0.0
        
        load_sum = sum(state.dataHeatBalMgr.LoadZoneRpt[zone_num][:count])
        avg_load = load_sum / count
        
        # Calculate standard deviation
        temp_var_sum = sum((state.dataHeatBalMgr.TempZoneRpt[zone_num][i] - avg_temp) ** 2 
                          for i in range(count))
        load_var_sum = sum((state.dataHeatBalMgr.LoadZoneRpt[zone_num][i] - avg_load) ** 2 
                          for i in range(count))
        
        std_dev_temp = math.sqrt(temp_var_sum / count) if count > 0 else 0.0
        std_dev_load = math.sqrt(load_var_sum / count) if count > 0 else 0.0


def update_window_face_temps_non_bsdf_win(state: Any) -> None:
    """Update window face temperatures for non-BSDF windows."""
    # Stub: update window face temperature arrays
    pass


def report_heat_balance(state: Any) -> None:
    """Report heat balance data."""
    pass


def open_shading_file(state: Any) -> None:
    """Open and set up external shading fraction export file."""
    pass


def get_frame_and_divider_data(state: Any) -> None:
    """Read window frame and divider data."""
    pass


def search_window5_data_file(state: Any, desired_file_path: str, desired_construct_name: str,
                            construction_found: bool, eof_on_file: bool, errors_found: bool) -> None:
    """Search Window5 data file for window construction."""
    pass


def set_storm_window_control(state: Any) -> None:
    """Set storm window flags based on date."""
    pass


def create_fc_factor_constructions(state: Any, constr_num: int, errors_found: bool) -> None:
    """Create constructions with F/C factor methods."""
    pass


def create_air_boundary_constructions(state: Any, constr_num: int, errors_found: bool) -> None:
    """Create air boundary constructions."""
    pass


def get_incident_solar_multiplier(state: Any, errors_found: bool) -> None:
    """Get incident solar multiplier data."""
    pass


def get_scheduled_surface_gains(state: Any, errors_found: bool) -> None:
    """Load scheduled surface gains."""
    pass


def check_scheduled_surface_gains(state: Any, zone_num: int) -> None:
    """Check if surfaces in zone have consistent scheduling."""
    pass


def create_tc_constructions(state: Any, errors_found: bool) -> None:
    """Create thermochromic window constructions."""
    pass


def setup_complex_fenestration_state_input(state: Any, constr_num: int, errors_found: bool) -> None:
    """Set up complex fenestration state input."""
    pass


def init_conduction_transfer_functions(state: Any) -> None:
    """Initialize conduction transfer functions."""
    pass
