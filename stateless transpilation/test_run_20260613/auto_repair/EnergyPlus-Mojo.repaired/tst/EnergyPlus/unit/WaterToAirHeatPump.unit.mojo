from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.FluidProperties import Fluid
from EnergyPlus.General import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.Psychrometrics import PsyHFnTdbW
from EnergyPlus.WaterToAirHeatPump import *

def test_WaterToAirHeatPumpTest_SimWaterToAir():
    let idf_objects: String = delimited_string([
        " Coil:Cooling:WaterToAirHeatPump:ParameterEstimation, ",
        "   Sys 1 Heat Pump Cooling Mode, !- Name",
        "   ,            !- Availability Schedule Name",
        "   Scroll,      !- Compressor Type",
        "   R22,         !- Refrigerant Type",
        "   0.0015,      !- Design Source Side Flow Rate{ m3 / s }",
        "   38000,       !- Nominal Cooling Coil Capacity{ W }",
        "   0,           !- Nominal Time for Condensate Removal to Begin{ s }",
        "   0,           !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity{ dimensionless }",
        "   3000000,     !- High Pressure Cutoff{ Pa }",
        "   0,           !- Low Pressure Cutoff{ Pa }",
        "   Sys 1 Water to Air Heat Pump Source Side1 Inlet Node, !- Water Inlet Node Name",
        "   Sys 1 Water to Air Heat Pump Source Side1 Outlet Node, !- Water Outlet Node Name",
        "   Sys 1 Cooling Coil Air Inlet Node, !- Air Inlet Node Name",
        "   Sys 1 Heating Coil Air Inlet Node, !- Air Outlet Node Name",
        "   3.78019E+03, !- Load Side Total Heat Transfer Coefficient{ W / K }",
        "   2.80303E+03, !- Load Side Outside Surface Heat Transfer Coefficient{ W / K }",
        "   7.93591E-01, !- Superheat Temperature at the Evaporator Outlet{ C }",
        "   1.91029E+03, !- Compressor Power Losses{ W }",
        "   2.66127E+00, !- Compressor Efficiency",
        "   ,            !- Compressor Piston Displacement{ m3 / s }",
        "   ,            !- Compressor Suction / Discharge Pressure Drop{ Pa }",
        "   ,            !- Compressor Clearance Factor{ dimensionless }",
        "   1.06009E-01, !- Refrigerant Volume Flow Rate{ m3 / s }",
        "   1.65103E+00, !- Volume Ratio{ dimensionless }",
        "   9.73887E-03, !- Leak Rate Coefficient",
        "   1.04563E+03, !- Source Side Heat Transfer Coefficient{ W / K }",
        "   0.8,         !- Source Side Heat Transfer Resistance1{ dimensionless }",
        "   20.0,        !- Source Side Heat Transfer Resistance2{ W / K }",
        "   PLFFPLR;     !- Part Load Fraction Correlation Curve Name",
        " Coil:Heating:WaterToAirHeatPump:ParameterEstimation,",
        "   Sys 1 Heat Pump HEATING Mode, !- Name",
        "   ,            !- Availability Schedule Name",
        "   Scroll,      !- Compressor Type",
        "   R22,         !- Refrigerant Type",
        "   0.0015,      !- Design Source Side Flow Rate{ m3 / s }",
        "   38000,       !- Gross Rated Heating Capacity{ W }",
        "   3000000,     !- High Pressure Cutoff",
        "   0,           !- Low Pressure Cutoff{ Pa }",
        "   Sys 1 Water to Air Heat Pump Source Side2 Inlet Node, !- Water Inlet Node Name",
        "   Sys 1 Water to Air Heat Pump Source Side2 Outlet Node, !- Water Outlet Node Name",
        "   Sys 1 Heating Coil Air Inlet Node, !- Air Inlet Node Name",
        "   Sys 1 SuppHeating Coil Air Inlet Node, !- Air Outlet Node Name",
        "   3.91379E+03, !- Load Side Total Heat Transfer Coefficient{ W / K }",
        "   5.94753E-01, !- Superheat Temperature at the Evaporator Outlet{ C }",
        "   2.49945E+03, !- Compressor Power Losses{ W }",
        "   8.68734E-01, !- Compressor Efficiency",
        "   ,            !- Compressor Piston Displacement{ m3 / s }",
        "   ,            !- Compressor Suction / Discharge Pressure Drop{ Pa }",
        "   ,            !- Compressor Clearance Factor{ dimensionless }",
        "   7.23595E-02, !- Refrigerant Volume Flow Rate{ m3 / s }",
        "   3.69126E+00, !- Volume Ratio{ dimensionless }",
        "   1.75701E-05, !- Leak Rate Coefficient{ dimensionless }",
        "   3.65348E+03, !- Source Side Heat Transfer Coefficient{ W / K }",
        "   0.8,         !- Source Side Heat Transfer Resistance1{ dimensionless }",
        "   20.0,        !- Source Side Heat Transfer Resistance2{ W / K }",
        "   PLFFPLR;     !- Part Load Fraction Correlation Curve Name",
        "Curve:Quadratic, PLFFPLR, 0.85, 0.83, 0.0, 0.0, 0.3, 0.85, 1.0, Dimensionless, Dimensionless; ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var refrig = Fluid.RefrigProps()
    refrig.Name = "R22"
    state.dataFluid.refrigs.push_back(refrig)
    refrig.Num = state.dataFluid.refrigs.isize()
    refrig.PsLowTempIndex = 1
    refrig.PsHighTempIndex = 2
    refrig.PsTemps.allocate(2)
    refrig.PsTemps[0] = -157.42
    refrig.PsTemps[1] = 96.145
    refrig.PsValues.allocate(2)
    refrig.PsValues[0] = 0.3795
    refrig.PsValues[1] = 4990000.0
    refrig.HfLowTempIndex = 1
    refrig.HfHighTempIndex = 2
    refrig.PsLowPresIndex = 1
    refrig.PsHighPresIndex = 2
    refrig.HTemps.allocate(2)
    refrig.HfValues.allocate(2)
    refrig.HfgValues.allocate(2)
    refrig.HTemps[0] = -157.42
    refrig.HTemps[1] = 96.145
    refrig.HfValues[0] = 29600.0
    refrig.HfValues[1] = 366900.0
    refrig.HfgValues[0] = 332700.0
    refrig.HfgValues[1] = 366900.0
    refrig.NumSupTempPoints = 2
    refrig.NumSupPressPoints = 2
    refrig.SupTemps.allocate(2)
    refrig.SupPress.allocate(2)
    refrig.SupTemps[0] = -157.15
    refrig.SupTemps[1] = 152.85
    refrig.SupPress[0] = 0.4043
    refrig.SupPress[1] = 16500000.0
    refrig.HshValues.allocate(2, 2)
    refrig.HshValues[0, 0] = 332800.0
    refrig.HshValues[0, 1] = 537000.0
    refrig.HshValues[1, 0] = 332800.0
    refrig.HshValues[1, 1] = 537000.0
    refrig.RhoshValues.allocate(2, 2)
    refrig.RhoshValues[0, 0] = 0.00003625
    refrig.RhoshValues[0, 1] = 0.0
    refrig.RhoshValues[1, 0] = 0.00003625
    refrig.RhoshValues[1, 1] = 0.0
    refrig.RhofLowTempIndex = 1
    refrig.RhofHighTempIndex = 2
    refrig.RhoTemps.allocate(2)
    refrig.RhoTemps[0] = -157.42
    refrig.RhoTemps[1] = 96.145
    refrig.RhofValues.allocate(2)
    refrig.RhofValues[0] = 1721.0
    refrig.RhofValues[1] = 523.8
    refrig.RhofgValues.allocate(2)
    refrig.RhofgValues[0] = 0.341
    refrig.RhofgValues[1] = 523.8
    GetWatertoAirHPInput(state)
    var HPNum: Int = 1
    var DesignAirflow: Float64 = 2.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].Temp = 5.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].Enthalpy = 44650.0
    state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRate = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRateMax = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRateMaxAvail = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].MassFlowRate = DesignAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].Temp = 26.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].HumRat = 0.007
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].Enthalpy = 43970.75
    state.dataPlnt.TotNumLoops = 2
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    for l in range(1, state.dataPlnt.TotNumLoops + 1):
        var loopside = state.dataPlnt.PlantLoop[l - 1].LoopSide[DataPlant.LoopSideLocation.Demand]
        loopside.TotalBranches = 1
        loopside.Branch.allocate(1)
        var loopsidebranch = state.dataPlnt.PlantLoop[l - 1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0]
        loopsidebranch.TotalComponents = 1
        loopsidebranch.Comp.allocate(1)
    state.dataPlnt.PlantLoop[0].Name = "ChilledWaterLoop"
    state.dataPlnt.PlantLoop[0].FluidName = "WATER"
    state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Name
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WAHPType
    state.dataPlnt.PlantLoop[0].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum
    var InitFlag: Bool = True
    var SensLoad: Float64 = 38000.0
    var LatentLoad: Float64 = 0.0
    var PartLoadRatio: Float64 = 1.0
    var fanOp: HVAC.FanOp = HVAC.FanOp.Cycling
    var FirstHVACIteration: Bool = True
    var compressorOp: HVAC.CompressorOp = HVAC.CompressorOp.On
    state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].plantLoc.loopNum = 1
    InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
    CalcWatertoAirHPCooling(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
    EXPECT_NE(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].QSource, 0.0)
    EXPECT_NE(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Power, 0.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].QSource, state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].InletWaterMassFlowRate * (state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].OutletWaterEnthalpy - state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].InletWaterEnthalpy), 0.000000001)
    HPNum = 2
    state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].plantLoc.loopNum = 2
    state.dataPlnt.PlantLoop[1].Name = "HotWaterLoop"
    state.dataPlnt.PlantLoop[1].FluidName = "WATER"
    state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Name = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Name
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].Type = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WAHPType
    state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].Temp = 35.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].Enthalpy = 43950.0
    state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRate = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRateMax = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].WaterInletNodeNum - 1].MassFlowRateMaxAvail = state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].MassFlowRate = DesignAirflow
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].Temp = 15.0
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].HumRat = 0.004
    state.dataLoopNodes.Node[state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].AirInletNodeNum - 1].Enthalpy = PsyHFnTdbW(15.0, 0.004)
    state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].DesignWaterMassFlowRate = 15.0
    InitWatertoAirHP(state, HPNum, InitFlag, SensLoad, LatentLoad, DesignAirflow, PartLoadRatio)
    CalcWatertoAirHPHeating(state, HPNum, fanOp, FirstHVACIteration, InitFlag, SensLoad, compressorOp, PartLoadRatio)
    EXPECT_NE(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].QSource, 0.0)
    EXPECT_NE(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].Power, 0.0)
    EXPECT_NEAR(state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].QSource, state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].InletWaterMassFlowRate * (state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].InletWaterEnthalpy - state.dataWaterToAirHeatPump.WatertoAirHP[HPNum - 1].OutletWaterEnthalpy), 0.000000001)
    state.dataWaterToAirHeatPump.WatertoAirHP.deallocate()