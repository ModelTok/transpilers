from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataGlobalConstants import *
from EnergyPlus.EconomicLifeCycleCost import *
from EnergyPlus.EconomicTariff import *
from EnergyPlus.InputProcessing.InputProcessor import *
from Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf
from json import JSON as json
from testing import expect_eq, expect_ne, expect_approx_eq, assert_true
from util import MonthNamesUC, makeUPPER, getEnumValue

def EconomicLifeCycleCost_GetInput():
    var idf_objects: String = delimited_string([
        "  LifeCycleCost:Parameters,                                           ",
        "    TypicalLCC,              !- Name                                  ",
        "    EndOfYear,               !- Discounting Convention                ",
        "    ConstantDollar,          !- Inflation Approach                    ",
        "    0.03,                    !- Real Discount Rate                    ",
        "    ,                        !- Nominal Discount Rate                 ",
        "    ,                        !- Inflation                             ",
        "    January,                 !- Base Date Month                       ",
        "    2012,                    !- Base Date Year                        ",
        "    January,                 !- Service Date Month                    ",
        "    2014,                    !- Service Date Year                     ",
        "    22,                      !- Length of Study Period in Years       ",
        "    0,                       !- Tax rate                              ",
        "    ;                        !- Depreciation Method                   ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    Phase One Investment,    !- Name                                  ",
        "    Construction,            !- Category                              ",
        "    51500,                   !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    0,                       !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    Phase Two Investment,    !- Name                                  ",
        "    Construction,            !- Category                              ",
        "    51500,                   !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    1,                       !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    FanReplacement,          !- Name                                  ",
        "    OtherCapital,            !- Category                              ",
        "    12000,                   !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    13,                      !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    PlantReplacement,        !- Name                                  ",
        "    OtherCapital,            !- Category                              ",
        "    60000,                   !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    16,                      !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    ResidualValue,           !- Name                                  ",
        "    Salvage,                 !- Category                              ",
        "    -20000,                  !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    21,                      !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:RecurringCosts,                                       ",
        "    AnnualMaint,             !- Name                                  ",
        "    Maintenance,             !- Category                              ",
        "    7000,                    !- Cost                                  ",
        "    ServicePeriod,           !- Start of Costs                        ",
        "    0,                       !- Years from Start                      ",
        "    0,                       !- Months from Start                     ",
        "    1,                       !- Repeat Period Years                   ",
        "    0,                       !- Repeat Period Months                  ",
        "    0;                       !- Annual escalation rate                ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Electricity,  !- Name                         ",
        "    ElectricityPurchased,    !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    1.0072,                  !- Year 1 Escalation                     ",
        "    1.0148,                  !- Year 2 Escalation                     ",
        "    1.0315,                  !- Year 3 Escalation                     ",
        "    1.0493,                  !- Year 4 Escalation                     ",
        "    1.0505,                  !- Year 5 Escalation                     ",
        "    1.0451,                  !- Year 6 Escalation                     ",
        "    1.0429,                  !- Year 7 Escalation                     ",
        "    1.0410,                  !- Year 8 Escalation                     ",
        "    1.0406,                  !- Year 9 Escalation                     ",
        "    1.0444,                  !- Year 10 Escalation                    ",
        "    1.0505,                  !- Year 11 Escalation                    ",
        "    1.0535,                  !- Year 12 Escalation                    ",
        "    1.0524,                  !- Year 13 Escalation                    ",
        "    1.0478,                  !- Year 14 Escalation                    ",
        "    1.0429,                  !- Year 15 Escalation                    ",
        "    1.0391,                  !- Year 16 Escalation                    ",
        "    1.0372,                  !- Year 17 Escalation                    ",
        "    1.0360,                  !- Year 18 Escalation                    ",
        "    1.0341,                  !- Year 19 Escalation                    ",
        "    1.0319,                  !- Year 20 Escalation                    ",
        "    1.0288,                  !- Year 21 Escalation                    ",
        "    1.0341,                  !- Year 22 Escalation                    ",
        "    1.0425,                  !- Year 23 Escalation                    ",
        "    1.0508,                  !- Year 24 Escalation                    ",
        "    1.0569,                  !- Year 25 Escalation                    ",
        "    1.0626,                  !- Year 26 Escalation                    ",
        "    1.0694,                  !- Year 27 Escalation                    ",
        "    1.0721,                  !- Year 28 Escalation                    ",
        "    1.0744,                  !- Year 29 Escalation                    ",
        "    1.0774;                  !- Year 30 Escalation                    ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Electricity,  !- Name                         ",
        "    ElectricitySurplusSold,  !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    1.0072,                  !- Year 1 Escalation                     ",
        "    1.0148,                  !- Year 2 Escalation                     ",
        "    1.0315,                  !- Year 3 Escalation                     ",
        "    1.0493,                  !- Year 4 Escalation                     ",
        "    1.0505,                  !- Year 5 Escalation                     ",
        "    1.0451,                  !- Year 6 Escalation                     ",
        "    1.0429,                  !- Year 7 Escalation                     ",
        "    1.0410,                  !- Year 8 Escalation                     ",
        "    1.0406,                  !- Year 9 Escalation                     ",
        "    1.0444,                  !- Year 10 Escalation                    ",
        "    1.0505,                  !- Year 11 Escalation                    ",
        "    1.0535,                  !- Year 12 Escalation                    ",
        "    1.0524,                  !- Year 13 Escalation                    ",
        "    1.0478,                  !- Year 14 Escalation                    ",
        "    1.0429,                  !- Year 15 Escalation                    ",
        "    1.0391,                  !- Year 16 Escalation                    ",
        "    1.0372,                  !- Year 17 Escalation                    ",
        "    1.0360,                  !- Year 18 Escalation                    ",
        "    1.0341,                  !- Year 19 Escalation                    ",
        "    1.0319,                  !- Year 20 Escalation                    ",
        "    1.0288,                  !- Year 21 Escalation                    ",
        "    1.0341,                  !- Year 22 Escalation                    ",
        "    1.0425,                  !- Year 23 Escalation                    ",
        "    1.0508,                  !- Year 24 Escalation                    ",
        "    1.0569,                  !- Year 25 Escalation                    ",
        "    1.0626,                  !- Year 26 Escalation                    ",
        "    1.0694,                  !- Year 27 Escalation                    ",
        "    1.0721,                  !- Year 28 Escalation                    ",
        "    1.0744,                  !- Year 29 Escalation                    ",
        "    1.0774;                  !- Year 30 Escalation                    ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Natural gas,  !- Name                         ",
        "    NaturalGas,              !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    0.9950,                  !- Year 1 Escalation                     ",
        "    0.9711,                  !- Year 2 Escalation                     ",
        "    0.9774,                  !- Year 3 Escalation                     ",
        "    0.9849,                  !- Year 4 Escalation                     ",
        "    0.9899,                  !- Year 5 Escalation                     ",
        "    1.0000,                  !- Year 6 Escalation                     ",
        "    1.0113,                  !- Year 7 Escalation                     ",
        "    1.0289,                  !- Year 8 Escalation                     ",
        "    1.0616,                  !- Year 9 Escalation                     ",
        "    1.1031,                  !- Year 10 Escalation                    ",
        "    1.1321,                  !- Year 11 Escalation                    ",
        "    1.1484,                  !- Year 12 Escalation                    ",
        "    1.1623,                  !- Year 13 Escalation                    ",
        "    1.1786,                  !- Year 14 Escalation                    ",
        "    1.1925,                  !- Year 15 Escalation                    ",
        "    1.2025,                  !- Year 16 Escalation                    ",
        "    1.2138,                  !- Year 17 Escalation                    ",
        "    1.2289,                  !- Year 18 Escalation                    ",
        "    1.2453,                  !- Year 19 Escalation                    ",
        "    1.2642,                  !- Year 20 Escalation                    ",
        "    1.2818,                  !- Year 21 Escalation                    ",
        "    1.3182,                  !- Year 22 Escalation                    ",
        "    1.3560,                  !- Year 23 Escalation                    ",
        "    1.3899,                  !- Year 24 Escalation                    ",
        "    1.4151,                  !- Year 25 Escalation                    ",
        "    1.4491,                  !- Year 26 Escalation                    ",
        "    1.4881,                  !- Year 27 Escalation                    ",
        "    1.4818,                  !- Year 28 Escalation                    ",
        "    1.4931,                  !- Year 29 Escalation                    ",
        "    1.5145;                  !- Year 30 Escalation                    ",
        "                                                                      ",
        "  LifeCycleCost:UseAdjustment,                                        ",
        "    NoElectricUseAdjustment, !- Name                                  ",
        "    ElectricityPurchased,    !- Resource                              ",
        "    1.0;                     !- Year 1 Multiplier                     ",
    ])
    assert_true(process_idf(idf_objects))
    GetInputForLifeCycleCost(*state)
    expect_eq(state.dataEconLifeCycleCost.discountConvention, DiscConv.EndOfYear)
    expect_eq(state.dataEconLifeCycleCost.inflationApproach, InflAppr.ConstantDollar)
    expect_approx_eq(state.dataEconLifeCycleCost.realDiscountRate, 0.03)
    expect_eq(state.dataEconLifeCycleCost.baseDateMonth, 0)
    expect_eq(state.dataEconLifeCycleCost.baseDateYear, 2012)
    expect_eq(state.dataEconLifeCycleCost.lengthStudyTotalMonths, 22 * 12)
    expect_eq(state.dataEconLifeCycleCost.numNonrecurringCost, 5)
    expect_eq(state.dataEconLifeCycleCost.NonrecurringCost[3].name, "RESIDUALVALUE")  # 0-based index 4 -> 3
    expect_eq(state.dataEconLifeCycleCost.NonrecurringCost[3].category, CostCategory.Salvage)
    expect_eq(state.dataEconLifeCycleCost.NonrecurringCost[3].startOfCosts, StartCosts.BasePeriod)
    expect_approx_eq(state.dataEconLifeCycleCost.NonrecurringCost[3].cost, -20000.0)
    expect_eq(state.dataEconLifeCycleCost.numRecurringCosts, 1)
    expect_eq(state.dataEconLifeCycleCost.RecurringCosts[0].name, "ANNUALMAINT")
    expect_eq(state.dataEconLifeCycleCost.RecurringCosts[0].category, CostCategory.Maintenance)
    expect_approx_eq(state.dataEconLifeCycleCost.RecurringCosts[0].cost, 7000.0)
    expect_eq(state.dataEconLifeCycleCost.RecurringCosts[0].startOfCosts, StartCosts.ServicePeriod)
    expect_eq(state.dataEconLifeCycleCost.RecurringCosts[0].repeatPeriodYears, 1)
    expect_eq(state.dataEconLifeCycleCost.numUsePriceEscalation, 3)
    # Note: C++ uses 1-based indexing for UsePriceEscalation(3) -> here index 2
    expect_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].name, "MIDWEST  COMMERCIAL-NATURAL GAS")
    expect_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].escalationStartYear, 2012)
    # Escalation array is 1-based in C++ (Escalation(11)) -> 0-based index 10
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[10], 1.1321)
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[20], 1.2818)  # Escalation(21) -> index 20
    expect_eq(state.dataEconLifeCycleCost.numUseAdjustment, 1)
    expect_eq(state.dataEconLifeCycleCost.UseAdjustment[0].name, "NOELECTRICUSEADJUSTMENT")
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[0], 1.0)

def EconomicLifeCycleCost_ProcessMaxInput():
    var idf_objects: String = delimited_string([
        "  LifeCycleCost:Parameters,                                           ",
        "    TypicalLCC,              !- Name                                  ",
        "    EndOfYear,               !- Discounting Convention                ",
        "    ConstantDollar,          !- Inflation Approach                    ",
        "    0.03,                    !- Real Discount Rate                    ",
        "    ,                        !- Nominal Discount Rate                 ",
        "    ,                        !- Inflation                             ",
        "    January,                 !- Base Date Month                       ",
        "    2012,                    !- Base Date Year                        ",
        "    January,                 !- Service Date Month                    ",
        "    2014,                    !- Service Date Year                     ",
        "    100,                     !- Length of Study Period in Years       ",
        "    0,                       !- Tax rate                              ",
        "    ;                        !- Depreciation Method                   ",
        "                                                                      ",
        "  LifeCycleCost:NonrecurringCost,                                     ",
        "    FanReplacement,          !- Name                                  ",
        "    OtherCapital,            !- Category                              ",
        "    12000,                   !- Cost                                  ",
        "    BasePeriod,              !- Start of Costs                        ",
        "    13,                      !- Years from Start                      ",
        "    0;                       !- Months from Start                     ",
        "                                                                      ",
        "  LifeCycleCost:RecurringCosts,                                       ",
        "    AnnualMaint,             !- Name                                  ",
        "    Maintenance,             !- Category                              ",
        "    7000,                    !- Cost                                  ",
        "    ServicePeriod,           !- Start of Costs                        ",
        "    0,                       !- Years from Start                      ",
        "    0,                       !- Months from Start                     ",
        "    1,                       !- Repeat Period Years                   ",
        "    0,                       !- Repeat Period Months                  ",
        "    0;                       !- Annual escalation rate                ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Electricity,  !- Name                         ",
        "    ElectricityPurchased,    !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 1-10 Escalation ",
        "    1.008, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 11-20 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 21-30 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 31-40 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 41-50 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 51-60 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 61-70 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 71-80 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 81-90 Escalation ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.099, 1.100; !- Year 91-100 Escalation ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Electricity,  !- Name                         ",
        "    ElectricitySurplusSold,  !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 1-10 Escalation ",
        "    1.008, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 11-20 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 21-30 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 31-40 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 41-50 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 51-60 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 61-70 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 71-80 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 81-90 Escalation ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.099, 1.100; !- Year 91-100 Escalation ",
        "                                                                      ",
        "  LifeCycleCost:UsePriceEscalation,                                   ",
        "    MidWest  Commercial-Natural gas,  !- Name                         ",
        "    NaturalGas,              !- Resource                              ",
        "    2012,                    !- Escalation Start Year                 ",
        "    January,                 !- Escalation Start Month                ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 1-10 Escalation ",
        "    1.008, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 11-20 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 21-30 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 31-40 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 41-50 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 51-60 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 61-70 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 71-80 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 81-90 Escalation ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.099, 1.100; !- Year 91-100 Escalation ",
        "                                                                      ",
        "  LifeCycleCost:UseAdjustment,                                        ",
        "    NoElectricUseAdjustment, !- Name                                  ",
        "    ElectricityPurchased,    !- Resource                              ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 1-10 Escalation ",
        "    1.008, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 11-20 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 21-30 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 31-40 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 41-50 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 51-60 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 61-70 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 71-80 Escalation ",
        "    1.009, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.040, 1.044, !- Year 81-90 Escalation ",
        "    1.007, 1.014, 1.031, 1.049, 1.050, 1.045, 1.042, 1.041, 1.099, 1.100; !- Year 91-100 Escalation ",
    ])
    assert_true(process_idf(idf_objects))
    GetInputForLifeCycleCost(*state)
    expect_eq(state.dataEconLifeCycleCost.discountConvention, DiscConv.EndOfYear)
    expect_eq(state.dataEconLifeCycleCost.inflationApproach, InflAppr.ConstantDollar)
    expect_approx_eq(state.dataEconLifeCycleCost.realDiscountRate, 0.03)
    expect_eq(state.dataEconLifeCycleCost.baseDateMonth, 0)
    expect_eq(state.dataEconLifeCycleCost.baseDateYear, 2012)
    expect_eq(state.dataEconLifeCycleCost.lengthStudyTotalMonths, 100 * 12)
    expect_eq(state.dataEconLifeCycleCost.numUsePriceEscalation, 3)
    expect_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].name, "MIDWEST  COMMERCIAL-NATURAL GAS")
    expect_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].escalationStartYear, 2012)
    # 0-based indexing for Escalation array: Escalation(1) -> [0], Escalation(11)->[10], Escalation(21)->[20], Escalation(99)->[98], Escalation(100)->[99]
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[0], 1.007)
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[10], 1.008)
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[20], 1.009)
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[98], 1.099)
    expect_approx_eq(state.dataEconLifeCycleCost.UsePriceEscalation[2].Escalation[99], 1.100)
    expect_eq(state.dataEconLifeCycleCost.numUseAdjustment, 1)
    expect_eq(state.dataEconLifeCycleCost.UseAdjustment[0].name, "NOELECTRICUSEADJUSTMENT")
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[0], 1.007)
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[10], 1.008)
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[20], 1.009)
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[98], 1.099)
    expect_approx_eq(state.dataEconLifeCycleCost.UseAdjustment[0].Adjustment[99], 1.100)

def EconomicLifeCycleCost_ComputeEscalatedEnergyCosts():
    state.dataEconLifeCycleCost.lengthStudyYears = 5
    state.dataEconLifeCycleCost.numCashFlow = 1
    # resize CashFlow (assume we have a method)
    state.dataEconLifeCycleCost.CashFlow = List[CashFlowStruct]()
    for i in range(state.dataEconLifeCycleCost.numCashFlow):
        state.dataEconLifeCycleCost.CashFlow.append(CashFlowStruct())
    state.dataEconLifeCycleCost.CashFlow[0].pvKind = PrValKind.Energy
    state.dataEconLifeCycleCost.CashFlow[0].Resource = Constant.eResource.Electricity
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount = Array[Float64](state.dataEconLifeCycleCost.lengthStudyYears)
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount[0] = 100  # 1-based -> 0
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount[1] = 110
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount[2] = 120
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount[3] = 130
    state.dataEconLifeCycleCost.CashFlow[0].yrAmount[4] = 140
    state.dataEconLifeCycleCost.numResourcesUsed = 1
    # Initialize EscalatedEnergy map per year
    for year in range(1, state.dataEconLifeCycleCost.lengthStudyYears + 1):
        var yearMap: StaticArray[Float64, Constant.eResource.Num] = StaticArray[Float64, Constant.eResource.Num](0.0)
        # fill with zeros
        for r in range(Constant.eResource.Num):
            yearMap[r] = 0.0
        state.dataEconLifeCycleCost.EscalatedEnergy[year] = yearMap
    state.dataEconLifeCycleCost.EscalatedTotEnergy = Array[Float64](state.dataEconLifeCycleCost.lengthStudyYears)
    state.dataEconLifeCycleCost.EscalatedTotEnergy = 0.0
    ComputeEscalatedEnergyCosts(*state)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[1][Int(Constant.eResource.Electricity)], 100.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[2][Int(Constant.eResource.Electricity)], 110.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[3][Int(Constant.eResource.Electricity)], 120.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[4][Int(Constant.eResource.Electricity)], 130.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[5][Int(Constant.eResource.Electricity)], 140.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[0], 100.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[1], 110.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[2], 120.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[3], 130.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[4], 140.0, 0.001)
    state.dataEconLifeCycleCost.numUsePriceEscalation = 1
    state.dataEconLifeCycleCost.UsePriceEscalation = Array[UsePriceEscalationStruct](state.dataEconLifeCycleCost.numUsePriceEscalation)
    state.dataEconLifeCycleCost.UsePriceEscalation[0].resource = Constant.eResource.Electricity
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation = Array[Float64](state.dataEconLifeCycleCost.lengthStudyYears)
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation[0] = 1.03
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation[1] = 1.05
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation[2] = 1.07
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation[3] = 1.11
    state.dataEconLifeCycleCost.UsePriceEscalation[0].Escalation[4] = 1.15
    state.dataEconLifeCycleCost.EscalatedTotEnergy = 0.0
    ComputeEscalatedEnergyCosts(*state)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[1][Int(Constant.eResource.Electricity)], 103.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[2][Int(Constant.eResource.Electricity)], 115.5, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[3][Int(Constant.eResource.Electricity)], 128.4, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[4][Int(Constant.eResource.Electricity)], 144.3, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedEnergy[5][Int(Constant.eResource.Electricity)], 161.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[0], 103.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[1], 115.5, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[2], 128.4, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[3], 144.3, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.EscalatedTotEnergy[4], 161.0, 0.001)

def EconomicLifeCycleCost_GetMonthNumber():
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("January")), 0)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("February")), 1)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("March")), 2)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("April")), 3)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("May")), 4)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("June")), 5)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("July")), 6)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("August")), 7)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("September")), 8)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("October")), 9)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("November")), 10)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("December")), 11)
    expect_eq(getEnumValue(MonthNamesUC, makeUPPER("Hexember")), -1)

def EconomicLifeCycleCost_ExpressAsCashFlows():
    state.dataEconLifeCycleCost.baseDateYear = 2020
    state.dataEconLifeCycleCost.baseDateMonth = 0
    state.dataEconLifeCycleCost.serviceDateYear = 2023
    state.dataEconLifeCycleCost.serviceDateMonth = 0
    state.dataEconLifeCycleCost.lengthStudyYears = 5
    state.dataEconLifeCycleCost.lengthStudyTotalMonths = state.dataEconLifeCycleCost.lengthStudyYears * 12
    state.dataEconTariff.numTariff = 1
    state.dataEconTariff.tariff = Array[TariffStruct](1)
    state.dataEconTariff.tariff[0].isSelected = true
    state.dataEconTariff.tariff[0].resource = Constant.eResource.Electricity
    state.dataEconTariff.tariff[0].cats[Int(Cat.Total)] = 1
    state.dataEconTariff.econVar = Array[EconVarStruct](1)
    state.dataEconTariff.econVar[0].values = Array[Float64](12)
    state.dataEconTariff.econVar[0].values[0] = 101.0
    state.dataEconTariff.econVar[0].values[1] = 102.0
    state.dataEconTariff.econVar[0].values[2] = 103.0
    state.dataEconTariff.econVar[0].values[3] = 104.0
    state.dataEconTariff.econVar[0].values[4] = 105.0
    state.dataEconTariff.econVar[0].values[5] = 106.0
    state.dataEconTariff.econVar[0].values[6] = 107.0
    state.dataEconTariff.econVar[0].values[7] = 108.0
    state.dataEconTariff.econVar[0].values[8] = 109.0
    state.dataEconTariff.econVar[0].values[9] = 110.0
    state.dataEconTariff.econVar[0].values[10] = 111.0
    state.dataEconTariff.econVar[0].values[11] = 112.0
    state.dataEconLifeCycleCost.numNonrecurringCost = 1
    state.dataEconLifeCycleCost.NonrecurringCost = List[NonrecurringCostStruct]()
    state.dataEconLifeCycleCost.NonrecurringCost.append(NonrecurringCostStruct())
    state.dataEconLifeCycleCost.NonrecurringCost[0].name = "MiscConstruction"
    state.dataEconLifeCycleCost.NonrecurringCost[0].category = CostCategory.Construction
    state.dataEconLifeCycleCost.NonrecurringCost[0].cost = 123456.0
    state.dataEconLifeCycleCost.NonrecurringCost[0].startOfCosts = StartCosts.ServicePeriod
    state.dataEconLifeCycleCost.NonrecurringCost[0].totalMonthsFromStart = 10
    ExpressAsCashFlows(*state)
    # CashFlow indices are 0-based; C++ CashFlow[16] -> index 16 (0-based), CashFlow[17] -> 17
    # mnAmount(47) -> index 46 (0-based) etc. But need to know if mnAmount is 1-based. ObjexxFCL arrays often 1-based. Translate to 0.
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[16].mnAmount[46], 123456.0, 0.001)  # 36 + 10 + 1? wait compute: 36 months? Actually from C++ comment: 36 months plus 10 months plus one month = 47 months -> 0-based 46
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[36], 101.0, 0.001)  # 37 -> 36
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[37], 102.0, 0.001)  # 38 -> 37
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[38], 103.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[39], 104.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[40], 105.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[41], 106.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[42], 107.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[43], 108.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[44], 109.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[45], 110.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[46], 111.0, 0.001)  # 47 -> 46
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[47], 112.0, 0.001)  # 48 -> 47
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[48], 101.0, 0.001)  # 49 -> 48
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[49], 102.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[50], 103.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[51], 104.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[52], 105.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[53], 106.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[54], 107.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[55], 108.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[56], 109.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[57], 110.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[58], 111.0, 0.001)  # 59 -> 58
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].mnAmount[59], 112.0, 0.001)  # 60 -> 59
    # yrAmount(4) -> index 3, yrAmount(5) -> index 4
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].yrAmount[3], 1278.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[17].yrAmount[4], 1278.0, 0.001)
    # C++ uses CostCategory::Energy etc. as integer indices for CashFlow array? Actually they use them as indexes: CashFlow[CostCategory::Energy] - likely enum has integer values. In Mojo assume enum has underlying int.
    var idxEnergy = Int(CostCategory.Energy)
    var idxTotEnergy = Int(CostCategory.TotEnergy)
    var idxConstruction = Int(CostCategory.Construction)
    var idxTotCaptl = Int(CostCategory.TotCaptl)
    var idxTotGrand = Int(CostCategory.TotGrand)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxEnergy].yrAmount[3], 1278.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxEnergy].yrAmount[4], 1278.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxTotEnergy].yrAmount[3], 1278.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxTotEnergy].yrAmount[4], 1278.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxConstruction].yrAmount[3], 123456.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxTotCaptl].yrAmount[3], 123456.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxTotGrand].yrAmount[3], 1278.0 + 123456.0, 0.001)
    expect_approx_eq(state.dataEconLifeCycleCost.CashFlow[idxTotGrand].yrAmount[4], 1278.0, 0.001)

def EconomicLifeCycleCost_GetInput_EnsureFuelTypesAllRecognized():
    # using json = nlohmann::json
    var lcc_useprice_props: json = state.dataInputProcessing.inputProcessor.getObjectSchemaProps(*state, "LifeCycleCost:UsePriceEscalation")
    var resource_field: json = lcc_useprice_props["resource"]
    var enum_values: json = resource_field["enum"]
    const numResources: Int = Int(Constant.eFuel.Num) + 3
    expect_eq(numResources, enum_values.size())
    var idf_objects: String = delimited_string([
        "LifeCycleCost:Parameters,",
        "  TypicalLCC,              !- Name",
        "  EndOfYear,               !- Discounting Convention",
        "  ConstantDollar,          !- Inflation Approach",
        "  0.03,                    !- Real Discount Rate",
        "  ,                        !- Nominal Discount Rate",
        "  ,                        !- Inflation",
        "  January,                 !- Base Date Month",
        "  2012,                    !- Base Date Year",
        "  January,                 !- Service Date Month",
        "  2014,                    !- Service Date Year",
        "  100,                     !- Length of Study Period in Years",
        "  0,                       !- Tax rate",
        "  ;                        !- Depreciation Method",
    ])
    for enum_value in enum_values:
        var enum_string: String = makeUPPER(enum_value.get[String]())
        var resource: Constant.eResource = Constant.eResource(getEnumValue(Constant.eResourceNamesUC, enum_string))
        expect_ne(resource, Constant.eResource.Invalid)
        idf_objects += fmt.format(R"idf(
LifeCycleCost:UsePriceEscalation,
  LCCUsePriceEscalation {0},             !- Name
  {0},                                   !- Resource
  2009,                                   !- Escalation Start Year
  January,                                !- Escalation Start Month
  1,                                      !- Year Escalation 1
  1.01,                                   !- Year Escalation 2
  1.02;                                   !- Year Escalation 3
LifeCycleCost:UseAdjustment,
  LCCUseAdjustment {0},              !- Name
  {0},                               !- Resource
  1,                                      !- Year Multiplier 1
  1.005,                                  !- Year Multiplier 2
  1.01;                                   !- Year Multiplier 3
  )idf", enum_string)
    assert_true(process_idf(idf_objects))
    GetInputForLifeCycleCost(*state)
    expect_eq(numResources, state.dataEconLifeCycleCost.numUsePriceEscalation)
    for lcc in state.dataEconLifeCycleCost.UsePriceEscalation:
        expect_ne(lcc.resource, Constant.eResource.Invalid)
    expect_eq(numResources, state.dataEconLifeCycleCost.numUseAdjustment)
    for lcc in state.dataEconLifeCycleCost.UseAdjustment:
        expect_ne(lcc.resource, Constant.eResource.Invalid)