from math import pi, log, exp, sqrt, pow
import sys

# EXTERNAL DEPS (to wire in glue):
# state.dataGlobal: NumOfZones, TimeStepZone, HourOfDay, TimeStep, BeginDayFlag, BeginEnvrnFlag, WarmupFlag, DayOfSim
# state.dataEnvrn: OutDryBulbTemp, OutBaroPress, OutHumRat, WindSpeed, DayOfYear, StdRhoAir
# state.dataHVACGlobal: SysTimeElapsed, TimeStepSysSec
# state.dataHeatBal->Zone: Zone list, indexed 1-based
# state.dataZoneTempPredictorCorrector->zoneHeatBalance: zoneHeatBalance list, MAT/ZT/MCPE/MCPTE/EAMFL/EAMFLxHumRat
# inputProcessor: getNumObjectsFound, getObjectSchemaProps, epJSON, getAlphaFieldValue, getIntFieldValue, getRealFieldValue, 
#   markObjectAsUsed, getEnumValue
# Sched::Schedule.getCurrentVal()
# Psychrometrics: PsyRhoAirFnPbTdbW, PsyCpAirFnW, PsyTdpFnWPb, PsyHFnTdbW, PsyTdbFnHW, PsyWFnTdpPb, PsyTwbFnTdbWPb
# Constant: Pi, rHoursInDay, Units, eResource
# Error/IO: ShowSevereError, ShowContinueError, ShowFatalError, ShowSevereEmptyField, ShowSevereItemNotFound,
#   ShowSevereInvalidKey, SetupOutputVariable
# Util: SameString, FindItemInList
# pow_2(x) = x*x

alias Float64 = Float64

struct Ventilation:
    var Invalid: Int = -1
    var Natural: Int = 0
    var Intake: Int = 1
    var Exhaust: Int = 2
    var Num: Int = 3

struct EarthTubeModelType:
    var Invalid: Int = -1
    var Basic: Int = 0
    var Vertical: Int = 1
    var Num: Int = 2

struct SoilType:
    var Invalid: Int = -1
    var HeavyAndSat: Int = 0
    var HeavyAndDamp: Int = 1
    var HeavyAndDry: Int = 2
    var LightAndDry: Int = 3
    var Num: Int = 4

struct Schedule:
    fn getCurrentVal(self) -> Float64:
        return 0.0

struct Zone:
    var Name: String = ""

struct ZoneHeatBalance:
    var MAT: Float64 = 0.0
    var ZT: Float64 = 0.0
    var MCPE: Float64 = 0.0
    var MCPTE: Float64 = 0.0
    var EAMFL: Float64 = 0.0
    var EAMFLxHumRat: Float64 = 0.0

struct GlobalData:
    var NumOfZones: Int = 0
    var TimeStepZone: Float64 = 0.0
    var HourOfDay: Int = 0
    var TimeStep: Int = 0
    var BeginDayFlag: Bool = False
    var BeginEnvrnFlag: Bool = False
    var WarmupFlag: Bool = False
    var DayOfSim: Int = 0

struct EnvrnData:
    var OutDryBulbTemp: Float64 = 0.0
    var OutBaroPress: Float64 = 0.0
    var OutHumRat: Float64 = 0.0
    var WindSpeed: Float64 = 0.0
    var DayOfYear: Int = 0
    var StdRhoAir: Float64 = 1.225

struct HVACGlobalData:
    var SysTimeElapsed: Float64 = 0.0
    var TimeStepSysSec: Float64 = 0.0

struct HeatBalData:
    var Zone: List[Zone]
    
    fn __init__(inout self):
        self.Zone = List[Zone]()
        self.Zone.append(Zone())

struct ZoneTempPredictorCorrectorData:
    var zoneHeatBalance: List[ZoneHeatBalance]
    
    fn __init__(inout self):
        self.zoneHeatBalance = List[ZoneHeatBalance]()
        self.zoneHeatBalance.append(ZoneHeatBalance())

trait InputProcessor:
    fn getNumObjectsFound(self, state: Unknown, obj_type: String) -> Int: ...
    fn getObjectSchemaProps(self, state: Unknown, obj_type: String) -> Unknown: ...
    fn getAlphaFieldValue(self, fields: Unknown, schema: Unknown, key: String) -> String: ...
    fn getIntFieldValue(self, fields: Unknown, schema: Unknown, key: String) -> Int: ...
    fn getRealFieldValue(self, fields: Unknown, schema: Unknown, key: String) -> Float64: ...
    fn markObjectAsUsed(self, obj_type: String, key: String): ...

trait Psychrometrics:
    @staticmethod
    fn PsyRhoAirFnPbTdbW(state: Unknown, pb: Float64, tdb: Float64, w: Float64) -> Float64: ...
    @staticmethod
    fn PsyCpAirFnW(w: Float64) -> Float64: ...
    @staticmethod
    fn PsyTdpFnWPb(state: Unknown, w: Float64, pb: Float64) -> Float64: ...
    @staticmethod
    fn PsyHFnTdbW(tdb: Float64, w: Float64) -> Float64: ...
    @staticmethod
    fn PsyTdbFnHW(h: Float64, w: Float64) -> Float64: ...
    @staticmethod
    fn PsyWFnTdpPb(state: Unknown, tdp: Float64, pb: Float64) -> Float64: ...
    @staticmethod
    fn PsyTwbFnTdbWPb(state: Unknown, tdb: Float64, w: Float64, pb: Float64) -> Float64: ...

struct EarthTubeData:
    var ZonePtr: Int = 0
    var availSched: Unknown = None
    var DesignLevel: Float64 = 0.0
    var MinTemperature: Float64 = 0.0
    var MaxTemperature: Float64 = 0.0
    var DelTemperature: Float64 = 0.0
    var FanType: Int = -1
    var FanPressure: Float64 = 0.0
    var FanEfficiency: Float64 = 0.0
    var FanPower: Float64 = 0.0
    var GroundTempt: Float64 = 0.0
    var InsideAirTemp: Float64 = 0.0
    var AirTemp: Float64 = 0.0
    var HumRat: Float64 = 0.0
    var WetBulbTemp: Float64 = 0.0
    var r1: Float64 = 0.0
    var r2: Float64 = 0.0
    var r3: Float64 = 0.0
    var PipeLength: Float64 = 0.0
    var PipeThermCond: Float64 = 0.0
    var z: Float64 = 0.0
    var SoilThermDiff: Float64 = 0.0
    var SoilThermCond: Float64 = 0.0
    var AverSoilSurTemp: Float64 = 0.0
    var ApmlSoilSurTemp: Float64 = 0.0
    var SoilSurPhaseConst: Int = 0
    var ConstantTermCoef: Float64 = 0.0
    var TemperatureTermCoef: Float64 = 0.0
    var VelocityTermCoef: Float64 = 0.0
    var VelocitySQTermCoef: Float64 = 0.0
    var ModelType: Int = 0
    var vertParametersPtr: Int = 0
    var totNodes: Int = 0
    var aCoeff: List[Float64]
    var bCoeff: List[Float64]
    var cCoeff: List[Float64]
    var cCoeff0: List[Float64]
    var dCoeff: List[Float64]
    var cPrime: List[Float64]
    var dPrime: List[Float64]
    var cPrime0: List[Float64]
    var tCurrent: List[Float64]
    var tLast: List[Float64]
    var depthNode: List[Float64]
    var dMult0: Float64 = 0.0
    var dMultN: Float64 = 0.0
    var depthUpperBound: Float64 = 0.0
    var depthLowerBound: Float64 = 0.0
    var tUndist: List[Float64]
    var tUpperBound: Float64 = 0.0
    var tLowerBound: Float64 = 0.0
    var airFlowCoeff: Float64 = 0.0

    fn __init__(inout self):
        self.aCoeff = List[Float64]()
        self.bCoeff = List[Float64]()
        self.cCoeff = List[Float64]()
        self.cCoeff0 = List[Float64]()
        self.dCoeff = List[Float64]()
        self.cPrime = List[Float64]()
        self.dPrime = List[Float64]()
        self.cPrime0 = List[Float64]()
        self.tCurrent = List[Float64]()
        self.tLast = List[Float64]()
        self.depthNode = List[Float64]()
        self.tUndist = List[Float64]()

    fn initCPrime0(inout self):
        self.cPrime0[0] = self.cCoeff0[0] / self.bCoeff[0]
        for i in range(1, self.totNodes - 1):
            self.cPrime0[i] = self.cCoeff0[i] / (self.bCoeff[i] - self.aCoeff[i] * self.cPrime0[i - 1])
        self.cPrime0[self.totNodes - 1] = 0.0

    fn calcUndisturbedGroundTemperature(self, state: Unknown, depth: Float64) -> Float64:
        let sqrt_term = sqrt(pi / 365.0 / self.SoilThermDiff)
        let cos_term = (pi * 2.0 / 365.0 * 
                       (Float64(state.dataEnvrn.DayOfYear) - Float64(self.SoilSurPhaseConst) - 
                        depth / 2.0 * sqrt(365.0 / pi / self.SoilThermDiff)))
        return self.AverSoilSurTemp - self.ApmlSoilSurTemp * exp(-depth * sqrt_term)

    fn calcVerticalEarthTube(inout self, state: Unknown, airFlowTerm: Float64):
        let nodeET = state.dataEarthTube.EarthTubePars[self.vertParametersPtr].numNodesAbove
        let nodeLast = self.totNodes - 1

        if airFlowTerm <= 0.0:
            for nodeNum in range(nodeLast + 1):
                self.cPrime[nodeNum] = self.cPrime0[nodeNum]
        else:
            self.cPrime[0] = self.cCoeff[0] / self.bCoeff[0]
            for nodeNum in range(1, nodeLast + 1):
                let addTerm = airFlowTerm if nodeNum == nodeET else 0.0
                self.cPrime[nodeNum] = self.cCoeff[nodeNum] / (self.bCoeff[nodeNum] + addTerm - self.aCoeff[nodeNum] * self.cPrime[nodeNum - 1])

        self.dCoeff[0] = self.tLast[0] + self.dMult0 * self.tUpperBound
        for nodeNum in range(1, nodeLast):
            if nodeNum != nodeET:
                self.dCoeff[nodeNum] = self.tLast[nodeNum]
            else:
                self.dCoeff[nodeNum] = self.tLast[nodeNum] + airFlowTerm * state.dataEnvrn.OutDryBulbTemp
        self.dCoeff[nodeLast] = self.tLast[nodeLast] + self.dMultN * self.tLowerBound

        self.dPrime[0] = self.dCoeff[0] / self.bCoeff[0]
        for nodeNum in range(1, nodeLast + 1):
            let addTerm = airFlowTerm if nodeNum == nodeET else 0.0
            self.dPrime[nodeNum] = (self.dCoeff[nodeNum] - self.aCoeff[nodeNum] * self.dPrime[nodeNum - 1]) /
                                   (self.bCoeff[nodeNum] + addTerm - self.aCoeff[nodeNum] * self.cPrime[nodeNum - 1])

        self.tCurrent[nodeLast] = self.dPrime[nodeLast]
        for nodeNum in range(nodeLast - 1, -1, -1):
            self.tCurrent[nodeNum] = self.dPrime[nodeNum] - self.cPrime[nodeNum] * self.tCurrent[nodeNum + 1]

    fn CalcEarthTubeHumRat(inout self, state: Unknown, NZ: Int):
        let InsideDewPointTemp = Psychrometrics.PsyTdpFnWPb(state, state.dataEnvrn.OutHumRat, state.dataEnvrn.OutBaroPress)
        var InsideHumRat = 0.0
        var thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ]

        if self.InsideAirTemp >= InsideDewPointTemp:
            InsideHumRat = state.dataEnvrn.OutHumRat
            let InsideEnthalpy = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, state.dataEnvrn.OutHumRat)
            if self.FanType == 1:
                var OutletAirEnthalpy = 0.0
                if thisZoneHB.EAMFL == 0.0:
                    OutletAirEnthalpy = InsideEnthalpy
                else:
                    OutletAirEnthalpy = InsideEnthalpy + self.FanPower / thisZoneHB.EAMFL
                self.AirTemp = Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, state.dataEnvrn.OutHumRat)
            else:
                self.AirTemp = self.InsideAirTemp
            thisZoneHB.MCPTE = thisZoneHB.MCPE * self.AirTemp
        else:
            InsideHumRat = Psychrometrics.PsyWFnTdpPb(state, self.InsideAirTemp, state.dataEnvrn.OutBaroPress)
            let InsideEnthalpy = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, InsideHumRat)
            if self.FanType == 1:
                var OutletAirEnthalpy = 0.0
                if thisZoneHB.EAMFL == 0.0:
                    OutletAirEnthalpy = InsideEnthalpy
                else:
                    OutletAirEnthalpy = InsideEnthalpy + self.FanPower / thisZoneHB.EAMFL
                self.AirTemp = Psychrometrics.PsyTdbFnHW(OutletAirEnthalpy, InsideHumRat)
            else:
                self.AirTemp = self.InsideAirTemp
            thisZoneHB.MCPTE = thisZoneHB.MCPE * self.AirTemp

        self.HumRat = InsideHumRat
        self.WetBulbTemp = Psychrometrics.PsyTwbFnTdbWPb(state, self.InsideAirTemp, InsideHumRat, state.dataEnvrn.OutBaroPress)
        thisZoneHB.EAMFLxHumRat = thisZoneHB.EAMFL * InsideHumRat

struct EarthTubeZoneReportVars:
    var EarthTubeHeatLoss: Float64 = 0.0
    var EarthTubeHeatLossRate: Float64 = 0.0
    var EarthTubeHeatGain: Float64 = 0.0
    var EarthTubeHeatGainRate: Float64 = 0.0
    var EarthTubeOATreatmentPower: Float64 = 0.0
    var EarthTubeVolume: Float64 = 0.0
    var EarthTubeVolFlowRate: Float64 = 0.0
    var EarthTubeVolFlowRateStd: Float64 = 0.0
    var EarthTubeMass: Float64 = 0.0
    var EarthTubeMassFlowRate: Float64 = 0.0
    var EarthTubeWaterMassFlowRate: Float64 = 0.0
    var EarthTubeFanElec: Float64 = 0.0
    var EarthTubeFanElecPower: Float64 = 0.0
    var EarthTubeAirTemp: Float64 = 0.0
    var EarthTubeWetBulbTemp: Float64 = 0.0
    var EarthTubeHumRat: Float64 = 0.0

struct EarthTubeParameters:
    var nameParameters: String = ""
    var numNodesAbove: Int = 0
    var numNodesBelow: Int = 0
    var dimBoundAbove: Float64 = 0.0
    var dimBoundBelow: Float64 = 0.0
    var width: Float64 = 0.0

struct EarthTubeDataGlobal:
    var GetInputFlag: Bool = True
    var initFirstTime: Bool = True
    var timeElapsed: Float64 = 0.0
    var EarthTubeSys: List[EarthTubeData]
    var ZnRptET: List[EarthTubeZoneReportVars]
    var EarthTubePars: List[EarthTubeParameters]

    fn __init__(inout self):
        self.EarthTubeSys = List[EarthTubeData]()
        self.EarthTubeSys.append(EarthTubeData())
        self.ZnRptET = List[EarthTubeZoneReportVars]()
        self.ZnRptET.append(EarthTubeZoneReportVars())
        self.EarthTubePars = List[EarthTubeParameters]()
        self.EarthTubePars.append(EarthTubeParameters())

var totEarthTube = 0

fn pow_2(x: Float64) -> Float64:
    return x * x

fn SameString(s1: String, s2: String) -> Bool:
    return s1.upper() == s2.upper()

fn FindItemInList(name: String, items: List[Zone]) -> Int:
    for i in range(1, len(items)):
        if SameString(items[i].Name, name):
            return i
    return 0

fn GetSchedule(state: Unknown, name: String) -> Schedule:
    return Schedule()

fn ShowSevereError(state: Unknown, msg: String):
    pass

fn ShowContinueError(state: Unknown, msg: String):
    pass

fn ShowFatalError(state: Unknown, msg: String):
    pass

fn ShowSevereEmptyField(state: Unknown, eoh: Unknown, field: String):
    pass

fn ShowSevereItemNotFound(state: Unknown, eoh: Unknown, field: String, value: String):
    pass

fn ShowSevereInvalidKey(state: Unknown, eoh: Unknown, field: String, value: String):
    pass

fn SetupOutputVariable(state: Unknown, name: String, *args: Unknown):
    pass

fn getEnumValue(names: List[String], searchValue: String) -> Int:
    let uc_search = searchValue.upper()
    for i in range(len(names)):
        if names[i] == uc_search:
            return i
    return -1

fn ManageEarthTube(state: Unknown):
    if state.dataEarthTube.GetInputFlag:
        var ErrorsFound = False
        GetEarthTube(state, ErrorsFound)
        state.dataEarthTube.GetInputFlag = False

    if len(state.dataEarthTube.EarthTubeSys) <= 1:
        return

    initEarthTubeVertical(state)
    CalcEarthTube(state)
    ReportEarthTube(state)

fn GetEarthTube(state: Unknown, inout ErrorsFound: Bool):
    pass

fn CheckEarthTubesInZones(state: Unknown, ZoneName: String, FieldName: String, inout ErrorsFound: Bool):
    let numEarthTubes = len(state.dataEarthTube.EarthTubeSys) - 1
    for Loop in range(1, numEarthTubes):
        for Loop1 in range(Loop + 1, numEarthTubes + 1):
            if state.dataEarthTube.EarthTubeSys[Loop].ZonePtr == state.dataEarthTube.EarthTubeSys[Loop1].ZonePtr:
                ShowSevereError(state, f"{ZoneName} has more than one {FieldName} associated with it.")
                ShowContinueError(state, f"Only one {FieldName} is allowed per zone.")
                ErrorsFound = True

fn initEarthTubeVertical(state: Unknown):
    pass

fn CalcEarthTube(state: Unknown):
    pass

fn ReportEarthTube(state: Unknown):
    pass
