from EnergyPlus.Autosizing.HeatingAirflowUASizing import HeatingAirflowUASizer
from EnergyPlus.DataSizing import DataSizing
from autosizing import Sizer, HeatingAirflowUAZoneConfigType, HeatingAirflowUASystemConfigType
from state import EnergyPlusState
from EnergyPlus.api.TypeDefs import Real64
from memory import memset, memcpy
from string import String
from utils import CString

def sizerGetLastErrorMessages(sizer: Sizer) -> CString:
    var s = sizer.__as_pointer[EnergyPlus.BaseSizer]()
    var msg = s.getLastErrorMessages()
    var p = CString.alloc(len(msg) + 1)
    memcpy(p, msg.data(), len(msg) + 1)
    return p

def sizerHeatingAirflowUANew() -> Sizer:
    var sizer = EnergyPlus.HeatingAirflowUASizer()
    return sizer.__as_pointer[Sizer]()

def sizerHeatingAirflowUADelete(sizer: Sizer):
    var s = sizer.__as_pointer[EnergyPlus.HeatingAirflowUASizer]()
    del s

def sizerHeatingAirflowUAInitializeForZone(
    state: EnergyPlusState,
    sizer: Sizer,
    zoneConfig: HeatingAirflowUAZoneConfigType,
    elevation: Real64,
    representativeFlowRate: Real64,
    reheatMultiplier: Real64
):
    var s = sizer.__as_pointer[EnergyPlus.HeatingAirflowUASizer]()
    if zoneConfig == HeatingAirflowUAZoneConfigType.HeatingAirflowUAZoneTerminal:
        s.initializeForSingleDuctZoneTerminal(state, elevation, representativeFlowRate)
    elif zoneConfig == HeatingAirflowUAZoneConfigType.HeatingAirflowUAZoneInductionUnit:
        s.initializeForZoneInductionUnit(state, elevation, representativeFlowRate, reheatMultiplier)
    elif zoneConfig == HeatingAirflowUAZoneConfigType.HeatingAirflowUAZoneFanCoil:
        s.initializeForZoneFanCoil(state, elevation, representativeFlowRate)

def sizerHeatingAirflowUAInitializeForSystem(
    state: EnergyPlusState,
    sizer: Sizer,
    sysConfig: HeatingAirflowUASystemConfigType,
    elevation: Real64,
    representativeFlowRate: Real64,
    minFlowRateRatio: Real64,
    DOAS: Int
):
    var s = sizer.__as_pointer[EnergyPlus.HeatingAirflowUASizer]()
    if sysConfig == HeatingAirflowUASystemConfigType.HeatingAirflowUASystemConfigTypeOutdoorAir:
        s.initializeForSystemOutdoorAir(state, elevation, representativeFlowRate, DOAS == 1)
    elif sysConfig == HeatingAirflowUASystemConfigType.HeatingAirflowUASystemConfigTypeMainDuct:
        s.initializeForSystemMainDuct(state, elevation, representativeFlowRate, minFlowRateRatio)
    elif sysConfig == HeatingAirflowUASystemConfigType.HeatingAirflowUASystemConfigTypeCoolingDuct:
        s.initializeForSystemCoolingDuct(state, elevation)
    elif sysConfig == HeatingAirflowUASystemConfigType.HeatingAirflowUASystemConfigTypeHeatingDuct:
        s.initializeForSystemHeatingDuct(state, elevation)
    elif sysConfig == HeatingAirflowUASystemConfigType.HeatingAirflowUASystemConfigTypeOtherDuct:
        s.initializeForSystemOtherDuct(state, elevation)

def sizerHeatingAirflowUASize(state: EnergyPlusState, sizer: Sizer) -> Int:
    var s = sizer.__as_pointer[EnergyPlus.HeatingAirflowUASizer]()
    var st = state.__as_pointer[EnergyPlus.EnergyPlusData]()
    var errorsFound = False
    s.size(st[], EnergyPlus.DataSizing.AutoSize, errorsFound)
    if errorsFound:
        return 1
    return 0

def sizerHeatingAirflowUAValue(sizer: Sizer) -> Real64:
    return sizer.__as_pointer[EnergyPlus.HeatingAirflowUASizer]().autoSizedValue