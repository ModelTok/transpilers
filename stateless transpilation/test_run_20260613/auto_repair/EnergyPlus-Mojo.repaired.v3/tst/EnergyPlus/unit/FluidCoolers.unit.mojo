from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataSizing import DataSizing, AutoSize
from EnergyPlus.FluidCoolers import (
    FluidCoolerspecs,
    PerfInputMethod,
    SimpleFluidCoolerData,
    GetFluidCoolerInput,
)
from EnergyPlus.Plant.DataPlant import DataPlant, PlantLocation, LoopSideLocation, LoopDemandCalcScheme, FlowLock
from EnergyPlus.PlantUtilities import PlantUtilities, SetPlantLocationLinks
from EnergyPlus.UtilityRoutines import UtilityRoutines
from EnergyPlus.Fluid import Fluid

# Define simple test functions to replace gtest macros
def EXPECT_TRUE(condition: Bool):
    if not condition:
        raise Error("EXPECT_TRUE failed")

def EXPECT_FALSE(condition: Bool):
    if condition:
        raise Error("EXPECT_FALSE failed")

def EXPECT_EQ(a: Int, b: Int):
    if a != b:
        raise Error("EXPECT_EQ failed: " + str(a) + " != " + str(b))

def EXPECT_EQ(a: Float64, b: Float64, epsilon: Float64 = 1e-9):
    if abs(a - b) > epsilon:
        raise Error("EXPECT_EQ failed: " + str(a) + " != " + str(b))

def EXPECT_EQ(a: String, b: String):
    if a != b:
        raise Error("EXPECT_EQ failed: " + a + " != " + b)

def EXPECT_NEAR(a: Float64, b: Float64, tolerance: Float64):
    if abs(a - b) > tolerance:
        raise Error("EXPECT_NEAR failed: " + str(a) + " != " + str(b) + " within " + str(tolerance))

def EXPECT_ENUM_EQ(a: PerfInputMethod, b: PerfInputMethod):
    if a != b:
        raise Error("EXPECT_ENUM_EQ failed")

def ASSERT_TRUE(condition: Bool):
    if not condition:
        raise Error("ASSERT_TRUE failed")

# Helper function for delimited_string (assume it's imported from somewhere)
def delimited_string(lines: List[String]) -> String:
    var result = String()
    for line in lines:
        result += line + "\n"
    return result

class Array1D_string:
    var data: List[String]
    
    def __init__(inout self):
        self.data = List[String]()
    
    def allocate(inout self, size: Int):
        self.data = List[String](repeating="", count=size)
    
    def deallocate(inout self):
        self.data = List[String]()
    
    def __getitem__(self, index: Int) -> String:
        return self.data[index - 1]  # 1-based to 0-based
    
    def __setitem__(inout self, index: Int, value: String):
        self.data[index - 1] = value

# The test fixture class
class TwoSpeedFluidCoolerInput_Test1(EnergyPlusFixture):
    def run_test(inout self):
        self.state.init_state(self.state)
        # using DataSizing::AutoSize
        var StringArraySize: Int = 20
        var cNumericFieldNames = Array1D_string()
        cNumericFieldNames.allocate(StringArraySize)
        var cAlphaFieldNames = Array1D_string()
        cAlphaFieldNames.allocate(StringArraySize)
        var AlphArray = Array1D_string()
        AlphArray.allocate(StringArraySize)
        for i in range(1, StringArraySize + 1):
            cAlphaFieldNames[i] = "AlphaField"
            cNumericFieldNames[i] = "NumerField"
            AlphArray[i] = "FieldValues"
        var cCurrentModuleObject = String("FluidCooler:TwoSpeed")
        var FluidCoolerNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler.allocate(FluidCoolerNum)
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].Name = "Test"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerMassFlowRateMultiplier = 2.5
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].PerformanceInputMethod_Num = PerfInputMethod.NOMINAL_CAPACITY
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].WaterInletNodeNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].WaterOutletNodeNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerNominalCapacity = 50000.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringWaterTemp = 52.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirTemp = 35.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirWetBulbTemp = 25.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPower = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPowerWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedAirFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedAirFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFanPower = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFanPowerWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerLowSpeedNomCap = 30000.0
        AlphArray[4] = "NominalCapacity"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUA = 0.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFluidCoolerUA = 0.0
        self.state.dataFluidCoolers.SimpleFluidCooler[1].DesignEnteringWaterTemp = 50.0
        var testResult: Bool = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[1].DesignEnteringWaterTemp = -10.0
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_TRUE(testResult)  # error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[1].DesignEnteringWaterTemp = 50.0
        self.state.dataFluidCoolers.SimpleFluidCooler[1].FluidCoolerLowSpeedNomCap = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[1].FluidCoolerLowSpeedNomCapWasAutoSized = True
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[1].FluidCoolerLowSpeedNomCap = 0.0  # this should trigger the original error condition
        self.state.dataFluidCoolers.SimpleFluidCooler[1].FluidCoolerLowSpeedNomCapWasAutoSized = False
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_TRUE(testResult)  # error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler.deallocate()

class TwoSpeedFluidCoolerInput_Test2(EnergyPlusFixture):
    def run_test(inout self):
        self.state.init_state(self.state)
        var StringArraySize: Int = 20
        var cNumericFieldNames = Array1D_string()
        cNumericFieldNames.allocate(StringArraySize)
        var cAlphaFieldNames = Array1D_string()
        cAlphaFieldNames.allocate(StringArraySize)
        var AlphArray = Array1D_string()
        AlphArray.allocate(StringArraySize)
        for i in range(1, StringArraySize + 1):
            cAlphaFieldNames[i] = "AlphaField"
            cNumericFieldNames[i] = "NumerField"
            AlphArray[i] = "FieldValues"
        var cCurrentModuleObject = String("FluidCooler:TwoSpeed")
        var FluidCoolerNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler.allocate(FluidCoolerNum)
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].Name = "Test"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerMassFlowRateMultiplier = 1.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].PerformanceInputMethod_Num = PerfInputMethod.U_FACTOR
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringWaterTemp = 52.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirTemp = 35.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirWetBulbTemp = 25.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPower = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPowerWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedAirFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedAirFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFanPower = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFanPowerWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerLowSpeedNomCap = 30000.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFluidCoolerUA = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].LowSpeedFluidCoolerUAWasAutoSized = True
        AlphArray[4] = "UFactorTimesAreaAndDesignWaterFlowRate"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUA = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUAWasAutoSized = False
        var testResult: Bool = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_TRUE(testResult)  # error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUA = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUAWasAutoSized = True
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateTwoSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler.deallocate()
        cNumericFieldNames.deallocate()
        cAlphaFieldNames.deallocate()
        AlphArray.deallocate()

class SingleSpeedFluidCoolerInput_Test3(EnergyPlusFixture):
    def run_test(inout self):
        self.state.init_state(self.state)
        var StringArraySize: Int = 20
        var cNumericFieldNames = Array1D_string()
        cNumericFieldNames.allocate(StringArraySize)
        var cAlphaFieldNames = Array1D_string()
        cAlphaFieldNames.allocate(StringArraySize)
        var AlphArray = Array1D_string()
        AlphArray.allocate(StringArraySize)
        for i in range(1, StringArraySize + 1):
            cAlphaFieldNames[i] = "AlphaField"
            cNumericFieldNames[i] = "NumerField"
            AlphArray[i] = "FieldValues"
        var cCurrentModuleObject = String("FluidCooler:SingleSpeed")
        var FluidCoolerNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler.allocate(FluidCoolerNum)
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].Name = "Test"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerMassFlowRateMultiplier = 2.5
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].PerformanceInputMethod_Num = PerfInputMethod.U_FACTOR
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].WaterInletNodeNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].WaterOutletNodeNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].FluidCoolerNominalCapacity = 50000.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringWaterTemp = 52.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirTemp = 35.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignEnteringAirWetBulbTemp = 25.0
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRate = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedAirFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPower = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFanPowerWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUA = AutoSize
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].HighSpeedFluidCoolerUAWasAutoSized = True
        AlphArray[4] = "UFactorTimesAreaAndDesignWaterFlowRate"
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = 1.0
        var testResult: Bool = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateSingleSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = True
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = 0.0
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateSingleSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = False
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = 1.0
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateSingleSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_FALSE(testResult)  # no error message triggered
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRateWasAutoSized = False
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].DesignWaterFlowRate = 0.0
        testResult = self.state.dataFluidCoolers.SimpleFluidCooler[1].validateSingleSpeedInputs(
            self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames
        )
        EXPECT_TRUE(testResult)  # error message triggered

class SingleSpeedFluidCoolerInput_Test4(EnergyPlusFixture):
    def run_test(inout self):
        var FluidCoolerNum = 1
        var idf_objects = delimited_string([
            "   FluidCooler:SingleSpeed,",
            "     FluidCooler_SingleSpeed, !- Name",
            "     FluidCooler_SingleSpeed Water Inlet,  !- Water Inlet Node Name",
            "     FluidCooler_SingleSpeed Water Outlet,  !- Water Outlet Node Name",
            "     UFactorTimesAreaAndDesignWaterFlowRate,  !- Performance Input Method",
            "     autosize,                !- Design Air Flow Rate U-factor Times Area Value {W/K}",
            "     ,                        !- Nominal Capacity {W}",
            "     46.0,                    !- Design Entering Water Temperature {C}",
            "     35.0,                    !- Design Entering Air Temperature {C}",
            "     25.5,                    !- Design Entering Air Wetbulb Temperature {C}",
            "     5.05e-03,                 !- Design Water Flow Rate {m3/s}",
            "     autosize,                !- Design Air Flow Rate {m3/s}",
            "     autosize;                !- Design Air Flow Rate Fan Power {W}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        GetFluidCoolerInput(self.state)
        var thisFluidCooler = self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum]
        EXPECT_TRUE(thisFluidCooler.HighSpeedFluidCoolerUAWasAutoSized)
        EXPECT_EQ(thisFluidCooler.HighSpeedFluidCoolerUA, DataSizing.AutoSize)
        EXPECT_EQ(thisFluidCooler.FluidCoolerNominalCapacity, 0.0)

class SingleSpeedFluidCoolerInput_Test5(EnergyPlusFixture):
    def run_test(inout self):
        self.state.init_state(self.state)
        var StringArraySize: Int = 20
        var cNumericFieldNames = Array1D_string()
        cNumericFieldNames.allocate(StringArraySize)
        var cAlphaFieldNames = Array1D_string()
        cAlphaFieldNames.allocate(StringArraySize)
        var AlphArray = Array1D_string()
        AlphArray.allocate(StringArraySize)
        for i in range(1, StringArraySize + 1):
            cAlphaFieldNames[i] = "AlphaField"
            cNumericFieldNames[i] = "NumerField"
            AlphArray[i] = "FieldValues"
        var cCurrentModuleObject = String("FluidCooler:SingleSpeed")
        var FluidCoolerNum = 1
        self.state.dataFluidCoolers.SimpleFluidCooler.allocate(FluidCoolerNum)
        var thisFluidCooler = self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum]
        thisFluidCooler.Name = "Test"
        thisFluidCooler.FluidCoolerMassFlowRateMultiplier = 2.5
        thisFluidCooler.WaterInletNodeNum = 1
        thisFluidCooler.WaterOutletNodeNum = 1
        thisFluidCooler.DesignEnteringWaterTemp = 52.0
        thisFluidCooler.DesignEnteringAirTemp = 35.0
        thisFluidCooler.DesignEnteringAirWetBulbTemp = 25.0
        thisFluidCooler.HighSpeedAirFlowRate = AutoSize
        thisFluidCooler.HighSpeedAirFlowRateWasAutoSized = True
        thisFluidCooler.HighSpeedFanPower = AutoSize
        thisFluidCooler.HighSpeedFanPowerWasAutoSized = True
        thisFluidCooler.DesignWaterFlowRateWasAutoSized = True
        thisFluidCooler.DesignWaterFlowRate = 1.0
        AlphArray[4] = "NominalCapacity"
        thisFluidCooler.FluidCoolerNominalCapacity = 5000.0
        thisFluidCooler.HighSpeedFluidCoolerUA = 500.0
        thisFluidCooler.HighSpeedFluidCoolerUAWasAutoSized = False
        var testResult: Bool = thisFluidCooler.validateSingleSpeedInputs(self.state, cCurrentModuleObject, AlphArray, cNumericFieldNames, cAlphaFieldNames)
        EXPECT_FALSE(testResult)  # no error message triggered
        EXPECT_ENUM_EQ(thisFluidCooler.PerformanceInputMethod_Num, PerfInputMethod.NOMINAL_CAPACITY)
        EXPECT_EQ(thisFluidCooler.HighSpeedFluidCoolerUA, 0.0)

class FluidCooler_SizeWhenPlantSizingIndexIsZero(EnergyPlusFixture):
    def run_test(inout self):
        var FluidCoolerNum = 1
        var idf_objects = delimited_string([
            "   FluidCooler:SingleSpeed,",
            "     Dry Cooler,              !- Name",
            "     Dry Cooler Inlet Node,   !- Water Inlet Node Name",
            "     Dry Cooler Outlet Node,  !- Water Outlet Node Name",
            "     NominalCapacity,         !- Performance Input Method",
            "     ,                        !- Design Air Flow Rate U-factor Times Area Value {W/K}",
            "     58601,                   !- Nominal Capacity {W}",
            "     50,                      !- Design Entering Water Temperature {C}",
            "     35,                      !- Design Entering Air Temperature {C}",
            "     25,                      !- Design Entering Air Wetbulb Temperature {C}",
            "     0.001262,                !- Design Water Flow Rate {m3/s}",
            "     2.124,                   !- Design Air Flow Rate {m3/s}",
            "     1491;                    !- Design Air Flow Rate Fan Power {W}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        GetFluidCoolerInput(self.state)
        var thisFluidCooler = self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum]
        self.state.dataPlnt.PlantLoop.allocate(FluidCoolerNum)
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum].plantLoc.loopNum = 1
        self.state.dataPlnt.PlantLoop[1].PlantSizNum = 0
        thisFluidCooler.plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, thisFluidCooler.plantLoc)
        EXPECT_EQ("DRY COOLER", thisFluidCooler.Name)
        EXPECT_FALSE(thisFluidCooler.HighSpeedFanPowerWasAutoSized)
        EXPECT_FALSE(thisFluidCooler.HighSpeedAirFlowRateWasAutoSized)
        EXPECT_FALSE(thisFluidCooler.HighSpeedFluidCoolerUAWasAutoSized)
        thisFluidCooler.size(self.state)

class ExerciseSingleSpeedFluidCooler(EnergyPlusFixture):
    def run_test(inout self):
        var idf_objects = delimited_string([
            "   FluidCooler:SingleSpeed,",
            "     Dry Cooler,              !- Name",
            "     Dry Cooler Inlet Node,   !- Water Inlet Node Name",
            "     Dry Cooler Outlet Node,  !- Water Outlet Node Name",
            "     NominalCapacity,         !- Performance Input Method",
            "     ,                        !- Design Air Flow Rate U-factor Times Area Value {W/K}",
            "     58601,                   !- Nominal Capacity {W}",
            "     50,                      !- Design Entering Water Temperature {C}",
            "     35,                      !- Design Entering Air Temperature {C}",
            "     25,                      !- Design Entering Air Wetbulb Temperature {C}",
            "     0.001262,                !- Design Water Flow Rate {m3/s}",
            "     2.124,                   !- Design Air Flow Rate {m3/s}",
            "     1491;                    !- Design Air Flow Rate Fan Power {W}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        var ptr = FluidCoolerspecs.factory(self.state, DataPlant.PlantEquipmentType.FluidCooler_SingleSpd, "DRY COOLER")
        var pl = PlantLocation(1, LoopSideLocation.Supply, 1, 1)
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch.allocate(1)
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp.allocate(1)
        var max: Float64
        var opt: Float64
        var min: Float64 = 0.0
        ptr.getDesignCapacities(self.state, pl, max, min, opt)
        EXPECT_NEAR(max, 58601.0, 1.0)
        EXPECT_NEAR(min, 0.0, 1.0)
        EXPECT_NEAR(opt, 58601.0, 1.0)
        self.state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = LoopDemandCalcScheme.SingleSetPoint
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].TempSetPoint = 2.0
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp[1].MyLoad = 1000.0
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp[1].ON = True
        self.state.dataPlnt.PlantLoop[1].MaxVolFlowRate = 3.0
        self.state.dataPlnt.PlantLoop[1].MaxMassFlowRate = 3.0
        self.state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMaxAvail = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMax = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].Temp = 20.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMaxAvail = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMax = 5.0
        EXPECT_EQ(0, ptr.OutdoorAirInletNodeNum)
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.OutHumRat = 0.0001
        var firstHVAC: Bool = True
        var curLoad: Float64 = 0.0
        ptr.plantLoc.loopNum = 1
        ptr.plantLoc.loopSideNum = LoopSideLocation.Supply
        ptr.plantLoc.branchNum = 1
        ptr.plantLoc.compNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, ptr.plantLoc)
        ptr.DesWaterMassFlowRate = 3.141
        ptr.WaterMassFlowRate = 3.141
        ptr.onInitLoopEquip(self.state, pl)
        ptr.HighSpeedFluidCoolerUA = 10.0
        ptr.simulate(self.state, pl, firstHVAC, curLoad, True)

class ExerciseTwoSpeedFluidCooler(EnergyPlusFixture):
    def run_test(inout self):
        var idf_objects = delimited_string([
            "FluidCooler:TwoSpeed,",
            "Big FluidCooler,         !- Name",
            "Condenser FluidCooler Inlet Node,  !- Water Inlet Node Name",
            "Condenser FluidCooler Outlet Node,  !- Water Outlet Node Name",
            "NominalCapacity,         !- Performance Input Method",
            ",                        !- High Fan Speed U-factor Times Area Value {W/K}",
            ",                        !- Low Fan Speed U-factor Times Area Value {W/K}",
            ",                        !- Low Fan Speed U-Factor Times Area Sizing Factor",
            "58601.,                  !- High Speed Nominal Capacity {W}",
            "28601.,                  !- Low Speed Nominal Capacity {W}",
            ",                        !- Low Speed Nominal Capacity Sizing Factor",
            "51.67,                   !- Design Entering Water Temperature {C}",
            "35,                      !- Design Entering Air Temperature {C}",
            "25.6,                    !- Design Entering Air Wet-bulb Temperature {C}",
            "Autosize,                !- Design Water Flow Rate {m3/s}",
            "Autosize,                !- High Fan Speed Air Flow Rate {m3/s}",
            "Autosize,                !- High Fan Speed Fan Power {W}",
            "autocalculate,           !- Low Fan Speed Air Flow Rate {m3/s}",
            ",                        !- Low Fan Speed Air Flow Rate Sizing Factor",
            "autocalculate,           !- Low Fan Speed Fan Power {W}",
            ";                        !- Low Fan Speed Fan Power Sizing Factor",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        self.state.init_state(self.state)
        var ptr = FluidCoolerspecs.factory(self.state, DataPlant.PlantEquipmentType.FluidCooler_TwoSpd, "BIG FLUIDCOOLER")
        var pl = PlantLocation(1, LoopSideLocation.Supply, 1, 1)
        self.state.dataPlnt.PlantLoop.allocate(1)
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch.allocate(1)
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp.allocate(1)
        var max: Float64
        var opt: Float64
        var min: Float64 = 0.0
        ptr.getDesignCapacities(self.state, pl, max, min, opt)
        EXPECT_NEAR(max, 58601.0, 1.0)
        EXPECT_NEAR(min, 0.0, 1.0)
        EXPECT_NEAR(opt, 58601.0, 1.0)
        self.state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = LoopDemandCalcScheme.SingleSetPoint
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].TempSetPoint = 2.0
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp[1].MyLoad = 1000.0
        self.state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Supply].Branch[1].Comp[1].ON = True
        self.state.dataPlnt.PlantLoop[1].MaxVolFlowRate = 3.0
        self.state.dataPlnt.PlantLoop[1].MaxMassFlowRate = 3.0
        self.state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMaxAvail = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterOutletNodeNum].MassFlowRateMax = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].Temp = 20.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMaxAvail = 5.0
        self.state.dataLoopNodes.Node[ptr.WaterInletNodeNum].MassFlowRateMax = 5.0
        EXPECT_EQ(0, ptr.OutdoorAirInletNodeNum)
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.OutHumRat = 0.0001
        var firstHVAC: Bool = True
        var curLoad: Float64 = 0.0
        ptr.plantLoc.loopNum = 1
        ptr.plantLoc.loopSideNum = LoopSideLocation.Supply
        ptr.plantLoc.branchNum = 1
        ptr.plantLoc.compNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, ptr.plantLoc)
        ptr.DesWaterMassFlowRate = 3.141
        ptr.WaterMassFlowRate = 3.141
        ptr.HighSpeedAirFlowRate = 2.124  # Autosizing didn't occur so...
        self.state.dataSize.PlantSizData.allocate(1)
        self.state.dataSize.PlantSizData[1].ExitTemp = 25.0
        self.state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        ptr.onInitLoopEquip(self.state, pl)
        ptr.HighSpeedFluidCoolerUA = 10.0
        ptr.simulate(self.state, pl, firstHVAC, curLoad, True)
        self.state.dataPlnt.PlantLoop[pl.loopNum].LoopSide[pl.loopSideNum].FlowLock = FlowLock.Locked
        ptr.simulate(self.state, pl, firstHVAC, curLoad, True)

class FluidCooler_SizeWhenPlantSizingIndexIsZeroAndAutosized(EnergyPlusFixture):
    def run_test(inout self):
        var idf_objects = delimited_string([
            "   FluidCooler:SingleSpeed,",
            "     Dry Cooler,              !- Name",
            "     Dry Cooler Inlet Node,   !- Water Inlet Node Name",
            "     Dry Cooler Outlet Node,  !- Water Outlet Node Name",
            "     NominalCapacity,         !- Performance Input Method",
            "     Autosize,                !- Design Air Flow Rate U-factor Times Area Value {W/K}",
            "     58601,                   !- Nominal Capacity {W}",
            "     50,                      !- Design Entering Water Temperature {C}",
            "     35,                      !- Design Entering Air Temperature {C}",
            "     25,                      !- Design Entering Air Wetbulb Temperature {C}",
            "     Autosize,                !- Design Water Flow Rate {m3/s}",
            "     Autosize,                !- Design Air Flow Rate {m3/s}",
            "     Autosize;                !- Design Air Flow Rate Fan Power {W}",
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        GetFluidCoolerInput(self.state)
        var FluidCoolerNum = 1
        self.state.dataPlnt.PlantLoop.allocate(FluidCoolerNum)
        self.state.dataPlnt.PlantLoop[FluidCoolerNum].PlantSizNum = 0
        var thisFluidCooler = self.state.dataFluidCoolers.SimpleFluidCooler[FluidCoolerNum]
        thisFluidCooler.plantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, thisFluidCooler.plantLoc)
        self.state.dataPlnt.PlantFirstSizesOkayToFinalize = False
        EXPECT_TRUE(thisFluidCooler.DesignWaterFlowRateWasAutoSized)
        EXPECT_TRUE(thisFluidCooler.HighSpeedFanPowerWasAutoSized)
        EXPECT_TRUE(thisFluidCooler.HighSpeedAirFlowRateWasAutoSized)
        EXPECT_TRUE(thisFluidCooler.HighSpeedFluidCoolerUAWasAutoSized)
        thisFluidCooler.size(self.state)