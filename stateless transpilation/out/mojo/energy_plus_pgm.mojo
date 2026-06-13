from datetime import import now
import os
from sys import platform


# EXTERNAL DEPS (to wire in glue):
# - EnergyPlus::EnergyPlusData: state container for all simulation data (passed as parameter)
# - EnergyPlus::CommandLineInterface::ProcessArgs: processes command-line arguments
# - EnergyPlus::CommandLineInterface::runReadVarsESO: runs ReadVarsESO post-processor
# - EnergyPlus::CommandLineInterface::ReturnCodes: enum for return code values
# - EnergyPlus::DisplayString: outputs a message string
# - EnergyPlus::ShowMessage: shows a message
# - EnergyPlus::ShowWarningMessage: shows a warning message
# - EnergyPlus::ShowSevereError: shows a severe error message
# - EnergyPlus::GenOutputVariablesAuditReport: generates output variables audit report
# - EnergyPlus::Psychrometrics::ShowPsychrometricSummary: outputs psychrometric summary
# - EnergyPlus::Fluid::ReportOrphanFluids: reports orphan fluid definitions
# - EnergyPlus::Sched::ReportOrphanSchedules: reports orphan schedule definitions
# - EnergyPlus::SimulationManager::ManageSimulation: main simulation loop
# - EnergyPlus::InputProcessor::factory: creates InputProcessor instance
# - EnergyPlus::DataStringGlobals::VerString: version string constant
# - EnergyPlus::DataStringGlobals::pathChar: platform-specific path separator
# - EnergyPlus::DataSystemVariables::processEnvironmentVariables: processes environment setup
# - EnergyPlus::FatalError: exception class
# - EnergyPlus::EndEnergyPlus: cleanup and normal exit
# - EnergyPlus::AbortEnergyPlus: cleanup and error exit
# - initErrorFile: initializes error reporting file


struct EnergyPlusData:
    var dataStrGlobals: StringData
    var dataSysVars: SysVarsData
    var dataResultsFramework: ResultsFrameworkData
    var dataInputProcessing: InputProcessingData
    var dataGlobal: GlobalData
    var dataSQLiteProcedures: SQLiteData
    var files: FilesData


struct StringData:
    var CurrentDateTime: String
    var VerStringVar: String
    var ProgramPath: String


struct SysVarsData:
    var TestAllPaths: Bool


struct ResultsFrameworkData:
    pass


struct InputProcessingData:
    var inputProcessor: AnyPointer


struct GlobalData:
    var outputEpJSONConversionOnly: Bool
    var eplusRunningViaAPI: Bool
    var runReadVars: Bool
    var fProgressPtr: AnyPointer
    var fMessagePtr: AnyPointer


struct SQLiteData:
    var sqlite: AnyPointer


struct FilesData:
    pass


fn create_current_date_time_string() -> String:
    var now_val = now()
    var year = now_val.year
    var month = now_val.month
    var day = now_val.day
    var hour = now_val.hour
    var minute = now_val.minute
    
    var result = String.format_int(year, 4, '0')
    result += "."
    result += String.format_int(month, 2, '0')
    result += "."
    result += String.format_int(day, 2, '0')
    result += " "
    result += String.format_int(hour, 2, '0')
    result += ":"
    result += String.format_int(minute, 2, '0')
    return " YMD=" + result


fn energy_plus_pgm(args: List[String], filepath: String = "") -> Int32:
    var state = EnergyPlusData()
    
    var now_val = now()
    var year = now_val.year
    var month = now_val.month
    var day = now_val.day
    var hour = now_val.hour
    var minute = now_val.minute
    
    var datestring = String()
    # Format as YYYYMMDD
    datestring += String.format_int(year, 4, '0')
    datestring += String.format_int(month, 2, '0')
    datestring += String.format_int(day, 2, '0')
    
    if datestring.length() > 0:
        state.dataStrGlobals.CurrentDateTime = " YMD="
        state.dataStrGlobals.CurrentDateTime += String.format_int(year, 4, '0')
        state.dataStrGlobals.CurrentDateTime += "."
        state.dataStrGlobals.CurrentDateTime += String.format_int(month, 2, '0')
        state.dataStrGlobals.CurrentDateTime += "."
        state.dataStrGlobals.CurrentDateTime += String.format_int(day, 2, '0')
        state.dataStrGlobals.CurrentDateTime += " "
        state.dataStrGlobals.CurrentDateTime += String.format_int(hour, 2, '0')
        state.dataStrGlobals.CurrentDateTime += ":"
        state.dataStrGlobals.CurrentDateTime += String.format_int(minute, 2, '0')
    else:
        state.dataStrGlobals.CurrentDateTime = " unknown date/time"
    
    # CommandLineInterface.ProcessArgs(state, args)
    return run_energy_plus(state, filepath)


fn common_initialize(inout state: EnergyPlusData) -> None:
    # state.dataSysVars.runtimeTimer.tick()
    
    state.dataStrGlobals.CurrentDateTime = create_current_date_time_string()
    
    # state.dataResultsFramework.resultsFramework.SimulationInformation.setProgramVersion(
    #     state.dataStrGlobals.VerStringVar
    # )
    # state.dataResultsFramework.resultsFramework.SimulationInformation.setStartDateTimeStamp(
    #     state.dataStrGlobals.CurrentDateTime[5:]
    # )
    
    # DataSystemVariables.processEnvironmentVariables(state)


fn common_run(inout state: EnergyPlusData) -> Int32:
    # var errStatus = init_error_file(state)
    var errStatus: Int32 = 0
    if errStatus != 0:
        return errStatus
    
    state.dataSysVars.TestAllPaths = True
    
    # DisplayString(state, "EnergyPlus Starting")
    # DisplayString(state, state.dataStrGlobals.VerStringVar)
    
    try:
        if not state.dataInputProcessing.inputProcessor:
            # state.dataInputProcessing.inputProcessor = InputProcessor.factory()
            pass
        
        # state.dataInputProcessing.inputProcessor.processInput(state)
        
        if state.dataGlobal.outputEpJSONConversionOnly:
            # DisplayString(state, "Converted input file format. Exiting.")
            # return EndEnergyPlus(state)
            pass
    except:
        # return AbortEnergyPlus(state)
        return 1
    
    return 0


fn initialize_energy_plus(inout state: EnergyPlusData, filepath: String = "") -> Int32:
    common_initialize(state)
    
    if filepath.length() > 0:
        # DisplayString(state, "EnergyPlus Library: Changing directory to: " + filepath)
        var status: Int32
        if _get_platform() == "win32":
            # status = _chdir(filepath.cstr())
            status = 0
        else:
            # status = chdir(filepath.cstr())
            status = 0
        
        if status == 0:
            # DisplayString(state, "Directory change successful.")
            pass
        else:
            # DisplayString(state, "Couldn't change directory; aborting EnergyPlus")
            return 1
        
        var pathChar: String
        if _get_platform() == "win32":
            pathChar = "\\"
        else:
            pathChar = "/"
        
        state.dataStrGlobals.ProgramPath = filepath + pathChar
        # CommandLineInterface.ProcessArgs(state, List[String]("energyplus"))
    
    return common_run(state)


fn initialize_as_library(inout state: EnergyPlusData) -> Int32:
    common_initialize(state)
    return common_run(state)


fn wrap_up_energy_plus(inout state: EnergyPlusData) -> Int32:
    try:
        # ShowMessage(state, "Simulation Error Summary *************")
        
        # GenOutputVariablesAuditReport(state)
        
        # Psychrometrics.ShowPsychrometricSummary(state, state.files.audit)
        
        # state.dataInputProcessing.inputProcessor.reportOrphanRecordObjects(state)
        
        # Fluid.ReportOrphanFluids(state)
        # Sched.ReportOrphanSchedules(state)
        
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite = AnyPointer()
        
        if state.dataInputProcessing.inputProcessor:
            state.dataInputProcessing.inputProcessor = AnyPointer()
        
        if state.dataGlobal.runReadVars:
            # if state.files.outputControl.csv:
            #     ShowWarningMessage(state, "Native CSV output requested in input file, but running ReadVarsESO due to command line argument.")
            #     ShowWarningMessage(state, "This will overwrite the native CSV output.")
            # var status = CommandLineInterface.runReadVarsESO(state)
            # if status != 0:
            #     return status
            pass
    except:
        # return AbortEnergyPlus(state)
        return 1
    
    # return EndEnergyPlus(state)
    return 0


fn run_energy_plus(inout state: EnergyPlusData, filepath: String = "") -> Int32:
    var status = initialize_energy_plus(state, filepath)
    if status != 0 or state.dataGlobal.outputEpJSONConversionOnly:
        return status
    
    try:
        # SimulationManager.ManageSimulation(state)
        pass
    except:
        # return AbortEnergyPlus(state)
        return 1
    
    return wrap_up_energy_plus(state)


fn run_energy_plus_as_library(inout state: EnergyPlusData, args: List[String]) -> Int32:
    state.dataGlobal.eplusRunningViaAPI = True
    
    # Clean cin, cerr, cout flags
    # (Platform specific, not directly translatable)
    
    # var return_code = CommandLineInterface.ProcessArgs(state, args)
    var return_code: Int32 = 0
    
    # if return_code == CommandLineInterface.ReturnCodes.FAILURE:
    #     return return_code
    # if return_code == CommandLineInterface.ReturnCodes.SUCCESS_BUT_HELPER:
    #     return CommandLineInterface.ReturnCodes.SUCCESS
    
    var status = initialize_as_library(state)
    if status != 0 or state.dataGlobal.outputEpJSONConversionOnly:
        return status
    
    try:
        # SimulationManager.ManageSimulation(state)
        pass
    except:
        # return AbortEnergyPlus(state)
        return 1
    
    return wrap_up_energy_plus(state)


fn store_progress_callback(inout state: EnergyPlusData, f: AnyPointer) -> None:
    state.dataGlobal.fProgressPtr = f


fn store_message_callback(inout state: EnergyPlusData, f: AnyPointer) -> None:
    state.dataGlobal.fMessagePtr = f


fn _get_platform() -> String:
    return platform()
