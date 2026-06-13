# EnergyPlus, Copyright (c) 1996-present, The Board of Trustees of the University of Illinois,
# The Regents of the University of California, through Lawrence Berkeley National Laboratory
# (subject to receipt of any required approvals from the U.S. Dept. of Energy), Oak Ridge
# National Laboratory, managed by UT-Battelle, Alliance for Energy Innovation, LLC, and other
# contributors. All rights reserved.

from typing import List, Tuple, Optional, Protocol, Any
from dataclasses import dataclass, field
from enum import IntEnum, auto
import math

# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusData: state object containing all global/mutable simulation state
# - DataSizing enums/constants: OAFlowCalcMethod, PeakLoad, LoadSizing, SizingConcurrence, etc.
# - Constant enums: KindOfSim, CallIndicator
# - Error/message functions: ShowSevereError, ShowWarningError, ShowContinueError, ShowFatalError, etc.
# - Schedule functions: GetSchedule, GetScheduleAlwaysOn
# - Weather functions: ResetEnvironmentCounter, GetNextEnvironment, ManageWeather
# - HeatBalance functions: ManageHeatBalance
# - ZoneEquipment functions: ManageZoneEquipment, UpdateZoneSizing, RezeroZoneSizingArrays
# - AirLoop functions: ManageAirLoops, UpdateSysSizing
# - Output functions: PreDefTableEntry, DisplayString
# - Util functions: FindItemInList, makeUPPER, SameString
# - Format/print: EnergyPlus.format, print functions

class KindOfSim(IntEnum):
    RunPeriodDesign = 1
    RunPeriodWeather = 2

class CallIndicator(IntEnum):
    BeginDay = 1
    DuringDay = 2
    EndDay = 3
    EndZoneSizingCalc = 4

class OAFlowCalcMethod(IntEnum):
    PerPerson = 0
    PerZone = 1
    PerArea = 2
    ACH = 3
    Sum = 4
    Max = 5
    IAQProcedure = 6
    PCOccSch = 7
    PCDesOcc = 8
    Invalid = 9

@dataclass
class ZoneListData:
    Name: str = ""
    NumOfZones: int = 0
    Zones: List[int] = field(default_factory=list)

@dataclass
class SizingManagerData:
    NumAirLoops: int = 0
    ReportZoneSizingMyOneTimeFlag: bool = True
    ReportSpaceSizingMyOneTimeFlag: bool = True
    ReportSysSizingMyOneTimeFlag: bool = True
    runZeroingOnce: bool = True

    def init_constant_state(self, state: Any) -> None:
        pass

    def init_state(self, state: Any) -> None:
        pass

    def clear_state(self) -> None:
        self.NumAirLoops = 0
        self.ReportZoneSizingMyOneTimeFlag = True
        self.ReportSpaceSizingMyOneTimeFlag = True
        self.ReportSysSizingMyOneTimeFlag = True
        self.runZeroingOnce = True

OAFlowCalcMethodNamesUC = [
    "FLOW/PERSON",
    "FLOW/ZONE",
    "FLOW/AREA",
    "AIRCHANGES/HOUR",
    "SUM",
    "MAXIMUM",
    "INDOORAIRQUALITYPROCEDURE",
    "PROPORTIONALCONTROLBASEDONOCCUPANCYSCHEDULE",
    "PROPORTIONALCONTROLBASEDONDESIGNOCCUPANCY"
]

def ManageSizing(state: Any) -> None:
    state.dataSize.SysSizingRunDone = False
    state.dataSize.ZoneSizingRunDone = False
    curName = "Unknown"
    
    GetOARequirements(state)
    GetZoneAirDistribution(state)
    GetZoneHVACSizing(state)
    GetAirTerminalSizing(state)
    GetSizingParams(state)
    GetZoneSizingInput(state)
    GetSystemSizingInput(state)
    GetPlantSizingInput(state)

    if state.dataGlobal.DoZoneSizing or state.dataGlobal.DoSystemSizing:
        if (state.dataSize.NumSysSizInput > 0 and state.dataSize.NumZoneSizingInput == 0) or \
           (not state.dataGlobal.DoZoneSizing and state.dataGlobal.DoSystemSizing and state.dataSize.NumSysSizInput > 0):
            from EnergyPlus import ShowSevereError, ShowContinueError, ShowFatalError, format as EnergyPlus_format
            ShowSevereError(state, EnergyPlus_format("Requested System Sizing but did not request Zone Sizing."))
            ShowContinueError(state, "System Sizing cannot be done without Zone Sizing")
            ShowFatalError(state, "Program terminates for preceding conditions.")

    isUserReqCompLoadReport = False
    fileHasSizingPeriodDays = False
    
    if state.dataGlobal.DoZoneSizing and (state.dataSize.NumZoneSizingInput > 0) and fileHasSizingPeriodDays:
        state.dataGlobal.CompLoadReportIsReq = isUserReqCompLoadReport
    else:
        if isUserReqCompLoadReport:
            if fileHasSizingPeriodDays:
                pass
            else:
                pass

    numZoneSizeIter = 2 if state.dataGlobal.CompLoadReportIsReq else 1

    if (state.dataGlobal.DoZoneSizing) and (state.dataSize.NumZoneSizingInput == 0):
        pass

    if (state.dataSize.NumZoneSizingInput > 0) and \
       (state.dataGlobal.DoZoneSizing or state.dataGlobal.DoSystemSizing or state.dataGlobal.DoPlantSizing):
        state.dataGlobal.DoOutputReporting = False
        state.dataGlobal.ZoneSizingCalc = True

    state.dataGlobal.ZoneSizingCalc = False
    state.dataGlobal.DoOutputReporting = False

    if (state.dataGlobal.DoSystemSizing) and (state.dataSize.NumSysSizInput == 0) and (state.dataSizingManager.NumAirLoops > 0):
        pass

    if (state.dataSize.NumSysSizInput > 0) and (state.dataGlobal.DoSystemSizing or state.dataGlobal.DoPlantSizing):
        pass

    state.dataGlobal.SysSizingCalc = False

    if state.dataSize.ZoneSizingRunDone:
        pass

    if state.dataSize.SysSizingRunDone:
        pass

def CalcdoLoadComponentPulseNow(state: Any, isPulseZoneSizing: bool, WarmupFlag: bool, 
                                 HourOfDay: int, TimeStep: int, KindOfSim: KindOfSim) -> bool:
    HourDayToPulse = 10
    TimeStepToPulse = 1
    
    if (isPulseZoneSizing) and (not WarmupFlag) and (HourOfDay == HourDayToPulse) and \
       (TimeStep == TimeStepToPulse) and \
       ((KindOfSim == KindOfSim.RunPeriodDesign) or (state.dataGlobal.DayOfSim == 1)):
        return True
    return False

def ManageSystemSizingAdjustments(state: Any) -> None:
    if (state.dataSize.NumSysSizInput > 0) and (state.dataGlobal.DoSystemSizing):
        pass

def ManageSystemVentilationAdjustments(state: Any) -> None:
    pass

def DetermineSystemPopulationDiversity(state: Any) -> None:
    anyVRPinModel = False
    for AirLoopNum in range(1, state.dataHVACGlobal.NumPrimaryAirSys + 1):
        pass

def GetOARequirements(state: Any) -> None:
    pass

def ProcessInputOARequirements(state: Any, CurrentModuleObject: str, OAIndex: int,
                               Alphas: List[str], NumAlphas: int,
                               Numbers: List[float], NumNumbers: int,
                               lAlphaBlanks: List[bool], cAlphaFields: List[str],
                               ErrorsFound: bool) -> None:
    pass

def GetZoneAirDistribution(state: Any) -> None:
    pass

def GetZoneHVACSizing(state: Any) -> None:
    pass

def GetAirTerminalSizing(state: Any) -> None:
    pass

def GetSizingParams(state: Any) -> None:
    pass

def GetZoneSizingInput(state: Any) -> None:
    pass

def ReportTemperatureInputError(state: Any, cObjectName: str, paramNum: int,
                                 comparisonTemperature: float, shouldFlagSevere: bool,
                                 ErrorsFound: bool) -> None:
    pass

def GetZoneAndZoneListNames(state: Any, ErrorsFound: bool) -> Tuple[int, List[str], int, List[ZoneListData]]:
    NumZones = 0
    ZoneNames: List[str] = []
    NumZoneLists = 0
    ZoneListNames: List[ZoneListData] = []
    return NumZones, ZoneNames, NumZoneLists, ZoneListNames

def GetSystemSizingInput(state: Any) -> None:
    pass

def GetPlantSizingInput(state: Any) -> None:
    pass

def SetupZoneSizing(state: Any, ErrorsFound: bool) -> None:
    pass

def reportZoneSizing(state: Any, zoneOrSpace: Any, zsFinalSizing: Any,
                     zsCalcFinalSizing: Any, zsCalcSizing: Any, zSizing: Any,
                     zoneMult: float, isSpace: bool) -> None:
    pass

def reportZoneSizingEio(state: Any, ZoneName: str, LoadType: str,
                        CalcDesLoad: float, UserDesLoad: float,
                        CalcDesFlow: float, UserDesFlow: float,
                        DesDayName: str, PeakHrMin: str,
                        PeakTemp: float, PeakHumRat: float,
                        FloorArea: float, TotOccs: float,
                        MinOAVolFlow: float, DOASHeatAddRate: float,
                        isSpace: bool) -> None:
    pass

def ReportSysSizing(state: Any, SysName: str, LoadType: str, PeakLoadType: str,
                    UserDesCap: float, CalcDesVolFlow: float, UserDesVolFlow: float,
                    DesDayName: str, DesDayDate: str, TimeStepIndex: int) -> None:
    pass

def TimeIndexToHrMinString(state: Any, timeIndex: int) -> str:
    tMinOfDay = timeIndex * state.dataGlobal.MinutesInTimeStep
    tHr = int(tMinOfDay / 60)
    tMin = tMinOfDay - tHr * 60
    return f"{tHr:02d}:{tMin:02d}"

def UpdateFacilitySizing(state: Any, CallIndicator: CallIndicator) -> None:
    pass

def UpdateTermUnitFinalZoneSizing(state: Any) -> None:
    for termUnitSizingIndex in range(1, state.dataSize.NumAirTerminalUnits + 1):
        pass
