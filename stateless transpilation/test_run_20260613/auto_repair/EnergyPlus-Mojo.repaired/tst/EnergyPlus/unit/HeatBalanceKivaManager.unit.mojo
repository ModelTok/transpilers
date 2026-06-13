from testing import *
from math import log
from Fixtures.EnergyPlusFixture import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataZoneControls import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.HeatBalanceKivaManager import *
from EnergyPlus.HeatBalanceManager import *
from EnergyPlus.HeatBalanceSurfaceManager import *
from EnergyPlus.IOFiles import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.WeatherManager import *
from EnergyPlus.ZoneTempPredictorCorrector import *
from EnergyPlus.ConfiguredFunctions import *

# Helper functions (assuming they are defined in some utility module)
def pow_2(x: Float64) -> Float64:
    return x * x

def pow_3(x: Float64) -> Float64:
    return x * x * x

class EnergyPlusFixture:
    var state: EnergyPlusData

    def __init__(inout self):
        self.state = EnergyPlusData()

    # This is a simplified simulation of the fixture. In real test, it would be more.

# Test functions (translate each TEST_F)
def HeatBalanceKiva_SetInitialBCs() -> TestResult:
    var fnd = Kiva.Foundation()
    fnd.reductionStrategy = Kiva.Foundation.RS_AP
    var concrete = Kiva.Material(1.95, 2400.0, 900.0)
    var tempLayer = Kiva.Layer()
    tempLayer.thickness = 0.10
    tempLayer.material = concrete
    fnd.slab.interior.emissivity = 0.8
    fnd.slab.layers.append(tempLayer)
    tempLayer.thickness = 0.2
    tempLayer.material = concrete
    fnd.wall.layers.append(tempLayer)
    fnd.wall.heightAboveGrade = 0.1
    fnd.wall.depthBelowSlab = 0.2
    fnd.wall.interior.emissivity = 0.8
    fnd.wall.exterior.emissivity = 0.8
    fnd.wall.interior.absorptivity = 0.8
    fnd.wall.exterior.absorptivity = 0.8
    fnd.foundationDepth = 0.0
    fnd.numericalScheme = Kiva.Foundation.NS_ADI
    fnd.polygon.outer().append(Kiva.Point(-6.0, -6.0))
    fnd.polygon.outer().append(Kiva.Point(-6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, -6.0))
    var kivaweather = HeatBalanceKivaManager.KivaWeatherData()
    kivaweather.annualAverageDrybulbTemp = 10.0
    kivaweather.intervalsPerHour = 1
    kivaweather.dryBulb = [10.0]
    kivaweather.windSpeed = [0.0]
    kivaweather.skyEmissivity = [0.0]
    var km = HeatBalanceKivaManager.KivaManager()
    # Simulate idf_objects as a string (replace delimited_string with literal newline)
    var idf_objects: String = (
        "Zone,\n"
        "  Core_bottom,             !- Name\n"
        "  0.0000,                  !- Direction of Relative North {deg}\n"
        "  0.0000,                  !- X Origin {m}\n"
        "  0.0000,                  !- Y Origin {m}\n"
        "  0.0000,                  !- Z Origin {m}\n"
        "  1,                       !- Type\n"
        "  1,                       !- Multiplier\n"
        "  ,                        !- Ceiling Height {m}\n"
        "  ,                        !- Volume {m3}\n"
        "  autocalculate,           !- Floor Area {m2}\n"
        "  ,                        !- Zone Inside Convection Algorithm\n"
        "  ,                        !- Zone Outside Convection Algorithm\n"
        "  Yes;                     !- Part of Total Floor Area\n"
        " \n"
        "ZoneControl:Thermostat,\n"
        "  Core_bottom Thermostat,  !- Name\n"
        "  Core_bottom,             !- Zone or ZoneList Name\n"
        "  Dual Zone Control Type Sched,  !- Control Type Schedule Name\n"
        "  ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type\n"
        "  Core_bottom DualSPSched; !- Control 1 Name\n"
        " \n"
        "Schedule:Constant,\n"
        "  Dual Zone Control Type Sched,  !- Name\n"
        "  Control Type,            !- Schedule Type Limits Name\n"
        "  4;                       !- Field 1\n"
        " \n"
        "ThermostatSetpoint:DualSetpoint,\n"
        "  Core_bottom DualSPSched, !- Name\n"
        "  HTGSETP_SCH,             !- Heating Setpoint Temperature Schedule Name\n"
        "  CLGSETP_SCH;             !- Cooling Setpoint Temperature Schedule Name\n"
        " \n"
        "Schedule:Constant,\n"
        "  CLGSETP_SCH,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  24.0;                    !- Field 1\n"
        " \n"
        "Schedule:Constant,\n"
        "  HTGSETP_SCH,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  20.0;                    !- Field 1\n"
        " \n"
        "Schedule:Constant,\n"
        "  CLGSETP_SCH_EXTREME,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  100.0;                    !- Field 1\n"
        " \n"
        "Schedule:Constant,\n"
        "  HTGSETP_SCH_EXTREME,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  -100.0;                    !- Field 1\n"
        " \n"
    )
    # Assume process_idf is defined
    assert process_idf(idf_objects) == True
    var state_ref = &state  # using a global state? In test we need a fixture.
    # The test uses state-> (C-style). In Mojo we'll use a fixture approach.
    # We'll create a fixture instance. For brevity, we'll just use a global variable.
    # In real translation, we'd have fixture class.
    var s = EnergyPlusFixture()
    s.state.dataGlobal.TimeStepsInHour = 1
    s.state.dataGlobal.MinutesInTimeStep = 60
    s.state.init_state(s.state)  # assuming init_state is a method
    var ErrorsFound = False
    HeatBalanceManager.GetZoneData(s.state, ErrorsFound)  # This is a free function? In C++ it's HeatBalanceManager::GetZoneData
    assert ErrorsFound == False
    var DualZoneNum = 1
    s.state.dataEnvrn.DayOfYear_Schedule = 1
    s.state.dataEnvrn.DayOfWeek = 1
    s.state.dataGlobal.HourOfDay = 1
    s.state.dataGlobal.TimeStep = 1
    ZoneTempPredictorCorrector.GetZoneAirSetPoints(s.state)
    s.state.dataZoneCtrls.TempControlledZone[DualZoneNum-1].setptTypeSched.currentVal = Int(HVAC.SetptType.DualHeatCool)  # 0-based index
    var zoneAssumedTemperature1: Float64 = 15.0
    var kv1 = HeatBalanceKivaManager.KivaInstanceMap(s.state, fnd, 0, List[Int64](), 0, zoneAssumedTemperature1, 1.0, 0, &km)
    kv1.zoneControlNum = 1
    kv1.zoneControlType = 1
    kv1.setInitialBoundaryConditions(s.state, kivaweather, 1, 1, 1)
    var expectedResult1 = kv1.instance.bcs.slabConvectiveTemp
    expectApproxEq(expectedResult1, zoneAssumedTemperature1 + Constant.Kelvin, 0.001)
    var heatingSetpoint2: Float64 = 20.0
    var zoneAssumedTemperature2: Float64 = -9999.0
    var kv2 = HeatBalanceKivaManager.KivaInstanceMap(s.state, fnd, 0, List[Int64](), 0, zoneAssumedTemperature2, 1.0, 0, &km)
    kv2.zoneControlNum = 1
    kv2.zoneControlType = 1
    kv2.setInitialBoundaryConditions(s.state, kivaweather, 1, 1, 1)
    var expectedResult2 = kv2.instance.bcs.slabConvectiveTemp
    expectApproxEq(expectedResult2, heatingSetpoint2 + Constant.Kelvin, 0.001)
    s.state.dataZoneCtrls.TempControlledZone[0].setpts[Int(HVAC.SetptType.DualHeatCool)].coolSetptSched = Sched.GetSchedule(s.state, "CLGSETP_SCH_EXTREME")
    s.state.dataZoneCtrls.TempControlledZone[0].setpts[Int(HVAC.SetptType.DualHeatCool)].heatSetptSched = Sched.GetSchedule(s.state, "HTGSETP_SCH_EXTREME")
    var heatingSetpoint3: Float64 = -100.0
    var zoneAssumedTemperature3: Float64 = -9999.0
    var kv3 = HeatBalanceKivaManager.KivaInstanceMap(s.state, fnd, 0, List[Int64](), 0, zoneAssumedTemperature3, 1.0, 0, &km)
    kv3.zoneControlNum = 1
    kv3.zoneControlType = 1
    kv3.setInitialBoundaryConditions(s.state, kivaweather, 1, 1, 1)
    var expectedResult3 = kv3.instance.bcs.slabConvectiveTemp
    expectApproxEq(expectedResult3, heatingSetpoint3 + Constant.Kelvin, 0.001)
    s.state.dataZoneCtrls.TempControlledZone[0].setpts[Int(HVAC.SetptType.DualHeatCool)].coolSetptSched = Sched.GetSchedule(s.state, "CLGSETP_SCH_EXTREME")
    s.state.dataZoneCtrls.TempControlledZone[0].setpts[Int(HVAC.SetptType.DualHeatCool)].heatSetptSched = Sched.GetSchedule(s.state, "HTGSETP_SCH_EXTREME")
    var zoneAssumedTemperature4: Float64 = 15.0
    var kv4 = HeatBalanceKivaManager.KivaInstanceMap(s.state, fnd, 0, List[Int64](), 0, zoneAssumedTemperature4, 1.0, 0, &km)
    kv4.zoneControlNum = 1
    kv4.zoneControlType = 1
    kv4.setInitialBoundaryConditions(s.state, kivaweather, 1, 1, 1)
    var expectedResult4 = kv4.instance.bcs.slabConvectiveTemp
    expectApproxEq(expectedResult4, zoneAssumedTemperature4 + Constant.Kelvin, 0.001)
    return TestResult(passed=True)

def HeatBalanceKiva_setupKivaInstances_ThermalComfort() -> TestResult:
    var fnd = Kiva.Foundation()
    fnd.reductionStrategy = Kiva.Foundation.RS_AP
    var concrete = Kiva.Material(1.95, 2400.0, 900.0)
    var tempLayer = Kiva.Layer()
    tempLayer.thickness = 0.10
    tempLayer.material = concrete
    fnd.slab.interior.emissivity = 0.8
    fnd.slab.layers.append(tempLayer)
    tempLayer.thickness = 0.2
    tempLayer.material = concrete
    fnd.wall.layers.append(tempLayer)
    fnd.wall.heightAboveGrade = 0.1
    fnd.wall.depthBelowSlab = 0.2
    fnd.wall.interior.emissivity = 0.8
    fnd.wall.exterior.emissivity = 0.8
    fnd.wall.interior.absorptivity = 0.8
    fnd.wall.exterior.absorptivity = 0.8
    fnd.foundationDepth = 0.0
    fnd.numericalScheme = Kiva.Foundation.NS_ADI
    fnd.polygon.outer().append(Kiva.Point(-6.0, -6.0))
    fnd.polygon.outer().append(Kiva.Point(-6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, -6.0))
    var kivaweather = HeatBalanceKivaManager.KivaWeatherData()
    kivaweather.annualAverageDrybulbTemp = 10.0
    kivaweather.intervalsPerHour = 1
    kivaweather.dryBulb = [10.0]
    kivaweather.windSpeed = [0.0]
    kivaweather.skyEmissivity = [0.0]
    var km = HeatBalanceKivaManager.KivaManager()
    var idf_objects: String = (
        "Material,\n"
        "  1/2IN Gypsum,            !- Name\n"
        "  Smooth,                  !- Roughness\n"
        "  0.0127,                  !- Thickness {m}\n"
        "  0.1600,                  !- Conductivity {W/m-K}\n"
        "  784.9000,                !- Density {kg/m3}\n"
        "  830.0000,                !- Specific Heat {J/kg-K}\n"
        "  0.9000,                  !- Thermal Absorptance\n"
        "  0.9200,                  !- Solar Absorptance\n"
        "  0.9200;                  !- Visible Absorptance\n"
        " \n"
        "Material,\n"
        "  MAT-CC05 4 HW CONCRETE,  !- Name\n"
        "  Rough,                   !- Roughness\n"
        "  0.1016,                  !- Thickness {m}\n"
        "  1.3110,                  !- Conductivity {W/m-K}\n"
        "  2240.0000,               !- Density {kg/m3}\n"
        "  836.8000,                !- Specific Heat {J/kg-K}\n"
        "  0.9000,                  !- Thermal Absorptance\n"
        "  0.7000,                  !- Solar Absorptance\n"
        "  0.7000;                  !- Visible Absorptance\n"
        " \n"
        "Material:NoMass,\n"
        "  CP02 CARPET PAD,         !- Name\n"
        "  VeryRough,               !- Roughness\n"
        "  0.2165,                  !- Thermal Resistance {m2-K/W}\n"
        "  0.9000,                  !- Thermal Absorptance\n"
        "  0.7000,                  !- Solar Absorptance\n"
        "  0.8000;                  !- Visible Absorptance\n"
        " \n"
        "Material,\n"
        "  Std AC02,                !- Name\n"
        "  MediumSmooth,            !- Roughness\n"
        "  1.2700000E-02,           !- Thickness {m}\n"
        "  5.7000000E-02,           !- Conductivity {W/m-K}\n"
        "  288.0000,                !- Density {kg/m3}\n"
        "  1339.000,                !- Specific Heat {J/kg-K}\n"
        "  0.9000000,               !- Thermal Absorptance\n"
        "  0.7000000,               !- Solar Absorptance\n"
        "  0.2000000;               !- Visible Absorptance\n"
        " \n"
        "Construction,\n"
        "  int-walls,               !- Name\n"
        "  1/2IN Gypsum,            !- Outside Layer\n"
        "  1/2IN Gypsum;            !- Layer 2\n"
        " \n"
        "Construction,\n"
        "  INT-FLOOR-TOPSIDE,       !- Name\n"
        "  MAT-CC05 4 HW CONCRETE,  !- Outside Layer\n"
        "  CP02 CARPET PAD;         !- Layer 2\n"
        " \n"
        "Construction,\n"
        "  DropCeiling,             !- Name\n"
        "  Std AC02;                !- Outside Layer\n"
        " \n"
        "Zone,\n"
        "  Core_bottom,             !- Name\n"
        "  0.0000,                  !- Direction of Relative North {deg}\n"
        "  0.0000,                  !- X Origin {m}\n"
        "  0.0000,                  !- Y Origin {m}\n"
        "  0.0000,                  !- Z Origin {m}\n"
        "  1,                       !- Type\n"
        "  1,                       !- Multiplier\n"
        "  ,                        !- Ceiling Height {m}\n"
        "  ,                        !- Volume {m3}\n"
        "  autocalculate,           !- Floor Area {m2}\n"
        "  ,                        !- Zone Inside Convection Algorithm\n"
        "  ,                        !- Zone Outside Convection Algorithm\n"
        "  Yes;                     !- Part of Total Floor Area\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Ceiling,   !- Name\n"
        "  Ceiling,                 !- Surface Type\n"
        "  DropCeiling,             !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  4.5732,44.1650,2.7440,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  4.5732,4.5732,2.7440,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  68.5340,4.5732,2.7440,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  68.5340,44.1650,2.7440;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Floor,     !- Name\n"
        "  Floor,                   !- Surface Type\n"
        "  INT-FLOOR-TOPSIDE,       !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  68.5340,44.1650,0.0000,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  68.5340,4.5732,0.0000,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  4.5732,4.5732,0.0000,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  4.5732,44.1650,0.0000;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Wall_East, !- Name\n"
        "  Wall,                    !- Surface Type\n"
        "  int-walls,               !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  68.5340,4.5732,2.7440,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  68.5340,4.5732,0.0000,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  68.5340,44.1650,0.0000,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  68.5340,44.1650,2.7440;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Wall_North,!- Name\n"
        "  Wall,                    !- Surface Type\n"
        "  int-walls,               !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  68.5340,44.1650,2.7440,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  68.5340,44.1650,0.0000,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  4.5732,44.1650,0.0000,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  4.5732,44.1650,2.7440;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Wall_South,!- Name\n"
        "  Wall,                    !- Surface Type\n"
        "  int-walls,               !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  4.5732,4.5732,2.7440,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  4.5732,4.5732,0.0000,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  68.5340,4.5732,0.0000,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  68.5340,4.5732,2.7440;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "BuildingSurface:Detailed,\n"
        "  Core_bot_ZN_5_Wall_West, !- Name\n"
        "  Wall,                    !- Surface Type\n"
        "  int-walls,               !- Construction Name\n"
        "  Core_bottom,             !- Zone Name\n"
        "  ,                        !- Space Name\n"
        "  Adiabatic,               !- Outside Boundary Condition\n"
        "  ,                        !- Outside Boundary Condition Object\n"
        "  NoSun,                   !- Sun Exposure\n"
        "  NoWind,                  !- Wind Exposure\n"
        "  AutoCalculate,           !- View Factor to Ground\n"
        "  4,                       !- Number of Vertices\n"
        "  4.5732,44.1650,2.7440,  !- X,Y,Z ==> Vertex 1 {m}\n"
        "  4.5732,44.1650,0.0000,  !- X,Y,Z ==> Vertex 2 {m}\n"
        "  4.5732,4.5732,0.0000,  !- X,Y,Z ==> Vertex 3 {m}\n"
        "  4.5732,4.5732,2.7440;  !- X,Y,Z ==> Vertex 4 {m}\n"
        " \n"
        "People,\n"
        "  Core_bottom People,      !- Name\n"
        "  Core_bottom,             !- Zone or ZoneList Name\n"
        "  Core_bottom Occupancy,   !- Number of People Schedule Name\n"
        "  People,                  !- Number of People Calculation Method\n"
        "  4,                       !- Number of People\n"
        "  ,                        !- People per Zone Floor Area\n"
        "  ,                        !- Zone Floor Area per Person\n"
        "  0.9,                     !- Fraction Radiant\n"
        "  0.1,                     !- Sensible Heat Fraction\n"
        "  Core_bottom Activity,    !- Activity Level Schedule Name\n"
        "  3.82e-08,                !- Carbon Dioxide Generation Rate\n"
        "  Yes,                     !- Enable ASHRAE 55 Comfort Warnings\n"
        "  EnclosureAveraged,            !- Mean Radiant Temperature Calculation Type\n"
        "  ,                        !- Surface NameAngle Factor List Name\n"
        "  Work Eff Sched,          !- Work Efficiency Schedule Name\n"
        "  ClothingInsulationSchedule,  !- Clothing Insulation Calculation Method\n"
        "  ,                        !- Clothing Insulation Calculation Method Schedule Name\n"
        "  Clothing Schedule,       !- Clothing Insulation Schedule Name\n"
        "  Air Velocity Schedule,   !- Air Velocity Schedule Name\n"
        "  Fanger;                  !- Thermal Comfort Model 1 Type\n"
        " \n"
        "Schedule:Compact,\n"
        "  Core_bottom Occupancy,   !- Name\n"
        "  Fraction,                !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: Alldays,            !- Field 2\n"
        "  Until: 07:00,            !- Field 3\n"
        "  0,                       !- Field 4\n"
        "  Until: 21:00,            !- Field 13\n"
        "  1,                       !- Field 14\n"
        "  Until: 24:00,            !- Field 15\n"
        "  0;                       !- Field 16\n"
        " \n"
        "Schedule:Compact,\n"
        "  Core_bottom Activity,    !- Name\n"
        "  Activity Level,          !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: Alldays,            !- Field 2\n"
        "  Until: 24:00,            !- Field 3\n"
        "  166;                     !- Field 4\n"
        " \n"
        "Schedule:Compact,\n"
        "  Work Eff Sched,          !- Name\n"
        "  Dimensionless,           !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: AllDays,            !- Field 2\n"
        "  Until: 24:00,            !- Field 3\n"
        "  0;                       !- Field 4\n"
        " \n"
        "Schedule:Compact,\n"
        "  Clothing Schedule,       !- Name\n"
        "  Any Number,              !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: AllDays,            !- Field 2\n"
        "  Until: 24:00,            !- Field 3\n"
        "  0.5;                     !- Field 4\n"
        " \n"
        "Schedule:Compact,\n"
        "  Air Velocity Schedule,   !- Name\n"
        "  Velocity,                !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: AllDays,            !- Field 2\n"
        "  Until: 24:00,            !- Field 3\n"
        "  0.129999995231628;       !- Field 4\n"
        " \n"
        "ZoneControl:Thermostat,\n"
        "  Core_bottom Thermostat,  !- Name\n"
        "  Core_bottom,             !- Zone or ZoneList Name\n"
        "  Dual Zone Control Type Sched,  !- Control Type Schedule Name\n"
        "  ThermostatSetpoint:DualSetpoint,  !- Control 1 Object Type\n"
        "  Core_bottom DualSPSched; !- Control 1 Name\n"
        " \n"
        "ZoneControl:Thermostat:ThermalComfort,\n"
        "  Core_bottom Comfort,     !- Name\n"
        "  Core_bottom,             !- Zone or ZoneList Name\n"
        "  SpecificObject,          !- Averaging Method\n"
        "  Core_bottom People,      !- Specific People Name\n"
        "  0,                       !- Minimum DryBulb Temperature Setpoint\n"
        "  50,                      !- Maximum DryBulb Temperature Setpoint\n"
        "  Comfort Control,         !- Thermal Comfort Control Type Schedule Name\n"
        "  ThermostatSetpoint:ThermalComfort:Fanger:SingleHeating,    !- Thermal Comfort Control 1 Object Type\n"
        "  Single Htg PMV,          !- Thermal Comfort Control 1 Name\n"
        "  ThermostatSetpoint:ThermalComfort:Fanger:SingleCooling,    !- Thermal Comfort Control 2 Object Type\n"
        "  Single Cooling PMV;      !- Thermal Comfort Control 2 Name,\n"
        " \n"
        "Schedule:Compact,\n"
        "  Comfort Control,          !- Name\n"
        "  Control Type,             !- Schedule Type Limits Name\n"
        "  Through: 5/31,            !- Field 1\n"
        "  For: AllDays,             !- Field 2\n"
        "  Until: 24:00,             !- Field 3\n"
        "  1,                        !- Field 4\n"
        "  Through: 8/31,            !- Field 5\n"
        "  For: AllDays,             !- Field 6\n"
        "  Until: 24:00,             !- Field 7\n"
        "  2,                        !- Field 8\n"
        "  Through: 12/31,           !- Field 9\n"
        "  For: AllDays,             !- Field 10\n"
        "  Until: 24:00,             !- Field 11\n"
        "  1;                        !- Field 12\n"
        " \n"
        "THERMOSTATSETPOINT:THERMALCOMFORT:FANGER:SINGLEHEATING,\n"
        "  Single Htg PMV,          !- Name\n"
        "  Single Htg PMV;          !- Fanger Thermal Comfort Schedule Name\n"
        " \n"
        "THERMOSTATSETPOINT:THERMALCOMFORT:FANGER:SINGLECOOLING,\n"
        "  Single Cooling PMV,      !- Name\n"
        "  Single Cooling PMV;      !- Fanger Thermal Comfort Schedule Name\n"
        " \n"
        "Schedule:Constant,\n"
        "  Dual Zone Control Type Sched,  !- Name\n"
        "  Control Type,            !- Schedule Type Limits Name\n"
        "  4;                       !- Field 1\n"
        " \n"
        "ThermostatSetpoint:DualSetpoint,\n"
        "  Core_bottom DualSPSched, !- Name\n"
        "  HTGSETP_SCH,             !- Heating Setpoint Temperature Schedule Name\n"
        "  CLGSETP_SCH;             !- Cooling Setpoint Temperature Schedule Name\n"
        " \n"
        "Schedule:Constant,\n"
        "  CLGSETP_SCH,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  24.0;                    !- Field 1\n"
        " \n"
        "Schedule:Constant,\n"
        "  HTGSETP_SCH,             !- Name\n"
        "  Temperature,             !- Schedule Type Limits Name\n"
        "  20.0;                    !- Field 1\n"
        " \n"
        "Schedule:Compact,\n"
        "  Single Htg PMV,          !- Name\n"
        "  Any Number,              !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: AllDays,            !- Field 2\n"
        "  Until: 6:00,             !- Field 3\n"
        "  -0.5,                    !- Field 4\n"
        "  Until: 23:00,            !- Field 5\n"
        "  -0.2,                    !- Field 6\n"
        "  Until: 24:00,            !- Field 7\n"
        "  -0.5;                    !- Field 8\n"
        " \n"
        "Schedule:Compact,\n"
        "  Single Cooling PMV,      !- Name\n"
        "  Any Number,              !- Schedule Type Limits Name\n"
        "  Through: 12/31,          !- Field 1\n"
        "  For: AllDays,            !- Field 2\n"
        "  Until: 6:00,             !- Field 3\n"
        "  0.5,                     !- Field 4\n"
        "  Until: 23:00,            !- Field 5\n"
        "  0.2,                     !- Field 6\n"
        "  Until: 24:00,            !- Field 7\n"
        "  0.5;                     !- Field 8\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Fraction,                 !- Name\n"
        "  0,                        !- Lower Limit Value\n"
        "  1,                        !- Upper Limit Value\n"
        "  Continuous,               !- Numeric Type\n"
        "  Dimensionless;            !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Temperature,              !- Name\n"
        "  -60,                      !- Lower Limit Value\n"
        "  200,                      !- Upper Limit Value\n"
        "  Continuous,               !- Numeric Type\n"
        "  Temperature;              !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Control Type,             !- Name\n"
        "  0,                        !- Lower Limit Value\n"
        "  4,                        !- Upper Limit Value\n"
        "  Discrete,                 !- Numeric Type\n"
        "  Dimensionless;            !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  On/Off,                   !- Name\n"
        "  0,                        !- Lower Limit Value\n"
        "  1,                        !- Upper Limit Value\n"
        "  Discrete,                 !- Numeric Type\n"
        "  Dimensionless;            !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Any Number,               !- Name\n"
        "  ,                         !- Lower Limit Value\n"
        "  ,                         !- Upper Limit Value\n"
        "  Continuous;               !- Numeric Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Velocity,                 !- Name\n"
        "  ,                         !- Lower Limit Value\n"
        "  ,                         !- Upper Limit Value\n"
        "  Continuous,               !- Numeric Type\n"
        "  Velocity;                 !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Activity Level,           !- Name\n"
        "  0,                        !- Lower Limit Value\n"
        "  ,                         !- Upper Limit Value\n"
        "  Continuous,               !- Numeric Type\n"
        "  ActivityLevel;            !- Unit Type\n"
        " \n"
        "ScheduleTypeLimits,\n"
        "  Dimensionless,            !- Name\n"
        "  -1,                       !- Lower Limit Value\n"
        "  1,                        !- Upper Limit Value\n"
        "  Continuous;               !- Numeric Type\n"
    )
    assert process_idf(idf_objects) == True
    var s = EnergyPlusFixture()
    s.state.dataGlobal.TimeStepsInHour = 1
    s.state.dataGlobal.MinutesInTimeStep = 60
    s.state.init_state(s.state)
    var ErrorsFound = False
    assert ErrorsFound == False
    s.state.dataEnvrn.DayOfYear_Schedule = 1
    s.state.dataEnvrn.DayOfWeek = 1
    s.state.dataGlobal.HourOfDay = 1
    s.state.dataGlobal.TimeStep = 1
    s.state.files.inputWeatherFilePath.filePath = configured_source_directory() / "tst/EnergyPlus/unit/Resources/HeatBalanceKivaManagerOSkyTest.epw"
    HeatBalanceManager.GetHeatBalanceInput(s.state)
    # EXPECT_FALSE(has_err_output()) -> check error output; simplified
    assert has_err_output() == False
    return TestResult(passed=True)

def OpaqueSkyCover_InterpretWeatherMissingOpaqueSkyCover() -> TestResult:
    var s = EnergyPlusFixture()
    s.state.files.inputWeatherFilePath.filePath = configured_source_directory() / "tst/EnergyPlus/unit/Resources/HeatBalanceKivaManagerOSkyTest.epw"
    s.state.dataWeather.wvarsMissing.OpaqueSkyCover = 5
    var km = HeatBalanceKivaManager.KivaManager()
    km.readWeatherData(s.state)
    var TDewK: Float64 = 264.25
    var expected_OSky: Float64 = 5.0
    var expected_ESky = (0.787 + 0.764 * log(TDewK / Constant.Kelvin)) * (1.0 + 0.0224 * expected_OSky - 0.0035 * pow_2(expected_OSky) + 0.00028 * pow_3(expected_OSky))
    expectApproxEq(expected_ESky, km.kivaWeather.skyEmissivity[0], 0.01)
    return TestResult(passed=True)

def HeatBalanceKiva_DeepGroundDepthCheck() -> TestResult:
    var fnd = Kiva.Foundation()
    fnd.wall.heightAboveGrade = 0.1
    fnd.wall.depthBelowSlab = 0.2
    fnd.foundationDepth = 10.0
    fnd.deepGroundDepth = 5.0
    var initDeepGroundDepth = fnd.deepGroundDepth
    var km = HeatBalanceKivaManager.KivaManager()
    fnd.deepGroundDepth = km.getDeepGroundDepth(fnd)
    var totalDepthOfWallBelowGrade = fnd.wall.depthBelowSlab + (fnd.foundationDepth - fnd.wall.heightAboveGrade) + fnd.slab.totalWidth()
    var expectedValue = totalDepthOfWallBelowGrade + 1.0
    assert initDeepGroundDepth != fnd.deepGroundDepth
    assert expectedValue == fnd.deepGroundDepth
    return TestResult(passed=True)

def HeatBalanceKiva_GetAccDate() -> TestResult:
    var fnd = Kiva.Foundation()
    fnd.reductionStrategy = Kiva.Foundation.RS_AP
    var concrete = Kiva.Material(1.95, 2400.0, 900.0)
    var tempLayer = Kiva.Layer()
    tempLayer.thickness = 0.10
    tempLayer.material = concrete
    fnd.slab.interior.emissivity = 0.8
    fnd.slab.layers.append(tempLayer)
    tempLayer.thickness = 0.2
    tempLayer.material = concrete
    fnd.wall.layers.append(tempLayer)
    fnd.wall.heightAboveGrade = 0.1
    fnd.wall.depthBelowSlab = 0.2
    fnd.wall.interior.emissivity = 0.8
    fnd.wall.exterior.emissivity = 0.8
    fnd.wall.interior.absorptivity = 0.8
    fnd.wall.exterior.absorptivity = 0.8
    fnd.foundationDepth = 0.0
    fnd.numericalScheme = Kiva.Foundation.NS_ADI
    fnd.polygon.outer().append(Kiva.Point(-6.0, -6.0))
    fnd.polygon.outer().append(Kiva.Point(-6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, 6.0))
    fnd.polygon.outer().append(Kiva.Point(6.0, -6.0))
    var km = HeatBalanceKivaManager.KivaManager()
    var s = EnergyPlusFixture()
    var kv = HeatBalanceKivaManager.KivaInstanceMap(s.state, fnd, 0, List[Int64](), 0, 15.0, 1.0, 0, &km)
    s.state.dataEnvrn.DayOfYear = 121
    var numAccelaratedTimesteps = 3
    var acceleratedTimestep = 30
    var accDate = kv.getAccDate(s.state, numAccelaratedTimesteps, acceleratedTimestep)
    assert accDate > 0
    return TestResult(passed=True)

def HeatBalanceKiva_setMessageCallback() -> TestResult:
    var s = EnergyPlusFixture()
    var SurfNum = 1
    s.state.dataSurface.Surface.allocate(1)
    s.state.dataSurface.Surface[SurfNum-1].ExtBoundCond = DataSurfaces.KivaFoundation
    s.state.dataSurface.Surface[SurfNum-1].Name = "Kiva Floor"
    s.state.dataSurface.AllHTKivaSurfaceList = [1]
    var km = HeatBalanceKivaManager.KivaManager()
    # EXPECT_THROW -> wrap in try
    var caught = False
    try:
        km.calcKivaSurfaceResults(s.state)
    except:
        caught = True
    assert caught == True
    var error_string: String = (
        "   ** Severe  ** Surface=\"Kiva Floor\": The weights of associated Kiva instances do not add to unity--check exposed perimeter values.\n"
        "   **  Fatal  ** Kiva: Errors discovered, program terminates.\n"
        "   ...Summary of Errors that led to program termination:\n"
        "   ..... Reference severe error count=1\n"
        "   ..... Last severe error=Surface=\"Kiva Floor\": The weights of associated Kiva instances do not add to "
        "unity--check exposed perimeter values.\n"
    )
    # compare_err_stream -> assume compare_err_stream returns bool
    assert compare_err_stream(error_string, True) == True
    return TestResult(passed=True)

# Main test runner
def main():
    var tests = List[fn() -> TestResult]()
    tests.append(HeatBalanceKiva_SetInitialBCs)
    tests.append(HeatBalanceKiva_setupKivaInstances_ThermalComfort)
    tests.append(OpaqueSkyCover_InterpretWeatherMissingOpaqueSkyCover)
    tests.append(HeatBalanceKiva_DeepGroundDepthCheck)
    tests.append(HeatBalanceKiva_GetAccDate)
    tests.append(HeatBalanceKiva_setMessageCallback)
    for test_fn in tests:
        var result = test_fn()
        if not result.passed:
            print("Test failed")
            return
    print("All tests passed")