from testing import *
from EnergyPlus.Data.EnergyPlusData import *
from EnergyPlus.DataEnvironment import *
from EnergyPlus.DataGlobals import *
from EnergyPlus.EconomicTariff import *
from EnergyPlus.ExteriorEnergyUse import *
from EnergyPlus.General import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportPredefined import *
from EnergyPlus.OutputReportTabular import *
from EnergyPlus.ScheduleManager import * as Sched
from EnergyPlus.SimulationManager import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
from .Fixtures.SQLiteFixture import SQLiteFixture

using EnergyPlus
using EnergyPlus.EconomicTariff
using EnergyPlus.OutputProcessor
using EnergyPlus.OutputReportPredefined

struct EconomicTariff_GetInput_Test(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  UtilityCost:Tariff,                                                       ",
            "    ExampleFmc,              !- Name                                        ",
            "    ElectricityPurchased:Facility,  !- Output Meter Name                    ",
            "    kWh,                     !- Conversion Factor Choice                    ",
            "    ,                        !- Energy Conversion Factor                    ",
            "    ,                        !- Demand Conversion Factor                    ",
            "    TimeOfDaySchedule-Fmc,   !- Time of Use Period Schedule Name            ",
            "    TwoSeasonSchedule-Fmc,   !- Season Schedule Name                        ",
            "    ,                        !- Month Schedule Name                         ",
            "    ,                        !- Demand Window Length                        ",
            "    37.75;                   !- Monthly Charge or Variable Name             ",
            "                                                                            ",
            "  UtilityCost:Charge:Simple,                                                ",
            "    SummerOnPeak,            !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    peakEnergy,              !- Source Variable                             ",
            "    summer,                  !- Season                                      ",
            "    EnergyCharges,           !- Category Variable Name                      ",
            "    0.14009;                 !- Cost per Unit Value or Variable Name        ",
            "                                                                            ",
            "  UtilityCost:Charge:Simple,                                                ",
            "    SummerOffPeak,           !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    offPeakEnergy,           !- Source Variable                             ",
            "    summer,                  !- Season                                      ",
            "    EnergyCharges,           !- Category Variable Name                      ",
            "    0.06312;                 !- Cost per Unit Value or Variable Name        ",
            "                                                                            ",
            "  UtilityCost:Charge:Block,                                                 ",
            "    WinterOnPeak,            !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    peakEnergy,              !- Source Variable                             ",
            "    winter,                  !- Season                                      ",
            "    EnergyCharges,           !- Category Variable Name                      ",
            "    ,                        !- Remaining Into Variable                     ",
            "    ,                        !- Block Size Multiplier Value or Variable Name",
            "    650,                     !- Block Size 1 Value or Variable Name         ",
            "    0.04385,                 !- Block 1 Cost per Unit Value or Variable Name",
            "    350,                     !- Block Size 2 Value or Variable Name         ",
            "    0.03763,                 !- Block 2 Cost per Unit Value or Variable Name",
            "    remaining,               !- Block Size 3 Value or Variable Name         ",
            "    0.03704;                 !- Block 3 Cost per Unit Value or Variable Name",
            "                                                                            ",
            "  UtilityCost:Charge:Simple,                                                ",
            "    WinterOffPeak,           !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    offPeakEnergy,           !- Source Variable                             ",
            "    winter,                  !- Season                                      ",
            "    EnergyCharges,           !- Category Variable Name                      ",
            "    0.02420;                 !- Cost per Unit Value or Variable Name        ",
            "                                                                            ",
            "  UtilityCost:Qualify,                                                      ",
            "    MinDemand,               !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    TotalDemand,             !- Variable Name                               ",
            "    Minimum,                 !- Qualify Type                                ",
            "    12,                      !- Threshold Value or Variable Name            ",
            "    Annual,                  !- Season                                      ",
            "    Count,                   !- Threshold Test                              ",
            "    2;                       !- Number of Months                            ",
            "                                                                            ",
            "  UtilityCost:Computation,                                                  ",
            "    ManualExample,           !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    SumEneCharges SUM SUMMERONPEAK SUMMEROFFPEAK,  !- Compute Step 1        ",
            "    WinEneCharges SUM WINTERONPEAK WINTEROFFPEAK,  !- Compute Step 2        ",
            "    EnergyCharges SUM SumEneCharges WinEneCharges,  !- Compute Step 3       ",
            "    Basis SUM EnergyCharges DemandCharges ServiceCharges,  !- Compute Step 4",
            "    Subtotal SUM Basis Adjustment Surcharge,  !- Compute Step 5             ",
            "    Total SUM Subtotal Taxes;!- Compute Step 6                              ",
            "                                                                            ",
            "  UtilityCost:Ratchet,                                                      ",
            "    BillingDemand1,          !- Name                                        ",
            "    ExampleFmc,              !- Tariff Name                                 ",
            "    TotalDemand,             !- Baseline Source Variable                    ",
            "    TotalDemand,             !- Adjustment Source Variable                  ",
            "    Summer,                  !- Season From                                 ",
            "    Annual,                  !- Season To                                   ",
            "    0.80,                    !- Multiplier Value or Variable Name           ",
            "    0;                       !- Offset Value or Variable Name               ",
            "                                                                            ",
            "  Schedule:Compact,                                                         ",
            "    TwoSeasonSchedule-Fmc,   !- Name                                        ",
            "    number,                  !- Schedule Type Limits Name                   ",
            "    Through: 5/31,           !- Field 1                                     ",
            "    For: AllDays,            !- Field 2                                     ",
            "    Until: 24:00,1,          !- Field 3                                     ",
            "    Through: 9/30,           !- Field 5                                     ",
            "    For: AllDays,            !- Field 6                                     ",
            "    Until: 24:00,3,          !- Field 7                                     ",
            "    Through: 12/31,          !- Field 9                                     ",
            "    For: AllDays,            !- Field 10                                    ",
            "    Until: 24:00,1;          !- Field 11                                    ",
            "                                                                            ",
            "  Schedule:Compact,                                                         ",
            "    TimeOfDaySchedule-Fmc,   !- Name                                        ",
            "    number,                  !- Schedule Type Limits Name                   ",
            "    Through: 5/31,           !- Field 1                                     ",
            "    For: AllDays,            !- Field 2                                     ",
            "    Until: 15:00,3,          !- Field 3                                     ",
            "    Until: 22:00,1,          !- Field 5                                     ",
            "    Until: 24:00,3,          !- Field 7                                     ",
            "    Through: 9/30,           !- Field 9                                     ",
            "    For: AllDays,            !- Field 10                                    ",
            "    Until: 10:00,3,          !- Field 11                                    ",
            "    Until: 19:00,1,          !- Field 13                                    ",
            "    Until: 24:00,3,          !- Field 15                                    ",
            "    Through: 12/31,          !- Field 17                                    ",
            "    For: AllDays,            !- Field 18                                    ",
            "    Until: 15:00,3,          !- Field 19                                    ",
            "    Until: 22:00,1,          !- Field 21                                    ",
            "    Until: 24:00,3;          !- Field 23                                    ",
            "                                                                            ",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        UpdateUtilityBills(state)
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_eq("EXAMPLEFMC", state.dataEconTariff.tariff[1].tariffName)
        expect_enum_eq(EconConv.KWH, state.dataEconTariff.tariff[1].convChoice)
        expect_eq(37.75, state.dataEconTariff.tariff[1].monthChgVal)
        expect_eq(1, state.dataEconTariff.numQualify)
        expect_false(state.dataEconTariff.qualify[1].isMaximum)
        expect_eq(12, state.dataEconTariff.qualify[1].thresholdVal)
        expect_enum_eq(Season.Annual, state.dataEconTariff.qualify[1].season)
        expect_false(state.dataEconTariff.qualify[1].isConsecutive)
        expect_eq(2, state.dataEconTariff.qualify[1].numberOfMonths)
        expect_eq(3, state.dataEconTariff.numChargeSimple)
        expect_enum_eq(Season.Winter, state.dataEconTariff.chargeSimple[3].season)
        expect_eq(0.02420, state.dataEconTariff.chargeSimple[3].costPerVal)
        expect_eq(1, state.dataEconTariff.numChargeBlock)
        expect_enum_eq(Season.Winter, state.dataEconTariff.chargeBlock[1].season)
        expect_eq(3, state.dataEconTariff.chargeBlock[1].numBlk)
        expect_eq(350, state.dataEconTariff.chargeBlock[1].blkSzVal[2])
        expect_eq(0.03763, state.dataEconTariff.chargeBlock[1].blkCostVal[2])
        expect_eq(1, state.dataEconTariff.numRatchet)
        expect_enum_eq(Season.Summer, state.dataEconTariff.ratchet[1].seasonFrom)
        expect_enum_eq(Season.Annual, state.dataEconTariff.ratchet[1].seasonTo)
        expect_eq(0.80, state.dataEconTariff.ratchet[1].multiplierVal)
        expect_eq(0.0, state.dataEconTariff.ratchet[1].offsetVal)
        expect_eq(1, state.dataEconTariff.numComputation)

struct EconomicTariff_Water_DefaultConv_Test(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  UtilityCost:Tariff,                                                       ",
            "    ExampleWaterTariff,      !- Name                                        ",
            "    Water:Facility,          !- Output Meter Name                           ",
            "    ,                        !- Conversion Factor Choice                    ",
            "    ,                        !- Energy Conversion Factor                    ",
            "    ,                        !- Demand Conversion Factor                    ",
            "    ,                        !- Time of Use Period Schedule Name            ",
            "    ,                        !- Season Schedule Name                        ",
            "    ,                        !- Month Schedule Name                         ",
            "    ,                        !- Demand Window Length                        ",
            "    10;                      !- Monthly Charge or Variable Name             ",
            "                                                                            ",
            "  UtilityCost:Charge:Simple,                                                ",
            "    FlatWaterChargePerm3,    !- Name                                        ",
            "    ExampleWaterTariff,      !- Tariff Name                                 ",
            "    totalEnergy,             !- Source Variable                             ",
            "    Annual,                  !- Season                                      ",
            "    EnergyCharges,           !- Category Variable Name                      ",
            "    3.3076;                  !- Cost per Unit Value or Variable Name        ",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        var meter: OutputProcessor.Meter = OutputProcessor.Meter("WATER:FACILITY")
        meter.resource = Constant.eResource.Water
        state.dataOutputProcessor.meters.append(meter)
        state.dataOutputProcessor.meterMap.insert_or_assign("WATER:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        UpdateUtilityBills(state)
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_eq("EXAMPLEWATERTARIFF", state.dataEconTariff.tariff[1].tariffName)
        expect_enum_eq(EconomicTariff.MeterType.Water, state.dataEconTariff.tariff[1].kindMtr)
        expect_enum_eq(EconConv.M3, state.dataEconTariff.tariff[1].convChoice)
        expect_eq(1, state.dataEconTariff.tariff[1].energyConv)
        expect_eq(3600, state.dataEconTariff.tariff[1].demandConv)
        expect_eq(10, state.dataEconTariff.tariff[1].monthChgVal)

struct EconomicTariff_Water_CCF_Test(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  UtilityCost:Tariff,                                                       ",
            "    ExampleWaterTariff,      !- Name                                        ",
            "    Water:Facility,          !- Output Meter Name                           ",
            "    CCF,                     !- Conversion Factor Choice                    ",
            "    ,                        !- Energy Conversion Factor                    ",
            "    ,                        !- Demand Conversion Factor                    ",
            "    ,                        !- Time of Use Period Schedule Name            ",
            "    ,                        !- Season Schedule Name                        ",
            "    ,                        !- Month Schedule Name                         ",
            "    ,                        !- Demand Window Length                        ",
            "    10;                      !- Monthly Charge or Variable Name             ",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        var meter: OutputProcessor.Meter = Meter("WATER:FACILITY")
        state.dataOutputProcessor.meters.append(meter)
        meter.resource = Constant.eResource.Water
        state.dataOutputProcessor.meterMap.insert_or_assign("WATER:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        UpdateUtilityBills(state)
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_enum_eq(EconomicTariff.MeterType.Water, state.dataEconTariff.tariff[1].kindMtr)
        expect_enum_eq(EconConv.CCF, state.dataEconTariff.tariff[1].convChoice)
        assert_double_eq(0.35314666721488586, state.dataEconTariff.tariff[1].energyConv)

struct EconomicTariff_Gas_CCF_Test(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  UtilityCost:Tariff,                                                       ",
            "    ExampleTariff,           !- Name                                        ",
            "    NaturalGas:Facility,     !- Output Meter Name                           ",
            "    CCF,                     !- Conversion Factor Choice                    ",
            "    ,                        !- Energy Conversion Factor                    ",
            "    ,                        !- Demand Conversion Factor                    ",
            "    ,                        !- Time of Use Period Schedule Name            ",
            "    ,                        !- Season Schedule Name                        ",
            "    ,                        !- Month Schedule Name                         ",
            "    ,                        !- Demand Window Length                        ",
            "    10;                      !- Monthly Charge or Variable Name             ",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        var meter: OutputProcessor.Meter = Meter("NATURALGAS:FACILITY")
        state.dataOutputProcessor.meters.append(meter)
        meter.resource = Constant.eResource.NaturalGas
        state.dataOutputProcessor.meterMap.insert_or_assign("NATURALGAS:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        UpdateUtilityBills(state)
        ;
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_enum_eq(EconomicTariff.MeterType.Gas, state.dataEconTariff.tariff[1].kindMtr)
        expect_enum_eq(EconConv.CCF, state.dataEconTariff.tariff[1].convChoice)
        assert_double_eq(9.4781712e-9, state.dataEconTariff.tariff[1].energyConv)

struct EconomicTariff_Electric_CCF_Test(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "  UtilityCost:Tariff,                                                       ",
            "    ExampleTariff,           !- Name                                        ",
            "    Electricity:Facility,    !- Output Meter Name                           ",
            "    CCF,                     !- Conversion Factor Choice                    ",
            "    ,                        !- Energy Conversion Factor                    ",
            "    ,                        !- Demand Conversion Factor                    ",
            "    ,                        !- Time of Use Period Schedule Name            ",
            "    ,                        !- Season Schedule Name                        ",
            "    ,                        !- Month Schedule Name                         ",
            "    ,                        !- Demand Window Length                        ",
            "    10;                      !- Monthly Charge or Variable Name             ",
        ])
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        var meter: OutputProcessor.Meter = Meter("ELECTRICITY:FACILITY")
        state.dataOutputProcessor.meters.append(meter)
        meter.resource = Constant.eResource.Electricity
        state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        UpdateUtilityBills(state)
        ;
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_eq(EconomicTariff.MeterType.ElecSimple, state.dataEconTariff.tariff[1].kindMtr)
        expect_enum_eq(EconConv.KWH, state.dataEconTariff.tariff[1].convChoice)
        assert_double_eq(0.0000002778, state.dataEconTariff.tariff[1].energyConv)
        assert_double_eq(0.001, state.dataEconTariff.tariff[1].demandConv)

struct EconomicTariff_LEEDtariffReporting_Test(EnergyPlusFixture):
    def run(self) raises:
        state.init_state(state)
        state.dataOutputProcessor.meters.append(Meter("ELECTRICITY:FACILITY"))
        state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        state.dataOutputProcessor.meters.append(Meter("NATURALGAS:FACILITY"))
        state.dataOutputProcessor.meterMap.insert_or_assign("NATURALGAS:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        state.dataOutputProcessor.meters.append(Meter("DISTRICTCOOLING:FACILITY"))
        state.dataOutputProcessor.meterMap.insert_or_assign("DISTRICTCOOLING:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        state.dataOutputProcessor.meters.append(Meter("DISTRICTHEATINGWATER:FACILITY"))
        state.dataOutputProcessor.meterMap.insert_or_assign("DISTRICTHEATINGWATER:FACILITY", len(state.dataOutputProcessor.meters) - 1)
        state.dataEconTariff.numTariff = 4
        state.dataEconTariff.tariff.allocate(state.dataEconTariff.numTariff)
        state.dataEconTariff.tariff[1].tariffName = "SecondaryGeneralUnit"
        state.dataEconTariff.tariff[1].isSelected = true
        state.dataEconTariff.tariff[1].totalAnnualCost = 4151.45
        state.dataEconTariff.tariff[1].totalAnnualEnergy = 4855.21
        state.dataEconTariff.tariff[1].kindMtr = EconomicTariff.MeterType.ElecPurchased
        state.dataEconTariff.tariff[1].reportMeterIndx = GetMeterIndex(state, "ELECTRICITY:FACILITY")
        state.dataEconTariff.tariff[1].demandWindow = DemandWindow.Day
        state.dataEconTariff.tariff[2].tariffName = "SmallCGUnit"
        state.dataEconTariff.tariff[2].isSelected = true
        state.dataEconTariff.tariff[2].totalAnnualCost = 415.56
        state.dataEconTariff.tariff[2].totalAnnualEnergy = 0.00
        state.dataEconTariff.tariff[2].kindMtr = EconomicTariff.MeterType.Gas
        state.dataEconTariff.tariff[2].reportMeterIndx = GetMeterIndex(state, "NATURALGAS:FACILITY")
        state.dataEconTariff.tariff[2].demandWindow = DemandWindow.Day
        state.dataEconTariff.tariff[3].tariffName = "DistrictCoolingUnit"
        state.dataEconTariff.tariff[3].isSelected = true
        state.dataEconTariff.tariff[3].totalAnnualCost = 55.22
        state.dataEconTariff.tariff[3].totalAnnualEnergy = 8.64
        state.dataEconTariff.tariff[3].kindMtr = EconomicTariff.MeterType.Other
        state.dataEconTariff.tariff[3].reportMeterIndx = GetMeterIndex(state, "DISTRICTCOOLING:FACILITY")
        state.dataEconTariff.tariff[3].demandWindow = DemandWindow.Day
        state.dataEconTariff.tariff[4].tariffName = "DistrictHeatingUnit"
        state.dataEconTariff.tariff[4].isSelected = true
        state.dataEconTariff.tariff[4].totalAnnualCost = 15.98
        state.dataEconTariff.tariff[4].totalAnnualEnergy = 1.47
        state.dataEconTariff.tariff[4].kindMtr = EconomicTariff.MeterType.Other
        state.dataEconTariff.tariff[4].reportMeterIndx = GetMeterIndex(state, "DISTRICTHEATINGWATER:FACILITY")
        state.dataEconTariff.tariff[4].demandWindow = DemandWindow.Day
        for tariff in state.dataEconTariff.tariff:
            tariff.demandWindow = EconomicTariff.DemandWindow.Hour
        LEEDtariffReporting(state)
        expect_eq("SecondaryGeneralUnit", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsRtNm, "Electricity"))
        expect_eq("SmallCGUnit", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsRtNm, "Natural Gas"))
        expect_eq("DistrictCoolingUnit", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsRtNm, "District Cooling"))
        expect_eq("DistrictHeatingUnit", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsRtNm, "District Heating Water"))
        expect_eq("0.855", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsVirt, "Electricity"))
        expect_eq("6.391", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsVirt, "District Cooling"))
        expect_eq("10.871", RetrievePreDefTableEntry(state, state.dataOutRptPredefined.pdchLeedEtsVirt, "District Heating Water"))

struct EconomicTariff_GatherForEconomics(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "RunPeriodControl:DaylightSavingTime,",
            "  2nd Sunday in March,     !- Start Date",
            "  1st Sunday in November;  !- End Date",
            "SimulationControl,",
            "  Yes,                     !- Do Zone Sizing Calculation",
            "  Yes,                     !- Do System Sizing Calculation",
            "  No,                      !- Do Plant Sizing Calculation",
            "  No,                      !- Run Simulation for Sizing Periods",
            "  YES;                     !- Run Simulation for Weather File Run Periods",
            "Building,",
            "  Mid-Rise Apartment,      !- Name",
            "  0,                       !- North Axis {deg}",
            "  City,                    !- Terrain",
            "  0.04,                    !- Loads Convergence Tolerance Value",
            "  0.4,                     !- Temperature Convergence Tolerance Value {deltaC}",
            "  FullExterior,            !- Solar Distribution",
            "  25,                      !- Maximum Number of Warmup Days",
            "  6;                       !- Minimum Number of Warmup Days",
            "Timestep,",
            "  4;                       !- Number of Timesteps per Hour",
            "RunPeriod,",
            "  Annual,                  !- Name",
            "  1,                       !- Begin Month",
            "  1,                       !- Begin Day of Month",
            "  ,                        !- Begin Year",
            "  12,                      !- End Month",
            "  31,                      !- End Day of Month",
            "  ,                        !- End Year",
            "  Sunday,                  !- Day of Week for Start Day",
            "  No,                      !- Use Weather File Holidays and Special Days",
            "  No,                      !- Use Weather File Daylight Saving Period",
            "  Yes,                     !- Apply Weekend Holiday Rule",
            "  Yes,                     !- Use Weather File Rain Indicators",
            "  Yes;                     !- Use Weather File Snow Indicators",
            "GlobalGeometryRules,",
            "  LowerLeftCorner,         !- Starting Vertex Position",
            "  Clockwise,               !- Vertex Entry Direction",
            "  Relative;                !- Coordinate System",
            "ScheduleTypeLimits,",
            "  Any Number;              !- Name",
            "Schedule:Constant,",
            "  Always On Discrete,      !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  1;                       !- Hourly Value",
            "Exterior:Lights,",
            "  Exterior Facade Lighting,!- Name",
            "  Always On Discrete,      !- Schedule Name",
            "  1000.00,                 !- Design Level {W}",
            "  ScheduleNameOnly,        !- Control Option",
            "  Exterior Facade Lighting;!- End-Use Subcategory",
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  Seasonal_Tariff,         !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Charge:Simple,",
            "  Seasonal_Tariff_Winter_Charge, !- Utility Cost Charge Simple Name",
            "  Seasonal_Tariff,         !- Tariff Name",
            "  totalEnergy,             !- Source Variable",
            "  Winter,                  !- Season",
            "  EnergyCharges,           !- Category Variable Name",
            "  0.02;                    !- Cost per Unit Value or Variable Name",
            "UtilityCost:Charge:Simple,",
            "  Seasonal_Tariff_Summer_Charge, !- Utility Cost Charge Simple Name",
            "  Seasonal_Tariff,         !- Tariff Name",
            "  totalEnergy,             !- Source Variable",
            "  Summer,                  !- Season",
            "  EnergyCharges,           !- Category Variable Name",
            "  0.04;                    !- Cost per Unit Value or Variable Name",
            "Output:Table:SummaryReports,",
            "  TariffReport;            !- Report 1 Name",
            "OutputControl:Table:Style,",
            "  HTML;                                   !- Column Separator",
            "Output:SQLite,",
            "  SimpleAndTabular;                       !- Option Type",
            "Output:Meter,Electricity:Facility,timestep;"
        ])
        assert_true(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 4
        state.dataGlobal.MinutesInTimeStep = 15
        state.dataGlobal.TimeStepZone = 0.25
        state.dataGlobal.TimeStepZoneSec = state.dataGlobal.TimeStepZone * Constant.rSecsInHour
        state.init_state(state)
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        expect_eq(1, state.dataExteriorEnergyUse.NumExteriorLights)
        expect_eq(1000, state.dataExteriorEnergyUse.ExteriorLights[1].DesignLevel)
        EconomicTariff.UpdateUtilityBills(state)
        ;
        expect_eq(1, state.dataEconTariff.numTariff)
        expect_eq("SEASONAL_TARIFF", state.dataEconTariff.tariff[1].tariffName)
        expect_enum_eq(EconConv.KWH, state.dataEconTariff.tariff[1].convChoice)
        expect_eq(0, state.dataEconTariff.tariff[1].monthChgVal)
        expect_eq("ELECTRICITY SEASON SCHEDULE", state.dataEconTariff.tariff[1].seasonSched.Name)
        expect_eq(2, state.dataEconTariff.numChargeSimple)
        expect_enum_eq(Season.Winter, state.dataEconTariff.chargeSimple[1].season)
        expect_eq(0.02, state.dataEconTariff.chargeSimple[1].costPerVal)
        expect_enum_eq(Season.Summer, state.dataEconTariff.chargeSimple[2].season)
        expect_eq(0.04, state.dataEconTariff.chargeSimple[2].costPerVal)
        state.dataGlobal.KindOfSim = Constant.KindOfSim.RunPeriodWeather
        expect_enum_eq(Season.Invalid, state.dataEconTariff.tariff[1].seasonForMonth[5])
        expect_enum_eq(Season.Invalid, state.dataEconTariff.tariff[1].seasonForMonth[6])
        state.dataEnvrn.Month = 5
        state.dataEnvrn.DayOfMonth = 31
        state.dataGlobal.HourOfDay = 23
        state.dataEnvrn.DSTIndicator = 1
        state.dataEnvrn.MonthTomorrow = 6
        state.dataEnvrn.DayOfWeek = 4
        state.dataEnvrn.DayOfWeekTomorrow = 5
        state.dataEnvrn.HolidayIndex = 0
        state.dataGlobal.TimeStep = 4
        state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
        Sched.UpdateScheduleVals(state)
        expect_eq(1.0, Sched.GetSchedule(state, "ALWAYS ON DISCRETE").getHrTsVal(state, state.dataGlobal.HourOfDay, state.dataGlobal.TimeStep))
        expect_eq(1.0, state.dataEconTariff.tariff[1].seasonSched.getCurrentVal())
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        expect_eq(1000.0, state.dataExteriorEnergyUse.ExteriorLights[1].Power)
        expect_eq(state.dataExteriorEnergyUse.ExteriorLights[1].Power * state.dataGlobal.TimeStepZoneSec,
                  state.dataExteriorEnergyUse.ExteriorLights[1].CurrentUse)
        expect_eq(0, state.dataEconTariff.tariff[1].gatherEnergy(state.dataEnvrn.Month)[int(Period.Peak)])
        state.dataGlobal.DoOutputReporting = true
        EconomicTariff.UpdateUtilityBills(state)
        ;
        expect_enum_eq(Season.Winter, state.dataEconTariff.tariff[1].seasonForMonth[5])
        expect_enum_eq(Season.Invalid, state.dataEconTariff.tariff[1].seasonForMonth[6])
        state.dataEnvrn.Month = 5
        state.dataEnvrn.DayOfMonth = 31
        state.dataGlobal.HourOfDay = 24
        state.dataEnvrn.DSTIndicator = 1
        state.dataEnvrn.MonthTomorrow = 6
        state.dataEnvrn.DayOfWeek = 4
        state.dataEnvrn.DayOfWeekTomorrow = 5
        state.dataEnvrn.HolidayIndex = 0
        state.dataGlobal.TimeStep = 1
        state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
        Sched.UpdateScheduleVals(state)
        expect_eq(3.0, state.dataEconTariff.tariff[1].seasonSched.getCurrentVal())
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        expect_eq(1000.0, state.dataExteriorEnergyUse.ExteriorLights[1].Power)
        expect_eq(state.dataExteriorEnergyUse.ExteriorLights[1].Power * state.dataGlobal.TimeStepZoneSec,
                  state.dataExteriorEnergyUse.ExteriorLights[1].CurrentUse)
        EconomicTariff.UpdateUtilityBills(state)
        ;
        expect_enum_eq(Season.Winter, state.dataEconTariff.tariff[1].seasonForMonth[5])
        expect_enum_eq(Season.Summer, state.dataEconTariff.tariff[1].seasonForMonth[6])

struct EconomicTariff_GatherForEconomics_ZeroMeterIndex(EnergyPlusFixture):
    def run(self) raises:
        state.init_state(state)
        state.dataEconTariff.numTariff = 1
        state.dataEconTariff.tariff.allocate(state.dataEconTariff.numTariff)
        state.dataEconTariff.tariff[1].reportMeterIndx = 0
        state.dataEconTariff.tariff[1].demWinTime = 1.
        state.dataEconTariff.tariff[1].energyConv = 1.
        state.dataGlobal.TimeStepZoneSec = 3600
        state.dataEnvrn.Month = 1
        var meter: Meter = None
        meter = Meter("FacElec")
        meter.CurTSValue = 100
        state.dataOutputProcessor.meters.append(meter)
        GatherForEconomics(state)
        expect_eq(100, state.dataEconTariff.tariff[1].gatherEnergy(1)[1])

struct EconomicTariff_PushPopStack(EnergyPlusFixture):
    def run(self) raises:
        state.init_state(state)
        state.dataEconTariff.numTariff = 1
        state.dataEconTariff.tariff.allocate(state.dataEconTariff.numTariff)
        var aMonths: Array1D[Real64](NumMonths)
        var aVarPt: Int
        var bMonths: Array1D[Real64](NumMonths)
        var bVarPt: Int
        var cMonths: Array1D[Real64](NumMonths)
        var cVarPt: Int
        aMonths = [1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]
        aVarPt = 0
        pushStack(state, aMonths, aVarPt)
        expect_eq(1, state.dataEconTariff.topOfStack)
        expect_eq(0, state.dataEconTariff.stack[1].varPt)
        expect_eq(aMonths[0], state.dataEconTariff.stack[1].values[0])
        expect_eq(aMonths[1], state.dataEconTariff.stack[1].values[1])
        expect_eq(aMonths[2], state.dataEconTariff.stack[1].values[2])
        expect_eq(aMonths[3], state.dataEconTariff.stack[1].values[3])
        expect_eq(aMonths[4], state.dataEconTariff.stack[1].values[4])
        expect_eq(aMonths[5], state.dataEconTariff.stack[1].values[5])
        bMonths = [2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6]
        bVarPt = 0
        pushStack(state, bMonths, bVarPt)
        expect_eq(2, state.dataEconTariff.topOfStack)
        expect_eq(0, state.dataEconTariff.stack[1].varPt)
        expect_eq(aMonths[0], state.dataEconTariff.stack[1].values[0])
        expect_eq(aMonths[1], state.dataEconTariff.stack[1].values[1])
        expect_eq(aMonths[2], state.dataEconTariff.stack[1].values[2])
        expect_eq(aMonths[3], state.dataEconTariff.stack[1].values[3])
        expect_eq(aMonths[4], state.dataEconTariff.stack[1].values[4])
        expect_eq(aMonths[5], state.dataEconTariff.stack[1].values[5])
        expect_eq(0, state.dataEconTariff.stack[2].varPt)
        expect_eq(bMonths[0], state.dataEconTariff.stack[2].values[0])
        expect_eq(bMonths[1], state.dataEconTariff.stack[2].values[1])
        expect_eq(bMonths[2], state.dataEconTariff.stack[2].values[2])
        expect_eq(bMonths[3], state.dataEconTariff.stack[2].values[3])
        expect_eq(bMonths[4], state.dataEconTariff.stack[2].values[4])
        expect_eq(bMonths[5], state.dataEconTariff.stack[2].values[5])
        popStack(state, cMonths, cVarPt)
        expect_eq(1, state.dataEconTariff.topOfStack)
        expect_eq(0, state.dataEconTariff.stack[1].varPt)
        expect_eq(aMonths[0], state.dataEconTariff.stack[1].values[0])
        expect_eq(aMonths[1], state.dataEconTariff.stack[1].values[1])
        expect_eq(aMonths[2], state.dataEconTariff.stack[1].values[2])
        expect_eq(aMonths[3], state.dataEconTariff.stack[1].values[3])
        expect_eq(aMonths[4], state.dataEconTariff.stack[1].values[4])
        expect_eq(aMonths[5], state.dataEconTariff.stack[1].values[5])
        expect_eq(bMonths[0], cMonths[0])
        expect_eq(bMonths[1], cMonths[1])
        expect_eq(bMonths[2], cMonths[2])
        expect_eq(bMonths[3], cMonths[3])
        expect_eq(bMonths[4], cMonths[4])
        expect_eq(bMonths[5], cMonths[5])
        expect_eq(bVarPt, cVarPt)
        popStack(state, cMonths, cVarPt)
        expect_eq(0, state.dataEconTariff.topOfStack)
        expect_eq(aMonths[0], cMonths[0])
        expect_eq(aMonths[1], cMonths[1])
        expect_eq(aMonths[2], cMonths[2])
        expect_eq(aMonths[3], cMonths[3])
        expect_eq(aMonths[4], cMonths[4])
        expect_eq(aMonths[5], cMonths[5])
        expect_eq(aVarPt, cVarPt)
        state.dataEconTariff.econVar.allocate(10)
        state.dataEconTariff.econVar[1].isEvaluated = false
        state.dataEconTariff.econVar[1].kindOfObj = ObjType.Variable
        var dMonths: Array1D[Real64](NumMonths)
        var dVarPt: Int
        dMonths = [3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6]
        dVarPt = 1
        state.dataEconTariff.econVar[dVarPt].values = dMonths
        pushStack(state, aMonths, dVarPt)
        popStack(state, cMonths, cVarPt)
        expect_eq(0, state.dataEconTariff.topOfStack)
        expect_eq(dMonths[0], cMonths[0])
        expect_eq(dMonths[1], cMonths[1])
        expect_eq(dMonths[2], cMonths[2])
        expect_eq(dMonths[3], cMonths[3])
        expect_eq(dMonths[4], cMonths[4])
        expect_eq(dMonths[5], cMonths[5])
        expect_eq(dVarPt, cVarPt)

struct EconomicTariff_evaluateChargeSimple(EnergyPlusFixture):
    def run(self) raises:
        state.init_state(state)
        var curTariff: Int = 6
        state.dataEconTariff.tariff.allocate(curTariff)
        var curEconVar: Int = 7
        state.dataEconTariff.econVar.allocate(curEconVar)
        state.dataEconTariff.econVar[curEconVar].tariffIndx = curTariff
        state.dataEconTariff.econVar[curEconVar].kindOfObj = ObjType.Variable
        var results: Array1D[Real64](NumMonths)
        var sourceEconVar: Int = 4
        var sourceMonths: Array1D[Real64](NumMonths)
        sourceMonths = [310, 320, 330, 340, 350, 360, 360, 350, 340, 330, 320, 310]
        state.dataEconTariff.econVar[sourceEconVar].values = sourceMonths
        var costPerEconVar: Int = 6
        var costPerMonths: Array1D[Real64](NumMonths)
        costPerMonths = [0.1, 0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.2, 0.1, 0.1, 0.1, 0.1]
        state.dataEconTariff.econVar[costPerEconVar].values = costPerMonths
        var curSimpChg: Int = 3
        state.dataEconTariff.econVar[curEconVar].index = curSimpChg
        state.dataEconTariff.chargeSimple.allocate(curSimpChg)
        state.dataEconTariff.chargeSimple[curSimpChg].namePt = curEconVar
        state.dataEconTariff.chargeSimple[curSimpChg].tariffIndx = curTariff
        state.dataEconTariff.chargeSimple[curSimpChg].sourcePt = sourceEconVar
        state.dataEconTariff.chargeSimple[curSimpChg].costPerPt = costPerEconVar
        state.dataEconTariff.chargeSimple[curSimpChg].season = Season.Annual
        evaluateChargeSimple(state, curEconVar)
        results = state.dataEconTariff.econVar[curEconVar].values
        expect_near(results[0], 310 * 0.1, 0.01)
        expect_near(results[1], 320 * 0.1, 0.01)
        expect_near(results[2], 330 * 0.1, 0.01)
        expect_near(results[3], 340 * 0.2, 0.01)
        expect_near(results[4], 350 * 0.2, 0.01)
        expect_near(results[5], 360 * 0.2, 0.01)
        expect_near(results[6], 360 * 0.2, 0.01)
        expect_near(results[7], 350 * 0.2, 0.01)
        expect_near(results[8], 340 * 0.1, 0.01)
        expect_near(results[9], 330 * 0.1, 0.01)
        expect_near(results[10], 320 * 0.1, 0.01)
        expect_near(results[11], 310 * 0.1, 0.01)
        state.dataEconTariff.chargeSimple[curSimpChg].costPerPt = 0
        state.dataEconTariff.chargeSimple[curSimpChg].costPerVal = 0.15
        evaluateChargeSimple(state, curEconVar)
        results = state.dataEconTariff.econVar[curEconVar].values
        expect_near(results[0], 310 * 0.15, 0.01)
        expect_near(results[1], 320 * 0.15, 0.01)
        expect_near(results[2], 330 * 0.15, 0.01)
        expect_near(results[3], 340 * 0.15, 0.01)
        expect_near(results[4], 350 * 0.15, 0.01)
        expect_near(results[5], 360 * 0.15, 0.01)
        expect_near(results[6], 360 * 0.15, 0.01)
        expect_near(results[7], 350 * 0.15, 0.01)
        expect_near(results[8], 340 * 0.15, 0.01)
        expect_near(results[9], 330 * 0.15, 0.01)
        expect_near(results[10], 320 * 0.15, 0.01)
        expect_near(results[11], 310 * 0.15, 0.01)
        state.dataEconTariff.chargeSimple[curSimpChg].season = Season.Summer
        var summerEconVar: Int = 2
        var summerMonths: Array1D[Real64](NumMonths)
        costPerMonths = [0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0]
        state.dataEconTariff.econVar[summerEconVar].values = costPerMonths
        state.dataEconTariff.tariff[curTariff].natives[int(Native.IsSummer)] = summerEconVar
        evaluateChargeSimple(state, curEconVar)
        results = state.dataEconTariff.econVar[curEconVar].values
        expect_near(results[0], 0., 0.01)
        expect_near(results[1], 0., 0.01)
        expect_near(results[2], 0., 0.01)
        expect_near(results[3], 0., 0.01)
        expect_near(results[4], 350 * 0.15, 0.01)
        expect_near(results[5], 360 * 0.15, 0.01)
        expect_near(results[6], 360 * 0.15, 0.01)
        expect_near(results[7], 350 * 0.15, 0.01)
        expect_near(results[8], 340 * 0.15, 0.01)
        expect_near(results[9], 0., 0.01)
        expect_near(results[10], 0., 0.01)
        expect_near(results[11], 0., 0.01)

struct EconomicTariff_evaluateChargeBlock(EnergyPlusFixture):
    def run(self) raises:
        state.init_state(state)
        var curTariff: Int = 8
        state.dataEconTariff.tariff.allocate(curTariff)
        var curEconVar: Int = 11
        state.dataEconTariff.econVar.allocate(curEconVar)
        state.dataEconTariff.econVar[curEconVar].tariffIndx = curTariff
        state.dataEconTariff.econVar[curEconVar].kindOfObj = ObjType.Variable
        var results: Array1D[Real64](NumMonths)
        var sourceEconVar: Int = 4
        var sourceMonths: Array1D[Real64](NumMonths)
        sourceMonths = [450, 650, 950, 1350, 1850, 2850, 500, 1000, 1500, 501, 1001, 1501]
        state.dataEconTariff.econVar[sourceEconVar].values = sourceMonths
        var curChgBlk: Int = 3
        state.dataEconTariff.econVar[curEconVar].index = curChgBlk
        state.dataEconTariff.chargeBlock.allocate(curChgBlk)
        state.dataEconTariff.chargeBlock[curChgBlk].namePt = curEconVar
        state.dataEconTariff.chargeBlock[curChgBlk].tariffIndx = curTariff
        state.dataEconTariff.chargeBlock[curChgBlk].sourcePt = sourceEconVar
        state.dataEconTariff.chargeBlock[curChgBlk].season = Season.Annual
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzMultPt = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzMultVal = 1
        var numBlocks: Int = 3
        state.dataEconTariff.chargeBlock[curChgBlk].numBlk = numBlocks
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzPt.allocate(numBlocks)
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzVal.allocate(numBlocks)
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostPt.allocate(numBlocks)
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostVal.allocate(numBlocks)
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzPt[0] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzVal[0] = 500
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostPt[0] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostVal[0] = 0.15
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzPt[1] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzVal[1] = 1000
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostPt[1] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostVal[1] = 0.12
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzPt[2] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkSzVal[2] = 999999999
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostPt[2] = 0
        state.dataEconTariff.chargeBlock[curChgBlk].blkCostVal[2] = 0.10
        evaluateChargeBlock(state, curEconVar)
        results = state.dataEconTariff.econVar[curEconVar].values
        expect_near(results[0], 450 * 0.15, 0.01)
        expect_near(results[1], 500 * 0.15 + 150 * 0.12, 0.01)
        expect_near(results[2], 500 * 0.15 + 450 * 0.12, 0.01)
        expect_near(results[3], 500 * 0.15 + 850 * 0.12, 0.01)
        expect_near(results[4], 500 * 0.15 + 1000 * 0.12 + 350 * 0.10, 0.01)
        expect_near(results[5], 500 * 0.15 + 1000 * 0.12 + 1350 * 0.10, 0.01)
        expect_near(results[6], 500 * 0.15, 0.01)
        expect_near(results[7], 500 * 0.15 + 500 * 0.12, 0.01)
        expect_near(results[8], 500 * 0.15 + 1000 * 0.12, 0.01)
        expect_near(results[9], 500 * 0.15 + 1 * 0.12, 0.01)
        expect_near(results[10], 500 * 0.15 + 501 * 0.12, 0.01)
        expect_near(results[11], 500 * 0.15 + 1000 * 0.12 + 1 * 0.10, 0.01)

struct InputEconomics_UtilityCost_Variable_Test0(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  ExampleAWithVariableMonthlyCharge,     !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Variable,",
            "VariableFixedCharge, !-Name",
            "ExampleAWithVariableMonthlyCharge, !-Tariff Name",
            "Demand, !-Variable Type",
            "1.00, !-January Value",
            "2.00, !-February Value",
            "3.00, !-March Value",
            "4.00, !-April Value",
            "5.00, !-May Value",
            "6.00, !-June Value",
            "7.00, !-July Value",
            "8.00, !-August Value",
            "9.00, !-September Value",
            "10.00, !-October Value",
            "11.00, !-November Value",
            "12.00; !-December Value"})
        var ErrorsFound: Bool = false
        assert_true(process_idf(idf_objects))
        state.init_state(state)
        GetInputEconomicsVariable(state, ErrorsFound)
        expect_enum_eq(state.dataEconTariff.econVar[1].varUnitType, VarUnitType.Demand)
        expect_eq(state.dataEconTariff.econVar[1].values[0], 1.00)
        expect_eq(state.dataEconTariff.econVar[1].values[1], 2.00)
        expect_eq(state.dataEconTariff.econVar[1].values[2], 3.00)
        expect_eq(state.dataEconTariff.econVar[1].values[3], 4.00)
        expect_eq(state.dataEconTariff.econVar[1].values[4], 5.00)
        expect_eq(state.dataEconTariff.econVar[1].values[5], 6.00)
        expect_eq(state.dataEconTariff.econVar[1].values[6], 7.00)
        expect_eq(state.dataEconTariff.econVar[1].values[7], 8.00)
        expect_eq(state.dataEconTariff.econVar[1].values[8], 9.00)
        expect_eq(state.dataEconTariff.econVar[1].values[9], 10.00)
        expect_eq(state.dataEconTariff.econVar[1].values[10], 11.00)
        expect_eq(state.dataEconTariff.econVar[1].values[11], 12.00)

struct InputEconomics_UtilityCost_Variable_Test1(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects1: String = delimited_string([
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  ExampleAWithVariableMonthlyCharge,     !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Variable,",
            "VariableFixedCharge, !-Name",
            "ExampleAWithVariableMonthlyCharge, !-Tariff Name",
            "Energy, !-Variable Type",
            "1.00, !-January Value",
            "2.00, !-February Value",
            "3.00, !-March Value",
            "4.00, !-April Value",
            "5.00, !-May Value",
            "6.00, !-June Value",
            "7.00, !-July Value",
            "8.00, !-August Value",
            "9.00, !-September Value",
            "10.00, !-October Value",
            "11.00, !-November Value",
            "12.00; !-December Value"})
        var ErrorsFound: Bool = false
        assert_true(process_idf(idf_objects1))
        state.init_state(state)
        GetInputEconomicsVariable(state, ErrorsFound)
        expect_enum_eq(state.dataEconTariff.econVar[1].varUnitType, VarUnitType.Energy)
        expect_eq(state.dataEconTariff.econVar[1].values[0], 1.00)
        expect_eq(state.dataEconTariff.econVar[1].values[1], 2.00)
        expect_eq(state.dataEconTariff.econVar[1].values[2], 3.00)
        expect_eq(state.dataEconTariff.econVar[1].values[3], 4.00)
        expect_eq(state.dataEconTariff.econVar[1].values[4], 5.00)
        expect_eq(state.dataEconTariff.econVar[1].values[5], 6.00)
        expect_eq(state.dataEconTariff.econVar[1].values[6], 7.00)
        expect_eq(state.dataEconTariff.econVar[1].values[7], 8.00)
        expect_eq(state.dataEconTariff.econVar[1].values[8], 9.00)
        expect_eq(state.dataEconTariff.econVar[1].values[9], 10.00)
        expect_eq(state.dataEconTariff.econVar[1].values[10], 11.00)
        expect_eq(state.dataEconTariff.econVar[1].values[11], 12.00)

struct InputEconomics_UtilityCost_Variable_Test2(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects2: String = delimited_string([
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  ExampleAWithVariableMonthlyCharge,     !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Variable,",
            "VariableFixedCharge, !-Name",
            "ExampleAWithVariableMonthlyCharge, !-Tariff Name",
            "Dimensionless, !-Variable Type",
            "1.00, !-January Value",
            "2.00, !-February Value",
            "3.00, !-March Value",
            "4.00, !-April Value",
            "5.00, !-May Value",
            "6.00, !-June Value",
            "7.00, !-July Value",
            "8.00, !-August Value",
            "9.00, !-September Value",
            "10.00, !-October Value",
            "11.00, !-November Value",
            "12.00; !-December Value"})
        var ErrorsFound: Bool = false
        assert_true(process_idf(idf_objects2))
        state.init_state(state)
        GetInputEconomicsVariable(state, ErrorsFound)
        expect_enum_eq(state.dataEconTariff.econVar[1].varUnitType, VarUnitType.Dimensionless)
        expect_eq(state.dataEconTariff.econVar[1].values[0], 1.00)
        expect_eq(state.dataEconTariff.econVar[1].values[1], 2.00)
        expect_eq(state.dataEconTariff.econVar[1].values[2], 3.00)
        expect_eq(state.dataEconTariff.econVar[1].values[3], 4.00)
        expect_eq(state.dataEconTariff.econVar[1].values[4], 5.00)
        expect_eq(state.dataEconTariff.econVar[1].values[5], 6.00)
        expect_eq(state.dataEconTariff.econVar[1].values[6], 7.00)
        expect_eq(state.dataEconTariff.econVar[1].values[7], 8.00)
        expect_eq(state.dataEconTariff.econVar[1].values[8], 9.00)
        expect_eq(state.dataEconTariff.econVar[1].values[9], 10.00)
        expect_eq(state.dataEconTariff.econVar[1].values[10], 11.00)
        expect_eq(state.dataEconTariff.econVar[1].values[11], 12.00)

struct InputEconomics_UtilityCost_Variable_Test3(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects3: String = delimited_string([
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  ExampleAWithVariableMonthlyCharge,     !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Variable,",
            "VariableFixedCharge, !-Name",
            "ExampleAWithVariableMonthlyCharge, !-Tariff Name",
            "Currency, !-Variable Type",
            "1.00, !-January Value",
            "2.00, !-February Value",
            "3.00, !-March Value",
            "4.00, !-April Value",
            "5.00, !-May Value",
            "6.00, !-June Value",
            "7.00, !-July Value",
            "8.00, !-August Value",
            "9.00, !-September Value",
            "10.00, !-October Value",
            "11.00, !-November Value",
            "12.00; !-December Value"})
        var ErrorsFound: Bool = false
        assert_true(process_idf(idf_objects3))
        state.init_state(state)
        GetInputEconomicsVariable(state, ErrorsFound)
        expect_enum_eq(state.dataEconTariff.econVar[1].varUnitType, VarUnitType.Currency)
        expect_eq(state.dataEconTariff.econVar[1].values[0], 1.00)
        expect_eq(state.dataEconTariff.econVar[1].values[1], 2.00)
        expect_eq(state.dataEconTariff.econVar[1].values[2], 3.00)
        expect_eq(state.dataEconTariff.econVar[1].values[3], 4.00)
        expect_eq(state.dataEconTariff.econVar[1].values[4], 5.00)
        expect_eq(state.dataEconTariff.econVar[1].values[5], 6.00)
        expect_eq(state.dataEconTariff.econVar[1].values[6], 7.00)
        expect_eq(state.dataEconTariff.econVar[1].values[7], 8.00)
        expect_eq(state.dataEconTariff.econVar[1].values[8], 9.00)
        expect_eq(state.dataEconTariff.econVar[1].values[9], 10.00)
        expect_eq(state.dataEconTariff.econVar[1].values[10], 11.00)
        expect_eq(state.dataEconTariff.econVar[1].values[11], 12.00)

struct WriteEconomicTariffTable_DualUnits(SQLiteFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "RunPeriodControl:DaylightSavingTime,",
            "  2nd Sunday in March,     !- Start Date",
            "  1st Sunday in November;  !- End Date",
            "SimulationControl,",
            "  Yes,                     !- Do Zone Sizing Calculation",
            "  Yes,                     !- Do System Sizing Calculation",
            "  No,                      !- Do Plant Sizing Calculation",
            "  No,                      !- Run Simulation for Sizing Periods",
            "  YES;                     !- Run Simulation for Weather File Run Periods",
            "Building,",
            "  Mid-Rise Apartment,      !- Name",
            "  0,                       !- North Axis {deg}",
            "  City,                    !- Terrain",
            "  0.04,                    !- Loads Convergence Tolerance Value",
            "  0.4,                     !- Temperature Convergence Tolerance Value {deltaC}",
            "  FullExterior,            !- Solar Distribution",
            "  25,                      !- Maximum Number of Warmup Days",
            "  6;                       !- Minimum Number of Warmup Days",
            "Timestep,",
            "  4;                       !- Number of Timesteps per Hour",
            "RunPeriod,",
            "  Annual,                  !- Name",
            "  1,                       !- Begin Month",
            "  1,                       !- Begin Day of Month",
            "  ,                        !- Begin Year",
            "  12,                      !- End Month",
            "  31,                      !- End Day of Month",
            "  ,                        !- End Year",
            "  Sunday,                  !- Day of Week for Start Day",
            "  No,                      !- Use Weather File Holidays and Special Days",
            "  No,                      !- Use Weather File Daylight Saving Period",
            "  Yes,                     !- Apply Weekend Holiday Rule",
            "  Yes,                     !- Use Weather File Rain Indicators",
            "  Yes;                     !- Use Weather File Snow Indicators",
            "GlobalGeometryRules,",
            "  LowerLeftCorner,         !- Starting Vertex Position",
            "  Clockwise,               !- Vertex Entry Direction",
            "  Relative;                !- Coordinate System",
            "ScheduleTypeLimits,",
            "  Any Number;              !- Name",
            "Schedule:Constant,",
            "  Always On Discrete,      !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  1;                       !- Hourly Value",
            "Exterior:Lights,",
            "  Exterior Facade Lighting,!- Name",
            "  Always On Discrete,      !- Schedule Name",
            "  1000.00,                 !- Design Level {W}",
            "  ScheduleNameOnly,        !- Control Option",
            "  Exterior Facade Lighting;!- End-Use Subcategory",
            "Schedule:Compact,",
            "  Electricity Season Schedule,  !- Name",
            "  Any Number,              !- Schedule Type Limits Name",
            "  Through: 5/31,           !- Field 1",
            "  For: AllDays,            !- Field 2",
            "  Until: 24:00,            !- Field 3",
            "  1,                       !- Field 4",
            "  Through: 9/30,           !- Field 5",
            "  For: AllDays,            !- Field 6",
            "  Until: 24:00,            !- Field 7",
            "  3,                       !- Field 8",
            "  Through: 12/31,          !- Field 9",
            "  For: AllDays,            !- Field 10",
            "  Until: 24:00,            !- Field 11",
            "  1;                       !- Field 12",
            "UtilityCost:Tariff,",
            "  Seasonal_Tariff,         !- Name",
            "  ElectricityNet:Facility, !- Output Meter Name",
            "  kWh,                     !- Conversion Factor Choice",
            "  ,                        !- Energy Conversion Factor",
            "  ,                        !- Demand Conversion Factor",
            "  ,                        !- Time of Use Period Schedule Name",
            "  Electricity Season Schedule,  !- Season Schedule Name",
            "  ,                        !- Month Schedule Name",
            "  ,                        !- Demand Window Length",
            "  0,                       !- Monthly Charge or Variable Name",
            "  ,                        !- Minimum Monthly Charge or Variable Name",
            "  ,                        !- Real Time Pricing Charge Schedule Name",
            "  ,                        !- Customer Baseline Load Schedule Name",
            "  ,                        !- Group Name",
            "  NetMetering;             !- Buy Or Sell",
            "UtilityCost:Charge:Simple,",
            "  Seasonal_Tariff_Winter_Charge, !- Utility Cost Charge Simple Name",
            "  Seasonal_Tariff,         !- Tariff Name",
            "  totalEnergy,             !- Source Variable",
            "  Winter,                  !- Season",
            "  EnergyCharges,           !- Category Variable Name",
            "  0.02;                    !- Cost per Unit Value or Variable Name",
            "UtilityCost:Charge:Simple,",
            "  Seasonal_Tariff_Summer_Charge, !- Utility Cost Charge Simple Name",
            "  Seasonal_Tariff,         !- Tariff Name",
            "  totalEnergy,             !- Source Variable",
            "  Summer,                  !- Season",
            "  EnergyCharges,           !- Category Variable Name",
            "  0.04;                    !- Cost per Unit Value or Variable Name",
            "Output:Table:SummaryReports,",
            "  TariffReport;            !- Report 1 Name",
            "OutputControl:Table:Style,",
            "  HTML;                                   !- Column Separator",
            "Output:SQLite,",
            "  SimpleAndTabular;                       !- Option Type",
            "Output:Meter,Electricity:Facility,timestep;"
        ])
        assert_true(process_idf(idf_objects))
        state.dataGlobal.TimeStepsInHour = 4
        state.dataGlobal.MinutesInTimeStep = 15
        state.dataGlobal.TimeStepZone = 0.25
        state.dataGlobal.TimeStepZoneSec = state.dataGlobal.TimeStepZone * Constant.rSecsInHour
        state.init_state(state)
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        state.dataSQLiteProcedures.sqlite.createSQLiteSimulationsRecord(1, "EnergyPlus Version", "Current Time")
        state.dataOutRptTab.displayTabularBEPS = true
        state.dataOutRptTab.displayDemandEndUse = true
        state.dataOutRptTab.displayLEEDSummary = true
        state.dataOutRptTab.WriteTabularFiles = true
        OutputReportTabular.SetupUnitConversions(state)
        state.dataOutRptTab.unitsStyle_Tabular = OutputReportTabular.UnitsStyle.JtoKWH
        state.dataOutRptTab.unitsStyle_SQLite = OutputReportTabular.UnitsStyle.JtoKWH
        OutputReportTabular.setTabularReportStyles(state)
        var enerConv: Real64 = OutputReportTabular.getSpecificUnitDivider(state, "m2", "ft2")
        expect_near(enerConv, 0.092903, 0.001)
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        EconomicTariff.UpdateUtilityBills(state)
        state.dataGlobal.KindOfSim = Constant.KindOfSim.RunPeriodWeather
        state.dataEnvrn.Month = 5
        state.dataEnvrn.DayOfMonth = 31
        state.dataGlobal.HourOfDay = 23
        state.dataEnvrn.DSTIndicator = 1
        state.dataEnvrn.MonthTomorrow = 6
        state.dataEnvrn.DayOfWeek = 4
        state.dataEnvrn.DayOfWeekTomorrow = 5
        state.dataEnvrn.HolidayIndex = 0
        state.dataGlobal.TimeStep = 4
        state.dataEnvrn.DayOfYear_Schedule = General.OrdinalDay(state.dataEnvrn.Month, state.dataEnvrn.DayOfMonth, 1)
        Sched.UpdateScheduleVals(state)
        ExteriorEnergyUse.ManageExteriorEnergyUse(state)
        state.dataGlobal.DoOutputReporting = true
        EconomicTariff.UpdateUtilityBills(state)
        state.dataOutRptTab.buildingGrossFloorArea = 200.0
        state.dataOutRptTab.buildingConditionedFloorArea = 100.0
        state.dataOutRptTab.displayEconomicResultSummary = true
        state.dataEconTariff.chargeBlock.allocate(1)
        state.dataEconTariff.tariff[1].totalAnnualCost = 2000.0
        state.dataEconTariff.tariff[1].isSelected = true
        EconomicTariff.WriteTabularTariffReports(state)
        expect_eq(state.dataEconTariff.tariff[1].totalAnnualCost, 2000.0)
        var reportName: String = "Economics Results Summary Report"
        var tableName: String = "Annual Cost"
        var results0: List[tuple[String, String, String, Real64]] = [
            ("Total", "Cost", "~~$~~", 2000.0),
            ("Total", "Cost per Total Building Area", "~~$~~/m2", 10.0),
            ("Total", "Cost per Net Conditioned Building Area", "~~$~~/m2", 20.0)
        ]
        for v in results0:
            var columnName: String = v.get[0, String]()
            var rowName: String = v.get[1, String]()
            var unitName: String = v.get[2, String]()
            var expectedValue: Real64 = v.get[3, Real64]()
            var query: String = "SELECT Value From TabularDataWithStrings WHERE ReportName = '" + reportName + "' AND TableName = '" + tableName + "' AND RowName = '" + rowName + "' AND ColumnName = '" + columnName + "' AND Units = '" + unitName + "'"
            var return_val: Real64 = execAndReturnFirstDouble(query)
            expect_near(expectedValue, return_val, 0.01) or "Failed for TableName=" + tableName + "; RowName=" + rowName
        state.dataOutRptTab.unitsStyle_Tabular = OutputReportTabular.UnitsStyle.JtoKWH
        state.dataOutRptTab.unitsStyle_SQLite = OutputReportTabular.UnitsStyle.InchPound
        OutputReportTabular.setTabularReportStyles(state)
        EconomicTariff.WriteTabularTariffReports(state)
        expect_eq(state.dataEconTariff.tariff[1].totalAnnualCost, 2000.0)
        var results1: List[tuple[String, String, String, Real64]] = [
            ("Total", "Cost", "~~$~~", 2000.0),
            ("Total", "Cost per Total Building Area", "~~$~~/ft2", 10.0 * enerConv),
            ("Total", "Cost per Net Conditioned Building Area", "~~$~~/ft2", 20.0 * enerConv)
        ]
        for v in results1:
            var columnName: String = v.get[0, String]()
            var rowName: String = v.get[1, String]()
            var unitName: String = v.get[2, String]()
            var expectedValue: Real64 = v.get[3, Real64]()
            var query: String = "SELECT Value From TabularDataWithStrings WHERE ReportName = '" + reportName + "' AND TableName = '" + tableName + "' AND RowName = '" + rowName + "' AND ColumnName = '" + columnName + "' AND Units = '" + unitName + "'"
            var return_val: Real64 = execAndReturnFirstDouble(query)
            expect_near(expectedValue, return_val, 0.01) or "Failed for TableName=" + tableName + "; RowName=" + rowName

struct EconomicTariff_LEEDtariff_with_Custom_Meter(EnergyPlusFixture):
    def run(self) raises:
        var idf_objects: String = delimited_string([
            "Meter:Custom,",
            "    Building Natural Gas,    !- Name",
            "    NaturalGas,              !- Resource Type",
            "    ,                        !- Key Name 1",
            "    NaturalGas:Facility;     !- Output Variable or Meter Name 1",
            "UtilityCost:Tariff,",
            "    Sample with All Utilities_NGas,  !- Name",
            "    Building Natural Gas,    !- Output Meter Name",
            "    Therm,                   !- Conversion Factor Choice",
            "    ,                        !- Energy Conversion Factor",
            "    ,                        !- Demand Conversion Factor",
            "    ,                        !- Time of Use Period Schedule Name",
            "    ,                        !- Season Schedule Name",
            "    ,                        !- Month Schedule Name",
            "    ,                        !- Demand Window Length",
            "    ,                        !- Monthly Charge or Variable Name",
            "    ,                        !- Minimum Monthly Charge or Variable Name",
            "    ,                        !- Real Time Pricing Charge Schedule Name",
            "    ,                        !- Customer Baseline Load Schedule Name",
            "    ,                        !- Group Name",
            "    BuyFromUtility;          !- Buy Or Sell",
            "UtilityCost:Charge:Simple,",
            "    FlatEnergyCharge-Gas_Custom,  !- Utility Cost Charge Simple Name",
            "    Sample with All Utilities_NGas,  !- Tariff Name",
            "    totalEnergy,             !- Source Variable",
            "    Annual,                  !- Season",
            "    EnergyCharges,           !- Category Variable Name",
            "    0.50;                    !- Cost per Unit Value or Variable Name",
            "UtilityCost:Tariff,                                                 ",
            "    ExampleA,                !- Name                                ",
            "    ElectricityPurchased:Facility,  !- Output Meter Name            ",
            "    kWh,                     !- Conversion Factor Choice            ",
            "    ,                        !- Energy Conversion Factor            ",
            "    ,                        !- Demand Conversion Factor            ",
            "    ,                        !- Time of Use Period Schedule Name    ",
            "    ,                        !- Season Schedule Name                ",
            "    ,                        !- Month Schedule Name                 ",
            "    ,                        !- Demand Window Length                ",
            "    2.51;                    !- Monthly Charge or Variable Name     ",
            "UtilityCost:Charge:Simple,                                          ",
            "    FlatEnergyCharge,        !- Utility Cost Charge Simple Name     ",
            "    ExampleA,                !- Tariff Name                         ",
            "    totalEnergy,             !- Source Variable                     ",
            "    Annual,                  !- Season                              ",
            "    EnergyCharges,           !- Category Variable Name              ",
            "    0.055342;                !- Cost per Unit Value or Variable Name",
            "UtilityCost:Tariff,                                                      ",
            "    ExampleI-Sell,           !- Name                                    