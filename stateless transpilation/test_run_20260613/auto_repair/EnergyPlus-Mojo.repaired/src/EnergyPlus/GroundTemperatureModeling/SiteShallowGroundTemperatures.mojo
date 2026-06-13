from BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType, modelTypeNames
from DataEnvironment import GroundTempType
from DataGlobals import Constant, rSecsInDay
from InputProcessor import InputProcessor
from UtilityRoutines import ShowSevereError, ShowFatalError, format, write_ground_temps
from WeatherManager import WeatherManager

alias numMonths: Int = 12

struct SiteShallowGroundTemps(BaseGroundTempsModel):
    var timeOfSimInMonths: Int = 0
    var surfaceGroundTemps: StaticTuple[Float64, 12] = StaticTuple[Float64, 12](13.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    @staticmethod
    def ShallowGTMFactory(state: EnergyPlusData, objectName: String) -> Pointer[SiteShallowGroundTemps]:
        var errorsFound: Bool = false
        var thisModelPtr = Pointer[SiteShallowGroundTemps].alloc(1)
        thisModelPtr.store(SiteShallowGroundTemps(), 0)
        ref thisModel = thisModelPtr[0]
        let modelType = ModelType.SiteShallow
        let cCurrentModuleObject = modelTypeNames[Int(modelType)]
        let currentModuleObject = StringRef(cCurrentModuleObject)
        var inputProcessor = state.dataInputProcessing.inputProcessor
        let numCurrObjects = inputProcessor.getNumObjectsFound(state, cCurrentModuleObject)
        thisModel.modelType = modelType
        thisModel.Name = objectName
        if numCurrObjects == 1:
            let groundTempsInstances = inputProcessor.epJSON.at(currentModuleObject)
            let groundTempsInstance = groundTempsInstances.begin()
            let groundTempsFields = groundTempsInstance.value()
            let groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance.key())
            alias fieldNames = StaticTuple[StringLiteral, numMonths](
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
            )
            for i in range(numMonths):
                thisModel.surfaceGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, String(fieldNames[i]))
            state.dataEnvrn.GroundTempInputs[Int(GroundTempType.Shallow)] = true
        elif numCurrObjects > 1:
            ShowSevereError(state, format("{}: Too many objects entered. Only one allowed.", modelTypeNames[Int(modelType)]))
            errorsFound = true
        else:
            for i in range(numMonths):
                thisModel.surfaceGroundTemps[i] = 13.0
        write_ground_temps(state.files.eio, "Shallow", thisModel.surfaceGroundTemps)
        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.push_back(thisModelPtr)
            return thisModelPtr
        ShowFatalError(state, format("{}--Errors getting input for ground temperature model", modelTypeNames[Int(modelType)]))
        return Pointer[SiteShallowGroundTemps]()

    def getGroundTemp(state: EnergyPlusData) -> Float64:
        return surfaceGroundTemps[timeOfSimInMonths - 1]

    def getGroundTempAtTimeInSeconds(state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
        let secPerMonth = state.dataWeather.NumDaysInYear * Constant.rSecsInDay / 12
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