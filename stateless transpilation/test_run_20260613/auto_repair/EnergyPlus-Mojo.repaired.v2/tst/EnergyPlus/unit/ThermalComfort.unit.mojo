from testing import test, expect_equal, expect_true, expect_almost_equal, assert
from EnergyPlus.ConfiguredFunctions import *
from EnergyPlus.Construction import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.DataHeatBalFanSys import *
from EnergyPlus.DataHeatBalSurface import *
from EnergyPlus.DataHeatBalance import *
from EnergyPlus.DataRoomAirModel import *
from EnergyPlus.DataSurfaces import *
from EnergyPlus.DataViewFactorInformation import *
from EnergyPlus.DataZoneEnergyDemands import *
from EnergyPlus.IOFiles import *
from EnergyPlus.Psychrometrics import *
from EnergyPlus.ScheduleManager import *
from EnergyPlus.SimulationManager import *
from EnergyPlus.ThermalComfort import *
from EnergyPlus.ZoneTempPredictorCorrector import *

def delimited_string(lines: List[String]) -> String:
    var result = ""
    for line in lines:
        result += line + "\n"
    return result

@test
def ThermalComfort_CalcIfSetPointMetTest1():
    state.dataGlobal.NumOfZones = 1
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand = DynamicVector[ZoneSysEnergyDemandData](state.dataGlobal.NumOfZones)
    state.dataThermalComforts.ThermalComfortSetPoint = DynamicVector[ThermalComfortSetPointData](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.TempControlType = DynamicVector[Int](1)
    state.dataRoomAir.AirModel = DynamicVector[RoomAirModelData](state.dataGlobal.NumOfZones)
    state.dataRoomAir.AirModel[0].AirModel = RoomAir.RoomAirModel.Mixing
    state.dataZoneTempPredictorCorrector.zoneHeatBalance = DynamicVector[ZoneHeatBalanceData](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.zoneTstatSetpts = DynamicVector[ZoneTstatSetptsData](state.dataGlobal.NumOfZones)
    state.dataGlobal.TimeStepZone = 0.25
    state.dataThermalComforts.ThermalComfortInASH55 = DynamicVector[ThermalComfortInASH55Data](state.dataGlobal.NumOfZones)
    state.dataThermalComforts.ThermalComfortInASH55[0].ZoneIsOccupied = true
    state.dataHeatBal.Zone = DynamicVector[ZoneData](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleHeat
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 21.1           # 70F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.2                     # 72F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 500.0 # must be greater than zero
    CalcIfSetPointMet(state)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 25.0            # 77F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9                      # 75F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = -500.0 # must be less than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleCool
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 21.1           # 70F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.2                     # 72F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 500.0 # must be greater than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 25.0            # 77F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9                      # 75F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = -500.0 # must be less than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.SingleHeatCool
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 21.1           # 70F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.2                     # 72F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 500.0 # must be greater than zero
    CalcIfSetPointMet(state)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 25.0            # 77F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9                      # 75F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = -500.0 # must be less than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 21.1           # 70F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.2                     # 72F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 500.0 # must be greater than zero
    CalcIfSetPointMet(state)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 25.0            # 77F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9                      # 75F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = -500.0 # must be less than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)

@test
def ThermalComfort_CalcThermalComfortFanger():
    let const idf_objects = delimited_string([
        "  People,                                                                 ",
        "    Space People,   !- Name                                      ",
        "    Space,     !- Zone or ZoneList Name                     ",
        "    PeopleSchedule,          !- Number of People Schedule Name            ",
        "    People,                  !- Number of People Calculation Method       ",
        "    5.0,                     !- Number of People                          ",
        "    ,                        !- People per Zone Floor Area {person/m2}    ",
        "    ,                        !- Zone Floor Area per Person {m2/person}    ",
        "    0.3,                     !- Fraction Radiant                          ",
        "    AUTOCALCULATE,           !- Sensible Heat Fraction                    ",
        "    Activity Schedule,       !- Activity Level Schedule Name              ",
        "    ,                        !- Carbon Dioxide Generation Rate {m3/s-W}   ",
        "    Yes,                     !- Enable ASHRAE 55 Comfort Warnings         ",
        "    EnclosureAveraged,            !- Mean Radiant Temperature Calculation Type ",
        "    ,                        !- Surface Name/Angle Factor List Name       ",
        "    Work efficiency,         !- Work Efficiency Schedule Name             ",
        "    ClothingInsulationSchedule,  !- Clothing Insulation Calculation Method",
        "    ,                        !- Clothing Insulation Calculation Method Sch",
        "    Clothing Schedule,       !- Clothing Insulation Schedule Name         ",
        "    AirVelocitySchedule,     !- Air Velocity Schedule Name                ",
        "    Fanger;                  !- Thermal Comfort Model 1 Type              ",
        "                                                                          ",
        "  Schedule:Compact,                                                       ",
        "    PeopleSchedule,          !- Name                                      ",
        "    Any Number,              !- Schedule Type Limits Name                 ",
        "    Through: 12/30,          !- Field 1                                   ",
        "    For: AllDays,            !- Field 2                                   ",
        "    Until: 24:00,1.0,        !- Field 3                                   ",
        "    Through: 12/31,          !- Field 1                                   ",
        "    For: AllDays,            !- Field 2                                   ",
        "    Until: 24:00,0.3;        !- Field 3                                   ",
        "                                                                          ",
        "  Schedule:Compact,                                                       ",
        "    Activity Schedule,       !- Name                                      ",
        "    Any Number,              !- Schedule Type Limits Name                 ",
        "    Through: 12/31,          !- Field 1                                   ",
        "    For: AllDays,            !- Field 2                                   ",
        "    Until: 24:00,70;         !- Field 3                                   ",
        "                                                                          ",
        "  Schedule:Compact,                                                       ",
        "    Clothing Schedule,       !- Name                                      ",
        "    Any Number,              !- Schedule Type Limits Name                 ",
        "    Through: 12/31,          !- Field 9                                   ",
        "    For: AllDays,            !- Field 10                                  ",
        "    Until: 24:00,1.0;         !- Field 11                                 ",
        "                                                                          ",
        "  Schedule:Compact,                                                       ",
        "    AirVelocitySchedule,     !- Name                                      ",
        "    Any Number,              !- Schedule Type Limits Name                 ",
        "    Through: 12/31,          !- Field 1                                   ",
        "    For: AllDays,            !- Field 2                                   ",
        "    Until: 24:00,0.0;        !- Field 3                                   ",
        "                                                                          ",
        "  Schedule:Compact,                                                       ",
        "    Work efficiency,         !- Name                                      ",
        "    Any Number,              !- Schedule Type Limits Name                 ",
        "    Through: 12/31,          !- Field 9                                   ",
        "    For: AllDays,            !- Field 10                                  ",
        "    Until: 24:00,0.0;         !- Field 11                                 ",
        "                                                                          ",
        " Output:Diagnostics, DisplayExtraWarnings;",
        " Timestep, 4;",
        " BUILDING, AirloopHVAC_VentilationRateProcedure, 0.0, Suburbs, .04, .4, FullExterior, 25, 6;",
        " SimulationControl, NO, NO, NO, YES, NO;",
        "ScheduleTypeLimits,",
        "  Any Number;              !- Name",
        "  Site:Location,",
        "    Miami Intl Ap FL USA TMY3 WMO=722020E,    !- Name",
        "    25.82,                 !- Latitude {deg}",
        "    -80.30,                !- Longitude {deg}",
        "    -5.00,                 !- Time Zone {hr}",
        "    11;                    !- Elevation {m}",
        "SizingPeriod:DesignDay,",
        " Miami Intl Ap Ann Clg .4% Condns DB/MCWB, !- Name",
        " 7,                        !- Month",
        " 21,                       !- Day of Month",
        " SummerDesignDay,          !- Day Type",
        " 31.7,                     !- Maximum Dry - Bulb Temperature{ C }",
        " 10.0,                      !- Daily Dry - Bulb Temperature Range{ deltaC }",
        " ,                         !- Dry - Bulb Temperature Range Modifier Type",
        " ,                         !- Dry - Bulb Temperature Range Modifier Day Schedule Name",
        " Wetbulb,                  !- Humidity Condition Type",
        " 22.7,                     !- Wetbulb or DewPoint at Maximum Dry - Bulb{ C }",
        " ,                         !- Humidity Condition Day Schedule Name",
        " ,                         !- Humidity Ratio at Maximum Dry - Bulb{ kgWater / kgDryAir }",
        " ,                         !- Enthalpy at Maximum Dry - Bulb{ J / kg }",
        " ,                         !- Daily Wet - Bulb Temperature Range{ deltaC }",
        " 101217.,                  !- Barometric Pressure{ Pa }",
        " 3.8,                      !- Wind Speed{ m / s }",
        " 340,                      !- Wind Direction{ deg }",
        " No,                       !- Rain Indicator",
        " No,                       !- Snow Indicator",
        " No,                       !- Daylight Saving Time Indicator",
        " ASHRAEClearSky,           !- Solar Model Indicator",
        " ,                         !- Beam Solar Day Schedule Name",
        " ,                         !- Diffuse Solar Day Schedule Name",
        " ,                         !- ASHRAE Clear Sky Optical Depth for Beam Irradiance( taub ) { dimensionless }",
        " ,                         !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance( taud ) { dimensionless }",
        " 1.00;                     !- Sky Clearness",
        "SizingPeriod:DesignDay,",
        " Miami Intl Ap Ann Htg 99.6% Condns DB, !- Name",
        " 1,                        !- Month",
        " 21,                       !- Day of Month",
        " WinterDesignDay,          !- Day Type",
        " 8.7,                      !- Maximum Dry - Bulb Temperature{ C }",
        " 0.0,                      !- Daily Dry - Bulb Temperature Range{ deltaC }",
        " ,                         !- Dry - Bulb Temperature Range Modifier Type",
        " ,                         !- Dry - Bulb Temperature Range Modifier Day Schedule Name",
        " Wetbulb,                  !- Humidity Condition Type",
        " 8.7,                      !- Wetbulb or DewPoint at Maximum Dry - Bulb{ C }",
        " ,                         !- Humidity Condition Day Schedule Name",
        " ,                         !- Humidity Ratio at Maximum Dry - Bulb{ kgWater / kgDryAir }",
        " ,                         !- Enthalpy at Maximum Dry - Bulb{ J / kg }",
        " ,                         !- Daily Wet - Bulb Temperature Range{ deltaC }",
        " 101217.,                  !- Barometric Pressure{ Pa }",
        " 3.8,                      !- Wind Speed{ m / s }",
        " 340,                      !- Wind Direction{ deg }",
        " No,                       !- Rain Indicator",
        " No,                       !- Snow Indicator",
        " No,                       !- Daylight Saving Time Indicator",
        " ASHRAEClearSky,           !- Solar Model Indicator",
        " ,                         !- Beam Solar Day Schedule Name",
        " ,                         !- Diffuse Solar Day Schedule Name",
        " ,                         !- ASHRAE Clear Sky Optical Depth for Beam Irradiance( taub ) { dimensionless }",
        " ,                         !- ASHRAE Clear Sky Optical Depth for Diffuse Irradiance( taud ) { dimensionless }",
        " 0.00;                     !- Sky Clearness",
        "Zone,",
        "  Space,                   !- Name",
        "  0.0000,                  !- Direction of Relative North {deg}",
        "  0.0000,                  !- X Origin {m}",
        "  0.0000,                  !- Y Origin {m}",
        "  0.0000,                  !- Z Origin {m}",
        "  1,                       !- Type",
        "  1,                       !- Multiplier",
        "  2.4,                     !- Ceiling Height {m}",
        "  ,                        !- Volume {m3}",
        "  autocalculate,           !- Floor Area {m2}",
        "  ,                        !- Zone Inside Convection Algorithm",
        "  ,                        !- Zone Outside Convection Algorithm",
        "  Yes;                     !- Part of Total Floor Area",
        "ZoneGroup,",
        " Zone Group,               !- Name",
        " Zone List,                !- Zone List Name",
        " 10;                       !- Zone List Multiplier",
        "ZoneList,",
        " Zone List,                !- Name",
        " Spacex10;                 !- Zone 1 Name",
        "Zone,",
        "  Spacex10,                !- Name",
        "  0.0000,                  !- Direction of Relative North {deg}",
        "  0.0000,                  !- X Origin {m}",
        "  0.0000,                  !- Y Origin {m}",
        "  0.0000,                  !- Z Origin {m}",
        "  1,                       !- Type",
        "  1,                       !- Multiplier",
        "  2.4,                     !- Ceiling Height {m}",
        "  ,                        !- Volume {m3}",
        "  autocalculate,           !- Floor Area {m2}",
        "  ,                        !- Zone Inside Convection Algorithm",
        "  ,                        !- Zone Outside Convection Algorithm",
        "  Yes;                     !- Part of Total Floor Area",
        "People,",
        " Spacex10 People,          !- Name",
        " Spacex10,                 !- Zone or ZoneList Name",
        " OnSched,                  !- Number of People Schedule Name",
        " people,                   !- Number of People Calculation Method",
        " 11,                       !- Number of People",
        " ,                         !- People per Zone Floor Area{ person / m2 }",
        " ,                         !- Zone Floor Area per Person{ m2 / person }",
        " 0.3,                      !- Fraction Radiant",
        " AutoCalculate,            !- Sensible Heat Fraction",
        " Activity Schedule;        !- Activity Level Schedule Name",
        "Lights,",
        " Space Lights,             !- Name",
        " Space,                    !- Zone or ZoneList Name",
        " OnSched,                  !- Schedule Name",
        " Watts/Area,               !- Design Level Calculation Method",
        " ,                         !- Lighting Level{ W }",
        " 10.0,                     !- Watts per Zone Floor Area{ W / m2 }",
        " ,                         !- Watts per Person{ W / person }",
        " 0.0,                      !- Return Air Fraction",
        " 0.59,                     !- Fraction Radiant",
        " 0.2,                      !- Fraction Visible",
        " 0,                        !- Fraction Replaceable",
        " GeneralLights;            !- End - Use Subcategory",
        "Lights,",
        " Space Lights x10,         !- Name",
        " Spacex10,                 !- Zone or ZoneList Name",
        " OnSched,                  !- Schedule Name",
        " Watts/Area,               !- Design Level Calculation Method",
        " ,                         !- Lighting Level{ W }",
        " 10.0,                     !- Watts per Zone Floor Area{ W / m2 }",
        " ,                         !- Watts per Person{ W / person }",
        " 0.0,                      !- Return Air Fraction",
        " 0.59,                     !- Fraction Radiant",
        " 0.2,                      !- Fraction Visible",
        " 0,                        !- Fraction Replaceable",
        " GeneralLights;            !- End - Use Subcategory",
        "ElectricEquipment,",
        " Space ElecEq,             !- Name",
        " Space,                    !- Zone or ZoneList Name",
        " OnSched,                  !- Schedule Name",
        " Watts/Area,               !- Design Level Calculation Method",
        " ,                         !- Design Level{ W }",
        " 20.0,                     !- Watts per Zone Floor Area{ W / m2 }",
        " ,                         !- Watts per Person{ W / person }",
        " 0.1,                      !- Fraction Latent",
        " 0.3,                      !- Fraction Radiant",
        " 0.1;                      !- Fraction Lost",
        "ElectricEquipment,",
        " Space ElecEq x10,         !- Name",
        " Spacex10,                 !- Zone or ZoneList Name",
        " OnSched,                  !- Schedule Name",
        " Watts/Area,               !- Design Level Calculation Method",
        " ,                         !- Design Level{ W }",
        " 20.0,                     !- Watts per Zone Floor Area{ W / m2 }",
        " ,                         !- Watts per Person{ W / person }",
        " 0.1,                      !- Fraction Latent",
        " 0.3,                      !- Fraction Radiant",
        " 0.1;                      !- Fraction Lost",
        "Schedule:Compact,",
        " OnSched,                  !- Name",
        " Fraction,                 !- Schedule Type Limits Name",
        " Through: 12/31,           !- Field 1",
        " For: AllDays,             !- Field 2",
        " Until: 24:00, 1.0;        !- Field 26",
        "ScheduleTypeLimits,",
        " Fraction,                 !- Name",
        " 0.0,                      !- Lower Limit Value",
        " 1.0,                      !- Upper Limit Value",
        " CONTINUOUS;               !- Numeric Type",
        "Construction,",
        " INT-WALL-1,               !- Name",
        " GP02,                     !- Outside Layer",
        " AL21,                     !- Layer 2",
        " GP02;                     !- Layer 3",
        "Material,",
        " GP02,                     !- Name",
        " MediumSmooth,             !- Roughness",
        " 1.5900001E-02,            !- Thickness{ m }",
        " 0.1600000,                !- Conductivity{ W / m - K }",
        " 801.0000,                 !- Density{ kg / m3 }",
        " 837.0000,                 !- Specific Heat{ J / kg - K }",
        " 0.9000000,                !- Thermal Absorptance",
        " 0.7500000,                !- Solar Absorptance",
        " 0.7500000;                !- Visible Absorptance",
        "Material:AirGap,",
        " AL21,                     !- Name",
        " 0.1570000;                !- Thermal Resistance{ m2 - K / W }",
        "Construction,",
        "FLOOR-SLAB-1,              !- Name",
        "CC03,                      !- Outside Layer",
        "CP01;                      !- Layer 2",
        "Material,",
        " CC03,                     !- Name",
        " MediumRough,              !- Roughness",
        " 0.1016000,                !- Thickness{ m }",
        " 1.310000,                 !- Conductivity{ W / m - K }",
        " 2243.000,                 !- Density{ kg / m3 }",
        " 837.0000,                 !- Specific Heat{ J / kg - K }",
        " 0.9000000,                !- Thermal Absorptance",
        " 0.6500000,                !- Solar Absorptance",
        " 0.6500000;                !- Visible Absorptance",
        "Material:NoMass,",
        " CP01,                     !- Name",
        " Rough,                    !- Roughness",
        " 0.3670000,                !- Thermal Resistance{ m2 - K / W }",
        " 0.9000000,                !- Thermal Absorptance",
        " 0.7500000,                !- Solar Absorptance",
        " 0.7500000;                !- Visible Absorptance",
        "Construction,",
        " CLNG-1,                   !- Name",
        " MAT-CLNG-1;               !- Outside Layer",
        "Material:NoMass,",
        " MAT-CLNG-1,               !- Name",
        " Rough,                    !- Roughness",
        " 0.652259290,              !- Thermal Resistance{ m2 - K / W }",
        " 0.65,                     !- Thermal Absorptance",
        " 0.65,                     !- Solar Absorptance",
        " 0.65;                     !- Visible Absorptance",
        "BuildingSurface:Detailed,",
        " FRONT-1,                  !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                 !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " SunExposed,               !- Sun Exposure",
        " WindExposed,              !- Wind Exposure",
        " 0.50000,                  !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 0.0, 0.0, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 2 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 3 {m}",
        " 30.5, 0.0, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " C1-1,                     !- Name",
        " CEILING,                  !- Surface Type",
        " CLNG-1,                   !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                 !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 3.7, 3.7, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 0.0, 0.0, 2.4,            !- X, Y, Z == > Vertex 2 {m}",
        " 30.5, 0.0, 2.4,           !- X, Y, Z == > Vertex 3 {m}",
        " 26.8, 3.7, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " F1-1,                     !- Name",
        " FLOOR,                    !- Surface Type",
        " FLOOR-SLAB-1,             !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                   !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 1 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 3.7, 3.7, 0.0;            !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB12,                     !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 30.5, 0.0, 2.4,           !- X, Y, Z == > Vertex 1 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 3 {m}",
        " 26.8, 3.7, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB14,                     !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 3.7, 3.7, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 3.7, 3.7, 0.0,            !- X, Y, Z == > Vertex 2 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 0.0, 0.0, 2.4;            !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB15,                     !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Space,                    !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 26.8, 3.7, 2.4,           !- X, Y, Z == > Vertex 1 {m}",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 3.7, 3.7, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 3.7, 3.7, 2.4;            !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " FRONT-1x10,               !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                 !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " SunExposed,               !- Sun Exposure",
        " WindExposed,              !- Wind Exposure",
        " 0.50000,                  !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 0.0, 0.0, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 2 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 3 {m}",
        " 30.5, 0.0, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " C1-1x10,                  !- Name",
        " CEILING,                  !- Surface Type",
        " CLNG-1,                   !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                 !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 3.7, 3.7, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 0.0, 0.0, 2.4,            !- X, Y, Z == > Vertex 2 {m}",
        " 30.5, 0.0, 2.4,           !- X, Y, Z == > Vertex 3 {m}",
        " 26.8, 3.7, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " F1-1x10,                  !- Name",
        " FLOOR,                    !- Surface Type",
        " FLOOR-SLAB-1,             !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Outdoors,                   !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 1 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 3.7, 3.7, 0.0;            !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB12x10,                  !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 30.5, 0.0, 2.4,           !- X, Y, Z == > Vertex 1 {m}",
        " 30.5, 0.0, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 3 {m}",
        " 26.8, 3.7, 2.4;           !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB14x10,                  !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 3.7, 3.7, 2.4,            !- X, Y, Z == > Vertex 1 {m}",
        " 3.7, 3.7, 0.0,            !- X, Y, Z == > Vertex 2 {m}",
        " 0.0, 0.0, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 0.0, 0.0, 2.4;            !- X, Y, Z == > Vertex 4 {m}",
        "BuildingSurface:Detailed,",
        " SB15x10,                  !- Name",
        " WALL,                     !- Surface Type",
        " INT-WALL-1,               !- Construction Name",
        " Spacex10,                 !- Zone Name",
        "    ,                        !- Space Name",
        " Adiabatic,                !- Outside Boundary Condition",
        " ,                         !- Outside Boundary Condition Object",
        " NoSun,                    !- Sun Exposure",
        " NoWind,                   !- Wind Exposure",
        " 0.0,                      !- View Factor to Ground",
        " 4,                        !- Number of Vertices",
        " 26.8, 3.7, 2.4,           !- X, Y, Z == > Vertex 1 {m}",
        " 26.8, 3.7, 0.0,           !- X, Y, Z == > Vertex 2 {m}",
        " 3.7, 3.7, 0.0,            !- X, Y, Z == > Vertex 3 {m}",
        " 3.7, 3.7, 2.4;            !- X, Y, Z == > Vertex 4 {m}",
        "Output:Table:SummaryReports,",
        "  AllSummary; !- Report 1 Name",
        " ",
    ])
    expect_true(process_idf(idf_objects))
    state.dataGlobal.DDOnlySimulation = true
    ManageSimulation(state)
    var zoneHB1 = state.dataZoneTempPredictorCorrector.zoneHeatBalance[0]
    zoneHB1.ZTAVComf = 25.0
    zoneHB1.MRT = 26.0
    state.dataViewFactor.EnclRadInfo[0].MRT = 26.0
    zoneHB1.airHumRatAvgComf = 0.00529 # 0.002 to 0.006
    CalcThermalComfortFanger(state)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPMV, -1.262, tol=0.005)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPPD, 38.1, tol=0.1)
    zoneHB1.ZTAVComf = 26.0
    zoneHB1.MRT = 27.0
    state.dataViewFactor.EnclRadInfo[0].MRT = 27.0
    zoneHB1.airHumRatAvgComf = 0.00529 # 0.002 to 0.006
    CalcThermalComfortFanger(state)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPMV, -0.860, tol=0.005)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPPD, 20.5, tol=0.1)
    zoneHB1.ZTAVComf = 27.0
    zoneHB1.MRT = 28.0
    state.dataViewFactor.EnclRadInfo[0].MRT = 28.0
    zoneHB1.airHumRatAvgComf = 0.00529 # 0.002 to 0.006
    CalcThermalComfortFanger(state)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPMV, -0.460, tol=0.005)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPPD, 9.3, tol=0.1)
    zoneHB1.ZTAVComf = 25.0
    zoneHB1.MRT = 26.0
    state.dataViewFactor.EnclRadInfo[0].MRT = 26.0
    zoneHB1.airHumRatAvgComf = 0.00629 # 0.002 to 0.006
    CalcThermalComfortFanger(state)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPMV, -1.201, tol=0.005)
    expect_almost_equal(state.dataThermalComforts.ThermalComfortData[0].FangerPPD, 35.1, tol=0.1)

@test
def ThermalComfort_CalcSurfaceWeightedMRT():
    var SurfNum = 1
    var RadTemp = 0.0
    state.dataThermalComforts.AngleFactorList = DynamicVector[AngleFactorListData](1)
    state.dataSurface.TotSurfaces = 3
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBalSurf.SurfInsideTempHist = DynamicVector[DynamicVector[Real64]](1)
    state.dataHeatBalSurf.SurfInsideTempHist[0] = DynamicVector[Real64](state.dataSurface.TotSurfaces)
    state.dataSurface.Surface = DynamicVector[SurfaceData](state.dataSurface.TotSurfaces)
    state.dataConstruction.Construct = DynamicVector[ConstructData](state.dataSurface.TotSurfaces)
    state.dataHeatBal.Zone = DynamicVector[ZoneData](1)
    state.dataHeatBal.space = DynamicVector[SpaceData](1)
    state.dataSurface.Surface[0].Area = 20.0
    state.dataSurface.Surface[1].Area = 15.0
    state.dataSurface.Surface[2].Area = 10.0
    state.dataSurface.Surface[0].HeatTransSurf = true
    state.dataSurface.Surface[1].HeatTransSurf = true
    state.dataSurface.Surface[2].HeatTransSurf = true
    state.dataSurface.Surface[0].Construction = 0
    state.dataSurface.Surface[1].Construction = 1
    state.dataSurface.Surface[2].Construction = 2
    state.dataConstruction.Construct[0].InsideAbsorpThermal = 1.0
    state.dataConstruction.Construct[1].InsideAbsorpThermal = 0.9
    state.dataConstruction.Construct[2].InsideAbsorpThermal = 0.8
    state.dataSurface.Surface[0].Zone = 0
    state.dataSurface.Surface[1].Zone = 0
    state.dataSurface.Surface[2].Zone = 0
    state.dataHeatBal.Zone[0].spaceIndexes.append(0)
    state.dataHeatBal.space[0].HTSurfaceFirst = 0
    state.dataHeatBal.space[0].HTSurfaceLast = 2
    state.dataHeatBalSurf.SurfInsideTempHist[0][0] = 20.0
    state.dataHeatBalSurf.SurfInsideTempHist[0][1] = 15.0
    state.dataHeatBalSurf.SurfInsideTempHist[0][2] = 10.0
    state.dataViewFactor.EnclRadInfo = DynamicVector[EnclRadInfoData](state.dataGlobal.NumOfZones)
    state.dataViewFactor.EnclRadInfo[0].SurfacePtr = DynamicVector[Int](3)
    state.dataViewFactor.EnclRadInfo[0].SurfacePtr = DynamicVector[Int](0, 1, 2)
    state.dataSurface.Surface[0].RadEnclIndex = 0
    state.dataSurface.Surface[1].RadEnclIndex = 0
    state.dataSurface.Surface[2].RadEnclIndex = 0
    SurfNum = 0
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum)
    expect_almost_equal(RadTemp, 16.6, tol=0.1)
    SurfNum = 1
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum)
    expect_almost_equal(RadTemp, 16.1, tol=0.1)
    SurfNum = 2
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum)
    expect_almost_equal(RadTemp, 14.0, tol=0.1)
    SurfNum = 0
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum, false)
    expect_almost_equal(RadTemp, 13.1, tol=0.1)
    SurfNum = 1
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum, false)
    expect_almost_equal(RadTemp, 17.1, tol=0.1)
    SurfNum = 2
    state.dataThermalComforts.clear_state()
    RadTemp = CalcSurfaceWeightedMRT(state, SurfNum, false)
    expect_almost_equal(RadTemp, 18.0, tol=0.1)

@test
def ThermalComfort_CalcAngleFactorMRT():
    var RadTemp = 0.0
    state.dataThermalComforts.AngleFactorList = DynamicVector[AngleFactorListData](1)
    state.dataThermalComforts.AngleFactorList[0].TotAngleFacSurfaces = 3
    state.dataThermalComforts.AngleFactorList[0].SurfacePtr = DynamicVector[Int](state.dataThermalComforts.AngleFactorList[0].TotAngleFacSurfaces)
    state.dataThermalComforts.AngleFactorList[0].AngleFactor = DynamicVector[Real64](state.dataThermalComforts.AngleFactorList[0].TotAngleFacSurfaces)
    state.dataThermalComforts.AngleFactorList[0].SurfacePtr[0] = 0
    state.dataThermalComforts.AngleFactorList[0].SurfacePtr[1] = 1
    state.dataThermalComforts.AngleFactorList[0].SurfacePtr[2] = 2
    state.dataThermalComforts.AngleFactorList[0].AngleFactor[0] = 0.5
    state.dataThermalComforts.AngleFactorList[0].AngleFactor[1] = 0.3
    state.dataThermalComforts.AngleFactorList[0].AngleFactor[2] = 0.2
    state.dataSurface.TotSurfaces = state.dataThermalComforts.AngleFactorList[0].TotAngleFacSurfaces
    state.dataHeatBalSurf.SurfInsideTempHist = DynamicVector[DynamicVector[Real64]](1)
    state.dataHeatBalSurf.SurfInsideTempHist[0] = DynamicVector[Real64](state.dataSurface.TotSurfaces)
    state.dataSurface.Surface.deallocate()
    state.dataConstruction.Construct.deallocate()
    state.dataSurface.Surface = DynamicVector[SurfaceData](state.dataSurface.TotSurfaces)
    state.dataConstruction.Construct = DynamicVector[ConstructData](state.dataSurface.TotSurfaces)
    state.dataHeatBalSurf.SurfInsideTempHist[0][0] = 20.0
    state.dataHeatBalSurf.SurfInsideTempHist[0][1] = 15.0
    state.dataHeatBalSurf.SurfInsideTempHist[0][2] = 10.0
    state.dataSurface.Surface[0].Construction = 0
    state.dataSurface.Surface[1].Construction = 1
    state.dataSurface.Surface[2].Construction = 2
    state.dataConstruction.Construct[0].InsideAbsorpThermal = 1.0
    state.dataConstruction.Construct[1].InsideAbsorpThermal = 0.9
    state.dataConstruction.Construct[2].InsideAbsorpThermal = 0.8
    RadTemp = CalcAngleFactorMRT(state, 0)
    expect_almost_equal(RadTemp, 16.9, tol=0.1)

@test
def ThermalComfort_CalcThermalComfortAdaptiveASH55Test():
    state.dataThermalComforts.useEpwData = true
    state.dataThermalComforts.DailyAveOutTemp = DynamicVector[Real64](30)
    state.dataThermalComforts.DailyAveOutTemp[0] = 8.704166667
    state.dataThermalComforts.DailyAveOutTemp[1] = 9.895833333
    state.dataThermalComforts.DailyAveOutTemp[2] = 12.2
    state.dataThermalComforts.DailyAveOutTemp[3] = 8.445833333
    state.dataThermalComforts.DailyAveOutTemp[4] = 7.8
    state.dataThermalComforts.DailyAveOutTemp[5] = 7.158333333
    state.dataThermalComforts.DailyAveOutTemp[6] = 8.0125
    state.dataThermalComforts.DailyAveOutTemp[7] = 8.279166667
    state.dataThermalComforts.DailyAveOutTemp[8] = 8.166666667
    state.dataThermalComforts.DailyAveOutTemp[9] = 7.141666667
    state.dataThermalComforts.DailyAveOutTemp[10] = 7.433333333
    state.dataThermalComforts.DailyAveOutTemp[11] = 9.0625
    state.dataThermalComforts.DailyAveOutTemp[12] = 9.741666667
    state.dataThermalComforts.DailyAveOutTemp[13] = 9.545833333
    state.dataThermalComforts.DailyAveOutTemp[14] = 11.43333333
    state.dataThermalComforts.DailyAveOutTemp[15] = 12.375
    state.dataThermalComforts.DailyAveOutTemp[16] = 12.59583333
    state.dataThermalComforts.DailyAveOutTemp[17] = 12.6625
    state.dataThermalComforts.DailyAveOutTemp[18] = 13.50833333
    state.dataThermalComforts.DailyAveOutTemp[19] = 12.99583333
    state.dataThermalComforts.DailyAveOutTemp[20] = 11.58333333
    state.dataThermalComforts.DailyAveOutTemp[21] = 11.72083333
    state.dataThermalComforts.DailyAveOutTemp[22] = 9.1875
    state.dataThermalComforts.DailyAveOutTemp[23] = 6.8
    state.dataThermalComforts.DailyAveOutTemp[24] = 9.391666667
    state.dataThermalComforts.DailyAveOutTemp[25] = 8.1125
    state.dataThermalComforts.DailyAveOutTemp[26] = 8.4
    state.dataThermalComforts.DailyAveOutTemp[27] = 8.475
    state.dataThermalComforts.DailyAveOutTemp[28] = 7.941666667
    state.dataThermalComforts.DailyAveOutTemp[29] = 9.316666667
    state.dataGlobal.BeginDayFlag = true
    CalcThermalComfortAdaptiveASH55(state, false)
    expect_almost_equal(state.dataThermalComforts.runningAverageASH, 9.29236111, tol=0.001)
    state.dataThermalComforts.useEpwData = false
    state.dataGlobal.BeginDayFlag = false

@test
def ThermalComfort_CalcIfSetPointMetWithCutoutTest():
    state.dataGlobal.NumOfZones = 1
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand = DynamicVector[ZoneSysEnergyDemandData](state.dataGlobal.NumOfZones)
    state.dataThermalComforts.ThermalComfortSetPoint = DynamicVector[ThermalComfortSetPointData](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.TempControlType = DynamicVector[Int](1)
    state.dataRoomAir.AirModel = DynamicVector[RoomAirModelData](state.dataGlobal.NumOfZones)
    state.dataRoomAir.AirModel[0].AirModel = RoomAir.RoomAirModel.Mixing
    state.dataZoneTempPredictorCorrector.zoneHeatBalance = DynamicVector[ZoneHeatBalanceData](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.zoneTstatSetpts = DynamicVector[ZoneTstatSetptsData](state.dataGlobal.NumOfZones)
    state.dataThermalComforts.ThermalComfortInASH55 = DynamicVector[ThermalComfortInASH55Data](state.dataGlobal.NumOfZones)
    state.dataThermalComforts.ThermalComfortInASH55[0].ZoneIsOccupied = true
    state.dataGlobal.TimeStepZone = 0.25
    state.dataHeatBal.Zone = DynamicVector[ZoneData](state.dataGlobal.NumOfZones)
    state.dataZoneTempPredictorCorrector.NumOnOffCtrZone = 1
    state.dataHeatBalFanSys.TempControlType[0] = HVAC.SetptType.DualHeatCool
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 21.1           # 70F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLo = 22.2                     # 72F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptLoAver = 22.2                 # 72F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 500.0 # must be greater than zero
    CalcIfSetPointMet(state)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0.0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 25.0            # 77F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHi = 23.9                      # 75F
    state.dataHeatBalFanSys.zoneTstatSetpts[0].setptHiAver = 23.9                  # 75F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = -500.0 # must be less than zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    state.dataZoneTempPredictorCorrector.zoneHeatBalance[0].ZTAV = 23.0         # 73F
    state.dataZoneEnergyDemand.ZoneSysEnergyDemand[0].TotalOutputRequired = 0.0 # must be zero
    CalcIfSetPointMet(state)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeating)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetHeatingOccupied)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCooling)
    expect_equal(0, state.dataThermalComforts.ThermalComfortSetPoint[0].notMetCoolingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].totalNotMetHeating)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].totalNotMetHeatingOccupied)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].totalNotMetCooling)
    expect_equal(state.dataGlobal.TimeStepZone, state.dataThermalComforts.ThermalComfortSetPoint[0].totalNotMetCoolingOccupied)

@test
def ThermalComfort_CalcThermalComfortASH55():
    state.init_state(state)
    state.dataHeatBal.TotPeople = 1
    state.dataHeatBal.People = DynamicVector[PeopleData](state.dataHeatBal.TotPeople)
    state.dataThermalComforts.ThermalComfortData = DynamicVector[ThermalComfortData](state.dataHeatBal.TotPeople)
    state.dataGlobal.NumOfZones = 1
    state.dataHeatBal.Zone = DynamicVector[ZoneData](state.dataGlobal.NumOfZones)
    state.dataRoomAir.IsZoneDispVent3Node = DynamicVector[Bool](state.dataGlobal.NumOfZones)
    state.dataRoomAir.IsZoneUFAD = DynamicVector[Bool](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQdotRadHVACToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQHTRadSysToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQCoolingPanelToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQSteamBaseboardToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson = DynamicVector[Real64](state.dataGlobal.NumOfZones)
    state.dataHeatBal.People[0].ZonePtr = 0
    state.dataHeatBal.People[0].sched = Sched.GetScheduleAlwaysOn(state)
    state.dataHeatBal.People[0].NumberOfPeople = 5.0
    state.dataHeatBal.People[0].NomMinNumberPeople = 5.0
    state.dataHeatBal.People[0].NomMaxNumberPeople = 5.0
    state.dataHeatBal.Zone[state.dataHeatBal.People[0].ZonePtr].TotOccupants = state.dataHeatBal.People[0].NumberOfPeople
    state.dataHeatBal.People[0].FractionRadiant = 0.3
    state.dataHeatBal.People[0].FractionConvected = 1.0 - state.dataHeatBal.People[0].FractionRadiant
    state.dataHeatBal.People[0].UserSpecSensFrac = Constant.AutoCalculate
    state.dataHeatBal.People[0].CO2RateFactor = 3.82e-8
    state.dataHeatBal.People[0].Show55Warning = true
    state.dataHeatBal.People[0].Pierce = true
    state.dataHeatBal.People[0].MRTCalcType = DataHeatBalance.CalcMRT.EnclosureAveraged
    state.dataHeatBal.People[0].spaceIndex = 0
    state.dataHeatBal.space = DynamicVector[SpaceData](1)
    state.dataHeatBal.space[0].radiantEnclosureNum = 0
    state.dataViewFactor.EnclRadInfo = DynamicVector[EnclRadInfoData](1)
    state.dataHeatBal.People[0].workEffSched = Sched.GetScheduleAlwaysOff(state)
    state.dataHeatBal.People[0].clothingType = ClothingType.InsulationSchedule
    state.dataRoomAir.IsZoneDispVent3Node[0] = false
    state.dataRoomAir.IsZoneUFAD[0] = false
    state.dataHeatBalFanSys.ZoneQHTRadSysToPerson[0] = 0.0
    state.dataHeatBalFanSys.ZoneQCoolingPanelToPerson[0] = 0.0
    state.dataHeatBalFanSys.ZoneQHWBaseboardToPerson[0] = 0.0
    state.dataHeatBalFanSys.ZoneQSteamBaseboardToPerson[0] = 0.0
    state.dataHeatBalFanSys.ZoneQElecBaseboardToPerson[0] = 0.0
    let BodySurfaceArea = 1.8258
    state.dataEnvrn.OutBaroPress = 101325.0
    let WorkEff = 0.0
    var activitySched = Sched.AddScheduleConstant(state, "ACTIVITY")
    state.dataHeatBal.People[0].activityLevelSched = activitySched
    var clothingSched = Sched.AddScheduleConstant(state, "CLOTHING")
    state.dataHeatBal.People[0].clothingSched = clothingSched
    var airVeloSched = Sched.AddScheduleConstant(state, "AIR VELO")
    state.dataHeatBal.People[0].airVelocitySched = airVeloSched
    var ankleAirVeloSched = Sched.AddScheduleConstant(state, "ANKLE AIR VELO")
    state.dataHeatBal.People[0].ankleAirVelocitySched = ankleAirVeloSched
    let TAir = DynamicVector[Real64](25.0, 0.0, 40.0, 25.0, 25.0, 25.0, 25.0, 25.0)
    let RH = DynamicVector[Real64](0.5, 0.5, 0.5, 0.9, 0.5, 0.5, 0.5, 0.5)
    let Vel = DynamicVector[Real64](0.15, 0.15, 0.15, 0.15, 3.0, 0.15, 0.15, 0.15)
    let TRad = DynamicVector[Real64](25.0, 25.0, 25.0, 25.0, 25.0, 40.0, 25.0, 25.0)
    let MET = DynamicVector[Real64](1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0)
    let Clo = DynamicVector[Real64](0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0)
    let SET = DynamicVector[Real64](23.8, 12.3, 34.3, 24.9, 18.8, 31.8, 29.7, 32.5)
    for i in range(8):
        var SETResult = CalcStandardEffective