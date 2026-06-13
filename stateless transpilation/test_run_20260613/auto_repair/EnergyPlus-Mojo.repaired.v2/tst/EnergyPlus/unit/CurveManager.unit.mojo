from testing import *
from ConfiguredFunctions import ConfiguredFunctions
from CurveManager import CurveManager
from Data.EnergyPlusData import EnergyPlusData
from DataGlobals import DataGlobals
from DataIPShortCuts import DataIPShortCuts
from FileSystem import FileSystem
from Formatters import Formatters
from embedded.EmbeddedEpJSONSchema import EmbeddedEpJSONSchema
from nlohmann.json import json
from format import format
from stdexcept import stdexcept
from .Fixtures.EnergyPlusFixture import EnergyPlusFixture
using EnergyPlus

let state = EnergyPlusData()

def compute_expected_error(lines: List[String]) -> String:
    var result = ""
    for s in lines:
        result += s + "\n"
    return result

def delimited_string(lines: List[String], delimiter: String = "\n") -> String:
    var result = ""
    for i in range(len(lines)):
        if i > 0:
            result += delimiter
        result += lines[i]
    return result

@test
def test_CurveExponentialSkewNormal_MaximumCurveOutputTest():
    var idf_objects = delimited_string([
        "Curve:ExponentialSkewNormal,",
        "  FanEff120CPLANormal,     !- Name",
        "  0.072613,                !- Coefficient1 C1",
        "  0.833213,                !- Coefficient2 C2",
        "  0.,                      !- Coefficient3 C3",
        "  0.013911,                !- Coefficient4 C4",
        "  -4.,                     !- Minimum Value of x",
        "  5.,                      !- Maximum Value of x",
        "  0.1,                     !- Minimum Curve Output",
        "  1.;                      !- Maximum Curve Output",
    ])
    var result = process_idf(idf_objects)
    assert_equal(result, True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, 1.0)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, 0.1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)

@test
def test_QuadraticCurve():
    var idf_objects = delimited_string([
        "Curve:QuadLinear,",
        "  MinDsnWBCurveName, ! Curve Name",
        "  -3.3333,           ! CoefficientC1",
        "  0.1,               ! CoefficientC2",
        "  38.9,              ! CoefficientC3",
        "  0.1,                ! CoefficientC4",
        "  0.5,                ! CoefficientC5",
        "  -30.,              ! Minimum Value of w",
        "  40.,               ! Maximum Value of w",
        "  0.,                ! Minimum Value of x",
        "  1.,                ! Maximum Value of x",
        "  5.,                ! Minimum Value of y",
        "  38.,               ! Maximum Value of y",
        "  0,                 ! Minimum Value of z",
        "  20,                ! Maximum Value of z",
        "  0.,                ! Minimum Curve Output",
        "  38.;               ! Maximum Curve Output",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, 38.0)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, 0.)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    var var1 = 1.0
    var var2 = 0.1
    var var3 = 20.0
    var var4 = 10.0
    var expected_value = -3.3333 + (0.1 * 1) + (38.9 * 0.1) + (0.1 * 20) + (0.5 * 10)
    assert_equal(expected_value, Curve.CurveValue(state, 1, var1, var2, var3, var4))

@test
def test_QuintLinearCurve():
    var idf_objects = delimited_string([
        "Curve:QuintLinear,",
        "  MinDsnWBCurveName, ! Curve Name",
        "  -3.3333,           ! CoefficientC1",
        "  0.1,               ! CoefficientC2",
        "  38.9,              ! CoefficientC3",
        "  0.1,                ! CoefficientC4",
        "  0.5,                ! CoefficientC5",
        "  1.5,                ! CoefficientC6",
        "  0.,                ! Minimum Value of v",
        "  10.,               ! Maximum Value of v",
        "  -30.,              ! Minimum Value of w",
        "  40.,               ! Maximum Value of w",
        "  0.,                ! Minimum Value of x",
        "  1.,                ! Maximum Value of x",
        "  5.,                ! Minimum Value of y",
        "  38.,               ! Maximum Value of y",
        "  0,                 ! Minimum Value of z",
        "  20,                ! Maximum Value of z",
        "  0.,                ! Minimum Curve Output",
        "  38.;               ! Maximum Curve Output",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, 38.0)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, 0.)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    var var1 = 1.0
    var var2 = 0.1
    var var3 = 0.5
    var var4 = 10.0
    var var5 = 15.0
    var expected_value = -3.3333 + (0.1 * 1) + (38.9 * 0.1) + (0.1 * 0.5) + (0.5 * 10) + (1.5 * 15)
    assert_equal(expected_value, Curve.CurveValue(state, 1, var1, var2, var3, var4, var5))

@test
def test_TableLookup():
    var idf_objects = delimited_string([
        "Table:IndependentVariable,",
        "  SAFlow,                    !- Name",
        "  Cubic,                     !- Interpolation Method",
        "  Constant,                  !- Extrapolation Method",
        "  0.714,                     !- Minimum Value",
        "  1.2857,                    !- Maximum Value",
        "  ,                          !- Normalization Reference Value",
        "  Dimensionless,             !- Unit Type",
        "  ,                          !- External File Name",
        "  ,                          !- External File Column Number",
        "  ,                          !- External File Starting Row Number",
        "  0.714286,                  !- Value 1",
        "  1.0,",
        "  1.2857;",
        "Table:IndependentVariableList,",
        "  SAFlow_Variables,          !- Name",
        "  SAFlow;                    !- Independent Variable 1 Name",
        "Table:Lookup,",
        "  CoolCapModFuncOfSAFlow,    !- Name",
        "  SAFlow_Variables,          !- Independent Variable List Name",
        "  ,                          !- Normalization Method",
        "  ,                          !- Normalization Divisor",
        "  0.8234,                    !- Minimum Output",
        "  1.1256,                    !- Maximum Output",
        "  Dimensionless,             !- Output Unit Type",
        "  ,                          !- External File Name",
        "  ,                          !- External File Column Number",
        "  ,                          !- External File Starting Row Number",
        "  0.823403,                  !- Output Value 1",
        "  1.0,",
        "  1.1256;",
        "Table:Lookup,",
        "  HeatCapModFuncOfSAFlow,    !- Name",
        "  SAFlow_Variables,          !- Independent Variable List Name",
        "  ,                          !- Normalization Method",
        "  ,                          !- Normalization Divisor",
        "  0.8554,                    !- Minimum Output",
        "  1.0778,                    !- Maximum Output",
        "  Dimensionless,             !- Output Unit Type",
        "  ,                          !- External File Name",
        "  ,                          !- External File Column Number",
        "  ,                          !- External File Starting Row Number",
        "  0.8554,                    !- Output Value 1",
        "  1.0,",
        "  1.0778;",
        "Table:IndependentVariable,",
        "  WaterFlow,                 !- Name",
        "  Cubic,                     !- Interpolation Method",
        "  Constant,                  !- Extrapolation Method",
        "  0.0,                       !- Minimum Value",
        "  1.333333,                  !- Maximum Value",
        "  ,                          !- Normalization Reference Value",
        "  Dimensionless,             !- Unit Type",
        "  ,                          !- External File Name",
        "  ,                          !- External File Column Number",
        "  ,                          !- External File Starting Row Number",
        "  0.0,                       !- Value 1,",
        "  0.05,",
        "  0.33333,",
        "  0.5,",
        "  0.666667,",
        "  0.833333,",
        "  1.0,",
        "  1.333333;",
        "Table:IndependentVariableList,",
        "  WaterFlow_Variables,       !- Name",
        "  WaterFlow;                 !- Independent Variable 1 Name",
        "Table:Lookup,",
        "  CapModFuncOfWaterFlow,     !- Name",
        "  WaterFlow_Variables,       !- Independent Variable List Name",
        "  ,                          !- Normalization Method",
        "  ,                          !- Normalization Divisor",
        "  0.0,                       !- Minimum Output",
        "  1.04,                      !- Maximum Output",
        "  Dimensionless,             !- Output Unit Type",
        "  ,                          !- External File Name",
        "  ,                          !- External File Column Number",
        "  ,                          !- External File Starting Row Number",
        "  0.0,                       !- Output Value 1",
        "  0.001,",
        "  0.71,",
        "  0.85,",
        "  0.92,",
        "  0.97,",
        "  1.0,",
        "  1.04;",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 3)
    assert_equal(state.dataCurveManager.curves[0].curveType, Curve.CurveType.BtwxtTableLookup)
    assert_equal(state.dataCurveManager.curves[0].Name, "CAPMODFUNCOFWATERFLOW")
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, 0.0)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, 1.04)

@test
def test_DivisorNormalizationNone():
    var expected_curve_min = 2.0
    var expected_curve_max = 21.0
    var table_data = [
        (2.0, 1.0),
        (2.0, 2.0),
        (2.0, 3.0),
        (7.0, 1.0),
        (7.0, 2.0),
        (7.0, 3.0),
        (3.0, 3.0),
        (5.0, 2.0),
    ]
    var idf_objects = delimited_string([
        "Table:Lookup,",
        "y_values,                              !- Name",
        "y_values_list,                         !- Independent Variable List Name",
        ",                                      !- Normalization Method",
        ",                                      !- Normalization Divisor",
        "2.0,                                   !- Minimum Output",
        "21.0,                                  !- Maximum Output",
        "Dimensionless,                         !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        "2.0,                                   !- Value 1",
        "4.0,                                   !- Value 2",
        "6.0,                                   !- Value 3",
        "7.0,                                   !- Value 4",
        "14.0,                                  !- Value 5",
        "21.0;                                  !- Value 6",
        "Table:IndependentVariableList,",
        "y_values_list,                         !- Name",
        "x_values_1,                            !- Independent Variable Name 1",
        "x_values_2;                            !- Independent Variable Name 2",
        "Table:IndependentVariable,",
        "x_values_1,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        ",                                      !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "2.0,                                   !- Value 1",
        "7.0;                                   !- Value 1",
        "Table:IndependentVariable,",
        "x_values_2,                            !- Name",
        "Linear,                                !- Interpolation Method",
        "Linear,                                !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        ",                                      !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "1.0,                                   !- Value 1",
        "2.0,                                   !- Value 2",
        "3.0;                                   !- Value 3",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, expected_curve_min)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, expected_curve_max)
    for data_point in table_data:
        assert_equal(data_point[0] * data_point[1], Curve.CurveValue(state, 1, data_point[0], data_point[1]))

@test
def test_DivisorNormalizationDivisorOnly():
    var expected_divisor = 3.0
    var expected_curve_min = 2.0 / expected_divisor
    var expected_curve_max = 21.0 / expected_divisor
    var table_data = [
        (2.0, 1.0),
        (2.0, 2.0),
        (2.0, 3.0),
        (7.0, 1.0),
        (7.0, 2.0),
        (7.0, 3.0),
        (3.0, 3.0),
        (5.0, 2.0),
    ]
    var idf_objects = delimited_string([
        "Table:Lookup,",
        "y_values,                              !- Name",
        "y_values_list,                         !- Independent Variable List Name",
        "DivisorOnly,                           !- Normalization Method",
        "3.0,                                   !- Normalization Divisor",
        "2.0,                                   !- Minimum Output",
        "21.0,                                  !- Maximum Output",
        "Dimensionless,                         !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        "2.0,                                   !- Value 1",
        "4.0,                                   !- Value 2",
        "6.0,                                   !- Value 3",
        "7.0,                                   !- Value 4",
        "14.0,                                  !- Value 5",
        "21.0;                                  !- Value 6",
        "Table:IndependentVariableList,",
        "y_values_list,                         !- Name",
        "x_values_1,                            !- Independent Variable Name 1",
        "x_values_2;                            !- Independent Variable Name 2",
        "Table:IndependentVariable,",
        "x_values_1,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        ",                                      !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "2.0,                                   !- Value 1",
        "7.0;                                   !- Value 1",
        "Table:IndependentVariable,",
        "x_values_2,                            !- Name",
        "Linear,                                !- Interpolation Method",
        "Linear,                                !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        ",                                      !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "1.0,                                   !- Value 1",
        "2.0,                                   !- Value 2",
        "3.0;                                   !- Value 3",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, expected_curve_min)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, expected_curve_max)
    for data_point in table_data:
        assert_equal(data_point[0] * data_point[1] / expected_divisor, Curve.CurveValue(state, 1, data_point[0], data_point[1]))

@test
def test_DivisorNormalizationDivisorOnlyButItIsZero():
    var idf_objects = delimited_string([
        "Table:Lookup,",
        "y_values,                              !- Name",
        "y_values_list,                         !- Independent Variable List Name",
        "DivisorOnly,                           !- Normalization Method",
        "0.0,                                   !- Normalization Divisor",
        "2.0,                                   !- Minimum Output",
        "21.0,                                  !- Maximum Output",
        "Dimensionless,                         !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        "2.0,                                   !- Value 1",
        "4.0;                                   !- Value 2",
        "Table:IndependentVariableList,",
        "y_values_list,                         !- Name",
        "x_values_1;                            !- Independent Variable Name 1",
        "Table:IndependentVariable,",
        "x_values_1,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        ",                                      !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "2.0,                                   !- Value 1",
        "3.0;                                   !- Value 3",
    ])
    assert_equal(process_idf(idf_objects), True)
    var caught = false
    try:
        Curve.GetCurveInput(state)
    except:
        caught = true
    assert_equal(caught, true)
    assert_equal(compare_err_stream_substring("Normalization divisor entered as zero"), true)

@test
def test_DivisorNormalizationAutomaticWithDivisor():
    var expected_auto_divisor = 6.0
    var expected_curve_max = 21.0 / expected_auto_divisor
    var expected_curve_min = 2.0 / expected_auto_divisor
    var table_data = [
        (2.0, 1.0),
        (2.0, 2.0),
        (2.0, 3.0),
        (7.0, 1.0),
        (7.0, 2.0),
        (7.0, 3.0),
        (3.0, 3.0),
        (5.0, 2.0),
    ]
    var idf_objects = delimited_string([
        "Table:Lookup,",
        "y_values,                              !- Name",
        "y_values_list,                         !- Independent Variable List Name",
        "AutomaticWithDivisor,                  !- Normalization Method",
        ",                                      !- Normalization Divisor",
        "2.0,                                   !- Minimum Output",
        "21.0,                                  !- Maximum Output",
        "Dimensionless,                         !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        "2.0,                                   !- Value 1",
        "4.0,                                   !- Value 2",
        "6.0,                                   !- Value 3",
        "7.0,                                   !- Value 4",
        "14.0,                                  !- Value 5",
        "21.0;                                  !- Value 6",
        "Table:IndependentVariableList,",
        "y_values_list,                         !- Name",
        "x_values_1,                            !- Independent Variable Name 1",
        "x_values_2;                            !- Independent Variable Name 2",
        "Table:IndependentVariable,",
        "x_values_1,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        "3.0,                                   !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "2.0,                                   !- Value 1",
        "7.0;                                   !- Value 1",
        "Table:IndependentVariable,",
        "x_values_2,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        "2.0,                                   !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "1.0,                                   !- Value 1",
        "2.0,                                   !- Value 2",
        "3.0;                                   !- Value 3",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, expected_curve_min)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, expected_curve_max)
    for data_point in table_data:
        assert_equal(data_point[0] * data_point[1] / expected_auto_divisor,
                     Curve.CurveValue(state, 1, data_point[0], data_point[1]))

@test
def test_NormalizationAutomaticWithDivisorAndSpecifiedDivisor():
    var expected_auto_divisor = 6.0
    var normalization_divisor = 4.0
    var expected_curve_max = 21.0 / expected_auto_divisor / normalization_divisor
    var expected_curve_min = 2.0 / expected_auto_divisor / normalization_divisor
    var table_data = [
        (2.0, 1.0),
        (2.0, 2.0),
        (2.0, 3.0),
        (7.0, 1.0),
        (7.0, 2.0),
        (7.0, 3.0),
        (3.0, 3.0),
        (5.0, 2.0),
    ]
    var idf_objects = delimited_string([
        "Table:Lookup,",
        "y_values,                              !- Name",
        "y_values_list,                         !- Independent Variable List Name",
        "AutomaticWithDivisor,                  !- Normalization Method",
        "4.0,                                   !- Normalization Divisor",
        "2.0,                                   !- Minimum Output",
        "21.0,                                  !- Maximum Output",
        "Dimensionless,                         !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        "2.0,                                   !- Value 1",
        "4.0,                                   !- Value 2",
        "6.0,                                   !- Value 3",
        "7.0,                                   !- Value 4",
        "14.0,                                  !- Value 5",
        "21.0;                                  !- Value 6",
        "Table:IndependentVariableList,",
        "y_values_list,                         !- Name",
        "x_values_1,                            !- Independent Variable Name 1",
        "x_values_2;                            !- Independent Variable Name 2",
        "Table:IndependentVariable,",
        "x_values_1,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        "3.0,                                   !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "2.0,                                   !- Value 1",
        "7.0;                                   !- Value 1",
        "Table:IndependentVariable,",
        "x_values_2,                            !- Name",
        ",                                      !- Interpolation Method",
        ",                                      !- Extrapolation Method",
        ",                                      !- Minimum value",
        ",                                      !- Maximum value",
        "2.0,                                   !- Normalization Reference Value",
        "Dimensionless                          !- Output Unit Type",
        ",                                      !- External File Name",
        ",                                      !- External File Column Number",
        ",                                      !- External File Starting Row Number",
        ",",
        "1.0,                                   !- Value 1",
        "2.0,                                   !- Value 2",
        "3.0;                                   !- Value 3",
    ])
    assert_equal(process_idf(idf_objects), True)
    state.init_state(state)
    assert_equal(len(state.dataCurveManager.curves), 1)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.minPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.min, expected_curve_min)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.maxPresent, True)
    assert_equal(state.dataCurveManager.curves[0].outputLimits.max, expected_curve_max)
    for data_point in table_data:
        assert_equal(data_point[0] * data_point[1] / expected_auto_divisor / normalization_divisor,
                     Curve.CurveValue(state, 1, data_point[0], data_point[1]))

@test
def test_CSV_CarriageReturns_Handling():
    var testTableFile = Curve.TableFile()
    var testCSV = configured_source_directory() + "/tst/EnergyPlus/unit/Resources/TestCarriageReturn.csv"
    testTableFile.filePath = testCSV
    testTableFile.load(state, testCSV)
    var TestArray: List[Float64]
    var col = 2
    var row = 1
    var expected_length = 168
    TestArray = testTableFile.getArray(state, (col, row))
    assert_equal(len(TestArray), expected_length)
    for i in TestArray:
        assert_false(math.isnan(i))

def getPatternProperties(schema_obj: json) -> json:
    var pattern_properties = schema_obj["patternProperties"]
    var dot_star_present = pattern_properties.count(".*")
    var pattern_property = ""
    if dot_star_present > 0:
        pattern_property = ".*"
    else:
        var no_whitespace_present = pattern_properties.count(r"^.*\S.*$")
        if no_whitespace_present > 0:
            pattern_property = r"^.*\S.*$"
        else:
            throw std.runtime_error(r"The patternProperties value is not a valid choice (\".*\", \"^.*\S.*$\")")
    var schema_obj_props = pattern_properties[pattern_property]["properties"]
    return schema_obj_props

def getPossibleChoicesFromSchema(objectType: String, fieldName: String) -> List[String]:
    static json_schema = json.from_cbor(EmbeddedEpJSONSchema.embeddedEpJSONSchema())
    var schema_properties = json_schema.at("properties")
    var object_schema = schema_properties.at(objectType)
    var schema_obj_props = getPatternProperties(object_schema)
    var schema_field_obj = schema_obj_props.at(fieldName)
    var choices = List[String]()
    for e in schema_field_obj.at("enum"):
        choices.append(e)
    return choices

@test
def test_TableIndependentVariableUnitType_IsValid():
    var unit_type_choices = getPossibleChoicesFromSchema("Table:IndependentVariable", "unit_type")
    for input_unit_type in unit_type_choices:
        assert_true(Curve.IsCurveInputTypeValid(input_unit_type)) + " " + input_unit_type + " is rejected by IsCurveInputTypeValid"
    assert_equal(len(unit_type_choices), 8)

@test
def test_TableLookupUnitType_IsValid():
    var unit_type_choices = getPossibleChoicesFromSchema("Table:Lookup", "output_unit_type")
    for output_unit_type in unit_type_choices:
        if output_unit_type.empty():
            continue
        assert_true(Curve.IsCurveOutputTypeValid(output_unit_type)) + " " + output_unit_type + " is rejected by IsCurveOutputTypeValid"
    assert_equal(len(unit_type_choices), 6)

# The following tests use parameterized tests - we'll create a helper to iterate over values
var InputUnitTypeIsValid_params = ["", "Angle", "Dimensionless", "Distance", "MassFlow", "Power", "Temperature", "VolumetricFlow"]
var OutputUnitTypeIsValid_params = ["", "Capacity", "Dimensionless", "Power", "Pressure", "Temperature"]

@test
def test_InputUnitTypeIsValid_IndepentVariable():
    for unit_type in InputUnitTypeIsValid_params:
        var idf_objects = delimited_string([
            "Table:IndependentVariable,",
            "  SAFlow,                    !- Name",
            "  Cubic,                     !- Interpolation Method",
            "  Constant,                  !- Extrapolation Method",
            "  0.714,                     !- Minimum Value",
            "  1.2857,                    !- Maximum Value",
            "  ,                          !- Normalization Reference Value",
            "  " + unit_type + ",             !-  Unit Type",
            "  ,                          !- External File Name",
            "  ,                          !- External File Column Number",
            "  ,                          !- External File Starting Row Number",
            "  0.714286,                  !- Value 1",
            "  1.0,",
            "  1.2857;",
            "Table:IndependentVariableList,",
            "  SAFlow_Variables,          !- Name",
            "  SAFlow;                    !- Independent Variable 1 Name",
            "Table:Lookup,",
            "  CoolCapModFuncOfSAFlow,    !- Name",
            "  SAFlow_Variables,          !- Independent Variable List Name",
            "  ,                          !- Normalization Method",
            "  ,                          !- Normalization Divisor",
            "  0.8234,                    !- Minimum Output",
            "  1.1256,                    !- Maximum Output",
            "  Dimensionless,             !- Output Unit Type",
            "  ,                          !- External File Name",
            "  ,                          !- External File Column Number",
            "  ,                          !- External File Starting Row Number",
            "  0.823403,                  !- Output Value 1",
            "  1.0,",
            "  1.1256;",
        ])
        assert_equal(process_idf(idf_objects), True)
        Curve.GetCurveInput(state)
        assert_true(compare_err_stream("", True))

@test
def test_OutputUnitTypeIsValid_TableLookup():
    for unit_type in OutputUnitTypeIsValid_params:
        var idf_objects = delimited_string([
            "Table:IndependentVariable,",
            "  SAFlow,                    !- Name",
            "  Cubic,                     !- Interpolation Method",
            "  Constant,                  !- Extrapolation Method",
            "  0.714,                     !- Minimum Value",
            "  1.2857,                    !- Maximum Value",
            "  ,                          !- Normalization Reference Value",
            "  Dimensionless,             !- Unit Type",
            "  ,                          !- External File Name",
            "  ,                          !- External File Column Number",
            "  ,                          !- External File Starting Row Number",
            "  0.714286,                  !- Value 1",
            "  1.0,",
            "  1.2857;",
            "Table:IndependentVariableList,",
            "  SAFlow_Variables,          !- Name",
            "  SAFlow;                    !- Independent Variable 1 Name",
            "Table:Lookup,",
            "  CoolCapModFuncOfSAFlow,    !- Name",
            "  SAFlow_Variables,          !- Independent Variable List Name",
            "  ,                          !- Normalization Method",
            "  ,                          !- Normalization Divisor",
            "  0.8234,                    !- Minimum Output",
            "  1.1256,                    !- Maximum Output",
            "  " + unit_type + ",             !- Output Unit Type",
            "  ,                          !- External File Name",
            "  ,                          !- External File Column Number",
            "  ,                          !- External File Starting Row Number",
            "  0.823403,                  !- Output Value 1",
            "  1.0,",
            "  1.1256;",
        ])
        assert_equal(process_idf(idf_objects), True)
        Curve.GetCurveInput(state)
        assert_true(compare_err_stream("", True))

def getAllPossibleInputOutputTypesForCurves() -> (Set[String], Set[String]):
    var json_schema = json.from_cbor(EmbeddedEpJSONSchema.embeddedEpJSONSchema())
    var schema_properties = json_schema.at("properties")
    var all_input_choices = Set[String]()
    var all_output_choices = Set[String]()
    for (objectType, object_schema) in schema_properties.items():
        var is_curve = (objectType.rfind("Curve:", 0) == 0) or (objectType == "Table:Lookup") or (objectType == "Table:IndependentVariable")
        if not is_curve:
            continue
        var schema_obj_props = getPatternProperties(object_schema)
        for (fieldName, schema_field_obj) in schema_obj_props.items():
            if String(fieldName) == "output_unit_type":
                for e in schema_field_obj.at("enum"):
                    all_output_choices.insert(String{e})
            elif fieldName.find("unit_type") != -1:
                for e in schema_field_obj.at("enum"):
                    all_input_choices.insert(String{e})
    return (all_input_choices, all_output_choices)

@test
def test_AllPossibleUnitTypeValid():
    var (all_input_choices, all_output_choices) = getAllPossibleInputOutputTypesForCurves()
    assert_false(all_input_choices.empty()) + " " + format("{}", all_input_choices)
    assert_false(all_output_choices.empty()) + " " + format("{}", all_output_choices)
    for input_unit_type in all_input_choices:
        assert_true(Curve.IsCurveInputTypeValid(input_unit_type)) + " " + input_unit_type + " is rejected by IsCurveOutputTypeValid"
    for output_unit_type in all_output_choices:
        if output_unit_type.empty():
            continue
        assert_true(Curve.IsCurveOutputTypeValid(output_unit_type)) + " " + output_unit_type + " is rejected by IsCurveOutputTypeValid"

@test
def test_QuadraticCurve_CheckCurveMinMaxValues():
    var idf_objects = delimited_string([
        "Curve:Quadratic,",
        "  DummyEIRfPLR,                       !- Name",
        "  1,                                  !- Coefficient1 Constant",
        "  1,                                  !- Coefficient2 x",
        "  0,                                  !- Coefficient3 x**2",
        "  0.8,                                !- Minimum Value of x {BasedOnField A2}",
        "  0.5,                                !- Maximum Value of x {BasedOnField A2}",
        "  ,                                   !- Minimum Curve Output {BasedOnField A3}",
        "  ,                                   !- Maximum Curve Output {BasedOnField A3}",
        "  ,                                   !- Input Unit Type for X",
        "  ;                                   !- Output Unit Type",
    ])
    assert_equal(process_idf(idf_objects), True)
    var caught = false
    try:
        Curve.GetCurveInput(state)
    except:
        caught = true
    assert_equal(caught, true)
    assert_equal(len(state.dataCurveManager.curves), 1)
    var expected_error = delimited_string([
        "   ** Severe  ** GetCurveInput: For Curve:Quadratic: ",
        "   **   ~~~   ** Minimum Value of x [0.80] > Maximum Value of x [0.50]",
        "   **  Fatal  ** GetCurveInput: Errors found in getting Curve Objects.  Preceding condition(s) cause termination.",
    ])
    assert_true(compare_err_stream_substring(expected_error))

# Parameterized test for curve min max validation - we'll use a helper struct and loop
struct CurveTestParam:
    var object_name: String
    var tested_dim: String
    var idf_objects: String
    var expected_error: String

var CurveManagerValidationFixture_params = [
    CurveTestParam{"Curve:Linear",
                   "x",
                   delimited_string([
                       "Curve:Linear,",
                       "  Linear,                                 !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Quadratic",
                   "x",
                   delimited_string([
                       "Curve:Quadratic,",
                       "  Quadratic,                              !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Cubic",
                   "x",
                   delimited_string([
                       "Curve:Cubic,",
                       "  Cubic,                                  !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 x**3",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Quartic",
                   "x",
                   delimited_string([
                       "Curve:Quartic,",
                       "  Quartic,                                !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 x**3",
                       "  1,                                      !- Coefficient5 x**4",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Exponent",
                   "x",
                   delimited_string([
                       "Curve:Exponent,",
                       "  Exponent,                               !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 Constant",
                       "  1,                                      !- Coefficient3 Constant",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:ExponentialSkewNormal",
                   "x",
                   delimited_string([
                       "Curve:ExponentialSkewNormal,",
                       "  ExponentialSkewNormal,                  !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Sigmoid",
                   "x",
                   delimited_string([
                       "Curve:Sigmoid,",
                       "  Sigmoid,                                !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  1,                                      !- Coefficient5 C5",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:RectangularHyperbola1",
                   "x",
                   delimited_string([
                       "Curve:RectangularHyperbola1,",
                       "  RectangularHyperbola1,                  !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:RectangularHyperbola2",
                   "x",
                   delimited_string([
                       "Curve:RectangularHyperbola2,",
                       "  RectangularHyperbola2,                  !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:ExponentialDecay",
                   "x",
                   delimited_string([
                       "Curve:ExponentialDecay,",
                       "  ExponentialDecay,                       !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:DoubleExponentialDecay",
                   "x",
                   delimited_string([
                       "Curve:DoubleExponentialDecay,",
                       "  DoubleExponentialDecay,                 !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  1,                                      !- Coefficient5 C5",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A3}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A3}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Bicubic",
                   "x",
                   delimited_string([
                       "Curve:Bicubic,",
                       "  Bicubic,                                !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 y**2",
                       "  1,                                      !- Coefficient6 x*y",
                       "  1,                                      !- Coefficient7 x**3",
                       "  1,                                      !- Coefficient8 y**3",
                       "  1,                                      !- Coefficient9 x**2*y",
                       "  1,                                      !- Coefficient10 x*y**2",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Bicubic",
                   "y",
                   delimited_string([
                       "Curve:Bicubic,",
                       "  Bicubic,                                !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 y**2",
                       "  1,                                      !- Coefficient6 x*y",
                       "  1,                                      !- Coefficient7 x**3",
                       "  1,                                      !- Coefficient8 y**3",
                       "  1,                                      !- Coefficient9 x**2*y",
                       "  1,                                      !- Coefficient10 x*y**2",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:Biquadratic",
                   "x",
                   delimited_string([
                       "Curve:Biquadratic,",
                       "  Biquadratic,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 y**2",
                       "  1,                                      !- Coefficient6 x*y",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Biquadratic",
                   "y",
                   delimited_string([
                       "Curve:Biquadratic,",
                       "  Biquadratic,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 y**2",
                       "  1,                                      !- Coefficient6 x*y",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:QuadraticLinear",
                   "x",
                   delimited_string([
                       "Curve:QuadraticLinear,",
                       "  QuadraticLinear,                        !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 x*y",
                       "  1,                                      !- Coefficient6 x**2*y",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:QuadraticLinear",
                   "y",
                   delimited_string([
                       "Curve:QuadraticLinear,",
                       "  QuadraticLinear,                        !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 x*y",
                       "  1,                                      !- Coefficient6 x**2*y",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:CubicLinear",
                   "x",
                   delimited_string([
                       "Curve:CubicLinear,",
                       "  CubicLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 x**3",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 x*y",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:CubicLinear",
                   "y",
                   delimited_string([
                       "Curve:CubicLinear,",
                       "  CubicLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x",
                       "  1,                                      !- Coefficient3 x**2",
                       "  1,                                      !- Coefficient4 x**3",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 x*y",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:FanPressureRise",
                   "Qfan",
                   delimited_string([
                       "Curve:FanPressureRise,",
                       "  FanPressureRise,                        !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  0.8,                                    !- Minimum Value of Qfan {m3/s}",
                       "  0.5,                                    !- Maximum Value of Qfan {m3/s}",
                       "  0,                                      !- Minimum Value of Psm {Pa}",
                       "  1,                                      !- Maximum Value of Psm {Pa}",
                       "  ,                                       !- Minimum Curve Output {Pa}",
                       "  ;                                       !- Maximum Curve Output {Pa}",
                   ]),
                   "Minimum Value of Qfan [0.80] > Maximum Value of Qfan [0.50]"},
    CurveTestParam{"Curve:FanPressureRise",
                   "Psm",
                   delimited_string([
                       "Curve:FanPressureRise,",
                       "  FanPressureRise,                        !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  0,                                      !- Minimum Value of Qfan {m3/s}",
                       "  1,                                      !- Maximum Value of Qfan {m3/s}",
                       "  0.8,                                    !- Minimum Value of Psm {Pa}",
                       "  0.5,                                    !- Maximum Value of Psm {Pa}",
                       "  ,                                       !- Minimum Curve Output {Pa}",
                       "  ;                                       !- Maximum Curve Output {Pa}",
                   ]),
                   "Minimum Value of Psm [0.80] > Maximum Value of Psm [0.50]"},
    CurveTestParam{"Curve:Triquadratic",
                   "x",
                   delimited_string([
                       "Curve:Triquadratic,",
                       "  Triquadratic,                           !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x**2",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y**2",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z**2",
                       "  1,                                      !- Coefficient7 z",
                       "  1,                                      !- Coefficient8 x**2*y**2",
                       "  1,                                      !- Coefficient9 x*y",
                       "  1,                                      !- Coefficient10 x*y**2",
                       "  1,                                      !- Coefficient11 x**2*y",
                       "  1,                                      !- Coefficient12 x**2*z**2",
                       "  1,                                      !- Coefficient13 x*z",
                       "  1,                                      !- Coefficient14 x*z**2",
                       "  1,                                      !- Coefficient15 x**2*z",
                       "  1,                                      !- Coefficient16 y**2*z**2",
                       "  1,                                      !- Coefficient17 y*z",
                       "  1,                                      !- Coefficient18 y*z**2",
                       "  1,                                      !- Coefficient19 y**2*z",
                       "  1,                                      !- Coefficient20 x**2*y**2*z**2",
                       "  1,                                      !- Coefficient21 x**2*y**2*z",
                       "  1,                                      !- Coefficient22 x**2*y*z**2",
                       "  1,                                      !- Coefficient23 x*y**2*z**2",
                       "  1,                                      !- Coefficient24 x**2*y*z",
                       "  1,                                      !- Coefficient25 x*y**2*z",
                       "  1,                                      !- Coefficient26 x*y*z**2",
                       "  1,                                      !- Coefficient27 x*y*z",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless,                          !- Input Unit Type for Z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:Triquadratic",
                   "y",
                   delimited_string([
                       "Curve:Triquadratic,",
                       "  Triquadratic,                           !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x**2",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y**2",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z**2",
                       "  1,                                      !- Coefficient7 z",
                       "  1,                                      !- Coefficient8 x**2*y**2",
                       "  1,                                      !- Coefficient9 x*y",
                       "  1,                                      !- Coefficient10 x*y**2",
                       "  1,                                      !- Coefficient11 x**2*y",
                       "  1,                                      !- Coefficient12 x**2*z**2",
                       "  1,                                      !- Coefficient13 x*z",
                       "  1,                                      !- Coefficient14 x*z**2",
                       "  1,                                      !- Coefficient15 x**2*z",
                       "  1,                                      !- Coefficient16 y**2*z**2",
                       "  1,                                      !- Coefficient17 y*z",
                       "  1,                                      !- Coefficient18 y*z**2",
                       "  1,                                      !- Coefficient19 y**2*z",
                       "  1,                                      !- Coefficient20 x**2*y**2*z**2",
                       "  1,                                      !- Coefficient21 x**2*y**2*z",
                       "  1,                                      !- Coefficient22 x**2*y*z**2",
                       "  1,                                      !- Coefficient23 x*y**2*z**2",
                       "  1,                                      !- Coefficient24 x**2*y*z",
                       "  1,                                      !- Coefficient25 x*y**2*z",
                       "  1,                                      !- Coefficient26 x*y*z**2",
                       "  1,                                      !- Coefficient27 x*y*z",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless,                          !- Input Unit Type for Z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:Triquadratic",
                   "z",
                   delimited_string([
                       "Curve:Triquadratic,",
                       "  Triquadratic,                           !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 x**2",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y**2",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z**2",
                       "  1,                                      !- Coefficient7 z",
                       "  1,                                      !- Coefficient8 x**2*y**2",
                       "  1,                                      !- Coefficient9 x*y",
                       "  1,                                      !- Coefficient10 x*y**2",
                       "  1,                                      !- Coefficient11 x**2*y",
                       "  1,                                      !- Coefficient12 x**2*z**2",
                       "  1,                                      !- Coefficient13 x*z",
                       "  1,                                      !- Coefficient14 x*z**2",
                       "  1,                                      !- Coefficient15 x**2*z",
                       "  1,                                      !- Coefficient16 y**2*z**2",
                       "  1,                                      !- Coefficient17 y*z",
                       "  1,                                      !- Coefficient18 y*z**2",
                       "  1,                                      !- Coefficient19 y**2*z",
                       "  1,                                      !- Coefficient20 x**2*y**2*z**2",
                       "  1,                                      !- Coefficient21 x**2*y**2*z",
                       "  1,                                      !- Coefficient22 x**2*y*z**2",
                       "  1,                                      !- Coefficient23 x*y**2*z**2",
                       "  1,                                      !- Coefficient24 x**2*y*z",
                       "  1,                                      !- Coefficient25 x*y**2*z",
                       "  1,                                      !- Coefficient26 x*y*z**2",
                       "  1,                                      !- Coefficient27 x*y*z",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  0.8,                                    !- Minimum Value of z {BasedOnField A4}",
                       "  0.5,                                    !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for X",
                       "  Dimensionless,                          !- Input Unit Type for Y",
                       "  Dimensionless,                          !- Input Unit Type for Z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of z [0.80] > Maximum Value of z [0.50]"},
    CurveTestParam{"Curve:ChillerPartLoadWithLift",
                   "x",
                   delimited_string([
                       "Curve:ChillerPartLoadWithLift,",
                       "  ChillerPartLoadWithLift,                !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  1,                                      !- Coefficient5 C5",
                       "  1,                                      !- Coefficient6 C6",
                       "  1,                                      !- Coefficient7 C7",
                       "  1,                                      !- Coefficient8 C8",
                       "  1,                                      !- Coefficient9 C9",
                       "  1,                                      !- Coefficient10 C10",
                       "  1,                                      !- Coefficient11 C11",
                       "  1,                                      !- Coefficient12 C12",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless,                          !- Input Unit Type for z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:ChillerPartLoadWithLift",
                   "y",
                   delimited_string([
                       "Curve:ChillerPartLoadWithLift,",
                       "  ChillerPartLoadWithLift,                !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  1,                                      !- Coefficient5 C5",
                       "  1,                                      !- Coefficient6 C6",
                       "  1,                                      !- Coefficient7 C7",
                       "  1,                                      !- Coefficient8 C8",
                       "  1,                                      !- Coefficient9 C9",
                       "  1,                                      !- Coefficient10 C10",
                       "  1,                                      !- Coefficient11 C11",
                       "  1,                                      !- Coefficient12 C12",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless,                          !- Input Unit Type for z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:ChillerPartLoadWithLift",
                   "z",
                   delimited_string([
                       "Curve:ChillerPartLoadWithLift,",
                       "  ChillerPartLoadWithLift,                !- Name",
                       "  1,                                      !- Coefficient1 C1",
                       "  1,                                      !- Coefficient2 C2",
                       "  1,                                      !- Coefficient3 C3",
                       "  1,                                      !- Coefficient4 C4",
                       "  1,                                      !- Coefficient5 C5",
                       "  1,                                      !- Coefficient6 C6",
                       "  1,                                      !- Coefficient7 C7",
                       "  1,                                      !- Coefficient8 C8",
                       "  1,                                      !- Coefficient9 C9",
                       "  1,                                      !- Coefficient10 C10",
                       "  1,                                      !- Coefficient11 C11",
                       "  1,                                      !- Coefficient12 C12",
                       "  0,                                      !- Minimum Value of x {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A3}",
                       "  0.8,                                    !- Minimum Value of z {BasedOnField A4}",
                       "  0.5,                                    !- Maximum Value of z {BasedOnField A4}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A5}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A5}",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless,                          !- Input Unit Type for z",
                       "  Dimensionless;                          !- Output Unit Type",
                   ]),
                   "Minimum Value of z [0.80] > Maximum Value of z [0.50]"},
    CurveTestParam{"Curve:QuadLinear",
                   "w",
                   delimited_string([
                       "Curve:QuadLinear,",
                       "  QuadLinear,                             !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 w",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 z",
                       "  0.8,                                    !- Minimum Value of w {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of w [0.80] > Maximum Value of w [0.50]"},
    CurveTestParam{"Curve:QuadLinear",
                   "x",
                   delimited_string([
                       "Curve:QuadLinear,",
                       "  QuadLinear,                             !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 w",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 z",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:QuadLinear",
                   "y",
                   delimited_string([
                       "Curve:QuadLinear,",
                       "  QuadLinear,                             !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 w",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 z",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A4}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:QuadLinear",
                   "z",
                   delimited_string([
                       "Curve:QuadLinear,",
                       "  QuadLinear,                             !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 w",
                       "  1,                                      !- Coefficient3 x",
                       "  1,                                      !- Coefficient4 y",
                       "  1,                                      !- Coefficient5 z",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0.8,                                    !- Minimum Value of z {BasedOnField A5}",
                       "  0.5,                                    !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of z [0.80] > Maximum Value of z [0.50]"},
    CurveTestParam{"Curve:QuintLinear",
                   "v",
                   delimited_string([
                       "Curve:QuintLinear,",
                       "  QuintLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 v",
                       "  1,                                      !- Coefficient3 w",
                       "  1,                                      !- Coefficient4 x",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z",
                       "  0.8,                                    !- Minimum Value of v {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of v {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for v",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of v [0.80] > Maximum Value of v [0.50]"},
    CurveTestParam{"Curve:QuintLinear",
                   "w",
                   delimited_string([
                       "Curve:QuintLinear,",
                       "  QuintLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 v",
                       "  1,                                      !- Coefficient3 w",
                       "  1,                                      !- Coefficient4 x",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z",
                       "  0,                                      !- Minimum Value of v {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of v {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of w {BasedOnField A2}",
                       "  0.5,                                    !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for v",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of w [0.80] > Maximum Value of w [0.50]"},
    CurveTestParam{"Curve:QuintLinear",
                   "x",
                   delimited_string([
                       "Curve:QuintLinear,",
                       "  QuintLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 v",
                       "  1,                                      !- Coefficient3 w",
                       "  1,                                      !- Coefficient4 x",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z",
                       "  0,                                      !- Minimum Value of v {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of v {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0.8,                                    !- Minimum Value of x {BasedOnField A3}",
                       "  0.5,                                    !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for v",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of x [0.80] > Maximum Value of x [0.50]"},
    CurveTestParam{"Curve:QuintLinear",
                   "y",
                   delimited_string([
                       "Curve:QuintLinear,",
                       "  QuintLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 v",
                       "  1,                                      !- Coefficient3 w",
                       "  1,                                      !- Coefficient4 x",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z",
                       "  0,                                      !- Minimum Value of v {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of v {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0.8,                                    !- Minimum Value of y {BasedOnField A4}",
                       "  0.5,                                    !- Maximum Value of y {BasedOnField A4}",
                       "  0,                                      !- Minimum Value of z {BasedOnField A5}",
                       "  1,                                      !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for v",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of y [0.80] > Maximum Value of y [0.50]"},
    CurveTestParam{"Curve:QuintLinear",
                   "z",
                   delimited_string([
                       "Curve:QuintLinear,",
                       "  QuintLinear,                            !- Name",
                       "  1,                                      !- Coefficient1 Constant",
                       "  1,                                      !- Coefficient2 v",
                       "  1,                                      !- Coefficient3 w",
                       "  1,                                      !- Coefficient4 x",
                       "  1,                                      !- Coefficient5 y",
                       "  1,                                      !- Coefficient6 z",
                       "  0,                                      !- Minimum Value of v {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of v {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of w {BasedOnField A2}",
                       "  1,                                      !- Maximum Value of w {BasedOnField A2}",
                       "  0,                                      !- Minimum Value of x {BasedOnField A3}",
                       "  1,                                      !- Maximum Value of x {BasedOnField A3}",
                       "  0,                                      !- Minimum Value of y {BasedOnField A4}",
                       "  1,                                      !- Maximum Value of y {BasedOnField A4}",
                       "  0.8,                                    !- Minimum Value of z {BasedOnField A5}",
                       "  0.5,                                    !- Maximum Value of z {BasedOnField A5}",
                       "  ,                                       !- Minimum Curve Output {BasedOnField A4}",
                       "  ,                                       !- Maximum Curve Output {BasedOnField A4}",
                       "  Dimensionless,                          !- Input Unit Type for v",
                       "  Dimensionless,                          !- Input Unit Type for w",
                       "  Dimensionless,                          !- Input Unit Type for x",
                       "  Dimensionless,                          !- Input Unit Type for y",
                       "  Dimensionless;                          !- Input Unit Type for z",
                   ]),
                   "Minimum Value of z [0.80] > Maximum Value of z [0.50]"},
]

@test
def test_CurveMinMaxValues_parameterized():
    for param in CurveManagerValidationFixture_params:
        var idf_objects = param.idf_objects
        assert_equal(process_idf(idf_objects), True)
        assert_equal(len(state.dataCurveManager.curves), 0)
        var caught = false
        var error_msg = ""
        try:
            Curve.GetCurveInput(state)
        except EnergyPlus.FatalError as e:
            error_msg = e.what()
            caught = true
            assert_false(error_msg.find("Error with format") != -1) + " " + error_msg
        except stdexcept.runtime_error as e:
            fail(e.what())
        except:
            fail("Got another exception!")
        assert_equal(caught, true)
        assert_equal(len(state.dataCurveManager.curves), 1)
        assert_true(compare_err_stream_substring(param.expected_error))