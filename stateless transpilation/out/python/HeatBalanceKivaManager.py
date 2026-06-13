# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object w/ attributes dataZoneCtrls, dataConstruction, dataMaterial,
#   dataSurface, dataEnvrn, dataHeatBalSurface, dataHeatBal, dataGlobal, dataWeather,
#   dataStringGlobals, dataSurfaceGeometry, files (from EnergyPlus.Data.EnergyPlusData)
# - Kiva: Foundation, Instance, Aggregator, Point, Polygon, Material, Layer, InputBlock,
#   BoundaryConditions, ConvectionAlgorithm, ForcedConvectionTerm, Surface, SnapshotSettings,
#   GroundPlot, MSG_INFO, MSG_WARN, MSG_ERR, setMessageCallback, (from libkiva)
# - ShowMessage, ShowWarningError, ShowSevereError, ShowFatalError (from EnergyPlus.UtilityRoutines)
# - Weather.InterpretWeatherDataLine (from EnergyPlus.WeatherManager)
# - ThermalComfort.CalcSurfaceWeightedMRT (from EnergyPlus.ThermalComfort)
# - DataEnvironment.WindSpeedAt (from EnergyPlus.DataEnvironment)
# - Vectors.PointsInPlane (from EnergyPlus.Vectors)
# - HVAC.SetptType (from EnergyPlus.DataHVACGlobals)
# - DataSurfaces.SurfaceClass, DataSurfaces.KivaFoundation (from EnergyPlus.DataSurfaces)
# - Constant.Kelvin, Constant.DegToRad, Constant.PiOvr2 (from EnergyPlus)
# - FileSystem.getAbsolutePath (from EnergyPlus)

from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional, Protocol, Any
import math
from enum import IntEnum

KIVAZONE_UNCONTROLLED = 0
KIVAZONE_TEMPCONTROL = 1
KIVAZONE_COMFORTCONTROL = 2
KIVAZONE_STAGEDCONTROL = 3


@dataclass
class KivaWeatherData:
    intervalsPerHour: int = 0
    annualAverageDrybulbTemp: float = 0.0
    dryBulb: List[float] = field(default_factory=list)
    windSpeed: List[float] = field(default_factory=list)
    skyEmissivity: List[float] = field(default_factory=list)


@dataclass
class FoundationKiva:
    foundation: Any = None
    intHIns: Any = None
    intVIns: Any = None
    extHIns: Any = None
    extVIns: Any = None
    footing: Any = None
    name: str = ""
    surfaces: List[int] = field(default_factory=list)
    wallConstructionIndex: int = 0
    assumedIndoorTemperature: float = 0.0


@dataclass
class KivaInstanceMap:
    instance: Any = None
    floorSurface: int = 0
    wallSurfaces: List[int] = field(default_factory=list)
    zoneNum: int = 0
    zoneControlType: int = KIVAZONE_UNCONTROLLED
    zoneControlNum: int = 0
    zoneAssumedTemperature: float = 0.0
    floorWeight: float = 0.0
    constructionNum: int = 0
    kmPtr: Optional['KivaManager'] = None
    debugDir: str = ""
    plotNum: int = 0

    def __init__(self, state, foundation, floor_surface, wall_surfaces, zone_num,
                 zone_assumed_temperature, floor_weight, construction_num, km_ptr=None):
        self.instance = type('Instance', (), {'ground': None})()
        self.instance.bcs = None
        self.floorSurface = floor_surface
        self.wallSurfaces = wall_surfaces
        self.zoneNum = zone_num
        self.zoneControlType = KIVAZONE_UNCONTROLLED
        self.zoneControlNum = 0
        self.zoneAssumedTemperature = zone_assumed_temperature
        self.floorWeight = floor_weight
        self.constructionNum = construction_num
        self.kmPtr = km_ptr
        self.debugDir = ""
        self.plotNum = 0

        for i in range(1, state.dataZoneCtrls.NumTempControlledZones + 1):
            if state.dataZoneCtrls.TempControlledZone[i].ActualZoneNum == zone_num:
                self.zoneControlType = KIVAZONE_TEMPCONTROL
                self.zoneControlNum = i
                break

        for i in range(1, state.dataZoneCtrls.NumComfortControlledZones + 1):
            if state.dataZoneCtrls.ComfortControlledZone[i].ActualZoneNum == zone_num:
                self.zoneControlType = KIVAZONE_COMFORTCONTROL
                self.zoneControlNum = i
                break

        for i in range(len(state.dataZoneCtrls.StageControlledZone)):
            if state.dataZoneCtrls.StageControlledZone[i].ActualZoneNum == zone_num:
                self.zoneControlType = KIVAZONE_STAGEDCONTROL
                self.zoneControlNum = i
                break

    def initGround(self, state, kiva_weather):
        num_accelerated_timesteps = 3
        accelerated_timestep = 30
        acc_date = self.getAccDate(state, num_accelerated_timesteps, accelerated_timestep)

        self.instance.ground.foundation.numericalScheme = 0
        self.setInitialBoundaryConditions(state, kiva_weather, acc_date, 24, state.dataGlobal.TimeStepsInHour)
        self.instance.calculate()
        acc_date += accelerated_timestep
        while acc_date > 365 + state.dataWeather.LeapYearAdd:
            acc_date = acc_date - (365 + state.dataWeather.LeapYearAdd)

        self.instance.ground.foundation.numericalScheme = 1
        for i in range(num_accelerated_timesteps):
            self.setInitialBoundaryConditions(state, kiva_weather, acc_date, 24, state.dataGlobal.TimeStepsInHour)
            self.instance.calculate(accelerated_timestep * 24 * 60 * 60)
            acc_date += accelerated_timestep
            while acc_date > 365 + state.dataWeather.LeapYearAdd:
                acc_date = acc_date - (365 + state.dataWeather.LeapYearAdd)

        self.instance.calculate_surface_averages()
        self.instance.foundation.numericalScheme = 2

    def getAccDate(self, state, num_accelerated_timesteps, accelerated_timestep):
        acc_date = state.dataEnvrn.DayOfYear - 1 - accelerated_timestep * (num_accelerated_timesteps + 1)
        while acc_date <= 0:
            acc_date = acc_date + 365 + state.dataWeather.LeapYearAdd
        return acc_date

    def setInitialBoundaryConditions(self, state, kiva_weather, date, hour, timestep):
        from EnergyPlus import Constant, HVAC

        data_size = len(kiva_weather.windSpeed)
        weight_now = 0.0

        if kiva_weather.intervalsPerHour == 1:
            index = (date - 1) * 24 + (hour - 1)
            weight_now = min(1.0, (float(timestep) / float(state.dataGlobal.TimeStepsInHour)))
        else:
            index = ((date - 1) * 24 * state.dataGlobal.TimeStepsInHour +
                     (hour - 1) * state.dataGlobal.TimeStepsInHour + (timestep - 1))
            weight_now = 1.0

        if index == 0:
            index_prev = data_size - 1
        else:
            index_prev = index - 1

        self.instance.bcs = type('BoundaryConditions', (), {})()

        bcs = self.instance.bcs
        bcs.outdoorTemp = (kiva_weather.dryBulb[index] * weight_now +
                           kiva_weather.dryBulb[index_prev] * (1.0 - weight_now) + Constant.Kelvin)

        bcs.localWindSpeed = ((kiva_weather.windSpeed[index] * weight_now +
                               kiva_weather.windSpeed[index_prev] * (1.0 - weight_now)) *
                              state.dataEnvrn.WeatherFileWindModCoeff *
                              math.pow(self.instance.ground.foundation.grade.roughness /
                                       state.dataEnvrn.SiteWindBLHeight,
                                       state.dataEnvrn.SiteWindExp))
        bcs.skyEmissivity = (kiva_weather.skyEmissivity[index] * weight_now +
                             kiva_weather.skyEmissivity[index_prev] * (1.0 - weight_now))
        bcs.solarAzimuth = 3.14
        bcs.solarAltitude = 0.0
        bcs.directNormalFlux = 0.0
        bcs.diffuseHorizontalFlux = 0.0
        bcs.slabAbsRadiation = 0.0
        bcs.wallAbsRadiation = 0.0
        bcs.deepGroundTemperature = kiva_weather.annualAverageDrybulbTemp + Constant.Kelvin

        default_flag_temp = -999
        standard_temp = 22
        assumed_floating_temp = standard_temp

        if self.zoneAssumedTemperature > default_flag_temp:
            Tin = self.zoneAssumedTemperature + Constant.Kelvin
        else:
            if self.zoneControlType == KIVAZONE_UNCONTROLLED:
                Tin = assumed_floating_temp + Constant.Kelvin
            elif self.zoneControlType == KIVAZONE_TEMPCONTROL:
                ctrl_type_sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setptTypeSched
                control_type = ctrl_type_sched.getHrTsVal(state, hour, timestep)

                if control_type == HVAC.SetptType.Uncontrolled:
                    Tin = assumed_floating_temp + Constant.Kelvin
                elif control_type == HVAC.SetptType.SingleHeat:
                    sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[control_type].heatSetptSched
                    setpoint = sched.getHrTsVal(state, hour, timestep)
                    Tin = setpoint + Constant.Kelvin
                elif control_type == HVAC.SetptType.SingleCool:
                    sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[control_type].coolSetptSched
                    setpoint = sched.getHrTsVal(state, hour, timestep)
                    Tin = setpoint + Constant.Kelvin
                elif control_type == HVAC.SetptType.SingleHeatCool:
                    sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[control_type].heatSetptSched
                    setpoint = sched.getHrTsVal(state, hour, timestep)
                    Tin = setpoint + Constant.Kelvin
                elif control_type == HVAC.SetptType.DualHeatCool:
                    heat_sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[control_type].heatSetptSched
                    cool_sched = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[control_type].coolSetptSched
                    heat_setpoint = heat_sched.getHrTsVal(state, hour, timestep)
                    cool_setpoint = cool_sched.getHrTsVal(state, hour, timestep)
                    heat_balance_temp = 10.0 + Constant.Kelvin
                    cool_balance_temp = 15.0 + Constant.Kelvin

                    if bcs.outdoorTemp < heat_balance_temp:
                        Tin = heat_setpoint + Constant.Kelvin
                    elif bcs.outdoorTemp > cool_balance_temp:
                        Tin = cool_setpoint + Constant.Kelvin
                    else:
                        weight = ((cool_balance_temp - bcs.outdoorTemp) /
                                  (cool_balance_temp - heat_balance_temp))
                        Tin = heat_setpoint * weight + cool_setpoint * (1.0 - weight) + Constant.Kelvin
                else:
                    Tin = 0.0
                    ShowSevereError(state, f"Illegal control type for Zone={state.dataHeatBal.Zone[self.zoneNum].Name}, Found value={control_type}, in Schedule={state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setptTypeSched.Name}")
            elif self.zoneControlType == KIVAZONE_COMFORTCONTROL:
                Tin = standard_temp + Constant.Kelvin
            elif self.zoneControlType == KIVAZONE_STAGEDCONTROL:
                heat_sched = state.dataZoneCtrls.StageControlledZone[self.zoneControlNum].heatSetptBaseSched
                cool_sched = state.dataZoneCtrls.StageControlledZone[self.zoneControlNum].coolSetptBaseSched
                heat_setpoint = heat_sched.getHrTsVal(state, hour, timestep)
                cool_setpoint = cool_sched.getHrTsVal(state, hour, timestep)
                heat_balance_temp = 10.0 + Constant.Kelvin
                cool_balance_temp = 15.0 + Constant.Kelvin
                if bcs.outdoorTemp < heat_balance_temp:
                    Tin = heat_setpoint + Constant.Kelvin
                elif bcs.outdoorTemp > cool_balance_temp:
                    Tin = cool_setpoint + Constant.Kelvin
                else:
                    weight = ((cool_balance_temp - bcs.outdoorTemp) /
                              (cool_balance_temp - heat_balance_temp))
                    Tin = heat_setpoint * weight + cool_setpoint * (1.0 - weight) + Constant.Kelvin
            else:
                Tin = assumed_floating_temp + Constant.Kelvin

        bcs.slabConvectiveTemp = Tin
        bcs.wallConvectiveTemp = Tin
        bcs.slabRadiantTemp = Tin
        bcs.wallRadiantTemp = Tin

        bcs.gradeForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
        bcs.gradeConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out
        bcs.slabConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].in_

        if len(self.wallSurfaces) > 0:
            bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].f
            bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].out
            bcs.intWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].in_
        else:
            bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
            bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out

    def setBoundaryConditions(self, state):
        from EnergyPlus import Constant, ThermalComfort, DataEnvironment

        bcs = self.instance.bcs

        bcs.outdoorTemp = state.dataEnvrn.OutDryBulbTemp + Constant.Kelvin
        bcs.localWindSpeed = DataEnvironment.WindSpeedAt(state, self.instance.ground.foundation.grade.roughness)
        bcs.windDirection = state.dataEnvrn.WindDir * Constant.DegToRad
        bcs.solarAzimuth = math.atan2(state.dataEnvrn.SOLCOS[0], state.dataEnvrn.SOLCOS[1])
        bcs.solarAltitude = Constant.PiOvr2 - math.acos(state.dataEnvrn.SOLCOS[2])
        bcs.directNormalFlux = state.dataEnvrn.BeamSolarRad
        bcs.diffuseHorizontalFlux = state.dataEnvrn.DifSolarRad
        bcs.skyEmissivity = math.pow(state.dataEnvrn.SkyTempKelvin, 4) / math.pow(bcs.outdoorTemp, 4)

        bcs.slabAbsRadiation = (state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[self.floorSurface] +
                                state.dataHeatBal.SurfQdotRadIntGainsInPerArea[self.floorSurface] +
                                state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[self.floorSurface])

        bcs.slabConvectiveTemp = state.dataHeatBal.SurfTempEffBulkAir[self.floorSurface] + Constant.Kelvin
        bcs.slabRadiantTemp = ThermalComfort.CalcSurfaceWeightedMRT(state, self.floorSurface, False) + Constant.Kelvin
        bcs.gradeForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
        bcs.gradeConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out
        bcs.slabConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].in_

        q_a_total = 0.0
        a_total = 0.0
        ta_rad_total = 0.0
        ta_conv_total = 0.0
        for wl in self.wallSurfaces:
            Q = (state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[wl] +
                 state.dataHeatBal.SurfQdotRadIntGainsInPerArea[wl] +
                 state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[wl])

            A = state.dataSurface.Surface[wl].Area

            Trad = ThermalComfort.CalcSurfaceWeightedMRT(state, wl, False)
            Tconv = state.dataHeatBal.SurfTempEffBulkAir[wl]

            q_a_total += Q * A
            ta_rad_total += Trad * A
            ta_conv_total += Tconv * A
            a_total += A

        if a_total > 0.0:
            bcs.wallAbsRadiation = q_a_total / a_total
            bcs.wallRadiantTemp = ta_rad_total / a_total + Constant.Kelvin
            bcs.wallConvectiveTemp = ta_conv_total / a_total + Constant.Kelvin
            bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].f
            bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].out
            bcs.intWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].in_
        else:
            bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
            bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out


@dataclass
class ConvectionAlgorithms:
    in_: Any = None
    out: Any = None
    f: Any = None


@dataclass
class Settings:
    soilK: float = 0.864
    soilRho: float = 1510.0
    soilCp: float = 1260.0
    groundSolarAbs: float = 0.9
    groundThermalAbs: float = 0.9
    groundRoughness: float = 0.9
    farFieldWidth: float = 40.0
    deepGroundBoundary: int = 2
    deepGroundDepth: float = 40.0
    autocalculateDeepGroundDepth: bool = True
    minCellDim: float = 0.02
    maxGrowthCoeff: float = 1.5
    timestepType: int = 0

    ZERO_FLUX = 0
    GROUNDWATER = 1
    AUTO = 2
    HOURLY = 0
    TIMESTEP = 1


@dataclass
class WallGroup:
    exposedPerimeter: float = 0.0
    wallIDs: List[int] = field(default_factory=list)


class KivaManager:
    def __init__(self):
        self.kivaWeather = KivaWeatherData()
        self.defaultFoundation = FoundationKiva()
        self.foundationInputs = []
        self.kivaInstances = []
        self.surfaceConvMap = {}
        self.surfaceMap = {}
        self.timestep = 3600.0
        self.settings = Settings()
        self.defaultAdded = False
        self.defaultIndex = 0

    def __del__(self):
        pass

    def readWeatherData(self, state):
        from EnergyPlus import Weather, Constant

        kiva_weather_file = state.files.inputWeatherFilePath.open(state, "KivaManager::readWeatherFile")

        Header = ["LOCATION", "DESIGN CONDITIONS", "TYPICAL/EXTREME PERIODS",
                  "GROUND TEMPERATURES", "HOLIDAYS/DAYLIGHT SAVING",
                  "COMMENTS 1", "COMMENTS 2", "DATA PERIODS"]

        hd_line = 0
        still_looking = True
        while still_looking:
            line_result = kiva_weather_file.readLine()
            if line_result.eof:
                from EnergyPlus import UtilityRoutines
                UtilityRoutines.ShowFatalError(state, f"Kiva::ReadWeatherFile: Unexpected End-of-File on EPW Weather file, while reading header information, looking for header={Header[hd_line]}")

            endcol = len(line_result.data)
            if endcol > 0:
                if ord(line_result.data[endcol - 1]) == 65279:
                    from EnergyPlus import UtilityRoutines
                    UtilityRoutines.ShowSevereError(state, "OpenWeatherFile: EPW Weather File appears to be a Unicode or binary file.")
                    UtilityRoutines.ShowContinueError(state, "...This file cannot be read by this program. Please save as PC or Unix file and try again")
                    UtilityRoutines.ShowFatalError(state, "Program terminates due to previous condition.")

            pos = line_result.data.find(Header[hd_line])
            if pos == -1:
                continue
            pos = line_result.data.find(',')

            if (pos == -1) and not Header[hd_line].upper().startswith("COMMENTS"):
                from EnergyPlus import UtilityRoutines
                UtilityRoutines.ShowSevereError(state, "Invalid Header line in in.epw -- no commas")
                UtilityRoutines.ShowContinueError(state, f"Line={line_result.data}")
                UtilityRoutines.ShowFatalError(state, "Previous conditions cause termination.")

            if pos != -1:
                line_result.data = line_result.data[pos + 1:]

            if Header[hd_line].upper() == "DATA PERIODS":
                line_result.data = line_result.data.upper().strip()
                num_hd_args = 2
                count = 1
                while count <= num_hd_args:
                    line_result.data = line_result.data.strip()
                    pos = line_result.data.find(',')
                    if pos == -1:
                        if len(line_result.data) == 0:
                            while pos == -1:
                                line_result = kiva_weather_file.readLine()
                                line_result.data = line_result.data.strip().upper()
                                pos = line_result.data.find(',')
                        else:
                            pos = len(line_result.data)

                    if count == 1:
                        try:
                            num_periods = int(line_result.data[:pos])
                            num_hd_args += 4 * num_periods
                        except:
                            pass
                    elif count == 2:
                        try:
                            self.kivaWeather.intervalsPerHour = int(line_result.data[:pos])
                        except:
                            pass

                    line_result.data = line_result.data[pos + 1:]
                    count += 1

            hd_line += 1
            if hd_line == 8:
                still_looking = False

        total_db = 0.0
        count = 0

        while True:
            weather_data_line = kiva_weather_file.readLine()
            if weather_data_line.eof:
                break

            dry_bulb = 0.0
            dew_point = 0.0
            rel_hum = 0.0
            at_m_press = 0.0
            et_horiz = 0.0
            et_direct = 0.0
            ir_horiz = 0.0
            glb_horiz = 0.0
            direct_rad = 0.0
            diffuse_rad = 0.0
            glb_horiz_illum = 0.0
            direct_nrm_illum = 0.0
            diffuse_horiz_illum = 0.0
            zen_lum = 0.0
            wind_dir = 0.0
            wind_speed = 0.0
            total_sky_cover = 0.0
            opaque_sky_cover = 0.0
            visibility = 0.0
            ceil_height = 0.0
            precip_water = 0.0
            aerosol_opt_depth = 0.0
            snow_depth = 0.0
            days_since_last_snow = 0.0
            albedo = 0.0
            liquid_precip = 0.0
            pres_weath_obs = 0
            pres_weath_conds = [0] * 9

            Weather.InterpretWeatherDataLine(state, weather_data_line.data,
                                             dry_bulb, dew_point, rel_hum, at_m_press,
                                             et_horiz, et_direct, ir_horiz, glb_horiz,
                                             direct_rad, diffuse_rad, glb_horiz_illum,
                                             direct_nrm_illum, diffuse_horiz_illum, zen_lum,
                                             wind_dir, wind_speed, total_sky_cover,
                                             opaque_sky_cover, visibility, ceil_height,
                                             pres_weath_obs, pres_weath_conds,
                                             precip_water, aerosol_opt_depth, snow_depth,
                                             days_since_last_snow, albedo, liquid_precip)

            if dry_bulb >= 99.9:
                dry_bulb = state.dataWeather.wvarsMissing.OutDryBulbTemp
            if dew_point >= 99.9:
                dew_point = state.dataWeather.wvarsMissing.OutDewPointTemp
            if wind_speed >= 999.0:
                wind_speed = state.dataWeather.wvarsMissing.WindSpeed
            if opaque_sky_cover >= 99.0:
                opaque_sky_cover = state.dataWeather.wvarsMissing.OpaqueSkyCover

            self.kivaWeather.dryBulb.append(dry_bulb)
            self.kivaWeather.windSpeed.append(wind_speed)

            o_sky = opaque_sky_cover
            t_dew_k = min(dry_bulb, dew_point) + Constant.Kelvin
            e_sky = ((0.787 + 0.764 * math.log(t_dew_k / Constant.Kelvin)) *
                     (1.0 + 0.0224 * o_sky - 0.0035 * o_sky ** 2 + 0.00028 * o_sky ** 3))

            self.kivaWeather.skyEmissivity.append(e_sky)

            count += 1
            total_db += dry_bulb

        self.kivaWeather.annualAverageDrybulbTemp = total_db / count

    def setupKivaInstances(self, state):
        from EnergyPlus import Vectors, DataSurfaces

        Kiva.setMessageCallback(kivaErrorCallback, (state, ""))
        errors_found = False

        if state.dataZoneCtrls.GetZoneAirStatsInputFlag:
            from EnergyPlus import ZoneTempPredictorCorrector
            ZoneTempPredictorCorrector.GetZoneAirSetPoints(state)
            state.dataZoneCtrls.GetZoneAirStatsInputFlag = False

        self.readWeatherData(state)

        surfaces = state.dataSurface.Surface
        constructs = state.dataConstruction.Construct
        materials = state.dataMaterial.materials

        inst = 0
        surf_num = 0

        for surface in surfaces:
            if surface.ExtBoundCond == DataSurfaces.KivaFoundation and surface.Class == DataSurfaces.SurfaceClass.Floor:
                wall_surfaces = []

                for wl in self.foundationInputs[surface.OSCPtr].surfaces:
                    if surfaces[wl].Zone == surface.Zone and wl != surf_num:
                        if surfaces[wl].Class != DataSurfaces.SurfaceClass.Wall:
                            if surfaces[wl].Class == DataSurfaces.SurfaceClass.Floor:
                                errors_found = True
                                from EnergyPlus import UtilityRoutines
                                UtilityRoutines.ShowSevereError(state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\", only one floor per Foundation:Kiva Object allowed.")
                            else:
                                errors_found = True
                                from EnergyPlus import UtilityRoutines
                                UtilityRoutines.ShowSevereError(state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\", only floor and wall surfaces are allowed to reference Foundation Outside Boundary Conditions.")
                                UtilityRoutines.ShowContinueError(state, f"Surface=\"{surfaces[wl].Name}\", is not a floor or wall.")
                        else:
                            wall_surfaces.append(wl)

                is_exposed_perimeter = []
                user_set_exposed_perimeter = False
                use_detailed_exposed_perimeter = False
                exposed_fraction = 0.0

                exp_perim_map = state.dataSurfaceGeometry.exposedFoundationPerimeter.surfaceMap
                if surf_num in exp_perim_map:
                    user_set_exposed_perimeter = True
                    use_detailed_exposed_perimeter = exp_perim_map[surf_num].useDetailedExposedPerimeter
                    if use_detailed_exposed_perimeter:
                        is_exposed_perimeter = exp_perim_map[surf_num].isExposedPerimeter[:]
                    else:
                        exposed_fraction = exp_perim_map[surf_num].exposedFraction
                else:
                    errors_found = True
                    from EnergyPlus import UtilityRoutines
                    UtilityRoutines.ShowSevereError(state, f"Surface=\"{surfaces[surf_num].Name}\", references a Foundation Outside Boundary Condition but there is no corresponding SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER object defined.")

                floor_polygon = []
                for v in surface.Vertex:
                    floor_polygon.append((v.x, v.y))
                    if not user_set_exposed_perimeter:
                        is_exposed_perimeter.append(True)

                total_perimeter = 0.0
                for i in range(len(surface.Vertex)):
                    i_next = 0 if i == len(surface.Vertex) - 1 else i + 1
                    v = surface.Vertex[i]
                    v_next = surface.Vertex[i_next]
                    total_perimeter += math.sqrt((v.x - v_next.x) ** 2 + (v.y - v_next.y) ** 2)

                if use_detailed_exposed_perimeter:
                    total_2d_perimeter = 0.0
                    exposed_2d_perimeter = 0.0
                    for i in range(len(floor_polygon)):
                        i_next = 0 if i == len(floor_polygon) - 1 else i + 1
                        p = floor_polygon[i]
                        p_next = floor_polygon[i_next]
                        perim = math.sqrt((p[0] - p_next[0]) ** 2 + (p[1] - p_next[1]) ** 2)
                        total_2d_perimeter += perim
                        if is_exposed_perimeter[i]:
                            exposed_2d_perimeter += perim
                    exposed_fraction = min(exposed_2d_perimeter / total_2d_perimeter, 1.0)

                total_exposed_perimeter = exposed_fraction * total_perimeter
                remaining_exposed_perimeter = total_exposed_perimeter

                combination_map = {}

                if len(wall_surfaces) > 0:
                    for wl in wall_surfaces:
                        v = surfaces[wl].Vertex
                        num_vs = len(v)

                        if num_vs > 4:
                            from EnergyPlus import UtilityRoutines
                            UtilityRoutines.ShowWarningError(state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\", wall surfaces with more than four vertices referencing")
                            UtilityRoutines.ShowContinueError(state, "...Foundation Outside Boundary Conditions may not be interpreted correctly in the 2D finite difference model.")
                            UtilityRoutines.ShowContinueError(state, f"Surface=\"{surfaces[wl].Name}\", has {num_vs} vertices.")
                            UtilityRoutines.ShowContinueError(state, "Consider separating the wall into separate surfaces, each spanning from the floor slab to the top of the foundation wall.")

                        coplanar_points = Vectors.PointsInPlane(surfaces[surf_num].Vertex, len(surfaces[surf_num].Vertex),
                                                                 surfaces[wl].Vertex, len(surfaces[wl].Vertex), errors_found)

                        perimeter = 0.0

                        for i in range(len(coplanar_points)):
                            p = coplanar_points[i]
                            p_c = 0 if p == num_vs - 1 else p + 1
                            p2 = coplanar_points[0] if i == len(coplanar_points) - 1 else coplanar_points[i + 1]

                            if p2 == p_c:
                                perimeter += math.sqrt((v[p].x - v[p2].x) ** 2 + (v[p].y - v[p2].y) ** 2)

                        if perimeter == 0.0:
                            from EnergyPlus import UtilityRoutines
                            UtilityRoutines.ShowWarningError(state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\".")
                            UtilityRoutines.ShowContinueError(state, f"   Wall Surface=\"{surfaces[wl].Name}\", does not have any vertices that are")
                            UtilityRoutines.ShowContinueError(state, f"   coplanar with the corresponding Floor Surface=\"{surfaces[surf_num].Name}\".")
                            UtilityRoutines.ShowContinueError(state, "   Simulation will continue using the distance between the two lowest points in the wall for the interface distance.")

                            zs = list(range(num_vs))
                            zs.sort(key=lambda i: v[i].z)
                            perimeter = math.sqrt((v[zs[0]].x - v[zs[1]].x) ** 2 + (v[zs[0]].y - v[zs[1]].y) ** 2)

                        surf_height = surfaces[wl].get_average_height(state)
                        surf_height = round(surf_height * 1000.0) / 1000.0

                        key = (surfaces[wl].Construction, surf_height)
                        if key not in combination_map:
                            combination_map[key] = WallGroup(perimeter, [wl])
                        else:
                            combination_map[key].exposedPerimeter += perimeter
                            combination_map[key].wallIDs.append(wl)

                floor_aggregator = type('Aggregator', (), {})()

                assign_kiva_instances = True
                comb_iter = iter(sorted(combination_map.items()))
                try:
                    comb = next(comb_iter)
                except StopIteration:
                    comb = None

                while assign_kiva_instances:
                    if comb is not None:
                        construction_num = comb[0][0]
                        wall_height = comb[0][1]
                        perimeter = comb[1].exposedPerimeter
                        wall_ids = comb[1].wallIDs
                    else:
                        construction_num = self.foundationInputs[surface.OSCPtr].wallConstructionIndex
                        wall_height = 0.0
                        perimeter = remaining_exposed_perimeter

                    if total_exposed_perimeter > 0.001:
                        floor_weight = perimeter / total_exposed_perimeter
                    else:
                        floor_weight = 1.0

                    fnd = self.foundationInputs[surface.OSCPtr].foundation

                    fnd.useDetailedExposedPerimeter = use_detailed_exposed_perimeter
                    fnd.isExposedPerimeter = is_exposed_perimeter[:]
                    fnd.exposedFraction = exposed_fraction

                    if construction_num > 0:
                        c = constructs[construction_num]
                        fnd.wall.layers = []

                        for layer in range(c.TotLayers):
                            mat = materials[c.LayerPoint[layer]]
                            if mat.ROnly:
                                errors_found = True
                                from EnergyPlus import UtilityRoutines
                                UtilityRoutines.ShowSevereError(state, f"Construction=\"{c.Name}\", constructions referenced by surfaces with a")
                                UtilityRoutines.ShowContinueError(state, "\"Foundation\" Outside Boundary Condition must use only regular material objects")
                                UtilityRoutines.ShowContinueError(state, f"Material=\"{mat.Name}\", is not a regular material object")
                                return errors_found

                            temp_layer = type('Layer', (), {})()
                            temp_layer.material = type('Material', (), {})()
                            temp_layer.material.conductivity = mat.Conductivity
                            temp_layer.material.density = mat.Density
                            temp_layer.material.specificHeat = mat.SpecHeat
                            temp_layer.thickness = mat.Thickness

                            fnd.wall.layers.append(temp_layer)

                        fnd.wall.interior.emissivity = constructs[construction_num].InsideAbsorpThermal
                        fnd.wall.interior.absorptivity = constructs[construction_num].InsideAbsorpSolar
                        fnd.wall.exterior.emissivity = constructs[construction_num].OutsideAbsorpThermal
                        fnd.wall.exterior.absorptivity = constructs[construction_num].OutsideAbsorpSolar

                    fnd.slab.layers = []
                    for i in range(constructs[surface.Construction].TotLayers):
                        mat = materials[constructs[surface.Construction].LayerPoint[i]]
                        if mat.ROnly:
                            errors_found = True
                            from EnergyPlus import UtilityRoutines
                            UtilityRoutines.ShowSevereError(state, f"Construction=\"{constructs[surface.Construction].Name}\", constructions referenced by surfaces with a")
                            UtilityRoutines.ShowContinueError(state, "\"Foundation\" Outside Boundary Condition must use only regular material objects")
                            UtilityRoutines.ShowContinueError(state, f"Material=\"{mat.Name}\", is not a regular material object")
                            return errors_found

                        temp_layer = type('Layer', (), {})()
                        temp_layer.material = type('Material', (), {})()
                        temp_layer.material.conductivity = mat.Conductivity
                        temp_layer.material.density = mat.Density
                        temp_layer.material.specificHeat = mat.SpecHeat
                        temp_layer.thickness = mat.Thickness

                        fnd.slab.layers.append(temp_layer)

                    fnd.slab.interior.emissivity = constructs[surface.Construction].InsideAbsorpThermal
                    fnd.slab.interior.absorptivity = constructs[surface.Construction].InsideAbsorpSolar

                    fnd.foundationDepth = wall_height
                    fnd.hasPerimeterSurface = False
                    fnd.perimeterSurfaceWidth = 0.0

                    int_h_ins = self.foundationInputs[surface.OSCPtr].intHIns
                    int_v_ins = self.foundationInputs[surface.OSCPtr].intVIns
                    ext_h_ins = self.foundationInputs[surface.OSCPtr].extHIns
                    ext_v_ins = self.foundationInputs[surface.OSCPtr].extVIns
                    footing = self.foundationInputs[surface.OSCPtr].footing

                    if abs(int_h_ins.width) > 0.0:
                        int_h_ins.z += fnd.foundationDepth + fnd.slab.totalWidth()
                        fnd.inputBlocks.append(int_h_ins)
                    if abs(int_v_ins.width) > 0.0:
                        fnd.inputBlocks.append(int_v_ins)
                    if abs(ext_h_ins.width) > 0.0:
                        ext_h_ins.z += fnd.wall.heightAboveGrade
                        ext_h_ins.x = fnd.wall.totalWidth()
                        fnd.inputBlocks.append(ext_h_ins)
                    if abs(ext_v_ins.width) > 0.0:
                        ext_v_ins.x = fnd.wall.totalWidth()
                        fnd.inputBlocks.append(ext_v_ins)
                    if abs(footing.width) > 0.0:
                        footing.z = fnd.foundationDepth + fnd.slab.totalWidth() + fnd.wall.depthBelowSlab
                        footing.x = fnd.wall.totalWidth() / 2.0 - footing.width / 2.0
                        fnd.inputBlocks.append(footing)

                    init_deep_ground_depth = fnd.deepGroundDepth
                    fnd.deepGroundDepth = self.getDeepGroundDepth(fnd)

                    if fnd.deepGroundDepth > init_deep_ground_depth:
                        from EnergyPlus import UtilityRoutines
                        UtilityRoutines.ShowWarningError(state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\", the autocalculated deep ground depth ({fnd.deepGroundDepth:.3f} m) is shallower than foundation construction elements ({init_deep_ground_depth:.3f} m)")
                        UtilityRoutines.ShowContinueError(state, f"The deep ground depth will be set one meter below the lowest element ({fnd.deepGroundDepth:.3f} m)")

                    fnd.polygon = floor_polygon

                    Kiva.setMessageCallback(kivaErrorCallback, (state, f"Foundation:Kiva=\"{self.foundationInputs[surface.OSCPtr].name}\""))

                    self.kivaInstances.append(KivaInstanceMap(state, fnd, surf_num, wall_ids,
                                                              surface.Zone,
                                                              self.foundationInputs[surface.OSCPtr].assumedIndoorTemperature,
                                                              floor_weight, construction_num, self))

                    floor_aggregator.add_instance(self.kivaInstances[inst].instance.ground, floor_weight)

                    for wl in wall_ids:
                        self.surfaceMap[wl] = type('Aggregator', (), {})()
                        self.surfaceMap[wl].add_instance(self.kivaInstances[inst].instance.ground, 1.0)

                    inst += 1

                    if comb is not None:
                        try:
                            comb = next(comb_iter)
                        except StopIteration:
                            comb = None

                    remaining_exposed_perimeter -= perimeter

                    if remaining_exposed_perimeter < 0.001:
                        assign_kiva_instances = False
                        if remaining_exposed_perimeter < -0.1:
                            errors_found = True
                            from EnergyPlus import UtilityRoutines
                            UtilityRoutines.ShowSevereError(state, f"For Floor Surface=\"{surfaces[surf_num].Name}\", the Wall surfaces referencing")
                            UtilityRoutines.ShowContinueError(state, f"  the same Foundation:Kiva=\"{self.foundationInputs[surfaces[surf_num].OSCPtr].name}\" have")
                            UtilityRoutines.ShowContinueError(state, "  a combined length greater than the exposed perimeter of the foundation.")
                            UtilityRoutines.ShowContinueError(state, "  Ensure that each Wall surface shares at least one edge with the corresponding")
                            UtilityRoutines.ShowContinueError(state, "  Floor surface.")

                self.surfaceMap[surf_num] = floor_aggregator

            surf_num += 1

        for surf_num2 in state.dataSurface.AllHTKivaSurfaceList:
            if surf_num2 not in self.surfaceMap or self.surfaceMap[surf_num2].size() == 0:
                errors_found = True
                from EnergyPlus import UtilityRoutines
                UtilityRoutines.ShowSevereError(state, f"Surface=\"{surfaces[surf_num2].Name}\" has a 'Foundation' Outside Boundary Condition")
                UtilityRoutines.ShowContinueError(state, f"  referencing Foundation:Kiva=\"{self.foundationInputs[surfaces[surf_num2].OSCPtr].name}\".")
                if surfaces[surf_num2].Class == DataSurfaces.SurfaceClass.Wall:
                    UtilityRoutines.ShowContinueError(state, f"  You must also reference Foundation:Kiva=\"{self.foundationInputs[surfaces[surf_num2].OSCPtr].name}\"")
                    UtilityRoutines.ShowContinueError(state, f"  in a floor surface within the same Zone=\"{state.dataHeatBal.Zone[surfaces[surf_num2].Zone].Name}\".")
                elif surfaces[surf_num2].Class == DataSurfaces.SurfaceClass.Floor:
                    UtilityRoutines.ShowContinueError(state, "  However, this floor was never assigned to a Kiva instance.")
                    UtilityRoutines.ShowContinueError(state, "  This should not occur for floor surfaces. Please report to EnergyPlus Development Team.")
                else:
                    UtilityRoutines.ShowContinueError(state, "  Only floor and wall surfaces are allowed to reference 'Foundation' Outside Boundary Conditions.")
                    UtilityRoutines.ShowContinueError(state, f"  Surface=\"{surfaces[surf_num2].Name}\", is not a floor or wall.")

        state.files.eio.write("! <Kiva Foundation Name>, Horizontal Cells, Vertical Cells, Total Cells, Total Exposed Perimeter, Perimeter Fraction, Wall Height, Wall Construction, Floor Surface, Wall Surface(s)\n")

        for kv in self.kivaInstances:
            grnd = kv.instance.ground

            if kv.constructionNum <= 0:
                construction_name = "<Default Footing Wall Construction>"
            else:
                construction_name = state.dataConstruction.Construct[kv.constructionNum].Name

            wall_surface_string = ""
            for wl in kv.wallSurfaces:
                wall_surface_string += "," + state.dataSurface.Surface[wl].Name

            fmt = "{},{},{},{},{:.2f},{:.2f},{:.2f},{},{}{}\n"
            state.files.eio.write(fmt.format(
                self.foundationInputs[state.dataSurface.Surface[kv.floorSurface].OSCPtr].name,
                grnd.nX,
                grnd.nZ,
                grnd.nX * grnd.nZ,
                grnd.foundation.netPerimeter,
                kv.floorWeight,
                grnd.foundation.foundationDepth,
                construction_name,
                state.dataSurface.Surface[kv.floorSurface].Name,
                wall_surface_string))

        return errors_found

    def getDeepGroundDepth(self, fnd):
        total_depth_of_wall_below_grade = (fnd.wall.depthBelowSlab +
                                           (fnd.foundationDepth - fnd.wall.heightAboveGrade) +
                                           fnd.slab.totalWidth())
        if fnd.deepGroundDepth < total_depth_of_wall_below_grade + 1.0:
            fnd.deepGroundDepth = total_depth_of_wall_below_grade + 1.0

        for block in fnd.inputBlocks:
            if block.depth == 0.0:
                block.depth = fnd.foundationDepth
            if self.settings.deepGroundBoundary == Settings.AUTO:
                if block.z + block.depth + 1.0 > fnd.deepGroundDepth:
                    fnd.deepGroundDepth = block.z + block.depth + 1.0

        return fnd.deepGroundDepth

    def initKivaInstances(self, state):
        for kv in self.kivaInstances:
            kv.initGround(state, self.kivaWeather)
        self.calcKivaSurfaceResults(state)

    def calcKivaInstances(self, state):
        for kv in self.kivaInstances:
            kv.setBoundaryConditions(state)
            kv.instance.calculate(self.timestep)
            kv.instance.calculate_surface_averages()

        self.calcKivaSurfaceResults(state)

    def calcKivaSurfaceResults(self, state):
        for surf_num in state.dataSurface.AllHTKivaSurfaceList:
            Kiva.setMessageCallback(kivaErrorCallback, (state, f"Surface=\"{state.dataSurface.Surface[surf_num].Name}\""))
            self.surfaceMap[surf_num].calc_weighted_results()
            state.dataHeatBalSurf.SurfHConvInt[surf_num] = state.dataSurfaceGeometry.kivaManager.surfaceMap[surf_num].results.hconv

        Kiva.setMessageCallback(kivaErrorCallback, None)

    def defineDefaultFoundation(self, state):
        def_fnd = type('Foundation', (), {})()

        def_fnd.soil = type('Material', (), {})()
        def_fnd.soil.conductivity = self.settings.soilK
        def_fnd.soil.density = self.settings.soilRho
        def_fnd.soil.specificHeat = self.settings.soilCp

        def_fnd.grade = type('Grade', (), {})()
        def_fnd.grade.absorptivity = self.settings.groundSolarAbs
        def_fnd.grade.emissivity = self.settings.groundThermalAbs
        def_fnd.grade.roughness = self.settings.groundRoughness
        def_fnd.farFieldWidth = self.settings.farFieldWidth

        water_table_depth = 0.1022 * state.dataEnvrn.Elevation

        if self.settings.deepGroundBoundary == Settings.AUTO:
            if water_table_depth <= 40.0:
                def_fnd.deepGroundDepth = water_table_depth
                def_fnd.deepGroundBoundary = 1
            else:
                def_fnd.deepGroundDepth = 40.0
                def_fnd.deepGroundBoundary = 0
            if not self.settings.autocalculateDeepGroundDepth:
                if def_fnd.deepGroundDepth != self.settings.deepGroundDepth:
                    from EnergyPlus import UtilityRoutines
                    UtilityRoutines.ShowWarningError(state, "Foundation:Kiva:Settings, when Deep-Ground Boundary Condition is Autoselect,")
                    UtilityRoutines.ShowContinueError(state, f"the user-specified Deep-Ground Depth ({self.settings.deepGroundDepth:.1f} m)")
                    UtilityRoutines.ShowContinueError(state, f"will be overridden with the Autoselected depth ({def_fnd.deepGroundDepth:.1f} m)")
        elif self.settings.deepGroundBoundary == Settings.ZERO_FLUX:
            def_fnd.deepGroundDepth = self.settings.deepGroundDepth
            def_fnd.deepGroundBoundary = 0
        else:
            def_fnd.deepGroundDepth = self.settings.deepGroundDepth
            def_fnd.deepGroundBoundary = 1

        def_fnd.wall = type('Wall', (), {})()
        def_fnd.wall.heightAboveGrade = 0.2

        concrete = type('Material', (), {})()
        concrete.conductivity = 1.95
        concrete.density = 2400
        concrete.specificHeat = 900

        default_foundation_wall = type('Layer', (), {})()
        default_foundation_wall.thickness = 0.3
        default_foundation_wall.material = concrete

        def_fnd.wall.layers = [default_foundation_wall]

        def_fnd.wall.interior = type('Surface', (), {})()
        def_fnd.wall.interior.emissivity = 0.9
        def_fnd.wall.interior.absorptivity = 0.9
        def_fnd.wall.exterior = type('Surface', (), {})()
        def_fnd.wall.exterior.emissivity = 0.9
        def_fnd.wall.exterior.absorptivity = 0.9

        def_fnd.wall.depthBelowSlab = 0.0

        def_fnd.mesh = type('Mesh', (), {})()
        def_fnd.mesh.minCellDim = self.settings.minCellDim
        def_fnd.mesh.maxNearGrowthCoeff = self.settings.maxGrowthCoeff
        def_fnd.mesh.maxDepthGrowthCoeff = self.settings.maxGrowthCoeff
        def_fnd.mesh.maxInteriorGrowthCoeff = self.settings.maxGrowthCoeff
        def_fnd.mesh.maxExteriorGrowthCoeff = self.settings.maxGrowthCoeff

        self.defaultFoundation.foundation = def_fnd
        self.defaultFoundation.name = "<Default Foundation>"
        self.defaultFoundation.assumedIndoorTemperature = -9999

    def addDefaultFoundation(self):
        self.foundationInputs.append(self.defaultFoundation)
        self.defaultIndex = len(self.foundationInputs) - 1
        self.defaultAdded = True

    def findFoundation(self, name):
        fnd_num = 0
        for fnd in self.foundationInputs:
            if fnd.name == name:
                return fnd_num
            fnd_num += 1
        return len(self.foundationInputs)


def kivaErrorCallback(message_type, message, context_ptr):
    from EnergyPlus import UtilityRoutines, Kiva

    if context_ptr is None:
        raise RuntimeError(f"Unhandled Kiva Error: {message}")

    state, context_name = context_ptr
    if context_name:
        full_message = f"{context_name}: {message}"
    else:
        full_message = f"Kiva: {message}"

    if message_type == Kiva.MSG_INFO:
        UtilityRoutines.ShowMessage(state, full_message)
    elif message_type == Kiva.MSG_WARN:
        UtilityRoutines.ShowWarningError(state, full_message)
    else:
        UtilityRoutines.ShowSevereError(state, full_message)
        UtilityRoutines.ShowFatalError(state, "Kiva: Errors discovered, program terminates.")
