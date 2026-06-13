# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object with:
#   - state.dataWeather.NumDaysInYear: int
#   - state.dataInputProcessing.inputProcessor: InputProcessor
#   - state.dataGrndTempModelMgr.groundTempModels: list
# BaseGroundTempsModel: base class from GroundTemperatureModeling.BaseGroundTemperatureModel
# Constant: namespace with rSecsInDay (86400.0), Pi (3.141592653589793)
# ModelType: enum with Kusuda value
# GroundTemp: namespace with modelTypeNames array
# Util: utilities module with makeUPPER function
# SiteShallowGroundTemps: module with ShallowGTMFactory function
# ShowFatalError: function(state, message)
# format: EnergyPlus format function
# math.sqrt, math.exp, math.cos, math.fmod: standard library

import math
from typing import Optional

class BaseGroundTempsModel:
    """Stub for base class - override methods as needed"""
    def __init__(self):
        self.Name = ""
        self.modelType = None
    
    def getGroundTempAtTimeInMonths(self, state, depth: float, month: int) -> float:
        raise NotImplementedError


class KusudaGroundTempsModel(BaseGroundTempsModel):
    def __init__(self):
        super().__init__()
        self.depth = 0.0
        self.groundThermalDiffusivity = 0.0
        self.simTimeInSeconds = 0.0
        self.aveGroundTemp = 0.0
        self.aveGroundTempAmplitude = 0.0
        self.phaseShiftInSecs = 0.0
    
    @staticmethod
    def KusudaGTMFactory(state, objectName: str) -> Optional['KusudaGroundTempsModel']:
        found = False
        thisModel = KusudaGroundTempsModel()
        
        lookingForName = objectName
        
        modelType = 0
        
        cCurrentModuleObject = "Site:GroundTemperature:Kusuda:Achenbach"
        currentModuleObject = cCurrentModuleObject
        inputProcessor = state.dataInputProcessing.inputProcessor
        
        try:
            modelInstances = inputProcessor.epJSON[currentModuleObject]
        except (KeyError, AttributeError):
            raise RuntimeError(
                f"Site:GroundTemperature:Kusuda:Achenbach--Errors getting input for ground temperature model"
            )
        
        modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        
        for modelInstance_key, modelInstance_value in modelInstances.items():
            modelName = modelInstance_key.upper()
            modelFields = modelInstance_value
            
            if lookingForName == modelName:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance_key)
                
                thisModel.Name = modelName
                thisModel.modelType = modelType
                
                soil_thermal_conductivity = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_thermal_conductivity"
                )
                soil_density = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_density"
                )
                soil_specific_heat = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_specific_heat"
                )
                
                thisModel.groundThermalDiffusivity = soil_thermal_conductivity / (soil_density * soil_specific_heat)
                
                flags = [
                    inputProcessor.getRealFieldValue(
                        modelFields, modelSchemaProps, "average_soil_surface_temperature"
                    ),
                    inputProcessor.getRealFieldValue(
                        modelFields, modelSchemaProps, "average_amplitude_of_surface_temperature"
                    ),
                    inputProcessor.getRealFieldValue(
                        modelFields, modelSchemaProps, "phase_shift_of_minimum_surface_temperature"
                    ),
                ]
                useGroundTempDataForKusuda = any(flags)
                
                if useGroundTempDataForKusuda:
                    thisModel.aveGroundTemp = inputProcessor.getRealFieldValue(
                        modelFields, modelSchemaProps, "average_soil_surface_temperature"
                    )
                    thisModel.aveGroundTempAmplitude = inputProcessor.getRealFieldValue(
                        modelFields, modelSchemaProps, "average_amplitude_of_surface_temperature"
                    )
                    thisModel.phaseShiftInSecs = (
                        inputProcessor.getRealFieldValue(
                            modelFields, modelSchemaProps, "phase_shift_of_minimum_surface_temperature"
                        )
                        * 86400.0
                    )
                else:
                    monthsInYear = 12
                    avgDaysInMonth = 30
                    monthOfMinSurfTemp = 0
                    averageGroundTemp = 0.0
                    amplitudeOfGroundTemp = 0.0
                    phaseShiftOfMinGroundTempDays = 0.0
                    minSurfTemp = 100.0
                    maxSurfTemp = -100.0
                    
                    shallowObj = state.dataGrndTemp.ShallowGroundTemps
                    
                    for monthIndex in range(1, 13):
                        currMonthTemp = shallowObj.getGroundTempAtTimeInMonths(state, 0.0, monthIndex)
                        
                        averageGroundTemp += currMonthTemp
                        
                        if currMonthTemp <= minSurfTemp:
                            monthOfMinSurfTemp = monthIndex
                            minSurfTemp = currMonthTemp
                        
                        if currMonthTemp >= maxSurfTemp:
                            maxSurfTemp = currMonthTemp
                    
                    averageGroundTemp /= monthsInYear
                    
                    amplitudeOfGroundTemp = (maxSurfTemp - minSurfTemp) / 2.0
                    
                    phaseShiftOfMinGroundTempDays = monthOfMinSurfTemp * avgDaysInMonth
                    
                    thisModel.aveGroundTemp = averageGroundTemp
                    thisModel.aveGroundTempAmplitude = amplitudeOfGroundTemp
                    thisModel.phaseShiftInSecs = phaseShiftOfMinGroundTempDays * 86400.0
                
                found = True
                break
        
        if found:
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            return thisModel
        
        raise RuntimeError(
            "Site:GroundTemperature:Kusuda:Achenbach--Errors getting input for ground temperature model"
        )
    
    def getGroundTemp(self, state) -> float:
        secsInYear = 86400.0 * state.dataWeather.NumDaysInYear
        
        pi_const = 3.141592653589793
        
        term1 = (
            -self.depth
            * math.sqrt(pi_const / (secsInYear * self.groundThermalDiffusivity))
        )
        term2 = (2 * pi_const / secsInYear) * (
            self.simTimeInSeconds
            - self.phaseShiftInSecs
            - (self.depth / 2.0)
            * math.sqrt(
                secsInYear / (pi_const * self.groundThermalDiffusivity)
            )
        )
        
        return (
            self.aveGroundTemp
            - self.aveGroundTempAmplitude
            * math.exp(term1)
            * math.cos(term2)
        )
    
    def getGroundTempAtTimeInSeconds(self, state, depth: float, seconds: float) -> float:
        secondsInYear = state.dataWeather.NumDaysInYear * 86400.0
        
        self.depth = depth
        
        self.simTimeInSeconds = seconds
        
        if self.simTimeInSeconds > secondsInYear:
            self.simTimeInSeconds = math.fmod(self.simTimeInSeconds, secondsInYear)
        
        return self.getGroundTemp(state)
    
    def getGroundTempAtTimeInMonths(self, state, depth: float, month: int) -> float:
        aveSecondsInMonth = (state.dataWeather.NumDaysInYear / 12.0) * 86400.0
        secondsPerYear = state.dataWeather.NumDaysInYear * 86400.0
        
        self.depth = depth
        
        self.simTimeInSeconds = aveSecondsInMonth * (month - 1 + 0.5)
        
        if self.simTimeInSeconds > secondsPerYear:
            self.simTimeInSeconds = math.fmod(self.simTimeInSeconds, secondsPerYear)
        
        return self.getGroundTemp(state)
