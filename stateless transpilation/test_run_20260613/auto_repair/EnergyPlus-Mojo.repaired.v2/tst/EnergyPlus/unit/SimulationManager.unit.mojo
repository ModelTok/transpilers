# Mojo translation of SimulationManager.unit.cc
# This file is a 1:1 mapping; test macros are emulated with functions.
# Required stubs for gtest and EnergyPlus internals are defined locally.

from testing import Test, Assert, AssertEqual, AssertRaises, AssertNoRaises
from IOFiles import IOFiles
from DataGlobals import DataGlobals
from DataEnvironment import DataEnvironment
from DataBranchNodeConnections import DataBranchNodeConnections
from DataReportingFlags import DataReportingFlags
from DataSystemVariables import DataSystemVariables
from FileSystem import FileSystem
from SimulationManager import SimulationManager
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, compare_err_stream, compare_err_stream_substring, state, delimited_string
from stdlib import fs, string, stringstream, ifstream
from runtime_error import runtime_error

# Helper to emulate TEST_F macro: define a function with the test name.
# In a real test runner, these functions would be discovered.
def CheckThreading() raises:
    var idf_objects: string = delimited_string([
        "ProgramControl,",
        "	1;",
    ])
    Assert.assert_false(process_idf(idf_objects, false))
    state.init_state(state)
    var error_string: string = delimited_string([
        "   ** Severe  ** Line: 1 Index: 14 - \"ProgramControl\" is not a valid Object Type.",
    ])
    Assert.true(compare_err_stream(error_string, true))

def Test_PerformancePrecisionTradeoffs() raises:
    var idf_objects: string = delimited_string([
        "  SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    No,                      !- Do Plant Sizing Calculation",
        "    No,                      !- Run Simulation for Sizing Periods",
        "    Yes;                     !- Run Simulation for Weather File Run Periods",
        "  PerformancePrecisionTradeoffs,",
        "    No;       ! - Use Coil Direct Solutions",
    ])
    Assert.true(process_idf(idf_objects))
    SimulationManager.GetProjectData(state)
    Assert.true(compare_err_stream("", true))

def Test_PerformancePrecisionTradeoffs_DirectSolution_Message() raises:
    var idf_objects: string = delimited_string([
        "  PerformancePrecisionTradeoffs,",
        "     Yes; ! - Use Coil Direct Solutions",
    ])
    Assert.true(process_idf(idf_objects, false))
    state.init_state(state)
    var error_string: string = delimited_string([
        "   ** Warning ** PerformancePrecisionTradeoffs: Coil Direct Solution simulation is selected.",
    ])
    Assert.true(compare_err_stream(error_string, true))

def SimulationManager_bool_to_string() raises:
    Assert.equal(SimulationManager.bool_to_string(true), "True")
    Assert.equal(SimulationManager.bool_to_string(false), "False")

def SimulationManager_writeInitialPerfLogValues() raises:
    state.dataStrGlobals.outputPerfLogFilePath = "eplusout_perflog.csv"
    fs.remove(state.dataStrGlobals.outputPerfLogFilePath)
    Util.appendPerfLog(state, "RESET", "RESET")
    SimulationManager.writeInitialPerfLogValues(state, "MODE193")
    Util.appendPerfLog(state, "lastHeader", "lastValue", true)
    var perfLogFile: ifstream
    var perfLogStrSteam: stringstream
    perfLogFile.open(state.dataStrGlobals.outputPerfLogFilePath)
    perfLogStrSteam << perfLogFile.rdbuf()
    perfLogFile.close()
    var perfLogContents: string = perfLogStrSteam.str()
    var expectedContents: string = "Program, Version, TimeStamp,Use Coil Direct Solution,Zone Radiant Exchange Algorithm," \
                                   "Override Mode,Number of Timesteps per Hour,Minimum Number of Warmup " \
                                   "Days,SuppressAllBeginEnvironmentResets,Minimum System Timestep,MaxZoneTempDiff,MaxAllowedDelTemp,lastHeader,\n" + \
                                   state.dataStrGlobals.VerStringVar + ",False,ScriptF,MODE193,0,1,False,1.0,0.30,2.0000E-003,lastValue,\n"
    Assert.equal(perfLogContents, expectedContents)
    fs.remove(state.dataStrGlobals.outputPerfLogFilePath)

def SimulationManager_OutputDebuggingData() raises:
    # First block
    do:
        var idf_objects: string = delimited_string([
            "  Output:DebuggingData,",
            "    No;                      !- Report Debugging Data",
        ])
        Assert.true(process_idf(idf_objects))
        Assert.false(state.dataReportFlag.DebugOutput)
        Assert.false(state.dataReportFlag.EvenDuringWarmup)
        Assert.true(compare_err_stream("", true))
    # Second block
    do:
        var idf_objects: string = delimited_string([
            "  Output:DebuggingData,",
            "    Yes,                     !- Report Debugging Data",
            "    ;                        !- Report During Warmup",
        ])
        state.init_state_called = false
        Assert.true(process_idf(idf_objects))
        state.init_state(state)
        Assert.true(state.dataReportFlag.DebugOutput)
        Assert.false(state.dataReportFlag.EvenDuringWarmup)
        Assert.true(compare_err_stream("", true))
    # Third block
    do:
        var idf_objects: string = delimited_string([
            "  Output:DebuggingData,",
            "    No,                      !- Report Debugging Data",
            "    Yes;                     !- Report During Warmup",
        ])
        state.init_state_called = false
        Assert.true(process_idf(idf_objects))
        state.init_state(state)
        Assert.false(state.dataReportFlag.DebugOutput)
        Assert.true(state.dataReportFlag.EvenDuringWarmup)
        Assert.true(compare_err_stream("", true))
    # Fourth block
    do:
        var idf_objects: string = delimited_string([
            "  Output:DebuggingData,",
            "    No,                      !- Report Debugging Data",
            "    Yes;                     !- Report During Warmup",
            "  Output:DebuggingData,",
            "    Yes,                     !- Report Debugging Data",
            "    No;                      !- Report During Warmup",
        ])
        state.init_state_called = false
        compare_err_stream_substring("", true)
        Assert.false(process_idf(idf_objects, false))
        state.init_state(state)
        do:
            var expectedError: string = delimited_string([
                "   ** Severe  ** <root>[Output:DebuggingData] - Object should have no more than 1 properties.",
                "   ** Warning ** Output:DebuggingData: More than 1 occurrence of this object found, only first will be used.",
            ])
            Assert.true(compare_err_stream(expectedError, true))
        Assert.false(state.dataReportFlag.DebugOutput)
        Assert.true(state.dataReportFlag.EvenDuringWarmup)

def SimulationManager_OutputDiagnostics_DefaultState() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics;",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    Assert.false(state.dataGlobal.DisplayAllWarnings)
    Assert.false(state.dataGlobal.DisplayExtraWarnings)
    Assert.false(state.dataGlobal.DisplayUnusedObjects)
    Assert.false(state.dataGlobal.DisplayUnusedSchedules)
    Assert.false(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.false(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.true(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.true(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.false(state.dataSysVars.ReportDuringWarmup)
    Assert.false(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.false(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.false(state.dataSysVars.ReportDuringHVACSizingSimulation)
    Assert.false(state.dataEnvrn.IgnoreSolarRadiation)
    Assert.false(state.dataEnvrn.IgnoreBeamRadiation)
    Assert.false(state.dataEnvrn.IgnoreDiffuseRadiation)
    Assert.false(state.dataSysVars.DeveloperFlag)
    Assert.false(state.dataSysVars.TimingFlag)
    Assert.true(compare_err_stream("", true))

def SimulationManager_OutputDiagnostics_SimpleCase() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics,",
        "    DisplayAllWarnings,      !- Key 1",
        "    DisplayAdvancedReportVariables;    !- Key 2",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    Assert.true(state.dataGlobal.DisplayAllWarnings)
    Assert.true(state.dataGlobal.DisplayExtraWarnings)
    Assert.true(state.dataGlobal.DisplayUnusedObjects)
    Assert.true(state.dataGlobal.DisplayUnusedSchedules)
    Assert.true(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.false(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.true(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.true(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.false(state.dataSysVars.ReportDuringWarmup)
    Assert.false(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.false(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.false(state.dataSysVars.ReportDuringHVACSizingSimulation)
    Assert.true(compare_err_stream("", true))

def SimulationManager_OutputDiagnostics_AllKeys() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics,",
        "    DisplayAllWarnings,",
        "    DisplayExtraWarnings,",
        "    DisplayUnusedSchedules,",
        "    DisplayUnusedObjects,",
        "    DisplayAdvancedReportVariables,",
        "    DisplayZoneAirHeatBalanceOffBalance,",
        "    DoNotMirrorDetachedShading,",
        "    DoNotMirrorAttachedShading,",
        "    DisplayWeatherMissingDataWarnings,",
        "    ReportDuringWarmup,",
        "    ReportDetailedWarmupConvergence,",
        "    ReportDuringHVACSizingSimulation;",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    Assert.true(state.dataGlobal.DisplayAllWarnings)
    Assert.true(state.dataGlobal.DisplayExtraWarnings)
    Assert.true(state.dataGlobal.DisplayUnusedObjects)
    Assert.true(state.dataGlobal.DisplayUnusedSchedules)
    Assert.true(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.true(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.false(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.false(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.true(state.dataSysVars.ReportDuringWarmup)
    Assert.true(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.true(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.true(state.dataSysVars.ReportDuringHVACSizingSimulation)
    Assert.true(compare_err_stream("", true))

def SimulationManager_OutputDiagnostics_Unicity() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics,",
        "    DisplayAdvancedReportVariables;    !- Key 1",
        "  Output:Diagnostics,",
        "    DisplayAllWarnings;      !- Key 1",
    ])
    compare_err_stream_substring("", true)
    Assert.false(process_idf(idf_objects, false))
    state.init_state(state)
    do:
        var expectedError: string = delimited_string([
            "   ** Severe  ** <root>[Output:Diagnostics] - Object should have no more than 1 properties.",
            "   ** Warning ** Output:Diagnostics: More than 1 occurrence of this object found, only first will be used.",
        ])
        Assert.true(compare_err_stream(expectedError, true))
    Assert.false(state.dataGlobal.DisplayAllWarnings)
    Assert.false(state.dataGlobal.DisplayExtraWarnings)
    Assert.false(state.dataGlobal.DisplayUnusedObjects)
    Assert.false(state.dataGlobal.DisplayUnusedSchedules)
    Assert.true(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.false(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.true(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.true(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.false(state.dataSysVars.ReportDuringWarmup)
    Assert.false(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.false(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.false(state.dataSysVars.ReportDuringHVACSizingSimulation)

def SimulationManager_OutputDiagnostics_UndocumentedFlags() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics,",
        "    IgnoreSolarRadiation,",
        "    IgnoreBeamRadiation,",
        "    IgnoreDiffuseRadiation,",
        "    DeveloperFlag,",
        "    TimingFlag;",
    ])
    Assert.false(process_idf(idf_objects, false))
    state.init_state(state)
    const expected_warning: string = delimited_string([
        "   ** Severe  ** <root>[Output:Diagnostics][Output:Diagnostics 1][diagnostics][0][key] - \"IgnoreSolarRadiation\" - Failed to match against "
        "any enum values.",
        "   ** Severe  ** <root>[Output:Diagnostics][Output:Diagnostics 1][diagnostics][1][key] - \"IgnoreBeamRadiation\" - Failed to match against "
        "any enum values.",
        "   ** Severe  ** <root>[Output:Diagnostics][Output:Diagnostics 1][diagnostics][2][key] - \"IgnoreDiffuseRadiation\" - Failed to match "
        "against any enum values.",
        "   ** Severe  ** <root>[Output:Diagnostics][Output:Diagnostics 1][diagnostics][3][key] - \"DeveloperFlag\" - Failed to match against any "
        "enum values.",
        "   ** Severe  ** <root>[Output:Diagnostics][Output:Diagnostics 1][diagnostics][4][key] - \"TimingFlag\" - Failed to match against any enum "
        "values.",
    ])
    Assert.true(compare_err_stream(expected_warning, true))
    Assert.false(state.dataGlobal.DisplayAllWarnings)
    Assert.false(state.dataGlobal.DisplayExtraWarnings)
    Assert.false(state.dataGlobal.DisplayUnusedObjects)
    Assert.false(state.dataGlobal.DisplayUnusedSchedules)
    Assert.false(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.false(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.true(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.true(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.false(state.dataSysVars.ReportDuringWarmup)
    Assert.false(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.false(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.false(state.dataSysVars.ReportDuringHVACSizingSimulation)
    Assert.true(state.dataEnvrn.IgnoreSolarRadiation)
    Assert.true(state.dataEnvrn.IgnoreBeamRadiation)
    Assert.true(state.dataEnvrn.IgnoreDiffuseRadiation)
    Assert.true(state.dataSysVars.DeveloperFlag)
    Assert.true(state.dataSysVars.TimingFlag)
    Assert.true(compare_err_stream("", true))

def SimulationManager_OutputDiagnostics_HasEmpty() raises:
    var idf_objects: string = delimited_string([
        "  Output:Diagnostics,",
        "    ,                                  !- Key 1",
        "    DisplayAdvancedReportVariables;    !- Key 2",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    Assert.false(state.dataGlobal.DisplayAllWarnings)
    Assert.false(state.dataGlobal.DisplayExtraWarnings)
    Assert.false(state.dataGlobal.DisplayUnusedObjects)
    Assert.false(state.dataGlobal.DisplayUnusedSchedules)
    Assert.true(state.dataGlobal.DisplayAdvancedReportVariables)
    Assert.false(state.dataGlobal.DisplayZoneAirHeatBalanceOffBalance)
    Assert.true(state.dataReportFlag.MakeMirroredDetachedShading)
    Assert.true(state.dataReportFlag.MakeMirroredAttachedShading)
    Assert.false(state.dataSysVars.ReportDuringWarmup)
    Assert.false(state.dataEnvrn.DisplayWeatherMissingDataWarnings)
    Assert.false(state.dataSysVars.ReportDetailedWarmupConvergence)
    Assert.false(state.dataSysVars.ReportDuringHVACSizingSimulation)
    var expectedError: string = delimited_string([
        "   ** Warning ** Output:Diagnostics: empty key found, consider removing it to avoid this warning.",
    ])
    Assert.true(compare_err_stream(expectedError, true))

def SimulationManager_HVACSizingSimulationChoiceTest() raises:
    var idf_objects: string = delimited_string([
        "  SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    No,                      !- Do Plant Sizing Calculation",
        "    No,                      !- Run Simulation for Sizing Periods",
        "    Yes,                     !- Run Simulation for Weather File Run Periods",
        "    Yes;                     !- Do HVAC Sizing Simulation for Sizing Periods",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    Assert.false(state.dataGlobal.DoHVACSizingSimulation)
    Assert.equal(state.dataGlobal.HVACSizingSimMaxIterations, 0)

def Test_SimulationControl_ZeroSimulation() raises:
    var idf_objects: string = delimited_string([
        "SimulationControl,",
        "  No,                       !- Do Zone Sizing Calculation",
        "  No,                       !- Do System Sizing Calculation",
        "  Yes,                      !- Do Plant Sizing Calculation",
        "  No,                       !- Run Simulation for Sizing Periods",
        "  No,                       !- Run Simulation for Weather File Run Periods",
        "  No,                       !- Do HVAC Sizing Simulation for Sizing Periods",
        "  1;                        !- Maximum Number of HVAC Sizing Simulation Passes",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    AssertRaises(runtime_error, lambda: SimulationManager.CheckForMisMatchedEnvironmentSpecifications(state))
    var error_string: string = delimited_string([
        "   ** Severe  ** All elements of SimulationControl are set to \"No\". No simulations can be done. Program terminates.",
        "   **  Fatal  ** Program terminates due to preceding conditions.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=All elements of SimulationControl are set to \"No\". No simulations can be done. Program terminates.",
    ])
    Assert.true(compare_err_stream(error_string, true))

def Test_SimulationControl_PureLoadCalc() raises:
    var idf_objects: string = delimited_string([
        "SimulationControl,",
        "  Yes,                      !- Do Zone Sizing Calculation",
        "  Yes,                      !- Do System Sizing Calculation",
        "  No,                       !- Do Plant Sizing Calculation",
        "  No,                       !- Run Simulation for Sizing Periods",
        "  No,                       !- Run Simulation for Weather File Run Periods",
        "  No,                       !- Do HVAC Sizing Simulation for Sizing Periods",
        "  1;                        !- Maximum Number of HVAC Sizing Simulation Passes",
    ])
    Assert.true(process_idf(idf_objects))
    state.init_state(state)
    AssertNoRaises(lambda: SimulationManager.CheckForMisMatchedEnvironmentSpecifications(state))
    var error_string: string = delimited_string([
        "   ** Warning ** \"Run Simulation for Sizing Periods\" and \"Run Simulation for Weather File Run Periods\" are both set to \"No\". "
        "No simulations will be performed, and most input will not be read.",
    ])
    Assert.true(compare_err_stream(error_string, true))

def SimulationManager_ReportLoopConnectionsTest() raises:
    state.dataBranchNodeConnections.NumCompSets = 1
    state.dataBranchNodeConnections.CompSets.allocate(1)
    state.dataBranchNodeConnections.CompSets[0].ParentObjectType = Node.ConnectionObjectType.WaterHeaterMixed
    state.dataBranchNodeConnections.CompSets[0].ComponentObjectType = Node.ConnectionObjectType.WaterHeaterMixed
    state.dataBranchNodeConnections.CompSets[0].CName = "WaterHeaterMixed1"
    state.dataBranchNodeConnections.CompSets[0].InletNodeName = "MixedWaterHeater1Inlet"
    state.dataBranchNodeConnections.CompSets[0].OutletNodeName = "MixedWaterHeater1Outlet"
    state.dataSimulationManager.WarningOut = false
    state.dataBranchNodeConnections.CompSets[0].Description = "UNDEFINED"
    AssertRaises(runtime_error, lambda: EnergyPlus.SimulationManager.ReportLoopConnections(state))
    var error_string: string = delimited_string([
        "   ** Severe  ** Potential Node Connection Error for object WATERHEATER:MIXED, name=WaterHeaterMixed1",
        "   **   ~~~   **   Node Types are still UNDEFINED -- See Branch/Node Details file for further information",
        "   **   ~~~   **   Inlet Node : MixedWaterHeater1Inlet",
        "   **   ~~~   **   Outlet Node: MixedWaterHeater1Outlet",
        "   ************* There was 1 node connection error noted.",
        "   **  Fatal  ** Please see severe error(s) and correct either the branch nodes or the component nodes so that they match.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=1",
        "   ..... Last severe error=Potential Node Connection Error for object WATERHEATER:MIXED, name=WaterHeaterMixed1",
    ])
    Assert.true(compare_err_stream(error_string, true))

def SimulationManager_PlantSizingInputTest() raises:
    var idf_objects: string = delimited_string([
        "SimulationControl,",
        "  No,                       !- Do Zone Sizing Calculation",
        "  No,                       !- Do System Sizing Calculation",
        "  Yes,                      !- Do Plant Sizing Calculation",
        "  No,                       !- Run Simulation for Sizing Periods",
        "  No,                       !- Run Simulation for Weather File Run Periods",
        "  Yes,                      !- Do HVAC Sizing Simulation for Sizing Periods",
        "  2;                        !- Maximum Number of HVAC Sizing Simulation Passes",
    ])
    Assert.true(process_idf(idf_objects))
    AssertRaises(runtime_error, lambda: SimulationManager.GetProjectData(state))
    Assert.true(compare_err_stream_substring(
        "GetProjectData: No Sizing:Plant object entered when the Do HVAC Sizing Simulation and Do Plant Sizing are both YES", true))