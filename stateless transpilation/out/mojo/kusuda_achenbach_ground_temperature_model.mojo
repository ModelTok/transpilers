# EXTERNAL DEPS (to wire in glue):
# EnergyPlusData: state object with:
#   - state.dataWeather.NumDaysInYear: Int
#   - state.dataInputProcessing.inputProcessor: InputProcessor
#   - state.dataGrndTempModelMgr.groundTempModels: list-like
# BaseGroundTempsModel: base struct from GroundTemperatureModeling.BaseGroundTemperatureModel
# Constant: namespace with rSecsInDay (86400.0), Pi (3.141592653589793)
# ModelType: enum with Kusuda value
# GroundTemp: namespace with modelTypeNames array
# Util: utilities module with makeUPPER function
# SiteShallowGroundTemps: module with ShallowGTMFactory function
# ShowFatalError: function(state, message)
# format: EnergyPlus format function
# math.sqrt, math.exp, math.cos, math.fmod: standard library

from math import sqrt, exp, cos, fmod

struct BaseGroundTempsModel:
    var Name: String
    var modelType: Int
    
    fn __init__(inout self):
        self.Name = ""
        self.modelType = 0


struct KusudaGroundTempsModel(BaseGroundTempsModel):
    var depth: Float64
    var groundThermalDiffusivity: Float64
    var simTimeInSeconds: Float64
    var aveGroundTemp: Float64
    var aveGroundTempAmplitude: Float64
    var phaseShiftInSecs: Float64
    
    fn __init__(inout self):
        self.Name = ""
        self.modelType = 0
        self.depth = 0.0
        self.groundThermalDiffusivity = 0.0
        self.simTimeInSeconds = 0.0
        self.aveGroundTemp = 0.0
        self.aveGroundTempAmplitude = 0.0
        self.phaseShiftInSecs = 0.0
    
    @staticmethod
    fn KusudaGTMFactory(state: EnergyPlusData, objectName: String) -> KusudaGroundTempsModel:
        var found = False
        var thisModel = KusudaGroundTempsModel()
        
        var lookingForName = objectName
        
        var modelType: Int = 0
        
        var cCurrentModuleObject = "Site:GroundTemperature:Kusuda:Achenbach"
        var currentModuleObject = cCurrentModuleObject
        var inputProcessor = state.dataInputProcessing.inputProcessor
        
        var modelInstances = inputProcessor.epJSON.get(currentModuleObject)
        if not modelInstances:
            raise Error(
                "Site:GroundTemperature:Kusuda:Achenbach--Errors getting input for ground temperature model"
            )
        
        var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        
        for modelInstance_key in modelInstances.keys():
            var modelName = modelInstance_key.upper()
            var modelFields = modelInstances[modelInstance_key]
            
            if lookingForName == modelName:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance_key)
                
                thisModel.Name = modelName
                thisModel.modelType = modelType
                
                var soil_thermal_conductivity = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_thermal_conductivity"
                )
                var soil_density = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_density"
                )
                var soil_specific_heat = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "soil_specific_heat"
                )
                
                thisModel.groundThermalDiffusivity = soil_thermal_conductivity / (
                    soil_density * soil_specific_heat
                )
                
                var flag0 = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "average_soil_surface_temperature"
                )
                var flag1 = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "average_amplitude_of_surface_temperature"
                )
                var flag2 = inputProcessor.getRealFieldValue(
                    modelFields, modelSchemaProps, "phase_shift_of_minimum_surface_temperature"
                )
                
                var useGroundTempDataForKusuda = bool(flag0) or bool(flag1) or bool(flag2)
                
                if useGroundTempDataForKusuda:
                    thisModel.aveGroundTemp = flag0
                    thisModel.aveGroundTempAmplitude = flag1
                    thisModel.phaseShiftInSecs = flag2 * 86400.0
                else:
                    var monthsInYear: Int = 12
                    var avgDaysInMonth: Int = 30
                    var monthOfMinSurfTemp: Int = 0
                    var averageGroundTemp: Float64 = 0.0
                    var amplitudeOfGroundTemp: Float64 = 0.0
                    var phaseShiftOfMinGroundTempDays: Float64 = 0.0
                    var minSurfTemp: Float64 = 100.0
                    var maxSurfTemp: Float64 = -100.0
                    
                    var shallowObj = state.dataGrndTemp.ShallowGroundTemps
                    
                    for monthIndex in range(1, 13):
                        var currMonthTemp = shallowObj.getGroundTempAtTimeInMonths(
                            state, 0.0, monthIndex
                        )
                        
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
        
        raise Error(
            "Site:GroundTemperature:Kusuda:Achenbach--Errors getting input for ground temperature model"
        )
    
    fn getGroundTemp(self, state: EnergyPlusData) -> Float64:
        var secsInYear = 86400.0 * state.dataWeather.NumDaysInYear
        
        var pi_const = 3.141592653589793
        
        var term1 = (
            -self.depth
            * sqrt(pi_const / (secsInYear * self.groundThermalDiffusivity))
        )
        var term2 = (2 * pi_const / secsInYear) * (
            self.simTimeInSeconds
            - self.phaseShiftInSecs
            - (self.depth / 2.0)
            * sqrt(
                secsInYear / (pi_const * self.groundThermalDiffusivity)
            )
        )
        
        return (
            self.aveGroundTemp
            - self.aveGroundTempAmplitude
            * exp(term1)
            * cos(term2)
        )
    
    fn getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, depth: Float64, seconds: Float64) -> Float64:
        var secondsInYear = state.dataWeather.NumDaysInYear * 86400.0
        
        self.depth = depth
        
        self.simTimeInSeconds = seconds
        
        if self.simTimeInSeconds > secondsInYear:
            self.simTimeInSeconds = fmod(self.simTimeInSeconds, secondsInYear)
        
        return self.getGroundTemp(state)
    
    fn getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, depth: Float64, month: Int) -> Float64:
        var aveSecondsInMonth = (state.dataWeather.NumDaysInYear / 12.0) * 86400.0
        var secondsPerYear = state.dataWeather.NumDaysInYear * 86400.0
        
        self.depth = depth
        
        self.simTimeInSeconds = aveSecondsInMonth * (month - 1 + 0.5)
        
        if self.simTimeInSeconds > secondsPerYear:
            self.simTimeInSeconds = fmod(self.simTimeInSeconds, secondsPerYear)
        
        return self.getGroundTemp(state)
