from ..api.EnergyPlusAPI import ENERGYPLUSLIB_API
from ..CommandLineInterface import CommandLineInterface
from ..Data.EnergyPlusData import EnergyPlusData
from ..DataGlobals import DataGlobals
from ..DataStringGlobals import DataStringGlobals
from ..DataSystemVariables import DataSystemVariables
from ..DisplayRoutines import DisplayString
from ..FileSystem import FileSystem
from ..FluidProperties import Fluid
from ..IOFiles import IOFiles
from ..InputProcessing.InputProcessor import InputProcessor
from ..OutputProcessor import GenOutputVariablesAuditReport
from ..Psychrometrics import Psychrometrics
from ..ResultsFramework import ResultsFramework
from ..SQLiteProcedures import SQLiteProcedures
from ..ScheduleManager import Sched
from ..SimulationManager import SimulationManager
from ..UtilityRoutines import ShowMessage, ShowSevereError, ShowWarningMessage, AbortEnergyPlus, EndEnergyPlus, initErrorFile, FatalError
from ObjexxFCL.Array1D import Array1D_int
from ObjexxFCL.time import date_and_time
import os
import sys
from time import time

def CreateCurrentDateTimeString() -> String:
    var value = Array1D_int(8)
    var datestring: String  # supposedly returns blank when no date available.
    date_and_time(datestring, _, _, value)
    if not datestring.empty():
        return " YMD={:4}.{:02}.{:02} {:02}:{:02}".format(value[0], value[1], value[2], value[4], value[5])
    return " unknown date/time"

def initializeEnergyPlus(inout state: EnergyPlusData, filepath: String) -> Int:
    commonInitialize(state)
    if not filepath.empty():
        DisplayString(state, "EnergyPlus Library: Changing directory to: " + filepath)
        var status: Int
        status = os.chdir(filepath)
        if status == 0:
            DisplayString(state, "Directory change successful.")
        else:
            DisplayString(state, "Couldn't change directory; aborting EnergyPlus")
            return -1  # EXIT_FAILURE
        state.dataStrGlobals.ProgramPath = filepath + DataStringGlobals.pathChar
        CommandLineInterface.ProcessArgs(state, ["energyplus"])
    return commonRun(state)

def wrapUpEnergyPlus(inout state: EnergyPlusData) -> Int:
    try:
        ShowMessage(state, "Simulation Error Summary *************")
        GenOutputVariablesAuditReport(state)
        Psychrometrics.ShowPsychrometricSummary(state, state.files.audit)
        state.dataInputProcessing.inputProcessor.reportOrphanRecordObjects(state)
        Fluid.ReportOrphanFluids(state)
        Sched.ReportOrphanSchedules(state)
        if state.dataSQLiteProcedures.sqlite:
            state.dataSQLiteProcedures.sqlite.reset()
        if state.dataInputProcessing.inputProcessor:
            state.dataInputProcessing.inputProcessor.reset()
        if state.dataGlobal.runReadVars:
            if state.files.outputControl.csv:
                ShowWarningMessage(state, "Native CSV output requested in input file, but running ReadVarsESO due to command line argument.")
                ShowWarningMessage(state, "This will overwrite the native CSV output.")
            var status = CommandLineInterface.runReadVarsESO(state)
            if status != 0:
                return status
    except FatalError as e:
        return AbortEnergyPlus(state)
    except Exception as e:
        ShowSevereError(state, str(e))
        return AbortEnergyPlus(state)
    return EndEnergyPlus(state)

def ENERGYPLUSLIB_API EnergyPlusPgm(args: List[String], filepath: String = String()) -> Int:
    var state = EnergyPlusData()
    var value = Array1D_int(8)
    var datestring: String  # supposedly returns blank when no date available.
    date_and_time(datestring, _, _, value)
    if not datestring.empty():
        state.dataStrGlobals.CurrentDateTime = " YMD={:4}.{:02}.{:02} {:02}:{:02}".format(value[0], value[1], value[2], value[4], value[5])
    else:
        state.dataStrGlobals.CurrentDateTime = " unknown date/time"
    state.dataStrGlobals.VerStringVar = DataStringGlobals.VerString + "," + state.dataStrGlobals.CurrentDateTime
    CommandLineInterface.ProcessArgs(state, args)
    return RunEnergyPlus(state, filepath)

def commonInitialize(inout state: EnergyPlusData):
    state.dataSysVars.runtimeTimer.tick()
    state.dataStrGlobals.CurrentDateTime = CreateCurrentDateTimeString()
    state.dataResultsFramework.resultsFramework.SimulationInformation.setProgramVersion(state.dataStrGlobals.VerStringVar)
    state.dataResultsFramework.resultsFramework.SimulationInformation.setStartDateTimeStamp(state.dataStrGlobals.CurrentDateTime.substr(5))
    state.dataStrGlobals.VerStringVar = DataStringGlobals.VerString + "," + state.dataStrGlobals.CurrentDateTime
    DataSystemVariables.processEnvironmentVariables(state)

def commonRun(inout state: EnergyPlusData) -> Int:
    var errStatus = initErrorFile(state)
    if errStatus != 0:
        return errStatus
    state.dataSysVars.TestAllPaths = True
    DisplayString(state, "EnergyPlus Starting")
    DisplayString(state, state.dataStrGlobals.VerStringVar)
    try:
        if not state.dataInputProcessing.inputProcessor:
            state.dataInputProcessing.inputProcessor = InputProcessor.factory()
        state.dataInputProcessing.inputProcessor.processInput(state)
        if state.dataGlobal.outputEpJSONConversionOnly:
            DisplayString(state, "Converted input file format. Exiting.")
            return EndEnergyPlus(state)
    except FatalError as e:
        return AbortEnergyPlus(state)
    except Exception as e:
        ShowSevereError(state, str(e))
        return AbortEnergyPlus(state)
    return 0

def initializeAsLibrary(inout state: EnergyPlusData) -> Int:
    commonInitialize(state)
    return commonRun(state)

def RunEnergyPlus(inout state: EnergyPlusData, filepath: String = String()) -> Int:
    var status = initializeEnergyPlus(state, filepath)
    if (status != 0) or state.dataGlobal.outputEpJSONConversionOnly:
        return status
    try:
        SimulationManager.ManageSimulation(state)
    except FatalError as e:
        return AbortEnergyPlus(state)
    except Exception as e:
        ShowSevereError(state, str(e))
        return AbortEnergyPlus(state)
    return wrapUpEnergyPlus(state)

def runEnergyPlusAsLibrary(inout state: EnergyPlusData, args: List[String]) -> Int:
    state.dataGlobal.eplusRunningViaAPI = True
    if not sys.stdin.good():
        sys.stdin.clear()
    if not sys.stderr.good():
        sys.stderr.clear()
    if not sys.stdout.good():
        sys.stdout.clear()
    var return_code = CommandLineInterface.ProcessArgs(state, args)
    if return_code == Int(CommandLineInterface.ReturnCodes.Failure):
        return return_code
    if return_code == Int(CommandLineInterface.ReturnCodes.SuccessButHelper):
        return Int(CommandLineInterface.ReturnCodes.Success)
    var status = initializeAsLibrary(state)
    if (status != 0) or state.dataGlobal.outputEpJSONConversionOnly:
        return status
    try:
        SimulationManager.ManageSimulation(state)
    except FatalError as e:
        return AbortEnergyPlus(state)
    except Exception as e:
        ShowSevereError(state, str(e))
        return AbortEnergyPlus(state)
    return wrapUpEnergyPlus(state)

def StoreProgressCallback(inout state: EnergyPlusData, f: fn(Int) raises -> None):
    state.dataGlobal.fProgressPtr = f

def StoreMessageCallback(inout state: EnergyPlusData, f: fn(String) raises -> None):
    state.dataGlobal.fMessagePtr = f