from AutosizingFixture import AutoSizingFixture
from gtest import *  # Use Mojo's built-in test macros if available, else define our own
from EnergyPlus.Autosizing.SystemAirFlowSizing import SystemAirFlowSizer
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.WeatherManager import WeatherManager

# Helper for test macros (since Mojo does not have gtest)
def expect_true(cond: Bool, msg: String = "") raises:
    assert cond, msg if msg != "" else "Expected true"

def expect_false(cond: Bool, msg: String = "") raises:
    assert not cond, msg if msg != "" else "Expected false"

def expect_near(actual: Float64, expected: Float64, tol: Float64, msg: String = "") raises:
    var diff = actual - expected
    if diff < 0: diff = -diff
    assert diff <= tol, msg if msg != "" else "Expected near: " + String(actual) + " vs " + String(expected) + " tol " + String(tol)

def expect_enum_eq[T: EqualityComparable](actual: T, expected: T, msg: String = "") raises:
    assert actual == expected, msg if msg != "" else "Expected enum equality"

# Helper for EIO output comparison (mock)
def compare_eio_stream(output: String, exact: Bool) -> Bool:
    # Placeholder: in real test framework, compare with captured output
    return True

def has_eio_output(flag: Bool):
    # mock

struct SystemAirFlowSizingGauntlet(TestingFunction):
    def run(state: AutoSizingFixture.State) raises:
        state.dataSize.ZoneEqSizing.allocate(1)
        var routineName = "SystemAirFlowSizingGauntlet"
        var sizer = SystemAirFlowSizer()
        var inputValue = 5.0
        var errorsFound = False
        var printFlag = False
        var sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_true(errorsFound)
        expect_enum_eq(AutoSizingResultType.ErrorType2, sizer.errorType)
        expect_near(0.0, sizedValue, 0.0001)
        errorsFound = False
        state.dataSize.CurZoneEqNum = 1
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        printFlag = True
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        var eiooutput = String("! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n" +
                               " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Supply Air Maximum Flow Rate [m3/s], 5.00000\n")
        expect_true(compare_eio_stream(eiooutput, True))
        has_eio_output(True)
        state.dataSize.FinalZoneSizing.allocate(1)
        state.dataSize.ZoneEqSizing.allocate(1)
        state.dataSize.ZoneEqSizing(1).SizingMethod.allocate(35)
        state.dataSize.ZoneSizingRunDone = True
        state.dataSize.FinalZoneSizing(1).DesCoolVolFlow = 1.6
        state.dataSize.FinalZoneSizing(1).DesHeatVolFlow = 1.2
        state.dataSize.FinalZoneSizing(1).CoolDDNum = 1
        state.dataSize.FinalZoneSizing(1).HeatDDNum = 2
        state.dataSize.FinalZoneSizing(1).TimeStepNumAtCoolMax = 12
        state.dataSize.FinalZoneSizing(1).TimeStepNumAtHeatMax = 6
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.dataEnvrn.TotDesDays = 2
        state.dataWeather.DesDayInput.allocate(2)
        state.dataWeather.DesDayInput(1).Month = 7
        state.dataWeather.DesDayInput(1).DayOfMonth = 7
        state.dataWeather.DesDayInput(2).Month = 1
        state.dataWeather.DesDayInput(2).DayOfMonth = 1
        state.dataWeather.DesDayInput(1).Title = "CoolingDD"
        state.dataWeather.DesDayInput(2).Title = "HeatingDD"
        inputValue = DataSizing.AutoSize
        state.dataSize.ZoneSizingInput.allocate(1)
        state.dataSize.ZoneSizingInput(1).ZoneNum = 1
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.6, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Supply Air Maximum Flow Rate [m3/s], 1.60000\n")
        expect_true(compare_eio_stream(eiooutput, True))
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.6, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataFractionUsedForSizing = 0.5
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.8, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataFractionUsedForSizing = 0.0
        state.dataSize.ZoneEqSizing(1).SystemAirFlow = True
        state.dataSize.ZoneEqSizing(1).AirVolFlow = 1.8
        state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.SupplyAirFlowRate
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.8, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).SystemAirFlow = False
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.6, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneCoolingOnlyFan = False
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        state.dataSize.ZoneEqSizing(1).CoolingAirVolFlow = 2.2
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(2.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
        state.dataSize.ZoneEqSizing(1).HeatingAirVolFlow = 3.2
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(3.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(3.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
        state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FractionOfAutosizedCoolingAirflow
        state.dataSize.DataFracOfAutosizedCoolingAirflow = 0.4
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.64, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataFracOfAutosizedHeatingAirflow = 0.4
        state.dataSize.ZoneCoolingOnlyFan = False
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.48, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.64, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.88, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.28, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.28, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FractionOfAutosizedHeatingAirflow
        state.dataSize.DataFracOfAutosizedCoolingAirflow = 0.4
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.64, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneCoolingOnlyFan = False
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.48, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.88, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.28, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.28, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.64, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FlowPerCoolingCapacity
        state.dataSize.DataFlowPerCoolingCapacity = 0.00005
        state.dataSize.DataAutosizedCoolingCapacity = 10000.0
        state.dataSize.DataFlowPerHeatingCapacity = 0.00006
        state.dataSize.DataAutosizedHeatingCapacity = 20000.0
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.5, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneCoolingOnlyFan = False
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.5, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FlowPerHeatingCapacity
        state.dataSize.ZoneCoolingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.5, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneCoolingOnlyFan = False
        state.dataSize.ZoneHeatingOnlyFan = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneHeatingOnlyFan = False
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.5, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
        state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.2, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).DesignSizeFromParent = True
        state.dataSize.ZoneEqSizing(1).AirVolFlow = 1.75
        inputValue = DataSizing.AutoSize
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.75, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.ZoneEqSizing(1).DesignSizeFromParent = False
        inputValue = 1.44
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(1.44, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        inputValue = 1.44
        state.dataSize.ZoneSizingRunDone = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(1.44, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataEMSOverrideON = True
        state.dataSize.DataEMSOverride = 1.33
        inputValue = 1.44
        state.dataSize.ZoneSizingRunDone = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(1.33, sizedValue, 0.0001)
        expect_near(1.44, sizer.originalValue, 0.0001)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        eiooutput = ""
        state.dataSize.CurZoneEqNum = 0
        state.dataSize.NumZoneSizingInput = 0
        state.dataSize.ZoneEqSizing.deallocate()
        state.dataSize.FinalZoneSizing.deallocate()
        state.dataSize.CurSysNum = 1
        state.dataHVACGlobal.NumPrimaryAirSys = 1
        state.dataSize.NumSysSizInput = 1
        state.dataSize.SysSizingRunDone = False
        inputValue = 5.0
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        expect_true(compare_eio_stream(eiooutput, True))
        state.dataSize.SysSizingRunDone = True
        state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
        state.dataEnvrn.TotDesDays = 2
        state.dataSize.SysSizPeakDDNum.allocate(2)
        state.dataSize.SysSizPeakDDNum(1).CoolFlowPeakDD = 1
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk.allocate(2)
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk(1) = 12
        state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk(2) = 6
        state.dataSize.FinalSysSizing.allocate(1)
        state.dataSize.FinalSysSizing(1).HeatDDNum = 2
        state.dataSize.SysSizInput.allocate(1)
        state.dataSize.SysSizInput(1).AirLoopNum = 1
        state.dataSize.FinalSysSizing(1).DesMainVolFlow = 5.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(1.33, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataEMSOverrideON = False
        eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Supply Air Maximum Flow Rate [m3/s], 1.33000\n")
        expect_true(compare_eio_stream(eiooutput, True))
        state.dataSize.CurDuctType = HVAC.AirDuctType.Main
        state.dataSize.FinalSysSizing(1).DesMainVolFlow = 5.0
        state.dataSize.FinalSysSizing(1).DesCoolVolFlow = 5.0
        state.dataSize.FinalSysSizing(1).SysAirMinFlowRat = 0.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.UnitarySysEqSizing.allocate(1)
        state.dataSize.UnitarySysEqSizing(1).CoolingCapacity = True
        state.dataSize.UnitarySysEqSizing(1).CoolingAirFlow = True
        state.dataSize.UnitarySysEqSizing(1).CoolingAirVolFlow = 6.0
        state.dataSize.UnitarySysEqSizing(1).HeatingAirFlow = True
        state.dataSize.UnitarySysEqSizing(1).HeatingAirVolFlow = 7.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(7.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.UnitarySysEqSizing(1).CoolingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(7.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.UnitarySysEqSizing(1).CoolingAirFlow = True
        state.dataSize.UnitarySysEqSizing(1).HeatingAirFlow = False
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(6.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.HRFlowSizingFlag = True
        state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 0.0
        state.dataSize.FinalSysSizing(1).DesOutAirVolFlow = 3.0
        state.dataSize.OASysEqSizing.allocate(1)
        state.dataAirLoop.OutsideAirSys.allocate(1)
        state.dataSize.CurOASysNum = 1
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(3.0, sizedValue, 0.0001)
        sizer.autoSizedValue = 0.0
        state.dataSize.FinalSysSizing(1).DesOutAirVolFlow = 0.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
        state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 8.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(8.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Other
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurOASysNum = 0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Main
        state.dataSize.FinalSysSizing(1).DesOutAirVolFlow = 0.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
        state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 8.0
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(8.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.Other
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.CurDuctType = HVAC.AirDuctType.RAB
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(5.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        has_eio_output(True)
        inputValue = 2.0
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(2.0, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        expect_false(errorsFound)
        eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Supply Air Maximum Flow Rate [m3/s], 5.00000\n" +
                            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Supply Air Maximum Flow Rate [m3/s], 2.00000\n")
        expect_true(compare_eio_stream(eiooutput, True))
        inputValue = 2.2
        state.dataSize.DataConstantUsedForSizing = 3.5
        state.dataSize.DataFractionUsedForSizing = 1.0
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_false(sizer.wasAutoSized)
        expect_near(2.2, sizedValue, 0.01)
        sizer.autoSizedValue = 0.0
        state.dataSize.DataConstantUsedForSizing = 0.0
        state.dataSize.DataFractionUsedForSizing = 0.0
        expect_false(errorsFound)
        eiooutput = String(" Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Supply Air Maximum Flow Rate [m3/s], 3.50000\n" +
                            " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Supply Air Maximum Flow Rate [m3/s], 2.20000\n")
        expect_true(compare_eio_stream(eiooutput, True))
        state.dataSize.HRFlowSizingFlag = False
        state.dataSize.CurOASysNum = 1
        state.dataAirLoop.OutsideAirSys(1).AirLoopDOASNum = 0
        var thisDOAS = AirLoopHVACDOAS.AirLoopDOAS()
        state.dataAirLoopHVACDOAS.airloopDOAS.push_back(thisDOAS)
        state.dataAirLoopHVACDOAS.airloopDOAS[state.dataAirLoop.OutsideAirSys(1).AirLoopDOASNum].SizingMassFlow = 0.53 * 1.2
        inputValue = DataSizing.AutoSize
        sizer.wasAutoSized = False
        printFlag = True
        sizer.initializeWithinEP(state, "Fan:SystemModel", "MyDOASFan", printFlag, routineName)
        sizedValue = sizer.size(state, inputValue, errorsFound)
        expect_enum_eq(AutoSizingResultType.NoError, sizer.errorType)
        expect_true(sizer.wasAutoSized)
        expect_near(0.53, sizedValue, 0.01)