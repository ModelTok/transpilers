from gtest import Test, Expect
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.CurveManager import Curve
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantChillers import PlantChillers, ElectricChillerSpecs
from EnergyPlus.Psychrometrics import Psychrometrics
from EnergyPlus.DataBranchAirLoopPlant import DataBranchAirLoopPlant
from EnergyPlus.DataLoopNodes import DataLoopNodes
from EnergyPlus.Fluid import Fluid
from EnergyPlus.Constant import Constant

struct ChillerElectric_WaterCooled_Autosize(EnergyPlusFixture):
    def run(self):
        self.state.dataPlnt.TotNumLoops = 4
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.StdRhoAir = 1.20
        self.state.dataGlobal.TimeStepsInHour = 1
        self.state.dataGlobal.TimeStep = 1
        self.state.dataGlobal.MinutesInTimeStep = 60
        var idf_objects: String = delimited_string([
            "  Chiller:Electric,",
            "    Big Chiller,             !- Name",
            "    WaterCooled,             !- Condenser Type",
            "    100000.0,                !- Nominal Capacity {W}",
            "    4.75,                    !- Nominal COP {W/W}",
            "    Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
            "    Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
            "    Big Cond Inlet Node,     !- Condenser Inlet Node Name",
            "    Big Cond Outlet Node,    !- Condenser Outlet Node Name",
            "    0.15,                    !- Minimum Part Load Ratio",
            "    1.0,                     !- Maximum Part Load Ratio",
            "    0.65,                    !- Optimum Part Load Ratio",
            "    29.44,                   !- Design Condenser Inlet Temperature {C}",
            "    2.682759,                !- Temperature Rise Coefficient",
            "    6.667,                   !- Design Chilled Water Outlet Temperature {C}",
            "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}",
            "    0.0011,                  !- Design Condenser Fluid Flow Rate {m3/s}",
            "    0.94483600,              !- Coefficient 1 of Capacity Ratio Curve",
            "    -.05700880,              !- Coefficient 2 of Capacity Ratio Curve",
            "    -.00185486,              !- Coefficient 3 of Capacity Ratio Curve",
            "    1.907846,                !- Coefficient 1 of Power Ratio Curve",
            "    -1.20498700,             !- Coefficient 2 of Power Ratio Curve",
            "    0.26346230,              !- Coefficient 3 of Power Ratio Curve",
            "    0.03303,                 !- Coefficient 1 of Full Load Ratio Curve",
            "    0.6852,                  !- Coefficient 2 of Full Load Ratio Curve",
            "    0.2818,                  !- Coefficient 3 of Full Load Ratio Curve",
            "    5,                       !- Chilled Water Outlet Temperature Lower Limit {C}",
            "    LeavingSetpointModulated;!- Chiller Flow Mode",
        ])
        Expect(process_idf(idf_objects, false))
        self.state.init_state(self.state)
        self.state.dataPlnt.PlantLoop.allocate(self.state.dataPlnt.TotNumLoops)
        self.state.dataPlnt.PlantLoop.allocate(self.state.dataPlnt.TotNumLoops)
        for l in range(1, self.state.dataPlnt.TotNumLoops + 1):
            var loopside = self.state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = self.state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        ElectricChillerSpecs.getInput(self.state)
        self.state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
        self.state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = self.state.dataPlantChillers.ElectricChiller[1].Name
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_Electric
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = self.state.dataPlantChillers.ElectricChiller[1].EvapInletNodeNum
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = self.state.dataPlantChillers.ElectricChiller[1].EvapOutletNodeNum
        self.state.dataPlnt.PlantLoop[2].Name = "CondenserWaterLoop"
        self.state.dataPlnt.PlantLoop[2].PlantSizNum = 2
        self.state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = self.state.dataPlantChillers.ElectricChiller[1].Name
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_Electric
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = self.state.dataPlantChillers.ElectricChiller[1].CondInletNodeNum
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = self.state.dataPlantChillers.ElectricChiller[1].CondOutletNodeNum
        self.state.dataSize.PlantSizData.allocate(2)
        self.state.dataSize.PlantSizData[1].DesVolFlowRate = 0.001
        self.state.dataSize.PlantSizData[1].DeltaT = 5.0
        self.state.dataSize.PlantSizData[2].DesVolFlowRate = 0.001
        self.state.dataSize.PlantSizData[2].DeltaT = 5.0
        self.state.dataPlnt.PlantFirstSizesOkayToFinalize = true
        self.state.dataPlnt.PlantFirstSizesOkayToReport = true
        self.state.dataPlnt.PlantFinalSizesOkayToReport = true
        var RunFlag: Bool = true
        var MyLoad: Float64 = -20000.0
        var thisChiller = self.state.dataPlantChillers.ElectricChiller[1]
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.size(self.state)
        self.state.dataGlobal.BeginEnvrnFlag = true
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].NomCap, 100000.00)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRate, 0.0011)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRate, 0.0011)
        self.state.dataPlantChillers.ElectricChiller[1].NomCap = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRate = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRate = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].NomCapWasAutoSized = true
        self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRateWasAutoSized = true
        self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRateWasAutoSized = true
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.size(self.state)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].NomCap, 20987.509055700004)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRate, 0.0010000000000000000)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRate, 0.0012208075356136608)

struct ChillerElectric_WaterCooled_Simulate(EnergyPlusFixture):
    def run(self):
        self.state.dataPlnt.TotNumLoops = 4
        self.state.dataEnvrn.OutBaroPress = 101325.0
        self.state.dataEnvrn.StdRhoAir = 1.20
        self.state.dataGlobal.TimeStepsInHour = 1
        self.state.dataGlobal.TimeStep = 1
        self.state.dataGlobal.MinutesInTimeStep = 60
        self.state.dataHVACGlobal.TimeStepSys = 60
        self.state.dataHVACGlobal.TimeStepSysSec = self.state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
        var idf_objects: String = delimited_string([
            "  Chiller:Electric,",
            "    Big Chiller,             !- Name",
            "    WaterCooled,             !- Condenser Type",
            "    100000.0,                !- Nominal Capacity {W}",
            "    4.75,                    !- Nominal COP {W/W}",
            "    Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
            "    Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
            "    Big Cond Inlet Node,     !- Condenser Inlet Node Name",
            "    Big Cond Outlet Node,    !- Condenser Outlet Node Name",
            "    0.15,                    !- Minimum Part Load Ratio",
            "    1.0,                     !- Maximum Part Load Ratio",
            "    0.65,                    !- Optimum Part Load Ratio",
            "    29.44,                   !- Design Condenser Inlet Temperature {C}",
            "    2.682759,                !- Temperature Rise Coefficient",
            "    6.667,                   !- Design Chilled Water Outlet Temperature {C}",
            "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}",
            "    0.0011,                  !- Design Condenser Fluid Flow Rate {m3/s}",
            "    0.94483600,              !- Coefficient 1 of Capacity Ratio Curve",
            "    -.05700880,              !- Coefficient 2 of Capacity Ratio Curve",
            "    -.00185486,              !- Coefficient 3 of Capacity Ratio Curve",
            "    1.907846,                !- Coefficient 1 of Power Ratio Curve",
            "    -1.20498700,             !- Coefficient 2 of Power Ratio Curve",
            "    0.26346230,              !- Coefficient 3 of Power Ratio Curve",
            "    0.03303,                 !- Coefficient 1 of Full Load Ratio Curve",
            "    0.6852,                  !- Coefficient 2 of Full Load Ratio Curve",
            "    0.2818,                  !- Coefficient 3 of Full Load Ratio Curve",
            "    5,                       !- Chilled Water Outlet Temperature Lower Limit {C}",
            "    LeavingSetpointModulated,!- Chiller Flow Mode",
            "    ,                        !- Design Heat Recovery Water Flow Rate",
            "    ,                        !- Heat Recovery Inlet Node Name",
            "    ,                        !- Heat Recovery Outlet Node Name",
            "    ,                        !- Sizing Factor",
            "    ,                        !- Basin Heater Capacity",
            "    ,                        !- Basin Heater Setpoint Temperature",
            "    ,                        !- Basin Heater Operating Schedule Name",
            "    ,                        !- Condenser Heat Recovery Relative Capacity Fraction",
            "    ,                        !- Heat Recovery Inlet High Temperature Limit Schedule Name",
            "    ,                        !- Heat Recovery Leaving Temperature Setpoint Node Name",
            "    ,                        !- End-Use Subcategory",
            "    ThermoCapFracCurve;      !- Thermosiphon Capacity Fraction Curve Name",
            "  Curve:Linear,",
            "    ThermoCapFracCurve,      !- Name",
            "    0.0,                     !- Coefficient1 Constant",
            "    0.06,                    !- Coefficient2 x",
            "    0.0,                     !- Minimum Value of x",
            "    10.0,                    !- Maximum Value of x",
            "    0.0,                     !- Minimum Curve Output",
            "    1.0,                     !- Maximum Curve Output",
            "    Dimensionless,           !- Input Unit Type for X",
            "    Dimensionless;           !- Output Unit Type",
        ])
        Expect(process_idf(idf_objects, false))
        self.state.init_state(self.state)
        self.state.dataPlnt.PlantLoop.allocate(self.state.dataPlnt.TotNumLoops)
        self.state.dataPlnt.PlantLoop.allocate(self.state.dataPlnt.TotNumLoops)
        for l in range(1, self.state.dataPlnt.TotNumLoops + 1):
            var loopside = self.state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand]
            loopside.TotalBranches = 1
            loopside.Branch.allocate(1)
            var loopsidebranch = self.state.dataPlnt.PlantLoop[l].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1]
            loopsidebranch.TotalComponents = 1
            loopsidebranch.Comp.allocate(1)
        ElectricChillerSpecs.getInput(self.state)
        self.state.dataPlnt.PlantLoop[1].Name = "ChilledWaterLoop"
        self.state.dataPlnt.PlantLoop[1].PlantSizNum = 1
        self.state.dataPlnt.PlantLoop[1].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[1].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = self.state.dataPlantChillers.ElectricChiller[1].Name
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_Electric
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = self.state.dataPlantChillers.ElectricChiller[1].EvapInletNodeNum
        self.state.dataPlnt.PlantLoop[1].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = self.state.dataPlantChillers.ElectricChiller[1].EvapOutletNodeNum
        self.state.dataPlnt.PlantLoop[1].LoopDemandCalcScheme = DataPlant.LoopDemandCalcScheme.SingleSetPoint
        self.state.dataPlnt.PlantLoop[1].TempSetPointNodeNum = self.state.dataPlantChillers.ElectricChiller[1].EvapOutletNodeNum
        self.state.dataPlnt.PlantLoop[2].Name = "CondenserWaterLoop"
        self.state.dataPlnt.PlantLoop[2].PlantSizNum = 2
        self.state.dataPlnt.PlantLoop[2].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[2].glycol = Fluid.GetWater(self.state)
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Name = self.state.dataPlantChillers.ElectricChiller[1].Name
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].Type = DataPlant.PlantEquipmentType.Chiller_Electric
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumIn = self.state.dataPlantChillers.ElectricChiller[1].CondInletNodeNum
        self.state.dataPlnt.PlantLoop[2].LoopSide[DataPlant.LoopSideLocation.Demand].Branch[1].Comp[1].NodeNumOut = self.state.dataPlantChillers.ElectricChiller[1].CondOutletNodeNum
        self.state.dataSize.PlantSizData.allocate(2)
        self.state.dataSize.PlantSizData[1].DesVolFlowRate = 0.001
        self.state.dataSize.PlantSizData[1].DeltaT = 5.0
        self.state.dataSize.PlantSizData[2].DesVolFlowRate = 0.001
        self.state.dataSize.PlantSizData[2].DeltaT = 5.0
        self.state.dataPlnt.PlantFirstSizesOkayToFinalize = true
        self.state.dataPlnt.PlantFirstSizesOkayToReport = true
        self.state.dataPlnt.PlantFinalSizesOkayToReport = true
        var RunFlag: Bool = true
        var MyLoad: Float64 = -20000.0
        var thisChiller = self.state.dataPlantChillers.ElectricChiller[1]
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.size(self.state)
        self.state.dataGlobal.BeginEnvrnFlag = true
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].NomCap, 100000.00)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRate, 0.0011)
        Expect.DoubleEq(self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRate, 0.0011)
        self.state.dataPlantChillers.ElectricChiller[1].NomCap = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRate = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRate = DataSizing.AutoSize
        self.state.dataPlantChillers.ElectricChiller[1].NomCapWasAutoSized = true
        self.state.dataPlantChillers.ElectricChiller[1].EvapVolFlowRateWasAutoSized = true
        self.state.dataPlantChillers.ElectricChiller[1].CondVolFlowRateWasAutoSized = true
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.size(self.state)
        var loc: PlantLocation = PlantLocation(1, DataPlant.LoopSideLocation.Demand, 1, 1)
        var firstHVAC: Bool = true
        var curLoad: Float64 = -10000.0
        var runFlag: Bool = true
        thisChiller.simulate(self.state, loc, firstHVAC, curLoad, runFlag)
        var TestCOP: Float64 = thisChiller.QEvaporator / thisChiller.Power
        Expect.Near(TestCOP, thisChiller.ActualCOP, 1E-3)
        var EquipFlowCtrl: DataBranchAirLoopPlant.ControlType = DataBranchAirLoopPlant.ControlType.SeriesActive
        self.state.dataLoopNodes.Node[thisChiller.EvapInletNodeNum].Temp = 10.0
        self.state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].Temp = 6.0
        self.state.dataLoopNodes.Node[thisChiller.EvapOutletNodeNum].TempSetPoint = 6.0
        self.state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 12.0
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.calculate(self.state, MyLoad, RunFlag, EquipFlowCtrl)
        Expect.Gt(thisChiller.partLoadRatio, 0.77)
        Expect.Eq(thisChiller.thermosiphonStatus, 0)
        Expect.Gt(thisChiller.Power, 3000.0)
        self.state.dataLoopNodes.Node[thisChiller.CondInletNodeNum].Temp = 5.0
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.calculate(self.state, MyLoad, RunFlag, EquipFlowCtrl)
        Expect.Gt(thisChiller.partLoadRatio, 0.73)
        Expect.Eq(thisChiller.thermosiphonStatus, 0)
        Expect.Gt(thisChiller.Power, 3000.0)
        MyLoad /= 15.0
        thisChiller.initialize(self.state, RunFlag, MyLoad)
        thisChiller.calculate(self.state, MyLoad, RunFlag, EquipFlowCtrl)
        var dT: Float64 = thisChiller.EvapOutletTemp - thisChiller.CondInletTemp
        var thermosiphonCapFrac: Float64 = Curve.CurveValue(self.state, thisChiller.thermosiphonTempCurveIndex, dT)
        Expect.Lt(thisChiller.partLoadRatio, 0.05)
        Expect.Gt(thermosiphonCapFrac, thisChiller.partLoadRatio)
        Expect.Eq(thisChiller.thermosiphonStatus, 1)
        Expect.Eq(thisChiller.Power, 0.0)