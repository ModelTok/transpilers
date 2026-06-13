from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.IOFiles import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.SizingAnalysisObjects import *
from EnergyPlus.UtilityRoutines import *
from EnergyPlus.WeatherManager import *
from testing import *

struct SizingAnalysisObjectsTest:
    var state: EnergyPlusData
    var lowLogVal: Float64
    var midLogVal: Float64
    var hiLogVal: Float64
    var LogVal: Float64
    var averagingWindow: Int
    var logIndex: Int
    var sizingLoggerFrameObj: SizingLoggerFramework

    def SetUp(inout self):
        EnergyPlusFixture.SetUp()
        self.state.files.eio.open_as_stringstream()
        self.lowLogVal = 50.0
        self.midLogVal = 75.0
        self.hiLogVal = 100.0
        self.state.dataGlobal.TimeStepsInHour = 4
        self.state.dataGlobal.TimeStepZone = 0.25
        self.state.dataWeather.NumOfEnvrn = 2
        self.state.dataWeather.Environment = List[type(self.state.dataWeather.Environment[0])](self.state.dataWeather.NumOfEnvrn)
        self.state.dataWeather.Environment[0].KindOfEnvrn = Constant.KindOfSim.DesignDay
        self.state.dataWeather.Environment[0].DesignDayNum = 1
        self.state.dataWeather.Environment[1].KindOfEnvrn = Constant.KindOfSim.DesignDay
        self.state.dataWeather.Environment[1].DesignDayNum = 2
        self.averagingWindow = 1
        self.logIndex = self.sizingLoggerFrameObj.SetupVariableSizingLog(self.state, self.LogVal, self.averagingWindow)
        self.state.dataWeather.NumOfEnvrn = 4
        self.state.dataWeather.Environment = List[type(self.state.dataWeather.Environment[0])](self.state.dataWeather.NumOfEnvrn)
        self.state.dataWeather.Environment[2].KindOfEnvrn = Constant.KindOfSim.HVACSizeDesignDay
        self.state.dataWeather.Environment[2].DesignDayNum = 1
        self.state.dataWeather.Environment[2].SeedEnvrnNum = 1
        self.state.dataWeather.Environment[3].KindOfEnvrn = Constant.KindOfSim.HVACSizeDesignDay
        self.state.dataWeather.Environment[3].DesignDayNum = 2
        self.state.dataWeather.Environment[3].SeedEnvrnNum = 2
        OutputProcessor.SetupTimePointers(self.state, OutputProcessor.TimeStepType.Zone, self.state.dataGlobal.TimeStepZone)
        OutputProcessor.SetupTimePointers(self.state, OutputProcessor.TimeStepType.System, self.state.dataHVACGlobal.TimeStepSys)
        self.state.dataSize.PlantSizData = List[type(self.state.dataSize.PlantSizData[0])](1)
        self.state.dataSize.PlantSizData[0].SizingFactorOption = NoSizingFactorMode
        self.state.dataSize.PlantSizData[0].DesVolFlowRate = 0.002
        self.state.dataSize.PlantSizData[0].DeltaT = 10
        self.state.dataPlnt.TotNumLoops = 1
        self.state.dataPlnt.PlantLoop = List[type(self.state.dataPlnt.PlantLoop[0])](self.state.dataPlnt.TotNumLoops)
        self.state.dataPlnt.PlantLoop[0].Name = "Test Plant Loop 1"
        self.state.dataPlnt.PlantLoop[0].MaxVolFlowRateWasAutoSized = true
        self.state.dataPlnt.PlantLoop[0].MaxVolFlowRate = 0.002
        self.state.dataPlnt.PlantLoop[0].MaxMassFlowRate = 2.0
        self.state.dataPlnt.PlantLoop[0].VolumeWasAutoSized = true

    def TearDown(inout self):
        EnergyPlusFixture.TearDown()

@test
def testZoneUpdateInLoggerFramework():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    ShowMessage(fix.state, "Begin Test: SizingAnalysisObjectsTest, testZoneUpdateInLoggerFramework")
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    fix.state.dataGlobal.DayOfSim = 1
    fix.state.dataGlobal.HourOfDay = 1
    fix.state.dataWeather.Envrn = 3
    fix.state.dataWeather.Environment[fix.state.dataWeather.Envrn - 1].DesignDayNum = 1
    fix.sizingLoggerFrameObj.SetupSizingLogsNewEnvironment(fix.state)
    fix.state.dataGlobal.TimeStep = 1
    fix.LogVal = fix.lowLogVal
    fix.sizingLoggerFrameObj.UpdateSizingLogValuesZoneStep(fix.state)
    expect_equal(fix.lowLogVal, fix.sizingLoggerFrameObj.logObjs[fix.logIndex].ztStepObj[0].logDataValue)
    fix.state.dataGlobal.HourOfDay = 24
    fix.state.dataGlobal.TimeStep = 4
    fix.LogVal = fix.hiLogVal
    fix.sizingLoggerFrameObj.UpdateSizingLogValuesZoneStep(fix.state)
    expect_equal(fix.hiLogVal, fix.sizingLoggerFrameObj.logObjs[fix.logIndex].ztStepObj[95].logDataValue)
    fix.state.dataGlobal.HourOfDay = 1
    fix.state.dataGlobal.TimeStep = 1
    fix.state.dataWeather.Envrn = 4
    fix.state.dataWeather.Environment[fix.state.dataWeather.Envrn - 1].DesignDayNum = 2
    fix.sizingLoggerFrameObj.SetupSizingLogsNewEnvironment(fix.state)
    fix.LogVal = fix.midLogVal
    fix.sizingLoggerFrameObj.UpdateSizingLogValuesZoneStep(fix.state)
    expect_equal(fix.midLogVal, fix.sizingLoggerFrameObj.logObjs[fix.logIndex].ztStepObj[96].logDataValue)
    fix.TearDown()

@test
def BasicLogging4stepsPerHour():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    ShowMessage(fix.state, "Begin Test: SizingAnalysisObjectsTest, BasicLogging4stepsPerHour")
    var TestLogObj = SizingLog(fix.LogVal)
    TestLogObj.NumOfEnvironmentsInLogSet = 2
    TestLogObj.NumOfDesignDaysInLogSet = 2
    TestLogObj.NumberOfSizingPeriodsInLogSet = 0
    TestLogObj.NumOfStepsInLogSet = 8
    TestLogObj.ztStepCountByEnvrnMap[1] = 4
    TestLogObj.ztStepCountByEnvrnMap[2] = 4
    TestLogObj.envrnStartZtStepIndexMap[1] = 0
    TestLogObj.envrnStartZtStepIndexMap[2] = 4
    TestLogObj.newEnvrnToSeedEnvrnMap[3] = 1
    TestLogObj.newEnvrnToSeedEnvrnMap[4] = 2
    TestLogObj.ztStepObj = List[type(TestLogObj.ztStepObj[0])](TestLogObj.NumOfStepsInLogSet)
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    var Envrn: Int = 3
    fix.state.dataGlobal.DayOfSim = 1
    var HourofDay: Int = 1
    var timeStp: Int = 1
    var timeStepDuration: Float64 = 0.25
    var numTimeStepsInHour: Int = 4
    fix.LogVal = fix.lowLogVal
    var tmpztStepStamp1 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    TestLogObj.FillZoneStep(tmpztStepStamp1)
    timeStp = 2
    fix.LogVal = fix.midLogVal
    var tmpztStepStamp2 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    TestLogObj.FillZoneStep(tmpztStepStamp2)
    timeStp = 3
    fix.LogVal = fix.midLogVal
    var tmpztStepStamp3 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    TestLogObj.FillZoneStep(tmpztStepStamp3)
    timeStp = 4
    fix.LogVal = fix.hiLogVal
    var tmpztStepStamp4 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    TestLogObj.FillZoneStep(tmpztStepStamp4)
    expect_equal(fix.lowLogVal, TestLogObj.ztStepObj[0].logDataValue)
    expect_equal(fix.midLogVal, TestLogObj.ztStepObj[2].logDataValue)
    expect_not_equal(fix.lowLogVal, TestLogObj.ztStepObj[1].logDataValue)
    fix.sizingLoggerFrameObj.logObjs.push_back(TestLogObj)
    fix.TearDown()

@test
def LoggingDDWrap1stepPerHour():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    ShowMessage(fix.state, "Begin Test: SizingAnalysisObjectsTest, LoggingDDWrap1stepPerHour")
    var TestLogObj = SizingLog(fix.LogVal)
    TestLogObj.NumOfEnvironmentsInLogSet = 2
    TestLogObj.NumOfDesignDaysInLogSet = 2
    TestLogObj.NumberOfSizingPeriodsInLogSet = 0
    TestLogObj.NumOfStepsInLogSet = 48
    TestLogObj.ztStepCountByEnvrnMap[1] = 24
    TestLogObj.ztStepCountByEnvrnMap[2] = 24
    TestLogObj.envrnStartZtStepIndexMap[1] = 0
    TestLogObj.envrnStartZtStepIndexMap[2] = 24
    TestLogObj.newEnvrnToSeedEnvrnMap[3] = 1
    TestLogObj.newEnvrnToSeedEnvrnMap[4] = 2
    TestLogObj.ztStepObj = List[type(TestLogObj.ztStepObj[0])](TestLogObj.NumOfStepsInLogSet)
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    var Envrn: Int = 3
    fix.state.dataGlobal.DayOfSim = 1
    var HourofDay: Int = 1
    var timeStp: Int = 1
    var timeStepDuration: Float64 = 1.0
    var numTimeStepsInHour: Int = 1
    fix.LogVal = fix.lowLogVal
    for hr in range(1, 25):
        HourofDay = hr
        var tmpztStepStamp1 = ZoneTimestepObject(
            fix.state.dataGlobal.KindOfSim,
            Envrn,
            fix.state.dataGlobal.DayOfSim,
            HourofDay,
            timeStp,
            timeStepDuration,
            numTimeStepsInHour)
        TestLogObj.FillZoneStep(tmpztStepStamp1)
    Envrn = 4
    fix.LogVal = fix.hiLogVal
    for hr in range(1, 25):
        HourofDay = hr
        var tmpztStepStamp1 = ZoneTimestepObject(
            fix.state.dataGlobal.KindOfSim,
            Envrn,
            fix.state.dataGlobal.DayOfSim,
            HourofDay,
            timeStp,
            timeStepDuration,
            numTimeStepsInHour)
        TestLogObj.FillZoneStep(tmpztStepStamp1)
    expect_equal(fix.lowLogVal, TestLogObj.ztStepObj[23].logDataValue)
    expect_equal(fix.hiLogVal, TestLogObj.ztStepObj[24].logDataValue)
    fix.sizingLoggerFrameObj.logObjs.push_back(TestLogObj)
    fix.TearDown()

@test
def PlantCoincidentAnalyObjTest():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    ShowMessage(fix.state, "Begin Test: SizingAnalysisObjectsTest, PlantCoincidentAnalyObjTest")
    var loopName: String = "Test Plant Loop 1"
    var loopNum: Int = 1
    var nodeNum: Int = 1
    var density: Float64 = 1000
    var cp: Float64 = 1.0
    var timestepsInAvg: Int = 1
    var plantSizingIndex: Int = 1
    var TestAnalysisObj = PlantCoinicidentAnalysis(loopName, loopNum, nodeNum, density, cp, timestepsInAvg, plantSizingIndex)
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    var Envrn: Int = 4
    fix.state.dataGlobal.DayOfSim = 1
    var HourofDay: Int = 1
    var timeStp: Int = 1
    var timeStepDuration: Float64 = 0.25
    var numTimeStepsInHour: Int = 4
    var tmpztStepStamp1 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    fix.LogVal = 1.5
    tmpztStepStamp1.runningAvgDataValue = 1.5
    fix.sizingLoggerFrameObj.logObjs[fix.logIndex].FillZoneStep(tmpztStepStamp1)
    TestAnalysisObj.newFoundMassFlowRateTimeStamp = tmpztStepStamp1
    TestAnalysisObj.peakMdotCoincidentDemand = 1000.0
    TestAnalysisObj.peakMdotCoincidentReturnTemp = 10.0
    TestAnalysisObj.NewFoundMaxDemandTimeStamp = tmpztStepStamp1
    TestAnalysisObj.peakDemandMassFlow = 1.5
    TestAnalysisObj.peakDemandReturnTemp = 10.0
    expect_equal(0.002, fix.state.dataPlnt.PlantLoop[0].MaxVolFlowRate)
    TestAnalysisObj.ResolveDesignFlowRate(fix.state, 1)
    expect_equal(0.0015, fix.state.dataPlnt.PlantLoop[0].MaxVolFlowRate)
    expect_equal(1.5, fix.state.dataPlnt.PlantLoop[0].MaxMassFlowRate)
    expect_true(TestAnalysisObj.anotherIterationDesired)
    fix.TearDown()

@test
def LoggingSubStep4stepPerHour():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    ShowMessage(fix.state, "Begin Test: SizingAnalysisObjectsTest, LoggingSubStep4stepPerHour")
    var TestLogObj = SizingLog(fix.LogVal)
    TestLogObj.NumOfEnvironmentsInLogSet = 2
    TestLogObj.NumOfDesignDaysInLogSet = 2
    TestLogObj.NumberOfSizingPeriodsInLogSet = 0
    TestLogObj.NumOfStepsInLogSet = 24 * 2 * 4
    TestLogObj.ztStepCountByEnvrnMap[1] = 96
    TestLogObj.ztStepCountByEnvrnMap[2] = 96
    TestLogObj.envrnStartZtStepIndexMap[1] = 0
    TestLogObj.envrnStartZtStepIndexMap[2] = 96
    TestLogObj.newEnvrnToSeedEnvrnMap[3] = 1
    TestLogObj.newEnvrnToSeedEnvrnMap[4] = 2
    TestLogObj.ztStepObj = List[type(TestLogObj.ztStepObj[0])](TestLogObj.NumOfStepsInLogSet)
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    var Envrn: Int = 3
    fix.state.dataGlobal.DayOfSim = 1
    var HourofDay: Int = 0
    fix.state.dataHVACGlobal.TimeStepSys = 1.0 / (4.0 * 5.0)
    fix.state.dataHVACGlobal.TimeStepSysSec = fix.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    var zoneTimeStepDuration: Float64 = 0.25
    var numTimeStepsInHour: Int = 4
    fix.LogVal = fix.lowLogVal
    for hr in range(1, 25):
        HourofDay = hr
        for timeStp in range(1, 5):
            for subTimeStp in range(1, 6):
                var minutesPerHour: Float64 = 60.0
                var tmpztStepStamp = ZoneTimestepObject(fix.state.dataGlobal.KindOfSim,
                                                        Envrn,
                                                        fix.state.dataGlobal.DayOfSim,
                                                        HourofDay,
                                                        timeStp,
                                                        zoneTimeStepDuration,
                                                        numTimeStepsInHour)
                var tmpSysStepStamp = SystemTimestepObject()
                tmpSysStepStamp.CurMinuteEnd = (timeStp - 1) * (minutesPerHour * zoneTimeStepDuration) + (subTimeStp) * (fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep) * minutesPerHour
                if tmpSysStepStamp.CurMinuteEnd == 0.0:
                    tmpSysStepStamp.CurMinuteEnd = minutesPerHour
                tmpSysStepStamp.CurMinuteStart = tmpSysStepStamp.CurMinuteEnd - (fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep) * minutesPerHour
                tmpSysStepStamp.TimeStepDuration = fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep
                TestLogObj.FillSysStep(tmpztStepStamp, tmpSysStepStamp)
            var tmpztStepStamp1 = ZoneTimestepObject(fix.state.dataGlobal.KindOfSim,
                                                     Envrn,
                                                     fix.state.dataGlobal.DayOfSim,
                                                     HourofDay,
                                                     timeStp,
                                                     zoneTimeStepDuration,
                                                     numTimeStepsInHour)
            TestLogObj.FillZoneStep(tmpztStepStamp1)
    Envrn = 4
    fix.LogVal = fix.hiLogVal
    for hr in range(1, 25):
        HourofDay = hr
        for timeStp in range(1, 5):
            for subTimeStp in range(1, 6):
                var minutesPerHour: Float64 = 60.0
                var tmpztStepStamp = ZoneTimestepObject(fix.state.dataGlobal.KindOfSim,
                                                        Envrn,
                                                        fix.state.dataGlobal.DayOfSim,
                                                        HourofDay,
                                                        timeStp,
                                                        zoneTimeStepDuration,
                                                        numTimeStepsInHour)
                var tmpSysStepStamp = SystemTimestepObject()
                tmpSysStepStamp.CurMinuteEnd = (timeStp - 1) * (minutesPerHour * zoneTimeStepDuration) + (subTimeStp) * (fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep) * minutesPerHour
                if tmpSysStepStamp.CurMinuteEnd == 0.0:
                    tmpSysStepStamp.CurMinuteEnd = minutesPerHour
                tmpSysStepStamp.CurMinuteStart = tmpSysStepStamp.CurMinuteEnd - (fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep) * minutesPerHour
                tmpSysStepStamp.TimeStepDuration = fix.state.dataOutputProcessor.TimeValue[Int(OutputProcessor.TimeStepType.System)].TimeStep
                TestLogObj.FillSysStep(tmpztStepStamp, tmpSysStepStamp)
            var tmpztStepStamp1 = ZoneTimestepObject(fix.state.dataGlobal.KindOfSim,
                                                     Envrn,
                                                     fix.state.dataGlobal.DayOfSim,
                                                     HourofDay,
                                                     timeStp,
                                                     zoneTimeStepDuration,
                                                     numTimeStepsInHour)
            TestLogObj.FillZoneStep(tmpztStepStamp1)
    expect_equal(fix.lowLogVal, TestLogObj.ztStepObj[95].logDataValue)
    expect_equal(fix.hiLogVal, TestLogObj.ztStepObj[96].logDataValue)
    TestLogObj.AverageSysTimeSteps()
    TestLogObj.ProcessRunningAverage()
    expect_equal(fix.lowLogVal, TestLogObj.ztStepObj[95].logDataValue)
    expect_equal(fix.hiLogVal, TestLogObj.ztStepObj[96].logDataValue)
    expect_equal(fix.lowLogVal, TestLogObj.ztStepObj[95].subSteps[4].LogDataValue)
    expect_equal(fix.hiLogVal, TestLogObj.ztStepObj[96].subSteps[0].LogDataValue)
    fix.TearDown()

@test
def PlantCoincidentAnalyObjTestNullMassFlowRateTimestamp():
    var fix = SizingAnalysisObjectsTest()
    fix.SetUp()
    var loopName: String = "Test Plant Loop 1"
    var loopNum: Int = 1
    var nodeNum: Int = 1
    var density: Float64 = 1000
    var cp: Float64 = 1.0
    var timestepsInAvg: Int = 1
    var plantSizingIndex: Int = 1
    var TestAnalysisObj = PlantCoinicidentAnalysis(loopName, loopNum, nodeNum, density, cp, timestepsInAvg, plantSizingIndex)
    fix.state.dataGlobal.KindOfSim = Constant.KindOfSim.HVACSizeDesignDay
    var Envrn: Int = 4
    fix.state.dataGlobal.DayOfSim = 1
    var HourofDay: Int = 1
    var timeStp: Int = 1
    var timeStepDuration: Float64 = 0.25
    var numTimeStepsInHour: Int = 4
    var tmpztStepStamp1 = ZoneTimestepObject(
        fix.state.dataGlobal.KindOfSim,
        Envrn,
        fix.state.dataGlobal.DayOfSim,
        HourofDay,
        timeStp,
        timeStepDuration,
        numTimeStepsInHour)
    fix.LogVal = 1.5
    tmpztStepStamp1.runningAvgDataValue = 1.5
    fix.sizingLoggerFrameObj.logObjs[fix.logIndex].FillZoneStep(tmpztStepStamp1)
    var tmpNullztStep2 = ZoneTimestepObject()  # default constructor
    TestAnalysisObj.newFoundMassFlowRateTimeStamp = tmpNullztStep2
    TestAnalysisObj.peakMdotCoincidentDemand = 1000.0
    TestAnalysisObj.peakMdotCoincidentReturnTemp = 10.0
    TestAnalysisObj.NewFoundMaxDemandTimeStamp = tmpztStepStamp1
    TestAnalysisObj.peakDemandMassFlow = 1.5
    TestAnalysisObj.peakDemandReturnTemp = 10.0
    expect_equal(0.002, fix.state.dataPlnt.PlantLoop[0].MaxVolFlowRate)
    TestAnalysisObj.ResolveDesignFlowRate(fix.state, 1)
    expect_near(0.00015, fix.state.dataPlnt.PlantLoop[0].MaxVolFlowRate, 0.00001)
    expect_near(0.15, fix.state.dataPlnt.PlantLoop[0].MaxMassFlowRate, 0.001)
    expect_true(TestAnalysisObj.anotherIterationDesired)
    fix.TearDown()