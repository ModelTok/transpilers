from ..Data.EnergyPlusData import EnergyPlusData
from ..DataGlobalConstants import Constant
from ..GroundTemperatureModeling.BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType
from ..InputProcessing.InputProcessor import InputProcessor
from ..UtilityRoutines import Util
from ..WeatherManager import WeatherManager
from memory import new
from math import sqrt, exp, cos, remainder
from string import String

@value
struct XingGroundTempsModel(BaseGroundTempsModel):
    var depth: Float64 = 0.0
    var groundThermalDiffusivity: Float64 = 0.0
    var simTimeInDays: Float64 = 0.0
    var aveGroundTemp: Float64 = 0.0
    var surfTempAmplitude_1: Float64 = 0.0
    var phaseShift_1: Float64 = 0.0
    var surfTempAmplitude_2: Float64 = 0.0
    var phaseShift_2: Float64 = 0.0

    @staticmethod
    def XingGTMFactory(state: EnergyPlusData, objectName: String) -> XingGroundTempsModel:
        var found = False
        var thisModel = XingGroundTempsModel()
        var modelType = ModelType.Xing
        var cCurrentModuleObject = GroundTemp.modelTypeNames[int(modelType)]
        var currentModuleObject = String(cCurrentModuleObject)
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var modelInstances = inputProcessor.epJSON.find(currentModuleObject)
        if modelInstances == inputProcessor.epJSON.end():
            ShowFatalError(state,
                           EnergyPlus.format("{}--Errors getting input for ground temperature model", GroundTemp.modelTypeNames[int(modelType)]))
        var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        thisModel.modelType = modelType
        thisModel.Name = objectName
        for modelInstance in modelInstances.value().items():
            var modelName = Util.makeUPPER(modelInstance.key())
            var modelFields = modelInstance.value()
            if thisModel.Name == modelName:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance.key())
                thisModel.Name = modelName
                thisModel.groundThermalDiffusivity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity") / \
                                                      (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density") * \
                                                       inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat")) * \
                                                      Constant.rSecsInDay
                thisModel.aveGroundTemp = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_soil_surface_temperature")
                thisModel.surfTempAmplitude_1 = \
                    inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_1")
                thisModel.surfTempAmplitude_2 = \
                    inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_surface_temperature_amplitude_2")
                thisModel.phaseShift_1 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_1")
                thisModel.phaseShift_2 = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_temperature_amplitude_2")
                found = True
                break
        if found:
            state.dataGrndTempModelMgr.groundTempModels.push_back(thisModel)
            return thisModel
        ShowFatalError(state,
                       EnergyPlus.format("{}--Errors getting input for ground temperature model", GroundTemp.modelTypeNames[int(modelType)]))
        return thisModel

    def getGroundTemp(inout self, state: EnergyPlusData) -> Float64:
        var tp = state.dataWeather.NumDaysInYear # Period of soil temperature cycle
        var Ts_1 = self.surfTempAmplitude_1 # Amplitude of surface temperature
        var PL_1 = self.phaseShift_1        # Phase shift of surface temperature
        var Ts_2 = self.surfTempAmplitude_2 # Amplitude of surface temperature
        var PL_2 = self.phaseShift_2        # Phase shift of surface temperature
        var n1 = 1
        var gamma1 = sqrt((n1 * Constant.Pi) / (self.groundThermalDiffusivity * tp))
        var exp1 = -self.depth * gamma1
        var cos1 = 2 * Constant.Pi * n1 / tp * (self.simTimeInDays - PL_1) - self.depth * gamma1
        var n2 = 2
        var gamma2 = sqrt((n2 * Constant.Pi) / (self.groundThermalDiffusivity * tp))
        var exp2 = -self.depth * gamma2
        var cos2 = 2 * Constant.Pi * n2 / tp * (self.simTimeInDays - PL_2) - self.depth * gamma2
        var summation = exp(exp1) * Ts_1 * cos(cos1) + exp(exp2) * Ts_2 * cos(cos2)
        return self.aveGroundTemp - summation

    def getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, _depth: Float64, _month: Int) -> Float64:
        var aveDaysInMonth = state.dataWeather.NumDaysInYear / 12
        self.depth = _depth
        if _month >= 1 and _month <= 12:
            self.simTimeInDays = aveDaysInMonth * (_month - 1 + 0.5)
        else:
            var monthIndex = _month % 12
            self.simTimeInDays = aveDaysInMonth * (monthIndex - 1 + 0.5)
        return self.getGroundTemp(state)

    def getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, _depth: Float64, seconds: Float64) -> Float64:
        self.depth = _depth
        self.simTimeInDays = seconds / Constant.rSecsInDay
        if self.simTimeInDays > state.dataWeather.NumDaysInYear:
            self.simTimeInDays = remainder(self.simTimeInDays, state.dataWeather.NumDaysInYear)
        return self.getGroundTemp(state)