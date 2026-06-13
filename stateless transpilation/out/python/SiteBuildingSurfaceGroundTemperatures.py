from typing import Protocol, Optional, List, Any
from dataclasses import dataclass
from enum import Enum
import math

# EXTERNAL DEPS (to wire in glue):
# - BaseGroundTempsModel: base class (from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel)
# - ModelType: enum for model types (from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel)
# - GroundTempType: enum for ground temp types (from EnergyPlus.DataEnvironment)
# - modelTypeNames: list of model type name strings (from EnergyPlus.GroundTemperatureModeling)
# - EnergyPlusData: state object (from EnergyPlus.Data.EnergyPlusData)
# - Constant.rSecsInDay: seconds per day constant (from EnergyPlus.DataGlobals)
# - ShowWarningError: warning logging function (from EnergyPlus.UtilityRoutines)
# - ShowContinueError: logging function (from EnergyPlus.UtilityRoutines)
# - ShowSevereError: error logging function (from EnergyPlus.UtilityRoutines)
# - ShowFatalError: fatal error logging function (from EnergyPlus.UtilityRoutines)
# - write_ground_temps: output file writing function (from EnergyPlus.GroundTemperatureModeling)
# - InputProcessor interface: getNumObjectsFound, markObjectAsUsed, getObjectSchemaProps, getRealFieldValue
# - state.dataInputProcessing.inputProcessor: input processor instance
# - state.dataWeather.NumDaysInYear: days in year for current simulation
# - state.dataEnvrn.GroundTempInputs: ground temperature input flags
# - state.dataGrndTempModelMgr.groundTempModels: list of ground temperature models
# - state.files.eio: EIO output file handle

class BaseGroundTempsModel(Protocol):
    """Protocol for base ground temperature model"""
    modelType: Any
    Name: str

class ModelType(Enum):
    """Model type enumeration stub"""
    SiteBuildingSurface = 0

class GroundTempType(Enum):
    """Ground temperature type enumeration stub"""
    BuildingSurface = 0

@dataclass
class EnergyPlusData:
    """State object containing energy plus runtime data"""
    dataInputProcessing: Any = None
    dataWeather: Any = None
    dataEnvrn: Any = None
    dataGrndTempModelMgr: Any = None
    files: Any = None

class Constant:
    """Global constants stub"""
    rSecsInDay: float = 86400.0

def ShowWarningError(state: EnergyPlusData, message: str) -> None:
    """Stub for warning error function"""
    pass

def ShowContinueError(state: EnergyPlusData, message: str) -> None:
    """Stub for continue error function"""
    pass

def ShowSevereError(state: EnergyPlusData, message: str) -> None:
    """Stub for severe error function"""
    pass

def ShowFatalError(state: EnergyPlusData, message: str) -> None:
    """Stub for fatal error function"""
    pass

def write_ground_temps(eio_file: Any, surface_type: str, temperatures: List[float]) -> None:
    """Stub for ground temperature output function"""
    pass

class SiteBuildingSurfaceGroundTemps(BaseGroundTempsModel):
    """Derived class for Site:GroundTemperature:BuildingSurface"""
    
    def __init__(self) -> None:
        self.timeOfSimInMonths: int = 0
        self.buildingSurfaceGroundTemps: List[float] = [13.0] + [0.0] * 11
        self.modelType: Any = None
        self.Name: str = ""

    @staticmethod
    def BuildingSurfaceGTMFactory(state: EnergyPlusData, objectName: str) -> Optional['SiteBuildingSurfaceGroundTemps']:
        """Factory method to create Site:GroundTemperature:BuildingSurface model from input"""
        numMonths = 12
        errorsFound = False

        thisModel = SiteBuildingSurfaceGroundTemps()
        modelType = ModelType.SiteBuildingSurface

        cCurrentModuleObject = "Site:GroundTemperature:BuildingSurface"
        currentModuleObject = cCurrentModuleObject
        inputProcessor = state.dataInputProcessing.inputProcessor
        numCurrObjects = inputProcessor.getNumObjectsFound(state, currentModuleObject)

        thisModel.modelType = modelType
        thisModel.Name = objectName

        if numCurrObjects == 1:
            genErrorMessage = False
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
                thisModel.buildingSurfaceGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, fieldNames[i]
                )
                if thisModel.buildingSurfaceGroundTemps[i] < 15.0 or thisModel.buildingSurfaceGroundTemps[i] > 25.0:
                    genErrorMessage = True

            state.dataEnvrn.GroundTempInputs[GroundTempType.BuildingSurface.value] = True

            if genErrorMessage:
                ShowWarningError(state, "Site:GroundTemperature:BuildingSurface: Some values fall outside the range of 15-25C.")
                ShowContinueError(state, "These values may be inappropriate.  Please consult the Input Output Reference for more details.")

        elif numCurrObjects > 1:
            ShowSevereError(state, "Site:GroundTemperature:BuildingSurface: Too many objects entered. Only one allowed.")
            errorsFound = True
        else:
            thisModel.buildingSurfaceGroundTemps = [18.0] * 12

        write_ground_temps(state.files.eio, "BuildingSurface", thisModel.buildingSurfaceGroundTemps)

        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel

        ShowFatalError(state, "Site:GroundTemperature:BuildingSurface--Errors getting input for ground temperature model")
        return None

    def getGroundTemp(self, state: EnergyPlusData) -> float:
        """Returns the ground temperature for Site:GroundTemperature:BuildingSurface"""
        return self.buildingSurfaceGroundTemps[self.timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, _depth: float, _seconds: float) -> float:
        """Returns the ground temperature when input time is in seconds"""
        secPerMonth = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12.0

        month = math.ceil(_seconds / secPerMonth)

        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)

    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, _depth: float, _month: int) -> float:
        """Returns the ground temperature when input time is in months"""
        if _month >= 1 and _month <= 12:
            self.timeOfSimInMonths = _month
        else:
            self.timeOfSimInMonths = _month % 12

        return self.getGroundTemp(state)
