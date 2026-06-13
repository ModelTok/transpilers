from .Data.EnergyPlusData import EnergyPlusData
from DataIPShortCuts import dataIPShortCut
from .InputProcessing.InputProcessor import InputProcessor
from UtilityRoutines import getEnumValue

from enum import Enum

enum OpticalDataModel(Int):
    Invalid = -1
    SpectralAverage = 0
    Spectral = 1
    BSDF = 2
    SpectralAndAngle = 3
    Num = 4

var opticalDataModelNames: StaticTuple[StringLiteral, 4] = (
    "SpectralAverage",
    "Spectral",
    "BSDF",
    "SpectralAndAngle",
)

var opticalDataModelNamesUC: StaticTuple[StringLiteral, 4] = (
    "SPECTRALAVERAGE",
    "SPECTRAL",
    "BSDF",
    "SPECTRALANDANGLE",
)

enum WindowsModel(Int):
    Invalid = -1
    BuiltIn = 0
    External = 1
    Num = 2

var windowsModelNamesUC: StaticTuple[StringLiteral, 2] = (
    "BUILTINWINDOWSMODEL",
    "EXTERNALWINDOWSMODEL",
)

struct CWindowModel:
    var m_Model: WindowsModel

    def __init__(inout self):
        self.m_Model = WindowsModel.BuiltIn

    @staticmethod
    def WindowModelFactory(state: EnergyPlusData, objectName: String) -> CWindowModel:
        var aModel = CWindowModel()  # (AUTO_OK)
        var numCurrModels = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, objectName)
        if numCurrModels > 0:
            var NumNums: Int
            var NumAlphas: Int
            var IOStat: Int
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state, objectName, 1, state.dataIPShortCut.cAlphaArgs, NumAlphas, state.dataIPShortCut.rNumericArgs, NumNums, IOStat,
            )
            aModel.m_Model = WindowsModel(getEnumValue(windowsModelNamesUC, state.dataIPShortCut.cAlphaArgs[0]))
        return aModel

    def getWindowsModel(self) -> WindowsModel:
        return self.m_Model

    def isExternalLibraryModel(self) -> Bool:
        return self.m_Model == WindowsModel.External

    def setExternalLibraryModel(inout self, model: WindowsModel):
        self.m_Model = model

enum WindowsOpticalModel(Int):
    Invalid = -1
    Simplified = 0
    BSDF = 1
    Num = 2

struct CWindowOpticalModel:
    var m_Model: WindowsOpticalModel

    def __init__(inout self):
        self.m_Model = WindowsOpticalModel.Simplified

    @staticmethod
    def WindowOpticalModelFactory(state: EnergyPlusData) -> CWindowOpticalModel:
        var aModel = CWindowOpticalModel()  # (AUTO_OK)
        var numCurrModels = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, "Construction:ComplexFenestrationState")
        if numCurrModels > 0:
            aModel.m_Model = WindowsOpticalModel.BSDF
        return aModel

    def getWindowsOpticalModel(self) -> WindowsOpticalModel:
        return self.m_Model

    def isSimplifiedModel(self) -> Bool:
        return self.m_Model == WindowsOpticalModel.Simplified