from math import sqrt, exp, cos, remainder, pi
from ...Data.EnergyPlusData import EnergyPlusData
from ...InputProcessing.InputProcessor import InputProcessor
from ...UtilityRoutines import ShowFatalError, Util
from ...WeatherManager import WeatherManager
from ...Constant import Constant
from BaseGroundTemperatureModel import BaseGroundTempsModel, ModelType, modelTypeNames
from SiteShallowGroundTemperatures import SiteShallowGroundTemps

class KusudaGroundTempsModel(BaseGroundTempsModel):
    depth: Float64 = 0.0
    groundThermalDiffusivity: Float64 = 0.0
    simTimeInSeconds: Float64 = 0.0
    aveGroundTemp: Float64 = 0.0
    aveGroundTempAmplitude: Float64 = 0.0
    phaseShiftInSecs: Float64 = 0.0

    @staticmethod
    def KusudaGTMFactory(state: EnergyPlusData, objectName: String) -> Self:
        var found: Bool = False
        var thisModel = KusudaGroundTempsModel()
        let lookingForName = objectName
        var modelType = ModelType.Kusuda
        let cCurrentModuleObject = modelTypeNames[Int(modelType)]
        let currentModuleObject = String(cCurrentModuleObject)
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var modelInstances = inputProcessor.epJSON.find(currentModuleObject)
        if modelInstances == inputProcessor.epJSON.end():
            ShowFatalError(state, "{}--Errors getting input for ground temperature model".format(modelTypeNames[Int(modelType)]))
        var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        for modelInstance in modelInstances.value().items():
            let modelName = Util.makeUPPER(modelInstance.key())
            let modelFields = modelInstance.value()
            if lookingForName == modelName:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance.key())
                thisModel.Name = modelName
                thisModel.modelType = modelType
                thisModel.groundThermalDiffusivity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity") / (inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density") * inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat"))
                var flags: StaticTuple[Float64, 3] = StaticTuple[Float64, 3](
                    inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_soil_surface_temperature"),
                    inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_amplitude_of_surface_temperature"),
                    inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_minimum_surface_temperature"))
                let useGroundTempDataForKusuda = any(flag != 0.0 for flag in flags)
                if useGroundTempDataForKusuda:
                    thisModel.aveGroundTemp = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_soil_surface_temperature")
                    thisModel.aveGroundTempAmplitude = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "average_amplitude_of_surface_temperature")
                    thisModel.phaseShiftInSecs = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "phase_shift_of_minimum_surface_temperature") * Constant.rSecsInDay
                else:
                    alias monthsInYear: Int = 12
                    alias avgDaysInMonth: Int = 30
                    var monthOfMinSurfTemp: Int = 0
                    var averageGroundTemp: Float64 = 0.0
                    var amplitudeOfGroundTemp: Float64 = 0.0
                    var phaseShiftOfMinGroundTempDays: Float64 = 0.0
                    var minSurfTemp: Float64 = 100.0
                    var maxSurfTemp: Float64 = -100.0
                    var shallowObj = SiteShallowGroundTemps.ShallowGTMFactory(state, "")
                    for monthIndex in range(1, 13):
                        let currMonthTemp = shallowObj.getGroundTempAtTimeInMonths(state, 0.0, monthIndex)
                        averageGroundTemp += currMonthTemp
                        if currMonthTemp <= minSurfTemp:
                            monthOfMinSurfTemp = monthIndex
                            minSurfTemp = currMonthTemp
                        if currMonthTemp >= maxSurfTemp:
                            maxSurfTemp = currMonthTemp
                    averageGroundTemp /= Float64(monthsInYear)
                    amplitudeOfGroundTemp = (maxSurfTemp - minSurfTemp) / 2.0
                    phaseShiftOfMinGroundTempDays = Float64(monthOfMinSurfTemp * avgDaysInMonth)
                    thisModel.aveGroundTemp = averageGroundTemp
                    thisModel.aveGroundTempAmplitude = amplitudeOfGroundTemp
                    thisModel.phaseShiftInSecs = phaseShiftOfMinGroundTempDays * Constant.rSecsInDay
                found = True
                break
        if found:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel
        ShowFatalError(state, "{}--Errors getting input for ground temperature model".format(modelTypeNames[Int(modelType)]))
        return None

    def getGroundTemp(self, state: EnergyPlusData) -> Float64:
        let secsInYear = Constant.rSecsInDay * state.dataWeather.NumDaysInYear
        let term1 = -self.depth * sqrt(pi / (secsInYear * self.groundThermalDiffusivity))
        let term2 = (2.0 * pi / secsInYear) * (self.simTimeInSeconds - self.phaseShiftInSecs - (self.depth / 2.0) * sqrt(secsInYear / (pi * self.groundThermalDiffusivity)))
        return self.aveGroundTemp - self.aveGroundTempAmplitude * exp(term1) * cos(term2)

    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, _depth: Float64, _seconds: Float64) -> Float64:
        let secondsInYear = state.dataWeather.NumDaysInYear * Constant.rSecsInDay
        self.depth = _depth
        self.simTimeInSeconds = _seconds
        if self.simTimeInSeconds > secondsInYear:
            self.simTimeInSeconds = remainder(self.simTimeInSeconds, secondsInYear)
        return self.getGroundTemp(state)

    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, _depth: Float64, _month: Int) -> Float64:
        let aveSecondsInMonth = (state.dataWeather.NumDaysInYear / 12) * Constant.rSecsInDay
        let secondsPerYear = state.dataWeather.NumDaysInYear * Constant.rSecsInDay
        self.depth = _depth
        self.simTimeInSeconds = aveSecondsInMonth * (Float64(_month) - 1.0 + 0.5)
        if self.simTimeInSeconds > secondsPerYear:
            self.simTimeInSeconds = remainder(self.simTimeInSeconds, secondsPerYear)
        return self.getGroundTemp(state)