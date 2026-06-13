from testing import Test, Fixture, expect_true, expect_false, expect_eq, assert_true, assert_gt, expect_enum_eq, expect_double_eq
from EnergyPlus.CurveManager import *
from EnergyPlus.DataGenerators import CurveMode, SkinLoss, AirSupRateMode, RecoverMode, ConstituentMode, WaterTempMode, LossDestination, ExhaustGasHX, ElectricalStorage, InverterEfficiencyMode
from EnergyPlus.Plant.Loop import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, delimited_string, process_idf, has_err_output, state
from EnergyPlus.BranchInputManager import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.ElectricPowerServiceManager import GeneratorType, generatorTypeNamesUC
from EnergyPlus.FuelCellElectricGenerator import FCDataStruct
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.InternalHeatGains import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.Plant.PlantManager import *
from EnergyPlus.PlantUtilities import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import Simulate
from EnergyPlus.SizingManager import *

@fixture
struct EnergyPlusFixtureTest:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    def init_state(inout self):
        self.state.init_state(self.state)

    def run_test(inout self):
        # test body

def test_FuelCellTest(using self: EnergyPlusFixtureTest):
    var idf_objects: String = delimited_string({
        "Material,",
        "  8 in.Concrete Block Basement Wall,      !- Name",
        "  MediumRough,                            !- Roughness",
        "  0.2032,                                 !- Thickness{ m }",
        "  1.326,                                  !- Conductivity{ W / m - K }",
        "  1841.99999999999,                       !- Density{ kg / m3 }",
        "  911.999999999999,                       !- Specific Heat{ J / kg - K }",
        "  0.9,                                    !- Thermal Absorptance",
        "  0.7,                                    !- Solar Absorptance",
        "  0.7;                                    !- Visible Absorptance",
        "Construction,",
        "   Typical,   !- Name",
        "   8 in.Concrete Block Basement Wall;     !- Layer 1",
        "Zone,",
        "  Thermal Zone 1,                         !- Name",
        "  0,                                      !- Direction of Relative North {deg}",
        "  0,                                      !- X Origin {m}",
        "  0,                                      !- Y Origin {m}",
        "  0,                                      !- Z Origin {m}",
        "  ,                                       !- Type",
        "  1,                                      !- Multiplier",
        "  ,                                       !- Ceiling Height {m}",
        "  ,                                       !- Volume {m3}",
        "  ,                                       !- Floor Area {m2}",
        "  ,                                       !- Zone Inside Convection Algorithm",
        "  ,                                       !- Zone Outside Convection Algorithm",
        "  Yes;                                    !- Part of Total Floor Area",
        "BuildingSurface:Detailed,",
        "  Floor,                                  !- Name",
        "  Floor,                                  !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Ground,                                 !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  NoSun,                                  !- Sun Exposure",
        "  NoWind,                                 !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 0,                                !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  10, 10, 0,                              !- X,Y,Z Vertex 3 {m}",
        "  10, 0, 0;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Wall 1,                                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 10, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  0, 0, 0,                                !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3;                                !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Wall 2,                                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  10, 10, 3,                              !- X,Y,Z Vertex 1 {m}",
        "  10, 10, 0,                              !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 0,                               !- X,Y,Z Vertex 3 {m}",
        "  0, 10, 3;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Wall 3,                                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  10, 0, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  10, 0, 0,                               !- X,Y,Z Vertex 2 {m}",
        "  10, 10, 0,                              !- X,Y,Z Vertex 3 {m}",
        "  10, 10, 3;                              !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Wall 4,                                 !- Name",
        "  Wall,                                   !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  0, 0, 3,                                !- X,Y,Z Vertex 1 {m}",
        "  0, 0, 0,                                !- X,Y,Z Vertex 2 {m}",
        "  10, 0, 0,                               !- X,Y,Z Vertex 3 {m}",
        "  10, 0, 3;                               !- X,Y,Z Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        "  Roof,                                   !- Name",
        "  Roof,                                   !- Surface Type",
        "  Typical,                                !- Construction Name",
        "  Thermal Zone 1,                         !- Zone Name",
        "    ,                        !- Space Name",
        "  Outdoors,                               !- Outside Boundary Condition",
        "  ,                                       !- Outside Boundary Condition Object",
        "  SunExposed,                             !- Sun Exposure",
        "  WindExposed,                            !- Wind Exposure",
        "  ,                                       !- View Factor to Ground",
        "  ,                                       !- Number of Vertices",
        "  10, 0, 3,                               !- X,Y,Z Vertex 1 {m}",
        "  10, 10, 3,                              !- X,Y,Z Vertex 2 {m}",
        "  0, 10, 3,                               !- X,Y,Z Vertex 3 {m}",
        "  0, 0, 3;                                !- X,Y,Z Vertex 4 {m}",
        "ScheduleTypeLimits,",
        "  OnOff,                                  !- Name",
        "  0,                                      !- Lower Limit Value {BasedOnField A3}",
        "  1,                                      !- Upper Limit Value {BasedOnField A3}",
        "  Discrete,                               !- Numeric Type",
        "  availability;                           !- Unit Type",
        "ScheduleTypeLimits,",
        "  Temperature,                            !- Name",
        "  0,                                      !- Lower Limit Value {BasedOnField A3}",
        "  100,                                    !- Upper Limit Value {BasedOnField A3}",
        "  Continuous,                             !- Numeric Type",
        "  temperature;                            !- Unit Type",
        "Schedule:Constant,",
        "  Always On Discrete,                     !- Name",
        "  OnOff,                                  !- Schedule Type Limits Name",
        "  1;                                      !- Hourly Value",
        "Schedule:Constant,",
        "  Fuel Temperature,                       !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  20;                                     !- Hourly Value",
        "Schedule:Constant,",
        "  Hot_Water_Temperature,                  !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  55;                                     !- Hourly Value",
        "Schedule:Constant,",
        "  Water Temperature,                      !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  20;                                     !- Hourly Value",
        "Schedule:Constant,",
        "  Ambient Temperature 22C,                !- Name",
        "  Temperature,                            !- Schedule Type Limits Name",
        "  22;                                     !- Hourly Value",
        "OutdoorAir:Node,",
        "  Model Outdoor Air Node;                 !- Name",
        "PlantLoop,",
        "  SHW Loop,                               !- Name",
        "  Water,                                  !- Fluid Type",
        "  ,                                       !- User Defined Fluid Type",
        "  SHW Loop Operation Schemes,             !- Plant Equipment Operation Scheme Name",
        "  Node 3,                                 !- Loop Temperature Setpoint Node Name",
        "  100,                                    !- Maximum Loop Temperature {C}",
        "  0,                                      !- Minimum Loop Temperature {C}",
        "  Autosize,                               !- Maximum Loop Flow Rate {m3/s}",
        "  0,                                      !- Minimum Loop Flow Rate {m3/s}",
        "  Autocalculate,                          !- Plant Loop Volume {m3}",
        "  Node 2,                                 !- Plant Side Inlet Node Name",
        "  Node 3,                                 !- Plant Side Outlet Node Name",
        "  SHW Loop Supply Branches,               !- Plant Side Branch List Name",
        "  SHW Loop Supply Connector List,         !- Plant Side Connector List Name",
        "  Node 5,                                 !- Demand Side Inlet Node Name",
        "  Node 6,                                 !- Demand Side Outlet Node Name",
        "  SHW Loop Demand Branches,               !- Demand Side Branch List Name",
        "  SHW Loop Demand Connector List,         !- Demand Side Connector List Name",
        "  Optimal,                                !- Load Distribution Scheme",
        "  ,                                       !- Availability Manager List Name",
        "  SingleSetpoint,                         !- Plant Loop Demand Calculation Scheme",
        "  ;                                       !- Common Pipe Simulation",
        "Sizing:Plant,",
        "  SHW Loop,                               !- Plant or Condenser Loop Name",
        "  Heating,                                !- Loop Type",
        "  82,                                     !- Design Loop Exit Temperature {C}",
        "  11,                                     !- Loop Design Temperature Difference {deltaC}",
        "  NonCoincident,                          !- Sizing Option",
        "  1,                                      !- Zone Timesteps in Averaging Window",
        "  None;                                   !- Coincident Sizing Factor Mode",
        "BranchList,",
        "  SHW Loop Supply Branches,               !- Name",
        "  SHW Loop Supply Inlet Branch,           !- Branch Name 1",
        "  SHW Loop Supply Branch 2,               !- Branch Name 3",
        "  SHW Loop Supply Outlet Branch;          !- Branch Name 4",
        "ConnectorList,",
        "  SHW Loop Supply Connector List,         !- Name",
        "  Connector:Splitter,                     !- Connector Object Type 1",
        "  SHW Loop Supply Splitter,               !- Connector Name 1",
        "  Connector:Mixer,                        !- Connector Object Type 2",
        "  SHW Loop Supply Mixer;                  !- Connector Name 2",
        "Connector:Splitter,",
        "  SHW Loop Supply Splitter,               !- Name",
        "  SHW Loop Supply Inlet Branch,           !- Inlet Branch Name",
        "  SHW Loop Supply Branch 2;               !- Outlet Branch Name 2",
        "Connector:Mixer,",
        "  SHW Loop Supply Mixer,                  !- Name",
        "  SHW Loop Supply Outlet Branch,          !- Outlet Branch Name",
        "  SHW Loop Supply Branch 2;               !- Inlet Branch Name 2",
        "Branch,",
        "  SHW Loop Supply Inlet Branch,           !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Pump:ConstantSpeed,                     !- Component Object Type 1",
        "  Pump Constant Speed 1,                  !- Component Name 1",
        "  Node 2,                                 !- Component Inlet Node Name 1",
        "  Node 8;                                 !- Component Outlet Node Name 1",
        "Pump:ConstantSpeed,",
        "  Pump Constant Speed 1,                  !- Name",
        "  Node 2,                                 !- Inlet Node Name",
        "  Node 8,                                 !- Outlet Node Name",
        "  Autosize,                               !- Design Flow Rate {m3/s}",
        "  179352,                                 !- Design Pump Head {Pa}",
        "  Autosize,                               !- Design Power Consumption {W}",
        "  0.9,                                    !- Motor Efficiency",
        "  0,                                      !- Fraction of Motor Inefficiencies to Fluid Stream",
        "  Intermittent,                           !- Pump Control Type",
        "  ,                                       !- Pump Flow Rate Schedule Name",
        "  ,                                       !- Pump Curve Name",
        "  ,                                       !- Impeller Diameter {m}",
        "  ,                                       !- Rotational Speed {rev/min}",
        "  ,                                       !- Zone Name",
        "  ,                                       !- Skin Loss Radiative Fraction",
        "  PowerPerFlowPerPressure,                !- Design Power Sizing Method",
        "  348701.1,                               !- Design Electric Power per Unit Flow Rate {W/(m3/s)}",
        "  1.282051282,                            !- Design Shaft Power per Unit Flow Rate per Unit Head {W-s/m3-Pa}",
        "  General;                                !- End-Use Subcategory",
        "Branch,",
        "  SHW Loop Supply Branch 2,           !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Generator:FuelCell:ExhaustGasToWaterHeatExchanger, !- Component Object Type 1",
        "  Generator Fuel Cell Exhaust Gas To Water Heat Exchanger 1, !- Component Name 1",
        "  Node 10,                                !- Component Inlet Node Name 1",
        "  Node 11;                                !- Component Outlet Node Name 1",
        "Generator:FuelCell:ExhaustGasToWaterHeatExchanger,",
        "  Generator Fuel Cell Exhaust Gas To Water Heat Exchanger 1, !- Name",
        "  Node 10,                                !- Heat Recovery Water Inlet Node Name",
        "  Node 11,                                !- Heat Recovery Water Outlet Node Name",
        "  0.0004,                                 !- Heat Recovery Water Maximum Flow Rate {m3/s}",
        "  Generator Fuel Cell Exhaust Gas To Water Heat Exchanger 1 Exhaust Outlet Air Node, !- Exhaust Outlet Air Node Name",
        "  Condensing,                             !- Heat Exchanger Calculation Method",
        "  ,                                       !- Method 1 Heat Exchanger Effectiveness",
        "  83.1,                                   !- Method 2 Parameter hxs0",
        "  4798,                                   !- Method 2 Parameter hxs1",
        "  -138000,                                !- Method 2 Parameter hxs2",
        "  -353800,                                !- Method 2 Parameter hxs3",
        "  515000000,                              !- Method 2 Parameter hxs4",
        "  ,                                       !- Method 3 h0Gas Coefficient",
        "  ,                                       !- Method 3 NdotGasRef Coefficient",
        "  ,                                       !- Method 3 n Coefficient",
        "  ,                                       !- Method 3 Gas Area {m2}",
        "  ,                                       !- Method 3 h0 Water Coefficient",
        "  ,                                       !- Method 3 N dot Water ref Coefficient",
        "  ,                                       !- Method 3 m Coefficient",
        "  ,                                       !- Method 3 Water Area {m2}",
        "  ,                                       !- Method 3 F Adjustment Factor",
        "  0.0031,                                 !- Method 4 hxl1 Coefficient",
        "  1,                                      !- Method 4 hxl2 Coefficient",
        "  35;                                     !- Method 4 Condensation Threshold {C}",
        "Generator:FuelCell,",
        "  Generator Fuel Cell 1,                  !- Name",
        "  Generator Fuel Cell Power Module 1,     !- Power Module Name",
        "  Generator Fuel Cell Air Supply 1,       !- Air Supply Name",
        "  NATURALGAS,                             !- Fuel Supply Name",
        "  Generator Fuel Cell Water Supply 1,     !- Water Supply Name",
        "  Generator Fuel Cell Auxiliary Heater 1, !- Auxiliary Heater Name",
        "  Generator Fuel Cell Exhaust Gas To Water Heat Exchanger 1, !- Heat Exchanger Name",
        "  Generator Fuel Cell Electrical Storage 1, !- Electrical Storage Name",
        "  Generator Fuel Cell Inverter 1;         !- Inverter Name",
        "Generator:FuelCell:PowerModule,",
        "  Generator Fuel Cell Power Module 1,     !- Name",
        "  Annex42,                                !- Efficiency Curve Mode",
        "  Power Module Efficiency Curve,          !- Efficiency Curve Name",
        "  1,                                      !- Nominal Efficiency",
        "  3400,                                   !- Nominal Electrical Power {W}",
        "  10,                                     !- Number of Stops at Start of Simulation",
        "  0,                                      !- Cycling Performance Degradation Coefficient",
        "  0,                                      !- Number of Run Hours at Beginning of Simulation {hr}",
        "  0,                                      !- Accumulated Run Time Degradation Coefficient",
        "  10000,                                  !- Run Time Degradation Initiation Time Threshold {hr}",
        "  1.4,                                    !- Power Up Transient Limit {W/s}",
        "  0.2,                                    !- Power Down Transient Limit {W/s}",
        "  0,                                      !- Start Up Time {s}",
        "  0.2,                                    !- Start Up Fuel {kmol}",
        "  0,                                      !- Start Up Electricity Consumption {J}",
        "  0,                                      !- Start Up Electricity Produced {J}",
        "  0,                                      !- Shut Down Time {s}",
        "  0.2,                                    !- Shut Down Fuel {kmol}",
        "  0,                                      !- Shut Down Electricity Consumption {J}",
        "  0,                                      !- Ancillary Electricity Constant Term",
        "  0,                                      !- Ancillary Electricity Linear Term",
        "  ConstantRate,                           !- Skin Loss Calculation Mode",
        "  Thermal Zone 1,                         !- Zone Name",
        "  0.6392,                                 !- Skin Loss Radiative Fraction",
        "  729,                                    !- Constant Skin Loss Rate {W}",
        "  0,                                      !- Skin Loss U-Factor Times Area Term {W/K}",
        "  Skin Loss Curve,                        !- Skin Loss Quadratic Curve Name",
        "  0.006156,                               !- Dilution Air Flow Rate {kmol/s}",
        "  2307,                                   !- Stack Heat loss to Dilution Air {W}",
        "  Generator Fuel Cell Power Module 1 OA Node, !- Dilution Inlet Air Node Name",
        "  Generator Fuel Cell Power Module 1 Dilution Outlet Air Node, !- Dilution Outlet Air Node Name",
        "  3010,                                   !- Minimum Operating Point {W}",
        "  3728;                                   !- Maximum Operating Point {W}",
        "OutdoorAir:NodeList,",
        "  Generator Fuel Cell Power Module 1 OA Node; !- Node or NodeList Name 1",
        "Generator:FuelCell:AirSupply,",
        "  Generator Fuel Cell Air Supply 1,       !- Name",
        "  Generator Fuel Cell Air Supply 1 OA Node, !- Air Inlet Node Name",
        "  Blower Power Curve,                     !- Blower Power Curve Name",
        "  1,                                      !- Blower Heat Loss Factor",
        "  AirRatiobyStoics,                       !- Air Supply Rate Calculation Mode",
        "  1,                                      !- Stoichiometric Ratio",
        "  Air Rate Function of Electric Power Curve, !- Air Rate Function of Electric Power Curve Name",
        "  0.00283,                                !- Air Rate Air Temperature Coefficient",
        "  ,                                       !- Air Rate Function of Fuel Rate Curve Name",
        "  NoRecovery,                             !- Air Intake Heat Recovery Mode",
        "  AmbientAir,                             !- Air Supply Constituent Mode",
        "  0;                                      !- Number of UserDefined Constituents",
        "OutdoorAir:NodeList,",
        "  Generator Fuel Cell Air Supply 1 OA Node; !- Node or NodeList Name 1",
        "Generator:FuelSupply,",
        "  NATURALGAS,                             !- Name",
        "  Scheduled,                              !- Fuel Temperature Modeling Mode",
        "  ,                                       !- Fuel Temperature Reference Node Name",
        "  Fuel Temperature,                       !- Fuel Temperature Schedule Name",
        "  Compressor Power Multiplier Function of FuelRate Curve, !- Compressor Power Multiplier Function of Fuel Rate Curve Name",
        "  1,                                      !- Compressor Heat Loss Factor",
        "  GaseousConstituents,                    !- Fuel Type",
        "  ,                                       !- Liquid Generic Fuel Lower Heating Value {kJ/kg}",
        "  ,                                       !- Liquid Generic Fuel Higher Heating Value {kJ/kg}",
        "  ,                                       !- Liquid Generic Fuel Molecular Weight {g/mol}",
        "  ,                                       !- Liquid Generic Fuel CO2 Emission Factor",
        "  8,                                      !- Number of Constituents in Gaseous Constituent Fuel Supply",
        "  METHANE,                                !- Constituent Name 1",
        "  0.949,                                  !- Constituent Molar Fraction 1",
        "  CarbonDioxide,                          !- Constituent Name 2",
        "  0.007,                                  !- Constituent Molar Fraction 2",
        "  NITROGEN,                               !- Constituent Name 3",
        "  0.016,                                  !- Constituent Molar Fraction 3",
        "  ETHANE,                                 !- Constituent Name 4",
        "  0.025,                                  !- Constituent Molar Fraction 4",
        "  PROPANE,                                !- Constituent Name 5",
        "  0.002,                                  !- Constituent Molar Fraction 5",
        "  BUTANE,                                 !- Constituent Name 6",
        "  0.0006,                                 !- Constituent Molar Fraction 6",
        "  PENTANE,                                !- Constituent Name 7",
        "  0.0002,                                 !- Constituent Molar Fraction 7",
        "  OXYGEN,                                 !- Constituent Name 8",
        "  0.0002;                                 !- Constituent Molar Fraction 8",
        "Generator:FuelCell:WaterSupply,",
        "  Generator Fuel Cell Water Supply 1,     !- Name",
        "  Reformer Water FlowRate Function of FuelRate Curve, !- Reformer Water Flow Rate Function of Fuel Rate Curve Name",
        "  Reformer Water Pump Power Function of FuelRate Curve, !- Reformer Water Pump Power Function of Fuel Rate Curve Name",
        "  0,                                      !- Pump Heat Loss Factor",
        "  TemperatureFromSchedule,                !- Water Temperature Modeling Mode",
        "  ,                                       !- Water Temperature Reference Node Name",
        "  Water Temperature;                      !- Water Temperature Schedule Name",
        "Generator:FuelCell:AuxiliaryHeater,",
        "  Generator Fuel Cell Auxiliary Heater 1, !- Name",
        "  0,                                      !- Excess Air Ratio",
        "  0,                                      !- Ancillary Power Constant Term",
        "  0,                                      !- Ancillary Power Linear Term",
        "  0.5,                                    !- Skin Loss U-Factor Times Area Value {W/K}",
        "  AirInletForFuelCell,                    !- Skin Loss Destination",
        "  ,                                       !- Zone Name to Receive Skin Losses",
        "  Watts,                                  !- Heating Capacity Units",
        "  0,                                      !- Maximum Heating Capacity in Watts {W}",
        "  0,                                      !- Minimum Heating Capacity in Watts {W}",
        "  0,                                      !- Maximum Heating Capacity in Kmol per Second {kmol/s}",
        "  0;                                      !- Minimum Heating Capacity in Kmol per Second {kmol/s}",
        "Generator:FuelCell:ElectricalStorage,",
        "  Generator Fuel Cell Electrical Storage 1, !- Name",
        "  SimpleEfficiencyWithConstraints,        !- Choice of Model",
        "  1,                                      !- Nominal Charging Energetic Efficiency",
        "  1,                                      !- Nominal Discharging Energetic Efficiency",
        "  0,                                      !- Simple Maximum Capacity {J}",
        "  0,                                      !- Simple Maximum Power Draw {W}",
        "  0,                                      !- Simple Maximum Power Store {W}",
        "  0;                                      !- Initial Charge State {J}",
        "Generator:FuelCell:Inverter,",
        "  Generator Fuel Cell Inverter 1,         !- Name",
        "  Constant,                               !- Inverter Efficiency Calculation Mode",
        "  1,                                      !- Inverter Efficiency",
        "  Efficiency Function of DC Power Curve;  !- Efficiency Function of DC Power Curve Name",
        "Curve:Cubic,",
        "  Blower Power Curve,                     !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0,                                      !- Coefficient4 x**3",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Cubic,",
        "  Compressor Power Multiplier Function of FuelRate Curve, !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0,                                      !- Coefficient4 x**3",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Cubic,",
        "  Reformer Water Pump Power Function of FuelRate Curve, !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  0,                                      !- Coefficient4 x**3",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Air Rate Function of Electric Power Curve, !- Name",
        "  0.00150976,                             !- Coefficient1 Constant",
        "  -7.76656e-07,                           !- Coefficient2 x",
        "  1.30317e-10,                            !- Coefficient3 x**2",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Air Rate Function of Fuel Rate Curve,   !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Efficiency Function of DC Power Curve,  !- Name",
        "  0.560717,                               !- Coefficient1 Constant",
        "  0.00012401,                             !- Coefficient2 x",
        "  -2.01648e-08,                           !- Coefficient3 x**2",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Power Module Efficiency Curve,          !- Name",
        "  0.642388,                               !- Coefficient1 Constant",
        "  -0.0001619,                             !- Coefficient2 x",
        "  2.26e-08,                               !- Coefficient3 x**2",
        "  0,                                      !- Minimum Value of x {BasedOnField A2}",
        "  10000;                                  !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Reformer Water FlowRate Function of FuelRate Curve, !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Curve:Quadratic,",
        "  Skin Loss Curve,                        !- Name",
        "  0,                                      !- Coefficient1 Constant",
        "  0,                                      !- Coefficient2 x",
        "  0,                                      !- Coefficient3 x**2",
        "  -10000000000,                           !- Minimum Value of x {BasedOnField A2}",
        "  10000000000;                            !- Maximum Value of x {BasedOnField A2}",
        "Branch,",
        "  SHW Loop Supply Outlet Branch,          !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Pipe:Adiabatic,                         !- Component Object Type 1",
        "  SHW Loop Supply Outlet Pipe,            !- Component Name 1",
        "  SHW Loop Supply Outlet Pipe Node,       !- Component Inlet Node Name 1",
        "  Node 3;                                 !- Component Outlet Node Name 1",
        "Pipe:Adiabatic,",
        "  SHW Loop Supply Outlet Pipe,            !- Name",
        "  SHW Loop Supply Outlet Pipe Node,       !- Inlet Node Name",
        "  Node 3;                                 !- Outlet Node Name",
        "BranchList,",
        "  SHW Loop Demand Branches,               !- Name",
        "  SHW Loop Demand Inlet Branch,           !- Branch Name 1",
        "  SHW Loop Demand Branch 1,               !- Branch Name 2",
        "  SHW Loop Demand Bypass Branch,          !- Branch Name 3",
        "  SHW Loop Demand Outlet Branch;          !- Branch Name 4",
        "ConnectorList,",
        "  SHW Loop Demand Connector List,         !- Name",
        "  Connector:Splitter,                     !- Connector Object Type 1",
        "  SHW Loop Demand Splitter,               !- Connector Name 1",
        "  Connector:Mixer,                        !- Connector Object Type 2",
        "  SHW Loop Demand Mixer;                  !- Connector Name 2",
        "Connector:Splitter,",
        "  SHW Loop Demand Splitter,               !- Name",
        "  SHW Loop Demand Inlet Branch,           !- Inlet Branch Name",
        "  SHW Loop Demand Branch 1,               !- Outlet Branch Name 1",
        "  SHW Loop Demand Bypass Branch;          !- Outlet Branch Name 2",
        "Connector:Mixer,",
        "  SHW Loop Demand Mixer,                  !- Name",
        "  SHW Loop Demand Outlet Branch,          !- Outlet Branch Name",
        "  SHW Loop Demand Branch 1,               !- Inlet Branch Name 1",
        "  SHW Loop Demand Bypass Branch;          !- Inlet Branch Name 2",
        "Branch,",
        "  SHW Loop Demand Inlet Branch,           !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Pipe:Adiabatic,                         !- Component Object Type 1",
        "  SHW Loop Demand Inlet Pipe,             !- Component Name 1",
        "  Node 5,                                 !- Component Inlet Node Name 1",
        "  SHW Loop Demand Inlet Pipe Node;        !- Component Outlet Node Name 1",
        "Pipe:Adiabatic,",
        "  SHW Loop Demand Inlet Pipe,             !- Name",
        "  Node 5,                                 !- Inlet Node Name",
        "  SHW Loop Demand Inlet Pipe Node;        !- Outlet Node Name",
        "Branch,",
        "  SHW Loop Demand Branch 1,               !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  WaterUse:Connections,                   !- Component Object Type 1",
        "  Water Use Connections 1,                !- Component Name 1",
        "  Node 7,                                 !- Component Inlet Node Name 1",
        "  Node 12;                                !- Component Outlet Node Name 1",
        "WaterUse:Connections,",
        "  Water Use Connections 1,                !- Name",
        "  Node 7,                                 !- Inlet Node Name",
        "  Node 12,                                !- Outlet Node Name",
        "  ,                                       !- Supply Water Storage Tank Name",
        "  ,                                       !- Reclamation Water Storage Tank Name",
        "  ,                                       !- Hot Water Supply Temperature Schedule Name",
        "  ,                                       !- Cold Water Supply Temperature Schedule Name",
        "  None,                                   !- Drain Water Heat Exchanger Type",
        "  Plant,                                  !- Drain Water Heat Exchanger Destination",
        "  ,                                       !- Drain Water Heat Exchanger U-Factor Times Area {W/K}",
        "  Water Use Equipment 1;                  !- Water Use Equipment Name 1",
        "WaterUse:Equipment,",
        "  Water Use Equipment 1,                  !- Name",
        "  General,                                !- End-Use Subcategory",
        "  1.0,                                    !- Peak Flow Rate {m3/s}",
        "  Always On Discrete,                     !- Flow Rate Fraction Schedule Name",
        "  Hot_Water_Temperature;                  !- Target Temperature Schedule Name",
        "Branch,",
        "  SHW Loop Demand Bypass Branch,          !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Pipe:Adiabatic,                         !- Component Object Type 1",
        "  SHW Loop Demand Bypass Pipe,            !- Component Name 1",
        "  SHW Loop Demand Bypass Pipe Inlet Node, !- Component Inlet Node Name 1",
        "  SHW Loop Demand Bypass Pipe Outlet Node; !- Component Outlet Node Name 1",
        "Pipe:Adiabatic,",
        "  SHW Loop Demand Bypass Pipe,            !- Name",
        "  SHW Loop Demand Bypass Pipe Inlet Node, !- Inlet Node Name",
        "  SHW Loop Demand Bypass Pipe Outlet Node; !- Outlet Node Name",
        "Branch,",
        "  SHW Loop Demand Outlet Branch,          !- Name",
        "  ,                                       !- Pressure Drop Curve Name",
        "  Pipe:Adiabatic,                         !- Component Object Type 1",
        "  SHW Loop Demand Outlet Pipe,            !- Component Name 1",
        "  SHW Loop Demand Outlet Pipe Node,       !- Component Inlet Node Name 1",
        "  Node 6;                                 !- Component Outlet Node Name 1",
        "Pipe:Adiabatic,",
        "  SHW Loop Demand Outlet Pipe,            !- Name",
        "  SHW Loop Demand Outlet Pipe Node,       !- Inlet Node Name",
        "  Node 6;                                 !- Outlet Node Name",
        "PlantEquipmentOperationSchemes,",
        "  SHW Loop Operation Schemes,             !- Name",
        "  PlantEquipmentOperation:HeatingLoad,    !- Control Scheme Object Type 1",
        "  SHW Loop Heating Operation Scheme,      !- Control Scheme Name 1",
        "  Always On Discrete;                     !- Control Scheme Schedule Name 1",
        "PlantEquipmentOperation:HeatingLoad,",
        "  SHW Loop Heating Operation Scheme,      !- Name",
        "  0,                                      !- Load Range Lower Limit 1 {W}",
        "  1000000000,                             !- Load Range Upper Limit 1 {W}",
        "  SHW Loop Heating Equipment List;        !- Range Equipment List Name 1",
        "PlantEquipmentList,",
        "  SHW Loop Heating Equipment List,        !- Name",
        "  Generator:FuelCell:ExhaustGasToWaterHeatExchanger, !- Equipment Object Type 1",
        "  Generator Fuel Cell Exhaust Gas To Water Heat Exchanger 1; !- Equipment Name 1",
        "SetpointManager:Scheduled,",
        "  SHW LWT SPM,                            !- Name",
        "  Temperature,                            !- Control Variable",
        "  Hot_Water_Temperature,                  !- Schedule Name",
        "  Node 3;                                 !- Setpoint Node or NodeList Name",
        "ElectricLoadCenter:Distribution,",
        "  Electric Load Center Distribution 1,    !- Name",
        "  Electric Load Center Distribution 1 Generators, !- Generator List Name",
        "  Baseload,                               !- Generator Operation Scheme Type",
        "  ,                                       !- Generator Demand Limit Scheme Purchased Electric Demand Limit {W}",
        "  ,                                       !- Generator Track Schedule Name Scheme Schedule Name",
        "  ,                                       !- Generator Track Meter Scheme Meter Name",
        "  AlternatingCurrent;                     !- Electrical Buss Type",
        "ElectricLoadCenter:Generators,",
        "  Electric Load Center Distribution 1 Generators, !- Name",
        "  Generator Fuel Cell 1,                  !- Generator Name 1",
        "  Generator:FuelCell,                     !- Generator Object Type 1",
        "  3400,                                   !- Generator Rated Electric Power Output 1 {W}",
        "  Always On Discrete,                     !- Generator Availability Schedule Name 1",
        "  ;                                       !- Generator Rated Thermal to Electrical Power Ratio 1",
        "Exterior:Lights,",
        "  Exterior Facade Lighting,!- Name",
        "  Always On Discrete,      !- Schedule Name",
        "  10000.00,                 !- Design Level {W}",
        "  ScheduleNameOnly,        !- Control Option",
        "  Exterior Facade Lighting;!- End-Use Subcategory",
        "  SimulationControl,",
        "    No,                      !- Do Zone Sizing Calculation",
        "    No,                      !- Do System Sizing Calculation",
        "    Yes,                     !- Do Plant Sizing Calculation",
        "    Yes,                     !- Run Simulation for Sizing Periods",
        "    No;                      !- Run Simulation for Weather File Run Periods",
        "  Site:Location,",
        "    CHICAGO_IL_USA TMY2-94846,  !- Name",
        "    41.78,                   !- Latitude {deg}",
        "    -87.75,                  !- Longitude {deg}",
        "    -6.00,                   !- Time Zone {hr}",
        "    190.00;                  !- Elevation {m}",
        "  SizingPeriod:DesignDay,",
        "    CHICAGO_IL_USA Annual Heating 99% Design Conditions DB,  !- Name",
        "    1,                       !- Month",
        "    21,                      !- Day of Month",
        "    WinterDesignDay,         !- Day Type",
        "    -17.3,                   !- Maximum Dry-Bulb Temperature {C}",
        "    0.0,                     !- Daily Dry-Bulb Temperature Range {deltaC}",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Type",
        "    ,                        !- Dry-Bulb Temperature Range Modifier Day Schedule Name",
        "    Wetbulb,                 !- Humidity Condition Type",
        "    -17.3,                   !- Wetbulb or DewPoint at Maximum Dry-Bulb {C}",
        "    ,                        !- Humidity Condition Day Schedule Name",
        "    ,                        !- Humidity Ratio at Maximum Dry-Bulb {kgWater/kgDryAir}",
        "    ,                        !- Enthalpy at Maximum Dry-Bulb {J/kg}",
        "    ,                        !- Daily Wet-Bulb Temperature Range {deltaC}",
        "    99063.,                  !- Barometric Pressure {Pa}",
        "    4.9,                     !- Wind Speed {m/s}",
        "    270,                     !- Wind Direction {deg}",
        "    No,                      !- Rain Indicator",
        "    No,                      !- Snow Indicator",
        "    No,                      !- Daylight Saving Time Indicator",
        "    ASHRAEClearSky,          !- Solar Model Indicator",
        "    ,                        !- Beam Solar Day Schedule Name",
        "    ,                        !- Diffuse Solar Day Schedule Name",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Beam Irradiance (taub) {dimensionless}",
        "    ,                        !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance (taud) {dimensionless}",
        "    1.0;                     !- Sky Clearness",
        "Timestep,4;",
        "Output:SQLite,",
        "  SimpleAndTabular;                       !- Option Type",
        "Output:Meter,",
        "  NaturalGas:Facility,                    !- Key Name",
        "  Timestep;                               !- Reporting Frequency",
    })
    assert_true(process_idf(idf_objects))
    expect_false(has_err_output())
    self.state.init_state(self.state)
    SimulationManager.ManageSimulation(self.state)
    expect_true(has_err_output(true))
    var generatorController = self.state.dataElectPwrSvcMgr.facilityElectricServiceObj.elecLoadCenterObjs[0].elecGenCntrlObj[0]
    expect_enum_eq(GeneratorType.FuelCell, generatorController.generatorType)
    expect_eq("GENERATOR FUEL CELL 1", generatorController.name)
    expect_eq("GENERATOR:FUELCELL", generatorTypeNamesUC[Int(generatorController.generatorType)])
    expect_enum_eq(DataPlant.PlantEquipmentType.Generator_FCExhaust, generatorController.compPlantType)
    expect_eq("GENERATOR FUEL CELL EXHAUST GAS TO WATER HEAT EXCHANGER 1", generatorController.compPlantName)
    expect_eq(0, generatorController.generatorIndex)
    expect_eq("ALWAYS ON DISCRETE", generatorController.availSched.Name)
    expect_eq(0, generatorController.nominalThermElectRatio)
    expect_true(generatorController.onThisTimestep)
    expect_eq(3400.0, generatorController.maxPowerOut)
    expect_eq(3400.0, generatorController.powerRequestThisTimestep)
    expect_eq(3400.0, generatorController.electProdRate)
    expect_eq(3400.0 * 15 * 60, generatorController.electricityProd) # Timestep = 4, so 15min
    expect_eq(0, generatorController.dCElectricityProd)
    expect_eq(0, generatorController.dCElectProdRate)
    var thisFCcompPtr = FCDataStruct.factory(self.state, generatorController.name)
    var thisFC = FCDataStruct(thisFCcompPtr)
    expect_eq("GENERATOR FUEL CELL POWER MODULE 1", thisFC.NameFCPM)
    var fCPM = thisFC.FCPM
    expect_eq(fCPM.Name, thisFC.NameFCPM)
    expect_enum_eq(DataGenerators.CurveMode.Direct, fCPM.EffMode)
    assert_gt(fCPM.EffCurve.Num, 0)
    expect_eq("POWER MODULE EFFICIENCY CURVE", fCPM.EffCurve.Name)
    expect_eq(1.0, fCPM.NomEff)
    expect_eq(3400.0, fCPM.NomPel)
    expect_eq(10, fCPM.NumCycles)
    expect_eq(0.0, fCPM.CyclingDegradRat)
    expect_eq(1.0, fCPM.NomEff)
    expect_eq(3400.0, fCPM.NomPel)
    expect_eq(0.0, fCPM.CyclingDegradRat)
    expect_eq(0.0, fCPM.NumRunHours)
    expect_eq(0.0, fCPM.OperateDegradRat)
    expect_eq(10000.0, fCPM.ThreshRunHours)
    expect_eq(1.4, fCPM.UpTranLimit)
    expect_eq(0.2, fCPM.DownTranLimit)
    expect_eq(0.0, fCPM.StartUpTime)
    expect_eq(0.2, fCPM.StartUpFuel)
    expect_eq(0.0, fCPM.StartUpElectConsum)
    expect_eq(0.0, fCPM.StartUpElectProd)
    expect_eq(0.0, fCPM.ShutDownTime)
    expect_eq(0.2, fCPM.ShutDownFuel)
    expect_eq(0.0, fCPM.ShutDownElectConsum)
    expect_eq(0.0, fCPM.ANC0)
    expect_eq(0.0, fCPM.ANC1)
    expect_enum_eq(DataGenerators.SkinLoss.ConstantRate, fCPM.SkinLossMode)
    expect_eq("THERMAL ZONE 1", fCPM.ZoneName)
    expect_eq(1, fCPM.ZoneID)
    expect_eq(0.6392, fCPM.RadiativeFract)
    expect_eq(729, fCPM.QdotSkin)
    expect_eq(0.0, fCPM.UAskin)
    assert_gt(fCPM.SkinLossCurve.Num, 0)
    expect_eq(0.006156, fCPM.NdotDilutionAir)
    expect_eq(2307, fCPM.StackHeatLossToDilution)
    expect_eq("GENERATOR FUEL CELL POWER MODULE 1 OA NODE", fCPM.DilutionInletNodeName)
    expect_eq("GENERATOR FUEL CELL POWER MODULE 1 DILUTION OUTLET AIR NODE", fCPM.DilutionExhaustNodeName)
    expect_eq(3010, fCPM.PelMin)
    expect_eq(3728, fCPM.PelMax)
    expect_eq("GENERATOR FUEL CELL AIR SUPPLY 1", thisFC.NameFCAirSup)
    var airSup = thisFC.AirSup
    expect_eq(airSup.Name, thisFC.NameFCAirSup)
    expect_eq("GENERATOR FUEL CELL AIR SUPPLY 1 OA NODE", airSup.NodeName)
    assert_gt(airSup.BlowerPowerCurve.Num, 0)
    expect_eq("BLOWER POWER CURVE", airSup.BlowerPowerCurve.Name)
    expect_eq(1.0, airSup.BlowerHeatLossFactor)
    expect_enum_eq(DataGenerators.AirSupRateMode.ConstantStoicsAirRat, airSup.AirSupRateMode)
    expect_eq(2.0, airSup.Stoics)
    assert_gt(airSup.AirFuncPelCurve.Num, 0)
    expect_eq("AIR RATE FUNCTION OF ELECTRIC POWER CURVE", airSup.AirFuncPelCurve.Name)
    expect_eq(0.00283, airSup.AirTempCoeff)
    expect_eq(None, airSup.AirFuncNdotCurve)
    expect_enum_eq(DataGenerators.RecoverMode.NoRecoveryOnAirIntake, airSup.IntakeRecoveryMode)
    expect_enum_eq(DataGenerators.ConstituentMode.RegularAir, airSup.ConstituentMode)
    expect_eq(5, airSup.NumConstituents)
    expect_eq("NATURALGAS", thisFC.NameFCFuelSup)
    expect_eq("GENERATOR FUEL CELL WATER SUPPLY 1", thisFC.NameFCWaterSup)
    var waterSup = thisFC.WaterSup
    expect_eq(waterSup.Name, thisFC.NameFCWaterSup)
    assert_gt(waterSup.WaterSupRateCurve.Num, 0)
    expect_eq("REFORMER WATER FLOWRATE FUNCTION OF FUELRATE CURVE", waterSup.WaterSupRateCurve.Name)
    assert_gt(waterSup.PmpPowerCurve.Num, 0)
    expect_eq("REFORMER WATER PUMP POWER FUNCTION OF FUELRATE CURVE", waterSup.PmpPowerCurve.Name)
    expect_eq(0.0, waterSup.PmpPowerLossFactor)
    expect_eq(0, waterSup.NodeNum)
    expect_enum_eq(DataGenerators.WaterTempMode.Schedule, waterSup.waterTempMode)
    assert_ne(waterSup.sched, None)
    expect_eq("GENERATOR FUEL CELL AUXILIARY HEATER 1", thisFC.NameFCAuxilHeat)
    var auxilHeat = thisFC.AuxilHeat
    expect_eq(auxilHeat.Name, thisFC.NameFCAuxilHeat)
    expect_eq(0.0, auxilHeat.ExcessAirRAT)
    expect_eq(0.0, auxilHeat.ANC0)
    expect_eq(0.0, auxilHeat.ANC1)
    expect_eq(0.5, auxilHeat.UASkin)
    expect_enum_eq(DataGenerators.LossDestination.AirInletForFC, auxilHeat.SkinLossDestination)
    expect_eq(0, auxilHeat.ZoneID)
    expect_true(auxilHeat.ZoneName.empty())
    expect_eq(0.0, auxilHeat.MaxPowerW)
    expect_eq(0.0, auxilHeat.MinPowerW)
    expect_eq(0.0, auxilHeat.MaxPowerkmolperSec)
    expect_eq(0.0, auxilHeat.MinPowerkmolperSec)
    expect_eq("GENERATOR FUEL CELL EXHAUST GAS TO WATER HEAT EXCHANGER 1", thisFC.NameExhaustHX)
    var exhaustHX = thisFC.ExhaustHX
    expect_eq(exhaustHX.Name, thisFC.NameExhaustHX)
    expect_eq("NODE 10", exhaustHX.WaterInNodeName)
    assert_gt(exhaustHX.WaterInNode, 0)
    expect_eq("NODE 11", exhaustHX.WaterOutNodeName)
    assert_gt(exhaustHX.WaterOutNode, 0)
    expect_eq(0.0004, exhaustHX.WaterVolumeFlowMax)
    expect_eq("GENERATOR FUEL CELL EXHAUST GAS TO WATER HEAT EXCHANGER 1 EXHAUST OUTLET AIR NODE", exhaustHX.ExhaustOutNodeName)
    assert_gt(exhaustHX.ExhaustOutNode, 0)
    expect_enum_eq(DataGenerators.ExhaustGasHX.Condensing, thisFC.ExhaustHX.HXmodelMode)
    expect_eq(83.1, exhaustHX.hxs0)
    expect_eq(4798.0, exhaustHX.hxs1)
    expect_eq(-138000.0, exhaustHX.hxs2)
    expect_eq(-353800.0, exhaustHX.hxs3)
    expect_eq(515000000.0, exhaustHX.hxs4)
    expect_eq(0.0, exhaustHX.HXEffect)
    expect_eq(0.0, exhaustHX.NdotGasRef)
    expect_eq(0.0, exhaustHX.nCoeff)
    expect_eq(0.0, exhaustHX.AreaGas)
    expect_eq(0.0, exhaustHX.h0Water)
    expect_eq(0.0, exhaustHX.NdotWaterRef)
    expect_eq(0.0, exhaustHX.mCoeff)
    expect_eq(0.0, exhaustHX.AreaWater)
    expect_eq(0.0, exhaustHX.Fadjust)
    expect_eq(0.0031, exhaustHX.l1Coeff)
    expect_eq(1.0, exhaustHX.l2Coeff)
    expect_eq(35.0, exhaustHX.CondensationThresholdTemp)
    expect_eq("GENERATOR FUEL CELL ELECTRICAL STORAGE 1", thisFC.NameElecStorage)
    var elecStorage = thisFC.ElecStorage
    expect_eq(elecStorage.Name, thisFC.NameElecStorage)
    expect_enum_eq(DataGenerators.ElectricalStorage.SimpleEffConstraints, elecStorage.StorageModelMode)
    expect_eq(1.0, elecStorage.EnergeticEfficCharge)
    expect_eq(1.0, elecStorage.EnergeticEfficDischarge)
    expect_eq(0.0, elecStorage.NominalEnergyCapacity)
    expect_eq(0.0, elecStorage.MaxPowerDraw)
    expect_eq(0.0, elecStorage.MaxPowerStore)
    expect_eq(0.0, elecStorage.StartingEnergyStored)
    expect_eq("GENERATOR FUEL CELL INVERTER 1", thisFC.NameInverter)
    var inverter = thisFC.Inverter
    expect_enum_eq(DataGenerators.InverterEfficiencyMode.Constant, inverter.EffMode)
    expect_eq(1.0, inverter.ConstEff)
    assert_gt(inverter.EffQuadraticCurve.Num, 0)
    expect_eq("EFFICIENCY FUNCTION OF DC POWER CURVE", inverter.EffQuadraticCurve.Name)
    expect_eq(1, thisFC.CWPlantLoc.loopNum)
    var report = thisFC.Report
    expect_eq(exhaustHX.qHX, report.qHX)
    expect_eq(report.ACPowerGen, generatorController.electProdRate)
    expect_eq(report.ACEnergyGen, generatorController.electricityProd)
    expect_true(generatorController.electProdRate > 1.15 * generatorController.thermProdRate) << "Power to Heat Ratio appears too low"
    expect_double_eq(exhaustHX.qHX, generatorController.thermProdRate)
    expect_double_eq(generatorController.thermProdRate * 15 * 60, generatorController.thermalProd)