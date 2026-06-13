from testing import *
from EnergyPlus.Autosizing.CoolingAirFlowSizing import CoolingAirFlowSizer
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataSizing import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.HVAC import *
from AutosizingFixture import AutoSizingFixture, has_eio_output, compare_eio_stream

# gtest macros translated to Mojo test helpers
def EXPECT_TRUE(cond: Bool):
    assert_true(cond)

def EXPECT_FALSE(cond: Bool):
    assert_false(cond)

def EXPECT_ENUM_EQ[T: Equatable](expected: T, actual: T):
    assert_equal(expected, actual)

def EXPECT_NEAR(expected: Float64, actual: Float64, tol: Float64):
    assert_almost_equal(actual, expected, tol)

@test
def CoolingAirFlowSizingGauntlet(self: AutoSizingFixture):
    self.state.dataSize.ZoneEqSizing.allocate(1)
    let routineName = "CoolingAirFlowSizingGauntlet"
    self.state.dataEnvrn.StdRhoAir = 1.2
    var sizer = CoolingAirFlowSizer()
    var inputValue: Float64 = 5.0
    var errorsFound: Bool = False
    var printFlag: Bool = False
    var sizedValue: Float64 = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_TRUE(errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.ErrorType2, sizer.errorType)
    EXPECT_NEAR(0.0, sizedValue, 0.0001) # uninitialized sizing types always return 0
    errorsFound = False
    self.state.dataSize.CurZoneEqNum = 1
    self.state.dataSize.CurTermUnitSizingNum = 1
    self.state.dataSize.TermUnitSingDuct = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.0001) # hard-sized value
    sizer.autoSizedValue = 0.0           # reset for next test
    has_eio_output(True)
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.0001) # hard-sized value
    sizer.autoSizedValue = 0.0           # reset for next test
    var eiooutput: String = (
        "! <Component Sizing Information>, Component Type, Component Name, Input Field Description, Value\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Cooling Supply Air Flow Rate [m3/s], 5.00000\n"
    )
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    has_eio_output(True)
    self.state.dataSize.FinalZoneSizing.allocate(1)
    self.state.dataSize.ZoneEqSizing.allocate(1)
    self.state.dataSize.ZoneEqSizing(1).SizingMethod.allocate(35)
    self.state.dataSize.ZoneSizingRunDone = True
    self.state.dataSize.FinalZoneSizing(1).DesCoolVolFlow = 1.6
    self.state.dataSize.FinalZoneSizing(1).DesHeatVolFlow = 1.2
    self.state.dataSize.FinalZoneSizing(1).CoolDDNum = 1
    self.state.dataSize.FinalZoneSizing(1).HeatDDNum = 2
    self.state.dataSize.FinalZoneSizing(1).TimeStepNumAtCoolMax = 12
    self.state.dataSize.FinalZoneSizing(1).TimeStepNumAtHeatMax = 6
    self.state.dataGlobal.TimeStepsInHour = 1
    self.state.dataGlobal.MinutesInTimeStep = 60
    self.state.dataEnvrn.TotDesDays = 2
    self.state.dataWeather.DesDayInput.allocate(2)
    self.state.dataWeather.DesDayInput(1).Month = 7
    self.state.dataWeather.DesDayInput(1).DayOfMonth = 7
    self.state.dataWeather.DesDayInput(2).Month = 1
    self.state.dataWeather.DesDayInput(2).DayOfMonth = 1
    self.state.dataWeather.DesDayInput(1).Title = "CoolingDD"
    self.state.dataWeather.DesDayInput(2).Title = "HeatingDD"
    inputValue = DataSizing.AutoSize
    self.state.dataSize.ZoneSizingInput.allocate(1)
    self.state.dataSize.ZoneSizingInput(1).ZoneNum = 1
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.6, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    eiooutput = (
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Cooling Supply Air Flow Rate [m3/s], 1.60000\n"
    )
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.6, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.DataFractionUsedForSizing = 0.5
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.6, sizedValue, 0.0001)               # data fraction has no affect on cooling air flow rate
    sizer.autoSizedValue = 0.0                         # reset for next test
    self.state.dataSize.DataFractionUsedForSizing = 0.0 # reset for next test
    self.state.dataSize.ZoneEqSizing(1).SystemAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).AirVolFlow = 1.8
    self.state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.SupplyAirFlowRate
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.8, sizedValue, 0.0001) # max of zone cooling/heating/ZoneEqSizing
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).SystemAirFlow = False
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.6, sizedValue, 0.0001) # zone cooling flow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneCoolingOnlyFan = False
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # zone heating flow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).CoolingAirVolFlow = 2.2
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(2.2, sizedValue, 0.0001) # ZoneEqSizing cooling flow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).HeatingAirVolFlow = 3.2
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.2, sizedValue, 0.0001) # ZoneEqSizing heating flow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.2, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FractionOfAutosizedCoolingAirflow
    self.state.dataSize.DataFracOfAutosizedCoolingAirflow = 0.4
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.64, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.DataFracOfAutosizedHeatingAirflow = 0.4
    self.state.dataSize.ZoneCoolingOnlyFan = False
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.48, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.64, sizedValue, 0.0001) # max of FinalZoneSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.88, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.28, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.28, sizedValue, 0.0001) # max of FinalZoneSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FractionOfAutosizedHeatingAirflow
    self.state.dataSize.DataFracOfAutosizedCoolingAirflow = 0.4
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.64, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneCoolingOnlyFan = False
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.48, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.88, sizedValue, 0.0001) # max of ZoneEqSizing cooling flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.28, sizedValue, 0.0001) # max of ZoneEqSizing heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.28, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.64, sizedValue, 0.0001) # max of FinalZoneSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FlowPerCoolingCapacity
    self.state.dataSize.DataFlowPerCoolingCapacity = 0.00005
    self.state.dataSize.DataAutosizedCoolingCapacity = 10000.0
    self.state.dataSize.DataFlowPerHeatingCapacity = 0.00006
    self.state.dataSize.DataAutosizedHeatingCapacity = 20000.0
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.5, sizedValue, 0.0001) # flow per cooling capacity
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneCoolingOnlyFan = False
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # flow per heating capacity
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.5, sizedValue, 0.0001) # max of ZoneEqSizing cooling capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # ZoneEqSizing heating capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # max of ZoneEqSizing cooling/heating flow * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # max of autosized cooling/heating capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).SizingMethod[int(sizer.sizingType)] = DataSizing.FlowPerHeatingCapacity
    self.state.dataSize.ZoneCoolingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.5, sizedValue, 0.0001) # flow per cooling capacity
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneCoolingOnlyFan = False
    self.state.dataSize.ZoneHeatingOnlyFan = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # flow per heating capacity
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneHeatingOnlyFan = False
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(0.5, sizedValue, 0.0001) # max of autosized cooling capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = True
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # autosized heating capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = True
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # max of autosized cooling/heating capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.ZoneEqSizing(1).HeatingAirFlow = False
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.2, sizedValue, 0.0001) # max of autosized cooling/heating capacity * fraction
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.ZoneEqSizing(1).DesignSizeFromParent = True
    self.state.dataSize.ZoneEqSizing(1).AirVolFlow = 1.75
    inputValue = DataSizing.AutoSize
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.75, sizedValue, 0.0001) # parent passed size
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.ZoneEqSizing(1).DesignSizeFromParent = False
    inputValue = 1.44
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(1.44, sizedValue, 0.0001) # hard sized result
    sizer.autoSizedValue = 0.0            # reset for next test
    inputValue = 1.44
    self.state.dataSize.ZoneSizingRunDone = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(1.44, sizedValue, 0.0001) # hard sized result
    sizer.autoSizedValue = 0.0            # reset for next test
    self.state.dataSize.DataEMSOverrideON = True
    self.state.dataSize.DataEMSOverride = 1.33
    inputValue = 1.44
    self.state.dataSize.ZoneSizingRunDone = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(1.33, sizedValue, 0.0001)          # override result
    EXPECT_NEAR(1.44, sizer.originalValue, 0.0001) # original input
    sizer.autoSizedValue = 0.0                     # reset for next test
    has_eio_output(True)
    eiooutput = ""
    self.state.dataSize.CurZoneEqNum = 0
    self.state.dataSize.NumZoneSizingInput = 0
    self.state.dataSize.ZoneEqSizing.deallocate()
    self.state.dataSize.FinalZoneSizing.deallocate()
    self.state.dataSize.CurSysNum = 1
    self.state.dataHVACGlobal.NumPrimaryAirSys = 1
    self.state.dataSize.NumSysSizInput = 1
    self.state.dataSize.SysSizingRunDone = False
    inputValue = 5.0
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.0001) # hard-sized value
    sizer.autoSizedValue = 0.0           # reset for next test
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.SysSizingRunDone = True
    self.state.dataAirSystemsData.PrimaryAirSystems.allocate(1)
    self.state.dataEnvrn.TotDesDays = 2
    self.state.dataSize.SysSizPeakDDNum.allocate(2)
    self.state.dataSize.SysSizPeakDDNum(1).CoolFlowPeakDD = 1
    self.state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk.allocate(2)
    self.state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk(1) = 12
    self.state.dataSize.SysSizPeakDDNum(1).TimeStepAtCoolFlowPk(2) = 6
    self.state.dataSize.FinalSysSizing.allocate(1)
    self.state.dataSize.FinalSysSizing(1).HeatDDNum = 2
    self.state.dataSize.SysSizInput.allocate(1)
    self.state.dataSize.SysSizInput(1).AirLoopNum = 1
    self.state.dataSize.FinalSysSizing(1).DesMainVolFlow = 5.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(1.33, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.DataEMSOverrideON = False
    eiooutput = (
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Cooling Supply Air Flow Rate [m3/s], 1.33000\n"
    )
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.UnitarySysEqSizing.allocate(1)
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    self.state.dataSize.FinalSysSizing(1).DesMainVolFlow = 5.0
    self.state.dataSize.FinalSysSizing(1).DesCoolVolFlow = 5.0
    self.state.dataSize.FinalSysSizing(1).SysAirMinFlowRat = 0.0
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    printFlag = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.UnitarySysEqSizing(1).CoolingCapacity = True
    self.state.dataSize.UnitarySysEqSizing(1).CoolingAirFlow = True
    self.state.dataSize.UnitarySysEqSizing(1).CoolingAirVolFlow = 6.0
    self.state.dataSize.UnitarySysEqSizing(1).HeatingAirFlow = True
    self.state.dataSize.UnitarySysEqSizing(1).HeatingAirVolFlow = 7.0
    inputValue = DataSizing.AutoSize
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(6.0, sizedValue, 0.0001) # set by UnitarySysEqSizing(1).CoolingAirVolFlow
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.UnitarySysEqSizing(1).CoolingAirFlow = False
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    self.state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 7.2
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(7.2, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 0.0
    self.state.dataSize.FinalSysSizing(1).DesOutAirVolFlow = 3.0
    self.state.dataSize.OASysEqSizing.allocate(1)
    self.state.dataAirLoop.OutsideAirSys.allocate(1)
    self.state.dataSize.CurOASysNum = 1
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.0, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.OASysEqSizing(1).AirFlow = True
    self.state.dataSize.OASysEqSizing(1).AirVolFlow = 3.7
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.7, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.OASysEqSizing(1).AirFlow = False
    self.state.dataSize.OASysEqSizing(1).CoolingAirFlow = True
    self.state.dataSize.OASysEqSizing(1).CoolingAirVolFlow = 3.6
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(3.6, sizedValue, 0.0001)
    sizer.autoSizedValue = 0.0 # reset for next test
    self.state.dataSize.OASysEqSizing(1).CoolingAirFlow = False
    self.state.dataAirLoop.OutsideAirSys(1).AirLoopDOASNum = 0
    self.state.dataAirLoopHVACDOAS.airloopDOAS.emplace_back()
    self.state.dataAirLoopHVACDOAS.airloopDOAS[0].SizingMassFlow = 4.8
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(4.0, sizedValue, 0.0001) # 4.8 / 1.2 = 4
    sizer.autoSizedValue = 0.0           # reset for next test
    self.state.dataSize.CurOASysNum = 0
    self.state.dataSize.CurSysNum = 1
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Main
    self.state.dataSize.FinalSysSizing(1).DesMainVolFlow = 5.4
    self.state.dataSize.FinalSysSizing(1).DesCoolVolFlow = 5.3
    self.state.dataSize.FinalSysSizing(1).DesHeatVolFlow = 5.2
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.4, sizedValue, 0.01) # uses main flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Cooling
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.3, sizedValue, 0.01) # uses cooling flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Heating
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.2, sizedValue, 0.01) # uses heating flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.Other
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.4, sizedValue, 0.01) # uses a main flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.CurDuctType = HVAC.AirDuctType.RAB
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.4, sizedValue, 0.01) # uses main flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.DataAirFlowUsedForSizing = 5.8
    inputValue = DataSizing.AutoSize
    sizer.wasAutoSized = False
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType)
    EXPECT_TRUE(sizer.wasAutoSized)
    EXPECT_NEAR(5.8, sizedValue, 0.01) # uses cooling flow rate
    sizer.autoSizedValue = 0.0         # reset for next test
    has_eio_output(True)
    inputValue = 2.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType) # cumulative of previous calls
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2.0, sizedValue, 0.01) # hard-sized value
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.DataAirFlowUsedForSizing = 0.0
    EXPECT_FALSE(errorsFound)
    eiooutput = (
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Cooling Supply Air Flow Rate [m3/s], 5.80000\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Cooling Supply Air Flow Rate [m3/s], 2.00000\n"
    )
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    inputValue = 2.2
    self.state.dataSize.DataConstantUsedForSizing = 3.5
    self.state.dataSize.DataFractionUsedForSizing = 1.0
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType) # cumulative of previous calls
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2.2, sizedValue, 0.01) # hard-sized value
    sizer.autoSizedValue = 0.0         # reset for next test
    self.state.dataSize.DataConstantUsedForSizing = 0.0
    self.state.dataSize.DataFractionUsedForSizing = 0.0
    EXPECT_FALSE(errorsFound)
    eiooutput = (
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, Design Size Cooling Supply Air Flow Rate [m3/s], 3.50000\n"
        " Component Sizing Information, Coil:Heating:Water, MyWaterCoil, User-Specified Cooling Supply Air Flow Rate [m3/s], 2.20000\n"
    )
    EXPECT_TRUE(compare_eio_stream(eiooutput, True))
    self.state.dataSize.SysSizingRunDone = False
    inputValue = 2.9
    sizer.wasAutoSized = False
    printFlag = True
    sizer.initializeWithinEP(self.state, HVAC.coilTypeNames[int(HVAC.CoilType.HeatingWater)], "MyWaterCoil", printFlag, routineName)
    sizedValue = sizer.size(self.state, inputValue, errorsFound)
    EXPECT_ENUM_EQ(AutoSizingResultType.NoError, sizer.errorType) # cumulative of previous calls
    EXPECT_FALSE(sizer.wasAutoSized)
    EXPECT_NEAR(2.9, sizedValue, 0.01) # hard-sized value
    sizer.autoSizedValue = 0.0         # reset for next test