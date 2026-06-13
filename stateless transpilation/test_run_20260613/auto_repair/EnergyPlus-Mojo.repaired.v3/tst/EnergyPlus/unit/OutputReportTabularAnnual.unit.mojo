from testing import *
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture, process_idf, state
from .Fixtures.SQLiteFixture import SQLiteFixture
from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataHVACGlobals import *
from EnergyPlus.OutputProcessor import *
from EnergyPlus.OutputReportData import *
from EnergyPlus.OutputReportTabular import *
from EnergyPlus.OutputReportTabularAnnual import *
from EnergyPlus.UtilityRoutines import *

from Mojo import Constant as Constant

def delimited_string(parts: List[String]) -> String:
    var result = ""
    for part in parts:
        result += part + "\n"
    return result

@test
def OutputReportTabularAnnual_GetInput():
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Space Gains Annual Report, !- Name",
        "Filter1, !- Filter",
        "Constant-1.0, !- Schedule Name",
        "Zone People Total Heating Energy, !- Variable or Meter 1 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 1",
        "4, !- field Digits After Decimal 1",
        "Zone Lights Total Heating Energy, !- Variable or Meter 2 Name",
        "hoursNonZero, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Zone Electric Equipment Total Heating Energy; !- Variable or Meter 3 Name",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = True
    expect_false(state.dataOutRptTab.WriteTabularFiles)
    GetInputTabularAnnual(state)
    expect_true(state.dataOutRptTab.WriteTabularFiles)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    var tableParams = firstTable.inspectTable()
    expect_eq(tableParams[0], "SPACE GAINS ANNUAL REPORT") # m_name
    expect_eq(tableParams[1], "FILTER1")                   # m_filter
    expect_eq(tableParams[2], "Constant-1.0")              # m_scheduleName
    var fieldSetParams = firstTable.inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "ZONE PEOPLE TOTAL HEATING ENERGY")
    expect_eq(fieldSetParams[3], "4") # m_showDigits
    expect_eq(fieldSetParams[8], "0") # m_aggregate - 0 is sumOrAvg
    fieldSetParams = firstTable.inspectTableFieldSets(1)
    expect_eq(fieldSetParams[3], "2") # m_showDigits (2 is the default if no value provided)
    expect_eq(fieldSetParams[8], "3") # m_aggregate - 3 is hoursNonZero
    fieldSetParams = firstTable.inspectTableFieldSets(2)
    expect_eq(fieldSetParams[8], "0") # m_aggregate - 0 is sumOrAvg is default if not included in idf input object

@test
def OutputReportTabularAnnual_SetupGathering():
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Space Gains Annual Report, !- Name",
        ", !- Filter",
        ", !- Schedule Name",
        "Exterior Lights Electric Energy, !- Variable or Meter 1 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 1",
        "4, !- field Digits After Decimal 1",
        "Exterior Lights Electric Power, !- Variable or Meter 2 Name",
        "hoursNonZero, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Zone Electric Equipment Total Heating Energy; !- Variable or Meter 3 Name",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var extLitPow: Float64
    var extLitUse: Float64
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite1",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite2",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite3",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite1")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite2")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite3")
    state.dataGlobal.DoWeathSim = True
    GetInputTabularAnnual(state) # this also calls setupGathering
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    var fieldSetParams = firstTable.inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "EXTERIOR LIGHTS ELECTRIC ENERGY")
    expect_eq(fieldSetParams[2], "J") # m_varUnits
    expect_eq(fieldSetParams[4], "1") # m_typeOfVar
    expect_eq(fieldSetParams[5], "3") # m_keyCount
    expect_eq(fieldSetParams[6], "1") # m_varAvgSum
    expect_eq(fieldSetParams[7], "0") # m_varStepType

@test
def OutputReportTabularAnnual_GatherResults():
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Space Gains Annual Report, !- Name",
        ", !- Filter",
        ", !- Schedule Name",
        "Exterior Lights Electric Energy, !- Variable or Meter 1 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 1",
        "4, !- field Digits After Decimal 1",
        "Exterior Lights Electric Power, !- Variable or Meter 2 Name",
        "Maximum, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Zone Electric Equipment Total Heating Energy; !- Variable or Meter 3 Name",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var extLitPow: Float64
    var extLitUse: Float64
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite1",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite2",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Energy",
                        Constant.Units.J,
                        extLitUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite3",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.ExteriorLights,
                        "General")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite1")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite2")
    SetupOutputVariable(state,
                        "Exterior Lights Electric Power",
                        Constant.Units.W,
                        extLitPow,
                        TimeStepType.Zone,
                        StoreType.Average,
                        "Lite3")
    state.dataGlobal.DoWeathSim = True
    state.dataGlobal.TimeStepZone = 0.25
    GetInputTabularAnnual(state)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    extLitPow = 2.01
    extLitUse = 1.01
    GatherAnnualResultsForTimeStep(state, TimeStepType.Zone)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    var fieldSetParams = firstTable.inspectTableFieldSets(0)

@test
def OutputReportTabularAnnual_GatherResults_MinMaxHrsShown():
    using (OutputProcessor)
    state.dataGlobal.TimeStepZone = 1.0
    state.dataGlobal.TimeStepZoneSec = state.dataGlobal.TimeStepZone * Constant.rSecsInHour
    state.dataHVACGlobal.TimeStepSys = 1.0
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour
    var meter1 = Meter("HEATING:MYTH:VARIABLE")
    meter1.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter1)
    state.dataOutputProcessor.meterMap.insert_or_assign("HEATING:MYTH:VARIABLE", state.dataOutputProcessor.meters.size() - 1)
    var meter2 = Meter("ELECTRICITY:MYTH")
    meter2.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter2)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:MYTH", state.dataOutputProcessor.meters.size() - 1)
    var annualTables: List[AnnualTable]
    annualTables.append(AnnualTable(state, "PEAK ELECTRICITY ANNUAL MYTH REPORT", "", ""))
    annualTables[-1].addFieldSet("HEATING:MYTH:VARIABLE", AnnualFieldSet.AggregationKind.hoursPositive, 2)
    annualTables[-1].addFieldSet("ELECTRICITY:MYTH", AnnualFieldSet.AggregationKind.maximumDuringHoursShown, 2)
    annualTables[-1].setupGathering(state)
    meter1.CurTSValue = -10.0
    meter2.CurTSValue = 50.0
    annualTables[-1].gatherForTimestep(state, TimeStepType.Zone)
    var fieldSetParams = annualTables[-1].inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "HEATING:MYTH:VARIABLE") # m_colHead
    expect_eq(fieldSetParams[13], "0.000000")             # m_cell[0].result
    fieldSetParams = annualTables[-1].inspectTableFieldSets(1)
    expect_eq(fieldSetParams[0], "ELECTRICITY:MYTH") # m_colHead
    var limit = String(Float64.minValue)
    expect_eq(fieldSetParams[13].substr(0, 6), limit.substr(0, 6)) # m_cell[0].result
    meter1.CurTSValue = 15.0
    meter2.CurTSValue = 55.0
    annualTables[-1].gatherForTimestep(state, TimeStepType.Zone)
    fieldSetParams = annualTables[-1].inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "HEATING:MYTH:VARIABLE") # m_colHead
    expect_eq(fieldSetParams[13], "1.000000")             # m_cell[0].result
    fieldSetParams = annualTables[-1].inspectTableFieldSets(1)
    expect_eq(fieldSetParams[0], "ELECTRICITY:MYTH")                  # m_colHead
    expect_eq(fieldSetParams[13].substr(0, 6), "0.0152") # m_cell[0].result

@test
def OutputReportTabularAnnual_Maximum_SummedVariable_UsesZoneSeconds():
    using (OutputProcessor)
    state.dataGlobal.TimeStepZone = 0.25                                                       # hours
    state.dataGlobal.TimeStepZoneSec = state.dataGlobal.TimeStepZone * Constant.rSecsInHour # 900 s
    state.dataHVACGlobal.TimeStepSys = 1.0                                                           # hours
    state.dataHVACGlobal.TimeStepSysSec = state.dataHVACGlobal.TimeStepSys * Constant.rSecsInHour # 3600 s
    var meter = Meter("ELECTRICITY:MYTH")
    meter.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:MYTH", state.dataOutputProcessor.meters.size() - 1)
    var annualTables: List[AnnualTable]
    annualTables.append(AnnualTable(state, "TEST MAX RATE FROM SUM", "", ""))
    annualTables[-1].addFieldSet("ELECTRICITY:MYTH", AnnualFieldSet.AggregationKind.maximum, 6)
    annualTables[-1].setupGathering(state)
    meter.CurTSValue = 55.0
    annualTables[-1].gatherForTimestep(state, TimeStepType.Zone)
    var fieldSetParams = annualTables[-1].inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "ELECTRICITY:MYTH")                  # m_colHead
    expect_eq(fieldSetParams[13].substr(0, 6), "0.0611") # m_cell[0].result

@test
def OutputReportTabularAnnual_columnHeadersToTitleCase():
    using (OutputProcessor)
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Test Report, !- Name",
        ", !- Filter",
        ", !- Schedule Name",
        "OnPeakTime, !- Variable or Meter 1 Name",
        "HoursNonZero, !- Aggregation Type for Variable or Meter 1",
        "0, !- field Digits After Decimal 1",
        "Electricity:Facility, !- Variable or Meter 2 Name",
        "SumOrAverageDuringHoursShown, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Misc Facility Electric Energy, !- Variable or Meter 3 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 3",
        "0; !- field Digits After Decimal 3",
        "",
        "Schedule:Compact,",
        "    OnPeakTime,              !- Name",
        "    Fraction,                !- Schedule Type Limits Name",
        "    Through: 12/31,          !- Field 1",
        "    For: Weekdays SummerDesignDay,  !- Field 2",
        "    Until: 12:00, 0.0,       !- Field 4",
        "    Until: 20:00, 1.0,       !- Field 6",
        "    Until: 24:00, 0.0,       !- Field 8",
        "    For: AllOtherDays,       !- Field 9",
        "    Until: 24:00, 0.0;       !- Field 11",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var facilUse: Float64
    SetupOutputVariable(state,
                        "Misc Facility Electric Energy",
                        Constant.Units.J,
                        facilUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite1",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.InteriorLights, # Was "Facility"
                        "General")                # create an electric meter
    var meter1 = Meter("Electricity:Facility")
    meter1.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter1)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:FACILITY", state.dataOutputProcessor.meters.size() - 1)
    var meter2 = Meter("ELECTRICITY:LIGHTING")
    meter2.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter2)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:LIGHTING", state.dataOutputProcessor.meters.size() - 1)
    state.dataGlobal.DoWeathSim = True
    GetInputTabularAnnual(state)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    firstTable.columnHeadersToTitleCase(state)
    var fieldSetParams = firstTable.inspectTableFieldSets(0)
    expect_eq(fieldSetParams[0], "ONPEAKTIME") # m_colHead
    expect_eq(fieldSetParams[4], "3")          # m_typeOfVar = VarType_Schedule
    fieldSetParams = firstTable.inspectTableFieldSets(1)
    expect_eq(fieldSetParams[0], "Electricity:Facility") # m_colHead
    expect_eq(fieldSetParams[4], "2")                    # m_typeOfVar = VarType_Meter
    fieldSetParams = firstTable.inspectTableFieldSets(2)
    expect_eq(fieldSetParams[0], "Misc Facility Electric Energy") # m_colHead
    expect_eq(fieldSetParams[4], "1")                             # m_typeOfVar = VarType_Real

@test
def OutputReportTabularAnnual_invalidAggregationOrder():
    using (OutputProcessor)
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Test Report, !- Name",
        ", !- Filter",
        ", !- Schedule Name",
        "Electricity:Facility, !- Variable or Meter 2 Name",
        "SumOrAverageDuringHoursShown, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Misc Facility Electric Energy, !- Variable or Meter 3 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 3",
        "0; !- field Digits After Decimal 3",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var facilUse: Float64
    SetupOutputVariable(state,
                        "Misc Facility Electric Energy",
                        Constant.Units.J,
                        facilUse,
                        TimeStepType.Zone,
                        StoreType.Sum,
                        "Lite1",
                        Constant.eResource.Electricity,
                        Group.Invalid,
                        EndUseCat.InteriorLights, # Was "Facility"
                        "General")                # create an electric meter
    var meter1 = Meter("ELECTRICITY:FACILITY")
    meter1.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter1)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:FACILITY", state.dataOutputProcessor.meters.size() - 1)
    var meter2 = Meter("ELECTRICITY:LIGHTING")
    meter2.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter2)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:LIGHTING", state.dataOutputProcessor.meters.size() - 1)
    state.dataGlobal.DoWeathSim = True
    GetInputTabularAnnual(state)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    expect_true(firstTable.invalidAggregationOrder(state))

@test
def OutputReportTabularAnnual_CurlyBraces():
    using (OutputProcessor)
    state.dataSQLiteProcedures.sqlite.createSQLiteSimulationsRecord(1, "EnergyPlus Version", "Current Time")
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "  ANNUAL EXAMPLE,                         !- Name",
        "  ,                                       !- Filter",
        "  ,                                       !- Schedule Name",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 1",
        "  SumOrAverage,                           !- Aggregation Type for Variable or Meter 1",
        "  2,                                      !- Digits After Decimal 1",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 2",
        "  Maximum,                                !- Aggregation Type for Variable or Meter 2",
        "  2,                                      !- Digits After Decimal 2",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 3",
        "  Minimum,                                !- Aggregation Type for Variable or Meter 3",
        "  2,                                      !- Digits After Decimal 3",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 4",
        "  ValueWhenMaximumOrMinimum,              !- Aggregation Type for Variable or Meter 4",
        "  2,                                      !- Digits After Decimal 4",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 5",
        "  HoursNonZero,                           !- Aggregation Type for Variable or Meter 5",
        "  2,                                      !- Digits After Decimal 5",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 6",
        "  HoursZero,                              !- Aggregation Type for Variable or Meter 6",
        "  2,                                      !- Digits After Decimal 6",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 7",
        "  HoursPositive,                          !- Aggregation Type for Variable or Meter 7",
        "  2,                                      !- Digits After Decimal 7",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 8",
        "  HoursNonPositive,                       !- Aggregation Type for Variable or Meter 8",
        "  2,                                      !- Digits After Decimal 8",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 9",
        "  HoursNegative,                          !- Aggregation Type for Variable or Meter 9",
        "  2,                                      !- Digits After Decimal 9",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 10",
        "  HoursNonNegative,                       !- Aggregation Type for Variable or Meter 10",
        "  2,                                      !- Digits After Decimal 10",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 11",
        "  HourInTenBinsMinToMax,                  !- Aggregation Type for Variable or Meter 11",
        "  2,                                      !- Digits After Decimal 11",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 12",
        "  HourInTenBinsZeroToMax,                 !- Aggregation Type for Variable or Meter 12",
        "  2,                                      !- Digits After Decimal 12",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 13",
        "  HourInTenBinsMinToZero,                 !- Aggregation Type for Variable or Meter 13",
        "  2,                                      !- Digits After Decimal 13",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 14",
        "  SumOrAverageDuringHoursShown,           !- Aggregation Type for Variable or Meter 14",
        "  2,                                      !- Digits After Decimal 14",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 15",
        "  MaximumDuringHoursShown,                !- Aggregation Type for Variable or Meter 15",
        "  2,                                      !- Digits After Decimal 15",
        "  Electricity:Facility,                   !- Variable or Meter or EMS Variable or Field Name 16",
        "  MinimumDuringHoursShown,                !- Aggregation Type for Variable or Meter 16",
        "  2;                                      !- Digits After Decimal 16",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    var meter1 = Meter("ELECTRICITY:FACILITY")
    meter1.units = Constant.Units.None
    state.dataOutputProcessor.meters.append(meter1)
    state.dataOutputProcessor.meterMap.insert_or_assign("ELECTRICITY:FACILITY", state.dataOutputProcessor.meters.size() - 1)
    state.dataGlobal.DoWeathSim = True
    state.dataGlobal.TimeStepZone = 0.25
    state.dataGlobal.TimeStepZoneSec = state.dataGlobal.TimeStepZone * 60.0
    GetInputTabularAnnual(state)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    setTabularReportStyles(state)
    WriteAnnualTables(state)
    var columnHeaders = queryResult(
        "SELECT DISTINCT(ColumnName) FROM TabularDataWithStrings WHERE ReportName LIKE \"ANNUAL EXAMPLE%\"",
        "TabularDataWithStrings")
    expect_eq(36, columnHeaders.size())
    var missingBracesHeaders = queryResult(
        "SELECT DISTINCT(ColumnName) FROM TabularDataWithStrings WHERE ReportName LIKE \"ANNUAL EXAMPLE%\" AND ColumnName LIKE \"%{%\" AND ColumnName NOT LIKE \"%}%\"",
        "TabularDataWithStrings")
    for col in missingBracesHeaders:
        var colHeader: String = col[0]
        expect_true(false)  # "Missing braces in monthly table for : " + colHeader

@test
def OutputReportTabularAnnual_WarnBlankVariable():
    var idf_objects: String = delimited_string(List[String](
        "Output:Table:Annual,",
        "Space Gains Annual Report, !- Name",
        "Filter1, !- Filter",
        "Constant-1.0, !- Schedule Name",
        "Zone People Total Heating Energy, !- Variable or Meter 1 Name",
        "SumOrAverage, !- Aggregation Type for Variable or Meter 1",
        "4, !- field Digits After Decimal 1",
        ", !- Variable or Meter 2 Name",
        "hoursNonZero, !- Aggregation Type for Variable or Meter 2",
        ", !- field Digits After Decimal 2",
        "Zone Electric Equipment Total Heating Energy; !- Variable or Meter 3 Name",
    ))
    ASSERT_TRUE(process_idf(idf_objects))
    state.init_state(state)
    state.dataGlobal.DoWeathSim = True
    expect_false(state.dataOutRptTab.WriteTabularFiles)
    GetInputTabularAnnual(state)
    expect_true(state.dataOutRptTab.WriteTabularFiles)
    expect_eq(state.dataOutputReportTabularAnnual.annualTables.size(), 1u)
    var firstTable = state.dataOutputReportTabularAnnual.annualTables[0]
    var tableParams = firstTable.inspectTable()
    var expected_error: String = delimited_string(List[String](
        "   ** Warning ** Output:Table:Annual: Blank column specified in 'SPACE GAINS ANNUAL REPORT', need to provide a variable or meter or EMS variable name ",
        "   ** Warning ** Invalid aggregation type=\"\"  Defaulting to SumOrAverage."))
    compare_err_stream(expected_error)