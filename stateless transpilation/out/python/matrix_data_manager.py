from typing import Any, Optional
from dataclasses import dataclass, field
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data managers
# - InputProcessor: state.dataInputProcessing.inputProcessor (methods: getNumObjectsFound, getObjectItem)
# - ShowSevereError, ShowContinueError, ShowFatalError: UtilityRoutines error functions
# - FindItemInList: Util function to find item in list by Name field
# - math.floor: standard math function

TWO_DIMENSIONAL = 2


@dataclass
class MatrixDataStruct:
    Name: str = ""
    MatrixType: int = 0
    Mat2D: list[list[float]] = field(default_factory=list)


@dataclass
class MatrixDataManagerData:
    MatData: list[MatrixDataStruct] = field(default_factory=list)
    NumMats: int = 0

    def clear_state(self) -> None:
        self.MatData.clear()
        self.NumMats = 0


def GetMatrixInput(state: Any) -> None:
    cCurrentModuleObject = "Matrix:TwoDimension"
    NumTwoDimMatrix = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCurrentModuleObject
    )

    state.dataMatrixDataManager.NumMats = NumTwoDimMatrix
    state.dataMatrixDataManager.MatData = [
        MatrixDataStruct() for _ in range(NumTwoDimMatrix)
    ]

    MatNum = 0
    for MatIndex in range(1, NumTwoDimMatrix + 1):
        state.dataInputProcessing.inputProcessor.getObjectItem(
            state,
            cCurrentModuleObject,
            MatIndex,
            state.dataIPShortCut.cAlphaArgs,
            state.dataIPShortCut.rNumericArgs,
            state.dataIPShortCut.lNumericFieldBlanks,
            state.dataIPShortCut.cAlphaFieldNames,
            state.dataIPShortCut.cNumericFieldNames,
        )
        MatNum += 1

        state.dataMatrixDataManager.MatData[MatNum - 1].Name = (
            state.dataIPShortCut.cAlphaArgs[0]
        )
        NumRows = int(math.floor(state.dataIPShortCut.rNumericArgs[0]))
        NumCols = int(math.floor(state.dataIPShortCut.rNumericArgs[1]))
        NumElements = NumRows * NumCols

        ErrorsFound = False

        if NumElements < 1:
            from EnergyPlus.UtilityRoutines import (
                ShowSevereError,
                ShowContinueError,
            )

            ShowSevereError(
                state,
                f"GetMatrixInput: for {cCurrentModuleObject}: {state.dataIPShortCut.cAlphaArgs[0]}",
            )
            ShowContinueError(
                state,
                f"Check {state.dataIPShortCut.cNumericFieldNames[0]} and {state.dataIPShortCut.cNumericFieldNames[1]} total number of elements in matrix must be 1 or more",
            )
            ErrorsFound = True

        if (len(state.dataIPShortCut.rNumericArgs) - 2) < NumElements:
            from EnergyPlus.UtilityRoutines import (
                ShowSevereError,
                ShowContinueError,
            )

            ShowSevereError(
                state,
                f"GetMatrixInput: for {cCurrentModuleObject}: {state.dataIPShortCut.cAlphaArgs[0]}",
            )
            ShowContinueError(
                state,
                f"Check input, total number of elements does not agree with {state.dataIPShortCut.cNumericFieldNames[0]} and {state.dataIPShortCut.cNumericFieldNames[1]}",
            )
            ErrorsFound = True

        state.dataMatrixDataManager.MatData[MatNum - 1].MatrixType = TWO_DIMENSIONAL
        matrix = [[0.0 for _ in range(NumRows)] for _ in range(NumCols)]

        for ElementNum in range(1, NumElements + 1):
            RowIndex = (ElementNum - 1) // NumCols + 1
            ColIndex = (ElementNum - 1) % NumCols + 1
            matrix[ColIndex - 1][RowIndex - 1] = state.dataIPShortCut.rNumericArgs[
                ElementNum + 1
            ]

        state.dataMatrixDataManager.MatData[MatNum - 1].Mat2D = matrix

        if ErrorsFound:
            from EnergyPlus.UtilityRoutines import ShowFatalError

            ShowFatalError(
                state,
                "GetMatrixInput: Errors found in Matrix objects. Preceding condition(s) cause termination.",
            )


def MatrixIndex(state: Any, MatrixName: str) -> int:
    if state.dataUtilityRoutines.GetMatrixInputFlag:
        GetMatrixInput(state)
        state.dataUtilityRoutines.GetMatrixInputFlag = False

    if state.dataMatrixDataManager.NumMats > 0:
        from EnergyPlus.Util import FindItemInList

        MatrixIndexPtr = FindItemInList(
            MatrixName, state.dataMatrixDataManager.MatData
        )
    else:
        MatrixIndexPtr = 0

    return MatrixIndexPtr


def Get2DMatrix(state: Any, Idx: int) -> Optional[list[list[float]]]:
    if Idx > 0:
        return state.dataMatrixDataManager.MatData[Idx - 1].Mat2D
    else:
        return None


def Get2DMatrixDimensions(state: Any, Idx: int) -> tuple[int, int]:
    if Idx > 0:
        mat = state.dataMatrixDataManager.MatData[Idx - 1].Mat2D
        NumRows = len(mat[0]) if mat else 0
        NumCols = len(mat)
    else:
        NumRows = 0
        NumCols = 0

    return NumRows, NumCols
