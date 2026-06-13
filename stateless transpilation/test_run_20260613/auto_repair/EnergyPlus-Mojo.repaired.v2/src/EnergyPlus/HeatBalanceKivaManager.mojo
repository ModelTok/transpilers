from libkiva.Aggregator import Aggregator
from libkiva.Ground import Ground
from libkiva.Instance import Instance
from libkiva.Errors import Errors
from EnergyPlus.Data.BaseData import BaseData
from .Data.EnergyPlusData import EnergyPlusData
from DataEnvironment import DataEnvironment
from DataHVACGlobals import DataHVACGlobals
from EnergyPlus.DataHeatBalSurface import DataHeatBalSurface
from DataHeatBalance import DataHeatBalance
from DataSurfaces import DataSurfaces
from DataSystemVariables import DataSystemVariables
from EnergyPlus.DataZoneControls import DataZoneControls
from Construction import Construction
from InternalHeatGains import InternalHeatGains
from Material import Material
from ScheduleManager import ScheduleManager
from SurfaceGeometry import SurfaceGeometry
from ThermalComfort import ThermalComfort
from UtilityRoutines import UtilityRoutines
from Vectors import Vectors
from WeatherManager import WeatherManager
from ZoneTempPredictorCorrector import ZoneTempPredictorCorrector
from WeatherManager import WeatherManager

# import stdlib
from memory import Pointer
from math import sqrt, exp, pow, log, atan2, acos, sin, cos, min, max
from python import Python

def kivaErrorCallback(messageType: Int, message: String, contextPtr: Pointer[UInt8]) raises:
    if contextPtr.is_null():
        throw FatalError(String.format("Unhandled Kiva Error: {}", message))
    var fullMessage: String
    var contextPair: PythonObject = Python.steal_from_ptr(contextPtr.bitcast[PythonObject]())
    if contextPair[1].__len__() > 0:
        fullMessage = String.format("{}: {}", contextPair[1], message)
    else:
        fullMessage = String.format("Kiva: {}", message)
    if messageType == Kiva.MSG_INFO:
        ShowMessage(contextPair[0], fullMessage)
    elif messageType == Kiva.MSG_WARN:
        ShowWarningError(contextPair[0], fullMessage)
    else:
        ShowSevereError(contextPair[0], fullMessage)
        ShowFatalError(contextPair[0], "Kiva: Errors discovered, program terminates.")

@value
struct KivaWeatherData:
    var intervalsPerHour: Int
    var annualAverageDrybulbTemp: Float64
    var dryBulb: List[Float64]
    var windSpeed: List[Float64]
    var skyEmissivity: List[Float64]

@value
struct FoundationKiva:
    var foundation: Kiva.Foundation
    var intHIns: Kiva.InputBlock
    var intVIns: Kiva.InputBlock
    var extHIns: Kiva.InputBlock
    var extVIns: Kiva.InputBlock
    var footing: Kiva.InputBlock
    var name: String
    var surfaces: List[Int]
    var wallConstructionIndex: Int = 0
    var assumedIndoorTemperature: Float64

@value
struct KivaInstanceMap:
    var instance: Kiva.Instance
    var floorSurface: Int
    var wallSurfaces: List[Int]
    var zoneNum: Int
    var zoneControlType: Int
    var zoneControlNum: Int
    var zoneAssumedTemperature: Float64
    var floorWeight: Float64
    var constructionNum: Int = 0
    var kmPtr: Pointer[KivaManager]

@value
struct KivaManager:
    var kivaWeather: KivaWeatherData
    var defaultFoundation: FoundationKiva
    var foundationInputs: List[FoundationKiva]
    var kivaInstances: List[KivaInstanceMap]
    var surfaceConvMap: Dict[Int, ConvectionAlgorithms]
    var surfaceMap: Dict[Int, Kiva.Aggregator]
    var timestep: Float64
    var settings: Settings
    var defaultAdded: Bool
    var defaultIndex: Int

    @value
    struct ConvectionAlgorithms:
        var in_: Kiva.ConvectionAlgorithm
        var out_: Kiva.ConvectionAlgorithm
        var f: Kiva.ForcedConvectionTerm

    @value
    struct Settings:
        var soilK: Float64
        var soilRho: Float64
        var soilCp: Float64
        var groundSolarAbs: Float64
        var groundThermalAbs: Float64
        var groundRoughness: Float64
        var farFieldWidth: Float64
        var deepGroundBoundary: DGType
        var deepGroundDepth: Float64
        var autocalculateDeepGroundDepth: Bool
        var minCellDim: Float64
        var maxGrowthCoeff: Float64
        var timestepType: TSType

        @value
        enum DGType:
            ZERO_FLUX
            GROUNDWATER
            AUTO

        @value
        enum TSType:
            HOURLY
            TIMESTEP

    @value
    struct WallGroup:
        var exposedPerimeter: Float64
        var wallIDs: List[Int]

def KivaInstanceMap.__init__(inout self, state: EnergyPlusData, foundation: Kiva.Foundation, floorSurface: Int, wallSurfaces: List[Int], zoneNum: Int, zoneAssumedTemperature: Float64, floorWeight: Float64, constructionNum: Int, kmPtr: Pointer[KivaManager]) raises:
    self.instance = Kiva.Instance(foundation)
    self.floorSurface = floorSurface
    self.wallSurfaces = wallSurfaces
    self.zoneNum = zoneNum
    self.zoneControlType = KIVAZONE_UNCONTROLLED
    self.zoneControlNum = 0
    self.zoneAssumedTemperature = zoneAssumedTemperature
    self.floorWeight = floorWeight
    self.constructionNum = constructionNum
    self.kmPtr = kmPtr
    for i in range(1, state.dataZoneCtrls.NumTempControlledZones + 1):
        if state.dataZoneCtrls.TempControlledZone[i].ActualZoneNum == zoneNum:
            self.zoneControlType = KIVAZONE_TEMPCONTROL
            self.zoneControlNum = i
            break
    for i in range(1, state.dataZoneCtrls.NumComfortControlledZones + 1):
        if state.dataZoneCtrls.ComfortControlledZone[i].ActualZoneNum == zoneNum:
            self.zoneControlType = KIVAZONE_COMFORTCONTROL
            self.zoneControlNum = i
            break
    for i in range(1, len(state.dataZoneCtrls.StageControlledZone) + 1):
        if state.dataZoneCtrls.StageControlledZone[i].ActualZoneNum == zoneNum:
            self.zoneControlType = KIVAZONE_STAGEDCONTROL
            self.zoneControlNum = i
            break

def KivaInstanceMap.initGround(inout self, state: EnergyPlusData, kivaWeather: KivaWeatherData) raises:
    var numAccelaratedTimesteps: Int = 3
    var acceleratedTimestep: Int = 30
    var accDate: Int = self.getAccDate(state, numAccelaratedTimesteps, acceleratedTimestep)
    self.instance.ground.foundation.numericalScheme = Kiva.Foundation.NS_STEADY_STATE
    self.setInitialBoundaryConditions(state, kivaWeather, accDate, 24, state.dataGlobal.TimeStepsInHour)
    self.instance.calculate()
    accDate += acceleratedTimestep
    while accDate > 365 + state.dataWeather.LeapYearAdd:
        accDate = accDate - (365 + state.dataWeather.LeapYearAdd)
    self.instance.ground.foundation.numericalScheme = Kiva.Foundation.NS_IMPLICIT
    for i in range(numAccelaratedTimesteps):
        self.setInitialBoundaryConditions(state, kivaWeather, accDate, 24, state.dataGlobal.TimeStepsInHour)
        self.instance.calculate(acceleratedTimestep * 24 * 60 * 60)
        accDate += acceleratedTimestep
        while accDate > 365 + state.dataWeather.LeapYearAdd:
            accDate = accDate - (365 + state.dataWeather.LeapYearAdd)
    self.instance.calculate_surface_averages()
    self.instance.foundation.numericalScheme = Kiva.Foundation.NS_ADI

def KivaInstanceMap.getAccDate(inout self, state: EnergyPlusData, numAccelaratedTimesteps: Int, acceleratedTimestep: Int) -> Int:
    var accDate: Int = state.dataEnvrn.DayOfYear - 1 - acceleratedTimestep * (numAccelaratedTimesteps + 1)
    while accDate <= 0:
        accDate = accDate + 365 + state.dataWeather.LeapYearAdd
    return accDate

def KivaInstanceMap.setInitialBoundaryConditions(inout self, state: EnergyPlusData, kivaWeather: KivaWeatherData, date: Int, hour: Int, timestep: Int) raises:
    var index: UInt
    var indexPrev: UInt
    var dataSize: UInt = len(kivaWeather.windSpeed)
    var weightNow: Float64
    if kivaWeather.intervalsPerHour == 1:
        index = (date - 1) * 24 + (hour - 1)
        weightNow = min(1.0, Float64(timestep) / Float64(state.dataGlobal.TimeStepsInHour))
    else:
        index = (date - 1) * 24 * state.dataGlobal.TimeStepsInHour + (hour - 1) * state.dataGlobal.TimeStepsInHour + (timestep - 1)
        weightNow = 1.0
    if index == 0:
        indexPrev = dataSize - 1
    else:
        indexPrev = index - 1
    self.instance.bcs = Kiva.BoundaryConditions()
    var bcs: Pointer[Kiva.BoundaryConditions] = self.instance.bcs
    bcs.outdoorTemp = kivaWeather.dryBulb[index] * weightNow + kivaWeather.dryBulb[indexPrev] * (1.0 - weightNow) + Constant.Kelvin
    bcs.localWindSpeed = (kivaWeather.windSpeed[index] * weightNow + kivaWeather.windSpeed[indexPrev] * (1.0 - weightNow)) * state.dataEnvrn.WeatherFileWindModCoeff * pow(self.instance.ground.foundation.grade.roughness / state.dataEnvrn.SiteWindBLHeight, state.dataEnvrn.SiteWindExp)
    bcs.skyEmissivity = kivaWeather.skyEmissivity[index] * weightNow + kivaWeather.skyEmissivity[indexPrev] * (1.0 - weightNow)
    bcs.solarAzimuth = 3.14
    bcs.solarAltitude = 0.0
    bcs.directNormalFlux = 0.0
    bcs.diffuseHorizontalFlux = 0.0
    bcs.slabAbsRadiation = 0.0
    bcs.wallAbsRadiation = 0.0
    bcs.deepGroundTemperature = kivaWeather.annualAverageDrybulbTemp + Constant.Kelvin
    var defaultFlagTemp: Float64 = -999
    var standardTemp: Float64 = 22
    var assumedFloatingTemp: Float64 = standardTemp
    var Tin: Float64
    if self.zoneAssumedTemperature > defaultFlagTemp:
        Tin = self.zoneAssumedTemperature + Constant.Kelvin
    else:
        if self.zoneControlType == KIVAZONE_UNCONTROLLED:
            Tin = assumedFloatingTemp + Constant.Kelvin
        elif self.zoneControlType == KIVAZONE_TEMPCONTROL:
            var ctrlTypeSched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setptTypeSched
            var controlType: HVAC.SetptType = HVAC.SetptType(ctrlTypeSched.getHrTsVal(state, hour, timestep))
            if controlType == HVAC.SetptType.Uncontrolled:
                Tin = assumedFloatingTemp + Constant.Kelvin
            elif controlType == HVAC.SetptType.SingleHeat:
                var sched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[Int(controlType)].heatSetptSched
                var setpoint: Float64 = sched.getHrTsVal(state, hour, timestep)
                Tin = setpoint + Constant.Kelvin
            elif controlType == HVAC.SetptType.SingleCool:
                var sched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[Int(controlType)].coolSetptSched
                var setpoint: Float64 = sched.getHrTsVal(state, hour, timestep)
                Tin = setpoint + Constant.Kelvin
            elif controlType == HVAC.SetptType.SingleHeatCool:
                var sched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[Int(controlType)].heatSetptSched
                var setpoint: Float64 = sched.getHrTsVal(state, hour, timestep)
                Tin = setpoint + Constant.Kelvin
            elif controlType == HVAC.SetptType.DualHeatCool:
                var heatSched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[Int(controlType)].heatSetptSched
                var coolSched: Pointer[Schedule] = state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setpts[Int(controlType)].coolSetptSched
                var heatSetpoint: Float64 = heatSched.getHrTsVal(state, hour, timestep)
                var coolSetpoint: Float64 = coolSched.getHrTsVal(state, hour, timestep)
                var heatBalanceTemp: Float64 = 10.0 + Constant.Kelvin
                var coolBalanceTemp: Float64 = 15.0 + Constant.Kelvin
                if bcs.outdoorTemp < heatBalanceTemp:
                    Tin = heatSetpoint + Constant.Kelvin
                elif bcs.outdoorTemp > coolBalanceTemp:
                    Tin = coolSetpoint + Constant.Kelvin
                else:
                    var weight: Float64 = (coolBalanceTemp - bcs.outdoorTemp) / (coolBalanceTemp - heatBalanceTemp)
                    Tin = heatSetpoint * weight + coolSetpoint * (1.0 - weight) + Constant.Kelvin
            else:
                Tin = 0.0
                ShowSevereError(state, String.format("Illegal control type for Zone={}, Found value={}, in Schedule={}", state.dataHeatBal.Zone[self.zoneNum].Name, Int(controlType), state.dataZoneCtrls.TempControlledZone[self.zoneControlNum].setptTypeSched.Name))
        elif self.zoneControlType == KIVAZONE_COMFORTCONTROL:
            Tin = standardTemp + Constant.Kelvin
        elif self.zoneControlType == KIVAZONE_STAGEDCONTROL:
            var heatSched: Pointer[Schedule] = state.dataZoneCtrls.StageControlledZone[self.zoneControlNum].heatSetptBaseSched
            var coolSched: Pointer[Schedule] = state.dataZoneCtrls.StageControlledZone[self.zoneControlNum].coolSetptBaseSched
            var heatSetpoint: Float64 = heatSched.getHrTsVal(state, hour, timestep)
            var coolSetpoint: Float64 = coolSched.getHrTsVal(state, hour, timestep)
            var heatBalanceTemp: Float64 = 10.0 + Constant.Kelvin
            var coolBalanceTemp: Float64 = 15.0 + Constant.Kelvin
            if bcs.outdoorTemp < heatBalanceTemp:
                Tin = heatSetpoint + Constant.Kelvin
            elif bcs.outdoorTemp > coolBalanceTemp:
                Tin = coolSetpoint + Constant.Kelvin
            else:
                var weight: Float64 = (coolBalanceTemp - bcs.outdoorTemp) / (coolBalanceTemp - heatBalanceTemp)
                Tin = heatSetpoint * weight + coolSetpoint * (1.0 - weight) + Constant.Kelvin
        else:
            Tin = assumedFloatingTemp + Constant.Kelvin
    bcs.slabConvectiveTemp = bcs.wallConvectiveTemp = bcs.slabRadiantTemp = bcs.wallRadiantTemp = Tin
    bcs.gradeForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
    bcs.gradeConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out_
    bcs.slabConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].in_
    if len(self.wallSurfaces) > 0:
        bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].f
        bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].out_
        bcs.intWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].in_
    else:
        bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
        bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out_

def KivaInstanceMap.setBoundaryConditions(inout self, state: EnergyPlusData) raises:
    var bcs: Pointer[Kiva.BoundaryConditions] = self.instance.bcs
    bcs.outdoorTemp = state.dataEnvrn.OutDryBulbTemp + Constant.Kelvin
    bcs.localWindSpeed = DataEnvironment.WindSpeedAt(state, self.instance.ground.foundation.grade.roughness)
    bcs.windDirection = state.dataEnvrn.WindDir * Constant.DegToRad
    bcs.solarAzimuth = atan2(state.dataEnvrn.SOLCOS[1], state.dataEnvrn.SOLCOS[2])
    bcs.solarAltitude = Constant.PiOvr2 - acos(state.dataEnvrn.SOLCOS[3])
    bcs.directNormalFlux = state.dataEnvrn.BeamSolarRad
    bcs.diffuseHorizontalFlux = state.dataEnvrn.DifSolarRad
    bcs.skyEmissivity = pow(state.dataEnvrn.SkyTempKelvin, 4) / pow(bcs.outdoorTemp, 4)
    bcs.slabAbsRadiation = state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[self.floorSurface] + state.dataHeatBal.SurfQdotRadIntGainsInPerArea[self.floorSurface] + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[self.floorSurface]
    bcs.slabConvectiveTemp = state.dataHeatBal.SurfTempEffBulkAir[self.floorSurface] + Constant.Kelvin
    bcs.slabRadiantTemp = ThermalComfort.CalcSurfaceWeightedMRT(state, self.floorSurface, False) + Constant.Kelvin
    bcs.gradeForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
    bcs.gradeConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out_
    bcs.slabConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].in_
    var QAtotal: Float64 = 0.0
    var Atotal: Float64 = 0.0
    var TARadTotal: Float64 = 0.0
    var TAConvTotal: Float64 = 0.0
    for wl in self.wallSurfaces:
        var Q: Float64 = state.dataHeatBalSurf.SurfOpaqQRadSWInAbs[wl] + state.dataHeatBal.SurfQdotRadIntGainsInPerArea[wl] + state.dataHeatBalSurf.SurfQdotRadHVACInPerArea[wl]
        var A: Float64 = state.dataSurface.Surface[wl].Area
        var Trad: Float64 = ThermalComfort.CalcSurfaceWeightedMRT(state, wl, False)
        var Tconv: Float64 = state.dataHeatBal.SurfTempEffBulkAir[wl]
        QAtotal += Q * A
        TARadTotal += Trad * A
        TAConvTotal += Tconv * A
        Atotal += A
    if Atotal > 0.0:
        bcs.wallAbsRadiation = QAtotal / Atotal
        bcs.wallRadiantTemp = TARadTotal / Atotal + Constant.Kelvin
        bcs.wallConvectiveTemp = TAConvTotal / Atotal + Constant.Kelvin
        bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].f
        bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].out_
        bcs.intWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.wallSurfaces[0]].in_
    else:
        bcs.extWallForcedTerm = self.kmPtr.surfaceConvMap[self.floorSurface].f
        bcs.extWallConvectionAlgorithm = self.kmPtr.surfaceConvMap[self.floorSurface].out_

def KivaManager.Settings.__init__(inout self):
    self.soilK = 0.864
    self.soilRho = 1510
    self.soilCp = 1260
    self.groundSolarAbs = 0.9
    self.groundThermalAbs = 0.9
    self.groundRoughness = 0.9
    self.farFieldWidth = 40.0
    self.deepGroundBoundary = Settings.DGType.AUTO
    self.deepGroundDepth = 40.0
    self.autocalculateDeepGroundDepth = True
    self.minCellDim = 0.02
    self.maxGrowthCoeff = 1.5
    self.timestepType = Settings.TSType.HOURLY

def KivaManager.WallGroup.__init__(inout self, exposedPerimeter: Float64, wallIDs: List[Int]):
    self.exposedPerimeter = exposedPerimeter
    self.wallIDs = wallIDs

def KivaManager.WallGroup.__init__(inout self):
    self.exposedPerimeter = 0.0
    self.wallIDs = List[Int]()

def KivaManager.__init__(inout self):
    self.timestep = 3600
    self.defaultAdded = False
    self.defaultIndex = 0

def KivaManager.__del__(inout self):

def KivaManager.readWeatherData(inout self, state: EnergyPlusData) raises:
    var kivaWeatherFile = state.files.inputWeatherFilePath.open(state, "KivaManager::readWeatherFile")
    var Header: List[String] = List[String]("LOCATION", "DESIGN CONDITIONS", "TYPICAL/EXTREME PERIODS", "GROUND TEMPERATURES", "HOLIDAYS/DAYLIGHT SAVING", "COMMENTS 1", "COMMENTS 2", "DATA PERIODS")
    var HdLine: Int = 1
    var StillLooking: Bool = True
    while StillLooking:
        var LineResult = kivaWeatherFile.readLine()
        if LineResult.eof:
            ShowFatalError(state, String.format("Kiva::ReadWeatherFile: Unexpected End-of-File on EPW Weather file, while reading header information, looking for header={}", Header[HdLine - 1]))
        var endcol: Int = len(LineResult.data)
        if endcol > 0:
            if Int(LineResult.data[endcol - 1]) == DataSystemVariables.iUnicode_end:
                ShowSevereError(state, "OpenWeatherFile: EPW Weather File appears to be a Unicode or binary file.")
                ShowContinueError(state, "...This file cannot be read by this program. Please save as PC or Unix file and try again")
                ShowFatalError(state, "Program terminates due to previous condition.")
        var Pos: Int = FindNonSpace(LineResult.data)
        var HdPos: Int = index(LineResult.data, Header[HdLine - 1])
        if Pos != HdPos:
            continue
        Pos = index(LineResult.data, ',')
        if (Pos == -1) and (not has_prefixi(Header[HdLine - 1], "COMMENTS")):
            ShowSevereError(state, "Invalid Header line in in.epw -- no commas")
            ShowContinueError(state, String.format("Line={}", LineResult.data))
            ShowFatalError(state, "Previous conditions cause termination.")
        if Pos != -1:
            LineResult.data = LineResult.data[Pos + 1:]
        if Util.makeUPPER(Header[HdLine - 1]) == "DATA PERIODS":
            var IOStatus: Bool
            uppercase(LineResult.data)
            var NumHdArgs: Int = 2
            var Count: Int = 1
            while Count <= NumHdArgs:
                strip(LineResult.data)
                Pos = index(LineResult.data, ',')
                if Pos == -1:
                    if len(LineResult.data) == 0:
                        while Pos == -1:
                            LineResult.update(kivaWeatherFile.readLine())
                            strip(LineResult.data)
                            uppercase(LineResult.data)
                            Pos = index(LineResult.data, ',')
                    else:
                        Pos = len(LineResult.data)
                if Count == 1:
                    NumHdArgs += 4 * Util.ProcessNumber(LineResult.data[:Pos], IOStatus)
                elif Count == 2:
                    self.kivaWeather.intervalsPerHour = Util.ProcessNumber(LineResult.data[:Pos], IOStatus)
                LineResult.data = LineResult.data[Pos + 1:]
                Count += 1
        HdLine += 1
        if HdLine == 9:
            StillLooking = False
    var ErrorFound: Bool = False
    var WYear: Int
    var WMonth: Int
    var WDay: Int
    var WHour: Int
    var WMinute: Int
    var DryBulb: Float64
    var DewPoint: Float64
    var RelHum: Float64
    var AtmPress: Float64
    var ETHoriz: Float64
    var ETDirect: Float64
    var IRHoriz: Float64
    var GLBHoriz: Float64
    var DirectRad: Float64
    var DiffuseRad: Float64
    var GLBHorizIllum: Float64
    var DirectNrmIllum: Float64
    var DiffuseHorizIllum: Float64
    var ZenLum: Float64
    var WindDir: Float64
    var WindSpeed: Float64
    var TotalSkyCover: Float64
    var OpaqueSkyCover: Float64
    var Visibility: Float64
    var CeilHeight: Float64
    var PrecipWater: Float64
    var AerosolOptDepth: Float64
    var SnowDepth: Float64
    var DaysSinceLastSnow: Float64
    var Albedo: Float64
    var LiquidPrecip: Float64
    var PresWeathObs: Int
    var PresWeathConds: List[Int] = List[Int](9)
    var totalDB: Float64 = 0.0
    var count: Int = 0
    while True:
        var WeatherDataLine = kivaWeatherFile.readLine()
        if WeatherDataLine.eof:
            break
        Weather.InterpretWeatherDataLine(state, WeatherDataLine.data, ErrorFound, WYear, WMonth, WDay, WHour, WMinute, DryBulb, DewPoint, RelHum, AtmPress, ETHoriz, ETDirect, IRHoriz, GLBHoriz, DirectRad, DiffuseRad, GLBHorizIllum, DirectNrmIllum, DiffuseHorizIllum, ZenLum, WindDir, WindSpeed, TotalSkyCover, OpaqueSkyCover, Visibility, CeilHeight, PresWeathObs, PresWeathConds, PrecipWater, AerosolOptDepth, SnowDepth, DaysSinceLastSnow, Albedo, LiquidPrecip)
        if DryBulb >= 99.9:
            DryBulb = state.dataWeather.wvarsMissing.OutDryBulbTemp
        if DewPoint >= 99.9:
            DewPoint = state.dataWeather.wvarsMissing.OutDewPointTemp
        if WindSpeed >= 999.0:
            WindSpeed = state.dataWeather.wvarsMissing.WindSpeed
        if OpaqueSkyCover >= 99.0:
            OpaqueSkyCover = state.dataWeather.wvarsMissing.OpaqueSkyCover
        self.kivaWeather.dryBulb.append(DryBulb)
        self.kivaWeather.windSpeed.append(WindSpeed)
        var OSky: Float64 = OpaqueSkyCover
        var TDewK: Float64 = min(DryBulb, DewPoint) + Constant.Kelvin
        var ESky: Float64 = (0.787 + 0.764 * log(TDewK / Constant.Kelvin)) * (1.0 + 0.0224 * OSky - 0.0035 * pow(OSky, 2) + 0.00028 * pow(OSky, 3))
        self.kivaWeather.skyEmissivity.append(ESky)
        count += 1
        totalDB += DryBulb
    self.kivaWeather.annualAverageDrybulbTemp = totalDB / Float64(count)

def KivaManager.setupKivaInstances(inout self, state: EnergyPlusData) -> Bool raises:
    var contextPair: PythonObject = Python.make_tuple(state, "")
    Kiva.setMessageCallback(kivaErrorCallback, contextPair)
    var ErrorsFound: Bool = False
    if state.dataZoneCtrls.GetZoneAirStatsInputFlag:
        ZoneTempPredictorCorrector.GetZoneAirSetPoints(state)
        state.dataZoneCtrls.GetZoneAirStatsInputFlag = False
    self.readWeatherData(state)
    var Surfaces = state.dataSurface.Surface
    var Constructs = state.dataConstruction.Construct
    var materials = state.dataMaterial.materials
    var inst: Int = 0
    var surfNum: Int = 1
    for surface in Surfaces:
        if surface.ExtBoundCond == DataSurfaces.KivaFoundation and surface.Class == DataSurfaces.SurfaceClass.Floor:
            var wallSurfaces: List[Int] = List[Int]()
            for wl in self.foundationInputs[surface.OSCPtr].surfaces:
                if Surfaces[wl].Zone == surface.Zone and wl != surfNum:
                    if Surfaces[wl].Class != DataSurfaces.SurfaceClass.Wall:
                        if Surfaces[wl].Class == DataSurfaces.SurfaceClass.Floor:
                            ErrorsFound = True
                            ShowSevereError(state, String.format("Foundation:Kiva=\"{}\", only one floor per Foundation:Kiva Object allowed.", self.foundationInputs[surface.OSCPtr].name))
                        else:
                            ErrorsFound = True
                            ShowSevereError(state, String.format("Foundation:Kiva=\"{}\", only floor and wall surfaces are allowed to reference Foundation Outside Boundary Conditions.", self.foundationInputs[surface.OSCPtr].name))
                            ShowContinueError(state, String.format("Surface=\"{}\", is not a floor or wall.", Surfaces[wl].Name))
                    else:
                        wallSurfaces.append(wl)
            var isExposedPerimeter: List[Bool] = List[Bool]()
            var userSetExposedPerimeter: Bool = False
            var useDetailedExposedPerimeter: Bool = False
            var exposedFraction: Float64 = 0.0
            var expPerimMap = state.dataSurfaceGeometry.exposedFoundationPerimeter.surfaceMap
            if expPerimMap.count(surfNum) == 1:
                userSetExposedPerimeter = True
                useDetailedExposedPerimeter = expPerimMap[surfNum].useDetailedExposedPerimeter
                if useDetailedExposedPerimeter:
                    for s in expPerimMap[surfNum].isExposedPerimeter:
                        isExposedPerimeter.append(s)
                else:
                    exposedFraction = expPerimMap[surfNum].exposedFraction
            else:
                ErrorsFound = True
                ShowSevereError(state, String.format("Surface=\"{}\", references a Foundation Outside Boundary Condition but there is no corresponding SURFACEPROPERTY:EXPOSEDFOUNDATIONPERIMETER object defined.", Surfaces[surfNum].Name))
            var floorPolygon: Kiva.Polygon = Kiva.Polygon()
            for v in surface.Vertex:
                floorPolygon.outer().append(Kiva.Point(v.x, v.y))
                if not userSetExposedPerimeter:
                    isExposedPerimeter.append(True)
            var totalPerimeter: Float64 = 0.0
            for i in range(len(surface.Vertex)):
                var iNext: Int
                if i == len(surface.Vertex) - 1:
                    iNext = 0
                else:
                    iNext = i + 1
                var v = surface.Vertex[i]
                var vNext = surface.Vertex[iNext]
                totalPerimeter += distance(v, vNext)
            if useDetailedExposedPerimeter:
                var total2DPerimeter: Float64 = 0.0
                var exposed2DPerimeter: Float64 = 0.0
                for i in range(len(floorPolygon.outer())):
                    var iNext: Int
                    if i == len(floorPolygon.outer()) - 1:
                        iNext = 0
                    else:
                        iNext = i + 1
                    var p = floorPolygon.outer()[i]
                    var pNext = floorPolygon.outer()[iNext]
                    var perim: Float64 = Kiva.getDistance(p, pNext)
                    total2DPerimeter += perim
                    if isExposedPerimeter[i]:
                        exposed2DPerimeter += perim
                    else:
                        exposed2DPerimeter += 0.0
                exposedFraction = min(exposed2DPerimeter / total2DPerimeter, 1.0)
            var totalExposedPerimeter: Float64 = exposedFraction * totalPerimeter
            var remainingExposedPerimeter: Float64 = totalExposedPerimeter
            var combinationMap: Dict[Tuple[Int, Float64], WallGroup] = Dict[Tuple[Int, Float64], WallGroup]()
            if len(wallSurfaces) > 0:
                for wl in wallSurfaces:
                    var v = Surfaces[wl].Vertex
                    var numVs: Int = len(v)
                    if numVs > 4:
                        ShowWarningError(state, String.format("Foundation:Kiva=\"{}\", wall surfaces with more than four vertices referencing", self.foundationInputs[surface.OSCPtr].name))
                        ShowContinueError(state, "...Foundation Outside Boundary Conditions may not be interpreted correctly in the 2D finite difference model.")
                        ShowContinueError(state, String.format("Surface=\"{}\", has {} vertices.", Surfaces[wl].Name, numVs))
                        ShowContinueError(state, "Consider separating the wall into separate surfaces, each spanning from the floor slab to the top of the foundation wall.")
                    var coplanarPoints: List[Int] = Vectors.PointsInPlane(Surfaces[surfNum].Vertex, Surfaces[surfNum].Sides, Surfaces[wl].Vertex, Surfaces[wl].Sides, ErrorsFound)
                    var perimeter: Float64 = 0.0
                    for i in range(len(coplanarPoints)):
                        var p: Int = coplanarPoints[i]
                        var pC: Int = p if p == Int(len(v)) else p + 1
                        var p2: Int = coplanarPoints[0] if i == len(coplanarPoints) - 1 else coplanarPoints[i + 1]
                        if p2 == pC:
                            perimeter += distance(v[p], v[p2])
                    if perimeter == 0.0:
                        ShowWarningError(state, String.format("Foundation:Kiva=\"{}\".", self.foundationInputs[surface.OSCPtr].name))
                        ShowContinueError(state, String.format("   Wall Surface=\"{}\", does not have any vertices that are", Surfaces[wl].Name))
                        ShowContinueError(state, String.format("   coplanar with the corresponding Floor Surface=\"{}\".", Surfaces[surfNum].Name))
                        ShowContinueError(state, "   Simulation will continue using the distance between the two lowest points in the wall for the interface distance.")
                        var zs: List[Int] = List[Int]()
                        for i in range(numVs):
                            zs.append(i)
                        sort(zs, def (a: Int, b: Int) -> Bool: return v[a].z < v[b].z)
                        perimeter = distance(v[zs[0]], v[zs[1]])
                    var surfHeight: Float64 = Surfaces[wl].get_average_height(state)
                    surfHeight = round(surfHeight * 1000.0) / 1000.0
                    var key: Tuple[Int, Float64] = (Surfaces[wl].Construction, surfHeight)
                    if not combinationMap.__contains__(key):
                        var walls: List[Int] = List[Int](wl)
                        combinationMap[key] = WallGroup(perimeter, walls)
                    else:
                        combinationMap[key].exposedPerimeter += perimeter
                        combinationMap[key].wallIDs.append(wl)
            var floorAggregator: Kiva.Aggregator = Kiva.Aggregator(Kiva.Surface.ST_SLAB_CORE)
            var assignKivaInstances: Bool = True
            var comb: Int = 0
            var combKeys: List[Tuple[Int, Float64]] = List[Tuple[Int, Float64]]()
            for key in combinationMap.keys():
                combKeys.append(key)
            while assignKivaInstances:
                var constructionNum: Int
                var wallHeight: Float64
                var perimeter: Float64
                var wallIDs: List[Int]
                if comb < len(combKeys):
                    var key: Tuple[Int, Float64] = combKeys[comb]
                    constructionNum = key[0]
                    wallHeight = key[1]
                    perimeter = combinationMap[key].exposedPerimeter
                    wallIDs = combinationMap[key].wallIDs
                else:
                    constructionNum = self.foundationInputs[surface.OSCPtr].wallConstructionIndex
                    wallHeight = 0.0
                    perimeter = remainingExposedPerimeter
                var floorWeight: Float64
                if totalExposedPerimeter > 0.001:
                    floorWeight = perimeter / totalExposedPerimeter
                else:
                    floorWeight = 1.0
                var fnd: Kiva.Foundation = self.foundationInputs[surface.OSCPtr].foundation
                fnd.useDetailedExposedPerimeter = useDetailedExposedPerimeter
                fnd.isExposedPerimeter = isExposedPerimeter
                fnd.exposedFraction = exposedFraction
                if constructionNum > 0:
                    var c = Constructs[constructionNum]
                    fnd.wall.layers.clear()
                    for layer in range(1, c.TotLayers + 1):
                        var mat = materials[c.LayerPoint[layer]]
                        if mat.ROnly:
                            ErrorsFound = True
                            ShowSevereError(state, String.format("Construction=\"{}\", constructions referenced by surfaces with a", c.Name))
                            ShowContinueError(state, "\"Foundation\" Outside Boundary Condition must use only regular material objects")
                            ShowContinueError(state, String.format("Material=\"{}\", is not a regular material object", mat.Name))
                            return ErrorsFound
                        var tempLayer: Kiva.Layer = Kiva.Layer()
                        tempLayer.material = Kiva.Material(mat.Conductivity, mat.Density, mat.SpecHeat)
                        tempLayer.thickness = mat.Thickness
                        fnd.wall.layers.append(tempLayer)
                    fnd.wall.interior.emissivity = Constructs[constructionNum].InsideAbsorpThermal
                    fnd.wall.interior.absorptivity = Constructs[constructionNum].InsideAbsorpSolar
                    fnd.wall.exterior.emissivity = Constructs[constructionNum].OutsideAbsorpThermal
                    fnd.wall.exterior.absorptivity = Constructs[constructionNum].OutsideAbsorpSolar
                for i in range(Constructs[surface.Construction].TotLayers):
                    var mat = materials[Constructs[surface.Construction].LayerPoint[i]]
                    if mat.ROnly:
                        ErrorsFound = True
                        ShowSevereError(state, String.format("Construction=\"{}\", constructions referenced by surfaces with a", Constructs[surface.Construction].Name))
                        ShowContinueError(state, "\"Foundation\" Outside Boundary Condition must use only regular material objects")
                        ShowContinueError(state, String.format("Material=\"{}\", is not a regular material object", mat.Name))
                        return ErrorsFound
                    var tempLayer: Kiva.Layer = Kiva.Layer()
                    tempLayer.material = Kiva.Material(mat.Conductivity, mat.Density, mat.SpecHeat)
                    tempLayer.thickness = mat.Thickness
                    fnd.slab.layers.append(tempLayer)
                fnd.slab.interior.emissivity = Constructs[surface.Construction].InsideAbsorpThermal
                fnd.slab.interior.absorptivity = Constructs[surface.Construction].InsideAbsorpSolar
                fnd.foundationDepth = wallHeight
                fnd.hasPerimeterSurface = False
                fnd.perimeterSurfaceWidth = 0.0
                var intHIns: Kiva.InputBlock = self.foundationInputs[surface.OSCPtr].intHIns
                var intVIns: Kiva.InputBlock = self.foundationInputs[surface.OSCPtr].intVIns
                var extHIns: Kiva.InputBlock = self.foundationInputs[surface.OSCPtr].extHIns
                var extVIns: Kiva.InputBlock = self.foundationInputs[surface.OSCPtr].extVIns
                var footing: Kiva.InputBlock = self.foundationInputs[surface.OSCPtr].footing
                if abs(intHIns.width) > 0.0:
                    intHIns.z += fnd.foundationDepth + fnd.slab.totalWidth()
                    fnd.inputBlocks.append(intHIns)
                if abs(intVIns.width) > 0.0:
                    fnd.inputBlocks.append(intVIns)
                if abs(extHIns.width) > 0.0:
                    extHIns.z += fnd.wall.heightAboveGrade
                    extHIns.x = fnd.wall.totalWidth()
                    fnd.inputBlocks.append(extHIns)
                if abs(extVIns.width) > 0.0:
                    extVIns.x = fnd.wall.totalWidth()
                    fnd.inputBlocks.append(extVIns)
                if abs(footing.width) > 0.0:
                    footing.z = fnd.foundationDepth + fnd.slab.totalWidth() + fnd.wall.depthBelowSlab
                    footing.x = fnd.wall.totalWidth() / 2.0 - footing.width / 2.0
                    fnd.inputBlocks.append(footing)
                var initDeepGroundDepth: Float64 = fnd.deepGroundDepth
                fnd.deepGroundDepth = self.getDeepGroundDepth(fnd)
                if fnd.deepGroundDepth > initDeepGroundDepth:
                    ShowWarningError(state, String.format("Foundation:Kiva=\"{}\", the autocalculated deep ground depth ({:.3f} m) is shallower than foundation construction elements ({:.3f} m)", self.foundationInputs[surface.OSCPtr].name, initDeepGroundDepth, fnd.deepGroundDepth - 1.0))
                    ShowContinueError(state, String.format("The deep ground depth will be set one meter below the lowest element ({:.3f} m)", fnd.deepGroundDepth))
                fnd.polygon = floorPolygon
                var contexPair2: PythonObject = Python.make_tuple(state, String.format("Foundation:Kiva=\"{}\"", self.foundationInputs[surface.OSCPtr].name))
                Kiva.setMessageCallback(kivaErrorCallback, contexPair2)
                self.kivaInstances.append(KivaInstanceMap(state, fnd, surfNum, wallIDs, surface.Zone, self.foundationInputs[surface.OSCPtr].assumedIndoorTemperature, floorWeight, constructionNum, Pointer[KivaManager](addressof(self))))
                floorAggregator.add_instance(self.kivaInstances[inst].instance.ground.get(), floorWeight)
                for wl in wallIDs:
                    self.surfaceMap[wl] = Kiva.Aggregator(Kiva.Surface.ST_WALL_INT)
                    self.surfaceMap[wl].add_instance(self.kivaInstances[inst].instance.ground.get(), 1.0)
                inst += 1
                if comb < len(combKeys):
                    comb += 1
                remainingExposedPerimeter -= perimeter
                if remainingExposedPerimeter < 0.001:
                    assignKivaInstances = False
                    if remainingExposedPerimeter < -0.1:
                        ErrorsFound = True
                        ShowSevereError(state, String.format("For Floor Surface=\"{}\", the Wall surfaces referencing", Surfaces[surfNum].Name))
                        ShowContinueError(state, String.format("  the same Foundation:Kiva=\"{}\" have", self.foundationInputs[Surfaces[surfNum].OSCPtr].name))
                        ShowContinueError(state, "  a combined length greater than the exposed perimeter of the foundation.")
                        ShowContinueError(state, "  Ensure that each Wall surface shares at least one edge with the corresponding")
                        ShowContinueError(state, "  Floor surface.")
            self.surfaceMap[surfNum] = floorAggregator
        surfNum += 1
    for surfNum2 in state.dataSurface.AllHTKivaSurfaceList:
        if len(self.surfaceMap[surfNum2]) == 0:
            ErrorsFound = True
            ShowSevereError(state, String.format("Surface=\"{}\" has a 'Foundation' Outside Boundary Condition", Surfaces[surfNum].Name))
            ShowContinueError(state, String.format("  referencing Foundation:Kiva=\"{}\".", self.foundationInputs[Surfaces[surfNum].OSCPtr].name))
            if Surfaces[surfNum2].Class == DataSurfaces.SurfaceClass.Wall:
                ShowContinueError(state, String.format("  You must also reference Foundation:Kiva=\"{}\"", self.foundationInputs[Surfaces[surfNum].OSCPtr].name))
                ShowContinueError(state, String.format("  in a floor surface within the same Zone=\"{}\".", state.dataHeatBal.Zone[Surfaces[surfNum].Zone].Name))
            elif Surfaces[surfNum2].Class == DataSurfaces.SurfaceClass.Floor:
                ShowContinueError(state, "  However, this floor was never assigned to a Kiva instance.")
                ShowContinueError(state, "  This should not occur for floor surfaces. Please report to EnergyPlus Development Team.")
            else:
                ShowContinueError(state, "  Only floor and wall surfaces are allowed to reference 'Foundation' Outside Boundary Conditions.")
                ShowContinueError(state, String.format("  Surface=\"{}\", is not a floor or wall.", Surfaces[surfNum].Name))
    print(state.files.eio, "{}", "! <Kiva Foundation Name>, Horizontal Cells, Vertical Cells, Total Cells, Total Exposed Perimeter, Perimeter Fraction, Wall Height, Wall Construction, Floor Surface, Wall Surface(s)\n")
    for kv in self.kivaInstances:
        var grnd = kv.instance.ground.get()
        var constructionName: String
        if kv.constructionNum <= 0:
            constructionName = "<Default Footing Wall Construction>"
        else:
            constructionName = state.dataConstruction.Construct[kv.constructionNum].Name
        var wallSurfaceString: String = ""
        for wl in kv.wallSurfaces:
            wallSurfaceString += "," + state.dataSurface.Surface[wl].Name
        var fmt: String = "{},{},{},{:.2f},{:.2f},{:.2f},{},{}{}\n"
        print(state.files.eio, fmt, self.foundationInputs[state.dataSurface.Surface[kv.floorSurface].OSCPtr].name, grnd.nX, grnd.nZ, grnd.nX * grnd.nZ, grnd.foundation.netPerimeter, kv.floorWeight, grnd.foundation.foundationDepth, constructionName, state.dataSurface.Surface[kv.floorSurface].Name, wallSurfaceString)
    return ErrorsFound

def KivaManager.getDeepGroundDepth(inout self, fnd: Kiva.Foundation) -> Float64:
    var totalDepthOfWallBelowGrade: Float64 = fnd.wall.depthBelowSlab + (fnd.foundationDepth - fnd.wall.heightAboveGrade) + fnd.slab.totalWidth()
    if fnd.deepGroundDepth < totalDepthOfWallBelowGrade + 1.0:
        fnd.deepGroundDepth = totalDepthOfWallBelowGrade + 1.0
    for block in fnd.inputBlocks:
        if block.depth == 0.0:
            block.depth = fnd.foundationDepth
        if self.settings.deepGroundBoundary == Settings.DGType.AUTO:
            if block.z + block.depth + 1.0 > fnd.deepGroundDepth:
                fnd.deepGroundDepth = block.z + block.depth + 1.0
    return fnd.deepGroundDepth

def KivaManager.initKivaInstances(inout self, state: EnergyPlusData) raises:
    for kv in self.kivaInstances:
        kv.initGround(state, self.kivaWeather)
    self.calcKivaSurfaceResults(state)

def KivaManager.calcKivaInstances(inout self, state: EnergyPlusData) raises:
    for kv in self.kivaInstances:
        kv.setBoundaryConditions(state)
        kv.instance.calculate(self.timestep)
        kv.instance.calculate_surface_averages()
    self.calcKivaSurfaceResults(state)

def KivaManager.calcKivaSurfaceResults(inout self, state: EnergyPlusData) raises:
    for surfNum in state.dataSurface.AllHTKivaSurfaceList:
        var contextPair: PythonObject = Python.make_tuple(state, String.format("Surface=\"{}\"", state.dataSurface.Surface[surfNum].Name))
        Kiva.setMessageCallback(kivaErrorCallback, contextPair)
        self.surfaceMap[surfNum].calc_weighted_results()
        state.dataHeatBalSurf.SurfHConvInt[surfNum] = state.dataSurfaceGeometry.kivaManager.surfaceMap[surfNum].results.hconv
    Kiva.setMessageCallback(kivaErrorCallback, None)

def KivaManager.defineDefaultFoundation(inout self, state: EnergyPlusData) raises:
    var defFnd: Kiva.Foundation = Kiva.Foundation()
    defFnd.soil = Kiva.Material(self.settings.soilK, self.settings.soilRho, self.settings.soilCp)
    defFnd.grade.absorptivity = self.settings.groundSolarAbs
    defFnd.grade.emissivity = self.settings.groundThermalAbs
    defFnd.grade.roughness = self.settings.groundRoughness
    defFnd.farFieldWidth = self.settings.farFieldWidth
    var waterTableDepth: Float64 = 0.1022 * state.dataEnvrn.Elevation
    if self.settings.deepGroundBoundary == Settings.DGType.AUTO:
        if waterTableDepth <= 40.0:
            defFnd.deepGroundDepth = waterTableDepth
            defFnd.deepGroundBoundary = Kiva.Foundation.DGB_FIXED_TEMPERATURE
        else:
            defFnd.deepGroundDepth = 40.0
            defFnd.deepGroundBoundary = Kiva.Foundation.DGB_ZERO_FLUX
        if not self.settings.autocalculateDeepGroundDepth:
            if defFnd.deepGroundDepth != self.settings.deepGroundDepth:
                ShowWarningError(state, "Foundation:Kiva:Settings, when Deep-Ground Boundary Condition is Autoselect,")
                ShowContinueError(state, String.format("the user-specified Deep-Ground Depth ({:.1f} m)", self.settings.deepGroundDepth))
                ShowContinueError(state, String.format("will be overridden with the Autoselected depth ({:.1f} m)", defFnd.deepGroundDepth))
    elif self.settings.deepGroundBoundary == Settings.DGType.ZERO_FLUX:
        defFnd.deepGroundDepth = self.settings.deepGroundDepth
        defFnd.deepGroundBoundary = Kiva.Foundation.DGB_ZERO_FLUX
    else:
        defFnd.deepGroundDepth = self.settings.deepGroundDepth
        defFnd.deepGroundBoundary = Kiva.Foundation.DGB_FIXED_TEMPERATURE
    defFnd.wall.heightAboveGrade = 0.2
    var concrete: Kiva.Material = Kiva.Material()
    concrete.conductivity = 1.95
    concrete.density = 2400
    concrete.specificHeat = 900
    var defaultFoundationWall: Kiva.Layer = Kiva.Layer()
    defaultFoundationWall.thickness = 0.3
    defaultFoundationWall.material = concrete
    defFnd.wall.layers.append(defaultFoundationWall)
    defFnd.wall.interior.emissivity = 0.9
    defFnd.wall.interior.absorptivity = 0.9
    defFnd.wall.exterior.emissivity = 0.9
    defFnd.wall.exterior.absorptivity = 0.9
    defFnd.wall.depthBelowSlab = 0.0
    defFnd.mesh.minCellDim = self.settings.minCellDim
    defFnd.mesh.maxNearGrowthCoeff = self.settings.maxGrowthCoeff
    defFnd.mesh.maxDepthGrowthCoeff = self.settings.maxGrowthCoeff
    defFnd.mesh.maxInteriorGrowthCoeff = self.settings.maxGrowthCoeff
    defFnd.mesh.maxExteriorGrowthCoeff = self.settings.maxGrowthCoeff
    self.defaultFoundation.foundation = defFnd
    self.defaultFoundation.name = "<Default Foundation>"
    self.defaultFoundation.assumedIndoorTemperature = -9999

def KivaManager.addDefaultFoundation(inout self) raises:
    self.foundationInputs.append(self.defaultFoundation)
    self.defaultIndex = Int(len(self.foundationInputs) - 1)
    self.defaultAdded = True

def KivaManager.findFoundation(inout self, name: String) -> Int:
    var fndNum: Int = 0
    for fnd in self.foundationInputs:
        if fnd.name == name:
            return fndNum
        fndNum += 1
    return Int(len(self.foundationInputs))