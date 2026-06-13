# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state struct with attributes:
#     - dataWeather.NumDaysInYear: Int, number of days in simulation year
#     - dataGrndTempModelMgr.groundTempModels: DynamicVector to append models to
#     - dataInputProcessing.inputProcessor: input processing instance
#     - Constant.Pi: Float64, π constant
#     - Constant.rSecsInDay: Float64, seconds per day (86400.0)
#     - modelTypeNames: dict mapping model type to string name
# - InputProcessor: struct with methods:
#     - epJSON: dict of JSON objects
#     - getRealFieldValue(fields, schema, key): Float64
#     - getObjectSchemaProps(state, objectName): dict
#     - markObjectAsUsed(objectName, instanceKey): None

from math import sqrt, exp, cos, remainder


struct XingGroundTempsModel:
    var depth: Float64
    var groundThermalDiffusivity: Float64
    var simTimeInDays: Float64
    var aveGroundTemp: Float64
    var surfTempAmplitude_1: Float64
    var phaseShift_1: Float64
    var surfTempAmplitude_2: Float64
    var phaseShift_2: Float64
    var modelType: String
    var Name: String

    fn __init__(inout self):
        self.depth = 0.0
        self.groundThermalDiffusivity = 0.0
        self.simTimeInDays = 0.0
        self.aveGroundTemp = 0.0
        self.surfTempAmplitude_1 = 0.0
        self.phaseShift_1 = 0.0
        self.surfTempAmplitude_2 = 0.0
        self.phaseShift_2 = 0.0
        self.modelType = ""
        self.Name = ""

    fn getGroundTemp(inout self, state: Pointer[EnergyPlusData]) -> Float64:
        var tp = state[].dataWeather.NumDaysInYear

        var Ts_1 = self.surfTempAmplitude_1
        var PL_1 = self.phaseShift_1
        var Ts_2 = self.surfTempAmplitude_2
        var PL_2 = self.phaseShift_2

        var n1 = 1
        var gamma1 = sqrt((n1 * state[].Constant.Pi) / (self.groundThermalDiffusivity * tp))
        var exp1 = -self.depth * gamma1
        var cos1 = 2 * state[].Constant.Pi * n1 / tp * (self.simTimeInDays - PL_1) - self.depth * gamma1

        var n2 = 2
        var gamma2 = sqrt((n2 * state[].Constant.Pi) / (self.groundThermalDiffusivity * tp))
        var exp2 = -self.depth * gamma2
        var cos2 = 2 * state[].Constant.Pi * n2 / tp * (self.simTimeInDays - PL_2) - self.depth * gamma2

        var summation = exp(exp1) * Ts_1 * cos(cos1) + exp(exp2) * Ts_2 * cos(cos2)

        return self.aveGroundTemp - summation

    fn getGroundTempAtTimeInMonths(inout self, state: Pointer[EnergyPlusData], _depth: Float64, _month: Int) -> Float64:
        var aveDaysInMonth = state[].dataWeather.NumDaysInYear / 12

        self.depth = _depth

        if _month >= 1 and _month <= 12:
            self.simTimeInDays = aveDaysInMonth * (_month - 1 + 0.5)
        else:
            var monthIndex = _month % 12
            self.simTimeInDays = aveDaysInMonth * (monthIndex - 1 + 0.5)

        return self.getGroundTemp(state)

    fn getGroundTempAtTimeInSeconds(inout self, state: Pointer[EnergyPlusData], _depth: Float64, seconds: Float64) -> Float64:
        self.depth = _depth

        self.simTimeInDays = seconds / state[].Constant.rSecsInDay

        if self.simTimeInDays > state[].dataWeather.NumDaysInYear:
            self.simTimeInDays = remainder(self.simTimeInDays, state[].dataWeather.NumDaysInYear)

        return self.getGroundTemp(state)


fn XingGTMFactory(state: Pointer[EnergyPlusData], objectName: String) -> Pointer[XingGroundTempsModel]:
    var found = False
    var thisModel = Pointer[XingGroundTempsModel].alloc(1)
    thisModel[0] = XingGroundTempsModel()

    var modelType = "Xing"

    var cCurrentModuleObject = state[].modelTypeNames[modelType]
    var currentModuleObject = cCurrentModuleObject
    var inputProcessor = state[].dataInputProcessing.inputProcessor

    if currentModuleObject not in inputProcessor.epJSON:
        raise Error(state[].modelTypeNames[modelType] + "--Errors getting input for ground temperature model")

    var modelInstances = inputProcessor.epJSON[currentModuleObject]
    var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)

    thisModel[].modelType = modelType
    thisModel[].Name = objectName

    for modelName in modelInstances.keys():
        var modelNameUpper = modelName.upper()
        var modelFields = modelInstances[modelName]

        if thisModel[].Name == modelNameUpper:
            inputProcessor.markObjectAsUsed(currentModuleObject, modelName)
            thisModel[].Name = modelNameUpper
            thisModel[].groundThermalDiffusivity = (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity") /
                                                    (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density") *
                                                     inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat"))) * state[].Constant.rSecsInDay
            thisModel[].aveGroundTemp = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_soil_surface_temperature")
            thisModel[].surfTempAmplitude_1 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_1")
            thisModel[].surfTempAmplitude_2 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_2")
            thisModel[].phaseShift_1 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_1")
            thisModel[].phaseShift_2 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_2")

            found = True
            break

    if found:
        state[].dataGrndTempModelMgr.groundTempModels.push_back(thisModel)
        return thisModel

    raise Error(state[].modelTypeNames[modelType] + "--Errors getting input for ground temperature model")
