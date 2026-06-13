from testing import TestFixture
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataOutputs import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportData import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.Constant import Constant
from ObjexxFCL.Array1D import Array1D

using EnergyPlus
using OutputProcessor
using DataOutputs

@fixture
class TestOutputReportData(EnergyPlusFixture):

def test_OutputReportData_AnnualFieldSetConstructor():
    var varNameTest: String = "TestReport"
    var kindOfAggregationTest: AnnualFieldSet.AggregationKind = AnnualFieldSet.AggregationKind.sumOrAvg
    var numDigitsShownTest: Int = 3
    var fldStTest: AnnualFieldSet = AnnualFieldSet(varNameTest, kindOfAggregationTest, numDigitsShownTest)
    assert_equal(fldStTest.m_variMeter, varNameTest)
    assert_equal(fldStTest.m_aggregate, kindOfAggregationTest)
    assert_equal(fldStTest.m_showDigits, numDigitsShownTest)

def test_OutputReportData_getVariableKeys():
    var varNameTest: String = "TestReport"
    var kindOfAggregationTest: AnnualFieldSet.AggregationKind = AnnualFieldSet.AggregationKind.sumOrAvg
    var numDigitsShownTest: Int = 3
    var fldStTest: AnnualFieldSet = AnnualFieldSet(varNameTest, kindOfAggregationTest, numDigitsShownTest)
    var extLitPow: Float64
    var extLitUse: Float64
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Sum,
                        "Lite1",
                        Constant.eResource.Electricity,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Sum,
                        "Lite2",
                        Constant.eResource.Electricity,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Sum,
                        "Lite3",
                        Constant.eResource.Electricity,
                        OutputProcessor.Group.Invalid,
                        OutputProcessor.EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        "Lite1")
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        "Lite2")
    SetupOutputVariable(state[],
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        OutputProcessor.TimeStepType.Zone,
                        OutputProcessor.StoreType.Average,
                        "Lite3")
    var keyCount: Int = 0
    var typeVar: OutputProcessor.VariableType = OutputProcessor.VariableType.Invalid
    var avgSumVar: OutputProcessor.StoreType
    var stepTypeVar: OutputProcessor.TimeStepType
    var unitsVar: Constant.Units = Constant.Units.None
    fldStTest.m_variMeter = "EXTERIOR LIGHTS ELECTRIC ENERGY"
    keyCount = fldStTest.getVariableKeyCountandTypeFromFldSt(state[], typeVar, avgSumVar, stepTypeVar, unitsVar)
    assert_equal(keyCount, 3)
    fldStTest.getVariableKeysFromFldSt(state[], typeVar, keyCount, fldStTest.m_namesOfKeys, fldStTest.m_indexesForKeyVar)
    assert_equal(fldStTest.m_namesOfKeys[0], "LITE1")
    assert_equal(fldStTest.m_namesOfKeys[1], "LITE2")
    assert_equal(fldStTest.m_namesOfKeys[2], "LITE3")

def test_OutputReportData_Regex():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "Outside Air Inlet Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "Relief Air Outlet Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "(Relief|Outside) Air (Outlet|Inlet) Node,",
        "System Node Temperature,",
        "timestep;",
        " Output:Variable,",
        "Mixed Air Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "(Mixed|Single) Air Node,",
        "System Node Temperature,",
        "timestep;",
        " Output:Variable,",
        "*,",
        "Unitary System Compressor Part Load Ratio,",
        "timestep;",
        " Output:Variable,",
        ".*,",
        "Zone Air System Sensible Heating Rate,",
        "timestep;",
        " Output:Variable,",
        "SALESFLOOR OUTLET NODE,",
        "System Node Temperature,",
        "timestep;",
        " Output:Variable,",
        "BackRoom(.*),",
        "System Node Temperature,",
        "timestep;",
        " Output:Variable,",
        "(.*)N(ode|ODE),",
        "System Node Humidity Ratio,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 10)
    assert_true(FindItemInVariableList(state[], "Outside Air Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "OUTSIDE AIR INLET NODE", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "OutsIDE AiR InLEt NoDE", "System NoDE MaSS FLOw Rate"))
    assert_true(FindItemInVariableList(state[], "OUTSIDE AIR INLET NODE", "System NODE Mass Flow RATE"))
    assert_true(FindItemInVariableList(state[], "Mixed Air Node", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "Outside Air Inlet Node", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "Outside Air Inlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Any Node Here", "Zone Air System Sensible Heating Rate"))
    assert_true(FindItemInVariableList(state[], "Salesfloor Outlet Node", "System Node Temperature"))
    assert_false(FindItemInVariableList(state[], "AnySalesfloor Outlet Node", "System Node Temperature"))
    assert_false(FindItemInVariableList(state[], "AnyOutside Air Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "BackRoom OUTLET NODE", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "BackRoom Inlet NODE", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "BackRoom Node", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "BackRoom OUTLET NODE", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom Inlet NODE", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom Any Node", "System Node Humidity Ratio"))

def test_OutputReportData_Regex_Plus():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "(.+)Inlet(.+),",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "(.+)Inlet,",
        "System Node Humidity Ratio,",
        "timestep;",
        " Output:Variable,",
        "(.+)Node,",
        "Zone Air System Sensible Heating Rate,",
        "timestep;",
        " Output:Variable,",
        "Outside Air (.+) Node,",
        "Unitary System Compressor Part Load Ratio,",
        "timestep;",
        " Output:Variable,",
        "Outside Air .+ Node,",
        "Unitary System Load Ratio,",
        "timestep;",
        " Output:Variable,",
        ".+,",
        "System Node Temperature,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 6)
    assert_true(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "SalesFloor INLET Node", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "Inlet", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "BackRoom Inlet Node", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom Any Node", "Zone Air System Sensible Heating Rate"))
    assert_true(FindItemInVariableList(state[], "Outside Air Inlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Outside Air Outlet Node", "Unitary System Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Any Node", "System Node Temperature"))
    assert_false(FindItemInVariableList(state[], "", "System Node Temperature"))

def test_OutputReportData_Regex_Star():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "(.*)Inlet(.*),",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "(.*)Inlet,",
        "System Node Humidity Ratio,",
        "timestep;",
        " Output:Variable,",
        "(.*)Node,",
        "Zone Air System Sensible Heating Rate,",
        "timestep;",
        " Output:Variable,",
        "Outside Air(.*) Node,",
        "Unitary System Compressor Part Load Ratio,",
        "timestep;",
        " Output:Variable,",
        "Outside Air.* Node,",
        "Unitary System Load Ratio,",
        "timestep;",
        " Output:Variable,",
        ".*,",
        "System Node Temperature,",
        "timestep;",
        " Output:Variable,",
        "*,",
        "Refrigeration Compressor Rack Electric Power,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 7)
    assert_true(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "SalesFloor INLET Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Inlet", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Inlet Node", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "BackRoom Inlet Node", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "Inlet", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "Any Inlet", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom Any Node", "Zone Air System Sensible Heating Rate"))
    assert_true(FindItemInVariableList(state[], "Node", "Zone Air System Sensible Heating Rate"))
    assert_true(FindItemInVariableList(state[], "NODE", "Zone Air System Sensible Heating Rate"))
    assert_true(FindItemInVariableList(state[], "Outside Air Inlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Outside Air Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Outside Air Outlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Outside Air Outlet Node", "Unitary System Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Outside Air Node", "Unitary System Load Ratio"))
    assert_false(FindItemInVariableList(state[], "Outside AirNode", "Unitary System Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Any Node", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "", "System Node Temperature"))
    assert_true(FindItemInVariableList(state[], "Any Node", "Refrigeration Compressor Rack Electric Power"))
    assert_true(FindItemInVariableList(state[], "", "Refrigeration Compressor Rack Electric Power"))

def test_OutputReportData_Regex_Pipe():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "SalesFloor I(nlet|NLET) Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "SalesFloor O(utlet|UTLET) Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "System (Inlet|Outlet) Node,",
        "Unitary System Compressor Part Load Ratio,",
        "timestep;",
        " Output:Variable,",
        "(BackRoom|BACKROOM|SALESFLOOR|SalesFloor) (Outlet|OUTLET) (NODE|Node),",
        "System Node Humidity Ratio,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 4)
    assert_true(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "SalesFloor INLET Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "SalesFloor Outlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "SalesFloor OUTLET Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "System Inlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "System Outlet Node", "Unitary System Compressor Part Load Ratio"))
    assert_false(FindItemInVariableList(state[], "System Another Node", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom OUTLET NODE", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "SALESFLOOR OUTLET NODE", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "SalesFloor Outlet Node", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BACKROOM Outlet Node", "System Node Humidity Ratio"))

def test_OutputReportData_Regex_Brackets():
    var idf_objects: String = delimited_string([
        "Output:Variable,",
        "([A-Za-z] ?)+,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "[A-Za-z0-9_]+,",
        "System Node Humidity Ratio,",
        "timestep;",
        " Output:Variable,",
        "[A-Z]{4},",
        "Unitary System Compressor Part Load Ratio,",
        "timestep;",
        " Output:Variable,",
        "[A-Za-z]{5,6},",
        "Zone Air System Sensible Heating Rate,",
        "timestep;",
        " Output:Variable,",
        "[A-Za-z ]{5,},",
        "Refrigeration Compressor Rack Electric Power,",
        "timestep;",
        " Output:Variable,",
        "([A-Za-z] ?)+,",
        "System Node Mass Flow Rate,",
        "timestep;",
    ])
    assert_false(process_idf(idf_objects, false))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 6)
    assert_true(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Node", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "BackRoom OUTLET NODE", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "BackRoom_NODE1", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "NODE", "Unitary System Compressor Part Load Ratio"))
    assert_true(FindItemInVariableList(state[], "Node", "Unitary System Compressor Part Load Ratio"))
    assert_false(FindItemInVariableList(state[], "NOD", "Unitary System Compressor Part Load Ratio"))
    assert_false(FindItemInVariableList(state[], "Inlet", "Zone Air System Sensible Heating Rate"))
    assert_false(FindItemInVariableList(state[], "Outlet", "Zone Air System Sensible Heating Rate"))
    assert_false(FindItemInVariableList(state[], "Any Node", "Zone Air System Sensible Heating Rate"))
    assert_false(FindItemInVariableList(state[], "Inlet", "Refrigeration Compressor Rack Electric Power"))
    assert_false(FindItemInVariableList(state[], "Outlet", "Refrigeration Compressor Rack Electric Power"))
    assert_false(FindItemInVariableList(state[], "Outlet Node", "Refrigeration Compressor Rack Electric Power"))
    assert_false(FindItemInVariableList(state[], "Node", "Refrigeration Compressor Rack Electric Power"))

def test_OutputReportData_Regex_SpecChars():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "\\w,",
        "System Node Mass Flow Rate,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 1)
    compare_err_stream("")

def test_OutputReportData_Regex_Carrot():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "^Inlet(.*)Node,",
        "System Node Mass Flow Rate,",
        "timestep;",
        " Output:Variable,",
        "[^0-9]+,",
        "System Node Humidity Ratio,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 2)
    assert_false(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Inlet System Node", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "SalesFloor1", "System Node Humidity Ratio"))
    assert_true(FindItemInVariableList(state[], "SalesFloor", "System Node Humidity Ratio"))

def test_OutputReportData_Regex_Dollar():
    var idf_objects: String = delimited_string([
        " Output:Variable,",
        "(.*)Node$,",
        "System Node Mass Flow Rate,",
        "timestep;",
    ])
    assert_true(process_idf(idf_objects))
    assert_equal(state.dataOutput.NumConsideredOutputVariables, 1)
    assert_true(FindItemInVariableList(state[], "SalesFloor Inlet Node", "System Node Mass Flow Rate"))
    assert_true(FindItemInVariableList(state[], "Outlet Node", "System Node Mass Flow Rate"))
    assert_false(FindItemInVariableList(state[], "Inlet Node1 ", "System Node Mass Flow Rate"))