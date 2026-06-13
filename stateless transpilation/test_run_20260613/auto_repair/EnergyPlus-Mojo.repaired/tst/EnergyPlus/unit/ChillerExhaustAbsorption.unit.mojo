from gtest import Test, TestFixture, EXPECT_EQ, EXPECT_TRUE, EXPECT_FALSE, EXPECT_NEAR, ASSERT_TRUE
from ObjexxFCL.Array1D import Array1D
from EnergyPlus.ChillerExhaustAbsorption import ExhaustAbsorberSpecs, GetExhaustAbsorberInput
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataErrorTracking import DataErrorTracking
from EnergyPlus.DataLoopNode import DataLoopNode
from EnergyPlus.FluidProperties import Fluid
from EnergyPlus.Plant.DataPlant import DataPlant, PlantLocation, LoopSideLocation, FlowLock, LoopDemandCalcScheme
from EnergyPlus.PlantUtilities import PlantUtilities
from EnergyPlus.Psychrometrics import Psychrometrics
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, compare_err_stream

using EnergyPlus
using EnergyPlus.ChillerExhaustAbsorption

@fixture
class EnergyPlusFixture(TestFixture):

@test
def ExhAbsorption_GetInput_Test(regression):
    let idf_objects = delimited_string([
        "  ChillerHeater:Absorption:DoubleEffect,                                                                     ",
        "    Exh Chiller,             !- Name                                                                         ",
        "    100000,                  !- Nominal Cooling Capacity {W}                                                 ",
        "    0.8,                     !- Heating to Cooling Capacity Ratio                                            ",
        "    0.97,                    !- Thermal Energy Input to Cooling Output Ratio                                 ",
        "    1.25,                    !- Thermal Energy Input to Heating Output Ratio                                 ",
        "    0.01,                    !- Electric Input to Cooling Output Ratio                                       ",
        "    0.005,                   !- Electric Input to Heating Output Ratio                                       ",
        "    Exh Chiller Inlet Node,  !- Chilled Water Inlet Node Name                                                ",
        "    Exh Chiller Outlet Node, !- Chilled Water Outlet Node Name                                               ",
        "    Exh Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name                                          ",
        "    Exh Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name                                        ",
        "    Exh Chiller Heating Inlet Node,  !- Hot Water Inlet Node Name                                            ",
        "    Exh Chiller Heating Outlet Node,  !- Hot Water Outlet Node Name                                          ",
        "    0.000001,                !- Minimum Part Load Ratio                                                      ",
        "    1.0,                     !- Maximum Part Load Ratio                                                      ",
        "    0.6,                     !- Optimum Part Load Ratio                                                      ",
        "    29,                      !- Design Entering Condenser Water Temperature {C}                              ",
        "    7,                       !- Design Leaving Chilled Water Temperature {C}                                 ",
        "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                        ",
        "    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                      ",
        "    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                            ",
        "    ExhAbsorb_CapFt,         !- Cooling Capacity Function of Temperature Curve Name                          ",
        "    ExhAbsorb_EIRFt,         !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name        ",
        "    ExhAbsorb_PLR,           !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name    ",
        "    ExhAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name    ",
        "    ExhAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "    ExhAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                     ",
        "    ExhAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name     ",
        "    EnteringCondenser,       !- Temperature Curve Input Variable                                             ",
        "    AirCooled,             !- Condenser Type                                                                 ",
        "    2,                       !- Chilled Water Temperature Lower Limit {C}                                    ",
        "    Generator:MicroTurbine,  !- Exhaust Source Object Type                                                   ",
        "    Capstone C65,            !- Exhaust Source Object Name                                                   ",
        "    ;                        !- Sizing Factor                                                                ",
        "                                                                                                             ",
        "OutdoorAir:Node,                                                                 ",
        "  Exh Chiller Condenser Inlet Node,                                  !- Name     ",
        "  -1;                                                      !- Height Above Ground",
        "                                                                                 ",
        "  CURVE:BIQUADRATIC,                                                                                         ",
        "    ExhAbsorb_CapFt,         !- Name                                                                         ",
        "    -0.115131E+01,           !- Coefficient1 Constant                                                        ",
        "    -0.801316E-01,           !- Coefficient2 x                                                               ",
        "    -0.945353E-02,           !- Coefficient3 x**2                                                            ",
        "    0.209867E+00,            !- Coefficient4 y                                                               ",
        "    -0.567055E-02,           !- Coefficient5 y**2                                                            ",
        "    0.943605E-02,            !- Coefficient6 x*y                                                             ",
        "    4.44444,                 !- Minimum Value of x                                                           ",
        "    8.88889,                 !- Maximum Value of x                                                           ",
        "    21.11111,                !- Minimum Value of y                                                           ",
        "    35.00000;                !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  CURVE:BIQUADRATIC,                                                                                         ",
        "    ExhAbsorb_EIRFt,         !- Name                                                                         ",
        "    0.131195E+01,            !- Coefficient1 Constant                                                        ",
        "    -0.159283E-01,           !- Coefficient2 x                                                               ",
        "    0.773725E-03,            !- Coefficient3 x**2                                                            ",
        "    -0.196279E-01,           !- Coefficient4 y                                                               ",
        "    0.378351E-03,            !- Coefficient5 y**2                                                            ",
        "    0.558356E-04,            !- Coefficient6 x*y                                                             ",
        "    4.44444,                 !- Minimum Value of x                                                           ",
        "    8.88889,                 !- Maximum Value of x                                                           ",
        "    21.11111,                !- Minimum Value of y                                                           ",
        "    35.00000;                !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  Curve:Biquadratic,                                                                                         ",
        "    ExhAbsFlatBiQuad,        !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    0.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.000000000,             !- Coefficient4 y                                                               ",
        "    0.000000000,             !- Coefficient5 y**2                                                            ",
        "    0.000000000,             !- Coefficient6 x*y                                                             ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.,                     !- Maximum Value of x                                                           ",
        "    0.,                      !- Minimum Value of y                                                           ",
        "    50.;                     !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsLinearQuad,        !- Name                                                                         ",
        "    0.000000000,             !- Coefficient1 Constant                                                        ",
        "    1.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsInvLinearQuad,     !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    -1.000000000,            !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:QUADRATIC,                                                                                           ",
        "    ExhAbsorb_PLR,           !- Name                                                                         ",
        "    0.026280035,             !- Coefficient1 Constant                                                        ",
        "    0.678066088,             !- Coefficient2 x                                                               ",
        "    0.273905867,             !- Coefficient3 x**2                                                            ",
        "    0.0,                     !- Minimum Value of x                                                           ",
        "    1.0;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsFlatQuad,          !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    0.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                              ",
        "  Generator:MicroTurbine,                                                                                     ",
        "    Capstone C65,            !- Name                                                                          ",
        "    65000,                   !- Reference Electrical Power Output {W}                                         ",
        "    29900,                   !- Minimum Full Load Electrical Power Output {W}                                 ",
        "    65000,                   !- Maximum Full Load Electrical Power Output {W}                                 ",
        "    0.29,                    !- Reference Electrical Efficiency Using Lower Heating Value                     ",
        "    15.0,                    !- Reference Combustion Air Inlet Temperature {C}                                ",
        "    0.00638,                 !- Reference Combustion Air Inlet Humidity Ratio {kgWater/kgDryAir}              ",
        "    0.0,                     !- Reference Elevation {m}                                                       ",
        "    Capstone C65 Power_vs_Temp_Elev,  !- Electrical Power Function of Temperature and Elevation Curve Name    ",
        "    Capstone C65 Efficiency_vs_Temp,  !- Electrical Efficiency Function of Temperature Curve Name             ",
        "    Capstone C65 Efficiency_vs_PLR,  !- Electrical Efficiency Function of Part Load Ratio Curve Name          ",
        "    NaturalGas,              !- Fuel Type                                                                     ",
        "    50000,                   !- Fuel Higher Heating Value {kJ/kg}                                             ",
        "    45450,                   !- Fuel Lower Heating Value {kJ/kg}                                              ",
        "    300,                     !- Standby Power {W}                                                             ",
        "    4500,                    !- Ancillary Power {W}                                                           ",
        "    ,                        !- Ancillary Power Function of Fuel Input Curve Name                             ",
        "    ,                        !- Heat Recovery Water Inlet Node Name                                           ",
        "    ,                        !- Heat Recovery Water Outlet Node Name                                          ",
        "    ,                        !- Reference Thermal Efficiency Using Lower Heat Value                           ",
        "    ,                        !- Reference Inlet Water Temperature {C}                                         ",
        "    ,                        !- Heat Recovery Water Flow Operating Mode                                       ",
        "    ,                        !- Reference Heat Recovery Water Flow Rate {m3/s}                                ",
        "    ,                        !- Heat Recovery Water Flow Rate Function of Temperature and Power Curve Name    ",
        "    ,                        !- Thermal Efficiency Function of Temperature and Elevation Curve Name           ",
        "    ,                        !- Heat Recovery Rate Function of Part Load Ratio Curve Name                     ",
        "    ,                        !- Heat Recovery Rate Function of Inlet Water Temperature Curve Name             ",
        "    ,                        !- Heat Recovery Rate Function of Water Flow Rate Curve Name                     ",
        "    ,                        !- Minimum Heat Recovery Water Flow Rate {m3/s}                                  ",
        "    ,                        !- Maximum Heat Recovery Water Flow Rate {m3/s}                                  ",
        "    ,                        !- Maximum Heat Recovery Water Temperature {C}                                   ",
        "    Capstone C65 Combustion Air Inlet Node,  !- Combustion Air Inlet Node Name                                ",
        "    Capstone C65 Combustion Air Outlet Node,  !- Combustion Air Outlet Node Name                              ",
        "    0.6,                     !- Reference Exhaust Air Mass Flow Rate {kg/s}                                   ",
        "    Capstone C65 ExhFlowRate_vs_Inlet_Temp,  !- Exhaust Air Flow Rate Function of Temperature Curve Name      ",
        "    Capstone C65 ExhFlowRate_vs_PLR,  !- Exhaust Air Flow Rate Function of Part Load Ratio Curve Name         ",
        "    350,                     !- Nominal Exhaust Air Outlet Temperature                                        ",
        "    Capstone C65 ExhTemp_vs_Inlet_Temp,  !- Exhaust Air Temperature Function of Temperature Curve Name        ",
        "    Capstone C65 ExhTemp_vs_PLR;  !- Exhaust Air Temperature Function of Part Load Ratio Curve Name           ",
        "                                                                                                              ",
        "  OutdoorAir:Node,                                                                                            ",
        "    Capstone C65 Combustion Air Inlet Node,  !- Name                                                          ",
        "    -1;                      !- Height Above Ground {m}                                                       ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhTemp_vs_Inlet_Temp,  !- Name                                                              ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    -20.,                    !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhTemp_vs_PLR,  !- Name                                                                     ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.;                      !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhFlowRate_vs_PLR,  !- Name                                                                 ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.;                      !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 ExhFlowRate_vs_Inlet_Temp,  !- Name                                                          ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.0,                     !- Coefficient4 x**3                                                             ",
        "    -20.,                    !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 Efficiency_vs_Temp,  !- Name                                                                 ",
        "    1.0402217,               !- Coefficient1 Constant                                                         ",
        "    -0.0017314,              !- Coefficient2 x                                                                ",
        "    -6.497040E-05,           !- Coefficient3 x**2                                                             ",
        "    5.133175E-07,            !- Coefficient4 x**3                                                             ",
        "    -20.0,                   !- Minimum Value of x                                                            ",
        "    50.0,                    !- Maximum Value of x                                                            ",
        "    ,                        !- Minimum Curve Output                                                          ",
        "    ,                        !- Maximum Curve Output                                                          ",
        "    Temperature,             !- Input Unit Type for X                                                         ",
        "    Dimensionless;           !- Output Unit Type                                                              ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 Efficiency_vs_PLR,  !- Name                                                                  ",
        "    0.215290,                !- Coefficient1 Constant                                                         ",
        "    2.561463,                !- Coefficient2 x                                                                ",
        "    -3.24613,                !- Coefficient3 x**2                                                             ",
        "    1.497306,                !- Coefficient4 x**3                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.0;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Biquadratic,                                                                                          ",
        "    Capstone C65 Power_vs_Temp_Elev,  !- Name                                                                 ",
        "    1.2027697,               !- Coefficient1 Constant                                                         ",
        "    -9.671305E-03,           !- Coefficient2 x                                                                ",
        "    -4.860793E-06,           !- Coefficient3 x**2                                                             ",
        "    -1.542394E-04,           !- Coefficient4 y                                                                ",
        "    9.111418E-09,            !- Coefficient5 y**2                                                             ",
        "    8.797885E-07,            !- Coefficient6 x*y                                                              ",
        "    -17.8,                   !- Minimum Value of x                                                            ",
        "    50.0,                    !- Maximum Value of x                                                            ",
        "    0.0,                     !- Minimum Value of y                                                            ",
        "    3050.,                   !- Maximum Value of y                                                            ",
        "    ,                        !- Minimum Curve Output                                                          ",
        "    ,                        !- Maximum Curve Output                                                          ",
        "    Temperature,             !- Input Unit Type for X                                                         ",
        "    Distance,                !- Input Unit Type for Y                                                         ",
        "    Dimensionless;           !- Output Unit Type                                                              ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    compare_err_stream("")
    state.init_state(*state)
    GetExhaustAbsorberInput(*state)
    compare_err_stream("")
    EXPECT_EQ(1u, state.dataChillerExhaustAbsorption.ExhaustAbsorber.size())
    EXPECT_EQ("EXH CHILLER", state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].Name)
    EXPECT_EQ(100000., state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].NomCoolingCap)
    EXPECT_EQ(0.8, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].NomHeatCoolRatio)
    EXPECT_EQ(0.97, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].ThermalEnergyCoolRatio)
    EXPECT_EQ(1.25, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].ThermalEnergyHeatRatio)
    EXPECT_EQ(0.01, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].ElecCoolRatio)
    EXPECT_EQ(0.005, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].ElecHeatRatio)
    EXPECT_EQ(0.000001, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].MinPartLoadRat)
    EXPECT_EQ(1.0, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].MaxPartLoadRat)
    EXPECT_EQ(0.6, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].OptPartLoadRat)
    EXPECT_EQ(29., state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].TempDesCondReturn)
    EXPECT_EQ(7., state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].TempDesCHWSupply)
    EXPECT_EQ(0.0011, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].EvapVolFlowRate)
    EXPECT_EQ(0.0043, state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].HeatVolFlowRate)
    EXPECT_TRUE(state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].isEnterCondensTemp)
    EXPECT_FALSE(state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].isWaterCooled)
    EXPECT_EQ(2., state.dataChillerExhaustAbsorption.ExhaustAbsorber[0].CHWLowLimitTemp)

@test
def ExhAbsorption_getDesignCapacities_Test(regression):
    state.init_state(*state)
    state.dataPlnt.TotNumLoops = 3
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].TotalBranches = 3
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].Branch.allocate(3)
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].Branch[0].TotalComponents = 2
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].Branch[0].Comp.allocate(2)
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 100
    state.dataPlnt.PlantLoop[0].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[1].NodeNumIn = 111
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].TotalBranches = 3
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].Branch.allocate(3)
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].Branch[0].TotalComponents = 2
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].Branch[0].Comp.allocate(2)
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 200
    state.dataPlnt.PlantLoop[1].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[1].NodeNumIn = 222
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].TotalBranches = 4
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].Branch.allocate(4)
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].Branch[0].TotalComponents = 2
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].Branch[0].Comp.allocate(2)
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[0].NodeNumIn = 300
    state.dataPlnt.PlantLoop[2].LoopSide[LoopSideLocation.Demand].Branch[0].Comp[1].NodeNumIn = 333
    var thisChillerHeater = ExhaustAbsorberSpecs()
    thisChillerHeater.ChillReturnNodeNum = 111
    thisChillerHeater.HeatReturnNodeNum = 222
    thisChillerHeater.CondReturnNodeNum = 333
    var loc_1 = PlantLocation{1, LoopSideLocation.Demand, 1, 1}
    PlantUtilities.SetPlantLocationLinks(*state, loc_1)
    var maxload = -1.0
    var minload = -1.0
    var optload = -1.0
    thisChillerHeater.NomCoolingCap = 100000.0
    thisChillerHeater.MinPartLoadRat = 0.1
    thisChillerHeater.MaxPartLoadRat = 0.9
    thisChillerHeater.OptPartLoadRat = 0.8
    thisChillerHeater.getDesignCapacities(*state, loc_1, maxload, minload, optload)
    EXPECT_NEAR(minload, 10000.0, 0.001)
    EXPECT_NEAR(maxload, 90000.0, 0.001)
    EXPECT_NEAR(optload, 80000.0, 0.001)
    thisChillerHeater.NomHeatCoolRatio = 0.9
    var loc_2 = PlantLocation{2, LoopSideLocation.Demand, 1, 1}
    PlantUtilities.SetPlantLocationLinks(*state, loc_2)
    thisChillerHeater.getDesignCapacities(*state, loc_2, maxload, minload, optload)
    EXPECT_NEAR(minload, 9000.0, 0.001)
    EXPECT_NEAR(maxload, 81000.0, 0.001)
    EXPECT_NEAR(optload, 72000.0, 0.001)
    var loc_3 = PlantLocation{3, LoopSideLocation.Demand, 1, 1}
    PlantUtilities.SetPlantLocationLinks(*state, loc_3)
    thisChillerHeater.getDesignCapacities(*state, loc_3, maxload, minload, optload)
    EXPECT_NEAR(minload, 0.0, 0.001)
    EXPECT_NEAR(maxload, 0.0, 0.001)
    EXPECT_NEAR(optload, 0.0, 0.001)

@test
def ExhAbsorption_calcHeater_Fix_Test(regression):
    let idf_objects = delimited_string([
        "  ChillerHeater:Absorption:DoubleEffect,                                                                     ",
        "    Exh Chiller,             !- Name                                                                         ",
        "    100000,                  !- Nominal Cooling Capacity {W}                                                 ",
        "    0.8,                     !- Heating to Cooling Capacity Ratio                                            ",
        "    0.97,                    !- Thermal Energy Input to Cooling Output Ratio                                 ",
        "    1.25,                    !- Thermal Energy Input to Heating Output Ratio                                 ",
        "    0.01,                    !- Electric Input to Cooling Output Ratio                                       ",
        "    0.005,                   !- Electric Input to Heating Output Ratio                                       ",
        "    Exh Chiller Inlet Node,  !- Chilled Water Inlet Node Name                                                ",
        "    Exh Chiller Outlet Node, !- Chilled Water Outlet Node Name                                               ",
        "    Exh Chiller Condenser Inlet Node,  !- Condenser Inlet Node Name                                          ",
        "    Exh Chiller Condenser Outlet Node,  !- Condenser Outlet Node Name                                        ",
        "    Exh Chiller Heating Inlet Node,  !- Hot Water Inlet Node Name                                            ",
        "    Exh Chiller Heating Outlet Node,  !- Hot Water Outlet Node Name                                          ",
        "    0.000001,                !- Minimum Part Load Ratio                                                      ",
        "    1.0,                     !- Maximum Part Load Ratio                                                      ",
        "    0.6,                     !- Optimum Part Load Ratio                                                      ",
        "    29,                      !- Design Entering Condenser Water Temperature {C}                              ",
        "    7,                       !- Design Leaving Chilled Water Temperature {C}                                 ",
        "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                        ",
        "    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                      ",
        "    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                            ",
        "    ExhAbsorb_CapFt,         !- Cooling Capacity Function of Temperature Curve Name                          ",
        "    ExhAbsorb_EIRFt,         !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name        ",
        "    ExhAbsorb_PLR,           !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name    ",
        "    ExhAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name    ",
        "    ExhAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name",
        "    ExhAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                     ",
        "    ExhAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name     ",
        "    EnteringCondenser,       !- Temperature Curve Input Variable                                             ",
        "    AirCooled,             !- Condenser Type                                                                 ",
        "    2,                       !- Chilled Water Temperature Lower Limit {C}                                    ",
        "    Generator:MicroTurbine,  !- Exhaust Source Object Type                                                   ",
        "    Capstone C65,            !- Exhaust Source Object Name                                                   ",
        "    ;                        !- Sizing Factor                                                                ",
        "                                                                                                             ",
        "OutdoorAir:Node,                                                                 ",
        "  Exh Chiller Condenser Inlet Node,                                  !- Name     ",
        "  -1;                                                      !- Height Above Ground",
        "                                                                                 ",
        "  CURVE:BIQUADRATIC,                                                                                         ",
        "    ExhAbsorb_CapFt,         !- Name                                                                         ",
        "    -0.115131E+01,           !- Coefficient1 Constant                                                        ",
        "    -0.801316E-01,           !- Coefficient2 x                                                               ",
        "    -0.945353E-02,           !- Coefficient3 x**2                                                            ",
        "    0.209867E+00,            !- Coefficient4 y                                                               ",
        "    -0.567055E-02,           !- Coefficient5 y**2                                                            ",
        "    0.943605E-02,            !- Coefficient6 x*y                                                             ",
        "    4.44444,                 !- Minimum Value of x                                                           ",
        "    8.88889,                 !- Maximum Value of x                                                           ",
        "    21.11111,                !- Minimum Value of y                                                           ",
        "    35.00000;                !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  CURVE:BIQUADRATIC,                                                                                         ",
        "    ExhAbsorb_EIRFt,         !- Name                                                                         ",
        "    0.131195E+01,            !- Coefficient1 Constant                                                        ",
        "    -0.159283E-01,           !- Coefficient2 x                                                               ",
        "    0.773725E-03,            !- Coefficient3 x**2                                                            ",
        "    -0.196279E-01,           !- Coefficient4 y                                                               ",
        "    0.378351E-03,            !- Coefficient5 y**2                                                            ",
        "    0.558356E-04,            !- Coefficient6 x*y                                                             ",
        "    4.44444,                 !- Minimum Value of x                                                           ",
        "    8.88889,                 !- Maximum Value of x                                                           ",
        "    21.11111,                !- Minimum Value of y                                                           ",
        "    35.00000;                !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  Curve:Biquadratic,                                                                                         ",
        "    ExhAbsFlatBiQuad,        !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    0.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.000000000,             !- Coefficient4 y                                                               ",
        "    0.000000000,             !- Coefficient5 y**2                                                            ",
        "    0.000000000,             !- Coefficient6 x*y                                                             ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.,                     !- Maximum Value of x                                                           ",
        "    0.,                      !- Minimum Value of y                                                           ",
        "    50.;                     !- Maximum Value of y                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsLinearQuad,        !- Name                                                                         ",
        "    0.000000000,             !- Coefficient1 Constant                                                        ",
        "    1.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsInvLinearQuad,     !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    -1.000000000,            !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:QUADRATIC,                                                                                           ",
        "    ExhAbsorb_PLR,           !- Name                                                                         ",
        "    0.026280035,             !- Coefficient1 Constant                                                        ",
        "    0.678066088,             !- Coefficient2 x                                                               ",
        "    0.273905867,             !- Coefficient3 x**2                                                            ",
        "    0.0,                     !- Minimum Value of x                                                           ",
        "    1.0;                     !- Maximum Value of x                                                           ",
        "                                                                                                             ",
        "  Curve:Quadratic,                                                                                           ",
        "    ExhAbsFlatQuad,          !- Name                                                                         ",
        "    1.000000000,             !- Coefficient1 Constant                                                        ",
        "    0.000000000,             !- Coefficient2 x                                                               ",
        "    0.000000000,             !- Coefficient3 x**2                                                            ",
        "    0.,                      !- Minimum Value of x                                                           ",
        "    50.;                     !- Maximum Value of x                                                           ",
        "                                                                                                              ",
        "  Generator:MicroTurbine,                                                                                     ",
        "    Capstone C65,            !- Name                                                                          ",
        "    65000,                   !- Reference Electrical Power Output {W}                                         ",
        "    29900,                   !- Minimum Full Load Electrical Power Output {W}                                 ",
        "    65000,                   !- Maximum Full Load Electrical Power Output {W}                                 ",
        "    0.29,                    !- Reference Electrical Efficiency Using Lower Heating Value                     ",
        "    15.0,                    !- Reference Combustion Air Inlet Temperature {C}                                ",
        "    0.00638,                 !- Reference Combustion Air Inlet Humidity Ratio {kgWater/kgDryAir}              ",
        "    0.0,                     !- Reference Elevation {m}                                                       ",
        "    Capstone C65 Power_vs_Temp_Elev,  !- Electrical Power Function of Temperature and Elevation Curve Name    ",
        "    Capstone C65 Efficiency_vs_Temp,  !- Electrical Efficiency Function of Temperature Curve Name             ",
        "    Capstone C65 Efficiency_vs_PLR,  !- Electrical Efficiency Function of Part Load Ratio Curve Name          ",
        "    NaturalGas,              !- Fuel Type                                                                     ",
        "    50000,                   !- Fuel Higher Heating Value {kJ/kg}                                             ",
        "    45450,                   !- Fuel Lower Heating Value {kJ/kg}                                              ",
        "    300,                     !- Standby Power {W}                                                             ",
        "    4500,                    !- Ancillary Power {W}                                                           ",
        "    ,                        !- Ancillary Power Function of Fuel Input Curve Name                             ",
        "    ,                        !- Heat Recovery Water Inlet Node Name                                           ",
        "    ,                        !- Heat Recovery Water Outlet Node Name                                          ",
        "    ,                        !- Reference Thermal Efficiency Using Lower Heat Value                           ",
        "    ,                        !- Reference Inlet Water Temperature {C}                                         ",
        "    ,                        !- Heat Recovery Water Flow Operating Mode                                       ",
        "    ,                        !- Reference Heat Recovery Water Flow Rate {m3/s}                                ",
        "    ,                        !- Heat Recovery Water Flow Rate Function of Temperature and Power Curve Name    ",
        "    ,                        !- Thermal Efficiency Function of Temperature and Elevation Curve Name           ",
        "    ,                        !- Heat Recovery Rate Function of Part Load Ratio Curve Name                     ",
        "    ,                        !- Heat Recovery Rate Function of Inlet Water Temperature Curve Name             ",
        "    ,                        !- Heat Recovery Rate Function of Water Flow Rate Curve Name                     ",
        "    ,                        !- Minimum Heat Recovery Water Flow Rate {m3/s}                                  ",
        "    ,                        !- Maximum Heat Recovery Water Flow Rate {m3/s}                                  ",
        "    ,                        !- Maximum Heat Recovery Water Temperature {C}                                   ",
        "    Capstone C65 Combustion Air Inlet Node,  !- Combustion Air Inlet Node Name                                ",
        "    Capstone C65 Combustion Air Outlet Node,  !- Combustion Air Outlet Node Name                              ",
        "    0.6,                     !- Reference Exhaust Air Mass Flow Rate {kg/s}                                   ",
        "    Capstone C65 ExhFlowRate_vs_Inlet_Temp,  !- Exhaust Air Flow Rate Function of Temperature Curve Name      ",
        "    Capstone C65 ExhFlowRate_vs_PLR,  !- Exhaust Air Flow Rate Function of Part Load Ratio Curve Name         ",
        "    350,                     !- Nominal Exhaust Air Outlet Temperature                                        ",
        "    Capstone C65 ExhTemp_vs_Inlet_Temp,  !- Exhaust Air Temperature Function of Temperature Curve Name        ",
        "    Capstone C65 ExhTemp_vs_PLR;  !- Exhaust Air Temperature Function of Part Load Ratio Curve Name           ",
        "                                                                                                              ",
        "  OutdoorAir:Node,                                                                ",
        "    Capstone C65 Combustion Air Inlet Node,  !- Name                              ",
        "    -1;                      !- Height Above Ground {m}                           ",
        "                                                                                  ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhTemp_vs_Inlet_Temp,  !- Name                                                              ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    -20.,                    !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhTemp_vs_PLR,  !- Name                                                                     ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.;                      !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    Capstone C65 ExhFlowRate_vs_PLR,  !- Name                                                                 ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.;                      !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 ExhFlowRate_vs_Inlet_Temp,  !- Name                                                          ",
        "    1.0,                     !- Coefficient1 Constant                                                         ",
        "    0.0,                     !- Coefficient2 x                                                                ",
        "    0.0,                     !- Coefficient3 x**2                                                             ",
        "    0.0,                     !- Coefficient4 x**3                                                             ",
        "    -20.,                    !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 Efficiency_vs_Temp,  !- Name                                                                 ",
        "    1.0402217,               !- Coefficient1 Constant                                                         ",
        "    -0.0017314,              !- Coefficient2 x                                                                ",
        "    -6.497040E-05,           !- Coefficient3 x**2                                                             ",
        "    5.133175E-07,            !- Coefficient4 x**3                                                             ",
        "    -20.0,                   !- Minimum Value of x                                                            ",
        "    50.0,                    !- Maximum Value of x                                                            ",
        "    ,                        !- Minimum Curve Output                                                          ",
        "    ,                        !- Maximum Curve Output                                                          ",
        "    Temperature,             !- Input Unit Type for X                                                         ",
        "    Dimensionless;           !- Output Unit Type                                                              ",
        "                                                                                                              ",
        "  Curve:Cubic,                                                                                                ",
        "    Capstone C65 Efficiency_vs_PLR,  !- Name                                                                  ",
        "    0.215290,                !- Coefficient1 Constant                                                         ",
        "    2.561463,                !- Coefficient2 x                                                                ",
        "    -3.24613,                !- Coefficient3 x**2                                                             ",
        "    1.497306,                !- Coefficient4 x**3                                                             ",
        "    0.03,                    !- Minimum Value of x                                                            ",
        "    1.0;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Biquadratic,                                                                                          ",
        "    Capstone C65 Power_vs_Temp_Elev,  !- Name                                                                 ",
        "    1.2027697,               !- Coefficient1 Constant                                                         ",
        "    -9.671305E-03,           !- Coefficient2 x                                                                ",
        "    -4.860793E-06,           !- Coefficient3 x**2                                                             ",
        "    -1.542394E-04,           !- Coefficient4 y                                                                ",
        "    9.111418E-09,            !- Coefficient5 y**2                                                             ",
        "    8.797885E-07,            !- Coefficient6 x*y                                                              ",
        "    -17.8,                   !- Minimum Value of x                                                            ",
        "    50.0,                    !- Maximum Value of x                                                            ",
        "    0.0,                     !- Minimum Value of y                                                            ",
        "    3050.,                   !- Maximum Value of y                                                            ",
        "    ,                        !- Minimum Curve Output                                                          ",
        "    ,                        !- Maximum Curve Output                                                          ",
        "    Temperature,             !- Input Unit Type for X                                                         ",
        "    Distance,                !- Input Unit Type for Y                                                         ",
        "    Dimensionless;           !- Output Unit Type                                                              ",
    ])
    ASSERT_TRUE(process_idf(idf_objects))
    compare_err_stream("")
    state.init_state(*state)
    GetExhaustAbsorberInput(*state)
    var thisChillerHeater = state.dataChillerExhaustAbsorption.ExhaustAbsorber[0]
    thisChillerHeater.CoolingLoad = 100000.0
    thisChillerHeater.CoolPartLoadRatio = 1.0
    state.dataPlnt.TotNumLoops = 1
    state.dataPlnt.PlantLoop.allocate(state.dataPlnt.TotNumLoops)
    thisChillerHeater.HWPlantLoc.loopNum = 1
    thisChillerHeater.HWPlantLoc.loopSideNum = LoopSideLocation.Demand
    var hwPlantLoop = state.dataPlnt.PlantLoop[0]
    hwPlantLoop.FluidName = "WATER"
    hwPlantLoop.glycol = Fluid.GetWater(*state)
    hwPlantLoop.LoopDemandCalcScheme = LoopDemandCalcScheme.SingleSetPoint
    hwPlantLoop.LoopSide[LoopSideLocation.Demand].FlowLock = FlowLock.Locked
    EXPECT_EQ(1, thisChillerHeater.ChillReturnNodeNum)
    EXPECT_EQ("EXH CHILLER INLET NODE", state.dataLoopNodes.NodeID[0])
    EXPECT_EQ(2, thisChillerHeater.ChillSupplyNodeNum)
    EXPECT_EQ("EXH CHILLER OUTLET NODE", state.dataLoopNodes.NodeID[1])
    EXPECT_EQ(3, thisChillerHeater.HeatReturnNodeNum)
    EXPECT_EQ("EXH CHILLER HEATING INLET NODE", state.dataLoopNodes.NodeID[2])
    EXPECT_EQ(4, thisChillerHeater.HeatSupplyNodeNum)
    EXPECT_EQ("EXH CHILLER HEATING OUTLET NODE", state.dataLoopNodes.NodeID[3])
    EXPECT_EQ(5, thisChillerHeater.CondReturnNodeNum)
    EXPECT_EQ("EXH CHILLER CONDENSER INLET NODE", state.dataLoopNodes.NodeID[4])
    EXPECT_EQ("CAPSTONE C65 COMBUSTION AIR INLET NODE", state.dataLoopNodes.NodeID[5])
    EXPECT_EQ(7, thisChillerHeater.ExhaustAirInletNodeNum)
    EXPECT_EQ("CAPSTONE C65 COMBUSTION AIR OUTLET NODE", state.dataLoopNodes.NodeID[6])
    let hwSupplySetpoint = 70.0
    let hwReturnTemp = 60.0
    let hwMassFlow = 0.5
    state.dataLoopNodes.Node[thisChillerHeater.HeatReturnNodeNum - 1].Temp = hwReturnTemp
    state.dataLoopNodes.Node[thisChillerHeater.HeatReturnNodeNum - 1].MassFlowRate = hwMassFlow
    state.dataLoopNodes.Node[thisChillerHeater.HeatSupplyNodeNum - 1].TempSetPoint = hwSupplySetpoint
    let exhaustInTemp = 350.0
    let absLeavingTemp = 176.667
    let exhaustInMassFlowRate = 0.5
    let exhaustInHumRate = 0.005
    state.dataLoopNodes.Node[thisChillerHeater.ExhaustAirInletNodeNum - 1].Temp = exhaustInTemp
    state.dataLoopNodes.Node[thisChillerHeater.ExhaustAirInletNodeNum - 1].MassFlowRate = exhaustInMassFlowRate
    state.dataLoopNodes.Node[thisChillerHeater.ExhaustAirInletNodeNum - 1].HumRat = exhaustInHumRate
    var loadinput = 5000.0
    var runflaginput = True
    thisChillerHeater.calcHeater(*state, loadinput, runflaginput)
    let CpHW = hwPlantLoop.glycol.getSpecificHeat(*state, hwReturnTemp, "UnitTest")
    EXPECT_EQ(4185.0, CpHW)
    let expectedHeatingLoad = (hwSupplySetpoint - hwReturnTemp) * hwMassFlow * CpHW
    EXPECT_NEAR(20925.0, expectedHeatingLoad, 1e-6)
    EXPECT_NEAR(thisChillerHeater.HeatingLoad, expectedHeatingLoad, 1e-6)
    EXPECT_NEAR(thisChillerHeater.HeatElectricPower, 400.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.HotWaterReturnTemp, 60.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.HotWaterSupplyTemp, 70.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.HotWaterFlowRate, 0.5, 1e-6)
    EXPECT_NEAR(thisChillerHeater.FractionOfPeriodRunning, 1.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.ElectricPower, 400.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.ExhaustInTemp, 350.0, 1e-6)
    EXPECT_NEAR(thisChillerHeater.ExhaustInFlow, 0.5, 1e-6)
    let CpAir = Psychrometrics.PsyCpAirFnW(exhaustInHumRate)
    let expectedExhHeatRecPotentialHeat = exhaustInMassFlowRate * CpAir * (exhaustInTemp - absLeavingTemp)
    EXPECT_NEAR(87891.51, expectedExhHeatRecPotentialHeat, 0.01)
    EXPECT_NEAR(expectedExhHeatRecPotentialHeat, thisChillerHeater.ExhHeatRecPotentialHeat, 0.01)

@test
def ExhAbsorption_GetInput_Multiple_Objects_Test(regression):
    let idf_objects = delimited_string([
        "  ChillerHeater:Absorption:DoubleEffect,                                                                      ",
        "    Exh Chiller1,             !- Name                                                                         ",
        "    100000,                   !- Nominal Cooling Capacity {W}                                                 ",
        "    0.8,                      !- Heating to Cooling Capacity Ratio                                            ",
        "    0.97,                     !- Thermal Energy Input to Cooling Output Ratio                                 ",
        "    1.25,                     !- Thermal Energy Input to Heating Output Ratio                                 ",
        "    0.01,                     !- Electric Input to Cooling Output Ratio                                       ",
        "    0.005,                    !- Electric Input to Heating Output Ratio                                       ",
        "    Exh Chiller1 Inlet Node,  !- Chilled Water Inlet Node Name                                                ",
        "    Exh Chiller1 Outlet Node, !- Chilled Water Outlet Node Name                                               ",
        "    Exh Chiller1 Condenser Inlet Node,   !- Condenser Inlet Node Name                                         ",
        "    Exh Chiller1 Condenser Outlet Node,  !- Condenser Outlet Node Name                                        ",
        "    Exh Chiller1 Heating Inlet Node,   !- Hot Water Inlet Node Name                                           ",
        "    Exh Chiller1 Heating Outlet Node,  !- Hot Water Outlet Node Name                                          ",
        "    0.000001,                !- Minimum Part Load Ratio                                                       ",
        "    1.0,                     !- Maximum Part Load Ratio                                                       ",
        "    0.6,                     !- Optimum Part Load Ratio                                                       ",
        "    29,                      !- Design Entering Condenser Water Temperature {C}                               ",
        "    7,                       !- Design Leaving Chilled Water Temperature {C}                                  ",
        "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                         ",
        "    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                       ",
        "    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                             ",
        "    ExhAbsorb_CapFt,         !- Cooling Capacity Function of Temperature Curve Name                           ",
        "    ExhAbsorb_EIRFt,         !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name         ",
        "    ExhAbsorb_PLR,           !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name     ",
        "    ExhAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name     ",
        "    ExhAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name ",
        "    ExhAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                      ",
        "    ExhAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name      ",
        "    EnteringCondenser,       !- Temperature Curve Input Variable                                              ",
        "    AirCooled,               !- Condenser Type                                                                ",
        "    2,                       !- Chilled Water Temperature Lower Limit {C}                                     ",
        "    Generator:MicroTurbine,  !- Exhaust Source Object Type                                                    ",
        "    Capstone1 C65,           !- Exhaust Source Object Name                                                    ",
        "    ;                        !- Sizing Factor                                                                 ",
        "                                                                                                              ",
        "  OutdoorAir:Node,                                                                                            ",
        "    Exh Chiller1 Condenser Inlet Node,                       !- Name                                          ",
        "    -1;                                                      !- Height Above Ground                           ",
        "                                                                                                              ",
        "                                                                                                              ",
        "  ChillerHeater:Absorption:DoubleEffect,                                                                      ",
        "    Exh Chiller2,             !- Name                                                                         ",
        "    100000,                   !- Nominal Cooling Capacity {W}                                                 ",
        "    0.8,                      !- Heating to Cooling Capacity Ratio                                            ",
        "    0.97,                     !- Thermal Energy Input to Cooling Output Ratio                                 ",
        "    1.25,                     !- Thermal Energy Input to Heating Output Ratio                                 ",
        "    0.01,                     !- Electric Input to Cooling Output Ratio                                       ",
        "    0.005,                    !- Electric Input to Heating Output Ratio                                       ",
        "    Exh Chiller2 Inlet Node,  !- Chilled Water Inlet Node Name                                                ",
        "    Exh Chiller2 Outlet Node, !- Chilled Water Outlet Node Name                                               ",
        "    Exh Chiller2 Condenser Inlet Node,   !- Condenser Inlet Node Name                                         ",
        "    Exh Chiller2 Condenser Outlet Node,  !- Condenser Outlet Node Name                                        ",
        "    Exh Chiller2 Heating Inlet Node,   !- Hot Water Inlet Node Name                                           ",
        "    Exh Chiller2 Heating Outlet Node,  !- Hot Water Outlet Node Name                                          ",
        "    0.000001,                !- Minimum Part Load Ratio                                                       ",
        "    1.0,                     !- Maximum Part Load Ratio                                                       ",
        "    0.6,                     !- Optimum Part Load Ratio                                                       ",
        "    29,                      !- Design Entering Condenser Water Temperature {C}                               ",
        "    7,                       !- Design Leaving Chilled Water Temperature {C}                                  ",
        "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                         ",
        "    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                       ",
        "    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                             ",
        "    ExhAbsorb_CapFt,         !- Cooling Capacity Function of Temperature Curve Name                           ",
        "    ExhAbsorb_EIRFt,         !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name         ",
        "    ExhAbsorb_PLR,           !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name     ",
        "    ExhAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name     ",
        "    ExhAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name ",
        "    ExhAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                      ",
        "    ExhAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name      ",
        "    EnteringCondenser,       !- Temperature Curve Input Variable                                              ",
        "    AirCooled,               !- Condenser Type                                                                ",
        "    2,                       !- Chilled Water Temperature Lower Limit {C}                                     ",
        "    Generator:MicroTurbine,  !- Exhaust Source Object Type                                                    ",
        "    Capstone2 C65,           !- Exhaust Source Object Name                                                    ",
        "    ;                        !- Sizing Factor                                                                 ",
        "                                                                                                              ",
        "  OutdoorAir:Node,                                                                                            ",
        "    Exh Chiller2 Condenser Inlet Node,                       !- Name                                          ",
        "    -1;                                                      !- Height Above Ground                           ",
        "                                                                                                              ",
        "                                                                                                              ",
        "  ChillerHeater:Absorption:DoubleEffect,                                                                      ",
        "    Exh Chiller3,             !- Name                                                                         ",
        "    100000,                   !- Nominal Cooling Capacity {W}                                                 ",
        "    0.8,                      !- Heating to Cooling Capacity Ratio                                            ",
        "    0.97,                     !- Thermal Energy Input to Cooling Output Ratio                                 ",
        "    1.25,                     !- Thermal Energy Input to Heating Output Ratio                                 ",
        "    0.01,                     !- Electric Input to Cooling Output Ratio                                       ",
        "    0.005,                    !- Electric Input to Heating Output Ratio                                       ",
        "    Exh Chiller3 Inlet Node,  !- Chilled Water Inlet Node Name                                                ",
        "    Exh Chiller3 Outlet Node, !- Chilled Water Outlet Node Name                                               ",
        "    Exh Chiller3 Condenser Inlet Node,   !- Condenser Inlet Node Name                                         ",
        "    Exh Chiller3 Condenser Outlet Node,  !- Condenser Outlet Node Name                                        ",
        "    Exh Chiller3 Heating Inlet Node,   !- Hot Water Inlet Node Name                                           ",
        "    Exh Chiller3 Heating Outlet Node,  !- Hot Water Outlet Node Name                                          ",
        "    0.000001,                !- Minimum Part Load Ratio                                                       ",
        "    1.0,                     !- Maximum Part Load Ratio                                                       ",
        "    0.6,                     !- Optimum Part Load Ratio                                                       ",
        "    29,                      !- Design Entering Condenser Water Temperature {C}                               ",
        "    7,                       !- Design Leaving Chilled Water Temperature {C}                                  ",
        "    0.0011,                  !- Design Chilled Water Flow Rate {m3/s}                                         ",
        "    0.0011,                  !- Design Condenser Water Flow Rate {m3/s}                                       ",
        "    0.0043,                  !- Design Hot Water Flow Rate {m3/s}                                             ",
        "    ExhAbsorb_CapFt,         !- Cooling Capacity Function of Temperature Curve Name                           ",
        "    ExhAbsorb_EIRFt,         !- Fuel Input to Cooling Output Ratio Function of Temperature Curve Name         ",
        "    ExhAbsorb_PLR,           !- Fuel Input to Cooling Output Ratio Function of Part Load Ratio Curve Name     ",
        "    ExhAbsFlatBiQuad,        !- Electric Input to Cooling Output Ratio Function of Temperature Curve Name     ",
        "    ExhAbsFlatQuad,          !- Electric Input to Cooling Output Ratio Function of Part Load Ratio Curve Name ",
        "    ExhAbsInvLinearQuad,     !- Heating Capacity Function of Cooling Capacity Curve Name                      ",
        "    ExhAbsLinearQuad,        !- Fuel Input to Heat Output Ratio During Heating Only Operation Curve Name      ",
        "    EnteringCondenser,       !- Temperature Curve Input Variable                                              ",
        "    AirCooled,               !- Condenser Type                                                                ",
        "    2,                       !- Chilled Water Temperature Lower Limit {C}                                     ",
        "    Generator:MicroTurbine,  !- Exhaust Source Object Type                                                    ",
        "    Capstone3 C65,           !- Exhaust Source Object Name                                                    ",
        "    ;                        !- Sizing Factor                                                                 ",
        "                                                                                                              ",
        "  OutdoorAir:Node,                                                                                            ",
        "    Exh Chiller3 Condenser Inlet Node,                       !- Name                                          ",
        "    -1;                                                      !- Height Above Ground                           ",
        "                                                                                                              ",
        "                                                                                                              ",
        "  CURVE:BIQUADRATIC,                                                                                          ",
        "    ExhAbsorb_CapFt,         !- Name                                                                          ",
        "    -0.115131E+01,           !- Coefficient1 Constant                                                         ",
        "    -0.801316E-01,           !- Coefficient2 x                                                                ",
        "    -0.945353E-02,           !- Coefficient3 x**2                                                             ",
        "    0.209867E+00,            !- Coefficient4 y                                                                ",
        "    -0.567055E-02,           !- Coefficient5 y**2                                                             ",
        "    0.943605E-02,            !- Coefficient6 x*y                                                              ",
        "    4.44444,                 !- Minimum Value of x                                                            ",
        "    8.88889,                 !- Maximum Value of x                                                            ",
        "    21.11111,                !- Minimum Value of y                                                            ",
        "    35.00000;                !- Maximum Value of y                                                            ",
        "                                                                                                              ",
        "  CURVE:BIQUADRATIC,                                                                                          ",
        "    ExhAbsorb_EIRFt,         !- Name                                                                          ",
        "    0.131195E+01,            !- Coefficient1 Constant                                                         ",
        "    -0.159283E-01,           !- Coefficient2 x                                                                ",
        "    0.773725E-03,            !- Coefficient3 x**2                                                             ",
        "    -0.196279E-01,           !- Coefficient4 y                                                                ",
        "    0.378351E-03,            !- Coefficient5 y**2                                                             ",
        "    0.558356E-04,            !- Coefficient6 x*y                                                              ",
        "    4.44444,                 !- Minimum Value of x                                                            ",
        "    8.88889,                 !- Maximum Value of x                                                            ",
        "    21.11111,                !- Minimum Value of y                                                            ",
        "    35.00000;                !- Maximum Value of y                                                            ",
        "                                                                                                              ",
        "  Curve:Biquadratic,                                                                                          ",
        "    ExhAbsFlatBiQuad,        !- Name                                                                          ",
        "    1.000000000,             !- Coefficient1 Constant                                                         ",
        "    0.000000000,             !- Coefficient2 x                                                                ",
        "    0.000000000,             !- Coefficient3 x**2                                                             ",
        "    0.000000000,             !- Coefficient4 y                                                                ",
        "    0.000000000,             !- Coefficient5 y**2                                                             ",
        "    0.000000000,             !- Coefficient6 x*y                                                              ",
        "    0.,                      !- Minimum Value of x                                                            ",
        "    50.,                     !- Maximum Value of x                                                            ",
        "    0.,                      !- Minimum Value of y                                                            ",
        "    50.;                     !- Maximum Value of y                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    ExhAbsLinearQuad,        !- Name                                                                          ",
        "    0.000000000,             !- Coefficient1 Constant                                                         ",
        "    1.000000000,             !- Coefficient2 x                                                                ",
        "    0.000000000,             !- Coefficient3 x**2                                                             ",
        "    0.,                      !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    ExhAbsInvLinearQuad,     !- Name                                                                          ",
        "    1.000000000,             !- Coefficient1 Constant                                                         ",
        "    -1.000000000,            !- Coefficient2 x                                                                ",
        "    0.000000000,             !- Coefficient3 x**2                                                             ",
        "    0.,                      !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:QUADRATIC,                                                                                            ",
        "    ExhAbsorb_PLR,           !- Name                                                                          ",
        "    0.026280035,             !- Coefficient1 Constant                                                         ",
        "    0.678066088,             !- Coefficient2 x                                                                ",
        "    0.273905867,             !- Coefficient3 x**2                                                             ",
        "    0.0,                     !- Minimum Value of x                                                            ",
        "    1.0;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Curve:Quadratic,                                                                                            ",
        "    ExhAbsFlatQuad,          !- Name                                                                          ",
        "    1.000000000,             !- Coefficient1 Constant                                                         ",
        "    0.000000000,             !- Coefficient2 x                                                                ",
        "    0.000000000,             !- Coefficient3 x**2                                                             ",
        "    0.,                      !- Minimum Value of x                                                            ",
        "    50.;                     !- Maximum Value of x                                                            ",
        "                                                                                                              ",
        "  Generator:MicroTurbine,                                                                                     ",
        "    Capstone1 C65,           !- Name                                                                          ",
        "    65000,                   !- Reference Electrical Power Output {W}                                         ",
        "    29900,                   !- Minimum Full Load Electrical Power Output {W}                                 ",
        "    65000,                   !- Maximum Full Load Electrical Power Output {W}                                 ",
        "    0.29,                    !- Reference Electrical Efficiency Using Lower Heating Value                     ",
        "    15.0,                    !- Reference Combustion Air Inlet Temperature {C}                                ",
        "    0.00638,                 !- Reference Combustion Air Inlet Humidity Ratio {kgWater/kgDryAir}              ",
        "    0.0,                     !- Reference Elevation {m}                                                       ",
        "    Capstone C65 Power_vs_Temp_Elev,  !- Electrical Power Function of Temperature and Elevation Curve Name    ",
        "    Capstone C65 Efficiency_vs_Temp,  !- Electrical Efficiency Function of Temperature Curve Name             ",
        "    Capstone C65 Efficiency_vs_PLR,   !- Electrical Efficiency Function of Part Load Ratio Curve Name         ",
        "    NaturalGas,              !- Fuel Type                                                                     ",
        "    50000,                   !- Fuel Higher Heating Value {kJ/kg}                                             ",
        "    45450,                   !- Fuel Lower Heating Value {kJ/kg}                                              ",
        "    300,                     !- Standby Power {W}                                                             ",
        "    4500,                    !- Ancillary Power {W}                                                           ",
        "    ,                        !- Ancillary Power Function of Fuel Input Curve Name                             ",
        "    ,                        !- Heat Recovery Water Inlet Node Name                                           ",
        "    ,                        !- Heat Recovery Water Outlet Node Name                                          ",
        "    ,                        !- Reference Thermal Efficiency Using Lower Heat Value                           ",
        "    ,                        !- Reference Inlet Water Temperature {C}                                         ",
        "    ,                        !- Heat Recovery Water Flow Operating Mode                                       ",
        "    ,                        !- Reference Heat Recovery Water Flow Rate {m3/s}                                ",
        "    ,                        !- Heat Recovery Water Flow Rate Function of Temperature and Power Curve Name    ",
        "    ,                        !- Thermal Efficiency Function of Temperature and Elevation Curve Name           ",
        "    ,                        !- Heat Recovery Rate Function of Part Load Ratio Curve Name                     ",
        "    ,                        !- Heat Recovery Rate Function of Inlet Water Temperature Curve Name             ",
        "    ,                        !- Heat Recovery Rate