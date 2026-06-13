from BaseGroundTemperatureModel import BaseGroundTempsModel
from ...Data.EnergyPlusData import EnergyPlusData
from ...DataEnvironment import DataEnvironment, GroundTempType
from ...DataGlobals import DataGlobals
from ...InputProcessing.InputProcessor import InputProcessor
from ...UtilityRoutines import ShowSevereError, ShowFatalError, write_ground_temps
from ...WeatherManager import WeatherManager
from ...Constant import Constant
from stdlib.array import StaticArray
from math import ceil

alias numMonths: Int = 12

struct SiteDeepGroundTemps(BaseGroundTempsModel):
    var timeOfSimInMonths: Int = 12
    var deepGroundTemps: StaticArray[Float64, numMonths] = StaticArray[Float64, numMonths](0.0)

    def __init__(inout self):
        self.deepGroundTemps[0] = 13.0

    @staticmethod
    def DeepGTMFactory(state: EnergyPlusData, objectName: String) -> Pointer[SiteDeepGroundTemps]:
        var errorsFound: Bool = False
        var thisModel = Pointer[SiteDeepGroundTemps].alloc()
        var modelType: ModelType = ModelType.SiteDeep
        var cCurrentModuleObject: String = GroundTemp.modelTypeNames[int(modelType)]
        var currentModuleObject: String = cCurrentModuleObject
        var inputProcessor: InputProcessor = state.dataInputProcessing.inputProcessor
        var numCurrObjects: Int = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        thisModel.modelType = modelType
        thisModel.Name = objectName
        if numCurrObjects == 1:
            var groundTempsInstances = inputProcessor.epJSON[currentModuleObject]
            var groundTempsInstance = groundTempsInstances.items()[0]
            var groundTempsFields = groundTempsInstance.value()
            var groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance.key())
            alias fieldNames: StaticArray[String, numMonths] = StaticArray[String, numMonths](
                "january_deep_ground_temperature",
                "february_deep_ground_temperature",
                "march_deep_ground_temperature",
                "april_deep_ground_temperature",
                "may_deep_ground_temperature",
                "june_deep_ground_temperature",
                "july_deep_ground_temperature",
                "august_deep_ground_temperature",
                "september_deep_ground_temperature",
                "october_deep_ground_temperature",
                "november_deep_ground_temperature",
                "december_deep_ground_temperature"
            )
            for i in range(numMonths):
                thisModel.deepGroundTemps[i] = inputProcessor.getRealFieldValue(groundTempsFields, groundTempsSchemaProps, String(fieldNames[i]))
            state.dataEnvrn.GroundTempInputs[int(GroundTempType.Deep)] = True
        elif numCurrObjects > 1:
            ShowSevereError(state, String.format("{}: Too many objects entered. Only one allowed.", GroundTemp.modelTypeNames[int(modelType)]))
            errorsFound = True
        else:
            for i in range(numMonths):
                thisModel.deepGroundTemps[i] = 16.0
        write_ground_temps(state.files.eio, "Deep", thisModel.deepGroundTemps)
        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel
        ShowFatalError(state, String.format("{}--Errors getting input for ground temperature model", GroundTemp.modelTypeNames[int(modelType)]))
        return Pointer[SiteDeepGroundTemps]()

    def getGroundTemp(self, state: EnergyPlusData) -> Float64:
        return self.deepGroundTemps[self.timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
        var secPerMonth: Float64 = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12.0
        var month: Int = int(ceil(_seconds / secPerMonth))
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12
        return self.getGroundTemp(state)

    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, _depth: Float64, _month: Int) -> Float64:
        if _month >= 1 and _month <= 12:
            self.timeOfSimInMonths = _month
        else:
            self.timeOfSimInMonths = _month % 12
        return self.getGroundTemp(state)