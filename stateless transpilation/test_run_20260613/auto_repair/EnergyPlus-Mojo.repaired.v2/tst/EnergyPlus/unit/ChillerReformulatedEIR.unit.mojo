from gtest import Test, TestFixture, EXPECT_TRUE, EXPECT_EQ, EXPECT_NEAR, EXPECT_GT, EXPECT_LT
from EnergyPlus.ChillerReformulatedEIR import *
from EnergyPlus.CurveManager import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.DataSizing import *
from EnergyPlus.FluidProperties import *
from EnergyPlus.General import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.DataPlant import *
from EnergyPlus.Plant.Enums import *
from EnergyPlus.Psychrometrics import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture

using EnergyPlus
using EnergyPlus::ChillerReformulatedEIR

@fixture
class ChillerElectricReformulatedEIR_WaterCooledChillerVariableSpeedCondenser(EnergyPlusFixture):
    def run(self):
        var RunFlag: Bool = True
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
        var idf_objects: String = delimited_string([
            "Chiller:Electric:ReformulatedEIR,",
            "  WaterChiller,                       !- Name",
            "  autosize,                           !- Reference Capacity {W}",
            "  1,                                  !- Reference COP {W/W}",
            "  6.67,                               !- Reference Leaving Chilled Water Temperature {C}",
            "  29.40,                              !- Reference Entering Condenser Fluid Temperature {C}",
            "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
            "  0.001,                              !- Reference Condenser Fluid Flow Rate {m3/s}",
            "  DummyCapfT,                         !- Cooling Capacity Function of Temperature Curve Name",
            "  DummyEIRfT,                         !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
            "  LeavingCondenserWaterTemperature,   !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Type",
            "  DummyEIRfPLR,                       !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
            "  0.10,                               !- Minimum Part Load Ratio",
            "  1.00,                               !- Maximum Part Load Ratio",
            "  1.00,                               !- Optimum Part Load Ratio",
            "  0.25,                               !- Minimum Unloading Ratio",
            "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
            "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
            "  Condenser Inlet Node,               !- Condenser Inlet Node Name",
            "  Condenser Outlet Node,              !- Condenser Outlet Node Name",
            "  1,                                  !- Fraction of Compressor Electric Consumption Rejected by Condenser",
            "  2,                                  !- Leaving Chilled Water Lower Temperature Limit {C}",
            "  ConstantFlow,                       !- Chiller Flow Mode",
            "  0.0,                                !- Design Heat Recovery Water Flow Rate {m3/s}",
            "  ,                                   !- Heat Recovery Inlet Node Name",
            "  ,                                   !- Heat Recovery Outlet Node Name",
            "  1.00,                               !- Sizing Factor",
            "  1.00,                               !- Condenser Heat Recovery Relative Capacity Fraction",
            "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
            "  ,                                   !- Heat Recovery Leaving Temperature Setpoint Node Name",
            "  ,                                   !- End-Use Subcategory",
            "  ModulatedLoopPLR,                   !- Condenser Flow Control",
            "  Y=F(X),                             !- Condenser Loop Flow Rate Fraction Function of Loop Part Load Ratio Curve Name",
            "  CondenserdT,                        !- Temperature Difference Across Condenser Schedule Name",
            "  0.35,                               !- Condenser Minimum Flow Fraction",
            "  ThermoCapFracCurve;                 !- Thermosiphon Capacity Fraction Curve Name",
            "Curve:Linear, ThermoCapFracCurve, 0.0, 0.06, 0.0, 1.0, 0.0, 1.0, Dimensionless, Dimensionless;",
            "Curve:Linear,Y=F(X),0,1,0,1;",
            "Schedule:Constant,CondenserdT,,10.0;"
            "Curve:Biquadratic, DummyCapfT, 1, 0, 0, 0, 0, 0, 5, 10, 24, 35, , , , , ;",
            "Curve:Biquadratic, DummyEIRfT, 1, 0,  0, 0, 0, 0,   5, 10, 24, 35, , , , , ;",
            "Curve:Biquadratic, DummyEIRfPLR, 1, 0,  0, 0, 0, 0,   5, 10, 0, 1, , , , , ;",
        ])
        EXPECT_TRUE(process_idf(idf_objects, False))
        state.init_state(state)
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        for l in range(1, state.dataPlnt.TotNumLoops + 1):
            var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetElecReformEIRChillerInput(state)
        var thisChiller = state.dataChillerReformulatedEIR.ElecReformEIRChiller[1]
        state.dataLoopNodes.Node.allocate(4)
        state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
        state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[1].TempSetPointNodeNum = 10
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = thisChiller.Name
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = thisChiller.EvapInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumOut = thisChiller.EvapOutletNodeNum
        state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
        state.dataPlnt.PlantLoop[1].LoopSide(EnergyPlus.DataPlant.LoopSideLocation.Demand).TempSetPoint = 4.4
        state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].TempSetPoint = 4.4
        state.dataSize.PlantSizData.allocate(2)
        state.dataSize.PlantSizData[1].DesVolFlowRate = 0.001
        state.dataSize.PlantSizData[1].DeltaT = 5.0
        state.dataPlnt.PlantLoop[2].Name = "CondenserWaterLoop"
        state.dataPlnt.PlantLoop[2].PlantSizNum = 1
        state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = thisChiller.Name
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = thisChiller.CondInletNodeNum
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumOut = thisChiller.CondOutletNodeNum
        state.dataSize.PlantSizData[2].DesVolFlowRate = 0.001
        state.dataSize.PlantSizData[2].DeltaT = 5.0
        state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        state.dataPlnt.PlantFirstSizesOkayToReport = True
        state.dataPlnt.PlantFinalSizesOkayToReport = True
        var MyLoad: Float64 = 0.0
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.size(state)
        MyLoad = -thisChiller.RefCap
        state.dataSize.PlantSizData[1].DesCapacity = abs(MyLoad) * 2
        Sched.UpdateScheduleVals(state)
        state.dataGlobal.BeginEnvrnFlag = True
        thisChiller.initialize(state, RunFlag, MyLoad)
        state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 25.0
        state.dataLoopNodes.Node[thisChiller.EvapInletNodeNum].Temp = 15.0
        state.dataPlnt.PlantLoop[thisChiller.CWPlantLoc.loopNum].LoopSide[thisChiller.CWPlantLoc.loopSideNum].UpdatedDemandToLoopSetPoint = MyLoad
        thisChiller.control(state, MyLoad, RunFlag, False)
        EXPECT_NEAR(thisChiller.CondMassFlowRate, thisChiller.CondMassFlowRateMax / 2, 0.00001)
        thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedChillerPLR
        MyLoad /= 2
        thisChiller.control(state, MyLoad, RunFlag, False)
        EXPECT_NEAR(thisChiller.CondMassFlowRate, thisChiller.CondMassFlowRateMax / 2, 0.00001)
        thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedDeltaTemperature
        var Cp: Float64 = state.dataPlnt.PlantLoop[thisChiller.CWPlantLoc.loopNum].glycol.getSpecificHeat(state, thisChiller.CondInletTemp, "ChillerElectricEIR_WaterCooledChillerVariableSpeedCondenser")
        thisChiller.control(state, MyLoad, RunFlag, False)
        var ActualCondFlow: Float64 = 3.0 * abs(MyLoad) / (Cp * 10.0)
        EXPECT_NEAR(thisChiller.CondMassFlowRate, ActualCondFlow, 0.00001)
        thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ConstantFlow
        thisChiller.control(state, MyLoad, RunFlag, False)
        EXPECT_NEAR(thisChiller.CondMassFlowRate, thisChiller.CondMassFlowRateMax, 0.00001)
        MyLoad = -500
        thisChiller.CondenserFlowControl = DataPlant.CondenserFlowControl.ModulatedChillerPLR
        thisChiller.control(state, MyLoad, RunFlag, False)
        EXPECT_NEAR(thisChiller.CondMassFlowRate, thisChiller.CondMassFlowRateMax * 0.35, 0.00001)
        MyLoad = -15000.0
        var FalsiCondOutTemp: Float64 = state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp
        state.dataLoopNodes.Node[thisChiller.EvapInletNodeNum].Temp = 10.0
        state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].Temp = 6.0
        state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].TempSetPoint = 6.0
        state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 12.0
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.calculate(state, MyLoad, RunFlag, FalsiCondOutTemp)
        EXPECT_GT(thisChiller.ChillerPartLoadRatio, 0.7)
        EXPECT_EQ(thisChiller.thermosiphonStatus, 0)
        EXPECT_GT(thisChiller.Power, 20000.0)
        state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 5.0
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.calculate(state, MyLoad, RunFlag, FalsiCondOutTemp)
        EXPECT_GT(thisChiller.ChillerPartLoadRatio, 0.7)
        EXPECT_EQ(thisChiller.thermosiphonStatus, 0)
        EXPECT_GT(thisChiller.Power, 20000.0)
        MyLoad /= 15.0
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.calculate(state, MyLoad, RunFlag, FalsiCondOutTemp)
        var dT: Float64 = thisChiller.EvapOutletTemp - thisChiller.CondInletTemp
        var thermosiphonCapFrac: Float64 = Curve.CurveValue(state, thisChiller.thermosiphonTempCurveIndex, dT)
        EXPECT_LT(thisChiller.ChillerPartLoadRatio, 0.05)
        EXPECT_GT(thermosiphonCapFrac, thisChiller.ChillerPartLoadRatio)
        EXPECT_EQ(thisChiller.thermosiphonStatus, 1)
        EXPECT_EQ(thisChiller.Power, 0.0)

@fixture
class ChillerElectricReformulatedEIR_OutputReport(EnergyPlusFixture):
    def run(self):
        var RunFlag: Bool = True
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
        var idf_objects: String = delimited_string([
            "Chiller:Electric:ReformulatedEIR,",
            "  WaterChiller,                       !- Name",
            "  autosize,                           !- Reference Capacity {W}",
            "  3.5,                                !- Reference COP {W/W}",
            "  5.67,                               !- Reference Leaving Chilled Water Temperature {C}",
            "  35.40,                              !- Reference Leaving Condenser Water Temperature {C}",
            "  autosize,                           !- Reference Chilled Water Flow Rate {m3/s}",
            "  autosize,                           !- Reference Condenser Water Flow Rate {m3/s}",
            "  DummyCapfT,                         !- Cooling Capacity Function of Temperature Curve Name",
            "  DummyEIRfT,                         !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name",
            "  LeavingCondenserWaterTemperature,   !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Type",
            "  DummyEIRfPLR,                       !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
            "  0.10,                               !- Minimum Part Load Ratio",
            "  1.00,                               !- Maximum Part Load Ratio",
            "  1.00,                               !- Optimum Part Load Ratio",
            "  0.25,                               !- Minimum Unloading Ratio",
            "  CHW Inlet Node,                     !- Chilled Water Inlet Node Name",
            "  CHW Outlet Node,                    !- Chilled Water Outlet Node Name",
            "  Condenser Inlet Node,               !- Condenser Inlet Node Name",
            "  Condenser Outlet Node,              !- Condenser Outlet Node Name",
            "  1,                                  !- Fraction of Compressor Electric Consumption Rejected by Condenser",
            "  2,                                  !- Leaving Chilled Water Lower Temperature Limit {C}",
            "  ConstantFlow,                       !- Chiller Flow Mode Type",
            "  autosize,                           !- Design Heat Recovery Water Flow Rate {m3/s}",
            "  HetRec Inlet Node,                  !- Heat Recovery Inlet Node Name",
            "  HetRec Outlet Node,                 !- Heat Recovery Outlet Node Name",
            "  1.00,                               !- Sizing Factor",
            "  0.30,                               !- Condenser Heat Recovery Relative Capacity Fraction",
            "  ,                                   !- Heat Recovery Inlet High Temperature Limit Schedule Name",
            "  HetRec Outlet Node,                 !- Heat Recovery Leaving Temperature Setpoint Node Name",
            "  ,                                   !- End-Use Subcategory",
            "  ModulatedLoopPLR,                   !- Condenser Flow Control",
            "  Y=F(X),                             !- Condenser Loop Flow Rate Fraction Function of Loop Part Load Ratio Curve Name",
            "  CondenserdT,                        !- Temperature Difference Across Condenser Schedule Name",
            "  0.35,                               !- Condenser Minimum Flow Fraction",
            "  ThermoCapFracCurve;                 !- Thermosiphon Capacity Fraction Curve Name",
            "Curve:Linear, ThermoCapFracCurve, 0.0, 0.06, 0.0, 1.0, 0.0, 1.0, Dimensionless, Dimensionless;",
            "Curve:Linear,Y=F(X),0,1,0,1;",
            "Schedule:Constant,CondenserdT,,10.0;"
            "Curve:Biquadratic, DummyCapfT, 1, 0, 0, 0, 0, 0, 5, 10, 24, 35, , , , , ;",
            "Curve:Biquadratic, DummyEIRfT, 1, 0,  0, 0, 0, 0,   5, 10, 24, 35, , , , , ;",
            "Curve:Biquadratic,",
            "  DummyEIRfPLR,                           !- Name",
            "  1,                                      !- Coefficient1 Constant",
            "  0,                                      !- Coefficient2 x",
            "  0,                                      !- Coefficient3 x**2",
            "  0,                                      !- Coefficient4 y",
            "  0,                                      !- Coefficient5 y**2",
            "  0,                                      !- Coefficient6 x*y",
            "  5,                                      !- Minimum Value of x {BasedOnField A2}",
            "  10,                                     !- Maximum Value of x {BasedOnField A2}",
            "  0.02,                                   !- Minimum Value of y {BasedOnField A3}",
            "  1,                                      !- Maximum Value of y {BasedOnField A3}",
            "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
            "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
            "  ,                                       !- Input Unit Type for X",
            "  ,                                       !- Input Unit Type for Y",
            "  ;                                       !- Output Unit Type",
        ])
        EXPECT_TRUE(process_idf(idf_objects, False))
        state.init_state(state)
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataSize.PlantSizData.allocate(state.dataPlnt.TotNumLoops)
        for l in range(1, state.dataPlnt.TotNumLoops + 1):
            var loopside = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand)
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        GetElecReformEIRChillerInput(state)
        var thisChiller = state.dataChillerReformulatedEIR.ElecReformEIRChiller[1]
        var num_nodes: Int = 10
        state.dataLoopNodes.Node.allocate(num_nodes)
        state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
        state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[1].TempSetPointNodeNum = 10
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Name = "WaterChiller Supply Branch"
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = thisChiller.Name
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = thisChiller.EvapInletNodeNum
        state.dataPlnt.PlantLoop[1].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumOut = thisChiller.EvapOutletNodeNum
        state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
        state.dataPlnt.PlantLoop[1].LoopSide(EnergyPlus.DataPlant.LoopSideLocation.Demand).TempSetPoint = 4.4
        state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].TempSetPoint = 4.4
        state.dataSize.PlantSizData[1].DesVolFlowRate = 0.02
        state.dataSize.PlantSizData[1].DeltaT = 5.0
        state.dataPlnt.PlantLoop[2].Name = "CondenserWaterLoop"
        state.dataPlnt.PlantLoop[2].PlantSizNum = 2
        state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Name = "WaterChiller Condenser Branch"
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = thisChiller.Name
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = thisChiller.CondInletNodeNum
        state.dataPlnt.PlantLoop[2].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumOut = thisChiller.CondOutletNodeNum
        state.dataSize.PlantSizData[2].DesVolFlowRate = 0.03
        state.dataSize.PlantSizData[2].DeltaT = 5.0
        state.dataPlnt.PlantLoop[3].Name = "HecRecWaterLoop"
        state.dataPlnt.PlantLoop[3].PlantSizNum = 3
        state.dataPlnt.PlantLoop[3].FluidName = "WATER"
        state.dataPlnt.PlantLoop[3].glycol = Fluid.GetWater(state)
        state.dataPlnt.PlantLoop[3].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Name = "WaterChiller HecRec Branch"
        state.dataPlnt.PlantLoop[3].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Name = thisChiller.Name
        state.dataPlnt.PlantLoop[3].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_ElectricReformEIR
        state.dataPlnt.PlantLoop[3].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumIn = thisChiller.HeatRecInletNodeNum
        state.dataPlnt.PlantLoop[3].LoopSide(DataPlant.LoopSideLocation.Demand).Branch[1].Comp[1].NodeNumOut = thisChiller.HeatRecOutletNodeNum
        state.dataSize.PlantSizData[3].DesVolFlowRate = 0.03
        state.dataSize.PlantSizData[3].DeltaT = 5.0
        for n in range(1, num_nodes + 1):
            state.dataLoopNodes.Node[n].MassFlowRateMaxAvail = 2.0
            state.dataLoopNodes.Node[n].MassFlowRateMax = 2.0
        state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        state.dataPlnt.PlantFirstSizesOkayToReport = True
        state.dataPlnt.PlantFinalSizesOkayToReport = False
        var MyLoad: Float64 = 0.0
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.size(state)
        MyLoad = -thisChiller.RefCap
        state.dataSize.PlantSizData[1].DesCapacity = abs(MyLoad) * 2
        Sched.UpdateScheduleVals(state)
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataPlnt.PlantFinalSizesOkayToReport = True
        thisChiller.initialize(state, RunFlag, MyLoad)
        thisChiller.size(state)
        var orp = state.dataOutRptPredefined
        var ChillerName: String = thisChiller.Name
        EXPECT_EQ("Chiller:Electric:ReformulatedEIR", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerType, ChillerName))
        EXPECT_EQ("419750.18", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefCap, ChillerName))
        EXPECT_EQ("3.50", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefEff, ChillerName))
        EXPECT_EQ("419750.18", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedCap, ChillerName))
        EXPECT_EQ("3.50", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedEff, ChillerName))
        EXPECT_EQ("2.03", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerIPLVinSI, ChillerName))
        EXPECT_EQ("2.03", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerIPLVinIP, ChillerName))
        EXPECT_EQ("0.10", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerMinPLR, ChillerName))
        EXPECT_EQ("Electricity", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerFuelType, ChillerName))
        EXPECT_EQ("30.33", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedEntCondTemp, ChillerName))
        EXPECT_EQ("5.67", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRatedLevEvapTemp, ChillerName))
        EXPECT_EQ("30.33", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefEntCondTemp, ChillerName))
        EXPECT_EQ("5.67", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRefLevEvapTemp, ChillerName))
        EXPECT_EQ("20.00", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerDesSizeRefCHWFlowRate, ChillerName))
        EXPECT_EQ("25.49", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerDesSizeRefCondFluidFlowRate, ChillerName))
        EXPECT_EQ("ChilledWaterLoop", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerPlantloopName, ChillerName))
        EXPECT_EQ("WaterChiller Supply Branch", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerPlantloopBranchName, ChillerName))
        EXPECT_EQ("CondenserWaterLoop", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerCondLoopName, ChillerName))
        EXPECT_EQ("WaterChiller Condenser Branch", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerCondLoopBranchName, ChillerName))
        EXPECT_EQ("HecRecWaterLoop", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerHeatRecPlantloopName, ChillerName))
        EXPECT_EQ("WaterChiller HecRec Branch", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerHeatRecPlantloopBranchName, ChillerName))
        EXPECT_EQ("0.30", OutputReportPredefined.RetrievePreDefTableEntry(state, orp.pdchChillerRecRelCapFrac, ChillerName))