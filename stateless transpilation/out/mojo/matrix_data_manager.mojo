from collections import InlineArray
from math import floor

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with nested data managers
# - InputProcessor: state.dataInputProcessing.inputProcessor (methods: getNumObjectsFound, getObjectItem)
# - ShowSevereError, ShowContinueError, ShowFatalError: UtilityRoutines error functions
# - FindItemInList: Util function to find item in list by Name field
# - math.floor: standard math function

alias TWO_DIMENSIONAL = 2


struct MatrixDataStruct:
    var Name: String
    var MatrixType: Int32
    var Mat2D: List[List[Float64]]

    fn __init__(inout self) -> None:
        self.Name = String()
        self.MatrixType = 0
        self.Mat2D = List[List[Float64]]()


struct MatrixDataManagerData:
    var MatData: List[MatrixDataStruct]
    var NumMats: Int32

    fn __init__(inout self) -> None:
        self.MatData = List[MatrixDataStruct]()
        self.NumMats = 0

    fn clear_state(inout self) -> None:
        self.MatData.clear()
        self.NumMats = 0


fn GetMatrixInput(state: PythonObject) -> None:
    var cCurrentModuleObject = String("Matrix:TwoDimension")
    var NumTwoDimMatrix = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
        state, cCurrentModuleObject
    )

    state.dataMatrixDataManager.NumMats = NumTwoDimMatrix

    var mat_list = List[MatrixDataStruct]()
    for _ in range(NumTwoDimMatrix):
        mat_list.append(MatrixDataStruct())
    state.dataMatrixDataManager.MatData = mat_list

    var MatNum = 0
    for MatIndex in range(1, NumTwoDimMatrix + 1):
        _ = state.dataInputProcessing.inputProcessor.getObjectItem(
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

        state.dataMatrixDataManager.MatData[MatNum - 1].Name = String(
            state.dataIPShortCut.cAlphaArgs[0]
        )
        var NumRows = int(floor(state.dataIPShortCut.rNumericArgs[0]))
        var NumCols = int(floor(state.dataIPShortCut.rNumericArgs[1]))
        var NumElements = NumRows * NumCols

        var ErrorsFound = False

        if NumElements < 1:
            var msg1 = String("GetMatrixInput: for ") + cCurrentModuleObject + String(
                ": "
            ) + String(state.dataIPShortCut.cAlphaArgs[0])
            _ = state.UtilityRoutines.ShowSevereError(state, msg1)
            var msg2 = String("Check ") + String(
                state.dataIPShortCut.cNumericFieldNames[0]
            ) + String(" and ") + String(
                state.dataIPShortCut.cNumericFieldNames[1]
            ) + String(
                " total number of elements in matrix must be 1 or more"
            )
            _ = state.UtilityRoutines.ShowContinueError(state, msg2)
            ErrorsFound = True

        if (len(state.dataIPShortCut.rNumericArgs) - 2) < NumElements:
            var msg1 = String("GetMatrixInput: for ") + cCurrentModuleObject + String(
                ": "
            ) + String(state.dataIPShortCut.cAlphaArgs[0])
            _ = state.UtilityRoutines.ShowSevereError(state, msg1)
            var msg2 = String(
                "Check input, total number of elements does not agree with "
            ) + String(
                state.dataIPShortCut.cNumericFieldNames[0]
            ) + String(" and ") + String(
                state.dataIPShortCut.cNumericFieldNames[1]
            )
            _ = state.UtilityRoutines.ShowContinueError(state, msg2)
            ErrorsFound = True

        state.dataMatrixDataManager.MatData[MatNum - 1].MatrixType = TWO_DIMENSIONAL
        var matrix = List[List[Float64]]()
        for _ in range(NumCols):
            var col = List[Float64]()
            for _ in range(NumRows):
                col.append(0.0)
            matrix.append(col)

        for ElementNum in range(1, NumElements + 1):
            var RowIndex = (ElementNum - 1) // NumCols + 1
            var ColIndex = (ElementNum - 1) % NumCols + 1
            matrix[ColIndex - 1][RowIndex - 1] = state.dataIPShortCut.rNumericArgs[
                ElementNum + 1
            ]

        state.dataMatrixDataManager.MatData[MatNum - 1].Mat2D = matrix

        if ErrorsFound:
            var msg = String(
                "GetMatrixInput: Errors found in Matrix objects. Preceding condition(s) cause termination."
            )
            _ = state.UtilityRoutines.ShowFatalError(state, msg)


fn MatrixIndex(state: PythonObject, MatrixName: String) -> Int32:
    if state.dataUtilityRoutines.GetMatrixInputFlag:
        GetMatrixInput(state)
        state.dataUtilityRoutines.GetMatrixInputFlag = False

    var MatrixIndexPtr: Int32
    if state.dataMatrixDataManager.NumMats > 0:
        MatrixIndexPtr = state.Util.FindItemInList(
            MatrixName, state.dataMatrixDataManager.MatData
        )
    else:
        MatrixIndexPtr = 0

    return MatrixIndexPtr


fn Get2DMatrix(state: PythonObject, Idx: Int32) -> PythonObject:
    if Idx > 0:
        return state.dataMatrixDataManager.MatData[Idx - 1].Mat2D
    else:
        return PythonObject()


fn Get2DMatrixDimensions(state: PythonObject, Idx: Int32) -> tuple[Int32, Int32]:
    var NumRows: Int32 = 0
    var NumCols: Int32 = 0

    if Idx > 0:
        var mat = state.dataMatrixDataManager.MatData[Idx - 1].Mat2D
        if len(mat) > 0:
            NumRows = int32(len(mat[0]))
            NumCols = int32(len(mat))
        else:
            NumRows = 0
            NumCols = 0
    else:
        NumRows = 0
        NumCols = 0

    return (NumRows, NumCols)
