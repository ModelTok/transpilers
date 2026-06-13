from DataGlobals import *
from EnergyPlus import *
from OutputProcessor import *
from Data.BaseData import *
from .Data.EnergyPlusData import *  // for EnergyPlusData struct
from DataStringGlobals import *
from Formatters import *
from GlobalNames import *
from .InputProcessing.InputProcessor import *
from OutputReportTabular import *
from UtilityRoutines import *
from json import json  // assume a json module exists in project (nlohmann::json equivalent)

module EnergyPlus.ResultsFramework:

    using json as json

    def trim(s: StringSlice) -> String:
        if s.empty():
            return String{}
        var first = s.find_first_not_of(' ')
        var last = s.find_last_not_of(' ')
        if first == StringSlice.npos or last == StringSlice.npos:
            return String{}
        return String(s.substr(first, last - first + 1))

    struct BaseResultObject:

    struct SimInfo(BaseResultObject):
        var ProgramVersion: String = ""
        var SimulationEnvironment: String = ""
        var InputModelURI: String = ""
        var StartDateTimeStamp: String = ""
        var RunTime: String = ""
        var NumWarningsDuringWarmup: String = ""
        var NumSevereDuringWarmup: String = ""
        var NumWarningsDuringSizing: String = ""
        var NumSevereDuringSizing: String = ""
        var NumWarnings: String = ""
        var NumSevere: String = ""

        def setProgramVersion(self, programVersion: String):
            self.ProgramVersion = programVersion

        def getProgramVersion(self) -> String:
            return self.ProgramVersion

        def setSimulationEnvironment(self, simulationEnvironment: String):
            self.SimulationEnvironment = simulationEnvironment

        def setInputModelURI(self, inputModelURI: String):
            self.InputModelURI = inputModelURI

        def setStartDateTimeStamp(self, startDateTimeStamp: String):
            self.StartDateTimeStamp = startDateTimeStamp

        def setRunTime(self, elapsedTime: String):
            self.RunTime = elapsedTime

        def setNumErrorsWarmup(self, numWarningsDuringWarmup: String, numSevereDuringWarmup: String):
            self.NumWarningsDuringWarmup = numWarningsDuringWarmup
            self.NumSevereDuringWarmup = numSevereDuringWarmup

        def setNumErrorsSizing(self, numWarningsDuringSizing: String, numSevereDuringSizing: String):
            self.NumWarningsDuringSizing = numWarningsDuringSizing
            self.NumSevereDuringSizing = numSevereDuringSizing

        def setNumErrorsSummary(self, numWarnings: String, numSevere: String):
            self.NumWarnings = numWarnings
            self.NumSevere = numSevere

        def getJSON(self) -> json:
            var root = json({
                "ProgramVersion": self.ProgramVersion,
                "SimulationEnvironment": self.SimulationEnvironment,
                "InputModelURI": self.InputModelURI,
                "StartDateTimeStamp": self.StartDateTimeStamp,
                "RunTime": self.RunTime,
                "ErrorSummary": json({
                    "NumWarnings": self.NumWarnings, "NumSevere": self.NumSevere
                }),
                "ErrorSummaryWarmup": json({
                    "NumWarnings": self.NumWarningsDuringWarmup, "NumSevere": self.NumSevereDuringWarmup
                }),
                "ErrorSummarySizing": json({
                    "NumWarnings": self.NumWarningsDuringSizing, "NumSevere": self.NumSevereDuringSizing
                })
            })
            return root

    struct Variable(BaseResultObject):
        var m_varName: String = ""
        var m_reportFreq: ReportFreq = ReportFreq.EachCall
        var m_timeStepType: TimeStepType = TimeStepType.Zone
        var m_rptID: Int = -1
        var m_units: Units = Units.none
        var m_customUnits: String = ""
        var m_values: List[Float64] = List[Float64]()

        def __init__(self, VarName: String, reportFrequency: ReportFreq, timeStepType: TimeStepType, ReportID: Int, units: Units):
            self.m_varName = VarName
            self.m_reportFreq = reportFrequency
            self.m_timeStepType = timeStepType
            self.m_rptID = ReportID
            self.m_units = units

        def __init__(self, VarName: String, reportFrequency: ReportFreq, timeStepType: TimeStepType, ReportID: Int, units: Units, customUnits: String):
            self.m_varName = VarName
            self.m_reportFreq = reportFrequency
            self.m_timeStepType = timeStepType
            self.m_rptID = ReportID
            self.m_units = units
            self.m_customUnits = customUnits

        def variableName(self) -> String:
            return self.m_varName

        def setVariableName(self, VarName: String):
            self.m_varName = VarName

        def sReportFrequency(self) -> String:
            var reportFreqStrings: List[StringSlice] = ["Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly"]
            var timeStepTypeStrings: List[StringSlice] = ["Detailed - Zone", "Detailed - HVAC"]
            if self.m_reportFreq == ReportFreq.EachCall:
                return String(timeStepTypeStrings[Int(self.m_timeStepType)])
            else:
                return String(reportFreqStrings[Int(self.m_reportFreq)])

        def iReportFrequency(self) -> ReportFreq:
            return self.m_reportFreq

        def setReportFrequency(self, reportFrequency: ReportFreq):
            self.m_reportFreq = reportFrequency

        def timeStepType(self) -> TimeStepType:
            return self.m_timeStepType

        def setTimeStepType(self, timeStepType: TimeStepType):
            self.m_timeStepType = timeStepType

        def reportID(self) -> Int:
            return self.m_rptID

        def setReportID(self, Id: Int):
            self.m_rptID = Id

        def units(self) -> Units:
            return self.m_units

        def setUnits(self, units: Units):
            self.m_units = units

        def customUnits(self) -> String:
            return self.m_customUnits

        def setCustomUnits(self, customUnits: String):
            self.m_customUnits = customUnits

        def pushValue(self, val: Float64):
            self.m_values.append(val)

        def value(self, index: Int) -> Float64:
            return self.m_values[index]

        def numValues(self) -> Int:
            return len(self.m_values)

        def getJSON(self) -> json:
            var root: json
            if self.m_customUnits.empty():
                root = json({"Name": self.m_varName, "Units": unitNames[Int(self.m_units)], "Frequency": self.sReportFrequency()})
            else:
                root = json({"Name": self.m_varName, "Units": self.m_customUnits, "Frequency": self.sReportFrequency()})
            return root

    struct OutputVariable(Variable):
        def __init__(self, VarName: String, reportFrequency: ReportFreq, timeStepType: TimeStepType, ReportID: Int, units: Units):
            super().__init__(VarName, reportFrequency, timeStepType, ReportID, units)

        def __init__(self, VarName: String, reportFrequency: ReportFreq, timeStepType: TimeStepType, ReportID: Int, units: Units, customUnits: String):
            super().__init__(VarName, reportFrequency, timeStepType, ReportID, units, customUnits)

    struct MeterVariable(Variable):
        var acc: Bool = false
        var meter_only: Bool = true

        def __init__(self, VarName: String, reportFrequency: ReportFreq, ReportID: Int, units: Units, MeterOnly: Bool, Accumulative: Bool = False):
            super().__init__(VarName, reportFrequency, TimeStepType.Zone, ReportID, units)
            self.acc = Accumulative
            self.meter_only = MeterOnly

        def accumulative(self) -> Bool:
            return self.acc

        def setAccumulative(self, state: Bool):
            self.acc = state

        def meterOnly(self) -> Bool:
            return self.meter_only

        def setMeterOnly(self, state: Bool):
            self.meter_only = state

        def getJSON(self) -> json:
            var root = super().getJSON()
            if self.acc:
                root["Cumulative"] = true
            return root

    struct DataFrame(BaseResultObject):
        var DataFrameEnabled: Bool = false
        var VariablesScanned: Bool = false
        var lastHour: Int = 0
        var lastMinute: Int = 0
        var ReportFrequency: String = ""
        var TS: List[String] = List[String]()
        var variableMap: Dict[Int, Variable] = Dict[Int, Variable]()
        var lastVarID: Int = -1
        var iso8601: Bool = false
        var beginningOfInterval: Bool = false

        def __init__(self, ReportFreq: String):
            self.ReportFrequency = ReportFreq

        def addVariable(self, var: Variable):
            self.lastVarID = var.reportID()
            self.variableMap[self.lastVarID] = var

        def lastVariable(self) -> Variable:
            return self.variableMap[self.lastVarID]

        def newRow(self, month: Int, dayOfMonth: Int, hourOfDay: Int, curMin: Int, calendarYear: Int):
            if curMin > 0:
                hourOfDay -= 1
            if curMin == 60:
                curMin = 0
                hourOfDay += 1
            if self.beginningOfInterval:
                if hourOfDay == 24:
                    hourOfDay = 0
                # swap hourOfDay with lastHour, curMin with lastMinute
                var tmp_hour = hourOfDay
                hourOfDay = self.lastHour
                self.lastHour = tmp_hour
                var tmp_min = curMin
                curMin = self.lastMinute
                self.lastMinute = tmp_min
            if self.iso8601:
                self.TS.append("{:04d}-{:02d}-{:02d}T{:02d}:{:02d}:00".format(calendarYear, month, dayOfMonth, hourOfDay, curMin))
            else:
                self.TS.append("{:02d}/{:02d} {:02d}:{:02d}:00".format(month, dayOfMonth, hourOfDay, curMin))

        def dataFrameEnabled(self) -> Bool:
            return self.DataFrameEnabled

        def setDataFrameEnabled(self, state: Bool):
            self.DataFrameEnabled = state

        def setVariablesScanned(self, state: Bool):
            self.VariablesScanned = state

        def variablesScanned(self) -> Bool:
            return self.VariablesScanned

        def pushVariableValue(self, reportID: Int, value: Float64):
            self.variableMap[reportID].pushValue(value)

        def getVariablesJSON(self) -> json:
            var arr = json.array()
            for varMap in self.variableMap.items():
                arr.append(varMap[1].getJSON())
            return arr

        def getJSON(self) -> json:
            var root: json
            var cols = json.array()
            var rows = json.array()
            for varMap in self.variableMap.items():
                var v = varMap[1]
                if v.customUnits().empty():
                    cols.append(json({"Variable": v.variableName(), "Units": unitNames[Int(v.units())]}))
                else:
                    cols.append(json({"Variable": v.variableName(), "Units": v.customUnits()}))
            var vals = json.array()
            for row in range(len(self.TS)):
                vals = json.array()
                for varMap in self.variableMap.items():
                    var v = varMap[1]
                    if row < v.numValues():
                        vals.append(v.value(row))
                    else:
                        vals.append(None)
                rows.append(json({self.TS[row]: vals}))
            root = json({"ReportFrequency": self.ReportFrequency, "Cols": cols, "Rows": rows})
            return root

        def writeReport(self, jsonOutputFilePaths: JsonOutputFilePaths, outputJSON: Bool, outputCBOR: Bool, outputMsgPack: Bool):
            var root = self.getJSON()
            if self.ReportFrequency == "Detailed-HVAC":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputTSHvacJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputTSHvacCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputTSHvacMsgPackFilePath, root)
            elif self.ReportFrequency == "Detailed-Zone":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputTSZoneJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputTSZoneCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputTSZoneMsgPackFilePath, root)
            elif self.ReportFrequency == "TimeStep":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputTSJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputTSCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputTSMsgPackFilePath, root)
            elif self.ReportFrequency == "Daily":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputDYJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputDYCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputDYMsgPackFilePath, root)
            elif self.ReportFrequency == "Hourly":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputHRJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputHRCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputHRMsgPackFilePath, root)
            elif self.ReportFrequency == "Monthly":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputMNJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputMNCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputMNMsgPackFilePath, root)
            elif self.ReportFrequency == "RunPeriod":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputSMJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputSMCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputSMMsgPackFilePath, root)
            elif self.ReportFrequency == "Yearly":
                if outputJSON:
                    FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputYRJsonFilePath, root)
                if outputCBOR:
                    FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputYRCborFilePath, root)
                if outputMsgPack:
                    FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputYRMsgPackFilePath, root)

    struct MeterDataFrame(DataFrame):
        var meterMap: Dict[Int, MeterVariable] = Dict[Int, MeterVariable]()

        def addVariable(self, var: MeterVariable):
            self.lastVarID = var.reportID()
            self.meterMap[self.lastVarID] = var

        def pushVariableValue(self, reportID: Int, value: Float64):
            self.meterMap[reportID].pushValue(value)

        def getJSON(self, meterOnlyCheck: Bool = False) -> json:
            var root: json
            var cols = json.array()
            var rows = json.array()
            for varMap in self.meterMap.items():
                if not (meterOnlyCheck and varMap[1].meterOnly()):
                    cols.append(json({"Variable": varMap[1].variableName(), "Units": unitNames[Int(varMap[1].units())]}))
            if cols.empty():
                return root
            var vals = json.array()
            for row in range(len(self.TS)):
                vals = json.array()
                for varMap in self.meterMap.items():
                    if not (meterOnlyCheck and varMap[1].meterOnly()):
                        if row < varMap[1].numValues():
                            vals.append(varMap[1].value(row))
                        else:
                            vals.append(None)
                rows.append(json({self.TS[row]: vals}))
            root = json({"ReportFrequency": self.ReportFrequency, "Cols": cols, "Rows": rows})
            return root

    struct Table(BaseResultObject):
        var TableName: String = ""
        var FootnoteText: String = ""
        var ColHeaders: List[String] = List[String]()
        var RowHeaders: List[String] = List[String]()
        var Data: List[List[String]] = List[List[String]]()

        def __init__(self, body: Array2D_string, rowLabels: Array1D_string, columnLabels: Array1D_string, tableName: String, footnoteText: String):
            var sizeColumnLabels = len(columnLabels)
            var sizeRowLabels = len(rowLabels)
            self.TableName = tableName
            self.FootnoteText = footnoteText
            # body is assumed to be a list of lists (2D array)
            for iCol in range(sizeColumnLabels):
                self.ColHeaders.append(columnLabels[iCol])
                var col: List[String] = List[String]()
                for iRow in range(sizeRowLabels):
                    if iCol == 0:
                        self.RowHeaders.append(rowLabels[iRow])
                    col.append(trim(body[iRow][iCol]))
                self.Data.append(col)

        def getJSON(self) -> json:
            var root: json
            var cols = json.array()
            var rows = json()
            for ColHeader in self.ColHeaders:
                cols.append(ColHeader)
            for row in range(len(self.RowHeaders)):
                var rowvec = json.array()
                for col in range(len(self.ColHeaders)):
                    rowvec.append(self.Data[col][row])
                rows[self.RowHeaders[row]] = rowvec
            root = json({"TableName": self.TableName, "Cols": cols, "Rows": rows})
            if not self.FootnoteText.empty():
                root["Footnote"] = self.FootnoteText
            return root

    struct Report(BaseResultObject):
        var ReportName: String = ""
        var ReportForString: String = ""
        var Tables: List[Table] = List[Table]()

        def getJSON(self) -> json:
            var root = json({"ReportName": self.ReportName, "For": self.ReportForString})
            var cols = json.array()
            for table in self.Tables:
                cols.append(table.getJSON())
            root["Tables"] = cols
            return root

    struct ReportsCollection(BaseResultObject):
        var reportsMap: Dict[String, Report] = Dict[String, Report]()
        var rpt: Report = Report()

        def addReportTable(self, body: Array2D_string, rowLabels: Array1D_string, columnLabels: Array1D_string, reportName: String, reportForString: String, tableName: String):
            self.addReportTable(body, rowLabels, columnLabels, reportName, reportForString, tableName, "")

        def addReportTable(self, body: Array2D_string, rowLabels: Array1D_string, columnLabels: Array1D_string, reportName: String, reportForString: String, tableName: String, footnoteText: String):
            var key = reportName + reportForString
            var tbl = Table(body, rowLabels, columnLabels, tableName, footnoteText)
            var search = self.reportsMap.get(key)
            if search is not None:
                search.Tables.append(tbl)
            else:
                var r: Report = Report()
                r.ReportName = reportName
                r.ReportForString = reportForString
                r.Tables.append(tbl)
                self.reportsMap[key] = r

        def getJSON(self) -> json:
            var root = json.array()
            for iter in self.reportsMap.items():
                root.append(iter[1].getJSON())
            return root

    struct CSVWriter(BaseResultObject):
        var s: List[Char] = [Char(0) for _ in range(129)]
        var smallestReportFreq: ReportFreq = ReportFreq.Year
        var outputs: Dict[String, List[String]] = Dict[String, List[String]]()
        var outputVariableIndices: List[Bool] = List[Bool]()

        def __init__(self):

        def __init__(self, num_output_variables: Int):
            self.outputVariableIndices = [False for _ in range(num_output_variables)]

        def convertToMonth(datetime: String) -> String:
            var months: Dict[String, String] = {
                "01": "January", "02": "February", "03": "March", "04": "April", "05": "May", "06": "June",
                "07": "July", "08": "August", "09": "September", "10": "October", "11": "November", "12": "December"
            }
            var month = datetime.substr(0, 2)
            var pos = datetime.find(' ')
            var time: String
            if pos != StringSlice.npos:
                time = datetime.substr(pos)
            assert time == " 24:00:00" or time == " 00:00:00"
            datetime = months[month]
            return datetime

        def updateReportFreq(self, reportingFrequency: ReportFreq):
            if reportingFrequency < self.smallestReportFreq:
                self.smallestReportFreq = reportingFrequency

        def parseTSOutputs(self, state: EnergyPlusData, data: json, outputVariables: List[String], reportingFrequency: ReportFreq):
            if data.empty():
                return
            self.updateReportFreq(reportingFrequency)
            var indices: List[Int] = List[Int]()
            var reportFrequency = data["ReportFrequency"].get[String]()
            if reportFrequency == "Detailed-HVAC" or reportFrequency == "Detailed-Zone":
                reportFrequency = "Each Call"
            var columns = data["Cols"]
            for column in columns:
                var search_string = "{0} [{1}]({2})".format(column["Variable"].get[String](), column["Units"].get[String](), reportFrequency)
                var found = outputVariables.find(search_string)
                if found == -1:
                    search_string = "{0} [{1}]({2})".format(column["Variable"].get[String](), column["Units"].get[String](), "Each Call")
                    found = outputVariables.find(search_string)
                if found == -1:
                    ShowFatalError(state, "Output variable ({0}) not found output variable list".format(search_string))
                self.outputVariableIndices[found] = True
                indices.append(found)
            var rows = data["Rows"]
            for row in rows:
                for el in row.items():
                    var found_key = self.outputs.get(el[0])
                    if found_key is None:
                        var output: List[String] = List[String]()
                        output.resize(len(outputVariables))
                        var i: Int = 0
                        for col in el[1]:
                            if col.is_null():
                                output[indices[i]] = ""
                            else:
                                var val = col.get[Float64]()
                                # dtoa equivalent using String conversion
                                var str_val = String(val)
                                self.s = str_val.data()  # not exactly same; keep buffer
                                output[indices[i]] = str_val
                            i += 1
                        self.outputs[el[0]] = output
                    else:
                        var i: Int = 0
                        for col in el[1]:
                            if col.is_null():
                                found_key[indices[i]] = ""
                            else:
                                var val = col.get[Float64]()
                                var str_val = String(val)
                                self.s = str_val.data()
                                found_key[indices[i]] = str_val
                            i += 1

        def writeOutput(self, state: EnergyPlusData, outputVariables: List[String], outputFile: InputOutputFile, outputControl: Bool, rewriteTimestamp: Bool):
            outputFile.ensure_open(state, "OpenOutputFiles", outputControl)
            print[FormatSyntax.FMT](outputFile, "{}", "Date/Time,")
            var sep: String = ""
            for it in outputVariables:
                if not self.outputVariableIndices[outputVariables.find(it)]:
                    continue
                print[FormatSyntax.FMT](outputFile, "{}{}", sep, it)
                if sep.empty():
                    sep = ","
            print[FormatSyntax.FMT](outputFile, "{}", '\n')
            for item in self.outputs.items():
                var datetime = item[0]
                if rewriteTimestamp:
                    if self.smallestReportFreq < ReportFreq.Month:
                        datetime = datetime.replace(datetime.find(' '), 1, "  ")
                    else:
                        convertToMonth(datetime)
                print[FormatSyntax.FMT](outputFile, " {},", datetime)
                # erase elements not in outputVariableIndices (reverse order)
                var idx = len(item[1]) - 1
                while idx >= 0:
                    if not self.outputVariableIndices[idx]:
                        item[1].pop(idx)
                    idx -= 1
                var last: Int = len(item[1]) - 1
                # find last non-empty
                var result = -1
                for i in range(len(item[1]) - 1, -1, -1):
                    if not item[1][i].empty():
                        result = i
                        break
                if result != -1:
                    last = result
                # print up to last
                for i in range(last):
                    print[FormatSyntax.FMT](outputFile, "{},", item[1][i])
                if last >= 0:
                    print[FormatSyntax.FMT](outputFile, "{}\n", item[1][last])
            outputFile.close()

    struct ResultsFramework(BaseResultObject):
        var tsEnabled: Bool = false
        var tsAndTabularEnabled: Bool = false
        var outputJSON: Bool = false
        var outputCBOR: Bool = false
        var outputMsgPack: Bool = false
        var rewriteTimestamp: Bool = True  # Convert monthly data timestamp to month name
        var outputVariables: List[String] = List[String]()
        var SimulationInformation: SimInfo = SimInfo()
        var MDD: List[String] = List[String]()
        var RDD: List[String] = List[String]()
        var TabularReportsCollection: ReportsCollection = ReportsCollection()
        var detailedTSData: List[DataFrame] = List[DataFrame](DataFrame("Detailed-Zone"), DataFrame("Detailed-HVAC"))
        var freqTSData: List[DataFrame] = List[DataFrame](
            DataFrame("Each Call"), DataFrame("TimeStep"), DataFrame("Hourly"), DataFrame("Daily"),
            DataFrame("Monthly"), DataFrame("RunPeriod"), DataFrame("Yearly")
        )
        var Meters: List[MeterDataFrame] = List[MeterDataFrame](
            MeterDataFrame("Each Call"), MeterDataFrame("TimeStep"), MeterDataFrame("Hourly"),
            MeterDataFrame("Daily"), MeterDataFrame("Monthly"), MeterDataFrame("RunPeriod"), MeterDataFrame("Yearly")
        )

        def setupOutputOptions(self, state: EnergyPlusData):
            if state.files.outputControl.csv:
                self.tsEnabled = True
                self.tsAndTabularEnabled = True
            if not state.files.outputControl.json:
                return
            var numberOfOutputSchemaObjects = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Output:JSON")
            if numberOfOutputSchemaObjects == 0:
                return
            # Array1D_string alphas(6)
            var alphas: List[String] = List[String]()
            alphas.resize(6)
            var numAlphas: Int
            var numbers: List[Float64] = List[Float64]()
            numbers.resize(2)
            var numNumbers: Int
            var status: Int
            state.dataInputProcessing.inputProcessor.getObjectItem(state, "Output:JSON", 1, alphas, numAlphas, numbers, numNumbers, status)
            if numAlphas > 0:
                var option = alphas[0]
                if Util.SameString(option, "TimeSeries"):
                    self.tsEnabled = True
                elif Util.SameString(option, "TimeSeriesAndTabular"):
                    self.tsEnabled = True
                    self.tsAndTabularEnabled = True
                self.outputJSON = True
                self.outputCBOR = False
                self.outputMsgPack = False
                if numAlphas >= 2:
                    self.outputJSON = Util.SameString(alphas[1], "Yes")
                if numAlphas >= 3:
                    self.outputCBOR = Util.SameString(alphas[2], "Yes")
                if numAlphas >= 4:
                    self.outputMsgPack = Util.SameString(alphas[3], "Yes")
                var ort = state.dataOutRptTab
                ort.unitsStyle_JSON = OutputReportTabular.SetUnitsStyleFromString(alphas[4])
                ort.formatReals_JSON = (getYesNoValue(alphas[5]) == BooleanSwitch.Yes)

        def timeSeriesEnabled(self) -> Bool:
            return self.tsEnabled

        def timeSeriesAndTabularEnabled(self) -> Bool:
            return self.tsAndTabularEnabled

        def JSONEnabled(self) -> Bool:
            return self.outputJSON

        def CBOREnabled(self) -> Bool:
            return self.outputCBOR

        def MsgPackEnabled(self) -> Bool:
            return self.outputMsgPack

        def setISO8601(self, value: Bool):
            self.rewriteTimestamp = not value
            for iTimeStep in range(Int(TimeStepType.Zone), Int(TimeStepType.Num)):
                self.detailedTSData[iTimeStep].iso8601 = value
            for iFreq in range(Int(ReportFreq.TimeStep), Int(ReportFreq.Num)):
                self.freqTSData[iFreq].iso8601 = value
                self.Meters[iFreq].iso8601 = value

        def setBeginningOfInterval(self, value: Bool):
            for iTimeStep in range(Int(TimeStepType.Num)):
                self.detailedTSData[iTimeStep].beginningOfInterval = value
            for iFreq in range(Int(ReportFreq.Num)):
                self.freqTSData[iFreq].beginningOfInterval = value
                self.Meters[iFreq].beginningOfInterval = value

        def initializeTSDataFrame(self, reportFrequency: ReportFreq, Variables: List[OutVar], timeStepType: TimeStepType = TimeStepType.Zone):
            for var in Variables:
                if var.Report and var.freq == reportFrequency:
                    var rfvar: Variable
                    if var.units == Units.customEMS:
                        rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units, var.unitNameCustomEMS)
                    else:
                        rfvar = Variable(var.keyColonName, reportFrequency, var.timeStepType, var.ReportID, var.units)
                    match reportFrequency:
                        case ReportFreq.EachCall:
                            if timeStepType == var.timeStepType:
                                self.detailedTSData[Int(timeStepType)].setDataFrameEnabled(True)
                                self.detailedTSData[Int(timeStepType)].addVariable(rfvar)
                        case ReportFreq.Hour | ReportFreq.TimeStep | ReportFreq.Day | ReportFreq.Month | ReportFreq.Simulation | ReportFreq.Year:
                            self.freqTSData[Int(reportFrequency)].setDataFrameEnabled(True)
                            self.freqTSData[Int(reportFrequency)].addVariable(rfvar)
                        case _:
                            assert False
            match reportFrequency:
                case ReportFreq.EachCall:
                    self.detailedTSData[Int(timeStepType)].setVariablesScanned(True)
                case ReportFreq.TimeStep | ReportFreq.Hour | ReportFreq.Day | ReportFreq.Month | ReportFreq.Simulation | ReportFreq.Year:
                    self.detailedTSData[Int(timeStepType)].setVariablesScanned(True)
                case _:
                    assert False

        def initializeMeters(self, meters: List[Meter], freq: ReportFreq):
            match freq:
                case ReportFreq.EachCall:

                case ReportFreq.TimeStep | ReportFreq.Hour | ReportFreq.Day | ReportFreq.Month | ReportFreq.Simulation | ReportFreq.Year:
                    for meter in meters:
                        var period = meter.periods[Int(freq)]
                        if period.Rpt or period.RptFO:
                            self.Meters[Int(freq)].addVariable(MeterVariable(meter.Name, freq, period.RptNum, meter.units, period.RptFO))
                            self.Meters[Int(freq)].setDataFrameEnabled(True)
                        if period.accRpt or period.accRptFO:
                            self.Meters[Int(freq)].addVariable(MeterVariable(meter.Name, freq, period.accRptNum, meter.units, period.accRptFO))
                            self.Meters[Int(freq)].setDataFrameEnabled(True)
                case _:
                    assert False
            match freq:
                case ReportFreq.EachCall:

                case ReportFreq.TimeStep | ReportFreq.Hour | ReportFreq.Day | ReportFreq.Month | ReportFreq.Simulation | ReportFreq.Year:
                    self.Meters[Int(freq)].setVariablesScanned(True)
                case _:
                    assert False

        def writeOutputs(self, state: EnergyPlusData):
            if state.files.outputControl.csv:
                self.writeCSVOutput(state)
            if self.timeSeriesEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
                self.writeTimeSeriesReports(state.files.json)
            if self.timeSeriesAndTabularEnabled() and (self.outputJSON or self.outputCBOR or self.outputMsgPack):
                self.writeReport(state.files.json)

        def writeCSVOutput(self, state: EnergyPlusData):
            using OutputProcessor.ReportFreq
            if not self.hasOutputData():
                return
            var csv = CSVWriter(len(self.outputVariables))
            var mtr_csv = CSVWriter(len(self.outputVariables))
            for freq in [ReportFreq.Year, ReportFreq.Simulation, ReportFreq.Month, ReportFreq.Day, ReportFreq.Hour, ReportFreq.TimeStep]:
                if self.hasTSData(freq):
                    csv.parseTSOutputs(state, self.freqTSData[Int(freq)].getJSON(), self.outputVariables, freq)
                if self.hasMeters(freq):
                    csv.parseTSOutputs(state, self.Meters[Int(freq)].getJSON(True), self.outputVariables, freq)
                    mtr_csv.parseTSOutputs(state, self.Meters[Int(freq)].getJSON(), self.outputVariables, freq)
            for timeStepType in [TimeStepType.System, TimeStepType.Zone]:
                if self.hasDetailedTSData(timeStepType):
                    csv.parseTSOutputs(state, self.detailedTSData[Int(timeStepType)].getJSON(), self.outputVariables, ReportFreq.EachCall)
            csv.writeOutput(state, self.outputVariables, state.files.csv, state.files.outputControl.csv, self.rewriteTimestamp)
            if self.hasMeterData():
                mtr_csv.writeOutput(state, self.outputVariables, state.files.mtr_csv, state.files.outputControl.csv, self.rewriteTimestamp)

        def writeTimeSeriesReports(self, jsonOutputFilePaths: JsonOutputFilePaths):
            for timeStepType in [TimeStepType.Zone, TimeStepType.System]:
                if self.hasDetailedTSData(timeStepType):
                    self.detailedTSData[Int(timeStepType)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)
            for freq in [ReportFreq.TimeStep, ReportFreq.Hour, ReportFreq.Day, ReportFreq.Month, ReportFreq.Simulation, ReportFreq.Year]:
                if self.hasFreqTSData(freq):
                    self.freqTSData[Int(freq)].writeReport(jsonOutputFilePaths, self.outputJSON, self.outputCBOR, self.outputMsgPack)

        def writeReport(self, jsonOutputFilePaths: JsonOutputFilePaths):
            var root: json
            var outputVars: json
            var meterVars: json
            var meterData: json
            root = json({"SimulationResults": json({"Simulation": self.SimulationInformation.getJSON()})})
            var timeStepStrings: List[String] = ["Detailed-Zone", "Detailed-HVAC"]
            for timeStep in [TimeStepType.Zone, TimeStepType.System]:
                if self.hasDetailedTSData(timeStep):
                    outputVars[timeStepStrings[Int(timeStep)]] = self.detailedTSData[Int(timeStep)].getVariablesJSON()
            var freqStrings: List[String] = ["Detailed", "TimeStep", "Hourly", "Daily", "Monthly", "RunPeriod", "Yearly"]
            for freq in [ReportFreq.Year, ReportFreq.Simulation, ReportFreq.Month, ReportFreq.Day, ReportFreq.Hour, ReportFreq.TimeStep]:
                if self.hasFreqTSData(freq):
                    outputVars[freqStrings[Int(freq)]] = self.freqTSData[Int(freq)].getVariablesJSON()
            outputVars["OutputDictionary"] = json({"Description": "Dictionary containing output variables that may be requested", "Variables": self.RDD})
            for freq in [ReportFreq.Year, ReportFreq.Simulation, ReportFreq.Month, ReportFreq.Day, ReportFreq.Hour, ReportFreq.TimeStep]:
                if self.hasMeters(freq):
                    meterVars[freqStrings[Int(freq)]] = self.Meters[Int(freq)].getVariablesJSON()
                    meterData[freqStrings[Int(freq)]] = self.Meters[Int(freq)].getJSON()
            meterVars["MeterDictionary"] = json({"Description": "Dictionary containing meter variables that may be requested", "Meters": self.MDD})
            root["OutputVariables"] = outputVars
            root["MeterVariables"] = meterVars
            root["MeterData"] = meterData
            root["TabularReports"] = self.TabularReportsCollection.getJSON()
            if self.outputJSON:
                FileSystem.writeFile[FileSystem.FileTypes.JSON](jsonOutputFilePaths.outputJsonFilePath, root)
            if self.outputCBOR:
                FileSystem.writeFile[FileSystem.FileTypes.CBOR](jsonOutputFilePaths.outputCborFilePath, root)
            if self.outputMsgPack:
                FileSystem.writeFile[FileSystem.FileTypes.MsgPack](jsonOutputFilePaths.outputMsgPackFilePath, root)

        def addReportVariable(self, keyedValue: StringSlice, variableName: StringSlice, units: StringSlice, freq: ReportFreq):
            self.outputVariables.append("{0}:{1} [{2}]({3})".format(keyedValue, variableName, units, reportFreqNames[Int(freq)]))

        def addReportMeter(self, meter: String, units: StringSlice, freq: ReportFreq):
            self.outputVariables.append("{0} [{1}]({2})".format(meter, units, reportFreqNames[Int(freq)]))

        # Helper methods (in original header)
        def hasDetailedTSData(self, timeStepType: TimeStepType) -> Bool:
            return self.detailedTSData[Int(timeStepType)].dataFrameEnabled()

        def hasFreqTSData(self, freq: ReportFreq) -> Bool:
            return self.freqTSData[Int(freq)].dataFrameEnabled()

        def hasMeters(self, freq: ReportFreq) -> Bool:
            return self.Meters[Int(freq)].dataFrameEnabled()

        def hasMeterData(self) -> Bool:
            return self.hasMeters(ReportFreq.TimeStep) or self.hasMeters(ReportFreq.Hour) or self.hasMeters(ReportFreq.Day) or self.hasMeters(ReportFreq.Month) or self.hasMeters(ReportFreq.Simulation) or self.hasMeters(ReportFreq.Year)

        def hasTSData(self, freq: ReportFreq, timeStepType: TimeStepType = TimeStepType.Invalid) -> Bool:
            assert freq != ReportFreq.Invalid and (freq != ReportFreq.EachCall or timeStepType != TimeStepType.Invalid)
            if freq == ReportFreq.EachCall:
                return self.detailedTSData[Int(timeStepType)].dataFrameEnabled()
            else:
                return self.freqTSData[Int(freq)].dataFrameEnabled()

        def hasAnyTSData(self) -> Bool:
            for iTimeStep in range(Int(TimeStepType.Num)):
                if self.detailedTSData[iTimeStep].dataFrameEnabled():
                    return True
            for iFreq in range(Int(ReportFreq.TimeStep), Int(ReportFreq.Num)):
                if self.freqTSData[iFreq].dataFrameEnabled():
                    return True
            return False

        def hasOutputData(self) -> Bool:
            return self.hasAnyTSData() or self.hasMeterData()

# Data structure for ResultsFrameworkData (from header)
struct ResultsFrameworkData(BaseGlobalStruct):
    var resultsFramework: ResultsFramework = ResultsFramework()

    def init_constant_state(self, state: EnergyPlusData):

    def init_state(self, state: EnergyPlusData):

    def clear_state(self):
        using OutputProcessor.ReportFreq
        for iFreq in range(Int(ReportFreq.TimeStep), Int(ReportFreq.Num)):
            var meters = self.resultsFramework.Meters[iFreq]
            meters.setDataFrameEnabled(False)
            meters.setVariablesScanned(False)
