from ......Data.EnergyPlusData import EnergyPlusData
from ......DataEnvironment import DataEnvironment
from ......DataGlobals import DataGlobals, Constant
from ......InputProcessing.InputProcessor import InputProcessor
from ......UtilityRoutines import ShowSevereError, ShowFatalError, write_ground_temps
from ......WeatherManager import WeatherManager
from ..BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType, modelTypeNames

struct SiteFCFactorMethodGroundTemps : BaseGroundTempsModel:
    var timeOfSimInMonths: Int = 0
    var fcFactorGroundTemps: Array[Float64, 12] = Array[Float64, 12](13.0)  # all elements initialized to 13.0

    @staticmethod
    def FCFactorGTMFactory(state: EnergyPlusData, objectName: String) -> Self:
        const numMonths: Int = 12
        var found: Bool = False
        var thisModel = SiteFCFactorMethodGroundTemps()
        var modelType = ModelType.SiteFCFactorMethod
        var cCurrentModuleObject: String = modelTypeNames[Int(modelType)]  # TODO: ensure modelTypeNames is accessible
        var currentModuleObject = cCurrentModuleObject  # String copy
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var numCurrObjects = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        thisModel.modelType = modelType
        thisModel.Name = objectName
        if numCurrObjects == 1:
            var groundTempsInstances = inputProcessor.epJSON.at(currentModuleObject)
            var groundTempsInstance = groundTempsInstances.begin()
            var groundTempsFields = groundTempsInstance.value()
            var groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance.key())
            const fieldNames: Array[String, numMonths] = [
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
                "december_ground_temperature"]
            for i in range(numMonths):
                thisModel.fcFactorGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, fieldNames[i])
            state.dataEnvrn.GroundTempInputs[Int(DataEnvironment.GroundTempType.FCFactorMethod)] = True
            found = True
        elif numCurrObjects > 1:
            ShowSevereError(state, EnergyPlus.format(
                "{}: Too many objects entered. Only one allowed.", modelTypeNames[Int(modelType)]))
        elif state.dataWeather.wthFCGroundTemps:
            for i in range(1, 13):  # 1-indexed loop in C++, converts to 0-indexed array access
                thisModel.fcFactorGroundTemps[i - 1] = state.dataWeather.GroundTempsFCFromEPWHeader(i)
            state.dataEnvrn.GroundTempInputs[Int(DataEnvironment.GroundTempType.FCFactorMethod)] = True
            found = True
        else:
            thisModel.fcFactorGroundTemps = Array[Float64, 12](0.0)
            found = True
        if state.dataEnvrn.GroundTempInputs[Int(DataEnvironment.GroundTempType.FCFactorMethod)]:
            write_ground_temps(state.files.eio, "FCfactorMethod", thisModel.fcFactorGroundTemps)
        if found:
            state.dataGrndTempModelMgr.groundTempModels.push_back(thisModel)
            return thisModel
        ShowFatalError(state, EnergyPlus.format(
            "{}--Errors getting input for ground temperature model", modelTypeNames[Int(modelType)]))
        return Self  # unreachable but needed

    def getGroundTemp(state: EnergyPlusData) -> Float64:
        return fcFactorGroundTemps[timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
        var secPerMonth: Float64 = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12.0
        var month: Int = ceil(_seconds / secPerMonth)
        if month >= 1 and month <= 12:
            timeOfSimInMonths = month
        else:
            timeOfSimInMonths = month % 12
        return getGroundTemp(state)

    def getGroundTempAtTimeInMonths(state: EnergyPlusData, _depth: Float64, _month: Int) -> Float64:
        if _month >= 1 and _month <= 12:
            timeOfSimInMonths = _month
        else:
            timeOfSimInMonths = _month % 12
        return getGroundTemp(state)