# EXTERNAL DEPS (to wire in glue):
# - OutputProcessor.ReportFreq: enum, members EachCall, TimeStep, Hour, Day, Month, Simulation, Year, Num, Invalid
# - OutputProcessor.TimeStepType: enum, members Zone, System, Num, Invalid
# - Constant.Units: enum for unit types
# - Constant.unitNames: list[str] mapping Units enum to string names
# - EnergyPlusData: struct/dataclass with .files, .dataInputProcessing, .dataOutRptTab attributes
# - JsonOutputFilePaths: dataclass with output file path attributes
# - InputOutputFile: class with ensure_open(state, name, control), close() methods
# - FileSystem: module with writeFile(path, data) function and FileTypes enum (JSON, CBOR, MsgPack)
# - EnergyPlus.format: string formatting function (equivalent to fmt::format)
# - OutputReportTabular.SetUnitsStyleFromString: function
# - UtilityRoutines.ShowFatalError: function  
# - UtilityRoutines.getYesNoValue, BooleanSwitch.Yes: enum/function
# - reportFreqNames: list[str] mapping ReportFreq to display strings
# - milo.dtoa: double to string conversion
# - print with FormatSyntax: output printing

from dataclasses import dataclass, field
from typing import Protocol, List, Dict, Any, Optional, Tuple
import json as json_module
from enum import IntEnum


def trim(s: str) -> str:
    """trim string whitespace from both ends"""
    if not s:
        return ""
    first = 0
    last = len(s) - 1
    while first <= last and s[first] == ' ':
        first += 1
    while last >= first and s[last] == ' ':
        last -= 1
    if first > last:
        return ""
    return s[first:last+1]


class BaseResultObject:
    pass


class SimInfo(BaseResultObject):
    def __init__(self):
        self.ProgramVersion = ""
        self.SimulationEnvironment = ""
        self.InputModelURI = ""
        self.StartDateTimeStamp = ""
        self.RunTime = ""
        self.NumWarningsDuringWarmup = ""
        self.NumSevereDuringWarmup = ""
        self.NumWarningsDuringSizing = ""
        self.NumSevereDuringSizing = ""
        self.NumWarnings = ""
        self.NumSevere = ""

    def setProgramVersion(self, programVersion: str):
        self.ProgramVersion = programVersion

    def getProgramVersion(self) -> str:
        return self.ProgramVersion

    def setSimulationEnvironment(self, simulationEnvironment: str):
        self.SimulationEnvironment = simulationEnvironment

    def setInputModelURI(self, inputModelURI: str):
        self.InputModelURI = inputModelURI

    def setStartDateTimeStamp(self, startDateTimeStamp: str):
        self.StartDateTimeStamp = startDateTimeStamp

    def setRunTime(self, elapsedTime: str):
        self.RunTime = elapsedTime

    def setNumErrorsWarmup(self, numWarningsDuringWarmup: str, numSevereDuringWarmup: str):
        self.NumWarningsDuringWarmup = numWarningsDuringWarmup
        self.NumSevereDuringWarmup = numSevereDuringWarmup

    def setNumErrorsSizing(self, numWarningsDuringSizing: str, numSevereDuringSizing: str):
        self.NumWarningsDuringSizing = numWarningsDuringSizing
        self.NumSevereDuringSizing = numSevereDuringSizing

    def setNumErrorsSummary(self, numWarnings: str, numSevere: str):
        self.NumWarnings = numWarnings
        self.NumSevere = numSevere

    def getJSON(self) -> Dict[str, Any]:
        root = {
            "ProgramVersion": self.ProgramVersion,
            "SimulationEnvironment": self.SimulationEnvironment,
            "InputModelURI": self.InputModelURI,
            "StartDateTimeStamp": self.StartDateTimeStamp,
            "RunTime": self.RunTime,
            "ErrorSummary": {
                "NumWarnings": self.NumWarnings,
                "NumSevere": self.NumSevere
            },
            "ErrorSummaryWarmup": {
                "NumWarnings": self.NumWarningsDuringWarmup,
                "NumSevere": self.NumSevereDuringWarmup
            },
            "ErrorSummarySizing": {
                "NumWarnings": self.NumWarningsDuringSizing,
                "NumSevere": self.NumSevereDuringSizing
            }
        }
        return root


class Variable(BaseResultObject):
    def __init__(self, VarName: str = "", reportFrequency=None, timeStepType=None, 
                 ReportID: int = -1, units=None, customUnits: str = ""):
        self.m_varName = VarName
        self.m_reportFreq = reportFrequency
        self.m_timeStepType = timeStepType
        self.m_rptID = ReportID
        self.m_units = units
        self.m_customUnits = customUnits
        self.m_values: List[float] = []

    def variableName(self) -> str:
        return self.m_varName

    def setVariableName(self, VarName: str):
        self.m_varName = VarName

    def sReportFrequency(self) -> str:
        reportFreqStrings = ["Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly"]
        timeStepTypeStrings = ["Detailed - Zone", "Detailed - HVAC"]
        
        if self.m_reportFreq == 0:  # ReportFreq::EachCall
            return timeStepTypeStrings[int(self.m_timeStepType)]
        else:
            return reportFreqStrings[int(self.m_reportFreq)]

    def iReportFrequency(self):
        return self.m_reportFreq

    def setReportFrequency(self, reportFrequency):
        self.m_reportFreq = reportFrequency

    def timeStepType(self):
        return self.m_timeStepType

    def setTimeStepType(self, timeStepType):
        self.m_timeStepType = timeStepType

    def reportID(self) -> int:
        return self.m_rptID

    def setReportID(self, Id: int):
        self.m_rptID = Id

    def units(self):
        return self.m_units

    def setUnits(self, units):
        self.m_units = units

    def customUnits(self) -> str:
        return self.m_customUnits

    def setCustomUnits(self, customUnits: str):
        self.m_customUnits = customUnits

    def pushValue(self, val: float):
        self.m_values.append(val)

    def value(self, index: int) -> float:
        return self.m_values[index]

    def numValues(self) -> int:
        return len(self.m_values)

    def getJSON(self) -> Dict[str, Any]:
        if self.m_customUnits:
            root = {
                "Name": self.m_varName,
                "Units": self.m_customUnits,
                "Frequency": self.sReportFrequency()
            }
        else:
            root = {
                "Name": self.m_varName,
                "Units": Constant_unitNames[int(self.m_units)],
                "Frequency": self.sReportFrequency()
            }
        return root


class OutputVariable(Variable):
    def __init__(self, VarName: str, reportFrequency, timeStepType, 
                 ReportID: int, units, customUnits: str = ""):
        super().__init__(VarName, reportFrequency, timeStepType, ReportID, units, customUnits)


class MeterVariable(Variable):
    def __init__(self, VarName: str = "", reportFrequency=None, ReportID: int = -1,
                 units=None, MeterOnly: bool = True, Accumulative: bool = False):
        super().__init__(VarName, reportFrequency, 1, ReportID, units)  # TimeStepType::Zone = 1
        self.acc = Accumulative
        self.meter_only = MeterOnly

    def accumulative(self) -> bool:
        return self.acc

    def setAccumulative(self, state: bool):
        self.acc = state

    def meterOnly(self) -> bool:
        return self.meter_only

    def setMeterOnly(self, state: bool):
        self.meter_only = state

    def getJSON(self) -> Dict[str, Any]:
        root = super().getJSON()
        if self.acc:
            root["Cumulative"] = True
        return root


class DataFrame(BaseResultObject):
    def __init__(self, ReportFreq: str):
        self.ReportFrequency = ReportFreq
        self.DataFrameEnabled = False
        self.VariablesScanned = False
        self.lastHour = 0
        self.lastMinute = 0
        self.TS: List[str] = []
        self.variableMap: Dict[int, Variable] = {}
        self.lastVarID = -1
        self.iso8601 = False
        self.beginningOfInterval = False

    def addVariable(self, var: Variable):
        self.lastVarID = var.reportID()
        self.variableMap[self.lastVarID] = var

    def setDataFrameEnabled(self, state: bool):
        self.DataFrameEnabled = state

    def dataFrameEnabled(self) -> bool:
        return self.DataFrameEnabled

    def setVariablesScanned(self, state: bool):
        self.VariablesScanned = state

    def variablesScanned(self) -> bool:
        return self.VariablesScanned

    def newRow(self, month: int, dayOfMonth: int, hourOfDay: int, curMin: int, calendarYear: int):
        if curMin > 0:
            hourOfDay -= 1
        if curMin == 60:
            curMin = 0
            hourOfDay += 1

        if self.beginningOfInterval:
            if hourOfDay == 24:
                hourOfDay = 0
            hourOfDay, self.lastHour = self.lastHour, hourOfDay
            curMin, self.lastMinute = self.lastMinute, curMin

        if self.iso8601:
            ts_str = f"{calendarYear:04d}-{month:02d}-{dayOfMonth:02d}T{hourOfDay:02d}:{curMin:02d}:00"
        else:
            ts_str = f"{month:02d}/{dayOfMonth:02d} {hourOfDay:02d}:{curMin:02d}:00"
        self.TS.append(ts_str)

    def lastVariable(self) -> Variable:
        return self.variableMap[self.lastVarID]

    def pushVariableValue(self, reportID: int, value: float):
        self.variableMap[reportID].pushValue(value)

    def getVariablesJSON(self) -> List[Dict[str, Any]]:
        arr = []
        for varMap in self.variableMap.values():
            arr.append(varMap.getJSON())
        return arr

    def getJSON(self) -> Dict[str, Any]:
        cols = []
        rows = []

        for varMap in self.variableMap.values():
            if varMap.customUnits():
                cols.append({
                    "Variable": varMap.variableName(),
                    "Units": varMap.customUnits()
                })
            else:
                cols.append({
                    "Variable": varMap.variableName(),
                    "Units": Constant_unitNames[int(varMap.units())]
                })

        vals = []
        for row in range(len(self.TS)):
            vals.clear()
            for varMap in self.variableMap.values():
                if row < varMap.numValues():
                    vals.append(varMap.value(row))
                else:
                    vals.append(None)
            rows.append({self.TS[row]: vals})

        root = {
            "ReportFrequency": self.ReportFrequency,
            "Cols": cols,
            "Rows": rows
        }
        return root

    def writeReport(self, jsonOutputFilePaths, outputJSON: bool, outputCBOR: bool, outputMsgPack: bool):
        root = self.getJSON()
        
        if self.ReportFrequency == "Detailed-HVAC":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSHvacJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSHvacCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSHvacMsgPackFilePath, root)
        elif self.ReportFrequency == "Detailed-Zone":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSZoneJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSZoneCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSZoneMsgPackFilePath, root)
        elif self.ReportFrequency == "TimeStep":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSMsgPackFilePath, root)
        elif self.ReportFrequency == "Daily":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputDYJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputDYCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputDYMsgPackFilePath, root)
        elif self.ReportFrequency == "Hourly":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputHRJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputHRCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputHRMsgPackFilePath, root)
        elif self.ReportFrequency == "Monthly":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputMNJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputMNCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputMNMsgPackFilePath, root)
        elif self.ReportFrequency == "RunPeriod":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputSMJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputSMCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputSMMsgPackFilePath, root)
        elif self.ReportFrequency == "Yearly":
            if outputJSON:
                FileSystem_writeFile("JSON", jsonOutputFilePaths.outputYRJsonFilePath, root)
            if outputCBOR:
                FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputYRCborFilePath, root)
            if outputMsgPack:
                FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputYRMsgPackFilePath, root)


class MeterDataFrame(DataFrame):
    def __init__(self, ReportFreq: str):
        super().__init__(ReportFreq)
        self.meterMap: Dict[int, MeterVariable] = {}

    def addVariable(self, var: MeterVariable):
        self.lastVarID = var.reportID()
        self.meterMap[self.lastVarID] = var

    def pushVariableValue(self, reportID: int, value: float):
        self.meterMap[reportID].pushValue(value)

    def getJSON(self, meterOnlyCheck: bool = False) -> Dict[str, Any]:
        cols = []
        rows = []

        for varMap in self.meterMap.values():
            if not (meterOnlyCheck and varMap.meterOnly()):
                cols.append({
                    "Variable": varMap.variableName(),
                    "Units": Constant_unitNames[int(varMap.units())]
                })

        if not cols:
            return {}

        vals = []
        for row in range(len(self.TS)):
            vals.clear()
            for varMap in self.meterMap.values():
                if not (meterOnlyCheck and varMap.meterOnly()):
                    if row < varMap.numValues():
                        vals.append(varMap.value(row))
                    else:
                        vals.append(None)
            rows.append({self.TS[row]: vals})

        root = {
            "ReportFrequency": self.ReportFrequency,
            "Cols": cols,
            "Rows": rows
        }
        return root


class Table(BaseResultObject):
    def __init__(self, body: List[List[str]], rowLabels: List[str], columnLabels: List[str],
                 tableName: str, footnoteText: str):
        self.TableName = tableName
        self.FootnoteText = footnoteText
        self.ColHeaders: List[str] = []
        self.RowHeaders: List[str] = []
        self.Data: List[List[str]] = []

        sizeColumnLabels = len(columnLabels)
        sizeRowLabels = len(rowLabels)

        for iCol in range(sizeColumnLabels):
            self.ColHeaders.append(columnLabels[iCol])
            col: List[str] = []
            for iRow in range(sizeRowLabels):
                if iCol == 0:
                    self.RowHeaders.append(rowLabels[iRow])
                col.append(trim(body[iCol][iRow]))
            self.Data.append(col)

    def getJSON(self) -> Dict[str, Any]:
        cols = []
        rows = {}

        for ColHeader in self.ColHeaders:
            cols.append(ColHeader)

        for row in range(len(self.RowHeaders)):
            rowvec = []
            for col in range(len(self.ColHeaders)):
                rowvec.append(self.Data[col][row])
            rows[self.RowHeaders[row]] = rowvec

        root = {
            "TableName": self.TableName,
            "Cols": cols,
            "Rows": rows
        }

        if self.FootnoteText:
            root["Footnote"] = self.FootnoteText

        return root


class Report(BaseResultObject):
    def __init__(self):
        self.ReportName = ""
        self.ReportForString = ""
        self.Tables: List[Table] = []

    def getJSON(self) -> Dict[str, Any]:
        root = {
            "ReportName": self.ReportName,
            "For": self.ReportForString
        }

        cols = []
        for table in self.Tables:
            cols.append(table.getJSON())

        root["Tables"] = cols
        return root


class ReportsCollection(BaseResultObject):
    def __init__(self):
        self.reportsMap: Dict[str, Report] = {}

    def addReportTable(self, body: List[List[str]], rowLabels: List[str], columnLabels: List[str],
                      reportName: str, reportForString: str, tableName: str, footnoteText: str = ""):
        key = reportName + reportForString
        tbl = Table(body, rowLabels, columnLabels, tableName, footnoteText)

        if key in self.reportsMap:
            self.reportsMap[key].Tables.append(tbl)
        else:
            r = Report()
            r.ReportName = reportName
            r.ReportForString = reportForString
            r.Tables.append(tbl)
            self.reportsMap[key] = r

    def getJSON(self) -> List[Dict[str, Any]]:
        root = []
        for report in self.reportsMap.values():
            root.append(report.getJSON())
        return root


class CSVWriter(BaseResultObject):
    def __init__(self, num_output_variables: int = 0):
        self.s = ""
        self.smallestReportFreq = 6  # ReportFreq::Year
        self.outputs: Dict[str, List[str]] = {}
        self.outputVariableIndices: List[bool] = [False] * num_output_variables

    def parseTS Outputs(self, state, data: Dict[str, Any], outputVariables: List[str], reportingFrequency: int):
        if not data:
            return

        self.updateReportFreq(reportingFrequency)
        indices = []

        reportFrequency = data.get("ReportFrequency", "")
        if reportFrequency == "Detailed-HVAC" or reportFrequency == "Detailed-Zone":
            reportFrequency = "Each Call"

        columns = data.get("Cols", [])
        for column in columns:
            search_string = f"{column['Variable']} [{column['Units']}]({reportFrequency})"
            if search_string not in outputVariables:
                search_string = f"{column['Variable']} [{column['Units']}](Each Call)"
                if search_string not in outputVariables:
                    ShowFatalError(state, f"Output variable ({search_string}) not found output variable list")

            idx = outputVariables.index(search_string)
            self.outputVariableIndices[idx] = True
            indices.append(idx)

        rows = data.get("Rows", [])
        for row in rows:
            for ts_key, values in row.items():
                if ts_key not in self.outputs:
                    output = [""] * len(outputVariables)
                    for i, col in enumerate(values):
                        if col is None:
                            output[indices[i]] = ""
                        else:
                            output[indices[i]] = str(col)
                    self.outputs[ts_key] = output
                else:
                    for i, col in enumerate(values):
                        if col is None:
                            self.outputs[ts_key][indices[i]] = ""
                        else:
                            self.outputs[ts_key][indices[i]] = str(col)

    def updateReportFreq(self, reportingFrequency: int):
        if reportingFrequency < self.smallestReportFreq:
            self.smallestReportFreq = reportingFrequency

    @staticmethod
    def convertToMonth(datetime: str) -> str:
        months = {
            "01": "January", "02": "February", "03": "March", "04": "April",
            "05": "May", "06": "June", "07": "July", "08": "August",
            "09": "September", "10": "October", "11": "November", "12": "December"
        }
        month = datetime[:2]
        pos = datetime.find(' ')
        if pos != -1:
            time = datetime[pos:]
        else:
            time = ""

        assert time == " 24:00:00" or time == " 00:00:00"

        return months[month]

    def writeOutput(self, state, outputVariables: List[str], outputFile, outputControl: bool, rewriteTimestamp: bool):
        outputFile.ensure_open(state, "OpenOutputFiles", outputControl)

        print_format_output(outputFile, "Date/Time,")
        sep = ""
        for idx, var in enumerate(outputVariables):
            if not self.outputVariableIndices[idx]:
                continue
            print_format_output(outputFile, f"{sep}{var}")
            if not sep:
                sep = ","
        print_format_output(outputFile, "\n")

        for datetime, values in self.outputs.items():
            dt = datetime
            if rewriteTimestamp:
                if self.smallestReportFreq < 4:  # ReportFreq::Month
                    dt = dt.replace(' ', '  ', 1)
                else:
                    dt = self.convertToMonth(dt)

            print_format_output(outputFile, f" {dt},")

            filtered_values = []
            for idx, v in enumerate(values):
                if self.outputVariableIndices[idx]:
                    filtered_values.append(v)

            last_idx = len(filtered_values) - 1
            for idx in range(len(filtered_values) - 1, -1, -1):
                if filtered_values[idx]:
                    last_idx = idx
                    break

            for idx in range(last_idx):
                print_format_output(outputFile, f"{filtered_values[idx]},")
            print_format_output(outputFile, f"{filtered_values[last_idx]}\n")

        outputFile.close()


class ResultsFramework(BaseResultObject):
    def __init__(self):
        self.tsEnabled = False
        self.tsAndTabularEnabled = False
        self.outputJSON = False
        self.outputCBOR = False
        self.outputMsgPack = False
        self.rewriteTimestamp = True
        self.outputVariables: List[str] = []
        
        self.SimulationInformation = SimInfo()
        self.MDD: List[str] = []
        self.RDD: List[str] = []
        self.TabularReportsCollection = ReportsCollection()
        
        self.detailedTSData = [DataFrame("Detailed-Zone"), DataFrame("Detailed-HVAC")]
        self.freqTSData = [
            DataFrame("Each Call"),
            DataFrame("TimeStep"),
            DataFrame("Hourly"),
            DataFrame("Daily"),
            DataFrame("Monthly"),
            DataFrame("RunPeriod"),
            DataFrame("Yearly")
        ]
        self.Meters = [
            MeterDataFrame("Each Call"),
            MeterDataFrame("TimeStep"),
            MeterDataFrame("Hourly"),
            MeterDataFrame("Daily"),
            MeterDataFrame("Monthly"),
            MeterDataFrame("RunPeriod"),
            MeterDataFrame("Yearly")
        ]

    def setupOutputOptions(self, state):
        if state.files.outputControl.csv:
            self.tsEnabled = True
            self.tsAndTabularEnabled = True

        if not state.files.outputControl.json:
            return

        numberOfOutputSchemaObjects = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Output:JSON")
        if numberOfOutputSchemaObjects == 0:
            return

        alphas = [""] * 6
        numAlphas = 0
        numbers = [0.0, 0.0]
        numNumbers = 0
        status = 0
        state.dataInputProcessing.inputProcessor.getObjectItem(state, "Output:JSON", 1, alphas, numAlphas, numbers, numNumbers, status)

        if numAlphas > 0:
            option = alphas[0]
            if Util_SameString(option, "TimeSeries"):
                self.tsEnabled = True
            elif Util_SameString(option, "TimeSeriesAndTabular"):
                self.tsEnabled = True
                self.tsAndTabularEnabled = True

            self.outputJSON = True
            self.outputCBOR = False
            self.outputMsgPack = False

            if numAlphas >= 2:
                self.outputJSON = Util_SameString(alphas[1], "Yes")

            if numAlphas >= 3:
                self.outputCBOR = Util_SameString(alphas[2], "Yes")

            if numAlphas >= 4:
                self.outputMsgPack = Util_SameString(alphas[3], "Yes")

            ort = state.dataOutRptTab
            ort.unitsStyle_JSON = OutputReportTabular_SetUnitsStyleFromString(alphas[4])
            ort.formatReals_JSON = (getYesNoValue(alphas[5]) == BooleanSwitch_Yes)

    def timeSeriesEnabled(self) -> bool:
        return self.tsEnabled

    def timeSeriesAndTabularEnabled(self) -> bool:
        return self.tsAndTabularEnabled

    def JSONEnabled(self) -> bool:
        return self.outputJSON

    def CBOREnabled(self) -> bool:
        return self.outputCBOR

    def MsgPackEnabled(self) -> bool:
        return self.outputMsgPack

    def initializeTSDataFrame(self, reportFrequency: int, Variables: List, timeStepType: int = 1):
        for var in Variables:
            if var.Report and var.freq == reportFrequency:
                if var.units == 15:  # Constant::Units::customEMS
                    rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units, var.unitNameCustomEMS)
                else:
                    rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units)

                if reportFrequency == 0:  # ReportFreq::EachCall
                    if timeStepType == var.timeStepType:
                        self.detailedTSData[int(timeStepType)].setDataFrameEnabled(True)
                        self.detailedTSData[int(timeStepType)].addVariable(rfvar)
                elif reportFrequency in [1, 2, 3, 4, 5, 6]:  # Hour, TimeStep, Day, Month, Simulation, Year
                    self.freqTSData[int(reportFrequency)].setDataFrameEnabled(True)
                    self.freqTSData[int(reportFrequency)].addVariable(rfvar)

        if reportFrequency == 0:  # ReportFreq::EachCall
            self.detailedTSData[int(timeStepType)].setVariablesScanned(True)
        elif reportFrequency in [1, 2, 3, 4, 5, 6]:
            self.detailedTSData[int(timeStepType)].setVariablesScanned(True)

    def initializeMeters(self, meters: List, freq: int):
        if freq == 0:  # ReportFreq::EachCall
            pass
        elif freq in [1, 2, 3, 4, 5, 6]:
            for meter in meters:
                period = meter.periods[int(freq)]
                if period.Rpt or period.RptFO:
                    self.Meters[int(freq)].addVariable(MeterVariable(meter.Name, freq, period.RptNum, meter.units, period.RptFO))
                    self.Meters[int(freq)].setDataFrameEnabled(True)
                if period.accRpt or period.accRptFO:
                    self.Meters[int(freq)].addVariable(MeterVariable(meter.Name, freq, period.accRptNum, meter.units, period.accRptFO))
                    self.Meters[int(freq)].setDataFrameEnabled(True)

        if freq in [1, 2, 3, 4, 5, 6]:
            self.Meters[int(freq)].setVariablesScanned(True)

    def setISO8601(self, value: bool):
        self.rewriteTimestamp = not value
        for iTimeStep in range(2):  # TimeStepType::Num = 2
            self.detailedTSData[iTimeStep].iso8601 = value

        for iFreq in range(1, 7):  # ReportFreq::TimeStep to Num
            self.freqTSData[iFreq].iso8601 = value
            self.Meters[iFreq].iso8601 = value

    def setBeginningOfInterval(self, value: bool):
        for iTimeStep in range(2):
            self.detailedTSData[iTimeStep].beginningOfInterval = value

        for iFreq in range(7):
            self.freqTSData[iFreq].beginningOfInterval = value
            self.Meters[iFreq].beginningOfInterval = value

    def writeOutputs(self, state):
        if state.files.outputControl.csv:
            self.writeCSVOutput(state)

        if self.timeSeriesEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
            self.writeTimeSeriesReports(state.files.json)

        if self.timeSeriesAndTabularEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
            self.writeReport(state.files.json)

    def writeCSVOutput(self, state):
        if not self.hasOutputData():
            return

        csv = CSVWriter(len(self.outputVariables))
        mtr_csv = CSVWriter(len(self.outputVariables))

        for freq in [6, 5, 4, 3, 2, 1]:  # Year, Simulation, Month, Day, Hour, TimeStep
            if self.hasTSData(freq):
                csv.parseTSOutputs(state, self.freqTSData[int(freq)].getJSON(), self.outputVariables, freq)

            if self.hasMeters(freq):
                csv.parseTSOutputs(state, self.Meters[int(freq)].getJSON(True), self.outputVariables, freq)
                mtr_csv.parseTSOutputs(state, self.Meters[int(freq)].getJSON(), self.outputVariables, freq)

        for timeStepType in [1, 0]:  # System, Zone
            if self.hasDetailedTSData(timeStepType):
                csv.parseTSOutputs(state, self.detailedTSData[int(timeStepType)].getJSON(), self.outputVariables, 0)

        csv.writeOutput(state, self.outputVariables, state.files.csv, state.files.outputControl.csv, self.rewriteTimestamp)
        if self.hasMeterData():
            mtr_csv.writeOutput(state, self.outputVariables, state.files.mtr_csv, state.files.outputControl.csv, self.rewriteTimestamp)

    def writeTimeSeriesReports(self, jsonOutputFilePaths):
        for timeStepType in [1, 0]:  # Zone, System
            if self.hasDetailedTSData(timeStepType):
                self.detailedTSData[int(timeStepType)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)

        for freq in [1, 2, 3, 4, 5, 6]:  # TimeStep, Hour, Day, Month, Simulation, Year
            if self.hasFreqTSData(freq):
                self.freqTSData[int(freq)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)

    def writeReport(self, jsonOutputFilePaths):
        root = {"SimulationResults": {"Simulation": self.SimulationInformation.getJSON()}}

        outputVars = {}
        timeStepStrings = ["Detailed-Zone", "Detailed-HVAC"]
        for timeStep in [1, 0]:  # Zone, System
            if self.hasDetailedTSData(timeStep):
                outputVars[timeStepStrings[int(timeStep)]] = self.detailedTSData[int(timeStep)].getVariablesJSON()

        freqStrings = ["Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly"]
        for freq in [6, 5, 4, 3, 2, 1]:  # Year, Simulation, Month, Day, Hour, TimeStep
            if self.hasFreqTSData(freq):
                outputVars[freqStrings[int(freq)]] = self.freqTSData[int(freq)].getVariablesJSON()

        outputVars["OutputDictionary"] = {
            "Description": "Dictionary containing output variables that may be requested",
            "Variables": self.RDD
        }

        meterVars = {}
        meterData = {}
        for freq in [6, 5, 4, 3, 2, 1]:
            if self.hasMeters(freq):
                meterVars[freqStrings[int(freq)]] = self.Meters[int(freq)].getVariablesJSON()
                meterData[freqStrings[int(freq)]] = self.Meters[int(freq)].getJSON()

        meterVars["MeterDictionary"] = {
            "Description": "Dictionary containing meter variables that may be requested",
            "Meters": self.MDD
        }

        root["OutputVariables"] = outputVars
        root["MeterVariables"] = meterVars
        root["MeterData"] = meterData
        root["TabularReports"] = self.TabularReportsCollection.getJSON()

        if self.outputJSON:
            FileSystem_writeFile("JSON", jsonOutputFilePaths.outputJsonFilePath, root)
        if self.outputCBOR:
            FileSystem_writeFile("CBOR", jsonOutputFilePaths.outputCborFilePath, root)
        if self.outputMsgPack:
            FileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputMsgPackFilePath, root)

    def addReportVariable(self, keyedValue: str, variableName: str, units: str, freq: int):
        var_str = f"{keyedValue}:{variableName} [{units}]({reportFreqNames[int(freq)]})"
        self.outputVariables.append(var_str)

    def addReportMeter(self, meter: str, units: str, freq: int):
        meter_str = f"{meter} [{units}]({reportFreqNames[int(freq)]})"
        self.outputVariables.append(meter_str)

    def hasDetailedTSData(self, timeStepType: int) -> bool:
        return self.detailedTSData[int(timeStepType)].dataFrameEnabled()

    def hasFreqTSData(self, freq: int) -> bool:
        return self.freqTSData[int(freq)].dataFrameEnabled()

    def hasMeters(self, freq: int) -> bool:
        return self.Meters[int(freq)].dataFrameEnabled()

    def hasMeterData(self) -> bool:
        return (self.hasMeters(1) or self.hasMeters(2) or self.hasMeters(3) or
                self.hasMeters(4) or self.hasMeters(5) or self.hasMeters(6))

    def hasTSData(self, freq: int, timeStepType: int = 2) -> bool:
        assert freq != 7 and (freq != 0 or timeStepType != 2)
        if freq == 0:  # ReportFreq::EachCall
            return self.detailedTSData[int(timeStepType)].dataFrameEnabled()
        else:
            return self.freqTSData[int(freq)].dataFrameEnabled()

    def hasAnyTSData(self) -> bool:
        for iTimeStep in range(2):
            if self.detailedTSData[iTimeStep].dataFrameEnabled():
                return True
        for iFreq in range(1, 7):
            if self.freqTSData[iFreq].dataFrameEnabled():
                return True
        return False

    def hasOutputData(self) -> bool:
        return self.hasAnyTSData() or self.hasMeterData()


@dataclass
class ResultsFrameworkData:
    resultsFramework: ResultsFramework = field(default_factory=ResultsFramework)

    def init_constant_state(self, state):
        pass

    def init_state(self, state):
        pass

    def clear_state(self):
        for iFreq in range(1, 7):
            meters = self.resultsFramework.Meters[iFreq]
            meters.setDataFrameEnabled(False)
            meters.setVariablesScanned(False)


def FileSystem_writeFile(file_type: str, path: str, data: Any):
    pass


def print_format_output(outputFile, text: str):
    pass


def Util_SameString(a: str, b: str) -> bool:
    return a.lower() == b.lower()


def ShowFatalError(state, msg: str):
    raise RuntimeError(msg)


def OutputReportTabular_SetUnitsStyleFromString(s: str):
    return 0


def getYesNoValue(s: str):
    return 0


BooleanSwitch_Yes = 1

Constant_unitNames = [""] * 100

reportFreqNames = ["Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly"]
