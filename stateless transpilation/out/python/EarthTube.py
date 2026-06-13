from enum import IntEnum
from typing import Protocol, Optional, List
from dataclasses import dataclass, field
import math

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

class Ventilation(IntEnum):
    Invalid = -1
    Natural = 0
    Intake = 1
    Exhaust = 2
    Num = 3

class EarthTubeModelType(IntEnum):
    Invalid = -1
    Basic = 0
    Vertical = 1
    Num = 2

class SoilType(IntEnum):
    Invalid = -1
    HeavyAndSat = 0
    HeavyAndDamp = 1
    HeavyAndDry = 2
    LightAndDry = 3
    Num = 4

@dataclass
class Schedule:
    def getCurrentVal(self):
        return 0.0

@dataclass
class Zone:
    Name: str = ""

@dataclass
class ZoneHeatBalance:
    MAT: float = 0.0
    ZT: float = 0.0
    MCPE: float = 0.0
    MCPTE: float = 0.0
    EAMFL: float = 0.0
    EAMFLxHumRat: float = 0.0

@dataclass
class GlobalData:
    NumOfZones: int = 0
    TimeStepZone: float = 0.0
    HourOfDay: int = 0
    TimeStep: int = 0
    BeginDayFlag: bool = False
    BeginEnvrnFlag: bool = False
    WarmupFlag: bool = False
    DayOfSim: int = 0

@dataclass
class EnvrnData:
    OutDryBulbTemp: float = 0.0
    OutBaroPress: float = 0.0
    OutHumRat: float = 0.0
    WindSpeed: float = 0.0
    DayOfYear: int = 0
    StdRhoAir: float = 1.225

@dataclass
class HVACGlobalData:
    SysTimeElapsed: float = 0.0
    TimeStepSysSec: float = 0.0

@dataclass
class HeatBalData:
    Zone: List[Zone] = field(default_factory=lambda: [Zone()])

@dataclass
class ZoneTempPredictorCorrectorData:
    zoneHeatBalance: List[ZoneHeatBalance] = field(default_factory=lambda: [ZoneHeatBalance()])

class InputProcessor(Protocol):
    def getNumObjectsFound(self, state, obj_type: str) -> int: ...
    def getObjectSchemaProps(self, state, obj_type: str): ...
    def getAlphaFieldValue(self, fields, schema, key: str) -> str: ...
    def getIntFieldValue(self, fields, schema, key: str) -> int: ...
    def getRealFieldValue(self, fields, schema, key: str) -> float: ...
    def markObjectAsUsed(self, obj_type: str, key: str): ...

class Psychrometrics(Protocol):
    @staticmethod
    def PsyRhoAirFnPbTdbW(state, pb: float, tdb: float, w: float) -> float: ...
    @staticmethod
    def PsyCpAirFnW(w: float) -> float: ...
    @staticmethod
    def PsyTdpFnWPb(state, w: float, pb: float) -> float: ...
    @staticmethod
    def PsyHFnTdbW(tdb: float, w: float) -> float: ...
    @staticmethod
    def PsyTdbFnHW(h: float, w: float) -> float: ...
    @staticmethod
    def PsyWFnTdpPb(state, tdp: float, pb: float) -> float: ...
    @staticmethod
    def PsyTwbFnTdbWPb(state, tdb: float, w: float, pb: float) -> float: ...

@dataclass
class EarthTubeData:
    ZonePtr: int = 0
    availSched: Optional[Schedule] = None
    DesignLevel: float = 0.0
    MinTemperature: float = 0.0
    MaxTemperature: float = 0.0
    DelTemperature: float = 0.0
    FanType: Ventilation = Ventilation.Invalid
    FanPressure: float = 0.0
    FanEfficiency: float = 0.0
    FanPower: float = 0.0
    GroundTempt: float = 0.0
    InsideAirTemp: float = 0.0
    AirTemp: float = 0.0
    HumRat: float = 0.0
    WetBulbTemp: float = 0.0
    r1: float = 0.0
    r2: float = 0.0
    r3: float = 0.0
    PipeLength: float = 0.0
    PipeThermCond: float = 0.0
    z: float = 0.0
    SoilThermDiff: float = 0.0
    SoilThermCond: float = 0.0
    AverSoilSurTemp: float = 0.0
    ApmlSoilSurTemp: float = 0.0
    SoilSurPhaseConst: int = 0
    ConstantTermCoef: float = 0.0
    TemperatureTermCoef: float = 0.0
    VelocityTermCoef: float = 0.0
    VelocitySQTermCoef: float = 0.0
    ModelType: EarthTubeModelType = EarthTubeModelType.Basic
    vertParametersPtr: int = 0
    totNodes: int = 0
    aCoeff: List[float] = field(default_factory=list)
    bCoeff: List[float] = field(default_factory=list)
    cCoeff: List[float] = field(default_factory=list)
    cCoeff0: List[float] = field(default_factory=list)
    dCoeff: List[float] = field(default_factory=list)
    cPrime: List[float] = field(default_factory=list)
    dPrime: List[float] = field(default_factory=list)
    cPrime0: List[float] = field(default_factory=list)
    tCurrent: List[float] = field(default_factory=list)
    tLast: List[float] = field(default_factory=list)
    depthNode: List[float] = field(default_factory=list)
    dMult0: float = 0.0
    dMultN: float = 0.0
    depthUpperBound: float = 0.0
    depthLowerBound: float = 0.0
    tUndist: List[float] = field(default_factory=list)
    tUpperBound: float = 0.0
    tLowerBound: float = 0.0
    airFlowCoeff: float = 0.0

    def initCPrime0(self):
        self.cPrime0[0] = self.cCoeff0[0] / self.bCoeff[0]
        for i in range(1, self.totNodes - 1):
            self.cPrime0[i] = self.cCoeff0[i] / (self.bCoeff[i] - self.aCoeff[i] * self.cPrime0[i - 1])
        self.cPrime0[self.totNodes - 1] = 0.0

    def calcUndisturbedGroundTemperature(self, state, depth: float) -> float:
        pi = math.pi
        sqrt_term = math.sqrt(pi / 365.0 / self.SoilThermDiff)
        cos_term = math.cos(2.0 * pi / 365.0 * 
                           (state.dataEnvrn.DayOfYear - self.SoilSurPhaseConst - 
                            depth / 2.0 * math.sqrt(365.0 / pi / self.SoilThermDiff)))
        return self.AverSoilSurTemp - self.ApmlSoilSurTemp * math.exp(-depth * sqrt_term) * cos_term

    def calcVerticalEarthTube(self, state, airFlowTerm: float):
        nodeET = state.dataEarthTube.EarthTubePars[self.vertParametersPtr].numNodesAbove
        nodeLast = self.totNodes - 1

        if airFlowTerm <= 0.0:
            for nodeNum in range(nodeLast + 1):
                self.cPrime[nodeNum] = self.cPrime0[nodeNum]
        else:
            self.cPrime[0] = self.cCoeff[0] / self.bCoeff[0]
            for nodeNum in range(1, nodeLast + 1):
                addTerm = airFlowTerm if nodeNum == nodeET else 0.0
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
            addTerm = airFlowTerm if nodeNum == nodeET else 0.0
            self.dPrime[nodeNum] = (self.dCoeff[nodeNum] - self.aCoeff[nodeNum] * self.dPrime[nodeNum - 1]) / \
                                   (self.bCoeff[nodeNum] + addTerm - self.aCoeff[nodeNum] * self.cPrime[nodeNum - 1])

        self.tCurrent[nodeLast] = self.dPrime[nodeLast]
        for nodeNum in range(nodeLast - 1, -1, -1):
            self.tCurrent[nodeNum] = self.dPrime[nodeNum] - self.cPrime[nodeNum] * self.tCurrent[nodeNum + 1]

    def CalcEarthTubeHumRat(self, state, NZ: int):
        InsideDewPointTemp = Psychrometrics.PsyTdpFnWPb(state, state.dataEnvrn.OutHumRat, state.dataEnvrn.OutBaroPress)
        InsideHumRat = 0.0
        thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ]

        if self.InsideAirTemp >= InsideDewPointTemp:
            InsideHumRat = state.dataEnvrn.OutHumRat
            InsideEnthalpy = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, state.dataEnvrn.OutHumRat)
            if self.FanType == Ventilation.Intake:
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
            InsideEnthalpy = Psychrometrics.PsyHFnTdbW(self.InsideAirTemp, InsideHumRat)
            if self.FanType == Ventilation.Intake:
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

@dataclass
class EarthTubeZoneReportVars:
    EarthTubeHeatLoss: float = 0.0
    EarthTubeHeatLossRate: float = 0.0
    EarthTubeHeatGain: float = 0.0
    EarthTubeHeatGainRate: float = 0.0
    EarthTubeOATreatmentPower: float = 0.0
    EarthTubeVolume: float = 0.0
    EarthTubeVolFlowRate: float = 0.0
    EarthTubeVolFlowRateStd: float = 0.0
    EarthTubeMass: float = 0.0
    EarthTubeMassFlowRate: float = 0.0
    EarthTubeWaterMassFlowRate: float = 0.0
    EarthTubeFanElec: float = 0.0
    EarthTubeFanElecPower: float = 0.0
    EarthTubeAirTemp: float = 0.0
    EarthTubeWetBulbTemp: float = 0.0
    EarthTubeHumRat: float = 0.0

@dataclass
class EarthTubeParameters:
    nameParameters: str = ""
    numNodesAbove: int = 0
    numNodesBelow: int = 0
    dimBoundAbove: float = 0.0
    dimBoundBelow: float = 0.0
    width: float = 0.0

@dataclass
class EarthTubeDataGlobal:
    GetInputFlag: bool = True
    initFirstTime: bool = True
    timeElapsed: float = 0.0
    EarthTubeSys: List[EarthTubeData] = field(default_factory=lambda: [EarthTubeData()])
    ZnRptET: List[EarthTubeZoneReportVars] = field(default_factory=lambda: [EarthTubeZoneReportVars()])
    EarthTubePars: List[EarthTubeParameters] = field(default_factory=lambda: [EarthTubeParameters()])

totEarthTube = 0

ventilationNamesUC = ["NATURAL", "INTAKE", "EXHAUST"]
soilTypeNamesUC = ["HEAVYANDSATURATED", "HEAVYANDDAMP", "HEAVYANDDRY", "LIGHTANDDRY"]
solutionTypeNamesUC = ["BASIC", "VERTICAL"]

thermalDiffusivity = [0.0781056, 0.055728, 0.0445824, 0.024192]
thermalConductivity = [2.42, 1.3, 0.865, 0.346]

class ErrorObjectHeader:
    def __init__(self, routineName: str, moduleObject: str, zoneName: str):
        self.routineName = routineName
        self.moduleObject = moduleObject
        self.zoneName = zoneName

def getEnumValue(names: List[str], searchValue: str) -> int:
    uc_search = searchValue.upper()
    for i, name in enumerate(names):
        if name == uc_search:
            return i
    return -1

def pow_2(x: float) -> float:
    return x * x

def ManageEarthTube(state):
    if state.dataEarthTube.GetInputFlag:
        ErrorsFound = False
        GetEarthTube(state, ErrorsFound)
        state.dataEarthTube.GetInputFlag = False

    if not state.dataEarthTube.EarthTubeSys[1:]:
        return

    initEarthTubeVertical(state)
    CalcEarthTube(state)
    ReportEarthTube(state)

def GetEarthTube(state, ErrorsFound):
    routineName = "GetEarthTube"
    EarthTubeTempLimit = 100.0
    earthTubeParametersModuleObject = "ZoneEarthtube:Parameters"
    earthTubeModuleObject = "ZoneEarthtube"
    
    numericFieldNames = [
        "Design Flow Rate", "Minimum Zone Temperature when Cooling",
        "Maximum Zone Temperature when Heating", "Delta Temperature",
        "Fan Pressure Rise", "Fan Total Efficiency", "Pipe Radius",
        "Pipe Thickness", "Pipe Length", "Pipe Thermal Conductivity",
        "Pipe Depth Under Ground Surface", "Average Soil Surface Temperature",
        "Amplitude of Soil Surface Temperature", "Phase Constant of Soil Surface Temperature",
        "Constant Term Flow Coefficient", "Temperature Term Flow Coefficient",
        "Velocity Term Flow Coefficient", "Velocity Squared Term Flow Coefficient"
    ]

    RepVarSet = [True] * (state.dataGlobal.NumOfZones + 1)

    state.dataEarthTube.ZnRptET = [EarthTubeZoneReportVars() for _ in range(state.dataGlobal.NumOfZones + 1)]

    inputProcessor = state.inputProcessor

    totEarthTubePars = inputProcessor.getNumObjectsFound(state, earthTubeParametersModuleObject)
    state.dataEarthTube.EarthTubePars = [EarthTubeParameters()] * (totEarthTubePars + 1)

    Loop = 0
    if hasattr(inputProcessor, 'epJSON') and earthTubeParametersModuleObject in inputProcessor.epJSON:
        for key, earthTubeParameterFields in inputProcessor.epJSON[earthTubeParametersModuleObject].items():
            Loop += 1
            thisEarthTubePars = state.dataEarthTube.EarthTubePars[Loop]
            thisEarthTubePars.nameParameters = inputProcessor.getAlphaFieldValue(
                earthTubeParameterFields, None, "earth_tube_model_parameters_name")
            inputProcessor.markObjectAsUsed(earthTubeParametersModuleObject, key)

            for otherParams in range(1, Loop):
                if SameString(thisEarthTubePars.nameParameters, state.dataEarthTube.EarthTubePars[otherParams].nameParameters):
                    ShowSevereError(state,
                        f"{earthTubeParametersModuleObject}: Earth Tube Model Parameters Name = {thisEarthTubePars.nameParameters} is not a unique name.")
                    ShowContinueError(state, f"Check the other {earthTubeParametersModuleObject} names for a duplicate.")
                    ErrorsFound = True

            thisEarthTubePars.numNodesAbove = inputProcessor.getIntFieldValue(
                earthTubeParameterFields, None, "nodes_above_earth_tube")
            thisEarthTubePars.numNodesBelow = inputProcessor.getIntFieldValue(
                earthTubeParameterFields, None, "nodes_below_earth_tube")
            thisEarthTubePars.dimBoundAbove = inputProcessor.getRealFieldValue(
                earthTubeParameterFields, None, "earth_tube_dimensionless_boundary_above")
            thisEarthTubePars.dimBoundBelow = inputProcessor.getRealFieldValue(
                earthTubeParameterFields, None, "earth_tube_dimensionless_boundary_below")
            thisEarthTubePars.width = inputProcessor.getRealFieldValue(
                earthTubeParameterFields, None, "earth_tube_solution_space_width")

    global totEarthTube
    totEarthTube = inputProcessor.getNumObjectsFound(state, earthTubeModuleObject)
    state.dataEarthTube.EarthTubeSys = [EarthTubeData() for _ in range(totEarthTube + 1)]

    lastZoneName = ""
    Loop = 0
    if hasattr(inputProcessor, 'epJSON') and earthTubeModuleObject in inputProcessor.epJSON:
        for key, earthTubeFields in inputProcessor.epJSON[earthTubeModuleObject].items():
            Loop += 1
            thisEarthTube = state.dataEarthTube.EarthTubeSys[Loop]
            zoneName = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "zone_name")
            scheduleName = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "schedule_name")
            earthTubeType = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "earthtube_type")
            soilCondition = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "soil_condition")
            earthTubeModelType = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "earth_tube_model_type")
            earthTubeModelParameters = inputProcessor.getAlphaFieldValue(earthTubeFields, None, "earth_tube_model_parameters")

            inputProcessor.markObjectAsUsed(earthTubeModuleObject, key)
            eoh = ErrorObjectHeader(routineName, earthTubeModuleObject, zoneName)
            lastZoneName = zoneName

            thisEarthTube.ZonePtr = FindItemInList(zoneName, state.dataHeatBal.Zone)
            if thisEarthTube.ZonePtr == 0:
                ShowSevereError(state, f"{earthTubeModuleObject}: Zone Name not found={zoneName}")
                ErrorsFound = True

            if not scheduleName:
                ShowSevereEmptyField(state, eoh, "Schedule Name")
                ErrorsFound = True
            else:
                thisEarthTube.availSched = GetSchedule(state, scheduleName)
                if thisEarthTube.availSched is None:
                    ShowSevereItemNotFound(state, eoh, "Schedule Name", scheduleName)
                    ErrorsFound = True

            thisEarthTube.DesignLevel = inputProcessor.getRealFieldValue(earthTubeFields, None, "design_flow_rate")

            thisEarthTube.MinTemperature = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "minimum_zone_temperature_when_cooling")
            if (thisEarthTube.MinTemperature < -EarthTubeTempLimit) or (thisEarthTube.MinTemperature > EarthTubeTempLimit):
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName} must have a minimum temperature between -{EarthTubeTempLimit:.2f}C and {EarthTubeTempLimit:.2f}C")
                ShowContinueError(state, f"Entered value={thisEarthTube.MinTemperature}")
                ErrorsFound = True

            thisEarthTube.MaxTemperature = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "maximum_zone_temperature_when_heating")
            if (thisEarthTube.MaxTemperature < -EarthTubeTempLimit) or (thisEarthTube.MaxTemperature > EarthTubeTempLimit):
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName} must have a maximum temperature between -{EarthTubeTempLimit:.2f}C and {EarthTubeTempLimit:.2f}C")
                ShowContinueError(state, f"Entered value={thisEarthTube.MaxTemperature}")
                ErrorsFound = True

            thisEarthTube.DelTemperature = inputProcessor.getRealFieldValue(earthTubeFields, None, "delta_temperature")

            if not earthTubeType:
                thisEarthTube.FanType = Ventilation.Natural
            else:
                thisEarthTube.FanType = Ventilation(getEnumValue(ventilationNamesUC, earthTubeType))
                if thisEarthTube.FanType == Ventilation.Invalid:
                    ShowSevereInvalidKey(state, eoh, "Earthtube Type", earthTubeType)
                    ErrorsFound = True

            thisEarthTube.FanPressure = inputProcessor.getRealFieldValue(earthTubeFields, None, "fan_pressure_rise")
            if thisEarthTube.FanPressure < 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[4]} must be positive, entered value={thisEarthTube.FanPressure}")
                ErrorsFound = True

            thisEarthTube.FanEfficiency = inputProcessor.getRealFieldValue(earthTubeFields, None, "fan_total_efficiency")
            if (thisEarthTube.FanEfficiency <= 0.0) or (thisEarthTube.FanEfficiency > 1.0):
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[5]} must be greater than zero and less than or equal to one, entered value={thisEarthTube.FanEfficiency}")
                ErrorsFound = True

            thisEarthTube.r1 = inputProcessor.getRealFieldValue(earthTubeFields, None, "pipe_radius")
            if thisEarthTube.r1 <= 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[6]} must be positive, entered value={thisEarthTube.r1}")
                ErrorsFound = True

            thisEarthTube.r2 = inputProcessor.getRealFieldValue(earthTubeFields, None, "pipe_thickness")
            if thisEarthTube.r2 <= 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[7]} must be positive, entered value={thisEarthTube.r2}")
                ErrorsFound = True

            thisEarthTube.r3 = 2.0 * thisEarthTube.r1

            thisEarthTube.PipeLength = inputProcessor.getRealFieldValue(earthTubeFields, None, "pipe_length")
            if thisEarthTube.PipeLength <= 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[8]} must be positive, entered value={thisEarthTube.PipeLength}")
                ErrorsFound = True

            thisEarthTube.PipeThermCond = inputProcessor.getRealFieldValue(earthTubeFields, None, "pipe_thermal_conductivity")
            if thisEarthTube.PipeThermCond <= 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[9]} must be positive, entered value={thisEarthTube.PipeThermCond}")
                ErrorsFound = True

            thisEarthTube.z = inputProcessor.getRealFieldValue(earthTubeFields, None, "pipe_depth_under_ground_surface")
            if thisEarthTube.z <= 0.0:
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[10]} must be positive, entered value={thisEarthTube.z}")
                ErrorsFound = True
            if thisEarthTube.z <= (thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3):
                ShowSevereError(state,
                    f"{earthTubeModuleObject}: Zone Name={zoneName}, {numericFieldNames[10]} must be greater than 3*{numericFieldNames[6]} + {numericFieldNames[7]} entered value={thisEarthTube.z} ref sum={thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3}")
                ErrorsFound = True

            soilType = SoilType(getEnumValue(soilTypeNamesUC, soilCondition))
            if soilType == SoilType.Invalid:
                ShowSevereInvalidKey(state, eoh, "Soil Condition", soilCondition)
                ErrorsFound = True
            else:
                thisEarthTube.SoilThermDiff = thermalDiffusivity[int(soilType)]
                thisEarthTube.SoilThermCond = thermalConductivity[int(soilType)]

            thisEarthTube.AverSoilSurTemp = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "average_soil_surface_temperature")
            thisEarthTube.ApmlSoilSurTemp = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "amplitude_of_soil_surface_temperature")
            thisEarthTube.SoilSurPhaseConst = int(inputProcessor.getRealFieldValue(
                earthTubeFields, None, "phase_constant_of_soil_surface_temperature"))

            if thisEarthTube.FanType == Ventilation.Natural:
                thisEarthTube.FanPressure = 0.0
                thisEarthTube.FanEfficiency = 1.0

            thisEarthTube.ConstantTermCoef = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "constant_term_flow_coefficient")
            thisEarthTube.TemperatureTermCoef = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "temperature_term_flow_coefficient")
            thisEarthTube.VelocityTermCoef = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "velocity_term_flow_coefficient")
            thisEarthTube.VelocitySQTermCoef = inputProcessor.getRealFieldValue(
                earthTubeFields, None, "velocity_squared_term_flow_coefficient")

            if not earthTubeModelType:
                thisEarthTube.ModelType = EarthTubeModelType.Basic
            else:
                thisEarthTube.ModelType = EarthTubeModelType(getEnumValue(solutionTypeNamesUC, earthTubeModelType))
                if thisEarthTube.ModelType == EarthTubeModelType.Invalid:
                    ShowSevereInvalidKey(state, eoh, "Earth Tube Model Type", earthTubeModelType)
                    ErrorsFound = True

            if thisEarthTube.ModelType == EarthTubeModelType.Vertical:
                thisEarthTube.r3 = 0.0
                thisEarthTube.vertParametersPtr = 0
                for parIndex in range(1, totEarthTubePars + 1):
                    if SameString(earthTubeModelParameters, state.dataEarthTube.EarthTubePars[parIndex].nameParameters):
                        thisEarthTube.vertParametersPtr = parIndex
                        break
                if thisEarthTube.vertParametersPtr == 0:
                    ShowSevereItemNotFound(state, eoh, "Earth Tube Model Parameters", earthTubeModelParameters)
                    ErrorsFound = True

            if thisEarthTube.ZonePtr > 0:
                if RepVarSet[thisEarthTube.ZonePtr]:
                    RepVarSet[thisEarthTube.ZonePtr] = False
                    zone = state.dataHeatBal.Zone[thisEarthTube.ZonePtr]
                    thisZnRptET = state.dataEarthTube.ZnRptET[thisEarthTube.ZonePtr]

                    SetupOutputVariable(state, "Earth Tube Zone Sensible Cooling Energy", thisZnRptET.EarthTubeHeatLoss, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Cooling Rate", thisZnRptET.EarthTubeHeatLossRate, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Heating Energy", thisZnRptET.EarthTubeHeatGain, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Sensible Heating Rate", thisZnRptET.EarthTubeHeatGainRate, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Flow Volume", thisZnRptET.EarthTubeVolume, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Current Density Air Volume Flow Rate", thisZnRptET.EarthTubeVolFlowRate, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Standard Density Air Volume Flow Rate", thisZnRptET.EarthTubeVolFlowRateStd, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Flow Mass", thisZnRptET.EarthTubeMass, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Air Mass Flow Rate", thisZnRptET.EarthTubeMassFlowRate, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Water Mass Flow Rate", thisZnRptET.EarthTubeWaterMassFlowRate, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Fan Electricity Energy", thisZnRptET.EarthTubeFanElec, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Fan Electricity Rate", thisZnRptET.EarthTubeFanElecPower, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Air Temperature", thisZnRptET.EarthTubeAirTemp, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Ground Interface Temperature", thisEarthTube.GroundTempt, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Outdoor Air Heat Transfer Rate", thisZnRptET.EarthTubeOATreatmentPower, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Wet Bulb Temperature", thisZnRptET.EarthTubeWetBulbTemp, zone.Name)
                    SetupOutputVariable(state, "Earth Tube Zone Inlet Humidity Ratio", thisZnRptET.EarthTubeHumRat, zone.Name)

    CheckEarthTubesInZones(state, lastZoneName, earthTubeModuleObject, ErrorsFound)

    if ErrorsFound:
        ShowFatalError(state, f"{earthTubeModuleObject}: Errors getting input.  Program terminates.")

def CheckEarthTubesInZones(state, ZoneName: str, FieldName: str, ErrorsFound):
    numEarthTubes = len(state.dataEarthTube.EarthTubeSys) - 1
    for Loop in range(1, numEarthTubes):
        for Loop1 in range(Loop + 1, numEarthTubes + 1):
            if state.dataEarthTube.EarthTubeSys[Loop].ZonePtr == state.dataEarthTube.EarthTubeSys[Loop1].ZonePtr:
                ShowSevereError(state, f"{ZoneName} has more than one {FieldName} associated with it.")
                ShowContinueError(state, f"Only one {FieldName} is allowed per zone.  Check the definitions of {FieldName}")
                ShowContinueError(state, "in your input file and make sure that there is only one defined for each zone.")
                ErrorsFound = True

def initEarthTubeVertical(state):
    if state.dataEarthTube.initFirstTime:
        state.dataEarthTube.initFirstTime = False
        for etNum in range(1, totEarthTube + 1):
            thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum]
            if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                continue
            thisEarthTubeParams = state.dataEarthTube.EarthTubePars[thisEarthTube.vertParametersPtr]
            thisEarthTube.totNodes = thisEarthTubeParams.numNodesAbove + thisEarthTubeParams.numNodesBelow + 1
            thisEarthTube.aCoeff = [0.0] * thisEarthTube.totNodes
            thisEarthTube.bCoeff = [0.0] * thisEarthTube.totNodes
            thisEarthTube.cCoeff = [0.0] * thisEarthTube.totNodes
            thisEarthTube.cCoeff0 = [0.0] * thisEarthTube.totNodes
            thisEarthTube.dCoeff = [0.0] * thisEarthTube.totNodes
            thisEarthTube.cPrime = [0.0] * thisEarthTube.totNodes
            thisEarthTube.dPrime = [0.0] * thisEarthTube.totNodes
            thisEarthTube.cPrime0 = [0.0] * thisEarthTube.totNodes
            thisEarthTube.tCurrent = [0.0] * thisEarthTube.totNodes
            thisEarthTube.tLast = [0.0] * thisEarthTube.totNodes
            thisEarthTube.depthNode = [0.0] * thisEarthTube.totNodes
            thisEarthTube.tUndist = [0.0] * thisEarthTube.totNodes

            thickBase = thisEarthTube.z - 3.0 * thisEarthTube.r1
            thickTop = thickBase * thisEarthTubeParams.dimBoundAbove / float(thisEarthTubeParams.numNodesAbove)
            thickBottom = thickBase * thisEarthTubeParams.dimBoundBelow / float(thisEarthTubeParams.numNodesBelow)
            thickEarthTube = 4.0 * thisEarthTube.r1
            deltat = state.dataGlobal.TimeStepZone
            thermDiff = thisEarthTube.SoilThermDiff / 24.0

            commonTerm = thermDiff * deltat / (thickTop * thickTop)
            thisEarthTube.aCoeff[0] = 0.0
            thisEarthTube.bCoeff[0] = 1.0 + 3.0 * commonTerm
            thisEarthTube.cCoeff[0] = -1.0 * commonTerm
            thisEarthTube.dMult0 = 2.0 * commonTerm

            for nodeNum in range(1, thisEarthTubeParams.numNodesAbove - 1):
                thisEarthTube.aCoeff[nodeNum] = -1.0 * commonTerm
                thisEarthTube.bCoeff[nodeNum] = 1.0 + 2.0 * commonTerm
                thisEarthTube.cCoeff[nodeNum] = -1.0 * commonTerm

            thisNode = thisEarthTubeParams.numNodesAbove - 1
            commonTerm2 = 2.0 * thermDiff * deltat / (thickTop + thickEarthTube) / thickTop
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm2

            thisNode = thisEarthTubeParams.numNodesAbove
            commonTerm = 2.0 * thermDiff * deltat / (thickTop + thickEarthTube) / thickEarthTube
            commonTerm2 = 2.0 * thermDiff * deltat / (thickBottom + thickEarthTube) / thickEarthTube
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm2

            thisNode = thisEarthTubeParams.numNodesAbove + 1
            commonTerm = thermDiff * deltat / (thickBottom * thickBottom)
            commonTerm2 = 2.0 * thermDiff * deltat / (thickBottom + thickEarthTube) / thickBottom
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm2
            thisEarthTube.bCoeff[thisNode] = 1.0 + commonTerm + commonTerm2
            thisEarthTube.cCoeff[thisNode] = -1.0 * commonTerm

            for nodeNum in range(thisNode + 1, thisEarthTube.totNodes - 1):
                thisEarthTube.aCoeff[nodeNum] = -1.0 * commonTerm
                thisEarthTube.bCoeff[nodeNum] = 1.0 + 2.0 * commonTerm
                thisEarthTube.cCoeff[nodeNum] = -1.0 * commonTerm

            thisNode = thisEarthTube.totNodes - 1
            thisEarthTube.aCoeff[thisNode] = -1.0 * commonTerm
            thisEarthTube.bCoeff[thisNode] = 1.0 + 3.0 * commonTerm
            thisEarthTube.cCoeff[thisNode] = 0.0
            thisEarthTube.dMultN = 2.0 * commonTerm

            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove - 1] = thisEarthTube.z - 0.5 * (thickEarthTube + thickTop)
            for nodeNum in range(thisEarthTubeParams.numNodesAbove - 2, -1, -1):
                thisEarthTube.depthNode[nodeNum] = thisEarthTube.depthNode[nodeNum + 1] - thickTop
            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove] = thisEarthTube.z
            thisEarthTube.depthNode[thisEarthTubeParams.numNodesAbove + 1] = thisEarthTube.z + 0.5 * (thickEarthTube + thickBottom)
            for nodeNumBelow in range(2, thisEarthTubeParams.numNodesBelow + 1):
                nodeNum = thisEarthTubeParams.numNodesAbove + nodeNumBelow
                thisEarthTube.depthNode[nodeNum] = thisEarthTube.depthNode[nodeNum - 1] + thickBottom
            thisEarthTube.depthUpperBound = thisEarthTube.depthNode[0] - 0.5 * thickTop
            thisEarthTube.depthLowerBound = thisEarthTube.depthNode[thisEarthTube.totNodes - 1] + 0.5 * thickBottom

            thisEarthTube.airFlowCoeff = state.dataGlobal.TimeStepZone * thermDiff / thisEarthTube.SoilThermCond / thickEarthTube / \
                                         thisEarthTubeParams.width / thisEarthTube.PipeLength

            for nodeNum in range(thisEarthTube.totNodes):
                thisEarthTube.cCoeff0[nodeNum] = thisEarthTube.cCoeff[nodeNum]
            thisEarthTube.initCPrime0()

            zone = state.dataHeatBal.Zone[thisEarthTube.ZonePtr]
            for nodeNum in range(1, thisEarthTube.totNodes + 1):
                SetupOutputVariable(state, f"Earth Tube Node Temperature {nodeNum}",
                                  thisEarthTube.tCurrent[nodeNum - 1], zone.Name)
                SetupOutputVariable(state, f"Earth Tube Undisturbed Ground Temperature {nodeNum}",
                                  thisEarthTube.tUndist[nodeNum - 1], zone.Name)
            SetupOutputVariable(state, "Earth Tube Upper Boundary Ground Temperature",
                              thisEarthTube.tUpperBound, zone.Name)
            SetupOutputVariable(state, "Earth Tube Lower Boundary Ground Temperature",
                              thisEarthTube.tLowerBound, zone.Name)

    timeElapsedLoc = state.dataGlobal.HourOfDay + state.dataGlobal.TimeStep * state.dataGlobal.TimeStepZone + state.dataHVACGlobal.SysTimeElapsed
    if state.dataEarthTube.timeElapsed != timeElapsedLoc:
        if state.dataGlobal.BeginDayFlag or state.dataGlobal.BeginEnvrnFlag:
            for etNum in range(1, totEarthTube + 1):
                thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum]
                if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                    continue
                thisEarthTube.tUpperBound = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthUpperBound)
                thisEarthTube.tLowerBound = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthLowerBound)
                for nodeNum in range(thisEarthTube.totNodes):
                    thisEarthTube.tUndist[nodeNum] = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.depthNode[nodeNum])

        if state.dataGlobal.BeginEnvrnFlag or (not state.dataGlobal.WarmupFlag and state.dataGlobal.BeginDayFlag and state.dataGlobal.DayOfSim == 1):
            for etNum in range(1, totEarthTube + 1):
                thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum]
                if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                    continue
                for nodeNum in range(thisEarthTube.totNodes):
                    thisEarthTube.tLast[nodeNum] = thisEarthTube.tUndist[nodeNum]
                    thisEarthTube.tCurrent[nodeNum] = thisEarthTube.tLast[nodeNum]

        for etNum in range(1, totEarthTube + 1):
            thisEarthTube = state.dataEarthTube.EarthTubeSys[etNum]
            if thisEarthTube.ModelType != EarthTubeModelType.Vertical:
                continue
            for nodeNum in range(thisEarthTube.totNodes):
                thisEarthTube.tLast[nodeNum] = thisEarthTube.tCurrent[nodeNum]

    state.dataEarthTube.timeElapsed = timeElapsedLoc

def CalcEarthTube(state):
    outTdb = state.dataEnvrn.OutDryBulbTemp
    numEarthTubes = len(state.dataEarthTube.EarthTubeSys) - 1

    for Loop in range(1, numEarthTubes + 1):
        thisEarthTube = state.dataEarthTube.EarthTubeSys[Loop]
        NZ = thisEarthTube.ZonePtr
        thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[NZ]
        thisZoneHB.MCPTE = 0.0
        thisZoneHB.MCPE = 0.0
        thisZoneHB.EAMFL = 0.0
        thisZoneHB.EAMFLxHumRat = 0.0
        thisEarthTube.FanPower = 0.0

        tempShutDown = (thisZoneHB.MAT < thisEarthTube.MinTemperature or
                       thisZoneHB.MAT > thisEarthTube.MaxTemperature or
                       abs(thisZoneHB.MAT - outTdb) < thisEarthTube.DelTemperature)
        if (thisEarthTube.ModelType == EarthTubeModelType.Basic) and tempShutDown:
            continue

        AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, outTdb, state.dataEnvrn.OutHumRat)
        AirSpecHeat = Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)
        EVF = 0.0 if tempShutDown else thisEarthTube.DesignLevel * thisEarthTube.availSched.getCurrentVal()
        thisZoneHB.MCPE = EVF * AirDensity * AirSpecHeat * \
            (thisEarthTube.ConstantTermCoef +
             abs(outTdb - thisZoneHB.MAT) * thisEarthTube.TemperatureTermCoef +
             state.dataEnvrn.WindSpeed * (thisEarthTube.VelocityTermCoef + state.dataEnvrn.WindSpeed * thisEarthTube.VelocitySQTermCoef))

        thisZoneHB.EAMFL = thisZoneHB.MCPE / AirSpecHeat
        if thisEarthTube.FanEfficiency > 0.0:
            thisEarthTube.FanPower = thisZoneHB.EAMFL * thisEarthTube.FanPressure / (thisEarthTube.FanEfficiency * AirDensity)

        AverPipeAirVel = EVF / math.pi / pow_2(thisEarthTube.r1)
        AirMassFlowRate = EVF * AirDensity

        if thisEarthTube.ModelType == EarthTubeModelType.Basic:
            GroundTempt = thisEarthTube.calcUndisturbedGroundTemperature(state, thisEarthTube.z)
            thisEarthTube.GroundTempt = GroundTempt

        AirThermCond = 0.02442 + 0.6992 * outTdb / 10000.0
        AirKinemVisco = (0.1335 + 0.000925 * outTdb) / 10000.0
        AirThermDiffus = (0.0014 * outTdb + 0.1872) / 10000.0
        Re = 2.0 * thisEarthTube.r1 * AverPipeAirVel / AirKinemVisco
        Pr = AirKinemVisco / AirThermDiffus

        if Re <= 2300.0:
            Nu = 3.66
        elif Re <= 4000.0:
            fa = 1.0 / pow_2(1.58 * math.log(Re) - 3.28)
            Process1 = (fa / 2.0) * (Re - 1000.0) * Pr / (1.0 + 12.7 * math.sqrt(fa / 2.0) * (pow_2(Pr) ** (1.0 / 3.0) - 1.0))
            Nu = (Process1 - 3.66) / 1700.0 * Re + (4000.0 * 3.66 - 2300.0 * Process1) / 1700.0
        else:
            fa = 1.0 / pow_2(1.58 * math.log(Re) - 3.28)
            Nu = (fa / 2.0) * (Re - 1000.0) * Pr / (1.0 + 12.7 * math.sqrt(fa / 2.0) * (pow_2(Pr) ** (1.0 / 3.0) - 1.0))

        PipeHeatTransCoef = Nu * AirThermCond / 2.0 / thisEarthTube.r1

        Rc = 1.0 / 2.0 / math.pi / thisEarthTube.r1 / PipeHeatTransCoef
        Rp = math.log((thisEarthTube.r1 + thisEarthTube.r2) / thisEarthTube.r1) / 2.0 / math.pi / thisEarthTube.PipeThermCond
        if thisEarthTube.r3 > 0.0:
            Rs = math.log((thisEarthTube.r1 + thisEarthTube.r2 + thisEarthTube.r3) / (thisEarthTube.r1 + thisEarthTube.r2)) / 2.0 / math.pi / thisEarthTube.SoilThermCond
        else:
            Rs = 0.0
        Rt = Rc + Rp + Rs
        OverallHeatTransCoef = 1.0 / Rt

        if thisEarthTube.ModelType == EarthTubeModelType.Vertical:
            if AirMassFlowRate > 0.0:
                NTU = OverallHeatTransCoef * 2.0 * math.pi * thisEarthTube.r1 * thisEarthTube.PipeLength / (AirMassFlowRate * AirSpecHeat)
                maxExpPower = 50.0
                if NTU > maxExpPower:
                    eff = 1.0
                else:
                    eff = 1.0 - math.exp(-NTU)
            else:
                eff = 0.0

            airFlowTerm = AirMassFlowRate * AirSpecHeat * eff * thisEarthTube.airFlowCoeff
            thisEarthTube.calcVerticalEarthTube(state, airFlowTerm)

            nodeET = state.dataEarthTube.EarthTubePars[thisEarthTube.vertParametersPtr].numNodesAbove
            if eff <= 0.0:
                thisEarthTube.InsideAirTemp = outTdb
            elif eff >= 1.0:
                thisEarthTube.InsideAirTemp = thisEarthTube.tCurrent[nodeET]
            else:
                thisEarthTube.InsideAirTemp = outTdb - eff * (outTdb - thisEarthTube.tCurrent[nodeET])
        else:
            if AirMassFlowRate * AirSpecHeat == 0.0:
                thisEarthTube.InsideAirTemp = GroundTempt
            else:
                if outTdb > GroundTempt:
                    Process1 = (math.log(abs(outTdb - GroundTempt)) * AirMassFlowRate * AirSpecHeat - OverallHeatTransCoef * thisEarthTube.PipeLength) / (AirMassFlowRate * AirSpecHeat)
                    thisEarthTube.InsideAirTemp = math.exp(Process1) + GroundTempt
                elif outTdb == GroundTempt:
                    thisEarthTube.InsideAirTemp = GroundTempt
                else:
                    Process1 = (math.log(abs(outTdb - GroundTempt)) * AirMassFlowRate * AirSpecHeat - OverallHeatTransCoef * thisEarthTube.PipeLength) / (AirMassFlowRate * AirSpecHeat)
                    thisEarthTube.InsideAirTemp = GroundTempt - math.exp(Process1)

        thisEarthTube.CalcEarthTubeHumRat(state, NZ)

def ReportEarthTube(state):
    ReportingConstant = state.dataHVACGlobal.TimeStepSysSec

    for ZoneLoop in range(1, state.dataGlobal.NumOfZones + 1):
        thisZone = state.dataEarthTube.ZnRptET[ZoneLoop]
        thisZoneHB = state.dataZoneTempPredictorCorrector.zoneHeatBalance[ZoneLoop]

        AirDensity = Psychrometrics.PsyRhoAirFnPbTdbW(state, state.dataEnvrn.OutBaroPress, state.dataEnvrn.OutDryBulbTemp, state.dataEnvrn.OutHumRat)
        CpAir = Psychrometrics.PsyCpAirFnW(state.dataEnvrn.OutHumRat)
        thisZone.EarthTubeVolume = (thisZoneHB.MCPE / CpAir / AirDensity) * ReportingConstant
        thisZone.EarthTubeMass = (thisZoneHB.MCPE / CpAir) * ReportingConstant
        thisZone.EarthTubeVolFlowRate = thisZoneHB.MCPE / CpAir / AirDensity
        thisZone.EarthTubeVolFlowRateStd = thisZoneHB.MCPE / CpAir / state.dataEnvrn.StdRhoAir
        thisZone.EarthTubeMassFlowRate = thisZoneHB.MCPE / CpAir
        thisZone.EarthTubeWaterMassFlowRate = thisZoneHB.EAMFLxHumRat

        thisZone.EarthTubeFanElec = 0.0
        thisZone.EarthTubeAirTemp = 0.0
        for thisEarthTube in state.dataEarthTube.EarthTubeSys[1:]:
            if thisEarthTube.ZonePtr == ZoneLoop:
                thisZone.EarthTubeFanElec = thisEarthTube.FanPower * ReportingConstant
                thisZone.EarthTubeFanElecPower = thisEarthTube.FanPower

                if thisZoneHB.ZT > thisEarthTube.AirTemp:
                    thisZone.EarthTubeHeatLoss = thisZoneHB.MCPE * (thisZoneHB.ZT - thisEarthTube.AirTemp) * ReportingConstant
                    thisZone.EarthTubeHeatLossRate = thisZoneHB.MCPE * (thisZoneHB.ZT - thisEarthTube.AirTemp)
                    thisZone.EarthTubeHeatGain = 0.0
                    thisZone.EarthTubeHeatGainRate = 0.0
                else:
                    thisZone.EarthTubeHeatGain = thisZoneHB.MCPE * (thisEarthTube.AirTemp - thisZoneHB.ZT) * ReportingConstant
                    thisZone.EarthTubeHeatGainRate = thisZoneHB.MCPE * (thisEarthTube.AirTemp - thisZoneHB.ZT)
                    thisZone.EarthTubeHeatLoss = 0.0
                    thisZone.EarthTubeHeatLossRate = 0.0

                thisZone.EarthTubeAirTemp = thisEarthTube.AirTemp
                thisZone.EarthTubeWetBulbTemp = thisEarthTube.WetBulbTemp
                thisZone.EarthTubeHumRat = thisEarthTube.HumRat
                thisZone.EarthTubeOATreatmentPower = thisZoneHB.MCPE * (thisEarthTube.AirTemp - state.dataEnvrn.OutDryBulbTemp)
                break

def SameString(s1: str, s2: str) -> bool:
    return s1.upper() == s2.upper()

def FindItemInList(name: str, items: List) -> int:
    for i, item in enumerate(items[1:], 1):
        if hasattr(item, 'Name') and SameString(item.Name, name):
            return i
    return 0

def GetSchedule(state, name: str) -> Optional[Schedule]:
    return Schedule()

def ShowSevereError(state, msg: str):
    pass

def ShowContinueError(state, msg: str):
    pass

def ShowFatalError(state, msg: str):
    pass

def ShowSevereEmptyField(state, eoh, field: str):
    pass

def ShowSevereItemNotFound(state, eoh, field: str, value: str):
    pass

def ShowSevereInvalidKey(state, eoh, field: str, value: str):
    pass

def SetupOutputVariable(state, name: str, *args):
    pass
