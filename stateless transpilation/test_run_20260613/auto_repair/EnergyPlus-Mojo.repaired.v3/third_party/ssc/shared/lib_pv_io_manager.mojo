from lib_cec6par import cec6par_module_t, module6par
from lib_iec61853 import iec61853_module_t
from lib_irradproc import irrad, solarpos_spa, incidence, poaDecompReq, weather_data_provider, weatherfile, weatherdata, weather_record, weather_header
from lib_mlmodel import mlmodel_module_t
from lib_ondinv import ond_inverter
from lib_pvinv import pvcelltemp_t, pvmodule_t
from lib_pv_incidence_modifier import *
from lib_pvshade import ssky_diffuse_table, ssinputs, ssoutputs, shading_factor_calculator
from lib_sandia import sandia_inverter_t, sandia_module_t, sandia_celltemp_t
from lib_shared_inverter import SharedInverter
from lib_snowmodel import pvsnowmodel
from lib_util import util
from ...ssc.common import ssc_number_t, var_data, exec_error
from ...ssc.core import compute_module

# Static constant
var __nday: StaticTuple[Int, 12] = StaticTuple(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

# Enums
enum modulePowerModelList:
    MODULE_SIMPLE_EFFICIENCY = 0
    MODULE_CEC_DATABASE = 1
    MODULE_CEC_USER_INPUT = 2
    MODULE_SANDIA = 3
    MODULE_IEC61853 = 4
    MODULE_PVYIELD = 5

enum inverterTypeList:
    INVERTER_CEC_DATABASE = 0
    INVERTER_DATASHEET = 1
    INVERTER_PARTLOAD = 2
    INVERTER_COEFFICIENT_GEN = 3
    INVERTER_PVYIELD = 4

# Forward declarations
struct Simulation_IO;
struct Irradiance_IO;
struct Subarray_IO;
struct Module_IO;
struct Inverter_IO;
struct PVSystem_IO;

# flag class
struct flag:
    var init: Bool = False
    var value: Int = 0

    def __init__(inout self):
        self.init = False
        self.value = 0

    def set(inout self, setValue: Int):
        if setValue <= -1:
            return
        self.init = True
        self.value = setValue

    def checkInit(self):
        if not self.init:
            raise exec_error("PV IO Manager", "Flag used without initialization.")

    def __bool__(self) -> Bool:
        self.checkInit()
        return self.value != 0

    def __eq__(self, testValue: Int) -> Bool:
        self.checkInit()
        return self.value == testValue

    def __ne__(self, testValue: Int) -> Bool:
        self.checkInit()
        return self.value != testValue

# PVIOManager class
struct PVIOManager:
    var m_SimulationIO: owned[Simulation_IO]
    var m_IrradianceIO: owned[Irradiance_IO]
    var m_PVSystemIO: owned[PVSystem_IO]
    var m_InverterIO: owned[Inverter_IO]
    var m_SubarraysIO: List[owned[Subarray_IO]]
    var m_shadeDatabase: owned[ShadeDB8_mpp]
    var nSubarrays: Int
    var m_computeModule: Pointer[compute_module]
    var m_computeModuleName: String

    def __init__(inout self, cm: Pointer[compute_module], cmName: String):
        var ptr = owned[Irradiance_IO](Irradiance_IO(cm, cmName))
        self.m_IrradianceIO = ptr^
        var ptr2 = owned[Simulation_IO](Simulation_IO(cm, self.m_IrradianceIO[]))
        self.m_SimulationIO = ptr2^
        var shadeDatabase = owned[ShadeDB8_mpp](ShadeDB8_mpp())
        self.m_shadeDatabase = shadeDatabase^
        self.m_shadeDatabase[].init()
        var ptrInv = owned[Inverter_IO](Inverter_IO(cm, cmName))
        self.m_InverterIO = ptrInv^
        self.nSubarrays = 1
        var subarray1 = owned[Subarray_IO](Subarray_IO(cm, cmName, 1))
        self.m_SubarraysIO.append(subarray1^)
        for subarray in range(2, 5):
            var ptr3 = owned[Subarray_IO](Subarray_IO(cm, cmName, subarray))
            if ptr3[].enable:
                self.m_SubarraysIO.append(ptr3^)
                self.nSubarrays += 1
        var pvSystem = owned[PVSystem_IO](PVSystem_IO(cm, cmName, self.m_SimulationIO[], self.m_IrradianceIO[], self.getSubarrays(), self.m_InverterIO[]))
        self.m_PVSystemIO = pvSystem^
        self.allocateOutputs(cm)
        self.m_computeModule = cm
        self.m_computeModuleName = cmName

    def allocateOutputs(inout self, cm: Pointer[compute_module]):
        self.m_IrradianceIO[].AllocateOutputs(cm)
        self.m_PVSystemIO[].AllocateOutputs(cm)

    def getIrradianceIO(self) -> Pointer[Irradiance_IO]:
        return self.m_IrradianceIO[]

    def getComputeModule(self) -> Pointer[compute_module]:
        return self.m_computeModule

    def getSubarrayIO(self, subarrayNumber: Int) -> Pointer[Subarray_IO]:
        return self.m_SubarraysIO[subarrayNumber][]

    def getShadeDatabase(self) -> Pointer[ShadeDB8_mpp]:
        return self.m_shadeDatabase[]

    def getSubarrays(self) -> List[Pointer[Subarray_IO]]:
        var subarrays: List[Pointer[Subarray_IO]] = List[Pointer[Subarray_IO]]()
        for subarray in range(self.m_SubarraysIO.size):
            subarrays.append(self.m_SubarraysIO[subarray][])
        return subarrays

    def getPVSystemIO(self) -> Pointer[PVSystem_IO]:
        return self.m_PVSystemIO[]

    def getSimulationIO(self) -> Pointer[Simulation_IO]:
        return self.m_SimulationIO[]

# Irradiance_IO struct
struct Irradiance_IO:
    static let irradprocNoInterpolateSunriseSunset: Int = -1
    var weatherDataProvider: owned[weather_data_provider]
    var weatherRecord: weather_record
    var weatherHeader: weather_header
    var tsShiftHours: Float64
    var instantaneous: flag
    var numberOfWeatherFileRecords: Int
    var stepsPerHour: Int
    var numberOfSubarrays: Int
    var dtHour: Float64
    var radiationMode: Int
    var skyModel: Int
    var useWeatherFileAlbedo: flag
    var userSpecifiedMonthlyAlbedo: List[Float64]
    var p_weatherFileGHI: Pointer[ssc_number_t]
    var p_weatherFileDNI: Pointer[ssc_number_t]
    var p_weatherFileDHI: Pointer[ssc_number_t]
    var p_weatherFilePOA: List[Pointer[ssc_number_t]]
    var p_sunPositionTime: Pointer[ssc_number_t]
    var p_weatherFileWindSpeed: Pointer[ssc_number_t]
    var p_weatherFileAmbientTemp: Pointer[ssc_number_t]
    var p_weatherFileAlbedo: Pointer[ssc_number_t]
    var p_weatherFileSnowDepth: Pointer[ssc_number_t]
    var p_IrradianceCalculated: StaticTuple[Pointer[ssc_number_t], 3]
    var p_sunZenithAngle: Pointer[ssc_number_t]
    var p_sunAltitudeAngle: Pointer[ssc_number_t]
    var p_sunAzimuthAngle: Pointer[ssc_number_t]
    var p_absoluteAirmass: Pointer[ssc_number_t]
    var p_sunUpOverHorizon: Pointer[ssc_number_t]

    def __init__(inout self, cm: Pointer[compute_module], cmName: String):
        self.numberOfSubarrays = 4
        self.radiationMode = cm[].as_integer("irrad_mode")
        self.skyModel = cm[].as_integer("sky_model")
        if cm[].is_assigned("solar_resource_file"):
            self.weatherDataProvider = owned[weather_data_provider](weatherfile(cm[].as_string("solar_resource_file")))
            var weatherFile = weatherfile(self.weatherDataProvider[])
            if not weatherFile.ok():
                raise exec_error(cmName, weatherFile.message())
            if weatherFile.has_message():
                cm[].log(weatherFile.message(), SSC_WARNING)
        elif cm[].is_assigned("solar_resource_data"):
            self.weatherDataProvider = owned[weather_data_provider](weatherdata(cm[].lookup("solar_resource_data")))
            if self.weatherDataProvider[].has_message():
                cm[].log(self.weatherDataProvider[].message(), SSC_WARNING)
        else:
            raise exec_error(cmName, "No weather data supplied")
        self.tsShiftHours = 0.0
        self.instantaneous.set(True)
        if self.weatherDataProvider[].has_data_column(weather_data_provider.MINUTE):
            var rec: weather_record
            if self.weatherDataProvider[].read(rec):
                self.tsShiftHours = rec.minute / 60.0
            self.weatherDataProvider[].rewind()
        elif self.weatherDataProvider[].annualSimulation() and self.weatherDataProvider[].nrecords() == 8760:
            self.instantaneous.set(False)
            self.tsShiftHours = 0.5
        else:
            raise exec_error(cmName, "subhourly and non-annual weather files must specify the minute for each record")
        self.weatherDataProvider[].header(self.weatherHeader)
        self.numberOfWeatherFileRecords = self.weatherDataProvider[].nrecords()
        self.dtHour = 1.0
        self.stepsPerHour = 1
        if self.weatherDataProvider[].annualSimulation():
            self.stepsPerHour = self.numberOfWeatherFileRecords / 8760
            if self.stepsPerHour > 0:
                self.dtHour /= self.stepsPerHour
        if self.weatherDataProvider[].annualSimulation() and self.numberOfWeatherFileRecords % 8760 != 0:
            raise exec_error(cmName, util.format("invalid number of data records (%zu): must be an integer multiple of 8760", self.numberOfWeatherFileRecords))
        if self.weatherDataProvider[].annualSimulation() and (self.stepsPerHour < 1 or self.stepsPerHour > 60):
            raise exec_error(cmName, util.format("%d timesteps per hour found. Weather data should be single year.", self.stepsPerHour))
        self.useWeatherFileAlbedo.set(cm[].as_boolean("use_wf_albedo"))
        self.userSpecifiedMonthlyAlbedo = cm[].as_vector_double("albedo")
        self.checkWeatherFile(cm, cmName)

    def checkWeatherFile(inout self, cm: Pointer[compute_module], cmName: String):
        for idx in range(self.numberOfWeatherFileRecords):
            if not self.weatherDataProvider[].read(self.weatherRecord):
                raise exec_error(cmName, "could not read data line " + util.to_string(idx + 1) + " in weather file")
            if (self.weatherRecord.gh != self.weatherRecord.gh) and (self.radiationMode == irrad.DN_GH or self.radiationMode == irrad.GH_DF):
                cm[].log(util.format("missing global irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.gh, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if (self.weatherRecord.dn != self.weatherRecord.dn) and (self.radiationMode == irrad.DN_DF or self.radiationMode == irrad.DN_GH):
                cm[].log(util.format("missing beam irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.dn, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if (self.weatherRecord.df != self.weatherRecord.df) and (self.radiationMode == irrad.DN_DF or self.radiationMode == irrad.GH_DF):
                cm[].log(util.format("missing diffuse irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.df, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if (self.weatherRecord.poa != self.weatherRecord.poa) and (self.radiationMode == irrad.POA_R or self.radiationMode == irrad.POA_P):
                cm[].log(util.format("missing POA irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.poa, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if self.weatherRecord.tdry != self.weatherRecord.tdry:
                cm[].log(util.format("missing temperature %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.tdry, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if self.weatherRecord.wspd != self.weatherRecord.wspd:
                cm[].log(util.format("missing wind speed %lg W/m2 at time [y:%d m:%d d:%d h:%d], exiting",
                    self.weatherRecord.wspd, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_ERROR, Float32(idx))
                return
            if (self.weatherRecord.gh < 0 or self.weatherRecord.gh > irrad.irradiationMax) and (self.radiationMode == irrad.DN_GH or self.radiationMode == irrad.GH_DF):
                cm[].log(util.format("out of range global irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                    self.weatherRecord.gh, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_WARNING, Float32(idx))
                self.weatherRecord.gh = 0
            if (self.weatherRecord.dn < 0 or self.weatherRecord.dn > irrad.irradiationMax) and (self.radiationMode == irrad.DN_DF or self.radiationMode == irrad.DN_GH):
                cm[].log(util.format("out of range beam irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                    self.weatherRecord.dn, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_WARNING, Float32(idx))
                self.weatherRecord.dn = 0
            if (self.weatherRecord.df < 0 or self.weatherRecord.df > irrad.irradiationMax) and (self.radiationMode == irrad.DN_DF or self.radiationMode == irrad.GH_DF):
                cm[].log(util.format("out of range diffuse irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                    self.weatherRecord.df, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_WARNING, Float32(idx))
                self.weatherRecord.df = 0
            if (self.weatherRecord.poa < 0 or self.weatherRecord.poa > irrad.irradiationMax) and (self.radiationMode == irrad.POA_R or self.radiationMode == irrad.POA_P):
                cm[].log(util.format("out of range POA irradiance %lg W/m2 at time [y:%d m:%d d:%d h:%d], set to zero",
                    self.weatherRecord.poa, self.weatherRecord.year, self.weatherRecord.month, self.weatherRecord.day, self.weatherRecord.hour), SSC_WARNING, Float32(idx))
                self.weatherRecord.poa = 0
            var month_idx = self.weatherRecord.month - 1
            var albedoError = True
            if self.useWeatherFileAlbedo and Math.isfinite(self.weatherRecord.alb) and self.weatherRecord.alb > 0 and self.weatherRecord.alb < 1:
                albedoError = False
            elif month_idx >= 0 and month_idx < 12:
                if self.userSpecifiedMonthlyAlbedo[month_idx] > 0 and self.userSpecifiedMonthlyAlbedo[month_idx] < 1:
                    albedoError = False
                    self.weatherRecord.alb = self.userSpecifiedMonthlyAlbedo[month_idx]
            if albedoError:
                raise exec_error(cmName,
                    util.format("Error retrieving albedo value: Invalid month in weather file or invalid albedo value in weather file"))
        self.weatherDataProvider[].rewind()

    def AllocateOutputs(inout self, cm: Pointer[compute_module]):
        self.p_weatherFileGHI = cm[].allocate("gh", self.numberOfWeatherFileRecords)
        self.p_weatherFileDNI = cm[].allocate("dn", self.numberOfWeatherFileRecords)
        self.p_weatherFileDHI = cm[].allocate("df", self.numberOfWeatherFileRecords)
        self.p_sunPositionTime = cm[].allocate("sunpos_hour", self.numberOfWeatherFileRecords)
        self.p_weatherFileWindSpeed = cm[].allocate("wspd", self.numberOfWeatherFileRecords)
        self.p_weatherFileAmbientTemp = cm[].allocate("tdry", self.numberOfWeatherFileRecords)
        self.p_weatherFileAlbedo = cm[].allocate("alb", self.numberOfWeatherFileRecords)
        self.p_weatherFileSnowDepth = cm[].allocate("snowdepth", self.numberOfWeatherFileRecords)
        for subarray in range(self.numberOfSubarrays):
            var wfpoa = "wfpoa" + util.to_string(subarray + 1)
            self.p_weatherFilePOA.append(cm[].allocate(wfpoa, self.numberOfWeatherFileRecords))
        if self.radiationMode == irrad.DN_DF:
            self.p_IrradianceCalculated[0] = cm[].allocate("gh_calc", self.numberOfWeatherFileRecords)
        if self.radiationMode == irrad.DN_GH or self.radiationMode == irrad.POA_R or self.radiationMode == irrad.POA_P:
            self.p_IrradianceCalculated[1] = cm[].allocate("df_calc", self.numberOfWeatherFileRecords)
        if self.radiationMode == irrad.GH_DF or self.radiationMode == irrad.POA_R or self.radiationMode == irrad.POA_P:
            self.p_IrradianceCalculated[2] = cm[].allocate("dn_calc", self.numberOfWeatherFileRecords)
        self.p_sunZenithAngle = cm[].allocate("sol_zen", self.numberOfWeatherFileRecords)
        self.p_sunAltitudeAngle = cm[].allocate("sol_alt", self.numberOfWeatherFileRecords)
        self.p_sunAzimuthAngle = cm[].allocate("sol_azi", self.numberOfWeatherFileRecords)
        self.p_absoluteAirmass = cm[].allocate("airmass", self.numberOfWeatherFileRecords)
        self.p_sunUpOverHorizon = cm[].allocate("sunup", self.numberOfWeatherFileRecords)

    def AssignOutputs(inout self, cm: Pointer[compute_module]):
        cm[].assign("ts_shift_hours", var_data(ssc_number_t(self.tsShiftHours)))

# Simulation_IO struct
struct Simulation_IO:
    var numberOfYears: Int
    var numberOfWeatherFileRecords: Int
    var numberOfSteps: Int
    var stepsPerHour: Int
    var dtHour: Float64
    var useLifetimeOutput: flag
    var saveLifetimeVars: flag
    var annualSimulation: flag

    def __init__(inout self, cm: Pointer[compute_module], IrradianceIO: Irradiance_IO):
        self.numberOfWeatherFileRecords = IrradianceIO.numberOfWeatherFileRecords
        self.stepsPerHour = IrradianceIO.stepsPerHour
        self.dtHour = IrradianceIO.dtHour
        self.useLifetimeOutput.set(False)
        if cm[].is_assigned("system_use_lifetime_output"):
            self.useLifetimeOutput.set(cm[].as_integer("system_use_lifetime_output"))
        self.numberOfYears = 1
        self.saveLifetimeVars.set(0)
        if self.useLifetimeOutput:
            self.numberOfYears = cm[].as_integer("analysis_period")
            self.saveLifetimeVars.set(cm[].as_integer("save_full_lifetime_variables"))
        self.numberOfSteps = self.numberOfYears * self.numberOfWeatherFileRecords
        self.annualSimulation.set(IrradianceIO.weatherDataProvider[].annualSimulation())

# PVSystem_IO struct
struct PVSystem_IO:
    var numberOfSubarrays: Int
    var numberOfInverters: Int
    var Irradiance: Pointer[Irradiance_IO]
    var Simulation: Pointer[Simulation_IO]
    var Subarrays: List[Pointer[Subarray_IO]]
    var Inverter: Pointer[Inverter_IO]
    var m_sharedInverter: owned[SharedInverter]
    var enableDCLifetimeLosses: flag
    var enableACLifetimeLosses: flag
    var enableSnowModel: flag
    var stringsInParallel: Int
    var ratedACOutput: Float64
    var clipMpptWindow: flag
    var mpptMapping: List[List[Int]]
    var enableMismatchVoltageCalc: flag
    var dcDegradationFactor: List[Float64]
    var dcLifetimeLosses: List[Float64]
    var acLifetimeLosses: List[Float64]
    var acDerate: Float64
    var acLossPercent: Float64
    var transmissionDerate: Float64
    var transmissionLossPercent: Float64
    var transformerLoadLossFraction: ssc_number_t
    var transformerNoLoadLossFraction: ssc_number_t
    var p_angleOfIncidence: List[Pointer[ssc_number_t]]
    var p_angleOfIncidenceModifier: List[Pointer[ssc_number_t]]
    var p_surfaceTilt: List[Pointer[ssc_number_t]]
    var p_surfaceAzimuth: List[Pointer[ssc_number_t]]
    var p_axisRotation: List[Pointer[ssc_number_t]]
    var p_idealRotation: List[Pointer[ssc_number_t]]
    var p_poaNominalFront: List[Pointer[ssc_number_t]]
    var p_poaShadedFront: List[Pointer[ssc_number_t]]
    var p_poaShadedSoiledFront: List[Pointer[ssc_number_t]]
    var p_poaBeamFront: List[Pointer[ssc_number_t]]
    var p_poaDiffuseFront: List[Pointer[ssc_number_t]]
    var p_poaFront: List[Pointer[ssc_number_t]]
    var p_poaTotal: List[Pointer[ssc_number_t]]
    var p_poaRear: List[Pointer[ssc_number_t]]
    var p_derateSoiling: List[Pointer[ssc_number_t]]
    var p_beamShadingFactor: List[Pointer[ssc_number_t]]
    var p_temperatureCell: List[Pointer[ssc_number_t]]
    var p_temperatureCellSS: List[Pointer[ssc_number_t]]
    var p_moduleEfficiency: List[Pointer[ssc_number_t]]
    var p_dcStringVoltage: List[Pointer[ssc_number_t]]
    var p_voltageOpenCircuit: List[Pointer[ssc_number_t]]
    var p_currentShortCircuit: List[Pointer[ssc_number_t]]
    var p_dcPowerGross: List[Pointer[ssc_number_t]]
    var p_derateLinear: List[Pointer[ssc_number_t]]
    var p_derateSelfShading: List[Pointer[ssc_number_t]]
    var p_derateSelfShadingDiffuse: List[Pointer[ssc_number_t]]
    var p_derateSelfShadingReflected: List[Pointer[ssc_number_t]]
    var p_shadeDBShadeFraction: List[Pointer[ssc_number_t]]
    var p_mpptVoltage: List[Pointer[ssc_number_t]]
    var p_dcPowerNetPerMppt: List[Pointer[ssc_number_t]]
    var p_snowLoss: List[Pointer[ssc_number_t]]
    var p_snowCoverage: List[Pointer[ssc_number_t]]
    var p_shadeDB_GPOA: List[Pointer[ssc_number_t]]
    var p_shadeDB_DPOA: List[Pointer[ssc_number_t]]
    var p_shadeDB_temperatureCell: List[Pointer[ssc_number_t]]
    var p_shadeDB_modulesPerString: List[Pointer[ssc_number_t]]
    var p_shadeDB_voltageMaxPowerSTC: List[Pointer[ssc_number_t]]
    var p_shadeDB_voltageMPPTLow: List[Pointer[ssc_number_t]]
    var p_shadeDB_voltageMPPTHigh: List[Pointer[ssc_number_t]]
    var p_dcDegradationFactor: Pointer[ssc_number_t]
    var p_transformerNoLoadLoss: Pointer[ssc_number_t]
    var p_transformerLoadLoss: Pointer[ssc_number_t]
    var p_transformerLoss: Pointer[ssc_number_t]
    var p_poaFrontNominalTotal: Pointer[ssc_number_t]
    var p_poaFrontBeamNominalTotal: Pointer[ssc_number_t]
    var p_poaFrontBeamTotal: Pointer[ssc_number_t]
    var p_poaFrontShadedTotal: Pointer[ssc_number_t]
    var p_poaFrontShadedSoiledTotal: Pointer[ssc_number_t]
    var p_poaRearTotal: Pointer[ssc_number_t]
    var p_poaFrontTotal: Pointer[ssc_number_t]
    var p_poaTotalAllSubarrays: Pointer[ssc_number_t]
    var p_snowLossTotal: Pointer[ssc_number_t]
    var p_inverterEfficiency: Pointer[ssc_number_t]
    var p_inverterClipLoss: Pointer[ssc_number_t]
    var p_inverterMPPTLoss: Pointer[ssc_number_t]
    var p_inverterPowerConsumptionLoss: Pointer[ssc_number_t]
    var p_inverterNightTimeLoss: Pointer[ssc_number_t]
    var p_inverterThermalLoss: Pointer[ssc_number_t]
    var p_inverterTotalLoss: Pointer[ssc_number_t]
    var p_acWiringLoss: Pointer[ssc_number_t]
    var p_transmissionLoss: Pointer[ssc_number_t]
    var p_systemDCPower: Pointer[ssc_number_t]
    var p_systemACPower: Pointer[ssc_number_t]

    def __init__(inout self, cm: Pointer[compute_module], cmName: String, SimulationIO: Pointer[Simulation_IO], IrradianceIO: Pointer[Irradiance_IO], SubarraysAll: List[Pointer[Subarray_IO]], InverterIO: Pointer[Inverter_IO]):
        self.Irradiance = IrradianceIO
        self.Simulation = SimulationIO
        self.Subarrays = SubarraysAll
        self.Inverter = InverterIO
        self.numberOfSubarrays = self.Subarrays.size
        self.stringsInParallel = 0
        for s in range(self.numberOfSubarrays):
            self.stringsInParallel += self.Subarrays[s][].nStrings
        self.numberOfInverters = cm[].as_integer("inverter_count")
        self.ratedACOutput = self.Inverter[].ratedACOutput * self.numberOfInverters
        self.acDerate = 1 - cm[].as_double("acwiring_loss") / 100
        self.acLossPercent = (1 - self.acDerate) * 100
        self.transmissionDerate = 1 - cm[].as_double("transmission_loss") / 100
        self.transmissionLossPercent = (1 - self.transmissionDerate) * 100
        self.enableDCLifetimeLosses.set(cm[].as_boolean("en_dc_lifetime_losses"))
        self.enableACLifetimeLosses.set(cm[].as_boolean("en_ac_lifetime_losses"))
        self.enableSnowModel.set(cm[].as_boolean("en_snow_model"))
        var tmpSharedInverter = owned[SharedInverter](SharedInverter(self.Inverter[].inverterType, self.numberOfInverters, self.Inverter[].sandiaInverter, self.Inverter[].partloadInverter, self.Inverter[].ondInverter))
        self.m_sharedInverter = tmpSharedInverter^
        InverterIO[].setupSharedInverter(cm, self.m_sharedInverter[])
        if self.Simulation[].useLifetimeOutput:
            var dc_degrad = cm[].as_vector_double("dc_degradation")
            self.dcDegradationFactor.append(1.0)
            self.dcDegradationFactor.append(1.0)
            if dc_degrad.size == 1:
                for i in range(1, self.Simulation[].numberOfYears):
                    self.dcDegradationFactor.append(Math.pow(1.0 - dc_degrad[0] / 100.0, i))
            elif dc_degrad.size > 0:
                for i in range(1, min(self.Simulation[].numberOfYears, dc_degrad.size)):
                    self.dcDegradationFactor.append(1.0 - dc_degrad[i] / 100.0)
            if self.enableDCLifetimeLosses:
                if not self.Simulation[].annualSimulation:
                    raise exec_error(cmName, "Lifetime daily losses cannot be entered with non-annual weather data")
                self.dcLifetimeLosses = cm[].as_vector_double("dc_lifetime_losses")
                if self.dcLifetimeLosses.size != self.Simulation[].numberOfYears * 365:
                    raise exec_error(cmName, "Length of the lifetime daily DC losses array must be equal to the analysis period * 365 days/year")
            if self.enableACLifetimeLosses:
                if not self.Simulation[].annualSimulation:
                    raise exec_error(cmName, "Lifetime daily losses cannot be entered with non-annual weather data")
                self.acLifetimeLosses = cm[].as_vector_double("ac_lifetime_losses")
                if self.acLifetimeLosses.size != self.Simulation[].numberOfYears * 365:
                    raise exec_error(cmName, "Length of the lifetime daily AC losses array must be equal to the analysis period * 365 days/year")
        self.transformerLoadLossFraction = cm[].as_number("transformer_load_loss") * ssc_number_t(util.percent_to_fraction)
        self.transformerNoLoadLossFraction = cm[].as_number("transformer_no_load_loss") * ssc_number_t(util.percent_to_fraction)
        self.clipMpptWindow.set(False)
        if self.Inverter[].mpptLowVoltage > 0 and self.Inverter[].mpptHiVoltage > self.Inverter[].mpptLowVoltage:
            var modulePowerModel = self.Subarrays[0][].Module[].modulePowerModel
            if modulePowerModel == 1 or modulePowerModel == 2 or modulePowerModel == 4 or modulePowerModel == 5:
                self.clipMpptWindow.set(True)
            else:
                cm[].log("The simple efficiency and Sandia module models do not allow limiting module voltage to the MPPT tracking range of the inverter.", SSC_NOTICE)
        else:
            cm[].log("Inverter MPPT voltage tracking window not defined - modules always operate at MPPT.", SSC_NOTICE)
        for n_subarray in range(self.numberOfSubarrays):
            if self.Subarrays[n_subarray][].enable:
                if self.Subarrays[n_subarray][].mpptInput > self.Inverter[].nMpptInputs:
                    raise exec_error(cmName, "Subarray " + util.to_string(n_subarray) + " MPPT input is greater than the number of inverter MPPT inputs.")
        for mppt in range(1, self.Inverter[].nMpptInputs + 1):
            var mppt_n: List[Int] = List[Int]()
            for n_subarray in range(self.Subarrays.size):
                if self.Subarrays[n_subarray][].enable:
                    if self.Subarrays[n_subarray][].mpptInput == mppt:
                        mppt_n.append(n_subarray)
            if mppt_n.size < 1:
                raise exec_error(cmName, "At least one subarray must be assigned to each inverter MPPT input.")
            self.mpptMapping.append(mppt_n)
        if self.Inverter[].nMpptInputs > 1 and self.numberOfInverters > 1:
            raise exec_error(cmName, "At this time, only one multiple-MPPT-input inverter may be modeled per system. See help for details.")
        self.enableMismatchVoltageCalc.set(cm[].as_boolean("enable_mismatch_vmax_calc"))
        if self.enableMismatchVoltageCalc and \
            self.Subarrays[0][].Module[].modulePowerModel != MODULE_CEC_DATABASE and \
            self.Subarrays[0][].Module[].modulePowerModel != MODULE_CEC_USER_INPUT and \
            self.Subarrays[0][].Module[].modulePowerModel != MODULE_IEC61853:
            raise exec_error(cmName, "String level subarray mismatch can only be calculated using a single-diode based module model.")
        if self.enableMismatchVoltageCalc and self.numberOfSubarrays <= 1:
            raise exec_error(cmName, "Subarray voltage mismatch calculation requires more than one subarray. Please check your inputs.")
        self.SetupPOAInput()

    def SetupPOAInput(inout self):
        if self.Irradiance[].radiationMode == irrad.POA_R or self.Irradiance[].radiationMode == irrad.POA_P:
            for nn in range(self.Subarrays.size):
                if not self.Subarrays[nn][].enable:
                    continue
                var tmp = owned[poaDecompReq](poaDecompReq())
                self.Subarrays[nn][].poa.poaAll = tmp^
                self.Subarrays[nn][].poa.poaAll[].elev = self.Irradiance[].weatherHeader.elev
                if self.Irradiance[].stepsPerHour > 1:
                    self.Subarrays[nn][].poa.poaAll[].stepScale = 'm'
                    self.Subarrays[nn][].poa.poaAll[].stepSize = 60.0 / self.Irradiance[].stepsPerHour
                self.Subarrays[nn][].poa.poaAll[].POA.reserve(self.Irradiance[].numberOfWeatherFileRecords)
                self.Subarrays[nn][].poa.poaAll[].inc.reserve(self.Irradiance[].numberOfWeatherFileRecords)
                self.Subarrays[nn][].poa.poaAll[].tilt.reserve(self.Irradiance[].numberOfWeatherFileRecords)
                self.Subarrays[nn][].poa.poaAll[].zen.reserve(self.Irradiance[].numberOfWeatherFileRecords)
                self.Subarrays[nn][].poa.poaAll[].exTer.reserve(self.Irradiance[].numberOfWeatherFileRecords)
                for i in range(self.Irradiance[].numberOfWeatherFileRecords):
                    self.Subarrays[nn][].poa.poaAll[].POA.append(0)
                    self.Subarrays[nn][].poa.poaAll[].inc.append(0)
                    self.Subarrays[nn][].poa.poaAll[].tilt.append(0)
                    self.Subarrays[nn][].poa.poaAll[].zen.append(0)
                    self.Subarrays[nn][].poa.poaAll[].exTer.append(0)
                var ts_hour = self.Simulation[].dtHour
                var hdr = self.Irradiance[].weatherHeader
                var wdprov = self.Irradiance[].weatherDataProvider[]
                var wf = self.Irradiance[].weatherRecord
                wdprov.rewind()
                for ii in range(self.Irradiance[].numberOfWeatherFileRecords):
                    if not wdprov.read(wf):
                        raise exec_error("pvsamv1", "could not read data line " + util.to_string(ii + 1) + " in weather file while loading POA data")
                    var month_idx = wf.month - 1
                    if self.Subarrays[nn][].trackMode == irrad.SEASONAL_TILT:
                        self.Subarrays[nn][].tiltDegrees = self.Subarrays[nn][].monthlyTiltDegrees[month_idx]
                    if wf.poa > 0:
                        self.Subarrays[nn][].poa.poaAll[].POA[ii] = wf.poa
                    else:
                        self.Subarrays[nn][].poa.poaAll[].POA[ii] = -999
                    var t_cur = wf.hour + wf.minute / 60
                    var sun: StaticTuple[Float64, 9]
                    var angle: StaticTuple[Float64, 5]
                    var tms: StaticTuple[Int, 3]
                    var dut1 = 0
                    solarpos_spa(wf.year, wf.month, wf.day, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sun)
                    var t_sunrise = sun[4]
                    var t_sunset = sun[5]
                    if t_sunset > 24:
                        var sunanglestemp: StaticTuple[Float64, 9]
                        if wf.day > 1:
                            solarpos_spa(wf.year, wf.month, wf.day - 1, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        elif wf.month > 1:
                            solarpos_spa(wf.year, wf.month - 1, __nday[wf.month - 2], 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        else:
                            solarpos_spa(wf.year - 1, 12, 31, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        if sunanglestemp[5] >= 24:
                            t_sunset = sunanglestemp[5] - 24.0
                    if t_sunrise < 0:
                        var sunanglestemp: StaticTuple[Float64, 9]
                        if wf.day < __nday[wf.month - 1]:
                            solarpos_spa(wf.year, wf.month, wf.day + 1, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        elif wf.month < 12:
                            solarpos_spa(wf.year, wf.month + 1, 1, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        else:
                            solarpos_spa(wf.year + 1, 1, 1, 12, 0.0, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sunanglestemp)
                        if sunanglestemp[4] < 0:
                            t_sunrise = sunanglestemp[4] + 24.0
                    if t_cur >= t_sunrise - ts_hour / 2.0 and t_cur < t_sunrise + ts_hour / 2.0:
                        var t_calc = (t_sunrise + (t_cur + ts_hour / 2.0)) / 2.0
                        var hr_calc = Int(t_calc)
                        var min_calc = (t_calc - hr_calc) * 60.0
                        tms[0] = hr_calc
                        tms[1] = Int(min_calc)
                        solarpos_spa(wf.year, wf.month, wf.day, hr_calc, min_calc, 0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sun)
                        tms[2] = 2
                    elif t_cur > t_sunset - ts_hour / 2.0 and t_cur <= t_sunset + ts_hour / 2.0:
                        var t_calc = ((t_cur - ts_hour / 2.0) + t_sunset) / 2.0
                        var hr_calc = Int(t_calc)
                        var min_calc = (t_calc - hr_calc) * 60.0
                        tms[0] = hr_calc
                        tms[1] = Int(min_calc)
                        solarpos_spa(wf.year, wf.month, wf.day, hr_calc, min_calc, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sun)
                        tms[2] = 3
                    elif (t_sunrise < t_sunset and t_cur >= t_sunrise and t_cur <= t_sunset) or \
                        (t_sunrise > t_sunset and (t_cur <= t_sunset or t_cur >= t_sunrise)):
                        tms[0] = wf.hour
                        tms[1] = Int(wf.minute)
                        solarpos_spa(wf.year, wf.month, wf.day, wf.hour, wf.minute, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sun)
                        tms[2] = 1
                    else:
                        solarpos_spa(wf.year, wf.month, wf.day, wf.hour, wf.minute, 0.0, hdr.lat, hdr.lon, hdr.tz, dut1, hdr.elev, wf.pres, wf.tdry, 0, 180, sun)
                        tms[0] = wf.hour
                        tms[1] = Int(wf.minute)
                        tms[2] = 0
                    if tms[2] > 0:
                        incidence(self.Subarrays[nn][].trackMode, self.Subarrays[nn][].tiltDegrees, self.Subarrays[nn][].azimuthDegrees, self.Subarrays[nn][].trackerRotationLimitDegrees, sun[1], sun[0], self.Subarrays[nn][].backtrackingEnabled, self.Subarrays[nn][].groundCoverageRatio, False, 0.0, angle)
                    else:
                        angle[0] = -999
                        angle[1] = -999
                        angle[2] = -999
                        angle[3] = -999
                        angle[4] = -999
                    self.Subarrays[nn][].poa.poaAll[].inc[ii] = angle[0]
                    self.Subarrays[nn][].poa.poaAll[].tilt[ii] = angle[1]
                    self.Subarrays[nn][].poa.poaAll[].zen[ii] = sun[1]
                    self.Subarrays[nn][].poa.poaAll[].exTer[ii] = sun[8]
                wdprov.rewind()

    def AllocateOutputs(inout self, cm: Pointer[compute_module]):
        var numberOfWeatherFileRecords = self.Irradiance[].numberOfWeatherFileRecords
        if self.Simulation[].saveLifetimeVars == 1:
            numberOfWeatherFileRecords = self.Simulation[].numberOfSteps
        var numberOfLifetimeRecords = self.Simulation[].numberOfSteps
        var numberOfYears = self.Simulation[].numberOfYears
        for subarray in range(self.Subarrays.size):
            if self.Subarrays[subarray][].enable:
                var prefix = self.Subarrays[subarray][].prefix
                self.p_angleOfIncidence.append(cm[].allocate(prefix + "aoi", numberOfWeatherFileRecords))
                self.p_angleOfIncidenceModifier.append(cm[].allocate(prefix + "aoi_modifier", numberOfWeatherFileRecords))
                self.p_surfaceTilt.append(cm[].allocate(prefix + "surf_tilt", numberOfWeatherFileRecords))
                self.p_surfaceAzimuth.append(cm[].allocate(prefix + "surf_azi", numberOfWeatherFileRecords))
                self.p_axisRotation.append(cm[].allocate(prefix + "axisrot", numberOfWeatherFileRecords))
                self.p_idealRotation.append(cm[].allocate(prefix + "idealrot", numberOfWeatherFileRecords))
                self.p_poaNominalFront.append(cm[].allocate(prefix + "poa_nom", numberOfWeatherFileRecords))
                self.p_poaShadedFront.append(cm[].allocate(prefix + "poa_shaded", numberOfWeatherFileRecords))
                self.p_poaShadedSoiledFront.append(cm[].allocate(prefix + "poa_shaded_soiled", numberOfWeatherFileRecords))
                self.p_poaBeamFront.append(cm[].allocate(prefix + "poa_eff_beam", numberOfWeatherFileRecords))
                self.p_poaDiffuseFront.append(cm[].allocate(prefix + "poa_eff_diff", numberOfWeatherFileRecords))
                self.p_poaTotal.append(cm[].allocate(prefix + "poa_eff", numberOfWeatherFileRecords))
                self.p_poaRear.append(cm[].allocate(prefix + "poa_rear", numberOfWeatherFileRecords))
                self.p_poaFront.append(cm[].allocate(prefix + "poa_front", numberOfWeatherFileRecords))
                self.p_derateSoiling.append(cm[].allocate(prefix + "soiling_derate", numberOfWeatherFileRecords))
                self.p_beamShadingFactor.append(cm[].allocate(prefix + "beam_shading_factor", numberOfWeatherFileRecords))
                self.p_temperatureCell.append(cm[].allocate(prefix + "celltemp", numberOfWeatherFileRecords))
                self.p_temperatureCellSS.append(cm[].allocate(prefix + "celltempSS", numberOfWeatherFileRecords))
                self.p_moduleEfficiency.append(cm[].allocate(prefix + "modeff", numberOfWeatherFileRecords))
                self.p_dcStringVoltage.append(cm[].allocate(prefix + "dc_voltage", numberOfWeatherFileRecords))
                self.p_voltageOpenCircuit.append(cm[].allocate(prefix + "voc", numberOfWeatherFileRecords))
                self.p_currentShortCircuit.append(cm[].allocate(prefix + "isc", numberOfWeatherFileRecords))
                self.p_dcPowerGross.append(cm[].allocate(prefix + "dc_gross", numberOfWeatherFileRecords))
                self.p_derateLinear.append(cm[].allocate(prefix + "linear_derate", numberOfWeatherFileRecords))
                self.p_derateSelfShading.append(cm[].allocate(prefix + "ss_derate", numberOfWeatherFileRecords))
                self.p_derateSelfShadingDiffuse.append(cm[].allocate(prefix + "ss_diffuse_derate", numberOfWeatherFileRecords))
                self.p_derateSelfShadingReflected.append(cm[].allocate(prefix + "ss_reflected_derate", numberOfWeatherFileRecords))
                if self.enableSnowModel:
                    self.p_snowLoss.append(cm[].allocate(prefix + "snow_loss", numberOfWeatherFileRecords))
                    self.p_snowCoverage.append(cm[].allocate(prefix + "snow_coverage", numberOfWeatherFileRecords))
                if self.Subarrays[subarray][].enableSelfShadingOutputs:
                    self.p_shadeDB_GPOA.append(cm[].allocate("shadedb_" + prefix + "gpoa", numberOfWeatherFileRecords))
                    self.p_shadeDB_DPOA.append(cm[].allocate("shadedb_" + prefix + "dpoa", numberOfWeatherFileRecords))
                    self.p_shadeDB_temperatureCell.append(cm[].allocate("shadedb_" + prefix + "pv_cell_temp", numberOfWeatherFileRecords))
                    self.p_shadeDB_modulesPerString.append(cm[].allocate("shadedb_" + prefix + "mods_per_str", numberOfWeatherFileRecords))
                    self.p_shadeDB_voltageMaxPowerSTC.append(cm[].allocate("shadedb_" + prefix + "str_vmp_stc", numberOfWeatherFileRecords))
                    self.p_shadeDB_voltageMPPTLow.append(cm[].allocate("shadedb_" + prefix + "mppt_lo", numberOfWeatherFileRecords))
                    self.p_shadeDB_voltageMPPTHigh.append(cm[].allocate("shadedb_" + prefix + "mppt_hi", numberOfWeatherFileRecords))
                self.p_shadeDBShadeFraction.append(cm[].allocate("shadedb_" + prefix + "shade_frac", numberOfWeatherFileRecords))
        for mppt_input in range(self.Inverter[].nMpptInputs):
            self.p_mpptVoltage.append(cm[].allocate("inverterMppt" + String(mppt_input + 1) + "_DCVoltage", numberOfLifetimeRecords))
            self.p_dcPowerNetPerMppt.append(cm[].allocate("inverterMppt" + String(mppt_input + 1) + "_NetDCPower", numberOfLifetimeRecords))
        self.p_transformerNoLoadLoss = cm[].allocate("xfmr_nll_ts", numberOfWeatherFileRecords)
        self.p_transformerLoadLoss = cm[].allocate("xfmr_ll_ts", numberOfWeatherFileRecords)
        self.p_transformerLoss = cm[].allocate("xfmr_loss_ts", numberOfWeatherFileRecords)
        self.p_poaFrontNominalTotal = cm[].allocate("poa_nom", numberOfWeatherFileRecords)
        self.p_poaFrontBeamNominalTotal = cm[].allocate("poa_beam_nom", numberOfWeatherFileRecords)
        self.p_poaFrontBeamTotal = cm[].allocate("poa_beam_eff", numberOfWeatherFileRecords)
        self.p_poaFrontShadedTotal = cm[].allocate("poa_shaded", numberOfWeatherFileRecords)
        self.p_poaFrontShadedSoiledTotal = cm[].allocate("poa_shaded_soiled", numberOfWeatherFileRecords)
        self.p_poaFrontTotal = cm[].allocate("poa_front", numberOfWeatherFileRecords)
        self.p_poaRearTotal = cm[].allocate("poa_rear", numberOfWeatherFileRecords)
        self.p_poaTotalAllSubarrays = cm[].allocate("poa_eff", numberOfWeatherFileRecords)
        self.p_snowLossTotal = cm[].allocate("dc_snow_loss", numberOfWeatherFileRecords)
        self.p_inverterEfficiency = cm[].allocate("inv_eff", numberOfWeatherFileRecords)
        self.p_inverterClipLoss = cm[].allocate("inv_cliploss", numberOfWeatherFileRecords)
        self.p_inverterMPPTLoss = cm[].allocate("dc_invmppt_loss", numberOfWeatherFileRecords)
        self.p_inverterPowerConsumptionLoss = cm[].allocate("inv_psoloss", numberOfWeatherFileRecords)
        self.p_inverterNightTimeLoss = cm[].allocate("inv_pntloss", numberOfWeatherFileRecords)
        self.p_inverterThermalLoss = cm[].allocate("inv_tdcloss", numberOfWeatherFileRecords)
        self.p_inverterTotalLoss = cm[].allocate("inv_total_loss", numberOfWeatherFileRecords)
        self.p_acWiringLoss = cm[].allocate("ac_wiring_loss", numberOfWeatherFileRecords)
        self.p_transmissionLoss = cm[].allocate("ac_transmission_loss", numberOfWeatherFileRecords)
        self.p_systemDCPower = cm[].allocate("dc_net", numberOfLifetimeRecords)
        self.p_systemACPower = cm[].allocate("gen", numberOfLifetimeRecords)
        if self.Simulation[].useLifetimeOutput:
            self.p_dcDegradationFactor = cm[].allocate("dc_degrade_factor", numberOfYears + 1)

    def AssignOutputs(inout self, cm: Pointer[compute_module]):
        cm[].assign("ac_loss", var_data(ssc_number_t(self.acLossPercent + self.transmissionLossPercent)))

# Subarray_IO struct
struct Subarray_IO:
    var prefix: String
    enum self_shading:
        NO_SHADING = 0
        NON_LINEAR_SHADING = 1
        LINEAR_SHADING = 2
    var Module: owned[Module_IO]
    var enable: flag
    var nStrings: Int
    var nModulesPerString: Int
    var mpptInput: Int
    var groundCoverageRatio: Float64
    var tiltDegrees: Float64
    var azimuthDegrees: Float64
    var trackMode: Int
    var trackerRotationLimitDegrees: Float64
    var tiltEqualLatitude: flag
    var monthlyTiltDegrees: List[Float64]
    var backtrackingEnabled: flag
    var moduleAspectRatio: Float64
    var nStringsBottom: Int
    var monthlySoiling: List[Float64]
    var rearIrradianceLossPercent: Float64
    var dcOptimizerLossPercent: Float64
    var mismatchLossPercent: Float64
    var diodesLossPercent: Float64
    var dcWiringLossPercent: Float64
    var trackingLossPercent: Float64
    var nameplateLossPercent: Float64
    var dcLossTotalPercent: Float64
    var enableSelfShadingOutputs: flag
    var shadeMode: Int
    var usePOAFromWeatherFile: flag
    var selfShadingSkyDiffTable: ssky_diffuse_table
    var selfShadingInputs: ssinputs
    var selfShadingOutputs: ssoutputs
    var shadeCalculator: shading_factor_calculator
    var subarrayEnableSnow: flag
    var snowModel: pvsnowmodel
    var poa: struct:
        var poaBeamFront: Float64
        var poaDiffuseFront: Float64
        var poaGroundFront: Float64
        var poaRear: Float64
        var poaTotal: Float64
        var sunUp: Bool
        var angleOfIncidenceDegrees: Float64
        var surfaceTiltDegrees: Float64
        var surfaceAzimuthDegrees: Float64
        var nonlinearDCShadingDerate: Float64
        var usePOAFromWF: Bool
        var poaShadWarningCount: Int
        var poaAll: owned[poaDecompReq]
    var dcPowerSubarray: Float64

    def __init__(inout self, cm: Pointer[compute_module], cmName: String, subarrayNumber: Int):
        self.prefix = "subarray" + util.to_string(subarrayNumber) + "_"
        self.enable.set(True)
        if subarrayNumber > 1:
            self.enable.set(cm[].as_boolean(self.prefix + "enable"))
        if self.enable:
            var n = cm[].as_integer(self.prefix + "nstrings")
            if n < 0:
                raise exec_error(cmName, "invalid string allocation between subarrays.  all subarrays must have zero or positive number of strings.")
            self.nStrings = n
            if self.nStrings == 0:
                self.enable.set(False)
                return
            self.nModulesPerString = cm[].as_integer(self.prefix + "modules_per_string")
            self.mpptInput = cm[].as_integer(self.prefix + "mppt_input")
            self.trackMode = cm[].as_integer(self.prefix + "track_mode")
            self.tiltEqualLatitude.set(0)
            if cm[].is_assigned(self.prefix + "tilt_eq_lat"):
                self.tiltEqualLatitude.set(cm[].as_boolean(self.prefix + "tilt_eq_lat"))
            self.tiltDegrees = Float64.nan
            if self.trackMode == irrad.FIXED_TILT or self.trackMode == irrad.SINGLE_AXIS or self.trackMode == irrad.AZIMUTH_AXIS:
                if not self.tiltEqualLatitude and not cm[].is_assigned(self.prefix + "tilt"):
                    raise exec_error(cmName, "Subarray " + util.to_string(subarrayNumber) + " tilt required but not assigned.")
            if cm[].is_assigned(self.prefix + "tilt"):
                self.tiltDegrees = Math.fabs(cm[].as_double(self.prefix + "tilt"))
            if self.trackMode == irrad.SEASONAL_TILT and not cm[].is_assigned(self.prefix + "monthly_tilt"):
                raise exec_error(cmName, "Subarray " + util.to_string(subarrayNumber) + " monthly tilt required but