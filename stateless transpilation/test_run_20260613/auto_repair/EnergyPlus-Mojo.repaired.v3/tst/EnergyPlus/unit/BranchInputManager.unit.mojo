from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.BranchInputManager import GetSingleBranchInput, FindAirLoopBranchConnection, GetAirBranchIndex, ManageBranchInput, ManageConnectorInput, TestBranchIntegrity
from EnergyPlus.DataSizing import AutoSize
from EnergyPlus.Util import SameString
from EnergyPlus.Errors import FatalError
from EnergyPlus.DataErrorTracking import DataErrorTracking
# Note: state is provided by EnergyPlusFixture

def delimited_string(parts: List[String]) -> String:
    var result = String()
    for part in parts:
        result += part + "\n"
    return result

def expect_no_throw(body: fn()) -> None:
    try:
        body()
    except:
        assert False, "Expected no exception"

def expect_throw(body: fn(), exc_type: type) -> None:
    try:
        body()
        assert False, "Expected exception"
    except exc_type:

# Helper to allocate a list with default values
def allocate_list[T](size: Int, default: T) -> List[T]:
    var lst = List[T]()
    for _ in range(size):
        lst.append(default)
    return lst

# Test functions

@test
def GetBranchInput_One_SingleComponentBranch():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "Branch,",
        "VAV Sys 1 Main Branch,   !- Name",
        ",                        !- Pressure Drop Curve Name",
        "AirLoopHVAC:OutdoorAirSystem,  !- Component 1 Object Type",
        "OA Sys 1,                !- Component 1 Name",
        "VAV Sys 1 Inlet Node,    !- Component 1 Inlet Node Name",
        "Mixed Air Node 1;        !- Component 1 Outlet Node Name",
        "AirLoopHVAC:OutdoorAirSystem,",
        "OA Sys 1,                !- Name",
        "OA Sys 1 Controllers,    !- Controller List Name",
        "OA Sys 1 Equipment;      !- Outdoor Air Equipment List Name",
    ])
    assert fixture.process_idf(idf_objects)
    alias RoutineName = "GetBranchInput: "
    var CurrentModuleObject = "Branch"
    var NumOfBranches = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    var NumParams: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var Alphas: List[String]
    var NodeNums: List[Int]
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    if NumOfBranches > 0:
        state.dataBranchInputManager.Branch.allocate(NumOfBranches)
        for e in state.dataBranchInputManager.Branch:
            e.AssignedLoopName = ""
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNumbers)
        NodeNums = allocate_list(NumParams, 0)
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
        Alphas = allocate_list(NumAlphas, "")
        Numbers = allocate_list(NumNumbers, 0.0)
        cAlphaFields = allocate_list(NumAlphas, "")
        cNumericFields = allocate_list(NumNumbers, "")
        lAlphaBlanks = allocate_list(NumAlphas, True)
        lNumericBlanks = allocate_list(NumNumbers, True)
        var BCount = 0
        for Count in range(1, NumOfBranches + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
            BCount += 1
            GetSingleBranchInput(state, RoutineName, BCount, Alphas, cAlphaFields, NumAlphas, NodeNums, lAlphaBlanks)
        assert NumOfBranches == 1
        assert SameString(Alphas[0], "VAV Sys 1 Main Branch")
        assert SameString(Alphas[2], "AirLoopHVAC:OutdoorAirSystem")
        assert SameString(Alphas[3], "OA Sys 1")
        assert SameString(Alphas[4], "VAV Sys 1 Inlet Node")
        assert SameString(Alphas[5], "Mixed Air Node 1")

@test
def GetBranchInput_One_FourComponentBranch():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "Branch,",
        "VAV Sys 1 Main Branch,   !- Name",
        ",                        !- Pressure Drop Curve Name",
        "AirLoopHVAC:OutdoorAirSystem,  !- Component 1 Object Type",
        "OA Sys 1,                !- Component 1 Name",
        "VAV Sys 1 Inlet Node,    !- Component 1 Inlet Node Name",
        "Mixed Air Node 1,        !- Component 1 Outlet Node Name",
        "Coil:Cooling:Water,      !- Component 2 Object Type",
        "Main Cooling Coil 1,     !- Component 2 Name",
        "Mixed Air Node 1,        !- Component 2 Inlet Node Name",
        "Main Cooling Coil 1 Outlet Node,  !- Component 2 Outlet Node Name",
        "Coil:Heating:Water,      !- Component 3 Object Type",
        "Main Heating Coil 1,     !- Component 3 Name",
        "Main Cooling Coil 1 Outlet Node,  !- Component 3 Inlet Node Name",
        "Main Heating Coil 1 Outlet Node,  !- Component 3 Outlet Node Name",
        "Fan:VariableVolume,      !- Component 4 Object Type",
        "Supply Fan 1,            !- Component 4 Name",
        "Main Heating Coil 1 Outlet Node,  !- Component 4 Inlet Node Name",
        "VAV Sys 1 Outlet Node;   !- Component 4 Outlet Node Name",
        "AirLoopHVAC:OutdoorAirSystem,",
        "OA Sys 1,                !- Name",
        "OA Sys 1 Controllers,    !- Controller List Name",
        "OA Sys 1 Equipment;      !- Outdoor Air Equipment List Name",
        "Coil:Cooling:Water,",
        "Main Cooling Coil 1,     !- Name",
        "CoolingCoilAvailSched,   !- Availability Schedule Name",
        "0.0033,                  !- Design Water Flow Rate {m3/s}",
        "2.284,                   !- Design Air Flow Rate {m3/s}",
        "7.222,                   !- Design Inlet Water Temperature {C}",
        "26.667,                  !- Design Inlet Air Temperature {C}",
        "14.389,                  !- Design Outlet Air Temperature {C}",
        "0.0167,                  !- Design Inlet Air Humidity Ratio {kgWater/kgDryAir}",
        "0.0099,                  !- Design Outlet Air Humidity Ratio {kgWater/kgDryAir}",
        "Main Cooling Coil 1 Water Inlet Node,  !- Water Inlet Node Name",
        "Main Cooling Coil 1 Water Outlet Node,  !- Water Outlet Node Name",
        "Mixed Air Node 1,        !- Air Inlet Node Name",
        "Main Cooling Coil 1 Outlet Node,  !- Air Outlet Node Name",
        "SimpleAnalysis,          !- Type of Analysis",
        "CrossFlow;               !- Heat Exchanger Configuration",
        "Coil:Heating:Water,",
        "Main Heating Coil 1,     !- Name",
        "ReheatCoilAvailSched,    !- Availability Schedule Name",
        "5000.0,                  !- U-Factor Times Area Value {W/K}",
        "0.0043,                  !- Maximum Water Flow Rate {m3/s}",
        "Main Heating Coil 1 Water Inlet Node,  !- Water Inlet Node Name",
        "Main Heating Coil 1 Water Outlet Node,  !- Water Outlet Node Name",
        "Main Cooling Coil 1 Outlet Node,  !- Air Inlet Node Name",
        "Main Heating Coil 1 Outlet Node,  !- Air Outlet Node Name",
        "UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
        "autosize,                !- Rated Capacity {W}",
        "82.2,                    !- Rated Inlet Water Temperature {C}",
        "16.6,                    !- Rated Inlet Air Temperature {C}",
        "71.1,                    !- Rated Outlet Water Temperature {C}",
        "32.2,                    !- Rated Outlet Air Temperature {C}",
        ";                        !- Rated Ratio for Air and Water Convection",
        "Fan:VariableVolume,",
        "Supply Fan 1,            !- Name",
        "FanAvailSched,           !- Availability Schedule Name",
        "0.7,                     !- Fan Total Efficiency",
        "600.0,                   !- Pressure Rise {Pa}",
        "autosize,                !- Maximum Flow Rate {m3/s}",
        "Fraction,                !- Fan Power Minimum Flow Rate Input Method",
        "0.25,                    !- Fan Power Minimum Flow Fraction",
        ",                        !- Fan Power Minimum Air Flow Rate {m3/s}",
        "0.9,                     !- Motor Efficiency",
        "1.0,                     !- Motor In Airstream Fraction",
        "0.35071223,              !- Fan Power Coefficient 1",
        "0.30850535,              !- Fan Power Coefficient 2",
        "-0.54137364,             !- Fan Power Coefficient 3",
        "0.87198823,              !- Fan Power Coefficient 4",
        "0.000,                   !- Fan Power Coefficient 5",
        "Main Heating Coil 1 Outlet Node,  !- Air Inlet Node Name",
        "VAV Sys 1 Outlet Node;   !- Air Outlet Node Name",
    ])
    assert fixture.process_idf(idf_objects)
    alias RoutineName = "GetBranchInput: "
    var CurrentModuleObject = "Branch"
    var NumOfBranches = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, CurrentModuleObject)
    var NumParams: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var Alphas: List[String]
    var NodeNums: List[Int]
    var Numbers: List[Float64]
    var cAlphaFields: List[String]
    var cNumericFields: List[String]
    var lNumericBlanks: List[Bool]
    var lAlphaBlanks: List[Bool]
    var IOStat: Int
    if NumOfBranches > 0:
        state.dataBranchInputManager.Branch.allocate(NumOfBranches)
        for e in state.dataBranchInputManager.Branch:
            e.AssignedLoopName = ""
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, "NodeList", NumParams, NumAlphas, NumNumbers)
        NodeNums = allocate_list(NumParams, 0)
        state.dataInputProcessing.inputProcessor.getObjectDefMaxArgs(state, CurrentModuleObject, NumParams, NumAlphas, NumNumbers)
        Alphas = allocate_list(NumAlphas, "")
        Numbers = allocate_list(NumNumbers, 0.0)
        cAlphaFields = allocate_list(NumAlphas, "")
        cNumericFields = allocate_list(NumNumbers, "")
        lAlphaBlanks = allocate_list(NumAlphas, True)
        lNumericBlanks = allocate_list(NumNumbers, True)
        var BCount = 0
        for Count in range(1, NumOfBranches + 1):
            state.dataInputProcessing.inputProcessor.getObjectItem(state, CurrentModuleObject, Count, Alphas, NumAlphas, Numbers, NumNumbers, IOStat, lNumericBlanks, lAlphaBlanks, cAlphaFields, cNumericFields)
            BCount += 1
            GetSingleBranchInput(state, RoutineName, BCount, Alphas, cAlphaFields, NumAlphas, NodeNums, lAlphaBlanks)
        assert NumOfBranches == 1
        assert SameString(Alphas[0], "VAV Sys 1 Main Branch")
        assert SameString(Alphas[2], "AirLoopHVAC:OutdoorAirSystem")
        assert SameString(Alphas[3], "OA Sys 1")
        assert SameString(Alphas[4], "VAV Sys 1 Inlet Node")
        assert SameString(Alphas[5], "Mixed Air Node 1")
        assert SameString(Alphas[6], "Coil:Cooling:Water")
        assert SameString(Alphas[7], "Main Cooling Coil 1")
        assert SameString(Alphas[8], "Mixed Air Node 1")
        assert SameString(Alphas[9], "Main Cooling Coil 1 Outlet Node")
        assert SameString(Alphas[10], "Coil:Heating:Water")
        assert SameString(Alphas[11], "Main Heating Coil 1")
        assert SameString(Alphas[12], "Main Cooling Coil 1 Outlet Node")
        assert SameString(Alphas[13], "Main Heating Coil 1 Outlet Node")
        assert SameString(Alphas[14], "Fan:VariableVolume")
        assert SameString(Alphas[15], "Supply Fan 1")
        assert SameString(Alphas[16], "Main Heating Coil 1 Outlet Node")
        assert SameString(Alphas[17], "VAV Sys 1 Outlet Node")

@test
def BranchInputManager_FindAirLoopBranchConnection():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "AirLoopHVAC,",
        "  DOAS,                    !- Name",
        "  ,                        !- Controller List Name",
        "  DOAS Availability Managers,  !- Availability Manager List Name",
        "  autosize,                !- Design Supply Air Flow Rate {m3/s}",
        "  DOAS Branches,           !- Branch List Name",
        "  ,                        !- Connector List Name",
        "  DOAS Air Loop Inlet,     !- Supply Side Inlet Node Name",
        "  DOAS Return Air Outlet,  !- Demand Side Outlet Node Name",
        "  DOAS Supply Path Inlet,  !- Demand Side Inlet Node Names",
        "  DOAS Supply Fan Outlet;  !- Supply Side Outlet Node Names",
        "AirLoopHVAC,",
        "  Air Loop 1,                    !- Name",
        "  ,                        !- Controller List Name",
        "  Air Loop 1 Availability Managers,  !- Availability Manager List Name",
        "  50.0,                !- Design Supply Air Flow Rate {m3/s}",
        "  Air Loop 1 Branches,           !- Branch List Name",
        "  ,                        !- Connector List Name",
        "  Air Loop 1 Air Loop Inlet,     !- Supply Side Inlet Node Name",
        "  Air Loop 1 Return Air Outlet,  !- Demand Side Outlet Node Name",
        "  Air Loop 1 Supply Path Inlet,  !- Demand Side Inlet Node Names",
        "  Air Loop 1 Supply Fan Outlet;  !- Supply Side Outlet Node Names",
    ])
    assert fixture.process_idf(idf_objects)
    var BranchListName: String
    var FoundLoopName: String
    var FoundLoopNum: Int
    var LoopType: String
    var FoundLoopVolFlowRate: Float64
    var MatchedLoop: Bool
    BranchListName = "AIR LOOP 1 BRANCHES"
    FoundLoopName = "None"
    FoundLoopNum = 0
    LoopType = "None"
    FoundLoopVolFlowRate = 0.0
    MatchedLoop = False
    FindAirLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopType, FoundLoopVolFlowRate, MatchedLoop)
    assert FoundLoopName == "AIR LOOP 1"
    assert FoundLoopNum == 2
    assert LoopType == "Air"
    assert FoundLoopVolFlowRate == 50.0
    assert MatchedLoop
    BranchListName = "DOAS BRANCHES"
    FoundLoopName = "None"
    FoundLoopNum = 0
    LoopType = "None"
    FoundLoopVolFlowRate = 0.0
    MatchedLoop = False
    FindAirLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopType, FoundLoopVolFlowRate, MatchedLoop)
    assert FoundLoopName == "DOAS"
    assert FoundLoopNum == 1
    assert LoopType == "Air"
    assert FoundLoopVolFlowRate == AutoSize
    assert MatchedLoop
    BranchListName = "Not There"
    FoundLoopName = "None"
    FoundLoopNum = 0
    LoopType = "None"
    FoundLoopVolFlowRate = 0.0
    MatchedLoop = False
    FindAirLoopBranchConnection(state, BranchListName, FoundLoopName, FoundLoopNum, LoopType, FoundLoopVolFlowRate, MatchedLoop)
    assert FoundLoopName == "None"
    assert FoundLoopNum == 0
    assert LoopType == "None"
    assert FoundLoopVolFlowRate == 0.0
    assert not MatchedLoop

@test
def BranchInputManager_GetAirBranchIndex():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    var idf_objects = delimited_string([
        "Branch,",
        "  DOAS Main Branch,        !- Name",
        "  ,                        !- Pressure Drop Curve Name",
        "  AirLoopHVAC:OutdoorAirSystem,  !- Component 1 Object Type",
        "  DOAS OA System,          !- Component 1 Name",
        "  DOAS Air Loop Inlet,     !- Component 1 Inlet Node Name",
        "  DOAS Mixed Air Outlet,   !- Component 1 Outlet Node Name",
        "  CoilSystem:Cooling:DX,   !- Component 2 Object Type",
        "  DOAS Cooling Coil,       !- Component 2 Name",
        "  DOAS Mixed Air Outlet,   !- Component 2 Inlet Node Name",
        "  DOAS Cooling Coil Outlet,!- Component 2 Outlet Node Name",
        "  Coil:Heating:Fuel,        !- Component 2 Object Type",
        "  DOAS Heating Coil,       !- Component 2 Name",
        "  DOAS Cooling Coil Outlet,  !- Component 2 Inlet Node Name",
        "  DOAS Heating Coil Outlet,!- Component 2 Outlet Node Name",
        "  Fan:VariableVolume,      !- Component 3 Object Type",
        "  DOAS Supply Fan,         !- Component 3 Name",
        "  DOAS Heating Coil Outlet,!- Component 3 Inlet Node Name",
        "  DOAS Supply Fan Outlet;  !- Component 3 Outlet Node Name",
        "  Branch,",
        "    TowerWaterSys Demand Bypass Branch,  !- Name",
        "    ,                        !- Pressure Drop Curve Name",
        "    Pipe:Adiabatic,          !- Component 1 Object Type",
        "    TowerWaterSys Demand Bypass Pipe,  !- Component 1 Name",
        "    TowerWaterSys Demand Bypass Pipe Inlet Node,  !- Component 1 Inlet Node Name",
        "    TowerWaterSys Demand Bypass Pipe Outlet Node;  !- Component 1 Outlet Node Name",
    ])
    assert fixture.process_idf(idf_objects)
    var CompType: String
    var CompName: String
    var BranchIndex: Int
    CompType = "AIRLOOPHVAC:OUTDOORAIRSYSTEM"
    CompName = "DOAS OA SYSTEM"
    BranchIndex = GetAirBranchIndex(state, CompType, CompName)
    assert BranchIndex == 1
    CompType = "PIPE:ADIABATIC"
    CompName = "TOWERWATERSYS DEMAND BYPASS PIPE"
    BranchIndex = GetAirBranchIndex(state, CompType, CompName)
    assert BranchIndex == 2
    CompType = "PIPE:ADIABATIC"
    CompName = "TOWERWATERSYS DEMAND BYPASS PIPE NOT THERE"
    BranchIndex = GetAirBranchIndex(state, CompType, CompName)
    assert BranchIndex == 0

@test
def BranchInputManager_OrphanObjects():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    var idf_objects = delimited_string([
        "Branch,",
        "   Heating Supply Main Branch,     !- Name",
        "   ,                               !- Pressure Drop Curve Name",
        "   Coil:Heating:Water,             !- Component 1 Object Type",
        "   Heating Supply Reheat Coil,     !- Component 1 Name",
        "   Heating Supply Inlet Node,      !- Component 1 Inlet Node Name",
        "   Heating Supply Outlet Node;     !- Component 1 Outlet Node Name",
    ])
    assert fixture.process_idf(idf_objects)
    expect_no_throw(fn() => ManageBranchInput(state))
    var expected_error = delimited_string([
        "   ** Severe  ** During Branch Input, Invalid Component Name input=HEATING SUPPLY REHEAT COIL",
        "   **   ~~~   ** Component type=COIL:HEATING:WATER",
        "   **   ~~~   ** Occurs on Branch=HEATING SUPPLY MAIN BRANCH",
        "   ** Severe  ** AuditBranches: There are 1 branch(es) that do not appear on any BranchList.",
        "   **   ~~~   ** Use Output:Diagnostics,DisplayExtraWarnings; for detail of each branch not on a branch list.",
    ])
    fixture.compare_err_stream(expected_error, True)
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    idf_objects = delimited_string([
        "BranchList,",
        "   Heating Supply Branches,        !- Name",
        "   Heating Supply Main Branch;     !- Branch 1 Name",
    ])
    assert fixture.process_idf(idf_objects)
    expect_no_throw(fn() => ManageBranchInput(state))
    expected_error = delimited_string([
        "   ** Severe  ** GetBranchListInput: BranchList=\"HEATING SUPPLY BRANCHES\", invalid data.",
        "   **   ~~~   ** ..invalid Branch Name not found=\"HEATING SUPPLY MAIN BRANCH\".",
        "   ** Severe  ** GetBranchListInput:  Invalid Input -- preceding condition(s) will likely cause termination.",
    ])
    fixture.compare_err_stream(expected_error, True)
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    idf_objects = delimited_string([
        "Connector:Splitter,",
        "   Heating Supply Splitter,        !- Name",
        "   Heating Supply Inlet Branch,    !- Inlet Branch Name",
        "   Central Boiler Branch,          !- Outlet Branch 1 Name",
        "   Heating Supply Bypass Branch;   !- Outlet Branch 2 Name",
    ])
    assert fixture.process_idf(idf_objects)
    expect_throw(fn() => ManageConnectorInput(state), FatalError)
    expected_error = delimited_string([
        "   ** Severe  ** GetSplitterInput: Invalid Branch=HEATING SUPPLY INLET BRANCH, referenced as Inlet Branch to Connector:Splitter=HEATING SUPPLY SPLITTER",
        "   ** Severe  ** GetSplitterInput: Invalid Branch=CENTRAL BOILER BRANCH, referenced as Outlet Branch # 1 to Connector:Splitter=HEATING SUPPLY SPLITTER",
        "   ** Severe  ** GetSplitterInput: Invalid Branch=HEATING SUPPLY BYPASS BRANCH, referenced as Outlet Branch # 2 to Connector:Splitter=HEATING SUPPLY SPLITTER",
        "   **  Fatal  ** GetSplitterInput: Fatal Errors Found in Connector:Splitter, program terminates.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=3",
        "   ..... Last severe error=GetSplitterInput: Invalid Branch=HEATING SUPPLY BYPASS BRANCH, referenced as Outlet Branch # 2 to Connector:Splitter=HEATING SUPPLY SPLITTER",
    ])
    fixture.compare_err_stream(expected_error, True)
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    idf_objects = delimited_string([
        "Connector:Mixer,",
        "   Heating Supply Mixer,           !- Name",
        "   Heating Supply Outlet Branch,   !- Outlet Branch Name",
        "   Central Boiler Branch,          !- Inlet Branch 1 Name",
        "   Heating Supply Bypass Branch;   !- Inlet Branch 2 Name",
    ])
    assert fixture.process_idf(idf_objects)
    expect_throw(fn() => ManageConnectorInput(state), FatalError)
    expected_error = delimited_string([
        "   ** Severe  ** GetMixerInput: Invalid Branch=HEATING SUPPLY OUTLET BRANCH, referenced as Outlet Branch in Connector:Mixer=HEATING SUPPLY MIXER",
        "   ** Severe  ** GetMixerInput: Invalid Branch=CENTRAL BOILER BRANCH, referenced as Inlet Branch # 1 in Connector:Mixer=HEATING SUPPLY MIXER",
        "   ** Severe  ** GetMixerInput: Invalid Branch=HEATING SUPPLY BYPASS BRANCH, referenced as Inlet Branch # 2 in Connector:Mixer=HEATING SUPPLY MIXER",
        "   **  Fatal  ** GetMixerInput: Fatal Errors Found in Connector:Mixer, program terminates.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=3",
        "   ..... Last severe error=GetMixerInput: Invalid Branch=HEATING SUPPLY BYPASS BRANCH, referenced as Inlet Branch # 2 in Connector:Mixer=HEATING SUPPLY MIXER",
    ])
    fixture.compare_err_stream(expected_error, True)
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    idf_objects = delimited_string([
        "ConnectorList,",
        "   Heating Supply Side Connectors, !- Name",
        "   Connector:Splitter,             !- Connector 1 Object Type",
        "   Heating Supply Splitter,        !- Connector 1 Name",
        "   Connector:Mixer,                !- Connector 2 Object Type",
        "   Heating Supply Mixer;           !- Connector 2 Name",
    ])
    assert fixture.process_idf(idf_objects)
    expect_throw(fn() => ManageConnectorInput(state), FatalError)
    expected_error = delimited_string([
        "   ** Severe  ** Invalid Connector:Splitter(none)=HEATING SUPPLY SPLITTER, referenced by ConnectorList=HEATING SUPPLY SIDE CONNECTORS",
        "   ** Severe  ** Invalid Connector:Mixer(none)=HEATING SUPPLY MIXER, referenced by ConnectorList=HEATING SUPPLY SIDE CONNECTORS",
        "   ** Severe  ** For ConnectorList=HEATING SUPPLY SIDE CONNECTORS",
        "   **   ~~~   ** ...Item=HEATING SUPPLY SPLITTER, Type=CONNECTOR:SPLITTER was not matched.",
        "   **   ~~~   ** The BranchList for this Connector:Splitter does not match the BranchList for its corresponding Connector:Mixer.",
        "   ** Severe  ** For ConnectorList=HEATING SUPPLY SIDE CONNECTORS",
        "   **   ~~~   ** ...Item=HEATING SUPPLY MIXER, Type=CONNECTOR:MIXER was not matched.",
        "   **   ~~~   ** The BranchList for this Connector:Mixer does not match the BranchList for its corresponding Connector:Splitter.",
        "   **  Fatal  ** GetConnectorListInput: Program terminates for preceding conditions.",
        "   ...Summary of Errors that led to program termination:",
        "   ..... Reference severe error count=4",
        "   ..... Last severe error=For ConnectorList=HEATING SUPPLY SIDE CONNECTORS",
    ])
    fixture.compare_err_stream(expected_error, True)

@test
def BranchInputManager_OrphanBaseboard():
    var fixture = EnergyPlusFixture()
    var state = fixture.state
    state.dataBranchInputManager.clear_state()
    state.dataErrTracking.TotalSevereErrors = 0
    var idf_objects = delimited_string([
        "BranchList,",
        "   Baseboard Heating Branches,          !- Name",
        "   Baseboard Heating Branch;            !- Branch 1 Name",
        "Branch,",
        "   Baseboard Heating Branch,            !- Name",
        "   ,                                    !- Pressure Drop Curve Name",
        "   ZoneHVAC:Baseboard:Convective:Water, !- Component 1 Object Type",
        "   Baseboard Heater,                    !- Component 1 Name",
        "   Baseboard Water Inlet Node,          !- Component 1 Inlet Node Name",
        "   Baseboard Water Outlet Node;         !- Component 1 Outlet Node Name",
        "ZoneHVAC:Baseboard:Convective:Water,",
        "   Baseboard Heater,                    !-Name",
        "   ,                                    !-Availability Schedule Name",
        "   Baseboard Water Inlet Node,          !-Inlet Node Name",
        "   Baseboard Water Outlet Node,         !-Outlet Node Name",
        "   HeatingDesignCapacity,               !-Heating Design Capacity Method",
        "   Autosize,                            !-Heating Design Capacity{W}",
        "   ,                                    !-Heating Design Capacity Per Floor Area{W/m2}",
        "   ,                                    !-Fraction of Autosized Heating Design Capacity",
        "   Autosize,                            !-U - Factor Times Area Value{W/K}",
        "   Autosize;                            !-Maximum Water Flow Rate {m3/s}",
    ])
    assert fixture.process_idf(idf_objects)
    expect_no_throw(fn() => ManageBranchInput(state))
    var expected_error = ""
    fixture.compare_err_stream(expected_error, True)
    var ErrFound = False
    TestBranchIntegrity(state, ErrFound)
    expected_error = delimited_string([
        "   ************* Testing Individual Branch Integrity",
        "   ** Severe  ** CheckBranchEquipInZoneHVACEquipList: Branch = BASEBOARD HEATING BRANCH, contains a component of type ZONEHVAC:BASEBOARD:CONVECTIVE:WATER with name = BASEBOARD HEATER",
        "   **   ~~~   ** but that component is not listed in any ZoneHVAC:EquipmentList.",
        "   ** Severe  ** Branch(es) did not pass integrity testing",
    ])
    fixture.compare_err_stream(expected_error, True)