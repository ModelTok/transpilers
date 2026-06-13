from ObjexxFCL.environment import get_environment_variable, env_var_on
from FileSystem import FileSystem
from UtilityRoutines import UtilityRoutines
from pathlib import Path
alias DDOnlyEnvVar = "DDONLY"
alias ReverseDDEnvVar = "REVERSEDD"
alias FullAnnualSimulation = "FULLANNUALRUN"
alias cDeveloperFlag = "DeveloperFlag"
alias cDisplayAllWarnings = "DisplayAllWarnings"
alias cDisplayExtraWarnings = "DisplayExtraWarnings"
alias cDisplayAdvancedReportVariables = "DisplayAdvancedReportVariables"
alias cDisplayUnusedObjects = "DisplayUnusedObjects"
alias cDisplayUnusedSchedules = "DisplayUnusedSchedules"
alias cDisplayZoneAirHeatBalanceOffBalance = "DisplayZoneAirHeatBalanceOffBalance"
alias cSortIDD = "SortIDD"
alias cReportDuringWarmup = "ReportDuringWarmup"
alias cReportDuringHVACSizingSimulation = "REPORTDURINGHVACSIZINGSIMULATION"
alias cIgnoreSolarRadiation = "IgnoreSolarRadiation"
alias cIgnoreBeamRadiation = "IgnoreBeamRadiation"
alias cIgnoreDiffuseRadiation = "IgnoreDiffuseRadiation"
alias cSutherlandHodgman = "SutherlandHodgman"
alias cSlaterBarsky = "SlaterBarsky"
alias cMinimalSurfaceVariables = "CreateMinimalSurfaceVariables"
alias cMinimalShadowing = "MinimalShadowing"
alias cInputPath1 = "epin"
alias cInputPath2 = "input_path"
alias cProgramPath = "program_path"
alias cTimingFlag = "TimingFlag"
alias TrackAirLoopEnvVar = "TRACK_AIRLOOP"
alias TraceAirLoopEnvVar = "TRACE_AIRLOOP"
alias TraceHVACControllerEnvVar = "TRACE_HVACCONTROLLER"
alias MinReportFrequencyEnvVar = "MINREPORTFREQUENCY"
alias cDisplayInputInAuditEnvVar = "DISPLAYINPUTINAUDIT"
alias ciForceTimeStepEnvVar = "CI_FORCE_TIME_STEP"
alias cBufferedErrFileEnvVar = "BufferedErrFile"
def CheckForActualFilePath(
    state: EnergyPlusData,
    originalInputFilePath: Path,
    contextString: String = String()
) -> Path:
    # Helper to try and locate a file in common folders if it's not found directly (such as when passed as a filename only). Looks in current
    # working folder, programs folder, etc.
    # Returns an empty path if not found.
    var foundFilePath: Path
    if state.dataSysVars.firstTime:
        state.files.audit.ensure_open(state, "CheckForActualFilePath", state.files.outputControl.audit)
        var tmp: String
        get_environment_variable(cInputPath1, tmp)
        state.dataSysVars.envinputpath1 = FileSystem.getParentDirectoryPath(Path(tmp))
        get_environment_variable(cInputPath2, tmp)
        state.dataSysVars.envinputpath2 = Path(tmp)
        get_environment_variable(cProgramPath, tmp)
        state.dataStrGlobals.ProgramPath = Path(tmp)
        state.dataSysVars.firstTime = False
    var InputFilePath = FileSystem.makeNativePath(originalInputFilePath)
    var pathsChecked: List[Tuple[Path, String]] = List[Tuple[Path, String]]()
    var pathsToCheck: Tuple[Tuple[Path, String], 7] = (
        (InputFilePath, "Current Working Directory"),
        (state.dataStrGlobals.inputDirPath / InputFilePath, "IDF Directory"),
        (state.dataStrGlobals.exeDirectoryPath / InputFilePath, "EnergyPlus Executable Directory"),
        (state.dataSysVars.envinputpath1 / InputFilePath, "\"epin\" Environment Variable"),
        (state.dataSysVars.envinputpath2 / InputFilePath, "\"input_path\" Environment Variable"),
        (state.dataStrGlobals.CurrentWorkingFolder / InputFilePath, "INI File Directory"),
        (state.dataStrGlobals.ProgramPath / InputFilePath, "\"program\", \"dir\" from INI File")
    )
    var numPathsToTest: Int = (len(pathsToCheck) - 2) if not state.dataSysVars.TestAllPaths else len(pathsToCheck)
    for i in range(numPathsToTest):
        if FileSystem.fileExists(pathsToCheck[i].first):
            foundFilePath = pathsToCheck[i].first
            print(f"found ({pathsToCheck[i].second})={FileSystem.getAbsolutePath(foundFilePath)}", file=state.files.audit)
            return foundFilePath
        var currentPath: Tuple[Path, String] = (FileSystem.getParentDirectoryPath(FileSystem.getAbsolutePath(pathsToCheck[i].first)), pathsToCheck[i].second)
        var found: Bool = False
        for path in pathsChecked:
            if path.first == currentPath.first:
                found = True
                break
        if not found:
            pathsChecked.append(currentPath)
        print(f"not found ({pathsToCheck[i].second})={FileSystem.getAbsolutePath(pathsToCheck[i].first)}", file=state.files.audit)
    UtilityRoutines.ShowSevereError(state, f"\"{contextString}\"{originalInputFilePath.string()} not found.")
    UtilityRoutines.ShowContinueError(state, "  Paths searched:")
    for path in pathsChecked:
        UtilityRoutines.ShowContinueError(state, f"    {path.second}: \"{path.first.string()}\"")
    return foundFilePath
def processEnvironmentVariables(state: EnergyPlusData):
    var cEnvValue: String
    get_environment_variable(DDOnlyEnvVar, cEnvValue)
    state.dataSysVars.DDOnly = env_var_on(cEnvValue)
    if state.dataGlobal.DDOnlySimulation:
        state.dataSysVars.DDOnly = True
    get_environment_variable(ReverseDDEnvVar, cEnvValue)
    state.dataSysVars.ReverseDD = env_var_on(cEnvValue)
    get_environment_variable(FullAnnualSimulation, cEnvValue)
    state.dataSysVars.FullAnnualRun = env_var_on(cEnvValue)
    if state.dataGlobal.AnnualSimulation:
        state.dataSysVars.FullAnnualRun = True
    get_environment_variable(cDisplayAllWarnings, cEnvValue)
    state.dataGlobal.DisplayAllWarnings = env_var_on(cEnvValue)
    if state.dataGlobal.DisplayAllWarnings:
        state.dataGlobal.DisplayAllWarnings = True
        state.dataGlobal.DisplayExtraWarnings = True
        state.dataGlobal.DisplayUnusedSchedules = True
        state.dataGlobal.DisplayUnusedObjects = True
    get_environment_variable(cDisplayExtraWarnings, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayExtraWarnings = env_var_on(cEnvValue)
    get_environment_variable(cDisplayUnusedObjects, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayUnusedObjects = env_var_on(cEnvValue)
    get_environment_variable(cDisplayUnusedSchedules, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayUnusedSchedules = env_var_on(cEnvValue)
    get_environment_variable(cDisplayZoneAirHeatBalanceOffBalance, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance = env_var_on(cEnvValue)
    get_environment_variable(cDisplayAdvancedReportVariables, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayAdvancedReportVariables = env_var_on(cEnvValue)
    get_environment_variable(cReportDuringWarmup, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.ReportDuringWarmup = env_var_on(cEnvValue)
    if state.dataSysVars.ReverseDD:
        state.dataSysVars.ReportDuringWarmup = False
    get_environment_variable(cReportDuringWarmup, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.ReportDuringWarmup = env_var_on(cEnvValue)
    get_environment_variable(cReportDuringHVACSizingSimulation, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.ReportDuringHVACSizingSimulation = env_var_on(cEnvValue)
    get_environment_variable(cIgnoreSolarRadiation, cEnvValue)
    if cEnvValue != "":
        state.dataEnvrn.IgnoreSolarRadiation = env_var_on(cEnvValue)
    get_environment_variable(cMinimalSurfaceVariables, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.CreateMinimalSurfaceVariables = env_var_on(cEnvValue)
    get_environment_variable(cSortIDD, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.SortedIDD = env_var_on(cEnvValue)
    get_environment_variable(MinReportFrequencyEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.MinReportFrequency = cEnvValue
    get_environment_variable(cDeveloperFlag, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.DeveloperFlag = env_var_on(cEnvValue)
    get_environment_variable(cIgnoreBeamRadiation, cEnvValue)
    if cEnvValue != "":
        state.dataEnvrn.IgnoreBeamRadiation = env_var_on(cEnvValue)
    get_environment_variable(cIgnoreDiffuseRadiation, cEnvValue)
    if cEnvValue != "":
        state.dataEnvrn.IgnoreDiffuseRadiation = env_var_on(cEnvValue)
    get_environment_variable(cSutherlandHodgman, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.SutherlandHodgman = env_var_on(cEnvValue)
    get_environment_variable(cSlaterBarsky, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.SlaterBarsky = env_var_on(cEnvValue)
    get_environment_variable(cMinimalShadowing, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.lMinimalShadowing = env_var_on(cEnvValue)
    get_environment_variable(cTimingFlag, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.TimingFlag = env_var_on(cEnvValue)
    get_environment_variable(TrackAirLoopEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.TrackAirLoopEnvFlag = env_var_on(cEnvValue)
    get_environment_variable(TraceAirLoopEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.TraceAirLoopEnvFlag = env_var_on(cEnvValue)
    get_environment_variable(TraceHVACControllerEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.TraceHVACControllerEnvFlag = env_var_on(cEnvValue)
    get_environment_variable(cDisplayInputInAuditEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataGlobal.DisplayInputInAudit = env_var_on(cEnvValue)
    get_environment_variable(ciForceTimeStepEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.ciForceTimeStep = env_var_on(cEnvValue)
    get_environment_variable(cBufferedErrFileEnvVar, cEnvValue)
    if cEnvValue != "":
        state.dataSysVars.BufferedErrFileEnvVar = env_var_on(cEnvValue)