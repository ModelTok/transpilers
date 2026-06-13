# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with attributes:
#   - dataInputProcessing.inputProcessor: InputProcessor with methods getNumObjectsFound(state, str)->int, epJSON property, getObjectSchemaProps(state, str)->dict, markObjectAsUsed(str, str), getRealFieldValue(dict, dict, str)->float
#   - dataEnvrn.GroundTempInputs: list indexed by GroundTempType.Shallow (0)
#   - dataGrndTempModelMgr.groundTempModels: list to append model instances
#   - files.eio: output file handle
#   - dataWeather.NumDaysInYear: int
# - Constant.rSecsInDay: float (seconds per day constant)
# - BaseGroundTempsModel: base class from GroundTemperatureModeling.BaseGroundTemperatureModel
# - ShowSevereError(state, message: str): error reporting function
# - ShowFatalError(state, message: str): fatal error function
# - write_ground_temps(file, label: str, temps: list): output writer function

import math
from typing import Any, Protocol, Optional

class InputProcessor(Protocol):
    @property
    def epJSON(self) -> dict: ...
    def getNumObjectsFound(self, state: Any, object_name: str) -> int: ...
    def getObjectSchemaProps(self, state: Any, object_name: str) -> dict: ...
    def markObjectAsUsed(self, object_name: str, key: str) -> None: ...
    def getRealFieldValue(self, fields: dict, schema_props: dict, field_name: str) -> float: ...

class InputProcessingData(Protocol):
    inputProcessor: InputProcessor

class EnvironmentData(Protocol):
    GroundTempInputs: list

class GroundTempModelMgr(Protocol):
    groundTempModels: list

class FilesData(Protocol):
    eio: Any

class WeatherData(Protocol):
    NumDaysInYear: int

class EnergyPlusData(Protocol):
    dataInputProcessing: InputProcessingData
    dataEnvrn: EnvironmentData
    dataGrndTempModelMgr: GroundTempModelMgr
    files: FilesData
    dataWeather: WeatherData

class Constant:
    rSecsInDay: float = 86400.0

def ShowSevereError(state: EnergyPlusData, message: str) -> None:
    pass

def ShowFatalError(state: EnergyPlusData, message: str) -> None:
    pass

def write_ground_temps(file: Any, label: str, temps: list) -> None:
    pass

class BaseGroundTempsModel:
    def __init__(self):
        self.modelType = None
        self.Name = ""

class SiteShallowGroundTemps(BaseGroundTempsModel):
    def __init__(self):
        super().__init__()
        self.timeOfSimInMonths = 0
        self.surfaceGroundTemps = [13.0] + [0.0] * 11

    @staticmethod
    def ShallowGTMFactory(state: EnergyPlusData, objectName: str) -> Optional['SiteShallowGroundTemps']:
        numMonths = 12
        errorsFound = False

        thisModel = SiteShallowGroundTemps()

        modelType = "SiteShallow"
        currentModuleObject = modelType
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
                "january_surface_ground_temperature",
                "february_surface_ground_temperature",
                "march_surface_ground_temperature",
                "april_surface_ground_temperature",
                "may_surface_ground_temperature",
                "june_surface_ground_temperature",
                "july_surface_ground_temperature",
                "august_surface_ground_temperature",
                "september_surface_ground_temperature",
                "october_surface_ground_temperature",
                "november_surface_ground_temperature",
                "december_surface_ground_temperature"
            ]

            for i in range(numMonths):
                thisModel.surfaceGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, fieldNames[i]
                )

            state.dataEnvrn.GroundTempInputs[0] = True

        elif numCurrObjects > 1:
            ShowSevereError(state, f"{modelType}: Too many objects entered. Only one allowed.")
            errorsFound = True
        else:
            thisModel.surfaceGroundTemps = [13.0] * numMonths

        write_ground_temps(state.files.eio, "Shallow", thisModel.surfaceGroundTemps)

        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel

        ShowFatalError(state, f"{modelType}--Errors getting input for ground temperature model")
        return None

    def getGroundTemp(self, state: EnergyPlusData) -> float:
        return self.surfaceGroundTemps[self.timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, depth: float, timeInSecondsOfSim: float) -> float:
        secPerMonth = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12

        month = math.ceil(timeInSecondsOfSim / secPerMonth)

        if 1 <= month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)

    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, depth: float, month: int) -> float:
        if 1 <= month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)
