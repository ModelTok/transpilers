from ...Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, state, delimited_string, assert_true, assert_eq
from .........src.EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from .........src.EnergyPlus.DataIPShortCuts import DataIPShortCuts
from .........src.EnergyPlus.MicroturbineElectricGenerator import GetMTGeneratorInput, Constant

def test_MicroturbineElectricGenerator_Fueltype():
    var idf_objects = delimited_string(
        "Generator:MicroTurbine,",
        "  Capstone C65,            !- Name",
        "  65000,                   !- Reference Electrical Power Output {W}",
        "  29900,                   !- Minimum Full Load Electrical Power Output {W}",
        "  65000,                   !- Maximum Full Load Electrical Power Output {W}",
        "  0.29,                    !- Reference Electrical Efficiency Using Lower Heating Value",
        "  15.0,                    !- Reference Combustion Air Inlet Temperature {C}",
        "  0.00638,                 !- Reference Combustion Air Inlet Humidity Ratio {kgWater/kgDryAir}",
        "  0.0,                     !- Reference Elevation {m}",
        "  Capstone C65 Power_vs_Temp_Elev,  !- Electrical Power Function of Temperature and Elevation Curve Name",
        "  Capstone C65 Efficiency_vs_Temp,  !- Electrical Efficiency Function of Temperature Curve Name",
        "  Capstone C65 Efficiency_vs_PLR,  !- Electrical Efficiency Function of Part Load Ratio Curve Name",
        "  NaturalGas,              !- Fuel Type",
        "  50000,                   !- Fuel Higher Heating Value {kJ/kg}",
        "  45450,                   !- Fuel Lower Heating Value {kJ/kg}",
        "  300,                     !- Standby Power {W}",
        "  4500;                    !- Ancillary Power {W}",
        "Curve:Biquadratic,",
        "  Capstone C65 Power_vs_Temp_Elev,  !- Name",
        "  1.2027697,               !- Coefficient1 Constant",
        "  -9.671305E-03,           !- Coefficient2 x",
        "  -4.860793E-06,           !- Coefficient3 x**2",
        "  -1.542394E-04,           !- Coefficient4 y",
        "  9.111418E-09,            !- Coefficient5 y**2",
        "  8.797885E-07,            !- Coefficient6 x*y",
        "  -17.8,                   !- Minimum Value of x",
        "  50.0,                    !- Maximum Value of x",
        "  0.0,                     !- Minimum Value of y",
        "  3050.,                   !- Maximum Value of y",
        "  ,                        !- Minimum Curve Output",
        "  ,                        !- Maximum Curve Output",
        "  Temperature,             !- Input Unit Type for X",
        "  Distance,                !- Input Unit Type for Y",
        "  Dimensionless;           !- Output Unit Type",
        "Curve:Cubic,",
        "  Capstone C65 Efficiency_vs_Temp,  !- Name",
        "  1.0402217,               !- Coefficient1 Constant",
        "  -0.0017314,              !- Coefficient2 x",
        "  -6.497040E-05,           !- Coefficient3 x**2",
        "  5.133175E-07,            !- Coefficient4 x**3",
        "  -20.0,                   !- Minimum Value of x",
        "  50.0,                    !- Maximum Value of x",
        "  ,                        !- Minimum Curve Output",
        "  ,                        !- Maximum Curve Output",
        "  Temperature,             !- Input Unit Type for X",
        "  Dimensionless;           !- Output Unit Type",
        "Curve:Cubic,",
        "  Capstone C65 Efficiency_vs_PLR,  !- Name",
        "  0.215290,                !- Coefficient1 Constant",
        "  2.561463,                !- Coefficient2 x",
        "  -3.24613,                !- Coefficient3 x**2",
        "  1.497306,                !- Coefficient4 x**3",
        "  0.03,                    !- Minimum Value of x",
        "  1.0;                     !- Maximum Value of x",
    )
    assert_true(process_idf(idf_objects))
    state.init_state(state) // Calls GetCurveInput
    state.dataIPShortCut.cAlphaArgs[0] = "Capstone C65"
    state.dataIPShortCut.cCurrentModuleObject = "Generator:MicroTurbine"
    GetMTGeneratorInput(state)
    assert_eq(state.dataMircoturbElectGen.MTGenerator[0].FuelType, Constant.eFuel.NaturalGas)