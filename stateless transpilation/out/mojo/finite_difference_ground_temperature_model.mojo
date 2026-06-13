# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: struct with .dataWeather, .dataGlobal, .dataEnvrn, .dataReportFlag, .dataGrndTempModelMgr, .dataInputProcessing
# - BaseGroundTempsModel: trait/base struct
# - KusudaGroundTempsModel: struct for temporary initialization model
# - GroundTemp.ModelType: enum with .FiniteDiff, .Kusuda
# - GroundTemp.modelTypeNames: array/dict mapping model type to string names
# - Constant: namespace with .rSecsInDay, .KindOfSim (enum)
# - Weather.SetupEnvironmentTypes, Weather.GetNextEnvironment, Weather.ManageWeather: functions
# - ShowFatalError, ShowSevereError, ShowContinueError: error reporting functions
# - Util.makeUPPER: string upper conversion
# - EnergyPlus.format: string formatting (printf-style)
# Origin: EnergyPlus/GroundTemperatureModeling/FiniteDifferenceGroundTemperatureModel

from math import exp, sqrt, pow
alias Real64 = Float64


trait BaseGroundTempsModel:
    var Name: String
    var modelType: Int32


struct InstanceOfWeatherData:
    var dryBulbTemp: Real64
    var relativeHumidity: Real64
    var windSpeed: Real64
    var horizontalRadiation: Real64
    var airDensity: Real64
    
    fn __init__(inout self):
        self.dryBulbTemp = 0.0
        self.relativeHumidity = 0.0
        self.windSpeed = 0.0
        self.horizontalRadiation = 0.0
        self.airDensity = 0.0


struct CellProperties:
    var conductivity: Real64
    var density: Real64
    var specificHeat: Real64
    var diffusivity: Real64
    var rhoCp: Real64
    
    fn __init__(inout self):
        self.conductivity = 0.0
        self.density = 0.0
        self.specificHeat = 0.0
        self.diffusivity = 0.0
        self.rhoCp = 0.0


struct InstanceOfCellData:
    var props: CellProperties
    var index: Int32
    var thickness: Real64
    var minZValue: Real64
    var maxZValue: Real64
    var temperature: Real64
    var temperature_prevIteration: Real64
    var temperature_prevTimeStep: Real64
    var temperature_finalConvergence: Real64
    var beta: Real64
    var volume: Real64
    var conductionArea: Real64
    
    fn __init__(inout self):
        self.props = CellProperties()
        self.index = 0
        self.thickness = 0.0
        self.minZValue = 0.0
        self.maxZValue = 0.0
        self.temperature = 0.0
        self.temperature_prevIteration = 0.0
        self.temperature_prevTimeStep = 0.0
        self.temperature_finalConvergence = 0.0
        self.beta = 0.0
        self.volume = 0.0
        self.conductionArea = 1.0


struct SurfaceTypes:
    alias surfaceCoverType_bareSoil = 1
    alias surfaceCoverType_shortGrass = 2
    alias surfaceCoverType_longGrass = 3


struct FiniteDiffGroundTempsModel(BaseGroundTempsModel):
    alias maxYearsToIterate = 10
    
    var Name: String
    var modelType: Int32
    var rhoCp_soil_liq_1: Real64
    var rhoCP_soil_liq: Real64
    var rhoCP_soil_transient: Real64
    var rhoCP_soil_ice: Real64
    
    var baseConductivity: Real64
    var baseDensity: Real64
    var baseSpecificHeat: Real64
    var totalNumCells: Int32
    var timeStepInSeconds: Real64
    var evapotransCoeff: Real64
    var saturatedWaterContent: Real64
    var waterContent: Real64
    var annualAveAirTemp: Real64
    var minDailyAirTemp: Real64
    var maxDailyAirTemp: Real64
    var dayOfMinDailyAirTemp: Real64
    var depth: Real64
    var simTimeInDays: Real64
    
    var cellArray: DynamicVector[InstanceOfCellData]
    var weatherDataArray: DynamicVector[InstanceOfWeatherData]
    var groundTemps: DynamicVector[DynamicVector[Real64]]
    var cellDepths: DynamicVector[Real64]
    
    fn __init__(inout self):
        self.Name = String()
        self.modelType = 0
        self.rhoCp_soil_liq_1 = 0.0
        self.rhoCP_soil_liq = 0.0
        self.rhoCP_soil_transient = 0.0
        self.rhoCP_soil_ice = 0.0
        self.baseConductivity = 0.0
        self.baseDensity = 0.0
        self.baseSpecificHeat = 0.0
        self.totalNumCells = 0
        self.timeStepInSeconds = 0.0
        self.evapotransCoeff = 0.0
        self.saturatedWaterContent = 0.0
        self.waterContent = 0.0
        self.annualAveAirTemp = 0.0
        self.minDailyAirTemp = 100.0
        self.maxDailyAirTemp = -100.0
        self.dayOfMinDailyAirTemp = 1.0
        self.depth = 0.0
        self.simTimeInDays = 0.0
        self.cellArray = DynamicVector[InstanceOfCellData]()
        self.weatherDataArray = DynamicVector[InstanceOfWeatherData]()
        self.groundTemps = DynamicVector[DynamicVector[Real64]]()
        self.cellDepths = DynamicVector[Real64]()
    
    @staticmethod
    fn FiniteDiffGTMFactory(inout state: EnergyPlusData, objectName: String) -> Optional[Self]:
        var found: Bool = False
        var thisModel = Self()
        
        var modelType: Int32 = 0
        var cCurrentModuleObject: String = "Site:GroundTemperature:Undisturbed:FiniteDifference"
        var currentModuleObject: String = cCurrentModuleObject
        
        var inputProcessor = state.dataInputProcessing.inputProcessor
        var modelInstances = inputProcessor.epJSON.get(currentModuleObject)
        
        if modelInstances is None:
            ShowFatalError(state, cCurrentModuleObject + "--Errors getting input for ground temperature model")
        
        var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        
        for modelInstance_key in modelInstances.keys():
            var modelFields = modelInstances.get(modelInstance_key)
            var modelName = Util.makeUPPER(modelInstance_key)
            
            if objectName == modelName:
                inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance_key)
                
                thisModel.modelType = modelType
                thisModel.Name = modelName
                thisModel.baseConductivity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity")
                thisModel.baseDensity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density")
                thisModel.baseSpecificHeat = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat")
                thisModel.waterContent = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_moisture_content_volume_fraction") / 100.0
                thisModel.saturatedWaterContent = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_moisture_content_volume_fraction_at_saturation") / 100.0
                thisModel.evapotransCoeff = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "evapotranspiration_ground_cover_parameter")
                
                found = True
                break
        
        if found:
            state.dataGrndTempModelMgr.groundTempModels.push_back(thisModel)
            thisModel.initAndSim(state)
            return thisModel
        
        ShowFatalError(state, cCurrentModuleObject + "--Errors getting input for ground temperature model")
        return None
    
    fn initAndSim(inout self, inout state: EnergyPlusData) -> None:
        self.getWeatherData(state)
        self.developMesh()
        self.performSimulation(state)
    
    fn getWeatherData(inout self, inout state: EnergyPlusData) -> None:
        var Envrn_reset = state.dataWeather.Envrn
        var KindOfSim_reset = state.dataGlobal.KindOfSim
        var TimeStep_reset = state.dataGlobal.TimeStep
        var HourOfDay_reset = state.dataGlobal.HourOfDay
        var BeginEnvrnFlag_reset = state.dataGlobal.BeginEnvrnFlag
        var EndEnvrnFlag_reset = state.dataGlobal.EndEnvrnFlag
        var EndMonthFlag_reset = state.dataEnvrn.EndMonthFlag
        var WarmupFlag_reset = state.dataGlobal.WarmupFlag
        var DayOfSim_reset = state.dataGlobal.DayOfSim
        var DayOfSimChr_reset = state.dataGlobal.DayOfSimChr
        var NumOfWarmupDays_reset = state.dataReportFlag.NumOfWarmupDays
        var BeginDayFlag_reset = state.dataGlobal.BeginDayFlag
        var EndDayFlag_reset = state.dataGlobal.EndDayFlag
        var BeginHourFlag_reset = state.dataGlobal.BeginHourFlag
        var EndHourFlag_reset = state.dataGlobal.EndHourFlag
        
        if not state.dataWeather.WeatherFileExists:
            ShowSevereError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference -- using this model requires specification of a weather file.")
            ShowContinueError(state, "Either place in.epw in the working directory or specify a weather file on the command line using -w /path/to/weather.epw")
            ShowFatalError(state, "Simulation halted due to input error in ground temperature model.")
        
        var originalNumOfEnvrn = state.dataWeather.NumOfEnvrn
        state.dataWeather.NumOfEnvrn += 1
        state.dataWeather.TotRunPers += 1
        state.dataWeather.Environment.resize(state.dataWeather.NumOfEnvrn)
        state.dataWeather.RunPeriodInput.resize(state.dataWeather.TotRunPers)
        state.dataWeather.Environment[state.dataWeather.NumOfEnvrn - 1].KindOfEnvrn = 5
        state.dataWeather.RPReadAllWeatherData = True
        state.dataGlobal.WeathSimReq = True
        
        Weather.SetupEnvironmentTypes(state)
        
        state.dataWeather.Envrn = originalNumOfEnvrn
        var Available: Bool = True
        var ErrorsFound: Bool = False
        Weather.GetNextEnvironment(state, Available, ErrorsFound)
        if ErrorsFound:
            ShowFatalError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data")
        
        if state.dataGlobal.KindOfSim != 5:
            ShowFatalError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data, bad KindOfSim.")
        
        self.weatherDataArray.resize(state.dataWeather.NumDaysInYear)
        for i in range(state.dataWeather.NumDaysInYear):
            self.weatherDataArray[i] = InstanceOfWeatherData()
        
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataGlobal.EndEnvrnFlag = False
        state.dataEnvrn.EndMonthFlag = False
        state.dataGlobal.WarmupFlag = False
        state.dataGlobal.DayOfSim = 0
        state.dataGlobal.DayOfSimChr = "0"
        state.dataReportFlag.NumOfWarmupDays = 0
        
        var annualAveAirTemp_num: Real64 = 0.0
        
        while (state.dataGlobal.DayOfSim < state.dataWeather.NumDaysInYear) or state.dataGlobal.WarmupFlag:
            state.dataGlobal.DayOfSim += 1
            
            var outDryBulbTemp_num: Real64 = 0.0
            var relHum_num: Real64 = 0.0
            var windSpeed_num: Real64 = 0.0
            var horizSolarRad_num: Real64 = 0.0
            var airDensity_num: Real64 = 0.0
            var denominator: Int32 = 0
            
            var tdwd = self.weatherDataArray[state.dataGlobal.DayOfSim - 1]
            
            state.dataGlobal.BeginDayFlag = True
            state.dataGlobal.EndDayFlag = False
            
            for var hour in range(1, 25):
                state.dataGlobal.HourOfDay = hour
                state.dataGlobal.BeginHourFlag = True
                state.dataGlobal.EndHourFlag = False
                
                for var ts in range(1, state.dataGlobal.TimeStepsInHour + 1):
                    state.dataGlobal.TimeStep = ts
                    state.dataGlobal.BeginTimeStepFlag = True
                    
                    if state.dataGlobal.TimeStep == state.dataGlobal.TimeStepsInHour:
                        state.dataGlobal.EndHourFlag = True
                        if state.dataGlobal.HourOfDay == 24:
                            state.dataGlobal.EndDayFlag = True
                            if (not state.dataGlobal.WarmupFlag) and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
                                state.dataGlobal.EndEnvrnFlag = True
                    
                    Weather.ManageWeather(state)
                    
                    outDryBulbTemp_num += state.dataEnvrn.OutDryBulbTemp
                    airDensity_num += state.dataEnvrn.OutAirDensity
                    relHum_num += state.dataEnvrn.OutRelHumValue
                    windSpeed_num += state.dataEnvrn.WindSpeed
                    horizSolarRad_num += max(state.dataEnvrn.SOLCOS[2], 0.0) * state.dataEnvrn.BeamSolarRad + state.dataEnvrn.DifSolarRad
                    
                    state.dataGlobal.BeginHourFlag = False
                    state.dataGlobal.BeginDayFlag = False
                    state.dataGlobal.BeginEnvrnFlag = False
                    state.dataGlobal.BeginSimFlag = False
                    
                    denominator += 1
                
                state.dataGlobal.PreviousHour = state.dataGlobal.HourOfDay
            
            tdwd.dryBulbTemp = outDryBulbTemp_num / denominator
            tdwd.relativeHumidity = relHum_num / denominator
            tdwd.windSpeed = windSpeed_num / denominator
            tdwd.horizontalRadiation = horizSolarRad_num / denominator
            tdwd.airDensity = airDensity_num / denominator
            
            self.weatherDataArray[state.dataGlobal.DayOfSim - 1] = tdwd
            
            annualAveAirTemp_num += tdwd.dryBulbTemp
            
            if tdwd.dryBulbTemp < self.minDailyAirTemp:
                self.minDailyAirTemp = tdwd.dryBulbTemp
                self.dayOfMinDailyAirTemp = Float64(state.dataGlobal.DayOfSim)
            
            if tdwd.dryBulbTemp > self.maxDailyAirTemp:
                self.maxDailyAirTemp = tdwd.dryBulbTemp
        
        self.annualAveAirTemp = annualAveAirTemp_num / Float64(state.dataWeather.NumDaysInYear)
        
        state.dataWeather.NumOfEnvrn -= 1
        state.dataWeather.TotRunPers -= 1
        state.dataGlobal.KindOfSim = KindOfSim_reset
        state.dataWeather.RPReadAllWeatherData = False
        state.dataWeather.Environment.resize(state.dataWeather.NumOfEnvrn)
        state.dataWeather.RunPeriodInput.resize(state.dataWeather.TotRunPers)
        state.dataWeather.Envrn = Envrn_reset
        state.dataGlobal.TimeStep = TimeStep_reset
        state.dataGlobal.HourOfDay = HourOfDay_reset
        state.dataGlobal.BeginEnvrnFlag = BeginEnvrnFlag_reset
        state.dataGlobal.EndEnvrnFlag = EndEnvrnFlag_reset
        state.dataEnvrn.EndMonthFlag = EndMonthFlag_reset
        state.dataGlobal.WarmupFlag = WarmupFlag_reset
        state.dataGlobal.DayOfSim = DayOfSim_reset
        state.dataGlobal.DayOfSimChr = DayOfSimChr_reset
        state.dataReportFlag.NumOfWarmupDays = NumOfWarmupDays_reset
        state.dataGlobal.BeginDayFlag = BeginDayFlag_reset
        state.dataGlobal.EndDayFlag = EndDayFlag_reset
        state.dataGlobal.BeginHourFlag = BeginHourFlag_reset
        state.dataGlobal.EndHourFlag = EndHourFlag_reset
    
    fn developMesh(inout self) -> None:
        var surfaceLayerThickness: Real64 = 2.0
        var surfaceLayerCellThickness: Real64 = 0.015
        var surfaceLayerNumCells = Int32(surfaceLayerThickness / surfaceLayerCellThickness)
        
        var centerLayerNumCells: Int32 = 80
        
        var deepLayerThickness: Real64 = 0.2
        var deepLayerCellThickness: Real64 = surfaceLayerCellThickness
        var deepLayerNumCells = Int32(deepLayerThickness / deepLayerCellThickness)
        
        var currentCellDepth: Real64 = 0.0
        
        self.totalNumCells = surfaceLayerNumCells + centerLayerNumCells + deepLayerNumCells
        
        self.cellArray.resize(self.totalNumCells)
        self.cellDepths.resize(self.totalNumCells)
        
        for i in range(self.totalNumCells):
            var thisCell = self.cellArray[i]
            thisCell.index = i + 1
            
            if i < surfaceLayerNumCells:
                thisCell.thickness = surfaceLayerCellThickness
            elif i < (centerLayerNumCells + surfaceLayerNumCells):
                var numCenterCell = i - surfaceLayerNumCells + 1
                
                if numCenterCell <= (centerLayerNumCells / 2):
                    var centerLayerExpansionCoeff: Real64 = 1.10879
                    thisCell.thickness = surfaceLayerCellThickness * pow(centerLayerExpansionCoeff, Float64(numCenterCell))
                else:
                    thisCell.thickness = self.cellArray[(surfaceLayerNumCells + (centerLayerNumCells / 2)) - (numCenterCell - (centerLayerNumCells / 2)) - 1].thickness
            else:
                thisCell.thickness = deepLayerCellThickness
            
            thisCell.minZValue = currentCellDepth
            self.cellDepths[i] = currentCellDepth + thisCell.thickness / 2.0
            currentCellDepth += thisCell.thickness
            thisCell.maxZValue = currentCellDepth
            
            thisCell.props.conductivity = self.baseConductivity
            thisCell.props.density = self.baseDensity
            thisCell.props.specificHeat = self.baseSpecificHeat
            thisCell.props.diffusivity = self.baseConductivity / (self.baseDensity * self.baseSpecificHeat)
            
            self.cellArray[i] = thisCell
    
    fn performSimulation(inout self, inout state: EnergyPlusData) -> None:
        self.timeStepInSeconds = 86400.0
        var convergedFinal: Bool = False
        
        self.initDomain(state)
        
        while not convergedFinal:
            for var day in range(1, state.dataWeather.NumDaysInYear + 1):
                state.dataGlobal.FDsimDay = day
                var iterationConverged: Bool = False
                
                self.doStartOfTimeStepInits()
                
                while not iterationConverged:
                    for cell in range(self.totalNumCells):
                        if cell == 0:
                            self.updateSurfaceCellTemperature(state)
                        elif cell > 0 and cell < self.totalNumCells - 1:
                            self.updateGeneralDomainCellTemperature(cell)
                        elif cell == self.totalNumCells - 1:
                            self.updateBottomCellTemperature()
                    
                    iterationConverged = self.checkIterationTemperatureConvergence()
                    
                    if not iterationConverged:
                        self.updateIterationTemperatures()
                
                self.updateTimeStepTemperatures(state)
            
            convergedFinal = self.checkFinalTemperatureConvergence(state)
    
    fn updateSurfaceCellTemperature(inout self, inout state: EnergyPlusData) -> None:
        var numerator: Real64 = 0.0
        var denominator: Real64 = 0.0
        var resistance: Real64 = 0.0
        
        var rho_water: Real64 = 998.0
        var absor_Corrected: Real64 = 0.77
        var convert_Wm2_To_MJhrmin: Real64 = 3600.0 / 1000000.0
        var convert_MJhrmin_To_Wm2: Real64 = 1.0 / convert_Wm2_To_MJhrmin
        
        var thisCell = self.cellArray[0]
        var cellBelow_thisCell = self.cellArray[1]
        var cwd = self.weatherDataArray[state.dataGlobal.FDsimDay - 1]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1.0
        
        resistance = thisCell.thickness / 2.0 / (thisCell.props.conductivity * thisCell.conductionArea) + \
                     cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.props.conductivity * cellBelow_thisCell.conductionArea)
        numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        if cwd.windSpeed > 0.1:
            var airSpecificHeat: Real64 = 1003.0
            resistance = 208.0 / (cwd.airDensity * airSpecificHeat * cwd.windSpeed * thisCell.conductionArea)
        
        numerator += thisCell.beta / resistance * cwd.dryBulbTemp
        denominator += thisCell.beta / resistance
        
        var currAirTempK: Real64 = cwd.dryBulbTemp + 273.15
        var incidentSolar_MJhrmin: Real64 = cwd.horizontalRadiation * convert_Wm2_To_MJhrmin
        var absorbedIncidentSolar_MJhrmin: Real64 = absor_Corrected * incidentSolar_MJhrmin
        
        var vaporPressureSaturated_kPa: Real64 = 0.6108 * exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3))
        var vaporPressureActual_kPa: Real64 = vaporPressureSaturated_kPa * cwd.relativeHumidity
        
        var QRAD_NL: Real64 = 2.042E-10 * pow(currAirTempK, 4.0) * (0.34 - 0.14 * sqrt(vaporPressureActual_kPa))
        var netIncidentRadiation_MJhr: Real64 = absorbedIncidentSolar_MJhrmin - QRAD_NL
        
        var CN: Real64 = 37.0
        var G_hr: Real64
        var Cd: Real64
        
        if netIncidentRadiation_MJhr < 0.0:
            G_hr = 0.5 * netIncidentRadiation_MJhr
            Cd = 0.96
        else:
            G_hr = 0.1 * netIncidentRadiation_MJhr
            Cd = 0.24
        
        var slope_S: Real64 = 2503.0 * exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3)) / pow(cwd.dryBulbTemp + 237.3, 2.0)
        var pressure: Real64 = 98.0
        var psychrometricConstant: Real64 = 0.665e-3 * pressure
        
        var evapotransFluidLoss_mmhr: Real64 = (self.evapotransCoeff * slope_S * (netIncidentRadiation_MJhr - G_hr) +
                                     psychrometricConstant * (CN / currAirTempK) * cwd.windSpeed * (vaporPressureSaturated_kPa - vaporPressureActual_kPa)) / \
                                    (slope_S + psychrometricConstant * (1.0 + Cd * cwd.windSpeed))
        
        var evapotransFluidLoss_mhr: Real64 = evapotransFluidLoss_mmhr / 1000.0
        var latentHeatVaporization: Real64 = 2.501 - 2.361e-3 * thisCell.temperature_prevTimeStep
        var evapotransHeatLoss_MJhrmin: Real64 = rho_water * evapotransFluidLoss_mhr * latentHeatVaporization
        
        var netIncidentRadiation_Wm2: Real64 = netIncidentRadiation_MJhr * convert_MJhrmin_To_Wm2
        var evapotransHeatLoss_Wm2: Real64 = evapotransHeatLoss_MJhrmin * convert_MJhrmin_To_Wm2
        
        var incidentHeatGain: Real64 = (netIncidentRadiation_Wm2 - evapotransHeatLoss_Wm2) * thisCell.conductionArea
        numerator += thisCell.beta * incidentHeatGain
        
        thisCell.temperature = numerator / denominator
        self.cellArray[0] = thisCell
    
    fn updateGeneralDomainCellTemperature(inout self, cell: Int32) -> None:
        var numerator: Real64 = 0.0
        var denominator: Real64 = 0.0
        var resistance: Real64 = 0.0
        
        var thisCell = self.cellArray[cell]
        var cellAbove_thisCell = self.cellArray[cell - 1]
        var cellBelow_thisCell = self.cellArray[cell + 1]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1.0
        
        resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     cellAbove_thisCell.thickness / 2.0 / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity)
        
        numerator += thisCell.beta / resistance * cellAbove_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.conductionArea * cellBelow_thisCell.props.conductivity)
        
        numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        thisCell.temperature = numerator / denominator
        self.cellArray[cell] = thisCell
    
    fn updateBottomCellTemperature(inout self) -> None:
        var numerator: Real64 = 0.0
        var denominator: Real64 = 0.0
        var resistance: Real64 = 0.0
        var geothermalGradient: Real64 = 0.025
        
        var thisCell = self.cellArray[self.totalNumCells - 1]
        var cellAbove_thisCell = self.cellArray[self.totalNumCells - 2]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1.0
        
        resistance = (thisCell.thickness / 2.0) / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     (cellAbove_thisCell.thickness / 2.0) / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity)
        
        numerator += (thisCell.beta / resistance) * cellAbove_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        var HTBottom: Real64 = geothermalGradient * thisCell.props.conductivity * thisCell.conductionArea
        numerator += thisCell.beta * HTBottom
        
        thisCell.temperature = numerator / denominator
        self.cellArray[self.totalNumCells - 1] = thisCell
    
    fn checkFinalTemperatureConvergence(inout self, inout state: EnergyPlusData) -> Bool:
        var converged: Bool = True
        var finalTempConvergenceCriteria: Real64 = 0.05
        
        if state.dataGlobal.FDnumIterYears == Self.maxYearsToIterate:
            return converged
        
        for cell in range(self.totalNumCells):
            var thisCell = self.cellArray[cell]
            
            if abs(thisCell.temperature - thisCell.temperature_finalConvergence) >= finalTempConvergenceCriteria:
                converged = False
            
            thisCell.temperature_finalConvergence = thisCell.temperature
            self.cellArray[cell] = thisCell
        
        state.dataGlobal.FDnumIterYears += 1
        
        return converged
    
    fn checkIterationTemperatureConvergence(self) -> Bool:
        var converged: Bool = True
        var iterationTempConvergenceCriteria: Real64 = 0.00001
        
        for cell in range(self.totalNumCells):
            if abs(self.cellArray[cell].temperature - self.cellArray[cell].temperature_prevIteration) >= iterationTempConvergenceCriteria:
                converged = False
                break
        
        return converged
    
    fn initDomain(inout self, inout state: EnergyPlusData) -> None:
        var tempModel = KusudaGroundTempsModel()
        tempModel.Name = "KAModelForFDModel"
        tempModel.modelType = 1
        tempModel.aveGroundTemp = self.annualAveAirTemp
        tempModel.aveGroundTempAmplitude = (self.maxDailyAirTemp - self.minDailyAirTemp) / 4.0
        tempModel.phaseShiftInSecs = self.dayOfMinDailyAirTemp * 86400.0
        tempModel.groundThermalDiffusivity = self.baseConductivity / (self.baseDensity * self.baseSpecificHeat)
        
        for cell in range(self.totalNumCells):
            var thisCell = self.cellArray[cell]
            
            var depth: Real64 = (thisCell.maxZValue + thisCell.minZValue) / 2.0
            
            thisCell.temperature = tempModel.getGroundTempAtTimeInSeconds(state, depth, 0.0)
            thisCell.temperature_finalConvergence = thisCell.temperature
            thisCell.temperature_prevIteration = thisCell.temperature
            thisCell.temperature_prevTimeStep = thisCell.temperature
            
            thisCell.volume = thisCell.thickness * thisCell.conductionArea
            
            self.cellArray[cell] = thisCell
        
        self.evaluateSoilRhoCpInit()
        
        self.groundTemps.resize(state.dataWeather.NumDaysInYear)
        for i in range(state.dataWeather.NumDaysInYear):
            var row = DynamicVector[Real64]()
            row.resize(self.totalNumCells)
            for j in range(self.totalNumCells):
                row[j] = 0.0
            self.groundTemps[i] = row
    
    fn updateIterationTemperatures(inout self) -> None:
        for cell in range(self.totalNumCells):
            var thisCell = self.cellArray[cell]
            thisCell.temperature_prevIteration = thisCell.temperature
            self.cellArray[cell] = thisCell
    
    fn updateTimeStepTemperatures(inout self, inout state: EnergyPlusData) -> None:
        for cell in range(self.totalNumCells):
            var thisCell = self.cellArray[cell]
            thisCell.temperature_prevTimeStep = thisCell.temperature
            self.groundTemps[state.dataGlobal.FDsimDay - 1][cell] = thisCell.temperature
            self.cellArray[cell] = thisCell
    
    fn doStartOfTimeStepInits(inout self) -> None:
        for cell in range(self.totalNumCells):
            var thisCell = self.cellArray[cell]
            self.evaluateSoilRhoCpCell(cell)
            thisCell.beta = (self.timeStepInSeconds / (thisCell.props.rhoCp * thisCell.volume))
            self.cellArray[cell] = thisCell
    
    @staticmethod
    fn interpolate(x: Real64, x_hi: Real64, x_low: Real64, y_hi: Real64, y_low: Real64) -> Real64:
        return (x - x_low) / (x_hi - x_low) * (y_hi - y_low) + y_low
    
    fn getGroundTemp(inout self, inout state: EnergyPlusData) -> Real64:
        if self.depth < 0.0:
            self.depth = 0.0
        
        var j0: Int32 = 0
        for i in range(self.totalNumCells):
            if self.cellDepths[i] < self.depth:
                j0 = i
        
        j0 += 1
        
        var dayFrac: Real64 = self.simTimeInDays - Float64(Int32(self.simTimeInDays))
        
        if j0 < self.totalNumCells - 1:
            var j1: Int32 = j0 + 1
            
            if self.simTimeInDays <= 1.0 or self.simTimeInDays >= Float64(state.dataWeather.NumDaysInYear):
                var i0: Int32 = state.dataWeather.NumDaysInYear - 1
                var i1: Int32 = 0
                
                var T_i0_j0: Real64 = self.groundTemps[i0][j0]
                var T_i0_j1: Real64 = self.groundTemps[i0][j1]
                var T_i1_j0: Real64 = self.groundTemps[i1][j0]
                var T_i1_j1: Real64 = self.groundTemps[i1][j1]
                
                var T_ix_j0: Real64 = Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j0, T_i0_j0)
                var T_ix_j1: Real64 = Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
                
                return Self.interpolate(self.depth, self.cellDepths[j1], self.cellDepths[j0], T_ix_j1, T_ix_j0)
            
            var i0: Int32 = Int32(self.simTimeInDays) - 1
            var i1: Int32 = i0 + 1
            
            var T_i0_j0: Real64 = self.groundTemps[i0][j0]
            var T_i0_j1: Real64 = self.groundTemps[i0][j1]
            var T_i1_j0: Real64 = self.groundTemps[i1][j0]
            var T_i1_j1: Real64 = self.groundTemps[i1][j1]
            
            var T_ix_j0: Real64 = Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j0, T_i0_j0)
            var T_ix_j1: Real64 = Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
            
            return Self.interpolate(self.depth, self.cellDepths[j1], self.cellDepths[j0], T_ix_j1, T_ix_j0)
        
        j0 = self.totalNumCells - 1
        var j1: Int32 = j0
        
        if self.simTimeInDays <= 1.0 or self.simTimeInDays >= Float64(state.dataWeather.NumDaysInYear):
            var i0: Int32 = state.dataWeather.NumDaysInYear - 1
            var i1: Int32 = 0
            
            var T_i0_j1: Real64 = self.groundTemps[i0][j1]
            var T_i1_j1: Real64 = self.groundTemps[i1][j1]
            
            return Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
        
        var i0: Int32 = Int32(self.simTimeInDays) - 1
        var i1: Int32 = i0 + 1
        
        var T_i0_j1: Real64 = self.groundTemps[i0][j1]
        var T_i1_j1: Real64 = self.groundTemps[i1][j1]
        
        return Self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
    
    fn getGroundTempAtTimeInSeconds(inout self, inout state: EnergyPlusData, _depth: Real64, seconds: Real64) -> Real64:
        self.depth = _depth
        self.simTimeInDays = seconds / 86400.0
        
        if self.simTimeInDays > Float64(state.dataWeather.NumDaysInYear):
            self.simTimeInDays = self.simTimeInDays % Float64(state.dataWeather.NumDaysInYear)
        
        return self.getGroundTemp(state)
    
    fn getGroundTempAtTimeInMonths(inout self, inout state: EnergyPlusData, _depth: Real64, month: Int32) -> Real64:
        var aveDaysInMonth: Real64 = Float64(state.dataWeather.NumDaysInYear) / 12.0
        
        self.depth = _depth
        self.simTimeInDays = aveDaysInMonth * (Float64(month - 1) + 0.5)
        
        if self.simTimeInDays > Float64(state.dataWeather.NumDaysInYear):
            self.simTimeInDays = self.simTimeInDays % Float64(state.dataWeather.NumDaysInYear)
        
        return self.getGroundTemp(state)
    
    fn evaluateSoilRhoCpCell(inout self, cell: Int32) -> None:
        var thisCell = self.cellArray[cell]
        thisCell.props.rhoCp = self.baseDensity * self.baseSpecificHeat
        thisCell.props.specificHeat = thisCell.props.rhoCp / thisCell.props.density
        self.cellArray[cell] = thisCell
    
    fn evaluateSoilRhoCpInit(inout self) -> None:
        var Theta_liq: Real64 = self.waterContent
        var Theta_sat: Real64 = self.saturatedWaterContent
        var Theta_ice: Real64 = Theta_liq
        
        var rho_ice: Real64 = 917.0
        var rho_liq: Real64 = 1000.0
        self.rhoCp_soil_liq_1 = 1225000.0 / (1.0 - Theta_sat)
        var CP_liq: Real64 = 4180.0
        var CP_ice: Real64 = 2066.0
        var Lat_fus: Real64 = 334000.0
        var Cp_transient: Real64 = Lat_fus / 0.4 + (0.5 * CP_ice - (CP_liq + CP_ice) / 2.0 * 0.1) / 0.4
        self.rhoCP_soil_liq = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_liq * CP_liq * Theta_liq
        self.rhoCP_soil_transient = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + ((rho_liq + rho_ice) / 2.0) * Cp_transient * Theta_ice
        self.rhoCP_soil_ice = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_ice * CP_ice * Theta_ice
