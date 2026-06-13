from testing import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataOutputs import *
from EnergyPlus.NodeInputManager import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.ResultsFramework import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.UtilityRoutines import *
from nlohmann.json import json
from .Fixtures.ResultsFrameworkFixture import ResultsFrameworkFixture
from EnergyPlus.OutputProcessor import *
from EnergyPlus.ResultsFramework import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.DataOutputs import *
from nlohmann.json import literals

@fixture
def state():
    return EnergyPlusData()

def test_ResultsFramework_ParseJsonObject1(state: EnergyPlusData):
    var idf_objects: String = delimited_string([
        "Output:JSON,",
        "TimeSeriesAndTabular;",
    ])
    assert_true(process_idf(idf_objects))
    state.dataResultsFramework.resultsFramework.setupOutputOptions(state)
    assert_true(state.dataResultsFramework.resultsFramework.timeSeriesAndTabularEnabled())

def test_ResultsFramework_ParseJsonObject2(state: EnergyPlusData):
    var idf_objects: String = delimited_string([
        "Output:JSON,",
        "TimeSeries;",
    ])
    assert_true(process_idf(idf_objects))
    state.dataResultsFramework.resultsFramework.setupOutputOptions(state)
    assert_true(state.dataResultsFramework.resultsFramework.timeSeriesEnabled())

def test_ResultsFramework_SimInfo(state: EnergyPlusData):
    state.dataResultsFramework.resultsFramework.SimulationInformation.setProgramVersion("EnergyPlus, Version 8.6.0-0f5a10914b")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setStartDateTimeStamp("2017.03.22 11:03")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setInputModelURI("")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime("00hr 08min  6.67sec")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary("1", "2")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing("0", "0")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup("0", "2")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setSimulationEnvironment("")
    var result: json = state.dataResultsFramework.resultsFramework.SimulationInformation.getJSON()
    var expectedResult: json = json(R"( {
            "ErrorSummary": {
                "NumSevere": "2",
                "NumWarnings": "1"
            },
            "ErrorSummarySizing": {
                "NumSevere": "0",
                "NumWarnings": "0"
            },
            "ErrorSummaryWarmup": {
                "NumSevere": "2",
                "NumWarnings": "0"
            },
            "InputModelURI": "",
            "ProgramVersion": "EnergyPlus, Version 8.6.0-0f5a10914b",
            "RunTime": "00hr 08min  6.67sec",
            "SimulationEnvironment": "",
            "StartDateTimeStamp": "2017.03.22 11:03"
        } )"_json)
    assert_equal(result.dump(), expectedResult.dump())

def test_ResultsFramework_SimInfo_String(state: EnergyPlusData):
    state.dataResultsFramework.resultsFramework.SimulationInformation.setProgramVersion("EnergyPlus, Version 8.6.0-0f5a10914b")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setStartDateTimeStamp("2017.03.22 11:03")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setInputModelURI("")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setRunTime("00hr 08min  6.67sec")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSummary("1", "2")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsSizing("0", "0")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setNumErrorsWarmup("0", "2")
    state.dataResultsFramework.resultsFramework.SimulationInformation.setSimulationEnvironment("")
    var result: json = state.dataResultsFramework.resultsFramework.SimulationInformation.getJSON()
    var expectedResult: String = "{\n    \"ErrorSummary\": {\n        \"NumSevere\": \"2\",\n        \"NumWarnings\": \"1\"\n    },\n    \"ErrorSummarySizing\": {\n        \"NumSevere\": \"0\",\n        \"NumWarnings\": \"0\"\n    },\n    \"ErrorSummaryWarmup\": {\n        \"NumSevere\": \"2\",\n        \"NumWarnings\": \"0\"\n    },\n    \"InputModelURI\": \"\",\n    \"ProgramVersion\": \"EnergyPlus, Version 8.6.0-0f5a10914b\",\n    \"RunTime\": \"00hr 08min  6.67sec\",\n    \"SimulationEnvironment\": \"\",\n    \"StartDateTimeStamp\": \"2017.03.22 11:03\"\n}"
    assert_equal(result.dump(4), expectedResult)

def test_ResultsFramework_VariableInfo(state: EnergyPlusData):
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var repordId: Int = 1
    var var_: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, repordId, Constant.Units.C)
    var expected_result: String = "{\n         \"Frequency\": \"TimeStep\",\n         \"Name\": \"SALESFLOOR INLET NODE:System Node Temperature\",\n " \
                                  "        \"Units\": \"C\"\n}"
    assert_equal(expected_result, var_.getJSON().dump('\t'))
    var expectedObject: json = json(R"( {
            "Frequency": "TimeStep",
            "Name": "SALESFLOOR INLET NODE:System Node Temperature",
            "Units": "C"
        } )"_json)
    assert_equal(expectedObject, var_.getJSON())

def test_ResultsFramework_DataFrameInfo1(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var OutputVars: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    reportId += 1
    var var1: Variable = Variable("SALESFLOOR INLET NODE:System Node Humidity Ratio", ReportFreq.TimeStep, indexType, reportId, Constant.Units.kgWater_kgDryAir)
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    dataTS.addVariable(var0)
    dataTS.addVariable(var1)
    OutputVars["TimeStep"] = dataTS.getVariablesJSON()
    var expectedObject: json = json(R"( {
            "TimeStep": [
                 {
                    "Frequency": "TimeStep",
                    "Name": "SALESFLOOR INLET NODE:System Node Humidity Ratio",
                    "Units": "kgWater/kgDryAir"
                },
                {
                    "Frequency": "TimeStep",
                    "Name": "SALESFLOOR INLET NODE:System Node Temperature",
                    "Units": "C"
                }]
        } )"_json)

def test_ResultsFramework_DataFrameInfo2(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var OutputData: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    dataTS.addVariable(var0)
    dataTS.newRow(2, 25, 1, 45, 2017)
    dataTS.newRow(2, 25, 1, 60, 2017)
    dataTS.newRow(2, 25, 24, 45, 2017)
    dataTS.newRow(2, 25, 24, 60, 2017)
    dataTS.pushVariableValue(reportId, 1.0)
    dataTS.pushVariableValue(reportId, 2.0)
    dataTS.pushVariableValue(reportId, 3.0)
    dataTS.pushVariableValue(reportId, 4.0)
    reportId += 1
    var var1: Variable = Variable("SALESFLOOR INLET NODE:System Node Humidity Ratio", ReportFreq.TimeStep, indexType, reportId, Constant.Units.kgWater_kgDryAir)
    dataTS.addVariable(var1)
    dataTS.pushVariableValue(reportId, 5.0)
    dataTS.pushVariableValue(reportId, 6.0)
    dataTS.pushVariableValue(reportId, 7.0)
    dataTS.pushVariableValue(reportId, 8.0)
    OutputData["TimeStep"] = dataTS.getJSON()
    var expectedObject: json = json(R"( {
            "TimeStep": {
                "Cols":[
                    {
                        "Units" : "C",
                        "Variable":"SALESFLOOR INLET NODE:System Node Temperature"
                    },
                    {
                        "Units" : "kgWater/kgDryAir",
                        "Variable" : "SALESFLOOR INLET NODE:System Node Humidity Ratio"
                    }
                ],
                "ReportFrequency" : "TimeStep",
                "Rows":[
                    { "02/25 00:45:00" : [1.0,5.0] },
                    { "02/25 01:00:00" : [2.0,6.0] },
                    { "02/25 23:45:00" : [3.0,7.0] },
                    { "02/25 24:00:00" : [4.0,8.0] }
                ]
            }
        } )"_json)
    assert_equal(expectedObject.dump(), OutputData.dump())
    reportId += 1
    var var2: Variable = Variable("SALESFLOOR OUTLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    dataTS.addVariable(var2)
    dataTS.pushVariableValue(reportId, 9.0)
    dataTS.pushVariableValue(reportId, 10.0)
    dataTS.pushVariableValue(reportId, 11.0)
    dataTS.pushVariableValue(reportId, 12.0)
    OutputData["TimeStep"] = dataTS.getJSON()
    expectedObject = json(R"( {
            "TimeStep": {
                "Cols":[
                    {
                        "Units" : "C",
                        "Variable":"SALESFLOOR INLET NODE:System Node Temperature"
                    },
                    {
                        "Units" : "kgWater/kgDryAir",
                        "Variable" : "SALESFLOOR INLET NODE:System Node Humidity Ratio"
                    },
                    {
                        "Units": "C",
                        "Variable" : "SALESFLOOR OUTLET NODE:System Node Temperature"
                    }
                ],
                "ReportFrequency" : "TimeStep",
                "Rows":[
                    { "02/25 00:45:00" : [1.0,5.0,9.0] },
                    { "02/25 01:00:00" : [2.0,6.0,10.0] },
                    { "02/25 23:45:00" : [3.0,7.0,11.0] },
                    { "02/25 24:00:00" : [4.0,8.0,12.0] }
                ]
            }
        } )"_json)
    assert_equal(expectedObject.dump(), OutputData.dump())

def test_ResultsFramework_TableInfo(state: EnergyPlusData):
    var rowLabels: Array1D_string = Array1D_string(2)
    rowLabels[0] = "ZONE1DIRECTAIR"
    rowLabels[1] = "ZONE2DIRECTAIR"
    var columnLabels: Array1D_string = Array1D_string(1)
    columnLabels[0] = "User-Specified Maximum Air Flow Rate [m3/s]"
    var tableBody: Array2D_string = Array2D_string()
    tableBody.allocate(columnLabels.size1(), rowLabels.size1())
    tableBody = ""
    tableBody[0][0] = "5.22"
    tableBody[0][1] = "0.275000"
    var tbl: Table = Table(tableBody,
              rowLabels,
              columnLabels,
              "AirTerminal:SingleDuct:ConstantVolume:NoReheat",
              "User-Specified values were used. Design Size values were used if no User-Specified values were provided.")
    var result: json = tbl.getJSON()
    var expectedResult: json = json(R"( {
            "Cols": [
                    "User-Specified Maximum Air Flow Rate [m3/s]"
            ],
            "Footnote": "User-Specified values were used. Design Size values were used if no User-Specified values were provided.",
            "Rows": {
            "ZONE1DIRECTAIR": [
                   "5.22"
                ],
                "ZONE2DIRECTAIR": [
                   "0.275000"
                ]
            },
            "TableName": "AirTerminal:SingleDuct:ConstantVolume:NoReheat"
        } )"_json)
    assert_equal(result.dump(), expectedResult.dump())

def test_ResultsFramework_ReportInfo(state: EnergyPlusData):
    var rowLabels: Array1D_string = Array1D_string(2)
    rowLabels[0] = "ZONE1DIRECTAIR"
    rowLabels[1] = "ZONE2DIRECTAIR"
    var columnLabels: Array1D_string = Array1D_string(1)
    columnLabels[0] = "User-Specified Maximum Air Flow Rate [m3/s]"
    var tableBody: Array2D_string = Array2D_string()
    tableBody.allocate(columnLabels.size1(), rowLabels.size1())
    tableBody[0][0] = "5.22"
    tableBody[0][1] = "0.275000"
    var tbl: Table = Table(tableBody,
              rowLabels,
              columnLabels,
              "AirTerminal:SingleDuct:ConstantVolume:NoReheat",
              "User-Specified values were used. Design Size values were used if no User-Specified values were provided.")
    rowLabels.deallocate()
    columnLabels.deallocate()
    tableBody.deallocate()
    rowLabels.allocate(1)
    columnLabels.allocate(3)
    tableBody.allocate(columnLabels.size1(), rowLabels.size1())
    rowLabels[0] = "FURNACE ACDXCOIL 1"
    columnLabels[0] = "User-Specified rated_air_flow_rate [m3/s]"
    columnLabels[1] = "User-Specified gross_rated_total_cooling_capacity [W]"
    columnLabels[2] = "User-Specified gross_rated_sensible_heat_ratio"
    tableBody[0][0] = "5.50"
    tableBody[1][0] = "100000.00"
    tableBody[2][0] = "100000.00"
    var tbl2: Table = Table(tableBody,
               rowLabels,
               columnLabels,
               "Coil:Cooling:DX:SingleSpeed",
               "User-Specified values were used. Design Size values were used if no User-Specified values were provided.")
    var report: Report = Report()
    report.Tables.push_back(tbl)
    report.Tables.push_back(tbl2)
    report.ReportName = "Component Sizing Summary"
    report.ReportForString = "Entire Facility"
    var result: json = report.getJSON()
    var expectedResult: json = json(R"( {
            "For": "Entire Facility",
            "ReportName": "Component Sizing Summary",
            "Tables": [
                {
                    "Cols": [
                        "User-Specified Maximum Air Flow Rate [m3/s]"
                    ],
                    "Footnote": "User-Specified values were used. Design Size values were used if no User-Specified values were provided.",
                    "Rows": {
                        "ZONE1DIRECTAIR": [
                            "5.22"
                        ],
                        "ZONE2DIRECTAIR": [
                            "0.275000"
                        ]
                    },
                    "TableName": "AirTerminal:SingleDuct:ConstantVolume:NoReheat"
                },
                {
                    "Cols": [
                        "User-Specified rated_air_flow_rate [m3/s]",
                        "User-Specified gross_rated_total_cooling_capacity [W]",
                        "User-Specified gross_rated_sensible_heat_ratio"
                    ],
                    "Footnote": "User-Specified values were used. Design Size values were used if no User-Specified values were provided.",
                    "Rows": {
                        "FURNACE ACDXCOIL 1": [
                            "5.50",
                            "100000.00",
                            "100000.00"
                        ]
                    },
                    "TableName": "Coil:Cooling:DX:SingleSpeed"
                }
            ]
        } )"_json)
    assert_equal(result.dump(), expectedResult.dump())

def test_ResultsFramework_convertToMonth(state: EnergyPlusData):
    var datetime: String
    datetime = "01/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "January")
    datetime = "02/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "February")
    datetime = "03/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "March")
    datetime = "04/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "April")
    datetime = "05/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "May")
    datetime = "06/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "June")
    datetime = "07/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "July")
    datetime = "08/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "August")
    datetime = "09/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "September")
    datetime = "10/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "October")
    datetime = "11/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "November")
    datetime = "12/01 24:00:00"
    convertToMonth(datetime)
    assert_equal(datetime, "December")

def test_ResultsFramework_CSV_Timestamp_Beginning(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    var OutputData: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    dataTS.addVariable(var0)
    rf.addReportVariable("SALESFLOOR INLET NODE", "System Node Temperature", "C", ReportFreq.TimeStep)
    rf.setBeginningOfInterval(true)
    dataTS.newRow(2, 25, 1, 45, 2017)
    dataTS.newRow(2, 25, 1, 60, 2017)
    dataTS.newRow(2, 25, 24, 45, 2017)
    dataTS.newRow(2, 25, 24, 60, 2017)
    dataTS.pushVariableValue(reportId, 1.0)
    dataTS.pushVariableValue(reportId, 2.0)
    dataTS.pushVariableValue(reportId, 3.0)
    dataTS.pushVariableValue(reportId, 4.0)
    var outputs = getCSVOutputs(state, dataTS.getJSON(), state.dataResultsFramework.resultsFramework, OutputProcessor.ReportFreq.TimeStep)
    var expected_output: Map[String, List[String]] = {
        "02/25 00:00:00": ["1.0"], "02/25 00:45:00": ["2.0"], "02/25 01:00:00": ["3.0"], "02/25 23:45:00": ["4.0"]
    }
    assert_equal(expected_output, outputs)

def test_ResultsFramework_CSV_Timestamp(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    var OutputData: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    dataTS.addVariable(var0)
    rf.addReportVariable("SALESFLOOR INLET NODE", "System Node Temperature", "C", ReportFreq.TimeStep)
    dataTS.newRow(2, 25, 1, 45, 2017)
    dataTS.newRow(2, 25, 1, 60, 2017)
    dataTS.newRow(2, 25, 24, 45, 2017)
    dataTS.newRow(2, 25, 24, 60, 2017)
    dataTS.pushVariableValue(reportId, 1.0)
    dataTS.pushVariableValue(reportId, 2.0)
    dataTS.pushVariableValue(reportId, 3.0)
    dataTS.pushVariableValue(reportId, 4.0)
    var outputs = getCSVOutputs(state, dataTS.getJSON(), state.dataResultsFramework.resultsFramework, OutputProcessor.ReportFreq.TimeStep)
    var expected_output: Map[String, List[String]] = {
        "02/25 00:45:00": ["1.0"], "02/25 01:00:00": ["2.0"], "02/25 23:45:00": ["3.0"], "02/25 24:00:00": ["4.0"]
    }
    assert_equal(expected_output, outputs)

def test_ResultsFramework_CSV_Timestamp_8601_End(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    var OutputData: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    dataTS.addVariable(var0)
    rf.addReportVariable("SALESFLOOR INLET NODE", "System Node Temperature", "C", ReportFreq.TimeStep)
    rf.setISO8601(true)
    dataTS.newRow(2, 25, 1, 45, 2017)
    dataTS.newRow(2, 25, 1, 60, 2017)
    dataTS.newRow(2, 25, 24, 45, 2017)
    dataTS.newRow(2, 25, 24, 60, 2017)
    dataTS.pushVariableValue(reportId, 1.0)
    dataTS.pushVariableValue(reportId, 2.0)
    dataTS.pushVariableValue(reportId, 3.0)
    dataTS.pushVariableValue(reportId, 4.0)
    var outputs = getCSVOutputs(state, dataTS.getJSON(), rf, OutputProcessor.ReportFreq.TimeStep)
    var expected_output: Map[String, List[String]] = {
        "2017-02-25T00:45:00": ["1.0"], "2017-02-25T01:00:00": ["2.0"], "2017-02-25T23:45:00": ["3.0"], "2017-02-25T24:00:00": ["4.0"]
    }
    assert_equal(expected_output, outputs)

def test_ResultsFramework_CSV_Timestamp_8601_Beginning(state: EnergyPlusData):
    var rf = state.dataResultsFramework.resultsFramework
    var dataTS = rf.freqTSData[Int(ReportFreq.TimeStep)]
    var OutputData: json
    var indexType: OutputProcessor.TimeStepType = OutputProcessor.TimeStepType.Zone
    var reportId: Int = 1
    var var0: Variable = Variable("SALESFLOOR INLET NODE:System Node Temperature", ReportFreq.TimeStep, indexType, reportId, Constant.Units.C)
    dataTS.addVariable(var0)
    rf.addReportVariable("SALESFLOOR INLET NODE", "System Node Temperature", "C", ReportFreq.TimeStep)
    rf.setISO8601(true)
    rf.setBeginningOfInterval(true)
    dataTS.newRow(2, 25, 1, 45, 2017)
    dataTS.newRow(2, 25, 1, 60, 2017)
    dataTS.newRow(2, 25, 24, 45, 2017)
    dataTS.newRow(2, 25, 24, 60, 2017)
    dataTS.pushVariableValue(reportId, 1.0)
    dataTS.pushVariableValue(reportId, 2.0)
    dataTS.pushVariableValue(reportId, 3.0)
    dataTS.pushVariableValue(reportId, 4.0)
    var outputs = getCSVOutputs(state, dataTS.getJSON(), rf, OutputProcessor.ReportFreq.TimeStep)
    var expected_output: Map[String, List[String]] = {
        "2017-02-25T00:00:00": ["1.0"], "2017-02-25T00:45:00": ["2.0"], "2017-02-25T01:00:00": ["3.0"], "2017-02-25T23:45:00": ["4.0"]
    }
    assert_equal(expected_output, outputs)