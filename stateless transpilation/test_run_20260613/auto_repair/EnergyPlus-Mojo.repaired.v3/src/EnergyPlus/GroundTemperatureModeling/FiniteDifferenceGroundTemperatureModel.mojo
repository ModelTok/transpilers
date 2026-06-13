// AUTO-GENERATED FROM C++: src/EnergyPlus/GroundTemperatureModeling/FiniteDifferenceGroundTemperatureModel.cc
// HEADER CONTEXT: FiniteDifferenceGroundTemperatureModel.hh
// 1:1 translation, no refactoring, 0-based indexing for arrays.

from algorithm import sort, binary_search, lower_bound, upper_bound, insert, sort, stable_sort, partial_sort, nth_element, inplace_merge, make_heap, push_heap, pop_heap, sort_heap, is_heap, is_heap_until, is_sorted, is_sorted_until, all_of, any_of, none_of, for_each, count, count_if, mismatch, equal, find, find_if, find_if_not, find_end, find_first_of, adjacent_find, search, search_n, copy, copy_n, copy_if, copy_backward, move, move_backward, fill, fill_n, transform, generate, generate_n, remove, remove_if, remove_copy, remove_copy_if, replace, replace_if, replace_copy, replace_copy_if, swap, swap_ranges, iter_swap, reverse, reverse_copy, rotate, rotate_copy, shuffle, sample, unique, unique_copy, is_partitioned, partition, partition_copy, stable_partition, partition_point, partial_sort, partial_sort_copy, is_permutation, next_permutation, prev_permutation
from math import abs, exp, sqrt, pow, max, min, fmod
from builtin import String, StringRef, Int, Float64, Bool, List, Pointer, new, delete, print, len, str
from Fmath import pow_2, pow_4  // Assume these exist in that module; otherwise define below

from ......FiniteDifferenceGroundTemperatureModel import FiniteDiffGroundTempsModel  // self? circular? Actually we are defining, so we don't import.

// Forward imports for EnergyPlus types
from ......Data.EnergyPlusData import EnergyPlusData
from ......DataEnvironment import DataEnvironment
from ......DataGlobals import DataGlobals
from ......DataReportingFlags import DataReportingFlags
from ......General import General
from ......GroundTemperatureModeling.BaseGroundTemperatureModel import BaseGroundTempsModel
from ......GroundTemperatureModeling.KusudaAchenbachGroundTemperatureModel import KusudaGroundTempsModel
from ......InputProcessing.InputProcessor import InputProcessor
from ......UtilityRoutines import UtilityRoutines
from ......WeatherManager import Weather
from ......Constant import Constant

// Define missing helper functions if not provided by Fmath
def pow_2(x: Float64) -> Float64 {
    return x * x
}
def pow_4(x: Float64) -> Float64 {
    let sq = x * x
    return sq * sq
}

namespace GroundTemp:
    struct FiniteDiffGroundTempsModel(BaseGroundTempsModel):
        static var maxYearsToIterate: Int = 10
        var rhoCp_soil_liq_1: Float64 = 0.0
        var rhoCP_soil_liq: Float64 = 0.0
        var rhoCP_soil_transient: Float64 = 0.0
        var rhoCP_soil_ice: Float64 = 0.0

        var baseConductivity: Float64 = 0.0
        var baseDensity: Float64 = 0.0
        var baseSpecificHeat: Float64 = 0.0
        var totalNumCells: Int = 0
        var timeStepInSeconds: Float64 = 0.0
        var evapotransCoeff: Float64 = 0.0
        var saturatedWaterContent: Float64 = 0.0
        var waterContent: Float64 = 0.0
        var annualAveAirTemp: Float64 = 0.0
        var minDailyAirTemp: Float64 = 100.0  // Set hi. Will be reset later
        var maxDailyAirTemp: Float64 = -100.0 // Set low. Will be reset later
        var dayOfMinDailyAirTemp: Float64 = 1.0
        var depth: Float64 = 0.0
        var simTimeInDays: Float64 = 0.0

        struct instanceOfCellData:
            struct properties:
                var conductivity: Float64 = 0.0
                var density: Float64 = 0.0
                var specificHeat: Float64 = 0.0
                var diffusivity: Float64 = 0.0
                var rhoCp: Float64 = 0.0

            var props: properties
            var index: Int = 0
            var thickness: Float64 = 0.0
            var minZValue: Float64 = 0.0
            var maxZValue: Float64 = 0.0
            var temperature: Float64 = 0.0
            var temperature_prevIteration: Float64 = 0.0
            var temperature_prevTimeStep: Float64 = 0.0
            var temperature_finalConvergence: Float64 = 0.0
            var beta: Float64 = 0.0
            var volume: Float64 = 0.0
            var conductionArea: Float64 = 1.0 // Assumes 1 m2

        var cellArray: List[instanceOfCellData]

        struct instanceOfWeatherData:
            var dryBulbTemp: Float64 = 0.0
            var relativeHumidity: Float64 = 0.0
            var windSpeed: Float64 = 0.0
            var horizontalRadiation: Float64 = 0.0
            var airDensity: Float64 = 0.0

        var weatherDataArray: List[instanceOfWeatherData]

        var groundTemps: List[List[Float64]]  // 2D array (days x cells) 0-based
        var cellDepths: List[Float64]

        enum surfaceTypes:
            surfaceCoverType_bareSoil = 1
            surfaceCoverType_shortGrass = 2
            surfaceCoverType_longGrass = 3

        @staticmethod
        def FiniteDiffGTMFactory(state: EnergyPlusData, objectName: StringRef) -> Pointer[FiniteDiffGroundTempsModel]:
            var found = False
            var thisModel = new FiniteDiffGroundTempsModel()
            var modelType = GroundTemp.ModelType.FiniteDiff
            var cCurrentModuleObject = GroundTemp.modelTypeNames[Int(modelType)]
            var currentModuleObject = String(cCurrentModuleObject)
            var inputProcessor = state.dataInputProcessing.inputProcessor
            var modelInstances = inputProcessor.epJSON.find(currentModuleObject)
            if modelInstances == inputProcessor.epJSON.end():
                ShowFatalError(
                    state,
                    EnergyPlus.format(
                        "{}--Errors getting input for ground temperature model",
                        GroundTemp.modelTypeNames[Int(modelType)]
                    )
                )
            var modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
            for modelInstance in modelInstances.value().items():
                var modelName = Util.makeUPPER(modelInstance.key())
                var modelFields = modelInstance.value()
                if objectName == modelName:
                    inputProcessor.markObjectAsUsed(currentModuleObject, modelInstance.key())
                    thisModel[].modelType = modelType
                    thisModel[].Name = modelName
                    thisModel[].baseConductivity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_thermal_conductivity")
                    thisModel[].baseDensity = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_density")
                    thisModel[].baseSpecificHeat = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_specific_heat")
                    thisModel[].waterContent = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_moisture_content_volume_fraction") / 100.0
                    thisModel[].saturatedWaterContent = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "soil_moisture_content_volume_fraction_at_saturation") / 100.0
                    thisModel[].evapotransCoeff = inputProcessor.getRealFieldValue(modelFields, modelSchemaProps, "evapotranspiration_ground_cover_parameter")
                    found = True
                    break

            if found:
                state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
                thisModel[].initAndSim(state)
                return thisModel

            ShowFatalError(
                state,
                EnergyPlus.format(
                    "{}--Errors getting input for ground temperature model",
                    GroundTemp.modelTypeNames[Int(modelType)]
                )
            )
            return None  // Should not reach

        def initAndSim(inout self, state: EnergyPlusData):
            self.getWeatherData(state)
            self.developMesh()
            self.performSimulation(state)

        def getWeatherData(inout self, state: EnergyPlusData):
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
                ShowSevereError(
                    state,
                    "Site:GroundTemperature:Undisturbed:FiniteDifference -- using this model requires specification of a weather file."
                )
                ShowContinueError(
                    state,
                    "Either place in.epw in the working directory or specify a weather file on the command line using -w /path/to/weather.epw"
                )
                ShowFatalError(state, "Simulation halted due to input error in ground temperature model.")

            var originalNumOfEnvrn = state.dataWeather.NumOfEnvrn
            state.dataWeather.NumOfEnvrn += 1
            state.dataWeather.TotRunPers += 1

            // redimension not directly applicable; we'll resize lists
            state.dataWeather.Environment.resize(state.dataWeather.NumOfEnvrn)
            state.dataWeather.RunPeriodInput.resize(state.dataWeather.TotRunPers)
            state.dataWeather.Environment[state.dataWeather.NumOfEnvrn - 1].KindOfEnvrn = Constant.KindOfSim.ReadAllWeatherData
            state.dataWeather.RPReadAllWeatherData = True
            state.dataGlobal.WeathSimReq = True

            Weather.SetupEnvironmentTypes(state)

            state.dataWeather.Envrn = originalNumOfEnvrn

            var Available = True
            var ErrorsFound = False
            Weather.GetNextEnvironment(state, Available, ErrorsFound)
            if ErrorsFound:
                ShowFatalError(
                    state,
                    "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data"
                )
            if state.dataGlobal.KindOfSim != Constant.KindOfSim.ReadAllWeatherData:
                ShowFatalError(
                    state,
                    "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data, bad KindOfSim."
                )

            self.weatherDataArray = List[instanceOfWeatherData]()
            self.weatherDataArray.resize(state.dataWeather.NumDaysInYear)

            state.dataGlobal.BeginEnvrnFlag = True
            state.dataGlobal.EndEnvrnFlag = False
            state.dataEnvrn.EndMonthFlag = False
            state.dataGlobal.WarmupFlag = False
            state.dataGlobal.DayOfSim = 0
            state.dataGlobal.DayOfSimChr = "0"
            state.dataReportFlag.NumOfWarmupDays = 0

            var annualAveAirTemp_num = 0.0

            while (state.dataGlobal.DayOfSim < state.dataWeather.NumDaysInYear) or (state.dataGlobal.WarmupFlag):
                state.dataGlobal.DayOfSim += 1

                var outDryBulbTemp_num = 0.0
                var relHum_num = 0.0
                var windSpeed_num = 0.0
                var horizSolarRad_num = 0.0
                var airDensity_num = 0.0
                var denominator = 0

                var tdwd = self.weatherDataArray[state.dataGlobal.DayOfSim - 1]  // 0-based
                state.dataGlobal.BeginDayFlag = True
                state.dataGlobal.EndDayFlag = False

                for state.dataGlobal.HourOfDay in range(1, 25):
                    state.dataGlobal.BeginHourFlag = True
                    state.dataGlobal.EndHourFlag = False

                    for state.dataGlobal.TimeStep in range(1, state.dataGlobal.TimeStepsInHour + 1):
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

                tdwd.dryBulbTemp = outDryBulbTemp_num / Float64(denominator)
                tdwd.relativeHumidity = relHum_num / Float64(denominator)
                tdwd.windSpeed = windSpeed_num / Float64(denominator)
                tdwd.horizontalRadiation = horizSolarRad_num / Float64(denominator)
                tdwd.airDensity = airDensity_num / Float64(denominator)

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

        def developMesh(inout self):
            var surfaceLayerThickness: Float64 = 2.0
            var surfaceLayerCellThickness: Float64 = 0.015
            var surfaceLayerNumCells = Int(surfaceLayerThickness / surfaceLayerCellThickness)
            var centerLayerNumCells: Int = 80
            var deepLayerThickness: Float64 = 0.2
            var deepLayerCellThickness: Float64 = surfaceLayerCellThickness
            var deepLayerNumCells = Int(deepLayerThickness / deepLayerCellThickness)

            var currentCellDepth: Float64 = 0.0

            self.totalNumCells = surfaceLayerNumCells + centerLayerNumCells + deepLayerNumCells

            self.cellArray = List[FiniteDiffGroundTempsModel.instanceOfCellData]()
            self.cellArray.resize(self.totalNumCells)
            self.cellDepths = List[Float64]()
            self.cellDepths.resize(self.totalNumCells)

            for i in range(1, self.totalNumCells + 1):
                var thisCell = self.cellArray[i - 1]  // 0-based
                thisCell.index = i

                if i <= surfaceLayerNumCells:
                    thisCell.thickness = surfaceLayerCellThickness
                elif i <= (centerLayerNumCells + surfaceLayerNumCells):
                    var numCenterCell = i - surfaceLayerNumCells
                    if numCenterCell <= (centerLayerNumCells / 2):
                        var centerLayerExpansionCoeff: Float64 = 1.10879
                        thisCell.thickness = surfaceLayerCellThickness * pow(centerLayerExpansionCoeff, Float64(numCenterCell))
                    else:
                        thisCell.thickness = self.cellArray[(surfaceLayerNumCells + (centerLayerNumCells / 2)) - (numCenterCell - (centerLayerNumCells / 2)) - 1].thickness
                else:
                    thisCell.thickness = deepLayerCellThickness

                thisCell.minZValue = currentCellDepth
                self.cellDepths[i - 1] = currentCellDepth + thisCell.thickness / 2.0
                currentCellDepth += thisCell.thickness
                thisCell.maxZValue = currentCellDepth

                thisCell.props.conductivity = self.baseConductivity
                thisCell.props.density = self.baseDensity
                thisCell.props.specificHeat = self.baseSpecificHeat
                thisCell.props.diffusivity = self.baseConductivity / (self.baseDensity * self.baseSpecificHeat)

        def performSimulation(inout self, state: EnergyPlusData):
            self.timeStepInSeconds = Constant.rSecsInDay
            var convergedFinal = False
            self.initDomain(state)

            while not convergedFinal:
                for state.dataGlobal.FDsimDay in range(1, state.dataWeather.NumDaysInYear + 1):
                    var iterationConverged = False
                    self.doStartOfTimeStepInits()
                    while not iterationConverged:
                        for cell in range(1, self.totalNumCells + 1):
                            if cell == 1:
                                self.updateSurfaceCellTemperature(state)
                            elif (cell > 1) and (cell < self.totalNumCells):
                                self.updateGeneralDomainCellTemperature(cell)
                            elif cell == self.totalNumCells:
                                self.updateBottomCellTemperature()
                        iterationConverged = self.checkIterationTemperatureConvergence()
                        if not iterationConverged:
                            self.updateIterationTemperatures()
                    self.updateTimeStepTemperatures(state)
                convergedFinal = self.checkFinalTemperatureConvergence(state)

        def updateSurfaceCellTemperature(inout self, state: EnergyPlusData):
            var numerator = 0.0
            var denominator = 0.0
            var resistance = 0.0
            var G_hr: Float64
            var Cd: Float64
            var rho_water: Float64 = 998.0  // [kg/m3]
            var absor_Corrected: Float64 = 0.77
            var convert_Wm2_To_MJhrmin: Float64 = 3600.0 / 1000000.0
            var convert_MJhrmin_To_Wm2: Float64 = 1.0 / convert_Wm2_To_MJhrmin

            var thisCell = self.cellArray[0]  // cell 1 -> index 0
            var cellBelow_thisCell = self.cellArray[1]
            var cwd = self.weatherDataArray[state.dataGlobal.FDsimDay - 1]

            numerator += thisCell.temperature_prevTimeStep
            denominator += 1.0

            resistance = thisCell.thickness / 2.0 / (thisCell.props.conductivity * thisCell.conductionArea) + cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.props.conductivity * cellBelow_thisCell.conductionArea)
            numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
            denominator += thisCell.beta / resistance

            if cwd.windSpeed > 0.1:
                var airSpecificHeat: Float64 = 1003  // '[J/kg-K]
                resistance = 208.0 / (cwd.airDensity * airSpecificHeat * cwd.windSpeed * thisCell.conductionArea)
            else:
                pass  // resistance unchanged

            numerator += thisCell.beta / resistance * cwd.dryBulbTemp
            denominator += thisCell.beta / resistance

            var currAirTempK: Float64 = cwd.dryBulbTemp + 273.15
            var incidentSolar_MJhrmin: Float64 = cwd.horizontalRadiation * convert_Wm2_To_MJhrmin
            var absorbedIncidentSolar_MJhrmin: Float64 = absor_Corrected * incidentSolar_MJhrmin

            var vaporPressureSaturated_kPa: Float64 = 0.6108 * exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3))
            var vaporPressureActual_kPa: Float64 = vaporPressureSaturated_kPa * cwd.relativeHumidity

            var QRAD_NL: Float64 = 2.042E-10 * pow_4(currAirTempK) * (0.34 - 0.14 * sqrt(vaporPressureActual_kPa))

            var netIncidentRadiation_MJhr: Float64 = absorbedIncidentSolar_MJhrmin - QRAD_NL
            var CN: Float64 = 37.0

            if netIncidentRadiation_MJhr < 0.0:
                G_hr = 0.5 * netIncidentRadiation_MJhr
                Cd = 0.96
            else:
                G_hr = 0.1 * netIncidentRadiation_MJhr
                Cd = 0.24

            var slope_S: Float64 = 2503.0 * exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3)) / pow_2(cwd.dryBulbTemp + 237.3)
            var pressure: Float64 = 98.0
            var psychrometricConstant: Float64 = 0.665e-3 * pressure

            var evapotransFluidLoss_mmhr: Float64 = (self.evapotransCoeff * slope_S * (netIncidentRadiation_MJhr - G_hr) + psychrometricConstant * (CN / currAirTempK) * cwd.windSpeed * (vaporPressureSaturated_kPa - vaporPressureActual_kPa)) / (slope_S + psychrometricConstant * (1 + Cd * cwd.windSpeed))

            var evapotransFluidLoss_mhr: Float64 = evapotransFluidLoss_mmhr / 1000.0
            var latentHeatVaporization: Float64 = 2.501 - 2.361e-3 * thisCell.temperature_prevTimeStep
            var evapotransHeatLoss_MJhrmin: Float64 = rho_water * evapotransFluidLoss_mhr * latentHeatVaporization

            var netIncidentRadiation_Wm2: Float64 = netIncidentRadiation_MJhr * convert_MJhrmin_To_Wm2
            var evapotransHeatLoss_Wm2: Float64 = evapotransHeatLoss_MJhrmin * convert_MJhrmin_To_Wm2
            var incidentHeatGain: Float64 = (netIncidentRadiation_Wm2 - evapotransHeatLoss_Wm2) * thisCell.conductionArea

            numerator += thisCell.beta * incidentHeatGain

            self.cellArray[0].temperature = numerator / denominator

        def updateGeneralDomainCellTemperature(inout self, cell: Int):
            var numerator = 0.0
            var denominator = 0.0
            var resistance = 0.0

            var thisCell = self.cellArray[cell - 1]
            var cellAbove_thisCell = self.cellArray[cell - 2]
            var cellBelow_thisCell = self.cellArray[cell]  // cell+1 -> index cell

            numerator += thisCell.temperature_prevTimeStep
            denominator += 1.0

            resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + cellAbove_thisCell.thickness / 2.0 / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity)
            numerator += thisCell.beta / resistance * cellAbove_thisCell.temperature
            denominator += thisCell.beta / resistance

            resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.conductionArea * cellBelow_thisCell.props.conductivity)
            numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
            denominator += thisCell.beta / resistance

            thisCell.temperature = numerator / denominator

        def updateBottomCellTemperature(inout self):
            var numerator = 0.0
            var denominator = 0.0
            var resistance = 0.0
            var geothermalGradient: Float64 = 0.025  // C/m

            var thisCell = self.cellArray[self.totalNumCells - 1]
            var cellAbove_thisCell = self.cellArray[self.totalNumCells - 2]

            numerator += thisCell.temperature_prevTimeStep
            denominator += 1.0

            resistance = ((thisCell.thickness / 2.0) / (thisCell.conductionArea * thisCell.props.conductivity)) + ((cellAbove_thisCell.thickness / 2.0) / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity))
            numerator += (thisCell.beta / resistance) * cellAbove_thisCell.temperature
            denominator += thisCell.beta / resistance

            var HTBottom: Float64 = geothermalGradient * thisCell.props.conductivity * thisCell.conductionArea
            numerator += thisCell.beta * HTBottom

            self.cellArray[self.totalNumCells - 1].temperature = numerator / denominator

        def checkFinalTemperatureConvergence(inout self, state: EnergyPlusData) -> Bool:
            var converged = True
            var finalTempConvergenceCriteria: Float64 = 0.05

            if state.dataGlobal.FDnumIterYears == self.maxYearsToIterate:
                return converged

            for cell in range(1, self.totalNumCells + 1):
                var thisCell = self.cellArray[cell - 1]
                if abs(thisCell.temperature - thisCell.temperature_finalConvergence) >= finalTempConvergenceCriteria:
                    converged = False
                thisCell.temperature_finalConvergence = thisCell.temperature

            state.dataGlobal.FDnumIterYears += 1
            return converged

        def checkIterationTemperatureConvergence(inout self) -> Bool:
            var converged = True
            var iterationTempConvergenceCriteria: Float64 = 0.00001

            for cell in range(1, self.totalNumCells + 1):
                if abs(self.cellArray[cell - 1].temperature - self.cellArray[cell - 1].temperature_prevIteration) >= iterationTempConvergenceCriteria:
                    converged = False
                    break
            return converged

        def initDomain(inout self, state: EnergyPlusData):
            var tempModel = new KusudaGroundTempsModel()
            tempModel[].Name = "KAModelForFDModel"
            tempModel[].modelType = GroundTemp.ModelType.Kusuda
            tempModel[].aveGroundTemp = self.annualAveAirTemp
            tempModel[].aveGroundTempAmplitude = (self.maxDailyAirTemp - self.minDailyAirTemp) / 4.0
            tempModel[].phaseShiftInSecs = self.dayOfMinDailyAirTemp * Constant.rSecsInDay
            tempModel[].groundThermalDiffusivity = self.baseConductivity / (self.baseDensity * self.baseSpecificHeat)

            for cell in range(1, self.totalNumCells + 1):
                var thisCell = self.cellArray[cell - 1]
                var depth = (thisCell.maxZValue + thisCell.minZValue) / 2.0
                if tempModel:
                    thisCell.temperature = tempModel[].getGroundTempAtTimeInSeconds(state, depth, 0.0)
                thisCell.temperature_finalConvergence = thisCell.temperature
                thisCell.temperature_prevIteration = thisCell.temperature
                thisCell.temperature_prevTimeStep = thisCell.temperature
                thisCell.volume = thisCell.thickness * thisCell.conductionArea

            self.evaluateSoilRhoCpInit()

            // groundTemps: days x cells, 0-based
            self.groundTemps = List[List[Float64]]()
            self.groundTemps.resize(state.dataWeather.NumDaysInYear)
            for i in range(state.dataWeather.NumDaysInYear):
                self.groundTemps[i] = List[Float64]()
                self.groundTemps[i].resize(self.totalNumCells)
                for j in range(self.totalNumCells):
                    self.groundTemps[i][j] = 0.0

            delete tempModel

        def updateIterationTemperatures(inout self):
            for cell in range(1, self.totalNumCells + 1):
                self.cellArray[cell - 1].temperature_prevIteration = self.cellArray[cell - 1].temperature

        def updateTimeStepTemperatures(inout self, state: EnergyPlusData):
            for cell in range(1, self.totalNumCells + 1):
                var thisCell = self.cellArray[cell - 1]
                thisCell.temperature_prevTimeStep = thisCell.temperature
                self.groundTemps[state.dataGlobal.FDsimDay - 1][cell - 1] = thisCell.temperature

        def doStartOfTimeStepInits(inout self):
            for cell in range(1, self.totalNumCells + 1):
                var thisCell = self.cellArray[cell - 1]
                self.evaluateSoilRhoCpCell(cell)
                thisCell.beta = self.timeStepInSeconds / (thisCell.props.rhoCp * thisCell.volume)

        @staticmethod
        def interpolate(x: Float64, x_hi: Float64, x_low: Float64, y_hi: Float64, y_low: Float64) -> Float64:
            return (x - x_low) / (x_hi - x_low) * (y_hi - y_low) + y_low

        def getGroundTemp(inout self, state: EnergyPlusData) -> Float64:
            var i0: Int
            var i1: Int
            var j1: Int

            if self.depth < 0.0:
                self.depth = 0.0

            var it = lower_bound(self.cellDepths.begin(), self.cellDepths.end(), self.depth)
            var j0 = Int(distance(self.cellDepths.begin(), it))  // 0-based index of first element >= depth
            j0 += 1  // adjust to original 1-based index, but we keep 0-based eventually?

            // Actually original code: ++j0 to get 1-based cell index with depth less than y-depth.
            // Then later comparison j0 < totalNumCells - 1 uses 1-based.
            // We'll keep j0 as 1-based here and later convert to 0-based when accessing.

            var dayFrac = self.simTimeInDays - Float64(Int(self.simTimeInDays))

            if j0 < self.totalNumCells - 1:
                j1 = j0 + 1
                if (self.simTimeInDays <= 1.0) or (self.simTimeInDays >= Float64(state.dataWeather.NumDaysInYear)):
                    i0 = state.dataWeather.NumDaysInYear
                    i1 = 1
                    var T_i0_j0 = self.groundTemps[i0 - 1][j0 - 1]
                    var T_i0_j1 = self.groundTemps[i0 - 1][j1 - 1]
                    var T_i1_j0 = self.groundTemps[i1 - 1][j0 - 1]
                    var T_i1_j1 = self.groundTemps[i1 - 1][j1 - 1]
                    var T_ix_j0 = self.interpolate(dayFrac, 1.0, 0.0, T_i1_j0, T_i0_j0)
                    var T_ix_j1 = self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
                    return self.interpolate(self.depth, self.cellDepths[j1 - 1], self.cellDepths[j0 - 1], T_ix_j1, T_ix_j0)
                else:
                    i0 = Int(self.simTimeInDays)
                    i1 = i0 + 1
                    var T_i0_j0 = self.groundTemps[i0 - 1][j0 - 1]
                    var T_i0_j1 = self.groundTemps[i0 - 1][j1 - 1]
                    var T_i1_j0 = self.groundTemps[i1 - 1][j0 - 1]
                    var T_i1_j1 = self.groundTemps[i1 - 1][j1 - 1]
                    var T_ix_j0 = self.interpolate(dayFrac, 1.0, 0.0, T_i1_j0, T_i0_j0)
                    var T_ix_j1 = self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
                    return self.interpolate(self.depth, self.cellDepths[j1 - 1], self.cellDepths[j0 - 1], T_ix_j1, T_ix_j0)
            else:
                j0 = self.totalNumCells
                j1 = j0
                if (self.simTimeInDays <= 1.0) or (self.simTimeInDays >= Float64(state.dataWeather.NumDaysInYear)):
                    i0 = state.dataWeather.NumDaysInYear
                    i1 = 1
                    var T_i0_j1 = self.groundTemps[i0 - 1][j1 - 1]
                    var T_i1_j1 = self.groundTemps[i1 - 1][j1 - 1]
                    return self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)
                else:
                    i0 = Int(self.simTimeInDays)
                    i1 = i0 + 1
                    var T_i0_j1 = self.groundTemps[i0 - 1][j1 - 1]
                    var T_i1_j1 = self.groundTemps[i1 - 1][j1 - 1]
                    return self.interpolate(dayFrac, 1.0, 0.0, T_i1_j1, T_i0_j1)

        def getGroundTempAtTimeInSeconds(inout self, state: EnergyPlusData, _depth: Float64, seconds: Float64) -> Float64:
            self.depth = _depth
            self.simTimeInDays = seconds / Constant.rSecsInDay
            if self.simTimeInDays > Float64(state.dataWeather.NumDaysInYear):
                self.simTimeInDays = fmod(self.simTimeInDays, Float64(state.dataWeather.NumDaysInYear))
            return self.getGroundTemp(state)

        def getGroundTempAtTimeInMonths(inout self, state: EnergyPlusData, _depth: Float64, month: Int) -> Float64:
            var aveDaysInMonth = Float64(state.dataWeather.NumDaysInYear) / 12.0
            self.depth = _depth
            self.simTimeInDays = aveDaysInMonth * (Float64(month - 1) + 0.5)
            if self.simTimeInDays > Float64(state.dataWeather.NumDaysInYear):
                self.simTimeInDays = fmod(self.simTimeInDays, Float64(state.dataWeather.NumDaysInYear))
            return self.getGroundTemp(state)

        def evaluateSoilRhoCpCell(inout self, cell: Int):
            var thisCell = self.cellArray[cell - 1]
            thisCell.props.rhoCp = self.baseDensity * self.baseSpecificHeat
            thisCell.props.specificHeat = thisCell.props.rhoCp / thisCell.props.density

        def evaluateSoilRhoCpInit(inout self):
            var Theta_liq = self.waterContent
            var Theta_sat = self.saturatedWaterContent
            var Theta_ice = Theta_liq
            var rho_ice: Float64 = 917.0  // 'Kg / m3
            var rho_liq: Float64 = 1000.0 // 'kg / m3
            self.rhoCp_soil_liq_1 = 1225000.0 / (1.0 - Theta_sat)  // J/m3K
            var CP_liq: Float64 = 4180.0    // 'J / KgK
            var CP_ice: Float64 = 2066.0    // 'J / KgK
            var Lat_fus: Float64 = 334000.0 // 'J / Kg
            var Cp_transient: Float64 = Lat_fus / 0.4 + (0.5 * CP_ice - (CP_liq + CP_ice) / 2.0 * 0.1) / 0.4
            self.rhoCP_soil_liq = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_liq * CP_liq * Theta_liq
            self.rhoCP_soil_transient = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + ((rho_liq + rho_ice) / 2.0) * Cp_transient * Theta_ice
            self.rhoCP_soil_ice = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_ice * CP_ice * Theta_ice  //'!J / m3K