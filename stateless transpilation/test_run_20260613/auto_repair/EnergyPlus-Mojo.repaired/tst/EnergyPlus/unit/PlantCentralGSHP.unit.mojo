from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_DOUBLE_EQ, EXPECT_NEAR, EXPECT_ENUM_EQ, ASSERT_TRUE
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataBranchNodeConnections import DataBranchNodeConnections
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.FluidProperties import Fluid
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantCentralGSHP import PlantCentralGSHP
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Data.EnergyPlusData import state as global_state
from EnergyPlus.Data.EnergyPlusData import Constant
from EnergyPlus.Sched import Sched
from EnergyPlus.Node import Node

@fixture
class ChillerHeater_Autosize(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.init_state(state)
        var NumWrappers: Int = 1
        state.dataPlantCentralGSHP.numWrappers = NumWrappers
        state.dataPlantCentralGSHP.Wrapper.allocate(NumWrappers)
        var NumberOfComp: Int = 1
        state.dataPlantCentralGSHP.Wrapper[0].NumOfComp = NumberOfComp
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(NumberOfComp)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp[0].WrapperPerformanceObjectType = "CHILLERHEATERPERFORMANCE:ELECTRIC:EIR"
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp[0].WrapperIdenticalObjectNum = 2
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp[0].chSched = Sched.GetScheduleAlwaysOn(state)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeaterNums = 2
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(2)
        state.dataPlantCentralGSHP.Wrapper[0].ControlMode = PlantCentralGSHP.CondenserType.SmartMixing
        var NumChillerHeaters: Int = 1
        state.dataPlantCentralGSHP.numChillerHeaters = NumChillerHeaters
        state.dataPlantCentralGSHP.ChillerHeater.allocate(NumChillerHeaters)
        state.dataPlantCentralGSHP.ChillerHeater[0].ConstantFlow = False
        state.dataPlantCentralGSHP.ChillerHeater[0].VariableFlow = True
        state.dataPlantCentralGSHP.ChillerHeater[0].condenserType = PlantCentralGSHP.CondenserType.WaterCooled
        state.dataPlantCentralGSHP.ChillerHeater[0].SizFac = 1.2
        state.dataPlantCentralGSHP.ChillerHeater[0].RefCapCooling = DataSizing.AutoSize
        state.dataPlantCentralGSHP.ChillerHeater[0].RefCapCoolingWasAutoSized = True
        state.dataPlantCentralGSHP.ChillerHeater[0].EvapVolFlowRate = DataSizing.AutoSize
        state.dataPlantCentralGSHP.ChillerHeater[0].EvapVolFlowRateWasAutoSized = True
        state.dataPlantCentralGSHP.ChillerHeater[0].CondVolFlowRate = DataSizing.AutoSize
        state.dataPlantCentralGSHP.ChillerHeater[0].CondVolFlowRateWasAutoSized = True
        state.dataPlantCentralGSHP.ChillerHeater[0].RefCOPCooling = 1.5
        state.dataPlantCentralGSHP.ChillerHeater[0].OpenMotorEff = 0.98
        state.dataPlantCentralGSHP.ChillerHeater[0].TempRefCondInCooling = 29.4
        state.dataPlantCentralGSHP.ChillerHeater[0].ClgHtgToCoolingCapRatio = 0.74
        state.dataPlantCentralGSHP.ChillerHeater[0].ClgHtgtoCogPowerRatio = 1.38
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0] = state.dataPlantCentralGSHP.ChillerHeater[0]
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[1] = state.dataPlantCentralGSHP.ChillerHeater[0]
        state.dataPlantCentralGSHP.ChillerHeater.deallocate()
        state.dataPlnt.PlantLoop.allocate(2)
        state.dataSize.PlantSizData.allocate(2)
        var PltSizNum: Int = 1
        state.dataPlnt.PlantLoop[PltSizNum - 1].PlantSizNum = 1
        state.dataPlnt.PlantLoop[PltSizNum - 1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[PltSizNum - 1].glycol = Fluid.GetWater(state)
        state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate = 1.0
        state.dataSize.PlantSizData[PltSizNum - 1].DeltaT = 10.0
        state.dataSize.PlantSizData[PltSizNum - 1].LoopType = DataSizing.TypeOfPlantLoop.Cooling
        state.dataPlantCentralGSHP.Wrapper[0].CWPlantLoc.loopNum = PltSizNum
        PlantUtilities.SetPlantLocationLinks(state, state.dataPlantCentralGSHP.Wrapper[0].CWPlantLoc)
        var PltSizCondNum: Int = 2
        state.dataPlnt.PlantLoop[PltSizCondNum - 1].PlantSizNum = PltSizCondNum
        state.dataPlnt.PlantLoop[PltSizCondNum - 1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[PltSizCondNum - 1].glycol = Fluid.GetWater(state)
        state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT = 5.6
        state.dataSize.PlantSizData[PltSizCondNum - 1].LoopType = DataSizing.TypeOfPlantLoop.Condenser
        state.dataPlantCentralGSHP.Wrapper[0].GLHEPlantLoc.loopNum = PltSizCondNum
        PlantUtilities.SetPlantLocationLinks(state, state.dataPlantCentralGSHP.Wrapper[0].GLHEPlantLoc)
        var rho_evap: Float64 = state.dataPlnt.PlantLoop[PltSizNum - 1].glycol.getDensity(state, Constant.CWInitConvTemp, "ChillerHeater_Autosize_TEST")
        var Cp_evap: Float64 = state.dataPlnt.PlantLoop[PltSizNum - 1].glycol.getSpecificHeat(state, Constant.CWInitConvTemp, "ChillerHeater_Autosize_TEST")
        var rho_cond: Float64 = state.dataPlnt.PlantLoop[PltSizCondNum - 1].glycol.getDensity(state, Constant.CWInitConvTemp, "ChillerHeater_Autosize_TEST")
        var Cp_cond: Float64 = state.dataPlnt.PlantLoop[PltSizCondNum - 1].glycol.getSpecificHeat(state, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].TempRefCondInCooling, "ChillerHeater_Autosize_TEST")
        var EvapVolFlowRateExpected: Float64 = state.dataSize.PlantSizData[PltSizNum - 1].DesVolFlowRate * state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].SizFac
        var RefCapCoolingExpected: Float64 = rho_evap * Cp_evap * EvapVolFlowRateExpected * state.dataSize.PlantSizData[PltSizNum - 1].DeltaT
        var CondVolFlowRateExpected: Float64 = RefCapCoolingExpected * (1.0 + (1.0 / state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefCOPCooling) * state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].OpenMotorEff) / (rho_cond * Cp_cond * state.dataSize.PlantSizData[PltSizCondNum - 1].DeltaT)
        state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        state.dataPlantCentralGSHP.Wrapper[0].SizeWrapper(state)
        EXPECT_DOUBLE_EQ(EvapVolFlowRateExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].EvapVolFlowRate)
        EXPECT_DOUBLE_EQ(RefCapCoolingExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefCapCooling)
        EXPECT_DOUBLE_EQ(CondVolFlowRateExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].CondVolFlowRate)
        EXPECT_DOUBLE_EQ(CondVolFlowRateExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[1].CondVolFlowRate)
        var RefCapClgHtgExpected: Float64 = RefCapCoolingExpected * state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].ClgHtgToCoolingCapRatio
        EXPECT_DOUBLE_EQ(RefCapClgHtgExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefCapClgHtg)
        var RefPowerClgHtgExpected: Float64 = (RefCapCoolingExpected / state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefCOPCooling) * state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].ClgHtgtoCogPowerRatio
        EXPECT_DOUBLE_EQ(RefPowerClgHtgExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefPowerClgHtg)
        var RefCOPClgHtgExpected: Float64 = RefCapClgHtgExpected / RefPowerClgHtgExpected
        EXPECT_DOUBLE_EQ(RefCOPClgHtgExpected, state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater[0].RefCOPClgHtg)

@fixture
class Test_CentralHeatPumpSystem_Control_Schedule_fix(EnergyPlusFixture):
    def run(self):
        state = global_state
        var idf_objects: String = delimited_string([
            "Schedule:Compact,",
            "Always1, !-Name",
            "On/Off, !-Schedule Type Limits Name",
            "Through: 12/31, !-Field 1",
            "For: AllDays, !-Field 2",
            "Until: 24:00, 1; !-Field 3 ",
            "CentralHeatPumpSystem,",
            "ChW_Loop HeatPump1, !-Name",
            "SmartMixing, !-Control Method",
            "ChW_Loop HeatPump1 ChW Inlet, !-Cooling Loop Inlet Node Name",
            "ChW_Loop HeatPump1 ChW Outlet, !-Cooling Loop Outlet Node Name",
            "ChW_Loop HeatPump1 Cnd Inlet, !-Source Loop Inlet Node Name",
            "ChW_Loop HeatPump1 Cnd Outlet, !-Source Loop Outlet Node Name",
            "ChW_Loop HeatPump1 HHW Inlet, !-Heating Loop Inlet Node Name",
            "ChW_Loop HeatPump1 HHW Outlet, !-Heating Loop Outlet Node Name",
            "460,  !-Ancillary Power{W}",
            ",  !-Ancillary Operation Schedule Name",
            "ChillerHeaterPerformance:Electric:EIR, !-Chiller Heater Modules Performance Component Object Type 1",
            "ChW_Loop HeatPump1 Module, !-Chiller Heater Modules Performance Component Name 1",
            "Always_1_typo, !-Chiller Heater Modules Control Schedule Name 1",
            "2; !-Number of Chiller Heater Modules 1",
            "ChillerHeaterPerformance:Electric:EIR,",
            "    ChW_Loop HeatPump1 Module,  !- Name",
            "    autosize,                !- Reference Cooling Mode Evaporator Capacity {W}",
            "    1.5,                     !- Reference Cooling Mode COP {W/W}",
            "    6.67,                    !- Reference Cooling Mode Leaving Chilled Water Temperature {C}",
            "    29.4,                    !- Reference Cooling Mode Entering Condenser Fluid Temperature {C}",
            "    35.0,                    !- Reference Cooling Mode Leaving Condenser Water Temperature {C}",
            "    0.74,                    !- Reference Heating Mode Cooling Capacity Ratio",
            "    0.925,                   !- Reference Heating Mode Cooling Power Input Ratio",
            "    6.67,                    !- Reference Heating Mode Leaving Chilled Water Temperature {C}",
            "    60,                      !- Reference Heating Mode Leaving Condenser Water Temperature {C}",
            "    29.4,                    !- Reference Heating Mode Entering Condenser Fluid Temperature {C}",
            "    5,                       !- Heating Mode Entering Chilled Water Temperature Low Limit {C}",
            "    VariableFlow,            !- Chilled Water Flow Mode Type",
            "    autosize,                !- Design Chilled Water Flow Rate {m3/s}",
            "    autosize,                !- Design Condenser Water Flow Rate {m3/s}",
            "    0.01684,                 !- Design Hot Water Flow Rate {m3/s}",
            "    1,                       !- Compressor Motor Efficiency",
            "    WaterCooled,             !- Condenser Type",
            "    EnteringCondenser,       !- Cooling Mode Temperature Curve Condenser Water Independent Variable",
            "    ChillerHeaterClgCapFT,   !- Cooling Mode Cooling Capacity Function of Temperature Curve Name",
            "    ChillerHeaterClgEIRFT,   !- Cooling Mode Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
            "    ChillerHeaterClgEIRFPLR, !- Cooling Mode Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
            "    1,                       !- Cooling Mode Cooling Capacity Optimum Part Load Ratio",
            "    LeavingCondenser,        !- Heating Mode Temperature Curve Condenser Water Independent Variable",
            "    ChillerHeaterHtgCapFT,   !- Heating Mode Cooling Capacity Function of Temperature Curve Name",
            "    ChillerHeaterHtgEIRFT,   !- Heating Mode Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
            "    ChillerHeaterHtgEIRFPLR, !- Heating Mode Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
            "    1,                       !- Heating Mode Cooling Capacity Optimum Part Load Ratio",
            "    1;                       !- Sizing Factor",
            "Curve:Biquadratic,",
            "    ChillerHeaterClgCapFT,   !- Name",
            "    0.950829,                !- Coefficient1 Constant",
            "    3.419327E-02,            !- Coefficient2 x",
            "    2.66642E-04,             !- Coefficient3 x**2",
            "    -1.733397E-03,           !- Coefficient4 y",
            "    -1.762417E-04,           !- Coefficient5 y**2",
            "    -3.69198E-05,            !- Coefficient6 x*y",
            "    4.44,                    !- Minimum Value of x",
            "    12.78,                   !- Maximum Value of x",
            "    12.78,                   !- Minimum Value of y",
            "    29.44,                   !- Maximum Value of y",
            "    ,                        !- Minimum Curve Output",
            "    ,                        !- Maximum Curve Output",
            "    Temperature,             !- Input Unit Type for X",
            "    Temperature,             !- Input Unit Type for Y",
            "    Dimensionless;           !- Output Unit Type",
            "Curve:Biquadratic,",
            "    ChillerHeaterHtgCapFT,   !- Name",
            "    0.9415266,               !- Coefficient1 Constant",
            "    5.527431E-02,            !- Coefficient2 x",
            "    3.573558E-04,            !- Coefficient3 x**2",
            "    1.258391E-03,            !- Coefficient4 y",
            "    -6.420546E-05,           !- Coefficient5 y**2",
            "    -5.350989E-04,           !- Coefficient6 x*y",
            "    4.44,                    !- Minimum Value of x",
            "    15.56,                   !- Maximum Value of x",
            "    35,                      !- Minimum Value of y",
            "    57.22,                   !- Maximum Value of y",
            "    ,                        !- Minimum Curve Output",
            "    ,                        !- Maximum Curve Output",
            "    Temperature,             !- Input Unit Type for X",
            "    Temperature,             !- Input Unit Type for Y",
            "    Dimensionless;           !- Output Unit Type",
            "Curve:Biquadratic,",
            "    ChillerHeaterClgEIRFT,   !- Name",
            "    0.7362431,               !- Coefficient1 Constant",
            "    2.136491E-02,            !- Coefficient2 x",
            "    3.638909E-04,            !- Coefficient3 x**2",
            "    -4.284947E-03,           !- Coefficient4 y",
            "    3.389817E-04,            !- Coefficient5 y**2",
            "    -3.632396E-04,           !- Coefficient6 x*y",
            "    4.44,                    !- Minimum Value of x",
            "    12.78,                   !- Maximum Value of x",
            "    12.78,                   !- Minimum Value of y",
            "    29.44,                   !- Maximum Value of y",
            "    ,                        !- Minimum Curve Output",
            "    ,                        !- Maximum Curve Output",
            "    Temperature,             !- Input Unit Type for X",
            "    Temperature,             !- Input Unit Type for Y",
            "    Dimensionless;           !- Output Unit Type",
            "Curve:Biquadratic,",
            "    ChillerHeaterHtgEIRFT,   !- Name",
            "    0.2286246,               !- Coefficient1 Constant",
            "    2.498714E-02,            !- Coefficient2 x",
            "    -1.267106E-05,           !- Coefficient3 x**2",
            "    9.327184E-03,            !- Coefficient4 y",
            "    5.892037E-05,            !- Coefficient5 y**2",
            "    -3.268512E-04,           !- Coefficient6 x*y",
            "    4.44,                    !- Minimum Value of x",
            "    15.56,                   !- Maximum Value of x",
            "    35.0,                    !- Minimum Value of y",
            "    57.22,                   !- Maximum Value of y",
            "    ,                        !- Minimum Curve Output",
            "    ,                        !- Maximum Curve Output",
            "    Temperature,             !- Input Unit Type for X",
            "    Temperature,             !- Input Unit Type for Y",
            "    Dimensionless;           !- Output Unit Type",
            " Curve:Cubic,",
            "     ChillerHeaterClgEIRFPLR, !- Name",
            "     0.0,                     !- Coefficient1 Constant",
            "     1.22895,                 !- Coefficient2 x",
            "     -0.751383,               !- Coefficient3 x**2",
            "     0.517396,                !- Coefficient4 x**3",
            "     0.2,                     !- Minimum Value of x",
            "     1;                       !- Maximum Value of x",
            "Curve:Cubic,",
            "    ChillerHeaterHtgEIRFPLR, !- Name",
            "    0.0,                     !- Coefficient1 Constant",
            "    1.12853,                 !- Coefficient2 x",
            "    -0.0264962,              !- Coefficient3 x**2",
            "    -0.103811,               !- Coefficient4 x**3",
            "    0.3,                     !- Minimum Value of x",
            "    1;                       !- Maximum Value of x"
        ])
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(state)
        state.dataPlantCentralGSHP.getWrapperInputFlag = True
        PlantCentralGSHP.GetWrapperInput(state)
        EXPECT_EQ(state.dataPlantCentralGSHP.Wrapper[0].WrapperComp[0].chSched, Sched.GetScheduleAlwaysOn(state))
        EXPECT_EQ(state.dataBranchNodeConnections.NumOfNodeConnections, 6)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[0].NodeName, "CHW_LOOP HEATPUMP1 CHW INLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[0].ConnectionType, Node.ConnectionType.Inlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[0].FluidStream, Node.CompFluidStream.Primary)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[1].NodeName, "CHW_LOOP HEATPUMP1 CHW OUTLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[1].ConnectionType, Node.ConnectionType.Outlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[1].FluidStream, Node.CompFluidStream.Primary)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[2].NodeName, "CHW_LOOP HEATPUMP1 CND INLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[2].ConnectionType, Node.ConnectionType.Inlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[2].FluidStream, Node.CompFluidStream.Secondary)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[3].NodeName, "CHW_LOOP HEATPUMP1 CND OUTLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[3].ConnectionType, Node.ConnectionType.Outlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[3].FluidStream, Node.CompFluidStream.Secondary)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[4].NodeName, "CHW_LOOP HEATPUMP1 HHW INLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[4].ConnectionType, Node.ConnectionType.Inlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[4].FluidStream, Node.CompFluidStream.Tertiary)
        EXPECT_EQ(state.dataBranchNodeConnections.NodeConnections[5].NodeName, "CHW_LOOP HEATPUMP1 HHW OUTLET")
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[5].ConnectionType, Node.ConnectionType.Outlet)
        EXPECT_ENUM_EQ(state.dataBranchNodeConnections.NodeConnections[5].FluidStream, Node.CompFluidStream.Tertiary)

@fixture
class Test_CentralHeatPumpSystem_adjustChillerHeaterCondFlowTemp(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.dataFluid.init_state(state)
        state.dataPlantCentralGSHP.Wrapper.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(1)
        var thisWrap = state.dataPlantCentralGSHP.Wrapper[0]
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
        thisWrap.HWPlantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(state, thisWrap.HWPlantLoc)
        var qCondenser: Float64
        var condMassFlowRate: Float64
        var condOutletTemp: Float64
        var condInletTemp: Float64
        var condDeltaTemp: Float64
        var expCondenser: Float64
        var expMassFlowRate: Float64
        var expOutletTemp: Float64
        var allowedTolerance: Float64 = 0.0001
        qCondenser = 1000.0
        condMassFlowRate = 1.0
        condOutletTemp = 60.0
        condInletTemp = 59.0
        condDeltaTemp = 1.0
        thisWrap.VariableFlowCH = True
        expCondenser = 1000.0
        expMassFlowRate = 0.23897
        expOutletTemp = 60.0
        thisWrap.adjustChillerHeaterCondFlowTemp(state, qCondenser, condMassFlowRate, condOutletTemp, condInletTemp, condDeltaTemp)
        EXPECT_NEAR(qCondenser, expCondenser, allowedTolerance)
        EXPECT_NEAR(condMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(condOutletTemp, expOutletTemp, allowedTolerance)
        qCondenser = 5000.0
        condMassFlowRate = 1.0
        condOutletTemp = 60.0
        condInletTemp = 59.0
        condDeltaTemp = 1.0
        thisWrap.VariableFlowCH = True
        expCondenser = 4184.6
        expMassFlowRate = 1.0
        expOutletTemp = 60.0
        thisWrap.adjustChillerHeaterCondFlowTemp(state, qCondenser, condMassFlowRate, condOutletTemp, condInletTemp, condDeltaTemp)
        EXPECT_NEAR(qCondenser, expCondenser, allowedTolerance)
        EXPECT_NEAR(condMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(condOutletTemp, expOutletTemp, allowedTolerance)
        qCondenser = 1000.0
        condMassFlowRate = 1.0
        condOutletTemp = 60.0
        condInletTemp = 59.0
        condDeltaTemp = 1.0
        thisWrap.VariableFlowCH = False
        expCondenser = 1000.0
        expMassFlowRate = 1.0
        expOutletTemp = 59.23897
        thisWrap.adjustChillerHeaterCondFlowTemp(state, qCondenser, condMassFlowRate, condOutletTemp, condInletTemp, condDeltaTemp)
        EXPECT_NEAR(qCondenser, expCondenser, allowedTolerance)
        EXPECT_NEAR(condMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(condOutletTemp, expOutletTemp, allowedTolerance)
        qCondenser = 8369.2
        condMassFlowRate = 1.0
        condOutletTemp = 60.0
        condInletTemp = 59.0
        condDeltaTemp = 1.0
        thisWrap.VariableFlowCH = False
        expCondenser = 4184.6
        expMassFlowRate = 1.0
        expOutletTemp = 60.0
        thisWrap.adjustChillerHeaterCondFlowTemp(state, qCondenser, condMassFlowRate, condOutletTemp, condInletTemp, condDeltaTemp)
        EXPECT_NEAR(qCondenser, expCondenser, allowedTolerance)
        EXPECT_NEAR(condMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(condOutletTemp, expOutletTemp, allowedTolerance)

@fixture
class Test_CentralHeatPumpSystem_adjustChillerHeaterEvapFlowTemp(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.dataFluid.init_state(state)
        state.dataPlantCentralGSHP.Wrapper.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(1)
        var thisWrap = state.dataPlantCentralGSHP.Wrapper[0]
        state.dataPlnt.PlantLoop.allocate(1)
        state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(state)
        thisWrap.HWPlantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(state, thisWrap.HWPlantLoc)
        var qEvaporator: Float64
        var evapMassFlowRate: Float64
        var evapOutletTemp: Float64
        var evapInletTemp: Float64
        var expMassFlowRate: Float64
        var expOutletTemp: Float64
        var allowedTolerance: Float64 = 0.0001
        qEvaporator = 0.00001
        evapMassFlowRate = 1.0
        evapOutletTemp = 34.0
        evapInletTemp = 35.0
        thisWrap.VariableFlowCH = False
        expMassFlowRate = 0.0
        expOutletTemp = 35.0
        thisWrap.adjustChillerHeaterEvapFlowTemp(state, qEvaporator, evapMassFlowRate, evapOutletTemp, evapInletTemp)
        EXPECT_NEAR(evapMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expOutletTemp, allowedTolerance)
        qEvaporator = 1000.0
        evapMassFlowRate = 1.0
        evapOutletTemp = 35.0
        evapInletTemp = 35.0
        thisWrap.VariableFlowCH = False
        expMassFlowRate = 0.0
        expOutletTemp = 35.0
        thisWrap.adjustChillerHeaterEvapFlowTemp(state, qEvaporator, evapMassFlowRate, evapOutletTemp, evapInletTemp)
        EXPECT_NEAR(evapMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expOutletTemp, allowedTolerance)
        qEvaporator = 5000.0
        evapMassFlowRate = 1.0
        evapOutletTemp = 34.0
        evapInletTemp = 35.0
        thisWrap.VariableFlowCH = True
        expMassFlowRate = 1.0
        expOutletTemp = 33.80383
        thisWrap.adjustChillerHeaterEvapFlowTemp(state, qEvaporator, evapMassFlowRate, evapOutletTemp, evapInletTemp)
        EXPECT_NEAR(evapMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expOutletTemp, allowedTolerance)
        qEvaporator = 1045.0
        evapMassFlowRate = 1.0
        evapOutletTemp = 34.0
        evapInletTemp = 35.0
        thisWrap.VariableFlowCH = True
        expMassFlowRate = 0.25
        expOutletTemp = 34.0
        thisWrap.adjustChillerHeaterEvapFlowTemp(state, qEvaporator, evapMassFlowRate, evapOutletTemp, evapInletTemp)
        EXPECT_NEAR(evapMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expOutletTemp, allowedTolerance)
        qEvaporator = 2090.0
        evapMassFlowRate = 1.0
        evapOutletTemp = 34.0
        evapInletTemp = 35.0
        thisWrap.VariableFlowCH = False
        expMassFlowRate = 1.0
        expOutletTemp = 34.5
        thisWrap.adjustChillerHeaterEvapFlowTemp(state, qEvaporator, evapMassFlowRate, evapOutletTemp, evapInletTemp)
        EXPECT_NEAR(evapMassFlowRate, expMassFlowRate, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expOutletTemp, allowedTolerance)

@fixture
class Test_CentralHeatPumpSystem_setChillerHeaterCondTemp(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.dataPlantCentralGSHP.Wrapper.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(1)
        var thisWrap = state.dataPlantCentralGSHP.Wrapper[0]
        var thisCH = thisWrap.ChillerHeater[0]
        var functionAnswer: Float64
        var expectedAnswer: Float64
        var allowedTolerance: Float64 = 0.001
        var condEnterTemp: Float64
        var condLeaveTemp: Float64
        var chillNum: Int = 1
        functionAnswer = 0.0
        thisCH.CondMode = EnergyPlus.PlantCentralGSHP.CondenserModeTemperature.EnteringCondenser
        condEnterTemp = 55.5
        condLeaveTemp = 44.4
        expectedAnswer = 55.5
        functionAnswer = thisWrap.setChillerHeaterCondTemp(state, chillNum, condEnterTemp, condLeaveTemp)
        EXPECT_NEAR(functionAnswer, expectedAnswer, allowedTolerance)
        functionAnswer = 0.0
        thisCH.CondMode = EnergyPlus.PlantCentralGSHP.CondenserModeTemperature.LeavingCondenser
        condEnterTemp = 55.5
        condLeaveTemp = 44.4
        expectedAnswer = 44.4
        functionAnswer = thisWrap.setChillerHeaterCondTemp(state, chillNum, condEnterTemp, condLeaveTemp)
        EXPECT_NEAR(functionAnswer, expectedAnswer, allowedTolerance)

@fixture
class Test_CentralHeatPumpSystem_checkEvapOutletTemp(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.dataPlantCentralGSHP.Wrapper.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(1)
        var thisWrap = state.dataPlantCentralGSHP.Wrapper[0]
        var thisCH = thisWrap.ChillerHeater[0]
        var chNum: Int = 1
        var evapOutletTemp: Float64
        var lowTempLimitEout: Float64
        var evapInletTemp: Float64
        var qEvaporator: Float64
        var evapMassFlowRate: Float64
        var Cp: Float64 = 4000.0
        var expQEvap: Float64
        var expTout: Float64
        var allowedTolerance: Float64 = 0.0001
        thisCH.EvapOutletNode.TempMin = 5.0
        evapInletTemp = 10.0
        evapOutletTemp = 8.0
        lowTempLimitEout = 9.0
        qEvaporator = 4000.0
        evapMassFlowRate = 0.5
        expQEvap = 2000.0
        expTout = 9.0
        thisWrap.checkEvapOutletTemp(state, chNum, evapOutletTemp, lowTempLimitEout, evapInletTemp, qEvaporator, evapMassFlowRate, Cp)
        EXPECT_NEAR(qEvaporator, expQEvap, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expTout, allowedTolerance)
        thisCH.EvapOutletNode.TempMin = 5.0
        evapInletTemp = 8.0
        evapOutletTemp = 7.0
        lowTempLimitEout = 9.0
        qEvaporator = 2000.0
        evapMassFlowRate = 0.5
        expQEvap = 0.0
        expTout = 8.0
        thisWrap.checkEvapOutletTemp(state, chNum, evapOutletTemp, lowTempLimitEout, evapInletTemp, qEvaporator, evapMassFlowRate, Cp)
        EXPECT_NEAR(qEvaporator, expQEvap, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expTout, allowedTolerance)
        thisCH.EvapOutletNode.TempMin = 9.0
        evapInletTemp = 10.0
        evapOutletTemp = 8.0
        lowTempLimitEout = 5.0
        qEvaporator = 4000.0
        evapMassFlowRate = 0.5
        expQEvap = 2000.0
        expTout = 9.0
        thisWrap.checkEvapOutletTemp(state, chNum, evapOutletTemp, lowTempLimitEout, evapInletTemp, qEvaporator, evapMassFlowRate, Cp)
        EXPECT_NEAR(qEvaporator, expQEvap, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expTout, allowedTolerance)
        thisCH.EvapOutletNode.TempMin = 9.0
        evapInletTemp = 8.0
        evapOutletTemp = 7.0
        lowTempLimitEout = 5.0
        qEvaporator = 2000.0
        evapMassFlowRate = 0.5
        expQEvap = 0.0
        expTout = 8.0
        thisWrap.checkEvapOutletTemp(state, chNum, evapOutletTemp, lowTempLimitEout, evapInletTemp, qEvaporator, evapMassFlowRate, Cp)
        EXPECT_NEAR(qEvaporator, expQEvap, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expTout, allowedTolerance)
        thisCH.EvapOutletNode.TempMin = 5.0
        evapInletTemp = 8.0
        evapOutletTemp = 6.0
        lowTempLimitEout = 5.0
        qEvaporator = 4000.0
        evapMassFlowRate = 0.5
        expQEvap = 4000.0
        expTout = 6.0
        thisWrap.checkEvapOutletTemp(state, chNum, evapOutletTemp, lowTempLimitEout, evapInletTemp, qEvaporator, evapMassFlowRate, Cp)
        EXPECT_NEAR(qEvaporator, expQEvap, allowedTolerance)
        EXPECT_NEAR(evapOutletTemp, expTout, allowedTolerance)

@fixture
class Test_CentralHeatPumpSystem_calcPLRAndCyclingRatio(EnergyPlusFixture):
    def run(self):
        state = global_state
        state.dataPlantCentralGSHP.Wrapper.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].WrapperComp.allocate(1)
        state.dataPlantCentralGSHP.Wrapper[0].ChillerHeater.allocate(1)
        var thisWrap = state.dataPlantCentralGSHP.Wrapper[0]
        var availChillerCap: Float64
        var actualPartLoadRatio: Float64
        var minPartLoadRatio: Float64
        var maxPartLoadRatio: Float64
        var qEvaporator: Float64
        var frac: Float64
        var expPLR: Float64
        var expFrac: Float64
        var expFalseLoad: Float64
        var allowedTolerance: Float64 = 0.0001
        availChillerCap = -10000.0
        actualPartLoadRatio = -1.0
        minPartLoadRatio = 0.1
        maxPartLoadRatio = 1.0
        qEvaporator = 50000.0
        frac = -1.0
        expPLR = 0.0
        expFrac = 1.0
        expFalseLoad = 0.0
        state.dataPlantCentralGSHP.ChillerCyclingRatio = -1.0
        state.dataPlantCentralGSHP.ChillerPartLoadRatio = -1.0
        state.dataPlantCentralGSHP.ChillerFalseLoadRate = -1.0
        thisWrap.calcPLRAndCyclingRatio(state, availChillerCap, actualPartLoadRatio, minPartLoadRatio, maxPartLoadRatio, qEvaporator, frac)
        EXPECT_NEAR(frac, expFrac, allowedTolerance)
        EXPECT_NEAR(actualPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerCyclingRatio, expFrac, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerFalseLoadRate, expFalseLoad, allowedTolerance)
        availChillerCap = 50000.0
        actualPartLoadRatio = -1.0
        minPartLoadRatio = -0.1
        maxPartLoadRatio = 1.0
        qEvaporator = 10000.0
        frac = -1.0
        expPLR = 0.2
        expFrac = 1.0
        expFalseLoad = 0.0
        state.dataPlantCentralGSHP.ChillerCyclingRatio = -1.0
        state.dataPlantCentralGSHP.ChillerPartLoadRatio = -1.0
        state.dataPlantCentralGSHP.ChillerFalseLoadRate = -1.0
        thisWrap.calcPLRAndCyclingRatio(state, availChillerCap, actualPartLoadRatio, minPartLoadRatio, maxPartLoadRatio, qEvaporator, frac)
        EXPECT_NEAR(frac, expFrac, allowedTolerance)
        EXPECT_NEAR(actualPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerCyclingRatio, expFrac, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerFalseLoadRate, expFalseLoad, allowedTolerance)
        availChillerCap = 50000.0
        actualPartLoadRatio = -1.0
        minPartLoadRatio = 0.4
        maxPartLoadRatio = 1.0
        qEvaporator = 10000.0
        frac = -1.0
        expPLR = 0.4
        expFrac = 0.5
        expFalseLoad = 0.0
        state.dataPlantCentralGSHP.ChillerCyclingRatio = -1.0
        state.dataPlantCentralGSHP.ChillerPartLoadRatio = -1.0
        state.dataPlantCentralGSHP.ChillerFalseLoadRate = -1.0
        thisWrap.calcPLRAndCyclingRatio(state, availChillerCap, actualPartLoadRatio, minPartLoadRatio, maxPartLoadRatio, qEvaporator, frac)
        EXPECT_NEAR(frac, expFrac, allowedTolerance)
        EXPECT_NEAR(actualPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerCyclingRatio, expFrac, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerFalseLoadRate, expFalseLoad, allowedTolerance)
        availChillerCap = 50000.0
        actualPartLoadRatio = -1.0
        minPartLoadRatio = 0.4
        maxPartLoadRatio = 1.0
        qEvaporator = 30000.0
        frac = -1.0
        expPLR = 0.6
        expFrac = 1.0
        expFalseLoad = 0.0
        state.dataPlantCentralGSHP.ChillerCyclingRatio = -1.0
        state.dataPlantCentralGSHP.ChillerPartLoadRatio = -1.0
        state.dataPlantCentralGSHP.ChillerFalseLoadRate = -1.0
        thisWrap.calcPLRAndCyclingRatio(state, availChillerCap, actualPartLoadRatio, minPartLoadRatio, maxPartLoadRatio, qEvaporator, frac)
        EXPECT_NEAR(frac, expFrac, allowedTolerance)
        EXPECT_NEAR(actualPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerCyclingRatio, expFrac, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerFalseLoadRate, expFalseLoad, allowedTolerance)
        availChillerCap = 50000.0
        actualPartLoadRatio = -1.0
        minPartLoadRatio = 0.4
        maxPartLoadRatio = 1.0
        qEvaporator = 60000.0
        frac = -1.0
        expPLR = 1.0
        expFrac = 1.0
        expFalseLoad = 0.0
        state.dataPlantCentralGSHP.ChillerCyclingRatio = -1.0
        state.dataPlantCentralGSHP.ChillerPartLoadRatio = -1.0
        state.dataPlantCentralGSHP.ChillerFalseLoadRate = -1.0
        thisWrap.calcPLRAndCyclingRatio(state, availChillerCap, actualPartLoadRatio, minPartLoadRatio, maxPartLoadRatio, qEvaporator, frac)
        EXPECT_NEAR(frac, expFrac, allowedTolerance)
        EXPECT_NEAR(actualPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerCyclingRatio, expFrac, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerPartLoadRatio, expPLR, allowedTolerance)
        EXPECT_NEAR(state.dataPlantCentralGSHP.ChillerFalseLoadRate, expFalseLoad, allowedTolerance)