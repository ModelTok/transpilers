# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataSysVars, files, dataStrGlobals, dataGlobal, dataEnvrn
# - get_environment_variable: function(name: str, value: str) -> str (C++ stdlib)
# - env_var_on: function(value: str) -> bool
# - ShowSevereError: function(state, message: str)
# - ShowContinueError: function(state, message: str)
# - FileSystem.getParentDirectoryPath: function(path) -> Path
# - FileSystem.makeNativePath: function(path) -> Path
# - FileSystem.fileExists: function(path) -> bool
# - FileSystem.getAbsolutePath: function(path) -> Path
# - Timer: class with no-arg constructor
# - BaseGlobalStruct: base class (unused in Python)
# - Array1D_string: use List[str]

from pathlib import Path
from enum import Enum
from dataclasses import dataclass, field
from typing import List, Tuple

IUNICODE_END = 0

class ShadingMethod(Enum):
    INVALID = -1
    POLYGON_CLIPPING = 0
    PIXEL_COUNTING = 1
    SCHEDULED = 2
    IMPORTED = 3
    NUM = 4

DDONLY_ENV_VAR = "DDONLY"
REVERSE_DD_ENV_VAR = "REVERSEDD"
FULL_ANNUAL_SIMULATION = "FULLANNUALRUN"
C_DEVELOPER_FLAG = "DeveloperFlag"
C_DISPLAY_ALL_WARNINGS = "DisplayAllWarnings"
C_DISPLAY_EXTRA_WARNINGS = "DisplayExtraWarnings"
C_DISPLAY_ADVANCED_REPORT_VARIABLES = "DisplayAdvancedReportVariables"
C_DISPLAY_UNUSED_OBJECTS = "DisplayUnusedObjects"
C_DISPLAY_UNUSED_SCHEDULES = "DisplayUnusedSchedules"
C_DISPLAY_ZONE_AIR_HEAT_BALANCE_OFF_BALANCE = "DisplayZoneAirHeatBalanceOffBalance"
C_SORT_IDD = "SortIDD"
C_REPORT_DURING_WARMUP = "ReportDuringWarmup"
C_REPORT_DURING_HVAC_SIZING_SIMULATION = "REPORTDURINGHVACSIZINGSIMULATION"
C_IGNORE_SOLAR_RADIATION = "IgnoreSolarRadiation"
C_IGNORE_BEAM_RADIATION = "IgnoreBeamRadiation"
C_IGNORE_DIFFUSE_RADIATION = "IgnoreDiffuseRadiation"
C_SUTHERLAND_HODGMAN = "SutherlandHodgman"
C_SLATER_BARSKY = "SlaterBarsky"
C_MINIMAL_SURFACE_VARIABLES = "CreateMinimalSurfaceVariables"
C_MINIMAL_SHADOWING = "MinimalShadowing"
C_INPUT_PATH_1 = "epin"
C_INPUT_PATH_2 = "input_path"
C_PROGRAM_PATH = "program_path"
C_TIMING_FLAG = "TimingFlag"
TRACK_AIR_LOOP_ENV_VAR = "TRACK_AIRLOOP"
TRACE_AIR_LOOP_ENV_VAR = "TRACE_AIRLOOP"
TRACE_HVAC_CONTROLLER_ENV_VAR = "TRACE_HVACCONTROLLER"
MIN_REPORT_FREQUENCY_ENV_VAR = "MINREPORTFREQUENCY"
C_DISPLAY_INPUT_IN_AUDIT_ENV_VAR = "DISPLAYINPUTINAUDIT"
CI_FORCE_TIME_STEP_ENV_VAR = "CI_FORCE_TIME_STEP"
C_BUFFERED_ERR_FILE_ENV_VAR = "BufferedErrFile"

def check_for_actual_file_path(state, original_input_file_path: Path, context_string: str = "") -> Path:
    found_file_path = Path()
    
    if state.dataSysVars.firstTime:
        state.files.audit.ensure_open(state, "CheckForActualFilePath", state.files.outputControl.audit)
        tmp = ""
        
        get_environment_variable(C_INPUT_PATH_1, tmp)
        state.dataSysVars.envinputpath1 = FileSystem.getParentDirectoryPath(Path(tmp))
        
        get_environment_variable(C_INPUT_PATH_2, tmp)
        state.dataSysVars.envinputpath2 = Path(tmp)
        
        get_environment_variable(C_PROGRAM_PATH, tmp)
        state.dataStrGlobals.ProgramPath = Path(tmp)
        state.dataSysVars.firstTime = False
    
    input_file_path = FileSystem.makeNativePath(original_input_file_path)
    
    paths_checked: List[Tuple[Path, str]] = []
    
    paths_to_check = [
        (input_file_path, "Current Working Directory"),
        (state.dataStrGlobals.inputDirPath / input_file_path, "IDF Directory"),
        (state.dataStrGlobals.exeDirectoryPath / input_file_path, "EnergyPlus Executable Directory"),
        (state.dataSysVars.envinputpath1 / input_file_path, '"epin" Environment Variable'),
        (state.dataSysVars.envinputpath2 / input_file_path, '"input_path" Environment Variable'),
        (state.dataStrGlobals.CurrentWorkingFolder / input_file_path, "INI File Directory"),
        (state.dataStrGlobals.ProgramPath / input_file_path, '"program", "dir" from INI File'),
    ]
    
    num_paths_to_test = len(paths_to_check) if state.dataSysVars.TestAllPaths else len(paths_to_check) - 2
    
    for i in range(num_paths_to_test):
        if FileSystem.fileExists(paths_to_check[i][0]):
            found_file_path = paths_to_check[i][0]
            print(f"found ({paths_to_check[i][1]})={FileSystem.getAbsolutePath(found_file_path)}")
            return found_file_path
        
        current_path_dir = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(paths_to_check[i][0]))
        current_path = (current_path_dir, paths_to_check[i][1])
        found = False
        for path in paths_checked:
            if path[0] == current_path[0]:
                found = True
                break
        if not found:
            paths_checked.append(current_path)
        
        print(f"not found ({paths_to_check[i][1]})={FileSystem.getAbsolutePath(paths_to_check[i][0])}")
    
    ShowSevereError(state, f'{context_string}"{original_input_file_path}" not found.')
    ShowContinueError(state, "  Paths searched:")
    for path in paths_checked:
        ShowContinueError(state, f'    {path[1]}: "{path[0]}"')
    
    return found_file_path

def process_environment_variables(state) -> None:
    c_env_value = ""
    
    get_environment_variable(DDONLY_ENV_VAR, c_env_value)
    state.dataSysVars.DDOnly = env_var_on(c_env_value)
    if state.dataGlobal.DDOnlySimulation:
        state.dataSysVars.DDOnly = True
    
    get_environment_variable(REVERSE_DD_ENV_VAR, c_env_value)
    state.dataSysVars.ReverseDD = env_var_on(c_env_value)
    
    get_environment_variable(FULL_ANNUAL_SIMULATION, c_env_value)
    state.dataSysVars.FullAnnualRun = env_var_on(c_env_value)
    if state.dataGlobal.AnnualSimulation:
        state.dataSysVars.FullAnnualRun = True
    
    get_environment_variable(C_DISPLAY_ALL_WARNINGS, c_env_value)
    state.dataGlobal.DisplayAllWarnings = env_var_on(c_env_value)
    if state.dataGlobal.DisplayAllWarnings:
        state.dataGlobal.DisplayAllWarnings = True
        state.dataGlobal.DisplayExtraWarnings = True
        state.dataGlobal.DisplayUnusedSchedules = True
        state.dataGlobal.DisplayUnusedObjects = True
    
    get_environment_variable(C_DISPLAY_EXTRA_WARNINGS, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayExtraWarnings = env_var_on(c_env_value)
    
    get_environment_variable(C_DISPLAY_UNUSED_OBJECTS, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayUnusedObjects = env_var_on(c_env_value)
    
    get_environment_variable(C_DISPLAY_UNUSED_SCHEDULES, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayUnusedSchedules = env_var_on(c_env_value)
    
    get_environment_variable(C_DISPLAY_ZONE_AIR_HEAT_BALANCE_OFF_BALANCE, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance = env_var_on(c_env_value)
    
    get_environment_variable(C_DISPLAY_ADVANCED_REPORT_VARIABLES, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayAdvancedReportVariables = env_var_on(c_env_value)
    
    get_environment_variable(C_REPORT_DURING_WARMUP, c_env_value)
    if c_env_value:
        state.dataSysVars.ReportDuringWarmup = env_var_on(c_env_value)
    if state.dataSysVars.ReverseDD:
        state.dataSysVars.ReportDuringWarmup = False
    
    get_environment_variable(C_REPORT_DURING_WARMUP, c_env_value)
    if c_env_value:
        state.dataSysVars.ReportDuringWarmup = env_var_on(c_env_value)
    
    get_environment_variable(C_REPORT_DURING_HVAC_SIZING_SIMULATION, c_env_value)
    if c_env_value:
        state.dataSysVars.ReportDuringHVACSizingSimulation = env_var_on(c_env_value)
    
    get_environment_variable(C_IGNORE_SOLAR_RADIATION, c_env_value)
    if c_env_value:
        state.dataEnvrn.IgnoreSolarRadiation = env_var_on(c_env_value)
    
    get_environment_variable(C_MINIMAL_SURFACE_VARIABLES, c_env_value)
    if c_env_value:
        state.dataGlobal.CreateMinimalSurfaceVariables = env_var_on(c_env_value)
    
    get_environment_variable(C_SORT_IDD, c_env_value)
    if c_env_value:
        state.dataSysVars.SortedIDD = env_var_on(c_env_value)
    
    get_environment_variable(MIN_REPORT_FREQUENCY_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.MinReportFrequency = c_env_value
    
    get_environment_variable(C_DEVELOPER_FLAG, c_env_value)
    if c_env_value:
        state.dataSysVars.DeveloperFlag = env_var_on(c_env_value)
    
    get_environment_variable(C_IGNORE_BEAM_RADIATION, c_env_value)
    if c_env_value:
        state.dataEnvrn.IgnoreBeamRadiation = env_var_on(c_env_value)
    
    get_environment_variable(C_IGNORE_DIFFUSE_RADIATION, c_env_value)
    if c_env_value:
        state.dataEnvrn.IgnoreDiffuseRadiation = env_var_on(c_env_value)
    
    get_environment_variable(C_SUTHERLAND_HODGMAN, c_env_value)
    if c_env_value:
        state.dataSysVars.SutherlandHodgman = env_var_on(c_env_value)
    
    get_environment_variable(C_SLATER_BARSKY, c_env_value)
    if c_env_value:
        state.dataSysVars.SlaterBarsky = env_var_on(c_env_value)
    
    get_environment_variable(C_MINIMAL_SHADOWING, c_env_value)
    if c_env_value:
        state.dataSysVars.lMinimalShadowing = env_var_on(c_env_value)
    
    get_environment_variable(C_TIMING_FLAG, c_env_value)
    if c_env_value:
        state.dataSysVars.TimingFlag = env_var_on(c_env_value)
    
    get_environment_variable(TRACK_AIR_LOOP_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.TrackAirLoopEnvFlag = env_var_on(c_env_value)
    
    get_environment_variable(TRACE_AIR_LOOP_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.TraceAirLoopEnvFlag = env_var_on(c_env_value)
    
    get_environment_variable(TRACE_HVAC_CONTROLLER_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.TraceHVACControllerEnvFlag = env_var_on(c_env_value)
    
    get_environment_variable(C_DISPLAY_INPUT_IN_AUDIT_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataGlobal.DisplayInputInAudit = env_var_on(c_env_value)
    
    get_environment_variable(CI_FORCE_TIME_STEP_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.ciForceTimeStep = env_var_on(c_env_value)
    
    get_environment_variable(C_BUFFERED_ERR_FILE_ENV_VAR, c_env_value)
    if c_env_value:
        state.dataSysVars.BufferedErrFileEnvVar = env_var_on(c_env_value)

@dataclass
class SystemVarsData:
    firstTime: bool = True
    shadingMethod: ShadingMethod = ShadingMethod.POLYGON_CLIPPING
    DDOnly: bool = False
    ReverseDD: bool = False
    FullAnnualRun: bool = False
    DeveloperFlag: bool = False
    TimingFlag: bool = False
    SutherlandHodgman: bool = True
    SlaterBarsky: bool = False
    DetailedSkyDiffuseAlgorithm: bool = False
    DetailedSolarTimestepIntegration: bool = False
    ReportExtShadingSunlitFrac: bool = False
    DisableGroupSelfShading: bool = False
    DisableAllSelfShading: bool = False
    DisableSelfShadingWithinGroup: bool = False
    DisableSelfShadingBetweenGroup: bool = False
    shadingGroupsNum: int = 0
    shadingGroupZoneListNames: List[str] = field(default_factory=list)
    TrackAirLoopEnvFlag: bool = False
    TraceAirLoopEnvFlag: bool = False
    TraceHVACControllerEnvFlag: bool = False
    ReportDuringWarmup: bool = False
    ReportDuringHVACSizingSimulation: bool = False
    ReportDetailedWarmupConvergence: bool = False
    UpdateDataDuringWarmupExternalInterface: bool = False
    runtimeTimer: object = field(default_factory=object)
    MinReportFrequency: str = ""
    SortedIDD: bool = True
    lMinimalShadowing: bool = False
    envinputpath1: Path = field(default_factory=Path)
    envinputpath2: Path = field(default_factory=Path)
    TestAllPaths: bool = False
    iEnvSetThreads: int = 0
    lEnvSetThreadsInput: bool = False
    iepEnvSetThreads: int = 0
    lepSetThreadsInput: bool = False
    iIDFSetThreads: int = 0
    lIDFSetThreadsInput: bool = False
    inumActiveSims: int = 1
    lnumActiveSims: bool = False
    MaxNumberOfThreads: int = 1
    NumberIntRadThreads: int = 1
    iNominalTotSurfaces: int = 0
    Threading: bool = False
    ciForceTimeStep: bool = False
    BufferedErrFileEnvVar: bool = False
    
    def init_constant_state(self, state) -> None:
        pass
    
    def init_state(self, state) -> None:
        pass
    
    def clear_state(self) -> None:
        self.shadingMethod = ShadingMethod.POLYGON_CLIPPING
        self.DDOnly = False
        self.ReverseDD = False
        self.FullAnnualRun = False
        self.DeveloperFlag = False
        self.TimingFlag = False
        self.firstTime = True
        self.SutherlandHodgman = True
        self.SlaterBarsky = False
        self.DetailedSkyDiffuseAlgorithm = False
        self.DetailedSolarTimestepIntegration = False
        self.ReportExtShadingSunlitFrac = False
        self.DisableGroupSelfShading = False
        self.DisableAllSelfShading = False
        self.TrackAirLoopEnvFlag = False
        self.TraceAirLoopEnvFlag = False
        self.TraceHVACControllerEnvFlag = False
        self.ReportDuringWarmup = False
        self.ReportDuringHVACSizingSimulation = False
        self.ReportDetailedWarmupConvergence = False
        self.UpdateDataDuringWarmupExternalInterface = False
        self.runtimeTimer = object()
        self.SortedIDD = True
        self.lMinimalShadowing = False
        self.TestAllPaths = False
        self.iEnvSetThreads = 0
        self.lEnvSetThreadsInput = False
        self.iepEnvSetThreads = 0
        self.lepSetThreadsInput = False
        self.iIDFSetThreads = 0
        self.lIDFSetThreadsInput = False
        self.inumActiveSims = 1
        self.lnumActiveSims = False
        self.MaxNumberOfThreads = 1
        self.NumberIntRadThreads = 1
        self.iNominalTotSurfaces = 0
        self.Threading = False
