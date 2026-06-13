from gtest import gtest
from Fixtures.EnergyPlusFixture import EnergyPlusFixture
from EnergyPlus.DataZoneEquipment import DataZoneEquipment
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataHeatBalance import DataHeatBalance
from EnergyPlus.HeatBalanceInternalHeatGains import HeatBalanceInternalHeatGains
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.Plant.DataPlant import DataPlant
from EnergyPlus.ScheduleManager import ScheduleManager
from EnergyPlus.InternalHeatGains import InternalHeatGains
from EnergyPlus.RefrigeratedCase import RefrigeratedCase
from fmt import format  # note: fmt module may not exist; use Python's format

# using EnergyPlus namespace is implicit via imports

let oneZoneBuildingWithIdealLoads: StringLiteral = R"IDF(
ScheduleTypeLimits,
  Any Number;                             !- Name
Schedule:Constant,
  Always On,                              !- Name
  Any Number,                             !- Schedule Type Limits Name
  1;                                      !- Hourly Value
Schedule:Constant,
  Always Off,                             !- Name
  Any Number,                             !- Schedule Type Limits Name
  0;                                      !- Hourly Value
Zone,
  Zone_1,                                 !- Name
  ,                                       !- Direction of Relative North {deg}
  0,                                      !- X Origin {m}
  0,                                      !- Y Origin {m}
  0,                                      !- Z Origin {m}
  ,                                       !- Type
  1,                                      !- Multiplier
  ,                                       !- Ceiling Height {m}
  ,                                       !- Volume {m3}
  ,                                       !- Floor Area {m2}
  ,                                       !- Zone Inside Convection Algorithm
  ,                                       !- Zone Outside Convection Algorithm
  Yes;                                    !- Part of Total Floor Area
Space,
  Space_1,                                !- Name
  Zone_1,                                 !- Zone Name
  ,                                       !- Ceiling Height {m}
  ,                                       !- Volume {m3}
  ;                                       !- Floor Area {m2}
BuildingSurface:Detailed,
  Space_1 Floor,                          !- Name
  Floor,                                  !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Ground,                                 !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  NoSun,                                  !- Sun Exposure
  NoWind,                                 !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  10, 5, 0,                               !- X,Y,Z Vertex 1 {m}
  10, -5, 0,                              !- X,Y,Z Vertex 2 {m}
  -10, -5, 0,                             !- X,Y,Z Vertex 3 {m}
  -10, 5, 0;                              !- X,Y,Z Vertex 4 {m}
BuildingSurface:Detailed,
  Space_1 RoofCeiling,                    !- Name
  Roof,                                   !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Outdoors,                               !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  SunExposed,                             !- Sun Exposure
  WindExposed,                            !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  -10, 5, 3,                              !- X,Y,Z Vertex 1 {m}
  -10, -5, 3,                             !- X,Y,Z Vertex 2 {m}
  10, -5, 3,                              !- X,Y,Z Vertex 3 {m}
  10, 5, 3;                               !- X,Y,Z Vertex 4 {m}
BuildingSurface:Detailed,
  Space_1 Wall 1,                         !- Name
  Wall,                                   !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Outdoors,                               !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  SunExposed,                             !- Sun Exposure
  WindExposed,                            !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  10, 5, 3,                               !- X,Y,Z Vertex 1 {m}
  10, -5, 3,                              !- X,Y,Z Vertex 2 {m}
  10, -5, 0,                              !- X,Y,Z Vertex 3 {m}
  10, 5, 0;                               !- X,Y,Z Vertex 4 {m}
BuildingSurface:Detailed,
  Space_1 Wall 2,                         !- Name
  Wall,                                   !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Outdoors,                               !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  SunExposed,                             !- Sun Exposure
  WindExposed,                            !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  10, -5, 3,                              !- X,Y,Z Vertex 1 {m}
  -10, -5, 3,                             !- X,Y,Z Vertex 2 {m}
  -10, -5, 0,                             !- X,Y,Z Vertex 3 {m}
  10, -5, 0;                              !- X,Y,Z Vertex 4 {m}
BuildingSurface:Detailed,
  Space_1 Wall 3,                         !- Name
  Wall,                                   !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Outdoors,                               !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  SunExposed,                             !- Sun Exposure
  WindExposed,                            !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  -10, -5, 3,                             !- X,Y,Z Vertex 1 {m}
  -10, 5, 3,                              !- X,Y,Z Vertex 2 {m}
  -10, 5, 0,                              !- X,Y,Z Vertex 3 {m}
  -10, -5, 0;                             !- X,Y,Z Vertex 4 {m}
BuildingSurface:Detailed,
  Space_1 Wall 4,                         !- Name
  Wall,                                   !- Surface Type
  Construction 1,                         !- Construction Name
  Zone_1,                                 !- Zone Name
  Space_1,                                !- Space Name
  Outdoors,                               !- Outside Boundary Condition
  ,                                       !- Outside Boundary Condition Object
  SunExposed,                             !- Sun Exposure
  WindExposed,                            !- Wind Exposure
  ,                                       !- View Factor to Ground
  ,                                       !- Number of Vertices
  -10, 5, 3,                              !- X,Y,Z Vertex 1 {m}
  10, 5, 3,                               !- X,Y,Z Vertex 2 {m}
  10, 5, 0,                               !- X,Y,Z Vertex 3 {m}
  -10, 5, 0;                              !- X,Y,Z Vertex 4 {m}
Material,
  Material 1,                             !- Name
  Smooth,                                 !- Roughness
  0.1,                                    !- Thickness {m}
  0.1,                                    !- Conductivity {W/m-K}
  0.1,                                    !- Density {kg/m3}
  1400,                                   !- Specific Heat {J/kg-K}
  0.9,                                    !- Thermal Absorptance
  0.7,                                    !- Solar Absorptance
  0.7;                                    !- Visible Absorptance
Construction,
  Construction 1,                         !- Name
  Material 1;                             !- Layer 1
ZoneHVAC:EquipmentConnections,
  Zone_1,                                 !- Zone Name
  Zone_1 Equipment List,                  !- Zone Conditioning Equipment List Name
  Zone_1 Inlet Node List,                 !- Zone Air Inlet Node or NodeList Name
  Zone_1 Exhaust Node List,               !- Zone Air Exhaust Node or NodeList Name
  Node 1;                                 !- Zone Air Node Name
NodeList,
  Zone_1 Inlet Node List,                 !- Name
  Node 3;                                 !- Node Name 1
NodeList,
  Zone_1 Exhaust Node List,               !- Name
  Node 2;                                 !- Node Name 1
ZoneHVAC:IdealLoadsAirSystem,
  Zone HVAC Ideal Loads Air System 1,     !- Name
  ,                                       !- Availability Schedule Name
  Node 3,                                 !- Zone Supply Air Node Name
  Node 2,                                 !- Zone Exhaust Air Node Name
  ,                                       !- System Inlet Air Node Name
  ,                                       !- Maximum Heating Supply Air Temperature {C}
  ,                                       !- Minimum Cooling Supply Air Temperature {C}
  ,                                       !- Maximum Heating Supply Air Humidity Ratio {kgWater/kgDryAir}
  ,                                       !- Minimum Cooling Supply Air Humidity Ratio {kgWater/kgDryAir}
  ,                                       !- Heating Limit
  ,                                       !- Maximum Heating Air Flow Rate {m3/s}
  ,                                       !- Maximum Sensible Heating Capacity {W}
  ,                                       !- Cooling Limit
  ,                                       !- Maximum Cooling Air Flow Rate {m3/s}
  ,                                       !- Maximum Total Cooling Capacity {W}
  ,                                       !- Heating Availability Schedule Name
  ,                                       !- Cooling Availability Schedule Name
  ,                                       !- Dehumidification Control Type
  ,                                       !- Cooling Sensible Heat Ratio {dimensionless}
  ,                                       !- Humidification Control Type
  ,                                       !- Design Specification Outdoor Air Object Name
  ,                                       !- Outdoor Air Inlet Node Name
  ,                                       !- Demand Controlled Ventilation Type
  ,                                       !- Outdoor Air Economizer Type
  ,                                       !- Heat Recovery Type
  ,                                       !- Sensible Heat Recovery Effectiveness {dimensionless}
  ;                                       !- Latent Heat Recovery Effectiveness {dimensionless}
ZoneHVAC:EquipmentList,
  Zone_1 Equipment List,                  !- Name
  SequentialLoad,                         !- Load Distribution Scheme
  ZoneHVAC:IdealLoadsAirSystem,           !- Zone Equipment Object Type 1
  Zone HVAC Ideal Loads Air System 1,     !- Zone Equipment Name 1
  1,                                      !- Zone Equipment Cooling Sequence 1
  1,                                      !- Zone Equipment Heating or No-Load Sequence 1
  ,                                       !- Zone Equipment Sequential Cooling Fraction Schedule Name 1
  ;                                       !- Zone Equipment Sequential Heating Fraction Schedule Name 1
)IDF"

@fixture
def RefrigeratedRackWithCaseInZone():
    let idf_objects: StringLiteral = R"IDF(
Refrigeration:CompressorRack,
  SelfContainedDisplay,    !- Name
  Zone,                    !- Heat Rejection Location
  4.0,                     !- Design Compressor Rack COP {W/W}
  RackCOPfTCurve2,         !- Compressor Rack COP Function of Temperature Curve Name
  175.0,                   !- Design Condenser Fan Power {W}
  ,                        !- Condenser Fan Power Function of Temperature Curve Name
  AirCooled,               !- Condenser Type
  ,                        !- Water-Cooled Condenser Inlet Node Name
  ,                        !- Water-Cooled Condenser Outlet Node Name
  ,                        !- Water-Cooled Loop Flow Type
  ,                        !- Water-Cooled Condenser Outlet Temperature Schedule Name
  ,                        !- Water-Cooled Condenser Design Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Water Outlet Temperature {C}
  ,                        !- Water-Cooled Condenser Minimum Water Inlet Temperature {C}
  ,                        !- Evaporative Condenser Availability Schedule Name
  ,                        !- Evaporative Condenser Effectiveness {dimensionless}
  ,                        !- Evaporative Condenser Air Flow Rate {m3/s}
  ,                        !- Basin Heater Capacity {W/K}
  ,                        !- Basin Heater Setpoint Temperature {C}
  ,                        !- Design Evaporative Condenser Water Pump Power {W}
  ,                        !- Evaporative Water Supply Tank Name
  ,                        !- Condenser Air Inlet Node Name
  ,                        !- End-Use Subcategory
  SelfContainedDisplayCase,!- Refrigeration Case Name or WalkIn Name or CaseAndWalkInList Name
  ZONE_1;                  !- Heat Rejection Zone Name
Curve:Quadratic,
  RackCOPfTCurve2,         !- Name
  1.0,                     !- Coefficient1 Constant
  0.0,                     !- Coefficient2 x
  0.0,                     !- Coefficient3 x**2
  0.0,                     !- Minimum Value of x
  50.0,                    !- Maximum Value of x
  ,                        !- Minimum Curve Output
  ,                        !- Maximum Curve Output
  Temperature,             !- Input Unit Type for X
  Dimensionless;           !- Output Unit Type
Refrigeration:Case,
  SelfContainedDisplayCase,!- Name
  ,                        !- Availability Schedule Name
  ZONE_1,                  !- Zone Name
  23.88,                   !- Rated Ambient Temperature {C}
  55.0,                    !- Rated Ambient Relative Humidity {percent}
  1000.0,                  !- Rated Total Cooling Capacity per Unit Length {W/m}
  0.08,                    !- Rated Latent Heat Ratio
  0.85,                    !- Rated Runtime Fraction
  10.0,                    !- Case Length {m}
  13.0,                    !- Case Operating Temperature {C}
  CaseTemperatureMethod,   !- Latent Case Credit Curve Type
  MultiShelfVertical_LatentEnergyMult,  !- Latent Case Credit Curve Name
  40.0,                    !- Standard Case Fan Power per Unit Length {W/m}
  40.0,                    !- Operating Case Fan Power per Unit Length {W/m}
  75.0,                    !- Standard Case Lighting Power per Unit Length {W/m}
  ,                        !- Installed Case Lighting Power per Unit Length {W/m}
  Always On,               !- Case Lighting Schedule Name
  0.9,                     !- Fraction of Lighting Energy to Case
  0.0,                     !- Case Anti-Sweat Heater Power per Unit Length {W/m}
  ,                        !- Minimum Anti-Sweat Heater Power per Unit Length {W/m}
  None,                    !- Anti-Sweat Heater Control Type
  0.0,                     !- Humidity at Zero Anti-Sweat Heater Energy {percent}
  0.0,                     !- Case Height {m}
  0.0,                     !- Fraction of Anti-Sweat Heater Energy to Case
  0.0,                     !- Case Defrost Power per Unit Length {W/m}
  None,                    !- Case Defrost Type
  ,                        !- Case Defrost Schedule Name
  ,                        !- Case Defrost Drip-Down Schedule Name
  ,                        !- Defrost Energy Correction Curve Type
  ,                        !- Defrost Energy Correction Curve Name
  0.0,                     !- Under Case HVAC Return Air Fraction
  SelfContainedCaseStockingSched;  !- Refrigerated Case Restocking Schedule Name
Curve:Cubic,
  MultiShelfVertical_LatentEnergyMult,  !- Name
  0.026526281,             !- Coefficient1 Constant
  0.001078032,             !- Coefficient2 x
  -0.0000602558,           !- Coefficient3 x**2
  0.00000123732,           !- Coefficient4 x**3
  -35.0,                   !- Minimum Value of x
  20.0;                    !- Maximum Value of x
Schedule:Compact,
  SelfContainedCaseStockingSched,  !- Name
  AnyNumber,               !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 6:00,0.0,         !- Field 3
  Until: 7:00,50.0,        !- Field 5
  Until: 9:00,70.0,        !- Field 7
  Until: 10:00,80.0,       !- Field 9
  Until: 11:00,70.0,       !- Field 11
  Until: 13:00,50.0,       !- Field 13
  Until: 14:00,80.0,       !- Field 15
  Until: 15:00,90.0,       !- Field 17
  Until: 16:00,80.0,       !- Field 19
  Until: 24:00,0.0;        !- Field 21
)IDF"
    ASSERT_TRUE(process_idf(oneZoneBuildingWithIdealLoads + "\n" + idf_objects)) # read idf objects
    state.init_state(state)
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    state.dataEnvrn.OutBaroPress = 101325.0
    var ErrorsFound: Bool = False
    HeatBalanceManager::GetZoneData(state, ErrorsFound)
    ASSERT_FALSE(ErrorsFound)
    DataZoneEquipment::GetZoneEquipmentData(state)
    InternalHeatGains::ManageInternalHeatGains(state, True)
    RefrigeratedCase::ManageRefrigeratedCaseRacks(state)

@fixture
def RefrigeratedRackWithWalkInInZone():
    let idf_objects: StringLiteral = R"IDF(
Refrigeration:CompressorRack,
  SelfContainedDisplay,    !- Name
  Zone,                    !- Heat Rejection Location
  4.0,                     !- Design Compressor Rack COP {W/W}
  RackCOPfTCurve2,         !- Compressor Rack COP Function of Temperature Curve Name
  175.0,                   !- Design Condenser Fan Power {W}
  ,                        !- Condenser Fan Power Function of Temperature Curve Name
  AirCooled,               !- Condenser Type
  ,                        !- Water-Cooled Condenser Inlet Node Name
  ,                        !- Water-Cooled Condenser Outlet Node Name
  ,                        !- Water-Cooled Loop Flow Type
  ,                        !- Water-Cooled Condenser Outlet Temperature Schedule Name
  ,                        !- Water-Cooled Condenser Design Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Water Outlet Temperature {C}
  ,                        !- Water-Cooled Condenser Minimum Water Inlet Temperature {C}
  ,                        !- Evaporative Condenser Availability Schedule Name
  ,                        !- Evaporative Condenser Effectiveness {dimensionless}
  ,                        !- Evaporative Condenser Air Flow Rate {m3/s}
  ,                        !- Basin Heater Capacity {W/K}
  ,                        !- Basin Heater Setpoint Temperature {C}
  ,                        !- Design Evaporative Condenser Water Pump Power {W}
  ,                        !- Evaporative Water Supply Tank Name
  ,                        !- Condenser Air Inlet Node Name
  ,                        !- End-Use Subcategory
  RefrigerationWalkIn,     !- Refrigeration Case Name or WalkIn Name or CaseAndWalkInList Name
  ZONE_1;                  !- Heat Rejection Zone Name
Curve:Quadratic,
  RackCOPfTCurve2,         !- Name
  1.0,                     !- Coefficient1 Constant
  0.0,                     !- Coefficient2 x
  0.0,                     !- Coefficient3 x**2
  0.0,                     !- Minimum Value of x
  50.0,                    !- Maximum Value of x
  ,                        !- Minimum Curve Output
  ,                        !- Maximum Curve Output
  Temperature,             !- Input Unit Type for X
  Dimensionless;           !- Output Unit Type
Refrigeration:WalkIn,
  RefrigerationWalkIn,     !- Name
  Always On,               !- Availability Schedule Name
  5,                       !- Rated Coil Cooling Capacity {W}
  1.66666666666667,        !- Operating Temperature {C}
  -6.11111111111111,       !- Rated Cooling Source Temperature {C}
  0.0,                     !- Rated Total Heating Power {W}
  Always On,               !- Heating Power Schedule Name
  5,                       !- Rated Cooling Coil Fan Power {W}
  0.0,                     !- Rated Circulation Fan Power {W}
  5,                       !- Rated Total Lighting Power {W}
  Always On,               !- Lighting Schedule Name
  Electric,                !- Defrost Type
  TimeSchedule,            !- Defrost Control Type
  Always Off,              !- Defrost Schedule Name
  ,                        !- Defrost Drip-Down Schedule Name
  0.001,                   !- Defrost Power {W}
  ,                        !- Temperature Termination Defrost Fraction to Ice {dimensionless}
  ,                        !- Restocking Schedule Name
  ,                        !- Average Refrigerant Charge Inventory {kg}
  1,                       !- Insulated Floor Surface Area {m2}
  0.17744571875,           !- Insulated Floor U-Value {W/m2-K}
  ZONE_1,                  !- Zone 1 Name
  6.504,                   !- Total Insulated Surface Area Facing Zone 1 {m2}
  0.17744571875,           !- Insulated Surface U-Value Facing Zone 1 {W/m2-K}
  ,                        !- Area of Glass Reach In Doors Facing Zone 1 {m2}
  ,                        !- Height of Glass Reach In Doors Facing Zone 1 {m}
  ,                        !- Glass Reach In Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Glass Reach In Door Opening Schedule Name Facing Zone 1
  1.216,                   !- Area of Stocking Doors Facing Zone 1 {m2}
  1.651,                   !- Height of Stocking Doors Facing Zone 1 {m}
  ,                        !- Stocking Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Stocking Door Opening Schedule Name Facing Zone 1
  None;                    !- Stocking Door Opening Protection Type Facing Zone 1
)IDF"
    ASSERT_TRUE(process_idf(oneZoneBuildingWithIdealLoads + "\n" + idf_objects)) # read idf objects
    state.init_state(state)
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    state.dataEnvrn.OutBaroPress = 101325.0
    var ErrorsFound: Bool = False
    HeatBalanceManager::GetZoneData(state, ErrorsFound)
    ASSERT_FALSE(ErrorsFound)
    DataZoneEquipment::GetZoneEquipmentData(state)
    InternalHeatGains::ManageInternalHeatGains(state, True)
    RefrigeratedCase::ManageRefrigeratedCaseRacks(state)

@fixture
def RefrigeratedRackWithWalkInInZone_CaseAndWalkinList():
    let idf_objects: StringLiteral = R"IDF(
Refrigeration:CompressorRack,
  SelfContainedDisplay,    !- Name
  Zone,                    !- Heat Rejection Location
  4.0,                     !- Design Compressor Rack COP {W/W}
  RackCOPfTCurve2,         !- Compressor Rack COP Function of Temperature Curve Name
  175.0,                   !- Design Condenser Fan Power {W}
  ,                        !- Condenser Fan Power Function of Temperature Curve Name
  AirCooled,               !- Condenser Type
  ,                        !- Water-Cooled Condenser Inlet Node Name
  ,                        !- Water-Cooled Condenser Outlet Node Name
  ,                        !- Water-Cooled Loop Flow Type
  ,                        !- Water-Cooled Condenser Outlet Temperature Schedule Name
  ,                        !- Water-Cooled Condenser Design Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Water Outlet Temperature {C}
  ,                        !- Water-Cooled Condenser Minimum Water Inlet Temperature {C}
  ,                        !- Evaporative Condenser Availability Schedule Name
  ,                        !- Evaporative Condenser Effectiveness {dimensionless}
  ,                        !- Evaporative Condenser Air Flow Rate {m3/s}
  ,                        !- Basin Heater Capacity {W/K}
  ,                        !- Basin Heater Setpoint Temperature {C}
  ,                        !- Design Evaporative Condenser Water Pump Power {W}
  ,                        !- Evaporative Water Supply Tank Name
  ,                        !- Condenser Air Inlet Node Name
  ,                        !- End-Use Subcategory
  CompressorRack with Case and Walkin List,     !- Refrigeration Case Name or WalkIn Name or CaseAndWalkInList Name
  ZONE_1;                  !- Heat Rejection Zone Name
Curve:Quadratic,
  RackCOPfTCurve2,         !- Name
  1.0,                     !- Coefficient1 Constant
  0.0,                     !- Coefficient2 x
  0.0,                     !- Coefficient3 x**2
  0.0,                     !- Minimum Value of x
  50.0,                    !- Maximum Value of x
  ,                        !- Minimum Curve Output
  ,                        !- Maximum Curve Output
  Temperature,             !- Input Unit Type for X
  Dimensionless;           !- Output Unit Type
Refrigeration:CaseAndWalkInList,
  CompressorRack with Case and Walkin List, !- Name
  RefrigerationWalkIn;                      !- Case or WalkIn Name 1
Refrigeration:WalkIn,
  RefrigerationWalkIn,     !- Name
  Always On,               !- Availability Schedule Name
  5,                       !- Rated Coil Cooling Capacity {W}
  1.66666666666667,        !- Operating Temperature {C}
  -6.11111111111111,       !- Rated Cooling Source Temperature {C}
  0.0,                     !- Rated Total Heating Power {W}
  Always On,               !- Heating Power Schedule Name
  5,                       !- Rated Cooling Coil Fan Power {W}
  0.0,                     !- Rated Circulation Fan Power {W}
  5,                       !- Rated Total Lighting Power {W}
  Always On,               !- Lighting Schedule Name
  Electric,                !- Defrost Type
  TimeSchedule,            !- Defrost Control Type
  Always Off,              !- Defrost Schedule Name
  ,                        !- Defrost Drip-Down Schedule Name
  0.001,                   !- Defrost Power {W}
  ,                        !- Temperature Termination Defrost Fraction to Ice {dimensionless}
  ,                        !- Restocking Schedule Name
  ,                        !- Average Refrigerant Charge Inventory {kg}
  1,                       !- Insulated Floor Surface Area {m2}
  0.17744571875,           !- Insulated Floor U-Value {W/m2-K}
  ZONE_1,                  !- Zone 1 Name
  6.504,                   !- Total Insulated Surface Area Facing Zone 1 {m2}
  0.17744571875,           !- Insulated Surface U-Value Facing Zone 1 {W/m2-K}
  ,                        !- Area of Glass Reach In Doors Facing Zone 1 {m2}
  ,                        !- Height of Glass Reach In Doors Facing Zone 1 {m}
  ,                        !- Glass Reach In Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Glass Reach In Door Opening Schedule Name Facing Zone 1
  1.216,                   !- Area of Stocking Doors Facing Zone 1 {m2}
  1.651,                   !- Height of Stocking Doors Facing Zone 1 {m}
  ,                        !- Stocking Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Stocking Door Opening Schedule Name Facing Zone 1
  None;                    !- Stocking Door Opening Protection Type Facing Zone 1
)IDF"
    ASSERT_TRUE(process_idf(oneZoneBuildingWithIdealLoads + "\n" + idf_objects)) # read idf objects
    state.init_state(state)
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    state.dataEnvrn.OutBaroPress = 101325.0
    var ErrorsFound: Bool = False
    HeatBalanceManager::GetZoneData(state, ErrorsFound)
    ASSERT_FALSE(ErrorsFound)
    DataZoneEquipment::GetZoneEquipmentData(state)
    InternalHeatGains::ManageInternalHeatGains(state, True)
    RefrigeratedCase::ManageRefrigeratedCaseRacks(state)

@fixture
def RefrigeratedRackWithBothInZone_CaseAndWalkinList():
    let idf_objects: StringLiteral = R"IDF(
Refrigeration:CompressorRack,
  SelfContainedDisplay,    !- Name
  Zone,                    !- Heat Rejection Location
  4.0,                     !- Design Compressor Rack COP {W/W}
  RackCOPfTCurve2,         !- Compressor Rack COP Function of Temperature Curve Name
  175.0,                   !- Design Condenser Fan Power {W}
  ,                        !- Condenser Fan Power Function of Temperature Curve Name
  AirCooled,               !- Condenser Type
  ,                        !- Water-Cooled Condenser Inlet Node Name
  ,                        !- Water-Cooled Condenser Outlet Node Name
  ,                        !- Water-Cooled Loop Flow Type
  ,                        !- Water-Cooled Condenser Outlet Temperature Schedule Name
  ,                        !- Water-Cooled Condenser Design Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Flow Rate {m3/s}
  ,                        !- Water-Cooled Condenser Maximum Water Outlet Temperature {C}
  ,                        !- Water-Cooled Condenser Minimum Water Inlet Temperature {C}
  ,                        !- Evaporative Condenser Availability Schedule Name
  ,                        !- Evaporative Condenser Effectiveness {dimensionless}
  ,                        !- Evaporative Condenser Air Flow Rate {m3/s}
  ,                        !- Basin Heater Capacity {W/K}
  ,                        !- Basin Heater Setpoint Temperature {C}
  ,                        !- Design Evaporative Condenser Water Pump Power {W}
  ,                        !- Evaporative Water Supply Tank Name
  ,                        !- Condenser Air Inlet Node Name
  ,                        !- End-Use Subcategory
  CompressorRack with Case and Walkin List,     !- Refrigeration Case Name or WalkIn Name or CaseAndWalkInList Name
  ZONE_1;                  !- Heat Rejection Zone Name
Curve:Quadratic,
  RackCOPfTCurve2,         !- Name
  1.0,                     !- Coefficient1 Constant
  0.0,                     !- Coefficient2 x
  0.0,                     !- Coefficient3 x**2
  0.0,                     !- Minimum Value of x
  50.0,                    !- Maximum Value of x
  ,                        !- Minimum Curve Output
  ,                        !- Maximum Curve Output
  Temperature,             !- Input Unit Type for X
  Dimensionless;           !- Output Unit Type
Refrigeration:CaseAndWalkInList,
  CompressorRack with Case and Walkin List, !- Name
  RefrigerationWalkIn,                      !- Case or WalkIn Name 1
  SelfContainedDisplayCase;                 !- Case or WalkIn Name 2
Refrigeration:WalkIn,
  RefrigerationWalkIn,     !- Name
  Always On,               !- Availability Schedule Name
  5,                       !- Rated Coil Cooling Capacity {W}
  1.66666666666667,        !- Operating Temperature {C}
  -6.11111111111111,       !- Rated Cooling Source Temperature {C}
  0.0,                     !- Rated Total Heating Power {W}
  Always On,               !- Heating Power Schedule Name
  5,                       !- Rated Cooling Coil Fan Power {W}
  0.0,                     !- Rated Circulation Fan Power {W}
  5,                       !- Rated Total Lighting Power {W}
  Always On,               !- Lighting Schedule Name
  Electric,                !- Defrost Type
  TimeSchedule,            !- Defrost Control Type
  Always Off,              !- Defrost Schedule Name
  ,                        !- Defrost Drip-Down Schedule Name
  0.001,                   !- Defrost Power {W}
  ,                        !- Temperature Termination Defrost Fraction to Ice {dimensionless}
  ,                        !- Restocking Schedule Name
  ,                        !- Average Refrigerant Charge Inventory {kg}
  1,                       !- Insulated Floor Surface Area {m2}
  0.17744571875,           !- Insulated Floor U-Value {W/m2-K}
  ZONE_1,                  !- Zone 1 Name
  6.504,                   !- Total Insulated Surface Area Facing Zone 1 {m2}
  0.17744571875,           !- Insulated Surface U-Value Facing Zone 1 {W/m2-K}
  ,                        !- Area of Glass Reach In Doors Facing Zone 1 {m2}
  ,                        !- Height of Glass Reach In Doors Facing Zone 1 {m}
  ,                        !- Glass Reach In Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Glass Reach In Door Opening Schedule Name Facing Zone 1
  1.216,                   !- Area of Stocking Doors Facing Zone 1 {m2}
  1.651,                   !- Height of Stocking Doors Facing Zone 1 {m}
  ,                        !- Stocking Door U Value Facing Zone 1 {W/m2-K}
  ,                        !- Stocking Door Opening Schedule Name Facing Zone 1
  None;                    !- Stocking Door Opening Protection Type Facing Zone 1
Refrigeration:Case,
  SelfContainedDisplayCase,!- Name
  ,                        !- Availability Schedule Name
  ZONE_1,                  !- Zone Name
  23.88,                   !- Rated Ambient Temperature {C}
  55.0,                    !- Rated Ambient Relative Humidity {percent}
  1000.0,                  !- Rated Total Cooling Capacity per Unit Length {W/m}
  0.08,                    !- Rated Latent Heat Ratio
  0.85,                    !- Rated Runtime Fraction
  10.0,                    !- Case Length {m}
  13.0,                    !- Case Operating Temperature {C}
  CaseTemperatureMethod,   !- Latent Case Credit Curve Type
  MultiShelfVertical_LatentEnergyMult,  !- Latent Case Credit Curve Name
  40.0,                    !- Standard Case Fan Power per Unit Length {W/m}
  40.0,                    !- Operating Case Fan Power per Unit Length {W/m}
  75.0,                    !- Standard Case Lighting Power per Unit Length {W/m}
  ,                        !- Installed Case Lighting Power per Unit Length {W/m}
  Always On,               !- Case Lighting Schedule Name
  0.9,                     !- Fraction of Lighting Energy to Case
  0.0,                     !- Case Anti-Sweat Heater Power per Unit Length {W/m}
  ,                        !- Minimum Anti-Sweat Heater Power per Unit Length {W/m}
  None,                    !- Anti-Sweat Heater Control Type
  0.0,                     !- Humidity at Zero Anti-Sweat Heater Energy {percent}
  0.0,                     !- Case Height {m}
  0.0,                     !- Fraction of Anti-Sweat Heater Energy to Case
  0.0,                     !- Case Defrost Power per Unit Length {W/m}
  None,                    !- Case Defrost Type
  ,                        !- Case Defrost Schedule Name
  ,                        !- Case Defrost Drip-Down Schedule Name
  ,                        !- Defrost Energy Correction Curve Type
  ,                        !- Defrost Energy Correction Curve Name
  0.0,                     !- Under Case HVAC Return Air Fraction
  SelfContainedCaseStockingSched;  !- Refrigerated Case Restocking Schedule Name
Curve:Cubic,
  MultiShelfVertical_LatentEnergyMult,  !- Name
  0.026526281,             !- Coefficient1 Constant
  0.001078032,             !- Coefficient2 x
  -0.0000602558,           !- Coefficient3 x**2
  0.00000123732,           !- Coefficient4 x**3
  -35.0,                   !- Minimum Value of x
  20.0;                    !- Maximum Value of x
Schedule:Compact,
  SelfContainedCaseStockingSched,  !- Name
  AnyNumber,               !- Schedule Type Limits Name
  Through: 12/31,          !- Field 1
  For: AllDays,            !- Field 2
  Until: 6:00,0.0,         !- Field 3
  Until: 7:00,50.0,        !- Field 5
  Until: 9:00,70.0,        !- Field 7
  Until: 10:00,80.0,       !- Field 9
  Until: 11:00,70.0,       !- Field 11
  Until: 13:00,50.0,       !- Field 13
  Until: 14:00,80.0,       !- Field 15
  Until: 15:00,90.0,       !- Field 17
  Until: 16:00,80.0,       !- Field 19
  Until: 24:00,0.0;        !- Field 21
)IDF"
    ASSERT_TRUE(process_idf(oneZoneBuildingWithIdealLoads + "\n" + idf_objects)) # read idf objects
    state.init_state(state)
    state.dataZoneEquip.ZoneEquipInputsFilled = True
    state.dataEnvrn.OutBaroPress = 101325.0
    var ErrorsFound: Bool = False
    HeatBalanceManager::GetZoneData(state, ErrorsFound)
    ASSERT_FALSE(ErrorsFound)
    DataZoneEquipment::GetZoneEquipmentData(state)
    InternalHeatGains::ManageInternalHeatGains(state, True)
    RefrigeratedCase::ManageRefrigeratedCaseRacks(state)

@fixture
def DesuperheaterRefrigeration():
    let idf_objects: String = """  Zone,
    Basic Zone,                                               !- Name
    ,                                                         !- Direction of Relative North {deg}
    0,                                                        !- X Origin {m}
    0,                                                        !- Y Origin {m}
    0,                                                        !- Z Origin {m}
    ,                                                         !- Type
    1,                                                        !- Multiplier
    ,                                                         !- Ceiling Height {m}
    ,                                                         !- Volume {m3}
    ,                                                         !- Floor Area {m2}
    ,                                                         !- Zone Inside Convection Algorithm
    ,                                                         !- Zone Outside Convection Algorithm
    Yes;                                                      !- Part of Total Floor Area
  ZoneHVAC:EquipmentConnections,
    Basic Zone,                                               !- Zone Name
    Basic Zone Equipment List,                                !- Zone Conditioning Equipment List Name
    Basic Zone Inlet Node,                                    !- Zone Air Inlet Node or NodeList Name
    Basic Zone Exhaust Node,                                  !- Zone Air Exhaust Node or NodeList Name
    Basic Zone Air Node;                                      !- Zone Air Node Name
  ZoneHVAC:EquipmentList,
    Basic Zone Equipment List,                                !- Name
    SequentialLoad,                                           !- Load Distribution Scheme
    ZoneHVAC:PackagedTerminalAirConditioner,                  !- Zone Equipment 1 Object Type
    Basic Zone PTAC,                                          !- Zone Equipment 1 Name
    1,                                                        !- Zone Equipment 1 Cooling Sequence
    1,                                                        !- Zone Equipment 1 Heating or No-Load Sequence
    ,                                                         !- Zone Equipment 1 Sequential Cooling Fraction Schedule Name
    ;                                                         !- Zone Equipment 1 Sequential Heating Fraction Schedule Name
  ZoneHVAC:PackagedTerminalAirConditioner,
    Basic Zone PTAC,                                          !- Name
    ,                                                         !- Availability Schedule Name
    Basic Zone PTAC Inlet Node,                               !- Air Inlet Node Name
    Basic Zone Inlet Node,                                    !- Air Outlet Node Name
    OutdoorAir:Mixer,                                         !- Outdoor Air Mixer Object Type
    Basic Zone PTAC OA Mixer,                                 !- Outdoor Air Mixer Name
    Autosize,                                                 !- Cooling Supply Air Flow Rate {m3/s}
    Autosize,                                                 !- Heating Supply Air Flow Rate {m3/s}
    Autosize,                                                 !- No Load Supply Air Flow Rate {m3/s}
    No,                                                       !- No Load Supply Air Flow Rate Control Set To Low Speed
    Autosize,                                                 !- Cooling Outdoor Air Flow Rate {m3/s}
    Autosize,                                                 !- Heating Outdoor Air Flow Rate {m3/s}
    Autosize,                                                 !- No Load Outdoor Air Flow Rate {m3/s}
    Fan:OnOff,                                                !- Supply Air Fan Object Type
    Basic Zone PTAC Fan,                                      !- Supply Air Fan Name
    Coil:Heating:Fuel,                                        !- Heating Coil Object Type
    Basic Zone PTAC Heating Coil,                             !- Heating Coil Name
    Coil:Cooling:DX:SingleSpeed,                              !- Cooling Coil Object Type
    Basic Zone PTAC Cooling Coil,                             !- Cooling Coil Name
    DrawThrough,                                              !- Fan Placement
    ;                                                         !- Supply Air Fan Operating Mode Schedule Name
  OutdoorAir:Mixer,
    Basic Zone PTAC OA Mixer,                                 !- Name
    Basic Zone PTAC Mixed Air Node,                           !- Mixed Air Node Name
    Basic Zone PTAC OA Node,                                  !- Outdoor Air Stream Node Name
    Basic Zone PTAC Relief Air Node,                          !- Relief Air Stream Node Name
    Basic Zone PTAC Inlet Node;                               !- Return Air Stream Node Name
  OutdoorAir:NodeList,
    Basic Zone PTAC OA Node;                                  !- Node or NodeList Name 1
  Fan:OnOff,
    Basic Zone PTAC Fan,                                      !- Name
    ,                                                         !- Availability Schedule Name
    0.6,                                                      !- Fan Total Efficiency
    250,                                                      !- Pressure Rise {Pa}
    Autosize,                                                 !- Maximum Flow Rate {m3/s}
    0.8,                                                      !- Motor Efficiency
    1,                                                        !- Motor In Airstream Fraction
    Basic Zone PTAC Heating Coil Outlet Node,                 !- Air Inlet Node Name
    Basic Zone Inlet Node,                                    !- Air Outlet Node Name
    Generic Curve,                                            !- Fan Power Ratio Function of Speed Ratio Curve Name
    Generic Curve,                                            !- Fan Efficiency Ratio Function of Speed Ratio Curve Name
    General;                                                  !- End-Use Subcategory
  Coil:Heating:Fuel,
    Basic Zone PTAC Heating Coil,                             !- Name
    ,                                                         !- Availability Schedule Name
    NaturalGas,                                               !- Fuel Type
    0.8,                                                      !- Burner Efficiency
    1,                                                        !- Nominal Capacity {W}
    Basic Zone PTAC Cooling Coil Outlet Node,                 !- Air Inlet Node Name
    Basic Zone PTAC Heating Coil Outlet Node,                 !- Air Outlet Node Name
    ,                                                         !- Temperature Setpoint Node Name
    0,                                                        !- On Cycle Parasitic Electric Load {W}
    ,                                                         !- Part Load Fraction Correlation Curve Name
    0;                                                        !- Off Cycle Parasitic Fuel Load {W}
  Coil:Cooling:DX:SingleSpeed,
    Basic Zone PTAC Cooling Coil,                             !- Name
    ,                                                         !- Availability Schedule Name
    Autosize,                                                 !- Gross Rated Total Cooling Capacity {W}
    Autosize,                                                 !- Gross Rated Sensible Heat Ratio
    3,                                                        !- Gross Rated Cooling COP {W/W}
    Autosize,                                                 !- Rated Air Flow Rate {m3/s}
    773.3,                                                    !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
    934.4,                                                    !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
    Basic Zone PTAC Mixed Air Node,                           !- Air Inlet Node Name
    Basic Zone PTAC Cooling Coil Outlet Node,                 !- Air Outlet Node Name
    Generic Curve,                                            !- Total Cooling Capacity Function of Temperature Curve Name
    Generic Curve,                                            !- Total Cooling Capacity Function of Flow Fraction Curve Name
    Generic Curve,                                            !- Energy Input Ratio Function of Temperature Curve Name
    Generic Curve,                                            !- Energy Input Ratio Function of Flow Fraction Curve Name
    Generic Curve,                                            !- Part Load Fraction Correlation Curve Name
    -25,                                                      !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}
    0,                                                        !- Nominal Time for Condensate Removal to Begin {s}
    0,                                                        !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}
    0,                                                        !- Maximum Cycling Rate {cycles/hr}
    0,                                                        !- Latent Capacity Time Constant {s}
    ,                                                         !- Condenser Air Inlet Node Name
    AirCooled,                                                !- Condenser Type
    0,                                                        !- Evaporative Condenser Effectiveness {dimensionless}
    Autosize,                                                 !- Evaporative Condenser Air Flow Rate {m3/s}
    Autosize,                                                 !- Evaporative Condenser Pump Rated Power Consumption {W}
    0,                                                        !- Crankcase Heater Capacity {W}
    ,                                                         !- Crankcase Heater Capacity Function of Temperature Curve Name
    0,                                                        !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}
    ,                                                         !- Supply Water Storage Tank Name
    ,                                                         !- Condensate Collection Water Storage Tank Name
    0,                                                        !- Basin Heater Capacity {W/K}
    10;                                                       !- Basin Heater Setpoint Temperature {C}
  Zone,
    Refrig Cond AC Zone,                                      !- Name
    ,                                                         !- Direction of Relative North {deg}
    0,                                                        !- X Origin {m}
    0,                                                        !- Y Origin {m}
    0,                                                        !- Z Origin {m}
    ,                                                         !- Type
    1,                                                        !- Multiplier
    ,                                                         !- Ceiling Height {m}
    ,                                                         !- Volume {m3}
    ,                                                         !- Floor Area {m2}
    ,                                                         !- Zone Inside Convection Algorithm
    ,                                                         !- Zone Outside Convection Algorithm
    Yes;                                                      !- Part of Total Floor Area
  ZoneHVAC:EquipmentConnections,
    Refrig Cond AC Zone,                                      !- Zone Name
    Refrig Cond AC Zone Equipment List,                       !- Zone Conditioning Equipment List Name
    Refrig Cond AC Zone Inlet Node,                           !- Zone Air Inlet Node or NodeList Name
    Refrig Cond AC Zone Exhaust Node,                         !- Zone Air Exhaust Node or NodeList Name
    Refrig Cond AC Zone Air Node,                             !- Zone Air Node Name
    Refrig Cond AC Zone Return Node;                          !- Zone Return Air Node or NodeList Name
  ZoneHVAC:EquipmentList,
    Refrig Cond AC Zone Equipment List,                       !- Name
    SequentialLoad,                                           !- Load Distribution Scheme
    ZoneHVAC:AirDistributionUnit,                             !- Zone Equipment 1 Object Type
    Refrig Cond AC ADU,                                       !- Zone Equipment 1 Name
    1,                                                        !- Zone Equipment 1 Cooling Sequence
    1,                                                        !- Zone Equipment 1 Heating or No-Load Sequence
    ,                                                         !- Zone Equipment 1 Sequential Cooling Fraction Schedule Name
    ;                                                         !- Zone Equipment 1 Sequential Heating Fraction Schedule Name
  ZoneHVAC:AirDistributionUnit,
    Refrig Cond AC ADU,                                       !- Name
    Refrig Cond AC Zone Inlet Node,                           !- Air Distribution Unit Outlet Node Name
    AirTerminal:SingleDuct:ConstantVolume:NoReheat,           !- Air Terminal Object Type
    Refrig Cond AC Air Terminal;                              !- Air Terminal Name
  AirTerminal:SingleDuct:ConstantVolume:NoReheat,
    Refrig Cond AC Air Terminal,                              !- Name
    ,                                                         !- Availability Schedule Name
    Refrig Cond AC Air Terminal Inlet Node,                   !- Air Inlet Node Name
    Refrig Cond AC Zone Inlet Node,                           !- Air Outlet Node Name
    AutoSize;                                                 !- Maximum Air Flow Rate {m3/s}
  AirLoopHVAC,
    Refrig Cond AC PTAC,                                      !- Name
    ,                                                         !- Controller List Name
    ,                                                         !- Availability Manager List Name
    AutoSize,                                                 !- Design Supply Air Flow Rate {m3/s}
    Refrig Cond AC PTAC Supply Branch List,                   !- Branch List Name
    ,                                                         !- Connector List Name
    Refrig Cond AC PTAC Supply Side Inlet Node,               !- Supply Side Inlet Node Name
    Refrig Cond AC PTAC Demand Side Outlet Node,              !- Demand Side Outlet Node Name
    Refrig Cond AC PTAC Demand Side Inlet Node,               !- Demand Side Inlet Node Names
    Refrig Cond AC PTAC Supply Side Outlet Node,              !- Supply Side Outlet Node Names
    1;                                                        !- Design Return Air Flow Fraction of Supply Air Flow
  BranchList,
    Refrig Cond AC PTAC Supply Branch List,                   !- Name
    Refrig Cond AC PTAC Branch;                               !- Branch 1 Name
  Branch,
    Refrig Cond AC PTAC Branch,                               !- Name
    ,                                                         !- Pressure Drop Curve Name
    AirLoopHVAC:OutdoorAirSystem,                             !- Component 1 Object Type
    Refrig Cond AC PTAC OA System,                            !- Component 1 Name
    Refrig Cond AC PTAC Supply Side Inlet Node,               !- Component 1 Inlet Node Name
    Refrig Cond AC PTAC Mixed Air Node,                       !- Component 1 Outlet Node Name
    Coil:Cooling:DX:SingleSpeed,                              !- Component 2 Object Type
    Refrig Cond AC PTAC Cooling Coil,                         !- Component 2 Name
    Refrig Cond AC PTAC Mixed Air Node,                       !- Component 2 Inlet Node Name
    Refrig Cond AC PTAC Desuperheater Inlet Node,             !- Component 2 Outlet Node Name
    Coil:Heating:Desuperheater,                               !- Component 3 Object Type
    Refrig Cond AC PTAC Desuperheater,                        !- Component 3 Name
    Refrig Cond AC PTAC Desuperheater Inlet Node,             !- Component 3 Inlet Node Name
    Refrig Cond AC PTAC Desuperheater Outlet Node,            !- Component 3 Outlet Node Name
    Coil:Heating:Fuel,                                        !- Component 4 Object Type
    Refrig Cond AC PTAC Heating Coil,                         !- Component 4 Name
    Refrig Cond AC PTAC Desuperheater Outlet Node,            !- Component 4 Inlet Node Name
    Refrig Cond AC PTAC Heating Coil Outlet Node,             !- Component 4 Outlet Node Name
    Fan:ConstantVolume,                                       !- Component 5 Object Type
    Refrig Cond AC PTAC Fan,                                  !- Component 5 Name
    Refrig Cond AC PTAC Heating Coil Outlet Node,             !- Component 5 Inlet Node Name
    Refrig Cond AC PTAC Supply Side Outlet Node;              !- Component 5 Outlet Node Name
  AirLoopHVAC:OutdoorAirSystem,
    Refrig Cond AC PTAC OA System,                            !- Name
    Refrig Cond AC PTAC OA System Controller List,            !- Controller List Name
    Refrig Cond AC PTAC OA System Equipment List;             !- Outdoor Air Equipment List Name
  AirLoopHVAC:ControllerList,
    Refrig Cond AC PTAC OA System Controller List,            !- Name
    Controller:OutdoorAir,                                    !- Controller 1 Object Type
    Refrig Cond AC PTAC OA Controller;                        !- Controller 1 Name
  Controller:OutdoorAir,
    Refrig Cond AC PTAC OA Controller,                        !- Name
    Refrig Cond AC PTAC Relief Node,                          !- Relief Air Outlet Node Name
    Refrig Cond AC PTAC Supply Side Inlet Node,               !- Return Air Node Name
    Refrig Cond AC PTAC Mixed Air Node,                       !- Mixed Air Node Name
    Refrig Cond AC PTAC OA Node,                              !- Actuator Node Name
    0,                                                        !- Minimum Outdoor Air Flow Rate {m3/s}
    Autosize,                                                 !- Maximum Outdoor Air Flow Rate {m3/s}
    NoEconomizer,                                             !- Economizer Control Type
    ModulateFlow,                                             !- Economizer Control Action Type
    28,                                                       !- Economizer Maximum Limit Dry-Bulb Temperature {C}
    64000,                                                    !- Economizer Maximum Limit Enthalpy {J/kg}
    ,                                                         !- Economizer Maximum Limit Dewpoint Temperature {C}
    ,                                                         !- Electronic Enthalpy Limit Curve Name
    -100,                                                     !- Economizer Minimum Limit Dry-Bulb Temperature {C}
    NoLockout,                                                !- Lockout Type
    FixedMinimum,                                             !- Minimum Limit Type
    ,                                                         !- Minimum Outdoor Air Schedule Name
    ,                                                         !- Minimum Fraction of Outdoor Air Schedule Name
    ,                                                         !- Maximum Fraction of Outdoor Air Schedule Name
    Refrig Cond AC PTAC MV Controller,                        !- Mechanical Ventilation Controller Name
    ,                                                         !- Time of Day Economizer Control Schedule Name
    No,                                                       !- High Humidity Control
    ,                                                         !- Humidistat Control Zone Name
    ,                                                         !- High Humidity Outdoor Air Flow Ratio
    Yes,                                                      !- Control High Indoor Humidity Based on Outdoor Humidity Ratio
    BypassWhenWithinEconomizerLimits,                         !- Heat Recovery Bypass Control Type
    InterlockedWithMechanicalCooling;                         !- Economizer Operation Staging
  OutdoorAir:NodeList,
    Refrig Cond AC PTAC OA Node;                              !- Node or NodeList Name 1
  Controller:MechanicalVentilation,
    Refrig Cond AC PTAC MV Controller,                        !- Name
    ,                                                         !- Availability Schedule Name
    No,                                                       !- Demand Controlled Ventilation
    ZoneSum,                                                  !- System Outdoor Air Method
    ,                                                         !- Zone Maximum Outdoor Air Fraction {dimensionless}
    Refrig Cond AC Zone,                                      !- Zone or ZoneList 1 Name
    ,                                                         !- Design Specification Outdoor Air Object Name 1
    ;                                                         !- Design Specification Zone Air Distribution Object Name 1
  AirLoopHVAC:OutdoorAirSystem:EquipmentList,
    Refrig Cond AC PTAC OA System Equipment List,             !- Name
    OutdoorAir:Mixer,                                         !- Component 1 Object Type
    Refrig Cond AC PTAC OA System Outdoor Air Mixer;          !- Component 1 Name
  OutdoorAir:Mixer,
    Refrig Cond AC PTAC OA System Outdoor Air Mixer,          !- Name
    Refrig Cond AC PTAC Mixed Air Node,                       !- Mixed Air Node Name
    Refrig Cond AC PTAC OA Node,                              !- Outdoor Air Stream Node Name
    Refrig Cond AC PTAC Relief Node,                          !- Relief Air Stream Node Name
    Refrig Cond AC PTAC Supply Side Inlet Node;               !- Return Air Stream Node Name
  Coil:Cooling:DX:SingleSpeed,
    Refrig Cond AC PTAC Cooling Coil,                         !- Name
    ,                                                         !- Availability Schedule Name
    Autosize,                                                 !- Gross Rated Total Cooling Capacity {W}
    Autosize,                                                 !- Gross Rated Sensible Heat Ratio
    3,                                                        !- Gross Rated Cooling COP {W/W}
    Autosize,                                                 !- Rated Air Flow Rate {m3/s}
    773.3,                                                    !- 2017 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
    934.4,                                                    !- 2023 Rated Evaporator Fan Power Per Volume Flow Rate {W/(m3/s)}
    Refrig Cond AC PTAC Mixed Air Node,                       !- Air Inlet Node Name
    Refrig Cond AC PTAC Desuperheater Inlet Node,             !- Air Outlet Node Name
    Generic Curve,                                            !- Total Cooling Capacity Function of Temperature Curve Name
    Generic Curve,                                            !- Total Cooling Capacity Function of Flow Fraction Curve Name
    Generic Curve,                                            !- Energy Input Ratio Function of Temperature Curve Name
    Generic Curve,                                            !- Energy Input Ratio Function of Flow Fraction Curve Name
    Generic Curve,                                            !- Part Load Fraction Correlation Curve Name
    -25,                                                      !- Minimum Outdoor Dry-Bulb Temperature for Compressor Operation {C}
    0,                                                        !- Nominal Time for Condensate Removal to Begin {s}
    0,                                                        !- Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity {dimensionless}
    0,                                                        !- Maximum Cycling Rate {cycles/hr}
    0,                                                        !- Latent Capacity Time Constant {s}
    ,                                                         !- Condenser Air Inlet Node Name
    AirCooled,                                                !- Condenser Type
    0.9,                                                      !- Evaporative Condenser Effectiveness {dimensionless}
    Autosize,                                                 !- Evaporative Condenser Air Flow Rate {m3/s}
    Autosize,                                                 !- Evaporative Condenser Pump Rated Power Consumption {W}
    0,                                                        !- Crankcase Heater Capacity {W}
    ,                                                         !- Crankcase Heater Capacity Function of Temperature Curve Name
    10,                                                       !- Maximum Outdoor Dry-Bulb Temperature for Crankcase Heater Operation {C}
    ,                                                         !- Supply Water Storage Tank Name
    ,                                                         !- Condensate Collection Water Storage Tank Name
    0,                                                        !- Basin Heater Capacity {W/K}
    2;                                                        !- Basin Heater Setpoint Temperature {C}
  Coil:Heating:Desuperheater,
    Refrig Cond AC PTAC Desuperheater,                        !- Name
    ,                                                         !- Availability Schedule Name
    0.25,                                                     !- Refrig Cond AC PTAC Desuperheater Recovery Efficiency
    Refrig Cond AC PTAC Desuperheater Inlet Node,             !- Air Inlet Node Name
    Refrig Cond AC PTAC Desuperheater Outlet Node,            !- Air Outlet Node Name
    Refrigeration:Condenser:AirCooled,                        !- Heating Source Object Type
    Refrig Cond AC Refrig Condenser,                          !- Heating Source Name
    Refrig Cond AC PTAC Desuperheater Outlet Node;            !- Temperature Setpoint Node Name
  Coil:Heating:Fuel,
    Refrig Cond AC PTAC Heating Coil,                         !- Name
    ,                                                         !- Availability Schedule Name
    NaturalGas,                                               !- Fuel Type
    0.9,                                                      !- Burner Efficiency
    AutoSize,                                                 !- Nominal Capacity {W}
    Refrig Cond AC PTAC Desuperheater Outlet Node,            !- Air Inlet Node Name
    Refrig Cond AC PTAC Heating Coil Outlet Node,             !- Air Outlet Node Name
    Refrig Cond AC PTAC Heating Coil Outlet Node,             !- Temperature Setpoint Node Name
    0,                                                        !- On Cycle Parasitic Electric Load {W}
    ,                                                         !- Part Load Fraction Correlation Curve Name
    0;                                                        !- Off Cycle Parasitic Fuel Load {W}
  Fan:ConstantVolume,
    Refrig Cond AC PTAC Fan,                                  !- Name
    ,                                                         !- Availability Schedule Name
    0.7,                                                      !- Fan Total Efficiency
    500,                                                      !- Pressure Rise {Pa}
    AutoSize,                                                 !- Maximum Flow Rate {m3/s}
    0.9,                                                      !- Motor Efficiency
    1,                                                        !- Motor In Airstream Fraction
    Refrig Cond AC PTAC Heating Coil Outlet Node,             !- Air Inlet Node Name
    Refrig Cond AC PTAC Supply Side Outlet Node;              !- Air Outlet Node Name
  Refrigeration:System,
    Refrig Cond AC Refrig System,                             !- Name
    Refrig Cond AC CaseAndWalkInList,                         !- Refrigerated Case or Walkin or CaseAndWalkInList Name
    ,                                                         !- Refrigeration Transfer Load or TransferLoad List Name
    Refrig Cond AC Refrig Condenser,                          !- Refrigeration Condenser Name
    Refrig Cond AC Refrig Compressor,                         !- Compressor or CompressorList Name
    20,                                                       !- Minimum Condensing Temperature {C}
    R407a,                                                    !- Refrigeration System Working Fluid Type
    ConstantSuctionTemperature,                               !- Suction Temperature Control Type
    ,                                                         !- Mechanical Subcooler Name
    ,                                                         !- Liquid Suction Heat Exchanger Subcooler Name
    0,                                                        !- Sum UA Suction Piping {W/K}
    Refrig Cond AC Zone,                                      !- Suction Piping Zone Name
    General,                                                  !- End-Use Subcategory
    1,                                                        !- Number of Compressor Stages
    None,                                                     !- Intercooler Type
    0.8;                                                      !- Shell-and-Coil Intercooler Effectiveness
  Refrigeration:CaseAndWalkInList,
    Refrig Cond AC CaseAndWalkInList,                         !- Name
    Refrig Cond AC Case,                                      !- Case or Refrig Cond AC WalkIn Name
    Refrig Cond AC WalkIn;                                    !- Case or WalkIn 2 Name
  Refrigeration:Case,
    Refrig Cond AC Case,                                      !- Name
    ,                                                         !- Availability Schedule Name
    Refrig Cond AC Zone,                                      !- Zone Name
    24,                                                       !- Rated Ambient Temperature {C}
    55,                                                       !- Rated Ambient Relative Humidity {percent}
    1406,                                                     !- Rated Total Cooling Capacity per Unit Length {W/m}
    0.3,                                                      !- Rated Latent Heat Ratio
    0.85,                                                     !- Rated Runtime Fraction
    2.19,                                                     !- Case Length {m}
    4,                                                        !- Case Operating Temperature {C}
    CaseTemperatureMethod,                                    !- Latent Case Credit Curve Type
    Generic Curve,                                            !- Latent Case Credit Curve Name
    30,                                                       !- Standard Case Fan Power per Unit Length {W/m}
    30,                                                       !- Operating Case Fan Power per Unit Length {W/m}
    20,                                                       !- Standard Case Lighting Power per Unit Length {W/m}
    20,                                                       !- Installed Case Lighting Power per Unit Length {W/m}
    ,                                                         !- Case Lighting Schedule Name
    1,                                                        !- Fraction of Lighting Energy to Case
    0,                                                        !- Case Anti-Sweat Heater Power per Unit Length {W/m}
    0,                                                        !- Minimum Anti-Sweat Heater Power per Unit Length {W/m}
    None,                                                     !- Anti-Sweat Heater Control Type
    -10,                                                      !- Humidity at Zero Anti-Sweat Heater Energy {percent}
    1.5,                                                      !- Case Height {m}
    1,                                                        !- Fraction of Anti-Sweat Heater Energy to Case
    0,                                                        !- Case Defrost Power per Unit Length {W/m}
    OffCycle,                                                 !- Case Defrost Type
    AlwaysOn,                                                 !- Case Defrost Schedule Name
    ,                                                         !- Case Defrost Drip-Down Schedule Name
    None,                                                     !- Defrost Energy Correction Curve Type
    ,                                                         !- Defrost Energy Correction Curve Name
    0,                                                        !- Under Case HVAC Return Air Fraction
    ,                                                         !- Refrigerated Case Restocking Schedule Name
    ,                                                         !- Case Credit Fraction Schedule Name
    -7,                                                       !- Design Evaporator Temperature or Brine Inlet Temperature {C}
    0;                                                        !- Average Refrigerant Charge Inventory {kg/m}
  Refrigeration:WalkIn,
    Refrig Cond AC WalkIn,                                    !- Name
    ,                                                        