from EnergyPlus.Data.EnergyPlusData import EnergyPlusData
from EnergyPlus.DataEnvironment import DataEnvironment
from EnergyPlus.DataGlobals import DataGlobals
from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType, modelTypeNames
from EnergyPlus.InputProcessing.InputProcessor import InputProcessor
from EnergyPlus.UtilityRoutines import ShowWarningError, ShowContinueError, ShowSevereError, ShowFatalError, format
from EnergyPlus.WeatherManager import WeatherManager
from EnergyPlus.EnergyPlus import Constant, Real64
from memory import new
from math import ceil
from utils import StringRef

@value
struct SiteBuildingSurfaceGroundTemps(BaseGroundTempsModel):
    var timeOfSimInMonths: Int = 0
    var buildingSurfaceGroundTemps: StaticTuple[Real64, 12] = StaticTuple[Real64, 12](13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0, 13.0)

    @staticmethod
    def BuildingSurfaceGTMFactory(state: EnergyPlusData, objectName: StringRef) -> SiteBuildingSurfaceGroundTemps:
        let numMonths: Int = 12
        var errorsFound: Bool = False
        var thisModel = SiteBuildingSurfaceGroundTemps()
        let modelType: ModelType = ModelType.SiteBuildingSurface
        let cCurrentModuleObject: StringRef = modelTypeNames[modelType.__index__()]
        let currentModuleObject: String = String(cCurrentModuleObject)
        let inputProcessor = state.dataInputProcessing.inputProcessor
        let numCurrObjects: Int = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        thisModel.modelType = modelType
        thisModel.Name = objectName
        if numCurrObjects == 1:
            var genErrorMessage: Bool = False
            let groundTempsInstances = inputProcessor.epJSON[currentModuleObject]
            let groundTempsInstance = groundTempsInstances.begin()
            let groundTempsFields = groundTempsInstance.value()
            let groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance.key())
            let fieldNames: StaticTuple[StringRef, 12] = StaticTuple[StringRef, 12](
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
            )
            for i in range(numMonths):
                thisModel.buildingSurfaceGroundTemps[i] = inputProcessor.getRealFieldValue(groundTempsFields, groundTempsSchemaProps, String(fieldNames[i]))
                if thisModel.buildingSurfaceGroundTemps[i] < 15.0 or thisModel.buildingSurfaceGroundTemps[i] > 25.0:
                    genErrorMessage = True
            state.dataEnvrn.GroundTempInputs[DataEnvironment.GroundTempType.BuildingSurface.__index__()] = True
            if genErrorMessage:
                ShowWarningError(state, format("{}: Some values fall outside the range of 15-25C.", modelTypeNames[modelType.__index__()]))
                ShowContinueError(state, "These values may be inappropriate.  Please consult the Input Output Reference for more details.")
        elif numCurrObjects > 1:
            ShowSevereError(state, format("{}: Too many objects entered. Only one allowed.", modelTypeNames[modelType.__index__()]))
            errorsFound = True
        else:
            for i in range(12):
                thisModel.buildingSurfaceGroundTemps[i] = 18.0
        write_ground_temps(state.files.eio, "BuildingSurface", thisModel.buildingSurfaceGroundTemps)
        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel
        ShowFatalError(state, format("{}--Errors getting input for ground temperature model", modelTypeNames[modelType.__index__()]))
        return SiteBuildingSurfaceGroundTemps()

    def getGroundTemp(inout self, state: EnergyPlusData) -> Real64:
        return self.buildingSurfaceGroundTemps[self.timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, _depth: Real64, _seconds: Real64) -> Real64:
        let secPerMonth: Real64 = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12.0
        let month: Int = ceil(_seconds / secPerMonth)
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        return self.getGroundTemp(state)

    def getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, _depth: Real64, _month: Int) -> Real64:
        if _month >= 1 and _month <= 12:
            self.timeOfSimInMonths = _month
        else:
            self.timeOfSimInMonths = _month % 12
        return self.getGroundTemp(state)