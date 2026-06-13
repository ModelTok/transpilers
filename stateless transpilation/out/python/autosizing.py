# EXTERNAL DEPS (to wire in glue):
# - EnergyPlusState: opaque state parameter type
# - HeatingAirflowUASizer: sizer class with initialization and sizing methods, from HeatingAirflowUASizing.hh
# - BaseSizer: base class for sizers with getLastErrorMessages() method
# - EnergyPlusData: internal state data, passed by reference to size()
# - Real64: float64 type alias
# - DataSizing.AutoSize: constant for auto-sizing mode

from enum import IntEnum
from typing import Any, Protocol


class HeatingAirflowUAZoneConfigType(IntEnum):
    """Zone configuration types for HeatingAirflowUA sizer."""
    Terminal = 0
    InductionUnit = 1
    FanCoil = 2


class HeatingAirflowUASystemConfigType(IntEnum):
    """System configuration types for HeatingAirflowUA sizer."""
    OutdoorAir = 0
    MainDuct = 1
    CoolingDuct = 2
    HeatingDuct = 3
    OtherDuct = 4


class BaseSizer(Protocol):
    """Protocol for base sizer class."""
    def getLastErrorMessages(self) -> str:
        ...


class HeatingAirflowUASizerType(Protocol):
    """Protocol for HeatingAirflowUA sizer."""
    autoSizedValue: float
    
    def initializeForSingleDuctZoneTerminal(
        self, state: Any, elevation: float, representativeFlowRate: float
    ) -> None:
        ...
    
    def initializeForZoneInductionUnit(
        self, state: Any, elevation: float, representativeFlowRate: float, reheatMultiplier: float
    ) -> None:
        ...
    
    def initializeForZoneFanCoil(
        self, state: Any, elevation: float, representativeFlowRate: float
    ) -> None:
        ...
    
    def initializeForSystemOutdoorAir(
        self, state: Any, elevation: float, representativeFlowRate: float, doas: bool
    ) -> None:
        ...
    
    def initializeForSystemMainDuct(
        self, state: Any, elevation: float, representativeFlowRate: float, minFlowRateRatio: float
    ) -> None:
        ...
    
    def initializeForSystemCoolingDuct(
        self, state: Any, elevation: float
    ) -> None:
        ...
    
    def initializeForSystemHeatingDuct(
        self, state: Any, elevation: float
    ) -> None:
        ...
    
    def initializeForSystemOtherDuct(
        self, state: Any, elevation: float
    ) -> None:
        ...
    
    def size(self, state: Any, auto_size: float, errors_found: list) -> None:
        ...


Sizer = Any


def sizer_get_last_error_messages(sizer: Sizer) -> str:
    """Gets warning and error messages from the autosizing process."""
    s = sizer
    msg = s.getLastErrorMessages()
    return msg


def sizer_heating_airflow_ua_new() -> Sizer:
    """Returns a new reference to a HeatingAirflowUA Sizer class."""
    raise NotImplementedError("Requires HeatingAirflowUASizer implementation")


def sizer_heating_airflow_ua_delete(sizer: Sizer) -> None:
    """Deletes an instance of a HeatingAirflowUA Sizer class."""
    pass


def sizer_heating_airflow_ua_initialize_for_zone(
    state: Any,
    sizer: Sizer,
    zone_config: HeatingAirflowUAZoneConfigType,
    elevation: float,
    representative_flow_rate: float,
    reheat_multiplier: float,
) -> None:
    """Initializes the HeatingAirflowUA sizer class for zone configurations."""
    s = sizer
    if zone_config == HeatingAirflowUAZoneConfigType.Terminal:
        s.initializeForSingleDuctZoneTerminal(state, elevation, representative_flow_rate)
    elif zone_config == HeatingAirflowUAZoneConfigType.InductionUnit:
        s.initializeForZoneInductionUnit(state, elevation, representative_flow_rate, reheat_multiplier)
    elif zone_config == HeatingAirflowUAZoneConfigType.FanCoil:
        s.initializeForZoneFanCoil(state, elevation, representative_flow_rate)


def sizer_heating_airflow_ua_initialize_for_system(
    state: Any,
    sizer: Sizer,
    sys_config: HeatingAirflowUASystemConfigType,
    elevation: float,
    representative_flow_rate: float,
    min_flow_rate_ratio: float,
    doas: int,
) -> None:
    """Initializes the HeatingAirflowUA sizer class for system configurations."""
    s = sizer
    if sys_config == HeatingAirflowUASystemConfigType.OutdoorAir:
        s.initializeForSystemOutdoorAir(state, elevation, representative_flow_rate, doas == 1)
    elif sys_config == HeatingAirflowUASystemConfigType.MainDuct:
        s.initializeForSystemMainDuct(state, elevation, representative_flow_rate, min_flow_rate_ratio)
    elif sys_config == HeatingAirflowUASystemConfigType.CoolingDuct:
        s.initializeForSystemCoolingDuct(state, elevation)
    elif sys_config == HeatingAirflowUASystemConfigType.HeatingDuct:
        s.initializeForSystemHeatingDuct(state, elevation)
    elif sys_config == HeatingAirflowUASystemConfigType.OtherDuct:
        s.initializeForSystemOtherDuct(state, elevation)


def sizer_heating_airflow_ua_size(state: Any, sizer: Sizer) -> int:
    """Does calculation of the HeatingAirflowUA sizer."""
    s = sizer
    errors_found = [False]
    s.size(state, -1.0, errors_found)
    if errors_found[0]:
        return 1
    return 0


def sizer_heating_airflow_ua_value(sizer: Sizer) -> float:
    """Returns the resulting autosized value after sizerHeatingAirflowUASize() is called."""
    return sizer.autoSizedValue
