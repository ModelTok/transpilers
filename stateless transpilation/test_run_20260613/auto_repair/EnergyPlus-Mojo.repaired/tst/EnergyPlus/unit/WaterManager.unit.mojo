from gtest import *
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.Data.DataEnvironment import DataEnvironment
from EnergyPlus.Data.DataHVACGlobals import DataHVACGlobals
from EnergyPlus.Data.DataWater import DataWater
from EnergyPlus.HeatBalanceManager import HeatBalanceManager
from EnergyPlus.OutputProcessor import OutputProcessor
from EnergyPlus.ScheduleManager import ScheduleManager as Sched
from EnergyPlus.SurfaceGeometry import SurfaceGeometry
from EnergyPlus.WaterManager import WaterManager
from EnergyPlus.WeatherManager import WeatherManager
from ......Fixtures.EnergyPlusFixture import EnergyPlusFixture
TEST_F(EnergyPlusFixture, WaterManager_NormalAnnualPrecipitation)
{
    var idf_objects: String = delimited_string({
        "Site:Precipitation,",
        "ScheduleAndDesignLevel,  !- Precipitation Model Type",
        "0.75,                    !- Design Level for Total Annual Precipitation {m/yr}",
        "PrecipitationSchd,       !- Precipitation Rates Schedule Name",
        "0.80771;                 !- Average Total Annual Precipitation {m/yr}",
        "Schedule:Constant,",
        "PrecipitationSchd,",
        ",",
        "1;",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(*state)
    WaterManager.GetWaterManagerInput(*state)
    state.dataEnvrn.Year = 2000
    state.dataEnvrn.EndYear = 2000
    state.dataEnvrn.Month = 1
    state.dataGlobal.TimeStep = 2
    state.dataGlobal.TimeStepZoneSec = 900
    Sched.GetSchedule(*state, "PRECIPITATIONSCHD").currentVal = 1.0
    WaterManager.UpdatePrecipitation(*state)
    var ExpectedNomAnnualRain: Float64 = 0.80771
    var ExpectedCurrentRate: Float64 = 1.0 * (0.75 / 0.80771) / Constant.rSecsInHour
    var NomAnnualRain: Float64 = state.dataWaterData.RainFall.NomAnnualRain
    EXPECT_NEAR(NomAnnualRain, ExpectedNomAnnualRain, 0.000001)
    var CurrentRate: Float64 = state.dataWaterData.RainFall.CurrentRate
    EXPECT_NEAR(CurrentRate, ExpectedCurrentRate, 0.000001)
}

TEST_F(EnergyPlusFixture, WaterManager_UpdatePrecipitation)
{
    var idf_objects: String = delimited_string({
        "Site:Precipitation,",
        "ScheduleAndDesignLevel,  !- Precipitation Model Type",
        "0.75,                    !- Design Level for Total Annual Precipitation {m/yr}",
        "PrecipitationSchd,       !- Precipitation Rates Schedule Name",
        "0.75;                    !- Average Total Annual Precipitation {m/yr}",
        "Schedule:Constant,",
        "PrecipitationSchd,",
        ",",
        "1;",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(*state)
    WaterManager.GetWaterManagerInput(*state)
    state.dataGlobal.TimeStepZoneSec = 900
    state.dataEnvrn.Year = 2000
    state.dataEnvrn.EndYear = 2000
    state.dataEnvrn.Month = 1
    state.dataGlobal.TimeStep = 2
    Sched.GetSchedule(*state, "PRECIPITATIONSCHD").currentVal = 2.0
    state.dataEnvrn.LiquidPrecipitation = 0.5
    WaterManager.UpdatePrecipitation(*state)
    ASSERT_EQ(state.dataWaterData.RainFall.CurrentRate, 2.0 / 3600)
    state.dataEnvrn.LiquidPrecipitation = 0.5
    state.dataWaterData.RainFall.ModeID = DataWater.RainfallMode.None
    WaterManager.UpdatePrecipitation(*state)
    ASSERT_EQ(state.dataWaterData.RainFall.CurrentRate, 0.5 / state.dataGlobal.TimeStepZoneSec)
    state.dataEnvrn.LiquidPrecipitation = 0.0
    WaterManager.UpdatePrecipitation(*state)
    ASSERT_EQ(state.dataWaterData.RainFall.CurrentRate, 0.0)
}

TEST_F(EnergyPlusFixture, WaterManager_ZeroAnnualPrecipitation)
{
    var idf_objects: String = delimited_string({
        "Site:Precipitation,",
        "ScheduleAndDesignLevel,  !- Precipitation Model Type",
        "0.75,                    !- Design Level for Total Annual Precipitation {m/yr}",
        "PrecipitationSchd,       !- Precipitation Rates Schedule Name",
        "0.0;                     !- Average Total Annual Precipitation {m/yr}",
        "Schedule:Constant,",
        "PrecipitationSchd,",
        ",",
        "1;",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(*state)
    WaterManager.GetWaterManagerInput(*state)
    state.dataEnvrn.Year = 2000
    state.dataEnvrn.EndYear = 2000
    state.dataEnvrn.Month = 1
    state.dataGlobal.TimeStep = 2
    state.dataGlobal.TimeStepZoneSec = 900
    Sched.GetSchedule(*state, "PRECIPITATIONSCHD").currentVal = 1.0
    WaterManager.UpdatePrecipitation(*state)
    var NomAnnualRain: Float64 = state.dataWaterData.RainFall.NomAnnualRain
    EXPECT_NEAR(NomAnnualRain, 0.0, 0.000001)
    var CurrentRate: Float64 = state.dataWaterData.RainFall.CurrentRate
    EXPECT_NEAR(CurrentRate, 0.0, 0.000001)
}

TEST_F(EnergyPlusFixture, WaterManager_Fill)
{
    var idf_objects: String = delimited_string({
        "WaterUse:Storage,",
        "  Cooling Tower Water Storage Tank,  !- Name",
        "  Mains,                   !- Water Quality Subcategory",
        "  3,                       !- Maximum Capacity {m3}",
        "  0.25,                    !- Initial Volume {m3}",
        "  0.003,                   !- Design In Flow Rate {m3/s}",
        "  ,                        !- Design Out Flow Rate {m3/s}",
        "  ,                        !- Overflow Destination",
        "  GroundwaterWell,         !- Type of Supply Controlled by Float Valve",
        "  0.20,                    !- Float Valve On Capacity {m3}",
        "  3,                       !- Float Valve Off Capacity {m3}",
        "  0.10,                    !- Backup Mains Capacity {m3}",
        "  ,                        !- Other Tank Name",
        "  ScheduledTemperature,    !- Water Thermal Mode",
        "  Always 18,               !- Water Temperature Schedule Name",
        "  ,                        !- Ambient Temperature Indicator",
        "  ,                        !- Ambient Temperature Schedule Name",
        "  ,                        !- Zone Name",
        "  ,                        !- Tank Surface Area {m2}",
        "  ,                        !- Tank U Value {W/m2-K}",
        "  ;                        !- Tank Outside Surface Material Name",
        "WaterUse:Well,",
        "  Cooling Tower Transfer Pumps,  !- Name",
        "  Cooling Tower Water Storage Tank,  !- Storage Tank Name",
        "  ,                        !- Pump Depth {m}",
        "  0.003,                   !- Pump Rated Flow Rate {m3/s}",
        "  ,                        !- Pump Rated Head {Pa}",
        "  1500,                    !- Pump Rated Power Consumption {W}",
        "  ,                        !- Pump Efficiency",
        "  ,                        !- Well Recovery Rate {m3/s}",
        "  ,                        !- Nominal Well Storage Volume {m3}",
        "  ,                        !- Water Table Depth Mode",
        "  ,                        !- Water Table Depth {m}",
        "  ;                        !- Water Table Depth Schedule Name",
        "Schedule:Constant,",
        "    Always 18,               !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    18.0;                    !- Hourly Value",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(*state)
    WaterManager.GetWaterManagerInput(*state)
    state.dataWaterManager.GetInputFlag = false
    EXPECT_EQ(1u, len(state.dataWaterData.WaterStorage))
    var TankNum: Int32 = 1
    EXPECT_ENUM_EQ(DataWater.ControlSupplyType.WellFloatMainsBackup, state.dataWaterData.WaterStorage[TankNum - 1].ControlSupply)
    EXPECT_EQ(0u, state.dataWaterData.WaterStorage[TankNum - 1].NumWaterDemands)
    EXPECT_EQ(0.003, state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate)
    EXPECT_EQ(0.20, state.dataWaterData.WaterStorage[TankNum - 1].ValveOnCapacity)
    EXPECT_EQ(3.0, state.dataWaterData.WaterStorage[TankNum - 1].ValveOffCapacity)
    EXPECT_EQ(3.0, state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity)
    var calcVolume: Float64 = 0.26
    state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepVolume = calcVolume
    state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume = calcVolume
    state.dataHVACGlobal.TimeStepSys = 10.0 / 60.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    state.dataWaterData.WaterStorage[TankNum - 1].NumWaterDemands = 1
    state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand.allocate(1)
    var draw: Float64 = 0.025
    state.dataWaterData.WaterStorage[TankNum - 1].VdotRequestDemand[0] = draw / state.dataHVACGlobal.TimeStepSysSec
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(0.235, calcVolume)
    EXPECT_FALSE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(0.21, calcVolume)
    EXPECT_FALSE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    calcVolume += state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate * state.dataHVACGlobal.TimeStepSysSec
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(1.985, calcVolume)
    EXPECT_TRUE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    calcVolume += state.dataWaterData.WaterStorage[TankNum - 1].MaxInFlowRate * state.dataHVACGlobal.TimeStepSysSec
    EXPECT_DOUBLE_EQ(3.76, calcVolume)
    calcVolume = min(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].MaxCapacity)
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(3.0, calcVolume)
    EXPECT_FALSE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(2.975, calcVolume)
    EXPECT_FALSE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
    WaterManager.ManageWater(*state)
    calcVolume -= draw
    EXPECT_DOUBLE_EQ(calcVolume, state.dataWaterData.WaterStorage[TankNum - 1].ThisTimeStepVolume)
    EXPECT_DOUBLE_EQ(2.95, calcVolume)
    EXPECT_FALSE(state.dataWaterData.WaterStorage[TankNum - 1].LastTimeStepFilling)
    WaterManager.UpdateWaterManager(*state)
}

TEST_F(EnergyPlusFixture, WaterManager_MainsWater_Meter_Test)
{
    var idf_objects: String = delimited_string({
        "WaterUse:Storage,",
        "  Cooling Tower Water Storage Tank,  !- Name",
        "  ,                        !- Water Quality Subcategory",
        "  3,                       !- Maximum Capacity {m3}",
        "  0.25,                    !- Initial Volume {m3}",
        "  0.003,                   !- Design In Flow Rate {m3/s}",
        "  ,                        !- Design Out Flow Rate {m3/s}",
        "  ,                        !- Overflow Destination",
        "  GroundwaterWell,         !- Type of Supply Controlled by Float Valve",
        "  0.20,                    !- Float Valve On Capacity {m3}",
        "  3,                       !- Float Valve Off Capacity {m3}",
        "  0.10,                    !- Backup Mains Capacity {m3}",
        "  ,                        !- Other Tank Name",
        "  ScheduledTemperature,    !- Water Thermal Mode",
        "  Always 18,               !- Water Temperature Schedule Name",
        "  ,                        !- Ambient Temperature Indicator",
        "  ,                        !- Ambient Temperature Schedule Name",
        "  ,                        !- Zone Name",
        "  ,                        !- Tank Surface Area {m2}",
        "  ,                        !- Tank U Value {W/m2-K}",
        "  ;                        !- Tank Outside Surface Material Name",
        "WaterUse:Well,",
        "  Cooling Tower Transfer Pumps,  !- Name",
        "  Cooling Tower Water Storage Tank,  !- Storage Tank Name",
        "  ,                        !- Pump Depth {m}",
        "  0.003,                   !- Pump Rated Flow Rate {m3/s}",
        "  ,                        !- Pump Rated Head {Pa}",
        "  1500,                    !- Pump Rated Power Consumption {W}",
        "  ,                        !- Pump Efficiency",
        "  ,                        !- Well Recovery Rate {m3/s}",
        "  ,                        !- Nominal Well Storage Volume {m3}",
        "  ,                        !- Water Table Depth Mode",
        "  ,                        !- Water Table Depth {m}",
        "  ;                        !- Water Table Depth Schedule Name",
        "Schedule:Constant,",
        "    Always 18,               !- Name",
        "    ,                        !- Schedule Type Limits Name",
        "    18.0;                    !- Hourly Value",
    })
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(*state)
    WaterManager.GetWaterManagerInput(*state)
    state.dataWaterManager.GetInputFlag = false
    EXPECT_EQ(len(state.dataWaterData.WaterStorage), 1u)
    EXPECT_EQ(len(state.dataOutputProcessor.meters), 11u)
    EXPECT_EQ(state.dataOutputProcessor.meters[3].Name, "General:WaterSystems:MainsWater")
    EXPECT_ENUM_EQ(state.dataOutputProcessor.meters[3].resource, Constant.eResource.MainsWater)
    EXPECT_ENUM_EQ(state.dataOutputProcessor.meters[3].endUseCat, OutputProcessor.EndUseCat.WaterSystem)
    EXPECT_EQ(state.dataOutputProcessor.meters[3].EndUseSub, "General")
    EXPECT_ENUM_EQ(state.dataOutputProcessor.meters[3].group, OutputProcessor.Group.Invalid)
}