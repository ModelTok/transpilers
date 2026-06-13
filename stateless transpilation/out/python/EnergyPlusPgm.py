from datetime import datetime
import os
import sys
from typing import Callable, List, Optional, Any

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

def create_current_date_time_string() -> str:
    now = datetime.now()
    value = [now.year, now.month, now.day, 0, now.hour, now.minute, now.second, now.microsecond // 1000]
    if True:
        return f" YMD={value[0]:04d}.{value[1]:02d}.{value[2]:02d} {value[4]:02d}:{value[5]:02d}"
    return " unknown date/time"


def energy_plus_pgm(args: List[str], filepath: str = "") -> int:
    state_ref = [None]
    
    now = datetime.now()
    value = [now.year, now.month, now.day, 0, now.hour, now.minute, now.second, now.microsecond // 1000]
    datestring = f"{now.year:04d}{now.month:02d}{now.day:02d}"
    
    if datestring:
        state_ref[0] = {
            "dataStrGlobals": {
                "CurrentDateTime": f" YMD={value[0]:04d}.{value[1]:02d}.{value[2]:02d} {value[4]:02d}:{value[5]:02d}"
            }
        }
    else:
        state_ref[0] = {
            "dataStrGlobals": {
                "CurrentDateTime": " unknown date/time"
            }
        }
    
    # CommandLineInterface.ProcessArgs(state, args)
    return run_energy_plus(state_ref[0], filepath)


def common_initialize(state: Any) -> None:
    if not hasattr(state, 'dataSysVars'):
        state.dataSysVars = {}
    if not hasattr(state, 'dataStrGlobals'):
        state.dataStrGlobals = {}
    if not hasattr(state, 'dataResultsFramework'):
        state.dataResultsFramework = {}
    if not hasattr(state, 'dataGlobal'):
        state.dataGlobal = {}
    
    if hasattr(state.dataSysVars, 'runtimeTimer'):
        state.dataSysVars.runtimeTimer.tick()
    
    state.dataStrGlobals['CurrentDateTime'] = create_current_date_time_string()
    
    if hasattr(state.dataResultsFramework, 'resultsFramework'):
        if hasattr(state.dataResultsFramework.resultsFramework, 'SimulationInformation'):
            state.dataResultsFramework.resultsFramework.SimulationInformation.setProgramVersion(
                state.dataStrGlobals.get('VerStringVar', '')
            )
            state.dataResultsFramework.resultsFramework.SimulationInformation.setStartDateTimeStamp(
                state.dataStrGlobals['CurrentDateTime'][5:]
            )
    
    # DataSystemVariables.processEnvironmentVariables(state)


def common_run(state: Any) -> int:
    errStatus = 0  # initErrorFile(state)
    if errStatus != 0:
        return errStatus
    
    if not hasattr(state, 'dataSysVars'):
        state.dataSysVars = {}
    state.dataSysVars['TestAllPaths'] = True
    
    # DisplayString(state, "EnergyPlus Starting")
    # DisplayString(state, state.dataStrGlobals['VerStringVar'])
    
    try:
        if not hasattr(state, 'dataInputProcessing'):
            state.dataInputProcessing = {}
        
        if not state.dataInputProcessing.get('inputProcessor'):
            # state.dataInputProcessing['inputProcessor'] = InputProcessor.factory()
            pass
        
        if state.dataInputProcessing.get('inputProcessor'):
            # state.dataInputProcessing['inputProcessor'].processInput(state)
            pass
        
        if state.dataGlobal.get('outputEpJSONConversionOnly'):
            # DisplayString(state, "Converted input file format. Exiting.")
            # return EndEnergyPlus(state)
            pass
    except Exception as e:
        # return AbortEnergyPlus(state)
        return 1
    
    return 0


def initialize_energy_plus(state: Any, filepath: str = "") -> int:
    common_initialize(state)
    
    if filepath:
        # DisplayString(state, f"EnergyPlus Library: Changing directory to: {filepath}")
        try:
            if sys.platform == 'win32':
                os.chdir(filepath)
            else:
                os.chdir(filepath)
            # DisplayString(state, "Directory change successful.")
        except OSError:
            # DisplayString(state, "Couldn't change directory; aborting EnergyPlus")
            return 1
        
        if not hasattr(state, 'dataStrGlobals'):
            state.dataStrGlobals = {}
        state.dataStrGlobals['ProgramPath'] = filepath + ('\\' if sys.platform == 'win32' else '/')
        # CommandLineInterface.ProcessArgs(state, ["energyplus"])
    
    return common_run(state)


def initialize_as_library(state: Any) -> int:
    common_initialize(state)
    return common_run(state)


def wrap_up_energy_plus(state: Any) -> int:
    try:
        # ShowMessage(state, "Simulation Error Summary *************")
        
        # GenOutputVariablesAuditReport(state)
        
        # Psychrometrics.ShowPsychrometricSummary(state, state.files.audit)
        
        if hasattr(state, 'dataInputProcessing') and hasattr(state.dataInputProcessing, 'inputProcessor'):
            if state.dataInputProcessing.inputProcessor:
                # state.dataInputProcessing.inputProcessor.reportOrphanRecordObjects(state)
                pass
        
        # Fluid.ReportOrphanFluids(state)
        # Sched.ReportOrphanSchedules(state)
        
        if hasattr(state, 'dataSQLiteProcedures') and hasattr(state.dataSQLiteProcedures, 'sqlite'):
            if state.dataSQLiteProcedures.sqlite:
                state.dataSQLiteProcedures.sqlite = None
        
        if hasattr(state, 'dataInputProcessing') and hasattr(state.dataInputProcessing, 'inputProcessor'):
            if state.dataInputProcessing.inputProcessor:
                state.dataInputProcessing.inputProcessor = None
        
        if state.dataGlobal.get('runReadVars'):
            if hasattr(state, 'files') and hasattr(state.files, 'outputControl'):
                if state.files.outputControl.csv:
                    # ShowWarningMessage(state, "Native CSV output requested in input file, but running ReadVarsESO due to command line argument.")
                    # ShowWarningMessage(state, "This will overwrite the native CSV output.")
                    pass
            # status = CommandLineInterface.runReadVarsESO(state)
            # if status != 0:
            #     return status
    except Exception as e:
        # return AbortEnergyPlus(state)
        return 1
    
    # return EndEnergyPlus(state)
    return 0


def run_energy_plus(state: Any, filepath: str = "") -> int:
    status = initialize_energy_plus(state, filepath)
    if status != 0 or state.dataGlobal.get('outputEpJSONConversionOnly'):
        return status
    
    try:
        # SimulationManager.ManageSimulation(state)
        pass
    except Exception as e:
        # return AbortEnergyPlus(state)
        return 1
    
    return wrap_up_energy_plus(state)


def run_energy_plus_as_library(state: Any, args: List[str]) -> int:
    if not hasattr(state, 'dataGlobal'):
        state.dataGlobal = {}
    
    state.dataGlobal['eplusRunningViaAPI'] = True
    
    if hasattr(sys.stdin, 'isatty'):
        pass
    if hasattr(sys.stderr, 'isatty'):
        pass
    if hasattr(sys.stdout, 'isatty'):
        pass
    
    # return_code = CommandLineInterface.ProcessArgs(state, args)
    return_code = 0
    
    # if return_code == CommandLineInterface.ReturnCodes.FAILURE:
    #     return return_code
    # if return_code == CommandLineInterface.ReturnCodes.SUCCESS_BUT_HELPER:
    #     return CommandLineInterface.ReturnCodes.SUCCESS
    
    status = initialize_as_library(state)
    if status != 0 or state.dataGlobal.get('outputEpJSONConversionOnly'):
        return status
    
    try:
        # SimulationManager.ManageSimulation(state)
        pass
    except Exception as e:
        # return AbortEnergyPlus(state)
        return 1
    
    return wrap_up_energy_plus(state)


def store_progress_callback(state: Any, f: Callable[[int], None]) -> None:
    if not hasattr(state, 'dataGlobal'):
        state.dataGlobal = {}
    state.dataGlobal['fProgressPtr'] = f


def store_message_callback(state: Any, f: Callable[[str], None]) -> None:
    if not hasattr(state, 'dataGlobal'):
        state.dataGlobal = {}
    state.dataGlobal['fMessagePtr'] = f
