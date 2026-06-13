from collections import List
from enum import Enum
import math

# EXTERNAL DEPS (to wire in glue):
# - BaseGroundTempsModel: base struct (from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel)
# - ModelType: enum for model types (from EnergyPlus.GroundTemperatureModeling.BaseGroundTemperatureModel)
# - GroundTempType: enum for ground temp types (from EnergyPlus.DataEnvironment)
# - modelTypeNames: list of model type name strings (from EnergyPlus.GroundTemperatureModeling)
# - EnergyPlusData: state struct (from EnergyPlus.Data.EnergyPlusData)
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

struct ModelType:
    alias SiteBuildingSurface = 0

struct GroundTempType:
    alias BuildingSurface = 0

struct Constant:
    alias rSecsInDay = 86400.0

@always_inline
fn month_field_names() -> StaticTuple[12, StringLiteral]:
    return (
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

fn ShowWarningError(state: EnergyPlusData, message: String) -> None:
    """Stub for warning error function"""
    pass

fn ShowContinueError(state: EnergyPlusData, message: String) -> None:
    """Stub for continue error function"""
    pass

fn ShowSevereError(state: EnergyPlusData, message: String) -> None:
    """Stub for severe error function"""
    pass

fn ShowFatalError(state: EnergyPlusData, message: String) -> None:
    """Stub for fatal error function"""
    pass

fn write_ground_temps(eio_file: AnyType, surface_type: String, temperatures: List[Float64]) -> None:
    """Stub for ground temperature output function"""
    pass

struct SiteBuildingSurfaceGroundTemps:
    """Derived struct for Site:GroundTemperature:BuildingSurface"""
    
    var timeOfSimInMonths: Int32
    var buildingSurfaceGroundTemps: List[Float64]
    var modelType: AnyType
    var Name: String

    fn __init__(inout self) -> None:
        self.timeOfSimInMonths = 0
        self.buildingSurfaceGroundTemps = List[Float64](capacity=12)
        self.buildingSurfaceGroundTemps.append(13.0)
        for _ in range(11):
            self.buildingSurfaceGroundTemps.append(0.0)
        self.modelType = AnyType()
        self.Name = String()

    @staticmethod
    fn BuildingSurfaceGTMFactory(inout state: EnergyPlusData, objectName: String) -> AnyType:
        """Factory method to create Site:GroundTemperature:BuildingSurface model from input"""
        let numMonths: Int32 = 12
        var errorsFound: Bool = False

        var thisModel = SiteBuildingSurfaceGroundTemps()
        let modelType: Int32 = ModelType.SiteBuildingSurface

        let cCurrentModuleObject = "Site:GroundTemperature:BuildingSurface"
        let currentModuleObject = cCurrentModuleObject
        let inputProcessor = state.dataInputProcessing.inputProcessor
        let numCurrObjects = inputProcessor.getNumObjectsFound(state, currentModuleObject)

        thisModel.modelType = modelType
        thisModel.Name = objectName

        if numCurrObjects == 1:
            var genErrorMessage: Bool = False
            let groundTempsInstances = inputProcessor.epJSON[currentModuleObject]
            let groundTempsInstance = groundTempsInstances.begin()
            let groundTempsFields = groundTempsInstance.value()
            let groundTempsSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            inputProcessor.markObjectAsUsed(currentModuleObject, groundTempsInstance.key())
            
            let fieldNames = month_field_names()

            for i in range(numMonths):
                thisModel.buildingSurfaceGroundTemps[i] = inputProcessor.getRealFieldValue(
                    groundTempsFields, groundTempsSchemaProps, String(fieldNames[i])
                )
                if thisModel.buildingSurfaceGroundTemps[i] < 15.0 or thisModel.buildingSurfaceGroundTemps[i] > 25.0:
                    genErrorMessage = True

            state.dataEnvrn.GroundTempInputs[GroundTempType.BuildingSurface] = True

            if genErrorMessage:
                ShowWarningError(state, String("Site:GroundTemperature:BuildingSurface: Some values fall outside the range of 15-25C."))
                ShowContinueError(state, String("These values may be inappropriate.  Please consult the Input Output Reference for more details."))

        elif numCurrObjects > 1:
            ShowSevereError(state, String("Site:GroundTemperature:BuildingSurface: Too many objects entered. Only one allowed."))
            errorsFound = True
        else:
            for i in range(12):
                thisModel.buildingSurfaceGroundTemps[i] = 18.0

        write_ground_temps(state.files.eio, String("BuildingSurface"), thisModel.buildingSurfaceGroundTemps)

        if not errorsFound:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel

        ShowFatalError(state, String("Site:GroundTemperature:BuildingSurface--Errors getting input for ground temperature model"))
        return AnyType()

    fn getGroundTemp(self, inout state: EnergyPlusData) -> Float64:
        """Returns the ground temperature for Site:GroundTemperature:BuildingSurface"""
        return self.buildingSurfaceGroundTemps[self.timeOfSimInMonths - 1]

    fn getGroundTempAtTimeInSeconds(inout self, inout state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
        """Returns the ground temperature when input time is in seconds"""
        let secPerMonth: Float64 = (state.dataWeather.NumDaysInYear * Constant.rSecsInDay) / 12.0

        let month: Int32 = Int32(math.ceil(_seconds / secPerMonth))

        if month >= 1 and month <= 12:
            self.timeOfSimInMonths = month
        else:
            self.timeOfSimInMonths = month % 12

        return self.getGroundTemp(state)

    fn getGroundTempAtTimeInMonths(inout self, inout state: EnergyPlusData, _depth: Float64, _month: Int32) -> Float64:
        """Returns the ground temperature when input time is in months"""
        if _month >= 1 and _month <= 12:
            self.timeOfSimInMonths = _month
        else:
            self.timeOfSimInMonths = _month % 12

        return self.getGroundTemp(state)
