from collections import Dict, List
from dataclasses import dataclass
from typing import Optional, Tuple, Protocol
import json


fn trim(s: String) -> String:
    """trim string whitespace from both ends"""
    if s.is_empty():
        return String()
    
    var first = 0
    var last = len(s) - 1
    
    while first <= last and s[first] == ' ':
        first += 1
    while last >= first and s[last] == ' ':
        last -= 1
    
    if first > last:
        return String()
    
    return s[first:last+1]


struct BaseResultObject:
    pass


struct SimInfo(BaseResultObject):
    var ProgramVersion: String
    var SimulationEnvironment: String
    var InputModelURI: String
    var StartDateTimeStamp: String
    var RunTime: String
    var NumWarningsDuringWarmup: String
    var NumSevereDuringWarmup: String
    var NumWarningsDuringSizing: String
    var NumSevereDuringSizing: String
    var NumWarnings: String
    var NumSevere: String

    fn __init__(inout self):
        self.ProgramVersion = String()
        self.SimulationEnvironment = String()
        self.InputModelURI = String()
        self.StartDateTimeStamp = String()
        self.RunTime = String()
        self.NumWarningsDuringWarmup = String()
        self.NumSevereDuringWarmup = String()
        self.NumWarningsDuringSizing = String()
        self.NumSevereDuringSizing = String()
        self.NumWarnings = String()
        self.NumSevere = String()

    fn setProgramVersion(inout self, programVersion: String):
        self.ProgramVersion = programVersion

    fn getProgramVersion(self) -> String:
        return self.ProgramVersion

    fn setSimulationEnvironment(inout self, simulationEnvironment: String):
        self.SimulationEnvironment = simulationEnvironment

    fn setInputModelURI(inout self, inputModelURI: String):
        self.InputModelURI = inputModelURI

    fn setStartDateTimeStamp(inout self, startDateTimeStamp: String):
        self.StartDateTimeStamp = startDateTimeStamp

    fn setRunTime(inout self, elapsedTime: String):
        self.RunTime = elapsedTime

    fn setNumErrorsWarmup(inout self, numWarningsDuringWarmup: String, numSevereDuringWarmup: String):
        self.NumWarningsDuringWarmup = numWarningsDuringWarmup
        self.NumSevereDuringWarmup = numSevereDuringWarmup

    fn setNumErrorsSizing(inout self, numWarningsDuringSizing: String, numSevereDuringSizing: String):
        self.NumWarningsDuringSizing = numWarningsDuringSizing
        self.NumSevereDuringSizing = numSevereDuringSizing

    fn setNumErrorsSummary(inout self, numWarnings: String, numSevere: String):
        self.NumWarnings = numWarnings
        self.NumSevere = numSevere

    fn getJSON(self) -> Dict[String, String]:
        var root = Dict[String, String]()
        root["ProgramVersion"] = self.ProgramVersion
        root["SimulationEnvironment"] = self.SimulationEnvironment
        root["InputModelURI"] = self.InputModelURI
        root["StartDateTimeStamp"] = self.StartDateTimeStamp
        root["RunTime"] = self.RunTime
        return root


struct Variable(BaseResultObject):
    var m_varName: String
    var m_reportFreq: Int
    var m_timeStepType: Int
    var m_rptID: Int
    var m_units: Int
    var m_customUnits: String
    var m_values: List[Float64]

    fn __init__(inout self):
        self.m_varName = String()
        self.m_reportFreq = 0
        self.m_timeStepType = 0
        self.m_rptID = -1
        self.m_units = 0
        self.m_customUnits = String()
        self.m_values = List[Float64]()

    fn __init__(inout self, VarName: String, reportFrequency: Int, timeStepType: Int, 
                ReportID: Int, units: Int):
        self.m_varName = VarName
        self.m_reportFreq = reportFrequency
        self.m_timeStepType = timeStepType
        self.m_rptID = ReportID
        self.m_units = units
        self.m_customUnits = String()
        self.m_values = List[Float64]()

    fn __init__(inout self, VarName: String, reportFrequency: Int, timeStepType: Int,
                ReportID: Int, units: Int, customUnits: String):
        self.m_varName = VarName
        self.m_reportFreq = reportFrequency
        self.m_timeStepType = timeStepType
        self.m_rptID = ReportID
        self.m_units = units
        self.m_customUnits = customUnits
        self.m_values = List[Float64]()

    fn variableName(self) -> String:
        return self.m_varName

    fn setVariableName(inout self, VarName: String):
        self.m_varName = VarName

    fn sReportFrequency(self) -> String:
        var reportFreqStrings = InlineArray[StringLiteral, 7](
            "Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly")
        var timeStepTypeStrings = InlineArray[StringLiteral, 2](
            "Detailed - Zone", "Detailed - HVAC")

        if self.m_reportFreq == 0:
            return String(timeStepTypeStrings[int(self.m_timeStepType)])
        else:
            return String(reportFreqStrings[int(self.m_reportFreq)])

    fn iReportFrequency(self) -> Int:
        return self.m_reportFreq

    fn setReportFrequency(inout self, reportFrequency: Int):
        self.m_reportFreq = reportFrequency

    fn timeStepType(self) -> Int:
        return self.m_timeStepType

    fn setTimeStepType(inout self, timeStepType: Int):
        self.m_timeStepType = timeStepType

    fn reportID(self) -> Int:
        return self.m_rptID

    fn setReportID(inout self, Id: Int):
        self.m_rptID = Id

    fn units(self) -> Int:
        return self.m_units

    fn setUnits(inout self, units: Int):
        self.m_units = units

    fn customUnits(self) -> String:
        return self.m_customUnits

    fn setCustomUnits(inout self, customUnits: String):
        self.m_customUnits = customUnits

    fn pushValue(inout self, val: Float64):
        self.m_values.append(val)

    fn value(self, index: Int) -> Float64:
        return self.m_values[index]

    fn numValues(self) -> Int:
        return len(self.m_values)

    fn getJSON(self) -> Dict[String, String]:
        var root = Dict[String, String]()
        root["Name"] = self.m_varName
        if not self.m_customUnits.is_empty():
            root["Units"] = self.m_customUnits
        else:
            root["Units"] = constant_unitNames[int(self.m_units)]
        root["Frequency"] = self.sReportFrequency()
        return root


struct OutputVariable(Variable):
    fn __init__(inout self, VarName: String, reportFrequency: Int, timeStepType: Int,
                ReportID: Int, units: Int):
        super().__init__(VarName, reportFrequency, timeStepType, ReportID, units)

    fn __init__(inout self, VarName: String, reportFrequency: Int, timeStepType: Int,
                ReportID: Int, units: Int, customUnits: String):
        super().__init__(VarName, reportFrequency, timeStepType, ReportID, units, customUnits)


struct MeterVariable(Variable):
    var acc: Bool
    var meter_only: Bool

    fn __init__(inout self):
        super().__init__()
        self.acc = False
        self.meter_only = True

    fn __init__(inout self, VarName: String, reportFrequency: Int, ReportID: Int,
                units: Int, MeterOnly: Bool, Accumulative: Bool = False):
        super().__init__(VarName, reportFrequency, 0, ReportID, units)
        self.acc = Accumulative
        self.meter_only = MeterOnly

    fn accumulative(self) -> Bool:
        return self.acc

    fn setAccumulative(inout self, state: Bool):
        self.acc = state

    fn meterOnly(self) -> Bool:
        return self.meter_only

    fn setMeterOnly(inout self, state: Bool):
        self.meter_only = state

    fn getJSON(self) -> Dict[String, String]:
        var root = super().getJSON()
        if self.acc:
            root["Cumulative"] = "true"
        return root


struct DataFrame(BaseResultObject):
    var ReportFrequency: String
    var DataFrameEnabled: Bool
    var VariablesScanned: Bool
    var lastHour: Int
    var lastMinute: Int
    var TS: List[String]
    var variableMap: Dict[Int, Variable]
    var lastVarID: Int
    var iso8601: Bool
    var beginningOfInterval: Bool

    fn __init__(inout self, ReportFreq: String):
        self.ReportFrequency = ReportFreq
        self.DataFrameEnabled = False
        self.VariablesScanned = False
        self.lastHour = 0
        self.lastMinute = 0
        self.TS = List[String]()
        self.variableMap = Dict[Int, Variable]()
        self.lastVarID = -1
        self.iso8601 = False
        self.beginningOfInterval = False

    fn addVariable(inout self, var: Variable):
        self.lastVarID = var.reportID()
        self.variableMap[self.lastVarID] = var

    fn setDataFrameEnabled(inout self, state: Bool):
        self.DataFrameEnabled = state

    fn dataFrameEnabled(self) -> Bool:
        return self.DataFrameEnabled

    fn setVariablesScanned(inout self, state: Bool):
        self.VariablesScanned = state

    fn variablesScanned(self) -> Bool:
        return self.VariablesScanned

    fn newRow(inout self, month: Int, dayOfMonth: Int, hourOfDay: Int, curMin: Int, calendarYear: Int):
        var hod = hourOfDay
        var cm = curMin

        if cm > 0:
            hod -= 1
        if cm == 60:
            cm = 0
            hod += 1

        if self.beginningOfInterval:
            if hod == 24:
                hod = 0
            var tmp_hod = hod
            hod = self.lastHour
            self.lastHour = tmp_hod
            var tmp_cm = cm
            cm = self.lastMinute
            self.lastMinute = tmp_cm

        var ts_str: String
        if self.iso8601:
            ts_str = String.format_string("{:04d}-{:02d}-{:02d}T{:02d}:{:02d}:00", calendarYear, month, dayOfMonth, hod, cm)
        else:
            ts_str = String.format_string("{:02d}/{:02d} {:02d}:{:02d}:00", month, dayOfMonth, hod, cm)

        self.TS.append(ts_str)

    fn lastVariable(self) -> Variable:
        return self.variableMap[self.lastVarID]

    fn pushVariableValue(inout self, reportID: Int, value: Float64):
        self.variableMap[reportID].pushValue(value)

    fn getVariablesJSON(self) -> List[Dict[String, String]]:
        var arr = List[Dict[String, String]]()
        for varMap in self.variableMap.values():
            arr.append(varMap.getJSON())
        return arr

    fn getJSON(self) -> Dict[String, List]:
        var cols = List[Dict[String, String]]()
        var rows = List[Dict[String, List[Float64]]]()

        for varMap in self.variableMap.values():
            var col = Dict[String, String]()
            col["Variable"] = varMap.variableName()
            if not varMap.customUnits().is_empty():
                col["Units"] = varMap.customUnits()
            else:
                col["Units"] = constant_unitNames[int(varMap.units())]
            cols.append(col)

        for row in range(len(self.TS)):
            var vals = List[Float64]()
            for varMap in self.variableMap.values():
                if row < varMap.numValues():
                    vals.append(varMap.value(row))

            var row_dict = Dict[String, List[Float64]]()
            row_dict[self.TS[row]] = vals
            rows.append(row_dict)

        var root = Dict[String, List]()
        root["ReportFrequency"] = self.ReportFrequency
        root["Cols"] = cols
        root["Rows"] = rows
        return root

    fn writeReport(inout self, jsonOutputFilePaths, outputJSON: Bool, outputCBOR: Bool, outputMsgPack: Bool):
        var root = self.getJSON()

        if self.ReportFrequency == "Detailed-HVAC":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSHvacJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSHvacCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSHvacMsgPackFilePath, root)
        elif self.ReportFrequency == "Detailed-Zone":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSZoneJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSZoneCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSZoneMsgPackFilePath, root)
        elif self.ReportFrequency == "TimeStep":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputTSJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputTSCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputTSMsgPackFilePath, root)
        elif self.ReportFrequency == "Daily":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputDYJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputDYCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputDYMsgPackFilePath, root)
        elif self.ReportFrequency == "Hourly":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputHRJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputHRCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputHRMsgPackFilePath, root)
        elif self.ReportFrequency == "Monthly":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputMNJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputMNCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputMNMsgPackFilePath, root)
        elif self.ReportFrequency == "RunPeriod":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputSMJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputSMCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputSMMsgPackFilePath, root)
        elif self.ReportFrequency == "Yearly":
            if outputJSON:
                fileSystem_writeFile("JSON", jsonOutputFilePaths.outputYRJsonFilePath, root)
            if outputCBOR:
                fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputYRCborFilePath, root)
            if outputMsgPack:
                fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputYRMsgPackFilePath, root)


struct MeterDataFrame(DataFrame):
    var meterMap: Dict[Int, MeterVariable]

    fn __init__(inout self, ReportFreq: String):
        super().__init__(ReportFreq)
        self.meterMap = Dict[Int, MeterVariable]()

    fn addVariable(inout self, var: MeterVariable):
        self.lastVarID = var.reportID()
        self.meterMap[self.lastVarID] = var

    fn pushVariableValue(inout self, reportID: Int, value: Float64):
        self.meterMap[reportID].pushValue(value)

    fn getJSON(self, meterOnlyCheck: Bool = False) -> Dict[String, List]:
        var cols = List[Dict[String, String]]()
        var rows = List[Dict[String, List[Float64]]]()

        for varMap in self.meterMap.values():
            if not (meterOnlyCheck and varMap.meterOnly()):
                var col = Dict[String, String]()
                col["Variable"] = varMap.variableName()
                col["Units"] = constant_unitNames[int(varMap.units())]
                cols.append(col)

        if len(cols) == 0:
            return Dict[String, List]()

        for row in range(len(self.TS)):
            var vals = List[Float64]()
            for varMap in self.meterMap.values():
                if not (meterOnlyCheck and varMap.meterOnly()):
                    if row < varMap.numValues():
                        vals.append(varMap.value(row))

            var row_dict = Dict[String, List[Float64]]()
            row_dict[self.TS[row]] = vals
            rows.append(row_dict)

        var root = Dict[String, List]()
        root["ReportFrequency"] = self.ReportFrequency
        root["Cols"] = cols
        root["Rows"] = rows
        return root


struct Table(BaseResultObject):
    var TableName: String
    var FootnoteText: String
    var ColHeaders: List[String]
    var RowHeaders: List[String]
    var Data: List[List[String]]

    fn __init__(inout self, body: List[List[String]], rowLabels: List[String], columnLabels: List[String],
                tableName: String, footnoteText: String):
        self.TableName = tableName
        self.FootnoteText = footnoteText
        self.ColHeaders = List[String]()
        self.RowHeaders = List[String]()
        self.Data = List[List[String]]()

        var sizeColumnLabels = len(columnLabels)
        var sizeRowLabels = len(rowLabels)

        for iCol in range(sizeColumnLabels):
            self.ColHeaders.append(columnLabels[iCol])
            var col = List[String]()
            for iRow in range(sizeRowLabels):
                if iCol == 0:
                    self.RowHeaders.append(rowLabels[iRow])
                col.append(trim(body[iCol][iRow]))
            self.Data.append(col)

    fn getJSON(self) -> Dict[String, List]:
        var cols = List[String]()
        var rows = Dict[String, List[String]]()

        for ColHeader in self.ColHeaders:
            cols.append(ColHeader)

        for row in range(len(self.RowHeaders)):
            var rowvec = List[String]()
            for col in range(len(self.ColHeaders)):
                rowvec.append(self.Data[col][row])
            rows[self.RowHeaders[row]] = rowvec

        var root = Dict[String, List]()
        root["TableName"] = self.TableName
        root["Cols"] = cols
        root["Rows"] = rows

        if not self.FootnoteText.is_empty():
            root["Footnote"] = self.FootnoteText

        return root


struct Report(BaseResultObject):
    var ReportName: String
    var ReportForString: String
    var Tables: List[Table]

    fn __init__(inout self):
        self.ReportName = String()
        self.ReportForString = String()
        self.Tables = List[Table]()

    fn getJSON(self) -> Dict[String, List]:
        var root = Dict[String, List]()
        root["ReportName"] = self.ReportName
        root["For"] = self.ReportForString

        var cols = List[Dict[String, List]]()
        for table in self.Tables:
            cols.append(table.getJSON())

        root["Tables"] = cols
        return root


struct ReportsCollection(BaseResultObject):
    var reportsMap: Dict[String, Report]

    fn __init__(inout self):
        self.reportsMap = Dict[String, Report]()

    fn addReportTable(inout self, body: List[List[String]], rowLabels: List[String], columnLabels: List[String],
                     reportName: String, reportForString: String, tableName: String):
        self.addReportTable(body, rowLabels, columnLabels, reportName, reportForString, tableName, String())

    fn addReportTable(inout self, body: List[List[String]], rowLabels: List[String], columnLabels: List[String],
                     reportName: String, reportForString: String, tableName: String, footnoteText: String):
        var key = reportName + reportForString
        var tbl = Table(body, rowLabels, columnLabels, tableName, footnoteText)

        if key in self.reportsMap:
            self.reportsMap[key].Tables.append(tbl)
        else:
            var r = Report()
            r.ReportName = reportName
            r.ReportForString = reportForString
            r.Tables.append(tbl)
            self.reportsMap[key] = r

    fn getJSON(self) -> List[Dict[String, List]]:
        var root = List[Dict[String, List]]()
        for report in self.reportsMap.values():
            root.append(report.getJSON())
        return root


struct CSVWriter(BaseResultObject):
    var s: String
    var smallestReportFreq: Int
    var outputs: Dict[String, List[String]]
    var outputVariableIndices: List[Bool]

    fn __init__(inout self):
        self.s = String()
        self.smallestReportFreq = 6
        self.outputs = Dict[String, List[String]]()
        self.outputVariableIndices = List[Bool]()

    fn __init__(inout self, num_output_variables: Int):
        self.s = String()
        self.smallestReportFreq = 6
        self.outputs = Dict[String, List[String]]()
        self.outputVariableIndices = List[Bool]()
        for _ in range(num_output_variables):
            self.outputVariableIndices.append(False)

    fn parseTSOutputs(inout self, state, data: Dict[String, List], outputVariables: List[String], reportingFrequency: Int):
        if len(data) == 0:
            return

        self.updateReportFreq(reportingFrequency)
        var indices = List[Int]()

        var reportFrequency = data["ReportFrequency"]
        if reportFrequency == "Detailed-HVAC" or reportFrequency == "Detailed-Zone":
            reportFrequency = "Each Call"

        var columns = data["Cols"]
        for column in columns:
            var search_string = String.format_string("{} [{}]({})", column["Variable"], column["Units"], reportFrequency)
            if search_string not in outputVariables:
                search_string = String.format_string("{} [{}](Each Call)", column["Variable"], column["Units"])
                if search_string not in outputVariables:
                    showFatalError(state, String.format_string("Output variable ({}) not found output variable list", search_string))

            var idx = outputVariables.index(search_string)
            self.outputVariableIndices[idx] = True
            indices.append(idx)

        var rows = data["Rows"]
        for row in rows:
            for ts_key in row.keys():
                var values = row[ts_key]
                if ts_key not in self.outputs:
                    var output = List[String]()
                    for _ in range(len(outputVariables)):
                        output.append(String())
                    for i in range(len(values)):
                        if values[i] is None:
                            output[indices[i]] = String()
                        else:
                            output[indices[i]] = String(values[i])
                    self.outputs[ts_key] = output
                else:
                    for i in range(len(values)):
                        if values[i] is None:
                            self.outputs[ts_key][indices[i]] = String()
                        else:
                            self.outputs[ts_key][indices[i]] = String(values[i])

    fn updateReportFreq(inout self, reportingFrequency: Int):
        if reportingFrequency < self.smallestReportFreq:
            self.smallestReportFreq = reportingFrequency

    @staticmethod
    fn convertToMonth(inout datetime: String) -> String:
        var months = Dict[String, String]()
        months["01"] = "January"
        months["02"] = "February"
        months["03"] = "March"
        months["04"] = "April"
        months["05"] = "May"
        months["06"] = "June"
        months["07"] = "July"
        months["08"] = "August"
        months["09"] = "September"
        months["10"] = "October"
        months["11"] = "November"
        months["12"] = "December"

        var month = datetime[0:2]
        var pos = datetime.find(' ')
        var time = String()
        if pos >= 0:
            time = datetime[pos:]

        debug_assert(time == " 24:00:00" or time == " 00:00:00")

        return months[month]

    fn writeOutput(inout self, state, outputVariables: List[String], outputFile, outputControl: Bool, rewriteTimestamp: Bool):
        outputFile.ensure_open(state, "OpenOutputFiles", outputControl)

        printFormatOutput(outputFile, "Date/Time,")
        var sep = String()
        for idx in range(len(outputVariables)):
            if not self.outputVariableIndices[idx]:
                continue
            printFormatOutput(outputFile, String.format_string("{}{}", sep, outputVariables[idx]))
            if sep.is_empty():
                sep = ","

        printFormatOutput(outputFile, "\n")

        for item_key in self.outputs.keys():
            var datetime = item_key
            if rewriteTimestamp:
                if self.smallestReportFreq < 4:
                    datetime = datetime.replace(" ", "  ", 1)
                else:
                    datetime = self.convertToMonth(datetime)

            printFormatOutput(outputFile, String.format_string(" {{}},", datetime))

            var values = self.outputs[datetime]
            var filtered_values = List[String]()
            for idx in range(len(values)):
                if self.outputVariableIndices[idx]:
                    filtered_values.append(values[idx])

            var last_idx = len(filtered_values) - 1
            for idx in range(len(filtered_values) - 1, -1, -1):
                if not filtered_values[idx].is_empty():
                    last_idx = idx
                    break

            for idx in range(last_idx):
                printFormatOutput(outputFile, String.format_string("{{}},", filtered_values[idx]))
            printFormatOutput(outputFile, String.format_string("{{}}\n", filtered_values[last_idx]))

        outputFile.close()


struct ResultsFramework(BaseResultObject):
    var tsEnabled: Bool
    var tsAndTabularEnabled: Bool
    var outputJSON: Bool
    var outputCBOR: Bool
    var outputMsgPack: Bool
    var rewriteTimestamp: Bool
    var outputVariables: List[String]

    var SimulationInformation: SimInfo
    var MDD: List[String]
    var RDD: List[String]
    var TabularReportsCollection: ReportsCollection

    var detailedTSData: List[DataFrame]
    var freqTSData: List[DataFrame]
    var Meters: List[MeterDataFrame]

    fn __init__(inout self):
        self.tsEnabled = False
        self.tsAndTabularEnabled = False
        self.outputJSON = False
        self.outputCBOR = False
        self.outputMsgPack = False
        self.rewriteTimestamp = True
        self.outputVariables = List[String]()

        self.SimulationInformation = SimInfo()
        self.MDD = List[String]()
        self.RDD = List[String]()
        self.TabularReportsCollection = ReportsCollection()

        self.detailedTSData = List[DataFrame]()
        self.detailedTSData.append(DataFrame("Detailed-Zone"))
        self.detailedTSData.append(DataFrame("Detailed-HVAC"))

        self.freqTSData = List[DataFrame]()
        self.freqTSData.append(DataFrame("Each Call"))
        self.freqTSData.append(DataFrame("TimeStep"))
        self.freqTSData.append(DataFrame("Hourly"))
        self.freqTSData.append(DataFrame("Daily"))
        self.freqTSData.append(DataFrame("Monthly"))
        self.freqTSData.append(DataFrame("RunPeriod"))
        self.freqTSData.append(DataFrame("Yearly"))

        self.Meters = List[MeterDataFrame]()
        self.Meters.append(MeterDataFrame("Each Call"))
        self.Meters.append(MeterDataFrame("TimeStep"))
        self.Meters.append(MeterDataFrame("Hourly"))
        self.Meters.append(MeterDataFrame("Daily"))
        self.Meters.append(MeterDataFrame("Monthly"))
        self.Meters.append(MeterDataFrame("RunPeriod"))
        self.Meters.append(MeterDataFrame("Yearly"))

    fn setupOutputOptions(inout self, state):
        if state.files.outputControl.csv:
            self.tsEnabled = True
            self.tsAndTabularEnabled = True

        if not state.files.outputControl.json:
            return

        var numberOfOutputSchemaObjects = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Output:JSON")
        if numberOfOutputSchemaObjects == 0:
            return

        var alphas = List[String]()
        for _ in range(6):
            alphas.append(String())
        var numAlphas = 0
        var numbers = List[Float64]()
        numbers.append(0.0)
        numbers.append(0.0)
        var numNumbers = 0
        var status = 0

        state.dataInputProcessing.inputProcessor.getObjectItem(state, "Output:JSON", 1, alphas, numAlphas, numbers, numNumbers, status)

        if numAlphas > 0:
            var option = alphas[0]
            if util_SameString(option, "TimeSeries"):
                self.tsEnabled = True
            elif util_SameString(option, "TimeSeriesAndTabular"):
                self.tsEnabled = True
                self.tsAndTabularEnabled = True

            self.outputJSON = True
            self.outputCBOR = False
            self.outputMsgPack = False

            if numAlphas >= 2:
                self.outputJSON = util_SameString(alphas[1], "Yes")

            if numAlphas >= 3:
                self.outputCBOR = util_SameString(alphas[2], "Yes")

            if numAlphas >= 4:
                self.outputMsgPack = util_SameString(alphas[3], "Yes")

            var ort = state.dataOutRptTab
            ort.unitsStyle_JSON = outputReportTabular_SetUnitsStyleFromString(alphas[4])
            ort.formatReals_JSON = (getYesNoValue(alphas[5]) == booleanSwitch_Yes)

    fn timeSeriesEnabled(self) -> Bool:
        return self.tsEnabled

    fn timeSeriesAndTabularEnabled(self) -> Bool:
        return self.tsAndTabularEnabled

    fn JSONEnabled(self) -> Bool:
        return self.outputJSON

    fn CBOREnabled(self) -> Bool:
        return self.outputCBOR

    fn MsgPackEnabled(self) -> Bool:
        return self.outputMsgPack

    fn initializeTSDataFrame(inout self, reportFrequency: Int, Variables: List, timeStepType: Int = 1):
        for var in Variables:
            if var.Report and var.freq == reportFrequency:
                var rfvar: Variable
                if var.units == 15:
                    rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units, var.unitNameCustomEMS)
                else:
                    rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units)

                if reportFrequency == 0:
                    if timeStepType == var.timeStepType:
                        self.detailedTSData[int(timeStepType)].setDataFrameEnabled(True)
                        self.detailedTSData[int(timeStepType)].addVariable(rfvar)
                elif reportFrequency in [1, 2, 3, 4, 5, 6]:
                    self.freqTSData[int(reportFrequency)].setDataFrameEnabled(True)
                    self.freqTSData[int(reportFrequency)].addVariable(rfvar)

        if reportFrequency == 0:
            self.detailedTSData[int(timeStepType)].setVariablesScanned(True)
        elif reportFrequency in [1, 2, 3, 4, 5, 6]:
            self.detailedTSData[int(timeStepType)].setVariablesScanned(True)

    fn initializeMeters(inout self, meters: List, freq: Int):
        if freq == 0:
            pass
        elif freq in [1, 2, 3, 4, 5, 6]:
            for meter in meters:
                var period = meter.periods[int(freq)]
                if period.Rpt or period.RptFO:
                    self.Meters[int(freq)].addVariable(MeterVariable(meter.Name, freq, period.RptNum, meter.units, period.RptFO))
                    self.Meters[int(freq)].setDataFrameEnabled(True)
                if period.accRpt or period.accRptFO:
                    self.Meters[int(freq)].addVariable(MeterVariable(meter.Name, freq, period.accRptNum, meter.units, period.accRptFO))
                    self.Meters[int(freq)].setDataFrameEnabled(True)

        if freq in [1, 2, 3, 4, 5, 6]:
            self.Meters[int(freq)].setVariablesScanned(True)

    fn setISO8601(inout self, value: Bool):
        self.rewriteTimestamp = not value
        for iTimeStep in range(2):
            self.detailedTSData[iTimeStep].iso8601 = value

        for iFreq in range(1, 7):
            self.freqTSData[iFreq].iso8601 = value
            self.Meters[iFreq].iso8601 = value

    fn setBeginningOfInterval(inout self, value: Bool):
        for iTimeStep in range(2):
            self.detailedTSData[iTimeStep].beginningOfInterval = value

        for iFreq in range(7):
            self.freqTSData[iFreq].beginningOfInterval = value
            self.Meters[iFreq].beginningOfInterval = value

    fn writeOutputs(inout self, state):
        if state.files.outputControl.csv:
            self.writeCSVOutput(state)

        if self.timeSeriesEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
            self.writeTimeSeriesReports(state.files.json)

        if self.timeSeriesAndTabularEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
            self.writeReport(state.files.json)

    fn writeCSVOutput(inout self, state):
        if not self.hasOutputData():
            return

        var csv = CSVWriter(len(self.outputVariables))
        var mtr_csv = CSVWriter(len(self.outputVariables))

        for freq in [6, 5, 4, 3, 2, 1]:
            if self.hasTSData(freq):
                csv.parseTSOutputs(state, self.freqTSData[int(freq)].getJSON(), self.outputVariables, freq)

            if self.hasMeters(freq):
                csv.parseTSOutputs(state, self.Meters[int(freq)].getJSON(True), self.outputVariables, freq)
                mtr_csv.parseTSOutputs(state, self.Meters[int(freq)].getJSON(), self.outputVariables, freq)

        for timeStepType in [1, 0]:
            if self.hasDetailedTSData(timeStepType):
                csv.parseTSOutputs(state, self.detailedTSData[int(timeStepType)].getJSON(), self.outputVariables, 0)

        csv.writeOutput(state, self.outputVariables, state.files.csv, state.files.outputControl.csv, self.rewriteTimestamp)
        if self.hasMeterData():
            mtr_csv.writeOutput(state, self.outputVariables, state.files.mtr_csv, state.files.outputControl.csv, self.rewriteTimestamp)

    fn writeTimeSeriesReports(inout self, jsonOutputFilePaths):
        for timeStepType in [1, 0]:
            if self.hasDetailedTSData(timeStepType):
                self.detailedTSData[int(timeStepType)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)

        for freq in [1, 2, 3, 4, 5, 6]:
            if self.hasFreqTSData(freq):
                self.freqTSData[int(freq)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)

    fn writeReport(inout self, jsonOutputFilePaths):
        var root = Dict[String, Dict[String, String]]()
        root["SimulationResults"] = Dict[String, String]()
        root["SimulationResults"]["Simulation"] = self.SimulationInformation.getJSON()

        var outputVars = Dict[String, List[Dict[String, String]]]()
        var timeStepStrings = InlineArray[StringLiteral, 2]("Detailed-Zone", "Detailed-HVAC")
        for timeStep in [1, 0]:
            if self.hasDetailedTSData(timeStep):
                outputVars[String(timeStepStrings[int(timeStep)])] = self.detailedTSData[int(timeStep)].getVariablesJSON()

        var freqStrings = InlineArray[StringLiteral, 7]("Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly")
        for freq in [6, 5, 4, 3, 2, 1]:
            if self.hasFreqTSData(freq):
                outputVars[String(freqStrings[int(freq)])] = self.freqTSData[int(freq)].getVariablesJSON()

        var dict = Dict[String, String]()
        dict["Description"] = "Dictionary containing output variables that may be requested"
        var dict_list = Dict[String, List[String]]()
        dict_list["Variables"] = self.RDD
        outputVars["OutputDictionary"] = dict_list

        var meterVars = Dict[String, List[Dict[String, String]]]()
        var meterData = Dict[String, Dict[String, List]]()
        for freq in [6, 5, 4, 3, 2, 1]:
            if self.hasMeters(freq):
                meterVars[String(freqStrings[int(freq)])] = self.Meters[int(freq)].getVariablesJSON()
                meterData[String(freqStrings[int(freq)])] = self.Meters[int(freq)].getJSON()

        var meter_dict = Dict[String, String]()
        meter_dict["Description"] = "Dictionary containing meter variables that may be requested"
        var meter_dict_list = Dict[String, List[String]]()
        meter_dict_list["Meters"] = self.MDD
        meterVars["MeterDictionary"] = meter_dict_list

        root["OutputVariables"] = outputVars
        root["MeterVariables"] = meterVars
        root["MeterData"] = meterData
        root["TabularReports"] = self.TabularReportsCollection.getJSON()

        if self.outputJSON:
            fileSystem_writeFile("JSON", jsonOutputFilePaths.outputJsonFilePath, root)
        if self.outputCBOR:
            fileSystem_writeFile("CBOR", jsonOutputFilePaths.outputCborFilePath, root)
        if self.outputMsgPack:
            fileSystem_writeFile("MsgPack", jsonOutputFilePaths.outputMsgPackFilePath, root)

    fn addReportVariable(inout self, keyedValue: String, variableName: String, units: String, freq: Int):
        var var_str = String.format_string("{}:{} [{}]({})", keyedValue, variableName, units, reportFreqNames[int(freq)])
        self.outputVariables.append(var_str)

    fn addReportMeter(inout self, meter: String, units: String, freq: Int):
        var meter_str = String.format_string("{} [{}]({})", meter, units, reportFreqNames[int(freq)])
        self.outputVariables.append(meter_str)

    fn hasDetailedTSData(self, timeStepType: Int) -> Bool:
        return self.detailedTSData[int(timeStepType)].dataFrameEnabled()

    fn hasFreqTSData(self, freq: Int) -> Bool:
        return self.freqTSData[int(freq)].dataFrameEnabled()

    fn hasMeters(self, freq: Int) -> Bool:
        return self.Meters[int(freq)].dataFrameEnabled()

    fn hasMeterData(self) -> Bool:
        return (self.hasMeters(1) or self.hasMeters(2) or self.hasMeters(3) or
                self.hasMeters(4) or self.hasMeters(5) or self.hasMeters(6))

    fn hasTSData(self, freq: Int, timeStepType: Int = 2) -> Bool:
        debug_assert(freq != 7 and (freq != 0 or timeStepType != 2))
        if freq == 0:
            return self.detailedTSData[int(timeStepType)].dataFrameEnabled()
        else:
            return self.freqTSData[int(freq)].dataFrameEnabled()

    fn hasAnyTSData(self) -> Bool:
        for iTimeStep in range(2):
            if self.detailedTSData[iTimeStep].dataFrameEnabled():
                return True
        for iFreq in range(1, 7):
            if self.freqTSData[iFreq].dataFrameEnabled():
                return True
        return False

    fn hasOutputData(self) -> Bool:
        return self.hasAnyTSData() or self.hasMeterData()


struct ResultsFrameworkData:
    var resultsFramework: ResultsFramework

    fn __init__(inout self):
        self.resultsFramework = ResultsFramework()

    fn init_constant_state(inout self, state):
        pass

    fn init_state(inout self, state):
        pass

    fn clear_state(inout self):
        for iFreq in range(1, 7):
            var meters = self.resultsFramework.Meters[iFreq]
            meters.setDataFrameEnabled(False)
            meters.setVariablesScanned(False)


fn fileSystem_writeFile(file_type: String, path: String, data):
    pass


fn printFormatOutput(outputFile, text: String):
    pass


fn util_SameString(a: String, b: String) -> Bool:
    return a.lower() == b.lower()


fn showFatalError(state, msg: String):
    print(msg)


fn outputReportTabular_SetUnitsStyleFromString(s: String) -> Int:
    return 0


fn getYesNoValue(s: String) -> Int:
    return 0


var booleanSwitch_Yes = 1
var constant_unitNames = InlineArray[StringLiteral, 100]()
var reportFreqNames = InlineArray[StringLiteral, 7]("Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly")
