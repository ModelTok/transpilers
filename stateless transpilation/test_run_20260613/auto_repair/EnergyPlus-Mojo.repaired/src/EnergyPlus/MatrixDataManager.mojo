from Data.BaseData import BaseGlobalStruct
from DataGlobals import *
from EnergyPlus import *
from Data.EnergyPlusData import EnergyPlusData
from DataIPShortCuts import *
from InputProcessing.InputProcessor import *
from UtilityRoutines import *
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.Array2D import Array2D
from ObjexxFCL.Array2S import Array2S
from ObjexxFCL.Fmath import mod, floor
from ObjexxFCL.Fmath import FindItemInList as Util_FindItemInList
from ObjexxFCL.Fmath import ShowSevereError, ShowContinueError, ShowFatalError
from math import floor as std_floor
from string import String
from format import format

alias TwoDimensional = 2

@value
struct MatrixDataStruct:
    var Name: String
    var MatrixType: Int
    var Mat2D: Array2D[Float64]
    def __init__(inout self):
        self.MatrixType = 0
        self.Name = String("")
        self.Mat2D = Array2D[Float64]()

@value
struct MatrixDataManagerData(BaseGlobalStruct):
    var MatData: Array1D[MatrixDataStruct]
    var NumMats: Int
    def __init__(inout self):
        self.MatData = Array1D[MatrixDataStruct]()
        self.NumMats = 0
    def init_constant_state(inout self, inout state: EnergyPlusData):

    def init_state(inout self, inout state: EnergyPlusData):

    def clear_state(inout self):
        self.MatData.clear()
        self.NumMats = Int()

def GetMatrixInput(inout state: EnergyPlusData):
    var NumTwoDimMatrix: Int
    var MatIndex: Int
    var MatNum: Int
    var NumAlphas: Int
    var NumNumbers: Int
    var IOStatus: Int
    var ErrorsFound: Bool = False
    var cCurrentModuleObject: String = "Matrix:TwoDimension"
    NumTwoDimMatrix = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
    state.dataMatrixDataManager.NumMats = NumTwoDimMatrix
    state.dataMatrixDataManager.MatData.allocate(state.dataMatrixDataManager.NumMats)
    MatNum = 0
    for MatIndex in range(1, NumTwoDimMatrix + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(state,
                                                                 cCurrentModuleObject,
                                                                 MatIndex,
                                                                 state.dataIPShortCut.cAlphaArgs,
                                                                 NumAlphas,
                                                                 state.dataIPShortCut.rNumericArgs,
                                                                 NumNumbers,
                                                                 IOStatus,
                                                                 state.dataIPShortCut.lNumericFieldBlanks,
                                                                 _,
                                                                 state.dataIPShortCut.cAlphaFieldNames,
                                                                 state.dataIPShortCut.cNumericFieldNames)
        MatNum += 1
        state.dataMatrixDataManager.MatData[MatNum].Name = state.dataIPShortCut.cAlphaArgs[1]
        var NumRows: Int = std_floor(state.dataIPShortCut.rNumericArgs[1])
        var NumCols: Int = std_floor(state.dataIPShortCut.rNumericArgs[2])
        var NumElements: Int = NumRows * NumCols
        if NumElements < 1:
            ShowSevereError(state, format("GetMatrixInput: for {}: {}", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[1]))
            ShowContinueError(state,
                              format("Check {} and {} total number of elements in matrix must be 1 or more",
                                      state.dataIPShortCut.cNumericFieldNames[1],
                                      state.dataIPShortCut.cNumericFieldNames[2]))
            ErrorsFound = True
        if (NumNumbers - 2) < NumElements:
            ShowSevereError(state, format("GetMatrixInput: for {}: {}", cCurrentModuleObject, state.dataIPShortCut.cAlphaArgs[1]))
            ShowContinueError(state,
                              format("Check input, total number of elements does not agree with {} and {}",
                                      state.dataIPShortCut.cNumericFieldNames[1],
                                      state.dataIPShortCut.cNumericFieldNames[2]))
            ErrorsFound = True
        state.dataMatrixDataManager.MatData[MatNum].MatrixType = TwoDimensional
        var matrix: Array2D[Float64] = state.dataMatrixDataManager.MatData[MatNum].Mat2D
        matrix.allocate(NumCols, NumRows)
        var l: Int = 0
        for ElementNum in range(1, NumElements + 1):
            var RowIndex: Int = (ElementNum - 1) // NumCols + 1
            var ColIndex: Int = mod((ElementNum - 1), NumCols) + 1
            matrix[ColIndex, RowIndex] = state.dataIPShortCut.rNumericArgs[ElementNum + 2]
            l += matrix.size()
    if ErrorsFound:
        ShowFatalError(state, "GetMatrixInput: Errors found in Matrix objects. Preceding condition(s) cause termination.")

def MatrixIndex(inout state: EnergyPlusData, MatrixName: String) -> Int:
    var MatrixIndexPtr: Int
    if state.dataUtilityRoutines.GetMatrixInputFlag:
        GetMatrixInput(state)
        state.dataUtilityRoutines.GetMatrixInputFlag = False
    if state.dataMatrixDataManager.NumMats > 0:
        MatrixIndexPtr = Util_FindItemInList(MatrixName, state.dataMatrixDataManager.MatData)
    else:
        MatrixIndexPtr = 0
    return MatrixIndexPtr

def Get2DMatrix(inout state: EnergyPlusData, Idx: Int, inout Mat2D: Array2S[Float64]):
    if Idx > 0:
        Mat2D = state.dataMatrixDataManager.MatData[Idx].Mat2D
    else:

def Get2DMatrixDimensions(inout state: EnergyPlusData, Idx: Int, inout NumRows: Int, inout NumCols: Int):
    if Idx > 0:
        NumRows = state.dataMatrixDataManager.MatData[Idx].Mat2D.isize(2)
        NumCols = state.dataMatrixDataManager.MatData[Idx].Mat2D.isize(1)
    else:
