from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from ...ChillerElectricEIR import GetElectricEIRChillerInput, ElectricEIRChillerData, ChillerElectricEIR
from ...CurveManager import Curve
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironmentState
from ...DataLoopNode import NodeData
from ...DataSizing import PlantSizingData
from ...FluidProperties import Fluid
from ...General import General
from ...OutputReportPredefined import OutputReportPredefined
from ...Plant.DataPlant import DataPlant
from ...Plant.Enums import PlantEquipmentType, LoopDemandCalcScheme, CondenserFlowControl
from ...PlantUtilities import PlantUtilities
from ...Psychrometrics import Psychrometrics
from ...Data.Constant import Constant
@test
def ChillerElectricEIR_TestNegativeCurveRoundingError():
    state.dataPlnt.TotNumLoops = 2
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    let idf_objects = delimited_string([
        "Chiller:Electric:EIR,",
        "    Big Chiller,             !- Name",
        "    25000,                   !- Reference Capacity {W}",
        "    2.75,                    !- Reference COP {W/W}",
        "    6.67,                    !- Reference Leaving Chilled Water Temperature {C}",
        "    29.4,                    !- Reference Entering Condenser Fluid Temperature {C}",
        "    0.001075,                !- Reference Chilled Water Flow Rate {m3/s}",
        "    0.001345,                !- Reference Condenser Fluid Flow Rate {m3/s}",
        "    ChillerCentCapFT,        !- Cooling Capacity Function of Temperature Curve Name",
        "    ChillerCentEIRFT,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
        "    ChillerCentEIRFPLR,      !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "    0.15,                    !- Minimum Part Load Ratio",
        "    1.0,                     !- Maximum Part Load Ratio",
        "    1.0,                     !- Optimum Part Load Ratio",
        "    0.25,                    !- Minimum Unloading Ratio",
        "    Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
        "    Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
        "    Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name",
        "    Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name",
        "    WaterCooled,             !- Condenser Type",
        "    ,                        !- Condenser Fan Power Ratio {W/W}",
        "    ,                        !- Fraction of Compressor Electric Consumption Rejected by Condenser",
        "    5,                       !- Leaving Chilled Water Lower Temperature Limit {C}",
        "    NotModulated,            !- Chiller Flow Mode",
        "    0.0,                     !- Design Heat Recovery Water Flow Rate {m3/s}",
        "    ,                        !- Heat Recovery Inlet Node Name",
        "    ;                        !- Heat Recovery Outlet Node Name",
        "  Curve:Biquadratic,",
        "    ChillerCentCapFT,        !- Name",
        "    0.257896E+00,            !- Coefficient1 Constant",
        "    0.389016E-01,            !- Coefficient2 x",
        "    -0.217080E-03,           !- Coefficient3 x**2",
        "    0.468684E-01,            !- Coefficient4 y",
        "    -0.942840E-03,           !- Coefficient5 y**2",
        "    -0.343440E-03,           !- Coefficient6 x*y",
        "    5.0,                     !- Minimum Value of x",
        "    10.0,                    !- Maximum Value of x",
        "    24.0,                    !- Minimum Value of y",
        "    35.0,                    !- Maximum Value of y",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Temperature,             !- Input Unit Type for X",
        "    Temperature,             !- Input Unit Type for Y",
        "    Dimensionless;           !- Output Unit Type",
        "  Curve:Biquadratic,",
        "    ChillerCentEIRFT,        !- Name",
        "    0.933884E+00,            !- Coefficient1 Constant",
        "    -0.582120E-01,           !- Coefficient2 x",
        "    0.450036E-02,            !- Coefficient3 x**2",
        "    0.243000E-02,            !- Coefficient4 y",
        "    0.486000E-03,            !- Coefficient5 y**2",
        "    -0.121500E-02,           !- Coefficient6 x*y",
        "    5.0,                     !- Minimum Value of x",
        "    10.0,                    !- Maximum Value of x",
        "    24.0,                    !- Minimum Value of y",
        "    35.0,                    !- Maximum Value of y",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Temperature,             !- Input Unit Type for X",
        "    Temperature,             !- Input Unit Type for Y",
        "    Dimensionless;           !- Output Unit Type",
        "  Curve:Quadratic,",
        "    ChillerCentEIRFPLR,      !- Name",
        "    -0.11519596634680696,                     !- Coefficient1 Constant",
        "    0.6582045440515927,                     !- Coefficient2 x",
        "    0.3663655959196781,                     !- Coefficient3 x**2",
        "    0.15,                     !- Minimum Value of x",
        "    1.0;                     !- Maximum Value of x",
        "  Curve:Biquadratic,",
        "    ChillerRecipCapFT,       !- Name",
        "    0.507883E+00,            !- Coefficient1 Constant",
        "    0.145228E+00,            !- Coefficient2 x",
        "    -0.625644E-02,           !- Coefficient3 x**2",
        "    -0.111780E-02,           !- Coefficient4 y",
        "    -0.129600E-03,           !- Coefficient5 y**2",
        "    -0.281880E-03,           !- Coefficient6 x*y",
        "    5.0,                     !- Minimum Value of x",
        "    10.0,                    !- Maximum Value of x",
        "    24.0,                    !- Minimum Value of y",
        "    35.0,                    !- Maximum Value of y",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Temperature,             !- Input Unit Type for X",
        "    Temperature,             !- Input Unit Type for Y",
        "    Dimensionless;           !- Output Unit Type",
        "  Curve:Biquadratic,",
        "    ChillerRecipEIRFT,       !- Name",
        "    0.103076E+01,            !- Coefficient1 Constant",
        "    -0.103536E+00,           !- Coefficient2 x",
        "    0.710208E-02,            !- Coefficient3 x**2",
        "    0.931860E-02,            !- Coefficient4 y",
        "    0.317520E-03,            !- Coefficient5 y**2",
        "    -0.104328E-02,           !- Coefficient6 x*y",
        "    5.0,                     !- Minimum Value of x",
        "    10.0,                    !- Maximum Value of x",
        "    24.0,                    !- Minimum Value of y",
        "    35.0,                    !- Maximum Value of y",
        "    ,                        !- Minimum Curve Output",
        "    ,                        !- Maximum Curve Output",
        "    Temperature,             !- Input Unit Type for X",
        "    Temperature,             !- Input Unit Type for Y",
        "    Dimensionless;           !- Output Unit Type",
        "  Curve:Quadratic,",
        "    ChillerRecipEIRFPLR,     !- Name",
        "    0.088065,                !- Coefficient1 Constant",
        "    1.137742,                !- Coefficient2 x",
        "    -0.225806,               !- Coefficient3 x**2",
        "    0.0,                     !- Minimum Value of x",
        "    1.0;                     !- Maximum Value of x",
    ])
    assert process_idf(idf_objects, false)
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    try:
        GetElectricEIRChillerInput(state)
        assert False, "Expected FatalError"
    except EnergyPlus.FatalError:

    assert compare_err_stream_substring("0.00,   0.00", true, false) == false

@test
def ChillerElectricEIR_TestOutletNodeConditions():
    state.dataChillerElectricEIR.ElectricEIRChiller.allocate(1)
    var thisEIR = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    thisEIR.EvapInletNodeNum = 1
    thisEIR.EvapOutletNodeNum = 2
    thisEIR.CondInletNodeNum = 3
    thisEIR.CondOutletNodeNum = 4
    thisEIR.HeatRecInletNodeNum = 5
    thisEIR.HeatRecOutletNodeNum = 6
    state.dataLoopNodes.Node.allocate(6)
    state.dataLoopNodes.Node[thisEIR.EvapInletNodeNum - 1].Temp = 18.0
    state.dataLoopNodes.Node[thisEIR.CondInletNodeNum - 1].Temp = 35.0
    thisEIR.update(state, -2000, true)
    assert thisEIR.EvapOutletTemp == 18
    assert thisEIR.CondOutletTemp == 35
    state.dataLoopNodes.Node.deallocate()

@test
def ElectricEIRChiller_HeatRecoveryAutosizeTest():
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(2)
    state.dataSize.PlantSizData.allocate(2)
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantLoop[1].PlantSizNum = 2
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataSize.PlantSizData[1].DesVolFlowRate = 1.0
    state.dataSize.PlantSizData[1].DeltaT = 5.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataChillerElectricEIR.ElectricEIRChiller.allocate(1)
    var thisEIR = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    thisEIR.SizFac = 1.0
    thisEIR.DesignHeatRecVolFlowRateWasAutoSized = true
    thisEIR.HeatRecCapacityFraction = 0.5
    thisEIR.HeatRecActive = true
    thisEIR.CondenserType = DataPlant.CondenserType.WaterCooled
    thisEIR.CWPlantLoc.loopNum = 1
    PlantUtilities.SetPlantLocationLinks(state, thisEIR.CWPlantLoc)
    thisEIR.CDPlantLoc.loopNum = 2
    PlantUtilities.SetPlantLocationLinks(state, thisEIR.CDPlantLoc)
    thisEIR.EvapVolFlowRate = 1.0
    thisEIR.CondVolFlowRate = 1.0
    thisEIR.RefCap = 10000
    thisEIR.RefCOP = 3.0
    thisEIR.size(state)
    assert abs(thisEIR.DesignHeatRecVolFlowRate - 0.5) < 0.00001
    state.dataSize.PlantSizData.deallocate()
    state.dataPlnt.PlantLoop.deallocate()

@test
def ChillerElectricEIR_AirCooledChiller():
    let RunFlag = true
    var MyLoad = -10000.0
    state.dataPlnt.TotNumLoops = 2
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    let idf_objects = delimited_string([
        "Chiller:Electric:EIR,",
        "  AirCooledChiller,                   !- Name",
        "  autosize,                           !- Reference Capacity {W}",
        "  5.50,                               !- Reference COP {W/W}",
        "  6.67,                               !- Reference Leaving Chilled Water Temperature {C}",
        "  29.40,                              !- Reference Entering Condenser Fluid Temperature {C}",
        "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
        "  autosize,                           !- Reference Condenser Fluid Flow Rate {m3/s}",
        "  Air cooled CentCapFT,               !- Cooling Capacity Function of Temperature Curve Name",
        "  Air cooled CentEIRFT,               !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
        "  Air cooled CentEIRFPLR,             !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "  0.25,                               !- Minimum Part Load Ratio",
        "  1.00,                               !- Maximum Part Load Ratio",
        "  1.00,                               !- Optimum Part Load Ratio",
        "  0.25,                               !- Minimum Unloading Ratio",
        "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
        "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
        "  Outdoor Air Condenser Inlet Node,   !- Condenser Inlet Node Name",
        "  Outdoor Air Condenser Outlet Node,  !- Condenser Outlet Node Name",
        "  AirCooled,                          !- Condenser Type",
        "  0.04,                               !- Condenser Fan Power Ratio {W/W}",
        "  1.00,                               !- Fraction of Compressor Electric Consumption Rejected by Condenser",
        "  5.00,                               !- Leaving Chilled Water Lower Temperature Limit {C}",
        "  NotModulated,                       !- Chiller Flow Mode",
        "  0.0,                                !- Design Heat Recovery Water Flow Rate {m3/s}",
        "  ,                                   !- Heat Recovery Inlet Node Name",
        "  ,                                   !- Heat Recovery Outlet Node Name",
        "  1.00,                               !- Sizing Factor",
        "  0.00,                               !- Basin Heater Capacity {W/K}",
        "  2.00,                               !- Basin Heater Setpoint Temperature {C}",
        "  ,                                   !- Basin Heater Operating Schedule Name",
        "  1.00,                               !- Condenser Heat Recovery Relative Capacity Fraction",
        "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
        "  ,                                   !- Heat Recovery Leaving Temperature Setpoint Node Name",
        "  ,                                   !- End-Use Subcategory",
        "  ,                                   !- Condenser Flow Control",
        "  ,                                   !- Condenser Loop Flow Rate Fraction Function of Loop Part Load Ratio Curve Name",
        "  ,                                   !- Temperature Difference Across Condenser Schedule Name",
        "  ,                                   !- Condenser Minimum Flow Fraction",
        "  ThermoCapFracCurve;                 !- Thermosiphon Capacity Fraction Curve Name",
        "Curve:Linear, ThermoCapFracCurve, 0.0, 0.06, 0.0, 10.0, 0.0, 1.0, Dimensionless, Dimensionless;",
        "Curve:Biquadratic, Air cooled CentCapFT, 0.257896, 0.0389016, -0.00021708, 0.0468684, -0.00094284, -0.00034344, 5, 10, 24, 35, , , , , ;",
        "Curve:Biquadratic, Air cooled CentEIRFT, 0.933884, -0.058212,  0.00450036, 0.00243,    0.000486,   -0.001215,   5, 10, 24, 35, , , , , ;",
        "Curve:Quadratic, Air cooled CentEIRFPLR, 0.222903,  0.313387,  0.46371,    0, 1, , , , ;",
    ])
    assert process_idf(idf_objects, false)
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    GetElectricEIRChillerInput(state)
    var thisEIR = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisEIR.Name
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisEIR.EvapInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisEIR.EvapOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataPlnt.PlantLoop[0].TempSetPointNodeNum = thisEIR.EvapOutletNodeNum
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFirstSizesOkayToReport = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    thisEIR.initialize(state, RunFlag, MyLoad)
    thisEIR.size(state)
    state.dataGlobal.BeginEnvrnFlag = true
    thisEIR.initialize(state, RunFlag, MyLoad)
    assert abs(thisEIR.EvapMassFlowRateMax - 0.999898) < 0.0000001
    let CalcCondVolFlow = thisEIR.RefCap * 0.000114
    assert CalcCondVolFlow == thisEIR.CondVolFlowRate
    assert abs(thisEIR.CondVolFlowRate - 2.3925760323498) < 0.0000001
    assert abs(thisEIR.CondMassFlowRateMax - 2.7918772761695) < 0.0000001
    state.dataLoopNodes.Node[thisEIR.EvapInletNodeNum - 1].Temp = 10.0
    state.dataLoopNodes.Node[thisEIR.EvapOutletNodeNum - 1].Temp = 6.0
    state.dataLoopNodes.Node[thisEIR.EvapOutletNodeNum - 1].TempSetPoint = 6.0
    state.dataLoopNodes.Node[thisEIR.CondInletNodeNum - 1].OutAirDryBulb = 12.0
    thisEIR.initialize(state, RunFlag, MyLoad)
    thisEIR.calculate(state, MyLoad, RunFlag)
    assert thisEIR.ChillerPartLoadRatio > 0.4
    assert thisEIR.thermosiphonStatus == 0
    assert thisEIR.Power > 1500.0
    state.dataLoopNodes.Node[thisEIR.CondInletNodeNum - 1].OutAirDryBulb = 5.0
    thisEIR.initialize(state, RunFlag, MyLoad)
    thisEIR.calculate(state, MyLoad, RunFlag)
    assert thisEIR.ChillerPartLoadRatio > 0.4
    assert thisEIR.thermosiphonStatus == 0
    assert thisEIR.Power > 1500.0
    MyLoad /= 25.0
    thisEIR.initialize(state, RunFlag, MyLoad)
    thisEIR.calculate(state, MyLoad, RunFlag)
    let dT = thisEIR.EvapOutletTemp - thisEIR.CondInletTemp
    let thermosiphonCapFrac = Curve.CurveValue(state, thisEIR.thermosiphonTempCurveIndex, dT)
    assert thisEIR.ChillerPartLoadRatio < 0.3
    assert thermosiphonCapFrac > thisEIR.ChillerPartLoadRatio
    assert thisEIR.thermosiphonStatus == 1
    assert thisEIR.Power == 0.0

@test
def ChillerElectricEIR_EvaporativelyCooled_Calculate():
    let idf_objects = delimited_string([
        "Chiller:Electric:EIR,",
        "  EvapCooledChiller,                  !- Name",
        "  autosize,                           !- Reference Capacity {W}",
        "  5.50,                               !- Reference COP {W/W}",
        "  6.67,                               !- Reference Leaving Chilled Water Temperature {C}",
        "  29.40,                              !- Reference Entering Condenser Fluid Temperature {C}",
        "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
        "  autosize,                           !- Reference Condenser Fluid Flow Rate {m3/s}",
        "  Evap cooled CentCapFT,              !- Cooling Capacity Function of Temperature Curve Name",
        "  Evap cooled CentEIRFT,              !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
        "  Evap cooled CentEIRFPLR,            !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "  0.10,                               !- Minimum Part Load Ratio",
        "  1.00,                               !- Maximum Part Load Ratio",
        "  1.00,                               !- Optimum Part Load Ratio",
        "  0.25,                               !- Minimum Unloading Ratio",
        "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
        "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
        "  OutdoorAir Condenser Inlet Node,    !- Condenser Inlet Node Name",
        "  OutdoorAir Condenser Outlet Node,   !- Condenser Outlet Node Name",
        "  EvaporativelyCooled,                !- Condenser Type",
        "  0.04,                               !- Condenser Fan Power Ratio {W/W}",
        "  1.00,                               !- Fraction of Compressor Electric Consumption Rejected by Condenser",
        "  5.00,                               !- Leaving Chilled Water Lower Temperature Limit {C}",
        "  NotModulated,                       !- Chiller Flow Mode",
        "  0.0,                                !- Design Heat Recovery Water Flow Rate {m3/s}",
        "  ,                                   !- Heat Recovery Inlet Node Name",
        "  ,                                   !- Heat Recovery Outlet Node Name",
        "  1.00,                               !- Sizing Factor",
        "  0.00,                               !- Basin Heater Capacity {W/K}",
        "  2.00,                               !- Basin Heater Setpoint Temperature {C}",
        "  ,                                   !- Basin Heater Operating Schedule Name",
        "  1.00,                               !- Condenser Heat Recovery Relative Capacity Fraction",
        "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
        "  ;                                   !- Heat Recovery Leaving Temperature Setpoint Node Name",
        "Curve:Biquadratic, Evap cooled CentCapFT, 0.257896, 0.0389016, -0.00021708, 0.0468684, -0.00094284, -0.00034344, 5, 10, 24, 35, , , , , ;",
        "Curve:Biquadratic, Evap cooled CentEIRFT, 0.933884, -0.058212,  0.00450036, 0.00243,    0.000486,   -0.001215,   5, 10, 24, 35, , , , , ;",
        "Curve:Quadratic, Evap cooled CentEIRFPLR, 0.222903,  0.313387,  0.46371,    0, 1, , , , ;",
    ])
    assert process_idf(idf_objects, false)
    state.dataPlnt.TotNumLoops = 2
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    GetElectricEIRChillerInput(state)
    var thisEIRChiller = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisEIRChiller.Name
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisEIRChiller.EvapInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisEIRChiller.EvapOutletNodeNum
    state.dataSize.PlantSizData.allocate(1)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFirstSizesOkayToReport = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    state.dataEnvrn.OutDryBulbTemp = 29.4
    state.dataEnvrn.OutWetBulbTemp = 23.0
    state.dataEnvrn.OutHumRat = Psychrometrics.PsyWFnTdbTwbPb(state, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutWetBulbTemp, state.dataEnvrn.OutBaroPress)
    state.dataLoopNodes.Node[thisEIRChiller.CondInletNodeNum - 1].Temp = state.dataEnvrn.OutDryBulbTemp
    state.dataLoopNodes.Node[thisEIRChiller.CondInletNodeNum - 1].OutAirWetBulb = state.dataEnvrn.OutWetBulbTemp
    state.dataLoopNodes.Node[thisEIRChiller.CondInletNodeNum - 1].HumRat = state.dataEnvrn.OutHumRat
    let RunFlag = true
    var MyLoad = -18000.0
    openOutputFiles(state)
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataLoopNodes.Node[thisEIRChiller.EvapOutletNodeNum - 1].TempSetPoint = 6.67
    state.dataLoopNodes.Node[thisEIRChiller.EvapInletNodeNum - 1].Temp = 16.0
    thisEIRChiller.initialize(state, RunFlag, MyLoad)
    thisEIRChiller.size(state)
    state.dataGlobal.BeginEnvrnFlag = true
    thisEIRChiller.initialize(state, RunFlag, MyLoad)
    assert abs(thisEIRChiller.EvapMassFlowRateMax - 0.999898) < 0.0000001
    let resultCondVolFlowRate = thisEIRChiller.RefCap * 0.000114
    assert resultCondVolFlowRate == thisEIRChiller.CondVolFlowRate
    assert abs(thisEIRChiller.CondVolFlowRate - 2.3925760323498) < 0.0000001
    assert abs(thisEIRChiller.CondMassFlowRateMax - 2.7918772761695) < 0.0000001
    thisEIRChiller.calculate(state, MyLoad, RunFlag)
    let EvapCondWaterVolFlowRate = thisEIRChiller.CondMassFlowRate * (thisEIRChiller.CondOutletHumRat - state.dataEnvrn.OutHumRat) / Psychrometrics.RhoH2O(Constant.InitConvTemp)
    assert abs(thisEIRChiller.CondMassFlowRate - 2.31460814) < 0.0000001
    assert abs(EvapCondWaterVolFlowRate - 6.22019725E-06) < 0.000000001
    assert abs(EvapCondWaterVolFlowRate - thisEIRChiller.EvapWaterConsumpRate) < 0.000000001

@test
def ChillerElectricEIR_WaterCooledChillerVariableSpeedCondenser():
    let RunFlag = true
    state.dataPlnt.TotNumLoops = 2
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.dataGlobal.HourOfDay = 1
    state.dataEnvrn.DayOfWeek = 1
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    let idf_objects = delimited_string([
        "Chiller:Electric:EIR,",
        "  WaterChiller,                       !- Name",
        "  autosize,                           !- Reference Capacity {W}",
        "  1.0,                               !- Reference COP {W/W}",
        "  6.67,                               !- Reference Leaving Chilled Water Temperature {C}",
        "  29.40,                              !- Reference Entering Condenser Fluid Temperature {C}",
        "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
        "  0.001,                              !- Reference Condenser Fluid Flow Rate {m3/s}",
        "  DummyCapfT,                         !- Cooling Capacity Function of Temperature Curve Name",
        "  DummyEIRfT,                         !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
        "  DummyEIRfPLR,                       !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "  0.10,                               !- Minimum Part Load Ratio",
        "  1.00,                               !- Maximum Part Load Ratio",
        "  1.00,                               !- Optimum Part Load Ratio",
        "  0.25,                               !- Minimum Unloading Ratio",
        "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
        "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
        "  Condenser Inlet Node,               !- Condenser Inlet Node Name",
        "  Condenser Outlet Node,              !- Condenser Outlet Node Name",
        "  WaterCooled,                        !- Condenser Type",
        "  0.04,                               !- Condenser Fan Power Ratio {W/W}",
        "  1.00,                               !- Fraction of Compressor Electric Consumption Rejected by Condenser",
        "  5.00,                               !- Leaving Chilled Water Lower Temperature Limit {C}",
        "  NotModulated,                       !- Chiller Flow Mode",
        "  0.0,                                !- Design Heat Recovery Water Flow Rate {m3/s}",
        "  ,                                   !- Heat Recovery Inlet Node Name",
        "  ,                                   !- Heat Recovery Outlet Node Name",
        "  1.00,                               !- Sizing Factor",
        "  0.00,                               !- Basin Heater Capacity {W/K}",
        "  2.00,                               !- Basin Heater Setpoint Temperature {C}",
        "  ,                                   !- Basin Heater Operating Schedule Name",
        "  1.00,                               !- Condenser Heat Recovery Relative Capacity Fraction",
        "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
        "  ,                                   !- Heat Recovery Leaving Temperature Setpoint Node Name",
        "  ,                                   !- End-Use Subcategory",
        "  ModulatedLoopPLR,                   !- Condenser Flow Control",
        "  Y=F(X),                             !- Condenser Loop Flow Rate Fraction Function of Loop Part Load Ratio Curve Name",
        "  CondenserdT,                        !- Temperature Difference Across Condenser Schedule Name",
        "  0.35;                               !- Condenser Minimum Flow Fraction",
        "Curve:Linear,Y=F(X),0,1,0,1;",
        "Schedule:Constant,CondenserdT,,10;"
        "Curve:Biquadratic, DummyCapfT, 1, 0, 0, 0, 0, 0, 5, 10, 24, 35, , , , , ;",
        "Curve:Biquadratic, DummyEIRfT, 1, 0,  0, 0, 0, 0,   5, 10, 24, 35, , , , , ;",
        "Curve:Quadratic, DummyEIRfPLR, 1,  0,  0, 0, 1, , , , ;",
    ])
    assert process_idf(idf_objects, false)
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    GetElectricEIRChillerInput(state)
    var thisChiller = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    state.dataLoopNodes.Node.allocate(10)
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].TempSetPointNodeNum = 10
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisChiller.EvapInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisChiller.EvapOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataPlnt.PlantLoop[0].LoopSide(EnergyPlus.DataPlant.LoopSideLocation.Demand).TempSetPoint = 4.4
    state.dataSize.PlantSizData.allocate(2)
    state.dataSize.PlantSizData[0].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantLoop[1].Name = "CondenserWaterLoop"
    state.dataPlnt.PlantLoop[1].PlantSizNum = 1
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisChiller.CondInletNodeNum
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisChiller.CondOutletNodeNum
    state.dataSize.PlantSizData[1].DesVolFlowRate = 0.001
    state.dataSize.PlantSizData[1].DeltaT = 5.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFirstSizesOkayToReport = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    var MyLoad = 0.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.size(state)
    MyLoad = -thisChiller.RefCap
    state.dataSize.PlantSizData[0].DesCapacity = abs(MyLoad) * 2
    Sched.UpdateScheduleVals(state)
    state.dataGlobal.BeginEnvrnFlag = true
    thisChiller.initialize(state, RunFlag, MyLoad)
    state.dataLoopNodes.Node[thisChiller.CondInletNodeNum - 1].Temp = 25.0
    state.dataLoopNodes.Node[thisChiller.EvapInletNodeNum - 1].Temp = 15.0
    thisChiller.CWPlantLoc.side.UpdatedDemandToLoopSetPoint = MyLoad
    state.dataLoopNodes.Node[thisChiller.CWPlantLoc.loop.TempSetPointNodeNum - 1].TempSetPoint = 21.0
    thisChiller.calculate(state, MyLoad, RunFlag)
    assert abs(thisChiller.CondMassFlowRate - thisChiller.CondMassFlowRateMax / 2) < 0.00001
    thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedChillerPLR
    MyLoad /= 2
    thisChiller.calculate(state, MyLoad, RunFlag)
    assert abs(thisChiller.CondMassFlowRate - thisChiller.CondMassFlowRateMax / 2) < 0.00001
    thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedDeltaTemperature
    thisChiller.calculate(state, MyLoad, RunFlag)
    let Cp = thisChiller.CWPlantLoc.loop.glycol.getSpecificHeat(state, thisChiller.CondInletTemp, "ChillerElectricEIR_WaterCooledChillerVariableSpeedCondenser")
    let ActualCondFlow = 3.0 * abs(MyLoad) / (Cp * 10.0)
    assert abs(thisChiller.CondMassFlowRate - ActualCondFlow) < 0.00001
    MyLoad = -500
    thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedChillerPLR
    thisChiller.calculate(state, MyLoad, RunFlag)
    assert abs(thisChiller.CondMassFlowRate - thisChiller.CondMassFlowRateMax * 0.35) < 0.00001
    thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ConstantFlow
    MyLoad = -10000
    let savedMyLoad = MyLoad
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.calculate(state, MyLoad, RunFlag)
    thisChiller.update(state, MyLoad, RunFlag)
    let chWOutletTemp = thisChiller.EvapInletTemp + savedMyLoad / (Cp * thisChiller.EvapMassFlowRate)
    let condOutletTemp = thisChiller.CondInletTemp + thisChiller.QCondenser / (Cp * thisChiller.CondMassFlowRate)
    assert MyLoad == savedMyLoad
    assert abs(thisChiller.CondMassFlowRate - thisChiller.CondMassFlowRateMax) < 0.00001
    assert abs(thisChiller.EvapMassFlowRate - thisChiller.EvapMassFlowRateMax) < 0.00001
    assert abs(thisChiller.EvapOutletTemp - chWOutletTemp) < 0.1
    assert abs(thisChiller.CondOutletTemp - condOutletTemp) < 0.1
    assert abs(thisChiller.QEvaporator - (-savedMyLoad)) < 1.0
    assert abs(thisChiller.QCondenser - (-savedMyLoad + thisChiller.Power)) < 1.0
    assert abs(thisChiller.Power - 20987) < 1.0
    state.dataLoopNodes.Node[thisChiller.CondInletNodeNum - 1].MassFlowRate = 0.0
    state.dataLoopNodes.Node[thisChiller.CondInletNodeNum - 1].MassFlowRateMaxAvail = 0.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.calculate(state, MyLoad, RunFlag)
    thisChiller.update(state, MyLoad, RunFlag)
    assert MyLoad == 0.0
    assert thisChiller.CondMassFlowRate == 0.0
    assert thisChiller.EvapMassFlowRate == 0.0
    assert thisChiller.EvapOutletTemp == thisChiller.EvapInletTemp
    assert thisChiller.CondOutletTemp == thisChiller.CondInletTemp
    assert thisChiller.QEvaporator == 0.0
    assert thisChiller.QCondenser == 0.0
    assert thisChiller.Power == 0.0

@test
def ChillerElectricEIR_OutputReport():
    let RunFlag = true
    state.dataPlnt.TotNumLoops = 3
    state.dataEnvrn.OutBaroPress = 101325.0
    state.dataEnvrn.StdRhoAir = 1.20
    state.dataGlobal.TimeStepsInHour = 1
    state.dataGlobal.TimeStep = 1
    state.dataGlobal.MinutesInTimeStep = 60
    state.dataGlobal.HourOfDay = 1
    state.dataEnvrn.DayOfWeek = 1
    state.dataEnvrn.Month = 1
    state.dataEnvrn.DayOfMonth = 1
    state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
    Psychrometrics.InitializePsychRoutines(state)
    let idf_objects = delimited_string([
        "Chiller:Electric:EIR,",
        "  WaterChiller,                       !- Name",
        "  autosize,                           !- Reference Capacity {W}",
        "  3.5,                                !- Reference COP {W/W}",
        "  5.67,                               !- Reference Leaving Chilled Water Temperature {C}",
        "  28.40,                              !- Reference Entering Condenser Fluid Temperature {C}",
        "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
        "  autosize,                           !- Reference Condenser Fluid Flow Rate {m3/s}",
        "  DummyCapfT,                         !- Cooling Capacity Function of Temperature Curve Name",
        "  DummyEIRfT,                         !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
        "  DummyEIRfPLR,                       !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "  0.10,                               !- Minimum Part Load Ratio",
        "  1.00,                               !- Maximum Part Load Ratio",
        "  1.00,                               !- Optimum Part Load Ratio",
        "  0.25,                               !- Minimum Unloading Ratio",
        "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
        "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
        "  Condenser Inlet Node,               !- Condenser Inlet Node Name",
        "  Condenser Outlet Node,              !- Condenser Outlet Node Name",
        "  WaterCooled,                        !- Condenser Type",
        "  0.04,                               !- Condenser Fan Power Ratio {W/W}",
        "  1.00,                               !- Fraction of Compressor Electric Consumption Rejected by Condenser",
        "  5.00,                               !- Leaving Chilled Water Lower Temperature Limit {C}",
        "  NotModulated,                       !- Chiller Flow Mode",
        "  autosize,                           !- Design Heat Recovery Water Flow Rate {m3/s}",
        "  HetRec Inlet Node,                  !- Heat Recovery Inlet Node Name",
        "  HetRec Outlet Node,                 !- Heat Recovery Outlet Node Name",
        "  1.00,                               !- Sizing Factor",
        "  0.00,                               !- Basin Heater Capacity {W/K}",
        "  2.00,                               !- Basin Heater Setpoint Temperature {C}",
        "  ,                                   !- Basin Heater Operating Schedule Name",
        "  0.30,                               !- Condenser Heat Recovery Relative Capacity Fraction",
        "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
        "  HetRec Outlet Node,                 !- Heat Recovery Leaving Temperature Setpoint Node Name",
        "  ,                                   !- End-Use Subcategory",
        "  ModulatedLoopPLR,                   !- Condenser Flow Control",
        "  Y=F(X),                             !- Condenser Loop Flow Rate Fraction Function of Loop Part Load Ratio Curve Name",
        "  CondenserdT,                        !- Temperature Difference Across Condenser Schedule Name",
        "  0.35;                               !- Condenser Minimum Flow Fraction",
        "Curve:Linear,Y=F(X),0,1,0,1;",
        "Schedule:Constant,CondenserdT,,10;"
        "Curve:Biquadratic, DummyCapfT, 1, 0, 0, 0, 0, 0, 5, 10, 24, 35, , , , , ;",
        "Curve:Biquadratic, DummyEIRfT, 1, 0,  0, 0, 0, 0,   5, 10, 24, 35, , , , , ;",
        "Curve:Quadratic, DummyEIRfPLR, 1,  0,  0, 0, 1, , , , ;",
    ])
    assert process_idf(idf_objects, false)
    state.init_state(state)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataSize.PlantSizData.allocate(state.dataPlnt.TotNumLoops)
    for l in range(state.dataPlnt.TotNumLoops):
        var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    GetElectricEIRChillerInput(state)
    var thisChiller = state.dataChillerElectricEIR.ElectricEIRChiller[0]
    let num_nodes = 10
    state.dataLoopNodes.Node.allocate(num_nodes)
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].PlantSizNum = 1
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].TempSetPointNodeNum = 10
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Name = "WaterChiller Supply Branch"
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisChiller.EvapInletNodeNum
    state.dataPlnt.PlantLoop[0].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisChiller.EvapOutletNodeNum
    state.dataPlnt.PlantLoop[0].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataPlnt.PlantLoop[0].LoopSide(EnergyPlus.DataPlant.LoopSideLocation.Demand).TempSetPoint = 4.4
    state.dataSize.PlantSizData[0].DesVolFlowRate = 0.02
    state.dataSize.PlantSizData[0].DeltaT = 5.0
    state.dataPlnt.PlantLoop[1].Name = "CondenserWaterLoop"
    state.dataPlnt.PlantLoop[1].PlantSizNum = 2
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Name = "WaterChiller Condenser Branch"
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisChiller.CondInletNodeNum
    state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisChiller.CondOutletNodeNum
    state.dataSize.PlantSizData[1].DesVolFlowRate = 0.03
    state.dataSize.PlantSizData[1].DeltaT = 5.0
    state.dataPlnt.PlantLoop[2].Name = "HecRecWaterLoop"
    state.dataPlnt.PlantLoop[2].PlantSizNum = 3
    state.dataPlnt.PlantLoop[2].FluidName = "WATER"
    state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Name = "WaterChiller HecRec Branch"
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Name = thisChiller.Name
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].Type = DataPlant.PlantEquipmentType.Chiller_ElectricEIR
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumIn = thisChiller.HeatRecInletNodeNum
    state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[0].Comp[0].NodeNumOut = thisChiller.HeatRecOutletNodeNum
    state.dataPlnt.PlantLoop[2].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
    state.dataLoopNodes.Node[thisChiller.HeatRecOutletNodeNum - 1].TempSetPoint = 60.0
    state.dataSize.PlantSizData[2].DesVolFlowRate = 0.03
    state.dataSize.PlantSizData[2].DeltaT = 5.0
    for n in range(num_nodes):
        state.dataLoopNodes.Node[n].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[n].MassFlowRateMax = 2.0
    state.dataPlnt.PlantFirstSizesOkayToFinalize = true
    state.dataPlnt.PlantFirstSizesOkayToReport = true
    state.dataPlnt.PlantFinalSizesOkayToReport = false
    var MyLoad = 0.0
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.size(state)
    MyLoad = -thisChiller.RefCap
    state.dataSize.PlantSizData[0].DesCapacity = abs(MyLoad) * 2
    Sched.UpdateScheduleVals(state)
    state.dataGlobal.BeginEnvrnFlag = true
    state.dataPlnt.PlantFinalSizesOkayToReport = true
    thisChiller.initialize(state, RunFlag, MyLoad)
    thisChiller.size(state)
    var orp = state.dataOutRptPredefined
    let ChillerName = thisChiller.Name
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerType, ChillerName) == "Chiller:Electric:EIR"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefCap, ChillerName) == "419750.18"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefEff, ChillerName) == "3.50"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedCap, ChillerName) == "419750.18"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedEff, ChillerName) == "3.50"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerIPLVinSI, ChillerName) == "2.03"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerIPLVinIP, ChillerName) == "2.03"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerMinPLR, ChillerName) == "0.10"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerFuelType, ChillerName) == "Electricity"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedEntCondTemp, ChillerName) == "28.40"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedLevEvapTemp, ChillerName) == "5.67"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefEntCondTemp, ChillerName) == "28.40"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefLevEvapTemp, ChillerName) == "5.67"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerDesSizeRefCHWFlowRate, ChillerName) == "20.00"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerDesSizeRefCondFluidFlowRate, ChillerName) == "25.82"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerPlantloopName, ChillerName) == "ChilledWaterLoop"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerPlantloopBranchName, ChillerName) == "WaterChiller Supply Branch"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerCondLoopName, ChillerName) == "CondenserWaterLoop"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerCondLoopBranchName, ChillerName) == "WaterChiller Condenser Branch"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerHeatRecPlantloopName, ChillerName) == "HecRecWaterLoop"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerHeatRecPlantloopBranchName, ChillerName) == "WaterChiller HecRec Branch"
    assert OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRecRelCapFrac, ChillerName) == "0.30"