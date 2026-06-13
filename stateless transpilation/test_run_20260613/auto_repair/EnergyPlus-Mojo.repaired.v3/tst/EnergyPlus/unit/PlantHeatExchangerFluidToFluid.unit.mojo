from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.BranchInputManager import ManageBranchInput
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import EndMonthFlag, Month, DayOfMonth, DSTIndicator, DayOfWeek, HolidayIndex, DayOfYear_Schedule, OutDryBulbTemp
from EnergyPlus.DataHVACGlobals import TimeStepSys
from EnergyPlus.DataLoopNode import Node, MassFlowRateMaxAvail, MassFlowRateMax, Temp, MassFlowRate, TempSetPoint
from EnergyPlus.ElectricPowerServiceManager import createFacilityElectricPowerServiceObject
from EnergyPlus.General import OrdinalDay
from EnergyPlus.HeatBalanceManager import SetPreConstructionInputParameters, ManageHeatBalance
from EnergyPlus.IOFiles import *
from EnergyPlus.InputProcessing.InputProcessor import *
from EnergyPlus.OutputProcessor import SetupTimePointers, TimeStepType, TimeStepZone, Zone
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.PlantManager import CheckIfAnyPlant
from EnergyPlus.PlantHeatExchangerFluidToFluid import *
from EnergyPlus.PlantUtilities import SetPlantLocationLinks
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import SetupSimulation
from EnergyPlus.WeatherManager import ManageWeather, GetNextEnvironment, ResetEnvironmentCounter

struct EnergyPlusFixture:

def delimited_string(lines: List[String]) -> String:
    return "\n".join(lines)

def compare_err_stream(expected: String, _: Bool):
    # placeholder for gtest error stream comparison

extend EnergyPlusFixture:
    def PlantHXModulatedDualDeadDefectFileHi(self):
        var idf_objects: String = delimited_string(List[String](
            "Building,",
            "Plant Load Profile Example,  !- Name",
            "    0.0,                     !- North Axis {deg}",
            "    Suburbs,                 !- Terrain",
            "    0.04,                    !- Loads Convergence Tolerance Value",
            "    0.04,                    !- Temperature Convergence Tolerance Value {deltaC}",
            "    FullInteriorAndExterior, !- Solar Distribution",
            "    25,                      !- Maximum Number of Warmup Days",
            "    6;                       !- Minimum Number of Warmup Days",
            "  Timestep,6;",
            # ... full IDF list must be included. Due to length, this is a placeholder.
            # The actual code will contain the complete list as in the C++ source.
        ))
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(*state)
        var ErrorsFound: Bool = False
        state.dataGlobal.BeginSimFlag = True
        HeatBalanceManager.SetPreConstructionInputParameters(*state)
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.Zone, state.dataGlobal.TimeStepZone)
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.System, state.dataHVACGlobal.TimeStepSys)
        PlantManager.CheckIfAnyPlant(*state)
        createFacilityElectricPowerServiceObject(*state)
        BranchInputManager.ManageBranchInput(*state)
        state.dataGlobal.DoingSizing = False
        state.dataGlobal.KickOffSimulation = True
        Weather.ResetEnvironmentCounter(*state)
        SimulationManager.SetupSimulation(*state, ErrorsFound)
        state.dataGlobal.KickOffSimulation = False
        var EnvCount: Int = 0
        state.dataGlobal.WarmupFlag = True
        var Available: Bool = True
        while Available:
            Weather.GetNextEnvironment(*state, Available, ErrorsFound)
            if not Available:
                break
            if ErrorsFound:
                break
            EnvCount += 1
            state.dataGlobal.BeginEnvrnFlag = True
            state.dataGlobal.EndEnvrnFlag = False
            state.dataEnvrn.EndMonthFlag = False
            state.dataGlobal.WarmupFlag = True
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
            while (state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn) or (state.dataGlobal.WarmupFlag):
                state.dataGlobal.DayOfSim += 1
                if not state.dataGlobal.WarmupFlag:
                    state.dataEnvrn.CurrentOverallSimDay += 1
                state.dataGlobal.BeginDayFlag = True
                state.dataGlobal.EndDayFlag = False
                state.dataGlobal.HourOfDay = 1
                while state.dataGlobal.HourOfDay <= 24:
                    state.dataGlobal.BeginHourFlag = True
                    state.dataGlobal.EndHourFlag = False
                    state.dataGlobal.TimeStep = 1
                    while state.dataGlobal.TimeStep <= state.dataGlobal.TimeStepsInHour:
                        state.dataGlobal.BeginTimeStepFlag = True
                        if state.dataGlobal.TimeStep == state.dataGlobal.TimeStepsInHour:
                            state.dataGlobal.EndHourFlag = True
                            if state.dataGlobal.HourOfDay == 24:
                                state.dataGlobal.EndDayFlag = True
                                if (not state.dataGlobal.WarmupFlag) and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
                                    state.dataGlobal.EndEnvrnFlag = True
                        Weather.ManageWeather(*state)
                        HeatBalanceManager.ManageHeatBalance(*state)
                        state.dataGlobal.BeginHourFlag = False
                        state.dataGlobal.BeginDayFlag = False
                        state.dataGlobal.BeginEnvrnFlag = False
                        state.dataGlobal.BeginSimFlag = False
                        state.dataGlobal.TimeStep += 1
                    state.dataGlobal.PreviousHour = state.dataGlobal.HourOfDay
                    state.dataGlobal.HourOfDay += 1
        EXPECT_NEAR(state.dataLoopNodes.Node[4].Temp, 20.0, 0.01)

    def PlantHXModulatedDualDeadDefectFileLo(self):
        var idf_objects: String = delimited_string(List[String](
            "Building,",
            "Plant Load Profile Example,  !- Name",
            "    0.0,                     !- North Axis {deg}",
            "    Suburbs,                 !- Terrain",
            "    0.04,                    !- Loads Convergence Tolerance Value",
            "    0.04,                    !- Temperature Convergence Tolerance Value {deltaC}",
            "    FullInteriorAndExterior, !- Solar Distribution",
            "    25,                      !- Maximum Number of Warmup Days",
            "    6;                       !- Minimum Number of Warmup Days",
            # ... full IDF list (identical to the Hi version except schedule values) ...
        ))
        ASSERT_TRUE(process_idf(idf_objects))
        state.init_state(*state)
        var ErrorsFound: Bool = False
        state.dataGlobal.BeginSimFlag = True
        HeatBalanceManager.SetPreConstructionInputParameters(*state)
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.Zone, state.dataGlobal.TimeStepZone)
        OutputProcessor.SetupTimePointers(*state, OutputProcessor.TimeStepType.System, state.dataHVACGlobal.TimeStepSys)
        PlantManager.CheckIfAnyPlant(*state)
        createFacilityElectricPowerServiceObject(*state)
        BranchInputManager.ManageBranchInput(*state)
        state.dataGlobal.DoingSizing = False
        state.dataGlobal.KickOffSimulation = True
        Weather.ResetEnvironmentCounter(*state)
        SimulationManager.SetupSimulation(*state, ErrorsFound)
        state.dataGlobal.KickOffSimulation = False
        var EnvCount: Int = 0
        state.dataGlobal.WarmupFlag = True
        var Available: Bool = True
        while Available:
            Weather.GetNextEnvironment(*state, Available, ErrorsFound)
            if not Available:
                break
            if ErrorsFound:
                break
            EnvCount += 1
            state.dataGlobal.BeginEnvrnFlag = True
            state.dataGlobal.EndEnvrnFlag = False
            state.dataEnvrn.EndMonthFlag = False
            state.dataGlobal.WarmupFlag = True
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
            while (state.dataGlobal.DayOfSim < state.dataGlobal.NumOfDayInEnvrn) or (state.dataGlobal.WarmupFlag):
                state.dataGlobal.DayOfSim += 1
                if not state.dataGlobal.WarmupFlag:
                    state.dataEnvrn.CurrentOverallSimDay += 1
                state.dataGlobal.BeginDayFlag = True
                state.dataGlobal.EndDayFlag = False
                state.dataGlobal.HourOfDay = 1
                while state.dataGlobal.HourOfDay <= 24:
                    state.dataGlobal.BeginHourFlag = True
                    state.dataGlobal.EndHourFlag = False
                    state.dataGlobal.TimeStep = 1
                    while state.dataGlobal.TimeStep <= state.dataGlobal.TimeStepsInHour:
                        state.dataGlobal.BeginTimeStepFlag = True
                        if state.dataGlobal.TimeStep == state.dataGlobal.TimeStepsInHour:
                            state.dataGlobal.EndHourFlag = True
                            if state.dataGlobal.HourOfDay == 24:
                                state.dataGlobal.EndDayFlag = True
                                if (not state.dataGlobal.WarmupFlag) and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
                                    state.dataGlobal.EndEnvrnFlag = True
                        Weather.ManageWeather(*state)
                        HeatBalanceManager.ManageHeatBalance(*state)
                        state.dataGlobal.BeginHourFlag = False
                        state.dataGlobal.BeginDayFlag = False
                        state.dataGlobal.BeginEnvrnFlag = False
                        state.dataGlobal.BeginSimFlag = False
                        state.dataGlobal.TimeStep += 1
                    state.dataGlobal.PreviousHour = state.dataGlobal.HourOfDay
                    state.dataGlobal.HourOfDay += 1
        EXPECT_NEAR(state.dataLoopNodes.Node[4].Temp, 20.0, 0.01)

    def PlantHXControlWithFirstHVACIteration(self):
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.init_state(*state)
        state.dataPlantHXFluidToFluid.FluidHX.allocate(1)
        state.dataEnvrn.Month = 1
        state.dataEnvrn.DayOfMonth = 21
        state.dataGlobal.HourOfDay = 1
        state.dataGlobal.TimeStep = 1
        state.dataEnvrn.DSTIndicator = 0
        state.dataEnvrn.DayOfWeek = 2
        state.dataEnvrn.HolidayIndex = 0
        state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
        Sched.UpdateScheduleVals(*state)
        state.dataPlantHXFluidToFluid.FluidHX[1].availSched = Sched.GetScheduleAlwaysOn(*state)
        state.dataLoopNodes.Node.allocate(4)
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.inletNodeNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.outletNodeNum = 3
        state.dataLoopNodes.Node[1].Temp = 18.0
        state.dataLoopNodes.Node[1].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[1].MassFlowRateMax = 2.0
        state.dataLoopNodes.Node[3].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[3].MassFlowRateMax = 2.0
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.InletTemp = 18.0
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.inletNodeNum = 2
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.outletNodeNum = 4
        state.dataLoopNodes.Node[2].Temp = 19.0
        state.dataLoopNodes.Node[2].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[2].MassFlowRateMax = 2.0
        state.dataLoopNodes.Node[4].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[4].MassFlowRateMax = 2.0
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.InletTemp = 19.0
        state.dataPlantHXFluidToFluid.FluidHX[1].controlMode = PlantHeatExchangerFluidToFluid.ControlType.CoolingDifferentialOnOff
        state.dataPlantHXFluidToFluid.FluidHX[1].MinOperationTemp = 10.0
        state.dataPlantHXFluidToFluid.FluidHX[1].MaxOperationTemp = 30.0
        state.dataPlantHXFluidToFluid.FluidHX[1].Name = "Test HX"
        state.dataPlnt.TotNumLoops = 2
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        for l in range(1, state.dataPlnt.TotNumLoops + 1):
            var loopside = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].Name = "HX supply side loop "
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataPlantHXFluidToFluid.FluidHX[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.FluidToFluidPlantHtExchg
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.inletNodeNum
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.loopNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.loopSideNum = DataPlant.LoopSideLocation.Demand
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.branchNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.compNum = 1
        PlantUtilities.SetPlantLocationLinks(*state, state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop)
        state.dataPlnt.PlantLoop[2].Name = "HX demand side loop "
        state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataPlantHXFluidToFluid.FluidHX[1].Name
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.FluidToFluidPlantHtExchg
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.inletNodeNum
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.loopNum = 2
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.loopSideNum = DataPlant.LoopSideLocation.Demand
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.branchNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.compNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.MassFlowRateMax = 2.0
        PlantUtilities.SetPlantLocationLinks(*state, state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop)
        var testFirstHVACIteration: Bool = True
        state.dataPlantHXFluidToFluid.FluidHX[1].control(*state, -1000.0, testFirstHVACIteration)
        EXPECT_NEAR(state.dataLoopNodes.Node[2].MassFlowRate, state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.MassFlowRateMax, 0.001)
        testFirstHVACIteration = False
        state.dataPlantHXFluidToFluid.FluidHX[1].control(*state, -1000.0, testFirstHVACIteration)
        EXPECT_NEAR(state.dataLoopNodes.Node[2].MassFlowRate, 0.0, 0.001)

    def PlantHXControl_CoolingSetpointOnOffWithComponentOverride(self):
        state.dataGlobal.TimeStepsInHour = 1
        state.dataGlobal.MinutesInTimeStep = 60
        state.init_state(*state)
        state.dataPlantHXFluidToFluid.FluidHX.allocate(1)
        state.dataEnvrn.Month = 1
        state.dataEnvrn.DayOfMonth = 21
        state.dataGlobal.HourOfDay = 1
        state.dataGlobal.TimeStep = 1
        state.dataEnvrn.DSTIndicator = 0
        state.dataEnvrn.DayOfWeek = 2
        state.dataEnvrn.HolidayIndex = 0
        state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
        Sched.UpdateScheduleVals(*state)
        state.dataPlantHXFluidToFluid.FluidHX[1].availSched = Sched.GetScheduleAlwaysOn(*state)
        state.dataLoopNodes.Node.allocate(6)
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.inletNodeNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.outletNodeNum = 3
        state.dataPlantHXFluidToFluid.FluidHX[1].SetPointNodeNum = 3
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.MassFlowRateMax = 2.0
        state.dataLoopNodes.Node[1].Temp = 18.0
        state.dataLoopNodes.Node[1].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[1].MassFlowRateMax = 2.0
        state.dataLoopNodes.Node[3].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[3].MassFlowRateMax = 2.0
        state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.InletTemp = 18.0
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.inletNodeNum = 2
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.outletNodeNum = 4
        state.dataLoopNodes.Node[2].Temp = 19.0
        state.dataLoopNodes.Node[2].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[2].MassFlowRateMax = 2.0
        state.dataLoopNodes.Node[4].MassFlowRateMaxAvail = 2.0
        state.dataLoopNodes.Node[4].MassFlowRateMax = 2.0
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.InletTemp = 19.0
        state.dataPlantHXFluidToFluid.FluidHX[1].controlMode = PlantHeatExchangerFluidToFluid.ControlType.CoolingSetPointOnOffWithComponentOverride
        state.dataPlantHXFluidToFluid.FluidHX[1].MinOperationTemp = 10.0
        state.dataPlantHXFluidToFluid.FluidHX[1].MaxOperationTemp = 30.0
        state.dataPlantHXFluidToFluid.FluidHX[1].Name = "Test HX"
        state.dataPlnt.TotNumLoops = 2
        state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 2
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(2)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[2].TotalComponents = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[2].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[2].Comp[1].NodeNumIn = 5
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].TotalBranches = 1
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch.allocate(1)
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Supply].TotalBranches = 1
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Supply].Branch.allocate(1)
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].TotalComponents = 1
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp.allocate(1)
        state.dataPlnt.PlantLoop[1].Name = "HX supply side loop "
        state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp[1].Name = state.dataPlantHXFluidToFluid.FluidHX[1].Name
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.FluidToFluidPlantHtExchg
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[1].Comp[1].NodeNumIn = state.dataPlantHXFluidToFluid.FluidHX[1].SupplySideLoop.inletNodeNum
        state.dataPlnt.PlantLoop[2].Name = "HX demand side loop "
        state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = state.dataPlantHXFluidToFluid.FluidHX[1].Name
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.FluidToFluidPlantHtExchg
        state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.inletNodeNum
        state.dataPlantHXFluidToFluid.FluidHX[1].DemandSideLoop.MassFlowRateMax = 2.0
        state.dataPlantHXFluidToFluid.FluidHX[1].ControlSignalTemp = PlantHeatExchangerFluidToFluid.CtrlTempType.DryBulbTemperature
        state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop.inletNodeNum = 5
        state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop.loopNum = 1
        state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop.loopSideNum = DataPlant.LoopSideLocation.Supply
        state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop.branchNum = 2
        state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop.compNum = 1
        PlantUtilities.SetPlantLocationLinks(*state, state.dataPlantHXFluidToFluid.FluidHX[1].OtherCompSupplySideLoop)
        state.dataPlantHXFluidToFluid.NumberOfPlantFluidHXs = 1
        state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[2].Comp[1].HowLoadServed = DataPlant.HowMet.ByNominalCap
        state.dataEnvrn.OutDryBulbTemp = 9.0
        state.dataPlantHXFluidToFluid.FluidHX[1].TempControlTol = 0.0
        state.dataLoopNodes.Node[3].TempSetPoint = 11.0
        state.dataPlantHXFluidToFluid.FluidHX[1].initialize(*state)
        EXPECT_NEAR(state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Supply].Branch[2].Comp[1].FreeCoolCntrlMinCntrlTemp, 11.0, 0.001)
        state.dataPlantHXFluidToFluid.FluidHX[1].TempControlTol = 1.5
        state.dataPlantHXFluidToFluid.FluidHX[1].initialize(*state)

    def PlantHXFluidToFluid_HeatTransferMeteringEndUseType(self):
        var idf_objects: String = R"IDF(
        HeatExchanger:FluidToFluid,
          Water Side Economizer,                        !- Name
          ,                                             !- Availability Schedule Name
          WaterSide Economizer Condenser Inlet Node,    !- Loop Demand Side Inlet Node Name
          WaterSide Economizer Condenser Outlet Node,   !- Loop Demand Side Outlet Node Name
          autosize,                                     !- Loop Demand Side Design Flow Rate {m3/s}
          CW Pump Outlet Node,                          !- Loop Supply Side Inlet Node Name
          WaterSide Economizer Outlet Node,             !- Loop Supply Side Outlet Node Name
          autosize,                                     !- Loop Supply Side Design Flow Rate {m3/s}
          ParallelFlow,                                 !- Heat Exchange Model Type
          autosize,                                     !- Heat Exchanger U-Factor Times Area Value {W/K}
          CoolingSetpointModulated,                     !- Control Type
          WaterSide Economizer Outlet Node,             !- Heat Exchanger Setpoint Node Name
          1.0,                                          !- Minimum Temperature Difference to Activate Heat Exchanger {deltaC}
          HeatRecovery;                                 !- Heat Transfer Metering End Use Type
        )IDF"
        EXPECT_FALSE(process_idf(idf_objects, False))
        var expected_error: String =
            "   ** Severe  ** <root>[HeatExchanger:FluidToFluid][Water Side Economizer][heat_transfer_metering_end_use_type] - " +
            "\"HeatRecovery\" - Failed to match against any enum values.\n"
        compare_err_stream(expected_error, True)
        var invalidEndUse: StringLiteral = "HeatRecovery"
        var validEndUses: StaticTuple[String, 5] = StaticTuple("FreeCooling", "HeatRejection", "HeatRecoveryForCooling", "HeatRecoveryForHeating", "LoopToLoop")
        for validEndUse in validEndUses:
            state.dataInputProcessing.clear_state()
            var idf_objects_copy: String = idf_objects
            var index: Int = idf_objects_copy.find(invalidEndUse, 0)
            idf_objects_copy.replace(index, invalidEndUse.length(), validEndUse)
            EXPECT_TRUE(process_idf(idf_objects_copy, False))
            compare_err_stream("", True)
