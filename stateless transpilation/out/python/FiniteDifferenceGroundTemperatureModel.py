# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object with .dataWeather, .dataGlobal, .dataEnvrn, .dataReportFlag, .dataGrndTempModelMgr, .dataInputProcessing
# - BaseGroundTempsModel: base class (parent)
# - KusudaGroundTempsModel: class for temporary initialization model
# - GroundTemp.ModelType: enum with .FiniteDiff, .Kusuda
# - GroundTemp.modelTypeNames: array/dict mapping model type to string names
# - Constant: namespace with .rSecsInDay, .KindOfSim (enum)
# - Weather.SetupEnvironmentTypes, Weather.GetNextEnvironment, Weather.ManageWeather: functions
# - ShowFatalError, ShowSevereError, ShowContinueError: error reporting functions
# - Util.makeUPPER: string upper conversion
# - EnergyPlus.format: string formatting (printf-style)
# Origin: EnergyPlus/GroundTemperatureModeling/FiniteDifferenceGroundTemperatureModel

from typing import Protocol, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import math
import bisect


# Stubs for external dependencies
class EnergyPlusData(Protocol):
    class DataWeather(Protocol):
        Envrn: int
        NumOfEnvrn: int
        TotRunPers: int
        NumDaysInYear: int
        WeatherFileExists: bool
        RPReadAllWeatherData: bool
        Environment: list
        RunPeriodInput: list
    
    class DataGlobal(Protocol):
        KindOfSim: int
        TimeStep: int
        HourOfDay: int
        BeginEnvrnFlag: bool
        EndEnvrnFlag: bool
        WarmupFlag: bool
        DayOfSim: int
        DayOfSimChr: str
        BeginDayFlag: bool
        EndDayFlag: bool
        BeginHourFlag: bool
        EndHourFlag: bool
        BeginTimeStepFlag: bool
        TimeStepsInHour: int
        NumOfDayInEnvrn: int
        PreviousHour: int
        BeginSimFlag: bool
        FDsimDay: int
        FDnumIterYears: int
        WeathSimReq: bool
    
    class DataEnvrn(Protocol):
        OutDryBulbTemp: float
        OutRelHumValue: float
        OutAirDensity: float
        WindSpeed: float
        SOLCOS: List[float]
        BeamSolarRad: float
        DifSolarRad: float
        EndMonthFlag: bool
    
    class DataReportFlag(Protocol):
        NumOfWarmupDays: int
    
    class DataGrndTempModelMgr(Protocol):
        groundTempModels: list
    
    class DataInputProcessing(Protocol):
        inputProcessor: object
    
    dataWeather: DataWeather
    dataGlobal: DataGlobal
    dataEnvrn: DataEnvrn
    dataReportFlag: DataReportFlag
    dataGrndTempModelMgr: DataGrndTempModelMgr
    dataInputProcessing: DataInputProcessing


class BaseGroundTempsModel(Protocol):
    Name: str
    modelType: int


class KusudaGroundTempsModel(Protocol):
    Name: str
    modelType: int
    aveGroundTemp: float
    aveGroundTempAmplitude: float
    phaseShiftInSecs: float
    groundThermalDiffusivity: float
    
    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, depth: float, time_sec: float) -> float:
        ...


def ShowFatalError(state: EnergyPlusData, msg: str) -> None:
    raise RuntimeError(msg)


def ShowSevereError(state: EnergyPlusData, msg: str) -> None:
    pass


def ShowContinueError(state: EnergyPlusData, msg: str) -> None:
    pass


class Weather:
    @staticmethod
    def SetupEnvironmentTypes(state: EnergyPlusData) -> None:
        pass
    
    @staticmethod
    def GetNextEnvironment(state: EnergyPlusData, available: bool, errors_found: bool) -> Tuple[bool, bool]:
        return available, errors_found
    
    @staticmethod
    def ManageWeather(state: EnergyPlusData) -> None:
        pass


class Util:
    @staticmethod
    def makeUPPER(s: str) -> str:
        return s.upper()


def format_string(fmt: str, *args) -> str:
    return fmt.format(*args)


# Main class and nested structures
@dataclass
class InstanceOfWeatherData:
    dryBulbTemp: float = 0.0
    relativeHumidity: float = 0.0
    windSpeed: float = 0.0
    horizontalRadiation: float = 0.0
    airDensity: float = 0.0


@dataclass
class CellProperties:
    conductivity: float = 0.0
    density: float = 0.0
    specificHeat: float = 0.0
    diffusivity: float = 0.0
    rhoCp: float = 0.0


@dataclass
class InstanceOfCellData:
    props: CellProperties = field(default_factory=CellProperties)
    index: int = 0
    thickness: float = 0.0
    minZValue: float = 0.0
    maxZValue: float = 0.0
    temperature: float = 0.0
    temperature_prevIteration: float = 0.0
    temperature_prevTimeStep: float = 0.0
    temperature_finalConvergence: float = 0.0
    beta: float = 0.0
    volume: float = 0.0
    conductionArea: float = 1.0


class SurfaceTypes(Enum):
    surfaceCoverType_bareSoil = 1
    surfaceCoverType_shortGrass = 2
    surfaceCoverType_longGrass = 3


class FiniteDiffGroundTempsModel(BaseGroundTempsModel):
    maxYearsToIterate = 10
    
    def __init__(self):
        self.Name: str = ""
        self.modelType: int = 0
        self.rhoCp_soil_liq_1: float = 0.0
        self.rhoCP_soil_liq: float = 0.0
        self.rhoCP_soil_transient: float = 0.0
        self.rhoCP_soil_ice: float = 0.0
        
        self.baseConductivity: float = 0.0
        self.baseDensity: float = 0.0
        self.baseSpecificHeat: float = 0.0
        self.totalNumCells: int = 0
        self.timeStepInSeconds: float = 0.0
        self.evapotransCoeff: float = 0.0
        self.saturatedWaterContent: float = 0.0
        self.waterContent: float = 0.0
        self.annualAveAirTemp: float = 0.0
        self.minDailyAirTemp: float = 100.0
        self.maxDailyAirTemp: float = -100.0
        self.dayOfMinDailyAirTemp: float = 1.0
        self.depth: float = 0.0
        self.simTimeInDays: float = 0.0
        
        self.cellArray: List[InstanceOfCellData] = []
        self.weatherDataArray: List[InstanceOfWeatherData] = []
        self.groundTemps: List[List[float]] = []
        self.cellDepths: List[float] = []
    
    @staticmethod
    def FiniteDiffGTMFactory(state: EnergyPlusData, objectName: str) -> Optional['FiniteDiffGroundTempsModel']:
        found = False
        thisModel = FiniteDiffGroundTempsModel()
        
        modelType = 0  # GroundTemp.ModelType.FiniteDiff
        cCurrentModuleObject = "Site:GroundTemperature:Undisturbed:FiniteDifference"
        currentModuleObject = cCurrentModuleObject
        
        inputProcessor = state.dataInputProcessing.inputProcessor
        modelInstances = inputProcessor.epJSON.get(currentModuleObject)
        
        if modelInstances is None:
            ShowFatalError(state, f"{cCurrentModuleObject}--Errors getting input for ground temperature model")
        
        modelSchemaProps = inputProcessor.getObjectSchemaProps(state, currentModuleObject)
        
        for modelInstance_key, modelFields in modelInstances.items():
            modelName = Util.makeUPPER(modelInstance_key)
            
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
            state.dataGrndTempModelMgr.groundTempModels.append(thisModel)
            thisModel.initAndSim(state)
            return thisModel
        
        ShowFatalError(state, f"{cCurrentModuleObject}--Errors getting input for ground temperature model")
        return None
    
    def initAndSim(self, state: EnergyPlusData) -> None:
        self.getWeatherData(state)
        self.developMesh()
        self.performSimulation(state)
    
    def getWeatherData(self, state: EnergyPlusData) -> None:
        Envrn_reset = state.dataWeather.Envrn
        KindOfSim_reset = state.dataGlobal.KindOfSim
        TimeStep_reset = state.dataGlobal.TimeStep
        HourOfDay_reset = state.dataGlobal.HourOfDay
        BeginEnvrnFlag_reset = state.dataGlobal.BeginEnvrnFlag
        EndEnvrnFlag_reset = state.dataGlobal.EndEnvrnFlag
        EndMonthFlag_reset = state.dataEnvrn.EndMonthFlag
        WarmupFlag_reset = state.dataGlobal.WarmupFlag
        DayOfSim_reset = state.dataGlobal.DayOfSim
        DayOfSimChr_reset = state.dataGlobal.DayOfSimChr
        NumOfWarmupDays_reset = state.dataReportFlag.NumOfWarmupDays
        BeginDayFlag_reset = state.dataGlobal.BeginDayFlag
        EndDayFlag_reset = state.dataGlobal.EndDayFlag
        BeginHourFlag_reset = state.dataGlobal.BeginHourFlag
        EndHourFlag_reset = state.dataGlobal.EndHourFlag
        
        if not state.dataWeather.WeatherFileExists:
            ShowSevereError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference -- using this model requires specification of a weather file.")
            ShowContinueError(state, "Either place in.epw in the working directory or specify a weather file on the command line using -w /path/to/weather.epw")
            ShowFatalError(state, "Simulation halted due to input error in ground temperature model.")
        
        originalNumOfEnvrn = state.dataWeather.NumOfEnvrn
        state.dataWeather.NumOfEnvrn += 1
        state.dataWeather.TotRunPers += 1
        state.dataWeather.Environment = state.dataWeather.Environment[:state.dataWeather.NumOfEnvrn-1] + [None]
        state.dataWeather.RunPeriodInput = state.dataWeather.RunPeriodInput[:state.dataWeather.TotRunPers-1] + [None]
        state.dataWeather.Environment[state.dataWeather.NumOfEnvrn - 1] = {"KindOfEnvrn": 5}  # ReadAllWeatherData
        state.dataWeather.RPReadAllWeatherData = True
        state.dataGlobal.WeathSimReq = True
        
        Weather.SetupEnvironmentTypes(state)
        
        state.dataWeather.Envrn = originalNumOfEnvrn
        Available = True
        ErrorsFound = False
        Available, ErrorsFound = Weather.GetNextEnvironment(state, Available, ErrorsFound)
        if ErrorsFound:
            ShowFatalError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data")
        
        if state.dataGlobal.KindOfSim != 5:  # ReadAllWeatherData
            ShowFatalError(state, "Site:GroundTemperature:Undisturbed:FiniteDifference: error in reading weather file data, bad KindOfSim.")
        
        self.weatherDataArray = [InstanceOfWeatherData() for _ in range(state.dataWeather.NumDaysInYear)]
        
        state.dataGlobal.BeginEnvrnFlag = True
        state.dataGlobal.EndEnvrnFlag = False
        state.dataEnvrn.EndMonthFlag = False
        state.dataGlobal.WarmupFlag = False
        state.dataGlobal.DayOfSim = 0
        state.dataGlobal.DayOfSimChr = "0"
        state.dataReportFlag.NumOfWarmupDays = 0
        
        annualAveAirTemp_num = 0.0
        
        while (state.dataGlobal.DayOfSim < state.dataWeather.NumDaysInYear) or state.dataGlobal.WarmupFlag:
            state.dataGlobal.DayOfSim += 1
            
            outDryBulbTemp_num = 0.0
            relHum_num = 0.0
            windSpeed_num = 0.0
            horizSolarRad_num = 0.0
            airDensity_num = 0.0
            denominator = 0
            
            tdwd = self.weatherDataArray[state.dataGlobal.DayOfSim - 1]
            
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
                            if not state.dataGlobal.WarmupFlag and (state.dataGlobal.DayOfSim == state.dataGlobal.NumOfDayInEnvrn):
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
            
            annualAveAirTemp_num += tdwd.dryBulbTemp
            
            if tdwd.dryBulbTemp < self.minDailyAirTemp:
                self.minDailyAirTemp = tdwd.dryBulbTemp
                self.dayOfMinDailyAirTemp = state.dataGlobal.DayOfSim
            
            if tdwd.dryBulbTemp > self.maxDailyAirTemp:
                self.maxDailyAirTemp = tdwd.dryBulbTemp
        
        self.annualAveAirTemp = annualAveAirTemp_num / state.dataWeather.NumDaysInYear
        
        state.dataWeather.NumOfEnvrn -= 1
        state.dataWeather.TotRunPers -= 1
        state.dataGlobal.KindOfSim = KindOfSim_reset
        state.dataWeather.RPReadAllWeatherData = False
        state.dataWeather.Environment = state.dataWeather.Environment[:state.dataWeather.NumOfEnvrn]
        state.dataWeather.RunPeriodInput = state.dataWeather.RunPeriodInput[:state.dataWeather.TotRunPers]
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
    
    def developMesh(self) -> None:
        surfaceLayerThickness = 2.0
        surfaceLayerCellThickness = 0.015
        surfaceLayerNumCells = int(surfaceLayerThickness / surfaceLayerCellThickness)
        
        centerLayerNumCells = 80
        
        deepLayerThickness = 0.2
        deepLayerCellThickness = surfaceLayerCellThickness
        deepLayerNumCells = int(deepLayerThickness / deepLayerCellThickness)
        
        currentCellDepth = 0.0
        
        self.totalNumCells = surfaceLayerNumCells + centerLayerNumCells + deepLayerNumCells
        
        self.cellArray = [InstanceOfCellData() for _ in range(self.totalNumCells)]
        self.cellDepths = [0.0] * self.totalNumCells
        
        for i in range(self.totalNumCells):
            thisCell = self.cellArray[i]
            thisCell.index = i + 1
            
            if i < surfaceLayerNumCells:
                thisCell.thickness = surfaceLayerCellThickness
            elif i < (centerLayerNumCells + surfaceLayerNumCells):
                numCenterCell = i - surfaceLayerNumCells + 1
                
                if numCenterCell <= (centerLayerNumCells / 2):
                    centerLayerExpansionCoeff = 1.10879
                    thisCell.thickness = surfaceLayerCellThickness * (centerLayerExpansionCoeff ** numCenterCell)
                else:
                    thisCell.thickness = self.cellArray[(surfaceLayerNumCells + (centerLayerNumCells // 2)) - (numCenterCell - (centerLayerNumCells // 2)) - 1].thickness
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
    
    def performSimulation(self, state: EnergyPlusData) -> None:
        self.timeStepInSeconds = 86400.0  # Constant.rSecsInDay
        convergedFinal = False
        
        self.initDomain(state)
        
        while not convergedFinal:
            for state.dataGlobal.FDsimDay in range(1, state.dataWeather.NumDaysInYear + 1):
                iterationConverged = False
                
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
    
    def updateSurfaceCellTemperature(self, state: EnergyPlusData) -> None:
        numerator = 0.0
        denominator = 0.0
        resistance = 0.0
        
        rho_water = 998.0
        absor_Corrected = 0.77
        convert_Wm2_To_MJhrmin = 3600.0 / 1000000.0
        convert_MJhrmin_To_Wm2 = 1.0 / convert_Wm2_To_MJhrmin
        
        thisCell = self.cellArray[0]
        cellBelow_thisCell = self.cellArray[1]
        cwd = self.weatherDataArray[state.dataGlobal.FDsimDay - 1]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1
        
        resistance = thisCell.thickness / 2.0 / (thisCell.props.conductivity * thisCell.conductionArea) + \
                     cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.props.conductivity * cellBelow_thisCell.conductionArea)
        numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        if cwd.windSpeed > 0.1:
            airSpecificHeat = 1003
            resistance = 208.0 / (cwd.airDensity * airSpecificHeat * cwd.windSpeed * thisCell.conductionArea)
        
        numerator += thisCell.beta / resistance * cwd.dryBulbTemp
        denominator += thisCell.beta / resistance
        
        currAirTempK = cwd.dryBulbTemp + 273.15
        incidentSolar_MJhrmin = cwd.horizontalRadiation * convert_Wm2_To_MJhrmin
        absorbedIncidentSolar_MJhrmin = absor_Corrected * incidentSolar_MJhrmin
        
        vaporPressureSaturated_kPa = 0.6108 * math.exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3))
        vaporPressureActual_kPa = vaporPressureSaturated_kPa * cwd.relativeHumidity
        
        QRAD_NL = 2.042E-10 * (currAirTempK ** 4) * (0.34 - 0.14 * math.sqrt(vaporPressureActual_kPa))
        netIncidentRadiation_MJhr = absorbedIncidentSolar_MJhrmin - QRAD_NL
        
        CN = 37.0
        
        if netIncidentRadiation_MJhr < 0.0:
            G_hr = 0.5 * netIncidentRadiation_MJhr
            Cd = 0.96
        else:
            G_hr = 0.1 * netIncidentRadiation_MJhr
            Cd = 0.24
        
        slope_S = 2503.0 * math.exp(17.27 * cwd.dryBulbTemp / (cwd.dryBulbTemp + 237.3)) / ((cwd.dryBulbTemp + 237.3) ** 2)
        pressure = 98.0
        psychrometricConstant = 0.665e-3 * pressure
        
        evapotransFluidLoss_mmhr = (evapotransCoeff * slope_S * (netIncidentRadiation_MJhr - G_hr) +
                                     psychrometricConstant * (CN / currAirTempK) * cwd.windSpeed * (vaporPressureSaturated_kPa - vaporPressureActual_kPa)) / \
                                    (slope_S + psychrometricConstant * (1 + Cd * cwd.windSpeed))
        
        evapotransFluidLoss_mhr = evapotransFluidLoss_mmhr / 1000.0
        latentHeatVaporization = 2.501 - 2.361e-3 * thisCell.temperature_prevTimeStep
        evapotransHeatLoss_MJhrmin = rho_water * evapotransFluidLoss_mhr * latentHeatVaporization
        
        netIncidentRadiation_Wm2 = netIncidentRadiation_MJhr * convert_MJhrmin_To_Wm2
        evapotransHeatLoss_Wm2 = evapotransHeatLoss_MJhrmin * convert_MJhrmin_To_Wm2
        
        incidentHeatGain = (netIncidentRadiation_Wm2 - evapotransHeatLoss_Wm2) * thisCell.conductionArea
        numerator += thisCell.beta * incidentHeatGain
        
        self.cellArray[0].temperature = numerator / denominator
    
    def updateGeneralDomainCellTemperature(self, cell: int) -> None:
        numerator = 0.0
        denominator = 0.0
        resistance = 0.0
        
        thisCell = self.cellArray[cell]
        cellAbove_thisCell = self.cellArray[cell - 1]
        cellBelow_thisCell = self.cellArray[cell + 1]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1
        
        resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     cellAbove_thisCell.thickness / 2.0 / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity)
        
        numerator += thisCell.beta / resistance * cellAbove_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        resistance = thisCell.thickness / 2.0 / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     cellBelow_thisCell.thickness / 2.0 / (cellBelow_thisCell.conductionArea * cellBelow_thisCell.props.conductivity)
        
        numerator += thisCell.beta / resistance * cellBelow_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        thisCell.temperature = numerator / denominator
    
    def updateBottomCellTemperature(self) -> None:
        numerator = 0.0
        denominator = 0.0
        resistance = 0.0
        geothermalGradient = 0.025
        
        thisCell = self.cellArray[self.totalNumCells - 1]
        cellAbove_thisCell = self.cellArray[self.totalNumCells - 2]
        
        numerator += thisCell.temperature_prevTimeStep
        denominator += 1
        
        resistance = (thisCell.thickness / 2.0) / (thisCell.conductionArea * thisCell.props.conductivity) + \
                     (cellAbove_thisCell.thickness / 2.0) / (cellAbove_thisCell.conductionArea * cellAbove_thisCell.props.conductivity)
        
        numerator += (thisCell.beta / resistance) * cellAbove_thisCell.temperature
        denominator += thisCell.beta / resistance
        
        HTBottom = geothermalGradient * thisCell.props.conductivity * thisCell.conductionArea
        numerator += thisCell.beta * HTBottom
        
        self.cellArray[self.totalNumCells - 1].temperature = numerator / denominator
    
    def checkFinalTemperatureConvergence(self, state: EnergyPlusData) -> bool:
        converged = True
        finalTempConvergenceCriteria = 0.05
        
        if state.dataGlobal.FDnumIterYears == self.maxYearsToIterate:
            return converged
        
        for cell in range(self.totalNumCells):
            thisCell = self.cellArray[cell]
            
            if abs(thisCell.temperature - thisCell.temperature_finalConvergence) >= finalTempConvergenceCriteria:
                converged = False
            
            thisCell.temperature_finalConvergence = thisCell.temperature
        
        state.dataGlobal.FDnumIterYears += 1
        
        return converged
    
    def checkIterationTemperatureConvergence(self) -> bool:
        converged = True
        iterationTempConvergenceCriteria = 0.00001
        
        for cell in range(self.totalNumCells):
            if abs(self.cellArray[cell].temperature - self.cellArray[cell].temperature_prevIteration) >= iterationTempConvergenceCriteria:
                converged = False
                break
        
        return converged
    
    def initDomain(self, state: EnergyPlusData) -> None:
        tempModel = KusudaGroundTempsModel()
        tempModel.Name = "KAModelForFDModel"
        tempModel.modelType = 1  # GroundTemp.ModelType.Kusuda
        tempModel.aveGroundTemp = self.annualAveAirTemp
        tempModel.aveGroundTempAmplitude = (self.maxDailyAirTemp - self.minDailyAirTemp) / 4.0
        tempModel.phaseShiftInSecs = self.dayOfMinDailyAirTemp * 86400.0  # Constant.rSecsInDay
        tempModel.groundThermalDiffusivity = self.baseConductivity / (self.baseDensity * self.baseSpecificHeat)
        
        for cell in range(self.totalNumCells):
            thisCell = self.cellArray[cell]
            
            depth = (thisCell.maxZValue + thisCell.minZValue) / 2.0
            
            if tempModel:
                thisCell.temperature = tempModel.getGroundTempAtTimeInSeconds(state, depth, 0.0)
            thisCell.temperature_finalConvergence = thisCell.temperature
            thisCell.temperature_prevIteration = thisCell.temperature
            thisCell.temperature_prevTimeStep = thisCell.temperature
            
            thisCell.volume = thisCell.thickness * thisCell.conductionArea
        
        self.evaluateSoilRhoCpInit()
        
        self.groundTemps = [[0.0] * self.totalNumCells for _ in range(state.dataWeather.NumDaysInYear)]
        
        tempModel = None
    
    def updateIterationTemperatures(self) -> None:
        for cell in range(self.totalNumCells):
            self.cellArray[cell].temperature_prevIteration = self.cellArray[cell].temperature
    
    def updateTimeStepTemperatures(self, state: EnergyPlusData) -> None:
        for cell in range(self.totalNumCells):
            thisCell = self.cellArray[cell]
            thisCell.temperature_prevTimeStep = thisCell.temperature
            self.groundTemps[state.dataGlobal.FDsimDay - 1][cell] = thisCell.temperature
    
    def doStartOfTimeStepInits(self) -> None:
        for cell in range(self.totalNumCells):
            thisCell = self.cellArray[cell]
            self.evaluateSoilRhoCpCell(cell)
            thisCell.beta = (self.timeStepInSeconds / (thisCell.props.rhoCp * thisCell.volume))
    
    @staticmethod
    def interpolate(x: float, x_hi: float, x_low: float, y_hi: float, y_low: float) -> float:
        return (x - x_low) / (x_hi - x_low) * (y_hi - y_low) + y_low
    
    def getGroundTemp(self, state: EnergyPlusData) -> float:
        if self.depth < 0.0:
            self.depth = 0.0
        
        it = bisect.bisect_left(self.cellDepths, self.depth)
        j0 = it
        j0 += 1
        
        dayFrac = self.simTimeInDays - int(self.simTimeInDays)
        
        if j0 < self.totalNumCells - 1:
            j1 = j0 + 1
            
            if self.simTimeInDays <= 1 or self.simTimeInDays >= state.dataWeather.NumDaysInYear:
                i0 = state.dataWeather.NumDaysInYear - 1
                i1 = 0
                
                T_i0_j0 = self.groundTemps[i0][j0]
                T_i0_j1 = self.groundTemps[i0][j1]
                T_i1_j0 = self.groundTemps[i1][j0]
                T_i1_j1 = self.groundTemps[i1][j1]
                
                T_ix_j0 = self.interpolate(dayFrac, 1, 0, T_i1_j0, T_i0_j0)
                T_ix_j1 = self.interpolate(dayFrac, 1, 0, T_i1_j1, T_i0_j1)
                
                return self.interpolate(self.depth, self.cellDepths[j1], self.cellDepths[j0], T_ix_j1, T_ix_j0)
            
            i0 = int(self.simTimeInDays) - 1
            i1 = i0 + 1
            
            T_i0_j0 = self.groundTemps[i0][j0]
            T_i0_j1 = self.groundTemps[i0][j1]
            T_i1_j0 = self.groundTemps[i1][j0]
            T_i1_j1 = self.groundTemps[i1][j1]
            
            T_ix_j0 = self.interpolate(dayFrac, 1, 0, T_i1_j0, T_i0_j0)
            T_ix_j1 = self.interpolate(dayFrac, 1, 0, T_i1_j1, T_i0_j1)
            
            return self.interpolate(self.depth, self.cellDepths[j1], self.cellDepths[j0], T_ix_j1, T_ix_j0)
        
        j0 = self.totalNumCells - 1
        j1 = j0
        
        if self.simTimeInDays <= 1 or self.simTimeInDays >= state.dataWeather.NumDaysInYear:
            i0 = state.dataWeather.NumDaysInYear - 1
            i1 = 0
            
            T_i0_j1 = self.groundTemps[i0][j1]
            T_i1_j1 = self.groundTemps[i1][j1]
            
            return self.interpolate(dayFrac, 1, 0, T_i1_j1, T_i0_j1)
        
        i0 = int(self.simTimeInDays) - 1
        i1 = i0 + 1
        
        T_i0_j1 = self.groundTemps[i0][j1]
        T_i1_j1 = self.groundTemps[i1][j1]
        
        return self.interpolate(dayFrac, 1, 0, T_i1_j1, T_i0_j1)
    
    def getGroundTempAtTimeInSeconds(self, state: EnergyPlusData, _depth: float, seconds: float) -> float:
        self.depth = _depth
        self.simTimeInDays = seconds / 86400.0  # Constant.rSecsInDay
        
        if self.simTimeInDays > state.dataWeather.NumDaysInYear:
            self.simTimeInDays = self.simTimeInDays % state.dataWeather.NumDaysInYear
        
        return self.getGroundTemp(state)
    
    def getGroundTempAtTimeInMonths(self, state: EnergyPlusData, _depth: float, month: int) -> float:
        aveDaysInMonth = state.dataWeather.NumDaysInYear / 12
        
        self.depth = _depth
        self.simTimeInDays = aveDaysInMonth * ((month - 1) + 0.5)
        
        if self.simTimeInDays > state.dataWeather.NumDaysInYear:
            self.simTimeInDays = self.simTimeInDays % state.dataWeather.NumDaysInYear
        
        return self.getGroundTemp(state)
    
    def evaluateSoilRhoCpCell(self, cell: int) -> None:
        thisCell = self.cellArray[cell]
        thisCell.props.rhoCp = self.baseDensity * self.baseSpecificHeat
        thisCell.props.specificHeat = thisCell.props.rhoCp / thisCell.props.density
    
    def evaluateSoilRhoCpInit(self) -> None:
        Theta_liq = self.waterContent
        Theta_sat = self.saturatedWaterContent
        Theta_ice = Theta_liq
        
        rho_ice = 917.0
        rho_liq = 1000.0
        self.rhoCp_soil_liq_1 = 1225000.0 / (1.0 - Theta_sat)
        CP_liq = 4180.0
        CP_ice = 2066.0
        Lat_fus = 334000.0
        Cp_transient = Lat_fus / 0.4 + (0.5 * CP_ice - (CP_liq + CP_ice) / 2.0 * 0.1) / 0.4
        self.rhoCP_soil_liq = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_liq * CP_liq * Theta_liq
        self.rhoCP_soil_transient = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + ((rho_liq + rho_ice) / 2.0) * Cp_transient * Theta_ice
        self.rhoCP_soil_ice = self.rhoCp_soil_liq_1 * (1.0 - Theta_sat) + rho_ice * CP_ice * Theta_ice
