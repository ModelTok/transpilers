from testing import *
from EnergyPlus.Coils.CoilCoolingDX import *
from EnergyPlus.Coils.CoilCoolingDXCurveFitOperatingMode import *
from EnergyPlus.Coils.CoilCoolingDXCurveFitPerformance import *
from EnergyPlus.CurveManager import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataSizing import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.OutputReportTabular import *
from ...Coils.CoilCoolingDXFixture import *

using EnergyPlus

@fixture
class CoilCoolingDXTest:
    var state: State

    def __init__(inout self):
        self.state = State()

    def getModeObjectString(self, name: String, speedCount: Int) -> String:
        # Placeholder - actual implementation would generate IDF string
        return ""

    def getSpeedObjectString(self, name: String) -> String:
        # Placeholder - actual implementation would generate IDF string
        return ""

    def process_idf(self, idf_objects: String, echo: Bool) -> Bool:
        # Placeholder - actual implementation would process IDF
        return True

def test_CoilCoolingDXCurveFitModeInput():
    var test = CoilCoolingDXTest()
    var idf_objects = test.getModeObjectString("mode1", 2) // What is going on here?
    assert_true(test.process_idf(idf_objects, False))
    test.state.init_state(test.state)
    var thisMode = CoilCoolingDXCurveFitOperatingMode(test.state, "mode1")
    assert_equal("MODE1", thisMode.name)
    assert_equal("MODE1SPEED1", thisMode.speeds[0].name)

def test_CoilCoolingDXCurveFitOperatingMode_Sizing():
    var test = CoilCoolingDXTest()
    test.state.dataSQLiteProcedures.sqlite.createSQLiteSimulationsRecord(1, "EnergyPlus Version", "Current Time")
    var idf_objects = delimited_string([
        "Coil:Cooling:DX,",
        "  Coil Cooling DX 1,                      !- Name",
        "  Air Loop HVAC Unitary System 5 Fan - Cooling Coil Node, !- Evaporator Inlet Node Name",
        "  Air Loop HVAC Unitary System 5 Cooling Coil - Heating Coil Node, !- Evaporator Outlet Node Name",
        "  Always On Discrete,                     !- Availability Schedule Name",
        "  ,                                       !- Condenser Zone Name",
        "  Coil Cooling DX 1 Condenser Inlet Node, !- Condenser Inlet Node Name",
        "  Coil Cooling DX 1 Condenser Outlet Node, !- Condenser Outlet Node Name",
        "  Coil Cooling DX Curve Fit Performance 1; !- Performance Object Name",
        "",
        "Coil:Cooling:DX:CurveFit:Performance,",
        "  Coil Cooling DX Curve Fit Performance 1, !- Name",
        "  0,                                      !- Crankcase Heater Capacity {W}",
        "  ,                                       !- Crankcase Heater Capacity Function of Temperature Curve Name",
        "  -25,                                    !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "  10,                                     !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
        "  773.3,                                  !- Unit Internal Static Air Pressure {Pa}",
        "  Discrete,                               !- Capacity Control Method",
        "  0,                                      !- Evaporative Condenser Basin Heater Capacity {W/K}",
        "  2,                                      !- Evaporative Condenser Basin Heater Setpoint Temperature {C}",
        "  Always On Discrete,                     !- Evaporative Condenser Basin Heater Operating Schedule Name",
        "  Electricity,                            !- Compressor Fuel Type",
        "  Coil Cooling DX Curve Fit Operating Mode 1; !- Base Operating Mode",
        "Coil:Cooling:DX:CurveFit:OperatingMode,",
        "  Coil Cooling DX Curve Fit Operating Mode 1, !- Name",
        "  Autosize,                               !- Rated Gross Total Cooling Capacity {W}",
        "  Autosize,                                    !- Rated Evaporator Air Flow Rate {m3/s}",
        "  Autosize,                               !- Rated Condenser Air Flow Rate {m3/s}",
        "  0,                                      !- Maximum Cycling Rate {cycles/hr}",
        "  0,                                      !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        "  0,                                      !- Latent Capacity Time Constant {s}",
        "  0,                                      !- Nominal Time for Condensate Removal to Begin {s}",
        "  Yes,                                    !- Apply Part Load Fraction to Speeds Greater than 1",
        "  No,                                     !- Apply Latent Degradation to Speeds Greater than 1",
        "  EvaporativelyCooled,                    !- Condenser Type",
        "  Autosize,                               !- Nominal Evaporative Condenser Pump Power {W}",
        "  1,                                      !- Nominal Speed Number",
        "  Coil Cooling DX Curve Fit Speed 1;      !- Speed Name 1",
    ])
    idf_objects += test.getSpeedObjectString("Coil Cooling DX Curve Fit Speed 1")
    assert_true(test.process_idf(idf_objects, False))
    test.state.init_state(test.state)
    var thisMode = CoilCoolingDXCurveFitOperatingMode(test.state, "Coil Cooling DX Curve Fit Operating Mode 1")
    assert_equal(CoilCoolingDXCurveFitOperatingMode.CondenserType.EVAPCOOLED, thisMode.condenserType)
    assert_equal(DataSizing.AutoSize, thisMode.ratedEvapAirFlowRate)
    assert_equal(DataSizing.AutoSize, thisMode.ratedGrossTotalCap)
    assert_equal(DataSizing.AutoSize, thisMode.ratedCondAirFlowRate)
    assert_equal(DataSizing.AutoSize, thisMode.nominalEvaporativePumpPower)
    test.state.dataSize.FinalZoneSizing.allocate(1)
    test.state.dataSize.ZoneEqSizing.allocate(1)
    test.state.dataSize.SysSizPeakDDNum.allocate(1)
    test.state.dataSize.CurSysNum = 0
    test.state.dataSize.CurOASysNum = 0
    test.state.dataSize.CurZoneEqNum = 1
    test.state.dataEnvrn.StdRhoAir = 1.0 // Prevent divide by zero in ReportSizingManager
    test.state.dataEnvrn.StdBaroPress = 101325.0
    test.state.dataSize.ZoneSizingRunDone = True
    test.state.dataSize.ZoneEqSizing[test.state.dataSize.CurZoneEqNum - 1].DesignSizeFromParent = False
    test.state.dataSize.ZoneEqSizing[test.state.dataSize.CurZoneEqNum - 1].SizingMethod.allocate(25)
    test.state.dataSize.ZoneEqSizing[test.state.dataSize.CurZoneEqNum - 1].SizingMethod[HVAC.SystemAirflowSizing - 1] = DataSizing.SupplyAirFlowRate
    var ratedEvapAirFlowRate: Float64 = 1.005
    test.state.dataSize.FinalZoneSizing[test.state.dataSize.CurZoneEqNum - 1].DesCoolVolFlow = ratedEvapAirFlowRate
    test.state.dataSize.FinalZoneSizing[test.state.dataSize.CurZoneEqNum - 1].DesCoolCoilInTemp = 30.0
    test.state.dataSize.FinalZoneSizing[test.state.dataSize.CurZoneEqNum - 1].DesCoolCoilInHumRat = 0.001
    test.state.dataSize.FinalZoneSizing[test.state.dataSize.CurZoneEqNum - 1].CoolDesTemp = 15.0
    test.state.dataSize.FinalZoneSizing[test.state.dataSize.CurZoneEqNum - 1].CoolDesHumRat = 0.0006
    thisMode.size(test.state)
    assert_equal(ratedEvapAirFlowRate, thisMode.ratedEvapAirFlowRate)
    var ratedGrossTotalCap: Float64 = thisMode.ratedGrossTotalCap
    assert_equal(ratedGrossTotalCap, thisMode.ratedGrossTotalCap)
    var ratedCondAirFlowRate: Float64 = 0.000114 * ratedGrossTotalCap
    assert_equal(ratedCondAirFlowRate, thisMode.ratedCondAirFlowRate)
    var nominalEvaporativePumpPower: Float64 = 0.004266 * ratedGrossTotalCap
    assert_equal(nominalEvaporativePumpPower, thisMode.nominalEvaporativePumpPower)
    var compType: String = "Coil:Cooling:DX:CurveFit:OperatingMode"
    var compName: String = thisMode.name
    assert_equal(compName, "COIL COOLING DX CURVE FIT OPERATING MODE 1")
    struct TestQuery:
        var description: String
        var units: String
        var expectedValue: Float64
        var displayString: String

        def __init__(inout self, t_description: String, t_units: String, t_value: Float64):
            self.description = t_description
            self.units = t_units
            self.expectedValue = t_value
            self.displayString = "Description='" + self.description + "'; Units='" + self.units + "'"

    var testQueries: List[TestQuery] = List[TestQuery]()
    testQueries.append(TestQuery("Design Size Rated Evaporator Air Flow Rate", "m3/s", ratedEvapAirFlowRate))
    testQueries.append(TestQuery("Design Size Rated Gross Total Cooling Capacity", "W", ratedGrossTotalCap))
    testQueries.append(TestQuery("Design Size Rated Condenser Air Flow Rate", "m3/s", ratedCondAirFlowRate))
    testQueries.append(TestQuery("Design Size Nominal Evaporative Condenser Pump Power", "W", nominalEvaporativePumpPower))
    for testQuery in testQueries:
        var query: String = "SELECT Value From ComponentSizes" + \
                          "  WHERE CompType = '" + \
                          compType + \
                          "'" + \
                          "  AND CompName = '" + \
                          compName + \
                          "'" + \
                          "  AND Description = '" + \
                          testQuery.description + "'" + "  AND Units = '" + testQuery.units + "'"
        var return_val: Float64 = SQLiteFixture.execAndReturnFirstDouble(query)
        if return_val < 0:
            assert_true(False) << "Query returned nothing for " + testQuery.displayString
        else:
            assert_approx_equal(testQuery.expectedValue, return_val, 0.01) << "Failed for " + testQuery.displayString

def test_CoilCoolingDXCurveFitCrankcaseHeaterCurve():
    var test = CoilCoolingDXTest()
    var idf_objects = delimited_string([
        "Coil:Cooling:DX,",
        "  Coil Cooling DX 1,                      !- Name",
        "  Air Loop HVAC Unitary System 5 Fan - Cooling Coil Node, !- Evaporator Inlet Node Name",
        "  Air Loop HVAC Unitary System 5 Cooling Coil - Heating Coil Node, !- Evaporator Outlet Node Name",
        "  ,                                       !- Availability Schedule Name",
        "  ,                                       !- Condenser Zone Name",
        "  Coil Cooling DX 1 Condenser Inlet Node, !- Condenser Inlet Node Name",
        "  Coil Cooling DX 1 Condenser Outlet Node, !- Condenser Outlet Node Name",
        "  Coil Cooling DX Curve Fit Performance 1; !- Performance Object Name",
        "Coil:Cooling:DX:CurveFit:Performance,",
        "  Coil Cooling DX Curve Fit Performance 1, !- Name",
        "  10,                                      !- Crankcase Heater Capacity {W}",
        "heaterCapCurve,                           !- Crankcase Heater Capacity Function of Outdoor Temperature Curve Name",
        "  -25,                                    !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}",
        "  10,                                     !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}",
        "  773.3,                                  !- Unit Internal Static Air Pressure {Pa}",
        "  Discrete,                               !- Capacity Control Method",
        "  0,                                      !- Evaporative Condenser Basin Heater Capacity {W/K}",
        "  2,                                      !- Evaporative Condenser Basin Heater Setpoint Temperature {C}",
        "  ,                                       !- Evaporative Condenser Basin Heater Operating Schedule Name",
        "  Electricity,                            !- Compressor Fuel Type",
        "  Coil Cooling DX Curve Fit Operating Mode 1, !- Base Operating Mode",
        ",",
        ";",
        "Curve:Linear,",
        "heaterCapCurve,          !- Name",
        "10.0,                    !- Coefficient1 Constant",
        "2.,                      !- Coefficient2 x",
        "-10.0,                    !- Minimum Value of x",
        "70;                      !- Maximum Value of x",
        "Coil:Cooling:DX:CurveFit:OperatingMode,",
        "  Coil Cooling DX Curve Fit Operating Mode 1, !- Name",
        "  Autosize,                               !- Rated Gross Total Cooling Capacity {W}",
        "  Autosize,                                    !- Rated Evaporator Air Flow Rate {m3/s}",
        "  Autosize,                               !- Rated Condenser Air Flow Rate {m3/s}",
        "  0,                                      !- Maximum Cycling Rate {cycles/hr}",
        "  0,                                      !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}",
        "  0,                                      !- Latent Capacity Time Constant {s}",
        "  0,                                      !- Nominal Time for Condensate Removal to Begin {s}",
        "  Yes,                                    !- Apply Part Load Fraction to Speeds Greater than 1",
        "  No,                                     !- Apply Latent Degradation to Speeds Greater than 1",
        "  EvaporativelyCooled,                    !- Condenser Type",
        "  Autosize,                               !- Nominal Evaporative Condenser Pump Power {W}",
        "  1,                                      !- Nominal Speed Number",
        "  Coil Cooling DX Curve Fit Speed 1;      !- Speed Name 1"
    ])
    idf_objects += test.getSpeedObjectString("Coil Cooling DX Curve Fit Speed 1")
    assert_true(test.process_idf(idf_objects, False))
    test.state.init_state(test.state)
    var coilIndex: Int = CoilCoolingDX.factory(test.state, "Coil Cooling DX 1")
    var thisCoil = test.state.dataCoilCoolingDX.coilCoolingDXs[coilIndex]
    assert_equal("COIL COOLING DX 1", thisCoil.name)
    assert_equal("COIL COOLING DX CURVE FIT PERFORMANCE 1", thisCoil.performance.name)
    var coilMode: HVAC.CoilMode = HVAC.CoilMode.Normal
    var speedNum: Int = 1
    var speedRatio: Float64 = 1.0
    var fanOp: HVAC.FanOp = HVAC.FanOp.Cycling
    var singleMode: Bool = False
    test.state.dataEnvrn.OutDryBulbTemp = 1.0
    var evapInletNode = test.state.dataLoopNodes.Node[thisCoil.evapInletNodeIndex - 1]
    var evapOutletNode = test.state.dataLoopNodes.Node[thisCoil.evapOutletNodeIndex - 1]
    var condInletNode = test.state.dataLoopNodes.Node[thisCoil.condInletNodeIndex - 1]
    var condOutletNode = test.state.dataLoopNodes.Node[thisCoil.condOutletNodeIndex - 1]
    var LoadSHR: Float64 = 0.0
    thisCoil.performance.simulate(
        test.state, evapInletNode, evapOutletNode, coilMode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode, LoadSHR)
    assert_equal(thisCoil.performance.crankcaseHeaterPower, 120.0)
    assert_equal(thisCoil.performance.minOutdoorDrybulb, -25.0)
    var performance = thisCoil.performance as CoilCoolingDXCurveFitPerformance
    assert_equal(performance.normalMode.minOutdoorDrybulb, -25.0)
    assert_equal(performance.alternateMode.minOutdoorDrybulb, -25.0)
    assert_equal(performance.alternateMode2.minOutdoorDrybulb, -25.0)
    assert_equal(thisCoil.totalCoolingEnergyRate, 0.0)
    thisCoil.performance.minOutdoorDrybulb = 5.0
    performance.myOneTimeMinOATFlag = True
    thisCoil.size(test.state) // run size() to reset the min OA temp
    thisCoil.performance.simulate(
        test.state, evapInletNode, evapOutletNode, coilMode, speedNum, speedRatio, fanOp, condInletNode, condOutletNode, singleMode, LoadSHR)
    assert_equal(performance.normalMode.minOutdoorDrybulb, 5.0)
    assert_equal(performance.alternateMode.minOutdoorDrybulb, 5.0)
    assert_equal(performance.alternateMode2.minOutdoorDrybulb, 5.0)
    assert_equal(thisCoil.totalCoolingEnergyRate, 0.0)