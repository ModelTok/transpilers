# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: struct with fields:
#   - dataInputProcessing: InputProcessingData
#   - dataEnvrn: EnvironmentData
#   - dataGrndTempModelMgr: GroundTempModelMgr
#   - files: FilesData
#   - dataWeather: WeatherData
# - InputProcessor: struct with methods:
#   - fn getNumObjectsFound(self, state: EnergyPlusData, object_name: StringRef) -> Int: ...
#   - fn epJSON(self) -> Pointer[DictType]: ...
#   - fn getObjectSchemaProps(self, state: EnergyPlusData, object_name: StringRef) -> Pointer[DictType]: ...
#   - fn markObjectAsUsed(self, object_name: StringRef, key: StringRef) -> None: ...
#   - fn getRealFieldValue(self, fields: Pointer[DictType], schema_props: Pointer[DictType], field_name: StringRef) -> Float64: ...
# - Constant: struct with rSecsInDay field (Float64)
# - BaseGroundTempsModel: struct base for inheritance
# - ShowSevereError(state: EnergyPlusData, message: StringRef) -> None
# - ShowFatalError(state: EnergyPlusData, message: StringRef) -> None
# - write_ground_temps(file: OpaquePointer, label: StringRef, temps: InlineArray) -> None

from math import ceil

struct DictType:
    pass

struct InputProcessor:
    fn getNumObjectsFound(self, state: EnergyPlusData, object_name: StringRef) -> Int:
        return 0
    fn epJSON(self) -> Pointer[DictType]:
        return Pointer[DictType]()
    fn getObjectSchemaProps(self, state: EnergyPlusData, object_name: StringRef) -> Pointer[DictType]:
        return Pointer[DictType]()
    fn markObjectAsUsed(self, object_name: StringRef, key: StringRef) -> None:
        pass
    fn getRealFieldValue(self, fields: Pointer[DictType], schema_props: Pointer[DictType], field_name: StringRef) -> Float64:
        return 0.0

struct InputProcessingData:
    var inputProcessor: InputProcessor

struct EnvironmentData:
    var GroundTempInputs: Pointer[Int]

struct GroundTempModelMgr:
    var groundTempModels: Pointer[Pointer[BaseGroundTempsModel]]

struct FilesData:
    var eio: OpaquePointer

struct WeatherData:
    var NumDaysInYear: Int

struct EnergyPlusData:
    var dataInputProcessing: InputProcessingData
    var dataEnvrn: EnvironmentData
    var dataGrndTempModelMgr: GroundTempModelMgr
    var files: FilesData
    var dataWeather: WeatherData

struct Constant:
    var rSecsInDay: Float64 = 86400.0

fn ShowSevereError(state: EnergyPlusData, message: StringRef) -> None:
    pass

fn ShowFatalError(state: EnergyPlusData, message: StringRef) -> None:
    pass

fn write_ground_temps(file: OpaquePointer, label: StringRef, temps: Pointer[Float64]) -> None:
    pass

struct BaseGroundTempsModel:
    var modelType: OpaquePointer
    var Name: String

struct SiteShallowGroundTemps(BaseGroundTempsModel):
    var timeOfSimInMonths: Int
    var surfaceGroundTemps: InlineArray[Float64, 12]

    fn __init__(inout self):
        self.modelType = OpaquePointer()
        self.Name = String()
        self.timeOfSimInMonths = 0
        self.surfaceGroundTemps = InlineArray[Float64, 12](fill=0.0)
        self.surfaceGroundTemps[0] = 13.0

    @staticmethod
    fn ShallowGTMFactory(state: EnergyPlusData, objectName: String) -> Pointer[SiteShallowGroundTemps]:
        let numMonths = 12
        var errorsFound = False

        var thisModel = SiteShallowGroundTemps()

        let modelType = "SiteShallow"
        let currentModuleObject = modelType
        let inputProcessor = state.dataInputProcessing.inputProcessor
        let numCurrObjects = inputProcessor.getNumObjectsFound(state, currentModuleObject)

        thisModel.modelType = OpaquePointer()
        thisModel.Name = objectName

        if numCurrObjects == 1:
            let groundTempsInstances = inputProcessor.epJSON()
            let groundTempsFields = Pointer[DictType]()
            let groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, "")

            let fieldNames = InlineArray[StringRef, 12](
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
                    groundTempsFields, groundTempsSchemaProps, fieldNames[i]
                )

            state.dataEnvrn.GroundTempInputs[0] = 1

        elif numCurrObjects > 1:
            ShowSevereError(state, StringRef(modelType + ": Too many objects entered. Only one allowed."))
            errorsFound = True
        else:
            for i in range(numMonths):
                thisModel.surfaceGroundTemps[i] = 13.0

        write_ground_temps(state.files.eio, "Shallow", Pointer[Float64](thisModel.surfaceGroundTemps.data()))

        if not errorsFound:
            let model_ptr = Pointer[SiteShallowGroundTemps].alloc(1)
            model_ptr[] = thisModel
            return model_ptr

        ShowFatalError(state, StringRef(modelType + "--Errors getting input for ground temperature model"))
        return Pointer[SiteShallowGroundTemps]()

    fn getGroundTemp(self, state: EnergyPlusData) -> Float64:
        return self.surfaceGroundTemps[self.timeOfSimInMonths - 1]

    fn getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, depth: Float64, timeInSecondsOfSim: Float64) -> Float64:
        let secPerMonth = Float64(state.dataWeather.NumDaysInYear) * 86400.0 / 12.0

        let month = Int(ceil(timeInSecondsOfSim / secPerMonth))

        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)

    fn getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, depth: Float64, month: Int) -> Float64:
        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)
