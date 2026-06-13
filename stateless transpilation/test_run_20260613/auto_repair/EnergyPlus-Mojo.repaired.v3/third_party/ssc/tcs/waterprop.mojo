// Mojo translation of waterprop.cpp
// Faithful 1:1 translation, no refactoring.

from math import sqrt, pow, acos, fabs
from memory import DynamicVector

// Data arrays from waterprop_critical.dat and waterprop_saturated.dat
// These must be filled with the actual values from the original .dat files.
// Placeholder values (all zeros) are used here; replace with real data.

let water_max_sat_temp: Float64 = 0.0
let water_min_sat_temp: Float64 = 0.0
let water_max_sat_pres: Float64 = 0.0
let water_min_sat_pres: Float64 = 0.0
let water_min_temp: Float64 = 0.0
let water_max_temp: Float64 = 0.0

// Saturation temperature vector (size 127)
let water_sat_temp_vector: StaticArray[Float64, 127] = StaticArray[Float64, 127](0.0)

// Saturation pressure vector (size 127)
let water_sat_pres_vector: StaticArray[Float64, 127] = StaticArray[Float64, 127](0.0)

// Pressure vector (size 127)
let water_pres_vector: StaticArray[Float64, 127] = StaticArray[Float64, 127](0.0)

// Saturation pressure coefficient array (4 x 127)
let water_sat_pres_coef_array: StaticArray[Float64, 4*127] = StaticArray[Float64, 4*127](0.0)

// Saturation temperature coefficient array (4 x 127)
let water_sat_temp_coef_array: StaticArray[Float64, 4*127] = StaticArray[Float64, 4*127](0.0)

// Vapor entropy values (size unknown, assume 1000)
let water_vapor_entr_values: StaticArray[Float64, 1000] = StaticArray[Float64, 1000](0.0)

// Vapor entropy index vector (size unknown, assume 128)
let water_vapor_entr_index_vector: StaticArray[Int, 128] = StaticArray[Int, 128](0)

// Liquid entropy values (size unknown, assume 1000)
let water_liquid_entr_values: StaticArray[Float64, 1000] = StaticArray[Float64, 1000](0.0)

// Liquid entropy index vector (size unknown, assume 128)
let water_liquid_entr_index_vector: StaticArray[Int, 128] = StaticArray[Int, 128](0)

// Vapor coefficient array (4 x 4 x 8 x ?) - assume size 4*4*8*1000
let water_vapor_coef_array: StaticArray[Float64, 4*4*8*1000] = StaticArray[Float64, 4*4*8*1000](0.0)

// Liquid coefficient array (4 x 4 x 8 x ?) - assume size 4*4*8*1000
let water_liquid_coef_array: StaticArray[Float64, 4*4*8*1000] = StaticArray[Float64, 4*4*8*1000](0.0)

// Saturation property coefficient array (4 x 5 x 2 x 127)
let water_sat_prop_coef_array: StaticArray[Float64, 4*5*2*127] = StaticArray[Float64, 4*5*2*127](0.0)

// Saturation VHS coefficient array (3 x 2 x 4 x 127)
let water_sat_vhs_coef_array: StaticArray[Float64, 3*2*4*127] = StaticArray[Float64, 3*2*4*127](0.0)

struct _property_info:
    var T: Float64  # temperature ('C)
    var Q: Float64  # quality [0..1]
    var P: Float64  # pressure (kPa)
    var V: Float64  # specific volume (m3/kg)
    var U: Float64  # internal energy (kJ/kg)
    var H: Float64  # enthalpy (kJ/kg)
    var S: Float64  # entropy (kJ/kg-K)
    var dens: Float64  # density (kg/m3)
    var Cv: Float64  # specific heat at const. volume (kJ/kg-K), only available at a quality of 0 or 1
    var Cp: Float64  # specific heat at const. pressure (kJ/kg-K), only available at a quality of 0 or 1
    var cond: Float64  # thermal conductivity (W/m-K), only available at a quality of 0 or 1
    var visc: Float64  # viscosity (Pa-s or kg/ms-s), only available at a quality of 0 or 1
    var ssnd: Float64  # speed of sound in fluid (m/s), only available at a quality of 0 or 1

typealias property_info = _property_info

// Forward declarations of static functions
def VaporNonGap(pIndex: Int, pFraction: Float64, data: Pointer[property_info], edgeInd: Int, indVar: Float64) -> Int
def LiquidNonGap(pIndex: Int, pFraction: Float64, data: Pointer[property_info], edgeInd: Int, indVar: Float64)
def VaporGap(firstCoefIndex: Int, TSat: Float64, sFraction: Float64, data: Pointer[property_info])
def LiquidGap(lastCoefIndex: Int, TSat: Float64, sFraction: Float64, data: Pointer[property_info])
def cubic_solution(coef_1: Float64, coef_2: Float64, coef_3: Float64, coef_4: Float64, value: Float64) -> Float64
def t_sat(P: Float64) -> Float64
def sat_find(T: Float64, TSatIndex: Pointer[Int], dT: Pointer[Float64])
def pres_find(P: Float64, pSatIndex: Pointer[Int], pFraction: Pointer[Float64])
def vaporGrid(j: Int, k: Int, firstCoefIndex: Int, pFraction: Float64) -> Float64
def vaporGrid(k: Int, lastCoefIndex: Int, pFraction: Float64, sFraction: Float64 = 1.0) -> Float64
def liquidGrid(j: Int, k: Int, firstCoefIndex: Int, pFraction: Float64) -> Float64
def liquidGrid(k: Int, lastCoefIndex: Int, pFraction: Float64, sFraction: Float64 = 1.0) -> Float64
def propDome(j: Int, k: Int, TSatIndex: Int, dT: Float64) -> Float64
def VHSDome(i: Int, j: Int, TSatIndex: Int, dT: Float64) -> Float64
def maxloc(firstIndex: Int, lastIndex: Int, indexVector: Pointer[Float64], S: Float64) -> Int
def maxloc(valueVector: DynamicVector[Float64], S: Float64) -> Int

// Inline functions (translated as regular functions)
def vapor_gap_temp(sFraction: Float64, pFraction: Float64, TSat: Float64, firstCoefIndex: Int) -> Float64:
    var grid: Float64 = vaporGrid(0, 0, firstCoefIndex, pFraction)
    return TSat + (grid - TSat) * sFraction

def vapor_gap_dens(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = 1.0 / (VHSDome(0, 1, TSatIndex, dT))
    var grid: Float64 = vaporGrid(0, 1, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_enth(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = VHSDome(1, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 2, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_cv(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(0, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 3, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_cp(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(1, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 4, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_ssnd(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(2, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 5, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_cond(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(3, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 6, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_visc(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, firstCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(4, 1, TSatIndex, dT)
    var grid: Float64 = vaporGrid(0, 7, firstCoefIndex, pFraction)
    return dome + (grid - dome) * sFraction

def vapor_gap_entr(sFraction: Float64, dT: Float64, TSatIndex: Int, pIndex: Int) -> Float64:
    var dome: Float64 = VHSDome(2, 1, TSatIndex, dT)
    return dome + (water_vapor_entr_values[water_vapor_entr_index_vector[pIndex]] - dome) * sFraction

def liquid_gap_temp(sFraction: Float64, pFraction: Float64, TSat: Float64, lastCoefIndex: Int) -> Float64:
    var grid: Float64 = liquidGrid(0, lastCoefIndex, pFraction, 1.0)
    return grid + (TSat - grid) * sFraction

def liquid_gap_dens(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = 1.0 / (VHSDome(0, 0, TSatIndex, dT))
    var grid: Float64 = liquidGrid(1, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_enth(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = VHSDome(1, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(2, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_cv(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(0, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(3, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_cp(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(1, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(4, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_ssnd(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(2, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(5, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_cond(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(3, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(6, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_visc(sFraction: Float64, pFraction: Float64, dT: Float64, TSatIndex: Int, lastCoefIndex: Int) -> Float64:
    var dome: Float64 = propDome(4, 0, TSatIndex, dT)
    var grid: Float64 = liquidGrid(7, lastCoefIndex, pFraction, 1.0)
    return grid + (dome - grid) * sFraction

def liquid_gap_entr(sFraction: Float64, dT: Float64, TSatIndex: Int, pIndex: Int) -> Float64:
    var dome: Float64 = VHSDome(2, 0, TSatIndex, dT)
    var lastIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - 1
    return water_liquid_entr_values[lastIndex] + (dome - water_liquid_entr_values[lastIndex]) * sFraction

/* Purpose is to return an index to a 1D array for multidimensional inputs 
* Note: Assumes COLUMN based arrays !!!
* Notation:
* i,j,k,l = indices in the 1st, 2nd, 3rd, 4th dimension
* R = number of elements in first dimension (rows)
* C = number of elements in second dimension (columns)
* D = number of elements in third dimension (depth)
**************************************************************************/
def Index2D(i: Int, j: Int, R: Int) -> Int:
    return i + R * j

def Index4D(i: Int, j: Int, k: Int, l: Int, R: Int, C: Int, D: Int) -> Int:
    return R * C * D * l + (R * C * k + (i + R * j))

def water_TQ(T: Float64, Q: Float64, data: Pointer[property_info]) -> Int:
    /************************************************************
    *************************************************************/
    data[].T = T
    data[].Q = Q
    var error_code: Int = 0
    if Q > 1.0 or Q < 0.0:
        error_code = 1
        return error_code
    if T > water_max_sat_temp or T < water_min_sat_temp:
        error_code = 2
        return error_code
    var TSatIndex: Int
    var dT: Float64
    sat_find(T, &TSatIndex, &dT)
    var sat_vhs_values: StaticArray[StaticArray[Float64, 2], 3] = StaticArray[StaticArray[Float64, 2], 3](StaticArray[Float64, 2](0.0))
    for i in range(3):
        for j in range(2):
            sat_vhs_values[i][j] = VHSDome(i, j, TSatIndex, dT)
    var vhs_values: StaticArray[Float64, 3] = StaticArray[Float64, 3](0.0)
    for i in range(3):
        vhs_values[i] = Q * (sat_vhs_values[i][1] - sat_vhs_values[i][0]) + sat_vhs_values[i][0]
    var ind: StaticArray[Int, 4] = StaticArray[Int, 4](0)
    ind[0] = Index2D(0, TSatIndex, 4)
    ind[1] = Index2D(1, TSatIndex, 4)
    ind[2] = Index2D(2, TSatIndex, 4)
    ind[3] = Index2D(3, TSatIndex, 4)
    data[].P = ((water_sat_pres_coef_array[ind[0]] * dT +
                  water_sat_pres_coef_array[ind[1]]) * dT +
                  water_sat_pres_coef_array[ind[2]]) * dT +
                  water_sat_pres_coef_array[ind[3]]
    data[].dens = 1.0 / vhs_values[0]
    data[].V = vhs_values[0]
    data[].H = vhs_values[1]
    data[].S = vhs_values[2]
    data[].U = data[].H - data[].P * data[].V
    var propValues: StaticArray[Float64, 5] = StaticArray[Float64, 5](0.0)
    if Q == 0.0:
        for i in range(5):
            propValues[i] = propDome(i, 0, TSatIndex, dT)
    elif Q == 1.0:
        for i in range(5):
            propValues[i] = propDome(i, 1, TSatIndex, dT)
    data[].Cv = propValues[0]
    data[].Cp = propValues[1]
    data[].ssnd = propValues[2]
    data[].cond = propValues[3]
    data[].visc = propValues[4]
    data[].T = T
    data[].Q = Q
    return error_code

def water_PQ(P: Float64, Q: Float64, data: Pointer[property_info]) -> Int:
    /************************************************************
    *************************************************************/
    var error_code: Int = 0
    data[].P = P
    data[].Q = Q
    if Q > 1.0 or Q < 0.0:
        error_code = 1
        return error_code
    if P > water_max_sat_pres or P < water_min_sat_pres:
        error_code = 3
        return error_code
    var TSat: Float64 = t_sat(P)
    var TSatIndex: Int
    var dT: Float64
    sat_find(TSat, &TSatIndex, &dT)
    var sat_vhs_values: StaticArray[StaticArray[Float64, 2], 3] = StaticArray[StaticArray[Float64, 2], 3](StaticArray[Float64, 2](0.0))
    for i in range(3):
        for j in range(2):
            sat_vhs_values[i][j] = VHSDome(i, j, TSatIndex, dT)
    var vhs_values: StaticArray[Float64, 3] = StaticArray[Float64, 3](0.0)
    for i in range(3):
        vhs_values[i] = Q * (sat_vhs_values[i][1] - sat_vhs_values[i][0]) + sat_vhs_values[i][0]
    data[].T = TSat
    data[].dens = 1.0 / vhs_values[0]
    data[].V = vhs_values[0]
    data[].H = vhs_values[1]
    data[].S = vhs_values[2]
    data[].U = vhs_values[1] - P * vhs_values[0]  # U = H - PV
    var propValues: StaticArray[Float64, 5] = StaticArray[Float64, 5](0.0)
    if Q == 0.0:
        for i in range(5):
            propValues[i] = propDome(i, 0, TSatIndex, dT)
    elif Q == 1.0:
        for i in range(5):
            propValues[i] = propDome(i, 1, TSatIndex, dT)
    data[].Cv = propValues[0]
    data[].Cp = propValues[1]
    data[].ssnd = propValues[2]
    data[].cond = propValues[3]
    data[].visc = propValues[4]
    data[].P = P
    data[].Q = Q
    return error_code

def water_TP(T: Float64, P: Float64, data: Pointer[property_info]) -> Int:
    /************************************************************
    *************************************************************/
    var error_code: Int = 0
    data[].P = P
    data[].T = T
    if P > water_max_sat_pres or P < water_min_sat_pres:
        error_code = 4
        return error_code
    if T < water_min_temp or T > water_max_temp:
        error_code = 7
        return error_code
    if P <= water_max_sat_pres:
        var TSat: Float64 = t_sat(P)
        if T == TSat:
            error_code = 8
            return error_code
        var pIndex: Int
        var pFraction: Float64
        pres_find(P, &pIndex, &pFraction)
        if T > TSat:
            var firstCoefIndex: Int = water_vapor_entr_index_vector[pIndex] - pIndex
            var Tgrid: Float64 = vaporGrid(0, 0, firstCoefIndex, pFraction)
            if T < Tgrid:
                var sFraction: Float64 = (T - TSat) / (Tgrid - TSat)
                VaporGap(firstCoefIndex, TSat, sFraction, data)
            else:
                error_code = VaporNonGap(pIndex, pFraction, data, 0, T)
        else:
            var lastCoefIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - pIndex - 2
            var TGrid: Float64 = liquidGrid(0, lastCoefIndex, pFraction, 1.0)
            if T > TGrid:
                var sFraction: Float64 = (T - TGrid) / (TSat - TGrid)
                LiquidGap(lastCoefIndex, TSat, sFraction, data)
            else:
                LiquidNonGap(pIndex, pFraction, data, 0, T)
    else:
        error_code = 99
    data[].T = T
    data[].P = P
    return error_code

def water_PH(P: Float64, H: Float64, data: Pointer[property_info]) -> Int:
    /************************************************************
    *************************************************************/
    data[].P = P
    data[].H = H
    var error_code: Int = 0
    if P > water_max_sat_pres or P < water_min_sat_pres:
        error_code = 4
        return error_code
    if P <= water_max_sat_pres:
        var TSatIndex: Int
        var dT: Float64
        var TSat: Float64 = t_sat(P)
        sat_find(TSat, &TSatIndex, &dT)
        var pIndex: Int
        var pFraction: Float64
        pres_find(P, &pIndex, &pFraction)
        var HSat: StaticArray[Float64, 2] = StaticArray[Float64, 2](0.0)
        HSat[0] = VHSDome(1, 0, TSatIndex, dT)
        HSat[1] = VHSDome(1, 1, TSatIndex, dT)
        if H > HSat[1]:
            var firstCoefIndex: Int = water_vapor_entr_index_vector[pIndex] - pIndex
            var HGrid: Float64 = vaporGrid(0, 2, firstCoefIndex, pFraction)
            if H < HGrid:
                var sFraction: Float64 = (H - HSat[1]) / (HGrid - HSat[1])
                VaporGap(firstCoefIndex, TSat, sFraction, data)
            else:
                error_code = VaporNonGap(pIndex, pFraction, data, 2, H)
        elif H >= HSat[0]:
            data[].Q = (H - HSat[0]) / (HSat[1] - HSat[0])
            var sat_vhs_values: StaticArray[StaticArray[Float64, 2], 3] = StaticArray[StaticArray[Float64, 2], 3](StaticArray[Float64, 2](0.0))
            var vhs_values: StaticArray[Float64, 3] = StaticArray[Float64, 3](0.0)
            for i in range(3):
                for j in range(2):
                    sat_vhs_values[i][j] = VHSDome(i, j, TSatIndex, dT)
                vhs_values[i] = data[].Q * (sat_vhs_values[i][1] - sat_vhs_values[i][0]) + sat_vhs_values[i][0]
            data[].T = TSat
            data[].V = vhs_values[0]
            data[].dens = 1.0 / data[].V
            data[].S = vhs_values[2]
            data[].U = H - data[].P * data[].V
            var prop_values: StaticArray[Float64, 5] = StaticArray[Float64, 5](0.0)
            var Q: Float64 = data[].Q
            if Q == 0.0:
                for i in range(5):
                    prop_values[i] = propDome(i, 0, TSatIndex, dT)
            elif Q == 1.0:
                for i in range(5):
                    prop_values[i] = propDome(i, 1, TSatIndex, dT)
            data[].Cv = prop_values[0]
            data[].Cp = prop_values[1]
            data[].ssnd = prop_values[2]
            data[].cond = prop_values[3]
            data[].visc = prop_values[4]
        else:
            var lastCoefIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - pIndex - 2
            var HGrid: Float64 = liquidGrid(2, lastCoefIndex, pFraction, 1.0)
            if H > HGrid:
                var sFraction: Float64 = (H - HGrid) / (HSat[0] - HGrid)
                LiquidGap(lastCoefIndex, TSat, sFraction, data)
            else:
                LiquidNonGap(pIndex, pFraction, data, 2, H)
    else:
        error_code = 99
    data[].P = P
    data[].H = H
    return error_code

def water_PS(P: Float64, S: Float64, data: Pointer[property_info]) -> Int:
    /************************************************************
    *************************************************************/
    data[].P = P
    data[].S = S
    var error_code: Int = 0
    if P > water_max_sat_pres or P < water_min_sat_pres:
        error_code = 4
        return error_code
    if P <= water_max_sat_pres:
        var TSat: Float64 = t_sat(P)
        var TSatIndex: Int
        var dT: Float64
        sat_find(TSat, &TSatIndex, &dT)
        var SSat: StaticArray[Float64, 2] = StaticArray[Float64, 2](0.0)
        SSat[0] = VHSDome(2, 0, TSatIndex, dT)
        SSat[1] = VHSDome(2, 1, TSatIndex, dT)
        var pIndex: Int
        var pFraction: Float64
        pres_find(P, &pIndex, &pFraction)
        if S > SSat[1]:
            var firstIndex: Int = water_vapor_entr_index_vector[pIndex]
            if S < water_vapor_entr_values[firstIndex]:
                var sFraction: Float64 = (S - SSat[1]) / (water_vapor_entr_values[firstIndex] - SSat[1])
                var firstCoefIndex: Int = water_vapor_entr_index_vector[pIndex] - pIndex
                VaporGap(firstCoefIndex, TSat, sFraction, data)
            else:
                var lastIndex: Int = water_vapor_entr_index_vector[pIndex + 1] - 1
                var rowInd: Int = maxloc(firstIndex, lastIndex, water_vapor_entr_values, S)
                var sIndex: Int = firstIndex + rowInd
                if sIndex >= lastIndex:
                    if S == water_vapor_entr_values[lastIndex]:
                        rowInd -= 1
                        sIndex -= 1
                    else:
                        error_code = 5
                        return error_code
                var sFraction: Float64 = (S - water_vapor_entr_values[sIndex]) / (water_vapor_entr_values[sIndex + 1] - water_vapor_entr_values[sIndex])
                var coefIndex: Int = firstIndex - pIndex + rowInd
                data[].T = vaporGrid(0, coefIndex, pFraction, sFraction)
                data[].dens = vaporGrid(1, coefIndex, pFraction, sFraction)
                data[].V = 1.0 / data[].dens
                data[].H = vaporGrid(2, coefIndex, pFraction, sFraction)
                data[].Cv = vaporGrid(3, coefIndex, pFraction, sFraction)
                data[].Cp = vaporGrid(4, coefIndex, pFraction, sFraction)
                data[].ssnd = vaporGrid(5, coefIndex, pFraction, sFraction)
                data[].cond = vaporGrid(6, coefIndex, pFraction, sFraction)
                data[].visc = vaporGrid(7, coefIndex, pFraction, sFraction)
                data[].U = data[].H - data[].P * data[].V
                data[].Q = 10
        elif S >= SSat[0]:
            var Q: Float64 = (S - SSat[0]) / (SSat[1] - SSat[0])
            var sat_vhs_values: StaticArray[StaticArray[Float64, 2], 2] = StaticArray[StaticArray[Float64, 2], 2](StaticArray[Float64, 2](0.0))
            var vhs_values: StaticArray[Float64, 2] = StaticArray[Float64, 2](0.0)
            for i in range(2):
                for j in range(2):
                    sat_vhs_values[i][j] = VHSDome(i, j, TSatIndex, dT)
                vhs_values[i] = Q * (sat_vhs_values[i][1] - sat_vhs_values[i][0]) + sat_vhs_values[i][0]
            data[].T = TSat
            data[].V = vhs_values[0]
            data[].dens = 1.0 / data[].V
            data[].H = vhs_values[1]
            data[].U = data[].H - data[].P * data[].V
            data[].Q = Q
            var prop_values: StaticArray[Float64, 5] = StaticArray[Float64, 5](0.0)
            if Q == 0.0:
                for i in range(5):
                    prop_values[i] = propDome(i, 0, TSatIndex, dT)
            elif Q == 1.0:
                for i in range(5):
                    prop_values[i] = propDome(i, 1, TSatIndex, dT)
            data[].Cv = prop_values[0]
            data[].Cp = prop_values[1]
            data[].ssnd = prop_values[2]
            data[].cond = prop_values[3]
            data[].visc = prop_values[4]
        else:
            var lastIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - 1
            if S > water_liquid_entr_values[lastIndex]:
                var sFraction: Float64 = (S - water_liquid_entr_values[lastIndex]) / (SSat[0] - water_liquid_entr_values[lastIndex])
                var lastCoefIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - pIndex - 2
                LiquidGap(lastCoefIndex, TSat, sFraction, data)
            else:
                var firstIndex: Int = water_liquid_entr_index_vector[pIndex]
                var rowInd: Int = maxloc(firstIndex, lastIndex, water_liquid_entr_values, S)
                var sIndex: Int = firstIndex + rowInd
                if sIndex == lastIndex and S == water_liquid_entr_values[lastIndex]:
                    rowInd -= 1
                    sIndex -= 1
                if S < water_liquid_entr_values[firstIndex]:
                    error_code = 6
                    return error_code
                var sFraction: Float64 = (S - water_liquid_entr_values[sIndex]) / (water_liquid_entr_values[sIndex + 1] - water_liquid_entr_values[sIndex])
                var coefIndex: Int = water_liquid_entr_index_vector[pIndex] - pIndex + rowInd
                data[].T = liquidGrid(0, coefIndex, pFraction, sFraction)
                data[].dens = liquidGrid(1, coefIndex, pFraction, sFraction)
                data[].V = 1.0 / data[].dens
                data[].H = liquidGrid(2, coefIndex, pFraction, sFraction)
                data[].Cv = liquidGrid(3, coefIndex, pFraction, sFraction)
                data[].Cp = liquidGrid(4, coefIndex, pFraction, sFraction)
                data[].ssnd = liquidGrid(5, coefIndex, pFraction, sFraction)
                data[].cond = liquidGrid(6, coefIndex, pFraction, sFraction)
                data[].visc = liquidGrid(7, coefIndex, pFraction, sFraction)
                data[].U = data[].H - data[].P * data[].V
                data[].Q = -10
    else:
        error_code = 99
    data[].P = P
    data[].S = S
    return error_code

def VaporNonGap(pIndex: Int, pFraction: Float64, data: Pointer[property_info], edgeInd: Int, indVar: Float64) -> Int:
    var error_code: Int = 0
    var fortranOffset: Int = -1
    var firstCoefIndex: Int = water_vapor_entr_index_vector[pIndex] - pIndex + 1 + fortranOffset
    var lastCoefIndex: Int = water_vapor_entr_index_vector[pIndex + 1] - pIndex - 1 + fortranOffset
    var edge: DynamicVector[Float64] = DynamicVector[Float64]()
    edge.reserve(lastCoefIndex - firstCoefIndex + 1)
    for i in range(firstCoefIndex, lastCoefIndex + 1):
        edge.append(vaporGrid(0, edgeInd, i, pFraction))
    var rowInd: Int = maxloc(edge, indVar)
    var coefIndex: Int = firstCoefIndex + rowInd
    var pAdjustedCoefs: StaticArray[Float64, 4] = StaticArray[Float64, 4](0.0)
    for i in range(4):
        pAdjustedCoefs[i] = vaporGrid(i, edgeInd, coefIndex, pFraction)
    var sFraction: Float64 = cubic_solution(pAdjustedCoefs[0], pAdjustedCoefs[1], pAdjustedCoefs[2], pAdjustedCoefs[3], indVar)
    if fabs(sFraction) > 1.0:
        return error_code = 9
    var sIndex: Int = water_vapor_entr_index_vector[pIndex] + rowInd
    data[].S = water_vapor_entr_values[sIndex] + sFraction * (water_vapor_entr_values[sIndex + 1] - water_vapor_entr_values[sIndex])
    data[].T = vaporGrid(0, coefIndex, pFraction, sFraction)
    data[].dens = vaporGrid(1, coefIndex, pFraction, sFraction)
    data[].V = 1.0 / data[].dens
    data[].H = vaporGrid(2, coefIndex, pFraction, sFraction)
    data[].Cv = vaporGrid(3, coefIndex, pFraction, sFraction)
    data[].Cp = vaporGrid(4, coefIndex, pFraction, sFraction)
    data[].ssnd = vaporGrid(5, coefIndex, pFraction, sFraction)
    data[].cond = vaporGrid(6, coefIndex, pFraction, sFraction)
    data[].visc = vaporGrid(7, coefIndex, pFraction, sFraction)
    data[].U = data[].H - data[].P * data[].V
    data[].Q = 10
    return error_code

def LiquidNonGap(pIndex: Int, pFraction: Float64, data: Pointer[property_info], edgeInd: Int, indVar: Float64):
    var fortranOffset: Int = -1
    var firstCoefIndex: Int = water_liquid_entr_index_vector[pIndex] - pIndex + 1 + fortranOffset
    var lastCoefIndex: Int = water_liquid_entr_index_vector[pIndex + 1] - pIndex - 1 + fortranOffset
    var edge: DynamicVector[Float64] = DynamicVector[Float64]()
    edge.reserve(lastCoefIndex - firstCoefIndex + 1)
    for i in range(firstCoefIndex, lastCoefIndex + 1):
        edge.append(liquidGrid(0, edgeInd, i, pFraction))
    var rowInd: Int = maxloc(edge, indVar)
    var coefIndex: Int = firstCoefIndex + rowInd
    var pAdjustedCoefs: StaticArray[Float64, 4] = StaticArray[Float64, 4](0.0)
    for i in range(4):
        pAdjustedCoefs[i] = liquidGrid(i, edgeInd, coefIndex, pFraction)
    var sFraction: Float64 = cubic_solution(pAdjustedCoefs[0], pAdjustedCoefs[1], pAdjustedCoefs[2], pAdjustedCoefs[3], indVar)
    var sIndex: Int = water_liquid_entr_index_vector[pIndex] + rowInd
    data[].S = water_liquid_entr_values[sIndex] + sFraction * (water_liquid_entr_values[sIndex + 1] - water_liquid_entr_values[sIndex])
    data[].T = liquidGrid(0, coefIndex, pFraction, sFraction)
    data[].dens = liquidGrid(1, coefIndex, pFraction, sFraction)
    data[].V = 1.0 / data[].dens
    data[].H = liquidGrid(2, coefIndex, pFraction, sFraction)
    data[].Cv = liquidGrid(3, coefIndex, pFraction, sFraction)
    data[].Cp = liquidGrid(4, coefIndex, pFraction, sFraction)
    data[].ssnd = liquidGrid(5, coefIndex, pFraction, sFraction)
    data[].cond = liquidGrid(6, coefIndex, pFraction, sFraction)
    data[].visc = liquidGrid(7, coefIndex, pFraction, sFraction)
    data[].U = data[].H - data[].P * data[].V
    data[].Q = -10

def VaporGap(firstCoefIndex: Int, TSat: Float64, sFraction: Float64, data: Pointer[property_info]):
    var TSatIndex: Int
    var dT: Float64
    sat_find(TSat, &TSatIndex, &dT)
    var pIndex: Int
    var pFraction: Float64
    pres_find(data[].P, &pIndex, &pFraction)
    data[].T = vapor_gap_temp(sFraction, pFraction, TSat, firstCoefIndex)
    data[].dens = vapor_gap_dens(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].V = 1.0 / data[].dens
    data[].H = vapor_gap_enth(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].S = vapor_gap_entr(sFraction, dT, TSatIndex, pIndex)
    data[].U = data[].H - data[].P * data[].V
    data[].Cv = vapor_gap_cv(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].Cp = vapor_gap_cp(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].ssnd = vapor_gap_ssnd(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].cond = vapor_gap_cond(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].visc = vapor_gap_visc(sFraction, pFraction, dT, TSatIndex, firstCoefIndex)
    data[].Q = 10.0

def LiquidGap(lastCoefIndex: Int, TSat: Float64, sFraction: Float64, data: Pointer[property_info]):
    var TSatIndex: Int
    var dT: Float64
    sat_find(TSat, &TSatIndex, &dT)
    var pIndex: Int
    var pFraction: Float64
    pres_find(data[].P, &pIndex, &pFraction)
    data[].T = liquid_gap_temp(sFraction, pFraction, TSat, lastCoefIndex)
    data[].dens = liquid_gap_dens(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].V = 1.0 / data[].dens
    data[].H = liquid_gap_enth(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].S = liquid_gap_entr(sFraction, dT, TSatIndex, pIndex)
    data[].U = data[].H - data[].P * data[].V
    data[].Cv = liquid_gap_cv(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].Cp = liquid_gap_cp(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].ssnd = liquid_gap_ssnd(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].cond = liquid_gap_cond(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].visc = liquid_gap_visc(sFraction, pFraction, dT, TSatIndex, lastCoefIndex)
    data[].Q = -10.0

def cubic_solution(coef_1: Float64, coef_2: Float64, coef_3: Float64, coef_4: Float64, value: Float64) -> Float64:
    var PI: Float64 = 3.1415926535897932384626433
    var root: Float64 = -999999999999.0
    var one_third: Float64 = 1.0 / 3.0
    var a: Float64 = coef_3 / coef_4
    var b: Float64 = coef_2 / coef_4
    var c: Float64 = (coef_1 - value) / coef_4
    var q: Float64 = ((a * a) - 3.0 * b) * (1.0 / 9.0)
    var r: Float64 = (2.0 * (a * a * a) - 9.0 * (a * b) + 27.0 * c) * (1.0 / 54.0)
    var r2: Float64 = r * r
    var q3: Float64 = q * q * q
    if r2 < q3:
        var theta: Float64 = acos(r / sqrt(q3))
        var root_basis: Float64 = -2.0 * sqrt(q)
        var root_1: Float64 = root_basis * cos(theta / 3.0) - a / 3.0
        if (root_1 >= 0.0) and (root_1 <= 1.0):
            root = root_1
            return root
        else:
            var root_2: Float64 = root_basis * cos((theta + 2.0 * PI) / 3.0) - a / 3.0
            if (root_2 >= 0.0) and (root_2 <= 1.0):
                root = root_2
                return root
            else:
                var root_3: Float64 = root_basis * cos((theta - 2.0 * PI) / 3.0) - a / 3.0
                if (root_3 >= 0.0) and (root_3 <= 1.0):
                    root = root_3
                    return root
                else:
                    var froot_1: Float64 = fabs(root_1)
                    var froot_2: Float64 = fabs(root_2)
                    var froot_3: Float64 = fabs(root_3)
                    if (froot_1 < froot_2) and (froot_1 < froot_3):
                        root = root_1
                    elif (froot_2 < froot_1) and (froot_2 < froot_3):
                        root = root_2
                    else:
                        root = root_3
                    return root
    else:
        var sign: Int = 1
        var t1: Float64 = sqrt(r2 - q3)
        var A: Float64
        var B: Float64
        if r < 0:
            sign = -1
        A = -sign * pow((fabs(r) + t1), one_third)
        if fabs(A) < 1e-9:
            B = 0
        else:
            B = q / A
        root = (A + B) - a * one_third
        return root

def t_sat(P: Float64) -> Float64:
    var index: Int = -1
    if P >= water_sat_pres_vector[index + 64]:
        index = index + 64
    if P >= water_sat_pres_vector[index + 32]:
        index = index + 32
    if P >= water_sat_pres_vector[index + 16]:
        index = index + 16
    if P >= water_sat_pres_vector[index + 8]:
        index = index + 8
    if P >= water_sat_pres_vector[index + 4]:
        index = index + 4
    if P >= water_sat_pres_vector[index + 2]:
        index = index + 2
    if P >= water_sat_pres_vector[index + 1]:
        index = index + 1
    var dP: Float64 = P - water_sat_pres_vector[index]
    var ind: StaticArray[Int, 4] = StaticArray[Int, 4](0)
    ind[0] = Index2D(0, index, 4)
    ind[1] = Index2D(1, index, 4)
    ind[2] = Index2D(2, index, 4)
    ind[3] = Index2D(3, index, 4)
    var TSat: Float64 = ((water_sat_temp_coef_array[ind[0]] * dP +
                           water_sat_temp_coef_array[ind[1]]) * dP +
                           water_sat_temp_coef_array[ind[2]]) * dP +
                           water_sat_temp_coef_array[ind[3]]
    return TSat

def sat_find(T: Float64, TSatIndex: Pointer[Int], dT: Pointer[Float64]):
    var index: Int = -1
    if T >= water_sat_temp_vector[index + 64]:
        index = index + 64
    if T >= water_sat_temp_vector[index + 32]:
        index = index + 32
    if T >= water_sat_temp_vector[index + 16]:
        index = index + 16
    if T >= water_sat_temp_vector[index + 8]:
        index = index + 8
    if T >= water_sat_temp_vector[index + 4]:
        index = index + 4
    if T >= water_sat_temp_vector[index + 2]:
        index = index + 2
    if T >= water_sat_temp_vector[index + 1]:
        index = index + 1
    if index == 126 and T == water_sat_temp_vector[126]:
        index = 125
    TSatIndex[] = index
    dT[] = T - water_sat_temp_vector[index]

def pres_find(P: Float64, PSatIndex: Pointer[Int], pFraction: Pointer[Float64]):
    var index: Int = -1
    if P >= water_pres_vector[index + 64]:
        index = index + 64
    if P >= water_pres_vector[index + 32]:
        index = index + 32
    if P >= water_pres_vector[index + 16]:
        index = index + 16
    if P >= water_pres_vector[index + 8]:
        index = index + 8
    if P >= water_pres_vector[index + 4]:
        index = index + 4
    if P >= water_pres_vector[index + 2]:
        index = index + 2
    if P >= water_pres_vector[index + 1]:
        index = index + 1
    if index == 126 and P == water_pres_vector[126]:
        index = 125
    pFraction[] = (P - water_pres_vector[index]) / (water_pres_vector[index + 1] - water_pres_vector[index])
    PSatIndex[] = index

def vaporGrid(j: Int, k: Int, firstCoefIndex: Int, pFraction: Float64) -> Float64:
    var ind: StaticArray[Int, 4] = StaticArray[Int, 4](0)
    ind[0] = Index4D(3, j, k, firstCoefIndex, 4, 4, 8)
    ind[1] = Index4D(2, j, k, firstCoefIndex, 4, 4, 8)
    ind[2] = Index4D(1, j, k, firstCoefIndex, 4, 4, 8)
    ind[3] = Index4D(0, j, k, firstCoefIndex, 4, 4, 8)
    var grid: Float64 = ((water_vapor_coef_array[ind[0]] * pFraction +
                           water_vapor_coef_array[ind[1]]) * pFraction +
                           water_vapor_coef_array[ind[2]]) * pFraction +
                           water_vapor_coef_array[ind[3]]
    return grid

def vaporGrid(k: Int, lastCoefIndex: Int, pFraction: Float64, sFraction: Float64 = 1.0) -> Float64:
    var ind: StaticArray[Int, 16] = StaticArray[Int, 16](0)
    ind[0] = Index4D(3, 3, k, lastCoefIndex, 4, 4, 8)
    ind[1] = Index4D(2, 3, k, lastCoefIndex, 4, 4, 8)
    ind[2] = Index4D(1, 3, k, lastCoefIndex, 4, 4, 8)
    ind[3] = Index4D(0, 3, k, lastCoefIndex, 4, 4, 8)
    ind[4] = Index4D(3, 2, k, lastCoefIndex, 4, 4, 8)
    ind[5] = Index4D(2, 2, k, lastCoefIndex, 4, 4, 8)
    ind[6] = Index4D(1, 2, k, lastCoefIndex, 4, 4, 8)
    ind[7] = Index4D(0, 2, k, lastCoefIndex, 4, 4, 8)
    ind[8] = Index4D(3, 1, k, lastCoefIndex, 4, 4, 8)
    ind[9] = Index4D(2, 1, k, lastCoefIndex, 4, 4, 8)
    ind[10] = Index4D(1, 1, k, lastCoefIndex, 4, 4, 8)
    ind[11] = Index4D(0, 1, k, lastCoefIndex, 4, 4, 8)
    ind[12] = Index4D(3, 0, k, lastCoefIndex, 4, 4, 8)
    ind[13] = Index4D(2, 0, k, lastCoefIndex, 4, 4, 8)
    ind[14] = Index4D(1, 0, k, lastCoefIndex, 4, 4, 8)
    ind[15] = Index4D(0, 0, k, lastCoefIndex, 4, 4, 8)
    var grid: Float64 = (((((water_vapor_coef_array[ind[0]] * pFraction +
        water_vapor_coef_array[ind[1]]) * pFraction +
        water_vapor_coef_array[ind[2]]) * pFraction +
        water_vapor_coef_array[ind[3]]) * sFraction) +
        ((water_vapor_coef_array[ind[4]] * pFraction +
        water_vapor_coef_array[ind[5]]) * pFraction +
        water_vapor_coef_array[ind[6]]) * pFraction +
        water_vapor_coef_array[ind[7]]) * sFraction +
        ((water_vapor_coef_array[ind[8]] * pFraction +
        water_vapor_coef_array[ind[9]]) * pFraction +
        water_vapor_coef_array[ind[10]]) * pFraction +
        water_vapor_coef_array[ind[11]]) * sFraction +
        ((water_vapor_coef_array[ind[12]] * pFraction +
        water_vapor_coef_array[ind[13]]) * pFraction +
        water_vapor_coef_array[ind[14]]) * pFraction +
        water_vapor_coef_array[ind[15]]
    return grid

def liquidGrid(j: Int, k: Int, firstCoefIndex: Int, pFraction: Float64) -> Float64:
    var ind1: Int = Index4D(3, j, k, firstCoefIndex, 4, 4, 8)
    var ind2: Int = Index4D(2, j, k, firstCoefIndex, 4, 4, 8)
    var ind3: Int = Index4D(1, j, k, firstCoefIndex, 4, 4, 8)
    var ind4: Int = Index4D(0, j, k, firstCoefIndex, 4, 4, 8)
    var grid: Float64 = ((water_liquid_coef_array[ind1] * pFraction +
                           water_liquid_coef_array[ind2]) * pFraction +
                           water_liquid_coef_array[ind3]) * pFraction +
                           water_liquid_coef_array[ind4]
    return grid

def liquidGrid(k: Int, lastCoefIndex: Int, pFraction: Float64, sFraction: Float64 = 1.0) -> Float64:
    var ind: StaticArray[Int, 16] = StaticArray[Int, 16](0)
    ind[0] = Index4D(3, 3, k, lastCoefIndex, 4, 4, 8)
    ind[1] = Index4D(2, 3, k, lastCoefIndex, 4, 4, 8)
    ind[2] = Index4D(1, 3, k, lastCoefIndex, 4, 4, 8)
    ind[3] = Index4D(0, 3, k, lastCoefIndex, 4, 4, 8)
    ind[4] = Index4D(3, 2, k, lastCoefIndex, 4, 4, 8)
    ind[5] = Index4D(2, 2, k, lastCoefIndex, 4, 4, 8)
    ind[6] = Index4D(1, 2, k, lastCoefIndex, 4, 4, 8)
    ind[7] = Index4D(0, 2, k, lastCoefIndex, 4, 4, 8)
    ind[8] = Index4D(3, 1, k, lastCoefIndex, 4, 4, 8)
    ind[9] = Index4D(2, 1, k, lastCoefIndex, 4, 4, 8)
    ind[10] = Index4D(1, 1, k, lastCoefIndex, 4, 4, 8)
    ind[11] = Index4D(0, 1, k, lastCoefIndex, 4, 4, 8)
    ind[12] = Index4D(3, 0, k, lastCoefIndex, 4, 4, 8)
    ind[13] = Index4D(2, 0, k, lastCoefIndex, 4, 4, 8)
    ind[14] = Index4D(1, 0, k, lastCoefIndex, 4, 4, 8)
    ind[15] = Index4D(0, 0, k, lastCoefIndex, 4, 4, 8)
    var grid: Float64 = (((((water_liquid_coef_array[ind[0]] * pFraction +
        water_liquid_coef_array[ind[1]]) * pFraction +
        water_liquid_coef_array[ind[2]]) * pFraction +
        water_liquid_coef_array[ind[3]]) * sFraction) +
        ((water_liquid_coef_array[ind[4]] * pFraction +
        water_liquid_coef_array[ind[5]]) * pFraction +
        water_liquid_coef_array[ind[6]]) * pFraction +
        water_liquid_coef_array[ind[7]]) * sFraction +
        ((water_liquid_coef_array[ind[8]] * pFraction +
        water_liquid_coef_array[ind[9]]) * pFraction +
        water_liquid_coef_array[ind[10]]) * pFraction +
        water_liquid_coef_array[ind[11]]) * sFraction +
        ((water_liquid_coef_array[ind[12]] * pFraction +
        water_liquid_coef_array[ind[13]]) * pFraction +
        water_liquid_coef_array[ind[14]]) * pFraction +
        water_liquid_coef_array[ind[15]]
    return grid

def propDome(j: Int, k: Int, TSatIndex: Int, dT: Float64) -> Float64:
    var ind: StaticArray[Int, 4] = StaticArray[Int, 4](0)
    ind[0] = Index4D(0, j, k, TSatIndex, 4, 5, 2)
    ind[1] = Index4D(1, j, k, TSatIndex, 4, 5, 2)
    ind[2] = Index4D(2, j, k, TSatIndex, 4, 5, 2)
    ind[3] = Index4D(3, j, k, TSatIndex, 4, 5, 2)
    var dome: Float64 = ((water_sat_prop_coef_array[ind[0]] * dT +
                           water_sat_prop_coef_array[ind[1]]) * dT +
                           water_sat_prop_coef_array[ind[2]]) * dT +
                           water_sat_prop_coef_array[ind[3]]
    return dome

def VHSDome(i: Int, j: Int, TSatIndex: Int, dT: Float64) -> Float64:
    var ind: StaticArray[Int, 4] = StaticArray[Int, 4](0)
    ind[0] = Index4D(i, j, 0, TSatIndex, 3, 2, 4)
    ind[1] = Index4D(i, j, 1, TSatIndex, 3, 2, 4)
    ind[2] = Index4D(i, j, 2, TSatIndex, 3, 2, 4)
    ind[3] = Index4D(i, j, 3, TSatIndex, 3, 2, 4)
    var dome: Float64 = ((water_sat_vhs_coef_array[ind[0]] * dT +
        water_sat_vhs_coef_array[ind[1]]) * dT +
        water_sat_vhs_coef_array[ind[2]]) * dT +
        water_sat_vhs_coef_array[ind[3]]
    return dome

def maxloc(firstIndex: Int, lastIndex: Int, valueVector: Pointer[Float64], S: Float64) -> Int:
    var maxS: Float64 = 0.0
    var rowInd: Int = -1
    for i in range(firstIndex, lastIndex):
        if valueVector[i] < S:
            if valueVector[i] > maxS:
                rowInd += 1
                maxS = valueVector[i]
    return rowInd

def maxloc(valueVector: DynamicVector[Float64], S: Float64) -> Int:
    var maxS: Float64 = 0.0
    var rowInd: Int = -1
    for i in range(valueVector.size):
        if valueVector[i] < S:
            if valueVector[i] > maxS:
                rowInd += 1
                maxS = valueVector[i]
        else:
            return rowInd
    return rowInd