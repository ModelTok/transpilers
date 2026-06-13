from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataSizing import DataSizing
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.PlantChillers import PlantChillers, GTChillerSpecs, EngineDrivenChillerSpecs
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Constant import Constant
from EnergyPlus.Fluid import Fluid

def expect_near(actual: Float64, expected: Float64, tolerance: Float64):
    if abs(actual - expected) > tolerance:
        print("FAIL: expected", expected, "got", actual)
        assert False

def expect_eq(actual: Int, expected: Int):
    if actual != expected:
        print("FAIL: expected", expected, "got", actual)
        assert False

def expect_enum_eq(actual: Int, expected: Int):
    if actual != expected:
        print("FAIL: expected", expected, "got", actual)
        assert False

struct EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def init_state(inout self):
        self.state.init_state(self.state)

    def process_idf(inout self, idf_objects: String) -> Bool:
        # Placeholder: assume fixture provides this
        return True

    def GTChiller_HeatRecoveryAutosizeTest(inout self):
        self.state.init_state(self.state)
        self.state.dataPlnt.PlantLoop.allocate(2)
        self.state.dataSize.PlantSizData.allocate(1)
        self.state.dataPlnt.PlantLoop[0].PlantSizNum = 1
        self.state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(self.state)
        self.state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
        self.state.dataSize.PlantSizData[0].DeltaT = 5.0
        self.state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        self.state.dataPlantChillers.GTChiller.allocate(1)
        self.state.dataPlantChillers.GTChiller[0].SizFac = 1.0
        self.state.dataPlantChillers.GTChiller[0].DesignHeatRecVolFlowRateWasAutoSized = True
        self.state.dataPlantChillers.GTChiller[0].HeatRecCapacityFraction = 0.5
        self.state.dataPlantChillers.GTChiller[0].HeatRecActive = True
        self.state.dataPlantChillers.GTChiller[0].CondenserType = DataPlant.CondenserType.WaterCooled
        self.state.dataPlantChillers.GTChiller[0].CWPlantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, self.state.dataPlantChillers.GTChiller[0].CWPlantLoc)
        self.state.dataPlantChillers.GTChiller[0].CDPlantLoc.loopNum = 2
        PlantUtilities.SetPlantLocationLinks(self.state, self.state.dataPlantChillers.GTChiller[0].CDPlantLoc)
        self.state.dataPlantChillers.GTChiller[0].EvapVolFlowRate = 1.0
        self.state.dataPlantChillers.GTChiller[0].CondVolFlowRate = 1.0
        self.state.dataPlantChillers.GTChiller[0].NomCap = 10000
        self.state.dataPlantChillers.GTChiller[0].COP = 3.0
        self.state.dataPlantChillers.GTChiller[0].engineCapacityScalar = 1.0
        self.state.dataPlantChillers.GTChiller[0].size(self.state)
        expect_near(self.state.dataPlantChillers.GTChiller[0].DesignHeatRecVolFlowRate, 0.5, 0.00001)
        self.state.dataPlantChillers.GTChiller.deallocate()
        self.state.dataSize.PlantSizData.deallocate()
        self.state.dataPlnt.PlantLoop.deallocate()

    def EngineDrivenChiller_HeatRecoveryAutosizeTest(inout self):
        self.state.init_state(self.state)
        self.state.dataPlnt.PlantLoop.allocate(2)
        self.state.dataSize.PlantSizData.allocate(1)
        self.state.dataPlnt.PlantLoop[0].PlantSizNum = 1
        self.state.dataPlnt.PlantLoop[0].FluidName = "WATER"
        self.state.dataPlnt.PlantLoop[0].glycol = Fluid.GetWater(self.state)
        self.state.dataSize.PlantSizData[0].DesVolFlowRate = 1.0
        self.state.dataSize.PlantSizData[0].DeltaT = 5.0
        self.state.dataPlnt.PlantFirstSizesOkayToFinalize = True
        self.state.dataPlantChillers.EngineDrivenChiller.allocate(1)
        self.state.dataPlantChillers.EngineDrivenChiller[0].SizFac = 1.0
        self.state.dataPlantChillers.EngineDrivenChiller[0].DesignHeatRecVolFlowRateWasAutoSized = True
        self.state.dataPlantChillers.EngineDrivenChiller[0].HeatRecCapacityFraction = 0.5
        self.state.dataPlantChillers.EngineDrivenChiller[0].HeatRecActive = True
        self.state.dataPlantChillers.EngineDrivenChiller[0].CondenserType = DataPlant.CondenserType.WaterCooled
        self.state.dataPlantChillers.EngineDrivenChiller[0].CWPlantLoc.loopNum = 1
        PlantUtilities.SetPlantLocationLinks(self.state, self.state.dataPlantChillers.EngineDrivenChiller[0].CWPlantLoc)
        self.state.dataPlantChillers.EngineDrivenChiller[0].CDPlantLoc.loopNum = 2
        PlantUtilities.SetPlantLocationLinks(self.state, self.state.dataPlantChillers.EngineDrivenChiller[0].CDPlantLoc)
        self.state.dataPlantChillers.EngineDrivenChiller[0].EvapVolFlowRate = 1.0
        self.state.dataPlantChillers.EngineDrivenChiller[0].CondVolFlowRate = 1.0
        self.state.dataPlantChillers.EngineDrivenChiller[0].NomCap = 10000
        self.state.dataPlantChillers.EngineDrivenChiller[0].COP = 3.0
        self.state.dataPlantChillers.EngineDrivenChiller[0].size(self.state)
        expect_near(self.state.dataPlantChillers.EngineDrivenChiller[0].DesignHeatRecVolFlowRate, 0.5, 0.00001)
        self.state.dataPlantChillers.EngineDrivenChiller.deallocate()
        self.state.dataSize.PlantSizData.deallocate()
        self.state.dataPlnt.PlantLoop.deallocate()

    def EngineDrivenChiller_Fueltype(inout self):
        var idf_objects: String = delimited_string([
            "Chiller:EngineDriven,",
            "  Big Chiller,             !- Name",
            "  WaterCooled,             !- Condenser Type",
            "  100000,                  !- Nominal Capacity {W}",
            "  2.75,                    !- Nominal COP {W/W}",
            "  Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
            "  Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
            "  Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name",
            "  Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name",
            "  0.15,                    !- Minimum Part Load Ratio",
            "  1.0,                     !- Maximum Part Load Ratio",
            "  0.65,                    !- Optimum Part Load Ratio",
            "  35.0,                    !- Design Condenser Inlet Temperature {C}",
            "  2.778,                   !- Temperature Rise Coefficient",
            "  6.67,                    !- Design Chilled Water Outlet Temperature {C}",
            "  0.0011,                  !- Design Chilled Water Flow Rate {m3/s}",
            "  0.0011,                  !- Design Condenser Water Flow Rate {m3/s}",
            "  0.9949,                  !- Coefficient 1 of Capacity Ratio Curve",
            "  -0.045954,               !- Coefficient 2 of Capacity Ratio Curve",
            "  -0.0013543,              !- Coefficient 3 of Capacity Ratio Curve",
            "  2.333,                   !- Coefficient 1 of Power Ratio Curve",
            "  -1.975,                  !- Coefficient 2 of Power Ratio Curve",
            "  0.6121,                  !- Coefficient 3 of Power Ratio Curve",
            "  0.03303,                 !- Coefficient 1 of Full Load Ratio Curve",
            "  0.6852,                  !- Coefficient 2 of Full Load Ratio Curve",
            "  0.2818,                  !- Coefficient 3 of Full Load Ratio Curve",
            "  5,                       !- Chilled Water Outlet Temperature Lower Limit {C}",
            "  Fuel Use Curve,          !- Fuel Use Curve Name",
            "  Jacket Heat Recovery Curve,  !- Jacket Heat Recovery Curve Name",
            "  Lube Heat Recovery Curve,!- Lube Heat Recovery Curve Name",
            "  Total Exhaust Energy Curve,  !- Total Exhaust Energy Curve Name",
            "  Exhaust Temperature Curve,  !- Exhaust Temperature Curve Name",
            "  0.01516,                 !- Coefficient 1 of U-Factor Times Area Curve",
            "  0.9,                     !- Coefficient 2 of U-Factor Times Area Curve",
            "  0.00063,                 !- Maximum Exhaust Flow per Unit of Power Output {(kg/s)/W}",
            "  150,                     !- Design Minimum Exhaust Temperature {C}",
            "  Diesel,                  !- Fuel Type",
            "  45500,                   !- Fuel Higher Heating Value {kJ/kg}",
            "  0.0,                     !- Design Heat Recovery Water Flow Rate {m3/s}",
            "  ,                   !- Heat Recovery Inlet Node Name",
            "  ,                  !- Heat Recovery Outlet Node Name",
            "  LeavingSetpointModulated,!- Chiller Flow Mode",
            "  60.0,                    !- Maximum Temperature for Heat Recovery at Heat Recovery Outlet Node {C}",
            " ;                       !- Sizing Factor",
            " Curve:Quadratic,",
            "  Fuel Use Curve,          !- Name",
            "  1.3,                     !- Coefficient1 Constant",
            "  0.6318,                  !- Coefficient2 x",
            "  -0.4165,                 !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            " Curve:Quadratic,",
            "  Jacket Heat Recovery Curve,  !- Name",
            "  0.25,                    !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            " Curve:Quadratic,",
            "  Lube Heat Recovery Curve,!- Name",
            "  0.15,                    !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            " Curve:Quadratic,",
            "  Total Exhaust Energy Curve,  !- Name",
            "  0.1,                     !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            " Curve:Quadratic,",
            "  Exhaust Temperature Curve,  !- Name",
            "  392.4,                   !- Coefficient1 Constant",
            "  33.33,                   !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
        ])
        assert self.process_idf(idf_objects)
        self.state.init_state(self.state)
        EngineDrivenChillerSpecs.getInput(self.state)
        expect_eq(1, self.state.dataPlantChillers.NumEngineDrivenChillers)
        expect_enum_eq(self.state.dataPlantChillers.EngineDrivenChiller[0].FuelType, Constant.eFuel.Diesel)

    def CombustionTurbineChiller_Fueltype(inout self):
        var idf_objects: String = delimited_string([
            "Chiller:CombustionTurbine,",
            "  Big Chiller,             !- Name",
            "  WaterCooled,             !- Condenser Type",
            "  30000,                   !- Nominal Capacity {W}",
            "  2.75,                    !- Nominal COP {W/W}",
            "  Big Chiller Inlet Node,  !- Chilled Water Inlet Node Name",
            "  Big Chiller Outlet Node, !- Chilled Water Outlet Node Name",
            "  Big Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name",
            "  Big Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name",
            "  0.15,                    !- Minimum Part Load Ratio",
            "  1.0,                     !- Maximum Part Load Ratio",
            "  0.65,                    !- Optimum Part Load Ratio",
            "  35.0,                    !- Design Condenser Inlet Temperature {C}",
            "  2.778,                   !- Temperature Rise Coefficient",
            "  6.67,                    !- Design Chilled Water Outlet Temperature {C}",
            "  0.0011,                  !- Design Chilled Water Flow Rate {m3/s}",
            "  0.0011,                  !- Design Condenser Water Flow Rate {m3/s}",
            "  0.9949,                  !- Coefficient 1 of Capacity Ratio Curve",
            "  -0.045954,               !- Coefficient 2 of Capacity Ratio Curve",
            "  -0.0013543,              !- Coefficient 3 of Capacity Ratio Curve",
            "  2.333,                   !- Coefficient 1 of Power Ratio Curve",
            "  -1.975,                  !- Coefficient 2 of Power Ratio Curve",
            "  0.6121,                  !- Coefficient 3 of Power Ratio Curve",
            "  0.03303,                 !- Coefficient 1 of Full Load Ratio Curve",
            "  0.6852,                  !- Coefficient 2 of Full Load Ratio Curve",
            "  0.2818,                  !- Coefficient 3 of Full Load Ratio Curve",
            "  5,                       !- Chilled Water Outlet Temperature Lower Limit {C}",
            "  9.41,                    !- Coefficient 1 of Fuel Input Curve",
            "  -9.48,                   !- Coefficient 2 of Fuel Input Curve",
            "  4.32,                    !- Coefficient 3 of Fuel Input Curve",
            "  1.0044,                  !- Coefficient 1 of Temperature Based Fuel Input Curve",
            "  -0.0008,                 !- Coefficient 2 of Temperature Based Fuel Input Curve",
            "  0,                       !- Coefficient 3 of Temperature Based Fuel Input Curve",
            "  15.63518363,             !- Coefficient 1 of Exhaust Flow Curve",
            "  -0.03059999,             !- Coefficient 2 of Exhaust Flow Curve",
            "  -0.0002,                 !- Coefficient 3 of Exhaust Flow Curve",
            "  916.992,                 !- Coefficient 1 of Exhaust Gas Temperature Curve",
            "  307.998,                 !- Coefficient 2 of Exhaust Gas Temperature Curve",
            "  79.992,                  !- Coefficient 3 of Exhaust Gas Temperature Curve",
            "  1.005,                   !- Coefficient 1 of Temperature Based Exhaust Gas Temperature Curve",
            "  0.0018,                  !- Coefficient 2 of Temperature Based Exhaust Gas Temperature Curve",
            "  0,                       !- Coefficient 3 of Temperature Based Exhaust Gas Temperature Curve",
            "  0.223,                   !- Coefficient 1 of Recovery Lube Heat Curve",
            "  -0.4,                    !- Coefficient 2 of Recovery Lube Heat Curve",
            "  0.2286,                  !- Coefficient 3 of Recovery Lube Heat Curve",
            "  0.01907045,              !- Coefficient 1 of U-Factor Times Area Curve",
            "  0.9,                     !- Coefficient 2 of U-Factor Times Area Curve",
            "  50000,                   !- Gas Turbine Engine Capacity {W}",
            "  0.00000504,              !- Maximum Exhaust Flow per Unit of Power Output {(kg/s)/W}",
            "  150,                     !- Design Steam Saturation Temperature {C}",
            "  43500,                   !- Fuel Higher Heating Value {kJ/kg}",
            "  0.0,                     !- Design Heat Recovery Water Flow Rate {m3/s}",
            "  ,                        !- Heat Recovery Inlet Node Name",
            "  ,                        !- Heat Recovery Outlet Node Name",
            "  LeavingSetpointModulated,!- Chiller Flow Mode",
            "  NATURALGAS,              !- Fuel Type",
            "  80.0;                    !- Heat Recovery Maximum Temperature {C}",
        ])
        assert self.process_idf(idf_objects)
        self.state.init_state(self.state)
        GTChillerSpecs.getInput(self.state)
        expect_eq(1, self.state.dataPlantChillers.NumGTChillers)
        expect_enum_eq(self.state.dataPlantChillers.GTChiller[0].FuelType, Constant.eFuel.NaturalGas)

def main():
    var fixture = EnergyPlusFixture()
    fixture.GTChiller_HeatRecoveryAutosizeTest()
    fixture.EngineDrivenChiller_HeatRecoveryAutosizeTest()
    fixture.EngineDrivenChiller_Fueltype()
    fixture.CombustionTurbineChiller_Fueltype()