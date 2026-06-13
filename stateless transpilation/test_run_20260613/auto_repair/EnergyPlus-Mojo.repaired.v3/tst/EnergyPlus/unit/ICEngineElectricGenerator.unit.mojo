from gtest import Test, TestFixture, AssertTrue, AssertEqual
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.ICEngineElectricGenerator import GetICEngineGeneratorInput, Constant
from EnergyPlus.Data.GlobalConstants import Constant as GlobalConstant

using EnergyPlus::ICEngineElectricGenerator

@fixture
class ICEngineElectricGenerator_Fueltype(EnergyPlusFixture):
    def TestBody(self):
        var idf_objects: String = delimited_string([
            "Generator:InternalCombustionEngine,",
            "  Cat Diesel,              !- Name",
            "  50000,                   !- Rated Power Output {W}",
            "  Generator Diesel Electric Node,  !- Electric Circuit Node Name",
            "  0.15,                    !- Minimum Part Load Ratio",
            "  1.0,                     !- Maximum Part Load Ratio",
            "  0.65,                    !- Optimum Part Load Ratio",
            "  BG Shaft Power Curve,    !- Shaft Power Curve Name",
            "  BG Recovery Jacket Heat Curve,  !- Jacket Heat Recovery Curve Name",
            "  BG Recovery Lube Heat Curve,  !- Lube Heat Recovery Curve Name",
            "  BG Total Exhaust Energy Curve,  !- Total Exhaust Energy Curve Name",
            "  BG Exhaust Temperature Curve,  !- Exhaust Temperature Curve Name",
            "  0.00952329,              !- Coefficient 1 of U-Factor Times Area Curve",
            "  0.9,                     !- Coefficient 2 of U-Factor Times Area Curve",
            "  0.00000063,              !- Maximum Exhaust Flow per Unit of Power Output {(kg/s)/W}",
            "  150,                     !- Design Minimum Exhaust Temperature {C}",
            "  45500,                   !- Fuel Higher Heating Value {kJ/kg}",
            "  0.0,                     !- Design Heat Recovery Water Flow Rate {m3/s}",
            "  ,                        !- Heat Recovery Inlet Node Name",
            "  ,                        !- Heat Recovery Outlet Node Name",
            "  Diesel;                  !- Fuel Type",
            "Curve:Quadratic,",
            "  BG Shaft Power Curve,    !- Name",
            "  0.09755,                 !- Coefficient1 Constant",
            "  0.6318,                  !- Coefficient2 x",
            "  -0.4165,                 !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            "Curve:Quadratic,",
            "  BG Recovery Jacket Heat Curve,  !- Name",
            "  0.25,                    !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            "Curve:Quadratic,",
            "  BG Recovery Lube Heat Curve,  !- Name",
            "  0.15,                    !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            "Curve:Quadratic,",
            "  BG Total Exhaust Energy Curve,  !- Name",
            "  0.1,                     !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
            "Curve:Quadratic,",
            "  BG Exhaust Temperature Curve,  !- Name",
            "  425,                     !- Coefficient1 Constant",
            "  0,                       !- Coefficient2 x",
            "  0,                       !- Coefficient3 x**2",
            "  0,                       !- Minimum Value of x",
            "  1;                       !- Maximum Value of x",
        ])
        AssertTrue(process_idf(idf_objects))
        state.init_state(state) // Calls GetCurveInput
        GetICEngineGeneratorInput(state)
        AssertEqual(state.dataICEngElectGen.ICEngineGenerator[0].FuelType, Constant.eFuel.Diesel)