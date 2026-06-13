from ...Data.EnergyPlusData import EnergyPlusData
from ...DataSurfaces import SurfaceData
from ...DataEnvironment import DataEnvironment
from ...DataHVACGlobals import DataHVACGlobals
from ...DataHeatBalance import DataHeatBalance
from ...DataIPShortCuts import DataIPShortCuts
from ...ElectricPowerServiceManager import ElectricPowerServiceManager
from ...General import General
from ...InputProcessing.InputProcessor import InputProcessor
from ...OutputProcessor import OutputProcessor, SetupOutputVariable, TimeStepType, StoreType, Group, EndUseCat
from ...UtilityRoutines import FindItemInList, ShowSevereError, ShowFatalError, ShowWarningMessage, ShowErrorMessage
from ...WeatherManager import WeatherManager
from ......third_party.ssc.ssc.sscapi import (
    ssc_module_t, ssc_data_t, ssc_module_create, ssc_data_create, ssc_data_set_number,
    ssc_module_exec, ssc_module_log, ssc_data_get_number,
    SSC_WARNING, SSC_ERROR
)
from math import isfinite

alias Real64 = Float64
alias int = Int

enum ModuleType: Int32 {
    Invalid = -1,
    STANDARD = 0,
    PREMIUM = 1,
    THIN_FILM = 2,
    Num = 3
}

enum ArrayType: Int32 {
    Invalid = -1,
    FIXED_OPEN_RACK = 0,
    FIXED_ROOF_MOUNTED = 1,
    ONE_AXIS = 2,
    ONE_AXIS_BACKTRACKING = 3,
    TWO_AXIS = 4,
    Num = 5
}

enum GeometryType: Int32 {
    Invalid = -1,
    TILT_AZIMUTH = 0,
    SURFACE = 1,
    Num = 2
}

struct DCPowerOutput:
    var poa: Real64  # Plane of array irradiance
    var tpoa: Real64 # Transmitted plane of array irradiance
    var pvt: Real64  # PV Cell temperature
    var dc: Real64   # DC power output

struct IrradianceOutput:
    var solazi: Real64
    var solzen: Real64
    var solalt: Real64
    var aoi: Real64
    var stilt: Real64
    var sazi: Real64
    var rot: Real64
    var btd: Real64
    var ibeam: Real64
    var iskydiff: Real64
    var ignddiff: Real64
    var sunup: Int

@value
class PVWattsGenerator:
    private:
        # enum AlphaFields
        const NAME: Int = 0
        const VERSION: Int = 1
        const MODULE_TYPE: Int = 2
        const ARRAY_TYPE: Int = 3
        const GEOMETRY_TYPE: Int = 4
        const SURFACE_NAME: Int = 5

        # enum NumFields
        const DC_SYSTEM_CAPACITY: Int = 0
        const SYSTEM_LOSSES: Int = 1
        const TILT_ANGLE: Int = 2
        const AZIMUTH_ANGLE: Int = 3
        const GROUND_COVERAGE_RATIO: Int = 4

        var name_: String
        var dcSystemCapacity_: Real64
        var moduleType_: ModuleType
        var arrayType_: ArrayType
        var systemLosses_: Real64
        var geometryType_: GeometryType
        var tilt_: Real64
        var azimuth_: Real64
        var surfaceNum_: Int
        var groundCoverageRatio_: Real64
        var DCtoACRatio_: Real64
        var inverterEfficiency_: Real64
        var outputDCPower_: Real64
        var outputDCEnergy_: Real64
        var outputACPower_: Real64
        var outputACEnergy_: Real64
        var cellTemperature_: Real64
        var planeOfArrayIrradiance_: Real64
        var shadedPercent_: Real64
        var pvwattsModule_: ssc_module_t
        var pvwattsData_: ssc_data_t
        var NumTimeStepsToday_: Real64

    public:
        @staticmethod
        def createFromIdfObj(state: EnergyPlusData, objNum: Int) -> PVWattsGenerator:
            var cAlphaFieldNames = List[String](6)
            var cNumericFieldNames = List[String](5)
            var lNumericFieldBlanks = List[Bool](5)
            var lAlphaFieldBlanks = List[Bool](6)
            var cAlphaArgs = List[String](6)
            var rNumericArgs = List[Real64](5)
            const maxAlphas: Int = 6  # from idd
            const maxNumeric: Int = 5 # from idd
            var NumAlphas: Int = 0
            var NumNums: Int = 0
            var IOStat: Int = 0
            var errorsFound: Bool = False
            state.dataInputProcessing.inputProcessor.getObjectItem(
                state,
                "Generator:PVWatts",
                objNum,
                cAlphaArgs,
                NumAlphas,
                rNumericArgs,
                NumNums,
                IOStat,
                lNumericFieldBlanks,
                lAlphaFieldBlanks,
                cAlphaFieldNames,
                cNumericFieldNames
            )
            let name = cAlphaArgs[PVWattsGenerator.NAME]
            let dcSystemCapacity = rNumericArgs[PVWattsGenerator.DC_SYSTEM_CAPACITY]
            var moduleTypeMap: Dict[String, ModuleType] = {
                "STANDARD": ModuleType.STANDARD,
                "PREMIUM": ModuleType.PREMIUM,
                "THINFILM": ModuleType.THIN_FILM
            }
            var moduleType: ModuleType
            let moduleTypeIt = moduleTypeMap.get(cAlphaArgs[PVWattsGenerator.MODULE_TYPE])
            if moduleTypeIt == None:
                ShowSevereError(state, f"PVWatts: Invalid Module Type: {cAlphaArgs[PVWattsGenerator.MODULE_TYPE]}")
                errorsFound = True
            else:
                moduleType = moduleTypeIt.
            var arrayTypeMap: Dict[String, ArrayType] = {
                "FIXEDOPENRACK": ArrayType.FIXED_OPEN_RACK,
                "FIXEDROOFMOUNTED": ArrayType.FIXED_ROOF_MOUNTED,
                "ONEAXIS": ArrayType.ONE_AXIS,
                "ONEAXISBACKTRACKING": ArrayType.ONE_AXIS_BACKTRACKING,
                "TWOAXIS": ArrayType.TWO_AXIS
            }
            var arrayType: ArrayType
            let arrayTypeIt = arrayTypeMap.get(cAlphaArgs[PVWattsGenerator.ARRAY_TYPE])
            if arrayTypeIt == None:
                ShowSevereError(state, f"PVWatts: Invalid Array Type: {cAlphaArgs[PVWattsGenerator.ARRAY_TYPE]}")
                errorsFound = True
            else:
                arrayType = arrayTypeIt.
            let systemLosses = rNumericArgs[PVWattsGenerator.SYSTEM_LOSSES]
            var geometryTypeMap: Dict[String, GeometryType] = {
                "TILTAZIMUTH": GeometryType.TILT_AZIMUTH,
                "SURFACE": GeometryType.SURFACE
            }
            var geometryType: GeometryType
            let geometryTypeIt = geometryTypeMap.get(cAlphaArgs[PVWattsGenerator.GEOMETRY_TYPE])
            if geometryTypeIt == None:
                ShowSevereError(state, f"PVWatts: Invalid Geometry Type: {cAlphaArgs[PVWattsGenerator.GEOMETRY_TYPE]}")
                errorsFound = True
            else:
                geometryType = geometryTypeIt.
            let tilt = rNumericArgs[PVWattsGenerator.TILT_ANGLE]
            let azimuth = rNumericArgs[PVWattsGenerator.AZIMUTH_ANGLE]
            var surfaceNum: Int = 0
            if lAlphaFieldBlanks[PVWattsGenerator.SURFACE_NAME]:
                surfaceNum = 0
            else:
                surfaceNum = FindItemInList(cAlphaArgs[PVWattsGenerator.SURFACE_NAME], state.dataSurface.Surface)
            if errorsFound:
                ShowFatalError(state, "Errors found in getting PVWatts input")
            if NumNums < PVWattsGenerator.GROUND_COVERAGE_RATIO + 1:
                return PVWattsGenerator(
                    state, name, dcSystemCapacity, moduleType, arrayType, systemLosses, geometryType, tilt, azimuth, surfaceNum, 0.4
                )
            let groundCoverageRatio = rNumericArgs[PVWattsGenerator.GROUND_COVERAGE_RATIO]
            return PVWattsGenerator(
                state, name, dcSystemCapacity, moduleType, arrayType, systemLosses, geometryType, tilt, azimuth, surfaceNum, groundCoverageRatio
            )

        def __init__(
            inout self,
            state: EnergyPlusData,
            name: String,
            dcSystemCapacity: Real64,
            moduleType: ModuleType,
            arrayType: ArrayType,
            systemLosses: Real64 = 0.14,
            geometryType: GeometryType = GeometryType.TILT_AZIMUTH,
            tilt: Real64 = 20.0,
            azimuth: Real64 = 180.0,
            surfaceNum: Int = 0,
            groundCoverageRatio: Real64 = 0.4
        ):
            self.moduleType_ = moduleType
            self.arrayType_ = arrayType
            self.geometryType_ = geometryType
            self.DCtoACRatio_ = 1.1
            self.inverterEfficiency_ = 0.96
            self.outputDCPower_ = 1000.0
            self.outputDCEnergy_ = 0.0
            self.outputACPower_ = 0.0
            self.outputACEnergy_ = 0.0
            self.cellTemperature_ = -9999
            self.planeOfArrayIrradiance_ = -9999
            self.shadedPercent_ = 0.0
            self.pvwattsModule_ = ssc_module_create("pvwattsv5_1ts")
            self.pvwattsData_ = ssc_data_create()
            self.NumTimeStepsToday_ = 0.0

            assert self.pvwattsModule_ != None
            var errorsFound: Bool = False
            if name == "":
                ShowSevereError(state, "PVWatts: name cannot be blank.")
                errorsFound = True
            self.name_ = name
            if dcSystemCapacity <= 0:
                ShowSevereError(state, "PVWatts: DC system capacity must be greater than zero.")
                errorsFound = True
            self.dcSystemCapacity_ = dcSystemCapacity
            if systemLosses > 1.0 or systemLosses < 0.0:
                ShowSevereError(state, "PVWatts: Invalid system loss value {:.2f}".format(systemLosses))
                errorsFound = True
            self.systemLosses_ = systemLosses
            if self.geometryType_ == GeometryType.TILT_AZIMUTH:
                if tilt < 0 or tilt > 90:
                    ShowSevereError(state, "PVWatts: Invalid tilt: {:.2f}".format(tilt))
                    errorsFound = True
                self.tilt_ = tilt
                if azimuth < 0 or azimuth >= 360:
                    ShowSevereError(state, "PVWatts: Invalid azimuth: {:.2f}".format(azimuth))
                self.azimuth_ = azimuth
            else if self.geometryType_ == GeometryType.SURFACE:
                if surfaceNum == 0 or surfaceNum > state.dataSurface.Surface.size():
                    ShowSevereError(state, "PVWatts: SurfaceNum not in Surfaces: {}".format(surfaceNum))
                    errorsFound = True
                else:
                    self.surfaceNum_ = surfaceNum
                    self.tilt_ = self.getSurface(state).Tilt
                    self.azimuth_ = self.getSurface(state).Azimuth
            else:
                assert False
            if groundCoverageRatio > 1.0 or groundCoverageRatio < 0.0:
                ShowSevereError(state, "PVWatts: Invalid ground coverage ratio: {:.2f}".format(groundCoverageRatio))
                errorsFound = True
            self.groundCoverageRatio_ = groundCoverageRatio
            if errorsFound:
                ShowFatalError(state, "Errors found in getting PVWatts input")
            ssc_data_set_number(self.pvwattsData_, "lat", state.dataWeather.WeatherFileLatitude)
            ssc_data_set_number(self.pvwattsData_, "lon", state.dataWeather.WeatherFileLongitude)
            ssc_data_set_number(self.pvwattsData_, "tz", state.dataWeather.WeatherFileTimeZone)
            ssc_data_set_number(self.pvwattsData_, "time_step", state.dataGlobal.TimeStepZone)
            ssc_data_set_number(self.pvwattsData_, "system_capacity", self.dcSystemCapacity_ * 0.001)
            ssc_data_set_number(self.pvwattsData_, "module_type", Int(self.moduleType_))
            ssc_data_set_number(self.pvwattsData_, "dc_ac_ratio", self.DCtoACRatio_)
            ssc_data_set_number(self.pvwattsData_, "inv_eff", self.inverterEfficiency_ * 100.0)
            ssc_data_set_number(self.pvwattsData_, "losses", self.systemLosses_ * 100.0)
            ssc_data_set_number(self.pvwattsData_, "array_type", Int(self.arrayType_))
            ssc_data_set_number(self.pvwattsData_, "tilt", self.tilt_)
            ssc_data_set_number(self.pvwattsData_, "azimuth", self.azimuth_)
            ssc_data_set_number(self.pvwattsData_, "gcr", self.groundCoverageRatio_)
            ssc_data_set_number(self.pvwattsData_, "shaded_percent", self.shadedPercent_)

        def setupOutputVariables(self, state: EnergyPlusData):
            SetupOutputVariable(
                state,
                "Generator Produced DC Electricity Rate",
                Constant.Units.W,
                self.outputDCPower_,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name_
            )
            SetupOutputVariable(
                state,
                "Generator Produced DC Electricity Energy",
                Constant.Units.J,
                self.outputDCEnergy_,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Sum,
                self.name_,
                Constant.eResource.ElectricityProduced,
                OutputProcessor.Group.Plant,
                OutputProcessor.EndUseCat.Photovoltaic
            )
            SetupOutputVariable(
                state,
                "Generator PV Cell Temperature",
                Constant.Units.C,
                self.cellTemperature_,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name_
            )
            SetupOutputVariable(
                state,
                "Plane of Array Irradiance",
                Constant.Units.W_m2,
                self.planeOfArrayIrradiance_,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name_
            )
            SetupOutputVariable(
                state,
                "Shaded Percent",
                Constant.Units.Perc,
                self.shadedPercent_,
                OutputProcessor.TimeStepType.System,
                OutputProcessor.StoreType.Average,
                self.name_
            )

        def getDCSystemCapacity(self) -> Real64:
            return self.dcSystemCapacity_

        def getModuleType(self) -> ModuleType:
            return self.moduleType_

        def getArrayType(self) -> ArrayType:
            return self.arrayType_

        def getSystemLosses(self) -> Real64:
            return self.systemLosses_

        def getGeometryType(self) -> GeometryType:
            return self.geometryType_

        def getTilt(self) -> Real64:
            return self.tilt_

        def getAzimuth(self) -> Real64:
            return self.azimuth_

        def getSurface(self, state: EnergyPlusData) -> SurfaceData:
            return state.dataSurface.Surface[self.surfaceNum_ - 1]  # 1-based to 0-based

        def getGroundCoverageRatio(self) -> Real64:
            return self.groundCoverageRatio_

        def getCellTemperature(self) -> Real64:
            return self.cellTemperature_

        def setCellTemperature(self, cellTemp: Real64):
            self.cellTemperature_ = cellTemp

        def getPlaneOfArrayIrradiance(self) -> Real64:
            return self.planeOfArrayIrradiance_

        def setPlaneOfArrayIrradiance(self, poa: Real64):
            self.planeOfArrayIrradiance_ = poa

        def setDCtoACRatio(self, dc2ac: Real64):
            self.DCtoACRatio_ = dc2ac

        def setInverterEfficiency(self, inverterEfficiency: Real64):
            self.inverterEfficiency_ = inverterEfficiency

        def calc(self, state: EnergyPlusData):
            let TimeStepSysSec = state.dataHVACGlobal.TimeStepSysSec
            let NumTimeStepsToday_loc = state.dataGlobal.HourOfDay * state.dataGlobal.TimeStepsInHour + state.dataGlobal.TimeStep
            if self.NumTimeStepsToday_ != NumTimeStepsToday_loc:
                self.NumTimeStepsToday_ = NumTimeStepsToday_loc
            else:
                self.outputDCEnergy_ = self.outputDCPower_ * TimeStepSysSec
                self.outputACEnergy_ = self.outputACPower_ * TimeStepSysSec
                return
            ssc_data_set_number(self.pvwattsData_, "year", state.dataEnvrn.Year)
            ssc_data_set_number(self.pvwattsData_, "month", state.dataEnvrn.Month)
            ssc_data_set_number(self.pvwattsData_, "day", state.dataEnvrn.DayOfMonth)
            ssc_data_set_number(self.pvwattsData_, "hour", state.dataGlobal.HourOfDay - 1)
            ssc_data_set_number(self.pvwattsData_, "minute", (state.dataGlobal.TimeStep - 0.5) * state.dataGlobal.MinutesInTimeStep)
            ssc_data_set_number(self.pvwattsData_, "beam", state.dataEnvrn.BeamSolarRad)
            ssc_data_set_number(self.pvwattsData_, "diffuse", state.dataEnvrn.DifSolarRad)
            ssc_data_set_number(self.pvwattsData_, "tamb", state.dataEnvrn.OutDryBulbTemp)
            ssc_data_set_number(self.pvwattsData_, "wspd", state.dataEnvrn.WindSpeed)
            var albedo = state.dataWeather.wvarsHrTsToday[state.dataGlobal.TimeStep - 1, state.dataGlobal.HourOfDay - 1].Albedo
            if not (isfinite(albedo) and albedo > 0.0 and albedo < 1):
                albedo = 0.2
            ssc_data_set_number(self.pvwattsData_, "alb", albedo)
            ssc_data_set_number(self.pvwattsData_, "tcell", self.cellTemperature_)
            ssc_data_set_number(self.pvwattsData_, "poa", self.planeOfArrayIrradiance_)
            if self.geometryType_ == GeometryType.SURFACE:
                self.shadedPercent_ = (1.0 - state.dataHeatBal.SurfSunlitFrac[state.dataGlobal.HourOfDay - 1, state.dataGlobal.TimeStep - 1, self.surfaceNum_ - 1]) * 100.0
                ssc_data_set_number(self.pvwattsData_, "shaded_percent", self.shadedPercent_)
            if ssc_module_exec(self.pvwattsModule_, self.pvwattsData_) == 0:
                var errtext: String
                var sscErrType: Int
                var time: Float
                var i: Int = 0
                while True:
                    errtext = ssc_module_log(self.pvwattsModule_, i, sscErrType, time)
                    if errtext == None:
                        break
                    var err = "PVWatts: "
                    if sscErrType == SSC_WARNING:
                        err += errtext
                        ShowWarningMessage(state, err)
                    else if sscErrType == SSC_ERROR:
                        err += errtext
                        ShowErrorMessage(state, err)
                    i += 1
            else:
                var dc: Real64
                ssc_data_get_number(self.pvwattsData_, "dc", &dc)
                self.outputDCPower_ = dc
                self.outputDCEnergy_ = self.outputDCPower_ * TimeStepSysSec
                var ac: Real64
                ssc_data_get_number(self.pvwattsData_, "ac", &ac)
                self.outputACPower_ = ac
                self.outputACEnergy_ = self.outputACPower_ * TimeStepSysSec
                var tcell: Real64
                ssc_data_get_number(self.pvwattsData_, "tcell", &tcell)
                self.cellTemperature_ = tcell
                var poa: Real64
                ssc_data_get_number(self.pvwattsData_, "poa", &poa)
                self.planeOfArrayIrradiance_ = poa

        def getResults(
            self,
            GeneratorPower: Real64,
            GeneratorEnergy: Real64,
            ThermalPower: Real64,
            ThermalEnergy: Real64
        ):
            GeneratorPower = self.outputDCPower_
            GeneratorEnergy = self.outputDCEnergy_
            ThermalPower = 0.0
            ThermalEnergy = 0.0