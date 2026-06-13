from testing import *
from AirflowNetwork.Elements import *
from AirflowNetwork.Properties import *
from AirflowNetwork.Solver import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataAirLoop import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataIPShortCuts import *
from EnergyPlus.DataLoopNode import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.Material import *
from EnergyPlus.OutAirNodeManager import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SurfaceGeometry import *
from EnergyPlus.UtilityRoutines import *
from Fixtures.EnergyPlusFixture import *

using EnergyPlus
using AirflowNetwork
using DataHeatBalance

@fixture
def EnergyPlusFixture():
    ...

@fixture
def AirflowNetwork_SolverTest_HorizontalOpening():
    i = 1
    j = 1
    n = 0
    m = 0
    NF = 0
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    n = 1
    m = 2
    state.afn.AirflowNetworkCompData.allocate(j)
    state.afn.AirflowNetworkCompData[j].TypeNum = 1
    state.afn.MultizoneSurfaceData.allocate(i)
    state.afn.MultizoneSurfaceData[i].Width = 10.0
    state.afn.MultizoneSurfaceData[i].Height = 5.0
    state.afn.MultizoneSurfaceData[i].OpenFactor = 1.0
    state.afn.node_states.clear()
    for it in range(2):
        state.afn.node_states.append(AIRDENSITY_CONSTEXPR(20.0, 101325.0, 0.0))
    state.afn.node_states[0].density = 1.2
    state.afn.node_states[1].density = 1.18
    state.afn.MultizoneCompHorOpeningData.allocate(1)
    state.afn.MultizoneCompHorOpeningData[1].FlowCoef = 0.1
    state.afn.MultizoneCompHorOpeningData[1].FlowExpo = 0.5
    state.afn.MultizoneCompHorOpeningData[1].Slope = 90.0
    state.afn.MultizoneCompHorOpeningData[1].DischCoeff = 0.2
    state.afn.AirflowNetworkLinkageData.allocate(i)
    state.afn.AirflowNetworkLinkageData[i].NodeHeights[0] = 4.0
    state.afn.AirflowNetworkLinkageData[i].NodeHeights[1] = 2.0
    multiplier = 1.0
    control = 1.0
    NF = state.afn.MultizoneCompHorOpeningData[1].calculate(
        state, True, 0.05, 1, multiplier, control, state.afn.node_states[0], state.afn.node_states[1], F, DF)
    assert_approx_equal(3.47863, F[0], 0.00001)
    assert_approx_equal(34.7863, DF[0], 0.0001)
    assert_approx_equal(2.96657, F[1], 0.00001)
    assert_equal(0.0, DF[1])
    NF = state.afn.MultizoneCompHorOpeningData[1].calculate(
        state, True, -0.05, 1, multiplier, control, state.afn.node_states[0], state.afn.node_states[1], F, DF)
    assert_approx_equal(-3.42065, F[0], 0.00001)
    assert_approx_equal(34.20649, DF[0], 0.0001)
    assert_approx_equal(2.96657, F[1], 0.00001)
    assert_equal(0.0, DF[1])
    state.afn.AirflowNetworkLinkageData.deallocate()
    state.afn.MultizoneCompHorOpeningData.deallocate()
    state.afn.MultizoneSurfaceData.deallocate()
    state.afn.AirflowNetworkCompData.deallocate()

@fixture
def AirflowNetwork_SolverTest_Coil():
    NF = 0
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    state.afn.AirflowNetworkCompData.allocate(1)
    state.afn.AirflowNetworkCompData[0].TypeNum = 1
    state.afn.DisSysCompCoilData.allocate(1)
    state.afn.DisSysCompCoilData[0].hydraulicDiameter = 1.0
    state.afn.DisSysCompCoilData[0].L = 1.0
    state.afn.node_states.clear()
    for it in range(2):
        state.afn.node_states.append(AIRDENSITY_CONSTEXPR(20.0, 101325.0, 0.0))
    state.afn.node_states[0].density = 1.2
    state.afn.node_states[1].density = 1.2
    state.afn.node_states[0].viscosity = 1.0e-5
    state.afn.node_states[1].viscosity = 1.0e-5
    F[1] = DF[1] = 0.0
    multiplier = 1.0
    control = 1.0
    NF = state.afn.DisSysCompCoilData[0].calculate(
        state, True, 0.05, 1, multiplier, control, state.afn.node_states[0], state.afn.node_states[1], F, DF)
    assert_approx_equal(-294.5243112740431, F[0], 0.00001)
    assert_approx_equal(5890.4862254808613, DF[0], 0.0001)
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[1])
    NF = state.afn.DisSysCompCoilData[0].calculate(
        state, True, -0.05, 1, multiplier, control, state.afn.node_states[0], state.afn.node_states[1], F, DF)
    assert_approx_equal(294.5243112740431, F[0], 0.00001)
    assert_approx_equal(5890.4862254808613, DF[0], 0.0001)
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[1])
    state.afn.DisSysCompCoilData.deallocate()
    state.afn.AirflowNetworkCompData.deallocate()

@fixture
def AirflowNetwork_SolverTest_Crack():
    NF = 0
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    crack = SurfaceCrack()
    crack.coefficient = 0.001
    crack.exponent = 0.65
    state0 = AirState()
    state1 = AirState()
    sqrt_density = state0.sqrt_density
    viscosity = state0.viscosity
    dp = 10.0
    NF = crack.calculate(state, True, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(0.01 * sqrt_density / viscosity, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.001 * sqrt_density / viscosity, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = crack.calculate(state, True, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(-0.01 * sqrt_density / viscosity, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.001 * sqrt_density / viscosity, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = crack.calculate(state, False, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(0.001 * math.pow(10.0, 0.65), F[0])
    assert_equal(0.0, F[1])
    assert_almost_equal(0.000065 * math.pow(10.0, 0.65), DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = crack.calculate(state, False, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(-0.001 * math.pow(10.0, 0.65), F[0])
    assert_equal(0.0, F[1])
    assert_almost_equal(0.000065 * math.pow(10.0, 0.65), DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)

@fixture
def AirflowNetwork_SolverTest_GenericCrack():
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    coef = 0.001
    expo = 0.65
    state0 = AirState()
    state1 = AirState()
    sqrt_density = state0.sqrt_density
    viscosity = state0.viscosity
    dp = 10.0
    generic_crack(coef, expo, True, dp, state0, state1, F, DF)
    assert_equal(0.01 * sqrt_density / viscosity, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.001 * sqrt_density / viscosity, DF[0])
    assert_equal(0.0, DF[1])
    generic_crack(coef, expo, True, -dp, state0, state1, F, DF)
    assert_equal(-0.01 * sqrt_density / viscosity, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.001 * sqrt_density / viscosity, DF[0])
    assert_equal(0.0, DF[1])
    generic_crack(coef, expo, False, dp, state0, state1, F, DF)
    assert_equal(0.001 * math.pow(10.0, 0.65), F[0])
    assert_equal(0.0, F[1])
    assert_almost_equal(0.000065 * math.pow(10.0, 0.65), DF[0])
    assert_equal(0.0, DF[1])
    generic_crack(coef, expo, False, -dp, state0, state1, F, DF)
    assert_equal(-0.001 * math.pow(10.0, 0.65), F[0])
    assert_equal(0.0, F[1])
    assert_almost_equal(0.000065 * math.pow(10.0, 0.65), DF[0])
    assert_equal(0.0, DF[1])

@fixture
def AirflowNetwork_SolverTest_SpecifiedMassFlow():
    NF = 0
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    element = SpecifiedMassFlow()
    element.mass_flow = 0.1
    state0 = AirState()
    state1 = AirState()
    dp = 10.0
    f = element.mass_flow
    NF = element.calculate(state, True, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, True, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, False, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, False, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)

@fixture
def AirflowNetwork_SolverTest_SpecifiedVolumeFlow():
    NF = 0
    F = [0.0, 0.0]
    DF = [0.0, 0.0]
    element = SpecifiedVolumeFlow()
    element.volume_flow = 0.1
    state0 = AirState()
    state1 = AirState()
    density = state0.density
    dp = 10.0
    f = element.volume_flow * density
    NF = element.calculate(state, True, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, True, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, False, dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)
    NF = element.calculate(state, False, -dp, 0, 1.0, 1.0, state0, state1, F, DF)
    assert_equal(f, F[0])
    assert_equal(0.0, F[1])
    assert_equal(0.0, DF[0])
    assert_equal(0.0, DF[1])
    assert_equal(1, NF)

@fixture
def AirflowNetwork_TestTriangularWindowWarning():
    state.dataHeatBal.Zone.allocate(1)
    state.dataHeatBal.Zone[1].Name = "WEST_ZONE"
    state.dataSurface.Surface.allocate(3)
    state.dataSurface.Surface[1].Name = "SURFACE_1"
    state.dataSurface.Surface[1].Zone = 1
    state.dataSurface.Surface[1].ZoneName = "WEST_ZONE"
    state.dataSurface.Surface[1].Azimuth = 0.0
    state.dataSurface.Surface[1].ExtBoundCond = 0
    state.dataSurface.Surface[1].HeatTransSurf = True
    state.dataSurface.Surface[1].Tilt = 90.0
    state.dataSurface.Surface[1].Sides = 4
    state.dataSurface.Surface[2].Name = "SURFACE_2"
    state.dataSurface.Surface[2].Zone = 1
    state.dataSurface.Surface[2].ZoneName = "WEST_ZONE"
    state.dataSurface.Surface[2].Azimuth = 180.0
    state.dataSurface.Surface[2].ExtBoundCond = 0
    state.dataSurface.Surface[2].HeatTransSurf = True
    state.dataSurface.Surface[2].Tilt = 90.0
    state.dataSurface.Surface[2].Sides = 4
    state.dataSurface.Surface[3].Name = "WINDOW1"
    state.dataSurface.Surface[3].Zone = 1
    state.dataSurface.Surface[3].ZoneName = "WEST_ZONE"
    state.dataSurface.Surface[3].Azimuth = 180.0
    state.dataSurface.Surface[3].ExtBoundCond = 0
    state.dataSurface.Surface[3].HeatTransSurf = True
    state.dataSurface.Surface[3].Tilt = 90.0
    state.dataSurface.Surface[3].Sides = 3
    state.dataSurface.Surface[3].Vertex.allocate(3)
    state.dataSurface.Surface[3].Vertex[1].x = 3.0
    state.dataSurface.Surface[3].Vertex[2].x = 3.0
    state.dataSurface.Surface[3].Vertex[3].x = 1.0
    state.dataSurface.Surface[3].Vertex[1].y = 10.778
    state.dataSurface.Surface[3].Vertex[2].y = 10.778
    state.dataSurface.Surface[3].Vertex[3].y = 10.778
    state.dataSurface.Surface[3].Vertex[1].z = 2.0
    state.dataSurface.Surface[3].Vertex[2].z = 1.0
    state.dataSurface.Surface[3].Vertex[3].z = 1.0
    SurfaceGeometry.AllocateSurfaceWindows(state, 3)
    state.dataSurface.Surface[1].OriginalClass = DataSurfaces.SurfaceClass.Window
    state.dataSurface.Surface[2].OriginalClass = DataSurfaces.SurfaceClass.Window
    state.dataSurface.Surface[3].OriginalClass = DataSurfaces.SurfaceClass.Window
    state.dataGlobal.NumOfZones = 1
    idf_objects = delimited_string([
        "Schedule:Constant,OnSch,,1.0;",
        "Schedule:Constant,Aula people sched,,0.0;",
        "Schedule:Constant,Sempre 21,,21.0;",
        "AirflowNetwork:SimulationControl,",
        "  NaturalVentilation, !- Name",
        "  MultizoneWithoutDistribution, !- AirflowNetwork Control",
        "  SurfaceAverageCalculation, !- Wind Pressure Coefficient Type",
        "  , !- Height Selection for Local Wind Pressure Calculation",
        "  LOWRISE, !- Building Type",
        "  1000, !- Maximum Number of Iterations{ dimensionless }",
        "  LinearInitializationMethod, !- Initialization Type",
        "  0.0001, !- Relative Airflow Convergence Tolerance{ dimensionless }",
        "  0.0001, !- Absolute Airflow Convergence Tolerance{ kg / s }",
        "  -0.5, !- Convergence Acceleration Limit{ dimensionless }",
        "  90, !- Azimuth Angle of Long Axis of Building{ deg }",
        "  0.36;                    !- Ratio of Building Width Along Short Axis to Width Along Long Axis",
        "AirflowNetwork:MultiZone:Zone,",
        "  WEST_ZONE, !- Zone Name",
        "  Temperature, !- Ventilation Control Mode",
        "  Sempre 21, !- Ventilation Control Zone Temperature Setpoint Schedule Name",
        "  1, !- Minimum Venting Open Factor{ dimensionless }",
        "  , !- Indoor and Outdoor Temperature Difference Lower Limit For Maximum Venting Open Factor{ deltaC }",
        "  100, !- Indoor and Outdoor Temperature Difference Upper Limit for Minimum Venting Open Factor{ deltaC }",
        "  , !- Indoor and Outdoor Enthalpy Difference Lower Limit For Maximum Venting Open Factor{ deltaJ / kg }",
        "  300000, !- Indoor and Outdoor Enthalpy Difference Upper Limit for Minimum Venting Open Factor{ deltaJ / kg }",
        "  Aula people sched, !- Venting Availability Schedule Name",
        "  Standard;                !- Single Sided Wind Pressure Coefficient Algorithm",
        "AirflowNetwork:MultiZone:Surface,",
        "  Surface_1, !- Surface Name",
        "  CR-1, !- Leakage Component Name",
        "  , !- External Node Name",
        "  1; !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
        "AirflowNetwork:MultiZone:Surface,",
        "  Surface_2, !- Surface Name",
        "  CR-1, !- Leakage Component Name",
        "  , !- External Node Name",
        "  1; !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
        "AirflowNetwork:MultiZone:Surface,",
        "  Window1, !- Surface Name",
        "  Simple Window, !- Leakage Component Name",
        "  , !- External Node Name",
        "  1; !- Window / Door Opening Factor, or Crack Factor{ dimensionless }",
        "AirflowNetwork:MultiZone:Component:SimpleOpening,",
        "  Simple Window, !- Name",
        "  0.0010, !- Air Mass Flow Coefficient When Opening is Closed{ kg / s - m }",
        "  0.65, !- Air Mass Flow Exponent When Opening is Closed{ dimensionless }",
        "  0.01, !- Minimum Density Difference for Two - Way Flow{ kg / m3 }",
        "  0.78;                    !- Discharge Coefficient{ dimensionless }",
        "AirflowNetwork:MultiZone:ReferenceCrackConditions,",
        "  ReferenceCrackConditions, !- Name",
        "  20.0, !- Reference Temperature{ C }",
        "  101320, !- Reference Barometric Pressure{ Pa }",
        "  0.005;                   !- Reference Humidity Ratio{ kgWater / kgDryAir }",
        "AirflowNetwork:MultiZone:Surface:Crack,",
        "  CR-1, !- Name",
        "  0.01, !- Air Mass Flow Coefficient at Reference Conditions{ kg / s }",
        "  0.667, !- Air Mass Flow Exponent{ dimensionless }",
        "  ReferenceCrackConditions; !- Reference Crack Conditions",
    ])
    assert_true(process_idf(idf_objects))
    state.init_state(state)
    state.afn.get_input()
    error_string = delimited_string([
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = ONSCH",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = AULA PEOPLE SCHED",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** ProcessScheduleInput: Schedule:Constant = SEMPRE 21",
        "   **   ~~~   ** Schedule Type Limits Name is empty.",
        "   **   ~~~   ** Schedule will not be validated.",
        "   ** Warning ** AirflowNetwork::Solver::get_input: AirflowNetwork:MultiZone:Surface=\"WINDOW1\".",
        "   **   ~~~   ** The opening is a Triangular subsurface. A rectangular subsurface will be used with equivalent width and height.",
    ])
    assert_true(compare_err_stream(error_string, True))
    state.afn.AirflowNetworkNodeData.deallocate()
    state.afn.AirflowNetworkCompData.deallocate()
    state.afn.MultizoneExternalNodeData.deallocate()
    state.dataHeatBal.Zone.deallocate()
    state.dataSurface.Surface.deallocate()
    state.dataSurface.SurfaceWindow.deallocate()

@fixture
def AirflowNetwork_UserDefinedDuctViewFactors():
    idf_objects = delimited_string([
        "  SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    No,                      !- Do Plant Sizing Calculation",
        "    No,                      !- Run Simulation for Sizing Periods",
        "    Yes;                     !- Run Simulation for Weather File Run Periods",
        "  Building,",
        "    Exercise 1A,             !- Name",
        "    0.0,                     !- North Axis {deg}",
        "    Country,                 !- Terrain",
        "    0.04,                    !- Loads Convergence Tolerance Value",
        "    0.4,                     !- Temperature Convergence Tolerance Value {deltaC}",
        "    FullInteriorAndExterior, !- Solar Distribution",
        "    ,                        !- Maximum Number of Warmup Days",
        "    6;                       !- Minimum Number of Warmup Days",
        "  SurfaceConvectionAlgorithm:Inside,",
        "    TARP;                    !- Algorithm",
        "  SurfaceConvectionAlgorithm:Outside,",
        "    TARP;                    !- Algorithm",
        "  HeatBalanceAlgorithm,",
        "    ConductionTransferFunction;  !- Algorithm",
        "  Timestep,",
        "    4;                       !- Number of Timesteps per Hour",
        "  Site:Location,",
        "    Phoenix,                 !- Name",
        "    33.43,                   !- Latitude {deg}",
        "    -112.02,                 !- Longitude {deg}",
        "    -7.0,                    !- Time Zone {hr}",
        "    339.0;                   !- Elevation {m}",
        "  SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Cooling .4% Conditions DB=>MWB,  !- Name",
        "    7,                       !- Month",
        "    21,                      !- Day of Month",
        "    SummerDesignDay,         !- Day Type",
        "    32.80000,                !- Maximum Dry-Bulb Temperature {C}",
        "    10.90000,                !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    23.60000,                !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.21,                !- Barometric Pressure {Pa}",
        "    0.0,                     !- Wind Speed {m/s}",
        "    0.0,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    1.000000;                !- Sky Clearness",
        "  SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Heating 99.6% Conditions,  !- Name",
        "    1,                       !- Month",
        "    21,                      !- Day of Month",
        "    WinterDesignDay,         !- Day Type",
        "    -21.20000,               !- Maximum Dry-Bulb Temperature {C}",
        "    0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    -21.20000,               !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.21,                !- Barometric Pressure {Pa}",
        "    4.600000,                !- Wind Speed {m/s}",
        "    270.0000,                !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    0.0;                     !- Sky Clearness",
        "  RunPeriod,",
        "    RP1,                     !- Name",
        "    1,                       !- Begin Month",
        "    1,                       !- Begin Day of Month",
        "    ,                        !- Begin Year",
        "    12,                      !- End Month",
        "    31,                      !- End Day of Month",
        "    ,                        !- End Year",
        "    Tuesday,                 !- Day of Week for Start Day",
        "    Yes,                     !- Use Weather File Holidays and Special Days",
        "    Yes,                     !- Use Weather File Daylight Saving Period",
        "    No,                      !- Apply Weekend Holiday Rule",
        "    Yes,                     !- Use Weather File Rain Indicators",
        "    Yes;                     !- Use Weather File Snow Indicators",
        "  Site:GroundTemperature:BuildingSurface,",
        "    23.0,                    !- January Ground Temperature {C}",
        "    23.0,                    !- February Ground Temperature {C}",
        "    23.0,                    !- March Ground Temperature {C}",
        "    23.0,                    !- April Ground Temperature {C}",
        "    23.0,                    !- May Ground Temperature {C}",
        "    23.0,                    !- June Ground Temperature {C}",
        "    23.0,                    !- July Ground Temperature {C}",
        "    23.0,                    !- August Ground Temperature {C}",
        "    23.0,                    !- September Ground Temperature {C}",
        "    23.0,                    !- October Ground Temperature {C}",
        "    23.0,                    !- November Ground Temperature {C}",
        "    23.0;                    !- December Ground Temperature {C}",
        "  ScheduleTypeLimits,",
        "    Temperature,             !- Name",
        "    -60,                     !- Lower Limit Value",
        "    200,                     !- Upper Limit Value",
        "    CONTINUOUS,              !- Numeric Type",
        "    Temperature;             !- Unit Type",
        "  ScheduleTypeLimits,",
        "    Control Type,            !- Name",
        "    0,                       !- Lower Limit Value",
        "    4,                       !- Upper Limit Value",
        "    DISCRETE;                !- Numeric Type",
        "  ScheduleTypeLimits,",
        "    Fraction,                !- Name",
        "    0.0,                     !- Lower Limit Value",
        "    1.0,                     !- Upper Limit Value",
        "    CONTINUOUS;              !- Numeric Type",
        "  Schedule:Compact,",
        "    HVACAvailSched,          !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    1.0;                     !- Field 4",
        "  Schedule:Compact,",
        "    Dual Heating Setpoints,  !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    23.0;                    !- Field 4",
        "  Schedule:Compact,",
        "    Dual Cooling Setpoints,  !- Name",
        "    Temperature,             !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    23.0;                    !- Field 4",
        "  Schedule:Compact,",
        "    Dual Zone Control Type Sched,  !- Name",
        "    Control Type,            !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: AllDays,            !- Field 2",
        "    Until: 24:00,            !- Field 3",
        "    4;                       !- Field 4",
        "  Material,",
        "    Gypsum Board,            !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.0127,                  !- Thickness {m}",
        "    0.160158849,             !- Conductivity {W/m-K}",
        "    800.923168698,           !- Density {kg/m3}",
        "    1087.84,                 !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Gypsum Board Wall,       !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.0127,                  !- Thickness {m}",
        "    0.160158849,             !- Conductivity {W/m-K}",
        "    800.923168698,           !- Density {kg/m3}",
        "    1087.84,                 !- Specific Heat {J/kg-K}",
        "    1e-6,                    !- Thermal Absorptance",
        "    1e-6,                    !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    R-19 Insulation,         !- Name",
        "    Rough,                   !- Roughness",
        "    0.88871384,              !- Thickness {m}",
        "    0.25745056,              !- Conductivity {W/m-K}",
        "    3.05091836,              !- Density {kg/m3}",
        "    794.96,                  !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    R-A Lot,                 !- Name",
        "    Rough,                   !- Roughness",
        "    1.25,                    !- Thickness {m}",
        "    0.001,                   !- Conductivity {W/m-K}",
        "    3.05091836,              !- Density {kg/m3}",
        "    794.96,                  !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Shingles,                !- Name",
        "    Rough,                   !- Roughness",
        "    0.006348984,             !- Thickness {m}",
        "    0.081932979,             !- Conductivity {W/m-K}",
        "    1121.292436177,          !- Density {kg/m3}",
        "    1256.04,                 !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Felt,                    !- Name",
        "    Rough,                   !- Roughness",
        "    0.00216408,              !- Thickness {m}",
        "    0.081932979,             !- Conductivity {W/m-K}",
        "    1121.292436177,          !- Density {kg/m3}",
        "    1507.248,                !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Plywood,                 !- Name",
        "    Rough,                   !- Roughness",
        "    0.012701016,             !- Thickness {m}",
        "    0.11544,                 !- Conductivity {W/m-K}",
        "    544.627754714,           !- Density {kg/m3}",
        "    1214.172,                !- Specific Heat {J/kg-K}",
        "    0.9,                     !- Thermal Absorptance",
        "    0.9,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Hardboard Siding-Gable,  !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.0111125,               !- Thickness {m}",
        "    0.214957246,             !- Conductivity {W/m-K}",
        "    640.736,                 !- Density {kg/m3}",
        "    1172.304,                !- Specific Heat {J/kg-K}",
        "    0.90,                    !- Thermal Absorptance",
        "    0.7,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Studs,                   !- Name",
        "    Rough,                   !- Roughness",
        "    0.0003137,               !- Thickness {m}",
        "    0.02189835,              !- Conductivity {W/m-K}",
        "    448.516974471,           !- Density {kg/m3}",
        "    1632.852,                !- Specific Heat {J/kg-K}",
        "    0.90,                    !- Thermal Absorptance",
        "    0.7,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    Hardboard Siding-Eave,   !- Name",
        "    MediumSmooth,            !- Roughness",
        "    0.0111125,               !- Thickness {m}",
        "    0.214957246,             !- Conductivity {W/m-K}",
        "    640.736,                 !- Density {kg/m3}",
        "    1172.304,                !- Specific Heat {J/kg-K}",
        "    0.90,                    !- Thermal Absorptance",
        "    0.7,                     !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Material,",
        "    HF-C5,                   !- Name",
        "    MediumRough,             !- Roughness",
        "    0.1015000,               !- Thickness {m}",
        "    1.729600,                !- Conductivity {W/m-K}",
        "    2243.000,                !- Density {kg/m3}",
        "    837.0000,                !- Specific Heat {J/kg-K}",
        "    0.9000000,               !- Thermal Absorptance",
        "    0.6500000,               !- Solar Absorptance",
        "    1.0;                     !- Visible Absorptance",
        "  Construction,",
        "    CeilingConstruction,     !- Name",
        "    R-19 Insulation,         !- Outside Layer",
        "    Gypsum Board;            !- Layer 2",
        "  Construction,",
        "    Reverse:CeilingConstruction,  !- Name",
        "    Gypsum Board,            !- Outside Layer",
        "    R-19 Insulation;         !- Layer 2",
        "  Construction,",
        "    Roof,                    !- Name",
        "    Shingles,                !- Outside Layer",
        "    Felt,                    !- Layer 2",
        "    Plywood;                 !- Layer 3",
        "  Construction,",
        "    Gables,                  !- Name",
        "    Hardboard Siding-Eave;   !- Outside Layer",
        "  Construction,",
        "    Eave Walls,              !- Name",
        "    Hardboard Siding-Eave;   !- Outside Layer",
        "  Construction,",
        "    Walls,                   !- Name",
        "    Hardboard Siding-Eave,   !- Outside Layer",
        "    R-A Lot,                 !- Layer 2",
        "    Gypsum Board Wall;       !- Layer 3",
        "  Construction,",
        "    LTFLOOR,                 !- Name",
        "    HF-C5;                   !- Outside Layer",
        "  GlobalGeometryRules,",
        "    UpperLeftCorner,         !- Starting Vertex Position",
        "    Counterclockwise,        !- Vertex Entry Direction",
        "    World;                   !- Coordinate System",
        "  Zone,",
        "    OCCUPIED ZONE,           !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        "  Zone,",
        "    ATTIC ZONE,              !- Name",
        "    0,                       !- Direction of Relative North {deg}",
        "    0,                       !- X Origin {m}",
        "    0,                       !- Y Origin {m}",
        "    0,                       !- Z Origin {m}",
        "    1,                       !- Type",
        "    1,                       !- Multiplier",
        "    autocalculate,           !- Ceiling Height {m}",
        "    autocalculate;           !- Volume {m3}",
        "  BuildingSurface:Detailed,",
        "    North Wall,              !- Name",
        "    Wall,                    !- Surface Type",
        "    Walls,                   !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    0,                       !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    0,                       !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    North Wall Attic,        !- Name",
        "    Wall,                    !- Surface Type",
        "    Eave Walls,              !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.7254;                  !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    East Wall,               !- Name",
        "    Wall,                    !- Surface Type",
        "    Walls,                   !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    0,                       !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    0,                       !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    0,                       !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    East Wall Attic,         !- Name",
        "    Wall,                    !- Surface Type",
        "    Gables,              !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    5,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    0,                       !- Vertex 1 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 4 Z-coordinate {m}",
        "    16.764,                  !- Vertex 5 X-coordinate {m}",
        "    4.2672,                  !- Vertex 5 Y-coordinate {m}",
        "    4.5034;                  !- Vertex 5 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    South Wall,              !- Name",
        "    Wall,                    !- Surface Type",
        "    Walls,                   !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    0,                       !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    0,                       !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    0,                       !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    0,                       !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    South Wall Attic,        !- Name",
        "    Wall,                    !- Surface Type",
        "    Eave Walls,              !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    0,                       !- Vertex 1 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    0,                       !- Vertex 4 Y-coordinate {m}",
        "    2.7254;                  !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    West Wall,               !- Name",
        "    Wall,                    !- Surface Type",
        "    Walls,                   !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    0,                       !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    0,                       !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    0,                       !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    West Wall Attic,         !- Name",
        "    Wall,                    !- Surface Type",
        "    Gables,              !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0.50,                    !- View Factor to Ground",
        "    5,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    0,                       !- Vertex 4 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 4 Z-coordinate {m}",
        "    0,                       !- Vertex 5 X-coordinate {m}",
        "    4.2672,                  !- Vertex 5 Y-coordinate {m}",
        "    4.5034;                  !- Vertex 5 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    Zone Floor,              !- Name",
        "    Floor,                   !- Surface Type",
        "    LTFLOOR,                 !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Ground,                  !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    NoSun,                   !- Sun Exposure",
        "    NoWind,                  !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    0,                       !- Vertex 1 Y-coordinate {m}",
        "    0,                       !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    0,                       !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    0,                       !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    0,                       !- Vertex 4 Y-coordinate {m}",
        "    0;                       !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    Zone Ceiling,            !- Name",
        "    Ceiling,                 !- Surface Type",
        "    CeilingConstruction,     !- Construction Name",
        "    OCCUPIED ZONE,           !- Zone Name",
        "    ,                        !- Space Name",
        "    Surface,                 !- Outside Boundary Condition",
        "    Attic Floor,             !- Outside Boundary Condition Object",
        "    NoSun,                   !- Sun Exposure",
        "    NoWind,                  !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    Attic Floor,             !- Name",
        "    Floor,                   !- Surface Type",
        "    Reverse:CeilingConstruction,  !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Surface,                 !- Outside Boundary Condition",
        "    Zone Ceiling,            !- Outside Boundary Condition Object",
        "    NoSun,                   !- Sun Exposure",
        "    NoWind,                  !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    8.5344,                  !- Vertex 1 Y-coordinate {m}",
        "    2.70,                    !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    2.70,                    !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    2.70,                    !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    8.5344,                  !- Vertex 4 Y-coordinate {m}",
        "    2.70;                    !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    Attic Roof South,        !- Name",
        "    Roof,                    !- Surface Type",
        "    Roof,                    !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    0,                       !- Vertex 1 X-coordinate {m}",
        "    4.2672,                  !- Vertex 1 Y-coordinate {m}",
        "    4.5034,                  !- Vertex 1 Z-coordinate {m}",
        "    0,                       !- Vertex 2 X-coordinate {m}",
        "    0,                       !- Vertex 2 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 2 Z-coordinate {m}",
        "    16.764,                  !- Vertex 3 X-coordinate {m}",
        "    0,                       !- Vertex 3 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 3 Z-coordinate {m}",
        "    16.764,                  !- Vertex 4 X-coordinate {m}",
        "    4.2672,                  !- Vertex 4 Y-coordinate {m}",
        "    4.5034;                  !- Vertex 4 Z-coordinate {m}",
        "  BuildingSurface:Detailed,",
        "    Attic Roof North,        !- Name",
        "    Roof,                    !- Surface Type",
        "    Roof,                    !- Construction Name",
        "    ATTIC ZONE,              !- Zone Name",
        "    ,                        !- Space Name",
        "    Outdoors,                !- Outside Boundary Condition",
        "    ,                        !- Outside Boundary Condition Object",
        "    SunExposed,              !- Sun Exposure",
        "    WindExposed,             !- Wind Exposure",
        "    0,                       !- View Factor to Ground",
        "    4,                       !- Number of Vertices",
        "    16.764,                  !- Vertex 1 X-coordinate {m}",
        "    4.2672,                  !- Vertex 1 Y-coordinate {m}",
        "    4.5034,                  !- Vertex 1 Z-coordinate {m}",
        "    16.764,                  !- Vertex 2 X-coordinate {m}",
        "    8.5344,                  !- Vertex 2 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 2 Z-coordinate {m}",
        "    0,                       !- Vertex 3 X-coordinate {m}",
        "    8.5344,                  !- Vertex 3 Y-coordinate {m}",
        "    2.7254,                  !- Vertex 3 Z-coordinate {m}",
        "    0,                       !- Vertex 4 X-coordinate {m}",
        "    4.2672,                  !- Vertex 4 Y-coordinate {m}",
        "    4.5034;                  !- Vertex 4 Z-coordinate {m}",
        "  ZoneProperty:UserViewFactors:BySurfaceName,",
        "    ATTIC ZONE,              !- Zone Name",
        "    Attic Floor,		!=From Surface 1",
        "    Attic Floor,		!=To Surface 1",
        "    0.000000,",
        "    Attic Floor,		!=From Surface 1",
        "    Attic Roof South,		!=To Surface 2",
        "    0.476288,",
        "    Attic Floor,		!=From Surface 1",
        "    Attic Roof North,		!=To Surface 3",
        "    0.476288,",
        "    Attic Floor,		!=From Surface 1",
        "    East Wall Attic,		!=To Surface 4",
        "    0.023712,",
        "    Attic Floor,		!=From Surface 1",
        "    West Wall Attic,		!=To Surface 5",
        "    0.023712,",
        "    Attic Floor,		!=From Surface 1",
        "    North Wall Attic,		!=To Surface 6",
        "    0.000000,",
        "    Attic Floor,		!=From Surface 1",
        "    South Wall Attic,		!=To Surface 7",
        "    0.000000,",
        "    Attic Roof South,		!=From Surface 2",
        "    Attic Floor,		!=To Surface 1",
        "    0.879300,",
        "    Attic Roof South,		!=From Surface 2",
        "    Attic Roof South,		!=To Surface 2",
        "    0.000000,",
        "    Attic Roof South,		!=From Surface 2",
        "    Attic Roof North,		!=To Surface 3",
        "    0.067378,",
        "    Attic Roof South,		!=From Surface 2",
        "    East Wall Attic,		!=To Surface 4",
        "    0.026661,",
        "    Attic Roof South,		!=From Surface 2",
        "    West Wall Attic,		!=To Surface 5",
        "    0.026661,",
        "    Attic Roof South,		!=From Surface 2",
        "    North Wall Attic,		!=To Surface 6",
        "    0.000000,",
        "    Attic Roof South,		!=From Surface 2",
        "    South Wall Attic,		!=To Surface 7",
        "    0.000000,",
        "    Attic Roof North,		!=From Surface 3",
        "    Attic Floor,		!=To Surface 1",
        "    0.879300,",
        "    Attic Roof North,		!=From Surface 3",
        "    Attic Roof South,		!=To Surface 2