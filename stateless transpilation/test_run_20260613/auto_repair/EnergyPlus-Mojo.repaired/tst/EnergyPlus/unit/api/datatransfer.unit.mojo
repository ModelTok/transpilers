import "utility"
import "vector"
import "gtest" as gtest
from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataRuntimeLanguage import DataRuntimeLanguage
from EnergyPlus.EMSManager import EMSManager
from EnergyPlus.IOFiles import IOFiles
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.OutAirNodeManager import OutAirNodeManager
from EnergyPlus.OutputProcessor import OutputProcessor
from EnergyPlus.PluginManager import PluginManager
from EnergyPlus.api.datatransfer import *
from EnergyPlus.DataEnvironment import DataEnvironment
class DataExchangeAPIUnitTestFixture(EnergyPlusFixture):
    struct DummyRealVariable:
        var varName: String
        var varKey: String
        var value: Float64 = 0.0
        var meterType: Bool = false
        def __init__(inout self, _varName: String, _varKey: String, _value: Float64, _meterType: Bool):
            self.varName = _varName
            self.varKey = _varKey
            self.value = _value
            self.meterType = _meterType

    struct DummyIntVariable:
        var varName: String
        var varKey: String
        var value: Int = 0
        def __init__(inout self, _varName: String, _varKey: String, _value: Float64):
            self.varName = _varName
            self.varKey = _varKey
            self.value = _value

    struct DummyBaseActuator:
        var objType: String
        var controlType: String
        var key: String
        var flag: Bool = false
        def __init__(inout self, _objType: String, _controlType: String, _key: String):
            self.objType = _objType
            self.controlType = _controlType
            self.key = _key

    struct DummyRealActuator(DummyBaseActuator):
        var val: Float64 = 0.0
        def __init__(inout self, _objType: String, _controlType: String, _key: String):
            super.__init__(_objType, _controlType, _key)

    struct DummyIntActuator(DummyBaseActuator):
        var val: Int = 0
        def __init__(inout self, _objType: String, _controlType: String, _key: String):
            super.__init__(_objType, _controlType, _key)

    struct DummyBoolActuator(DummyBaseActuator):
        var val: Bool = True
        def __init__(inout self, _objType: String, _controlType: String, _key: String):
            super.__init__(_objType, _controlType, _key)

    struct DummyInternalVariable:
        var varName: String
        var varKey: String
        var value: Float64 = 0.0
        def __init__(inout self, _varName: String, _varKey: String, _value: Float64):
            self.varName = _varName
            self.varKey = _varKey
            self.value = _value

    var realVariablePlaceholders: List[DummyRealVariable]
    var intVariablePlaceholders: List[DummyIntVariable]
    var realActuatorPlaceholders: List[DummyRealActuator]
    var intActuatorPlaceholders: List[DummyIntActuator]
    var boolActuatorPlaceholders: List[DummyBoolActuator]
    var internalVarPlaceholders: List[DummyInternalVariable]

    def SetUp(self):
        EnergyPlusFixture.SetUp(self)
        state.dataGlobal.TimeStepZone = 1.0 / 60.0
        state.dataHVACGlobal.TimeStepSys = state.dataGlobal.TimeStepZone
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.Zone, state.dataGlobal.TimeStepZone)
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.System, state.dataHVACGlobal.TimeStepSys)
        state.dataPluginManager.pluginManager = PluginManager(*state)

    def TearDown(self):
        self.realVariablePlaceholders.Clear()
        self.realActuatorPlaceholders.Clear()
        EnergyPlusFixture.TearDown(self)

    def preRequestRealVariable(self, varName: String, key: String, initialValue: Float64 = 0.0, meterType: Bool = False):
        self.realVariablePlaceholders.Append(DummyRealVariable(varName, key, initialValue, meterType))
        requestVariable((void*)self.state, varName.c_str(), key.c_str())

    def preRequestIntegerVariable(self, varName: String, key: String, initialValue: Int = 0):
        self.intVariablePlaceholders.Append(DummyIntVariable(varName, key, initialValue))
        requestVariable((void*)self.state, varName.c_str(), key.c_str())

    def setupVariablesOnceAllAreRequested(self):
        state.dataInputProcessing.inputProcessor.preScanReportingVariables(*state)
        for val in self.realVariablePlaceholders:
            if val.meterType:
                SetupOutputVariable(*state,
                                    val.varName,
                                    Constant.Units.J,
                                    val.value,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Sum,
                                    val.varKey,
                                    Constant.eResource.Electricity,
                                    OutputProcessor.Group.HVAC,
                                    OutputProcessor.EndUseCat.Heating)
            else:
                SetupOutputVariable(*state,
                                    val.varName,
                                    Constant.Units.kg_s,
                                    val.value,
                                    OutputProcessor.TimeStepType.Zone,
                                    OutputProcessor.StoreType.Average,
                                    val.varKey)
        for val in self.intVariablePlaceholders:
            SetupOutputVariable(*state,
                                val.varName,
                                Constant.Units.kg_s,
                                val.value,
                                OutputProcessor.TimeStepType.Zone,
                                OutputProcessor.StoreType.Average,
                                val.varKey)

    enum ActuatorType:
        REAL
        INTEGER
        BOOL

    def preRequestActuator(self, objType: String, controlType: String, objKey: String, t: ActuatorType):
        if t == ActuatorType.REAL:
            self.realActuatorPlaceholders.Append(DummyRealActuator(objType, controlType, objKey))
        elif t == ActuatorType.INTEGER:
            self.intActuatorPlaceholders.Append(DummyIntActuator(objType, controlType, objKey))
        elif t == ActuatorType.BOOL:
            self.boolActuatorPlaceholders.Append(DummyBoolActuator(objType, controlType, objKey))

    def setupActuatorsOnceAllAreRequested(self):
        for act in self.realActuatorPlaceholders:
            SetupEMSActuator(*state, act.objType, act.key, act.controlType, "kg/s", act.flag, act.val)
        for act in self.intActuatorPlaceholders:
            SetupEMSActuator(*state, act.objType, act.key, act.controlType, "kg/s", act.flag, act.val)
        for act in self.boolActuatorPlaceholders:
            SetupEMSActuator(*state, act.objType, act.key, act.controlType, "kg/s", act.flag, act.val)

    def preRequestInternalVariable(self, varType: String, varKey: String, value: Float64):
        self.internalVarPlaceholders.Append(DummyInternalVariable(varType, varKey, value))

    def setupInternalVariablesOnceAllAreRequested(self):
        for iv in self.internalVarPlaceholders:
            SetupEMSInternalVariable(*state, iv.varName, iv.varKey, "kg/s", iv.value)

    @staticmethod
    def addPluginGlobal(state: EnergyPlusData, varName: String):
        state.dataPluginManager.pluginManager.addGlobalVariable(state, varName)

    def addTrendWithNewGlobal(self, newGlobalVarName: String, trendName: String, numTrendValues: Int):
        state.dataPluginManager.pluginManager.addGlobalVariable(*state, newGlobalVarName)
        var i = EnergyPlus.PluginManagement.PluginManager.getGlobalVariableHandle(*state, newGlobalVarName, True)
        state.dataPluginManager.trends.Append(Trend(*state, trendName, numTrendValues, i))

    def simulateTimeStepAndReport(self):
        UpdateMeterReporting(*state)
        UpdateDataandReport(*state, OutputProcessor.TimeStepType.Zone)

@test def DataTransfer_TestListAllDataInCSV():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    var idf_objects = delimited_string(["Version,", DataStringGlobals.MatchVersion + ";"])
    ASSERT_TRUE(process_idf(idf_objects, False))
    var charCsvDataEmpty = listAllAPIDataCSV((void*)fixture.state)
    var strCsvDataEmpty = String(charCsvDataEmpty)
    free(charCsvDataEmpty)
    fixture.preRequestRealVariable("Boiler Heat Transfer", "Boiler 1")
    fixture.preRequestRealVariable("Chiller Electric Energy", "Chiller 1", 3.14, True)
    fixture.setupVariablesOnceAllAreRequested()
    fixture.preRequestActuator("Chiller:Electric", "Max Flow Rate", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.setupActuatorsOnceAllAreRequested()
    fixture.preRequestInternalVariable("Floor Area", "Zone 1", 6.02e23)
    fixture.setupInternalVariablesOnceAllAreRequested()
    DataExchangeAPIUnitTestFixture.addPluginGlobal(*fixture.state, "Plugin_Global_Var_Name")
    fixture.addTrendWithNewGlobal("NewGlobalVarHere", "Trend 1", 3)
    var charCsvDataFull = listAllAPIDataCSV((void*)fixture.state)
    var csvData = String(charCsvDataFull)
    free(charCsvDataFull)
    var foundAddedBoiler = csvData.find("BOILER 1") != String.npos
    var foundAddedMeter = csvData.find("CHILLER 1") != String.npos
    var foundAddedActuator = csvData.find("Chiller:Electric") != String.npos
    var foundAddedIV = csvData.find("Zone 1") != String.npos
    var foundAddedGlobal = csvData.find("PLUGIN_GLOBAL_VAR_NAME") != String.npos
    var foundAddedTrend = csvData.find("Trend 1") != String.npos
    assert_true(foundAddedBoiler)
    assert_true(foundAddedMeter)
    assert_true(foundAddedActuator)
    assert_true(foundAddedIV)
    assert_true(foundAddedGlobal)
    assert_true(foundAddedTrend)
    fixture.TearDown()

@test def DataTransfer_TestApiDataFullyReady():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    assert_equal(0, apiDataFullyReady((void*)fixture.state))
    assert_false(apiDataFullyReady((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestGetVariableHandlesRealTypes():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestRealVariable("Chiller Heat Transfer", "Chiller 1")
    fixture.preRequestRealVariable("Zone Mean Temperature", "Zone 1")
    fixture.setupVariablesOnceAllAreRequested()
    var hChillerHT = getVariableHandle((void*)fixture.state, "Chiller Heat Transfer", "Chiller 1")
    var hZoneTemp = getVariableHandle((void*)fixture.state, "Zone Mean Temperature", "Zone 1")
    assert_true(hChillerHT > -1)
    assert_true(hZoneTemp > -1)
    fixture.TearDown()

@test def DataTransfer_TestGetVariableHandlesIntegerTypes():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestIntegerVariable("Chiller Operating Mode", "Chiller 1")
    fixture.preRequestIntegerVariable("Chiller Operating Mode", "Chiller 2")
    fixture.setupVariablesOnceAllAreRequested()
    var hChillerMode1 = getVariableHandle((void*)fixture.state, "Chiller Operating Mode", "Chiller 1")
    var hChillerMode2 = getVariableHandle((void*)fixture.state, "Chiller Operating Mode", "Chiller 2")
    assert_true(hChillerMode1 > -1)
    assert_true(hChillerMode2 > -1)
    fixture.TearDown()

@test def DataTransfer_TestGetVariableHandlesMixedTypes():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestRealVariable("Chiller Heat Transfer", "Chiller 1")
    fixture.preRequestRealVariable("Zone Mean Temperature", "Zone 1")
    fixture.preRequestIntegerVariable("Chiller Operating Mode", "Chiller 1")
    fixture.setupVariablesOnceAllAreRequested()
    var hChillerHT = getVariableHandle((void*)fixture.state, "Chiller Heat Transfer", "Chiller 1")
    var hZoneTemp = getVariableHandle((void*)fixture.state, "Zone Mean Temperature", "Zone 1")
    var hChillerMode = getVariableHandle((void*)fixture.state, "Chiller Operating Mode", "Chiller 1")
    assert_true(hChillerHT > -1)
    assert_true(hZoneTemp > -1)
    assert_true(hChillerMode > -1)
    var hChiller2HT = getVariableHandle((void*)fixture.state, "Chiller Heat Transfer", "Chiller 2")
    var hZone2Temp = getVariableHandle((void*)fixture.state, "Zone Mean Radiant Temperature", "Zone 1")
    assert_equal(-1, hChiller2HT)
    assert_equal(-1, hZone2Temp)
    fixture.TearDown()

@test def DataTransfer_TestGetVariableValuesRealTypes():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestRealVariable("Chiller Heat Transfer", "Chiller 1", 3.14)
    fixture.preRequestRealVariable("Zone Mean Temperature", "Zone 1", 2.718)
    fixture.setupVariablesOnceAllAreRequested()
    var hChillerHT = getVariableHandle((void*)fixture.state, "Chiller Heat Transfer", "Chiller 1")
    var hZoneTemp = getVariableHandle((void*)fixture.state, "Zone Mean Temperature", "Zone 1")
    fixture.state.dataGlobal.HourOfDay = 1
    fixture.state.dataGlobal.MinutesInTimeStep = 1
    fixture.state.dataEnvrn.Month = 1
    fixture.state.dataEnvrn.DayOfMonth = 1
    fixture.simulateTimeStepAndReport()
    var curHeatTransfer = getVariableValue((void*)fixture.state, hChillerHT)
    var curZoneTemp = getVariableValue((void*)fixture.state, hZoneTemp)
    assert_approx_equal(3.14, curHeatTransfer, 0.0001)
    assert_approx_equal(2.718, curZoneTemp, 0.0001)
    getVariableValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getVariableValue((void*)fixture.state, 3)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestGetMeterHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestRealVariable("Chiller Electric Energy", "Chiller 1", 3.14, True)
    fixture.setupVariablesOnceAllAreRequested()
    var hFacilityElectricity = getMeterHandle((void*)fixture.state, "Electricity:Facility")
    assert_true(hFacilityElectricity > -1)
    var hDummyMeter = getMeterHandle((void*)fixture.state, "EnergySomething")
    assert_equal(-1, hDummyMeter)
    fixture.TearDown()

@test def DataTransfer_TestGetMeterValues():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestRealVariable("Chiller Electric Energy", "Chiller 1", 3.14, True)
    fixture.setupVariablesOnceAllAreRequested()
    var hFacilityElectricity = getMeterHandle((void*)fixture.state, "Electricity:Facility")
    assert_true(hFacilityElectricity > -1)
    fixture.state.dataGlobal.HourOfDay = 1
    fixture.state.dataGlobal.MinutesInTimeStep = 1
    fixture.state.dataEnvrn.Month = 1
    fixture.state.dataEnvrn.DayOfMonth = 1
    fixture.simulateTimeStepAndReport()
    var curFacilityElectricity = getMeterValue((void*)fixture.state, hFacilityElectricity)
    assert_approx_equal(3.14, curFacilityElectricity, 0.001)
    getMeterValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getMeterValue((void*)fixture.state, 5)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestGetRealActuatorHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 2", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 1")
    assert_true(hActuator > -1)
    var hActuator2 = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 2")
    assert_true(hActuator2 > -1)
    assert_ne(hActuator, hActuator2)
    fixture.TearDown()

@test def DataTransfer_TestGetIntActuatorHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 2", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 1")
    assert_true(hActuator > -1)
    var hActuator2 = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 2")
    assert_true(hActuator2 > -1)
    assert_ne(hActuator, hActuator2)
    fixture.TearDown()

@test def DataTransfer_TestGetBoolActuatorHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 2", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 1")
    assert_true(hActuator > -1)
    var hActuator2 = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 2")
    assert_true(hActuator2 > -1)
    assert_ne(hActuator, hActuator2)
    fixture.TearDown()

@test def DataTransfer_TestGetMixedActuatorHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 2", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.preRequestActuator("Chiller", "Max Flow", "Chiller 3", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 1")
    assert_true(hActuator > -1)
    var hActuator2 = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 2")
    assert_true(hActuator2 > -1)
    var hActuator3 = getActuatorHandle((void*)fixture.state, "Chiller", "Max Flow", "Chiller 3")
    assert_true(hActuator3 > -1)
    assert_ne(hActuator, hActuator2)
    assert_ne(hActuator, hActuator3)
    assert_ne(hActuator2, hActuator3)
    fixture.TearDown()

@test def DataTransfer_TestGetBadActuatorHandles():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("Chiller:Electric", "Max Flow Rate", "Chiller 1", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator = getActuatorHandle((void*)fixture.state, "Chiller:Electric", "Max Flow Rate", "Chiller 1")
    assert_true(hActuator > -1)
    do:
        var hActuatorBad = getActuatorHandle((void*)fixture.state, "Chiller:Electric", "Max Flow Rate", "InvalidInstance")
        assert_equal(hActuatorBad, -1)
    do:
        var hActuatorBad = getActuatorHandle((void*)fixture.state, "Chiller:Electric", "InvalidVar", "Chiller 1")
        assert_equal(hActuatorBad, -1)
    do:
        var hActuatorBad = getActuatorHandle((void*)fixture.state, "InvalidType", "Max Flow Rate", "Chiller 1")
        assert_equal(hActuatorBad, -1)
    fixture.TearDown()

@test def DataTransfer_TestGetAndSetRealActuators():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("a", "b", "c", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.preRequestActuator("d", "e", "f", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator1 = getActuatorHandle((void*)fixture.state, "a", "b", "c")
    var hActuator2 = getActuatorHandle((void*)fixture.state, "d", "e", "f")
    assert_true(hActuator1 > -1)
    assert_true(hActuator2 > -1)
    setActuatorValue((void*)fixture.state, hActuator1, 3.14)
    setActuatorValue((void*)fixture.state, hActuator2, 6.28)
    var val1 = getActuatorValue((void*)fixture.state, hActuator1)
    var val2 = getActuatorValue((void*)fixture.state, hActuator2)
    assert_double_eq(3.14, val1)
    assert_double_eq(6.28, val2)
    getActuatorValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getActuatorValue((void*)fixture.state, 3)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestGetAndSetIntActuators():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("a", "b", "c", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.preRequestActuator("d", "e", "f", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator1 = getActuatorHandle((void*)fixture.state, "a", "b", "c")
    var hActuator2 = getActuatorHandle((void*)fixture.state, "d", "e", "f")
    assert_true(hActuator1 > -1)
    assert_true(hActuator2 > -1)
    setActuatorValue((void*)fixture.state, hActuator1, 3)
    setActuatorValue((void*)fixture.state, hActuator2, -6.1)
    var val1 = getActuatorValue((void*)fixture.state, hActuator1)
    var val2 = getActuatorValue((void*)fixture.state, hActuator2)
    assert_double_eq(3.0, val1)
    assert_double_eq(-6.0, val2)
    getActuatorValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getActuatorValue((void*)fixture.state, 3)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestGetAndSetBoolActuators():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("a", "b", "c", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.preRequestActuator("d", "e", "f", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator1 = getActuatorHandle((void*)fixture.state, "a", "b", "c")
    var hActuator2 = getActuatorHandle((void*)fixture.state, "d", "e", "f")
    assert_true(hActuator1 > -1)
    assert_true(hActuator2 > -1)
    setActuatorValue((void*)fixture.state, hActuator1, 0)
    setActuatorValue((void*)fixture.state, hActuator2, 1)
    var val1 = getActuatorValue((void*)fixture.state, hActuator1)
    var val2 = getActuatorValue((void*)fixture.state, hActuator2)
    assert_double_eq(0.0, val1)
    assert_double_eq(1.0, val2)
    getActuatorValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getActuatorValue((void*)fixture.state, 3)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestResetActuators():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestActuator("a", "b", "c", DataExchangeAPIUnitTestFixture.ActuatorType.REAL)
    fixture.preRequestActuator("d", "e", "f", DataExchangeAPIUnitTestFixture.ActuatorType.INTEGER)
    fixture.preRequestActuator("g", "h", "i", DataExchangeAPIUnitTestFixture.ActuatorType.BOOL)
    fixture.setupActuatorsOnceAllAreRequested()
    var hActuator1 = getActuatorHandle((void*)fixture.state, "a", "b", "c")
    var hActuator2 = getActuatorHandle((void*)fixture.state, "d", "e", "f")
    var hActuator3 = getActuatorHandle((void*)fixture.state, "g", "h", "i")
    resetActuator((void*)fixture.state, hActuator1)
    resetActuator((void*)fixture.state, hActuator2)
    resetActuator((void*)fixture.state, hActuator3)
    resetActuator((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    resetActuator((void*)fixture.state, 8)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestAccessingInternalVariables():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    fixture.preRequestInternalVariable("a", "b", 1.0)
    fixture.preRequestInternalVariable("c", "d", 2.0)
    fixture.setupInternalVariablesOnceAllAreRequested()
    var hIntVar1 = getInternalVariableHandle((void*)fixture.state, "a", "b")
    var hIntVar2 = getInternalVariableHandle((void*)fixture.state, "c", "d")
    assert_true(hIntVar1 > -1)
    assert_true(hIntVar2 > -1)
    var val1 = getInternalVariableValue((void*)fixture.state, hIntVar1)
    var val2 = getInternalVariableValue((void*)fixture.state, hIntVar2)
    assert_double_eq(1.0, val1)
    assert_double_eq(2.0, val2)
    getInternalVariableValue((void*)fixture.state, -1)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    resetErrorFlag((void*)fixture.state)
    getInternalVariableValue((void*)fixture.state, 3)
    assert_equal(1, apiErrorFlag((void*)fixture.state))
    fixture.TearDown()

@test def DataTransfer_TestMiscSimData():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    year((void*)fixture.state)
    month((void*)fixture.state)
    dayOfMonth((void*)fixture.state)
    dayOfWeek((void*)fixture.state)
    dayOfYear((void*)fixture.state)
    daylightSavingsTimeIndicator((void*)fixture.state)
    hour((void*)fixture.state)
    currentTime((void*)fixture.state)
    minutes((void*)fixture.state)
    systemTimeStep((void*)fixture.state)
    holidayIndex((void*)fixture.state)
    sunIsUp((void*)fixture.state)
    isRaining((void*)fixture.state)
    warmupFlag((void*)fixture.state)
    kindOfSim((void*)fixture.state)
    currentEnvironmentNum((void*)fixture.state)
    fixture.TearDown()

@test def DataTransfer_Python_EMS_Override():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    var idf_objects = delimited_string([
        "OutdoorAir:Node, Test node;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpointLo,          !- Name",
        "Test node,  !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Minimum Setpoint;    !- Actuated Component Control Type",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    OutAirNodeManager.SetOutAirNodes(*fixture.state)
    EMSManager.CheckIfAnyEMS(*fixture.state)
    fixture.state.dataEMSMgr.FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(*fixture.state, EMSManager.EMSCallFrom.SetupSimulation, anyRan)
    assert_true(fixture.state.dataRuntimeLang.numEMSActuatorsAvailable > 0)
    assert_equal(1, fixture.state.dataRuntimeLang.numActuatorsUsed)
    assert_true(compare_err_stream("", True))
    var hActuator = getActuatorHandle(fixture.state, "System Node Setpoint", "Temperature Minimum Setpoint", "Test node")
    assert_true(hActuator > -1)
    assert_equal(fixture.state.dataRuntimeLang.EMSActuatorUsed(1).ActuatorVariableNum, hActuator)
    var expectedError = delimited_string([
        "   ** Warning ** Data Exchange API: An EnergyManagementSystem:Actuator seems to be already defined in the EnergyPlus File and named "
        "'TEMPSETPOINTLO'.",
        "   **   ~~~   ** Occurred for componentType='SYSTEM NODE SETPOINT', controlType='TEMPERATURE MINIMUM SETPOINT', uniqueKey='TEST NODE'.",
        "   **   ~~~   ** The getActuatorHandle function will still return the handle (= 2) but caller should take note that there is a risk of "
        "overwriting.",
    ])
    assert_true(compare_err_stream(expectedError, True))
    fixture.TearDown()

@test def DataTransfer_PythonHandle_MarksActuatorAsUsed():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    var idf_objects = delimited_string([
        "OutdoorAir:Node, Test node;",
        "EnergyManagementSystem:Actuator,",
        "TempSetpointLo,          !- Name",
        "Test node,               !- Actuated Component Unique Name",
        "System Node Setpoint,    !- Actuated Component Type",
        "Temperature Minimum Setpoint;    !- Actuated Component Control Type",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    OutAirNodeManager.SetOutAirNodes(*fixture.state)
    EMSManager.CheckIfAnyEMS(*fixture.state)
    fixture.state.dataEMSMgr.FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(*fixture.state, EMSManager.EMSCallFrom.SetupSimulation, anyRan)
    ASSERT_EQ(1, fixture.state.dataRuntimeLang.numActuatorsUsed)
    assert_false(fixture.state.dataRuntimeLang.EMSActuatorUsed(1).wasActuated)
    var hActuator = getActuatorHandle(fixture.state, "System Node Setpoint", "Temperature Minimum Setpoint", "Test node")
    assert_true(hActuator > -1)
    assert_true(fixture.state.dataRuntimeLang.EMSActuatorUsed(1).wasActuated)
    EMSManager.checkForUnusedActuatorsAtEnd(*fixture.state)
    assert_false(compare_err_stream_substring("Unused EMS Actuator detected", False, False))
    fixture.TearDown()

@test def DataTransfer_Python_Python_Override():
    var fixture = DataExchangeAPIUnitTestFixture()
    fixture.SetUp()
    var idf_objects = delimited_string([
        "OutdoorAir:Node, Test node;",
        "PythonPlugin:Instance,",
        "  Vav2Mixedairmanagers,",
        "  Yes,",
        "  PythonPluginDemandManager_LargeOffice,",
        "  Vav2Mixedairmanagers;",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    OutAirNodeManager.SetOutAirNodes(*fixture.state)
    EMSManager.CheckIfAnyEMS(*fixture.state)
    fixture.state.dataEMSMgr.FinishProcessingUserInput = True
    var anyRan: Bool
    EMSManager.ManageEMS(*fixture.state, EMSManager.EMSCallFrom.SetupSimulation, anyRan)
    assert_true(fixture.state.dataRuntimeLang.numEMSActuatorsAvailable > 0)
    assert_equal(0, fixture.state.dataRuntimeLang.numActuatorsUsed)
    assert_true(compare_err_stream("", True))
    var hActuator = getActuatorHandle(fixture.state, "System Node Setpoint", "Temperature Minimum Setpoint", "Test node")
    assert_true(hActuator > -1)
    assert_true(compare_err_stream("", True))
    var hActuator2 = getActuatorHandle(fixture.state, "System Node Setpoint", "Temperature Minimum Setpoint", "Test node")
    assert_true(hActuator2 > -1)
    assert_equal(hActuator2, hActuator)
    var expectedError = delimited_string([
        "   ** Warning ** Data Exchange API: You seem to already have tried to get an Actuator Handle on this one.",
        "   **   ~~~   ** Occurred for componentType='SYSTEM NODE SETPOINT', controlType='TEMPERATURE MINIMUM SETPOINT', uniqueKey='TEST NODE'.",
        "   **   ~~~   ** The getActuatorHandle function will still return the handle (= 2) but caller should take note that there is a risk of "
        "overwriting.",
    ])
    assert_true(compare_err_stream(expectedError, True))
    fixture.TearDown()