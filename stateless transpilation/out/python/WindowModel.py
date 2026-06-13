# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state container with dataInputProcessing.inputProcessor and dataIPShortCut

from enum import IntEnum
from typing import Protocol, Any


class OpticalDataModel(IntEnum):
    Invalid = -1
    SpectralAverage = 0
    Spectral = 1
    BSDF = 2
    SpectralAndAngle = 3
    Num = 4


class WindowsModel(IntEnum):
    Invalid = -1
    BuiltIn = 0
    External = 1
    Num = 2


class WindowsOpticalModel(IntEnum):
    Invalid = -1
    Simplified = 0
    BSDF = 1
    Num = 2


OPTICAL_DATA_MODEL_NAMES = [
    "SpectralAverage",
    "Spectral",
    "BSDF",
    "SpectralAndAngle"
]

OPTICAL_DATA_MODEL_NAMES_UC = [
    "SPECTRALAVERAGE",
    "SPECTRAL",
    "BSDF",
    "SPECTRALANDANGLE"
]

WINDOWS_MODEL_NAMES_UC = [
    "BUILTINWINDOWSMODEL",
    "EXTERNALWINDOWSMODEL"
]


class InputProcessor(Protocol):
    def getNumObjectsFound(self, state: Any, object_name: str) -> int: ...
    
    def getObjectItem(
        self,
        state: Any,
        object_name: str,
        item_index: int,
        alpha_args: list,
        num_alphas_ref: Any,
        numeric_args: list,
        num_nums_ref: Any,
        io_stat_ref: Any
    ) -> None: ...


class DataIPShortCut(Protocol):
    cAlphaArgs: list[str]
    rNumericArgs: list[float]


class DataInputProcessing(Protocol):
    inputProcessor: InputProcessor


class EnergyPlusData(Protocol):
    dataInputProcessing: DataInputProcessing
    dataIPShortCut: DataIPShortCut


def get_enum_value(names: list[str], value: str) -> int:
    try:
        return names.index(value)
    except ValueError:
        return -1


class CWindowModel:
    def __init__(self) -> None:
        self.m_Model = WindowsModel.BuiltIn
    
    @staticmethod
    def WindowModelFactory(state: EnergyPlusData, object_name: str) -> "CWindowModel":
        aModel = CWindowModel()
        num_curr_models = state.dataInputProcessing.inputProcessor.getNumObjectsFound(state, object_name)
        
        if num_curr_models > 0:
            num_nums = 0
            num_alphas = 0
            io_stat = 0
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                object_name,
                1,
                state.dataIPShortCut.cAlphaArgs,
                num_alphas,
                state.dataIPShortCut.rNumericArgs,
                num_nums,
                io_stat
            )
            aModel.m_Model = WindowsModel(get_enum_value(WINDOWS_MODEL_NAMES_UC, state.dataIPShortCut.cAlphaArgs[0]))
        
        return aModel
    
    def getWindowsModel(self) -> WindowsModel:
        return self.m_Model
    
    def isExternalLibraryModel(self) -> bool:
        return self.m_Model == WindowsModel.External
    
    def setExternalLibraryModel(self, model: WindowsModel) -> None:
        self.m_Model = model


class CWindowOpticalModel:
    def __init__(self) -> None:
        self.m_Model = WindowsOpticalModel.Simplified
    
    @staticmethod
    def WindowOpticalModelFactory(state: EnergyPlusData) -> "CWindowOpticalModel":
        aModel = CWindowOpticalModel()
        num_curr_models = state.dataInputProcessing.inputProcessor.getNumObjectsFound(
            state,
            "Construction:ComplexFenestrationState"
        )
        
        if num_curr_models > 0:
            aModel.m_Model = WindowsOpticalModel.BSDF
        
        return aModel
    
    def getWindowsOpticalModel(self) -> WindowsOpticalModel:
        return self.m_Model
    
    def isSimplifiedModel(self) -> bool:
        return self.m_Model == WindowsOpticalModel.Simplified
