# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with dataSysVars, files, dataStrGlobals, dataGlobal, dataEnvrn
# - get_environment_variable: fn(name: StringRef, inout value: String)
# - env_var_on: fn(value: String) -> Bool
# - ShowSevereError: fn(state: EnergyPlusData, message: String)
# - ShowContinueError: fn(state: EnergyPlusData, message: String)
# - FileSystem.getParentDirectoryPath: fn(path: Path) -> Path
# - FileSystem.makeNativePath: fn(path: Path) -> Path
# - FileSystem.fileExists: fn(path: Path) -> Bool
# - FileSystem.getAbsolutePath: fn(path: Path) -> Path
# - Timer: struct with no-arg constructor
# - BaseGlobalStruct: trait (unused in Mojo)
# - Array1D_string: DynamicVector[String]

from math import *

alias IUNICODE_END = 0

@export
enum ShadingMethod:
    INVALID
    POLYGON_CLIPPING
    PIXEL_COUNTING
    SCHEDULED
    IMPORTED
    NUM

alias DDONLY_ENV_VAR = "DDONLY"
alias REVERSE_DD_ENV_VAR = "REVERSEDD"
alias FULL_ANNUAL_SIMULATION = "FULLANNUALRUN"
alias C_DEVELOPER_FLAG = "DeveloperFlag"
alias C_DISPLAY_ALL_WARNINGS = "DisplayAllWarnings"
alias C_DISPLAY_EXTRA_WARNINGS = "DisplayExtraWarnings"
alias C_DISPLAY_ADVANCED_REPORT_VARIABLES = "DisplayAdvancedReportVariables"
alias C_DISPLAY_UNUSED_OBJECTS = "DisplayUnusedObjects"
alias C_DISPLAY_UNUSED_SCHEDULES = "DisplayUnusedSchedules"
alias C_DISPLAY_ZONE_AIR_HEAT_BALANCE_OFF_BALANCE = "DisplayZoneAirHeatBalanceOffBalance"
alias C_SORT_IDD = "SortIDD"
alias C_REPORT_DURING_WARMUP = "ReportDuringWarmup"
alias C_REPORT_DURING_HVAC_SIZING_SIMULATION = "REPORTDURINGHVACSIZINGSIMULATION"
alias C_IGNORE_SOLAR_RADIATION = "IgnoreSolarRadiation"
alias C_IGNORE_BEAM_RADIATION = "IgnoreBeamRadiation"
alias C_IGNORE_DIFFUSE_RADIATION = "IgnoreDiffuseRadiation"
alias C_SUTHERLAND_HODGMAN = "SutherlandHodgman"
alias C_SLATER_BARSKY = "SlaterBarsky"
alias C_MINIMAL_SURFACE_VARIABLES = "CreateMinimalSurfaceVariables"
alias C_MINIMAL_SHADOWING = "MinimalShadowing"
alias C_INPUT_PATH_1 = "epin"
alias C_INPUT_PATH_2 = "input_path"
alias C_PROGRAM_PATH = "program_path"
alias C_TIMING_FLAG = "TimingFlag"
alias TRACK_AIR_LOOP_ENV_VAR = "TRACK_AIRLOOP"
alias TRACE_AIR_LOOP_ENV_VAR = "TRACE_AIRLOOP"
alias TRACE_HVAC_CONTROLLER_ENV_VAR = "TRACE_HVACCONTROLLER"
alias MIN_REPORT_FREQUENCY_ENV_VAR = "MINREPORTFREQUENCY"
alias C_DISPLAY_INPUT_IN_AUDIT_ENV_VAR = "DISPLAYINPUTINAUDIT"
alias CI_FORCE_TIME_STEP_ENV_VAR = "CI_FORCE_TIME_STEP"
alias C_BUFFERED_ERR_FILE_ENV_VAR = "BufferedErrFile"

struct Path:
    var path_str: String
    
    fn __init__(inout self, s: String = ""):
        self.path_str = s
    
    fn __truediv__(self, other: Path) -> Path:
        var result = self.path_str + "/" + other.path_str
        return Path(result)
    
    fn __str__(self) -> String:
        return self.path_str

struct PathStringPair:
    var path: Path
    var desc: String
    
    fn __init__(inout self, p: Path, d: String):
        self.path = p
        self.desc = d

@export
fn check_for_actual_file_path(state: EnergyPlusData, original_input_file_path: Path, context_string: String = "") -> Path:
    var found_file_path = Path()
    
    if state.dataSysVars.firstTime:
        state.files.audit.ensure_open(state, "CheckForActualFilePath", state.files.outputControl.audit)
        var tmp = String()
        
        get_environment_variable(DDONLY_ENV_VAR, tmp)
        state.dataSysVars.envinputpath1 = FileSystem.getParentDirectoryPath(Path(tmp))
        
        tmp = String()
        get_environment_variable(C_INPUT_PATH_2, tmp)
        state.dataSysVars.envinputpath2 = Path(tmp)
        
        tmp = String()
        get_environment_variable(C_PROGRAM_PATH, tmp)
        state.dataStrGlobals.ProgramPath = Path(tmp)
        state.dataSysVars.firstTime = False
    
    var input_file_path = FileSystem.makeNativePath(original_input_file_path)
    
    var paths_checked = DynamicVector[PathStringPair]()
    
    var paths_to_check = DynamicVector[PathStringPair]()
    paths_to_check.push_back(PathStringPair(input_file_path, "Current Working Directory"))
    paths_to_check.push_back(PathStringPair(state.dataStrGlobals.inputDirPath / input_file_path, "IDF Directory"))
    paths_to_check.push_back(PathStringPair(state.dataStrGlobals.exeDirectoryPath / input_file_path, "EnergyPlus Executable Directory"))
    paths_to_check.push_back(PathStringPair(state.dataSysVars.envinputpath1 / input_file_path, "\"epin\" Environment Variable"))
    paths_to_check.push_back(PathStringPair(state.dataSysVars.envinputpath2 / input_file_path, "\"input_path\" Environment Variable"))
    paths_to_check.push_back(PathStringPair(state.dataStrGlobals.CurrentWorkingFolder / input_file_path, "INI File Directory"))
    paths_to_check.push_back(PathStringPair(state.dataStrGlobals.ProgramPath / input_file_path, "\"program\", \"dir\" from INI File"))
    
    var num_paths_to_test = len(paths_to_check)
    if not state.dataSysVars.TestAllPaths:
        num_paths_to_test = len(paths_to_check) - 2
    
    for i in range(num_paths_to_test):
        if FileSystem.fileExists(paths_to_check[i].path):
            found_file_path = paths_to_check[i].path
            print("found (" + paths_to_check[i].desc + ")=" + FileSystem.getAbsolutePath(found_file_path).path_str)
            return found_file_path
        
        var current_path_dir = FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(paths_to_check[i].path))
        var current_path = PathStringPair(current_path_dir, paths_to_check[i].desc)
        
        var found = False
        for j in range(len(paths_checked)):
            if paths_checked[j].path.path_str == current_path.path.path_str:
                found = True
                break
        
        if not found:
            paths_checked.push_back(current_path)
        
        print("not found (" + paths_to_check[i].desc + ")=" + FileSystem.getAbsolutePath(paths_to_check[i].path).path_str)
    
    ShowSevereError(state, context_string + "\"" + original_input_file_path.path_str + "\" not found.")
    ShowContinueError(state, "  Paths searched:")
    for i in range(len(paths_checked)):
        ShowContinueError(state, "    " + paths_checked[i].desc + ": \"" + paths_checked[i].path.path_str + "\"")
    
    return found_file_path

@export
fn process_environment_variables(state: EnergyPlusData) -> None:
    var c_env_value = String()
    
    get_environment_variable(DDONLY_ENV_VAR, c_env_value)
    state.dataSysVars.DDOnly = env_var_on(c_env_value)
    if state.dataGlobal.DDOnlySimulation:
        state.dataSysVars.DDOnly = True
    
    c_env_value = String()
    get_environment_variable(REVERSE_DD_ENV_VAR, c_env_value)
    state.dataSysVars.ReverseDD = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(FULL_ANNUAL_SIMULATION, c_env_value)
    state.dataSysVars.FullAnnualRun = env_var_on(c_env_value)
    if state.dataGlobal.AnnualSimulation:
        state.dataSysVars.FullAnnualRun = True
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_ALL_WARNINGS, c_env_value)
    state.dataGlobal.DisplayAllWarnings = env_var_on(c_env_value)
    if state.dataGlobal.DisplayAllWarnings:
        state.dataGlobal.DisplayAllWarnings = True
        state.dataGlobal.DisplayExtraWarnings = True
        state.dataGlobal.DisplayUnusedSchedules = True
        state.dataGlobal.DisplayUnusedObjects = True
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_EXTRA_WARNINGS, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayExtraWarnings = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_UNUSED_OBJECTS, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayUnusedObjects = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_UNUSED_SCHEDULES, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayUnusedSchedules = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_ZONE_AIR_HEAT_BALANCE_OFF_BALANCE, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_ADVANCED_REPORT_VARIABLES, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayAdvancedReportVariables = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_REPORT_DURING_WARMUP, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.ReportDuringWarmup = env_var_on(c_env_value)
    if state.dataSysVars.ReverseDD:
        state.dataSysVars.ReportDuringWarmup = False
    
    c_env_value = String()
    get_environment_variable(C_REPORT_DURING_WARMUP, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.ReportDuringWarmup = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_REPORT_DURING_HVAC_SIZING_SIMULATION, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.ReportDuringHVACSizingSimulation = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_IGNORE_SOLAR_RADIATION, c_env_value)
    if len(c_env_value) > 0:
        state.dataEnvrn.IgnoreSolarRadiation = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_MINIMAL_SURFACE_VARIABLES, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.CreateMinimalSurfaceVariables = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_SORT_IDD, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.SortedIDD = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(MIN_REPORT_FREQUENCY_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.MinReportFrequency = c_env_value
    
    c_env_value = String()
    get_environment_variable(C_DEVELOPER_FLAG, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.DeveloperFlag = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_IGNORE_BEAM_RADIATION, c_env_value)
    if len(c_env_value) > 0:
        state.dataEnvrn.IgnoreBeamRadiation = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_IGNORE_DIFFUSE_RADIATION, c_env_value)
    if len(c_env_value) > 0:
        state.dataEnvrn.IgnoreDiffuseRadiation = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_SUTHERLAND_HODGMAN, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.SutherlandHodgman = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_SLATER_BARSKY, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.SlaterBarsky = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_MINIMAL_SHADOWING, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.lMinimalShadowing = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_TIMING_FLAG, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.TimingFlag = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(TRACK_AIR_LOOP_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.TrackAirLoopEnvFlag = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(TRACE_AIR_LOOP_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.TraceAirLoopEnvFlag = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(TRACE_HVAC_CONTROLLER_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.TraceHVACControllerEnvFlag = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_DISPLAY_INPUT_IN_AUDIT_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataGlobal.DisplayInputInAudit = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(CI_FORCE_TIME_STEP_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.ciForceTimeStep = env_var_on(c_env_value)
    
    c_env_value = String()
    get_environment_variable(C_BUFFERED_ERR_FILE_ENV_VAR, c_env_value)
    if len(c_env_value) > 0:
        state.dataSysVars.BufferedErrFileEnvVar = env_var_on(c_env_value)

struct SystemVarsData:
    var firstTime: Bool
    var shadingMethod: ShadingMethod
    var DDOnly: Bool
    var ReverseDD: Bool
    var FullAnnualRun: Bool
    var DeveloperFlag: Bool
    var TimingFlag: Bool
    var SutherlandHodgman: Bool
    var SlaterBarsky: Bool
    var DetailedSkyDiffuseAlgorithm: Bool
    var DetailedSolarTimestepIntegration: Bool
    var ReportExtShadingSunlitFrac: Bool
    var DisableGroupSelfShading: Bool
    var DisableAllSelfShading: Bool
    var DisableSelfShadingWithinGroup: Bool
    var DisableSelfShadingBetweenGroup: Bool
    var shadingGroupsNum: Int
    var shadingGroupZoneListNames: DynamicVector[String]
    var TrackAirLoopEnvFlag: Bool
    var TraceAirLoopEnvFlag: Bool
    var TraceHVACControllerEnvFlag: Bool
    var ReportDuringWarmup: Bool
    var ReportDuringHVACSizingSimulation: Bool
    var ReportDetailedWarmupConvergence: Bool
    var UpdateDataDuringWarmupExternalInterface: Bool
    var runtimeTimer: object
    var MinReportFrequency: String
    var SortedIDD: Bool
    var lMinimalShadowing: Bool
    var envinputpath1: Path
    var envinputpath2: Path
    var TestAllPaths: Bool
    var iEnvSetThreads: Int
    var lEnvSetThreadsInput: Bool
    var iepEnvSetThreads: Int
    var lepSetThreadsInput: Bool
    var iIDFSetThreads: Int
    var lIDFSetThreadsInput: Bool
    var inumActiveSims: Int
    var lnumActiveSims: Bool
    var MaxNumberOfThreads: Int
    var NumberIntRadThreads: Int
    var iNominalTotSurfaces: Int
    var Threading: Bool
    var ciForceTimeStep: Bool
    var BufferedErrFileEnvVar: Bool
    
    fn __init__(inout self):
        self.firstTime = True
        self.shadingMethod = ShadingMethod.POLYGON_CLIPPING
        self.DDOnly = False
        self.ReverseDD = False
        self.FullAnnualRun = False
        self.DeveloperFlag = False
        self.TimingFlag = False
        self.SutherlandHodgman = True
        self.SlaterBarsky = False
        self.DetailedSkyDiffuseAlgorithm = False
        self.DetailedSolarTimestepIntegration = False
        self.ReportExtShadingSunlitFrac = False
        self.DisableGroupSelfShading = False
        self.DisableAllSelfShading = False
        self.DisableSelfShadingWithinGroup = False
        self.DisableSelfShadingBetweenGroup = False
        self.shadingGroupsNum = 0
        self.shadingGroupZoneListNames = DynamicVector[String]()
        self.TrackAirLoopEnvFlag = False
        self.TraceAirLoopEnvFlag = False
        self.TraceHVACControllerEnvFlag = False
        self.ReportDuringWarmup = False
        self.ReportDuringHVACSizingSimulation = False
        self.ReportDetailedWarmupConvergence = False
        self.UpdateDataDuringWarmupExternalInterface = False
        self.runtimeTimer = object()
        self.MinReportFrequency = String()
        self.SortedIDD = True
        self.lMinimalShadowing = False
        self.envinputpath1 = Path()
        self.envinputpath2 = Path()
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
        self.ciForceTimeStep = False
        self.BufferedErrFileEnvVar = False
    
    fn init_constant_state(inout self, state: EnergyPlusData) -> None:
        pass
    
    fn init_state(inout self, state: EnergyPlusData) -> None:
        pass
    
    fn clear_state(inout self) -> None:
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
