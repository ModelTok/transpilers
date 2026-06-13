# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData (state): main state object with sub-containers
#   source: EnergyPlus/Data/EnergyPlusData.hh
# - state.dataWeather: contains NumDaysInYear, GroundTempsFCFromEPWHeader, wthFCGroundTemps
#   source: EnergyPlus/DataEnvironment.hh
# - state.dataEnvrn: contains GroundTempInputs array indexed by GroundTempType
#   source: EnergyPlus/DataEnvironment.hh
# - state.dataInputProcessing.inputProcessor: JSON input processor interface
#   source: EnergyPlus/InputProcessing/InputProcessor.hh
# - state.dataGrndTempModelMgr.groundTempModels: list of temperature models
#   source: GroundTemperatureModeling module
# - state.files.eio: EIO output file handle
#   source: EnergyPlus/FileSystem.hh
# - Constant.rSecsInDay: seconds per day constant
#   source: EnergyPlus/DataGlobals.hh
# - ShowSevereError, ShowFatalError: error reporting functions
#   source: EnergyPlus/UtilityRoutines.hh
# - write_ground_temps: ground temperature output writer
#   source: GroundTemperatureModeling module

from typing import Protocol, Any, Optional, List, Dict
from dataclasses import dataclass, field
import math


class DataWeather(Protocol):
    NumDaysInYear: int
    GroundTempsFCFromEPWHeader: Dict[int, float]
    wthFCGroundTemps: bool


class DataEnvironment(Protocol):
    GroundTempInputs: Dict[int, bool]


class InputProcessor(Protocol):
    epJSON: Dict[str, Any]
    
    def getNumObjectsFound(self, state: Any, objectType: str) -> int: ...
    def getObjectSchemaProps(self, state: Any, objectType: str) -> Any: ...
    def getRealFieldValue(self, fields: Any, schemaProps: Any, fieldName: str) -> float: ...
    def markObjectAsUsed(self, objectType: str, objectName: str) -> None: ...


class DataInputProcessing(Protocol):
    inputProcessor: InputProcessor


class DataGrndTempModelMgr(Protocol):
    groundTempModels: List[Any]


class Files(Protocol):
    eio: Any


class EnergyPlusData(Protocol):
    dataWeather: DataWeather
    dataEnvrn: DataEnvironment
    dataInputProcessing: DataInputProcessing
    dataGrndTempModelMgr: DataGrndTempModelMgr
    files: Files


@dataclass
class SiteFCFactorMethodGroundTemps:
    modelType: Any = None
    Name: str = ""
    timeOfSimInMonths: int = 0
    fcFactorGroundTemps: List[float] = field(default_factory=lambda: [13.0] + [0.0] * 11)
    
    @staticmethod
    def FCFactorGTMFactory(state: EnergyPlusData, objectName: str) -> Optional['SiteFCFactorMethodGroundTemps']:
        numMonths = 12
        found = False
        
        thisModel = SiteFCFactorMethodGroundTemps()
        
        modelType = "SiteFCFactorMethod"
        
        cCurrentModuleObject = modelType
        currentModuleObject = cCurrentModuleObject
        inputProcessor = state.dataInputProcessing.inputProcessor
        numCurrObjects = inputProcessor.getNumObjectsFound(state, currentModuleObject)
        
        thisModel.modelType = modelType
        thisModel.Name = objectName
        
        if numCurrObjects == 1:
            groundTempsInstances = inputProcessor.epJSON[currentModuleObject]
            groundTempsInstance = next(iter(groundTempsInstances.items()))
            groundTempsFields = groundTempsInstance[1]
            groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance[0])
            
            fieldNames = [
                "january_ground_temperature",
                "february_ground_temperature",
                "march_ground_temperature",
                "april_ground_temperature",
                "may_ground_temperature",
                "june_ground_temperature",
                "july_ground_temperature",
                "august_ground_temperature",
                "september_ground_temperature",
                "october_ground_temperature",
                "november_ground_temperature",
                "december_ground_temperature"
            ]
            
            for i in range(numMonths):
                thisModel.fcFactorGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, fieldNames[i]
                )
            
            state.dataEnvrn.GroundTempInputs[0] = True
            found = True
        
        elif numCurrObjects > 1:
            ShowSevereError(state, f"{cCurrentModuleObject}: Too many objects entered. Only one allowed.")
        
        elif state.dataWeather.wthFCGroundTemps:
            for i in range(1, 13):
                thisModel.fcFactorGroundTemps[i - 1] = state.dataWeather.GroundTempsFCFromEPWHeader[i]
            
            state.dataEnvrn.GroundTempInputs[0] = True
            found = True
        
        else:
            thisModel.fcFactorGroundTemps = [0.0] * 12
            found = True
        
        if state.dataEnvrn.GroundTempInputs[0]:
            write_ground_temps(state.files.eio, "FCfactorMethod", thisModel.fcFactorGroundTemps)
        
        if found:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel
        
        ShowFatalError(state, f"{cCurrentModuleObject}--Errors getting input for ground temperature model")
        return None
    
    def getGroundTemp(self, state: EnergyPlusData) -> float:
        return self.fcFactorGroundTemps[self.timeOfSimInMonths - 1]
    
    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, depth: float, seconds: float) -> float:
        secPerMonth = state.dataWeather.NumDaysInYear * 86400.0 / 12
        
        month = math.ceil(seconds / secPerMonth)
        
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        
        return self.getGroundTemp(state)
    
    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, depth: float, month: int) -> float:
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        
        return self.getGroundTemp(state)


def ShowSevereError(state: EnergyPlusData, message: str) -> None:
    pass


def ShowFatalError(state: EnergyPlusData, message: str) -> None:
    pass


def write_ground_temps(eio_file: Any, method_name: str, temps: List[float]) -> None:
    pass
